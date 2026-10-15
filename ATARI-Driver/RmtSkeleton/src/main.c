//
// RmtSkeleton - Minimal RMT player example
//
// Shows the bare minimum to play an RMT song on the immediate VBI.
// Copy this project as a template to use RMT music in your cc65 programs.
//

#include <stdio.h>
#include <conio.h>
#include <atari.h>
#include "rmt.h"

// 8 channels: a shorter VU line, it must fit in 40 columns
#if RMT_TRACKS > 4
#define CH_TITLE "Ch: "
#define CH_FORMAT "%u:%X "
#else
#define CH_TITLE "Channels: "
#define CH_FORMAT "%u:%X  "
#endif

int main(void)
{
	static const char * const output[] = {
		"POKEY",
		"POKEY + VERA PSG",
		"POKEY + 2nd POKEY",
		"POKEY 1-4 only",
		"2 POKEYs"
	};
	unsigned char speed, i, vol;

	clrscr();
	cputs("RMT Music Player\r\n");
	cputs("================\r\n\r\n");

	// Initialize the player with the song module
	speed = rmt_init(rmt_song);
	cprintf("Song loaded, instrument speed: %u\r\n", speed);
	cprintf("%u tracks: %s%s\r\n", RMT_TRACKS, output[rmt_output],
	        rmt_mirror ? ", VERA mirror" : "");

	// Attach the player to the immediate VBI
	rmt_vbi_on();
	cputs("Music started (VBI attached)\r\n\r\n");

	// Show player diagnostics
	cputs("Press ESC to stop\r\n");
	cputs("\r\n");
	cputs("Player timing (scanlines):\r\n");

	// Main loop: just display diagnostics while music plays
	for (;;) {
		gotoxy(0, 9);
		cprintf("Frames:%5u Last:%3u ", rmt_frames, rmt_lines);
		cprintf("Avg:%3u Max:%3u\r\n", rmt_avglines, rmt_maxlines);
		cprintf("Deferred: %5u  ", rmt_deferred);
		cprintf("Dropped: %5u", rmt_dropped);

		// Show channel volumes (VU meter)
		gotoxy(0, 12);
		cputs(CH_TITLE);
		for (i = 0; i < RMT_TRACKS; i++) {
			vol = rmt_audc[i] & 0x0F;
			cprintf(CH_FORMAT, i + 1, vol);
		}

		// Check for ESC key
		if (kbhit() && cgetc() == 27)  // 27 = ESC
			break;
	}

	// Stop the player and silence POKEY
	rmt_vbi_off();
	clrscr();
	cputs("Music stopped.\r\n");

	return 0;
}
