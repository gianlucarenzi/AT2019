# MOD to RMT Conversion Workflow

## Overview

Convert **ProTracker MOD files** to **RMT (Raster Music Tracker)** format for Atari POKEY audio sequencing.

This guide covers:
1. **Automatic extraction** of note sequences from MOD files
2. **Manual composition** in RMT Editor using extracted notes as reference
3. **Synth design** to match MOD instrument character
4. **Final tuning** for Atari POKEY audio output

---

## Why MOD→RMT Conversion?

| Aspect | MOD | RMT | Match? |
|--------|-----|-----|--------|
| **Format** | Sequencer (ProTracker) | Sequencer (Atari tracker) | ✅ YES |
| **Channels** | 4 channels | 4 channels (POKEY) | ✅ YES |
| **Note Data** | Easily extractable | Directly importable | ✅ YES |
| **Samples/Synth** | Wave-based instruments | Oscillator-based synth | ❌ MANUAL |
| **Timing** | Amiga frequency reference | POKEY frequency reference | ⚠️ REQUIRES ADJUSTMENT |

**Key insight**: Note sequences transfer perfectly. Instrument design requires manual work.

---

## Step 1: Extract MOD Note Sequences

### 1.1 Run the Extractor

```bash
python3 tools/mod_to_rmt_extractor.py <your_file.mod> --output <prefix>
```

**Output files**:
- `<prefix>_ch1.csv` – Channel 1 note sequence
- `<prefix>_ch2.csv` – Channel 2 note sequence
- `<prefix>_ch3.csv` – Channel 3 note sequence
- `<prefix>_ch4.csv` – Channel 4 note sequence
- `<prefix>_report.txt` – Detailed analysis and conversion guide

### 1.2 Examine the Report

The report shows:

```
INSTRUMENTS:
  1. Kick drum          Length: 10320 Vol: 64 Loop: ...
  2. Snare              Length: 7168 Vol: 64 Loop: ...
  3. Hi-hat             Length: 2416 Vol: 64 Loop: ...
  ...

PATTERN TABLE (Song Order):
  0:   2   0   0   1   1   3   4  16   5   6   7   8
 16:  17  18  13  14  13  14   9  10  11  12   5   6

FIRST 2 PATTERNS (per channel):
  Row  CH1        CH2        CH3        CH4
    0  D#4 S64    --- S00    D#2 S176   D#3 S176
    8  D#4 S64    --- S224   --- S176   --- S176
   16  D#4 S64    C-4 S112   --- S176   --- S176
```

**Understanding the output**:
- **Note**: D#4, C-4, etc. (standard MIDI note names)
- **S##**: Sample number used in MOD
- **---**: No note playing (silence)

### 1.3 Analyze CSV Files

Example CSV:
```
Pattern,Row,Note,Sample,Effect,Param
0,0,D#4,64,12,32
0,3,D#4,64,12,20
0,16,C-4,112,0,0
```

This shows:
- **Pattern 0, Row 0**: Play D#4 using Sample 64, Effect 12 (volume slide)
- **Pattern 0, Row 16**: Play C-4 using Sample 112, no effect

---

## Step 2: Launch RMT Editor

### 2.1 Open or Create New Song

RMT Editor is a Windows program. Start with:

```
File → New → Module → 4 Channels → Create
```

### 2.2 Set Module Parameters

```
Song Title:      [Your Song Name]
Speed:           1 (or match MOD speed with adjustment: MOD speed ÷ ~1.2)
Bpm:             125 (or extract from MOD report)
Instruments:     [Create per next section]
```

**Timing Adjustment**:
- MOD default: 6 ticks/row at 125 BPM = ~312 ms per row
- POKEY: RMT speed 1 advances 1 line per VBI (50 Hz PAL = 20 ms/line, 60 Hz NTSC = 16.7 ms/line)
- **Approximate conversion**: MOD speed 6 → RMT speed 6-8 (test in player)

---

## Step 3: Design Synth Instruments

This is the **manual, creative part**. RMT uses oscillator-based synthesis instead of samples.

### 3.1 Instrument Types in RMT

RMT Editor offers several synth algorithms:

- **Saw/Triangle/Pulse**: Basic oscillator waveforms
- **Harmonics**: Multi-oscillator stacking
- **Low-pass filter**: Classic Moog-style LPF
- **FM Synthesis**: Frequency modulation for complex timbres
- **Drums**: Specialized percussion synth

### 3.2 Match MOD Instrument Character

For each MOD instrument, analyze its **sample waveform** and create a similar RMT synth:

| MOD Sample | Characteristic | RMT Synth Strategy |
|-----------|-----------------|------------------|
| **Kick drum** | Deep, boomy, short decay | Pitch-fall envelope + low-pass filter |
| **Snare** | Metallic, white-noise-ish | Pulse wave + high-pass, short envelope |
| **Bass** | Warm, sustained | Sawtooth + low-pass filter, slow envelope |
| **Pad** | Smooth, harmonic | Triangle + harmonic stacking, long decay |
| **Lead** | Bright, articulate | Pulse/square + filter sweep |
| **Cymbal/Hi-hat** | Bright, decaying metallic | High harmonics + quick decay |

