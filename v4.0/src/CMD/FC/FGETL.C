/* fgetl.c - expand tabs and return lines w/o separators */

#include "tools.h"

/* returns line from file (no CRLFs); returns NULL if EOF */
fgetl (buf, len, fh)
char *buf;
int len;
FILE *fh;
{
    register int c;
    register char *p;

    /* remember NUL at end */
    len--;
    p = buf;
    while (len) {
	c = getc (fh);
	if (c == EOF || c == '\n')
	    break;
#if MSDOS
	if (c != '\r')
#endif
	    if (c != '\t') {
		*p++ = c;
		len--;
		}
	    else {
		c = min (8 - ((p-buf) & 0x0007), len);
		Fill (p, ' ', c);
		p += c;
		len -= c;
		}
	}
    *p = 0;
    return ! ( (c == EOF) && (p == buf) );
}

/* writes a line to file (with trailing CRLFs) from buf, return <> 0 if
 * writes fail
 */
fputl (buf, len, fh)
char *buf;
int len;
FILE *fh;
{
#if MSDOS
    return (fwrite (buf, 1, len, fh) != len || fputs ("\r\n", fh) == EOF) ? EOF : 0;
#else
    return (fwrite (buf, 1, len, fh) != len || fputs ("\n", fh) == EOF) ? EOF : 0;
#endif
}
