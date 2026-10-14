; ============================================================================
; psgrmt.s - RMT player output on the VERA PSG (POKEY -> PSG translation)
;
; From VERA_ATARI_PBI/vera-tests/rmt/psgrmt.s. RmtSkeleton and PokeyATest
; link it in the RMT8 builds (-D RMT_TRACKS=8): when rmtvbi.s finds the
; VeraX16 card, POKEY plays channels 1-4 and this code plays channels 5-8
; (psg_hybrid), once per frame from the VBI, after the player. The player
; (rmtplayr.s / lzsplayr.s) computes the channels in trackn_audf,
; trackn_audc, v_audctl and v_audctl2; this code turns them into VERA PSG
; voices:
;
;   frequency  from AUDF, AUDCTL (64/15 kHz, 1.79 MHz, 16 bit) and the
;              distortion: word = K / n, n = POKEY divider in machine
;              cycles, K = constant of the kind of sound (psg_ktab, PAL /
;              NTSC, tools/mkpsgtab.py). 64 kHz 8 bit channels, the usual
;              case, read the word from psgtab; the other modes divide, only
;              when AUDF, AUDCTL or the distortion change
;   waveform   pure tone -> pulse 50%; distortion C (poly4) and poly5 tones
;              -> pulse 25%; poly17 / poly5 noise -> VERA noise
;   volume     POKEY volume is linear, VERA volume is logarithmic (0.5 dB per
;              step): vol_log maps 0..15 to the VERA level of the same
;              amplitude
;   channels   one VERA voice per channel (the low channel of a 16 bit pair
;              is silent, as on POKEY). RMT4: voices 0-3; RMT8 (RMT_TRACKS =
;              8, stereo modules for two POKEYs): voices 0-7, channels 1-4
;              from the left POKEY state, 5-8 from the right one (never
;              written to hardware, see rmtplayr.s), each with its own
;              AUDCTL. Pan L+R; with psg_stereo, RMT4 puts ch 1/3 left and
;              2/4 right, RMT8 puts ch 1-4 left and 5-8 right. psg_hybrid
;              silences the voices of channels 1-4 (POKEY plays them, VERA
;              only 5-8)
;
; Not reproduced: volume only mode (AUDC bit 4, sample playback) and the
; high pass filters (AUDCTL bits 2, 1). The noise is VERA's own LFSR at the
; POKEY rate, not POKEY's poly17/poly5 pattern.
;
; Speed: this runs in the VBI next to the player, so every cycle counts.
; One unrolled block per channel (absolute addresses, no loop, no calls on
; the common path); AUDC & $1F indexes the VERA level table (0 for volume 0
; and volume only); the four bytes of each voice go straight to DATA0 as
; soon as they are known. The 64 kHz 8 bit case is about 115 cycles per
; channel. 256 byte tables indexed by AUDC would save ~16 cycles per
; channel but VERA_ATARI_PBI's TESTRIO.COM has no room left for them. The
; other clock modes (1.79 MHz, 15 kHz, 16 bit) go to
; full_word, which keeps the last word of each channel and divides again
; only when its AUDF, the AUDF of the paired channel, AUDCTL or the
; distortion change.
;
; The VERA writes happen inside an interrupt: CTRL, FX_CTRL and the port 0
; address are saved and restored, so the interrupted program can be in the
; middle of its own VRAM access sequence. A foreground call (psg_silence)
; sets wbusy and the VBI skips that frame instead of nesting.
;
; C interface: see rmt.h
; ============================================================================

        .setcpu "6502"
        .include "vera.inc"

        .export psg_update, psg_silence
        .export _psg_init, _psg_silence := psg_silence
        .export _psg_enable, _psg_stereo, _psg_hybrid, _psg_volume
        .import trackn_audf, trackn_audc, v_audctl
        .import psgtab_lo, psgtab_hi, psg_ktab

.ifdef RMT_TRACKS
NCH             = RMT_TRACKS            ; channels = PSG voices driven
.else
NCH             = 4
.endif
.if NCH > 4
        .import v_audctl2
.endif

; PSG data port. -D PSG_CAPTURE (test bench only) sends every byte to
; psg_put / psg_putx instead, which must preserve A, X, Y and the flags.
.ifdef PSG_CAPTURE
        .import psg_put, psg_putx
