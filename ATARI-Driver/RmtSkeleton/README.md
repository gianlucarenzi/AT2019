# RmtSkeleton – Minimal RMT Player Template

A bare-bones cc65 project showing how to integrate the **Raster Music Tracker** player into your own programs.

This is **not** a complete game or demo – it's a reference skeleton that shows:
- The minimal file structure
- How to configure the linker
- How to set up the Makefile
- A simple main.c example
- How the player shares POKEY with disk I/O (SIO)

**Use this as a template** for your own cc65 projects that need background music.

The player is the one of `../PokeyATest`, where it has been tested while loading
files from disk. The skeleton itself does no disk I/O: for the asset loader see
PokeyATest (`src/sio.s`, `src/dos2fs.c`).

## Project Structure

```
RmtSkeleton/
├── Makefile              build automation
├── README.md             this file
├── src/
│   ├── main.c            your program (shows basic API usage)
│   ├── rmtskeleton.cfg   linker configuration (key: RMTTAB align=$100)
│   ├── rmtplayr.s        RMT player (from PokeyATest) - DO NOT MODIFY
│   ├── rmtvbi.s          VBI handler and C interface - DO NOT MODIFY
│   ├── rmt.h             C header with API
│   └── rmt_feat.inc      RMT feature switches - DO NOT MODIFY
├── tools/
│   ├── rmt2ca65.py       converts .rmt files to relocatable ca65 source
│   ├── mod2rmt4.py       converts a ProTracker MOD to RMT4 (MOD_TO_RMT_WORKFLOW.md)
│   ├── song3ch.py        writes music/claude_3ch.rmt (original song, channels 1-3 only)
│   └── rmtplay/          RMT player for the PC (C, SDL2) running src/rmtplayr.s
├── music/
│   ├── gemx.rmt          example RMT song (replace with your own)
│   └── claude_3ch.rmt    3 channel song (channel 4 silent): same on POKEY and C64 SID
└── build/                generated files (ignored by git)
    ├── rmtskeleton.com   the final executable
    ├── rmtskeleton.map   linker map
    └── song.s            generated from .rmt file
```

## Files from PokeyATest

These files are copied from `../PokeyATest` and should not be modified:
- `src/rmtplayr.s` – the RMT 1.20090108 player in ca65 (mono, 4 channels)
- `src/rmtvbi.s` – VBI handler and C wrapper
- `src/rmt.h` – C API (used by main.c)
- `src/rmt_feat.inc` – feature switches (all enabled)
- `tools/rmt2ca65.py` – converts .rmt to relocatable ca65

If you update PokeyATest, re-copy these files to stay in sync. `rmtplayr.s` is
also used by `../rmt_cbm64` (Commodore 64): assembled there with `-D RMT_C64` it
writes the POKEY registers to RAM instead of `$D200`; without that define it is
the Atari code, unchanged.

## Building

### Prerequisites
- **cc65** (ca65 assembler, cl65 linker)
- **python3** (for rmt2ca65.py)
- Optionally: **atari800** emulator (to run the program)

### Compile

```bash
make                # build build/rmtskeleton.com
make run            # build and run in atari800 (-nopatchall)
make clean          # remove build artifacts
```

### Use a Different Song

```bash
make SONG=music/your_song.rmt
```

The Makefile automatically:
1. Converts `your_song.rmt` → `build/song.s` (relocatable source)
2. Assembles and links everything
3. Outputs `build/rmtskeleton.com`

To verify a .rmt file is compatible before building:

```bash
python3 tools/rmt2ca65.py music/your_song.rmt /dev/null
```

This shows the file size, relocations, and instrument speed. **Instrument speed must be 1.**

### Listen on the PC: tools/rmtplay

`rmtplay` is an RMT player for the PC (Linux, C + SDL2). It runs the same
player routine as the Atari build (`src/rmtplayr.s`) on a 6502 emulator, with a
POKEY emulation, so a song sounds as it will on the Atari.

**Requirements**

- `gcc` and `make`
- **cc65** (`ca65`, `ld65`): the player is assembled from the Atari source
- **SDL2** development files, with `sdl2-config` (Debian/Ubuntu: `sudo apt install libsdl2-dev`)

**Build** (from the `RmtSkeleton` directory)

```bash
make -C tools/rmtplay          # builds tools/rmtplay/rmtplay
make -C tools/rmtplay clean    # removes the binary and tools/rmtplay/build/
```

The Makefile:

1. assembles `src/rmtplayr.s` (with `src/rmt_feat.inc`) with `ca65`;
2. links it at a fixed address (`tools/rmtplay/rmtplay.cfg`, `$A000`) with `ld65`
   into a raw 6502 binary;
3. turns the binary and the player entry points into `build/rmtplayr_bin.h`;
4. compiles `rmtplay.c`, `cpu6502.c` and `pokey.c` with SDL2.

A change to `src/rmtplayr.s` or `src/rmt_feat.inc` is picked up by the next
`make`. The binary and `build/` are not in git: build again after a clone.

**Usage**

