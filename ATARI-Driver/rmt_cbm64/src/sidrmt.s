; sidrmt.s - RMT player on the Commodore 64: raster IRQ + POKEY -> SID
;
; The music is played by the Atari RMT player routine (rmtplayr.s, the same
; source as PokeyATest and RmtSkeleton, assembled with -D RMT_C64): it writes
; the POKEY registers to pokey_shadow instead of $D200. Once per frame, from
; a raster IRQ chained to the KERNAL IRQ vector ($0314), this code calls the
; player and turns the shadow registers into SID registers:
;
;   frequency  from AUDF, AUDCTL (64/15 kHz, 1.79 MHz, 16 bit) and the
;              distortion: SID Fn = K / n, n = POKEY divider in machine
;              cycles, K = constant of the sound (table ktab, PAL / NTSC).
;              64 kHz 8 bit channels, the usual case, read Fn from sidtab
;              (tools/mksidtab.py, scaled once for NTSC); the other modes
;              divide, only when the divider changes
;   waveform   pure tone ($A0) -> pulse 50%; distortion C ($C0, poly4) and
;              poly5 tones -> pulse 25%; poly17/poly5 noise -> SID noise
;   volume     SID has no volume per voice: the sustain level of the
;              envelope (attack 0, decay 0) is the POKEY volume; a louder
;              step restarts the envelope (gate off/on)
;   channels   SID has 3 voices: POKEY 1 -> voice 1, 2 -> voice 2, the
;              louder of 3 and 4 -> voice 3 (with 1+2 joined: 3, 2, 4)
;
; Not reproduced: volume only mode (AUDC bit 4, sample playback) and the
; high pass filters (AUDCTL bits 2, 1).

        .export _sid_init, _sid_play_on, _sid_play_off
        .export _sid_frames, _sid_status, _sid_volume, _sid_ntsc
        .export pokey_shadow
        ; state shown by src/rmtplay.c
        .export _sid_mute, _sid_src
        .export _sid_pokey := pokey_shadow
        .export _sid_freq_lo := v_flo, _sid_freq_hi := v_fhi, _sid_wave := v_wave
        .import RASTERMUSICTRACKER
        .import __RMTZPMEM_START__, __RMTZPMEM_SIZE__
        .import sidtab_lo, sidtab_hi

        .constructor rmtzp_save
        .destructor rmtzp_restore

rmt_init    = RASTERMUSICTRACKER+0      ; X/Y = module, A = song line
rmt_play    = RASTERMUSICTRACKER+3
rmt_silence = RASTERMUSICTRACKER+9

SID         = $D400
SID_VOLUME  = $D418
VIC_CTRL1   = $D011
VIC_RASTER  = $D012
VIC_IRQ     = $D019
VIC_IRQMASK = $D01A
CINV        = $0314                     ; KERNAL IRQ vector
IRQ_EXIT    = $EA81                     ; KERNAL: pull Y/X/A, RTI

WAVE_PULSE  = $40
WAVE_NOISE  = $80
GATE        = $01

        .segment "BSS"

pokey_shadow:   .res 16         ; AUDF1 AUDC1 ... AUDF4 AUDC4 AUDCTL, SKCTL at +15
_sid_frames:    .res 2          ; frames played
_sid_status:    .res 1          ; 1 = playing
_sid_volume:    .res 3          ; volume of the 3 SID voices (0..15)
_sid_ntsc:      .res 1          ; 1 = NTSC machine (60 Hz), 0 = PAL
_sid_mute:      .res 1          ; bit 0..2 set: SID voice 1..3 kept silent
_sid_src:       .res 3          ; POKEY channel (0..3) of each SID voice

old_irq:        .res 2
ktab_ofs:       .res 1          ; 0 = PAL constants, 21 = NTSC
tab_ntsc:       .res 1          ; 1 = sidtab already scaled for NTSC

; per POKEY channel, computed every frame
c_vol:          .res 4
c_wave:         .res 4          ; WAVE_PULSE / WAVE_NOISE
c_pw:           .res 4          ; pulse width high nibble ($08 = 50%, $04 = 25%)
c_k:            .res 4          ; index in ktab
c_simple:       .res 4          ; 1 = 64 kHz 8 bit: Fn from sidtab
c_audf:         .res 4
c_sk:           .res 4          ; sidtab kind 0..4
c_n0:           .res 4          ; divider in machine cycles (24 bit)
c_n1:           .res 4
c_n2:           .res 4