.macro  PUTA
        jsr psg_put
.endmacro
.macro  PUTX
        jsr psg_putx
.endmacro
.else
.macro  PUTA
        sta VERA_DATA0
.endmacro
.macro  PUTX
        stx VERA_DATA0
.endmacro
.endif

PALNTS          = $0062                 ; XL OS: 0 = NTSC
PSG_ADDR        = VERA_PSG_BASE         ; $1F9C0, voice 0
WAVE_PULSE      = $00                   ; PSG reg 3 bits 7:6
WAVE_NOISE      = $C0
PW_50           = 63                    ; duty = (PW + 1) / 128
PW_25           = 31
PAN_LR          = $C0                   ; PSG reg 2: bit 7 right, bit 6 left

        .segment "BSS"

_psg_enable:    .res 1          ; 1 = voices 0..NCH-1 follow the player
_psg_stereo:    .res 1          ; 1 = stereo pan (see header)
_psg_hybrid:    .res 1          ; 1 = channels 1-4 silent on VERA
_psg_volume:    .res NCH        ; VERA level of the voices (0..63)

psg_on:         .res 1          ; voices currently driven
wbusy:          .res 1          ; a VERA write is in progress
pan_mode:       .res 1          ; _psg_stereo the pan table was built for
pan:            .res NCH        ; PSG reg 2 pan bits of each voice
page_lo:        .res 8          ; per distortion: page of psgtab_lo / _hi
page_hi:        .res 8          ; for this TV standard
kofs:           .res 1          ; std * 21: offset in psg_ktab
lvl:            .res 1          ; current voice: VERA level
wpw:            .res 1          ; current voice: waveform | pulse width

; full_word: last word of each channel and what it was computed from
fk_f0:          .res NCH        ; AUDF of the channel
fk_f1:          .res NCH        ; AUDF of the paired channel (16 bit)
fk_ctl:         .res NCH        ; AUDCTL
fk_dist:        .res NCH        ; distortion, $FF = nothing cached
fk_sil:         .res NCH        ; 1 = silent
fw_lo:          .res NCH
fw_hi:          .res NCH

ch:             .res 1
cx:             .res 1          ; channel within its POKEY (0..3)
abase:          .res 1          ; 0 / 4: index of the POKEY's AUDF1
actl:           .res 1          ; AUDCTL of the channel's POKEY
dist:           .res 1
fast:           .res 1
base:           .res 1
tmp:            .res 1
n0:             .res 1          ; divider in machine cycles (24 bit)
n1:             .res 1
n2:             .res 1

dvd:            .res 3          ; dividend / quotient
dsr:            .res 3          ; divisor
rem:            .res 3

save_ctrl:      .res 1
save_fx:        .res 1
save_l:         .res 1
save_m:         .res 1
save_h:         .res 1

        .segment "RODATA"

; AUDC & $1F -> VERA level of the same amplitude as the POKEY volume (psg.v
; log table), 0 for volume 0 and for volume only mode (bit 4)
audc_lvl:
        .byte 0, 17, 28, 35, 40, 44, 47, 50, 52, 54, 56, 58, 59, 61, 62, 63
        .res  16, 0

; per distortion: 0 poly5+17, 1 poly5 tone, 2 poly5+4, 3 poly5 tone,
; 4 poly17, 5 pure, 6 poly4 (distortion C), 7 pure
dist_wpw:                               ; waveform | pulse width
        .byte WAVE_NOISE, WAVE_PULSE|PW_25, WAVE_NOISE, WAVE_PULSE|PW_25
        .byte WAVE_NOISE, WAVE_PULSE|PW_50, WAVE_PULSE|PW_25, WAVE_PULSE|PW_50
dist_k:                                 ; $FF: distortion C, from n mod 15
        .byte 6, 4, 6, 4, 5, 0, $FF, 0
dist_sk:                                ; psgtab kind (tools/mkpsgtab.py)
        .byte 4, 2, 4, 2, 3, 0, 1, 0
; n mod 15 -> constant index for distortion C, $FF = no pulses change (silent)
distc_k:
        .byte $FF, 3, 3, 2, 3, 1, 2, 3, 3, 2, 1, 3, 2, 3, 3
