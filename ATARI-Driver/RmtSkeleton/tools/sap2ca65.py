#!/usr/bin/env python3
"""
sap2ca65.py - the LZSS streams of a SAP (type B) or XEX exported by RITMO /
Raster Music Tracker (VU-Player v2) as a relocatable ca65 source for
lzsplayr.s, the player that plays them in place of rmtplayr.s.

RITMO records the POKEY registers of every frame of the song, with the
tracker driver chosen in its options, and compresses them (LZ16, DMSC) into
an intro section and a loop section per subtune. This tool takes one
subtune out of the VU-Player memory of the file:

    $1F40  song index: per subtune the address of its section list and of
           its sequence (section numbers, the last one | $80 = loop to)
    $183D  instrument speed, $0E0C stereo flag ($FF = stereo)

and writes it as

    label:      .byte speed, tracks (4 / 8), sections, loop section
                .word section 0, section 1 ..., end
    label_s0:   the LZ16 stream of section 0 ...
    label_end:

with rmt_song_tracks (4 or 8) exported, as tools/rmt2ca65.py does: the
player checks it at link time against RMT_TRACKS. Every section is decoded
here once (the frames it makes are printed): a file that is not a RITMO
LZSS export stops the tool.

--info out.h writes the song name, author and date for rmtplay.c, as
tools/rmtinfo.py does for an .rmt: from the NAME / AUTHOR / DATE tags of a
SAP, from the screen text of a XEX (first line = name, a dd/mm/yyyy line =
date, "Author: x" = author). Without an author (RITMO writes "???") the name
is split as rmtinfo.py splits the song text: "gem'x song, Atari version by
raster/c.p.u. 2004" -> NAME "gem'x song", AUTHOR the rest. --name /
--author / --date override them.

sap2ca65.py input --tracks prints 4 or 8 (mono / stereo) for a Makefile.

usage: sap2ca65.py input.sap|input.xex output.s [label] [--subsong N]
                   [--info out.h] [--name S] [--author S] [--date S]
       sap2ca65.py input.sap|input.xex --tracks
"""
import argparse
import os
import re
import sys

SONGINDEX = 0x1F40          # VU-Player v2 (RITMO src/lzssp.h)
SONG_SPEED = 0x183D
IS_STEREO = 0x0E0C
SONGTOTAL = 0x1B0D
XEX_TEXT = 0x1428           # LZSSP_LINE_1: 5 lines of 40 screen codes
MAXLEN = 200                # longest info line kept (as rmtinfo.py)


def die(msg):
    sys.stderr.write("sap2ca65: %s\n" % msg)
    sys.exit(1)


def load(path):
    """Memory image and SAP tags of a SAP type B or an Atari binary file."""
    raw = open(path, "rb").read()
    tags = {}
    if raw.startswith(b"SAP\r\n"):
        end = raw.find(b"\r\n\r\n")
        if end < 0:
            die("%s: SAP header without end" % path)
        for line in raw[5:end].decode("latin-1").split("\r\n"):
            key, _, value = line.partition(" ")
            tags[key] = value.strip().strip('"')
        if tags.get("TYPE") != "B":
            die("%s: SAP of type %s, not B" % (path, tags.get("TYPE")))
        raw = raw[end + 4:]
    elif raw[:2] != b"\xff\xff":
        die("%s: neither a SAP nor an Atari binary file" % path)
    mem = bytearray(65536)
    loaded = bytearray(65536)
    i = 0
    while i + 4 <= len(raw):
        if raw[i:i + 2] == b"\xff\xff":
            i += 2
            continue
        start = raw[i] | raw[i + 1] << 8
        end = raw[i + 2] | raw[i + 3] << 8
        i += 4
        if end < start or i + end - start + 1 > len(raw):
            die("%s: bad binary block $%04X-$%04X" % (path, start, end))
        mem[start:end + 1] = raw[i:i + end - start + 1]
        loaded[start:end + 1] = b"\1" * (end - start + 1)
        i += end - start + 1
    if not loaded[SONGINDEX]:
        die("%s: no VU-Player song index at $%04X: not a RITMO SAP/XEX export" % (path, SONGINDEX))
    return mem, loaded, tags


