;
;******************************************************************************
; Message Macro Definitions
;******************************************************************************
;

      EXTRN Display_Interface:near


;-----------------------------------------------------------------------------

Message macro	Message_Name			;				;AN000;
						;
	mov	dx,offset dg:Message_Name     ; 			      ;AN000;
	call	Display_Interface		;				;AN000;
	endm					;				;AN000;

;-----------------------------------------------------------------------------

Parse_Message macro				;				;AN000;

						;
	push	ds				;				;AN000;bgb
	mov	dx,dg				;				;AN000;bgb
	mov	ds,dx				;				;AN000;bgb
	mov	word ptr Parse_Error_Msg,ax	;				;AN000;
	mov	dx,offset dg:Parse_Error_Msg	   ;				   ;AN000;
	call	Display_Interface		;				;AN000;
	pop	ds				;				;AN000;bgb
	endm					;				;AN000;

;-----------------------------------------------------------------------------

Extended_Message macro				;				;AN000;
						;

	push	ds				;				;AN000;bgb
	mov	dx,dg				;				;AN000;bgb
	mov	ds,dx				;				;AN000;bgb
	mov	word ptr Ext_Error_Msg,ax	;				;AN000;
	mov	dx,offset dg:Ext_Error_Msg    ; 			      ;AN000;
	call	Display_Interface		;				;AN000;
	pop	ds				;				;AN000;bgb
	endm					;				;AN000;

;
;*****************************************************************************
; General Macro's
;*****************************************************************************
;

Procedure	macro	Proc_Name		;				;AN000;
						;
Public	Proc_Name				;				;AN000;
Proc_Name    proc				;				;AN000;
						;
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

	jmp	$+3
	iret
	push	cs
	call	$-2

	endm


;-----------------------------------------------------------------------------

Set_Data_Segment     macro

	push	ax
	mov	ax,dg				;Point to data segment
	mov	ds,ax				;
assume	ds:dg,es:dg
	push	ds
	pop	es
	pop	ax


	endm