; per SID voice
v_level:        .res 3          ; level the SID envelope is at (0..15)
v_wave:         .res 3
v_key0:         .res 3          ; divider and constant of the last frequency
v_key1:         .res 3
v_key2:         .res 3
v_keyk:         .res 3
v_flo:          .res 3
v_fhi:          .res 3

; scratch
ch:             .res 1
voice:          .res 1
src:            .res 1
base:           .res 1
dvd:            .res 3          ; dividend / quotient
dsr:            .res 3          ; divisor
rem:            .res 3
tmp:            .res 1

        .segment "DATA"

; what RMTZP held before the program started; not in BSS: cc65 clears the
; BSS after running the constructors (they live in the same area)
zp_saved:       .res 32

        .segment "RODATA"

; K = POKEY clock * 2^24 / C64 clock / m, 24 bit:
;   PAL  POKEY 1773447 Hz, C64 985248 Hz; NTSC POKEY 1789790 Hz, C64 1022727 Hz
;   m:  0 pure tone /2, 1 distortion C /3, 2 /5, 3 /15 (period of poly4 at
;       that divider), 4 poly5 tone /31, 5 poly17 noise /16 (SID noise shifts
;       at 16 x the oscillator frequency), 6 poly5 noise /32
ktab:
        .faraddr 15099500, 10066333, 6039800, 2013267, 974161, 1887437, 943719
        .faraddr 14680210,  9786806, 5872084, 1957361, 947110, 1835026, 917513

; n mod 15 -> constant index for distortion C, $FF = no pulses change (silent)
distc_k:
        .byte $FF, 3, 3, 2, 3, 1, 2, 3, 3, 2, 1, 3, 2, 3, 3

sid_ofs:
        .byte 0, 7, 14
voice_bit:
        .byte $01, $02, $04

        .segment "CODE"

; ---------------------------------------------------------------------------
; The player's zero page (RMTZP, BASIC work area) is saved at start-up and
; given back at exit, so BASIC finds its pointers again.
rmtzp_save:
        ldx #<(__RMTZPMEM_SIZE__ - 1)
@l:     lda __RMTZPMEM_START__,x
        sta zp_saved,x
        dex
        bpl @l
        rts

rmtzp_restore:
        jsr _sid_play_off
        ldx #<(__RMTZPMEM_SIZE__ - 1)
@l:     lda zp_saved,x
        sta __RMTZPMEM_START__,x
        dex
        bpl @l
        rts

; ---------------------------------------------------------------------------
; void __fastcall__ sid_init(const void *module)
; Only while the player is stopped.
_sid_init:
        pha
        txa
        tay                             ; Y = module hi
        pla
        tax                             ; X = module lo
        tya
        pha
        txa
        pha
        jsr detect_video
        jsr ntsc_table
        jsr sid_clear
        pla
        tax
        pla
        tay
        lda #0                          ; start from song line 0
        jmp rmt_init

; PAL / NTSC from the number of raster lines (codebase64): the low byte of
; the last line is $37 on PAL (312 lines), $05/$06 on NTSC (262/263 lines)
detect_video:
        php
        sei
@l1:    lda VIC_RASTER
@l2:    cmp VIC_RASTER
        beq @l2
        bmi @l1
        plp
        ldx #0
        cmp #$20
        bcs @pal
        inx
@pal:   stx _sid_ntsc
        lda #0
        cpx #0
        beq @k
        lda #21
@k:     sta ktab_ofs
        rts

; NTSC: sidtab (PAL values) x (1 - 7/256) = x 0.9727, once
; (exact ratio 0.97223: POKEY 1789790 / 1773447, C64 985248 / 1022727)
ntsc_table:
        lda _sid_ntsc
        beq @no
        lda tab_ntsc
        beq @go
@no:    rts
@go:    inc tab_ntsc
        lda #>sidtab_lo
        sta @rl+2
        sta @wl+2
        lda #>sidtab_hi
        sta @rh+2
        sta @wh+2
        ldx #5                          ; 5 pages
@page:  ldy #0
@l:
@rl:    lda sidtab_lo,y                 ; dvd = Fn * 7 = Fn * 8 - Fn (24 bit)
        sta rem
@rh:    lda sidtab_hi,y
        sta rem+1
        lda rem
        asl a
        sta dvd
        lda rem+1
        rol a
        sta dvd+1
        lda #0
        rol a
        sta dvd+2
        asl dvd
        rol dvd+1
        rol dvd+2
        asl dvd
        rol dvd+1
        rol dvd+2
        sec
        lda dvd
        sbc rem
        lda dvd+1
        sbc rem+1
        sta dvd+1
        lda dvd+2
        sbc #0
        sta dvd+2
        sec                             ; Fn - (Fn * 7) / 256
        lda rem
        sbc dvd+1
