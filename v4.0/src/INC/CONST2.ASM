;	SCCSID = @(#)const2.asm 1.4 85/07/24
TITLE	CONST2 - More constants data
NAME	CONST2

.xlist
.xcref
INCLUDE DOSSYM.INC
include dosseg.asm
INCLUDE DEVSYM.INC
.cref
.list

Break <Initialized data and data used at DOS initialization>

;
; We need to identify the parts of the data area that are relevant to tasks
; and those that are relevant to the system as a whole.  Under 3.0, the system
; data will be gathered with the system code.  The process data under 2.x will
; be available for swapping and under 3.0 it will be allocated per-process.
;
; The data that is system data will be identified by [SYSTEM] in the comments
; describing that data item.
;

	AsmVars <Kanji, Debug, Redirector, ShareF>

CONSTANTS	SEGMENT WORD PUBLIC 'CONST'

;
; Table of routines for assignable devices
;
; MSDOS allows assignment if the following standard devices:
;   stdin  (usually CON input)
;   stdout (usually CON output)
;   auxin  (usually AUX input)
;   auxout (usually AUX output)
;   stdlpt (usually PRN output)
;
; SPECIAL NOTE:
;   Status of a file is a strange idea.  We choose to handle it in this
;   manner:  If we're not at end-of-file, then we always say that we have a
;   character.	Otherwise, we return ^Z as the character and set the ZERO
;   flag.  In this manner we can support program written under the old DOS
;   (they use ^Z as EOF on devices) and programs written under the new DOS
;   (they use the ZERO flag as EOF).

; Default SFTs for boot up

Public CONST001S,CONST001E
CONST001s	label byte
	PUBLIC	sftabl
sftabl	LABEL	DWORD			; [SYSTEM] file table
	DW	-1			; [SYSTEM] link to next table
	DW	-1			; [SYSTEM] link seg to next table
	DW	sf_default_number	; [SYSTEM] Number of entries in table
	DB	sf_default_number DUP ( (SIZE sf_entry) DUP (0)); [SYSTEM]

; the next two variables relate to the position of the logical stdout/stdin
; cursor.  They are only meaningful when stdin/stdout are assigned to the
; console.
	I_am	CARPOS,BYTE		; [SYSTEM] cursor position in stdin
	I_am	STARTPOS,BYTE		; [SYSTEM] position of cursor at beginning of buffered input call
	I_am	INBUF,128		; [SYSTEM] general device input buffer
	I_am	CONBUF,131		; [SYSTEM] The rest of INBUF and console buffer

	I_am	PFLAG,BYTE		; [SYSTEM] printer echoing flag
	I_am	VERFLG,BYTE		; [SYSTEM] Initialize with verify off
	I_am	CharCo,BYTE,<00000011B> ; [SYSTEM] Allows statchks every 4 chars...
	I_am	chSwitch,BYTE,<'/'>     ; [SYSTEM] current switch character
	I_am	AllocMethod,BYTE	; [SYSTEM] how to alloc first(best)last
	I_am	fShare,BYTE,<0> 	; [SYSTEM] TRUE => sharing installed
	I_am	DIFFNAM,BYTE,<1>	; [SYSTEM] Indicates when MYNAME has
					;	     changed
	I_am	MYNAME,16,<32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32>
					; [SYSTEM] My network name


;
; The following table is a list of addresses that the sharer patches to be
; PUSH AX to enable the critical sections
;
PUBLIC	CritPatch
CritPatch LABEL WORD
IRP sect,<critDisk,critDevice>
IF (NOT REDIRECTOR) AND (NOT SHAREF)
	Short_Addr  E&sect
	Short_Addr  L&sect
ELSE
	DW	0
	DW	0
ENDIF
ENDM
	DW	0

;
; WARNING!!!  PRINT and PSPRINT *REQUIRE* ErrorMode to precede INDOS.
; Also, IBM server 1.0 requires this also.
;
	EVEN			; Force swap area to start on word boundry
PUBLIC	SWAP_START
SWAP_START	LABEL BYTE
	I_am	ErrorMode,BYTE		; Flag for INT 24 processing
	I_am	INDOS,BYTE,<0>		; DOS status for interrupt processing
	I_am	WPErr,BYTE,<-1> 	; Write protect error flag
	I_am	EXTERR_LOCUS,BYTE	; Extended Error Locus
	I_am	EXTERR,WORD,<0> 	; Extended Error code

;WARNING Following two bytes Accessed as word in $GetExtendedError
	I_am	EXTERR_ACTION,BYTE	; Extended Error Action
	I_am	EXTERR_CLASS,BYTE	; Extended Error Class
; end warning

	I_am	EXTERRPT,DWORD		; Extended Error pointer
	I_am	DMAADD,DWORD,<80h,?>	; User's disk transfer address (disp/seg)
	I_am	CurrentPDB,WORD 	; Current process identifier
	I_am	ConC_spsave,WORD	; saved SP before ^C
	I_am	exit_code,WORD		; exit code of last proc.
	I_am	CURDRV,BYTE		; Default drive (init A)
	I_am	CNTCFLAG,BYTE,<0>	; ^C check in dispatch disabled
					; F.C. 2/17/86
	I_am	CPSWFLAG,BYTE,<0>	; Code Page Switching Flag  DOS 4.00
	I_am	CPSWSAVE,BYTE,<0>	; copy of above in case of ABORT
	EVEN
 PUBLIC Swap_Always
 Swap_Always	LABEL	BYTE
	I_am	USER_IN_AX,WORD 	; User INPUT AX value (used for
					;   extended error type stuff.	NOTE:
					;   does not have Correct value on
					;   1-12, OEM, Get/Set CurrentPDB,
					;   GetExtendedError system calls
	I_am	PROC_ID,WORD,<0>	; PID for sharing (0 = local)
	I_am	USER_ID,WORD,<0>	; Machine for sharing (0 = local)
	I_am	FirstArena,WORD 	; first free block found
	I_am	BestArena,WORD		; best free block found
	I_am	LastArena,WORD		; last free block found
	I_am	EndMem,WORD		; End of memory used in DOSINIT
	I_am	LASTENT,WORD		; Last entry for directory search

	I_am	FAILERR,BYTE,<0>	; NZ if user did FAIL on I 24
	I_am	ALLOWED,BYTE,<0>	; Allowed I 24 answers (see allowed_)
	I_am	NoSetDir,BYTE		; true -> do not set directory
	I_am	DidCTRLC,BYTE		; true -> we did a ^C exit
	I_am	SpaceFlag,BYTE		; true -> embedded spaces are allowed in FCB
; Warning!  The following items are accessed as a WORD in TIME.ASM
	EVEN
	I_am	DAY,BYTE,<0>		; Day of month
	I_am	MONTH,BYTE,<0>		; Month of year
	I_am	YEAR,WORD,<0>		; Year (with century)
	I_am	DAYCNT,WORD,<-1>	; Day count from beginning of year
	I_am	WEEKDAY,BYTE,<0>	; Day of week
; end warning
	I_am	CONSWAP,BYTE		; TRUE => console was swapped during device read
	I_am	IDLEINT,BYTE,<1>	; TRUE => idle int is allowed
	I_am	fAborting,BYTE,<0>	; TRUE => abort in progress

; Combination of all device call parameters
	PUBLIC	DEVCALL 		;
DEVCALL SRHEAD	<>			; basic header for disk packet
	PUBLIC	CALLUNIT
CALLUNIT    LABEL   BYTE		; unit number for disk
CALLFLSH    LABEL   WORD		;
	I_am	CALLMED,BYTE		; media byte
CALLBR	    LABEL   DWORD		;
	PUBLIC	CALLXAD 		;
CALLXAD     LABEL   DWORD		;
	I_am	CALLRBYT,BYTE		;
	PUBLIC	CALLVIDM		;
CALLVIDM    LABEL   DWORD		;
	DB	3 DUP(?)		;
	PUBLIC CallBPB			;
CALLBPB     LABEL   DWORD		;
	I_am	CALLSCNT,WORD		;
	PUBLIC	CALLSSEC
CALLSSEC    LABEL    WORD		;
	    DW	    ?			;
	I_am	CALLVIDRW,DWORD 	;
					;
	I_am	CALLNEWSC,DWORD 	; starting sector for >32mb
	I_am	CALLDEVAD,DWORD 	; stash for device entry point
					;
; Same as above for I/O calls		;
					;
	PUBLIC	IOCall			;
IOCALL	SRHEAD	<>			;
IOFLSH	LABEL	WORD			;
	PUBLIC	IORCHR			;
IORCHR	LABEL	BYTE			;
	I_am	IOMED,BYTE		;
	I_am	IOXAD,DWORD		;
	I_am	IOSCNT,WORD		;
	I_am	IOSSEC,WORD		;
; Call struct for DSKSTATCHK		;
	I_am	DSKSTCALL,2,<DRDNDHL,0> ;
	I_am	DSKSTCOM,1,<DEVRDND>	;
	I_am	DSKSTST,WORD		;
	DB	8 DUP (0)		;
	I_am	DSKCHRET,BYTE		;
	short_addr  DEVIOBUF		;
	DW	?			; DOS segment set at Init
	I_AM	DSKSTCNT,WORD,<1>	;
	DW	0			;

	I_am	CreatePDB,BYTE		; flag for creating a process
	PUBLIC	Lock_Buffer		;
Lock_Buffer LABEL    DWORD		;MS. DOS Lock Buffer for Ext Lock
	    DD	    ?			;MS. position
	    DD	    ?			;MS. length
CONST001e	label byte

CONSTANTS	ENDS
	END
