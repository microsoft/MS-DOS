

;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
;
;   Module:   DESC.INC - Descriptor Table Definitions for 286/386
;
;   Version:  0.02
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
;   01/31/86  Original
;   04/07/86  A 	added bit map base to 386 TSS
;   05/12/86  B 	Cleanup and segment reorganization
;   06/25/86  0.02	removed A0 macros
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;
;******************************************************************************
ifndef INC_LIST
.xlist
endif

; ---------------------------------------------------
;
; Definitions for the access byte in a descriptor
;
; ---------------------------------------------------


; Following fields are common to segment and control descriptors

D_PRES		equ	080h		; present in memory
D_NOTPRES	equ	0		; not present in memory

D_DPL0		equ	0		; Ring 0
D_DPL1		equ	020h		; Ring 1
D_DPL2		equ	040h		; Ring 2
D_DPL3		equ	060h		; Ring 3

D_SEG		equ	010h		; Segment descriptor
D_CTRL		equ	0		; Control descriptor


; Following fields are specific to control descriptors

D_TSS			equ	01h		; A Free TSS
D_LDT			equ	02h		; LDT
D_TSS_BUSY		equ	03h		; A Busy TSS
D_CALLGATE		equ	04h		; call gate
D_TASKGATE		equ	05h		; task gate
D_INTGATE		equ	06h		; interrupt gate
D_TRAPGATE		equ	07h		; trap gate
						; 8 is invalid
D_386TSS		equ	9		; available 386 TSS
						; 0ah - Intel Reserved
D_BUSY386TSS		equ	0bh		; busy 386 TSS
D_386CALL_GATE		equ	0ch		; 386 call gate
						; 0dh - Intel Reserved
D_386INT_GATE		equ	0eh		; 386 interrupt gate
D_386TRAP_GATE		equ	0fh		; 386 trap gate

; Following fields are specific to segment descriptors

D_CODE		equ	08h		; code
D_DATA		equ	0		; data

D_CONFORM	equ	04h		; if code, conforming
D_EXPDN 	equ	04h		; if data, expand down

D_RX		equ	02h		; if code, readable
D_X		equ	0		; if code, exec only
D_W		equ	02h		; if data, writable
D_R		equ	0		; if data, read only

D_ACCESSED	equ	1		; segment accessed bit


; Useful combination access rights bytes

D_DATA0 	equ	(D_PRES+D_DPL0+D_SEG+D_DATA+D_W)  ; Ring 0 rw data
D_CODE0 	equ	(D_PRES+D_DPL0+D_SEG+D_CODE+D_RX) ; Ring 0 rx code
D_TRAP0 	equ	(D_PRES+D_DPL0+D_CTRL+D_TRAPGATE) ; Ring 0 trap gate
D_INT0		equ	(D_PRES+D_DPL0+D_CTRL+D_INTGATE)  ; Ring 0 int gate
D_TSS0		equ	(D_PRES+D_DPL0+D_CTRL+D_TSS)	  ; Ring 0 TSS
D_386TSS0	equ	(D_PRES+D_DPL0+D_CTRL+D_386TSS)   ; Ring 0 TSS
D_LDT0		equ	(D_PRES+D_DPL0+D_CTRL+D_LDT)	  ; Ring 0 LDT
D_386INT0	equ	(D_PRES+D_DPL0+D_CTRL+D_386INT_GATE) ; Ring 0 int gate

;D_DATA1	equ	(D_PRES+D_DPL1+D_SEG+D_DATA+D_W)  ; Ring 1 rw data
;D_CODE1	equ	(D_PRES+D_DPL1+D_SEG+D_CODE+D_RX) ; Ring 1 rx code

;D_DATA2	equ	(D_PRES+D_DPL2+D_SEG+D_DATA+D_W)  ; Ring 2 rw data
;D_CODE2	equ	(D_PRES+D_DPL2+D_SEG+D_CODE+D_RX) ; Ring 2 rx code

D_DATA3 	equ	(D_PRES+D_DPL3+D_SEG+D_DATA+D_W)  ; Ring 3 rw data
D_CODE3 	equ	(D_PRES+D_DPL3+D_SEG+D_CODE+D_RX) ; Ring 3 rx code
D_INT3		equ	(D_PRES+D_DPL3+D_CTRL+D_INTGATE)  ; Ring 3 int gate
D_GATE3 	equ	(D_PRES+D_DPL3+D_CTRL+D_CALLGATE) ; Ring 3 call gate
D_386INT3	equ	(D_PRES+D_DPL3+D_CTRL+D_386INT_GATE) ; Ring 3 int gate

; 386 Extensions

D_B_BIT 	equ	(1 SHL 6)			; 32 bit stack offsets


; Masks for selector fields

SELECTOR_MASK	equ	0fff8h		; selector index
SEL_LOW_MASK	equ	0f8h		; mask for low byte of sel indx
TABLE_MASK	equ	04h		; table bit
RPL_MASK	equ	03h		; privilige bits
RPL_CLR 	equ	not 03h 	; clear ring bits


; Machine Status Word bits

MSW_PROTECT	equ	1		; virtual mode bit


; System IOPL

SYS_IOPL	equ	3000h		; wide open
CLEAR_IOPL	equ	0cfffh		; mask to remove IOPL bits