@wl:    sta sidtab_lo,y
        lda rem+1
        sbc dvd+2
@wh:    sta sidtab_hi,y
        iny
        bne @l
        inc @rl+2
        inc @wl+2
        inc @rh+2
        inc @wh+2
        dex
        bne @page
        rts

; SID registers to 0, envelopes closed, volume 15; voice state reset
sid_clear:
        lda #0
        ldx #$17
@l:     sta SID,x
        dex
        bpl @l
        lda #$0F
        sta SID_VOLUME
        ldx #2
@v:     lda #0
        sta v_level,x
        sta v_wave,x
        sta _sid_volume,x
        lda #$FF
        sta v_keyk,x
        dex
        bpl @v
        rts

; ---------------------------------------------------------------------------
; void sid_play_on(void): raster IRQ at line 0, chained to the KERNAL one
_sid_play_on:
        php
        sei
        lda _sid_status
        bne @done
        lda CINV
        sta old_irq
        lda CINV+1
        sta old_irq+1
        lda #<irq
        sta CINV
        lda #>irq
        sta CINV+1
        lda #0
        sta VIC_RASTER
        sta _sid_frames
        sta _sid_frames+1
        lda VIC_CTRL1
        and #$7F                        ; raster line bit 8 = 0
        sta VIC_CTRL1
        lda #$01
        sta VIC_IRQ                     ; clear a pending raster IRQ
        sta VIC_IRQMASK                 ; enable the raster IRQ
        sta _sid_status
@done:  plp
        rts

; void sid_play_off(void): IRQ removed, POKEY and SID silent
_sid_play_off:
        php
        sei
        lda _sid_status
        beq @done
        lda #0
        sta VIC_IRQMASK
        sta _sid_status
        lda #$01
        sta VIC_IRQ
        lda old_irq
        sta CINV
        lda old_irq+1
        sta CINV+1
        jsr rmt_silence
        jsr sid_clear
        lda #0
        sta SID_VOLUME
@done:  plp
        rts

; KERNAL IRQ entry has pushed A, X, Y
irq:
        lda VIC_IRQ
        and #$01
        beq @kernal
        sta VIC_IRQ                     ; acknowledge the raster IRQ
        jsr rmt_play                    ; writes pokey_shadow, computes next frame
        jsr pokey_to_sid
        inc _sid_frames
        bne @x
        inc _sid_frames+1
@x:     jmp IRQ_EXIT
@kernal:
        jmp (old_irq)                   ; CIA timer: keyboard, clock

; ---------------------------------------------------------------------------
; POKEY shadow registers -> SID
pokey_to_sid:
        lda #0
        sta ch
@c:     jsr channel
        inc ch
        lda ch
        cmp #4
        bne @c

        ; voice 1 <- POKEY 1 (3 when 1+2 are joined), voice 2 <- 2,
        ; voice 3 <- the louder of 3 and 4 (4 when 1+2 are joined)
        lda pokey_shadow+8
        and #$10
        beq @nj
        lda #2
        ldx #0
        jsr voice_out
        lda #1
        ldx #1
        jsr voice_out
        lda #3
        ldx #2
        jmp voice_out
@nj:    lda #0
        ldx #0
        jsr voice_out
        lda #1
        ldx #1
        jsr voice_out
        lda c_vol+3
        cmp c_vol+2
        beq @three
        bcs @four
@three: lda #2
        .byte $2C                       ; BIT abs: skip the next LDA
@four:  lda #3
        ldx #2
        jmp voice_out

; channel ch: volume, waveform, constant, divider (in machine cycles)
channel:
        lda ch
        asl a
        tay                             ; Y = 2*ch: AUDF at shadow+Y
        ldx ch
        lda pokey_shadow+1,y            ; AUDC
        and #$0F
        sta c_vol,x
        lda pokey_shadow+1,y
        and #$10                        ; volume only: not reproduced
        beq @nvo
        lda #0
        sta c_vol,x
@nvo:
        ; 64 kHz clock, not joined, not 1.79 MHz: Fn from sidtab
        lda pokey_shadow+8
        and simple_mask,x
        bne @full
        lda #1
        sta c_simple,x
        lda pokey_shadow,y
        sta c_audf,x
        lda pokey_shadow+1,y
        lsr a
        lsr a
        lsr a
        lsr a
        lsr a
        tay
        lda dist_wave,y
        sta c_wave,x
        lda dist_pw,y
        sta c_pw,x
        lda dist_sk,y
        sta c_sk,x
        rts
