/*
 * rmtplay.c - RMT player for the Commodore 64 with a visualizer, in the style
 * of RMTPLAY.COM of VERA_ATARI_PBI (vera-tests/rmt/rmtplay.c) and of the
 * XEX/SAP export of Raster Music Tracker.
 *
 *   NAME / AUTHOR / DATE of the song (tools/rmtinfo.py: text stored in the
 *   .rmt file, or NAME= AUTHOR= DATE= on the make line); a line longer than
 *   40 characters scrolls left, one character at a time, after 5 seconds
 *   one volume bar per SID voice (1, 2, 3), centred, red at the top, green
 *   at the bottom
 *   AUDF / AUDC of every channel and AUDCTL; SID frequency, waveform and
 *   POKEY channel of every voice, in hex
 *   song line, row in the track, speed, play time
 *
 *   SPACE  pause / play       R  restart the song
 *   1 2 3  SID voice on/off   RUN/STOP or <-  stop and exit
 *
 * Text screen at $0400 in the upper/lower case character set; the bars use
 * the block characters of the ROM font (1/8 to 8/8 of a cell).
 * Sound: the same player as build/rmt_cbm64.prg (rmtplayr.s + sidrmt.s).
 */

#include <c64.h>
#include <cbm.h>
#include <conio.h>
#include <string.h>
#include "sid.h"
#include "songinfo.h"

/* cc65 is much faster with static locals; nothing here is recursive */
#pragma static-locals (on)

#define SCREEN      ((unsigned char *)0x0400)
#define SHFLAG_LOCK (*(unsigned char *)0x0291)  /* $80: SHIFT+C= does not switch case */

/* ---- screen layout ---------------------------------------------------- */

#define ROW_TITLE   0
#define ROW_NAME    2       /* NAME, AUTHOR, DATE on 2, 3, 4 */
#define ROW_GROUPS  6
#define BAR_TOP     7       /* 8 rows of bars: 64 pixels, 4 per volume step */
#define BAR_ROWS    8
#define ROW_LABELS  (BAR_TOP + BAR_ROWS)
#define ROW_AUDF    17
#define ROW_AUDC    18
#define ROW_FREQ    19
#define ROW_WAVE    20
#define ROW_POS     22
#define ROW_STATE   23
#define ROW_KEYS    24

#define BARS        3       /* SID voices 1-3 */
#define BAR_W       6       /* 6 wide, 4 apart: columns 7-12, 17-22, 27-32 */
static const unsigned char bar_x[BARS] = { 7, 17, 27 };

/* block characters of the ROM font: the bottom 1..8 pixel rows of a cell */
static const unsigned char block[9] = {
    0x20, 0x64, 0x6F, 0x79, 0x62, 0xF8, 0xF7, 0xE3, 0xA0
};

/* colour of each bar row, top to bottom */
static const unsigned char bar_color[BAR_ROWS] = {
    COLOR_RED, COLOR_LIGHTRED, COLOR_ORANGE, COLOR_YELLOW,
    COLOR_YELLOW, COLOR_LIGHTGREEN, COLOR_GREEN, COLOR_GREEN
};

#define COL_TEXT    COLOR_GRAY3
#define COL_HEAD    COLOR_LIGHTBLUE
#define COL_DIM     COLOR_GRAY1

/* screen codes of the hex digits */
static const unsigned char hexscr[16] = {
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
    0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46
};

/* offset of each screen row: no multiplication in the drawing code */
#define R(n) ((n) * 40)
static const unsigned int row_ofs[25] = {
    R(0), R(1), R(2), R(3), R(4), R(5), R(6), R(7), R(8), R(9), R(10), R(11), R(12),
    R(13), R(14), R(15), R(16), R(17), R(18), R(19), R(20), R(21), R(22), R(23), R(24)
};
#undef R

static unsigned char bar_px[BARS];          /* height shown, with fall-off */
static unsigned char bar_shown[BARS];       /* height drawn on screen */
static unsigned char line_buf[40];

/* value shown in each field: a field is written again only when it changes
 * ($FFFF = not drawn yet) */
