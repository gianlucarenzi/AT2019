EESchema Schematic File Version 2
LIBS:AmigaComponents
LIBS:4xxx
LIBS:4xxx_IEEE
LIBS:74xGxx
LIBS:74xx
LIBS:74xx_IEEE
LIBS:Amplifier_Audio
LIBS:Amplifier_Buffer
LIBS:Amplifier_Current
LIBS:Amplifier_Difference
LIBS:Amplifier_Instrumentation
LIBS:Amplifier_Operational
LIBS:Amplifier_Video
LIBS:Analog
LIBS:Analog_ADC
LIBS:Analog_DAC
LIBS:Analog_Switch
LIBS:Audio
LIBS:Battery_Management
LIBS:Comparator
LIBS:Connector
LIBS:Connector_Generic
LIBS:Connector_Generic_MountingPin
LIBS:Connector_Generic_Shielded
LIBS:Converter_ACDC
LIBS:Converter_DCDC
LIBS:CPLD_Altera
LIBS:CPLD_Xilinx
LIBS:CPU
LIBS:CPU_NXP_6800
LIBS:CPU_NXP_68000
LIBS:CPU_PowerPC
LIBS:Device
LIBS:Diode
LIBS:Diode_Bridge
LIBS:Diode_Laser
LIBS:Display_Character
LIBS:Display_Graphic
LIBS:Driver_Display
LIBS:Driver_FET
LIBS:Driver_LED
LIBS:Driver_Motor
LIBS:Driver_Relay
LIBS:DSP_AnalogDevices
LIBS:DSP_Freescale
LIBS:DSP_Microchip_DSPIC33
LIBS:DSP_Motorola
LIBS:DSP_Texas
LIBS:Fiber_Optic
LIBS:Filter
LIBS:FPGA_Lattice
LIBS:FPGA_Microsemi
LIBS:FPGA_Xilinx
LIBS:FPGA_Xilinx_Artix7
LIBS:FPGA_Xilinx_Kintex7
LIBS:FPGA_Xilinx_Spartan6
LIBS:FPGA_Xilinx_Virtex5
LIBS:FPGA_Xilinx_Virtex6
LIBS:FPGA_Xilinx_Virtex7
LIBS:ft232rl
LIBS:GPU
LIBS:Graphic
LIBS:Interface
LIBS:Interface_CAN_LIN
LIBS:Interface_CurrentLoop
LIBS:Interface_Ethernet
LIBS:Interface_Expansion
LIBS:Interface_HID
LIBS:Interface_LineDriver
LIBS:Interface_Optical
LIBS:Interface_Telecom
LIBS:Interface_UART
LIBS:Interface_USB
LIBS:Isolator
LIBS:Isolator_Analog
LIBS:Jumper
LIBS:LED
LIBS:Logic_LevelTranslator
LIBS:Logic_Programmable
LIBS:MCU_AnalogDevices
LIBS:MCU_Cypress
LIBS:MCU_Espressif
LIBS:MCU_Intel
LIBS:MCU_Microchip_8051
LIBS:MCU_Microchip_ATmega
LIBS:MCU_Microchip_ATtiny
LIBS:MCU_Microchip_AVR
LIBS:MCU_Microchip_PIC10
LIBS:MCU_Microchip_PIC12
LIBS:MCU_Microchip_PIC16
LIBS:MCU_Microchip_PIC18
LIBS:MCU_Microchip_PIC24
LIBS:MCU_Microchip_PIC32
LIBS:MCU_Microchip_SAMD
LIBS:MCU_Microchip_SAME
LIBS:MCU_Microchip_SAML
LIBS:MCU_Module
LIBS:MCU_Nordic
LIBS:MCU_NXP_ColdFire
LIBS:MCU_NXP_HC11
LIBS:MCU_NXP_HC12
LIBS:MCU_NXP_HCS12
LIBS:MCU_NXP_Kinetis
LIBS:MCU_NXP_LPC
LIBS:MCU_NXP_MAC7100
LIBS:MCU_NXP_MCore
LIBS:MCU_NXP_S08
LIBS:MCU_Parallax
LIBS:MCU_SiFive
LIBS:MCU_SiliconLabs
LIBS:MCU_ST_STM8
LIBS:MCU_ST_STM32F0
LIBS:MCU_ST_STM32F1
LIBS:MCU_ST_STM32F2
LIBS:MCU_ST_STM32F3
LIBS:MCU_ST_STM32F4
LIBS:MCU_ST_STM32F7
LIBS:MCU_ST_STM32H7
LIBS:MCU_ST_STM32L0
LIBS:MCU_ST_STM32L1
LIBS:MCU_ST_STM32L4
LIBS:MCU_ST_STM32L4+
LIBS:MCU_Texas
LIBS:MCU_Texas_MSP430
LIBS:Mechanical
LIBS:Memory_Controller
LIBS:Memory_EEPROM
LIBS:Memory_EPROM
LIBS:Memory_Flash
LIBS:Memory_NVRAM
LIBS:Memory_RAM
LIBS:Memory_ROM
LIBS:Memory_UniqueID
LIBS:Motor
LIBS:Oscillator
LIBS:Potentiometer_Digital
LIBS:power
LIBS:Power_Management
LIBS:Power_Protection
LIBS:Power_Supervisor
LIBS:pspice
LIBS:Reference_Current
LIBS:Reference_Voltage
LIBS:Regulator_Controller
LIBS:Regulator_Current
LIBS:Regulator_Linear
LIBS:Regulator_SwitchedCapacitor
LIBS:Regulator_Switching
LIBS:Relay
LIBS:Relay_SolidState
LIBS:RF
LIBS:RF_AM_FM
LIBS:RF_Amplifier
LIBS:RF_Bluetooth
LIBS:RF_GPS
LIBS:RF_GSM
LIBS:RF_Mixer
LIBS:RF_Module
LIBS:RF_RFID
LIBS:RF_Switch
LIBS:RF_WiFi
LIBS:RF_ZigBee
LIBS:Security
LIBS:Sensor
LIBS:Sensor_Audio
LIBS:Sensor_Current
LIBS:Sensor_Gas
LIBS:Sensor_Humidity
LIBS:Sensor_Magnetic
LIBS:Sensor_Motion
LIBS:Sensor_Optical
LIBS:Sensor_Pressure
LIBS:Sensor_Proximity
LIBS:Sensor_Temperature
LIBS:Sensor_Touch
LIBS:Sensor_Voltage
LIBS:Switch
LIBS:Timer
LIBS:Timer_PLL
LIBS:Timer_RTC
LIBS:Transformer
LIBS:Transistor_Array
LIBS:Transistor_BJT
LIBS:Transistor_FET
LIBS:Transistor_IGBT
LIBS:Triac_Thyristor
LIBS:Valve
LIBS:Video
LIBS:atari23MTS_Upgrade-cache
EELAYER 25 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 2 4
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
F 3 "" H 7650 2250 60  0001 C CNN
	1    7650 2250
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR023
U 1 1 5C2BB99F
P 7650 3350
F 0 "#PWR023" H 7650 3100 50  0001 C CNN
F 1 "GND" H 7650 3200 50  0000 C CNN
F 2 "" H 7650 3350 60  0001 C CNN
F 3 "" H 7650 3350 60  0001 C CNN
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
F 3 "" H 7800 1100 60  0001 C CNN
	1    7800 1100
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR024
U 1 1 5C2BF58F
P 7900 1100
F 0 "#PWR024" H 7900 850 50  0001 C CNN
F 1 "GND" H 7900 950 50  0000 C CNN
F 2 "" H 7900 1100 60  0001 C CNN
F 3 "" H 7900 1100 60  0001 C CNN
	1    7900 1100
	0    -1   -1   0   
