# RmtSkeleton – Minimal RMT Player Template

A bare-bones cc65 project showing how to integrate the **Raster Music Tracker** player into your own programs.

This is **not** a complete game or demo – it's a reference skeleton that shows:
- The minimal file structure
- How to configure the linker
- How to set up the Makefile
- A simple main.c example
- **Optional**: Audio design pattern for videogames with SIO (disk I/O)

**Use this as a template** for your own cc65 projects that need background music.

## 🎮 Perfect For: Atari Videogames with Disk Loading

This skeleton is especially useful for **Atari videogames that load assets from disk via SIO** while maintaining uninterrupted background music. See [Audio Design Pattern](#-audio-design-pattern-for-videogames) below.

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
│   └── rmt2ca65.py       converts .rmt files to relocatable ca65 source
├── music/
│   └── gemx.rmt          example RMT song (replace with your own)
└── build/                generated files (ignored by git)
    ├── rmtskeleton.com   the final executable
    └── song.s            generated from .rmt file
```

## Files from PokeyATest

These files are copied from `../PokeyATest` and should not be modified:
- `rmtplayr.s` – the RMT 1.20090108 player in ca65 (mono, 4 channels)
- `rmtvbi.s` – VBI handler and C wrapper
- `rmt.h` – C API (used by main.c)
- `rmt_feat.inc` – feature switches (all enabled)
- `tools/rmt2ca65.py` – converts .rmt to relocatable ca65

If you update PokeyATest, re-copy these files to stay in sync.

## Building

### Prerequisites
- **cc65** (ca65 assembler, cl65 linker)
- **python3** (for rmt2ca65.py)
- Optionally: **atari800** emulator (to run the program)

### Compile

```bash
make                # build rmtskeleton.com
make run            # build and run in atari800
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

## API Overview (C Interface)

See `src/rmt.h` for the full interface. Basic usage:

```c
#include "rmt.h"

// Initialize the player (do this BEFORE attaching to VBI)
rmt_init(rmt_song);

// Attach to the immediate VBI (music starts)
rmt_vbi_on();

// ... your program runs here ...

// If you need to load/save/access disk while music plays
rmt_io_begin();          // channels 3/4 go silent (used by SIO baud rate)
// ... do your SIO operation ...
rmt_io_end();            // channels 3/4 resume

// Stop the player (silence POKEY)
rmt_vbi_off();
```

Diagnostics (updated every VBI by the player):

```c
rmt_frames   // VBI counter
rmt_lines    // duration of last player call (scanlines)
rmt_maxlines // worst-case player time
rmt_deferred // ticks postponed (should be rare)
rmt_dropped  // ticks lost (must be 0 - indicates a problem)
rmt_audc[4]  // AUDC values for channels 1..4 (for VU meter)
```

## 🎮 Audio Design Pattern for Videogames

### The Problem: SIO + Full 4-Channel Music = Audio Glitches

When loading assets from disk via SIO while playing RMT music on all 4 POKEY channels, **channels 3+4 become unavailable** (used for the serial baud rate generator). This causes:

- ❌ Sudden drop from 4-channel to 2-channel audio
- ❌ Bass/drums cut off (typically in CH3+4)
- ❌ Noticeable "pop" or discontinuity
- ❌ Breaks immersion during loading

### The Solution: 2+2 Audio Strategy

Use a **2+2 split**:

```
┌────────────────────────────────────────────────────────┐
│           POKEY 4 Channels - Optimal Layout             │
├────────────────────────────────────────────────────────┤
│                                                        │
│  🎶 Channels 1+2: BACKGROUND MUSIC (RMT)               │
│     ├─ Continuous during gameplay AND disk loading     │
│     ├─ Never interrupted, never glitches               │
│     ├─ Maintains atmosphere & narrative flow           │
│     └─ Gives player sense of progress                  │
│                                                        │
│  🔊 Channels 3+4: SOUND EFFECTS (Custom Synth)         │
│     ├─ Game effects: collisions, explosions, power-ups │
│     ├─ Available whenever SIO is INACTIVE              │
│     ├─ Maximizes gameplay responsiveness               │
│     ├─ Muted during disk loading (no interference)     │
│     └─ Resumes immediately after loading completes     │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### How It Works

**Normal Gameplay (SIO Inactive)**
```
CH1+2: 🎵 Music ✓
CH3+4: 🔊 SFX ✓
═════════════════════════════════════════════
Result: Full 4-channel audio, professionally produced
```

**During Disk Loading (SIO Active)**
```
CH1+2: 🎵 Music ✓ (continues uninterrupted)
CH3+4: [Serial baud rate generator]
═════════════════════════════════════════════
Result: 2-channel music + zero glitch = seamless experience
```

### Why This is Optimal

| Aspect | Benefit |
|--------|---------|
| **Audio Continuity** | Music never cuts out → immersive experience |
| **Zero Glitches** | No pops, crackles, or discontinuities during load |
| **Gameplay Feel** | SFX provide immediate feedback when not loading |
| **Disk I/O Safety** | CH3+4 interference eliminated completely |
| **Professional Quality** | Sounds like a polished arcade game |

### Implementation Strategy

```c
// Audio channels - fixed mapping
#define MUSIC_CH_LO    1    // RMT: main melody/harmony
#define MUSIC_CH_HI    2    // RMT: counterpoint/accompaniment
#define SFX_CH_BASS    3    // Sound effects: deep tones
#define SFX_CH_HI      4    // Sound effects: accents/melodies

// The magic: rmt_io_begin/end brackets every disk operation
void load_game_asset_from_disk(void)
{
    rmt_io_begin();          // Mutes CH3+4, CH1+2 continues
    // ... SIO transfer (music plays uninterrupted) ...
    rmt_io_end();            // CH3+4 restored, SFX available again
}

// Sound effects only when SIO is inactive
void play_collision_sfx(void)
{
    if (!sio_is_active()) {
        // Generate collision sound on CH3+4
        // (CH1+2 music is never touched)
        generate_sfx_collision();
    }
}

// Main game loop
int main(void)
{
    rmt_init(rmt_song_2channel);  // Load 2-channel RMT
    rmt_vbi_on();                  // Start music - never stops
    
    for (;;) {
        // Normal gameplay: 4-channel audio available
        handle_input();
        update_game_state();
        
        // Collision? Play SFX (if SIO inactive)
        if (collision_detected()) {
            play_collision_sfx();
        }
        
        // Load next level? SFX muted, music continues
        if (should_load_level()) {
            load_level_from_disk();  // rmt_io_begin/end inside
        }
    }
}
```

### Composing for This Pattern

When creating or selecting a 2-channel RMT for your game:

- **Channel 1**: Main melody, lead instruments
- **Channel 2**: Harmony, bass line, rhythm
- Both channels should work together to create a complete, satisfying musical experience
- Avoid putting critical bass/drums ONLY in CH3+4

See `FIND_2CHANNEL_SONGS.md` for how to find and verify 2-channel RMT files.

### Audio Statistics for Typical Game

From a collection of ~100 RMT files:

```
10-15%  ✅ 2-channel ONLY (perfect for this pattern)
50%     ⚠️  3 channels (partial loss during SIO)
30%     ⚠️  4 channels (noticeable loss during SIO)
5%      ❌ Other combinations
```

**Bottom line**: About 1 in 6-10 existing RMT files is perfectly suited to this design pattern.



- **RMT4 mono only** (4 channels, single POKEY)
  - RMT8 stereo modules are rejected by rmt2ca65.py
  - Instruments can use all 4 channels
  
- **Instrument speed 1 only** (player called once per frame)
  - Speed > 1 will play slower than intended
  - rmt2ca65.py warns about this
  
- Works with RMT files generated by:
  - Raster Music Tracker (RMT)
  - FatTracker
  - Other RMT-compatible trackers

## Key Implementation Details

### Why Immediate VBI?

The player runs in the **immediate VBI** (`VVBLKI`), not the deferred one. Why?

- During SIO operations, the OS sets `CRITIC` and **skips the deferred VBI** (`VVBLKD`).
- Only the immediate VBI always runs, so music keeps playing while loading.

### IRQ Handling

The player re-enables IRQs (`CLI`) while running so the serial port (SIO) doesn't starve:
- Data arrives at ~930 CPU cycles per byte at 19200 baud
- Without IRQs enabled, bytes would be lost during long player calls

But `CLI` is only safe if the interrupted code had I=0 (IRQs enabled). If the VBI hits inside an IRQ handler, the tick is **postponed** and run later from the IRQ tail or next frame (`rmt_deferred` counter). The song tempo stays correct.

### SIO and Music

While a disk transfer is active (between `rmt_io_begin()` and `rmt_io_end()`):

- Channels 3+4 of POKEY become the 16-bit baud rate generator (`AUDCTL=$28`)
- The player **does not** write `AUDF3`, `AUDC3`, `AUDF4`, `AUDC4`, or `AUDCTL`
- Music continues on **channels 1+2 only**
- The song still advances at normal tempo

So if you compose for channels 1+2 as the main instruments, users won't notice the reduced channel count during loading.

### Memory Layout

The RMT player needs:
- **19 bytes of zero page** (in cc65's `ZEROPAGE` segment)
- **~640 bytes of page-aligned tables** in `RMTTAB` segment (aligned to $100 boundaries)
- **~160 bytes of variables** in `BSS` segment
- **~2 KB of code** (automodifying, must be in RAM)
- **Module size** (varies, typically 2-4 KB)

Total: roughly 5-8 KB depending on module size.

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

The `align = $100` ensures the player tables start at a page boundary. This must come **before** other code segments in `MAIN`.

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
   - `rmt_vbi_off()` at cleanup

4. **Update `src/rmtskeleton.cfg`** if you add more code segments.

5. **Update the Makefile** with your own C/ASM source files.

6. **Keep the RMT player files unchanged**: `rmtplayr.s`, `rmtvbi.s`, `rmt.h`, `rmt_feat.inc`.

## Troubleshooting

### The music skips or sounds wrong

- Check `rmt_dropped`: if it's > 0, the player is losing ticks and the song tempo is wrong
  - Usually caused by other code or IRQ handlers taking too long
  - Try reducing CPU load elsewhere

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
- RMT player original documentation in PokeyATest
- cc65 documentation: https://cc65.github.io/

## License and Attribution

- **RMT player**: Radek Sterba (Raster/C.P.U.), ported to ca65
- **This skeleton**: based on PokeyATest by RetroBitLab
- **cc65**: https://cc65.github.io/ (distributed under zlib license)

---

**Ready to add music to your Atari program?** Start editing `src/main.c`!
