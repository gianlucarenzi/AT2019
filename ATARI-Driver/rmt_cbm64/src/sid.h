/*
 * sid.h - RMT player on the Commodore 64 SID (src/sidrmt.s)
 *
 * The Atari RMT player routine (rmtplayr.s) runs from a raster IRQ once per
 * frame; its POKEY registers are translated to SID registers.
 */

#ifndef __SID_H__
#define __SID_H__

/* RMT module linked in the program (tools/rmt2ca65.py) */
extern const unsigned char rmt_song_data[];

/* Init the player on a module, only while it is stopped */
void __fastcall__ sid_init(const void *module);

/* Start playback: raster IRQ chained to the KERNAL IRQ vector ($0314) */
void sid_play_on(void);

/* Stop playback and silence the SID (also done at program exit) */
void sid_play_off(void);

extern volatile unsigned int  sid_frames;     /* frames played */
extern volatile unsigned char sid_status;     /* 1 = playing */
extern volatile unsigned char sid_volume[3];  /* level of the 3 SID voices, 0..15 */
extern unsigned char          sid_ntsc;       /* 1 = NTSC machine, set by sid_init */

#endif
