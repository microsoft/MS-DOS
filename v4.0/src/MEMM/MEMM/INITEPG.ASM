

page	58,132
;******************************************************************************
	title	InitEPage - initialize EMM Page pointers
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   InitEPage - initialize EMM Page pointers
;
;   Version:  0.05
;
;   Date:     June 4,1986
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
;   06/28/86  0.02	Name changed from MEMM386 to MEMM
;   07/06/86  0.04	_pft386 changed to a ptr
;   07/06/86  0.04	fixed hdma_exit label to edma_exit
;   07/06/86  0.04	changed assume to DGROUP
;   07/09/86  0.05	added to FindDMA routine
;
;******************************************************************************
;
;   Functional Description:
;
;	This module initializes the array of pointers to the EMM Pages used
;  by the expanded memory manager code.   Specifically, this module initializes
;  the array EMM_PTE.
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	InitEPage

	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
	include VDMseg.inc
	include VDMsel.inc
	include desc.inc
	include page.inc
	include instr386.inc
	include emmdef.inc
;
;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************
;

LAST	segment

ifndef	NOHIMEM
extrn	Hi_Mem_Size:near
endif

extrn	mappable_segs:byte

LAST	ends


ABS0	segment at 0000h
ABS0	ends


_DATA	segment

extrn	DMA_Pages:word		; DMA EMM pages buffer
extrn	DMA_PAGE_COUNT:word	; number of DMA pages

extrn	xbase_addr_l:word	; 24 bit address of beginning of extended mem
extrn	xbase_addr_h:byte	; pool of EMM pages.
extrn	ext_size:word		; size of extended memory in kbytes
extrn	sys_size:word		; size of system memory in kbytes

extrn	_pft386:word		; ptr to dword array of Page Table entries

_DATA	ends

;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************
_DATA	segment

ifndef	NOHIMEM
DMA_hi_begin	dw	0	; EMM page # for begin of DMA area in hi mem
DMA_hi_cnt	dw	0	; # of contiguous EMM pages in hi mem DMA area
endif

DMA_ext_begin	dw	0	; EMM page # for begin of DMA area in ext mem
DMA_ext_cnt	dw	0	; # of contiguous EMM pages in ext mem DMA area

;
; FindDMA variables
;
crossed 	db	0	; flag => crossed 1st 64k bndry
b_start 	dw	0	; 1st EMM page before 1st 64k bndry
b_cnt		dw	0	; # of EMM pages before 1st 64k bndry
a_start 	dw	0	; 1st EMM page after 1st 64k bndry
a_cnt		dw	0	; # of EMM pages after 1st 64k bndry


_DATA	ends
;
;------------------------------------------------------------------------------
LAST	segment
	assume	cs:LAST, ds:DGROUP, es:DGROUP, ss:DGROUP
	page
;******************************************************************************
;   InitEPage - init EMM_PTE - array of pointers for EMM pages.
;
;   ENTRY: Real Mode
;	   DGROUP:[xbase_addr_l] = 24 bit address of beginning of extended mem
;	   DGROUP:[xbase_addr_h]   pool of EMM pages.
;	   DGROUP:[ext_size] = size of extended memory buffer in kbytes
;
;   EXIT:  Real Mode
;	   DGROUP:[DMA_Pages] = initialized to point to up to 8 physically
;				contiguous EMM pages in high memory.
;	   DGROUP:[_pft386] = pts to array of ptrs for EMM Pages
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
InitEPage proc	 near
;
	PUSH_EAX
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
;
	cld
;
	mov	ax,seg DGROUP
	mov	ds,ax
	mov	es,ax
	mov	di,[_pft386]		; ES:DI points to begin of table
;
	mov	bx,0			; BX = current EMM page #
;
; set system memory pointers first
;
	mov	cx,[sys_size]		; get size of system memory in kb
	shr	cx,4			; convert to number of pages
	jcxz	fin_sys
	mov	eax,0000h*16		; address of first system page
	xor	si,si			; index into mappable page array
;
; store in pft386 array
;
SEP_hloop:
	cmp	 cs:mappable_segs[si],PAGE_MAPPABLE
	jne	not_this_page
;
	stosd
	inc	bx			; next emm page
	dec	cx
	jcxz	fin_sys 		; found all pages
not_this_page:
	inc	si
	add	eax,4000h		; point to next 16k page
	jmp	SEP_hloop		;
fin_sys:
;
ifndef NOHIMEM
;
; set high memory pointers next
;
	call	Hi_Mem_Size		; CX = kbytes of high mem,
					; EAX = pointer to high mem
					;Q: any hi memory pages ? CX = pg cnt
	jz	IEP_ext 		;  N: set up ext mem pointers
					;  Y: set high memory pointers
;
;  check for contiguous EMM pages
;
	push	bx			; first hi mem EMM page #
	push	cx			; save # of hi mem EMM pages
	call	FindDMA 		;   find the DMA pages for hi mem
	mov	[DMA_hi_begin],bx	; save begin EMM page #
	mov	[DMA_hi_cnt],cx 	; save cnt
	pop	cx			; restore # of hi mem EMM pages
	pop	bx			; restore EMM page# for 1st of hi mem
;
;  set entries in _pft386
;
IEP_hloop:
	db	66h
	stosw				; set this table entry
	db	66h
	add	ax,4000h		; ADD EAX,4000h
	dw	0000h			;   EAX = addr of next EMM page
	inc	bx			; increment EMM page #
	loop	IEP_hloop		; set all high memory entries

