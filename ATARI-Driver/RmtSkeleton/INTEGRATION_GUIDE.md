# Integration Guide - Aggiungere il Player RMT al Tuo Progetto cc65

Questo documento spiega passo passo come integrare il player RMT dal skeleton nel tuo progetto cc65, inclusa la strategia audio ottimale per videogame con caricamento da disco.

## Strategia Audio Consigliata: 2+2 Channels

**Prima di integrare**, capisci il design pattern ottimale per Atari:

- **CH1+2**: Musica di fondo RMT (continua, mai interrotta)
- **CH3+4**: Effetti sonori del gioco (disponibili quando SIO inattivo)

**Vantaggio**: Durante il caricamento da disco, la musica suona **identicamente** perché usa solo CH1+2. Zero glitch audio.

Vedi `README.md` sezione "Audio Design Pattern" per i dettagli tecnici e `SFX_INTEGRATION.md` per come implementare gli effetti sonori.

---

## Passo 1: Copia i File Necessari

Dal skeleton RmtSkeleton copia questi file al tuo progetto:

```
src/rmtplayr.s          player RMT (non modificare)
src/rmtvbi.s            VBI handler (non modificare)
src/rmt.h               header C (non modificare)
src/rmt_feat.inc        feature switches (non modificare)
tools/rmt2ca65.py       convertitore .rmt → .s (non modificare)
```

Copia la tua canzone RMT:

```
music/your_song.rmt
```

## Passo 2: Linker Configuration

Aggiorna il tuo linker config (`.cfg`). Aggiungi il segmento `RMTTAB`:

```
MEMORY {
    ...
    MAIN: file = %O, define = yes, start = %S, size = ...;
    ...
}

SEGMENTS {
    ...
    RMTTAB:    load = MAIN, type = ro, align = $100;    ← AGGIUNGI QUESTA RIGA
    STARTUP:   load = MAIN, type = ro, define = yes;
    ...
}
```

**Importante:** `RMTTAB` **deve precedere** `STARTUP` e altri segmenti di codice. È la prima cosa che entra in MAIN.

Se non hai un linker config personalizzato, copia `rmtskeleton.cfg` e adattalo.

## Passo 3: Makefile

Aggiungi alla regola di build:

```makefile
# Converti .rmt in .s
$(BUILD)/song.s: music/your_song.rmt tools/rmt2ca65.py
	python3 tools/rmt2ca65.py music/your_song.rmt $@

# Link
your_program.com: src/main.c src/rmtplayr.s src/rmtvbi.s $(BUILD)/song.s
	cl65 -t atari -C your_config.cfg -o $@ \
	  src/main.c src/rmtplayr.s src/rmtvbi.s $(BUILD)/song.s
```

Oppure prendi il Makefile dello skeleton e adattalo.

## Passo 4: Includi l'Header nel Codice

Nel tuo main.c (o dove usi la musica):

```c
#include "rmt.h"
#include "sfx.h"     // Se usi effetti sonori

int main(void)
{
    // Inizializza il player
    rmt_init(rmt_song_2channel);
    
    // Avvia la musica (attacca al VBI)
    rmt_vbi_on();
    
    // Main game loop
    for (;;) {
        // ... tua logica di gioco ...
        
        // Gestisci effetti sonori (se SIO inattivo)
        if (player_jumped()) {
            sfx_play(SFX_JUMP);
        }
        
        // Se fai accesso a disco (IMPORTANTE!)
        if (should_load_asset()) {
            rmt_io_begin();         // CH3+4 silenziano, CH1+2 continua
            // ... operazione SIO ...
            rmt_io_end();           // CH3+4 riprendono
        }
    }
    
    // Ferma la musica
    rmt_vbi_off();
    
    return 0;
}
```

**Cosa cambia**: 
- Includi anche `sfx.h` per gli effetti sonori
- Usa `rmt_io_begin()` / `rmt_io_end()` **per ogni operazione SIO**
- Gli effetti sonori vengono muti automaticamente durante SIO (verifichi `rmt_ioactive` interno a `rmt_io_begin`)

Vedi `SFX_INTEGRATION.md` per l'implementazione completa degli effetti sonori.

## Passo 5: Testa la Compilazione

```bash
make clean
make
```

Se tutto funziona:
- `build/song.s` viene generato
- Il linker assembla e linka tutto
- Il file eseguibile è pronto

