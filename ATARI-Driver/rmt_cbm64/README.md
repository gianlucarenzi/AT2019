# RMT CBM64 – RMT modules on the Commodore 64 SID

Plays **RMT4** modules (Raster Music Tracker, Atari POKEY) on a Commodore 64,
and **RMT8** (stereo) modules on a C64 with a second SID.

There is no "generic" RMT format: RMT modules are written for POKEY (RMT4 mono,
RMT8 stereo). This project does not convert the module. It runs the **Atari RMT
player routine itself** on the C64, and turns the POKEY registers it writes
into SID registers every frame. The same `.rmt` file used on the Atari (for
example the ones made by `../RmtSkeleton/tools/mod2rmt4.py`) plays here.

```
.rmt ──rmt2ca65.py──> song.s ─┐
                              ├─ cl65 ──> rmt_cbm64.prg ──c1541──> rmt_cbm64.d64 ──> VICE x64sc
src/rmtplayr.s (-D RMT_C64) ──┤
src/sidrmt.s, sidtab.s ───────┘
```

## How it works

1. **Player**: `src/rmtplayr.s` is the RMT 1.20090108 routine, the same source
   as `../RmtSkeleton/src` and `../PokeyATest/src`. Assembled with
   `-D RMT_C64` it writes the POKEY registers to `pokey_shadow` (16 bytes of
   RAM: `$D200` on the C64 is the VIC-II) and puts its 19 zero page bytes in
   segment `RMTZP`. Without `RMT_C64` it is the Atari code, byte for byte.
2. **Timing** (`src/sidrmt.s`): a raster IRQ at line 0, chained to the KERNAL
   IRQ vector `$0314`, calls the player once per frame, like the Atari VBI.
   With instrument speed N > 1 it calls it N times per frame, at evenly
   spaced raster lines (every 312 / N lines on PAL, as the `FASTPLAY` of a
   SAP exported by RMT; 262 or 263 / N on NTSC); the SID is updated after
   the last call of the frame, so it changes once per frame, as POKEY does
   on the Atari with the VBI player of RmtSkeleton and PokeyATest. A call
   that runs past the line of the next one makes that one at once, so no
   call is lost. The KERNAL CIA IRQ (keyboard, clock) keeps running. PAL
   (50 Hz) or NTSC (60 Hz) is detected from the number of raster lines.
3. **POKEY → SID**, every frame:

| POKEY | SID |
|-------|-----|
| frequency: AUDF, AUDCTL (64 kHz / 15 kHz, 1.79 MHz, 16 bit), distortion | Fn = K / n, n = POKEY divider in machine cycles, K per kind of sound, PAL and NTSC clocks. 64 kHz 8 bit channels (the usual case) read Fn from a table (`tools/mksidtab.py`, 2.5 KB, scaled once on NTSC); the other modes divide |
| pure tone (`$A0`) | pulse 50% |
| distortion C (`$C0`, poly4), with the period of poly4 at that divider (15, 5 or 3 pulses) | pulse 25% |
| poly5 tones (`$20`, `$60`) | pulse 25% |
| poly17 / poly5 noise (`$80`, `$00`, `$40`) | noise |
| volume 0..15 | sustain level of the envelope (attack 0, decay 0); a step 2 or more louder restarts the envelope (gate off/on), a lower one decays to it |
| channels 1, 2, 3, 4 | voice 1 ← 1, voice 2 ← 2, voice 3 ← the louder of 3 and 4 (with 1+2 joined: 3, 2, 4) |

The SID has **3 voices**: when channels 3 and 4 both play, the quieter one
is not heard. A song made for loading on the Atari (main voices on
channels 1+2) keeps them.

Not reproduced: volume only mode (AUDC bit 4, sample playback), the high pass
filters (AUDCTL bits 2 and 1). The timbre is the SID one: square, pulse and
noise waves stand for POKEY's.

## Dual SID: RMT8 (stereo) songs

An RMT8 module, or a stereo SAP / XEX of RITMO, has two POKEYs: channels 1-4
on the left one, 5-8 on the right one. The build follows the song (`make`
reads `RMT8` in the module, `sap2ca65.py --tracks` for a SAP / XEX) and then:

- the player (`-D RMT_TRACKS=8`) writes the right POKEY to `pokey_shadow2`,
  RAM, as it writes the left one to `pokey_shadow`;
