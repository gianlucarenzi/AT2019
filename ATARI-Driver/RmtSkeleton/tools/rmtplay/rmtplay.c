/*
 * rmtplay - RMT module player for the PC (SDL2)
 *
 * Plays a .rmt module with the real Atari player routine: src/rmtplayr.s
 * (RMT 1.20090108, the same code linked in the Atari program) is assembled
 * by ca65 and runs here on a 6502 emulator, once per frame like on the
 * immediate VBI (instrument speed N: N calls back to back, as src/rmtvbi.s
 * does); its POKEY writes drive a POKEY emulation.
 *
 * A .sap (type B) or .xex exported by RITMO / RMT (VU-Player LZSS streams)
 * is played by src/lzsplayr.s, as the Atari and C64 programs do: one
 * subtune is taken out of the file, as tools/sap2ca65.py does, into a
 * module at $1000. Mono only.
 *
 * With -c64 it plays as the Commodore 64 player (../../../rmt_cbm64): the
 * same routine assembled with -D RMT_C64 writes the POKEY registers to RAM,
 * the POKEY -> SID code of that project (sidrmt.s) turns them into SID
 * registers once per frame (instrument speed N: the N calls at the raster
 * lines sidrmt.s computes, the SID after the last one), and they drive a SID
 * emulation.
 *
 * Usage: rmtplay [options] file.rmt|file.sap|file.xex
 *   -t sec     stop after sec seconds (default: until Ctrl+C; WAV: 60)
 *   -w file    render to a WAV file instead of playing
 *   -n         NTSC (60 Hz frames) instead of PAL (50 Hz)
 *   -c64       Commodore 64: POKEY -> SID as rmt_cbm64 does
 *   -s n       subtune n of a .sap / .xex (default 0)
 *   -io sec    simulate disk loading: every sec seconds toggle the player
 *              I/O mode (rmt_io_begin/rmt_io_end), only channels 1+2 play
 *   -r         dump POKEY registers written by the player, one line per frame
 *              (with -c64 also SID frequency, waveform and level of the 3
 *              voices, and the POKEY channel each one plays)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <SDL.h>

#include "cpu6502.h"
#include "pokey.h"
#include "sid.h"
/* generated: player binaries and their addresses */
#include "atari_rmt_bin.h"      /* src/rmtplayr.s */
#include "atari_lzs_bin.h"      /* src/lzsplayr.s */
#include "c64_rmt_bin.h"        /* rmt_cbm64: rmtplayr.s -D RMT_C64 + sidrmt.s */
#include "c64_lzs_bin.h"        /* rmt_cbm64: lzsplayr.s -D RMT_C64 + sidrmt.s */

#define PLAYER_BASE 0xA000      /* rmtplay.cfg, rmtplay_c64.cfg */
#define LZS_MODULE  0x1000      /* where a .sap / .xex subtune is put */

typedef struct {
	const uint8_t *bin;
	unsigned size;
	uint16_t entry, ioactive;                       /* rmtplayr.s / lzsplayr.s */
	uint16_t sid_init, pokey_to_sid, shadow;        /* sidrmt.s (C64) */
	uint16_t sid_src, sid_volume, sid_flo, sid_fhi, sid_wave;
	uint16_t ispeed, line_lo, line_hi;
	uint16_t lzs_section, lzs_pos;                  /* lzsplayr.s */
} player_t;

#define PLAYER(p, b) { b, sizeof(b), p##_ENTRY, p##_IOACTIVE, p##_SID_INIT, \
	p##_POKEY_TO_SID, p##_SHADOW, p##_SID_SRC, p##_SID_VOLUME, p##_SID_FLO, \
	p##_SID_FHI, p##_SID_WAVE, p##_ISPEED, p##_LINE_LO, p##_LINE_HI, \
	p##_LZS_SECTION, p##_LZS_POS }

/* [c64][lzss] */
static const player_t players[2][2] = {
	{ PLAYER(ATARI_RMT, atari_rmt_bin), PLAYER(ATARI_LZS, atari_lzs_bin) },
	{ PLAYER(C64_RMT, c64_rmt_bin), PLAYER(C64_LZS, c64_lzs_bin) },
};
static const player_t *pl;

