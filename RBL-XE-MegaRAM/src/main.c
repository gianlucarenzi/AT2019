
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  ** This notice applies to any and all portions of this file
  * that are not between comment pairs USER CODE BEGIN and
  * USER CODE END. Other portions of this file, whether 
  * inserted by the user or by software development tools
  * are owned by their respective copyright owners.
  *
  * COPYRIGHT(c) 2019 STMicroelectronics
  *
  * Redistribution and use in source and binary forms, with or without modification,
  * are permitted provided that the following conditions are met:
  *   1. Redistributions of source code must retain the above copyright notice,
  *      this list of conditions and the following disclaimer.
  *   2. Redistributions in binary form must reproduce the above copyright notice,
  *      this list of conditions and the following disclaimer in the documentation
  *      and/or other materials provided with the distribution.
  *   3. Neither the name of STMicroelectronics nor the names of its contributors
  *      may be used to endorse or promote products derived from this software
  *      without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  ******************************************************************************
  */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "main.h"
#include "stm32f4xx_hal.h"
#include "syscall.h"
#include "debug.h"
#include "stm32f4xx_it.h"
#include "atari.h"

/* Local functions prototypes */
static void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART2_UART_Init(int baud);

/* Local variables */
static int debuglevel = DBG_INFO;
static const char *fwBuild = "v1.0beta";
static UART_HandleTypeDef huart2;

static void banner(void)
{
	printf("\r\n\r\n" ANSI_BLUE "RETROBITLAB AMIGA USB KEYBOARD ADAPTER" ANSI_RESET "\r\n");
	printf(ANSI_BLUE "-=* STM32F401 BASED BOARD HANDLER  *=-" ANSI_RESET "\r\n");
	printf(ANSI_YELLOW);
	printf("FWVER: %s", fwBuild);
	printf(ANSI_RESET "\r\n");
	printf("\r\n\n");
}

static void led_light(int state)
{
	int ledval = GPIO_PIN_RESET;

	if (!!state)
	{
		ledval = GPIO_PIN_RESET; /* LED ON */
	}
	else
	{
		ledval = GPIO_PIN_SET; /* LED OFF */
	}
	HAL_GPIO_WritePin(ACT_GPIO_Port, ACT_Pin, ledval);
}

static void led_toggle(void)
{
	static int ledval = 0;
	if (ledval == 0)
	{
		ledval = 1;
	}
	else
	{
		ledval = 0;
	}
	led_light(ledval);
}

#define BANKCTL 0xD311
#define BANKSEL 0xD301
#define BANKCTL_RAMEN      (1 << 0) /* BIT 0 */
#define BANKCTL_ROMEN      (1 << 1) /* BIT 1 */
#define BANKCTL_ROMSEL     (1 << 2) /* BIT 2..5 ROM SELECTOR */
#define BANKCTL_NC00       (1 << 6) /* BIT 6 */
#define BANKCTL_NC01       (1 << 7) /* BIT 7 */

/*
 *  -------------------------------------
 *  NC01 NC00 SEL SEL SEL SEL ROMEN RAMEN
 * --------------------------------------
 *   X    X    X   X   X   X    X     0    -- EXTRA RAM DISABLE
 * 
 * TODO:
 * 
 *   X    X    X   X   X   X    X     1    -- EXTRA RAM ENABLE
 *   X    X    X   X   X   X    0     X    -- ROM DISABLE
 *   X    X    0   0   0   0    1     X    -- ROM ENABLE & SELECT ROM n.0
 *   X    X    0   0   0   1    1     X    -- ROM ENABLE & SELECT ROM n.1
 *   X    X    0   0   1   0    1     X    -- ROM ENABLE & SELECT ROM n.2
 *   X    X    0   0   1   1    1     X    -- ROM ENABLE & SELECT ROM n.3
 *   X    X    0   1   0   0    1     X    -- ROM ENABLE & SELECT ROM n.4
 *   X    X    0   1   0   1    1     X    -- ROM ENABLE & SELECT ROM n.5
 *   X    X    0   1   1   0    1     X    -- ROM ENABLE & SELECT ROM n.6
 *   X    X    0   1   1   1    1     X    -- ROM ENABLE & SELECT ROM n.7
 *   X    X    1   0   0   0    1     X    -- ROM ENABLE & SELECT ROM n.8
 *   X    X    1   0   0   1    1     X    -- ROM ENABLE & SELECT ROM n.9
 *   X    X    1   0   1   0    1     X    -- ROM ENABLE & SELECT ROM n.10
 *   X    X    1   0   1   1    1     X    -- ROM ENABLE & SELECT ROM n.11
 *   X    X    1   1   0   0    1     X    -- ROM ENABLE & SELECT ROM n.12
 *   X    X    1   1   0   1    1     X    -- ROM ENABLE & SELECT ROM n.13
 *   X    X    1   1   1   1    1     X    -- ROM ENABLE & SELECT ROM n.14
 *   X    X    1   1   1   1    1     X    -- ROM ENABLE & SELECT ROM n.15
 * 
 */