pan_stereo:                             ; with psg_stereo
.if NCH > 4
        .byte $40, $40, $40, $40, $80, $80, $80, $80    ; left / right POKEY
.else
        .byte $40, $80, $40, $80                        ; 1/3 left, 2/4 right
.endif

        .segment "CODE"

; ----------------------------------------------------------------------------
; void psg_init(void) - PAL/NTSC constants, voices silent
; ----------------------------------------------------------------------------
_psg_init:
        lda PALNTS
        beq @ntsc
        lda #0                          ; PAL: tables 0-4, constants 0-20
        ldx #0
        beq @std
@ntsc:  lda #5                          ; NTSC: tables 5-9, constants 21-41
        ldx #21
@std:   stx kofs
        clc
        adc #>psgtab_lo
        sta tmp
        ldx #7
@pg:    lda dist_sk,x                   ; page = (std * 5 + kind) of psgtab_lo
        clc
        adc tmp
        sta page_lo,x
        adc #10                         ; psgtab_hi follows, 10 pages later
        sta page_hi,x
        dex
        bpl @pg
        lda #$FF
        sta pan_mode                    ; pan table not built
        ldx #NCH-1
@c:     sta fk_dist,x                   ; no cached word
        dex
        bpl @c
        jmp psg_silence

; ----------------------------------------------------------------------------
; CHAN n - voice n from POKEY channel n, 4 bytes to DATA0
; ----------------------------------------------------------------------------
.macro  CHAN CH
        .local sil, zero, full, have, nz, lo, hi, done
.if CH < 4
        lda _psg_hybrid                 ; hybrid: POKEY plays channels 1-4
        bne sil
.endif
        lda trackn_audc+CH
        tay
        and #$1F
        tax
        lda audc_lvl,x
        beq sil                         ; volume 0 or volume only
        sta lvl
        tya
        lsr a
        lsr a
        lsr a
        lsr a
        lsr a
        tax                             ; X = distortion
        lda dist_wpw,x
        sta wpw
.if CH < 4
        lda v_audctl
.else
        lda v_audctl2
.endif
        ; AUDCTL bits that take the channel out of the table: 15 kHz,
        ; 16 bit, 1.79 MHz
.if (CH & 3) = 0
        and #$51
.elseif (CH & 3) = 1
        and #$11
.elseif (CH & 3) = 2
        and #$29
.else
        and #$09
.endif
        bne full
        lda page_lo,x                   ; 64 kHz 8 bit: word from psgtab
        sta lo+2
        lda page_hi,x
        sta hi+2
        ldy trackn_audf+CH
lo:     lda psgtab_lo,y
hi:     ldx psgtab_hi,y                 ; Z: high byte 0
have:   PUTA                            ; frequency word
        PUTX
        bne nz
        cmp #0
        beq zero                        ; word 0: silent
nz:     lda lvl
        sta _psg_volume+CH
        ora pan+CH
        PUTA                            ; pan | volume
        lda wpw
        PUTA                            ; waveform | pulse width
        jmp done
full:   ldx #CH
        jsr full_word
        bcs sil
        cpx #0
        jmp have
sil:    lda #0
        PUTA
        PUTA
zero:   PUTA                            ; A = 0
        PUTA
        sta _psg_volume+CH
done:
.endmacro

; ----------------------------------------------------------------------------
; psg_update - called once per frame from the VBI, after the player
; ----------------------------------------------------------------------------
psg_update:
        cld
        lda wbusy                       ; foreground VERA write running:
        bne upd_rts                     ; skip this frame
        lda _psg_enable
        bne upd_on
        lda psg_on                      ; switched off since last frame:
        beq upd_rts                     ; silence once
        jmp psg_silence
upd_rts:
        rts
upd_on: lda #1
        sta psg_on
        lda _psg_stereo
        cmp pan_mode
        beq @pan
        jsr set_pan
@pan:   jsr vera_begin
.repeat NCH, I
        CHAN I
.endrepeat
        jmp vera_end

; set_pan - A = _psg_stereo: pan bits of every voice
set_pan:
        sta pan_mode
        ldx #NCH-1
@p:     lda #PAN_LR
        ldy pan_mode
        beq @m
        lda pan_stereo,x
@m:     sta pan,x
        dex
        bpl @p
        rts

