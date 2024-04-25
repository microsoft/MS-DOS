;0
page 80,132

title CP/DOS DosError   mapper


;**********************************************************************
;*
;*   MODULE:   doserror
;*
;*   ;AN000; PCDOS 4.00 ptm p2629 - Drive not ready yields FORMAT TERMINATED
;*
;*********************************************************************

SystemIsHandling      equ     1       ; system handles errors
AppIsHandling	      equ     0       ; application handle errors

;------------------------------------------------------------;;;
databuff  segment   public  'databuff'                       ;;;
							     ;;;
errorstate db	SystemIsHandling			     ;;;
							     ;;;
databuff   ends 					     ;;;
;------------------------------------------------------------;;;


dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing


	    public   doserror
	    .sall
	    .xlist
	    include  macros.inc
	    .list

str	    struc
old_bp	    dw	     ?
Return	    dd	     ?
Flag	    dw	     ?		; error flag;  0 = APP handle error
str	    ends		;	       1 = System handle error


DosError   proc  far
	Enter	 doserror		; Push registers

	mov	 ax,seg databuff	;-->RW
	mov	 ds,ax			;-->RW
	assume	 ds:databuff		;-->RW

	mov	 ax,[bp].flag		; get error flag
	cmp	 ax,AppIsHandling	; check who should handle errors
	je	 apperrorhandle 	; branch if application handles error
	cmp	 ax,SystemIsHandling	; system handle error ??
	je	 syserrorhandle 	; branch if true

	mov	 ax,1			; else, set error code
	jmp	 exit			; return

SysErrorHandle:

	cmp	 errorstate,SystemIsHandling	; system handles error ??
	jne	 setsys 			; branch if not
	xor	 ax,ax			   ; else set good return code
	jmp	 exit			; return

setsys: mov	 errorstate,SystemIsHandling	 ; set flag for system
	lds	 dx,cs:prevadrs

	mov	 ax,02524H
	int	 21h			; set new vector

	xor	ax,ax			; set good return code
	jmp	exit			; return


AppErrorHandle:
	cmp	 errorstate,AppIsHandling    ; application handle errors
	jne	 setapp 		     ; branch if true

	xor	 ax,ax			; else, set good error code
	jmp	 exit			; return

setapp: mov	 errorstate,AppIsHandling ; indicate app handles error
	mov	 ax,03524h		; Get Interrupt 24 Vector
	int	 21h

	mov	 word ptr cs:prevadrs+0,bx     ; save it in prevadrs
	mov	 word ptr cs:prevadrs+2,es

	mov	dx,cs
	mov	ds,dx
	mov	dx,offset ApiErrorHandler   ; put error interrupt handler
					    ; as new vector
	mov	 ax,02524H
	int	 21h		       ;set new vector

	xor	 ax,ax		       ; set good error return

exit:	mexit			       ; pop all registers
	ret	 size str - 6	       ; return

DosError    endp

	page





;-------------------------------------------------------
; ****	 Error Handler	******
; This routine will get control on  a hard error, returning an error.
; If error is Drive not ready, keep retrying until drive IS ready or ^C
;-------------------------------------------------------
DriveNotReady	equ	2		;AN000;

Ignore		equ	0		;AN000;
Retry		equ	1		;AN000;
Terminate	equ	2		;AN000;
Fail		equ	3		;AN000;

prevadrs   dd	?			;AN000; ;save old interrupt handler address  ;;;

ApiErrorHandler    proc    near 	;AN000;
	pushf				;AN000;
	cmp	di,DriveNotReady	;AN000; Is it Drive Not Ready?
	jne	popf_and_fail_it	;AN000; If not, fail call and return

Drive_Not_Ready:			;AN000; The drive is not ready!
	call	dword ptr cs:prevadrs	;AN000; Get user to respond
	cmp	al,Terminate		;AN000; For any resonse other than terminate,
	jne	retry_it		;AN000;  retry the operation
	int	023h			;AN000; Otherwise terminate via INT 023h

popf_and_fail_it:			;AN000; Fail the operation
	pop	ax			;AN000; Remove garbage from stack
	mov	al,Fail 		;AN000; Func code for fail
	jmp	rett			;AN000;
retry_it:				;AN000; Retry the operation
	mov	al,Retry		;AN000; Func code for retry
rett:					;AN000;
	iret				;AN000; return
Apierrorhandler 	endp
;-------------------------------------------------------
;-------------------------------------------------------

dosxxx	    ends
	   end
