

	page 58,132
;******************************************************************************
	TITLE	PPAGE - MODULE to find mappable Physical pages
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:	PPAGE - Find Mappable Physical Pages
;
;   Version:	0.01
;
;   Date:	Aug 1, 1988
;
;   Author:	ISP
;		COMMENTS** This routine needs extensive work to do a better
;			   job of identification of unmappable segments. That
;			   is why we seem to have a whole lot of procedures
;			   which don't do much now.
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;******************************************************************************
;   Functional Description:
;   This module initialises the mappable physical pages in memory.
;   It also finds a valid page frame for use.
;
;******************************************************************************
.lfcond
.386p

	page
;******************************************************************************
;		P U B L I C   D E C L A R A T I O N S
;******************************************************************************

	public	mappable_segs
	public	Map_tbl
	public	max_PF
	public	find_phys_pages
	public	exclude_segments
	public	is_page_mappable

	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
FIRST_SYSTEM_ROM_SEG_HI =  0F000h
FIRST_SYSTEM_ROM_SEG_LO =  0E000h
LAST_SYSTEM_ROM_SEG	=  0FFFFh
;
FIRST_VIDEO_MEM_SEG	=  0A000h
LAST_VIDEO_MEM_SEG	=  0BFFFh
;
FIRST_CONV_UMAP_SEG	=  00000h
LAST_CONV_UMAP_SEG	=  03FFFh


;******************************************************************************
;			INCLUDE FILES
;******************************************************************************
    include  vdmseg.inc     ; segment definitions
    include  emm386.inc     ;contains the error messages
    include  emmdef.inc     ;contains some emm defines

	page
;******************************************************************************
;			E X T E R N A L    R E F E R E N C E S
;******************************************************************************
;
;
_DATA	segment

	extrn	PF_Base:word
	extrn	msg_flag:word

_DATA	ends

;
LAST	segment
;
	extrn	rom_srch:near
;
LAST	ends

	page
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************


;******************************************************************************
;
;	Code Segments
;
;******************************************************************************
;
_TEXT	segment
_TEXT	ends

LAST	segment
	assume	cs:LAST, ds:DGROUP, es:DGROUP

	page
;*************************************************************************
;
; initialisation data
;
;*************************************************************************
;	table for identifying mappable pages
;
mappable_segs	label	byte
		db	TOT_PHYS_PAGES dup(PAGE_MAPPABLE)  ;
;
;	table for PF base addresses
;
Map_tbl 	label	word
		dw	0c000h
		dw	0c400h
		dw	0c800h
		dw	0cc00h
		dw	0d000h
		dw	0d400h
		dw	0d800h
		dw	0dc00h
max_PF		equ	(this byte - Map_tbl)
		dw	0e000h

	page
