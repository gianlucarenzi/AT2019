/*
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
#include "version.h"

#define PLP()	__asm__("plp")
#define PHP()	__asm__("php")
#define ArraySize(a)	(sizeof(a)/sizeof(a[0]))

static unsigned char peek(unsigned char * addr)
{
	return *(addr);
}

static void poke(unsigned char *addr, unsigned char val)
{
	*(addr) = val;
}

#define KB(a)	((a)*1024L)
#define MB(a)	(KB(a)*1024L)
#ifndef MEMSIZEK
	#error "MEMSIZEK must be defined"
#else
	#define MEMORY_SIZE KB(MEMSIZEK)
#endif

static unsigned char memory_banks[MEMSIZEK];

int main(void)
{
	int reg;
	int m_portb;
	char c;
	int tab[] = { 0x00, 0x018, 0x3C, 0x66, 0x7E, 0x66, 0x66, 0x00 };
	unsigned char * osram = (unsigned char *) 0x4000;
	unsigned char * osrom = (unsigned char *) 0xC000;
	unsigned char * nmien = (unsigned char *) 0xD40E;
	unsigned char * portb = (unsigned char *) 0xD301;
	unsigned char * addr =  NULL;
	unsigned char * bankctl = (unsigned char *) 0xD531;
	unsigned char * banksel = (unsigned char *) 0xD530;

	int numbanks = MEMSIZEK / 16;
	int numbanks_good = 0;

	clrscr();
	printf("Mega2/4 RAM Expansion Hardware\n");
	printf("-- Max Numbanks: %d\n", numbanks);
	/* 0xc000 - 0xcfff copy
	 * 0xd800 - 0xffff copy
	 */
	memcpy(osram, osrom, 0x1000); /* 0xc000 - 0xcfff */
	osrom = (unsigned char *) 0xD800;
	memcpy(osram + 0x1000, osrom, 0x2800); /* 0xd800 - 0xffff */

	PHP();             /* save processor status */
	SEI();             /* disable IRQs */
	reg = peek(nmien);
	poke(nmien, 0);    /* disable NMIs */

	m_portb = peek(portb);
	m_portb = m_portb & 0xFE;  /* turn off ROMs */
	poke(portb, m_portb);      /* leaving BASIC unchanged! */

	/* Now move OS ROM back to its (shadow RAM) location */
	osram = (unsigned char *) 0x4000;
	osrom = (unsigned char *) 0xC000;

	memcpy(osrom, osram, 0x1000);
	osrom = (unsigned char *) 0xD800;
	memcpy(osrom, osram + 0x1000, 0x2800);

	poke(nmien, reg); /* re-enalbe NMIs */
	PLP();            /* restore processor status */

	printf("0x4000: 0x%02x\n", peek(osram));

	/* Change the 'A' and the background color to a darker one... */
	osrom = (unsigned char *) (0xE000 + ('A' - 32) * 8);
	for (reg = 0; reg < ArraySize(tab); reg++)
		*(osrom + reg) = tab[reg];
	/* Setcolor */
	addr = (unsigned char *) 710;
	poke(addr, peek(addr) - 1);

	/* Enable expansion. If you enable bankswitching the on-board 16K
	 * from 0x4000 - 0x7fff will be never used anymore */
	poke (bankctl, 1);
	printf("RAM EXPANSION Checking...\n");

	srand(0xfeedf00d);
	for (reg = 0; reg < numbanks; reg++)
	{
		unsigned char r;
		r = (unsigned char) rand() & 0xff;
		/* Select BANK */
		poke (banksel, reg);
		/* Write a byte at the same address of each bank */
		memory_banks[reg] = r;
		/* printf("WBANK    : %d - WR: 0x%02x\n", reg, r); */
		poke (osram, memory_banks[reg]);
	}

	/* Now read all data back */
	for (reg = 0; reg < numbanks; reg++)
	{
		unsigned char rdb, rd;
		/* Select BANK */
		poke (banksel, reg);
		rdb = peek(osram);
		/* printf("RBANK    : %d - RD: 0x%02x\n", reg, rdb); */
		if (rdb != memory_banks[reg])
		{
			printf("MEMORY ERROR! NEED: 0x%02x\n", memory_banks[reg]);
			break;
		}
		numbanks_good++;
	}

	printf("%dK GOOD\n", numbanks_good * 16);
	printf("Done! Press any key to exit...\n");
	c = cgetc();

	return(0);
}
