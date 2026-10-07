#!/usr/bin/env python3
"""
song3ch.py - writes original RMT4 modules that use only channels 1, 2, 3

    python3 tools/song3ch.py music/claude_3ch.rmt
    python3 tools/song3ch.py --song claude_3ch_fast music/claude_3ch_fast.rmt

Channel 4 is always empty, so the song sounds the same on every player of
this tree: Atari POKEY (RmtSkeleton, PokeyATest) and the C64 SID
(../rmt_cbm64, 3 voices: 1 -> 1, 2 -> 2, 3 -> 3). Channels 1+2 (lead and
bass) also keep playing on the Atari while it loads from disk.

    channel 1  lead: pure tone, vibrato after a delay
    channel 2  bass: distortion C (bass tables 1 and 2, the closer one per note)
    channel 3  drums (kick: distortion C pitch sweep, snare: noise) and
               chord stabs (pure tone, arpeggio from the instrument table)

Songs (SONGS below), track length 64 = 4 bars of 16 rows:
    claude_3ch       A minor, speed 6 (125 BPM at 50 Hz)
    claude_3ch_fast  E minor, speed 4 (188 BPM at 50 Hz)
The module layout is the one of tools/mod2rmt4.py (song last, as
tools/rmt2ca65.py expects).
"""
import argparse
import math
import struct

from mod2rmt4 import (FRQ_BASS1, FRQ_BASS2, FRQ_PURE, DIST_NOISE, DIST_PURE,
                      DIST_BASS1, DIST_BASS2, CMD_NOTE, CMD_AUDF,
                      pokey_freq, distc_audf, encode_track)

TRACKLEN = 64
ADDR = 0x4000
TABLE = {DIST_PURE: FRQ_PURE, DIST_BASS1: FRQ_BASS1, DIST_BASS2: FRQ_BASS2}


# ---------------------------------------------------------------------------
# instruments
# ---------------------------------------------------------------------------
def instrument(env, loop=None, table=(0,), vibrato=0, delay=0):
    """env: [(volume, distortion, command, param)], loop: frame the envelope
    returns to after its end (default: the last one), table: note offsets
    played one per frame (arpeggio)"""
    tableend = 12 + len(table) - 1
    first = tableend + 1
    last = first + 3 * (len(env) - 1)
    lop = first + 3 * (len(env) - 1 if loop is None else loop)
    b = bytearray([tableend, 12, last, lop,
                   0x00,                # table type 0 (notes), mode 0, speed 0 (every frame)
                   0x00,                # AUDCTL
                   0, 0,                # volume slide, minimum volume
                   delay, vibrato, 0, 0])
    b += bytes(t & 0xFF for t in table)
    for vol, dist, cmd, par in env:
        b += bytes([(vol << 4) | vol, (cmd << 4) | (dist << 1), par & 0xFF])
    return bytes(b)


def tone(vols, dist):
    return [(v, dist, CMD_NOTE, 0) for v in vols]


INSTR = {}
DATA = []


def add(name, data):
    INSTR[name] = len(DATA)
    DATA.append(data)


# lead: quick attack, decay to a sustain, vibrato from frame 10
add('lead', instrument(tone([11, 15, 14, 13, 12, 12, 11, 11, 11, 10], DIST_PURE),
                       vibrato=1, delay=10))
# bass: punch then sustain (two copies: the two distortion C tables)
BASS_ENV = [15, 14, 13, 12, 11, 11, 10, 10, 10, 9]
add('bass1', instrument(tone(BASS_ENV, DIST_BASS1)))
add('bass2', instrument(tone(BASS_ENV, DIST_BASS2)))
# kick: distortion C from 120 Hz down to 45 Hz
kick = []
for i, v in enumerate([15, 15, 14, 12, 10, 8, 6, 4, 2, 0]):
    f = 120 * (45 / 120) ** (i / 9)
    kick.append((v, DIST_BASS1, CMD_AUDF, distc_audf(f)))
add('kick', instrument(kick))
# snare: bright noise, then darker
add('snare', instrument([(15, DIST_NOISE, CMD_AUDF, 6), (13, DIST_NOISE, CMD_AUDF, 8),
                         (11, DIST_NOISE, CMD_AUDF, 10), (9, DIST_NOISE, CMD_AUDF, 12),
                         (7, DIST_NOISE, CMD_AUDF, 14), (5, DIST_NOISE, CMD_AUDF, 16),
                         (3, DIST_NOISE, CMD_AUDF, 18), (1, DIST_NOISE, CMD_AUDF, 20),
                         (0, DIST_NOISE, CMD_AUDF, 20)]))
