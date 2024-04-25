;
page 80,132
;0
title CP/DOS DosChgFilePtr mapper	    * * *
;
dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;**********************************************************************
;*
;*   MODULE:   doschgfileptr
;*
;*   FILE NAME: dos007.asm
;*
;*   CALLING SEQUENCE:
;*
;*	 push	   word    file handle
;*	 push	   dword   distance
;*	 push	   word    move type
;*	 push@	   dword   new pointer
;*	 call	   doschgfileptr
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=42h, move file pointer
;*
;*********************************************************************

	    public   doschgfileptr
	    .sall
	    .xlist
	    include  macros.inc
	    .list

str	    struc
old_bp	    dw	     ?
return	    dd	     ?
newptr	    dd	     ?	     ; new file pointer
movtyp	    dw	     ?	     ; move type
dstnce	    dd	     ?	     ; distance to be moved
handle	    dw	     ?	     ; file handle
str	    ends

doschgfileptr  proc  far
	    Enter    doschgfileptr	 ; push registers

	    push     es
	    les      dx,[bp].dstnce
	    mov      cx,es		 ; set distance
	    pop      es
	    mov      ax,[bp].movtyp	 ; get move type
	    mov      bx,[bp].handle	 ; get handle

	    mov      ah,42h
	    int      21h		 ; move file pointer
	    jc	     exit		 ; return if error

	    lds      si,[bp].newptr	   ; set pointer
	    mov      word ptr [si],ax	   ; save the new pointer
	    mov      word ptr [si]+2,dx    ;
	    sub      ax,ax		   ; set godd return code

exit:	    mexit		       ;pop registers
	    ret      size str - 6      ;return

doschgfileptr endp

dosxxx	    ends

	    end
