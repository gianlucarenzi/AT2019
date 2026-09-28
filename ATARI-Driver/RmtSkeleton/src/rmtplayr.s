;*
;* Raster Music Tracker, RMT Atari routine version 1.20090108
;* (c) Radek Sterba, Raster/C.P.U., 2002 - 2009
;* http://raster.atari.org
;*
;* ca65 port (mono, 4 tracks) for PokeyATest - RetroBitLab
;*
;* Differences from the original xasm source:
;*  - relocatable: zero page vars in ZEROPAGE, track vars in BSS, tables in
;*    RODATA (frqtab is page aligned through .align), code in CODE.
;*    The original "PLAYER must be at $xx00" constraint is gone.
;*  - mono only (STEREOMODE 0).
;*  - SetPokey honours rmt_ioactive: while a SIO transfer is running POKEY
;*    channels 3+4 are the serial baud rate generator (AUDCTL=$28, 16 bit
;*    joined, 1.79MHz clock) so the player must NOT write AUDF3/AUDC3/
;*    AUDF4/AUDC4/AUDCTL. Only channels 1 and 2 keep playing.
;*
        .include "rmt_feat.inc"

        .export rmt_init, rmt_play, rmt_p3, rmt_silence, SetPokey
        .export RASTERMUSICTRACKER
        .export rmt_ioactive
        .export _rmt_audc

;* current AUDC values computed by the player (C: rmt_audc[4], VU meter)
_rmt_audc = trackn_audc

TRACKS          = 4
INSTRPAR        = 12

AUDF1           = $D200
AUDC1           = $D201
AUDF2           = $D202
AUDC2           = $D203
AUDF3           = $D204
AUDC3           = $D205
AUDF4           = $D206
AUDC4           = $D207
AUDCTL          = $D208
SKCTL           = $D20F

FEAT_EFFECTS    = FEAT_EFFECTVIBRATO || FEAT_EFFECTFSHIFT

;* ---------------------------------------------------------------------------
;* RMT ZeroPage addresses (19 bytes, used only by the player)
;* ---------------------------------------------------------------------------
        .segment "ZEROPAGE"
p_tis:
p_instrstable:          .res 2
p_trackslbstable:       .res 2
p_trackshbstable:       .res 2
p_song:                 .res 2
ns:                     .res 2
nr:                     .res 2
nt:                     .res 2
reg1:                   .res 1
reg2:                   .res 1
reg3:                   .res 1
tmp:                    .res 1
.if FEAT_COMMAND2
frqaddcmd2:             .res 1
.endif

;* ---------------------------------------------------------------------------
;* Track variables
;* ---------------------------------------------------------------------------
        .segment "BSS"
track_variables:
trackn_db:              .res TRACKS
trackn_hb:              .res TRACKS
trackn_idx:             .res TRACKS
trackn_pause:           .res TRACKS
trackn_note:            .res TRACKS
trackn_volume:          .res TRACKS
trackn_distor:          .res TRACKS
trackn_shiftfrq:        .res TRACKS
.if FEAT_PORTAMENTO
trackn_portafrqc:       .res TRACKS
trackn_portafrqa:       .res TRACKS
trackn_portaspeed:      .res TRACKS
trackn_portaspeeda:     .res TRACKS
trackn_portadepth:      .res TRACKS
.endif
trackn_instrx2:         .res TRACKS
trackn_instrdb:         .res TRACKS
trackn_instrhb:         .res TRACKS
trackn_instridx:        .res TRACKS
trackn_instrlen:        .res TRACKS
trackn_instrlop:        .res TRACKS
trackn_instrreachend:   .res TRACKS
trackn_volumeslidedepth: .res TRACKS
trackn_volumeslidevalue: .res TRACKS
.if FEAT_VOLUMEMIN
trackn_volumemin:       .res TRACKS
.endif
.if FEAT_EFFECTS
trackn_effdelay:        .res TRACKS
.endif
.if FEAT_EFFECTVIBRATO
trackn_effvibratoa:     .res TRACKS
.endif
.if FEAT_EFFECTFSHIFT
trackn_effshift:        .res TRACKS
.endif
trackn_tabletypespeed:  .res TRACKS
.if FEAT_TABLEMODE
trackn_tablemode:       .res TRACKS
.endif
trackn_tablenote:       .res TRACKS
trackn_tablea:          .res TRACKS
trackn_tableend:        .res TRACKS
.if FEAT_TABLEGO
trackn_tablelop:        .res TRACKS
.endif
trackn_tablespeeda:     .res TRACKS
.if FEAT_FILTER || FEAT_BASS16
trackn_command:         .res TRACKS
.endif
.if FEAT_BASS16
trackn_outnote:         .res TRACKS
.endif
.if FEAT_FILTER
trackn_filter:          .res TRACKS
.endif
trackn_audf:            .res TRACKS
trackn_audc:            .res TRACKS
.if FEAT_AUDCTLMANUALSET
trackn_audctl:          .res TRACKS
.endif
v_aspeed:               .res 1
track_endvariables:

        .assert track_endvariables - track_variables < 256, error, "RMT track variables too big"

