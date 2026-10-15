;
; vmirror.s - the Atari text screen mirrored on the VERA (VeraX16 PBI card)
;
; Used by rmtvbi.s when an RMT8 song finds both a second POKEY and the VERA:
; the two POKEYs play the 8 channels and the VERA only shows a copy of the
; OS text screen (GRAPHICS 0, 40x24 at SAVMSC, what conio writes).
;
; vmirror_init (once, from rmt_init): the OS font (CHBAS) in VRAM as 1bpp
; tiles, then inverse copies for the screen codes 128-255; layer 1 in text
; mode, 64x32 map, 320x240 (the 24 rows centred in 30), every cell a space.
; Colours: VERA palette entries 1 (text), 2 (background) and 3 (border) get
; the Atari colours of GRAPHICS 0: background COLOR2, text with the hue of
; COLOR2 and the luminance of COLOR1, border COLOR4 (OS shadows), turned into
; 12 bit colours with the PAL / NTSC palette of atari800; they follow the
; shadows when the program changes them, and the attract mode of the OS. The display registers and the 3
; palette entries are saved and put back by vmirror_off.
;
; vmirror_step (from the VBI, after the player, once per frame when the
; frame has time left): the next row of a pass over the screen (a full pass
; every 24 frames), plus one "hot" row: the rows that had changed cells the
; last time they were compared (VU meters, counters) are taken in turn, so
; they come again every few frames instead of every 24. Each cell is compared with
; a shadow copy of what the VERA shows and only the changed ones are
; written: one byte (the tile; the colour byte never changes, the address
; steps by 2, downwards), a new address only when the changed cells are not
; next to each other. An unchanged row costs about 650 cycles. The VERA
; address and CTRL are saved and put back: the interrupted program may be
; using the VERA.
;
        .export vmirror_init, vmirror_step, vmirror_off
        .include "vera.inc"

SAVMSC  = $58                   ; OS: screen memory
CHBAS   = $02F4                 ; OS: font page
PALNTS  = $62                   ; XL/XE OS: 0 = NTSC, 1 = PAL
COLOR1  = $02C5                 ; OS colour shadows: text luminance,
COLOR2  = $02C6                 ; background (and text hue),
COLOR4  = $02C8                 ; border
COLRSH  = $4F                   ; OS attract mode: hardware colour =
DRKMSK  = $4E                   ; (shadow EOR COLRSH) AND DRKMSK
VROW0   = 3                     ; VERA map row of screen row 0
VMAP    = $0000                 ; 64x32 map, 128 bytes per row
VFONT   = $1000                 ; 256 tiles of 8 bytes
ATTR    = $21                   ; colour: background palette entry 2, text 1
VPAL    = $FA00                 ; palette at $1FA00, 2 bytes per entry

VERA_DC_VIDEO   = PBI_ADDR+$09  ; DCSEL 0
VERA_DC_HSCALE  = PBI_ADDR+$0A
VERA_DC_VSCALE  = PBI_ADDR+$0B
VERA_DC_BORDER  = PBI_ADDR+$0C
VERA_L1_CONFIG  = PBI_ADDR+$14  ; CONFIG MAPBASE TILEBASE HSCROLL(2) VSCROLL(2)
VERA_DECR       = $08           ; ADDR_H: the address goes down
VERA_INC2       = $20           ; ADDR_H: steps of 2

        .segment "BSS"
saved:          .res 4 + 7      ; DC_VIDEO HSCALE VSCALE BORDER, L1 x 7
shadow:         .res 24 * 40    ; screen codes shown on the VERA
mrow:           .res 1          ; next screen row of the pass
hrow:           .res 1          ; last hot row done
hot:            .res 24         ; <> 0: the row changed when last compared
ctmp:           .res 1
vrl:            .res 1          ; VERA map address of the row: low (0 / $80)
vrm:            .res 1          ;                              middle
next:           .res 1          ; column the VERA address points to
s_ctrl:         .res 1
s_l:            .res 1
s_m:            .res 1
s_h:            .res 1
pal_saved:      .res 6          ; palette entries 1-3 before vmirror_init
col:            .res 3          ; COLOR1 COLOR2 COLOR4 shown ($FF: none yet)
eff:            .res 3          ; the same as the OS puts them in hardware

        .segment "RODATA"
; row * 40, for SAVMSC and shadow
rowlo:
        .repeat 24, I
        .byte <(I * 40)
        .endrepeat
rowhi:
        .repeat 24, I
        .byte >(I * 40)
        .endrepeat

        .segment "RODATA"
