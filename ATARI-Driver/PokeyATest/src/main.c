//
// POKEYATEST - RMT music on VBI while loading assets from disk via SIO
// RetroBitLab
//
// The RMT player runs on the immediate VBI. Every disk transfer is
// bracketed by rmt_io_begin()/rmt_io_end(): meanwhile POKEY channels 3+4 and
// AUDCTL are the SIO baud rate generator, so the music continues on
// channels 1+2 only. SOUNDR=0 silences the OS "beep" of the serial data.
//
// Two loaders (key L): the own IRQ driven SIO driver (default) and the OS
// SIOV, which can lose the first data byte of a sector when the VBI player
// runs right after the drive "Complete" byte (see sio.s).
//
// Keys: L = toggle loader   S = toggle OS SIO noise (SOUNDR)   ESC = quit
//

#include <stdio.h>
#include <string.h>
#include <conio.h>
#include <atari.h>
#include <peekpoke.h>
#include "rmt.h"
#include "dos2fs.h"
#include "assets.h"

extern unsigned char secbuf[];

#ifndef SONGNAME
#define SONGNAME "?"
#endif

#define SOUNDR      0x41
#define ATRACT      0x4D
#define PAL_REG     0xD014

#define ROW_MODE    5
#define ROW_VU      6
#define ROW_PLAYER  7
#define ROW_PASS    9
#define ROW_FIRST   11
#define ROW_MSG     (ROW_FIRST + ASSET_COUNT + 1)
#define VU_ON       0xA0    // inverse space

static unsigned char buffer[ASSET_MAXSIZE];
static unsigned char fps;
static unsigned int  pass, ok_count, err_count;
static unsigned char cur_row;

// OS RTCLOK low 16 bits ($13 hi, $14 lo), incremented by VBI stage 1
static unsigned int frames_now(void)
{
	unsigned char lo, hi;

	do {
		lo = PEEK(0x14);
		hi = PEEK(0x13);
	} while (lo != PEEK(0x14));
	return (hi << 8) | lo;
}

static unsigned int checksum(const unsigned char *p, unsigned int n)
{
	unsigned char s1 = 0, s2 = 0;

	while (n--) {
		s1 += *p++;
		s2 += s1;
	}
	return (s2 << 8) | s1;
}

static void show_soundr(void)
{
	gotoxy(0, 2);
	cprintf("Loader: %s  [L]", fs_loader == FS_LOADER_OS ? "OS SIOV     " : "RBL IRQ SIO ");
	gotoxy(0, 3);
	cprintf("OS SIO noise: %s  [S]  [ESC]quit",
	        PEEK(SOUNDR) ? "ON " : "OFF");
}

static void show_mode(unsigned char io)
{
	gotoxy(0, ROW_MODE);
	if (io)
		cputs("Music: CH1+2 only (SIO owns CH3+4)");
	else
		cputs("Music: CH1..4 full                 ");
}

static void show_vu(void)
{
	unsigned char ch, v, i;

	gotoxy(0, ROW_VU);
	for (ch = 0; ch < 4; ch++) {
		v = rmt_audc[ch] & 0x0F;
		cputc('1' + ch);
		cputc(':');
		for (i = 0; i < 6; i++)
			cputc(i < ((v + 2) >> 1) ? VU_ON : '.');
		cputc(' ');
	}
	gotoxy(0, ROW_PLAYER);
	cprintf("Player:%3u ln (max%3u) late%5u lost%u", rmt_lines, rmt_maxlines, rmt_deferred, rmt_dropped);
}

static void progress(unsigned int bytes)
{
	gotoxy(18, cur_row);
	cprintf("%5u", bytes);
	show_vu();
}

static void wait_frames(unsigned int n)
{
	unsigned int t0 = frames_now();

	while ((unsigned int)(frames_now() - t0) < n)
		show_vu();
}

