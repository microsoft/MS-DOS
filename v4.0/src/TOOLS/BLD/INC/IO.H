/***
*io.h - declarations for low-level file handling and I/O functions
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file contains the function declarations for the low-level
*   file handling and I/O functions.
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
#else /* extensions not enabled */
    #define _CDECL
#endif /* NO_EXT_KEYS */

/* function prototypes */

int _CDECL access(char *, int);
int _CDECL chmod(char *, int);
int _CDECL chsize(int, long);
int _CDECL close(int);
int _CDECL creat(char *, int);
int _CDECL dup(int);
int _CDECL dup2(int, int);
int _CDECL eof(int);
long _CDECL filelength(int);
int _CDECL isatty(int);
int _CDECL locking(int, int, long);
long _CDECL lseek(int, long, int);
char * _CDECL mktemp(char *);
int _CDECL open(char *, int, ...);
int _CDECL read(int, char *, unsigned int);
int _CDECL remove(const char *);
int _CDECL rename(const char *, const char *);
int _CDECL setmode(int, int);
int _CDECL sopen(char *, int, int, ...);
long _CDECL tell(int);
int _CDECL umask(int);
int _CDECL unlink(const char *);
int _CDECL write(int, char *, unsigned int);
