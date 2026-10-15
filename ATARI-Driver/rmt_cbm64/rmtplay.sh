#!/usr/bin/env bash
# rmtplay.sh — build the C64 RMT player with visualizer (build/rmtplay.prg)
# for an RMT song and play it in VICE (x64sc).
#
#   ./rmtplay.sh SONG.rmt|SONG.sap|SONG.xex
#
#   SONG.rmt   RMT4 module, or RMT8 (stereo) module (any path)
#   SONG.sap   SAP or XEX exported by RITMO / RMT, mono or stereo: its LZSS
#   SONG.xex   streams, played by src/lzsplayr.s (RMT_SUBSONG=n: another subtune)
#
# A stereo song plays the right POKEY on a second SID: VICE is started with
# one ("-sidextra 1 -sid2address", stereo sound output), at $D420 unless
# RMT_SID2 says otherwise.
#
# Environment (optional):
#   X64SC      emulator to run (default: x64sc from PATH)
#   VICE_OPTS  extra emulator options, e.g. "-ntsc" or "-sidenginemodel 256"
#              (default machine: PAL, no CRT emulation and fast reSID
#              sampling, "-VICIIfilter 0 -residsamp 0": on a slow PC VICE
#              with its window ran at 78-88% of the speed of a C64, so music,
#              bars and scroll stuttered; VICE_OPTS="-VICIIfilter 1
#              -residsamp 2" brings them back)
#   RMT_NAME, RMT_AUTHOR, RMT_DATE   song info shown by the player instead
#              of the text stored in the .rmt (see tools/rmtinfo.py) or of
#              the SAP tags (tools/sap2ca65.py)
#   RMT_SUBSONG  subtune of a .sap / .xex (default 0)
#   VICE_CONFIG  configuration file of VICE (-config); by default
#              ~/.config/vice/vicerc-<version> when there is one for the
#              version of the emulator: VICE versions disagree on a shared
#              vicerc (VICE 3.10 crashes in -console on a 3.9 one)
#   RMT_SID2   address of the second SID of a stereo song, hex digits
#              (default D420; D500, DE00... any address VICE offers)
#
# Keys in the player: SPACE pause, R restart, 1/2/3 (1-6 with two SIDs) SID voice on/off,
# RUN/STOP or <- exit. The program is also written to build/rmtplay.d64
# for a real C64.

set -euo pipefail

usage() {
    sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2
}

[ $# -eq 1 ] || usage

song=$1

if [ ! -f "$song" ]; then
    echo "rmtplay.sh: $song: no such file" >&2
    exit 1
fi
case $song in
    *.sap|*.SAP)
        if [ "$(head -c 4 "$song")" != "$(printf 'SAP\r')" ]; then
            echo "rmtplay.sh: $song: not a SAP file" >&2
            exit 1
        fi
        ;;
    *)
        if [ "$(head -c 2 "$song" | od -An -tx1 | tr -d ' \n')" != "ffff" ]; then
            echo "rmtplay.sh: $song: not an RMT module or XEX (no Atari binary header)" >&2
            exit 1
        fi
        ;;
esac

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
emu=${X64SC:-x64sc}
if ! command -v "$emu" >/dev/null; then
    echo "rmtplay.sh: emulator '$emu' not found (set X64SC=...)" >&2
    exit 1
fi

# make cannot handle spaces in file names: such a song is copied first
song_abs=$(realpath "$song")
case $song_abs in
    *[[:space:]]*)
        mkdir -p "$dir/build/gen"
        base=$(basename "$song_abs")
        copy="$dir/build/gen/${base//[[:space:]]/_}"
        cp "$song_abs" "$copy"
        song_abs=$copy
        ;;
esac

echo "rmtplay.sh: building build/rmtplay.prg for $(basename "$song")"
sid2=${RMT_SID2:-D420}
make -C "$dir" --no-print-directory rmtplay SONG="$song_abs" SUBSONG="${RMT_SUBSONG:-0}" SID2="$sid2" \
     NAME="${RMT_NAME:-}" AUTHOR="${RMT_AUTHOR:-}" DATE="${RMT_DATE:-}"

# the configuration file of this version of VICE, when there is one
config=${VICE_CONFIG:-}
if [ -z "$config" ]; then
    version=$("$emu" -version 2>&1 | sed -n 's/.*VICE \([0-9.]*\)).*/\1/p' | head -1)
    [ -n "$version" ] && [ -f "$HOME/.config/vice/vicerc-$version" ] && config="$HOME/.config/vice/vicerc-$version"
fi

# a stereo song (RMT8, or a stereo SAP / XEX): VICE with the second SID
stereo=""
case $song_abs in
    *.sap|*.SAP|*.xex|*.XEX) tracks=$(python3 "$dir/tools/sap2ca65.py" "$song_abs" --tracks) ;;
    *) [ "$(head -c 10 "$song_abs" | tail -c 4)" = "RMT8" ] && tracks=8 || tracks=4 ;;
esac
if [ "$tracks" = 8 ]; then
    stereo="-sidextra 1 -sid2address 0x$sid2 -soundoutput 2"
fi

echo "rmtplay.sh: starting $emu${stereo:+ with a second SID at \$$sid2}"
# -autostartprgmode 1: the program goes straight into RAM (no disk loading)
# shellcheck disable=SC2086 # VICE_OPTS is a list of options
exec "$emu" ${config:+-config "$config"} -pal -VICIIfilter 0 -residsamp 0 $stereo ${VICE_OPTS:-} -autostartprgmode 1 -autostart "$dir/build/rmtplay.prg"