### 3.3 RMT Instrument Editor Workflow

For each instrument:

1. **Select synth type** (Osc Type): Saw/Triangle/Pulse/FM/etc.
2. **Adjust waveform**: Duty cycle (for pulse), harmonic mix
3. **Set envelope**:
   - **Attack**: How quickly the note reaches full volume
   - **Decay**: How it falls after attack
   - **Sustain**: Held volume level
   - **Release**: Tail after note ends
4. **Apply filter**:
   - **Cutoff**: Center frequency
   - **Resonance**: Peak emphasis
   - **Envelope**: Modulate cutoff over time
5. **Test**: Play notes and compare to MOD original

**Example**: Kick drum
```
Osc Type:    Saw
Attack:      0 (instant)
Decay:       20 (quick fall)
Sustain:     0 (no sustain)
Release:     5 (small tail)
Cutoff:      800 Hz
Resonance:   High
Cutoff Env:  Pitch fall (fast decay from center freq)
```

### 3.4 Quick Synth Recipes

These are starting points; adjust to taste:

#### Kick Drum
```
Osc:        Sine (lowest distortion for bass)
Att:        0
Dec:        25
Sus:        0
Rel:        5
Filter:     Low-pass, cutoff 400 Hz, resonance 8
```

#### Snare/Drums
```
Osc:        Pulse (Duty 30%)
Att:        0
Dec:        15
Sus:        0
Rel:        5
Filter:     High-pass, cutoff 3000 Hz
```

#### Bass (Sustained)
```
Osc:        Sawtooth
Att:        5
Dec:        10
Sus:        63
Rel:        15
Filter:     Low-pass, cutoff 2500 Hz, resonance 5
```

#### Lead (Bright/Articulate)
```
Osc:        Pulse (Duty 50%)
Att:        2
Dec:        5
Sus:        60
Rel:        10
Filter:     Low-pass, cutoff 4500 Hz, sweep with envelope
```

---

## Step 4: Input Note Sequences

### 4.1 Using CSV as Reference

Open the extracted CSV files side-by-side with RMT Editor:

```
# From CSV (e.g., stardstm_ch1.csv):
Pattern,Row,Note,Sample,Effect,Param
0,0,D#4,64,12,32      ← Play D#4 at pattern 0, row 0
0,3,D#4,64,12,20
0,16,C-4,112,0,0      ← Play C-4 at pattern 0, row 16
```

### 4.2 Enter Notes in RMT

In **RMT Editor's pattern grid**:

