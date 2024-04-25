

;
	page	58,132
;******************************************************************************
	title	ROM_SRCH - search for option ROMs
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;  Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;  Module:	ROM_SRCH - search for option ROMS and RAM
;
;  Version:	0.04
;
;  Date	:	June 5,1986
;
;  Authors:	SP, BT
;
;******************************************************************************
;
;  CHANGES:
;
;    DATE     REVISION			DESCRIPTION
;  --------   --------   ------------------------------------------------------
;  06/05/86   Original   Adapted from ROM code
;  06/25/86   0.02	 Fixed upd_map.
;  06/26/86   0.02	 Fixed upd_map (again) and ram_srch
;  06/28/86   0.02	 Name changed from MEMM386 to MEMM
;  07/06/86   0.04	 changed assume to DGROUP
;  08/01/88		 Updated to identify mappable segs between C000 and E000
;
;******************************************************************************
	page
;******************************************************************************
;
;  Functional description:
;
;	This module contains the code that scans the ROM at the segment
;	supplied in register AX looking for ROMs on hardware interface
;	boards.  The layout of each valid ROM is as follows:
;
;	 OFFSET	+-----------------------+
;	    0	|	   55h		|
;		+-----------------------+
;	    1	|	   AAh		|
;		+-----------------------+
;	    2	|    ROM size / 512	|
;		+-----------------------+
;	    3	|  Start of init code	|
;			    :
;	   n-1	|			|
;		+-----------------------+
;		(Sum of all bytes MOD 100h is 00h.)
;
;	This module also contains the code to search and vector to VDU
;	roms (C000:0 to C000:7800 in 2K increments).
;
;******************************************************************************
	page
.386P
;
;******************************************************************************
;  	Public Declarations
;******************************************************************************
;
	public	rom_srch		; Search and Vector to option ROMs.
;******************************************************************************
;  	Externs
;******************************************************************************
LAST	segment
	extrn	Map_tbl:word
	extrn	max_PF:abs
	extrn	mappable_segs:byte
	extrn	exclude_segments:near

LAST	ends
;
;******************************************************************************
;  	Equates
;******************************************************************************
;					   
FIRST_ROM	=	0C800H		; Segment address of first option ROM.
LAST_ROM	=	0EF80H		; Segment address of last option ROM.
FIRST_VDU_ROM	=	0C000H		; Seg address of first VDU option ROM.
LAST_VDU_ROM	=	0C780H		; Seg address of last VDU option ROM.
FIRST_RAM	=	0C000H		; Seg address of 1st possible RAM addr
LAST_RAM	=	0EF80H		; Seg addr of last possible RAM addr
NOT_FOUND_INCR  =	0800H		; Amount to skip if no ROM found.
;
	include emmdef.inc
	include	vdmseg.inc
	include	romstruc.equ		; Option ROM structure.
PF_LENGTH	equ	0400h		; length of a page frame (*16)
;
;******************************************************************************
;		S E G M E N T S
;******************************************************************************
LAST	segment
	ASSUME	CS:LAST, DS:DGROUP
;
	page
;******************************************************************************
;
;	ROM_SRCH - Search for option ROMs.
;
;	This section of code searches the auxiliary rom area (from C8000 up 
;	to E0000) in 2K increments. A ROM checksum is calculated to insure
;	that the ROMs are valid.  Valid ROMs must have the 1st byte = 55H 
;	and the next byte = 0AAH.  The next byte indicates the size of the
;       ROM in 512-byte	blocks.  The sum of all bytes in the ROM, modulo 256,
;       must be zero.
;
;	If a ROM is not found at a location, the next location 2K-bytes down
;	is examined.  However, if it is found, the next location after this
;	ROM is tried.  The next ROM location is determine according to the
;	size of the previous ROM.
;
;
;******************************************************************************
rom_srch	proc	near		; Entry point.
	push	bx
;
; search for option ROMs
;
	mov	ax,FIRST_ROM		; Segment address of first option ROM.
	cld				; Set direction flag.
nxt_opt:
	call	opt_rom			; Look for option ROM.
	jnc	not_fnd1		; No ROM here
	call	upd_seg
not_fnd1:
	cmp	ax,LAST_ROM		;Q: All ROMs looked at ?
	jbe	nxt_opt			; No, keep looking
					; Y: check for VDU roms
;
; search for VDM ROMs
;
	mov	ax,FIRST_VDU_ROM	; segment addr for first vdu ROM
	cld
nxt_vdu:
	call	opt_rom			; Q:is it there
	jnc	not_fnd2		; No ROM here
	call	upd_seg
not_fnd2:
	cmp	ax,LAST_VDU_ROM		;Q: last VDU ROM ?
	jbe	nxt_vdu			;  N: continue
					;  Y: check for RAM
;
; search for RAM
;
	mov	ax,FIRST_RAM		; first seg addr for RAM search
	cld
nxt_ram:
 	call	ram_srch		;Q: RAM here ?
	jnc	not_fndr		;  N: check again ?
	call	upd_seg
not_fndr:
	cmp	ax,LAST_RAM		;Q: last RAM location
	jbe	nxt_ram			;  N: continue searching
					;  Y: all done
