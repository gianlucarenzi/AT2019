;*
;* LZSS player: the POKEY streams of the SAP and XEX exports of RITMO / RMT
;* (VU-Player v2, LZ16 format by DMSC), played the way VU-Player plays them.
;*
;* A drop-in replacement of rmtplayr.s (same entry points, same exports, same
;* -D RMT_C64 / RMT_VERA / RMT_TRACKS builds): the music is not computed from
;* an RMT module but read from the POKEY registers that RMT recorded frame by
;* frame when it exported the song, with the tracker driver chosen there
;* (Patch16 by default). The sound is the one of the SAP / XEX export.
;*
;* The module (tools/sap2ca65.py, from a .sap or .xex exported by RITMO):
;*
;*   +0  instrument speed (stream frames per video frame)
;*   +1  tracks: 4 (mono) or 8 (stereo: frames alternate left / right)
;*   +2  n = number of sections (intro, loop)
;*   +3  section played after the last one (the loop)
;*   +4  n+1 words: start of each section, then the end of the last one
;*
;* Each section is one LZ16 stream: the 9 POKEY registers (AUDF1 AUDC1 ..
;* AUDC4 AUDCTL) are 9 byte streams, each with a 256 byte window:
;*
;*   1 byte    bit 0..7 = 1: register 8..1 never changes (bit 0 = AUDCTL)
;*   9 bytes   frame 0, registers 8..0
;*   then, for each frame and each register 8..0 that changes, unless it
;*   is inside a match: a control bit (LSB first, 8 per byte, the byte
;*   comes where the first of its bits is needed)
;*     1  literal: 1 byte, the value
;*     0  match:   2 bytes, position in the window - 2, length (0 = 256):
;*                 the values written there are repeated, one per frame
;*   The section ends when the stream reaches the start of the next one
;*   (the compressor makes the last frame read a byte).
;*
;* As rmtplayr.s, rmt_play first writes POKEY (SetPokey: the frame decoded
;* by the previous call) then decodes the next frame into trackn_audf,
;* trackn_audc and v_audctl. A stereo module decodes two frames per call:
;* first the right POKEY into channels 5-8 (v_audctl2), then the left one
;* into channels 1-4. That is the order of the export (VU-Player plays the
;* first one on $D210): the echo on channel 8 of an RMT8 song is heard on
;* the right POKEY, as the RMT player plays it.
;*
;* The intro is played once, then the loop for ever, as a SAP of RITMO 2.6
;* plays in VU-Player (in an older SAP the INIT of VU-Player cleared the
;* endless loop flag, and it started a fade out at the second end of the
;* loop: that is left out).
;*
;* Not the VU meters, the rasterbar and the subtune keys of VU-Player: the
;* host program has its own display. The instrument speed is returned by
;* rmt_init as by rmtplayr.s: the host calls rmt_play that many times per
;* frame (RMT_VERA rmtvbi.s) or plays slower (one call per frame).
;*
        .export rmt_init, rmt_play, rmt_p3, rmt_silence, SetPokey
        .export RASTERMUSICTRACKER
        .export rmt_ioactive
        .export _rmt_audc
;* stream position for players that show it (rmtplay.c with RMT_LZSS): the
;* section of the next frame and its place in the section (24 bit, in
;* rmt_play calls: a stereo call is two stream frames)
        .export _lzs_section, _lzs_pos
.ifdef RMT_VERA
        .export trackn_audf, trackn_audc, v_audctl, v_audctl2
        .export _rmt_pokey_mute, _rmt_tracks
;* the same channel state under C names (rmtplay.c)
        .export _rmt_chan_audf := trackn_audf, _rmt_chan_audc := trackn_audc
        .export _rmt_audctl := v_audctl, _rmt_audctl2 := v_audctl2
.endif

;* current AUDC values computed by the player (C: rmt_audc[4], VU meter)
_rmt_audc = trackn_audc

;* the module (tools/sap2ca65.py) states how many tracks it was made for
        .importzp rmt_song_tracks

