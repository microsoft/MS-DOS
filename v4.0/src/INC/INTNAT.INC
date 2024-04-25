;	SCCSID = @(#)intnat.asm	1.1 85/04/10
BREAK <International data structure format>

;
; Current structure of the data returned by the international call
;
internat_block STRUC
Date_tim_format DW	?		; 0-USA, 1-EUR, 2-JAP
Currency_sym	DB	?		; Currency Symbol 5 bytes
		DB	?
		DB	?
		DB	?
		DB	?
Thous_sep	DB	?		; Thousands separator 2 bytes
		DB	?
Decimal_sep	DB	?		; Decimal separator 2 bytes
		DB	?
Date_sep	DB	?		; Date separator 2 bytes
		DB	?
Time_sep	DB	?		; Decimal separator 2 bytes
		DB	?
Bit_field	DB	?		; Bit values
					;   Bit 0 = 0 if currency symbol first
					;	  = 1 if currency symbol last
					;   Bit 1 = 0 if No space after currency symbol
					;	  = 1 if space after currency symbol
Currency_cents	DB	?		; Number of places after currency dec point
Time_24 	DB	?		; 1 if 24 hour time, 0 if 12 hour time
Map_call	DW	?		; Address of case mapping call (DWORD)
		DW	?		; THIS IS TWO WORDS SO IT CAN BE INITIALIZED
					;  in pieces.
Data_sep	DB	?		; Data list separator character
		DB	?
internat_block ENDS

;
; Max size of the block returned by the INTERNATIONAL call
;
internat_block_max	EQU	32
