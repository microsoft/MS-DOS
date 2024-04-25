

page	58,132
;******************************************************************************
	title	TABDEF.ASM - 386 Protected Mode CPU Tables
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   TABDEF.ASM - 386 Protected Mode CPU Tables
;
;   Version:  0.04
;
;   Date:     January 31, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   01/31/86		Tables for Standalone protected mode system
;	      A-	Modified for Virtual DOS
;   05/12/86  B-	Cleanup and segment reorganization
;   06/28/86  0.02	Name changed from MEMM386 to MEMM
;   07/05/86  0.04	Moved KBD and PRINT to DCODE segment
;   07/20/88		Remove debugger codes (pc)
;
;******************************************************************************
;
;   Functional Description:
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p

NAME	tabdef
;

.xlist
	include VDMseg.inc
	include VDMsel.inc
	include desc.inc
	include page.inc
.list


_TEXT SEGMENT
	extrn	vm_trap00:far
	extrn	vm_trap01:far
	extrn	vm_trap02:far
	extrn	vm_trap03:far
	extrn	vm_trap04:far
	extrn	vm_trap05:far
	extrn	vm_trap06:far
	extrn	vm_trap07:far
	extrn	vm_trap08:far
	extrn	vm_trap09:far
	extrn	vm_trap0a:far
	extrn	vm_trap0b:far
	extrn	vm_trap0c:far
	extrn	vm_trap0d:far
	extrn	vm_trap0e:far
	extrn	vm_trap0f:far
	extrn	vm_trap50:far
	extrn	vm_trap51:far
	extrn	vm_trap52:far
	extrn	vm_trap53:far
	extrn	vm_trap54:far
	extrn	vm_trap55:far
	extrn	vm_trap56:far
	extrn	vm_trap57:far
	extrn	vm_trap70:far
	extrn	vm_trap71:far
	extrn	vm_trap72:far
	extrn	vm_trap73:far
	extrn	vm_trap74:far
	extrn	vm_trap75:far
	extrn	vm_trap76:far
	extrn	vm_trap77:far

	extrn	EMM_pEntry:far

_TEXT ENDS


;***	GDT - Global Descriptor Table
;
;	This is the system GDT. Some parts are statically initialised,
;	others must be set up at run time, either because masm can't
;	calculate the data or it changes while the system is running.
;
;	WARNING
;
;	Don't change this without consulting "sel.inc", and the
;	routines which initialise the gdt.
;

GDT SEGMENT

gdtstart	label byte	; label for everyone to refer to the GDT

