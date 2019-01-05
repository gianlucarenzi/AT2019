EESchema Schematic File Version 2
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:AmigaComponents
LIBS:atari23MTS_Upgrade-cache
EELAYER 25 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 3
Title "ATARI XE 2/4 MegaRAM Expansion"
Date "2018-12-31"
Rev ""
Comp "RetrobitLab"
Comment1 "CART+ECI Interface to mapping 512K x 8 x 4"
Comment2 "2048K + 64K RAM EXPANSION"
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L GND #PWR01
U 1 1 5C2A61A8
P 2350 2100
F 0 "#PWR01" H 2350 1850 50  0001 C CNN
F 1 "GND" H 2350 1950 50  0000 C CNN
F 2 "" H 2350 2100 50  0001 C CNN
F 3 "" H 2350 2100 50  0001 C CNN
	1    2350 2100
	1    0    0    -1  
$EndComp
$Comp
L CP1_Small C2
U 1 1 5C2A61C4
P 2800 1850
F 0 "C2" H 2810 1920 50  0000 L CNN
F 1 "22u" H 2810 1770 50  0000 L CNN
F 2 "Capacitors_SMD:c_elec_5x5.3" H 2800 1850 50  0001 C CNN
F 3 "" H 2800 1850 50  0000 C CNN
	1    2800 1850
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR02
U 1 1 5C2A6632
P 3250 2100
F 0 "#PWR02" H 3250 1850 50  0001 C CNN
F 1 "GND" H 3250 1950 50  0000 C CNN
F 2 "" H 3250 2100 50  0001 C CNN
F 3 "" H 3250 2100 50  0001 C CNN
	1    3250 2100
	1    0    0    -1  
$EndComp
$Comp
L VCC #PWR03
U 1 1 5C2A6795
P 1100 1400
F 0 "#PWR03" H 1100 1250 50  0001 C CNN
F 1 "VCC" H 1100 1550 50  0000 C CNN
F 2 "" H 1100 1400 50  0001 C CNN
F 3 "" H 1100 1400 50  0001 C CNN
	1    1100 1400
	1    0    0    -1  
$EndComp
Text Notes 3700 2350 0    60   ~ 12
POWER SECTION
Text Notes 1650 4600 0    60   ~ 12
DEBUG/PROGRAMMING SECTION
$Comp
L GND #PWR04
U 1 1 5C2AE0B0
P 9050 5450
F 0 "#PWR04" H 9050 5200 50  0001 C CNN
F 1 "GND" H 9050 5300 50  0000 C CNN
F 2 "" H 9050 5450 50  0001 C CNN
F 3 "" H 9050 5450 50  0001 C CNN
	1    9050 5450
	1    0    0    -1  
$EndComp
Wire Wire Line
	2750 1600 3400 1600
Wire Wire Line
	2800 1750 2800 1600
Connection ~ 2800 1600
Wire Wire Line
	3000 1750 3000 1600
Connection ~ 3000 1600
Wire Wire Line
	1900 1950 1900 2000
Wire Wire Line
	1900 2000 3000 2000
Wire Wire Line
	2800 2000 2800 1950
Wire Wire Line
	3000 2000 3000 1950
Connection ~ 2800 2000
Wire Wire Line
	1900 1350 1900 1750
Wire Wire Line
	1800 1600 1950 1600
Connection ~ 1900 1600
Wire Wire Line
	2350 1900 2350 2100
Connection ~ 2350 2000
Wire Wire Line
	3250 1700 3250 1600
Connection ~ 3250 1600
Wire Wire Line
	1000 1600 1300 1600
Wire Wire Line
	1100 1400 1100 1650
Connection ~ 1100 1600
Wire Wire Line
	3750 850  3750 950 
Wire Wire Line
	4000 850  4000 950 
Wire Wire Line
	4000 950  4050 950 
Wire Wire Line
	3900 1600 4000 1600
Wire Notes Line
	550  550  4500 550 
Wire Notes Line
	4500 550  4500 2450
Wire Notes Line
	4500 2450 550  2450
Wire Notes Line
	550  2450 550  550 
Wire Wire Line
	1550 3600 2500 3600
Wire Wire Line
	2500 3500 1950 3500
Wire Wire Line
	1400 4000 1500 4000
Wire Wire Line
	1400 4100 2150 4100
Wire Wire Line
	7100 2150 7200 2150
Wire Wire Line
	7100 2350 7200 2350
Wire Wire Line
	7100 2650 7200 2650
Wire Wire Line
	5700 3100 5550 3100
Wire Wire Line
	5550 3100 5550 3500
Wire Wire Line
	5550 3500 5700 3500
Wire Wire Line
	6500 3500 5900 3500
Wire Wire Line
	6200 3500 6200 3400
Wire Wire Line
	6200 3200 6200 3100
Wire Wire Line
	6500 3100 5900 3100
Wire Wire Line
	6500 3250 7200 3250
Wire Wire Line
	6500 3250 6500 3100
Connection ~ 6200 3100
Wire Wire Line
	6500 3350 7200 3350
Wire Wire Line
	6500 3350 6500 3500
Connection ~ 6200 3500
Wire Wire Line
	5550 3300 5400 3300
Connection ~ 5550 3300
Wire Wire Line
	9150 1700 9150 1800
Wire Wire Line
	8500 2250 9150 2250
Wire Wire Line
	9150 2250 9150 2200
Wire Wire Line
	8500 2150 8750 2150
Wire Wire Line
	7550 1400 7550 1800
Wire Wire Line
	7550 1800 7800 1800
Wire Wire Line
	7800 1800 7800 1950
Wire Wire Line
	7800 1400 7800 1700
Wire Wire Line
	7800 1700 7900 1700
Wire Wire Line
	7900 1700 7900 1950
Wire Wire Line
	8000 1700 8100 1700
