/***
*direct.h - function declarations for directory handling/creation
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This include file contains the function declarations for the library
*   functions related to directory handling and creation.
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
#else /* extensions not enabled */
    #define _CDECL
#endif /* NO_EXT_KEYS */

/* function prototypes */

int _CDECL chdir(char *);
char * _CDECL getcwd(char *, int);
int _CDECL mkdir(char *);
int _CDECL rmdir(char *);
