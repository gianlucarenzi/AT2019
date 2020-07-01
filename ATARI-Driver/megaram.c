//
// OS ROM RAM Expansion Checker
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include <atari.h>
#include <cc65.h>
#include <6502.h>
#include <stdlib.h>
#include <peekpoke.h>
#include "version.h"
#include "c64.h"

#define PLP()	__asm__("plp")
#define PHP()	__asm__("php")

#define ArraySize(a)	(sizeof(a)/sizeof(a[0]))
#define peek(a)		PEEK(a)
#define poke(a,b)	POKE(a,b)

static int nmien_reg = 0;
static unsigned char * nmien = (unsigned char *) 0xD40E;
#define CRAZY_COLOR		poke((unsigned char *) 0xD01A, rand());

#define ENTER_CRITICAL() \
	SEI(); \
	nmien_reg = peek(nmien); \
	poke(nmien, 0);

#define EXIT_CRITICAL() \
	poke(nmien, nmien_reg); \
	CLI();

static int mode_576k[32] = {
	0x80, 0x82, 0x84, 0x86, 0x88, 0x8A, 0x8C, 0x8E,
	0xA0, 0xA2, 0xA4, 0xA6, 0xA8, 0xAA, 0xAC, 0xAE,
	0xC0, 0xC2, 0xC4, 0xC6, 0xC8, 0xCA, 0xCC, 0xCE,
	0xE0, 0xE2, 0xE4, 0xE6, 0xE8, 0xEA, 0xEC, 0xEE,
}; 

static int mode_130xe[8] = {
	0xA2, 0xA6, 0xAA, 0xAE, 0xE2, 0xE6, 0xEA, 0xEE,
};

static int bank_val[32] = {
	0xde, 0xad, 0xbe, 0xef, 0xfe, 0xed, 0xf0, 0x0d, // dead beef feed f00d
	0x00, 0xff, 0x2a, 0xa2, 0xcc, 0x33, 0xfe, 0xef, // inverse
	0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, // walking one
	0xfe, 0xfd, 0xfb, 0xf7, 0xef, 0xdf, 0xbf, 0x7f, // walking zero
};

static void asm_delay(int l)
{
	int c;
	for (c = 0; c < l; c++)
		__asm__("nop");
}

static void delay(int l)
{
	int c;
	for (c = 0; c < l; c++)
		asm_delay(255);
}

static void setbank(int reg)
{
	unsigned char * portb = (unsigned char *) 0xD301;
	ENTER_CRITICAL();
	poke(portb, reg);
	EXIT_CRITICAL();
	delay(1);
}

