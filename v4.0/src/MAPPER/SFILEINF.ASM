; 0
page 80,132

title CP/DOS DosSetFileInfo mapper


FileAttributeSegment	segment word public 'fat'

	extrn	FileAttributeTable:word

FileAttributeSegment	ends


dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
;**********************************************************************
;*
;*   MODULE:   dossetfileinfo
;*
;*   FUNCTION:	set file information
;*
;*   CALLING SEQUENCE:
;*
;*	 push	   word     file handle
;*	 push	   word     info level
;*	 push@	   other    file info buffer
;*	 push	   word     file buffer size
;*	 call	   dossetfileinfo
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=57h, set file's date/time
;*
;*********************************************************************

	    public   dossetfileinfo
	    .sall
	    .xlist
	    include  macros.inc
	    .list



str	    struc
old_bp	    dw	     ?
return	    dd	     ?
BufferSize  dw	     ?		; file info buufer size
BufferPtr   dd	     ?		; file info buffer
Level	    dw	     ?		; file info level
Handle	    dw	     ?		; file handle
str	    ends

dossetfileinfo	proc	 far
	Enter	dossetfileinfo	      ; push registers

	mov	bx,[bp].Handle	      ; fill registers for function call
	lds	si,[bp].BufferPtr     ; date/time pointer
	mov	dx,word ptr [si]+8    ; date to be set
	mov	cx,word ptr [si]+10   ; time to be set

	mov	ax,5701h
	int	21h
	jc	ErrorExit	      ; check for error

; This code should be un-commented when the attribute can be set from
; the setfileinfo call

;	lds	si,[bp].BufferPtr
;	mov	ax,ds:[si].the offset to the attribute word

;	mov	bx,seg FileAttributeSegment
;	mov	ds,bx
;	assume	ds:FileAttributeSegment

;	mov	bx,[bp].Handle
;	add	bx,bx

;	mov	FileAttributeTable[bx],ax

	sub	ax,ax		       ; set good return code

ErrorExit:
	mexit			       ; pop registers
	ret	size  str - 6	       ; return

dossetfileinfo endp

dosxxx	    ends

	    end
