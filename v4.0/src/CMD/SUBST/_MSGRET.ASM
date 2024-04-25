page	60,132
name	_msgret
title	C	to Message Retriever
;-------------------------------------------------------------------
;
;	MODULE: 	_msgret
;
;	PURPOSE:	Supplies an interface between C programs and
;			the DOS 3.3 message retriever
;
;	CALLING FORMAT:
;			sysloadmsg(&inregs,&outregs);
;			sysgetmsg(&inregs,&outregs);
;			sysdispmsg(&inregs,&outregs);
;
;	DATE:		5-21-87
;
;-------------------------------------------------------------------

	INCLUDE SYSMSG.INC		;PERMIT SYSTEM MESSAGE HANDLER DEFINITION;AN000;

	MSG_UTILNAME <SUBST>		;IDENTIFY THE COMPONENT 		;AN000;

	.8087									;AN000;
_TEXT	SEGMENT BYTE PUBLIC 'CODE'						;AN000;
_TEXT	ENDS									;AN000;
_DATA	SEGMENT WORD PUBLIC 'DATA'						;AN000;
_DATA	ENDS									;AN000;
CONST	SEGMENT WORD PUBLIC 'CONST'						;AN000;
CONST	ENDS									;AN000;
_BSS	SEGMENT WORD PUBLIC 'BSS'						;AN000;
_BSS	ENDS									;AN000;
DGROUP	GROUP	CONST, _BSS, _DATA						;AN000;
	ASSUME	CS: _TEXT, DS: _TEXT, SS: DGROUP, ES: DGROUP			;AN000;


	public	_sysloadmsg							;AN000;
	public	_sysgetmsg							;AN000;
	public	_sysdispmsg							;AN000;

;-------------------------------------------------------------------
;-------------------------------------------------------------------

_DATA	segment 								;AN000;
.XLIST										;AN000;
.XCREF										;AN000;
	MSG_SERVICES <MSGDATA>		;DATA AREA FOR THE MESSAGE HANDLER	;AN000;
.LIST										;AN000;
.CREF										;AN000;
_DATA	ends									;AN000;


_TEXT	segment 								;AN000;

;-------------------------------------------------------------------

; =  =	=  =  =  =  =  =  =  =	=  =

					;DEFAULT=CHECK DOS VERSION		;AN000;
					;DEFAULT=NEARmsg			;AN000;
					;DEFAULT=INPUTmsg			;AN000;
					;DEFAULT=NUMmsg 			;AN000;
					;DEFAULT=NO TIMEmsg			;AN000;
					;DEFAULT=NO DATEmsg			;AN000;
;	MSG_SERVICES <LOADmsg,GETmsg,DISPLAYmsg,CHARmsg,NUMmsg,TIMEmsg,DATEmsg,INPUTmsg,FARmsg>;AN000;
;	MSG_SERVICES <SUBST.CLA,SUBST.CL1,SUBST.CL2> ;MSG TEXT			;AN000;
.XLIST										;AN000;
.XCREF										;AN000;
;	MSG_SERVICES <MSGDATA>		;DATA AREA FOR THE MESSAGE HANDLER	;AN000;
	MSG_SERVICES <LOADmsg,GETmsg,DISPLAYmsg,CHARmsg,NUMmsg,TIMEmsg,DATEmsg,INPUTmsg,FARmsg>;AN000;
	MSG_SERVICES <SUBST.CLA,SUBST.CL1,SUBST.CL2> ;MSG TEXT			;AN000;
.LIST										;AN000;
.CREF										;AN000;
;-------------------------------------------------------------------

_sysloadmsg proc near								;AN000;

	push	bp			; save user's base pointer              ;AN000;
	mov	bp,sp			; set bp to current sp			;AN000;
	push	di			; save some registers			;AN000;
	push	si								;AN000;

;	copy C inregs into proper registers

	mov	di,[bp+4]		; fix di (arg 0)			;AN000;

;-------------------------------------------------------------------

	mov	ax,[di+0ah]		; load di				;AN000;
	push	ax			; the di value from inregs is now on stack;AN000;

	mov	ax,[di+00]		; get inregs.x.ax			;AN000;
	mov	bx,[di+02]		; get inregs.x.bx			;AN000;
	mov	cx,[di+04]		; get inregs.x.cx			;AN000;
	mov	dx,[di+06]		; get inregs.x.dx			;AN000;
	mov	si,[di+08]		; get inregs.x.si			;AN000;
	pop	di			; get inregs.x.di from stack		;AN000;

	push	bp			; save base pointer			;AN000;

;-------------------------------------------------------------------
	call	sysloadmsg		; call the message retriever		;AN000;
;-------------------------------------------------------------------

	pop	bp			; restore base pointer			;AN000;
	push	di			; the di value from call is now on stack;AN000;
	mov	di,[bp+6]		; fix di (arg 1)			;AN000;

	mov	[di+00],ax		; load outregs.x.ax			;AN000;
	mov	[di+02],bx		; load outregs.x.bx			;AN000;
	mov	[di+04],cx		; load outregs.x.cx			;AN000;
	mov	[di+06],dx		; load outregs.x.dx			;AN000;
	mov	[di+08],si		; load outregs.x.si			;AN000;

	lahf				; get flags into ax			;AN000;
	mov	al,ah			; move into low byte			;AN000;
	mov	[di+0ch],ax		; load outregs.x.cflag			;AN000;

	pop	ax			; get di from stack			;AN000;
	mov	[di+0ah],ax		; load outregs.x.di			;AN000;

