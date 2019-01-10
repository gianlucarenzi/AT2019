#include "atari.h"
#include "syscall.h"
#include "debug.h"

static int debuglevel = DBG_INFO;

/**
 * This function set the mRST & mHALT lines to low, awaiting the stm32
 * is fully configured and running.
 * The 6502 on the mainboard will be in set in this state until
 * this pin is held low.
 */
void atari_gpio_init(void)
{
	DBG_N("Enter mHALT & mRST low\r\n");
	HAL_GPIO_WritePin(GPIOB, mHALT_Pin | mRST_Pin, GPIO_PIN_RESET);
	DBG_N("Exit\r\n");
}

void atari_cpu_startup(void)
{
	DBG_N("Enter\r\n");
	/* De-assert HALT Pin first (other chip involved can run... */
	HAL_GPIO_WritePin(GPIOB, mHALT_Pin, GPIO_PIN_SET);
	mdelay(100); // wait 100msecs
	/* De-assert RST Pin for CPU */
	HAL_GPIO_WritePin(GPIOB, mRST_Pin, GPIO_PIN_SET);
	DBG_N("Exit\r\n");
}

uint8_t atari_get_databus(void)
{
	/* ATARI DATA BUS IS CONNECTED TO PortB PB0..PB7 */
	uint8_t data = (GPIOB->IDR & 0x000000ff);
	DBG_N("Exit with 0x%02X\r\n", data);
	return data;
}

uint16_t atari_get_addressbus(void)
{
	/* ATARI ADDRESS BUS IS CONNECTED TO Port PC0..PC15 */
	uint16_t addr = (GPIOC->IDR & 0x0000ffff);
	DBG_N("Exit with 0x%04X\r\n", addr);
	return addr;
}

uint8_t atari_get_addressbus_low(void)
{
	/* ATARI ADDRESS BUS LOW BYTE IS CONNECTED TO Port PC0..PC7 */
	uint8_t addr = (GPIOC->IDR & 0x000000ff);
	DBG_N("Exit with 0x%02X\r\n", addr);
	return addr;
}

void atari_set_expansion_memory(uint8_t exp)
{
	/* MEMORY EXPANSION DATA BUS ARE CONNECTED TO PA4..PA11 (A0..A7) */
	/* BIT 0 */
	HAL_GPIO_WritePin(GPIOA, PB0_Pin, exp & (1 << 0) ? GPIO_PIN_SET : GPIO_PIN_RESET);
	/* BIT 1 */
	HAL_GPIO_WritePin(GPIOA, PB1_Pin, exp & (1 << 1) ? GPIO_PIN_SET : GPIO_PIN_RESET);
	/* BIT 2 */
	HAL_GPIO_WritePin(GPIOA, PB2_Pin, exp & (1 << 2) ? GPIO_PIN_SET : GPIO_PIN_RESET);
	/* BIT 3 */
	HAL_GPIO_WritePin(GPIOA, PB3_Pin, exp & (1 << 3) ? GPIO_PIN_SET : GPIO_PIN_RESET);
	/* BIT 4 */
	HAL_GPIO_WritePin(GPIOA, PB4_Pin, exp & (1 << 4) ? GPIO_PIN_SET : GPIO_PIN_RESET);
	/* BIT 5 */
	HAL_GPIO_WritePin(GPIOA, PB5_Pin, exp & (1 << 5) ? GPIO_PIN_SET : GPIO_PIN_RESET);
	/* BIT 6 */
	HAL_GPIO_WritePin(GPIOA, PB6_Pin, exp & (1 << 6) ? GPIO_PIN_SET : GPIO_PIN_RESET);
	/* BIT 7 */
	HAL_GPIO_WritePin(GPIOA, PB7_Pin, exp & (1 << 7) ? GPIO_PIN_SET : GPIO_PIN_RESET);
	DBG_E("Exit\r\n");
}

int atari_get_phi2(void)
{
	/* ATARI PHI2 SIGNAL IS ON Port PD2 */
	uint8_t phi2 = (GPIOD->IDR & (1 << 2));
	DBG_N("Exit with: %s\r\n", phi2 == 0 ? "NOT ACTIVE" : "ACTIVE");
	return phi2;
}

int atari_has_write(void)
{
	/* ATARI R/nW os connected to Port A15 */
	uint8_t rw = (GPIOA->IDR & (1 << 15)); // high = read  low = write
	DBG_E("Exit with: %s\r\n", rw == 1 ? "READ" : "WRITE");
	return rw == 0;
}

int atari_has_cctl(void)
{
	/* ATARI nCCTL means access to D5xx - D7xx */
	uint8_t cctl = (GPIOA->IDR & (1 << 12)); // high = no D5xx low = D5xx access
	DBG_E("Exit with: %s D5XX Access\r\n", cctl == 1 ? "NO " : "YES");
	return cctl == 0;
}
