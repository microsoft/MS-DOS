/***
*sys\stat.h - defines structure used by stat() and fstat()
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file defines the structure used by the stat() and fstat()
*   routines.
*   [System V]
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define CDECL   cdecl
#else /* extensions not enabled */
    #define CDECL
#endif /* NO_EXT_KEYS */

#ifndef _TIME_T_DEFINED
typedef long time_t;
#define _TIME_T_DEFINED
#endif

/* define structure for returning status information */

#ifndef _STAT_DEFINED
struct stat {
    dev_t st_dev;
    ino_t st_ino;
    unsigned short st_mode;
    short st_nlink;
    short st_uid;
    short st_gid;
    dev_t st_rdev;
    off_t st_size;
    time_t st_atime;
    time_t st_mtime;
    time_t st_ctime;
    };
#define _STAT_DEFINED
#endif

#define S_IFMT      0170000         /* file type mask */
#define S_IFDIR     0040000         /* directory */
#define S_IFCHR     0020000         /* character special */
#define S_IFREG     0100000         /* regular */
#define S_IREAD     0000400         /* read permission, owner */
#define S_IWRITE    0000200         /* write permission, owner */
#define S_IEXEC     0000100         /* execute/search permission, owner */


/* function prototypes */

int CDECL fstat(int, struct stat *);
int CDECL stat(char *, struct stat *);