enum {
    F_LINE, F_ROW, F_ROWS, F_SPEED, F_SEC, F_PAUSE, F_MUTE, F_COUNT
};
static unsigned int shown[F_COUNT];

static unsigned char changed(unsigned char f, unsigned int v)
{
    if (shown[f] == v)
        return 0;
    shown[f] = v;
    return 1;
}

static const unsigned char *song_start;

/* ---- screen helpers --------------------------------------------------- */

/* PETSCII (cc65 strings, keyboard) -> screen code, upper/lower case set */
static unsigned char screen_code(unsigned char c)
{
    if (c < 0x20)
        return 0x20;
    if (c < 0x40)
        return c;
    if (c < 0x60)
        return c - 0x40;        /* @, a-z, [ £ ] ^ <- */
    if (c < 0x80)
        return c - 0x20;
    if (c < 0xA0)
        return 0x20;
    if (c < 0xC0)
        return c - 0x40;        /* graphics, _ */
    return c - 0x80;            /* A-Z */
}

static void put_codes(unsigned char x, unsigned char y, const unsigned char *c, unsigned char n)
{
    memcpy(SCREEN + row_ofs[y] + x, c, n);
}

static void put_color(unsigned char x, unsigned char y, unsigned char col, unsigned char n)
{
    memset(COLOR_RAM + row_ofs[y] + x, col, n);
}

static void put_text(unsigned char x, unsigned char y, const char *s, unsigned char inv)
{
    unsigned char n = 0;

    while (s[n] && x + n < 40) {
        line_buf[n] = screen_code((unsigned char)s[n]) | inv;
        n++;
    }
    put_codes(x, y, line_buf, n);
}

static void put_center(unsigned char y, const char *s)
{
    unsigned char n = (unsigned char)strlen(s);

    put_text(n < 40 ? (40 - n) / 2 : 0, y, s, 0);
}

static void put_hex(unsigned char x, unsigned char y, unsigned char v)
{
    unsigned char *p = SCREEN + row_ofs[y] + x;

    p[0] = hexscr[v >> 4];
    p[1] = hexscr[v & 15];
}

static void put_dec(unsigned char x, unsigned char y, unsigned int v, unsigned char digits)
{
    unsigned char i = digits;

    while (i--) {
        line_buf[i] = screen_code('0' + v % 10);
        v /= 10;
    }
    put_codes(x, y, line_buf, digits);
}

/* ---- static parts of the screen ---------------------------------------- */

#define SCROLL_WAIT     5       /* seconds of play before a long line scrolls */
#define SCROLL_SHIFT    3       /* one character every 8 frames */
#define SCROLL_GAP      40      /* blanks between the end and the start again */

static const char *const info_text[3] = { RMT_INFO_NAME, RMT_INFO_AUTHOR, RMT_INFO_DATE };
static unsigned char info_len[3];
static unsigned char info_shown[3];         /* scroll offset drawn */
/* screen codes of a long line and its SCROLL_GAP blanks (rmtinfo.py keeps
 * at most 200 characters) */
static unsigned char info_codes[3][200 + SCROLL_GAP];

/* the 40 cells of a long info line, from scroll offset k: the text and its
 * gap go round, so the row is at most two copies */
static void info_render(unsigned char i, unsigned char k)
{
    unsigned char period = info_len[i] + SCROLL_GAP;
    unsigned char first = period - k;
    unsigned char *dst = SCREEN + row_ofs[ROW_NAME + i];

    if (first >= 40) {
        memcpy(dst, info_codes[i] + k, 40);
        return;
    }
    memcpy(dst, info_codes[i] + k, first);
    memcpy(dst + first, info_codes[i], 40 - first);
}

