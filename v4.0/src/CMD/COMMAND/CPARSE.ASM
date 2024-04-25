 page 80,132
;	SCCSID = @(#)cparse.asm 1.1 85/05/14
;	SCCSID = @(#)cparse.asm 1.1 85/05/14
	INCLUDE comsw.asm

.xlist
.xcref
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm
.list
.cref


TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BADCD_PTR:WORD		;AC022;
	EXTRN	BADCPMES_ptr:word	;AC000;
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	comma:byte
	EXTRN	cpyflag:byte
	EXTRN	CURDRV:BYTE
	EXTRN	ELCNT:BYTE
	EXTRN	ELPOS:BYTE
	EXTRN	EXPAND_STAR:BYTE
	EXTRN	SKPDEL:BYTE
	EXTRN	STARTEL:WORD
	EXTRN	SWITCHAR:BYTE
	EXTRN	switch_list:byte
	EXTRN	TPA:WORD
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING

	EXTRN	CERROR:NEAR

	PUBLIC	BADCDERR		;AC022;
	PUBLIC	CPARSE

SWCOUNT EQU	5			; Must agree with length of switch_list

;-----------------------------------------------------------------------;
; ENTRY:								;
;	DS:SI	Points input buffer					;
;	ES:DI	Points to the token buffer				;
;	BL	Special delimiter for this call 			;
;		    Always checked last 				;
;		    set it to space if there is no special delimiter	;
; EXIT: 								;
;	DS:SI	Points to next char in the input buffer 		;
;	ES:DI	Points to the token buffer				;
;	[STARTEL] Points to start of last element of path in token	;
;		points to a NUL for no element strings 'd:' 'd:/'       ;
;	CX	Character count 					;
;	BH	Condition Code						;
;			Bit 1H of BH set if switch character		;
;				Token buffer contains char after	;
;				switch character			;
;				BP has switch bits set (ORing only)	;
;			Bit 2H of BH set if ? or * in token		;
;				if * found element ? filled		;
;			Bit 4H of BH set if path sep in token		;
;			Bit 80H of BH set if the special delimiter	;
;			   was skipped at the start of this token	;
;		Token buffer always starts d: for non switch tokens	;
;	CARRY SET							;
;	    if CR on input						;
;		token buffer not altered				;
;									;
;	DOES NOT RETURN ON BAD PATH, OR TRAILING SWITCH CHAR ERROR	;
; MODIFIES:								;
;	CX, SI, AX, BH, DX and the Carry Flag				;	;
;									;
; -----------------------------------------------------------------------;
;---------------
; Modifications to cparse:  recognition of right and left parentheses
; as integral tokens, and removal of automatic upper-case conversion code.
;
; Both modifications were installed in the course of adding a coherent
; command-line parser to COMMAND.COM which builds a UNIX-style argv[]/argc
; structure for command-line arguments.  This parser relies on cparse to
; recognize individual tokens.
;
; To process for-loops correctly, parentheses must therefore be
; recognized as tokens.  The upper-case conversion code was removed so
; that commands (such as for and echo) would be able to use the "original"
; text of the command line.
;
; Note also the modification to prevent the automatic conversion of colons
; into spaces WITHIN THE SOURCE TEXT!
;
; Also note that BP is also clobbered if cparse recognizes any switches
; on the command line.
;
; Alan L, OS/MSDOS				    14 August 1983
;---------------

CPARSE:
ASSUME	DS:TRANGROUP,ES:TRANGROUP

	xor	ax,ax
	mov	[STARTEL],DI			; No path element (Is DI correct?)
	mov	[ELPOS],al			; Start in 8 char prefix
	mov	[SKPDEL],al			; No skip delimiter yet
	mov	bh,al				; Init nothing
	pushf					; save flags
	push	di				; save the token buffer addrss
	xor	cx,cx				; no chars in token buffer
	mov	comma,cl			;g reset comma flag
moredelim:
	LODSB
	INVOKE	DELIM
	JNZ	SCANCDONE
	CMP	AL,' '
	JZ	moredelim
	CMP	AL,9
	JZ	moredelim
	xchg	al,[SKPDEL]
	or	al,al
	jz	moredelim			; One non space/tab delimiter allowed
	test	bh,080h 			;g  has a special char been found?
	jz	no_comma			;g  no - just exit
	mov	comma,1 			;g  set comma flag
no_comma:
	JMP	x_done				; Nul argument

SCANCDONE:

;;;;	IF	NOT KANJI	3/3/KK
;---------------
; Mod to avoid upper-case conversion.
;	cmp	cpyflag,1		3/3/KK
;	jnz	cpcont1 		3/3/KK
;	invoke	UPCONV			3/3/KK
cpcont1:
;---------------
;;;;	ENDIF			3/3/KK

	cmp	al,bl				; Special delimiter?
	jnz	nospec
	or	bh,80H
	jmp	short moredelim

nospec:
	cmp	al,0DH				; a CR?
	jne	ncperror
	jmp	cperror

ncperror:
	cmp	al,[SWITCHAR]			; is the char the switch char?
	jne	na_switch			; yes, process...
	jmp	a_switch

na_switch:
	mov	dl,':'
	cmp	byte ptr [si],dl
	jne	anum_chard			; Drive not specified

;;;;	IF	KANJI		3/3/KK
;---------------
; Mod to avoid upper-case conversion.
	cmp	cpyflag,1
	jnz	cpcont2
	invoke	UPCONV
cpcont2:
;---------------
;;;;	ENDIF			3/3/KK

	call	move_char
	lodsb					; Get the ':'
	call	move_char
	mov	[STARTEL],di
	mov	[ELCNT],0
	jmp	anum_test

anum_chard:
	mov	[STARTEL],di
	mov	[ELCNT],0			; Store of this char sets it to one
	cmp	cpyflag,1			; Was CPARSE called from COPY?
	jnz	anum_char			; No, don't add drive spec.
	invoke	PATHCHRCMP			; Starts with a pathchar?
	jnz	anum_char			; no
	push	ax
	mov	al,[CURDRV]			; Insert drive spec
	add	al,capital_A
	call	move_char
	mov	al,':'
	call	move_char
	pop	ax
	mov	[STARTEL],di
	mov	[ELCNT],0

anum_char:

;;;;	IF	KANJI		3/3/KK
	invoke	TESTKANJ
	jz	NOTKANJ 			;AC048;
	call	move_char
	lodsb
	jmp	short notspecial

NOTKANJ:					;AN048; If not kanji
	cmp	cpyflag,1			;AN048; and if we're in COPY
	jnz	testdot 			;AN048;
	invoke	upconv				;AN048; upper case the char

TESTDOT:
;;;;	ENDIF			3/3/KK

	cmp	al,dot_chr
	jnz	testquest
	inc	[ELPOS] 			; flag in extension
	mov	[ELCNT],0FFH			; Store of the '.' resets it to 0

testquest:
	cmp	al,'?'
	jnz	testsplat
	or	bh,2

testsplat:
	cmp	al,star
	jnz	testpath
	or	bh,2
	cmp	byte ptr [expand_star],0
	jnz	expand_filename
	jmp	SHORT testpath

badperr2j:
	jmp	badperr2

expand_filename:
	mov	ah,7
	cmp	[ELPOS],0
	jz	gotelcnt
	mov	ah,2

gotelcnt:
	mov	al,'?'
	sub	ah,[ELCNT]
	jc	badperr2j
	xchg	ah,cl
	jcxz	testpathx

qmove:
	xchg	ah,cl
	call	move_char
	xchg	ah,cl
	loop	qmove

testpathx:
	xchg	ah,cl

testpath:
	invoke	PATHCHRCMP
	jnz	notspecial
	or	bh,4
	cmp	byte ptr [expand_star],0
	jz	no_err_check
	test	bh,2				; If just hit a '/', cannot have ? or * yet
	jnz	badperr

no_err_check:
	mov	[STARTEL],di			; New element
	INC	[STARTEL]			; Point to char after /
	mov	[ELCNT],0FFH			; Store of '/' sets it to 0
	mov	[ELPOS],0

notspecial:
	call	move_char			; just an alphanum string
anum_test:

	lodsb

;;;;	IF	NOT KANJI		3/3/KK
;---------------
; Mod to avoid upper-case conversion.
;	cmp	cpyflag,1		3/3/KK
;	jnz	cpcont3 		3/3/KK
;	invoke	UPCONV			3/3/KK
cpcont3:
;---------------
;;;;	ENDIF				3/3/KK

	INVOKE	DELIM
	je	x_done

	cmp	al,0DH
	je	x_done
	cmp	al,[SWITCHAR]
	je	x_done
	cmp	al,bl
	je	x_done
	cmp	al,':'                          ; ':' allowed as trailer because
						; of devices
;;;;	IF	KANJI		3/3/KK
	je	FOO15
	jmp	anum_char
FOO15:
;;;	ELSE			3/3/KK
;;;	jne	anum_charj	3/3/KK
;;;	ENDIF			3/3/KK

;---------------
; Modification made for parseline.
; Why would it be necessary to change colons to spaces?  In this
; case, EVERY colon is changed to a space; e.g., 'f:' yields 'f ',
; but so does 'echo foo:bar' yield 'echo foo bar'.
;---------------
	cmp	cpyflag,2			; Is CPARSE parsing the 1st token from
						;  from PARSELINE?
	jnz	cpcont4 			; No, continue
	call	move_char			; Yes, save the ':' and go get another
	jmp	anum_test			;  character.

cpcont4:
	inc	si				;Skip the ':'
	jmp	short x_done

anum_charj:
	jmp	anum_char

badperr2:
	mov	dx,offset trangroup:BADCPMES_ptr
	jmp	CERROR

badperr:
BADCDERR:					;AC022; Issue "Invalid Directory"
	MOV	DX,OFFSET TRANGROUP:BADCD_ptr	;AC022;     message
	JMP	CERROR				;AC022;

cperror:
	dec	si				; adjust the pointer
	pop	di				; retrive token buffer address
	popf					; restore flags
	stc					; set the carry bit
	return

x_done:
	dec	si				; adjust for next round
;---------------
; Mod to recognize right and left parens as integral tokens.
x_done2:
;---------------
	jmp	short out_token

a_switch:
	OR	BH,1				; Indicate switch
	OR	BP,fSwitch
	INVOKE	SCANOFF
	INC	SI
	invoke	testkanj			;AN057; See if DBCS lead byte
	jz	a_switch_notkanj		;AN057; no - continue processing
	call	move_char			;AN057; DBCS - store first byte
	lodsb					;AN057; get second byte
	call	move_char			;AN057; store second byte
	or	bp,fBadSwitch			;AN057; DBCS switch is invalid
	jmp	short out_token 		;AN057; don't bother checking switch
a_switch_notkanj:				;AN057;
	cmp	al,0DH
	jne	Store_swt
	mov	al,0
	stosb					; null at the end
	OR	BP,fBadSwitch
	jmp	cperror 			; Trailing switch character error
						;   BP = fSwitch but no switch
						;   bit is set (unknown switch)
Store_swt:
	call	move_char			; store the character
;
;---------------
; This upconv call must stay.  It is used to identify copy-switches
; on the command line, and won't store anything into the output buffer.
	invoke	UPCONV
;---------------
;
	PUSH	ES
	PUSH	DI
	PUSH	CX
	PUSH	CS
	POP	ES
ASSUME	ES:TRANGROUP
	MOV	DI,OFFSET TRANGROUP:switch_list
	MOV	CX,SWCOUNT
	OR	BP,fBadSwitch
	REPNE	SCASB
	JNZ	out_tokenp
	AND	BP,NOT fBadSwitch
	MOV	AX,1
	SHL	AX,CL
	OR	BP,AX

out_tokenp:
	POP	CX
	POP	DI
	POP	ES

ASSUME	ES:NOTHING
out_token:
	mov	al,0
	stosb				; null at the end
	pop	di			; restore token buffer pointer
	popf
	clc				; clear carry flag
	return

move_char:
	stosb				; store char in token buffer
	inc	cx			; increment char count
	inc	[ELCNT] 		; increment element count for * substi
	return

TRANCODE	ENDS
	END