#define RATE    44100
#define GAIN    500             /* 60 (4 channels at volume 15) -> ~30000 */
#define C64_GAIN 1.0            /* sid_cycle() is already scaled */

static uint8_t mem[65536];
static cpu6502_t cpu;
static pokey_t pokey;
static sid_t sid;
static int c64;                 /* 1 = Commodore 64 build, SID output */
static unsigned raster;         /* C64 raster line seen by sidrmt.s */
static int raster_lines = 312;

static long clock_hz = POKEY_CLOCK_PAL;
static int frame_cycles = 312 * 114;
static int frame_rate = 50;
static int io_period;           /* frames between I/O mode toggles, 0 = off */
static int dump_regs;
static int instrspeed = 1;      /* player calls per frame */
static long tick_pos[4];        /* -c64: frame cycle of each call */
static int tick;                /* -c64: next call of the frame */
static uint16_t module_addr;
static int lzss;                /* 1 = .sap / .xex, lzsplayr.s */

static long frame_pos, acc;
static double dc;
static volatile long frames;
static volatile int io_on, failed;
static volatile sig_atomic_t quit;

static void io_write(uint16_t addr, uint8_t val)
{
	if ((addr & 0xFF00) == 0xD200)          /* POKEY, mirrored every 16 bytes */
		pokey_write(&pokey, addr & 0x0F, val);
}

static void c64_io_write(uint16_t addr, uint8_t val)
{
	if ((addr & 0xFC00) == 0xD400)          /* SID, mirrored every 32 bytes */
		sid_write(&sid, addr & 0x1F, val);
}

/* sidrmt.s reads only the VIC-II raster line, to tell PAL from NTSC: every
 * read sees the next line, so its wait loops end */
static uint8_t c64_io_read(uint16_t addr)
{
	if (addr == 0xD012) {
		raster = (raster + 1) % raster_lines;
		return raster & 0xFF;
	}
	if (addr == 0xD011)
		return (raster >> 1) & 0x80;
	return mem[addr];
}

static void set_io(int on)
{
	io_on = on;
	mem[pl->ioactive] = on;
	if (on) {                               /* what rmt_io_begin + SIO do */
		pokey_write(&pokey, 5, 0);      /* AUDC3 */
		pokey_write(&pokey, 7, 0);      /* AUDC4 */
		pokey_write(&pokey, 8, 0x28);   /* AUDCTL: serial baud rate */
	}
}

/* LZSS: the section and the frame in it that the player decodes next */
static const char *lzs_where(void)
{
	static char buf[32];

	if (!lzss)
		return "";
	snprintf(buf, sizeof(buf), "  s%u:%lu", mem[pl->lzs_section],
		 (unsigned long)(mem[pl->lzs_pos] | mem[pl->lzs_pos + 1] << 8 |
				 (unsigned long)mem[pl->lzs_pos + 2] << 16));
	return buf;
}

/* call k of the frame, at its raster line: what the raster IRQ of sidrmt.s
 * does (rmt_play; after the last call of the frame POKEY -> SID) */
static void c64_tick(int k)
{
	if (cpu_call(&cpu, pl->entry + 3, 0, 0, 0))
		failed = 1;
	if (k < instrspeed - 1)
		return;                                 /* the frame goes on */
	if (cpu_call(&cpu, pl->pokey_to_sid, 0, 0, 0))
		failed = 1;
	if (dump_regs) {
		const uint8_t *r = mem + pl->shadow;
		int v;

		printf("%6ld  %02X %02X  %02X %02X  %02X %02X  %02X %02X  %02X ", frames,
		       r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8]);
		for (v = 0; v < 3; v++)
			printf(" |%d<%d %02X%02X %c %2d", v + 1, mem[pl->sid_src + v] + 1,
			       mem[pl->sid_fhi + v], mem[pl->sid_flo + v],
			       mem[pl->sid_wave + v] & 0x80 ? 'N' : mem[pl->sid_wave + v] ? 'P' : '-',
			       mem[pl->sid_volume + v]);
		printf("%s\n", lzs_where());
	}
	frames++;
}

