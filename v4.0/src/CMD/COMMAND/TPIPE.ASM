 page 80,132
;	SCCSID = @(#)tpipe.asm	1.1 85/05/14
;	SCCSID = @(#)tpipe.asm	1.1 85/05/14
TITLE	PART8 COMMAND Transient routines.


	INCLUDE comsw.asm
.xlist
.xcref
	INCLUDE DOSSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm
.list
.cref


DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	ECHOFLAG:BYTE
	EXTRN	InitFlag:byte
	EXTRN	INPIPEPTR:WORD
	EXTRN	OUTPIPEPTR:WORD
	EXTRN	PIPE1:BYTE
	EXTRN	PIPE1T:BYTE
	EXTRN	PIPE2:BYTE
	EXTRN	PIPE2T:BYTE
	EXTRN	PIPEFILES:BYTE
	EXTRN	PIPEFLAG:BYTE
	EXTRN	PIPEPTR:WORD
	EXTRN	RESTDIR:BYTE
	EXTRN	SINGLECOM:WORD
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BADDAT_PTR:WORD
	EXTRN	BADTIM_PTR:WORD
	EXTRN	curdat_mo_day:word	;AN000;
	EXTRN	CURDAT_PTR:WORD
	EXTRN	curdat_yr:word		;AN000;
	EXTRN	curtim_hr_min:word	;AN000;
	EXTRN	CURTIM_PTR:WORD
	EXTRN	curtim_sec_hn:word	;AN000;
	EXTRN	eurdat_ptr:word
	EXTRN	japdat_ptr:word
	EXTRN	newdat_format:word	;AN000;
	EXTRN	NEWDAT_PTR:WORD
	EXTRN	NEWTIM_PTR:WORD
	EXTRN	parse_date:byte 	;AN000;
	EXTRN	parse_time:byte 	;AN000;
	EXTRN	PIPEEMES_PTR:WORD
	EXTRN	promtim_hr_min:word	;AN000;
	EXTRN	promtim_ptr:word	;AN000;
	EXTRN	promtim_sec_hn:word	;AN000;
	EXTRN	STRING_BUF_PTR:WORD	;AC000;
	EXTRN	SYNTMES_PTR:WORD
	EXTRN	usadat_ptr:word

TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	COMBUF:BYTE
	EXTRN	date_day:byte		;AN000;
	EXTRN	date_month:byte 	;AN000;
	EXTRN	date_year:word		;AN000;
	EXTRN	INTERNATVARS:BYTE
	EXTRN	RESSEG:WORD
	EXTRN	time_fraction:byte	;AN000;
	EXTRN	time_hour:byte		;AN000;
	EXTRN	time_minutes:byte	;AN000;
	EXTRN	time_seconds:byte	;AN000;
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE
ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	CERROR:NEAR
	EXTRN	NOPIPEPROC:NEAR
	EXTRN	STD_PRINTF:NEAR
	EXTRN	TCOMMAND:NEAR
	EXTRN	TESTDOREIN:NEAR
	EXTRN	TESTDOREOUT:NEAR
	EXTRN	TESTKANJ:NEAR		;AN000;3/3/KK
	EXTRN	TSYSGETMSG:NEAR 	;AN000;

	PUBLIC	CTIME
	PUBLIC	DATE
	PUBLIC	DATINIT
	PUBLIC	PIPEDEL
	PUBLIC	PIPEERRSYN
	PUBLIC	PIPEPROC
	PUBLIC	PIPEPROCSTRT
	PUBLIC	PRINT_TIME
	PUBLIC	SETREST
	PUBLIC	SETREST1
	PUBLIC	SINGLETEST

SINGLETEST:
	ASSUME	DS:NOTHING
	push	ds
	MOV	DS,ResSeg
	ASSUME	DS:ResGroup
	CMP	[SINGLECOM],0
	JZ	TestDone
	CMP	[SINGLECOM],0EFFFH
TestDone:
	pop	ds
	return


ASSUME	DS:TRANGROUP
SETREST1:
	MOV	AL,1
SETREST:
	PUSH	DS
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	[RESTDIR],AL
	POP	DS
ASSUME	DS:TRANGROUP
	return

ASSUME	DS:RESGROUP

;
; Note that we need to handle the same thing that RestDir handles:  the
; requirement that we try only once to restore the user's environment after
; and INT 24 or the like.  If the condition that causes the INT 24 does not
; disappear, we just give up.
;

PIPEDEL:
	assume	ds:nothing
	push	ds
	PUSH	DX
	mov	ds,ResSeg
	assume	ds:ResGroup
	mov	DX,OFFSET RESGROUP:PIPE1	; Clean up in case ^C
	MOV	AH,UNLINK
	INT	int_command
	MOV	DX,OFFSET RESGROUP:PIPE2
	MOV	AH,UNLINK
	INT	int_command
	POP	DX
	call	PipeOff
	mov	PipeFiles,0
	pop	ds
	return

PIPEERRSYN:
	MOV	DX,OFFSET TRANGROUP:SYNTMES_ptr
	CALL	PIPEDEL
	PUSH	CS
	POP	DS
	JMP	CERROR
PIPEERR:
	pushf
	invoke	triageError
	SaveReg    <AX,DX>			; Save results from TriageError
	MOV	DX,OFFSET TRANGROUP:PIPEEMES_ptr
	CALL	PIPEDEL
	PUSH	CS
	POP	DS
	invoke	std_eprintf
	RestoreReg <DX,AX>			; Restore results from TriageError
	popf
	cmp	ax, 65
	jnz	tcommandj
	JMP	CERROR
tcommandj:
	jmp	tcommand

PIPEPROCSTRT:
ASSUME	DS:TRANGROUP,ES:TRANGROUP
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	INC	[PIPEFILES]			; Flag that the pipe files exist
	MOV	AH,Get_Default_Drive		; Get current drive
	INT	int_command
	ADD	AL,capital_A
	MOV	[PIPE2],AL			; Make pipe files in root of def drv
	MOV	BX,OFFSET RESGROUP:PIPE1
	MOV	[BX],AL
	xor	ah,ah				; nul terminate path names
	mov	[Pipe1T],ah
	mov	[Pipe2T],ah
	MOV	DX,BX
	XOR	CX,CX
	mov	ah,CreateTempFile		; the CreateTemp call
	INT	int_command
	JC	PIPEERR 			; Couldn't create
	MOV	BX,AX
	MOV	AH,CLOSE			; Don't proliferate handles
	INT	int_command

	MOV	DX,OFFSET RESGROUP:PIPE2
	mov	ah,createTempFile		; the CreateTemp call
	INT	int_command
	JC	PIPEERR
	MOV	BX,AX
	MOV	AH,CLOSE
	INT	int_command

	CALL	TESTDOREIN			; Set up a redirection if specified
	MOV	SI,[PIPEPTR]
	CMP	[SINGLECOM],-1
	JNZ	NOSINGP
	MOV	[SINGLECOM],0F000H		; Flag single command pipe
NOSINGP:
	JMP	SHORT FIRSTPIPE

PIPEPROC:
ASSUME	DS:RESGROUP
	AND	[ECHOFLAG],0FEh 		; force current echo to be off
	MOV	SI,[PIPEPTR]
	LODSB
	CMP	AL,AltPipeChr			; Alternate pipe char?
	JZ	IsPipe1 			; Yes
	CMP	AL,vbar
	jz	IsPipe1
	jmp	PIPEEND 			; Pipe done
IsPipe1:
	MOV	DX,[INPIPEPTR]			; Get the input file name
	MOV	AX,(OPEN SHL 8)
	INT	int_command
PIPEERRJ:
	jnc	no_pipeerr
	JMP	PIPEERR 			; Lost the pipe file
no_pipeerr:
	MOV	BX,AX
	MOV	AL,0FFH
	XCHG	AL,[BX.PDB_JFN_Table]
	MOV	DS:[PDB_JFN_Table],AL		; Redirect

FIRSTPIPE:
	MOV	DI,OFFSET TRANGROUP:COMBUF + 2
	XOR	CX,CX
	CMP	BYTE PTR [SI],0DH		; '|<CR>'
	JNZ	PIPEOK1
PIPEERRSYNJ:
	JMP	PIPEERRSYN
PIPEOK1:
	mov	al,vbar
	CMP	BYTE PTR [SI],al		; '||'
	JZ	PIPEERRSYNJ
	CMP	BYTE PTR [SI],AltPipeChr	; '##' or '|#'?
	JZ	PipeErrSynJ			; Yes, Error
PIPECOMLP:
	LODSB
	STOSB

;;;;	IF	KANJI		3/3/KK
	CALL	TESTKANJ
	JZ	NOTKANJ5
	MOVSB
;
;  Added following 2 commands to the fix pipe bug.
;
	inc	cx				;AN000;  3/3/KK
	inc	cx				;AN000;  3/3/KK
;
	JMP	PIPECOMLP

NOTKANJ5:
;;;;	ENDIF			; 3/3/KK

	CMP	AL,0DH
	JZ	LASTPIPE
	INC	CX
	CMP	AL,AltPipeChr
	JZ	IsPipe2
	CMP	AL,vbar
	JNZ	PIPECOMLP
IsPipe2:
	MOV	BYTE PTR ES:[DI-1],0DH
	DEC	CX
	MOV	[COMBUF+1],CL
	DEC	SI
	MOV	[PIPEPTR],SI			; On to next pipe element
	MOV	DX,[OUTPIPEPTR]
	PUSH	CX
	XOR	CX,CX
	MOV	AX,(CREAT SHL 8)
	INT	int_command
	POP	CX
	JC	PIPEERRJ			; Lost the file
	MOV	BX,AX
	MOV	AL,0FFH
	XCHG	AL,[BX.PDB_JFN_Table]
	MOV	DS:[PDB_JFN_Table+1],AL
	XCHG	DX,[INPIPEPTR]			; Swap for next element of pipe
	MOV	[OUTPIPEPTR],DX
	JMP	SHORT PIPECOM

LASTPIPE:
	MOV	[COMBUF+1],CL
	DEC	SI
	MOV	[PIPEPTR],SI			; Point at the CR (anything not '|' will do)
	CALL	TESTDOREOUT			; Set up the redirection if specified
PIPECOM:
	PUSH	CS
	POP	DS
	JMP	NOPIPEPROC			; Process the pipe element

PIPEEND:
	CALL	PIPEDEL
	CMP	[SINGLECOM],0F000H
	JNZ	NOSINGP2
	MOV	[SINGLECOM],-1			; Make it return
NOSINGP2:
	JMP	TCOMMAND

ASSUME	DS:TRANGROUP,ES:TRANGROUP

; Date and time are set during initialization and use
; this routines since they need to do a long return

DATINIT PROC	FAR
	mov	cs:[resseg],ds			; SetInitFlag needs resseg initialized
	PUSH	ES
	PUSH	DS				; Going to use the previous stack
	MOV	AX,CS				; Set up the appropriate segment registers
	MOV	ES,AX
	MOV	DS,AX
	invoke	TSYSLOADMSG			;AN000; preload messages
	invoke	SETSTDINON			;AN026; turn on critical error on STDIN
	invoke	SETSTDOUTOFF			;AN026; turn off critical error on STDOUT
	MOV	DX,OFFSET TRANGROUP:INTERNATVARS;Set up internat vars
	MOV	AX,INTERNATIONAL SHL 8
	INT	21H
	MOV	WORD PTR DS:[81H],13		; Want to prompt for date during initialization
	MOV	[COMBUF],COMBUFLEN		; Init COMBUF
	MOV	WORD PTR [COMBUF+1],0D01H
	CALL	DATE
	CALL	CTIME
	POP	DS
	POP	ES
	RET
DATINIT ENDP

; DATE - Gets and sets the time


	break	Date


; ****************************************************************
; *
; * ROUTINE:	 DATE - Set system date
; *
; * FUNCTION:	 If a date is specified, set the system date,
; *		 otherwise display the current system date and
; *		 prompt the user for a new date.  If an invalid
; *		 date is specified, issue an error message and
; *		 prompt for a new date.  If the user enters
; *		 nothing when prompted for a date, terminate.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

assume	ds:trangroup,es:trangroup

DATE:
	MOV	SI,81H				; Accepting argument for date inline
	mov	di,offset trangroup:parse_date	;AN000; Get adderss of PARSE_DATE
	xor	cx,cx				;AN000; clear counter for positionals
	xor	dx,dx				;AN000;
	invoke	cmd_parse			;AC000; call parser
	cmp	ax,end_of_line			;AC000; are we at end of line?
	JZ	PRMTDAT 			;AC000; yes - go ask for date
	cmp	ax,result_no_error		;AN000; did we have an error?
	jne	daterr				;AN000; yes - go issue message
	JMP	COMDAT				;AC000; we have a date

PRMTDAT:
	; Print "Current date is

	invoke	GetDate 			;AN000; get date  for output
	xchg	dh,dl				;AN000; switch month & day
	mov	CurDat_yr,cx			;AC000; put year into message control block
	mov	CurDat_mo_day,dx		;AC000; put month and day into message control block
	mov	dx,offset trangroup:CurDat_ptr	;AC000; set up message for output
	invoke	std_printf
;AD061; mov	CurDat_yr,0			;AC000; reset year, month and day
;AD061; mov	CurDat_mo_day,0 		;AC000;     pointers in control block

GET_NEW_DATE:					;AN000;
	call	getdat				;AC000; prompt user for date
	cmp	ax,end_of_line			;AC000; are we at end of line?
	jz	date_end			;AC000; yes - exit
	cmp	ax,result_no_error		;AN000; did we have an error?
	jne	daterr				;AN000; yes - go issue message
COMDAT:
	mov	cx,date_year			;AC000; get parts of date in
	mov	dh,date_month			;AC000;    cx and dx for set
	mov	dl,date_day			;AC000;    date function call.
	push	cx				;AC000; save date
	push	dx				;AC000;
	mov	cx,1				;AC000; set 1 positional entered
	xor	dx,dx				;AN029;
	invoke	cmd_parse			;AN029; call parser
	cmp	al,end_of_line			;AN029; Are we at end of line?
	pop	dx				;AC000; retrieve date
	pop	cx				;AC000;
	jnz	daterr				;AC000; extra stuff on line - try again
	MOV	AH,SET_DATE			;yes - set date
	INT	int_command
	OR	AL,AL
	JNZ	DATERR
date_end:
	ret

DATERR:
	invoke	crlf2				;AN028; print out a blank line
	MOV	DX,OFFSET TRANGROUP:BADDAT_ptr
	invoke	std_printf
	JMP	GET_NEW_DATE			;AC000; get date again


; TIME gets and sets the time

	break	Time

; ****************************************************************
; *
; * ROUTINE:	 TIME - Set system time
; *
; * FUNCTION:	 If a time is specified, set the system time,
; *		 otherwise display the current system time and
; *		 prompt the user for a new time.  If an invalid
; *		 time is specified, issue an error message and
; *		 prompt for a new time.  If the user enters
; *		 nothing when prompted for a time, terminate.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

assume	ds:trangroup,es:trangroup

CTIME:
	MOV	SI,81H				; Accepting argument for time inline
	mov	di,offset trangroup:parse_time	;AN000; Get adderss of PARSE_time
	xor	cx,cx				;AN000; clear counter for positionals
	xor	dx,dx				;AN000;
	invoke	cmd_parse			;AC000; call parser
	cmp	ax,end_of_line			;AC000; are we at end of line?
	JZ	PRMTTIM 			;AC000; yes - prompt for time
	cmp	ax,result_no_error		;AN000; did we have an error?
	jne	timerr				;AN000; yes - go issue message
	JMP	COMTIM				;AC000; we have a time

PRMTTIM:
	;Printf "Current time is ... "

	MOV	AH,GET_TIME			;AC000; get the current time
	INT	int_command			;AC000;    Get time in CX:DX
	xchg	ch,cl				;AN000; switch hours & minutes
	xchg	dh,dl				;AN000; switch seconds & hundredths
	mov	CurTim_hr_min,cx		;AC000; put hours and minutes into message subst block
	mov	CurTim_sec_hn,dx		;AC000; put seconds and hundredths into message subst block
	mov	dx,offset trangroup:CurTim_ptr	;AC000; set up message for output
	invoke	std_printf
;AD061; mov	CurTim_hr_min,0 		;AC000; reset hour, minutes, seconds, and hundredths
;AD061; mov	CurTim_sec_hn,0 		;AC000;     pointers in control block

GET_NEW_TIME:
	call	gettim				;AC000;
	cmp	ax,end_of_line			;AC000; are we at end of line?
	jz	time_end			;AC000;
	cmp	ax,result_no_error		;AN000; did we have an error?
	jne	timerr				;AN000; yes - go issue message

COMTIM:
	mov	ch,time_hour			;AC000; get parts of time in
	mov	cl,time_minutes 		;AC000;    cx and dx for set
	mov	dh,time_seconds 		;AC000;    time function call
	mov	dl,time_fraction		;AC000;
	push	cx				;AC000; save time
	push	dx				;AC000;
	mov	cx,1				;AC000; set 1 positional parm entered
	xor	dx,dx				;AN029;
	invoke	cmd_parse			;AN029; call parser
	cmp	al,end_of_line			;AN029; Are we at end of line?
	pop	dx				;AC000; retieve time
	pop	cx				;AC000;
	jnz	timerr				;AC000; extra stuff on line - try again

SAVTIM:
	MOV	AH,SET_TIME
	INT	int_command
	OR	AL,AL
	JNZ	TIMERR				;AC000; if an error occured, try again

TIME_END:

	ret

TIMERR:
	invoke	crlf2				;AN028; print out a blank line
	MOV	DX,OFFSET TRANGROUP:BADTIM_ptr
	invoke	std_printf			; Print error message
	JMP	GET_NEW_TIME			;AC000; Try again


;
; Set the special flag in the INIT flag to the value in CX.
;
SetInitFlag:
	mov	ds,[RESSEG]
assume ds:resgroup
	and	InitFlag,NOT initSpecial
	or	InitFlag,cL
	push	cs
	pop	ds
	return

Public	PipeOff
PipeOff:
	ASSUME	DS:NOTHING,ES:NOTHING
	SaveReg <DS,AX>
	MOV	DS,ResSeg
	ASSUME	DS:RESGroup
	XOR	AL,AL
	XCHG	PipeFlag,AL
	OR	AL,AL
	JZ	PipeOffDone
	SHR	EchoFlag,1
PipeOffDone:
	RestoreReg  <AX,DS>
	return


PRINT_TIME:

	MOV	AH,GET_TIME
	INT	int_command			; Get time in CX:DX

	PUSH	ES
	PUSH	CS
	POP	ES
	xchg	ch,cl				;AN000; switch hours & minutes
	xchg	dh,dl				;AN000; switch seconds & hundredths
	mov	promTim_hr_min,cx		;AC000; put hours and minutes into message subst block
	mov	promTim_sec_hn,dx		;AC000; put seconds and hundredths into message subst block
	mov	dx,offset trangroup:promTim_ptr ;AC000; set up message for output
	invoke	std_printf
;AD061; mov	promTim_hr_min,0		;AC000; reset hour, minutes, seconds, and hundredths
;AD061; mov	promTim_sec_hn,0		;AC000;     pointers in control block

	POP	ES
	return


; ****************************************************************
; *
; * ROUTINE:	 GETDAT - Prompt user for date
; *
; * FUNCTION:	 Gets the date format from the COUNTRY DEPENDENT
; *		 INFORMATION and issues the "Enter new date"
; *		 message with the proper date format.  COMBUF
; *		 is reset to get a date from the command line.
; *		 The PARSE_DATE blocks are then reset and the
; *		 PARSE function call is issued.
; *
; * INPUT:	 NONE
; *
; * OUTPUT:	 COMBUF
; *		 PARSER RETURN CODES
; *
; ****************************************************************


GETDAT	proc	near				;AC000;

	mov	ax,(International SHL 8)	; Determine what format the date
	mov	dx,5ch				;  should be entered in and
	int	int_command			;  print a message describing it
	mov	si,dx
	lodsw
	mov	dx,usadat_ptr			;AC000; get mm-dd-yy
	dec	ax
	js	printformat
	mov	dx,eurdat_ptr			;AC000; get dd-mm-yy
	jz	printformat
	mov	dx,japdat_ptr			;AC000; get yy-mm-dd
printformat:
	mov	ax,dx				;AN000; get message number of format
	mov	dh,util_msg_class		;AN000; this is a utility message
	call	Tsysgetmsg			;AN000; get the address of the message
	mov	newdat_format,si		;AN000; put the address in subst block
	MOV	DX,OFFSET TRANGROUP:NEWDAT_ptr	;AC000; get address of message to print
	invoke	std_printf
	mov	newdat_format,no_subst		;AN000; reset subst block

	MOV	AH,STD_CON_STRING_INPUT
	MOV	DX,OFFSET TRANGROUP:COMBUF
	mov	cx,initSpecial			; Set bit in InitFlag that indicates
	call	SetInitFlag			;  prompting for date.
	INT	int_command			; Get input line
	xor	cx,cx				; Reset bit in InitFlag that indicates
	call	SetInitFlag			;  prompting for date.
	invoke	CRLF2
	MOV	SI,OFFSET TRANGROUP:COMBUF+2
	mov	di,offset trangroup:parse_date	;AN000; Get adderss of PARSE_DATE
	xor	cx,cx				;AN000; clear counter for positionals
	xor	dx,dx				;AN000;
	invoke	cmd_parse			;AC000; call parser

	ret

GETDAT	endp					;AC000;


; ****************************************************************
; *
; * ROUTINE:	 GETTIME - Prompt user for time
; *
; * FUNCTION:	 Gets the time format from the COUNTRY DEPENDENT
; *		 INFORMATION and issues the "Enter new time"
; *		 message. COMBUF is reset to get a time from the
; *		 command line.	The PARSE_TIME blocks are then
; *		 reset and the PARSE function call is issued.
; *
; * INPUT:	 NONE
; *
; * OUTPUT:	 COMBUF
; *		 PARSER RETURN CODES
; *
; ****************************************************************


GETTIM	proc	near				;AC000;

	XOR	CX,CX				; Initialize hours and minutes to zero
	MOV	DX,OFFSET TRANGROUP:NEWTIM_ptr
	invoke	std_printf
	MOV	AH,STD_CON_STRING_INPUT
	MOV	DX,OFFSET TRANGROUP:COMBUF
	mov	cx,initSpecial			; Set bit in InitFlag that indicates
	call	SetInitFlag			;  prompting for time.
	INT	int_command			; Get input line
	xor	cx,cx				; Reset bit in InitFlag that indicates
	call	SetInitFlag			;  prompting for time.
	invoke	CRLF2
	MOV	SI,OFFSET TRANGROUP:COMBUF+2
	mov	di,offset trangroup:parse_time	;AN000; Get adderss of PARSE_TIME
	xor	cx,cx				;AN000; clear counter for positionals
	xor	dx,dx				;AN000;
	invoke	cmd_parse			;AC000; call parser

	ret

GETTIM	endp					;AC000;

TRANCODE    ENDS
	    END