;******************************************************************************
;	find_phys_pages: routine to find mappable phsyical pages and a page fr
;
;	ENTRY: PF_base set to -1 (user didn't specify apge frame)
;			   or offset into Map_tbl
;	EXIT:  mappable_segs array initalised to indicate mappable pages
;	       first_system_page initialised
;	       num_system_pages initialised
;	       PF_Base initalised to page frame
;	       [msg_flag] set if error to error message number
;	USED: none
;
;******************************************************************************
find_phys_pages proc	near
;
; start out with all the pages initialised to be mappable except those excluded
; by explicit instruction of the command line.
;

;
; exclude segments in the lo end of system memory
;
	call	exclude_conv_RAM

; exclude segments in the system ROM area
;
	call	exclude_system_ROM

;
; exclude segments in the video area
;
	call	exclude_video_mem

;
; then search for option rom's in the area C000 to E000 and exclude the
; segments in which option rom exists.
;
	call	rom_srch		; this searches for option rom's and
					; removes the segments of these from
					; being mappable
;
; then find the page frame from the information of mappable segs from C000-E000
; and the user specified page frame (if any).
;
	call	find_pf_base
;
; and then exit
;
	ret
;
find_phys_pages endp

    page
;******************************************************************************
;   find_pf_base: routine to find a valid page frame
;
;	ENTRY: PF_base set to -1 (user didn't specify apge frame)
;			   or index into Map_tbl
;	       ax = index into Map_tbl from rom_srch on a possible pageframe.
;
;	EXIT:  PF_base set to page frame segment (C000..E000) on no error
;	       If error msg_flag set to appropriate error message
;
;	USES:  NONE
;
;******************************************************************************
find_pf_base	proc	near
;
	push	ax
	push	bx
	push	cx
	push	si
;
; we have to examine all the possible page frames by looking at the entries
; for the page frame in the mappable_segs array and find all possible page
; frames.  the first such valid page frame found is remembered
;

    ;
    ; initialise
    ;
	mov	ax,0ffffh	    ; first possible page frame
	xor	bx,bx		    ; index into map_tbl
    ;
    ; outer loop entry. check for loop termination
    ;
examine_map_tbl_loop:
    ;
	cmp	bx,MAX_PF	    ; are we done
	ja	choose_PF	    ; yes, go to choose page frame
    ;
    ; get the page frame segment. convert to phys. page #
    ;
	mov	si,cs:Map_Tbl[bx]   ;
	shr	si,10
    ;
    ; examine the entries for the 4 pages comprising this segment
    ;
	mov	cx,4
check_pages_loop:
	cmp	cs:mappable_segs[si],PAGE_MAPPABLE
	jne	invalidate_PF
	inc	si
	loop	check_pages_loop

    ;***SUCCESS

    ;
    ; exit point. pf is valid.	see if we already have a pf. if not we store
    ; this.
    ;
	cmp	ax,0ffffh	    ; do we have a pf already?
	jne	skip_get_PF	    ; skip if we do
	mov	ax,bx		    ; else store
skip_get_PF:
    ;
    ; go to examine next PF
    ;
	jmp	next_PF

    ;***FAILURE

    ;
    ; exit point. pf is invalid. remove it from map_tbl
    ;
invalidate_PF:
	mov	cs:Map_Tbl[bx],0ffffh	;
    ;
    ;***SETUP TO LOOP AGAIN
next_PF:
    ;
	add	bx,2
	jmp	examine_map_tbl_loop
;
choose_PF:
;
; Choosing a page frame.  If the user has specified a page frame then
; validate it else give him the page frame we found first.
;
    ;
    ; has the user specified a pf. if so go to validate it
    ;
	cmp	[PF_Base],0ffffh	;
	jne	def_cont2
    ;
    ; user didn't specify a pf. did we find a pf. if so give it else indicate
    ; error
    ;
	cmp	ax,0ffffh		; did we find one
	je	no_PF_warn		; if not go to warn the user
	mov	bx,ax
	mov	ax, cs:Map_Tbl[bx]	; get the PF
	mov	[PF_Base],ax		;
	or	[msg_flag],BASE_ADJ_MSG ;
	jmp	pf_xit

    ;
    ; we don't have a pf. warn the user
    ;
no_PF_warn:
	or	[msg_flag],NO_PF_MSG
	jmp	pf_xit
;
; they specified a base address. Let's make sure it's good
;
def_cont2:
	mov	bx,[PF_Base]		; get the offset they specified
	mov	ax,bx			; ax = bx
	shr	ax,1			; back to 0..8
	mov	cx,0400h		; length of PF segments
	mul	cx			; addr = 0c000h + (Mx-1)*400h
	add	ax,0c000h
	mov	[PF_Base],ax		; save it

	cmp	cs:Map_tbl[bx],0ffffh	; Is this any good?
	jne	pf_xit			; probably
	or	[msg_flag],PF_WARN_MSG	; probably not
;
; we need to ensure that the pages corresponding to the page frame are forced
; into being mappable. this is necessary because we accept the user's discretio
; in forcing a page frame in a certain area.
;
	mov	si,ax			; segment
	shr	si,10			; phys page#
	mov	cx,4
force_PF_pages:
	mov	cs:mappable_segs[si],PAGE_MAPPABLE
	inc	si
	loop	force_PF_pages

pf_xit:
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret

find_pf_base	endp


;***********************************************************************;
; exclude_video_mem							;
;									;
; Excludes the segments between A000 and C000.				;
;									;
; input: none								;
;									;
; returns: none 							;
;									;
; uses: 								;
;									;
; calls:exclude_segments						;
;									;
; History:                                                              ;
;	ISP (isp). Wrote it.				;
;***********************************************************************;
exclude_video_mem   proc    near
;
    push    bx
    push    ax
;
    mov     bx,FIRST_VIDEO_MEM_SEG
    mov     ax,LAST_VIDEO_MEM_SEG
    call    exclude_segments
;
    pop     ax
    pop     bx
    ret
;
exclude_video_mem   endp

;***********************************************************************;
; exclude_system_ROM							;
;									;
; Excludes the segments between A000 and C000.				;
;									;
; input: none								;
;									;
; returns: none 							;
;									;
; uses: 								;
;									;
; calls:exclude_segments						;
;									;
; History:                                                              ;
;	ISP (isp). Wrote it.				;
;***********************************************************************;
exclude_system_ROM  proc    near
;
    push    bx
    push    ax
;
ifndef	NOHIMEM
    mov     bx,FIRST_SYSTEM_ROM_SEG_LO
else
    mov     bx,FIRST_SYSTEM_ROM_SEG_HI
endif

    mov     ax,LAST_SYSTEM_ROM_SEG
    call    exclude_segments
;
    pop     ax
    pop     bx
    ret
;
exclude_system_ROM  endp

;***********************************************************************;
; exclude_conv_RAM							;
;									;
; Excludes segments between 0000 and 4000h				;
;									;
; inputs:none								;
;									;
; returns: none 							;
;									;
; History:								;
;	ISP (isp).  Wrote it
;***********************************************************************;
exclude_conv_RAM    proc    near
;
    push    bx
    push    ax
;
    mov     bx,FIRST_CONV_UMAP_SEG
    mov     ax,LAST_CONV_UMAP_SEG
    call    exclude_segments
;
    pop     ax
    pop     bx
    ret
;
exclude_conv_RAM    endp

;-----------------------------------------------------------------------;
; exclude_segments                                                      ;
;                                                                       ;
; Excludes the given segments from the memory map.			;
; 									;
; Arguments:                                                            ;
; 	AX = high segment						;
; 	BX = low segment						;
; Returns:                                                              ;
; 	nothing								;
; Alters:                                                               ;
;	AX,BX								;
; Calls:                                                                ;
; 	nothing								;
; History:                                                              ;
;	ISP (isp). modified from ps2emm sources. 	;
;-----------------------------------------------------------------------;
exclude_segments	proc	near
;
	push	cx
	push	es
	push	di
;
; fix the segments to form physical page numbers
;
	mov	cl,10		; to convert segment to physical page #
	shr	ax,cl
	shr	bx,cl
	sub	ax,bx
	jb	exclude_segments_done
	inc	ax
	mov	cx,ax
;
; get addressing into mappable_segs array
;
	push	cs
	pop	es
	assume	es:nothing
	lea	di, mappable_segs[bx]
	mov	al,PAGE_NOT_MAPPABLE
	cld
	rep	stosb
exclude_segments_done:
;
	pop	di
	pop	es
	pop	cx
	ret
;
exclude_segments	endp

;-----------------------------------------------------------------------;
; is_page_mappable							;
;                                                                       ;
; specifies whether a given physical page is mappable or not.		;
; 									;
; Arguments:                                                            ;
;	si = physical page						;
; Returns:                                                              ;
;	ZF set if mappable						;
;	ZF clear if not mappable					;
; Alters:                                                               ;
;	flags								;
; Calls:                                                                ;
; 	nothing								;
; History:                                                              ;
;	ISP (isp). 8/29/88				;
;-----------------------------------------------------------------------;
is_page_mappable    proc    near
;
	cmp	cs:mappable_segs[si],PAGE_MAPPABLE
	ret
;
is_page_mappable    endp

LAST	ends				; End of segment
;

	end				; End of module

