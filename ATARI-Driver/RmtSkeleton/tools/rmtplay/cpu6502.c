/*
 * cpu6502.c - minimal NMOS 6502 core (documented opcodes only)
 *
 * Runs the real RMT player routine (src/rmtplayr.s assembled by ca65) on the
 * PC (and, for the C64 build, ../../../rmt_cbm64/src/sidrmt.s). No cycle
 * timing and no interrupts: the player is called once per frame
 * and its POKEY writes are applied at the start of the frame.
 */
#include <stdio.h>
#include "cpu6502.h"

#define FC 0x01
#define FZ 0x02
#define FI 0x04
#define FD 0x08
#define FB 0x10
#define FU 0x20
#define FV 0x40
#define FN 0x80

#define RETURN_TRAP 0x0203      /* JSR stub at $0200, returns here */
#define MAX_STEPS   200000      /* the player takes a few thousand at most */

static uint8_t rd(cpu6502_t *c, uint16_t a)
{
	if (c->read_hook && (a & 0xF800) == 0xD000)
		return c->read_hook(a);
	return c->mem[a];
}

static void wr(cpu6502_t *c, uint16_t a, uint8_t v)
{
	if (a >= 0xD000 && a < 0xD800) {
		if (c->write_hook)
			c->write_hook(a, v);
		return;
	}
	c->mem[a] = v;
}

static uint16_t rd16(cpu6502_t *c, uint16_t a)
{
	return rd(c, a) | (rd(c, (uint16_t)(a + 1)) << 8);
}

static uint16_t rd16zp(cpu6502_t *c, uint8_t a)
{
	return rd(c, a) | (rd(c, (uint8_t)(a + 1)) << 8);
}

static void push(cpu6502_t *c, uint8_t v) { c->mem[0x100 + c->s--] = v; }
static uint8_t pull(cpu6502_t *c) { return c->mem[0x100 + ++c->s]; }

static void setnz(cpu6502_t *c, uint8_t v)
{
	c->p = (c->p & ~(FN | FZ)) | (v & FN) | (v ? 0 : FZ);
}

static void adc(cpu6502_t *c, uint8_t v)
{
	unsigned carry = c->p & FC;
	if (c->p & FD) {
		unsigned lo = (c->a & 0x0F) + (v & 0x0F) + carry;
		unsigned hi = (c->a & 0xF0) + (v & 0xF0);
		if (lo > 9) { lo += 6; hi += 0x10; }
		uint8_t bin = (uint8_t)(c->a + v + carry);
		c->p &= ~(FN | FZ | FV | FC);
		if (!bin) c->p |= FZ;
		if (hi & 0x80) c->p |= FN;
		if (~(c->a ^ v) & (c->a ^ hi) & 0x80) c->p |= FV;
		if (hi > 0x90) { hi += 0x60; }
		if (hi > 0xFF) c->p |= FC;
		c->a = (uint8_t)((hi & 0xF0) | (lo & 0x0F));
		return;
	}
	unsigned r = c->a + v + carry;
	c->p &= ~(FC | FV);
	if (r > 0xFF) c->p |= FC;
	if (~(c->a ^ v) & (c->a ^ r) & 0x80) c->p |= FV;
	c->a = (uint8_t)r;
	setnz(c, c->a);
}

static void sbc(cpu6502_t *c, uint8_t v)
{
	if (c->p & FD) {
		unsigned borrow = (c->p & FC) ? 0 : 1;
		int lo = (c->a & 0x0F) - (v & 0x0F) - borrow;
		int hi = (c->a & 0xF0) - (v & 0xF0);
		unsigned r = c->a - v - borrow;
		if (lo < 0) { lo -= 6; hi -= 0x10; }
		if (hi < 0) hi -= 0x60;
		c->p &= ~(FC | FV);
		if (r < 0x100) c->p |= FC;
		if ((c->a ^ v) & (c->a ^ r) & 0x80) c->p |= FV;
		setnz(c, (uint8_t)r);
		c->a = (uint8_t)((hi & 0xF0) | (lo & 0x0F));
		return;
	}
	adc(c, (uint8_t)~v);
}

static void cmp(cpu6502_t *c, uint8_t reg, uint8_t v)
{
	unsigned r = reg - v;
	c->p = (c->p & ~FC) | (reg >= v ? FC : 0);
	setnz(c, (uint8_t)r);
}

static uint8_t asl(cpu6502_t *c, uint8_t v)
{
	c->p = (c->p & ~FC) | (v >> 7);
	v <<= 1;
	setnz(c, v);
	return v;
}