;* ---------------------------------------------------------------------------
;* Tables (RMTTAB segment is page aligned by src/pokeyatest.cfg)
;* ---------------------------------------------------------------------------
        .segment "RMTTAB"
frqtab:                         ;* frqtab must begin at the memory page bound!
frqtabbass1:
        .byte $BF,$B6,$AA,$A1,$98,$8F,$89,$80,$F2,$E6,$DA,$CE,$BF,$B6,$AA,$A1
        .byte $98,$8F,$89,$80,$7A,$71,$6B,$65,$5F,$5C,$56,$50,$4D,$47,$44,$3E
        .byte $3C,$38,$35,$32,$2F,$2D,$2A,$28,$25,$23,$21,$1F,$1D,$1C,$1A,$18
        .byte $17,$16,$14,$13,$12,$11,$10,$0F,$0E,$0D,$0C,$0B,$0A,$09,$08,$07
frqtabbass2:
        .byte $FF,$F1,$E4,$D8,$CA,$C0,$B5,$AB,$A2,$99,$8E,$87,$7F,$79,$73,$70
        .byte $66,$61,$5A,$55,$52,$4B,$48,$43,$3F,$3C,$39,$37,$33,$30,$2D,$2A
        .byte $28,$25,$24,$21,$1F,$1E,$1C,$1B,$19,$17,$16,$15,$13,$12,$11,$10
        .byte $0F,$0E,$0D,$0C,$0B,$0A,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00
frqtabpure:
        .byte $F3,$E6,$D9,$CC,$C1,$B5,$AD,$A2,$99,$90,$88,$80,$79,$72,$6C,$66
        .byte $60,$5B,$55,$51,$4C,$48,$44,$40,$3C,$39,$35,$32,$2F,$2D,$2A,$28
        .byte $25,$23,$21,$1F,$1D,$1C,$1A,$18,$17,$16,$14,$13,$12,$11,$10,$0F
        .byte $0E,$0D,$0C,$0B,$0A,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00,$00
.if FEAT_BASS16
frqtabbasshi:
        .byte $0D,$0D,$0C,$0B,$0B,$0A,$0A,$09,$08,$08,$07,$07,$07,$06,$06,$05
        .byte $05,$05,$04,$04,$04,$04,$03,$03,$03,$03,$03,$02,$02,$02,$02,$02
        .byte $02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.endif
volumetab:
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01
        .byte $00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02
        .byte $00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03,$03,$03
        .byte $00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03,$04,$04
        .byte $00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$04,$05,$05
        .byte $00,$00,$01,$01,$02,$02,$02,$03,$03,$04,$04,$04,$05,$05,$06,$06
        .byte $00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$07
        .byte $00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$07,$08
        .byte $00,$01,$01,$02,$02,$03,$04,$04,$05,$05,$06,$07,$07,$08,$08,$09
        .byte $00,$01,$01,$02,$03,$03,$04,$05,$05,$06,$07,$07,$08,$09,$09,$0A
        .byte $00,$01,$01,$02,$03,$04,$04,$05,$06,$07,$07,$08,$09,$0A,$0A,$0B
        .byte $00,$01,$02,$02,$03,$04,$05,$06,$06,$07,$08,$09,$0A,$0A,$0B,$0C
        .byte $00,$01,$02,$03,$03,$04,$05,$06,$07,$08,$09,$0A,$0A,$0B,$0C,$0D
        .byte $00,$01,$02,$03,$04,$05,$06,$07,$07,$08,$09,$0A,$0B,$0C,$0D,$0E
        .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F
