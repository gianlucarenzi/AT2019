# Makefile - RmtSkeleton: minimal RMT player example
#
# Usage:
#   make              build the executable (build/rmtskeleton.com)
#   make run          build and run in atari800 emulator
#   make SONG=music/other.rmt   use a different RMT song
#   make SONG=music/gemx.sap    play a SAP or XEX exported by RITMO / RMT:
#                               its LZSS streams with src/lzsplayr.s
#   make SONG=x.sap SUBSONG=1   another subtune of the file
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
SUBSONG ?= 0

# A .sap or .xex exported by RITMO / RMT (VU-Player LZSS streams) is played by
# src/lzsplayr.s, the same interface as src/rmtplayr.s
ifneq ($(filter .sap .SAP .xex .XEX,$(suffix $(SONG))),)
PLAYER  = src/lzsplayr.s
SONG_S  = $(PYTHON) tools/sap2ca65.py $(SONG) $@ --subsong $(SUBSONG)
SONG_PY = tools/sap2ca65.py
else
PLAYER  = src/rmtplayr.s
SONG_S  = $(PYTHON) tools/rmt2ca65.py $(SONG) $@
SONG_PY = tools/rmt2ca65.py
endif

# Source files
C_SOURCES = src/main.c

ASM_SOURCES = \
	$(PLAYER) \
	src/rmtvbi.s \
	$(BUILD)/song.s \

all: $(TARGET)

# build/song.cfg changes when SONG or SUBSONG does, so "make SONG=x" then
# "make" rebuilds even when the new song file is older than build/song.s
$(BUILD)/song.cfg: FORCE
	@mkdir -p $(BUILD)
	@echo '$(SONG) $(SUBSONG)' | cmp -s - $@ || echo '$(SONG) $(SUBSONG)' > $@

# Convert the song to relocatable ca65 source
$(BUILD)/song.s: $(SONG) $(SONG_PY) $(BUILD)/song.cfg
	@mkdir -p $(BUILD)
	$(SONG_S)

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

.PHONY: all run clean FORCE