static uint8_t lsr(cpu6502_t *c, uint8_t v)
{
	c->p = (c->p & ~FC) | (v & 1);
	v >>= 1;
	setnz(c, v);
	return v;
}

static uint8_t rol(cpu6502_t *c, uint8_t v)
{
	uint8_t r = (uint8_t)((v << 1) | (c->p & FC));
	c->p = (c->p & ~FC) | (v >> 7);
	setnz(c, r);
	return r;
}

static uint8_t ror(cpu6502_t *c, uint8_t v)
{
	uint8_t r = (uint8_t)((v >> 1) | ((c->p & FC) << 7));
	c->p = (c->p & ~FC) | (v & 1);
	setnz(c, r);
	return r;
}

static void bit(cpu6502_t *c, uint8_t v)
{
	c->p = (c->p & ~(FN | FV | FZ)) | (v & (FN | FV)) | ((c->a & v) ? 0 : FZ);
}

static void branch(cpu6502_t *c, int cond)
{
	int8_t off = (int8_t)rd(c, c->pc++);
	if (cond) {
		uint16_t t = (uint16_t)(c->pc + off);
		c->cycles += 1 + ((t ^ c->pc) >> 8 != 0);       /* taken, page crossed */
		c->pc = t;
	}
}

/* effective addresses */
static uint16_t a_zp(cpu6502_t *c)  { return rd(c, c->pc++); }
static uint16_t a_zpx(cpu6502_t *c) { return (uint8_t)(rd(c, c->pc++) + c->x); }
static uint16_t a_zpy(cpu6502_t *c) { return (uint8_t)(rd(c, c->pc++) + c->y); }
static uint16_t a_abs(cpu6502_t *c) { uint16_t a = rd16(c, c->pc); c->pc += 2; return a; }
static uint16_t indexed(cpu6502_t *c, uint16_t base, uint8_t i)
{
	uint16_t a = (uint16_t)(base + i);
	c->cross = (a ^ base) >> 8 != 0;
	return a;
}
static uint16_t a_abx(cpu6502_t *c) { return indexed(c, a_abs(c), c->x); }
static uint16_t a_aby(cpu6502_t *c) { return indexed(c, a_abs(c), c->y); }
static uint16_t a_izx(cpu6502_t *c) { return rd16zp(c, (uint8_t)(rd(c, c->pc++) + c->x)); }
static uint16_t a_izy(cpu6502_t *c) { return indexed(c, rd16zp(c, rd(c, c->pc++)), c->y); }
static uint16_t a_imm(cpu6502_t *c) { return c->pc++; }

/* read-modify-write helper */
#define RMW(mode, fn) { uint16_t ea = mode(c); wr(c, ea, fn(c, rd(c, ea))); } break

static uint8_t inc(cpu6502_t *c, uint8_t v) { v++; setnz(c, v); return v; }
static uint8_t dec(cpu6502_t *c, uint8_t v) { v--; setnz(c, v); return v; }

/* ALU group: ORA AND EOR ADC STA LDA CMP SBC, 8 addressing modes each */
static int alu(cpu6502_t *c, uint8_t op)
{
	uint16_t ea;
	switch (op & 0x1F) {
	case 0x01: ea = a_izx(c); break;
	case 0x05: ea = a_zp(c);  break;
	case 0x09: ea = a_imm(c); break;
	case 0x0D: ea = a_abs(c); break;
	case 0x11: ea = a_izy(c); break;
	case 0x15: ea = a_zpx(c); break;
	case 0x19: ea = a_aby(c); break;
	case 0x1D: ea = a_abx(c); break;
	default: return -1;
	}
	switch (op >> 5) {
	case 0: c->a |= rd(c, ea); setnz(c, c->a); break;
	case 1: c->a &= rd(c, ea); setnz(c, c->a); break;
	case 2: c->a ^= rd(c, ea); setnz(c, c->a); break;
	case 3: adc(c, rd(c, ea)); break;
	case 4: if (op == 0x89) return -1; wr(c, ea, c->a); break;
	case 5: c->a = rd(c, ea); setnz(c, c->a); break;
	case 6: cmp(c, c->a, rd(c, ea)); break;
	case 7: sbc(c, rd(c, ea)); break;
	}
	return 0;
}

/* NMOS 6502 cycles per opcode (documented ones), without the extra cycle of
 * a page crossing or of a taken branch */
