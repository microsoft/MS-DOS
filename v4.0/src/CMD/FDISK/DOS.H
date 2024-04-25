/* dos.h
 *
 * Defines the structs and unions used to handle the input and output
 * registers for the DOS interface routines defined in the V2.0 to V3.0
 * compatability package.  It also includes macros to access the segment
 * and offset values of MS C "far" pointers, so that they may be used by
 * these routines.
 *
 */

/* word registers */

struct WORDREGS {
	unsigned ax;
	unsigned bx;
	unsigned cx;
	unsigned dx;
	unsigned si;
	unsigned di;
	unsigned cflag;
	};

/* byte registers */

struct BYTEREGS {
	unsigned char al, ah;
	unsigned char bl, bh;
	unsigned char cl, ch;
	unsigned char dl, dh;
	};

/* general purpose registers union - overlays the corresponding word and
 * byte registers.
 */

union REGS {
	struct WORDREGS x;
	struct BYTEREGS h;
	};

/* segment registers */

struct SREGS {
	unsigned es;
	unsigned cs;
	unsigned ss;
	unsigned ds;
	};

/* dosexterror struct */

struct DOSERROR {
	int exterror;
	char class;
	char action;
	char locus;
	};

/* macros to break MS C "far" pointers into their segment and offset
 * components
 */

#define FP_SEG(fp) (*((unsigned *)&(fp) + 1))
#define FP_OFF(fp) (*((unsigned *)&(fp)))

/* function declarations for those who want strong type checking
 * on arguments to library function calls
 */

#ifdef LINT_ARGS		/* arg. checking enabled */

int bdos(int, unsigned int, unsigned int);
int dosexterr(struct DOSERROR *);
int intdos(union REGS *, union REGS *);
int intdosx(union REGS *, union REGS *, struct SREGS *);
int int86(int, union REGS *, union REGS *);
int int86x(int, union REGS *, union REGS *, struct SREGS *);
void segread(struct SREGS *);

#endif	/* LINT_ARGS */
