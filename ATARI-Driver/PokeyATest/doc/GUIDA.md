# PokeyATest – Guida all'uso

Questa guida spiega come usare, nei propri programmi cc65, i due componenti del test:

1. il **player RMT** in versione ca65 guidato dal VBI;
2. l'**accesso ai file (asset) su disco** tramite SIO, senza DOS residente.

Le interfacce C sono in `src/rmt.h` e `src/dos2fs.h`; `src/main.c` è l'esempio completo.

---

## 1. Player RMT

### 1.1 Cos'è questa versione

È il player *Raster Music Tracker 1.20090108* (Radek Sterba, Raster/C.P.U.) portato
da xasm a **ca65**, con queste differenze rispetto all'originale:

| Originale (xasm)                                 | Questa versione (ca65)                                   |
|--------------------------------------------------|----------------------------------------------------------|
| `PLAYER` deve stare a un indirizzo `$xx00`       | rilocabile: il linker lo mette dove vuole                |
| ~1 KB di variabili fisse prima di `PLAYER`       | variabili in `BSS`, tabelle nel segmento `RMTTAB`        |
| zero page fissa da 203 (`$CB`)                   | 19 byte nel segmento `ZEROPAGE` di cc65                  |
| mono e stereo (`STEREOMODE`)                     | solo mono, 4 canali (un POKEY)                           |
| il modulo `.rmt` va caricato al suo indirizzo    | il modulo viene convertito in sorgente rilocabile        |
| suonato dal programma (sincronia su `VCOUNT`)    | suonato dal **VBI immediato**                            |
| scrive sempre tutti i registri POKEY             | durante l'I/O non tocca canali 3/4 e AUDCTL              |

File coinvolti:

| File                   | Contenuto                                                        |
|------------------------|------------------------------------------------------------------|
| `src/rmtplayr.s`       | il player (codice automodificante, sta in `CODE`, cioè in RAM)   |
| `src/rmt_feat.inc`     | interruttori `FEAT_xxx` (tutti attivi)                           |
| `src/rmtvbi.s`         | aggancio al VBI e interfaccia C                                  |
| `src/rmt.h`            | prototipi C                                                      |
| `src/pokeyatest.cfg`   | config del linker = `atari.cfg` + segmento `RMTTAB` (`align = $100`) |
| `tools/rmt2ca65.py`    | converte un `.rmt` in sorgente ca65 rilocabile                   |

### 1.2 Moduli supportati

- **RMT4** (mono, 4 tracce). I moduli **RMT8** (stereo) vengono rifiutati dal convertitore.
- **Instrument speed 1**, cioè il player viene chiamato una volta per frame. Con valori
  maggiori il brano funziona ma va più lento: il convertitore stampa un warning e il
  programma lo segnala a video.
- Vanno bene sia i moduli "stripped" sia quelli con i nomi di brano/strumenti
  (il secondo blocco del file viene ignorato).

Per sapere se un modulo è adatto:

```sh
python3 tools/rmt2ca65.py mio.rmt /dev/null
# rmt2ca65: mio.rmt -> /dev/null (3727 bytes, 161 relocations, instr speed 1)
```

### 1.3 Conversione del modulo

`rmt2ca65.py` legge il primo blocco del file Atari (`$FFFF`, inizio, fine) e riscrive
come `rmt_song + offset` tutti i puntatori assoluti del modulo:

- i 4 puntatori dell'header (strumenti, tracce lo, tracce hi, song);
- la tabella degli strumenti (le word a 0 sono strumenti inutilizzati);
- le tabelle lo/hi delle tracce (0 = traccia inutilizzata);
- i "goto" della song (righe `$FE, xx, lo, hi`).

Il risultato è un `.s` con il simbolo esportato `_rmt_song` (in C: `rmt_song`)
nel segmento `RODATA`. Nel Makefile:

```make
$(BUILD)/song.s: $(SONG) tools/rmt2ca65.py
	$(PYTHON) tools/rmt2ca65.py $(SONG) $@
```

