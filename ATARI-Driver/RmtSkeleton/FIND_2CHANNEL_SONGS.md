# Come Trovare File RMT con Solo Canali 1+2

Durante il caricamento da disco i canali 3+4 di POKEY sono il generatore di baud rate della seriale: il player continua a suonare solo i canali 1+2 e riprende il 3 e il 4 a fine caricamento. Un brano che usa **solo i canali 1+2** suona quindi identico anche durante i caricamenti. Un brano a 4 canali va bene lo stesso, ma durante il caricamento perde le voci dei canali 3 e 4.

## 🌐 Dove Cercare File RMT

| Sito | URL | Note |
|------|-----|------|
| **AtariAge** | https://atariage.com/ | forum Atari 8-bit, sezione musica |
| **Pouet** | https://www.pouet.net/ | produzioni Atari 8-bit, spesso con i sorgenti RMT |
| **GitHub** | https://github.com/search?q=rmt+atari | repository con file `.rmt` |

Attenzione: HVSC è solo musica Commodore 64 (SID), e ASMA (archivio musica Atari) contiene file `.sap`, non `.rmt`. Il player accetta solo moduli `.rmt`.

## 🔍 Verificare Quanti Canali Usa un RMT

In un modulo RMT4 la **song** è un elenco di righe da 4 byte, un byte per canale: il numero della traccia da suonare su quel canale, oppure `$FF` se il canale è vuoto. Le righe che iniziano con `$FE` sono salti ("goto"). Un canale è inutilizzato se in tutte le righe vale `$FF`.

Le tabelle `tracks lo/hi` dell'header **non** dicono niente sui canali: sono indicizzate per numero di traccia (un brano può averne decine), non per canale.

### Script

Questo script legge le righe della song e stampa i canali usati:

```python
#!/usr/bin/env python3
# rmtchannels.py file.rmt ... - canali POKEY usati da moduli RMT4
import struct, sys

for fn in sys.argv[1:]:
    d = open(fn, 'rb').read()
    start, end = struct.unpack('<HH', d[2:6])
    m = d[6:6 + end - start + 1]
    if d[:2] != b'\xff\xff' or m[:4] != b'RMT4':
        print(fn, ': non è un modulo RMT4'); continue
    off = struct.unpack('<H', m[14:16])[0] - start   # puntatore alla song
    used = set()
    while off + 3 < len(m):
        if m[off] != 0xFE:                           # $FE = goto
            used |= {c + 1 for c in range(4) if m[off + c] != 0xFF}
        off += 4
    print(fn, ': canali', sorted(used))
```

Esempio:

```
$ python3 rmtchannels.py music/gemx.rmt
music/gemx.rmt : canali [1, 2, 3, 4]
```

Per una cartella: `python3 rmtchannels.py cartella/*.rmt`.

### Gli script in `tools/`

Gli script del progetto usano lo stesso metodo, con un report più dettagliato:

```bash
python3 tools/analyze_rmt_fixed.py music/mysong.rmt   # un file (exit 0 = solo CH1+2)
python3 tools/batch_check_rmt.py cartella/            # una cartella, ricorsivo
```

`batch_check_rmt.py` salva l'elenco dei file con solo CH1+2 in `/tmp/rmt_2channel_list.txt`.

## 📥 Come Integrare nel Progetto

Una volta trovato un RMT adatto:

```bash
cp mysong.rmt RmtSkeleton/music/
cd RmtSkeleton
python3 tools/rmt2ca65.py music/mysong.rmt /dev/null   # RMT4? instrument speed 1?
make SONG=music/mysong.rmt
make run
```

## 🎼 Adattare un Brano a 4 Canali

Non esiste una conversione automatica. In Raster Music Tracker puoi:

- spostare melodia e voci principali sui canali 1 e 2;
- lasciare sui canali 3 e 4 basso, batteria o riempimenti, che durante il caricamento possono tacere senza rovinare il brano;
- evitare, sui canali 1 e 2, gli effetti di `AUDCTL` (1,79 MHz, 16 bit, 15 kHz, filtri): durante il caricamento vale l'`AUDCTL` della seriale (`$28`) e quelle voci cambierebbero timbro o intonazione.

## 💡 Quando Scarichi

- Solo `RMT4` (mono), non `RMT8` (stereo)
- Solo `instrument speed = 1` (altrimenti suona rallentato)
- Verifica con `tools/rmt2ca65.py` e con lo script dei canali prima di usarlo

---

**Domande?** Leggi `README.md` (sezione "POKEY Channels and Disk I/O") o la GUIDA.md di PokeyATest.

Buona ricerca! 🎵
