;
page 80,132
;
title CP/DOS  DosDelete  mapper
;
dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
; ************************************************************************* *
; *
; *	 MODULE: DosDelete
; *
; *	 FILE NAME: DOS012.ASM
; *
; *	 FUNCTION: This module removes a directory entry associated with a
; *		   filename.
; *
; *
; *	 CALLING SEQUENCE:
; *
; *		   PUSH@ ASCIIZ FileName  ;  FileName path
; *		   PUSH@ DWORD 0	  ;  Reserved (must be zero)
; *		   CALL  DosDelete
; *
; *	 RETURN SEQUENCE:
; *
; *		   IF ERROR (AX not = 0)
; *
; *		      AX = Error Code:
; *		      o   Invalid file path name
; *
; *	 MODULES CALLED:  DOS int 21H  function 41H
; *
; *
; *
; *************************************************************************

	public	DosDelete
	.sall
	.xlist
	include macros.inc
	.list

str	struc
old_bp	dw	?
return	dd	?
dtrm12	dd	?	; reserved, always 0
asc012	dd	?	; file name path pointer
str	ends

DosDelete  proc   far
	Enter	DosDelete		    ; push registers

	lds	dx,dword ptr [bp].asc012    ; file path name

	mov	ah,041h
	int	21h			    ; delete the file
	jc	err012			    ; jump if no error

	sub	ax,ax			    ; set good return code

err012:
	mexit				    ; pop registers
	ret	size str - 6		    ; return

DosDelete  endp

dosxxx	ends

	end
