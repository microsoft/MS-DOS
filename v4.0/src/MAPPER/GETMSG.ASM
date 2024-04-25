;
page 80,132
;
title CP/DOS DosGetMessage mapper
;
messages segment word public 'messages'

OurMessage	db	0dh,0ah,"DosGetMessage returning ->",'$'

ErrorMessageFlag	db	0
MessageToGo	dw	0
MessageLength	dw	0
NextVarPointer	dd	0
VarsToGo	dw	0

MaxMessageNumber	=	0

; This macro is used to define/declare all of the messages

; We will have four macros, msg 	 -> defines a complete message
;			    msgStart	 -> defines the first part of a message
;			    msgContinue  ->   continues a started message
;			    msgEnd	 ->	ends a message

MacroState = 0

;----------------------------------------------

MsgError	macro text		; message string error

	if1
	else
	%out 
	%out $ERROR - &text
	endif

 $ERROR - &text

	endm

;----------------------------------------------

msg	macro	number,text

	if	MacroState NE 0
 MsgError <Cannot use the 'Msg' Macro when inside a message definition.>
	mexit
	endif

Message&Number	db	text
		db	0

	if	MaxMessageNumber lt &number
	  MaxMessageNumber	  =	  &Number
	endif

MacroState = 0

	endm

;----------------------------------------------

msgStart	macro	number,text	 ; start of  a message string

	if	MacroState NE 0
 MsgError <Cannot use the 'MsgStart' macro when inside a message definition.>
	mexit
	endif

Message&Number	db	text

	if	MaxMessageNumber lt &number
	  MaxMessageNumber	  =	  &Number
	endif

MacroState = 1

	endm

;----------------------------------------------

msgContinue	macro	text		 ; messgage string contination

	if	MacroState EQ 0
 MsgError <Cannot use the 'MsgContinue' macro unless inside a message definition.>
	mexit
	endif

	db	text

MacroState = 1

	endm

;----------------------------------------------

msgEnd	macro				; end of message string

	if	MacroState EQ 0
 MsgError <Cannot use the 'MsgEnd' macro unless inside a message definition.>
	mexit
	endif

	db	0

MacroState = 0

	endm


;-----------------------------------------------

; Define/declare the messages first!

	include messages.inc

NotFoundNumber	=	-2

NotFoundMessage label	byte
		msg	NotFoundNumber,<'We could not find your message #'>

; Now, for each defined message, generate an index

msgidx	macro	number
	ifdef	Message&Number
	dw	&Number
	dw	offset messages:Message&Number
	endif
	endm

	even

MessageIndex	label	word

ThisMessageNumber	=	0
	rept	MaxMessageNumber + 1
	msgidx	%ThisMessageNumber
ThisMessageNumber	=	ThisMessageNumber + 1
	endm

	dw	-1

NotFoundIndex	dw	-2
		dw	offset messages:NotFoundMessage

messages ends
;
dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
;**********************************************************************
;*
;*   MODULE:   dosgetmessage
;*
;*   FILE NAME: dos029.asm
;*
;*   CALLING SEQUENCE:
;*
;*	 push@	   other   insert variable table
;*	 push	   word    insert variable count
;*	 push@	   other   message buffer address
;*	 push	   word    buffer length
;*	 push	   word    message number
;*	 push@	   asciiz  message file name
;*	 push@	   word    returned message length
;*	 call	   dosgetmessage
;*
;*   MODULES CALLED:  None (preliminary version)
;*
;*********************************************************************
;
	    public   dosgetmessage
	    .sall
	    .xlist
	    include  macros.inc
	    .list

str	    struc
old_bp	    dw	     ?
return	    dd	     ?
ReturnLengthPtr  dd	 ?	; length of returned message
MessageFileName  dd	 ?	; message file name
MessageNumber	 dw	 ?	; number of the message
MessageBufferLen dw	 ?	; length of the message buffer
MessageBufferPtr dd	 ?	; buffer address to return message
VariablesCount	 dw	 ?	; number of variables
VariableTablePtr dd	 ?	; table of variables to insert
str	    ends


dosgetmessage  proc	far

	Enter	Dosgetmessage		; push registers
	mov	ax,messages		; setup message buffer
	mov	ds,ax
	assume	ds:messages
	mov	ErrorMessageFlag,0	; reset error message flag

	mov	bx,[bp].MessageNumber		 ; get message number
	mov	si,offset messages:MessageIndex

