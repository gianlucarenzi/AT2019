EESchema Schematic File Version 4
LIBS:atari23MTS_Upgrade-cache
EELAYER 26 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 3 5
Title "ATARI EXPANSION BUS PASS THRU & DXXX Address Select"
Date "2019-04-06"
Rev ""
Comp "RetroBit Lab"
Comment1 "PBI Device Selection and Hardware Activity for Accessing D8XX-DFXX addresses"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L RetroBitLab:ATARICARTRIDGE CART2
U 1 1 5C2FF23F
P 1850 2200
F 0 "CART2" H 2300 3050 50  0000 C CNN
F 1 "ATARICARTRIDGE" H 1900 2300 50  0000 C CNN
F 2 "RetroBitLab:TE_5530843-2_15X2_CART_EDGE_CONNECTOR" H 1900 1200 50  0000 C CNN
F 3 "" H 1850 2200 60  0001 C CNN
	1    1850 2200
	1    0    0    -1  
$EndComp
$Comp
L RetroBitLab:ECIBUS ECI2
U 1 1 5C2FF2C0
P 4950 2250
F 0 "ECI2" H 5400 2700 50  0000 C CNN
F 1 "ECIBUS" H 5000 1950 50  0000 C CNN
F 2 "RetroBitLab:TE_5530843-2_7X2_EDGE_CONNECTOR" H 4950 1650 50  0000 C CNN
F 3 "" H 4950 2250 60  0001 C CNN
	1    4950 2250
	1    0    0    -1  
$EndComp
Text GLabel 950  1550 0    39   BiDi ~ 0
~S4
Text GLabel 950  1650 0    39   BiDi ~ 0
A3
Text GLabel 950  1750 0    39   BiDi ~ 0
A2
Text GLabel 950  1850 0    39   BiDi ~ 0
A1
Text GLabel 950  1950 0    39   BiDi ~ 0
A0
Text GLabel 950  2050 0    39   BiDi ~ 0
D4
Text GLabel 950  2150 0    39   BiDi ~ 0
D5
Text GLabel 950  2250 0    39   BiDi ~ 0
D2
Text GLabel 950  2350 0    39   BiDi ~ 0
D1
Text GLabel 950  2450 0    39   BiDi ~ 0
D0
Text GLabel 950  2550 0    39   BiDi ~ 0
D6
Text GLabel 950  2650 0    39   BiDi ~ 0
~S5
Text GLabel 950  2750 0    39   BiDi ~ 0
+5VDC
Text GLabel 950  2850 0    39   BiDi ~ 0
RD5
Text GLabel 950  2950 0    39   BiDi ~ 0
~CCTL
Text GLabel 2750 2950 2    39   BiDi ~ 0
B02/PHI2
Text GLabel 2750 2850 2    39   BiDi ~ 0
R/~W
Text GLabel 2750 2750 2    39   BiDi ~ 0
A10
Text GLabel 2750 2650 2    39   BiDi ~ 0
A11
Text GLabel 2750 2550 2    39   BiDi ~ 0
D7
Text GLabel 2750 2450 2    39   BiDi ~ 0
D3
Text GLabel 2750 2350 2    39   BiDi ~ 0
A12
Text GLabel 2750 2250 2    39   BiDi ~ 0
A9
Text GLabel 2750 2150 2    39   BiDi ~ 0
A8
Text GLabel 2750 2050 2    39   BiDi ~ 0
A7
Text GLabel 2750 1950 2    39   BiDi ~ 0
A6
Text GLabel 2750 1850 2    39   BiDi ~ 0
A5
Text GLabel 2750 1750 2    39   BiDi ~ 0
A4
Text GLabel 2750 1650 2    39   BiDi ~ 0
GND
Text GLabel 2750 1550 2    39   BiDi ~ 0
RD4
Text GLabel 5850 2100 2    39   BiDi ~ 0
~IRQ
Text GLabel 5850 2200 2    39   BiDi ~ 0
~HALT
Text GLabel 5850 2300 2    39   BiDi ~ 0
A13
Text GLabel 5850 2400 2    39   BiDi ~ 0
A14
Text GLabel 5850 2500 2    39   BiDi ~ 0
A15
Text GLabel 5850 2600 2    39   BiDi ~ 0
GND
Text GLabel 5850 2000 2    39   BiDi ~ 0
RSRVD
Text GLabel 4050 2600 0    39   BiDi ~ 0
+5VDC
Text GLabel 4050 2500 0    39   BiDi ~ 0
~REF
Text GLabel 4050 2400 0    39   BiDi ~ 0
AUDIO
Text GLabel 4050 2300 0    39   BiDi ~ 0
~MPD
Text GLabel 4050 2200 0    39   BiDi ~ 0
~D1XX
Text GLabel 4050 2100 0    39   BiDi ~ 0
~RST
Text GLabel 4050 2000 0    39   BiDi ~ 0
~EXSEL
Text Notes 700  1050 0    59   ~ 12
EXPANSION BUS PASS THRU
$Comp
L 74xGxx1:74LVC2G74 U12
U 1 1 5C5D431D
P 9750 3950
F 0 "U12" H 9650 4150 50  0000 C CNN
F 1 "74LVC2G74" H 9950 3750 50  0000 C CNN
F 2 "Package_SO:TSSOP-8_3x3mm_P0.65mm" H 9750 3950 50  0001 C CNN
F 3 "" H 9750 3950 50  0001 C CNN
	1    9750 3950
	1    0    0    -1  