- `src/sidrmt.s` translates each POKEY with the same rules as above: the left
  one to the SID at `$D400`, the right one to a second SID at `SID2` (voices
  4-6). `make SID2=D500` (hex digits) puts it elsewhere: any address of a
  dual SID board or of VICE (`$D420`-`$D7E0`, `$DE00`-`$DFE0`); the default
  is `$D420`. `SID2=0` builds without it.
- at start-up `detect_sid2` checks that `SID2` is a chip of its own: on a C64
  with one SID, `$D420`-`$D7FF` are images of `$D400`. Voice 3 of the SID is
  held at 0 (TEST bit) while voice 3 of `SID2` runs; if `SID2` is an image,
  OSC3 of the SID moves. Without a second SID the right POKEY is not heard,
  as on an Atari without a second POKEY. A free I/O area (`$DE00`, `$DF00`)
  cannot be told from a chip: there the writes are lost.

In VICE: `x64sc -sidextra 1 -sid2address 0xd420 -soundoutput 2`, the SID on
the left and the second SID on the right; `rmtplay.sh` adds these options by
itself for a stereo song (`RMT_SID2=D500` for another address).

**Instrument speed 4.** The 8 track player called 4 times per frame takes more
than a frame of the 6510 (0.985 MHz, against the 1.77 MHz of the Atari, where
it takes about half of one): the song plays slower. Measured in VICE (PAL,
frames played in the same 20 million cycles): a stereo song at instrument
speed 1, 2 or 3 with two SIDs plays 850-852 frames, as a mono one (855); at
speed 4, 586 with two SIDs and 720 with one. `rmtplay.c` then shows no volume
bars, which would only take time from the rest.

## SAP / XEX exported by RITMO: lzsplayr.s

A `.sap` or `.xex` exported by RITMO (or Raster Music Tracker 1.31 and later)
does not hold the RMT module: it holds the POKEY registers RMT recorded frame
by frame, with the tracker driver chosen in its options (Patch16 by default),
compressed with LZSS (LZ16 by DMSC) and played by VU-Player v2. With such a
file as `SONG`, `src/lzsplayr.s` takes the place of `src/rmtplayr.s`: the
same entry points, the same `-D RMT_C64` build, the same POKEY → SID
translation. The C64 then plays what the SAP / XEX plays on the Atari.

```bash
make SONG=music/gemx.sap                 # gemx exported by RITMO (Patch16)
make SONG=other.xex SUBSONG=1            # another subtune of the file
./rmtplay.sh music/gemx.sap              # with the visualizer, in x64sc
```

```
.sap / .xex ──sap2ca65.py──> song.s ─┐
src/lzsplayr.s (-D RMT_C64) ─────────┼─ cl65 ──> rmt_cbm64.prg / rmtplay.prg
src/sidrmt.s, sidtab.s ──────────────┘
```

- `tools/sap2ca65.py` takes the subtune out of the VU-Player memory of the
  file (song index at `$1F40`, instrument speed, stereo flag) and writes its
  intro and loop sections as a relocatable source; it decodes every section
  once to check it. With `--info` it writes `songinfo.h` from the SAP tags
  (`NAME`, `AUTHOR`, `DATE`) or the XEX screen text.
- `src/lzsplayr.s` decodes one frame per `rmt_play` (9 byte streams with a
  256 byte window each, 2.3 KB of BSS, 4 zero page bytes in `RMTZP`): intro,
  then the loop over and over. As `rmtplayr.s` it writes `pokey_shadow`
  first and then decodes the next frame.
- The visualizer shows `SECT` (section of the stream: 0 intro, 1 loop, or 0
  when the song loops to its start) and `FRAME` (frame in the section / last
  frame) in place of song line, row and speed.
- Mono or stereo files: a stereo one plays its right POKEY on the second SID,
  as an RMT8 module (see "Dual SID"). Instrument speed N > 1: N calls per frame as with an `.rmt` (the stream
  holds N frames per video frame).

Checked in VICE 3.9 (PAL): `gemx.rmt` with `rmtplayr.s` and the same song
exported by RITMO with the "RMT 1.28 Unpatched" driver, with `lzsplayr.s`,
give the same SID registers in every one of 6954 frames (`-sounddev dump`).
`lzsplayr.s` (also the `RMT_C64` build) gives the POKEY registers of
VU-Player v2 byte for byte on a 6502 emulator, on 22 SAP exports.

