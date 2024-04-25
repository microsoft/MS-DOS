
BREAK	MACRO	subtitle
	SUBTTL	subtitle
	PAGE
ENDM


;
;******************************************************************************
; Message Macro Definitions
;******************************************************************************
;

      EXTRN Display_Interface:near


;-----------------------------------------------------------------------------

Message macro	Message_Name			;				;AN000;
						;
	mov	dx,offset dg:Message_Name	;				;AN000;
	call	Display_Interface		;				;AN000;
						;
	endm					;				;AN000;

;-----------------------------------------------------------------------------

Parse_Message macro				;				;AN000;

						;
	push	ds
	mov	dx,dg
	mov	ds,dx
	mov	word ptr Parse_Error_Msg,ax	;				;AN000;
	mov	dx,offset dg:Parse_Error_Msg	;				;AN000;
	call	Display_Interface		;				;AN000;
	pop	ds				;
	endm					;				;AN000;

;-----------------------------------------------------------------------------

Extended_Message macro				;				;AN000;
						;

	push	ds
	mov	dx,dg
	mov	ds,dx
	mov	word ptr Extended_Error_Msg,ax	  ;				  ;AN000;
	mov	dx,offset dg:Extended_Error_Msg    ;				   ;AN000;
	call	Display_Interface		;				;AN000;
	pop	ds
	endm					;				;AN000;
;
;*****************************************************************************
; General Macro's
;*****************************************************************************
;

Procedure	macro	Proc_Name,Seg_Name	;				;AN000;
						;
Public	Proc_Name				;				;AN000;
Proc_Name    proc				;				;AN000;

	endm					;				;AN000;
;-----------------------------------------------------------------------------

DOS_Call	macro	Function		;				;AN000;
						;
	mov	ah,Function			;				;AN000;
	int	21h				;				;AN000;
						;
	endm					;				;AN000;

;-----------------------------------------------------------------------------

Popff	macro

Assume	cs:DG

	jmp	$+3
	iret
	push	cs
	call	$-2

Assume	cs:code

	endm

;-----------------------------------------------------------------------------

Set_Data_Segment     macro

	push	ax
	mov	ax,dg				;Point to data segment
	mov	ds,ax				;
	push	ds
	pop	es
	pop	ax

	.LALL
	assume	ds:dg,es:dg
	.XALL
	endm

