# Makefile - PokeyATest: RMT player on VBI + SIO asset loader
#
# make            build build/pokeyatest.atr (bootable, MyPicoDos autorun)
# make run        launch atari800 with the SIO patch OFF (real serial timing):
#                 the program is run directly (-run, as ../RmtSkeleton), the
#                 disk is in D1: for the test assets
# make SONG=music/other.rmt
# make SONG=music/gemx.sap  a SAP or XEX exported by RITMO / RMT: its LZSS
#                           streams with src/lzsplayr.s (SUBSONG=n: subtune)
# make SONG=music/claude_3ch_stereo_speed_4.rmt   an RMT8 (stereo) song, or a
#                           stereo SAP / XEX: channels 5-8 go to the VERA PSG
#                           if there is a VeraX16 card, else to a second POKEY,
#                           else they are not heard
# make run EMUSTEREO=-stereo   atari800 with a second POKEY
# make ASSET_SIZES="2048 4096 16384"   generated test assets (empty = none)
# make ASSETS_DIR=path/to/files        your assets (default: assets/, see doc/GUIDA.md)
# make clean all DEFS=-DTEST_NOMUSIC    baseline: loader without the music player
# make clean all DEFS=-DSTOP_ON_ERROR   freeze the screen at the first load error
CL ?= cl65
MACH ?= atari
PYTHON ?= python3
EMULATOR ?= atari800
DIR2ATR ?= dir2atr
BOOTDOS ?= MyPicoDos406N
ROM ?= ~/ATARI/ATARIXL.ROM
ROMSWITCH ?= -xlxe_rom
MACHINE ?= -xl
VIDEO ?= -pal

DEFS ?=

SONG ?= music/gemx.rmt
SUBSONG ?= 0

# A .sap or .xex exported by RITMO / RMT (VU-Player LZSS streams) is played by
# src/lzsplayr.s, the same interface as src/rmtplayr.s
ifneq ($(filter .sap .SAP .xex .XEX,$(suffix $(SONG))),)
PLAYER  = src/lzsplayr.s
SONG_S  = $(PYTHON) tools/sap2ca65.py $(SONG) $@ --subsong $(SUBSONG)
SONG_PY = tools/sap2ca65.py
TRACKS := $(shell $(PYTHON) tools/sap2ca65.py $(SONG) --tracks)
else
PLAYER  = src/rmtplayr.s
SONG_S  = $(PYTHON) tools/rmt2ca65.py $(SONG) $@
SONG_PY = tools/rmt2ca65.py
TRACKS := $(shell $(PYTHON) -c "d=open('$(SONG)','rb').read(10); print(8 if d[6:10]==b'RMT8' else 4)")
endif
# 4 tracks (RMT4, mono SAP) or 8 (RMT8, stereo SAP): an 8 track song also
# links the VERA PSG output (src/psgrmt.s and its frequency tables)
ifeq ($(TRACKS),8)
PSG_SOURCES = src/psgrmt.s $(BUILD)/psgtab.s
endif
# generated test assets, sizes in bytes: 2K..16K, also not multiple of a sector
ASSET_SIZES ?= 2048 3500 5120 8000 12288 16384
# your assets: every file of this directory goes on the disk and in the test
# loop. DOS 8.3 names (letters/digits, case ignored), 1..16384 bytes each,
# no spaces in file names
ASSETS_DIR ?= assets
MY_ASSETS = $(sort $(wildcard $(ASSETS_DIR)/*))
# DOS 2.x sector links are 10 bit: the loader is tested up to 1023 sectors
MAXSECTORS ?= 1023

BUILD = build
DISK = $(BUILD)/disk
TARGET = $(DISK)/PKATEST.COM
ATR = $(BUILD)/pokeyatest.atr

EMUWINSIZE ?= \
	-win-width 800 \
	-win-height 600 \

# -nopatchall: no SIO patch (overrides ENABLE_SIO_PATCH=1 in ~/.atari800.cfg)
# nor any other OS patch: disk I/O goes through the real POKEY serial emulation
EMUSWITCHES = \
	$(EMUWINSIZE) \
	$(ROMSWITCH) $(ROM) \
	$(MACHINE) \
	$(VIDEO) \
	$(EMUSTEREO) \
	-nobasic \
	-nopatchall \
	-run $(TARGET) \
	$(ATR)

C_SOURCES = \
	src/main.c \
	src/dos2fs.c \

ASM_SOURCES = \
	$(PLAYER) \
	src/rmtvbi.s \
	src/sio.s \
	$(BUILD)/song.s \
	$(PSG_SOURCES) \

SONGNAME = $(basename $(notdir $(SONG)))

all: $(ATR)

# build/song.cfg changes when SONG or SUBSONG does, so "make SONG=x" then
# "make" rebuilds even when the new song file is older than build/song.s
$(BUILD)/song.cfg: FORCE
	@mkdir -p $(BUILD)
	@echo '$(SONG) $(SUBSONG) $(TRACKS)' | cmp -s - $@ || echo '$(SONG) $(SUBSONG) $(TRACKS)' > $@

$(BUILD)/song.s: $(SONG) $(SONG_PY) $(BUILD)/song.cfg
	@mkdir -p $(BUILD)
	$(SONG_S)

# the asset list and sizes are kept in a stamp file, so adding/removing a
# file or changing ASSET_SIZES on the command line rebuilds the disk
ASSETS_CFG = sizes=$(ASSET_SIZES) files=$(MY_ASSETS)

$(BUILD)/assets.cfg: FORCE
	@mkdir -p $(BUILD)
	@echo '$(ASSETS_CFG)' | cmp -s - $@ || echo '$(ASSETS_CFG)' > $@

$(BUILD)/assets.h: $(BUILD)/assets.cfg $(MY_ASSETS) tools/mkassets.py
	@mkdir -p $(DISK)
	find $(DISK) -type f ! -name $(notdir $(TARGET)) -delete
	$(PYTHON) tools/mkassets.py --out $(DISK) --header $@ --reserved $(notdir $(TARGET)) \
		--sizes $(ASSET_SIZES) --files $(MY_ASSETS)

# VERA PSG frequency tables (8 track builds)
$(BUILD)/psgtab.s: tools/mkpsgtab.py
	@mkdir -p $(BUILD)
	$(PYTHON) $< $@

# song.cfg: rebuilt when the track count changes
$(TARGET): $(C_SOURCES) $(ASM_SOURCES) $(BUILD)/assets.h src/*.h src/*.inc src/pokeyatest.cfg $(BUILD)/song.cfg
	$(CL) -Osir -t $(MACH) -C src/pokeyatest.cfg -I src -I $(BUILD) --asm-include-dir src \
		--asm-define RMT_TRACKS=$(TRACKS) -DRMT_TRACKS=$(TRACKS) \
		-DSONGNAME=\"$(SONGNAME)\" $(DEFS) -m $(BUILD)/pkatest.map \
		-o $@ $(C_SOURCES) $(ASM_SOURCES)

$(ATR): $(TARGET) $(BUILD)/assets.h
	rm -f $@
	$(DIR2ATR) -a -b $(BOOTDOS) $@ $(DISK)
	@$(PYTHON) tools/atrcheck.py $@ $(MAXSECTORS) || { rm -f $@; exit 1; }
	@# MyPicoDos autorun starts the first directory entry: the program
	@$(PYTHON) tools/atrorder.py $@ $(notdir $(TARGET)) || { rm -f $@; exit 1; }

run: $(ATR)
	$(EMULATOR) $(EMUSWITCHES)

clean:
	rm -rf $(BUILD)
	rm -f src/*.o

.PHONY: all run clean FORCE