Se ricevi errori:
- Linker error "undefined symbol rmt_song": assicurati che song.s sia generato
- Linker error "segment conflict": controlla che RMTTAB sia prima di STARTUP nel .cfg
- Other errors: controlla che rmtplayr.s e rmtvbi.s siano nei percorsi corretti

## Passo 6: Esegui il Programma

```bash
make run    # se hai atari800
```

Ascolta: la musica dovrebbe suonare perfettamente, sia durante il gioco che durante caricamenti (se implementati).

## Opzionale: Aggiungere Effetti Sonori

Se vuoi aggiungere effetti sonori su CH3+4:

1. Copia `SFX_INTEGRATION.md` nel tuo progetto
2. Implementa `sfx.c` e `sfx.h` seguendo l'esempio
3. Includi in main.c: `#include "sfx.h"`
4. Chiama `sfx_play()` per effetti (la mutazione durante SIO avviene automaticamente)

Vedi `SFX_INTEGRATION.md` per l'implementazione completa con esempi di codice.

---

## Utilizzo Avanzato

### Cambio Canzone a Runtime

```c
rmt_vbi_off();           // Ferma la musica attuale
rmt_init(rmt_intro);     // Inizializza la nuova canzone
rmt_vbi_on();            // Riavvia la musica
```

Per linkare più canzoni, genera un .s per ciascuna con un nome di simbolo diverso:

```bash
python3 tools/rmt2ca65.py music/intro.rmt build/intro.s _rmt_intro
python3 tools/rmt2ca65.py music/level1.rmt build/level1.s _rmt_level1
```

Nel codice:

```c
extern const unsigned char rmt_intro[];
extern const unsigned char rmt_level1[];

// ...
rmt_init(rmt_intro);
// ...
rmt_init(rmt_level1);
```

### Diagnostica

Leggi questi valori per monitorare il player:

```c
cprintf("Frames: %u, Last: %u, Max: %u\r\n", rmt_frames, rmt_lines, rmt_maxlines);
cprintf("Deferred: %u, Dropped: %u\r\n", rmt_deferred, rmt_dropped);

// Mostra i volumi dei canali
for (int i = 0; i < 4; i++) {
    printf("Ch%d volume: %d\r\n", i+1, rmt_audc[i] & 0x0F);
}
```

Se `rmt_dropped` è > 0, il player sta perdendo tick: il tempo del brano si alterà. 
Riduci il carico di CPU ailleurs.

## Limitazioni Tecniche

**✓ Supportato:**
- RMT4 mono (4 tracce, un solo POKEY)
- Instrument speed 1 (player eseguito una volta per frame)
- Canzone di qualunque lunghezza
- Cambio canzone a runtime (tra rmt_vbi_off e rmt_vbi_on)

**✗ NON supportato:**
- RMT8 stereo (rifiutato da rmt2ca65.py)
- Instrument speed > 1 (il brano suona in rallentatore)
- Player in ROM/cartuccia (è automodificante, va in RAM)
- Interruzione del player durante un trasferimento SIO

## Troubleshooting

### La musica non si sente

1. Assicurati di aver chiamato `rmt_vbi_on()`
2. Controlla che il file .rmt esista e sia leggibile
3. Verifica che il build di song.s sia avvenuto: `cat build/song.s | head`
4. Controlla che il linker abbia linkato song.s

### La musica ha interruzioni

- Se `rmt_dropped` > 0: il player sta perdendo tick (CPU troppo carica)
- Se `rmt_deferred` cresce: normal (tick postponed dal VBI), non è un problema se dropped = 0
- Se `rmt_maxlines` > 60: il player impiega molto tempo (ma funziona)

### Linker error "RMTTAB segment size"

Significa che il segmento RMTTAB è più grande dello spazio disponibile in MAIN.
Controllare lo spazio di memoria disponibile nel config.

### La musica cambia intonazione durante il caricamento

Questo è **normale** se la canzone usa AUDCTL per i canali 1/2 (15 kHz, 16-bit).
Durante SIO, AUDCTL = $28 (baud rate generator). 
Componi con canali 1/2 in modalità normale (64 kHz) per evitare questo effetto.

## Riferimenti

- `../PokeyATest/README` – breve descrizione (inglese)
- `../PokeyATest/doc/GUIDA.md` – guida completa (italiano)
- `src/rmt.h` – API C
- `build/rmtskeleton.map` – mappa memoria linker

---

**Domande?** Leggi la GUIDA.md di PokeyATest per i dettagli tecnici completi.
