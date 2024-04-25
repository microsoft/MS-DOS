/***
*stdio.h - definitions/declarations for standard I/O routines
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file defines the structures, values, macros, and functions
*   used by the level 2 I/O ("standard I/O") routines.
*   [ANSI/System V]
*
*******************************************************************************/


#ifndef _SIZE_T_DEFINED
typedef unsigned int size_t;
#define _SIZE_T_DEFINED
#endif

#ifndef _VA_LIST_DEFINED
typedef char *va_list;
#define _VA_LIST_DEFINED
#endif

#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
    #define _NEAR   near
#else /* extensions not enabled */
    #define _CDECL
    #define _NEAR
#endif /* NO_EXT_KEYS */


/* buffered I/O macros */

#define  BUFSIZ  512
#define  _NFILE  20
#define  EOF     (-1)

#ifndef _FILE_DEFINED
#define  FILE    struct _iobuf
#define _FILE_DEFINED
#endif

/* P_tmpnam: Directory where temporary files may be created.
 * L_tmpnam size =  size of P_tmpdir
 *      + 1 (in case P_tmpdir does not end in "\\")
 *      + 6 (for the temp number string)
 *      + 1 (for the null terminator)
 */

#define  P_tmpdir "\\"
#define  L_tmpnam sizeof(P_tmpdir)+8

#define  SEEK_CUR 1
#define  SEEK_END 2
#define  SEEK_SET 0

#define  SYS_OPEN 20
#define  TMP_MAX  32767


/* define NULL pointer value */

#if (defined(M_I86SM) || defined(M_I86MM))
#define  NULL    0
#elif (defined(M_I86CM) || defined(M_I86LM) || defined(M_I86HM))
#define  NULL    0L
#endif


/* define file control block */

#ifndef _IOB_DEFINED
extern FILE {
    char *_ptr;
    int   _cnt;
    char *_base;
    char  _flag;
    char  _file;
    } _NEAR _CDECL _iob[];
#define _IOB_DEFINED
#endif

#define  fpos_t  long   /* file position variable */

#define  stdin  (&_iob[0])
#define  stdout (&_iob[1])
#define  stderr (&_iob[2])
#define  stdaux (&_iob[3])
#define  stdprn (&_iob[4])

#define  _IOREAD    0x01
#define  _IOWRT     0x02

#define  _IOFBF     0x0
#define  _IOLBF     0x40
#define  _IONBF     0x04

#define  _IOMYBUF   0x08
#define  _IOEOF     0x10
#define  _IOERR     0x20
#define  _IOSTRG    0x40
#define  _IORW      0x80

#define getc(f)         (--(f)->_cnt >= 0 ? 0xff & *(f)->_ptr++ : _filbuf(f))
#define putc(c,f)       (--(f)->_cnt >= 0 ? 0xff & (*(f)->_ptr++ = (char)(c)) \
                        :  _flsbuf((c),(f)))
#define getchar()       getc(stdin)
#define putchar(c)      putc((c),stdout)

#define feof(f)         ((f)->_flag & _IOEOF)
#define ferror(f)       ((f)->_flag & _IOERR)
#define fileno(f)       ((f)->_file)


/* function prototypes */

int _CDECL _filbuf(FILE *);
int _CDECL _flsbuf(int, FILE *);
void _CDECL clearerr(FILE *);
int _CDECL fclose(FILE *);
int _CDECL fcloseall(void);
FILE * _CDECL fdopen(int, char *);
int _CDECL fflush(FILE *);
int _CDECL fgetc(FILE *);
int _CDECL fgetchar(void);
int _CDECL fgetpos(FILE *, fpos_t *);
char * _CDECL fgets(char *, int, FILE *);
int _CDECL flushall(void);
FILE * _CDECL fopen(const char *, const char *);
int _CDECL fprintf(FILE *, const char *, ...);
int _CDECL fputc(int, FILE *);
int _CDECL fputchar(int);
int _CDECL fputs(const char *, FILE *);
size_t _CDECL fread(void *, size_t, size_t, FILE *);
FILE * _CDECL freopen(const char *, const char *, FILE *);
int _CDECL fscanf(FILE *, const char *, ...);
int _CDECL fsetpos(FILE *, const fpos_t *);
int _CDECL fseek(FILE *, long, int);
long _CDECL ftell(FILE *);
size_t _CDECL fwrite(const void *, size_t, size_t, FILE *);
char * _CDECL gets(char *);
int _CDECL getw(FILE *);
void _CDECL perror(const char *);
int _CDECL printf(const char *, ...);
int _CDECL puts(const char *);
int _CDECL putw(int, FILE *);
int _CDECL remove(const char *);
int _CDECL rename(const char *, const char *);
void _CDECL rewind(FILE *);
int _CDECL rmtmp(void);
int _CDECL scanf(const char *, ...);
void _CDECL setbuf(FILE *, char *);
int _CDECL setvbuf(FILE *, char *, int, size_t);
int _CDECL sprintf(char *, const char *, ...);
int _CDECL sscanf(const char *, const char *, ...);
char * _CDECL tempnam(char *, char *);
FILE * _CDECL tmpfile(void);
char * _CDECL tmpnam(char *);
int _CDECL ungetc(int, FILE *);
int _CDECL unlink(const char *);
int _CDECL vfprintf(FILE *, const char *, va_list);
int _CDECL vprintf(const char *, va_list);
int _CDECL vsprintf(char *, const char *, va_list);

