PAGE	    ,132
TITLE	    PARSE CODE AND CONTROL BLOCKS FOR PRINTER.SYS

;****************** START OF SPECIFICATIONS **************************
;
;  MODULE NAME: PARSER.ASM
;
;  DESCRIPTIVE NAME: PARSES THE DEVICE= STATEMENT IN CONFIG.SYS FOR
;		     PRINTER.SYS
;
;  FUNCTION: THE COMMAND LINE PASSED TO PRINTER.SYS IN THE CONFIG.SYS
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
;
;  EXTERNAL REFERENCES:
;
;     ROUTINES: N/A
;
;     DATA AREAS: TABLE - TO CONTAIN VALUES FOUND IN DEVICE= LINE
;
;  NOTES:
;
;  REVISION HISTORY:
;	AN000; - DOS Version 4.00
;	AN001 - GHG Changes had to made for P897.  The PARSER was
;		    changed to need the '=' in the keywords.
;
;      Label: "DOS DISPLAY.SYS Device Driver"
;	      "Version 4.00 (C) Copyright 1988 Microsoft
;	      "Licensed Material - Program Property of Microsoft"
;
;
;****************** END OF SPECIFICATIONS ****************************
;*Modification history ********************************************************
;AN001; p1482 - PRINTER.SYS refused to initialize		   10/6/87 J.K.
;AN002; p2686 No range checking on n parameter for printer.sys	   12/11/87 J.K.
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


.XLIST
INCLUDE     STRUC.INC	     ; Structured macros				    ;AN000;
.LIST

INCLUDE     CPSPEQU.INC 							    ;AN000;

PUBLIC	    PARSER	     ; near procedure for parsing DEVICE= statement	    ;AN000;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Set assemble switches for parse code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DateSW	      EQU     0 							    ;AN000;
DrvSW	      EQU     0 							    ;AN000;
SwSW	      EQU     0 							    ;AN000;
Val1SW	      EQU     1     ;;AN002;						   ;AN000;
Val2SW	      EQU     0 							    ;AN000;
Val3SW	      EQU     0 							    ;AN000;


CSEG	      SEGMENT  PARA PUBLIC 'CODE'                                           ;AN000;
	      ASSUME CS:CSEG,DS:NOTHING,ES:NOTHING				    ;AN000;


EXTRN	    TABLE:WORD	     ; table for variable storage used by INIT module.	    ;AN000;
EXTRN	    DEVICE_NUM:WORD							    ;AN000;

.XLIST
INCLUDE     PARSE.ASM	    ; Parsing code					    ;AN000;
.LIST


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PARM control block for parsing PRINTER.SYS - DEVICE= command statement.
; Command line looks like:
;
;   DEVICE=[d:][path]PRINTER.SYS LPT#[:]=(type[,[hwcp][,n]])
;     or
;   DEVICE=[d:][path]PRINTER.SYS LPT#[:]=(type[,[(hwcp1,hwcp2,...)][,n]])
;
; The command line will be parsed from left to right, taking care of the
; nesting of complex lists as they occur.
;
; The first level of control blocks is shown below.
; Complex list control blocks follow.
; Null VALUE LIST and RESULT BUFFER are placed after all other PARSE control
; blocks.
;
; d:\path\PRINTER.SYS lpt#=(complex list)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARMS1	       LABEL WORD							    ;AN000;
	       DW	PARMSX1 						    ;AN000;
	       DB	0		   ; no extra delimeters or EOLs.	    ;AN000;

PARMSX1        LABEL BYTE							    ;AN000;
	       DB	1,1		   ; min,max positional operands	    ;AN000;
	       DW	D_NAME		   ; pointer to control block		    ;AN000;
	       DB	0		   ; no switches			    ;AN000;
	       DB	1		   ; 1 or more keywords 		    ;AN000;
	       DW	PRT_LIST	   ; pointer to control block		    ;AN000;

D_NAME	       LABEL WORD							    ;AN000;
	       DW	0200H		   ; file spec				    ;AN000;
	       DW	0001H		   ; cap result by file table		    ;AN000;
	       DW	RESULT_BUF	   ; result				    ;AN000;
	       DW	NOVALS		   ; no value checking done		    ;AN000;
	       DB	0		   ; no keyword/switch synonyms 	    ;AN000;