; Atari colour (hue, luminance / 2) -> VERA 12 bit colour: the PAL and NTSC
; palettes atari800 makes with its default settings (colours_pal.c,
; colours_ntsc.c); byte gb = G << 4 | B, byte r = R
pal_gb_pal:
        .byte $00, $22, $33, $55, $66, $88, $AA, $CC
        .byte $00, $10, $30, $41, $62, $84, $A6, $C8
        .byte $00, $00, $21, $43, $54, $76, $98, $BA
        .byte $00, $01, $22, $34, $55, $77, $99, $BB
        .byte $02, $03, $15, $37, $48, $6A, $8C, $BE
        .byte $04, $05, $17, $38, $4A, $6C, $8E, $BF
        .byte $05, $07, $18, $3A, $5B, $6D, $9F, $BF
        .byte $05, $17, $38, $4A, $6B, $8D, $AF, $CF
        .byte $14, $25, $37, $58, $7A, $8C, $AE, $DF
        .byte $12, $33, $45, $67, $78, $9A, $BC, $DE
        .byte $20, $31, $52, $64, $85, $A7, $C9, $EB
        .byte $20, $40, $50, $71, $82, $A4, $C6, $E8
        .byte $20, $30, $50, $60, $81, $A3, $C5, $E7
        .byte $10, $30, $40, $60, $70, $92, $B4, $E7
        .byte $10, $20, $30, $50, $61, $83, $A5, $D7
        .byte $00, $10, $30, $41, $62, $84, $A6, $C8
pal_r_pal:
        .byte $00, $02, $03, $05, $06, $08, $0A, $0C
        .byte $03, $04, $05, $07, $08, $0A, $0C, $0F
        .byte $03, $05, $06, $08, $09, $0B, $0D, $0F
        .byte $03, $05, $06, $08, $09, $0B, $0D, $0F
        .byte $03, $04, $06, $08, $09, $0B, $0D, $0F
        .byte $02, $04, $05, $07, $08, $0A, $0C, $0F
        .byte $01, $03, $04, $06, $07, $09, $0B, $0E
        .byte $00, $00, $02, $03, $05, $07, $09, $0B
        .byte $00, $00, $01, $02, $04, $06, $08, $0A
        .byte $00, $00, $00, $02, $03, $05, $07, $0A
        .byte $00, $00, $00, $02, $03, $05, $07, $09
        .byte $00, $00, $01, $02, $04, $06, $08, $0A
        .byte $00, $00, $02, $03, $05, $07, $09, $0B
        .byte $00, $02, $03, $05, $06, $08, $0A, $0C
        .byte $02, $03, $04, $06, $07, $09, $0B, $0E
        .byte $03, $04, $05, $07, $08, $0A, $0C, $0F
pal_gb_ntsc:
        .byte $00, $22, $33, $55, $66, $88, $AA, $CC
        .byte $10, $30, $40, $60, $70, $92, $B4, $D7
        .byte $00, $20, $30, $50, $61, $83, $A5, $D7
        .byte $00, $10, $20, $41, $53, $75, $97, $C9
        .byte $00, $01, $22, $34, $55, $77, $99, $BB
        .byte $02, $03, $15, $36, $48, $6A, $8C, $BE
        .byte $04, $06, $17, $39, $4A, $6C, $8E, $BF
        .byte $06, $07, $18, $3A, $5B, $7D, $9F, $BF
        .byte $06, $17, $29, $4A, $5C, $7E, $9F, $CF
        .byte $05, $26, $38, $59, $6B, $8D, $AF, $CF
        .byte $13, $24, $46, $67, $79, $9B, $BD, $DF
        .byte $20, $32, $53, $65, $86, $A8, $CA, $ED
        .byte $20, $40, $51, $72, $84, $A6, $C8, $EA
        .byte $20, $30, $50, $70, $82, $A4, $C6, $E8
        .byte $20, $30, $40, $60, $81, $93, $B5, $E7
        .byte $10, $20, $40, $50, $71, $93, $B5, $D7
pal_r_ntsc:
        .byte $00, $02, $03, $05, $06, $08, $0A, $0C
        .byte $00, $02, $03, $05, $06, $08, $0A, $0C
        .byte $02, $03, $04, $06, $08, $09, $0B, $0E
        .byte $03, $04, $06, $07, $09, $0B, $0D, $0F
        .byte $03, $05, $06, $08, $09, $0B, $0D, $0F
        .byte $03, $05, $06, $08, $09, $0B, $0D, $0F
        .byte $03, $04, $05, $07, $08, $0A, $0C, $0F
        .byte $01, $03, $04, $06, $07, $09, $0B, $0D
        .byte $00, $01, $03, $04, $06, $08, $0A, $0C
        .byte $00, $00, $01, $03, $04, $06, $08, $0B
        .byte $00, $00, $00, $02, $03, $05, $07, $0A
        .byte $00, $00, $00, $01, $03, $05, $07, $09
        .byte $00, $00, $00, $02, $03, $05, $07, $0A
        .byte $00, $00, $01, $03, $04, $06, $08, $0A
        .byte $00, $01, $02, $04, $05, $07, $09, $0C
        .byte $01, $02, $04, $05, $07, $09, $0B, $0D

        .segment "CODE"