static void draw_static(void)
{
    unsigned char i, y;
    char title[41];

    memset(title, ' ', 40);
    title[40] = 0;
    memcpy(title + 1, "RMT PLAYER  COMMODORE 64 SID", 28);
    memcpy(title + 31, "RMT4", 4);
    memcpy(title + 36, sid_ntsc ? "NTSC" : "PAL ", 4);
    put_text(0, ROW_TITLE, title, 0x80);
    put_color(0, ROW_TITLE, COL_HEAD, 40);

    for (i = 0; i < 3; i++) {
        info_len[i] = (unsigned char)strlen(info_text[i]);
        if (info_len[i] <= 40) {
            put_center(ROW_NAME + i, info_text[i]);
            continue;
        }
        memset(info_codes[i], 0x20, sizeof info_codes[i]);
        for (y = 0; y < info_len[i]; y++)
            info_codes[i][y] = screen_code((unsigned char)info_text[i][y]);
        info_render(i, 0);      /* first 40 characters until draw_info() scrolls */
    }
    put_color(0, ROW_NAME, COLOR_WHITE, 40);

    put_center(ROW_GROUPS, "SID voices");
    put_color(0, ROW_GROUPS, COL_HEAD, 40);
    for (y = 0; y < BAR_ROWS; y++)
        put_color(0, BAR_TOP + y, bar_color[y], 40);

    put_text(0, ROW_AUDF, "AUDF", 0);
    put_text(0, ROW_AUDC, "AUDC", 0);
    put_text(18, ROW_AUDF, "AUDCTL", 0);
    put_text(0, ROW_FREQ, "SID FREQ", 0);
    put_text(0, ROW_WAVE, "SID WAVE", 0);
    put_text(26, ROW_WAVE, "FROM", 0);
    put_text(0, ROW_POS, "LINE   /      ROW   /     SPEED", 0);
    put_text(0, ROW_STATE, "TIME   :", 0);
    put_text(0, ROW_KEYS, "SPC PAUSE  R RESTART  123 SID  STOP EXIT", 0);
    put_color(0, ROW_KEYS, COL_DIM, 40);
}

/* ---- dynamic parts ----------------------------------------------------- */

/* coarse scroll of the info lines longer than 40 characters; the offset comes
 * from the play time, so it stops in pause and starts again on restart */
static void draw_info(unsigned long frames, unsigned char fps)
{
    unsigned int wait = fps * SCROLL_WAIT;
    unsigned int step;
    unsigned char i, k;

    step = frames < wait ? 0 : (unsigned int)((frames - wait) >> SCROLL_SHIFT);
    for (i = 0; i < 3; i++) {
        if (info_len[i] <= 40)
            continue;
        k = (unsigned char)(step % (unsigned char)(info_len[i] + SCROLL_GAP));
        if (k == info_shown[i])
            continue;
        info_shown[i] = k;
        info_render(i, k);
    }
}

static void draw_bars(unsigned char paused)
{
    unsigned char i, r, h, g, last, target;
    unsigned char *p;

    for (i = 0; i < BARS; i++) {
        target = paused ? 0 : sid_volume[i] << 2;
        if (target >= bar_px[i])
            bar_px[i] = target;
        else
            bar_px[i] -= (bar_px[i] - target > 2) ? 2 : bar_px[i] - target;

        h = bar_px[i];
        g = bar_shown[i];
        if (h == g)
            continue;
        bar_shown[i] = h;
        /* only the rows between the old and the new top change */
        if (g < h) {
            r = g >> 3;
            last = (h - 1) >> 3;
        } else {
            r = h >> 3;
            last = (g - 1) >> 3;
        }
        p = SCREEN + (BAR_TOP + BAR_ROWS - 1) * 40 + bar_x[i] - row_ofs[r];
        for (; r <= last; r++) {
            /* r = 0 is the bottom row: pixels of the bar in row r */
            g = r << 3;
            g = h > g ? h - g : 0;
            if (g > 8)
                g = 8;
            memset(p, block[g], BAR_W);
            p -= 40;
        }
    }
}

/* hex fields: register -> screen position (2 cells); reg_old[] holds the
 * value drawn, so a field is written only when it changes */
