;***	Bugcode.inc - Debug code for including into sysini.asm and ibmbio.asm
;
;	Can't link in via buglib due to memory and relocation games played
;	by these modules.  Each gets a private, local-only copy of these
;	modules.


IFDEF	DEBUGFLG


;**	DPRINTF _ Debug Printf
;
;	Dprintf is a kernel debug print formatting package.  It is intended
;	to produce conviently formatted output.
;
;	Dprintf is called, indirectly, by a macro:
;
;	DEBUG	n,m,"string",<a1,...,an>
;
;	string = format string
;	a1     = first argument
;	an     = last argument
;
;	The format string is an ASCIZ string which can contain 2 types of
;	specifications:	 data-format specifications and literal characters.
;	Data format specifications always begin with a '$' character; all
;	characters not part of a data format specification are treated as
;	literal characters.
;
;	Literal characters
;	    - any character not part of a format specification.	 Special
;	      non-printing characters are:
;		\n	- CRLF
;		\t	- tab
;		\b	- bell
;		\\	- \
;		\$	- $
;
;	Format Specifications
;
;	A format specification takes the form:
;	     $ [@] <char>
;
;	where <char> =
;
;	    x	    - print argument as a hex word
;	    d	    - print argument as decimal word
;	    c	    - print argument as ascii character
;	    b	    - print argument as hex byte
;		For each of the above formats, the supplied argument
;		is a 16-bit word - the value to be printed.  The optional @
;		(described below) allows a segmented address to be supplied,
;		instead.
;
;	    s[nn]   - print argument as asciz string; if optional decimal
;		      argument follows the format character this specifys
;		      a maximum string length.	Non printing characters are
;		      printed in the form \nnn where "nnn" is the octal byte
;		      value.
;		      Note that this format character cannot be directly
;		      followed by a digit unless that digit is to be taken
;		      as the start of a length argument.
;
;	    Bnn	    - print argument as hex bytes.  The required following
;		      decimal argument is the number of bytes to print.
;
;		Both of these formats take a long address as their argument.
;		The '@' character is thus invalid for these formats.
;
;	WARNINGS
;	    As befitting a debug routine, DPRINTF does not have a whole lot
;	    of "failsafe" code in it.  Supplying screwed up formats can
;	    muck things up.  Specifically:
;		The @ argument must NOT be specified with the 's' or 'B'
;		     format
;		A string/byte-length argument of 0 is taken as 65536
;	    The string "%% BAD FMT %%" appears in the output when
;		1) an illegal format specifier is given, or
;		2) the B format is given a 0 or missing length
;
;	ENTRY	(sp+n  ) = address of format string (offset from return cs value)
;		(sp+n-2) = first argument word
;		(sp+n-4) = second argument word
;		    .
;		(sp+4  ) = last argument word
;		(sp+2  ) = seg of return address
;		(sp    ) = offset of return address
;		(bp) = offset of format string on the stack
;	EXIT	none
;	USES	flags

	PUBLIC	DPRINTF
DPRINTF PROC	near

	push	ds
	push	es
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax		; save registers
	cld

	mov	si,[bp]		; get address of format string
	sub	bp,2
	mov	bx,sp
	mov	ds,ss:20[bx]	; (ds:si) = address of format string
	push	cs
	pop	ds

;	Scan format string for next character
;
;	(ds:si) = address of format string
;	(ss:bp) = address of next argument

dpf1:	lodsb			; (al) = format string byte
	and	al,al
	je	dpf3		; all done
	cmp	al,'$'
	je	dpf4		; is data escape
	cmp	al,'\'
	jnz	dpf2		; got the character

;	it's an "\" escape code - crack the argument character

	lodsb
	and	al,al
	je	dpf3		; all done, ignore hanging \
	xchg	ah,al
	mov	al,0Ch
	cmp	ah,'n'
	jne	dpf1$5		; not \n
	mov	al,0dH
	call	putchar
	mov	al,0aH
	jmp	SHORT dpf2	; print LF

dpf1$5: cmp	ah,'t'
	mov	al,9
	je	dpf2		; is \t
	cmp	ah,'b'
	mov	al,7
	je	dpf2		; is \b
	xchg	ah,al
dpf2:	call	putchar
	jmp	dpf1

;	have the end of the format string - exit

dpf3:	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	es
	pop	ds
	ret


;*	Have a '$' character - is data format escape
;
;	Get address of data into es:di
;
;	(bp) = address of data value

dpf4:	mov	di,bp
	push	ss
	pop	es		; (es:di) = address of data value
	sub	bp,2		; point to next argument
	lodsb			; (al) = format specifier
	cmp	al,'@'
	jne	dpf5		; not an indirect flag
	les	di,[bp]
	sub	bp,2		; have an extra 2 for @
	lodsb
