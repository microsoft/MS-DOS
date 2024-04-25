

page	58,132
;******************************************************************************
	title	InitTab - OEM init routines to init tables
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   InitTab
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
;   06/21/86  0.02	Added cld
;   06/28/86  0.02	Name changed from MEMM386 to MEMM
;   07/05/86  0.04	Added NOHIMEM ifdef and added code to
;			move _TEXT segment to high mem
;   07/06/86  0.04	changed assume to DGROUP
;   07/06/86  0.04	added ring0 stack move
;   07/10/86  0.05	removed CODE_GSEL reset
;   07/10/86  0.05	PageT_Seg and PageD_Seg
;
;******************************************************************************
;
;   Functional Description:
;
;	This module is called after the system has been set up in a viable
;   state to start executing MEMM.  This routine provides a "hook" where
;   the tables (GDT,IDT,TSS, & PageTables, etc) can be modified.  This routine
;   must set the variables which hold the 32 bit address for each of the
;   VDM tables.  This routine also sets up the EXTRA1_GSEL to point to the
;   Diagnostics byte segment.
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	InitTab

	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
OEM_MEM_HI	equ	80c0h		; Upper 16 bits of high mem physical adr

	include VDMseg.inc
	include VDMsel.inc
	include desc.inc
	include page.inc
	include instr386.inc
	include oemdep.inc
;
;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************
;

GDT	segment
	extrn	GDTLEN:abs
GDT	ends

IDT	segment
	extrn	IDTLEN:abs
IDT	ends

TSS	segment
	extrn	TSSLEN:abs
TSS	ends

PAGESEG segment
	extrn	P_TABLE_CNT:abs
PAGESEG ends


_DATA	segment
	extrn	TEXT_Seg:word		; segment for TEXT
	extrn	STACK_Seg:word		; segment for STACK
	extrn	GDT_Seg:word		; segment for GDT
	extrn	IDT_Seg:word		; segment for IDT
	extrn	TSS_Seg:word		; segment for TSS
	extrn	PageD_Seg:word		; segment for page dir
	extrn	PageT_Seg:word		; segment for page table
	extrn	Page_Dir:word		; 32 bit address for Page directory
	extrn	driver_end:dword	; ending address for MEMM.EXE
	extrn	_emm_brk:word		; break address for EMM data

_DATA	ends

LAST	segment
ifndef	NOHIMEM
	extrn	HiSysAlloc:near 	; allocate high system memory
	extrn	UnLockROM:near
	extrn	LockROM:near
endif
	extrn	SegTo24:near
	extrn	SetSegDesc:near
	extrn	SetPageEntry:near
	extrn	moveb:near
	extrn	get_buffer:near

LAST	ends

_TEXT	segment
	extrn	Real_Seg:word	; fixup for _TEXT in RetReal (retreal.asm)
_TEXT	ends

R_CODE	segment
	extrn	EFunTab:word	; table of ELIM functions
	extrn	EFUN_CNT:abs	; # of entries in table
	extrn	EMM_rEfix:near	; far call to EMM function dispatcher in _TEXT
R_CODE	ends


;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************
;
;------------------------------------------------------------------------------
LAST	segment
	assume	cs:LAST, ds:DGROUP, es:DGROUP, ss:DGROUP
	page
