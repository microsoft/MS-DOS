;0
page 80,132

title CP/DOS KbdFlushBuffer mapper

kbdxxx	segment byte public 'kbd'
	assume	cs:kbdxxx,ds:nothing,es:nothing,ss:nothing

; ************************************************************************* *
; *
; *	 MODULE: kbdflushbuffer
; *
; *************************************************************************
;
	public kbdflushbuffer
	.sall
	.xlist
	include kbd.inc
	.list

	public savedkbdinput
savedkbdinput	label	word
		db	0	; Character goes here
		db	0	; Not zero means char is here


str	struc
old_bp	dw	?
return	dd	?
handle	dw	?	   ; kbd handle
str	ends

kbdflushbuffer	proc   far
	Enter	KbdFlushBuffer	  ; push registers
	mov	ah,0bh		  ; Check for ^C
	int	021h

	mov	ax,0c06h
	mov	dl,-1
	int	021h
	jz	nochar

	mov	ah,1
	mov	savedkbdinput,ax
	jmp	done
nochar:
	mov	savedkbdinput,0

done:	sub	ax,ax		  ; set good return code
	Mexit			  ; pop registers
	ret	size str - 6	  ; return

kbdflushbuffer endp

kbdxxx	ends

	end
