# Audio Tracker Resampling Guide
## ProTracker/MilkyTracker → RMT/Atari XL/XE

### TL;DR: Quick Decision Tree

```
Your sample is:
├─ Kick/Bass drum (< 1 KB, low freq)  → Resample to 8 kHz
├─ Snare/Percussion (< 2 KB, sharp)   → Resample to 11-16 kHz  
├─ Hi-hat/Cymbals (bright, trasients) → Resample to 16-22 kHz
├─ Melodic/Synth (sustained)          → Resample to 22 kHz (or 16 kHz if tight)
└─ Bass line (sub-harmonics)          → Resample to 11 kHz
```

---

## Atari POKEY Audio Specifications

### Hardware Constraints
- **Channels**: 4 independent (mono 8-bit PCM)
- **Frequency Range**: 30 Hz – 31.5 kHz
- **Bit Depth**: 8-bit unsigned (0-255, where 128 = silence)
- **Volume Resolution**: 4-bit per channel (16 levels)
- **Memory**: Typical cartridge has 16-64 KB free for audio

### CPU Impact
- **Player overhead**: ~60-80 cycles per frame @ 16 kHz
- **Max sustainable**: ~120-160 cycles (real-time constraints)
- **VBI time**: 1/50 sec (PAL, 20 ms) or 1/60 sec (NTSC, 16.7 ms)

---

## Optimal Resampling Frequencies for Atari

| Rate | Quality | Memory (1s) | Use Case | CPU Load |
|------|---------|------------|----------|----------|
| **8 kHz**   | Lo-fi | 8 KB | Drums, bass, effects | 🟢 Low |
| **11 kHz**  | Good | 11 KB | Bass, percussion, voice | 🟢 Low |
| **16 kHz**  | Very Good | 16 KB | Snare, hi-hat, melodic | 🟡 Medium |
| **22 kHz**  | Excellent | 22 KB | Lead, synth (rare) | 🟠 High |

### Why NOT Just 44 kHz?
- **Nyquist**: 44 kHz samples contain info up to 22 kHz
- **Atari POKEY**: Runs at ~8 MHz clock
- **Playback overhead**: Higher rates = more CPU cycles per frame
- **Memory**: 1 second @ 44 kHz = 44 KB (too much for game)

### Why NOT 4-6 kHz?
- ✅ Smallest file size
- ❌ Very lo-fi, notable aliasing
- ❌ Loses high-frequency character
- ❌ Bad for percussion (sounds muffled)

---

## Step-by-Step Resampling Workflow

### 1. Analyze Original Sample

Use the included tool:
```bash
python3 tools/tracker_resampler.py your_song.mod --output analysis.txt
```

This shows:
- Sample duration (in ms)
- Detected frequency content
- Suggested optimal rate
- RMS amplitude and peak level

### 2. Extract Samples from Tracker

#### ProTracker MOD
```bash
python3 tools/mod_to_rmt_extractor.py song.mod --output song
```
Outputs CSV per channel + instrument report.

#### MilkyTracker XM
- Save each instrument as WAV (File → Export → Sample)
- Or use ffmpeg to extract from XM binary

### 3. Resample to Target Frequency

#### Using SoX (command-line)
```bash
# Resample 8363 Hz → 16000 Hz (anti-alias filter included)
sox input.wav -r 16000 output.wav

# Resample with explicit filter quality
sox input.wav -r 16000 -s -b 16 output.wav sinc -t 20
```

#### Using Python + SciPy
```python
from scipy import signal
from scipy.io import wavfile

# Read original
rate, data = wavfile.read('input.wav')

# Resample
new_length = int(len(data) * 16000 / rate)
resampled = signal.resample(data, new_length)

# Save
wavfile.write('output.wav', 16000, resampled.astype(np.int16))
```

#### Using FFmpeg
```bash
ffmpeg -i input.wav -ar 16000 -ac 1 output.wav
```

### 4. Verify Resampling Quality

Listen for:
- ✅ Crisp highs (no muffling)
- ✅ Clear attack (punch preserved)
- ✅ No obvious aliasing (metallic artifacts)
- ✅ Appropriate file size

```bash
# Check file properties
ffprobe output.wav
```

### 5. Convert to RMT Format

Use the RMT Editor or conversion tool:
```bash
python3 tools/wav_to_rmt.py output.wav --rate 16000
```

---

## Sample Categories & Recommendations

### 1. **Drums & Percussion** (Kicks, Snare, Toms)

**Characteristics**:
- Short duration (50-200 ms)
- Sharp attack (important!)
- Energy concentrated in 100-5000 Hz range

**Recommendation**: **8-11 kHz**
```
Kick drum:       8 kHz   (punchy, retro feel)
Snare/Tom:      11 kHz   (preserves click/snap)
Closed hi-hat:  16 kHz   (needs high transient)
```

