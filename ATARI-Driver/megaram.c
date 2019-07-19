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
#define POKE(addr,val)     (*(unsigned char*) (addr) = (val))
#define PEEK(addr)         (*(unsigned char*) (addr))
#define peek(a)		PEEK(a)
#define poke(a,b)	POKE(a,b)

//static unsigned char peek(unsigned char * addr)
//{
//	return *(addr);
//}

//static void poke(unsigned char *addr, unsigned char val)
//{
//	*(addr) = val;
//}

#define KB(a)	((a)*1024L)
#define MB(a)	(KB(a)*1024L)
#ifndef MEMSIZEK
	#error "MEMSIZEK must be defined"
#else
	#define MEMORY_SIZE KB(MEMSIZEK)
#endif

static void asm_delay(int l)
{
	int c;
	for (c = 0; c < l; c++)
		__asm__("nop");
}

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
	unsigned int l;
	unsigned char dat;
	int count;

	clrscr();
	printf("Atari XL/XE Hardware test\n");
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

	/* Change the 'A' and the background color to a darker one... */
	osrom = (unsigned char *) (0xE000 + ('A' - 32) * 8);
	for (reg = 0; reg < ArraySize(tab); reg++)
		*(osrom + reg) = tab[reg];
	poke(710, peek(710)-2);

	printf("Accessing RetroBit Video Hardware\n");

	osrom = (unsigned char *) 0xD500;
	m_portb = peek(559);
	poke(559,0);

	poke(0xd501, 0xff); // # of colors for background $D501
	for (l = 0; l <= 0xff; l++) {
		poke(0xd502, l); // $D501 autoincrement address for palette
		printf("%02X\n", peek(0xd503));
	}

#if 0
	poke(0xd501, 0xff); // # of colors for background $D501
	for (l = 0; l <= 0xff; l++)
		poke(0xd502, colormap[l]); // $D501 autoincrement address for palette

	poke(0xd503, 0xff); // colormap for sprite $D503
	for (l = 0; l <= 0xff; l++)
		poke(0xd504, spritecolormap[l]); // $D504 autoincrement address for palette

	poke(0xd504, 64);   // sprite is 64x64
	for (l = 0; l < 64; l++)
		poke(0xd505, spritedata[l]);

	int x = 100;
	int y = 100;
	poke(0xd506, x); // sprite position
	poke(0xd507, y);
#endif

	poke(559,m_portb);

	printf("Done! Press any key to exit...\n");
	c = cgetc();

	return(0);
}
