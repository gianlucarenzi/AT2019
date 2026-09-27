# Makefile - RMT CBM64: Commodore 64 RMT Music Player
#
# Usage:
#   make              build the executable (rmt_cbm64.prg)
#   make run          build and run in VICE emulator
#   make SONG=music/other.rmt   use a different RMT song
#   make clean        remove build artifacts

# Build environment (force cc65, not system cc)
export PATH:=/usr/bin:$(PATH)

CL  ?= /usr/bin/cl65
CC  ?= /usr/bin/cc65
AS  ?= /usr/bin/ca65
PYTHON ?= python3
EMULATOR ?= x64

# Build directories
BUILD = build
TARGET = $(BUILD)/rmt_cbm64.prg

# RMT song (change with: make SONG=music/other.rmt)
SONG ?= music/example.rmt

# Source files
C_SOURCES = src/main.c

ASM_SOURCES = \
	src/sidplayer.s \
	src/sidvbi.s \
	$(BUILD)/rmt_data.s

OBJS = \
	$(BUILD)/main.o \
	$(BUILD)/sidplayer.o \
	$(BUILD)/sidvbi.o \
	$(BUILD)/rmt_data.o

# ============================================================================
# Targets
# ============================================================================

all: $(TARGET)

# Convert RMT file to relocatable ca65 source
$(BUILD)/rmt_data.s: $(SONG) tools/rmt2cbm64.py
	@mkdir -p $(BUILD)
	$(PYTHON) tools/rmt2cbm64.py $(SONG) $@

# Compile C source files
$(BUILD)/main.o: src/main.c src/sid.h
	@mkdir -p $(BUILD)
	/usr/bin/cc65 -t c64 src/main.c -o build/main.s
	/usr/bin/ca65 -t c64 build/main.s -o $@

# Assemble ASM sources
$(BUILD)/sidplayer.o: src/sidplayer.s
	@mkdir -p $(BUILD)
	/usr/bin/ca65 -t c64 src/sidplayer.s -o $@

$(BUILD)/sidvbi.o: src/sidvbi.s
	@mkdir -p $(BUILD)
	/usr/bin/ca65 -t c64 src/sidvbi.s -o $@

$(BUILD)/rmt_data.o: $(BUILD)/rmt_data.s
	@mkdir -p $(BUILD)
	/usr/bin/ca65 -t c64 $(BUILD)/rmt_data.s -o $@

# Link final executable
$(TARGET): $(OBJS) src/rmt_cbm64.cfg
	/usr/bin/cl65 -t c64 -C src/rmt_cbm64.cfg -o $@ $(OBJS) -m $(BUILD)/rmt_cbm64.map
	@echo ""
	@echo "✓ Build complete: $@"
	@echo ""

# Create D64 disk image with autorun
D64_IMAGE = $(BUILD)/rmt_cbm64.d64

$(D64_IMAGE): $(TARGET)
	@echo "🔧 Creating D64 disk image..."
	@c1541 -format "RMT CBM64,00" d64 $@ > /dev/null 2>&1
	@echo "📝 Adding program..."
	@c1541 -attach $@ -write $(TARGET) "RMT PLAYER" > /dev/null 2>&1
	@echo "✓ D64 disk created: $@"

# Run in VICE with PRG direct load
run: $(TARGET) $(D64_IMAGE)
	@echo ""
	@echo "╔═══════════════════════════════════════════════╗"
	@echo "║  RMT CBM64 - VICE Emulator Launcher           ║"
	@echo "╚═══════════════════════════════════════════════╝"
	@echo ""
	@echo "📀 PRG:  $(TARGET)"
	@echo "🎮 Launching VICE x64..."
	@echo ""
	@echo "💡 VICE Keyboard Shortcuts:"
	@echo "   Ctrl+H  → Monitor (debugger)"
	@echo "   Alt+P   → Pause"
	@echo "   Alt+R   → Reset"
	@echo "   Esc     → Exit menu"
	@echo ""
	@nohup $(EMULATOR) -autostart $(TARGET) > /dev/null 2>&1 &
	@sleep 1
	@echo "✓ VICE started!"

# Run PRG directly (faster, no disk)
run-direct: $(TARGET)
	@echo "🎮 Launching VICE x64 (direct PRG load)..."
	@$(EMULATOR) $(TARGET) 2>/dev/null &
	@sleep 2

# Clean up
clean:
	rm -rf $(BUILD)

.PHONY: all run run-direct clean
