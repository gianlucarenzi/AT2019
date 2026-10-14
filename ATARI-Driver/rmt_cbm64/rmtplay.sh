#!/usr/bin/env bash
# rmtplay.sh — build the C64 RMT player with visualizer (build/rmtplay.prg)
# for an RMT song and play it in VICE (x64sc).
#
#   ./rmtplay.sh SONG.rmt|SONG.sap|SONG.xex
#
#   SONG.rmt   RMT4 module (any path)
#   SONG.sap   SAP or XEX exported by RITMO / RMT (mono): its LZSS streams,
#   SONG.xex   played by src/lzsplayr.s (RMT_SUBSONG=n: another subtune)
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
#
# Keys in the player: SPACE pause, R restart, 1/2/3 SID voice on/off,
# RUN/STOP or <- exit. The program is also written to build/rmtplay.d64
# for a real C64.

set -euo pipefail

usage() {
    sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//' >&2
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
make -C "$dir" --no-print-directory rmtplay SONG="$song_abs" SUBSONG="${RMT_SUBSONG:-0}" \
     NAME="${RMT_NAME:-}" AUTHOR="${RMT_AUTHOR:-}" DATE="${RMT_DATE:-}"

echo "rmtplay.sh: starting $emu"
# -autostartprgmode 1: the program goes straight into RAM (no disk loading)
# shellcheck disable=SC2086 # VICE_OPTS is a list of options
exec "$emu" -pal -VICIIfilter 0 -residsamp 0 ${VICE_OPTS:-} -autostartprgmode 1 -autostart "$dir/build/rmtplay.prg"