endif	;  NOHIMEM

;
; set extended memory entries
;
IEP_ext:
	mov	cx,[ext_size]		;  CX = kbytes of ext memory
	shr	cx,4			;Q: any ext memory pages ? CX = pg cnt
	jz	IEP_Dpages		;  N: all done - leave
	db	66h			;  Y: set ext memory pointers
	mov	ax,[xbase_addr_l]	;   get pointer to ext memory pool
	db	66h
	and	ax,0FFFFh		; AND EAX,00FFFFFFh
	dw	00FFh			;   clear highest nibble
;
;  check for contiguous EMM pages
;
	push	bx			; first ext mem EMM page #
	push	cx			; save # of ext mem EMM pages
	call	FindDMA 		;   find the DMA pages for ext mem
	mov	[DMA_ext_begin],bx	; save begin EMM page #
	mov	[DMA_ext_cnt],cx	; save cnt
	pop	cx			; restore # of ext mem EMM pages
	pop	bx			; restore EMM page# for 1st of ext mem
;
;  set entries in _pft386
;
IEP_xloop:
	db	66h
	stosw				; set this table entry
	db	66h
	add	ax,4000h		; ADD EAX,4000h
	dw	0000h			;   EAX = addr of next EMM page
	inc	bx			; increment EMM page #
	loop	IEP_xloop		; set all ext memory entries
;
;
;  set up DMA Pages
;
IEP_Dpages:
ifndef	NOHIMEM
	mov	ax,[DMA_hi_begin]	; SI = beginning hi mem DMA page
	mov	cx,[DMA_hi_cnt] 	; CX = # of hi mem DMA pages
	cmp	cx,[DMA_ext_cnt]	;Q: more hi DMA pages ?
	jae	IEP_Dset		;  Y: use hi mem DMA pages
endif
	mov	cx,[DMA_ext_cnt]	;  N: use ext mem pages
	mov	ax,[DMA_ext_begin]
IEP_Dset:

	mov	DMA_Page_Count,cx
	mov	di,offset DGROUP:DMA_Pages	; ES:DI ->dest array
	cld
DMA_Pg_St:
	stosw					; store index for dma page
	inc	ax				;
	loop	DMA_Pg_St			;
;
;  all done
;
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	POP_EAX
	ret
;
InitEPage endp
;

;******************************************************************************
;   FindDMA - find contiguous DMA pages
;
;   ENTRY: Real Mode
;		EAX = 24 bits of beginning address of EMM memory pool
;		BX = first EMM page #
;		CX = # of EMM pages in this pool
;
;   EXIT:  Real Mode
;		BX = EMM page# of first DMA page
;		CX = # of DMA pages
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
FindDMA proc	near
;
	push	eax

;
; initialise the variables needed for this calculation
;
	mov	[b_start],bx
	mov	[a_start],bx
	mov	[crossed],0
	mov	[a_cnt],0
	mov	[b_cnt],0

	jcxz	fdp_exit		; if no pages to check exit ...
;
; convert physical address in eax (which is assumed to be aligned on 4k bdry)
; to page # (in 4k physical pages) modulo 32.  This is to find the page # in
; the current 128k block
;
	shr	eax,12			; physical_address >> 4*1024
	and	ax,01fh 		; modulo 32, also sets Z flag if on 128k
					; bdry.  So Q: On 128K bdry?
	jnz	fdp_loop		;  N: continue as normal
	mov	[crossed],1		;  Y: set flag

fdp_loop:
	add	ax,04h			;Q: add 16k bytes, did it cross 128k ?
	test	ax,NOT 01fh		; if into next 128k it will go into next
					; bit
	je	fdp_no_cross		;   N: continue
	cmp	[crossed],0		;  Y:Q: have we crossed it before ?
	je	fdp_cross1		;      N: update counts
	and	ax,01fh 		;      Y:Q: equal to 128k bndry ?
	jnz	fdp_exit		;	    N: then leave
	inc	[a_cnt] 		;	    Y: update last cnt
	jmp	fdp_exit		;	       and leave

fdp_cross1:				;  first crossing of 128k bndry
	mov	[crossed],1		; set crossed flag.
	mov	[a_start],bx		; start with ...
	inc	[a_start]		;   next page.
	and	ax,01fh 		;Q: equal to 128k bndry ?
	jnz	fdp_next		;  N: next page
	inc	[b_cnt] 		;  Y: include page in before pages
	jmp	fdp_next		;  and go to next page

fdp_no_cross:
	cmp	[crossed],0		;Q: have we crossed first 64k bndry ?
	jne	fdp_n_c 		;  Y: update it's count
	inc	[b_cnt] 		;  N: update before count
	jmp	fdp_next
fdp_n_c:
	inc	[a_cnt] 		;    update after count
fdp_next:
	inc	bx			;  next page #
	loop	fdp_loop		;     and continue
;
fdp_exit:
	mov	bx,[b_start]		; BX = first page before
	mov	cx,[b_cnt]		; CX = cnt of pages before
	cmp	cx,[a_cnt]		;Q: more before than after ?
	jae	fdp_ret 		;  Y: return pages before
	mov	bx,[a_start]		;  N: return pages after
	mov	cx,[a_cnt]		;
fdp_ret:
	pop	eax			 ; restore EAX
	ret
;
FindDMA endp

LAST	ends				; end of segment
;
	end				; end of module