# chord stabs: arpeggio 0-3-7 (minor) / 0-4-7 (major), short decay
STAB = tone([12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0], DIST_PURE)
add('minor', instrument(STAB, table=(0, 3, 7)))
add('major', instrument(STAB, table=(0, 4, 7)))


# ---------------------------------------------------------------------------
# notes
# ---------------------------------------------------------------------------
NAMES = {'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5, 'F#': 6, 'G': 7, 'G#': 8, 'A': 9,
         'A#': 10, 'B': 11}


def midi(name):
    return NAMES[name[:-1]] + 12 * (int(name[-1]) + 1)


def hz(m):
    return 440 * 2 ** ((m - 69) / 12)


ERRORS = {}


def table_note(m, dists):
    """(dist, note) of the frequency table entry closest to MIDI note m"""
    best = None
    for dist in dists:
        for note in range(61):
            f = pokey_freq(dist, TABLE[dist][note])
            if f > 0:
                err = 1200 * math.log2(f / hz(m))
                if best is None or abs(err) < abs(best[0]):
                    best = (err, dist, note)
    ERRORS.setdefault(dists, []).append(abs(best[0]))
    return best[1], best[2]


# ---------------------------------------------------------------------------
# scores: melodies one string per bar, "row:note:length" (16 rows per bar)
# ---------------------------------------------------------------------------
CHORDS = {
    'Am': ('A', 'minor'), 'Dm': ('D', 'minor'), 'Em': ('E', 'minor'),
    'C': ('C', 'major'), 'D': ('D', 'major'), 'E': ('E', 'major'), 'F': ('F', 'major'),
    'G': ('G', 'major'), 'B': ('B', 'major'),
}

# channel 3, rows of a bar: kick, snare, chord stab
CH3 = {
    'drums': {0: 'kick', 4: 'snare', 8: 'kick', 10: 'kick', 12: 'snare'},
    'full': {0: 'kick', 2: 'stab', 4: 'snare', 6: 'stab',
             8: 'kick', 10: 'stab', 12: 'snare', 14: 'stab'},
    'drive': {0: 'kick', 2: 'stab', 4: 'snare', 6: 'kick',
              8: 'kick', 10: 'stab', 12: 'snare', 14: 'stab'},
}