SearchForMessageLoop:			; search for message in table
	lodsw
	cmp	ax,bx			; found ??
	je	FoundMessage		; jump if true

	add	si,2			; if not serach continues
	cmp	ax,-1
	jne	SearchForMessageLoop

	mov	si,offset messages:NotFoundIndex + 2
	mov	ErrorMessageFlag,1

; Here, ds:[si] -> word message number, followed by word message offset

FoundMessage:
	mov	si,ds:[si]

; Here, ds:[si] -> message text bytes

	les	di,[bp].VariableTablePtr	; get variable address
	mov	word ptr NextVarPointer+0,di	; save it
	mov	word ptr NextVarPointer+2,es

	mov	di,[bp].VariablesCount		; get variable count
	mov	VarsToGo,di			; save it

	les	di,[bp].MessageBufferPtr	; get return message buffer
						;     address
	mov	ax,[bp].MessageBufferLen	; get return message buffer
	mov	MessageToGo,ax			;   length

	cmp	ax,0				; length = 0 ??
	jne	HaveLengthToCopy		; if not, jump

	jmp	GetMessageDone			; done

HaveLengthToCopy:
	mov	MessageLength,0 		; initialize counter

MoveCharsLoop:
	lodsb					; get  next character
	cmp	al,'%'                          ; is it a % sign
	je	DoSubstitution			; if so, need substitution

	cmp	al,0				; end of string ??
	jne	RealCharacter			; if not look for real chars

	jmp	GetMessageDone			; else, jump to update
						;    return message length

RealCharacter:					; look for real character
	stosb
	inc	MessageLength			; update message length counter
	dec	MessageToGo
	jnz	MoveCharsLoop			; branch if not all done

	jmp	GetMessageDone			; else alldone, branch

DoSubstitution: 				; do substitution
	lodsb					; get character
	cmp	al,'%'                          ; check for %%
	je	RealCharacter			; if so, get next character



; skip the numbers that indicate field width!

SkipFieldWidth: 				; check for field width  digit
	cmp	al,'0'                          ; indicator digits
	jc	CheckChar

	cmp	al,'9'+1
	jnc	CheckChar
						; if field width indicator
	lodsb					; jump to examine next	char
	jmp	SkipFieldWidth

;-----------------------------------------

CheckChar:					; check for char substitution
	cmp	al,'c'                          ;   if true go do character
	je	SubstituteChar			;      substitution
	cmp	al,'C'
	jne	CheckDecimal

SubstituteChar: 				; do character subtitution
	push	ds
	push	si
	lds	si,NextVarPointer
	lds	si,ds:dword ptr [si]

	assume	ds:nothing

	lodsb
	pop	si
	pop	ds

	assume	ds:messages

	add	word ptr NextVarPointer,4
	dec	VarsToGo

	jmp	RealCharacter

;-----------------------------------------

CheckDecimal:					; check for decimal subtitution
	cmp	al,'d'                          ;   if true, do decimal
	je	SubstituteDecimal		;      substitution
	cmp	al,'D'
	jne	CheckString

SubstituteDecimal:				; do decimal subtitution
	push	ds
	push	si
	lds	si,NextVarPointer
	lds	si,ds:dword ptr [si]

	assume	ds:nothing

	lodsw
	pop	si
	pop	ds

	assume	ds:messages

	add	word ptr NextVarPointer,4
	dec	VarsToGo

	mov	dx,0
	call	ConvDec

	add	MessageLength,ax
	sub	MessageToGo,ax
	jc	PastEndOfBuffer

	jmp	MoveCharsLoop

PastEndOfBuffer:
	jmp	GetMessageDone

;-----------------------------------------

CheckString:
	cmp	al,'s'                          ; check for string subtitution
	je	SubstituteString		;   if true, do string
	cmp	al,'S'                          ;      substitution
	jne	CheckLong

SubstituteString:				; do string substitution
	push	ds
	push	si
	mov	cx,MessageToGo
	mov	dx,MessageLength
	lds	si,NextVarPointer
	lds	si,ds:dword ptr [si]
	assume	ds:nothing

ContinueStringSubstitution:
	lodsb
	cmp	al,0
	je	EndOfSubstituteString

	stosb
	inc	dx
	loop	ContinueStringSubstitution

EndOfSubstituteString:
	pop	si
	pop	ds
	assume	ds:messages

	add	word ptr NextVarPointer,4
	dec	VarsToGo

	mov	MessageLength,dx
	mov	MessageToGo,cx
	jcxz	PastEndOfBuffer

	jmp	MoveCharsLoop

