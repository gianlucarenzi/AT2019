# RMT CBM64 – RMT modules on the Commodore 64 SID

Plays **RMT4** modules (Raster Music Tracker, Atari POKEY) on a Commodore 64.

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
   The KERNAL CIA IRQ (keyboard, clock) keeps running. PAL (50 Hz) or NTSC
   (60 Hz) is detected from the number of raster lines.
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

## Build

Requirements: **cc65** (`cl65`), **python3**, **c1541** and **x64sc** from VICE.

```bash
make                                   # build/rmt_cbm64.prg, build/rmtplay.prg and their D64s
make SONG=music/PROJECT-X_THESMOPHORIA_pokey.rmt
make run                               # x64sc -autostart build/rmt_cbm64.d64
make clean
```

`SONG` is any RMT4 module with instrument speed 1 (`python3 tools/rmt2ca65.py
file.rmt /dev/null` checks it). Songs in `music/`: `gemx.rmt` (default),
`PROJECT-X_LOADER_pokey.rmt`, `PROJECT-X_THESMOPHORIA_pokey.rmt`,
`ProjectX-End-Lynne_pokey.rmt` (15 KB; the D64 loads in about a minute on a
real-speed 1541), `claude_3ch.rmt` and `claude_3ch_fast.rmt` (channels 1-3 only, see below). `D64=build/other.d64` writes the disk under another name.
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
VICE_OPTS="-ntsc" ./rmtplay.sh song.rmt      # extra x64sc options (default -pal)
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
(the program goes straight into RAM); `build/rmtplay.d64` holds the program
(`RMTPLAY`) for a real C64. The play time is counted from the IRQ frames.
The screen work (bars every frame, the other fields every other frame, a
field written only when it changes) fits in the time the player IRQ leaves
in a frame, PAL and NTSC: checked in VICE by colouring the border, about 150
raster lines in the heaviest frame with the IRQ.

## C interface (`src/sid.h`)

```c
#include "sid.h"

sid_init(rmt_song_data);   /* only while stopped; detects PAL / NTSC */
sid_play_on();             /* raster IRQ on */
/* ... */
sid_play_off();            /* IRQ off, SID silent (also done at exit) */

sid_frames      /* frames played */
sid_status      /* 1 = playing */
sid_volume[3]   /* level of the 3 SID voices, 0..15 */
sid_ntsc        /* 1 = NTSC machine */
sid_mute        /* bit 0..2: SID voice 1..3 kept silent */

/* last frame, for a display (src/rmtplay.c) */
sid_pokey[16]   /* POKEY registers written by the player */
sid_src[3]      /* POKEY channel of each SID voice */
sid_freq_lo[3], sid_freq_hi[3], sid_wave[3]
rmt_p_song, rmt_abeat, rmt_maxtracklen, rmt_speed   /* song position (rmtplayr.s) */
```

The module symbol is `rmt_song_data` (`tools/rmt2ca65.py song.rmt song.s
_rmt_song_data`).

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
- Recording: `x64sc -console -sound -sounddev wav -soundarg out.wav
  -sidenginemodel 256 -limitcycles N -autostart build/rmt_cbm64.d64`, at real
  speed (with `-warp` the WAV stays empty).
- Exit: after a key, `PEEK(44)` in BASIC gives 8 again (zero page back) and
  the keyboard works (IRQ vector back).

## Files

| File | |
|------|---|
| `src/rmtplayr.s`, `src/rmt_feat.inc` | RMT player, copied from `../RmtSkeleton/src` (keep them in sync) |
| `src/sidrmt.s` | raster IRQ, PAL/NTSC, POKEY → SID, C interface |
| `src/sid.h` | C header |
| `src/main.c` | example program |
| `src/rmtplay.c` | player with visualizer (`rmtplay.sh`) |
| `rmtplay.sh` | builds `build/rmtplay.prg` for a song and runs it in x64sc |
| `tools/rmtinfo.py` | song name / author / date / length of a `.rmt` as a C header (from VERA_ATARI_PBI) |
| `src/rmt_cbm64.cfg` | linker configuration |
| `tools/rmt2ca65.py` | `.rmt` → relocatable ca65 source (copied from RmtSkeleton) |
| `tools/mksidtab.py` | SID frequency tables |
| `music/` | RMT modules |