Wire Wire Line
	8000 1700 8000 1950
Wire Wire Line
	8100 1800 8350 1800
Wire Wire Line
	8100 1800 8100 1950
Wire Wire Line
	8100 1700 8100 1400
Wire Wire Line
	8350 1800 8350 1400
Wire Wire Line
	8350 1200 8350 900 
Wire Wire Line
	8350 900  7350 900 
Wire Wire Line
	7550 1200 7550 900 
Connection ~ 7550 900 
Wire Wire Line
	7800 1200 7800 900 
Connection ~ 7800 900 
Wire Wire Line
	8100 1200 8100 900 
Connection ~ 8100 900 
Wire Wire Line
	7250 1550 8350 1550
Connection ~ 7550 1550
Connection ~ 7800 1550
Connection ~ 8100 1550
Connection ~ 8350 1550
Wire Notes Line
	650  3050 3150 3050
Wire Notes Line
	3150 3050 3150 4650
Wire Notes Line
	3150 4650 650  4650
Wire Notes Line
	650  4650 650  3050
Wire Wire Line
	8500 2350 10100 2350
Wire Wire Line
	8500 2450 10100 2450
Wire Wire Line
	9650 1950 9650 2050
Wire Wire Line
	9900 1950 9900 2050
Wire Wire Line
	9650 2250 9650 2350
Connection ~ 9650 2350
Wire Wire Line
	9900 2250 9900 2450
Connection ~ 9900 2450
Wire Wire Line
	8500 3850 8750 3850
Wire Wire Line
	8500 3950 8750 3950
Wire Wire Line
	8750 4050 8500 4050
Wire Wire Line
	8500 4150 8750 4150
Wire Wire Line
	8750 4250 8500 4250
Wire Wire Line
	8750 4350 8500 4350
Wire Wire Line
	8500 4450 8750 4450
Wire Wire Line
	8750 4550 8500 4550
Wire Wire Line
	8500 2550 8700 2550
Wire Wire Line
	8500 3150 8700 3150
Wire Wire Line
	7000 3750 7200 3750
Wire Wire Line
	7200 3850 7000 3850
Wire Wire Line
	7000 3950 7200 3950
Wire Wire Line
	7000 4050 7200 4050
Wire Wire Line
	7000 4150 7200 4150
Wire Wire Line
	7000 4250 7200 4250
Wire Wire Line
	7000 4350 7200 4350
Wire Wire Line
	7000 4450 7200 4450
Wire Wire Line
	7200 4550 7000 4550
Wire Wire Line
	7000 4650 7200 4650
Wire Wire Line
	7200 4750 7000 4750
Wire Wire Line
	7000 4850 7200 4850
Wire Wire Line
	7200 4950 7000 4950
Wire Wire Line
	7000 5050 7200 5050
Wire Wire Line
	7000 5150 7200 5150
Wire Wire Line
	7000 5250 7200 5250
Wire Wire Line
	8500 4650 9050 4650
Wire Wire Line
	8500 4750 9050 4750
Wire Wire Line
	8500 4850 9050 4850
Wire Wire Line
	8500 4950 9050 4950
Wire Wire Line
	8500 5050 9050 5050
Wire Wire Line
	8500 5150 9050 5150
Wire Wire Line
	8500 5250 9300 5250
Wire Wire Line
	7700 5450 7700 5600
Wire Wire Line
	7700 5600 8100 5600
Wire Wire Line
	8100 5600 8100 5450
Wire Wire Line
	8000 5450 8000 5600
Connection ~ 8000 5600
Wire Wire Line
	7900 5450 7900 5750
Connection ~ 7900 5600
Wire Wire Line
	7800 5450 7800 5600
Connection ~ 7800 5600
Wire Wire Line
	3000 5700 3250 5700
Wire Notes Line
	800  5100 6500 5100
Wire Notes Line
	6500 5100 6500 7350
Wire Notes Line
	6500 7350 700  7350
Wire Notes Line
	700  7350 700  5100
Wire Notes Line
	700  5100 850  5100
Text Notes 800  5250 0    60   ~ 12
ATARI CONNECTIONS
Wire Wire Line
	4400 3850 4400 3650
Wire Wire Line
	4200 3650 4300 3650
Text Notes 3700 3200 0    60   ~ 12
BOOTSEL
Wire Notes Line
	3600 3050 4900 3050
Wire Notes Line
	4900 3050 4900 4300
Wire Notes Line
	4900 4300 3600 4300
Wire Notes Line
	3600 4300 3600 3050
Text GLabel 5450 1700 0    60   Input ~ 0
nRESET
Wire Notes Line
	4700 550  4700 2450
Wire Notes Line
	4700 2450 6200 2450
Wire Notes Line
	6200 2450 6200 550 
Wire Notes Line
	6200 550  4700 550 
Text Notes 4750 700  0    60   ~ 12
RESET BUTTON
NoConn ~ 9000 5900
NoConn ~ 9250 5900
NoConn ~ 9450 5900
NoConn ~ 9700 5900
Text Notes 8950 6350 0    60   ~ 12
MOUNTING HOLES
Wire Notes Line
	8850 5750 8850 6400
Wire Notes Line
	8850 6400 9850 6400
Wire Notes Line
	9850 6400 9850 5750
Wire Notes Line
	9850 5750 8850 5750
$Comp
L STM32F401RCTx U2
U 1 1 5C2B6EFB
P 7900 3650
F 0 "U2" H 7300 5300 50  0000 L CNN
F 1 "STM32F401RCTx" H 8200 5300 50  0000 L CNN
F 2 "Housings_QFP:LQFP-64_10x10mm_Pitch0.5mm" H 7300 1950 50  0001 R CNN
F 3 "" H 7900 3650 50  0001 C CNN
	1    7900 3650
	1    0    0    -1  