$EndComp
$Comp
L TXB0108-PW U5
U 1 1 5C2BF846
P 1350 1650
F 0 "U5" H 1150 2400 60  0000 L CNN
F 1 "TXB0108-PW" H 1150 900 60  0000 L CNN
F 2 "Housings_SSOP:SSOP-20_4.4x6.5mm_Pitch0.65mm" H 1150 1600 60  0001 C CNN
F 3 "" H 1350 1650 60  0001 C CNN
	1    1350 1650
	1    0    0    -1  
$EndComp
$Comp
L TXB0108-PW U4
U 1 1 5C2BF9CC
P 1600 5800
F 0 "U4" H 1400 6550 60  0000 L CNN
F 1 "TXB0108-PW" H 1400 5050 60  0000 L CNN
F 2 "Housings_SSOP:SSOP-20_4.4x6.5mm_Pitch0.65mm" H 1400 5750 60  0001 C CNN
F 3 "" H 1600 5800 60  0001 C CNN
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
F 3 "" H 4050 5800 60  0001 C CNN
	1    4050 5800
	1    0    0    -1  
$EndComp
$Comp
L TXB0108-PW U10
U 1 1 5C2BFAD5
P 4600 1600
F 0 "U10" H 4400 2350 60  0000 L CNN
F 1 "TXB0108-PW" H 4400 850 60  0000 L CNN
F 2 "Housings_SSOP:SSOP-20_4.4x6.5mm_Pitch0.65mm" H 4400 1550 60  0001 C CNN
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
Text GLabel 2100 5200 2    39   BiDi ~ 0
VCC5V
Text GLabel 4550 5200 2    39   BiDi ~ 0
VCC5V
Text GLabel 5100 1000 2    39   BiDi ~ 0
VCC5V
$Comp
L GND #PWR025
U 1 1 5C2D99D7
P 950 2250
F 0 "#PWR025" H 950 2000 50  0001 C CNN
F 1 "GND" H 950 2100 50  0000 C CNN
F 2 "" H 950 2250 60  0001 C CNN
F 3 "" H 950 2250 60  0001 C CNN
	1    950  2250
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR026
U 1 1 5C2D9EC5
P 1200 6400
F 0 "#PWR026" H 1200 6150 50  0001 C CNN
F 1 "GND" H 1200 6250 50  0000 C CNN
F 2 "" H 1200 6400 60  0001 C CNN
F 3 "" H 1200 6400 60  0001 C CNN
	1    1200 6400
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR027
U 1 1 5C2D9EE5
P 3650 6400
F 0 "#PWR027" H 3650 6150 50  0001 C CNN
F 1 "GND" H 3650 6250 50  0000 C CNN
F 2 "" H 3650 6400 60  0001 C CNN
F 3 "" H 3650 6400 60  0001 C CNN
	1    3650 6400
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR028
U 1 1 5C2D9F05
P 4200 2200
F 0 "#PWR028" H 4200 1950 50  0001 C CNN
F 1 "GND" H 4200 2050 50  0000 C CNN
F 2 "" H 4200 2200 60  0001 C CNN
F 3 "" H 4200 2200 60  0001 C CNN
	1    4200 2200
	1    0    0    -1  
