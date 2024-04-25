;	Termcap description of capabilities:

;ibmans4:mtcon:IBM PC with V4.0 ANSI driver:\
;	:al=\E[L:am:bs:ce=\E[K:cl=\E[2J\E[H:cm=\E[%;%H:co#80:\
;	:dl=\E[M:do=\E[B:ho=\E[H:li#24:mi:nd=\E[C:\
;	:ms:pt:se=\E[m:so=\E[1;36m:up=\E[A:\
;	:kb=^h:ku=\E[A:kd=\E[B:kl=\E[D:kr=\E[C:kh=\E[H:kn#8:\
;	:k1=\ES:k2=\ET:k3=\EU:k4=\EV:k5=\EW:\
;	:k6=\EP:k7=\EQ:k8=\ER:

CMDTABL DB	'A'
	DW	CUU		;CUrsor Up
	DB	'B'
	DW	CUD		;CUrsor Down
	DB	'C'
	DW	CUF		;CUrsor Forward
	DB	'D'
	DW	CUB		;CUrsor Back
	DB	'H'
	DW	CUP		;CUrsor Position
	DB	'J'
	DW	ED		;Erase in Display
	DB	'K'
	DW	EL		;Erase in Line
	DB	'L'
	DW	IL		;Insert Line
	DB	'M'
	DW	xDL		;Delete Line
;;	DB	'R'
;;	DW	CPR		;Cursor Postion Report
	DB	'f'
	DW	HVP		;Horizontal and Vertical Position
	DB	'h'
	DW	SM		;Set Mode
	DB	'l'
	DW	RM		;Reset Mode
	DB	'm'
	DW	SGR		;Select Graphics Rendition
;;	DB	'n'
;;	DW	DSR		;Device Status Report
	DB	's'
	DW	SCP		;Save Cursor Position
	DB	'u'
	DW	RCP		;Restore Cursor Position
	DB	00

;	Graphic Rendition modes:  parameter, mask, set
GRMODE	DB	00,00000000B,00000111B	; all off
	DB	01,11111111B,00001000B	; bold (increased intensity)
	DB	04,11111000B,00000001B	; underscore
	DB	05,11111111B,10000000B	; blink
	DB	07,11111000B,01110000B	; reverse video
	DB	08,10001000B,00000000B	; concealed
	DB	30,11111000B,00000000B	; foreground colors ...
	DB	31,11111000B,00000100B
	DB	32,11111000B,00000010B
	DB	33,11111000B,00000110B
	DB	34,11111000B,00000001B
	DB	35,11111000B,00000101B
	DB	36,11111000B,00000011B
	DB	37,11111000B,00000111B
	DB	40,10001111B,00000000B	; background colors ...
	DB	41,10001111B,01000000B
	DB	42,10001111B,00100000B
	DB	43,10001111B,01100000B
	DB	44,10001111B,00010000B
	DB	45,10001111B,01010000B
	DB	46,10001111B,00110000B
	DB	47,10001111B,01110000B
	DB	0FFH

; Set/Reset Modes:  indexed by (SelChar-'<'*8) + (PARAM0 AND 7)
SRMODE	DW	0,0,0,0,0,0,0,0		; SelChar '<'
	DW	1,1,1,1,1,1,1,WRAP	; SelChar '='	
	DW	0,EnaL25,0,0,0,0,0,0	; SelChar '>'
	DW	0,0,0,0,0,0,0,WRAP	; SelChar '?'	

PAGE
;	The following are duplicates of the same variables from the ROM
;
;* WARNING - the following two variables are accessed as a word
MODE	DB	3
MAXCOL	DB	79
IF	LINE25		; special treatment of line 25?
maxrow	equ	24
ELSE
maxrow	equ	25
ENDIF
;* WARNING - the following two variables are accessed as a word
COL	DB	0			; current column
ROW	DB	0			; current row


AnsiState	LABEL	BYTE	; the following must be saved on a screen swap
WRAP	DB	1		; 0 = NO WRAP, 1 = WRAP
EnaL25	DB	0		; 0 = 25th line disabled, 1 = enabled
STATE	DW	S1
SAVCR	DW	0			; saved cursor position
;* WARNING - the following two variables are accessed as a word
SelChar	DB	0			; <,=,> or ? private use indicators
PRMCNT	LABEL	BYTE			; number of parameters for command
PRMCNTW	DW	0
NUMPARAM equ	5			; max. number of parameters
PARAM	DB	NUMPARAM DUP (?)	; buffer for command parameters
;* WARNING - the following two variables are accessed as a word
attrw	LABEL	WORD
ATTR	DB	00000111B	;CHARACTER ATTRIBUTE
BPAGE	DB	0		;BASE PAGE

AnsiSize	equ	($-AnsiState)

IF	(AnsiSize GT TermSize)
	.RADIX 0		; ERROR - Terminal state not big enough
ENDIF

;-------------------------------------------------------------
;
;	CHROUT - WRITE OUT CHAR IN AL USING CURRENT ATTRIBUTE
;
base	   dw	0b800h
screen_seg dw	00000h

chrout: cmp	al,13		; carriage return?
	ja	outchr
	jnz	trylf
	mov	[col],0
;;	jmp	short setit
	jmp	setit

trylf:	cmp	al,10		; line feed?
	jz	lf
	cmp	al,7		; bell?
	jnz	trytab
torom:
	mov	bx,[attrw]
	and	bl,7
	mov	ah,14
	int	10h
ret5:	ret

trytab:
	cmp	al,9		; tab?
	jnz	tryback
	mov	al,[col]
	add	al,8
	mov	ah,al
	and	ah,7
	sub	al,ah
	cmp	al,[maxcol]
	jb	tunder
	mov	al,[maxcol]
tunder:
	mov	[col],al
		jmp	short setit

tryback:
	cmp	al,8		; backspace?
	jnz	outchr
	cmp	[col],0
	jz	ret5
	dec	[col]
	jmp	short setit

outchr:
	mov	bx,[attrw]
	mov	cx,1
	mov	ah,9
	int	10h
	inc	[col]
	mov	al,[col]
	cmp	al,[maxcol]
	jbe	setit
	cmp	[wrap],1
	jz	outchr1
	dec	[col]
	ret
outchr1:
	mov	[col],0
lf:	cmp	[row],(maxrow-1)
	ja	setit				; on line 25, don't move
	jz	lf1				; on 24th line, scroll
	inc	[row]
	jmp	short setit
lf1:	call	scroll

setit:	mov	dx,word ptr col
	mov	bh,[bpage]
	mov	ah,2
	int	10h
	ret

scroll: mov	al,mode
	cmp	al,2
	jz	myscroll
	cmp	al,3
	jz	myscroll
IF	LINE25
	xor	cx,cx			; from 0,0
	mov	dh,(maxrow-1)		; to maxrow-1,maxcol
	mov	dl,maxcol
	mov	bh,attr
	mov	ax,0601h		; scroll  up one line
	int	10h
	ret
ELSE
	mov	al,10
	jmp	torom
ENDIF
myscroll:
	mov	bh,[attr]
	mov	bl,' '
	mov	bp,80
	mov	ax,[base]
	add	ax,[screen_seg]
	mov	es,ax
	mov	ds,ax
	xor	di,di
	mov	si,160
	mov	cx,(maxrow-1)*80
	cld

;	This code will never get executed since we get here when
;  mode = 2 or 3 only.
;;	cmp	cs:[base],0b800h
;;	jz	colorcard

;;    rep	movsw
;;	mov	ax,bx
;;	mov	cx,bp
;;    rep	stosw
;;	jmp	short sret

;;colorcard:
	mov	dx,3dah
wait2:	in	al,dx
	test	al,8
	jz	wait2
	mov	al,25h
	mov	dx,3d8h
	out	dx,al		;turn off video
    rep	movsw
	mov	ax,bx
	mov	cx,bp
	rep	stosw
	mov	al,29h
	mov	dx,3d8h
	out	dx,al		;turn on video
sret:	push	cs
	pop	ds
	ret


CharOut:	PUSH	AX		; Main entry point
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
	PUSH	DI
	PUSH	ES
	PUSH	BP

	MOV	[base],0B800H
	XCHG	AX,SI			; SAVE CHARACTER TO STUFF
	MOV	AX,40H			; POINT TO ROS BIOS
	MOV	DS,AX
	MOV	AX,DS:[49H]		; AL=MODE, AH=MAX COL
	DEC	AH			; ANSI NEEDS 0-79 OR 0-39
	MOV	WORD PTR CS:[MODE],AX	; SAVE MODE AND MAX COL
	CMP	AL,7
	JNZ	NOT_BW
	MOV	WORD PTR CS:[base],0B000H
NOT_BW: MOV	AL,DS:[62H]		; GET ACTIVE PAGE
	MOV	CS:[BPAGE],AL
	CBW
	ADD	AX,AX
	MOV	BX,AX
	MOV	AX,DS:[BX+50H]		; AL=COL, AH=ROW
	MOV	WORD PTR CS:[COL],AX	; SAVE ROW AND COLUMN
	MOV	AX,DS:[4EH]		; GET START OF SCREEN SEG
	MOV	CL,4
	SHR	AX,CL			; CONVERT TO A SEGMENT
	PUSH	CS
	POP	DS
	MOV	[screen_seg],AX
	XCHG	AX,SI			; GET BACK CHARACTER IN AL

	CALL	VIDEO
	POP	BP
	POP	ES
	POP	DI
	POP	SI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET


;----------------------------------------------------------
;
;	OUTPUT SINGLE CHAR IN AL TO VIDEO DEVICE
;
VIDEO:	MOV	SI,OFFSET STATE
	JMP	[SI]

S2:	CMP	AL,'['
	JZ	S22
	JMP	S1
S22:	MOV	WORD PTR [SI],OFFSET S30
	XOR	BX,BX
	MOV	WORD PTR SelChar,BX
	MOV	WORD PTR PARAM,BX
	JMP	SHORT S3B

S30:	CMP	AL,'?'			; experimental use selector (SM/RM)?
	JA	S7
	mov	SelChar,al
	MOV	WORD PTR [SI],OFFSET S3
	cmp	al,'<'
	jae	S3B

S3:	CMP	AL,';'
	JNZ	S3C
S3A:	INC	PRMCNT
S3B:	CALL	GETPTR
	XOR	AX,AX
	MOV	WORD PTR [BX],AX    ;DEFAULT VALUE IS ZERO
	RET

S3C:	CMP	AL,'0'
	JB	S3D
	CMP	AL,'9'
	JA	S7
	CALL	GETPTR
	SUB	AL,'0'
	XCHG	AL,BYTE PTR [BX]
	MOV	AH,10
	MUL	AH			;*10
	ADD	BYTE PTR [BX],AL	;MOVE IN DIGIT
	RET

S3D:
;;	CMP	AL,'"'                  ;BEGIN QUOTED STRING
;;	JZ	S3E
;;	CMP	AL,"'"
	JNZ	S7
;;S3E:	MOV	WORD PTR [SI],OFFSET S4
;;	MOV	[INQ],AL
S3RET:	RET

;
;   ENTER QUOTED STRINGS
;

;;S4:	CMP	AL,[INQ]		;CHECK FOR STRING TERMINATOR
;;	JNZ	S4A
;;	DEC	PRMCNT			;TERMINATE STRING
;;	MOV	WORD PTR [SI],OFFSET S3
;;	RET

;;S4A:	CALL	GETPTR
;;	MOV	BYTE PTR [BX],AL
;;	MOV	WORD PTR [SI],OFFSET S4
;;	JMP	S3A
;
;  LOOK FOR ANSI COMMAND SPECIFIED IN AL
;

S7:	MOV	BX,OFFSET CMDTABL-3
;
S7A:	ADD	BX,3
	CMP	BYTE PTR [BX],0
	JZ	S1B
	CMP	BYTE PTR [BX],AL
	JNZ	S7A
;
S7B:	MOV	AX,WORD PTR [BX+1]     ;AX = JUMP ADDRESS
	MOV	BX,OFFSET PARAM
	MOV	DL,BYTE PTR [BX]
	XOR	DH,DH		       ;DX = FIRST PARAMETER
	MOV	CX,DX
	OR	CX,CX
	JNZ	S7C
	INC	CX		       ; if DX=0, CX=1 else CX = DX
S7C:	JMP	AX		       ;AL = COMMAND

S1:	CMP	AL,1Bh		       ;ESCAPE SEQUENCE?
	JNZ	S1B
	MOV	WORD PTR [SI],OFFSET S2
	RET

S1B:	CALL	CHROUT
S1A:	MOV	WORD PTR [STATE],OFFSET S1
	RET

MOVCUR: CMP	BYTE PTR [BX],AH
	JZ	SETCUR
	ADD	BYTE PTR [BX],AL
	LOOP	MOVCUR
SETCUR: MOV	DX,WORD PTR COL
	XOR	BX,BX
	MOV	AH,2
	int	10h			; call ROM
	JMP	S1A

HVP:
CUP:
IF	LINE25
	CMP	CL,(maxrow+1)
	jb	cup3			; new row is 24 or less
	JA	SETCUR			; error - 26 or greater
	cmp	EnaL25,0		; else 25, is it allowed?
	jz	SETCUR
cup3:
ELSE
	CMP	CL,maxrow
	JA	SETCUR
ENDIF
	MOV	AL,MAXCOL
	MOV	CH,BYTE PTR [BX+1]
	OR	CH,CH
	JZ	CUP1
	DEC	CH
CUP1:	CMP	AL,CH
	JA	CUP2
	MOV	CH,AL
CUP2:	XCHG	CL,CH
	DEC	CH
	MOV	WORD PTR COL,CX
	JMP	SETCUR

CUF:	MOV	AH,MAXCOL
	MOV	AL,1
CUF1:	MOV	BX,OFFSET COL
	JMP	MOVCUR

CUB:	MOV	AX,00FFH
	JMP	CUF1

CUU:	MOV	AX,00FFH
CUU1:	MOV	BX,OFFSET ROW
	JMP	MOVCUR

CUD:	MOV	AX,(maxrow-1)*256+1
IF	LINE25
	cmp	ah,[row]			; at bottom of screen?
	ja	SETCUR
ENDIF
	JMP	CUU1

SCP:	MOV	AX,WORD PTR COL
	MOV	SAVCR,AX
	JMP	SETCUR

RCP:	MOV	AX,SAVCR
IF	LINE25
	cmp	ch,maxrow
	jb	rcp1
	cmp	EnaL25,0
	jz	rcp2
ENDIF
rcp1:	MOV	WORD PTR COL,AX
rcp2:	JMP	SETCUR

SGR:	XOR	CX,CX
	XCHG	CL,PRMCNT
	CALL	GETPTR
	INC	CX
SGR1:	MOV	AL,BYTE PTR [BX]
	PUSH	BX
	MOV	BX,OFFSET GRMODE
SGR2:	MOV	AH,BYTE PTR [BX]
	ADD	BX,3
	CMP	AH,0FFH
	JZ	SGR3
	CMP	AH,AL
	JNZ	SGR2
	MOV	AX,WORD PTR [BX-2]
	AND	ATTR,AL
	OR	ATTR,AH
SGR3:	POP	BX
	INC	BX
	LOOP	SGR1
	JMP	SETCUR

ED:
IF	LINE25
	cmp	row,maxrow		; on 25th line?
	je	EL			; yes, treat like Erase in Line
ENDIF
	xor	cx,cx
	mov	dl,maxcol
	mov	dh,(maxrow-1)
	cmp	param,1			; which subcommand?
	ja	el2			; all
	jb	ed1
	mov	dh,row			; to beginning
	dec	dh
	jle	EL
	jmp	short ed2
ed1:	mov	ch,row			; to end
	inc	ch
	cmp	ch,dh
	jae	EL
ed2:	mov	bh,attr
	MOV	AX,0600H
	int	10h			; call ROM

EL:	MOV	CX,WORD PTR COL
	MOV	dx,cx
	mov	al,param
	inc	al			; 0,1,2 => 1,2,3
	test	al,1			; to end?
	je	el1
	mov	dl,maxcol
el1:	test	al,2			; to beginning?
	je	el2
	mov	cl,0
el2:	mov	bh,attr
	mov	ax,0600H
	int	10h
S1A_j:	jmp	S1A

IL:	mov	ah,7			; scroll down
	jmp	short dl1

xDL:	mov	ah,6			; scroll up
dl1:	mov	al,cl			; number of lines
	mov	ch,row
	xor	cl,cl
	mov	dh,(maxrow-1)
	mov	dl,maxcol
	mov	bh,attr
	int	10h
	jmp	S1A_j

RM:	XOR	CL,CL
	JMP	SHORT SM1

SM:	MOV	CL,1
SM1:	mov	bl,SelChar		; get selection character
	sub	bl,'<'			; adjust
	jb	S1A_j			; less than '<'
	cmp	bl,4
	jae	S1A_j			; greater than '?'
	xor	bh,bh
	shl	bx,1
	shl	bx,1
	shl	bx,1
	MOV	AL,DL
	CMP	AL,7
	JA	S1A_j
	or	bl,al
	shl	bx,1
	mov	bx,SRMODE[bx]		; get function indicator
	cmp	bx,1			; no or special function?
	jb	S1A_j
	jz	SM2			; sets screen mode
	MOV	[bx],CL
	JMP	S1A_j

SM2:	MOV	AH,0
	int	10h			; call ROM
	JMP	S1A_j

;	GetPtr - get a pointer to the current parameter
GETPTR: MOV	BX,PRMCNTW
	CMP	BX,NUMPARAM
	JB	GET1
	DEC	PRMCNT
	JMP	GETPTR
GET1:	ADD	BX,OFFSET PARAM
	RET