.if FEAT_BASS16
frqtabbasslo:
        .byte $F2,$33,$96,$E2,$38,$8C,$00,$6A,$E8,$6A,$EF,$80,$08,$AE,$46,$E6
        .byte $95,$41,$F6,$B0,$6E,$30,$F6,$BB,$84,$52,$22,$F4,$C8,$A0,$7A,$55
        .byte $34,$14,$F5,$D8,$BD,$A4,$8D,$77,$60,$4E,$38,$27,$15,$06,$F7,$E8
        .byte $DB,$CF,$C3,$B8,$AC,$A2,$9A,$90,$88,$7F,$78,$70,$6A,$64,$5E,$00
.endif
tabbeganddistor:
        .byte <(frqtabpure-frqtab),$00
        .byte <(frqtabpure-frqtab),$20
        .byte <(frqtabpure-frqtab),$40
        .byte <(frqtabbass1-frqtab),$c0
        .byte <(frqtabpure-frqtab),$80
        .byte <(frqtabpure-frqtab),$a0
        .byte <(frqtabbass1-frqtab),$c0
        .byte <(frqtabbass2-frqtab),$c0
.if FEAT_EFFECTVIBRATO
vibtabbeg:
        .byte 0,vib1-vib0,vib2-vib0,vib3-vib0
vib0:   .byte 0
vib1:   .byte 1,$ff,$ff,1
vib2:   .byte 1,0,$ff,$ff,0,1
vib3:   .byte 1,1,0,$ff,$ff,$ff,$ff,0,1,1
vibtabnext:
        .byte vib0-vib0+0
        .byte vib1-vib0+1,vib1-vib0+2,vib1-vib0+3,vib1-vib0+0
        .byte vib2-vib0+1,vib2-vib0+2,vib2-vib0+3,vib2-vib0+4,vib2-vib0+5,vib2-vib0+0
        .byte vib3-vib0+1,vib3-vib0+2,vib3-vib0+3,vib3-vib0+4,vib3-vib0+5,vib3-vib0+6,vib3-vib0+7,vib3-vib0+8,vib3-vib0+9,vib3-vib0+0
.endif

        .assert <frqtab = 0, error, "frqtab must be page aligned"
        .assert >frqtab = >(frqtab+255), error, "frqtab crosses a page"
        .assert <volumetab = 0, warning, "volumetab not page aligned (slower)"

;* ---------------------------------------------------------------------------
;* Player code (self modifying: CODE is loaded in RAM on the Atari)
;* ---------------------------------------------------------------------------
        .segment "CODE"

;* != 0 while SIO is active: channels 3/4 and AUDCTL belong to the serial port
rmt_ioactive:   .byte 0

;*
;* Set of RMT main vectors:
;*
RASTERMUSICTRACKER:
        jmp rmt_init
        jmp rmt_play
        jmp rmt_p3
        jmp rmt_silence
        jmp SetPokey
.if FEAT_SFX
        jmp rmt_sfx             ;* A=note(0,..,60),X=channel(0,..,3),Y=instrument*2(0,2,4,..,126)
.endif

;* X = module lo, Y = module hi, A = starting song line
rmt_init:
        stx ns
        sty ns+1
.if FEAT_NOSTARTINGSONGLINE = 0
        pha
.endif
        ldy #track_endvariables-track_variables
        lda #0
ri0:    sta track_variables-1,y
        dey
        bne ri0
        ldy #4
        lda (ns),y
        sta v_maxtracklen
        iny
.if FEAT_CONSTANTSPEED = 0
        lda (ns),y
        sta v_speed
.endif
.if FEAT_INSTRSPEED = 0
        iny
        lda (ns),y
        sta v_instrspeed
        sta v_ainstrspeed
.elseif FEAT_INSTRSPEED > 1
        lda #FEAT_INSTRSPEED
        sta v_ainstrspeed
.endif
        ldy #8
ri1:    lda (ns),y
        sta p_tis-8,y
        iny
        cpy #8+8
        bne ri1
.if FEAT_NOSTARTINGSONGLINE = 0
        pla
        pha
        asl a
        asl a
        clc
        adc p_song
        sta p_song
        pla
        php
        and #$c0
        asl a
        rol a
        rol a
        plp
        adc p_song+1
        sta p_song+1
.endif
        jsr GetSongLineTrackLineInitOfNewSetInstrumentsOnlyRmtp3
rmt_silence:
        lda #0
        sta AUDCTL
        ldy #3
        sty SKCTL
        ldy #8
si1:    sta AUDF1,y
        dey
        bpl si1
