page	58,132
;******************************************************************************
	title	EMMSUP - EMM support routines
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:	CEMM.EXE - COMPAQ Expanded Memory Manager 386 Driver
;		EMMLIB.LIB - Expanded Memory Manager Functions Library
;
;   Module:	EMMSUP - EMM support routines 
;
;   Version:	0.04
;
;   Date:	May 13, 1986
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION                  DESCRIPTION
;   --------  --------  -------------------------------------------------------
;   5/13/86   Original	Initial _TEXT
;   6/14/86		Added _sotofar routine and removed stack define.
;   			And added protected mode check to Map_Page (SBP).
;   6/14/86		map_page now sets _current_map(SBP).
;   6/14/86		moved save_current_map and restore_map from C code (SBP)
;   6/14/86		brought SegOffTo24 and SetDescInfo in from LAST code
;			segment as local routines(SBP).
;   6/21/86    0.02	cld in copyout (SBP).
;   6/21/86    0.02	MapHandlePage added.
;   6/23/86    0.02	make_addr, sotofar removed. source_addr and dest_addr
;			added.
;   6/27/86    0.02	Fix for restore_map.
;   6/28/86    0.02	Name change from CEMM386 to CEMM (SBP).
;   7/06/86    0.04	Changed _emm_page,_emm_free, & _pft386 to ptrs (SBP).
;   7/06/86    0.04	Changed assumes from _DATA to DGROUP (SBP).
;   7/06/86    0.04	Changed internal save area structure (SBP).
;   7/06/86    0.04	moved SavePageMap and RestorePageMap to .ASM (SBP).
;   7/07/86    0.04	moved MapHandlePage,SavePageMap, and RestorePageMap to
;			emmp.asm (SBP).
;   5/09/88    1.01	moved routines names_match and flush_tlb from win386 
;   9/01/88		rename SegOffTo24/SetDescInfo to
;			SegOffTo24Resident/SetDescInfoResdient and made public
;******************************************************************************
;
;   Functional Description:
;	Support routines for emm/386
;	C callable 
;
;
;******************************************************************************
.lfcond					; list false conditionals
.386p

;******************************************************************************
;	P U B L I C S
;******************************************************************************
	public _source_addr
	public _dest_addr
	public _copyout
	public _copyin
	public _wcopy
	public _wcopyb
	public _valid_handle
	public SetDescInfoResident
	public SegOffTo24Resident
;
;******************************************************************************
;	 D E F I N E S
;******************************************************************************

	include	vdmseg.inc
	include vdmsel.inc
	include desc.inc
	include page.inc
;	include instr386.inc
	include	emmdef.inc

FALSE		equ	0
TRUE		equ	not FALSE
CR		equ	0dh
LF		equ	0ah

	page
;******************************************************************************
;	E X T E R N A L   R E F E R E N C E S
;******************************************************************************

_DATA	SEGMENT
;
;  pointer to entry stack frame
;	stored as offset, SS
extrn	_regp:word

;
;   current state of mapping registers and # of mapping registers emulated
;
;extrn	_current_map:byte
;extrn	_map_size:byte

;
; total # of EMM pages in system
;
extrn	_total_pages:word

;
; table of offsets into in to the first page table
; for user logical emm page map
;
extrn	_page_frame_base:dword

;
; ptr to table of emm page # for each handle's logical pages.
;
extrn	_emm_page:word

;
; ptr to table of page table entries for the EMM pages
;
extrn	_pft386:word		; note: actually a dword array

;
;  handle data structure
;
extrn	_handle_table:word
extrn	_handle_table_size:word

;
;   save area for handles
;
extrn	_save_map:byte

_DATA	ENDS


	page
;******************************************************************************
;	L O C A L   D A T A
;******************************************************************************
_DATA	SEGMENT
;
; kludge to prevent unresolved from C compiler
;
public	__acrtused
__acrtused	label	dword
	dd (0)
_DATA	ENDS

	page
;******************************************************************************
;	C O D E
;******************************************************************************
_TEXT	SEGMENT
assume	cs:_TEXT, ds:DGROUP, ss:DGROUP

