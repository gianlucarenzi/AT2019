/*
 * C64 Decrunching simulator. It's a FAKE!!! ;-)
 * OS ROM RAM Enabler
*/

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
//#define POKE(addr,val)     (*(unsigned char*) (addr) = (val))
//#define PEEK(addr)         (*(unsigned char*) (addr))
#define peek(a)		PEEK(a)
#define poke(a,b)	POKE(a,b)

#define KB(a)	((a)*1024L)
#define MB(a)	(KB(a)*1024L)
#ifndef MEMSIZEK
	#error "MEMSIZEK must be defined"
#else
	#define MEMORY_SIZE KB(MEMSIZEK)
#endif

#define ENTER_CRITICAL() \
	PHP(); \
	SEI(); \
	nmien_reg = peek(nmien); \
	poke(nmien, 0);

#define EXIT_CRITICAL() \
	poke(nmien, nmien_reg); \
	PLP();

static int mode_576k[32] = {
	0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E,
	0x20, 0x22, 0x24, 0x26, 0x28, 0x2A, 0x2C, 0x2E,
	0x40, 0x42, 0x44, 0x46, 0x48, 0x4A, 0x4C, 0x4E,
	0x60, 0x62, 0x64, 0x66, 0x68, 0x6A, 0x6C, 0x6E,
}; 

static int mode_130xe[8] = {
	0x00, 0x04, 0x08, 0x0C, 0x40, 0x44, 0x48, 0x4C,
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

#define CRAZY_COLOR		poke((unsigned char *) 0xD01A, rand());

int main(void)
{
	int reg;
	int m_portb;
	char c;
	unsigned char * wram = (unsigned char *) 0x7FFF; // 0x4000-0x7FFF
	unsigned char * osram = (unsigned char *) 0x3000;
	unsigned char * osrom;
	unsigned char * portb = (unsigned char *) 0xD301;
	unsigned char * addr =  NULL;
	int count;
	int i;
	int bad_main = 0;
	int bad_expansion = 0;

	m_portb = peek(559);
	poke(559, 0);
	srand(0xdeadbeef);
	clrscr();
#ifndef __ATARIXL__
#error "Use target as atarixl"
#endif

	/* Commodore 64 Chargen ROM */
	
	// chars from 32 to 63 '@ABC...[\]^_
	osrom = (unsigned char *) (0xE000 + ('@' - 32) * 8);
	count = 32;
	for (reg = 0; reg < (count * 8); reg++)
		*(osrom + reg) = c64_font[reg];

	// chars from 0 to 31 ' !"#...
	osrom = (unsigned char *) 0xE000;
	for (reg = 0; reg < (count * 8); reg++)
		*(osrom + reg) = c64_font[reg + (32 * 8)];

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
	printf("READY.\n%c\n\n", 128 + ' ');
	poke(559, m_portb);
	delay(150);

#ifdef M192K
	count = 0;
	/* 130XE mode: 192K RAM Pia Port B bank selection bit 2,3,6 */
	printf("Checking 130XE Mode: ");
	for (i = 0; i < 8; i++)
	{
		poke(portb, 0x72); // https://www.atarimagazines.com/v4n7/memorymanagement.html
		/*
		 * 7 6 5 4 3 2 1 0 
		 * 0 1 1 1 0 0 1 0 == 0x72
		 * 
		 * CPU & ANTIC accessing Main Memory space (NO EXPANSION WINDOW)
		 */
		poke(wram, 0xAA); // Watermark @ main bank 0x4000
		CRAZY_COLOR;
		
		/* Now accessing @ bank # (CPU & ANTIC) */
		poke(portb, 128 + mode_130xe[i] + 2);
		poke(wram, bank_val[i]);    // Write i @ bank # @ 0x4000
		CRAZY_COLOR;

		// read back the value
		reg = peek(wram);
		// Test if it is correctly written/read
		if (reg != bank_val[ i ])
		{
			//printf("ERROR Bank #%d - R $%02x - E $%02x\n",
				//i, reg, bank_val[ i ]);
			bad_expansion++;
		}
		else
		{
			// Now we can read data from original bank
			poke(portb, 0x72);
			reg = peek(wram);
			CRAZY_COLOR;
			// Test if it is the correct value 0xAA
			if (reg != 0xAA)
			{
				//printf("ERROR Main - R $%02x - E $AA\n", reg);
				bad_main++;
			}
			else
			{
				// If it is correct, assume the bank is good!
				count++;
			}
		}
	}
	// 130xe mode = 128k + 64k
	printf("%dK GOOD.\n", count * 16 + 64);
	if (bad_main > 0)
		printf("FAILED MAIN: %d\n", bad_main); 
	if (bad_expansion > 0)
		printf("FAILED BANK: %d\n", bad_expansion); 
#else
	count = 0;
	/* 576K mode: 576K RAM Pia Port B bank selection bit 1,2,3,5,6 */
	printf("Checking  576K Mode: ");
	for (i = 0; i < 32; i++)
	{
		poke(portb, 0x72); // https://www.atarimagazines.com/v4n7/memorymanagement.html
		/*
		 * 7 6 5 4 3 2 1 0 
		 * 0 1 1 1 0 0 1 0 == 0x72
		 * 
		 * CPU & ANTIC accessing Main Memory space (NO EXPANSION WINDOW)
		 */
		poke(wram, 0x55); // Watermark @ main bank 0x4000
		CRAZY_COLOR;
		
		/* Now accessing @ bank # (CPU & ANTIC) */
		poke(portb, 128 + mode_576k[ i ]);
		poke(wram, bank_val[i]);    // Write i @ bank # @ 0x4000
		CRAZY_COLOR;

		// read back the value
		reg = peek(wram);
		// Test if it is correctly written/read
		if (reg != bank_val[ i ])
		{
			//printf("ERROR Bank #%d - R $%02x - E $%02x\n",
			//	i, reg, bank_val[ i ]);
			bad_expansion++;
		}
		else
		{
			// Now we can read data from original bank
			poke(portb, 0x72);
			reg = peek(wram);
			CRAZY_COLOR;
			// Test if it is the correct value 0x55
			if (reg != 0x55)
			{
				//printf("ERROR Main - R $%02x - E $55\n", reg);
				bad_main++;
			}
			else
			{
				// If it is correct, assume the bank is good!
				count++;
			}
		}
	}
	// 576k mode = 512k + 64k
	printf("%dK GOOD.\n", count * 16 + 64);
	if (bad_main > 0)
		printf("FAILED MAIN: %d\n", bad_main); 
	if (bad_expansion > 0)
		printf("FAILED BANK: %d\n", bad_expansion); 
#endif

	for (;;) {
		if (peek(0xD01F) == 6)
			break;
		CRAZY_COLOR;
	}
//	c = cgetc();
	return(0);
}
