

page	58,132
;******************************************************************************
	title	MapDMA - Ensure all DMA transfers are physically contiguous
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   MapDMA
;
;   Version:  0.04
;
;   Date:     June 18,1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   06/18/86  Original
;   07/02/86  0.03	Added check for ECX = 0
;   07/02/86  0.03	MapLinear added to set_selector
;   07/06/86  0.04	Changed _pft386 to ptr to _pft386 array
;   07/06/86  0.04	Changed assume to DGROUP
;
;******************************************************************************
;
;   Functional Description:
;
;	This module ensures that EMM pages accessed by a DMA transfer (within
;  the EMM Page Frame) are physically contiguous in memory.  This is accomplished
;  by physically relocating entire EMM pages so that all of the pages participating
;  in the DMA transfer are adjacent.  As a first pass, pages that need to be
;  relocated will always be moved to the base address of extended memory (or
;  possibly hi memory if that option is selected).  A four word array (DMA_Pages)
;  initialized by InitEPG will contain the actual 32 bit physical address of 
;  the first four physical EMM page locations.  Although this will decrease
;  the time necessary to search for potential relocation candidates, it could
;  also result in the relocation of all pages when a fewer number might suffice
;  (given a more elegant mapping scheme).
;
;   Some transfers that will NOT require remapping are:
;	1.  The DMA transfer is entirely outside the EMM Page Frame
;	2.  The DMA transfer is entirely within one Page Frame Window
;	3.  The DMA transfer spans more than one Page Frame Window, but
;	    the EMM pages currently residing there are already contiguous
;	4.  See number 4 below
;
;   Some transfers that will result in an exception are:
;	1.  The DMA transfer spans more than one Page Frame Window, where
;	    at least one (but not all) of the windows is currently unmapped.
;	2.  The DMA transfer spans more than one Page Frame Window, with
;	    the same EMM page residing in more than one of the windows
;	3.  The DMA transfer spans more than one Page Frame Window, but there
;	    is physically not enough contiguous memory in which to locate the
;	    requested EMM Pages.  (This could occur in the model where both
;	    extended memory and hi memory combine to form the EMM pool)
;	4.  The DMA transfer includes memory outside the Page Frame, AND
;	    INSIDE the Page Frame (unless the Page Frame Windows are currently
;	    unmapped, in which case no relocation is necessary)
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	MapDMA
	public	DMA_Pages
	public	DMA_PAGE_COUNT

	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
	include VDMseg.inc
	include VDMsel.inc
	include desc.inc
	include page.inc
	include	instr386.inc
	include	vm386.inc
	include emmdef.inc
;
;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************
;
ABS0	segment use16 at 0000h
ABS0	ends

_DATA	segment

extrn	_page_frame_base:dword	; Page Table Entry pointers for windows 0-3
extrn	_pft386:word		; ptr to array of Page Table entries
;extrn	_current_map:byte	; current mapping register values
extrn	PF_Base:word		; Base addr of page frame
extrn	_total_pages:word	; total number of EMM pages
extrn	Page_Dir:word		

xfer_map	dw	0	; map of windows participating in DMA xfer
_DATA	ends

_TEXT	segment

	extrn	ErrHndlr:near
	extrn	MapLinear:near

_TEXT	ends

;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************
;
_DATA	segment

;
;    DMA_Pages - EMM Pages for DMA relocation. Each is an index into pft386.
;	To access actual entry in pft386 you need to multiply index by 4.
;	If eight contingous 16k EMM pages are not available - the unavailable
;	entries are left at NULL_PAGE.
;	This array should be initialized at boot time.
;
DMA_Pages	dw	8 dup (NULL_PAGE)   ; null for start
DMA_PAGE_COUNT	dw	0		    ; number of above initialised

_DATA	ends

;------------------------------------------------------------------------------
_TEXT	segment

	assume	cs:_TEXT, ds:DGROUP, es:DGROUP, ss:DGROUP		   
	page
