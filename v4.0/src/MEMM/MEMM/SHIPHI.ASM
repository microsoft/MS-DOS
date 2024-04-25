

	page 58,132
;******************************************************************************
	TITLE	SHIPHI -  MODULE to ship a segment up hi
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:	SHIPHI - Ship a segment up hi into extended memory
;
;   Version:	0.01
;
;   Date:	Sep 1, 1988
;
;   Author:	ISP
;
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;******************************************************************************
;   Functional Description:
;
;   We need to ship data structures up hi.
;   This file has routines to specify size requirements for this operation
;   and to shift a segment up hi.  Remember that in shipping a segment up hi
;   the GDT segment should be the last to be sent up since it is modified while
;   shipping a segment up hi
;
;******************************************************************************
.lfcond
.386p

	page
;******************************************************************************
;		P U B L I C   D E C L A R A T I O N S
;******************************************************************************
	public	set_src_selector	; Routines and data(GDT) for move block
	public	set_dest_selector
	public	moveb
	public	memreq

	public	gdt_mb


	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;

;******************************************************************************
;			INCLUDE FILES
;******************************************************************************
    include  vdmseg.inc     ; segment definitions
    include  desc.inc	    ;
    include  page.inc

	page
;******************************************************************************
;			E X T E R N A L    R E F E R E N C E S
;******************************************************************************
;
;
LAST	SEGMENT
	extrn	    get_buffer:near
LAST	ENDS

	page
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************

;*************************************************************************
;
; DATA
;
;*************************************************************************

_DATA	SEGMENT
	ASSUME	CS:DGROUP,DS:DGROUP
;
_DATA	ENDS




LAST   SEGMENT
ASSUME	CS:LAST,DS:DGROUP,ES:DGROUP

;  GDT for ROM Move Block calls
;
gdt_mb	label	word
;
gdt0_mb:	GDT_ENTRY 0,0,1,0		; Dummy   seg descriptor
gdt1_mb:	GDT_ENTRY 0,0,1,0		; GDT	  seg descriptor
gdt2_mb:	GDT_ENTRY 0,0,0,D_DATA3 	; Src	  seg descriptor
gdt3_mb:	GDT_ENTRY 0,0,0,D_DATA3 	; Dest	  seg descriptor
gdt4_mb:	GDT_ENTRY 0,0,1,0		; Bios cs seg descriptor
gdt5_mb:	GDT_ENTRY 0,0,1,0		; Bios ss seg descriptor
;

LAST   ENDS

;*************************************************************************
;
; CODE
;
;*************************************************************************
LAST   SEGMENT
ASSUME	CS:LAST,DS:DGROUP,ES:DGROUP

;******************************************************************************
;   SHIPHI - routine to ship a segment up hi				      ;
;									      ;
;   INPUTS:  es = segment to be moved up				      ;
;	     cx = number of bytes in the segment			      ;
;									      ;
;   OUTPUTS: dx:ax = new address of the segment 			      ;
;	     Z set if succeeded, NZ if error				      ;
;									      ;
;   USES:    ax,dx,flags						      ;
;									      ;
;   CALLS:								      ;
;									      ;
;   AUTHOR:  ISP (ISP) Sep 2, 1988			      ;
;									      ;
;*****************************************************************************;
SHIPHI	    proc    near
    ;
	push	di
    ;
    ; first get some memory to play with
    ;
	call	get_buffer
    ;
    ; then move the segment up to this new segment
    ;
	xor	dh,dh		; dx:ax 32 bit addr of dest
	xor	di,di		; es:di is source segment
	call	moveb
    ;
	pop	di
    ;
	ret
SHIPHI	    endp



;*****************************************************************************;
;*** MOVEB ***								      ;
;									      ;
;   Move data between from conventional memory to extended memory	      ;
;									      ;
;									      ;
;   INPUTS:    dl:ax = 24 bit address of extended memory address	      ;
;	       es:di = source address in lo memory
;	       cx    = number of bytes to transfer
;									      ;
;   OUTPUTS:	Z set if succeeded					      ;
;		NZ if error						      ;
;									      ;
;   USES:								      ;
;									      ;
;   AUTHOR: ISP, Sep 2,1988.						      ;
;									      ;
;*****************************************************************************;


