

	page	58,132
;******************************************************************************
	title	TRAPDEF.ASM - I/O trap Dispatch table
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   TRAPDEF.ASM - I/O trap Dispatch table
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
;   08/11/86		Split from IOTrap.asm
;   
;   7/26/88   		Added Trap handler entries for DMA ports on Channel 4
;			 - Jaywant H Bharadwaj
;
;******************************************************************************
;
.lfcond 				; list false conditionals
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	IOTrap_Tab		; dispatches I/O trap handlers
	public	IOT_BadT		; Unknown port trap routine
	public	IOT_OEM 		; OEM specific port emulation

	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
; % - how many of these are actually needed?
; % - Need any includes from Win/386 DMA code - trapdef.asm ?

	include VDMseg.inc
	include VDMsel.inc
	include desc.inc
	include elim.inc
	include page.inc
	include oemdep.inc
	include instr386.inc
	include vm386.inc
;
;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************
;

_DATA	segment
;extrn	_map_size:byte		; # of mapping registers used
;extrn	LIMP_Addr:word
_DATA	ends

_TEXT	segment
;
extrn	RRP_Handler:near
extrn	A20_Handler:near	; Kybd Data port - A20 watch
extrn	DMABase0:near		;  DMA base register for Channel 0
extrn	DMABase1:near		;  DMA base register for Channel 1
extrn	DMABase2:near		;  DMA base register for Channel 2
extrn	DMABase3:near		;  DMA base register for Channel 3
extrn	DMABase5:near		;  DMA base register for Channel 5
extrn	DMABase6:near		;  DMA base register for Channel 6
extrn	DMABase7:near		;  DMA base register for Channel 7
extrn	DMACnt0:near 		;  DMA count register for Channel 0
extrn	DMACnt1:near		;  DMA count register for Channel 1
extrn	DMACnt2:near		;  DMA count register for Channel 2
extrn	DMACnt3:near		;  DMA count register for Channel 3
extrn	DMACnt5:near		;  DMA count register for Channel 5
extrn	DMACnt6:near		;  DMA count register for Channel 6
extrn	DMACnt7:near		;  DMA count register for Channel 7
extrn	DMAPg0:near		;  DMA page register for Channel 0
extrn	DMAPg1:near		;  DMA page register for Channel 1
extrn	DMAPg2:near		;  DMA page register for Channel 2
extrn	DMAPg3:near		;  DMA page register for Channel 3
extrn	DMAPg5:near		;  DMA page register for Channel 5
extrn	DMAPg6:near		;  DMA page register for Channel 6
extrn	DMAPg7:near		;  DMA page register for Channel 7
extrn	DMAClrFF1:near		;  clear flip-flop cmd for channels 0-3
extrn	DMAClrFF2:near		;  clear flip-flop cmd for channels 5-7
extrn	DMAMode1:near		;  Mode register for channels 0-3
extrn	DMAMode2:near		;  Mode register for channels 4-7

_TEXT	ends

;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************

;
;------------------------------------------------------------------------------
_TEXT	segment
	assume	cs:_TEXT, ds:DGROUP, es:DGROUP, ss:DGROUP