$EndComp
Text GLabel 9650 4500 0    39   BiDi ~ 0
nRESET_MEM
Text GLabel 8300 3800 0    39   BiDi ~ 0
mPBISEL
Text Notes 8050 1850 0    59   ~ 12
PBI Device Selection when accessing $D1FF
Text GLabel 7050 4050 0    39   BiDi ~ 0
mR/~W
Text GLabel 7000 2050 0    39   BiDi ~ 8
mD0
Text GLabel 7000 2150 0    39   BiDi ~ 8
mD1
Text GLabel 7000 2250 0    39   BiDi ~ 8
mD2
Text GLabel 7000 2350 0    39   BiDi ~ 8
mD3
Text GLabel 7000 2450 0    39   BiDi ~ 8
mD4
Text GLabel 7000 2550 0    39   BiDi ~ 8
mD5
Text GLabel 7000 2650 0    39   BiDi ~ 8
mD6
Text GLabel 7000 2750 0    39   BiDi ~ 8
mD7
$Comp
L 74xGxx1:74LVC2G32 U10
U 1 1 5C5D66FE
P 8650 5250
F 0 "U10" H 8550 5400 50  0000 C CNN
F 1 "74LVC2G32" H 8650 5100 50  0000 C CNN
F 2 "Package_SO:TSSOP-8_3x3mm_P0.65mm" H 8650 5250 50  0001 C CNN
F 3 "" H 8650 5250 50  0001 C CNN
	1    8650 5250
	-1   0    0    1   
$EndComp
Text GLabel 8950 5300 2    39   BiDi ~ 0
~mD8XX-DFXX
Text GLabel 8400 5250 0    39   BiDi ~ 0
~mMPD
Text Notes 7100 5600 0    59   ~ 12
MATH PACK DISABLE WHEN DEVICE ENABLED & ACCESSING D8XX-DFXX
NoConn ~ 10000 3850
Text GLabel 9050 3250 2    39   BiDi ~ 0
PBIDEV
Text GLabel 8300 3900 0    39   BiDi ~ 0
PBIDEV
$Comp
L 74xGxx1:74LVC2G08 U11
U 1 1 5C5E39BC
P 8850 3850
F 0 "U11" H 8750 4000 50  0000 C CNN
F 1 "74LVC2G08" H 8850 3700 50  0000 C CNN
F 2 "Package_SO:TSSOP-8_3x3mm_P0.65mm" H 8850 3850 50  0001 C CNN
F 3 "" H 8850 3850 50  0001 C CNN
	1    8850 3850
	1    0    0    -1  
$EndComp
$Comp
L 74xGxx1:74LVC2G08 U11
U 2 1 5C5E3CD3
P 8850 4300
F 0 "U11" H 8750 4450 50  0000 C CNN
F 1 "74LVC2G08" H 8850 4150 50  0000 C CNN
F 2 "Package_SO:TSSOP-8_3x3mm_P0.65mm" H 8850 4300 50  0001 C CNN
F 3 "" H 8850 4300 50  0001 C CNN
	2    8850 4300
	1    0    0    -1  
$EndComp
Text Notes 8900 3450 0    59   ~ 12
mPBISEL will go high when accessing $D1FF
Text GLabel 8550 4350 0    39   BiDi ~ 0
mPBISEL
$Comp
L 74xx1:74HCT04 U9
U 1 1 5C5E40DA
P 7350 4050
F 0 "U9" H 7350 4100 50  0000 C CNN
F 1 "74HCT04" H 7350 4000 50  0000 C CNN
F 2 "Package_SO:SSOP-14_5.3x6.2mm_P0.65mm" H 7350 4050 50  0001 C CNN
F 3 "" H 7350 4050 50  0001 C CNN
	1    7350 4050
	1    0    0    -1  
