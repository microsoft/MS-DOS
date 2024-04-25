

	page 58,132
;******************************************************************************
	title	EMMINIT - Expanded Memory Manager initialization
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:	EMMINIT - Expanded Memory Manager initialization routine
;
;   Version:	0.05
;
;   Date:	May 24 ,1986
;
;   Author:
;
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;	04/16/86 Original	Adapted from DOS clock driver.
;	05/24/86 0.00		From EMML test driver.
;	06/21/86 0.02		added cld to EMM_Init
;	06/28/86 0.02		Name change from MEMM386 to MEMM
;	06/29/86 0.02		INC AX (was INC AL) for emm_free init
;	07/06/86 0.04		Size _emm_page,_emm_free, & _pft386 based
;				on # of pages in system
;	07/06/86 0.04		Changed assume to DGROUP
;	07/10/86 0.05		moved int 67h patch to INIT
;	06/07/88		added FRS_array initialization (Paul Chan)
;
;******************************************************************************
;   Functional Description:
;	This module initializes the data structures for the EMM
;   and sets the current emm data break address (_emm_brk).
;
;******************************************************************************
.lfcond
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	EMM_Init
	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
	include	vdmseg.inc
	include emmdef.inc

FALSE	equ	0
TRUE	equ	not FALSE

EMM_HW_ERROR	equ	81h		; EMM h/w error status

;******************************************************************************
;			E X T E R N A L    R E F E R E N C E S
;******************************************************************************
;
_DATA	segment

extrn	pool_size:word    	; size of EMM Pages Pool in kbytes
extrn	xbase_addr_h:byte	; bit 16-24 of address of first byte of emm memory
extrn	xbase_addr_l:word	; bit  0-15 of address of first byte of emm memory
extrn	sys_size:word		; number of 16k pages taken away from conv. mem
extrn	PageT_Seg:word		; segment of system page table

extrn	_PF_Base:word		 ; segment addr of page frame base
extrn	_page_frame_pages:word	; number of pages in 3.2 page frame

extrn	_EMMstatus:word		; status of EMM

extrn	_page_frame_base:word	; pointers into page tables for each window
extrn	_mappable_pages:word	; mappable page array
extrn	_EMM_MPindex:byte	; index into mappable page array
extrn	_physical_page_count:word   ; number of physical pages
extrn	_mappable_page_count:word   ; number of mappable pages

extrn	_cntxt_pages:word	; pages in a context
extrn	_cntxt_bytes:word	; bytes in a context

extrn	_emm_page:word		; ptr to array of EMM pages
extrn	_free_count:word	; # of free EMM pages
extrn	_emmpt_start:word	; start of empty part of emm page
extrn	_emm_free:word		; ptr to array of free EMM pages
extrn	_free_top:word		; top of _emm_free

extrn	_total_pages:word	; total # of EMM pages available
extrn	_pft386:word		; ptr to array of page table entries

extrn	_emm_brk:word		; offset for emm data break address

extrn	FRS_array:word		; 
extrn	CurRegSetn:byte
extrn	CurRegSet:word
extrn	FRS_free:byte

extrn	_handle_table:word
extrn	_handle_count:word

_DATA	ends

ifndef	NOHIMEM
else
VDATA	segment
extrn	vdata_begin:byte
VDATA	ends
endif

LAST	segment
extrn	mappable_segs:byte
LAST	ends

_TEXT	segment
extrn  InitELIM:far
_TEXT	ends

LAST	segment
extrn	InitEPage:near
LAST	ends


	page
;******************************************************************************
;			S E G M E N T   D E F I N I T I O N
;******************************************************************************
;
;******************************************************************************
;
;	Code Segment
;
;******************************************************************************
;******************************************************************************
; MACROS used in the EMM initialisation code
;******************************************************************************
;******************************************************************************
;
; Get_FRS_window - get pointer to Fast Register Set window
;
;	ENTRY:	Reg - points to an FRS_struc
;
;	EXIT:	Reg - points to FRS_window entry in the structure
;
;	USES:	Reg
;
;******************************************************************************
Get_FRS_window	MACRO	Reg

	mov	Reg, word ptr [CurRegSet]	; just offset (assume dgroup)
	add	Reg, FRS_window			; points to FRS window entries
	ENDM

