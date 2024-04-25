

page	58,132
;******************************************************************************
	title	UTIL - general MEMM utilities
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   UTIL - utilities
;
;   Version:  0.04
;
;   Date:     June 11, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   06/11/86  Original	from i286.asm
;   06/18/86  0.01	in GoVirtual - added code to init VDM state variables
;   06/25/86  0.02	in GoVirtual - more DiagByte state variable.
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   06/29/86  0.02	Changed check code for ROM write protect state
;   07/01/86  0.03	Added call to InitDMA in GoVirtual
;   07/05/86  0.04	Moved code to InitLOCK
;   07/05/86  0.04	Added FarGoVirtual and moved IsReal to PRINT.ASM
;   07/06/86  0.04	Changed assume to DGROUP and moved stack out of DGROUP
;
;******************************************************************************
;
;   Functional Description:
;
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p

	public	GoVirtual
	public	FarGoVirtual
	public	SelToSeg

;******************************************************************************
;	D E F I N E S
;******************************************************************************
	include VDMseg.inc
	include VDMsel.inc
	include desc.inc
	include instr386.inc
	include oemdep.inc

FALSE		equ	0
TRUE		equ	not FALSE

;******************************************************************************
;	E X T E R N A L   R E F E R E N C E S
;******************************************************************************
_DATA	SEGMENT

extrn	TEXT_Seg:word		; segment for _TEXT
extrn	GDT_Seg:word		; segment for GDT
extrn	TSS_Seg:word		; segment address of TSS
extrn	Page_Dir:word		; 32-bit address of Page Directory Table

extrn	Active_Status:byte

_DATA	ENDS

_TEXT SEGMENT

extrn	InitDMA:near		; (elimtrap.asm)
extrn	EnableA20:near		; (modesw.asm)
extrn	A20_Trap_Init:near	; (a20trap.asm)
extrn	RR_Trap_Init:near	; (RRTrap.asm)
extrn	OEM_Trap_Init:near	; (OEMTrap.asm)

_TEXT	ENDS

STACK	segment
	extrn	kstack_top:byte
STACK	ends

ifndef	NOHIMEM

R_CODE	segment
extrn	InitLock:far
R_CODE	ends

endif

	page
;******************************************************************************
;		S E G M E N T	D E F I N I T I O N S
;******************************************************************************

;******************************************************************************
;		_TEXT segment
;******************************************************************************

_TEXT SEGMENT
	assume cs:_TEXT, ds:DGROUP, es:DGROUP

;******************************************************************************
;	FarGoVirtual - far link for GoVirtual
;
;	NOTE: this is a FAR routine.
;
;    ENTRY:	Real Mode
;		DS = DGROUP
;
;    EXIT:	Virtual Mode
;		VDM state variables initialized
;
;    USED:	none
;
;******************************************************************************
FarGoVirtual	proc	far
	call	GoVirtual
	ret
FarGoVirtual	endp

;******************************************************************************
;	GoVirtual - go to virtual mode
;
;    ENTRY:	Real Mode
;		DS = DGROUP
;
;    EXIT:	Virtual Mode
;		VDM state variables initialized
;
;    USED:	none
;
;******************************************************************************
GoVirtual	proc	near
;
	PUSH_EAX
	push	bx
	push	bp
	push	ds
	push	es
	PUSH_FS
	PUSH_GS
;
	cli				; interrupts OFF
;
;   init VDM state variables
;
	push	es
	mov	ax,[TSS_Seg]
	mov	es,ax			; ES -> TSS
	call	A20_Trap_Init		; init a20 line watch
	call	RR_Trap_Init		; init return to real watch
	call	OEM_Trap_Init		; init any other I/O port watches
	pop	es

	mov	[Active_Status],1

	call	InitDMA 		; init DMA watcher

ifndef	NOHIMEM
	call	FAR PTR InitLOCK	; init status of TABLE lock
endif

;
;	mask off master 8259 to prevent all interrupts during setup
;
	call	MaskIntAll		; Mask all interrupts
