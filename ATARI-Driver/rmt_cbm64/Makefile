# Makefile - RMT CBM64: RMT modules played on the Commodore 64 SID
#
#   make                          build/rmt_cbm64.prg and build/rmt_cbm64.d64
#   make run                      autostart the D64 in VICE (x64sc)
#   make SONG=music/other.rmt     another RMT4 module (instrument speed 1)
#   make clean
#
# The player is the Atari RMT routine (src/rmtplayr.s, same source as
# ../RmtSkeleton and ../PokeyATest) assembled with -D RMT_C64.

CL       ?= cl65
PYTHON   ?= python3
C1541    ?= c1541
EMULATOR ?= x64sc

BUILD  = build
TARGET = $(BUILD)/rmt_cbm64.prg
D64    = $(BUILD)/rmt_cbm64.d64
CFG    = src/rmt_cbm64.cfg

SONG ?= music/gemx.rmt
# directory entry on the disk, max 16 characters (c1541 turns lowercase
# ASCII into uppercase PETSCII)
DISKNAME ?= rmt player

all: $(TARGET) $(D64)

# build/song.cfg changes when SONG does, so "make SONG=x" then "make" rebuilds
$(BUILD)/song.cfg: FORCE
	@mkdir -p $(BUILD)
	@echo '$(SONG)' | cmp -s - $@ || echo '$(SONG)' > $@

$(BUILD)/song.s: $(SONG) $(BUILD)/song.cfg tools/rmt2ca65.py
	$(PYTHON) tools/rmt2ca65.py $(SONG) $@ _rmt_song_data

$(BUILD)/sidtab.s: tools/mksidtab.py
	@mkdir -p $(BUILD)
	$(PYTHON) tools/mksidtab.py $@

$(BUILD)/sidtab.o: $(BUILD)/sidtab.s
	$(CL) -t c64 -c -o $@ $<

$(BUILD)/main.o: src/main.c src/sid.h
	@mkdir -p $(BUILD)
	$(CL) -t c64 -Osir -c -o $@ src/main.c

$(BUILD)/rmtplayr.o: src/rmtplayr.s src/rmt_feat.inc
	@mkdir -p $(BUILD)
	$(CL) -t c64 -c --asm-define RMT_C64 --asm-include-dir src -o $@ src/rmtplayr.s

$(BUILD)/sidrmt.o: src/sidrmt.s
	@mkdir -p $(BUILD)
	$(CL) -t c64 -c -o $@ src/sidrmt.s

$(BUILD)/song.o: $(BUILD)/song.s
	$(CL) -t c64 -c -o $@ $<

OBJS = $(BUILD)/main.o $(BUILD)/sidrmt.o $(BUILD)/rmtplayr.o $(BUILD)/sidtab.o $(BUILD)/song.o

$(TARGET): $(OBJS) $(CFG)
	$(CL) -t c64 -C $(CFG) -m $(BUILD)/rmt_cbm64.map -o $@ $(OBJS)

$(D64): $(TARGET)
	rm -f $@
	$(C1541) -format "rmt cbm64,01" d64 $@ -write $(TARGET) "$(DISKNAME)" -list

run: $(D64)
	$(EMULATOR) -autostart $(D64)

clean:
	rm -rf $(BUILD)

.PHONY: all run clean FORCE