.if FEAT_INSTRSPEED = 0
        lda v_instrspeed
.else
        lda #FEAT_INSTRSPEED
.endif
        rts

GetSongLineTrackLineInitOfNewSetInstrumentsOnlyRmtp3:
GetSongLine:
        ldx #0
        stx v_abeat
nn0:
nn1:    txa
        tay
        lda (p_song),y
        cmp #$fe
        bcs nn2
        tay
        lda (p_trackslbstable),y
        sta trackn_db,x
        lda (p_trackshbstable),y
nn1a:   sta trackn_hb,x
        lda #0
        sta trackn_idx,x
        lda #1
nn1a2:  sta trackn_pause,x
        lda #$80
        sta trackn_instrx2,x
        inx
xtracks01:
        cpx #TRACKS
        bne nn1
        lda p_song
        clc
xtracks02:
        adc #TRACKS
        sta p_song
        bcc GetTrackLine
        inc p_song+1
nn1b:
        jmp GetTrackLine
nn2:
        beq nn3
nn2a:
        lda #0
        beq nn1a2
nn3:
        ldy #2
        lda (p_song),y
        tax
        iny
        lda (p_song),y
        sta p_song+1
        stx p_song
        ldx #0
        beq nn0

GetTrackLine:
oo0:
oo0a:
.if FEAT_CONSTANTSPEED = 0
        lda #$ff
v_speed = *-1
        sta v_bspeed
.endif
        ldx #$ff
oo1:
        inx
        dec trackn_pause,x
        bne oo1x
oo1b:
        lda trackn_db,x
        sta ns
        lda trackn_hb,x
        sta ns+1
oo1i:
        ldy trackn_idx,x
        inc trackn_idx,x
        lda (ns),y
        sta reg1
        and #$3f
        cmp #61
        beq oo1a
        bcs oo2
        sta trackn_note,x
.if FEAT_BASS16
        sta trackn_outnote,x
.endif
        iny
        lda (ns),y
        lsr a
        and #$3f*2
        sta trackn_instrx2,x
oo1a:
        lda #1
        sta trackn_pause,x
        ldy trackn_idx,x
        inc trackn_idx,x
        lda (ns),y
        lsr a
        ror reg1
        lsr a
        ror reg1
        lda reg1
.if FEAT_GLOBALVOLUMEFADE
        sec
        sbc #$00
RMTGLOBALVOLUMEFADE = *-1
        bcs voig
        lda #0
voig:
.endif
        and #$f0
        sta trackn_volume,x
oo1x:
xtracks03sub1:
        cpx #TRACKS-1
        bne oo1
.if FEAT_CONSTANTSPEED = 0
        lda #$ff
v_bspeed = *-1
        sta v_speed
.else
        lda #FEAT_CONSTANTSPEED
.endif
        sta v_aspeed
        jmp InitOfNewSetInstrumentsOnly
oo2:
        cmp #63
        beq oo63
        lda reg1
        and #$c0
        beq oo62_b
        asl a
        rol a
        rol a
        sta trackn_pause,x
        jmp oo1x
oo62_b:
        iny
        lda (ns),y
        sta trackn_pause,x
        inc trackn_idx,x
        jmp oo1x
oo63:
        lda reg1
.if FEAT_CONSTANTSPEED = 0
        bmi oo63_1X
        iny
        lda (ns),y
        sta v_bspeed
        inc trackn_idx,x
        jmp oo1i
oo63_1X:
.endif
        cmp #255
        beq oo63_11
        iny
        lda (ns),y
        sta trackn_idx,x
        jmp oo1i
oo63_11:
        jmp GetSongLine
p2xrmtp3:
        jmp rmt_p3
p2x0:   dex
        bmi p2xrmtp3
InitOfNewSetInstrumentsOnly:
p2x1:   ldy trackn_instrx2,x
        bmi p2x0
.if FEAT_SFX
        jsr SetUpInstrumentY2
        jmp p2x0
rmt_sfx:
        sta trackn_note,x
.if FEAT_BASS16
        sta trackn_outnote,x
.endif
        lda #$f0                ;* sfx note volume*16
RMTSFXVOLUME = *-1              ;* label for sfx note volume parameter overwriting
        sta trackn_volume,x
.endif
SetUpInstrumentY2:
        lda (p_instrstable),y
        sta trackn_instrdb,x
        sta nt
        iny
        lda (p_instrstable),y
        sta trackn_instrhb,x
        sta nt+1