; ----------------------------------------------------------------------------
; void psg_silence(void) - all voices at volume 0 (also from the foreground)
; ----------------------------------------------------------------------------
psg_silence:
        lda #0
        sta psg_on
        ldx #NCH-1
@v:     sta _psg_volume,x
        dex
        bpl @v
        jsr vera_begin
        lda #0
        ldx #4*NCH
@w:     PUTA
        dex
        bne @w
        ; fall through

; ----------------------------------------------------------------------------
; vera_end - restore the VERA state saved by vera_begin
; ----------------------------------------------------------------------------
vera_end:
        lda save_l                      ; restoring the address also
        sta VERA_ADDR_L                 ; refreshes the DATA0 prefetch
        lda save_m
        sta VERA_ADDR_M
        lda save_h
        sta VERA_ADDR_H
        lda #VERA_DCSEL2
        sta VERA_CTRL
        lda save_fx
        sta VERA_FX_CTRL
        lda save_ctrl
        sta VERA_CTRL
        dec wbusy
        rts

; ----------------------------------------------------------------------------
; vera_begin - save the VERA state, DATA0 on PSG voice 0, increment 1
; ----------------------------------------------------------------------------
vera_begin:
        inc wbusy
        lda VERA_CTRL
        sta save_ctrl
        lda #VERA_DCSEL2
        sta VERA_CTRL
        lda VERA_FX_CTRL                ; cache/transparent writes would
        sta save_fx                     ; change what DATA0 stores
        lda #0
        sta VERA_FX_CTRL
        sta VERA_CTRL                   ; ADDRSEL 0, DCSEL 0
        lda VERA_ADDR_L
        sta save_l
        lda VERA_ADDR_M
        sta save_m
        lda VERA_ADDR_H
        sta save_h
        lda #<PSG_ADDR
        sta VERA_ADDR_L
        lda #>PSG_ADDR
        sta VERA_ADDR_M
        lda #(VERA_INC1 | ^PSG_ADDR)
        sta VERA_ADDR_H
        rts

; ----------------------------------------------------------------------------
; full_word - X = channel in a 1.79 MHz, 15 kHz or 16 bit mode.
; Returns C = 1: silent; C = 0: A = word low, X = word high.
; The word of the last call is reused while AUDF, the AUDF of the paired
; channel, AUDCTL and the distortion are the same.
; ----------------------------------------------------------------------------
full_word:
        stx ch
        lda trackn_audc,x
        lsr a
        lsr a
        lsr a
        lsr a
        lsr a
        sta dist
        lda v_audctl
.if NCH > 4
        cpx #4
        bcc @lp
        lda v_audctl2                   ; right POKEY
@lp:
.endif
        sta actl
        txa
        eor #1
        tay
        lda trackn_audf,y
        sta tmp                         ; AUDF of the paired channel
        lda trackn_audf,x
        cmp fk_f0,x
        bne @miss
        lda tmp
        cmp fk_f1,x
        bne @miss
        lda actl
        cmp fk_ctl,x
        bne @miss
        lda dist
        cmp fk_dist,x
        bne @miss
@hit:   lda fk_sil,x
        lsr a                           ; C = silent
        lda fw_lo,x
        pha
        lda fw_hi,x
        tax
        pla
        rts

@miss:  lda trackn_audf,x
        sta fk_f0,x
        lda tmp
        sta fk_f1,x
        lda actl
        sta fk_ctl,x
        lda dist
        sta fk_dist,x
        jsr calc_word
        ldx ch
        lda #0
        rol a
        sta fk_sil,x
        lda dvd
        sta fw_lo,x
        lda dvd+1
        sta fw_hi,x
        jmp @hit

; ----------------------------------------------------------------------------
; calc_word - X = channel (actl, dist set): divider, constant, word.
; Returns C = 1: silent; C = 0: word in dvd, dvd+1
; ----------------------------------------------------------------------------
calc_word:
        txa
        and #$03
        sta cx
        txa
        and #$04
        sta abase
        lda #0
        sta dvd+1
        sta dvd+2
        sta fast
        lda trackn_audf,x
        sta dvd
        ldy abase                       ; Y = AUDF1 of this POKEY
        lda cx
        bne @n1
        lda actl                        ; channel 1: low byte of 1+2?
        and #$10
        beq @f1
        sec
        rts
