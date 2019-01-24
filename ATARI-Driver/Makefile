# Makefile
CL ?= cl65
MACH ?= atari
TARGET ?= megaram.sys
EMULATOR ?= atari800
MEMSIZEK ?= 512
DISABLE_EXPANSION ?= no

# Usually this software can run on emulator and using the -retrobit switch
# to enable to memory expansion driver.

ifeq ($(DISABLE_EXPANSION),yes)
	EMUSWITCHES = -win-width 800 \
	-win-height 600 \
	-xlxe_rom ~/ATARI/ATARIXL.ROM \
	-scanlines 50 \
	-scanlinesint \
	$(TARGET)
else
	EMUSWITCHES = -win-width 800 \
	-win-height 600 \
	-xlxe_rom ~/ATARI/ATARIXL.ROM \
	-retrobit $(MEMSIZEK) \
	-scanlines 50 \
	-scanlinesint \
	$(TARGET)
endif

C_SOURCES = \
	megaram.c \


ASM_SOURCES =


all: $(TARGET)

$(TARGET): memsize megaram.c
	$(CL) -t $(MACH) $(C_SOURCES) $(ASM_SOURCES) -o $(TARGET)

# Build MEMSIZEK C variable
memsize:
	@echo "#define MEMSIZEK $(MEMSIZEK)" > version.h

build: $(TARGET)
	$(EMULATOR) $(EMUSWITCHES) $(TARGET)

clean:
	rm *.o
	rm version.h
	rm $(TARGET)
