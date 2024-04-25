;	SCCSID = @(#)mshead.asm	1.1 85/04/10
; TITLE   MSHEAD.ASM -- MS-DOS DEFINITIONS
PAGE
; MS-DOS  High-performance operating system for the 8086  version 1.28
;	by Microsoft MSDOS development group:
;	    TP (Ret.)
;	    AR
;	    NP (Parenting)
;	    MZ
;	    CP (BIOS) (ret.)

; ****************** Revision History *************************
;	   >> EVERY change must noted below!! <<
;
; 0.34 12/29/80 General release, updating all past customers
; 0.42 02/25/81 32-byte directory entries added
; 0.56 03/23/81 Variable record and sector sizes
; 0.60 03/27/81 Ctrl-C exit changes, including register save on user stack
; 0.74 04/15/81 Recognize I/O devices with file names
; 0.75 04/17/81 Improve and correct buffer handling
; 0.76 04/23/81 Correct directory size when not 2^N entries
; 0.80 04/27/81 Add console input without echo, Functions 7 & 8
; 1.00 04/28/81 Renumber for general release
; 1.01 05/12/81 Fix bug in `STORE'
; 1.10 07/21/81 Fatal error trapping, NUL device, hidden files, date & time,
;		RENAME fix, general cleanup
; 1.11 09/03/81 Don't set CURRENT BLOCK to 0 on open; fix SET FILE SIZE
; 1.12 10/09/81 Zero high half of CURRENT BLOCK after all (CP/M programs don't)
; 1.13 10/29/81 Fix classic "no write-through" error in buffer handling
; 1.20 12/31/81 Add time to FCB; separate FAT from DPT; Kill SMALLDIR; Add
;		FLUSH and MAPDEV calls; allow disk mapping in DSKCHG; Lots
;		of smaller improvements
; 1.21 01/06/82 HIGHMEM switch to run DOS in high memory
; 1.22 01/12/82 Add VERIFY system call to enable/disable verify after write
; 1.23 02/11/82 Add defaulting to parser; use variable escape character Don't
;		zero extent field in IBM version (back to 1.01!)
; 1.24 03/01/82 Restore fcn. 27 to 1.0 level; add fcn. 28
; 1.25 03/03/82 Put marker (00) at end of directory to speed searches
; 1.26 03/03/82 Directory buffers searched as a circular queue, current buffer
;		is searched first when possible to minimize I/O
;      03/03/82 STORE routine optimized to tack on partial sector tail as
;		full sector write when file is growing
;      03/09/82 Multiple I/O buffers
;      03/29/82 Two bugs:  Delete all case resets search to start at beginning
;		of directory (infinite loop possible otherwise), DSKRESET
;		must invalidate all buffers (disk and directory).
; 1.27 03/31/82 Installable device drivers
;		  Function call 47 - Get pointer to device table list
;		  Function call 48 - Assign CON AUX LIST
;      04/01/82 Spooler interrupt (INT 28) added.
; 1.28 04/15/82 DOS retructured to use ASSUMEs and PROC labels around system
;		call entries.  Most CS relative references changed to SS
;		relative with an eye toward putting a portion of the DOS in
;		ROM.  DOS source also broken into header, data and code pieces
;      04/15/82 GETDMA and GETVECT calls added as 24 and 32.  These calls
;		return the current values.
;      04/15/82 INDOS flag implemented for interrupt processing along with
;		call to return flag location (call 29)
;      04/15/82 Volume ID attribute added
;      04/17/82 Changed ABORT return to user to a long ret from a long jump to
;		avoid a CS relative reference.
;      04/17/82 Put call to STATCHK in dispatcher to catch ^C more often
;      04/20/82 Added INT int_upooler into loop ^S wait
;      04/22/82 Dynamic disk I/O buffer allocation and call to manage them
;		call 49.
;      04/23/82 Added GETDSKPTDL as call 50, similar to GETFATPT(DL), returns
;		address of DPB
;      04/29/82 Mod to WRTDEV to look for ^C or ^S at console input when
;		writting to console device via file I/O.  Added a console
;		output attribute to devices.
;      04/30/82 Call to en/dis able ^C check in dispatcher Call 51
;      04/30/82 Code to allow assignment of func 1-12 to disk files as well
;		as devices....	pipes, redirection now possible
;      04/30/82 Expanded GETLIST call to 2.0 standard
;      05/04/82 Change to INT int_fatal_abort callout int HARDERR.  DOS SS
;		(data segment) stashed in ES, INT int_fatal_abort routines must
;		preserve ES.  This mod so HARDERR can be ROMed.
; 1.29 06/01/82 Installable block and character devices as per 2.0 spec
;      06/04/82 Fixed Bug in CLOSE regarding call to CHKFATWRT.  It got left
;		out back about 1.27 or so (oops).  ARR
; 1.30 06/07/82 Directory sector buffering added to main DOS buffer queue
; 1.40 06/15/82 Tree structured directories.  XENIX Path Parser MKDIR CHDIR
;		RMDIR Xenix calls
; 1.41 06/13/82 Made GETBUFFR call PLACEBUF
; 1.50 06/17/82 FATs cached in buffer pool, get FAT pointer calls disappear
;		Frees up lots of memory.
; 1.51 06/24/82 BREAKDOWN Revised to do EXACT one sector read/write through
;		system buffers
; 1.52 06/30/82 OPEN, CLOSE, READ, WRITE, DUP, DUP2, LSEEK implemented
; 1.53 07/01/82 OPEN CLOSE mod for Xenix calls, saves and gets remote dir
; 1.54 07/11/82 Function calls 1-12 make use of new 2.0 PDB. Init code
;		changed to set file handle environment.
; 2.00 08/01/82 Number for IBM release
;      01/19/83 No environ bug in EXEC
;      01/19/83 MS-DOS OEM INT 21 extensions (SET_OEM_HANDLER)
;      01/19/83 Performance bug fix in cooked write to NUL
;      01/27/83 Growcnt fixed for 32-bits
;      01/27/83 Find-first problem after create
; 2.01 02/17/83 International DOS
; 2.10 03/09/83 Start of NETWORK support
;		New Buffer structure
;		New Sytem file table structure
;		FCB moved to internal representation
;		DOS re-organized
; 2.11 04/21/83 Continuation of 2.10, preliminary Network
;		device interface.
; 2.50 09/12/83 More network stuff
;
; *************************************************************

INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC

Break <SEGMENT DECLARATIONS>

; The following are all of the segments used.  They are declared in the order
; that they should be placed in the executable

;
; segment ordering for MSDOS
;

include dosseg.asm

AsmVar	<Installed>

START		SEGMENT BYTE PUBLIC 'START'
		ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	JMP	near ptr DOSINIT
START		ENDS

LAST		SEGMENT PARA PUBLIC 'LAST'
	Extrn	DOSINIT:NEAR
LAST		ENDS
