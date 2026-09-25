;
; Sector read, two implementations:
;
; 1) sio_read_sector: through the OS SIO vector (SIOV)
;
;    WEAK POINT with a music player on VBI: after the "Complete" byte the OS
;    re-arms the receiver (RECEIV) from non-interrupt code. If the VBI runs
;    the player right there, the first data byte arrives while the SERIN IRQ
;    is still disabled and is lost: the sector comes in shifted by one byte
;    (and the OS may even return status 1).
;
; 2) rbl_read_sector: own SIO driver, the whole response (ACK, Complete,
;    128 data bytes, checksum) is received by a state machine inside the
;    VSERIN IRQ handler. No main code in the critical path, so a long VBI
;    (with CLI) cannot break it. The command frame is sent polled with IRQs
;    masked (the VBI sees I=1 and postpones the player tick, see rmtvbi.s).
;    POKEY channels 3/4 are programmed silent: no SIO noise at all.
;
; unsigned char __fastcall__ sio_read_sector(unsigned char unit,
;                                            unsigned sector, void* buf);
; unsigned char __fastcall__ rbl_read_sector(unsigned char unit,
;                                            unsigned sector, void* buf);
; return: 1 = OK, 138 timeout, 139 NAK, 140 serial framing/overrun,
;         143 checksum, 144 device error. 128 bytes sectors only (SD/ED).
;
        .export _sio_read_sector, _rbl_read_sector
        .import popa, popax
        .import rmt_irqtick

SIOV    = $E459
DDEVIC  = $0300
DUNIT   = $0301
DCOMND  = $0302
DSTATS  = $0303
DBUFLO  = $0304
DBUFHI  = $0305
DTIMLO  = $0306
DBYTLO  = $0308
DBYTHI  = $0309
DAUX1   = $030A
DAUX2   = $030B

RTCLOK  = $12
POKMSK  = $10
VSERIN  = $020A
SSKCTL  = $0232

AUDF3   = $D204
AUDC3   = $D205
AUDF4   = $D206
AUDC4   = $D207
AUDCTL  = $D208
SKRES   = $D20A
SEROUT  = $D20D
SERIN   = $D20D
IRQEN   = $D20E
IRQST   = $D20E
SKCTL   = $D20F
SKSTAT  = $D20F
PBCTL   = $D303

BAUD_AUDF3 = $28                ; 19200 baud (OS standard)
TIMEOUT    = 150                ; frames (3 s PAL)

; state machine
ST_ACK   = 0
ST_CPL   = 1
ST_DATA  = 2
ST_CHK   = 3
ST_OK    = 4                    ; >= ST_OK: finished
ST_NAK   = 5
ST_DERR  = 6
ST_CKERR = 7
ST_SERR  = 8

        .segment "ZEROPAGE"
bufp:   .res 2

        .segment "BSS"
cmdframe: .res 5
state:  .res 1
cnt:    .res 1
chk:    .res 1
t0:     .res 1
oldserin: .res 2

        .segment "RODATA"
; DSTATS style result for every final state (ST_OK..ST_SERR)
resulttab: .byte 1, 139, 144, 143, 140

        .segment "CODE"

; ---------------------------------------------------------------------------
_sio_read_sector:
        sta DBUFLO
        stx DBUFHI
        jsr popax               ; sector number
        sta DAUX1
        stx DAUX2
        jsr popa                ; drive unit 1..8
        sta DUNIT
        lda #$31                ; disk drive device
        sta DDEVIC
        lda #'R'
        sta DCOMND
        lda #$40                ; data from device to computer
        sta DSTATS
        lda #3                  ; timeout (seconds): short, we retry anyway
        sta DTIMLO
        lda #128
        sta DBYTLO
        lda #0
        sta DBYTHI
        jsr SIOV
        lda DSTATS
        ldx #0
        rts

; ---------------------------------------------------------------------------
_rbl_read_sector:
        sta bufp
        stx bufp+1
        jsr popax               ; sector number
        sta cmdframe+2
        stx cmdframe+3
        jsr popa                ; drive unit 1..8
        clc
        adc #$30                ; $31 = D1:
        sta cmdframe
        lda #'R'
        sta cmdframe+1
        ; command frame checksum (8 bit add with end around carry)
        lda #0
        ldx #3
