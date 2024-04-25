;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;    DESCRIPTION :  Code Page Switching 5202 Printer Font File
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ESC1	EQU	01BH			;
					;
CSEG	SEGMENT 			;
	ASSUME CS:CSEG,DS:CSEG		;
BEGIN:	ORG    0			;
					;
FNTHEAD:DB     0FFH,"FONT   "           ; FILE TAG
	DB     8 DUP(0) 		; RESERVED
	DW     1			; CNT OF POINTERS IN HEADER
	DB     1			; TYPE FOR INFO POINTER
	DW     OFFSET INFO,0		; POINTER TO INFO IN FILE
					;
info :	DW	5			; COUNT OF ENTRIES
					;
QUI437: DW     LEN_437			; SIZE OF ENTRY HEADER
	DW     QUI850,0 		; POINTER TO NEXT HEADER
	DW     2			; DEVICE TYPE
	DB     "5202    "               ; DEVICE SUBTYPE ID
	DW     437			; CODE PAGE ID
	DW     3 DUP(0) 		; RESERVED
	DW     OFFSET DATA437,0 	; POINTER TO FONTS
LEN_437 EQU    ($-QUI437)-2		;
					;
QUI850: DW     LEN_850			; SIZE OF ENTRY HEADER
	DW     QUI860,0 		; POINTER TO NEXT HEADER
	DW     2			; DEVICE TYPE
	DB     "5202    "               ; DEVICE SUBTYPE ID
	DW     850			; CODE PAGE ID
	DW     3 DUP(0) 		; RESERVED
	DW     OFFSET DATA850,0 	; POINTER TO FONTS
LEN_850 EQU    ($-QUI850)-2		;
					;
QUI860: DW     LEN_860			; SIZE OF ENTRY HEADER
	DW     QUI863,0 		; POINTER TO NEXT HEADER
	DW     2			; DEVICE TYPE
	DB     "5202    "               ; DEVICE SUBTYPE ID
	DW     860			; CODE PAGE ID
	DW     3 DUP(0) 		; RESERVED
	DW     OFFSET DATA860,0 	; POINTER TO FONTS
LEN_860 EQU    ($-QUI860)-2		;
					;
QUI863: DW     LEN_863			; SIZE OF ENTRY HEADER
	DW     QUI865,0 		; POINTER TO NEXT HEADER
	DW     2			; DEVICE TYPE
	DB     "5202    "               ; DEVICE SUBTYPE ID
	DW     863			; CODE PAGE ID
	DW     3 DUP(0) 		; RESERVED
	DW     OFFSET DATA863,0 	; POINTER TO FONTS
LEN_863 EQU    ($-QUI863)-2		;
					;
QUI865: DW     LEN_865			; SIZE OF ENTRY HEADER
	DW     0,0			; POINTER TO NEXT HEADER
	DW     2			; DEVICE TYPE
	DB     "5202    "               ; DEVICE SUBTYPE ID
	DW     865			; CODE PAGE ID
	DW     3 DUP(0) 		; RESERVED
	DW     OFFSET DATA865,0 	; POINTER TO FONTS
LEN_865 EQU    ($-QUI865)-2		;
					;
DATA437:DW     1			; CART/NON-CART
	DW     1			; # OF FONTS
	DW     16			; LENGTH OF DATA
	DW     2			; SELECTION TYPE
	DW     12			; SELECTION length
	DB     ESC1,91,84,5,0,00,00,001H,0B5H,00   ; select code page ******
	dB     ESC1,"6"                  ;
					;
DATA850:DW     1			; CART/NON-CART
	DW     1			; # OF FONTS
	DW     16			; LENGTH OF DATA
	DW     2			; SELECTION TYPE
	DW     12			; SELECTION length
	DB     ESC1,91,84,5,0,00,00,003H,052H,00   ; select code page ******
	dB     ESC1,"6"                  ;
					;
DATA860:DW     1			; CART/NON-CART
	DW     1			; # OF FONTS
	DW     16			; LENGTH OF DATA
	DW     2			; SELECTION TYPE
	DW     12			; SELECTION length
	DB     ESC1,91,84,5,0,00,00,003H,05CH,00   ; select code page ******
	dB     ESC1,"6"                  ;
					;
DATA863:DW     1			; CART/NON-CART
	DW     1			; # OF FONTS
	DW     16			; LENGTH OF DATA
	DW     2			; SELECTION TYPE
	DW     12			; SELECTION length
	DB     ESC1,91,84,5,0,00,00,003H,05FH,00   ; select code page ******
	dB     ESC1,"6"                  ;
					;
DATA865:DW     1			; CART/NON-CART
	DW     1			; # OF FONTS
	DW     16			; LENGTH OF DATA
	DW     2			; SELECTION TYPE
	DW     12			; SELECTION length
	DB     ESC1,91,84,5,0,00,00,003H,061H,00   ; select code page ******
	dB     ESC1,"6"                  ;

include copyrigh.inc

CSEG	ENDS				;
	END BEGIN			;
