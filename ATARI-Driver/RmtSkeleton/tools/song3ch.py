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
    claude_3ch_slow  D minor, speed 8 (94 BPM at 50 Hz), half-time drums
The module layout is the one of tools/mod2rmt4.py (song last, as
tools/rmt2ca65.py expects). A second block holds the song text and the
instrument names, as the RMT editor writes them: players that show the song
info (rmt_cbm64 rmtplay.sh, VERA_ATARI_PBI rmtplay.sh) take the name from the
text before the first ", " and the author from the rest; both are longer than
40 characters, so they scroll.
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
def instrument(env, loop=None, table=(0,), vibrato=0, delay=0,
               tabletype=0x00, tableloop=0, vslide=0):
    """env: [(volume, distortion, command, param)], loop: step the envelope
    returns to after its end (default: the last one), table: note offsets
    (arpeggio) or, with tabletype $80, AUDF offsets; tabletype also holds the
    table speed (bits 0-5: the table steps every speed + 1 player calls),
    tableloop: entry the table returns to; vslide: volume slide once the
    envelope has reached its end (vslide / 256 volume steps per call)"""
    tableend = 12 + len(table) - 1
    first = tableend + 1
    last = first + 3 * (len(env) - 1)
    lop = first + 3 * (len(env) - 1 if loop is None else loop)
    b = bytearray([tableend, 12 + tableloop, last, lop,
                   tabletype,           # table type (bit 7), mode (bit 6), speed (bits 0-5)
                   0x00,                # AUDCTL
                   vslide, 0,           # volume slide, minimum volume
                   delay, vibrato, 0, 0])
    b += bytes(t & 0xFF for t in table)
    for vol, dist, cmd, par in env:
        b += bytes([(vol << 4) | vol, (cmd << 4) | (dist << 1), par & 0xFF])
    return bytes(b)


def tone(vols, dist):
    return [(v, dist, CMD_NOTE, 0) for v in vols]


INSTR = {}
DATA = []
NAMES = []                  # instrument names, for the text block


def add(name, data, text):
    INSTR[name] = len(DATA)
    DATA.append(data)
    NAMES.append(text)


# lead: quick attack, decay to a sustain, vibrato from frame 10
add('lead', instrument(tone([11, 15, 14, 13, 12, 12, 11, 11, 11, 10], DIST_PURE),
                       vibrato=1, delay=10), "lead")
# bass: punch then sustain (two copies: the two distortion C tables)
BASS_ENV = [15, 14, 13, 12, 11, 11, 10, 10, 10, 9]
add('bass1', instrument(tone(BASS_ENV, DIST_BASS1)), "bass (table 1)")
add('bass2', instrument(tone(BASS_ENV, DIST_BASS2)), "bass (table 2)")
# kick: distortion C from 120 Hz down to 45 Hz
kick = []
for i, v in enumerate([15, 15, 14, 12, 10, 8, 6, 4, 2, 0]):
    f = 120 * (45 / 120) ** (i / 9)
    kick.append((v, DIST_BASS1, CMD_AUDF, distc_audf(f)))
add('kick', instrument(kick), "kick")
# snare: bright noise, then darker
add('snare', instrument([(15, DIST_NOISE, CMD_AUDF, 6), (13, DIST_NOISE, CMD_AUDF, 8),
                         (11, DIST_NOISE, CMD_AUDF, 10), (9, DIST_NOISE, CMD_AUDF, 12),
                         (7, DIST_NOISE, CMD_AUDF, 14), (5, DIST_NOISE, CMD_AUDF, 16),
                         (3, DIST_NOISE, CMD_AUDF, 18), (1, DIST_NOISE, CMD_AUDF, 20),
                         (0, DIST_NOISE, CMD_AUDF, 20)]), "snare")
# chord stabs: arpeggio 0-3-7 (minor) / 0-4-7 (major), short decay
STAB = tone([12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0], DIST_PURE)
add('minor', instrument(STAB, table=(0, 3, 7)), "stab minor 0-3-7")
add('major', instrument(STAB, table=(0, 4, 7)), "stab major 0-4-7")


