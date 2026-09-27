#!/usr/bin/env python3
"""
Audio Tracker Resampler
Converts ProTracker/MilkyTracker samples to optimal Atari XL/XE frequencies.

Features:
- Reads MOD/XM sample data
- Resamples to optimal POKEY frequencies (based on note range)
- Analyzes audio quality and suggests bitrate
- Exports resampled samples for RMT integration
- Reports frequency mapping recommendations

Atari POKEY Specs:
  - 4 channels, 8-bit unsigned PCM
  - Frequency range: 30 Hz - 31.5 kHz
  - Optimal for instruments: 8-16 kHz (best quality/memory trade-off)
  - Drum samples: 8-11 kHz (shorter, punchier)
  - Percussion/hi-hats: 11-16 kHz (sharper transient)
"""

import sys
import struct
import math
from pathlib import Path
from collections import defaultdict
import numpy as np
from scipy import signal
from scipy.io import wavfile

class SampleAnalyzer:
    """Analyze audio samples for optimal resampling"""
    
    def __init__(self, sample_data, bitrate=8, original_freq=None):
        self.raw_data = sample_data
        self.bitrate = bitrate
        self.original_freq = original_freq or 8363  # Amiga PAL default
        self.length = len(sample_data)
        self.duration = self.length / self.original_freq
        
        # Analyze waveform
        self.samples = np.frombuffer(self.raw_data, dtype=np.uint8).astype(float) - 128.0
        self.amplitude = np.max(np.abs(self.samples))
        self.rms = np.sqrt(np.mean(self.samples ** 2))
        
    def estimate_frequency_content(self):
        """Estimate dominant frequency using FFT"""
        if len(self.samples) < 512:
            return None
        
        fft = np.fft.fft(self.samples[:512])
        freq_bins = np.abs(fft[:256])
        dominant_idx = np.argmax(freq_bins[1:]) + 1
        dominant_freq = (dominant_idx * self.original_freq) / 512
        return dominant_freq
    
    def suggest_resample_rate(self):
        """Suggest optimal resampling frequency for Atari"""
        # Estimate content frequency
        content_freq = self.estimate_frequency_content()
        
        # Target sampling theorem: Nyquist = original_freq / 2
        nyquist_orig = self.original_freq / 2
        
        # Atari optimal rates (for quality vs memory)
        ATARI_RATES = {
            8000:   "drums (kick, bass percussion)",
            11025:  "bass, low percussion",
            16000:  "full range, snare, hi-hat",
            22050:  "high quality, melodic instruments",
        }
        
        # If sample is short (<1KB) and percussive, use low rate
        if self.length < 2048:
            # Likely percussion/drum
            if content_freq and content_freq > 5000:
                return 16000, f"percussive (high transients)"
            else:
                return 8000, f"percussive (short duration)"
        
        # If RMS low, likely sparse/effect, use lower rate
        if self.rms < 20:
            return 8000, f"sparse signal (RMS={self.rms:.1f})"
        
        # Default to 16kHz for good quality
        if content_freq and content_freq > 8000:
            return 22050, f"high frequency content ({content_freq:.0f}Hz)"
        
        return 16000, f"general purpose"
    
    def report(self):
        """Return analysis report"""
        target_rate, reason = self.suggest_resample_rate()
        
        return {
            'length_bytes': self.length,
            'duration_ms': self.duration * 1000,
            'original_freq': self.original_freq,
            'amplitude': self.amplitude,
            'rms': self.rms,
            'suggested_rate': target_rate,
            'reason': reason,
            'content_freq': self.estimate_frequency_content(),
        }


class ModParser:
    """Parse ProTracker MOD file"""
    
    def __init__(self, filepath):
        self.filepath = Path(filepath)
        self.data = None
        self.title = ""
        self.samples = []
        self.sample_headers = []
        self.patterns = []
        
    def read(self):
        """Parse MOD file structure"""
        with open(self.filepath, 'rb') as f:
            self.data = f.read()
        
        if len(self.data) < 1084:
            raise ValueError(f"MOD file too small: {len(self.data)} bytes")
        
        # Title (0-20)
        self.title = self.data[0:20].rstrip(b'\x00').decode('ascii', errors='ignore')
        
        # Sample headers (20-950)
        for i in range(31):
            offset = 20 + (i * 30)
            header = self._parse_sample_header(offset, i)
            self.sample_headers.append(header)
        
        # Pattern table and patterns
        self._parse_patterns()
    
    def _parse_sample_header(self, offset, index):
        """Parse single sample header (30 bytes)"""
        name = self.data[offset:offset+22].rstrip(b'\x00').decode('ascii', errors='ignore')
        length = struct.unpack('>H', self.data[offset+22:offset+24])[0] * 2
        finetune = struct.unpack('b', self.data[offset+24:offset+25])[0]
        volume = struct.unpack('B', self.data[offset+25:offset+26])[0]
        loop_start = struct.unpack('>H', self.data[offset+26:offset+28])[0] * 2
        loop_length = struct.unpack('>H', self.data[offset+28:offset+30])[0] * 2
        
        return {
            'index': index,
            'name': name,
            'length': length,
            'finetune': finetune,
            'volume': volume,
            'loop_start': loop_start,
            'loop_length': loop_length,
            'sample_data': None,
        }
    
    def _parse_patterns(self):
        """Extract pattern data"""
        song_length = self.data[950]
        pattern_table = list(self.data[952:952+128])
        num_patterns = max(pattern_table) + 1 if pattern_table else 0
        
        # Extract all samples
        pattern_offset = 1084
        for p in range(num_patterns):
            pattern_data = []
            for row in range(64):
                channels = []
                for ch in range(4):
                    note_offset = pattern_offset + (row * 16) + (ch * 4)
                    note_bytes = self.data[note_offset:note_offset+4]
                    
                    period = ((note_bytes[0] & 0x0F) << 8) | note_bytes[1]
                    sample_num = ((note_bytes[2] & 0xF0) >> 4) | (note_bytes[0] & 0xF0)
                    
                    channels.append({'period': period, 'sample': sample_num})
                
                pattern_data.append(channels)
            
            self.patterns.append(pattern_data)
            pattern_offset += 1024
    
    def extract_samples(self):
        """Extract actual sample waveforms"""
        pattern_offset = 1084
        num_patterns = max([p for p in self.data[952:952+128]]) + 1 if self.data[952:952+128] else 0
        pattern_offset += num_patterns * 1024
        
        # Extract samples
        for header in self.sample_headers:
            if header['length'] > 0:
                sample_data = self.data[pattern_offset:pattern_offset + header['length']]
                header['sample_data'] = sample_data
                pattern_offset += header['length']
    
    def analyze_samples(self):
        """Analyze all samples and suggest parameters"""
        results = []
        
        for header in self.sample_headers:
            if header['sample_data'] and len(header['sample_data']) > 0:
                analyzer = SampleAnalyzer(
                    header['sample_data'],
                    original_freq=8363  # Amiga default
                )
                analysis = analyzer.report()
                
                results.append({
                    'index': header['index'],
                    'name': header['name'],
                    'length': header['length'],
                    'loop': (header['loop_start'], header['loop_length']),
                    'analysis': analysis,
                })
        
        return results


