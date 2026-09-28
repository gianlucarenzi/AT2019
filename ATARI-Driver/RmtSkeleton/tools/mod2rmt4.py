#!/usr/bin/env python3
"""
mod2rmt4.py - ProTracker MOD (4 channels) -> RMT4 module for the Atari

    python3 tools/mod2rmt4.py song.mod song.rmt [options]

The RMT4 layout written here follows the player routine src/rmtplayr.s
(RMT 1.20090108): header, instrument table, tracks lo/hi tables,
instruments, tracks, song (song last, as tools/rmt2ca65.py expects).

What is converted (details: MOD_TO_RMT_WORKFLOW.md)
-----------------
- song order, Bxx (position jump -> song "goto"), Dxx (pattern break)
- notes; sample volume, Cxx, Axy/5xy/6xy volume slides, EAx/EBx, ECx
  -> note volume or RMT volume events (no retrigger)
- Fxx speed/BPM -> RMT speed events (one line = speed frames at 50 Hz)
- 4xy/6xy vibrato -> instrument copy with RMT vibrato; 3xx/5xy tone portamento
  approximated by playing the target note
- instruments built from the samples:
    * volume envelope: RMS of the sample, frame by frame (1/50 s) at the
      playback rate, normalised on the loudest sample; looped samples sustain
    * sound, by sample kind (sample name, pitch analysis, or --kind):
        bass   tonal, low: distortion C (poly4) bass tables of the player
        tone   tonal, >= 125 Hz: pure tone table
        kick   distortion C pitch sweep (--kick-sweep), absolute AUDF
        noise  poly17 noise, AUDF per frame from the spectral centroid
               (calibrated on POKEY: tools/rmtplay)
    * one per (sample, period) if they fit in 64, else grouped (see report)
- MOD channels are routed to RMT channels by sample (--map) or kept as they are

Not converted (reported): arpeggio, pitch slides, tremolo, sample offset,
retrigger.

RMT channels 1+2 keep playing while the Atari loads from disk (3+4 are the
serial baud rate then): route the most important voices there.
"""
import argparse
import math
import struct
import sys

import numpy as np

PAL_CLOCK = 7093789.2           # Amiga PAL, for MOD periods
POKEY_BASE = 1773447 / 28       # PAL 64 kHz base clock
FRAME_HZ = 50

# frequency tables of src/rmtplayr.s (note 0..63)
FRQ_BASS1 = [
    0xBF, 0xB6, 0xAA, 0xA1, 0x98, 0x8F, 0x89, 0x80, 0xF2, 0xE6, 0xDA, 0xCE, 0xBF, 0xB6, 0xAA, 0xA1,
    0x98, 0x8F, 0x89, 0x80, 0x7A, 0x71, 0x6B, 0x65, 0x5F, 0x5C, 0x56, 0x50, 0x4D, 0x47, 0x44, 0x3E,
    0x3C, 0x38, 0x35, 0x32, 0x2F, 0x2D, 0x2A, 0x28, 0x25, 0x23, 0x21, 0x1F, 0x1D, 0x1C, 0x1A, 0x18,
    0x17, 0x16, 0x14, 0x13, 0x12, 0x11, 0x10, 0x0F, 0x0E, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08, 0x07]
FRQ_BASS2 = [
    0xFF, 0xF1, 0xE4, 0xD8, 0xCA, 0xC0, 0xB5, 0xAB, 0xA2, 0x99, 0x8E, 0x87, 0x7F, 0x79, 0x73, 0x70,
    0x66, 0x61, 0x5A, 0x55, 0x52, 0x4B, 0x48, 0x43, 0x3F, 0x3C, 0x39, 0x37, 0x33, 0x30, 0x2D, 0x2A,
    0x28, 0x25, 0x24, 0x21, 0x1F, 0x1E, 0x1C, 0x1B, 0x19, 0x17, 0x16, 0x15, 0x13, 0x12, 0x11, 0x10,
    0x0F, 0x0E, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00]
FRQ_PURE = [
    0xF3, 0xE6, 0xD9, 0xCC, 0xC1, 0xB5, 0xAD, 0xA2, 0x99, 0x90, 0x88, 0x80, 0x79, 0x72, 0x6C, 0x66,
    0x60, 0x5B, 0x55, 0x51, 0x4C, 0x48, 0x44, 0x40, 0x3C, 0x39, 0x35, 0x32, 0x2F, 0x2D, 0x2A, 0x28,
    0x25, 0x23, 0x21, 0x1F, 0x1D, 0x1C, 0x1A, 0x18, 0x17, 0x16, 0x14, 0x13, 0x12, 0x11, 0x10, 0x0F,
    0x0E, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00, 0x00]

