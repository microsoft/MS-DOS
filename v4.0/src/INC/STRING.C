#include "types.h"
#include "internat.h"
#include <dos.h>

/*  #define KANJI   TRUE	*/

char	haveinttab = FALSE;

struct	InterTbl Currtab;

int toupper(c)
int c;
{
	union REGS regs ;

	if(!haveinttab) {
	    regs.x.ax = 0x3800 ;
	    regs.x.dx = (unsigned) &Currtab ;
	    intdos (&regs, &regs) ;		/* INIT the table */

	    haveinttab = TRUE;
	}

	return(IToupper(c,Currtab.casecall));

}

char *strupr(string)
char *string;
{
	register char *p1;

	p1 = string;
	while (*p1 != NULL) {
	/*
	 *  A note about the following " & 0xFF" stuff. This is
	 *  to prevent the damn C compiler from converting bytes
	 *  to words with the CBW instruction which is NOT correct
	 *  for routines like toupper
	 */
#ifdef KANJI
	    if(testkanj(*p1 & 0xFF))
		p1 += 2 ;
	    else
		*p1++ = toupper(*p1 & 0xFF);
#else
	    *p1++ = toupper(*p1 & 0xFF);
#endif
	}
	return(string);
}

char *strpbrk(string1,string2)
char *string1;
char *string2;
{
	register char *p1;

	while (*string1 != NULL) {
	/*
	 *  A note about the following " & 0xFF" stuff. This is
	 *  to prevent the damn C compiler from converting bytes
	 *  to words with the CBW instruction which is NOT correct
	 *  for routines like toupper
	 */
#ifdef KANJI
	    if(testkanj(*string1 & 0xFF))
		string1 += 2 ;
	    else {
#endif
		p1 = string2;
		while (*p1 != NULL) {
		    if(*p1++ == *string1)
			return(string1);
		}
		string1++;
#ifdef KANJI
	    }
#endif

	}
	return(NULL);			/* no matches found */
}

#ifdef KANJI
testkanj(c)
unsigned char c;
{
	if((c >= 0x81 && c <= 0x9F) || (c >= 0xE0 && c <= 0xFC))
		return(TRUE);
	else
		return(FALSE);
}
#endif
