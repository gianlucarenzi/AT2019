//
// RMT CBM64 - Commodore 64 RMT Player
//
// Minimal example showing how to play an RMT module on C64 via SID.
// Equivalent to RmtSkeleton for ATARI, but targeting Commodore 64.
//

#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <time.h>
#include "sid.h"

int main(void)
{
    unsigned int old_frames;

    clrscr();
    cprintf("RMT Music Player - Commodore 64\r\n");
    cprintf("================================\r\n\r\n");

    // Initialize the player with the song module
    sid_init(rmt_song_data);
    cprintf("Song loaded from RMT module\r\n");

    // Start playback on CIA1 Timer A
    sid_play_on();
    cprintf("Music started (CIA1 IRQ active)\r\n\r\n");

    // Display info
    cprintf("Press any key to stop playback\r\n");
    cprintf("Playing 3-channel SID audio...\r\n\r\n");

    old_frames = 0;

    // Main loop: display frame counter and channel info
    for (;;) {
        // Show frame counter (basic timing info)
        gotoxy(0, 8);
        cprintf("Frames: %5u  ", sid_frames);
        
        // Show channel volumes (VU meter)
        cprintf("CH1:%X CH2:%X CH3:%X",
                sid_volume[0] & 0x0F,
                sid_volume[1] & 0x0F,
                sid_volume[2] & 0x0F);

        // Check for keypress
        if (kbhit()) {
            cgetc();
            break;
        }
    }

    // Stop the player and silence SID
    sid_play_off();
    clrscr();
    cprintf("Music stopped.\r\n");
    cprintf("Playback duration: %u frames\r\n", sid_frames);

    return 0;
}
