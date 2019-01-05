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
Sheet 3 3
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L ATARICARTRIDGE CART2
U 1 1 5C2FF23F
P 3400 3600
F 0 "CART2" H 3850 4450 50  0000 C CNN
F 1 "ATARICARTRIDGE" H 3450 3700 50  0000 C CNN
F 2 "RetroBitLab:TE_5530843-2_15X2_CART_EDGE_CONNECTOR" H 3450 2600 50  0000 C CNN
F 3 "" H 3400 2750 50  0000 C CNN
	1    3400 3600
	1    0    0    -1  
$EndComp
$Comp
L ECIBUS ECI2
U 1 1 5C2FF2C0
P 6500 3650
F 0 "ECI2" H 6950 4100 50  0000 C CNN
F 1 "ECIBUS" H 6550 3350 50  0000 C CNN
F 2 "RetroBitLab:TE_5530843-2_7X2_EDGE_CONNECTOR" H 6500 3050 50  0000 C CNN
F 3 "" H 6500 2800 50  0000 C CNN
	1    6500 3650
	1    0    0    -1  
$EndComp
Text GLabel 2500 2950 0    39   BiDi ~ 0
~S4
Text GLabel 2500 3050 0    39   BiDi ~ 0
A3
Text GLabel 2500 3150 0    39   BiDi ~ 0
A2
Text GLabel 2500 3250 0    39   BiDi ~ 0
A1
Text GLabel 2500 3350 0    39   BiDi ~ 0
A0
Text GLabel 2500 3450 0    39   BiDi ~ 0
D4
Text GLabel 2500 3550 0    39   BiDi ~ 0
D5
Text GLabel 2500 3650 0    39   BiDi ~ 0
D2
Text GLabel 2500 3750 0    39   BiDi ~ 0
D1
Text GLabel 2500 3850 0    39   BiDi ~ 0
D0
Text GLabel 2500 3950 0    39   BiDi ~ 0
D6
Text GLabel 2500 4050 0    39   BiDi ~ 0
~S5
Text GLabel 2500 4150 0    39   BiDi ~ 0
+5VDC
Text GLabel 2500 4250 0    39   BiDi ~ 0
RD5
Text GLabel 2500 4350 0    39   BiDi ~ 0
~CCTL
Text GLabel 4300 4350 2    39   BiDi ~ 0
B02/PHI2
Text GLabel 4300 4250 2    39   BiDi ~ 0
R/~W
Text GLabel 4300 4150 2    39   BiDi ~ 0
A10
Text GLabel 4300 4050 2    39   BiDi ~ 0
A11
Text GLabel 4300 3950 2    39   BiDi ~ 0
D7
Text GLabel 4300 3850 2    39   BiDi ~ 0
D3
Text GLabel 4300 3750 2    39   BiDi ~ 0
A12
Text GLabel 4300 3650 2    39   BiDi ~ 0
A9
Text GLabel 4300 3550 2    39   BiDi ~ 0
A8
Text GLabel 4300 3450 2    39   BiDi ~ 0
A7
Text GLabel 4300 3350 2    39   BiDi ~ 0
A6
Text GLabel 4300 3250 2    39   BiDi ~ 0
A5
Text GLabel 4300 3150 2    39   BiDi ~ 0
A4
Text GLabel 4300 3050 2    39   BiDi ~ 0
GND
Text GLabel 4300 2950 2    39   BiDi ~ 0
RD4
Text GLabel 7400 3500 2    39   BiDi ~ 0
~IRQ
Text GLabel 7400 3600 2    39   BiDi ~ 0
~HALT
Text GLabel 7400 3700 2    39   BiDi ~ 0
A13
Text GLabel 7400 3800 2    39   BiDi ~ 0
A14
Text GLabel 7400 3900 2    39   BiDi ~ 0
A15
Text GLabel 7400 4000 2    39   BiDi ~ 0
GND
Text GLabel 7400 3400 2    39   BiDi ~ 0
RSRVD
Text GLabel 5600 4000 0    39   BiDi ~ 0
+5VDC
Text GLabel 5600 3900 0    39   BiDi ~ 0
~REF
Text GLabel 5600 3800 0    39   BiDi ~ 0
AUDIO
Text GLabel 5600 3700 0    39   BiDi ~ 0
~MPD
Text GLabel 5600 3600 0    39   BiDi ~ 0
~D1XX
Text GLabel 5600 3500 0    39   BiDi ~ 0
~RST
Text GLabel 5600 3400 0    39   BiDi ~ 0
~EXSEL
Wire Notes Line
	2100 2250 2100 5000
Wire Notes Line
	2100 5000 7950 5000
Wire Notes Line
	7950 5000 7950 2250
Wire Notes Line
	7950 2250 2100 2250
Text Notes 2250 2450 0    59   ~ 12
EXPANSION BUS PASS THRU
$EndSCHEMATC
