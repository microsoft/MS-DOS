	PAGE	60,132 ;
	TITLE	DEBCOM1.ASM - PART1 DEBUGGER COMMANDS	PC DOS
;======================= START OF SPECIFICATIONS =========================
;
; MODULE NAME: DECOM1.SAL
;
; DESCRIPTIVE NAME: DEBUGGING TOOL
;
; FUNCTION: PROVIDES USERS WITH A TOOL FOR DEBUGGING PROGRAMS.
;
; ENTRY POINT: ANY CALLED ROUTINE
;
; INPUT: NA
;
; EXIT NORMAL: NA
;
; EXIT ERROR: NA
;
; INTERNAL REFERENCES:
;
; EXTERNAL REFERENCES:
;
;	ROUTINE: DEBCOM2 - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBCOM3 - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBASM  - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBUASM - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBMES  - CONTAINS ROUTINES CALLED BY DEBUG
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK DEBUG+DEBCOM1+DEBCOM2+DEBCOM3+DEBASM+DEBUASM+DEBERR+
;	      DEBCONST+DEBDATA+DEBMES
;
; REVISION HISTORY:
;
;	AN000	VERSION 4.00 - REVISIONS MADE RELATE TO THE FOLLOWING:
;
;				- IMPLEMENT DBCS HANDLING	DMS:6/17/87
;				- IMPLEMENT MESSAGE RETRIEVER	DMS:6/17/87
;				- IMPLEMENT > 32MB SUPPORT	DMS:6/17/87
;
; COPYRIGHT: "MS DOS DEBUG UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988 Microsoft"
;	     "LICENSED MATERIAL - PROPERTY OF Microsoft  "
;
;======================= END OF SPECIFICATIONS ===========================

; Routines to perform debugger commands except ASSEMble and UASSEMble

	IF1
	    %OUT COMPONENT=DEBUG, MODULE=DEBCOM1
	ENDIF
.XLIST
.XCREF
	INCLUDE DOSSYM.INC
	INCLUDE DEBEQU.ASM
.CREF
.LIST

CODE	SEGMENT PUBLIC BYTE
CODE	ENDS

CONST	SEGMENT PUBLIC BYTE
	EXTRN	SYNERR_PTR:BYTE
	EXTRN	DISPB:WORD,DSIZ:BYTE,DSSAVE:WORD
	IF	SYSVER
	    EXTRN   CIN:DWORD,PFLAG:BYTE
	ENDIF
CONST	ENDS

CSTACK	SEGMENT STACK
CSTACK	ENDS

DATA	SEGMENT PUBLIC BYTE
	EXTRN	DEFLEN:WORD,BYTEBUF:BYTE,DEFDUMP:BYTE
	EXTRN	ARG_BUF:BYTE,ARG_BUF_PTR:BYTE
	EXTRN	ONE_CHAR_BUF:BYTE,ONE_CHAR_BUF_PTR:WORD
DATA	ENDS

DG	GROUP	CODE,CONST,CSTACK,DATA

CODE	SEGMENT PUBLIC BYTE
ASSUME	CS:DG,DS:DG,ES:DG,SS:DG
	PUBLIC	HEXCHK,GETHEX1,PRINT,DSRANGE,ADDRESS,HEXIN,PERROR
	PUBLIC	GETHEX,GET_ADDRESS,GETEOL,GETHX,PERR
	PUBLIC	PERR,MOVE,DUMP,ENTERDATA,FILL,SEARCH,DEFAULT
	IF	SYSVER
	    PUBLIC  IN
	    EXTRN   DISPREG:NEAR,DEVIOCALL:NEAR
	ENDIF
	EXTRN	CRLF:NEAR,OUTDI:NEAR,OUTSI:NEAR,SCANP:NEAR
	EXTRN	SCANB:NEAR,BLANK:NEAR,TAB:NEAR,COMMAND:NEAR
	EXTRN	HEX:NEAR,BACKUP:NEAR
	EXTRN	PRINTF_CRLF:NEAR,HEX_ADDRESS_ONLY:NEAR,HEX_ADDRESS_STR:NEAR
	EXTRN	STD_PRINTF:NEAR
DEBCOM1:
; RANGE - Looks for parameters defining an address range.
; The first parameter is the starting address. The second parameter
; may specify the ending address, or it may be preceded by
; "L" and specify a length (4 digits max), or it may be
; omitted and a length of 128 bytes is assumed. Returns with
; segment in AX, displacement in DX, and length in CX.
DSRANGE:
	MOV	BP,[DSSAVE]		; Set default segment to DS
	MOV	[DEFLEN],128		; And default length to 128 bytes
