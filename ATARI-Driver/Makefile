# Makefile
CL ?= cl65
MACH ?= atarixl
TARGET ?= megaram.com
EMULATOR ?= atari800
ATRFOLDER ?= ~/ATARI/ATR
ROM ?= ~/ATARI/ATARIXL.ROM
ROMSWITCH ?= -xlxe_rom
MACHINE ?= 320xe
DEFINES ?= ATARIXL

EMUWINSIZE ?= \
	-win-width 800 \
	-win-height 600 \


VIDEOATTR ?= \
	-scanlines 50 \
	-scanlinesint \


ifeq ($(MACH),atari)
	ROM = ~/ATARI/ATARIOSB.ROM
	ROMSWITCH = -osb_rom
	DEFINES = ATARI
	
endif

ifeq ($(MACH),c64)
	ROM = 
	ROMSWITCH = 
	DEFINES = CBM
	MACHINE =
	EMULATOR = x64
	EMUWINSIZE =
	VIDEOATTR =
		
endif

EMUSWITCHES = \
	$(EMUWINSIZE) \
	$(ROMSWITCH) $(ROM) \
	$(MACHINE) \
	$(VIDEOATTR) \
	$(TARGET)

C_SOURCES = \
	memaccess.c \
#	megaram.c \


ASM_SOURCES =


all: $(TARGET)

$(TARGET): memsize $(C_SOURCES)
	$(CL) -Osir -o $(TARGET) -t $(MACH) -D$(DEFINES) $(C_SOURCES) $(ASM_SOURCES)

# Build MEMSIZEK C variable
memsize:
	@echo "#define MEMSIZEK $(MEMSIZEK)" > version.h

build: $(TARGET)
	$(EMULATOR) $(EMUSWITCHES)

atr: $(TARGET)
	cp $(TARGET) $(ATRFOLDER)/build/mypdos-406.ar0
	dir2atr -a -b MyPicoDos406 $(ATRFOLDER)/memorytester-xe.atr $(ATRFOLDER)/build

clean:
	rm *.o
	rm version.h
	rm $(TARGET)
