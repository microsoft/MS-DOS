/***
*stdlib.h - declarations/definitions for commonly used library functions
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This include file contains the function declarations for
*   commonly used library functions which either don't fit somewhere
*   else, or, like toupper/tolower, can't be declared in the normal
*   place (ctype.h in the case of toupper/tolower) for other reasons.
*   [ANSI]
*
*******************************************************************************/


#ifndef _SIZE_T_DEFINED
typedef unsigned int size_t;
#define _SIZE_T_DEFINED
#endif

#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
    #define _NEAR   near
#else /* extensions not enabled */
    #define _CDECL
    #define _NEAR
#endif /* NO_EXT_KEYS */


/* definition of the return type for the onexit() function */

#ifndef _ONEXIT_T_DEFINED
typedef int (_CDECL * _CDECL onexit_t)();
#define _ONEXIT_T_DEFINED
#endif


/* Data structure definitions for div and ldiv runtimes. */

#ifndef _DIV_T_DEFINED

typedef struct {
    int quot;
    int rem;
} div_t;

typedef struct {
    long quot;
    long rem;
} ldiv_t;

#define _DIV_T_DEFINED
#endif

/* Maximum value that can be returned by the rand function. */

#define RAND_MAX 0x7fff


/* min and max macros */

#define max(a,b)    (((a) > (b)) ? (a) : (b))
#define min(a,b)    (((a) < (b)) ? (a) : (b))


/* sizes for buffers used by the _makepath() and _splitpath() functions.
 * note that the sizes include space for 0-terminator
 */

#define _MAX_PATH      144      /* max. length of full pathname */
#define _MAX_DRIVE   3      /* max. length of drive component */
#define _MAX_DIR       130      /* max. length of path component */
#define _MAX_FNAME   9      /* max. length of file name component */
#define _MAX_EXT     5      /* max. length of extension component */

/* external variable declarations */

extern int _NEAR _CDECL errno;              /* XENIX style error number */
extern int _NEAR _CDECL _doserrno;          /* MS-DOS system error value */
extern char * _NEAR _CDECL sys_errlist[];   /* perror error message table */
extern int _NEAR _CDECL sys_nerr;           /* # of entries in sys_errlist table */

extern char ** _NEAR _CDECL environ;        /* pointer to environment table */

extern unsigned int _NEAR _CDECL _psp;      /* Program Segment Prefix */

extern int _NEAR _CDECL _fmode;             /* default file translation mode */

/* DOS major/minor version numbers */

extern unsigned char _NEAR _CDECL _osmajor;
extern unsigned char _NEAR _CDECL _osminor;

#define DOS_MODE    0   /* Real Address Mode */
#define OS2_MODE    1   /* Protected Address Mode */

extern unsigned char _NEAR _CDECL _osmode;


/* function prototypes */

double _CDECL atof(const char *);
double _CDECL strtod(const char *, char * *);
ldiv_t _CDECL ldiv(long, long);

void   _CDECL abort(void);
int    _CDECL abs(int);
int    _CDECL atexit(void (_CDECL *)(void));
int    _CDECL atoi(const char *);
long   _CDECL atol(const char *);
void * _CDECL bsearch(const void *, const void *, size_t, size_t, int (_CDECL *)(const void *, const void *));
void * _CDECL calloc(size_t, size_t);
div_t  _CDECL div(int, int);
char * _CDECL ecvt(double, int, int *, int *);
void   _CDECL exit(int);
void   _CDECL _exit(int);
char * _CDECL fcvt(double, int, int *, int *);
void   _CDECL free(void *);
char * _CDECL gcvt(double, int, char *);
char * _CDECL getenv(const char *);
char * _CDECL itoa(int, char *, int);
long   _CDECL labs(long);
unsigned long _CDECL _lrotl(unsigned long, int);
unsigned long _CDECL _lrotr(unsigned long, int);
char * _CDECL ltoa(long, char *, int);
void   _CDECL _makepath(char *, char *, char *, char *, char *);
void * _CDECL malloc(size_t);
onexit_t _CDECL onexit(onexit_t);
void   _CDECL perror(const char *);
int    _CDECL putenv(char *);
void   _CDECL qsort(void *, size_t, size_t, int (_CDECL *)(const void *, const void *));
unsigned int _CDECL _rotl(unsigned int, int);
unsigned int _CDECL _rotr(unsigned int, int);
int    _CDECL rand(void);
void * _CDECL realloc(void *, size_t);
void   _CDECL _searchenv(char *, char *, char *);
void   _CDECL _splitpath(char *, char *, char *, char *, char *);
void   _CDECL srand(unsigned int);
long   _CDECL strtol(const char *, char * *, int);
unsigned long _CDECL strtoul(const char *, char * *, int);
void   _CDECL swab(char *, char *, int);
int    _CDECL system(const char *);
char * _CDECL ultoa(unsigned long, char *, int);

#ifndef tolower         /* tolower has been undefined - use function */
int _CDECL tolower(int);
#endif  /* tolower */

#ifndef toupper         /* toupper has been undefined - use function */
int    _CDECL toupper(int);
#endif  /* toupper */