$EndComp
$Comp
L NCP1117ST33T3G U1
U 1 1 5C2B6EFC
P 2350 1650
F 0 "U1" H 2350 1900 50  0000 C CNN
F 1 "NCP1117ST33T3G" H 2350 1850 50  0000 C CNN
F 2 "TO_SOT_Packages_SMD:SOT-223" H 2350 1650 50  0001 C CNN
F 3 "" H 2350 1650 50  0000 C CNN
	1    2350 1650
	1    0    0    -1  
$EndComp
$Comp
L INDUCTOR_SMALL L1
U 1 1 5C2B6EFD
P 1550 1600
F 0 "L1" H 1550 1700 50  0000 C CNN
F 1 "INDUCTOR_SMALL" H 1550 1550 50  0001 C CNN
F 2 "Choke_SMD:Choke_SMD_1206_Handsoldering" H 1550 1600 50  0001 C CNN
F 3 "" H 1550 1600 50  0000 C CNN
	1    1550 1600
	-1   0    0    1   
$EndComp
$Comp
L INDUCTOR_SMALL L2
U 1 1 5C2B6EFE
P 3650 1600
F 0 "L2" H 3650 1700 50  0000 C CNN
F 1 "INDUCTOR_SMALL" H 3650 1550 50  0001 C CNN
F 2 "Choke_SMD:Choke_SMD_1206_Handsoldering" H 3650 1600 50  0001 C CNN
F 3 "" H 3650 1600 50  0000 C CNN
	1    3650 1600
	-1   0    0    1   
$EndComp
$Comp
L GND #PWR05
U 1 1 5C2B6EFF
P 2350 2100
F 0 "#PWR05" H 2350 1850 50  0001 C CNN
F 1 "GND" H 2350 1950 50  0000 C CNN
F 2 "" H 2350 2100 50  0001 C CNN
F 3 "" H 2350 2100 50  0001 C CNN
	1    2350 2100
	1    0    0    -1  
$EndComp
$Comp
L CP1_Small C3
U 1 1 5C2B6F01
P 3000 1850
F 0 "C3" H 3010 1920 50  0000 L CNN
F 1 "47u" H 3010 1770 50  0000 L CNN
F 2 "Capacitors_SMD:c_elec_5x5.3" H 3000 1850 50  0001 C CNN
F 3 "" H 3000 1850 50  0000 C CNN
	1    3000 1850
	1    0    0    -1  
$EndComp
$Comp
L CP1_Small C1
U 1 1 5C2B6F02
P 1900 1850
F 0 "C1" H 1910 1920 50  0000 L CNN
F 1 "10u" H 1910 1770 50  0000 L CNN
F 2 "Capacitors_SMD:c_elec_5x5.3" H 1900 1850 50  0001 C CNN
F 3 "" H 1900 1850 50  0000 C CNN
	1    1900 1850
	1    0    0    -1  
$EndComp
$Comp
L Led_Small D1
U 1 1 5C2B6F03
P 1100 1950
F 0 "D1" H 1050 2075 50  0000 L CNN
F 1 "LRED" V 1100 1700 50  0000 L CNN
F 2 "LEDs:LED_1206" V 1100 1950 50  0001 C CNN
F 3 "" V 1100 1950 50  0000 C CNN
	1    1100 1950
	0    -1   -1   0   
$EndComp
$Comp
L Led_Small D2
U 1 1 5C2B6F04
P 3250 2000
F 0 "D2" V 3150 1750 50  0000 L CNN
F 1 "LYELLOW" V 3250 1600 50  0000 L CNN
F 2 "LEDs:LED_1206" V 3250 2000 50  0001 C CNN
F 3 "" V 3250 2000 50  0000 C CNN
	1    3250 2000
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR06
U 1 1 5C2B6F05
P 3250 2100
F 0 "#PWR06" H 3250 1850 50  0001 C CNN
F 1 "GND" H 3250 1950 50  0000 C CNN
F 2 "" H 3250 2100 50  0001 C CNN
F 3 "" H 3250 2100 50  0001 C CNN
	1    3250 2100
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR07
U 1 1 5C2B6F06
P 1100 2050
F 0 "#PWR07" H 1100 1800 50  0001 C CNN
F 1 "GND" H 1100 1900 50  0000 C CNN
F 2 "" H 1100 2050 50  0001 C CNN
F 3 "" H 1100 2050 50  0001 C CNN
	1    1100 2050
	1    0    0    -1  
$EndComp
$Comp
L R_Small R1
U 1 1 5C2B6F07
P 1100 1750
F 0 "R1" H 1150 1800 50  0000 L CNN
F 1 "330" H 1130 1710 50  0000 L CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" H 1100 1750 50  0001 C CNN
F 3 "" H 1100 1750 50  0000 C CNN
	1    1100 1750
	1    0    0    -1  
$EndComp
$Comp
L R_Small R2
U 1 1 5C2B6F08
P 3250 1800
F 0 "R2" H 3300 1850 50  0000 L CNN
F 1 "220" H 3280 1760 50  0000 L CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" H 3250 1800 50  0001 C CNN
F 3 "" H 3250 1800 50  0000 C CNN
	1    3250 1800
	1    0    0    -1  
$EndComp
$Comp
L VCC #PWR08
U 1 1 5C2B6F09
P 1100 1400
F 0 "#PWR08" H 1100 1250 50  0001 C CNN
F 1 "VCC" H 1100 1550 50  0000 C CNN
F 2 "" H 1100 1400 50  0001 C CNN
F 3 "" H 1100 1400 50  0001 C CNN
	1    1100 1400
	1    0    0    -1  