$EndComp
Text GLabel 950  1050 0    39   BiDi ~ 0
VCC3V3
Text GLabel 1200 5200 0    39   BiDi ~ 0
VCC3V3
Text GLabel 3650 5200 0    39   BiDi ~ 0
VCC3V3
Text GLabel 4200 1000 0    39   BiDi ~ 0
VCC3V3
Text GLabel 950  1250 0    39   BiDi ~ 0
VCC3V3
Text GLabel 1200 5400 0    39   BiDi ~ 0
VCC3V3
Text GLabel 3650 5400 0    39   BiDi ~ 0
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
F 3 "" H 9300 2250 60  0001 C CNN
	1    9300 2250
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR029
U 1 1 5C2DCB90
P 9300 3350
F 0 "#PWR029" H 9300 3100 50  0001 C CNN
F 1 "GND" H 9300 3200 50  0000 C CNN
F 2 "" H 9300 3350 60  0001 C CNN
F 3 "" H 9300 3350 60  0001 C CNN
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
F 3 "" H 9450 1100 60  0001 C CNN
	1    9450 1100
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR030
U 1 1 5C2DCBA5
P 9550 1100
F 0 "#PWR030" H 9550 850 50  0001 C CNN
F 1 "GND" H 9550 950 50  0000 C CNN
F 2 "" H 9550 1100 60  0001 C CNN
F 3 "" H 9550 1100 60  0001 C CNN
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
F 3 "" H 7650 5150 60  0001 C CNN
	1    7650 5150
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR031
U 1 1 5C2DCF05
P 7650 6250
F 0 "#PWR031" H 7650 6000 50  0001 C CNN
F 1 "GND" H 7650 6100 50  0000 C CNN
F 2 "" H 7650 6250 60  0001 C CNN
F 3 "" H 7650 6250 60  0001 C CNN
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
F 3 "" H 7850 4000 60  0001 C CNN
	1    7850 4000
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR032
U 1 1 5C2DCF1A
P 7950 4000
F 0 "#PWR032" H 7950 3750 50  0001 C CNN
F 1 "GND" H 7950 3850 50  0000 C CNN
F 2 "" H 7950 4000 60  0001 C CNN
F 3 "" H 7950 4000 60  0001 C CNN
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
F 3 "" H 9300 5150 60  0001 C CNN
	1    9300 5150
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR033
U 1 1 5C2DCF47
P 9300 6250
F 0 "#PWR033" H 9300 6000 50  0001 C CNN
F 1 "GND" H 9300 6100 50  0000 C CNN
F 2 "" H 9300 6250 60  0001 C CNN
F 3 "" H 9300 6250 60  0001 C CNN
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
F 3 "" H 9500 4000 60  0001 C CNN
	1    9500 4000
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR034
U 1 1 5C2DCF5C
P 9600 4000
F 0 "#PWR034" H 9600 3750 50  0001 C CNN
F 1 "GND" H 9600 3850 50  0000 C CNN
F 2 "" H 9600 4000 60  0001 C CNN
F 3 "" H 9600 4000 60  0001 C CNN
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
Text GLabel 1000 4050 0    39   BiDi ~ 0
mA10
$Comp
L 74HC04 U7
U 2 1 5C2DFEE1
P 3050 3250
F 0 "U7" H 3050 3300 50  0000 C CNN
F 1 "74HC04" H 3050 3200 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 3050 3250 50  0001 C CNN
F 3 "" H 3050 3250 60  0001 C CNN
	2    3050 3250
	1    0    0    -1  
