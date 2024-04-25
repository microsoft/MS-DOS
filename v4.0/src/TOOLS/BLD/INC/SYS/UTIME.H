/***
*sys\utime.h - definitions/declarations for utime()
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file defines the structure used by the utime routine to set
*   new file access and modification times.  NOTE - MS-DOS
*   does not recognize access time, so this field will
*   always be ignored and the modification time field will be
*   used to set the new time.
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

/* define struct used by utime() function */

#ifndef _UTIMBUF_DEFINED
struct utimbuf {
    time_t actime;      /* access time */
    time_t modtime;     /* modification time */
    };
#define _UTIMBUF_DEFINED
#endif


/* function prototypes */

int CDECL utime(char *, struct utimbuf *);
