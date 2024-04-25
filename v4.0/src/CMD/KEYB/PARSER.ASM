PAGE	    ,132
TITLE	    PARSE CODE AND CONTROL BLOCKS FOR KEYB.COM

;****************** START OF SPECIFICATIONS **************************
;
;  MODULE NAME: PARSER.ASM
;
;  DESCRIPTIVE NAME: PARSES THE COMMAND LINE PARAMETERS FOR KEYB.COM
;
;  FUNCTION: THE COMMAND LINE IN THE PSP IS PARSED FOR PARAMETERS.
;
;  ENTRY POINT: PARSE_PARAMETERS
;
;  INPUT: BP POINTS TO PARAMETER LIST
;	  DS & ES POINT TO PSP
;
;  AT EXIT:
;     PARAMETER LIST FILLED IN AS REQUIRED.
;
;  INTERNAL REFERENCES:
;
;     ROUTINES: SYSPARSE - PARSING CODE
;
;     DATA AREAS: PARMS - PARSE CONTROL BLOCK FOR SYSPARSE
;
;  EXTERNAL REFERENCES:
;
;     ROUTINES: N/A
;
;     DATA AREAS: PARAMETER LIST BLOCK TO BE FILLED.
;
;  NOTES:
;
;  REVISION HISTORY:
;	 A000 - DOS Version 4.00
;  3/24/88 AN003 - P3906 PARSER changes to return "bogus" parameter on the
;	       "Parameter value not allowed " message - CNS
;  5/12/88 AN004 - P4867 /ID:NON-Numeric hangs the sytem as a 1st positional
;
;  COPYRIGHT: "The KEYB.COM Keyboard Driver"
;	      "Version 4.00 (C) Copyright 1988 Microsoft"
;	      "Licensed Material - Program Property of Microsoft"
;
;  PROGRAM AUTHOR: WGR
;
;****************** END OF SPECIFICATIONS ****************************

INCLUDE     KEYBDCL.INC 							    ;AN000

ID_VALID	     EQU  0		;AN000; 				    ;AN000
ID_INVALID	     EQU  1		;AN000; 					   ;AN000
NO_ID		     EQU  2		;AN000; 					   ;AN000

LANGUAGE_VALID	     EQU  0		;AN000; 					   ;AN000
LANGUAGE_INVALID     EQU  1		;AN000; 					   ;AN000
NO_LANGUAGE	     EQU  2		;AN000; 					   ;AN000

NO_IDLANG	     EQU  3		;AN000; 					   ;AN000

CODE_PAGE_VALID      EQU  0		;AN000; 					   ;AN000
CODE_PAGE_INVALID    EQU  1		;AN000; 					   ;AN000
NO_CODE_PAGE	     EQU  2		;AN000; 					   ;AN000
VALID_SYNTAX	     EQU  0		;AN000; 					   ;AN000
INVALID_SYNTAX	     EQU  1		;AN000; 					   ;AN000

COMMAND_LINE_START   EQU  81H		;AN000; 					   ;AN000
RC_EOL		     EQU  -1		;AN000; 					   ;AN000
RC_NO_ERROR	     EQU  0		;AN000; 					   ;AN000
RC_OP_MISSING	     EQU  2		;AN000; 					   ;AN000
RC_NOT_IN_SW	     EQU  3		;AN000; 					   ;AN000
;***CNS P4867 1st CHECK for /ID:ALPHA
RC_SW_FIRST	     EQU  9		;AN004; 					   ;AN000
;***CNS P4867 1st CHECK for /ID:ALPHA
ERROR_COND	     EQU  -1		;AN000; 					   ;AN000
NUMBER		     EQU  1		;AN000; 					   ;AN000
STRING		     EQU  3		;AN000; 					   ;AN000
FILE_SPEC	     EQU  5		;AN000; 					   ;AN000
MAX_ID		     EQU  999		;AN000; 					   ;AN000
LANG_LENGTH	     EQU  2		;AN000; 					   ;AN000

