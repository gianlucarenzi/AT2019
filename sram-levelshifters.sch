EESchema Schematic File Version 2  date Mon 07 Jan 2019 11:40:50 AM CET
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
EELAYER 25  0
EELAYER END
$Descr A4 11700 8267
encoding utf-8
Sheet 2 3
Title "STATIC RAM 2 MBytes (512K x 8 x 4)"
Date "7 jan 2019"
Rev ""
Comp "RetroBit Lab"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L ISSI61WV5128BL U11
U 1 1 5C2B9006
P 7650 2250
F 0 "U11" H 7350 3300 50  0000 C CNN
F 1 "ISSI61WV5128BL" H 8000 1200 50  0000 C CNN
F 2 "RetroBitLab:SOP-32L-20.5x11.30-1.27mm" H 7650 2250 50  0001 C CIN
	1    7650 2250
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR31
U 1 1 5C2BB99F
P 7650 3350
F 0 "#PWR31" H 7650 3100 50  0001 C CNN
F 1 "GND" H 7650 3200 50  0000 C CNN
	1    7650 3350
	1    0    0    -1  
$EndComp
Text GLabel 7650 1000 1    39   Input ~ 0
VCC3V3
Text GLabel 8150 2650 3    39   BiDi ~ 0
~BSEL0
Text GLabel 8250 2900 3    39   BiDi ~ 0
mR/~W
Wire Wire Line
	8150 2450 8150 2650
Wire Wire Line
	8150 2300 8250 2300
Wire Wire Line
	8250 2300 8250 2900
Wire Wire Line
	8150 2200 8350 2200
Wire Wire Line
	8350 2200 8350 2650
Wire Wire Line
	7650 1000 7650 1150
$Comp
L C_Small C10
U 1 1 5C2BF542
P 7800 1100
F 0 "C10" H 7810 1170 50  0000 L CNN
F 1 "100n" V 7900 900 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 7800 1100 50  0001 C CNN
	1    7800 1100
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR33
U 1 1 5C2BF58F
P 7900 1100
F 0 "#PWR33" H 7900 850 50  0001 C CNN
F 1 "GND" H 7900 950 50  0000 C CNN
	1    7900 1100
	0    -1   -1   0   
$EndComp
$Comp
L TXB0108-PW U6
U 1 1 5C2BF6B2
P 1750 3550
F 0 "U6" H 1550 4300 60  0000 L CNN
F 1 "TXB0108-PW" H 1550 2800 60  0000 L CNN
F 2 "Housings_SSOP:SSOP-20_4.4x6.5mm_Pitch0.65mm" H 1550 3500 60  0001 C CNN
	1    1750 3550
	1    0    0    -1  
$EndComp
$Comp
L TXB0108-PW U5
U 1 1 5C2BF846
P 1750 1800
F 0 "U5" H 1550 2550 60  0000 L CNN
F 1 "TXB0108-PW" H 1550 1050 60  0000 L CNN
F 2 "Housings_SSOP:SSOP-20_4.4x6.5mm_Pitch0.65mm" H 1550 1750 60  0001 C CNN
	1    1750 1800
	1    0    0    -1  
$EndComp
$Comp
L TXB0108-PW U4
U 1 1 5C2BF9CC
P 1600 5800
F 0 "U4" H 1400 6550 60  0000 L CNN
F 1 "TXB0108-PW" H 1400 5050 60  0000 L CNN
F 2 "Housings_SSOP:SSOP-20_4.4x6.5mm_Pitch0.65mm" H 1400 5750 60  0001 C CNN
	1    1600 5800
	1    0    0    -1  
$EndComp
$Comp
L TXB0108-PW U8
U 1 1 5C2BFA07
P 4050 5800
F 0 "U8" H 3850 6550 60  0000 L CNN
F 1 "TXB0108-PW" H 3850 5050 60  0000 L CNN
F 2 "Housings_SSOP:SSOP-20_4.4x6.5mm_Pitch0.65mm" H 3850 5750 60  0001 C CNN
	1    4050 5800
	1    0    0    -1  
$EndComp
$Comp
L TXB0108-PW U10
U 1 1 5C2BFAD5
P 4300 1850
F 0 "U10" H 4100 2600 60  0000 L CNN
F 1 "TXB0108-PW" H 4100 1100 60  0000 L CNN
F 2 "Housings_SSOP:SSOP-20_4.4x6.5mm_Pitch0.65mm" H 4100 1800 60  0001 C CNN
	1    4300 1850
	1    0    0    -1  
