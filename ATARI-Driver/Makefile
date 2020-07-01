# Makefile
CL ?= cl65
MACH ?= atari
TARGET ?= atari130xe_576k.com
EMULATOR ?= atari800
DISABLE_EXPANSION ?= no
ATRFOLDER ?= ~/ATARI/ATR

# Usually this software can run on emulator and using the -retrobit switch
# to enable to memory expansion driver.

ifeq ($(DISABLE_EXPANSION),yes)
	EMUSWITCHES = -win-width 800 \
	-win-height 600 \
	-xlxe_rom ~/ATARI/ATARIXL.ROM \
	-scanlines 50 \
	-scanlinesint \
	-xe \
	$(TARGET)
	
	DEFINES += M192K
else
	EMUSWITCHES = -win-width 800 \
	-win-height 600 \
	-xlxe_rom ~/ATARI/ATARIXL.ROM \
	-scanlines 50 \
	-scanlinesint \
	-320xe \
	$(TARGET)
	
	DEFINES += M576K
endif

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
	$(EMULATOR) $(EMUSWITCHES) $(TARGET)

atr: $(TARGET)
	cp $(TARGET) $(ATRFOLDER)/build/mypdos-406.ar0
	dir2atr -a -b MyPicoDos406 $(ATRFOLDER)/memorytester-xe.atr $(ATRFOLDER)/build

clean:
	rm *.o
	rm version.h
	rm $(TARGET)