@full:  lda #0
        sta c_simple,x
        ; divider: v = AUDF (or the 16 bit pair), fast = 1.79 MHz clock
        lda #0
        sta dvd+1
        sta dvd+2
        sta tmp                         ; tmp = 1.79 MHz clock
        lda pokey_shadow,y
        sta dvd
        lda pokey_shadow+8              ; AUDCTL
        cpx #0
        bne @n1
        and #$10                        ; channel 1: low byte of 1+2?
        beq @f1
        lda #0
        sta c_vol,x
        rts
@f1:    lda pokey_shadow+8
        and #$40
        sta tmp
        jmp @div
@n1:    cpx #1
        bne @n2
        and #$10                        ; channel 2: 16 bit 1+2
        beq @div
        lda pokey_shadow+0
        sta dvd
        lda pokey_shadow+2
        sta dvd+1
        lda pokey_shadow+8
        and #$40
        sta tmp
        jmp @div16
@n2:    cpx #2
        bne @n3
        and #$08                        ; channel 3: low byte of 3+4?
        beq @f3
        lda #0
        sta c_vol,x
        rts
@f3:    lda pokey_shadow+8
        and #$20
        sta tmp
        jmp @div
@n3:    and #$08                        ; channel 4: 16 bit 3+4
        beq @div
        lda pokey_shadow+4
        sta dvd
        lda pokey_shadow+6
        sta dvd+1
        lda pokey_shadow+8
        and #$20
        sta tmp
@div16: lda tmp
        beq @base
        lda #7                          ; 16 bit at 1.79 MHz: v + 7 cycles
        bne @addc
@div:   lda tmp
        beq @base
        lda #4                          ; 8 bit at 1.79 MHz: v + 4 cycles
@addc:  clc
        adc dvd
        sta c_n0,x
        lda dvd+1
        adc #0
        sta c_n1,x
        lda #0
        adc #0
        sta c_n2,x
        jmp @sound
@base:  inc dvd                         ; (v + 1) * 28 or * 114
        bne @nc
        inc dvd+1
        bne @nc
        inc dvd+2
@nc:    lda pokey_shadow+8
        and #$01
        beq @b64
        lda #114
        .byte $2C
@b64:   lda #28
        sta base
        lda #0
        sta c_n0,x
        sta c_n1,x
        sta c_n2,x
        ldy #8
@mul:   lsr base
        bcc @nadd
        clc
        lda c_n0,x
        adc dvd
        sta c_n0,x
        lda c_n1,x
        adc dvd+1
        sta c_n1,x
        lda c_n2,x
        adc dvd+2
        sta c_n2,x
@nadd:  asl dvd
        rol dvd+1
        rol dvd+2
        dey
        bne @mul

@sound: ; waveform and constant from the distortion (AUDC bits 7..5)
        lda ch
        asl a
        tay
        lda pokey_shadow+1,y
        lsr a
        lsr a
        lsr a
        lsr a
        lsr a
        tay                             ; Y = distortion 0..7
        lda dist_wave,y
        sta c_wave,x
        lda dist_pw,y
        sta c_pw,x
        lda dist_k,y
        bpl @k
        ; distortion C: the period depends on n mod 15 (nibble sum, 16 = 1)
        lda c_n0,x
        and #$0F
        sta tmp
        lda c_n0,x
        lsr a
        lsr a
        lsr a
        lsr a
        clc
        adc tmp
        sta tmp
        lda c_n1,x
        and #$0F
        adc tmp
        sta tmp
        lda c_n1,x
        lsr a
        lsr a
        lsr a
        lsr a
        adc tmp
        sta tmp
        lda c_n2,x
        and #$0F
        adc tmp
        sta tmp
        lda c_n2,x
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
        lda #0                          ; n multiple of 15: no sound
        sta c_vol,x
        lda #3
@k:     sta c_k,x
        rts

; per distortion (AUDC >> 5): 0 poly5+17, 1 poly5 tone, 2 poly5+4, 3 poly5
; tone, 4 poly17, 5 pure, 6 poly4 (distortion C), 7 pure
dist_wave:
        .byte WAVE_NOISE, WAVE_PULSE, WAVE_NOISE, WAVE_PULSE
        .byte WAVE_NOISE, WAVE_PULSE, WAVE_PULSE, WAVE_PULSE
