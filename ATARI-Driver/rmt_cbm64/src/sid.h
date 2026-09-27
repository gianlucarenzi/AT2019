/*
 * sid.h - C interface for SID RMT player (Commodore 64)
 *
 * Minimal API for playing RMT modules on C64 via SID chip.
 * Uses CIA1 Timer A for 50/60 Hz IRQ sync.
 */

#ifndef __SID_H__
#define __SID_H__

#include <stdint.h>

/* RMT module linked in the program (tools/rmt2cbm64.py) */
extern const unsigned char rmt_song_data[];

/* Initialize the player with an RMT module */
void __fastcall__ sid_init(const void *module);

/* Start playback (attach to CIA1 IRQ) */
void sid_play_on(void);

/* Stop playback and silence SID */
void sid_play_off(void);

/* Diagnostic counters (updated every IRQ) */
extern volatile unsigned int   sid_frames;     /* IRQ counter */
extern volatile unsigned char  sid_status;     /* Player status (0=idle, 1=playing) */
extern volatile unsigned char  sid_volume[3];  /* Volume for each voice */

#endif