RANGE:
	CALL	ADDRESS

	PUSH	AX			; Save segment
	PUSH	DX			; Save offset
	CALL	SCANP			; Get to next parameter

	MOV	AL,[SI]
	CMP	AL,UPPER_L		; Length indicator?
	JE	GETLEN

	MOV	DX,[DEFLEN]		; Default length
	CALL	HEXIN			; Second parameter present?

	JC	GETDEF			; If not, use default

	MOV	CX,4
	CALL	GETHEX			; Get ending address (same segment)

	MOV	CX,DX			; Low 16 bits of ending addr.
	POP	DX			; Low 16 bits of starting addr.
	SUB	CX,DX			; Compute range
	JAE	DSRNG2

DSRNG1:
	JMP	PERROR			; Negative range
DSRNG2:
	INC	CX			; Include last location
;	JCXZ	DSRNG1			; Wrap around error
;	Removing this instruction allows 0 FFFF to valid range
	POP	AX			; Restore segment
	RET
GETDEF:
	POP	CX			; get original offset
	PUSH	CX			; save it
	NEG	CX			; rest of segment
	JZ	RNGRET			; use default

	CMP	CX,DX			; more room in segment?
	JAE	RNGRET			; yes, use default

	JMP	RNGRET1 		; no, length is in CX

GETLEN:
	INC	SI			; Skip over "L" to length
	MOV	CX,4			; Length may have 4 digits
	CALL	GETHEX			; Get the range

RNGRET:
	MOV	CX,DX			; Length
RNGRET1:
	POP	DX			; Offset
	MOV	AX,CX
	ADD	AX,DX
	JNC	OKRET

	CMP	AX,1
	JAE	DSRNG1			; Look for wrap error

OKRET:
	POP	AX			; Segment
	RET
DEFAULT:
; DI points to default address and CX has default length
	CALL	SCANP

	JZ	USEDEF			; Use default if no parameters

	MOV	[DEFLEN],CX
	CALL	RANGE

	JMP	GETEOL

USEDEF:
	MOV	SI,DI
	LODSW				; Get default displacement
	MOV	DX,AX
	LODSW				; Get default segment
	RET

; Dump an area of memory in both hex and ASCII
DUMP:
	MOV	BP,[DSSAVE]
	MOV	CX,DISPB
	MOV	DI,OFFSET DG:DEFDUMP
	CALL	DEFAULT 		; Get range if specified

	MOV	DS,AX			; Set segment
	ASSUME	DS:NOTHING

	MOV	SI,DX			; SI has displacement in segment
	PUSH	SI			; save SI away
	MOV	AL,DSIZ
	XOR	AH,AH
	XOR	AX,-1
	AND	SI,AX			; convert to para number
	MOV	DI,OFFSET DG:ARG_BUF	; Build the output str in arg_buf
	CALL	OUTSI			; display location

	POP	SI			; get SI back
; Determine where the registers display should begin.
	MOV	AX,SI			; move offset
	MOV	AH,3			; spaces per byte
	AND	AL,DSIZ 		; convert to real offset
	MUL	AH			; 3 char positions per byte of output
	OR	AL,AL			; at beginning?
	JZ	INROW			; if so, then no movement.

	PUSH	CX
	MOV	CX,AX
	CALL	TAB

	POP	CX
INROW:
	PUSH	SI			; Save address for ASCII dump
BYTE0:
	CALL	BLANK			; Space between bytes
BYTE1:
	LODSB				; Get byte to dump
	CALL	HEX			; and display it

	POP	DX			; DX has start addr. for ASCII dump
	DEC	CX			; Drop loop count
	JZ	ASCII			; If through do ASCII dump

	MOV	AX,SI
	TEST	AL,DSIZ 		; On row boundary?
	JZ	ENDROW

	PUSH	DX			; Didn't need ASCII addr. yet
	TEST	AL,7			; On 8-byte boundary?
	JNZ	BYTE0

	MOV	AL,CHAR_MINUS		; Mark every 8 bytes with "-"
	STOSB
	JMP	SHORT BYTE1

ENDROW:
	CALL	ASCII			; Show it in ASCII

	MOV	DI,OFFSET DG:ARG_BUF	; Build the output str in arg_buf
	CALL	OUTSI			; Get the address at start of line

	JMP	INROW			; Loop until count is zero

