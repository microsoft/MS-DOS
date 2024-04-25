/*  file compare

    Fcom compares two files in either a line-by-line mode or in a strict
    byte-by-byte mode.

    The byte-by-byte mode is simple; merely read both files and print the
    offsets where they differ and the contents.

    The line compare mode attempts to isolate differences in ranges of lines.
    Two buffers of lines are read and compared.  No hashing of lines needs
    to be done; hashing only speedily tells you when things are different,
    not the same.  Most files run through this are expected to be largely
    the same.  Thus, hashing buys nothing.


***********************************************************************
The algorithm that immediately follows does not work.  There is an error
somewhere in the range of lines 11 on. An alternative explanation follows.
                                                            KGS
************************************************************************

    [0]     Fill buffers
    [1]     If both buffers are empty then
    [1.1]       Done
    [2]     Adjust buffers so 1st differing lines are at top.
    [3]     If buffers are empty then
    [3.1]       Goto [0]

    This is the difficult part.  We assume that there is a sequence of inserts,
    deletes and replacements that will bring the buffers back into alignment.

    [4]     xd = yd = FALSE
    [5]     xc = yc = 1
    [6]     xp = yp = 1
    [7]     If buffer1[xc] and buffer2[yp] begin a "sync" range then
    [7.1]       Output lines 1 through xc-1 in buffer 1
    [7.2]       Output lines 1 through yp-1 in buffer 2
    [7.3]       Adjust buffer 1 so line xc is at beginning
    [7.4]       Adjust buffer 2 so line yp is at beginning
    [7.5]       Goto [0]
    [8]     If buffer1[xp] and buffer2[yc] begin a "sync" range then
    [8.1]       Output lines 1 through xp-1 in buffer 1
    [8.2]       Output lines 1 through yc-1 in buffer 2
    [8.3]       Adjust buffer 1 so line xp is at beginning
    [8.4]       Adjust buffer 2 so line yc is at beginning
    [8.5]       Goto [0]
    [9]     xp = xp + 1
    [10]    if xp > xc then
    [10.1]      xp = 1
    [10.2]      xc = xc + 1
    [10.3]      if xc > number of lines in buffer 1 then
    [10.4]          xc = number of lines
    [10.5]          xd = TRUE
    [11]    if yp > yc then
    [11.1]      yp = 1
    [11.2]      yc = yc + 1
    [11.3]      if yc > number of lines in buffer 2 then
    [11.4]          yc = number of lines
    [11.5]          yd = TRUE
    [12]    if not xd or not yd then
    [12.1]      goto [6]

    At this point there is no possible match between the buffers.  For
    simplicity, we punt.

    [13]    Display error message.

EXPLANATION 2

    This is a variation of the Largest Common Subsequence problem.  A
    detailed explanation of this can be found on p 189 of Data Structures
    and Algorithms by Aho Hopcroft and Ulman.



    FC maintains two buffers within which it tries to find the Largest Common
    Subsequence (The largest common subsequence is simply the pattern in
    buffer1 that yields the most matches with the pattern in buffer2, or the
    pattern in buffer2 that yields the most matches with the pattern in buffer1)

    FC makes a simplifying assumption that the contents of one buffer can be
    converted to the contents of the other buffer by deleting the lines that are
    different between the two buffers.

    Two indices into each buffer are maintained:

            xc, yc == point to the last line that has been scanned up to now

            xp, yp == point to the first line that has not been exhaustively
                      compared to lines 0 - #c in the other buffer.

    FC now makes a second simplifying assumption:
        It is unnecessary to do any calculations on lines that are equal.

    Hence FC scans File1 and File two line by line until a difference is
    encountered.


    When a difference is encountered the two buffers are filled such that
    the line containing the first difference heads the buffer. The following
    exhaustive search algorithm is applied to find the first "sync" occurance.
    (The below is simplified to use == for comparison.  In practice more than
    one line needs to match for a "sync" to be established).


            FOR xc,yc = 1; xc,yx <= sizeof( BUFFERS ); xc++, yc++

                FOR xp,yp = 1; xp,yp <= xc,yc; xp++, yp++

                    IF ( BUFFER1[xp] == BUFFER2[yc] )

                        Then the range of lines BUFFER1[ 1 ... xp ] and
                        BUFFER2[ 1 ... yc ] need to be deleted for the
                        two files to be equal.  Therefore DISPLAY these
                        ranges, and begin scanning both files starting at
                        the matching lines.
                    FI

                    IF ( BUFFER1[yp] == BUFFER2[xc] )

                        Then the range of lines BUFFER2[ 1 ... yp ] and
                        BUFFER1[ 1 ... xc ] need to be deleted for the
                        two files to be equal.  Therefore DISPLAY these
                        ranges, and begin scanning both files starting at
                        the matching lines.
                    FI
                FOREND
            FOREND

    If a match is not found within the buffers, the message "RESYNC FAILED"
    is issued and further comparison is aborted since there is no valid way
    to find further matching lines.




END EXPLANATION 2





    Certain flags may be set to modify the behavior of the comparison:

    -a      abbreviated output.  Rather than displaying all of the modified
            ranges, just display the beginning, ... and the ending difference
    -b      compare the files in binary (or byte-by-byte) mode.  This mode is
            default on .EXE, .OBJ, .LIB, .COM, .BIN, and .SYS files
    -c      ignore case on compare (cmp = strcmpi instead of strcmp)
    -l      compare files in line-by-line mode
    -lb n   set the size of the internal line buffer to n lines from default
            of 100
    -w      ignore blank lines and white space (ignore len 0, use strcmps)
    -t      do not untabify (use fgets instead of fgetl)
    -n      output the line number also
    -NNNN   set the number of lines to resynchronize to n which defaults
            to 2.  Failure to have this value set correctly can result in
            odd output:
              file1:        file2:
                    abcdefg       abcdefg
                    aaaaaaa       aaaaaab
                    aaaaaaa       aaaaaaa
                    aaaaaaa       aaaaaaa
                    abcdefg       abcdefg

            with default sync of 2 yields:          with sync => 3 yields:

                    *****f1                             *****f1
                    abcdefg                             abcdefg
                    aaaaaaa                             aaaaaaa
                    *****f2                             aaaaaaa
                    abcdefg                             *****f2
                    aaaaaab                             abcdefg
                    aaaaaaa                             aaaaaab
                                                        aaaaaaa
                    *****f1
                    aaaaaaa
                    aaaaaaa
                    abcdefg
                    *****f2
                    aaaaaaa
                    abcdefg






WARNING:
        This program makes use of GOTO's and hence is not as straightforward
        as it could be!  CAVEAT PROGRAMMER.















 */


