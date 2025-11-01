EESchema Schematic File Version 4
LIBS:atari23MTS_Upgrade-cache
EELAYER 26 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 2 5
Title "STATIC RAM 1 MByte  (512K x 8 x 2)"
Date "2019-04-06"
Rev ""
Comp "RetroBit Lab"
Comment1 "BUS ADAPTERS AND MEMORY LAYOUT"
Comment2 "Level Shifters and Memory SRAM Connections"
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L RetroBitLab:ISSI61WV5128BL U7
U 1 1 5C2B9006
P 7500 2250
F 0 "U7" H 7200 3300 50  0000 C CNN
F 1 "ISSI61WV5128BL" H 7850 1200 50  0000 C CNN
F 2 "RetroBitLab:SOP-32L-20.5x11.30-1.27mm" H 7500 2250 50  0001 C CIN
F 3 "" H 7500 2250 60  0001 C CNN
	1    7500 2250
	1    0    0    -1  
$EndComp
$Comp
L power1:GND #PWR028
U 1 1 5C2BB99F
P 7500 3350
F 0 "#PWR028" H 7500 3100 50  0001 C CNN
F 1 "GND" H 7500 3200 50  0000 C CNN
F 2 "" H 7500 3350 60  0001 C CNN
F 3 "" H 7500 3350 60  0001 C CNN
	1    7500 3350
	1    0    0    -1  
$EndComp
Text GLabel 7500 1000 1    39   Input ~ 0
VCC3V3
Text GLabel 8350 2900 3    39   BiDi ~ 0
mR/~W
Wire Wire Line
	8000 2300 8350 2300
Wire Wire Line
	8350 2300 8350 2900
Wire Wire Line
	8000 2200 8450 2200
Wire Wire Line
	8450 2200 8450 2650
Wire Wire Line
	7500 1000 7500 1150
$Comp
L Device1:C_Small C4
U 1 1 5C2BF542
P 7650 1100
F 0 "C4" H 7660 1170 50  0000 L CNN
F 1 "100n" V 7750 900 50  0000 L CNN
F 2 "Capacitor_SMD:C_1206_3216Metric_Pad1.42x1.75mm_HandSolder" H 7650 1100 50  0001 C CNN
F 3 "" H 7650 1100 60  0001 C CNN
	1    7650 1100
	0    -1   -1   0   
$EndComp
$Comp
L power1:GND #PWR029
U 1 1 5C2BF58F
P 7750 1100
F 0 "#PWR029" H 7750 850 50  0001 C CNN
F 1 "GND" H 7750 950 50  0000 C CNN
F 2 "" H 7750 1100 60  0001 C CNN
F 3 "" H 7750 1100 60  0001 C CNN
	1    7750 1100
	0    -1   -1   0   
$EndComp
$Comp
L RetroBitLab:TXB0108-PW U2
U 1 1 5C2BF846
P 1350 1650
F 0 "U2" H 1150 2400 60  0000 L CNN
F 1 "TXB0108-PW" H 1150 900 60  0000 L CNN
F 2 "Package_SO:SSOP-20_4.4x6.5mm_P0.65mm" H 1150 1600 60  0001 C CNN
F 3 "" H 1350 1650 60  0001 C CNN
	1    1350 1650
	1    0    0    -1  
$EndComp
$Comp
L RetroBitLab:TXB0108-PW U3
U 1 1 5C2BF9CC
P 1650 4200
F 0 "U3" H 1450 4950 60  0000 L CNN
F 1 "TXB0108-PW" H 1450 3450 60  0000 L CNN
F 2 "Package_SO:SSOP-20_4.4x6.5mm_P0.65mm" H 1450 4150 60  0001 C CNN
F 3 "" H 1650 4200 60  0001 C CNN
	1    1650 4200
	1    0    0    -1  
$EndComp
$Comp
L RetroBitLab:TXB0108-PW U5
U 1 1 5C2BFA07
P 4100 4200
F 0 "U5" H 3900 4950 60  0000 L CNN
F 1 "TXB0108-PW" H 3900 3450 60  0000 L CNN
F 2 "Package_SO:SSOP-20_4.4x6.5mm_P0.65mm" H 3900 4150 60  0001 C CNN
F 3 "" H 4100 4200 60  0001 C CNN
	1    4100 4200
	1    0    0    -1  
