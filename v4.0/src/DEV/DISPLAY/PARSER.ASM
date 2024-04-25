PAGE	    ,132
TITLE	    PARSE CODE AND CONTROL BLOCKS FOR DISPLAY.SYS

;****************** START OF SPECIFICATIONS **************************
;
;  MODULE NAME: PARSER.ASM
;
;  DESCRIPTIVE NAME: PARSES THE DEVICE= STATEMENT IN CONFIG.SYS FOR
;		     DISPLAY.SYS
;
;  FUNCTION: THE COMMAND LINE PASSED TO DISPLAY.SYS IN THE CONFIG.SYS
;	     STATEMENT IS PARSED TO CHECK FOR CORRECT SYNTAX. A TABLE
;	     IS SETUP CONTAINING THE VALUES FOUND.
;
;  ENTRY POINT: PARSER
;
;  INPUT: ES:DI POINTS TO REQUEST HEADER
;
;  AT EXIT:
;     NORMAL: TABLE SET UP WITH VALUES FOUND.
;
;     ERROR: 0 RETURNED IN FIRST WORD OF TABLE.
;
;  INTERNAL REFERENCES:
;
;     ROUTINES: SYSPARSE - PARSING CODE
;
;     DATA AREAS: PARMSx - PARSE CONTROL BLOCK FOR SYSPARSE
;		  TABLE - TO CONTAIN VALUES FOUND IN DEVICE= LINE
;
;  EXTERNAL REFERENCES:
;
;     ROUTINES: N/A
;
;     DATA AREAS: N/A
;
;  NOTES:
;
;  REVISION HISTORY:
;	AN000; - DOS Version 4.00
;	AN001 - GHG P897 - Changes to the parser forced the inclusion
;			   of the '=' in the device ID.
;
;      Label: "The DOS DISPLAY.SYS Device Driver"
;	      "Version 4.00 (C) Copyright 1988 Microsoft
;	      "Licensed Material - Program Property of Microsoft"
;
;****************** END OF SPECIFICATIONS ****************************
;Modification history *********************************************************
;AN002; P1895 DISPLAY.SYS rejects command CON=(cga,(437),(0,0))   10/22/87 J.K.
;******************************************************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; The following is the table structure of the parser.	All fields are
; two bytes field (accept for the device and id name)
;
; TABLE HEADER :
; ÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Number of devices.	  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	 Device  # 1  offset	 ÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄ>ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´		  ³			     ³
;    ³	 Device  # 2  offset	  ³		  ³	 Table_1  (a)	     ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´		  ³			     ³
;    ³	 Device  # 3  offset	  ³		  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	 Device  # 4  offset	  ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;
; N = 1,2,3 or 4.  A two bytes number indicating the number of device specified.
; DEVICE # N OFFSET : a two bytes offset address to table_1. (ie. Device #1 offset
; is a pointer to table_1 (a). Device #2 offset is a pointer to table_1
; (b)...etc.).	 If an error was detected in the command N is set to zero.
;
;
;
; TABLE_1 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿	      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Number of Offsets.	  ³	      ³ 			 ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´    ÚÄÄÄÄÄÄ³      Table_2  (a)	 ³
;    ³	 Device Name  offset	 ÄÅÄÄÄÄÙ      ³ 			 ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´	      ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;    ³	 Device  Id   offset	 ÄÅÄÄÄÄÄÄ¿
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´	 ³    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³	 Device  HWCP offset	 ÄÅÄÄÄÄ¿ ³    ³ 			 ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´    ³ ÀÄÄÄÄ³      Table_3  (a)	 ³
;    ³	 Device  Desg offset	 ÄÅÄÄ¿ ³      ³ 			 ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´  ³ ³      ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;    ³	    "Reserved"            ³  ³ ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³ ³      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;				     ³ ³      ³ 			 ³
;				     ³ ÀÄÄÄÄÄÄ³      Table_4  (a)	 ³
;				     ³	      ³ 			 ³
;				     ³	      ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;				     ³	      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;				     ³	      ³ 			 ³
;				     ÀÄÄÄÄÄÄÄÄ³      Table_5  (a)	 ³
;					      ³ 			 ³
;					      ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;
;  N=Length of table_1, or the number of offsets contained in table_1.
;  The offsets are pointers (two bytes) to the parameters value of the device.
;  "Reserved" : a two byte memory reserved for future use of the "PARMS" option.
;
;
; TABLE_2 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of devices name ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  Device   name 	  ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
; N = Length of device name.  Device length is always 8 byte long.
; Device Name : the name of the device (eg. LPT1, CON, PRN).  The name
; is paded with spaces to make up the rest of the 8 characters.
;
;
;
; TABLE_3 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of Id name.	  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	   Id	Name		  ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
; N = Length of id name.  Id name length is always 8 byte long.
; Id Name : the name of the id (eg. EGA, VGA).	The name
; is paded with spaces to make up the rest of the 8 character.
;
;
;
; TABLE_4 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of table.	  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  HWCP	#  1		  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  HWCP	#  2		  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³		.		  ³
;    ³		.		  ³
;    ³		.		  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  HWCP	#  10		  ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;
; N = Length of table in words. Or the number of HWCP's.
; HWCP # N : a hardware code page number converted to binary.  The maximum
; number of pages allowed is 10.
;
;
;
; TABLE_5 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of table.	  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  Designate		  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  Font			  ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
; N = Lenght of table.	0 - nothing was specified
;			1 - Only a designate was specified.
;			2 - Designate and font were given.  If the Desg field
;			    was left empty in the DEVICE command then the
;			    Designate field is filled with 0FFFFH.
; Designate, Font : Are the Desg. and Font binary numbers.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE     DEF-EQU.INC      ; structures and equates					 ;AN000;

