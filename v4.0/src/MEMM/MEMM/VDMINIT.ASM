

page	58,132
;******************************************************************************
	title	VDM_Init - VDM initialization module
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   VDM_Init - VDM initialization routine
;
;   Version:  0.05
;
;   Date:     June 3,1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   06/03/86  Original	from VDM MAIN.ASM module
;   06/16/86  0.01	Added code to dword align LL buffer
;   06/21/86  0.02	moved cld in init_pages
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   07/06/86  0.04	changed assume to DGROUP and moved stack out of
;			DGROUP
;   07/10/86  0.05	Init of RCODEA_GSEL
;   07/10/86  0.05	Added PageT_Seg
;   07/20/88		Removed debugger codes (pc)
;
;******************************************************************************
;
;   Functional Description:
;
;	This module is the general initialization module for the Virtual DOS
;   Monitor part of MEMM.  This module initializes the protected mode
;   GDT, IDT, TSS (and I/O BitMap), and the Page Tables.  This module also
;   initializes all variables used by the VDM code.  This module returns
;   to the calling routine in Virtual Mode.
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
;******************************************************************************
;	P U B L I C S
;******************************************************************************

	public	VDM_Init
	public	PageD_Seg
	public	PageT_Seg
	public	Page_Dir

;******************************************************************************
;	D E F I N E S
;******************************************************************************
	include VDMseg.inc
	include VDMsel.inc
	include desc.inc
	include instr386.inc
	include page.inc

FALSE		equ	0
TRUE		equ	not FALSE
CR		equ	0dh
LF		equ	0ah

;******************************************************************************
;	E X T E R N A L   R E F E R E N C E S
;******************************************************************************
_DATA	SEGMENT
extrn	P_TABLE_CNT:abs
extrn	ELOff:word		; offset of LL buffer
_DATA	ENDS

_TEXT SEGMENT

extrn	InitBitMap:far	; (vminit.asm)

_TEXT	ENDS

GDT	SEGMENT
extrn	GDTLEN:abs
GDT	ENDS

IDT	SEGMENT
extrn	IDTLEN:abs
IDT	ENDS

TSS	SEGMENT
extrn	TSSLEN:abs
TSS	ENDS

PAGESEG SEGMENT
extrn	Page_Area:byte
PAGESEG ENDS


LAST	SEGMENT
extrn	SetSegDesc:near
extrn	SegTo24:near
extrn	SetPageEntry:near
extrn	get_init_a20_state:near
extrn	OEM_Init_Diag_Page:near
LAST	ENDS

;******************************************************************************
;	S E G M E N T	D E F I N I T I O N S
;******************************************************************************

;
;  Ring 0 stack for VDM exception/int handling
;
STACK SEGMENT
stkstrt label	byte

	db	STACK0_SIZE dup(0)

	public	kstack_top
kstack_top	label	byte

	db	400h dup (0)
	public	exe_stack
exe_stack	label	byte

STACK ENDS

_DATA	SEGMENT

PageD_Seg	dw	0		; segment for Page Directory
PageT_Seg	dw	0		; segment for Page Tables
Page_Dir	dd	0		; 32 bit address of Page Directory

_DATA ENDS

;
;   code
;
LAST SEGMENT

	assume cs:LAST, ds:DGROUP, es:DGROUP

;******************************************************************************
;	VDM_Init - VDM initialization routine
;
;
;    ENTRY:	Real Mode
;		DS = DGROUP
;		GDT = GDT segment
;		TSS = TSS segment
;
;    EXIT:	Real Mode
;		VDM Tables initialized
;		TSS initialized
;
;    USED:	none
;
;******************************************************************************
VDM_Init	proc	near
;
	pushf
	pusha
	PUSH_EAX
	push	ds
	push	es
;
	push	ds
	pop	es		; ES = data
;
	cli
;
	call	InitGdt 		;;; initialize GDT descriptors
;
;  initialize Page Table, I/O Bit Map and LIM h/w emulator
;
	call	InitPages		;;; initialize paging tables
	call	InitBitMap		;;; initialize I/O Bit Map
;
;  initialize TSS,GDTR,IDTR
;
;	set ring 0 SS:SP in the TSS so we can take outer ring traps

	mov	ax, seg TSS
	mov	es,ax			; ES -> TSS
	xor	di,di			; ES:DI -> TSS

	mov	ES:[di.TSS386_SS0], VDMS_GSEL
	mov	word ptr ES:[di.TSS386_ESP0lo], offset STACK:kstack_top
	mov	word ptr ES:[di.TSS386_ESP0hi], 0

; now set CR3 in the TSS

	db	66h
	mov	ax,word ptr [Page_Dir]		; EAX = page dir 32 bit addr
	db	66h
	mov	word ptr ES:[di.TSS386_CR3],ax	; mov EAX into CR3 spot in TSS

;	clear the TSS busy flag

	mov	ax,seg GDT
	mov	es, ax			; DS:0 = ptr to gdt

	and	byte ptr ES:[TSS_GSEL + 5], 11111101B

