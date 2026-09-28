/*
 * cpu6502.h - minimal NMOS 6502 core (documented opcodes only)
 *
 * Enough to run the RMT player routine: no cycle timing, no interrupts.
 */
#ifndef CPU6502_H
#define CPU6502_H

#include <stdint.h>

typedef struct {
	uint16_t pc;
	uint8_t a, x, y, s, p;
	uint8_t *mem;                                   /* 64 KB */
	void (*write_hook)(uint16_t addr, uint8_t val); /* I/O writes $D000-$D7FF */
} cpu6502_t;

/* Run a subroutine (JSR addr) with the given registers until it returns.
 * Returns 0 on success, -1 on illegal opcode or runaway code. */
int cpu_call(cpu6502_t *c, uint16_t addr, uint8_t a, uint8_t x, uint8_t y);

#endif