int main(void)
{
	int reg;
	int m_portb, dmareg;
	char c;
	unsigned char * wram = (unsigned char *) 0x4800; // RAM window (under SELFTEST ROM but within 0x4000-0x7FFF range
	unsigned char * portb = (unsigned char *) 0xD301;
	unsigned char * osrom;
	int count, i, bad;
	unsigned char fake[] = {
		'L', 'O', 'A', 'D', '"', '$', '"', ',', '8', ',', '1', 0x9b, 0x9b,
		'S', 'E', 'A', 'R', 'C', 'H', 'I', 'N', 'G', ' ', 'F', 'O', 'R', ' ', '$', 0x9b,
		'L', 'O', 'A', 'D', 'I', 'N', 'G', 0x9b,
		'\0'// must be last!
	};
	unsigned char * ptr;

	dmareg = peek(559);
	m_portb = peek(portb);

	// Turns off DMA
	poke(559, 0);
	srand(0xdeadbeef);
	clrscr();

#ifndef __ATARIXL__
#error "Use target as atarixl"
#endif

	// This program must be compiled and linked with the cc65 unique feature
	// of startup C code for mode: atarixl. It change the OS from
	// ROM to RAM!!

	// Commodore 64 Chargen ROM */
	// chars from 0 to 31 ' !"#...
	osrom = (unsigned char *) 0xE000;
	count = 32;
	for (reg = 0; reg < (count * 8); reg++)
		*(osrom + reg) = c64_font[reg + (32 * 8)];

	// chars from 32 to 63 '@ABC...[\]^_
	osrom = (unsigned char *) (0xE000 + ('@' - 32) * 8);
	for (reg = 0; reg < (count * 8); reg++)
		*(osrom + reg) = c64_font[reg];

	// chars from 64 to 95...
	osrom = (unsigned char *) (0xE000 + (64 * 8));
	for (reg = 0; reg < (count * 8); reg++)
		*(osrom + reg) = c64_font[reg + (64 * 8)];

	poke(709, 14);
	poke(712, 120);
	poke(710, 116);

	printf("\n  **** ATARI 130XE MEMORY TESTER ****\n\n");
	printf(" 576K INTERNAL EXPANSION RAM SYSTEM BY\n         Scott Peterson (c) 1986\n");
	printf("   written by Gianluca Renzi (c) 2020\n\n");
	printf("READY.\n");

	// Turns on DMA
	poke(559, dmareg);

	// Fake typing... ;-)
	ptr = fake;
	for (i = 0; i < 120; i++)
	{
		if (*(ptr) == '\0')
			break;
		putchar(*(ptr));
		ptr++;
		delay(1);
	}
	printf("READY.\n%c\n\n", 128 + ' ');
	delay(50);

	count = 0;
	bad = 0;
	// 130XE mode: 192K RAM Pia Port B bank selection bit 2,3,6
	printf("Checking 130XE Mode: ");
	for (i = 0; i < 8; i++)
	{
		// There is no way to disable this expansion
		// So the only way to check if it is working good, is to write/read
		// at the window address a well known data structures...

		//
		// 7 6 5 4 3 2 1 0 
		// - X - - X X - -
		// 
		// Now accessing @ bank # (CPU & ANTIC)
		reg = mode_130xe[i];		// Select BANK #
		setbank(reg);
		poke(wram, bank_val[i]);	// Write i @ bank # @
		CRAZY_COLOR;
	}

	for (i = 0; i < 8; i++)
	{
		reg = mode_130xe[i];		// Select BANK #
		setbank(reg);
		// Now read RAM WINDOWED DATA
		reg = peek(wram);
		CRAZY_COLOR;
		// Test if it is the correct value written
		if (reg == bank_val[i])
		{
			// If it is correct, assume the bank is good!
			count++;
		}
		else
		{
			//printf("ERROR Bank #%d - R $%02x - E $%02x\n",
			//		i, reg, bank_val[ i ]);
			bad++;
			delay(10);
		}
	}
	setbank(m_portb);
	// 130xe mode = 128k + 64k
	printf("%dK GOOD.\n", count * 16);
	if (bad > 0)
		printf("FAILED BANK: %d\n", bad); 

	// 576K mode: 576K RAM Pia Port B bank selection bit 1,2,3,5,6 (bit 4 must be 0)
	count = 0;
	bad = 0;
	printf("Checking  576K Mode: ");
	for (i = 0; i < 32; i++)
	{
		// There is no way to disable this expansion
		// So the only way to check if it is working good, is to write/read
		// at the window address a well known data structures...

		//
		// 7 6 5 4 3 2 1 0 
		// - X - - X X - -
		// 
		// Now accessing @ bank # (CPU & ANTIC)
		reg = mode_576k[i];		// Select BANK #
		setbank(reg);
		poke(wram, bank_val[i]);	// Write i @ bank # @
		CRAZY_COLOR;
	}

	for (i = 0; i < 32; i++)
	{
		reg = mode_576k[i];		// Select BANK #
		setbank(reg);
		// Now read RAM WINDOWED DATA
		reg = peek(wram);
		CRAZY_COLOR;
		// Test if it is the correct value written
		if (reg == bank_val[i])
		{
			// If it is correct, assume the bank is good!
			count++;
		}
		else
		{
			//printf("ERROR Bank #%d - R $%02x - E $%02x\n",
			//	i, reg, bank_val[ i ]);
			bad++;
			delay(10);
		}
	}
	setbank(m_portb);
	// 576k mode = 512k + 64k
	printf("%dK GOOD.\n", count * 16);
	if (bad > 0)
		printf("FAILED BANK: %d\n", bad); 

	for (;;) {
		CRAZY_COLOR;
	}
	// NEVERREACHED
	c = cgetc();
	return(0);
}