;
;  dword align the LL buffer (move foward)
;
	mov	ax,[ELOff]
	and	ax,0003h		; MOD 4
	mov	bx,4
	sub	bx,ax			; BX = amount to add to dword align
	add	[ELOff],bx		;  dword align it...

;
; and return
;
	pop	es
	pop	ds
	POP_EAX
	popa
	popf
	ret
VDM_Init	endp

;**	InitGdt - initialise GDT
;
;	Some of the GDT is statically initialised. This routine
;	initialises the rest, except the LDT pointer which
;	changes dynamically, and the VDM stack which changes too.
;
;	ENTRY	GDT:0 = GDT to use.
;	EXIT	None
;	USES	All except BP
;
;	WARNING This code only works on a 286.
;		Designed to be called from real mode ONLY.

	public InitGdt
InitGdt proc near
	push	es

	mov	ax,GDT
	mov	es,ax			; ES:0 -> gdt

	mov	ax,GDT
	call	SegTo24
	mov	cx,GDTLEN
	mov	ah,D_DATA0
	mov	bx,GDTD_GSEL
	call	SetSegDesc		; Set up GDT alias descriptor

	mov	ax,IDT
	call	SegTo24
	mov	cx,IDTLEN
	mov	ah,D_DATA0
	mov	bx,IDTD_GSEL
	call	SetSegDesc		; Set up IDT alias descriptor

	mov	ax,TSS
	call	SegTo24
	mov	cx,TSSLEN
	mov	ah,D_386TSS0
	mov	bx,TSS_GSEL
	call	SetSegDesc		; Set up TSS descriptor

	mov	ah,D_DATA0
	mov	bx,TSSD_GSEL
	call	SetSegDesc		; Set up TSS alias descriptor

	mov	ax,seg _TEXT
	call	SegTo24
	mov	cx,0			; 0 = 64K size
	mov	ah,D_CODE0
	mov	bx,VDMC_GSEL
	call	SetSegDesc		; Set up VDM Code descriptor

	mov	ax,_TEXT
	call	SegTo24
	mov	cx,0			; 0 = 64K size
	mov	ah,D_DATA0
	mov	bx,VDMCA_GSEL
	call	SetSegDesc		; Set up VDM Code segment alias descr

	mov	ax,R_CODE
	call	SegTo24
	mov	cx,0			; 0 = 64K size
	mov	ah,D_DATA0
	mov	bx,RCODEA_GSEL
	call	SetSegDesc		; Set up R_CODE segment alias descriptor

	mov	ax,seg DGROUP
	call	SegTo24
	mov	cx,0			; 0 = 64K size
	mov	ah,D_DATA0
	mov	bx,VDMD_GSEL
	call	SetSegDesc		; Set up VDM Data descriptor

	mov	ax, seg STACK		; set up Ring 0 stack
	call	SegTo24
	mov	cx, offset STACK:kstack_top
	mov	ah, D_DATA0
	mov	bx, VDMS_GSEL
	call	SetSegDesc

	pop	es
	ret
InitGdt endp

;**	InitPages - initialize Page Directory and Table
;
;	This routine initializes a page directory and a page table.
;	Both of these are aligned on a physical page boundary by
;	starting them at the nearest bndry. Thus, the page table area
;	must be large enough to allow this alignment.
;
;	The page dir and table set up by this routine maps the linear
;	addresses for Virtual mode programs into physical addresses using
;	the following scheme.
;	Linear Addr		Physical Addr
;	00000000h - 000FFFFFh	00000000h - 000FFFFFh
;	00100000h - 0010FFFFh	00000000h - 0000FFFFh  (64k wraparound)
;	00110000h - 0100FFFFh	00100000h - 00FFFFFFh  (top 15Meg of phys)
;
;	ISP,PC:  The above was totally unnecessary.  When the A20 is turned
;		 off the 64k at 1M is anyway unaccessible.  A better mapping
;		 has been implemented here:
;
;	Linear Addr		Physical Addr
;	00000000h - 000FFFFFh	00000000h - 000FFFFFh
;	00100000h - 0010FFFFh	00000000h - 0000FFFFh  (64k wraparound)
;	00110000h - 01000000h	00110000h - 01000000h  (top 15Meg of phys)
;	01000000h - 0100ffffh	xxxx0000h - xxxxffffh  (Done in OEMPROC)
;
;
;	ENTRY	PAGESEG:Page_Area = pointer to page table area.
;		DS = DGROUP
;	EXIT	DS:PageD_Seg = seg ptr for page directory.
;		DS:PageT_Seg = seg ptr for page tables
;		DS:Page_Dir = 32 bit addr for page directory.
;	USES	none
;
;	WARNING This code only works on a 286/386.
;		Designed to be called from real mode ONLY.

	public InitPages
InitPages	proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	es
	cld					; strings foward
;
;  get physical pointer to nearest page
;
	mov	ax,offset PAGESEG:Page_Area
	add	ax,15
	shr	ax,4			; AX = seg offset for page area
	mov	bx,PAGESEG		; PAGESEG is on a 256 boundary
	add	ax,bx			; AX = seg offset for page area
	add	ax,0FFh 		; 0FFh = # of paras in page - 1
	xor	al,al			; AX = seg addr for page align
	mov	[PageD_Seg],ax		; save it
