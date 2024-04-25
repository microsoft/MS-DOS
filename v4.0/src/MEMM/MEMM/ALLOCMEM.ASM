

	page 58,132
;******************************************************************************
	title	ALLOCMEM - allocate memory for EMM Pages Pool
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;	Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;	Module: AllocMem - allocate memory for EMM Pages Pool
;
;	Version: 0.05
;
;	Date:	May 24,1986
;
;	Author:
;
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;	05/24/86 Original
;	06/28/86 0.02		code read changes to various routines
;	07/05/86 0.04		Changes due to segment re-org
;	07/06/86 0.04		Made EXT_RES a define
;	07/06/86 0.04		Changed to DGROUP assume
;	07/10/86 0.05		added NOHIMEM flag
;	06/02/88 pc		change from VDISK allocation to INT-15 method
;	07/26/88 isp		completed work in changing over to int15 alloc
;
;******************************************************************************
;   Functional Description:
;	This module allocates the pool of memory to be used for the pool of
;   EMM pages.	 The pool of memory is allocated from "high" extended
;   memory (located in the 15-16 Meg range)and from "regular" extended memory
;   (starting at 1 Meg).  This module attempts to allocate high memory first,
;   then extended memory.  When allocating memory from either area, the memory
;   is allocated in 16k byte blocks which are aligned on a physical 4k boundary.
;   This module attempts to allocate extended memory using the int15 allocation
;   scheme.
;
;	NOTE: if this module is compiled with NOHIMEM defined, then
;		this code will not attempt to use the OEM specific
;		"high" memory.
;
;******************************************************************************
.lfcond
.386p
;
;
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	AllocMem
	public	DeallocMem
	public	xbase_addr_l		; data publics
	public	xbase_addr_h
	public	ext_size
	public	sys_size

	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
	include vdmseg.inc
	include vdmsel.inc
	include emm386.inc
	include driver.equ
	include driver.str
	include romxbios.equ
	include desc.inc
	include ascii_sm.equ
	include oemdep.inc
	include emmdef.inc
;
EXT_RES 	equ	10h		; must be a power of 2.
;
GET_VER 	equ	30h		; get dos version number
MSDOS		equ	21h		; DOS interrupt
;
FALSE	equ	0
TRUE	equ	not FALSE

;******************************************************************************
;			E X T E R N A L    R E F E R E N C E S
;******************************************************************************
;
_DATA	segment

	extrn	dos_version:byte
	extrn	pool_size:word
	extrn	msg_flag:word

ifndef	NOHIMEM
	extrn	hi_size:word		; size of hi memory in kbytes
	extrn	hi_alloc:word		; hi memory allocated
	extrn	hisys_alloc:word	; hi system memory allocated
					;    in 4k byte blocks
endif

_DATA	ends


LAST	segment
	extrn	mappable_segs:byte	; mappable segment map
	extrn	set_ext:near		; routine to set amount of ext mem
					; reported by int15 handler
	extrn	memreq:near		; memory requirements for move
	extrn	pool_initialise:near	; initialise the pool of extended
					; memory

ifndef	NOHIMEM
	extrn	hbuf_chk:near
	extrn	HiAlloc:near
	extrn	HiMod:near
endif
LAST	ends
;
	page
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************

	page
;******************************************************************************
;	Data segment
;******************************************************************************
_DATA	segment
	ASSUME	CS:DGROUP,DS:DGROUP

xbase_addr_l	dw	0000h	; 24 bit address of beginning of
xbase_addr_h	db	10h	; extended mem pool of EMM pages. (1M initially)
ext_size	dw	0	; size of extended memory allocated in kb
sys_size	dw	0	; size of system memory from 4000h in emm pool
total_mem	dw	0	; size of extended memory available at any moment
avail_mem	dw	0	; total size (hi+ext) available for MEMM
;

_DATA	ends


;******************************************************************************
;
;	Code Segment
;
;******************************************************************************
;
LAST	segment
	assume	cs:LAST, ds:DGROUP, es:DGROUP

	page
