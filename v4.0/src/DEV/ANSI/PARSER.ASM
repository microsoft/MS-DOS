PAGE	    ,132
TITLE	    PARSE CODE AND CONTROL BLOCKS FOR ANSI.SYS

;****************** START OF SPECIFICATIONS **************************
;
;  MODULE NAME: PARSER.ASM
;
;  DESCRIPTIVE NAME: PARSES THE DEVICE= STATEMENT IN CONFIG.SYS FOR
;		     ANSI.SYS
;
;  FUNCTION: THE COMMAND LINE PASSED TO ANSI.SYS IN THE CONFIG.SYS
;	     STATEMENT IS PARSED TO CHECK FOR THE /X SWITCH. A FLAG
;	     IS CLEARED IF NOT FOUND.
;
;  ENTRY POINT: PARSE_PARM
;
;  INPUT: DS:SI POINTS TO EVERYTHING AFTER DEVICE=
;
;  AT EXIT:
;     NORMAL: SWITCH FLAGS WILL BE SET IF /X or /L IS FOUND
;
;     ERROR: CARRY SET
;
;  INTERNAL REFERENCES:
;
;     ROUTINES: SYSLOADMSG - MESSAGE RETRIEVER LOADING CODE
;		SYSDISPMSG - MESSAGE RETRIEVER DISPLAYING CODE
;		PARM_ERROR - DISPLAYS ERROR MESSAGE
;		SYSPARSE - PARSING CODE
;
;     DATA AREAS: PARMS - PARSE CONTROL BLOCK FOR SYSPARSE
;
;  EXTERNAL REFERENCES:
;
;     ROUTINES: N/A
;
;     DATA AREAS: SWITCH - BYTE FLAG FOR EXISTENCE OF SWITCH PARAMETER
;
;  NOTES:
;
;  REVISION HISTORY:
;	    A000 - DOS Version 4.00
;
;      Label: "DOS ANSI.SYS Device Driver"
;	      "Version 4.00 (C) Copyright 1988 Microsoft"
;	      "Licensed Material - Program Property of Microsoft"
;
;****************** END OF SPECIFICATIONS ****************************
;Modification history**********************************************************
;AN001; P1529 ANSI /x /y gives wrong error message		   10/8/87 J.K.
;AN002; D397  /L option for "Enforcing" the line number            12/17/87 J.K.
;AN003; D479  An option to disable the extended keyboard functions 02/12/88 J.K.
;******************************************************************************


INCLUDE     ANSI.INC	    ; ANSI equates and structures				 ;AN000;
.XLIST
INCLUDE     STRUC.INC	    ; Structured macros 					 ;AN000;

INCLUDE     SYSMSG.INC	    ; Message retriever code					 ;AN000;
MSG_UTILNAME <ANSI>	    ; Let message retriever know its ANSI.SYS			 ;AN000;
.LIST

PUBLIC	    PARSE_PARM	     ; near procedure for parsing DEVICE= statement		 ;AN000;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Set assemble switches for parse code that is not required!!
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DateSW	      EQU     0 								 ;AN000;
TimeSW	      EQU     0 								 ;AN000;
CmpxSW	      EQU     0 								 ;AN000;
DrvSW	      EQU     0 								 ;AN000;
QusSW	      EQU     0 								 ;AN000;
NumSW	      EQU     0 								 ;AN000;
KeySW	      EQU     0 								 ;AN000;
Val1SW	      EQU     0 								 ;AN000;
Val2SW	      EQU     0 								 ;AN000;
Val3SW	      EQU     0 								 ;AN000;


CODE	      SEGMENT  PUBLIC BYTE
	      ASSUME CS:CODE

.XLIST
MSG_SERVICES <MSGDATA>									 ;AN000;
MSG_SERVICES <DISPLAYmsg,LOADmsg,CHARmsg>						 ;AN000;
MSG_SERVICES <ANSI.CL1> 								 ;AN000;
MSG_SERVICES <ANSI.CL2> 								 ;AN000;
MSG_SERVICES <ANSI.CLA> 								 ;AN000;

INCLUDE     PARSE.ASM	    ; Parsing code						 ;AN000;
.LIST


EXTRN	    SWITCH_X:BYTE	 ; /X switch flag						 ;AN000;
extrn	    Switch_L:Byte	 ;AN002; /L switch flag
extrn	    Switch_K:Byte	 ;AN003; /K switch

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PARM control blocks for ANSI
; Parsing DEVICE= statment from CONFIG.SYS
;
; DEVICE=[d:][path]ANSI.SYS [/X]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
											 ;AN000;
PARMS	       LABEL WORD								 ;AN000;
	       DW	PARMSX								 ;AN000;
	       DB	0		   ; no extra delimeters or EOLs.		 ;AN000;
											 ;AN000;
PARMSX	       LABEL BYTE								 ;AN000;
	       DB	1,1		   ;AN001; 1 valid positional operand
	       DW	FILENAME	   ;AN001; filename
	       DB	1		   ;AN002; 1 switche definition in the following
	       DW	Switches	   ;AN002;
	       DB	0		   ;AN001; no keywords
											 ;AN000;
