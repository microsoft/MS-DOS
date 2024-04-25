

page	58,132
;******************************************************************************
	title	RetReal - Return-To-Real routine(s) for the 386
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   RetReal - Return-To-Real routine(s) for the 386
;
;   Version:  0.04
;
;   Date:     February 20, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   02/20/86  Original
;   05/12/86  A 	Cleanup and segment reorganization
;   06/01/86		Removed Real386a (loadall version) and left only
;			RetReal via PE bit
;   06/21/86  0.02	Saved Eax
;   06/28/86  0.02	Name changed from MEMM386 to MEMM
;   07/02/86  0.03	Reset TSS busy bit
;   07/05/86  0.04	Added Real_Seg label for _TEXT fixup
;   07/06/86  0.04	changed assume to DGROUP
;
;******************************************************************************
;
;   Functional Description:
;
;   This module contains the routine RetReal which goes from Ring 0 protected
;   mode to Real Mode by resetting the PE bit (and the PG bit).
;
;   NOTE: this module only works on the B0 and later parts.  The A2 part
;	  will leave the CS non writeable.
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	RetReal
	public	Real_Seg

	page
;******************************************************************************
;			I N C L U D E	F I L E S
;******************************************************************************

include VDMSEG.INC
include VDMSEL.INC
include INSTR386.INC
include OEMDEP.INC

;
;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************
;
_DATA	segment
	extrn	Active_Status:byte
_DATA	ends

_TEXT	segment

	extrn	SelToSeg:near		; selector to segment	(I286)
	extrn	DisableA20:near 	; disable A20 line	(MODESW)

_TEXT	ends
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
FALSE	equ	0
TRUE	equ	not FALSE

	page
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************

_TEXT	segment
	assume	cs:_TEXT, ds:DGROUP

;***	RetReal - cause a 386 mode switch to real mode
;
;	ENTRY	Ring 0 protected mode
;		CLI - interrupts disabled
;		NMI should also be disabled here.
ifndef NOHIMEM
;		FS = Diag segment selector
endif
;
;	EXIT	Real Mode
;		DGROUP:[Active_Status] = 0
;		CS = _TEXT
;		DS = ES = FS = GS = DGROUP
;		SS = stack segment
;		general registers preserved
;		flags modified
;		interrupts disabled
;		A20 disabled
ifndef NOHIMEM
;		high system memory LOCKED
endif
;
;	USES	see exit conditions above
;
;	DESCRIPTION
;
real_gdt	label	qword
real_idt	dw	0FFFFh		; limit
		dw	0000		; base
		dw	0000
		dw	0000		; just in case

	public	RetReal
RetReal proc near
	PUSH_EAX			; save two scratch registers
	push	bx
	cli				; disable ints

	smsw	ax			;check to see if we are in real mode
	test	ax,1
	jnz	rl386_a 		;jump if in protected mode
	sti
	pop	bx
	POP_EAX
	ret				;otherwise return

rl386_a:

;
;   reset TSS busy bit before returning to Real Mode
;
	mov	ax, GDTD_GSEL
	mov	es, ax			; ES:0 = ptr to gdt

	and	byte ptr ES:[TSS_GSEL + 5], 11111101B

;
;   lock high system ROM before returning to real
;
	HwTabLock

;
;	First save return ss:sp. We have to translate
;	the current ss (a selector) into a segment number.
;	Calculate a real mode segment corresponding to the
;	current protected mode stack selector base address.
;
;	We get the base address from the descriptor table,
;	and convert it to a paragraph number.
;
	mov	bx,ss			; bx = selector for stack
	call	SelToSeg		; AX = segment number for SS
	mov	bx,ax			; BX = setup stack segment
;
;
;  Intel shows DS,ES,FS,GS,and SS set up to make sure 'Real Mode' type
;  access rights, and limit are installed.  In this program, that happens
;  to already be the case, but for general purposeness, VDMD_GSEL fits
;  the bill.
;
	mov	ax,VDMD_GSEL		; selector with real mode attributes
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	MOV_FS_AX
	MOV_GS_AX
;
;  Intel recommends the following code for resetting the PE bit.  Mine
;  works OK, but maybe it's not general purpose enough (I was counting
;  on knowing that paging wasn't enabled).
;
	MOV_EAX_CR0			;  get CR0

	OP32
	and	ax,0FFFEh		; force real mode and shut down paging
	dw	07FFFh			; (mov eax,07FFFFFFEh)

	MOV_CR0_EAX			; set CR0

					; flush prefetched instructions with:
	db	0EAh			; Far Jump opcode
	dw	offset _TEXT:rl386_b	; destination offset
Real_Seg	label	word
	dw	_TEXT			; destination segment
rl386_b:
	OP32				; load up full IDT address
	lidt	qword ptr cs:[real_idt]

	sti

	MOV_EAX_CR3			; get CR3
	MOV_CR3_EAX			; set CR3 => clear TLB

	mov	ss,bx			; ss = real mode stack segment
	mov	ax,DGROUP
	mov	ds,ax
	mov	es,ax
	MOV_FS_AX
	MOV_GS_AX

	mov	[Active_Status],0	; rest VDM status

	call	DisableA20		; disable A20 line

	pop	bx
	POP_EAX
	ret				; *** RETURN ***
RetReal endp

_TEXT	ends
	end