static void do_frame(void)
{
	int i;

	if (io_period && frames > 0 && frames % io_period == 0)
		set_io(!io_on);
	for (i = 0; i < instrspeed; i++)
		if (cpu_call(&cpu, pl->entry + 3, 0, 0, 0))     /* rmt_play */
			failed = 1;
	if (dump_regs)
		printf("%6ld  %02X %02X  %02X %02X  %02X %02X  %02X %02X  %02X%s%s\n", frames,
		       pokey.audf[0], pokey.audc[0], pokey.audf[1], pokey.audc[1],
		       pokey.audf[2], pokey.audc[2], pokey.audf[3], pokey.audc[3],
		       pokey.audctl, io_on ? "  io" : "", lzs_where());
	frames++;
}

static void render(int16_t *buf, int n)
{
	int i;

	for (i = 0; i < n; i++) {
		long k, nc, sum = 0;
		double v;

		acc += clock_hz;
		nc = acc / RATE;
		acc %= RATE;
		for (k = 0; k < nc; k++) {
			if (c64) {
				if (tick < instrspeed && frame_pos == tick_pos[tick] && !failed)
					c64_tick(tick++);
			} else if (frame_pos == 0 && !failed)
				do_frame();
			sum += c64 ? sid_cycle(&sid) : pokey_cycle(&pokey);
			if (++frame_pos == frame_cycles) {
				frame_pos = 0;
				tick = 0;
			}
		}
		v = (double)sum / nc;
		dc += (v - dc) * 0.0005;        /* remove the DC offset of the output */
		v = (v - dc) * (c64 ? C64_GAIN : GAIN);
		if (v > 32767) v = 32767;
		if (v < -32768) v = -32768;
		buf[i] = (int16_t)v;
	}
}

static void audio_cb(void *user, Uint8 *stream, int len)
{
	(void)user;
	render((int16_t *)stream, len / 2);
}

static void on_signal(int sig)
{
	(void)sig;
	quit = 1;
}

/* the whole file, at most 1 MB */
static uint8_t *read_file(const char *name, long *len)
{
	FILE *f = fopen(name, "rb");
	uint8_t *buf;

	if (!f) {
		perror(name);
		return NULL;
	}
	buf = malloc(1 << 20);
	*len = buf ? (long)fread(buf, 1, 1 << 20, f) : 0;
	fclose(f);
	if (buf && *len == 1 << 20) {
		fprintf(stderr, "%s: file too long\n", name);
		free(buf);
		return NULL;
	}
	return buf;
}

/* an .rmt: one Atari binary block with the RMT4 module */
static int load_rmt(const char *name, const uint8_t *raw, long rawlen)
{
	unsigned start, end, len;

	if (rawlen < 6 || raw[0] != 0xFF || raw[1] != 0xFF) {
		fprintf(stderr, "%s: not an Atari binary file ($FFFF header)\n", name);
		return -1;
	}
	start = raw[2] | (raw[3] << 8);
	end = raw[4] | (raw[5] << 8);
	if (end < start) {
		fprintf(stderr, "%s: bad block $%04X-$%04X\n", name, start, end);
		return -1;
	}
	len = end - start + 1;
	if (start < 0x0300 || end >= PLAYER_BASE) {
		fprintf(stderr, "%s: module at $%04X-$%04X overlaps the player ($%04X-$%04X)\n",
			name, start, end, PLAYER_BASE, PLAYER_BASE + pl->size - 1);
		return -1;
	}
	if (rawlen < 6 + (long)len) {
		fprintf(stderr, "%s: truncated module\n", name);
		return -1;
	}
	memcpy(mem + start, raw + 6, len);
	if (memcmp(mem + start, "RMT4", 4)) {
		fprintf(stderr, "%s: not an RMT4 (mono) module\n", name);
		return -1;
	}
	module_addr = start;
	printf("%s: $%04X-$%04X (%u bytes), track length %u, speed %u, instr speed %u\n",
	       name, start, end, len, mem[start + 4], mem[start + 5], mem[start + 6]);
	return 0;
}

/* VU-Player v2 memory of a SAP / XEX exported by RITMO (src/lzssp.h there) */
#define VU_SONGINDEX  0x1F40    /* per subtune: section list, sequence */
#define VU_SPEED      0x183D    /* instrument speed */
#define VU_STEREO     0x0E0C    /* $FF = stereo */
#define VU_SONGTOTAL  0x1B0D    /* subtunes of a XEX */