## Build

Requirements: **cc65** (`cl65`), **python3**, **c1541** and **x64sc** from VICE.

```bash
make                                   # build/rmt_cbm64.prg, build/rmtplay.prg and their D64s
make SONG=music/PROJECT-X_THESMOPHORIA_pokey.rmt
make run                               # x64sc -autostart build/rmt_cbm64.d64
make clean
```

`SONG` is any RMT4 module (`python3 tools/rmt2ca65.py file.rmt /dev/null`
checks it and shows its instrument speed). Songs in `music/`: `gemx.rmt` (default),
`PROJECT-X_LOADER_pokey.rmt`, `PROJECT-X_THESMOPHORIA_pokey.rmt`,
`ProjectX-End-Lynne_pokey.rmt` (15 KB; the D64 loads in about a minute on a
real-speed 1541), `claude_3ch.rmt`, `claude_3ch_fast.rmt` and `claude_3ch_slow.rmt` (channels 1-3 only, see below), `claude_3ch_mono_speed_4.rmt` (instrument speed 4: the player called 4 times per frame at evenly spaced raster lines; an echo of the lead on channel 4, heard on SID voice 3 when channel 3 is quieter). `D64=build/other.d64` writes the disk under another name.
The song in use is kept in `build/song.cfg`: changing `SONG` rebuilds.

On the disk the program is `RMT PLAYER`: `LOAD"*",8,1` and `RUN`, or
autostart the D64 in VICE. Any key stops the music and returns to BASIC.

## Player with visualizer: rmtplay.sh

`build/rmtplay.prg` (`src/rmtplay.c`) is the same player with a screen in the
style of `RMTPLAY.COM` of VERA_ATARI_PBI (`./rmtplay.sh` there) and of the
XEX/SAP export of Raster Music Tracker:

```bash
./rmtplay.sh music/claude_3ch_fast.rmt       # build for that song, run it in x64sc
RMT_NAME="My song" RMT_AUTHOR="Me" RMT_DATE=2026 ./rmtplay.sh song.rmt
VICE_OPTS="-ntsc" ./rmtplay.sh song.rmt      # extra x64sc options (default -pal -VICIIfilter 0 -residsamp 0)
make rmtplay SONG=song.rmt [NAME=.. AUTHOR=.. DATE=..]   # build only
```

- song name, author and date: from the text RMT stores in the `.rmt`
  (`tools/rmtinfo.py`, same rules as VERA_ATARI_PBI), otherwise the file name;
  a line longer than 40 characters scrolls after 5 seconds
- volume bars of the 3 SID voices (what is heard), centred on the screen
  (6 characters wide, columns 7-12, 17-22, 27-32), labelled 1 2 3 under the
  fourth column of each bar; a voice turned off shows `OFF`
- AUDF / AUDC / AUDCTL; frequency and waveform of every SID voice and the
  POKEY channel it plays; song line, row, speed, play time; PAL / NTSC
- keys: `SPACE` pause, `R` restart, `1` `2` `3` SID voice off / on,
  `RUN/STOP` or `←` exit

`rmtplay.sh` builds with `make rmtplay` and starts `x64sc -autostartprgmode 1`
(the program goes straight into RAM) without the CRT emulation and with the fast
reSID sampling (`-VICIIfilter 0 -residsamp 0`): on a Celeron N3060 VICE with
its window ran at 78-88% of the speed of a C64 (also with the C64 idle at the
BASIC prompt, 90-93%), and music, bars and scroll stuttered; with the two
options it runs at 100% (measured from the CPU clock of the VICE monitor
against the real time); `build/rmtplay.d64` holds the program
(`RMTPLAY`) for a real C64. The play time is counted from the IRQ frames.
The screen work (bars every frame, the other fields every other frame, a
field written only when it changes) fits in the time the player IRQ leaves
in a frame, PAL and NTSC: checked in VICE by colouring the border, about 150
raster lines in the heaviest frame with the IRQ.

