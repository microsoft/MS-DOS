

page	58,132
;******************************************************************************
	TITLE	i286.asm - Support Routines for protected mode system
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   i286.asm - Support Routines for protected mode system
;
;   Version:  0.02
;
;   Date:     January 31, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   01/31/86  Original
;   02/05/86  A 	added is286, is386
;   05/12/86  B 	Cleanup and segment reorganization
;   06/03/86  C 	added push/pop es to Init_GDT and changed Ring 0
;			stack to STACK0 and STACK0_SIZE.
;   06/28/86  0.02	Name changed from MEMM386 to MEMM
;
;******************************************************************************
;
;   Functional Description:
;
;	Anthony Short
;	26th Dec 1985
;
;	DESCRIPTION
;
;	These routines manage the various 286 memory management
;	tables and manipulate descriptors and selectors.
;
;	The routines which deal with descriptors use the following
;	register usage conventions:
;
;	BX	- selector of required descriptor. The selector may
;		  have RPL bits present, the routines ignore them.
;
;	CX	- SIZE IN BYTES of segment. NOTE: descriptors contain
;		  limits, not sizes (limit = size - 1). Since everyone
;		  else talks sizes, these routines do too, and do their
;		  own conversion.
;
;	DX	- second selector when needed
;
;	AH	- access rights byte
;
;	AL, DX	- 24 bit physical address
;
;	ES:0	- pointer to the desired descriptor table.
;
;	All the routines which manipulate descriptors are callable
;	in both real and protected mode.
;
;	In general all registers are preserved.
;
;	The following routines are provided:
;
;		SetDescInfo	- set descriptor information
;		SetSegDesc	- set segment descriptor information
;
;		SegTo24 	- convert segment number to 24 bit addr
;		SegOffTo24	- convert seg:offset to 24 bit addr
;
;		InitGdt 	- set up parts of GDT which cannot easily
;				  be initialised statically.
;
;	WARNING This code is 286 specific, it will NOT run on an 8088.
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p


	include VDMseg.inc
	include VDMsel.inc
	include desc.inc

;******************************************************************************
;		E X T E R N A L  R E F E R E N C E S
;******************************************************************************
GDT	segment
	extrn	GDTLEN:abs
GDT	ends

IDT	segment
	extrn	IDTLEN:abs
IDT	ends

TSS	segment
	extrn	TSSLEN:abs
TSS	ends

LAST SEGMENT

    assume cs:LAST

;**	SetDescInfo - set descriptor information
;
;	The limit field of a specified descriptor is set.
;	  (limit = size - 1).
;	The base address of the specified descriptor is set.
;	The access field of the specified descriptor is set.
;
;	ENTRY	BX = selector
;		ES:0 = descriptor table to use
;		CX = limit
;		AL, DX = 24 bit base address
;		AH = access rights byte
;	EXIT	None
;	USES	Flags, other regs preserved
;
;	WARNING This code only works on a 286. It can be called in
;		either mode.

	public SetDescInfo
SetDescInfo proc near
	push	bx			; save selector
	and	bl,SEL_LOW_MASK

;	fill in the limit field

	mov	es:[bx],cx

;	fill in base address

	mov	es:[bx + 2],dx
	mov	es:[bx + 4],al

;	fill in access rights byte

	mov	es:[bx + 5],ah
	pop	bx
	ret
SetDescInfo endp


;**	SetSegDesc - set segment descriptor information
;
;	The limit field of a specified descriptor is set.
;	  (limit = size - 1).
;	The base address of the specified descriptor is set.
;	The access field of the specified descriptor is set.
;
;	ENTRY	BX = selector
;		ES:0 = descriptor table to use
;		CX = size
;		AL, DX = 24 bit base address
;		AH = access rights byte
;	EXIT	None
;	USES	Flags, other regs preserved
;
;	WARNING This code only works on a 286. It can be called in
;		either mode.

	public SetSegDesc
SetSegDesc proc near
	dec	cx			; convert size to limit
	call	SetDescInfo		; set descriptor information
	inc	cx			; restore size
	ret
SetSegDesc endp