```bash
tools/rmtplay/rmtplay music/your_song.rmt                  # play, Ctrl+C to stop
tools/rmtplay/rmtplay -t 60 music/your_song.rmt            # stop after 60 s
tools/rmtplay/rmtplay -io 4 music/your_song.rmt            # toggle "disk loading" every 4 s
tools/rmtplay/rmtplay -t 40 -w song.wav music/your_song.rmt   # render 40 s to a WAV file
tools/rmtplay/rmtplay -r music/your_song.rmt               # POKEY registers, one line per frame
tools/rmtplay/rmtplay -n music/your_song.rmt               # NTSC (60 Hz) instead of PAL
```

With `-io` only channels 1+2 play, as between `rmt_io_begin()` and
`rmt_io_end()`. With `-r` the last column is AUDCTL: for a song meant to play
during disk loading it should stay `00`. The module must not overlap the
player at `$A000-$B7FF` (RMT files load at `$4000` as a rule).

To convert a MOD file see `MOD_TO_RMT_WORKFLOW.md`.

### A song on 3 channels: tools/song3ch.py

`music/claude_3ch.rmt` is an original song written by `tools/song3ch.py`
(`python3 tools/song3ch.py music/claude_3ch.rmt`): A minor, speed 6, 8 song
lines (about 61 s, loops to line 2). Channel 1 lead (pure tone, vibrato),
channel 2 bass (distortion C), channel 3 drums and arpeggio chord stabs;
**channel 4 is always silent**. It is the common test song for every player
of this tree: the C64 SID (`../rmt_cbm64`) has only 3 voices and plays it with
nothing left out, and on the Atari lead and bass keep playing during disk
loading. Rendered by `rmtplay` and by the C64 player in VICE, the pitch
content correlates 0.85 (0.67 for `gemx.rmt`, which uses 4 channels). Melody,
chords and instruments are plain data at the top of the script.

## API Overview (C Interface)

See `src/rmt.h` for the full interface. Basic usage:

```c
#include "rmt.h"

// Initialize the player (do this BEFORE attaching to VBI)
rmt_init(rmt_song);

// Attach to the immediate VBI (music starts)
rmt_vbi_on();

// ... your program runs here ...

// Bracket every disk access (SIO) while music plays
rmt_io_begin();          // player leaves channels 3+4 and AUDCTL to the SIO
// ... do your SIO operation ...
rmt_io_end();            // next VBI the player drives all 4 channels again

// Stop the player (silence POKEY)
rmt_vbi_off();
```

Diagnostics (updated every VBI by the player):

```c
rmt_frames   // VBI counter
rmt_lines    // duration of last player call (scanlines)
rmt_maxlines // worst-case player time
rmt_deferred // ticks postponed and caught up later (normal)
rmt_dropped  // ticks lost (must be 0 - indicates a problem)
rmt_audc[4]  // AUDC values for channels 1..4 (for VU meter)
```

## POKEY Channels and Disk I/O

During a SIO transfer POKEY channels 3+4, joined as a 16 bit counter clocked at
1.79 MHz (`AUDCTL = $28`), are the **baud rate generator** of the serial port.
The player therefore works in two modes:

```
Normal (no I/O)                     During I/O (rmt_io_begin .. rmt_io_end)
─────────────────────────────       ─────────────────────────────────────────
CH1+2: RMT music                    CH1+2: RMT music (unchanged)
CH3+4: RMT music                    CH3+4: serial baud rate (muted, volume 0)
AUDCTL: set by the song             AUDCTL: $28, set by the SIO
```

- **Channels 1+2 always belong to the music**, even while loading.
- **Channels 3+4 belong to the music when no I/O is running**, and to the SIO
  between `rmt_io_begin()` and `rmt_io_end()`.
- During I/O the player still computes all 4 channels, so the song stays in time:
  it only skips the writes to `AUDF3`, `AUDC3`, `AUDF4`, `AUDC4` and `AUDCTL`.
- `rmt_io_begin()` sets `AUDC3`/`AUDC4` to 0 right away, otherwise the last music
  volume would stay on while the SIO reprograms `AUDF3`/`AUDF4` (an audible whine).
  Loading is silent.
- After `rmt_io_end()` the next VBI rewrites all 4 channels and `AUDCTL`: the music
  goes back to 4 voices without any other call.

### Composing for loading screens

What you hear during a transfer is the song minus channels 3 and 4:

- Put melody and the main voices on **channels 1 and 2**; bass and drums on 3/4
  will pause while loading.
- A song that uses only channels 1+2 sounds identical during loading.
- If the song uses `AUDCTL` for channels 1/2 (1.79 MHz clock, 16 bit, 15 kHz,
  filters), during I/O the serial `AUDCTL` (`$28`) applies, so those voices can
  change timbre or pitch. Channels 1/2 in "normal" 64 kHz mode are not affected.

See `FIND_2CHANNEL_SONGS.md` for how to check which channels a song uses.

### Sound effects

The player writes all 4 channels every frame when no I/O is running, so it does
**not** leave channels 3+4 free for sound effects: anything you write there from
your program is overwritten at the next VBI. See `SFX_INTEGRATION.md` for what
would be needed.