#include "tools.h"
#include "fc.h"

/* #define  DEBUG  FALSE */

extern int  fgetl(),
            strcmp ();

extern byte toupper ();

int (*funcRead) (),                     /* function to use to read lines     */
    (*fCmp) ();                         /* function to use to compare lines  */

extern byte BadSw[],
            Bad_ver[],
            BadOpn[],
            LngFil[],
            NoDif[],
            NoMem[],
            UseMes[],
            ReSyncMes[];

int ctSync  = -1,                       /* number of lines required to sync  */
    cLine   = -1;                       /* number of lines in internal buffs */

flagType fAbbrev = FALSE,               /* abbreviated output                */
         fBinary = FALSE,               /* binary comparison                 */
         fLine   = FALSE,               /* line comparison                   */
         fNumb   = FALSE,               /* display line numbers              */
         fCase   = TRUE,                /* case is significant               */
         fIgnore = FALSE;               /* ignore spaces and blank lines     */

#ifdef  DEBUG

flagType fDebug = FALSE;
#endif

struct lineType *buffer1,
                *buffer2;

byte line[MAXARG];             /* single line buffer                */

byte *extBin[] = { ".EXE", ".OBJ", ".LIB",
                            ".COM", ".BIN", ".SYS", NULL };


main (c, v)
int c;
byte *v[];
{

        int     i;
        int     j;
        int     fileargs;
        char    *strpbrk(),
                *slash;
        char    n[2][80];
        char    temp;



        extern byte _osmajor, _osminor;
        word version;                   /* _osmajor._osminor, used for        */
                                        /* version binding checks.            */



      /* Issue error message if DOS version is not within valid range. */
        version = ((word)_osmajor << 8) + (word)_osminor;
        if (( LOWVERSION >  version) || (version >  HIGHVERSION))
        {
            usage (Bad_ver, 1);
        }

        funcRead = (int (*) ())FNADDR(fgetl);

        fileargs=0;

        for (i=1; i < c ; i++)
        {
/**
 *  If argument doesn't begin with a /, parse a filename off of it
 *  then examine the argument for following switches.
 *
**/
                if (*v[i] != '/')
                {
                        slash= strpbrk( v[i],"/" );

                        if ( slash )
                        {
                                temp = *slash;
                                *slash='\0'  ;
                                strcpy(n[fileargs++],v[i]);
                                *slash =temp  ;
                        }
                        else
                                strcpy(n[fileargs++],v[i]);
                }

                for ( j=0 ; j < strlen( v[i] ) ; j++)
                {
                        if(*(v[i]+j)=='/')
                        {
                                switch(toupper( *(v[i]+j+1)))
                                {
                                     case 'A' :
                                             fAbbrev = TRUE;
                                         break;
                                     case 'B' :
                                             fBinary = TRUE;
                                         break;
                                     case 'C' :
                                             fCase = FALSE;
                                         break;
#ifdef  DEBUG
                                     case 'D' :
                                             fDebug = TRUE;
                                         break;
#endif
                                     case 'W' :
                                             fIgnore = TRUE;
                                         break;
                                     case 'L' :
                                             if (toupper(*(v[i]+j+2))=='B')
                                             {
                                                 cLine = ntoi ((v[i]+j+3),10);
                                                 break;
                                             }
                                             else
                                                 fLine = TRUE;
                                         break;
                                     case 'N' :
                                             fNumb = TRUE;
                                         break;
                                     case 'T' :
                                             funcRead =(int (*) ())FNADDR(fgets);
                                         break;
                                     default:
                                             if (*strbskip((v[i]+j+1),"0123456789") == 0)
                                             {
                                                 ctSync = ntoi ((v[i]+j+1), 10);
                                             }
                                             else
                                             {
                                                 usage (NULL, 1);
                                             }
                                } /* end switch */
                        }       /* end if */
                }       /* end parse of argument for '/' */
        }       /* End ARGUMENT Search */



    if (fileargs != 2)
        usage (NULL, 1);

    if (ctSync != -1)
        fLine = TRUE;
    else
        ctSync = 2;

    if (cLine == -1)
        cLine = 100;

    if (!fBinary && !fLine)
    {
        extention (n[0], line);

        for (i = 0; extBin[i]; i++)
            if (!strcmpi (extBin[i], line))
                fBinary = TRUE;

        if (!fBinary)
            fLine = TRUE;
    }

    if (fBinary && (fLine || fNumb))
        usage (BadSw, 1);

    if (fIgnore)
    {
        if (fCase)
            fCmp = FNADDR(strcmps);
        else
            fCmp = FNADDR(strcmpis);
    }
    else
    {
        if (fCase)
            fCmp = FNADDR(strcmp);
        else
            fCmp = FNADDR(strcmpi);
    }

    if (fBinary)
        BinaryCompare (n[0], n[1]);
    else
        LineCompare (n[0], n[1]);

}