$EndComp
Text GLabel 2250 1500 2    39   BiDi ~ 0
A0
Text GLabel 2250 1600 2    39   BiDi ~ 0
A1
Text GLabel 2250 1700 2    39   BiDi ~ 0
A2
Text GLabel 2250 1800 2    39   BiDi ~ 0
A3
Text GLabel 2250 1900 2    39   BiDi ~ 0
A4
Text GLabel 2250 2000 2    39   BiDi ~ 0
A5
Text GLabel 2250 2100 2    39   BiDi ~ 0
A6
Text GLabel 2250 2200 2    39   BiDi ~ 0
A7
Text GLabel 2250 1200 2    39   BiDi ~ 0
VCC5V
Text GLabel 2250 2950 2    39   BiDi ~ 0
VCC5V
Text GLabel 2100 5200 2    39   BiDi ~ 0
VCC5V
Text GLabel 4550 5200 2    39   BiDi ~ 0
VCC5V
Text GLabel 4800 1250 2    39   BiDi ~ 0
VCC5V
$Comp
L GND #PWR26
U 1 1 5C2D99D7
P 1350 2400
F 0 "#PWR26" H 1350 2150 50  0001 C CNN
F 1 "GND" H 1350 2250 50  0000 C CNN
	1    1350 2400
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR27
U 1 1 5C2D99FE
P 1350 4150
F 0 "#PWR27" H 1350 3900 50  0001 C CNN
F 1 "GND" H 1350 4000 50  0000 C CNN
	1    1350 4150
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR25
U 1 1 5C2D9EC5
P 1200 6400
F 0 "#PWR25" H 1200 6150 50  0001 C CNN
F 1 "GND" H 1200 6250 50  0000 C CNN
	1    1200 6400
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR28
U 1 1 5C2D9EE5
P 3650 6400
F 0 "#PWR28" H 3650 6150 50  0001 C CNN
F 1 "GND" H 3650 6250 50  0000 C CNN
	1    3650 6400
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR29
U 1 1 5C2D9F05
P 3900 2450
F 0 "#PWR29" H 3900 2200 50  0001 C CNN
F 1 "GND" H 3900 2300 50  0000 C CNN
	1    3900 2450
	1    0    0    -1  
$EndComp
Text GLabel 2250 3250 2    39   BiDi ~ 0
A8
Text GLabel 2250 3350 2    39   BiDi ~ 0
A9
Text GLabel 2250 3450 2    39   BiDi ~ 0
A10
Text GLabel 2250 3550 2    39   BiDi ~ 0
A11
Text GLabel 2250 3650 2    39   BiDi ~ 0
A12
Text GLabel 2250 3750 2    39   BiDi ~ 0
A13
Text GLabel 2250 3850 2    39   BiDi ~ 0
A14
Text GLabel 2250 3950 2    39   BiDi ~ 0
A15
Text GLabel 1350 2950 0    39   BiDi ~ 0
VCC3V3
Text GLabel 1350 1200 0    39   BiDi ~ 0
VCC3V3
Text GLabel 1200 5200 0    39   BiDi ~ 0
VCC3V3
Text GLabel 3650 5200 0    39   BiDi ~ 0
VCC3V3
Text GLabel 3900 1250 0    39   BiDi ~ 0
VCC3V3
Text GLabel 1350 1400 0    39   BiDi ~ 0
VCC3V3
Text GLabel 1350 3150 0    39   BiDi ~ 0
VCC3V3
Text GLabel 1200 5400 0    39   BiDi ~ 0
VCC3V3
Text GLabel 3650 5400 0    39   BiDi ~ 0
VCC3V3
Text GLabel 3900 1450 0    39   BiDi ~ 0
VCC3V3
Text GLabel 1350 1500 0    39   BiDi ~ 0
mA0
Text GLabel 1350 1600 0    39   BiDi ~ 0
mA1
Text GLabel 1350 1700 0    39   BiDi ~ 0
mA2
Text GLabel 1350 1800 0    39   BiDi ~ 0
mA3
Text GLabel 1350 1900 0    39   BiDi ~ 0
mA4
Text GLabel 1350 2000 0    39   BiDi ~ 0
mA5
Text GLabel 1350 2100 0    39   BiDi ~ 0
mA6
Text GLabel 1350 2200 0    39   BiDi ~ 0
mA7
Text GLabel 1350 3250 0    39   BiDi ~ 0
mA8
Text GLabel 1350 3350 0    39   BiDi ~ 0
mA9
Text GLabel 1350 3450 0    39   BiDi ~ 0
mA10
Text GLabel 1350 3550 0    39   BiDi ~ 0
mA11
Text GLabel 1350 3650 0    39   BiDi ~ 0
mA12
Text GLabel 1350 3750 0    39   BiDi ~ 0
mA13
Text GLabel 1350 3850 0    39   BiDi ~ 0
mA14
Text GLabel 1350 3950 0    39   BiDi ~ 0
mA15
Wire Notes Line
	600  650  3050 650 
