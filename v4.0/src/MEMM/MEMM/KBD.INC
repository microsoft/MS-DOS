

;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
;
;   Module:   KBD.INC - KBD.ASM Structures and Equates
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
;   05/12/86  A 	Cleanup and segment reorganization
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;
;******************************************************************************
;
;   Functional Description:
;
;******************************************************************************
ifndef INC_LIST
.xlist
endif

;	SCCSID = @(#)keybxx.inc 1.1 85/10/09
;------------------------------------------------------
;
;   Keybxx.inc - Define struct and equates for KeybXX and Keyb??.ASM .
;
;	Keyb?? - denotes any of the files keybfr, keybgr, keybit, keybuk,
;		keybsp or keybdv (Dvorak keyboard).
;


esc		equ	1bh


KbData		equ	60h	; I/O Ports for keyboard
KbCtl		equ	61h
KbStatus	equ	64h

PCBeepFreq	equ	48h	; Count for Beep frequency
PCBeepDur	equ	105h	; Number of Beep half cycles
ATBeepFreq	equ	0CEh	; Use larger values since AT faster
ATBeepDur	equ	82h

InsState	equ	80h	; Bit values for BreakState and KeyState
CapsState	equ	40h
NumState	equ	20h
ScrollState	equ	10h
HoldState	equ	08h


AltShift	equ	08h	; Bit values for KeyState
CtrlShift	equ	04h
LeftShift	equ	02h
RightShift	equ	01h


BufFull 	equ	02h	; Bit value for KbStatus port


ATResend	equ	0FEh	; AT keyboard commands
ATAck		equ	0FAh


KBErr		equ	080h	; Bit values for ATKbFlags
KBSndLed	equ	040h
KBResend	equ	020h
KBAck		equ	010h
SysShift	equ	004h	;SysReq key held down


;***	AccChStruc - Structure for information about accent keys
;
;	Contains scan and char codes returned for all shift combinations
;	with an accent key.
;
;	Note: an accent key is an accent in both normal and shifted mode.
;
AccChStruc	struc
normal	dw	0	;chr & scan code for unshifted accent key
shift	dw	0	; "     "     "  for shifted      "    "
ctrl	dw	-1
alt	dw	-1
AccChStruc	ends

.list		; end of KBD.INC