usage (p, erc)
unsigned char *p;
{
    if (p)
        printf ("fc: %s\n", p);
    else
        printf (UseMes);

    exit (erc);
}

BinaryCompare (f1, f2)
unsigned char *f1, *f2;
{
    register int c1, c2;
    long pos;
    FILE *fh1, *fh2;
    flagType fSame;

    fSame = TRUE;

    if ((fh1 = fopen (f1, "rb")) == NULL)
    {
        sprintf (line, BadOpn, f1, error ());
        usage (line, 1);
    }

    if ((fh2 = fopen (f2, "rb")) == NULL)
    {
        sprintf (line, BadOpn, f2, error ());
        usage (line, 1);
    }
    pos = 0L;

    while (TRUE)
    {
        if ((c1 = getc (fh1)) != EOF)
        {
            if ((c2 = getc (fh2)) != EOF)
            {
                if (c1 == c2)
                    ;
                else
                {
                    fSame = FALSE;
                    printf ("%08lX: %02X %02X\n", pos, c1, c2);
                }
            }
            else
            {
                sprintf (line, LngFil, f1, f2);
                usage (line, 1);
            }
        }
        else
        {
            if ((c2 = getc (fh2)) == EOF)
            {
                if (fSame)
                    usage (NoDif, 0);
                else
                    exit (1);
            }
            else
            {
                sprintf (line, LngFil, f2, f1);
                usage (line, 1);
            }
        }
        pos++;
    }
}

