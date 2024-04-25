#include "internat.h"
#include <dos.h>
#define   NULL    0
#define   TRUE    0xffff
#define   FALSE   0
#define   KANJI   TRUE	
char	haveinttab = FALSE;
/*
 * ECS Support - This module provides support for international >7FH and 
 * TWO-BYTE character sets.  The toupper routine uses the DOS MAP_CASE call.
 * In addition, STRING.C contains a default_tab containing a default lead
 * byte table for two byte character sets.  If single byte operation is
 * desired, modify this table as follows:  ="\000".  If this utility 
 * is run on a DOS with Function 63H support, the default table will 
 * be replaced by the table in the DOS.  The lbtbl_ptr is the far ptr to
 * which ever table is in use.
*/
long  lbtbl_ptr;
char  *default_tab="\201\237\340\374\000\000";
char	have_lbtbl = FALSE;

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
	long *p1;
        union REGS regs ;
        int	i;

        p1 = (long *)&lbtbl_ptr ;			
	if (!have_lbtbl ) {
      (char far *)lbtbl_ptr = (char far *)default_tab	;	/* Load offset in pointer */
           get_lbtbl( p1 );
	   have_lbtbl=TRUE;
	}
                          
	   if ( test_ecs( c, lbtbl_ptr )) 
                return(TRUE);
           else
                return(FALSE);  
}
#endif