;******************************************************************************
;
;	AllocMem	Allocate Extended memory for MEMM using the int15
;			method of allocating extended memory.
;
;	description:
;		This routine attempts to get the requested extended memory
;		from two sources: a) the himem area (just below 16M) first
;		and if not enough b) extended memory.  Extended memory is
;		allocated using the int15 scheme.  We do not care for
;		compatibility with vdisk. The memory we allocate either in
;		himem area or in extended memory must start at a 4k boundary
;		because we are using them as pages.
;
;	entry:	DS pts to DGROUP
;		DGROUP:[pool_size] = mem size requested (kbytes)
;
;	exit:	If extended memory pool space is not available then
;		set MEM_ERR_MSG bit in DGROUP:[msg_flag] and exit.
;
;
;	used:	none
;
;	stack:
;
;	modified:   ISP 07/26/88    Changed to a simple check for availability
;				    of hi / ext memory and allocation of
;				    of appropriate amounts of each.
;
;
;******************************************************************************
;
AllocMem	proc	near
;
	push	ax
	push	bx
	push	cx
	push	dx
	push	es


;
; 1. Check available hi/extended memory
;
AM_getmem:
	call	xbuf_chk
	test	[msg_flag],MEM_ERR_MSG	;Q: memory error found ?
	jz	AM_nba			;  N: continue with allocation
	jmp	AM_exit 		;  Y: exit
;
; 2. Allocate extended memory
;
AM_nba:
	call	ExtAlloc		; alloc ext mem

ifndef	NOHIMEM 		; if HI memory in this model
;
; 3. Allocate Hi memory
;
AM_halloc:
	call	HiAlloc 		; Allocate hi memory
	jnc	AM_exit 		; no error
	or	[msg_flag],MEM_ERR_MSG	; memory error
endif

;
; 4. Allocate system memory
;
	call	SysAlloc
;
AM_exit:
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
AllocMem	endp				; End of procedure
;
	page
;******************************************************************************
;
;	DeallocMem	Deallocate Extended memory for MEMM using the int15
;			method of allocating extended memory. Note that since
;			we call this routine when we haven't already installed tc.)
;			the int15 handler we really don't need to do anything
;			as far as the regular extended memory is concerned.  We
;			only need to deallocate hi memory if allocated.
;
;	entry:	DS pts to DGROUP
;		DGROUP:[hi_alloc]  amount of hi memory to deallocate
;
;	used:	none
;
;	stack:
;
;	modif:	7/26/88 ISP	Removed VDISK deallocation of extended memory
;******************************************************************************
;
DeallocMem	proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	es
;
ifndef NOHIMEM			; if high memory in this model
	mov	ax,[hi_alloc]		; get hi memory to deallocate
	or	ax,ax			; q: did we ever get any?
	jz	deall_hisys		; n: check hi system memory
	neg	ax			; # of 16 byte pieces to remove
	mov	[hi_alloc],0		; make sure we never do it again
deall_hisys:
	mov	bx,[hisys_alloc]	; get hi system memory to deallocate
	neg	bx			; update by a negative amount
	add	bx,ax			; q: any hi or hisys to deallocate?
	jz	deall_ext		; n: don't waste our time doing it
	sub	bx,ax			; y: straighten our regs out
	mov	[hisys_alloc],0 	; make sure we don't do it again
	call	HImod			; modify memory. ignore any errors
deall_ext:
;
endif				; end of conditional
	pop	es
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
;
	ret
DeallocMem	endp
;
	page
