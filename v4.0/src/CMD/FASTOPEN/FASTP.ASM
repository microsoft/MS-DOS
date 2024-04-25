	PAGE	90,132			;A2
	TITLE	fastp.asm - fastopen SYSTEM COMMAND LINE PARSER
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: fastp.asm
;
; DESCRIPTIVE NAME: Include the DOS system PARSER in the SEGMENT
;		    configuration expected by the modules of fastopen.
;
;FUNCTION: The common code of the DOS command line PARSER is optimized by
;	   the setting of certain switches that cause the conditional
;	   assembly of only the required portions of the common PARSER.
;
; ENTRY POINT: SYSPARSE, near
;
; INPUT:
;	ES - has seg id of the SEGMENT
;	     that contains the input control blocks,
;	     defined below.
;
;	DI - offset into ES of the PARMS INPUT BLOCK
;
;	DS - has seg id of the SEGMENT
;	     that contains the DOS input COMMAND
;	     string, which is originally presented at 81h
;	     in the PSP.
;
;	SI - offset into DS of the text of the DOS input COMMAND string
;	     as originally presented at 81H in the PSP.
;
;	DX - zero
;
;	CX - ordinal value, intially zero, updated on each subsequent call
;	     to the value returned in CX on the previous call.
;
;	CS - points to the segment containing the
;	     INCLUDE PARSE.ASM statement
;
;	DS - also points to the segment containing the INCLUDE
;	     PARSE.ASM statement.
;
; EXIT-NORMAL:	Output registers:
;	 AX - return code:
;	    RC_No_Error     equ     0	 ; No error
;	    RC_EOL	    equ     -1	 ; End of command line
;
;	 DX - Offset into ES of the selected RESULT BLOCK.
;	 BL - terminated delimiter code
;	 CX - new operand ordinal
;	 SI - set past scanned operand
;
; EXIT-ERROR: Output registers:
;	 AX - return code:
;	    RC_Too_Many     equ     1	 ; Too many operands
;	    RC_Op_Missing   equ     2	 ; Required operand missing
;	    RC_Not_In_SW    equ     3	 ; Not in switch list provided
;	    RC_Not_In_Key   equ     4	 ; Not in keyword list provided
;	    RC_Out_Of_Range equ     6	 ; Out of range specified
;	    RC_Not_In_Val   equ     7	 ; Not in value list provided
;	    RC_Not_In_Str   equ     8	 ; Not in string list provided
;	    RC_Syntax	    equ     9	 ; Syntax error
;
; INTERNAL REFERENCES:
;    ROUTINES: SYSPARSE:near (INCLUDEd in PARSE.ASM)
;
;    DATA AREAS: none
;
; EXTERNAL REFERENCES:
;    ROUTINES: none
;
;    DATA AREAS: control blocks pointed to by input registers.
;
; NOTES:
;
;	 For LINK instructions, refer to the PROLOG of the main module,
;	 fastopen.asm.
;
; REVISION HISTORY: A000 Version 4.00: add PARSER, System Message Handler,
;
; COPYRIGHT: "MS DOS FASTOPEN Utility"
;	     "Version 4.00 (C)Copyright 1988 Microsoft  "
;	     "Licensed Material - Property of Microsoft  "
;
;PROGRAM AUTHOR: DOS 4.00 P L
;
;****************** END OF SPECIFICATIONS *****************************
	IF1				;					;AN000;
	    %OUT    COMPONENT=fastopen, MODULE=fastp.asm...
	ENDIF				;					;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =
	HEADER	<MACRO DEFINITION>	;					;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =

HEADER	MACRO	TEXT			;;					;AN000;
.XLIST
	SUBTTL	TEXT
.LIST
	PAGE				;;					;AN000;
	ENDM				;;					;AN000;

; =  =	=  =  =  =  =  =  =  =	=  =
	HEADER	<SYSPARSE - SYSTEM COMMAND LINE PARSER> ;			;AN000;
CSEG_INIT    SEGMENT PARA PUBLIC 'CODE'      ;
	ASSUME	CS:CSEG_INIT,DS:CSEG_INIT,ES:CSEG_INIT

	PUBLIC	SYSPARSE		;SUBROUTINE ENTRY POINT 		;AN000;


INCSW	EQU	1			;INCLUDE PSDATA.INC			;AN000;
FARSW	EQU	0			;CALL THE PARSER BY NEAR CALL
DATESW	EQU	0			;SUPPRESS DATE CHECKING 		;AN000;
TIMESW	EQU	0			;SUPPRESS TIME CHECKING 		;AN000;
FILESW	EQU	0			;SUPPRESS CHECKING FILE SPECIFICATION	;AN000;
CAPSW	EQU	0			;SUPPRESS FILE TABLE CAPS		;AN000;
CMPXSW	EQU	1			;SUPPRESS CHECKING COMPLEX LIST
DRVSW	EQU	1			;SUPPRESS SUPPORT OF DRIVE ONLY FORMAT
QUSSW	EQU	0			;SUPPRESS SUPPORT OF QUOTED STRING FORMAT ;AN000;
NUMSW	EQU	1			;SUPPRESS CHECKING NUMERIC VALUE
KEYSW	EQU	0			;SUPPRESS KEYWORD SUPPORT		;AN000;
SWSW	EQU	1			;DO SUPPORT SWITCHES			;AN000;
VAL1SW	EQU	0			;SUPPRESS SUPPORT OF VALUE DEFINITION 1 ;AN000;
VAL2SW	EQU	0			;SUPPRESS SUPPORT OF VALUE DEFINITION 2 ;AN000;
VAL3SW	EQU	0			;DO SUPPORT VALUE DEFINITION 3


	IF1				;					;AN000;
	    %OUT    COMPONENT=fastopen, SUBCOMPONENT=PARSE, MODULE=PARSE.ASM...
	    %OUT    COMPONENT=fastopen, SUBCOMPONENT=PARSE, MODULE=PSDATA.INC...
	ENDIF				;					;AN000;
	INCLUDE PARSE.ASM		;					;AN000;
CSEG_INIT  ENDS 			   ;
	END				;					;AN000;