.if FEAT_FILTER
        lda #1
        sta trackn_filter,x
.endif
.if FEAT_TABLEGO
.if FEAT_FILTER
        tay
.else
        ldy #1
.endif
        lda (nt),y
        sta trackn_tablelop,x
        iny
.else
        ldy #2
.endif
        lda (nt),y
        sta trackn_instrlen,x
        iny
        lda (nt),y
        sta trackn_instrlop,x
        iny
        lda (nt),y
        sta trackn_tabletypespeed,x
.if FEAT_TABLETYPE || FEAT_TABLEMODE
        and #$3f
.endif
        sta trackn_tablespeeda,x
.if FEAT_TABLEMODE
        lda (nt),y
        and #$40
        sta trackn_tablemode,x
.endif
.if FEAT_AUDCTLMANUALSET
        iny
        lda (nt),y
        sta trackn_audctl,x
        iny
.else
        ldy #6
.endif
        lda (nt),y
        sta trackn_volumeslidedepth,x
.if FEAT_VOLUMEMIN
        iny
        lda (nt),y
        sta trackn_volumemin,x
.if FEAT_EFFECTS
        iny
.endif
.else
.if FEAT_EFFECTS
        ldy #8
.endif
.endif
.if FEAT_EFFECTS
        lda (nt),y
        sta trackn_effdelay,x
.if FEAT_EFFECTVIBRATO
        iny
        lda (nt),y
        tay
        lda vibtabbeg,y
        sta trackn_effvibratoa,x
.endif
.if FEAT_EFFECTFSHIFT
        ldy #10
        lda (nt),y
        sta trackn_effshift,x
.endif
.endif
        lda #128
        sta trackn_volumeslidevalue,x
        sta trackn_instrx2,x
        asl a
        sta trackn_instrreachend,x
        sta trackn_shiftfrq,x
        tay
        lda (nt),y
        sta trackn_tableend,x
        adc #0
        sta trackn_instridx,x
        lda #INSTRPAR
        sta trackn_tablea,x
        tay
        lda (nt),y
        sta trackn_tablenote,x
xata_rtshere:
.if FEAT_SFX
        rts
.else
        jmp p2x0
.endif

rmt_play:
rmt_p0:
        jsr SetPokey
rmt_p1:
.if FEAT_INSTRSPEED = 0 || FEAT_INSTRSPEED > 1
        dec v_ainstrspeed
        bne rmt_p3
.endif
.if FEAT_INSTRSPEED = 0
        lda #$ff
v_instrspeed = *-1
        sta v_ainstrspeed
.elseif FEAT_INSTRSPEED > 1
        lda #FEAT_INSTRSPEED
        sta v_ainstrspeed
.endif
rmt_p2:
        dec v_aspeed
        bne rmt_p3
        inc v_abeat
        lda #$ff
v_abeat = *-1
        cmp #$ff
v_maxtracklen = *-1
        beq p2o3
        jmp GetTrackLine
p2o3:
        jmp GetSongLineTrackLineInitOfNewSetInstrumentsOnlyRmtp3
go_ppnext:
        jmp ppnext
rmt_p3:
        lda #>frqtab
        sta nr+1
xtracks05sub1:
        ldx #TRACKS-1
pp1:
        lda trackn_instrhb,x
        beq go_ppnext
        sta ns+1
        lda trackn_instrdb,x
        sta ns
        ldy trackn_instridx,x
        lda (ns),y
        sta reg1
        iny
        lda (ns),y
        sta reg2
        iny
        lda (ns),y
        sta reg3
        iny
        tya
        cmp trackn_instrlen,x
        bcc pp2
        beq pp2
        lda #$80
        sta trackn_instrreachend,x
pp1b:
        lda trackn_instrlop,x
pp2:    sta trackn_instridx,x
        lda reg1
        and #$0f
        ora trackn_volume,x
        tay
        lda volumetab,y
        sta tmp
        lda reg2
        and #$0e
        tay
        lda tabbeganddistor,y
        sta nr
        lda tmp
        ora tabbeganddistor+1,y
        sta trackn_audc,x
InstrumentsEffects:
.if FEAT_EFFECTS
        lda trackn_effdelay,x
        beq ei2
        cmp #1
        bne ei1
        lda trackn_shiftfrq,x
.if FEAT_EFFECTFSHIFT
        clc
        adc trackn_effshift,x