/* .sap / .xex: subtune sub as the module of lzsplayr.s, at LZS_MODULE
 * (the layout of tools/sap2ca65.py: speed, tracks, sections, loop, the
 * section addresses and the end, then the LZ16 streams) */
static int load_lzs(const char *name, const uint8_t *raw, long rawlen, int sub)
{
	static uint8_t img[65536], loaded[65536];
	long i = 0;
	int songs = 0, n, loop, k;
	unsigned sec, seq, addr[101], dst, size;

	if (rawlen >= 5 && !memcmp(raw, "SAP\r\n", 5)) {      /* header lines, then binary */
		const uint8_t *e = NULL;
		long j;

		for (j = 5; j + 4 <= rawlen; j++)
			if (!memcmp(raw + j, "\r\n\r\n", 4)) {
				e = raw + j;
				break;
			}
		if (!e) {
			fprintf(stderr, "%s: SAP header without end\n", name);
			return -1;
		}
		for (j = 5; j < e - raw; ) {
			const uint8_t *l = raw + j;
			long ll = 0;

			while (j + ll < e - raw && l[ll] != '\r')
				ll++;
			if (ll >= 5 && !memcmp(l, "TYPE ", 5) && (ll != 6 || l[5] != 'B')) {
				fprintf(stderr, "%s: SAP of type %.*s, not B\n", name, (int)(ll - 5), l + 5);
				return -1;
			}
			if (ll > 6 && !memcmp(l, "SONGS ", 6))
				songs = atoi((const char *)l + 6);
			j += ll + 2;
		}
		i = e + 4 - raw;
	} else if (rawlen < 2 || raw[0] != 0xFF || raw[1] != 0xFF) {
		fprintf(stderr, "%s: neither a SAP nor an Atari binary file\n", name);
		return -1;
	}
	while (i + 4 <= rawlen) {                               /* binary blocks */
		unsigned start, end;

		if (raw[i] == 0xFF && raw[i + 1] == 0xFF) {
			i += 2;
			continue;
		}
		start = raw[i] | raw[i + 1] << 8;
		end = raw[i + 2] | raw[i + 3] << 8;
		i += 4;
		if (end < start || i + (long)(end - start + 1) > rawlen) {
			fprintf(stderr, "%s: bad binary block $%04X-$%04X\n", name, start, end);
			return -1;
		}
		memcpy(img + start, raw + i, end - start + 1);
		memset(loaded + start, 1, end - start + 1);
		i += end - start + 1;
	}
	if (!loaded[VU_SONGINDEX]) {
		fprintf(stderr, "%s: no VU-Player song index at $%04X: not a RITMO SAP/XEX export\n",
			name, VU_SONGINDEX);
		return -1;
	}
	if (!songs)
		songs = img[VU_SONGTOTAL] ? img[VU_SONGTOTAL] : 1;
	if (sub < 0 || sub >= songs) {
		fprintf(stderr, "%s: subtune %d, the file has %d\n", name, sub, songs);
		return -1;
	}
	if (img[VU_STEREO]) {
		fprintf(stderr, "%s: stereo song: the Atari and C64 players are mono\n", name);
		return -1;
	}
	sec = img[VU_SONGINDEX + 4 * sub] | img[VU_SONGINDEX + 4 * sub + 1] << 8;
	seq = img[VU_SONGINDEX + 4 * sub + 2] | img[VU_SONGINDEX + 4 * sub + 3] << 8;
	for (n = 0; !(img[(seq + n) & 0xFFFF] & 0x80); n++)
		if (img[(seq + n) & 0xFFFF] != n || n >= 100) {
			fprintf(stderr, "%s: subtune %d: sections not 0, 1 .. in order\n", name, sub);
			return -1;
		}
	loop = img[(seq + n) & 0xFFFF] & 0x7F;
	if (n == 0 || loop >= n) {
		fprintf(stderr, "%s: subtune %d: %d sections, loop to %d\n", name, sub, n, loop);
		return -1;
	}
	for (k = 0; k <= n; k++)
		addr[k] = img[(sec + 2 * k) & 0xFFFF] | img[(sec + 2 * k + 1) & 0xFFFF] << 8;
	size = 4 + 2 * (n + 1);
	for (k = 0; k < n; k++) {
		unsigned a;

		if (addr[k + 1] <= addr[k]) {
			fprintf(stderr, "%s: section $%04X-$%04X\n", name, addr[k], addr[k + 1]);
			return -1;
		}
		for (a = addr[k]; a < addr[k + 1]; a++)
			if (!loaded[a]) {
				fprintf(stderr, "%s: section $%04X-$%04X is not in the file\n",
					name, addr[k], addr[k + 1]);
				return -1;
			}
		size += addr[k + 1] - addr[k];
	}
	if (LZS_MODULE + size > PLAYER_BASE) {
		fprintf(stderr, "%s: %u bytes of streams, more than $%04X-$%04X\n",
			name, size, LZS_MODULE, PLAYER_BASE - 1);
		return -1;
	}
	mem[LZS_MODULE] = img[VU_SPEED] ? img[VU_SPEED] : 1;
	mem[LZS_MODULE + 1] = 4;
	mem[LZS_MODULE + 2] = n;
	mem[LZS_MODULE + 3] = loop;
	dst = LZS_MODULE + 4 + 2 * (n + 1);
	for (k = 0; k <= n; k++) {                      /* sections, relocated */
		mem[LZS_MODULE + 4 + 2 * k] = dst & 0xFF;
		mem[LZS_MODULE + 5 + 2 * k] = dst >> 8;
		if (k < n) {
			memcpy(mem + dst, img + addr[k], addr[k + 1] - addr[k]);
			dst += addr[k + 1] - addr[k];
		}
	}
	module_addr = LZS_MODULE;
	printf("%s: subtune %d of %d, %d section%s (loop to %d), %u bytes, instr speed %u\n",
	       name, sub, songs, n, n > 1 ? "s" : "", loop, size, mem[LZS_MODULE]);
	return 0;
}

