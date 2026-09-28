/*
 * pokey.c - POKEY sound emulation (one chip, 4 channels)
 *
 * Cycle based model:
 *  - base clock 64 kHz (every 28 cycles) or 15 kHz (every 114 cycles, AUDCTL bit 0)
 *  - channels 1 and 3 optionally clocked at 1.79 MHz (AUDCTL bits 6, 5)
 *  - channels 1+2 and 3+4 optionally joined as 16 bit counters (bits 4, 3)
 *  - high-pass filters on channels 1 and 2, clocked by 3 and 4 (bits 2, 1)
 *  - poly4, poly5, poly9/poly17 (bit 7) shift registers stepping every cycle
 *  - AUDC distortion: bit 7 = 0 gates the channel with poly5, bit 5 = pure
 *    tone, else bit 6 selects poly4 or poly17/9; bit 4 = volume only
 */
#include <string.h>
#include "pokey.h"

#define POLY4_LEN   15
#define POLY5_LEN   31
#define POLY9_LEN   511
#define POLY17_LEN  131071

static uint8_t poly4[POLY4_LEN], poly5[POLY5_LEN], poly9[POLY9_LEN], poly17[POLY17_LEN];
static int polys_ready;

/* maximal length LFSR, x^n + x^(n-tap) + 1 */
static void make_poly(uint8_t *dst, int len, int bits, int tap)
{
	unsigned reg = 1;
	int i;

	for (i = 0; i < len; i++) {
		dst[i] = reg & 1;
		reg = (reg >> 1) | ((((reg >> 0) ^ (reg >> tap)) & 1) << (bits - 1));
	}
}

void pokey_init(pokey_t *p)
{
	int i;

	if (!polys_ready) {
		make_poly(poly4, POLY4_LEN, 4, 1);
		make_poly(poly5, POLY5_LEN, 5, 2);
		make_poly(poly9, POLY9_LEN, 9, 4);
		make_poly(poly17, POLY17_LEN, 17, 3);
		polys_ready = 1;
	}
	memset(p, 0, sizeof(*p));
	for (i = 0; i < 4; i++)
		p->counter[i] = 1;
	p->base = 28;
}

void pokey_write(pokey_t *p, uint8_t reg, uint8_t val)
{
	if (reg < 8) {
		if (reg & 1)
			p->audc[reg >> 1] = val;
		else
			p->audf[reg >> 1] = val;
	} else if (reg == 8) {
		p->audctl = val;
	}
}

static void pulse(pokey_t *p, int ch)
{
	uint8_t c = p->audc[ch];

	if ((c & 0x80) || poly5[p->poly5]) {
		if (c & 0x20)
			p->out[ch] ^= 1;
		else if (c & 0x40)
			p->out[ch] = poly4[p->poly4];
		else
			p->out[ch] = (p->audctl & 0x80) ? poly9[p->poly9 % POLY9_LEN] : poly17[p->poly17];
	}
	if (ch == 2 && (p->audctl & 0x04))
		p->hp[0] = p->out[0];
	if (ch == 3 && (p->audctl & 0x02))
		p->hp[1] = p->out[1];
}

/* one channel pair: lo = 0 or 2; fast = 1.79 MHz bit, join = 16 bit bit */
static void clock_pair(pokey_t *p, int lo, int tick, uint8_t fast, uint8_t join)
{
	int hi = lo + 1;
	int clk_lo = (p->audctl & fast) ? 1 : tick;

	if (p->audctl & join) {
		if (clk_lo && --p->counter[hi] <= 0) {
			p->counter[hi] = p->audf[lo] + 256 * p->audf[hi] + ((p->audctl & fast) ? 7 : 1);
			pulse(p, hi);
		}
		return;
	}
	if (clk_lo && --p->counter[lo] <= 0) {
		p->counter[lo] = p->audf[lo] + ((p->audctl & fast) ? 4 : 1);
		pulse(p, lo);
	}
	if (tick && --p->counter[hi] <= 0) {
		p->counter[hi] = p->audf[hi] + 1;
		pulse(p, hi);
	}
}

int pokey_cycle(pokey_t *p)
{
	int tick = 0, ch, sum = 0;

	if (++p->poly4 == POLY4_LEN) p->poly4 = 0;
	if (++p->poly5 == POLY5_LEN) p->poly5 = 0;
	if (++p->poly9 == POLY9_LEN) p->poly9 = 0;
	if (++p->poly17 == POLY17_LEN) p->poly17 = 0;

	if (--p->base <= 0) {
		tick = 1;
		p->base = (p->audctl & 0x01) ? 114 : 28;
	}
	/* channel 3/4 first: their pulses latch the high-pass filters of 1/2 */
	clock_pair(p, 2, tick, 0x20, 0x08);
	clock_pair(p, 0, tick, 0x40, 0x10);

	for (ch = 0; ch < 4; ch++) {
		uint8_t c = p->audc[ch];
		int bit;

		if (c & 0x10) {
			sum += c & 0x0F;
			continue;
		}
		bit = p->out[ch];
		if (ch == 0 && (p->audctl & 0x04))
			bit ^= p->hp[0];
		if (ch == 1 && (p->audctl & 0x02))
			bit ^= p->hp[1];
		if (bit)
			sum += c & 0x0F;
	}
	return sum;
}
