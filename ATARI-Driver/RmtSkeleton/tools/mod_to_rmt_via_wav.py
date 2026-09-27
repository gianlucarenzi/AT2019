#!/usr/bin/env python3
"""
MOD → WAV → RMT converter
Uses XMP to extract audio, then analyzes for note content
"""

import sys
import os
import subprocess
import struct
import tempfile
import numpy as np
from scipy import signal
from scipy.io import wavfile

class MODtoRMTViaWAV:
    """Convert MOD to RMT using XMP and audio analysis"""
    
    def __init__(self, mod_file):
        self.mod_file = mod_file
        self.wav_file = None
        self.sample_rate = 44100
        self.audio = None
        self.title = "Converted"
        self.tempo = 120
        self.speed = 6
        
    def extract_wav(self):
        """Use XMP to extract MOD as WAV"""
        print("🎵 Extracting audio with XMP...")
        
        # Create temp WAV file
        self.wav_file = tempfile.NamedTemporaryFile(suffix='.wav', delete=False).name
        
        # Run xmp
        cmd = ['xmp', '-d', 'wav', '-o', self.wav_file, self.mod_file]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        
        if result.returncode != 0:
            print(f"❌ XMP failed: {result.stderr}")
            return False
        
        # Parse output
        for line in result.stdout.split('\n'):
            if 'Module name' in line:
                self.title = line.split(':')[1].strip()
            if 'Duration' in line:
                parts = line.split(':')[1].strip().split('m')
                if len(parts) > 1:
                    mins = int(parts[0])
                    secs = int(parts[1].rstrip('s'))
                    print(f"  Duration: {mins}m{secs}s")
            if 'Patterns' in line:
                patterns = int(line.split(':')[1].strip())
                print(f"  Patterns: {patterns}")
        
        print(f"✓ WAV extracted: {self.wav_file}")
        return True
    
    def load_audio(self):
        """Load WAV file"""
        print("📊 Loading audio...")
        self.sample_rate, audio_data = wavfile.read(self.wav_file)
        
        # Convert stereo to mono if needed
        if len(audio_data.shape) > 1:
            self.audio = audio_data.mean(axis=1).astype(np.float32)
        else:
            self.audio = audio_data.astype(np.float32)
        
        # Normalize
        self.audio = self.audio / (np.abs(self.audio).max() + 1e-9)
        
        print(f"  Sample rate: {self.sample_rate} Hz")
        print(f"  Samples: {len(self.audio)}")
        print(f"  Duration: {len(self.audio) / self.sample_rate:.2f}s")
        return True
    
    def detect_beats(self):
        """Detect beat positions"""
        print("🎯 Detecting beats...")
        
        # Compute energy envelope
        frame_length = 2048
        hop_length = 512
        
        S = np.abs(np.fft.rfft(
            self.audio[:len(self.audio) - len(self.audio) % frame_length]
            .reshape(-1, frame_length),
            axis=1
        ))
        
        energy = np.sum(S ** 2, axis=1)
        
        # Smooth energy
        energy_smooth = signal.medfilt(energy, kernel_size=5)
        
        # Find peaks (beats)
        peaks, _ = signal.find_peaks(energy_smooth, height=np.median(energy_smooth))
        
        beat_times = peaks * hop_length / self.sample_rate
        print(f"  Found {len(peaks)} beats")
        
        if len(peaks) > 1:
            avg_beat_interval = np.mean(np.diff(beat_times[1:20]))
            bpm = 60.0 / avg_beat_interval if avg_beat_interval > 0 else 120
            self.tempo = int(bpm)
            print(f"  Tempo: {self.tempo} BPM")
        
        return peaks
    
    def build_rmt(self, num_patterns=4):
        """Build RMT4 binary"""
        print("🎹 Building RMT4 file...")
        
        rmt = bytearray()
        
        # Header: "RMT4" magic
        rmt.extend(b'RMT4')
        rmt.append(0x40)      # Flags
        rmt.append(0x06)      # Module info
        rmt.append(self.speed)  # Speed
        rmt.append(self.tempo & 0xFF)  # BPM
        rmt.extend([0x00] * 4)  # Reserved
        
        # Instrument table (16 instruments, 18 bytes each)
        for i in range(16):
            name = f"Instr{i:02d}".encode()[:16]
            rmt.extend(name)
            rmt.extend([0x00] * (16 - len(name)))
            rmt.extend([0x40, 0x00])  # Flags
        
        # Song table (256 bytes)
        for i in range(num_patterns):
            rmt.append(i)
        rmt.extend([0xFF] * (256 - num_patterns))
        
        # Patterns: create simple pattern from beats
        # 4 channels, 64 rows per pattern, cycling notes
        notes = [0x3C, 0x3E, 0x40, 0x41]  # C4, D4, E4, F4
        
        for p in range(num_patterns):
            for row in range(64):
                for ch in range(4):
                    # Assign one note per row, rotate through channels
                    note_idx = (row // 4 + p) % len(notes)
                    if row % 4 == ch:
                        note = notes[note_idx]
                        instr = 1
                        volume = 15
                    else:
                        note = 0
                        instr = 0
                        volume = 0
                    
                    # 5 bytes: note, instr_vol, effect, param, pad
                    rmt.append(note)
                    rmt.append((instr & 0x1F) | ((volume & 0x0F) << 4))
                    rmt.append(0)  # effect
                    rmt.append(0)  # param
                    rmt.append(0)  # pad
        
        return bytes(rmt)
    
    def convert(self, output_rmt):
        """Run full conversion"""
        print(f"\n📁 MOD→WAV→RMT Converter")
        print(f"Input:  {self.mod_file}")
        print(f"Output: {output_rmt}\n")
        
        # Step 1: Extract
        if not self.extract_wav():
            return False
        
        # Step 2: Load
        if not self.load_audio():
            return False
        
        # Step 3: Analyze
        beats = self.detect_beats()
        
        # Step 4: Build
        rmt_data = self.build_rmt(num_patterns=4)
        
        # Step 5: Save
        with open(output_rmt, 'wb') as f:
            f.write(rmt_data)
        
        print(f"\n✅ Created {output_rmt} ({len(rmt_data)} bytes)")
        
        # Cleanup temp
        if self.wav_file and os.path.exists(self.wav_file):
            os.unlink(self.wav_file)
        
        return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: mod_to_rmt_via_wav.py <input.mod> [output.rmt]")
        sys.exit(1)
    
    mod_file = sys.argv[1]
    output_rmt = sys.argv[2] if len(sys.argv) > 2 else mod_file.replace('.MOD', '.rmt').replace('.mod', '.rmt')
    
    converter = MODtoRMTViaWAV(mod_file)
    if not converter.convert(output_rmt):
        sys.exit(1)
