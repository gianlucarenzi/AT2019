# binhdr.awk - the player addresses rmtplay.c needs, from an ld65 label file
#   awk -v P=PREFIX -f binhdr.awk file.lbl
# prints "#define PREFIX_NAME 0x...." for each symbol, 0 when it is missing
BEGIN {
	split("RASTERMUSICTRACKER ENTRY rmt_ioactive IOACTIVE " \
	      "_sid_init SID_INIT pokey_to_sid POKEY_TO_SID pokey_shadow SHADOW " \
	      "_sid_src SID_SRC _sid_volume SID_VOLUME _sid_freq_lo SID_FLO " \
	      "_sid_freq_hi SID_FHI _sid_wave SID_WAVE ispeed ISPEED " \
	      "line_lo LINE_LO line_hi LINE_HI _lzs_section LZS_SECTION _lzs_pos LZS_POS", a, " ")
	for (i = 1; i in a; i += 2) {
		name[a[i]] = a[i + 1]
		order[++n] = a[i + 1]
	}
}
{
	s = substr($3, 2)
	if (s in name)
		addr[name[s]] = "0x" substr($2, 3)
}
END {
	for (i = 1; i <= n; i++)
		printf "#define %s_%s %s\n", P, order[i], (order[i] in addr) ? addr[order[i]] : "0"
}
