/***
*process.h - definition and declarations for process control functions
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file defines the modeflag values for spawnxx calls.  Only
*   P_WAIT and P_OVERLAY are currently implemented on DOS 2 & 3.
*   P_NOWAIT is also enabled on DOS 4.  Also contains the function
*   argument declarations for all process control related routines.
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
    #define _NEAR   near
#else /* extensions not enabled */
    #define _CDECL
    #define _NEAR
#endif /* NO_EXT_KEYS */


/* modeflag values for spawnxx routines */

extern int _NEAR _CDECL _p_overlay;

#define P_WAIT      0
#define P_NOWAIT    1
#define P_OVERLAY   _p_overlay
#define OLD_P_OVERLAY  2
#define P_NOWAITO   3


/* Action Codes used with Cwait() */

#define WAIT_CHILD 0
#define WAIT_GRANDCHILD 1


/* function prototypes */

void _CDECL abort(void);
int _CDECL cwait(int *, int, int);
int _CDECL execl(char *, char *, ...);
int _CDECL execle(char *, char *, ...);
int _CDECL execlp(char *, char *, ...);
int _CDECL execlpe(char *, char *, ...);
int _CDECL execv(char *, char * *);
int _CDECL execve(char *, char * *, char * *);
int _CDECL execvp(char *, char * *);
int _CDECL execvpe(char *, char * *, char * *);
void _CDECL exit(int);
void _CDECL _exit(int);
int _CDECL getpid(void);
int _CDECL spawnl(int, char *, char *, ...);
int _CDECL spawnle(int, char *, char *, ...);
int _CDECL spawnlp(int, char *, char *, ...);
int _CDECL spawnlpe(int, char *, char *, ...);
int _CDECL spawnv(int, char *, char * *);
int _CDECL spawnve(int, char *, char * *, char * *);
int _CDECL spawnvp(int, char *, char * *);
int _CDECL spawnvpe(int, char *, char * *, char * *);
int _CDECL system(const char *);
int _CDECL wait(int *);
