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
#include "c64.h"

#define PLP()	__asm__("plp")
#define PHP()	__asm__("php")
#define ArraySize(a)	(sizeof(a)/sizeof(a[0]))
#define POKE(addr,val)     (*(unsigned char*) (addr) = (val))
#define PEEK(addr)         (*(unsigned char*) (addr))
#define peek(a)		PEEK(a)
#define poke(a,b)	POKE(a,b)

#define KB(a)	((a)*1024L)
#define MB(a)	(KB(a)*1024L)
#ifndef MEMSIZEK
	#error "MEMSIZEK must be defined"
#else
	#define MEMORY_SIZE KB(MEMSIZEK)
#endif

static int nmien_reg = 0;
static unsigned char * nmien = (unsigned char *) 0xD40E;
#define ENTER_CRITICAL() \
	PHP(); \
	SEI(); \
	nmien_reg = peek(nmien); \
	poke(nmien, 0);

#define EXIT_CRITICAL() \
	poke(nmien, nmien_reg); \
	PLP();

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

int main(void)
{
	int reg;
	int m_portb;
	char c;
	int tab[] = { 0x00, 0x018, 0x3C, 0x66, 0x7E, 0x66, 0x66, 0x00 };
	unsigned char * osram = (unsigned char *) 0x4000;
	unsigned char * osrom = (unsigned char *) 0xC000;
	unsigned char * portb = (unsigned char *) 0xD301;
	unsigned char * addr =  NULL;
	unsigned int l;
	unsigned char dat;
	int count;
	unsigned int cc;

	srand(0xdeadbeef);
	clrscr();
	/* 0xc000 - 0xcfff copy
	 * 0xd800 - 0xffff copy
	 */
	memcpy(osram, osrom, 0x1000); /* 0xc000 - 0xcfff */
	osrom = (unsigned char *) 0xD800;
	memcpy(osram + 0x1000, osrom, 0x2800); /* 0xd800 - 0xffff */

	ENTER_CRITICAL();

	m_portb = peek(portb);
	m_portb = m_portb & 0xFE;  /* turn off ROMs */
	poke(portb, m_portb);      /* leaving BASIC unchanged! */

	/* Now move OS ROM back to its (shadow RAM) location */
	osram = (unsigned char *) 0x4000;
	osrom = (unsigned char *) 0xC000;

	memcpy(osrom, osram, 0x1000);
	osrom = (unsigned char *) 0xD800;
	memcpy(osrom, osram + 0x1000, 0x2800);

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
	poke(712, 110);
	poke(710, 120);

	EXIT_CRITICAL();

	printf("\n    **** COMMODORE 64 BASIC V2 ****\n\n");
	printf(" 64K RAM SYSTEM  38911 BASIC BYTES FREE\n\n");
	printf("READY.\n");
	printf("LOAD\"$\",8\n");
	printf("\nSEARCHING FOR $\nLOADING\n");
	printf("\nREADY.\nRUN\n");
	delay(100);
	for (;;) poke((unsigned char *) 0xD01A, rand());
	c = cgetc();
	return(0);
}