;******************************************************************************
;**init_PAGE_FRAME_BASE: macro to fill in the page_frame_base array.  this
;  array contains the selector:offset into page table. The selector is already
;  initialised.  So the offset of each of the physical pages into the page
;  table needs to be filled in.
;
;  ENTRY: SI = INDEX INTO _page_frame_base, also physical page #
;	  BX = Segment of physical page
;
;******************************************************************************
init_page_frame_base	MACRO
;
    push    si
    push    bx
;
    shl     si,2		    ; convert index into offset in dword array
;
    shr     bx,6		    ; convert segment into page table offset
				    ; since there is 1 dword entry for each 4k
				    ;
    mov     _page_frame_base[si],bx ; fill this in
;
    pop     bx
    pop     si
;
    ENDM

;******************************************************************************
;**init_MAPPABLE_PAGES: macro to fill the _mappable_pages array.  this array
;  contains the segment and physical page number of all the mappable physical
;  pages.
;
;  ENTRY: SI = INDEX INTO _page_frame_base, also physical page #
;	  BX = Segment of physical page
;	  DI = Index into _mappable_pages
;
;******************************************************************************
init_mappable_pages	MACRO
;
    push    di
;
    shl     di,2		    ; convert index into offset in dword array
;
    mov     _mappable_pages[di],bx  ; fill in segment
    mov     _mappable_pages[di][2],si	; and physical page number
;
    pop     di
;
    ENDM

;******************************************************************************
;**init_MAPPABLE_INDEX: macro to fill in EMM_MPIndex array.  This array
;  contains a cross reference for the memory from 4000h to 10000h into the
;  mappable_pages array.  There is an entry for each 16k page. The pages in
;  this range which are not mappable are initialised to -1.  The ones which
;  are mappable are initialised to the index into the mappable_pages array
;  for the entry which represents this page
;
;  ENTRY: DI = Index into _mappable_pages
;	  BX = Segment of physical page
;
;******************************************************************************
init_mappable_index	MACRO
;
    push    ax
    push    bx
;
    shr     bx,10		    ; convert segment to 16k page #
    sub     bx,CONV_STRT_PG	    ; first page in EMM_MPIndex array is 16
;
    mov     ax,di		    ; to extract the lower byte
    mov     _EMM_MPIndex[bx],al     ; fill in index
;
    pop     bx
    pop     ax
;
    ENDM

;******************************************************************************
; INVALIDATE_MAPPABLE_PAGE_ENTRY: macro to remove the page from the mappable
; page temporary list we are using.  this is to facilitate the recognition
; of pages above A000 which are not page frame pages.  When we recognise page
; frame pages we invalidate them so that the subsequent pass for pages doesn't
; include these.
;
;  ENTRY: BX = Segment of physical page
;******************************************************************************
inv_mpbl    MACRO
;
    push    bx
;
    shr     bx,10		    ; convert segment to 16k page #
    mov     cs:mappable_segs[bx],PAGE_NOT_MAPPABLE
;
    pop     bx
;

    ENDM

;
LAST	segment     USE16
	assume	cs:LAST, ds:DGROUP, es:DGROUP

;******************************************************************************
; LOCAL VARIABLES
;******************************************************************************
first_sys_ppage  dw	 0ffffh      ; physical page number of first system page

	page
;******************************************************************************
;
; CODE FOR INITIALISATION
;
;******************************************************************************


	page
;******************************************************************************
;	EMM_Init - initialization routine for EMM.
;			Patches int 67h vector.
;
;	ENTRY: none
;
;	EXIT:	EMM vector initialized.
;		EMM data structures initialized
;		NC => no errors
;		C => errors
;
;	USED: none
;
;******************************************************************************
EMM_Init	proc	near
;
	pusha
	push	ds
	push	es