static const uint8_t cycletab[256] = {
	7,6,0,0,0,3,5,0,3,2,2,0,0,4,6,0, 2,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0,
	6,6,0,0,3,3,5,0,4,2,2,0,4,4,6,0, 2,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0,
	6,6,0,0,0,3,5,0,3,2,2,0,3,4,6,0, 2,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0,
	6,6,0,0,0,3,5,0,4,2,2,0,5,4,6,0, 2,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0,
	0,6,0,0,3,3,3,0,2,0,2,0,4,4,4,0, 2,6,0,0,4,4,4,0,2,5,2,0,0,5,0,0,
	2,6,2,0,3,3,3,0,2,2,2,0,4,4,4,0, 2,5,0,0,4,4,4,0,2,4,2,0,4,4,4,0,
	2,6,0,0,3,3,5,0,2,2,2,0,4,4,6,0, 2,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0,
	2,6,0,0,3,3,5,0,2,2,2,0,4,4,6,0, 2,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0,
};

/* reads with abs,X / abs,Y / (zp),Y: one more cycle when the page is crossed */
static int cross_penalty(uint8_t op)
{
	switch (op) {
	case 0x11: case 0x19: case 0x1D: case 0x31: case 0x39: case 0x3D:
	case 0x51: case 0x59: case 0x5D: case 0x71: case 0x79: case 0x7D:
	case 0xB1: case 0xB9: case 0xBD: case 0xD1: case 0xD9: case 0xDD:
	case 0xF1: case 0xF9: case 0xFD: case 0xBC: case 0xBE:
		return 1;
	}
	return 0;
}

static int exec(cpu6502_t *c, uint8_t op);

static int step(cpu6502_t *c)
{
	uint8_t op = rd(c, c->pc++);
	int r;

	c->cross = 0;
	c->cycles += cycletab[op];
	r = exec(c, op);
	if (c->cross && cross_penalty(op))
		c->cycles++;
	return r;
}

