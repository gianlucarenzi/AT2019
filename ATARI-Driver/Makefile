# Makefile
CL ?= cl65
MACH ?= atari
TARGET ?= megaram.sys
EMULATOR ?= atari800
MEMSIZEK ?= 512

EMUSWITCHES ?= -win-width 800 \
-win-height 600 \
-xlxe_rom ~/ATARI/ATARIXL.ROM \
-retrobit $(MEMSIZEK) \
$(TARGET)

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
	rm $(TARGET)
