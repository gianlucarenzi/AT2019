/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2019 STMicroelectronics.
  * All rights reserved.</center></h2>
  *
  * This software component is licensed by ST under BSD 3-Clause license,
  * the "License"; You may not use this file except in compliance with the
  * License. You may obtain a copy of the License at:
  *                        opensource.org/licenses/BSD-3-Clause
  *
  ******************************************************************************
  */
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include "stm32f4xx_ll_gpio.h"
#include "main.h"

#define CONTROL_IN  GPIOC->IDR
#define ADDR_IN     GPIOD->IDR
#define DATA_IN     GPIOE->IDR
#define DATA_OUT    GPIOE->ODR

/* PORTA SIGNALS */
#define UART_TX_TTL     (1 << 9)
#define UART_RX_TTL     (1 << 10)

/* PORTB SIGNALS */
#define HALT        (1 << 7)
#define RST         (1 << 8)

/* PORTC SIGNALS */
#define PHI2    (1 << 0)
#define S5      (1 << 1)
#define S4      (1 << 2)
#define TP1     (1 << 3)
#define CCTL    (1 << 4)
#define RW      (1 << 5)

#define PHI2_RD        (GPIOC->IDR & 0x0001)
#define S5_RD          (GPIOC->IDR & 0x0002)
#define S4_RD          (GPIOC->IDR & 0x0004)
#define S4_AND_S5_HIGH ((GPIOC->IDR & 0x0006) == 0x6)

#define SET_DATA_MODE_IN  GPIOE->MODER = 0x00000000;
#define SET_DATA_MODE_OUT GPIOE->MODER = 0x55550000;

static UART_HandleTypeDef huart1;
static void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART1_UART_Init(void);
//static GPIO_InitTypeDef  GPIO_InitStructure;

/**
  * @brief  The application entry point.
  * @retval int
  */
static uint16_t ramPtr[256] = {0};

/*
 * In this example, CPU can read data accessing the $D800-D8FF area
 */
static void readdata(uint16_t addr)
{
	if (addr >= 0xD800 && addr <= 0xD8FF)
	{
		// read
		SET_DATA_MODE_OUT
		DATA_OUT = ((uint16_t) ramPtr[addr&0xFF])<<8;
	}
}

static void writedata(uint16_t addr)
{
	uint16_t data;
	if (addr >= 0xD800 && addr <= 0xD8FF)
	{
		data = DATA_IN;
		while (CONTROL_IN & PHI2)
			data = DATA_IN;
		ramPtr[addr&0xff] = data;
	}
}
//#define ArraySize(a)    (sizeof(a)/sizeof(a[0]))

int main(void)
{
	/* MCU Configuration--------------------------------------------------------*/
	uint16_t addr;  // ADDRESS LINES
//	uint16_t data;  // DATA LINES
	uint16_t c;     // CONTROL LINES

	/* Reset of all peripherals, Initializes the Flash interface and the Systick. */
	HAL_Init();

	/* Configure the system clock */
	SystemClock_Config();

	/* Reset external memory expansion */
//	memset(ramPtr, 0, ArraySize(ramPtr));

	/* Initialize all configured peripherals */
	MX_GPIO_Init();
	MX_USART1_UART_Init();

	while (1)
	{
		// wait for phi2 high
		while (!((c = CONTROL_IN) & PHI2)) ;

		addr = ADDR_IN;
		if (!(c & RW))
		{
			// CPU WANTS TO WRITE DATA
			writedata(addr);
		}
		else
		{
			// CPU WANTS TO READ DATA
			readdata(addr);
		}

		// wait for phi2 low
		while (CONTROL_IN & PHI2) ;

		SET_DATA_MODE_IN
	}
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
	RCC_OscInitTypeDef RCC_OscInitStruct = {0};
	RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

	/** Configure the main internal regulator output voltage 
	*/
	__HAL_RCC_PWR_CLK_ENABLE();
	__HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);
	/** Initializes the CPU, AHB and APB busses clocks 
	*/
	RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
	RCC_OscInitStruct.HSEState = RCC_HSE_ON;
	RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
	RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
	RCC_OscInitStruct.PLL.PLLM = 4;
	RCC_OscInitStruct.PLL.PLLN = 168;
	RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
	RCC_OscInitStruct.PLL.PLLQ = 4;

	if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
	{
		Error_Handler();
	}
	/** Initializes the CPU, AHB and APB busses clocks 
	*/
	RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
							  |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
	RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
	RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
	RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
	RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;

	if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_5) != HAL_OK)
	{
		Error_Handler();
	}
	/** Enables the Clock Security System 
	*/
	HAL_RCC_EnableCSS();
}

