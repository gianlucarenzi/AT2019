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
 *   song line, row in the track, speed, play time; for a .sap/.xex song
 *   (RMT_LZSS, src/lzsplayr.s) the section of the LZSS stream (intro, loop)
 *   and the frame in it
 *
 *   SPACE  pause / play       R  restart the song
 *   1 2 3  SID voice on/off   RUN/STOP or <-  stop and exit
 *
 * Text screen at $0400 in the upper/lower case character set; the bars use
 * the block characters of the ROM font (1/8 to 8/8 of a cell).
 * Sound: the same player as build/rmt_cbm64.prg (rmtplayr.s or lzsplayr.s
 * + sidrmt.s).
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

#ifdef RMT_LZSS
/* rmt_play calls of each section (sap2ca65.py) */
static const unsigned long sec_frames[RMT_INFO_SECTIONS] = RMT_INFO_FRAMES;
#else
static const unsigned char *song_start;
#endif

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

/* two decimal digits of v (0..99): tens by subtraction, no division (the
 * cc65 runtime division takes hundreds of cycles) */
static void put_dec2(unsigned char x, unsigned char y, unsigned char v)
{
    unsigned char *p = SCREEN + row_ofs[y] + x;
    unsigned char t = '0';

    while (v >= 10) {
        v -= 10;
        ++t;
    }
    p[0] = t;               /* digits: screen code = PETSCII */
    p[1] = '0' + v;
}

/* ---- static parts of the screen ---------------------------------------- */

#define SCROLL_WAIT     5       /* seconds of play before a long line scrolls */
#define SCROLL_SHIFT    3       /* one character every 8 frames */
#define SCROLL_GAP      40      /* blanks between the end and the start again */

static const char *const info_text[3] = { RMT_INFO_NAME, RMT_INFO_AUTHOR, RMT_INFO_DATE };
static unsigned char info_len[3];
static unsigned char info_shown[3];         /* scroll offset drawn */
static unsigned int info_wait;              /* frames of play before the long lines scroll */
static unsigned char info_sub;              /* frames since the last scroll step */
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
#ifdef RMT_LZSS
    put_text(0, ROW_POS, "SECT   /     FRAME       /", 0);
#else
    put_text(0, ROW_POS, "LINE   /      ROW   /     SPEED", 0);
#endif
    put_text(0, ROW_STATE, "TIME   :", 0);
    put_text(0, ROW_KEYS, "SPC PAUSE  R RESTART  123 SID  STOP EXIT", 0);
    put_color(0, ROW_KEYS, COL_DIM, 40);
}

/* ---- dynamic parts ----------------------------------------------------- */

/* coarse scroll of the info lines longer than 40 characters: SCROLL_WAIT
 * seconds of play, then one character every 2^SCROLL_SHIFT frames. It follows
 * the frames played (it stops in pause), kept step by step: the offset from
 * the total of the frames took a 32 bit shift and a 16 bit modulo per line at
 * every call, the slowest part of a pass of the main loop */
static void info_reset(unsigned char fps)
{
    unsigned char i;

    info_wait = fps * SCROLL_WAIT;
    info_sub = 0;
    for (i = 0; i < 3; i++)
        if (info_len[i] > 40 && info_shown[i]) {
            info_shown[i] = 0;
            info_render(i, 0);
        }
}

static void draw_info(unsigned char adv)    /* frames played since the last call */
{
    unsigned char i, k, n, period;

    if (info_wait) {
        if (info_wait > adv) {
            info_wait -= adv;
            return;
        }
        adv -= (unsigned char)info_wait;
        info_wait = 0;
    }
    info_sub += adv;
    n = info_sub >> SCROLL_SHIFT;
    if (!n)
        return;
    info_sub &= (1 << SCROLL_SHIFT) - 1;
    for (i = 0; i < 3; i++) {
        if (info_len[i] <= 40)
            continue;
        period = info_len[i] + SCROLL_GAP;
        k = info_shown[i] + n;
        while (k >= period)
            k -= period;
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
            g = block[g];
            /* BAR_W cells, without the call of memset() */
            p[0] = g;
            p[1] = g;
            p[2] = g;
            p[3] = g;
            p[4] = g;
            p[5] = g;
            p -= 40;
        }
    }
}

/* hex fields: register -> screen position (2 cells); reg_old[] holds the
 * value drawn, so a field is written only when it changes. reg_val[] gets
 * the registers first (reg_load: one load and store each), so an unchanged
 * field costs a compare: with instrument speed 4 the pointer table of the
 * sources, read for all 18 fields every other frame, took about 45 raster
 * lines and the pass of the main loop did not fit in the frame */
