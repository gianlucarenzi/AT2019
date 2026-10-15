#ifndef __RMT_H__
#define __RMT_H__

/* RMT module linked in the program (tools/rmt2ca65.py) */
extern const unsigned char rmt_song[];

/* Init the player on a module; returns the instrument speed (1 = 1x/frame) */
unsigned char __fastcall__ rmt_init(const void *module);

/* Install/remove the player on the VBI (immediate + deferred, see rmtvbi.s) */
void rmt_vbi_on(void);
void rmt_vbi_off(void);

/* Bracket every SIO transfer: while active the player only uses channels 1+2 */
void rmt_io_begin(void);
void rmt_io_end(void);

extern volatile unsigned int  rmt_frames;     /* VBI counter */
extern volatile unsigned char rmt_lines;      /* last player time (scanlines) */
extern volatile unsigned char rmt_maxlines;   /* worst player time (scanlines) */
extern volatile unsigned char rmt_avglines;   /* player time, average of about 64 frames */
extern volatile unsigned int  rmt_deferred;   /* ticks postponed (VBI with I=1), caught up next frame */
extern volatile unsigned int  rmt_dropped;    /* ticks lost: song tempo error */
/* Tracks of the song: 4 (RMT4, mono SAP) or 8 (RMT8, stereo SAP); the
 * Makefile builds with -DRMT_TRACKS from the song file */
#ifndef RMT_TRACKS
#define RMT_TRACKS 4
#endif

extern volatile unsigned char rmt_audc[RMT_TRACKS]; /* AUDC values computed by the player */

/* Where the channels are played: rmt_init chooses it (rmtvbi.s). With 8
 * tracks channels 5-8 (the right POKEY of the song) go to a second POKEY at
 * $D210 if there is one, else to the VERA PSG if there is a VeraX16 card,
 * else nowhere. With the VERA it also shows a copy of the text screen */
#define RMT_OUT_POKEY   0       /* 4 tracks: one POKEY */
#define RMT_OUT_VERA    1       /* POKEY plays channels 1-4, VERA PSG 5-8, and
                                   the VERA mirrors the screen */
#define RMT_OUT_POKEY2  2       /* two POKEYs */
#define RMT_OUT_LEFT    3       /* one POKEY: only channels 1-4 are heard */
#define RMT_OUT_POKEY2_VERA 4   /* two POKEYs, the VERA mirrors the screen */
extern unsigned char rmt_output;

#endif
