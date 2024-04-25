page 80,132

title CP/DOS DosQFileMode mapper

dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
;**********************************************************************
;*
;*   MODULE:   dosqfilemode	Read file attribute
;*
;*   FUNCTION:	Query file mode
;*
;*   CALLING SEQUENCE:
;*
;*	 push@	   asciiz   file path name
;*	 push@	   word     attribute return area
;*	 push	   dword    reserved
;*	 call	   dosqfilemode
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=43h, change file mode
;*
;*********************************************************************

	    public   dosqfilemode
	    .sall
	    .xlist
	    include  macros.inc
	    .list

error_code  equ      0002h

str	    struc
old_bp	    dw	     ?
return	    dd	     ?
rsrvd	    dd	     ?
Attrib	    dd	     ?	     ; current attribute pointer
Path	    dd	     ?	     ; file path name pointer
str	    ends

dosqfilemode proc    far
	    Enter    dosqfilemode	 ; push registers

	    lds      dx,[bp].path	 ; set path name

	    mov      ax,4300h		 ; set op code
	    int      21h		 ; get file mode
	    jc	     error		 ; jump if error

	    lds      si,[bp].attrib	 ; setup return data area
	    mov      word ptr [si],cx	 ; save attribute there
	    sub      ax,ax		 ; set good return code
	    jmp      short exit 	 ; return

error:	    mov      ax,error_code	 ; set error code

exit:	    mexit			 ; pop registers
	    ret      size str - 6	 ; return

dosqfilemode endp

dosxxx	    ends

	    end