/* compare a range of lines */
flagType compare (l1, s1, l2, s2, ct)
int l1, l2, ct;
register int s1, s2;
{

#ifdef  DEBUG
    if (fDebug)
        printf ("compare (%d, %d, %d, %d, %d)\n", l1, s1, l2, s2, ct);
#endif

    if (ct == 0 || s1+ct > l1 || s2+ct > l2)
        return FALSE;

    while (ct--)
    {

#ifdef  DEBUG
        if (fDebug)
            printf ("'%s' == '%s'? ", buffer1[s1].text, buffer2[s2].text);
#endif

        if ((*fCmp)(buffer1[s1++].text, buffer2[s2++].text))
        {

#ifdef  DEBUG
            if (fDebug)
                printf ("No\n");
#endif
            return FALSE;
        }
    }

#ifdef  DEBUG
    if (fDebug)
        printf ("Yes\n");
#endif

    return TRUE;
}

LineCompare (f1, f2)
unsigned char *f1, *f2;
{
    FILE *fh1, *fh2;
    int l1, l2, i, xp, yp, xc, yc;
    flagType xd, yd, fSame;
    int line1, line2;

    fSame = TRUE;

    if ((fh1 = fopen (f1, "rb")) == NULL)
    {
        sprintf (line, BadOpn, f1, error ());
        usage (line, 1);
    }

    if ((fh2 = fopen (f2, "rb")) == NULL)
    {
        sprintf (line, BadOpn, f2, error ());
        usage (line, 1);
    }

    if ((buffer1 = (struct lineType *)malloc (cLine * (sizeof *buffer1))) == NULL ||
        (buffer2 = (struct lineType *)malloc (cLine * (sizeof *buffer1))) == NULL)
        usage (NoMem);

    l1 = l2 = 0;
    line1 = line2 = 0;
l0:

#ifdef  DEBUG
    if (fDebug)
        printf ("At scan beginning\n");
#endif

    l1 += xfill (buffer1+l1, fh1, cLine-l1, &line1);
    l2 += xfill (buffer2+l2, fh2, cLine-l2, &line2);

    if (l1 == 0 && l2 == 0)
    {
        if (fSame)
            usage (NoDif, 0);
        return;
    }
    xc = min (l1, l2);

    for (i=0; i < xc; i++)
    {
        if (!compare (l1, i, l2, i, 1))
            break;
    }

    if (i != xc)
        i = max (i-1, 0);

    l1 = adjust (buffer1, l1, i);
    l2 = adjust (buffer2, l2, i);

  /* KLUDGE ALERT!! GOTO USED */
    if (l1 == 0 && l2 == 0)
        goto l0;

    l1 += xfill (buffer1+l1, fh1, cLine-l1, &line1);
    l2 += xfill (buffer2+l2, fh2, cLine-l2, &line2);

#ifdef  DEBUG
    if (fDebug)
        printf ("buffers are adjusted, %d, %d remain\n", l1, l2);
#endif

    xd = yd = FALSE;
    xc = yc = 1;
    xp = yp = 1;

l6:

#ifdef  DEBUG
    if (fDebug)
        printf ("Trying resync %d,%d  %d,%d\n", xc, xp, yc, yp);
#endif

    i = min (l1-xc,l2-yp);
    i = min (i, ctSync);

    if (compare (l1, xc, l2, yp, i))
    {
        fSame = FALSE;
        printf ("***** %s\n", f1);
        dump (buffer1, 0, xc);
        printf ("***** %s\n", f2);
        dump (buffer2, 0, yp);
        printf ("*****\n\n");

        l1 = adjust (buffer1, l1, xc);
        l2 = adjust (buffer2, l2, yp);

      /* KLUDGE ALERT!! GOTO USED */
        goto l0;
    }
    i = min (l1-xp, l2-yc);
    i = min (i, ctSync);

    if (compare (l1, xp, l2, yc, i))
    {
        fSame = FALSE;
        printf ("***** %s\n", f1);
        dump (buffer1, 0, xp);
        printf ("***** %s\n", f2);
        dump (buffer2, 0, yc);
        printf ("*****\n\n");

        l1 = adjust (buffer1, l1, xp);
        l2 = adjust (buffer2, l2, yc);

      /* KLUDGE ALERT!! GOTO USED */
        goto l0;
    }

    if (++xp > xc)
    {
        xp = 1;
        if (++xc >= l1)
        {
            xc = l1;
            xd = TRUE;
        }
    }

    if (++yp > yc)
    {
        yp = 1;
        if (++yc >= l2)
        {
            yc = l1;
            yd = TRUE;
        }
    }

    if (!xd || !yd)
        goto l6;
    fSame = FALSE;

    if (l1 >= cLine || l2 >= cLine)
        printf ("%s", ReSyncMes);

    printf ("***** %s\n", f1);
    dump (buffer1, 0, l1-1);
    printf ("***** %s\n", f2);
    dump (buffer2, 0, l2-1);
    printf ("*****\n\n");
    exit (1);
}



