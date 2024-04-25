;
;FORMAT Pre-defined switches
 SWITCH_S EQU		0001h			   ; System transfer
 SWITCH_V EQU		0002h			   ; Volume ID prompt
 SWITCH_BACKUP EQU	0004h
 SWITCH_C EQU		0008h
 SWITCH_T EQU		0010h
 SWITCH_N EQU		0020h
 SWITCH_1 EQU		0040h
 SWITCH_4 EQU		0080h
 SWITCH_8 EQU		0100h
 SWITCH_B EQU		0200h
 SWITCH_SELECT	EQU	0400h
 SWITCH_AUTOTEST EQU	0800h
 SWITCH_F	EQU	1000h
 SWITCH_FS	EQU	2000h

IF ShipDisk

 SWITCH_Z	EQU	4000h							;an000; dms;1 sector/cluster switch

ENDIF

;
; The following is a list of equates to define each IBM defined diskette size
; for use with the /F switch


Size_160	equ	0001h			;Flag settings for size switch	;AN000;
Size_180	equ	0002h			;				;AN000;
Size_320	equ	0004h			;				;AN000;
Size_360	equ	0008h			;				;AN000;
Size_720	equ	0010h			;				;AN000;
Size_1200	equ	0020h			;				;AN000;
Size_1440	equ	0040h			;				;AN000;



