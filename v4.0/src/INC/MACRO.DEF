 PAGE
;***************************************************************************;
;			     MACRO DEFINITION				    ;
;***************************************************************************;

PRINT	MACRO	MESSAGE
	MOV	DX,OFFSET MESSAGE&_PTR
	PUSH	DX
	PUSH	CS
	CALL	PRINTF
ENDM



INPUT	MACRO	MESSAGE
	PRINT	MESSAGE
	CALL PROMPT
ENDM
