; sidplayer.s - SID RMT Player Core
;
; Adapted from the RMT player by Radek Sterba (Raster/C.P.U.)
; This version targets the SID chip on Commodore 64.

.include "c64.inc"

.export _sid_init
.export _sid_player

; ============================================================================
; BSS section (player state)
; ============================================================================

.bss

player_speed:       .byte   0
player_pos:         .byte   0
player_line:        .byte   0
pattern_pos:        .word   0

voice_note:         .res    3
voice_volume:       .res    3
voice_freq_lo:      .res    3
voice_freq_hi:      .res    3
voice_ctrl:         .res    3

module_ptr:         .word   0

; ============================================================================
; Code section
; ============================================================================

.code

; _sid_init(const void *module)
; Initialize the player with an RMT module.
.proc _sid_init
    stx module_ptr + 1          ; Save high byte (X register)
    sta module_ptr              ; Save low byte (A register)
    
    ; Initialize player state
    lda #0
    sta player_speed
    sta player_pos
    sta player_line
    sta pattern_pos
    sta pattern_pos + 1
    
    ; Silence SID
    jsr _silence_sid
    
    rts
.endproc

; _sid_player()
; Main player routine, called from IRQ handler at ~50 Hz.
; Minimal skeleton - full implementation would process RMT patterns.
.proc _sid_player
    ; Placeholder: player logic goes here
    ; For now, just maintain state
    
    rts
.endproc

; _silence_sid()
; Mute all three SID voices
.proc _silence_sid
    lda #0
    
    sta SID_Ctl1                ; Clear gate bit
    sta SID_Ctl2
    sta SID_Ctl3
    sta SID_Amp                 ; Volume = 0
    
    rts
.endproc
