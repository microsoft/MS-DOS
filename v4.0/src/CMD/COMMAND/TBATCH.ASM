 page 80,132
;	SCCSID = @(#)tbatch.asm 4.5 85/10/01
;	SCCSID = @(#)tbatch.asm 4.5 85/10/01
TITLE	Batch processing routines


.xlist
.xcref
	INCLUDE comsw.asm
	INCLUDE DOSSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm
	include doscntry.inc		;AN000;
	include version.inc
.list
.cref


DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BATCH:WORD
	EXTRN	Batch_Abort:byte
	EXTRN	call_batch_flag:byte
	EXTRN	ECHOFLAG:BYTE
	EXTRN	forflag:byte
	EXTRN	forptr:word
	EXTRN	IFFlag:BYTE
	EXTRN	In_Batch:byte
	EXTRN	LTPA:WORD
	EXTRN	Nest:word
	EXTRN	next_batch:word
	EXTRN	nullflag:byte
	EXTRN	PIPEFLAG:BYTE
	EXTRN	RES_TPA:WORD
	EXTRN	SINGLECOM:WORD
	EXTRN	SUPPRESS:BYTE		;AC000;
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BADBAT_PTR:WORD
	EXTRN	Extend_buf_ptr:word	;AC000;
	EXTRN	Extend_buf_sub:byte	;AN022;
	EXTRN	msg_disp_class:byte	;AC000;
	EXTRN	NEEDBAT_PTR:WORD
	EXTRN	pausemes_ptr:word	;AC000;
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BatBufPos:WORD
	EXTRN	BATHAND:WORD
	EXTRN	bwdbuf:byte		;AN022;
	EXTRN	BYTCNT:WORD
	EXTRN	COMBUF:BYTE
	EXTRN	EXECPATH:BYTE
	EXTRN	ID:BYTE
	EXTRN	RCH_ADDR:DWORD
	EXTRN	RESSEG:WORD
	EXTRN	string_ptr_2:word	;AC000;
	EXTRN	TPA:WORD
	EXTRN	TRAN_TPA:WORD
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	cerror:near
	EXTRN	tcommand:near

;---------------

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
    extrn   arg:byte			; the arg structure!
transpace   ends
;---------------

Break	<PromptBat - Open or wait for batch file>

;
; Open the batch file.	If we cannot find the batch file.  If the media is
; changeable, we prompt for the change.  Otherwise, we terminate the batch
; file.  Leave segment registers alone.
;

Procedure   PromptBat,NEAR
	ASSUME	DS:ResGroup,ES:NOTHING
	invoke	BATOPEN 			; attempt to open batch file
	retnc
	cmp	dx,error_file_not_found 	;AN022; Ask for diskette if file not found
	jz	Bat_Remcheck			;AN022;
	cmp	dx,error_path_not_found 	;AN022; Ask for diskette if path not found
	jz	Bat_Remcheck			;AN022;    Otherwise, issue message and exit
	invoke	output_batch_name		;AN022; set up batch name in bwdbuf
	jmp	short BatDie			;AN022;

Bat_Remcheck:					;AN022; Go see if media is removable
	CALL	[RCH_ADDR]			; DX has error number
	JZ	AskForBat			; Media is removable
;
; The media is not changeable.	Turn everything off.
;
	invoke	ForOff
	invoke	PipeOff
	MOV	IfFlag,AL			; No If in progress.
	MOV	DX,OFFSET TRANGROUP:BADBAT_ptr

BatDie:
	call	BatchOff
	PUSH	CS
	POP	DS
	ASSUME	DS:TranGroup
	invoke	std_eprintf			;AC022; display message

;
; TCOMMAND resets the stack.  This is the equivalent of a non-local goto.
;
	JMP	TCOMMAND			; he cleans off stack

;
; Ask the user to reinsert the batch file
;
ASKFORBAT:
	ASSUME	DS:ResGroup
	PUSH	DS
	PUSH	CS
	POP	DS
	ASSUME	DS:TranGroup
	MOV	DX,OFFSET TRANGROUP:NEEDBAT_ptr  ;AN022;
	invoke	std_eprintf			 ;Prompt for batch file on stderr
	mov	dx,offset trangroup:pausemes_ptr ;AN000; get second part of message
	invoke	std_eprintf			 ;AN000; print it to stderr
	CALL	GetKeystroke
	POP	DS
	ASSUME	DS:ResGroup
	jmp	PromptBat
EndProc PromptBat

;****************************************************************
;*
;* ROUTINE:	Output_batch_name
;*
;* FUNCTION:	Sets up batch name to be printed on extended error
;*
;* INPUT:	DX - extended error number
;*
;* OUTPUT:	Ready to call print routine
;*
;****************************************************************

public	output_batch_name			;AN022;

Output_batch_name    proc near			;AN022;

	push	ds				;AN022; save resident segment
	mov	ds,[batch]			;AN022; get batch file segment
assume	DS:nothing				;AN022;
	mov	SI,BatFile			;AN022; get offset of batch file
	invoke	dstrlen 			;AN022; get length of string
	mov	di,offset Trangroup:bwdbuf	;AN022; target for batch name
	rep	movsb				;AN022; move the name

	push	cs				;AN022; get local segment
	pop	ds				;AN022;
assume	DS:trangroup				;AN022;
	mov	extend_buf_ptr,dx		;AN022; put message number in block
	mov	msg_disp_class,ext_msg_class	;AN022; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr   ;AN022; get extended message pointer
	mov	string_ptr_2,offset trangroup:bwdbuf ;AN022; point to substitution
	mov	extend_buf_sub,one_subst	;AN022; set up for one subst
	pop	ds				;AN022; restore data segment

	ret					;AN022; return

Output_batch_name    endp			;AN022;

Break	<GetKeystroke - get a keystroke and flush queue>

;
; read the next keystroke.  Since there may be several characters in the queue
; after the one we ask for (function keys/Kanji), we need to flush the queue
; AFTER waiting.
;
Procedure   GetKeyStroke,NEAR
;
; read any character at any mode, interim mode or not.
;

	PUSH	DX					;AN000;  3/3/KK
	MOV	AX,(ECS_call SHL 8) OR GetInterimMode	;AN000;  3/3/KK
	INT	int_command				;AN000;  3/3/KK
	PUSH	DX					;AN000;  save interim state 3/3/KK
	MOV	AX,(ECS_call SHL 8) OR SetInterimMode	;AN000;  3/3/KK
	MOV	DL,InterimMode				;AN000;  3/3/KK
	INT	int_command				;AN000;  3/3/KK

	MOV	AX,(STD_CON_INPUT_FLUSH SHL 8) OR STD_CON_INPUT_no_echo
	INT	int_command		; Get character with KB buffer flush
	MOV	AX,(STD_CON_INPUT_FLUSH SHL 8) + 0
	INT	int_command

	MOV	AX,(ECS_call SHL 8) OR SetInterimMode	;AN000;  3/3/KK
	POP	DX					;AN000;  restore interim state 3/3/KK
	INT	int_command				;AN000;  3/3/KK
	POP	DX					;AN000;  3/3/KK

	return
EndProc GetKeyStroke

Break	<ReadBat - read 1 line from batch file>

;
; ReadBat - read a single line from the batch file.  Perform all substitutions
; as appropriate
;

Procedure   ReadBat,NEAR
	ASSUME	DS:ResGroup,ES:TranGroup
	mov	suppress,yes_echo		;g initialize line suppress status
	test	byte ptr [Batch_Abort],-1
	jnz	Trying_To_Abort
	mov	byte ptr [In_Batch],1		; set flag to indicate batch job
	CALL	PromptBat

Trying_To_Abort:
	MOV	DI,OFFSET TRANGROUP:COMBUF+2

;
; Save position and try to scan for first non delimiter.
;

TESTNOP:
	MOV	AX,DS
	MOV	DS,Batch
	ASSUME	DS:NOTHING
	PUSH	WORD PTR DS:[BatSeek]
	PUSH	WORD PTR DS:[BatSeek+2] 	; save current location.
	MOV	DS,AX
	ASSUME	DS:ResGroup
	invoke	SkipDelim			; skip to first non-delim
;
; If the first non-delimiter is not a :  (label), we reseek back to the
; beginning and read the line.
;
	CMP	AL,':'                          ; is it a label?
	POP	CX
	POP	DX				; restore position in bat file
	JZ	NopLine 			; yes, resync everything.
	TEST	[BATCH],-1			; are we done with the batch file?
	JZ	RdBat

	CMP	AL, NO_ECHO_CHAR		;g see if user wants to suppress line
	JNZ	SET_BAT_POS			;g no - go and set batch file position
	MOV	SUPPRESS, NO_ECHO		;g yes set flag to indicate
	jmp	Rdbat				;g go read batch file

SET_BAT_POS:					;g
	PUSH	DS
	MOV	DS,Batch
	ASSUME	DS:NOTHING
	MOV	WORD PTR DS:[BatSeek],DX	; reseek back to beginning
	MOV	WORD PTR DS:[BatSeek+2],CX
	POP	DS
	ASSUME	DS:ResGroup
	MOV	AX,(LSEEK SHL 8) + 0		; seek back
	INT	int_command
	MOV	BatBufPos,-1			; nuke batch buffer position
	xor	cx,cx				; Initialize line length to zero
	JMP	RdBat
;
; The first non-delimiter is a :.  This line is not echoed and is ignored.
; We eat characters until a CR is seen.
;

NOPLINE:
	CALL	SkipToEOL
	invoke	GetBatByt			; eat trailing LF
	TEST	[BATCH],-1			; are we done with the batch file?
	JNZ	TESTNOP 			; no, go get another line
	return					; Hit EOF

;
; Read a line into the buffer pointed to by ES:DI.  If any %s are seen in the
; input, we are to consider two special cases:
;
;   %0 to %9	These represent replaceable parameters from the batch segment
;   %sym%	This is a symbol from the environment
;

RDBAT:
	invoke	GetBatByt
	inc	cx				; Inc the line length
	cmp	cx,COMBUFLEN			; Is it too long?
	jae	TooLong 			; Yes - handle it, handle it
;
; See if we have a parameter character.
;
	CMP	AL,'%'                          ; Check for parameter
	JZ	NEEDPARM
;
; no parameter character.  Store it as usual and see if we are done.
;

SAVBATBYT:
	STOSB
	CMP	AL,0DH				; End of line found?
	JNZ	RDBAT				; no, go for more
;
; We have read in an entire line.  Decide whether we should echo the command
; line or not.
;

Found_EOL:
	SUB	DI,OFFSET TRANGROUP:COMBUF+3
	MOV	AX,DI				; remember that we've not counted the CR
	MOV	ES:[COMBUF+1],AL		; Set length of line
	invoke	GetBatByt			; Eat linefeed
	invoke	BATCLOSE
	CMP	SUPPRESS, NO_ECHO		;G
	JZ	Reset				;G
	test	[echoflag],1			; To echo or not to echo, that is the
	jnz	try_nextflag

Reset:
	PUSH	CS				;  question.  (Profound, huh?)
	POP	DS				; Go back to local segment
	retz					; no echoing here...
;
; Echo the command line with appropriate CRLF...
;


try_nextflag:
	cmp	nullflag,nullcommand		;G was there a command last time?
	jz	No_crlf_print			;G no - don't print crlf
	invoke	CRLF2				;G  Print out prompt

no_crlf_print:
	invoke	PRINT_PROMPT			;G
	PUSH	CS				;G change data segment
	POP	DS				;G

ASSUME DS:TRANGROUP
	mov	dx,OFFSET TRANGROUP:COMBUF+2	; get command line for echoing
	invoke	CRPRINT
	invoke	CRLF2
	return
;
; The line was too long.  Eat remainder of input text up until the CR
;
TooLong:
	ASSUME	DS:ResGroup
	cmp	al,0dh				; Has the end of the line been reached?
	jz	Ltlcont 			; Yes, continue
	CALL	SkipToEOL			; Eat remainder of line

Ltlcont:
	stosb					; Terminate the command
	jmp	Found_EOL			; Go process the valid part of the line
;
; We have found a parameter lead-in character.	Check for the 0-9 case first
;

NEEDPARM:
	invoke	GetBatByt			; get next character
	CMP	AL,'%'                          ; Check for two consecutive %
	JZ	SAVBATBYT			; if so, replace with a single %
	CMP	AL,0Dh				; Check for end-of-line
	JZ	SAVBATBYT			; yes, treat it normally
;
; We have found %<something>.  If the <something> is in the range 0-9, we
; retrieve the appropriate parameter from the batch segment.  Otherwise we
; see if the <something> has a terminating % and then look up the contents
; in the environment
;
PAROK:
	SUB	AL,'0'
	JB	NEEDENV 			; look for parameter in the environment
	CMP	AL,9
	JA	NEEDENV
;
; We have found %<number>.  This is taken from the parameters in the
; allocated batch area.
;
	CBW
	MOV	BX,AX				; move index into AX
	SHL	BX,1				; convert word index into byte ptr
	SaveReg <ES>
	MOV	ES,Batch
;
; The structure of the batch area is:
;
;   BYTE    type of segment
;   DWORD   offset for next line
;   10 WORD pointers to parameters.  -1 is empty parameter
;   ASCIZ   file name (with . and ..)
;   BYTES   CR-terminated parameters
;   BYTE    0 flag to indicate end of parameters
;
; Get pointer to BX'th argument
;
	MOV	SI,ES:BatParm[BX]
	RestoreReg  <ES>
;
; Is there a parameter here?
;
	CMP	SI,-1				; Check if parameter exists
	JNZ	Yes_there_is			;G Yes go get it
	JMP	RDBAT				; Ignore if it doesn't
;
; Copy in the found parameter from batch segment
;

Yes_there_is:
	PUSH	DS
	MOV	DS,Batch
	ASSUME	DS:NOTHING
	dec	cx				; Don't count '%' in line length

CopyParm:
	LODSB					; From resident segment
	CMP	AL,0DH				; Check for end of parameter
	JZ	EndParam
	inc	cx				; Inc the line length
	cmp	cx,COMBUFLEN			; Is it too long?
	jae	LineTooL			; Yes - handle it, handle it
	STOSB
	JMP	CopyParm
;
; We have copied up to the limit.  Stop copying and eat remainder of batch
; line.  We need to make sure that the tooLong code isn't fooled into
; believing that we are at EOL.  Clobber AL too.
;

LineTooL:
	XOR	AL,AL
	POP	DS
	ASSUME	DS:RESGROUP
	JMP	TooLong
;
; We have copied in an entire parameter.  Go back for more
;

EndParam:
	POP	DS
	JMP	RDBat
;
; We have found % followed by something other than 0-9.  We presume that there
; will be a following % character.  In between is an environment variable that
; we will fetch and replace in the batch line with its value.
;

NEEDENV:
	SaveReg <DS,DI>
	MOV	DI,OFFSET TRANGROUP:ID		; temp spot for name
	ADD	AL,'0'                          ; reconvert character
	STOSB					; store it in appropriate place
;
; loop getting characters until the next % is found or until EOL
;

GETENV1:
	invoke	GetBatByt			; get the byte
	STOSB					; store it
	CMP	AL,0Dh				; EOL?
	JNZ	GETENV15			; no, see if it the term char
;
; The user entered a string with a % but no trailing %.  We copy the string.
;
	mov	byte ptr es:[di-1],0		; nul terminate the string
	mov	si,offset TranGroup:ID		; point to buffer
	pop	di				; point to line buffer
	push	cs
	pop	ds
	call	StrCpy
IF  IBMCOPYRIGHT
	dec	di
	pop	ds
ELSE
	pop	ds
	jc	LineTooL
ENDIF
	jmp	SavBatByt

getenv15:
	CMP	AL,'%'                          ; terminating %?
	JNZ	GETENV1 			; no, go suck out more characters
	mov	al,'='                          ; terminate  with =
	MOV	ES:[DI-1],al
;
; ID now either has a =-terminated string which we are to find in the
; environment or a non =-terminated string which will not be found in the
; environment.
;
GETENV2:
	MOV	SI,OFFSET TRANGROUP:ID
	PUSH	CS
	POP	DS				; DS:SI POINTS TO NAME
	ASSUME DS:TRANGROUP
	PUSH	CX
	INVOKE	FIND_NAME_IN_environment
	ASSUME ES:RESGROUP
	POP	CX
	PUSH	ES
	POP	DS
	assume ds:resgroup
	PUSH	CS
	POP	ES
	ASSUME ES:TRANGROUP
	MOV	SI,DI
	POP	DI				; get back pointer to command line
;
; If the parameter was not found,  there is no need to perform any replacement.
; We merely pretend that we've copied the parameter.
;
IF  IBMCOPYRIGHT
	JC	GETENV6
ELSE
	jnc	GETENV4
	pop	ds
	jmp	rdbat
ENDIF
;
; ES:DI points to command line being built
; DS:SI points either to nul-terminated environment object AFTER =
;

GETENV4:
	ASSUME	ES:NOTHING
	call	StrCpy

IF  IBMCOPYRIGHT
	dec	di

GETENV6:
	POP	DS				; restore pointer to resgroup
ELSE
	pop	ds
	jc	LineTooL
ENDIF
	JMP	RDBAT				; no, go back to batch file

EndProc ReadBat

;
;   SkipToEOL - read from batch file until end of line
;

Procedure   SkipToEOL,NEAR

	ASSUME	DS:ResGroup,ES:NOTHING

	TEST	Batch,-1
	retz					; no batch file in effect
	invoke	GetBatByt
	CMP	AL,0Dh				; eol character?
	JNZ	SkipToEOL			; no, go eat another
	return

EndProc SkipToEOL

Break	<Allocate and deallocate the transient portion>

;
; Free Transient.  Modify ES,AX,flags
;

Procedure   Free_TPA,NEAR

ASSUME	DS:TRANGROUP,ES:RESGROUP

	PUSH	ES
	MOV	ES,[RESSEG]
	MOV	ES,[RES_TPA]
	MOV	AH,DEALLOC
	INT	int_command			; Make lots of free memory
	POP	ES

	return

EndProc Free_TPA

;
; Allocate transient.  Modify AX,BX,DX,flags
;

Procedure   Alloc_TPA,NEAR

ASSUME DS:TRANGROUP,ES:RESGROUP

	PUSH	ES
	MOV	ES,[RESSEG]
	MOV	BX,0FFFFH			; Re-allocate the transient
	MOV	AH,ALLOC
	INT	int_command
	PUSH	BX				; Save size of block
	MOV	AH,ALLOC
	INT	int_command
;
; Attempt to align TPA on 64K boundary
;
	POP	BX				; Restore size of block
	MOV	[RES_TPA], AX			; Save segment to beginning of block
	MOV	[TRAN_TPA], AX
;
; Is the segment already aligned on a 64K boundary
;
	MOV	DX, AX				; Save segment
	AND	AX, 0FFFH			; Test if above boundary
	JNZ	Calc_TPA
	MOV	AX, DX
	AND	AX, 0F000H			; Test if multiple of 64K
	JNZ	NOROUND

Calc_TPA:
	MOV	AX, DX
	AND	AX, 0F000H
	ADD	AX, 01000H			; Round up to next 64K boundary
	JC	NOROUND 			; Memory wrap if carry set
;
; Make sure that new boundary is within allocated range
;
	MOV	DX, [RES_TPA]
	ADD	DX, BX				; Compute maximum address
	CMP	DX, AX				; Is 64K address out of range?
	JB	NOROUND
;
; Make sure that we won't overwrite the transient
;
	MOV	BX, CS				; CS is beginning of transient
	CMP	BX, AX
	JB	NOROUND
;
; The area from the 64K boundary to the beginning of the transient must
; be at least 64K.
;
	SUB	BX, AX
	CMP	BX, 4096			; Size greater than 64K?
	JAE	ROUNDDONE

NOROUND:
	MOV	AX, [RES_TPA]

ROUNDDONE:
	MOV	[LTPA],AX			; Re-compute everything
	MOV	[TPA],AX
	MOV	BX,AX
	MOV	AX,CS
	SUB	AX,BX
	PUSH	BX
	MOV	BX,16
	MUL	BX
	POP	BX
	OR	DX,DX
	JZ	SAVSIZ2
	MOV	AX,-1

SAVSIZ2:
;
; AX is the number of bytes free in the buffer between the resident and the
; transient with a maximum of 64K-1.  We round this down to a multiple of 512.
;
	CMP	AX,512
	JBE	GotSize
	AND	AX,0FE00h			; NOT 511 = NOT 1FF

GotSize:
	MOV	[BYTCNT],AX
	POP	ES

	return

EndProc Alloc_TPA

Break	<BatCom - enter a batch file>

;
; The exec search has determined that the user has requested a batch file for
; execution.  We parse the arguments, create the batch segment, and signal
; batch processing.
;
Procedure   BatCom,NEAR

ASSUME	DS:TRANGROUP, ES:NOTHING

;
; Batch parameters are read with ES set to segment of resident part
;

	MOV	ES,[RESSEG]
ASSUME	ES:RESGROUP
	cmp	es:[call_batch_flag],call_in_progress ;AN043; If in CALL,
	jz	skip_ioset			;AN043;   redirection was already set up
	invoke	IOSET				; Set up any redirection

skip_ioset:					;AN043;
	CALL	FREE_TPA			; G
	cmp	es:[call_batch_flag],call_in_progress ;G
	jz	getecho 			; G if we're in a call, don't execute
;
; Since BATCH has lower precedence than PIPE or FOR.  If a new BATCH file is
; being started it MUST be true that no FOR or PIPE is currently in progress.
; Don't execute if in call
;
	invoke	ForOff

getecho:
	invoke	PipeOff
	mov	al,EchoFlag			; preserve echo state for chaining

	and	al, 1				; Save current echo state
	push	ax

	xor	ax,ax				;G
	test	es:[batch],-1			;G  Are we in a batch file?
	jz	leavebat			;G  No, nothing to save
	mov	ax,es:[batch]			;G get current batch segment
	cmp	es:[call_batch_flag],call_in_progress  ;G
	jz	leavebat			;G
;
;  We are in a chained batch file, save batlast from previous batch segment
;  so that if we're in a CALL, we will return to the correct batch file.
;
	push	es				;G
	mov	es,ax				;G get current batch segment
	mov	ax,es:[batlast] 		;G get previous batch segment
	pop	es				;G

leavebat:					;G
	push	ax				;G keep segment until new one created
	cmp	es:[call_batch_flag],call_in_progress  ;G are we in a CALL?
	jz	startbat			;G Yes, keep current batch segment
	call	BatchOff			;G No, deallocate old batch segment

;
; Find length of batch file
;

startbat:					;G
	ASSUME	ES:RESGROUP
	MOV	es:[CALL_BATCH_FLAG], 0 	;G  reset call flag
	mov	SI, OFFSET TRANGROUP:EXECPATH

	mov	ax,AppendTruename		;AN042; Get the real path where the batch file
	int	2fh				;AN042;    was found with APPEND
	mov	ah,Find_First			;AN042; The find_first will return it
	mov	dx,si				;AN042; Get the string
	mov	cx,search_attr			;AN042; filetypes to search for
	int	int_command			;AN042;

	invoke	DStrLen
;
; Allocate batch area:
;   BYTE    type of segment
;   WORD    segment of last batch file
;   WORD    segment for FOR command
;   BYTE    FOR flag state on entry to batch file
;   DWORD   offset for next line
;   10 WORD pointers to parameters.  -1 is empty parameter
;   ASCIZ   file name (with . and ..)
;   BYTES   CR-terminated parameters
;   BYTE    0 flag to indicate end of parameters
;
; We allocate the maximum size for the command line and use setblock to shrink
; later when we've squeezed out the extra
;

	MOV	BX,CX				; length of file name.
	ADD	BX,0Fh + (SIZE BatchSegment) + COMBUFLEN + 0Fh
						; structure + max len + round up
	SaveReg <CX>
	MOV	CL,4
	SHR	BX,CL				; convert to paragraphs
	PUSH	BX				;G save size of batch segment
	MOV	AH,ALLOC
	INT	int_command			; Allocate batch segment
	POP	BX				;G get size of batch segment
;
; This should *NEVER* return an error.	The transient is MUCH bigger than
; the batch segment.  This may not be true, however, in a multitasking system.
; G This error will occur with nesting of batch files.	We also need to
; G make sure that we don't overlay the transient.
;
	jc	mem_error			;G not enough memory - exit
	push	ax				;G save batch segment
	add	ax,bx				;G get end of batch segment
	add	ax,20h				;G add some tpa work area
	mov	bx,cs				;G get the transient segment
	cmp	ax,bx				;G do we end before the transient
	pop	ax				;G get batch segment back
	jb	enough_mem			;G we have enough memory - continue
	push	es				;G no we're hitting the transient
	mov	es,ax
	mov	ax,DEALLOC SHL 8		;G deallocate the batch segment
	int	int_command
	pop	es

mem_error:
	jmp	no_memory			;G Set up for message and exit

enough_mem:
	MOV	[BATCH],AX
	CALL	ALLOC_TPA
;
; Initialize batch segment
;
	RestoreReg  <DX>			; length of name
	POP	AX				;G  get saved batch segment back
	inc	es:nest 			;G increment # batch files in progress
	PUSH	ES
	MOV	ES,[BATCH]
ASSUME	ES:NOTHING
	MOV	ES:[BatType],BatchType		; signal batch file type
	MOV	ES:[batlast],ax 		;G save segment of last batch file
	push	DS				;G
	mov	DS,[resseg]			;G set to resident data
ASSUME	DS:RESGROUP
	xor	ax,ax				;G
	mov	bl,forflag			;G get the current FOR state
	mov	ES:[batforflag],bl		;G save it in the batch segment
	test	bl,-1				;G are we in a FOR?
	jz	for_not_on			;G no, for segment set to 0
	mov	ax,forptr			;G yes, get current FOR segment
	mov	forflag,0			;G reset forflag

for_not_on:
	mov	ES:[batforptr],ax		;G save FOR segment in batch segment
	XOR	AX,AX
	mov	forptr,ax			;G make sure for segment is not active
	mov	bl,echoflag			;G
	pop	DS				;G

	mov	byte ptr es:[Batechoflag],bl	;G save echo state of parent
	MOV	WORD PTR ES:[BatSeek],AX	; point to beginning of file
	MOV	WORD PTR ES:[BatSeek+2],AX
;
; Initialize pointers
;
	DEC	AX				; put -1 into AX
	MOV	DI,BatParm			; point to parm area
	MOV	BX,DI
	MOV	CX,10
	REP	STOSW				; Init to no parms
;
; Move in batch file name
;
	MOV	CX,DX
	rep	movsb				; including NUL.
;
; Now copy the command line into batch segment, parsing the arguments along
; the way.  Segment will look like this:
;
;   <arg0>CR<arg1>CR...<arg9>CR<arg10>CR...<ARGn>CR 0
;
; or, in the case of fewer arguments:
;
;   <arg0>CR<arg1>CR...<arg6>CR CR CR ... CR 0
;
	MOV	SI,OFFSET TRANGROUP:COMBUF+2
	MOV	CX,10				; at most 10 arguments
;
; Look for beginning of next argument
;
EACHPARM:
	invoke	SCANOFF 			; skip to argument
;
; AL is first non-delimiter.  DS:SI points to char = AL
;
	CMP	AL,0DH				; end of road?
	JZ	HAVPARM 			; yes, no more arguments
;
; If CX = 0 then we have stored the most parm we can.  Skip store
;
	JCXZ	MOVPARM 			; Only first 10 parms get pointers
;
; Go into allocated piece and stick in new argument pointer.
;
	MOV	ES:[BX],DI			; store batch pointer
	ADD	BX,2				; advance arg counter
;
; Move the parameter into batch segment
;
MOVPARM:
	LODSB					; get byte
	INVOKE	DELIM				; if delimiter
	JZ	ENDPARM 			; then done with parm
	STOSB					; store byte
	CMP	AL,0DH				; if CR then not delimiter
	JZ	HAVPARM 			; but end of parm list, finish
	JMP	SHORT MOVPARM
;
; We have copied a parameter up until the first separator.  Terminate it with
; CR
;

ENDPARM:
	MOV	AL,0DH
	STOSB
	JCXZ	EACHPARM			; if no parameters, don't dec
	DEC	CX				; remember that we've seen one.
	JMP	SHORT EACHPARM
;
; We have parsed the entire line. Terminate the arg list
;

HAVPARM:
	XOR	AL,AL
	STOSB					; Nul terminate the parms
;
; Now we know EXACTLY how big the BATCH segment is.  Round up size (from DI)
; into paragraphs and setblock to the appropriate size
;
	LEA	BX,[DI+15]
	MOV	CL,4
	SHR	BX,CL
	MOV	AH,SetBlock
	INT	int_command

	POP	ES
ASSUME	ES:RESGROUP
	PUSH	ES
	POP	DS				; Simply batch FCB setup
ASSUME	DS:RESGROUP
	CMP	[SINGLECOM],-1
	JNZ	NOBATSING
	MOV	[SINGLECOM],0FFF0H		; Flag single command BATCH job

NOBATSING:
;
; Enter the batch file with the current echo state
;
	pop	ax				; Get original echo state
	mov	echoflag,al			;g restore it
	JMP	TCOMMAND

;
; The following is executed if there isn't enough memory for batch segment
;

NO_MEMORY:
	assume ds:trangroup,es:resgroup
	pop	dx				;g even up our stack
	pop	ax				;g
	pop	ax				;g
	call	Alloc_tpa			;g reallocate memory
	mov	msg_disp_class,ext_msg_class	;AN000; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr     ;AC000; get extended message pointer
	mov	Extend_Buf_ptr,error_not_enough_memory ;AN000; get message number in control block
	jmp	cerror				;g print error message and go...

EndProc BatCom

Procedure   BatchOff

	ASSUME	DS:NOTHING,ES:NOTHING

	SaveReg <AX,ES>
	PUSH	DS				;G
	PUSH	BX				;G
	MOV	ES,ResSeg
	MOV	DS,ResSeg			;G
	ASSUME	ES:ResGroup,DS:Resgroup 	;G
	MOV	AX,Batch			; Free the batch segment
	OR	AX,AX
	JZ	nofree

	PUSH	ES
	MOV	ES,AX
	test	[echoflag],1			;G Is echo on?
	jnz	echo_last_line			;G Yes - echo last line in file
	mov	suppress,no_echo		;G no - don't echo last line in file

echo_last_line:
	MOV	BL,ES:[BATECHOFLAG]		;G  Get echo state
	mov	[echoflag],bl			;G     and restore it
	MOV	BX,ES:[BATFORPTR]		;G  Get FOR segment
	MOV	FORPTR,BX			;G     and restore it
	MOV	BL,ES:[BATFORFLAG]		;G  Get FOR flag
	MOV	FORFLAG,BL			;G     and restore it
	MOV	BX,es:[batlast] 		;G  get old batch segment
	MOV	AH,DEALLOC
	INT	int_command
	POP	ES
	MOV	Next_BATCH,BX			;G  reset batch segment
	DEC	es:NEST 			;G

	XOR	AX,AX
	MOV	Batch,AX			; No batch in progress

NoFree:
	POP	BX				;G
	pop	ds				;G
	RestoreReg  <ES,AX>

	return

EndProc BatchOff


IF  IBMCOPYRIGHT

Procedure StrCpy,near

	push	ax
cycle:
	lodsb
	stosb
	or	al,al
	jnz	cycle
	pop	ax

	return

EndProc StrCpy

ELSE
; StrCpy - copy string, checking count in CX against COMBUFLEN
;	Entry : DS:SI ==> source string
;		ES:DI ==> destination string
;		CX = current length of destination string
;	Exit  : string copied, CX updated, Carry set if length limit exceeded
Procedure StrCpy,NEAR
	push	ax
ccycle:
	lodsb
	inc	cx
	cmp	cx,COMBUFLEN
	jb	ccopy
	stc				; set carry to signal error
	jmp	short ccend
ccopy:
	stosb
	or	al,al
	jnz	ccycle

ccend:
	dec	cx			; discount extra byte
	dec	di			; back up pointer
	pop	ax
	return				; return carry clear
EndProc StrCpy

ENDIF

TRANCODE    ENDS
	    END