Wire Notes Line
	3050 650  3050 4550
Wire Notes Line
	3050 4550 600  4550
Wire Notes Line
	600  4550 600  650 
Text Notes 750  800  0    59   ~ 12
ADDRESS BUS SECTION
Text GLabel 7150 1350 0    39   BiDi ~ 0
mA0
Text GLabel 7150 1450 0    39   BiDi ~ 0
mA1
Text GLabel 7150 1550 0    39   BiDi ~ 0
mA2
Text GLabel 7150 1650 0    39   BiDi ~ 0
mA3
Text GLabel 7150 1750 0    39   BiDi ~ 0
mA4
Text GLabel 7150 1850 0    39   BiDi ~ 0
mA5
Text GLabel 7150 1950 0    39   BiDi ~ 0
mA6
Text GLabel 7150 2050 0    39   BiDi ~ 0
mA7
Text GLabel 7150 2150 0    39   BiDi ~ 0
mA8
Text GLabel 7150 2250 0    39   BiDi ~ 0
mA9
Text GLabel 7150 2350 0    39   BiDi ~ 0
mA10
Text GLabel 7150 2450 0    39   BiDi ~ 0
mA11
Text GLabel 7150 2550 0    39   BiDi ~ 0
mA12
Text GLabel 7150 2650 0    39   BiDi ~ 0
mA13
Text GLabel 4800 1550 2    39   BiDi ~ 0
D0
Text GLabel 4800 1650 2    39   BiDi ~ 0
D1
Text GLabel 4800 1750 2    39   BiDi ~ 0
D2
Text GLabel 4800 1850 2    39   BiDi ~ 0
D3
Text GLabel 4800 1950 2    39   BiDi ~ 0
D4
Text GLabel 4800 2050 2    39   BiDi ~ 0
D5
Text GLabel 4800 2150 2    39   BiDi ~ 0
D6
Text GLabel 4800 2250 2    39   BiDi ~ 0
D7
Text GLabel 3900 2250 0    39   BiDi ~ 0
mD7
Text GLabel 3900 2150 0    39   BiDi ~ 0
mD6
Text GLabel 3900 2050 0    39   BiDi ~ 0
mD5
Text GLabel 3900 1950 0    39   BiDi ~ 0
mD4
Text GLabel 3900 1850 0    39   BiDi ~ 0
mD3
Text GLabel 3900 1750 0    39   BiDi ~ 0
mD2
Text GLabel 3900 1650 0    39   BiDi ~ 0
mD1
Text GLabel 3900 1550 0    39   BiDi ~ 0
mD0
Wire Notes Line
	3150 650  5150 650 
Wire Notes Line
	5150 650  5150 3100
Wire Notes Line
	5150 3100 3150 3100
Wire Notes Line
	3150 3100 3150 650 
