# MP3 → MOD → RMT Conversion Pipeline
## Trasformare canzoni MP3 in file Atari XL/XE

---

## ⚠️ ASPETTATIVE REALISTICHE

Prima di iniziare, è importante capire che **MP3 → MOD NON è una conversione perfetta**:

| Aspetto | MP3 | MOD | Risultato |
|---------|-----|-----|-----------|
| **Forma d'onda** | Compresso, flusso continuo | Discreto (campioni) | ⚠️ Approssimazione |
| **Strumenti** | Misti insieme | Separati (per canale) | ⚠️ Estrazione difficile |
| **Note/timing** | Analogico, fluido | Griglia ritmica quantizzata | ⚠️ Perdita di espressione |
| **Qualità audio** | Piena | Limitata da memoria Atari | ⚠️ Compromesso |

**Bottom line**: Aspettati un'**approssimazione utile**, non una replica 1:1.

---

## Pipeline Automatica

### Step 1: Installare Dipendenze

```bash
pip install librosa soundfile numpy scipy
```

Opzionale (per migliore qualità):
```bash
pip install demucs  # Stem separation (vocals, drums, bass)
```

### Step 2: Convertire MP3 → MOD

```bash
cd RmtSkeleton

# Analizza + crea MOD
python3 tools/mp3_to_mod.py "music/01 Broken the Promises.mp3" \
  --output "music/01_auto.mod"
```

Output mostrerà:
- ✅ BPM rilevato
- ✅ Chiave musicale
- ✅ Beat rilevati
- ✅ Note estratte
- ✅ MOD file generato

### Step 3: Verificare e Raffinare

```bash
# Aprire in OpenMPT (Windows) o MilkyTracker (multi-piattaforma)
# URL: https://openmpt.org/ o https://milkytracker.titandemo.com/

# Controllare:
#  ✓ Timing delle note correct?
#  ✓ BPM e speed? (MOD speed 6-8 è tipico)
#  ✓ Instrument assignment? (drums, bass, melodia su canali diversi)
#  ✓ Loop points?
```

### Step 4: Esportare come RMT

```bash
# Dalla cartella RmtSkeleton:
python3 tools/rmt2ca65.py "music/01_auto.mod" \
  --output "music/01_auto.s"
```

### Step 5: Linkare nel Progetto

```makefile
# Nel vostro Makefile:
MODULES = music/01_auto.rmt

# O usare direttamente il .s generato
```

---

## Workflow Manuale (Migliore Qualità)

Se il risultato automatico non soddisfa, usare il workflow **semi-manuale**:

### 1. Extracción Audio (Stem Separation)

```bash
# Separare strumenti (se hai demucs)
demucs "music/01 Broken the Promises.mp3" -o separated

# Risultato: drum_stems/, bass_stems/, other_stems/, vocals_stems/
```

### 2. Analizzare Separatamente

```bash
# Per ogni stem (drums, bass, melodia), analizzare indipendentemente
python3 tools/mp3_to_mod.py separated/drums.wav --output drums.mod
python3 tools/mp3_to_mod.py separated/bass.wav --output bass.mod
python3 tools/mp3_to_mod.py separated/other.wav --output melody.mod
```

### 3. Merge in MOD

Aprire OpenMPT:
1. Creare nuovo MOD 4 canali
2. Importare patterns da:
   - drums.mod → Canale 3+4
   - bass.mod → Canale 1 o 2
   - melody.mod → Canale restante
3. Sincronizzare timing
4. Regolare volumi e envelope

### 4. Esportare RMT

```bash
python3 tools/rmt2ca65.py final_song.mod --output final_song.s
```

---

## Troubleshooting

### Problema: "Librosa not found" / Import error

**Soluzione**:
```bash
pip install librosa --user
# o
python3 -m pip install librosa
```

### Problema: MOD file creato ma note sbagliate

**Cause**:
- Estrazione MIDI imprecisa (normale!)
- Chiave rilevata sbagliata
- Audio troppo complesso

**Soluzione**:
1. Usare OpenMPT per correggere manualmente
2. O ricreare direttamente in RMT (ctrl+C, ricomincia con formato vettoriale)

### Problema: Audio troppo silenzioso/forte

**Soluzione**:
```bash
# Normalizzare MP3 prima della conversione
ffmpeg -i "input.mp3" -af "loudnorm=I=-23:TP=-1.5:LRA=11" "normalized.mp3"

# Poi convertire:
python3 tools/mp3_to_mod.py normalized.mp3 --output output.mod
```

### Problema: Timing non sincronizzato

**Soluzione**:
- Verificare BPM rilevato dal tool vs BPM reale
- In MOD, regolare speed (File → Module Properties → Speed)
- Tipico: BPM 120 → MOD speed 6

---

## Alternativa: Ricreazione Diretta in RMT