;
	xor	di,di
	mov	es,ax			; ES:DI = ptr to Page Directory
;
	mov	dl,ah
	shr	dl,4			; DL = bits 16 - 19
	xor	dh,dh			; DX = bits 16 - 31
	shl	ah,4			; AX = bits 0 - 15
	mov	word ptr [Page_Dir],AX	; DX,AX = 32 bit addr of Page Directory
	mov	word ptr [Page_Dir+2],DX	; save it
;
;   get addr of Page Table for Page Directory entry
;
	add	ax,1000h		; add page
	adc	dx,0h			; carry it => DX,AX = addr of page table
;
;   set entries in page directory
;
;    ES:[DI] pts to first entry in page directory
;    DX,AX = addr of first page table
;
	mov	bh,0
	mov	bl,P_AVAIL		; make table available to all
	mov	cx,P_TABLE_CNT		; set entries in page table directory
					; for existing page tables.
init_dir:
	call	SetPageEntry		; set entry for first page table
;
;    ES:[DI] pts to next entry in page directory
	add	ax,1000h
	adc	dx,0			; DX,AX = addr of next page table
	loop	init_dir		; set next entry in dir
;
;    set rest of entries in page directory to not present
	mov	bh,0
	mov	bl,NOT P_PRES		; mark page table as not present
	mov	cx,400h
	sub	cx,P_TABLE_CNT		; set rest of entries in directory
set_dir:
	call	SetPageEntry
	loop	set_dir
;
;   set entries in page tables
;
;   first 1 Meg
;	Linear Addr		Physical Addr
;	00000000h - 000FFFFFh	00000000h - 000FFFFFh
;
	mov	ax,[PageD_Seg]		; get segment for page directory
	add	ax,0100h		; add 1 page to get to first page table
	mov	[PageT_Seg],ax		; save it

	mov	es,ax
	xor	di,di			; ES:[DI] pts to first page table

	xor	dx,dx
	xor	ax,ax			; start with physical addr = 00000000h
	mov	bh,0
	mov	bl,P_AVAIL		; make pages available to all
	mov	cx,100h 		; set 1 Meg worth of entries in table
set1_tentry:
	call	SetPageEntry
					; ES:[DI] pts to next page table entry
	add	ax,1000h		; next physical page
	adc	dx,0h			; address in DX,AX
	loop	set1_tentry		;Q: done with this page table
					;  N: the loop again
					;  Y: set next entries in next tables
;   64k wraparound at 1.0 Meg
;	Linear Addr		Physical Addr
;	00100000h - 0010FFFFh	00000000h - 0000FFFFh  (64k wraparound)
;
	call	get_init_a20_state     ; the physical a20 state has already
				       ; been established
	jnz	skip_wrap
	xor	dx,dx
	xor	ax,ax			; start with physical addr = 00000000h
skip_wrap:
	mov	bh,0
	mov	bl,P_AVAIL		; make pages available to all
	mov	cx,10h			; set 64k worth of entries
set2_tentry:
	call	SetPageEntry
					; ES:[DI] pts to next page table entry
	add	ax,1000h		; next physical page
	adc	dx,0h			; address in DX,AX
	loop	set2_tentry		;Q: done with the wraparound entries
					;  N: loop again
					;  Y: all done
;
;    last (15M - 64K) of linear addresses ( for Move Block/Loadall )
;	Linear Addr		Physical Addr
;	00110000h - 01000000h	00110000h - 01000000h
;
	mov	dx,0011h
	xor	ax,ax			; start with 00110000h physical
	mov	bh,0
	mov	bl,P_AVAIL		; make pages available to all
	mov	cx,(4*400h)-100h-10h	; (15M-64K) worth of Page Table Entries
set3_tentry:
	call	SetPageEntry
					; ES:[DI] pts to next page table entry
	add	ax,1000h		; next physical page
	adc	dx,0h			; address in DX,AX
	loop	set3_tentry		;Q: done with last entries
					;  N: loop again
					;  Y: all done

;
;   fill out entries in last table as not present
;
	xor	ax,ax
	xor	dx,dx			; addr = 0
	mov	bh,0
	mov	bl,0			; page not present
;
; we can actually forget about this last page table because we
; are not going to use them
;
	mov	cx,400h			; last table
setL_tentry:
	call	SetPageEntry		; set this entry
	loop	setL_tentry
;
; our honorable OEM Compaq has to be supported, so we have this hook into
; OEMPROC to modify the last page table to point at the diagnostics segment
;
	call	OEM_Init_Diag_Page
;
; all done with page dir and table setup
;  set up page directory and page table selectors
;
	mov	ax,seg GDT
	mov	es,ax				; ES pts to GDT

	mov	ax,[PageT_Seg]		; seg for page tables
	call	SegTo24
	mov	cx,0			; enough room for tables
	mov	ah,D_DATA0
	mov	bx,PAGET_GSEL
	call	SetSegDesc			; set up page tables entry

;
;    EXIT
;
	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
InitPages endp

LAST	ends

	END


