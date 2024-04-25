/***
*bios.h - declarations for bios interface functions and supporting definitions
*
*   Copyright (c) 1987-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file declares the constants, structures, and functions
*   used for accessing and using various BIOS interfaces.
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
#else   /* extensions not enabled */
    #define _CDECL
#endif  /* NO_EXT_KEYS */

/* manifest constants for BIOS serial communications (RS-232) support */

/* serial port services */

#define _COM_INIT       0   /* init serial port */
#define _COM_SEND       1   /* send character */
#define _COM_RECEIVE    2   /* receive character */
#define _COM_STATUS     3   /* get serial port status */

/* serial port initializers.  One and only one constant from each of the
 * following four groups - character size, stop bit, parity, and baud rate -
 * must be specified in the initialization byte.
 */

/* character size initializers */

#define _COM_CHR7       2   /* 7 bits characters */
#define _COM_CHR8       3   /* 8 bits characters */

/* stop bit values - on or off */

#define _COM_STOP1      0   /* 1 stop bit */
#define _COM_STOP2      4   /* 2 stop bits */

/*  parity initializers */

#define _COM_NOPARITY   0   /* no parity */
#define _COM_ODDPARITY  8   /* odd parity */
#define _COM_EVENPARITY 24  /* even parity */

/*  baud rate initializers */

#define _COM_110        0       /* 110 baud */
#define _COM_150        32      /* 150 baud */
#define _COM_300        64      /* 300 baud */
#define _COM_600        96      /* 600 baud */
#define _COM_1200       128     /* 1200 baud */
#define _COM_2400       160     /* 2400 baud */
#define _COM_4800       192     /* 4800 baud */
#define _COM_9600       224     /* 9600 baud */


/* manifest constants for BIOS disk support */

/* disk services */

#define _DISK_RESET     0   /* reset disk controller */
#define _DISK_STATUS    1   /* get disk status */
#define _DISK_READ      2   /* read disk sectors */
#define _DISK_WRITE     3   /* write disk sectors */
#define _DISK_VERIFY    4   /* verify disk sectors */
#define _DISK_FORMAT    5   /* format disk track */

/* struct used to send/receive information to/from the BIOS disk services */

#ifndef NO_EXT_KEYS     /* extensions must be enabled */

#ifndef _DISKINFO_T_DEFINED

struct diskinfo_t {
    unsigned drive;
    unsigned head;
    unsigned track;
    unsigned sector;
    unsigned nsectors;
    void far *buffer;
    };

#define _DISKINFO_T_DEFINED

#endif

#endif /* NO_EXT_KEYS */


/* manifest constants for BIOS keyboard support */

/* keyboard services */

#define _KEYBRD_READ        0   /* read next character from keyboard */
#define _KEYBRD_READY       1   /* check for keystroke */
#define _KEYBRD_SHIFTSTATUS 2   /* get current shift key status */


/* manifest constants for BIOS printer support */

/* printer services */

#define _PRINTER_WRITE  0   /* write character to printer */
#define _PRINTER_INIT   1   /* intialize printer */
#define _PRINTER_STATUS 2   /* get printer status */


/* manifest constants for BIOS time of day support */

/* time of day services */

#define _TIME_GETCLOCK  0   /* get current clock count */
#define _TIME_SETCLOCK  1   /* set current clock count */


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

#endif /* _REGS_DEFINED */


/* function prototypes */

unsigned _CDECL _bios_equiplist(void);
unsigned _CDECL _bios_keybrd(unsigned);
unsigned _CDECL _bios_memsize(void);
unsigned _CDECL _bios_printer(unsigned, unsigned, unsigned);
unsigned _CDECL _bios_serialcom(unsigned, unsigned, unsigned);
unsigned _CDECL _bios_timeofday(unsigned, long *);
int _CDECL int86(int, union REGS *, union REGS *);
int _CDECL int86x(int, union REGS *, union REGS *, struct SREGS *);

#ifndef NO_EXT_KEYS     /* extensions must be enabled */

unsigned _CDECL _bios_disk(unsigned, struct diskinfo_t *);

#endif /* NO_EXT_KEYS */