/* .sap / .xex (by the contents): LZSS streams; otherwise an .rmt */
static int load_song(const char *name, int sub)
{
	long len;
	uint8_t *raw = read_file(name, &len);
	int r;

	if (!raw)
		return -1;
	lzss = (len >= 5 && !memcmp(raw, "SAP\r\n", 5)) ||
	       (len >= 10 && raw[0] == 0xFF && raw[1] == 0xFF && memcmp(raw + 6, "RMT", 3));
	pl = &players[c64][lzss];
	memcpy(mem + PLAYER_BASE, pl->bin, pl->size);
	r = lzss ? load_lzs(name, raw, len, sub) : load_rmt(name, raw, len);
	free(raw);
	return r;
}

static void put32(FILE *f, uint32_t v) { fputc(v, f); fputc(v >> 8, f); fputc(v >> 16, f); fputc(v >> 24, f); }
static void put16(FILE *f, uint16_t v) { fputc(v, f); fputc(v >> 8, f); }

static int write_wav(const char *name, double seconds)
{
	long total = (long)(seconds * RATE), done = 0;
	int16_t buf[4096];
	FILE *f = fopen(name, "wb");

	if (!f) {
		perror(name);
		return -1;
	}
	fwrite("RIFF", 1, 4, f); put32(f, 36 + total * 2);
	fwrite("WAVEfmt ", 1, 8, f); put32(f, 16); put16(f, 1); put16(f, 1);
	put32(f, RATE); put32(f, RATE * 2); put16(f, 2); put16(f, 16);
	fwrite("data", 1, 4, f); put32(f, total * 2);
	while (done < total && !failed && !quit) {
		int n = total - done > 4096 ? 4096 : (int)(total - done);
		render(buf, n);
		fwrite(buf, 2, n, f);
		done += n;
	}
	fclose(f);
	printf("%s: %.1f s, %ld frames\n", name, (double)done / RATE, frames);
	return failed ? -1 : 0;
}