@f1:    lda actl
        and #$40
        sta fast
        jmp @div
@n1:    cmp #1
        bne @n2
        lda actl                        ; channel 2: 16 bit 1+2
        and #$10
        beq @div
        lda trackn_audf+0,y
        sta dvd
        lda trackn_audf+1,y
        sta dvd+1
        lda actl
        and #$40
        sta fast
        jmp @div16
@n2:    cmp #2
        bne @n3
        lda actl                        ; channel 3: low byte of 3+4?
        and #$08
        beq @f3
        sec
        rts
@f3:    lda actl
        and #$20
        sta fast
        jmp @div
@n3:    lda actl                        ; channel 4: 16 bit 3+4
        and #$08
        beq @div
        lda trackn_audf+2,y
        sta dvd
        lda trackn_audf+3,y
        sta dvd+1
        lda actl
        and #$20
        sta fast
@div16: lda fast
        beq @base
        lda #7                          ; 16 bit at 1.79 MHz: v + 7 cycles
        bne @addc
@div:   lda fast
        beq @base
        lda #4                          ; 8 bit at 1.79 MHz: v + 4 cycles
@addc:  clc
        adc dvd
        sta n0
        lda dvd+1
        adc #0
        sta n1
        lda #0
        adc #0
        sta n2
        jmp @sound
@base:  inc dvd                         ; (v + 1) * 28 or * 114
        bne @nc
        inc dvd+1
        bne @nc
        inc dvd+2
@nc:    lda actl
        and #$01
        beq @b64
        lda #114
        .byte $2C                       ; BIT abs: skip the next LDA
@b64:   lda #28
        sta base
        lda #0
        sta n0
        sta n1
        sta n2
        ldy #8
@mul:   lsr base
        bcc @nadd
        clc
        lda n0
        adc dvd
        sta n0
        lda n1
        adc dvd+1
        sta n1
        lda n2
        adc dvd+2
        sta n2
@nadd:  asl dvd
        rol dvd+1
        rol dvd+2
        dey
        bne @mul

@sound: ldy dist
        lda dist_k,y
        bpl @k
        ; distortion C: the period depends on n mod 15 (nibble sum, 16 = 1)
        lda n0
        and #$0F
        sta tmp
        lda n0
        lsr a
        lsr a
        lsr a
        lsr a
        clc
        adc tmp
        sta tmp
        lda n1
        and #$0F
        adc tmp
        sta tmp
        lda n1
        lsr a
        lsr a
        lsr a
        lsr a
        adc tmp
        sta tmp
        lda n2
        and #$0F
        adc tmp
        sta tmp
        lda n2
        lsr a
        lsr a
        lsr a
        lsr a
        adc tmp
@m15:   cmp #15
        bcc @r15
        sbc #15
        bcs @m15
@r15:   tay
        lda distc_k,y
        bpl @k
        sec                             ; n multiple of 15: no sound
        rts

@k:     sta tmp                         ; word = psg_ktab[k] / n
        asl a
        adc tmp                         ; 3 * k
        adc kofs
        tay
        lda psg_ktab,y
        sta dvd
        lda psg_ktab+1,y
        sta dvd+1
        lda psg_ktab+2,y
        sta dvd+2
        lda n0
        sta dsr
        lda n1
        sta dsr+1
        lda n2
        sta dsr+2
        jsr div24
        lda dvd+2
        beq @fit
        lda #$FF                        ; above the PSG range (> ~24 kHz)
        sta dvd
        sta dvd+1
@fit:   clc
        rts

; ----------------------------------------------------------------------------
; div24 - dvd (24 bit) / dsr (24 bit) -> dvd quotient, rem remainder
; ----------------------------------------------------------------------------
div24:
        lda #0
        sta rem
        sta rem+1
        sta rem+2
        ldx #24
@l:     asl dvd
        rol dvd+1
        rol dvd+2
        rol rem
        rol rem+1
        rol rem+2
        lda rem
        sec
        sbc dsr
        tay
        lda rem+1
        sbc dsr+1
        sta tmp
        lda rem+2
        sbc dsr+2
        bcc @n
        sta rem+2
        lda tmp
        sta rem+1
        sty rem
        inc dvd
@n:     dex
        bne @l
        rts