/**
  * @brief USART1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART1_UART_Init(void)
{
	huart1.Instance = USART1;
	huart1.Init.BaudRate = 115200;
	huart1.Init.WordLength = UART_WORDLENGTH_8B;
	huart1.Init.StopBits = UART_STOPBITS_1;
	huart1.Init.Parity = UART_PARITY_NONE;
	huart1.Init.Mode = UART_MODE_TX_RX;
	huart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
	huart1.Init.OverSampling = UART_OVERSAMPLING_16;
	if (HAL_UART_Init(&huart1) != HAL_OK)
	{
		Error_Handler();
	}
}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
	GPIO_InitTypeDef GPIO_InitStruct = {0};

	/* GPIO Ports Clock Enable */
	__HAL_RCC_GPIOC_CLK_ENABLE();
	__HAL_RCC_GPIOH_CLK_ENABLE();
	__HAL_RCC_GPIOB_CLK_ENABLE();
	__HAL_RCC_GPIOE_CLK_ENABLE();
	__HAL_RCC_GPIOD_CLK_ENABLE();
	__HAL_RCC_GPIOA_CLK_ENABLE();

	/*Configure GPIO pin Output Level */
	/* For BANK Selection
	 * B0, B1, B2, B3, B4, B5, B6, B7
	 * Actually only 5 bit are used to have 1024K expansion memory
	 */
	HAL_GPIO_WritePin(GPIOC,
		mB4_Pin | mB5_Pin | mB6_Pin | mB7_Pin |
		mB0_Pin | mB1_Pin | mB2_Pin | mB3_Pin |  
		mS5_Pin | mS5C2_Pin, GPIO_PIN_RESET);

	/*Configure GPIO pin Output Level */
	HAL_GPIO_WritePin(GPIOB,
		LEDGREEN_Pin | TP1_Pin  | mPBISEL_Pin   | mHALT_Pin |
		mIRQ_Pin     | mRST_Pin | mD8XX_DFXX_Pin| mEXSEL_Pin, GPIO_PIN_RESET);

	/*Configure GPIO pins :
	 * mB0_Pin mB1_Pin mB2_Pin mB3_Pin
	 * mB4_Pin mB5_Pin mB6_Pin mB7_Pin */
	GPIO_InitStruct.Pin =
		mB4_Pin | mB5_Pin | mB6_Pin | mB7_Pin |
		mB0_Pin | mB1_Pin | mB2_Pin | mB3_Pin;

	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
	HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

	/*Configure GPIO pins : mPHI2_Pin mCCTL_Pin mRW_Pin */
	GPIO_InitStruct.Pin = mPHI2_Pin | mCCTL_Pin | mRW_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

	/*Configure GPIO pins : mS5_Pin mS5C2_Pin mB0_Pin mB1_Pin 
						   mB2_Pin mB3_Pin mB4_Pin */
	GPIO_InitStruct.Pin = mS5_Pin | mS5C2_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

	/*Configure GPIO pins : LEDGREEN_Pin TP1_Pin */
	GPIO_InitStruct.Pin = LEDGREEN_Pin | TP1_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
	HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

	/*Configure GPIO pins : mPBISEL_Pin mHALT_Pin mIRQ_Pin mRST_Pin 
						   mD8XX_DFXX_Pin mEXSEL_Pin */
	GPIO_InitStruct.Pin =
		mPBISEL_Pin    | mHALT_Pin  |
		mIRQ_Pin       | mRST_Pin |
		mD8XX_DFXX_Pin | mEXSEL_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

	/*Configure GPIO pins : mD0_Pin mD1_Pin mD2_Pin mD3_Pin 
						   mD4_Pin mD5_Pin mD6_Pin mD7_Pin */
	GPIO_InitStruct.Pin =
		mD0_Pin  | mD1_Pin  | mD2_Pin  | mD3_Pin |
		mD4_Pin  | mD5_Pin  | mD6_Pin  | mD7_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(GPIOE, &GPIO_InitStruct);

	/*Configure GPIO pins : mMPD_Pin mREF_Pin mD1XX_Pin */
	GPIO_InitStruct.Pin =
		mMPD_Pin | mREF_Pin | mD1XX_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

	/*Configure GPIO pins :
	  Address BUS 16 bit wide
		mA0_Pin  mA1_Pin  mA2_Pin  mA3_Pin 
		mA4_Pin  mA5_Pin  mA6_Pin  mA7_Pin
		mA8_Pin  mA9_Pin  mA10_Pin mA11_Pin 
		mA12_Pin mA13_Pin mA14_Pin mA15_Pin 
	*/
	GPIO_InitStruct.Pin =
		mA0_Pin  | mA1_Pin  | mA2_Pin  | mA3_Pin  | 
		mA4_Pin  | mA5_Pin  | mA6_Pin  | mA7_Pin  |
		mA8_Pin  | mA9_Pin  | mA10_Pin | mA11_Pin |
		mA12_Pin | mA13_Pin | mA14_Pin | mA15_Pin; 
	GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(GPIOD, &GPIO_InitStruct);

}

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{ 
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     tex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
