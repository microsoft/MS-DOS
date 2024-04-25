page	58,132
;******************************************************************************
	title	EMMP - EMM protected mode functions
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986, 1987
;
;   Title:	CEMM.EXE - COMPAQ Expanded Memory Manager 386 Driver
;		EMMLIB.LIB - Expanded Memory Manager Functions Library
;
;   Module:	EMMP - WIN386 EMM functions
;
;   Version:	0.04
;
;   Date:	July 7,1986
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION                  DESCRIPTION
;   --------  --------  -------------------------------------------------------
;   07/07/86  0.04	Moved here from version 0.04 EMMSUP.ASM
;   07/08/86  0.04	Added Get/Set Page Map (SBP).
;   05/13/88            Change to LIM 4.0 functionality (PC)
;
;******************************************************************************
;
;   Functional Description:
;	This file contains the EMM functions which require greatest efficiency.
;
;******************************************************************************
.lfcond					; list false conditionals
.386p

;	include	protseg.inc
	include vdmseg.inc
	include page.inc
;	include vdmm.inc
	include vm386.inc
	include	vdmsel.inc
	include emmdef.inc
	include	desc.inc
;	include vmdm.inc
;	include vpicd.inc
;	include vdmmmac.inc

;******************************************************************************
;	P U B L I C S
;******************************************************************************
_TEXT	segment
	public	_MapHandlePage
	public	_SavePageMap
	public	_RestorePageMap
	public	_GetSetPageMap
	public	_GetSetPartial
	public	_MapHandleArray
	public	_AlterMapAndJump
	public	_AlterMapAndCall
;	public	TS_VEMMD_MC_Ret
	public	_MoveExchangeMemory
	public	_AlternateMapRegisterSet
;	public	VEMMD_Set_Map_Region
;	public	VEMMD_Unset_Map_Region
;	public	_VMpte_to_EMMpte
;	public	_Remap_EMM
	public	_Get_Key_Val
_TEXT	ends

	page
;******************************************************************************
;	E X T E R N A L   R E F E R E N C E S
;******************************************************************************

_TEXT	segment

extrn	_source_addr:near
extrn	_dest_addr:near

extrn	SetDescInfoResident:near
extrn	SegOffTo24Resident:near

extrn	ErrHndlr:near

_TEXT	ends

_DATA	SEGMENT

;extrn	_regp:dword				;  pointer to entry stack frame
;extrn	VEMMD_pt:dword
;extrn	Cur_VM_Handle:dword
;extrn	Cur_VMID:dword
;extrn	_VM_List:dword
;extrn	_MaxEMMSize:dword
;extrn	_VEMMD_PgFrame:word
;extrn	_VEMMD_Last_Offset:word
extrn	PF_Base:word
extrn	_OSEnabled:dword
;extrn	NullAvailPTE:dword
;extrn	NullUnavailPTE:dword

extrn	_total_pages:word			; total # of EMM pages in system

;
; table of offsets into in to the first page table
; for user logical emm page map
;
extrn	_page_frame_base:dword

extrn	_pft386:word

extrn	_mappable_pages:word			; table of mappable pages
extrn	_mappable_page_count:word		; how many in the table
extrn	_page_frame_pages:word			; how many in the page frame
extrn	_physical_page_count:word		; number of physical pages
extrn	_VM1_EMM_Pages:word			; pages not in the page frame
;extrn	_VM1_EMM_Offset:word			; offset of these in a context
extrn	_cntxt_pages:byte			; number of pages in a context
extrn	_cntxt_bytes:byte			; number of bytes in a context


;
; table of indexes into the above - maps segment to physical page
;
extrn	EMM_MPindex:byte

;
; ptr to table of emm page # for each handle's logical pages.
;
extrn	_emm_page:word

;
;  handle data structure
;
extrn	_handle_table:word
extrn	_handle_table_size:word

;
;   save area for handles
;
extrn	_save_map:byte

;
; Save area and misc variables for 4.0 function 27
;
extrn	EMM_savES:word
extrn	EMM_savDI:word

extrn	CurRegSetn:byte
extrn	FRS_free:byte
extrn	CurRegSet:dword
extrn	FRS_array:word

extrn	_regp:word
_DATA	ENDS

	page
;******************************************************************************
;	C O D E
;******************************************************************************
_TEXT	SEGMENT
assume	cs:_TEXT, ds:DGROUP, ss:DGROUP

	page
;***********************************************
;
; normalize
;
;	ENTRY:	Sel,Off - Selector:offset to be normalize
;		protected mode only
;
;	EXIT:	Sel:Off normalized
;
;	USES:	Sel,Off
;	NOTE:	Sel and Off should not be BX,DX,AX
;
;***********************************************
normalize	MACRO	Sel,Off

	push	dx
	push	ax
	push	bx
	push	es

	push	Sel		; save for later reload
	mov	bx, Sel		; get Selector into BX

	push	GDTD_GSEL	; ES -> GDT
	pop	es

	and	bl,SEL_LOW_MASK	; mask off mode bits
	mov	dx,es:[bx+2]	; AL:DX <-- base address
	mov	al,es:[bx+4]
	add	dx,Off		; adjust base address
	adc	al,0
	mov	es:[bx+2],dx	; store it back
	mov	es:[bx+4],al
	xor	Off, Off	; new Offset

	pop	Sel		; reload Selector (flush cache)

	pop	es
	pop	bx
	pop	ax
	pop	dx

	ENDM

