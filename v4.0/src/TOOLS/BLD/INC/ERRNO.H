/***
*errno.h - system wide error numbers (set by system calls)
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file defines the system-wide error numbers (set by
*   system calls).  Conforms to the XENIX standard.  Extended
*   for compatibility with Uniforum standard.
*   [System V]
*
*******************************************************************************/

#define  EZERO      0
#define  EPERM      1
#define  ENOENT     2
#define  ESRCH      3
#define  EINTR      4
#define  EIO        5
#define  ENXIO      6
#define  E2BIG      7
#define  ENOEXEC    8
#define  EBADF      9
#define  ECHILD    10
#define  EAGAIN    11
#define  ENOMEM    12
#define  EACCES    13
#define  EFAULT    14
#define  ENOTBLK   15
#define  EBUSY     16
#define  EEXIST    17
#define  EXDEV     18
#define  ENODEV    19
#define  ENOTDIR   20
#define  EISDIR    21
#define  EINVAL    22
#define  ENFILE    23
#define  EMFILE    24
#define  ENOTTY    25
#define  ETXTBSY   26
#define  EFBIG     27
#define  ENOSPC    28
#define  ESPIPE    29
#define  EROFS     30
#define  EMLINK    31
#define  EPIPE     32
#define  EDOM      33
#define  ERANGE    34
#define  EUCLEAN   35
#define  EDEADLOCK 36