## Supported Modules

- **RMT4 mono only** (4 channels, single POKEY)
  - RMT8 stereo modules are rejected by rmt2ca65.py
- **Instrument speed 1 only** (player called once per frame)
  - Speed > 1 plays slower than intended
  - rmt2ca65.py warns about this
- Both "stripped" modules and modules with song/instrument names work
  (the second block of the file is ignored)

## Key Implementation Details

### Why Immediate VBI?

The player runs in the **immediate VBI** (`VVBLKI`), not the deferred one. Why?

- During SIO operations, the OS sets `CRITIC` and **skips the deferred VBI** (`VVBLKD`).
- Only the immediate VBI always runs, so music keeps playing while loading.

### IRQ Handling

The player re-enables IRQs (`CLI`) while running so the serial port (SIO) doesn't starve:
- Data arrives at ~930 CPU cycles per byte at 19200 baud
- The player can take 10–40 scanlines; with IRQs masked, bytes would be lost

But `CLI` is only safe if the interrupted code had I=0 (IRQs enabled). If the VBI hits inside an IRQ handler, the tick is **postponed** and run later from the IRQ tail (`rmt_irqtick`) or the next frame (`rmt_deferred` counter). The song tempo stays correct.

### Which loader?

The OS `SIOV` is **not** safe with the player on the VBI: after the drive
"Complete" byte the OS re-enables the serial IRQ from main code, and if the VBI
runs there the first data byte is lost (sector shifted by one byte, sometimes
with status OK). PokeyATest measured ~70% failed files with `SIOV` and 0 errors
with its own IRQ driven loader (`rbl_read_sector` in `PokeyATest/src/sio.s`).
Use that loader, or one that receives the whole sector inside the IRQ handler.

### Memory Layout

Measured from `build/rmtskeleton.map`:
- **19 bytes of zero page** (in cc65's `ZEROPAGE` segment)
- **638 bytes of page-aligned tables** in `RMTTAB` segment (aligned to $100)
- **~170 bytes of variables** in `BSS` segment
- **~1.6 KB of code** (self-modifying, must be in RAM)
- **Module size** (varies; `gemx.rmt` is 3727 bytes)

## Linker Configuration (`rmtskeleton.cfg`)

The key difference from a standard cc65 config:

```
SEGMENTS {
    ...
    RMTTAB:    load = MAIN, type = ro, align = $100;  ← IMPORTANT
    STARTUP:   load = MAIN, type = ro, define = yes;
    ...
}
```

The `align = $100` ensures the player tables start at a page boundary. Putting
`RMTTAB` first in `MAIN` places it at `$2000` without wasting padding.

## Adapting for Your Project

1. **Copy the entire RmtSkeleton directory** as a starting point for your project.

2. **Replace `music/gemx.rmt`** with your own RMT song:
   ```bash
   cp your_song.rmt music/
   make SONG=music/your_song.rmt
   ```

3. **Update `src/main.c`** with your game/program logic. The RMT API calls are:
   - `rmt_init(rmt_song)` once at startup
   - `rmt_vbi_on()` to start music
   - `rmt_io_begin()` / `rmt_io_end()` around disk operations
   - `rmt_vbi_off()` at cleanup (never during a transfer)

4. **Update `src/rmtskeleton.cfg`** if you add more code segments.

5. **Update the Makefile** with your own C/ASM source files.

6. **Keep the RMT player files unchanged**: `rmtplayr.s`, `rmtvbi.s`, `rmt.h`, `rmt_feat.inc`.

## Troubleshooting

### The music skips or sounds wrong

- Check `rmt_dropped`: if it's > 0, the player is losing ticks and the song tempo is wrong
  - Usually caused by other code or IRQ handlers taking too long
  - Long IRQ handlers can call `jsr rmt_irqtick` at their end (see PokeyATest `sio.s`)

- Check `rmt_maxlines`: if it's > ~60 scanlines, the player is running long
  - This is a diagnostic; it doesn't prevent music, but indicates tight timing

### Linker errors: "symbol rmt_song not defined"

- The `build/song.s` file wasn't generated
- Make sure `music/gemx.rmt` (or your SONG file) exists
- Run `make clean && make` to rebuild

### .rmt file is rejected

- Make sure it's **RMT4 mono**, not RMT8 stereo
- Instrument speed must be 1
- Test with: `python3 tools/rmt2ca65.py music/your.rmt /dev/null`

## Related Documentation

- Full PokeyATest guide: `../PokeyATest/doc/GUIDA.md` (Italian, very detailed)
- Asset loader example: `../PokeyATest/src/main.c`
- cc65 documentation: https://cc65.github.io/

## License and Attribution

- **RMT player**: Radek Sterba (Raster/C.P.U.), ported to ca65
- **This skeleton**: based on PokeyATest by RetroBitLab
- **cc65**: https://cc65.github.io/ (distributed under zlib license)

---

**Ready to add music to your Atari program?** Start editing `src/main.c`!