INVALID_SWITCH	     EQU  3
TOO_MANY	     EQU  1
INVALID_PARAM	     EQU  10
VALUE_DISALLOW	     EQU  8

.XLIST
INCLUDE     STRUC.INC	    ; Structured macros 				    ;AN000
.LIST

PUBLIC	    PARSE_PARAMETERS ;AN003;; near procedure for parsing command line		   ;AN000
PUBLIC	    CUR_PTR ;AN003;; near procedure for parsing command line		  ;AN000
PUBLIC	    OLD_PTR ;AN003;; near procedure for parsing command line		  ;AN000
PUBLIC	    ERR_PART;AN003;; near procedure for parsing command line		  ;AN000
EXTRN  BAD_ID:BYTE	       ;; WGR to match old code ;AN000; 			   ;AN000
EXTRN  FOURTH_PARM:BYTE        ;; WGR to match old code ;AN000; 			   ;AN000
EXTRN  ONE_PARMID:BYTE	       ;; WGR to match old code ;AN000; 			   ;AN000
EXTRN  FTH_PARMID:BYTE	       ;; WGR to match old code ;AN000; 			   ;AN000
EXTRN  ALPHA:BYTE	       ;; WGR to match old code ;AN000; 			   ;AN000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Set assemble switches for parse code that is not required!!
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DateSW	      EQU     0 		;AN000; 					   ;AN000
TimeSW	      EQU     0 		;AN000; 					   ;AN000
CmpxSW	      EQU     0 		;AN000; 					   ;AN000
DrvSW	      EQU     0 		;AN000; 					   ;AN000
QusSW	      EQU     0 		;AN000; 					   ;AN000
KeySW	      EQU     0 		;AN000; 					   ;AN000
Val1SW	      EQU     0 		;AN000; 					   ;AN000
Val2SW	      EQU     0 		;AN000; 					   ;AN000
Val3SW	      EQU     0 		;AN000; 					   ;AN000


CODE	      SEGMENT  PUBLIC 'CODE' BYTE            ;AN000;                               ;AN000
	      ASSUME CS:CODE,DS:CODE		     ;AN000;				   ;AN000

.XLIST
INCLUDE     PARSE.ASM	    ; Parsing code					    ;AN000
.LIST


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PARM control blocks for KEYB
; Parsing command line as follows:
;
; KEYB [lang],[cp],[[d:][path]KEYBOARD.SYS][/ID:id]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARMS	       LABEL WORD		   ;AN000;					   ;AN000
	       DW	PARMSX		   ;AN000;					   ;AN000
	       DB	0		   ;AN000;; no extra delimeters or EOLs.	   ;AN000

PARMSX	       LABEL BYTE		   ;AN000;					   ;AN000
	       DB	0,3		   ;AN000;; min,max positional operands 	   ;AN000
	       DW	LANG		   ;AN000;; pointer to control block		   ;AN000
	       DW	CP		   ;AN000;; pointer to control block		   ;AN000
	       DW	FILE_NAME	   ;AN000;; pointer to control block		   ;AN000
	       DB	1		   ;AN000;; 1 switch				   ;AN000
	       DW	ID_VALUE	   ;AN000;; pointer to control block		   ;AN000
	       DB	0		   ;AN000;; no keywords 			   ;AN000

LANG	       LABEL WORD		   ;AN000;					   ;AN000
	       DW	0A001H		   ;AN000;; sstring or numeric value (optional)    ;AN000
	       DW	0002H		   ;AN000;; cap result by char table (sstring)	   ;AN000
	       DW	RESULT_BUF	   ;AN000;; result				   ;AN000
	       DW	NOVALS		   ;AN000;; no value checking done		   ;AN000
	       DB	0		   ;AN000;; no keyword/switch synonyms		   ;AN000