Se il workflow MP3→MOD non soddisfa, **ricreazione manuale in RMT** spesso è migliore:

### Vantaggi
- ✅ Controllo totale sulla qualità
- ✅ Adattato specificamente a POKEY
- ✅ Migliore sfruttamento dei 4 canali
- ✅ Niente dipendenze da AI/estrazione

### Come
1. Ascoltare MP3
2. Aprire RMT Editor
3. Cominciare a digitare note manualmente
4. Disegnare synth strumenti per ognuno
5. Perfezionare iterativamente

**Tempo**: 1-2 ore per canzone breve, ma risultato professionale!

---

## Specifiche Atari XL/XE per Importazione

Quando importi in MOD/RMT:

### Sample Rate (Velocità)
- **Amiga default**: 8363 Hz (PAL)
- **Atari POKEY target**: 11025 Hz (best balance)
- **Conversione**: Scalare BPM × (11025/8363) ≈ 1.32

### Canali Consigliati
```
┌─────────────────────────┐
│ CH1: Melodia principale │
│ CH2: Armonia/contropunto│
│ CH3: Drums/Percussion   │
│ CH4: Bass/Effetti       │
└─────────────────────────┘
```

### Bitrate
- **8-bit signed PCM** (standard MOD)
- **11025 Hz** per memoria ottimale
- **Mono** (ogni canale indipendente)

---

## Workflow Completo: Esempio

**File**: `01 Broken the Promises.mp3`

```bash
# 1. Analizzare
python3 tools/mp3_to_mod.py "music/01 Broken the Promises.mp3"

# Output:
#   🎵 Loading 01 Broken the Promises.mp3...
#   Sample rate: 44100 Hz
#   Duration: 3.24s
#   Detected BPM: 112.5
#   Estimated key: G major
#   Suggested MOD speed: 3

# 2. Convertire
python3 tools/mp3_to_mod.py "music/01 Broken the Promises.mp3" \
  --output "music/01_broken.mod"

# 3. Aprire in OpenMPT
# Verificare: note, timing, BPM, instruments
# Refine se necessario

# 4. Salvare come MOD

# 5. Convertire a RMT
python3 tools/rmt2ca65.py "music/01_broken.mod" \
  --output "music/01_broken.s"

# 6. Nel Makefile:
# MODULES = music/01_broken.rmt

# 7. Compilare e testare:
make clean && make run
```

---

## Tool Supplementari (Opzionali)

### **OpenMPT** (Windows/Linux)
- GUI completo per MOD editing
- Visualizzazione patterns
- Test playback
- https://openmpt.org/

### **MilkyTracker** (Cross-platform)
- Editor MOD/XM minimalista
- Buon per il raffinamento
- https://milkytracker.titandemo.com/

### **SoX** (Command-line audio)
```bash
# Normalizzare volume
sox input.wav -n norm

# Resample
sox input.wav -r 22050 output.wav

# Applicare EQ
sox input.wav output.wav equalizer 100 2q -3
```

### **FFmpeg** (Conversione formati)
```bash
# Convertire MP3 → WAV (formato grezzo)
ffmpeg -i input.mp3 output.wav

# Mixare stereo → mono
ffmpeg -i stereo.wav -ac 1 mono.wav
```

---

## Limiti e Considerazioni

### Non è Possibile
- ❌ Estrarre **perfettamente** nota/timing da MP3 (format compresso)
- ❌ Separare completamente strumenti senza AI (e AI non è perfetta)
- ❌ Mantenere qualità originale a POKEY bitrate

### È Possibile
- ✅ Creare versione **riconoscibile** di una canzone
- ✅ Catturare **struttura ritmica e melodica**
- ✅ Usare come **base** per ulteriore editing
- ✅ Converitere **velocemente** in formato Atari

---

## Prossimi Passi

1. ✅ Installa librosa: `pip install librosa`
2. ✅ Prova conversione: `python3 tools/mp3_to_mod.py music/01*.mp3`
3. ✅ Apri risultato in OpenMPT per verificare
4. ✅ Raffina manualmente se necessario
5. ✅ Esporta a RMT con `rmt2ca65.py`
6. ✅ Testa in emulatore

---

## Domande Comuni

**D: Quanto è fedele la conversione?**  
R: ~60-70%. Struttura ritmica e melodica sì, dettagli di effetti/dinamica no.

**D: Meglio MP3→MOD o ricreazione manuale?**  
R: Dipende da tempo disponibile. MP3→MOD veloce ma approssimativo. Manuale più lungo ma migliore qualità.

**D: Posso usare MP3 direttamente in RMT?**  
R: No, RMT vuole MOD o synth. MP3 è per riferimento (ascoltare mentre riscrivl).

**D: Come gesto copyright?**  
R: Conversione per hobby OK. Distribuzione pubblica = rispetto copyright originale.

---

**Buona conversione!** 🎵→📝→🎮
