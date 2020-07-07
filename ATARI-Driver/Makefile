# Makefile
CL ?= cl65
MACH ?= atarixl
TARGET ?= megaram.com
EMULATOR ?= atari800
ATRFOLDER ?= ~/ATARI/ATR
ROM ?= ~/ATARI/ATARIXL.ROM
ROMSWITCH ?= -xlxe_rom
MACHINE ?= 320xe
DEFINES ?= RETROBIT

ifeq ($(MACH),atari)
	ROM = ~/ATARI/ATARIOSB.ROM
	ROMSWITCH = -osb_rom
	DEFINES += -DATARI800 \
	
endif

EMUSWITCHES = \
	-win-width 800 \
	-win-height 600 \
	$(ROMSWITCH) $(ROM) \
	-$(MACHINE) \
	-scanlines 50 \
	-scanlinesint \
	$(TARGET)

C_SOURCES = \
	megaram.c \


ASM_SOURCES =


all: $(TARGET)

$(TARGET): memsize megaram.c
	$(CL) -Oi -t $(MACH) -D$(DEFINES) $(C_SOURCES) $(ASM_SOURCES) -o $(TARGET)

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