PRT_LIST       LABEL WORD							    ;AN000;
	       DW	0402H		   ; complex list,  repeats allowed	    ;AN000;
	       DW	0002H		   ; cap result by char table		    ;AN000;
	       DW	RESULT_BUF	   ; result				    ;AN000;
	       DW	NOVALS		   ; no value checking done		    ;AN000;
	       DB	8		   ; 4 keywords 			    ;AN000;
	       DB	"PRN=",0           ;GHG Ä¿                                  ;AN001;
	       DB	"LPT1=",0          ;GHG  ³ 4 possible keywords              ;AN001;
	       DB	"LPT2=",0          ;GHG  ³                                  ;AN001;
	       DB	"LPT3=",0          ;GHG ÄÙ                                  ;AN001;
	       DB	"PRN:=",0          ;GHG Ä¿                                  ;AN001;
	       DB	"LPT1:=",0         ;GHG  ³ 4 possible keywords              ;AN001;
	       DB	"LPT2:=",0         ;GHG  ³   with colon                     ;AN001;
	       DB	"LPT3:=",0         ;GHG ÄÙ                                  ;AN001;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PARM control block for second level of nesting.
; ie. complex list from first level of nesting
;
; (type, hwcp or complex list, n)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARMS2	       LABEL WORD							    ;AN000;
	       DW	PARMSX2 						    ;AN000;
	       DB	0		   ; no extra delimeters or EOLs.	    ;AN000;

PARMSX2        LABEL BYTE							    ;AN000;
	       DB	1,3		   ; min,max positional operands	    ;AN000;
	       DW	PRT_TYPE	   ; pointer to control block		    ;AN000;
	       DW	HWCP		   ; pointer to control block		    ;AN000;
	       DW	CP_PREPS	   ; pointer to control block		    ;AN000;
	       DB	0		   ; no switches			    ;AN000;
	       DB	0		   ; no keywords			    ;AN000;

PRT_TYPE       LABEL BYTE							    ;AN000;
	       DW	2000H		   ; sstring				    ;AN000;
	       DW	0002H		   ; cap by char table			    ;AN000;
	       DW	RESULT_BUF	   ; result				    ;AN000;
	       DW	NOVALS		   ; value list 			    ;AN000;
	       DB	0		   ; no keyword/switch synonyms 	    ;AN000;

HWCP	       LABEL BYTE							    ;AN000;
	       DW	8401H		   ; numeric or complex list (optional)     ;AN000;
	       DW	0		   ; no functions			    ;AN000;
	       DW	RESULT_BUF	   ; result				    ;AN000;
	       DW	NOVALS		   ; no value checking done		    ;AN000;
	       DB	0		   ; no keyword/switch synonyms 	    ;AN000;

CP_PREPS       LABEL BYTE							    ;AN000;
	       DW	8001H		   ; numeric (optional) 		    ;AN000;
	       DW	0		   ; no functions			    ;AN000;
	       DW	RESULT_BUF	   ; result				    ;AN000;
	       DW	N_Val_Range	   ;AN002; value list				  ;AN000;
	       DB	0		   ; no keyword/switch synonyms 	    ;AN000;


N_Val_Range    label   byte
	       db      1		   ;AN002; Range defintion
	       db      1		   ;AN002; Number of ranges
	       db      1		   ;AN002; item tag
	       dd      0, 12		   ;AN002; 0 - 12

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PARM control block for third level of nesting.
; ie. complex list from second nesting level
;
; (hwcp1,hwcp2,...)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARMS3	       LABEL WORD							    ;AN000;
	       DW	PARMSX3 						    ;AN000;
	       DB	0		   ; no extra delimeters or EOLs.	    ;AN000;

PARMSX3        LABEL BYTE							    ;AN000;
	       DB	1,1		   ; min,max positional operands	    ;AN000;
	       DW	HWCPS		   ; pointer to control block		    ;AN000;
	       DB	0		   ; no switches			    ;AN000;
	       DB	0		   ; no keywords			    ;AN000;