$EndComp
$Comp
L 74HC04 U7
U 3 1 5C2DFF28
P 1300 3650
F 0 "U7" H 1300 3700 50  0000 C CNN
F 1 "74HC04" H 1300 3600 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 1300 3650 50  0001 C CNN
F 3 "" H 1300 3650 60  0001 C CNN
	3    1300 3650
	1    0    0    -1  
$EndComp
$Comp
L 74HC04 U7
U 4 1 5C2E0001
P 1300 4450
F 0 "U7" H 1300 4500 50  0000 C CNN
F 1 "74HC04" H 1300 4400 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 1300 4450 50  0001 C CNN
F 3 "" H 1300 4450 60  0001 C CNN
	4    1300 4450
	1    0    0    -1  
$EndComp
$Comp
L 74HC04 U7
U 5 1 5C2E0114
P 3050 4250
F 0 "U7" H 3050 4300 50  0000 C CNN
F 1 "74HC04" H 3050 4200 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 3050 4250 50  0001 C CNN
F 3 "" H 3050 4250 60  0001 C CNN
	5    3050 4250
	1    0    0    -1  
$EndComp
$Comp
L 74HC04 U7
U 6 1 5C2E0161
P 1300 3250
F 0 "U7" H 1300 3300 50  0000 C CNN
F 1 "74HC04" H 1300 3200 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 1300 3250 50  0001 C CNN
F 3 "" H 1300 3250 60  0001 C CNN
	6    1300 3250
	1    0    0    -1  
$EndComp
$Comp
L 74HC04 U7
U 7 1 5C2E0C9C
P 5750 3550
F 0 "U7" H 5750 3600 50  0000 C CNN
F 1 "74HC04" H 5750 3500 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 5750 3550 50  0001 C CNN
F 3 "" H 5750 3550 60  0001 C CNN
	7    5750 3550
	1    0    0    -1  
$EndComp
Text GLabel 5750 3050 1    39   BiDi ~ 0
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
L GND #PWR035
U 1 1 5C2E9245
P 5650 4050
F 0 "#PWR035" H 5650 3800 50  0001 C CNN
F 1 "GND" H 5650 3900 50  0000 C CNN
F 2 "" H 5650 4050 60  0001 C CNN
F 3 "" H 5650 4050 60  0001 C CNN
	1    5650 4050
	0    1    1    0   
$EndComp
Wire Wire Line
	5650 4050 5750 4050
