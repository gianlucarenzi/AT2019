# RMT CBM64 – Commodore 64 RMT Player

## Overview

**RMT CBM64** is a complete cc65 project for playing **RMT music files** on a **Commodore 64** with the **SID chip**.

This project demonstrates a **cross-platform audio strategy**: A generic **3-channel RMT format** that plays on both:

- **Commodore 64** (SID: 3 polyphonic voices)
- **ATARI 8-bit** (POKEY: 4 channels, 1 reserved for SIO)

## Quick Start

### Prerequisites

```bash
sudo apt install cc65 python3 vice
```

- **cc65**: C compiler and assembler for 6502
- **python3**: For RMT conversion tool
- **vice**: Commodore 64 emulator (optional, for testing)

### Build

```bash
cd rmt_cbm64
make                    # Build rmt_cbm64.prg
make run                # Build and run in VICE
make SONG=music/your.rmt # Use different song
make clean              # Remove build artifacts
```

## Project Structure

```
rmt_cbm64/
├── 00-START-HERE.txt         Quick reference
├── README.md                 This file
├── Makefile                  Build automation
├── src/
│   ├── main.c               C64 program template
│   ├── sid.h                C API header
│   ├── sidplayer.s          SID player core (RMT engine)
│   ├── sidvbi.s             CIA1 IRQ handler
│   └── rmt_cbm64.cfg        Linker configuration
├── tools/
│   └── rmt2cbm64.py         RMT→ca65 converter
├── music/
│   └── example.rmt          Example 3-channel RMT song
└── build/                   Generated files (ignored)
    ├── rmt_cbm64.prg        Final executable
    ├── rmt_data.s           Generated from .rmt
    └── *.o                  Object files
```

## C API

### Initialization

```c
#include "sid.h"

// Initialize the SID player with an RMT module
sid_init(rmt_song_data);

// Start playback (attaches to CIA1 Timer A)
sid_play_on();

// Stop playback and silence SID
sid_play_off();
```

### Diagnostic Counters

```c
extern volatile unsigned int   sid_frames;    // Frame counter (incremented ~50 Hz)
extern volatile unsigned char  sid_status;    // 0=idle, 1=playing
extern volatile unsigned char  sid_volume[3]; // Volume for each voice
```

## RMT File Conversion

### Scenario 1: You have a 3-channel RMT (ready to use)

```bash
cp your_3ch_song.rmt music/
make SONG=music/your_3ch_song.rmt
```

### Scenario 2: You have a 4-channel ATARI RMT

```bash
# Verify it's convertible
python3 tools/rmt2cbm64.py your_4ch_song.rmt /dev/null

# Use it (player will auto-merge channels 3+4)
make SONG=music/your_4ch_song.rmt
```

## Cross-Platform Audio Design

### Why 3 Channels?

The SID chip has exactly 3 polyphonic voices, making 3-channel RMT files optimal:

```
┌─────────────────┬──────────────────────┐
│  SID (C64)      │   POKEY (ATARI)      │
├─────────────────┼──────────────────────┤
│ Voice 1         │ Channel 1 (Melody)   │
│ Voice 2         │ Channel 2 (Harmony)  │
│ Voice 3         │ Channel 3 (Bass)     │
│ ---             │ Channel 4 [Reserved] │
└─────────────────┴──────────────────────┘
```

**On ATARI**: Channel 4 is reserved for SIO (disk I/O) baud rate, so using 3 channels avoids glitches during disk loading.

**On C64**: All 3 voices are fully available for music.

### Practical Example

Playing the same RMT module on both platforms:

**C64 (SID)**:
```
3-channel full stereo + digital effects available
```

**ATARI (during disk loading)**:
```
3-channel music continues uninterrupted
Channels 3+4 silenced (used by SIO)
```

Result: **Zero audio glitches** during load, professional game feel.

## Building a C64 Program with RMT

### Step 1: Copy the skeleton

```bash
cp -r rmt_cbm64 my_game
cd my_game
```

### Step 2: Add your RMT song

```bash
cp my_song.rmt music/
make SONG=music/my_song.rmt
```