@ck:    clc
        adc cmdframe,x
        adc #0
        dex
        bpl @ck
        sta cmdframe+4

        sei
        ; POKEY ch3+4 = 16 bit baud rate generator, silent
        lda #$28
        sta AUDCTL
        lda #BAUD_AUDF3
        sta AUDF3
        lda #0
        sta AUDF4
        lda #$A0
        sta AUDC3
        sta AUDC4

        lda VSERIN
        sta oldserin
        lda VSERIN+1
        sta oldserin+1
        lda #<serin_irq
        sta VSERIN
        lda #>serin_irq
        sta VSERIN+1

        ; --- command frame, polled, IRQs masked ---
        lda SSKCTL
        and #$07
        ora #$20                ; async transmit, clock from ch4
        sta SKCTL
        sta SKRES
        lda #$34                ; command line asserted
        sta PBCTL
        lda POKMSK
        and #$C7
        sta IRQEN               ; no serial IRQ pending
        lda cmdframe            ; first byte straight in (as the OS does):
        sta SEROUT              ; "output needed" fires once it is moved
        ldx #1                  ; into the shift register
@tx:    lda POKMSK
        and #$C7
        ora #$10                ; serial output needed
        sta IRQEN
@w1:    lda IRQST
        and #$10
        bne @w1
        lda cmdframe,x
        sta SEROUT
        lda POKMSK
        and #$C7
        sta IRQEN               ; acknowledge
        inx
        cpx #5
        bne @tx
        lda POKMSK
        and #$C7
        ora #$08                ; transmission done
        sta IRQEN
@w2:    lda IRQST
        and #$08
        bne @w2
        lda POKMSK
        and #$C7
        sta IRQEN

        ; --- response, IRQ driven ---
        lda #0
        sta state
        sta cnt
        sta chk
        lda SSKCTL
        and #$07
        ora #$10                ; async receive
        sta SKCTL
        sta SKRES
        lda #$3C                ; command line released
        sta PBCTL
        lda POKMSK              ; the OS IRQ handler re-enables IRQEN from
        ora #$20                ; POKMSK, so the SERIN bit goes in both
        sta POKMSK
        sta IRQEN
        lda RTCLOK+2
        sta t0
        cli

@wait:  lda state
        cmp #ST_OK
        bcs @done
        lda RTCLOK+2
        sec
        sbc t0
        cmp #TIMEOUT
        bcc @wait
        lda #138                ; timeout
        bne @fin
@done:  sec
        sbc #ST_OK
        tax
        lda resulttab,x
@fin:   tax
        sei
        lda POKMSK
        and #$DF
        sta POKMSK
        sta IRQEN
        lda oldserin
        sta VSERIN
        lda oldserin+1
        sta VSERIN+1
        cli
        txa
        ldx #0
        rts

; ---------------------------------------------------------------------------
; VSERIN handler. The OS has pushed A and already acknowledged the IRQ.
serin_irq:
        tya
        pha
        lda SKSTAT
        sta SKRES               ; reset serial error latches
        and #$A0                ; bit7=0 framing error, bit5=0 overrun
        cmp #$A0
        bne @serr
        lda SERIN
        ldy state
        beq @ack
        dey
        beq @cpl
        dey
        beq @data
        dey
        beq @chk
        bne @out                ; finished: ignore further bytes

@ack:   cmp #'A'
        bne @nak
        inc state
        bne @out
@nak:   lda #ST_NAK
        bne @set

@cpl:   cmp #'C'
        bne @derr
        inc state
        bne @out
@derr:  lda #ST_DERR
        bne @set

@data:  ldy cnt
        sta (bufp),y
        clc
        adc chk
        adc #0
        sta chk
        iny
        sty cnt
        bpl @out                ; < 128 bytes
        inc state               ; -> ST_CHK
        bne @out

@chk:   cmp chk
        bne @ckerr
        lda #ST_OK
        bne @set
@ckerr: lda #ST_CKERR
        bne @set

@serr:  lda SERIN
        lda state
        cmp #ST_OK
        bcs @out
        lda #ST_SERR
@set:   sta state
@out:   jsr rmt_irqtick         ; player tick the VBI had to postpone
        pla
        tay
        pla
        rti