SONGS = {
    'claude_3ch': {
        'speed': 6,
        'prog': {
            'A': ['Am', 'F', 'C', 'G'],
            'B': ['Dm', 'Em', 'F', 'G'],
            'B2': ['Dm', 'Em', 'F', 'E'],
        },
        'melody': {
            'A1': ["0:A4:2 2:C5:2 4:E5:4 8:D5:2 10:C5:2 12:E5:4",
                   "0:F5:3 3:E5:3 6:C5:2 8:A4:6 14:C5:2",
                   "0:G5:3 3:E5:3 6:C5:2 8:E5:2 10:G5:2 12:E5:4",
                   "0:D5:6 6:B4:2 8:G4:4 12:B4:2 14:D5:2"],
            'A2': ["0:A4:2 2:C5:2 4:E5:4 8:D5:2 10:C5:2 12:E5:4",
                   "0:F5:3 3:E5:3 6:C5:2 8:A4:6 14:C5:2",
                   "0:G5:3 3:E5:3 6:C5:2 8:E5:2 10:G5:2 12:A5:4",
                   "0:B4:2 2:C5:2 4:D5:4 8:E5:6"],
            'B1': ["0:F5:2 2:E5:2 4:D5:2 6:A4:2 8:D5:4 12:F5:4",
                   "0:G5:2 2:F5:2 4:E5:2 6:B4:2 8:E5:4 12:G5:4",
                   "0:A5:4 4:G5:2 6:F5:2 8:E5:2 10:F5:2 12:C5:4",
                   "0:D5:2 2:B4:2 4:G4:2 6:B4:2 8:D5:4 12:F5:2 14:G5:2"],
            'B2': ["0:F5:2 2:E5:2 4:D5:2 6:A4:2 8:D5:4 12:F5:4",
                   "0:G5:2 2:F5:2 4:E5:2 6:B4:2 8:E5:4 12:G5:4",
                   "0:A5:4 4:G5:2 6:F5:2 8:E5:2 10:F5:2 12:C5:4",
                   "0:B4:2 2:G#4:2 4:B4:2 6:D5:2 8:E5:6"],
        },
        # song lines: (melody or None, progression, bass style, channel 3 style)
        'lines': [
            (None, 'A', 'roots', 'drums'),
            (None, 'A', 'octaves', 'full'),
            ('A1', 'A', 'octaves', 'full'),
            ('A2', 'A', 'octaves', 'full'),
            ('B1', 'B', 'octaves', 'full'),
            ('B2', 'B2', 'octaves', 'full'),
            ('A1', 'A', 'octaves', 'full'),
            ('A2', 'A', 'octaves', 'full'),
        ],
        'loop': 2,
    },
    # faster, E minor: i-VI-III-VII, then iv-i-VI-VII and a B major turnaround;
    # 16th note pickups in the B part, a kick on the "and" of beat 2
    'claude_3ch_fast': {
        'speed': 4,
        'prog': {
            'A': ['Em', 'C', 'G', 'D'],
            'B': ['Am', 'Em', 'C', 'D'],
            'B2': ['Am', 'Em', 'C', 'B'],
        },
        'melody': {
            'A1': ["0:E5:2 2:B4:2 4:E5:2 6:G5:2 8:F#5:2 10:E5:2 12:D5:2 14:B4:2",
                   "0:C5:2 2:E5:2 4:G5:4 8:E5:2 10:G5:2 12:A5:4",
                   "0:G5:4 4:F#5:2 6:G5:2 8:D5:2 10:B4:2 12:D5:4",
                   "0:F#5:3 3:E5:3 6:D5:2 8:A4:4 12:D5:2 14:F#5:2"],
            'A2': ["0:E5:2 2:B4:2 4:E5:2 6:G5:2 8:F#5:2 10:E5:2 12:D5:2 14:B4:2",
                   "0:C5:2 2:E5:2 4:G5:4 8:E5:2 10:G5:2 12:A5:4",
                   "0:G5:4 4:F#5:2 6:G5:2 8:D5:2 10:B4:2 12:D5:4",
                   "0:F#5:2 2:E5:2 4:D5:2 6:F#5:2 8:E5:8"],
            'B1': ["0:A4:1 1:C5:1 2:E5:2 4:A5:4 8:G5:2 10:E5:2 12:C5:4",
                   "0:B4:1 1:E5:1 2:G5:2 4:B4:2 6:E5:2 8:G5:4 12:F#5:2 14:E5:2",
                   "0:E5:2 2:G5:2 4:C5:2 6:E5:2 8:G5:4 12:A5:4",
                   "0:F#5:2 2:A5:2 4:D5:2 6:F#5:2 8:A5:4 12:F#5:2 14:D5:2"],
            'B2': ["0:A4:1 1:C5:1 2:E5:2 4:A5:4 8:G5:2 10:E5:2 12:C5:4",
                   "0:B4:1 1:E5:1 2:G5:2 4:B4:2 6:E5:2 8:G5:4 12:F#5:2 14:E5:2",
                   "0:E5:2 2:G5:2 4:C5:2 6:E5:2 8:G5:4 12:A5:4",
                   "0:D#5:2 2:F#5:2 4:B4:2 6:D#5:2 8:F#5:4 12:D#5:2 14:B4:2"],
        },
        'lines': [
            (None, 'A', 'roots', 'drums'),
            (None, 'A', 'octaves', 'drive'),
            ('A1', 'A', 'octaves', 'drive'),
            ('A2', 'A', 'octaves', 'drive'),
            ('B1', 'B', 'octaves', 'drive'),
            ('B2', 'B2', 'octaves', 'drive'),
            ('A1', 'A', 'octaves', 'drive'),
            ('A2', 'A', 'octaves', 'drive'),
        ],
        'loop': 2,
    },
}

VOL_LEAD, VOL_BASS, VOL_DRUM, VOL_STAB = 13, 15, 15, 10