### Step 3: Customize main.c

Edit `src/main.c` to add your game logic:

```c
#include "sid.h"

int main(void) {
    sid_init(rmt_song_data);
    sid_play_on();
    
    // Your game code here
    game_loop();
    
    sid_play_off();
    return 0;
}
```

## Implementation Notes

### SID Player Components

- **sidplayer.s**: Core RMT playback engine
  - Parses 3-channel RMT format
  - Converts RMT instruments to SID waveforms
  - Outputs to $D400-$D41F (SID registers)

- **sidvbi.s**: CIA1 Timer A IRQ handler
  - Generates ~50 Hz IRQ (PAL)
  - Calls player at correct tempo
  - Updates diagnostic counters

- **sid.h**: C interface
  - `sid_init()` - Initialize
  - `sid_play_on()` - Start
  - `sid_play_off()` - Stop

### CIA1 Timer Configuration

The player uses **CIA1 Timer A** for timing:

```
PAL C64:  50 Hz  (20 ms per tick)
         CPU: 985,248 Hz
         Divide by 19,700 ≈ 50 Hz
```

The timer runs continuously and generates IRQs that trigger the player.

### Memory Layout (C64)

```
$0000-$00FF    Zero page (cc65 + player variables)
$0100-$01FF    Stack
$0200-$07FF    Free space / BASIC area (disabled)
$0800-$9FFF    Program + music data + RMT player (~40 KB)
$A000-$BFFF    BASIC ROM (disabled)
$C000-$CFFF    Character ROM (disabled)
$D000-$DFFF    I/O area (SID at $D400-$D41F)
$E000-$FFFF    Kernal ROM
```

## Troubleshooting

### "Error: Invalid RMT file format"

The input file isn't a valid RMT. Verify:

```bash
# Check header (should show "✓ RMT Header found")
python3 tools/rmt2cbm64.py your_song.rmt /dev/null

# File should start with 0xFF 0xFF
xxd -l 16 your_song.rmt
```

### Linker error: "undefined symbol rmt_song_data"

The RMT song wasn't converted. Make sure `music/example.rmt` exists:

```bash
ls -la music/
make clean
make
```

### Music doesn't play

1. Check if SID is being silenced properly by `sid_play_off()`
2. Verify CIA1 Timer A is installed (check in VICE debugger)
3. Ensure IRQ handler is being called (add debug output)

### Different playback speed on emulator vs real C64

Some emulators don't accurately emulate CIA timing. Use **VICE** with cycle-exact mode for best results.

## Related Documentation

- **RmtSkeleton**: ATARI 8-bit version at `../RmtSkeleton/`
- **PokeyATest**: Full RMT documentation at `../PokeyATest/`
- **cc65 docs**: https://cc65.github.io/
- **VICE manual**: http://vice-emu.sourceforge.net/

## File Format: Generic 3-Channel RMT

### RMT Header (Standard)

```
Offset  Size    Description
------  ----    -----------
0       2       Magic: $FFFF
2       1       Format version
3       1       Flags
4       2       Unknown
6       1       Number of samples
7       1       Number of instruments
8       1       Channels (3 for generic, 1-4 for ATARI)
9+      ...     Instrument and pattern data
```

### Channels

```
Channel 1: Melodic voice (lead, bass, main)
Channel 2: Harmonic voice (chords, counterpoint)
Channel 3: Rhythmic/bass voice (drums, bass line)
[Channel 4: ATARI only, reserved for SIO]
```

## License and Attribution

- **RMT Player**: Radek Sterba (Raster/C.P.U.)
  - Original ATARI version
  - Ported to ca65
- **SID Adaptation**: This project
- **cc65 Toolchain**: https://cc65.github.io/ (zlib license)

---

**Next Steps:**

1. Read `00-START-HERE.txt` for a quick reference
2. Try `make run` to build and run the skeleton
3. Convert your own RMT song: `python3 tools/rmt2cbm64.py your_song.rmt /dev/null`
4. Integrate into your C64 game!

**Questions?** Refer to the embedded comments in `src/sidplayer.s` and `src/sidvbi.s`.
