;
; RMT player driven by the vertical blank interrupt: the immediate one (VVBLKI),
; the deferred one (VVBLKD) when the OS runs stage 2 (see below)
;
; Why the immediate VBI too: during every SIO operation the OS sets
; CRITIC ($42) and in that case the deferred VBI (VVBLKD) is skipped. The
; immediate VBI always runs, so the music keeps playing while loading.
;
; The OS NMI handler has already pushed A, X, Y; the handler must exit with
; JMP SYSVBV so the OS stage 1 (RTCLOK, CDTMV1 used by SIO timeouts...) and,
; when allowed, stage 2 still run.
;
; The player can take a good part of a frame. While it runs we re-enable
; IRQs (CLI): the SIO receive/transmit is IRQ driven (VSERIN/VSEROR/VSEROC)
; and a byte arrives every ~930 CPU cycles at 19200 baud. Keeping IRQs
; masked for the whole player time would overrun the serial port.
;
; BUT the CLI is allowed only if the interrupted code had IRQs enabled
; (I flag of the P register stacked by the NMI). If the VBI hit inside an
; IRQ handler (e.g. the SIO serial input one, before it acknowledged IRQST)
; a CLI would re-enter it: bytes stored twice, corrupted sectors. In that
; case the player tick is postponed: it is executed at the end of the
; next SIO serial input IRQ (rmt_irqtick, a few microseconds later, when
; the IRQ work is done and CLI is safe) or at the next VBI (two calls in
; the same frame), so the song tempo is unchanged.
;
; Instrument speed N > 1: every frame the player is called N times, back to
; back (play_tick). The player counts the calls itself: the song advances once
; every N calls, the other calls only step the instruments, so tempo and
; instrument speed are right; the sound still changes once per frame (the
; tracker spreads the calls over the frame). A postponed tick stands for N
; calls too.
;
; Where the player runs: the OS stage 2 VBI copies the shadow registers to
; the hardware (SDLSTL to DLISTL, the colours...) after the immediate VBI. A
; player that ran first in the immediate VBI and took most of the vertical
; blank (instrument speed 4: up to 66 lines, the blank is about 72 lines on
; PAL) pushed that copy past the start of the display list, and ANTIC,
; given DLISTL again in the middle of it, started the display list over: a
; jumping screen. So when the OS will run stage 2 (CRITIC = 0 and the
; interrupted code had IRQs enabled, the OS's own test) the immediate VBI only
; asks for a tick and the deferred VBI (VVBLKD, after the shadow copy) plays
; it, as the XEX with the RMT player of RITMO does: a long player then only
; takes time from the program. When the OS skips stage 2 (CRITIC set during
; SIO, or a VBI inside an IRQ) there is no shadow copy in that frame and the
; player runs in the immediate VBI (or is postponed) as before, so the music
; goes on while loading.
;
; Stack at VBI entry: $101,X = Y  $102,X = X  $103,X = A  $104,X = P
;
; C interface (see rmt.h)
;
        .export _rmt_init, _rmt_vbi_on, _rmt_vbi_off
        .export _rmt_io_begin, _rmt_io_end
        .export _rmt_frames, _rmt_lines, _rmt_maxlines, _rmt_deferred, _rmt_dropped

        .export rmt_irqtick
        .import rmt_init, rmt_play, rmt_silence
        .import rmt_ioactive

SETVBV  = $E45C
SYSVBV  = $E45F
VVBLKI  = $0222
VVBLKD  = $0224
CRITIC  = $42                   ; <> 0: the OS skips stage 2 (SIO running)
VCOUNT  = $D40B
AUDC3   = $D205
AUDC4   = $D207

        .segment "BSS"
_rmt_frames:    .res 2          ; frame counter incremented by the VBI
_rmt_lines:     .res 1          ; last player duration (scanlines)
_rmt_maxlines:  .res 1          ; worst player duration (scanlines)
oldvbi:         .res 2
oldvbd:         .res 2          ; deferred VBI vector before rmt_vbi_on
dtick:          .res 1          ; ticks the deferred VBI has to play
busy:           .res 1
vstart:         .res 1
vbion:          .res 1
pending:        .res 1          ; player ticks postponed (VBI inside an IRQ)
_rmt_deferred:  .res 2          ; statistics: how many ticks were postponed
_rmt_dropped:   .res 2          ; statistics: ticks lost (tempo error)
ispeed:         .res 1          ; player calls per frame = instrument speed (1..4)
ticks:          .res 1          ; calls left in the current play_tick

        .segment "CODE"

; unsigned char __fastcall__ rmt_init(const void* module)
; returns the module instrument speed (1 = once per frame)
_rmt_init:
        pha                     ; X = lo, Y = hi for the player
        txa
        tay
        pla
        tax
        lda #0                  ; start from song line 0
        jsr rmt_init
        pha                     ; A = instrument speed of the module
        cmp #1                  ; clamp to 1..4 (RMT format range)
        bcs @lo
        lda #1
@lo:    cmp #5
        bcc @hi
        lda #4
@hi:    sta ispeed
        pla
        ldx #0
        rts

; void rmt_vbi_on(void)
_rmt_vbi_on:
        lda vbion
        bne @done
        lda #0
        sta busy
        sta pending
        sta dtick
        sta _rmt_maxlines
        lda VVBLKD
        sta oldvbd
        lda VVBLKD+1
        sta oldvbd+1
        ldy #<dvbi
        ldx #>dvbi
        lda #7                  ; 7 = deferred VBI vector
        jsr SETVBV
        lda VVBLKI
        sta oldvbi
        lda VVBLKI+1
        sta oldvbi+1
        ldy #<vbi
        ldx #>vbi
        lda #6                  ; 6 = immediate VBI vector
        jsr SETVBV
        inc vbion
@done:  rts

; void rmt_vbi_off(void)
_rmt_vbi_off:
        lda vbion
        beq @done
        ldy oldvbi
        ldx oldvbi+1
        lda #6
        jsr SETVBV
        ldy oldvbd
        ldx oldvbd+1
        lda #7
        jsr SETVBV
        lda #0
        sta vbion
        sta dtick
        jsr rmt_silence
@done:  rts

; void rmt_io_begin(void)
; From now on the player leaves POKEY channels 3/4 and AUDCTL to the SIO.
; Channels 3/4 are muted right away, otherwise the last music volume would
; stay set while SIO reprograms AUDF3/AUDF4 as baud rate: an audible whine.
_rmt_io_begin:
        lda #1
        sta rmt_ioactive
        lda #0
        sta AUDC3
        sta AUDC4
        rts

; void rmt_io_end(void)
; Next VBI rewrites all 4 channels and AUDCTL.
_rmt_io_end:
        lda #0
        sta rmt_ioactive
        rts

; ---------------------------------------------------------------------------
; play_tick: one frame of music = ispeed calls of rmt_play, back to back
play_tick:
        lda ispeed
        bne @n
        lda #1                  ; not initialised yet: one call
@n:     sta ticks
@l:     jsr rmt_play
        dec ticks
        bne @l
        rts

; ---------------------------------------------------------------------------
; rmt_irqtick: run a postponed player tick from the tail of an IRQ handler.
; Call with I=1 once the IRQ has been fully served. Preserves X and Y.
rmt_irqtick:
        lda pending
        beq @none
        lda busy
        bne @none
        inc busy
        dec pending
        txa
        pha
        tya
        pha
        cli                     ; the IRQ is done: nesting is safe now
        jsr play_tick
        sei
        pla
        tay
        pla
        tax
        lda #0
        sta busy
@none:  rts

; ---------------------------------------------------------------------------
; Immediate VBI handler
; ---------------------------------------------------------------------------
vbi:
        inc _rmt_frames
        bne @nohi
        inc _rmt_frames+1
@nohi:
        tsx
        lda $0104,x             ; P of the interrupted code
        and #$04                ; I flag set: we are inside an IRQ handler
        bne @defer              ; or a SEI section, no CLI allowed
        lda busy                ; previous player call still running
        bne @defer              ; (can only happen with IRQs enabled)
        lda CRITIC              ; the OS will run stage 2 (I flag clear,
        bne @now                ; CRITIC = 0): the deferred VBI plays,
        inc dtick               ; after the shadow registers are copied
        jmp SYSVBV
@now:   inc busy                ; no stage 2 in this frame: play here
        cli                     ; let SIO serial IRQs in while we play
        jsr play_ticks
        sei
        lda #0
        sta busy
        jmp SYSVBV
@defer:
        inc _rmt_deferred
        bne @nohi2
        inc _rmt_deferred+1
@nohi2:
        lda pending
        cmp #4                  ; do not accumulate forever
        bcc @keep
        inc _rmt_dropped
        bne @exit
        inc _rmt_dropped+1
        jmp SYSVBV
@keep:  inc pending
@exit:
        jmp SYSVBV

; ---------------------------------------------------------------------------
; Deferred VBI handler: the tick the immediate VBI left (OS stage 2, IRQs
; enabled, the shadow registers already copied)
; ---------------------------------------------------------------------------
dvbi:
        lda dtick
        beq @exit
        lda #0
        sta dtick
        sei
        lda busy                ; rmt_irqtick is playing (an IRQ between
        beq @play               ; the two VBI stages): one tick more later
        lda pending
        cmp #4
        bcs @lost
        inc pending
        cli
        jmp @exit
@lost:  inc _rmt_dropped
        bne @lo
        inc _rmt_dropped+1
@lo:    cli
        jmp @exit
@play:  inc busy
        cli
        jsr play_ticks
        lda #0
        sta busy
@exit:  jmp (oldvbd)            ; XITVBV, or what was there before

; one frame of music and one postponed tick if any, with the player time in
; _rmt_lines / _rmt_maxlines
play_ticks:
        lda VCOUNT
        sta vstart
        jsr play_tick
        lda pending             ; catch up one postponed tick
        beq @nocatch
        dec pending
        jsr play_tick
@nocatch:
        lda VCOUNT
        sec
        sbc vstart
        bcs @nowrap             ; VCOUNT wrapped around the frame end
        adc #156                ; (PAL value, only a diagnostic)
@nowrap:
        asl a                   ; VCOUNT counts line pairs
        sta _rmt_lines
        cmp _rmt_maxlines
        bcc @nomax
        sta _rmt_maxlines
@nomax: rts