**Why lower rates work**:
- Duration is short, file size negligible
- Sub-12 kHz captures all meaningful harmonics
- Memory saved for melody/bass

### 2. **Bass & Low-Frequency Instruments**

**Characteristics**:
- Sustained notes (0.5-2 seconds)
- Energy in 50-1000 Hz
- Minimal high-frequency content

**Recommendation**: **11 kHz**
```
Bass guitar:    11 kHz  (one octave preserves fundamental + harmonics)
Sub bass:       11 kHz  (nothing above 5 kHz anyway)
Bassline synth: 11 kHz  (warm, full, sufficient)
```

### 3. **Mid-Range Instruments** (Synths, Pads, Strings)

**Characteristics**:
- Sustained or evolved
- Energy spread 200-8000 Hz
- Require harmonic richness

**Recommendation**: **16 kHz**
```
Electric piano: 16 kHz  (captures harmonics)
Strings/Pad:    16 kHz  (smooth, natural decay)
Organ:          16 kHz  (timbre definition)
```

### 4. **Hi-Fi/Lead Instruments** (Flutes, Bright Synths)

**Characteristics**:
- Bright timbre, lots of harmonics
- Articulate attacks
- Energy up to 10-12 kHz

**Recommendation**: **22 kHz** (or 16 kHz for budget)
```
Lead synth:     22 kHz  (pristine)
Flute/Whistle:  22 kHz  (airy, natural)
```

### 5. **Vocal & Speech**

**Characteristics**:
- Intelligence in 300-8000 Hz
- Intelligibility lost below 4 kHz

**Recommendation**: **16 kHz minimum**
```
Speech:         16-22 kHz (clarity critical)
Vocal melody:   22 kHz    (full expression)
```

---

## Memory & CPU Considerations

### Budget Constraints

**Scenario 1: Game with 32 KB cartridge**
```
Code:              12 KB
Data/Sprites:      10 KB
Available for audio: 10 KB
═════════════════════════════
Maximum song:
  - 2 channels @ 11 kHz = ~22 KB (TOO BIG)
  - 2 channels @ 8 kHz  = ~16 KB (OK but tight)
  - 2 channels @ 8 kHz  = ~5 sec (must loop)

Solution:
  Use 8 kHz for loops
  Keep drum samples < 1 second
  Use 2-channel mode (CH1+2 for music, CH3+4 for SIO)
```

**Scenario 2: Disk-based game**
```
Available: Unlimited (disk is big)
CPU constraint is primary

At 16 kHz playback:
  4 channels = ~80 cycles per frame (OK)
  2 channels = ~40 cycles per frame (plenty headroom)

Recommendation:
  Use 16 kHz for music (excellent quality)
  Use 22 kHz only for critical lead
  Avoid 4-channel at 22 kHz (too slow)
```

### Quick CPU Budget Calculator

```
Total CPU cycles per frame = (sample_rate / 50) * instructions_per_sample
                           = (16000 / 50) * 5  = 1600 cycles

In VBI (3600 cycles available):
  1600 cycles = 44% utilization (SAFE)
  2000 cycles = 55% utilization (OK)
  3000 cycles = 83% utilization (RISKY)
  3500 cycles = 97% utilization (UNSAFE)
```

---

## Common Resampling Problems & Solutions

### Problem: Aliasing (Metallic Artifacts)

**Cause**: Source rate too low, or filter inadequate

**Solution**:
1. Use anti-alias filter BEFORE downsampling
   ```bash
   sox input.wav -r 16000 output.wav sinc -a 120
   ```

2. Increase target rate
   ```bash
   # Instead of 8 kHz, try 11 kHz
   sox input.wav -r 11000 output.wav
   ```

3. Apply gentle EQ to smooth harsh highs
   ```bash
   sox input.wav output.wav equalizer 5000 0.3q -10
   ```

### Problem: Loss of Attack/Transient

**Cause**: Too aggressive low-pass filter during resampling

**Solution**:
1. Use higher-quality resampler (sinc vs linear)
   ```bash
   sox input.wav -r 16000 output.wav sinc -t 20
   ```

2. Increase bitrate (go from 8-bit → higher before downsampling)

3. Use FFmpeg with better resampler
   ```bash
   ffmpeg -i input.wav -ar 16000 -af lowpass=f=7000 output.wav
   ```

### Problem: Wow/Flutter (Pitch Drift)

**Cause**: Incorrect clock calibration in RMT player

**Solution** (in RMT):
- Check BPM and speed settings match original tracker
- Verify playback rate matches Atari system frequency (49.856 Hz PAL)

### Problem: DC Offset (Pops/Clicks)

**Cause**: Sample not centered around zero

**Solution**:
```bash
sox input.wav -c 1 output.wav remix - norm   # Remove DC and normalize
```

---

## Multi-Sample Resampling Workflow

