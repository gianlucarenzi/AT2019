/*
 * sid.h - SID sound emulation (MOS 6581/8580, 3 voices, no filter)
 */
#ifndef SID_H
#define SID_H

#include <stdint.h>

#define SID_CLOCK_PAL   985248
#define SID_CLOCK_NTSC  1022727

typedef struct {
	uint32_t acc;           /* 24 bit phase accumulator */
	uint32_t noise;         /* 23 bit noise shift register */
	uint16_t freq, pw;
	uint8_t ctrl, ad, sr;
	uint8_t env;            /* envelope counter 0..255 */
	uint8_t state;          /* attack, decay/sustain, release */
	uint8_t hold_zero;
	uint16_t rate_cnt;
	uint8_t exp_cnt, exp_period;
} sid_voice_t;

typedef struct {
	sid_voice_t v[3];
	uint8_t vol;            /* $D418 bits 0..3 */
} sid_t;

void sid_init(sid_t *s);
void sid_write(sid_t *s, uint8_t reg, uint8_t val);       /* reg 0..$1F */

/* Advance one C64 clock cycle; returns the output, about -24000..24000 */
int sid_cycle(sid_t *s);

#endif
