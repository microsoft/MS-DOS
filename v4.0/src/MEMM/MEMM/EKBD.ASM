

	page	58,132
;******************************************************************************
	title	EKBD - get keyboard make codes
;******************************************************************************
;   (C) Copyright MICROSOFT Corp. 1986
;
;  Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;  Module:	EKBD - basic keyboard handler for error handler routine
;
;  Version:	0.04
;
;  Date :	June 10,1986
;
;  Author:
;
;******************************************************************************
;
;  CHANGES:
;
;    DATE     REVISION			DESCRIPTION
;  --------   --------	 ------------------------------------------------------
;  06/10/86   Original
;  06/28/86   0.02	 Name change from MEMM386 to MEMM
;  07/06/86   0.04	 Changed assumes to DGROUP
;
;******************************************************************************
;
;  Functional description:  Return keyboard code while ignoring any break
;			    or command codes.
;
;******************************************************************************
	page
.386P
;
	include vdmseg.inc
	include kbd.inc
;******************************************************************************
;	Public Declarations
;******************************************************************************
;
	public	egetc			; get a character
	public	WaitKBD 		; wait for keyboard ready
;******************************************************************************
;	Externs
;******************************************************************************
_TEXT	segment
_TEXT	ends

_DATA	segment
_DATA	ends
;
;******************************************************************************
;	Equates
;******************************************************************************
;
;
;******************************************************************************
;		LOCAL DATA
;******************************************************************************
_DATA	segment
_DATA	ends
;
;******************************************************************************
;
;	egetc - read a character from keyboard
;
;	entry:	NONE
;
;	exit:	al = make code
;		ZF = 0
;
;		or ZF = 1 if no code available
;
;	used:	none
;
;	stack:
;
;******************************************************************************
_TEXT	segment
	ASSUME	CS:_TEXT, DS:DGROUP, ES:DGROUP
egetc	proc	near
;
	in	al,KbStatus		; get status
	test	al,1			; q: is there anything out there?
	jz	kret			; n: return
;					; y: disable keyboard
	call	WaitKBD 		; wait til 8042 ready for input
	mov	al,0adh 		; disable keyboard interface
	out	KbStatus,al
	in	al,KbData		; get character
	cmp	al,7fh			; q: break or control word?
	jae	ign_chr 		; y: ignore it
	cmp	al,80h			; clear ZF
	jmp	enaKB			; go enable keyboard
ign_chr:
	mov	al,0			; return an invalid character
					; but preserve ZF
enaKB:
	pushf				; save flags
	push	ax			; save character
	call	WaitKBD
	mov	al,0aeh 		; enable keyboard
	out	KbStatus,al
	pop	ax
	popf
kret:
	ret
egetc	endp
;
;******************************************************************************
;
;	WaitKBD - wait for status to indicate ready for new command
;
;	entry:	NONE
;
;	exit:	NONE
;
;	used:	al
;
;	stack:
;
;******************************************************************************
WaitKBD proc	near
	push	cx
	xor	cx,cx			; do 65536 times
wait:
	in	al,KbStatus
	test	al,BufFull		; q: busy?
	loopnz	wait			; y: try again
;
	pop	cx			; n: return
	ret
WaitKBD endp

_TEXT	ENDS
	END