; ---------------------------------------------------------------------------
; vmirror_init - VERA text screen, font, empty map
vmirror_init:
        lda #0
        sta VERA_CTRL
        ldx #3
@sv:    lda VERA_DC_VIDEO,x
        sta saved,x
        dex
        bpl @sv
        ldx #6
@sl:    lda VERA_L1_CONFIG,x
        sta saved+4,x
        dex
        bpl @sl

        ; palette entries 1-3: saved, then the Atari colours
        lda PALNTS
        bne @pal
        lda #<pal_gb_ntsc
        sta pc_gb+1
        lda #>pal_gb_ntsc
        sta pc_gb+2
        lda #<pal_r_ntsc
        sta pc_r+1
        lda #>pal_r_ntsc
        sta pc_r+2
@pal:   jsr pal_seek
        ldx #0
@ps:    lda VERA_DATA0
        sta pal_saved,x
        inx
        cpx #6
        bne @ps
        lda #$FF
        sta col
        sta col+1
        sta col+2
        jsr colours

        ; font: 1024 bytes of the OS font, then the same inverted
        lda #<VFONT
        sta VERA_ADDR_L
        lda #>VFONT
        sta VERA_ADDR_M
        lda #VERA_INC1
        sta VERA_ADDR_H
        lda CHBAS
        sta @src+2
        sta @inv+2
        ldx #4                  ; 4 pages
@fp:    ldy #0
@src:   lda $FF00,y
        sta VERA_DATA0
        iny
        bne @src
        inc @src+2
        dex
        bne @fp
        ldx #4
@ip:    ldy #0
@inv:   lda $FF00,y
        eor #$FF
        sta VERA_DATA0
        iny
        bne @inv
        inc @inv+2
        dex
        bne @ip

        ; map: 64 x 32 spaces (screen code 0) in ATTR
        lda #<VMAP
        sta VERA_ADDR_L
        lda #>VMAP
        sta VERA_ADDR_M
        lda #VERA_INC1
        sta VERA_ADDR_H
        ldx #16                 ; 16 x 128 cells
@m1:    ldy #128
@m2:    lda #0
        sta VERA_DATA0
        lda #ATTR
        sta VERA_DATA0
        dey
        bne @m2
        dex
        bne @m1

        ; shadow: all spaces, as the map
        lda #0
        ldx #240                ; 4 x 240 = 960 bytes
@sh:    sta shadow-1,x
        sta shadow+240-1,x
        sta shadow+480-1,x
        sta shadow+720-1,x
        dex
        bne @sh
        sta mrow
        sta hrow
        ldx #23
@ht:    sta hot,x
        dex
        bpl @ht

        ; layer 1: 1bpp text, map 64x32 at VMAP, 8x8 tiles at VFONT, no scroll
        lda #$10
        sta VERA_L1_CONFIG
        lda #VMAP >> 9
        sta VERA_L1_CONFIG+1
        lda #(VFONT >> 11) << 2
        sta VERA_L1_CONFIG+2
        lda #0
        ldx #3
@sc:    sta VERA_L1_CONFIG+3,x
        dex
        bpl @sc
        lda #64                 ; 320x240
        sta VERA_DC_HSCALE
        sta VERA_DC_VSCALE
        lda #3                  ; palette entry 3: COLOR4
        sta VERA_DC_BORDER
        lda saved               ; output mode of the card, layer 1 only
        and #$0F
        bne @om
        lda #1                  ; none set: VGA
@om:    ora #$20
        sta VERA_DC_VIDEO
        rts

; ---------------------------------------------------------------------------
; vmirror_off - the VERA display as it was before vmirror_init
vmirror_off:
        lda #0
        sta VERA_CTRL
        ldx #3
@d:     lda saved,x
        sta VERA_DC_VIDEO,x
        dex
        bpl @d
        ldx #6
@l:     lda saved+4,x
        sta VERA_L1_CONFIG,x
        dex
        bpl @l
        jsr pal_seek
        ldx #0
@p:     lda pal_saved,x
        sta VERA_DATA0
        inx
        cpx #6
        bne @p
        rts