# RMT envelope distortion index (reg2 bits 1..3) -> tabbeganddistor of the player
DIST_NOISE = 4      # AUDC $80: poly17 noise (pure frequency table)
DIST_PURE = 5       # AUDC $A0: pure tone
DIST_BASS1 = 3      # AUDC $C0: distortion C, bass table 1 (not 6: 6 = 16 bit bass)
DIST_BASS2 = 7      # AUDC $C0: distortion C, bass table 2
CMD_NOTE = 0        # AUDF = table[note + param]
CMD_AUDF = 1        # AUDF = param

# poly17 noise ($80): AUDF -> spectral centroid (Hz), measured with tools/rmtplay's
# POKEY emulation, for original bandwidths of 10.4 kHz and 6.2 kHz
NOISE_CAL_N = [0, 1, 2, 3, 4, 5, 6, 7, 9, 11, 12, 15, 20, 30, 40, 60, 80, 120, 160, 255]
NOISE_CAL_10K = [5033, 4986, 4747, 4490, 4050, 3587, 3203, 3113, 3075, 2922, 2737, 2666,
                 2450, 2285, 2156, 1912, 1874, 1753, 1644, 1568]
NOISE_CAL_6K = [3030, 3049, 2976, 2979, 2852, 2756, 2663, 2542, 2136, 1926, 1889, 1851,
                1660, 1559, 1433, 1286, 1258, 1167, 1094, 1026]

C_K = 261.6256 * 428   # f0 * period of a sample tuned to C at C-2 (ProTracker)
MAX_ENV = 48        # envelope frames per instrument (the RMT editor limit)


def die(msg):
    sys.exit("mod2rmt4: " + msg)


# ---------------------------------------------------------------------------
# POKEY pitch of a frequency table entry (64 kHz clock)
# ---------------------------------------------------------------------------
def pokey_freq(dist, audf):
    n = audf + 1
    if dist == DIST_PURE:
        return POKEY_BASE / (2 * n)
    if dist in (DIST_BASS1, DIST_BASS2):
        # poly4 sampled every n*28 cycles: period 15 pulses, or 5/3 if n shares factors
        period = 15 // math.gcd(n, 15)
        return POKEY_BASE / (period * n) if period > 1 else 0.0
    raise ValueError(dist)


def best_note(freq, dists):
    """(cents error, dist, note) of the table entry closest to freq"""
    best = None
    for dist in dists:
        table = {DIST_PURE: FRQ_PURE, DIST_BASS1: FRQ_BASS1, DIST_BASS2: FRQ_BASS2}[dist]
        for note in range(61):
            f = pokey_freq(dist, table[note])
            if f <= 0:
                continue
            err = abs(1200 * math.log2(f / freq))
            if best is None or err < best[0]:
                best = (err, dist, note)
    return best


def distc_audf(freq):
    """distortion C AUDF with period 15 (N+1 not a multiple of 3 or 5) closest to freq"""
    best = None
    for audf in range(256):
        n = audf + 1
        if math.gcd(n, 15) != 1:
            continue
        f = POKEY_BASE / (15 * n)
        err = abs(math.log2(f / freq))
        if best is None or err < best[0]:
            best = (err, audf)
    return best[1]


# ---------------------------------------------------------------------------
# MOD
# ---------------------------------------------------------------------------
class Mod:
    def __init__(self, path):
        d = open(path, 'rb').read()
        if len(d) < 1084 or d[1080:1084] not in (b'M.K.', b'M!K!', b'4CHN', b'FLT4'):
            die("%s: only 31 sample, 4 channel MODs (M.K.) are supported" % path)
        self.title = d[:20].rstrip(b'\0').decode('latin-1')
        self.samples = []
        off = 20
        for _ in range(31):
            name = d[off:off + 22].rstrip(b'\0').decode('latin-1', 'replace')
            ln, ft, vol, ls, ll = struct.unpack('>HBBHH', d[off + 22:off + 30])
            self.samples.append({'name': name, 'len': ln * 2, 'finetune': ft & 15,
                                 'vol': min(vol, 64), 'loop': ls * 2, 'looplen': ll * 2})
            off += 30
        self.songlen = d[950]
        self.order = list(d[952:952 + self.songlen])
        npat = max(d[952:952 + 128]) + 1
        self.patterns = []
        for p in range(npat):
            rows = []
            for r in range(64):
                row = []
                for c in range(4):
                    b = d[1084 + p * 1024 + r * 16 + c * 4:][:4]
                    row.append({'smp': (b[0] & 0xF0) | (b[2] >> 4),
                                'period': ((b[0] & 0x0F) << 8) | b[1],
                                'eff': b[2] & 0x0F, 'par': b[3]})
                rows.append(row)
            self.patterns.append(rows)
        p = 1084 + npat * 1024
        for s in self.samples:
            s['data'] = np.frombuffer(d[p:p + s['len']], dtype=np.int8).astype(float)
            p += s['len']


