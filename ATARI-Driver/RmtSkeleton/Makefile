# Makefile - RmtSkeleton: minimal RMT player example
#
# Usage:
#   make              build the executable (rmtskeleton.atr)
#   make run          build and run in atari800 emulator
#   make SONG=music/other.rmt   use a different RMT song
#   make clean        remove build artifacts

CL ?= cl65
PYTHON ?= python3
EMULATOR ?= atari800

# Machine target and ROM
MACHINE ?= -xl
ROMSWITCH ?= -xlxe_rom
ROM ?= ~/ATARI/ATARIXL.ROM
VIDEO ?= -pal

# Build directories
BUILD = build
TARGET = $(BUILD)/rmtskeleton.com

# RMT song (change with: make SONG=music/other.rmt)
SONG ?= music/gemx.rmt
SONGNAME = $(basename $(notdir $(SONG)))

# Source files
C_SOURCES = src/main.c

ASM_SOURCES = \
	src/rmtplayr.s \
	src/rmtvbi.s \
	$(BUILD)/song.s \

all: $(TARGET)

# Convert RMT file to relocatable ca65 source
$(BUILD)/song.s: $(SONG) tools/rmt2ca65.py
	@mkdir -p $(BUILD)
	$(PYTHON) tools/rmt2ca65.py $(SONG) $@

# Link the executable
$(TARGET): $(C_SOURCES) $(ASM_SOURCES) src/rmtskeleton.cfg
	@mkdir -p $(BUILD)
	$(CL) -t atari -C src/rmtskeleton.cfg -o $@ $(C_SOURCES) $(ASM_SOURCES) -m $(BUILD)/rmtskeleton.map
	@echo "Build complete: $@"

# Run in emulator (no SIO patch: real serial timing)
run: $(TARGET)
	$(EMULATOR) $(ROMSWITCH) $(ROM) $(MACHINE) $(VIDEO) -nobasic -nopatchall $<

# Clean up
clean:
	rm -rf $(BUILD)

.PHONY: all run clean