GDT_ENTRY	0, 0, 1, 0			; null selector
GDT_ENTRY	0, 0, 0, D_DATA0		; GDT alias
GDT_ENTRY	0, 0, 0, D_DATA0		; IDT alias
GDT_ENTRY	0, 0, 0, D_LDT0 		; LDT
GDT_ENTRY	0, 0, 0, D_DATA0		; LDT alias
GDT_ENTRY	0, 0, 0, D_386TSS0		; TSS
GDT_ENTRY	0, 0, 0, D_DATA0		; TSS alias
GDT_ENTRY	0, 0, <400h>, D_DATA3		; Real Mode IDT
GDT_ENTRY	400h, 0, <300h>, D_DATA0	; ROM Data
GDT_ENTRY	0, 0, 0, D_CODE0		; VDM Code
GDT_ENTRY	0, 0, 0, D_DATA0		; VDM Data
GDT_ENTRY	0, 0, 0, D_DATA0		; VDM Stack
GDT_ENTRY	0, 0bh, 1000h, D_DATA0		; Mono Display
GDT_ENTRY	8000h, 0bh, 4000h, D_DATA0	; Colour Disp
GDT_ENTRY	0, 0ah, 0, D_DATA0		; EGA Low
GDT_ENTRY	0, 0ch, 0, D_DATA0		; EGA High
GDT_ENTRY	800h, 0, 66h, D_DATA0		; LOADALL
GDT_ENTRY	0, 0, 0, 0			; debugger work 1
GDT_ENTRY	0, 0, 0, 0			; debugger work	2
GDT_ENTRY	0, 0, 0, 0			; debugger work	3
GDT_ENTRY	0, 0, 0, 0			; debugger work	4
GDT_ENTRY	0, 0, 0, 0			; debugger work	5
GDT_ENTRY	0, 0, 0, 0			; debugger work	(Addresses all memory)
GDT_ENTRY	0, 0, 0, 0			; general work
GDT_ENTRY	0, 0, 0, 0			; general work
GDT_ENTRY	0, 0, 0, D_CODE0		; maps CODE segment
GDT_ENTRY	0, 0, 0, D_DATA0		; VM1_GSEL - vm trap scratch
GDT_ENTRY	0, 0, 0, D_DATA0		; VM2_GSEL - vm trap scratch
GDT_ENTRY	0, 0, 0, D_DATA0		; MBSRC_GSEL - move blk scratch
GDT_ENTRY	0, 0, 0, D_DATA0		; MBTAR_GSEL - move blk scratch
GDT_ENTRY	0, 0, 0, D_DATA0		; PAGET_GSEL - page table area
GDT_ENTRY	0, 0, 0, D_DATA0		; VDM Code - Data Alias
GDT_ENTRY	0, 0, 0, D_DATA0		; EMM1 - EMM scratch selector
GDT_ENTRY	0, 0, 0, D_DATA0		; EMM2 - EMM scratch selector
GDT_ENTRY	0, 0, 0, D_DATA0		; OEM0 entry
GDT_ENTRY	0, 0, 0, D_DATA0		; OEM1 entry
GDT_ENTRY	0, 0, 0, D_DATA0		; OEM2 entry
GDT_ENTRY	0, 0, 0, D_DATA0		; OEM3 entry
GDT_ENTRY	0, 0, 0, D_DATA0		; USER1 entry

	public	GDTLEN
GDTLEN		equ	$ - gdtstart

GDT ENDS


;***	TSS for protected Mode
;
;	This is the VDM TSS. We only use one, for loading
;	SS:SP on privilige transitions. We don't use all
;	the 286 task switching stuff.
;
;

TSS	segment
;
	TssArea 	TSS386STRUC	<>
;
;   I/O Bit Map for Virtual Mode I/O trapping
;
	public	IOBitMap
IOBitMap	label	byte
	db	2000h dup (0)		; initialize all ports to NO trapping
	db	0FFh			; last byte is all 1's

	public	TSSLEN
TSSLEN		equ	$ - tss

TSS	ends

;***	IDT for protected mode
;
;   This is the protected mode interrupt descriptor table.
;
;   The first 78h entries are defined.	Only processor exceptions and
;   hardware interrupts are fielded through the PM IDT.  Since the
;   gate DPLs are < 3, all software INTs are funneled through INT 13
;   (GP exception) and emulated.   Note that Null IDT entries and limit
;   exceptions produce the same results (GP error code) as DPL faults,
;   so we can use a truncated IDT.  This assumes no one is reprogramming
;   the 8259s base vector for some reason - don't know of any DOS apps
;   that do this.
;
IDT SEGMENT

idtstart	label byte

IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap00>,D_386INT0 ; 00 Divide Error
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap01>,D_386INT0 ; 01 Debug
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap02>,D_386INT0 ; 02 NMI/287 Error
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap03>,D_386INT0 ; 03 Breakpoint
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap04>,D_386INT0 ; 04 INTO
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap05>,D_386INT0 ; 05 BOUND/Print Screen
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap06>,D_386INT0 ; 06 Invalid Opcode
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap07>,D_386INT0 ; 07 287 Not Available

IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap08>,D_386INT0 ; 08 Double Exception/Timer
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap09>,D_386INT0 ; 09 (not on 386)/Keyboard
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap0a>,D_386INT0 ; 0A Invalid TSS/Cascade
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap0b>,D_386INT0 ; 0B Segment Not Present/COM2
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap0c>,D_386INT0 ; 0C Stack Fault/COM1
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap0d>,D_386INT0 ; 0D General Protection/LPT2
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap0e>,D_386INT0 ; 0E Page Fault/Diskette
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap0F>,D_386INT0 ; 0F Intel Reserved/LPT1