;
	pop	bx
	ret	
rom_srch endp
	page
;
;******************************************************************************
;	OPT_ROM - This routine looks at the ROM located at the segment address
;		    specified in AX to see if 0TH and 1ST Bytes = 0AA55H.
;		    If so, it calculates the checksum over the length of
;		    ROM.  If the checksum is valid it updates AX to point
;		    to the location of the next ROM.
;
;	 Inputs:  AX = Segment address of ROM.
;
;	 Outputs: CY = Found a VDU ROM at this location.
;		  NC = Did not find a valid ROM at this location.
;		  AX = Segment address of next ROM location. 
;		  DX = Length of this ROM
;
;******************************************************************************
;
opt_rom	proc near	      
	push	bx
	push	cx
	push	si
	push	ds
;
	mov	ds,ax			; DS=ROM segment address.
	xor	bx,bx			; Index uses less code than absolute.
	cmp	[bx.ROM_RECOGNITION],0AA55H ;Q: Looks like a ROM?
	jne	rs_3			;  No, Skip down
;
;	Compute checksum over ROM.
;
	xor	si,si			; DS:SI=ROM Pointer; Start at beg.
	xor	cx,cx			; Prepare to accept byte into word.
	mov	ch,[bx.ROM_LEN]		; CH=byte count/512 (CX=byte count/2)
	shl	cx,1			; CX=adjusted byte count.
	mov	dx,cx			; Extract size.
rs_2:
	lodsb				; MOV  AL,DS:[SI+];  Pickup next byte.
	add	bl,al			; Checksum += byte(SEG:offset)
	loop	rs_2			; Loop doesn't affect flags.
	jnz	rs_3			; Jump down if bad checksum.
;
	mov	cl,4			; Shift of 4...
	shr	dx,cl			; Converts bytes to paragraphs (D.03)
	mov	ax,ds			; Replace segment in AX.
	add	ax,dx			; increment segment by this amount
	stc				; rom found
	jmp	short rs_exit		; Continue.
;
rs_3:								
	mov	dx,(NOT_FOUND_INCR shr 4) ; Prepare for next ROM.
	mov	ax,ds			; Replace segment in AX.
	add	ax,dx			; Increment segment.
	clc				; no rom found
;
rs_exit:
	pop	ds
	pop	si
	pop	cx
	pop	bx
	ret				; *** RETURN ***
;
opt_rom	endp
	page
;
;******************************************************************************
;	RAM_SRCH - This routine looks at the address range potentially used    
;		    by the Page Frame to determine if any RAM is in the way.
;		    It updates the map accordingly.
;
;	 Inputs:  AX = Segment address for RAM search.
;
;	 Outputs: CY = Found RAM at this location.
;		  NC = Did not find RAM at this location.
;		  AX = Segment address of next RAM location. 
;		  DX = Length of this RAM
;
;******************************************************************************
;
ram_srch	proc	near

	push	bx
	push	ds
;
;  search for RAM
;
	xor	dx,dx					; length = 0
ram_loop:
	mov	ds,ax
	add	ax,(NOT_FOUND_INCR shr 4);     prepare for next chunk
	mov	bx,ds:0			; get a word
	xor	ds:0,0FFFFh		; flip all bits
	xor	bx,0FFFFh		; BX = "flipped" value
	cmp	bx,ds:0			;Q: "flipped" value written out ?
	jne	no_more_ram		;  N: not RAM - leave
	xor	ds:0,0FFFFh		;  Y: is ram, flip bits back
	add	dx,(NOT_FOUND_INCR shr 4);     increment length count
	cmp	ax,LAST_RAM		;Q: last RAM location ?
	jbe	ram_loop		;  N: continue searching
	mov	ds,ax			;  Y: no more searching
no_more_ram:
;
	mov	ax,ds			;  get current segment
	or	dx,dx			;Q: any RAM found ?
	jnz	ram_found		;  Y: set RAM found & chk DS seg again
	clc				;  N: set no RAM
	add	ax,(NOT_FOUND_INCR shr 4) ; AX -> next one to check
	jmp	short ram_exit		;     and leave
;
ram_found:
	stc
ram_exit:
	pop	ds
	pop	bx
;
	ret
ram_srch	endp
	page
;

;******************************************************************************
;	UPD_SEG - This routine looks at the address range used by the ROM/RAM
;		    that was found to determine how many potential physical
;		    pages are invalidated from being mappable.	It updates
;		    the mappable_segs array appropriately.
;
;	 Inputs:  AX = Segment address of next ROM/RAM position.
;		  DX = Length of ROM/RAM
;
;	 Outputs: [mappable_segs] updated.
;
;	 Written: 8/1/88 ISP
;	 Modif:   8/25/88 ISP to make use of exclude_segments
;******************************************************************************
upd_seg proc	near
;
	push	bx
	push	ax
;
	mov	bx,ax
	sub	bx,dx		; bx now has the first segment of the area
	dec	ax		; and ax has the last segment of the area
;
	call	exclude_segments
;
	pop	ax
	pop	bx
	ret
upd_seg endp
LAST	ENDS
	END