; Produce a dump of the ascii text characters.	We take the current SI which
; contains the byte after the last one dumped.	From this we determine how
; many spaces we need to output to get to the ascii column.  Then we look at
; the beginning address of the dump to tsee how many spaces we need to indent.
ASCII:
	PUSH	CX			; Save count of remaining bytes
; Determine how many spaces to go until the ASCII column.
	MOV	AX,SI			; get offset of next byte
	DEC	AL
	AND	AL,DSIZ
	INC	AL
; AX now has the number of bytes that we have displayed:  1 to Dsiz+1.
; Compute characters remaining to be displayed.  We *always* put the ASCII
; dump in column 51 (or whereever)
	SUB	AL,10H			; get negative of number
	DEC	AL			;
	NEG	AL			; convert to positive
	CBW				; convert to word
; 3 character positions for each byte displayed.
	MOV	CX,AX
	SHL	AX,1
	ADD	CX,AX
; Compute indent for ascii dump
	MOV	AX,DX
	AND	AL,DSIZ
	XOR	AH,AH
	ADD	CX,AX
; Tab over
	CALL	TAB

; Set up for true dump
	MOV	CX,SI
	MOV	SI,DX
	SUB	CX,SI
ASCDMP:
	LODSB				; Get ASCII byte to dump
	CMP	AL,CHAR_RUBOUT
	JAE	NOPRT			; Don't print RUBOUT or above

	CMP	AL,CHAR_BLANK
	JAE	PRIN			; print space through RUBOUT-1

NOPRT:
	MOV	AL,CHAR_PERIOD		; If unprintable character
PRIN:
	STOSB
	LOOP	ASCDMP			; CX times
	MOV	AL,0
	STOSB
	PUSH	DS
	PUSH	CS
	POP	DS
	ASSUME	DS:DG

	CALL	HEX_ADDRESS_STR

	CALL	CRLF

	POP	DS
	ASSUME	DS:NOTHING

	POP	CX			; Restore overall dump len
	MOV	WORD PTR [DEFDUMP],SI
	MOV	WORD PTR [DEFDUMP+WORD],DS ; Save last address as def
	RET

	ASSUME	DS:DG
