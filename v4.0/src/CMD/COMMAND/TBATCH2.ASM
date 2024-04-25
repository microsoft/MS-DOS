 page 80,132
;	SCCSID = @(#)tbatch2.asm	4.2 85/07/22
;	SCCSID = @(#)tbatch2.asm	4.2 85/07/22
TITLE	Batch processing routines part II

	INCLUDE comsw.asm

.xlist
.xcref
	INCLUDE DOSSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm
.list
.cref


DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BATCH:WORD
	EXTRN	Batch_Abort:byte
	EXTRN	call_batch_flag:byte
	EXTRN	call_flag:byte
	EXTRN	IFFlag:BYTE
	EXTRN	In_Batch:byte
	EXTRN	Nest:word
	EXTRN	PIPEFILES:BYTE
	EXTRN	RETCODE:WORD
	EXTRN	SINGLECOM:WORD
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BADLAB_PTR:WORD
	EXTRN	BatBufLen:WORD
	EXTRN	IFTAB:BYTE
	EXTRN	SYNTMES_PTR:WORD
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg:byte		; the arg structure!
	EXTRN	BatBuf:BYTE
	EXTRN	BatBufEnd:WORD
	EXTRN	BatBufPos:WORD
	EXTRN	BATHAND:WORD
	EXTRN	COMBUF:BYTE
	EXTRN	DIRBUF:BYTE
	EXTRN	GOTOLEN:WORD
	EXTRN	if_not_count:word
	EXTRN	IFNOTFLAG:BYTE
	EXTRN	RESSEG:WORD
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	cerror:near
	EXTRN	docom1:near
	EXTRN	tcommand:near

	public	$if,iferlev,goto,shift,ifexists,ifnot,forerror,$call


Break	<GetBatByt - retrieve a byte from the batch file>

; Get one byte from the batch file and return it in AL.  End-of-file returns
; <CR> and ends batch mode.  DS must be set to resident segment.
; AH, DX destroyed.

Procedure   GETBATBYT,NEAR

ASSUME	DS:RESGROUP

	SaveReg <BX,CX,DS>
	test	byte ptr [Batch_Abort],-1
	jnz	BatEOF
	TEST	Batch,-1
	JZ	BatEOF
	PUSH	ES
	MOV	ES,Batch
	ASSUME	ES:NOTHING
	ADD	WORD PTR ES:[BatSeek],1
	ADC	WORD PTR ES:[BatSeek+2],0
	POP	ES
;
; See if we have bytes buffered...
;
	MOV	AX,CS
	MOV	DS,AX
	ASSUME	DS:TranGroup
	MOV	BX,BatBufPos
	CMP	BX,-1
	JNZ	UnBuf
;
; There are no bytes in the buffer.  Let's try to fill it up.
;
	MOV	DX,OFFSET TranGROUP:BatBuf
	MOV	CX,BatBufLen			; max to read.
	MOV	BX,BatHand
	MOV	AH,READ
	INT	int_command			; Get one more byte from batch file
	jnc	bat_read_ok			;AN022; if no error - continue
	invoke	get_ext_error_number		;AN022; get the error
	push	ds				;AN022; save local segment
	mov	ds,[resseg]			;AN022; get resident segment
assume	ds:resgroup				;AN022;
	mov	dx,ax				;AN022; put error in DX
	invoke	output_batch_name		;AN022; set up to print the error
	pop	ds				;AN022;
assume	ds:trangroup				;AN022;
	invoke	std_eprintf			;AN022; print out the error
	mov	byte ptr combuf+2,end_of_line_in;AN022; terminate the batch line for parsing
	mov	byte ptr combuf+3,end_of_line_out ;AN022; terminate the batch line for output
	jmp	bateof				;AN022; terminate the batch file

bat_read_ok:					;AN022;
	MOV	CX,AX
	JCXZ	BATEOFDS
	MOV	BatBufEnd,CX
	XOR	BX,BX
	MOV	BatBufPos,BX
;
; Buffered bytes!
;
UnBuf:
	MOV	AL,BatBuf[BX]			; get next byte
	INC	BX
	CMP	BX,BatBufEnd			; beyond end of buffer?
	JB	SetBufPos
	MOV	BX,-1

SetBufPos:
	MOV	BatBufPos,BX
	CMP	AL,1AH				; ^Z for termination?
	jnz	GetByteDone

BatEOFDS:
	ASSUME	DS:TranGroup
	MOV	DS,ResSeg
	ASSUME	DS:ResGroup

BATEOF:
	invoke	BatchOff
	CALL	BATCLOSE
	MOV	AL,0DH				; If end-of-file, then end of line
	test	byte ptr [Batch_Abort],-1
	mov	byte ptr [Batch_Abort],0
	jz	Cont_Get_Byt
	mov	di,offset TRANGROUP:COMBUF+2	; reset pointer to beginning of buffer
	xor	cx,cx				; zero line length
	jmp	short GetByteDone

Cont_Get_Byt:
	CMP	[SINGLECOM],0FFF0H		; See if we need to set SINGLECOM
	JNZ	GetByteDone
	CMP	NEST,0				;G See if we have nested batch files
	JNZ	GETBYTEDONE			;G Yes - don't exit just yet
	MOV	[SINGLECOM],-1			; Cause termination

GetByteDone:
	RestoreReg  <DS,CX,BX>

	return

EndProc GetBatByt

	break	<$If - conditional execution>
assume	ds:trangroup,es:trangroup

IFERRORP:
	POP	AX
IFERROR:
FORERROR:
	MOV	DX,OFFSET TRANGROUP:SYNTMES_ptr
	JMP	CERROR

$IF:
;
; Turn off any pipes in progress.
;
	push	ds				;AN004; save local DS
	mov	ds,[resseg]			;AN004; get resident segment
	assume	ds:resgroup			;AN004;
	cmp	[PIPEFILES],0			;AN004; Only turn off if present.
	jz	IFNoPipe			;AN004; no pipe - continue
	invoke	PipeDel 			;AN004; turn off piping

IFNoPipe:					;AN004;
	pop	ds				;AN004; get local DS back
	assume	ds:trangroup			;AN004;
	MOV	[IFNOTFLAG],0
	mov	[if_not_count], 0
	MOV	SI,81H

IFREENT:
	invoke	SCANOFF
	CMP	AL,0DH
	JZ	IFERROR
	MOV	BP,SI
	MOV	DI,OFFSET TRANGROUP:IFTAB	; Prepare to search if table
	MOV	CH,0

IFINDCOM:
	MOV	SI,BP
	MOV	CL,[DI]
	INC	DI
	JCXZ	IFSTRING
	JMP	SHORT FIRSTCOMP

IFCOMP:
	JNZ	IF_DIF				;AC000;

FIRSTCOMP:
	LODSB
	MOV	AH,ES:[DI]
	INC	DI
	CMP	AL,AH
	JZ	IFLP
	OR	AH,20H				; Try lower case
	CMP	AL,AH

IFLP:
	LOOP	IFCOMP

IF_DIF: 					;AC000;
	LAHF
	ADD	DI,CX				; Bump to next position without affecting flags
	MOV	BX,[DI] 			; Get handler address
	INC	DI
	INC	DI
	SAHF
	JNZ	IFINDCOM
	LODSB
	CMP	AL,0DH

IFERRORJ:
	JZ	IFERROR
	invoke	DELIM
	JNZ	IFINDCOM
	invoke	SCANOFF
	JMP	BX

IFNOT:
	NOT	[IFNOTFLAG]
	inc	[if_not_count]
	JMP	IFREENT

;
; We are comparing two strings for equality.  First, find the end of the
; first string.
;

IFSTRING:
	PUSH	SI				; save away pointer for later compare
	XOR	CX,CX				; count of chars in first string

FIRST_STRING:
	LODSB					; get character
	CMP	AL,0DH				; end of line?
	JZ	IFERRORP			; yes => error
	invoke	DELIM				; is it a delimiter?
	JZ	EQUAL_CHECK			; yes, go find equal sign
	INC	CX				; remember 1 byte for the length
	JMP	FIRST_STRING			; go back for more
;
; We have found the end of the first string.  Unfortunately, we CANNOT use
; scanoff to find the next token; = is a valid separator and will be skipped
; over.
;

EQUAL_CHECK:
	CMP	AL,'='                          ; is char we have an = sign?
	JZ	EQUAL_CHECK2			; yes, go find second one.
	CMP	AL,0DH				; end of line?
	JZ	IFERRORPj			;AC004; yes, syntax error
	LODSB					; get next char
	JMP	EQUAL_CHECK
;
; The first = has been found.  The next char had better be an = too.
;

EQUAL_CHECK2:
	LODSB					; get potential = char
	CMP	AL,'='                          ; is it good?
	jnz	iferrorpj			; no, error
;
; Find beginning of second string.
;
	invoke	SCANOFF
	CMP	AL,0DH
	jz	iferrorpj
	POP	DI
;
; DS:SI points to second string
; CX has number of chars in first string
; ES:DI points to first string
;
; Perform compare to elicit match
;
	REPE	CMPSB
	JZ	MATCH				; match found!
;
; No match.  Let's find out what was wrong.  The character that did not match
; has been advanced over.  Let's back up to it.
;
	DEC	SI
;
; If it is EOL, then syntax error
;
	CMP	BYTE PTR [SI],0DH
	JZ	IFERRORJ
;
; Advance pointer over remainder of unmatched text to next delimiter
;

SKIPSTRINGEND:
	LODSB

NOTMATCH:
	CMP	AL,0DH

IFERRORJ2:
	JZ	IFERRORJ
	invoke	DELIM
	JNZ	SKIPSTRINGEND
;
; Signal that we did NOT have a match
;
	MOV	AL,-1
	JMP	SHORT IFRET

iferrorpj:
	jmp	iferrorp
;
; The compare succeeded.  Was the second string longer than the first?	We
; do this by seeing if the next char is a delimiter.
;

MATCH:
	LODSB
	invoke	DELIM
	JNZ	NOTMATCH			; not same.
	XOR	AL,AL
	JMP	SHORT IFRET

IFEXISTS:
ifexist_attr	    EQU     attr_hidden+attr_system

moredelim:
	lodsb					; move command line pointer over
	invoke	delim				; pathname -- have to do it ourselves
	jnz	moredelim			; 'cause parse_file_descriptor is dumb
	mov	DX, OFFSET TRANGROUP:dirbuf
	trap	set_dma
	mov	BX, 2				; if(0) [|not](|1) exist[1|2] file(2|3)
	add	BX, [if_not_count]
	mov	AX, OFFSET TRANGROUP:arg.argv
	invoke	argv_calc			; convert arg index to pointer
	mov	DX, [BX].argpointer		; get pointer to supposed filename
	mov	CX, ifexist_attr		; filetypes to search for
	trap	Find_First			; request first match, if any
	jc	if_ex_c 			; carry is how to determine error
	xor	AL, AL
	jmp	ifret

if_ex_c:
	mov	AL, -1				; false 'n' fall through...

IFRET:
	TEST	[IFNOTFLAG],-1
	JZ	REALTEST
	NOT	AL

REALTEST:
	OR	AL,AL
	JZ	IFTRUE
	JMP	TCOMMAND

IFTRUE:
	invoke	SCANOFF
	MOV	CX,SI
	SUB	CX,81H
	SUB	DS:[80H],CL
	MOV	CL,DS:[80H]
	MOV	[COMBUF+1],CL
	MOV	DI,OFFSET TRANGROUP:COMBUF+2
	CLD
	REP	MOVSB
	MOV	AL,0DH
	STOSB
;
; Signal that an IF was done.  This prevents the redirections from getting
; lost.
;
	PUSH	DS
	MOV	DS,ResSeg
	ASSUME	DS:RESGROUP
	MOV	IFFlag,-1
	POP	DS
	ASSUME	DS:TRANGROUP
;
; Go do the command
;
	JMP	DOCOM1

iferrorj3:
	jmp	iferrorj2

IFERLEV:
	MOV	BH,10
	XOR	BL,BL

GETNUMLP:
	LODSB
	CMP	AL,0DH
	jz	iferrorj3
	invoke	DELIM
	JZ	GOTNUM
	SUB	AL,'0'
	XCHG	AL,BL
	MUL	BH
	ADD	AL,BL
	XCHG	AL,BL
	JMP	SHORT GETNUMLP

GOTNUM:
	PUSH	DS
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	AH,BYTE PTR [RETCODE]
	POP	DS
ASSUME	DS:TRANGROUP
	XOR	AL,AL
	CMP	AH,BL
	JAE	IFRET
	DEC	AL
	JMP	SHORT IFRET


	break	<Shift - advance arguments>
assume	ds:trangroup,es:trangroup

;
; Shift the parameters in the batch structure by 1 and set up the new argument.
; This is a NOP if no batch in progress.
;

Procedure   Shift,NEAR

	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	AX,[BATCH]			; get batch pointer
	OR	AX,AX				; in batch mode?
	retz					; no, done.
	MOV	ES,AX				; operate in batch segment
	MOV	DS,AX

ASSUME	DS:NOTHING,ES:NOTHING

;
; Now move the batch args down by 1 word
;
	MOV	DI,BatParm			; point to parm table
	LEA	SI,[DI+2]			; make source = dest + 2
	MOV	CX,9				; move 9 parameters
	REP	MOVSW				; SHIFT down
;
; If the last parameter (the one not moved) is empty (= -1) then we are done.
; We have copied it into the previous position
;
	CMP	WORD PTR [DI],-1		; if last one was not in use then
	retz					; No new parm
;
; This last pointer is NOT nul.  Get it and scan to find the next argument.
; Assume, first, that there is no next argument
;
	MOV	SI,[DI]
	MOV	WORD PTR [DI],-1		; Assume no parm
;
; The parameters are CR separated.  Scan for end of this parm
;
SKIPCRLP:
	LODSB
	CMP	AL,0DH
	JNZ	SKIPCRLP
;
; We are now pointing at next arg.  If it is 0 (end of original line) then we
; are finished.  There ARE no more parms and the pointer has been previously
; initialized to indicate it.
;
	CMP	BYTE PTR [SI],0
	retz					; End of parms
	MOV	[DI],SI 			; Pointer to next parm as %9

	return

EndProc Shift

;
; Skip delim reads bytes from the batch file until a non-delimiter is seen.
; returns char in AL, carry set -> eof
;

Procedure   SkipDelim,NEAR

	ASSUME	DS:ResGroup,ES:NOTHING
	TEST	Batch,-1
	JZ	SkipErr 			; batch file empty.  OOPS!
	CALL	GetBatByt			; get a char
	invoke	Delim				; check for ignoreable chars
	JZ	SkipDelim			; ignore this char.
	clc
	return

SkipErr:
	stc
	return

EndProc SkipDelim

	break  $Call

;  CALL is an internal command that transfers control to a .bat, .exe, or
;  .com file.  This routine strips the CALL off the command line,  sets
;  the CALL_FLAG to indicate a call in progress, and returns control to
;  DOCOM1 in TCODE to reprocess the command line and execute the file
;  being CALLed.

$CALL:

;  strip off CALL from command line

	ASSUME DS:trangroup,ES:trangroup
	push	si
	push	di
	push	ax
	push	cx
	mov	si,offset trangroup:combuf+2
	invoke	scanoff 			;get to first non-delimeter
	add	si,length_call			;point to char past CALL
	mov	di,offset trangroup:combuf+2
	mov	cx,combuflen-length_call	;get length of buffer
	rep	movsb				;move it
	pop	cx
	pop	ax
	pop	di
	pop	si


;  set call flag to indicate call in progress

	push	ds
	mov	ds,[resseg]
	ASSUME DS:resgroup,ES:resgroup
	mov	call_flag, call_in_progress
	mov	call_batch_flag, call_in_progress
;
; Turn off any pipes in progress.
;
	cmp	[PIPEFILES],0			; Only turn off if present.
	jz	NoPipe
	invoke	PipeDel
NoPipe:
	pop	ds

	ret

	break	Goto

GOTO:

assume	ds:trangroup,es:trangroup
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	TEST	[BATCH],-1
	retz					; If not in batch mode, a nop
	XOR	DX,DX
	PUSH	DS
	MOV	DS,Batch
	MOV	WORD PTR DS:[BatSeek],DX	; Back to start
	MOV	WORD PTR DS:[BatSeek+2],DX	; Back to start
	POP	DS

GotoOpen:
	invoke	promptBat
	MOV	DI,FCB+1			; Get the label
	MOV	CX,11
	MOV	AL,' '
	REPNE	SCASB
	JNZ	NOINC
	INC	CX

NOINC:
	SUB	CX,11
	NEG	CX
	MOV	[GOTOLEN],CX
;
; At beginning of file.  Skip to first non-delimiter char
;
	CALL	SkipDelim
	JC	BadGoto
	CMP	AL,':'
	JZ	CHKLABEL

LABLKLP:					; Look for the label
	CALL	GETBATBYT
	CMP	AL,0AH
	JNZ	LABLKTST
;
; At beginning of line.  Skip to first non-delimiter char
;
	CALL	SkipDelim
	JC	BadGoto
	CMP	AL,':'
	JZ	CHKLABEL

LABLKTST:
	TEST	[BATCH],-1
	JNZ	LABLKLP

BadGoto:
	CALL	BATCLOSE
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET TRANGROUP:BADLAB_ptr
	JMP	CERROR

;
; Found the :.	Skip to first non-delimiter char
;

CHKLABEL:
	CALL	SkipDelim
	JC	BadGoto
	MOV	DI,FCB+1
	MOV	CX,[GOTOLEN]
	JMP	SHORT GotByte

NEXTCHRLP:
	PUSH	CX
	CALL	GETBATBYT
	POP	CX

GotByte:
	INVOKE	TESTKANJ			;AN000;  3/3/KK
	JZ	NOTKANJ1			;AN000;  3/3/KK
	CMP	AL, ES:[DI]			;AN000;  3/3/KK
	JNZ	LABLKTST			;AN000;  3/3/KK
	INC	DI				;AN000;  3/3/KK
	DEC	CX				;AN000;  3/3/KK
	JCXZ	LABLKTST			;AN000;  3/3/KK
	PUSH	CX				;AN000;  3/3/KK
	CALL	GETBATBYT			;AN000;  3/3/KK
	POP	CX				;AN000;  3/3/KK
	CMP	AL, ES:[DI]			;AN000;  3/3/KK
	JMP	SHORT KNEXTLABCHR		;AN000;  3/3/KK

NOTKANJ1:					;AN000;  3/3/KK
	OR	AL,20H
	CMP	AL,ES:[DI]
	JNZ	TRYUPPER
	JMP	SHORT NEXTLABCHR

TRYUPPER:
	SUB	AL,20H
	CMP	AL,ES:[DI]

KNEXTLABCHR:					;AN000;  3/3/KK
	JNZ	LABLKTST

NEXTLABCHR:
	INC	DI
	LOOP	NEXTCHRLP
	CALL	GETBATBYT
	cmp	[GOTOLEN],8			; Is the label atleast 8 chars long?
	jge	gotocont			; Yes, then the next char doesn't matter
	CMP	AL,' '
	JA	LABLKTST

gotocont:
	CMP	AL,0DH
	JZ	SKIPLFEED

TONEXTBATLIN:
	CALL	GETBATBYT
	CMP	AL,0DH
	JNZ	TONEXTBATLIN

SKIPLFEED:
	CALL	GETBATBYT
	CALL	BatClose

	return

Procedure   BatClose,NEAR

	MOV	BX,CS:[BATHAND]
	CMP	BX,5
	JB	CloseReturn
	MOV	AH,CLOSE
	INT	int_command

CloseReturn:
	mov	byte ptr [In_Batch],0		; reset flag
	return

EndProc BatClose

;
; Open the BATCH file, If open fails, AL is drive of batch file (A=1)
; Also, fills internal batch buffer.  If access denied, then AX = -1
;

Procedure   BatOpen,NEAR

ASSUME	DS:RESGROUP,ES:TRANGROUP

	PUSH	DS
	MOV	DS,[BATCH]
ASSUME	DS:NOTHING

	MOV	DX,BatFile
	MOV	AX,OPEN SHL 8
	INT	int_command			; Open the batch file
	JC	SETERRDL
	MOV	DX,WORD PTR DS:[BatSeek]
	MOV	CX,WORD PTR DS:[BatSeek+2]
	POP	DS
ASSUME	DS:RESGROUP

	MOV	[BATHAND],AX
	MOV	BX,AX
	MOV	AX,LSEEK SHL 8			; Go to the right spot
	INT	int_command
	MOV	BatBufPos,-1			; nuke batch buffer position

	return

SETERRDL:
	MOV	BX,DX
	invoke	get_ext_error_number		;AN022; get the extended error
	mov	dx,ax				;AN022; save extended error in DX
	MOV	AL,[BX] 			; Get drive spec
	SUB	AL,'@'                          ; A = 1
	POP	DS
	STC					; SUB mucked over carry

	return

EndProc BatOpen


TRANCODE    ENDS
	    END