;******************************************************************************
;
;	xbuf_chk Extended memory pool check.
;	 Check 1) for previously loaded MEMM,VDISKs in extended memory
;	       2) available memory pool space. (hi memory and extended)
;
;	entry:	DS = DGROUP
;		DGROUP:[pool_size] = mem size requested (kbytes)
;
;
;	exit:	If hi memory pool space is available then
;
;		    DGROUP:[hi_size]   = hi memory size allocated (kbytes).
;
;		If extended memory pool space is necessary and available then
;
;		    DGROUP:[xbase_addr_h] and DGROUP:[xbase_addr_l] contain the
;		    starting 24-bit address of MEMM extended memory pool.
;
;		DGROUP:[pool_size] = mem size ALLOCATED (kbytes)
;		DGROUP:[total_mem] = total extended memory left after allocation
;		DGROUP:[avail_mem] = available memory for MEMM.
;		DGROUP:[ext_size]  = extended memory size allocated (kbytes)
;
;		If hi/extended memory pool space is not available then
;		set MEM_ERR_MSG bit in DGROUP:[msg_flag] and exit.
;
;	used:	none
;
;	stack:
;
;	modified:   ISP 07/26/88    int15 allocation requires different check
;				    on extended memory. substancial rewrite.
;******************************************************************************
;
xbuf_chk	proc	near
;
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
;
; determine amount of extended memory and store it in total_mem
;
	mov	ah,EXT_MEM		; function request - ext mem data
	clc				; clear carry flag
	int	XBIOS			;Q: extended memory supported ?
;
	jnc	store_ext		; Y: go to store the amount got
	xor	ax,ax			; N: Assume zero extended memory
store_ext:
	mov	[total_mem],ax
;
ifndef NOHIMEM			; if high memory in this model
;
;	check for hi memory
;
	call	hbuf_chk		; get available hi memory in AX
	jc	xb_NoHiMem
	mov	[hi_size],ax		; save it
	mov	[avail_mem],ax		; update available memory
xb_NoHiMem:
	mov	ax,[pool_size]
	cmp	ax,[hi_size]		; q: enough?
	ja	get_ext 		; n: try extended memory
	mov	[hi_size],ax		; y: just use enough
	jmp	x_buf_exit		; and exit
endif

get_ext:
	mov	ax,[total_mem]		; get size of extended memory available
					;  Y: how much there ?
;
; we have to reserve enough memory here to ship the segments up hi.
;
	call	memreq			; get memory requirements for our o
					; our grand operation in cx in K
	cmp	ax,cx			; lets see if we can satisfy
	jbe	x_buf_no_install	; if not we shan't install memm

	push	ax
	sub	ax,cx
	cmp	ax,64 + 64		; we should try to leave enough memory
					; for himem and atleast four pages of
					; expanded memory.
	pop	ax
	jbe	x_buf_no_install	; if we don't have enough for this we
					; shouldn't install memm
    ;
    ; we can now get memory to shift things up. and intialise the manager of
    ; this pool.
    ;
	sub	ax,cx			; ax = start of this pool as an offset
					;      in K from 1M
					; cx = size in K of this pool
	call	pool_initialise 	; intialise the pool
	or	ax,ax			;Q: any extended memory ?
	jz	x_buf_2			;  N: If none go to set buf adj or no
					;     memory error
;					;  Y: continue to process
;
	mov	bx,[pool_size]		; get size requested
;
ifndef	NOHIMEM 			; if high memory in this model
	sub	bx,[hi_size]		; adjust by the size already allocated
endif					; from the high memory

	and	ax,0fff0h		; round to 16k boundary
;
;   it is necessary to support himem.  So if we have a 64k block at 1M we
;   should leave it for himem. The himem we are talking about here is the
;   EMS 4.1 standard himem at 1M
    ;
    ; initialise reserved memory for himem
    ;
	xor	cx,cx			; amount reserved for himem
    ;
    ; see if we have 64k available for himem
    ;
	cmp	ax,64			; Q:do we have 64k?
	jb	no_himem_alloc		       ;   N: we reserve nothing for himem
					;   Y: we should reserve 64k for himem
    ;
    ; reserve 64k for himem
    ;
	mov	cx,64
	sub	ax,cx
    ;