FILENAME       LABEL WORD								 ;AN000;
	       DW	0200H		   ; file spec					 ;AN000;
	       DW	0001H		   ; cap by file table				 ;AN000;
	       DW	RESULT_BUF	   ; result					 ;AN000;
	       DW	NOVALS		   ; no value checking done			 ;AN000;
	       DB	0		   ; no switch/keyword synonyms 		 ;AN000;
											 ;AN000;
Switches       LABEL WORD								 ;AN000;
	       DW	0		   ; switch with no value			 ;AN000;
	       DW	0		   ; no functions				 ;AN000;
	       DW	RESULT_BUF	   ; result					 ;AN000;
	       DW	NOVALS		   ; no value checking done			 ;AN000;
	       DB	3		   ;AN002;AN003; 3 switch synonym
X_SWITCH       DB	"/X",0             ;AN002; /X name
L_SWITCH       DB	"/L",0             ;AN002; /L
K_SWITCH       DB	"/K",0             ;AN003; /K

NOVALS	       LABEL BYTE								 ;AN000;
	       DB	0		   ; no value checking done			 ;AN000;

RESULT_BUF     LABEL BYTE								 ;AN000;
	       DB	?		   ; type returned (number, string, etc.)	 ;AN000;
	       DB	?		   ; matched item tag (if applicable)		 ;AN000;
SYNONYM_PTR    DW	0		   ; synonym ptr (if applicable)		 ;AN000;
	       DD	?		   ; value					 ;AN000;
											 ;AN000;
SUBLIST        LABEL DWORD		   ; list for substitution			 ;AN000;
	       DB	SUB_SIZE							 ;AN000;
	       DB	0								 ;AN000;
	       DD	?								 ;AN000;
	       DB	1								 ;AN000;
	       DB	LEFT_ASCIIZ							 ;AN000;
	       DB	UNLIMITED							 ;AN000;
	       DB	1								 ;AN000;
	       DB	" "                                                              ;AN000;

Old_SI		dw	?			;AN001;
Saved_Chr	db	0			;AN001;
Continue_Flag	db	ON			;AN002;
Parse_Err_Flag	db	OFF			;AN002;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARSE_PARM
;
; FUNCTION:
; THIS PROCEDURE PARSES THE DEVICE= PARAMETERS FROM THE INIT REQUEST
; BLOCK. ERROR MESSAGES ARE DISPLAYED ACCORDINGLY.
;
; AT ENTRY: DS:SI POINTS TO EVERYTHING AFTER THE DEVICE= STATEMENT
;
; AT EXIT:
;    NORMAL: CARRY CLEAR - SWITCH FLAG BYTE SET TO 1 IF /X FOUND
;
;    ERROR: CARRY SET
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSE_PARM    PROC     NEAR								 ;AN000;
	      CALL     SYSLOADMSG		; load message				 ;AN000;
	      .IF C NEAR								 ;AN000;
		CALL	 SYSDISPMSG		; display error message 		 ;AN000;
		STC				; ensure carry still set		 ;AN000;
	      .ELSE NEAR								 ;AN000;
		PUSH	 CS			; establish ES ..			 ;AN000;
		POP	 ES			; addressability to data		 ;AN000;
		LEA	 DI,PARMS		; point to PARMS control block		 ;AN000;
		XOR	 CX,CX			; clear both CX and DX for		 ;AN000;
		XOR	 DX,DX			;  SYSPARSE				 ;AN000;
		CALL	 SYSPARSE		; move pointer past file spec		 ;AN000;
		mov	 Switch_L, OFF		;AN002;
		mov	 Switch_X, OFF		;AN002;
		.WHILE <Continue_Flag EQ ON>	;AN002;
		     mov Old_SI, SI		;AN001;to be use by PARM_ERROR
		     call SysParse		;AN002;
		     .IF <AX EQ RC_EOL> 	;AN002;
			mov Continue_Flag, OFF	;AN002;
		     .ELSE			;AN002;
			.IF <AX NE RC_NO_ERROR> ;AN002;
			   mov Continue_Flag, OFF    ;AN002;
			   mov Switch_X, OFF	;AN002;
			   mov Switch_L, OFF	;AN002;
			   mov Switch_K, OFF	;AN003;
			   call Parm_Error	;AN002;
			   mov Parse_Err_Flag,ON;AN002;
			.ELSE			;AN002;
			   .IF <Synonym_ptr EQ <offset X_SWITCH>>      ;AN002;
				mov	Switch_X, ON		       ;AN002;
			   .ELSE				       ;AN002;
			       .IF <Synonym_ptr EQ <offset L_SWITCH>>  ;AN003;
				    mov     Switch_L, ON ;AN002;
			       .ELSE			 ;AN003;Must be /K option.
				    mov     Switch_K, ON ;AN003;/K entered.
			       .ENDIF			 ;AN003;
			   .ENDIF			 ;AN002;
			    clc 		;AN002;
			.ENDIF			;AN002;
		     .ENDIF			;AN002;
		.ENDWHILE			;AN002;
		.IF <Parse_Err_Flag EQ ON>	;AN002;
		     stc			;AN002;
		.ELSE				;AN002;
		     clc			;AN002;
		.ENDIF				;AN002;
	      .ENDIF				;AN002;