static unsigned char handle_keys(void)
{
	char c;

	if (!kbhit())
		return 0;
	c = cgetc();
	if (c == CH_ESC)
		return 1;
	if (c == 's' || c == 'S') {
		POKE(SOUNDR, PEEK(SOUNDR) ? 0 : 3);
		show_soundr();
	}
	if (c == 'l' || c == 'L') {
		fs_loader ^= 1;
		show_soundr();
	}
	return 0;
}

static void load_asset(unsigned char n)
{
	const asset_t *a = &assets[n];
	fs_entry_t e;
	fs_result_t r;
	unsigned char st;
	unsigned int t0, frames, sum;
	unsigned long bps;

	cur_row = ROW_FIRST + n;
	gotoxy(0, cur_row);
	cprintf("%.8s.%.3s ", a->name83, a->name83 + 8);
	cclear(40 - 13);
	gotoxy(13, cur_row);
	cputs("LOAD ");

	memset(buffer, 0, sizeof(buffer));

	rmt_io_begin();
	show_mode(1);
	t0 = frames_now();
	st = fs_find(a->name83, &e);
	if (st == FS_OK)
		st = fs_load(&e, buffer, sizeof(buffer), &r);
	frames = frames_now() - t0;
	rmt_io_end();
	show_mode(0);

	gotoxy(13, cur_row);
	if (st != FS_OK) {
		++err_count;
		switch (st) {
		case FS_NOTFOUND: cputs("NOT FOUND");                  break;
		case FS_SIOERR:   cprintf("SIO ERR %3u @%u", r.sio_status, r.bad_sector); break;
		case FS_TOOBIG:   cputs("TOO BIG");                    break;
		default:
			cprintf("BADLNK@%u %02X%02X%02X %02X%02X", r.bad_sector,
			        secbuf[125], secbuf[126], secbuf[127], secbuf[0], secbuf[1]);
			break;
		}
		return;
	}

	sum = checksum(buffer, r.bytes);
	if (r.bytes != a->size || sum != a->sum) {
		++err_count;
		cprintf("%5u %04X!=%04X", r.bytes, sum, a->sum);
		return;
	}
	++ok_count;
	bps = frames ? ((unsigned long)r.bytes * fps) / frames : 0;
	cprintf("OK   %5u %4ufr %4lub/s", r.bytes, frames, bps);
}

int main(void)
{
	unsigned char n, speed, oldsoundr;

	fps = (PEEK(PAL_REG) & 0x0E) ? 60 : 50;
	oldsoundr = PEEK(SOUNDR);
	POKE(SOUNDR, 0);                // silence the SIO noise while loading

	clrscr();
	cputs("POKEYATEST  RMT on VBI + SIO loader\r\n");
	cprintf("Song: %s  %s  %u assets\r\n", SONGNAME, fps == 50 ? "PAL" : "NTSC", ASSET_COUNT);
	show_soundr();

	speed = rmt_init(rmt_song);
	if (speed != 1) {
		gotoxy(0, ROW_MSG);
		cprintf("Warn: instr speed %u, VBI plays 1x", speed);
	}
#ifndef TEST_NOMUSIC
	rmt_vbi_on();
#endif
	show_mode(0);

	wait_frames(fps * 2);           // some music alone before loading

	for (;;) {
		++pass;
		gotoxy(0, ROW_PASS);
		cprintf("Pass %u  OK %u  ERR %u  RETRY %u   ", pass, ok_count, err_count, fs_retries);

		for (n = 0; n < ASSET_COUNT; n++) {
			fs_progress = progress;
			load_asset(n);
#ifdef STOP_ON_ERROR
			if (err_count)
				for (;;)
					show_vu();
#endif
			gotoxy(0, ROW_PASS);
			cprintf("Pass %u  OK %u  ERR %u  RETRY %u   ", pass, ok_count, err_count, fs_retries);
			POKE(ATRACT, 0);        // no attract color cycling
			wait_frames(fps);       // one second of full 4 channel music
			if (handle_keys())
				goto quit;
		}
	}

quit:
	rmt_vbi_off();
	POKE(SOUNDR, oldsoundr);
	gotoxy(0, ROW_MSG + 1);
	cputs("Bye.\r\n");
	return 0;
}
