/***
*float.h - constants for floating point values
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file contains defines for a number of implementation dependent
*   values which are commonly used by sophisticated numerical (floating
*   point) programs.
*   [ANSI]
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
#else /* extensions not enabled */
    #define _CDECL
#endif /* NO_EXT_KEYS */

#define DBL_DIG         15                      /* # of decimal digits of precision */
#define DBL_EPSILON     2.2204460492503131e-016 /* smallest such that 1.0+DBL_EPSILON != 1.0 */
#define DBL_MANT_DIG    53                      /* # of bits in mantissa */
#define DBL_MAX         1.7976931348623158e+308 /* max value */
#define DBL_MAX_10_EXP  308                     /* max decimal exponent */
#define DBL_MAX_EXP     1024                    /* max binary exponent */
#define DBL_MIN         2.2250738585072014e-308 /* min positive value */
#define DBL_MIN_10_EXP  -307                    /* min decimal exponent
#define DBL_MIN_EXP     -1021                   /* min binary exponent */
#define DBL_RADIX       2                       /* exponent radix */
#define DBL_ROUNDS      0                       /* addition rounding: chops */

#define FLT_DIG         6                       /* # of decimal digits of precision */
#define FLT_EPSILON     1.192092896e-07         /* smallest such that 1.0+FLT_EPSILON != 1.0 */
#define FLT_GUARD       0
#define FLT_MANT_DIG    24                      /* # of bits in mantissa */
#define FLT_MAX         3.402823466e+38         /* max value */
#define FLT_MAX_10_EXP  38                      /* max decimal exponent */
#define FLT_MAX_EXP     128                     /* max binary exponent */
#define FLT_MIN         1.175494351e-38         /* min positive value */
#define FLT_MIN_10_EXP  -37                     /* min decimal exponent */
#define FLT_MIN_EXP     -125                    /* min binary exponent */
#define FLT_NORMALIZE   0
#define FLT_RADIX       2                       /* exponent radix */
#define FLT_ROUNDS      0                       /* addition rounding: chops */

#define LDBL_DIG        DBL_DIG                 /* # of decimal digits of precision */
#define LDBL_EPSILON    DBL_EPSILON             /* smallest such that 1.0+LDBL_EPSILON != 1.0 */
#define LDBL_MANT_DIG   DBL_MANT_DIG            /* # of bits in mantissa */
#define LDBL_MAX        DBL_MAX                 /* max value */
#define LDBL_MAX_10_EXP DBL_MAX_10_EXP          /* max decimal exponent */
#define LDBL_MAX_EXP    DBL_MAX_EXP             /* max binary exponent */
#define LDBL_MIN        DBL_MIN                 /* min positive value */
#define LDBL_MIN_10_EXP DBL_MIN_10_EXP          /* min deimal exponent
#define LDBL_MIN_EXP    DBL_MIN_EXP             /* min binary exponent */
#define LDBL_RADIX      DBL_RADIX               /* exponent radix */
#define LDBL_ROUNDS     DBL_ROUNDS              /* addition rounding: chops */


/*
 *  8087/80287 math control information
 */


/* User Control Word Mask and bit definitions.
 * These definitions match the 8087/80287
 */

#define     MCW_EM          0x003f      /* interrupt Exception Masks */
#define     EM_INVALID      0x0001      /*   invalid */
#define     EM_DENORMAL     0x0002      /*   denormal */
#define     EM_ZERODIVIDE   0x0004      /*   zero divide */
#define     EM_OVERFLOW     0x0008      /*   overflow */
#define     EM_UNDERFLOW    0x0010      /*   underflow */
#define     EM_INEXACT      0x0020      /*   inexact (precision) */

#define     MCW_IC          0x1000      /* Infinity Control */
#define     IC_AFFINE       0x1000      /*   affine */
#define     IC_PROJECTIVE   0x0000      /*   projective */

#define     MCW_RC          0x0c00      /* Rounding Control */
#define     RC_CHOP         0x0c00      /*   chop */
#define     RC_UP           0x0800      /*   up */
#define     RC_DOWN         0x0400      /*   down */
#define     RC_NEAR         0x0000      /*   near */

#define     MCW_PC          0x0300      /* Precision Control */
#define     PC_24           0x0000      /*    24 bits */
#define     PC_53           0x0200      /*    53 bits */
#define     PC_64           0x0300      /*    64 bits */


/* initial Control Word value */

#define CW_DEFAULT ( IC_AFFINE + RC_NEAR + PC_64 + EM_DENORMAL + EM_UNDERFLOW + EM_INEXACT )


/* user Status Word bit definitions */

#define SW_INVALID          0x0001      /*   invalid */
#define SW_DENORMAL         0x0002      /*   denormal */
#define SW_ZERODIVIDE       0x0004      /*   zero divide */
#define SW_OVERFLOW         0x0008      /*   overflow */
#define SW_UNDERFLOW        0x0010      /*   underflow */
#define SW_INEXACT          0x0020      /*   inexact (precision) */


/* invalid subconditions (SW_INVALID also set) */

#define SW_UNEMULATED       0x0040      /* unemulated instruction */
#define SW_SQRTNEG          0x0080      /* square root of a neg number */
#define SW_STACKOVERFLOW    0x0200      /* FP stack overflow */
#define SW_STACKUNDERFLOW   0x0400      /* FP stack underflow */


/*  Floating point error signals and return codes */

#define FPE_INVALID         0x81
#define FPE_DENORMAL        0x82
#define FPE_ZERODIVIDE      0x83
#define FPE_OVERFLOW        0x84
#define FPE_UNDERFLOW       0x85
#define FPE_INEXACT         0x86

#define FPE_UNEMULATED      0x87
#define FPE_SQRTNEG         0x88
#define FPE_STACKOVERFLOW   0x8a
#define FPE_STACKUNDERFLOW  0x8b

#define FPE_EXPLICITGEN     0x8c    /* raise( SIGFPE ); */

/* function prototypes */

unsigned int _CDECL _clear87(void);
unsigned int _CDECL _control87(unsigned int,unsigned int);
void _CDECL _fpreset(void);
unsigned int _CDECL _status87(void);