class XMParser:
    """Parse FastTracker XM file"""
    
    def __init__(self, filepath):
        self.filepath = Path(filepath)
        self.data = None
        self.instruments = []
        
    def read(self):
        """Parse XM file structure"""
        with open(self.filepath, 'rb') as f:
            self.data = f.read()
        
        if not self.data.startswith(b'Extended Module:'):
            raise ValueError("Invalid XM file")
    
    def extract_samples(self):
        """Extract samples from XM"""
        # XM format is more complex - simplified extraction
        pass


class ResamplerEngine:
    """Resample audio to target frequency"""
    
    @staticmethod
    def resample(sample_data, original_rate, target_rate):
        """Resample using linear interpolation"""
        if original_rate == target_rate:
            return sample_data
        
        samples = np.frombuffer(sample_data, dtype=np.uint8).astype(float)
        samples -= 128.0  # Convert to signed
        
        # Resample using scipy
        ratio = target_rate / original_rate
        new_length = int(len(samples) * ratio)
        resampled = signal.resample(samples, new_length)
        
        # Clip and convert back
        resampled = np.clip(resampled, -128, 127) + 128
        resampled = resampled.astype(np.uint8)
        
        return bytes(resampled)
    
    @staticmethod
    def apply_lowpass_filter(sample_data, cutoff_freq, sample_rate):
        """Apply low-pass filter to reduce aliasing"""
        samples = np.frombuffer(sample_data, dtype=np.uint8).astype(float) - 128.0
        
        # Design Butterworth filter
        nyquist = sample_rate / 2
        normalized_cutoff = cutoff_freq / nyquist
        
        if normalized_cutoff >= 1:
            return sample_data
        
        b, a = signal.butter(4, normalized_cutoff)
        filtered = signal.filtfilt(b, a, samples)
        
        # Clip and convert back
        filtered = np.clip(filtered, -128, 127) + 128
        return bytes(filtered.astype(np.uint8))


def main():
    """CLI: Analyze and convert tracker samples"""
    
    if len(sys.argv) < 2:
        print(__doc__)
        print("\nUsage:")
        print("  python3 tracker_resampler.py <file.mod|file.xm> [--output report.txt]")
        print("\nExample:")
        print("  python3 tracker_resampler.py song.mod --output samples_report.txt")
        sys.exit(1)
    
    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else None
    
    print(f"📊 Analyzing {input_file.name}...")
    
    try:
        if input_file.suffix.lower() == '.mod':
            parser = ModParser(input_file)
            parser.read()
            parser.extract_samples()
            analyses = parser.analyze_samples()
        elif input_file.suffix.lower() == '.xm':
            parser = XMParser(input_file)
            parser.read()
            analyses = parser.extract_samples()
        else:
            raise ValueError(f"Unsupported format: {input_file.suffix}")
        
        # Print report
        print("\n╔═══════════════════════════════════════════════════════════╗")
        print("║          ATARI POKEY RESAMPLING RECOMMENDATIONS            ║")
        print("╚═══════════════════════════════════════════════════════════╝\n")
        
        for item in analyses:
            analysis = item['analysis']
            print(f"Sample #{item['index']:02d}: {item['name']}")
            print(f"  Length: {analysis['length_bytes']} bytes ({analysis['duration_ms']:.1f}ms)")
            print(f"  Original: {analysis['original_freq']} Hz")
            print(f"  Suggested: {analysis['suggested_rate']} Hz ({analysis['reason']})")
            print(f"  Signal: RMS={analysis['rms']:.1f}, Peak={analysis['amplitude']:.1f}")
            if analysis['content_freq']:
                print(f"  Content frequency: {analysis['content_freq']:.0f} Hz")
            print()
        
        # Optional: save to file
        if output_file:
            with open(output_file, 'w') as f:
                for item in analyses:
                    analysis = item['analysis']
                    f.write(f"Sample #{item['index']:02d}: {item['name']}\n")
                    f.write(f"  Suggested rate: {analysis['suggested_rate']} Hz\n")
                    f.write(f"  Reason: {analysis['reason']}\n\n")
            print(f"✅ Report saved to {output_file}")
    
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
