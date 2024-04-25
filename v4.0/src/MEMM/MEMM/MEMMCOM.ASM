

	page	58,132
;******************************************************************************
	title	MEMMCOM - main module for MEMM.COM
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.COM - MICROSOFT Expanded Memory Manager 386 Utility
;
;   Module:   MEMMCOM - main module for MEMM.COM
;
;   Version:  0.02
;
;   Date:     June 4, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   06/04/86  Original
;   06/21/86  0.02	Added CLD to Inst_Chk
;   06/28/86  0.02	Name change from MEMM386.COM to MEMM.COM
;
;******************************************************************************
;
;   Functional Description:
;	MEMM.COM which allows the user to poll or set the operating mode
;   of the MEMM device driver.
;	Syntax:
;		MEMM [ ON | OFF | AUTO ]
;
;	If the user specifies no arguments, MEMM.COM will return the
;   current mode of the MEMM device driver.
;
;	ON
;   If the user specifies ON, MEMM.COM enables the MEMM driver;
;   expanded memory is available and the processor is in virtual mode.
;
;	OFF
;   If the user specifies OFF, MEMM.COM disables the MEMM driver;
;   expanded memory is not available and the processor is in real mode.
;
;	AUTO
;   If the user specifies AUTO, MEMM.COM enables the MEMM driver's auto
;   mode.  In auto mode, the driver will enable and disable itself
;   "automatically" (depending on accesses to the EMM functions).
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	EMM386
	public	Inst_chk
	public	ELIM_link
;
;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************
_TEXT	segment byte use16 public 'CODE'
	extrn	onf_func:near
_TEXT	ends
abs0	segment use16 at 0000h

	org	67h*4		; EMM function interrupt
int67	dw	?		; offset of vector
	dw	?		; segment of vector
abs0	ends


	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;

MSDOS		equ	21h			; MS-DOS function call

;
; Device driver header for MEMM
;
emm_hdr 	STRUC
;
	DW		?			;Null segment address
	DW		?			;Null offset address
	DW		?			;Attribute - Char
	DW		?			;Strategy routine entry
	DW		?			;Interrupt routine entry
	DB		'EMMXXXX0'		;Character device name
;
; GENERAL FUNCTIONS ENTRY POINT
; ELIM_Entry is a entry point for executing general MEMM
; functions. (e.g. ON, OFF function).
;
ELIM_Entry_off	dw	?		; general entry point

;
;	       MEMM signature
;
memmsig db	?			; MEMM signature

emm_hdr 	ends

;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************
;
_TEXT	segment byte use16 public 'CODE'
	assume	cs:_TEXT, ds:_TEXT, es:_TEXT, ss:_TEXT
	org	81h
cmd_line	dw	?		; pointer to command line
;
;******************************************************************************
;			M O D U L E   E N T R Y   P O I N T
;******************************************************************************
;
;   Standard .COM entry conditions are assumed
;
	org	100h
EMM386	proc	near
	jmp	start
;******************************************************************************
;			L O C A L   D A T A   A R E A
;******************************************************************************
;

oursig	db	'MICROSOFT EXPANDED MEMORY MANAGER 386'
SIG_LENGTH	equ	(this byte - oursig)
;
;	define double word to store segment/offset of status routine for far call
;
status_loc	label	dword
entry_off	dw	0		; store offset for far call
entry_seg	dw	0		; store segment for far call
;

start:
	push	cs
	pop	ds
	push	cs
	pop	es

;
	cli
	mov	sp,offset Stack_Top
	sti
;
	cld
;
	mov	di,offset cmd_line	; es:di = command line pointer
	call	onf_func		; do the on/off function

	mov	ax,4C00h
	int	MSDOS			; exit to DOS

EMM386		endp

page
;******************************************************************************
;	ELIM_link - Call ELIM_Entry status routine via the status_loc
;
;	ENTRY: [status_loc] contains the far address
;
;	EXIT: ?
;
;	USED: none
;
;******************************************************************************
ELIM_link	proc	near
	call	status_loc
	ret
ELIM_link	endp
page
;******************************************************************************
;	Inst_chk - Check to see if MEMM is already installed
;
;	ENTRY: int 67 vector
;
;	EXIT: ax = 0 if not already installed
;	      ax = 1 if MEMM is already installed
;	      If MEMM is installed, then
;			[entry_seg] = segment of driver header
;			[entry_off] = offset of status routine in MEMM
;
;	USED: none
;
;******************************************************************************
Inst_chk	proc		near
	push	di			; save di
	push	si			; and si
	push	ds			; and ds
	push	es			; and es
	push	cx			; and cx
;
	xor	ax,ax			; put segment 0000h in ds
	mov	ds,ax
	assume	ds:abs0 		; assume ds is abs0
	mov	ax,[int67+2]		; get segment pointed to by int 67
	mov	es,ax

	assume	ds:_TEXT			; update assume
	push	cs
	pop	ds			; set DS = _TEXT

	mov	di,offset memmsig	; MEMM signature
	mov	si,offset oursig	; point to our signature
	xor	ax,ax			; initialize to not found
	mov	cx,SIG_LENGTH		; length to compare
	cld				; strings foward
	repe	cmpsb			; q: is the MEMM signature out there?
	jne	not_inst		; n: return zero
	inc	ax			; y: return one
	mov	[entry_seg],es		; save segment for far call
	xor	di,di
	mov	cx,es:[ELIM_Entry_off]	 ; save offset for far call
	mov	[entry_off],cx
not_inst:
	pop	cx
	pop	es
	pop	ds
	pop	si
	pop	di
	ret
Inst_chk	endp


	db	100h dup (0)
Stack_Top:
	db	0

_TEXT	ends

	end	EMM386
