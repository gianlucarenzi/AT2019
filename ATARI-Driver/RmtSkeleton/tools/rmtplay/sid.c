/*
 * sid.c - SID sound emulation (MOS 6581/8580, 3 voices, no filter)
 *
 * Enough for ../../../rmt_cbm64/src/sidrmt.s, which uses pulse and noise,
 * all ADSR rates 0 and the sustain level as volume:
 *  - 24 bit oscillators, pulse / sawtooth / triangle / noise (combined
 *    waveforms are ANDed), test bit; no sync, no ring modulation
 *  - noise: 23 bit LFSR clocked when bit 19 of the accumulator goes high
 *  - envelope as in reSID: rate counter, exponential counter at levels
 *    $5D/$36/$1A/$0E/$06, decay stops at the sustain level and goes on
 *    down to 0 when the sustain level is above the counter, frozen at 0
 *  - master volume ($D418 bits 0..3); the filter is not emulated
 */
#include <string.h>
#include "sid.h"

enum { ATTACK, DECAY_SUSTAIN, RELEASE };

/* cycles per envelope step, ADSR rate 0..15 */
static const uint16_t rate_period[16] = {
	9, 32, 63, 95, 149, 220, 274, 313, 392, 977, 1954, 3126, 3907, 11720, 19532, 31251
};

void sid_init(sid_t *s)
{
	int i;

	memset(s, 0, sizeof(*s));
	for (i = 0; i < 3; i++) {
		s->v[i].noise = 0x7FFFF8;
		s->v[i].state = RELEASE;
		s->v[i].hold_zero = 1;
		s->v[i].exp_period = 1;
	}
}

void sid_write(sid_t *s, uint8_t reg, uint8_t val)
{
	sid_voice_t *v;

	reg &= 0x1F;
	if (reg == 0x18) {
		s->vol = val & 0x0F;
		return;
	}
	if (reg >= 21)
		return;                         /* filter, not emulated */
	v = &s->v[reg / 7];
	switch (reg % 7) {
	case 0: v->freq = (v->freq & 0xFF00) | val; break;
	case 1: v->freq = (v->freq & 0x00FF) | (val << 8); break;
	case 2: v->pw = (v->pw & 0x0F00) | val; break;
	case 3: v->pw = (v->pw & 0x00FF) | ((val & 0x0F) << 8); break;
	case 4:
		if ((val & 0x01) && !(v->ctrl & 0x01)) {
			v->state = ATTACK;      /* gate on: attack from the current level */
			v->hold_zero = 0;
		} else if (!(val & 0x01) && (v->ctrl & 0x01))
			v->state = RELEASE;
		if (val & 0x08) {               /* test bit: oscillator and noise reset */
			v->acc = 0;
			v->noise = 0x7FFFF8;
		}
		v->ctrl = val;
		break;
	case 5: v->ad = val; break;
	case 6: v->sr = val; break;
	}
}

static void envelope(sid_voice_t *v)
{
	uint16_t period;

	switch (v->state) {
	case ATTACK:        period = rate_period[v->ad >> 4]; break;
	case DECAY_SUSTAIN: period = rate_period[v->ad & 0x0F]; break;
	default:            period = rate_period[v->sr & 0x0F]; break;
	}
	if (++v->rate_cnt < period)
		return;
	v->rate_cnt = 0;
	if (v->state != ATTACK && ++v->exp_cnt < v->exp_period)
		return;
	v->exp_cnt = 0;
	if (v->hold_zero)
		return;
	switch (v->state) {
	case ATTACK:
		if (++v->env == 0xFF)
			v->state = DECAY_SUSTAIN;
		break;
	case DECAY_SUSTAIN:
		if (v->env != (v->sr >> 4) * 0x11)
			v->env--;
		break;
	default:
		v->env--;
		break;
	}
	switch (v->env) {
	case 0xFF: v->exp_period = 1; break;
	case 0x5D: v->exp_period = 2; break;
	case 0x36: v->exp_period = 4; break;
	case 0x1A: v->exp_period = 8; break;
	case 0x0E: v->exp_period = 16; break;
	case 0x06: v->exp_period = 30; break;
	case 0x00: v->exp_period = 1; v->hold_zero = 1; break;
	}
}

static unsigned waveform(sid_voice_t *v)
{
	unsigned out = 0xFFF, acc12 = v->acc >> 12;

	if (!(v->ctrl & 0xF0))
		return 0x800;                   /* no waveform: the DAC midpoint */
	if (v->ctrl & 0x10)                     /* triangle */
		out &= ((v->acc & 0x800000) ? ~acc12 << 1 : acc12 << 1) & 0xFFF;
	if (v->ctrl & 0x20)                     /* sawtooth */
		out &= acc12;
	if (v->ctrl & 0x40)                     /* pulse */
		out &= (v->ctrl & 0x08) || acc12 >= v->pw ? 0xFFF : 0;
	if (v->ctrl & 0x80) {                   /* noise */
		uint32_t r = v->noise;
		out &= ((r >> 9) & 0x800) | ((r >> 8) & 0x400) | ((r >> 5) & 0x200) |
		       ((r >> 3) & 0x100) | ((r >> 2) & 0x080) | ((r << 1) & 0x040) |
		       ((r << 3) & 0x020) | ((r << 4) & 0x010);
	}
	return out;
}

int sid_cycle(sid_t *s)
{
	long sum = 0;
	int i;

	for (i = 0; i < 3; i++) {
		sid_voice_t *v = &s->v[i];

		if (!(v->ctrl & 0x08)) {
			uint32_t prev = v->acc;

			v->acc = (v->acc + v->freq) & 0xFFFFFF;
			if (!(prev & 0x080000) && (v->acc & 0x080000)) {
				uint32_t r = v->noise;
				v->noise = ((r << 1) | (((r >> 22) ^ (r >> 17)) & 1)) & 0x7FFFFF;
			}
		}
		envelope(v);
		sum += ((long)waveform(v) - 0x800) * v->env;
	}
	return (int)((sum * s->vol) >> 10);
}
