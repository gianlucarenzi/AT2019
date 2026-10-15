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
extern volatile unsigned char sid_volume[6];  /* level of the SID voices, 0..15 (4-6: SID2) */
extern unsigned char          sid_ntsc;       /* 1 = NTSC machine, set by sid_init */

/* RMT8 (stereo) build: the right POKEY plays on a second SID at sid_sid2
 * (0 in a mono build or with make SID2=0); sid_voices is 6 when sid_init
 * found it there, 3 otherwise (on a C64 with one SID, $D420 is an image of
 * $D400) */
extern unsigned char          sid_voices;
extern const unsigned int     sid_sid2;
extern unsigned char          sid_ispeed;     /* player calls per frame (instrument speed) */

/* bit 0..5 set: SID voice 1..6 kept silent (the player goes on) */
extern volatile unsigned char sid_mute;

/* state of the last frame, for a display (src/rmtplay.c) */
extern volatile unsigned char sid_pokey[16];   /* POKEY registers written by the
                                                * player: AUDF1 AUDC1 .. AUDC4 AUDCTL */
extern volatile unsigned char sid_pokey2[16];  /* the right POKEY (RMT8) */
extern volatile unsigned char sid_src[6];      /* POKEY channel (0..7) of each voice */
extern volatile unsigned char sid_freq_lo[6];  /* SID frequency of each voice */
extern volatile unsigned char sid_freq_hi[6];
extern volatile unsigned char sid_wave[6];     /* SID waveform ($40 pulse, $80 noise) */

/* RMT player (src/rmtplayr.s): song position */
extern volatile unsigned char *rmt_p_song;     /* next song line */
#pragma zpsym ("rmt_p_song")
extern volatile unsigned char rmt_abeat;       /* row in the track */
extern volatile unsigned char rmt_maxtracklen; /* rows per track */
extern volatile unsigned char rmt_speed;       /* frames per row */

/* LZSS player (src/lzsplayr.s, a .sap/.xex song): stream position */
extern volatile unsigned char lzs_section;     /* section of the next frame (intro, loop) */
extern volatile unsigned char lzs_pos[3];      /* its frame in the section, 24 bit */

#endif