MOVEB	proc	near
	push	es
	push	dx
	push	ax
	push	di
	push	cx


    ;
    ; no setup needed for dest selector, already set up.
    ;
	call	set_dest_selector	; destination is unlock address
    ;
    ; for source selector we need to convert segment:offset to dl:ax
    ; cx is already # of words
    ;
	xor	dx,dx
	mov	ax,es
	mov	bx,16
	mul	bx
	add	ax,di
	adc	dx,0

	call	set_src_selector	; set source segment selector to buffer
    ;
    ; do the block move
    ;
	mov	si,seg LAST
	mov	es,si
	mov	si,offset LAST:gdt_mb ; ES:SI -> global descriptor table
    ;
    ; convert count to number of words
    ;
	inc	cx
	shr	cx,1
;
    ;
	mov	ah,87h			; int 15 block move function code
	int	15h			; unlock rom
	or	ah,ah			; Q: error?
					;   Y: return NZ
	pop	cx
	pop	di
	pop	ax
	pop	dx
	pop	es
					;   N: return Z
	ret
MOVEB	endp

	page
;******************************************************************************
;
;	set_src_selector
;			Set base address, limit of source segment selector
;			in gdt_mb for int 15h block move
;
;
;			entry:	dl:ax == source address (24 bits)
;				cx    == size, in words
;
;			exit:	gdt_mb(2) contains source base address, limit
;
;			used:	none
;
;******************************************************************************
;
set_src_selector	proc	near
;
	push	di
	mov	di,offset LAST:gdt2_mb ; cs:di -> source seg descriptor
set_entry:
	mov	cs:[di.BASE_LOW],ax	   ; Store base address bits 15:00
	mov	cs:[di.BASE_HIGH],dl	   ; Store base address bits 23:16
	mov	cs:[di.LIMIT],cx	   ; Store size
	sub	cs:[di.LIMIT],1 	   ; subtract 1 => convert to limit
;
	pop	di
	ret				; *** Return ***
;
set_src_selector	endp		; End of procedure
;
	page
;******************************************************************************
;
;	set_dest_selector
;			Set base address, limit of destination segment selector
;			in gdt_mb for int 15h block move
;
;			entry:	dx:ax ==  address (32 bits)
;				cx    == size of segment, in words
;				ds = DGROUP
;
;			exit:	gdt_mb(3) contains destination base address,
;				limit
;
;			used:	none
;
;******************************************************************************
;
set_dest_selector	proc	near
;
	push	di
	mov	di,offset LAST:gdt3_mb	; cs:di -> source seg descriptor
	mov	cs:[di.BASE_XHI],dh	; bits 24-31
	jmp	set_entry		; set this entry in gdt_mb
;
	ret				; *** Return ***
;
set_dest_selector	endp		; End of procedure







;******************************************************************************
;   MEMREQ - routine to determine memory requirements for shifting the driver ;
;	     up into extended memory					      ;
;									      ;
;   INPUTS:  none							      ;
;									      ;
;   OUTPUTS: CX = size requirements in K				      ;
;									      ;
;   USES:    CX, flags							      ;
;									      ;
;   AUTHOR:  ISP (ISP) Sep 2, 1988			      ;
;									      ;
;*****************************************************************************;
MEMREQ	    proc    near
;
	push	ax
;
	mov	ax,seg LAST		    ; this is the last segment and
					    ; one which is discarded.
	sub	ax,seg PAGESEG		    ; this is the first segment of the
					    ; region which is to be moved.

	add	ax, (P_SIZE/16 -1)	     ; to round it up to next page bdry
	shr	ax, 6			    ; find the size in K
	add	ax,16			    ; throw in 4 more pages for safety
	mov	cx,ax			    ; and return the size needed
;
	pop	ax
	ret
MEMREQ	    endp

LAST   ENDS

	end
