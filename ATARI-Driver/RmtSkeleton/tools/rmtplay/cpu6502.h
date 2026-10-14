/*
 * cpu6502.h - minimal NMOS 6502 core (documented opcodes only)
 *
 * Enough to run the RMT player routine: no interrupts; cycles are counted
 * per instruction (NMOS timing, page crossing, branches), without DMA.
 */
#ifndef CPU6502_H
#define CPU6502_H

#include <stdint.h>

typedef struct {
	uint16_t pc;
	uint8_t a, x, y, s, p;
	uint8_t *mem;                                   /* 64 KB */
	void (*write_hook)(uint16_t addr, uint8_t val); /* I/O writes $D000-$D7FF */
	uint8_t (*read_hook)(uint16_t addr);            /* I/O reads $D000-$D7FF, NULL = RAM */
	unsigned long cycles;                           /* CPU cycles run, no DMA */
	uint8_t cross;                                  /* page crossed by the last indexed address */
} cpu6502_t;

/* Run a subroutine (JSR addr) with the given registers until it returns.
 * Returns 0 on success, -1 on illegal opcode or runaway code. */
int cpu_call(cpu6502_t *c, uint16_t addr, uint8_t a, uint8_t x, uint8_t y);

#endif
