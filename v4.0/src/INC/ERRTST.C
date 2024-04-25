/*  0  */
#include "comsub.h"
#include "dpb.h"
#include <dos.h>
#include "jointype.h"

extern unsigned char *com_substr() ;            /* ;AN000; DBCS enabled */
extern char getdrv() ;

union REGS inregs, outregs;                     /* ;AN000; Regs for Int21 */
struct SREGS segregs;                           /* ;AN000; Segment regs for Int21 */

#define GET_DBCS_VEC   0x6300                   /* ;AN000; Int21 Get DBCS Vector */
#define DBLNULL        "00"                     /* ;AN000; */
#define NULL           0                        /* ;AN000; */

#define KANJI   TRUE

/* return FALSE if drive is valid AND the path is not a prefix of a non-root
 * current directory.
 */
char fPathErr(p)
char *p ;
{
        char buf[MAXARG] ;
        int d ;
#ifdef KANJI
        char *p1;
#endif

        if (p[1] == ':')
                d = *p-'A'+1 ;
        else
                d = 0 ;

        if (curdir(buf, d) == -1)       /* drive is invalid => error       */
                return(TRUE) ;

        if (strlen(buf) == 3)           /* current directory is root => OK */
                return(FALSE) ;

        if (strpre(p, buf)) {
#ifdef KANJI
                p1 = p;
                while (*p1 != NULL) {
                    if(testkanj(*p1 & 0xFF))
                        p1 += 2 ;
                    else
                        if((*p1++ == '\\') && (*p1 == NULL))
                                return(TRUE) ;
                }
#else
                if (p[strlen(p)-1] == '\\') /* prefix matched, prefix had...*/
                        return(TRUE) ;      /* ...trailing / => valid ...   */
                                           /* ...prefix => ERROR           */
#endif
                d = buf[strlen(p)] ;
                if (d == 0 || d == '\\') /* prefix matched,... */
                        return(TRUE) ;      /* ...prefix had no trailing /, */
                                           /* ...next char was / => ...    */
                                           /* ...valid prefix => ERROR     */
        } ;

        return(FALSE) ;    /* drive letter good and not valid prefix => OK  */
}


strpre(pre, tot)
        char    *pre;
        char    *tot;
{
        return(!strncmp(pre, tot, strlen(pre)));
}



Fatal(p)
char *p ;
{
        printf("%s\n", p) ;
        exit(1) ;
}




ffirst(pb, attr, pfbuf)
char *pb ;
int attr ;
struct findType *pfbuf ;
{
        union REGS regs ;

        /* set DMA to point to buffer */

        regs.h.ah = 0x1A ;
        regs.x.dx = (unsigned) pfbuf ;
        intdos (&regs, &regs) ;

        /* perform system call */

        regs.h.ah = 0x4E ;
        regs.x.cx = attr ;
        regs.x.dx = (unsigned) pb ;
        intdos (&regs, &regs) ;

        return (regs.x.cflag ? -1 : 0) ;
}

fnext (pfbuf)
struct findType *pfbuf;
{
    union REGS regs;

    /* set DMA to point to buffer */
    regs.h.ah = 0x1A;
    regs.x.dx = (unsigned) pfbuf;
    intdos (&regs, &regs);
    /* perform system call */
    regs.h.ah = 0x4F;
    intdos (&regs, &regs);
    return (regs.x.cflag ? -1 : 0) ;
}


char *strbscan(str, class)
char *str ;
char *class ;
{
        char *p ;

        p = com_substr(str, class) ;            /* :AN000; DBCS function */
        return((p == NULL) ? (str + strlen(str)) : p) ;
}





/* curdir.c - return text of current directory for a particular drive */


curdir (dst, drive)
char *dst ;
int drive ;
{
    union REGS regs ;

    *dst++ = PathChr ;
    regs.h.ah = 0x47 ;
    regs.h.dl = drive ;
    regs.x.si = (unsigned) dst ;
    intdos (&regs, &regs) ;
    return(regs.x.cflag ? -1 : 0) ;
}




/*
   rootpath
*/

/*** rootpath  --  convert a pathname argument to root based cannonical form
 *
 * rootpath determines the current directory, appends the path argument (which
 * may affect which disk the current directory is relative to), and qualifies
 * "." and ".." references.  The result is a complete, simple, path name with
 * drive specifier.
 *
 * If the relative path the user specifies does not include a drive spec., the
 * default drive will be used as the base.  (The default drive will never be
 * changed.)
 *
 *  entry: relpath  -- pointer to the pathname to be expanded
 *         fullpath -- must point to a working buffer, see warning
 *   exit: fullpath -- the full path which results
 * return: true if an error occurs, false otherwise
 *
 * calls: curdir, getdrv
 *
 * warning: fullpath must point to a working buffer large enough to hold the
 *          longest possible relative path argument plus the longest possible
 *          current directory path.
 *
 */
