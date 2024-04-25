

;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
;
;   Module:   OEMDEP.INC
;
;   Version:  0.04
;
;   Date:     June 13, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   06/13/86  Original
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   07/05/86  0.04	Moved Diagbyte to _DATA
;   07/06/86  0.04	Change from _DATA assume to DGROUP
;   08/06/86  0.05	Broke out OEMPROC.ASM from OEMDEP.INC
;
;******************************************************************************
ifndef INC_LIST
.xlist
endif


_TEXT	segment

extrn	MaskIntAll:near 		; Mask interrupts routine
extrn	RestIntMask:near		; restore interrupt mask routine

extrn	Map_Lin_OEM:near		; MapLinear hook
extrn	UMap_Lin_OEM:near		; UnMapLinear hook
extrn	MB_Map_Src:near 		; Move block map source hook
extrn	MB_Map_Dest:near		; Move block map destination hook
extrn	MB_Start:near			; Move block start move hook

_TEXT	ends


LAST	segment

extrn	VerifyMachine:near		; Verify machine valid for software

LAST	ends

ifndef	NOHIMEM 			; only for high memory

;Define routines in OEMPROC module

_TEXT	segment

extrn	HwMemLock:near
extrn	HwMemUnlock:near

_TEXT	ends

LAST	segment

extrn	hbuf_chk:near
extrn	HiAlloc:near
extrn	HiSysAlloc:near
extrn	HImod:near
extrn	LockROM:near
extrn	UnLockROM:near

LAST	ends

endif

;******************************************************************************
;
;   HwTabUnlock - unlocks high system RAM - makes tables writeable
;
;	EXIT:	FS points to DIAG segment
;		high system RAM writeable
;
HwTabUnlock	MACRO
ifndef	NOHIMEM 			; only for high memory
	call	HwMemUnlock
endif
	ENDM

;******************************************************************************
;
;   HwTabLock - update client's hi system RAM write locks state
;
;	ENTRY:	CS = _TEXT
;		CS:[DiagByte] = last byte written to diag byte by user.
;
;	EXIT:	high system RAM write protect ON or OFF depenending on
;		write protect bit in CS:[DiagByte].
;		Bit 1 = 0 => write protect ON
;		Bit 1 = 1 => write protect OFF
;
HwTabLock	MACRO
ifndef	NOHIMEM 			; only for high memory
	call	HwMemLock
endif

	ENDM

.list	; end of OEMDEP.INC
