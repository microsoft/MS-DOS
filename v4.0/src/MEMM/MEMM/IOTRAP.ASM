

	page	58,132
;******************************************************************************
	title	IOTRAP.ASM - Dispatches I/O trap handlers
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   IOTRAP.ASM - Dispatches I/O trap handlers
;
;   Version:  0.04
;
;   Date:     July 1, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   07/01/86  0.03	From ELIMTRAP.ASM
;   07/03/86  0.03	Added handlers for 84,85,60, & 64
;   07/06/86  0.04	Changed assume to DGROUP
;
;******************************************************************************
;
;   Functional Description:
;
;	This routine is called by all I/O space trap handlers to allow
;   emulation/monitoring of I/O address reads and writes.  When a GP fault
;   occurs due to I/O to an address trapped in the I/O Bit Map, the I/O
;   instruction emulation routine in VMINST calls this routine.  This
;   routine calls the appropriate I/O trap handler for the I/O address.
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
	page
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	IO_Trap 		; dispatches I/O trap handlers

;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
FALSE	equ	0
TRUE	equ	not FALSE

	include VDMseg.inc
	include VDMsel.inc

;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************

_TEXT	segment

extrn	IOTrap_Tab:word 	; System board IO trap routine address table
extrn	IOT_BadT:near		; Routine to execute for unknown port
;extrn	IOT_LIM:near		; Routine to handle LIM emulated ports
extrn	IOT_OEM:near		; Routine to handle OEM specific emulate ports

_TEXT	ends

;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************

_TEXT	segment
	assume	cs:_TEXT, ds:DGROUP, es:DGROUP, ss:DGROUP

;******************************************************************************
;   IO_Trap - Dispatches trap handler for an I/O address
;
;   ENTRY: Protected Mode Ring 0
;		AL = byte to output to port.
;		DX = port address for I/O.
;		SS:BP = points to stack frame on entry to GP fault handler
;		BX = 0 => Emulate Input.
;		   <>0 => Emulate Output.
;
;   EXIT:  Protected Mode Ring 0
;		AL = emulated input value from port.
;		CLC => I/O emulated by LIM_Trap.
;		STC => I/O NOT emulated by LIM_Trap.
;
;   WARNING:***********
;	    This routine is closely allied with IOTBadT which is in TrapDef.
;	    IOTBadT assumes that the stack is in a certain state!
;	    ***********
;
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
IO_Trap proc	near
;
	push	ds
	push	dx

	push	VDMD_GSEL
	pop	ds			; set DS = DGROUP

	cmp	dx,0100h		;Q: I/O Addr < 0100h (system brd port)?
	jae	IOT_NotSys		;  N: check mapping regs
IOT_Sys:				;  Y: dispatch I/O trap handler
	xchg	bx, dx			; BL = port address
	shl	bx,1			; BX = BX*2 (word table)
	call	cs:IOTrap_Tab[bx]	; call handler
					;   ENTRY: entry DX,DS on stack
					;   DS = DGROUP selector
					;   BX = 2 * port address in 0100h range
					;   DX = input/output flag

	xchg	bx,dx			; reset bx
	pop	dx			;
	pop	ds			; reset dx
	ret				; CF = 1 if I/O not emulated

;
;    Address >= 0100h

IOT_NotSys:
;
;  check for OEM specific I/O emulation
;
	call	IOT_OEM 		;If emulated by OEM specific routine
					; does not return(returns from IO_Trap)
; NOTE : we don't have LIM h/w port anymore
;
;  check for LIM mapping register address
;
;	call	IOT_LIM 		;If emulated by LIM emulation routine
					; does not return(returns from IO_Trap)

;
;   Here if I/O Address >= 0100h and not a mapping register
;	map it into 1k and try system board ports again
;
	and	dx,3FFh 	; map address into 1k range
	cmp	dx,0100h	;Q: I/O Addr < 0100h (system brd port)?
	jb	IOT_Sys 	;  Y: check system ports
				;  N: unknown port
	xchg	bx,dx		; put Input/Output flag in DX for IOT_BadT
	shl	bx,1
	call	IOT_BadT
	jmp	$		;IOT_BadT pops return address off restores regs
				;	and returns

IO_Trap endp


_TEXT	ends

	end