$EndComp
$Comp
L VCC #PWR09
U 1 1 5C2B6F0A
P 3750 850
F 0 "#PWR09" H 3750 700 50  0001 C CNN
F 1 "VCC" H 3750 1000 50  0000 C CNN
F 2 "" H 3750 850 50  0001 C CNN
F 3 "" H 3750 850 50  0001 C CNN
	1    3750 850 
	1    0    0    -1  
$EndComp
$Comp
L PWR_FLAG #FLG010
U 1 1 5C2B6F0B
P 3750 950
F 0 "#FLG010" H 3750 1025 50  0001 C CNN
F 1 "PWR_FLAG" H 3750 1100 50  0000 C CNN
F 2 "" H 3750 950 50  0001 C CNN
F 3 "" H 3750 950 50  0001 C CNN
	1    3750 950 
	0    -1   -1   0   
$EndComp
Text GLabel 1000 1600 0    60   Input ~ 0
+5VDC
Text GLabel 1900 1350 1    60   Input ~ 0
VCC5V
$Comp
L GND #PWR011
U 1 1 5C2B6F0C
P 4000 850
F 0 "#PWR011" H 4000 600 50  0001 C CNN
F 1 "GND" H 4000 700 50  0000 C CNN
F 2 "" H 4000 850 50  0001 C CNN
F 3 "" H 4000 850 50  0001 C CNN
	1    4000 850 
	-1   0    0    1   
$EndComp
$Comp
L PWR_FLAG #FLG012
U 1 1 5C2B6F0D
P 4050 950
F 0 "#FLG012" H 4050 1025 50  0001 C CNN
F 1 "PWR_FLAG" H 4050 1100 50  0000 C CNN
F 2 "" H 4050 950 50  0001 C CNN
F 3 "" H 4050 950 50  0001 C CNN
	1    4050 950 
	0    1    1    0   
$EndComp
Text GLabel 4000 1600 2    60   Output ~ 0
VCC3V3
Text Notes 3700 2350 0    60   ~ 12
POWER SECTION
$Comp
L CONN_01X04 STLinkV2.1
U 1 1 5C2B6F0E
P 2700 3550
F 0 "STLinkV2.1" V 2900 3550 50  0000 C CNN
F 1 "CONN_01X04" V 2800 3550 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Angled_1x04" H 2700 3550 50  0001 C CNN
F 3 "" H 2700 3550 50  0000 C CNN
	1    2700 3550
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR013
U 1 1 5C2B6F0F
P 2500 3400
F 0 "#PWR013" H 2500 3150 50  0001 C CNN
F 1 "GND" H 2500 3250 50  0000 C CNN
F 2 "" H 2500 3400 50  0001 C CNN
F 3 "" H 2500 3400 50  0001 C CNN
	1    2500 3400
	-1   0    0    1   
$EndComp
Text GLabel 2500 3700 0    60   Input ~ 0
VCC3V3
Text GLabel 1950 3500 0    60   BiDi ~ 0
SWDIO
Text GLabel 1550 3600 0    60   BiDi ~ 0
SWDCLK
$Comp
L CONN_01X03 FT232RPi.1
U 1 1 5C2B6F10
P 1200 4100
F 0 "FT232RPi.1" V 1400 4100 50  0000 C CNN
F 1 "CONN_01X03" V 1300 4100 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Straight_1x03" H 1200 4100 50  0001 C CNN
F 3 "" H 1200 4100 50  0000 C CNN
	1    1200 4100
	-1   0    0    1   
$EndComp
Text GLabel 1500 4000 2    60   Input ~ 0
UART_TX_TTL
Text GLabel 2150 4100 2    60   Output ~ 0
UART_RX_TTL
$Comp
L GND #PWR014
U 1 1 5C2B6F11
P 1400 4200
F 0 "#PWR014" H 1400 3950 50  0001 C CNN
F 1 "GND" H 1400 4050 50  0000 C CNN
F 2 "" H 1400 4200 50  0001 C CNN
F 3 "" H 1400 4200 50  0001 C CNN
	1    1400 4200
	1    0    0    -1  
$EndComp
Text GLabel 7100 2150 0    60   Input ~ 0
nRESET
Text GLabel 7100 2350 0    60   Input ~ 0
BOOT0
Text GLabel 7100 2650 0    60   Input ~ 0
VCC3V3
$Comp
L Crystal_Small XT1
U 1 1 5C2B6F12
P 6200 3300
F 0 "XT1" H 6200 3400 50  0000 C CNN
F 1 "8Mhz" H 6200 3200 50  0000 C CNN
F 2 "Crystals:Crystal_SMD_0603_4Pads" H 6200 3300 50  0001 C CNN
F 3 "" H 6200 3300 50  0000 C CNN
	1    6200 3300
	0    1    1    0   
$EndComp
$Comp
L C_Small C4
U 1 1 5C2B6F13
P 5800 3100
F 0 "C4" H 5810 3170 50  0000 L CNN
F 1 "C_Small" H 5810 3020 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 5800 3100 50  0001 C CNN
F 3 "" H 5800 3100 50  0000 C CNN
	1    5800 3100
	0    1    1    0   
$EndComp
$Comp
L C_Small C5
U 1 1 5C2B6F14
P 5800 3500
F 0 "C5" H 5810 3570 50  0000 L CNN
F 1 "C_Small" H 5810 3420 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 5800 3500 50  0001 C CNN
F 3 "" H 5800 3500 50  0000 C CNN
	1    5800 3500
	0    1    1    0   
$EndComp
Text GLabel 9150 1700 1    60   Input ~ 0
VCC3V3
NoConn ~ 7700 1950
Text GLabel 7250 1550 0    60   Input ~ 0
VCC3V3
$Comp
L GND #PWR015
U 1 1 5C2B6F19
P 7350 900
F 0 "#PWR015" H 7350 650 50  0001 C CNN
F 1 "GND" H 7350 750 50  0000 C CNN
F 2 "" H 7350 900 50  0001 C CNN
F 3 "" H 7350 900 50  0001 C CNN
	1    7350 900 
	-1   0    0    1   
