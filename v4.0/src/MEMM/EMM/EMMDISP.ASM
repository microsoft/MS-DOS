page	58,132
;******************************************************************************
	title	EMMDISP - EMM dispatcher
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:	CEMM.EXE - COMPAQ Expanded Memory Manager 386 Driver
;		EMMLIB.LIB - Expanded Memory Manager Functions Library
;
;   Module:	EMM Dispatcher
;
;   Version:	0.04
;
;   Date:	May 17, 1986
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION                  DESCRIPTION
;   --------  --------  -------------------------------------------------------
;   5/17/86	0	initial code
;   6/14/86		modified registers on stack for exit and removed call
;			to _emm_init (SBP).
;   6/28/86    0.02	Name change from CEMM386 to CEMM (SBP).
;   7/06/86    0.04	Changed data assumes to DGROUP (SBP).
;   5/25/88             Changed function range check to cover LIM 4.0 (PC)
;******************************************************************************
;
;   Functional Description:
;	This module serves to trap Int 67h, place
;	arguments on the stack and call the associated
;	function 
;
;
;******************************************************************************
.lfcond					; list false conditionals
.386p

;******************************************************************************
;	P U B L I C S
;******************************************************************************
	public	int67_Entry
	public	dispatch_vector

;******************************************************************************
;	I N C L U D E S
;******************************************************************************
	include	vdmseg.inc
	include vdmsel.inc
	include	emmdef.inc
;
;******************************************************************************
;	D E F I N E S
;******************************************************************************
;
FALSE		equ	0
TRUE		equ	not FALSE
CR		equ	0dh
LF		equ	0ah

mkvect	MACRO	name
	extrn	_&name:near
	dw	offset _TEXT:_&name
endm

;******************************************************************************
;	E X T E R N A L S 
;******************************************************************************

_DATA	SEGMENT
extrn	_EMMstatus:word
extrn	Active_Status:byte
extrn	Auto_Mode:byte
extrn	_regp:word
_DATA	ENDS


;******************************************************************************
;	local data
;******************************************************************************
;
; remove duplicated variables (defined in emmdata.asm)
;
;_DATA	SEGMENT
;
;_regp	label	word
;	dw	0
;	dw	0
;
;_DATA	ENDS

_TEXT	SEGMENT
assume	cs:_text,ds:DGROUP,ss:DGROUP,es:DGROUP
;
	db	'PxB'
;

dispatch_vector	label word
	mkvect	GetStatus
	mkvect	GetPageFrameAddress
	mkvect	GetUnallocatedPageCount
	mkvect	AllocatePages
	mkvect	MapHandlePage
	mkvect	DeallocatePages
	mkvect	GetEMMVersion
	mkvect	SavePageMap
	mkvect	RestorePageMap
	mkvect	GetPageMappingRegisterIOArray
	mkvect	GetLogicalToPhysicalPageTrans
	mkvect	GetEMMHandleCount
	mkvect	GetEMMHandlePages
	mkvect	GetAllEMMHandlePages
	mkvect	GetSetPageMap
	mkvect	GetSetPartial			; AH = 4Fh
						; 4.0 Functions...
	mkvect	MapHandleArray			; AH = 50h
	mkvect	ReallocatePages
	mkvect	GetSetHandleAttribute
	mkvect	GetSetHandleName
	mkvect	GetHandleDirectory
	mkvect	AlterMapAndJump
	mkvect	AlterMapAndCall
	mkvect	MoveExchangeMemory
	mkvect	GetMappablePAddrArray
	mkvect	GetInformation
	mkvect	AllocateRawPages
	mkvect	AlternateMapRegisterSet
	mkvect	PrepareForWarmBoot
	mkvect	OSDisable

;*************************************
;	int67_Entry(PFlag,DS,ES) - entry point for int 67 (EMM functions)
;
;	unsigned	PFlag;	/* non-zero = protected mode, else */
;			   	/*    virtual or real mode */
;	unsigned	DS;	/* DS segment value on entry to int67 */
;	unsigned	ES;	/* ES segment value on entry to int67 */
;
;	ENTRY:
;	    REAL or VIRTUAL mode
;		DS = DGROUP segment
;	    PROTECTED mode
;		DS = VDMD_GSEL
;
; At the point of the indirect call,
; The stack looks as follows:
;
;
;	+-------+
;	|  FS	|		+2CH	<--- entry FS segment
;	+-------+
;	|  GS	|		+2AH	<--- entry GS segment
;	+-------+
;	|  ES	|		+28H	<--- entry ES segment
;	+-------+
;	|  DS	|		+26h	<--- entry DS segment
;	+-------+
;	| PFlag	|		+24h	<--- protected mode flag
;	+-------+
;	|  CS   |		+22h	<--- from FAR call to int67_handler
;	+-------+
;	|  ret	|		+20h	<--- CS:ret
;	+-------+
;	| EAX	|		+1C	<-+- from PUSH ALL
;	+-------+			  |
;	| ECX	|		+18	  V
;	+-------+
;	| EDX	|		+14
;	+-------+
;	| EBX	|		+10
;	+-------+
;	| ESP	|		+C
;	+-------+
;	| EBP	|		+8
;	+-------+
;	| ESI	|		+4
;	+-------+
;	| EDI	|		<--- regp
;	+-------+
;
;*************************************
int67_Entry	proc	far
	pushad			; save all regs
	mov	bp,sp		;  SS:[BP] points to stack frame
;
	mov	[_regp],sp	; regp points to regs on stack
	mov	[_regp+2],ss	; regp now has a far ptr to regs

	;
	; validate function code
	;
	sub	ah,40h		; check if entry code too small
	jb	i67_inv_exit	; if so, error exit
	cmp	ah,(5Dh-40h)	; check if entry code too big
	ja	i67_inv_exit	; if so, error exit
	
	;
	; check for VDM off
	;
	cmp	[Auto_Mode],0		;Q: Auto mode on ?
	jne	i67_jump		;  Y: go ahead
	cmp	[Active_Status],0	;  N:Q: are we ON ?
	je	i67_off_err		;      N: exit with error code

	;
	; call through the jump table
	;
i67_jump:
	xchg	ah,al		; AL = function code
	mov	si,ax
	xchg	ah,al		; AH = function code again
	and	si,00FFh	; SI = function #
	shl	si,1		; SI = table offset
	call	CS:dispatch_vector[si] ; call function

ok_exit:
	popad			; restore all regs
	ret			; bye!

i67_off_err:				; set h/w error
	mov	byte ptr [bp.rAX+1],EMM_HW_MALFUNCTION
	jmp	ok_exit

i67_inv_exit:				; set invalid function code error
	mov	byte ptr [bp.rAX+1],INVALID_FUNCTION
	jmp	ok_exit

int67_entry	endp

_TEXT	ENDS
END
