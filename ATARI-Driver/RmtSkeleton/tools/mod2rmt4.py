#!/usr/bin/env python3
"""
mod2rmt4.py - ProTracker MOD (4 channels) -> RMT4 module for the Atari

    python3 tools/mod2rmt4.py song.mod song.rmt [options]

The RMT4 layout written here follows the player routine src/rmtplayr.s
(RMT 1.20090108): header, instrument table, tracks lo/hi tables,
instruments, tracks, song (song last, as tools/rmt2ca65.py expects).

What is converted
-----------------
- song order, Bxx (position jump -> song "goto"), Dxx (pattern break)
- notes, sample default volume and Cxx (volume) -> RMT note volume 0..15
- speed: MOD speed at 125 BPM = RMT speed (one line = speed frames at 50 Hz)
- each (sample, period) pair becomes an RMT instrument built from the sample:
    * volume envelope: RMS of the sample, frame by frame (1/50 s) at the
      playback rate of that period, normalised on the loudest sample
    * sound, by sample kind (automatic, or --kind):
        bass   tonal, low: distortion C (poly4) bass tables of the player,
               note chosen from the measured pitch (autocorrelation)
        tone   tonal, >= 125 Hz: pure tone table
        kick   distortion C pitch sweep (--kick-sweep), absolute AUDF
        noise  poly17 noise, AUDF per frame from the spectral centroid
               (calibrated on POKEY: tools/rmtplay)
- MOD channels are routed to RMT channels by sample (--map) or kept as they are

Not converted (reported): other effects (slides, portamento, vibrato, ...).

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
    seg = seg - seg.mean()
    w = np.abs(np.fft.rfft(seg * np.hanning(len(seg)), 4096))
    fr = np.fft.rfftfreq(4096, 1 / rate)
    return float((w * fr).sum() / max(w.sum(), 1e-9))


def pitch(x, rate, fmin=20, fmax=2000):
    """fundamental (Hz) and strength (0..1) by autocorrelation of the first 80 ms"""
    seg = x[int(0.01 * rate):int(0.09 * rate)]
    seg = seg - seg.mean()
    if len(seg) < 32 or not seg.any():
        return 0.0, 0.0
    ac = np.correlate(seg, seg, 'full')[len(seg) - 1:]
    lo, hi = max(2, int(rate / fmax)), min(len(ac) - 1, int(rate / fmin))
    if hi <= lo:
        return 0.0, 0.0
    lag = lo + int(np.argmax(ac[lo:hi]))
    return rate / lag, float(ac[lag] / ac[0])


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
    def __init__(self, env, note, desc):
        self.env = env          # [(volume 0..15, distortion, command, param)]
        self.note = note        # track note (0..60)
        self.desc = desc

    def encode(self):
        env = list(self.env)
        while env and env[-1][0] == 0:
            env.pop()
        env = env[:MAX_ENV - 1] + [(0, env[-1][1] if env else DIST_PURE, CMD_NOTE, 0)]
        tableend = 12                           # table of 1 note (offset 0)
        first = tableend + 1
        last = first + 3 * (len(env) - 1)
        b = bytearray([tableend, 12, last, last, 0x00, 0x00, 0, 0, 0, 0, 0, 0, 0x00])
        for vol, dist, cmd, par in env:         # last frame: silent, loops on itself
            b += bytes([(vol << 4) | vol, (cmd << 4) | (dist << 1), par & 0xFF])
        return bytes(b)


def build_instrument(smp, period, kind, k, level, args):
    x = smp['data']
    rate = mod_period_rate(period, smp['finetune'])
    if smp['looplen'] > 2:          # looped sample: repeat the loop to fill the envelope
        need = int(rate / FRAME_HZ * MAX_ENV) + 1
        loop = x[smp['loop']:smp['loop'] + smp['looplen']]
        x = np.concatenate([x[:smp['loop'] + smp['looplen']]] + [loop] * (need // len(loop) + 1))
    segs = frames_of(x, rate)
    vols = [min(15, round(15 * rms(s) / level)) for s in segs]

    if kind in ('bass', 'tone'):
        f0 = k / period
        dists = (DIST_BASS2, DIST_BASS1) if kind == 'bass' else (DIST_PURE,)
        err, dist, note = best_note(f0, dists)
        env = [(v, dist, CMD_NOTE, 0) for v in vols]
        return Instrument(env, note, "%s %.1f Hz -> %s note %d (%+.0f c)" % (
            kind, f0, {DIST_BASS1: 'distC/bass1', DIST_BASS2: 'distC/bass2',
                       DIST_PURE: 'pure'}[dist], note, err))
    if kind == 'kick':
        f_hi, f_lo = args.kick_sweep
        n = max(1, len(vols) - 1)
        env = []
        for i, v in enumerate(vols):
            f = f_hi * (f_lo / f_hi) ** min(1.0, i / min(n, 8))
            env.append((v, DIST_BASS2, CMD_AUDF, distc_audf(f)))
        return Instrument(env, 0, "kick distC sweep %g -> %g Hz" % (f_hi, f_lo))
    # noise
    env = [(v, DIST_NOISE, CMD_AUDF, noise_audf(centroid(s, rate), rate)) for v, s in zip(vols, segs)]
    return Instrument(env, 0, "noise poly17, AUDF %s" % sorted({e[3] for e in env}))


def pitch_constant(smp, periods):
    """f0 * period of a sample: the same for every note, so the median over all
    the periods it is played at discards octave errors of single estimates"""
    ks = []
    for per in periods:
        f0, strength = pitch(smp['data'], mod_period_rate(per, smp['finetune']), 20, 500)
        if f0:
            ks.append((f0 * per, strength))
    if not ks:
        return 0.0, 0.0
    ks.sort()
    k, strength = ks[len(ks) // 2]
    return k, strength


def classify(k, strength, period):
    if strength < 0.5:
        return 'noise'
    return 'bass' if k / period < 125 else 'tone'


# ---------------------------------------------------------------------------
# RMT module
# ---------------------------------------------------------------------------
def encode_track(events, length):
    """events: {row: (note, instr, vol)} -> RMT track bytes covering length rows"""
    out = bytearray()
    row = 0
    for r in sorted(events):
        gap = r - row
        out += pause(gap)
        note, instr, vol = events[r]
        out += bytes([((vol & 3) << 6) | note, (instr << 2) | (vol >> 2)])
        row = r + 1
    out += pause(length - row)
    return bytes(out)


def pause(n):
    out = bytearray()
    while n > 0:
        k = min(n, 255)
        out += bytes([0x3E | (k << 6)]) if k <= 3 else bytes([0x3E, k])
        n -= k
    return out


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
    ap.add_argument('--addr', type=lambda s: int(s, 0), default=0x4000,
                    help="module load address (default $4000; rmt2ca65 relocates it anyway)")
    args = ap.parse_args()

    mod = Mod(args.mod)
    route = {int(a): int(b) - 1 for a, b in (x.split(':') for x in args.map.split(',') if x)}
    kinds = {int(a): b for a, b in (x.split(':') for x in args.kind.split(',') if x)}
    segs, loop_to = mod_segments(mod)

    # speed: first Fxx < 32 at the start, BPM from Fxx >= 32
    speed, bpm = 6, 125
    effects = {}
    for _, p, r0, n in segs:
        for r in range(r0, r0 + n):
            for cell in mod.patterns[p][r]:
                e, par = cell['eff'], cell['par']
                if e == 0xF and par:
                    if par < 32:
                        speed = par
                    else:
                        bpm = par
                elif (e or par) and e not in (0xB, 0xC, 0xD):
                    effects[e] = effects.get(e, 0) + 1
    rmt_speed = max(1, round(speed * 125 / bpm))

    # collect notes per RMT channel, find (sample, period) pairs
    pairs = {}
    lines = []          # per segment: 4 dicts row -> (smp, period, vol)
    conflicts = 0
    for _, p, r0, n in segs:
        chans = [dict() for _ in range(4)]
        last_smp = [0] * 4
        for r in range(r0, r0 + n):
            for c, cell in enumerate(mod.patterns[p][r]):
                s, per = cell['smp'], cell['period']
                if s:
                    last_smp[c] = s
                if not per:
                    continue
                s = s or last_smp[c]
                if not s or not mod.samples[s - 1]['len']:
                    continue
                vol = cell['par'] if cell['eff'] == 0xC else mod.samples[s - 1]['vol']
                vol = min(vol, 64)
                ch = route.get(s, c)
                if (r - r0) in chans[ch]:
                    conflicts += 1
                    if chans[ch][r - r0][2] >= vol:
                        continue
                chans[ch][r - r0] = (s, per, vol)
                pairs[(s, per)] = True
        lines.append((n, chans))

    # instruments
    level = 1e-9
    for s, per in pairs:
        smp = mod.samples[s - 1]
        rate = mod_period_rate(per, smp['finetune'])
        for seg in frames_of(smp['data'], rate):
            level = max(level, rms(seg))
    instr_of, instruments = {}, []
    for s, per in sorted(pairs):
        k, strength = pitch_constant(mod.samples[s - 1], [p for (s2, p) in pairs if s2 == s])
        kind = kinds.get(s) or classify(k, strength, per)
        instr_of[(s, per)] = len(instruments)
        instruments.append(build_instrument(mod.samples[s - 1], per, kind, k, level, args))
    if len(instruments) > 64:
        die("%d instruments, RMT allows 64" % len(instruments))

    # tracks (deduplicated) and song lines
    tracks, track_id, song = [], {}, []
    for n, chans in lines:
        line = []
        for ch in range(4):
            if not chans[ch]:
                line.append(0xFF)
                continue
            ev = {}
            for r, (s, per, vol) in chans[ch].items():
                ins = instr_of[(s, per)]
                v = max(1, round(vol * 15 / 64)) if vol else 0
                ev[r] = (instruments[ins].note, ins, v)
            data = encode_track(ev, n)
            if n < 64:
                data += b'\xFF'         # pattern break: end of this song line
            if data not in track_id:
                track_id[data] = len(tracks)
                tracks.append(data)
            line.append(track_id[data])
        if n < 64 and all(t == 0xFF for t in line):
            data = pause(n) + b'\xFF'
            track_id.setdefault(data, len(tracks))
            if track_id[data] == len(tracks):
                tracks.append(data)
            line[0] = track_id[data]
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
    body = bytearray(b'RMT4' + bytes([64, rmt_speed, 1, 1]))
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
    if end > 0xFFFF:
        die("module too big")
    with open(args.rmt, 'wb') as f:
        f.write(struct.pack('<3H', 0xFFFF, a, end) + body)

    # report
    used = sorted({ch + 1 for _, chans in lines for ch in range(4) if chans[ch]})
    print("mod2rmt4: %s -> %s (%d bytes at $%04X)" % (args.mod, args.rmt, len(body), a))
    print("  title '%s', %d song lines (loop to line %d), speed %d (MOD speed %d, %d BPM)"
          % (mod.title, len(song), loop_to, rmt_speed, speed, bpm))
    print("  %d instruments, %d tracks, RMT channels used %s" % (len(instruments), len(tracks), used))
    for (s, per), i in sorted(instr_of.items(), key=lambda kv: kv[1]):
        smp = mod.samples[s - 1]
        ch = sorted({ch + 1 for _, chans in lines for ch in range(4)
                     for v in chans[ch].values() if v[0] == s and v[1] == per})
        print("  instr %2d: sample %2d '%s' period %d, ch %s, %d frames: %s"
              % (i, s, smp['name'], per, ch, len(instruments[i].env), instruments[i].desc))
    if conflicts:
        print("  warning: %d notes dropped (two notes on the same RMT channel and row)" % conflicts)
    if effects:
        print("  warning: effects not converted: %s" %
              ", ".join("%X x%d" % kv for kv in sorted(effects.items())))


if __name__ == '__main__':
    main()