static int exec(cpu6502_t *c, uint8_t op)
{
	uint16_t ea;

	if ((op & 0x03) == 0x01)
		return alu(c, op);

	switch (op) {
	/* loads / stores */
	case 0xA2: c->x = rd(c, a_imm(c)); setnz(c, c->x); break;
	case 0xA6: c->x = rd(c, a_zp(c));  setnz(c, c->x); break;
	case 0xB6: c->x = rd(c, a_zpy(c)); setnz(c, c->x); break;
	case 0xAE: c->x = rd(c, a_abs(c)); setnz(c, c->x); break;
	case 0xBE: c->x = rd(c, a_aby(c)); setnz(c, c->x); break;
	case 0xA0: c->y = rd(c, a_imm(c)); setnz(c, c->y); break;
	case 0xA4: c->y = rd(c, a_zp(c));  setnz(c, c->y); break;
	case 0xB4: c->y = rd(c, a_zpx(c)); setnz(c, c->y); break;
	case 0xAC: c->y = rd(c, a_abs(c)); setnz(c, c->y); break;
	case 0xBC: c->y = rd(c, a_abx(c)); setnz(c, c->y); break;
	case 0x86: wr(c, a_zp(c), c->x);  break;
	case 0x96: wr(c, a_zpy(c), c->x); break;
	case 0x8E: wr(c, a_abs(c), c->x); break;
	case 0x84: wr(c, a_zp(c), c->y);  break;
	case 0x94: wr(c, a_zpx(c), c->y); break;
	case 0x8C: wr(c, a_abs(c), c->y); break;

	/* transfers */
	case 0xAA: c->x = c->a; setnz(c, c->x); break;
	case 0x8A: c->a = c->x; setnz(c, c->a); break;
	case 0xA8: c->y = c->a; setnz(c, c->y); break;
	case 0x98: c->a = c->y; setnz(c, c->a); break;
	case 0xBA: c->x = c->s; setnz(c, c->x); break;
	case 0x9A: c->s = c->x; break;

	/* stack */
	case 0x48: push(c, c->a); break;
	case 0x68: c->a = pull(c); setnz(c, c->a); break;
	case 0x08: push(c, c->p | FB | FU); break;
	case 0x28: c->p = pull(c) | FU; break;

	/* inc / dec */
	case 0xE8: c->x++; setnz(c, c->x); break;
	case 0xCA: c->x--; setnz(c, c->x); break;
	case 0xC8: c->y++; setnz(c, c->y); break;
	case 0x88: c->y--; setnz(c, c->y); break;
	case 0xE6: RMW(a_zp, inc);
	case 0xF6: RMW(a_zpx, inc);
	case 0xEE: RMW(a_abs, inc);
	case 0xFE: RMW(a_abx, inc);
	case 0xC6: RMW(a_zp, dec);
	case 0xD6: RMW(a_zpx, dec);
	case 0xCE: RMW(a_abs, dec);
	case 0xDE: RMW(a_abx, dec);

	/* shifts */
	case 0x0A: c->a = asl(c, c->a); break;
	case 0x4A: c->a = lsr(c, c->a); break;
	case 0x2A: c->a = rol(c, c->a); break;
	case 0x6A: c->a = ror(c, c->a); break;
	case 0x06: RMW(a_zp, asl);
	case 0x16: RMW(a_zpx, asl);
	case 0x0E: RMW(a_abs, asl);
	case 0x1E: RMW(a_abx, asl);
	case 0x46: RMW(a_zp, lsr);
	case 0x56: RMW(a_zpx, lsr);
	case 0x4E: RMW(a_abs, lsr);
	case 0x5E: RMW(a_abx, lsr);
	case 0x26: RMW(a_zp, rol);
	case 0x36: RMW(a_zpx, rol);
	case 0x2E: RMW(a_abs, rol);
	case 0x3E: RMW(a_abx, rol);
	case 0x66: RMW(a_zp, ror);
	case 0x76: RMW(a_zpx, ror);
	case 0x6E: RMW(a_abs, ror);
	case 0x7E: RMW(a_abx, ror);

	/* compares */
	case 0xE0: cmp(c, c->x, rd(c, a_imm(c))); break;
	case 0xE4: cmp(c, c->x, rd(c, a_zp(c)));  break;
	case 0xEC: cmp(c, c->x, rd(c, a_abs(c))); break;
	case 0xC0: cmp(c, c->y, rd(c, a_imm(c))); break;
	case 0xC4: cmp(c, c->y, rd(c, a_zp(c)));  break;
	case 0xCC: cmp(c, c->y, rd(c, a_abs(c))); break;
	case 0x24: bit(c, rd(c, a_zp(c)));  break;
	case 0x2C: bit(c, rd(c, a_abs(c))); break;

	/* branches */
	case 0x10: branch(c, !(c->p & FN)); break;
	case 0x30: branch(c, c->p & FN);    break;
	case 0x50: branch(c, !(c->p & FV)); break;
	case 0x70: branch(c, c->p & FV);    break;
	case 0x90: branch(c, !(c->p & FC)); break;
	case 0xB0: branch(c, c->p & FC);    break;
	case 0xD0: branch(c, !(c->p & FZ)); break;
	case 0xF0: branch(c, c->p & FZ);    break;

	/* jumps */
	case 0x4C: c->pc = a_abs(c); break;
	case 0x6C:                          /* NMOS page wrap bug */
		ea = a_abs(c);
		c->pc = rd(c, ea) | (rd(c, (uint16_t)((ea & 0xFF00) | ((ea + 1) & 0xFF))) << 8);
		break;
	case 0x20:
		ea = a_abs(c);
		c->pc--;
		push(c, c->pc >> 8);
		push(c, c->pc & 0xFF);
		c->pc = ea;
		break;
	case 0x60:
		c->pc = pull(c);
		c->pc |= pull(c) << 8;
		c->pc++;
		break;
	case 0x40:
		c->p = pull(c) | FU;
		c->pc = pull(c);
		c->pc |= pull(c) << 8;
		break;

	/* flags */
	case 0x18: c->p &= ~FC; break;
	case 0x38: c->p |= FC;  break;
	case 0x58: c->p &= ~FI; break;
	case 0x78: c->p |= FI;  break;
	case 0xB8: c->p &= ~FV; break;
	case 0xD8: c->p &= ~FD; break;
	case 0xF8: c->p |= FD;  break;
	case 0xEA: break;

	default:
		fprintf(stderr, "cpu6502: illegal opcode $%02X at $%04X\n", op, (uint16_t)(c->pc - 1));
		return -1;
	}
	return 0;
}

int cpu_call(cpu6502_t *c, uint16_t addr, uint8_t a, uint8_t x, uint8_t y)
{
	long n;

	c->mem[0x0200] = 0x20;                  /* JSR addr */
	c->mem[0x0201] = addr & 0xFF;
	c->mem[0x0202] = addr >> 8;
	c->pc = 0x0200;
	c->a = a;
	c->x = x;
	c->y = y;
	c->s = 0xFF;
	c->p = FU | FI;

	for (n = 0; n < MAX_STEPS; n++) {
		if (c->pc == RETURN_TRAP)
			return 0;
		if (step(c))
			return -1;
	}
	fprintf(stderr, "cpu6502: routine $%04X did not return\n", addr);
	return -1;
}
