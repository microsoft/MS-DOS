

;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
;
;   Module:   VDMSEL.INC - Selector Definitions for MEMM
;
;   Version:  0.05
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
;   06/07/86  C 	merged with module from Rick
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   07/10/86  0.05	Changed CODE_GSEL to RCODEA_GSEL
;   07/20/88		Remove debugger selectors
;
;******************************************************************************
ifndef INC_LIST
.xlist
endif


;
;	DESCRIPTION
;
;	These are the fixed selector numbers for the GDT and LDT
;
;	All are declared with RPL = 0 so they can easily be used
;	as table indices.
;
;	Do not change anything without consulting files which include
;	this one. Add new selectors to the end and update the
;	gdt declaration and initialisation code elsewhere.
;

;	Define LDT and GDT table bits

TAB_LDT 	equ	4h
TAB_GDT 	equ	0h


;	Define GDT selectors

GDTD_GSEL	equ	008h OR TAB_GDT		; gdt data alias
IDTD_GSEL	equ	010h OR TAB_GDT		; idt data alias
LDT_GSEL	equ	018h OR TAB_GDT		; ldt
LDTD_GSEL	equ	020h OR TAB_GDT		; ldt data alias
TSS_GSEL	equ	028h OR TAB_GDT		; tss
TSSD_GSEL	equ	030h OR TAB_GDT		; tss data alias
RM_IDT_GSEL	equ	038h OR TAB_GDT		; real mode idt (locn 0)
ROMDATA_GSEL	equ	040h OR TAB_GDT		; maps 40:0 - DON'T CHANGE!!
VDMC_GSEL	equ	048h OR TAB_GDT		; VDM Code selector
VDMD_GSEL	equ	050h OR TAB_GDT		; VDM Data Selector
VDMS_GSEL	equ	058h OR TAB_GDT		; VDM stack selector
MONO_GSEL	equ	060h OR TAB_GDT		; monochrome display memory
COLOUR_GSEL	equ	068h OR TAB_GDT		; colour display memory
EGA1_GSEL	equ	070h OR TAB_GDT		; first EGA sel
EGA2_GSEL	equ	078h OR TAB_GDT		; second EGA sel
LOADALL_GSEL	equ	080h OR TAB_GDT		; loadall buffer - DON'T CHANGE
;DEBC_GSEL	equ	088h or TAB_GDT		; debugger work descr
;DEBD_GSEL	equ	090h or TAB_GDT		; debugger work descr
;DEBW1_GSEL	equ	098h or TAB_GDT		; debugger work descr
;DEBW2_GSEL	equ	0A0h or TAB_GDT 	; debugger work descr
DEB1_GSEL	equ	088h or TAB_GDT		; deb386 word descr
DEB2_GSEL	equ	090h or TAB_GDT		; deb386 word descr
DEB3_GSEL	equ	098h or TAB_GDT		; deb386 word descr
DEB4_GSEL	equ	0A0h or TAB_GDT		; deb386 word descr
DEB5_GSEL	equ	0A8h or TAB_GDT		; deb386 word descr
DEBX_GSEL	equ	0B0h or TAB_GDT		; deb386 descr for all of addressing space
K_PUTC286	equ	0B8h OR TAB_GDT 	; 286 call gate to kputc
K_GETC286	equ	0C0h OR TAB_GDT 	; 286 call gate to kgetc
RCODEA_GSEL	equ	0C8h OR TAB_GDT 	; data alias for R_CODE segment
VM1_GSEL	equ	0D0h OR TAB_GDT 	; scratch for vm handler
VM2_GSEL	equ	0D8h OR TAB_GDT 	; scratch for vm handler
MBSRC_GSEL	equ	0E0h OR TAB_GDT 	; source sel for move blk
MBTAR_GSEL	equ	0E8h OR TAB_GDT 	; target sel for move blk
PAGET_GSEL	equ	0F0h OR TAB_GDT 	; page table area sel
VDMCA_GSEL	equ	0F8h OR TAB_GDT 	; VDM code segment alias
EMM1_GSEL	equ	100h OR TAB_GDT 	; EMM scratch selector
EMM2_GSEL	equ	108h OR TAB_GDT 	; EMM scratch selector
OEM0_GSEL	equ	110h OR TAB_GDT 	; OEM specific selector
OEM1_GSEL	equ	118h OR TAB_GDT 	; OEM specific selector
OEM2_GSEL	equ	120h OR TAB_GDT 	; OEM specific selector
OEM3_GSEL	equ	128h OR TAB_GDT 	; OEM specific selector
USER1_GSEL	equ	130h OR TAB_GDT		; USER data structure 

.list	; end of VDMSEL.INC