With instrument speed 4 the IRQ takes more of the frame (about 113 raster
lines on average, up to 147, with `claude_3ch_mono_speed_4.rmt`), so the
screen work was made lighter: the registers are copied to a buffer before
the fields are compared (an unchanged field is a compare, not two pointer
table reads), the bars are written without `memset()`, the scroll of the
long info lines advances step by step (it took a 32 bit shift and a 16 bit
modulo per line every other frame) and the play time keeps minutes and
seconds (no division). Measured in VICE (PAL, counters in a test build,
4400 frames of that song): a pass of the main loop fits in one frame 99.9%
of the time (5 passes in two frames), against 92% before and 39% when the
SID was also updated after every player call; a pass takes 111-117 lines on
average, IRQ included, at most 276.

## C interface (`src/sid.h`)

```c
#include "sid.h"

sid_init(rmt_song_data);   /* only while stopped; detects PAL / NTSC */
sid_play_on();             /* raster IRQ on */
/* ... */
sid_play_off();            /* IRQ off, SID silent (also done at exit) */

sid_frames      /* frames played */
sid_status      /* 1 = playing */
sid_volume[6]   /* level of the SID voices, 0..15 (4-6: second SID) */
sid_ntsc        /* 1 = NTSC machine */
sid_mute        /* bit 0..5: SID voice 1..6 kept silent */
sid_voices      /* 3, or 6 with a second SID (RMT8 build, detected) */
sid_sid2        /* address of the second SID, 0 in a mono build */
sid_ispeed      /* player calls per frame (instrument speed) */

/* last frame, for a display (src/rmtplay.c) */
sid_pokey[16]   /* POKEY registers written by the player */
sid_pokey2[16]  /* the right POKEY (RMT8) */
sid_src[6]      /* POKEY channel (0..7) of each SID voice */
sid_freq_lo[6], sid_freq_hi[6], sid_wave[6]
rmt_p_song, rmt_abeat, rmt_maxtracklen, rmt_speed   /* song position (rmtplayr.s) */
lzs_section, lzs_pos[3]   /* stream position (lzsplayr.s): section, frame in it */
```

The module symbol is `rmt_song_data` (`tools/rmt2ca65.py song.rmt song.s
_rmt_song_data`, `tools/sap2ca65.py song.sap song.s _rmt_song_data`).

## Memory and CPU

`src/rmt_cbm64.cfg` is cc65's `c64.cfg` plus:

- `RMTZP`: the player's zero page at `$22-$34` (BASIC work area). It is saved
  at start-up (constructor) and given back at exit (destructor), so BASIC finds
  its pointers again. The save buffer is in `DATA`: cc65 clears the `BSS` after
  running the constructors.
- `RMTTAB`, `SIDTAB`: page aligned tables of the player and of the SID
  frequencies.

With THESMOPHORIA the program is 16 KB (`$0801-$47A2`, song 7 KB).

CPU time of the IRQ, measured in VICE (PAL) by colouring the border: player
21–24 raster lines, POKEY→SID 18–23 lines, about 13–15% of a frame (312 lines).
On a frame with heavy player work the player alone was measured at 37 lines.
With instrument speed N (1 to 4, the RMT range) the IRQ calls the player N
times per frame and translates POKEY to SID once, after the last call.
Counted on a 6502 emulator (`../RmtSkeleton/tools/rmtplay`, cycles of the
instructions, 63 per PAL line, no badlines): `claude_3ch_mono_speed_4.rmt`
takes up to 127 of the 312 lines (player 107, POKEY→SID 21),
`mono_reference_song.rmt` of RITMO (16 bit bass at 1.79 MHz) up to 134.
Translating after every call, as before, took up to 190 and 315 lines
(more than a frame): POKEY→SID ran N times for a change heard once per frame
on the Atari, and its 24 bit division (the frequency of 16 bit, 1.79 MHz and
15 kHz channels) took 24 steps; it now takes 16, the quotient being 16 bit
(the same results: the SID registers after every call of 6144 frames of four
songs are unchanged by it).

## Checked in VICE 3.9

- `gemx.rmt` and THESMOPHORIA, PAL: the pitch content (chroma, 0.1 s steps)
  of the C64 audio against the same song played by `../RmtSkeleton/tools/rmtplay`
  (Atari player + POKEY emulation) correlates 0.65 (gemx) and 0.69
  (THESMOPHORIA), against 0.05 or less when shifted by one to three
  semitones, with the best match at a time lag of 0–0.4 s: same notes, same
  key, same tempo.
