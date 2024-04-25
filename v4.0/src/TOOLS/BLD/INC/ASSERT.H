/***
*assert.h - define the assert macro
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   Defines the assert(exp) macro.
*   [ANSI/System V]
*
*******************************************************************************/


#ifndef _ASSERT_DEFINED

#ifndef NDEBUG

static char _assertstring[] = "Assertion failed: %s, file %s, line %d\n";

#define assert(exp) { \
    if (!(exp)) { \
        fprintf(stderr, _assertstring, #exp, __FILE__, __LINE__); \
        fflush(stderr); \
        abort(); \
        } \
    }

#else

#define assert(exp)

#endif /* NDEBUG */

#define _ASSERT_DEFINED

#endif /* _ASSERT_DEFINED */
