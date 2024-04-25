/***
*math.h - definitions and declarations for math library
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   This file contains constant definitions and external subroutine
*   declarations for the math subroutine library.
*   [ANSI/System V]
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL   cdecl
#else /* extensions not enabled */
    #define _CDECL
#endif /* NO_EXT_KEYS */


/* definition of exception struct - this struct is passed to the matherr
 * routine when a floating point exception is detected
 */

#ifndef _EXCEPTION_DEFINED
struct exception {
    int type;           /* exception type - see below */
    char *name;   /* name of function where error occured */
    double arg1;        /* first argument to function */
    double arg2;        /* second argument (if any) to function */
    double retval;      /* value to be returned by function */
    } ;
#define _EXCEPTION_DEFINED
#endif


/* definition of a complex struct to be used by those who use cabs and
 * want type checking on their argument
 */

#ifndef _COMPLEX_DEFINED
struct complex {
    double x,y;     /* real and imaginary parts */
    } ;
#define _COMPLEX_DEFINED
#endif


/* Constant definitions for the exception type passed in the exception struct
 */

#define DOMAIN      1   /* argument domain error */
#define SING        2   /* argument singularity */
#define OVERFLOW    3   /* overflow range error */
#define UNDERFLOW   4   /* underflow range error */
#define TLOSS       5   /* total loss of precision */
#define PLOSS       6   /* partial loss of precision */

#define EDOM        33
#define ERANGE      34


/* definitions of HUGE and HUGE_VAL - respectively the XENIX and ANSI names
 * for a value returned in case of error by a number of the floating point
 * math routines
 */

extern double HUGE;
#define HUGE_VAL HUGE



/* function prototypes */

int    _CDECL abs(int);
double _CDECL acos(double);
double _CDECL asin(double);
double _CDECL atan(double);
double _CDECL atan2(double, double);
double _CDECL atof(const char *);
double _CDECL cabs(struct complex);
double _CDECL ceil(double);
double _CDECL cos(double);
double _CDECL cosh(double);
int    _CDECL dieeetomsbin(double *, double *);
int    _CDECL dmsbintoieee(double *, double *);
double _CDECL exp(double);
double _CDECL fabs(double);
int    _CDECL fieeetomsbin(float *, float *);
double _CDECL floor(double);
double _CDECL fmod(double, double);
int    _CDECL fmsbintoieee(float *, float *);
double _CDECL frexp(double, int *);
double _CDECL hypot(double, double);
double _CDECL j0(double);
double _CDECL j1(double);
double _CDECL jn(int, double);
long   _CDECL labs(long);
double _CDECL ldexp(double, int);
double _CDECL log(double);
double _CDECL log10(double);
int    _CDECL matherr(struct exception *);
double _CDECL modf(double, double *);
double _CDECL pow(double, double);
double _CDECL sin(double);
double _CDECL sinh(double);
double _CDECL sqrt(double);
double _CDECL tan(double);
double _CDECL tanh(double);
double _CDECL y0(double);
double _CDECL y1(double);
double _CDECL yn(int, double);