;
;  set DS,ES to DGROUP segment
;
	mov	ax,seg DGROUP
	mov	ds,ax
	mov	es,ax
;
	cld				; strings foward
;
;  init EMM status
;
	mov	[_EMMstatus],0

;
; set total # of EMM pages
;
	mov	cx,[pool_size]		; CX = kbytes of expanded memory
	shr	cx,4			; CX = # of EMM pages available
	mov	[_total_pages],cx	; pages total
;
; init ptrs for _emm_page, _emm_free and _pft386
;
	shl	cx,1			; CX = bytes in total_pages words

ifndef	NOHIMEM
else
	mov	ax,seg VDATA
	sub	ax,seg DGROUP
	shl	ax,4			; convert into offset from dgroup
	add	ax,offset VDATA:vdata_begin
	mov	[_emm_page],ax
endif


	mov	ax,[_emm_page]		; AX = ptr to emm_page array
	add	ax,cx			; AX = ptr to word just past emm_page[]
	mov	[_emm_free],ax		; set ptr for emm_free[]
	add	ax,cx			; AX = ptr to word just past emm_free[]
	mov	[_pft386],ax		; set ptr for _pft386[]
	shl	cx,1			; CX = bytes in total_pages dwords
	add	ax,cx			; AX = ptr to word just past _pft386[]
	mov	[_emm_brk],ax		; set break address for emm data
	shr	cx,2			; CX = total_pages again
;
; init free pages array
;
	mov	[_free_count],cx	; all pages free initially
	mov	[_free_top],0		;  top ptr pts to first free page
	mov	di,[_emm_free]		; ES:DI pts to _emm_free[0]
	mov	bx,[_free_top]		;  BX = current top of free list
	shl	bx,1
	add	di,bx			; ES:DI pts to begin of free page area
	xor	ax,ax			; start with EMM page#0
EMMP_loop:				;   copy free pages into _emm_free
	stosw				; store EMM page#
	inc	ax			;(0.02) increment page#
	loop	EMMP_loop		;Q: all entries in _emm_free[] ?
					;  N: do next page.
;
; fix _page_frame_pages to be a maximum of 4 (for the LIM 3.2 frame)
;
	cmp	[_page_frame_pages],4
	jbe	EMIN_1
	mov	[_page_frame_pages],4
EMIN_1:
;
; See validity of page frame
;
	test	[_PF_base],3ffh        ; if any of these bits are set it is
					; invalid
	jne	EMIN_2			 ;
	cmp	[_PF_base],0E400h	; in the ROM area
	jae	EMIN_2			 ; also invalid
	cmp	[_PF_base],0C000h	; or in the video area
	jnb	EMIN_3			 ;
EMIN_2:
;
; Page Frame invalid, set it to FFFFh and _page_frame_pages to 0
;
	mov	[_PF_base],0FFFFh
	mov	[_page_frame_pages],0