; Block move one area of memory to another Overlapping moves are performed
; correctly, i.e., so that a source byte is not overwritten until after it has
; been moved.
MOVE:
	CALL	DSRANGE 		; Get range of source area

	PUSH	CX			; Save length
	PUSH	AX			; Save segment
	PUSH	DX			; Save source displacement
	CALL	ADDRESS 		; Get destination address (sam

	CALL	GETEOL			; Check for errors

	POP	SI
	MOV	DI,DX			; Set dest. displacement
	POP	BX			; Source segment
	MOV	DS,BX
	MOV	ES,AX			; Destination segment
	POP	CX			; Length
	CMP	DI,SI			; Check direction of move
	SBB	AX,BX			; Extend the CMP to 32 bits
	JB	COPYLIST		; Move forward into lower mem.

; Otherwise, move backward. Figure end of source and destination
; areas and flip direction flag.
	DEC	CX
	ADD	SI,CX			; End of source area
	ADD	DI,CX			; End of destination area
	STD				; Reverse direction
	INC	CX
COPYLIST:
	MOVSB				; Do at least 1 - Range is 1-1
	DEC	CX
	REP	MOVSB			; Block move
RET1:
	RET

; Fill an area of memory with a list values. If the list
; is bigger than the area, don't use the whole list. If the
; list is smaller, repeat it as many times as necessary.
FILL:
	CALL	DSRANGE 		; Get range to fill

	PUSH	CX			; Save length
	PUSH	AX			; Save segment number
	PUSH	DX			; Save displacement
	CALL	LIST			; Get list of values to fill w

	POP	DI			; Displacement in segment
	POP	ES			; Segment
	POP	CX			; Length
	CMP	BX,CX			; BX is length of fill list
	MOV	SI,OFFSET DG:BYTEBUF	; List is in byte buffer
	JCXZ	BIGRNG

	JAE	COPYLIST		; If list is big, copy part of

BIGRNG:
	SUB	CX,BX			; How much bigger is area than
	XCHG	CX,BX			; CX=length of list
	PUSH	DI			; Save starting addr. of area
	REP	MOVSB			; Move list into area
	POP	SI
; The list has been copied into the beginning of the
; specified area of memory. SI is the first address
; of that area, DI is the end of the copy of the list
; plus one, which is where the list will begin to repeat.
; All we need to do now is copy [SI] to [DI] until the
; end of the memory area is reached. This will cause the
; list to repeat as many times as necessary.
	MOV	CX,BX			; Length of area minus list
	PUSH	ES			; Different index register
	POP	DS			; requires different segment r
	JMP	SHORT COPYLIST		; Do the block move

; Search a specified area of memory for given list of bytes.
; Print address of first byte of each match.
SEARCH:
	CALL	DSRANGE 		; Get area to be searched

	PUSH	CX			; Save count
	PUSH	AX			; Save segment number
	PUSH	DX			; Save displacement
	CALL	LIST			; Get search list

	DEC	BX			; No. of bytes in list-1
	POP	DI			; Displacement within segment
	POP	ES			; Segment
	POP	CX			; Length to be searched
	SUB	CX,BX			;  minus length of list
SCAN:
	MOV	SI,OFFSET DG:BYTEBUF	; List kept in byte buffer
	LODSB				; Bring first byte into AL
DOSCAN:
	SCASB				; Search for first byte
	LOOPNE	DOSCAN			; Do at least once by using LO

	JNZ	RET1			; Exit if not found

	PUSH	BX			; Length of list minus 1
	XCHG	BX,CX
	PUSH	DI			; Will resume search here
	REPE	CMPSB			; Compare rest of string
	MOV	CX,BX			; Area length back in CX
	POP	DI			; Next search location
	POP	BX			; Restore list length
	JNZ	TTEST			 ; Continue search if no match

	DEC	DI			; Match address
	CALL	OUTDI			; Print it

	INC	DI			; Restore search address
	CALL	HEX_ADDRESS_ONLY	; Print the addresss

	CALL	CRLF

TTEST:
	JCXZ	RET1

	JMP	SHORT SCAN		; Look for next occurrence

; Get the next parameter, which must be a hex number.
; CX is maximum number of digits the number may have.

;=========================================================================
; GETHX: This routine calculates the binary representation of an address
;	 entered in ASCII by a user.  GETHX has been modified to provide
;	 support for sector addresses > 32mb.  To do this the bx register
;	 has been added to provide a 32 bit address.  BX is the high word
;	 and DX is the low word.  For routines that rely on DX for a 16
;	 bit address, the use of BX will have no effect.
;
;	Date	   : 6/16/87
;=========================================================================

GETHX:
	CALL	SCANP
GETHX1:
	XOR	DX,DX			; Initialize the number
	xor	bx,bx			;an000;initialize high word for
					;      sector address
	CALL	HEXIN			; Get a hex digit

	JC	HXERR			; Must be one valid digit

	MOV	DL,AL			; First 4 bits in position
GETLP:
	INC	SI			; Next char in buffer
	DEC	CX			; Digit count
	CALL	HEXIN			; Get another hex digit?

	JC	RETHX			; All done if no more digits

	STC
	JCXZ	HXERR			; Too many digits?


	call	ADDRESS_32_BIT		;an000;multiply by 32
	JMP	SHORT GETLP		; Get more digits

GETHEX:
	CALL	GETHX			; Scan to next parameter

	JMP	SHORT GETHX2

GETHEX1:
	CALL	GETHX1
GETHX2:
	JC	PERROR
RETHX:
	CLC
HXERR:
	RET

; Check if next character in the input buffer is a hex digit
; and convert it to binary if it is. Carry set if not.
HEXIN:
	MOV	AL,[SI]
; Check if AL  is a hex digit and convert it to binary if it
; is. Carry set if not.
HEXCHK:
	SUB	AL,CHAR_ZERO		; Kill ASCII numeric bias
	JC	RET2

	CMP	AL,10
	CMC
	JNC	RET2			; OK if 0-9

	AND	AL,5FH
	SUB	AL,7			; Kill A-F bias
	CMP	AL,10
	JC	RET2

	CMP	AL,16
	CMC
RET2:
	RET

; Process one parameter when a list of bytes is
; required. Carry set if parameter bad. Called by LIST.
LISTITEM:
	CALL	SCANP			; Scan to parameter

	CALL	HEXIN			; Is it in hex?

	JC	STRINGCHK		; If not, could be a string

	MOV	CX,2			; Only 2 hex digits for bytes
	push	bx			;an000;save it - we stomp it
	CALL	GETHEX			; Get the byte value
	pop	bx			;an000;restore it

	MOV	[BX],DL 		; Add to list
	INC	BX
GRET:
	CLC				; Parameter was OK
	RET

STRINGCHK:
	MOV	AL,[SI] 		; Get first character of param
	CMP	AL,SINGLE_QUOTE 	; String?
	JZ	STRING

	CMP	AL,DOUBLE_QUOTE 	; Either quote is all right
	JZ	STRING

	STC				; Not string, not hex - bad
	RET
STRING:
	MOV	AH,AL			; Save for closing quote
	INC	SI
STRNGLP:
	LODSB				; Next char of string
	CMP	AL,CR			; Check for end of line
	JZ	PERR			; Must find a close quote

	CMP	AL,AH			; Check for close quote
	JNZ	STOSTRG 		; Add new character to list

	CMP	AH,[SI] 		; Two quotes in a row?
	JNZ	GRET			; If not, we're done

	INC	SI			; Yes - skip second one
STOSTRG:
	MOV	[BX],AL 		; Put new char in list
	INC	BX
	JMP	SHORT STRNGLP		; Get more characters

; Get a byte list for ENTER, FILL or SEARCH. Accepts any number
; of 2-digit hex values or character strings in either single
; (') or double (") quotes.
LIST:
	MOV	BX,OFFSET DG:BYTEBUF	; Put byte list in the byte buffer
LISTLP:
	CALL	LISTITEM		; Process a parameter

	JNC	LISTLP			; If OK, try for more

	SUB	BX,OFFSET DG:BYTEBUF	; BX now has no. of bytes in list
	JZ	PERROR			; List must not be empty

; Make sure there is nothing more on the line except for
; blanks and carriage return. If there is, it is an
; unrecognized parameter and an error.
GETEOL:
	CALL	SCANB			; Skip blanks

	JNZ	PERROR			; Better be a RETURN
RET3:
	RET

; Command error.  SI has been incremented beyond the command letter so it must
; decremented for the error pointer to work.
PERR:
	DEC	SI
; Syntax error.  SI points to character in the input buffer which caused
; error.  By subtracting from start of buffer, we will know how far to tab
; over to appear directly below it on the terminal.  Then print "^ Error".
PERROR:
	SUB	SI,OFFSET DG:(BYTEBUF-1) ; How many char processed so far?
	MOV	CX,SI			; Parameter for TAB in CX
	MOV	DI,OFFSET DG:ARG_BUF	;
	CALL	TAB			; Directly below bad char

	MOV	BYTE PTR [DI],0 	; nul terminate the tab
	MOV	DX,OFFSET DG:SYNERR_PTR ; Error message
; Print error message and abort to command level
PRINT:
	CALL	PRINTF_CRLF

	JMP	COMMAND

; Gets an address in Segment:Displacement format. Segment may be omitted
; and a default (kept in BP) will be used, or it may be a segment
; register (DS, ES, SS, CS). Returns with segment in AX, OFFSET in DX.
ADDRESS:
	CALL	GET_ADDRESS

	JC	PERROR

ADRERR:
	STC
	RET

GET_ADDRESS:
	CALL	SCANP

	MOV	AL,[SI+1]
	CMP	AL,UPPER_S
	JZ	SEGREG

	MOV	CX,4
	CALL	GETHX

	JC	ADRERR

	MOV	AX,BP			; Get default segment
	CMP	BYTE PTR [SI],CHAR_COLON
	JNZ	GETRET

	PUSH	DX
GETDISP:
	INC	SI			; Skip over ":"
	MOV	CX,4
	CALL	GETHX

	POP	AX
	JC	ADRERR

GETRET:
	CLC
	RET

SEGREG:
	MOV	AL,[SI]
	MOV	DI,OFFSET DG:SEGLET	; SEGLET  DB  "CSED"
	MOV	CX,4
	REPNE	SCASB
	JNZ	ADRERR

	INC	SI
	INC	SI
	SHL	CX,1
	MOV	BX,CX
	CMP	BYTE PTR [SI],CHAR_COLON
	JNZ	ADRERR

	PUSH	[BX+DSSAVE]
	JMP	SHORT GETDISP

SEGLET	DB	"CSED"			; First letter of each of the segregs: CS,SS,ES,DS

; Short form of ENTER command. A list of values from the
; command line are put into memory without using normal
; ENTER mode.
GETLIST:
	CALL	LIST			; Get the bytes to enter

	POP	DI			; Displacement within segment
	POP	ES			; Segment to enter into
	MOV	SI,OFFSET DG:BYTEBUF	; List of bytes is in byte buffer
	MOV	CX,BX			; Count of bytes
	REP	MOVSB			; Enter that byte list
	RET

; Enter values into memory at a specified address.  If the line contains
; nothing but the address we go into "enter mode", where the address and its
; current value are printed and the user may change it if desired.  To change,
; type in new value in hex.  Backspace works to correct errors.  If an illegal
; hex digit or too many digits are typed, the bell is sounded but it is
; otherwise ignored.  To go to the next byte (with or without change), hit
; space bar.  To back CLDto a previous address, type "-".  On every 8-byte
; boundary a new line is started and the address is printed.  To terminate
; command, type carriage return.
;  Alternatively, the list of bytes to be entered may be included on the
; original command line immediately following the address.  This is in regular
; LIST format so any number of hex values or strings in quotes may be entered.
ENTERDATA:
	MOV	BP,[DSSAVE]		; Set default segment to DS
	CALL	ADDRESS

	PUSH	AX			; Save for later
	PUSH	DX
	CALL	SCANB			; Any more parameters?

	JNZ	GETLIST 		; If not end-of-line get list

	POP	DI			; Displacement of ENTER
	POP	ES			; Segment
GETROW:
	CALL	OUTDI			; Print address of entry

	PUSH	DI
	PUSH	ES
	PUSH	DS
	POP	ES
	MOV	DI,OFFSET DG:ARG_BUF
	CALL	BLANK

	XOR	AL,AL
	STOSB
	CALL	HEX_ADDRESS_STR

	POP	ES
	POP	DI
GETBYTE:
	MOV	AL,ES:[DI]		; Get current value
	PUSH	DI
	PUSH	ES
	PUSH	DS
	POP	ES
	MOV	DI,OFFSET DG:ARG_BUF
	CALL	HEX			; And display it

	MOV	AL,CHAR_PERIOD
	STOSB
	XOR	AL,AL
	STOSB
	MOV	DX,OFFSET DG:ARG_BUF_PTR
	CALL	STD_PRINTF

	POP	ES
	POP	DI
LOOK_AGAIN:
	MOV	CX,2			; Max of 2 digits in new value
	MOV	DX,0			; Intial new value
GETDIG:
	CALL	INPT			; Get digit from user

	MOV	AH,AL			; Save
	CALL	HEXCHK			; Hex digit?

	XCHG	AH,AL			; Need original for echo
	JC	NOHEX			; If not, try special command

	MOV	DH,DL			; Rotate new value
	MOV	DL,AH			; And include new digit
	LOOP	GETDIG			; At most 2 digits

; We have two digits, so all we will accept now is a command.
DWAIT:
	CALL	INPT			; Get command character
NOHEX:
	CMP	AL,CHAR_BACKSPACE	; Backspace
	JZ	BS

	CMP	AL,CHAR_RUBOUT		; RUBOUT
	JZ	RUB

	CMP	AL,CHAR_MINUS		; Back up to previous address
	JZ	PREV

	CMP	AL,CR			; All done with command?
	JZ	EOL

	CMP	AL,CHAR_BLANK		; Go to next address
	JZ	NEXT

	MOV	AL,CHAR_BACKSPACE
	CALL	OUT_CHAR		; Back up over illegal character

	CALL	BACKUP

	JCXZ	DWAIT

	JMP	SHORT GETDIG

RUB:
	MOV	AL,CHAR_BACKSPACE
	CALL	OUT_char
BS:
	CMP	CL,2			; CX=2 means nothing typed yet
	JZ	PUTDOT			; Put back the dot we backed up over

	INC	CL			; Accept one more character
	MOV	DL,DH			; Rotate out last digit
	MOV	DH,CH			; Zero this digit
	CALL	BACKUP			; Physical backspace

	JMP	SHORT GETDIG		; Get more digits

PUTDOT:
	MOV	AL,CHAR_PERIOD
	CALL	OUT_CHAR

	JMP	LOOK_AGAIN

; If new value has been entered, convert it to binary and
; put into memory. Always bump pointer to next location
STORE:
	CMP	CL,2			; CX=2 means nothing typed yet
	JZ	NOSTO			; So no new value to store

; Rotate DH left 4 bits to combine with DL and make a byte value
	PUSH	CX
	MOV	CL,4
	SHL	DH,CL
	POP	CX
	OR	DL,DH			; Hex is now converted to binary
	MOV	ES:[DI],DL		; Store new value
NOSTO:
	INC	DI			; Prepare for next location
	RET

NEXT:
	CALL	STORE			; Enter new value

	INC	CX			; Leave a space plus two for
	INC	CX			;  each digit not entered
	PUSH	DI
	MOV	DI,OFFSET DG:ARG_BUF
	PUSH	ES
	PUSH	DS
	POP	ES
	CALL	TAB

	XOR	AL,AL
	STOSB
	MOV	DX,OFFSET DG:ARG_BUF_PTR
	CALL	STD_PRINTF

	POP	ES
	POP	DI
	MOV	AX,DI			; Next memory address
	AND	AL,7			; Check for 8-byte boundary
	JZ	NEWROW			; Take 8 per line

	JMP	GETBYTE

NEWROW:
	CALL	CRLF			; Terminate line

	JMP	GETROW			; Print address on new line

PREV:
	CALL	STORE			; Enter the new value

; DI has been bumped to next byte. Drop it 2 to go to previous addr
	DEC	DI
	DEC	DI
	JMP	SHORT NEWROW		; Terminate line after backing	 CLD

EOL:
	CALL	STORE			; Enter the new value

	JMP	CRLF			; CR/LF and terminate

; Console input of single character
	IF	SYSVER
INPT:					  ;*** change for build - label to inpt
	    PUSH    DS
	    PUSH    SI
	    LDS     SI,CS:[CIN]
	    MOV     AH,4
	    CALL    DEVIOCALL

	    POP     SI
	    POP     DS
	    CMP     AL,3
	    JNZ     NOTCNTC

	    INT     VEC_CTRL_BREAK	;23H

NOTCNTC:
	    CMP     AL,UPPER_P - CHAR_AT_SIGN
	    JZ	    PRINTON

	    CMP     AL,UPPER_N - CHAR_AT_SIGN
	    JZ	    PRINTOFF

	    CALL    OUT_CHAR

	    RET

PRINTOFF:
PRINTON:
	    NOT     [PFLAG]
	    JMP     SHORT IN

	ELSE
INPT:				; Change label for build
	    MOV     AH,Std_Con_Input ;OPTION=1, STANDARD CONSOLE INPUT
	    INT     21H

	    RET

	ENDIF
OUT_CHAR:
	PUSH	DI
	PUSH	DX
	PUSH	ES
	PUSH	DS
	POP	ES
	MOV	DI,OFFSET DG:ONE_CHAR_BUF
	STOSB
	MOV	AL,0
	STOSB
	MOV	DX,OFFSET DG:ONE_CHAR_BUF_PTR
	CALL	STD_PRINTF

	POP	ES
	POP	DX
	POP	DI
	RET

;=========================================================================
; ADDRESS_32_BIT: This routine will build an address for 32bit sector
;		  addressibility.  BX will be the high word, with DX being
;		  the low word.
;
;	Inputs : DX/BX - registers to contain 32bit sector address
;		 DX & BX are both initialized to 0 on first call to routine.
;
;	Outputs: DX/BX - registers to contain 32bit sector address
;
;	Date	  : 6/16/87
;=========================================================================

ADDRESS_32_BIT	proc	near			;an000;perform 32 bit address
						;      creation
	push	cx				;an000;save affected regs.
	mov	cx,04h				;an000;initialize to
						;      nibble shift
;	$do					;an000;while cx not= 0
$$DO1:
		cmp	cx,00h			;an000;are we done?
;		$leave	e			;an000;yes, quit loop
		JE $$EN1
		shl	bx,1			;an000;shift bx 1 bit
		shl	dx,1			;an000;shift dx 1 bit
;		$if	c			;an000;did low word carry
		JNC $$IF3
			or	bx,01h		;an000;set bit 0 of high word
;		$endif				;an000;
$$IF3:
		dec	cx			;an000;decrease counter
;	$enddo					;an000;end while loop
	JMP SHORT $$DO1
$$EN1:
	or	dl,	al			;an000;overlay low word
						;      bits 0-3 with next
						;      portion of the address
	pop	cx				;an000;restore affected regs.

	ret					;an000;return to caller

ADDRESS_32_BIT	endp				;an000;end proc



CODE	ENDS
	END	DEBCOM1