$EndComp
$Comp
L RetroBitLab:TXB0108-PW U6
U 1 1 5C2BFAD5
P 4600 1600
F 0 "U6" H 4400 2350 60  0000 L CNN
F 1 "TXB0108-PW" H 4400 850 60  0000 L CNN
F 2 "Package_SO:SSOP-20_4.4x6.5mm_P0.65mm" H 4400 1550 60  0001 C CNN
F 3 "" H 4600 1600 60  0001 C CNN
	1    4600 1600
	1    0    0    -1  
$EndComp
Text GLabel 1850 1350 2    39   BiDi ~ 0
A0
Text GLabel 1850 1450 2    39   BiDi ~ 0
A1
Text GLabel 1850 1550 2    39   BiDi ~ 0
A2
Text GLabel 1850 1650 2    39   BiDi ~ 0
A3
Text GLabel 1850 1750 2    39   BiDi ~ 0
A4
Text GLabel 1850 1850 2    39   BiDi ~ 0
A5
Text GLabel 1850 1950 2    39   BiDi ~ 0
A6
Text GLabel 1850 2050 2    39   BiDi ~ 0
A7
Text GLabel 1850 1050 2    39   BiDi ~ 0
VCC5V
Text GLabel 2150 3600 2    39   BiDi ~ 0
VCC5V
Text GLabel 4600 3600 2    39   BiDi ~ 0
VCC5V
Text GLabel 5100 1000 2    39   BiDi ~ 0
VCC5V
$Comp
L power1:GND #PWR030
U 1 1 5C2D99D7
P 950 2250
F 0 "#PWR030" H 950 2000 50  0001 C CNN
F 1 "GND" H 950 2100 50  0000 C CNN
F 2 "" H 950 2250 60  0001 C CNN
F 3 "" H 950 2250 60  0001 C CNN
	1    950  2250
	1    0    0    -1  
$EndComp
$Comp
L power1:GND #PWR031
U 1 1 5C2D9EC5
P 1250 4800
F 0 "#PWR031" H 1250 4550 50  0001 C CNN
F 1 "GND" H 1250 4650 50  0000 C CNN
F 2 "" H 1250 4800 60  0001 C CNN
F 3 "" H 1250 4800 60  0001 C CNN
	1    1250 4800
	1    0    0    -1  
$EndComp
$Comp
L power1:GND #PWR032
U 1 1 5C2D9EE5
P 3700 4800
F 0 "#PWR032" H 3700 4550 50  0001 C CNN
F 1 "GND" H 3700 4650 50  0000 C CNN
F 2 "" H 3700 4800 60  0001 C CNN
F 3 "" H 3700 4800 60  0001 C CNN
	1    3700 4800
	1    0    0    -1  
$EndComp
$Comp
L power1:GND #PWR033
U 1 1 5C2D9F05
P 4200 2200
F 0 "#PWR033" H 4200 1950 50  0001 C CNN
F 1 "GND" H 4200 2050 50  0000 C CNN
F 2 "" H 4200 2200 60  0001 C CNN
F 3 "" H 4200 2200 60  0001 C CNN
	1    4200 2200
	1    0    0    -1  
$EndComp
Text GLabel 950  1050 0    39   BiDi ~ 0
VCC3V3
Text GLabel 1250 3600 0    39   BiDi ~ 0
VCC3V3
Text GLabel 3700 3600 0    39   BiDi ~ 0
VCC3V3
Text GLabel 4200 1000 0    39   BiDi ~ 0
VCC3V3
Text GLabel 950  1250 0    39   BiDi ~ 0
VCC3V3
Text GLabel 1250 3800 0    39   BiDi ~ 0
VCC3V3
Text GLabel 3700 3800 0    39   BiDi ~ 0
VCC3V3
Text GLabel 4200 1200 0    39   BiDi ~ 0
VCC3V3
Text GLabel 950  1350 0    39   BiDi ~ 0
mA0
Text GLabel 950  1450 0    39   BiDi ~ 0
mA1
Text GLabel 950  1550 0    39   BiDi ~ 0
mA2
Text GLabel 950  1650 0    39   BiDi ~ 0
mA3
Text GLabel 950  1750 0    39   BiDi ~ 0
mA4
Text GLabel 950  1850 0    39   BiDi ~ 0
mA5
Text GLabel 950  1950 0    39   BiDi ~ 0
mA6
Text GLabel 950  2050 0    39   BiDi ~ 0
mA7
Wire Notes Line
	600  650  3050 650 
