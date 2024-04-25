;0
page 80,132
;
title CP/DOS DosQCurDisk mapper

	    extrn    dosqcurdir:far
	    extrn    dosdevconfig:far

buffer	segment word public 'buffer'
drive	dw	?	      ; driver number
buffr	db	20 dup(?)     ; buffer
bufflng dw	20	      ; buffer length
map	dw	2 dup(?)      ; map area
dsket	db	?	      ;
buffer	ends



dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;
;**********************************************************************
;*
;*   MODULE:   dosqcurdisk
;*
;*   FILE NAME: dos037.asm
;*
;*   CALLING SEQUENCE:
;*
;*	 push@	   dword   drive number return location pointer
;*	 push@	   dword   drive map area  pointer
;*	 call	   dosqcurdisk
;*
;*   MODULES CALLED:  PC-DOS Int 21h, AH=19h, get current disk
;*		      Rom Bios Int 11 (called by DosDevConfig)
;*
;*********************************************************************
;
	    public   dosqcurdisk
	    .sall
	    .xlist
	    include  macros.inc
	    .list

str	    struc
old_bp	    dw	     ?
return	    dd	     ?
Drvmap	    dd	     ?	     ; drive map pointer
Drvnbr	    dd	     ?	     ; drive number
str	    ends


defdrive	db	?	; Save area for default drive -->RW



dosqcurdisk proc     far

	    Enter    Dosqcurdisk	 ; push registers

	    mov      ah,19h		 ; get current default drive
	    int      21h
	    mov      defdrive,al	; Save default drive

	    cbw 			 ; fill ax with drive #
	    lds      si,[bp].drvnbr	 ; output address
	    inc      ax 		 ; set drive A = 1
	    mov      word ptr [si],ax	 ; drive number

	    mov      ax,buffer		 ; prepare data segment
	    mov      ds,ax		 ; register for calls

	    assume   ds:buffer

	    lea      di,dsket		 ; diskette address
	    push     ds
	    push     di
	    mov      ax,2		 ; request diskette count
	    push     ax
	    sub      ax,ax		 ; reserved parm
	    push     ax

	    call     dosdevconfig	 ; get number of drives

	    cmp      dsket,0		 ; if none, jump
	    je	     nodisk
	    stc 			 ; else set flag
	    jmp      short dskbits

nodisk:     clc 			 ; clear flag

dskbits:    mov      map+2,0		 ; clear output areas
	    mov      map,0
	    pushf			 ; save carry status, then
	    rcr      map+2,1		 ; set flags for devices
	    popf			 ; A and B
	    rcr      map+2,1

	    mov      drive,2		 ; start at C  -->RW --> Changed 3 to 2
	    mov      di,2		 ; start with low-order
loopx:
	mov	ah,0eh			; DOS Select Disk -->RW
	mov	dx,drive		; Drive number in DL -->RW
	int	021h			;  -->RW

	mov	ah,019h 		; DOS Get Current Disk -->RW
	int	021h			;  -->RW
	xor	ah,ah			; Clear AH -->RW
	cmp	ax,drive		; Drive now in AX -->RW

	    je	     driveok		 ; drive at this number
	    clc 			 ; else drive no good
	    jmp      short rotate

driveok:    stc

rotate:     rcr      map[di],1		 ; shift bit in
	    inc      drive
	    cmp      drive,17		 ; finished first word?
	    jl	     loopx		  ; if no, jump
	    mov      di,0		 ; if so, switch to high
	    cmp      drive,26		 ; order word, and check
	    jle      loopx		  ; for last drive.
				;restore current drive
	mov	ah,0eh			; DOS Select Disk -->RW
	mov	dl,defdrive		; Drive number in DL -->RW
	int	021h			;  -->RW

	    mov      cl,6		 ; only ten bits used
	    shr      map,cl		 ; in high-order word.
	    mov      ax,map		 ; Now put in registers
	    mov      bx,map+2		 ; for shift into output
	    push     cs 		 ; area.
	    pop      ds
	    lds      si,[bp].drvmap	 ;
	    mov      [si],ax
	    mov      [si]+2,bx		 ;
					 ; Set good return code -->RW
	    xor      ax,ax
exit:	    mexit			 ; pop registers
	    ret      size str - 6	 ; return

dosqcurdisk endp

dosxxx	    ends

	    end