$EndComp
$Comp
L C_Small C7
U 1 1 5C2B6F1A
P 7800 1300
F 0 "C7" H 7810 1370 50  0000 L CNN
F 1 "100n" H 7810 1220 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 7800 1300 50  0001 C CNN
F 3 "" H 7800 1300 50  0000 C CNN
	1    7800 1300
	1    0    0    -1  
$EndComp
$Comp
L C_Small C8
U 1 1 5C2B6F1B
P 8100 1300
F 0 "C8" H 8110 1370 50  0000 L CNN
F 1 "100n" H 8110 1220 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 8100 1300 50  0001 C CNN
F 3 "" H 8100 1300 50  0000 C CNN
	1    8100 1300
	1    0    0    -1  
$EndComp
$Comp
L C_Small C9
U 1 1 5C2B6F1C
P 8350 1300
F 0 "C9" H 8360 1370 50  0000 L CNN
F 1 "100n" H 8360 1220 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 8350 1300 50  0001 C CNN
F 3 "" H 8350 1300 50  0000 C CNN
	1    8350 1300
	1    0    0    -1  
$EndComp
Text Notes 1650 4600 0    60   ~ 12
DEBUG/PROGRAMMING SECTION
Text GLabel 10100 2350 2    39   Input ~ 0
UART_TX_TTL
Text GLabel 10100 2450 2    39   Output ~ 0
UART_RX_TTL
$Comp
L R_Small R6
U 1 1 5C2B6F1D
P 9650 2150
F 0 "R6" H 9680 2170 50  0000 L CNN
F 1 "10K" H 9680 2110 50  0000 L CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" H 9650 2150 50  0001 C CNN
F 3 "" H 9650 2150 50  0000 C CNN
	1    9650 2150
	1    0    0    -1  
$EndComp
Text GLabel 9650 1950 1    60   Input ~ 0
VCC3V3
$Comp
L R_Small R7
U 1 1 5C2B6F1E
P 9900 2150
F 0 "R7" H 9930 2170 50  0000 L CNN
F 1 "10K" H 9930 2110 50  0000 L CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" H 9900 2150 50  0001 C CNN
F 3 "" H 9900 2150 50  0000 C CNN
	1    9900 2150
	1    0    0    -1  
$EndComp
Text GLabel 8750 4150 2    39   BiDi ~ 0
mD3
Text GLabel 8750 4250 2    39   BiDi ~ 0
mD4
Text GLabel 8750 4350 2    39   BiDi ~ 0
mD5
Text GLabel 8750 4450 2    39   BiDi ~ 0
mD6
Text GLabel 8750 4550 2    39   BiDi ~ 0
mD7
$Comp
L R_Small R4
U 1 1 5C2B6F1F
P 9050 5350
F 0 "R4" H 8900 5350 50  0000 L CNN
F 1 "2.2k" H 9080 5310 50  0000 L CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" H 9050 5350 50  0001 C CNN
F 3 "" H 9050 5350 50  0000 C CNN
	1    9050 5350
	1    0    0    -1  
$EndComp
Text GLabel 9050 4650 2    39   BiDi ~ 0
~mEXSEL
Text GLabel 9050 4950 2    39   BiDi ~ 0
~mMPD
Text GLabel 9050 5150 2    39   BiDi ~ 0
~mREF
Text GLabel 8700 3350 2    39   BiDi ~ 0
~mCCTL
Text GLabel 7000 3550 0    39   BiDi ~ 0
mB02/PHI2
$Comp
L CONN_01X01 P1
U 1 1 5C2B6F21
P 900 3300
F 0 "P1" H 900 3400 50  0000 C CNN
F 1 "CONN_01X01" H 850 3150 50  0000 C CNN
F 2 "Measurement_Points:Measurement_Point_Round-SMD-Pad_Small" H 900 3300 50  0001 C CNN
F 3 "" H 900 3300 50  0000 C CNN
	1    900  3300
	-1   0    0    1   
$EndComp
Text GLabel 1100 3300 2    60   Output ~ 0
TP1
Text GLabel 7000 3850 0    39   BiDi ~ 0
mA1
Text GLabel 7000 3950 0    39   BiDi ~ 0
mA2
Text GLabel 7000 4050 0    39   BiDi ~ 0
mA3
Text GLabel 7000 4150 0    39   BiDi ~ 0
mA4
Text GLabel 7000 4250 0    39   BiDi ~ 0
mA5
Text GLabel 7000 4450 0    39   BiDi ~ 0
mA7
Text GLabel 7000 4550 0    39   BiDi ~ 0
mA8
Text GLabel 7000 4650 0    39   BiDi ~ 0
mA9
Text GLabel 7000 4850 0    39   BiDi ~ 0
mA11
Text GLabel 7000 4950 0    39   BiDi ~ 0
mA12
Text GLabel 7000 5050 0    39   BiDi ~ 0
mA13
Text GLabel 7000 5150 0    39   BiDi ~ 0
mA14
Text GLabel 7000 5250 0    39   BiDi ~ 0
mA15
Text GLabel 8700 2550 2    39   BiDi ~ 0
PB0
Text GLabel 8700 2650 2    39   BiDi ~ 0
PB1
Text GLabel 8700 2850 2    39   BiDi ~ 0
PB3
Text GLabel 8700 2950 2    39   BiDi ~ 0
PB4
Text GLabel 8700 3050 2    39   BiDi ~ 0
PB5
Text GLabel 8700 3150 2    39   BiDi ~ 0
PB6
$Comp
L GND #PWR016
U 1 1 5C2B6F22
P 7900 5750
F 0 "#PWR016" H 7900 5500 50  0001 C CNN
F 1 "GND" H 7900 5600 50  0000 C CNN
F 2 "" H 7900 5750 50  0001 C CNN
F 3 "" H 7900 5750 50  0001 C CNN
	1    7900 5750
	1    0    0    -1  
