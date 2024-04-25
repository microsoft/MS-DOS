 page 80,132
;	SCCSID = @(#)command1.asm	1.1 85/05/14
;	SCCSID = @(#)command1.asm	1.1 85/05/14
TITLE	COMMAND - resident code for COMMAND.COM
NAME	COMMAND

;*****************************************************************************
;
; MODULE:	       COMMAND.COM
;
; DESCRIPTIVE NAME:    Default DOS command interpreter
;
; FUNCTION:	       This version of COMMAND is divided into three distinct
;		       parts.  First is the resident portion, which includes
;		       handlers for interrupts	23H (Cntrl-C), 24H (fatal
;		       error), and 2EH (command line execute); it also has
;		       code to test and, if necessary, reload the transient
;		       portion. Following the resident is the init code, which
;		       is overwritten after use.  Then comes the transient
;		       portion, which includes all command processing (whether
;		       internal or external).  The transient portion loads at
;		       the end of physical memory, and it may be overlayed by
;		       programs that need as much memory as possible. When the
;		       resident portion of command regains control from a user
;		       program, a check sum is performed on the transient
;		       portion to see if it must be reloaded.  Thus programs
;		       which do not need maximum memory will save the time
;		       required to reload COMMAND when they terminate.
;
; ENTRY POINT:	       PROGSTART
;
; INPUT:	       command line at offset 81H
;
; EXIT_NORMAL:	       No exit from root level command processor.  Can exit
;		       from a secondary command processor via the EXIT
;		       internal command.
;
; EXIT_ERROR:	       Exit to prior command processor if possible, otherwise
;		       hang the system.
;
; INTERNAL REFERENCES:
;
;     ROUTINES:        See the COMMAND Subroutine Description Document
;		       (COMMAND.DOC)
;
;     DATA AREAS:      See the COMMAND Subroutine Description Document
;		       (COMMAND.DOC)
;
; EXTERNAL REFERENCES:
;
;      ROUTINES:       none
;
;      DATA AREAS:     none
;
;*****************************************************************************
;
;			      REVISION HISTORY
;			      ----------------
;
; DOS 1.00 to DOS 3.30
; --------------------------
; SEE REVISION LOG IN COPY.ASM ALSO
;
; REV 1.17
;    05/19/82  Fixed bug in BADEXE error (relocation error must return to
;	       resident since the EXELOAD may have overwritten the transient.
;
; REV 1.18
;    05/21/82  IBM version always looks on drive A
;	       MSVER always looks on default drive
;
; REV 1.19
;    06/03/82  Drive spec now entered in command line
;    06/07/82  Added VER command (print DOS version number) and VOL command
;	       (print volume label)
;
; REV 1.20
;    06/09/82  Prints "directory" after directories
;    06/13/82  MKDIR, CHDIR, PWD, RMDIR added
;
; REV 1.50
;	       Some code for new 2.0 DOS, sort of HACKey.  Not enough time to
;	       do it right.
;
; REV 1.70
;	       EXEC used to fork off new processes
;
; REV 1.80
;	       C switch for single command execution
;
; REV 1.90
;	       Batch uses XENIX
;
; Rev 2.00
;	       Lots of neato stuff
;	       IBM 2.00 level
;
; Rev 2.01
;	       'D' switch for date time suppression
;
; Rev 2.02
;	       Default userpath is NUL rather than BIN
;		       same as IBM
;	       COMMAND split into pieces
;
; Rev 2.10
;	       INTERNATIONAL SUPPORT
;
; Rev 2.50
;	       all the 2.x new stuff -MU
;
; Rev 3.30     (Ellen G)
;	       CALL internal command (TBATCH2.ASM)
;	       CHCP internal command (TCMD2B.ASM)
;	       INT 24H support of abort, retry, ignore, and fail prompt
;	       @ sign suppression of batch file line
;	       Replaceable environment value support in batch files
;	       INT 2FH calls for APPEND
;	       Lots of PTR fixes!
;
; Beyond 3.30 to forever  (Ellen G)
; ----------------------
;
; A000 DOS 4.00  -	Use SYSPARSE for internal commands
;			Use Message Retriever services
;			/MSG switch for resident extended error msg
;			Convert to new capitalization support
;			Better error recovery on CHCP command
;			Code page file tag support
;			TRUENAME internal command
;			Extended screen line support
;			/P switch on DEL/ERASE command
;			Improved file redirection error recovery
;	(removed)	Improved batch file performance
;			Unconditional DBCS support
;			Volume serial number support
;	(removed)	COMMENT=?? support
;
; A001	PTM P20 	Move system_cpage from TDATA to TSPC
;
; A002	PTM P74 	Fix PRESCAN so that redirection symbols do not
;			require delimiters.
;
; A003	PTM P5,P9,P111	Included in A000 development
;
; A004	PTM P86 	Fix IF command to turn off piping before
;			executing
;
; A005	DCR D17 	If user specifies an extension on the command
;			line search for that extension only.
;
; A006	DCR D15 	New message for MkDir - "Directory already
;			exists"
;
; A007	DCR D2		Change CTTY so that a write is done before XDUP
;
; A008	PTM P182	Change COPY to set default if invalid function
;			returned from code page call.
;
; A009	PTM P179	Add CRLF to invalid disk change message
;
; A010	DCR D43 	Allow APPEND to do a far call to SYSPARSE in
;			transient COMMAND.
;
; A011	DCR D130	Change redirection to overwrite an EOF mark
;			before appending to a file.
;
; A012	PTM P189	Fix redirection error recovery.
;
; A013	PTM P330	Change date format
;
; A014	PTM P455	Fix echo parsing
;
; A015	PTM P517	Fix DIR problem with * vs *.
;
; A016	PTM P354	Fix extended error message addressing
;
; A017	PTM P448	Fix appending to 0 length files
;
; A018	PTM P566,P3903	Fix parse error messages to print out parameter
;			the parser fails on. Fail on duplicate switches.
;
; A019	PTM P542	Fix device name to be printed correctly during
;			critical error
;
; A020	DCR D43 	Set append state off while in DIR
;
; A021	PTM P709	Fix CTTY printing ascii characters.
;
; A022	DCR D209	Enhanced error recovery
;
; A023	PTM P911	Fix ANSI.SYS IOCTL structure.
;
; A024	PTM P899	Fix EXTOPEN open modes.
;
; A025	PTM P922	Fix messages and optimize PARSE switches
;
; A026	DCR D191	Change redirection error recovery support.
;
; A027	PTM P991	Fix so that KAUTOBAT & AUTOEXEC are terminated
;			with a carriage return.
;
; A028	PTM P1076	Print a blank line before printing invalid
;			date and invalid time messages.
;
; A029	PTM P1084	Eliminate calls to parse_check_eol in DATE
;			and TIME.
;
; A030	DCR D201	New extended attribute format.
;
; A031	PTM P1149	Fix DATE/TIME add blank before prompt.
;
; A032	PTM P931	Fix =ON, =OFF for BREAK, VERIFY, ECHO
;
; A033	PTM P1298	Fix problem with system crashes on ECHO >""
;
; A034	PTM P1387	Fix COPY D:fname+,, to work
;
; A035	PTM P1407	Fix so that >> (appending) to a device does
;			do a read to determine eof.
;
; A036	PTM P1406	Use 69h instead of 44h to get volume serial
;			so that ASSIGN works correctly.
;
; A037	PTM P1335	Fix COMMAND /C with FOR
;
; A038	PTM P1635	Fix COPY so that it doesn't accept /V /V
;
; A039	DCR D284	Change invalid code page tag from -1 to 0.
;
; A040	PTM P1787	Fix redirection to cause error when no file is
;			specified.
;
; A041	PTM P1705	Close redirected files after internal APPEND
;			executes.
;
; A042	PTM P1276	Fix problem of APPEND paths changes in batch
;			files causing loss of batch file.
;
; A043	PTM P2208	Make sure redirection is not set up twice for
;			CALL'ed batch files.
;
; A044	PTM P2315	Set switch on PARSE so that 0ah is not used
;			as an end of line character
;
; A045	PTM P2560	Make sure we don't lose parse, critical error,
;			and extended message pointers when we EXIT if
;			COMMAND /P is the top level process.
;
; A046	PTM P2690	Change COPY message "fn File not found" to
;			"File not found - fn"
;
; A047	PTM P2819	Fix transient reload prompt message
;
; A048	PTM P2824	Fix COPY path to be upper cased.  This was broken
;			when DBCS code was added.
;
; A049	PTM P2891	Fix PATH so that it doesn't accept extra characters
;			on line.
;
; A050	PTM P3030	Fix TYPE to work properly on files > 64K
;
; A051	PTM P3011	Fix DIR header to be compatible with prior releases.
;
; A052	PTM P3063,P3228 Fix COPY message for invalid filename on target.
;
; A053	PTM P2865	Fix DIR to work in 40 column mode.
;
; A054	PTM P3407	Code reduction and critical error on single line
;	PTM P3672	(Change to single parser exported under P3407)
;
; A055	PTM P3282	Reset message service variables in INT 23h to fix
;			problems with breaking out of INT 24h
;
; A056	PTM P3389	Fix problem of environment overlaying transient.
;
; A057	PTM P3384	Fix COMMAND /C so that it works if there is no space
;			before the "string".  EX: COMMAND /CDIR
;
; A058	PTM P3493	Fix DBCS so that CPARSE eats second character of
;			DBCS switch.
;
; A059	PTM P3394	Change the TIME command to right align the display of
;			the time.
;
; A060	PTM P3672	Code reduction - change PARSE and EXTENDED ERROR
;			messages to be disk based.  Only keep them if /MSG
;			is used.
;
; A061	PTM P3928	Fix so that transient doesn't reload when breaking
;			out of internal commands, due to substitution blocks
;			not being reset.
;
; A062	PTM P4079	Fix segment override for fetching address of environment
;			of parent copy of COMMAND when no COMSPEC exists in
;			secondary copy of environment.	Change default slash in
;			default comspec string to backslash.

; A063	PTM P4140	REDIRECTOR and IFSFUNC changed interface for getting
;			text for critical error messages.

; A064	PTM P4934	Multiplex number for ANSI.SYS changed due to conflict
;	5/20/88 	with Microsoft product already shipped.

; A065	PTM P4935	Multiplex number for SHELL changed due to conflict with
;	 5/20/88	with Microsoft product already shipped.

; A066	PTM P4961	DIR /W /P scrolled first line off the screen in some
;	 5/24/88	cases; where the listing would barely fit without the
;			header and space remaining.

; A067	PTM P5011	For /E: values of 993 to 1024 the COMSPEC was getting
;	 6/6/88 	trashed.  Turns out that the SETBLOCK for the new
;			environment was putting a "Z block" marker in the old
;			environment.  The fix is to move to the old environment
;			to the new environment before doing the SETBLOCK.
;***********************************************************************************

.XCREF
.XLIST
	INCLUDE DOSSYM.INC
	INCLUDE comsw.asm
	INCLUDE comequ.asm
	INCLUDE resmsg.equ		;AN000;
.LIST
.CREF

CODERES 	SEGMENT PUBLIC BYTE	;AC000;
CODERES ENDS

DATARES SEGMENT PUBLIC BYTE
	EXTRN	BATCH:WORD
	EXTRN	ECHOFLAG:BYTE
	EXTRN	disp_class:byte 	;AN055;
	EXTRN	execemes_block:byte	;AC000;
	EXTRN	execemes_off:word	;AC000;
	EXTRN	execemes_subst:byte	;AC000;
	EXTRN	execemes_seg:word	;AC000;
	EXTRN	EXTCOM:BYTE
	EXTRN	FORFLAG:BYTE
	EXTRN	IFFlag:BYTE
	EXTRN	InitFlag:BYTE
	EXTRN	NEST:WORD
	EXTRN	number_subst:byte	;AC000;
	EXTRN	PIPEFLAG:BYTE
	EXTRN	RETCODE:WORD
	EXTRN	SINGLECOM:WORD
DATARES ENDS

BATARENA	SEGMENT PUBLIC PARA	;AC000;
BATARENA ENDS

BATSEG		SEGMENT PUBLIC PARA	;AC000;
BATSEG	 ENDS

ENVARENA	SEGMENT PUBLIC PARA	;AC000;
ENVARENA  ENDS

ENVIRONMENT SEGMENT PUBLIC PARA 	; Default COMMAND environment
ENVIRONMENT ENDS

INIT	SEGMENT PUBLIC PARA
	EXTRN	CONPROC:NEAR
	EXTRN	init_contc_specialcase:near
INIT	ENDS

TAIL	SEGMENT PUBLIC PARA
TAIL	ENDS

TRANCODE	SEGMENT PUBLIC PARA
TRANCODE	ENDS

TRANDATA	SEGMENT PUBLIC BYTE
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE
TRANSPACE	ENDS

TRANTAIL	SEGMENT PUBLIC PARA
TRANTAIL	ENDS

RESGROUP  GROUP CODERES,DATARES,BATARENA,BATSEG,ENVARENA,ENVIRONMENT,INIT,TAIL
TRANGROUP GROUP TRANCODE,TRANDATA,TRANSPACE,TRANTAIL

	INCLUDE envdata.asm

; START OF RESIDENT PORTION

CODERES 	SEGMENT PUBLIC BYTE	;AC000;


	PUBLIC	EXT_EXEC
	PUBLIC	CONTC
	PUBLIC	Exec_Wait

ASSUME	CS:RESGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	lodcom:near
	EXTRN	LODCOM1:near

	ORG	0
ZERO	=	$

	ORG 80h-1
	PUBLIC	RESCOM
RESCOM	LABEL BYTE

	ORG	100H

PROGSTART:
	JMP	RESGROUP:CONPROC

;
; COMMAND has issued an EXEC system call and it has returned an error.	We
; examine the error code and select an appropriate message.
;
EXEC_ERR:
	push	ds				;AC000; get transient segment
	pop	es				;AC000;     into ES
	push	cs				;AC000; get resident segment
	pop	ds				;AC000;     into DS
ASSUME	DS:RESGROUP				;AN000;
	MOV	BX,RBADNAM			;AC000; Get message number for Bad command
	CMP	AX,error_file_not_found
	JZ	GOTEXECEMES
	MOV	BX,TOOBIG			;AC000; Get message number for file not found
	CMP	AX,error_not_enough_memory
	JZ	GOTEXECEMES
	MOV	BX,EXEBAD			;AC000; Get message number for bad exe file
	CMP	AX,error_bad_format
	JZ	GOTEXECEMES
	MOV	BX,AccDen			;AC000; Get message number for access denied
	CMP	AX,error_access_denied
	JZ	GOTEXECEMES			;AC000; go print message

DEFAULT_MESSAGE:
	MOV	BX,EXECEMES			;AC000; Get message number for default message
	MOV	EXECEMES_OFF,DX 		;AN000; put offset of EXEC string in subst block
	MOV	EXECEMES_SEG,ES 		;AN000; put segment of EXEC string in subst block
	MOV	AL,EXECEMES_SUBST		;AN000; get number of substitutions
	MOV	NUMBER_SUBST,AL 		;AN000;
	MOV	SI,OFFSET RESGROUP:EXECEMES_BLOCK ;AN000; get address of subst block
GOTEXECEMES:
	PUSH	CS
	POP	ES				;AC000; get resident segment into ES
ASSUME	ES:RESGROUP				;AN000;
	MOV	DX,BX				;AN000; get message number in DX
	INVOKE	RPRINT
	JMP	SHORT NOEXEC
;
; The transient has set up everything for an EXEC system call.	For
; cleanliness, we issue the EXEC here in the resident so that we may be able
; to recover cleanly upon success.
;
EXT_EXEC:
	push	dx				;AN000; save the command name offset
	INT	int_command			; Do the EXEC
	pop	dx				;AN000; restore the command name offset
	JC	EXEC_ERR			; EXEC failed
;
; The exec has completed.  Retrieve the exit code.
;
EXEC_WAIT:
	push	cs				;AC000; get resident segment
	pop	ds				;AC000;     into DS
	MOV	AH,WAITPROCESS			;AC000; Get errorlevel
	INT	int_command			; Get the return code
	MOV	[RETCODE],AX
;
; We need to test to see if we can reload the transient.  THe external command
; may have overwritten part of the transient.
;
NOEXEC:
	JMP	LODCOM
;
; This is the default system INT 23 handler.  All processes (including
; COMMAND) get it by default.  There are some games that are played:  We
; ignore ^C during most of the INIT code.  This is because we may perform an
; ALLOC and diddle the header!	Also, if we are prompting for date/time in the
; init code, we are to treat ^C as empty responses.
;
CONTC	PROC	FAR
	ASSUME	CS:ResGroup,DS:NOTHING,ES:NOTHING,SS:NOTHING
	test	InitFlag,initINIT		; in initialization?
	jz	NotAtInit			; no
	test	InitFlag,initSpecial		; doing special stuff?
	jz	CmdIRet 			; no, ignore ^C
	jmp	resgroup:init_contc_specialcase ; Yes, go handle it
CmdIret:
	iret					; yes, ignore the ^C
NotAtInit:
	test	InitFlag,initCtrlC		; are we already in a ^C?
	jz	NotInit 			; nope too.
;
; We are interrupting ourselves in this ^C handler.  We need to set carry
; and return to the user sans flags only if the system call was a 1-12 one.
; Otherwise, we ignore the ^C.
;
	cmp	ah,1
	jb	CmdIRet
	cmp	ah,12
	ja	CmdIRet
	add	sp,6				; remove int frame
	stc
	ret	2				; remove those flags...
;
; We have now received a ^C for some process (maybe ourselves but not at INIT).
;
; Note that we are running on the user's stack!!!  Bad news if any of the
; system calls below go and issue another INT 24...  Massive stack overflow!
; Another bad point is that SavHand will save an already saved handle, thus
; losing a possible redirection...
;
; All we need to do is set the flag to indicate nested ^C.  The above code
; will correctly flag the ^C diring the message output and prompting while
; ignoring the ^C the rest of the time.
;
; Clean up: flush disk.  If we are in the middle of a batch file, we ask if
; he wants to terminate it.  If he does, then we turn off all internal flags
; and let the DOS abort.
;
NotInit:
	or	InitFlag,initCtrlC		; nested ^c is on
	STI
	PUSH	CS				; El Yucko!  Change the user's DS!!
	POP	DS
ASSUME	DS:RESGROUP
	MOV	DISP_CLASS,UTIL_MSG_CLASS	;AN055; reset display class
	MOV	NUMBER_SUBST,NO_SUBST		;AN055; reset number of substitutions
	MOV	AX,SingleCom
	OR	AX,AX
	JNZ	NoReset
	PUSH	AX
	MOV	AH,DISK_RESET
	INT	int_command			; Reset disks in case files were open
	POP	AX
NoReset:
;
; In the generalized version of FOR, PIPE and BATCH, we would walk the entire
; active list and free each segment.  Here, we just free the single batch
; segment.
;
	TEST	Batch,-1
	JZ	CONTCTERM
	OR	AX,AX
	JNZ	Contcterm
	invoke	SavHand
	invoke	ASKEND				; See if user wants to terminate batch
;
; If the carry flag is clear, we do NOT free up the batch file
;
	JNC	ContBatch
	mov	cl,echoflag			;AN000; get current echo flag
	PUSH	BX				;G

ClearBatch:
	MOV	ES,[BATCH]			; get batch segment
	mov	di,batfile			;AN000; get offset of batch file name
	mov	ax,mult_shell_brk		;AN000; does the SHELL want this terminated?
	int	2fh				;AN000; call the SHELL
	cmp	al,shell_action 		;AN000; does shell want this batch?
	jz	shell_bat_cont			;AN000; yes - keep it

	MOV	BX,ES:[BATFORPTR]		;G get old FOR segment
	cmp	bx,0				;G is a FOR in progress
	jz	no_bat_for			;G no - don't deallocate
	push	es				;G
	mov	es,bx				;G yes - free it up...
	MOV	AH,DEALLOC			;G
	INT	21H				;G
	pop	es				;G restore to batch segment

no_bat_for:
	mov	cl,ES:[batechoflag]		;G get old echo flag
	MOV	BX,ES:[BATLAST] 		;G get old batch segment
	MOV	AH,DEALLOC			; free it up...
	INT	21H
	MOV	[BATCH],BX			;G get ready to deallocate next batch
	DEC	NEST				;G Is there another batch file?
	JNZ	CLEARBATCH			;G Keep going until no batch file

;
; We are terminating a batch file; restore the echo status
;

shell_bat_cont: 				;AN000; continue batch for SHELL

	POP	BX				;G
	MOV	ECHOFLAG,CL			;G reset echo status
	MOV	PIPEFLAG,0			;G turn off pipeflag
ContBatch:
	invoke	CRLF				;G print out crlf before returning
	invoke	RestHand
;
; Yes, we are terminating.  Turn off flags and allow the DOS to abort.
;
CONTCTERM:
	XOR	AX,AX				; Indicate no read
	MOV	BP,AX
;
; The following resetting of the state flags is good for the generalized batch
; processing.
;
	MOV	IfFlag,AL			; turn off iffing
	MOV	[FORFLAG],AL			; Turn off for processing
	call	ResPipeOff
	CMP	[SINGLECOM],AX			; See if we need to set SINGLECOM
	JZ	NOSETSING
	MOV	[SINGLECOM],-1			; Cause termination on pipe, batch, for
NOSETSING:
;
; If we are doing an internal command, go through the reload process.  If we
; are doing an external, let DOS abort the process.  In both cases, we are
; now done with the ^C processing.
;
	AND	InitFlag,NOT initCtrlC
	CMP	[EXTCOM],AL
	JNZ	DODAB				; Internal ^C
	JMP	LODCOM1
DODAB:
	STC					; Tell DOS to abort
	RET					; Leave flags on stack
ContC	ENDP

public	ResPipeOff
	assume	ds:nothing,es:nothing
ResPipeOff:
	SaveReg <AX>
	xor	ax,ax
	xchg	PipeFlag,al
	or	al,al
	jz	NoPipePop
	shr	EchoFlag,1
NoPipePop:
	RestoreReg  <AX>
	return
CODERES ENDS
	END	PROGSTART
