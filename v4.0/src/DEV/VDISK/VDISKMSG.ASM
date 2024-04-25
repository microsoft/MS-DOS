	PAGE	,132
	TITLE	VDISKMSG - VDISK message library

;All messages issued by VDISK are defined here for ease in
;translation for international use.

;Each message should end with a '$' to delimit the end of the string.

CSEG	SEGMENT PARA PUBLIC 'CODE'

	PUBLIC	IMSG
	PUBLIC	ERRM1,ERRM2,ERRM3,ERRM4,ERRM5,ERRM6,ERRM7,errm8
	PUBLIC	MSG1,MSG2,MSG3,MSG4,MSG5,MSGCRLF
	PUBLIC	MSGEND

;ASCII equates

BEL	EQU	07H		;alarm
LF	EQU	0AH		;line feed
CR	EQU	0DH		;carriage return


include vdiskmsg.inc

MSGEND	LABEL	BYTE				;must be last in module
CSEG	ENDS
	END
