#!/usr/bin/env python3
"""
atrcheck.py - print the size of an ATR image, fail if it has more sectors
than the loader supports or sectors that are not 128 bytes.

usage: atrcheck.py image.atr maxsectors
"""
import struct
import sys

path, maxsec = sys.argv[1], int(sys.argv[2])
raw = open(path, "rb").read()
if raw[:2] != b"\x96\x02":
    sys.exit("atrcheck: %s: not an ATR image" % path)
secsize = struct.unpack("<H", raw[4:6])[0]
sectors = (len(raw) - 16) // secsize
print("atrcheck: %s: %d sectors of %d bytes" % (path, sectors, secsize))
if secsize != 128:
    sys.exit("atrcheck: the loader reads 128 bytes sectors only")
if sectors > maxsec:
    sys.exit("atrcheck: %d sectors > %d: too many assets for the disk "
             "(the loader uses DOS 2.x 10 bit sector links)" % (sectors, maxsec))
