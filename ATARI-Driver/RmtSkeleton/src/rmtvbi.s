;
; RMT player driven by the IMMEDIATE vertical blank interrupt (VVBLKI)
;
; Why immediate and not deferred: during every SIO operation the OS sets
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
VCOUNT  = $D40B
AUDC3   = $D205
AUDC4   = $D207

        .segment "BSS"
_rmt_frames:    .res 2          ; frame counter incremented by the VBI
_rmt_lines:     .res 1          ; last player duration (scanlines)
_rmt_maxlines:  .res 1          ; worst player duration (scanlines)
oldvbi:         .res 2
busy:           .res 1
vstart:         .res 1
vbion:          .res 1
pending:        .res 1          ; player ticks postponed (VBI inside an IRQ)
_rmt_deferred:  .res 2          ; statistics: how many ticks were postponed
_rmt_dropped:   .res 2          ; statistics: ticks lost (tempo error)

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
        ldx #0
        rts

; void rmt_vbi_on(void)
_rmt_vbi_on:
        lda vbion
        bne @done
        lda #0
        sta busy
        sta pending
        sta _rmt_maxlines
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
        lda #0
        sta vbion
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
        jsr rmt_play
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
        inc busy
        lda VCOUNT
        sta vstart
        cli                     ; let SIO serial IRQs in while we play
        jsr rmt_play
        lda pending             ; catch up one postponed tick
        beq @nocatch
        dec pending
        jsr rmt_play
@nocatch:
        sei
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
@nomax:
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