;-------------------------------------------------------------------

	pop	si			; restore registers			;AN000;
	pop	di								;AN000;
	mov	sp,bp			; restore sp				;AN000;
	pop	bp			; restore user's bp                     ;AN000;
	ret									;AN000;

_sysloadmsg endp								;AN000;


_sysgetmsg proc near								;AN000;

	push	bp			; save user's base pointer              ;AN000;
	mov	bp,sp			; set bp to current sp			;AN000;
	push	di			; save some registers			;AN000;
	push	si								;AN000;
										;AN000;
;	copy C inregs into proper registers

	mov	di,[bp+4]		; fix di (arg 0)			;AN000;

;-------------------------------------------------------------------

	mov	ax,[di+0ah]		; load di				;AN000;
	push	ax			; the di value from inregs is now on stack;AN000;

	mov	ax,[di+00]		; get inregs.x.ax			;AN000;
	mov	bx,[di+02]		; get inregs.x.bx			;AN000;
	mov	cx,[di+04]		; get inregs.x.cx			;AN000;
	mov	dx,[di+06]		; get inregs.x.dx			;AN000;
	mov	si,[di+08]		; get inregs.x.si			;AN000;
	pop	di			; get inregs.x.di from stack		;AN000;

	push	bp			; save base pointer			;AN000;

;-------------------------------------------------------------------
	call	sysgetmsg		; call the message retriever		;AN000;
;-------------------------------------------------------------------

	pop	bp			; restore base pointer			;AN000;
	push	di			; the di value from call is now on stack;AN000;
	mov	di,[bp+6]		; fix di (arg 1)			;AN000;

	mov	[di+00],ax		; load outregs.x.ax			;AN000;
	mov	[di+02],bx		; load outregs.x.bx			;AN000;
	mov	[di+04],cx		; load outregs.x.cx			;AN000;
	mov	[di+06],dx		; load outregs.x.dx			;AN000;
	mov	[di+08],si		; load outregs.x.si			;AN000;

	lahf				; get flags into ax			;AN000;
	mov	al,ah			; move into low byte			;AN000;
	mov	[di+0ch],ax		; load outregs.x.cflag			;AN000;

	pop	ax			; get di from stack			;AN000;
	mov	[di+0ah],ax		; load outregs.x.di			;AN000;

;-------------------------------------------------------------------

	pop	si			; restore registers			;AN000;
	pop	di								;AN000;
	mov	sp,bp			; restore sp				;AN000;
	pop	bp			; restore user's bp                     ;AN000;
	ret									;AN000;

_sysgetmsg endp 								;AN000;

_sysdispmsg proc near								;AN000;

	push	bp			; save user's base pointer              ;AN000;
	mov	bp,sp			; set bp to current sp			;AN000;
	push	di			; save some registers			;AN000;
	push	si								;AN000;

;	copy C inregs into proper registers

	mov	di,[bp+4]		; fix di (arg 0)			;AN000;

;-------------------------------------------------------------------

	mov	ax,[di+0ah]		; load di				;AN000;
	push	ax			; the di value from inregs is now on stack;AN000;

	mov	ax,[di+00]		; get inregs.x.ax			;AN000;
	mov	bx,[di+02]		; get inregs.x.bx			;AN000;
	mov	cx,[di+04]		; get inregs.x.cx			;AN000;
	mov	dx,[di+06]		; get inregs.x.dx			;AN000;
	mov	si,[di+08]		; get inregs.x.si			;AN000;
	pop	di			; get inregs.x.di from stack		;AN000;

	push	bp			; save base pointer			;AN000;

;-------------------------------------------------------------------
	call	sysdispmsg		; call the message retriever		;AN000;
;-------------------------------------------------------------------

	pop	bp			; restore base pointer			;AN000;
	push	di			; the di value from call is now on stack;AN000;
	mov	di,[bp+6]		; fix di (arg 1)			;AN000;

	mov	[di+00],ax		; load outregs.x.ax			;AN000;
	mov	[di+02],bx		; load outregs.x.bx			;AN000;
	mov	[di+04],cx		; load outregs.x.cx			;AN000;
	mov	[di+06],dx		; load outregs.x.dx			;AN000;
	mov	[di+08],si		; load outregs.x.si			;AN000;

	lahf				; get flags into ax			;AN000;
	mov	al,ah			; move into low byte			;AN000;
	mov	[di+0ch],ax		; load outregs.x.cflag			;AN000;

	pop	ax			; get di from stack			;AN000;
	mov	[di+0ah],ax		; load outregs.x.di			;AN000;

;-------------------------------------------------------------------

	pop	si			; restore registers			;AN000;
	pop	di								;AN000;
	mov	sp,bp			; restore sp				;AN000;
	pop	bp			; restore user's bp                     ;AN000;
	ret									;AN000;

_sysdispmsg endp								;AN000;

include msgdcl.inc

_TEXT	ends				; end code segment			;AN000;
	end									;AN000;