;***********************************************
;
; _source_addr - return far pointer for source address (= int 67 entry DS:SI).
;
;  SYNOPSIS:	src = source_addr()
;		char far *src;	/* ptr to area at DS:SI */
;
;  DESCRIPTION:	This function generates a far pointer equivalent to the client's
;		DS:SI pointer.  If this code was called in protected mode, the
;		address is a (selector,offset) pair; otherwise, it is a segment
;		offset pair.  EMM1_GSEL is used if a selector is needed.
;
; 05/09/88  ISP   No update needed for MEMM
;***********************************************
_source_addr	proc	near
;
	push	bp
;
	mov	bp,[_regp]			; get entry stack frame pointer
	test	[bp.PFlag],PFLAG_VIRTUAL	;Q: real/virtual mode ?
	jnz	sa_pm				; N: go get selector/offset
	mov	ax,word ptr [bp.rSI]		; Y: get offset
	mov	dx,word ptr [bp.rDS]		;    get segment
	jmp	sa_exit				;    return DX:AX = seg:offset
;
;  protected mode - set up selector to client's DS
sa_pm:
	push	bx
	push	cx
	push	es			; save ES
	; 
	; load ES with GDT alias
	;
	push	GDTD_GSEL
	pop	es			; ES -> GDT
	;
	; compute physical address
	;
	mov	ax,word ptr [bp.rDS]	; ax <-- base addr
	mov	dx,word ptr [bp.rSI]	; dx <-- offset
	call	SegOffTo24Resident	; converts to physical addr

	;
	; set up the appropriate table entry
	;
	mov	bx,EMM1_GSEL 	; bx <-- selector 
	mov	cx,0FFFFh	; cx <-- gets limit (64k)
	mov	ah,D_DATA0	; ah <-- gets access rights
	;
	; at this point:
	;	ah -- access rights
	;	al -- bits 16-23 of linear address
	;	dx -- low 16 bits of linear address
	;	cx -- limit = 64k
	;	bx -- selector
	;	es -- selector to GDT Alias
	call	SetDescInfoResident	; set up descriptor

	; 
	; set up return pointer
	;
	xor	ax,ax		; ax <-- offset (0)
	mov	dx,bx		; dx <-- selector
	;
	pop	es		; restore ES
	pop	cx
	pop	bx
;
sa_exit:
	pop	bp
	ret
;
_source_addr	endp

;***********************************************
;
; _dest_addr - return far pointer for destination address (= int 67 entry ES:DI).
;
;  SYNOPSIS:	dest = dest_addr()
;		char far *dest;	/* ptr to area at ES:DI */
;
;  DESCRIPTION:	This function generates a far pointer equivalent to the client's
;		ES:DI pointer.  If this code was called in protected mode, the
;		address is a (selector,offset) pair; otherwise, it is a segment
;		offset pair.  EMM2_GSEL is used if a selector is needed.
;
; 05/09/88  ISP   No update needed for MEMM
;***********************************************
_dest_addr	proc	near
;
	push	bp
;
	mov	bp,[_regp]			; get entry stack frame pointer
	test	[bp.PFlag],PFLAG_VIRTUAL	;Q: real/virtual mode ?
	jnz	da_pm				; N: go get selector/offset
	mov	ax,word ptr [bp.rDI]		; Y: get offset
	mov	dx,word ptr [bp.rES]		;    get segment
	jmp	da_exit				;    return DX:AX = seg:offset
;
;  protected mode - set up selector to client's DS
da_pm:
	push	bx
	push	cx
	push	es			; save ES
	; 
	; load ES with GDT alias
	;
	push	GDTD_GSEL
	pop	es			; ES -> GDT
	;
	; compute physical address
	;
	mov	ax,word ptr [bp.rES]	; ax <-- base addr
	mov	dx,word ptr [bp.rDI]	; dx <-- offset
	call	SegOffTo24Resident	; converts to physical addr

	;
	; set up the appropriate table entry
	;
	mov	bx,EMM2_GSEL 	; bx <-- selector 
	mov	cx,0FFFFh	; cx <-- gets limit (64k)
	mov	ah,D_DATA0	; ah <-- gets access rights
	;
	; at this point:
	;	ah -- access rights
	;	al -- bits 16-23 of linear address
	;	dx -- low 16 bits of linear address
	;	cx -- limit = 64k
	;	bx -- selector
	;	es -- selector to GDT Alias
	call	SetDescInfoResident	; set up descriptor
	
	; 
	; set up return pointer
	;
	xor	ax,ax		; ax <-- offset (0)
	mov	dx,bx		; dx <-- selector
	;
	pop	es		; restore ES
	pop	cx
	pop	bx
