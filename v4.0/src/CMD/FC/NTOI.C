/* convert an arbitrary based number to an integer */

#include <ctype.h>
#include "tools.h"

/* p points to characters, return -1 if no good characters found
 * and base is 2 <= base <= 16
 */
int ntoi (p, base)
char *p;
int base;
{
    register int i, c;
    flagType fFound;

    if (base < 2 || base > 16)
	return -1;
    i = 0;
    fFound = FALSE;
    while (c = *p++) {
	c = tolower (c);
	if (!isxdigit (c))
	    break;
	if (c <= '9')
	    c -= '0';
	else
	    c -= 'a'-10;
	if (c >= base)
	    break;
	i = i * base + c;
	fFound = TRUE;
	}
    if (fFound)
	return i;
    else
	return -1;
}