1. Click on the row/channel cell
2. Type note (e.g., D#4, C-4, A-3)
3. Press Enter to move to next row
4. Select instrument number from dropdown

**Keyboard shortcuts** (typical):
- Arrow keys: Navigate cells
- 0-9, A-G: Enter note
- # or +: Sharp
- -: Flat
- . (dot): No note
- Backspace: Clear cell

### 4.3 Handle Effects

MOD effects (like volume slides, portamento) don't map directly to RMT.

**Strategy**:
- Copy the **note sequence** exactly (timing + pitch)
- **Ignore MOD effects** initially
- Let RMT's instrument envelope (ADSR) provide texture
- Add RMT-specific effects if needed (chorus, vibrato via instrument synth)

### 4.4 Pattern Structure

MOD patterns are 64 rows. RMT patterns are also 64 rows (default).

**Copy pattern structure from CSV**:
- If a note appears in MOD at row 16, enter it at RMT row 16
- If a note is absent, leave it empty (---)
- Preserve timing relationships exactly

---

## Step 5: Compose Remaining Channels

Repeat **Steps 3-4** for all 4 channels:

1. **CH1**: Usually melody/lead (most important)
2. **CH2**: Supporting melody or harmony
3. **CH3, CH4**: Often drums/bass or countermelody

**Channel assignment strategy**:
- If MOD has clear drum/percussion pattern, map to CH3+4 (as per 2+2 pattern for Atari games)
- If MOD is pure melody (4-channel polyphony), keep all 4 channels for music

---

## Step 6: Set Song Order

### 6.1 Copy Pattern Sequence

From the MOD report's **PATTERN TABLE**:

```
Song Order:
  0:   2   0   0   1   1   3   4  16   5   6   7   8
 16:  17  18  13  14  13  14   9  10  11  12   5   6
```

In **RMT Editor's Song Track view**, enter this sequence into the play order.

### 6.2 Set Loop Points

Most MOD files loop. Set RMT loop:
- Start loop at pattern 0
- End loop at the last pattern before silence

---

## Step 7: Test and Refine

### 7.1 Play in RMT Editor

```
RMT Editor → Play Module
```

**Listen for**:
- ✅ Correct note timing
- ✅ Smooth instrument transitions
- ✅ No unexpected silences
- ❌ Rough/metallic artifacts → tune synth filter
- ❌ Too quiet/loud → adjust instrument volume envelopes
- ❌ Timing feels rushed/sluggish → adjust speed parameter

### 7.2 Compare to Original MOD

Play MOD file in OpenMPT or Milkytracker alongside RMT playback.

**Adjustments**:
- **Pitch offset**: If RMT sounds higher/lower, check octave (C-3 vs C-4)
- **Timing**: If RMT feels faster/slower, adjust speed value
- **Timbre**: If synth doesn't match original, refine filter settings

### 7.3 Optimize for POKEY

Remember: **POKEY is very different from Amiga audio**.

- POKEY has only 4 channels (same as MOD) ✅
- POKEY channels can play different waveforms simultaneously (FM synthesis not directly supported)
- POKEY has no LPF in hardware; RMT implements software filtering
- Atari audio is "lo-fi" compared to Amiga samples

**Accept this**: Exact timbre match is impossible. Goal is to **capture the essence** of the original melody and harmonic structure, not reproduce samples.

---

## Step 8: Export and Integrate

### 8.1 Export to RMT Binary

```
RMT Editor → File → Export → Save as RMT Binary
```

Output: `your_song.rmt` (binary format)

### 8.2 Convert to CA65 Assembly

Use the provided `tools/rmt2ca65.py`:

```bash
python3 tools/rmt2ca65.py your_song.rmt
```

Output: `your_song.s` (assembly source)

### 8.3 Link into Atari Program

Update your Makefile to compile the new module:

```makefile
MODULES = music/gemx.rmt music/your_song.rmt
```

Or add directly to `src/rmtskeleton.cfg` linker script.

### 8.4 Load in C Code

```c
extern unsigned char your_song_module[];

void main(void) {
    rmt_init(your_song_module);
    rmt_vbi_on();
    
    // Now plays background music on CH1+2
}
```

---

## Troubleshooting

### "Notes sound wrong (too high/low)"
- Check octave in RMT note entry
- MOD uses MIDI-like note names; RMT should match exactly
- Example: D#4 (MOD) → D#4 (RMT)

### "Song plays too fast/slow"
- Adjust RMT speed value
- MOD speed 6 typically maps to RMT speed 6-8
- Test in RMT Editor and compare timing

### "Song sounds metallic/harsh"
- Reduce filter resonance
- Increase low-pass filter cutoff for smoother tone
- Test different waveforms (Sine is warmest, Square is harshest)

### "Drums/percussion sounds bad"
- Use high-pass filter for percussion (snare, hi-hat)
- Short ADSR envelopes (fast decay)
- Consider using RMT's drum synthesis modes if available

### "Song doesn't loop correctly"
- Verify loop point in MOD report
- Check song order sequence entered in RMT
- Test loop seamlessly in RMT Editor before export

---

## Example Workflow

### Scenario: Convert "Stardust Memories" (Volker Tripp, 1992)

1. **Extract**:
   ```bash
   python3 tools/mod_to_rmt_extractor.py ~/stardstm.mod --output stardstm
   ```

2. **Analyze**:
   - Read `stardstm_report.txt`
   - Identify instruments (kick, snare, bass, melody)
   - Note the pattern structure (20 unique patterns, 31-row song)

3. **Open RMT Editor**:
   - Create new 4-channel module
   - Set speed 6, BPM 125

4. **Design Synths**:
   - **Instrument 1**: Kick (Sine + LPF 400Hz)
   - **Instrument 2**: Snare (Pulse + HPF 3000Hz)
   - **Instrument 3**: Bass (Sawtooth + LPF 2500Hz)
   - **Instrument 4**: Lead (Pulse + LPF 4500Hz)

5. **Input Notes**: Copy from CSV files
   - CH1: Melody notes (D#4, C-4, A#3, ...)
   - CH2: Counter-melody or harmony
   - CH3: Bass line
   - CH4: Drums/percussion or additional voices

6. **Set Song Order**: From pattern table in report

7. **Test**: Play in RMT Editor, refine synths

8. **Export**: RMT binary → CA65 assembly → Link into game

9. **Integrate**: Load in Atari game, play uninterrupted during SIO!

---

## Tips & Best Practices

1. **Start Simple**: Convert a short, 2-channel MOD first (good test case)
2. **Focus on Melody**: Get the main melodic line perfect before details
3. **Use Headphones**: Small audio details are easier to hear
4. **Reference Often**: Keep MOD and RMT players side-by-side
5. **Iterate**: Synth design is iterative; expect 3-5 refinement passes
6. **Document**: Take notes on instrument settings that work well
7. **Reuse Synths**: Once you've designed a good kick/snare/bass, save as template

---

## Resources

- **RMT Editor**: https://sndh.atari.org/
- **MOD Player (OpenMPT)**: https://openmpt.org/
- **HVSC (High Voltage SID Collection)** - Atari section: https://www.hvsc.c64.org/hvsc/Atari/
- **Atari Audio Guides**: AtariAge wiki

---

## Next Steps

1. ✅ Extract note sequences from your MOD files
2. ✅ Analyze instrument characteristics
3. ✅ Open RMT Editor and start designing synths
4. ✅ Input note sequences per channel
5. ✅ Refine and test
6. ✅ Export, compile, and integrate into Atari game

**Enjoy the process!** 🎵
