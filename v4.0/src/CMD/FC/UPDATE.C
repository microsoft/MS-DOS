/*
 * update takes a def string and update and fills the
 * update with missing defs the update allowing
 * specification of missing parameters.
 * the parts are: ^{[~:]#:}{%#</|\>}{[~.]#}{.[~./\:]}$
 * maximum size of MAXPATHLEN (80) bytes
 *
 *   4/14/86  dl use U_ flags
 *
 */

#include "tools.h"

int upd (def, update, dst)
char *def, *update, *dst;
{
    char *p, buf[MAXPATHLEN];
    int f;

    f = 0;
    p = buf;
#if MSDOS
    if (drive(update, p) || drive (def, p))
        SETFLAG(f, U_DRIVE);
    p += strlen (p);
#endif

    if (path(update, p) || path (def, p))
        SETFLAG(f, U_PATH);
    p += strlen (p);

    if (filename(update, p) || filename (def, p))
        SETFLAG(f, U_NAME);
    p += strlen (p);

    if (extention(update, p) || extention (def, p))
        SETFLAG(f, U_EXT);

    strcpy (dst, buf);

    return f;
}

#if MSDOS
/* copy a drive from source to dest if present, return TRUE if we found one */
drive (src, dst)
char *src, *dst;
{
    register char *p;

    p = strbscan (src, ":");
    if (*p++ == NULL)
        p = src;
    strcpy (dst, src);
    dst[p-src] = 0;
    return strlen (dst) != 0;
}
#endif

/*  copy an extention from source to dest if present.  include the period.
    Return TRUE if one found.
 */
extention (src, dst)
char *src, *dst;
{
    register char *p, *p1;

    p = src - 1;
    while (*(p=strbscan(1+(p1=p), ".")) != NULL)
        ;
    /* p1 points to last . or begin of string  p points to eos */
    if (*strbscan (p1, "\\/:") != NULL || *p1 != '.')
        p1 = p;
    strcpy (dst, p1);
    return strlen (dst) != 0;
}

/*  copy a filename part from source to dest if present.  return true if one
    is found
 */
filename (src, dst)
char *src, *dst;
{
    register char *p, *p1;

    p = src-1;
    while (*(p=strbscan (p1=p+1, "\\/:")) != NULL)
        ;
    /* p1 points after last / or at bos */
    p = strbscan (p1, ".");
    strcpy (dst, p1);
    dst[p-p1] = 0;
    return strlen (dst) != 0;
}

/*  copy a filename.ext part from source to dest if present.  return true if one
    is found
 */
fileext  (src, dst)
char *src, *dst;
{
    *dst = '\0';
    if ( filename (src, dst) ) {
        dst += strlen (dst);
        extention (src, dst);
        return TRUE;
        }
    return FALSE;
}

/*  copy the paths part of the file description.  return true if found
 */
path (src, dst)
char *src, *dst;
{
    register char *p, *p1;

    if (*(p=strbscan (src, ":")) != NULL)
        src = p+1;
    p = src-1;
    /* p points to beginning of possible path (after potential drive spec) */
    while (*(p=strbscan (p1=p+1, "\\/:")) != NULL)
        ;
    /* p1 points after  final / or bos */;
    strcpy (dst, src);
    dst[p1-src] = 0;
    return strlen (dst) != 0;
}
