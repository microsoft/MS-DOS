/***
*conio.h - console and port I/O declarations
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This include file contains the function declarations for
*   the MS C V2.03 compatible console and port I/O routines.
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
#else /* extensions not enabled */
    #define _CDECL
#endif /* NO_EXT_KEYS */

/* function prototypes */

char * _CDECL cgets(char *);
int _CDECL cprintf(char *, ...);
int _CDECL cputs(char *);
int _CDECL cscanf(char *, ...);
int _CDECL getch(void);
int _CDECL getche(void);
int _CDECL inp(unsigned int);
unsigned _CDECL inpw(unsigned int);
int _CDECL kbhit(void);
int _CDECL outp(unsigned int, int);
unsigned _CDECL outpw(unsigned int, unsigned int);
int _CDECL putch(int);
int _CDECL ungetch(int);

