/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
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
/* USER CODE END Header */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32f4xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define mA13_Pin GPIO_PIN_13
#define mA13_GPIO_Port GPIOC
#define mA14_Pin GPIO_PIN_14
#define mA14_GPIO_Port GPIOC
#define mA15_Pin GPIO_PIN_15
#define mA15_GPIO_Port GPIOC
#define mA0_Pin GPIO_PIN_0
#define mA0_GPIO_Port GPIOC
#define mA1_Pin GPIO_PIN_1
#define mA1_GPIO_Port GPIOC
#define mA2_Pin GPIO_PIN_2
#define mA2_GPIO_Port GPIOC
#define mA3_Pin GPIO_PIN_3
#define mA3_GPIO_Port GPIOC
#define TP1_Pin GPIO_PIN_0
#define TP1_GPIO_Port GPIOA
#define ACT_Pin GPIO_PIN_1
#define ACT_GPIO_Port GPIOA
#define UART_TX_TTL_Pin GPIO_PIN_2
#define UART_TX_TTL_GPIO_Port GPIOA
#define UART_RX_TTL_Pin GPIO_PIN_3
#define UART_RX_TTL_GPIO_Port GPIOA
#define PB0_Pin GPIO_PIN_4
#define PB0_GPIO_Port GPIOA
#define PB1_Pin GPIO_PIN_5
#define PB1_GPIO_Port GPIOA
#define PB2_Pin GPIO_PIN_6
#define PB2_GPIO_Port GPIOA
#define PB3_Pin GPIO_PIN_7
#define PB3_GPIO_Port GPIOA
#define mA4_Pin GPIO_PIN_4
#define mA4_GPIO_Port GPIOC
#define mA5_Pin GPIO_PIN_5
#define mA5_GPIO_Port GPIOC
#define mD0_Pin GPIO_PIN_0
#define mD0_GPIO_Port GPIOB
#define mD1_Pin GPIO_PIN_1
#define mD1_GPIO_Port GPIOB
#define mD2_Pin GPIO_PIN_2
#define mD2_GPIO_Port GPIOB
#define mHALT_Pin GPIO_PIN_10
#define mHALT_GPIO_Port GPIOB
#define mMPD_Pin GPIO_PIN_12
#define mMPD_GPIO_Port GPIOB
#define mIRQ_Pin GPIO_PIN_13
#define mIRQ_GPIO_Port GPIOB
#define mREF_Pin GPIO_PIN_14
#define mREF_GPIO_Port GPIOB
#define mRST_Pin GPIO_PIN_15
#define mRST_GPIO_Port GPIOB
#define mA6_Pin GPIO_PIN_6
#define mA6_GPIO_Port GPIOC
#define mA7_Pin GPIO_PIN_7
#define mA7_GPIO_Port GPIOC
#define mA8_Pin GPIO_PIN_8
#define mA8_GPIO_Port GPIOC
#define mA9_Pin GPIO_PIN_9
#define mA9_GPIO_Port GPIOC
#define PB4_Pin GPIO_PIN_8
#define PB4_GPIO_Port GPIOA
#define PB5_Pin GPIO_PIN_9
#define PB5_GPIO_Port GPIOA
#define PB6_Pin GPIO_PIN_10
#define PB6_GPIO_Port GPIOA
#define PB7_Pin GPIO_PIN_11
#define PB7_GPIO_Port GPIOA
#define mCCTL_Pin GPIO_PIN_12
#define mCCTL_GPIO_Port GPIOA
#define SWDIO_Pin GPIO_PIN_13
#define SWDIO_GPIO_Port GPIOA
#define SWCLK_Pin GPIO_PIN_14
#define SWCLK_GPIO_Port GPIOA
#define mRW_Pin GPIO_PIN_15
#define mRW_GPIO_Port GPIOA
#define mA10_Pin GPIO_PIN_10
#define mA10_GPIO_Port GPIOC
#define mA11_Pin GPIO_PIN_11
#define mA11_GPIO_Port GPIOC
#define mA12_Pin GPIO_PIN_12
#define mA12_GPIO_Port GPIOC
#define PHI2_Pin GPIO_PIN_2
#define PHI2_GPIO_Port GPIOD
#define mD3_Pin GPIO_PIN_3
#define mD3_GPIO_Port GPIOB
#define mD4_Pin GPIO_PIN_4
#define mD4_GPIO_Port GPIOB
#define mD5_Pin GPIO_PIN_5
#define mD5_GPIO_Port GPIOB
#define mD6_Pin GPIO_PIN_6
#define mD6_GPIO_Port GPIOB
#define mD7_Pin GPIO_PIN_7
#define mD7_GPIO_Port GPIOB
#define mEXSEL_Pin GPIO_PIN_8
#define mEXSEL_GPIO_Port GPIOB
#define mD1XX_Pin GPIO_PIN_9
#define mD1XX_GPIO_Port GPIOB
/* USER CODE BEGIN Private defines */

/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
