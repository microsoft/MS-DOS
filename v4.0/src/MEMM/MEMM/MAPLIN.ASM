

page	58,132
;******************************************************************************
	title	MapLinear - map linear address according to page tables
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   MapLinear
;
;   Version:  0.04
;
;   Date:     June 2, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   06/08/86  Original
;   06/28/86  0.02	Name changed from MEMM386 to MEMM
;   07/05/86  0.04	DiagByte moved to _DATA
;   07/06/86  0.04	changed assume to DGROUP
;
;******************************************************************************
;
;   Functional Description:
;	This routine in this module takes a "virtual" addresses specified by
;   a virtual mode processs and "maps" it to the corresponding linear address
;   according to the linear to physical mapping in the page tables.
;   This file also contains a routine to do the inverse mapping.
;
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	MapLinear
	public	UnMapLinear
;

	page
;******************************************************************************
;			I N C L U D E	F I L E S
;******************************************************************************

	include vdmseg.inc
	include vdmsel.inc
	include instr386.inc
	include oemdep.inc

;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************
;
;******************************************************************************
;			C O D E   S E G M E N T
;******************************************************************************
_TEXT	 segment
	assume	cs:_TEXT, ds:DGROUP, es:DGROUP
	page
;******************************************************************************
;	MapLinear - maps a linear address to it's "true" linear address.
;
;	ENTRY:	PROTECTED MODE ONLY
;		EAX = 32 bit linear address
;
;	EXIT:	EAX = 32 bit "mapped" linear address
;
;	USED:	none.
;
;	The page dir and table set up by this routine maps the linear
;	addresses for Virtual mode programs into physical addresses using
;	the following scheme. Note that "high" memory is mapped to the
;	range starting at 16 Meg so that the page tables can be shorter.
;
;	Linear Addr		Physical Addr
;	00000000h - 000FFFFFh	00000000h - 000FFFFFh
;	00100000h - 0010FFFFh	00000000h - 0000FFFFh  (64k wraparound)
;	00110000h - 010FFFFFh	00100000h - 00FFFFFFh  (top 15Meg of phys)
ifndef	NOHIMEM
;	01010000h - 0101FFFFh	xxxx0000h - xxxxFFFFh  ("high" memory)
;				xxxx is mapped by Map_Lin_OEM in OEMPROC module
endif
;
;	True Linear is same as linear in our new mapping scheme.  So except
;	for the "high" memory we have the true linear returned being the same
;	as linear.  The new mapping is:
;
;	Linear Addr		Physical Addr
;	00000000h - 000FFFFFh	00000000h - 000FFFFFh
;	00100000h - 0010FFFFh	00000000h - 0000FFFFh  (64k wraparound)
;	00110000h - 00ffffffh	00110000h - 00ffffffh  (top 15Meg of phys)
;	01000000h - 0100FFFFh	xxxx0000h - xxxxFFFFh  ("high" memory)
;				xxxx is mapped by Map_Lin_OEM in OEMPROC module
;
;******************************************************************************
MapLinear	proc	near
;
	call	Map_Lin_OEM	;Q: Special mapping done by OEM routines?
	jc	ML_Exit 	;   Y: AX = mapped address
				;   N: Do standard mapping

;
;   the routine here is to be executed to get the true linear address.	Since
;   it is a 1 - 1 mapping we have no code here
;
ML_exit:
	ret
;
MapLinear	endp


;******************************************************************************
;	UnMapLinear - maps a "true" linear address to it's linear address.
;
;	ENTRY:	EAX = 32 bit "mapped" linear address
;
;	EXIT:	EAX = 32 bit linear address
;
;	USED:	none.
;
;	The page dir and table set up maps the linear
;	addresses for Virtual mode programs into physical addresses using
;	the following scheme.
;	Linear Addr		Physical Addr
;	00000000h - 000FFFFFh	00000000h - 000FFFFFh
;	00100000h - 0010FFFFh	00000000h - 0000FFFFh  (64k wraparound)
;	00110000h - 010FFFFFh	00100000h - 00FFFFFFh  (top 15Meg of phys)
ifndef	NOHIMEM
;	01010000h - 0101FFFFh	xxxx0000h - xxxxFFFFh  (high memory)
;				xxxx is mapped by UMap_Lin_OEM in OEMPROC module
endif
;
;	Our new mapping scheme is:
;
;	Linear Addr		Physical Addr
;	00000000h - 000FFFFFh	00000000h - 000FFFFFh
;	00100000h - 0010FFFFh	00000000h - 0000FFFFh  (64k wraparound)
;	00110000h - 00ffffffh	00110000h - 00ffffffh  (top 15Meg of phys)
;	01000000h - 0100FFFFh	xxxx0000h - xxxxFFFFh  ("high" memory)
;				xxxx is mapped by Map_Lin_OEM in OEMPROC module
;
;******************************************************************************
UnMapLinear	proc	near
;
	cmp	eax,01000000	;
	jb	UML_mask	;  N: chk for < 1 meg
	call	UMap_Lin_OEM	;  Y: set EAX to physical address for diags
	jmp	short UML_exit

UML_mask:
UML_exit:
	ret
;
UnMapLinear	endp


_TEXT	 ends

	end