.ifdef RMT_TRACKS
TRACKS          = RMT_TRACKS
.else
TRACKS          = 4
.endif
.if TRACKS <> 4 && TRACKS <> 8
.error "RMT_TRACKS must be 4 (mono) or 8 (stereo)"
.endif
;* 8 tracks without RMT_VERA (RmtSkeleton / PokeyATest): channels 5-8 for
;* psgrmt.s (VERA PSG) or a second POKEY at $D210 (_rmt_pokey2), see rmtvbi.s
.if TRACKS > 4 && .not .defined(RMT_VERA)
        .export trackn_audf, trackn_audc, v_audctl, v_audctl2
        .export _rmt_pokey2
.endif
        .assert rmt_song_tracks = TRACKS, error, "LZSS module and player track count differ (RMT_TRACKS; a stereo SAP/XEX needs RMT_TRACKS=8)"

.ifdef RMT_C64
        .import pokey_shadow
POKEY           = pokey_shadow
.if TRACKS > 4
        .import pokey_shadow2
.endif
.else
POKEY           = $D200
.endif
AUDF1           = POKEY+$00
AUDC1           = POKEY+$01
AUDF2           = POKEY+$02
AUDC2           = POKEY+$03
AUDF3           = POKEY+$04
AUDC3           = POKEY+$05
AUDF4           = POKEY+$06
AUDC4           = POKEY+$07
AUDCTL          = POKEY+$08
SKCTL           = POKEY+$0F
.ifdef RMT_C64
.if TRACKS > 4
POKEY2          = pokey_shadow2 ;* right POKEY: RAM, played by a second SID
.endif
.else
POKEY2          = $D210         ;* right POKEY (8 tracks, _rmt_pokey2 <> 0)
.endif
CRITIC          = $42           ;* OS: <> 0 during SIO

;* ---------------------------------------------------------------------------
;* Zero page: the stream and the window of the register being decoded
;* ---------------------------------------------------------------------------
.ifdef RMT_C64
        .segment "RMTZP": zeropage
.else
        .segment "ZEROPAGE"
.endif
lz_ptr:         .res 2          ;* next byte of the stream
lz_win:         .res 2          ;* window of one register (lo = <window)

;* ---------------------------------------------------------------------------
;* Variables
;* ---------------------------------------------------------------------------
        .segment "BSS"
trackn_audf:    .res TRACKS     ;* AUDF of the next frame, per channel
trackn_audc:    .res TRACKS     ;* AUDC of the next frame, per channel
v_audctl:       .res 1          ;* AUDCTL of the next frame
v_audctl2:      .res 1          ;* AUDCTL of the right POKEY (stereo)
_lzs_section:   .res 1          ;* section of the next frame
_lzs_pos:       .res 3          ;* place of the next frame in the section
lz_mod:         .res 2          ;* the module
lz_ispeed:      .res 1          ;* instrument speed
lz_nsec:        .res 1          ;* sections
lz_loop:        .res 1          ;* section after the last one
lz_next:        .res 1          ;* section to start when this one ends
lz_new:         .res 1          ;* <> 0: the section has ended
lz_end:         .res 2          ;* end of the section
lz_bits:        .res 1          ;* control bits left, above a 1 marker
lz_pos:         .res 1          ;* window position of the next frame
lz_tmp:         .res 1
lz_skip:        .res 9          ;* <> 0: the register never changes
lz_cnt:         .res 9          ;* values left in the current match
lz_src:         .res 9          ;* window position of the match
lz_val:         .res 9          ;* registers of the frame decoded last
lz_window:      .res 9*256      ;* the last 256 values of each register

;* ---------------------------------------------------------------------------
;* Player code
;* ---------------------------------------------------------------------------
        .segment "CODE"

;* != 0 while SIO is active: channels 3/4 and AUDCTL belong to the serial port
;* (CRITIC <> 0 has the same effect, see SetPokey)
rmt_ioactive:   .byte 0
.ifdef RMT_VERA
;* != 0: POKEY kept silent (VERA PSG only output)
_rmt_pokey_mute: .byte 0
;* tracks the player was built for (4 or 8)
_rmt_tracks:    .byte TRACKS
.elseif TRACKS > 4
.ifdef RMT_C64
;* the right POKEY is RAM (pokey_shadow2) on the C64: always written, the C64
;* code plays it on a second SID when there is one
        .pushseg
        .segment "DATA"
_rmt_pokey2:    .byte 1
        .popseg
