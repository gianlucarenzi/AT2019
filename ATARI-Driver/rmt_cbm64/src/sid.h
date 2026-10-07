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

/* bit 0..2 set: SID voice 1..3 kept silent (the player goes on) */
extern volatile unsigned char sid_mute;

/* state of the last frame, for a display (src/rmtplay.c) */
extern volatile unsigned char sid_pokey[16];   /* POKEY registers written by the
                                                * player: AUDF1 AUDC1 .. AUDC4 AUDCTL */
extern volatile unsigned char sid_src[3];      /* POKEY channel (0..3) of each voice */
extern volatile unsigned char sid_freq_lo[3];  /* SID frequency of each voice */
extern volatile unsigned char sid_freq_hi[3];
extern volatile unsigned char sid_wave[3];     /* SID waveform ($40 pulse, $80 noise) */

/* RMT player (src/rmtplayr.s): song position */
extern volatile unsigned char *rmt_p_song;     /* next song line */
#pragma zpsym ("rmt_p_song")
extern volatile unsigned char rmt_abeat;       /* row in the track */
extern volatile unsigned char rmt_maxtracklen; /* rows per track */
extern volatile unsigned char rmt_speed;       /* frames per row */

#endif