;
;	Set the CPU into 386 protected mode.
;
;	The following CPU registers are changed to have values
;	appropriate to protected mode operation:
;
;		CS, DS, ES, SS, TR, LDT, Flags, MSW, GDT, IDT
	call	EnableA20		; enable A20 address line

;
;    load CR3 register for paging
;
	OP32
	mov	ax,[Page_Dir]		; EAX = 32-bit address of Page Dir

	MOV_CR3_EAX

;
;   load gdt and ldt base registers
;
	mov	ax,[GDT_Seg]
	mov	ds, ax			; DS:0 = ptr to gdt
	lgdt	qword ptr ds:[GDTD_GSEL]
	lidt	qword ptr ds:[IDTD_GSEL]
;
;   go protected and enable paging - turn on bits in CR0
;
	MOV_EAX_CR0

	OP32
	or	ax,MSW_PROTECT	; or EAX,imm32	- enable PE bit - PROT MODE
	dw	8000h		;		- enable PG bit - PAGING

	MOV_CR0_EAX

;	far jump to flush prefetch, and reload CS

	db	0eah			; far jmp opcode
	dw	offset _TEXT:pm1	; offset
	dw	VDMC_GSEL		; selector
pm1:
;
;   We are now protected, set the Task Register and LDT Register
;
	mov	ax,TSS_GSEL
	ltr	ax

	xor	ax, ax			; LDT is null, not needed
	lldt	ax
;
;   save current stack pointer for after return to VM
;
	mov	bx,ss				; BX = saved SS
	mov	bp,sp				; BP = saved SP
;
;	set the stack selector to RING 0 stack
;
	mov	ax, VDMS_GSEL
	mov	ss, ax
	mov	sp, offset STACK:kstack_top
;
;	now reload DS and ES to be data selectors for protected mode
;
	mov	ax, VDMD_GSEL
	mov	ds, ax
	assume	ds:DGROUP
	mov	es, ax
	assume	es:DGROUP

;
; reset NT bit so IRET won't attempt a task switch
;
	pushf
	pop	ax
	and	ax,0FFFh
	push	ax
	popf
;
; build stack frame for IRET into virtual mode
;
	push	0
	push	0			; GS
	push	0
	push	0			; FS
	push	0
	push	seg DGROUP		; DS	(DGROUP for variable access)
	push	0
	push	0			; ES

	push	0
	push	bx			;* virtual mode SS

	push	0
	push	bp			;* virtual mode ESP

	push	2			; EFlags high, VM bit set
	push	3000h			;* EFlags low, NT = 0, IOPL=3, CLI

	push	0
	mov	ax, [TEXT_Seg]
	push	ax			; CS
	push	0
	mov	ax, offset _TEXT:VM_return
	push	ax			; IP

	OP32				; 32 bit operand size override
	iret

;
;	Enter Virtual Mode here
;
VM_return:
;
; re-enable interrupts
;
	call	RestIntMask		; Restore interrupt mask
	POP_GS
	POP_FS
	pop	es
	pop	ds
	pop	bp
	pop	bx
	POP_EAX
	ret
GoVirtual	endp


;**	SelToSeg - convert selector to a segment number
;
;	The protected mode selector value is converted to a
;	real mode segment number.
;
;	ENTRY	BX = selector
;	EXIT	AX = segment number
;	USES	BX, Flags, other regs preserved
;
;	WARNING This code only works on a 286.	It can be
;		called only in protected mode.

SelToSeg proc near
	push	ds
	mov	ax,LDTD_GSEL
	test	bx,TAB_LDT		; is the selector in the LDT?
	jnz	sts_addr		;  yes,
	mov	ax,GDTD_GSEL		; selector is in the GDT
sts_addr:
	mov	ds,ax
	and	bl,0F8h

	mov	ax,word ptr ds:[bx + 2] ; low 16 bits of base address
	mov	bh,ds:[bx + 4]		; high 8 bits of base address
	shr	ax,4
	shl	bh,4
	mov	bl,0
	add	ax,bx			; AX = segment number for selector
	pop	ds
	ret
SelToSeg endp

_TEXT	ends

	end
