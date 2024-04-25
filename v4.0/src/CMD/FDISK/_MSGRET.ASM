page	       60,132
name	       _msgret
title	       C to Message Retriever
;-------------------------------------------------------------------
;
;	MODULE: 	_msgret
;
;	PURPOSE:	Supplies an interface between C programs and
;			the DOS 3.3 message retriever
;
;	CALLING FORMAT:
;			msgret(&inregs,&outregs);
;
;	DATE:		5-21-87
;
;-------------------------------------------------------------------

	INCLUDE SYSMSG.INC		;PERMIT SYSTEM MESSAGE HANDLER DEFINITION ;AC010;

	MSG_UTILNAME <FDISK>		;IDENTIFY THE COMPONENT 		;AC010;

;-------------------------------------------------------------------
;-------------------------------------------------------------------


_TEXT	SEGMENT BYTE PUBLIC 'CODE'					;AC010;
_TEXT	ENDS								;AC010;
_DATA	SEGMENT WORD PUBLIC 'DATA'					;AC010;
_DATA	ENDS								;AC010;
CONST	SEGMENT WORD PUBLIC 'CONST'					;AC010;
CONST	ENDS								;AC010;
_BSS	SEGMENT WORD PUBLIC 'BSS'					;AC010;
_BSS	ENDS								;AC010;

DGROUP	GROUP	CONST, _BSS, _DATA					;AC010;
	ASSUME	CS: DGROUP, DS: DGROUP, SS: DGROUP, ES: NOTHING 	;AC010;

	public	data_sysloadmsg 					;AC010;
	public	data_sysdispmsg 					;AC010;
	public	data_sysgetmsg						;AC010;

_DATA	SEGMENT 							;AC010;

	MSG_SERVICES <MSGDATA>						;AC010;
	MSG_SERVICES <LOADmsg,FARmsg>					;AC010;
	MSG_SERVICES <DISPLAYmsg,GETmsg,CHARmsg,NUMmsg> 		;AC010;
	MSG_SERVICES <FDISK.CLA,FDISK.CLB,FDISK.CL1,FDISK.CL2,FDISK.CTL> ;AC010;		       ;AC010;


data_sysloadmsg proc far

	push	bp			; save user's base pointer      ;AC010;
	mov	bp,sp			; set bp to current sp		;AC010;
	push	di			; save some registers		;AC010;
	push	si							;AC010;

;	copy C inregs into proper registers

	mov	di,[bp+4+4]		  ; fix di (arg 0)		;AC010;

;-------------------------------------------------------------------

	mov	ax,[di+0ah]		; load di			;AC010;
	push	ax			; the di value from inregs is now on stack ;AC010;

	mov	ax,[di+00]		; get inregs.x.ax		;AC010;
	mov	bx,[di+02]		; get inregs.x.bx		;AC010;
	mov	cx,[di+04]		; get inregs.x.cx		;AC010;
	mov	dx,[di+06]		; get inregs.x.dx		;AC010;
	mov	si,[di+08]		; get inregs.x.si		;AC010;
	pop	di			; get inregs.x.di from stack	;AC010;

	push	bp			; save base pointer		;AC010;

;-------------------------------------------------------------------

	call	sysloadmsg		; call the message retriever	;AC010;

;-------------------------------------------------------------------

	pop	bp			; restore base pointer		;AC010;
	push	di			; the di value from call is now on stack ;AC010;
	mov	di,[bp+6+4]		  ; fix di (arg 1)		;AC010;

	mov	[di+00],ax		; load outregs.x.ax		;AC010;
	mov	[di+02],bx		; load outregs.x.bx		;AC010;
	mov	[di+04],cx		; load outregs.x.cx		;AC010;
	mov	[di+06],dx		; load outregs.x.dx		;AC010;
	mov	[di+08],si		; load outregs.x.si		;AC010;

	lahf				; get flags into ax		;AC010;
	mov	al,ah			; move into low byte		;AC010;
	mov	[di+0ch],ax		; load outregs.x.cflag		;AC010;

	pop	ax			; get di from stack		;AC010;
	mov	[di+0ah],ax		; load outregs.x.di		;AC010;

;-------------------------------------------------------------------

	pop	si			; restore registers		;AC010;
	pop	di							;AC010;
	mov	sp,bp			; restore sp			;AC010;
	pop	bp			; restore user's bp             ;AC010;
	ret

data_sysloadmsg endp							;AC010;


data_sysdispmsg proc far						;AC010;

	push	bp			; save user's base pointer      ;AC010;
	mov	bp,sp			; set bp to current sp		;AC010;
	push	di			; save some registers		;AC010;
	push	si							;AC010;

;	copy C inregs into proper registers

	mov	di,[bp+4+4]		  ; fix di (arg 0)		;AC010;

;-------------------------------------------------------------------

	mov	ax,[di+0ah]		; load di			;AC010;
	push	ax			; the di value from inregs is now on stack ;AC010;

	mov	ax,[di+00]		; get inregs.x.ax		;AC010;
	mov	bx,[di+02]		; get inregs.x.bx		;AC010;
	mov	cx,[di+04]		; get inregs.x.cx		;AC010;
	mov	dx,[di+06]		; get inregs.x.dx		;AC010;
	mov	si,[di+08]		; get inregs.x.si		;AC010;
	pop	di			; get inregs.x.di from stack	;AC010;

	push	bp			; save base pointer		;AC010;

;-------------------------------------------------------------------

	call	sysdispmsg						;AC010;

;-------------------------------------------------------------------

	pop	bp			; restore base pointer		;AC010;
	push	di			; the di value from call is now on stack ;AC010;
	mov	di,[bp+6+4]		  ; fix di (arg 1)		;AC010;

	mov	[di+00],ax		; load outregs.x.ax		;AC010;
	mov	[di+02],bx		; load outregs.x.bx		;AC010;
	mov	[di+04],cx		; load outregs.x.cx		;AC010;
	mov	[di+06],dx		; load outregs.x.dx		;AC010;
	mov	[di+08],si		; load outregs.x.si		;AC010;

	lahf				; get flags into ax		;AC010;
	mov	al,ah			; move into low byte		;AC010;
	mov	[di+0ch],ax		; load outregs.x.cflag		;AC010;

	pop	ax			; get di from stack		;AC010;
	mov	[di+0ah],ax		; load outregs.x.di		;AC010;

;-------------------------------------------------------------------

	pop	si			; restore registers		;AC010;
	pop	di							;AC010;
	mov	sp,bp			; restore sp			;AC010;
	pop	bp			; restore user's bp             ;AC010;
	ret								;AC010;

data_sysdispmsg endp							;AC010;


data_sysgetmsg	proc far						;AC010;

	push	bp			; save user's base pointer      ;AC010;
	mov	bp,sp			; set bp to current sp		;AC010;
	push	di			; save some registers		;AC010;
	push	si							;AC010;

;	copy C inregs into proper registers

	mov	di,[bp+4+4]		  ; fix di (arg 0)		;AC010;

;-------------------------------------------------------------------

	mov	ax,[di+0ah]		; load di			;AC010;
	push	ax			; the di value from inregs is now on stack ;AC010;

	mov	ax,[di+00]		; get inregs.x.ax		;AC010;
	mov	bx,[di+02]		; get inregs.x.bx		;AC010;
	mov	cx,[di+04]		; get inregs.x.cx		;AC010;
	mov	dx,[di+06]		; get inregs.x.dx		;AC010;
	mov	si,[di+08]		; get inregs.x.si		;AC010;
	pop	di			; get inregs.x.di from stack	;AC010;

	push	bp			; save base pointer		;AC010;

;-------------------------------------------------------------------

	call	sysgetmsg		; call the message retriever	;AC010;

;-------------------------------------------------------------------

	pop	bp			; restore base pointer		;AC010;
	push	di			; the di value from call is now on stack ;AC010;
	mov	di,[bp+6+4]		  ; fix di (arg 1)		;AC010;

	push	ax			; save ax			;AC010;
	mov	[di+00],es		; load segregs.es		;AC010;
	mov	[di+06],ds		; load outregs.ds		;AC010;
	pop	ax			; restore ax			;AC010;

	pop	di			; restore di			;AC010;
	push	di			; save it			;AC010;
	mov	di,[bp+8+4]		  ; fix di (arg 2)		;AC010;
	mov	[di+00],ax		; load outregs.x.ax		;AC010;
	mov	[di+02],bx		; load outregs.x.bx		;AC010;
	mov	[di+04],cx		; load outregs.x.cx		;AC010;
	mov	[di+06],dx		; load outregs.x.dx		;AC010;
	mov	[di+08],si		; load outregs.x.si		;AC010;

	lahf				; get flags into ax		;AC010;
	mov	al,ah			; move into low byte		;AC010;
	mov	[di+0ch],ax		; load outregs.x.cflag		;AC010;

	pop	ax			; get di from stack		;AC010;
	mov	[di+0ah],ax		; load outregs.x.di		;AC010;

;-------------------------------------------------------------------

	pop	si			; restore registers		;AC010;
	pop	di							;AC010;
	mov	sp,bp			; restore sp			;AC010;
	pop	bp			; restore user's bp             ;AC010;
	ret								;AC010;

data_sysgetmsg	endp							;AC010;


_DATA	ends			; end code segment			;AC010;

_TEXT	SEGMENT 							;AC010;

	assume cs:_TEXT 						;AC010;

	public	_sysdispmsg						;AC010;
	public	_sysloadmsg						;AC010;
	public	_sysgetmsg						;AC010;

_sysdispmsg	proc	near						;AC010;
		call	data_sysdispmsg 				;AC010;
		ret							;AC010;
_sysdispmsg	endp							;AC010;

_sysloadmsg	proc	near						;AC010;
		call	data_sysloadmsg 				;AC010;
		ret							;AC010;
_sysloadmsg	endp							;AC010;

_sysgetmsg	proc	near						;AC010;
		call	data_sysgetmsg					;AC010;
		ret							;AC010;
_sysgetmsg	endp							;AC010;

_TEXT	ENDS								;AC010;
	end								;AC010;