;
da_exit:
	pop	bp
	ret
;
_dest_addr	endp

	page
;***********************************************
;
; _copyout
;
; This routine takes a far pointer, a near pointer
; and a byte count and copies from the near address
; to the far address.
;
; Parameters:
;	destptr -- sel:off 286 pointer to target area
;	srcptr --- offset of source data in current D Seg
;	count ---- byte count for copy
;
; uses:
;	cx, ax, es
;
; 05/09/88  ISP   No update needed for MEMM
;***********************************************
destptr	=	4
srcptr	=	8
count	=	10
_copyout	proc	near
	push	bp		; entry prolog
	mov	bp,sp
	push	di		; reg var
	push	si		; reg var

	les	di,[bp+destptr]	; es:di <-- destination address
	mov	si,[bp+srcptr]	; ds:si <-- source address
	mov	cx,[bp+count]	; cx <-- byte count
	cld			;  strings foward
	rep movsb		; do it

	pop	si		; restore reg var
	pop	di		; restore reg var
	pop	bp		
	ret
_copyout	endp
	page

;***********************************************
;
; _copyin
;
; This routine takes a near pointer, a far pointer
; and a byte count and copies from the far address
; to the near address.
;
; Parameters:
;	destptr -- offset of dest in current D Seg
;	srcptr --- sel:off 286 pointer to source data area
;	count ---- byte count for copy
;
; uses:
;	cx, ax, es
;
; 05/09/88  ISP   Written for MEMM.
;***********************************************
destptr	=	4
srcptr	=	6
count	=	10
_copyin	proc	near
	push	bp		; entry prolog
	mov	bp,sp
	push	di		; reg var
	push	si		; reg var
	push	ds

	push	ds
	pop	es		; es to dgroup

	mov	di,[bp+destptr]	; es:di <-- destination address
	lds	si,[bp+srcptr]	; ds:si <-- source address
	mov	cx,[bp+count]	; cx <-- byte count
	cld			;  strings foward
	rep movsb		; do it

	pop	ds
	pop	si		; restore reg var
	pop	di		; restore reg var
	pop	bp		
	ret
_copyin	endp
	page
;***********************************************
;
; _wcopy
;
; This routine takes a two near pointers
; and a word count and copies from the 
; first address to the second address.
;
; Parameters:
;	srcptr --- offset of source data in current D Seg
;	destptr -- offset of destination address in DS
;	count ---- word count for copy
;
; uses:
;	si, di, cx, ax
;	(si, di are restored)
;
; 05/09/88  ISP   No update needed for MEMM
;***********************************************
srcptr	=	4
destptr	=	6
count	=	8
_wcopy	proc	near
	push	bp		; entry prolog
	mov	bp,sp
	push	di		; reg var
	push	si		; reg var

	cld			; clear dir flag (forward move)
	mov	ax,ds		;
	mov	es,ax		; mov es,ds 
	mov	di,[bp+destptr]	; es:di <-- destination address
	mov	si,[bp+srcptr]	; ds:si <-- source address
	mov	cx,[bp+count]	; cx <-- word count
	rep movsw		; do it

	pop	si		; restore reg var
	pop	di		; restore reg var
	pop	bp		
	ret
_wcopy	endp
	page
