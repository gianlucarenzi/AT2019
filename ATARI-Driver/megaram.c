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
	unsigned char * addr;

	clrscr();
	printf("Mega2/4 RAM Enabler\n");
	/* 0xc000 - 0xcfff copy
	 * 0xd800 - 0xffff copy
	 */
	memcpy(osram, osrom, 0x1000); /* 0xc000 - 0xcfff */
	osrom = (unsigned char *) 0xD800;
	memcpy(osram + 0x1000, osrom, 0x2800); /* 0xd800 - 0xffff */

	PHP();	// save processor status
	SEI();	// disable IRQs
	reg = peek(nmien);
	poke(nmien, 0);	// disable NMIs

	m_portb = peek(portb);
	m_portb = m_portb & 0xFE;	// turn off ROMs
	poke(portb, m_portb);			//leaving BASIC unchanged!

	// Now move OS ROM back to its (shadow RAM) location
	osram = (unsigned char *) 0x4000;
	osrom = (unsigned char *) 0xC000;

	memcpy(osrom, osram, 0x1000);
	osrom = (unsigned char *) 0xD800;
	memcpy(osrom, osram + 0x1000, 0x2800);

	poke(nmien, reg); // re-enalbe NMIs
	PLP(); // restore processor status

	/* Change the 'A' and the background color to a darker one... */
	osrom = (unsigned char *) (0xE000 + ('A' - 32) * 8);
	for (reg = 0; reg < ArraySize(tab); reg++)
		*(osrom + reg) = tab[reg];

	addr = (unsigned char *) 710;
	poke(addr, peek(addr) - 1);

	printf("$D531 = RAM ENABLE\n");
	addr = (unsigned char *) 0xD531;
	poke( addr, 1);

	addr = (unsigned char *) 0xD530;
	for (reg = 0; reg < (1 << 5); reg++)
	{
		clrscr();
		printf("$D530 = BANK RAM %02d\n", reg);
		c = cgetc();
	}

	printf("Done! Press any key to exit...\n");
	c = cgetc();

	return(0);
}