# ---------------------------------------------------------------------------
# instruments for instrument speed 4 (claude_3ch_*_speed_4), in the manner of
# mono_reference_song.rmt / stereo_reference_song.rmt of RITMO 2.6: the player
# is called 4 times per frame, the envelope steps at every call (4 steps per
# frame), the table every speed + 1 calls. The envelopes of the speed 1 set
# are drawn again with 4 steps per frame (volume and pitch interpolated);
# chord stabs and the echo decay by volume slide, the lead vibrato is an AUDF
# table, one step per frame (table speed 3) after a 10 frame delay: what
# changes once per frame sounds the same whether the 4 calls are back to back
# (Atari VBI) or spread over the frame (RITMO, the C64 raster IRQ).
# ---------------------------------------------------------------------------
TICKS = 4
INSTR4 = {}
DATA4 = []
NAMES4 = []


def add4(name, data, text):
    INSTR4[name] = len(DATA4)
    DATA4.append(data)
    NAMES4.append(text)


def ticks(values):
    """per frame values -> TICKS values per frame, linear between frames"""
    out = []
    for i, v in enumerate(values):
        w = values[i + 1] if i + 1 < len(values) else v
        out += [v + (w - v) * k / TICKS for k in range(TICKS)]
    return out


def tone4(vols, dist):
    return [(round(v), dist, CMD_NOTE, 0) for v in ticks(vols)]


# lead: the speed 1 lead, vibrato from the AUDF table (+1 +1 0 0 -1 -1 0 0,
# 8 frames per period) after 10 frames of 0
add4('lead', instrument(tone4([11, 15, 14, 13, 12, 12, 11, 11, 11, 10], DIST_PURE),
                        table=(0,) * 10 + (1, 1, 0, 0, -1, -1, 0, 0), tableloop=10,
                        tabletype=0x80 | (TICKS - 1)), "lead (vibrato table)")
add4('bass1', instrument(tone4(BASS_ENV, DIST_BASS1)), "bass (table 1)")
add4('bass2', instrument(tone4(BASS_ENV, DIST_BASS2)), "bass (table 2)")
# kick: the 120 -> 45 Hz sweep with 4 steps per frame
kick4 = []
for i, v in enumerate(ticks([15, 15, 14, 12, 10, 8, 6, 4, 2, 0])):
    f = 120 * (45 / 120) ** min(1, i / (9 * TICKS))
    kick4.append((round(v), DIST_BASS1, CMD_AUDF, distc_audf(f)))
add4('kick', instrument(kick4), "kick")
add4('snare', instrument([(round(v), DIST_NOISE, CMD_AUDF, round(a)) for v, a in
                          zip(ticks([15, 13, 11, 9, 7, 5, 3, 1, 0]),
                              ticks([6, 8, 10, 12, 14, 16, 18, 20, 20]))]), "snare")
# chord stabs: a constant envelope, the note volume (10) slides down by one
# step every 5 calls (vslide $33), silent after about 13 frames as the speed 1
# stab; arpeggio one note per frame (table speed 3)
STAB4 = tone4([12], DIST_PURE)
add4('minor', instrument(STAB4, table=(0, 3, 7), tabletype=TICKS - 1, vslide=0x33),
     "stab minor 0-3-7")
add4('major', instrument(STAB4, table=(0, 4, 7), tabletype=TICKS - 1, vslide=0x33),
     "stab major 0-4-7")
# echo of the lead: the lead envelope without vibrato, fading by volume slide
# (one step every 8 calls, 2 frames)
add4('echo', instrument(tone4([8, 11, 10, 10, 9], DIST_PURE), vslide=0x20), "lead echo")


# ---------------------------------------------------------------------------
# notes
# ---------------------------------------------------------------------------
NOTES = {'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5, 'F#': 6, 'G': 7, 'G#': 8, 'A': 9,
         'A#': 10, 'B': 11}


def midi(name):
    return NOTES[name[:-1]] + 12 * (int(name[-1]) + 1)


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
    'G': ('G', 'major'), 'B': ('B', 'major'), 'A': ('A', 'major'),
    'Gm': ('G', 'minor'), 'Bb': ('A#', 'major'),
}

# channel 3, rows of a bar: kick, snare, chord stab
CH3 = {
    'drums': {0: 'kick', 4: 'snare', 8: 'kick', 10: 'kick', 12: 'snare'},
    'full': {0: 'kick', 2: 'stab', 4: 'snare', 6: 'stab',
             8: 'kick', 10: 'stab', 12: 'snare', 14: 'stab'},
    'drive': {0: 'kick', 2: 'stab', 4: 'snare', 6: 'kick',
              8: 'kick', 10: 'stab', 12: 'snare', 14: 'stab'},
    # half time: snare on beat 3 only
    'half': {0: 'kick', 8: 'snare', 14: 'kick'},
    'half_full': {0: 'kick', 4: 'stab', 8: 'snare', 12: 'stab', 14: 'kick'},
}