IDT_ENTRY	0, 0, 0 		; 10 [287 Error]/Video INT (This exception
					;    cannot occur on AT architecture)
IDT_ENTRY	0, 0, 0 		; 11 Equipment Check
IDT_ENTRY	0, 0, 0 		; 12 Memory Size
IDT_ENTRY	0, 0, 0 		; 13 Disk INT
IDT_ENTRY	0, 0, 0 		; 14 RS232
IDT_ENTRY	0, 0, 0 		; 15 Post&Wait, mov_blk via GP fault
IDT_ENTRY	0, 0, 0 		; 16 Keyboard
IDT_ENTRY	0, 0, 0 		; 17 Printer

IDT_ENTRY	0, 0, 0 		; 18 Resident BASIC
IDT_ENTRY	0, 0, 0 		; 19 Bootstrap
IDT_ENTRY	0, 0, 0 		; 1A Time of Day
IDT_ENTRY	0, 0, 0 		; 1B Break
IDT_ENTRY	0, 0, 0 		; 1C Timer Tick
IDT_ENTRY	0, 0, 0 		; 1D Ptr to Video Param
IDT_ENTRY	0, 0, 0 		; 1E Ptr to Disk Params
IDT_ENTRY	0, 0, 0 		; 1F Ptr to Graphics

IDT_ENTRY	0, 0, 0 		; 20 DOS
IDT_ENTRY	0, 0, 0 		; 21 DOS
IDT_ENTRY	0, 0, 0 		; 22 DOS
IDT_ENTRY	0, 0, 0 		; 23 DOS
IDT_ENTRY	0, 0, 0 		; 24 DOS
IDT_ENTRY	0, 0, 0 		; 25 DOS
IDT_ENTRY	0, 0, 0 		; 26 DOS
IDT_ENTRY	0, 0, 0 		; 27 DOS

IDT_ENTRY	0, 0, 0 		; 28 DOS
IDT_ENTRY	0, 0, 0 		; 29 DOS
IDT_ENTRY	0, 0, 0 		; 2A DOS
IDT_ENTRY	0, 0, 0 		; 2B DOS
IDT_ENTRY	0, 0, 0 		; 2C DOS
IDT_ENTRY	0, 0, 0 		; 2D DOS
IDT_ENTRY	0, 0, 0 		; 2E DOS
IDT_ENTRY	0, 0, 0 		; 2F DOS

IDT_ENTRY	0, 0, 0 		; 30 DOS
IDT_ENTRY	0, 0, 0 		; 31 DOS
IDT_ENTRY	0, 0, 0 		; 32 DOS
IDT_ENTRY	0, 0, 0 		; 33 DOS
IDT_ENTRY	0, 0, 0 		; 34 DOS
IDT_ENTRY	0, 0, 0 		; 35 DOS
IDT_ENTRY	0, 0, 0 		; 36 DOS
IDT_ENTRY	0, 0, 0 		; 37 DOS

IDT_ENTRY	0, 0, 0 		; 38 DOS
IDT_ENTRY	0, 0, 0 		; 39 DOS
IDT_ENTRY	0, 0, 0 		; 3A DOS
IDT_ENTRY	0, 0, 0 		; 3B DOS
IDT_ENTRY	0, 0, 0 		; 3C DOS
IDT_ENTRY	0, 0, 0 		; 3D DOS
IDT_ENTRY	0, 0, 0 		; 3E DOS
IDT_ENTRY	0, 0, 0 		; 3F DOS

IDT_ENTRY	0, 0, 0 		; 40 Reserved
IDT_ENTRY	0, 0, 0 		; 41 Reserved
IDT_ENTRY	0, 0, 0 		; 42 Reserved
IDT_ENTRY	0, 0, 0 		; 43 Reserved
IDT_ENTRY	0, 0, 0 		; 44 Reserved
IDT_ENTRY	0, 0, 0 		; 45 Reserved
IDT_ENTRY	0, 0, 0 		; 46 Reserved
IDT_ENTRY	0, 0, 0 		; 47 Reserved