Text GLabel 2750 3250 0    39   BiDi ~ 0
mR/~W
Text GLabel 3350 3250 2    39   BiDi ~ 0
~mOE
Text GLabel 8350 2650 3    39   BiDi ~ 0
~mOE
Text GLabel 10000 2650 3    39   BiDi ~ 0
~mOE
Text GLabel 10000 5550 3    39   BiDi ~ 0
~mOE
Text GLabel 8350 5550 3    39   BiDi ~ 0
~mOE
Text GLabel 4550 5700 2    39   BiDi ~ 0
~S4
Text GLabel 4550 5800 2    39   BiDi ~ 0
RD4
Text GLabel 4550 5900 2    39   BiDi ~ 0
~S5
Text GLabel 4550 6000 2    39   BiDi ~ 0
RD5
Text GLabel 3650 6000 0    39   BiDi ~ 0
mRD5
Text GLabel 3650 5900 0    39   BiDi ~ 0
~mS5
Text GLabel 3650 5800 0    39   BiDi ~ 0
mRD4
Text GLabel 3650 5700 0    39   BiDi ~ 0
~mS4
$Comp
L TXB0108-PW U6
U 1 1 5C374049
P 2900 1600
F 0 "U6" H 2700 2350 60  0000 L CNN
F 1 "TXB0108-PW" H 2700 850 60  0000 L CNN
F 2 "Housings_SSOP:SSOP-20_4.4x6.5mm_Pitch0.65mm" H 2700 1550 60  0001 C CNN
F 3 "" H 2900 1600 60  0001 C CNN
	1    2900 1600
	1    0    0    -1  
$EndComp
Text GLabel 3400 1000 2    39   BiDi ~ 0
VCC5V
$Comp
L GND #PWR036
U 1 1 5C374058
P 2500 2200
F 0 "#PWR036" H 2500 1950 50  0001 C CNN
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
NoConn ~ 4550 6100
NoConn ~ 4550 6200
NoConn ~ 3650 6200
NoConn ~ 3650 6100
Text GLabel 1000 3250 0    39   BiDi ~ 0
mA13
Text GLabel 1600 3250 2    39   BiDi ~ 0
~mA13
Text GLabel 1000 3650 0    39   BiDi ~ 0
mA11
Text GLabel 1600 3650 2    39   BiDi ~ 0
~mA11
Text GLabel 1000 4450 0    39   BiDi ~ 0
mA8
Text GLabel 1600 4450 2    39   BiDi ~ 0
~mA8
Text GLabel 2750 4250 0    39   BiDi ~ 0
mD3XX
Text GLabel 3350 4250 2    39   BiDi ~ 0
~mD3XX
$Comp
L 74HC04 U7
U 1 1 5C2DFE46
P 1300 4050
F 0 "U7" H 1300 4100 50  0000 C CNN
F 1 "74HC04" H 1300 4000 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 1300 4050 50  0001 C CNN
F 3 "" H 1300 4050 60  0001 C CNN
	1    1300 4050
	1    0    0    -1  
$EndComp
Text GLabel 1600 4050 2    39   BiDi ~ 0
~mA10
$Comp
L 74HC04 U2
U 7 1 5C420D5D
P 5750 4550
F 0 "U2" H 5750 4600 50  0000 C CNN
F 1 "74HC04" H 5750 4500 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 5750 4550 50  0001 C CNN
F 3 "" H 5750 4550 60  0001 C CNN
	7    5750 4550
	-1   0    0    1   
$EndComp
Text GLabel 5750 5050 3    39   BiDi ~ 0
VCC3V3
Connection ~ 5750 4050
Text GLabel 2750 3750 0    39   BiDi ~ 0
mD6XX
Text GLabel 3350 3750 2    39   BiDi ~ 0
~mD6XX
$Comp
L 74HC04 U9
U 1 1 5C4210C2
P 3050 3750
F 0 "U9" H 3050 3800 50  0000 C CNN
F 1 "74HC04" H 3050 3700 50  0000 C CNN
F 2 "Housings_SSOP:TSSOP-14_4.4x5mm_Pitch0.65mm" H 3050 3750 50  0001 C CNN
F 3 "" H 3050 3750 60  0001 C CNN
	1    3050 3750
	1    0    0    -1  
$EndComp
Wire Notes Line
	600  3050 3750 3050
