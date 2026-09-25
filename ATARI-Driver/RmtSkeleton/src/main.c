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

int main(void)
{
	unsigned char speed, i, vol;

	clrscr();
	cputs("RMT Music Player\r\n");
	cputs("================\r\n\r\n");

	// Initialize the player with the song module
	speed = rmt_init(rmt_song);
	cprintf("Song loaded, instrument speed: %u\r\n", speed);

	// Attach the player to the immediate VBI
	rmt_vbi_on();
	cputs("Music started (VBI attached)\r\n\r\n");

	// Show player diagnostics
	cputs("Press ESC to stop\r\n");
	cputs("\r\n");
	cputs("Player timing (scanlines):\r\n");

	// Main loop: just display diagnostics while music plays
	for (;;) {
		gotoxy(0, 8);
		cprintf("Frames: %5u  ", rmt_frames);
		cprintf("Last:  %3u  ", rmt_lines);
		cprintf("Max: %3u\r\n", rmt_maxlines);
		cprintf("Deferred: %5u  ", rmt_deferred);
		cprintf("Dropped: %5u", rmt_dropped);

		// Show channel volumes (VU meter)
		gotoxy(0, 11);
		cputs("Channels: ");
		for (i = 0; i < 4; i++) {
			vol = rmt_audc[i] & 0x0F;
			cprintf("%u:%X  ", i + 1, vol);
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
