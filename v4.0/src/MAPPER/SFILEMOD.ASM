;0
page 80,132

title CP/DOS DosSetFileMode mapper

dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;**********************************************************************
;*
;*   MODULE:   dossetfilemode
;*
;*   FUNCTION:	 Set file mode
;*
;*   CALLING SEQUENCE:
;*
;*	 push@	   asciiz   file path name
;*	 push	   word     new attribute
;*	 push	   dword    reserved
;*	 call	   dossetfilemode
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=43h, change file mode
;*
;*********************************************************************

	    public   dossetfilemode
	    .sall
	    .xlist
	    include  macros.inc
	    .list


str	struc
old_bp	dw	?
return	dd	?
Rsrvd	dd	?	; reserved
Attrib	dw	?	; file attribute
Path	dd	?	; path name pointer  pointer
str	ends

dossetfilemode proc  far
	    Enter    dossetfilemode	   ; push registers

	    lds      dx,[bp].path	   ; set pointer to path
	    mov      cx,[bp].attrib

	    mov      ax,4301h
	    int      21h		   ; change file mode
	    jc	     exit		   ; jump if error, return DOS error in ax

	    xor      ax,ax		   ; set good return code
	    jmp      short exit 	   ; return

exit:	    mexit			   ; pop registers
	    ret      size  str - 6	   ; return

dossetfilemode endp

dosxxx	    ends

	    end
