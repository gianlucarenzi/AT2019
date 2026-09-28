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
- **Volume changes without a new note** become RMT volume events (the note is not
  retriggered): `Cxx`, a sample number alone, `Axy` volume slide (and the slide of
  `5xy`/`6xy`, one step per row), `EAx`/`EBx` fine slides, `ECx` note cut.
- **Speed**: `Fxx` anywhere in the song becomes an RMT speed event; the MOD speed at
  125 BPM is the RMT speed (one line = *speed* frames at 50 Hz), other BPM values
  are scaled.
- **Vibrato** (`4xy`, `6xy`): the note uses a copy of the instrument with the RMT
  vibrato (smallest type), when there is room for it.
- **Tone portamento** (`3xx`, `5xy`): approximated, the target note is played at once.
- **Instruments**, made from the sample:
  - volume envelope = RMS of the sample, frame by frame (1/50 s) at the playback
    rate of the note, normalised on the loudest sample (up to 48 frames);
    a looped sample holds its last frame until the next note (sustain);
  - sound, by kind of sample (override with `--kind`):

| Kind | POKEY sound |
|------|-------------|
| `bass` | tonal below 125 Hz: distortion C (poly4) with the player's bass tables, note chosen from the pitch measured on the sample |
| `tone` | tonal from 125 Hz: pure tone table (notes outside the table are moved by octaves) |
| `kick` | distortion C pitch sweep (`--kick-sweep HI LO`, default 110 → 40 Hz) |
| `noise` | poly17 noise, AUDF per frame from the spectral centroid of the sample |

  - one instrument per (sample, period) when it fits in the 64 RMT instruments;
    otherwise tonal samples get one instrument per distortion table (the note is
    in the track), then noise periods are grouped by octave, then the vibrato
    copies are dropped. The report shows the grouping level used.

**Kind of a sample.** First the sample name: words starting or ending with
`bassdrum`/`kick` → kick, `hat`/`snare`/`crash`/`cymbal`/`ride`/`rim`/`clap`/
`lazer`/`cheer`/... → noise, `bass` → bass. Otherwise the analysis: the pitch
(normalised square difference function, peaks only after its first zero
crossing) must be clear and the spectrum not flat, or the sample is noise.
The report lists the kind of every sample and why; check it and fix wrong ones
with `--kind`.

Not converted, and listed in the report: arpeggio (`0xy`), pitch slides
(`1xx`/`2xx`, `E1x`/`E2x`), tremolo, sample offset, retrigger (`E9x`); a
note delay (`EDx`) is played at the start of the row.

Options:

| Option | Meaning |
|--------|---------|
| `--map 3:1,4:2,...` | route sample → RMT channel (1-4); unlisted samples keep their MOD channel |
| `--kind 4:kick,...` | force the kind of a sample |
| `--kick-sweep HI LO` | kick pitch sweep in Hz |
| `--transpose 7:-12,...` | move a tonal sample by semitones |
| `--tuning measured\|c` | pitch from the analysis (default) or C-tuned samples |
| `--addr 0x4000` | load address of the module (rmt2ca65 relocates it anyway) |

**Channel routing.** While the Atari loads from disk, channels 3+4 are the
serial baud rate generator and only **channels 1+2** keep playing. Route the
voices that must survive a loading screen to channels 1 and 2 with `--map`.

**Pitch and octave.** Every tonal sample gets one sound (pure tone or
distortion C) and one octave shift for all its notes, chosen for the smallest
total pitch error, so a melody keeps its shape and its timbre. Distortion C
notes pick, one by one, the closer of the two bass tables (same sound). Notes
that still fall outside the tables are moved by octaves one by one. The report
shows, per instrument, the maximum error and how many notes are off by more
than 30 and 50 cents. `--transpose sample:semitones` moves a sample;
`--tuning c` assumes C-tuned samples (off by default: the Project-X samples are
tuned to G, F, E, B♭... and their measured pitch is right).

The pitch of a sample is measured for every note it plays;
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

**Memory.** The test program keeps the song and a load buffer as large as the
biggest asset (16 KB by default) in RAM from `$2000` up to `$B420` (`$BC20`
minus the 2 KB cc65 stack). Song + biggest asset can take about **28 KB**
(28390 bytes with the current program): with the default 16 KB buffer the song
can be up to about 12 KB. For a bigger song leave the 16 KB test asset out;
the linker otherwise stops with "Segment 'BSS' overflows memory area 'MAIN'".
End-Lynne (15316 bytes) runs with a 12 KB buffer:

```bash
make clean
make run SONG=../RmtSkeleton/music/ProjectX-End-Lynne_pokey.rmt \
         ASSET_SIZES="2048 3500 5120 8000 12288"
```

In atari800 (PAL, `-nopatchall`) End-Lynne kept playing on channels 1+2 while
loading 75% of the time; compared with `rmtplay` over 141 s, channels 1+2
matched except 70 single frames written one frame late (postponed ticks),
channels 3/4 stayed at volume 0 during every transfer.
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

## Results: the Project-X MODs

All converted with the default options (no `--map`, MOD channels kept), except
LOADER (see above):

| Module | Length | RMT size | Instr. | Notes | Kinds to know |
|--------|--------|----------|--------|-------|---------------|
| `PROJECT-X_THESMOPHORIA_pokey.rmt` | 7:24 | 7126 | 17 | 3357 | 172 tone portamentos approximated |
| `PROJECT-X_BLADSWEDE_REMIX_pokey.rmt` | 4:36 | 7656 | 39 | 5722 | 93 pitch slides not converted |
| `PROJECT-X_CONGRATULATIONS_pokey.rmt` | 0:20 | 1076 | 6 | 34 | the MOD plays long orchestral samples (1812 overture): POKEY can only give a rough idea |
| `ProjectX-End-Lynne_pokey.rmt` | 6:24 | 15316 | 58 | 4837 | 836 tone portamentos approximated, speed 7 and 15 |
| `ProjectXSE_pokey.rmt` | 4:28 | 8070 | 38 | 5530 | 78 pitch slides not converted |

Checked on the player running in `rmtplay`'s 6502 emulator: every note of every
song starts in the frame where the MOD row falls (speed changes and pattern
breaks included), and the channel volume matches the MOD at every row.

## Older tools

`mod2rmt.py`, `mod2rmt_fixed.py`, `mod_to_rmt_via_wav.py`,
`mod_to_rmt_extractor.py` and `mod_extractor.py` are earlier experiments;
several `music/PROJECT-X_LOADER_*.rmt` files they produced have no `$FFFF`
header and are rejected by `rmt2ca65.py`. `tools/rmt_player` is a binary without
its source (`Makefile.rmt_player` refers to a missing `rmt_player.c`) and needs
GLIBC 2.34. Use `mod2rmt4.py` and `rmtplay` instead.
