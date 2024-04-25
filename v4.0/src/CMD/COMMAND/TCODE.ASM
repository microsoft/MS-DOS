 page 80,132
;	SCCSID = @(#)tcode.asm	1.1 85/05/14
;	SCCSID = @(#)tcode.asm	1.1 85/05/14
TITLE	Part1 COMMAND Transient Routines

	INCLUDE comsw.asm
.xlist
.xcref
	INCLUDE DOSSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm
.list
.cref


CODERES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	EXEC_WAIT:NEAR
CODERES ENDS

DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BATCH:WORD
	EXTRN	CALL_BATCH_FLAG:byte
	EXTRN	CALL_FLAG:BYTE
	EXTRN	ECHOFLAG:BYTE
	EXTRN	envirseg:word
	EXTRN	EXTCOM:BYTE
	EXTRN	FORFLAG:BYTE
	EXTRN	IFFLAG:BYTE
	EXTRN	next_batch:word
	EXTRN	nullflag:byte
	EXTRN	PIPEFILES:BYTE
	EXTRN	PIPEFLAG:BYTE
	EXTRN	RE_OUT_APP:BYTE
	EXTRN	RE_OUTSTR:BYTE
	EXTRN	RESTDIR:BYTE
	EXTRN	SINGLECOM:WORD
	EXTRN	VERVAL:WORD
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BadNam_Ptr:word 	;AC000;
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	APPEND_EXEC:BYTE	;AN041;
	EXTRN	ARG1S:WORD
	EXTRN	ARG2S:WORD
	EXTRN	ARGTS:WORD
	EXTRN	BYTCNT:WORD
	EXTRN	COMBUF:BYTE
	EXTRN	COMSW:WORD
	EXTRN	CURDRV:BYTE
	EXTRN	HEADCALL:DWORD
	EXTRN	IDLEN:BYTE
	EXTRN	INTERNATVARS:BYTE
	EXTRN	PARM1:BYTE
	EXTRN	PARM2:BYTE
	EXTRN	RE_INSTR:BYTE
	EXTRN	RESSEG:WORD
	EXTRN	SPECDRV:BYTE
	EXTRN	STACK:WORD
	EXTRN	SWITCHAR:BYTE
	EXTRN	TPA:WORD
	EXTRN	UCOMBUF:BYTE
	EXTRN	USERDIR1:BYTE
	IF  IBM
	EXTRN	ROM_CALL:BYTE
	EXTRN	ROM_CS:WORD
	EXTRN	ROM_IP:WORD
	ENDIF

TRANSPACE	ENDS

; ********************************************************************
; START OF TRANSIENT PORTION
; This code is loaded at the end of memory and may be overwritten by
; memory-intensive user programs.

TRANCODE	SEGMENT PUBLIC BYTE	;AC000;

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	$EXIT:NEAR
	EXTRN	DRVBAD:NEAR
	EXTRN	EXTERNAL:NEAR
	EXTRN	FNDCOM:NEAR
	EXTRN	FORPROC:NEAR
	EXTRN	PIPEPROC:NEAR
	EXTRN	PIPEPROCSTRT:NEAR

	PUBLIC	COMMAND
	PUBLIC	DOCOM
	PUBLIC	DOCOM1
	PUBLIC	NOPIPEPROC
	PUBLIC	TCOMMAND

	IF  IBM
	PUBLIC	ROM_EXEC
	PUBLIC	ROM_SCAN
	ENDIF

	ORG	0
ZERO	=	$

	ORG	100H				; Allow for 100H parameter area

SETDRV:
	MOV	AH,SET_DEFAULT_DRIVE
	INT	int_command
;
; TCOMMAND is the recycle point in COMMAND.  Nothing is known here.
; No registers (CS:IP) no flags, nothing.
;

TCOMMAND:
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	AX,-1
	XCHG	AX,[VERVAL]
	CMP	AX,-1
	JZ	NOSETVER2
	MOV	AH,SET_VERIFY_ON_WRITE		; AL has correct value
	INT	int_command

NOSETVER2:
	CALL	[HEADCALL]			; Make sure header fixed
	XOR	BP,BP				; Flag transient not read
	CMP	[SINGLECOM],-1
	JNZ	COMMAND

$EXITPREP:
	PUSH	CS
	POP	DS
	JMP	$EXIT				; Have finished the single command
ASSUME	DS:NOTHING
;
; Main entry point from resident portion.
;
;   If BP <> 0, then we have just loaded transient portion otherwise we are
;   just beginning the processing of another command.
;

COMMAND:

;
; We are not always sure of the state of the world at this time.  We presume
; worst case and initialize the relevant registers: segments and stack.
;
	ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	CLD
	MOV	AX,CS
	CLI
	MOV	SS,AX
ASSUME	SS:TRANGROUP
	MOV	SP,OFFSET TRANGROUP:STACK
	STI
	MOV	ES,AX
	MOV	DS,AX				;AN000; set DS to transient
ASSUME	ES:TRANGROUP,DS:TRANGROUP		;AC000;
	invoke	TSYSLOADMSG			;AN000; preload messages
	invoke	SETSTDINOFF			;AN026; turn off critical error on STDIN
	invoke	SETSTDOUTOFF			;AN026; turn off critical error on STDOUT
	mov	append_exec,0			;AN041; set internal append state off

	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP

	MOV	[UCOMBUF],COMBUFLEN		; Init UCOMBUF
	MOV	[COMBUF],COMBUFLEN		; Init COMBUF (Autoexec doing DATE)
;
; If we have just loaded the transient, then we do NOT need to initialize the
; command buffer.  ????  DO WE NEED TO RESTORE THE USERS DIRECTORY ????  I
; guess not:  the only circumstances in which we reload the command processor
; is after a transient program execution.  In this case, we let the current
; directory lie where it may.
;
	OR	BP,BP				; See if just read
	JZ	TESTRDIR			; Not read, check user directory
	MOV	WORD PTR [UCOMBUF+1],0D01H	; Reset buffer
	JMP	SHORT NOSETBUF

TESTRDIR:
	CMP	[RESTDIR],0
	JZ	NOSETBUF			; User directory OK
	PUSH	DS
;
; We have an unusual situation to handle.  The user *may* have changed his
; directory as a result of an internal command that got aborted.  Restoring it
; twice may not help us:  the problem may never go away.  We just attempt it
; once and give up.
;
	MOV	[RESTDIR],0			; Flag users dirs OK
	PUSH	CS
	POP	DS
ASSUME	DS:TRANGROUP
	MOV	DX,OFFSET TRANGROUP:USERDIR1
	MOV	AH,CHDIR
	INT	int_command			; Restore users directory
	POP	DS
ASSUME	DS:RESGROUP

NOSETBUF:
	CMP	[PIPEFILES],0
	JZ	NOPCLOSE			; Don't bother if they don't exist
	CMP	[PIPEFLAG],0
	JNZ	NOPCLOSE			; Don't del if still piping
	INVOKE	PIPEDEL

NOPCLOSE:
	MOV	[EXTCOM],0			; Flag internal command
	MOV	AX,CS				; Get segment we're in
	MOV	DS,AX
ASSUME	DS:TRANGROUP

	PUSH	AX
	MOV	DX,OFFSET TRANGROUP:INTERNATVARS
	MOV	AX,INTERNATIONAL SHL 8
	INT	21H
	POP	AX
	SUB	AX,[TPA]			; AX=size of TPA in paragraphs
	PUSH	BX
	MOV	BX,16
	MUL	BX				; DX:AX=size of TPA in bytes
	POP	BX
	OR	DX,DX				; See if over 64K
	JZ	SAVSIZ				; OK if not
	MOV	AX,-1				; If so, limit to 65535 bytes

SAVSIZ:
;
; AX is the number of bytes free in the buffer between the resident and the
; transient with a maximum of 64K-1.  We round this down to a multiple of 512.
;
	CMP	AX,512
	JBE	GotSize
	AND	AX,0FE00h			; NOT 511 = NOT 1FF

GotSize:
	MOV	[BYTCNT],AX			; Max no. of bytes that can be buffered
	MOV	DS,[RESSEG]			; All batch work must use resident seg.
ASSUME	DS:RESGROUP

	TEST	[ECHOFLAG],1
	JZ	GETCOM				; Don't do the CRLF
	INVOKE	SINGLETEST
	JB	GETCOM
	TEST	[PIPEFLAG],-1
	JNZ	GETCOM
	TEST	[FORFLAG],-1			; G  Don't print prompt in FOR
	JNZ	GETCOM				; G
	TEST	[BATCH], -1			; G  Don't print prompt if in batch
	JNZ	GETCOM				; G
	INVOKE	CRLF2

GETCOM:
	MOV	CALL_FLAG,0			; G Reset call flags
	MOV	CALL_BATCH_FLAG,0		; G
	MOV	AH,GET_DEFAULT_DRIVE
	INT	int_command
	MOV	[CURDRV],AL
	TEST	[PIPEFLAG],-1			; Pipe has highest presedence
	JZ	NOPIPE
	JMP	PIPEPROC			; Continue the pipeline

NOPIPE:
	TEST	[ECHOFLAG],1
	JZ	NOPDRV				; No prompt if echo off
	INVOKE	SINGLETEST
	JB	NOPDRV
	TEST	[FORFLAG],-1			; G  Don't print prompt in FOR
	JNZ	NOPDRV				; G
	TEST	[BATCH], -1			; G  Don't print prompt if in batch
	JNZ	TESTFORBAT			; G
	INVOKE	PRINT_PROMPT			; Prompt the user

NOPDRV:
	TEST	[FORFLAG],-1			; FOR has next highest precedence
	JZ	TESTFORbat
	JMP	FORPROC 			; Continue the FOR

TESTFORBAT:
	MOV	[RE_INSTR],0			; Turn redirection back off
	MOV	[RE_OUTSTR],0
	MOV	[RE_OUT_APP],0
	MOV	IFFlag,0			; no more ifs...
	TEST	[BATCH],-1			; Batch has lowest precedence
	JZ	ISNOBAT

	push	es				;AN000; save ES
	push	ds				;AN000; save DS
	mov	ax,mult_shell_get		;AN000; check to see if SHELL has command
	mov	es,[batch]			;AN000; get batch segment
	mov	di,batfile			;AN000; get batch file name
	push	cs				;AN000; get local segment to DS
	pop	ds				;AN000;
	mov	dx,offset trangroup:combuf	;AN000; pass communications buffer
	int	2fh				;AN000; call the shell
	cmp	al,shell_action 		;AN000; does shell have a commmand?
	pop	ds				;AN000; restore DS
	pop	es				;AN000; restore ES
	jz	jdocom1 			;AN000; yes - go process command

	PUSH	DS				;G
	INVOKE	READBAT 			; Continue BATCH
	POP	DS				;G
	mov	nullflag,0			;G reset no command flag
	TEST	[BATCH],-1			;G
	JNZ	JDOCOM1 			;G if batch still in progress continue
	MOV	BX,NEXT_BATCH			;G
	CMP	BX,0				;G see if there is a new batch file
	JZ	JDOCOM1 			;G no - go do command
	MOV	BATCH,BX			;G get segment of next batch file
	MOV	NEXT_BATCH,0			;G reset next batch
JDOCOM1:
	PUSH	CS				;G
	POP	DS				;G
	JMP SHORT DoCom1			; echoing already done

ISNOBAT:
	CMP	[SINGLECOM],0
	JZ	REGCOM
	MOV	SI,-1
	XCHG	SI,[SINGLECOM]
	MOV	DI,OFFSET TRANGROUP:COMBUF + 2
	XOR	CX,CX

SINGLELOOP:
	LODSB
	STOSB
	INC	CX
	CMP	AL,0DH
	JNZ	SINGLELOOP
	DEC	CX
	PUSH	CS
	POP	DS
ASSUME	DS:TRANGROUP
	MOV	[COMBUF + 1],CL
;
; do NOT issue a trailing CRLF...
;
	JMP	DOCOM1

;
; We have a normal command.  
; Printers are a bizarre quantity.  Sometimes they are a stream and
; sometimes they aren't.  At this point, we automatically close all spool
; files and turn on truncation mode.
;

REGCOM:
	MOV	AX,(ServerCall SHL 8) + 9
	INT	21h
	MOV	AX,(ServerCall SHL 8) + 8
	MOV	DL,1
	INT	21h

	PUSH	CS
	POP	DS				; Need local segment to point to buffer
	MOV	DX,OFFSET TRANGROUP:UCOMBUF
	MOV	AH,STD_CON_STRING_INPUT
	INT	int_command			; Get a command
	MOV	CL,[UCOMBUF]
	XOR	CH,CH
	ADD	CX,3
	MOV	SI,OFFSET TRANGROUP:UCOMBUF
	MOV	DI,OFFSET TRANGROUP:COMBUF
	REP	MOVSB				; Transfer it to the cooked buffer

;---------------

transpace   segment
    extrn   arg:byte				; the arg structure!
transpace   ends
;---------------


DOCOM:
	INVOKE	CRLF2

DOCOM1:
	INVOKE	PRESCAN 			; Cook the input buffer
	JZ	NOPIPEPROC
	JMP	PIPEPROCSTRT			; Fire up the pipe

nullcomj:
	jmp	nullcom

NOPIPEPROC:
	invoke	parseline
	jnc	OkParse 			; user error?  or maybe we goofed?

BadParse:
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET TRANGROUP:BADNAM_ptr
	INVOKE	std_eprintf
	JMP	TCOMMAND

OkParse:
	test	arg.argv[0].argflags, MASK wildcard
	jnz	BadParse			; ambiguous commands not allowed
	cmp	arg.argvcnt, 0			; there WAS a command, wasn't there?
	jz	nullcomj
	cmp	arg.argv[0].arglen, 0		; probably an unnecessary check...
	jz	nullcomj			; guarantees argv[0] at least x<NULL>

	MOV	SI,OFFSET TRANGROUP:COMBUF+2
	MOV	DI,OFFSET TRANGROUP:IDLEN
	MOV	AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H ; Make FCB with blank scan-off
	INT	int_command
	mov	BX, arg.argv[0].argpointer
	cmp	BYTE PTR [BX+1],':'             ; was a drive specified?
	jne	short drvgd			; no, use default of zero...

	mov	DL, BYTE PTR [BX]		; pick-up drive letter
	and	DL, NOT 20H			; uppercase the sucker
	sub	DL, capital_A			; convert it to a drive number, A=0

	CMP	AL,-1				; See what PARSE said about our drive letter.
	JZ	drvbadj2			; It was invalid.

	mov	DI, arg.argv[0].argstartel
	cmp	BYTE PTR [DI], 0		; is there actually a command there?
	jnz	drvgd				; if not, we have:  "d:", "d:\", "d:/"
	jmp	setdrv				; and set drive to new drive spec

drvbadj2:
	jmp	drvbad

DRVGD:
	MOV	AL,[DI]
	MOV	[SPECDRV],AL
	MOV	AL,' '
	MOV	CX,9
	INC	DI
	REPNE	SCASB				; Count no. of letters in command name
	MOV	AL,8
	SUB	AL,CL
	MOV	[IDLEN],AL			; IDLEN is truly the length
	MOV	DI,81H
	PUSH	SI

	mov	si, OFFSET TRANGROUP:COMBUF+2	; Skip over all leading delims
	invoke	scanoff

do_skipcom:
	lodsb					; move command line pointer over
	invoke	delim				; pathname -- have to do it ourselves
	jz	do_skipped			; 'cause parse_file_descriptor is dumb
	cmp	AL, 0DH 			; can't always depend on argv[0].arglen
	jz	do_skipped			; to be the same length as the user-
	cmp	AL, [SWITCHAR]			; specified command string
	jnz	do_skipcom

do_skipped:
	dec	SI
	XOR	CX,CX

COMTAIL:
	LODSB
	STOSB					; Move command tail to 80H
	CMP	AL,13
	LOOPNZ	COMTAIL
	DEC	DI
	MOV	BP,DI
	NOT	CL
	MOV	BYTE PTR DS:[80H],CL
	POP	SI

;-----
; Some of these comments are sadly at odds with this brave new code.
;-----
; If the command has 0 parameters must check here for
; any switches that might be present.
; SI -> first character after the command.

	mov	DI, arg.argv[0].argsw_word
	mov	[COMSW], DI			; ah yes, the old addressing mode problem...
	mov	SI, arg.argv[1 * SIZE argv_ele].argpointer  ; s = argv[1];
	OR	SI,SI				;   if (s == NULL)
	JNZ	DoParse
	MOV	SI,BP				;	s = bp; (buffer end)

DoParse:
	MOV	DI,FCB
	MOV	AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
	INT	int_command
	MOV	[PARM1],AL			; Save result of parse

	mov	DI, arg.argv[1*SIZE argv_ele].argsw_word
	mov	[ARG1S], DI
	mov	SI, arg.argv[2*SIZE argv_ele].argpointer    ; s = argv[2];
	OR	SI,SI				;   if (s == NULL)
	JNZ	DoParse2
	MOV	SI,BP				;	s = bp; (bufend)1

DoParse2:
	MOV	DI,FCB+10H
	MOV	AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
	INT	int_command			; Parse file name
	MOV	[PARM2],AL			; Save result

	mov	DI, arg.argv[2*SIZE argv_ele].argsw_word
	mov	[ARG2S], DI
	mov	DI, arg.argv[0].argsw_word
	not	DI				; ARGTS doesn't include the flags
	and	DI, arg.argswinfo		; from COMSW...
	mov	[ARGTS], DI

	MOV	AL,[IDLEN]
	MOV	DL,[SPECDRV]
	or	DL, DL				; if a drive was specified...
	jnz	externalj1			; it MUST be external, by this time
	dec	al				; (I don't know why -- old code did it)
	jmp	fndcom				; otherwise, check internal com table

externalj1:
	jmp	external

nullcom:
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	TEST	[BATCH], -1			;G Are we in a batch file?
	JZ	nosetflag			;G only set flag if in batch
	mov	nullflag,nullcommand		;G set flag to indicate no command

nosetflag:
	CMP	[SINGLECOM],-1
	JZ	EXITJ
	JMP	GETCOM

EXITJ:
	JMP	$EXITPREP

IF IBM
	include mshalo.asm
ENDIF

TRANCODE	ENDS
	END
