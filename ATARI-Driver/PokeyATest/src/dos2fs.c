//
// Minimal read only DOS 2.x filesystem on raw SIO sector reads
//
// Directory: sectors 361..368, 8 entries of 16 bytes per sector
//   +0 flag  +1/2 sector count  +3/4 first sector  +5..12 name  +13..15 ext
// Data sector (128 bytes, SD/ED):
//   0..124 data, 125 = fileno<<2 | next_hi, 126 = next_lo, 127 = bytes used
//

#include <string.h>
#include "dos2fs.h"

#define DIR_FIRST   361
#define DIR_LAST    368
#define SECSIZE     128
#define RETRIES     3

#define FLAG_DELETED  0x80
#define FLAG_INUSE    0x40
#define FLAG_NOFILENO 0x04   // MyDOS: 16 bit links, no file number

unsigned char fs_unit = 1;
unsigned char fs_loader = FS_LOADER_RBL;
void (*fs_progress)(unsigned int bytes) = 0;
unsigned int fs_retries = 0;

unsigned char secbuf[SECSIZE];

static unsigned char read_sector(unsigned int sector)
{
	unsigned char st, n;

	for (n = 0; n < RETRIES; n++) {
		if (fs_loader == FS_LOADER_OS)
			st = sio_read_sector(fs_unit, sector, secbuf);
		else
			st = rbl_read_sector(fs_unit, sector, secbuf);
		if (st == 1)
			break;
		++fs_retries;
	}
	return st;
}

unsigned char fs_find(const char *name83, fs_entry_t *e)
{
	unsigned int sec;
	unsigned char i, st;
	unsigned char *d;

	for (sec = DIR_FIRST; sec <= DIR_LAST; sec++) {
		st = read_sector(sec);
		if (st != 1)
			return FS_SIOERR;
		for (i = 0; i < 8; i++) {
			d = secbuf + (i << 4);
			if (d[0] == 0)
				return FS_NOTFOUND;     // never used: end of directory
			if ((d[0] & FLAG_DELETED) || !(d[0] & FLAG_INUSE))
				continue;
			if (memcmp(d + 5, name83, 11) == 0) {
				e->flag    = d[0];
				e->sectors = d[1] | (d[2] << 8);
				e->start   = d[3] | (d[4] << 8);
				e->fileno  = (unsigned char)(((sec - DIR_FIRST) << 3) + i);
				return FS_OK;
			}
		}
	}
	return FS_NOTFOUND;
}

unsigned char fs_load(const fs_entry_t *e, unsigned char *dst, unsigned int maxlen, fs_result_t *r)
{
	unsigned int sec = e->start;
	unsigned char cnt, st;

	r->bytes = 0;
	r->sectors = 0;
	r->sio_status = 1;
	r->bad_sector = 0;

	while (sec != 0) {
		st = read_sector(sec);
		if (st != 1) {
			r->sio_status = st;
			r->bad_sector = sec;
			return FS_SIOERR;
		}
		++r->sectors;

		if (!(e->flag & FLAG_NOFILENO) && (secbuf[125] >> 2) != e->fileno) {
			r->bad_sector = sec;
			return FS_BADLINK;
		}

		cnt = secbuf[127] & 0x7F;
		if (cnt > 125) {
			r->bad_sector = sec;
			return FS_BADLINK;
		}
		if (r->bytes + cnt > maxlen)
			return FS_TOOBIG;
		memcpy(dst + r->bytes, secbuf, cnt);
		r->bytes += cnt;
		if (fs_progress)
			fs_progress(r->bytes);

		if (e->flag & FLAG_NOFILENO)
			sec = (secbuf[125] << 8) | secbuf[126];
		else
			sec = ((secbuf[125] & 0x03) << 8) | secbuf[126];
	}
	return FS_OK;
}
