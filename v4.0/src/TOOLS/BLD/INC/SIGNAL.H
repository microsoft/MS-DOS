/***
*signal.h - defines signal values and routines
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file defines the signal values and declares the signal functions.
*   [ANSI/System V]
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
#else /* extensions not enabled */
    #define _CDECL
#endif /* NO_EXT_KEYS */

#ifndef _SIG_ATOMIC_T_DEFINED
typedef int sig_atomic_t;
#define _SIG_ATOMIC_T_DEFINED
#endif


#define NSIG 23     /* maximum signal number + 1 */

/* signal types */
/* SIGINT, SIGFPE, SIGILL, SIGSEGV, and SIGABRT are recognized on DOS 3.x */

#define SIGINT      2   /* interrupt - corresponds to DOS 3.x int 23H */
#define SIGILL      4   /* illegal instruction - invalid function image */
#define SIGFPE      8   /* floating point exception */
#define SIGSEGV     11  /* segment violation */
#define SIGTERM     15  /* Software termination signal from kill */
#define SIGUSR1     16  /* User defined signal 1 */
#define SIGUSR2     17  /* User defined signal 2 */
#define SIGUSR3     20  /* User defined signal 3 */
#define SIGBREAK    21  /* Ctrl-Break sequence */
#define SIGABRT     22  /* abnormal termination triggered by abort call */


/* signal action codes */
/* SIG_DFL and SIG_IGN are recognized on DOS 3.x */

#define SIG_DFL (void (*)())0 /* default signal action */
#define SIG_IGN (void (*)())1 /* ignore */
#define SIG_SGE (void (*)())3 /* signal gets error */
#define SIG_ACK (void (*)())4 /* error if handler not setup */


/* signal error value (returned by signal call on error) */

#define SIG_ERR (void (*)())-1    /* signal error value */


/* function prototypes */

void (_CDECL * _CDECL signal(int, void (_CDECL *)()))();
int _CDECL raise(int);
