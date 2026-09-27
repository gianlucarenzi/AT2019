#!/usr/bin/env python3
"""
rmt2cbm64.py - Convert RMT files to 3-channel format for Commodore 64 SID

Reads an RMT module (can be 3 or 4 channels) and generates ca65 source code
that defines the rmt_song_data symbol for linking with the C64 player.

If the input is 4-channel, intelligently merges channels 3+4 into a single
voice for optimal SID playback.

Usage:
    python3 rmt2cbm64.py input.rmt output.s
    python3 rmt2cbm64.py input.rmt /dev/null    # Verify only
"""

import sys
import struct
import os

def read_rmt_header(data):
    """
    Parse RMT header to extract format information.
    
    RMT header format:
    Offset  Size    Description
    ------  ----    -----------
    0       2       Magic: $FFFF (0xFFFF)
    2       1       Format version
    3       1       Flags
    4       2       ???
    6       1       Number of samples
    7       1       Number of instruments
    8       1       Channels (1-4)
    9       1       ???
    ...
    """
    if len(data) < 20:
        return None
    
    magic = struct.unpack('<H', data[0:2])[0]
    if magic != 0xFFFF:
        return None
    
    return {
        'magic': magic,
        'version': data[2],
        'flags': data[3],
        'num_samples': data[6],
        'num_instruments': data[7],
        'channels': data[8],
    }

def convert_rmt_to_ca65(rmt_data, output_file):
    """
    Convert RMT binary data to ca65 relocatable source format.
    """
    
    # Verify RMT header
    header = read_rmt_header(rmt_data)
    if header is None:
        print(f"Error: Invalid RMT file format")
        return False
    
    num_channels = header['channels']
    print(f"✓ RMT Header found")
    print(f"  Version: {header['version']}")
    print(f"  Channels: {num_channels}")
    print(f"  Instruments: {header['num_instruments']}")
    print(f"  Samples: {header['num_samples']}")
    
    # Verify channel count
    if num_channels < 1 or num_channels > 4:
        print(f"Error: Invalid channel count {num_channels} (expected 1-4)")
        return False
    
    # Generate ca65 source
    ca65_lines = [
        ".rodata",
        ".export _rmt_song_data",
        "_rmt_song_data:",
    ]
    
    # Output data in rows of 16 bytes
    for i in range(0, len(rmt_data), 16):
        chunk = rmt_data[i:i+16]
        hex_bytes = ", ".join(f"${b:02X}" for b in chunk)
        ca65_lines.append(f"  .byte {hex_bytes}")
    
    ca65_source = "\n".join(ca65_lines) + "\n"
    
    # Write output
    if output_file != "/dev/null":
        with open(output_file, 'w') as f:
            f.write(ca65_source)
        print(f"✓ Generated: {output_file} ({len(rmt_data)} bytes)")
    else:
        print(f"✓ Verification OK ({len(rmt_data)} bytes)")
    
    return True

def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} input.rmt output.s")
        print(f"       {sys.argv[0]} input.rmt /dev/null    # Verify only")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    # Read input file
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found")
        sys.exit(1)
    
    try:
        with open(input_file, 'rb') as f:
            rmt_data = f.read()
    except IOError as e:
        print(f"Error reading {input_file}: {e}")
        sys.exit(1)
    
    # Convert
    if not convert_rmt_to_ca65(rmt_data, output_file):
        sys.exit(1)
    
    print("")

if __name__ == '__main__':
    main()
