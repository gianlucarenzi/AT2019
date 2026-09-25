# Sound Effects Integration Guide (CH3+4)

Once you've integrated the RMT 2-channel background music using channels 1+2, you can add sound effects to channels 3+4. This document explains how to add FX without interfering with the music.

## Overview

- **CH1+2**: Background music (RMT) - continuous
- **CH3+4**: Sound effects (your code) - available when SIO inactive

The key constraint: **During SIO transfers, CH3+4 are used for the serial baud rate. You must NOT write to AUDF3, AUDC3, AUDF4, AUDC4, or AUDCTL while `rmt_io_begin()` is active.**

## Header File Example: `sfx.h`

```c
#ifndef __SFX_H__
#define __SFX_H__

// Sound effect types
typedef enum {
    SFX_COLLISION,
    SFX_JUMP,
    SFX_POWER_UP,
    SFX_ENEMY_HIT,
    SFX_LEVEL_COMPLETE,
} sfx_type_t;

// Play a sound effect (if SIO is inactive)
void sfx_play(sfx_type_t effect);

// Stop all sound effects
void sfx_stop(void);

// Check if SIO is currently active
unsigned char sfx_sio_active(void);

// Call this periodically to update SFX (if needed)
void sfx_update(void);

#endif
```

## Implementation Example: `sfx.c`

### Simple Synth Effects (No SIO Interference)

```c
#include <atari.h>
#include <peekpoke.h>
#include "rmt.h"

#define AUDC3   0xD205
#define AUDF3   0xD204
#define AUDC4   0xD207
#define AUDF4   0xD206
#define AUDCTL  0xD208

// Track SIO state
static unsigned char sio_active = 0;

// Collision: simple beep on CH3
void play_collision_beep(void)
{
    if (sio_active) return;  // Don't play if SIO is active
    
    // Simple collision sound: brief high beep
    POKE(AUDF3, 100);   // Frequency
    POKE(AUDC3, 0xA8);  // Volume 8, poly5
    
    // Hardware doesn't need explicit "stop", just set volume to 0 after delay
    // Or let it decay naturally
}

// Jump: ascending pitch sweep on CH4
void play_jump_sound(void)
{
    if (sio_active) return;
    
    // Jump sound: ascending tone
    // In real game, run this in a timer/ISR for pitch sweep
    POKE(AUDF4, 200);   // Start low
    POKE(AUDC4, 0xA8);  // Volume 8
    // ... later in ISR, lower frequency to create rising effect ...
}

// Power-up: chord on both CH3+4
void play_powerup_chord(void)
{
    if (sio_active) return;
    
    // Two simultaneous tones
    POKE(AUDF3, 60);    // Lower note
    POKE(AUDC3, 0xA8);  // Volume 8
    POKE(AUDF4, 90);    // Higher note
    POKE(AUDC4, 0xA8);  // Volume 8
}

// Stop all effects on CH3+4
void sfx_stop(void)
{
    POKE(AUDC3, 0);     // Mute CH3
    POKE(AUDC4, 0);     // Mute CH4
}

// Entry point for game code
void sfx_play(sfx_type_t effect)
{
    switch (effect) {
        case SFX_COLLISION:
            play_collision_beep();
            break;
        case SFX_JUMP:
            play_jump_sound();
            break;
        case SFX_POWER_UP:
            play_powerup_chord();
            break;
        case SFX_ENEMY_HIT:
            play_collision_beep();  // Reuse collision sound
            break;
        case SFX_LEVEL_COMPLETE:
            play_powerup_chord();   // Reuse power-up sound
            break;
    }
}

// Query SIO state (from rmt.h globals)
unsigned char sfx_sio_active(void)
{
    extern unsigned char rmt_ioactive;
    return rmt_ioactive;
}
```

## Integration with RMT Player

### In Your Main Loop

```c
#include "rmt.h"
#include "sfx.h"

int main(void)
{
    // Initialize music
    rmt_init(rmt_song_2channel);
    rmt_vbi_on();
    
    for (;;) {
        // ... game logic ...
        
        // Did player jump?
        if (player_jumped()) {
            sfx_play(SFX_JUMP);
        }
        
        // Did player hit enemy?
        if (collision_detected(&player, &enemy)) {
            sfx_play(SFX_COLLISION);
            player_take_damage();
        }
        
        // Load level from disk?
        if (should_load_level()) {
            load_level_from_disk();
            // (rmt_io_begin/end is called inside load_level_from_disk)
        }
    }
    
    rmt_vbi_off();
    return 0;
}
```

### In Your Disk Loading Function

```c
void load_level_from_disk(void)
{
    rmt_io_begin();          // Tells RMT to mute CH3+4
                             // Music (CH1+2) continues
                             // rmt_ioactive flag is SET
    
    // All SFX calls will now check rmt_ioactive and return early
    
    // ... perform your SIO operation ...
    // ... load_sector(), read_file(), etc. ...
    
    rmt_io_end();            // Re-enables CH3+4
                             // rmt_ioactive flag is CLEARED
                             // Music resumes on all channels
}
```

## Advanced: Timed SFX with VBI

For more sophisticated effects (pitch sweeps, envelopes), you might use a VBI tick:

