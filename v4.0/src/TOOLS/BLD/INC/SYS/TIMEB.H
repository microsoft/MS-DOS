/***
*sys\timeb.h - definition/declarations for ftime()
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file define the ftime() function and the types it uses.
*   [System V]
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define CDECL   cdecl
#else /* extensions not enabled */
    #define CDECL
#endif /* NO_EXT_KEYS */

#ifndef _TIME_T_DEFINED
typedef long time_t;
#define _TIME_T_DEFINED
#endif

/* structure returned by ftime system call */

#ifndef _TIMEB_DEFINED
struct timeb {
    time_t time;
    unsigned short millitm;
    short timezone;
    short dstflag;
    };
#define _TIMEB_DEFINED
#endif


/* function prototypes */

void CDECL ftime(struct timeb *);