Per cambiare brano: `make SONG=music/altro.rmt`.
Un terzo argomento opzionale cambia il nome del simbolo, utile per linkare più brani
(in C vanno dichiarati come `extern const unsigned char rmt_intro[];` ecc.):

```sh
python3 tools/rmt2ca65.py intro.rmt build/intro.s _rmt_intro
python3 tools/rmt2ca65.py level1.rmt build/level1.s _rmt_level1
```

### 1.4 API C (`rmt.h`)

```c
extern const unsigned char rmt_song[];                 /* modulo convertito */

unsigned char __fastcall__ rmt_init(const void *module); /* ritorna l'instrument speed */
void rmt_vbi_on(void);      /* aggancia il player al VBI immediato (VVBLKI) */
void rmt_vbi_off(void);     /* ripristina il vettore precedente e zittisce POKEY */

void rmt_io_begin(void);    /* inizio trasferimento SIO: canali 3/4 alla seriale */
void rmt_io_end(void);      /* fine trasferimento: il player riprende tutti i canali */
```

Variabili diagnostiche (aggiornate dal VBI):

| Variabile       | Significato                                                                    |
|-----------------|--------------------------------------------------------------------------------|
| `rmt_frames`    | contatore di VBI (avanza solo con il player agganciato)                        |
| `rmt_lines`     | durata dell'ultima chiamata del player, in scanline                            |
| `rmt_maxlines`  | durata massima misurata (azzerata da `rmt_vbi_on`)                             |
| `rmt_deferred`  | tick rimandati (VBI caduto con I=1) e poi recuperati                           |
| `rmt_dropped`   | tick **persi**: il tempo del brano è stato alterato. Deve restare 0            |
| `rmt_audc[4]`   | valori AUDC calcolati per i 4 canali (volume = 4 bit bassi), per un VU meter   |

### 1.5 Uso tipico

```c
#include "rmt.h"

rmt_init(rmt_song);         /* sempre con il player NON agganciato al VBI */
rmt_vbi_on();               /* da qui la musica suona da sola */

/* ... il programma fa quello che vuole ... */

rmt_vbi_off();              /* fine: zittisce POKEY */
```

Cambio brano:

```c
rmt_vbi_off();
rmt_init(rmt_level1);
rmt_vbi_on();
```

Regole:

- **`rmt_init` solo a player fermo** (dopo `rmt_vbi_off` o prima di `rmt_vbi_on`):
  reinizializza le variabili che il VBI sta usando.
- **Mai `rmt_vbi_off` durante un trasferimento SIO.** Chiama `rmt_silence`, che scrive
  `AUDCTL = 0` e `SKCTL = 3` e interromperebbe la seriale.
- Il player è in `CODE` perché è **automodificante**: non si può mettere in ROM/cartuccia.
- Occupazione: 19 byte di zero page, ~640 byte di tabelle in `RMTTAB`
  (allineate a pagina, per questo il segmento è il primo di `MAIN`, a `$2000`),
  ~160 byte di variabili in `BSS`, più il codice e il modulo.

### 1.6 Perché il VBI immediato e il `CLI`

- Durante ogni operazione SIO l'OS mette `CRITIC` a 1 e **salta il VBI differito**
  (`VVBLKD`). Solo il VBI immediato (`VVBLKI`) gira sempre, quindi il player sta lì.
- Il player può durare 10–40 scanline. La ricezione seriale è a interrupt e a 19200 baud
  arriva un byte ogni ~930 cicli, quindi il VBI esegue un **`CLI`** prima del player
  per non far perdere byte alla seriale.
- Il `CLI` si fa solo se il codice interrotto aveva **I = 0**: il VBI legge il registro P
  salvato dall'NMI (`$0104,X` dopo `TSX`). Se l'NMI è caduto dentro un gestore IRQ,
  un `CLI` lo farebbe rientrare e i dati si corromperebbero. In quel caso il tick viene
  **rimandato**. Lo esegue la coda del gestore seriale (`rmt_irqtick`, pochi µs dopo),
  oppure il VBI successivo con due chiamate. Il tempo del brano non cambia
  (`rmt_deferred` cresce, `rmt_dropped` resta 0).