static int play_sdl(double seconds)
{
	SDL_AudioSpec want, have;
	SDL_AudioDeviceID dev;
	long last = -1;

	SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, "1");
	if (SDL_Init(SDL_INIT_AUDIO)) {
		fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
		return -1;
	}
	SDL_zero(want);
	want.freq = RATE;
	want.format = AUDIO_S16SYS;
	want.channels = 1;
	want.samples = 1024;
	want.callback = audio_cb;
	dev = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
	if (!dev) {
		fprintf(stderr, "SDL_OpenAudioDevice: %s\n", SDL_GetError());
		SDL_Quit();
		return -1;
	}
	printf("Playing (%s%s), Ctrl+C to stop\n", c64 ? "C64 SID, " : "",
	       frame_rate == 50 ? "PAL" : "NTSC");
	SDL_PauseAudioDevice(dev, 0);
	while (!quit && !failed) {
		long f = frames, sec = f / frame_rate;

		if (seconds > 0 && f >= seconds * frame_rate)
			break;
		if (sec != last && !dump_regs) {
			printf("\r  %02ld:%02ld  %s", sec / 60, sec % 60,
			       c64 ? "SID" : io_on ? "I/O: CH1+2 only " : "CH1-4           ");
			fflush(stdout);
			last = sec;
		}
		SDL_Delay(50);
	}
	SDL_CloseAudioDevice(dev);
	SDL_Quit();
	printf("\n");
	return failed ? -1 : 0;
}

static void usage(void)
{
	fprintf(stderr, "usage: rmtplay [-t sec] [-w out.wav] [-n] [-c64] [-s subtune] [-io sec] [-r] "
		"file.rmt|.sap|.xex\n");
	exit(2);
}

int main(int argc, char **argv)
{
	const char *wav = NULL, *file = NULL;
	double seconds = 0, io_sec = 0;
	int i, sub = 0;

	for (i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-t") && i + 1 < argc)
			seconds = atof(argv[++i]);
		else if (!strcmp(argv[i], "-w") && i + 1 < argc)
			wav = argv[++i];
		else if (!strcmp(argv[i], "-n"))
			frame_rate = 60;
		else if (!strcmp(argv[i], "-io") && i + 1 < argc)
			io_sec = atof(argv[++i]);
		else if (!strcmp(argv[i], "-r"))
			dump_regs = 1;
		else if (!strcmp(argv[i], "-c64"))
			c64 = 1;
		else if (!strcmp(argv[i], "-s") && i + 1 < argc)
			sub = atoi(argv[++i]);
		else if (argv[i][0] == '-' || file)
			usage();
		else
			file = argv[i];
	}
	if (!file)
		usage();
	if (c64 && io_sec > 0) {
		fprintf(stderr, "rmtplay: -io is the Atari disk loading, there is none on the C64\n");
		return 2;
	}
	if (c64) {                      /* C64 frames: 312 lines x 63 cycles, 263 x 65 */
		clock_hz = frame_rate == 60 ? SID_CLOCK_NTSC : SID_CLOCK_PAL;
		raster_lines = frame_rate == 60 ? 263 : 312;
		frame_cycles = frame_rate == 60 ? 263 * 65 : 312 * 63;
	} else if (frame_rate == 60) {
		clock_hz = POKEY_CLOCK_NTSC;
		frame_cycles = 262 * 114;
	}
	io_period = (int)(io_sec * frame_rate);

	if (load_song(file, sub))
		return 1;

	pokey_init(&pokey);
	sid_init(&sid);
	cpu.mem = mem;
	if (c64) {
		cpu.write_hook = c64_io_write;
		cpu.read_hook = c64_io_read;
		/* sid_init (fastcall): A/X = module; PAL / NTSC from the raster,
		 * SID cleared, rmt_init from song line 0, then the raster lines
		 * of the instrument speed calls */
		if (cpu_call(&cpu, pl->sid_init, module_addr & 0xFF, module_addr >> 8, 0))
			return 1;
		instrspeed = mem[pl->ispeed];
		for (i = 0; i < instrspeed; i++)
			tick_pos[i] = (mem[pl->line_lo + i] | (mem[pl->line_hi + i] ? 0x100 : 0)) *
				      (frame_rate == 60 ? 65 : 63);
	} else {
		cpu.write_hook = io_write;
		/* rmt_init: X/Y = module, A = starting song line; returns instr speed */
		if (cpu_call(&cpu, pl->entry, 0, module_addr & 0xFF, module_addr >> 8))
			return 1;
		instrspeed = cpu.a < 1 ? 1 : cpu.a > 4 ? 4 : cpu.a;    /* as rmtvbi.s */
	}

	signal(SIGINT, on_signal);
	if (wav)
		return write_wav(wav, seconds > 0 ? seconds : 60) ? 1 : 0;
	return play_sdl(seconds) ? 1 : 0;
}