- NTSC: THESMOPHORIA correlates 0.73 with `rmtplay -n`.
- `claude_3ch.rmt` (PAL, reSID 6581): correlates 0.85 (0.83–0.94 on 10 s
  windows), against -0.07 or less when transposed. The song uses only
  channels 1-3 (written by `../RmtSkeleton/tools/song3ch.py`), so every POKEY
  channel has its own SID voice: it is the module to compare the players with.
  With 4 channel songs the quieter of channels 3 and 4 is lost (gemx: 0.67).
- `claude_3ch_fast.rmt` (same song generator, speed 4, 188 BPM): correlates
  0.80 (0.80–0.92 on 10 s windows), -0.08 or less when transposed.
- `claude_3ch_slow.rmt` (speed 8, 94 BPM, played by `build/rmtplay.prg`):
  correlates 0.89 (0.91–0.96 on 10 s windows), -0.01 or less when transposed.
- Instrument speed > 1 (`-sounddev dump`, PAL): `enchanted_lands.rmt`
  (speed 2) and `garydenise.rmt` (speed 4, from the songs of RITMO) make
  exactly 2.000 and 4.000 player calls per frame, about 156 and 78 raster
  lines apart; the SID registers of the `.rmt` (`rmtplayr.s`) and of the same
  song exported by RITMO with the Unpatched driver (`lzsplayr.s`) are the
  same at every call (5275 calls at speed 4; at speed 2 all but the first 21,
  where the SAP holds the tail of the song's last note, its loop section
  being recorded on the second pass). With the SID updated once per frame,
  checked again with `rmtplay -c64` and the SAP of RITMO 2.6-rc9: the 3 SID
  voices are the same in all 10025 frames of `garydenise.rmt`, in all but
  the first 8 of `enchanted_lands.rmt`.
- `claude_3ch_mono_speed_4.rmt` (speed 4), the SID updated once per frame:
  correlates 0.96 with `rmtplay -c64` (0.91 for the loudness), -0.06 or less
  when transposed; 0.96 with the same song when the SID was updated after
  every call.
- Recording: `x64sc -console -sound -sounddev wav -soundarg out.wav
  -sidenginemodel 256 -limitcycles N -autostart build/rmt_cbm64.d64`, at real
  speed (with `-warp` the WAV stays empty).
- Exit: after a key, `PEEK(44)` in BASIC gives 8 again (zero page back) and
  the keyboard works (IRQ vector back).
- Dual SID (`-sounddev fs`, raw samples at real speed: with `-warp` the file
  stays empty): `turrican2_rev2s.rmt` (RMT8, from the songs of RITMO) built
  with `SID2=DE00` gives an RMS of 1920 with a SID at `$DE00` in VICE and 1238
  without (the same as a build without the second SID): the right POKEY is
  heard only from the second chip. With `$D420` and one SID, `detect_sid2`
  finds the image and the right POKEY is not translated. The same song
  exported by RITMO as a stereo SAP (`lzsplayr.s`): 1926 and 1238. A mono song
  gives the same sequence of SID writes as before the dual SID code
  (`-sounddev dump`, `gemx.rmt`), and the Atari builds of RmtSkeleton and
  PokeyATest are byte for byte the same.

## Files

| File | |
|------|---|
| `src/rmtplayr.s`, `src/rmt_feat.inc` | RMT player, copied from `../RmtSkeleton/src` (keep them in sync) |
| `src/lzsplayr.s` | player of the LZSS streams of a SAP / XEX, copied from `../RmtSkeleton/src` |
| `src/sidrmt.s` | raster IRQ, PAL/NTSC, POKEY → SID, C interface |
| `src/sid.h` | C header |
| `src/main.c` | example program |
| `src/rmtplay.c` | player with visualizer (`rmtplay.sh`) |
| `rmtplay.sh` | builds `build/rmtplay.prg` for a song and runs it in x64sc |
| `tools/rmtinfo.py` | song name / author / date / length of a `.rmt` as a C header (from VERA_ATARI_PBI) |
| `src/rmt_cbm64.cfg` | linker configuration |
| `tools/rmt2ca65.py` | `.rmt` → relocatable ca65 source (copied from RmtSkeleton) |
| `tools/sap2ca65.py` | `.sap` / `.xex` → relocatable ca65 source and `songinfo.h` (copied from RmtSkeleton) |
| `tools/mksidtab.py` | SID frequency tables |
| `music/` | RMT modules; `gemx.sap`: gemx exported by RITMO (driver Patch16) |