; pal_seek - DATA0 on palette entry 1, increment 1
pal_seek:
        lda #<(VPAL + 2)
        sta VERA_ADDR_L
        lda #>(VPAL + 2)
        sta VERA_ADDR_M
        lda #VERA_INC1 | 1      ; bank 1
        sta VERA_ADDR_H
        rts

; colours - palette entries 1-3 from COLOR1, COLOR2, COLOR4 when they
; changed (VERA_CTRL = 0; moves the VERA address)
colours:
        lda COLOR1              ; the colours as the OS writes them to
        eor COLRSH              ; the hardware (attract mode)
        and DRKMSK
        sta eff
        lda COLOR2
        eor COLRSH
        and DRKMSK
        sta eff+1
        lda COLOR4
        eor COLRSH
        and DRKMSK
        sta eff+2
        ldx #2
@c:     lda eff,x
        cmp col,x
        bne @set
        dex
        bpl @c
        rts
@set:   ldx #2
@cp:    lda eff,x
        sta col,x
        dex
        bpl @cp
        jsr pal_seek
        lda col+1               ; text: hue of COLOR2, luminance of COLOR1
        and #$F0
        sta ctmp
        lda col
        and #$0E
        ora ctmp
        jsr put_colour
        lda col+1               ; background
        jsr put_colour
        lda col+2               ; border
                                ; fall through
; put_colour - Atari colour A to the palette entry DATA0 points to
put_colour:
        lsr a                   ; hue * 8 + luminance / 2
        tax
pc_gb:  lda pal_gb_pal,x        ; (vmirror_init sets the PAL / NTSC table)
        sta VERA_DATA0
pc_r:   lda pal_r_pal,x
        sta VERA_DATA0
        rts

; ---------------------------------------------------------------------------
; vmirror_step - the next row of the pass and one hot row to the VERA
; (changed cells only), and the colours when the OS shadows changed
vmirror_step:
        lda VERA_CTRL
        sta s_ctrl
        lda #0
        sta VERA_CTRL           ; ADDRSEL 0, DCSEL 0
        lda VERA_ADDR_L
        sta s_l
        lda VERA_ADDR_M
        sta s_m
        lda VERA_ADDR_H
        sta s_h
        jsr colours
        ldx mrow                ; the pass
        jsr do_row
        ldy #24                 ; the next hot row after hrow, not mrow
        ldx hrow
@find:  inx
        cpx #24
        bcc @in
        ldx #0
@in:    lda hot,x
        beq @not
        cpx mrow
        bne @hot
@not:   dey
        bne @find
        beq @pass               ; no hot row
@hot:   stx hrow
        jsr do_row
@pass:  inc mrow
        lda mrow
        cmp #24
        bcc @more
        lda #0
        sta mrow
@more:  lda s_l
        sta VERA_ADDR_L
        lda s_m
        sta VERA_ADDR_M
        lda s_h
        sta VERA_ADDR_H
        lda s_ctrl
        sta VERA_CTRL
        rts

; do_row - screen row X to the VERA, changed cells only; hot,X = changed
do_row:
        lda #0
        sta hot,x
        stx ctmp
        lda rowlo,x             ; screen row and its shadow row
        clc
        adc SAVMSC
        sta @scr+1
        lda rowhi,x
        adc SAVMSC+1
        sta @scr+2
        lda rowlo,x
        clc
        adc #<shadow
        sta @cmp+1
        sta @shw+1
        lda rowhi,x
        adc #>shadow
        sta @cmp+2
        sta @shw+2
        txa                     ; VERA map row (x + VROW0) * 128
        clc
        adc #VROW0
        lsr a
        sta vrm
        lda #0
        ror a
        sta vrl
        lda #$FF
        sta next
        ldy #39                 ; right to left: the VERA address goes down
@cell:
@scr:   lda $FFFF,y
@cmp:   cmp $FFFF,y
        beq @same
@shw:   sta $FFFF,y
        cpy next
        beq @put                ; the address already points to this cell
        tax
        tya                     ; cell y: vrl + y * 2 (y * 2 < 128)
        asl a
        ora vrl
        sta VERA_ADDR_L
        lda vrm
        sta VERA_ADDR_M
        lda #VERA_INC2 | VERA_DECR
        sta VERA_ADDR_H
        txa
@put:   sta VERA_DATA0
        dey
        sty next
        bpl @cell
        ldx ctmp                ; something changed: a hot row
        inc hot,x
        rts
@same:  dey
        bpl @cell
        lda next                ; still $FF: nothing written (a write to
        cmp #$FF                ; cell 0 ends the loop above, not here)
        beq @cold
        ldx ctmp
        inc hot,x
@cold:  rts
