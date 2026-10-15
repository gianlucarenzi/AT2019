/*
 * RMT CBM64 - an RMT module played on the Commodore 64 SID
 *
 * Minimal example: init, start, show the voice levels, stop on a key.
 */

#include <conio.h>
#include "sid.h"

int main(void)
{
	unsigned char i;

	clrscr();
	cputs("RMT player - Commodore 64 SID\r\n");
	cputs("=============================\r\n\r\n");

	sid_init(rmt_song_data);
	cprintf("%s machine, %u Hz frames\r\n", sid_ntsc ? "NTSC" : "PAL", sid_ntsc ? 60 : 50);
	if (sid_voices == 6)
		cprintf("Dual SID: right POKEY on $%04X\r\n", sid_sid2);
	else if (sid_sid2)
		cprintf("No SID at $%04X: right POKEY silent\r\n", sid_sid2);
	sid_play_on();
	cputs("Playing, press any key to stop\r\n\r\n");

	while (!kbhit()) {
		gotoxy(0, 7);
		cprintf("Frames: %5u   ", sid_frames);
		for (i = 0; i < sid_voices; i++) {
			if (i == 3)
				cputs("\r\n                ");
			cprintf("V%u:%2u ", i + 1, sid_volume[i]);
		}
	}
	cgetc();

	sid_play_off();
	cputs("\r\n\r\nStopped.\r\n");
	return 0;
}