SONGS = {
    'claude_3ch': {
        'speed': 6,
        # song text: name up to the first ", ", then the author (players show
        # NAME / AUTHOR, a line longer than 40 characters scrolls)
        'text': "Claude 3ch - an original song in A minor for POKEY channels 1-3 "
                "and the C64 SID, composed by Claude (Opus 5.5) with "
                "RmtSkeleton/tools/song3ch.py in 2026",
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
        'text': "Claude 3ch fast - an original song in E minor at 188 BPM for POKEY "
                "channels 1-3 and the C64 SID, composed by Claude (Opus 5.5) with "
                "RmtSkeleton/tools/song3ch.py in 2026",
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
    # slower, D minor ballad: i-VI-III-VII (Dm Bb F C), then iv-i-VI-VII
    # and an A major turnaround back to D minor; long lead notes with
    # vibrato, half-time drums, chord stabs on beats 2 and 4
    'claude_3ch_slow': {
        'speed': 8,
        'text': "Claude 3ch slow - an original ballad in D minor at 94 BPM for POKEY "
                "channels 1-3 and the C64 SID, composed by Claude (Opus 5.5) with "
                "RmtSkeleton/tools/song3ch.py in 2026",
        'prog': {
            'A': ['Dm', 'Bb', 'F', 'C'],
            'B': ['Gm', 'Dm', 'Bb', 'C'],
            'B2': ['Gm', 'Dm', 'Bb', 'A'],
        },
        'melody': {
            'A1': ["0:D5:4 4:F5:4 8:E5:2 10:D5:2 12:A4:4",
                   "0:A#4:6 6:C5:2 8:D5:4 12:F5:4",
                   "0:C5:4 4:A4:4 8:C5:2 10:F5:2 12:E5:4",
                   "0:E5:6 6:D5:2 8:C5:4 12:G4:4"],
            'A2': ["0:D5:4 4:F5:4 8:E5:2 10:D5:2 12:A4:4",
                   "0:A#4:6 6:C5:2 8:D5:4 12:F5:4",
                   "0:C5:4 4:A4:4 8:C5:2 10:F5:2 12:E5:4",
                   "0:E5:4 4:D5:2 6:C5:2 8:D5:8"],
            'B1': ["0:G4:2 2:A#4:2 4:D5:4 8:G5:4 12:F5:2 14:D5:2",
                   "0:F5:4 4:E5:2 6:D5:2 8:A4:8",
                   "0:A#4:2 2:D5:2 4:F5:4 8:A#4:2 10:D5:2 12:F5:4",
                   "0:G5:6 6:F5:2 8:E5:4 12:C5:4"],
            'B2': ["0:G4:2 2:A#4:2 4:D5:4 8:G5:4 12:F5:2 14:D5:2",
                   "0:F5:4 4:E5:2 6:D5:2 8:A4:8",
                   "0:A#4:2 2:D5:2 4:F5:4 8:A#4:2 10:D5:2 12:F5:4",
                   "0:C#5:4 4:E5:4 8:A4:4 12:C#5:4"],
        },
        'lines': [
            (None, 'A', 'roots', 'half'),
            (None, 'A', 'octaves', 'half_full'),
            ('A1', 'A', 'octaves', 'half_full'),
            ('A2', 'A', 'octaves', 'half_full'),
            ('B1', 'B', 'octaves', 'half_full'),
            ('B2', 'B2', 'octaves', 'half_full'),
            ('A1', 'A', 'octaves', 'half_full'),
            ('A2', 'A', 'octaves', 'half_full'),
        ],
        'loop': 2,
    },
}

# claude_3ch at instrument speed 4, in the manner of mono_reference_song.rmt
# and stereo_reference_song.rmt of RITMO 2.6: the stereo song has the echo of
# the lead (3 rows later, softer) on the right POKEY, which repeats the left
# one (lead, bass, drums and stabs); the mono song is the same on one POKEY.
# mono_reference_song.rmt has its 4 channels busy and puts the echo in the
# melody channel where the melody rests; the lead of claude_3ch is legato
# (no echo note would fit: --echo-in-rests shows it), so here the echo goes
# to channel 4, free in claude_3ch. On the C64 SID voice 3 plays the louder
# of channels 3 and 4: the echo is heard when drums and stabs are silent.
for _name, _stereo in (('claude_3ch_mono_speed_4', False), ('claude_3ch_stereo_speed_4', True)):
    SONGS[_name] = dict(SONGS['claude_3ch'], instrspeed=4, stereo=_stereo, echo=3, text=(
        "Claude 3ch %s speed 4 - claude_3ch in A minor at instrument speed 4 %s, "
        "composed by Claude (Opus 5.5) with RmtSkeleton/tools/song3ch.py in 2026"
        % (('stereo', "on two POKEYs with an echo of the lead on the right one") if _stereo else
           ('mono', "on one POKEY with an echo of the lead on channel 4"))))

VOL_LEAD, VOL_BASS, VOL_DRUM, VOL_STAB = 13, 15, 15, 10


def melody_notes(melody):
    """[(row, length, table note)] of a melody, rows over the 4 bars"""
    notes = []
    for bar, text in enumerate(melody):
        for ev in text.split():
            r, n, ln = ev.split(':')
            notes.append((16 * bar + int(r), int(ln), table_note(midi(n), (DIST_PURE,))[1]))
    return notes


def note_rows(notes, ins, vol):
    """notes [(row, length, note)] -> rows; a rest after a note: volume 0"""
    rows = {}
    for r, ln, note in notes:
        rows[r] = {'ev': (note, ins, vol)}
    for r, ln, note in notes:
        if r + ln < TRACKLEN and r + ln not in rows:
            rows[r + ln] = {'ev': ('vol', 0)}
    return rows


def lead_rows(melody, instr=INSTR):
    return note_rows(melody_notes(melody), instr['lead'], VOL_LEAD)


VOL_ECHO = 8
ECHO_STATS = [0, 0]                         # echo notes placed, echo notes in all


def echo_notes(melody, delay, in_rests):
    """the lead notes delay rows later, each up to the next echo (stereo:
    a channel of their own) or, in_rests, only where the lead rests and up to
    its next note (mono: in the lead channel, as mono_reference_song.rmt
    holds the echo of stereo_reference_song.rmt)"""
    lead = melody_notes(melody)
    out = []
    for i, (r, ln, note) in enumerate(lead):
        t = r + delay
        if t >= TRACKLEN:
            continue
        ECHO_STATS[1] += 1
        end = t + ln
        if i + 1 < len(lead):
            end = min(end, lead[i + 1][0] + delay)  # the next echo
        if in_rests:
            if any(s <= t < s + l for s, l, _ in lead):
                continue                    # the lead is playing
            nxt = [s for s, _, _ in lead if s > t]
            if nxt:
                end = min(end, nxt[0])
        end = min(end, TRACKLEN)
        out.append((t, end - t, note))
        ECHO_STATS[0] += 1
    return out


def bass_rows(prog, style, instr=INSTR):
    rows = {}
    for bar, ch in enumerate(prog):
        root = midi(CHORDS[ch][0] + '2')
        if root > midi('D#2'):
            root -= 12                      # E1..D#2
        for i in range(8):
            m = root + (12 if style == 'octaves' and i % 2 else 0)
            dist, note = table_note(m, (DIST_BASS1, DIST_BASS2))
            ins = instr['bass1' if dist == DIST_BASS1 else 'bass2']
            rows[16 * bar + 2 * i] = {'ev': (note, ins, VOL_BASS)}
    return rows


def ch3_rows(prog, style, instr=INSTR):
    rows = {}
    for bar, ch in enumerate(prog):
        root, kind = CHORDS[ch]
        _, note = table_note(midi(root + '4'), (DIST_PURE,))
        for r, what in sorted(CH3[style].items()):
            if what == 'stab':
                rows[16 * bar + r] = {'ev': (note, instr[kind], VOL_STAB)}
            else:
                rows[16 * bar + r] = {'ev': (0, instr[what], VOL_DRUM)}
    return rows


def main():
    ap = argparse.ArgumentParser(description="original 3 channel RMT4 songs")
    ap.add_argument('--song', choices=sorted(SONGS), default='claude_3ch')
    ap.add_argument('rmt')
    ap.add_argument('--echo-in-rests', action='store_true',
                    help="mono song with an echo: put it in the lead channel where the lead rests, "
                         "as mono_reference_song.rmt, instead of channel 4")
    args = ap.parse_args()
    sng = SONGS[args.song]
    ispeed = sng.get('instrspeed', 1)
    stereo = sng.get('stereo', False)
    echo = sng.get('echo')
    instr, data, names = (INSTR4, DATA4, NAMES4) if ispeed > 1 else (INSTR, DATA, NAMES)
    tracks, track_id, song = [], {}, []

    def track(rows):
        if not rows:
            return 0xFF
        data = encode_track(rows, TRACKLEN)
        if data not in track_id:
            track_id[data] = len(tracks)
            tracks.append(data)
        return track_id[data]

    def echo_track(mel):
        if not mel:
            return 0xFF
        return track(note_rows(echo_notes(sng['melody'][mel], echo, False), instr['echo'], VOL_ECHO))

    def lead_track(mel, with_echo):
        if not mel:
            return 0xFF
        notes = [(r, ln, n, instr['lead'], VOL_LEAD) for r, ln, n in melody_notes(sng['melody'][mel])]
        if with_echo:
            notes += [(r, ln, n, instr['echo'], VOL_ECHO)
                      for r, ln, n in echo_notes(sng['melody'][mel], echo, True)]
        rows = {r: {'ev': (n, ins, vol)} for r, ln, n, ins, vol in notes}
        for r, ln, n, ins, vol in notes:    # a rest after a note: volume 0
            if r + ln < TRACKLEN and r + ln not in rows:
                rows[r + ln] = {'ev': ('vol', 0)}
        return track(rows)

    for mel, prog, bass, drums in sng['lines']:
        prog = sng['prog'][prog]
        left = [lead_track(mel, echo and args.echo_in_rests),
                track(bass_rows(prog, bass, instr)),
                track(ch3_rows(prog, drums, instr)),
                0xFF]                       # channel 4: silent in claude_3ch
        if stereo:                          # right POKEY: the left one, the echo on channel 8
            left += left[:3] + [echo_track(mel)]
        elif echo and not args.echo_in_rests:
            left[3] = echo_track(mel)       # mono: the echo on channel 4
        song.append(left)

    a = ADDR
    o_instr = 16
    o_tlo = o_instr + 2 * len(data)
    o_thi = o_tlo + len(tracks)
    o_idata = o_thi + len(tracks)
    o_tdata = o_idata + sum(len(b) for b in data)
    o_song = o_tdata + sum(len(t) for t in tracks)
    body = bytearray((b'RMT8' if stereo else b'RMT4') + bytes([TRACKLEN, sng['speed'], ispeed, 1]))
    body += struct.pack('<4H', a + o_instr, a + o_tlo, a + o_thi, a + o_song)
    p = a + o_idata
    for b in data:
        body += struct.pack('<H', p)
        p += len(b)
    tptr = []
    p = a + o_tdata
    for t in tracks:
        tptr.append(p)
        p += len(t)
    body += bytes(x & 0xFF for x in tptr) + bytes(x >> 8 for x in tptr)
    for b in data:
        body += b
    for t in tracks:
        body += t
    for line in song:
        body += bytes(line)
    body += bytes([0xFE, 0]) + struct.pack('<H', a + o_song + len(song[0]) * sng['loop'])
    # second block, as the RMT editor writes it: song text, then the name of
    # every instrument, each ending with a 0 byte
    text = (sng['text'] + '\0' + ''.join(n + '\0' for n in names)).encode('ascii')
    t = a + len(body)
    with open(args.rmt, 'wb') as f:
        f.write(struct.pack('<3H', 0xFFFF, a, a + len(body) - 1) + body)
        f.write(struct.pack('<2H', t, t + len(text) - 1) + text)

    secs = len(sng['lines']) * TRACKLEN * sng['speed'] / 50
    print("song3ch: %s -> %s, %s, %d bytes, %d instruments, %d tracks, %d song lines "
          "(loop to %d), speed %d, instrument speed %d, %d:%02d at 50 Hz, %s"
          % (args.song, args.rmt, 'RMT8' if stereo else 'RMT4', len(body), len(data), len(tracks),
             len(sng['lines']), sng['loop'], sng['speed'], ispeed, secs // 60, secs % 60,
             'channel 4 silent, the echo on channel 8' if stereo else
             'the echo on channel 4' if echo and not args.echo_in_rests else 'channel 4 silent'))
    if echo:
        print("  echo of the lead %d rows later: %d of %d notes%s"
              % (echo, ECHO_STATS[0], ECHO_STATS[1],
                 ' (where the lead rests)' if echo and args.echo_in_rests and not stereo else ''))
    for dists, errs in ERRORS.items():
        print("  %s: max pitch error %.0f cents" % (
            'lead/stabs (pure)' if dists == (DIST_PURE,) else 'bass (distortion C)', max(errs)))


if __name__ == '__main__':
    main()
