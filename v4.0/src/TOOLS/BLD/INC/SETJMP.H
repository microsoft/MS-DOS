/***
*setjmp.h - definitions/declarations for setjmp/longjmp routines
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file defines the machine-dependent buffer used by
*   setjmp/longjmp to save and restore the program state, and
*   declarations for those routines.
*   [ANSI/System V]
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
#else /* extensions not enabled */
    #define _CDECL
#endif /* NO_EXT_KEYS */


/* define the buffer type for holding the state information */

#define _JBLEN  9  /* bp, di, si, sp, ret addr, ds */

#ifndef _JMP_BUF_DEFINED
typedef  int  jmp_buf[_JBLEN];
#define _JMP_BUF_DEFINED
#endif


/* function prototypes */

int _CDECL setjmp(jmp_buf);
void _CDECL longjmp(jmp_buf, int);