;**	SegTo24 - convert segment to 24 bit physical address
;
;	The real mode segment number is convert to a 24 bit addr
;
;	ENTRY	AX = segment
;	EXIT	AL, DX = 24 bit physical address
;	USES	AH, Flags, other regs preserved
;
;	WARNING This code only works on a 286, it can be called in
;		either mode.
	public	SegTo24
SegTo24 proc near
	mov	dl,ah
	shr	dl,4			; DH = high byte of 24 bit addr
	xchg	ax,dx			; AH = high byte, DX = segment
	shl	dx,4			; DX = low word of 24 bit addr
	ret
SegTo24 endp


;**	SegOffTo24 - convert seg:off to 24 bit physical address
;
;	The specified real mode segment:offset is converted to
;	a 24 bit physical address.
;
;	ENTRY	AX = segment
;		DX = offset
;	EXIT	AL, DX = 24 bit physical address
;	USES	AH, Flags, other regs preserved.
;
;	WARNING This code only works on a 286. It can be called in
;		either mode.

	public SegOffTo24
SegOffTo24 proc near
	push	cx

;	Convert AX:DX into 24 bit addr in AL, DX

	mov	ch,ah
	shl	ax,4
	shr	ch,4			; CH = high byte
	add	dx,ax			; DX = low word
	mov	al,ch			; AL = high byte
	adc	al,0			; propagate cy from low word

	pop	cx
	ret
SegOffTo24 endp


	page
;******************************************************************************
;   IS286 - return type of processor (286 vs. 8088/86).  386 returns 286.
;	This routine relies on the documented behaviour of the PUSH SP
;	instruction as executed on the various processors.  This routine
;	may be called from any mode on any processor, provided a proper
;	stack exists.
;
;   ENTRY:  (none)
;   EXIT:   ZF = 1 if 8088/86
;	    ZF = 0 if 286/386
;   USED:   flags
;   STACK:  6 bytes
;------------------------------------------------------------------------------
	public	Is286
Is286	proc	near
	push	bp
	push	sp
	mov	bp,sp
	cmp	bp,[bp] 		; compare SP with saved SP
	pop	bp			; clean SP off stack
	pop	bp			; restore BP
	ret				; *** RETURN ***
Is286	endp
	page
;******************************************************************************
;   Is386 - return type of processor (386 vs. 8088/86/286).
;	This routine relies on Intel-approved code that takes advantage
;	of the documented behavior of the high nibble of the flag word
;	in the REAL MODE of the various processors.  The MSB (bit 15)
;	is always a one on the 8086 and 8088 and a zero on the 286 and
;	386.  Bit 14 (NT flag) and bits 13/12 (IOPL bit field) are
;	always zero on the 286, but can be set on the 386.
;
;	For future compatibility of this test, it is strongly recommended
;	that this specific instruction sequence be used.  The exit codes
;	can of course be changed to fit a particular need.
;
;	CALLABLE FROM REAL MODE ONLY - FAR ROUTINE
;
;   ENTRY:  (none)
;   EXIT:   STC if 8088/86/286
;	    CLC if 386
;   USED:   none
;   STACK:  6 bytes
;------------------------------------------------------------------------------
	public	Is386
Is386	proc	FAR
	push	ax
	pushf				; save entry flags
;
	xor	ax,ax			; 0000 into AX
	push	ax
	popf				; try to put that in the flags
	pushf
	pop	ax			; look at what really went into flags
	test	ax,08000h		;Q: was high bit set ?
	jnz	IsNot386_exit		;  Y: 8086/8088
	mov	ax,07000h		;  N: try to set the NT/IOPL bits
	push	ax
	popf				;      ... in the flags
	pushf
	pop	ax			; look at actual flags
	test	ax,07000h		; Q: any high bits set ?
	jz	IsNot386_exit		;   N: 80286
					;   Y: 80386
Is386_exit:
	popf				; restore flags
	clc				;  386
	jmp	short I386_exit 	; and leave

IsNot386_exit:
	popf				; restore flags
	stc				; not a 386

I386_exit:
	pop	ax
	ret				; *** RETURN ***

Is386	endp

LAST	ends


	end