Text Notes 3250 800  0    59   ~ 12
DATA BUS SECTION
Text GLabel 8150 1350 2    39   BiDi ~ 0
mD0
Text GLabel 8150 1450 2    39   BiDi ~ 0
mD1
Text GLabel 8150 1550 2    39   BiDi ~ 0
mD2
Text GLabel 8150 1650 2    39   BiDi ~ 0
mD3
Text GLabel 8150 1750 2    39   BiDi ~ 0
mD4
Text GLabel 8150 1850 2    39   BiDi ~ 0
mD5
Text GLabel 8150 1950 2    39   BiDi ~ 0
mD6
Text GLabel 8150 2050 2    39   BiDi ~ 0
mD7
$Comp
L ISSI61WV5128BL U13
U 1 1 5C2DCB84
P 9300 2250
F 0 "U13" H 9000 3300 50  0000 C CNN
F 1 "ISSI61WV5128BL" H 9650 1200 50  0000 C CNN
F 2 "RetroBitLab:SOP-32L-20.5x11.30-1.27mm" H 9300 2250 50  0001 C CIN
	1    9300 2250
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR35
U 1 1 5C2DCB90
P 9300 3350
F 0 "#PWR35" H 9300 3100 50  0001 C CNN
F 1 "GND" H 9300 3200 50  0000 C CNN
	1    9300 3350
	1    0    0    -1  
$EndComp
Text GLabel 9300 1000 1    39   Input ~ 0
VCC3V3
Text GLabel 9800 2650 3    39   BiDi ~ 0
~BSEL1
Text GLabel 9900 2900 3    39   BiDi ~ 0
mR/~W
Wire Wire Line
	9800 2450 9800 2650
Wire Wire Line
	9800 2300 9900 2300
Wire Wire Line
	9900 2300 9900 2900
Wire Wire Line
	9800 2200 10000 2200
Wire Wire Line
	10000 2200 10000 2650
Wire Wire Line
	9300 1000 9300 1150
$Comp
L C_Small C12
U 1 1 5C2DCB9F
P 9450 1100
F 0 "C12" H 9460 1170 50  0000 L CNN
F 1 "100n" V 9550 900 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 9450 1100 50  0001 C CNN
	1    9450 1100
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR37
U 1 1 5C2DCBA5
P 9550 1100
F 0 "#PWR37" H 9550 850 50  0001 C CNN
F 1 "GND" H 9550 950 50  0000 C CNN
	1    9550 1100
	0    -1   -1   0   
$EndComp
Text GLabel 8800 1350 0    39   BiDi ~ 0
mA0
Text GLabel 8800 1450 0    39   BiDi ~ 0
mA1
Text GLabel 8800 1550 0    39   BiDi ~ 0
mA2
Text GLabel 8800 1650 0    39   BiDi ~ 0
mA3
Text GLabel 8800 1750 0    39   BiDi ~ 0
mA4
Text GLabel 8800 1850 0    39   BiDi ~ 0
mA5
Text GLabel 8800 1950 0    39   BiDi ~ 0
mA6
Text GLabel 8800 2050 0    39   BiDi ~ 0
mA7
Text GLabel 8800 2150 0    39   BiDi ~ 0
mA8
Text GLabel 8800 2250 0    39   BiDi ~ 0
mA9
Text GLabel 8800 2350 0    39   BiDi ~ 0
mA10
Text GLabel 8800 2450 0    39   BiDi ~ 0
mA11
Text GLabel 8800 2550 0    39   BiDi ~ 0
mA12
Text GLabel 8800 2650 0    39   BiDi ~ 0
mA13
Text GLabel 9800 1350 2    39   BiDi ~ 0
mD0
Text GLabel 9800 1450 2    39   BiDi ~ 0
mD1
Text GLabel 9800 1550 2    39   BiDi ~ 0
mD2
Text GLabel 9800 1650 2    39   BiDi ~ 0
mD3
Text GLabel 9800 1750 2    39   BiDi ~ 0
mD4
Text GLabel 9800 1850 2    39   BiDi ~ 0
mD5
Text GLabel 9800 1950 2    39   BiDi ~ 0
mD6
Text GLabel 9800 2050 2    39   BiDi ~ 0
mD7
$Comp
L ISSI61WV5128BL U12
U 1 1 5C2DCEF9
P 7650 5150
F 0 "U12" H 7350 6200 50  0000 C CNN
F 1 "ISSI61WV5128BL" H 8000 4100 50  0000 C CNN
F 2 "RetroBitLab:SOP-32L-20.5x11.30-1.27mm" H 7650 5150 50  0001 C CIN
	1    7650 5150
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR32
U 1 1 5C2DCF05
P 7650 6250
F 0 "#PWR32" H 7650 6000 50  0001 C CNN
F 1 "GND" H 7650 6100 50  0000 C CNN
	1    7650 6250
	1    0    0    -1  
