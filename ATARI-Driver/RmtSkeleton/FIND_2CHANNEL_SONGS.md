# Come Trovare File RMT con Solo Canali 1+2

Per il tuo progetto con SIO, le canzoni che usano SOLO i canali POKEY 1+2 sono ideali, perché durante il caricamento da disco i canali 3+4 vengono usati dal baud rate generator della seriale e non possono riprodurre musica.

## 🌐 Repository Online di File RMT

### Principali Sorgenti

| Sito | URL | Contenuto |
|------|-----|----------|
| **HVSC** | https://www.hvsc.c64.org/ | Database gigante di musica retro (SID + Atari) |
| **AtariAge** | https://atariage.com/ | Community Atari, archivi musica |
| **GitHub** | https://github.com/search?q=rmt+atari | Collezioni di file RMT |
| **Pouet** | https://www.pouet.net/ | Archivio demo Atari con RMT |
| **ModArchive** | https://modarchive.org/ | Tracker music archive |
| **Atari Mania** | https://www.atarimania.com/ | Database giochi/musica Atari |

### Come Cercare

```bash
# In HVSC
# Vai in: /Atari/ oppure cerca "RMT"

# In GitHub
# Cerca: "atari rmt" oppure "pokey music collection"

# In Pouet
# Filtro: Platform = Atari
#         Search = "RMT"
```

## 🔍 Verificare Quanti Canali USA un RMT

### Metodo 1: Script Python (Consigliato)

Usa lo script `analyze_rmt_fixed.py` fornito:

```bash
python3 analyze_rmt_fixed.py music/mysong.rmt
```

Output:

```
✓ File RMT4 (mono)
  Canali POKEY usati: [1, 2]

✅ USA SOLO CANALI 1+2 - PERFETTO PER IL TUO PROGETTO!
```

o

```
✓ File RMT4 (mono)
  Canali POKEY usati: [1, 2, 3, 4]

⚠️  Usa canali [1, 2, 3, 4]
   Canali che si silenzierebbero durante SIO: [3, 4]
```

### Metodo 2: Batch Check (per una cartella)

Se hai una cartella con molti RMT:

```bash
python3 batch_check_rmt.py /path/to/rmt/files/
```

Output:

```
═══════════════════════════════════════════════════════════
REPORT CANALI RMT
═══════════════════════════════════════════════════════════

✅ PERFETTI (SOLO CH1+2): 12
   ✓ song1.rmt
   ✓ song2.rmt
   ...

⚠️  TUTTI 4 CANALI: 45
   (45 file)

═══════════════════════════════════════════════════════════
TOTALE: 89 file
COMPATIBILI SIO (CH1+2 only): 12 file (13%)
═══════════════════════════════════════════════════════════

💾 File compatibili salvati in: /tmp/rmt_2channel_list.txt
```

### Metodo 3: Hex Editor (Manuale)

Se vuoi ispezionare direttamente:

```bash
xxd -l 20 mysong.rmt
```

Guarda l'offset +10 (tracce lo) e +12 (tracce hi):

```
0000000: ffff 1f40 4041 0104 01ff 0800 0600 0007
         ^^^^  ^^^^^^^^^^                  ^^^^^^
        header   size   ...               tracce
```

Se ai byte +10,+11,+12,+13 vedi solo 2 valori non-zero:
- Byte +10: track_lo[0] (canale 1)
- Byte +11: track_lo[1] (canale 2)
- Byte +12: track_hi[0] (canale 1)
- Byte +13: track_hi[1] (canale 2)
- Byte +14,+15: track_lo[2,3] = 0x00 (canali 3+4 non usati)

**Non facile da leggere così, meglio usare lo script Python!**

## 📥 Come Integrare nel Progetto

Una volta trovato/scaricato un RMT con solo CH1+2:

```bash
# Copia nel skeleton
cp mysong.rmt /path/to/RmtSkeleton/music/

# Verifica
python3 analyze_rmt_fixed.py RmtSkeleton/music/mysong.rmt

# Compila
cd RmtSkeleton
make SONG=music/mysong.rmt
make run
```

## 🎼 Se Vuoi Convertire un RMT a Mano

Se hai un RMT con tutti 4 canali ma vuoi usare solo 1+2:

1. **Non è possibile automaticamente** - la struttura del file RMT lo vieta
2. **Puoi re-arrangiare manualmente** in Raster Music Tracker:
   - Apri il file
   - Copia le tracce dai canali 3+4 ai canali 1+2 (se hai spazio)
   - Ricompila il .rmt
   - Testa se il risultato è musicalmente valido

Questo è manuale e dipende da che cosa c'è nei canali 3+4.

## 📊 Statistiche Approssimative

In una collezione tipica di file RMT:

- ~10-15% usano SOLO canali 1+2 (perfetti per te)
- ~50% usano canali 1+2+3 (parziale loss durante SIO)
- ~30% usano tutti 4 i canali (perdita di basso/batteria durante SIO)
- ~5% altre combinazioni

Quindi circa **1 su 6-10 file** è perfetto per il tuo use case.

## 🔗 Link Utili

- **HVSC Atari**: https://www.hvsc.c64.org/hvsc/Atari/
  - Download: `wget -r https://www.hvsc.c64.org/hvsc/Atari/`

- **GitHub RMT collections**:
  ```bash
  git clone https://github.com/search?q=rmt+collection
  ```
  (cerca fra i risultati i repo con file RMT)

- **Atari XL XE Music Pack** (HVSC):
  - https://www.hvsc.c64.org/ → Download → Atari collection

## 💡 Pro Tips

1. **Filtra per autore**: Cerca compositori che prediligono RMT
   - Raster (autore RMT)
   - C.P.U. (ha scritto molti RMT)
   - Jarek Burczynski

2. **Cerca demo/gara musicale Atari**:
   - Atari demo scene (Pouet)
   - Competition songs di anno in anno
   - Spesso hanno canali limitati

3. **Quando scarichi**:
   - Prendi sempre `instrument speed = 1` (altrimenti suona lento)
   - Prendi solo `RMT4` (mono), non `RMT8` (stereo)
   - Verifica con lo script prima di usare

## 📋 Workflow Completo

```bash
# 1. Scarica un batch di RMT
wget -r https://www.hvsc.c64.org/hvsc/Atari/ -o /tmp/rmt_files

# 2. Analizza tutta la cartella
python3 batch_check_rmt.py /tmp/rmt_files/

# 3. Vedi il report e la lista salvata
cat /tmp/rmt_2channel_list.txt

# 4. Copia i migliori nel tuo progetto
for song in $(head -5 /tmp/rmt_2channel_list.txt); do
  cp /tmp/rmt_files/$song RmtSkeleton/music/
done

# 5. Testa uno
python3 analyze_rmt_fixed.py RmtSkeleton/music/$(head -1 /tmp/rmt_2channel_list.txt)
cd RmtSkeleton && make SONG=music/$(head -1 /tmp/rmt_2channel_list.txt) && make run
```

---

**Domande?** Leggi l'analisi tecnica di SAP/SID/RMT nel tuo prompt iniziale, o la GUIDA.md di PokeyATest.

Buona ricerca! 🎵