.XLIST
INCLUDE     STRUC.INC	     ; Structured macros					 ;AN000;
.LIST

PUBLIC	    PARSER	     ; near procedure for parsing DEVICE= statement		 ;AN000;
PUBLIC	    TABLE	     ; table for variable storage used by INIT module.		 ;AN000;
PUBLIC	    GET_DEVICE_ID    ; procedure to determine device adapter			 ;AN000;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Set assemble switches for parse code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DateSW	      EQU     0 								 ;AN000;
DrvSW	      EQU     0 								 ;AN000;
SwSW	      EQU     0 								 ;AN000;
Val1SW	      EQU     0 								 ;AN000;
Val2SW	      EQU     0 								 ;AN000;
Val3SW	      EQU     0 								 ;AN000;


CODE	      SEGMENT  PUBLIC BYTE 'CODE'
	      ASSUME CS:CODE


.XLIST
INCLUDE     PARSE.ASM	    ; Parsing code						 ;AN000;
.LIST


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PARM control block for DISPLAY.SYS - DEVICE= command statement.
; Command line looks like:
;
;   DEVICE=[d:][path]DISPLAY.SYS CON[:]=(type[,[hwcp][,n]])
;     or
;   DEVICE=[d:][path]DISPLAY.SYS CON[:]=(type[,[hwcp][,(n,m)]])
;     or, for compatibility with DOS 3.3; PTM P1895
;   DEVICE=[d:][path]DISPLAY.SYS CON[:]=(type[,[(hwcp)][,n|(n,m)]])
;
; The command line will be parsed from left to right, taking care of the
; nesting of complex lists as they occur.
;
; The first level of control blocks is shown below.
; Complex list control blocks follow.
; Null VALUE LIST and RESULT BUFFER are placed after all other PARSE control
; blocks.
;
; d:\path\DISPLAY.SYS CON=(complex list)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARMS1	       LABEL WORD								 ;AN000;
	       DW	PARMSX1 							 ;AN000;
	       DB	0		   ; no extra delimeters or EOLs.		 ;AN000;

PARMSX1        LABEL BYTE								 ;AN000;
	       DB	1,1		   ; min,max positional operands		 ;AN000;
	       DW	D_NAME		   ; pointer to control block			 ;AN000;
	       DB	0		   ; no switches				 ;AN000;
	       DB	1		   ; 1 keywords 				 ;AN000;
	       DW	DSP_LIST	   ; pointer to control block			 ;AN000;

D_NAME	       LABEL WORD								 ;AN000;
	       DW	0200H		   ; file spec					 ;AN000;
	       DW	0001H		   ; cap result by file table			 ;AN000;
	       DW	RESULT_BUF	   ; result					 ;AN000;
	       DW	NOVALS		   ; no value checking done			 ;AN000;
	       DB	0		   ; no keyword/switch synonyms 		 ;AN000;

DSP_LIST       LABEL WORD								 ;AN000;
	       DW	0400H		   ; complex list, ignore colon 		 ;AN000;
	       DW	0012H		   ; cap result by char table			 ;AN000;
	       DW	RESULT_BUF	   ; result					 ;AN000;
	       DW	NOVALS		   ; no value checking done			 ;AN000;
	       DB	2		   ; 1 keyword					 ;AN000;
	       DB	"CON=",0           ;GHG CON[:]= keyword                          ;AN001;
	       DB	"CON:=",0          ;GHG                                          ;AN001;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PARM control block for second level of nesting.
