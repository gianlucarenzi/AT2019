#!/usr/bin/env python3
"""
RMT File Format Parser & Analyzer
Decode RMT4 (Raster Music Tracker) binary files

RMT file structure:
  - Header (magic "RMT4")
  - Instrument definitions
  - Pattern table
  - Song data
  - Sample data (optional, usually external)
"""

import struct
from pathlib import Path
from dataclasses import dataclass
from typing import List, Optional


@dataclass
class RMTInstrument:
    """RMT instrument definition"""
    num: int
    name: str
    type: str  # Osc, Drum, ADSR, etc
    volume: int
    ctrl_data: bytes


@dataclass
class RMTPattern:
    """Single RMT pattern"""
    num: int
    data: bytes  # Raw pattern data


@dataclass
class RMTNote:
    """Single note in pattern"""
    note: int  # 0-95 (C-1 to B-7)
    instrument: int
    volume: int
    fx_cmd: int
    fx_arg: int


class RMTFile:
    """Parse RMT4 binary format"""
    
    MAGIC = b'RMT4'
    
    # MIDI note to name mapping
    NOTE_NAMES = [
        'C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-'
    ]
    
    def __init__(self, filepath):
        self.filepath = Path(filepath)
        self.data = None
        self.offset = 0
        
        # RMT metadata
        self.magic = None
        self.version = None
        self.flags = None
        self.speed = None
        self.bpm = None
        self.num_channels = None
        self.num_instruments = None
        self.num_patterns = None
        self.song_length = None
        self.num_voices = None
        
        # Data sections
        self.instruments: List[RMTInstrument] = []
        self.patterns: List[RMTPattern] = []
        self.song_table = []
        self.pattern_data = {}
    
    def read(self):
        """Parse RMT file"""
        with open(self.filepath, 'rb') as f:
            self.data = f.read()
        
        self._parse_header()
        self._parse_instruments()
        self._parse_patterns()
        
        return self
    
    def _parse_header(self):
        """Parse RMT header"""
        self.offset = 0
        
        # Magic
        self.magic = self._read_bytes(4)
        if self.magic != self.MAGIC:
            raise ValueError(f"Invalid RMT magic: {self.magic}")
        
        # Version and flags
        version_byte = self._read_byte()
        self.version = (version_byte >> 4) & 0x0F
        self.flags = version_byte & 0x0F
        
        # Speed (VBI ticks per pattern line)
        self.speed = self._read_byte()
        
        # BPM
        self.bpm = self._read_byte()
        
        # Channels
        self.num_channels = self._read_byte()
        
        # Instruments
        self.num_instruments = self._read_byte()
        
        # Patterns
        self.num_patterns = self._read_byte()
        
        # Song length
        self.song_length = self._read_byte()
        
        # Number of ADSR voices
        self.num_voices = self._read_byte()
        
        print(f"📊 RMT File: {self.filepath.name}")
        print(f"   Version: {self.version}")
        print(f"   Channels: {self.num_channels}")
        print(f"   Instruments: {self.num_instruments}")
        print(f"   Patterns: {self.num_patterns}")
        print(f"   Song length: {self.song_length}")
        print(f"   Speed: {self.speed} (VBI ticks/line)")
        print(f"   BPM: {self.bpm}")
    
    def _parse_instruments(self):
        """Parse instrument definitions"""
        print(f"\n🎹 Instruments:")
        
        for i in range(self.num_instruments):
            # Instrument name (up to 16 bytes, null-terminated)
            name_bytes = []
            while self.offset < len(self.data):
                b = self.data[self.offset]
                self.offset += 1
                if b == 0:
                    break
                name_bytes.append(b)
            
            name = bytes(name_bytes).decode('ascii', errors='ignore')
            
            # Instrument type byte
            instr_type = self._read_byte()
            
            # Volume and other params
            volume = self._read_byte()
            
            # Skip instrument data (varies by type)
            # For now, read remaining bytes until next instrument marker
            ctrl_data = b''
            
            instr = RMTInstrument(
                num=i,
                name=name or f"Instrument {i}",
                type=f"Type {instr_type}",
                volume=volume,
                ctrl_data=ctrl_data
            )
            
            self.instruments.append(instr)
            print(f"   {i:2d}: {instr.name:20s} Vol:{volume:3d} Type:{instr_type}")
    
    def _parse_patterns(self):
        """Parse pattern data"""
        print(f"\n🎼 Patterns:")
        
        # Read song table first
        self.song_table = []
        for i in range(self.song_length):
            pattern_idx = self._read_byte()
            self.song_table.append(pattern_idx)
        
        print(f"   Song order: {self.song_table}")
        
        # Read patterns
        for p in range(self.num_patterns):
            # Pattern length (usually 64 lines)
            pattern_length = self._read_byte()
            
            # Pattern data
            pattern_bytes = bytearray()
            for line in range(pattern_length):
                for ch in range(self.num_channels):
                    # Each note: 1-5 bytes depending on compression
                    note_byte = self._read_byte()
                    pattern_bytes.append(note_byte)
                    
                    # Check for multi-byte format
                    if note_byte & 0x80:  # Compressed format
                        # Read additional bytes
                        while True:
                            b = self._read_byte()
                            pattern_bytes.append(b)
                            if not (b & 0x80):
                                break
            
            pattern = RMTPattern(num=p, data=bytes(pattern_bytes))
            self.patterns.append(pattern)
            print(f"   Pattern {p}: {pattern_length} lines")
    
    def _read_byte(self) -> int:
        """Read single byte and advance offset"""
        if self.offset >= len(self.data):
            raise EOFError(f"Unexpected end of file at offset {self.offset}")
        value = self.data[self.offset]
        self.offset += 1
        return value
    
    def _read_bytes(self, count: int) -> bytes:
        """Read multiple bytes"""
        if self.offset + count > len(self.data):
            raise EOFError(f"Unexpected end of file at offset {self.offset}")
        value = self.data[self.offset:self.offset + count]
        self.offset += count
        return value
    
    def print_summary(self):
        """Print file summary"""
        print("\n" + "="*60)
        print(f"📋 RMT File Summary: {self.filepath.name}")
        print("="*60)
        print(f"Size: {len(self.data)} bytes")
        print(f"Format: RMT{self.version} ({self.num_channels} channels)")
        print(f"Duration: ~{self.song_length * 64 / (self.bpm * self.speed / 60):.1f}s")
        print(f"Instruments: {len(self.instruments)}")
        print(f"Patterns: {len(self.patterns)}")
        print("="*60 + "\n")


def main():
    """CLI: Analyze RMT files"""
    import sys
    
    if len(sys.argv) < 2:
        print(__doc__)
        print("\nUsage:")
        print("  python3 rmt_parser.py <file.rmt>")
        print("\nExample:")
        print("  python3 rmt_parser.py music/song.rmt")
        sys.exit(1)
    
    rmt_file = Path(sys.argv[1])
    
    if not rmt_file.exists():
        print(f"❌ File not found: {rmt_file}")
        sys.exit(1)
    
    try:
        rmt = RMTFile(rmt_file)
        rmt.read()
        rmt.print_summary()
    except Exception as e:
        print(f"❌ Error parsing RMT: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
