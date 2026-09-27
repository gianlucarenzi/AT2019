#!/usr/bin/env python3
"""
MP3 → MOD Simplified Converter
Works on Debian 11 (Bullseye) and Debian 13 (Trixie)
No heavy dependencies - uses only: numpy, scipy, soundfile

Pipeline:
  1. Load MP3 → extract waveform
  2. Detect beats (energy-based)
  3. Build MOD file with simple patterns
  4. Output MOD suitable for RMT conversion
"""

import sys
import struct
from pathlib import Path
import numpy as np
from scipy import signal

try:
    import soundfile as sf
except ImportError:
    print("❌ soundfile not installed")
    print("Install with: python3 -m pip install soundfile")
    sys.exit(1)


class SimpleMP3toMOD:
    """Lightweight MP3 to MOD converter"""
    
    def __init__(self, mp3_file):
        self.mp3_file = Path(mp3_file)
        self.audio = None
        self.sr = None
        self.duration = None
        self.bpm = 120  # Default
        
    def load_audio(self):
        """Load MP3 using ffmpeg + soundfile"""
        print(f"🎵 Loading {self.mp3_file.name}...")
        
        # Use ffmpeg to decode MP3 to WAV
        import subprocess
        import tempfile
        
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
            tmp_path = tmp.name
        
        try:
            # Convert MP3 to WAV
            result = subprocess.run(
                ['ffmpeg', '-i', str(self.mp3_file), '-q:a', '9', '-y', tmp_path],
                capture_output=True,
                timeout=30
            )
            
            if result.returncode != 0:
                print(f"⚠️  ffmpeg error: {result.stderr.decode()[:200]}")
            
            # Load WAV
            self.audio, self.sr = sf.read(tmp_path)
            
            # Convert to mono if stereo
            if len(self.audio.shape) > 1:
                self.audio = np.mean(self.audio, axis=1)
            
            self.duration = len(self.audio) / self.sr
            
            Path(tmp_path).unlink()
            
        except FileNotFoundError:
            print("⚠️  ffmpeg not found - trying direct MP3 load...")
            try:
                self.audio, self.sr = sf.read(str(self.mp3_file))
                if len(self.audio.shape) > 1:
                    self.audio = np.mean(self.audio, axis=1)
                self.duration = len(self.audio) / self.sr
            except Exception as e:
                print(f"❌ Cannot load MP3: {e}")
                return False
        
        print(f"  Sample rate: {self.sr} Hz")
        print(f"  Duration: {self.duration:.2f}s")
        print(f"  Samples: {len(self.audio)}")
        
        return True
    
    def detect_beats(self):
        """Simple beat detection using energy peaks"""
        print("\n🥁 Detecting beats...")
        
        # Compute energy per frame (1024 samples = ~23ms at 44.1kHz)
        frame_size = 1024
        energy = []
        
        for i in range(0, len(self.audio) - frame_size, frame_size):
            frame = self.audio[i:i+frame_size]
            e = np.sqrt(np.mean(frame ** 2))
            energy.append(e)
        
        energy = np.array(energy)
        
        # Smooth energy
        energy_smooth = signal.medfilt(energy, kernel_size=11)
        
        # Detect peaks (beats)
        threshold = np.mean(energy_smooth) * 1.5
        beats = np.where(energy > threshold)[0]
        
        # Cluster beats (remove duplicates within 10 frames)
        beat_times = []
        if len(beats) > 0:
            current_beat = beats[0]
            beat_times.append(current_beat * frame_size / self.sr)
            
            for b in beats[1:]:
                if b - current_beat > 10:
                    beat_times.append(b * frame_size / self.sr)
                    current_beat = b
        
        # Estimate BPM from beat intervals
        if len(beat_times) > 1:
            intervals = np.diff(beat_times)
            avg_interval = np.median(intervals)
            if avg_interval > 0:
                self.bpm = 60.0 / avg_interval
        
        print(f"  Found {len(beat_times)} beats")
        print(f"  Estimated BPM: {self.bpm:.1f}")
        
        return beat_times
    
    def build_mod(self, output_file):
        """Build MOD file"""
        print("\n📝 Building MOD file...")
        
        # Load audio
        if not self.load_audio():
            return False
        
        # Detect beats
        beats = self.detect_beats()
        
        # Resample to 11025 Hz (MOD standard for Atari)
        target_sr = 11025
        ratio = target_sr / self.sr
        new_length = int(len(self.audio) * ratio)
        
        print(f"  Resampling {self.sr} → {target_sr} Hz...")
        resampled = signal.resample(self.audio, new_length)
        
        # Normalize to 8-bit unsigned
        resampled = np.clip(resampled, -1.0, 1.0)
        resampled = ((resampled + 1.0) / 2.0 * 255).astype(np.uint8)
        
        # Build MOD file structure
        mod_data = bytearray()
        
        # 1. Module title (20 bytes)
        title = self.mp3_file.stem.encode('ascii')[:20].ljust(20, b'\x00')
        mod_data.extend(title)
        
        # 2. Sample headers (31 × 30 bytes)
        for i in range(31):
            if i == 0:
                # First sample: the resampled audio
                sample_name = b"mp3_audio".ljust(22, b'\x00')[:22]
                sample_length_words = (len(resampled) + 1) // 2  # Length in 16-bit words
                
                mod_data.extend(sample_name)
                mod_data.extend(struct.pack('>H', sample_length_words & 0xFFFF))
                mod_data.append(0)      # Finetune
                mod_data.append(64)     # Volume
                mod_data.extend(struct.pack('>H', 0))      # Loop start
                mod_data.extend(struct.pack('>H', 0))      # Loop length
            else:
                # Empty samples
                mod_data.extend(b'\x00' * 30)
        
        # 3. Song length (1 byte)
        num_patterns = 4
        mod_data.append(num_patterns)
        
        # 4. Restart position (1 byte)
        mod_data.append(0x7F)
        
        # 5. Pattern table (128 bytes)
        for i in range(128):
            if i < num_patterns:
                mod_data.append(i)
            else:
                mod_data.append(0)
        
        # 6. Magic "M.K." (4 bytes) - identifies as 4-channel MOD
        mod_data.extend(b'M.K.')
        
        # 7. Pattern data
        print(f"  Writing {num_patterns} patterns...")
        
        for pattern_idx in range(num_patterns):
            # Each pattern is 64 rows × 4 channels × 4 bytes
            pattern_data = bytearray()
            
            for row in range(64):
                for ch in range(4):
                    # Simple pattern: play sample on beat
                    if ch == 0:
                        # Check if this row corresponds to a beat
                        row_time = (row / 64) * (pattern_idx * 64 / (self.bpm / 60))
                        
                        # Simplified: every 4 rows, trigger sample
                        if row % 4 == 0:
                            # Period for middle C (~1200)
                            period = 400 + (row % 16) * 20
                            sample = 1
                        else:
                            period = 0
                            sample = 0
                    else:
                        period = 0
                        sample = 0
                    
                    # Pack into 4 bytes (ProTracker format)
                    if period > 0:
                        period_hi = (period >> 8) & 0x0F
                        period_lo = period & 0xFF
                        sample_hi = (sample >> 4) & 0x0F
                        sample_lo = (sample & 0x0F) << 4
                        
                        pattern_data.extend([
                            period_hi | sample_lo,
                            period_lo,
                            sample_hi,
                            0,  # Effect
                        ])
                    else:
                        pattern_data.extend([0, 0, 0, 0])
            
            mod_data.extend(pattern_data)
        
        # 8. Append audio sample data
        print(f"  Appending audio sample ({len(resampled)} bytes)...")
        mod_data.extend(resampled)
        
        # Write file
        with open(output_file, 'wb') as f:
            f.write(mod_data)
        
        print(f"\n✅ MOD file created: {output_file}")
        print(f"   Size: {len(mod_data)} bytes")
        print(f"   BPM: {self.bpm:.1f}")
        print(f"   Duration: {self.duration:.2f}s")
        
        return True


