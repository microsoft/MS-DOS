;0
page 80,132

title CP/DOS  DosClose  mapper   * * *

dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
; ************************************************************************* *
; *
; *	 MODULE: DosClose
; *
; *	 FUNCTION: This module will close a file or a device.
; *
; *	 CALLING SEQUENCE:
; *
; *		   PUSH  WORD  FileHandle ;  File Handle or device handle
; *		   CALL  DosClose
; *
; *	 RETURN SEQUENCE:
; *
; *		   IF ERROR (AX not = 0)
; *
; *		      AX = Error Code:
; *
; *		      o   Invalid file handle
; *
; *
; *	 MODULES CALLED:  DOS int 21H function 3EH
; *
; *
; *************************************************************************

	public	DosClose
	.sall
	.xlist
	include macros.inc
	.list

str	struc
old_bp	   dw	  ?
return	   dd	  ?
FileHandle dw	  ?	     ; file or device handle
str	ends


DosClose  proc	 far
	Enter	DosClose	       ; push registers

; Only files are closed.  Devices are not closed, since OPEN creates
; a dummy device handle without actually openning the device.

	mov	bx,[bp].FileHandle     ; load the handle
	mov	ax,bx		       ; check for device handle
	neg	ax		       ; if device handle, return
	jns	GoodExit	       ; do not close the device

FileCloseRequest:
	mov	ax,03e00h	       ; load opcode
	int	21h		       ; close the file
	jc	ErrorExit	       ; return if error

GoodExit:
	sub	ax,ax		       ; else, set good return code

ErrorExit:
	mexit			       ; pop registers
	ret	size str - 6	       ; return

DosClose  endp

dosxxx	ends

	end