$EndComp
Text GLabel 7650 3900 1    39   Input ~ 0
VCC3V3
Text GLabel 8150 5550 3    39   BiDi ~ 0
~BSEL2
Text GLabel 8250 5800 3    39   BiDi ~ 0
mR/~W
Wire Wire Line
	8150 5350 8150 5550
Wire Wire Line
	8150 5200 8250 5200
Wire Wire Line
	8250 5200 8250 5800
Wire Wire Line
	8150 5100 8350 5100
Wire Wire Line
	8350 5100 8350 5550
Wire Wire Line
	7650 3900 7650 4050
$Comp
L C_Small C11
U 1 1 5C2DCF14
P 7850 4000
F 0 "C11" H 7860 4070 50  0000 L CNN
F 1 "100n" V 7950 3800 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 7850 4000 50  0001 C CNN
	1    7850 4000
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR34
U 1 1 5C2DCF1A
P 7950 4000
F 0 "#PWR34" H 7950 3750 50  0001 C CNN
F 1 "GND" H 7950 3850 50  0000 C CNN
	1    7950 4000
	0    -1   -1   0   
$EndComp
Text GLabel 7150 4250 0    39   BiDi ~ 0
mA0
Text GLabel 7150 4350 0    39   BiDi ~ 0
mA1
Text GLabel 7150 4450 0    39   BiDi ~ 0
mA2
Text GLabel 7150 4550 0    39   BiDi ~ 0
mA3
Text GLabel 7150 4650 0    39   BiDi ~ 0
mA4
Text GLabel 7150 4750 0    39   BiDi ~ 0
mA5
Text GLabel 7150 4850 0    39   BiDi ~ 0
mA6
Text GLabel 7150 4950 0    39   BiDi ~ 0
mA7
Text GLabel 7150 5050 0    39   BiDi ~ 0
mA8
Text GLabel 7150 5150 0    39   BiDi ~ 0
mA9
Text GLabel 7150 5250 0    39   BiDi ~ 0
mA10
Text GLabel 7150 5350 0    39   BiDi ~ 0
mA11
Text GLabel 7150 5450 0    39   BiDi ~ 0
mA12
Text GLabel 7150 5550 0    39   BiDi ~ 0
mA13
Text GLabel 8150 4250 2    39   BiDi ~ 0
mD0
Text GLabel 8150 4350 2    39   BiDi ~ 0
mD1
Text GLabel 8150 4450 2    39   BiDi ~ 0
mD2
Text GLabel 8150 4550 2    39   BiDi ~ 0
mD3
Text GLabel 8150 4650 2    39   BiDi ~ 0
mD4
Text GLabel 8150 4750 2    39   BiDi ~ 0
mD5
Text GLabel 8150 4850 2    39   BiDi ~ 0
mD6
Text GLabel 8150 4950 2    39   BiDi ~ 0
mD7
$Comp
L ISSI61WV5128BL U14
U 1 1 5C2DCF3B
P 9300 5150
F 0 "U14" H 9000 6200 50  0000 C CNN
F 1 "ISSI61WV5128BL" H 9650 4100 50  0000 C CNN
F 2 "RetroBitLab:SOP-32L-20.5x11.30-1.27mm" H 9300 5150 50  0001 C CIN
	1    9300 5150
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR36
U 1 1 5C2DCF47
P 9300 6250
F 0 "#PWR36" H 9300 6000 50  0001 C CNN
F 1 "GND" H 9300 6100 50  0000 C CNN
	1    9300 6250
	1    0    0    -1  
$EndComp
Text GLabel 9300 3900 1    39   Input ~ 0
VCC3V3
Text GLabel 9800 5550 3    39   BiDi ~ 0
~BSEL3
Text GLabel 9900 5800 3    39   BiDi ~ 0
mR/~W
Wire Wire Line
	9800 5350 9800 5550
Wire Wire Line
	9800 5200 9900 5200
Wire Wire Line
	9900 5200 9900 5800
Wire Wire Line
	9800 5100 10000 5100
Wire Wire Line
	10000 5100 10000 5550
Wire Wire Line
	9300 3900 9300 4050