no_himem_alloc:
    ;
	cmp	ax,bx			; compare amount available to size needed
	jae	enough_mem		; Y: fine
	mov	bx,ax			; N: adjust size reuested to size avail
enough_mem:
    ;
    ; add back the memory reserved for himem as this figures in the size of
    ; free extended memory
    ;
	add	ax,cx			; adjust size to include amnt res. himem
	sub	ax,bx			; adjust the size of extended memory
					; after allocation
	mov	[total_mem],ax		; store size of extended mem available
;
	add	[avail_mem],bx		; add memory available to memory pool
	mov	[ext_size],bx		; and indicate size allocated
;
;   find the start address of extended memory allocated
;
	mov	cx,1024 		; kb multiplier
	mul	cx			; dx:ax = ax*cx
	add	[xbase_addr_l],ax	; adjsut starting address of allocated mem
	adc	[xbase_addr_h],dl	; higher byte of 24 bit address
;
x_buf_2:
;
	mov	ax,[avail_mem]		; ax == Available memory
	cmp	ax,[pool_size]		; Q: Extended memory available?
	jnb	x_buf_exit		; Y: Go to finish
;
not_enough:
	or	ax,ax			; Q: Any extended memory available?
	jz	x_buf_no_install	; N: Set error flag and exit
	mov	[pool_size],ax		; Y: Set pool_size to remaining memory
	or	[msg_flag],SIZE_ADJ_MSG ; Set buffer adjusted message bit
	jmp	short x_buf_exit	; And jump to exit
;
x_buf_no_install:
	or	[msg_flag],MEM_ERR_MSG	; memory error found in x_bufchk
;
x_buf_exit:
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret				; *** return ***
;
xbuf_chk	endp
;
	page
;******************************************************************************
;
;	ExtAlloc - allocate extended memory - update break address for ext. mem.
;
;	entry:	DS pts to DGROUP
;
;	exit:	extended memory size
;
;	used:	none. int15 size reported by int 15 handler in MEMM adjusted.
;
;	stack:
;
;	modified:   ISP 07/26/88 Substancially simplified.  For int15 scheme
;				 allocation is by lowering the size of int15
;				 reported extended memory size.
;
;******************************************************************************
ExtAlloc	proc	near
;
	mov	bx,[total_mem]	    ;size left after allocation to MEMM
	call	set_ext 	    ; set this size in the int15 handler
	ret
;
ExtAlloc	endp
;
;******************************************************************************
;
;	SysAlloc - allocate extended memory - update break address for ext. mem.
;
;	entry:	DS pts to DGROUP
;
;	exit:	system memory size
;
;	used:	none.
;
;	stack:
;
;	written:   ISP 07/28/88 This allocates the system memory from 0000H
;				to A000h to the EMM pool. This is for the LIM
;				4.0 implementation.
;
;******************************************************************************

SysAlloc	proc	near
;
	push	ax
	push	bx
	push	cx
;
; find end of memory reported by bios int 12 and round this to upper 16k.
;
	int	12h
	add	ax,0000fh	    ;
	and	ax,0fff0h	    ; round it 16k figure
;
; convert this to the a page #
;
	shr	ax, 4		    ; number of 16k pages
;
; start search for pages which can be reclaimed from the system mem. region
;
	mov	cx,ax		    ; number of pages from pg0 to be examined
	mov	[sys_size],0	    ; initialise the system memory allocate
	xor	bx,bx		    ; page #

	jcxz	find_sys_done
find_sys_page:
	cmp	cs:mappable_segs[bx], PAGE_MAPPABLE
	jne	find_next_sys
	add	[sys_size],16	    ; page found add 16k to system mem size
find_next_sys:
	inc	bx
	loop	find_sys_page
find_sys_done:

	mov	ax,[sys_size]	    ; find the total memory found
	add	[pool_size],ax	    ; add this to the pool size

;
	pop	cx
	pop	bx
	pop	ax
	ret

SysAlloc	endp



LAST	ends				; End of segment
;
	end				; End of module


