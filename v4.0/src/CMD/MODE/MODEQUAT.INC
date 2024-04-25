;---------------------- POSSIBLE VALUES FOR "machine_type" -------------------

;See "get_machine_type" for details on how "machine_type" is used


PC1	       EQU   0FFH	       ;scalar value and model byte for PC1
PCXT	       EQU   0FEH	       ;scalar value for XT, only one because each release is same to MODE
PCJr	       EQU   0FDH	       ;scalar value for PCJr
AT1	       EQU   0FCH	       ;scalar value for first release of AT and VAIL
AT2	       EQU   000H	       ;scalar value and submodel byte for second release of AT
AT3	       EQU   001H	       ;scalar value and submodel byte for internal release of third version of AT
AT4	       EQU   006H	       ;scalar value and submodel byte for AT on or later than 11/15/85
XT286	       EQU   002H	       ;scalar value and submodel byte for XT 286
Convertible    EQU   0F9H	       ;scalar value and model byte for PC Convertible
PS2Model30     EQU   0FAH	       ;scalar value and model byte for Personal System/2 Model 30
PS2Model50     EQU   004H	       ;scalar value and submodel byte for Personal System/2 Model 50
PS2Model60     EQU   005H	       ;scalar value and model byte for Personal System/2 Model 60
PS2Model80     EQU   0F8H	       ;scalar value and model byte for Personal System/2 Model 80 and SNOWMASS
Vail	       EQU   009H	       ;AN001;scalar value and submodel byte for VAIL


bogus			      EQU   88H 	;completely invalid value
COM1			      EQU   0C1H	;used by invoke
COM2			      EQU   0C2H	;used by invoke
COM3			      EQU   0C3H	;used by invoke
COM4			      EQU   0C4H	;used by invoke
false	EQU	00H
true	EQU	0FFH


;FLAGS field bit(s) values

Left_Align		equ	0	;00xxxxxx
Right_Align		equ	80h	;10xxxxxx

Unsgn_Bin_Byte	  equ	  11h	  ;a0010001


PUBLIC	 bogus

;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;  AX001 - P4543: Add VAIL and SNOWMASS to legal choices for 19200 baud

;บ											  บ
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ

