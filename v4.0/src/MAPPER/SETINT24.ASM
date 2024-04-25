;0
page 80,132

;**********************************************************************
;*
;*   MODULE:   set_int24_vector
;*
;*   Critical error handler for C programs BACKUP and RESTORE
;*
;*********************************************************************
;------------------------------------------------------------;;;;AN000;
databuff  segment   public  'databuff'                       ;;;;AN000;
databuff   ends 					     ;;;;AN000;
;------------------------------------------------------------;;;;AN000;


dosxxx	segment byte public 'dos'                               ;AN000;
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing	;AN000;


	    public   set_int24_vector				;AN000;
	    .sall						;AN000;
	    .xlist						;AN000;
	    include  macros.inc 				;AN000;
	    .list						;AN000;

str	    struc						;AN000;
old_bp	    dw	     ?						;AN000;
Return	    dd	     ?						;AN000;
Flag	    dw	     ?						;AN000;
str	    ends						;AN000;


set_int24_vector   proc  far					;AN000;
	Enter	set_int24_vector				;AN000;

	mov	ax,seg databuff 				;AN000;
	mov	ds,ax						;AN000;
	assume	ds:databuff					;AN000;

	mov	ax,03524h		;Get Int24 Vector	;AN000;
	int	21h						;AN000;
					;Save it
	mov	word ptr cs:OldInt24,bx 			;AN000;
	mov	word ptr cs:OldInt24+2,es			;AN000;

					;Get address of my Int24 Handler
	mov	dx,cs						;AN000;
	mov	ds,dx						;AN000;
	mov	dx,offset AppErrorHandler			;AN000;

	mov	ax,02524H	       ;Set new INT24 vector	;AN000;
	int	21h						;AN000;

	xor	ax,ax		       ;Set good error return	;AN000;

exit:	mexit			       ; pop all registers	;AN000;
	ret	size str - 6	       ; return 		;AN000;

set_int24_vector    endp					;AN000;





;-------------------------------------------------------
;
;	    ****   Error Handler  ******
;
;-------------------------------------------------------
Ignore		equ	0		;AN000;
Retry		equ	1		;AN000;
Abort		equ	2		;AN000;
Fail		equ	3		;AN000;

OldInt24   dd	?			;AN000; ;save old interrupt handler address  ;;;

AppErrorHandler    proc    near 	;AN000;
	pushf				;AN000;
	call	dword ptr cs:OldInt24	;AN000; Get user to respond
	cmp	al,Abort		;AN000; For any resonse other than Abort
	jne	rett			;AN000;  retry the operation

	int	023h			;AN000;

rett:					;AN000;
	iret				;AN000; return to caller
AppErrorHandler 	endp		;AN000;
;-------------------------------------------------------
;-------------------------------------------------------

dosxxx	    ends			;AN000;
	   end				;AN000;