$EndComp
Text GLabel 8550 4250 0    39   BiDi ~ 0
mW/~R
Text Notes 6900 4600 0    59   ~ 12
LATCH CLOCK will be enable only when WRITING
$Comp
L 74xx1:74HCT04 U9
U 2 1 5C5E4378
P 2800 4750
F 0 "U9" H 2800 4800 50  0000 C CNN
F 1 "74HCT04" H 2800 4700 50  0000 C CNN
F 2 "Package_SO:SSOP-14_5.3x6.2mm_P0.65mm" H 2800 4750 50  0001 C CNN
F 3 "" H 2800 4750 50  0001 C CNN
	2    2800 4750
	1    0    0    -1  
$EndComp
$Comp
L 74xx1:74HCT04 U9
U 3 1 5C5E43E6
P 5900 4500
F 0 "U9" H 5900 4550 50  0000 C CNN
F 1 "74HCT04" H 5900 4450 50  0000 C CNN
F 2 "Package_SO:SSOP-14_5.3x6.2mm_P0.65mm" H 5900 4500 50  0001 C CNN
F 3 "" H 5900 4500 50  0001 C CNN
	3    5900 4500
	1    0    0    -1  
$EndComp
$Comp
L 74xx1:74HCT04 U9
U 4 1 5C5E4437
P 5900 4950
F 0 "U9" H 5900 5000 50  0000 C CNN
F 1 "74HCT04" H 5900 4900 50  0000 C CNN
F 2 "Package_SO:SSOP-14_5.3x6.2mm_P0.65mm" H 5900 4950 50  0001 C CNN
F 3 "" H 5900 4950 50  0001 C CNN
	4    5900 4950
	1    0    0    -1  
$EndComp
$Comp
L 74xx1:74HCT04 U9
U 5 1 5C5E44D6
P 5100 4050
F 0 "U9" H 5100 4100 50  0000 C CNN
F 1 "74HCT04" H 5100 4000 50  0000 C CNN
F 2 "Package_SO:SSOP-14_5.3x6.2mm_P0.65mm" H 5100 4050 50  0001 C CNN
F 3 "" H 5100 4050 50  0001 C CNN
	5    5100 4050
	1    0    0    -1  
$EndComp
$Comp
L 74xx1:74HCT04 U9
U 6 1 5C5E455B
P 5100 4500
F 0 "U9" H 5100 4550 50  0000 C CNN
F 1 "74HCT04" H 5100 4450 50  0000 C CNN
F 2 "Package_SO:SSOP-14_5.3x6.2mm_P0.65mm" H 5100 4500 50  0001 C CNN
F 3 "" H 5100 4500 50  0001 C CNN
	6    5100 4500
	1    0    0    -1  
$EndComp
$Comp
L 74xx1:74HCT04 U9
U 7 1 5C5E4621
P 4800 5500
F 0 "U9" H 4800 5550 50  0000 C CNN
F 1 "74HCT04" H 4800 5450 50  0000 C CNN
F 2 "Package_SO:SSOP-14_5.3x6.2mm_P0.65mm" H 4800 5500 50  0001 C CNN
F 3 "" H 4800 5500 50  0001 C CNN
	7    4800 5500
	-1   0    0    1   
$EndComp
$Comp
L power1:GND #PWR037
U 1 1 5C5E4A20
P 4550 4500
F 0 "#PWR037" H 4550 4250 50  0001 C CNN
F 1 "GND" H 4550 4350 50  0000 C CNN
F 2 "" H 4550 4500 50  0001 C CNN
F 3 "" H 4550 4500 50  0001 C CNN
	1    4550 4500
	0    1    1    0   