dpf5:	cmp	al,'x'
	jne	dpfd1		; not 'x'

;	is 'x' format - print hex word

	mov	ax,es:[di]
	call	THW		; type hex word
	jmp	dpf1

dpfd1:	cmp	al,'d'
	jnz	dpfc1		; not 'd'

;	is 'd' format - print decimal word

	mov	ax,es:[di]
	call	TDW		; type decimal word
	jmp	dpf1

dpfc1:	cmp	al,'c'
	jne	dpfb1

;	is 'c' format - print character

	mov	al,es:[di]
	call	putchar
	jmp	dpf1

dpfb1:	cmp	al,'b'
	jne	dpfs1

;	is 'b' format - print hex byte

	mov	al,es:[di]
	call	THB		; type hex byte
	jmp	dpf1

dpfs1:	cmp	al,'s'
	jne	dpfbb1

;	is 's' format - print ASCIZ string.  First, check for
;		optional decimal limit

	public	SSB
SSB:	sub	cx,cx		; set 65536 limit
	les	di,[bp]		; (es:DI) = fwa of string
	sub	bp,2		; argument to 's' was two words
	mov	al,[si]
	cmp	al,'0'
	jb	dpfs2		; not decimal
	cmp	al,'9'
	ja	dpfs2		; not decimal
	call	atod		; (ax) = decimal value, (ds:si) updated
	xchg	cx,ax

;	print asciz string at es:di, max of (cx) characters
;	(cx) = 0  means max of 65536
;
;	Other sections of code in dpf jump here to print strings

dpfs2:	mov	al,es:[di]
	inc	di
	and	al,al
	je	dpfs3
	call	putchar
	loop	dpfs2		; continue if not at limit
dpfs3:	jmp	dpf1

dpfbb1: cmp	al,'B'
	je	dpfbb2		; is 'B' format

;	error in format code - print message

dpferr: push	cs
	pop	es
	mov	di,OFFSET dpfa	; (es:di) = error message
	sub	cx,cx
	jmp	dpfs2

dpfa:	DB	'%% BAD FMT %%',0

;	have B format

dpfbb2: call	atod		; (ax) = length specifier
	jc	dpferr		; number not there - error
	xchg	cx,ax
	jcxz	dpferr		; number is 0 - error
	les	di,[bp]		; (es:DI) = fwa of string
	sub	bp,2		; argument to 's' was two words
dpfbb3: mov	al,es:[di]
	call	THB		; type hex byte
	mov	al,' '
	call	putchar		; space em out
	inc	di
	loop	dpfbb3		; do em all
	jmp	dpf1

DPRINTF ENDP


;**	THB - Type Hex Byte
;
;	THB types a hex byte (via "putchar")
;
;	ENTRY	(AL) = byte
;	EXIT	none
;	USES	ax, flags

THBA	DB	'0123456789abcdef'

	PUBLIC	THB
THB	PROC	near

	push	ax
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
	and	ax,0fH
	xchg	bx,ax
	mov	bl,CS:THBA[bx]
	xchg	ax,bx
	call	putchar		    ; put first character
	pop	ax
	and	ax,0fH
	xchg	bx,ax
	mov	bl,CS:THBA[bx]
	xchg	ax,bx
	call	putchar
	ret

THB	ENDP




;**	THW - Type Hex Word
;
;	THW types a word in hex (via "putchar")
;
;	ENTRY	(AX) = word
;	EXIT	none
;	USES	AX, flags

	PUBLIC	THW
THW	PROC	near

	push	ax
	xchg	ah,al
	call	THB
	pop	ax
	call	THB
	ret

THW	ENDP



;**	TDW - Type Decimal Word
;
;	TDW types (via "putchar") the unsigned decimal representation
;	of a 16-bit unsigned integer.  Only significant digits are
;	printed; if the number is 0 a "0" is printed.
;
;	ENTRY	(AX) = number
;	EXIT	none
;	USES	AX, flags

	PUBLIC	TDW
TDW	PROC	near

	push	cx		; preserve registers
	push	dx
	mov	cx,10
	call	tdw$		; recurse cracking digits
	pop	dx
	pop	cx
	ret

TDW	ENDP


;*	tdw$ - crack number recursively
;
;	tdw$ cracks the least significant decimal digit.  If there
;	are no higher-significant digits, print and return.
;	else, recurse for higher digits
;
;	(AX) = value
;	(CX) = 10

