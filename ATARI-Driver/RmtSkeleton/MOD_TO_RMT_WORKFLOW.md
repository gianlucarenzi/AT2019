# MOD to RMT Conversion Workflow

Convert a **ProTracker MOD** (4 channels, 31 samples) into an **RMT4** module
for the Atari POKEY, listen to it on the PC with the real Atari player routine,
then put it on a disk image and run it in atari800 while files are loaded.

```
song.mod ──mod2rmt4.py──> song.rmt ──rmtplay──> PC speakers / WAV
                              │
                              └──PokeyATest make SONG=...──> .atr ──> atari800
```

Tools (all in `tools/`):

| Tool | What it does |
|------|--------------|
| `mod2rmt4.py` | MOD → RMT4, instruments built from the samples |
| `rmtplay/` | RMT player for the PC (C, SDL2): runs `src/rmtplayr.s` on a 6502 emulator with a POKEY emulation |
| `rmt2ca65.py` | checks the module and converts it for the cc65 build |
| `analyze_rmt_fixed.py` | which POKEY channels the song uses |

---

## Step 1: Look at the MOD

```bash
xmp --load-only -v music/song.mod     # samples, patterns, duration
```

Note which sample plays which role (bass, drums, melody) and on which MOD
channel. The converter prints the same information after the conversion.

## Step 2: Convert

```bash
python3 tools/mod2rmt4.py music/song.mod music/song.rmt [--map ...] [--kind ...]
```

What is converted:

- **Song order** with `Bxx` (position jump, becomes the RMT song loop) and `Dxx`
  (pattern break).
- **Notes and volume**: the sample default volume or `Cxx`, 0..64 → RMT note volume 0..15.
- **Speed**: the MOD speed at 125 BPM is the RMT speed (one line = *speed* frames
  at 50 Hz); other BPM values are scaled.
- **Instruments**: one RMT instrument per (sample, period) pair, made from the sample:
  - volume envelope = RMS of the sample, frame by frame (1/50 s) at the playback
    rate of that note, normalised on the loudest sample (up to 48 frames);
  - sound, by kind of sample (detected automatically, override with `--kind`):

| Kind | POKEY sound |
|------|-------------|
| `bass` | tonal below 125 Hz: distortion C (poly4) with the player's bass tables, note chosen from the pitch measured on the sample |
| `tone` | tonal from 125 Hz: pure tone table |
| `kick` | distortion C pitch sweep (`--kick-sweep HI LO`, default 110 → 40 Hz) |
| `noise` | poly17 noise, AUDF per frame from the spectral centroid of the sample |

Not converted, and listed in the report: the other effects (slides,
portamento, vibrato, arpeggio, ...).

Options:

| Option | Meaning |
|--------|---------|
| `--map 3:1,4:2,...` | route sample → RMT channel (1-4); unlisted samples keep their MOD channel |
| `--kind 4:kick,...` | force the kind of a sample |
| `--kick-sweep HI LO` | kick pitch sweep in Hz |
| `--addr 0x4000` | load address of the module (rmt2ca65 relocates it anyway) |

**Channel routing.** While the Atari loads from disk, channels 3+4 are the
serial baud rate generator and only **channels 1+2** keep playing. Route the
voices that must survive a loading screen to channels 1 and 2 with `--map`.

The pitch of a sample is measured by autocorrelation for every note it plays;
`f0 × period` is the same for all notes, so the median over the notes discards
octave errors. The noise AUDF comes from a calibration table measured with the
POKEY emulation of `rmtplay`.

## Step 3: Listen on the PC

```bash
make -C tools/rmtplay                 # needs gcc, cc65, SDL2 (libsdl2-dev)
tools/rmtplay/rmtplay music/song.rmt              # play, Ctrl+C to stop
tools/rmtplay/rmtplay -io 4 music/song.rmt        # toggle "disk loading" every 4 s
tools/rmtplay/rmtplay -t 40 -w song.wav music/song.rmt   # render 40 s to WAV
tools/rmtplay/rmtplay -r music/song.rmt           # dump POKEY registers per frame
```

