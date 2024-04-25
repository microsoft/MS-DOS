

page	58,132
;******************************************************************************
	title	InitDeb - initialize debugger
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   InitDeb - initialize debugger
;
;   Version:  0.04
;
;   Date:     June 16,1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   06/16/86  Original	from VDM MAIN.ASM module
;   06/28/86  0.02	Name changed from MEMM386 to MEMM
;   07/06/86  0.04	Changed assume to DGROUP
;
;******************************************************************************
;
;   Functional Description:
;
;	This routine is linked in when linking with the kernel debugger.
;    InitDeb calls the debugger initialization routine.
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
;******************************************************************************
;	P U B L I C S
;******************************************************************************

	public	InitDeb

;******************************************************************************
;	D E F I N E S
;******************************************************************************
	include VDMseg.inc
	include VDMsel.inc

FALSE		equ	0
TRUE		equ	not FALSE
CR		equ	0dh
LF		equ	0ah

MASTER_IMR	equ	21h		; mask port for master 8259

;
; Definition of the packet used in debug initialization. A pointer to
; this structure is passed to Debug_Entry.
;
DebugInit	struc
	CSseg		dw	?		;Real mode code segment
	DSseg		dw	?		;Real mode data segment
	CSsel		dw	?		;Prot mode code selector
	DSsel		dw	?		;Prot mode data selector
	SpareSel1	dw	?		;Prot mode alias selector 1
	SpareSel2	dw	?		;Prot mode alias selector 2
	GDTalias	dw	?		;Prot mode GDT r/w alias
	ProtIDTaddr	dq	?		;Prot mode IDT base & limit
	RealIDTaddr	dq	?		;Real mode IDT base & limit
	BrkFlag 	db	?		;TRUE if break to debugger
	ComFlag 	db	?		;TRUE if com1, FALSE if com2
DebugInit	ends


;******************************************************************************
;	E X T E R N A L   R E F E R E N C E S
;******************************************************************************
ifndef	NoBugMode
dcode	segment
extrn	_Debug_Entry:far	; (debinit.asm)
dcode	ends
endif

_DATA	SEGMENT

extrn	GDT_Seg:word

_DATA ENDS

;******************************************************************************
;	S E G M E N T	D E F I N I T I O N S
;******************************************************************************

_DATA	SEGMENT

InitData	DebugInit	<>

_DATA ENDS

;
;   code
;
LAST SEGMENT

	assume cs:LAST, ds:DGROUP, es:DGROUP

;******************************************************************************
;	InitDeb - initialize kernel debugger
;
;
;    ENTRY:	Real Mode
;		DS = DGROUP
;		AL = 00h => dont't break on debug init
;		AL = FFh => break on debug init
;
;    EXIT:	Real Mode
;		Kernel debugger initialized
;
;    USED:	none
;
;******************************************************************************
InitDeb proc	near
;
ifndef	NoBugMode
	pusha
	push	ds
	push	es
;
	push	ds
	pop	es		; ES = data
;
	mov	di, offset DGROUP:InitData

	mov	bx, dcode
	mov	[di].CSseg, bx
	mov	bx, ddata
	mov	[di].DSseg, bx
	mov	[di].CSsel, DEBC_GSEL
	mov	[di].DSsel, DEBD_GSEL
	mov	[di].SpareSel1, DEBW1_GSEL
	mov	[di].SpareSel2, DEBW2_GSEL
	mov	[di].GDTalias, GDTD_GSEL
	mov	[di].BrkFlag, al		; ? break on entry ?
	mov	[di].ComFlag, FALSE		; com2

	sidt	[di].RealIDTaddr

	push	ds
	push	di
	mov	ax, [GDT_Seg]
	mov	ds, ax

	lgdt	qword ptr ds:[GDTD_GSEL]

	mov	si, IDTD_GSEL
	mov	cx, 6
	lea	di, [di].ProtIDTaddr
	cld
	rep movsb
	pop	di
	pop	ds

	call	_Debug_Entry
;
; and return
;
	pop	es
	pop	ds
	popa
endif
	ret
InitDeb endp


LAST	ends

	END