CP	       LABEL WORD		   ;AN000;					   ;AN000
	       DW	8001H		   ;AN000;; numeric				   ;AN000
	       DW	0		   ;AN000;; no functions			   ;AN000
	       DW	RESULT_BUF	   ;AN000;; result				   ;AN000
	       DW	NOVALS		   ;AN000;; no value checking done		   ;AN000
	       DB	0		   ;AN000;; no keyword/switch synonyms		   ;AN000

FILE_NAME      LABEL WORD		   ;AN000;					   ;AN000
	       DW	0201H		   ;AN000;; file spec				   ;AN000
	       DW	0001H		   ;AN000;; cap by file table			   ;AN000
	       DW	RESULT_BUF	   ;AN000;; result				   ;AN000
	       DW	NOVALS		   ;AN000;; no value checking done		   ;AN000
	       DB	0		   ;AN000;; no keyword/switch synonyms		   ;AN000

ID_VALUE       LABEL WORD		   ;AN000;					   ;AN000
	       DW	8010H		   ;AN000;; numeric				   ;AN000
	       DW	0		   ;AN000;; no functions			   ;AN000
	       DW	RESULT_BUF	   ;AN000;; result				   ;AN000
	       DW	NOVALS		   ;AN000;; no value checking done		   ;AN000
	       DB	1		   ;AN000;; 1 switch synonym			   ;AN000
	       DB	"/ID",0            ;AN000;; ID switch                              ;AN000

NOVALS	       LABEL BYTE		   ;AN000;					   ;AN000
	       DB	0		   ;AN000;; no value checking done		   ;AN000

RESULT_BUF     LABEL BYTE		   ;AN000;					   ;AN000
RESULT_TYPE    DB	0		   ;AN000;; type returned (number, string, etc.)   ;AN000
	       DB	?		   ;AN000;; matched item tag (if applicable)	   ;AN000
RESULT_SYN_PTR DW	?		   ;AN000;; synonym ptr (if applicable) 	   ;AN000
RESULT_VAL     DD	?		   ;AN000;; value				   ;AN000

LOOP_COUNT     DB	0		   ;AN000;; keeps track of parameter position	   ;AN000
;***CNS
CUR_PTR        DW	0		   ;AN003;; keeps track of parameter position	   ;AN000
OLD_PTR        DW	0		   ;AN003;; keeps track of parameter position	   ;AN000
ERR_PART       DW	0		   ;AN003;; keeps track of parameter position	   ;AN000
;***CNS
					   ;AN000;; ..and reports an error condition	   ;AN000
TEMP_FILE_NAME DB	128 DUP(0)	   ;AN000;; place for file name 		   ;AN000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARSE_PARAMETERS
;
; FUNCTION:
; THIS PROCEDURE PARSES THE COMMAND LINE PARAMETERS IN THE PSP FOR
; KEYB.COM. THE PARAMETER LIST BLOCK IS FILLED IN ACCORDINGLY.
;
; AT ENTRY: AS ABOVE.
;
; AT EXIT:
;    AS ABOVE.
;
; AUTHOR: WGR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSE_PARAMETERS       PROC	NEAR						    ;AN000
      XOR    AX,AX				 ;AN000;; setup default parameters.	   ;AN000
      MOV    [BP].RET_CODE_1,NO_IDLANG		 ;AN000;;				   ;AN000
      MOV    [BP].RET_CODE_2,NO_CODE_PAGE	 ;AN000;;				   ;AN000
      MOV    [BP].RET_CODE_3,VALID_SYNTAX	 ;AN000;;				   ;AN000
      MOV    [BP].RET_CODE_4,NO_ID		 ;AN000;;				   ;AN000
      MOV    [BP].PATH_LENGTH,AX		 ;AN000;;				   ;AN000
      LEA    DI,PARMS				 ;AN000;; setup parse blocks		   ;AN000
      MOV    SI,COMMAND_LINE_START		 ;AN000;;				   ;AN000
