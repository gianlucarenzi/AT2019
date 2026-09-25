# Checklist - Integrazione e Test del Player RMT

Usa questa checklist quando integri il player RMT nel tuo progetto.

## Pre-Integrazione

- [ ] Ho una canzone in formato .rmt (RMT4 mono, instrument speed 1)
- [ ] Ho copiato i file dal skeleton: rmtplayr.s, rmtvbi.s, rmt.h, rmt_feat.inc
- [ ] Ho copiato tools/rmt2ca65.py
- [ ] Ho un progetto cc65 funzionante (compila, linka, esegue su Atari)

## Configurazione Linker

- [ ] Ho aggiunto il segmento RMTTAB al mio .cfg:
  ```
  RMTTAB: load = MAIN, type = ro, align = $100;
  ```
- [ ] RMTTAB viene PRIMA di STARTUP nel file SEGMENTS
- [ ] Ho mantenuto la configurazione del resto (ZP, MAIN, etc.)
- [ ] Il linker config è corretto (no linker errors dopo `make`)

## Makefile

- [ ] Ho aggiunto la regola di conversione .rmt → .s:
  ```makefile
  $(BUILD)/song.s: music/my_song.rmt tools/rmt2ca65.py
      python3 tools/rmt2ca65.py music/my_song.rmt $@
  ```
- [ ] Ho linkato i file del player:
  - `src/rmtplayr.s` ✓
  - `src/rmtvbi.s` ✓
  - `$(BUILD)/song.s` (generato) ✓
- [ ] `make clean && make` compila senza errori
- [ ] Il file song.s viene generato in build/
- [ ] Il file eseguibile finale viene creato

## Codice C

- [ ] Ho incluso `#include "rmt.h"`
- [ ] Ho chiamato `rmt_init(rmt_song)` **prima** di `rmt_vbi_on()`
- [ ] Ho chiamato `rmt_vbi_on()` per avviare la musica
- [ ] Ho chiamato `rmt_vbi_off()` prima di exit
- [ ] Se uso SIO: `rmt_io_begin()` prima, `rmt_io_end()` dopo
- [ ] Dichiaro tutte le variabili all'inizio della funzione (cc65 è C89, non C99)

## Verifica Compilazione

- [ ] `make clean`
  - [ ] Pulisce build/
- [ ] `make`
  - [ ] song.s viene generato ✓
  - [ ] Nessun linker error ✓
  - [ ] Eseguibile creato ✓
  - [ ] build/*.map creato (per debug) ✓
- [ ] Il file song.s contiene `_rmt_song` (o il tuo simbolo)
  ```bash
  grep "^_rmt_song:" build/song.s
  ```

## Verifica Runtime

Nel tuo programma in esecuzione:

- [ ] La musica inizia quando chiami `rmt_vbi_on()` 
- [ ] Il suono esce dagli altoparlanti Atari
- [ ] La musica suona al tempo corretto (non accelerata/rallentata)
- [ ] Quando premi ESC (o esci), la musica si ferma

## Diagnositca

Stampa questi valori regolarmente:

```c
cprintf("Frames:%5u Max:%3u Def:%5u Drop:%u\r\n",
        rmt_frames, rmt_maxlines, rmt_deferred, rmt_dropped);
```

- [ ] `rmt_frames` incrementa (il VBI sta girando)
- [ ] `rmt_maxlines` < 60 scanline (player tempo normale)
- [ ] `rmt_deferred` è basso (tick rari postponed = normale)
- [ ] `rmt_dropped` = 0 (niente tick persi = musica a tempo)

Se `rmt_dropped` > 0:
- [ ] Ridurre il carico di CPU in altri luoghi
- [ ] Controllare che nessun altro IRQ handler sia troppo lungo
- [ ] Considerare di disabilitare interrupt non critici

## Test Avanzati

Se usi più canzoni:

- [ ] Genero più song.s:
  ```bash
  python3 tools/rmt2ca65.py intro.rmt build/intro.s _rmt_intro
  python3 tools/rmt2ca65.py level1.rmt build/level1.s _rmt_level1
  ```
- [ ] Linkate tutte: `build/intro.s build/level1.s ...`
- [ ] Dichiaro extern nel codice:
  ```c
  extern const unsigned char rmt_intro[];
  extern const unsigned char rmt_level1[];
  ```
- [ ] Cambio canzone correttamente:
  ```c
  rmt_vbi_off();
  rmt_init(rmt_level1);
  rmt_vbi_on();
  ```

Se usi SIO (disk I/O):

- [ ] Quando carico un file, chiamo `rmt_io_begin()` prima
- [ ] Dopo il caricamento, chiamo `rmt_io_end()`
- [ ] La musica si sente meno forte durante il caricamento (canali 3/4 muti = normale)
- [ ] I dati caricati sono corretti (no corruzioni di settore)
- [ ] Nessun errore SIO e musica fluida

## Cleanup

- [ ] Prima di distribuzione, aggiungo i file del player al .gitignore:
  ```
  build/
  *.o
  song.s
  ```
- [ ] NON committo i file generati (solo il .rmt)
- [ ] Committo come sorgenti: main.c, rmtplayr.s, rmtvbi.s, rmt.h, rmt.inc, .cfg, Makefile

## Documentazione

- [ ] Ho aggiornato il README del mio progetto con:
  - come compilare
  - quale canzone usi
  - come cambiarla
  - eventuali limitazioni

## Final Test

- [ ] Compilo da zero: `make clean && make`
  - No errors ✓
  - Eseguibile funziona ✓
- [ ] Provo su un emulatore diverso (se possibile)
- [ ] Se ho atari800: `make run`
  - La musica parte subito ✓
  - Il programma risponde ai comandi ✓
  - Niente lag/interruzioni ✓

---

Se tutto è checkato ✓, il player RMT è integrato correttamente nel tuo progetto!

**Problemi?** Consulta INTEGRATION_GUIDE.md o la GUIDA.md di PokeyATest.