int main(void)
{
	bool enable_expansion;
	bool rom_enable;

	_write_ready(SYSCALL_NOTREADY, &huart2);

  /* MCU Configuration--------------------------------------------------------*/
  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
	HAL_Init();
	/* Configure the system clock */
	SystemClock_Config();

	/* Initialize all configured peripherals */
	MX_GPIO_Init();

	/* Initialize DEBUG UART */
	MX_USART2_UART_Init(115200);
	_write_ready(SYSCALL_READY, &huart2);

	/* Initialize GPIO for Atari and assert the mRST Line */
	atari_gpio_init();

	banner();

	timer_start();

	/* Now initialize Atari Pinouts and sync the CPU signals */
	atari_cpu_startup();

	/* There are two registers (Write Only)
	 * - Writing to BANKSEL trigger the expansion to be used
	 *   all 8-bit banked-memory (256 banks of 16K each mapped at
	 *   the same window (0x4000 - 0x7FFF)).
	 * 
	 * To disable/enable external memory the jumper can be used or
	 * write at the address BANKCTL at D0
	 * Other D1..D7 are currently unimplemented
	 */

	led_light(1); // Usually we start with memory expansion enabled...

	enable_expansion = true;
	rom_enable = false;

	DBG_I("Starting firmware: RAM ENABLE: %s - ROM ENABLE: %s...\r\n",
			enable_expansion == true ? "YES" : "NO",
			rom_enable == true ? "YES" : "NO");

	for (;;)
	{
		/* Act only when PHI2 is high */
		if (atari_get_phi2())
		{
			uint16_t address = atari_get_addressbus();
			uint8_t  data = atari_get_databus();
			DBG_N("PC: $%04X - DATA: $%02X\r\n", address, data);

			switch(address)
			{
				case BANKCTL:
					if (atari_has_write())
					{
						if (data & 0x01) /* Only D0 is used */
						{
							led_light(1); /* LED ON WHEN RAM EXPANSION WORKS */
							enable_expansion = true;
						}
						else
						{
							led_light(0);
							enable_expansion = false;
						}
					}
					break;

				case BANKSEL:
					if (atari_has_write())
					{
						if (enable_expansion == true)
							atari_set_expansion_memory(data);
					}
					break;

				default:
					break;
			}
		}

		/* If expansion ram is disabled, led will blink */
		if (enable_expansion == false)
		{
			if (timer_elapsed(500))
			{
				led_toggle();
				timer_start();
			}
		}
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

	/**Configure the main internal regulator output voltage
	*/
	__HAL_RCC_PWR_CLK_ENABLE();

	__HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE2);

	/**Initializes the CPU, AHB and APB busses clocks
	*/
	RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
	RCC_OscInitStruct.HSEState = RCC_HSE_ON;
	RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
	RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
	RCC_OscInitStruct.PLL.PLLM = 4;
	RCC_OscInitStruct.PLL.PLLN = 168;
	RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV4;
	RCC_OscInitStruct.PLL.PLLQ = 7;
	if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
	{
		_Error_Handler(__FILE__, __LINE__);
	}

	/**Initializes the CPU, AHB and APB busses clocks
	*/
	RCC_ClkInitStruct.ClockType =
		RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK |
		RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
	RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
	RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
	RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
	RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

	if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
	{
		_Error_Handler(__FILE__, __LINE__);
	}

	/**Configure the Systick interrupt time
	*/
	HAL_SYSTICK_Config(HAL_RCC_GetHCLKFreq()/1000);

	/**Configure the Systick
	*/
	HAL_SYSTICK_CLKSourceConfig(SYSTICK_CLKSOURCE_HCLK);

	/* SysTick_IRQn interrupt configuration */
	HAL_NVIC_SetPriority(SysTick_IRQn, 0, 0);
}

/* USART2 init function */
static void MX_USART2_UART_Init(int baud)
{
	huart2.Instance = USART2;
	huart2.Init.BaudRate = baud;
	huart2.Init.WordLength = UART_WORDLENGTH_8B;
	huart2.Init.StopBits = UART_STOPBITS_1;
	huart2.Init.Parity = UART_PARITY_NONE;
	huart2.Init.Mode = UART_MODE_TX_RX;
	huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
	huart2.Init.OverSampling = UART_OVERSAMPLING_16;
	if (HAL_UART_Init(&huart2) != HAL_OK)
	{
		_Error_Handler(__FILE__, __LINE__);
	}

}