;***CNS

	  PUSH AX				 ;AN003;Save environment
	  MOV AX,CUR_PTR			 ;AN003;Set advancing ptr to end of argument
	  MOV OLD_PTR,AX			 ;AN003;after saving the beginning the string
	  MOV CUR_PTR,SI			 ;AN003;
	  POP AX				 ;AN003;Restore the environment

;***CNS
      XOR    CX,CX				 ;AN000;;				   ;AN000
      XOR    DX,DX				 ;AN000;;				   ;AN000
      CALL   SYSPARSE				 ;AN000;;				   ;AN000
      .WHILE <AX NE RC_EOL> near AND		 ;AN000;; while not end of line and..	   ;AN000
      .WHILE <LOOP_COUNT NE ERROR_COND> near	 ;AN000;; parameters valid do.		   ;AN000
	.IF <AX EQ RC_NOT_IN_SW> near OR	 ;AN000;; invalid switch?		   ;AN000
	.IF <AX EQ RC_SW_FIRST>  near		;AN000;; invalid switch?		  ;AN000
	  MOV	 [BP].RET_CODE_3,INVALID_SYNTAX  ;AN000;; set invalid syntax flag.	   ;AN000
	  MOV	 LOOP_COUNT,ERROR_COND		 ;AN000;; set error flag to exit parse.    ;AN000
;***CNS
	  MOV	ERR_PART,INVALID_SWITCH
	  PUSH AX				 ;AN003;Save environment
	  MOV AX,CUR_PTR			 ;AN003;Set advancing ptr to end of argument
	  MOV OLD_PTR,AX			 ;AN003;after saving the beginning the string
	  MOV CUR_PTR,SI			 ;AN003;
	  POP AX				 ;AN003;Restore the environment

;***CNS
	.ELSE					 ;AN000;;				   ;AN000
	  .IF <RESULT_SYN_PTR NE 0>		 ;AN000;; was the switch found? 	   ;AN000
	    MOV    AX,WORD PTR RESULT_VAL+2	 ;AN000;; is it valid?			   ;AN000
	    OR	   AX,AX			 ;AN000;;				   ;AN000
	    .IF NZ OR				 ;AN000;;				   ;AN000
	    MOV    AX,WORD PTR RESULT_VAL	 ;AN000;;				   ;AN000
	    .IF <AX A MAX_ID>			 ;AN000;;				   ;AN000
	      MOV    [BP].RET_CODE_1,ID_INVALID  ;AN000;; no...invalid id.		   ;AN000
	      MOV    [BP].RET_CODE_3,INVALID_SYNTAX ;AN000;; syntax error.		   ;AN000
	      MOV    LOOP_COUNT,ERROR_COND	 ;AN000;; set flag to exit parse	   ;AN000
	      mov    bad_id,1			 ;AN000;;				   ;AN000
;***CNS

	  PUSH AX				 ;AN003;Save environment
	  MOV AX,CUR_PTR			 ;AN003;Set advancing ptr to end of argument
	  MOV OLD_PTR,AX			 ;AN003;after saving the beginning the string
	  MOV CUR_PTR,SI			 ;AN003;
	  POP AX				 ;AN003;Restore the environment

;***CNS
	    .ELSE				 ;AN000;;				   ;AN000
	      MOV    [BP].RET_CODE_4,ID_VALID	 ;AN000;; yes...set return code 4.	   ;AN000
	      MOV    [BP].ID_PARM,AX		 ;AN000;;				   ;AN000
	      mov    fourth_parm,1		 ;AN000;;				   ;AN000
	      mov    fth_parmid,1		 ;AN000;;				   ;AN000
	    .ENDIF				 ;AN000;;				   ;AN000
	  .ELSE 				 ;AN000;;				   ;AN000
	    INC    LOOP_COUNT			 ;AN000;; positional encountered...	   ;AN000
	    .SELECT				 ;AN000;;				   ;AN000
	    .WHEN <LOOP_COUNT EQ 1>		 ;AN000;; check for language		   ;AN000
	      CALL   PROCESS_1ST_PARM		 ;AN000;;				   ;AN000