def mod_segments(mod):
    """Play order as (position, pattern, first row, rows), plus the loop target index."""
    segs, start_of = [], {}
    pos, row = 0, 0
    while True:
        if pos >= mod.songlen:
            return segs, 0
        if (pos, row) in start_of:
            return segs, start_of[(pos, row)]
        start_of[(pos, row)] = len(segs)
        pat = mod.patterns[mod.order[pos]]
        nxt = None
        r = row
        while r < 64 and nxt is None:
            for cell in pat[r]:
                if cell['eff'] == 0xB:
                    nxt = (cell['par'], 0)
                elif cell['eff'] == 0xD:
                    brk = (cell['par'] >> 4) * 10 + (cell['par'] & 15)
                    nxt = (pos + 1 if nxt is None else nxt[0], brk if brk < 64 else 0)
            r += 1
        segs.append((pos, mod.order[pos], row, r - row))
        pos, row = nxt if nxt else (pos + 1, 0)


# ---------------------------------------------------------------------------
# sample analysis -> RMT instrument
# ---------------------------------------------------------------------------
def frames_of(x, rate, maxframes=MAX_ENV):
    spf = rate / FRAME_HZ
    out = []
    f = 0
    while f < maxframes:
        seg = x[int(f * spf):int((f + 1) * spf)]
        if len(seg) < 4:
            break
        out.append(seg)
        f += 1
    return out


def rms(seg):
    return float(np.sqrt(np.mean(seg ** 2)))


def centroid(seg, rate):
    seg = seg - seg.mean() if len(seg) else seg
    if len(seg) < 4:
        return 0.0
    w = np.abs(np.fft.rfft(seg * np.hanning(len(seg)), 4096))
    fr = np.fft.rfftfreq(4096, 1 / rate)
    return float((w * fr).sum() / max(w.sum(), 1e-9))