Chi scrive altri gestori IRQ lunghi può fare come `sio.s`: alla fine del gestore,
con I=1 e l'IRQ già servito, chiamare `jsr rmt_irqtick` (preserva X e Y).

### 1.7 Musica durante il caricamento

Durante un trasferimento i canali 3+4 di POKEY, uniti a 16 bit con clock a 1,79 MHz
(`AUDCTL = $28`), sono il **generatore di baud rate** della seriale. Tra
`rmt_io_begin()` e `rmt_io_end()`:

- il player continua a calcolare tutti e 4 i canali, quindi la song va avanti a tempo;
- scrive solo `AUDF1/AUDC1/AUDF2/AUDC2`;
- non scrive `AUDF3/AUDC3/AUDF4/AUDC4/AUDCTL`;
- `rmt_io_begin()` azzera subito `AUDC3/AUDC4`. Altrimenti l'ultimo volume della musica
  resterebbe acceso mentre la SIO riprogramma `AUDF3/AUDF4`, producendo un fischio.

Il caricamento è quindi **muto**: si sentono solo i canali 1 e 2 del brano.
Con il loader dell'OS serve anche `SOUNDR = 0` (`$41`), che il test imposta all'avvio.

Conseguenze musicali:

- durante il caricamento tacciono le voci sui canali 3 e 4 (spesso basso e batteria);
- se il brano usa AUDCTL per i canali 1/2 (clock a 1,79 MHz, 16 bit, 15 kHz, filtri),
  durante il caricamento vale l'AUDCTL della seriale (`$28`), quindi quelle voci
  possono cambiare timbro o intonazione. Brani con i canali 1/2 "normali" (64 kHz)
  suonano identici.

Consiglio per chi compone: mettere melodia e voci principali sui canali 1 e 2.

---

## 2. Accesso ai file (asset)

### 2.1 Architettura

```
main.c ──> fs_find / fs_load (dos2fs.c)      filesystem DOS 2.x in sola lettura
                    │
                    └─> read_sector() ──┬─> rbl_read_sector (sio.s)   loader IRQ (default)
                                        └─> sio_read_sector (sio.s)   OS SIOV
```

- Non serve un DOS in memoria: il disco si avvia con **MyPicoDos 4.06N** in autorun,
  che carica `PKATEST.COM`, e poi il programma legge i file da sé.
- Il disco è un'immagine ATR standard (DOS 2.x/MyDOS, 720 settori da 128 byte)
  creata con `dir2atr`: si può aprire e modificare con i tool Atari abituali.

### 2.2 API C (`dos2fs.h`)

```c
typedef struct {
	unsigned char  flag;      /* flag della voce di directory */
	unsigned int   sectors;   /* lunghezza in settori */
	unsigned int   start;     /* primo settore */
	unsigned char  fileno;    /* numero file (0..63), controllato nei link */
} fs_entry_t;

typedef struct {
	unsigned int   bytes;       /* byte caricati */
	unsigned int   sectors;     /* settori letti */
	unsigned char  sio_status;  /* DSTATS dell'errore */
	unsigned int   bad_sector;  /* settore che ha dato errore */
} fs_result_t;

unsigned char fs_find(const char *name83, fs_entry_t *e);
unsigned char fs_load(const fs_entry_t *e, unsigned char *dst,
                      unsigned int maxlen, fs_result_t *r);

extern unsigned char fs_unit;      /* drive: 1 = D1: (default) */
extern unsigned char fs_loader;    /* FS_LOADER_RBL (default) o FS_LOADER_OS */
extern unsigned int  fs_retries;   /* letture fallite e ripetute */
extern void (*fs_progress)(unsigned int bytes);  /* callback opzionale */
```

Codici di ritorno:

| Codice        | Significato                                                                 |
|---------------|-----------------------------------------------------------------------------|
| `FS_OK`       | file caricato                                                               |
| `FS_NOTFOUND` | nome non presente in directory                                              |
| `FS_SIOERR`   | lettura fallita 3 volte; `r.sio_status` e `r.bad_sector` dicono quale       |
| `FS_TOOBIG`   | il file supera `maxlen` (i primi byte sono comunque già in `dst`)           |
| `FS_BADLINK`  | catena dei settori incoerente (numero file errato o byte usati > 125)       |