;******************************************************************************
;   InitTab - init tables & 32 bit address
;
;   ENTRY: Real Mode
;	GDT = current segment for GDT
;	IDT = current segment for IDT
;	TSS = current segment for TSS
;	_TEXT = current segment for _TEXT
;	STACK = current segment for STACK
;	DGROUP:[PageD_Seg] = current segment portion of page directory
;	DGROUP:[PageT_Seg] = current segment portion of page tables
;	DGROUP:[Page_Dir] = current 32 bit address for page directory
;	IDTLEN:abs = length of IDT
;	TSSLEN:abs = length of TSS
;	P_TABLE_CNT:abs = # of page TABLES
;	_TEXT:[Real_Seg] =  fixup location for _TEXT in RetReal
;	R_CODE:[EFunTab] = table of ELIM functions
;	R_CODE:EFUN_CNT = # of entries in table
;	R_CODE:[EMM_rEfix] = far call to EMM function dispatcher in _TEXT
;
;   EXIT:  Real Mode
;	DGROUP:[TEXT_Seg] = current segment for TEXT
;	DGROUP:[STACK_Seg] = current segment for STACK
;	DGROUP:[GDT_Seg] = current segment for GDT
;	DGROUP:[IDT_Seg] = current segment for IDT
;	DGROUP:[TSS_Seg] = current segment for TSS
;	DGROUP:[PageD_Seg] = current segment portion of page directory
;	DGROUP:[PageT_Seg] = current segment portion of page tables
;	DGROUP:[Page_Dir] = current 32 bit address for page directory
;	DGROUP:[driver_end] = end of MEMM.EXE device driver
;	GDT:[IDTD_GSEL]  = current descriptor for IDT
;	GDT:[TSS_GSEL]	 = current descriptor for TSS
;	GDT:[TSSD_GSEL]  = current descriptor for TSS
;	GDT:[PAGET_GSEL] = current descriptor for Page TABLES
;
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
InitTab proc	 near
;
ifndef	NOHIMEM

	PUSH_EAX
	push	di
	push	ds
	push	es
	pushf
	cli		; turn off ints
	cld		; strings foward
;
	mov	ax,seg DGROUP
	mov	ds,ax
;
;  set up GDT entry for the diagnostics segment
;
	mov	ax, seg GDT		; GDT not moved yet !
	mov	es,ax

	xor	dx,dx
	mov	al,00h			; only low 24 bits of address here !
	mov	cx,0			; 64k long
	mov	ah,D_DATA0		; data segment
	mov	bx,OEM0_GSEL
	call	SetSegDesc		; Set up GDT alias descriptor
	mov	ES:[bx.BASE_XHI],01h	; set high 8 bits of address

;
;------------------------------------------------------------------------------
;  Move Tables to HIGH SYSTEM memory
;	The high system memory is mapped to FE0000h - FEFFFFh
;	AND 0E0000h-0EFFFFh.   The following code copies data to the E0000h
;	range
;------------------------------------------------------------------------------
;

;
;------------------------------------------------------------------------------
;  move PAGE DIR/TABLES up to high memory
;------------------------------------------------------------------------------
;
	mov	ax,P_TABLE_CNT		; AX = # of page tables
	inc	ax			; include page directory
	mov	cx,ax			; CX=AX = # of pages for page table seg
	call	HiSysAlloc		;Q: enough room in high sys mem ?
	jnc	IT_move_pt		;  Y: move page dir/tables to hi sys mem
	inc	ax			;  N: Q: is error not enough room?
	jnz	To_IT_Exit		;     Y: just go ahead and exit
	popf
	stc				;     N: return CF = 1(mem alloc error)
	jmp	IT_Quit
To_IT_Exit:
	jmp	IT_Exit 		;  N: then nothing is moved up
IT_move_pt:				;
	call	UnLockROM		;turn off write protect
	shl	ax,8			;
	add	ax,0E000h		;  AX = segment for sys mem block
	mov	es,ax			;  ES -> sys mem block
	xor	di,di			;  ES:DI -> sys mem block
	mov	ax,[PageD_Seg]		;
	mov	ds,ax			; DS -> page dir/tables
	xor	si,si			; DS:SI -> page dir/tables
	shl	cx,10			; CX = # of dwords in page tables
	cld
	OP32
	rep movsw			; mov cx dwords into hi sys mem
;
	mov	ax,seg DGROUP
	mov	ds,ax			; DS = DATA
;
;   reset break address for driver
;
	mov	word ptr [driver_end],0
	mov	ax,[PageD_Seg]
	mov	word ptr [driver_end+2],ax

;
;			reset page dir/table pointers
	XOR_EAX_EAX			; clear eax
	mov	ax,es			;
	mov	[PageD_Seg],ax		; reset segment for page dir
	add	ax,P_SIZE/10h		; ax = segment page table
	mov	[PageT_Seg],ax		; rest it

	mov	ax,es			; get page dir seg again
	OP32
	shl	ax,4			; shl EAX,4 => EAX = 32 bit address
	OP32
	mov	[Page_Dir],ax		; store 32 bit addr of page dir