.endif
.if FEAT_EFFECTVIBRATO
        clc
        ldy trackn_effvibratoa,x
        adc vib0,y
.endif
        sta trackn_shiftfrq,x
.if FEAT_EFFECTVIBRATO
        lda vibtabnext,y
        sta trackn_effvibratoa,x
.endif
        jmp ei2
ei1:
        dec trackn_effdelay,x
ei2:
.endif
        ldy trackn_tableend,x
        cpy #INSTRPAR+1
        bcc ei3
        lda trackn_tablespeeda,x
        bpl ei2f
ei2c:
        tya
        cmp trackn_tablea,x
        bne ei2c2
.if FEAT_TABLEGO
        lda trackn_tablelop,x
.else
        lda #INSTRPAR
.endif
        sta trackn_tablea,x
        bne ei2a
ei2c2:
        inc trackn_tablea,x
ei2a:
        lda trackn_instrdb,x
        sta nt
        lda trackn_instrhb,x
        sta nt+1
        ldy trackn_tablea,x
        lda (nt),y
.if FEAT_TABLEMODE
        ldy trackn_tablemode,x
        beq ei2e
        clc
        adc trackn_tablenote,x
ei2e:
.endif
        sta trackn_tablenote,x
        lda trackn_tabletypespeed,x
.if FEAT_TABLETYPE || FEAT_TABLEMODE
        and #$3f
.endif
ei2f:
        sec
        sbc #1
        sta trackn_tablespeeda,x
ei3:
        lda trackn_instrreachend,x
        bpl ei4
        lda trackn_volume,x
        beq ei4
.if FEAT_VOLUMEMIN
        cmp trackn_volumemin,x
        beq ei4
        bcc ei4
.endif
        tay
        lda trackn_volumeslidevalue,x
        clc
        adc trackn_volumeslidedepth,x
        sta trackn_volumeslidevalue,x
        bcc ei4
        tya
        sbc #16
        sta trackn_volume,x
ei4:
.if FEAT_COMMAND2
        lda #0
        sta frqaddcmd2
.endif
.if FEAT_COMMAND1 || FEAT_COMMAND2 || FEAT_COMMAND3 || FEAT_COMMAND4 || FEAT_COMMAND5 || FEAT_COMMAND6 || FEAT_COMMAND7SETNOTE || FEAT_COMMAND7VOLUMEONLY
        lda reg2
.if FEAT_FILTER || FEAT_BASS16
        sta trackn_command,x
.endif
        and #$70
.if 1 = (FEAT_COMMAND1 + FEAT_COMMAND2 + FEAT_COMMAND3 + FEAT_COMMAND4 + FEAT_COMMAND5 + FEAT_COMMAND6 + (FEAT_COMMAND7SETNOTE || FEAT_COMMAND7VOLUMEONLY))
        beq cmd0
.else
        lsr a
        lsr a
        sta jmx+1               ;* branch offset = command*4
jmx:    bcc *                   ;* carry is always clear here
        jmp cmd0
        nop
        jmp cmd1
.if FEAT_COMMAND2 || FEAT_COMMAND3 || FEAT_COMMAND4 || FEAT_COMMAND5 || FEAT_COMMAND6 || FEAT_COMMAND7SETNOTE || FEAT_COMMAND7VOLUMEONLY
        nop
        jmp cmd2
.endif
.if FEAT_COMMAND3 || FEAT_COMMAND4 || FEAT_COMMAND5 || FEAT_COMMAND6 || FEAT_COMMAND7SETNOTE || FEAT_COMMAND7VOLUMEONLY
        nop
        jmp cmd3
.endif
.if FEAT_COMMAND4 || FEAT_COMMAND5 || FEAT_COMMAND6 || FEAT_COMMAND7SETNOTE || FEAT_COMMAND7VOLUMEONLY
        nop
        jmp cmd4
.endif
.if FEAT_COMMAND5 || FEAT_COMMAND6 || FEAT_COMMAND7SETNOTE || FEAT_COMMAND7VOLUMEONLY
        nop
        jmp cmd5
.endif
.if FEAT_COMMAND6 || FEAT_COMMAND7SETNOTE || FEAT_COMMAND7VOLUMEONLY
        nop
        jmp cmd6
.endif
.if FEAT_COMMAND7SETNOTE || FEAT_COMMAND7VOLUMEONLY
        nop
        jmp cmd7
