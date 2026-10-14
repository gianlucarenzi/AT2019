# Makefile - RMT CBM64: RMT modules played on the Commodore 64 SID
#
#   make                          build/rmt_cbm64.prg and build/rmt_cbm64.d64
#   make run                      autostart the D64 in VICE (x64sc)
#   make SONG=music/other.rmt     another RMT4 module
#   make SONG=music/gemx.sap      a SAP or XEX exported by RITMO / RMT: its
#                                 LZSS streams played by src/lzsplayr.s
#   make SONG=x.sap SUBSONG=1     another subtune of the file
#   make rmtplay [NAME=.. AUTHOR=.. DATE=..]
#                                 build/rmtplay.prg and build/rmtplay.d64: the
#                                 player with a visualizer (./rmtplay.sh runs it)
#   make clean
#
# The player is the Atari RMT routine (src/rmtplayr.s, same source as
# ../RmtSkeleton and ../PokeyATest) assembled with -D RMT_C64; for a .sap or
# .xex song it is src/lzsplayr.s (same source as ../RmtSkeleton), the same
# interface.

CL       ?= cl65
PYTHON   ?= python3
C1541    ?= c1541
EMULATOR ?= x64sc

BUILD  = build
TARGET = $(BUILD)/rmt_cbm64.prg
D64    = $(BUILD)/rmt_cbm64.d64
CFG    = src/rmt_cbm64.cfg

SONG ?= music/gemx.rmt
SUBSONG ?= 0

# a .sap or .xex exported by RITMO / RMT: the VU-Player LZSS streams
ifneq ($(filter .sap .SAP .xex .XEX,$(suffix $(SONG))),)
LZSS   = 1
PLAYER = src/lzsplayr.s
else
PLAYER = src/rmtplayr.s
endif
# directory entry on the disk, max 16 characters (c1541 turns lowercase
# ASCII into uppercase PETSCII)
DISKNAME ?= rmt player

# RMTPLAY: the same player with a visualizer (src/rmtplay.c); song name,
# author and date from the text in the .rmt (tools/rmtinfo.py) unless given
RMTPLAY     = $(BUILD)/rmtplay.prg
RMTPLAY_D64 = $(BUILD)/rmtplay.d64
NAME   ?=
AUTHOR ?=
DATE   ?=

all: $(TARGET) $(D64) $(RMTPLAY) $(RMTPLAY_D64)

rmtplay: $(RMTPLAY) $(RMTPLAY_D64)

# build/song.cfg changes when SONG (or SUBSONG) does, so "make SONG=x" then
# "make" rebuilds; the player and rmtplay.c follow it too (RMT or LZSS)
$(BUILD)/song.cfg: FORCE
	@mkdir -p $(BUILD)
	@echo '$(SONG) $(SUBSONG)' | cmp -s - $@ || echo '$(SONG) $(SUBSONG)' > $@

$(BUILD)/song.s: $(SONG) $(BUILD)/song.cfg tools/rmt2ca65.py tools/sap2ca65.py
ifdef LZSS
	$(PYTHON) tools/sap2ca65.py $(SONG) $@ _rmt_song_data --subsong $(SUBSONG)
else
	$(PYTHON) tools/rmt2ca65.py $(SONG) $@ _rmt_song_data
endif

$(BUILD)/sidtab.s: tools/mksidtab.py
	@mkdir -p $(BUILD)
	$(PYTHON) tools/mksidtab.py $@

$(BUILD)/sidtab.o: $(BUILD)/sidtab.s
	$(CL) -t c64 -c -o $@ $<

$(BUILD)/main.o: src/main.c src/sid.h
	@mkdir -p $(BUILD)
	$(CL) -t c64 -Osir -c -o $@ src/main.c

$(BUILD)/rmtplayr.o: $(PLAYER) src/rmt_feat.inc $(BUILD)/song.cfg
	@mkdir -p $(BUILD)
	$(CL) -t c64 -c --asm-define RMT_C64 --asm-include-dir src -o $@ $(PLAYER)

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

# song info options kept in a stamp file: changing them regenerates the header
$(BUILD)/songinfo.cfg: FORCE
	@mkdir -p $(BUILD)
	@printf '%s\n' '$(SONG)|$(NAME)|$(AUTHOR)|$(DATE)' | cmp -s - $@ || \
		printf '%s\n' '$(SONG)|$(NAME)|$(AUTHOR)|$(DATE)' > $@

$(BUILD)/songinfo.h: $(SONG) $(BUILD)/songinfo.cfg $(BUILD)/song.cfg tools/rmtinfo.py tools/sap2ca65.py
ifdef LZSS
	$(PYTHON) tools/sap2ca65.py $(SONG) /dev/null --subsong $(SUBSONG) --info $@ \
		--name "$(NAME)" --author "$(AUTHOR)" --date "$(DATE)"
else
	$(PYTHON) tools/rmtinfo.py $(SONG) $@ --name "$(NAME)" --author "$(AUTHOR)" --date "$(DATE)"
endif

$(BUILD)/rmtplay.o: src/rmtplay.c src/sid.h $(BUILD)/songinfo.h $(BUILD)/song.cfg
	$(CL) -t c64 -Osir -I $(BUILD) $(if $(LZSS),-DRMT_LZSS) -c -o $@ src/rmtplay.c

RMTPLAY_OBJS = $(BUILD)/rmtplay.o $(BUILD)/sidrmt.o $(BUILD)/rmtplayr.o $(BUILD)/sidtab.o $(BUILD)/song.o

$(RMTPLAY): $(RMTPLAY_OBJS) $(CFG)
	$(CL) -t c64 -C $(CFG) -m $(BUILD)/rmtplay.map -o $@ $(RMTPLAY_OBJS)

$(RMTPLAY_D64): $(RMTPLAY)
	rm -f $@
	$(C1541) -format "rmt cbm64,01" d64 $@ -write $(RMTPLAY) "rmtplay" -list

run: $(D64)
	$(EMULATOR) -autostart $(D64)

clean:
	rm -rf $(BUILD)

.PHONY: all rmtplay run clean FORCE