$EndComp
$Comp
L ATARICARTRIDGE CART1
U 1 1 5C2B6F23
P 2100 6250
F 0 "CART1" H 2550 7100 50  0000 C CNN
F 1 "ATARI-CARTRIDGE" H 2150 6350 50  0000 C CNN
F 2 "RetroBitLab:ATARI-LEFT-CARTRIDGE" H 2100 5300 50  0000 C CNN
F 3 "" H 2100 5400 50  0000 C CNN
	1    2100 6250
	1    0    0    -1  
$EndComp
$Comp
L ECIBUS ECI1
U 1 1 5C2B6F24
P 5250 6200
F 0 "ECI1" H 5700 6650 50  0000 C CNN
F 1 "ECIBUS" H 5300 5900 50  0000 C CNN
F 2 "RetroBitLab:ATARI-XE-ECI-SLOT" H 5250 5650 50  0000 C CNN
F 3 "" H 5250 5350 50  0000 C CNN
	1    5250 6200
	1    0    0    -1  
$EndComp
Text GLabel 1200 6800 0    39   Input ~ 0
+5VDC
Text GLabel 4350 6550 0    39   Input ~ 0
+5VDC
$Comp
L GND #PWR017
U 1 1 5C2B6F25
P 3250 5700
F 0 "#PWR017" H 3250 5450 50  0001 C CNN
F 1 "GND" H 3250 5550 50  0000 C CNN
F 2 "" H 3250 5700 50  0001 C CNN
F 3 "" H 3250 5700 50  0001 C CNN
	1    3250 5700
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR018
U 1 1 5C2B6F26
P 6150 6550
F 0 "#PWR018" H 6150 6300 50  0001 C CNN
F 1 "GND" H 6150 6400 50  0000 C CNN
F 2 "" H 6150 6550 50  0001 C CNN
F 3 "" H 6150 6550 50  0001 C CNN
	1    6150 6550
	1    0    0    -1  
$EndComp
Text GLabel 6150 6450 2    39   BiDi ~ 0
A15
Text GLabel 6150 6350 2    39   BiDi ~ 0
A14
Text GLabel 6150 6250 2    39   BiDi ~ 0
A13
Text GLabel 3000 6400 2    39   BiDi ~ 0
A12
Text GLabel 3000 6800 2    39   BiDi ~ 0
A10
Text GLabel 3000 6700 2    39   BiDi ~ 0
A11
Text GLabel 3000 6300 2    39   BiDi ~ 0
A9
Text GLabel 3000 6200 2    39   BiDi ~ 0
A8
Text GLabel 3000 6100 2    39   BiDi ~ 0
A7
Text GLabel 3000 6000 2    39   BiDi ~ 0
A6
Text GLabel 3000 5900 2    39   BiDi ~ 0
A5
Text GLabel 3000 5800 2    39   BiDi ~ 0
A4
Text GLabel 3000 6600 2    39   BiDi ~ 0
D7
Text GLabel 3000 6500 2    39   BiDi ~ 0
D3
Text GLabel 3000 6900 2    39   BiDi ~ 0
R/~W
Text GLabel 3000 7000 2    39   BiDi ~ 0
B02/PHI2
Text GLabel 1200 6600 0    39   BiDi ~ 0
D6
Text GLabel 1200 6500 0    39   BiDi ~ 0
D0
Text GLabel 1200 6400 0    39   BiDi ~ 0
D1
Text GLabel 1200 6300 0    39   BiDi ~ 0
D2
Text GLabel 1200 6200 0    39   BiDi ~ 0
D5
Text GLabel 1200 6100 0    39   BiDi ~ 0
D4
Text GLabel 1200 5700 0    39   BiDi ~ 0
A3
Text GLabel 1200 5800 0    39   BiDi ~ 0
A2
Text GLabel 1200 5900 0    39   BiDi ~ 0
A1
Text GLabel 1200 6000 0    39   BiDi ~ 0
A0
Text GLabel 1200 7000 0    39   BiDi ~ 0
~CCTL
Text GLabel 4350 6450 0    39   BiDi ~ 0
~REF
Text GLabel 4350 6250 0    39   BiDi ~ 0
~MPD
Text GLabel 4350 6150 0    39   BiDi ~ 0
~D1XX
Text GLabel 4350 6050 0    39   BiDi ~ 0
~RST
Text GLabel 4350 5950 0    39   BiDi ~ 0
~EXSEL
Text GLabel 6150 6150 2    39   BiDi ~ 0
~HALT
Text GLabel 6150 6050 2    39   BiDi ~ 0
~IRQ
Text Notes 800  5250 0    60   ~ 12
ATARI CONNECTIONS
Text GLabel 4400 3850 3    60   Input ~ 0
BOOT0
$Comp
L CONN_01X03 JP1
U 1 1 5C2B6F27
P 4400 3450
F 0 "JP1" H 4400 3650 50  0000 C CNN
F 1 "CONN_01X03" V 4500 3450 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Straight_1x03" H 4400 3450 50  0001 C CNN
F 3 "" H 4400 3450 50  0000 C CNN
	1    4400 3450
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR019
U 1 1 5C2B6F28
P 4500 3650
F 0 "#PWR019" H 4500 3400 50  0001 C CNN
F 1 "GND" H 4500 3500 50  0000 C CNN
F 2 "" H 4500 3650 50  0001 C CNN
F 3 "" H 4500 3650 50  0001 C CNN
	1    4500 3650
	0    -1   -1   0   