;
;  reset page directory entries
;
	mov	ax,word ptr [Page_Dir]	; DX,AX = 32 bit addr of Page Directory
	mov	dx,word ptr [Page_Dir+2]	; save it
;
;   get addr of Page Table for Page Directory entry
;
	add	ax,1000h		; add page
	adc	dx,0h			; carry it => DX,AX = addr of page table
;
;    DX,AX = addr of first page table
;
	xor	di,di			; ES:[DI] -> 1st entry in page dir
	mov	bh,0
	mov	bl,P_AVAIL		; make table available to all
	mov	cx,P_TABLE_CNT		; set entries in page table directory
					; for existing page tables.
IT_pdir:
	call	SetPageEntry		; set entry for first page table
;
;    ES:[DI] pts to next entry in page directory
	add	ax,1000h
	adc	dx,0			; DX,AX = addr of next page table
	loop	IT_pdir 		; set next entry in dir
;
;  reset PAGET_GSEL descriptor
;
	mov	ax,seg GDT			; GDT has not yet moved!!!
	mov	es,ax				; ES pts to GDT

	mov	ax,[PageT_Seg]			; segment for page tables
	call	SegTo24
	mov	cx,0				; enough room for tables
	mov	ah,D_DATA0
	mov	bx,PAGET_GSEL
	call	SetSegDesc			; set up page table descriptor
;
; now set CR3 in the TSS - to reflect new Page DIR position
;
	mov	ax,seg TSS		; TSS not moved yet !!!
	mov	es,ax			; ES -> TSS
	xor	di,di			; ES:DI -> TSS

	db	66h
	mov	ax,[Page_Dir]			; EAX = page dir 32 bit addr
	db	66h
	mov	word ptr ES:[di.TSS386_CR3],ax	; mov EAX into CR3 spot in TSS
;
;------------------------------------------------------------------------------
;  move _TEXT, GDT,IDT, & TSS up to high system memory
;	**** this code depends on the order of the _TEXT, GDT, IDT, & TSS
;		segments when linked.  They should be in the order
;		_TEXT, GDT, IDT, then TSS.
;------------------------------------------------------------------------------
;
	mov	ax,seg TSS		; compute # of paras from begin of _TEXT
	sub	ax,seg _TEXT		; to begin of TSS
	shl	ax,4			; convert it to bytes
	add	ax,TSSLEN		; and add in length of TSS
					; AX=length of _TEXT,GDT,IDT, & TSS segs
	add	ax,P_SIZE-1		; round up to nearest page boundary
	shr	ax,12			; AX = # of 4k pages for these tables
	mov	cx,ax			; CX=AX = # of pages for these tables
	call	HiSysAlloc		;Q: enough room in high sys mem ?
	jnc	IT_move_tables		;  Y: move page dir/tables to hi sys mem
	call	LockROM 		;  N: move nothing.  write protect ROM
	jmp	IT_Exit 		;
IT_move_tables:
	call	UnLockROM		; turn off write protect
	shl	ax,8			;  AX = # of paras already allocated
					;	in high memory
	add	ax,0E000h		;  AX = segment for sys mem block
	mov	es,ax			;  ES -> sys mem block
	xor	di,di			;  ES:DI -> sys mem block

	mov	ax,seg _TEXT		; start with _TEXT
	mov	ds,ax			; DS -> _TEXT
	xor	si,si			; DS:SI -> _TEXT
	shl	cx,10			; CX=# of dwords for _TEXT,GDT,IDT,&TSS
	cld
	OP32
	rep movsw			; mov _TEXT,GDT,IDT,&TSS into hi sys mem