;***********************************************
;
; get_space_from_stack
;
;	ENTRY:	Len - amount of space requested
;
;	EXIT:	Len space allocated on ES:DI (client's stack)
;		ES:DI - points to First element on top of stack
;
;	USES:	DI
;
;***********************************************
Get_space_from_stack	MACRO	Len

	sub	di, Len
	ENDM

;***********************************************
;
; release_space_to_stack
;
;	ENTRY:	Len - amount of space to be release
;
;	EXIT:	Len space released from client's stack (DS:SI)
;
;	USES:	SI
;
;***********************************************
release_space_to_stack	MACRO	Len

	add	si, Len
	ENDM

;***********************************************
;
; Set_EMM_GDT - set GDT entry of selector with some fix infos
;	like access and limit
;
;	ENTRY:	Handle - selector of GDT to modify
;
;	EXIT:	GDT entry set
;		bx - selector
;
;	USES:	ax,bx,cx,dx,es
;
;***********************************************
Set_EMM_GDT	MACRO	handle

	mov	bx, handle			; GDT selector
	call	SegOffTo24Resident		; AL:DX <-- 24 bit base address
	mov	cx, 0ffffh			; Limit
	mov	ah, D_DATA0			; Acess right
	push	GDTD_GSEL
	pop	es				; ES:0 <-- GDT
	call	SetDescInfoResident		; set GDT entry
	ENDM

;***********************************************
;
; Set_Byte_Gran - set granularity of GDT entry to byte
;
;	ENTRY:	Handle - selector of GDT to modify
;
;	EXIT:	Granularity bit clear in GDT
;		bx - Selector 
;
;	USES:	bx,es
;
;***********************************************
Set_Byte_Gran	MACRO	handle

	mov	bx, handle			; GDT selector
	push	GDTD_GSEL
	pop	es				; ES:0 <-- GDT
	and	byte ptr es:[bx+6],NOT R_GRAN	; clear gran bit
	ENDM

;***********************************************
;
; Set_Page_Gran - set granularity of GDT entry to page
;
;	ENTRY:	Handle - selector of GDT to modify
;
;	EXIT:	Granularity bit set in GDT
;		bx - Selector 
;
;	USES:	bx,es
;
;***********************************************
Set_Page_Gran	MACRO	handle

	mov	bx, handle			; GDT selector
	push	GDTD_GSEL
	pop	es				; ES:0 <-- GDT
	or	byte ptr es:[bx+6], R_GRAN	; set gran bit
	ENDM

;***********************************************
;
; Get_FRS_window - get pointer to Fast Register Set window
;
;	ENTRY:	Reg - points to an FRS_struc
;
;	EXIT:	Reg - points to FRS_window entry in the structure
;
;	USES:	Reg
;
;***********************************************
Get_FRS_window	MACRO	Reg

	mov	Reg, word ptr [CurRegSet]	; just offset (assume dgroup)
	add	Reg, FRS_window			; points to FRS window entries
	ENDM

	page
;**********************************************************************
;
;   map_EMM_page - set page table entries for a page frame
;
;	ENTRY:	AX - physical page number to be mapped
;		BX - EMM page number to map
;	EXIT:	page table set up for EMM page # in this page frame
;	DESTROY:EAX,BX
;
;***********************************************
map_EMM_page	proc	near
	cmp	ax,[_physical_page_count]	;Q: valid physical page# ?
	jae	short mEp_inv_page		;  N: invalid page number
						;  Y: continue with it
	cmp	bx,[_total_pages]		;Q: valid EMM page# ?
	jae	short mEp_inv_page		;  N: invalid page number
						;  Y: continue with it
	push	es		; preserve es
	push	cx		; preserve cx
	push	di		; preserve di
	push	ax		; save ax (phys page#)

	;
	; construct pointer to physical address of the first
	; 386 page and move it into eax
	;
	mov	cx,bx		; emm page# in cx to save in FRS later
	shl	bx,2		; bx <-- pft index * 4

	;
	; continue calulation of pte
	;
	add	bx,[_pft386]	; BX  = points into _pft386
	mov	eax,[bx]	; EAX = physical address of EMM page #
	and	ax,0F000H	; clear the low 12 bits
	or	ax,P_AVAIL	; page ctl bits <-- user,present,write

	pop	bx		; bx <-- physical page index

	;
	; save mapping (offset into _pft386 struct) into
	; current FRS's physical page entry
	;

	Get_FRS_Window	DI	; di <-- address of current FRS
	add	di,bx		; di <-- address of physical page
	add	di,bx		;        entry in FRS
	mov	[di],cx		; save mapping (emm page#) into FRS
	;
	; construct pointer to physical address of
	; page frame
	;

	shl	bx,2	 		; bx <-- index * 4
	add	bx,offset DGROUP:_page_frame_base ; bx = offset for entry in _page_frame_base
	les	di,[bx]			; es:di <-- page frame address

	;
	; now, 
	;	es:di points to the 1st entry in the page table 
	;             for this page frame
	;	eax contains the new value of the PTE
	; set up 4 entries
	;

	pushf			; preserve direction flag
	cld			; forward

	stosd			; store 1st page table entry
	add	eax,P_SIZE	; eax <-- next address

	stosd			; store 2nd page table entry
	add	eax,P_SIZE	; eax <-- next address

	stosd			; store 3rd page table entry
	add	eax,P_SIZE	; eax <-- next address

	stosd			; store 4th page table entry

	popf			; restore direction flag
	pop	di		; get DI back
	pop	cx		; get CX back
	pop	es		; get ES back
	clc
	ret

mEp_inv_page:
	stc
	ret

map_EMM_page	endp

	page
;**********************************************************************
;
;    unmap_page - unmap a physical page
;
;	ENTRY:	AX - physical page number to be unmapped
;	DESTROY:EAX
;
;**********************************************************************
unmap_page	proc	near
	;
	; find FRS entry for the physical page and
	; update it as unmapped
	;
	push	es
	push	di
	push	bx
	push	cx
	Get_FRS_Window	DI		; di <-- address of current FRS
	add	di, ax			; di <-- address of physical page
	add	di, ax			;        entry in FRS
	mov	[di], NULL_PAGE		; unmap the entry

	;
	; find out the segment of the physical page
	;
	mov	cx, [_physical_page_count]
	mov	di, offset DGROUP:_mappable_pages
unmap_page_loop:
	cmp	ax, [di].mappable_pg
	je	unmap_page_found
	add	di, size Mappable_Page
	loop	unmap_page_loop

	jmp	short unmap_page_exit	; non-found : just return

unmap_page_found:
	mov	bx, [di].mappable_seg	; get segment into bx first

	;
	; construct pointer to physical address of
	; page frame
	;
	xchg	ax,bx
	shl	bx,2	 		; bx <-- index * 4
	add	bx,offset DGROUP:_page_frame_base ; bx <-- points to PTE address of phys page#
	les	di,[bx]			; es:di <-- points to PTE of page frame
	xchg	ax,bx

	;
	; construct PTE
	;
	movzx	eax, bx		; EAX <-- segment of physical page
	shl	eax, 4
	and	ax,0F000H	; clear the low 12 bits
	or	ax,P_AVAIL	; page ctl bits <-- user,present,write

	cmp	eax, 0A0000h	; Q:above 640K ?
	jge	unmap_page_ok	;  Y: go ahead, unmap it
	mov	eax, 0		;  N: shouldn't unmap below 640K - make page NotPresent

unmap_page_ok:
	pushf
	cld
	stosd				; unmap pte of page frame
	add	eax,P_SIZE
	stosd
	add	eax,P_SIZE
	stosd
	add	eax,P_SIZE
	stosd
	popf

unmap_page_exit:
	pop	cx
	pop	bx
	pop	di
	pop	es
	ret
unmap_page	endp

	page
;**********************************************************************
;
;   map_page - map a logical page to a phyical page
;
;	ENTRY:	AX - physical page number to be mapped
;		BX - logical page number to map
;		DX - handle pointer (do not destroy)
;	DESTROY:EAX,BX
;
;**********************************************************************
map_page	proc	near
	cmp	ax,[_physical_page_count]	;Q: valid physical page# ?
	jae	short mp_inv_phy		;  N: invalid page number
						;  Y: continue with it
	cmp	bx,0FFFFh			;Q: unmap ?
	je	short mp_unmap_page		;  Y: go ahead

	xchg	bx, dx
	cmp	dx,[bx.ht_count]		;Q: valid logical page# ?
	xchg	bx, dx
	jae	short mp_inv_log		;  N: invalid page number
						;  Y: continue with it

	xchg	bx, dx
	add	dx,[bx.ht_index]		; dx <-- index into _emm_page
	xchg	bx, dx
	shl	bx,1				; bx <-- index * 2
	add	bx,[_emm_page]
	mov	bx,[bx]				; bx <-- emm page#
	call	map_EMM_page
	jc	short mp_inv_emm_page		; emm page range error
	ret

mp_unmap_page:
	call	unmap_page
	clc
	ret

mp_inv_emm_page:
	mov	byte ptr [bp.rAX+1],SOURCE_CORRUPTED
	stc
	ret

mp_inv_phy:
	mov	byte ptr [bp.rAX+1],PHYS_PAGE_RANGE
	stc
	ret

mp_inv_log:
	mov	byte ptr [bp.rAX+1],LOG_PAGE_RANGE
	stc
	ret
map_page	endp


	page
;***********************************************
;
; _MapHandlePage - map a handle's page
;
; This routine maps 4 386 pages into the address
; space.
;
; ENTRY: PROTECTED MODE ONLY
;	 AH = 44h = map handle page function # 
;	 AL = window # (physical page #)
;	 BX = logical page #
;	 DX = EMM handle
; 	REGS on STACK:	SI = not used by this function
;	 SS:[EBP] -> regp stack frame
;	 DS = DGROUP
;
; EXIT:	page table entries set up
;	AH = status of this function
;		= EMM_HW_MALFUNCTION if entry in real/virtual mode.
;
; USED: EAX, EBX, EDX, EDI
;
;***********************************************

Dword_Align	_TEXT
_MapHandlePage	proc	near

	Validate_Handle	<short mhp_inv_handle>

	mov	byte ptr [bp.rAX+1],OK	; Assume success!
	movzx	eax, al			; Physical page
	movzx	ebx, bx			; Logical page

	push	eax
	mov	eax, cr3
	mov	cr3, eax		; Flush old mapping now
	pop	eax

	jmp	map_page		; Common page mapping code

mhp_inv_handle:
	mov	byte ptr [bp.rAX+1], INVALID_HANDLE
	ret

_MapHandlePage	endp

	page
;***********************************************
;
; _SavePageMap	- save current page mapping
;
;	This routine save the current page mapping context for a handle.
;
; ENTRY: PROTECTED MODE
;	 AH = 07h = save page map function # 
;	 DX = EMM handle
; 	REGS on STACK:	SI = not used by this function
;	 SS:[BP] -> regp stack frame
;	 DS = DGROUP
;
; EXIT:	current state saved
;	AH = status of this function
;
; USED: AX,BX,CX,DX,SI,DI
;
;***********************************************

Dword_Align	_TEXT
_SavePageMap	proc	near
	cmp	[_page_frame_pages], 4
	jb	short srpm_nopf		; no page frame

	mov	ax, dx			; Save for later
	Validate_Handle	<short srpm_inv_handle>
					; check state of handle's page area
	imul	bx,ax,SIZE SaveMap_struc ; BX = offset within Save Area for
					;  this handle's save area
	lea	di,_save_map[bx]	; DS:DI points to handle's save area
	cmp	[di].s_handle,NULL_HANDLE
					;Q: save area in use ?
	jne	short spm_prev_saved	; Y: return error
					; N: use it now
	cld
	push	ds
	pop	es
	stosw					; store handle # in s_handle
	Get_FRS_window	SI			; Current FRS page mappings
	movsd					; move to save area
	movsd					; Lim 3.2 has only 4 page frames

	mov	byte ptr [bp.rAX+1],OK	; ok return
	ret

spm_prev_saved:
	mov	byte ptr [bp.rAX+1],MAP_PREV_SAVED
	ret

srpm_inv_handle:					; Shared error returns
	mov	byte ptr [bp.rAX+1],INVALID_HANDLE
	ret

srpm_nopf:
	mov	byte ptr [bp.rAX+1], EMM_HW_MALFUNCTION ; No page frame!!!
	ret

_SavePageMap	endp

	page
;***********************************************
;
; _RestorePageMap - restore handle's saved page mapping
;
;	This routine restores the current page mapping context 
;	from a handle's save area.
;
; ENTRY: PROTECTED MODE ONLY
;	 AH = 08h = restore page map function # 
;	 DX = EMM handle
; 	REGS on STACK:	SI = not used by this function
;	 SS:[BP] -> regp stack frame
;	 DS = DGROUP
;
; EXIT:	current state restored
;	AH = status of this function
;
; USED: AX,BX,CX,DX,SI,DI
;
;***********************************************

Dword_Align	_TEXT
_RestorePageMap	proc	near
	cmp	[_page_frame_pages], 4
	jb	short srpm_nopf		; no page frame

	mov	ax, dx			; Save for later
	Validate_Handle	srpm_inv_handle
					; check state of handle's page area
	imul	bx,ax,SIZE SaveMap_struc ; BX = offset within Save Area for
					;  this handle's save area
	lea	si,_save_map[bx]	; DS:SI points to handle's save area
	cmp	[si].s_handle,NULL_HANDLE
					;Q: save area in use ?
	je	short rpm_no_map_saved	; N: return error
					; Y: restore it

	mov	byte ptr [bp.rAX+1],OK		; Assume success
	mov	[si].s_handle,NULL_HANDLE	; null handle's save area

	lea	si,[si].s_map			; SI -> handle's save area
	Get_FRS_window	DI			; Get pointer to current window
	push	ds
	pop	es				; ES <-- DGROUP
	cld
	movsd					; restore 4 words
	movsd					; Lim 3.2 has only 4 page frames
	jmp	_set_windows			; Restore mapping

rpm_no_map_saved:
	mov	byte ptr [bp.rAX+1],NO_MAP_SAVED
	ret

_RestorePageMap	endp

	page
;***********************************************
;
; _GetSetPageMap - get/set page map to/from external save area
;
;	This routine stores the current page mapping context (Intel
; compatible form for now) to an external save area and/or restores
; the current page mapping context from an external save area.
;
; ENTRY: PROTECTED MODE ONLY
;	 AH = 4Eh = Get/Set page map function number
;     or AH = 5Ch = Get/Set large page map function number
;	 AL = SUBFUNCTION CODE
;		AL = 0  => Get page map
;		AL = 1  => Set page map
;		AL = 2  => Get and Set page map
;		AL = 3  => return size of page map
; 	REGS on STACK:	SI = not used by this function
;	 SS:[BP] -> regp stack frame
;	 DS = DGROUP
;
; EXIT:	current state saved / restored
;	AH = status of this function
;
; USED: BX,CX,DX,SI,DI
;
;***********************************************
Dword_Align	_TEXT
_GetSetPageMap	proc	near

	cmp	al,GSPM_GET	   	;Q: get page map subfunction ?
	je	short _get_map		;  Y: get it

	cmp	al,GSPM_SET		;Q: set page map subfunction ?
	je	_set_map		;  Y: set it

	cmp	al,GSPM_GETSET		;Q: get & set page map subfunction ?
	jne	short gspm_chk_size	;  N: check for size function
	call	_get_map		;  Y: get current map first
	jmp	short _set_map		;     set new one

gspm_chk_size:
	cmp	al, GSPM_SIZE		;Q: return map size subfunction ?
	jne	short gspm_inv_subfun	;  N: return invalid subfunction

	mov	al, [_cntxt_bytes]		; size of map
	mov	ah, OK				; ok return
	mov	word ptr [bp.rAX], ax
	ret

gspm_inv_subfun:
	mov	byte ptr [bp.rAX+1],INVALID_SUBFUNCTION
	ret

gspm_inv_fun:
	mov	byte ptr [bp.rAX+1],INVALID_FUNCTION
	ret

_GetSetPageMap	endp

	page
;***********************************************
;
; _get_map - save current mapping register state to external area
;
;	ENTRY: on stack
;		clients ES:DI -> client's buffer for state
;	 SS:[BP] -> regp stack frame
;	 DS = DGROUP
;
;	EXIT:  state stored in client's buffer
;		return code set on stack
;
;	USED: AX,BX,CX,DX,SI,DI,ES
;
;  DESCRIPTION:	This function saves the current mapping
;		into the save area specified.
;
;***********************************************
Dword_Align	_TEXT
_get_map	proc

	cld
	call	_dest_addr			; DX:AX ptr for client's buff
	mov	es,dx
	mov	di,ax				; ES:DI pts to clients buffer

	Get_FRS_window	SI			; Get pointer to current window
	movzx	ecx, [_cntxt_pages]
	mov	ax, cx
	stosw					; save # pages
	shr	cx, 1				; now dwords
	rep movsd				; mov bytes to current map area
	mov	byte ptr [bp.rAX+1],OK		; ok return
	ret

_get_map	endp

	page
;***********************************************
;
; _set_map - restore mapping register state
;
;	ENTRY: on stack
;		clients DS:SI -> client's buffer containing state to restore
;	 SS:[BP] -> regp stack frame
;	 DS = DGROUP
;
;	EXIT:  state restored from client's buffer
;		return code set on stack
;		CLC => no errors
;		STC => error occurred
;
;	USED: EAX,BX,CX,DX,SI,DI,ES
;
;
;  DESCRIPTION:	This function restores the mapping from the state info input.
;		The mapping is assumed to be the same as in the
;		save_current_map function.  The count in the saved
;		state is verified.
;		
;***********************************************
Dword_Align	_TEXT
_set_map	proc	near

	mov	byte ptr [bp.rAX+1],OK		; Assume success
	Get_FRS_window	DI			; Get pointer to current window
						; before DS gets trashed
	push	ds
	pop	es				; use ES to address data
	push	dx
	mov	si, ax
	call	_source_addr			; DX:AX ptr for client's buff
	mov	ds,dx
	xchg	si,ax				; DS:SI pts to clients buffer
	pop	dx

	cld
	movzx	ecx, es:[_cntxt_pages]		; number of words in mapping
	lodsw					; saved size
	cmp	ax, cx				; should be this
	jne	short sm_inv_source		; Wrong, saved data corrupted
	shr	cx, 1				; now a word count
	rep movsd
	push	es
	pop	ds				; DS <-- DGROUP
	jmp	_set_windows			; make it effective

sm_inv_source:
	mov	byte ptr [bp.rAX+1], SOURCE_CORRUPTED
	ret

sm_exit:
	ret

_set_map	endp

	page
;***********************************************
;
; _set_windows - re-map all mapped physical pages
;
; This routine maps all mapped 386 pages of the EMM page frame into the
; linear address space for the page frame.
;
; ENTRY: PROTECTED MODE ONLY
;	 DS = DGROUP
;	 SS:[BP] -> regp stack frame
;
; EXIT:	page tables changed to map these pages.
;	_current_map contents initialized.
;
; uses:
;	FLAGS, EAX, EBX, ECX, ESI, EDI
;
;***********************************************
;
_set_windows	proc	near
;
	xor	ax, ax			; start from PHYS page 0
	Get_FRS_Window	SI		; SI <-- current FRS map
sw_loop:
	mov	bx, word ptr [si]	; BX <-- emm page #
	add	si, 2		  	; prepare for next PHYS page
	cmp	bx, 0FFFFh	  	; not mapped ?
	je	sw_unmap_page		;  Y: unmap it
	cmp	bx, [_total_pages]	; emm page out of range ?
	ja	sw_corrupt		;  Y: error
	mov	di, bx
	shl	di, 2			; SI <-- _pft386 offset of emm page
	add	di, [_pft386]
	cmp	dword ptr [di], 0	; pte not mapped ?
	je	sw_corrupt		;  Y: error
	push	eax
	call	map_EMM_page		; map a page
	pop	eax
sw_done_page:
	inc	ax
	cmp	ax, [_physical_page_count]
	jb	sw_loop			; next page

	mov	eax, cr3
	mov	cr3, eax		; flush TLB
	ret

sw_unmap_page:
	push	eax
	call	unmap_Page
	pop	eax
	jmp	short sw_done_page

sw_corrupt:
	mov	byte ptr [bp.rAX+1], SOURCE_CORRUPTED
	pop	dx
	ret

_set_windows	endp

	page
;*******************************************************************************
;
;	LIM 4.0 EXTRAS for Windows
;
;*******************************************************************************

;***********************************************
;
; _GetSetPartial - get/set partial page map to/from external save area
;
;	This routine stores the current page mapping context
; to an external save area and/or restores the current page
; mapping context from an external save area.
;
; ENTRY: PROTECTED MODE ONLY
;	 AH = 4Fh = Get/Set page map function number
;	 AL = SUBFUNCTION CODE
;		AL = 0  => Get page map
;		AL = 1  => Set page map
;		AL = 2  => return size of page map
; 	REGS on STACK:	SI = not used by this function
;	 SS:[BP] -> regp stack frame
;	 DS = DGROUP
;
; EXIT:	current state saved / restored
;	AH = status of this function
;
; USED: BX,CX,DX,SI,DI
;
;***********************************************
_GetSetPartial	proc	near
	cmp	al, 0			; Get...?
	jne	gsppm_not0

	call	_source_addr		; uses AX, DX
	mov	fs, dx
	mov	si, ax
	call	_dest_addr		; uses AX, DX
	mov	es, dx
	mov	di, ax
	cld
	lods	word ptr fs:[si]
	stosw				; Save count in save area
	or	ax, ax
	jz	gsppm_ok		; nothing to do
	movzx	ecx, ax

	mov	dx, [_mappable_page_count]
	cmp	cx, dx
	ja	gsppm_inv_phys
gsppm_get_loop:
	lods	word ptr fs:[si]		; Get segment
	shr	ax, 10				; 16k page number
	sub	ax, CONV_STRT_PG		; first page in emm_mpindex arr
	jb	gsppm_inv_seg			; only pages above 256k
	mov	bx, ax
	mov	al, EMM_MPindex[bx]		; convert to physical page
	cmp	al, -1				; does it exist
	je	gsppm_inv_seg
	mov	bx, ax
	shl	bx, 2
	lea	ax, _mappable_pages[bx]
	mov	bx, ax
	mov	bx, [bx.mappable_seg]		; segment for this page
	cmp	bx, fs:[si-2]
	jne	gsppm_inv_seg			; must match exactly
	mov	bx, ax
	movzx	ebx, [bx.mappable_pg]		; the physical page
	cmp	bx, dx
	ja	gsppm_inv_seg
	mov	ax, bx
	stosw					; Save physical page
	Get_FRS_window	BX			; Get pointer to current window
	add	bx, ax				; get ptr to emm page# in FRS
	add	bx, ax
	mov	ax, [bx]
	stosw					; and current mapping
	loop	gsppm_get_loop

gsppm_ok:
	mov	byte ptr [bp.rAX+1], OK
	ret
	
gsppm_not0:
	cmp	al, 1				; Set...?
	jne	gsppm_not1
						; Set Partial Page Map
	call	_source_addr			; uses AX, DX
	mov	fs, dx
	mov	si, ax
	movzx	ecx, word ptr fs:[si]		; Get count from save area
	add	si, 2
	jecxz	gsppm_ok			; Zero count, do nothing

	Get_FRS_window	DX			; Get pointer to current window
	cmp	cx, [_mappable_page_count]
	ja	short gsppm_corrupt		; can't be more than phys pages
gsppm_set_loop:
	push	esi
	movzx	eax, word ptr fs:[si]		; Get Physical page
	cmp	ax, [_mappable_page_count]
	jae	gsppm_sl_bad

	movzx	esi, word ptr fs:[si+2]		; Get mapping (emm page#)
	mov	di,dx
	add	di,ax
	add	di,ax				; di <-- current FRS phy page
	mov	[di], si			; Save new mapping

	cmp	si, 0FFFFh			; Unmapped?
	je	short gsppm_unmap		;   yes, go unmap it
	cmp	si, [_total_pages]		; valid page?
	jae	short gsppm_sl_bad		;   no, fail

	mov	bx, si				; bx <-- emm page#
						; ax <-- phys page#
	call	map_EMM_page

gsppm_set_done:
	pop	esi
	add	esi, 4				; Next page to map
	loop	gsppm_set_loop
	mov	eax, cr3			; Flush TLB
	mov	cr3, eax
	jmp	gsppm_ok

gsppm_unmap:
	call	unmap_page			; with ax <-- phys page#
	jmp	gsppm_set_done			; On to next page

gsppm_sl_bad:
	pop	esi
gsppm_corrupt:
	mov	byte ptr [bp.rAX+1], SOURCE_CORRUPTED
	ret

gsppm_not1:
	cmp	al, 2				; Size?
	jne	gspm_inv_subfun
	cmp	bx, [_mappable_page_count]	; # of page frames
	ja	short gsppm_inv_phys
	shl	bx, 2				; Size = pages * 4 + 2
	add	bx, 2
	mov	byte ptr [bp.rAX], bl
	jmp	gsppm_ok

gsppm_inv_subfun:
	mov	byte ptr [bp.rAX+1], INVALID_SUBFUNCTION
	ret

gsppm_inv_phys:
gsppm_inv_seg:
	mov	byte ptr [bp.rAX+1], PHYS_PAGE_RANGE
	ret

_GetSetPartial	endp

	page
;***********************************************
;
; _MapHandleArray - map an array of a handle's pages
;
; This routine maps the physical pages according to
; an array of mappings.
;
; ENTRY: PROTECTED MODE ONLY
;	 AH = 50h = map handle page function # 
;	 AL = Subfunction: 0)	Physical pages described by their number
;			   1)	Physical pages described by segment
;	 CX = number of pages to be mapped
;	 DX = EMM handle
; 	REGS on STACK	DS:SI = array of mappings
;	 SS:[BP] -> regp stack frame
;	 DS = DGROUP
;   NOTE:
;	There is a second entry point for this procedure at the label
;	MapHandleArray_Entry_2.  The entry conditions for this are identical
;	to those specified above except that ESI points to the mapping array--
;	the DS:SI on the stack are ignored.  Also, the value in AH is undefined.
;	This entry point is used by the AlterMapAndJump and AlterMapAndCall
;	functions.
;
; EXIT:	context block ve_window set up
;	page table entries set up
;	AH = status of this function
;		= EMM_HW_MALFUNCTION if entry in real/virtual mode.
;
; USED: AX,BX,DX,SI,DI,FS
;
;***********************************************
Dword_Align	_TEXT
_MapHandleArray	proc	near
	mov	si, ax
	push	dx
	call	_source_addr			; DX:AX <-- mapping array
	xchg	si, ax
	mov	fs, dx
	pop	dx				; FS:SI <-- mapping array

MapHandleArray_Entry_2:
	cmp	al, 1			; Q: Is subfunction 0 or 1?
	ja	mha_inv_sub		;    N: Invalid subfunction

	Validate_Handle <mha_inv_handle>

	mov	byte ptr [bp.rAX+1], OK		; Assume success
	movzx	ecx, cx
	jecxz	short mha_exit			;   none to do, just return

	or	al, al				; which subfunction?
	jnz	short mha_sub1			; subfunction 1?

		;
		; Subfunction 0:  array contains logical and physical
		; 		  page numbers.
		;
mha_sub0:
	movzx	eax, fs:[si.mha0_phys_pg]	; physical page number
	movzx	ebx, fs:[si.mha0_log_pg]	; logical page number
	call	map_page			; map it if possible
	jc	short mha_exit			; Error code already set
	add	si, size mha_array0
	loop	mha_sub0
	jmp	short mha_exit

		;
		; Subfunction 1:  array contains logical page number and
		; 		  segment numbers corresponding to the
		; 		  desired physical pages.
		;
mha_sub1:
	mov	di, fs:[si.mha1_seg]		; segment to map
	mov	ax, di				; save for later
	shr	di, 10				; 16k page number
	sub	di, CONV_STRT_PG		; first page in emm_mpindex arr
	jb	short mha_inv_seg		; only pages above 256k
	movsx	edi, EMM_MPindex[di]		; convert to physical page
	cmp	edi, -1				; does it exist
	je	short mha_inv_seg
	shl	di, 2				; index * 4
	lea	di, _mappable_pages[di]
	cmp	ax, [di.mappable_seg]		; segment for this page
	jne	short mha_inv_seg		; must match exactly
	movzx	eax, [di.mappable_pg]		; the physical page
	movzx	ebx, fs:[si.mha1_log_pg]	; the logical page
	call	map_page			; try to map it
	jc	short mha_exit			; error code already set
	add	si, size mha_array1
	loop	mha_sub1			; back for next segment to map

mha_exit:
	mov	eax, cr3			; Always clear TLB, we may have
	mov	cr3, eax			; mapped pages before an error
	ret
						; ERRORS...
mha_inv_handle:
	mov	byte ptr [bp.rAX+1], INVALID_HANDLE
	ret
mha_inv_sub:
	mov	byte ptr [bp.rAX+1], INVALID_SUBFUNCTION
	ret
mha_inv_seg:
	mov	byte ptr [bp.rAX+1], PHYS_PAGE_RANGE
	jmp	mha_exit

_MapHandleArray	endp



	page
;***********************************************
;
; _AlterMapAndJump - map an array of a handle's pages and Jump to a
;		     a specified address
;
; This routine maps pages using the MapHandleArray procedure and jumps
; to the specified address
;
; ENTRY: PROTECTED MODE ONLY
;	 AL = Mapping method -- 0 = Physical pages, 1 = Segments
;	 DX = EMM handle
;	REGS on STACK
;	REGS on STACK -- DS:SI -> Map and Jump structure
;	 SS:[BP] -> regp stack frame
;	 DS = DGROUP
;
; EXIT: context block ve_window set up
;	page table entries set up
;	AH = status of this function
;		= EMM_HW_MALFUNCTION if entry in real/virtual mode.
;	Address specified in Map and Jump structure will be new return address
;
; USED: AX,BX,CX,SI,DI,FS,GS
;
;**********************************************

_AlterMapAndJump    PROC    NEAR

	push	dx
	mov	si, ax
	call	_source_addr		; DX:AX <-- map & jump struct
	mov	gs, dx
	xchg	si, ax			; GS:SI <-- map & jump struct
	pop	dx
	push	si
	push	ax
	push	dx					; save EMM handle
	mov	dx, WORD PTR gs:[si.maj_map_address]	; AX:DX <-- map array
	mov	ax, WORD PTR gs:[si.maj_map_address+2]
	Set_EMM_GDT	EMM2_GSEL
	mov	fs, bx					; FS:0 <-- map array
	pop	dx					; restore handle
	pop	ax					; restore subfunction
	movzx	ecx, byte ptr gs:[si.maj_log_phys_map_len] ; Length of map
	xor	si, si					; FS:SI <-- map array
	call	MapHandleArray_Entry_2	    ; Map the array
	pop	si

	mov	ah, byte ptr [bp.rAX+1]
	or	ah, ah
	jnz	SHORT AMJ_Error
	mov	eax, dword ptr gs:[si.maj_target_address]
	mov	word ptr [bp.retaddr], ax  ; Put jump address in place of
	shr	eax, 16 		   ; old IRET return address
	mov	word ptr [bp.rCS], ax
	;
	; now, pop 5 words from client's stack because we are not
	; going to go back. (See AlterMapAndCall for client's
	; Stack frame structure)
	;
	mov	edi, dword ptr [bp.rFS+2+VTFO.VMTF_ESP]	; clients's ESP
	add	edi, 5 * 2				; "pop" 5 words
	mov	dword ptr [bp.rFS+2+VTFO.VMTF_ESP], edi	; save it
	;
	; tell EMMpEntry to patch CS:IP onto its' iretd stack frame
	;
	or	word ptr [bp.PFlag], PFLAG_PATCH_CS_IP
AMJ_Error:				    ; Do the jump
	ret

_AlterMapAndJump    ENDP


	page
;***********************************************
;
; _AlterMapAndCall - map an array of a handle's pages and call a procedure
;		     at a specified address (similar to a FAR call)
;		     This function pushes the return address on the
;		     client's stack and Jumps to the specified procedure.
;		     The "Called" procedure will return to AMC_return_address
;
; ENTRY: PROTECTED MODE ONLY
;	 AL = Subfunction -- 0 = Map phys pages, 1 = Map segs, 2 = Frame size
;	 DX = EMM handle
;	REGS on STACK	DS:SI = Map and Call structure
;	 SS:[BP] -> regp stack frame
;	 DS = DGROUP
;
; EXIT: context block ve_window set up
;	page table entries set up
;	Transfer Space pushed on client's stack
;	Return address CS and IP will point to called procedure
;	AH = status of this function
;		= EMM_HW_MALFUNCTION if entry in real/virtual mode.
;
; USED: AX,BX,CX,DX,SI,DI
;
;***********************************************

_AlterMapAndCall    PROC    NEAR

	cmp	al, 2			; Q: Which subfuction ?
	ja	AMC_inv_sub		;  >2: invalid subfunction
	je	AMC_Stack_Fram_Size	;  =2: Stack frame size subfuncion
					;  <2: map and call
	push	dx
	mov	si, ax
	call	_source_addr		; DX:AX <-- map & call structure
	mov	gs, dx
	xchg	si, ax			; GS:SI <-- map & call structure
	pop	dx
	;
	; check new and old map's length
	;
	xor	ch, ch
	mov	cl, byte ptr gs:[si.mac_old_page_map_len] ; CX = Length of old map
	cmp	cx, [_physical_page_count]
	jae	AMC_inv_phys_pages
	mov	cl, byte ptr gs:[si.mac_new_page_map_len] ; CX = Length of new map
	cmp	cx, [_physical_page_count]
	jae	AMC_inv_phys_pages
	;
	; get client's SS:ESP so we can push stuffs on it
	;
	push	ax
	push	dx

	mov	edi, dword ptr [bp.rFS+2+VTFO.VMTF_ESP]	; clients's ESP
	mov	ax, word ptr [bp.rFS+2+VTFO.VMTF_SS]	; client's SS
	xor	dx, dx					; AX:DX <-- Seg:Off of Client's Stack

	push	ax				; client's Stack Segment
	Set_EMM_GDT	EMM2_GSEL
	push	bx				; client's Stack Selector
	;
	; get CS's Base to "push" on stack for later retf from client
	;
	push	GDTD_GSEL
	pop	es				; ES:0 <-- GDT
	mov	bx, cs				; selector
	and	bl, SEL_LOW_MASK
	mov	dx, word ptr es:[bx + 2]	; get lower 16 bit of Base
	mov	al, byte ptr es:[bx + 4]	; get upper 8 bit of Base
	shr	dx, 4
	shl	al, 4
	or	dh, al				; get the segment value
	mov	bx, dx				; into BX

	pop	es				; ES:DI <-- client's SS
	pop	cx				; CX <-- Client's stack Segment

	pop	dx
	pop	ax
	;
	; save client's stack segment and target address on stack
	; cause they (CX and EMM1_GSEL) get destroy
	;
	push	cx
	push	word ptr gs:[si].mac_target_address+2
	push	word ptr gs:[si].mac_target_address
	;
	; On the Client's stack :
	;
	; +-----------------+
	; | client's Flag   |
	; +-----------------+
	; | client's CS	    |
	; +-----------------+
	; | client's IP	    |
	; +-----------------+
	; | EMM_rEntry's CS |
	; +-----------------+
	; | EMM_rEntry's IP | <-- "SS:ESP" (ES:EDI)
	; +-----------------+
	;
	; "pop" EMM_rEntry's CS:IP off the stack, save it on Ring0 stack
	; in case thereis an error and need to restore state of stack.
	; keep the rest (client's FLAG, CS and IP)
	;
	push	es:[di+2]	; EMM_rEntry's CS
	push	es:[di]		; EMM_rEntry's IP
	add	di, 2 * 2	; "pop"
	;
	; save old map on stack
	;
	movzx	ecx, byte ptr gs:[si.mac_old_page_map_len]  ; CX = Length of old map
	shl	cx, 2				; CX * 4 (4 bytes each entry)
	inc	cx				; one more for length
	get_space_from_stack	CX		; ES:DI <-- space on stack
	dec	cx
	shr	cx, 2				; CX back to length in bytes

	push	ds
	push	di				; save postion of stack
	push	si
	push	ax
	push	bx
	push	dx
	push	cx				; save #pages

	cld
	mov	dx, word ptr gs:[si.mac_old_map_address]    ; AX:DX <-- map array
	mov	ax, word ptr gs:[si.mac_old_map_address+2]
	push	es
	Set_EMM_GDT	USER1_GSEL
	pop	es
	mov	ds, bx				; DS:0 <-- map array
	xor	si, si
	pop	cx
	mov	ax, cx
	stosb					; store length of map

	shl	cx, 1				; move word
	rep movsw

	pop	dx				; restore handle
	pop	bx				; restore Segment of client Stack
	pop	ax				; restore subfunction
	pop	si
	pop	di
	pop	ds
	;
	; save FRS context on stack
	;
	movzx	ecx, [_cntxt_bytes]
	get_space_from_stack	CX		; ES:DI <-- space on stack

	push	si
	push	di
	get_FRS_Window		SI		; DS:SI <-- mapping context
	shr	ecx, 1				; move words
	rep movsw

	pop	di
	pop	si
	;
	; map new mapping
	;
	push	bx
	push	ax
	push	dx

	push	di					; save "stack pointer"
	push	si
	push	ax
	push	dx					; save EMM handle
	mov	dx, WORD PTR gs:[si.mac_new_map_address]; AX:DX <-- map array
	mov	ax, WORD PTR gs:[si.mac_new_map_address+2]
	push	es
	Set_EMM_GDT	USER1_GSEL
	pop	es
	mov	fs, bx					; FS:0 <-- map array
	xor	si, si
	pop	dx					; restore handle
	pop	ax					; restore subfunction
	movzx	ecx, byte ptr gs:[si.mac_new_page_map_len]
	call	MapHandleArray_Entry_2	    ; Map the array
	pop	si			    ; Restore structure pointer
	pop	di			    ; restore "stack" pointer
	pop	dx
	pop	ax
	mov	bh, byte ptr [bp.rAX+1]
	or	bh, bh
	pop	bx
	jnz	AMC_map_Error
	;
	; save needed registers, return address and call address
	; on client's stack
	;
	dec	di
	dec	di				; "pre-decrement" stack
	std					; store backward
	stosw					; subfunction code
	mov	ax, dx				; EMM handle
	stosw
	mov	ax, ds				; DGROUP
	stosw
	mov	ax, bx				; CS for return from called code
	stosw
	mov	ax, offset AMC_return_address	; IP for return from called code
	mov	es:[di], ax			; "push" without decrement "SP"
	cld
	;
	; NOW build a iretd stack frame to go back to virtual mode
	;
	pop	ax				; no error : we can throw
	pop	ax				; away EMM-rEntry's CS:IP now

	pop	ax				; target address
	pop	dx				; target address+2
	pop	cx				; Stack Segment

	push	0
	push	word ptr [bp].rGS
	push	0
	push	word ptr [bp].rFS
	push	0
	push	word ptr [bp].rDS
	push	0
	push	word ptr [bp].rES
	push	0
	push	cx				; client's SS
	push	edi				; client's ESP
	push	PFLAG_VM			; VM bit
	mov	bx, word ptr [bp].PFlag
	and	bx, not PFLAG_VIRTUAL		; clear fake bit
	push	bx
	push	0
	push	dx				; target address+2
	push	0
	push	ax				; target address
	;
	; restore registers context from stack frame
	;
	mov	eax, dword ptr [bp].rAX
	mov	ebx, dword ptr [bp].rBX
	mov	ecx, dword ptr [bp].rCX
	mov	edx, dword ptr [bp].rDX
	mov	esi, dword ptr [bp].rSI
	mov	edi, dword ptr [bp].rDI
	mov	ebp, dword ptr [bp].rFS+2	; clients's EBP
	;
	; return to virtual mode via iretd with calling address on stack
	;
	iretd

AMC_map_Error:
	;
	; mapping error occur : restore state and exit
	;
	movzx	ecx, [_cntxt_bytes]
	push	es
	pop	ds				; DS:SI <-- stack
	xchg	si, di
	release_space_to_stack	CX		; DS:SI <-- space on stack
	;
	movzx	ecx, byte ptr gs:[di.mac_old_page_map_len]  ; CX = Length of old map
	shl	cx, 2				; CX * 4 (4 bytes each entry)
	inc	cx				; one more for length
	release_space_to_stack	CX		; DS:SI <-- space on stack
	;
	mov	di, si
	mov	cx, 4
	get_space_from_stack	CX		; ES:DI <-- space on stack
	pop	es:[di]				; restore EMM_rEntry's CS:IP
	pop	es:[di+2]

	pop	ax				; discard target addr etc
	pop	ax
	pop	ax

	ret

AMC_Stack_Fram_Size:
	mov	byte ptr [bp.rAX+1], OK		; No error
	mov	ax, [_mappable_page_count]	; assume ALL mappable pages
	shl	ax, 2				; 4 bytes per page
	add	ax, 1 + (3+5)*2		; map length
			       		; + 3 words already pushed by EMM_rEntry
			       		; + 5 registers pushed
	add	al, [_cntxt_bytes]		; FRS context
	adc	ah, 0
	mov	word ptr [bp.rBX], ax
	ret

AMC_inv_phys_pages:
	mov	byte ptr [bp.rAX+1], PHYS_PAGE_RANGE
	ret

AMC_inv_sub:
	mov	byte ptr [bp.rAX+1], INVALID_SUBFUNCTION
	ret

_AlterMapAndCall    ENDP


;******************************************************************************
;
;	AMC_return_address -- Return from procedure called through a Map & Call
;
;	NOTE:	MapHandleArray will only access AH on the stack and so the
;		TSTF stack frame will work properly for this procedure.
;
;	ENTRY:	VTFOE frame,EBP,EBX,ESI are on the stack
;
;******************************************************************************

AMC_return_address proc	far

;
; This will causes an illegal instruction trap and goes into protected
; mode. The handler will return back to the point right after the
; 2 bytes ARPL instruction with ring0 stack having and IRETD stack frame
;
	arpl	ax, ax
	;
	; In Protected Mode Now
	;
	pushad				; saves all regs
	mov	ax, sp			; saves stack frame address
	mov	[_regp], ax		; to _regp

	mov	esi, dword ptr [bp.VTFOE.VMTF_ESP]	; clients's ESP
	mov	ax, word ptr [bp.VTFOE.VMTF_SS]		; client's SS
	xor	dx, dx					; AX:DX <-- Seg:Off of Client's Stack

	Set_EMM_GDT	EMM2_GSEL
	mov	fs, bx				; FS:SI <-- client's Stack

	cld					; forward
	;
	; "pop" back registers on "stack" FS:SI
	;
	push	fs
	pop	ds
	lodsw
	mov	es, ax				; DGROUP
	lodsw
	mov	dx, ax				; EMM handle
	lodsw					; subfunction code
	;
	; restore mapping context
	;
	push	ax

	push	es
	pop	ds			; DGROUP
	get_FRS_Window	DI		; ES:DI <-- FRS mapping context regs
	push	fs
	pop	ds			; DS:SI <-- client's stack
	xor	ch, ch
	mov	cl, ES:[_cntxt_bytes]
	shr	cx, 1			; move word
	cld
	rep movsw
	;
	; map old mapping
	;
	lodsb
	mov	ah, 0
	mov	cx, ax			; length
	pop	ax			; subfunction code
	push	si
	push	cx
	push	bp
	mov	bp, [_regp]		; setup pushad frame first
	push	es
	pop	ds			; DS <-- DGROUP
	call	MapHandleArray_Entry_2	; map it
	pop	bp
	pop	cx
	pop	si
	shl	cx, 2			; 4 bytes per mapping
	release_space_to_stack	CX
	;
	; saves CS:IP (BX:CX) on iretd stack frame
	;
	push	fs
	pop	ds			; DS <-- Client's Stack
	push	ax
	lodsw
	mov	word ptr [bp.VTFOE+VMTF_EIP], ax
	lodsw
	mov	word ptr [bp.VTFOE+VMTF_CS], ax
	lodsw
	mov	word ptr [bp.VTFOE+VMTF_EFLAGS], ax
	mov	word ptr [bp.VTFOE+VMTF_EFLAGShi], PFLAG_VM
	pop	ax
	;
	; save client's new stack pointer
	;
	mov	dword ptr [bp.VTFOE.VMTF_ESP], esi
	popad
	pop	esi
	pop	ebx
	pop	ebp
	add	esp, 4			; discard "error" code
	;
	; set return status
	;
	mov	ah, OK

	iretd

AMC_return_address endp

	page
;******************************************************************************
;
;   _MoveExchangeMemory
;
;	This function (23) will copy or exchange memory between EMM and
;	conventional memory or EMM to EMM.
;	Subfunction 0 is memory copy.  Subfunction 1 is exchange.
;	The current mapping context is preserved since the EMM pages are
;	mapped into high memory using VM1s page table.
;
;   ENTRY: PROTECTED MODE ONLY
;	AL = Subfunction -- 0 = Copy, 1 = Exchange
;	DX = EMM handle
;	REGS on STACK	DS:SI = Move/Exchange structure
;	SS:[BP] -> regp stack frame
;	DS = DGROUP
;
;   EXIT:   AL = Status
;
;   USES:   AX, BX, CX, DX, SI, DI
;
;==============================================================================
;
; ALGORITHM:
;
; BEGIN
;   check/validate source/dest and overlay,etc
;
;   save mapping context of first  physical page frame as source page frame
;   save mapping context of second physical page frame as dest   page frame
;
;   /*
;    * setup source and dest memory pointers
;    */
;   if (source.type == conv.mem)
;      DS:SI = source.initial.segment:source.initial.offset
;   else
;      if (backward.copy)
;         calculate last source emm page and new offset
;      map source.initial.page into source.page.frame
;      DS:SI = segment.of.source.page.frame:source.initial.offset
;
;   if (dest.type == conv.mem)
;      ES:DI = dest.initial.segment:dest.initial.offset
;   else
;      if (backward.copy)
;         calculate last dest emm page and new offset
;      map dest.initial.page into dest.page.frame
;      ES:DI = segment.of.dest.page.frame:dest.initial.offset
;
;   /********
;    *
;    * DS:SI - addresses source data area
;    * ES:DI - addresses dest buffer area
;    *
;    */
;
;   for (total.byte.to.process != 0) {
;      /*
;       * find out how many bytes to process (least bytes to process)
;       */
;      if (source.type == conv.mem)
;         bytes.to.process = 0x4000 - dest.offset
;      else
;         if (dest.type == conv.mem)
;            bytes.to.process = 0x4000 - source.offset
;         else /* emm to emm */
;            if (backward.copy)
;               bytes.to.process = min(source.offset, dest.offset) + 1
;            else
;               bytes.to.process = 0x4000 - max(source.offset, dest.offset)
;
;      /*
;       * adjust the total
;       */
;      if (bytes.to.process > totol.bytes.to.process)
;         bytes.to.process = totol.bytes.to.process
;
;      total.bytes.to.process -= bytes.to.process
;
;      /*
;       * do the processing
;       */
;      move/exchange bytes.to.process bytes
;
;      /*
;       * adjust memory pointers and map in new pages if necessary
;       * for the next iternation
;       */
;      if (total.bytes.to.process != 0)
;         if (source.type == emm)
;            if (SI == 0x4000)
;               /*
;                * forward.copy's index expire
;                */
;               map next emm source page into source.page.frame
;               SI = 0
;            if (SI == 0xffff)
;               /*
;                * backward.copy's index expire
;                */
;               map prev emm source page into source.page.frame
;               SI = 0x3fff
;         else
;            normalize DS:SI
;
;         if (dest.type == emm)
;            if (DI == 0x4000)
;               /*
;                * forward.copy's index expire
;                */
;               map next emm dest page into dest.page.frame
;               DI = 0
;            if (DI == 0xffff)
;               /*
;                * backward.copy's index expire
;                */
;               map prev emm dest page into dest.page.frame
;               DI = 0x3fff
;         else
;            normalize ES:DI
;   }
;
;   restore first  page frame's mapping context
;   restore second page frame's mapping context
; END
;
;==============================================================================


_MoveExchangeMemory proc near
	mov	byte ptr [bp.rAX+1], OK     ; Assume everything work OK
	cld				    ; Assume forward direction

	cmp	al, 1			    ; Q: Valid subfunction?
	ja	mem_inv_sub		    ;	 N: Error

	push	ds
	pop	fs			    ; fs <-- addresses MEMM's data group

	push	dx
	push	cx
	push	bx
	push	ax

	push	bp
	mov	bp,[_regp]
	mov	ax, word ptr [bp.rDS]	    ; DX:AX <-- move/xchg struct
	mov	dx, word ptr [bp.rSI]
	Set_EMM_GDT	USER1_GSEL	    ; use USER1_GSEL since both EMM1_GSEL
					    ; and EMM2_GSEL will be used
	mov	ds, bx
	xor	si, si			    ; DS:SI <-- Move/Exchange structure
	pop	bp
	pop	ax
	pop	bx
	pop	cx
	pop	dx

	mov	ecx, [si.mem_region_length]; ECX = Length of memory region
	or	ecx, ecx		    ; Q: Move 0 bytes?
	jz	mem_no_error		    ;	 Y: Silly! -- Just return
	cmp	ecx, 0100000h		    ; Q: Move greater than 1 Meg?
	ja	mem_inv_region_len	    ;	 Y: Error

	mov	bl, [si.mem_source.mem_memory_type]; Q: Is move Conventional
	or	bl, [si.mem_dest.mem_memory_type]  ;	 to Conven?
	jz	mem_conv_to_conv		   ;	 Y: Go do it

	mov	bl, [si.mem_source.mem_memory_type]; Q: Is move EMM
	and	bl, [si.mem_dest.mem_memory_type]  ;	 to EMM
	jz	SHORT mem_no_overlap		   ;	 N: No overlap
	mov	bx, [si.mem_source.mem_handle]
	cmp	bx, [si.mem_dest.mem_handle]	; Q: Same handle?
	jnz	SHORT mem_no_overlap		;    N: No overlap
	movzx	ebx, [si.mem_source.mem_initial_seg_page]
	movzx	edx, [si.mem_source.mem_initial_offset]
	shl	ebx, 14 		    ; * 4000h
	add	ebx, edx		    ; EBX = Source offset within EMM
	push	ebx			    ; Save it temporarily
	movzx	edx, [si.mem_dest.mem_initial_seg_page]
	movzx	ebx, [si.mem_dest.mem_initial_offset]
	shl	edx, 14 		    ; * 4000h
	add	edx, ebx		    ; EDX = Dest offset within EMM
	pop	ebx			    ; Source offset
	sub	edx, ebx		    ; EDX = Source - Destination
	jg	SHORT mem_dest_gt_source    ; Don't negate if Dest > Source
	or	al, Source_GT_Dest_Flag     ; Set flag to note Source > Dest
	neg	edx			    ; Absolute value of EDX
mem_dest_gt_source:
	cmp	edx, ecx		    ; Q: Is there an overlap?
	jae	SHORT mem_no_overlap	    ;	 N: Continue
	test	al, 1			    ; Q: Is this an exchange?
	jnz	mem_inv_overlap 	    ;	 Y: Error -- Cant overlap xchg
	mov	byte ptr [bp.rAX+1], VALID_OVERLAP ; Assume everything OK but overlap
	or	al, Overlap_Flag	    ;	 N: Note this for later
	test	al, Source_GT_Dest_Flag	    ; Q: Is it gonna be backward copy
	jnz	mem_no_overlap		    ;    N: Continue
	or	al, Backward_Copy_Flag	    ;    Y: Note for later
	std				    ; Set backword direction

mem_no_overlap:
	;
	; check validility of source
	;
	lea	di, [si.mem_source]
	call	validate_for_Move_or_Exchange
	or	ah, ah
	jnz	mem_error_exit
	;
	; check validility of dest
	;
	lea	di, [si.mem_dest]
	call	validate_for_Move_or_Exchange
	or	ah, ah
	jnz	mem_error_exit

	or	edx, edx		    ; delayed test for exact move/xchg
	je	mem_valid_overlap	    ; WEIRD!!! -- Move to same place!
;
; initialize loop
;
	push	ds
	pop	gs
	mov	bx, si			    ; GS:BX <-- move/exchange structure
	;
	; save first 2 physical page frames' mapping and use those pages
	; as source and dest physical pages
	;
	push	fs
	pop	ds			; DS <-- DGROUP
	get_FRS_Window	SI
	push	word ptr [SI]	       ; save 1st pgae's mapping on stack
	push	word ptr [SI+2]	       ; save 2st page's mapping on stack

	;
	; setup dest
	;
mem_set_dest:
	cmp	gs:[bx.mem_dest.mem_memory_type], 0	; Q: conv mem ?
	jnz	mem_map_dest				;  N: map in emm page
	;
	; conv memory : setup starting address of dest (always forward)
	;
	mov	cx, gs:[bx.mem_dest.mem_initial_seg_page]
	mov	dx, gs:[bx.mem_dest.mem_initial_offset] ; CX:DX <-- dest address

	push	ax
	push	bx
	mov	ax, cx					; AX:DX <-- first byte
	Set_EMM_GDT	EMM2_GSEL
	mov	es, bx
	xor	di, di					; ES:DI <-- dest SelOff
	pop	bx
	pop	ax
	push	0ffffh					; fake a logical page#
	jmp	mem_set_source

mem_map_dest:
	;
	; emm memory : find out starting address of dest
	;
	mov	dx, gs:[bx.mem_dest.mem_initial_seg_page] ; initial logical page#
	mov	di, gs:[bx.mem_dest.mem_initial_offset]   ; initial offset

	test	al, Backward_Copy_Flag			; Q: Backward copy ?
	jz	SHORT mem_map_dest_forward		;  N: forward

	;
	; backward move : calculate last logical page# and offset
	;
	mov	ecx, gs:[bx.mem_region_length]
	movzx	edi, gs:[bx.mem_dest.mem_initial_offset]
	dec	edi
	add	ecx, edi
	push	ecx
	and	ecx, 00003fffh
	mov	edi, ecx				; new offset
	pop	ecx
	shr	ecx, 14					; / 16K = # of pages
	add	dx, cx					; last emm page#

mem_map_dest_forward:
	push	dx		; put current dest logical page# on stack
	;
	; prepare to map
	;
	push	ax
	push	bx

	push	dx
	mov	dx, gs:[bx.mem_dest.mem_handle]
	Handle2HandlePtr
	pop	bx
	mov	ax, 1					; 2nd page frame
	call	map_page
	jc	mem_mapping_error_3_pop			; pop out dest seg_page

	; contruct GDT entry for EMM2_GSEL for ES:0
	;
	mov	ax, [PF_Base]
	add	ax, 0400h			; 2nd page frame segment
	xor	dx, dx				; offset 0
	Set_EMM_GDT	EMM2_GSEL
	mov	es, bx				; ES:DI <-- dest address

	pop	bx
	pop	ax

	;
	; setup source
	;
mem_set_source:
	cmp	gs:[bx.mem_source.mem_memory_type], 0	; Q: conv mem ?
	jnz	mem_map_source				;  N: map in emm page
	;
	; conv memory : setup starting address of source (always forward)
	;
	mov	cx, gs:[bx.mem_source.mem_initial_seg_page]
	mov	dx, gs:[bx.mem_source.mem_initial_offset] ; CX:DX <-- source address

	push	ax
	push	bx
	push	es
	mov	ax, cx					; AX:DX <-- first byte
	Set_EMM_GDT	EMM1_GSEL
	mov	ds, bx
	xor	si, si
	pop	es
	pop	bx
	pop	ax
	push	0ffffh					; fake a logical page#
	jmp	short mem_set_done

mem_map_source:
	;
	; emm memory : find out starting address of dest
	;
	mov	dx, gs:[bx.mem_source.mem_initial_seg_page] ; initial logical page#
	mov	si, gs:[bx.mem_source.mem_initial_offset]   ; inital offset

	test	al, Backward_Copy_Flag			; Q: Backward copy ?
	jz	SHORT mem_map_source_forward		;  N: forward

	;
	; backward move : calculate last logical page# and offset
	;
	mov	ecx, gs:[bx.mem_region_length]
	movzx	esi, gs:[bx.mem_source.mem_initial_offset]
	dec	esi
	add	ecx, esi
	push	ecx
	and	ecx, 00003fffh
	mov	esi, ecx				; new offset
	pop	ecx
	shr	ecx, 14					; / 16K = # of pages
	add	dx, cx					; last emm page#

mem_map_source_forward:
	push	dx		; put current source logical page# on stack
	;
	; prepare to map
	;
	push	ax
	push	bx

	push	dx
	mov	dx, gs:[bx.mem_source.mem_handle]
	Handle2HandlePtr
	pop	bx
	mov	ax, 0					; 1st page frame
	call	map_page
	jc	mem_mapping_error_4_pop			; pop out dest and source seg_page

	; contruct GDT entry for EMM1_GSEL for DS:0
	;
	mov	ax, [PF_Base]			; 1st page frame segment
	xor	dx, dx				; offset 0
	push	es
	Set_EMM_GDT	EMM1_GSEL
	pop	es				; ES:0 <-- GDT
	mov	ds, bx				; ES:DI <-- dest address

	pop	bx
	pop	ax

	; DS:SI <-- source address
	; ES:DI <-- dest address

mem_set_done:
	mov	edx, gs:[bx.mem_region_length]	; total length to move/xchg

;
; main move/exchange loop
;
mem_loop:
	mov	ecx, cr3
	mov	cr3, ecx			; flush TLB after each map loop

	mov	ecx, 4000h			; maximum length to move/xchg
						; in one mapping (<16K)
	cmp	gs:[bx.mem_source.mem_memory_type], 0	; Q: conv mem ?
	jnz	mem_source_is_emm			;  N: check dest
	sub	cx, di				; CX <-- length to move/xchg
	jmp	short mem_calculate_length
mem_source_is_emm:
	cmp	gs:[bx.mem_dest.mem_memory_type], 0	; Q: conv mem ?
	jnz	mem_both_are_emm			;  N: find out which
							;     emm has less
							;     to move/exchange
	sub	cx, si				; CX <-- length to move/xchg
	jmp	short mem_calculate_length
mem_both_are_emm:
	test	al, Backward_Copy_Flag		; Q:backward copy ?
	jz	SHORT mem_2_emm_forward		;  N:forward
	mov	cx, si
	inc	cx
	cmp	si, di				; Q:si<di ? (min(si,di))
	jb	short mem_calculate_length	;  Y: use si
	mov	cx, di				;  N: use di
	inc	cx
	jmp	short mem_calculate_length

mem_2_emm_forward:
	cmp	si, di				; Q:si>di ? (max(si,di))
	ja	mem_si_gt_di			;  Y: use si
	sub	cx, di				;  N: use di
	jmp	short mem_calculate_length
mem_si_gt_di:
	sub	cx, si				; si>di

mem_calculate_length:
	cmp	ecx, edx		    ; Q: bytes in this batch > total
	jbe	mem_do_move_xchg	    ;  N: go ahead to move/xchg
	mov	ecx, edx		    ;  Y: use total instead

;
; move/xchg loop
;
mem_do_move_xchg:
	sub	edx, ecx			; Adjust total first

	test	al, 1				; Q: Is this an exchange?
	jnz	SHORT mem_exchange		;  Y: Do it
	test	al, Backward_Copy_Flag		;  N: Q:Is this backward copy ?
	jz	SHORT mem_move_forward		;      N: forward
;
; memory move backward
;
	rep movsb
	jmp	mem_next_round
;
; memory move forward
;
mem_move_forward:
	push	eax
	mov	eax, ecx
	shr	ecx, 2			    ; ECX = # DWORDS to copy
	rep movsd			    ; Move the DWORDS
	mov	ecx, eax
	and	ecx, 00000003h		    ; ECX = # BYTES left to copy
	rep movsb			    ; Move the BYTES
	pop	eax
	jmp	short mem_next_round
;
; momory exchange
;
mem_exchange:
	push	dx
	push	ax
	push	bx
	push	ecx			    ; Save total # bytes on stack
	shr	ecx, 2			    ; ECX = # DWORDS to exchange
	jecxz	mem_xchg_bytes		    ; Exit if no DWORDS left
	mov	dx, 4			    ; Size of DWORD
mem_xchg_dword_loop:
	mov	eax, [si]
	mov	ebx, es:[di]
	mov	es:[di], eax
	mov	[si], ebx
	add	si, dx
	add	di, dx
	loop	mem_xchg_dword_loop	    ; Loop until all DWORDS exchanged
mem_xchg_bytes:
	pop	ecx
	and	ecx, 00000003h		    ; ECX = # BYTES left to exchange
	jecxz	mem_xchg_done		    ; Exit if no DWORDS left
mem_xchg_byte_loop:
	mov	al, [si]
	mov	bl, es:[di]
	mov	es:[di], al
	mov	[si], bl
	inc	si
	inc	di
	loop	mem_xchg_byte_loop	    ; Loop until all BYTES exchanged
mem_xchg_done:
	pop	bx
	pop	ax
	pop	dx			    ; DONE!!!!

;
; prepare for next iteration
;
mem_next_round:
	;
	; get source and dest's current mapped logical page
	; from stack
	;
	pop	cx		; source logical page#
	shl	ecx, 16		; put in high word
	pop	cx		; dest logical page#

	or	edx, edx			; Q: all done ?
	jz	mem_exit			;  Y: restore context first

	; fix dest addresses
	;
	cmp	gs:[bx.mem_dest.mem_memory_type], 0 ; Q: conv mem ?
	jnz	mem_map_next_dest	      	    ;  N: map next page
	normalize	ES,DI
	jmp	mem_check_source

mem_map_next_dest:
	cmp	di, 4000h			; Q: di expires (forward)?
	je	short mem_map_next_dest_forward	;  Y: 
	cmp	di, 0ffffh			; Q: di expires (backward) ?
	jne	short mem_check_source		;  N: go check source

	mov	di, 3fffh			; set di for next round
	dec	cx				; next logical page
	jmp	SHORT mem_map_next_dest_do_map

mem_map_next_dest_forward:
	xor	di, di				; clear di for next round
	inc	cx				; next logical page

	;
	; map in the next dest page
	;
mem_map_next_dest_do_map:
	push	dx
	push	ax
	push	bx
	push	ecx
	push	ds
	push	fs
	pop	ds
	mov	dx, gs:[bx.mem_dest.mem_handle]
	Handle2HandlePtr
	mov	ax, 1				; 2nd page frame
	mov	bx, cx
	call	map_page
	pop	ds
	pop	ecx
	pop	bx
	pop	ax
	pop	dx
	jc	mem_mapping_error

	;
	; fix source addresses
	;
mem_check_source:
	ror	ecx, 16				      ; get source log page in low word
	cmp	gs:[bx.mem_source.mem_memory_type], 0 ; Q: conv mem ?
	jnz	mem_map_next_source		      ;  N: map next page
	normalize	DS,SI
	jmp	mem_check_done

mem_map_next_source:
	cmp	si, 4000h			; Q: si expires (forward)?
	je	short mem_map_next_source_forward ;  Y:
	cmp	si, 0ffffh			; Q: si expires (backward) ?
	jne	short mem_check_done		;  N: all done

	mov	si, 3fffh			; set si for next round
	dec	cx				; next logical page
	jmp	SHORT mem_map_next_source_do_map

mem_map_next_source_forward:
	xor	si, si				; clear si for next round
	inc	cx				; next logical page

	;
	; map in the next source page
	;
mem_map_next_source_do_map:
	push	dx
	push	ax
	push	bx
	push	ecx
	push	ds
	push	fs
	pop	ds
	mov	dx, gs:[bx.mem_source.mem_handle]
	Handle2HandlePtr
	mov	ax, 0				; 1st page frame
	mov	bx, cx
	call	map_page
	pop	ds
	pop	ecx
	pop	bx
	pop	ax
	pop	dx
	jc	mem_mapping_error
	;
	; push back the logical pages on stack for
	; next iternation : dest first, then source
	;
mem_check_done:
	ror	ecx, 16		
	push	cx
	ror	ecx, 16
	push	cx
	jmp	mem_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; conv to conv
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mem_conv_to_conv:
	;
	; check validility of source
	;
	lea	di, [si.mem_source]
	call	validate_for_Move_or_Exchange
	or	ah, ah
	jnz	mem_error_exit
	;
	; check validility of dest
	;
	lea	di, [si.mem_dest]
	call	validate_for_Move_or_Exchange
	or	ah, ah
	jnz	mem_error_exit

	push	ax				; save subfunction
	push	[si.mem_region_length]		; save length

	movzx	eax, [si.mem_dest.mem_initial_seg_page]
	movzx	edx, [si.mem_dest.mem_initial_offset]
	mov	edi, eax
	shl	edi, 4
	add	edi, edx			; EDI <-- dest linear addr
	Set_EMM_GDT	EMM2_GSEL
	Set_Page_Gran	EMM2_GSEL
	push	bx				; save dest GDT selector

	movzx	eax, [si.mem_source.mem_initial_seg_page]
	movzx	edx, [si.mem_source.mem_initial_offset]
	mov	esi, eax
	shl	esi, 4
	add	esi, edx			; ESI <-- source linear addr
	Set_EMM_GDT	EMM1_GSEL
	Set_Page_Gran	EMM1_GSEL
	mov	ds, bx

	pop	es				; recover dest GDT sel
	pop	ecx				; recover length
	pop	ax				; recover subfunction
	;
	; test for overlapping transfer
	;
	mov	byte ptr [bp.rAX+1], VALID_OVERLAP ; assume valid overlap
	sub	edi, esi		    ; EDI = Source - Destination
	jg	SHORT mem_dest_gt_source_2  ; Don't negate if Dest > Source
	or	al, Source_GT_Dest_Flag     ; Set flag to note Source > Dest
	neg	edi			    ; Absolute value of EDI
mem_dest_gt_source_2:
	mov	ebx, edi		    ; Use EBX instead
	cmp	ebx, ecx		    ; Q: Is there an overlap?
	jae	SHORT mem_no_overlap_2	    ;	 N: Continue
	test	al, 1			    ; Q: Is this an exchange?
	jnz	mem_inv_overlap 	    ;	 Y: Error -- Cant overlap xchg
	or	al, Overlap_Flag	    ;	 N: Note this for later
	test	al, Source_GT_Dest_Flag	    ; Q: Is it gonna be backward copy
	jnz	mem_no_overlap_2	    ;    N: Continue
	or	al, Backward_Copy_Flag	    ;    Y: Note for later

	mov	edx, (not 1)+1		    ; increment value of -1 (2's compliment of 4)
	mov	esi, ecx		    ; Fix ESI and EDI for reverse copy
	dec	esi
	mov	edi, esi
	jmp	short mem_conv_copy

mem_no_overlap_2:
	mov	byte ptr [ebp.rAX+1], OK	; Everything worked OK
	mov	edx, 1				; increment value of 1
	xor	esi, esi			; DS:ESI <-- source addr
	xor	edi, edi			; ES:EDI <-- dest addr

	test	al, 1				; Q:copy ?
	jnz	mem_conv_xchg			;   N:go do exchange

mem_conv_copy:
	or	ebx, ebx
	je	mem_valid_overlap	    ; WEIRD!!! -- Move to same place!

	jecxz	mem_conv_done
mem_conv_copy_loop:
	mov	bl, [esi]
	mov	es:[edi], bl
	add	esi, edx
	add	edi, edx
	dec	ecx
	jnz	mem_conv_copy_loop
	jmp	mem_conv_done		    ; DONE!!!!

mem_conv_xchg:
	jecxz	mem_conv_done
mem_conv_xchg_loop:
	mov	al, [esi]
	mov	bl, es:[edi]
	mov	es:[edi], al
	mov	[esi], bl
	inc	esi
	inc	edi
	dec	ecx
	jnz	mem_conv_xchg_loop	    ; Loop until all BYTES exchanged
mem_conv_done:
	Set_Byte_Gran	EMM1_GSEL		; make sure EMM1_GSEL and
	Set_Byte_Gran	EMM2_GSEL		; EMM2_GSEL are Byte Granulated
	ret

mem_error_exit:
	cld
	mov	byte ptr [bp.rAX+1], ah	; error code already set in ah
	ret
mem_valid_overlap:
	mov	byte ptr [bp.rAX+1], VALID_OVERLAP
	ret
mem_no_error:
	mov	byte ptr [bp.rAX+1], OK
	ret

mem_inv_sub:
	mov	byte ptr [bp.rAX+1], INVALID_SUBFUNCTION
	ret
mem_inv_region_len:
	mov	byte ptr [bp.rAX+1], INVALID_REGION_LENGTH
	ret
mem_bad_memory_types:
	mov	byte ptr [bp.rAX+1], INVALID_MEMORY_TYPE
	ret
mem_inv_overlap:
	mov	byte ptr [bp.rAX+1], OVERLAPPING_EXCHANGE
	ret
;
; discard old ax,bx,source seg_page#,dest seg_page#
;
mem_mapping_error_4_pop:
	pop	bx
mem_mapping_error_3_pop:
	pop	bx
	pop	bx
	pop	bx
mem_mapping_error:
	mov	eax, cr3  		    ; Always clear TLB, we may have
	mov	cr3, eax		    ; mapped pages before an error
;
; all done, need to restore context of physical page frames
;
mem_exit:
	push	fs				; get DGROUP back into DS
	pop	ds
	get_FRS_Window	BX
	pop	word ptr [bx+2]
	pop	word ptr [bx]
	cld					; string forward again
	jmp	_set_windows			; remap all pages

_MoveExchangeMemory endp


;******************************************************************************
;
;   validate_for_Move_Or_Exchange
;
;	This procedure is called by _MoveExchangeMemory to validate
;	varies parameter on the memeory descriptor structure.
;	It is called once for the source and once for the
;	destination memory descriptor structures.
;
;   ENTRY:
;	CX    = move length
;	DS:DI = Move/Exchange memory descriptor data structure (source or dest)
;	FS    = MEMM's data segment
;   EXIT:
;	AH = Status (0 = No error) -- AL is preserved
;
;   USES:
;	DI, Flags
;	AL and all other registers are preserved
;
;==============================================================================

validate_for_Move_Or_Exchange    PROC NEAR

	push	edx			    ; Used as temporary variable
	push	eax

	mov	dl, [di.mem_memory_type]
	or	dl, dl			    ; Q: Conventional memory?
	jz	ME_Map_Conventional	    ;	 Y: Nothing to map
	cmp	dl, 1			    ; Q: Expanded memory?
	jne	ME_Map_Inv_Mem		    ;	 N: Invalid memory type
					    ;	 Y: EMM memory -- Must map it
	mov	dx, [di.mem_handle]	    ; Get the handle

	push	ds				; validate_handle expect DS
	push	fs				; points to dgroup
	pop	ds
	Validate_Handle	ME_Map_Inv_Handle	; check it
	pop	ds

	xchg	bx, dx
	mov	ax, fs:[bx.ht_count]	    ; EAX = # pages in handle
	xchg	bx, dx
	cmp	ax,[di.mem_initial_seg_page];Q: Is initial page in range
	jbe	ME_Map_Invalid_log_page     ;	 N: Error
	cmp	[di.mem_initial_offset], 04000h; Q: Is offset unreasonable?
	jae	ME_Map_Invalid_Offset	       ;    Y: Error

	movzx	edx, [di.mem_initial_offset]
	add	edx, ecx
	add	edx, 16 * 1024 - 1		; round up to nearest emm page boundary
	shr	edx, 14				; / 16K = # of emm pages
	add	dx, [di.mem_initial_seg_page]	; last emm page of move/exchange
	cmp	dx, ax
	ja	ME_Map_Not_Enough_EMM		;Q: Is last page in range
	jmp	short ME_Map_OK			;  N: error

ME_Map_Conventional:
	movzx	edx, word ptr [di.mem_initial_seg_page]
	shl	edx, 4
	movzx	edi, word ptr [di.mem_initial_offset]
	add	edx, edi		    ; EDX --> Conven mem to move/exch
	mov	edi, edx		    ; Use EDI for test
	add	edi, ecx		    ; EDI = Base + Move length
	cmp	edi, 100000h		    ; Q: Is there wraparound?
	jae	SHORT ME_Map_Inv_Wraparound ;	 Y: Error
	cmp	fs:[_page_frame_pages], 0   ; Is there a page frame?
	je	short No_EMM_Overlap	    ;	 no, no problem
	cmp	edi, 0E0000h		    ; Q: Is move ABOVE EMM area?
	jae	SHORT No_EMM_Overlap	    ;	 Y: That's not a problem
	movzx	eax, fs:[PF_Base]	    ; Where page frame starts
	shl	eax, 4
	cmp	edi, eax		    ; Q: Does move run into EMM area?
	ja	SHORT ME_Map_Inv_Overlap    ;	 Y: Error
No_EMM_Overlap:
					    ;	 N: Everything is okie dokie
ME_Map_OK:
	pop	eax
	pop	edx
	mov	ah, OK
	ret

ME_Map_Inv_Mem:
	pop	eax
	pop	edx
	mov	ah, INVALID_MEMORY_TYPE
	ret

ME_Map_Inv_Handle:
	pop	ds
	pop	eax
	pop	edx
	mov	ah, INVALID_HANDLE
	ret

ME_Map_Invalid_log_page:
	pop	eax
	pop	edx
	mov	ah, LOG_PAGE_RANGE
	ret

ME_Map_Invalid_Offset:
	pop	eax
	pop	edx
	mov	ah, INVALID_OFFSET
	ret

ME_Map_Not_Enough_EMM:
	pop	eax
	pop	edx
	mov	ah, INSUFFICIENT_EMM_PAGES
	ret

ME_Map_Inv_Overlap:
	pop	eax
	pop	edx
	mov	ah, CONVENTIONAL_EMM_OVERLAP
	ret

ME_Map_Inv_Wraparound:
	pop	eax
	pop	edx
	mov	ah, INVALID_WRAPAROUND
	ret

validate_for_Move_Or_Exchange    ENDP


	page
;***********************************************
;
; _AlternateMapRegisterSet - handle alternative register sets
;
;	This routine switches the current register set or stores
; the current page mapping context to an external save area and/or
; restores the current page mapping context from an external save area.
;
; ENTRY: PROTECTED MODE ONLY
;	 AH = 5Bh = Alternate Map Register Set function
;	 AL = SUBFUNCTION CODE
;		AL = 0  => Get Alternate Map Register Set
;		AL = 1  => Set Alternate Map Register Set
;		AL = 2  => Get and Set Alternate Map Register Set
;		AL = 3  => Get Alternate Map Save Array size
;		AL = 4  => Allocate Alternate Map Register Set
;		AL = 5  => Deallocate Alternate Map Register Set
;		AL = 6  => Enable DMA on Alternate Map Register Set
;		AL = 7  => Disable DMA on Alternate Map Register Set
; 	See sub-functions for individual ENTRY registers
;	 SS:[EBP] -> regp stack frame
;	 DS = DGROUP
;
; EXIT:	from individual sub-function or error with
;	AH = INVALID_SUBFUNCTION
;
; USED:	EAX,ESI
;
;***********************************************
Dword_Align	_TEXT
_AlternateMapRegisterSet	proc	near
	cmp	[_OSEnabled], OS_DISABLED
	jae	short AMRS_NotAllowed	; Disabled by OS
	cmp	al, 08h			; Valid sub-function?
	ja	short AMRS_invalid
	cld				; Done for all sub-functions
	mov	byte ptr [bp.rAX+1], OK ; Assume success!
	movzx	esi, al			; get offset to function dispatch
	shl	si, 1
	jmp	CS:AMRS_map[si]		; go to relevant sub-function
					; Return directly or to AMRS_exit...
AMRS_exit:				; Exit with AH already set
	ret

AMRS_NotAllowed:
	mov	byte ptr [bp.rAX+1], ACCESS_DENIED
	ret

AMRS_invalid:
	mov	byte ptr [bp.rAX+1], INVALID_SUBFUNCTION
	ret				; Error return!

AMRS_bad_src:
	mov	byte ptr [bp.rAX+1], SOURCE_CORRUPTED
	ret				; Error return!

AMRS_noDMA:
	mov	byte ptr [bp.rAX+1], FRSET_NO_DMA
	ret				; Error return!

Dword_Align	_TEXT
AMRS_map	dw	_TEXT:AMRS_get
		dw	_TEXT:AMRS_set
		dw	_TEXT:AMRS_size
		dw	_TEXT:AMRS_allocate
		dw	_TEXT:AMRS_deallocate
							; For now...
		dw	_TEXT:AMRS_noDMA		; AMRS_DMAallocate
		dw	_TEXT:AMRS_noDMA		; AMRS_DMAassign
		dw	_TEXT:AMRS_noDMA		; AMRS_DMAdeassign
		dw	_TEXT:AMRS_noDMA		; AMRS_DMAfree

	page
;***********************************************
;
; AMRS_get - get the current 'fast' register set
;
;	ENTRY: on stack
;	 SS:[EBP] -> regp stack frame
;	 DS = DGROUP
;
;	EXIT:	on stack
;		BL = register set number,
;		state stored in client's buffer if BL == 0
;		ES:SI set to point to client's buffer
;		return code set on stack
;
;	USED: EAX, EBX
;
;  DESCRIPTION: This function returns the current register set number.
;		If it is zero, it returns the save area previously specified
;
;-----------------------------------------------
Dword_Align	_TEXT
AMRS_get:
	mov	al, [CurRegSetn]		; Get current set number
	mov	byte ptr [bp.rBX], al		; to be picked up later
	or	al, al
	jz	short AMRS_get0
	ret					; non-zero - all done
AMRS_get0:					; Echo save area address
	movzx	eax, [EMM_savES]		; saved ES for reg set 0
	mov	word ptr [bp.rES], ax
	movzx	edi, [EMM_savDI]		; saved DI for reg set 0
	mov	word ptr [bp.rDI], di
	or	ax, ax
	jnz	short AMRS_get2			; got dest addr
	or	di, di
	jz	short AMRS_get1			; not specified yet
AMRS_get2:
	xor	dx, dx
	Set_EMM_GDT	EMM1_GSEL
	mov	es, bx				; ES:DI <-- temp store
	Get_FRS_window	SI			; Get pointer to current window
	movzx	eax, [_cntxt_pages]		; how many pages
	stosw					; save size
	mov	ecx, eax
	shr	ecx, 1				; convert to dwords
	rep movsd				; save the map
AMRS_get1:
	ret
	
	page
;***********************************************
;
; AMRS_set - set the current 'fast' register set
;
;	ENTRY:  BL = register set number
;		on stack
;		if BL == 0
;			ES:DI -> buffer containing mappings for register set 0
;	 SS:[EBP] -> regp stack frame
;	 DS = DGROUP
;
;	EXIT:	return code set on stack
;
;	USED:	EAX, EBX, ECX, EDX, ESI, EDI
;
;  DESCRIPTION: This function sets the current register set number.
;		If it is zero, it uses the save area specified in ES:DI.
;
;-----------------------------------------------
Dword_Align	_TEXT
AMRS_set:
	cmp	bl, FRS_COUNT			; Validate new Reg Set
	jae	AMRS_inv_FRS
	movzx	eax, bl
	imul	eax, size FRS_struc
	xchg	ax, bx
	lea	bx, FRS_array[bx]		; Get pointer to the new Reg Set
	cmp	[bx.FRS_alloc], 0		; Make sure it is allocated
	xchg	ax, bx
	je	AMRS_undef_FRS			;   unallocated, go complain

	cmp	bl, 0				; New reg set 0?
	je	short AMRS_set0			;   yes, always set context
	cmp	bl, [CurRegSetn]		; Setting the same reg set?
	je	AMRS_exit			;   yes, just return
AMRS_set0:					; Now set up new reg set
	mov	word ptr [CurRegSet], ax	; Set Current reg. set Offset
	mov	[CurRegSetn], bl

	or	bl, bl				; Real register set?
	jne	_set_windows			;   yes, go deal with it
						;   no, deal with reg set 0
	mov	ax, word ptr [bp.rES]		; Pick up user's pointer
	mov	[EMM_savES], ax			; and save for AMRS_get
	mov	dx, word ptr [bp.rDI]
	mov	[EMM_savDI], dx			; AX:DX <-- regs cntxt restore area
	push	ax
	or	ax, dx
	pop	ax
	jz	_set_windows			; AX:DX == 0:0 implies no save area

	; construct GDT entry using EMM1_GSEL to access user's FRS buffer
	;
	push	es
	Set_EMM_GDT	EMM1_GSEL
	pop	es

	mov	fs, bx				; FS:SI <-- FRS buffer
	xor	si, si
	lods	word ptr fs:[si]		; get saved count
	movzx	ecx, [_cntxt_pages]		; what it should be
	cmp	ax, cx				; Sensible count?
	jne	_set_windows			;   no, restore last context
	Get_FRS_window	DI
	shr	ecx, 1				; size in dwords
	push	ds				; xchg ds,fs
	push	fs
	pop	ds
	pop	fs				; use DS as default seg. reg.
	rep movsd
	push	ds
	push	fs
	pop	ds
	pop	fs
	jmp	_set_windows			; set up mappings

	page
;***********************************************
;
; AMRS_size - get the size of the register set 0 save area
;
;	ENTRY:
;	 SS:[EBP] -> regp stack frame
;	 DS = DGROUP
;
;	EXIT:	return code set on stack
;		DX = size of the save area
;
;	USED:	none
;
;  DESCRIPTION: This function returns the size of the save area used
;		for register set 0.
;
;-----------------------------------------------
AMRS_size:
	movzx	eax, [_cntxt_bytes]		; Previously calculated value
	mov	word ptr [bp.rDX], ax
	ret

	page
;***********************************************
;
; AMRS_allocate - allocate a fast register set
;
;	ENTRY:
;	 SS:[EBP] -> regp stack frame
;	 DS = DGROUP
;
;	EXIT:	return code set on stack
;		BL = register set number
;
;	USED:	EBX, ESI
;
;  DESCRIPTION: This function allocates a free register set.
;
;-----------------------------------------------
AMRS_allocate:
	cmp	[FRS_free], 0			; See if any are free
	je	short AMRS_noRS			;   no, none available
						; Search for first free set
	dec	[FRS_free]			; We are going to take one
	lea	di, [FRS_array]			; Start of FRS structures
	xor	bl, bl				; FRS number
AMRS_search:
	cmp	[di.FRS_alloc], 0		; This one free?
	je	short AMRS_foundRS		;   yes, bl has the number
	add	di, size FRS_struc		; on to the next one
	inc	bl
	cmp	bl, FRS_COUNT			; Safety... should never fail
	jb	short AMRS_search

	mov	byte ptr [bp.rAX+1], EMM_SW_MALFUNCTION	; Honesty...
	ret

AMRS_foundRS:
	mov	[di.FRS_alloc], 1		; Allocate it
	Get_FRS_Window	SI
	lea	di, [di.FRS_Window]
	movzx	ecx, [_cntxt_pages]
	shr	ecx, 1
	rep movsd				; Initialise to current mapping
	mov	byte ptr [bp.rBX], bl		; Return the number
	ret

AMRS_noRS:					; None free; return error
	mov	byte ptr [bp.rAX+1], NO_MORE_FRSETS
	ret

	page
;***********************************************
;
; AMRS_deallocate - deallocate a fast register set
;
;	ENTRY:	BL = register set to deallocate
;	 SS:[EBP] -> regp stack frame
;	 DS = DGROUP
;
;	EXIT:	return code set on stack
;
;	USED:	EAX
;
;  DESCRIPTION: This function deallocates a register set.
;
;-----------------------------------------------
AMRS_deallocate:
	or	bl, bl
	jz	AMRS_exit			; Deallocating 0 is ignored
	cmp	bl, [CurRegSetn]		; Can't deallocate current set
	je	short AMRS_undef_FRS
	cmp	bl, FRS_COUNT
	jae	short AMRS_undef_FRS		; Invalid Register set
	movzx	eax, bl
	imul	eax, size FRS_struc		; Offset into array
	xchg	ax, bx
	cmp	FRS_array[bx.FRS_alloc], 0	; Paranoid...
	xchg	ax, bx
	je	short AMRS_undef_FRS		;   Not allocated, complain
	xchg	ax, bx
	mov	FRS_array[bx.FRS_alloc], 0	; Mark it free
	xchg	ax, bx
	inc	[FRS_free]			; one more set free
	ret

AMRS_Inv_FRS:
AMRS_undef_FRS:
	mov	byte ptr [bp.rAX+1], FRSET_UNDEFINED
	ret

_AlternateMapRegisterSet	endp


	page
;******************************************************************************
;   _Get_Key_Val - use the timer to get a random number for OSDisable Key
;
;   ENTRY   DS, ES = DGROUP selectors
;
;   STACK
;
;   EXIT    EAX has randomish number
;
;   USES    Flags, EAX, EDX
;
;------------------------------------------------------------------------------
_Get_Key_Val	proc	near
	call	Get_Counter_Value		; (Who cares about the junk in
	mov	dx, ax				; the high words...?)
	call	Get_Counter_Value		; Likely to be very close
	mul	edx				; Mess it all up!
	ret
	
_Get_Key_Val	endp

;******************************************************************************
;
;   NAME:
;	Get_Counter_Value
;
;   DESCRIPTION:
;	Returns the current system timer counter value
;
;   ENTRY:
;	Assumes nothing
;
;   EXIT:
;	AX = Current counter value (High word of EAX NOT CHANGED)
;
;   USES:
;	Flags
;
;------------------------------------------------------------------------------

Get_Counter_Value	PROC NEAR

System_Clock_Port   EQU 40h
Sys_Clock_Ctrl_Port EQU 43h

Latch_Counter	    EQU 0

	mov	al, Latch_Counter
	out	Sys_Clock_Ctrl_Port, al 	; Latch the timer counter
	jmp	$+2
	in	al, System_Clock_Port		; Read the LSB
	mov	ah, al
	jmp	$+2
	in	al, System_Clock_Port		; Read the MSB
	xchg	ah, al				; AX = Counter value
	ret

Get_Counter_Value	ENDP


_TEXT	ENDS
END