/** Configure pins as
        * Analog
        * Input
        * Output
        * EVENT_OUT
        * EXTI
*/
static void MX_GPIO_Init(void)
{
	GPIO_InitTypeDef GPIO_InitStruct = {0};

	/* GPIO Ports Clock Enable */
	__HAL_RCC_GPIOC_CLK_ENABLE();
	__HAL_RCC_GPIOH_CLK_ENABLE();
	__HAL_RCC_GPIOA_CLK_ENABLE();
	__HAL_RCC_GPIOB_CLK_ENABLE();
	__HAL_RCC_GPIOD_CLK_ENABLE();

  /* Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOA, TP1_Pin |
	PB0_Pin| PB1_Pin| PB2_Pin |PB3_Pin |
	PB4_Pin| PB5_Pin| PB6_Pin |PB7_Pin
	, GPIO_PIN_RESET);

	/* Configure GPIO pin Output Level */
	HAL_GPIO_WritePin(ACT_GPIO_Port, ACT_Pin, GPIO_PIN_SET);

	/* Configure GPIO pin Output Level */
	HAL_GPIO_WritePin(GPIOB, mHALT_Pin | mRST_Pin, GPIO_PIN_RESET);

	/* Configure GPIO pins :
		mA0_Pin mA1_Pin mA2_Pin  mA3_Pin  mA4_Pin  mA5_Pin  mA6_Pin  mA7_Pin
		mA8_Pin mA9_Pin mA10_Pin mA11_Pin mA12_Pin mA13_Pin mA14_Pin mA15_Pin */
	GPIO_InitStruct.Pin = 
		mA0_Pin | mA1_Pin | mA2_Pin | mA3_Pin | mA4_Pin | mA5_Pin | mA6_Pin | mA7_Pin |
		mA8_Pin | mA9_Pin | mA10_Pin| mA11_Pin| mA12_Pin| mA13_Pin| mA14_Pin| mA15_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

  /* Configure GPIO pins :
	TP1_Pin ACT_Pin
	PB0_Pin PB1_Pin PB2_Pin PB3_Pin
    PB4_Pin PB5_Pin PB6_Pin PB7_Pin */
	GPIO_InitStruct.Pin =
		TP1_Pin | ACT_Pin |
		PB0_Pin | PB1_Pin | PB2_Pin | PB3_Pin |
		PB4_Pin | PB5_Pin | PB6_Pin | PB7_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

	/* Configure GPIO pins :
		mD0_Pin mD1_Pin mD2_Pin mD3_Pin mD4_Pin mD5_Pin mD6_Pin mD7_Pin
		mMPD_Pin
		mIRQ_Pin
		mREF_Pin
		mEXSEL_Pin
		mD1XX_Pin
	 */
	GPIO_InitStruct.Pin =
		mD0_Pin | mD1_Pin | mD2_Pin | mD3_Pin |
		mD4_Pin | mD5_Pin | mD6_Pin | mD7_Pin |
		mMPD_Pin |
		mIRQ_Pin |
		mREF_Pin |
		mEXSEL_Pin |
		mD1XX_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

	/*Configure GPIO pins : mHALT_Pin mRST_Pin */
	GPIO_InitStruct.Pin =
		mHALT_Pin | mRST_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

	/*Configure GPIO pins : mCCTL_Pin mRW_Pin */
	GPIO_InitStruct.Pin =
		mCCTL_Pin | mRW_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

	/*Configure GPIO pin : PHI2_Pin */
	GPIO_InitStruct.Pin = PHI2_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(PHI2_GPIO_Port, &GPIO_InitStruct);
}

/**
  * @brief  This function is executed in case of error occurrence.
  * @param  file: The file name as string.
  * @param  line: The line in file as a number.
  * @retval None
  */
void _Error_Handler(char *file, int line)
{
	/* USER CODE BEGIN Error_Handler_Debug */
	/* User can add his own implementation to report the HAL error return state */
	while (1)
	{
	}
	/* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t* file, uint32_t line)
{
	/* USER CODE BEGIN 6 */
	/* User can add his own implementation to report the file name and line number,
	 tex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
	/* USER CODE END 6 */
	DBG_E("Error! Wrong parameters value: file %s on line %d\r\n", file, line);
	while (1)
	{
	}
}
#endif /* USE_FULL_ASSERT */