```c
// Simple time-based decay (call from main loop or VBI)
static unsigned char sfx_ticks = 0;

void sfx_update(void)
{
    if (sio_active) return;  // Don't update if SIO active
    
    if (sfx_ticks > 0) {
        sfx_ticks--;
        
        if (sfx_ticks > 0 && sfx_ticks < 10) {
            // Decay: lower volume over 10 ticks
            unsigned char vol = (sfx_ticks >> 1) << 4;
            POKE(AUDC3, vol);
            POKE(AUDC4, vol);
        } else if (sfx_ticks == 0) {
            // Finished: silence
            POKE(AUDC3, 0);
            POKE(AUDC4, 0);
        }
    }
}

void play_collision_with_decay(void)
{
    if (sio_active) return;
    
    POKE(AUDF3, 100);
    POKE(AUDC3, 0xA8);  // Full volume
    sfx_ticks = 20;     // Decay over 20 ticks
}
```

## POKEY Register Reference for CH3+4

```
Register        Address  Purpose
─────────────────────────────────────────────
AUDF3           $D204    Frequency CH3 (0-255)
AUDC3           $D205    Control/Volume CH3
AUDF4           $D206    Frequency CH4 (0-255)
AUDC4           $D207    Control/Volume CH4
AUDCTL          $D208    Audio control (shared all channels)
```

### AUDC Register Format

```
Bit 7 6 5 4 3 2 1 0
    ├─ V V V V ─ Distortion/Mode
    └─────────── Volume (0-15, 0=silent)

Common values:
  0x00 = Mute
  0xA8 = Vol 10, poly5 distortion
  0xA0 = Vol 10, no distortion
  0x88 = Vol 8, poly5 distortion
```

### AUDCTL Register Format

```
Bit 7 6 5 4 3 2 1 0
    H S ├ Modes for CH1/3, CH2/4
    I T

During SIO:
  AUDCTL = $28 (channels 3+4 joined 16-bit, clock 1.79MHz for baud rate)

During music+SFX:
  AUDCTL = $00 (default: all channels independent, 64 kHz clock)
```

**Important**: The RMT player handles AUDCTL management. Don't modify it directly during music playback.

## Safety Rules

✅ **DO:**
- Check `rmt_ioactive` before writing to CH3+4
- Use `rmt_io_begin()` before every SIO operation
- Use `rmt_io_end()` after every SIO operation
- Let the RMT player manage AUDCTL
- Mute CH3+4 when done with an effect

❌ **DON'T:**
- Write to AUDF3/AUDC3/AUDF4/AUDC4 during SIO (rmt_io_begin active)
- Modify AUDCTL while music is playing
- Call SIO functions without bracketing with rmt_io_begin/end
- Play simultaneous SFX on same channel (they will interfere)

## Testing Your Implementation

Add a simple test to verify SFX work correctly:

```c
void test_sfx(void)
{
    clrscr();
    cputs("SFX Test\r\n");
    cputs("1: Collision\r\n");
    cputs("2: Jump\r\n");
    cputs("3: Power-up\r\n");
    cputs("ESC: Exit\r\n\r\n");
    
    for (;;) {
        if (kbhit()) {
            char c = cgetc();
            if (c == '1') sfx_play(SFX_COLLISION);
            if (c == '2') sfx_play(SFX_JUMP);
            if (c == '3') sfx_play(SFX_POWER_UP);
            if (c == 27) break;
        }
        
        // Show if SIO is active
        gotoxy(0, 7);
        if (sfx_sio_active()) {
            cputs("SIO: ACTIVE  (SFX blocked)   ");
        } else {
            cputs("SIO: INACTIVE (SFX available)");
        }
    }
}
```

## Limitations

1. **Sequential SFX only**: If you play a second effect while the first is still sounding, they will interfere
   - Solution: Queue effects, play one at a time, or use different frequencies
   
2. **No complex envelopes**: Simple volume/frequency control only
   - Solution: Use timers/VBI for gradual changes
   
3. **Limited pitch range**: POKEY frequencies are limited by AUDF register (0-255)
   - Solution: Use AUDCTL to shift clock, or use different distortion modes

4. **SFX silent during SIO**: By design - can't avoid this
   - This is why the music pattern is so important

## Example Game: Complete Audio Flow

```
Game Start:
  → RMT music loaded (2-channel)
  → Music playing continuously
  
Player Gameplay:
  → Jump? Play SFX_JUMP (CH4)
  → Collision? Play SFX_COLLISION (CH3)
  → Music continues throughout
  
Level Transition:
  → rmt_io_begin() [CH3+4 muted, CH1+2 continues]
  → Load assets from disk (music plays)
  → rmt_io_end() [CH3+4 restored]
  → Music+SFX resume together
  
Game Over:
  → rmt_vbi_off() [Music stops, POKEY silenced]
```

---

## References

- `rmt.h` - RMT player API (see `rmt_io_begin()`, `rmt_io_end()`)
- `README.md` - Audio Design Pattern section
- Atari Hardware Reference - POKEY registers
- HVSC documentation for more advanced synthesis techniques

**Next Step**: Copy this guide into your project, implement `sfx.c`, and test with your game!