.else
;* != 0: a second POKEY at $D210 plays channels 5-8 (rmtvbi.s detects it)
_rmt_pokey2:    .byte 0
.endif
.endif

;*
;* The vectors of rmtplayr.s
;*
RASTERMUSICTRACKER:
        jmp rmt_init
        jmp rmt_play
        jmp rmt_p3
        jmp rmt_silence
        jmp SetPokey

;* X = module lo, Y = module hi (A, the starting song line, is not used)
;* returns A = instrument speed
rmt_init:
        stx lz_mod
        sty lz_mod+1
        stx lz_ptr
        sty lz_ptr+1
        lda #<lz_window
        sta lz_win
        ldy #0
        lda (lz_ptr),y
        bne @sp
        lda #1                  ;* no speed: once per frame
@sp:    sta lz_ispeed
        ldy #2
        lda (lz_ptr),y
        sta lz_nsec
        iny
        lda (lz_ptr),y
        sta lz_loop
        lda #0
        sta lz_next
        sta v_audctl2
        ldx #TRACKS-1
@cl:    sta trackn_audf,x
        sta trackn_audc,x
        dex
        bpl @cl
        lda #1
        sta lz_new              ;* start section 0
        jsr rmt_p3              ;* frame 0
        ;* fall through: POKEY silent, A = instrument speed

rmt_silence:
        lda #0
        sta AUDCTL
        ldy #3
        sty SKCTL
        ldy #8
@si:    sta AUDF1,y
        dey
        bpl @si
.if TRACKS > 4 && .not .defined(RMT_VERA)
        ldy _rmt_pokey2
        beq @s3
        sta POKEY2+8            ;* right AUDCTL
        ldy #3
        sty POKEY2+$0F          ;* right SKCTL
        ldy #8
@s2:    sta POKEY2,y
        dey
        bpl @s2
@s3:
.endif
        lda lz_ispeed
        rts

;* one frame: POKEY gets the frame decoded last, then the next one is decoded
rmt_play:
        jsr SetPokey
;* decode the next frame only
rmt_p3:
        jsr lz_frame
        inc _lzs_pos            ;* lz_section sets it to -1
        bne @p
        inc _lzs_pos+1
        bne @p
        inc _lzs_pos+2
@p:
.if TRACKS > 4
        ldy #4                  ;* stereo: the right POKEY comes first (as
        jsr lz_tracks           ;* in the SAP-R of RITMO; VU-Player writes
        sta v_audctl2           ;* it to $D210)
        jsr lz_frame            ;* then the left one
.endif
        ldy #0
        jsr lz_tracks
        sta v_audctl
        rts

;* lz_val -> trackn_audf/audc + Y (channels Y..Y+3); returns A = AUDCTL
lz_tracks:
        ldx #0
@t:     lda lz_val,x
        sta trackn_audf,y
        lda lz_val+1,x
        sta trackn_audc,y
        inx
        inx
        iny
        cpx #8
        bne @t
        lda lz_val+8
        rts

;* ---------------------------------------------------------------------------
;* lz_frame: the next frame of the stream into lz_val (9 registers); at the
;* end of a section the next one starts (the last one goes on with the loop)
;* ---------------------------------------------------------------------------
lz_frame:
        lda lz_new
        beq @dec
        jsr lz_section
        jmp @end
@dec:   ldx #8
@reg:   lda lz_skip,x
        bne @nx
        lda lz_cnt,x
        bne @copy               ;* inside a match
        jsr lz_bit
        bcc @match
        jsr lz_byte             ;* literal
        pha
        txa
        clc
        adc #>lz_window
        sta lz_win+1
        pla
        jmp @put
@match: jsr lz_byte             ;* window position - 2
        clc
        adc #2
        sta lz_src,x
        jsr lz_byte             ;* length, 0 = 256
        sta lz_cnt,x
@copy:  txa
        clc
        adc #>lz_window
        sta lz_win+1
        ldy lz_src,x
        lda (lz_win),y
        inc lz_src,x
        dec lz_cnt,x
@put:   ldy lz_pos
        sta (lz_win),y
        sta lz_val,x
@nx:    dex
        bpl @reg
        inc lz_pos
@end:   lda lz_ptr              ;* the stream has reached the end?
        cmp lz_end
        lda lz_ptr+1
        sbc lz_end+1
        bcc @more
        lda #1
        sta lz_new