Wire Notes Line
	3750 3050 3750 4750
Wire Notes Line
	3750 4750 600  4750
Wire Notes Line
	600  4750 600  3050
Wire Notes Line
	5450 2950 5450 650 
Text GLabel 7150 2150 0    39   BiDi ~ 0
mD1E0_A8
Text GLabel 7150 2250 0    39   BiDi ~ 0
mD1E0_A9
Text GLabel 7150 2350 0    39   BiDi ~ 0
mD1E0_A10
Text GLabel 7150 2450 0    39   BiDi ~ 0
mD1E0_A11
Text GLabel 7150 2550 0    39   BiDi ~ 0
mD1E0_A12
Text GLabel 7150 2650 0    39   BiDi ~ 0
mD1E0_A13
Text GLabel 7150 2750 0    39   BiDi ~ 0
mD1E0_A14
Text GLabel 8800 2150 0    39   BiDi ~ 0
mD1E0_A8
Text GLabel 8800 2250 0    39   BiDi ~ 0
mD1E0_A9
Text GLabel 8800 2350 0    39   BiDi ~ 0
mD1E0_A10
Text GLabel 8800 2450 0    39   BiDi ~ 0
mD1E0_A11
Text GLabel 8800 2550 0    39   BiDi ~ 0
mD1E0_A12
Text GLabel 8800 2650 0    39   BiDi ~ 0
mD1E0_A13
Text GLabel 8800 2750 0    39   BiDi ~ 0
mD1E0_A14
Text GLabel 8800 3050 0    39   BiDi ~ 0
mD1E2_A17
Text GLabel 8800 3150 0    39   BiDi ~ 0
mD1E2_A18
Text GLabel 7150 5050 0    39   BiDi ~ 0
mD1E0_A8
Text GLabel 7150 5150 0    39   BiDi ~ 0
mD1E0_A9
Text GLabel 7150 5250 0    39   BiDi ~ 0
mD1E0_A10
Text GLabel 7150 5350 0    39   BiDi ~ 0
mD1E0_A11
Text GLabel 7150 5450 0    39   BiDi ~ 0
mD1E0_A12
Text GLabel 7150 5550 0    39   BiDi ~ 0
mD1E0_A13
Text GLabel 7150 5650 0    39   BiDi ~ 0
mD1E0_A14
Text GLabel 7150 5750 0    39   BiDi ~ 0
mD1E0_A15
Text GLabel 7150 5850 0    39   BiDi ~ 0
mD1E2_A16
Text GLabel 7150 5950 0    39   BiDi ~ 0
mD1E2_A17
Text GLabel 7150 6050 0    39   BiDi ~ 0
mD1E2_A18
Text GLabel 8800 5050 0    39   BiDi ~ 0
mD1E0_A8
Text GLabel 8800 5150 0    39   BiDi ~ 0
mD1E0_A9
Text GLabel 8800 5250 0    39   BiDi ~ 0
mD1E0_A10
Text GLabel 8800 5350 0    39   BiDi ~ 0
mD1E0_A11
Text GLabel 8800 5450 0    39   BiDi ~ 0
mD1E0_A12
Text GLabel 8800 5550 0    39   BiDi ~ 0
mD1E0_A13
Text GLabel 8800 5650 0    39   BiDi ~ 0
mD1E0_A14
Text GLabel 8800 5750 0    39   BiDi ~ 0
mD1E0_A15
Text GLabel 8800 5850 0    39   BiDi ~ 0
mD1E2_A16
Text GLabel 8800 5950 0    39   BiDi ~ 0
mD1E2_A17
Text GLabel 8800 6050 0    39   BiDi ~ 0
mD1E2_A18
Text GLabel 7150 2950 0    39   BiDi ~ 0
mD1E2_A16
Text GLabel 7150 2850 0    39   BiDi ~ 0
mD1E0_A15
Text GLabel 8800 2850 0    39   BiDi ~ 0
mD1E0_A15
Text GLabel 7150 3050 0    39   BiDi ~ 0
mD1E2_A17
Text GLabel 8800 2950 0    39   BiDi ~ 0
mD1E2_A16
Text GLabel 7150 3150 0    39   BiDi ~ 0
mD1E2_A18
$EndSCHEMATC
