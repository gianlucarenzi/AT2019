/*
 * rmtplay - RMT module player for the PC (SDL2)
 *
 * Plays a .rmt module with the real Atari player routine: src/rmtplayr.s
 * (RMT 1.20090108, the same code linked in the Atari program) is assembled
 * by ca65 and runs here on a 6502 emulator, once per frame like on the
 * immediate VBI; its POKEY writes drive a POKEY emulation.
 *
 * Usage: rmtplay [options] file.rmt
 *   -t sec     stop after sec seconds (default: until Ctrl+C; WAV: 60)
 *   -w file    render to a WAV file instead of playing
 *   -n         NTSC (60 Hz frames) instead of PAL (50 Hz)
 *   -io sec    simulate disk loading: every sec seconds toggle the player
 *              I/O mode (rmt_io_begin/rmt_io_end), only channels 1+2 play
 *   -r         dump POKEY registers written by the player, one line per frame
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <SDL.h>

#include "cpu6502.h"
#include "pokey.h"
#include "rmtplayr_bin.h"       /* generated: player binary and addresses */

#define RATE    44100
#define GAIN    500             /* 60 (4 channels at volume 15) -> ~30000 */

static uint8_t mem[65536];
static cpu6502_t cpu;
static pokey_t pokey;

static long clock_hz = POKEY_CLOCK_PAL;
static int frame_cycles = 312 * 114;
static int frame_rate = 50;
static int io_period;           /* frames between I/O mode toggles, 0 = off */
static int dump_regs;
static uint16_t module_addr;

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

static void set_io(int on)
{
	io_on = on;
	mem[RMT_IOACTIVE] = on;
	if (on) {                               /* what rmt_io_begin + SIO do */
		pokey_write(&pokey, 5, 0);      /* AUDC3 */
		pokey_write(&pokey, 7, 0);      /* AUDC4 */
		pokey_write(&pokey, 8, 0x28);   /* AUDCTL: serial baud rate */
	}
}

static void do_frame(void)
{
	if (io_period && frames > 0 && frames % io_period == 0)
		set_io(!io_on);
	if (cpu_call(&cpu, RMT_ENTRY + 3, 0, 0, 0))     /* rmt_play */
		failed = 1;
	if (dump_regs)
		printf("%6ld  %02X %02X  %02X %02X  %02X %02X  %02X %02X  %02X%s\n", frames,
		       pokey.audf[0], pokey.audc[0], pokey.audf[1], pokey.audc[1],
		       pokey.audf[2], pokey.audc[2], pokey.audf[3], pokey.audc[3],
		       pokey.audctl, io_on ? "  io" : "");
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
			if (frame_pos == 0 && !failed)
				do_frame();
			sum += pokey_cycle(&pokey);
			if (++frame_pos == frame_cycles)
				frame_pos = 0;
		}
		v = (double)sum / nc;
		dc += (v - dc) * 0.0005;        /* remove the DC offset of POKEY output */
		v = (v - dc) * GAIN;
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

static int load_rmt(const char *name)
{
	FILE *f = fopen(name, "rb");
	uint8_t h[6];
	unsigned start, end, len;

	if (!f) {
		perror(name);
		return -1;
	}
	if (fread(h, 1, 6, f) != 6 || h[0] != 0xFF || h[1] != 0xFF) {
		fprintf(stderr, "%s: not an Atari binary file ($FFFF header)\n", name);
		fclose(f);
		return -1;
	}
	start = h[2] | (h[3] << 8);
	end = h[4] | (h[5] << 8);
	if (end < start) {
		fprintf(stderr, "%s: bad block $%04X-$%04X\n", name, start, end);
		fclose(f);
		return -1;
	}
	len = end - start + 1;
	if (start < 0x0300 || (start < RMT_END && end >= RMT_BASE) || end >= 0xD000) {
		fprintf(stderr, "%s: module at $%04X-$%04X overlaps the player ($%04X-$%04X) or I/O\n",
			name, start, end, RMT_BASE, (unsigned)(RMT_END - 1));
		fclose(f);
		return -1;
	}
	if (fread(mem + start, 1, len, f) != len) {
		fprintf(stderr, "%s: truncated module\n", name);
		fclose(f);
		return -1;
	}
	fclose(f);
	if (memcmp(mem + start, "RMT4", 4)) {
		fprintf(stderr, "%s: not an RMT4 (mono) module\n", name);
		return -1;
	}
	module_addr = start;
	printf("%s: $%04X-$%04X (%u bytes), track length %u, speed %u, instr speed %u\n",
	       name, start, end, len, mem[start + 4], mem[start + 5], mem[start + 6]);
	return 0;
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
	printf("Playing (%s), Ctrl+C to stop\n", frame_rate == 50 ? "PAL" : "NTSC");
	SDL_PauseAudioDevice(dev, 0);
	while (!quit && !failed) {
		long f = frames, sec = f / frame_rate;

		if (seconds > 0 && f >= seconds * frame_rate)
			break;
		if (sec != last && !dump_regs) {
			printf("\r  %02ld:%02ld  %s", sec / 60, sec % 60,
			       io_on ? "I/O: CH1+2 only " : "CH1-4           ");
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
	fprintf(stderr, "usage: rmtplay [-t sec] [-w out.wav] [-n] [-io sec] [-r] file.rmt\n");
	exit(2);
}

int main(int argc, char **argv)
{
	const char *wav = NULL, *file = NULL;
	double seconds = 0, io_sec = 0;
	int i, instrspeed;

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
		else if (argv[i][0] == '-' || file)
			usage();
		else
			file = argv[i];
	}
	if (!file)
		usage();
	if (frame_rate == 60) {
		clock_hz = POKEY_CLOCK_NTSC;
		frame_cycles = 262 * 114;
	}
	io_period = (int)(io_sec * frame_rate);

	memcpy(mem + RMT_BASE, rmtplayr_bin, sizeof(rmtplayr_bin));
	if (load_rmt(file))
		return 1;

	pokey_init(&pokey);
	cpu.mem = mem;
	cpu.write_hook = io_write;
	/* rmt_init: X/Y = module, A = starting song line; returns instr speed */
	if (cpu_call(&cpu, RMT_ENTRY, 0, module_addr & 0xFF, module_addr >> 8))
		return 1;
	instrspeed = cpu.a;
	if (instrspeed != 1)
		fprintf(stderr, "warning: instrument speed %d: the VBI player calls it once per frame, "
			"so it plays %dx slower (as on the Atari)\n", instrspeed, instrspeed);

	signal(SIGINT, on_signal);
	if (wav)
		return write_wav(wav, seconds > 0 ? seconds : 60) ? 1 : 0;
	return play_sdl(seconds) ? 1 : 0;
}