$EndComp
NoConn ~ 6200 4500
NoConn ~ 6200 4950
NoConn ~ 5400 4050
NoConn ~ 5400 4500
Text GLabel 4800 6000 3    39   BiDi ~ 8
VCC3V3
Text GLabel 7650 4050 2    39   BiDi ~ 0
mW/~R
Text Notes 7600 1450 0    79   ~ 16
PBI Device Selection for UART/SPI Devices
Text Notes 800  6450 0    79   ~ 16
This expansion can have a PBI device driver in ROM. It can be a RS232 (850 R: Interface compatible) or a GPIO 16 Channels Interface
Text GLabel 2400 4750 0    39   BiDi ~ 0
mB5
Text GLabel 3100 4750 2    39   BiDi ~ 0
~mB5
Text Notes 2450 5050 0    39   ~ 8
RAM CHIP SELECT 0-1
$Comp
L atari23MTS_Upgrade-rescue:CONN_01X02 P7
U 1 1 5CA88462
P 7650 1850
AR Path="/5CA88462" Ref="P7"  Part="1" 
AR Path="/5C2FF215/5CA88462" Ref="P7"  Part="1" 
F 0 "P7" H 7650 2000 50  0000 C CNN
F 1 "CONN_01X02" V 7750 1850 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 7650 1850 50  0000 C CNN
F 3 "" H 7650 1850 50  0000 C CNN
	1    7650 1850
	0    -1   -1   0   
$EndComp
$Comp
L atari23MTS_Upgrade-rescue:CONN_01X02 P8
U 1 1 5CA884BD
P 7900 1950
AR Path="/5CA884BD" Ref="P8"  Part="1" 
AR Path="/5C2FF215/5CA884BD" Ref="P8"  Part="1" 
F 0 "P8" H 7900 2100 50  0000 C CNN
F 1 "CONN_01X02" V 8000 1950 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 7900 1950 50  0001 C CNN
F 3 "" H 7900 1950 50  0000 C CNN
	1    7900 1950
	0    -1   -1   0   
$EndComp
$Comp
L atari23MTS_Upgrade-rescue:CONN_01X02 P9
U 1 1 5CA88508
P 8150 2050
AR Path="/5CA88508" Ref="P9"  Part="1" 
AR Path="/5C2FF215/5CA88508" Ref="P9"  Part="1" 
F 0 "P9" H 8150 2200 50  0000 C CNN
F 1 "CONN_01X02" V 8250 2050 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 8150 2050 50  0001 C CNN
F 3 "" H 8150 2050 50  0000 C CNN
	1    8150 2050
	0    -1   -1   0   
$EndComp
$Comp
L atari23MTS_Upgrade-rescue:CONN_01X02 P10
U 1 1 5CA8867E
P 8400 2150
AR Path="/5CA8867E" Ref="P10"  Part="1" 
AR Path="/5C2FF215/5CA8867E" Ref="P10"  Part="1" 
F 0 "P10" H 8400 2300 50  0000 C CNN
F 1 "CONN_01X02" V 8500 2150 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 8400 2150 50  0001 C CNN
F 3 "" H 8400 2150 50  0000 C CNN
	1    8400 2150
	0    -1   -1   0   
$EndComp
$Comp
L atari23MTS_Upgrade-rescue:CONN_01X02 P11
U 1 1 5CA886CB
P 8650 2250
AR Path="/5CA886CB" Ref="P11"  Part="1" 
AR Path="/5C2FF215/5CA886CB" Ref="P11"  Part="1" 
F 0 "P11" H 8650 2400 50  0000 C CNN
F 1 "CONN_01X02" V 8750 2250 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 8650 2250 50  0001 C CNN
F 3 "" H 8650 2250 50  0000 C CNN
	1    8650 2250
	0    -1   -1   0   
$EndComp
$Comp
L atari23MTS_Upgrade-rescue:CONN_01X02 P12
U 1 1 5CA88715
P 8900 2350
AR Path="/5CA88715" Ref="P12"  Part="1" 
AR Path="/5C2FF215/5CA88715" Ref="P12"  Part="1" 
F 0 "P12" H 8900 2500 50  0000 C CNN
F 1 "CONN_01X02" V 9000 2350 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 8900 2350 50  0001 C CNN
F 3 "" H 8900 2350 50  0000 C CNN
	1    8900 2350
	0    -1   -1   0   
$EndComp
$Comp
L atari23MTS_Upgrade-rescue:CONN_01X02 P13
U 1 1 5CA88770
P 9150 2450
AR Path="/5CA88770" Ref="P13"  Part="1" 
AR Path="/5C2FF215/5CA88770" Ref="P13"  Part="1" 
F 0 "P13" H 9150 2600 50  0000 C CNN
F 1 "CONN_01X02" V 9250 2450 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 9150 2450 50  0001 C CNN
F 3 "" H 9150 2450 50  0000 C CNN
	1    9150 2450
	0    -1   -1   0   
