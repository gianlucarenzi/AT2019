#!/usr/bin/env python3
"""
MOD to RMT Note Extractor
Parses ProTracker MOD files and extracts note sequences per channel
for manual transcription into RMT Atari sequencer.

Usage:
  python3 mod_to_rmt_extractor.py <file.mod> [--output report.txt]

Output:
  - Text report showing patterns, notes, and timing
  - CSV per channel for easier RMT transcription
  - Instrument list and statistics
"""

import sys
import struct
from pathlib import Path

# MIDI note to frequency mapping (C-1 = 8 Hz, C-4 = 261 Hz)
MIDI_NOTES = {
    0x000: "---", 0x01B: "A-1", 0x024: "B-1",
    0x02D: "C-2", 0x036: "D-2", 0x03F: "E-2", 0x048: "F-2", 0x051: "G-2", 0x05A: "A-2", 0x063: "B-2",
    0x06C: "C-3", 0x075: "D-3", 0x07E: "E-3", 0x087: "F-3", 0x090: "G-3", 0x099: "A-3", 0x0A2: "B-3",
    0x0AB: "C-4", 0x0B4: "D-4", 0x0BD: "E-4", 0x0C6: "F-4", 0x0CF: "G-4", 0x0D8: "A-4", 0x0E1: "B-4",
    0x0EA: "C-5", 0x0F3: "D-5", 0x0FC: "E-5", 0x105: "F-5", 0x10E: "G-5", 0x117: "A-5", 0x120: "B-5",
}