Text Notes 1750 2650 0    59   ~ 12
ADDRESS BUS SECTION
Text GLabel 7000 1350 0    39   BiDi ~ 0
mA0
Text GLabel 7000 1450 0    39   BiDi ~ 0
mA1
Text GLabel 7000 1550 0    39   BiDi ~ 0
mA2
Text GLabel 7000 1650 0    39   BiDi ~ 0
mA3
Text GLabel 7000 1750 0    39   BiDi ~ 0
mA4
Text GLabel 7000 1850 0    39   BiDi ~ 0
mA5
Text GLabel 7000 1950 0    39   BiDi ~ 0
mA6
Text GLabel 7000 2050 0    39   BiDi ~ 0
mA7
Text GLabel 5100 1300 2    39   BiDi ~ 0
D0
Text GLabel 5100 1400 2    39   BiDi ~ 0
D1
Text GLabel 5100 1500 2    39   BiDi ~ 0
D2
Text GLabel 5100 1600 2    39   BiDi ~ 0
D3
Text GLabel 5100 1700 2    39   BiDi ~ 0
D4
Text GLabel 5100 1800 2    39   BiDi ~ 0
D5
Text GLabel 5100 1900 2    39   BiDi ~ 0
D6
Text GLabel 5100 2000 2    39   BiDi ~ 0
D7
Text GLabel 4200 2000 0    39   BiDi ~ 0
mD7
Text GLabel 4200 1900 0    39   BiDi ~ 0
mD6
Text GLabel 4200 1800 0    39   BiDi ~ 0
mD5
Text GLabel 4200 1700 0    39   BiDi ~ 0
mD4
Text GLabel 4200 1600 0    39   BiDi ~ 0
mD3
Text GLabel 4200 1500 0    39   BiDi ~ 0
mD2
Text GLabel 4200 1400 0    39   BiDi ~ 0
mD1
Text GLabel 4200 1300 0    39   BiDi ~ 0
mD0
Wire Notes Line
	3150 650  5450 650 
Text Notes 4200 2650 0    59   ~ 12
DATA BUS SECTION
Text GLabel 8000 1350 2    39   BiDi ~ 0
mD0
Text GLabel 8000 1450 2    39   BiDi ~ 0
mD1
Text GLabel 8000 1550 2    39   BiDi ~ 0
mD2
Text GLabel 8000 1650 2    39   BiDi ~ 0
mD3
Text GLabel 8000 1750 2    39   BiDi ~ 0
mD4
Text GLabel 8000 1850 2    39   BiDi ~ 0
mD5
Text GLabel 8000 1950 2    39   BiDi ~ 0
mD6
Text GLabel 8000 2050 2    39   BiDi ~ 0
mD7
Text GLabel 2150 4000 2    39   BiDi ~ 0
~D1XX
Text GLabel 2150 4100 2    39   BiDi ~ 0
~HALT
Text GLabel 2150 4200 2    39   BiDi ~ 0
~MPD
Text GLabel 2150 4300 2    39   BiDi ~ 0
~IRQ
Text GLabel 2150 4400 2    39   BiDi ~ 0
~RST
Text GLabel 2150 4500 2    39   BiDi ~ 0
~REF
Text GLabel 2150 4600 2    39   BiDi ~ 0
~CCTL
Text GLabel 4600 3900 2    39   BiDi ~ 0
B02/PHI2
Text GLabel 4600 4000 2    39   BiDi ~ 0
R/~W
Text GLabel 1250 3900 0    39   BiDi ~ 0
~mEXSEL
Text GLabel 3700 3900 0    39   BiDi ~ 0
mB02/PHI2
Text GLabel 3700 4000 0    39   BiDi ~ 0
mR/~W
Text GLabel 1250 4000 0    39   BiDi ~ 0
~mD1XX
Text GLabel 1250 4100 0    39   BiDi ~ 0
~mHALT
Text GLabel 1250 4200 0    39   BiDi ~ 0
~mMPD
Text GLabel 1250 4300 0    39   BiDi ~ 0
~mIRQ
Text GLabel 1250 4400 0    39   BiDi ~ 0
~mRST
Text GLabel 1250 4500 0    39   BiDi ~ 0
~mREF
Text GLabel 1250 4600 0    39   BiDi ~ 0
~mCCTL
Wire Notes Line
	650  3250 5250 3250