/* return number of lines read in */
xfill (pl, fh, ct, plnum)
struct lineType *pl;
FILE *fh;
int ct;
int *plnum;
{
    int i;

#ifdef  DEBUG
    if (fDebug)
        printf ("xfill (%04x, %04x)\n", pl, fh);
#endif

    i = 0;
    while (ct-- && (*funcRead) (pl->text, MAXARG, fh) != NULL)
    {
        if (funcRead == (int (*) ())FNADDR(fgets))
            pl->text[strlen(pl->text)-1] = 0;
        if (fIgnore && !strcmps (pl->text, ""))
            pl->text[0] = 0;
        if (strlen (pl->text) != 0 || !fIgnore)
        {
            pl->line = ++*plnum;
            pl++;
            i++;
        }
    }

#ifdef  DEBUG
    if (fDebug)
        printf ("xfill returns %d\n", i);
#endif

    return i;
}


/* adjust returns number of lines in buffer */
adjust (pl, ml, lt)
struct lineType *pl;
int ml;
int lt;
{

#ifdef  DEBUG
    if (fDebug)
        printf ("adjust (%04x, %d, %d) = ", pl, ml, lt);
    if (fDebug)
        printf ("%d\n", ml-lt);
#endif

    if (ml <= lt)
        return 0;

#ifdef  DEBUG
    if (fDebug)
        printf ("move (%04x, %04x, %04x)\n", &pl[lt], &pl[0], sizeof (*pl)*(ml-lt));
#endif

    Move ((unsigned char far *)&pl[lt], (char far *)&pl[0], sizeof (*pl)*(ml-lt));
    return ml-lt;
}


/* dump
 *      dump outputs a range of lines.
 *
 *  INPUTS
 *          pl      pointer to current lineType structure
 *          start   starting line number
 *          end     ending line number
 *
 *  CALLS
 *          pline, printf
 *
 */
dump (pl, start, end)
struct lineType *pl;
int start, end;
{
    if (fAbbrev && end-start > 2)
    {
        pline (pl+start);
        printf ("...\n");
        pline (pl+end);
    }
    else
        while (start <= end)
            pline (pl+start++);
}




/* PrintLINE
 *      pline prints a single line of output.  If the /n flag
 *  has been specified, the line number of the printed text is added.
 *
 *  Inputs
 *          pl      pointer to current lineType structure
 *          fNumb   TRUE if /n specified
 *
 */
pline (pl)
struct lineType *pl;
{
    if (fNumb)
        printf ("%5d:  ", pl->line);

    printf ("%s\n", pl->text);
}

/*
 *        strcmpi will compare two string lexically and return one of
 *  the following:
 *    - 0    if the strings are equal
 *    - 1    if first > the second
 *    - (-1) if first < the second
 *
 *	This was written to replace the run time library version of
 *  strcmpi which does not correctly compare the european character set.
 *  This version relies on a version of toupper which uses IToupper.
 */

int strcmpi(str1, str2)
unsigned char *str1, *str2;
{
   unsigned char c1, c2;

   while ((c1 = toupper(*str1++)) == (c2 = toupper(*str2++))) {
      if (c1 == '\0')
         return(0);
   }

   if (c1 > c2)
      return(1);
   else
      return(-1);
}


/* compare two strings, ignoring white space, case is significant, return
 * 0 if identical, <>0 otherwise
 */
strcmps (p1, p2)
unsigned char *p1, *p2;
{
    while (TRUE) {
	while (ISSPACE(*p1))
	    p1++;
	while (ISSPACE(*p2))
	    p2++;
	if (*p1 == *p2)
	    if (*p1++ == 0)
		return 0;
	    else
		p2++;
	else
	    return *p1-*p2;
	}
}


/* compare two strings, ignoring white space, case is not significant, return
 * 0 if identical, <>0 otherwise
 */
int strcmpis (p1, p2)
unsigned char *p1, *p2;
{
    while (TRUE) {
	while (ISSPACE(*p1))
	    p1++;
	while (ISSPACE(*p2))
	    p2++;
	if (toupper (*p1) == toupper (*p2))
	    if (*p1++ == 0)
		return 0;
	    else
		p2++;
	else
	    return *p1-*p2;
	}
}