def word(mem, a):
    return mem[a] | mem[a + 1] << 8


def sections(mem, sub):
    """Start / end of the sections of a subtune, and the loop section."""
    sec = word(mem, SONGINDEX + 4 * sub)
    seq = word(mem, SONGINDEX + 4 * sub + 2)
    n = 0
    while not mem[seq + n] & 0x80:
        if mem[seq + n] != n:
            die("subtune %d: sequence %d is section %d, only 0, 1, .. in order are supported"
                % (sub, n, mem[seq + n]))
        n += 1
        if n > 100:
            die("subtune %d: no end of the sequence" % sub)
    loop = mem[seq + n] & 0x7F
    if n == 0 or loop >= n:
        die("subtune %d: %d sections, loop to %d" % (sub, n, loop))
    addr = [word(mem, sec + 2 * i) for i in range(n + 1)]
    return [(addr[i], addr[i + 1]) for i in range(n)], loop


def decode(mem, start, end):
    """Frames of one LZ16 stream (checks that it ends where the next starts)."""
    p = start
    bits = mem[p]
    p += 1
    skip = [False] * 9
    for i in range(8, 0, -1):
        skip[i] = bool(bits & 1)
        bits >>= 1
    win = [[0] * 256 for _ in range(9)]
    for i in range(8, -1, -1):
        win[i][0] = mem[p]
        p += 1
    cnt = [0] * 9
    src = [0] * 9
    bitbuf = 1
    frames = 1
    pos = 1
    while p < end:
        for i in range(8, -1, -1):
            if skip[i]:
                continue
            if cnt[i] == 0:
                bit = bitbuf & 1
                bitbuf >>= 1
                if bitbuf == 0:
                    b = mem[p]
                    p += 1
                    bit = b & 1
                    bitbuf = (b >> 1) | 0x80
                if bit:
                    win[i][pos & 255] = mem[p]
                    p += 1
                    continue
                src[i] = (mem[p] + 2) & 255
                cnt[i] = mem[p + 1] or 256
                p += 2
            win[i][pos & 255] = win[i][src[i]]
            src[i] = (src[i] + 1) & 255
            cnt[i] -= 1
        frames += 1
        pos += 1
    if p != end:
        die("stream $%04X-$%04X: the last frame reads past the end ($%04X)" % (start, end, p))
    return frames


def screen_text(mem):
    """The 5 lines of the XEX screen text (ANTIC screen codes -> ASCII)."""
    lines = []
    for n in range(5):
        s = ""
        for c in mem[XEX_TEXT + 40 * n:XEX_TEXT + 40 * n + 40]:
            c &= 0x7F
            if c < 64:
                c += 32
            elif c < 96:
                c -= 64
            s += chr(c) if 32 <= c < 127 else " "
        lines.append(s.strip())
    return lines


def info_from_xex(mem):
    lines = screen_text(mem)
    name = lines[0]
    date = next((l for l in lines if re.fullmatch(r"\d\d/\d\d/\d{4}", l)), "")
    author = ""
    for l in lines[1:]:
        m = re.match(r"author:\s*(.*)", l, re.I)
        if m and m.group(1) not in ("", "???", "(press SHIFT key)"):
            author = m.group(1)
    return name, author, date