;
;		now reset pointers to _TEXT, GDT, IDT, & TSS
	mov	ax,seg DGROUP
	mov	ds,ax			; DS = DATA

	mov	ax,es			; AX = segment for new _TEXT location
	mov	[TEXT_Seg],ax		; set new _TEXT segment

	mov	bx,seg GDT
	sub	bx,seg _TEXT		; bx = offset from _TEXT to GDT
	add	ax,bx			; (don't worry, won't cross Linear 64k)
	mov	[GDT_Seg],ax		; set new GDT segment

	mov	bx,seg IDT
	sub	bx,seg GDT		; bx = offset from GDT to IDT
	add	ax,bx			; (don't worry, won't cross Linear 64k)
	mov	[IDT_Seg],ax		; set new IDT segment

	mov	bx,seg TSS
	sub	bx,seg IDT		; bx = offset from IDT to TSS
	add	ax,bx			; (don't worry, won't cross Linear 64k)
	mov	[TSS_Seg],ax		; set new TSS segment
;
;  reset descriptors for _TEXT, GDT, IDT, & TSS
;
	mov	ax,[GDT_Seg]			; GDT has MOVED !!!
	mov	es,ax				; ES pts to GDT

	mov	ax,[TEXT_Seg]			; _TEXT segment
	call	SegTo24
	mov	cx,0
	mov	ah,D_CODE0
	mov	bx,VDMC_GSEL
	call	SetSegDesc		; Set up VDM code descriptor - VDMC

	mov	ax,[TEXT_Seg]			; _TEXT segment
	call	SegTo24
	mov	cx,0
	mov	ah,D_DATA0
	mov	bx,VDMCA_GSEL
	call	SetSegDesc		; Set up VDM code alias descriptor

	mov	ax,[GDT_Seg]			; GDT segment
	call	SegTo24
	mov	cx,GDTLEN
	mov	ah,D_DATA0
	mov	bx,GDTD_GSEL
	call	SetSegDesc		; Set up GDT alias descriptor

	mov	ax,[IDT_Seg]			; IDT segment
	call	SegTo24
	mov	cx,IDTLEN
	mov	ah,D_DATA0
	mov	bx,IDTD_GSEL
	call	SetSegDesc		; Set up IDT alias descriptor

	mov	ax,[TSS_Seg]			; segment of TSS
	call	SegTo24
	mov	cx,TSSLEN
	mov	ah,D_386TSS0
	mov	bx,TSS_GSEL
	call	SetSegDesc		; Set up TSS descriptor

	mov	ah,D_DATA0
	mov	bx,TSSD_GSEL
	call	SetSegDesc		; Set up TSS alias descriptor

;
; fixup new RING 0 stack location
;
	mov	ax,[_emm_brk]		; get EMM break address
	add	ax,15			; round up to next paragraph
	shr	ax,4
	add	ax,seg _DATA		; AX = new seg address for STACK
	mov	[STACK_seg],ax		; save it

	call	SegTo24
	mov	cx,offset STACK0_SIZE	; length of stack
	mov	ah,D_DATA0
	mov	bx,VDMS_GSEL
	call	SetSegDesc		; Set up STACK segment GDT entry

;
; fixup far call / far jump references to _TEXT
;

;	   far call pointers in ELIM function table
	mov	ax,seg R_CODE
	mov	es,ax				; ES -> R_CODE
	mov	di,offset R_CODE:EFunTab+2	; ES:DI -> 1st seg in func tab
	mov	cx,EFUN_CNT			; CX = # of dword entries
	mov	ax,[TEXT_Seg]
IT_Tloop:
	stosw					; store new TEXT seg
	inc	di
	inc	di				; point to next seg in table
	loop	IT_Tloop

;	   ELIM_rEntry far call
	mov	di,offset R_CODE:EMM_rEfix	; point to far call
	mov	ES:[di+3],ax			; set seg portion of call

;	   Far jump in return to real code
	mov	es,ax				; ES -> new TEXT seg
	mov	di,offset _TEXT:Real_Seg	; ES:DI -> seg of far jmp
	mov	ES:[di],ax			; fix it

;
;   reset break address for driver - throw away _TEXT seg and all after it
;
	mov	word ptr [driver_end],10h	; just in case
	mov	ax,[STACK_Seg]			; begin of new stack location
	add	ax,STACK0_SIZE/10h		; add in size of stack
	mov	word ptr [driver_end+2],ax	; set break seg to end of stack