For a full MOD with 31 instruments:

### 1. Analyze All (Automated)
```bash
python3 tools/tracker_resampler.py song.mod --output resampling_plan.txt
```

Sample output:
```
Sample #01: Kick drum
  Suggested: 8000 Hz (short duration)
  
Sample #02: Snare
  Suggested: 11000 Hz (sharp transients)
  
Sample #03: Hi-hat
  Suggested: 16000 Hz (bright, percussive)
```

### 2. Group by Rate
```
8 kHz:   [Kick, Tom, Bass drum]
11 kHz:  [Snare, Hi-hat, Bass]
16 kHz:  [Pad, Strings, Lead]
```

### 3. Batch Resample
```bash
#!/bin/bash
# Resample all samples to their suggested rates

ffmpeg -i Kick.wav -ar 8000 kick_8k.wav
ffmpeg -i Snare.wav -ar 11000 snare_11k.wav
ffmpeg -i Hihat.wav -ar 16000 hihat_16k.wav
```

### 4. Import into RMT

Open RMT Editor:
1. **Instrument 1**: Import `kick_8k.wav`, set speed to 8000 Hz
2. **Instrument 2**: Import `snare_11k.wav`, set speed to 11000 Hz
3. **Instrument 3**: Import `hihat_16k.wav`, set speed to 16000 Hz
4. Adjust volume/envelope for each

### 5. Export and Link
```bash
python3 tools/rmt2ca65.py song.rmt
# Produces song.s for linking into your game
```

---

## Advanced: Custom Resampling Profiles

Some samples might benefit from custom filters. Example profiles:

### Smooth Bass Profile
```bash
# Remove high-frequency noise, preserve sub-bass
sox input.wav -r 11000 output.wav lowpass 5000 rate 11k
```

### Bright Lead Profile
```bash
# Preserve top-end, slight de-ess
sox input.wav -r 22000 output.wav equalizer 8000 0.3q +3 lowpass 10000
```

### Punchy Drum Profile
```bash
# Enhance attack, reduce muffle
sox input.wav -r 16000 output.wav equalizer 100 2q -3 equalizer 3000 0.3q +4
```

---

## References & Tools

### Essential Tools
- **SoX** (command-line resampler): http://sox.sourceforge.net/
- **FFmpeg** (multi-format converter): https://ffmpeg.org/
- **Audacity** (GUI editor): https://www.audacityteam.org/

### Atari-Specific
- **RMT Editor**: https://sndh.atari.org/
- **OpenMPT** (view/export MOD): https://openmpt.org/
- **Milkytracker**: https://milkytracker.titandemo.com/

### Theory
- Nyquist Theorem: https://en.wikipedia.org/wiki/Nyquist_frequency
- Anti-alias filtering: http://sox.sourceforge.net/SoX/Resampling

---

## Quick Checklist

- [ ] Analyze original tracker file
- [ ] Identify sample categories (drums, bass, melodic)
- [ ] Choose target resample rate per category
- [ ] Apply anti-alias filter during resampling
- [ ] Listen for aliasing/artifacts
- [ ] Check file sizes fit memory budget
- [ ] Import into RMT Editor
- [ ] Test in emulator
- [ ] Adjust envelopes/volume per instrument
- [ ] Export to ca65 and link
- [ ] Final playback test on hardware (if possible)

---

## Example: "Stardust Memories" Conversion

Original: **Volker Tripp, 1992** (Amiga MOD, 8363 Hz base)

```
Instrument Analysis:
  1. Kick        Length: 1200 bytes  → 8 kHz  (compact, punchy)
  2. Snare       Length: 2400 bytes  → 11 kHz (need snap)
  3. Hi-hat      Length: 800 bytes   → 16 kHz (bright)
  4. Bass synth  Length: 3200 bytes  → 11 kHz (sub-harmonics)
  5. Lead        Length: 2800 bytes  → 22 kHz (shimmery)

Total memory (original 8363 Hz): ~23 KB
Total memory (optimized):        ~10 KB ✓

CPU load (optimized, 4 channels average 14 kHz): ~70 cycles/frame ✓
```

Result: Smaller file, better quality, fits comfortably in Atari!

---

## Troubleshooting

**Q: "My resampled sample sounds metallic"**  
A: Apply stronger low-pass filter, or increase bitrate before downsampling.

**Q: "Drums sound muffled"**  
A: Switch from 8 kHz to 11 kHz, or check if low-pass cutoff is too aggressive.

**Q: "RMT complains about 'invalid instrument speed'"**  
A: Ensure resampled WAV matches the speed value you set in RMT (e.g., 16000 Hz WAV needs speed=16000).

**Q: "Audio plays at wrong pitch"**  
A: Verify pitch conversion formula. MOD uses Amiga periods; RMT uses playback frequency. Check conversion table.

---

**Happy Resampling!** 🎵🔊
