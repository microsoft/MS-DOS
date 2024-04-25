extrn	PrintString:near
extrn	PrintHex:near

display	macro string
	local	dbs,disp_exit
	pushf
	push	ds
	push	es

	push	cs
	pop	ds
	push	cs
	pop	es

	push	si
	mov	si,offset cs:dbs
	call	PrintString
	pop	si
	pop	es
	pop	ds
	popf
	jmp	disp_exit

dbs	db	&string,0

disp_exit:
	endm

content	macro reg
	pushf
	push	ds
	push	es
	push	ax

	mov	ax,reg

	push	cs
	pop	ds
	push	cs
	pop	es

	call	PrintHex

	pop	ax
	pop	es
	pop	ds
	popf
	endm

