//
// SERIAL POKEY DEVICE HANDLER DRIVER
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

#define POKEY_BASE_ADDRESS 0xD200
#define AUDCTL   (POKEY_BASE_ADDRESS + 0x08)
#define AUDF3    (POKEY_BASE_ADDRESS + 0x04)
#define AUDC3    (POKEY_BASE_ADDRESS + 0x05)
#define AUDF4    (POKEY_BASE_ADDRESS + 0x06)
#define AUDC4    (POKEY_BASE_ADDRESS + 0x07)
#define SEROUT   (POKEY_BASE_ADDRESS + 0x0D)
#define SERIN    (POKEY_BASE_ADDRESS + 0x0D)
#define SKCTL    (POKEY_BASE_ADDRESS + 0x0F)
#define IRQEN    (POKEY_BASE_ADDRESS + 0x0E)

#define SEROUT_RDY  (1 << 4)
#define SERIN_RDY   (1 << 5)

#define SKSEND      0x23
#define SKRECV      0x13 

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

static void setBaudRate(void)
{
	// Pokey Initialization for ~ 57600 bps

	*(unsigned char*)(AUDCTL) = 0x28; // Clock Channel3 at 1.7897725 Mhz NTSC or 1.7734470 Mhz PAL
	*(unsigned char*)(AUDC3)  = 0xA0; // No poly counter (pure tone)
	*(unsigned char*)(AUDC4)  = 0xA0; // No poly counter (pure tone)
	*(unsigned char*)(AUDF3)  = 0x08; // This should be approx. 57k6 baudrate (more or less)
	*(unsigned char*)(AUDF4)  = 0x00; // ----------------------

	// Disable serial interrupts IRQs for TX and RX.
	// They will be managed in polling mode
	*(unsigned char*)(IRQEN) &= ~(SEROUT_RDY | SERIN_RDY);
}


static void sendData(const char *str)
{
	printf("sendData() Sending: %s\n", str);
	*(unsigned char*)(SKCTL) = SKSEND; // Prepare POKEY to send data

   while (*str) {
		// Wait the transmitter to become ready (reset bit)
		while (*(unsigned char*)(IRQEN) & SEROUT_RDY)
			;
		// Byte to send
		*(unsigned char*)(SEROUT) = *str++;
	}
}


static void receiveData(char *buffer, int maxLength)
{
	int index = 0;
	char receivedChar;
	int timeout = 1000;
	
	printf("receiveData() Receiving...\n");
	*(unsigned char*)(SKCTL) = SKRECV; // Prepare POKEY to receive data

	while (index < maxLength - 1)
	{
		// Wait the receiver has data to be processed (set bit)
		while (!(*(unsigned char*)(IRQEN) & SERIN_RDY) && --timeout > 0)
			;

		if (timeout <= 0) {
			// Nothing on the receiver!!
			break;
		}

		// Byte received
		receivedChar = *(unsigned char*)(SERIN);
		// Wait a CR or LF to exit the loop (0x0A or 0x0D not ATASCII)
		if (receivedChar == '\r' || receivedChar == '\n')
			break;

		// Fill the buffer with the received byte
		buffer[index++] = receivedChar;
	}

	buffer[index] = '\0';
} 

//static void asm_delay(int l)
//{
//	int c;
//	for (c = 0; c < l; c++)
//		__asm__("nop");
//}

//static void delay(int l)
//{
//	int c;
//	for (c = 0; c < l; c++)
//		asm_delay(64);
//}

//static void setbank(int reg)
//{
//	unsigned char * portb = (unsigned char *) 0xD301;
//	ENTER_CRITICAL();
//	*(portb) = reg & OS_ROM_DISABLE_MASK; // Using RAM based OS (linker as -t atarixl)
//	EXIT_CRITICAL();
//	delay(1);
//}

int main(void)
{
	int reg;
	char buffer[128];
	int m_portb, dmareg;
	char c;
	unsigned char * wram  = (unsigned char *) WRAM; // RAM window (under SELFTEST ROM but within 0x4000-0x7FFF range
	unsigned char * portb = (unsigned char *) PORTB;
	unsigned char * sdmctl = (unsigned char *) SDMCTL;
	unsigned char * chargen;
	unsigned char * charbase;
	unsigned char * chbase = (unsigned char *) CHBASEOS;
	unsigned char * addr;
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

	EXIT_CRITICAL();
	// Turns on DMA
	*(sdmctl) = dmareg;

#ifndef __ATARIXL__
	*(chbase) = (CHRAMBASE & 0xff00) >> 8;
#else
	*(chbase) = (CHBASE & 0xff00) >> 8;
#endif

	clrscr();
	printf("\n");
	//      ---------0---------0---------0---------0
	printf("**  RETROBIT LAB VINTAGE ADVENTURES  **\n\n");
	printf("\nBitBanging POKEY on SIO @57600 Kbit/s\n");

	setBaudRate();

#ifdef __OSCILLOSCOPE_DEBUG__
	// When debugging and endless loop will be executed for sending
	for (;;)
#endif
	sendData("BITBANGING SIO\n");

	receiveData(buffer, sizeof(buffer));

	printf("RX: %s\n", buffer);
	// NEVERREACHED
	c = cgetc();
	return(0);
}