;******************************************************************************
;   MapDMA - Relocate (if necessary) EMM pages to ensure that a DMA transfer
;	     is contiguous
;
;   ENTRY: Protected Mode Ring 0
;	   EAX = linear base address of DMA transfer
;	   ECX = byte count of transfer
;	   DGROUP:[_pft386] = ptr to dword array of ptrs for EMM Pages
;	   DGROUP:[DMA_Pages] = array of EMM page addresses in 1st 64k (used for
;			       relocating pages to contiguous physical memory)
;
;   EXIT:  Protected mode Ring 0
;	   EAX = physical base address for DMA transfer
;	   DGROUP:_pft386[] = modified to reflect relocation of EMM pages
;	   Page Table Entries modified to reflect relocation.
;	   CY = CLEAR if exit address = entry address
;	   CY = SET   if exit address <> entry address (mapping was necessary)
;
;   USED:  EAX
;	   Flags
;   STACK:
;******************************************************************************
MapDMA proc	 near
;
	PUSH_EBX
	PUSH_EAX			; save original address
	PUSH_ECX
	PUSH_EDX
	PUSH_EDI
	PUSH_ESI
	push	es
;
	cld
;
;  check for ECX = 0
;
	jecxz	nomap1			; nomap out of jmp range
	jmp	short mDMA_domap
nomap1:
	jmp	nomap
;
;  As a quick first check, let's see if this transfer is any where near the PF
;
mDMA_domap:
	mov	ebx,eax			; get address
	shr	ebx,16	    		; get rid of 64k
	mov	dx,[PF_Base]		; base address of Page Frame div 4
	mov	di,dx			; save it
	shr	dx,12			; divide by 64k
	cmp	bx,dx			; q: is it in PF?
	jb	nomap			; n: no mapping necessary
	add	di,0fffh		; plus 64k div 4 for end of PF
	shr	di,12			; divide by 64k
	cmp	bx,di			; q: before end of PF?
	ja	nomap			; n: no mapping necessary
;
	push	ax			; save lower 16 bits of addr
	mov	ebx,4000h		; window size
;
;   build a map of windows used in this transfer
;
	mov	[xfer_map],0		; zero to start with
	dec	ecx			; stop at last byte
lloop:
	call	chk_loc			; mark this guy's location in the map
	or	ecx,ecx			; q: done?
	jz	chk_done		; y
	cmp	ecx,ebx			; n: q: is there a whole window left?
	jae	full_wind		;    y: skip the adjustment
	mov	bx,cx			;    n: just check what's left
full_wind:
	sub	ecx,ebx			; adjust count by window size
	add	ax,bx			; and base addr (let it wrap)
	jmp	lloop			; do the next one
chk_done:
	pop	ax			; restore base addr of transfer
	shl	[xfer_map],1		; q: is the transfer outside the PF?
	jnc	in_PF			; n: entirely within Page Frame
;
;  At least part of the transfer involves an area outside the Page Frame.
;  This is ok as long as all parts inside the Page Frame are currently unmapped.
;
	mov	cx,[xfer_map]		; get the map values
	xor	si,si			; set up to check all windows
	xor	edx,edx			; clean out high bits
	mov	dx,[PF_Base]		; dx = address of window 0
	shl	edx,4			; make it 32 bits