dist_pw:
        .byte $08, $04, $08, $04, $08, $08, $04, $08
dist_k:                                 ; $FF: distortion C, from n mod 15
        .byte 6, 4, 6, 4, 5, 0, $FF, 0
dist_sk:                                ; sidtab kind (tools/mksidtab.py)
        .byte 4, 2, 4, 2, 3, 0, 1, 0
; AUDCTL bits that take a channel out of the table: 15 kHz, 16 bit, 1.79 MHz
simple_mask:
        .byte $51, $11, $29, $09

; SID voice X from POKEY channel A
voice_out:
        stx voice
        sta src
        sta _sid_src,x
        tay                             ; Y = channel
        lda voice_bit,x
        and _sid_mute
        bne @off                        ; voice muted by the program
        lda c_vol,y
        bne @on
        ; silent: sustain 0, the envelope decays to 0 (gate stays on)
@off:   lda sid_ofs,x
        tax
        lda #0
        sta SID+6,x
        ldx voice
        sta v_level,x
        sta _sid_volume,x
        rts

@on:    lda c_simple,y
        beq @slow
        lda c_sk,y                      ; Fn = sidtab[kind * 256 + AUDF]
        clc
        adc #>sidtab_lo
        sta @tl+2
        adc #5
        sta @th+2
        lda c_audf,y
        tay
@tl:    lda sidtab_lo,y
        sta v_flo,x
@th:    lda sidtab_hi,y
        sta v_fhi,x
        lda #$FF
        sta v_keyk,x                    ; the divide cache is no longer valid
        jmp @freq

@slow:  ; frequency, recomputed only when divider or constant change
        lda c_n0,y
        cmp v_key0,x
        bne @calc
        lda c_n1,y
        cmp v_key1,x
        bne @calc
        lda c_n2,y
        cmp v_key2,x
        bne @calc
        lda c_k,y
        cmp v_keyk,x
        beq @freq
@calc:  lda c_n0,y
        sta v_key0,x
        sta dsr
        lda c_n1,y
        sta v_key1,x
        sta dsr+1
        lda c_n2,y
        sta v_key2,x
        sta dsr+2
        lda c_k,y
        sta v_keyk,x
        sta tmp
        asl a
        adc tmp                         ; 3 * k
        adc ktab_ofs
        tay
        lda ktab,y
        sta dvd
        lda ktab+1,y
        sta dvd+1
        lda ktab+2,y
        sta dvd+2
        jsr div24
        ldx voice
        lda dvd+2
        beq @fit
        lda #$FF                        ; above the SID range
        sta dvd
        sta dvd+1
@fit:   lda dvd
        sta v_flo,x
        lda dvd+1
        sta v_fhi,x

@freq:  ldy src
        lda sid_ofs,x
        tax                             ; X = SID register offset
        ldy voice
        lda v_flo,y
        sta SID+0,x
        lda v_fhi,y
        sta SID+1,x
        ldy src
        lda #0
        sta SID+2,x                     ; pulse width low
        lda c_pw,y
        sta SID+3,x
        lda #$00
        sta SID+5,x                     ; attack 0, decay 0
        lda c_vol,y
        asl a
        asl a
        asl a
        asl a
        sta SID+6,x                     ; sustain = volume, release 0

        ; a louder step, a new waveform or a note after silence restarts
        ; the envelope
        ldy src
        lda c_wave,y
        ldy voice
        cmp v_wave,y
        bne @restart
        lda v_level,y
        beq @restart
        ldy src
        lda c_vol,y
        ldy voice
        sec
        sbc v_level,y
        bcc @lower                      ; lower: the envelope decays to it
        cmp #2
        bcs @restart                    ; 2 or more steps louder
        lda v_level,y                   ; 1 step: stays where it is
        bcc @keep
@lower: ldy src
        lda c_vol,y
        ldy voice
@keep:  sta v_level,y
        sta _sid_volume,y
        lda v_wave,y
        ora #GATE
        sta SID+4,x
        rts
@restart:
        ldy src
        lda c_wave,y
        ldy voice
        sta v_wave,y
        sta SID+4,x                     ; gate off
        ora #GATE
        sta SID+4,x                     ; gate on: attack from the current level
        ldy src
        lda c_vol,y
        ldy voice
        sta v_level,y
        sta _sid_volume,y
        rts

; dvd (24 bit) / dsr (24 bit) -> dvd quotient, rem remainder
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
