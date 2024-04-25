;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	COLORS.ASM
;
;
;
; Color CODE Definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.alpha		; arrange segments alphabetically

	INCLUDE    SEL-PAN.INC		;AN000;
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Color Index Structure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CCB_PB	       STRUC			;AN000;
CCB_A1	       DB   0			;AN000;Normal/Base Panel
CCB_A2	       DB   0			;AN000;Selection Bar/Field Highlight
CCB_A3	       DB   0			;AN000;Selected Options
CCB_A4	       DB   0			;AN000;Highlighted and Selected Options
CCB_A5	       DB   0			;AN000;Active Options
CCB_A6	       DB   0			;AN000;Direction Indicators
CCB_A7	       DB   0			;AN000;Title
CCB_A8	       DB   0			;AN000;Instructions
CCB_A9	       DB   0			;AN000;Function Keys
CCB_AA	       DB   0			;AN000;Mnemonic Highlight
CCB_AB	       DB   0			;AN000;Reserved
CCB_AC	       DB   0			;AN000;Reserved
CCB_PB	       ENDS			;AN000;
					;
	PUBLIC	WR_CIS,WR_CIS2,L_WR_CIS,L_WR_CIS2;AN000;
					;
CODE	SEGMENT PARA PUBLIC 'CODE'      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Color Index Structure (Actual color values)
;
;   Attribute	Color Attribute Assignment
;   ---------	-----------------------------------
;      A1	- Normal/Base Panel
;      A2	- Selection Bar/Field Highlight
;      A3	- Selected Options
;      A4	- Highlighted and Selected Options
;      A5	- Active Options
;      A6	- Direction Indicators
;      A7	- Title
;      A8	- Instructions
;      A9	- Function Keys
;      AA	- Mnemonic Highlight
;      AB	- Reserved
;      AC	- Reserved
;
;		     A1, A2, A3, A4, A5, A6, A7, A8, A9, AA, AB, AC
;		      �   �   �   �   �   �   �   �   �   �   �   �
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_CIS	       DB    31,113, 48,113, 31, 31, 30, 30,112, 28, 00, 00  ;AN000;Logo Scr
WR_CIS_W       EQU   $-WR_CIS					     ;AN000;
	       DB    31,127, 48,113, 31, 31, 30, 30,112, 28, 00, 00  ;AN000;Inactive scroll
	       DB   112,112,112,112,112,112,112,112,112,112, 00, 00  ;AN000;Ctxt Help
	       DB   112,112,112,112,112,112,112,112,112,112, 00, 00  ;AN000;Ctxt Help
;		DB   4Fh,112,112,112,112,112,112,112,112,112, 00, 00  ;Indx Help
	       DB   112,112,112,112,112,112,112,112,112,112, 00, 00  ;AN000;Indx Help
L_WR_CIS       EQU  ($-WR_CIS)/WR_CIS_W 			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Color Index Structure (Actual MONO values)
;
;		     A1, A2, A3, A4, A5, A6, A7, A8, A9, AA, AB, AC
;		      �   �   �   �   �   �   �   �   �   �   �   �
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_CIS2        DB     7,112, 48,112,  7,  7,  7,  7,112, 28, 00, 00  ;AN000;Logo Scr
WR_CIS2_W      EQU   $-WR_CIS2					     ;AN000;
	       DB     7,127, 48,112,  7,  7,  7,  7,112, 28, 00, 00  ;AN000;Logo Scr
	       DB   112,112,112,112,112,112,112,112,112,112, 00, 00  ;AN000;Ctxt Help
	       DB   112,112,112,112,112,112,112,112,112,112, 00, 00  ;AN000;Ctxt Help
	       DB   112,112,112,112,112,112,112,112,112,112, 00, 00  ;AN000;Indx Help
L_WR_CIS2      EQU  ($-WR_CIS2)/WR_CIS2_W			     ;AN000;
CODE	ENDS							     ;AN000;
	END							     ;AN000;