int rootpath(relpath, fullpath)
char *relpath ;
char *fullpath ;
{
        int drivenum ;
        char tempchar;
        register char *lead, *follow ;
        char *p1, *p2;


        /* extract drive spec */
        drivenum = getdrv() ;
        if ((*relpath != NULL) && (relpath[1] == COLON)) {
                drivenum = relpath[0] - 'A' ;
                relpath += 2 ;
        }
        fullpath[0] = (char) ('A' + drivenum) ;
        fullpath[1] = COLON ;

        /* append relpath to fullpath/base */
        if (*relpath == PathChr) {
                /* relpath starts at base */
                strcpy(fullpath+2, relpath) ;
        }
        else {
                /* must get base path first */
                if (curdir(fullpath+2, drivenum+1))
                        return(TRUE) ;                  /* terrible error */
                if ((*relpath != ASCNULL) && (strlen(fullpath) > 3))
                        strcat(fullpath, "\\") ;
                strcat(fullpath, relpath) ;
        }


        /* convert path to cannonical form */
        lead = fullpath ;
        while(*lead != ASCNULL) {
                /* mark next path segment */
                follow = lead ;
                lead = (char *) com_substr(follow+1, "\\") ;    /* ;AC000; */
                if (lead == NULL)
                        lead = fullpath + strlen(fullpath) ;
                tempchar = *lead ;
                if (tempchar == PathChr)
                        tempchar = BACKSLASH ;   /* make breaks uniform */
                *lead = ASCNULL ;

                /* "." segment? */
                if (strcmp(follow+1, ".") == 0) {
                        *lead = tempchar ;
                        strcpy(follow, lead) ;  /* remove "." segment */
                        lead = follow ;
                }

                /* ".." segment? */
                else if (strcmp(follow+1, "..") == 0) {
                        *lead = tempchar ;
                        tempchar = *follow ;
                        *follow = NULL ;
                        p2 = fullpath - 1 ;
                        while(*(p2=strbscan(p1=p2+1,"\\")) != NULL) ;
                        /* p1 now points to the start of the previous element */
                        *follow = tempchar ;
                        if(p1 == fullpath)
                            return(TRUE) ;      /* tried to .. the root */
                        follow = p1 - 1 ;       /* follow points to path sep */
                        strcpy(follow, lead) ;         /* remove ".." segment */
                        lead = follow ;
                }

                /* normal segment */
                else
                        *lead = tempchar ;
        }
        if (strlen(fullpath) == 2)  /* 'D:' or some such */
                strcat(fullpath, "\\") ;

        return(FALSE) ;
}


/* getdrv - return current drive as a character */


char getdrv()
{
    union REGS regs ;

    regs.h.ah = CURDISK ;               /* Function 0x19 */
    intdos (&regs, &regs) ;
    return(regs.h.al) ;
}

testkanj(c)
unsigned char c;
{
  char   fix_es_reg[1];                         /* ;AN000; Fixes es reg after "far" */
  char far * fptr;                              /* ;AN000; Pts to DBCS vector */
  unsigned * ptr;                               /* ;AN000; Input to fptr */
  unsigned int got_dbcs;                        /* ;AN000; Flag */

  inregs.x.ax = GET_DBCS_VEC;                   /* ;AN000; 0x6300 */
  intdosx(&inregs,&outregs,&segregs);           /* ;AN000; Int21 */

  got_dbcs = FALSE;                             /* ;AN000; Initialize */

  ptr  = (unsigned *)&fptr;                     /* ;AN000; Int21 returns DS:SI */
  *ptr = outregs.x.si;                          /* ;AN000;   as ptr to DBCS    */
  ptr++;                                        /* ;AN000;   vector, now fill  */
  *ptr = segregs.ds;                            /* ;AN000;   in our pointer    */

  for (fptr; *(unsigned far *)fptr != (unsigned)DBLNULL; fptr += 2) /* ;AN000; */
  {                                             /* ;AN000; */
    if ( (c >= (char)*fptr) && (c <= (char)*(fptr+1)) ) /* ;AN000; Is char */
    {                                           /* ;AN000;  within the range? */
      got_dbcs = TRUE;                          /* ;AN000; Char is DBCS */
      break;                                    /* ;AN000; */
    }                                           /* ;AN000; */
  }                                             /* ;AN000; */

  strcpy(fix_es_reg,NULL);                      /* ;AN000; Repair ES reg */
  return(got_dbcs);                             /* ;AN000; */
}