@more:  rts

;* lz_section: start section lz_next, decode its frame 0
lz_section:
        lda lz_next
        sta _lzs_section
        tax
        inx
        cpx lz_nsec
        bcc @nl
        ldx lz_loop             ;* after the last one: the loop
@nl:    stx lz_next
        asl a                   ;* word of the section in the header
        clc
        adc #4
        tay
        lda lz_mod
        sta lz_ptr
        lda lz_mod+1
        sta lz_ptr+1
        lda (lz_ptr),y          ;* end = start of the next section
        tax
        iny
        lda (lz_ptr),y
        pha
        iny
        lda (lz_ptr),y
        sta lz_end
        iny
        lda (lz_ptr),y
        sta lz_end+1
        pla
        sta lz_ptr+1
        stx lz_ptr
        jsr lz_byte             ;* registers that never change
        sta lz_tmp
        ldx #8
@sk:    lda #0
        lsr lz_tmp
        rol a
        sta lz_skip,x
        dex
        bne @sk
        stx lz_skip             ;* register 0 (AUDF1) is always coded
        ldx #8
@iv:    jsr lz_byte             ;* frame 0
        sta lz_val,x
        pha
        txa
        clc
        adc #>lz_window
        sta lz_win+1
        pla
        ldy #0
        sta (lz_win),y
        tya
        sta lz_cnt,x
        dex
        bpl @iv
        lda #1
        sta lz_pos
        sta lz_bits             ;* no control bits: read a byte first
        lda #$FF
        sta _lzs_pos            ;* rmt_p3 makes it 0
        sta _lzs_pos+1
        sta _lzs_pos+2
        lda #0
        sta lz_new
        rts

;* lz_byte: A = next byte of the stream (X kept)
lz_byte:
        ldy #0
        lda (lz_ptr),y
        inc lz_ptr
        bne @x
        inc lz_ptr+1
@x:     rts

;* lz_bit: C = next control bit (X kept)
lz_bit:
        lsr lz_bits
        bne @x                  ;* still bits above the marker
        jsr lz_byte
        sec                     ;* marker
        ror a
        sta lz_bits
@x:     rts

;* L1 L2 L3 L4 (mono). The right POKEY of a stereo module is in
;* trackn_audf/audc+4 and v_audctl2; without RMT_VERA (the 8 track build of
;* RmtSkeleton / PokeyATest) it is also written to a second POKEY at $D210
;* when _rmt_pokey2 is set
SetPokey:
.if TRACKS > 4 && .not .defined(RMT_VERA)
        lda _rmt_pokey2         ;* no second POKEY: channels 5-8 stay in
        beq sp_left             ;* trackn_audf/audc+4 (VERA PSG or nothing)
        ldy v_audctl2
        lda trackn_audf+0+4
        ldx trackn_audc+0+4
        sta POKEY2+0
        stx POKEY2+1
        lda trackn_audf+1+4
        ldx trackn_audc+1+4
        sta POKEY2+2
        stx POKEY2+3
        lda trackn_audf+2+4
        ldx trackn_audc+2+4
        sta POKEY2+4
        stx POKEY2+5
        lda trackn_audf+3+4
        ldx trackn_audc+3+4
        sta POKEY2+6
        stx POKEY2+7
        sty POKEY2+8
sp_left:
.endif
        ldy v_audctl
.ifdef RMT_VERA
        lda _rmt_pokey_mute     ;* VERA only: keep POKEY silent
        beq sp_on
        lda #0
        sta AUDC1
        sta AUDC2
        beq sp_io               ;* always: channels 3/4 at volume 0 too
sp_on:
.endif
        lda trackn_audf+0
        ldx trackn_audc+0
        sta AUDF1
        stx AUDC1
        lda trackn_audf+1
        ldx trackn_audc+1
        sta AUDF2
        stx AUDC2
        lda rmt_ioactive        ;* SIO running? channels 3/4 + AUDCTL are
.ifndef RMT_C64
        ora CRITIC              ;* (OS SIO: CRITIC set)
.endif
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
        rts
sp_io:  lda #0                  ;* SIO owns channels 3/4: keep them silent
        sta AUDC3
        sta AUDC4
        rts