;
;   IOTrapTab
;	One entry per port in the I/O space from 00h to FFh.
;	Note that ports not specifically mapped otherwise(by IOT_OEM or
;	LIM emulation and whose least significant 10 bits are less than
;	100h are also dispatched through this table(upper 6 bits assumed to
;	be intended as zero since some earlier systems only had 10 bits of
;	I/O addressing).
;
IOTrap_Tab	label	word
	dw	offset _TEXT:DMAbase0  ;  0 DMA base register for Channel 0
	dw	offset _TEXT:DMACnt0   ;  1 DMA count register for Channel 0
	dw	offset _TEXT:DMABase1  ;  2 DMA base register for Channel 1
	dw	offset _TEXT:DMACnt1   ;  3 DMA count register for Channel 1
	dw	offset _TEXT:DMABase2  ;  4 DMA base register for Channel 2
	dw	offset _TEXT:DMACnt2   ;  5 DMA count register for Channel 2
	dw	offset _TEXT:DMABase3  ;  6 DMA base register for Channel 3
	dw	offset _TEXT:DMACnt3   ;  7 DMA count register for Channel 3
	dw	offset _TEXT:IOT_BadT  ;  8
	dw	offset _TEXT:IOT_BadT  ;  9
	dw	offset _TEXT:IOT_BadT  ;  a
	dw	offset _TEXT:DMAMode1  ;  b DMA Mode Register for for Ch 0-3
	dw	offset _TEXT:DMAClrFF1   ;  c clear flip-flop cmd for channels 0-3
	dw	offset _TEXT:IOT_BadT  ;  d
	dw	offset _TEXT:IOT_BadT  ;  e
	dw	offset _TEXT:IOT_BadT  ;  f
	dw	offset _TEXT:IOT_BadT  ; 10
	dw	offset _TEXT:IOT_BadT  ; 11
	dw	offset _TEXT:IOT_BadT  ; 12
	dw	offset _TEXT:IOT_BadT  ; 13
	dw	offset _TEXT:IOT_BadT  ; 14
	dw	offset _TEXT:IOT_BadT  ; 15
	dw	offset _TEXT:IOT_BadT  ; 16
	dw	offset _TEXT:IOT_BadT  ; 17
	dw	offset _TEXT:IOT_BadT  ; 18
	dw	offset _TEXT:IOT_BadT  ; 19
	dw	offset _TEXT:IOT_BadT  ; 1a
	dw	offset _TEXT:IOT_BadT  ; 1b
	dw	offset _TEXT:IOT_BadT  ; 1c
	dw	offset _TEXT:IOT_BadT  ; 1d
	dw	offset _TEXT:IOT_BadT  ; 1e
	dw	offset _TEXT:IOT_BadT  ; 1f
	dw	offset _TEXT:IOT_BadT  ; 20
	dw	offset _TEXT:IOT_BadT  ; 21
	dw	offset _TEXT:IOT_BadT  ; 22
	dw	offset _TEXT:IOT_BadT  ; 23
	dw	offset _TEXT:IOT_BadT  ; 24
	dw	offset _TEXT:IOT_BadT  ; 25
	dw	offset _TEXT:IOT_BadT  ; 26
	dw	offset _TEXT:IOT_BadT  ; 27
	dw	offset _TEXT:IOT_BadT  ; 28
	dw	offset _TEXT:IOT_BadT  ; 29
	dw	offset _TEXT:IOT_BadT  ; 2a
	dw	offset _TEXT:IOT_BadT  ; 2b
	dw	offset _TEXT:IOT_BadT  ; 2c
	dw	offset _TEXT:IOT_BadT  ; 2d
	dw	offset _TEXT:IOT_BadT  ; 2e
	dw	offset _TEXT:IOT_BadT  ; 2f
	dw	offset _TEXT:IOT_BadT  ; 30
	dw	offset _TEXT:IOT_BadT  ; 31
	dw	offset _TEXT:IOT_BadT  ; 32
	dw	offset _TEXT:IOT_BadT  ; 33
	dw	offset _TEXT:IOT_BadT  ; 34
	dw	offset _TEXT:IOT_BadT  ; 35
	dw	offset _TEXT:IOT_BadT  ; 36
	dw	offset _TEXT:IOT_BadT  ; 37
	dw	offset _TEXT:IOT_BadT  ; 38
	dw	offset _TEXT:IOT_BadT  ; 39
	dw	offset _TEXT:IOT_BadT  ; 3a
	dw	offset _TEXT:IOT_BadT  ; 3b
	dw	offset _TEXT:IOT_BadT  ; 3c
	dw	offset _TEXT:IOT_BadT  ; 3d
	dw	offset _TEXT:IOT_BadT  ; 3e
	dw	offset _TEXT:IOT_BadT  ; 3f
	dw	offset _TEXT:IOT_BadT  ; 40
	dw	offset _TEXT:IOT_BadT  ; 41
	dw	offset _TEXT:IOT_BadT  ; 42
	dw	offset _TEXT:IOT_BadT  ; 43
	dw	offset _TEXT:IOT_BadT  ; 44
	dw	offset _TEXT:IOT_BadT  ; 45
	dw	offset _TEXT:IOT_BadT  ; 46
	dw	offset _TEXT:IOT_BadT  ; 47
	dw	offset _TEXT:IOT_BadT  ; 48
	dw	offset _TEXT:IOT_BadT  ; 49
	dw	offset _TEXT:IOT_BadT  ; 4a
	dw	offset _TEXT:IOT_BadT  ; 4b
	dw	offset _TEXT:IOT_BadT  ; 4c
	dw	offset _TEXT:IOT_BadT  ; 4d
	dw	offset _TEXT:IOT_BadT  ; 4e
	dw	offset _TEXT:IOT_BadT  ; 4f
	dw	offset _TEXT:IOT_BadT  ; 50
	dw	offset _TEXT:IOT_BadT  ; 51
	dw	offset _TEXT:IOT_BadT  ; 52
	dw	offset _TEXT:IOT_BadT  ; 53
	dw	offset _TEXT:IOT_BadT  ; 54
	dw	offset _TEXT:IOT_BadT  ; 55
	dw	offset _TEXT:IOT_BadT  ; 56
	dw	offset _TEXT:IOT_BadT  ; 57
	dw	offset _TEXT:IOT_BadT  ; 58
	dw	offset _TEXT:IOT_BadT  ; 59
	dw	offset _TEXT:IOT_BadT  ; 5a
	dw	offset _TEXT:IOT_BadT  ; 5b
	dw	offset _TEXT:IOT_BadT  ; 5c
	dw	offset _TEXT:IOT_BadT  ; 5d
	dw	offset _TEXT:IOT_BadT  ; 5e
	dw	offset _TEXT:IOT_BadT  ; 5f
	dw	offset _TEXT:A20_Handler	; A20 watch on kybd data port
	dw	offset _TEXT:IOT_BadT  ; 61
	dw	offset _TEXT:IOT_BadT  ; 62
	dw	offset _TEXT:IOT_BadT  ; 63
	dw	offset _TEXT:A20_Handler	; A20 watch on kybd cmd port
	dw	offset _TEXT:IOT_BadT  ; 65
	dw	offset _TEXT:IOT_BadT  ; 66
	dw	offset _TEXT:IOT_BadT  ; 67
	dw	offset _TEXT:IOT_BadT  ; 68
	dw	offset _TEXT:IOT_BadT  ; 69
	dw	offset _TEXT:IOT_BadT  ; 6a
	dw	offset _TEXT:IOT_BadT  ; 6b
	dw	offset _TEXT:IOT_BadT  ; 6c
	dw	offset _TEXT:IOT_BadT  ; 6d
	dw	offset _TEXT:IOT_BadT  ; 6e
	dw	offset _TEXT:IOT_BadT  ; 6f
	dw	offset _TEXT:IOT_BadT  ; 70
	dw	offset _TEXT:IOT_BadT  ; 71
	dw	offset _TEXT:IOT_BadT  ; 72
	dw	offset _TEXT:IOT_BadT  ; 73
	dw	offset _TEXT:IOT_BadT  ; 74
	dw	offset _TEXT:IOT_BadT  ; 75
	dw	offset _TEXT:IOT_BadT  ; 76
	dw	offset _TEXT:IOT_BadT  ; 77
	dw	offset _TEXT:IOT_BadT  ; 78
	dw	offset _TEXT:IOT_BadT  ; 79
	dw	offset _TEXT:IOT_BadT  ; 7a
	dw	offset _TEXT:IOT_BadT  ; 7b
	dw	offset _TEXT:IOT_BadT  ; 7c
	dw	offset _TEXT:IOT_BadT  ; 7d
	dw	offset _TEXT:IOT_BadT  ; 7e
	dw	offset _TEXT:IOT_BadT  ; 7f
	dw	offset _TEXT:IOT_BadT  ; 80
	dw	offset _TEXT:DMAPg2    ; 81 DMA page register for Channel 2
	dw	offset _TEXT:DMAPg3    ; 82 DMA page register for Channel 3
	dw	offset _TEXT:DMAPg1    ; 83 DMA page register for Channel 1
	dw	offset _TEXT:RRP_Handler	; return to real port
	dw	offset _TEXT:RRP_Handler	; return to real port
	dw	offset _TEXT:IOT_BadT  ; 86
	dw	offset _TEXT:DMAPg0    ; 87 DMA page register for Channel 0
	dw	offset _TEXT:IOT_BadT  ; 88
	dw	offset _TEXT:DMAPg6    ; 89 DMA page register for Channel 6
	dw	offset _TEXT:DMAPg7    ; 8a DMA page register for Channel 7
	dw	offset _TEXT:DMAPg5    ; 8b DMA page register for Channel 5
	dw	offset _TEXT:IOT_BadT  ; 8c
	dw	offset _TEXT:IOT_BadT  ; 8d
	dw	offset _TEXT:IOT_BadT  ; 8e
	dw	offset _TEXT:IOT_BadT  ; 8f
	dw	offset _TEXT:IOT_BadT  ; 90
	dw	offset _TEXT:DMAPg2    ; 91 DMA page register for Channel 2
	dw	offset _TEXT:DMAPg3    ; 92 DMA page register for Channel 3
	dw	offset _TEXT:DMAPg1    ; 93 DMA page register for Channel 1
	dw	offset _TEXT:IOT_BadT  ; 94
	dw	offset _TEXT:IOT_BadT  ; 95
	dw	offset _TEXT:IOT_BadT  ; 96
	dw	offset _TEXT:IOT_BadT  ; 97 DMA page register for Channel 0
	dw	offset _TEXT:IOT_BadT  ; 98
	dw	offset _TEXT:DMAPg6    ; 99 DMA page register for Channel 6
	dw	offset _TEXT:DMAPg7    ; 9a DMA page register for Channel 7
	dw	offset _TEXT:DMAPg5    ; 9b DMA page register for Channel 5
	dw	offset _TEXT:IOT_BadT  ; 9c
	dw	offset _TEXT:IOT_BadT  ; 9d
	dw	offset _TEXT:IOT_BadT  ; 9e
	dw	offset _TEXT:IOT_BadT  ; 9f
	dw	offset _TEXT:IOT_BadT  ; a0
	dw	offset _TEXT:IOT_BadT  ; a1
	dw	offset _TEXT:IOT_BadT  ; a2
	dw	offset _TEXT:IOT_BadT  ; a3
	dw	offset _TEXT:IOT_BadT  ; a4
	dw	offset _TEXT:IOT_BadT  ; a5
	dw	offset _TEXT:IOT_BadT  ; a6
	dw	offset _TEXT:IOT_BadT  ; a7
	dw	offset _TEXT:IOT_BadT  ; a8
	dw	offset _TEXT:IOT_BadT  ; a9
	dw	offset _TEXT:IOT_BadT  ; aa
	dw	offset _TEXT:IOT_BadT  ; ab
	dw	offset _TEXT:IOT_BadT  ; ac
	dw	offset _TEXT:IOT_BadT  ; ad
	dw	offset _TEXT:IOT_BadT  ; ae
	dw	offset _TEXT:IOT_BadT  ; af
	dw	offset _TEXT:IOT_BadT  ; b0
	dw	offset _TEXT:IOT_BadT  ; b1
	dw	offset _TEXT:IOT_BadT  ; b2
	dw	offset _TEXT:IOT_BadT  ; b3
	dw	offset _TEXT:IOT_BadT  ; b4
	dw	offset _TEXT:IOT_BadT  ; b5
	dw	offset _TEXT:IOT_BadT  ; b6
	dw	offset _TEXT:IOT_BadT  ; b7
	dw	offset _TEXT:IOT_BadT  ; b8
	dw	offset _TEXT:IOT_BadT  ; b9
	dw	offset _TEXT:IOT_BadT  ; ba
	dw	offset _TEXT:IOT_BadT  ; bb
	dw	offset _TEXT:IOT_BadT  ; bc
	dw	offset _TEXT:IOT_BadT  ; bd
	dw	offset _TEXT:IOT_BadT  ; be
	dw	offset _TEXT:IOT_BadT  ; bf
	dw	offset _TEXT:IOT_BadT  ; c0 DMA base register for Channel 4
	dw	offset _TEXT:IOT_BadT  ; c1
	dw	offset _TEXT:IOT_BadT  ; c2 DMA count register for Channel 4
	dw	offset _TEXT:IOT_BadT  ; c3
	dw	offset _TEXT:DMABase5  ; c4 DMA base register for Channel 5
	dw	offset _TEXT:IOT_BadT  ; c5
	dw	offset _TEXT:DMACnt5   ; c6 DMA count register for Channel 5
	dw	offset _TEXT:IOT_BadT  ; c7
	dw	offset _TEXT:DMABase6  ; c8 DMA base register for Channel 6
	dw	offset _TEXT:IOT_BadT  ; c9
	dw	offset _TEXT:DMACnt6   ; ca DMA count register for Channel 6
	dw	offset _TEXT:IOT_BadT  ; cb
	dw	offset _TEXT:DMABase7  ; cc DMA base register for Channel 7
	dw	offset _TEXT:IOT_BadT  ; cd
	dw	offset _TEXT:DMACnt7   ; ce DMA count register for Channel 7
	dw	offset _TEXT:IOT_BadT  ; cf
	dw	offset _TEXT:IOT_BadT  ; d0
	dw	offset _TEXT:IOT_BadT  ; d1
	dw	offset _TEXT:IOT_BadT  ; d2
	dw	offset _TEXT:IOT_BadT  ; d3
	dw	offset _TEXT:IOT_BadT  ; d4
	dw	offset _TEXT:IOT_BadT  ; d5
	dw	offset _TEXT:DMAMode2  ; d6 DMA Mode Register for channels 4-7
	dw	offset _TEXT:IOT_BadT  ; d7
	dw	offset _TEXT:DMAClrFF2   ; d8 clear flip-flop cmd for channels 5-7
	dw	offset _TEXT:IOT_BadT  ; d9
	dw	offset _TEXT:IOT_BadT  ; da
	dw	offset _TEXT:IOT_BadT  ; db
	dw	offset _TEXT:IOT_BadT  ; dc
	dw	offset _TEXT:IOT_BadT  ; dd
	dw	offset _TEXT:IOT_BadT  ; de
	dw	offset _TEXT:IOT_BadT  ; df
	dw	offset _TEXT:IOT_BadT  ; e0
	dw	offset _TEXT:IOT_BadT  ; e1
	dw	offset _TEXT:IOT_BadT  ; e2
	dw	offset _TEXT:IOT_BadT  ; e3
	dw	offset _TEXT:IOT_BadT  ; e4
	dw	offset _TEXT:IOT_BadT  ; e5
	dw	offset _TEXT:IOT_BadT  ; e6
	dw	offset _TEXT:IOT_BadT  ; e7
	dw	offset _TEXT:IOT_BadT  ; e8
	dw	offset _TEXT:IOT_BadT  ; e9
	dw	offset _TEXT:IOT_BadT  ; ea
	dw	offset _TEXT:IOT_BadT  ; eb
	dw	offset _TEXT:IOT_BadT  ; ec
	dw	offset _TEXT:IOT_BadT  ; ed
	dw	offset _TEXT:IOT_BadT  ; ee
	dw	offset _TEXT:IOT_BadT  ; ef
	dw	offset _TEXT:IOT_BadT  ; f0
	dw	offset _TEXT:IOT_BadT  ; f1
	dw	offset _TEXT:IOT_BadT  ; f2
	dw	offset _TEXT:IOT_BadT  ; f3
	dw	offset _TEXT:IOT_BadT  ; f4
	dw	offset _TEXT:IOT_BadT  ; f5
	dw	offset _TEXT:IOT_BadT  ; f6
	dw	offset _TEXT:IOT_BadT  ; f7
	dw	offset _TEXT:IOT_BadT  ; f8
	dw	offset _TEXT:IOT_BadT  ; f9
	dw	offset _TEXT:IOT_BadT  ; fa
	dw	offset _TEXT:IOT_BadT  ; fb
	dw	offset _TEXT:IOT_BadT  ; fc
	dw	offset _TEXT:IOT_BadT  ; fd
	dw	offset _TEXT:IOT_BadT  ; fe
	dw	offset _TEXT:IOT_BadT  ; ff

;******************************************************************************
;   IOT_BadT - GP fault on Unknown I/O address
;
;   DESCRIPTION:    This routine is entered by being in the IOTrap_Tab above
;		and also for I/O ports which are not LIM(DMA) ports and are not
;		emulated by IOT_OEM routine below and the first 10 bits of the
;		address is greater than 100h. Note that only the first 10 bits
;		of the port (times 2) is passed in BX.	If the entire port
;		address is desired, it is available on the stack as the value
;		which is popped into DX.
;
;   ENTRY: Protected Mode Ring 0
;		return address, DX, DS, return address on stack
;		AL = byte to output to port.
;		BX == 2 * port address(either 0-1FE or 200-7FE)
;		DX == 0  => Emulate input
;		   <> 0  => Emulate output
;		DS = DGROUP
;		SS:BP = points to stack frame on entry to GP fault handler
;
;
;   EXIT:  Protected Mode Ring 0
;		First return address, pop'd from stack.
;		DX and DS restored from stack.
;		BX = DX on entry
;		STC => I/O NOT emulated.
;
;   WARNING:***********
;	    This routine is closely allied with IOTrap which is in IOTrap.
;	    It is assumed that IOTrap puts the stack in a certain state!
;	    ***********

;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
;
IOT_BadT	proc	near
	pop	bx		;   dump return address
	mov	bx,dx		; restore BX
	pop	dx		; restore DX(port address)
	pop	ds		; restore DS
	stc			;   port not emulated !
	ret			;  and return
IOT_BadT	endp

;******************************************************************************
;   IOT_OEM - Handles OEM specific I/O traps
;
;   ENTRY: Protected Mode Ring 0
;		AL = byte to output to port.
;		DX = port address for I/O.
;		SS:BP = points to stack frame on entry to GP fault handler
;		BX = 0 => Emulate Input.
;		   <>0 => Emulate Output.
;		DS = DGROUP
;		stack: near return to IOTrap, DX, DS, near return from IOTrap
;
;   EXIT:  Protected Mode Ring 0
;		Either emulate I/O and pop return, DX, DS from stack and RET
;		    with CF = 1(CF = 0 if I/O is to be ignored!?!?).
;		Or just return(no emulation done)
;
;
;   WARNING:***********
;	    This routine is closely allied with IOTrap.
;	    It assumes that the stack is in a certain state!
;	    ***********
;
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
IOT_OEM proc	near
;	cmp	dx,????
;	jnz	NoEmulation
;	or	bx,bx
;	jnz	NoEmulation
;	mov	al,???? 	;emulate input
;	pop	dx		;remove return
;	pop	dx		;restore DX
;	pop	ds		;restore DS
;	ret			;return from IOTRAP
;
;NoEmulation:
	ret			; no emulation
IOT_OEM endp


_TEXT	ends

	end