; ie. complex list from first level of nesting
;
; (type, hwcp, n or complex list)
;or,
; (type, (hwcp), n or complex list)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARMS2	       LABEL WORD								 ;AN000;
	       DW	PARMSX2 							 ;AN000;
	       DB	0		   ; no extra delimeters or EOLs.		 ;AN000;

PARMSX2        LABEL BYTE								 ;AN000;
	       DB	0,3		   ; min,max positional operands		 ;AN000;
	       DW	DSP_TYPE	   ; pointer to control block			 ;AN000;
	       DW	HWCP		   ; pointer to control block			 ;AN000;
	       DW	CP_PREPS	   ; pointer to control block			 ;AN000;
	       DB	0		   ; no switches				 ;AN000;
	       DB	0		   ; no keywords				 ;AN000;

DSP_TYPE       LABEL BYTE								 ;AN000;
	       DW	2001H		   ; sstring (optional) 			 ;AN000;
	       DW	0002H		   ; cap by char table				 ;AN000;
	       DW	RESULT_BUF	   ; result					 ;AN000;
	       DW	NOVALS		   ; value list 				 ;AN000;
	       DB	0		   ; no keyword/switch synonyms 		 ;AN000;


HWCP	       LABEL BYTE								 ;AN000;
	       DW	8401H		   ;AN002; numeric or complex list (optional)
	       DW	0		   ; no functions				 ;AN000;
	       DW	RESULT_BUF	   ; result					 ;AN000;
	       DW	NOVALS		   ; no value checking done			 ;AN000;
	       DB	0		   ; no keyword/switch synonyms 		 ;AN000;

CP_PREPS       LABEL BYTE								 ;AN000;
	       DW	8401H		   ; numeric or complex list (optional) 	 ;AN000;
	       DW	0		   ; no functions				 ;AN000;
	       DW	RESULT_BUF	   ; result					 ;AN000;
	       DW	NOVALS		   ; value list 				 ;AN000;
	       DB	0		   ; no keyword/switch synonyms 		 ;AN000;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PARM control block for third level of nesting.
; ie. complex list from second nesting level
;
; (hwcp)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARMS3_X       LABEL WORD		   ;AN002;
	       DW	PARMSX3_X	   ;AN002;
	       DB	0		   ;AN002; no extra delimeters or EOLs.

PARMSX3_X      LABEL BYTE		   ;AN002;
	       DB	1,1		   ;AN002; min,max positional operands
	       DW	PREPS		   ;AN002; pointer to control block
	       DB	0		   ;AN002; no switches
	       DB	0		   ;AN002; no keywords

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PARM control block for third level of nesting.
; ie. complex list from second nesting level
;
; (n,m)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARMS3	       LABEL WORD								 ;AN000;
	       DW	PARMSX3 							 ;AN000;
	       DB	0		   ; no extra delimeters or EOLs.		 ;AN000;

PARMSX3        LABEL BYTE								 ;AN000;
	       DB	1,2		   ; min,max positional operands		 ;AN000;
	       DW	PREPS		   ; pointer to control block			 ;AN000;
	       DW	SUBFONTS	   ; pointer to control block			 ;AN000;
	       DB	0		   ; no switches				 ;AN000;
	       DB	0		   ; no keywords				 ;AN000;

PREPS	       LABEL BYTE								 ;AN000;
	       DW	8000H		   ; numeric					 ;AN000;
	       DW	0		   ; no functions				 ;AN000;
	       DW	RESULT_BUF	   ; result					 ;AN000;
	       DW	NOVALS		   ; value list 				 ;AN000;
	       DB	0		   ; no keyword/switch synonyms 		 ;AN000;

SUBFONTS       LABEL BYTE								 ;AN000;
	       DW	8001H		   ; numeric (optional) 			 ;AN000;
	       DW	0		   ; no functions				 ;AN000;
	       DW	RESULT_BUF	   ; result					 ;AN000;
	       DW	NOVALS		   ; no value checking done			 ;AN000;
	       DB	0		   ; no keyword/switch synonyms 		 ;AN000;

; Null VALUE LIST and RESULT BUFFER for all PARSE control blocks			 ;AN000;

NOVALS	       LABEL BYTE								 ;AN000;
	       DB	0		   ; no value checking done			 ;AN000;

RESULT_BUF     LABEL BYTE								 ;AN000;
RESULT_TYPE    DB	?		   ; type returned (number, string, etc.)	 ;AN000;
	       DB	?		   ; matched item tag (if applicable)		 ;AN000;
	       DW	?		   ; synonym ptr (if applicable)		 ;AN000;