Valori di `sio_status`, uguali a quelli dell'OS: `1` OK, `138` timeout, `139` NAK,
`140` errore seriale (framing/overrun), `143` checksum, `144` errore del drive.

### 2.3 Nomi dei file

`fs_find` vuole il nome nel formato della directory: **11 caratteri, maiuscoli,
nome di 8 caratteri completato da spazi + estensione di 3, senza il punto**.

| Nome sul PC   | `name83`          |
|---------------|-------------------|
| `T02K0.DAT`   | `"T02K0   DAT"`   |
| `LEVEL1.MAP`  | `"LEVEL1  MAP"`   |
| `SPRITES.GFX` | `"SPRITES GFX"`   |

### 2.4 Caricare un file

```c
#include "rmt.h"
#include "dos2fs.h"

static unsigned char buffer[16384];

unsigned char load(const char *name83, unsigned int *len)
{
	fs_entry_t e;
	fs_result_t r;
	unsigned char st;

	*len = 0;
	rmt_io_begin();                     /* SEMPRE, anche solo per la directory */
	st = fs_find(name83, &e);
	if (st == FS_OK) {
		st = fs_load(&e, buffer, sizeof(buffer), &r);
		*len = r.bytes;
	}
	rmt_io_end();

	return st;
}
```

Regole:

- **Ogni accesso al disco va racchiuso tra `rmt_io_begin()` e `rmt_io_end()`**, anche
  `fs_find`, che legge la directory. Vale con entrambi i loader: anche il loader RBL
  riprogramma i canali 3/4 e AUDCTL. È meglio racchiudere l'intero file, non il singolo
  settore: così i canali 3/4 non si riaccendono e spengono a ogni settore.
- `fs_find` rilegge la directory a ogni chiamata: fino a 8 settori, quasi 1 s per i file
  in fondo (ogni settore richiede ~6–7 frame). Se lo stesso file si carica più volte conviene conservare il suo `fs_entry_t`
  e chiamare direttamente `fs_load`.