IDT_ENTRY	0, 0, 0 		; 48 Reserved
IDT_ENTRY	0, 0, 0 		; 49 Reserved
IDT_ENTRY	0, 0, 0 		; 4A Reserved
IDT_ENTRY	0, 0, 0 		; 4B Reserved
IDT_ENTRY	0, 0, 0 		; 4C Reserved
IDT_ENTRY	0, 0, 0 		; 4D Reserved
IDT_ENTRY	0, 0, 0 		; 4E Reserved
IDT_ENTRY	0, 0, 0 		; 4F Reserved

;
;  The following table entries assume the master 8259 base vector has been
;  set up to 50h.
;
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap50>,D_386INT0 ; 50 Timer Interrupt
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap51>,D_386INT0 ; 51 Keyboard Interrupt
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap52>,D_386INT0 ; 52 Misc peripheral Interrupt
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap53>,D_386INT0 ; 53 COM2
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap54>,D_386INT0 ; 54 COM1
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap55>,D_386INT0 ; 55 2nd Parallel
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap56>,D_386INT0 ; 56 Diskette Interrupt
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap57>,D_386INT0 ; 57 1st Parallel

IDT_ENTRY	0, 0, 0 		; 58 Reserved
IDT_ENTRY	0, 0, 0 		; 59 Reserved
IDT_ENTRY	0, 0, 0 		; 5A Reserved
IDT_ENTRY	0, 0, 0 		; 5B Reserved
IDT_ENTRY	0, 0, 0 		; 5C Reserved
IDT_ENTRY	0, 0, 0 		; 5D Reserved
IDT_ENTRY	0, 0, 0 		; 5E Reserved
IDT_ENTRY	0, 0, 0 		; 5F Reserved

IDT_ENTRY	0, 0, 0 		; 60 User Programs
IDT_ENTRY	0, 0, 0 		; 61 User Programs
IDT_ENTRY	0, 0, 0 		; 62 User Programs
IDT_ENTRY	0, 0, 0 		; 63 User Programs
IDT_ENTRY	0, 0, 0 		; 64 User Programs
IDT_ENTRY	0, 0, 0 		; 65 User Programs
IDT_ENTRY	0, 0, 0 		; 66 User Programs
;;;IDT_ENTRY	0, 0, 0 		; 67 User Programs
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:EMM_pEntry>,D_386INT3 ; 67 ELIM

IDT_ENTRY	0, 0, 0 		; 68 Not Used
IDT_ENTRY	0, 0, 0 		; 69 Not Used
IDT_ENTRY	0, 0, 0 		; 6A Not Used
IDT_ENTRY	0, 0, 0 		; 6B Not Used
IDT_ENTRY	0, 0, 0 		; 6C Not Used
IDT_ENTRY	0, 0, 0 		; 6D Not Used
IDT_ENTRY	0, 0, 0 		; 6E Not Used
IDT_ENTRY	0, 0, 0 		; 6F Not Used

IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap70>,D_386INT0 ; 70 IRQ8 - Real Time Clock
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap71>,D_386INT0 ; 71 IRQ9
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap72>,D_386INT0 ; 72 IRQ10
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap73>,D_386INT0 ; 73 IRQ11
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap74>,D_386INT0 ; 74 IRQ12
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap75>,D_386INT0 ; 75 IRQ13 - 287 error
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap76>,D_386INT0 ; 76 IRQ14 - Fixed disk
IDT_ENTRY	VDMC_GSEL,<offset _TEXT:vm_trap77>,D_386INT0 ; 77 IRQ15

	public	IDTLEN
idtlen		equ	this byte - idtstart

IDT ends

PAGESEG 	SEGMENT
;***	Page Tables Area
;
;	This area is used for the page directory and page tables
;

	public	P_TABLE_CNT
P_TABLE_CNT	equ	5	; # of page tables

	public	Page_Area
Page_Area	label	byte
	db	(2+P_TABLE_CNT) * P_SIZE dup	(0)	; enough for page dir &
							; tables after page
							; alignment.
PAGESEG ENDS

	END