#define AT(x, y)    (SCREEN + (y) * 40 + (x))
static volatile unsigned char *const reg_src[] = {
    &sid_pokey[0], &sid_pokey[2], &sid_pokey[4], &sid_pokey[6],     /* AUDF */
    &sid_pokey[1], &sid_pokey[3], &sid_pokey[5], &sid_pokey[7],     /* AUDC */
    &sid_pokey[8],                                                  /* AUDCTL */
    &sid_freq_hi[0], &sid_freq_lo[0], &sid_freq_hi[1], &sid_freq_lo[1],
    &sid_freq_hi[2], &sid_freq_lo[2],
    &sid_wave[0], &sid_wave[1], &sid_wave[2]
};
static unsigned char *const reg_dst[] = {
    AT(5, ROW_AUDF), AT(8, ROW_AUDF), AT(11, ROW_AUDF), AT(14, ROW_AUDF),
    AT(5, ROW_AUDC), AT(8, ROW_AUDC), AT(11, ROW_AUDC), AT(14, ROW_AUDC),
    AT(25, ROW_AUDF),
    AT(9, ROW_FREQ), AT(11, ROW_FREQ), AT(14, ROW_FREQ), AT(16, ROW_FREQ),
    AT(19, ROW_FREQ), AT(21, ROW_FREQ),
    AT(9, ROW_WAVE), AT(14, ROW_WAVE), AT(19, ROW_WAVE)
};
#define REGS        (sizeof reg_dst / sizeof reg_dst[0])
static unsigned char reg_old[REGS];
static unsigned char src_old[3];

static void draw_regs(void)
{
    unsigned char i, v;
    unsigned char *p;

    for (i = 0; i < REGS; i++) {
        v = *reg_src[i];
        if (v == reg_old[i])
            continue;
        reg_old[i] = v;
        p = reg_dst[i];
        p[0] = hexscr[v >> 4];
        p[1] = hexscr[v & 15];
    }
    for (i = 0; i < 3; i++) {
        v = sid_src[i];
        if (v == src_old[i])
            continue;
        src_old[i] = v;
        AT(31, ROW_WAVE)[i * 3] = 0x31 + v;     /* screen code of '1' + v */
    }
}

/* the first draw_regs() writes every field */
static void regs_reset(void)
{
    unsigned char i;

    for (i = 0; i < REGS; i++)
        reg_old[i] = *reg_src[i] ^ 0xFF;
    for (i = 0; i < 3; i++)
        src_old[i] = sid_src[i] ^ 0xFF;
}

static void draw_mute(void)
{
    unsigned char i, m;

    if (!changed(F_MUTE, sid_mute))
        return;
    for (i = 0; i < 3; i++) {
        m = sid_mute & (1 << i);
        /* voice number under the middle of the bar (column 3 of 0..5), OFF
         * when muted */
        put_text(bar_x[i] + 2, ROW_LABELS, m ? "OFF" : "   ", m ? 0x80 : 0);
        if (!m) {
            line_buf[0] = screen_code('1' + i);
            put_codes(bar_x[i] + 3, ROW_LABELS, line_buf, 1);
        }
    }
}

static void draw_position(void)
{
    const unsigned char *a, *b;
    unsigned int line;

    /* the IRQ may move the pointer between the two byte reads */
    do {
        a = (const unsigned char *)rmt_p_song;
        b = (const unsigned char *)rmt_p_song;
    } while (a != b);
    line = (unsigned int)(a - song_start) >> 2;
    line = line ? line - 1 : 0;     /* p_song already points to the next line */
    if (line >= RMT_INFO_LINES)
        line = RMT_INFO_LINES - 1;

    if (changed(F_LINE, line))
        put_hex(5, ROW_POS, (unsigned char)line);
    if (changed(F_ROW, rmt_abeat))
        put_hex(18, ROW_POS, rmt_abeat);
    if (changed(F_ROWS, rmt_maxtracklen))
        put_hex(21, ROW_POS, (unsigned char)(rmt_maxtracklen - 1));
    if (changed(F_SPEED, rmt_speed))
        put_hex(32, ROW_POS, rmt_speed);
}

