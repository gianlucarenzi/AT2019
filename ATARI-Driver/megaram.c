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

#define OS_ROM_ENA          (1 << 0)
#define OS_ROM_DISABLE_MASK (0xFE)
#define SELF_TEST_DISABLE   (1 << 7)

#define CHBASE		0xE000
#define CHRAMBASE	0x8000
#define WRAM		0x5000
#define PORTB		0xD301
#define CHBASEOS	0x02F4
#define SDMCTL		0x022F

#define ENTER_CRITICAL() \
	SEI(); \
	nmien_reg = peek(nmien); \
	poke(nmien, 0);

#define EXIT_CRITICAL() \
	poke(nmien, nmien_reg); \
	CLI();

static int mode_576k[32] = {
	0x81, 0x83, 0x85, 0x87, 0x89, 0x8B, 0x8D, 0x8F,
	0xA1, 0xA3, 0xA5, 0xA7, 0xA9, 0xAB, 0xAD, 0xAF,
	0xC1, 0xC3, 0xC5, 0xC7, 0xC9, 0xCB, 0xCD, 0xCF,
	0xE1, 0xE3, 0xE5, 0xE7, 0xE9, 0xEB, 0xED, 0xEF,
};

static int mode_130xe[8] = {
	0xA3, 0xA7, 0xAB, 0xAF, 0xE3, 0xE7, 0xEB, 0xEF,
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
		asm_delay(64);
}

static void setbank(int reg)
{
	unsigned char * portb = (unsigned char *) 0xD301;
	ENTER_CRITICAL();
	*(portb) = reg & OS_ROM_DISABLE_MASK; // Using RAM based OS (linker as -t atarixl)
	EXIT_CRITICAL();
	delay(1);
}

static unsigned char *scroll =
		"                                       "
		"Questo video e' stato prodotto per Federico Di Dato a.k.a. RetroBitLab"
		" e la sua cricca di compagni di merende, in attesa di essere rintracciati "
		" e successivamente giustiziati da una folla inferocita che grida vendetta..."
		"      Questa volta come ogni bella intro scroller abbiamo "
		"messo anche del testo che non siano i soliti ringraziamenti "
		" ;-) GRAZIE a tutti, a xAD Nightfall Crew ed anche a JAN BETA...         "
		"                          ";

static void do_scroll(int reset)
{
	static int scrlen = -1;
	static unsigned char *ptr;
	static int chr = 0;
	unsigned char buf[41];

	if (scrlen < 0 || reset) {
		scrlen = strlen(scroll);
		ptr = scroll;
		memset(buf, 0, 41);
		chr = 0;
	}
	strncpy(buf, ptr, 40);
	gotoxy(0, 21);
	cprintf("%s", buf);
	++ptr;
	++chr;
	if (chr > scrlen) {
		ptr = scroll;
		chr = 0;
	}
}

static unsigned char clut[256] = { 0 };

static void crazy_color(void)
{
	static unsigned char idx = 0;
	*((unsigned char *) 0xD01A) = clut[idx];
	++idx;
	if ( idx > 255 )
		idx = 0;
}

int main(void)
{
	int reg;
	int m_portb, dmareg;
	char c;
	unsigned char * wram  = (unsigned char *) WRAM; // RAM window (under SELFTEST ROM but within 0x4000-0x7FFF range
	unsigned char * portb = (unsigned char *) PORTB;
	unsigned char * sdmctl = (unsigned char *) SDMCTL;
	unsigned char * chargen;
	unsigned char * charbase;
	unsigned char * chbase = (unsigned char *) CHBASEOS;
	unsigned char * addr;
	int count, i, bad;
	unsigned char *fake =
			"LOAD \"$\",8,1\n\n"
			"Little  adventures into  retrocomputing \n"
			"world of 8bit and other  computers from \n"
			"             last century...\n\n";
	unsigned char * ptr;

	dmareg = *(sdmctl);
	ENTER_CRITICAL();
#ifdef __ATARIXL__
	m_portb = *(portb);
	m_portb &= OS_ROM_DISABLE_MASK;
	*(portb) = m_portb;
#endif

	// Turns off DMA
	*(sdmctl) = 0;
	srand(0xdeadbeef);

	charbase = (unsigned char *) CHBASE;
#ifndef __ATARIXL__
	// New character base
	chargen = (unsigned char *) CHRAMBASE;
	memcpy(chargen, charbase, 1024);
#else
	// Character base in ROM/RAM
	chargen = charbase;
#endif
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

	/* Fill in the clut */
	for (reg = 0; reg < 256; reg++)
		clut[reg] = rand();

	EXIT_CRITICAL();
	// Turns on DMA
	*(sdmctl) = dmareg;

#ifndef __ATARIXL__
	*(chbase) = (CHRAMBASE & 0xff00) >> 8;
#else
	*(chbase) = (CHBASE & 0xff00) >> 8;
#endif

	reg = strlen(fake);
	for (;;)
	{
		clrscr();
		printf("\n");
		//      ---------0---------0---------0---------0
		printf("**  RETROBIT LAB VINTAGE ADVENTURES  **\n\n");
		printf("READY.\n");

		// Fake typing... ;-)
		ptr = fake;
		for (i = 0; i < reg; ++i)
		{
			if (*(ptr) == '\0')
				break;
			putchar(*(ptr));
			++ptr;
			crazy_color();
			//delay(3);
		}
		printf("READY.\n%c\n\n", 128 + ' ');
		delay(50);
		for (;;)
		{
			c = peek(764);
			if (c != 255)
			{
				do_scroll(1);
				break;
			}
			do_scroll(0);
			//crazy_color();
			delay(12);
		}
		poke(764,255);
	}
	// NEVERREACHED
	c = cgetc();
	return(0);
}