$EndComp
Text GLabel 4200 3650 0    60   Input ~ 0
VCC3V3
Text Notes 3700 3200 0    60   ~ 12
BOOTSEL
$Comp
L SW_PUSH SW1
U 1 1 5C2B6F29
P 5800 1350
F 0 "SW1" H 5950 1460 50  0000 C CNN
F 1 "SW_PUSH" H 5800 1270 50  0000 C CNN
F 2 "Buttons_Switches_SMD:SW_SPST_FSMSM" H 5800 1350 50  0001 C CNN
F 3 "" H 5800 1350 50  0000 C CNN
	1    5800 1350
	0    1    1    0   
$EndComp
$Comp
L GND #PWR020
U 1 1 5C2B6F2A
P 5800 1050
F 0 "#PWR020" H 5800 800 50  0001 C CNN
F 1 "GND" H 5800 900 50  0000 C CNN
F 2 "" H 5800 1050 50  0001 C CNN
F 3 "" H 5800 1050 50  0001 C CNN
	1    5800 1050
	-1   0    0    1   
$EndComp
$Comp
L R_Small R3
U 1 1 5C2B6F2B
P 5800 1850
F 0 "R3" H 5830 1870 50  0000 L CNN
F 1 "10K" H 5830 1810 50  0000 L CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" H 5800 1850 50  0001 C CNN
F 3 "" H 5800 1850 50  0000 C CNN
	1    5800 1850
	1    0    0    -1  
$EndComp
Text GLabel 5800 2000 3    60   Input ~ 0
VCC3V3
Text Notes 4750 700  0    60   ~ 12
RESET BUTTON
$Comp
L CONN_01X01 P2
U 1 1 5C2B6F2C
P 9000 6100
F 0 "P2" H 9000 6200 50  0001 C CNN
F 1 "CONN_01X01" V 9100 6100 50  0001 C CNN
F 2 "Connect:1pin" V 9200 6100 50  0001 C CNN
F 3 "" H 9000 6100 50  0000 C CNN
	1    9000 6100
	0    1    1    0   
$EndComp
NoConn ~ 9000 5900
$Comp
L CONN_01X01 P3
U 1 1 5C2B6F2D
P 9250 6100
F 0 "P3" H 9250 6200 50  0001 C CNN
F 1 "CONN_01X01" V 9350 6100 50  0001 C CNN
F 2 "Connect:1pin" V 9450 6100 50  0001 C CNN
F 3 "" H 9250 6100 50  0000 C CNN
	1    9250 6100
	0    1    1    0   
$EndComp
NoConn ~ 9250 5900
$Comp
L CONN_01X01 P4
U 1 1 5C2B6F2E
P 9450 6100
F 0 "P4" H 9450 6200 50  0001 C CNN
F 1 "CONN_01X01" V 9550 6100 50  0001 C CNN
F 2 "Connect:1pin" V 9650 6100 50  0001 C CNN
F 3 "" H 9450 6100 50  0000 C CNN
	1    9450 6100
	0    1    1    0   
$EndComp
NoConn ~ 9450 5900
$Comp
L CONN_01X01 P5
U 1 1 5C2B6F2F
P 9700 6100
F 0 "P5" H 9700 6200 50  0001 C CNN
F 1 "CONN_01X01" V 9800 6100 50  0001 C CNN
F 2 "Connect:1pin" V 9900 6100 50  0001 C CNN
F 3 "" H 9700 6100 50  0000 C CNN
	1    9700 6100
	0    1    1    0   
$EndComp
NoConn ~ 9700 5900
Text Notes 8950 6350 0    60   ~ 12
MOUNTING HOLES
Text GLabel 7000 4350 0    39   BiDi ~ 0
mA6
$Sheet
S 0    8850 11700 8250
U 5C2B74C3
F0 "SRAM  & Level Shifters" 60
F1 "sram-levelshifters.sch" 60
$EndSheet
Text GLabel 8700 3450 2    39   BiDi ~ 0
SWDIO
Text GLabel 8700 3550 2    39   BiDi ~ 0
SWDCLK
Text GLabel 8700 3650 2    39   BiDi ~ 0
mR/~W
Text GLabel 8750 3850 2    39   BiDi ~ 0
mD0
Wire Wire Line
	5800 1650 5800 1750
Wire Wire Line
	5450 1700 5800 1700
Connection ~ 5800 1700
Wire Wire Line
	5800 1950 5800 2000
$Comp
L C_Small C6
U 1 1 5C2B6F18
P 7550 1300
F 0 "C6" H 7560 1370 50  0000 L CNN
F 1 "100n" H 7560 1220 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 7550 1300 50  0001 C CNN
F 3 "" H 7550 1300 50  0000 C CNN
	1    7550 1300
	1    0    0    -1  
$EndComp
$Comp
L Led_Small D3
U 1 1 5C2B6F16
P 9150 2100
F 0 "D3" H 9100 2225 50  0000 L CNN
F 1 "ACT" H 9100 2000 50  0000 L CNN
F 2 "LEDs:LED_1206" V 9150 2100 50  0001 C CNN
F 3 "" V 9150 2100 50  0000 C CNN
	1    9150 2100
	0    -1   -1   0   
$EndComp
$Comp
L R_Small R5
U 1 1 5C2B6F17
P 9150 1900
F 0 "R5" H 9180 1920 50  0000 L CNN
F 1 "220" H 9180 1860 50  0000 L CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" H 9150 1900 50  0001 C CNN
F 3 "" H 9150 1900 50  0000 C CNN
	1    9150 1900
	1    0    0    -1  
