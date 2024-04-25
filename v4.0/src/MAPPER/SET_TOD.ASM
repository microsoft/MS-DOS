;
page 80,132
;
title CP/DOS DosSetDateTime mapper
;
dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
;**********************************************************************
;*
;*   MODULE:   dossetdatetime
;*
;*   FILE NAME: dos050.asm
;*
;*   CALLING SEQUENCE:
;*
;*	 push@	   struc  date/time
;*	 call	   dossetdatetime
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=2bh, set date
;*				      ah=2dh, set time
;*
;*********************************************************************

	    public   dossetdatetime
	    .sall
	    include  macros.inc

error_ts_datetime equ 0002h

str	    struc
old_bp	    dw	     ?
return	    dd	     ?
Data	    dd	     ?	       ; TOD data pointer
str	    ends

dossetdatetime	proc far
	    Enter    dossetdatetime	   ; push registers

	    lds      si,[bp].data	   ; set TOD data pointer and load
					   ;   info into registers
	    mov      ch,byte ptr [si]	   ; load hour
	    mov      cl,byte ptr [si]+1    ;	 minutes
	    mov      dh,byte ptr [si]+2    ;	 seconds
	    mov      dl,byte ptr [si]+3    ;	 hundredths

	    mov      ah,2dh		   ; set time opcode
	    int      21h		   ; set new time
	    push     ax 		   ; check for error later

	    mov      dl,byte ptr [si]+4    ; load day
	    mov      dh,byte ptr [si]+5    ;	 month
	    mov      cx,word ptr [si]+6    ;	 year

	    mov      ah,2bh		   ; new date opcode
	    int      21h		   ; set new date

	    pop      bx
	    mov      cl,0
	    cmp      bl,cl		   ; return code from time set
	    jnz      error
	    cmp      al,0		   ; return code from date set
	    jz	     exit

error:	    mov      ax,error_ts_datetime  ; set error code
	    jmp      short exit1

exit:	    sub      ax,ax		   ; set good return code
exit1:	    Mexit			   ; pop registers
	    ret      size str - 6	   ; return

dossetdatetime endp

dosxxx	    ends

	    end
