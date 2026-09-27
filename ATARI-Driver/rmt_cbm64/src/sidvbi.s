; sidvbi.s - CIA1 IRQ handler for SID RMT player
;
; Provides timing for the RMT player on C64.
; Uses CIA1 Timer A to generate ~50 Hz IRQs.

.include "c64.inc"

.export _sid_play_on
.export _sid_play_off
.export _sid_frames
.export _sid_status
.export _sid_volume

; ============================================================================
; BSS section (uninitialized data)
; ============================================================================

.bss

_sid_frames:     .word   0       ; Frame counter
_sid_status:     .byte   0       ; Status: 0=idle, 1=playing
_sid_volume:     .res    3       ; Volume for each voice

; ============================================================================
; Code section
; ============================================================================

.code

; _sid_play_on()
; Install IRQ handler and start CIA1 Timer A
.proc _sid_play_on
    php                         ; Save flags
    sei                         ; Disable IRQs
    
    ; Disable CIA1 interrupts
    lda #$7F
    sta CIA1_ICR
    
    ; Set Timer A to ~50 Hz (PAL)
    lda #<19700
    sta CIA1_TA
    lda #>19700
    sta CIA1_TA + 1
    
    ; Enable Timer A interrupt
    lda #$81
    sta CIA1_ICR
    
    ; Start Timer A (continuous mode)
    lda #$01
    sta CIA1_CRA
    
    ; Mark as playing
    lda #1
    sta _sid_status
    
    plp                         ; Restore flags
    rts
.endproc

; _sid_play_off()
; Stop Timer A and silence SID
.proc _sid_play_off
    php                         ; Save flags
    sei                         ; Disable IRQs
    
    ; Disable CIA1 interrupts
    lda #$7F
    sta CIA1_ICR
    
    ; Silence all SID voices
    lda #0
    sta SID_Ctl1
    sta SID_Ctl2
    sta SID_Ctl3
    sta SID_Amp
    
    ; Mark as idle
    lda #0
    sta _sid_status
    
    plp                         ; Restore flags
    rts
.endproc