$Comp
L C_Small C13
U 1 1 5C2DCF56
P 9500 4000
F 0 "C13" H 9510 4070 50  0000 L CNN
F 1 "100n" V 9600 3800 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 9500 4000 50  0001 C CNN
	1    9500 4000
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR38
U 1 1 5C2DCF5C
P 9600 4000
F 0 "#PWR38" H 9600 3750 50  0001 C CNN
F 1 "GND" H 9600 3850 50  0000 C CNN
	1    9600 4000
	0    -1   -1   0   
$EndComp
Text GLabel 8800 4250 0    39   BiDi ~ 0
mA0
Text GLabel 8800 4350 0    39   BiDi ~ 0
mA1
Text GLabel 8800 4450 0    39   BiDi ~ 0
mA2
Text GLabel 8800 4550 0    39   BiDi ~ 0
mA3
Text GLabel 8800 4650 0    39   BiDi ~ 0
mA4
Text GLabel 8800 4750 0    39   BiDi ~ 0
mA5
Text GLabel 8800 4850 0    39   BiDi ~ 0
mA6
Text GLabel 8800 4950 0    39   BiDi ~ 0
mA7
Text GLabel 8800 5050 0    39   BiDi ~ 0
mA8
Text GLabel 8800 5150 0    39   BiDi ~ 0
mA9
Text GLabel 8800 5250 0    39   BiDi ~ 0
mA10
Text GLabel 8800 5350 0    39   BiDi ~ 0
mA11
Text GLabel 8800 5450 0    39   BiDi ~ 0
mA12
Text GLabel 8800 5550 0    39   BiDi ~ 0
mA13
Text GLabel 9800 4250 2    39   BiDi ~ 0
mD0
Text GLabel 9800 4350 2    39   BiDi ~ 0
mD1
Text GLabel 9800 4450 2    39   BiDi ~ 0
mD2
Text GLabel 9800 4550 2    39   BiDi ~ 0
mD3
Text GLabel 9800 4650 2    39   BiDi ~ 0
mD4
Text GLabel 9800 4750 2    39   BiDi ~ 0
mD5
Text GLabel 9800 4850 2    39   BiDi ~ 0
mD6
Text GLabel 9800 4950 2    39   BiDi ~ 0
mD7
Text GLabel 2100 5600 2    39   BiDi ~ 0
~D1XX
Text GLabel 2100 5700 2    39   BiDi ~ 0
~HALT
Text GLabel 2100 5800 2    39   BiDi ~ 0
~MPD
Text GLabel 2100 5900 2    39   BiDi ~ 0
~IRQ
Text GLabel 2100 6000 2    39   BiDi ~ 0
~RST
Text GLabel 2100 6100 2    39   BiDi ~ 0
~REF
Text GLabel 2100 6200 2    39   BiDi ~ 0
~CCTL
Text GLabel 4550 5500 2    39   BiDi ~ 0
B02/PHI2
Text GLabel 4550 5600 2    39   BiDi ~ 0
R/~W
Text GLabel 1200 5500 0    39   BiDi ~ 0
~mEXSEL
Text GLabel 3650 5500 0    39   BiDi ~ 0
mB02/PHI2
Text GLabel 3650 5600 0    39   BiDi ~ 0
mR/~W
Text GLabel 1200 5600 0    39   BiDi ~ 0
~mD1XX
Text GLabel 1200 5700 0    39   BiDi ~ 0
~mHALT
Text GLabel 1200 5800 0    39   BiDi ~ 0
~mMPD
Text GLabel 1200 5900 0    39   BiDi ~ 0
~mIRQ
Text GLabel 1200 6000 0    39   BiDi ~ 0
~mRST
Text GLabel 1200 6100 0    39   BiDi ~ 0
~mREF
Text GLabel 1200 6200 0    39   BiDi ~ 0
~mCCTL
NoConn ~ 3650 5700
NoConn ~ 3650 5800
NoConn ~ 3650 5900
NoConn ~ 3650 6000
NoConn ~ 3650 6100
NoConn ~ 3650 6200
NoConn ~ 4550 6200
NoConn ~ 4550 6100
NoConn ~ 4550 6000
NoConn ~ 4550 5900
NoConn ~ 4550 5800
NoConn ~ 4550 5700
Wire Notes Line
	600  4850 5200 4850
Wire Notes Line
	5200 4850 5200 7100
Wire Notes Line
	5200 7100 600  7100
Wire Notes Line
	600  7100 600  4850
Text Notes 750  6950 0    59   ~ 12
SIGNAL SECTION
Wire Notes Line
	6300 600  6300 6450