def extended(smp, seconds):
    """sample data, a looped sample repeated along its loop to last `seconds`
    at the Amiga C-2 rate or more"""
    x = smp['data']
    if smp['looplen'] > 2:
        loop = x[smp['loop']:smp['loop'] + smp['looplen']]
        need = int(seconds * 30000)
        if len(loop) and len(x) < need:
            x = np.concatenate([x[:smp['loop'] + smp['looplen']]] + [loop] * (need // len(loop) + 1))
    return x


def pitch(x, rate, fmin=20, fmax=2000):
    """fundamental (Hz) and clarity (0..1) with the normalised square difference
    function (McLeod) on 20..120 ms of the sample: only peaks after the first
    zero crossing, and the first one close to the best, to avoid octave errors"""
    seg = x[int(0.02 * rate):int(0.12 * rate)]
    if len(seg) < 64:
        seg = x[:int(0.12 * rate)]
    seg = seg - seg.mean() if len(seg) else seg
    lo, hi = max(2, int(rate / fmax)), int(rate / fmin)
    hi = min(hi, len(seg) // 2)
    if hi <= lo + 2 or not seg.any():
        return 0.0, 0.0
    n = len(seg)
    ac = np.correlate(seg, seg, 'full')[n - 1:n - 1 + hi + 2]
    sq = np.cumsum(seg[::-1] ** 2)[::-1]            # sum of x[t]^2 for t >= k
    e = np.cumsum(seg ** 2)                         # sum of x[t]^2 for t <= k
    lags = np.arange(hi + 2)
    m = e[n - 1 - lags] + sq[lags]
    nsdf = 2 * ac / np.maximum(m, 1e-9)
    neg = np.nonzero(nsdf[:hi] < 0)[0]
    if not len(neg):                        # never uncorrelated: no period in range
        return 0.0, 0.0
    lo = max(lo, int(neg[0]))               # peaks only after the first zero crossing
    if hi <= lo + 2:
        return 0.0, 0.0
    region = nsdf[lo:hi]
    best = float(region.max())
    if best <= 0:
        return 0.0, 0.0
    for i in range(1, len(region) - 1):
        if region[i] >= 0.9 * best and region[i] >= region[i - 1] and region[i] >= region[i + 1]:
            lag = lo + i
            break
    else:
        lag = lo + int(np.argmax(region))
    return rate / lag, float(nsdf[lag])


def noise_audf(cen, rate):
    """AUDF for poly17 noise with the closest centroid, for the sample bandwidth"""
    bw = rate / 2
    t = min(max((bw - 6222) / (10432 - 6222), 0.0), 1.0)
    cal = [a * t + b * (1 - t) for a, b in zip(NOISE_CAL_10K, NOISE_CAL_6K)]
    i = min(range(len(cal)), key=lambda k: abs(cal[k] - cen))
    return NOISE_CAL_N[i]


def mod_period_rate(period, finetune):
    ft = finetune - 16 if finetune > 7 else finetune
    return PAL_CLOCK / (2 * period) * 2 ** (ft / 96)


class Instrument:
    def __init__(self, env, desc, sustain=False, vibrato=0):
        self.env = env          # [(volume 0..15, distortion, command, param)]
        self.desc = desc
        self.sustain = sustain  # looped sample: hold the last frame until the next note
        self.vibrato = vibrato  # RMT vibrato type 0..3

    def encode(self):
        env = list(self.env)
        if self.sustain and env:
            env = env[:MAX_ENV]
        else:                   # one shot: end on a silent frame that loops on itself
            while env and env[-1][0] == 0:
                env.pop()
            env = env[:MAX_ENV - 1] + [(0, env[-1][1] if env else DIST_PURE, CMD_NOTE, 0)]
        tableend = 12                           # table of 1 note (offset 0)
        first = tableend + 1
        last = first + 3 * (len(env) - 1)
        b = bytearray([tableend, 12, last, last, 0x00, 0x00, 0, 0,
                       1 if self.vibrato else 0, self.vibrato, 0, 0, 0x00])
        for vol, dist, cmd, par in env:
            b += bytes([(vol << 4) | vol, (cmd << 4) | (dist << 1), par & 0xFF])
        return bytes(b)


def sample_frames(smp, rate):
    """frames of the sample at this playback rate; a looped sample is extended
    with its loop to fill the envelope"""
    x = smp['data']
    if smp['looplen'] > 2:
        need = int(rate / FRAME_HZ * MAX_ENV) + 1
        loop = x[smp['loop']:smp['loop'] + smp['looplen']]
        if len(loop):
            x = np.concatenate([x[:smp['loop'] + smp['looplen']]] + [loop] * (need // len(loop) + 1))
    return frames_of(x, rate)


def tonal_note(freq, dist):
    """(track note, cents error, octaves shifted) for freq on a distortion table;
    frequencies outside the table are moved by octaves"""
    table = {DIST_PURE: FRQ_PURE, DIST_BASS1: FRQ_BASS1, DIST_BASS2: FRQ_BASS2}[dist]
    fs = [pokey_freq(dist, table[n]) for n in range(61)]
    valid = [f for f in fs if f > 0]
    lo, hi = min(valid), max(valid)
    shift = 0
    while freq < lo / 1.03 and shift < 6:
        freq *= 2
        shift += 1
    while freq > hi * 1.03 and shift > -6:
        freq /= 2
        shift -= 1
    err, _, note = best_note(freq, (dist,))
    return note, err, shift


DISTC = (DIST_BASS2, DIST_BASS1)       # same sound (AUDC $C0), two tables


def table_range(dists):
    fs = []
    for dist in dists:
        table = {DIST_PURE: FRQ_PURE, DIST_BASS1: FRQ_BASS1, DIST_BASS2: FRQ_BASS2}[dist]
        fs += [pokey_freq(dist, table[n]) for n in range(61)]
    fs = [f for f in fs if f > 0]
    return min(fs) / 1.03, max(fs) * 1.03


def place_note(freq, dists):
    """(cents error, dist, note, octaves moved): the closest entry of the tables;
    a note outside them is moved by octaves"""
    lo, hi = table_range(dists)
    moved = 0
    while freq < lo and moved < 6:
        freq *= 2
        moved += 1
    while freq > hi and moved > -6:
        freq /= 2
        moved -= 1
    err, dist, note = best_note(freq, dists)
    return err, dist, note, moved


def tonal_plan(freqs, kind):
    """one sound (pure tone or distortion C) and one octave shift for all the
    notes of a sample (freqs: {frequency: number of notes}), so a melody keeps
    its shape and its timbre: the plan with the smallest total error in cents;
    a note outside the tables costs 1200"""
    families = [(DIST_PURE,)] if kind == 'tone' else [DISTC]
    best = None
    for dists in families:
        lo, hi = table_range(dists)
        for shift in range(-3, 4):
            cost = 30 * abs(shift) * sum(freqs.values())
            for f, cnt in freqs.items():
                g = f * 2 ** shift
                cost += cnt * (1200 if not lo <= g <= hi else best_note(g, dists)[0])
            if best is None or cost < best[0]:
                best = (cost, dists, shift)
    return best[1], best[2]


def tonal_dist(freq, kind):
    if kind == 'tone':
        return DIST_PURE
    if kind == 'bass' or freq < 125:
        err2 = best_note(freq, (DIST_BASS2,))[0]
        err1 = best_note(freq, (DIST_BASS1,))[0]
        return DIST_BASS2 if err2 <= err1 else DIST_BASS1
    return DIST_PURE


def build_instrument(smp, period, kind, dist, level, args, vibrato=0):
    rate = mod_period_rate(period, smp['finetune'])
    segs = sample_frames(smp, rate)
    vols = [min(15, round(15 * rms(s) / level)) for s in segs]
    sustain = smp['looplen'] > 2
    if kind == 'tonal':
        env = [(v, dist, CMD_NOTE, 0) for v in vols]
        name = {DIST_BASS1: 'distC/bass1', DIST_BASS2: 'distC/bass2', DIST_PURE: 'pure'}[dist]
        return Instrument(env, name, sustain, vibrato)
    if kind == 'kick':
        f_hi, f_lo = args.kick_sweep
        n = max(1, len(vols) - 1)
        env = [(v, DIST_BASS2, CMD_AUDF, distc_audf(f_hi * (f_lo / f_hi) ** min(1.0, i / min(n, 8))))
               for i, v in enumerate(vols)]
        return Instrument(env, "kick distC sweep %g -> %g Hz" % (f_hi, f_lo), sustain)
    env = [(v, DIST_NOISE, CMD_AUDF, noise_audf(centroid(s, rate), rate)) for v, s in zip(vols, segs)]
    return Instrument(env, "noise poly17, AUDF %s" % sorted({e[3] for e in env}), sustain)


def pitch_constant(smp, periods):
    """f0 * period of a sample: the same for every note, so the median over all
    the periods it is played at discards octave errors of single estimates"""
    ks = []
    for per in periods:
        f0, strength = pitch(extended(smp, 0.2), mod_period_rate(per, smp['finetune']), 20, 2000)
        if f0:
            ks.append((f0 * per, strength))
    if not ks:
        return 0.0, 0.0
    ks.sort()
    k, strength = ks[len(ks) // 2]
    return k, strength


def flatness(x, rate):
    """spectral flatness 0..1 (noise ~0.3+, tones < 0.05) of 20..200 ms"""
    seg = x[int(0.02 * rate):int(0.2 * rate)]
    if len(seg) < 256:
        seg = x[:int(0.2 * rate)]
    if len(seg) < 16:
        return 1.0
    seg = seg - seg.mean()
    w = np.abs(np.fft.rfft(seg * np.hanning(len(seg)), 8192)) ** 2 + 1e-6
    fr = np.fft.rfftfreq(8192, 1 / rate)
    w = w[(fr > 50) & (fr < min(rate / 2, 8000))]
    return float(np.exp(np.mean(np.log(w))) / np.mean(w))


NAME_KINDS = [                  # conventional MOD sample names, checked in order
    (('bassdrum', 'kick', 'bdrum'), 'kick'),
    (('hihat', 'hat', 'snare', 'crash', 'cymbal', 'ride', 'rim', 'clap', 'noise',
      'lazer', 'laser', 'cheer', 'shaker'), 'noise'),
    (('bass',), 'bass'),
]


def name_kind(name):
    """kind from the words of a sample name: a word must start or end with the
    key ('rimshot', 'sweethat', 'vbass'), so 'Brimble' is not a rimshot"""
    words = [w for w in ''.join(c if c.isalnum() else ' ' for c in name.lower()).split()]
    for keys, kind in NAME_KINDS:
        for w in words:
            w = w.rstrip('0123456789')
            if any(w.startswith(k) or w.endswith(k) for k in keys):
                return kind
    return None


def classify(smp, periods, k, clarity):
    """(kind, reason): the sample name first, then pitch clarity and flatness"""
    kind = name_kind(smp['name'])
    if kind:
        return kind, "name"
    med = sorted(periods)[len(periods) // 2]
    fl = flatness(extended(smp, 0.3), mod_period_rate(med, smp['finetune']))
    if k and clarity >= (0.5 if fl >= 0.1 else 0.35) and fl < 0.2:
        return ('bass' if k / med < 125 else 'tone'), "pitch %.0f Hz, clarity %.2f, flatness %.3f" % (
            k / med, clarity, fl)
    return 'noise', "clarity %.2f, flatness %.3f" % (clarity, fl)


# ---------------------------------------------------------------------------
# MOD playback -> RMT events
# ---------------------------------------------------------------------------
def q15(vol):
    return max(1, round(vol * 15 / 64)) if vol > 0 else 0


def simulate(mod, segs, route):
    """Walk the song like a MOD player (row by row, per channel state) and
    return, per song line, the rows of the 4 RMT channels:
    {'note': {...}} (retrigger), {'vol': v} (volume change), {'speed': s}."""
    speed, bpm = 6, 125
    st = [{'smp': 0, 'vol': 0, 'note': None, 'pending': False} for _ in range(4)]
    lastq = [None] * 4
    stats = {}
    lines = []

    def count(k):
        stats[k] = stats.get(k, 0) + 1

    for _, p, r0, n in segs:
        rows = [[dict() for _ in range(n)] for _ in range(4)]
        for r in range(r0, r0 + n):
            i = r - r0
            cells = mod.patterns[p][r]
            for cell in cells:
                if cell['eff'] == 0xF and cell['par']:
                    if cell['par'] < 32:
                        speed = cell['par']
                    else:
                        bpm = cell['par']
                    rows[0][i]['speed'] = max(1, round(speed * 125 / bpm))
            for c, cell in enumerate(cells):
                s, per, e, par = cell['smp'], cell['period'], cell['eff'], cell['par']
                ch_st = st[c]
                touched = ch_st['pending']
                ch_st['pending'] = False
                if s:
                    if mod.samples[s - 1]['len'] > 2:
                        ch_st['smp'] = s
                    ch_st['vol'] = mod.samples[s - 1]['vol']
                    touched = True
                if e == 0xC:
                    ch_st['vol'] = min(par, 64)
                    touched = True
                if e == 0xE and par >> 4 in (0xA, 0xB):            # fine volume slide
                    d = par & 15
                    ch_st['vol'] = min(64, max(0, ch_st['vol'] + (d if par >> 4 == 0xA else -d)))
                    touched = True
                if e == 0xE and par >> 4 == 0xC:                   # note cut
                    ch_st['vol'] = 0
                    touched = True
                    count('ECx note cut (at row start)')
                ch = route.get(ch_st['smp'], c)
                slot = rows[ch][i]
                if per and ch_st['smp']:
                    if e in (3, 5):
                        count('3xx/5xy tone portamento (target note retriggered)')
                    if e == 0xE and par >> 4 == 0xD:
                        count('EDx note delay (played at row start)')
                    note = {'smp': ch_st['smp'], 'per': per, 'vol': ch_st['vol'], 'vib': False}
                    if 'note' in slot:
                        count('notes dropped (same RMT channel and row)')
                        if slot['note']['vol'] >= note['vol']:
                            note = None
                    if note:
                        slot['note'] = note
                        slot.pop('vol', None)
                        ch_st['note'] = note
                        lastq[ch] = q15(note['vol'])
                elif touched and 'note' not in slot:
                    q = q15(ch_st['vol'])
                    if q != lastq[ch]:
                        slot['vol'] = q
                        lastq[ch] = q
                if e in (4, 6) and ch_st['note']:
                    ch_st['note']['vib'] = True
                if e in (0xA, 5, 6) and par:
                    x, y = par >> 4, par & 15
                    d = x if x else -y
                    ch_st['vol'] = min(64, max(0, ch_st['vol'] + d * (speed - 1)))
                    ch_st['pending'] = True
                if e == 0 and par:
                    count('0xy arpeggio')
                elif e in (1, 2):
                    count('1xx/2xx pitch slide')
                elif e == 7:
                    count('7xy tremolo')
                elif e == 9:
                    count('9xx sample offset')
                elif e == 0xE and par >> 4 == 9:
                    count('E9x retrigger')
                elif e == 0xE and par >> 4 in (1, 2):
                    count('E1x/E2x fine pitch slide')
        lines.append((n, rows))
    return lines, stats


# ---------------------------------------------------------------------------
# RMT module
# ---------------------------------------------------------------------------
def pause(n):
    out = bytearray()
    while n > 0:
        k = min(n, 255)
        out += bytes([0x3E | (k << 6)]) if k <= 3 else bytes([0x3E, k])
        n -= k
    return out


def encode_track(rows, length):
    """rows: {row: {'speed', 'ev'}} with ev = (note, instr, vol) or ('vol', v)"""
    out = bytearray()
    row = 0
    for r in sorted(rows):
        out += pause(r - row)
        row = r
        if 'speed' in rows[r]:
            out += bytes([0x3F, rows[r]['speed']])  # speed, then this row's event
        ev = rows[r].get('ev')
        if ev:
            if ev[0] == 'vol':
                v = ev[1]
                out += bytes([((v & 3) << 6) | 61, v >> 2])
            else:
                note, instr, vol = ev
                out += bytes([((vol & 3) << 6) | note, (instr << 2) | (vol >> 2)])
            row = r + 1
    out += pause(length - row)
    return bytes(out)


def main():
    ap = argparse.ArgumentParser(description="ProTracker MOD -> RMT4 (Atari POKEY)")
    ap.add_argument('mod')
    ap.add_argument('rmt')
    ap.add_argument('--map', default='',
                    help="sample:channel routing, e.g. 3:1,4:2,5:3,1:4,2:4 (RMT channels 1-4); "
                         "unlisted samples keep their MOD channel")
    ap.add_argument('--kind', default='',
                    help="sample:kind overrides, kind = bass, tone, kick, noise (e.g. 4:kick)")
    ap.add_argument('--kick-sweep', type=float, nargs=2, default=(110.0, 40.0), metavar=('HI', 'LO'),
                    help="kick pitch sweep in Hz (default 110 40)")
    ap.add_argument('--tuning', choices=('c', 'measured'), default='measured',
                    help="measured (default): pitch measured on the sample; c: assume tonal samples "
                         "tuned to C at C-2 (period 428), the analysis only picks the octave")
    ap.add_argument('--transpose', default='',
                    help="sample:semitones shifts after tuning, e.g. 7:-12,19:5")
    ap.add_argument('--addr', type=lambda s: int(s, 0), default=0x4000,
                    help="module load address (default $4000; rmt2ca65 relocates it anyway)")
    args = ap.parse_args()

    mod = Mod(args.mod)
    route = {int(a): int(b) - 1 for a, b in (x.split(':') for x in args.map.split(',') if x)}
    kinds = {int(a): b for a, b in (x.split(':') for x in args.kind.split(',') if x)}
    transpose = {int(a): float(b) for a, b in (x.split(':') for x in args.transpose.split(',') if x)}
    for k in kinds.values():
        if k not in ('bass', 'tone', 'kick', 'noise'):
            die("unknown kind '%s'" % k)
    segs, loop_to = mod_segments(mod)
    lines, stats = simulate(mod, segs, route)
    first_speed = next((rows[0][0]['speed'] for n, rows in lines[:1] if 'speed' in rows[0][0]), 6)

    # notes -> samples, periods
    notes = [slot['note'] for n, rows in lines for ch in rows for slot in ch if 'note' in slot]
    periods = {}
    for nt in notes:
        periods.setdefault(nt['smp'], set()).add(nt['per'])

    # sample analysis
    level = 1e-9
    for s, pers in periods.items():
        smp = mod.samples[s - 1]
        for per in pers:
            for seg in sample_frames(smp, mod_period_rate(per, smp['finetune'])):
                level = max(level, rms(seg))
    info = {}
    for s, pers in sorted(periods.items()):
        k, strength = pitch_constant(mod.samples[s - 1], sorted(pers))
        if s in kinds:
            kind, why = kinds[s], "--kind"
        else:
            kind, why = classify(mod.samples[s - 1], sorted(pers), k, strength)
        if kind in ('bass', 'tone') and not k:
            die("sample %d: no pitch found, cannot be '%s'" % (s, kind))
        tune = ""
        if k and kind in ('bass', 'tone'):
            measured = 12 * math.log2(k / C_K)
            if args.tuning == 'c':
                # measured pitches off C by 4/3, 3/2, 5/4... are harmonics, not tuning
                k = C_K * 2 ** round(measured / 12)
            k *= 2 ** (transpose.get(s, 0) / 12)
            tune = ", measured %+.1f st from C, used %+.1f" % (
                (measured + 6) % 12 - 6, 12 * math.log2(k / C_K))
            if kinds.get(s) is None and why != "name":
                med = sorted(pers)[len(pers) // 2]
                kind = 'bass' if k / med < 125 else 'tone'
        info[s] = {'k': k, 'kind': kind, 'why': why + tune}
        if kind in ('bass', 'tone'):
            freqs = {}
            for nt in notes:
                if nt['smp'] == s:
                    f = k / nt['per']
                    freqs[f] = freqs.get(f, 0) + 1
            info[s]['dists'], info[s]['shift'] = tonal_plan(freqs, kind)

    # instrument key of every note, coarser keys until they fit in 64 instruments
    def key(nt, lvl):
        s, per = nt['smp'], nt['per']
        kind = info[s]['kind']
        if kind in ('bass', 'tone'):
            dist = place_note(info[s]['k'] / per * 2 ** info[s]['shift'], info[s]['dists'])[1]
            vib = nt['vib'] and lvl < 3
            return (s, 'tonal', dist, per if lvl == 0 else None, vib)
        if kind == 'kick':
            return (s, 'kick', None, per if lvl == 0 else None, False)
        if lvl >= 4:
            return (s, 'noise', None, None, False)
        if lvl >= 2:            # up to 3 buckets of periods (by octave)
            return (s, 'noise', None, round(math.log2(per)), False)
        return (s, 'noise', None, per, False)

    for lvl in range(5):
        keys = sorted({key(nt, lvl) for nt in notes}, key=lambda k: (k[0], str(k[1:])))
        if len(keys) <= 64:
            break
    else:
        die("%d instruments needed, RMT allows 64" % len(keys))
    instr_of = {k: i for i, k in enumerate(keys)}
    instruments, notes_err = [], {}
    for k in keys:
        s, kind, dist, per, vib = k
        pers = sorted(nt['per'] for nt in notes if key(nt, lvl) == k)
        rep = pers[len(pers) // 2]                 # envelope at the median period
        ins = build_instrument(mod.samples[s - 1], rep, kind, dist, level, args, 1 if vib else 0)
        ins.sample, ins.periods = s, sorted(set(pers))
        instruments.append(ins)

    def track_note(nt, k):
        s, kind, dist = k[0], k[1], k[2]
        if kind != 'tonal':
            return 0
        err, _, note, moved = place_note(info[s]['k'] / nt['per'] * 2 ** info[s]['shift'], (dist,))
        e = notes_err.setdefault(instr_of[k], [0, 0, 0, 0, 0])
        e[4] += moved != 0
        e[0] = max(e[0], err)
        e[1] = info[s]['shift']
        e[2] += err > 30
        e[3] += err > 50
        return note

    # tracks (deduplicated) and song lines
    tracks, track_id, song = [], {}, []
    for n, rows in lines:
        line = []
        for ch in range(4):
            tr = {}
            for i, slot in enumerate(rows[ch]):
                ent = {}
                if 'speed' in slot:
                    ent['speed'] = slot['speed']
                if 'note' in slot:
                    k = key(slot['note'], lvl)
                    ent['ev'] = (track_note(slot['note'], k), instr_of[k], q15(slot['note']['vol']))
                elif 'vol' in slot:
                    ent['ev'] = ('vol', slot['vol'])
                if ent:
                    tr[i] = ent
            if not tr and not (n < 64 and ch == 0):
                line.append(0xFF)
                continue
            data = encode_track(tr, n) + (b'\xFF' if n < 64 else b'')   # pattern break
            if data not in track_id:
                track_id[data] = len(tracks)
                tracks.append(data)
            line.append(track_id[data])
        song.append(line)
    if len(tracks) > 254:
        die("%d tracks, RMT allows 254" % len(tracks))

    # layout: header, instrument table, tracks lo, tracks hi, instruments, tracks, song
    a = args.addr
    o_instr = 16
    o_tlo = o_instr + 2 * len(instruments)
    o_thi = o_tlo + len(tracks)
    o_idata = o_thi + len(tracks)
    idata = [i.encode() for i in instruments]
    o_tdata = o_idata + sum(len(b) for b in idata)
    o_song = o_tdata + sum(len(t) for t in tracks)
    body = bytearray(b'RMT4' + bytes([64, first_speed, 1, 1]))
    body += struct.pack('<4H', a + o_instr, a + o_tlo, a + o_thi, a + o_song)
    p = a + o_idata
    for b in idata:
        body += struct.pack('<H', p)
        p += len(b)
    tptr = []
    p = a + o_tdata
    for t in tracks:
        tptr.append(p)
        p += len(t)
    body += bytes(x & 0xFF for x in tptr) + bytes(x >> 8 for x in tptr)
    for b in idata:
        body += b
    for t in tracks:
        body += t
    for line in song:
        body += bytes(line)
    body += bytes([0xFE, 0]) + struct.pack('<H', a + o_song + 4 * loop_to)
    end = a + len(body) - 1
    if end >= 0xC000:
        die("module too big (%d bytes at $%04X)" % (len(body), a))
    with open(args.rmt, 'wb') as f:
        f.write(struct.pack('<3H', 0xFFFF, a, end) + body)

    # report
    frames = 0
    spd = first_speed
    for n, rows in lines:
        for i in range(n):
            spd = rows[0][i].get('speed', spd)
            frames += spd
    used = sorted({ch + 1 for n, rows in lines for ch in range(4) if any(rows[ch])})
    print("mod2rmt4: %s -> %s (%d bytes at $%04X)" % (args.mod, args.rmt, len(body), a))
    print("  title '%s', %d song lines (loop to line %d), speed %d, %d:%02d until the loop"
          % (mod.title, len(song), loop_to, first_speed, frames // 50 // 60, frames // 50 % 60))
    print("  %d instruments (grouping level %d), %d tracks, RMT channels used %s"
          % (len(instruments), lvl, len(tracks), used))
    for i, ins in enumerate(instruments):
        smp = mod.samples[ins.sample - 1]
        extra = ""
        if i in notes_err:
            e = notes_err[i]
            extra = ", max error %.0f c, notes > 30 c: %d, > 50 c: %d" % (e[0], e[2], e[3])
            if e[1]:
                extra += ", octave %+d" % e[1]
            if e[4]:
                extra += ", %d notes moved by octaves" % e[4]
        print("  instr %2d: sample %2d %-22s %s%s%s, %d periods, %d frames%s"
              % (i, ins.sample, "'%s'" % smp['name'][:20], ins.desc,
                 " +vibrato" if ins.vibrato else "", " (sustain)" if ins.sustain else "",
                 len(ins.periods), len(ins.env), extra))
    print("  sample kinds:")
    for s, v in sorted(info.items()):
        print("    %2d %-22s %-5s (%s)" % (s, mod.samples[s - 1]['name'][:22], v['kind'], v['why']))
    for k, v in sorted(stats.items()):
        print("  note: %s x%d" % (k, v))


if __name__ == '__main__':
    main()