def lead_rows(melody):
    rows, ends = {}, []
    for bar, text in enumerate(melody):
        for ev in text.split():
            r, n, ln = ev.split(':')
            r = 16 * bar + int(r)
            _, note = table_note(midi(n), (DIST_PURE,))
            rows[r] = {'ev': (note, INSTR['lead'], VOL_LEAD)}
            ends.append(r + int(ln))
    for e in ends:                          # a rest after the note: volume 0
        if e < TRACKLEN and e not in rows:
            rows[e] = {'ev': ('vol', 0)}
    return rows


def bass_rows(prog, style):
    rows = {}
    for bar, ch in enumerate(prog):
        root = midi(CHORDS[ch][0] + '2')
        if root > midi('D#2'):
            root -= 12                      # E1..D#2
        for i in range(8):
            m = root + (12 if style == 'octaves' and i % 2 else 0)
            dist, note = table_note(m, (DIST_BASS1, DIST_BASS2))
            ins = INSTR['bass1' if dist == DIST_BASS1 else 'bass2']
            rows[16 * bar + 2 * i] = {'ev': (note, ins, VOL_BASS)}
    return rows


def ch3_rows(prog, style):
    rows = {}
    for bar, ch in enumerate(prog):
        root, kind = CHORDS[ch]
        _, note = table_note(midi(root + '4'), (DIST_PURE,))
        for r, what in sorted(CH3[style].items()):
            if what == 'stab':
                rows[16 * bar + r] = {'ev': (note, INSTR[kind], VOL_STAB)}
            else:
                rows[16 * bar + r] = {'ev': (0, INSTR[what], VOL_DRUM)}
    return rows


def main():
    ap = argparse.ArgumentParser(description="original 3 channel RMT4 songs")
    ap.add_argument('--song', choices=sorted(SONGS), default='claude_3ch')
    ap.add_argument('rmt')
    args = ap.parse_args()
    sng = SONGS[args.song]
    tracks, track_id, song = [], {}, []

    def track(rows):
        if not rows:
            return 0xFF
        data = encode_track(rows, TRACKLEN)
        if data not in track_id:
            track_id[data] = len(tracks)
            tracks.append(data)
        return track_id[data]

    for mel, prog, bass, drums in sng['lines']:
        prog = sng['prog'][prog]
        song.append([track(lead_rows(sng['melody'][mel])) if mel else 0xFF,
                     track(bass_rows(prog, bass)),
                     track(ch3_rows(prog, drums)),
                     0xFF])                 # channel 4: always silent

    a = ADDR
    o_instr = 16
    o_tlo = o_instr + 2 * len(DATA)
    o_thi = o_tlo + len(tracks)
    o_idata = o_thi + len(tracks)
    o_tdata = o_idata + sum(len(b) for b in DATA)
    o_song = o_tdata + sum(len(t) for t in tracks)
    body = bytearray(b'RMT4' + bytes([TRACKLEN, sng['speed'], 1, 1]))
    body += struct.pack('<4H', a + o_instr, a + o_tlo, a + o_thi, a + o_song)
    p = a + o_idata
    for b in DATA:
        body += struct.pack('<H', p)
        p += len(b)
    tptr = []
    p = a + o_tdata
    for t in tracks:
        tptr.append(p)
        p += len(t)
    body += bytes(x & 0xFF for x in tptr) + bytes(x >> 8 for x in tptr)
    for b in DATA:
        body += b
    for t in tracks:
        body += t
    for line in song:
        body += bytes(line)
    body += bytes([0xFE, 0]) + struct.pack('<H', a + o_song + 4 * sng['loop'])
    with open(args.rmt, 'wb') as f:
        f.write(struct.pack('<3H', 0xFFFF, a, a + len(body) - 1) + body)

    secs = len(sng['lines']) * TRACKLEN * sng['speed'] / 50
    print("song3ch: %s -> %s, %d bytes, %d instruments, %d tracks, %d song lines "
          "(loop to %d), speed %d, %d:%02d at 50 Hz, channel 4 silent"
          % (args.song, args.rmt, len(body), len(DATA), len(tracks), len(sng['lines']),
             sng['loop'], sng['speed'], secs // 60, secs % 60))
    for dists, errs in ERRORS.items():
        print("  %s: max pitch error %.0f cents" % (
            'lead/stabs (pure)' if dists == (DIST_PURE,) else 'bass (distortion C)', max(errs)))


if __name__ == '__main__':
    main()
