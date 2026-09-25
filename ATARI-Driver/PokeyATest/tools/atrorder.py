#!/usr/bin/env python3
"""
atrorder.py - move a file to the top of a DOS 2.x ATR directory.

MyPicoDos autorun mode (-a) is documented for a disk with a single file;
with more files it starts the FIRST file of the directory, and dir2atr adds
files in alphabetical order, so an asset named e.g. ALPHA.BIN would be
"run" instead of the program. (The .AR0 extension is not an autorun marker
for MyPicoDos 4.06: tested, it shows the menu.)

This tool moves the entry of the program right after the leading .SYS
entries (the DOS/boot files) and rewrites the file number stored in every
data sector link (byte 125 bits 7..2) of the entries that change position,
keeping the disk valid.

usage: atrorder.py image.atr NAME.EXT
"""
import sys

DIR_FIRST = 361
ENTRIES = 64


def die(msg):
    sys.exit("atrorder: %s" % msg)


def main():
    if len(sys.argv) != 3:
        die("usage: atrorder.py image.atr NAME.EXT")
    path, want = sys.argv[1], sys.argv[2].upper()
    name, _, ext = want.partition(".")
    want83 = (name.ljust(8) + ext.ljust(3)).encode()

    img = bytearray(open(path, "rb").read())
    if img[:2] != b"\x96\x02" or img[4:6] != b"\x80\x00":
        die("%s: not an ATR image with 128 bytes sectors" % path)

    def off(sector):
        return 16 + (sector - 1) * 128

    def entry_off(i):
        return off(DIR_FIRST + i // 8) + (i % 8) * 16

    entries = []
    for i in range(ENTRIES):
        e = bytes(img[entry_off(i):entry_off(i) + 16])
        if e[0] == 0:
            break
        entries.append(e)

    for e in entries:
        if (e[0] & 0x40) and not (e[0] & 0x80) and (e[0] & 0x04):
            die("%s: MyDOS entries without file numbers are not supported" % path)

    names = [e[5:16] for e in entries]
    if want83 not in names:
        die("%s: %s not found" % (path, want))
    src = names.index(want83)
    dst = 0
    while dst < len(entries) and entries[dst][13:16] == b"SYS":
        dst += 1
    if src == dst:
        return

    order = list(range(len(entries)))
    order.insert(dst, order.pop(src))          # order[new_index] = old_index

    for new, old in enumerate(order):
        e = entries[old]
        if new == old or (e[0] & 0x80) or not (e[0] & 0x40):
            continue
        sec = e[3] | (e[4] << 8)
        count = 0
        while sec:
            o = off(sec)
            link = img[o + 125]
            if link >> 2 != old:
                die("sector %d: file number %d, expected %d" % (sec, link >> 2, old))
            img[o + 125] = (new << 2) | (link & 0x03)
            sec = ((link & 0x03) << 8) | img[o + 126]
            count += 1
            if count > 1024:
                die("sector chain loop in entry %d" % old)

    for new, old in enumerate(order):
        img[entry_off(new):entry_off(new) + 16] = entries[old]

    open(path, "wb").write(img)
    print("atrorder: %s moved to directory entry %d" % (want, dst))


if __name__ == "__main__":
    main()
