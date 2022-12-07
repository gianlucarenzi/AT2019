//
// 6502 Memory access tester
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#ifndef CBM
#include <atari.h>
/* Font */
#include "c64.h"
#else
#include <cbm.h>
#endif
#include <cc65.h>
#include <6502.h>
#include <stdlib.h>
#include <peekpoke.h>
#include <time.h>
#include "version.h"

#define PLP()	__asm__("plp")
#define PHP()	__asm__("php")

#define ArraySize(a)	(sizeof(a)/sizeof(a[0]))
#define peek(a)		PEEK(a)
#define poke(a,b)	POKE(a,b)

#if defined(ATARI) || defined(ATARIXL)
#warning "ATARI COMPUTER BUILD"
#define VDP_ADDR	0xD500
#define SRCMEM		0x0600
#elif defined(CBM)
#warning "COMMODORE 64 COMPUTER BUILD"
#define VDP_ADDR	0xDE00
#define SRCMEM		0xC000
#else
#error "NO MACHINE DEFINED"
#endif

#define VDP_REG_SZ	(1 << 5) // 32 registers
#define VDP_MEM		(VDP_ADDR + VDP_REG_SZ)
#define VDP_BUF_SZ	(0xFF - VDP_REG_SZ)

static clock_t ticks = 0;

static void jiffies_init(void)
{
	ticks = clock();
}

static int jiffies_elapsed(int j)
{
	register unsigned int _ticks = clock();

	if (_ticks > (ticks + j))
		return 1;
	else
		return 0;
}

static void prepare_screen(void)
{
#ifndef CBM
	#define CHBASE		0xE000
	#define CHRAMBASE	0x8000
	#define CHBASEOS	0x02F4

	int reg;
	unsigned char * chargen;
	unsigned char * charbase;
	unsigned char * chbase = (unsigned char *) CHBASEOS;
	unsigned char * addr;

	charbase = (unsigned char *) CHBASE;
	// New character base
	chargen = (unsigned char *) CHRAMBASE;
	memcpy(chargen, charbase, 1024);

	// Commodore 64 Chargen ROM */
	// chars from 0 to 31 ' !"#...
	addr = (unsigned char *) (chargen + (0 * 8));
	for (reg = 0; reg < (32 * 8); reg++)
		*(addr + reg) = c64_font[reg + (32 * 8)];

	// chars from 32 to 63 '@ABC...[\]^_
	addr = (unsigned char *) (chargen + (32 * 8));
	for (reg = 0; reg < (32 * 8); reg++)
		*(addr + reg) = c64_font[reg];

	// chars from 64 to 95...
	addr = (unsigned char *) (chargen + (64 * 8));
	for (reg = 0; reg < (32 * 8); reg++)
		*(addr + reg) = c64_font[reg + (64 * 8)];

	// Still uses pokes here, to improve readability
	poke(709, 14);
	poke(712, 120);
	poke(710, 116);

	*(chbase) = (CHRAMBASE & 0xff00) >> 8;
#endif
	clrscr();
}

int main(void)
{
	register char c;
	register unsigned int blks = 0;
	register unsigned int blksize = VDP_BUF_SZ;

	prepare_screen();

	printf("\nRETROBITLAB MEMORY ACCESS TESTER\n");

#if 1
	for (c = 0; c <= blksize; c += 32)
	{
		// Start from 32 bytes as minimum
		blks = 0;
		printf("Block size: %04d bytes\n", c);
		jiffies_init();
		for (;;)
		{
			if (jiffies_elapsed(50))
				break;
			memcpy((unsigned char *)SRCMEM, (unsigned char *)VDP_MEM, c);
			++blks;
		}
		printf("Blocks: %04d -- Size: %u bytes/sec\n", blks, (blks * c));
	}
	// Do Last computation
	c = blksize;
	blks = 0;
	printf("Last Block: %04d bytes\n", c);
	jiffies_init();
	for (;;)
	{
		if (jiffies_elapsed(50))
			break;
		memcpy((unsigned char *)SRCMEM, (unsigned char *)VDP_MEM, c);
		++blks;
	}
	printf("Last: %04d -- Size: %u bytes/sec\n", blks, (blks * c));
#endif
	// NEVERREACHED
	c = cgetc();
	return(0);
}
