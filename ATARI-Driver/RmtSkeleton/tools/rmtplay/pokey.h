/*
 * pokey.h - POKEY sound emulation (one chip, 4 channels)
 */
#ifndef POKEY_H
#define POKEY_H

#include <stdint.h>

#define POKEY_CLOCK_PAL   1773447
#define POKEY_CLOCK_NTSC  1789790

typedef struct {
	uint8_t audf[4], audc[4], audctl;
	int counter[4];         /* divider counters, in clock ticks */
	uint8_t out[4];         /* channel flip-flops */
	uint8_t hp[2];          /* high-pass latches of channels 1 and 2 */
	unsigned poly4, poly5, poly9, poly17;   /* positions in the sequences */
	int base;               /* cycles to the next 64 kHz / 15 kHz tick */
} pokey_t;

void pokey_init(pokey_t *p);
void pokey_write(pokey_t *p, uint8_t reg, uint8_t val);   /* reg 0..8 */

/* Advance one machine cycle; returns the output level 0..60 */
int pokey_cycle(pokey_t *p);

#endif