;-----------------------------------------

CheckLong:					  ; need long substitution
	cmp	al,'l'
	je	SubstituteLong			  ; if true go do it
	cmp	al,'L'
	jne	Unknown 			  ; else unknown substitution

SubstituteLong:
	jmp	RealCharacter			  ; just go back

;-----------------------------------------

Unknown:
	jmp	RealCharacter			  ; just go back




; Update the return message length

GetMessageDone:
	push	ds
	push	si
	mov	ax,MessageLength
	lds	si,[bp].ReturnLengthPtr
	assume	ds:nothing
	mov	ds:[si],ax
	pop	si
	pop	ds
	assume	ds:messages

	cmp	ErrorMessageFlag,0
	je	NotErrorMessage

	mov	ErrorMessageFlag,0

KeepGoingBackwards:
	cmp	es:byte ptr [di-1],0
	jne	PutItHere

	dec	di
	jmp	KeepGoingBackwards

PutItHere:
	mov	ax,[bp].MessageNumber
	mov	dx,0

	call	convdec
	lds	si,[bp].ReturnLengthPtr
	assume	ds:nothing
	add	ax,3			; for cr, lf, nul
	add	ds:[si],ax

	mov	al,0dh
	stosb
	mov	al,0ah
	stosb

	mov	al,0
	stosb

NotErrorMessage:
	jmp	SkipToHere

	mov	dx,seg messages
	mov	ds,dx
	mov	dx,offset messages:OurMessage

	mov	ah,9			   ; load op code
	int	21h			   ; display message

	lds	si,[bp].ReturnLengthPtr
	mov	cx,ds:[si]
	lds	dx,[bp].MessageBufferPtr

	mov	bx,1
	mov	ah,40h
	int	21h			   ; display message

SkipToHere:
	xor	ax,ax			   ; set good return code

	mexit				   ; pop registers
	ret	 size str - 6		   ; return

dosgetmessage  endp

	page

;������������������������������������������������������������������

Tens	dd	10000000
	dd	1000000
	dd	100000
	dd	10000
	dd	1000
	dd	100
	dd	10
	dd	1
	dd	0

convdec proc	near

; input es:di -> location to put decimal characters at
;	dx:ax -> 32bit value to be displayed

; output es:di -> next location for output characters
;	 ax = number of characters output

	push	bp
	sub	sp,6
	mov	bp,sp

DecLength	equ	word ptr [bp+0]
LowValue	equ	word ptr [bp+2]
HighValue	equ	word ptr [bp+4]

	mov	DecLength,0
	mov	HighValue,dx
	mov	LowValue,ax

	mov	bx,offset dosxxx:Tens

; Start with a count of zero.

DigitLoop:
	mov	dx,0

; Loop, counting the number of times you can subtract the current digit value

CountLoop:
	mov	ax,cs:[bx+0]
	sub	LowValue,ax
	mov	ax,cs:[bx+2]
	sbb	HighValue,ax
	jc	TooFar
	inc	dx		; Subtraction did no go negative, inc digit
	jmp	CountLoop

; Since we know when this digit is done by the number going negative, we must
;  fixup the damage.

TooFar:
	mov	ax,cs:[bx+0]
	add	LowValue,ax
	mov	ax,cs:[bx+2]
	adc	HighValue,ax

; We need to supress leading zeros, so check to see if this digit is non zero

	cmp	dx,0
	jnz	DoDisplay

; Digit is zero, check to see if we have put out any digits yet?

	cmp	Declength,0
	jz	NextDigit

; Either digit was non zero, or we have already output the leading non-zero.
;  It really doesn't matter, display the digit

DoDisplay:
	mov	al,dl
	add	al,'0'
	stosb
	inc	DecLength

; Set up for the next digit, and determine if we are done

NextDigit:
	add	bx,4
	cmp	cs:word ptr [bx+0],0
	jnz	DigitLoop
	cmp	cs:word ptr [bx+2],0
	jnz	DigitLoop

; Check to see that we at least put out a single 0 character

	cmp	DecLength,0
	jne	Done

; We didn't, so let's put the zero there

	mov	al,'0'
	stosb
	inc	DecLength

; The decimal display is complete.  Get the return value and return

Done:
	mov	ax,DecLength

	mov	sp,bp
	add	sp,6
	pop	bp

	ret

convdec endp

dosxxx	    ends

	    end