;		 mov	  cs:Old_SI, SI 	 ;AN001; Save pointer to parm
;		 CALL	  SYSPARSE		 ; look for /X switch			  ;AN000;
;		 .IF <AX EQ RC_EOL>		 ; if EOL then..			  ;AN000;
;		    MOV     ES:SWITCH_X,0	 ;  no switch...clear flag		  ;AN000;
;		    CLC 			 ;  clear carry 			  ;AN000;
;		 .ELSE				 ; else..				  ;AN000;
;		    .IF <AX GT RC_NO_ERROR>	 ;AN001;If any error
;			call parm_error 	 ;AN001; the show the error msg
;			stc			 ;AN001;
;		    .ELSE			 ;  else..leave flag set..		  ;AN000;
;			mov   cs:Old_SI, SI	 ;AN001;
;		       CALL    SYSPARSE 	 ; check for further parms		  ;AN000;
;		       .IF <AX NE RC_EOL>	 ; if other parms then...		  ;AN000;
;			  CALL	 PARM_ERROR	 ; display 'Invalid parameter' message    ;AN000;
;			  STC			 ;  error!				  ;AN000;
;		       .ELSE			 ; no other parms so..			  ;AN000;
;			  CLC			 ;  clear carry 			  ;AN000;
;		       .ENDIF			 ;					  ;AN000;
;		    .ENDIF			 ;					  ;AN000;
;		 .ENDIF 			 ;					  ;AN000;
;	       .ENDIF				 ;					  ;AN000;

	      RET									 ;AN000;
PARSE_PARM    ENDP									 ;AN000;
											 ;AN000;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARM_ERROR
;
; FUNCTION:
; LOADS AND DISPLAYS "Invalid parameter" MESSAGE
;
; AT ENTRY:
;   DS:Old_SI -> parms that is invalid
;
; AT EXIT:
;    NORMAL: ERROR MESSAGE DISPLAYED
;
;    ERROR: N/A
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARM_ERROR    PROC   NEAR								 ;AN000;
	      PUSH   CX 								 ;AN000;
	      PUSH   SI 								 ;AN000;
	      PUSH   ES 		;						 ;AN000;
	      PUSH   DS 		;						 ;AN000;

;	       PUSH   CS		 ;						  ;AN000;
;	       POP    DS		 ; establish addressability			  ;AN000;
;	       MOV    BX,DX		 ;						  ;AN000;
;	       LES    DX,[BX].RES_PTR	 ; find offending parameter			  ;AN000;
	       push   ds		;AN001;
	       pop    es		;AN001;
	       mov    si, cs:Old_SI	;AN001;Now es:dx -> offending parms
	       push   si		;AN001;Save it
Get_CR:
	       cmp    byte ptr es:[si], 13 ;AN001;CR?
	       je     Got_CR		   ;AN001;
	       inc    si		   ;AN001;
	       jmp    Get_CR		   ;AN001;
Got_CR: 				   ;AN001;
	       inc    si		   ;AN001; The next char.
	       mov    al, byte ptr es:[si] ;AN001;
	       mov    cs:Saved_Chr, al	   ;AN001; Save the next char

	       mov    byte ptr es:[si], 0     ;AN001; and make it an ASCIIZ
	       mov    cs:Old_SI, si	;AN001; Set it again
	       pop    dx		;AN001; saved SI -> DX

	       push   cs		;AN001;
	       pop    ds		;AN001;for addressability

	      LEA    SI,SUBLIST 	; ..and place the offset..			 ;AN000;
	      MOV    [SI].SUB_PTR_O,DX	; ..in the SUBLIST..				 ;AN000;
	      MOV    [SI].SUB_PTR_S,ES	;						 ;AN000;
	      MOV    AX,INVALID_PARM	; load 'Invalid parameter' message number        ;AN000;
	      MOV    BX,STDERR		; to standard error				 ;AN000;
	      MOV    CX,ONE		; 1 substitution				 ;AN000;
	      XOR    DL,DL		; no input					 ;AN000;
	      MOV    DH,UTILITY_MSG_CLASS ; parse error 				 ;AN000;
	      CALL   SYSDISPMSG 	; display error message 			 ;AN000;
	      mov    si, cs:Old_SI	;AN001;restore the original char.
	      mov    cl, cs:Saved_Chr	;AN001;
	      mov    byte ptr es:[si], cl ;AN001;

	      POP    DS 								 ;AN000;
	      POP    ES 								 ;AN000;
	      POP    SI 								 ;AN000;
	      POP    CX 								 ;AN000;
	      RET									 ;AN000;
PARM_ERROR    ENDP

include msgdcl.inc

CODE	      ENDS
	      END