$EndComp
$Comp
L atari23MTS_Upgrade-rescue:CONN_01X02 P14
U 1 1 5CA887C4
P 9400 2550
AR Path="/5CA887C4" Ref="P14"  Part="1" 
AR Path="/5C2FF215/5CA887C4" Ref="P14"  Part="1" 
F 0 "P14" H 9400 2700 50  0000 C CNN
F 1 "CONN_01X02" V 9500 2550 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 9400 2550 50  0001 C CNN
F 3 "" H 9400 2550 50  0000 C CNN
	1    9400 2550
	0    -1   -1   0   
$EndComp
Connection ~ 7800 3250
Wire Wire Line
	7800 2400 7800 3250
Wire Wire Line
	7950 2400 7800 2400
Wire Wire Line
	7950 2150 7950 2400
Connection ~ 7900 3250
Wire Wire Line
	7900 2500 7900 3250
Wire Wire Line
	8200 2500 7900 2500
Wire Wire Line
	8200 2250 8200 2500
Connection ~ 8050 3250
Wire Wire Line
	8050 2600 8050 3250
Wire Wire Line
	8450 2600 8050 2600
Wire Wire Line
	8450 2350 8450 2600
Connection ~ 8200 3250
Wire Wire Line
	8200 2700 8200 3250
Wire Wire Line
	8700 2700 8200 2700
Wire Wire Line
	8700 2450 8700 2700
Connection ~ 8350 3250
Wire Wire Line
	8350 2800 8350 3250
Wire Wire Line
	8950 2800 8350 2800
Wire Wire Line
	8950 2550 8950 2800
Connection ~ 8500 3250
Wire Wire Line
	8500 2850 8500 3250
Wire Wire Line
	9200 2850 8500 2850
Wire Wire Line
	9200 2650 9200 2850
Connection ~ 8650 3250
Wire Wire Line
	8650 2950 8650 3250
Wire Wire Line
	9450 2950 8650 2950
Wire Wire Line
	9450 2750 9450 2950
Wire Wire Line
	7700 2050 7700 3250
Wire Wire Line
	7000 2750 9350 2750
Wire Wire Line
	7000 2650 9100 2650
Wire Wire Line
	7000 2550 8850 2550
Wire Wire Line
	7000 2450 8600 2450
Wire Wire Line
	7000 2350 8350 2350
Wire Wire Line
	7000 2250 8100 2250
Wire Wire Line
	7000 2150 7850 2150
Wire Wire Line
	7000 2050 7600 2050
Wire Notes Line
	2100 5200 2100 4500
Wire Notes Line
	3450 5200 2100 5200
Wire Notes Line
	3450 4500 3450 5200
Wire Notes Line
	2100 4500 3450 4500
Wire Wire Line
	5500 4500 5500 4950
Wire Notes Line
	11050 1200 11050 5850
Connection ~ 4550 4500
Wire Wire Line
	4800 4500 4550 4500
Connection ~ 4800 4950
Wire Wire Line
	4550 4050 4550 4950
Wire Wire Line
	4800 4050 4550 4050
Connection ~ 5500 4500
Wire Wire Line
	5600 4500 5500 4500
Connection ~ 5500 4950
Wire Wire Line
	4800 4950 4800 5000
Wire Wire Line
	4550 4950 5600 4950
Wire Wire Line
	2500 4750 2400 4750
Wire Wire Line
	9350 4300 9350 4050
Wire Wire Line
	9100 4300 9350 4300
Wire Wire Line
	10400 5200 10400 4050
Wire Wire Line
	8300 3900 8550 3900
Wire Wire Line
	8300 3800 8550 3800
Connection ~ 9750 4350
Wire Wire Line
	9750 3600 9750 3700
Wire Wire Line
	10200 3600 9750 3600
Wire Wire Line
	10200 4350 10200 3600
Wire Wire Line
	9750 4350 10200 4350
Wire Wire Line
	7700 3250 9050 3250
Wire Wire Line
	9750 4500 9650 4500
Wire Notes Line
	6650 1200 6650 1450
Wire Notes Line
	6650 1200 11050 1200
Wire Notes Line
	11050 5850 6650 5850
Wire Notes Line
	6650 5850 6650 1400
Wire Wire Line
	8950 5200 10400 5200
Wire Wire Line
	10400 4050 10000 4050
Wire Wire Line
	9100 3850 9500 3850
Wire Wire Line
	9350 4050 9500 4050
Wire Wire Line
	9750 4200 9750 4500
Wire Notes Line
	6400 850  550  850 
Wire Notes Line
	6400 3600 6400 850 
Wire Notes Line
	550  3600 6400 3600
Wire Notes Line
	550  850  550  3600
$EndSCHEMATC
