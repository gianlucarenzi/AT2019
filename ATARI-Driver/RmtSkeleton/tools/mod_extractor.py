#!/usr/bin/env python3
"""
Proper MOD file parser - extracts real note data from ProTracker MOD files
"""

import struct
import sys

class MODExtractor:
    """Extract pattern data from MOD files"""
    
    def __init__(self, filename):
        self.filename = filename
        self.data = None
        self.title = ""
        self.samples = []
        self.num_patterns = 0
        self.pattern_table = []
        self.patterns = []
        
    def read_file(self):
        with open(self.filename, "rb") as f:
            self.data = f.read()
        print(f"📀 Read {len(self.data)} bytes")
    
    def parse_header(self):
        """Parse MOD header"""
        # Title (offset 0, 20 bytes)
        self.title = self.data[0:20].decode('latin-1', errors='ignore').strip()
        print(f"Title: {self.title}")
        
        # Samples (31 samples, 30 bytes each, starting at offset 20)
        for i in range(31):
            offset = 20 + (i * 30)
            name = self.data[offset:offset+22].decode('latin-1', errors='ignore').strip()
            size_words = struct.unpack('>H', self.data[offset+22:offset+24])[0]
            size_bytes = size_words * 2
            finetune = struct.unpack('b', self.data[offset+24:offset+25])[0]
            volume = self.data[offset+25]
            loop_start_words = struct.unpack('>H', self.data[offset+26:offset+28])[0]
            loop_len_words = struct.unpack('>H', self.data[offset+28:offset+30])[0]
            
            self.samples.append({
                'index': i + 1,
                'name': name,
                'size': size_bytes,
                'finetune': finetune,
                'volume': volume,
                'loop_start': loop_start_words * 2,
                'loop_len': loop_len_words * 2,
            })
        
        print(f"Samples: {len(self.samples)}")
        
        # Song info at offset 950
        song_len = self.data[945]
        restart_pos = self.data[946]  # Usually 127, ignored
        
        # Pattern table (128 bytes)
        self.pattern_table = list(self.data[950:950+128])
        max_pattern = max(self.pattern_table[:song_len]) if song_len > 0 else 0
        self.num_patterns = max_pattern + 1
        
        print(f"Song length: {song_len} positions")
        print(f"Number of patterns: {self.num_patterns}")
        print(f"Pattern table: {self.pattern_table[:song_len]}")
        
        # MOD format identifier at offset 1080 (4 bytes)
        # Can be "M.K.", "M!K!", "4CHN", "6CHN", "8CHN", "OKTA", "CD81", "OKTA"
        mod_id = self.data[1080:1084].decode('latin-1', errors='ignore')
        print(f"MOD type: {mod_id}")
        
        # Pattern data starts at offset 1084
        self.pattern_offset = 1084
        
    def parse_patterns(self):
        """Extract all patterns"""
        # Each pattern: 64 rows × 4 channels × 4 bytes = 1024 bytes
        pattern_size = 64 * 4 * 4
        
        for p in range(self.num_patterns):
            offset = self.pattern_offset + (p * pattern_size)
            pattern = []
            
            for row in range(64):
                row_data = []
                for ch in range(4):
                    note_offset = offset + (row * 16) + (ch * 4)
                    bytes4 = self.data[note_offset:note_offset+4]
                    
                    # Parse note cell (4 bytes)
                    sample_hi = (bytes4[0] & 0xF0)
                    period = ((bytes4[0] & 0x0F) << 8) | bytes4[1]
                    sample_lo = (bytes4[2] >> 4)
                    effect = (bytes4[2] & 0x0F)
                    param = bytes4[3]
                    
                    sample = sample_hi | sample_lo
                    
                    row_data.append({
                        'period': period,
                        'sample': sample,
                        'effect': effect,
                        'param': param,
                    })
                
                pattern.append(row_data)
            
            self.patterns.append(pattern)
        
        print(f"✓ Parsed {len(self.patterns)} patterns")
    
    def period_to_note(self, period):
        """Convert Amiga period to MIDI note number"""
        if period == 0:
            return 0
        
        # Amiga periods (3579545 Hz oscillator)
        # Period = 3579545 / (2 * frequency)
        # Frequency = 3579545 / (2 * period)
        
        # Standard periods for notes (C-1 to B-3, octave 1-3)
        periods = [
            # Octave 1
            1814, 1712, 1616, 1525, 1440, 1357, 1281, 1209, 1141, 1077, 1016, 961,
            # Octave 2
            907, 856, 808, 762, 720, 679, 640, 604, 571, 538, 508, 480,
            # Octave 3
            453, 428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240,
            # Octave 4
            226, 214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120,
        ]
        
        notes = [
            "C-1", "C#1", "D-1", "D#1", "E-1", "F-1", "F#1", "G-1", "G#1", "A-1", "A#1", "B-1",
            "C-2", "C#2", "D-2", "D#2", "E-2", "F-2", "F#2", "G-2", "G#2", "A-2", "A#2", "B-2",
            "C-3", "C#3", "D-3", "D#3", "E-3", "F-3", "F#3", "G-3", "G#3", "A-3", "A#3", "B-3",
            "C-4", "C#4", "D-4", "D#4", "E-4", "F-4", "F#4", "G-4", "G#4", "A-4", "A#4", "B-4",
        ]
        
        # Find closest period
        closest_idx = min(range(len(periods)), key=lambda i: abs(periods[i] - period))
        return notes[closest_idx] if closest_idx < len(notes) else "???"
    
    def show_first_pattern(self):
        """Display first pattern"""
        if not self.patterns:
            return
        
        print("\n📋 First pattern (first 16 rows):")
        pattern = self.patterns[0]
        for row in range(min(16, len(pattern))):
            cells = []
            for ch in range(4):
                cell = pattern[row][ch]
                if cell['period'] > 0:
                    note = self.period_to_note(cell['period'])
                    sample = cell['sample']
                    cells.append(f"{note}S{sample:02d}")
                else:
                    cells.append("---S00")
            print(f"  Row {row:2d}: {cells[0]:8s} {cells[1]:8s} {cells[2]:8s} {cells[3]:8s}")
    
    def extract(self):
        """Run full extraction"""
        self.read_file()
        self.parse_header()
        self.parse_patterns()
        self.show_first_pattern()
        return self.patterns

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: mod_extractor.py <mod_file>")
        sys.exit(1)
    
    extractor = MODExtractor(sys.argv[1])
    patterns = extractor.extract()