;***CNS

	  PUSH AX				 ;AN003;Save environment
	  MOV AX,CUR_PTR			 ;AN003;Set advancing ptr to end of argument
	  MOV OLD_PTR,AX			 ;AN003;after saving the beginning the string
	  MOV CUR_PTR,SI			 ;AN003;
	  POP AX				 ;AN003;Restore the environment
;***CNS


	    .WHEN <LOOP_COUNT EQ 2>		 ;AN000;; check for code page		   ;AN000
	      CALL   PROCESS_2ND_PARM		 ;AN000;;				   ;AN000
;***CNS

	  PUSH AX				 ;AN003;Save environment
	  MOV AX,CUR_PTR			 ;AN003;Set advancing ptr to end of argument
	  MOV OLD_PTR,AX			 ;AN003;after saving the beginning the string
	  MOV CUR_PTR,SI			 ;AN003;
	  POP AX				 ;AN003;Restore the environment
;***CNS
	    .WHEN <LOOP_COUNT EQ 3>		 ;AN000;; check for file name		   ;AN000
	      CALL   PROCESS_3RD_PARM		 ;AN000;;				   ;AN000
;***CNS

	  PUSH AX				 ;AN003;Save environment
	  MOV AX,CUR_PTR			 ;AN003;Set advancing ptr to end of argument
	  MOV OLD_PTR,AX			 ;AN003;after saving the beginning the string
	  MOV CUR_PTR,SI			 ;AN003;
	  POP AX				 ;AN003;Restore the environment
;***CNS
	    .OTHERWISE				 ;AN000;;				   ;AN000
	      MOV    [BP].RET_CODE_3,INVALID_SYNTAX ;AN000;; too many parms		   ;AN000
;***CNS

	  PUSH AX				 ;AN003;Save environment
	  MOV AX,CUR_PTR			 ;AN003;Set advancing ptr to end of argument
	  MOV OLD_PTR,AX			 ;AN003;after saving the beginning the string
	  MOV CUR_PTR,SI			 ;AN003;
	  POP AX				 ;AN003;Restore the environment
;***CNS
	  MOV	ERR_PART,TOO_MANY
	      MOV    LOOP_COUNT,ERROR_COND	 ;AN000;; set error flag to exit parse.    ;AN000
	    .ENDSELECT				 ;AN000;;				   ;AN000
	  .ENDIF				 ;AN000;;				   ;AN000
	  MOV	 RESULT_TYPE,0			 ;AN000;; reset result block.		   ;AN000
	  CALL	 SYSPARSE			 ;AN000;; parse next parameter. 	   ;AN000
	.ENDIF					 ;AN000;;				   ;AN000
      .ENDWHILE 				 ;AN000;;				   ;AN000
      .IF <[BP].RET_CODE_4 EQ ID_VALID> AND	 ;AN000;; ensure that if the switch	   ;AN000
      .IF <[BP].RET_CODE_1 NE LANGUAGE_VALID>	 ;AN000;; was used..that a valid keyboard  ;AN000
	MOV	[BP].RET_CODE_3,INVALID_SYNTAX	 ;AN000;; code was used..		   ;AN000
;***CNS

	  PUSH AX				 ;AN003;Save environment
	  MOV AX,CUR_PTR			 ;AN003;Set advancing ptr to end of argument
	  MOV OLD_PTR,AX			 ;AN003;after saving the beginning the string
	  MOV CUR_PTR,SI			 ;AN003;
	  POP AX				 ;AN003;Restore the environment
	  MOV	ERR_PART,VALUE_DISALLOW
;***CNS
      .ENDIF					 ;AN000;;				   ;AN000
      RET					 ;AN000;;				   ;AN000