tdw$	PROC	NEAR

	sub	dx,dx
	div	cx		; (ax) = quotient, (dx) = remainder
	and	ax,ax
	jz	tdw$1		; this is highest-order, do it
	push	dx
	call	tdw$
	pop	dx
tdw$1:	xchg	ax,dx
	add	al,'0'
	call	putchar
	ret

TDW$	ENDP



;**	ATOD - Convert ASCII string to decimal number
;
;	ATOD is called to convert an ascii string of digits to a
;	decimal number.	 Digits are converted until we run out of them.
;
;	ENTRY	(DS:SI) = address of first digit
;	EXIT	'C' clear if OK
;		  (AX) = value
;		  (SI) updated to first non-digit
;		'C' set if error - no digits, or result >65535
;		  (DS:SI) points to error character
;	USES	AX, SI, FLAGS

	PUBLIC	ATOD
ATOD	PROC	near

	push	dx
	push	cx		    ; save registers
	mov	al,[si]
	sub	al,'0'
	jc	atod9		    ; error - no digits
	cmp	al,10
	cmc
	jc	atod9		    ; error - no digits
	sub	ax,ax		    ; clear accumulator
	mov	cx,10		    ; base 10

;	crack next digit
;
;	(AX) = number accumulated so near
;	(CX) = 10
;	(DS:SI) = next character

atod1:	xchg	dx,ax		; keep accum in dx for a while
	lodsb			; (al) = character
	sub	al,'0'
	jc	atod7		; not digit - all done
	cmp	al,9
	ja	atod7		; not digit - all done
	sub	ah,ah		; (ax) = digit value (0 - 9)
	push	ax
	xchg	ax,dx
	mul	cx		; (ax) = 10*accum
	pop	dx		; (dx) = digit to add
	jo	atod8		; overflow
	add	ax,dx
	jmp	atod1		; go back for more

;	Done with number, all OK
;
;	(dx) = number
;	(ds:si) = address+1 of first unused character

atod7:	clc

;	Done with number, error
;	'C' set

atod8:	dec	si		; backup over non-decimal (or error) char
atod9:	pop	cx
	xchg	ax,dx		; (ax) = number iff no error
	pop	dx		; restore registers
	ret			; exit

ATOD	ENDP

;**	putchar - put a character on the console
;
;	ENTRY	(al) = character
;	EXIT	none
;	USES	ax,flags


UR_DAT	=	02f8H		; COM1 = 03f8H, COM2 = 02f8H
UR_IEN	=	UR_DAT+1	; Interrupt enable
UR_IER	=	UR_DAT+2	; interrupt ID
UR_LCR	=	UR_DAT+3	; line control registers
UR_MCR	=	UR_DAT+4	; modem control register
UR_LSR	=	UR_DAT+5	; line status register
UR_MSR	=	UR_DAT+6	; modem status regiser
UR_DLL	=	UR_DAT		; divisor latch least sig
UR_DLM	=	UR_DAT+1	; divisor latch most sig

iflag	DB	0		; != 0 when initialized 8250

;*	inchr - input character
;
;	EXIT	'z' set if no character
;		'z' clear if char
;		  (al) = char

inchr:	mov	dx,UR_LSR
	in	al,dx
	and	al,1
	jz	inchr1
	mov	dx,UR_DAT
	in	al,dx
	and	al,07fh
inchr1: ret


	PUBLIC	putchar
putchar PROC	NEAR
	pushf
	cli
	push	dx
	push	cx
	push	bx
	push	ax		; (al) = character
	test	iflag,255
	jnz	putc1		; is initialized
	inc	iflag

;	program the usart

	mov	dx,UR_LCR
	mov	al,80h
	out	dx,al		; command it
	sub	al,al
	mov	dx,UR_DLM
	out	dx,al
	mov	dx,UR_DLL
	mov	al,12		; 9600 baud = 12, 19.2 Kbaud = 6
	out	dx,al
	mov	al,3
	mov	dx,UR_LCR
	out	dx,al		; command normal mode

;	see if CTL-Q or CTL-S

putc1:	pushf
	cli
	call	inchr
	jz	putc3		; no characters incomming
	cmp	al,19		; ctl-S?
	jnz	putc3		; no, ignore

;	have ctl-s.  wait till we see ctl-Q

putc2:	call	inchr
	jz	putc2
	cmp	al,17
	jnz	putc2

putc3:	popf
	mov	dx,UR_LSR
putc4:	in	al,dx
	test	al,020h
	jz	putc4

;	ready.	crank it out!

	mov	dx,UR_DAT

	pop	ax
	out	dx,al

	pop	bx
	pop	cx
	pop	dx
	popf
	ret

putchar ENDP

ENDIF