.endif
.endif
.else
.if FEAT_FILTER || FEAT_BASS16
        lda reg2
        sta trackn_command,x
.endif
.endif
cmd1:
.if FEAT_COMMAND1
        lda reg3
        jmp cmd0c
.endif
cmd2:
.if FEAT_COMMAND2
        lda reg3
        sta frqaddcmd2
        lda trackn_note,x
        jmp cmd0a
.endif
cmd3:
.if FEAT_COMMAND3
        lda trackn_note,x
        clc
        adc reg3
        sta trackn_note,x
        jmp cmd0a
.endif
cmd4:
.if FEAT_COMMAND4
        lda trackn_shiftfrq,x
        clc
        adc reg3
        sta trackn_shiftfrq,x
        lda trackn_note,x
        jmp cmd0a
.endif
cmd5:
.if FEAT_COMMAND5 && FEAT_PORTAMENTO
.if FEAT_TABLETYPE
        lda trackn_tabletypespeed,x
        bpl cmd5a1
        ldy trackn_note,x
        lda (nr),y
        clc
        adc trackn_tablenote,x
        jmp cmd5ax
.endif
cmd5a1:
        lda trackn_note,x
        clc
        adc trackn_tablenote,x
        cmp #61
        bcc cmd5a2
        lda #63
cmd5a2:
        tay
        lda (nr),y
cmd5ax:
        sta trackn_portafrqc,x
        ldy reg3
        bne cmd5a
        sta trackn_portafrqa,x
cmd5a:
        tya
        lsr a
        lsr a
        lsr a
        lsr a
        sta trackn_portaspeed,x
        sta trackn_portaspeeda,x
        lda reg3
        and #$0f
        sta trackn_portadepth,x
        lda trackn_note,x
        jmp cmd0a
.elseif FEAT_COMMAND5
        lda trackn_note,x
        jmp cmd0a
.endif
cmd6:
.if FEAT_COMMAND6 && FEAT_FILTER
        lda reg3
        clc
        adc trackn_filter,x
        sta trackn_filter,x
        lda trackn_note,x
        jmp cmd0a
.elseif FEAT_COMMAND6
        lda trackn_note,x
        jmp cmd0a
.endif
cmd7:
.if FEAT_COMMAND7SETNOTE || FEAT_COMMAND7VOLUMEONLY
.if FEAT_COMMAND7SETNOTE
        lda reg3
.if FEAT_COMMAND7VOLUMEONLY
        cmp #$80
        beq cmd7a
.endif
        sta trackn_note,x
        jmp cmd0a
.endif
.if FEAT_COMMAND7VOLUMEONLY
cmd7a:
        lda trackn_audc,x
        ora #$f0
        sta trackn_audc,x
        lda trackn_note,x
        jmp cmd0a
.endif
.endif
cmd0:
        lda trackn_note,x
        clc
        adc reg3
cmd0a:
.if FEAT_TABLETYPE
        ldy trackn_tabletypespeed,x
        bmi cmd0b
.endif
        clc
        adc trackn_tablenote,x
        cmp #61
        bcc cmd0a1
        lda #0
        sta trackn_audc,x
        lda #63
cmd0a1:
.if FEAT_BASS16
        sta trackn_outnote,x
.endif
        tay
        lda (nr),y
        clc
        adc trackn_shiftfrq,x
.if FEAT_COMMAND2
        clc
        adc frqaddcmd2
.endif
.if FEAT_TABLETYPE
        jmp cmd0c
cmd0b:
        cmp #61
        bcc cmd0b1
        lda #0
        sta trackn_audc,x
        lda #63
cmd0b1:
        tay
        lda trackn_shiftfrq,x
        clc
        adc trackn_tablenote,x
        clc
        adc (nr),y
.if FEAT_COMMAND2
        clc
        adc frqaddcmd2
.endif
.endif
cmd0c:
        sta trackn_audf,x
pp9:
.if FEAT_PORTAMENTO
        lda trackn_portaspeeda,x
        beq pp10
        dec trackn_portaspeeda,x
        bne pp10
        lda trackn_portaspeed,x
        sta trackn_portaspeeda,x
        lda trackn_portafrqa,x
        cmp trackn_portafrqc,x
        beq pp10
        bcs pps1
        adc trackn_portadepth,x
        bcs pps8
        cmp trackn_portafrqc,x
        bcs pps8
        jmp pps9
