;	SCCSID = @(#)strin.asm	1.2 85/04/18
;
;	Revision history:
;	   A000  version 4.00   Jan. 1988
;
Break

; Inputs:
;	DS:DX Point to an input buffer
; Function:
;	Fill buffer from console input until CR
; Returns:
;	None

	procedure   $STD_CON_STRING_INPUT,NEAR	 ;System call 10
ASSUME	DS:NOTHING,ES:NOTHING

	MOV	AX,SS
	MOV	ES,AX
	MOV	SI,DX
	XOR	CH,CH
	LODSW
	mov	cs:Temp_Var,si	 ;AN000;   ; 3/31/KK
;
; AL is the buffer length
; AH is the template length
;
	OR	AL,AL
	retz			;Buffer is 0 length!!?
	MOV	BL,AH		;Init template counter
	MOV	BH,CH		;Init template counter
 ;
 ; BL is the number of bytes in the template
 ;
	CMP	AL,BL
	JBE	NOEDIT		;If length of buffer inconsistent with contents
	CMP	BYTE PTR [BX+SI],c_CR
	JZ	EDITON		;If CR correctly placed EDIT is OK
;
; The number of chars in the template is >= the number of chars in buffer or
; there is no CR at the end of the template.  This is an inconsistant state
; of affairs.  Pretend that the template was empty:
;
NOEDIT:
	MOV	BL,CH		;Reset buffer
EDITON:
	MOV	DL,AL
	DEC	DX		;DL is # of bytes we can put in the buffer
;
; Top level.  We begin to read a line in.
;
NEWLIN:
	MOV	AL,[CARPOS]
	MOV	[STARTPOS],AL	;Remember position in raw buffer
	PUSH	SI
	MOV	DI,OFFSET DOSGROUP:INBUF	;Build the new line here
	MOV	[INSMODE],CH	;Insert mode off
	MOV	BH,CH		;No chars from template yet
	MOV	DH,CH		;No chars to new line yet
	call	IntCNE0 	;AN000; Get first char			 2/17/KK
	jz	SavCh		;AN000; if ZF set then interim character 2/17/KK
	CMP	AL,c_LF 	;Linefeed
	JNZ	GOTCH		;Filter out LF so < works
;
; This is the main loop of reading in a character and processing it.
;
;   BH is the index of the next byte in the template
;   BL is the length of the template
;   DH is the number of bytes in the buffer
;   DL is the length of the buffer
;
entry	GETCH
	call	IntCNE0 	;AN000;; 2/17/KK
	jz	SavCh		;AN000;; if ZF set then interim character 2/17/KK
GOTCH:
;
; ^F ignored in case BIOS did not flush the input queue.
;
	CMP	AL,"F"-"@"
	JZ	GETCH
;
; If the leading char is the function-key lead byte
;
	CMP	AL,[ESCCHAR]
	JNZ	ARM03		;AN000;; 2/17/KK
	Jmp	ESCC		;AN000;; 2/17/KK
ARM03:				;AN000;; 2/17/KK
;
; Rubout and ^H are both destructive backspaces.
;
	CMP	AL,c_DEL
	JZ	BACKSPJ0	;AN000; 2/17/KK
	CMP	AL,c_BS
	JNZ	ARM04		;AN000;; 2/17/KK
BACKSPJ0:			;AN000;; 2/17/KK
	Jmp	BACKSPJ 	;AN000;; 2/17/KK
ARM04:				;AN000;; 2/17/KK
;
; ^W deletes backward once and then backs up until a letter is before the
; cursor
;
	CMP	AL,"W" - "@"
; The removal of the comment characters before the jump statement will
; cause ^W to backup a word.
;***	JZ	WordDel
	NOP
	NOP
	CMP	AL,"U" - "@"
; The removal of the comment characters before the jump statement will
; cause ^U to clear a line.
;***	JZ	LineDel
	NOP
	NOP

;
; CR terminates the line.
;
	CMP	AL,c_CR
	JNZ	ARM01		;AN000;; 2/17/KK
	Jmp	ENDLIN		;AN000;; 2/17/KK
ARM01:				;AN000;; 2/17/KK
;
; LF goes to a new line and keeps on reading.
;
	CMP	AL,c_LF
	JNZ	ARM00		;AN000;; 2/17/KK
	Jmp	PHYCRLF 	;AN000;; 2/17/KK
ARM00:				;AN000;; 2/17/KK
;
; ^X (or ESC) deletes the line and starts over
;
	CMP	AL,[CANCHAR]
	JNZ	SAVCH		;AN000;; 2/13/KK
	JMP	KILNEW		;AN000;; 2/13/KK
InterLoop:			;AN000;; 2/17/KK
	call	IntCNE0 	;AN000;; Get another interim character 2/17/KK
;
; Otherwise, we save the input character.
;
SAVCH:
	pushf			;AN000; 2/17/KK
	CMP	DH,DL
	JAE	BUFFUL			; buffer is full.
;----------------------------- Start of DBCS 2/13/KK

	invoke	TESTKANJ		;AN000;
	JZ	ISNORM			;AN000;
	INC	DH			;AN000;
	CMP	DH,DL			;AN000;
	JB	GOTROOM 		;AN000;
	DEC	DH			;AN000;; No room for second byte
	call	IntCNE0 		;AN000;; Get second byte
	JMP	SHORT BUFFUL		;AN000;
					;AN000;
GOTROOM:				;AN000;
	STOSB				;AN000;; Store first byte
	popf				;AN000;
	call	outchax 		;AN000;
	call	IntCNE0 		;AN000;; Get second byte
	pushf				;AN000;
	STOSB				;AN000;; Store second byte
	INC	DH			;AN000;
	popf				;AN000;
	call	outchax 		;AN000;
	jnz	ContIn1 		;AN000;; interim character?
	call	InterCheck		;AN000;
	call	InterCheck		;AN000;
	jmp	short InterLoop 	;AN000;; not interim skip another check

ISNORM:
;----------------------------- End of DBCS 2/13/KK
	STOSB				;AN000;
	INC	DH			;AN000;; increment count in buffer.
	popf				;AN000;; 2/17/KK
	invoke	BUFOUTx 		;AN000;; Print control chars nicely 2/17/KK
	jnz	ContIn1 		;AN000;; 2/17/KK
	call	InterCheck		;AN000;; 2/17/KK
	jmp	short InterLoop 	;AN000;; 2/17/KK
CONTIN1:				;AN000;; 2/13/KK
;;;CONTIN:				;AN000;; 2/13/KK
	CMP	BYTE PTR [INSMODE],0
	JNZ	GETCH0			; insertmode => don't advance template
	CMP	BH,BL
	JAE	GETCH0			; no more characters in template
	INC	SI			; Skip to next char in template
	INC	BH			; remember position in template

	PUSH	AX			;
	MOV	AL,BYTE PTR [SI-1]	;AN000;;		    2/13/KK
	invoke	TESTKANJ		;AN000;;		    2/13/KK
	POP	AX			;AN000;;		    2/13/KK
	JZ	GETCH0			;AN000;; Wasn't a dual byte 2/13/KK
	INC	SI			;AN000;; Was a dual byte,   2/13/KK
	INC	BH			;AN000;;     skip one more  2/13/KK
GETCH0: 				;AN000;; 2/17/KK
	JMP	GETCH			;AN000;; 2/17/KK

BACKSPJ: JMP	SHORT BACKSP

BUFFUL:
	popf				;AN000;; 2/17/KK
	MOV	AL,7			;AN000;; Bell to signal full buffer
	invoke	OUTT
	JMP	GETCH
;						2/17/KK
;	Reduce character count, reduce pointer	2/17/KK
;						2/17/KK
InterCheck:				;AN000;;       2/17/KK
	dec	dh			;AN000;; adjust count	       2/17/KK
	dec	di			;AN000;; adjust buffer pointer 2/17/KK
	ret				;AN000;;		       2/17/KK

ESCC:
	transfer    OEMFunctionKey	; let the OEM's handle the key dispatch

ENDLIN:
	STOSB				; Put the CR in the buffer
	invoke	OUTT			; Echo it
	POP	DI			; Get start of user buffer
	MOV	[DI-1],DH		; Tell user how many bytes
	INC	DH			; DH is length including CR
COPYNEW:
	SaveReg <DS,ES>
	RestoreReg <DS,ES>		; XCHG ES,DS
	MOV	SI,OFFSET DOSGROUP:INBUF
	MOV	CL,DH			; set up count
	REP	MOVSB			; Copy final line to user buffer
	return
;
; Output a CRLF to the user screen and do NOT store it into the buffer
;
PHYCRLF:
	invoke	CRLF
	JMP	GETCH

;
; Delete the previous line
;
LineDel:
	OR	DH,DH
	JNZ	bridge00	;AN000;; 2/13/KK
	JMP	GetCh		;AN000;; 2/13/KK
bridge00:			;AN000;; 2/13/KK
	Call	BackSpace
	JMP	LineDel

;
; delete the previous word.
;
WordDel:
WordLoop:
	Call	BackSpace		; backspace the one spot
	OR	DH,DH
	JZ	GetChJ
	MOV	AL,ES:[DI-1]
	cmp	al,'0'
	jb	GetChj
	cmp	al,'9'
	jbe	WordLoop
	OR	AL,20h
	CMP	AL,'a'
	JB	GetChJ
	CMP	AL,'z'
	JBE	WordLoop
GetChJ:
	JMP	GetCh
;
; The user wants to throw away what he's typed in and wants to start over.  We
; print the backslash and then go to the next line and tab to the correct spot
; to begin the buffered input.
;
	entry	KILNEW
	MOV	AL,"\"
	invoke	OUTT		;Print the CANCEL indicator
	POP	SI		;Remember start of edit buffer
PUTNEW:
	invoke	CRLF		;Go to next line on screen
	MOV	AL,[STARTPOS]
	invoke	TAB		;Tab over
	JMP	NEWLIN		;Start over again


;
; Destructively back up one character position
;
entry	BackSp
	Call	BackSpace
	JMP	GetCh

BackSpace:
	OR	DH,DH
	JZ	OLDBAK		;No chars in line, do nothing to line
	CALL	BACKUP		;Do the backup
	MOV	AL,ES:[DI]	;Get the deleted char
	invoke	TESTKANJ	;AN000;2/13/KK
	JNZ	OLDBAK		;AN000; Was a dual byte, done  2/13/KK
	CMP	AL," "
	JAE	OLDBAK		;Was a normal char
	CMP	AL,c_HT
	JZ	BAKTAB		;Was a tab, fix up users display
;; 9/27/86 fix for ctrl-U backspace
	CMP	AL,"U"-"@"      ; ctrl-U is a section symbol not ^U
	JZ	OLDBAK
	CMP	AL,"T"-"@"      ; ctrl-T is a paragraphs symbol not ^T
	JZ	OLDBAK
;; 9/27/86 fix for ctrl-U backspace
	CALL	BACKMES 	;Was a control char, zap the '^'
OLDBAK:
	CMP	BYTE PTR [INSMODE],0
	retnz			;In insert mode, done
	OR	BH,BH
	retz			;Not advanced in template, stay where we are
	DEC	BH		;Go back in template
	DEC	SI
;-------------------------- Start of DBCS 2/13/KK
	OR	BH,BH		;AN000;
	retz			;AN000;; If we deleted one char and it was the only
				;AN000;;  one, could not have dual byte
;;;;	POP	AX		;AN000;; Get start of template
;;;;	PUSH	AX		;AN000;; Put it back on stack
	mov	ax,cs:Temp_Var	;AN000;; 3/31/KK
	XCHG	AX,SI		;AN000;
LOOKDUAL:			;AN000;
	CMP	SI,AX		;AN000;
	JAE	ATLOC		;AN000;
	PUSH	AX		;AN000;
	MOV	AL,BYTE PTR [SI];AN000;
	invoke	TESTKANJ	;AN000;
	POP	AX		;AN000;
	JZ	ONEINC		;AN000;
	INC	SI		;AN000;
ONEINC: 			;AN000;
	INC	SI		;AN000;
	JMP	SHORT LOOKDUAL	;AN000;
				;AN000;
ATLOC:				;AN000;
	retz			;AN000;; Correctly pointing to start of single byte
	DEC	AX		;AN000;; Go back one more to correctly point at start
	DEC	BH		;AN000;        ; of dual byte
	MOV	SI,AX		;AN000;
	return			;AN000;
;-------------------------- End of DBCS 2/13/KK

BAKTAB:
	PUSH	DI
	DEC	DI		;Back up one char
	STD			;Go backward
	MOV	CL,DH		;Number of chars currently in line
	MOV	AL," "
	PUSH	BX
	MOV	BL,7		;Max
	JCXZ	FIGTAB		;At start, do nothing
FNDPOS:
	SCASB			;Look back
	JNA	CHKCNT
	CMP	BYTE PTR ES:[DI+1],9
	JZ	HAVTAB		;Found a tab
	DEC	BL		;Back one char if non tab control char
CHKCNT:
	LOOP	FNDPOS
FIGTAB:
	SUB	BL,[STARTPOS]
HAVTAB:
	SUB	BL,DH
	ADD	CL,BL
	AND	CL,7		;CX has correct number to erase
	CLD			;Back to normal
	POP	BX
	POP	DI
	JZ	OLDBAK		;Nothing to erase
TABBAK:
	invoke	BACKMES
	LOOP	TABBAK		;Erase correct number of chars
	JMP	SHORT OLDBAK

BACKUP:
	DEC	DH		;Back up in line
	DEC	DI
;-------------------------Start of DBCS 2/13/KK
	OR	DH,DH			;AN000;
	JZ	BACKMES 		;AN000;; If deleted one and got only, no dual
	MOV	AX,DI			;AN000;
	MOV	DI,OFFSET DOSGROUP:INBUF;AN000;
LOOKDUAL2:				;AN000;
	CMP	DI,AX			;AN000;
	JAE	ATLOC2			;AN000;
	PUSH	AX			;AN000;
	MOV	AL,BYTE PTR ES:[DI]	;AN000;
	invoke	TESTKANJ		;AN000;
	POP	AX			;AN000;
	JZ	ONEINC2 		;AN000;
	INC	DI			;AN000;
ONEINC2:				;AN000;
	INC	DI			;AN000;
	JMP	SHORT LOOKDUAL2 	;AN000;
					;AN000;
ATLOC2: 				;AN000;
	JE	BACKMES 		;AN000;; Correctly deleted single byte
	DEC	AX			;AN000; Go back one more to correctly delete dual byte
	DEC	DH			;AN000;
	MOV	DI,AX			;AN000;
	CALL	BACKMES 		;AN000;
;---------------------------End of DBCS 2/13/KK
BACKMES:
	MOV	AL,c_BS 	;Backspace
	invoke	OUTT
	MOV	AL," "          ;Erase
	invoke	OUTT
	MOV	AL,c_BS 	;Backspace
	JMP	OUTT		;Done

;User really wants an ESC character in his line
	entry	TwoEsc
	MOV	AL,[ESCCHAR]
	JMP	SAVCH

;Copy the rest of the template
	entry	COPYLIN
	MOV	CL,BL		;Total size of template
	SUB	CL,BH		;Minus position in template, is number to move
	JMP	SHORT COPYEACH

	entry	CopyStr
	invoke	FINDOLD 	;Find the char
	JMP	SHORT COPYEACH	;Copy up to it

;Copy one char from template to line
	entry	COPYONE
	MOV	CX,1			;AN000;;	       2/13/KK
	MOV	AL,[SI] 		;AN000;; get char      2/13/KK
	invoke	TestKanj		;AN000;; is it kanji?  2/13/KK
	JZ	CopyEach		;AN000;; no, go do copy2/13/KK
	INC	CX			;AN000;; do 2 byte copy2/13/KK

;Copy CX chars from template to line
COPYEACH:
	MOV	BYTE PTR [INSMODE],0	;All copies turn off insert mode
	CMP	DH,DL
	JZ	GETCH2			;At end of line, can't do anything
	CMP	BH,BL
	JZ	GETCH2			;At end of template, can't do anything
	LODSB
	STOSB
;----------------------------- Start of DBCS 2/13/KK
	INC	BH			;AN000;; Ahead in template
	INC	DH			;AN000;; Ahead in line
	CALL	TestKanj		;AN000;; 2 byte character?
	JZ	CopyLoop		;AN000;; no, go copy next
	CMP	DH,DL			;AN000;; over boundary?
	JNZ	CopyBoth		;AN000;; no, move both
	DEC	BH			;AN000;; yes, backup template
	DEC	DH			;AN000;; back up line
	DEC	SI			;AN000;; patch (from Dohhaku)
	DEC	DI			;AN000;; remember to backup after previous move
	JMP	GetCh			;AN000;; go get next char
					;AN000;
CopyBoth:				;AN000;
	invoke	BUFOUT			;AN000;; output the first byte
	LODSB				;AN000;; get the second
	STOSB				;AN000;; move the second
	INC	BH			;AN000;; bump template
	INC	DH			;AN000;; bump line
	DEC	CX			;AN000;; dump byte count
CopyLoop:				;AN000;
	invoke	BUFOUT			;AN000;
	LOOP	COPYEACH		;AN000;
;;;;;	invoke	BUFOUT
;;;;;	INC	BH			;Ahead in template
;;;;;	INC	DH			;Ahead in line
;;;;;	LOOP	COPYEACH
;----------------------------- End of DBCS 2/13/KK
GETCH2:
	JMP	GETCH

;Skip one char in template
	entry	SKIPONE
	CMP	BH,BL
	JZ	GETCH2			;At end of template
	INC	BH			;Ahead in template
	INC	SI
	PUSH	AX			;AN000;; 2/13/KK
	MOV	AL,BYTE PTR [SI-1]	;AN000;; 2/13/KK
	invoke	TESTKANJ		;AN000;; 2/13/KK
	POP	AX			;AN000;; 2/13/KK
	JZ	GETCH2			;AN000;; 2/13/KK
	INC	BH			;AN000;; 2/13/KK
	INC	SI			;AN000;; 2/13/KK
	JMP	GETCH

	entry	SKIPSTR
	invoke	FINDOLD 		;Find out how far to go
	ADD	SI,CX			;Go there
	ADD	BH,CL
	JMP	GETCH

;Get the next user char, and look ahead in template for a match
;CX indicates how many chars to skip to get there on output
;NOTE: WARNING: If the operation cannot be done, the return
;	address is popped off and a jump to GETCH is taken.
;	Make sure nothing extra on stack when this routine
;	is called!!! (no PUSHes before calling it).

TABLE	SEGMENT 			;AN000;; 2/17/KK
Public	KISTR001S,KISTR001E		;AN000;; 2/17/KK
KISTR001S	label	byte		;AN000;; 2/17/KK
LOOKSIZ DB	0			;AN000;; 0 if byte, NZ if word	2/17/KK
KISTR001E	label	byte		;AN000;; 2/17/KK
TABLE	ENDS				;AN000;; 2/17/KK

FINDOLD:
	MOV	[LOOKSIZ],0		;AN000;; Initialize to byte    2/13/KK
	call	IntCNE1 		;AN000;;		       2/17/KK
	CMP	AL,[ESCCHAR]		;AN000;; did he type a function key?
;;;;;	JNZ	FindSetup		;AN000;; no, set up for scan   2/13/KK
	JNZ	TryKanj 		;AN000;; no, continue testing  2/13/KK
	call	IntCNE1 		;AN000;;		       2/17/KK
	JMP	NotFnd			       ; go try again
;;;;;;;FindSetup:			;AN000;; 2/13/KK
TryKanj:				;AN000;; 2/13/KK
	invoke	TESTKANJ		;AN000;; 2/13/KK
	JZ	GOTLSIZ 		;AN000;; 2/13/KK
	INC	[LOOKSIZ]		;AN000;; Gonna look for a word	2/13/KK
	PUSH	AX			;AN000;; Save first byte	2/13/KK
	call	IntCNE1 		;AN000;;		       2/17/KK
	POP	CX			;AN000;; 2/13/KK
	MOV	AH,AL			;AN000;; 2/13/KK
	MOV	AL,CL			;AN000;; AX is dual byte sequence to look for
	XOR	CX,CX			;AN000;; Re-zero CH	2/13/KK
GOTLSIZ:
	MOV	CL,BL
	SUB	CL,BH		;CX is number of chars to end of template
	JZ	NOTFND		;At end of template
	DEC	CX		;Cannot point past end, limit search
	JZ	NOTFND		;If only one char in template, forget it
	PUSH	AX			;AN000;; 2/13/KK
	MOV	AL,BYTE PTR [SI]	;AN000;; 2/13/KK
	invoke	TESTKANJ		;AN000;; 2/13/KK
	POP	AX			;AN000;; 2/13/KK
	JZ	NOTDUAL5		;AN000;; 2/13/KK
	DEC	CX			;AN000;; And one more besides	2/13/KK
	JZ	NOTFND			;AN000;; If only one char in template, forget it
NOTDUAL5:				;AN000;; 2/13/KK
	PUSH	ES
	PUSH	DS
	POP	ES
	PUSH	DI
	MOV	DI,SI		;Template to ES:DI
;;;;	INC	DI		  2/13/KK
;;;;	REPNE	SCASB		;Look  2/13/KK
;--------------------- Start of DBCS 2/13/KK
	PUSH	AX			;AN000;
	MOV	AL,BYTE PTR ES:[DI]	;AN000;
	invoke	TESTKANJ		;AN000;
	POP	AX			;AN000;
	JZ	ONEINC5 		;AN000;
	INC	DI			;AN000;; We will skip at least something
ONEINC5:				;AN000;
	INC	DI			;AN000;
	CMP	[LOOKSIZ],0		;AN000;
	JNZ	LOOKWORD		;AN000;
LOOKBYTE:				;AN000;
	PUSH	AX			;AN000;
	MOV	AL,BYTE PTR ES:[DI]	;AN000;
	invoke	TESTKANJ		;AN000;
	POP	AX			;AN000;
	JZ	TESTITB 		;AN000;
	INC	DI			;AN000;
	INC	DI			;AN000;
	DEC	CX			;AN000;
	LOOP	LOOKBYTE		;AN000;
	JMP	SHORT ATNOTFND		;AN000;
					;AN000;
TESTITB:				;AN000;
	DEC	CX			;AN000;
	CMP	AL,ES:[DI]		;AN000;
	JZ	ATSPOT			;AN000;
	INC	DI			;AN000;
	INC	CX			;AN000;; Counter next instruction
	LOOP	LOOKBYTE		;AN000;
ATNOTFND:				;AN000;
	XOR	AL,AL			;AN000;
	INC	AL			;AN000;; Set NZ
ATSPOT: 			; 2/13/K;AN000;K
;--------------------- End of DBCS 2/13/KK
	POP	DI
	POP	ES
	JNZ	NOTFND		;Didn't find the char
	NOT	CL		;Turn how far to go into how far we went
	ADD	CL,BL		;Add size of template
	SUB	CL,BH		;Subtract current pos, result distance to skip
	return

NOTFND:
	POP	BP		;Chuck return address
	JMP	GETCH
;------------------------- Start of DBCS 2/13/KK
LOOKWORD:			       ;AN000;
	PUSH	AX		       ;AN000;
	MOV	AL,BYTE PTR ES:[DI]    ;AN000;
	invoke	TESTKANJ	       ;AN000;
	POP	AX		       ;AN000;
	JNZ	TESTITW 	       ;AN000;
	INC	DI		       ;AN000;
	LOOP	LOOKWORD	       ;AN000;
	JMP	SHORT ATNOTFND	       ;AN000;
				       ;AN000;
TESTITW:			       ;AN000;
	DEC	CX		       ;AN000;
	CMP	AX,ES:[DI]	       ;AN000;
	JZ	ATSPOT		       ;AN000;
	INC	DI		       ;AN000;
	INC	DI		       ;AN000;
	LOOP	LOOKWORD	       ;AN000; ; Performs second DEC of CX
	JMP	SHORT ATNOTFND	       ;AN000;
;------------------------- End of DBCS 2/13/KK

entry	REEDIT
	MOV	AL,"@"          ;Output re-edit character
	invoke	OUTT
	POP	DI
	PUSH	DI
	PUSH	ES
	PUSH	DS
	invoke	COPYNEW 	;Copy current line into template
	POP	DS
	POP	ES
	POP	SI
	MOV	BL,DH		;Size of line is new size template
	JMP	PUTNEW		;Start over again

	entry	EXITINS
	entry	ENTERINS
	NOT	BYTE PTR [INSMODE]
	JMP	GETCH

;Put a real live ^Z in the buffer (embedded)
	entry	CTRLZ
	MOV	AL,"Z"-"@"
	JMP	SAVCH

;Output a CRLF
	entry	CRLF
	MOV	AL,c_CR
	invoke	OUTT
	MOV	AL,c_LF
	JMP	OUTT

EndProc $STD_CON_STRING_INPUT

;-------------- Start of DBCS 2/17/KK
PUBLIC	IntCNE0 			;AN000;
procedure	IntCNE0,near		;AN000;
	push	word ptr [InterCon]	;AN000;
	mov	[InterCon],01		;AN000;
get_com:				;AN000;
	invoke	INTER_CON_INPUT_NO_ECHO ;AN000;; get a byte character
	pop	word ptr [InterCon]	;AN000;
	ret				;AN000;
IntCNE0 endp				;AN000;
					;AN000;
procedure	IntCNE1,near		;AN000;
	push	word ptr [InterCon]	;AN000;
	mov	[InterCon],00		;AN000;
	jmp	short get_com		;AN000;
IntCNE1 endp				;AN000;
					;AN000;
	procedure	outchax,near	;AN000;
	pushf				;AN000;
	mov	[SaveCurFlg],0		;AN000;
	jnz	sj1			;AN000;
	mov	[SaveCurFlg],1		;AN000;
sj1:					;AN000;
	CALL	OUTCHA			;AN000;
	mov	[SaveCurFlg],0		;AN000;
	popf				;AN000;
	ret				;AN000;
outchax endp				;AN000;
					;AN000;
	procedure	bufoutx,near	;AN000;
	pushf				;AN000;
	mov	[SaveCurFlg],0		;AN000;
	jnz	sj2			;AN000;
	mov	[SaveCurFlg],1		;AN000;
sj2:					;AN000;
	invoke	BUFOUT			;AN000;
	mov	[SaveCurFlg],0		;AN000;
	popf				;AN000;
	ret				;AN000;
bufoutx endp				;AN000;
;-------------- End of DBCS 2/17/KK
