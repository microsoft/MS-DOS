

;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
;
;   Module:   VDMSEG.INC - Segment Ordering and attributes for VDM
;
;   Version:  0.04
;
;   Date:     May 12, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;	      Original
;   05/12/86  A 	Cleanup and segment reorganization
;   06/03/86  C 	changed order and added STACK and STACK0,STACK0_SIZE
;   06/06/86  C 	changed CODE to _TEXT and DATA to _DATA
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   07/05/86  0.04	Re-organized to allow code seg move
;   06/03/88		add use16 to all segments
;
;******************************************************************************
ifndef INC_LIST
.xlist
endif

ifndef	NOHIMEM
;
;  SEGMENT definitions and order
;

;*     CODE area containing EMM/VDISK headers and writeable Real mode code
R_CODE		SEGMENT PARA USE16 PUBLIC 'R_CODE'
R_CODE		ENDS

;*	Contains initialized variables and variables used at startup.
_DATA		SEGMENT WORD USE16 PUBLIC 'DATA'
_DATA		ENDS

;* read only constants for C
CONST		SEGMENT WORD USE16 PUBLIC 'CONST'
CONST		ENDS

;* uninitialized static data for C
_BSS		SEGMENT WORD USE16 PUBLIC 'BSS'
_BSS		ENDS

;* Ring 0 stack in VDM
STACK		SEGMENT PARA USE16 STACK 'STACK'
STACK		ENDS

;
; data group
;
DGROUP	GROUP	_DATA,CONST,_BSS

;*	The code comprising the system.  Must be READ-ONLY in real mode.
_TEXT		SEGMENT BYTE USE16 PUBLIC 'CODE'
_TEXT		ENDS

;*	Global Descriptor Table
GDT		SEGMENT PARA USE16 COMMON
GDT		ENDS

;*	Local Descriptor Table
LDT		SEGMENT PARA USE16 COMMON
LDT		ENDS

;*	Interrupt Descriptor Table
IDT		SEGMENT PARA USE16 COMMON
IDT		ENDS

;*	Task State Segment
TSS		SEGMENT PARA USE16 COMMON
TSS		ENDS

;*	Contains initialized variables and variables used at startup.
PAGESEG 	SEGMENT PARA USE16 PUBLIC 'PAGES'
PAGESEG 	ENDS

;*	Initialization code and variables.  Used for data later.
;	Must be last segment.
LAST		SEGMENT PARA USE16 PUBLIC 'LAST'
LAST		ENDS



else
;
;  SEGMENT definitions and order
;

;*     CODE area containing EMM/VDISK headers and writeable Real mode code
R_CODE		SEGMENT PARA USE16 PUBLIC 'R_CODE'
R_CODE		ENDS

;*	Global Descriptor Table
GDT		SEGMENT PARA USE16 COMMON
GDT		ENDS

;*	Local Descriptor Table
LDT		SEGMENT PARA USE16 COMMON
LDT		ENDS

;*	Interrupt Descriptor Table
IDT		SEGMENT PARA USE16 COMMON
IDT		ENDS

;*	Task State Segment
TSS		SEGMENT PARA USE16 COMMON
TSS		ENDS

;*	Contains initialized variables and variables used at startup.
_DATA		SEGMENT WORD USE16 PUBLIC 'DATA'
_DATA		ENDS

;* read only constants for C
CONST		SEGMENT WORD USE16 PUBLIC 'CONST'
CONST		ENDS

;* uninitialized static data for C
_BSS		SEGMENT WORD USE16 PUBLIC 'BSS'
_BSS		ENDS

;* Ring 0 stack in VDM
STACK		SEGMENT PARA USE16 STACK 'STACK'
STACK		ENDS

;
; data group
;
DGROUP	GROUP	_DATA,CONST,_BSS

;*	The code comprising the system.  Must be READ-ONLY in real mode.
_TEXT		SEGMENT BYTE USE16 PUBLIC 'CODE'
_TEXT		ENDS

;*	Contains dynamically sized emm data structures.
VDATA		SEGMENT WORD USE16 PUBLIC 'VDATA'
VDATA		ENDS

;*	Contains initialized variables and variables used at startup.
PAGESEG 	SEGMENT PARA USE16 PUBLIC 'PAGES'
PAGESEG 	ENDS

;*	Initialization code and variables.  Used for data later.
;	Must be last segment.
LAST		SEGMENT PARA USE16 PUBLIC 'LAST'
LAST		ENDS
endif
;
;  segment related equates
;

; ring 0 stack size
STACK0_SIZE	equ	512

.list	; end of VDMSEG.INC