#define AT(x, y)    (SCREEN + (y) * 40 + (x))
static unsigned char *const reg_dst[] = {
    AT(5, ROW_AUDF), AT(8, ROW_AUDF), AT(11, ROW_AUDF), AT(14, ROW_AUDF),
    AT(5, ROW_AUDC), AT(8, ROW_AUDC), AT(11, ROW_AUDC), AT(14, ROW_AUDC),
    AT(25, ROW_AUDF),
    AT(9, ROW_FREQ), AT(11, ROW_FREQ), AT(14, ROW_FREQ), AT(16, ROW_FREQ),
    AT(19, ROW_FREQ), AT(21, ROW_FREQ),
    AT(9, ROW_WAVE), AT(14, ROW_WAVE), AT(19, ROW_WAVE)
};
#define REGS        (sizeof reg_dst / sizeof reg_dst[0])
static unsigned char reg_val[REGS];
static unsigned char reg_old[REGS];
static unsigned char src_old[3];

/* the registers of the fields, in the order of reg_dst[] */
static void reg_load(void)
{
    reg_val[0] = sid_pokey[0];      /* AUDF */
    reg_val[1] = sid_pokey[2];
    reg_val[2] = sid_pokey[4];
    reg_val[3] = sid_pokey[6];
    reg_val[4] = sid_pokey[1];      /* AUDC */
    reg_val[5] = sid_pokey[3];
    reg_val[6] = sid_pokey[5];
    reg_val[7] = sid_pokey[7];
    reg_val[8] = sid_pokey[8];      /* AUDCTL */
    reg_val[9] = sid_freq_hi[0];
    reg_val[10] = sid_freq_lo[0];
    reg_val[11] = sid_freq_hi[1];
    reg_val[12] = sid_freq_lo[1];
    reg_val[13] = sid_freq_hi[2];
    reg_val[14] = sid_freq_lo[2];
    reg_val[15] = sid_wave[0];
    reg_val[16] = sid_wave[1];
    reg_val[17] = sid_wave[2];
}

static void draw_regs(void)
{
    unsigned char i, v;
    unsigned char *p;

    reg_load();
    for (i = 0; i < REGS; i++) {
        v = reg_val[i];
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

    reg_load();
    for (i = 0; i < REGS; i++)
        reg_old[i] = reg_val[i] ^ 0xFF;
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

#ifdef RMT_LZSS
static void put_hex24(unsigned char x, unsigned char y, unsigned long v)
{
    put_hex(x, y, (unsigned char)(v >> 16));
    put_hex(x + 2, y, (unsigned char)(v >> 8));
    put_hex(x + 4, y, (unsigned char)v);
}

/* LZSS: section of the stream and frame in it, of the next frame */
static void draw_position(void)
{
    unsigned char sec, lo, mid, hi;

    /* the IRQ may change them between the reads */
    do {
        sec = lzs_section;
        lo = lzs_pos[0];
        mid = lzs_pos[1];
        hi = lzs_pos[2];
    } while (sec != lzs_section || lo != lzs_pos[0]);

    if (changed(F_LINE, sec)) {
        put_hex(5, ROW_POS, sec);
        put_hex24(26, ROW_POS, sec_frames[sec] - 1);
    }
    if (changed(F_ROW, ((unsigned int)mid << 8) | lo) | changed(F_ROWS, hi))
        put_hex24(19, ROW_POS, ((unsigned long)hi << 16) | ((unsigned int)mid << 8) | lo);
}
#else
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
#endif

static void draw_state(unsigned char min, unsigned char sec, unsigned char paused)
{
    if (changed(F_SEC, ((unsigned int)min << 8) | sec)) {
        put_dec2(5, ROW_STATE, min);
        put_dec2(8, ROW_STATE, sec);
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
    unsigned char min = 0, sec = 0, adv = 0;
    unsigned char old_border = VIC.bordercolor, old_bg = VIC.bgcolor0;
    unsigned char old_addr = VIC.addr, old_lock = SHFLAG_LOCK;

#ifndef RMT_LZSS
    song_start = (const unsigned char *)(rmt_song_data[14] | (rmt_song_data[15] << 8));
#endif
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
    info_reset(fps);
#ifdef RMT_LZSS
    put_hex(8, ROW_POS, RMT_INFO_SECTIONS - 1);
#else
    put_hex(8, ROW_POS, RMT_INFO_LINES - 1);
#endif

    sid_play_on();
    for (;;) {
        frame_wait(paused);
        /* frames played, from the IRQ counter (sid_play_on sets it to 0): a
         * pass of this loop can take more than one frame */
        if (!paused) {
            now = FRAME_LO;
            k = now - last;
            last = now;
            adv += k;               /* for draw_info, every other pass */
            sub += k;
            while (sub >= fps) {
                sub -= fps;
                if (++sec == 60) {
                    sec = 0;
                    if (++min == 100)
                        min = 0;
                }
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
            draw_state(min, sec, paused);
            draw_info(adv);
            adv = 0;
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
            min = sec = sub = last = adv = 0;
            info_reset(fps);
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