class MODParser:
    """Parse ProTracker MOD file format"""
    
    def __init__(self, filename):
        self.filename = filename
        self.data = None
        self.title = ""
        self.samples = []
        self.sample_headers = []
        self.num_patterns = 0
        self.song_length = 0
        self.pattern_table = []
        self.patterns = []
        self.bpm = 125
        self.speed = 6
        
    def read(self):
        """Parse MOD file"""
        with open(self.filename, 'rb') as f:
            self.data = f.read()
        
        if len(self.data) < 1084:
            raise ValueError(f"File too small: {len(self.data)} bytes")
        
        # Parse title (offset 0, 20 bytes)
        self.title = self.data[0:20].rstrip(b'\x00').decode('ascii', errors='ignore')
        
        # Parse sample headers (31 samples, 30 bytes each, offset 20)
        for i in range(31):
            offset = 20 + (i * 30)
            sample_info = {
                'name': self.data[offset:offset+22].rstrip(b'\x00').decode('ascii', errors='ignore'),
                'length': struct.unpack('>H', self.data[offset+22:offset+24])[0] * 2,
                'finetune': struct.unpack('B', self.data[offset+24:offset+25])[0],
                'volume': struct.unpack('B', self.data[offset+25:offset+26])[0],
                'loop_start': struct.unpack('>H', self.data[offset+26:offset+28])[0] * 2,
                'loop_length': struct.unpack('>H', self.data[offset+28:offset+30])[0] * 2,
            }
            self.sample_headers.append(sample_info)
        
        # Parse song info (offset 950)
        self.song_length = struct.unpack('B', self.data[950:951])[0]
        self.num_patterns = 128  # Standard
        
        # Parse pattern table (offset 952, 128 bytes)
        self.pattern_table = list(self.data[952:952+128])
        self.num_patterns = max(self.pattern_table) + 1
        
        # Parse patterns (offset 1084)
        pattern_offset = 1084
        for p in range(self.num_patterns):
            pattern = self._parse_pattern(pattern_offset)
            self.patterns.append(pattern)
            pattern_offset += 1024  # Each pattern is 1024 bytes
    
    def _parse_pattern(self, offset):
        """Parse single 64-row pattern"""
        pattern = []
        for row in range(64):
            channels = []
            for ch in range(4):
                # Each note is 4 bytes
                note_offset = offset + (row * 16) + (ch * 4)
                note_data = self.data[note_offset:note_offset+4]
                
                # Parse note (top 12 bits of first 2 bytes)
                period = ((note_data[0] & 0x0F) << 8) | note_data[1]
                sample = ((note_data[2] & 0xF0) | ((note_data[0] & 0xF0) >> 4))
                effect = note_data[2] & 0x0F
                effect_param = note_data[3]
                
                note_str = self._period_to_note(period) if period else "---"
                
                channels.append({
                    'period': period,
                    'note': note_str,
                    'sample': sample,
                    'effect': effect,
                    'effect_param': effect_param,
                })
            
            pattern.append(channels)
        
        return pattern
    
    def _period_to_note(self, period):
        """Convert period value to note name"""
        periods = {
            1712: "C-1", 1616: "C#1", 1524: "D-1", 1440: "D#1", 1356: "E-1", 1280: "F-1",
            1208: "F#1", 1140: "G-1", 1076: "G#1", 1016: "A-1", 960: "A#1", 907: "B-1",
            856: "C-2", 808: "C#2", 762: "D-2", 720: "D#2", 678: "E-2", 640: "F-2",
            604: "F#2", 570: "G-2", 538: "G#2", 508: "A-2", 480: "A#2", 453: "B-2",
            428: "C-3", 404: "C#3", 381: "D-3", 360: "D#3", 339: "E-3", 320: "F-3",
            302: "F#3", 285: "G-3", 269: "G#3", 254: "A-3", 240: "A#3", 226: "B-3",
            214: "C-4", 202: "C#4", 190: "D-4", 180: "D#4", 170: "E-4", 160: "F-4",
            151: "F#4", 143: "G-4", 135: "G#4", 127: "A-4", 120: "A#4", 113: "B-4",
        }
        return periods.get(period, f"?{period}")
    
    def export_csv(self, output_prefix):
        """Export patterns as CSV for each channel"""
        for ch in range(4):
            filename = f"{output_prefix}_ch{ch+1}.csv"
            with open(filename, 'w') as f:
                f.write("Pattern,Row,Note,Sample,Effect,Param\n")
                
                for p_idx in range(len(self.pattern_table)):
                    p = self.pattern_table[p_idx]
                    if p >= len(self.patterns):
                        continue
                    
                    pattern = self.patterns[p]
                    for row, channels in enumerate(pattern):
                        if ch < len(channels):
                            c = channels[ch]
                            if c['period'] > 0:  # Only log active notes
                                f.write(f"{p_idx},{row},{c['note']},{c['sample']},{c['effect']},{c['effect_param']}\n")
            
            print(f"  ✓ {filename}")
    
    def export_report(self, output_file):
        """Export human-readable report"""
        with open(output_file, 'w') as f:
            f.write("=" * 80 + "\n")
            f.write("MOD to RMT EXTRACTOR REPORT\n")
            f.write("=" * 80 + "\n\n")
            
            f.write(f"Title:           {self.title}\n")
            f.write(f"Song Length:     {self.song_length} patterns\n")
            f.write(f"Unique Patterns: {self.num_patterns}\n")
            f.write(f"BPM:             {self.bpm} (estimated)\n")
            f.write(f"Speed:           {self.speed} ticks/row\n\n")
            
            f.write("INSTRUMENTS:\n")
            f.write("-" * 80 + "\n")
            for i, s in enumerate(self.sample_headers[:31]):
                if s['name'] or s['length'] > 0:
                    f.write(f"  {i+1:2d}. {s['name']:22s} Length: {s['length']:6d} Vol: {s['volume']:3d} Loop: {s['loop_start']:6d}+{s['loop_length']:6d}\n")
            
            f.write("\n" + "=" * 80 + "\n")
            f.write("PATTERN TABLE (Song Order):\n")
            f.write("-" * 80 + "\n")
            
            # Print pattern table in rows of 16
            for i in range(0, len(self.pattern_table), 16):
                row = self.pattern_table[i:i+16]
                indices = " ".join(f"{r:3d}" for r in row)
                f.write(f"  {i:3d}: {indices}\n")
            
            f.write("\n" + "=" * 80 + "\n")
            f.write("FIRST 2 PATTERNS (per channel):\n")
            f.write("-" * 80 + "\n")
            
            for p_idx in range(min(2, len(self.pattern_table))):
                p = self.pattern_table[p_idx]
                if p >= len(self.patterns):
                    continue
                
                f.write(f"\nPattern {p_idx} (ID={p}):\n")
                pattern = self.patterns[p]
                
                f.write("Row  CH1        CH2        CH3        CH4\n")
                f.write("-" * 60 + "\n")
                
                for row, channels in enumerate(pattern):
                    if row % 8 != 0:  # Show every 8th row for brevity
                        continue
                    
                    f.write(f"{row:3d} ")
                    for ch in channels:
                        note_str = f"{ch['note']:3s} S{ch['sample']:02d}"
                        f.write(f" {note_str:10s}")
                    f.write("\n")
            
            f.write("\n" + "=" * 80 + "\n")
            f.write("NOTES FOR RMT CONVERSION:\n")
            f.write("-" * 80 + "\n")
            f.write("""
1. MOD uses 4 channels; RMT/POKEY also uses 4 channels - GOOD!

2. MOD Frequency reference (ProTracker):
   - Uses 4-sample resolution per row (@ 50 Hz VBI)
   - Default speed: 6 ticks per row
   - Tempo: 125 BPM

3. POKEY Frequency reference (Atari):
   - Uses 1 line per frame (60 Hz NTSC or 50 Hz PAL)
   - RMT speed 1 = 1 line advance per call
   - Need to adjust timing

4. Conversion Strategy:
   a) Export note sequences from CSV files above
   b) Open RMT Editor
   c) Create 4-channel module
   d) Manually input notes (preserve ordering and timing)
   e) Create synth instruments to match MOD instrument character
   f) Adjust tempo/speed for POKEY timing

5. Channel Mapping:
   MOD Channel 1 → POKEY Channel 1
   MOD Channel 2 → POKEY Channel 2
   MOD Channel 3 → POKEY Channel 3
   MOD Channel 4 → POKEY Channel 4

6. Instrument Mapping:
   MOD samples (wave-based) → RMT synth (oscillator-based)
   This MUST be done manually - no automatic conversion possible
   Look at the instrument names and characteristics above

7. Quality Tips:
   - Start with melodic channels first (usually CH1-2)
   - Use CSV exports as guide for note sequences
   - Test in RMT Editor with different synth types
   - Listen for similar texture/timbre to original
""")

def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file.mod> [--output prefix]")
        sys.exit(1)
    
    mod_file = sys.argv[1]
    output_prefix = Path(mod_file).stem
    
    if '--output' in sys.argv:
        idx = sys.argv.index('--output')
        if idx + 1 < len(sys.argv):
            output_prefix = sys.argv[idx + 1]
    
    print(f"\n📀 Parsing MOD file: {mod_file}")
    
    try:
        parser = MODParser(mod_file)
        parser.read()
        
        print(f"✓ Title: {parser.title}")
        print(f"✓ Patterns: {parser.num_patterns}")
        print(f"✓ Song length: {parser.song_length}")
        
        print(f"\n📊 Exporting CSV per channel...")
        parser.export_csv(output_prefix)
        
        report_file = f"{output_prefix}_report.txt"
        print(f"\n📝 Exporting report to {report_file}...")
        parser.export_report(report_file)
        
        print(f"\n✅ Done! Files generated:")
        print(f"   - {output_prefix}_ch1.csv")
        print(f"   - {output_prefix}_ch2.csv")
        print(f"   - {output_prefix}_ch3.csv")
        print(f"   - {output_prefix}_ch4.csv")
        print(f"   - {report_file}")
        
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