PARSE_PARAMETERS       ENDP			 ;AN000;				   ;AN000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PROCESS_1ST_PARM
;
; FUNCTION:
; THIS PROCEDURE PROCESSES THE FIRST POSITIONAL PARAMETER. THIS SHOULD
; BE THE LANGUAGE ID OR THE KEYBOARD ID.
;
; AT ENTRY: PARSE RESULT BLOCK CONTAINS VALUES IF AX HAS NO ERROR.
;
; AT EXIT:
;    PARAMETER CONTROL BLOCK UPDATED FOR LANGUAGE ID.
;
; AUTHOR: WGR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROCESS_1ST_PARM       PROC    NEAR						    ;AN000
       .IF <AX GT RC_NO_ERROR>			 ;AN000;; error on parse?		   ;AN000
	 MOV	[BP].RET_CODE_1,LANGUAGE_INVALID ;AN000;; yes...set invalid language	   ;AN000
	 MOV	[BP].RET_CODE_3,INVALID_SYNTAX	 ;AN000;; and syntax error..		   ;AN000
	 MOV	LOOP_COUNT,ERROR_COND		 ;AN000;; set flag to exit parse.	   ;AN000
      MOV    ERR_PART,AX			 ;AN003;;
       .ELSE near				 ;AN000;;				   ;AN000

	 .IF <RESULT_TYPE EQ NUMBER>		 ;AN000;; was this a number (id)?	   ;AN000
	   MOV	  AX,WORD PTR RESULT_VAL+2	 ;AN000;; yes...check to see if 	   ;AN000
	   OR	  AX,AX 			 ;AN000;; within range. 		   ;AN000
	   .IF NZ OR				 ;AN000;;				   ;AN000
	   MOV	  AX,WORD PTR RESULT_VAL	 ;AN000;;				   ;AN000
	   .IF <AX A MAX_ID>			 ;AN000;;				   ;AN000
	     MOV    [BP].RET_CODE_1,ID_INVALID	 ;AN000;; no...invalid id.		   ;AN000
	     MOV    [BP].RET_CODE_3,INVALID_SYNTAX ;AN000;; syntax error.		   ;AN000
	     MOV    LOOP_COUNT,ERROR_COND	 ;AN000;; set flag to exit parse	   ;AN000
	     mov    bad_id,1			 ;AN000;;				   ;AN000
	   .ELSE				 ;AN000;;				   ;AN000
	     MOV    [BP].RET_CODE_1,ID_VALID	 ;AN000;; valid id...set		   ;AN000
	     MOV    [BP].RET_CODE_4,ID_VALID	 ;AN000;; valid id...set		   ;AN000
	     MOV    [BP].ID_PARM,AX		 ;AN000;; and value moved into block	   ;AN000
	     MOV    LOOP_COUNT,4		 ;AN000;; there should be no more parms    ;AN000
	     mov    one_parmid,1		 ;AN000;;				   ;AN000
	   .ENDIF				 ;AN000;;				   ;AN000
	 .ELSEIF <RESULT_TYPE EQ STRING>	 ;AN000;; must be a string then..	   ;AN000
	   PUSH   SI				 ;AN000;;				   ;AN000
	   PUSH   DI				 ;AN000;;				   ;AN000
	   PUSH   CX				 ;AN000;;				   ;AN000
	   PUSH   DS				 ;AN000;;				   ;AN000
	   LDS	  SI,RESULT_VAL 		 ;AN000;; get ptr to string		   ;AN000
	   MOV	  DI,BP 			 ;AN000;;				   ;AN000
	   ADD	  DI,LANGUAGE_PARM		 ;AN000;; point to block for copy.	   ;AN000
	   MOV	  CX,LANG_LENGTH		 ;AN000;; maximum length = 2		   ;AN000
	   LODSB				 ;AN000;; load AL with 1st char..	   ;AN000
	   .WHILE <CX NE 0> AND 		 ;AN000;; do twice....unless		   ;AN000
	   .WHILE <AL NE 0>			 ;AN000;; there is only 1 character.	   ;AN000
	     STOSB				 ;AN000;; store 			   ;AN000
	     DEC    CX				 ;AN000;; dec count			   ;AN000
	     LODSB				 ;AN000;; load				   ;AN000
	   .ENDWHILE				 ;AN000;;				   ;AN000
	   .IF <CX NE 0> OR			 ;AN000;; if there was less than 2 or..    ;AN000
	   .IF <AL NE 0>			 ;AN000;; greater than 2 characters then.. ;AN000
	     MOV    [BP].RET_CODE_1,LANGUAGE_INVALID ;AN000;; invalid.			   ;AN000
	     MOV    [BP].RET_CODE_3,INVALID_SYNTAX ;AN000;; syntax error		   ;AN000
	  MOV	ERR_PART,INVALID_PARAM
	     MOV    LOOP_COUNT,ERROR_COND	 ;AN000;; set flag to exit parse.	   ;AN000
	   .ELSE				 ;AN000;;				   ;AN000
	     MOV    [BP].RET_CODE_1,LANGUAGE_VALID ;AN000;; valid language has been copied ;AN000
	     MOV    ALPHA,1			 ;AN000;; language found		   ;AN000
	   .ENDIF				 ;AN000;;				   ;AN000
	   POP	  DS				 ;AN000;;				   ;AN000
	   POP	  CX				 ;AN000;;				   ;AN000
	   POP	  DI				 ;AN000;;				   ;AN000
	   POP	  SI				 ;AN000;;				   ;AN000
	 .ELSE					 ;AN000;; ommited parameter...		   ;AN000
	   MOV	  [BP].RET_CODE_3,INVALID_SYNTAX ;AN000;; invalid since further parameters.;AN000
	 .ENDIF 				 ;AN000;;				   ;AN000
       .ENDIF					 ;AN000;;				   ;AN000
       RET					 ;AN000;;				   ;AN000