def main():
    """CLI interface"""
    if len(sys.argv) < 2:
        print(__doc__)
        print("\nUsage:")
        print("  python3 mp3_to_mod_simple.py <file.mp3> [--output output.mod]")
        print("\nExample:")
        print("  python3 mp3_to_mod_simple.py 'music/01 Broken the Promises.mp3'")
        print("\nRequired:")
        print("  - ffmpeg (for MP3 decoding)")
        print("  - python3-scipy python3-numpy python3-soundfile")
        sys.exit(1)
    
    mp3_file = Path(sys.argv[1])
    
    if not mp3_file.exists():
        print(f"❌ File not found: {mp3_file}")
        sys.exit(1)
    
    output_mod = None
    if '--output' in sys.argv:
        idx = sys.argv.index('--output')
        if idx + 1 < len(sys.argv):
            output_mod = Path(sys.argv[idx + 1])
    
    if output_mod is None:
        output_mod = mp3_file.with_suffix('.mod')
    
    converter = SimpleMP3toMOD(mp3_file)
    
    try:
        success = converter.build_mod(output_mod)
        
        if success:
            print("\n" + "="*60)
            print("✨ Next steps:")
            print(f"   1. Open {output_mod} in OpenMPT")
            print(f"   2. Verify note timing and pattern")
            print(f"   3. Refine manually if needed")
            print(f"   4. Save as MOD")
            print(f"   5. Convert to RMT:")
            print(f"      python3 tools/rmt2ca65.py {output_mod}")
            print("="*60)
        else:
            sys.exit(1)
    
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