RESULT_VAL     DD	?		   ; value					 ;AN000;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; TABLE STRUCTURE FOR RETURNING VALUES TO THE INIT MODULE
;  (ADAPTED FROM VERSION 1.0 DISPLAY.SYS)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TABLE	       LABEL	BYTE		   ; table header				 ;AN000;
DEVICE_NUM     DW	ONE		   ; should only be one device			 ;AN000;
TABLE2_PTR     DW	TABLE2		   ; pointer to table 2 			 ;AN000;

TABLE2	       LABEL	WORD								 ;AN000;
OFFSET_NUM     DW	FOUR		   ; 4 pointer follow				 ;AN000;
TABLE3_PTR     DW	TABLE3		   ; pointer to table 3 (device name)		 ;AN000;
TABLE4_PTR     DW	TABLE4		   ; pointer to table 4 (device id)		 ;AN000;
TABLE5_PTR     DW	TABLE5		   ; pointer to table 5 (hwcp's)                 ;AN000;
TABLE6_PTR     DW	TABLE6		   ; pointer to table 6 (num desg's and fonts)   ;AN000;

TABLE3	       LABEL	WORD		   ; device name (ie. CON)			 ;AN000;
T3_LENGTH      DW	EIGHT		   ; length					 ;AN000;
T3_NAME        DB	"CON     "         ; value                                       ;AN000;

TABLE4	       LABEL	WORD		   ; device id. (eg. EGA,MONO...)		 ;AN000;
T4_LENGTH      DW	ZERO		   ; length					 ;AN000;
T4_NAME        DB	"        "         ; value                                       ;AN000;

TABLE5	       LABEL	WORD		   ; hardware code pages			 ;AN000;
T5_NUM	       DW	ZERO		   ; only 1 for CON				 ;AN000;
T5_VALUE       DW	?		   ; value					 ;AN000;

TABLE6	       LABEL	WORD		   ; Designates and fonts			 ;AN000;
T6_NUM	       DW	ZERO		   ; values given (0 - 2 valid) 		 ;AN000;
T6_DESG        DW	?		   ; n value					 ;AN000;
T6_FONT        DW	?		   ; m value					 ;AN000;


OK_FLAG        DB	ON		   ; FLAG INDICATING PARSE STATUS		 ;AN000;
LOOP1	       DB	ZERO								 ;AN000;
LOOP2	       DB	ZERO								 ;AN000;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARSER
;
; FUNCTION:
; THIS PROCEDURE PARSES THE DEVICE= PARAMETERS FROM THE INIT REQUEST
; BLOCK.
;
; AT ENTRY: ES:DI POINTS TO REQUEST HEADER
;
; AT EXIT:
;    NORMAL: TABLE SET UP WITH VALUES FOUND
;
;    ERROR: 0 LOADED IN FIRST WORD OF TABLE
;
; AUTHOR: WGR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSER	PROC	 NEAR									 ;AN000;
	PUSH	 ES									 ;AN000;
	PUSH	 BX									 ;AN000;
	PUSH	 DS			  ;						 ;AN000;
	PUSH	 SI			  ;						 ;AN000;
	LDS	 SI,RH.RH0_BPBA 	  ;						 ;AN000;
	PUSH	 CS			  ; establish ES ..				 ;AN000;
	POP	 ES			  ; addressability to data			 ;AN000;
	LEA	 DI,PARMS1		  ; point to PARMS control block		 ;AN000;
	XOR	 CX,CX			  ; clear both CX and DX for			 ;AN000;
	XOR	 DX,DX			  ;  SYSPARSE					 ;AN000;
	CALL	 SYSPARSE		  ; move pointer past file spec 		 ;AN000;
	CALL	 SYSPARSE		  ; do first parse				 ;AN000;
	.WHILE <AX NE RC_EOL> AND	  ; EOL?...then end parse...and..		 ;AN000;
	.WHILE <OK_FLAG EQ ON>		  ; make sure that flag still ok..		 ;AN000;
	  .IF <AX NE RC_NO_ERROR>	  ; parse error?				 ;AN000;
	    MOV     OK_FLAG,OFF 	  ; yes...reset flag				 ;AN000;
	  .ELSE 			  ; no...process..				 ;AN000;
	    .SELECT			  ;						 ;AN000;
	    .WHEN <RESULT_TYPE EQ COMPLEX> ; complex string found?			 ;AN000;
	      INC    LOOP1		  ; increment count				 ;AN000;
	      .IF <LOOP1 GT ONE>	  ; more than one?				 ;AN000;
		MOV    OK_FLAG,OFF	  ; yes....we have an error			 ;AN000;
	      .ELSE			  ; no ..					 ;AN000;
		CALL   PARSE_MAIN	  ; process complex string..			 ;AN000;
	      .ENDIF			  ;						 ;AN000;
	    .OTHERWISE			  ; not a complex string so..			 ;AN000;
	      MOV    OK_FLAG,OFF	  ; we have a problem...reset flag		 ;AN000;
	    .ENDSELECT			  ;						 ;AN000;
	    CALL   SYSPARSE		  ; continue parsing..				 ;AN000;
	  .ENDIF			  ;						 ;AN000;
	.ENDWHILE			  ;						 ;AN000;
	.IF <OK_FLAG EQ OFF> OR 	  ; flag indicating error?			 ;AN000;
	.IF <LOOP1 EQ ZERO>		  ; or no parameters specified? 		 ;AN000;
	  MOV	DEVICE_NUM,ZERO 	  ; yes...set device number to 0		 ;AN000;
	  STC				  ;						 ;AN000;
	.ELSE				  ;						 ;AN000;
	  CLC				  ;						 ;AN000;
	.ENDIF				  ;						 ;AN000;
	POP    SI			  ;						 ;AN000;
	POP    DS			  ;						 ;AN000;
	POP    BX			  ;						 ;AN000;
	POP    ES			  ;						 ;AN000;
	RET				  ;						 ;AN000;
PARSER	ENDP										 ;AN000;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARSE_MAIN
;
; FUNCTION:
; THIS PROCEDURE PARSES THE CON=(    ) COMPLEX LIST DEVICE= LINE FOUND
; IN CONFIG.SYS
;
; AT ENTRY: RESULT BUFFER CONTAINS POINTER TO COMPLEX STRING
;
; AT EXIT:
;    NORMAL: TABLE SET UP WITH VALUES FOUND
;
;    ERROR: OK_FLAG = 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSE_MAIN  PROC   NEAR 								 ;AN000;
	    PUSH   DI			  ; setup to parse the nested.. 		 ;AN000;
	    PUSH   DS			  ; complex string...but save.. 		 ;AN000;
	    PUSH   SI			  ; current parsing status.			 ;AN000;
	    PUSH   CX			  ;						 ;AN000;
	    XOR    CX,CX		  ;						 ;AN000;
	    LEA    DI,PARMS2		  ; next control block..			 ;AN000;
	    LDS    SI,RESULT_VAL	  ; point to stored string			 ;AN000;
	    CALL   SYSPARSE		  ;						 ;AN000;
	    .WHILE <AX NE RC_EOL> AND	  ; not EOL?   and..				 ;AN000;
	    .WHILE <OK_FLAG EQ ON>	  ; error flag still ok?			 ;AN000;
	      .IF <AX NE RC_NO_ERROR>	  ; check for parse errors			 ;AN000;
		MOV    OK_FLAG,OFF	  ; yes....reset error flag			 ;AN000;
	      .ELSE			  ; no...process				 ;AN000;
		INC    LOOP2		  ;						 ;AN000;
		.SELECT 		  ;						 ;AN000;
		.WHEN <RESULT_TYPE EQ STRING> ; simple string				 ;AN000;
		  CALL	 PARSE_STR	  ; yes...process				 ;AN000;
		.WHEN <RESULT_TYPE EQ NUMBER> ; number?..				 ;AN000;
		  CALL	 PARSE_NUM	  ; yes...process				 ;AN000;
		.WHEN <RESULT_TYPE EQ COMPLEX> ; complex string?			 ;AN000;
		  CALL	 PARSE_COMPLEX	  ;AN002;
		.OTHERWISE		  ; anything else is..				 ;AN000;
		  MOV	 OK_FLAG,OFF	  ; an error...reset flag.			 ;AN000;
		.ENDSELECT		  ;						 ;AN000;
		CALL   SYSPARSE 	  ; continue parsing				 ;AN000;
	      .ENDIF			  ;						 ;AN000;
	    .ENDWHILE			  ;						 ;AN000;
	    POP    CX			  ; restore original parse..			 ;AN000;
	    POP    SI			  ; registers.					 ;AN000;
	    POP    DS			  ;						 ;AN000;
	    POP    DI			  ;						 ;AN000;
	    RET 			  ;						 ;AN000;
PARSE_MAIN  ENDP

;
PARSE_COMPLEX	PROC		 ;AN002;
	.IF  <LOOP2 EQ TWO>	 ;AN002; Should be for HWCP
	     CALL  PARSE_COMP_X  ;AN002; for (hwcp)
	.ELSE			 ;AN002;
	     CALL   PARSE_COMP	 ; yes...process for (n,m)				 ;AN000;
	.ENDIF			 ;AN002;
	ret			 ;AN002;
PARSE_COMPLEX	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARSE_COMP_X
;
; FUNCTION:
; THIS PROCEDURE PARSES A COMPLEX LIST FOUND WITHIN THE CON=(	)
; COMPLEX LIST for (hwcp).
;
; AT ENTRY: RESULT BUFFER CONTAINS POINTER TO COMPLEX STRING
;
; AT EXIT:
;    NORMAL: TABLE SET UP WITH VALUES FOUND
;
;    ERROR: OK_FLAG = 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSE_COMP_X PROC   NEAR		  ;AN002;
	     PUSH   DI			  ;AN002; setup ro parse the nested..
	     PUSH   DS			  ;AN002; complex string..saving the..
	     PUSH   SI			  ;AN002; current parse status.
	     PUSH   CX			  ;AN002;
	     XOR    CX,CX		  ;AN002;
	     LEA    DI,PARMS3_X 	  ;AN002; next control block
	     LDS    SI,RESULT_VAL	  ;AN002; point to stored string.
	     CALL   SYSPARSE		  ;AN002;
	     .WHILE <AX NE RC_EOL> AND	  ;AN002; not EOL?...and..
	     .WHILE <OK_FLAG EQ ON>	  ;AN002; error flag still okay?
	       .IF <AX NE RC_NO_ERROR> OR ;AN002; parse error?...or..
	       .IF <RESULT_TYPE NE NUMBER> ;AN002; something other than a number..
		 MOV	OK_FLAG,OFF	  ;AN002; found?....yes..reset flag.
	       .ELSE			  ;AN002; no...process..
		 INC	T5_NUM		  ;AN002; increment counter
		 MOV	AX,WORD PTR RESULT_VAL ;AN002; get numeric value into word
		 MOV	T5_VALUE,AX	  ;AN002; yes...number of designates.
		 CALL	SYSPARSE	  ;AN002; continue parsing
	       .ENDIF			  ;AN002;
	     .ENDWHILE			  ;AN002;
	     POP    CX			  ;AN002; restore previous parse..
	     POP    SI			  ;AN002; registers.
	     POP    DS			  ;AN002;
	     POP    DI			  ;AN002;
	     RET			  ;AN002;
PARSE_COMP_X ENDP			  ;AN002;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARSE_COMP
;
; FUNCTION:
; THIS PROCEDURE PARSES A COMPLEX LIST FOUND WITHIN THE CON=(	)
; COMPLEX LIST for (n,m).
;
; AT ENTRY: RESULT BUFFER CONTAINS POINTER TO COMPLEX STRING
;
; AT EXIT:
;    NORMAL: TABLE SET UP WITH VALUES FOUND
;
;    ERROR: OK_FLAG = 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSE_COMP   PROC   NEAR								 ;AN000;
	     PUSH   DI			  ; setup ro parse the nested.. 		 ;AN000;
	     PUSH   DS			  ; complex string..saving the..		 ;AN000;
	     PUSH   SI			  ; current parse status.			 ;AN000;
	     PUSH   CX			  ;						 ;AN000;
	     XOR    CX,CX		  ;						 ;AN000;
	     LEA    DI,PARMS3		  ; next control block				 ;AN000;
	     LDS    SI,RESULT_VAL	  ; point to stored string.			 ;AN000;
	     CALL   SYSPARSE		  ;						 ;AN000;
	     .WHILE <AX NE RC_EOL> AND	  ; not EOL?...and..				 ;AN000;
	     .WHILE <OK_FLAG EQ ON>	  ; error flag still okay?			 ;AN000;
	       .IF <AX NE RC_NO_ERROR> OR ; parse error?...or.. 			 ;AN000;
	       .IF <RESULT_TYPE NE NUMBER> ; something other than a number..		 ;AN000;
		 MOV	OK_FLAG,OFF	  ; found?....yes..reset flag.			 ;AN000;
	       .ELSE			  ; no...process..				 ;AN000;
		 INC	T6_NUM		  ; increment counter				 ;AN000;
		 MOV	AX,WORD PTR RESULT_VAL ; get numeric value into word		 ;AN000;
		 .IF <T6_NUM EQ ONE>	  ; first value found?				 ;AN000;
		   MOV	  T6_DESG,AX	  ; yes...number of designates. 		 ;AN000;
		 .ELSE			  ; else..					 ;AN000;
		   MOV	  T6_FONT,AX	  ; second number...number of fonts.		 ;AN000;
		 .ENDIF 		  ;						 ;AN000;
		 CALL	SYSPARSE	  ; continue parsing				 ;AN000;
	       .ENDIF			  ;						 ;AN000;
	     .ENDWHILE			  ;						 ;AN000;
	     POP    CX			  ; restore previous parse..			 ;AN000;
	     POP    SI			  ; registers.					 ;AN000;
	     POP    DS			  ;						 ;AN000;
	     POP    DI			  ;						 ;AN000;
	     RET			  ;						 ;AN000;
PARSE_COMP   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARSE_STR
;
; FUNCTION:
; THIS PROCEDURE PARSES A STRING FOUND WITHIN THE CON=(   ) STATEMENT
;
; AT ENTRY: RESULT BUFFER POINTS TO ASCIIZ STRING
;
; AT EXIT:
;    NORMAL: TABLE SET UP WITH VALUES FOUND
;
;    ERROR: N/A
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSE_STR    PROC   NEAR								 ;AN000;
	     PUSH   DI			  ; get source and..				 ;AN000;
	     PUSH   DS			  ; destination registers..			 ;AN000;
	     PUSH   SI			  ; setup.					 ;AN000;
	     LDS    SI,RESULT_VAL	  ;						 ;AN000;
	     .IF <<BYTE PTR DS:[SI]> NE ZERO> ; check for null string			 ;AN000;
	       LEA    DI,T4_NAME	  ;						 ;AN000;
	       LODSB			  ; load first character.			 ;AN000;
	       .WHILE <AL NE ZERO>	  ; while not at end of ASCIIZ do..		 ;AN000;
		 STOSB			  ; store..					 ;AN000;
		 LODSB			  ; load next character..			 ;AN000;
	       .ENDWHILE		  ;						 ;AN000;
	       MOV    T4_LENGTH,EIGHT	  ; value found.				 ;AN000;
	     .ENDIF			  ;						 ;AN000;
	     POP    SI			  ; restore registers.				 ;AN000;
	     POP    DS			  ;						 ;AN000;
	     POP    DI			  ;						 ;AN000;
	     RET									 ;AN000;
PARSE_STR    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARSE_NUM
;
; FUNCTION:
; THIS PROCEDURE PARSES NUMBERS FOUND IN THE CON=(   ) STATEMENT
; BLOCK.
;
; AT ENTRY: RESULT BUFFER CONTAINS A DWORD NUMBER VALUE
;
; AT EXIT:
;    NORMAL: TABLE SET UP WITH VALUES FOUND
;
;    ERROR: N/A
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSE_NUM    PROC   NEAR								 ;AN000;
	     MOV    AX,WORD PTR RESULT_VAL   ; get value into word form 		 ;AN000;
	     .IF <LOOP2 EQ TWO> 	     ; if this is the code page then..		 ;AN000;
		MOV   T5_VALUE,AX	     ; load that value. 			 ;AN000;
		INC   T5_NUM		     ;						 ;AN000;
	     .ELSEIF <LOOP2 EQ THREE>	     ;						 ;AN000;
		MOV   T6_DESG,AX	     ; must be number of designates..		 ;AN000;
		INC   T6_NUM		     ; load and increment count 		 ;AN000;
	     .ENDIF			     ;						 ;AN000;
	     RET			     ;						 ;AN000;
PARSE_NUM    ENDP									 ;AN000;


	     ASSUME CS:CODE,DS:CODE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: GET_DEVICE_ID
;
; FUNCTION:
; THIS PROCEDURE RETURNS THE DISPLAY DEVICE TO THE INIT ROUTINE WHEN
; A DEVICE ID IS NOT SUPPLIED.
;
; AT ENTRY: N/A
;
; AT EXIT:
;    NORMAL: DEVICE ID PLACED WITHIN THE TABLE. (EGA OR LCD)
;	     CARRY IS CLEARED.
;
;    ERROR:  DEVICE ID IS MONO OR CGA
;	     CARRY IS SET.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNC_INFO	  INFO_BLOCK <> 							 ;AN000;

DEVICE_N_LENGTH   EQU	EIGHT								 ;AN000;

DEVICE_TYPES	  DB	"EGA     "                                                       ;AN000;
		  DB	"LCD     "                                                       ;AN000;

NUM_DEVICE_TYPES  EQU ($-DEVICE_TYPES)/DEVICE_N_LENGTH					 ;AN000;

DEVICE_FLAG	  DB	00000000B							 ;AN000;


GET_DEVICE_ID  PROC   NEAR								 ;AN000;
	       PUSH   AX								 ;AN000;
	       PUSH   BX			  ;					 ;AN000;
	       PUSH   CX			  ; s					 ;AN000;
	       PUSH   DX			  ;  a	 r				 ;AN000;
	       PUSH   DI			  ;   v   e				 ;AN000;
	       PUSH   SI			  ;    e   g				 ;AN000;
	       PUSH   ES			  ;	    i				 ;AN000;
	       PUSH   DS			  ;	     s				 ;AN000;
	       PUSH   CS			  ;	      t 			 ;AN000;
	       POP    DS			  ;	       e			 ;AN000;
	       PUSH   CS			  ;		r			 ;AN000;
	       POP    ES			  ;		 s			 ;AN000;
	       XOR    AX,AX			  ;					 ;AN000;
	       MOV    AH,FUNC_CALL		  ;					 ;AN000;
	       LEA    DI,FUNC_INFO		  ;					 ;AN000;
	       XOR    BX,BX			  ;					 ;AN000;
	       INT    10H			  ; try VGA functionality call		 ;AN000;
	       .IF <AL EQ FUNC_CALL>		  ; worked?....then			 ;AN000;
		 OR	DEVICE_FLAG,VGA_FOUND	  ; VGA found.				 ;AN000;
	       .ELSE				  ; no VGA...try EGA			 ;AN000;
		 MOV	AH,ALT_SELECT		  ;					 ;AN000;
		 MOV	BL,EGA_INFO_CALL	  ;					 ;AN000;
		 INT	10H			  ;					 ;AN000;
		 .IF <BL NE EGA_INFO_CALL>	  ; if changed then EGA present..	 ;AN000;
		   OR	  DEVICE_FLAG,EGA_FOUND   ; mark as found.			 ;AN000;
		 .ELSE				  ; no EGA...try LCD.			 ;AN000;
		   MOV	  AH,GET_SYS_ID 	  ; get system id..			 ;AN000;
		   INT	  15H			  ; yup....its a convertible..so	 ;AN000;
		   .IF <ES:[BX].MODEL_BYTE EQ LCD_MODEL> AND				 ;AN000;
		   MOV	  AH,GET_STATUS 	  ; check for LCD..			 ;AN000;
		   INT	  15H			  ;					 ;AN000;
		   .IF <BIT AL NAND ON> 	  ; yes....bit says LCD..so..		 ;AN000;
		     OR     DEVICE_FLAG,LCD_FOUND ; mark as LCD.			 ;AN000;
		   .ENDIF			  ;					 ;AN000;
		 .ENDIF 			  ;					 ;AN000;
	       .ENDIF				  ;					 ;AN000;
	       .IF <DEVICE_FLAG NE ZERO>	  ; nothing found?..then exit (eg. MONO) ;AN000;
		 LEA	SI,DEVICE_TYPES 	  ; start of new id's                    ;AN000;
		 SAR	DEVICE_FLAG,ONE 	  ; shift flag into carry bit		 ;AN000;
		 .WHILE NC			  ; carry not set yet.. 		 ;AN000;
		   ADD	  SI,DEVICE_N_LENGTH	  ; next id				 ;AN000;
		   SAR	  DEVICE_FLAG,ONE	  ; next flag...			 ;AN000;
		 .ENDWHILE			  ;					 ;AN000;
		 PUSH	CS			  ; found....transfer id..		 ;AN000;
		 POP	ES			  ; into the table..			 ;AN000;
		 LEA	DI,T4_NAME		  ;					 ;AN000;
		 MOV	CX,DEVICE_N_LENGTH	  ;					 ;AN000;
		 REP	MOVSB			  ;					 ;AN000;
		 MOV	T4_LENGTH,EIGHT 	  ;					 ;AN000;
		 CLC				  ; clear error flag			 ;AN000;
	       .ELSE				  ;					 ;AN000;
		 STC				  ; set error (ie. MONO or CGA found)	 ;AN000;
	       .ENDIF				  ;					 ;AN000;
	       POP    DS			  ; r					 ;AN000;
	       POP    ES			  ;  e	  r				 ;AN000;
	       POP    SI			  ;   s    e				 ;AN000;
	       POP    DI			  ;    t    g				 ;AN000;
	       POP    DX			  ;	o    i				 ;AN000;
	       POP    CX			  ;	 r    s 			 ;AN000;
	       POP    BX			  ;	  e    t			 ;AN000;
	       POP    AX			  ;		e			 ;AN000;
	       RET				  ;		 r			 ;AN000;
GET_DEVICE_ID  ENDP				  ;		  s



CODE	      ENDS
	      END
