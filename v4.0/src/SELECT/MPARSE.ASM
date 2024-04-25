.ALPHA					;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	DUMMY DATA SEGMENT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	SEGMENT BYTE PUBLIC 'DATA'      ;AN000;
DATA	       ENDS			;AN000;DATA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	PARSER INFORMATION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.XLIST					;AN000;
FARSW	EQU	1			;AN000;
DATESW	EQU	0			;AN000;
TIMESW	EQU	0			;AN000;
FILESW	EQU	0			;AN000;
CAPSW	EQU	0			;AN000;
CMPXSW	EQU	0			;AN000;
DRVSW	EQU	0			;AN000;
QUSSW	EQU	0			;AN000;
KEYSW	EQU	1			;AN000;
SWSW	EQU	0			;AN000;
VAL1SW	EQU	1			;AN000;
VAL2SW	EQU	1			;AN000;
VAL3SW	EQU	1			;AN000;
.LIST					;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PARSER	SEGMENT PARA PUBLIC 'PARSER'    ;AN000;
	ASSUME	CS:PARSER,DS:DATA,ES:DATA;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	SYSPARSE		;AN000;
PAGE					;AN000;
	INCLUDE PARSE.ASM		;AN000;

PARSER	ENDS				;AN000;
	END				;AN000;