$EndComp
Text GLabel 8750 3950 2    39   BiDi ~ 0
mD1
Text GLabel 8750 4050 2    39   BiDi ~ 0
mD2
Text GLabel 8700 2750 2    39   BiDi ~ 0
PB2
Text GLabel 7000 3750 0    39   BiDi ~ 0
mA0
Text GLabel 7000 4750 0    39   BiDi ~ 0
mA10
Text GLabel 9900 1950 1    60   Input ~ 0
VCC3V3
Text Notes 9000 2950 0    60   ~ 0
16K BANK SELECTORS
Text GLabel 8700 3250 2    39   BiDi ~ 0
PB7
Text GLabel 9050 4750 2    39   BiDi ~ 0
~mD1XX
Text GLabel 9050 4850 2    39   BiDi ~ 0
~mHALT
Text GLabel 9050 5050 2    39   BiDi ~ 0
~mIRQ
Text GLabel 9300 5250 2    39   BiDi ~ 0
~mRST
Connection ~ 9050 5250
Wire Wire Line
	8500 3450 8700 3450
Wire Wire Line
	8500 3550 8700 3550
Wire Wire Line
	8500 3650 8700 3650
Wire Wire Line
	8500 3350 8700 3350
Wire Wire Line
	8500 3250 8700 3250
Wire Wire Line
	7000 3550 7200 3550
NoConn ~ 7200 2550
Text GLabel 8750 2150 2    60   Output ~ 0
TP1
$Comp
L GND #PWR021
U 1 1 5C2B6F15
P 5400 3300
F 0 "#PWR021" H 5400 3050 50  0001 C CNN
F 1 "GND" H 5400 3150 50  0000 C CNN
F 2 "" H 5400 3300 50  0001 C CNN
F 3 "" H 5400 3300 50  0001 C CNN
	1    5400 3300
	0    1    1    0   
$EndComp
Wire Wire Line
	8500 3050 8700 3050
Wire Wire Line
	8500 2950 8700 2950
Wire Wire Line
	8500 2850 8700 2850
Wire Wire Line
	8700 2750 8500 2750
Wire Wire Line
	8500 2650 8700 2650
Text GLabel 10200 3250 1    60   Input ~ 0
VCC3V3
$Comp
L GND #PWR022
U 1 1 5C2F7351
P 10200 4550
F 0 "#PWR022" H 10200 4300 50  0001 C CNN
F 1 "GND" H 10200 4400 50  0000 C CNN
F 2 "" H 10200 4550 50  0001 C CNN
F 3 "" H 10200 4550 50  0001 C CNN
	1    10200 4550
	1    0    0    -1  
$EndComp
$Comp
L 74LS138 U3
U 1 1 5C2F63E8
P 10200 3850
F 0 "U3" H 9900 4300 50  0000 C CNN
F 1 "74LS138" H 9900 3300 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-16_4.4x5mm_Pitch0.65mm" H 10200 3850 50  0001 C CNN
F 3 "" H 10200 3850 50  0001 C CNN
	1    10200 3850
	1    0    0    -1  
$EndComp
NoConn ~ 10700 3950
NoConn ~ 10700 4050
NoConn ~ 10700 4150
NoConn ~ 10700 4250
Text GLabel 9700 3550 0    39   BiDi ~ 0
PB5
Text GLabel 9700 3650 0    39   BiDi ~ 0
PB6
Text GLabel 9700 3750 0    39   BiDi ~ 0
PB7
Text GLabel 10700 3550 2    39   BiDi ~ 0
~BSEL0
Text GLabel 10700 3650 2    39   BiDi ~ 0
~BSEL1
Text GLabel 10700 3750 2    39   BiDi ~ 0
~BSEL2
Text GLabel 10700 3850 2    39   BiDi ~ 0
~BSEL3
Text Notes 9750 4950 0    60   ~ 0
ADDRESS DECODER 
$Comp
L CONN_01X04 EXTPWR1
U 1 1 5C2F33D4
P 2750 950
F 0 "EXTPWR1" V 2950 950 50  0000 C CNN
F 1 "CONN_01X04" V 2850 950 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Angled_1x04" H 2750 950 50  0001 C CNN
F 3 "" H 2750 950 50  0000 C CNN
	1    2750 950 
	0    1    1    0   
$EndComp
$Comp
L GND #PWR023
U 1 1 5C2F34E0
P 2800 750
F 0 "#PWR023" H 2800 500 50  0001 C CNN
F 1 "GND" H 2700 600 50  0000 C CNN
F 2 "" H 2800 750 50  0001 C CNN
F 3 "" H 2800 750 50  0001 C CNN
	1    2800 750 
	-1   0    0    1   
$EndComp
$Comp
L GND #PWR024
U 1 1 5C2F354E
P 2700 750
F 0 "#PWR024" H 2700 500 50  0001 C CNN
F 1 "GND" H 2800 600 50  0000 C CNN
F 2 "" H 2700 750 50  0001 C CNN
F 3 "" H 2700 750 50  0001 C CNN
	1    2700 750 
	-1   0    0    1   
$EndComp
NoConn ~ 2600 750 
Text GLabel 3000 750  2    39   BiDi ~ 0
+5VDC
Wire Wire Line
	3000 750  2900 750 
$Sheet
S 50   17500 11650 8350
U 5C2FF215
F0 "Expansion Slots pass through" 39
F1 "expansionslotspt.sch" 39
$EndSheet
Text GLabel 6150 5950 2    39   BiDi ~ 0
RSRVD
Text GLabel 4350 6350 0    39   BiDi ~ 0
AUDIO
Text GLabel 3000 5600 2    39   BiDi ~ 0
RD4
Text GLabel 1200 5600 0    39   BiDi ~ 0
~S4
Text GLabel 1200 6700 0    39   BiDi ~ 0
~S5
Text GLabel 1200 6900 0    39   BiDi ~ 0
RD5
Text GLabel 9700 4150 0    39   BiDi ~ 0
~ADDRSEL16K
Text GLabel 9700 4250 0    39   BiDi ~ 0
~ADDRSEL16K
Text GLabel 9700 4050 0    39   Input ~ 0
VCC3V3
$EndSCHEMATC