def c_string(s):
    s = "".join(c if 32 <= ord(c) < 127 else "?" for c in s)[:MAXLEN]
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    if len(sys.argv) == 3 and sys.argv[2] == "--tracks":
        mem = load(sys.argv[1])[0]
        print(8 if mem[IS_STEREO] else 4)
        return
    ap = argparse.ArgumentParser(description="RITMO SAP/XEX LZSS streams as a ca65 source")
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("label", nargs="?", default="_rmt_song")
    ap.add_argument("--subsong", type=int, default=0)
    ap.add_argument("--info")
    ap.add_argument("--name", default="")
    ap.add_argument("--author", default="")
    ap.add_argument("--date", default="")
    a = ap.parse_args()

    mem, loaded, tags = load(a.input)
    songs = int(tags["SONGS"]) if "SONGS" in tags else (mem[SONGTOTAL] or 1)
    if not 0 <= a.subsong < songs:
        die("%s: subsong %d, the file has %d" % (a.input, a.subsong, songs))
    secs, loop = sections(mem, a.subsong)
    for s, e in secs:
        if e <= s or not all(loaded[s:e]):
            die("%s: section $%04X-$%04X is not in the file" % (a.input, s, e))
    speed = mem[SONG_SPEED] or 1
    tracks = 8 if mem[IS_STEREO] else 4
    frames = [decode(mem, s, e) for s, e in secs]
    if tracks == 8 and any(f % 2 for f in frames):
        die("%s: stereo section with an odd number of frames" % a.input)

    lab = a.label
    out = ["; generated by sap2ca65.py from %s - do not edit" % os.path.basename(a.input),
           "; LZSS streams of VU-Player v2 for lzsplayr.s: subtune %d of %d, instrument speed %d, %s"
           % (a.subsong, songs, speed, "stereo" if tracks == 8 else "mono"),
           ";   " + ", ".join("section %d: %d frames" % (i, f) for i, f in enumerate(frames))
           + ", then section %d again" % loop,
           "        .export %s, %s_end" % (lab, lab),
           "        .export rmt_song_tracks = %d" % tracks,
           "        .segment \"RODATA\"",
           "%s:" % lab,
           "        .byte %d, %d, %d, %d" % (speed, tracks, len(secs), loop),
           "        .word " + ", ".join(["%s_s%d" % (lab, i) for i in range(len(secs))] + ["%s_end" % lab])]
    for i, (s, e) in enumerate(secs):
        out.append("%s_s%d:" % (lab, i))
        data = mem[s:e]
        for j in range(0, len(data), 16):
            out.append("        .byte " + ",".join("$%02X" % b for b in data[j:j + 16]))
    out.append("%s_end:" % lab)
    with open(a.output, "w") as f:
        f.write("\n".join(out) + "\n")
    size = 8 + 2 * len(secs) + sum(e - s for s, e in secs)
    sys.stderr.write("sap2ca65: %s -> %s (subtune %d, %s, instr speed %d, %d bytes, frames %s, loop to section %d)\n"
                     % (a.input, a.output, a.subsong, "stereo" if tracks == 8 else "mono", speed, size,
                        "+".join(str(f) for f in frames), loop))
    if speed > 1:
        sys.stderr.write("sap2ca65: note: instrument speed %d: %d stream frames per video frame\n" % (speed, speed))

    if a.info:
        if tags:
            name, author, date = tags.get("NAME", ""), tags.get("AUTHOR", ""), tags.get("DATE", "")
        else:
            name, author, date = info_from_xex(mem)
        if author == "???":
            author = ""
        if not author:
            name, _, author = name.partition(", ")
            name, author = name.strip(), author.strip()
        name = a.name or name or os.path.splitext(os.path.basename(a.input))[0]
        author = a.author or author
        date = a.date or date
        per = 2 if tracks == 8 else 1       # stream frames per rmt_play call
        with open(a.info, "w") as f:
            f.write("/* generated by sap2ca65.py from %s - do not edit */\n" % a.input)
            f.write("#define RMT_INFO_NAME   %s\n" % c_string(name))
            f.write("#define RMT_INFO_AUTHOR %s\n" % c_string(author))
            f.write("#define RMT_INFO_DATE   %s\n" % c_string(date))
            f.write("#define RMT_INFO_LINES  0\n")
            f.write("/* LZSS: rmt_play calls of each section, the section played after the last one */\n")
            f.write("#define RMT_INFO_SECTIONS %d\n" % len(secs))
            f.write("#define RMT_INFO_LOOP     %d\n" % loop)
            f.write("#define RMT_INFO_FRAMES   { %s }\n" % ", ".join("%dUL" % (fr // per) for fr in frames))
            f.write("#define RMT_INFO_SPEED    %d\n" % speed)
        sys.stderr.write("sap2ca65: %s: NAME=%r AUTHOR=%r DATE=%r\n" % (a.info, name, author, date))


if __name__ == "__main__":
    main()
