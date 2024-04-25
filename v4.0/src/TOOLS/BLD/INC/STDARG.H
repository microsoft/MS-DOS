/***
*stdarg.h - defines ANSI-style macros for variable argument functions
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file defines ANSI-style macros for accessing arguments
*   of functions which take a variable number of arguments.
*   [ANSI]
*
*******************************************************************************/

#ifndef _VA_LIST_DEFINED
typedef char *va_list;
#define _VA_LIST_DEFINED
#endif

#define va_start(ap,v) ap = (va_list)&v + sizeof(v)
#define va_arg(ap,t) ((t *)(ap += sizeof(t)))[-1]
#define va_end(ap) ap = NULL
