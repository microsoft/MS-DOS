page 60,132

title CP/DOS  DOSPutMessage  mapper

dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
; ************************************************************************* *
; *
; *	 MODULE: DosPutMessage
; *
; *	 FILE NAME: dos035.asm
; *
; *	 FUNCTION:   diplay message
; *
; *	 CALLING SEQUENCE:
; *
; *		push	handle		; file handle
; *		push	messlgth	; message length
; *		push	messbuff	; message buffer
; *		call	dosputmessage
; *
; *	 RETURN SEQUENCE:   AX = return code
; *
; *
; *
; *	 MODULES CALLED:     INT 21H  function 4
; *
; *************************************************************************

	public	dosputmessage
	.sall
	.xlist
	include macros.inc
	.list

str	struc
old_bp	dw	?
return	dd	?
MessagePtr	dd	?	; message pointer
MessageLength	dw	?	; message length
Handle		dw	?	; file handle
str	ends

dosputmessage proc   far

	Enter	dosputmessage		      ; save registers

	mov	bx,[bp].Handle		      ; get handle
	mov	cx,[bp].MessageLength	      ; get message length
	lds	dx,[bp].MessagePtr	      ; setup message buffer

	mov	ah,40h			      ; load opcode
	int	21h			      ; display message
	jc	ErrorExit		      ; jump if error

	xor	ax,ax			      ; else set good return code

ErrorExit:
	Mexit				      ; pop registers
	ret	size str - 6		      ; return

dosputmessage  endp

dosxxx	ends

	end
