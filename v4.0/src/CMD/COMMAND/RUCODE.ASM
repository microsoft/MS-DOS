 page 80,132
;	SCCSID = @(#)rucode.asm 4.5 85/07/22
;	SCCSID = @(#)rucode.asm 4.5 85/07/22
TITLE	COMMAND Language modifiable Code Resident


.xlist
.xcref
INCLUDE DOSSYM.INC			;AC000;
include doscntry.inc			;AC000;
DEBUG = 0				; NEED TO SET IT TO WHAT IT IS IN DOSSYM.INC


	INCLUDE DEVSYM.INC
	INCLUDE comsw.asm
	INCLUDE comseg.asm
	INCLUDE comequ.asm
	include resmsg.equ		;AN000;
.list
.cref


Tokenized   =	FALSE

DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	abort_char:byte
	EXTRN	badfat_block:byte	;AC000;
	EXTRN	badfat_subst:byte	;AC000;
	EXTRN	Batch_Abort:byte
	EXTRN	CDEVAT:BYTE
	EXTRN	COMSPEC:BYTE		;AN060;
	EXTRN	com_xlat_addr:word
	EXTRN	crit_err_info:byte
	EXTRN	crit_msg_off:word	;AC000;
	EXTRN	crit_msg_seg:word	;AC000;
	EXTRN	dbcs_vector_addr:dword	;AN000;
	EXTRN	devemes_block:byte	;AC000;
	EXTRN	devemes_subst:byte	;AC000;
	EXTRN	DEVENAM:BYTE
	EXTRN	deve_op_off:word	;AC000;
	EXTRN	disp_class:byte 	;AC000;
	EXTRN	DRVLET:BYTE
	EXTRN	drvnum_block:byte	;AC000;
	EXTRN	drvnum_op_off:word	;AC000;
	EXTRN	drvnum_subst:byte	;AC000;
	EXTRN	err15mes_block:byte	;AC000;
	EXTRN	err15mes_subst:byte	;AC000;
	EXTRN	ERRCD_24:WORD
	EXTRN	ErrType:BYTE
	EXTRN	fail_char:byte
	EXTRN	fFail:BYTE
	EXTRN	FORFLAG:BYTE
	EXTRN	ignore_char:byte
	EXTRN	InitFlag:BYTE
	EXTRN	In_Batch:byte
	EXTRN	LOADING:BYTE
;AD054; EXTRN	MESBAS:BYTE
	EXTRN	no_char:byte
	EXTRN	number_subst:byte	;AC000;
	EXTRN	olderrno:word
	EXTRN	PARENT:WORD
;AD060; EXTRN	pars_msg_off:word	;AC000;
;AD060; EXTRN	pars_msg_seg:word	;AC000;
	EXTRN	PERMCOM:BYTE
	EXTRN	RemMsg:DWORD
	EXTRN	retry_char:byte
	EXTRN	PIPEFLAG:BYTE
	EXTRN	SINGLECOM:WORD
	EXTRN	VolName:BYTE
	EXTRN	yes_char:byte

	IF	Tokenized
	EXTRN	IOTYP:BYTE
	EXTRN	MESADD:BYTE
	ENDIF

DATARES ENDS


CODERES SEGMENT PUBLIC BYTE

	EXTRN	GETCOMDSK2:NEAR

	PUBLIC	ASKEND
	PUBLIC	CRLF
	PUBLIC	DSKERR
	PUBLIC	ITESTKANJ		;AN000;
	PUBLIC	RESET_MSG_POINTERS	;AC000;
	PUBLIC	RPRINT

ASSUME	CS:RESGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;
; AskEnd - prompt the user to see if he should terminate the batch file.  If
; any system call returns with carry set or if RPRINT returns with carry set,
; we jump to the top and start over.
;
;    Returns:	carry set if response indicates that the batch file should
;		    be terminated.
;		carry clear otherwise.
;

ASSUME	DS:RESGROUP
ASKEND:
	MOV	DX,ENDBATMES			;AC000; get batch terminate question
	CALL	RPRINT
	MOV	AX,(STD_CON_INPUT_FLUSH SHL 8)+STD_CON_INPUT
	INT	21H
	call	in_char_xlat			;g change to upper case
	CMP	AL,no_char
	retz					; carry is clear => no free
	CMP	AL,yes_char
	JNZ	ASKEND
	stc					; carry set => free batch
	return

DSKERR:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	; ******************************************************
	;	THIS IS THE DEFAULT DISK ERROR HANDLING CODE
	;	AVAILABLE TO ALL USERS IF THEY DO NOT TRY TO
	;	INTERCEPT INTERRUPT 24H.
	; ******************************************************
	STI
	PUSH	DS
	PUSH	ES
	PUSH	SI				;AN000; save si
	PUSH	CX
	PUSH	DI
	PUSH	CX
	PUSH	AX
	MOV	DS,BP
	MOV	AX,[SI.SDEVATT]
	MOV	[CDEVAT],AH
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET RESGROUP:DEVENAM
	MOV	CX,8
	ADD	SI,SDEVNAME			; Suck up device name (even on Block)
	REP	MOVSB
	POP	AX
	POP	CX
	POP	DI				; Stack just contains DS and ES
						;     at this point
	INVOKE	SAVHAND
	PUSH	CS
	POP	DS				; Set up local data segment
ASSUME	DS:RESGROUP

	PUSH	DX
	CALL	CRLF
	POP	DX
	MOV	CRIT_ERR_INFO,AH		;G save so we know if R,I,F are valid

	ADD	AL,'A'                          ; Compute drive letter (even on character)
	MOV	[DRVLET],AL
	TEST	AH,80H				; Check if hard disk error
	JZ	NOHARDE
	TEST	[CDEVAT],DEVTYP SHR 8
	JNZ	NOHARDE
	JMP	FATERR

NOHARDE:
	MOV	SI,MREAD			;AC000;
	TEST	AH,1
	JZ	SAVMES
	MOV	SI,MWRITE			;AC000;

SAVMES:
	IF	Tokenized
	LODSW
	MOV	WORD PTR [IOTYP],AX
	LODSW
	MOV	WORD PTR [IOTYP+2],AX
	ENDIF

	mov	olderrno,di			; keep code in a safe place
	PUSH	ES				;AN000;
	PUSH	DS				; GetExtendedError likes to STOMP
	PUSH	BP
	PUSH	SI
	PUSH	DX
	PUSH	CX
	PUSH	BX
	mov	ah,GetExtendedError		; get extended error code
	INT	21H
	POP	BX
	POP	CX
	POP	DX
	POP	SI
	POP	BP
	POP	DS
	mov	word ptr cs:[RemMsg],di 	;AC000; save pointer to remote message
	mov	word ptr cs:[RemMsg+2],es	;AC000;    (only used on code 15)
	pop	ES				;AN000;
	XOR	AH,AH
	mov	di,ax				; REAL error code to DI
;
; DI is now the correct error code.  Classify things to see what we are
; allowed to report.  We convert DI into a 0-based index into a message table.
; This presumes that the int 24 errors (oldstyle) and new errors (sharing and
; the like) are contiguous.
;
	SUB	DI,error_write_protect
	JAE	HavCod
	MOV	DI,error_Gen_failure-error_write_protect
;
; DI now has the mapped error code.  Old style errors are:
;   FOOBAR <read|writ>ing drive ZZ.
; New style errors are:
;   FOOBAR
; We need to figure out which the particular error belongs to.
;

HAVCOD:
	mov	ErrType,0			; assume Old style
	cmp	di,error_FCB_Unavailable-error_write_protect
	jz	SetStyle
	cmp	di,error_sharing_buffer_exceeded-error_write_protect
	jnz	GotStyle

SetStyle:
	mov	ErrType,1			; must be new type

GotStyle:
	MOV	[ERRCD_24],DI
	cmp	di,error_handle_disk_full-error_write_protect  ;AC026;
						; If the error message is unknown
	jbe	NormalError			;  redirector, continue.  Otherwise,
;
; We do not know how to handle this error.  Ask IFSFUNC if she knows
; how to handle things
;

;input to IFSFUNC:    AL=1
;		      BX=extended error number

;output from IFSFUNC: AL=error type (0 or 1)
;			 0=<message> error (read/writ)ing (drive/device) xxx
;			   Abort, Retry, Ignore
;			 1=<message>
;			   Abort, Retry, Ignore
;		      ES:DI=pointer to message text
;		      carry set=>no message

	MOV	DI,AX				; retrieve correct extended error...
	mov	ax,0500h			; Is the redir there?
	int	2fh
	cmp	al,0ffh
	jnz	NoHandler			; No, go to NoHandler
	push	bx								   ;AN063;
	mov	bx,di				; Get ErrType and ptr to error msg ;AC063;
	mov	ax,0501h							   ;AC063;
	int	2fh
	pop	bx								   ;AC063;
	jc	NoHandler

	mov	ErrType,al
	push	ds
	push	es
	pop	ds
	mov	dx,di
	mov	cx,-1				; Find the end of the error msg and turn
	xor	al,al				;  the high byte on for rprint
	repnz	scasb

	IF	Tokenized
	or	byte ptr [di-2],80h
	call	rprint				; Print the message
	and	byte ptr [di-2], NOT 80h	; Restore msg to original condition
	ELSE
	mov	byte ptr [di-1],'$'
	MOV	AH,Std_con_string_output	;AC000; Print the message
	INT	21h				;AN000;
	mov	byte ptr [di-1],0		; Restore msg to original condition
	ENDIF

	pop	ds				; Clean up and continue processing
	jmp	short CheckErrType

NoHandler:					; Redir isn't available or doesn't
	mov	ErrType,0			;  recognize the error.  Reset vars and
	mov	di,olderrno			;  regs to unextended err and continue
	mov	ERRCD_24,di			;  normally.

NormalError:
;AD054; SHL	DI,1
;AD054; MOV	DI,WORD PTR [DI+MESBAS] 	; Get pointer to error message
	add	DI,error_write_protect		;AN054;
	XCHG	DI,DX				; May need DX later
	MOV	DISP_CLASS,EXT_CRLF_CLASS	;AN054; printing extended error class
	CALL	RPRINT				; Print error type

CheckErrType:
	cmp	ErrType,0			; Check error style...
	je	ContOld
	call	CRLF				; if new style then done printing
	jmp	short ASK

ContOld:
	IF	NOT Tokenized
	MOV	AX,SI				;AN000; get reading/writing for message
	MOV	DH,UTIL_MSG_CLASS		;AN000; this is a utility message
	CALL	SYSGETMSG			;AN000; get the message
	ENDIF

	TEST	[CDEVAT],DEVTYP SHR 8
	JZ	BLKERR
	MOV	DX,DEVEMES			;AC000; get message number for device message
	MOV	DEVE_OP_OFF,SI			;AN000; put address of read/write in subst block
	MOV	AL,DEVEMES_SUBST		;AN000; get number of substitutions
	MOV	NUMBER_SUBST,AL 		;AN000;
	MOV	SI,OFFSET RESGROUP:DEVEMES_BLOCK;AN000; get address of subst block

	CALL	RPRINT				;AC000; print the message
	JMP	SHORT ASK			; Don't ralph on COMMAND

BLKERR:
	MOV	DX,DRVNUM			;AN000; get drive message number
	MOV	DRVNUM_OP_OFF,SI		;AN000; put address of read/write in subst block
	MOV	AL,DRVNUM_SUBST 		;AN000; get number of substitutions
	MOV	NUMBER_SUBST,AL 		;AN000;
	MOV	SI,OFFSET RESGROUP:DRVNUM_BLOCK ;AN000; get address of subst block
	CALL	RPRINT
	CMP	[LOADING],0
	JZ	ASK
	INVOKE	RESTHAND
	JMP	GETCOMDSK2			; If error loading COMMAND, re-prompt

ASK:
	cmp	[ERRCD_24],15			; Wait! Error 15 has an extra message
	jne	Not15
	PUSH	CX
	push	ds
	pop	es
	lds	si,[RemMsg]
assume	ds:nothing
	push	di
	mov	di,offset resgroup:VolName
	mov	cx,16				;AC000; extra message volume name & serial number
	cld					; just in case!
	rep	movsb
	pop	di
	push	es
	pop	ds
	POP	CX
assume	ds:resgroup
	mov	dx,Err15Mes			;AC000; get message number
	MOV	AL,ERR15MES_SUBST		;AN000; get number of substitutions
	MOV	NUMBER_SUBST,AL 		;AN000;
	MOV	SI,OFFSET RESGROUP:ERR15MES_BLOCK ;AN000; get address of subst block
	CALL	RPRINT

; PRINT OUT ABORT, RETRY, IGNORE, FAIL MESSAGE.  ONLY PRINT OUT OPTIONS
; THAT ARE VALID

Not15:
	MOV	DX,REQ_ABORT			;AC000;G print out abort message
	CALL	RPRINT				;G
	TEST	CRIT_ERR_INFO,RETRY_ALLOWED	;G is retry allowed?
	JZ	TRY_IGNORE			;G
	MOV	DX,REQ_RETRY			;AC000;G yes,print out retry message
	CALL	RPRINT				;G

try_ignore:
	TEST	CRIT_ERR_INFO,IGNORE_ALLOWED	;G is ignore allowed?
	JZ	TRY_FAIL			;G
	MOV	DX,REQ_IGNORE			;AC000;G yes,print out ignore message
	CALL	RPRINT				;G

try_fail:
	TEST	CRIT_ERR_INFO,FAIL_ALLOWED	;G is FAIL allowed?
	JZ	TERM_QUESTION			;G
	MOV	DX,REQ_FAIL			;AC000;G yes,print out FAIL message
	CALL	RPRINT				;G

Term_Question:
	MOV	DX,REQ_END			;AC000;G terminate the string
	CALL	RPRINT				;G
;
; If the /f switch was given, we fail all requests...
;
	TEST	fFail,-1
	JZ	DoPrompt
	MOV	AH,3				; signal fail
	JMP	EExit

DoPrompt:
	MOV	AX,(STD_CON_INPUT_FLUSH SHL 8)+STD_CON_INPUT
	INT	21H				; Get response

	invoke	TestKanjR			;AN000;  3/3/KK
	jz	notkanj 			;AN000;  3/3/KK
	MOV	AX,(STD_CON_INPUT SHL 8)	;AN000;  eat the 2nd byte of ECS code  3/3/KK
	INT	21H				;AN000;  3/3/KK
	CALL	CRLF				;AN000;  3/3/KK
	JMP	ASK				;AN000;  3/3/KK

notkanj:					;AN000;  3/3/KK
	CALL	CRLF
	CALL	IN_CHAR_XLAT			;G Convert to upper case
	MOV	AH,0				; Return code for ignore
	TEST	CRIT_ERR_INFO,IGNORE_ALLOWED	;G is IGNORE allowed?
	JZ	USER_RETRY			;G
	CMP	AL,ignore_char			; Ignore?
	JZ	EEXITJ

USER_RETRY:
	INC	AH				; return code for retry
	TEST	CRIT_ERR_INFO,RETRY_ALLOWED	;G is RETRY allowed?
	JZ	USER_ABORT			;G
	CMP	AL,retry_char			; Retry?
	JZ	EEXITJ

USER_ABORT:
	INC	AH				; return code for abort - always allowed
	CMP	AL,abort_char			; Abort?
	JZ	abort_process			;G  exit user program
	INC	AH				;G  return code for fail
	TEST	CRIT_ERR_INFO,FAIL_ALLOWED	;G is FAIL allowed?
	JZ	ASKJ				;G
	CMP	AL,fail_char			;G fail?
	JZ	EEXITJ				;G

ASKJ:
	JMP	ASK				;G

EEXITJ:
	JMP SHORT EEXIT 			;G

abort_process:
	test	InitFlag,initINIT		; Was command initialization interrupted
	jz	AbortCont			; No, handle it normally
	cmp	PERMCOM,0			; Is this the top level process?
	jz	JustExit			; Yes, just exit
	mov	dx,Patricide			;AC000; No, load ptr to error msg
	call	RPRINT				; Print it

DeadInTheWater:
	jmp	DeadInTheWater			; Loop until the user reboots

JustExit:
ASSUME	DS:RESGROUP
	call	reset_msg_pointers		;AN000; reset critical & parse message addresses
	mov	ax,[PARENT]			; Load real parent PID
	mov	word ptr ds:[PDB_Parent_PID],ax ; Put it back where it belongs
	mov	ax,(Exit SHL 8) OR 255
	int	21H

AbortCont:
	test	byte ptr [In_Batch],-1		; Are we accessing a batch file?
	jz	Not_Batch_Abort
	mov	byte ptr [Batch_Abort],1	; set flag for abort

Not_Batch_Abort:
	mov	dl,PipeFlag
	invoke	ResPipeOff
	OR	DL,DL
	JZ	CHECKFORA
	CMP	[SINGLECOM],0
	JZ	CHECKFORA
	MOV	[SINGLECOM],-1			; Make sure SINGLECOM exits

CHECKFORA:
	CMP	[ERRCD_24],0			; Write protect
	JZ	ABORTFOR
	CMP	[ERRCD_24],2			; Drive not ready
	JNZ	EEXIT				; Don't abort the FOR

ABORTFOR:
	MOV	[FORFLAG],0			; Abort a FOR in progress
	CMP	[SINGLECOM],0
	JZ	EEXIT
	MOV	[SINGLECOM],-1			; Make sure SINGLECOM exits

EEXIT:
	MOV	AL,AH
	MOV	DX,DI

RESTHD:
	INVOKE	RESTHAND
	POP	CX
	POP	SI				;AN000; restore registers
	POP	ES
	POP	DS
	IRET

FATERR:
	MOV	DX,BADFAT			;AC000;
	MOV	AL,BADFAT_SUBST 		;AN000; get number of substitutions
	MOV	NUMBER_SUBST,AL 		;AN000;
	MOV	SI,OFFSET RESGROUP:BADFAT_BLOCK ;AN000; get address of subst block
	CALL	RPRINT

	IF	Tokenized
	MOV	DX,OFFSET RESGROUP:ERRMES
	CALL	RPRINT
	ENDIF

	MOV	AL,2				; Abort
	JMP	RESTHD

;*********************************************
; Print routines for Tokenized resident messages

ASSUME DS:RESGROUP,SS:RESGROUP

CRLF:
	MOV	DX,NEWLIN			;AC000;

;
; RPRINT prints out a message on the user's console.  We clear carry before
; each system call.  We do this so that the ^C checker may change things so
; that carry is set.  If we detect a system call that returns with carry set,
; we merely return.
;
;   Inputs:	DX has the message number as an offset from DS.
;   Outputs:	Carry clear: no carries detected in the system calls
;		Carry set: at least one system call returned with carry set
;   Registers modified: none
;

RPRINT:

;
; If we are not tokenized, the message consists of a $-terminated string.
; Use CPM io to output it.
;

if NOT tokenized
	PUSH	AX
	PUSH	BX				;AC000; save BX register
	PUSH	CX				;AC000; save CX register
	PUSH	DX				;AC000; save DX register
	MOV	AX,DX				;AC000; get message number
	MOV	DH,DISP_CLASS			;AC000; get display class
	MOV	DL,NO_CONT_FLAG 		;AN000; set control flags off
	MOV	BX,NO_HANDLE_OUT		;AC000; set message handler to use function 1-12
	XOR	CH,CH				;AC000; clear upper part of cx
	MOV	CL,NUMBER_SUBST 		;AC000; set number of substitutions
	CALL	SYSDISPMSG			;AC000; display the message
	MOV	DISP_CLASS,UTIL_MSG_CLASS	;AC000; reset display class
	MOV	NUMBER_SUBST,NO_SUBST		;AC000; reset number of substitutions
	POP	DX				;AC000; restore registers
	POP	CX				;AC000;
	POP	BX				;AC000;
	POP	AX

	return
endif

;
; If we are tokenized, output character-by-character.  If there is a digit in
; the output, look up that substring in the tokenization table.  Use the high
; bit to determine the end-of-string.
;

If Tokenized
	SaveReg <AX,DX,SI>
	MOV	SI,DX

RPRINT1:
	LODSB
	PUSH	AX				; save for EOS testing
	AND	AL,7FH
	CMP	AL,'0'
	JB	RPRINT2
	CMP	AL,'9'
	JA	RPRINT2
	SUB	AL,'0'
	CBW					; DS must be RESGROUP if we get here
	SHL	AX,1				; clear carry
	XCHG	SI,AX
	MOV	DX,[SI + OFFSET RESGroup:MesADD]
	CALL	RPrint
	XCHG	SI,AX
	JMP	SHORT RPRINT3

RPRINT2:
	MOV	DL,AL
	MOV	AH,STD_CON_OUTPUT
	clc					; set ok flag
	INT	21H

RPRINT3:
	POP	AX
	JC	RPrint5 			; Abnormal termination?
	TEST	AL,80h				; High bit set indicates end (carry clear)
	JZ	RPRINT1

RPRINT5:
	RestoreReg  <SI,DX,AX>
	RET
endif


;g
;g   This routine returns the upper case of the character in AL
;g   from the upper case table in DOS if character if above
;g   ascii 128, else subtract 20H if between "a" and "z"
;g

assume	ds:resgroup

in_char_xlat	proc	near

	cmp	al,80h				;g see if char is above ascii 128
	jb	other_xlat			;g no - upper case math
	sub	al,80h				;g only upper 128 characters in table
	push	ds
	push	bx
	lds	bx,dword ptr com_xlat_addr+1 ;g get table address
	add	bx,2				;g skip over first word, of table
	xlat	ds:byte ptr [bx]		;g convert to upper case
	pop	bx
	pop	ds
	jmp	short in_char_xlat_end		;g we finished - exit

other_xlat:
	cmp	al,'a'                          ;g if between "a" and "z", subtract
	jb	in_char_xlat_end		;g    20h to get upper case
	cmp	al,'z'                          ;g    equivalent.
	ja	in_char_xlat_end		;g
	sub	al,20h				;g Lower-case changed to upper-case

in_char_xlat_end:

	ret

in_char_xlat	endp
;---------------------- DBCS lead byte check. this is resident code ; 3/3/KK

ITESTKANJ:					;AN000;
TestKanjR:					;AN000;  3/3/KK
	push	ds				;AN000;  3/3/KK
	push	si				;AN000;  3/3/KK
	push	ax				;AN000;  3/3/KK
	lds	si,dbcs_vector_addr		;AN000;  GET DBCS VECTOR

ktlop:						;AN000;  3/3/KK
	cmp	word ptr ds:[si],0		;AN000;  3/3/KK end of Lead Byte Table
	je	notlead 			;AN000;  3/3/KK
	pop	ax				;AN000;  3/3/KK
	push	ax				;AN000;  3/3/KK
	cmp	al, byte ptr ds:[si]		;AN000;  3/3/KK
	jb	notlead 			;AN000;  3/3/KK
	inc	si				;AN000;  3/3/KK
	cmp	al, byte ptr ds:[si]		;AN000;  3/3/KK
	jbe	islead				;AN000;  3/3/KK
	inc	si				;AN000;  3/3/KK
	jmp	short ktlop			;AN000;  3/3/KK try another range

Notlead:					;AN000;  3/3/KK
	xor	ax,ax				;AN000;  3/3/KK set zero
	jmp	short ktret			;AN000;  3/3/KK

Islead: 					;AN000;  3/3/KK
	xor	ax,ax				;AN000;  3/3/KK reset zero
	inc	ax				;AN000;  3/3/KK

ktret:						;AN000;  3/3/KK
	pop	ax				;AN000;  3/3/KK
	pop	si				;AN000;  3/3/KK
	pop	ds				;AN000;  3/3/KK
	return					;AN000;  3/3/KK


; ****************************************************************
; *
; * ROUTINE:	 RESET_MSG_POINTERS
; *
; * FUNCTION:	 Resets addresses for parse and critical error
; *		 messages in DOS via INT 2fh.  This routine
; *		 is invoked before command exits.
; *
; * INPUT:	 none
; *
; * OUTPUT:	 none
; *
; ****************************************************************

reset_msg_pointers	proc	near

assume	ds:resgroup, es:nothing

	push	es				;AN000; save used registers
	push	ax				;AN000;
	push	dx				;AN000;
	push	di				;AN000;
;AD060; mov	ah,multdos			;AN000; reset parse message pointers
;AD060; mov	al,message_2f			;AN000; call for message retriever
;AD060; mov	dl,set_parse_msg		;AN000; set up parse message address
;AD060; mov	di,pars_msg_off 		;AN000; old offset of parse messages
;AD060; mov	es,pars_msg_seg 		;AN000; old segment of parse messages
;AD060; int	2fh				;AN000; go set it

;AD060; mov	ah,multdos			;AN000; set up to call DOS through int 2fh
;AD060; mov	al,message_2f			;AN000; call for message retriever
	mov	ax,(multdos shl 8 or message_2f);AN060; reset critical message pointers
	mov	dl,set_critical_msg		;AN000; set up critical error message address
	mov	di,crit_msg_off 		;AN000; old offset of critical messages
	mov	es,crit_msg_seg 		;AN000; old segment of critical messages
	int	2fh				;AN000; go set it
	pop	di				;AN000; restore used registers
	pop	dx				;AN000;
	pop	ax				;AN000;
	pop	es				;AN000;

	ret


reset_msg_pointers	endp

PUBLIC		MSG_SERV_ST			;AN000;
MSG_SERV_ST	LABEL	BYTE			;AN000;

PUBLIC	SYSGETMSG,SYSDISPMSG

ASSUME	DS:RESGROUP, ES:RESGROUP

.xlist
.xcref

INCLUDE SYSMSG.INC				;AN000; include message services

.list
.cref

MSG_UTILNAME <COMMAND>				;AN000; define utility name

MSG_SERVICES <COMR,NEARmsg,DISK_PROC,GETmsg,DISPLAYmsg,CHARmsg,NUMmsg> ;AC060; include message services macro

PUBLIC		RES_CODE_END			;AN000;
RES_CODE_END	LABEL	BYTE			;AN000;

include msgdcl.inc

CODERES ENDS
	END