HWCPS	       LABEL BYTE							    ;AN000;
	       DW	8003H		   ; numeric, repeats allowed		    ;AN000;
	       DW	0		   ; no functions			    ;AN000;
	       DW	RESULT_BUF	   ; result				    ;AN000;
	       DW	NOVALS		   ; no value checking done		    ;AN000;
	       DB	0		   ; no keyword/switch synonyms 	    ;AN000;


; Null VALUE LIST and RESULT BUFFER for all PARSE control blocks


NOVALS	       LABEL BYTE							    ;AN000;
	       DB	0		   ; no value checking done		    ;AN000;

RESULT_BUF     LABEL BYTE							    ;AN000;
RESULT_TYPE    DB	?		   ; type returned (number, string, etc.)   ;AN000;
	       DB	?		   ; matched item tag (if applicable)	    ;AN000;
SYN_PTR        DW	?		   ; synonym ptr (if applicable)	    ;AN000;
RESULT_VAL     DD	?		   ; value				    ;AN000;


OK_FLAG        DB	ON		   ; FLAG INDICATING PARSE STATUS	    ;AN000;
NUM_LOOP       DB	ZERO							    ;AN000;


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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSER	PROC	 NEAR								    ;AN000;
	PUSH	 DX								    ;AN000;
	PUSH	 DI								    ;AN000;
	PUSH	 ES								    ;AN000;
	PUSH	 BX								    ;AN000;
	PUSH	 DS			  ;					    ;AN000;
	PUSH	 SI			  ;					    ;AN000;
	CLD				  ;					    ;AN000;
	LDS	 SI,RH.RH0_BPBA 	  ;					    ;AN000;
	PUSH	 CS			  ; establish ES ..			    ;AN000;
	POP	 ES			  ; addressability to data		    ;AN000;
	LEA	 DI,PARMS1		  ; point to PARMS control block	    ;AN000;
	XOR	 CX,CX			  ; clear both CX and DX for		    ;AN000;
	XOR	 DX,DX			  ;  SYSPARSE				    ;AN000;
	CALL	 SYSPARSE		  ; move pointer past file spec 	    ;AN000;
	CALL	 SYSPARSE		  ; do first parse			    ;AN000;
	LEA	 BX,TABLE		  ;					    ;AN000;
	.WHILE <AX NE RC_EOL> AND	  ; EOL?...then end parse...and..	    ;AN000;
	.WHILE <OK_FLAG EQ ON>		  ; make sure that flag still ok..	    ;AN000;
	  .IF <AX NE RC_NO_ERROR>	  ; parse error?			    ;AN000;
	    MOV     OK_FLAG,OFF 	  ; yes...reset flag			    ;AN000;
	  .ELSE 			  ;					    ;AN000;
	    .SELECT			  ;					    ;AN000;
	    .WHEN <RESULT_TYPE EQ COMPLEX>; complex string found?		    ;AN000;
	      INC    DEVICE_NUM 	  ; increment count			    ;AN000;
	      INC    BX 		  ; point to next device table		    ;AN000;
	      INC    BX 		  ;					    ;AN000;
	      .IF <DEVICE_NUM GT FOUR>	  ; more than one?			    ;AN000;
		MOV    OK_FLAG,OFF	  ; yes....we have an error		    ;AN000;
	      .ELSE			  ; no ..				    ;AN000;
		PUSH   BX		  ;					    ;AN000;
		MOV    BX,CS:[BX]	  ;					    ;AN000;
		CALL   COPY_NAME	  ;					    ;AN000;
		MOV    NUM_LOOP,ZERO	  ;					    ;AN000;
		CALL   PARSE_MAIN	  ; process complex string..		    ;AN000;
		POP    BX		  ;					    ;AN000;
	      .ENDIF			  ;					    ;AN000;
	    .OTHERWISE			  ; not a complex string so..		    ;AN000;
	      MOV    OK_FLAG,OFF	  ; we have a problem...reset flag	    ;AN000;
	    .ENDSELECT			  ;					    ;AN000;
	  .ENDIF			  ;					    ;AN000;
	  PUSH	 BX			  ;					    ;AN000;
	  CALL	 SYSPARSE		  ; continue parsing..			    ;AN000;
	  POP	 BX			  ;					    ;AN000;
	.ENDWHILE			  ;					    ;AN000;
	.IF <OK_FLAG EQ OFF>		  ; flag indicating error?		    ;AN000;
	  MOV	DEVICE_NUM,ZERO 	  ; yes...set device number to 0	    ;AN000;
	  STC				  ;					    ;AN000;
	.ELSE				  ;					    ;AN000;
	  CLC				  ;					    ;AN000;
	.ENDIF				  ;					    ;AN000;
	POP    SI			  ;					    ;AN000;
	POP    DS			  ;					    ;AN000;
	POP    BX			  ;					    ;AN000;
	POP    ES			  ;					    ;AN000;
	POP    DI			  ;					    ;AN000;
	POP    DX			  ;					    ;AN000;
	RET				  ;					    ;AN000;
