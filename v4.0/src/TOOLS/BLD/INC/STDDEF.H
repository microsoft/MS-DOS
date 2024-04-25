/***
*stddef.h - definitions/declarations for common constants, types, variables
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file contains definitions and declarations for some commonly
*   used constants, types, and variables.
*   [ANSI]
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
    #define _NEAR   near
#else /* extensions not enabled */
    #define _CDECL
    #define _NEAR
#endif /* NO_EXT_KEYS */


/* define NULL pointer value */

#if (defined(M_I86SM) || defined(M_I86MM))
#define  NULL    0
#elif (defined(M_I86CM) || defined(M_I86LM) || defined(M_I86HM))
#define  NULL    0L
#endif


/* declare reference to errno */

extern int _NEAR _CDECL errno;


/* define the implementation dependent size types */

#ifndef _PTRDIFF_T_DEFINED
typedef int ptrdiff_t;
#define _PTRDIFF_T_DEFINED
#endif

#ifndef _SIZE_T_DEFINED
typedef unsigned int size_t;
#define _SIZE_T_DEFINED
#endif

