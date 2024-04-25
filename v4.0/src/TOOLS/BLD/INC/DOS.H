/***
*dos.h - definitions for MS-DOS interface routines
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   Defines the structs and unions used for the direct DOS interface
*   routines; includes macros to access the segment and offset
*   values of far pointers, so that they may be used by the routines; and
*   provides function prototypes for direct DOS interface functions.
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
    #define _NEAR   near
#else /* extensions not enabled */
    #define _CDECL
    #define _NEAR
#endif /* NO_EXT_KEYS */


#ifndef _REGS_DEFINED

/* word registers */

struct WORDREGS {
    unsigned int ax;
    unsigned int bx;
    unsigned int cx;
    unsigned int dx;
    unsigned int si;
    unsigned int di;
    unsigned int cflag;
    };


/* byte registers */

struct BYTEREGS {
    unsigned char al, ah;
    unsigned char bl, bh;
    unsigned char cl, ch;
    unsigned char dl, dh;
    };


/* general purpose registers union -
 *  overlays the corresponding word and byte registers.
 */

union REGS {
    struct WORDREGS x;
    struct BYTEREGS h;
    };


/* segment registers */

struct SREGS {
    unsigned int es;
    unsigned int cs;
    unsigned int ss;
    unsigned int ds;
    };

#define _REGS_DEFINED

#endif


/* dosexterror structure */

#ifndef _DOSERROR_DEFINED

struct DOSERROR {
    int exterror;
    char class;
    char action;
    char locus;
    };

#define _DOSERROR_DEFINED

#endif


/* _dos_findfirst structure */

#ifndef _FIND_T_DEFINED

struct find_t {
    char reserved[21];
    char attrib;
    unsigned wr_time;
    unsigned wr_date;
    long size;
    char name[13];
    };

#define _FIND_T_DEFINED

#endif


/* _dos_getdate/_dossetdate and _dos_gettime/_dos_settime structures */

#ifndef _DATETIME_T_DEFINED

struct dosdate_t {
    unsigned char day;          /* 1-31 */
    unsigned char month;        /* 1-12 */
    unsigned int year;          /* 1980-2099 */
    unsigned char dayofweek;    /* 0-6, 0=Sunday */
    };

struct dostime_t {
    unsigned char hour;     /* 0-23 */
    unsigned char minute;   /* 0-59 */
    unsigned char second;   /* 0-59 */
    unsigned char hsecond;  /* 0-99 */
    };

#define _DATETIME_T_DEFINED

#endif


/* _dos_getdiskfree structure */

#ifndef _DISKFREE_T_DEFINED

struct diskfree_t {
    unsigned total_clusters;
    unsigned avail_clusters;
    unsigned sectors_per_cluster;
    unsigned bytes_per_sector;
    };

#define _DISKFREE_T_DEFINED

#endif


/* manifest constants for _hardresume result parameter */

#define _HARDERR_IGNORE     0   /* Ignore the error */
#define _HARDERR_RETRY      1   /* Retry the operation */
#define _HARDERR_ABORT      2   /* Abort program issuing Interrupt 23h */
#define _HARDERR_FAIL       3   /* Fail the system call in progress */
                                /* _HARDERR_FAIL is not supported on DOS 2.x */

/* File attribute constants */

#define _A_NORMAL       0x00    /* Normal file - No read/write restrictions */
#define _A_RDONLY       0x01    /* Read only file */
#define _A_HIDDEN       0x02    /* Hidden file */
#define _A_SYSTEM       0x04    /* System file */
#define _A_VOLID        0x08    /* Volume ID file */
#define _A_SUBDIR       0x10    /* Subdirectory */
#define _A_ARCH         0x20    /* Archive file */

/* macros to break MS C "far" pointers into their segment and offset
 * components
 */

#define FP_SEG(fp) (*((unsigned *)&(fp) + 1))
#define FP_OFF(fp) (*((unsigned *)&(fp)))


/* external variable declarations */

extern unsigned int _NEAR _CDECL _osversion;


/* function prototypes */

int _CDECL bdos(int, unsigned int, unsigned int);
void _CDECL _disable(void);
unsigned _CDECL _dos_allocmem(unsigned, unsigned *);
unsigned _CDECL _dos_close(int);
unsigned _CDECL _dos_creat(char *, unsigned, int *);
unsigned _CDECL _dos_creatnew(char *, unsigned, int *);
unsigned _CDECL _dos_findfirst(char *, unsigned, struct find_t *);
unsigned _CDECL _dos_findnext(struct find_t *);
unsigned _CDECL _dos_freemem(unsigned);
void _CDECL _dos_getdate(struct dosdate_t *);
void _CDECL _dos_getdrive(unsigned *);
unsigned _CDECL _dos_getdiskfree(unsigned, struct diskfree_t *);
unsigned _CDECL _dos_getfileattr(char *, unsigned *);
unsigned _CDECL _dos_getftime(int, unsigned *, unsigned *);
void _CDECL _dos_gettime(struct dostime_t *);
void _CDECL _dos_keep(unsigned, unsigned);
unsigned _CDECL _dos_open(char *, unsigned, int *);
unsigned _CDECL _dos_setblock(unsigned, unsigned, unsigned *);
unsigned _CDECL _dos_setdate(struct dosdate_t *);
void _CDECL _dos_setdrive(unsigned, unsigned *);
unsigned _CDECL _dos_setfileattr(char *, unsigned);
unsigned _CDECL _dos_setftime(int, unsigned, unsigned);
unsigned _CDECL _dos_settime(struct dostime_t *);
int _CDECL dosexterr(struct DOSERROR *);
void _CDECL _enable(void);
void _CDECL _hardresume(int);
void _CDECL _hardretn(int);
int _CDECL intdos(union REGS *, union REGS *);
int _CDECL intdosx(union REGS *, union REGS *, struct SREGS *);
int _CDECL int86(int, union REGS *, union REGS *);
int _CDECL int86x(int, union REGS *, union REGS *, struct SREGS *);
void _CDECL segread(struct SREGS *);


#ifndef NO_EXT_KEYS /* extensions enabled */
void _CDECL _chain_intr(void (_CDECL interrupt far *)());
void (_CDECL interrupt far * _CDECL _dos_getvect(unsigned))();
unsigned _CDECL _dos_read(int, void far *, unsigned, unsigned *);
void _CDECL _dos_setvect(unsigned, void (_CDECL interrupt far *)());
unsigned _CDECL _dos_write(int, void far *, unsigned, unsigned *);
void _CDECL _harderr(void (far *)());
#endif /* NO_EXT_KEYS */
