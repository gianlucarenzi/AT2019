#ifndef __DOS2FS_H__
#define __DOS2FS_H__

/*
 * Minimal read only DOS 2.x / MyDOS filesystem, directly on SIO.
 * No DOS needed in memory: the disk can be booted by MyPicoDos.
 */

#define FS_OK           0
#define FS_NOTFOUND     1
#define FS_SIOERR       2
#define FS_TOOBIG       3
#define FS_BADLINK      4

typedef struct {
	unsigned char  flag;
	unsigned int   sectors;
	unsigned int   start;
	unsigned char  fileno;
} fs_entry_t;

typedef struct {
	unsigned int   bytes;      /* bytes loaded */
	unsigned int   sectors;    /* sectors read */
	unsigned char  sio_status; /* last DSTATS on error */
	unsigned int   bad_sector; /* sector that failed */
} fs_result_t;

unsigned char __fastcall__ sio_read_sector(unsigned char unit, unsigned int sector, void *buf);
unsigned char __fastcall__ rbl_read_sector(unsigned char unit, unsigned int sector, void *buf);

#define FS_LOADER_RBL   0   /* own IRQ driven SIO (default, music safe) */
#define FS_LOADER_OS    1   /* OS SIOV */

/* name83: 11 chars, blank padded, e.g. "T02K    DAT" */
unsigned char fs_find(const char *name83, fs_entry_t *e);
unsigned char fs_load(const fs_entry_t *e, unsigned char *dst, unsigned int maxlen, fs_result_t *r);

extern unsigned char fs_unit;
extern unsigned char fs_loader;       /* FS_LOADER_xxx */
extern unsigned int fs_retries;      /* failed sector reads (retried) */

/* optional: called after every sector with the bytes loaded so far */
extern void (*fs_progress)(unsigned int bytes);

#endif
