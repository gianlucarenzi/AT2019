#!/usr/bin/env python3
"""
MOD to RMT Direct Converter (Fixed - Correct binary layout)
"""

import sys
import struct
from pathlib import Path

class MODtoRMT:
    """Convert MOD to RMT"""
    
    def __init__(self, mod_file, rmt_file):
        self.mod_file = mod_file
        self.rmt_file = rmt_file
        self.mod_data = None
    
    def read_mod(self):
        """Parse MOD file"""
        with open(self.mod_file, 'rb') as f:
            self.mod_data = f.read()
        
        if len(self.mod_data) < 1084:
            raise ValueError("MOD file too small")
    
    def _parse_mod_header(self):
        """Extract MOD metadata"""
        title = self.mod_data[0:20].rstrip(b'\x00').decode('ascii', errors='ignore')
        song_length = self.mod_data[950]
        pattern_table = list(self.mod_data[952:952+128])
        max_pattern = max(pattern_table) if pattern_table else 0
        
        return {
            'title': title,
            'song_length': song_length,
            'num_patterns': max_pattern + 1,
            'pattern_table': pattern_table[:song_length],
        }
    
    def _period_to_midi(self, period):
        """Convert MOD period to MIDI note number"""
        periods = {
            1712: 36, 1616: 37, 1524: 38, 1440: 39, 1356: 40, 1280: 41,
            1208: 42, 1140: 43, 1076: 44, 1016: 45, 960: 46, 907: 47,
            856: 48, 808: 49, 762: 50, 720: 51, 678: 52, 640: 53,
            604: 54, 570: 55, 538: 56, 508: 57, 480: 58, 453: 59,
            428: 60, 404: 61, 381: 62, 360: 63, 339: 64, 320: 65,
            302: 66, 285: 67, 269: 68, 254: 69, 240: 70, 226: 71,
            214: 72, 202: 73, 190: 74, 180: 75, 170: 76, 160: 77,
            151: 78, 143: 79, 135: 80, 127: 81, 120: 82, 113: 83,
        }
        return periods.get(period, 0)
    
    def convert(self):
        """Convert MOD to RMT with correct Atari binary format"""
        print("📀 Reading MOD file...")
        self.read_mod()
        
        meta = self._parse_mod_header()
        print(f"  Title: {meta['title']}")
        print(f"  Patterns: {meta['num_patterns']}")
        print(f"  Song length: {meta['song_length']}")
        
        # Build RMT module data (will be loaded at 0x4000)
        rmt_data = bytearray()
        
        # RMT Header - MUST start with "RMT4" magic
        rmt_data.extend(b'RMT4')
        
        # Version/flags
        rmt_data.append(0x40)  # Version 4, flags
        
        # Speed, Tempo
        rmt_data.append(0x06)  # Speed 6
        rmt_data.append(0x78)  # Tempo 120
        
        # Number of channels (4)
        rmt_data.append(0x04)
        
        # Instrument table pointer (relative to module start @ 0x4000)
        instr_offset = 16
        rmt_data.append(instr_offset & 0xFF)
        rmt_data.append((instr_offset >> 8) & 0xFF)
        
        # Track table pointers (4 channels)
        track_offset = instr_offset + 128  # After 16 instruments * 8 bytes
        for ch in range(4):
            rmt_data.append(track_offset & 0xFF)
            rmt_data.append((track_offset >> 8) & 0xFF)
        
        # Song table pointer
        song_offset = track_offset + (meta['num_patterns'] * 2 * 4)
        rmt_data.append(song_offset & 0xFF)
        rmt_data.append((song_offset >> 8) & 0xFF)
        
        # Pad to instr_offset
        while len(rmt_data) < instr_offset:
            rmt_data.append(0)
        
        print("🎵 Building RMT module...")
        
        # Instrument table (16 instruments, 8 bytes each)
        for i in range(16):
            rmt_data.append(0x40)  # Type/Volume
            rmt_data.append(0x00)  # Attack
            rmt_data.append(0x14)  # Decay
            rmt_data.append(0x08)  # Sustain
            rmt_data.append(0x04)  # Release
            rmt_data.append(0x00)  # Padding
            rmt_data.append(0x00)
            rmt_data.append(0x00)
        
        # Pattern data
        print("📝 Converting patterns...")
        pattern_offset = 1084
        patterns_data = {}
        
        for p_idx in range(meta['num_patterns']):
            patterns_data[p_idx] = [[], [], [], []]  # 4 channels
            
            for row in range(64):
                for ch in range(4):
                    note_offset = pattern_offset + (row * 16) + (ch * 4)
                    note_data = self.mod_data[note_offset:note_offset+4]
                    
                    period = ((note_data[0] & 0x0F) << 8) | note_data[1]
                    sample = ((note_data[2] & 0xF0) >> 4) | (note_data[0] & 0xF0)
                    
                    note_num = self._period_to_midi(period)
                    instr = min((sample % 15) + 1 if sample > 0 else 0, 15)
                    
                    patterns_data[p_idx][ch].append((note_num, instr, 0))
            
            pattern_offset += 1024
        
        # Write track pointers (for each channel, list of offsets to pattern data)
        tracks_start = len(rmt_data) + (meta['num_patterns'] * 2 * 4)
        
        for ch in range(4):
            for p_idx in range(meta['num_patterns']):
                offset = tracks_start + (p_idx * 64 * 2 * 4) + (ch * 64 * 2)
                rmt_data.append(offset & 0xFF)
                rmt_data.append((offset >> 8) & 0xFF)
        
        # Write pattern data
        for p_idx in range(meta['num_patterns']):
            for ch in range(4):
                for row in range(64):
                    if row < len(patterns_data[p_idx][ch]):
                        note, instr, eff = patterns_data[p_idx][ch][row]
                        rmt_data.append(note & 0xFF)
                        rmt_data.append((instr << 4) | (eff & 0x0F))
                    else:
                        rmt_data.append(0)
                        rmt_data.append(0)
        
        # Song table
        for p in meta['pattern_table']:
            rmt_data.append(p & 0xFF)
        
        # Pad to at least 256 bytes
        while len(rmt_data) < 256:
            rmt_data.append(0)
        
        print(f"✓ Converted {meta['num_patterns']} patterns")
        print(f"✓ RMT module data: {len(rmt_data)} bytes")
        
        # NOW wrap with Atari binary header
        print("💾 Creating Atari binary file...")
        output = bytearray()
        
        # Atari binary header: FF FF START_LO START_HI END_LO END_HI DATA...
        output.append(0xFF)
        output.append(0xFF)
        
        # Start address
        start_addr = 0x4000
        output.append(start_addr & 0xFF)
        output.append((start_addr >> 8) & 0xFF)
        
        # End address  
        end_addr = start_addr + len(rmt_data) - 1
        output.append(end_addr & 0xFF)
        output.append((end_addr >> 8) & 0xFF)
        
        # RMT data
        output.extend(rmt_data)
        
        # Save file
        Path(self.rmt_file).parent.mkdir(parents=True, exist_ok=True)
        with open(self.rmt_file, 'wb') as f:
            f.write(output)
        
        print(f"✅ Saved to {self.rmt_file}")
        print(f"   Atari binary size: {len(output)} bytes")
        print(f"   Load address: 0x{start_addr:04X}")
        print(f"   End address:  0x{end_addr:04X}")
        
        return True

def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input.mod> <output.rmt>")
        sys.exit(1)
    
    mod_file = sys.argv[1]
    rmt_file = sys.argv[2]
    
    try:
        converter = MODtoRMT(mod_file, rmt_file)
        converter.convert()
        print("\n✨ Ready for rmt2ca65.py!")
        
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
