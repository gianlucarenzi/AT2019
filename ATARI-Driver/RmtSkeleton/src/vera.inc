; vera.inc - the VeraX16 PBI card registers used by psgrmt.s and rmtvbi.s
; (a subset of VERA_ATARI_PBI/vera_common.inc)

PBI_ADDR                = $D100                     ; VERA PBI base address ($D100-$D11F)

VERA_ADDR_L             = PBI_ADDR+$00              ; VRAM address bits  7:0 (active port)
VERA_ADDR_M             = PBI_ADDR+$01              ; VRAM address bits 15:8
VERA_ADDR_H             = PBI_ADDR+$02              ; bit[0]=A16, bits[7:4]=increment
VERA_DATA0              = PBI_ADDR+$03              ; VRAM data port 0
VERA_CTRL               = PBI_ADDR+$05              ; ADDRSEL(0) DCSEL(1) RESET(7)
VERA_FX_CTRL            = PBI_ADDR+$09              ; DCSEL=2: FX_CTRL

VERA_INC1               = $10                       ; ADDR_H: auto-increment by 1
VERA_DCSEL2             = $04                       ; CTRL: select FX bank 2 (FX_CTRL ...)

VERA_PSG_BASE           = $01F9C0                   ; PSG voice 0 register base in VRAM
