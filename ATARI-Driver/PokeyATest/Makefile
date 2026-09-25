# Makefile - PokeyATest: RMT player on VBI + SIO asset loader
#
# make            build build/pokeyatest.atr (bootable, MyPicoDos autorun)
# make run        launch atari800 with the SIO patch OFF (real serial timing)
# make SONG=music/other.rmt
# make ASSET_SIZES="2048 4096 16384"
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
# asset sizes in bytes: between 2K and 16K, also not multiple of a sector
ASSET_SIZES ?= 2048 3500 5120 8000 12288 16384

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
	-nobasic \
	-nopatchall \
	$(ATR)

C_SOURCES = \
	src/main.c \
	src/dos2fs.c \

ASM_SOURCES = \
	src/rmtplayr.s \
	src/rmtvbi.s \
	src/sio.s \
	$(BUILD)/song.s \

SONGNAME = $(basename $(notdir $(SONG)))

all: $(ATR)

$(BUILD)/song.s: $(SONG) tools/rmt2ca65.py
	@mkdir -p $(BUILD)
	$(PYTHON) tools/rmt2ca65.py $(SONG) $@

$(BUILD)/assets.h: tools/mkassets.py Makefile
	@mkdir -p $(DISK)
	rm -f $(DISK)/*.DAT
	$(PYTHON) tools/mkassets.py $(DISK) $@ $(ASSET_SIZES)

$(TARGET): $(C_SOURCES) $(ASM_SOURCES) $(BUILD)/assets.h src/*.h src/*.inc src/pokeyatest.cfg
	$(CL) -Osir -t $(MACH) -C src/pokeyatest.cfg -I src -I $(BUILD) --asm-include-dir src \
		-DSONGNAME=\"$(SONGNAME)\" $(DEFS) -m $(BUILD)/pkatest.map \
		-o $@ $(C_SOURCES) $(ASM_SOURCES)

$(ATR): $(TARGET) $(BUILD)/assets.h
	rm -f $@
	$(DIR2ATR) -a -b $(BOOTDOS) $@ $(DISK)

run: $(ATR)
	$(EMULATOR) $(EMUSWITCHES)

clean:
	rm -rf $(BUILD)
	rm -f src/*.o

.PHONY: all run clean