Wire Notes Line
	6300 6450 11050 6450
Wire Notes Line
	11050 6450 11050 600 
Wire Notes Line
	11050 600  6300 600 
Text Notes 6450 800  0    59   ~ 12
STATIC RAM
Text GLabel 5000 4100 2    39   BiDi ~ 8
~ADDRSEL16K
$Comp
L 74LS32 U9
U 1 1 5C2DFACA
P 4700 4100
F 0 "U9" H 4700 4150 50  0000 C CNN
F 1 "74LS32" H 4700 4050 50  0000 C CNN
F 2 "Housings_SSOP:SSOP-14_5.3x6.2mm_Pitch0.65mm" H 4700 4100 50  0001 C CNN
	1    4700 4100
	1    0    0    -1  
$EndComp
$Comp
L 74LS32 U9
U 2 1 5C2DFB95
P 5450 3650
F 0 "U9" H 5450 3700 50  0000 C CNN
F 1 "74LS32" H 5450 3600 50  0000 C CNN
F 2 "Housings_SSOP:SSOP-14_5.3x6.2mm_Pitch0.65mm" H 5450 3650 50  0001 C CNN
	2    5450 3650
	1    0    0    -1  
$EndComp
$Comp
L 74LS32 U9
U 3 1 5C2DFBE8
P 4800 3650
F 0 "U9" H 4800 3700 50  0000 C CNN
F 1 "74LS32" H 4800 3600 50  0000 C CNN
F 2 "Housings_SSOP:SSOP-14_5.3x6.2mm_Pitch0.65mm" H 4800 3650 50  0001 C CNN
	3    4800 3650
	1    0    0    -1  
$EndComp
$Comp
L 74LS32 U9
U 4 1 5C2DFC39
P 4150 3650
F 0 "U9" H 4150 3700 50  0000 C CNN
F 1 "74LS32" H 4150 3600 50  0000 C CNN
F 2 "Housings_SSOP:SSOP-14_5.3x6.2mm_Pitch0.65mm" H 4150 3650 50  0001 C CNN
	4    4150 3650
	1    0    0    -1  
$EndComp
NoConn ~ 5750 3650
NoConn ~ 5100 3650
NoConn ~ 5150 3550
NoConn ~ 5150 3750
NoConn ~ 4500 3750
NoConn ~ 4500 3550
NoConn ~ 3850 3550
NoConn ~ 3850 3750
NoConn ~ 4450 3650
Text GLabel 4400 4200 0    39   BiDi ~ 0
mA15
Text GLabel 3800 4000 0    39   BiDi ~ 0
mA14
$Comp
L 74HC04 U7
U 1 1 5C2DFE46
P 4100 4000
F 0 "U7" H 4100 4050 50  0000 C CNN
F 1 "74HC04" H 4100 3950 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 4100 4000 50  0001 C CNN
	1    4100 4000
	1    0    0    -1  
$EndComp
$Comp
L 74HC04 U7
U 2 1 5C2DFEE1
P 4600 4500
F 0 "U7" H 4600 4550 50  0000 C CNN
F 1 "74HC04" H 4600 4450 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 4600 4500 50  0001 C CNN
	2    4600 4500
	1    0    0    -1  
$EndComp
$Comp
L 74HC04 U7
U 3 1 5C2DFF28
P 5850 4800
F 0 "U7" H 5850 4850 50  0000 C CNN
F 1 "74HC04" H 5850 4750 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 5850 4800 50  0001 C CNN
	3    5850 4800
	0    1    1    0   
$EndComp
$Comp
L 74HC04 U7
U 4 1 5C2E0001
P 5850 5550
F 0 "U7" H 5850 5600 50  0000 C CNN
F 1 "74HC04" H 5850 5500 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 5850 5550 50  0001 C CNN
	4    5850 5550
	0    1    1    0   
$EndComp
NoConn ~ 5850 4500
NoConn ~ 5850 5100
NoConn ~ 5850 5250
NoConn ~ 5850 5850
$Comp
L 74HC04 U7
U 5 1 5C2E0114
P 5850 6300
F 0 "U7" H 5850 6350 50  0000 C CNN
F 1 "74HC04" H 5850 6250 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 5850 6300 50  0001 C CNN
	5    5850 6300
	0    1    1    0   