static void draw_state(unsigned int s, unsigned char paused)
{
    if (changed(F_SEC, s)) {
        put_dec(5, ROW_STATE, s / 60, 2);
        put_dec(8, ROW_STATE, s % 60, 2);
    }
    if (changed(F_PAUSE, paused))
        put_text(33, ROW_STATE, paused ? "PAUSED" : "      ", 0x80 * paused);
}

#define FRAME_LO    (*(volatile unsigned char *)&sid_frames)

/* Once per frame. Playing: until the player IRQ (raster line 0) counts the
 * next frame, then the screen work runs in the rest of the frame. Not a
 * wait for one raster line (waitvsync() waits for line 0): the player IRQ
 * and the KERNAL keyboard IRQ, 60 Hz and not in step with the frames, run
 * for tens of lines and the poll would miss the line in some frames.
 * Paused (IRQ off): until the beam is below line 250 (251..311 on PAL,
 * 251..262 on NTSC), wide enough for the keyboard IRQ. */
static unsigned char below(void)
{
    return (VIC.ctrl1 & 0x80) || VIC.rasterline > 250;
}

static void frame_wait(unsigned char paused)
{
    unsigned char f;

    if (!paused) {
        f = FRAME_LO;
        while (FRAME_LO == f)
            ;
        return;
    }
    while (below())
        ;
    while (!below())
        ;
}

/* ---- main --------------------------------------------------------------- */

int main(void)
{
    unsigned char paused = 0;
    unsigned char fps, k, now, last = 0, sub = 0, pass = 0;
    unsigned int secs = 0;
    unsigned char old_border = VIC.bordercolor, old_bg = VIC.bgcolor0;
    unsigned char old_addr = VIC.addr, old_lock = SHFLAG_LOCK;
    unsigned long frames = 0;

    song_start = (const unsigned char *)(rmt_song_data[14] | (rmt_song_data[15] << 8));
    sid_init(rmt_song_data);
    fps = sid_ntsc ? 60 : 50;

    VIC.bordercolor = COLOR_BLACK;
    VIC.bgcolor0 = COLOR_BLACK;
    VIC.addr = old_addr | 0x02;     /* upper/lower case characters */
    SHFLAG_LOCK = 0x80;
    clrscr();
    memset(COLOR_RAM, COL_TEXT, 1000);
    memset(shown, 0xFF, sizeof shown);
    regs_reset();
    draw_static();
    put_hex(8, ROW_POS, RMT_INFO_LINES - 1);

    sid_play_on();
    for (;;) {
        frame_wait(paused);
        /* frames played, from the IRQ counter (sid_play_on sets it to 0): a
         * pass of this loop can take more than one frame */
        if (!paused) {
            now = FRAME_LO;
            k = now - last;
            last = now;
            frames += k;
            sub += k;
            while (sub >= fps) {
                sub -= fps;
                ++secs;
            }
        }

        /* bars every frame, the rest every other frame: all of it does not
         * fit in the time the player IRQ leaves in one frame */
        draw_bars(paused);
        if (++pass & 1) {
            draw_regs();
            draw_mute();
        }
        else {
            draw_position();
            draw_state(secs, paused);
            draw_info(frames, fps);
        }

        if (!kbhit())
            continue;
        k = cgetc();
        if (k == CH_STOP || k == 0x5F)      /* RUN/STOP, <- */
            break;
        if (k == ' ') {
            paused = !paused;
            if (paused)
                sid_play_off();     /* silences the SID, keeps the position */
            else {
                last = 0;
                sid_play_on();
            }
        }
        else if (k == 'r' || k == 'R') {
            sid_play_off();
            sid_init(rmt_song_data);
            frames = 0;
            secs = sub = last = 0;
            paused = 0;
            sid_play_on();
        }
        else if (k >= '1' && k <= '3')
            sid_mute ^= 1 << (k - '1');
    }

    sid_play_off();
    sid_mute = 0;
    SHFLAG_LOCK = old_lock;
    VIC.addr = old_addr;
    VIC.bordercolor = old_border;
    VIC.bgcolor0 = old_bg;
    clrscr();
    cputs("music stopped.\r\n");
    return 0;
}
