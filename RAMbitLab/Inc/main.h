/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
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
#define mB5_Pin GPIO_PIN_13
#define mB5_GPIO_Port GPIOC
#define mB6_Pin GPIO_PIN_14
#define mB6_GPIO_Port GPIOC
#define mB7_Pin GPIO_PIN_15
#define mB7_GPIO_Port GPIOC
#define OSCIN_Pin GPIO_PIN_0
#define OSCIN_GPIO_Port GPIOH
#define OSCOUT_Pin GPIO_PIN_1
#define OSCOUT_GPIO_Port GPIOH
#define mPHI2_Pin GPIO_PIN_0
#define mPHI2_GPIO_Port GPIOC
#define mS5_Pin GPIO_PIN_1
#define mS5_GPIO_Port GPIOC
#define mS5C2_Pin GPIO_PIN_2
#define mS5C2_GPIO_Port GPIOC
#define mCCTL_Pin GPIO_PIN_4
#define mCCTL_GPIO_Port GPIOC
#define mRW_Pin GPIO_PIN_5
#define mRW_GPIO_Port GPIOC
#define LEDGREEN_Pin GPIO_PIN_0
#define LEDGREEN_GPIO_Port GPIOB
#define TP1_Pin GPIO_PIN_1
#define TP1_GPIO_Port GPIOB
#define mPBISEL_Pin GPIO_PIN_2
#define mPBISEL_GPIO_Port GPIOB
#define mD0_Pin GPIO_PIN_8
#define mD0_GPIO_Port GPIOE
#define mD1_Pin GPIO_PIN_9
#define mD1_GPIO_Port GPIOE
#define mD2_Pin GPIO_PIN_10
#define mD2_GPIO_Port GPIOE
#define mD3_Pin GPIO_PIN_11
#define mD3_GPIO_Port GPIOE
#define mD4_Pin GPIO_PIN_12
#define mD4_GPIO_Port GPIOE
#define mD5_Pin GPIO_PIN_13
#define mD5_GPIO_Port GPIOE
#define mD6_Pin GPIO_PIN_14
#define mD6_GPIO_Port GPIOE
#define mD7_Pin GPIO_PIN_15
#define mD7_GPIO_Port GPIOE
#define mHALT_Pin GPIO_PIN_10
#define mHALT_GPIO_Port GPIOB
#define mMPD_Pin GPIO_PIN_11
#define mMPD_GPIO_Port GPIOB
#define mIRQ_Pin GPIO_PIN_12
#define mIRQ_GPIO_Port GPIOB
#define mRST_Pin GPIO_PIN_13
#define mRST_GPIO_Port GPIOB
#define mREF_Pin GPIO_PIN_14
#define mREF_GPIO_Port GPIOB
#define mD8XX_DFXX_Pin GPIO_PIN_15
#define mD8XX_DFXX_GPIO_Port GPIOB
#define mA8_Pin GPIO_PIN_8
#define mA8_GPIO_Port GPIOD
#define mA9_Pin GPIO_PIN_9
#define mA9_GPIO_Port GPIOD
#define mA10_Pin GPIO_PIN_10
#define mA10_GPIO_Port GPIOD
#define mA11_Pin GPIO_PIN_11
#define mA11_GPIO_Port GPIOD
#define mA12_Pin GPIO_PIN_12
#define mA12_GPIO_Port GPIOD
#define mA13_Pin GPIO_PIN_13
#define mA13_GPIO_Port GPIOD
#define mA14_Pin GPIO_PIN_14
#define mA14_GPIO_Port GPIOD
#define mA15_Pin GPIO_PIN_15
#define mA15_GPIO_Port GPIOD
#define mB0_Pin GPIO_PIN_8
#define mB0_GPIO_Port GPIOC
#define mB1_Pin GPIO_PIN_9
#define mB1_GPIO_Port GPIOC
#define UART_TX_Pin GPIO_PIN_9
#define UART_TX_GPIO_Port GPIOA
#define UART_RX_Pin GPIO_PIN_10
#define UART_RX_GPIO_Port GPIOA
#define SWDIO_Pin GPIO_PIN_13
#define SWDIO_GPIO_Port GPIOA
#define SWDCLK_Pin GPIO_PIN_14
#define SWDCLK_GPIO_Port GPIOA
#define mB2_Pin GPIO_PIN_10
#define mB2_GPIO_Port GPIOC
#define mB3_Pin GPIO_PIN_11
#define mB3_GPIO_Port GPIOC
#define mB4_Pin GPIO_PIN_12
#define mB4_GPIO_Port GPIOC
#define mA0_Pin GPIO_PIN_0
#define mA0_GPIO_Port GPIOD
#define mA1_Pin GPIO_PIN_1
#define mA1_GPIO_Port GPIOD
#define mA2_Pin GPIO_PIN_2
#define mA2_GPIO_Port GPIOD
#define mA3_Pin GPIO_PIN_3
#define mA3_GPIO_Port GPIOD
#define mA4_Pin GPIO_PIN_4
#define mA4_GPIO_Port GPIOD
#define mA5_Pin GPIO_PIN_5
#define mA5_GPIO_Port GPIOD
#define mA6_Pin GPIO_PIN_6
#define mA6_GPIO_Port GPIOD
#define mA7_Pin GPIO_PIN_7
#define mA7_GPIO_Port GPIOD
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