pps1:
        sbc trackn_portadepth,x
        bcc pps8
        cmp trackn_portafrqc,x
        bcs pps9
pps8:
        lda trackn_portafrqc,x
pps9:
        sta trackn_portafrqa,x
pp10:
        lda reg2
        and #$01
        beq pp11
        lda trackn_portafrqa,x
        clc
        adc trackn_shiftfrq,x
        sta trackn_audf,x
pp11:
.endif
ppnext:
        dex
        bmi rmt_p4
        jmp pp1
rmt_p4:
.if FEAT_AUDCTLMANUALSET
        lda trackn_audctl+0
        ora trackn_audctl+1
        ora trackn_audctl+2
        ora trackn_audctl+3
        tax
.else
        ldx #0
.endif
qq1:
        stx v_audctl
.if FEAT_FILTER
.if FEAT_FILTERG0L
        lda trackn_command+0
        bpl qq2
        lda trackn_audc+0
        and #$0f
        beq qq2
        lda trackn_audf+0
        clc
        adc trackn_filter+0
        sta trackn_audf+2
.if FEAT_COMMAND7VOLUMEONLY && FEAT_VOLUMEONLYG2L
        lda trackn_audc+2
        and #$10
        bne qq1a
.endif
        lda #0
        sta trackn_audc+2
qq1a:
        txa
        ora #4
        tax
.endif
qq2:
.if FEAT_FILTERG1L
        lda trackn_command+1
        bpl qq3
        lda trackn_audc+1
        and #$0f
        beq qq3
        lda trackn_audf+1
        clc
        adc trackn_filter+1
        sta trackn_audf+3
.if FEAT_COMMAND7VOLUMEONLY && FEAT_VOLUMEONLYG3L
        lda trackn_audc+3
        and #$10
        bne qq2a
.endif
        lda #0
        sta trackn_audc+3
qq2a:
        txa
        ora #2
        tax
.endif
qq3:
.if FEAT_FILTERG0L || FEAT_FILTERG1L
        cpx v_audctl
        bne qq5
.endif
.endif
.if FEAT_BASS16
.if FEAT_BASS16G1L
        lda trackn_command+1
        and #$0e
        cmp #6
        bne qq4
        lda trackn_audc+1
        and #$0f
        beq qq4
        ldy trackn_outnote+1
        lda frqtabbasslo,y
        sta trackn_audf+0
        lda frqtabbasshi,y
        sta trackn_audf+1
.if FEAT_COMMAND7VOLUMEONLY && FEAT_VOLUMEONLYG0L
        lda trackn_audc+0
        and #$10
        bne qq3a
.endif
        lda #0
        sta trackn_audc+0
qq3a:
        txa
        ora #$50
        tax
.endif
qq4:
.if FEAT_BASS16G3L
        lda trackn_command+3
        and #$0e
        cmp #6
        bne qq5
        lda trackn_audc+3
        and #$0f
        beq qq5
        ldy trackn_outnote+3
        lda frqtabbasslo,y
        sta trackn_audf+2
        lda frqtabbasshi,y
        sta trackn_audf+3
.if FEAT_COMMAND7VOLUMEONLY && FEAT_VOLUMEONLYG2L
        lda trackn_audc+2
        and #$10
        bne qq4a
.endif
        lda #0
        sta trackn_audc+2
qq4a:
        txa
        ora #$28
        tax
.endif
.endif
qq5:
        stx v_audctl
rmt_p5:
.if FEAT_INSTRSPEED = 0 || FEAT_INSTRSPEED > 1
        lda #$ff
v_ainstrspeed = *-1
.else
        lda #1
.endif
        rts

;* L1 L2 L3 L4 (mono)
SetPokey:
        ldy #$ff
v_audctl = *-1
        lda trackn_audf+0
        ldx trackn_audc+0
        sta AUDF1
        stx AUDC1
        lda trackn_audf+1
        ldx trackn_audc+1
        sta AUDF2
        stx AUDC2
        lda rmt_ioactive        ;* SIO running? channels 3/4 + AUDCTL are
        bne sp_io               ;* the serial clock: do not touch them
        lda trackn_audf+2
        ldx trackn_audc+2
        sta AUDF3
        stx AUDC3
        lda trackn_audf+3
        ldx trackn_audc+3
        sta AUDF4
        stx AUDC4
        sty AUDCTL
sp_io:
        rts
RMTPLAYEREND:
