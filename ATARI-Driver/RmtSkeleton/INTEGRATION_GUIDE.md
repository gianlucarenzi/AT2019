# Integration Guide - Aggiungere il Player RMT al Tuo Progetto cc65

Questo documento spiega passo passo come integrare il player RMT dello skeleton nel tuo progetto cc65, anche quando il programma carica file da disco mentre la musica suona.

## Come il player usa i canali POKEY

**Prima di integrare**, tieni presente come sono divisi i canali:

- **CH1+2**: sempre alla musica RMT, anche durante i caricamenti.
- **CH3+4**: alla musica RMT quando non c'è I/O; alla seriale (generatore di baud rate) tra `rmt_io_begin()` e `rmt_io_end()`.

Durante il caricamento quindi si sente il brano senza i canali 3 e 4. Un brano che usa solo i canali 1+2 suona identico. Dopo `rmt_io_end()` la musica torna a 4 voci da sola.

Vedi `README.md`, sezione "POKEY Channels and Disk I/O", per i dettagli tecnici, e `SFX_INTEGRATION.md` per gli effetti sonori.

---

## Passo 1: Copia i File Necessari

Da RmtSkeleton copia questi file nel tuo progetto:

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

Se il tuo progetto ha un `.gitignore`, non escludere `*.s`: `rmtplayr.s` e `rmtvbi.s` sono sorgenti e vanno nel repository. Escludi solo la cartella di build, dove finisce `song.s` generato.

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

**Importante:** metti `RMTTAB` come **primo** segmento di `MAIN`, prima di `STARTUP`: così parte a `$2000`, già allineato a pagina, senza byte di riempimento.

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

int main(void)
{
    // Inizializza il player
    rmt_init(rmt_song);

    // Avvia la musica (aggancia al VBI)
    rmt_vbi_on();

    // Main game loop
    for (;;) {
        // ... tua logica di gioco ...

        // Se fai accesso a disco (IMPORTANTE!)
        if (should_load_asset()) {
            rmt_io_begin();         // CH3+4 alla seriale, CH1+2 continuano
            // ... operazione SIO ...
            rmt_io_end();           // CH3+4 tornano alla musica
        }
    }

    // Ferma la musica
    rmt_vbi_off();

    return 0;
}
```

Regole:
- Usa `rmt_io_begin()` / `rmt_io_end()` **per ogni operazione SIO**, anche per leggere solo la directory. Meglio racchiudere l'intero file, non il singolo settore.
- **Mai `rmt_vbi_off()` durante un trasferimento**: scrive `AUDCTL = 0` e `SKCTL = 3` e interrompe la seriale.
- Con il player nel VBI il `SIOV` dell'OS perde byte (settori spostati di uno). Usa il loader a interrupt di PokeyATest (`rbl_read_sector` in `../PokeyATest/src/sio.s`, con `dos2fs.c` per i file DOS 2). Vedi `../PokeyATest/doc/GUIDA.md`, capitolo 2.

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
- Errori sulla memoria o sull'allineamento: controlla che RMTTAB sia il primo segmento di MAIN nel .cfg
- Other errors: controlla che rmtplayr.s e rmtvbi.s siano nei percorsi corretti

## Passo 6: Esegui il Programma

```bash
make run    # se hai atari800
```

Il target usa `-nopatchall`: con la patch SIO dell'emulatore attiva la seriale di POKEY viene saltata e i caricamenti non sono realistici.

Ascolta: la musica deve suonare a tempo, e durante i caricamenti (se implementati) devono continuare i canali 1 e 2.

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
unsigned char i;

cprintf("Frames: %u, Last: %u, Max: %u\r\n", rmt_frames, rmt_lines, rmt_maxlines);
cprintf("Deferred: %u, Dropped: %u\r\n", rmt_deferred, rmt_dropped);

// Mostra i volumi dei canali
for (i = 0; i < 4; i++) {
    cprintf("Ch%u volume: %u\r\n", i + 1, rmt_audc[i] & 0x0F);
}
```

Se `rmt_dropped` è > 0, il player sta perdendo tick: il tempo del brano si altera.
Riduci il carico di CPU altrove, soprattutto negli altri gestori di interrupt.

## Limitazioni Tecniche

**✓ Supportato:**
- RMT4 mono (4 tracce, un solo POKEY)
- Instrument speed 1 (player eseguito una volta per frame)
- Canzone di qualunque lunghezza
- Cambio canzone a runtime (tra rmt_vbi_off e rmt_vbi_on)

**✗ NON supportato:**
- RMT8 stereo (rifiutato da rmt2ca65.py)
- Instrument speed > 1 (il brano suona rallentato)
- Player in ROM/cartuccia (è automodificante, va in RAM)
- Fermare il player durante un trasferimento SIO
- Effetti sonori su CH3+4 gestiti dal player (vedi `SFX_INTEGRATION.md`)

## Troubleshooting

### La musica non si sente

1. Assicurati di aver chiamato `rmt_vbi_on()`
2. Controlla che il file .rmt esista e sia leggibile
3. Verifica che il build di song.s sia avvenuto: `head build/song.s`
4. Controlla che il linker abbia linkato song.s

### La musica ha interruzioni

- Se `rmt_dropped` > 0: il player sta perdendo tick (CPU troppo carica)
- Se `rmt_deferred` cresce: è normale (tick rimandati e recuperati), non è un problema se dropped = 0
- Se `rmt_maxlines` > 60: il player impiega molto tempo (ma funziona)

### Linker error sul segmento RMTTAB

Il segmento RMTTAB (638 byte) non entra nello spazio disponibile in MAIN, oppure manca nel .cfg.
Controlla la mappa di memoria nel config.

### La musica cambia intonazione durante il caricamento

Questo è **normale** se la canzone usa AUDCTL per i canali 1/2 (1,79 MHz, 16 bit, 15 kHz, filtri).
Durante SIO, AUDCTL = $28 (baud rate generator).
Componi con canali 1/2 in modalità normale (64 kHz) per evitare questo effetto.

## Riferimenti

- `../PokeyATest/README` – breve descrizione (inglese)
- `../PokeyATest/doc/GUIDA.md` – guida completa (italiano)
- `src/rmt.h` – API C
- `build/rmtskeleton.map` – mappa memoria linker

---

**Domande?** Leggi la GUIDA.md di PokeyATest per i dettagli tecnici completi.