PARSER	ENDP									    ;AN000;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARSE_MAIN
;
; FUNCTION:
; THIS PROCEDURE PARSES THE LPT=(    ) COMPLEX LIST DEVICE= LINE FOUND
; IN CONFIG.SYS
;
; AT ENTRY: RESULT BUFFER CONTAINS POINTER TO COMPLEX STRING
;
; AT EXIT:
;    NORMAL: TABLE SET UP WITH VALUES FOUND
;
;    ERROR: OK_FLAG = 0
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSE_MAIN  PROC   NEAR 							    ;AN000;
	    PUSH   BX			  ;					    ;AN000;
	    PUSH   DI			  ; setup to parse the nested.. 	    ;AN000;
	    PUSH   DS			  ; complex string...but save.. 	    ;AN000;
	    PUSH   SI			  ; current parsing status.		    ;AN000;
	    PUSH   CX			  ;					    ;AN000;
	    XOR    CX,CX		  ;					    ;AN000;
	    LEA    DI,PARMS2		  ; next control block..		    ;AN000;
	    LDS    SI,RESULT_VAL	  ; point to stored string		    ;AN000;
	    PUSH   BX			  ;					    ;AN000;
	    CALL   SYSPARSE		  ;					    ;AN000;
	    POP    BX			  ;					    ;AN000;
	    .WHILE <AX NE RC_EOL> AND	  ; not EOL?   and..			    ;AN000;
	    .WHILE <OK_FLAG EQ ON>	  ; error flag still ok?		    ;AN000;
	      INC    NUM_LOOP		  ;					    ;AN000;
	      .IF <AX NE RC_NO_ERROR>	  ; check for parse errors		    ;AN000;
		MOV    OK_FLAG,OFF	  ; yes....reset error flag		    ;AN000;
	      .ELSE			  ; no...process			    ;AN000;
		PUSH   BX		  ;					    ;AN000;
		.SELECT 		  ;					    ;AN000;
		.WHEN <RESULT_TYPE EQ STRING> ; simple string			    ;AN000;
		  MOV	 BX,CS:[BX].DI_OFFSET ; 				    ;AN000;
		  CALL	 PARSE_STR	  ; yes...process			    ;AN000;
		.WHEN <RESULT_TYPE EQ NUMBER> ; number?..			    ;AN000;
		  .IF <NUM_LOOP EQ TWO>   ;					    ;AN000;
		    MOV    BX,CS:[BX].DCP_OFFSET				    ;AN000;
		  .ELSE 		  ;					    ;AN000;
		    MOV    BX,CS:[BX].DD_OFFSET 				    ;AN000;
		  .ENDIF		  ;					    ;AN000;
		   MOV	  AX,WORD PTR RESULT_VAL ; get value into word form	    ;AN000;
		   .IF <AX NE ZERO>						    ;AN000;
		     INC    WORD PTR CS:[BX] ;					    ;AN000;
		     MOV    WORD PTR CS:[BX+2],AX ; load that value.		    ;AN000;
		   .ENDIF							    ;AN000;
		.WHEN <RESULT_TYPE EQ COMPLEX> ; complex string?		    ;AN000;
		  MOV	 BX,CS:[BX].DCP_OFFSET ;				    ;AN000;
		  CALL	 PARSE_COMP	  ; yes...process			    ;AN000;
		.OTHERWISE		  ; anything else is..			    ;AN000;
		  MOV	 OK_FLAG,OFF	  ; an error...reset flag.		    ;AN000;
		.ENDSELECT		  ;					    ;AN000;
		CALL   SYSPARSE 	  ; continue parsing			    ;AN000;
		POP    BX		  ;					    ;AN000;
	      .ENDIF			  ;					    ;AN000;
	    .ENDWHILE			  ;					    ;AN000;
	    POP    CX			  ; restore original parse..		    ;AN000;
	    POP    SI			  ; registers.				    ;AN000;
	    POP    DS			  ;					    ;AN000;
	    POP    DI			  ;					    ;AN000;
	    POP    BX			  ;					    ;AN000;
	    RET 			  ;					    ;AN000;
