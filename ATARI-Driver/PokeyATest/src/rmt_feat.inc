;*
;* RMT FEATures definitions (ca65 version)
;*
;* For optimizations of RMT player routine to concrete RMT modul only!
;* Default: every feature enabled, so any mono RMT4 module plays correctly.
;* --------BEGIN--------
FEAT_SFX                = 0     ;* 0 => No SFX support, 1 => SFX support
FEAT_GLOBALVOLUMEFADE   = 0     ;* 0 => No RMTGLOBALVOLUMEFADE support
FEAT_NOSTARTINGSONGLINE = 0     ;* 0 => Init with starting songline
FEAT_INSTRSPEED         = 0
FEAT_CONSTANTSPEED      = 0
;* VARIOUS COMMANDS
FEAT_COMMAND1           = 1
FEAT_COMMAND2           = 1
FEAT_COMMAND3           = 1
FEAT_COMMAND4           = 1
FEAT_COMMAND5           = 1
FEAT_COMMAND6           = 1
;* COMMAND7 SETNOTE (i.e. command 7 with parameter != $80)
FEAT_COMMAND7SETNOTE    = 1
;* COMMAND7 VOLUMEONLY (i.e. command 7 with parameter == $80)
FEAT_COMMAND7VOLUMEONLY = 1
;* PORTAMENTO
FEAT_PORTAMENTO         = 1
;* FILTER
FEAT_FILTER             = 1
FEAT_FILTERG0L          = 1
FEAT_FILTERG1L          = 1
;* BASS16B (i.e. distortion value 6)
FEAT_BASS16             = 1
FEAT_BASS16G1L          = 1
FEAT_BASS16G3L          = 1
;* VOLUME ONLY for particular generators
FEAT_VOLUMEONLYG0L      = 1
FEAT_VOLUMEONLYG2L      = 1
FEAT_VOLUMEONLYG3L      = 1
;* TABLE TYPE (i.e. TABLETYPE=1)
FEAT_TABLETYPE          = 1
;* TABLE MODE (i.e. TABLEMODE=1)
FEAT_TABLEMODE          = 1
;* TABLE GO (i.e. TGO is nonzero value)
FEAT_TABLEGO            = 1
;* AUDCTLMANUALSET (i.e. any MANUAL AUDCTL setting is nonzero value)
FEAT_AUDCTLMANUALSET    = 1
;* VOLUME MINIMUM (i.e. VMIN is nonzero value)
FEAT_VOLUMEMIN          = 1
;* INSTRUMENT EFFECTS (i.e. VIBRATO or FSHIFT are nonzero values with nonzero DELAY)
FEAT_EFFECTVIBRATO      = 1
FEAT_EFFECTFSHIFT       = 1
;* --------END--------
