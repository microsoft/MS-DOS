/*
 *  tools.h - Header file for accessing TOOLS.LIB routines
 *  includes stdio.h and ctype.h
 *
 *   4/14/86  dl added U_* flags for upd return values
 *
 *	31-Jul-1986 mz	Add Connect definitions
 */

#define TRUE	-1
#define FALSE	0

#if MSDOS
#define     PSEPSTR "\\"
#define     PSEPCHR '\\'
#else
#define     PSEPSTR "/"
#define     PSEPCHR '/'
#endif

typedef char flagType;
typedef long ptrType;

#define SETFLAG(l,f)	((l) |= (f))
#define TESTFLAG(v,f)	(((v)&(f))!=0)
#define RSETFLAG(l,f)	((l) &= ~(f))

#define SHIFT(c,v)	{c--; v++;}

#define LOW(w)		((int)(w)&0xFF)
#define HIGH(w) 	LOW((int)(w)>>8)
#define WORD(h,l)	((LOW((h))<<8)|LOW((l)))
#define POINTER(seg,off) ((((long)(seg))<<4)+ (long)(off))

#define FNADDR(f)	(f)

#define SELECT		if(FALSE){
#define CASE(x) 	}else if((x)){
#define OTHERWISE	}else{
#define ENDSELECT	}

/* buffer description for findfirst and findnext */

struct findType {
    char reserved[21];			/* reserved for start up	     */
    char attr;				/* attribute found		     */
    unsigned time;			/* time of last modify		     */
    unsigned date;			/* date of last modify		     */
    long length;			/* file size			     */
    char name[13];			/* asciz file name		     */
};

/* attributes */
#define A_RO	1			/* read only			     */
#define A_H	2			/* hidden			     */
#define A_S	4			/* system			     */
#define A_V	8			/* volume id			     */
#define A_D	16			/* directory			     */
#define A_A	32			/* archive			     */

#define A_MOD	(A_RO+A_H+A_S+A_A)	/* changeable attributes	     */

#define HASATTR(a,v)	TESTFLAG(a,v)	/* true if a has attribute v	     */

extern char XLTab[], XUTab[];

#define MAXARG	128
#define MAXPATHLEN  128

#include "ttypes.h"

struct vectorType {
    int max;				/* max the vector can hold	     */
    int count;				/* count of elements in vector	     */
    unsigned elem[1];			/* elements in vector		     */
};

/* return flags for upd */
#define U_DRIVE 0x8
#define U_PATH	0x4
#define U_NAME	0x2
#define U_EXT	0x1

/*  Connect definitions */

#define REALDRIVE	0x8000
#define ISTMPDRIVE(x)	(((x)&REALDRIVE)==0)
#define TOKTODRV(x)	((x)&~REALDRIVE)

/*  Heap Checking return codes */

#define HEAPOK           0
#define HEAPBADBEGIN    -1
#define HEAPBADNODE     -2