;
EMIN_3:
;
; setting up _page_frame_base
;	     _mappable_pages
;	     _EMM_MPIndex
;	     _physical_page_count
;	     _mappable_page_count
;
;
;
;   -----------------	    -----------------	    -----------------
;   |	for pages   |	    |	 for pages  |	    |		    |FC00h
;   |	  below     |	    |	  below     |	    |---------------|
;   |	  A000h     |	    |	  A000h     |	    |		    |
;   -----------------	    -----------------	    |		    |
;   |		    |	    |		    |	    |	   .	    |
;   |	for pages   |	    |	for pages   |	    |	   .	    |
;   |	  above     |	    |	above	    |	    |	   .	    |
;   |	  A000h     |	    |	A000h	    | <--   |		    |
;   |		    |	    |		    |	|   |---------------|
;   -----------------	    -----------------	|   |		    |4800h
;   | for page frame|	    | for page frame|	|   |---------------|
;   | pages even if |	    | pages only if |	|-------	    |4400h
;   |	they don't  |       |   they exist  |       |---------------|
;   |	  exist     |	    |		    |	    |		    |4000h
;   -----------------	    -----------------	    -----------------
;
;   _page_frame_base	    _mappable_pages	     EMM_MPIndex
;
;   Each entry reps	    Each entry reps	     Each entry reps
;   a physical page.	    a mappable ph. page      a system page
;
;   DWORD.		    DWORD		     Byte
;
;   1st WORD: offset	    1st WORD: segment	     Index into
;   into page table	    of ph. page 	     _mappable_pages
;						     which reps the page
;   2nd WORD: sel.	    2nd WORD: physical
;   of page table	    page # of ph. page
;
;
; 1. Set up for the page frame pages.  Note that they may or may not exist.
;    Even if they do not exist entries must be set up for them in the
;    _page_frame_base.
;
    ;
    ; initialise indexes.
    ;
	xor	si,si			; index into _page_frame_pages
					; thus also physical page number
	xor	di,di			; index into _mappable_pages
    ;
    ; set up for page frame pages
    ;
	mov	cx,[_page_frame_pages]	; get number
	jcxz	EMIN_5			 ; if none exist then skip next portion
    ;
	mov	bx,[_PF_base]		; get page frame base
    ;
    ; the setup loop:
    ;
EMIN_4:
	init_page_frame_base
	init_mappable_pages
	init_mappable_index
	inv_mpbl
    ;
    ; update counters for next entry
    ;
	inc	si
	inc	di
	add	bx,0400h
    ;
    ; and loop back
    ;
	loop	EMIN_4
;
EMIN_5:
;
; 2. If page frame pages were less than 4 then also we should set aside
;    four entries in the physical page array
;
	mov	si,4
;
; 3. Setup for the mappable pages above A000h.	Search the mappable_segs
;    array for mappable pages above A000h and for each mappable page make
;    an entry in the arrays
;
    ;
    ; setup the segment and the count of pages we have to look for. also
    ; the index into the mappable_segs array
    ;
	mov	bx,0A000h		; segment
	mov	dx,bx			;
	shr	dx,10			; page # corresponding to segment
    ;
	mov	cx,64			; max page #
	sub	cx,dx			;
    ;
    ; setup loop
EMIN_6:
    ;
    ; see if page mappable
    ;
	xchg	dx,bx
	cmp	cs:mappable_segs[bx],PAGE_MAPPABLE ;
	xchg	dx,bx
	jnz	EMIN_7
    ;
    ; page mappable. set up entries for it
    ;
	init_page_frame_base		; set up the page_frame_base entry
	init_mappable_pages		; set up the mappable_pages entry
	init_mappable_index		; set up the EMM_MPIndex
    ;
    ; update counters for next entry
    ;
	inc	si			; these two are only updated
	inc	di			; if an entry is found
EMIN_7:
	inc	dx			; and these two are updated in
	add	bx,0400h		; any case
    ;
    ; and loop back
    ;
	loop	EMIN_6

;
; 4. Finally set up for the system pages
;
    ;
    ; store the physical page # of the 1st system page.
    ;
	mov	cs:[first_sys_ppage],si
    ;
    ; setup the segment and the count of pages we have to look for. also
    ; the index into the mappable_segs array
    ;
	mov	bx,04000h		; segment
	mov	dx,bx			;
	shr	dx,10			; page # corresponding to segment
    ;
	mov	cx,40			; max page #
	sub	cx,dx			;
					; number of pages to be examined
    ;
    ; setup loop
EMIN_8:
    ;
    ; see if page mappable.
    ;
	xchg	dx,bx
	cmp	cs:mappable_segs[bx],PAGE_MAPPABLE ;
	xchg	dx,bx
	jnz	EMIN_9
    ;
    ; page mappable. set up entries for it
    ;
	init_page_frame_base		; set up the page_frame_base entry
	init_mappable_pages		; set up the mappable_pages entry
	init_mappable_index		; set up the EMM_MPIndex
    ;
    ; update counters for next entry
    ;
	inc	si			; these two are only updated
	inc	di			; if an entry is found
