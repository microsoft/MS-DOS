
/*  types.h - basic types
 */

#define NULL 0
#define MAXPATHLEN 80		/* JOIN.C		*/
#define MAXARG 80		/* ERRTST.C		*/
#define CURDISK 0x19		/* ERRTST.C		*/
#define GETVERS 0x30		/* MAIN.C		*/
#define GETVARS 0x52		/* SYSVAR.C		*/
#define IOCTL9 0x4409		/* ERRTST.C		*/
#define SwitChr '/'		/* JOIN.C & SUBST.C 	*/
#define PathChr '\\'		/* SUBST.C		*/
#define	COLON	':'		/* ERRTST.C		*/
#define BACKSLASH '\\'		/* ERRTST.C		*/
#define ASCNULL	'\0'		/* ERRTST.C		*/


#define     IBMSPACE(c) ((c)==','||(c)==';'||(c)=='='||(c)==0x08||(c)==0x0a)
#define     IBMBREAK(c) ((c) == '/' || CMDSPACE((c)))
#define     CMDBREAK(c) IBMBREAK((c))
#define     CMDSPACE(c) (isspace((c)) || IBMSPACE((c)))

#define		SHIFT(c,v)	{c--; v++;}

/*  The following structure is a UNIX file block that retains information
 *  about a file being accessed via the level 1 I/O functions.
 */

struct UFB
{
	char	ufbflg ;		/* flags			   */
	char	ufbtyp ;		/* device type			   */
	int	ufbfh ;			/* file handle			   */
};

#define NUFBS 20			/* number of UFBs defined	   */

/*  UFB.ufbflg definitions	*/

#define UFB_OP 0x80			/* file is open			   */
#define UFB_RA 0x40			/* reading is allowed		   */
#define UFB_WA 0x20			/* writing is allowed		   */
#define UFB_NT 0x10			/* access file with no translation */
#define UFB_AP 8			/* append mode flag		   */

/*  UFB.ufbtyp definitions	*/

#define D_DISK 0
#define D_CON 1
#define D_PRN 2
#define D_AUX 3
#define D_NULL 4

#define TRUE    -1
#define FALSE   0

#define SETFLAG(l,f)    ((l) |= (f))
#define TESTFLAG(v,f)   (((v)&(f))!=0)
#define RSETFLAG(l,f)   ((l) &= ~(f))

#define LOW(w)          ((w)&0xFF)
#define HIGH(w)         LOW((w)>>8)
#define WORD(h,l)       ((LOW((h))<<8)|LOW((l)))

/* buffer description for findfirst and findnext */

struct findType {
    char reserved[21];                  /* reserved for start up */
    char attr;                          /* attribute found */
    unsigned int time;                  /* time of last modify */
    unsigned int date;                  /* date of last modify */
    long length;                        /* file size */
    char name[13];                      /* asciz file name */
};

/* attributes */
#define A_RO    1                       /* read only */
#define A_H     2                       /* hidden */
#define A_S     4                       /* system */
#define A_V     8                       /* volume id */
#define A_D     16                      /* directory */
#define A_A     32                      /* archive */

#define A_MOD   (A_RO+A_H+A_S+A_A)      /* changeable attributes */

#define HASATTR(a,v)    TESTFLAG(a,v)   /* true if a has attribute v */