;
;  OK, now lock high system RAM
;
	call	LockROM
;
IT_exit:
	popf
	clc				; No error in memory allocation attempt
IT_quit:
	pop	es
	pop	ds
	pop	di
	POP_EAX
else

	push	es
	push	di
	push	eax
	push	dx
	push	cx
	push	bx
;
; try to move the pageseg up
;
    ;
    ; segment to be moved up
    ;
	mov	ax, [PageD_Seg]
	mov	es,ax
    ;
    ; its length
    ;
	mov	ax,seg LAST
	sub	ax,seg PAGESEG
	shl	ax,4
	mov	cx,ax
    ;
    ; we need to allocate enough to have a page aligned page directory. so
    ; increase this by 4k
	push	cx
	add	cx,4*1024
    ;
    ; allocate a block of memory for this

	call	get_buffer
	pop	cx
	jc	no_mem
    ;
    ; dx:ax is new address of page directory, adjust this to be page aligned
    ;
	add	ax,4*1024
	adc	dx,0
	and	ax,0F000h
    ;
	push	ax
	push	dx
	push	cx
    ;
	add	ax,1000h
	adc	dx,0h
    ;
    ; set the entries in the page directory for these
    ;
	xor	di,di		    ; es:di points to first page_dir entry
	mov	bh,0
	mov	bl, P_AVAIL
	mov	cx,P_TABLE_CNT
set_entries:
	call	SetPageEntry
    ;
    ; es:di points to next entry in page directory
    ;
	add	ax,1000h
	adc	dx,0		    ; next page table
	loop	set_entries
    ;
    ; now we can move the page directory and tables up into extended
    ;
	pop	cx
	pop	dx
	pop	ax
    ;
	xor	di,di		    ; es:di is now the beginning, cx count of
				    ; number of bytes in segment and dx:ax area
				    ; where it is to be moved
	call	moveb		    ; move the data
	jnz	move_error	    ; there was an error in moving. the page
				    ; table entries need to be restored to the
				    ; lo memory stuff
    ;
    ; move succeded, fix page directory address and driver_end
    ;
	mov	word ptr [Page_Dir],ax	; DX,AX = 32 bit addr of Page Directory
	mov	word ptr [Page_Dir+2],dx	; save it
;
;  reset PAGET_GSEL descriptor
;
	mov	cx,seg GDT			; GDT has not yet moved!!!
	mov	es,cx				; ES pts to GDT

	add	ax,1000h
	adc	dx,0
	xchg	ax,dx				; for setsegdesc in opposite
						; al:dx

	mov	cx,0				; enough room for tables
	mov	ah,D_DATA0
	mov	bx,PAGET_GSEL
	call	SetSegDesc			; set up page table descriptor
    ;
    ; if we succeed in shifting the page tables up the ground is clear for us
    ; to shrink the driver even more to the point where the variable emm data
    ; structures end.
    ;
	mov	ax,[_emm_brk]		; get EMM break address
	add	ax,15			; round up to next paragraph
	shr	ax,4
	add	ax,seg DGROUP		; AX = end address for driver
	mov	word ptr [driver_end],10h   ; just in case, para offset
	mov	word ptr [driver_end+2],ax  ; segment


no_mem:
	pop	bx
	pop	cx
	pop	dx
	pop	eax
	pop	di
	pop	es
	clc
	jmp	end_inittab

move_error:
    ;	the address of page table in lo mem
    ;
	mov	ax,[PageT_Seg]
	mov	cx,4
	xor	dx,dx
	mul	cx
    ;
    ; set the entries in the page directory for these
    ;
	xor	di,di		    ; es:di points to first page_dir entry
	mov	bh,0
	mov	bl, P_AVAIL
	mov	cx,P_TABLE_CNT
restore_entries:
	call	SetPageEntry
    ;
    ; es:di points to next entry in page directory
    ;
	add	ax,1000h
	adc	dx,0		    ; next page table
	loop	restore_entries
    ;
	jmp	no_mem
endif
end_inittab:
	ret
;
InitTab endp
;
LAST	ends				; end of segment
;
	end				; end of module
