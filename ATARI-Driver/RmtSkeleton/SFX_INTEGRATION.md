# Sound Effects on Channels 3+4

This document explains what the current player allows for sound effects (SFX)
and what it does not.

## How the player uses POKEY

Every VBI the player's `SetPokey` routine writes:

| Mode                                   | Registers written by the player                   |
|----------------------------------------|---------------------------------------------------|
| normal (`rmt_ioactive = 0`)            | `AUDF1-4`, `AUDC1-4`, `AUDCTL`                    |
| I/O (`rmt_io_begin` .. `rmt_io_end`)   | `AUDF1`, `AUDC1`, `AUDF2`, `AUDC2` only           |

So in normal mode **the music owns all 4 channels**. A `POKE(AUDC3, ...)` from
your program is overwritten at the next VBI (within 1/50 s): there is no "SFX
mode" in the player, and channels 3+4 are not free just because no disk I/O
is running.

## What works today: borrowing channels 3+4

`rmt_io_begin()` does not start any I/O. It only sets `rmt_ioactive = 1`, which
tells the player to leave `AUDF3`, `AUDC3`, `AUDF4`, `AUDC4` and `AUDCTL` alone,
and mutes channels 3/4. You can use the same bracket to borrow channels 3+4
for an effect:

```c
rmt_io_begin();          // music continues on CH1+2, CH3+4 are yours
// ... play the effect on AUDF3/AUDC3/AUDF4/AUDC4 for a few frames ...
POKEY_WRITE.audc3 = 0;   // silence your channels
POKEY_WRITE.audc4 = 0;
rmt_io_end();            // next VBI the music takes CH3+4 back
```

Rules:

- **Your program must know when a disk transfer is running** and not touch
  channels 3+4 then: during a transfer they are the serial baud rate. You call
  the loader yourself, so keep your own flag; `rmt_ioactive` is not exported
  to C (it is an assembler symbol without the leading `_`), and it is 1 both
  while loading and while you borrow the channels.
- **`AUDCTL` is not written by the player in this mode.** It keeps the last value
  written by the song or by the SIO (`$28` after a transfer: channel 3 clocked
  at 1.79 MHz and joined to channel 4). If your effect needs a given `AUDCTL`,
  write it yourself, knowing that it also changes channels 1/2 of the music.
- **Nesting.** A load that calls `rmt_io_begin()`/`rmt_io_end()` in the middle of
  an effect ends the borrowing at its `rmt_io_end()`. Stop the effect before
  loading, or make your code track the two uses.
- While channels 3+4 are borrowed, the song's voices on those channels are not
  heard (as during loading).

## What would be needed for real SFX support

A cleaner design would give the player a second flag, for example
`rmt_sfxactive`, exported to C, that `SetPokey` checks like `rmt_ioactive` for
channels 3/4 only, and an `AUDCTL` policy (for example: the player keeps writing
`AUDCTL` with the channel 3/4 bits taken from the SFX code). This is not
implemented: it would be a change to `rmtplayr.s` and `rmtvbi.s`, which are
shared with PokeyATest.

## POKEY register reference

```
Register  Address  Purpose
────────────────────────────────────────────────────
AUDF1     $D200    Frequency divider CH1
AUDC1     $D201    Distortion / volume CH1
AUDF2     $D202    Frequency divider CH2
AUDC2     $D203    Distortion / volume CH2
AUDF3     $D204    Frequency divider CH3
AUDC3     $D205    Distortion / volume CH3
AUDF4     $D206    Frequency divider CH4
AUDC4     $D207    Distortion / volume CH4
AUDCTL    $D208    Audio control (shared by all channels)
```

In cc65 they are available as `POKEY_WRITE.audf1` ... `POKEY_WRITE.audctl`
(`<atari.h>`).

### AUDC

```
bit  7 6 5   4        3 2 1 0
     D D D   V        v v v v
     │       │        └─────── volume 0-15 (0 = silent)
     │       └──────────────── volume only (1 = output the volume level, no tone)
     └──────────────────────── distortion: %101 ($A0) = pure tone,
                               %000 ($00) = poly5+poly17 noise, %100 ($80) = poly17 noise, ...
```

Examples: `$A8` = pure tone, volume 8; `$AF` = pure tone, volume 15;
`$88` = noise, volume 8; `$00` = silent.

### AUDCTL

```
bit 7  poly9 instead of poly17
bit 6  channel 1 clocked at 1.79 MHz
bit 5  channel 3 clocked at 1.79 MHz
bit 4  channels 1+2 joined (16 bit)
bit 3  channels 3+4 joined (16 bit)
bit 2  high-pass filter on channel 1, clocked by channel 3
bit 1  high-pass filter on channel 2, clocked by channel 4
bit 0  base clock 15 kHz instead of 64 kHz
```

During SIO: `AUDCTL = $28` (bits 5 and 3: channels 3+4 joined, 1.79 MHz clock).

## References

- `README.md` – POKEY channels and disk I/O
- `src/rmtplayr.s` – `SetPokey`
- `src/rmtvbi.s` – `rmt_io_begin`, `rmt_io_end`
- Atari Hardware Manual / De Re Atari – POKEY chapter
