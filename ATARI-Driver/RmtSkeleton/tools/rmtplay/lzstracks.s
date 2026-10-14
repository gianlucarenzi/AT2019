; lzstracks.s - track count of an LZSS module for lzsplayr.s (tools/rmtplay)
; In the Atari and C64 programs it comes with the module (tools/sap2ca65.py);
; here the module is built at run time from the .sap / .xex, mono only.
rmt_song_tracks = 4
        .exportzp rmt_song_tracks
