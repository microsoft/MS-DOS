;0
page 60,132
;
title CP/DOS DosDevConfig mapper
;
dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
;**********************************************************************
;*
;*   MODULE:   dosdevconfig
;*
;*   FILE NAME: dos013.asm
;*
;*   CALLING SEQUENCE:
;*
;*	 push@	   other  returned info address
;*	 push	   word   item type being queried
;*	 push	   word   reserved parm(must be 0)
;*	 call	   dosdevconfig
;*
;*   MODULES CALLED:  ROM BIOS Int 11, Equipment check
;*
;*********************************************************************

	    public   dosdevconfig
	    .sall
	    include  macros.inc

inv_parm    equ      0002h
model_byte  equ      0fffeh

str	    struc
old_bp	    dw	     ?
return	    dd	     ?
rsrvd	    dw	     ?	      ; reserved
item	    dw	     ?	      ; item number
data	    dd	     ?	      ; returned information
str	    ends

dosdevconfig  proc far
	    Enter    dosdevconfig	   ; push registers

	    mov      ax,[bp].rsrvd	   ; reserved parm must
	    cmp      ax,0		   ; be zero
	    jne      error		   ; if not zero, jump

	    mov      ax,[bp].item	   ; range check
	    cmp      ax,0
	    jl	     error		   ; if not zero, jump

	    cmp      ax,3		   ; covered by Int 11?
	    jg	     notint11
	    mov      bx,ax		   ; ax destroyed by int

	    int      11h		   ; get peripherals on the system

	    xchg     ax,bx		   ; restore ax

	    cmp      ax,0		   ; check number of printers??
	    jg	     notprint		   ; jump if not
	    mov      cl,14		   ; else, setup print bits
	    shr      bx,cl		   ; in returned data
	    jmp      short exit 	   ; then return

notprint:   cmp      ax,1		   ; check for RS232 adapters??
	    jg	     diskchk		   ; jump if not
	    mov      cl,4		   ; else, setup RS232 bits
	    shl      bx,cl		   ; clear top bits
	    mov      cl,13
	    shr      bx,cl		   ; shift back
	    jmp      short exit

diskchk:    cmp      ax,2		   ; check for disk request??
	    jg	     math		   ; jump, if not
	    mov      cl,8		   ; else setup disk bits
	    shl      bx,cl		   ; clear top bits
	    mov      cl,14
	    shr      bx,cl		   ; and shift back
	    inc      bl 		   ; 0=1 drive, etc.
	    jmp      short exit

math:	    cmp      ax,3		   ; check for math coprocessor
	    jg	     notint11		   ; jump, if not
	    mov      cl,14		   ; else, setup math coprocessor
	    shl      bx,cl		   ; bits in return data
	    mov      cl,15
	    shr      bx,cl
	    jmp      short exit

notint11:   cmp      ax,4		  ; check for other valid item
	    je	     error
	    cmp      ax,5		  ; check for PC type ??
	    jg	     error		  ; jump if not so
	    push     es 		  ; else check for PC type
	    mov      dx,0f000h		  ; read model byte from RAM
	    mov      es,dx
	    mov      al,es:model_byte	  ;model byte
	    pop      es
	    sub      al,0fch		  ;AT value = FC
	    jmp      short exit 	  ;all done, return

error:	    mov      ax,inv_parm
	    jmp      short exit1

exit:	    sub      ax,ax		  ; set good return code
	    lds      si,[bp].data	  ; set return data area address
	    mov      byte ptr [si],bl	  ; save bit pattern in return
					  ; data area
exit1:	    Mexit			  ; pop registers
	    ret      size str - 6	  ; return

dosdevconfig endp

dosxxx	    ends

	    end