PROCESS_1ST_PARM       ENDP			 ;AN000;				   ;AN000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PROCESS_2ND_PARM
;
; FUNCTION:
; THIS PROCEDURE PROCESSES THE 2ND POSITIONAL PARAMETER. THIS SHOULD
; BE THE CODE PAGE, IF REQUESTED.
;
; AT ENTRY: PARSE RESULT BLOCK CONTAINS VALUES IF AX HAS NO ERROR.
;
; AT EXIT:
;    PARAMETER CONTROL BLOCK UPDATED FOR CODE PAGE.
;
; AUTHOR: WGR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROCESS_2ND_PARM       PROC    NEAR						    ;AN000
       .IF <AX GT RC_NO_ERROR>			   ;AN000;; if parse error..		   ;AN000
	 MOV	[BP].RET_CODE_2,CODE_PAGE_INVALID  ;AN000;; mark invalid..		   ;AN000
	 MOV	[BP].RET_CODE_3,INVALID_SYNTAX	   ;AN000;; syntax error		   ;AN000
	 MOV	LOOP_COUNT,ERROR_COND		   ;AN000;; set flag to exit parse	   ;AN000
      MOV    ERR_PART,AX			 ;AN003;;
       .ELSE					   ;AN000;;				   ;AN000
	 .IF <RESULT_TYPE EQ NUMBER>		   ;AN000;; was parameter specified?	   ;AN000
	   MOV	  AX,WORD PTR RESULT_VAL+2	   ;AN000;; yes..if code page not..	   ;AN000
	   OR	  AX,AX 			   ;AN000;;				   ;AN000
	   .IF NZ OR				   ;AN000;;				   ;AN000
	   MOV	  AX,WORD PTR RESULT_VAL	   ;AN000;; valid..then 		   ;AN000
	   .IF <AX A MAX_ID>			   ;AN000;;				   ;AN000
	     MOV    [BP].RET_CODE_2,CODE_PAGE_INVALID ;AN000;; mark invalid..		   ;AN000
	     MOV    [BP].RET_CODE_3,INVALID_SYNTAX ;AN000;; syntax error		   ;AN000
	     MOV    LOOP_COUNT,ERROR_COND	   ;AN000;; set flag to exit parse	   ;AN000
	   .ELSE				   ;AN000;;				   ;AN000
	     MOV    [BP].RET_CODE_2,CODE_PAGE_VALID;AN000;; else...valid code page	   ;AN000
	     MOV    [BP].CODE_PAGE_PARM,AX	   ;AN000;; move into parm		   ;AN000
	   .ENDIF				   ;AN000;;				   ;AN000
	 .ELSE					   ;AN000;;				   ;AN000
	   MOV	    [BP].RET_CODE_2,NO_CODE_PAGE   ;AN000;; mark as not specified.	   ;AN000
	 .ENDIF 				   ;AN000;;				   ;AN000
       .ENDIF					   ;AN000;;				   ;AN000
       RET					   ;AN000;;				   ;AN000