PARSE_MAIN  ENDP								    ;AN000;
										    ;AN000;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARSE_COMP
;
; FUNCTION:
; THIS PROCEDURE PARSES A COMPLEX LIST FOUND WITHIN THE LPT=(	)
; COMPLEX LIST.
;
; AT ENTRY: RESULT BUFFER CONTAINS POINTER TO COMPLEX STRING
;
; AT EXIT:
;    NORMAL: TABLE SET UP WITH VALUES FOUND
;
;    ERROR: OK_FLAG = 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSE_COMP   PROC   NEAR							    ;AN000;
	     PUSH   DI			  ; setup ro parse the nested.. 	    ;AN000;
	     PUSH   DS			  ; complex string..saving the..	    ;AN000;
	     PUSH   SI			  ; current parse status.		    ;AN000;
	     PUSH   CX			  ;					    ;AN000;
	     MOV    DI,BX		  ;					    ;AN000;
	     PUSH   DI			  ;					    ;AN000;
	     XOR    CX,CX		  ;					    ;AN000;
	     LEA    DI,PARMS3		  ; next control block			    ;AN000;
	     LDS    SI,RESULT_VAL	  ; point to stored string.		    ;AN000;
	     PUSH   BX			  ;					    ;AN000;
	     CALL   SYSPARSE		  ;					    ;AN000;
	     POP    BX			  ;					    ;AN000;
	     .WHILE <AX NE RC_EOL> AND	  ; not EOL?...and..			    ;AN000;
	     .WHILE <OK_FLAG EQ ON> AND   ; error flag still okay?		    ;AN000;
	     .WHILE <AX NE RC_OP_MISSING> ;					    ;AN000;
	       .IF <AX NE RC_NO_ERROR>	  ; parse error?...or.. 		    ;AN000;
		 MOV	OK_FLAG,OFF	  ; found?....yes..reset flag.		    ;AN000;
	       .ELSE			  ; no...process..			    ;AN000;
		 INC	WORD PTR CS:[BX]  ; increment counter			    ;AN000;
		 .IF <<WORD PTR CS:[BX]> LE TEN>				    ;AN000;
		   POP	  DI		  ;					    ;AN000;
		   MOV	  AX,WORD PTR RESULT_VAL ; get numeric value into word	    ;AN000;
		   MOV	  WORD PTR CS:[DI+2],AX ;				    ;AN000;
		   INC	  DI		  ;					    ;AN000;
		   INC	  DI		  ;					    ;AN000;
		   PUSH   DI		  ;					    ;AN000;
		   PUSH   BX		  ;					    ;AN000;
		   LEA	  DI,PARMS3	  ;					    ;AN000;
		   CALL   SYSPARSE	  ; continue parsing			    ;AN000;
		   POP	  BX		  ;					    ;AN000;
		 .ELSE			  ;					    ;AN000;
		   MOV	  OK_FLAG,OFF	  ;					    ;AN000;
		 .ENDIF 		  ;					    ;AN000;
	       .ENDIF			  ;					    ;AN000;
	     .ENDWHILE			  ;					    ;AN000;
	     POP    DI			  ;					    ;AN000;
	     POP    CX			  ; restore previous parse..		    ;AN000;
	     POP    SI			  ; registers.				    ;AN000;
	     POP    DS			  ;					    ;AN000;
	     POP    DI			  ;					    ;AN000;
	     RET			  ;					    ;AN000;