- `dst` può essere qualsiasi RAM libera, non solo un array: per esempio la finestra
  dei banchi estesi `$4000-$7FFF` (130XE/MegaRAM, 16 KB, esattamente l'asset più grande).
  Non deve sovrapporsi a programma, stack cc65 o memoria video.
- `fs_progress`, se impostata, viene chiamata dopo ogni settore con i byte caricati
  fin lì. Gira nel programma principale, non in interrupt: deve essere breve, perché
  ritarda la richiesta del settore successivo.

### 2.5 I due loader

| | `FS_LOADER_RBL` (default) | `FS_LOADER_OS` |
|---|---|---|
| Implementazione | `rbl_read_sector`, macchina a stati nel gestore `VSERIN` | `sio_read_sector`, `SIOV` dell'OS |
| Con il player nel VBI | sicuro | **perde byte** (settori spostati di uno) |
| Rumore di caricamento | nessuno (canali 3/4 a volume 0) | dipende da `SOUNDR` |
| Velocità misurata (con musica) | ~880 byte/s | – |

Perché `SIOV` non va bene con un player pesante: dopo il byte **Complete** del drive
l'OS riabilita l'IRQ di ricezione con codice non in interrupt (`RECEIV`). Se il VBI
cade lì, il primo byte dei dati arriva a IRQ disabilitato e si perde, e il settore
arriva spostato di un byte. A volte l'OS restituisce perfino status 1 (OK). Nel test
lo si vede premendo **L**: compaiono errori `BADLNK`.

Il loader RBL:

1. invia il command frame (5 byte, `$31+unit-1`, `'R'`, settore lo/hi, checksum)
   a polling con gli IRQ mascherati (~2,6 ms);
2. riceve ACK → Complete → 128 byte → checksum interamente nel proprio gestore IRQ
   (il vettore `VSERIN` viene installato all'inizio di ogni lettura e poi ripristinato);
3. il programma aspetta solo il flag di fine, con un timeout di 150 frame (3 s PAL).

Selezione a runtime: `fs_loader = FS_LOADER_OS;` oppure `FS_LOADER_RBL`.

### 2.6 Formato del filesystem letto

- Directory: settori **361–368**, 8 voci da 16 byte ciascuno
  (`+0` flag, `+1/2` numero settori, `+3/4` primo settore, `+5..12` nome, `+13..15` estensione).
  Una voce con flag `$00` chiude la directory; le voci con bit `$80` sono file cancellati.
- Settore dati (128 byte): byte `0..124` dati, `125` = `numero_file << 2 | settore_successivo_hi`,
  `126` = settore successivo lo, `127` = byte usati. Il settore successivo 0 chiude il file.
- Per le voci con flag bit `$04` (MyDOS, niente numero file) i link sono a 16 bit.
  Questo caso non è stato provato.

### 2.7 Mettere i propri asset sul disco

Basta copiare i file nella cartella **`assets/`** del progetto e lanciare `make`:

```sh
cp ~/grafica/SPRITES.GFX ~/livelli/level1.map assets/
make            # disco con gli asset di test + i tuoi
make run        # il test carica e verifica anche i tuoi file
```

Ogni file di `assets/` viene:

1. copiato su `build/disk/` con il nome in maiuscolo (`level1.map` → `LEVEL1.MAP`);
2. aggiunto alla tabella `build/assets.h` con dimensione e checksum calcolati dal file
   sul PC, quindi il loop di test lo carica e lo verifica come quelli generati;
3. scritto sull'ATR da `dir2atr`.

Variabili del Makefile:

| Variabile      | Default                             | Significato                                        |
|----------------|-------------------------------------|----------------------------------------------------|
| `ASSETS_DIR`   | `assets`                            | cartella dei tuoi file                             |
| `ASSET_SIZES`  | `2048 3500 5120 8000 12288 16384`   | asset di test generati; vuoto = nessuno            |
| `MAXSECTORS`   | `1023`                              | settori massimi accettati per l'ATR                |

```sh
make ASSET_SIZES=                       # sul disco solo i tuoi file
make ASSETS_DIR=../gioco/data           # file presi da un'altra cartella
```

Il disco si ricostruisce da solo quando aggiungi, togli o modifichi un file, o quando
cambi `ASSET_SIZES` da riga di comando (la lista viene salvata in `build/assets.cfg`).

Controlli fatti dalla build, con errore e messaggio esplicito:

- **nome**: deve essere un nome DOS 8.3 valido, cioè una lettera seguita da un massimo di
  7 lettere o cifre, più un'estensione opzionale di massimo 3 lettere o cifre. Maiuscole
  e minuscole sono indifferenti; niente spazi, trattini o underscore. Un nome non valido
  blocca la build invece di essere storpiato da `dir2atr` (che ridurrebbe
  `too_long_name.dat` a un nome diverso da quello della tabella).
- **nome riservato o duplicato**: `PKATEST.COM`, `PICODOS.SYS` e i nomi degli asset di test
  non si possono usare; due file che differiscono solo per le maiuscole sono un duplicato.
- **dimensione**: da 1 a 16384 byte, cioè il buffer del programma di test.
- **capacità**: `dir2atr` ingrandisce il disco oltre i 720 settori se serve. Oltre
  `MAXSECTORS` (1023, il limite dei link a 10 bit del DOS 2) l'ATR viene cancellato
  e la build fallisce. Con 1023 settori ci stanno circa 105 KB di asset.
- **file per disco**: la directory DOS 2 contiene 64 voci, programma e MyPicoDos compresi.

**Autorun.** La modalità `-a` di MyPicoDos è documentata (AtariSIO `README-tools`) per
un disco con un solo file. Con più file MyPicoDos avvia **il primo file della directory**,
e `dir2atr` aggiunge i file in ordine alfabetico: un asset chiamato `ALPHA.BIN` verrebbe
"eseguito" al posto del programma (provato: schermo vuoto o menu). L'estensione `.AR0`
con MyPicoDos 4.06 non fa partire il file, né con `-a` né senza (provato: compare il menu). Per questo, dopo `dir2atr`, il Makefile
lancia `tools/atrorder.py`, che sposta `PKATEST.COM` nella prima voce dopo `PICODOS.SYS`
e riscrive il numero file nei link dei settori dei file spostati. L'immagine resta un
disco DOS 2 valido e i tuoi file possono avere qualsiasi nome.

**Tempo**: ~880 byte/s, quindi un asset da 16 KB richiede circa 19 s.

Nel tuo programma i file si caricano con `fs_find`/`fs_load` usando il nome a 11
caratteri (vedi 2.3): per `LEVEL1.MAP` è `"LEVEL1  MAP"`.

### 2.8 Verifica degli asset del test

`tools/mkassets.py` genera file di dati pseudo-casuali deterministici
(`make ASSET_SIZES="2048 7000 16384"`, dimensioni tra 2048 e 16384), vi aggiunge
i file di `assets/` e scrive `build/assets.h`:

```c
static const asset_t assets[ASSET_COUNT] = {
	{ "T02K0   DAT",  2048, 0xE1D7 },   /* nome 8.3, dimensione, checksum */
	...
};
```

Il checksum è un Fletcher-16 a 8 bit (`s1 += b; s2 += s1`; risultato `s2 << 8 | s1`),
ricalcolato dal programma dopo ogni caricamento. Il nome (`T02K0`) indica i KB
arrotondati per eccesso e l'indice del file.

---

## 3. Test e diagnostica

### 3.1 Esecuzione

```sh
make run
```

Il target lancia atari800 con **`-nopatchall`**. È indispensabile perché
`~/.atari800.cfg` ha `ENABLE_SIO_PATCH=1`: con la patch attiva l'emulatore salta la
seriale di POKEY e il caricamento diventa istantaneo, quindi il test non vale niente.
La prova che la patch è spenta sono i ~900 byte/s misurati.

### 3.2 Schermo

```
Loader: RBL IRQ SIO  [L]                 loader in uso
OS SIO noise: OFF  [S]  [ESC]quit        SOUNDR (solo loader OS)
Music: CH1+2 only (SIO owns CH3+4)       modalità I/O in corso
1:###... 2:#####. 3:#..... 4:######      volumi dei 4 canali
Player: 12 ln (max 36) late 345 lost0    durata player, tick rimandati/persi
Pass 2  OK 7  ERR 0  RETRY 0             passate, file OK/errati, retry
T02K0   .DAT OK  2048  122fr  839b/s     byte, frame impiegati, velocità
```

Un test è riuscito se `ERR 0`, `RETRY 0` e `lost 0`.

### 3.3 Varianti di debug

```sh
make clean all DEFS=-DTEST_NOMUSIC    # solo loader, senza player: velocità di riferimento
make clean all DEFS=-DSTOP_ON_ERROR   # blocca lo schermo al primo errore
```

In caso di `BADLNK` il test stampa il settore e i byte `125 126 127 0 1` letti:
confrontandoli con l'ATR (offset `16 + (settore-1)*128`) si capisce se il settore
è arrivato spostato o se è un altro settore.

### 3.4 Risultati misurati (atari800, PAL, 19200 baud)

| Configurazione              | Velocità   | Esito                                          |
|-----------------------------|------------|------------------------------------------------|
| senza musica, OS SIOV       | ~960 B/s   | 0 errori                                       |
| musica, loader RBL          | ~880 B/s   | 0 errori, 0 retry, 0 tick persi (1216 file)    |
| musica, OS SIOV             | –          | ~70% dei file con settori spostati             |

Non ancora provato su hardware reale.

### 3.5 Limiti

- Settori da 128 byte (SD/ED), 19200 baud; drive `D1:`–`D8:` tramite `fs_unit`.
- Moduli RMT mono (RMT4), player chiamato una volta per frame.
- Il loader RBL non implementa scrittura né formati ad alta velocità.