PROCESS_2ND_PARM      ENDP			   ;AN000;				   ;AN000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PROCESS_3RD_PARM
;
; FUNCTION:
; THIS PROCEDURE PROCESSES THE 3RD POSITIONAL PARAMETER. THIS SHOULD
; BE THE KEYBOARD DEFINITION FILE PATH, IF SPECIFIED.
;
; AT ENTRY: PARSE RESULT BLOCK CONTAINS VALUES IF AX HAS NO ERROR.
;
; AT EXIT:
;    PARAMETER CONTROL BLOCK UPDATED FOR FILE NAME.
;
; AUTHOR: WGR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROCESS_3RD_PARM       PROC    NEAR	     ;AN000;					   ;AN000
       .IF <AX GT RC_NO_ERROR>		     ;AN000;; if parse error then..		   ;AN000
	 MOV	[BP].RET_CODE_3,INVALID_SYNTAX ;AN000;; syntax error.			   ;AN000
	 MOV	LOOP_COUNT,ERROR_COND	     ;AN000;; set flag to exit parse		   ;AN000
      MOV    ERR_PART,AX			 ;AN003;;
       .ELSE				     ;AN000;;					   ;AN000
	 .IF <RESULT_TYPE EQ FILE_SPEC>      ;AN000;;					   ;AN000
	   PUSH   DS			     ;AN000;;					   ;AN000
	   PUSH   SI			     ;AN000;;					   ;AN000
	   PUSH   DI			     ;AN000;;					   ;AN000
	   PUSH   CX			     ;AN000;;					   ;AN000
	   LDS	  SI,RESULT_VAL 	     ;AN000;; load offset of file name		   ;AN000
	   LEA	  DI,TEMP_FILE_NAME	     ;AN000;;					   ;AN000
	   MOV	  [BP].PATH_OFFSET,DI	     ;AN000;; copy to parameter block		   ;AN000
	   XOR	  CX,CX 		     ;AN000;;					   ;AN000
	   LODSB			     ;AN000;; count the length of the path.	   ;AN000
	   .WHILE <AL NE 0>		     ;AN000;;					   ;AN000
	     STOSB			     ;AN000;;					   ;AN000
	     LODSB			     ;AN000;;					   ;AN000
	     INC    CX			     ;AN000;;					   ;AN000
	   .ENDWHILE			     ;AN000;;					   ;AN000
	   MOV	  [BP].PATH_LENGTH,CX	     ;AN000;; copy to parameter block		   ;AN000
	   POP	  CX			     ;AN000;;					   ;AN000
	   POP	  DI			     ;AN000;;					   ;AN000
	   POP	  SI			     ;AN000;;					   ;AN000
	   POP	  DS			     ;AN000;;					   ;AN000
	 .ENDIF 			     ;AN000;;					   ;AN000
       .ENDIF				     ;AN000;;					   ;AN000
       RET				     ;AN000;;					   ;AN000
PROCESS_3RD_PARM       ENDP		     ;AN000;					   ;AN000
					     ;AN000;
CODE	      ENDS			     ;AN000;
	      END			     ;AN000;