$EndComp
$Comp
L 74HC04 U7
U 6 1 5C2E0161
P 5850 7050
F 0 "U7" H 5850 7100 50  0000 C CNN
F 1 "74HC04" H 5850 7000 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 5850 7050 50  0001 C CNN
	6    5850 7050
	0    1    1    0   
$EndComp
NoConn ~ 5850 6000
NoConn ~ 5850 6600
NoConn ~ 5850 6750
NoConn ~ 5850 7350
$Comp
L 74HC04 U7
U 7 1 5C2E0C9C
P 5750 1400
F 0 "U7" H 5750 1450 50  0000 C CNN
F 1 "74HC04" H 5750 1350 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 5750 1400 50  0001 C CNN
	7    5750 1400
	1    0    0    -1  
$EndComp
$Comp
L 74LS32 U9
U 5 1 5C2E0D29
P 5750 2400
F 0 "U9" H 5750 2450 50  0000 C CNN
F 1 "74LS32" H 5750 2350 50  0000 C CNN
F 2 "Housings_SSOP:SSOP-14_5.3x6.2mm_Pitch0.65mm" H 5750 2400 50  0001 C CNN
	5    5750 2400
	-1   0    0    1   
$EndComp
Text GLabel 5750 2900 3    39   BiDi ~ 0
VCC3V3
Text GLabel 5750 900  1    39   BiDi ~ 0
VCC3V3
Text GLabel 2100 5500 2    39   BiDi ~ 0
~EXSEL
Wire Wire Line
	7750 4000 7650 4000
Connection ~ 7650 4000
Wire Wire Line
	9400 4000 9300 4000
Connection ~ 9300 4000
Wire Wire Line
	9350 1100 9300 1100
Connection ~ 9300 1100
Wire Wire Line
	7700 1100 7650 1100
Connection ~ 7650 1100
$Comp
L GND #PWR30
U 1 1 5C2E9245
P 5650 1900
F 0 "#PWR30" H 5650 1650 50  0001 C CNN
F 1 "GND" H 5650 1750 50  0000 C CNN
	1    5650 1900
	0    1    1    0   
$EndComp
Wire Wire Line
	5650 1900 5750 1900
Connection ~ 5750 1900
Text GLabel 7150 2750 0    39   BiDi ~ 0
PB0
Text GLabel 7150 2850 0    39   BiDi ~ 0
PB1
Text GLabel 7150 2950 0    39   BiDi ~ 0
PB2
Text GLabel 7150 3050 0    39   BiDi ~ 0
PB3
Text GLabel 7150 3150 0    39   BiDi ~ 0
PB4
Text GLabel 8800 2750 0    39   BiDi ~ 0
PB0
Text GLabel 8800 2850 0    39   BiDi ~ 0
PB1
Text GLabel 8800 2950 0    39   BiDi ~ 0
PB2
Text GLabel 8800 3050 0    39   BiDi ~ 0
PB3
Text GLabel 8800 3150 0    39   BiDi ~ 0
PB4
Text GLabel 8800 5650 0    39   BiDi ~ 0
PB0
Text GLabel 7150 5650 0    39   BiDi ~ 0
PB0
Text GLabel 8800 5750 0    39   BiDi ~ 0
PB1
Text GLabel 7150 5750 0    39   BiDi ~ 0
PB1
Text GLabel 7150 5850 0    39   BiDi ~ 0
PB2
Text GLabel 8800 5850 0    39   BiDi ~ 0
PB2
Text GLabel 8800 5950 0    39   BiDi ~ 0
PB3
Text GLabel 8800 6050 0    39   BiDi ~ 0
PB4
Text GLabel 7150 5950 0    39   BiDi ~ 0
PB3
Text GLabel 7150 6050 0    39   BiDi ~ 0
PB4
Text GLabel 4300 4500 0    39   BiDi ~ 0
mR/~W
Text GLabel 4900 4500 2    39   BiDi ~ 0
~mOE
Text GLabel 8350 2650 3    39   BiDi ~ 0
~mOE
Text GLabel 10000 2650 3    39   BiDi ~ 0
~mOE
Text GLabel 10000 5550 3    39   BiDi ~ 0
~mOE
Text GLabel 8350 5550 3    39   BiDi ~ 0
~mOE
$EndSCHEMATC