; Kernel Stack Size (TO BE ADDED)

STK_SIZE	equ	4000h			; TO BE ADDED


; --------------------------------------------------
;
; Macros for creating descriptor table entries
;
; --------------------------------------------------



;   structure for 386 descriptor

desc	struc
LIMIT		dw	0	; offset of last byte in segment
BASE_LOW	dw	0	; Low 16 bits of 24 bit base address
BASE_HIGH	db	0	; High 8 bits of 24 bit base address
RIGHTS		db	0	; access rights
RES386		db	0	; reserved for 386
BASE_XHI	db	0	; High 8 bits of 32 bit base address
desc	ends

; MASK for RES386

R_GRAN		equ	10000000b	; granularity bit
R_AVL		equ	00010000b	; available
R_LIMIT_XHI	equ	00001111b	; limit bits 16..19

; IDT_ENTRY - for interrupt and task gate definitions in IDT

IDT_ENTRY	macro	sel, off, acc
		dw	off		; offset
		dw	sel		; selector
		db	0		; word count, unused for trap/int gates
		db	acc		; access rights byte
		dw	0		; reserved, must be 0 for 386
endm


; GDT_ENTRY - for static initialisation of GDT entries

GDT_ENTRY	macro	BaseLow, BaseHi, Size, Access
		dw	Size - 1	; segment limit
		dw	BaseLow 	; low word of 24 bit base address
		db	BaseHi		; high byte of base address
		db	Access		; access rights byte
		dw	0		; reserved, must be 0 for 386
endm


; LDT_ENTRY - for static initialisation of LDT entries

LDT_ENTRY	macro	BaseLow, BaseHi, Size, Access
		dw	Size - 1	; segment limit
		dw	BaseLow 	; low word of 24 bit base address
		db	BaseHi		; high byte of base address
		db	Access		; access rights byte
		dw	0		; reserved, must be 0 for 386
endm


;***	286 TSS Format
;

TSS286STRUC	struc

	TSS286_BackLink dw	0		; back link selector to TSS
	TSS286_SP0	dw	0		; ring 0 sp
	TSS286_SS0	dw	0		; ring 0 ss
	TSS286_SP1	dw	0		; ring 1 sp
	TSS286_SS1	dw	0		; ring 1 ss
	TSS286_SP2	dw	0		; ring 2 sp
	TSS286_SS2	dw	0		; ring 2 ss
	TSS286_IP	dw	0		; entry point IP
	TSS286_Flags	dw	0		; flag word
	TSS286_AX	dw	0		; AX
	TSS286_CX	dw	0		; CX
	TSS286_DX	dw	0		; DX
	TSS286_BX	dw	0		; BX
	TSS286_SP	dw	0		; SP
	TSS286_BP	dw	0		; BP
	TSS286_SI	dw	0		; SI
	TSS286_DI	dw	0		; DI
	TSS286_ES	dw	0		; ES
	TSS286_CS	dw	0		; CS
	TSS286_SS	dw	0		; SS
	TSS286_DS	dw	0		; DS
	TSS286_LDT	dw	0		; LDT

TSS286STRUC	ends

;***	386 TSS Format
;

TSS386STRUC	struc

	TSS386_BackLink dw	0		; back link selector to TSS
	TSS386_Unused1	dw	0		; unused
	TSS386_ESP0lo	dw	0		; ring 0 ESP low word
	TSS386_ESP0hi	dw	0		; ring 0 ESP high word
	TSS386_SS0	dw	0		; ring 0 SS
	TSS386_Unused2	dw	0		; unused
	TSS386_ESP1	dd	0		; ring 1 ESP
	TSS386_SS1	dw	0		; ring 1 SS
	TSS386_Unused3	dw	0		; unused
	TSS386_ESP2	dd	0		; ring 2 ESP
	TSS386_SS2	dw	0		; ring 2 SS
	TSS386_Unused4	dw	0		; unused
	TSS386_CR3	dd	0		; CR3
	TSS386_EIP	dd	0		; EIP
	TSS386_EFLAGS	dd	0		; EFLAGS
	TSS386_EAX	dd	0		; EAX
	TSS386_ECX	dd	0		; ECX
	TSS386_EDX	dd	0		; EDX
	TSS386_EBX	dd	0		; EBX
	TSS386_ESP	dd	0		; ESP
	TSS386_EBP	dd	0		; EBP
	TSS386_ESI	dd	0		; ESI
	TSS386_EDI	dd	0		; EDI
	TSS386_ES	dw	0		; ES
	TSS386_Unused5	dw	0		; Unused
	TSS386_CS	dw	0		; CS
	TSS386_Unused6	dw	0		; Unused
	TSS386_SS	dw	0		; SS
	TSS386_Unused7	dw	0		; Unused
	TSS386_DS	dw	0		; DS
	TSS386_Unused8	dw	0		; Unused
	TSS386_FS	dw	0		; FS
	TSS386_Unused9	dw	0		; Unused
	TSS386_GS	dw	0		; GS
	TSS386_Unused10 dw	0		; Unused
	TSS386_LDT	dw	0		; LDT
	TSS386_Unused11 dw	0		; Unused
	TaskAttributes	dw	0		; Task Attributes
	BitMapBase	dw	0		; offset of Base of Bit Map
TSS386STRUC	ends

.list	; end of DESC.INC
