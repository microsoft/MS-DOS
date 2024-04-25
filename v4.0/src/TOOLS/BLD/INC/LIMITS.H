/***
*limits.h - implementation dependent values
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   contains defines for a number of implementation dependent values
*   which are commonly used in C programs.
*   [ANSI]
*
*******************************************************************************/

#ifndef _CHAR_UNSIGNED
#define CHAR_MAX         127            /* maximum char value */
#define CHAR_MIN        -127            /* mimimum char value */
#else
#define CHAR_MAX         255
#define CHAR_MIN         0
#endif
#define SCHAR_MAX        127            /* maximum signed char value */
#define SCHAR_MIN       -127            /* minimum signed char value */
#define UCHAR_MAX        255            /* maximum unsigned char value */
#define CHAR_BIT         8              /* number of bits in a char */
#define USHRT_MAX        0xffff         /* maximum unsigned short value */
#define SHRT_MAX         32767          /* maximum (signed) short value */
#define SHRT_MIN        -32767          /* minimum (signed) short value */
#define UINT_MAX         0xffff         /* maximum unsigned int value */
#define ULONG_MAX        0xffffffff     /* maximum unsigned long value */
#define INT_MAX          32767          /* maximum (signed) int value */
#define INT_MIN         -32767          /* minimum (signed) int value */
#define LONG_MAX         2147483647     /* maximum (signed) long value */
#define LONG_MIN        -2147483647     /* minimum (signed) long value */
