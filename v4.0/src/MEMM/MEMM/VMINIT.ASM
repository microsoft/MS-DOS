

page	58,132
;******************************************************************************
	title	VMINIT.ASM - Initialization routines for VM-DOS
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   VMINIT - Initialization routines for MEMM/ VDM
;
;   Version:  0.04
;
;   Date:     January 30, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   01/30/86  Original
;   04/07/86  A 	Added InitBitMap
;   05/12/86  B 	Cleanup and segment reorganization
;   06/18/86  0.01	Re-arranged comments, etc.
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   07/03/86  0.03	Added call to Kybd_Watch
;   07/06/86  0.04	changed assume to DGROUP
;   07/30/86  0.06	removed PortClear reference
;
;******************************************************************************
;
;   Functional Description:
;
;   This module contains various initialization routines for Virtual DOS
;
;******************************************************************************
.386p
.lfcond 				; list false conditionals
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	vminit			; module label
	public	InitBitMap		; init I/O Bit Map
	public	PortTrap		; set bit(s) in I/O Bit Map
ifdef	oldstuff
	public	PortClear		; clear bit(s) in I/O Bit Map
endif
	public	BitOFF			; bit offset calculation
	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
	include VDMseg.inc
	include VDMsel.inc
	include desc.inc
	include elim.inc
FALSE	equ	0
TRUE	equ	not FALSE

	page
;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************
;
ABS0	segment at 0000h
ABS0	ends

TSS	segment

	extrn	IOBitMap:byte		; Bit Map in Tss

TSS	ends


_TEXT	segment

	extrn	A20_Trap_Init:near	; (a20trap.asm)
	extrn	RR_Trap_Init:near	; (RRtrap.asm)
	extrn	OEM_Trap_Init:near	; (OEMProc.asm)

_TEXT	ends
;
;
;******************************************************************************
;			L O C A L   D A T A   A R E A
;******************************************************************************
;
_DATA	segment
;
_DATA	ends

;
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************
;
;------------------------------------------------------------------------------
_TEXT	segment
	assume	cs:_TEXT, ds:DGROUP, es:DGROUP, ss:DGROUP
vminit	label	byte
	page
;******************************************************************************
;   InitBitMap - Initialize 386 Tss I/O bit map for Virtual mode I/O trapping.
;
;   ENTRY: Real Mode
;		DS = DGROUP
;		I/O bit map all zeroes (no trapping) except last byte.
;   EXIT:  Real Mode
;		I/O bit map in Tss initialized.
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
InitBitMap	proc	far
;
	push	ax
	push	bx
	push	si
	push	es
;
	mov	ax,seg TSS
	mov	es,ax			; set ES to I/O Bit Map seg
	ASSUME	ES:TSS
	xor	bx,bx			; ES:[BX] = pts to TSS
;
; initialize BitMapBase in Tss
;
	mov	ax,offset TSS:IOBitMap
	mov	ES:[bx.BitMapBase],ax		; set Bit Map base in Tss
;
;  set ports for return to real trap
;
	call	RR_Trap_Init
;
;  Turn on Keyboard watching for A20 disable
;
	call	A20_Trap_Init
;
;  Turn on any other OEM specific trapping
;
	call	OEM_Trap_Init

IB_exit:
	pop	es
	ASSUME	ES:DGROUP
	pop	si
	pop	bx
	pop	ax
	ret				; *** RETURN ***
InitBitMap	endp

;******************************************************************************
;   PortTrap - sets bit(s) in I/O bit map to enable trapping at an I/O address
;
;	This function sets the appropriate bits in the I/O bit map to enable
;   trapping of the desired I/O address.  Since some I/O ports on the AT system
;   board are selected via only 10 bits of address lines, these ports appear
;   at every 1K in the I/O address space.  When trapping these "system board"
;   ports, the trap bits in the I/O bit map must be set for every 1k instance
;   of the port.
;
;   ENTRY: AX = byte I/O address to set in Bit Map
;	   BH = high bit set => set traps bits for this address @ every 1K
;	   ES = TSS
;
;   EXIT: none.
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
PortTrap	proc	near
;
	ASSUME	ES:TSS
	push	ax
	push	bx
	push	cx
;
	mov	cx,1			;   once by default
	test	bh,80h			;Q: map it every 1K ?
	jz	PT_loop 		;  N: do it once
	mov	cx,64			;  Y: do it 64 times (once per 1k)
PT_loop:
	push	ax			;  map it. save this address
	call	BitOFF			; get offset and bit
	or	ES:IOBitMap[bx],al	; trap this address
	pop	ax			; restore this address
	add	ax,400h 		; add 1k for next address
	loop	PT_loop 		; and continue ...
;
	pop	cx
	pop	bx
	pop	ax
	ret
	ASSUME	ES:DGROUP
;
PortTrap	endp


ifdef	oldstuff
;******************************************************************************
;   PortClear - clears bit(s) in I/O bit map to disable trapping at an I/O
;   address
;
;	This function clears the appropriate bits in the I/O bit map to disable
;   trapping of the desired I/O address.  Since some I/O ports on the AT system
;   board are selected via only 10 bits of address lines, these ports appear
;   at every 1K in the I/O address space.  When clearing these "system board"
;   ports, the trap bits in the I/O bit map must be cleared at every 1k instance
;   of the port.
;
;   ENTRY: AX = byte I/O address to clear in Bit Map
;	   BH = high bit set => clear traps bits for this address @ every 1K
;	   ES = data segment for I/O bit map
;
;   EXIT: none.
;
;   USED:  Flags
;   STACK:
;   NOTE:   This implementation does not account for a port being multiply set
;   for many purposes.	(ie. If a port is set 3 times, it still only takes one
;   PortClear call to clear it.)  If this is a problem, a counter for each
;   enabled port will have to be added.
;
;------------------------------------------------------------------------------
PortClear	proc	near
;
	ASSUME	ES:TSS
	push	ax
	push	bx
	push	cx
;
	mov	cx,1			;   once by default
	test	bh,80h			;Q: map it every 1K ?
	jz	PC_loop 		;  N: do it once
	mov	cx,64			;  Y: do it 64 times (once per 1k)
PC_loop:
	push	ax			;  map it. save this address
	call	BitOFF			; get offset and bit
	not	al
	and	ES:IOBitMap[bx],al	; clear this address
	pop	ax			; restore this address
	add	ax,400h 		; add 1k for next address
	loop	PC_loop 		; and continue ...
;
	pop	cx
	pop	bx
	pop	ax
	ret
	ASSUME	ES:DGROUP
;
PortClear	endp
endif		; oldstuff


;******************************************************************************
;   BitOFF - sets up byte and bit for I/O address in I/O Bit Map
;
;   ENTRY: AX = byte I/O address to set in Bit Map
;
;   EXIT:  BX = byte offset
;	   AL = bit to OR in to set proper bit
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
BitOFF	proc	near
;
	push	cx

	mov	cx,ax
	and	cx,07h				; CL = bit pos for this port
	shr	ax,3				; AX = byte offset for this bit
	mov	bx,ax				; BX = byte offset for port
	mov	ax,1
	shl	ax,cl				; AL = bit mask for this port

	pop	cx
	ret
;
BitOFF	endp

;
_TEXT	ends				; end of segment
;
	end				; end of module