;***********************************************
;
; _wcopyb
;
; This routine takes a two near pointers
; and a word count and copies from the 
; first address to the second address.
; The copy is done backwards to allow certain overlap of source and destination.
;
; Parameters:
;	srcptr --- offset of source data in current D Seg
;	destptr -- offset of destination address in DS
;	count ---- word count for copy
;
; uses:
;	si, di, cx, ax, es
;	(si, di are restored)
;
; 05/20/88  ISP   Shifted in from win386 and updated for 16 bit ptrs
;***********************************************
srcptr	=	4
destptr	=	6
count	=	8
_wcopyb	proc	near
	push	bp		; entry prolog
	mov	bp,sp
	push	di		; reg var
	push	si		; reg var

	mov	ax,ds		;
	mov	es,ax		; mov es,ds 
	mov	di, word ptr [bp+destptr]      ; destination address
	mov	si, word ptr [bp+srcptr]       ; source address
	mov	cx, word ptr [bp+count]        ; word count
	dec	cx
	shl	cx, 1				; offset of 'last' word to move
	add	si, cx
	add	di, cx
	mov	cx, word ptr [bp+count]        ; recover word count

	std			; set dir flag (backward move)
	rep movsw		; do it
	cld			; 'C' tends to expect this.

	pop	si		; restore reg var
	pop	di		; restore reg var
	pop	bp		
	ret
_wcopyb	endp
	page
;***********************************************
;
; _valid_handle - validate current handle
;
;  SYNOPSIS:	hp = _valid_handle()
;		struct handle_ptr *hp;	/* ptr to handle's structure */
;					/* OR NULL_HANDLE if invalid handle */
;				/* also sets AH = INVALID_HANDLE if it fails */
;
;  DESCRIPTION:	This routine validates the current handle in regp->rDX and
;		returns either an error or a ptr to the handle's index and
;		page count structure.
;
; 05/09/88  ISP   No update needed for MEMM
;***********************************************
_valid_handle	proc	near
;
	push	bp
	mov	bp,[_regp]		; get entry args pointer
	push	bx
;
	mov	bx,word ptr [bp.rDX]	; BX = entry handle
	cmp	bx,[_handle_table_size]	;Q: handle in range ?
	jae	vh_fail			;  N: return invalid handle error
	shl	bx,2			;  Y: BX = handle's table offset
	add	bx,offset DGROUP:_handle_table	; BX = offset to handle's data
	cmp	[bx.ht_index],NULL_PAGE	;Q: is this an active handle ?
	je	vh_fail			;    N: return invalid handle error
	mov	ax,bx			;    Y: return ptr to handle's data
;
vh_exit:
	pop	bx
	pop	bp
	ret
vh_fail:
	mov	byte ptr [bp.rAX+1],INVALID_HANDLE	; set AH on stack
	mov	ax,NULL_HANDLE		; return NULL_HANDLE to caller
	jmp	short vh_exit

;
_valid_handle	endp

;***********************************************
;
; flush_tlb:
;
; no params, no return value, uses eax
;
; flush the Translation Look-Aside Buffer
;
; 05/09/88  ISP   Shifted in from WIN386
;***********************************************
_flush_tlb	proc	near
public	_flush_tlb
	mov	eax, cr3
	mov	cr3, eax
	ret
_flush_tlb	endp

;***********************************************
;
;   _Names_Match
;
;   Returns a boolean value (0 = false, FFFF = True) if 2 handle names match
;
; uses:
;	cx, ax
;
; 05/09/88  ISP   Shifted in from WIN386 and modified for 16 bit ptrs
;***********************************************
name1	=	4
name2	=	6
	public	_Names_Match
_Names_Match proc    near
	push	bp		; entry prolog
	mov	bp,sp
	push	di		; reg var
	push	si		; reg var

	mov	ax,ds		; initialise es segment to
	mov	es,ax		; DGROUP

	xor	ax, ax	; Assume it did NOT work

	mov	di, word ptr [bp+name1]	; First name
	mov	si, word ptr [bp+name2]	; Second name
	cld
	mov	cx, 2				; Compare 2 dwords
	rep 	cmpsd		; do it
	jne	SHORT Names_Dont_Match
	not	ax		; They match!

Names_Dont_Match:
	pop	si		; restore reg var
	pop	di		; restore reg var
	pop	bp
	ret
_Names_Match endp

	page
;**	SetDescInfoResident - set descriptor information
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

SetDescInfoResident proc near
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
SetDescInfoResident endp

	page
;**	SegOffTo24Resident - convert seg:off to 24 bit physical address
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

SegOffTo24Resident proc near
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
SegOffTo24Resident endp

_TEXT	ENDS
END