mloop1:
	shl	cx,1			; q: is this window involved?
	jnc	not_inv			; n: not involved but still more to check
	call	IsMapped		; q: is this page mapped?
	jne	excp			; y: exception (can't handle it)
not_inv:
	add	edx, 4000h			; n: update address of window
	add	si,4			; and _page_frame_base index
	or	cx,cx			; q: any more to check?
	jnz	mloop1			; y: check the next window
;
nomap:	jmp	DMA_nomap		; don't need to relocate
;
excp:	jmp	DMA_excp		; exception (can't deal with this)
;
;  The DMA transfer is entirely within the Page Frame area.  If the
;  physical location of the EMM pages (mapped into the windows participating
;  in the DMA transfer) are already contiguous, then don't do anything.
;  Otherwise, relocate them to the base area.
;
;  eax >= [PF_Base]  = linear base address of xfer 
;
in_PF:
	mov	bx,[xfer_map]		; get a copy of the map
	shr	bx,4			; duplicate on the end
	or	[xfer_map],bx		; ... for wraparound
	op32
	mov	cx,ax			; ecx = base addr of xfer
	op32
	shr	cx,4			; paragraph form
	sub	cx,[PF_Base]
 	shr	cx,10			; cx = starting window of transfer
	shl	[xfer_map],cl		; position on 1st window of transfer
	and	[xfer_map],0f7ffh	; only 1st 4 windows are valid
	shl	[xfer_map],1		; we know there's at least one
	or	[xfer_map],cx		; save starting window number
	mov	bx,cx			; bx = starting window
	shl	bx,2			; bx = double word index
	mov	cx,[xfer_map]		; get map back
	les	di,_page_frame_base[bx]	; es:di = page table pointer for window bx
	and	ax,3fffh		; get lower 14 bits
	push	ax			; save lower 14 bits of starting addr
	op32
	mov	ax,es:[di]		; get page table entry
	and	ax,0f000h		; get rid of lower 12 bits
	push_eax			; save physical address
;
;  bx = window number to check for contiguity
;  eax = physical address of EMM page mapped into previous window
;  cx = bit map of windows participating in the transfer
;
c_chk:
	shl	cx,1			; q: is the next window involved?
	jnc	DMA_addr 		; n: no need to check any more
	add	bx,4			; next window
	and	bx,0fh			; mod 16
	add     ax,4000h		; next physically contiguous window
	les	di,_page_frame_base[bx]	; es:di = page table pointer for window bx
	op32
	mov	dx,es:[di]		; get page table entry
	and	dx,0f000h		; get rid of lower 12 bits
	op32
	cmp	ax,dx			; q: contiguous?
	je	c_chk			; y: check next window 
;
	jmp	DMA_reloc		; They were not contiguous, must relocate
DMA_addr:
	pop_eax				; top part of actual address
	pop	dx			; get second half of actual address
	or	ax,dx			; form real address
	jmp	DMA_nomap		; don't need to map
;
;  Relocate EMM pages mapped into the windows starting with the
;  low order bits of [xfer_map], for as many high bits of [xfer_map].
;  The lower 14 bits of original address are still on the stack
;
DMA_reloc:
	pop_eax				; top part of actual address
	mov	bx,[xfer_map]		; get map
	mov	cx,bx			; copy it
	and	bx,3			; bx = starting window number
	xor	di,di			; di = index into DMA_Pages
reloc_loop:
	mov	si,12			; board index for _current_map
	push	cx			; save window map
	mov	cx,4			; 4 boards
bloop:
; WE NEED TO WORK ON THE DMA MORE
; BUT int the mean time, ignore _current_map (Paul Chan)
;	mov	dl,_current_map[bx+si]	; get mapping register value
	shl	dl,1			; q: is it mapped?
	jnc	next_board		; n: try next board
	mov	dh,cl			; y: dh = board number	
	dec	dh			; board is zero relative
	shr	dx,1			; dx = EMM page number
	cmp	dx,[_total_pages]	; q: is this page in range?
	jb	found_page		; y: go relocate it
next_board:				; n: try next board
	sub	si,4			; update index to _current_map
	loop	bloop			; do another
;
;  If we ever get here, we've got a problem in the data structures, or
;  in the previous couple of hundred lines since we couldn't seem to locate
;  any pages occupying window bx (which should have generated an exception
;  long ago).  In either case, we might just as well call it an exception.
excp2:	jmp	DMA_excp		; don't know what else to do
;
;  At this point we have found the EMM page (= dx) occupying window bx.
;  di is the index into DMA_Pages that tells us the physical address of this
;  particular relocation area.  Now we need to run through _pft386 and find
;  this address so we can swap him with page dx.  If DMA_Pages contains -1,
;  then we just don't have the physically contiguous memory to get the job done.
;
found_page:
	push	di				; save di
	op32
	mov	ax,DMA_Pages[di]		; get addr of relocation area
	op32
	or	ax,ax				; q: -1?
	js	excp2				; y: not enough contig memory
	mov	cx,[_total_pages]		; number of entries in _pft386
	mov	si,-4				; index into _pft386
	add	si,[_pft386]			; si = ptr for _pft386 array
floop:
	add	si,4				; point to next entry
	op32
	mov	di,[si]				; get pft entry
	and	di,0f000h			; get rid of low 12 bits
	op32
	cmp	di,ax				; q: did we find who's there?
	loopne	floop				; n: keep looking
	jne	excp2				; whoops, nobody was using it
;
;  si = ptr to EMM page currently using our relocation area.
;	Swap it with EMM page # dx
;
	mov	di,dx				; page number in window
	shl	di,2				; offset for _pft386
	add	di,[_pft386]			; di -> EMM page#dx entry
	cmp	di,si				; q: was it us all along?
	je	no_swap				; y: don't need to move it
	op32
	mov	dx,[di]				; PTE for this page
	and	dx,0f000h			; get rid of low 12 bits
;
;    DS:SI -> relocation page entry in _pft386
;    DS:DI -> EMM page # dx entry in _pft386
;  check to see if we have already relocated this guy once.  If so, that
;  implies that the same EMM page is mapped into more than one window.
;  Since there is no way (without scratch buffers) to make that contiguous,
;  we will just abort.
;
	op32
	cmp	dx,[DMA_Pages]			; q: have we already relocated it?
	jb	no_dup				; n: ok
	op32
	cmp	dx,ax				; q: is it in the relocation area?
	jb	excp2				; y: sorry
no_dup:
	op32
	and	[si],0fffh			; preserve his 12 bits
	dw	0
	op32
	or	[si],dx				; move in his new address
	op32
	and	[di],0fffh			; now do the same thing
	dw	0				; for the page in the window
	op32
	or	[di],ax				; fix up his address
;
;  swap pages residing at addresses eax and edx
;
	push_eax				; save address in window
	push	ds
	mov	di,MBSRC_GSEL			; source selector
	call	set_selector			; set to address eax
	mov	es,di
	mov	di,MBTAR_GSEL			; destination selector
	op32
	mov	ax,dx				; destination
	call	set_selector			; set up selector
	mov	ds,di
	mov	cx,1000h			; 16k bytes (4 at a time)
	xor	di,di				; initialize index
sloop:
	op32
	mov	ax,es:[di]			; get a word from dest.
	op32
	xchg	ax,ds:[di]			; swap with source
	op32
	stosw					; store in dest.
	loop	sloop				; do the next one
;
	pop	ds
	pop_eax					; restore physical address
	
no_swap:


	pop	di				; index into DMA_Pages
	add	di,4				; update index
	pop	cx				; window map
	inc	bx				; next window number
	and	bx,3				; mod 4
	shl	cx,1				; q: any left?
	jnc	fix_pte				; n: done relocating
	jmp 	reloc_loop			; y: relocate the next page
fix_pte:
;
;  Now set all 4 entries in page table.  Rather than try to figure out exactly
;  which entries in here have changed, we will reset all entries shown as
;  being "mapped" by _current_map.  Unmapped entries shouldn't have changed.
;
	mov	cx,15				; start at last entry
ploop:
	mov	si,cx				; copy index
;	mov	bl,_current_map[si]		; get current_map entry
	shl	bl,1				; q: is it mapped?
	jnc	pte_not_mapped			; n: try next
	mov	bh,cl				; copy index number
	shr	bh,2				; get board number
	shr	bx,1				; bx = emm page number
	cmp	bx,[_total_pages]		; q: in range?
	jae	pte_not_mapped			; n: try next
	shl	bx,2				; y: index into _pft386
	add	bx,[_pft386]			;     ptr into _pft386
	op32
	mov	ax,[bx]				; y: get pte value
	and	ax,0f000h			; get rid of lower 12 bits
	mov	si,cx				; get index number
	and	si,3				; get window number
	shl	si,2				; 32 bit index
	les	di,_page_frame_base[si]		; pointer to page table entry
	or	ax,P_AVAIL			; set access bits
	op32
	stosw					; set 1st Page Table Entry

	add_eax_ 1000h				; 2nd 386 page
	op32
	stosw					; set 2nd Page Table Entry

	add_eax_ 1000h				; 3rd 386 page
	op32
	stosw					; set 3rd Page Table Entry

	add_eax_ 1000h				; 4th 386 page
	op32
	stosw					; set 4th Page Table Entry
pte_not_mapped:
	dec	cx   				; q: done with _current_map?
	jns	ploop				; n: keep going
	   
;
;   reload CR3 to flush TLB
;
	db	66h
	mov	ax,[Page_Dir]		; mov EAX,dword ptr [Page_Dir]
	db	0Fh,22h,18h		; mov CR3,EAX
	op32
	mov	ax,[DMA_Pages]		; get physical address to return
	pop	dx			; don't forget about the lower 14 bits
	or	ax,dx
;
;	eax = physical address for DMA transfer
;
DMA_nomap:
 	pop	es
	POP_ESI
	POP_EDI
	POP_EDX
	POP_ECX
	POP_EBX				; get original eax
	clc				; assume they're the same
	OP32
	cmp	ax,bx			; q: did we have to map?
	je	cy_noset		; n: don't set carry
	stc				; y: set carry
cy_noset:
	POP_EBX
;
	ret
DMA_excp:
	mov	ax,ExcpErr
	mov	bx,ErrDMA		
	jmp	ErrHndlr			; don't come back
	
MapDMA		endp


	page
;******************************************************************************
;   IsMapped - Check whether or not a window is unmapped
;
;   ENTRY: Protected Mode Ring 0
;	   si = window number * 4
;	   edx = physical address of Page Frame Window
;	   DGROUP:[_page_frame_base] = array of ptrs to page table entries
;
;   EXIT:  Protected mode Ring 0
;	   ZF = unmapped
;	   NZF= mapped
;
;   USED:  di,ebx,es
;	   Flags
;   STACK:
;******************************************************************************
isMapped	proc	near
	les	di,_page_frame_base[si]	; es:di = addr of page table entry
	op32
	mov	bx,es:[di]		; ebx = page table entry for window
	and	bx,0f000h		; mask off low order 12 bits
	op32
	cmp	bx,dx			; q: is it mapped to itself (unmapped)?
	ret
isMapped	endp


	page
;******************************************************************************
;   chk_loc - Check the location of a given address and update map accordingly
;
;   ENTRY: Protected Mode Ring 0
;	   eax = physical address to check
;	   DGROUP:[xfer_map] = map of addresses used in this transfer     
;				bit 16 indicates an address outside the PF
;				bits 15-12 correspond to windows 0-3 resp.
;
;   EXIT:  Protected mode Ring 0
;	   DGROUP:[xfer_map] = updated as necessary
;
;   USED:  none
;	   Flags
;   STACK:
;******************************************************************************
chk_loc 	proc	near
	push_eax			; save address
	push	cx
;
	mov	ch,80h			; set high bit (outside indicator)
	op32
	shr	ax,4			; put in paragraph form
	sub	ax,[PF_Base]		; make it relative to base of Page Frame
	jb	outside			; outside of page frame
	op32
	shr	ax,10			; ax = window number
	cmp_eax_ 3			; q: inside Page Frame?
	ja	outside			; n: outside
	mov	cl,al			;
	inc	cl			; skip over outside bit
	shr	ch,cl
outside:
	xor	cl,cl			; clear lower byte
	or	[xfer_map],cx
;
	pop	cx
	pop_eax
	ret
chk_loc 	endp
	page
;******************************************************************************
;	set_selector - set up a selector address/attrib
;
;	ENTRY:	EAX = address for GDT selector
;		DI = GDT selector
;	EXIT:	selector at ES:DI is writeable data segment,64k long and points
;		to desired address.
;
;******************************************************************************
set_selector	proc	near
;
	PUSH_EAX
	push	di
	push	es
;
	call	MapLinear
;
	and	di,NOT 07h		; just in case... GDT entry
	push	GDTD_GSEL
	pop	es			; ES:DI -> selector entry
;
	mov	es:[di+2],ax		; low word of base address
	OP32
	shr	ax,16			; AX = high word of address
	mov	es:[di+4],al		; low byte of high word of address
	xor	al,al			; clear limit/G bit
	mov	es:[di+6],ax		; set high byte of high word of addr
					;   and high nibble of limit/G bit
;
	mov	ax,0FFFFh
	mov	es:[di],ax		; set limit to 64k
;
	mov	al,D_DATA0		; writeable DATA seg / ring 0
	mov	es:[di+5],al
;
	pop	es	
	pop	di
	POP_EAX
	ret
;
set_selector	endp

_TEXT	ends				; end of segment
;
	end				; end of module

