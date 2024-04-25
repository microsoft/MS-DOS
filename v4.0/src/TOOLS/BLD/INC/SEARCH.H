/***
*search.h - declarations for searcing/sorting routines
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file contains the declarations for the sorting and
*   searching routines.
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

char * _CDECL lsearch(char *, char *, unsigned int *, unsigned int, int (_CDECL *)(void *, void *));
char * _CDECL lfind(char *, char *, unsigned int *, unsigned int, int (_CDECL *)(void *, void *));
void * _CDECL bsearch(const void *, const void *, size_t, size_t, int (_CDECL *)(const void *, const void *));
void _CDECL qsort(void *, size_t, size_t, int (_CDECL *)(const void *, const void *));
