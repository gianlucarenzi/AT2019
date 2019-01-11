# Makefile
CL ?= cl65
MACH ?= atari
TARGET ?= megaram.sys
EMULATOR ?= atari800

EMUSWITCHES ?= -win-width 800 \
-win-height 600 \
-xlxe_rom ~/ATARI/ATARIXL.ROM \
$(TARGET)

C_SOURCES = \
	megaram.c \

ASM_SOURCES =

all: $(TARGET)

$(TARGET): megaram.c
	$(CL) -t $(MACH) $(C_SOURCES) $(ASM_SOURCES) -o $(TARGET)

build: $(TARGET)
	$(EMULATOR) $(EMUSWITCHES) $(TARGET)

clean:
	rm *.o
	rm $(TARGET)