EMIN_9:
	inc	dx			; and these two are updated in
	add	bx,0400h		; any case
    ;
    ; and loop back
    ;
	loop	EMIN_8
;
; 5. finally use the indexes to fill up the counts of the number of entries in
;    each array.
;
	mov	[_physical_page_count],si
	mov	[_mappable_page_count],di
;
;
; 6. and the pages in a context and the number of bytes needed to save a
;    context.
;
	inc	si			; cntxt_pages = (physical_page_count
					; + 1) & NOT 1
	and	si, NOT 0001h		; to round up si to higher even #
	mov	[_cntxt_pages],si	; number of pages in a context
;
	shl	si,1
	add	si,2			; cntxt_bytes = cntxt_pages*2 + 2
	mov	[_cntxt_bytes],si	;
;

;
; initialize FRS_array
;
	lea	si,FRS_array		; DS:SI <-- FRS_array
	mov	[si.FRS_alloc], 1	; mark FRS set 0 as allocated
	mov	[CurRegSetn], 0		; use FRS set 0
	mov	[FRS_free], FRS_COUNT-1	; one less FRS set
	mov	word ptr [CurRegSet], SI; save current FRS pointer

;
; NOW for some Handle 0 initialisation.  We have to reclaim the pages we
; released to the emm page pool from the conventional memory.  This is
; easy.  These happen to be the first k pages in the emm page pool.  We
; need to fix the following data structures to reclaim these.
;
; k pages need to be transferred to emm_page array from emm_free array
; and emmpt_start, _free_top, _free_count and _handle_table and _handle_count
; updated
    ;
    ; find out the number of pages to be reclaimed
    ;
	mov	cx,[sys_size]	    ; in kb
	shr	cx, 4		    ; convert to number of 16k pages
    ;
    ; transfer these many pages from the emm_free array to the emm_pages array
    ;
	push	cx
    ;
	mov	si,_emm_free	    ;
	add	si,_free_top	    ;
	add	si,_free_top	    ; get offset to free page
    ;
	mov	di,_emm_page	    ;
	add	di,_emmpt_start     ;
	add	di,_emmpt_start     ; get offset to next available loc in
				    ; emm_page
    ;
	cld
	rep	movsw		    ; transfer the pages over
    ;
	pop	cx
    ;
    ; fix entry for handle 0 in handle table
    ;
	mov	dx, [_emmpt_start]
	mov	_handle_table[0],dx ; offset into emm_page array
	mov	_handle_table[2],cx ; number of pages
    ;
    ; handle_count needs to be incremented to indicate that handle 0 is
    ; allocated
    ;
	inc	[_handle_count]
    ;
    ; fix ptr in emm page tracking arrays
    ;
	add	[_emmpt_start],cx
	add	[_free_top],cx
	sub	[_free_count],cx
;
; Initialise FRS initialisation
;
; di = pointer into FRS. bx = physical page number. si = pointer into emm_page
; cx = number of pages mapped.
;
	mov	si,_handle_table[0] ; get pointer into emm_page
	shl	si,1		    ; emm_page is a word array
	add	si,[_emm_page]	    ;
    ;
	GET_FRS_WINDOW	di	    ; get pointer to FRS area

	mov	bx,cs:[first_sys_ppage]
	shl	bx,1
	add	di,bx		    ;
    ;
	cld
	rep	movsw
    ;
;
; the way we have allocated the pages we don't need to  update the Page table
; the pages that have been mapped
;
;  init ELIM h/w emulation (DMA PORTS)
;
	call	InitELIM

;
;  init EMM_PTE - ptrs to EMM pages
;
	call	InitEPage
;
;  leave - no errors
;
	pop	es
	pop	ds
	popa
;
	xor	ax,ax
	clc
	ret
;
EMM_Init	endp

;
LAST	ends

	end