Wire Notes Line
	5250 3250 5250 5500
Wire Notes Line
	5250 5500 650  5500
Wire Notes Line
	650  5500 650  3250
Text Notes 800  5350 0    59   ~ 12
SIGNAL SECTION
Wire Notes Line
	6000 600  11050 600 
Text Notes 6450 800  0    59   ~ 12
1024K STATIC RAM
Text GLabel 2150 3900 2    39   BiDi ~ 0
~EXSEL
Wire Wire Line
	7550 1100 7500 1100
Connection ~ 7500 1100
Text GLabel 4600 4100 2    39   BiDi ~ 0
~S4
Text GLabel 4600 4200 2    39   BiDi ~ 0
RD4
Text GLabel 4600 4300 2    39   BiDi ~ 0
~S5
Text GLabel 4600 4400 2    39   BiDi ~ 0
RD5
Text GLabel 3700 4400 0    39   BiDi ~ 0
mRD5
Text GLabel 3700 4300 0    39   BiDi ~ 0
~mS5
Text GLabel 3700 4200 0    39   BiDi ~ 0
mRD4
Text GLabel 3700 4100 0    39   BiDi ~ 0
~mS4
$Comp
L RetroBitLab:TXB0108-PW U4
U 1 1 5C374049
P 2900 1600
F 0 "U4" H 2700 2350 60  0000 L CNN
F 1 "TXB0108-PW" H 2700 850 60  0000 L CNN
F 2 "Package_SO:SSOP-20_4.4x6.5mm_P0.65mm" H 2700 1550 60  0001 C CNN
F 3 "" H 2900 1600 60  0001 C CNN
	1    2900 1600
	1    0    0    -1  
$EndComp
Text GLabel 3400 1000 2    39   BiDi ~ 0
VCC5V
$Comp
L power1:GND #PWR034
U 1 1 5C374058
P 2500 2200
F 0 "#PWR034" H 2500 1950 50  0001 C CNN
F 1 "GND" H 2500 2050 50  0000 C CNN
F 2 "" H 2500 2200 60  0001 C CNN
F 3 "" H 2500 2200 60  0001 C CNN
	1    2500 2200
	1    0    0    -1  
$EndComp
Text GLabel 2500 1000 0    39   BiDi ~ 0
VCC3V3
Text GLabel 2500 1200 0    39   BiDi ~ 0
VCC3V3
Text GLabel 2500 1300 0    39   BiDi ~ 0
mA8
Text GLabel 2500 1400 0    39   BiDi ~ 0
mA9
Text GLabel 2500 1500 0    39   BiDi ~ 0
mA10
Text GLabel 2500 1600 0    39   BiDi ~ 0
mA11
Text GLabel 2500 1700 0    39   BiDi ~ 0
mA12
Text GLabel 2500 1800 0    39   BiDi ~ 0
mA13
Text GLabel 2500 1900 0    39   BiDi ~ 0
mA14
Text GLabel 2500 2000 0    39   BiDi ~ 0
mA15
Text GLabel 3400 2000 2    39   BiDi ~ 0
A15
Text GLabel 3400 1900 2    39   BiDi ~ 0
A14
Text GLabel 3400 1800 2    39   BiDi ~ 0
A13
Text GLabel 3400 1700 2    39   BiDi ~ 0
A12
Text GLabel 3400 1600 2    39   BiDi ~ 0
A11
Text GLabel 3400 1500 2    39   BiDi ~ 0
A10
Text GLabel 3400 1400 2    39   BiDi ~ 0
A9
Text GLabel 3400 1300 2    39   BiDi ~ 0
A8
Wire Notes Line
	3000 650  3200 650 