`rmtplay` runs `src/rmtplayr.s` (the same code as PokeyATest) assembled by ca65,
once per frame like the Atari VBI. Its POKEY writes are the same as the Atari
build: with `gemx.rmt`, 646 frames compared with `atari800 -pokeyrec` running
`build/rmtskeleton.com` were identical. `-io` does what `rmt_io_begin()` and the
SIO do (channels 3/4 muted, `AUDCTL=$28`), so you hear the song as it sounds
during a loading.

Check the module for the Atari build:

```bash
python3 tools/rmt2ca65.py music/song.rmt /dev/null    # RMT4, relocations, instr speed 1
python3 tools/analyze_rmt_fixed.py music/song.rmt     # channels used
```

## Step 4: Run it on the Atari while loading from disk

PokeyATest builds a disk that plays the song and loads, verifies and reloads
files forever:

```bash
cd ../PokeyATest
make clean
make SONG=../RmtSkeleton/music/song.rmt
make run SONG=../RmtSkeleton/music/song.rmt     # atari800 -nopatchall
```

Pass `SONG=` to `make run` too: without it the disk is rebuilt with `gemx.rmt`.
The test is good if the screen shows `ERR 0`, `RETRY 0` and `lost 0`.

To use the song in your own program, see `INTEGRATION_GUIDE.md`
(`make SONG=music/song.rmt` in this skeleton).

## Optional: refine in Raster Music Tracker

The `.rmt` file opens in Raster Music Tracker (Windows, or Wine), where the
instruments can be tuned by ear: envelopes, distortion, AUDF tables,
vibrato, filters. Save as RMT4 mono, instrument speed 1, and check it again
with `rmt2ca65.py`.

What a conversion cannot do: POKEY does not play samples, the timbre is
rebuilt from square waves and noise. Rhythm, pitch and dynamics are kept;
the sound is the Atari version of the song.

---

## Example: PROJECT-X_LOADER.MOD

```bash
python3 tools/mod2rmt4.py music/PROJECT-X_LOADER.MOD music/PROJECT-X_LOADER_pokey.rmt \
        --map 3:1,4:2,5:3,1:4,2:4 --kind 4:kick
```

| RMT channel | MOD sample | Conversion |
|-------------|------------|------------|
| 1 | 3 `vbass` | bass, distortion C bass2, notes A#0 C#1 E1 G1 C2 (29-66 Hz, within 20 cents) |
| 2 | 4 `flabbyrm` | kick, distortion C sweep 110 → 40 Hz |
| 3 | 5 `hipopsht` | snare, poly17 noise, AUDF 7-15 |
| 4 | 1 `wetrandm`, 2 `sweethat` | closed / open hi-hat, poly17 noise, AUDF 0 |

Result: 1432 bytes, 11 instruments, 12 tracks, speed 6, loop to pattern 1
(the `B01` of the MOD). During disk loading bass and kick keep playing.
In atari800 with PokeyATest, channels 1+2 matched `rmtplay` frame by frame
while loading, except single frames written one frame late (ticks postponed
by the VBI, the `late` counter), with no drift of the tempo.

## Older tools

`mod2rmt.py`, `mod2rmt_fixed.py`, `mod_to_rmt_via_wav.py`,
`mod_to_rmt_extractor.py` and `mod_extractor.py` are earlier experiments;
several `music/PROJECT-X_LOADER_*.rmt` files they produced have no `$FFFF`
header and are rejected by `rmt2ca65.py`. `tools/rmt_player` is a binary without
its source (`Makefile.rmt_player` refers to a missing `rmt_player.c`) and needs
GLIBC 2.34. Use `mod2rmt4.py` and `rmtplay` instead.
