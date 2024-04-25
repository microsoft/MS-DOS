/***
*memory.h - declarations for buffer (memory) manipulation routines
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This include file contains the function declarations for the
*   buffer (memory) manipulation routines.
*   [System V]
*
*******************************************************************************/


#ifndef _SIZE_T_DEFINED
typedef unsigned int size_t;
#define _SIZE_T_DEFINED
#endif

#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
#else /* extensions not enabled */
    #define _CDECL
#endif /* NO_EXT_KEYS */


/* function prototypes */

void * _CDECL memccpy(void *, void *, int, unsigned int);
void * _CDECL memchr(const void *, int, size_t);
int _CDECL memcmp(const void *, const void *, size_t);
void * _CDECL memcpy(void *, const void *, size_t);
int _CDECL memicmp(void *, void *, unsigned int);
void * _CDECL memset(void *, int, size_t);
void _CDECL movedata(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int);
