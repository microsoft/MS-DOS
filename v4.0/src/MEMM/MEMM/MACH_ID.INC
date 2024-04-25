

;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
;
;   Module:   MACH_ID.INC - include for Machine ID types
;
;   Version:  0.03
;
;   Date:     April 9, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   04/09/86  Original
;
;******************************************************************************
ifndef INC_LIST
.xlist
endif

;   STANDARD ROM BIOS MACHINE TYPES used in ROM_BIOS_Machine_ID

RBMI_PC 		equ	0FFh
RBMI_PCXT		equ	0FEh
RBMI_PCjr		equ	0FDh
RBMI_PCAT		equ	0FCh
RBMI_PCConvertible	equ	0F9h
RBMI_Sys80		equ	0F8h
RBMI_CompaqPortable	equ	000h
