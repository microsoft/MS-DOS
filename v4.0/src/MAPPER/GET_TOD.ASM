;
page 80,132
;
title CP/DOS DosGetDateTime mapper
;
dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
;**********************************************************************
;*
;*   MODULE:   dosgetdatetime
;*
;*   FUNCTION:	get date and time information
;*
;*   CALLING SEQUENCE:
;*
;*	 push@	   struc  date/time
;*	 call	   dosgetdatetime
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=2ah, get date
;*				      ah=2ch, get time
;*
;*********************************************************************

	    public   dosgetdatetime
	    .sall
	    include  macros.inc

str	    struc
old_bp	    dw	     ?
return	    dd	     ?
data	    dd	     ?	     ; date and time info return pointer
str	    ends

dosgetdatetime	proc far

	    Enter    dosgetdatetime	   ; push registers

	    lds      si,[bp].data	   ; set return data area

	    mov      ah,2ch		   ; get time information
	    int      21h
					   ; save info in return data are
	    mov      byte ptr [si],ch	   ; save hour
	    mov      byte ptr [si]+1,cl    ;	 minutes
	    mov      byte ptr [si]+2,dh    ;	 seconds
	    mov      byte ptr [si]+3,dl    ;	 hundredths

	    mov      ah,2ah		   ; get date  and save it
	    int      21h		   ;	in return data area

	    mov      byte ptr [si]+4,dl    ; save day
	    mov      byte ptr [si]+5,dh    ;	 month
	    mov      word ptr [si]+6,cx    ;	 year
	    mov      word ptr [si]+8,360   ;	 min. from GMT
	    mov      byte ptr [si]+10,al   ;	 day of week

exit:	    sub      ax,ax		   ; set good return code

	    Mexit			   ; pop registers
	    ret      size str - 6	   ; return

dosgetdatetime endp

dosxxx	    ends

	    end
