# Makefile
CL ?= cl65
MACH ?= atarixl
TARGET ?= megaram.com
EMULATOR ?= atari800
ATRFOLDER ?= ~/ATARI/ATR
ROM ?= ~/ATARI/ATARIXL.ROM
ROMSWITCH ?= -xlxe_rom
MACHINE ?= -576xe
DEFINES ?= ATARIXL

# CC65 Useful environment variables if not defined by the
# system/environment shell

#CC65_HOME ?= $(HOME)/bin
#CC65_DATADIR ?= $(HOME)/share/cc65

#CA65_INC = $(CC65_DATADIR)/asminc
#CC65_INC = $(CC65_DATADIR)/include
#CL65_TGT = $(CC65_DATADIR)/target
#LD65_LIB = $(CC65_DATADIR)/lib
#LD65_OBJ = $(CC65_DATADIR)/lib
#LD65_CFG = $(CC65_DATADIR)/cfg

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
	MACHINE =

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


ASM_SOURCES =

#INCDIR = -I$(CC65_INC) \
#	-I$(CA65_INC) \

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