Wire Notes Line
	600  2950 5450 2950
Wire Notes Line
	600  2950 600  650 
Wire Notes Line
	5450 2950 5450 650 
Text GLabel 7000 2150 0    39   BiDi ~ 0
mA8
Text GLabel 7000 2250 0    39   BiDi ~ 0
mA9
Text GLabel 7000 2350 0    39   BiDi ~ 0
mA10
Text GLabel 7000 2450 0    39   BiDi ~ 0
mA11
Text GLabel 7000 2550 0    39   BiDi ~ 0
mA12
Text GLabel 7000 2650 0    39   BiDi ~ 0
mA13
Text GLabel 6450 2750 0    39   BiDi ~ 0
mB0
Wire Notes Line
	11050 600  11050 5350
Text GLabel 6450 2850 0    39   BiDi ~ 0
mB1
Text GLabel 6450 2950 0    39   BiDi ~ 0
mB2
Text GLabel 6450 3050 0    39   BiDi ~ 0
mB3
Text GLabel 6450 3150 0    39   BiDi ~ 0
mB4
Wire Notes Line
	11050 5350 6300 5350
Wire Wire Line
	8000 2450 8200 2450
Wire Wire Line
	8200 2450 8200 3500
Text GLabel 8200 3500 3    39   BiDi ~ 0
mB5
Text Notes 7050 4500 0    79   ~ 16
EXTERNAL RAM ACCESS WILL ASSERT THE EXTSEL SIGNAL (code)
Text GLabel 8450 2650 3    39   BiDi ~ 0
mW/~R
$Comp
L RetroBitLab:ISSI61WV5128BL U8
U 1 1 5C5E8B61
P 9700 2300
F 0 "U8" H 9400 3350 50  0000 C CNN
F 1 "ISSI61WV5128BL" H 10050 1250 50  0000 C CNN
F 2 "RetroBitLab:SOP-32L-20.5x11.30-1.27mm" H 9700 2300 50  0001 C CIN
F 3 "" H 9700 2300 60  0001 C CNN
	1    9700 2300
	1    0    0    -1  
$EndComp
$Comp
L power1:GND #PWR035
U 1 1 5C5E8B67
P 9700 3400
F 0 "#PWR035" H 9700 3150 50  0001 C CNN
F 1 "GND" H 9700 3250 50  0000 C CNN
F 2 "" H 9700 3400 60  0001 C CNN
F 3 "" H 9700 3400 60  0001 C CNN
	1    9700 3400
	1    0    0    -1  
$EndComp
Text GLabel 9700 1050 1    39   Input ~ 0
VCC3V3
Text GLabel 10550 2950 3    39   BiDi ~ 0
mR/~W
Wire Wire Line
	10200 2350 10550 2350
Wire Wire Line
	10550 2350 10550 2950
Wire Wire Line
	10200 2250 10650 2250
Wire Wire Line
	10650 2250 10650 2700
Wire Wire Line
	9700 1050 9700 1200
$Comp
L Device1:C_Small C5
U 1 1 5C5E8B74
P 9850 1150
F 0 "C5" H 9860 1220 50  0000 L CNN
F 1 "100n" V 9950 950 50  0000 L CNN
F 2 "Capacitor_SMD:C_1206_3216Metric_Pad1.42x1.75mm_HandSolder" H 9850 1150 50  0001 C CNN
F 3 "" H 9850 1150 60  0001 C CNN
	1    9850 1150
	0    -1   -1   0   
$EndComp
$Comp
L power1:GND #PWR036
U 1 1 5C5E8B7A
P 9950 1150
F 0 "#PWR036" H 9950 900 50  0001 C CNN
F 1 "GND" H 9950 1000 50  0000 C CNN
F 2 "" H 9950 1150 60  0001 C CNN
F 3 "" H 9950 1150 60  0001 C CNN
	1    9950 1150
	0    -1   -1   0   
