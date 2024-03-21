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

#define PLP()	__asm__("plp")
#define PHP()	__asm__("php")

#define ArraySize(a)	(sizeof(a)/sizeof(a[0]))
#define peek(a)		PEEK(a)
#define poke(a,b)	POKE(a,b)

#if defined(ATARI) || defined(ATARIXL)
	#warning "ATARI COMPUTER BUILD"
	#define VDP_ADDR	0xD500 /* _CCTL pin 15 Cart Port */
#elif defined(CBM)
	#warning "COMMODORE 64 COMPUTER BUILD"
	#define VDP_ADDR	0xDE00 /* _IO1 pin 7 Cart Port */
#else
	#error "NO MACHINE DEFINED"
#endif

#define SRCMEM		0xC000

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

	// Commodore 64 Chargen ROM
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

static unsigned char gpu = 0;
static unsigned char use_gpu = 1;

static void ask_gpu(void)
{
#ifdef FORCE_BENCHMARK
	char buf[2];
	printf("\n---> Use GPU (Y/N)? ");
	scanf("%s", buf);
	use_gpu = (buf[0] == 'Y'| buf[0] == 'y') ? 1 : 0;
	printf("\n");
#endif
}

static void enable_gpu(void)
{
#ifdef FORCE_BENCHMARK
	if (!use_gpu)
	{
	#ifdef CBM
		poke(0xD011, gpu);
	#else
		poke(559, gpu);
	#endif
	}
#endif
}

static void disable_gpu(void)
{
#ifdef FORCE_BENCHMARK
	if (!use_gpu)
	{
	#ifdef CBM
		gpu = peek(0xD011);
		poke(0xD011, 0x0b);
	#else
		gpu = peek(559);
		poke(559,0);
	#endif
	}
#endif
}

int main(void)
{
	register char c;
	register unsigned int blks = 0;
	register unsigned int blksize = VDP_BUF_SZ;
	long sizes;

	prepare_screen();

	printf("\nRETROBITLAB MEMORY ACCESS TESTER\n");
#ifdef CBM
	printf("   FOR COMMODORE 64 COMPUTERS\n");
#endif
#ifdef ATARIXL
	printf("   FOR ATARI XL/XE COMPUTERS\n");
#endif
#ifdef ATARI
	printf("   FOR ATARI 400/800 COMPUTERS\n");
#endif

	ask_gpu();

	disable_gpu();

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
		sizes = 1L * blks * c;
		printf("Blocks: %04d -- Size: %ld bytes/sec\n\n", blks, sizes);
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
	sizes = 1L * blks * c;
	printf("Blocks: %04d -- Size: %ld bytes/sec\n", blks, sizes);
	enable_gpu();

	// NEVERREACHED
	c = cgetc();
	return(0);
}