PARSE_COMP   ENDP								    ;AN000;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: PARSE_STR
;
; FUNCTION:
; THIS PROCEDURE PARSES A STRING FOUND WITHIN THE LPT=(   ) STATEMENT
;
; AT ENTRY: RESULT BUFFER POINTS TO ASCIIZ STRING
;
; AT EXIT:
;    NORMAL: TABLE SET UP WITH VALUES FOUND
;
;    ERROR: STRING > 8 - OK_FLAG SET OFF
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PARSE_STR    PROC   NEAR							    ;AN000;
	     PUSH   DI			  ; get source and..			    ;AN000;
	     PUSH   DS			  ; destination registers..		    ;AN000;
	     PUSH   SI			  ; setup.				    ;AN000;
	     PUSH   CX			  ;					    ;AN000;
	     LDS    SI,RESULT_VAL	  ;					    ;AN000;
	     MOV    DI,BX		  ;					    ;AN000;
	     MOV    CS:[DI].N_LENGTH,EIGHT ;					    ;AN000;
	     INC    DI			  ;					    ;AN000;
	     INC    DI			  ;					    ;AN000;
	     MOV    CX,EIGHT		  ;					    ;AN000;
	     LODSB			  ; load first character.		    ;AN000;
	     .WHILE <AL NE ZERO> AND	  ; while not at end of ASCIIZ do..	    ;AN000;
	     .WHILE <CX NE ZERO>	  ;					    ;AN000;
	       STOSB			  ; store..				    ;AN000;
	       LODSB			  ; load next character..		    ;AN000;
	       DEC    CX		  ;					    ;AN000;
	     .ENDWHILE			  ;					    ;AN000;
	     .IF <CX EQ ZERO>							    ;AN000;
	       MOV    OK_FLAG,OFF						    ;AN000;
	     .ENDIF								    ;AN000;
	     POP    CX			  ; value found.			    ;AN000;
	     POP    SI			  ; restore registers.			    ;AN000;
	     POP    DS			  ;					    ;AN000;
	     POP    DI			  ;					    ;AN000;
	     RET								    ;AN000;
PARSE_STR    ENDP								    ;AN000;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: COPY_NAME
;
; FUNCTION:
; THIS PROCEDURE COPIES THE FOUND STRING VALUE INTO THE TABLE.
;
; AT ENTRY: N/A
;
; AT EXIT:
;    NORMAL: TABLE UPDATED
;
;    ERROR: N/A
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

COPY_NAME    PROC   NEAR							    ;AN000;
	     PUSH   DI			  ; get source and..			    ;AN000;
	     PUSH   DS			  ; destination registers..		    ;AN000;
	     PUSH   SI			  ; setup.				    ;AN000;
	     PUSH   CS			  ;					    ;AN000;
	     POP    DS			  ;					    ;AN000;
	     MOV    SI,SYN_PTR		  ;					    ;AN000;
	     MOV    DI,CS:[BX].DN_OFFSET  ;					    ;AN000;
	     MOV    CS:[DI].N_LENGTH,EIGHT ;					    ;AN000;
	     INC    DI			  ;					    ;AN000;
	     INC    DI			  ;					    ;AN000;
	     LODSB			  ; load first character.		    ;AN000;
	     .WHILE <AL NE ZERO>	  ; while not at end of ASCIIZ do..	    ;AN000;
	       .IF <AL NE ':'> AND        ;ignore colon                             ;AN001;
	       .IF <AL NE '='>            ; or =                                    ;AN001;
		 STOSB			  ; store..				    ;AN000;
	       .ENDIF			  ;					    ;AN000;
	       LODSB			  ; load next character..		    ;AN000;
	     .ENDWHILE			  ;					    ;AN000;
	     POP    SI			  ; restore registers.			    ;AN000;
	     POP    DS			  ;					    ;AN000;
	     POP    DI			  ;					    ;AN000;
	     RET								    ;AN000;
COPY_NAME    ENDP								    ;AN000;

CSEG	      ENDS
	      END