$EndComp
Text GLabel 9200 1400 0    39   BiDi ~ 0
mA0
Text GLabel 9200 1500 0    39   BiDi ~ 0
mA1
Text GLabel 9200 1600 0    39   BiDi ~ 0
mA2
Text GLabel 9200 1700 0    39   BiDi ~ 0
mA3
Text GLabel 9200 1800 0    39   BiDi ~ 0
mA4
Text GLabel 9200 1900 0    39   BiDi ~ 0
mA5
Text GLabel 9200 2000 0    39   BiDi ~ 0
mA6
Text GLabel 9200 2100 0    39   BiDi ~ 0
mA7
Text GLabel 10200 1400 2    39   BiDi ~ 0
mD0
Text GLabel 10200 1500 2    39   BiDi ~ 0
mD1
Text GLabel 10200 1600 2    39   BiDi ~ 0
mD2
Text GLabel 10200 1700 2    39   BiDi ~ 0
mD3
Text GLabel 10200 1800 2    39   BiDi ~ 0
mD4
Text GLabel 10200 1900 2    39   BiDi ~ 0
mD5
Text GLabel 10200 2000 2    39   BiDi ~ 0
mD6
Text GLabel 10200 2100 2    39   BiDi ~ 0
mD7
Wire Wire Line
	9750 1150 9700 1150
Connection ~ 9700 1150
Text GLabel 9200 2200 0    39   BiDi ~ 0
mA8
Text GLabel 9200 2300 0    39   BiDi ~ 0
mA9
Text GLabel 9200 2400 0    39   BiDi ~ 0
mA10
Text GLabel 9200 2500 0    39   BiDi ~ 0
mA11
Text GLabel 9200 2600 0    39   BiDi ~ 0
mA12
Text GLabel 9200 2700 0    39   BiDi ~ 0
mA13
Wire Wire Line
	10200 2500 10400 2500
Wire Wire Line
	10400 2500 10400 3550
Text GLabel 10400 3550 3    39   BiDi ~ 0
~mB5
Text GLabel 10650 2700 3    39   BiDi ~ 0
mW/~R
Wire Wire Line
	6450 2750 7000 2750
Wire Wire Line
	6450 2850 7000 2850
Wire Wire Line
	6450 2950 7000 2950
Wire Wire Line
	6450 3050 7000 3050
Wire Wire Line
	6450 3150 7000 3150
Wire Wire Line
	9200 2800 8650 2800
Wire Wire Line
	8650 2800 8650 3850
Wire Wire Line
	8650 3850 6950 3850
Wire Wire Line
	6950 3850 6950 2750
Connection ~ 6950 2750
Wire Wire Line
	9200 2900 8750 2900
Wire Wire Line
	8750 2900 8750 3950
Wire Wire Line
	8750 3950 6850 3950
Wire Wire Line
	6850 3950 6850 2850
Connection ~ 6850 2850
Wire Wire Line
	9200 3000 8850 3000
Wire Wire Line
	8850 3000 8850 4050
Wire Wire Line
	8850 4050 6750 4050
Wire Wire Line
	6750 4050 6750 2950
Connection ~ 6750 2950
Wire Wire Line
	9200 3100 8950 3100
Wire Wire Line
	8950 3100 8950 4150
Wire Wire Line
	8950 4150 6650 4150
Wire Wire Line
	6650 4150 6650 3050
Connection ~ 6650 3050
Wire Wire Line
	9200 3200 9050 3200
Wire Wire Line
	9050 3200 9050 4250
Wire Wire Line
	9050 4250 6550 4250
Wire Wire Line
	6550 4250 6550 3150
Connection ~ 6550 3150
Wire Notes Line
	6000 600  6000 5350
Wire Notes Line
	6000 5350 6350 5350
NoConn ~ 4600 4500
NoConn ~ 4600 4600
NoConn ~ 3700 4600
NoConn ~ 3700 4500
$EndSCHEMATC
