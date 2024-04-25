/***
*ctype.h - character conversion macros and ctype macros
*
*   Copyright (c) 1985-1988, Microsoft Corporation.  All rights reserved.
*
*Purpose:
*   Defines macros for character classification/conversion.
*   [ANSI/System V]
*
*******************************************************************************/


#ifndef NO_EXT_KEYS /* extensions enabled */
    #define _CDECL  cdecl
    #define _NEAR   near
#else /* extensions not enabled */
    #define _CDECL
    #define _NEAR
#endif /* NO_EXT_KEYS */

/*
 * This declaration allows the user access to the ctype look-up
 * array _ctype defined in ctype.obj by simply including ctype.h
 */

extern unsigned char _NEAR _CDECL _ctype[];

/* set bit masks for the possible character types */

#define _UPPER        0x1       /* upper case letter */
#define _LOWER        0x2       /* lower case letter */
#define _DIGIT        0x4       /* digit[0-9] */
#define _SPACE        0x8       /* tab, carriage return, newline, */
                                /* vertical tab or form feed */
#define _PUNCT       0x10       /* punctuation character */
#define _CONTROL     0x20       /* control character */
#define _BLANK       0x40       /* space char */
#define _HEX         0x80       /* hexadecimal digit */

/* the character classification macro definitions */

#define isalpha(c)      ( (_ctype+1)[c] & (_UPPER|_LOWER) )
#define isupper(c)      ( (_ctype+1)[c] & _UPPER )
#define islower(c)      ( (_ctype+1)[c] & _LOWER )
#define isdigit(c)      ( (_ctype+1)[c] & _DIGIT )
#define isxdigit(c)     ( (_ctype+1)[c] & _HEX )
#define isspace(c)      ( (_ctype+1)[c] & _SPACE )
#define ispunct(c)      ( (_ctype+1)[c] & _PUNCT )
#define isalnum(c)      ( (_ctype+1)[c] & (_UPPER|_LOWER|_DIGIT) )
#define isprint(c)      ( (_ctype+1)[c] & (_BLANK|_PUNCT|_UPPER|_LOWER|_DIGIT) )
#define isgraph(c)      ( (_ctype+1)[c] & (_PUNCT|_UPPER|_LOWER|_DIGIT) )
#define iscntrl(c)      ( (_ctype+1)[c] & _CONTROL )

#define toupper(c)      ( (islower(c)) ? _toupper(c) : (c) )
#define tolower(c)      ( (isupper(c)) ? _tolower(c) : (c) )

#define _tolower(c)     ( (c)-'A'+'a' )
#define _toupper(c)     ( (c)-'a'+'A' )

#define isascii(c)      ( (unsigned)(c) < 0x80 )
#define toascii(c)      ( (c) & 0x7f )

/* MS C version 2.0 extended ctype macros */

#define iscsymf(c)      (isalpha(c) || ((c) == '_'))
#define iscsym(c)       (isalnum(c) || ((c) == '_'))
