;*******************************************************************
; Parser include file
;*******************************************************************
IF1					;AN000;
	%OUT	INCLUDING COMP=COMMON DSN=PSDATA.INC...;AN000;
ENDIF					;AN000;
;
;**** Default assemble switches definition *************************

IFNDEF	FarSW				;AN000;
FarSW	equ	0			;AN000; Near call expected
ENDIF					;AN000;

IFNDEF	DateSW				;AN000;
DateSW	equ	1			;AN000; Check date format
ENDIF					;AN000;

IFNDEF	TimeSW				;AN000;
TimeSW	equ	1			;AN000; Check time format
ENDIF					;AN000;

IFNDEF	FileSW				;AN000;
FileSW	equ	1			;AN000; Check file specification
ENDIF					;AN000;

IFNDEF	CAPSW				;AN000;
CAPSW	equ	1			;AN000; Perform CAPS if specified
ENDIF					;AN000;

IFNDEF	CmpxSW				;AN000;
CmpxSW	equ	1			;AN000; Check complex list
ENDIF					;AN000;

IFNDEF	NumSW				;AN000;
NumSW	equ	1			;AN000; Check numeric value
ENDIF					;AN000;

IFNDEF	KeySW				;AN000;
KeySW	equ	1			;AN000; Support keywords
ENDIF					;AN000;

IFNDEF	SwSW				;AN000;
SwSW	equ	1			;AN000; Support switches
ENDIF					;AN000;

IFNDEF	Val1SW				;AN000;
Val1SW	equ	1			;AN000; Support value definition 1
ENDIF					;AN000;

IFNDEF	Val2SW				;AN000;
Val2SW	equ	1			;AN000; Support value definition 2
ENDIF					;AN000;

IFNDEF	Val3SW				;AN000;
Val3SW	equ	1			;AN000; Support value definition 3
ENDIF					;AN000;

IFNDEF	DrvSW				;AN000;
DrvSW	equ	1			;AN000; Support drive only format
ENDIF					;AN000;

IFNDEF	QusSW				;AN000;
QusSW	equ	1			;AN000; Support quoted string format
ENDIF					;AN000;

IFNDEF	LFEOLSW 			;AN028;
LFEOLSW EQU	1			;AN028; Accept Line feed (0AH) as end of line
ENDIF					;AN028;

;**** Equation field
;-------- Character code definition

$P_DBSP1	   equ	81h		;AN000; 1st byte of DBCS blank
$P_DBSP2	   equ	40h		;AN000; 2nd byte of DBCS blank
$P_Period	   equ	"."             ;AN020;
$P_Slash	   equ	"/"             ;AN020;
$P_Space	   equ	" "             ;AN000; SBCS blank
$P_Comma	   equ	","             ;AN000;
$P_Switch	   equ	"/"             ;AN000;
$P_Keyword	   equ	"="             ;AN000;
$P_Colon	   equ	":"             ;AN000;
$P_Plus 	   equ	"+"             ;AN000;
$P_Minus	   equ	"-"             ;AN000;
$P_Rparen	   equ	")"             ;AN000;
$P_Lparen	   equ	"("             ;AN000;
;(deleted ;AN025;) $P_SQuote	      equ  "'"
$P_DQuote	   equ	'"'             ;AN000;
$P_NULL 	   equ	0		;AN000;
$P_TAB		   equ	9		;AN000;
$P_CR		   equ	0Dh		;AN000;
$P_LF		   equ	0Ah		;AN000;
$P_ASCII80	   equ	80h		;AN000; ASCII 80h character code

;-------- Masks
$P_Make_Lower	   equ	20h		;AN000; make lower case character
$P_Make_Upper	   equ	0ffh-$P_Make_Lower ;AN000; make upper case character

		   PAGE 		   ;AN000;
;-------- DOS function call related equs

$P_DOS_Get_CDI	   equ	3800h		;AN000; get country dependent information
					; by this call, following information
$P_CDI		   struc		;AN000; is returned.
$P_CDI_DateF	   dw	0		;AN000;
$P_CDI_Money	   db	0,0,0,0,0	;AN000;
$P_CDI_1000	   db	0,0		;AN000;
$P_CDI_Dec	   db	0,0		;AN000;
$P_CDI_DateS	   db	0,0		;AN000;
$P_CDI_TimeS	   db	0,0		;AN000;
		   db	0		;AN000;
		   db	0		;AN000;
$P_CDI_TimeF	   db	0		;AN000;
		   dw	0,0		;AN000;
		   db	0,0		;AN000;
		   dw	5 dup(0)	;AN000;
$P_CDI		   ends 		;AN000;

$P_Date_MDY	   equ	0		;AN000;
$P_Date_DMY	   equ	1		;AN000;
$P_Date_YMD	   equ	2		;AN000;
;-------------
$P_DOS_GetEV	   equ	6300h		;AN000; get DBCS EV call
					;AN000; DS:SI will points to DBCS EV
;-------------
$P_DOS_Get_TBL	   equ	65h		;AN000; get uppercase table call
					;AN000; following parameters are set
					;AN000; to get casemap table.
$P_DOSTBL_Def	   equ	-1		;AN000; get default
$P_DOSTBL_BL	   equ	5		;AN000; buffer length for Tbl pointer
$P_DOSTBL_File	   equ	4		;AN000; get file uppercase table
$P_DOSTBL_Char	   equ	2		;AN000; get character uppercase table
					; By this call following information
					; is returned.
$P_DOS_TBL	   struc		;AN000;
$P_DOS_InfoID	   db	0		;AN000; information id for the table
$P_DOS_TBL_Off	   dw	0		;AN000; offset address of the table
$P_DOS_TBL_Seg	   dw	0		;AN000; segment address of the table
$P_DOS_TBL	   ends 		;AN000;
		   PAGE 		;AN000;
;---------------------------------------------------------------------------------------------------------
; PARMS 	LABEL	BYTE
;		DW	PARMSX
;		DB	2			; NUMBER OF STRINGS (0, 1, 2)
;		DB	length			; LENGTH OF THE NEXT LIST, 0 IF NONE
;		DB	" .. "                  ; EXTRA DELIMITER LIST,
;						; TYPICAL ARE ";", "="
;						; "," & WHITESPACE ALWAYS
;		DB	length			; LENGTH OF THE NEXT LIST, 0 IF NONE
;		DB	" .. "                  ; EXTRA END OF LINE LIST, CR, LF OR 0 ALWAYS
;---------------------------------------------------------------------------------------------------------

;-------------------------------- PARMS block structure
$P_PARMS_Blk	   struc		;AN000;
$P_PARMSX_Address  dw	0		;AN000; Address of PARMSX
$P_Num_Extra	   db	0		;AN000; Number of extra stuff
$P_Len_Extra_Delim db	0		;AN000; Length of extra delimiter
$P_PARMS_Blk	   ends 		;AN000;

$P_Len_PARMS	   equ	4		;AN000;
$P_I_Use_Default   equ	0		;AN000; no extra stuff specified
$P_I_Have_Delim    equ	1		;AN000; extra delimiter specified
$P_I_Have_EOL	   equ	2		;AN000; extra EOL specified

;---------------------------------------------------------------------------------------------------------
; PARMSX	LABEL	BYTE
;		DB	minp,maxp		; MIN, MAX POSITIONAL OPERANDS ALLOWED
;		DW	CONTROL 		; DESCRIPTION OF POSITIONAL 1
;		:				; REPEATS maxp-1 TIMES
;		DB	maxs			; # OF SWITCHES
;		DW	CONTROL 		; DESCRIPTION OF SWITCH 1
;		:				; REPEATS maxs-1 TIMES
;		DB	maxk			; # OF KEYWORD
;		DW	CONTROL 		; DESCRIPTION OF KEYWORD 1
;		:				; REPEATS maxk-1 TIMES
;---------------------------------------------------------------------------------------------------------

;-------------------------------- PARMSX block structure
$P_PARMSX_Blk	   struc		;AN000;
$P_MinP 	   db	0		;AN000; Minimum positional number
$P_Maxp 	   db	0		;AN000; Maximum positional number
$P_1st_Control	   dw	0		;AN000; Address of the 1st CONTROL block
$P_PARMSX_Blk	   ends 		;AN000;
		   PAGE 		;AN000;
;---------------------------------------------------------------------------------------------------------
; << Control field definition  >>
;
;
;CONTROL   LABEL   BYTE
;	   DW	   MATCH_FLAGS	   ; CONTROLS TYPE MATCHED
;				   ; 8000H=NUMERIC VALUE, (VALUE LIST WILL BE CHECKED)
;				   ; 4000H=SIGNED NUMERIC VALUE (VALUE LIST WILL BE CHECKED)
;				   ; 2000H=SIMPLE STRING(VALUE LIST WILL BE CHECKED)
;				   ; 1000H=DATE STRING (VALUE LIST WON'T BE CHECKED)
;				   ; 0800H=TIME STRING (VALUE LIST WON'T BE CHECKED)
;				   ; 0400H=COMPLEX LIST (VALUE LIST WON'T BE CHECKED)
;				   ; 0200H=FILE SPEC (VALUE LIST WON'T BE CHECKED)
;				   ; 0100H=DRIVE ONLY (VALUE LIST WON'T BE CHECKED)
;				   ; 0080H=QUOTED STRING (VALUE LIST WON'T BE CHECKED)
;				   ; 0010H=IGNORE ":" AT END IN MATCH
;				   ; 0002H=REPEATS ALLOWED
;				   ; 0001H=OPTIONAL
;	   DW	   FUNCTION_FLAGS
;				   ; 0001H=CAP RESULT BY FILE TABLE
;				   ; 0002H=CAP RESULT BY CHAR TABLE
;				   ; 0010H=REMOVE ":" AT END
; (tm10)			   ; 0020H=colon is not necessary for switch
;	   DW	   RESULT	   ; RESULT BUFFER
;	   DW	   VALUES	   ; VALUE LISTS
;	   DB	   nid		   ; NUMBER OF KEYWORD/SWITCH SYNONYMS IN FOLLOWING LIST
;	   DB	   "...",0         ; IF n >0, KEYWORD 1
;	   :
;
;Note:
;    - The MATCH_FLAG is bit significant. You can set, for example, TIME bit and
;      DATE bit simalteniously.
;
;      The parser examins each bit along with the following priority.
;
;      COMPLEX -> DATE -> TIME -> NUMERIC VAL -> SIGNED NUMERIC VAL -> DRIVE ->
;      FILE SPEC -> SIMPLE STRING.
;
;
;    - When the FUNCTION_FLAG is 0001 or 0002, the STRING pointed to by a pointer
;      in the result buffer is capitalized.
;
;    - Match_Flags 0001H and 0002H have meaning only for the positional.
;
;
;    - The "...",0 (bottom most line) does require '=' or '/'. When you need a
;      switch, for example, '/A', then STRING points to;
;
;			DB    1 	; number of following synonyms
;			DB   '/A',0
;
;      When you need a keyword, for example, 'CODEPAGE=', then "...",0 will be;
;
;			DB    1 	; number of following synonyms
;			DB   'CODEPAGE=',0
;
;
;    - "..." must consist of upper case characters only because the parser
;      performs pattern matching after converting input to upper case (by
;      using the current country upper case table)
;
;
;    - One "..." can contain only one switch or keyword. If you need, for
;      example /A and /B, the format will be;
;
;			DB    2 	; number of following synonyms
;			DB    '/A',0
;			DB    '/B',0
;---------------------------------------------------------------------------------------------------------

;**** Match_Flags

$P_Num_Val	   equ	8000h		;AN000; Numeric Value
$P_SNum_Val	   equ	4000h		;AN000; Signed numeric value
$P_Simple_S	   equ	2000h		;AN000; Simple string
$P_Date_S	   equ	1000h		;AN000; Date string
$P_Time_S	   equ	0800h		;AN000; Time string
$P_Cmpx_S	   equ	0400h		;AN000; Complex string
$P_File_Spc	   equ	0200h		;AN000; File Spec
$P_Drv_Only	   equ	0100h		;AN000; Drive Only
$P_Qu_String	   equ	0080h		;AN000; Quoted string
$P_Ig_Colon	   equ	0010h		;AN000; Ignore colon at end in match
$P_Repeat	   equ	0002h		;AN000; Repeat allowed
$P_Optional	   equ	0001h		;AN000; Optional

;**** Function flags

$P_CAP_File	   equ	0001h		;AN000; CAP result by file table
$P_CAP_Char	   equ	0002h		;AN000; CAP result by character table
$P_Rm_Colon	   equ	0010h		;AN000; Remove ":" at the end
$P_colon_is_not_necessary equ 0020h	;AN000;(tm10) /+10 and /+:10

;-------------------------------- Control block structure
$P_Control_Blk	   struc		;AN000;
$P_Match_Flag	   dw	0		;AN000; Controls type matched
$P_Function_Flag   dw	0		;AN000; Function should be taken
$P_Result_Buf	   dw	0		;AN000; Result buffer address
$P_Value_List	   dw	0		;AN000; Value list address
$P_nid		   db	0		;AN000; # of keyword/SW synonyms
$P_KeyorSW	   db	0		;AN000; keyword or sw
$P_Control_Blk	   ends 		;AN000;
		   PAGE 		;AN000;
;---------------------------------------------------------------------------------------------------------
; << Value List Definition >>
;
;VALUES 	LABEL	BYTE
;		DB	nval			; NUMBER OF VALUE DEFINITIONS (0 - 3)
;	     Ú
;	     ³	DB	nrng			; NUMBER OF RANGES
;	     ³ ÚDB	ITEM_TAG		; RETURN VALUE IF RANGE MATCHED
;	     ³ ÀDD	X,Y			; RANGE OF VALUES
;	     ³	:
;	     ³	DB	nnval			; NUMBER OF CHOICES
;	     ³ ÚDB	ITEM_TAG		; RETURN VALUE IF NUMBER CHOICE MATCHED
;	     ³ ÀDD	VALUE			; SPECIFIC CHOICE IF NUMBER
;	     ³	:
;	     ³	DB	nstrval 		; NUMBER OF CHOICES
;	     ³ ÚDB	ITEM_TAG		; RETURN VALUE IF STRING CHOICE MATCHED
;	     ³ ÀDW	STRING			; SPECIFIC CHOICE IF STING
;	     À	:
;
;STRING 	DB	"...",0                 ; ASCIIZ STRING IMAGE
;
;Note:
;    - ITEM_TAG must not be 0FFH, which will be used in the result buffer
;      when no choice lists are provided.
;
;    - STRING must consist of upper case characters only because the parser
;      performs pattern matching after converting input to upper case (by
;      using the current country upper case table)
;---------------------------------------------------------------------------------------------------------

$P_nval_None	   equ	0		;AN000; no value list ID
$P_nval_Range	   equ	1		;AN000; range list ID
$P_nval_Value	   equ	2		;AN000; value list ID
$P_nval_String	   equ	3		;AN000; string list ID
$P_Len_Range	   equ	9		;AN000; Length of a range choice(two DD plus one DB)
$P_Len_Value	   equ	5		;AN000; Length of a value choice(one DD plus one DB)
$P_Len_String	   equ	3		;AN000; Length of a string choice(one DW plus one DB)
$P_No_nrng	   equ	0		;AN000; (tm07) no nrng. nnval must not be 0.

$P_Val_List	   struc		;AN000;
$P_NumofList	   db	0		;AN000; number of following choice
$P_Val_XL	   dw	0		;AN000; lower word of value
$P_Val_XH	   dw	0		;AN000; higher word of value
$P_Val_YL	   dw	0		;AN000; lower word of another value
$P_Val_YH	   dw	0		;AN000; higher word of another value
$P_Val_List	   ends 		;AN000;
		   PAGE 		;AN000;
;---------------------------------------------------------------------------------------------------------
; << Result Buffer Definition  >>
;
;RESULT 	LABEL	BYTE			; BELOW FILLED IN FOR DEFAULTS
;		DB	type			; TYPE RETURNED: 0=RESERVED,
;						;	1=NUMBER, 2=LIST INDEX,
;						;	3=STRING, 4=COMPLEX,
;						;	5=FILESPEC, 6=DRIVE
;						;	7=DATE, 8=TIME
;						;	9=QUOTED STRING
;		DB	ITEM_TAG		; MATCHED ITEM TAG
;
;		dw	synonym@		; es:@ points to found SYNONYM if provided.
;
;
;	    Ú	DD	n			; VALUE IF NUMBER
;	    ³ or
;	    ³	DW	i			; INDEX (OFFSET) INTO VALUE LIST
;	    ³					; (ES presents Segment address)
;	    ³ or
;	    ³	DD	STRING			; OFFSET OF STRING VALUE
;	    ³ or
;	    ³	DB	drv			; DRIVE NUMBER (1-A, 2-B,..., 26-Z)
;	    ³ or
;	    ³	DW	YEAR	   ;(1980-2099)  IN CASE OF DATE
;	    ³	DB	MONTH	   ;(1-12)	 Note: Range check is not performed.
;	    ³	DB	DATE	   ;(1-31)	       0 is filled when the corresponding field was not specified.
;	    ³ or
;	    ³	DB	HOUR	   ;(0-23)	  IN CASE OF TIME
;	    ³	DB	MINUTES    ;(0-59)	  Note: Range check is not performed .
;	    ³	DB	SECONDS    ;(0-59)		0 is filled when the corresponding field was not specified .
;	    ³	DB	HUNDREDTHS ;(0-99)
;	    À
;
;
;Note: ITEM_TAG is 0FFH when the caller does not specify the choice
;      list.
;
;      YEAR: If the input value for the year is less than 100, parser
;	     adds 1900 to it.  For example, when 87 is input to parser for
;	     the year value, he returns 1987.
;---------------------------------------------------------------------------------------------------------

;-------------------------------- Result block structure
$P_Result_Blk	   struc		;AN000;
$P_Type 	   db	0		;AN000; Type returned
$P_Item_Tag	   db	0		;AN000; Matched item tag
$P_SYNONYM_Ptr	   dw	0		;AN000; pointer to Synonym list returned
$P_Picked_Val	   db	0,0,0,0 	;AN000; value
$P_Result_Blk	   ends 		;AN000;
;--------------------------------
;**** values for the type field in the result block

$P_EOL		   equ	0		;AN000; End of line
$P_Number	   equ	1		;AN000; Number
$P_List_Idx	   equ	2		;AN000; List Index
$P_String	   equ	3		;AN000; String
$P_Complex	   equ	4		;AN000; Complex
$P_File_Spec	   equ	5		;AN000; File Spec
$P_Drive	   equ	6		;AN000; Drive
$P_Date_F	   equ	7		;AN000; Date
$P_Time_F	   equ	8		;AN000; Time
$P_Quoted_String   equ	9		;AN000; Quoted String

$P_No_Tag	   equ	0FFH		;AN000; No ITEM_TAG found
;**** Return code
;
; following return code will be returned in the AX register.

$P_No_Error	   equ	0		;AN000; No error
$P_Too_Many	   equ	1		;AN000; Too many operands
$P_Op_Missing	   equ	2		;AN000; Required operand missing
$P_Not_In_SW	   equ	3		;AN000; Not in switch list provided
$P_Not_In_Key	   equ	4		;AN000; Not in keyword list provided
$P_Out_Of_Range    equ	6		;AN000; Out of range specified
$P_Not_In_Val	   equ	7		;AN000; Not in value list provided
$P_Not_In_Str	   equ	8		;AN000; Not in string list provided
$P_Syntax	   equ	9		;AN000; Syntax error
$P_RC_EOL	   equ	-1		;AN000; End of command line

		   PAGE 		;AN000;
;********************** Local Data *************************************
$P_ORDINAL	   dw	0		;AN000; Operand ordinal save area
$P_RC		   dw	0		;AN000; Return code from parser
$P_SI_Save	   dw	0		;AN000; Pointer of command buffer
$P_DX		   dw	0		;AN000; Return result buffer address
$P_Terminator	   db	0		;AN000; Terminator code (ASCII)
$P_DBCSEV_OFF	   dw	0		;AN000; Offset of DBCS EV
$P_DBCSEV_SEG	   dw	0		;AN000; Segment of DBCS EV
$P_Flags	   dw	0		;AN000; Parser internal flags
$P_Flags1	   equ	byte ptr $P_Flags ;AN038; to reference first byte flags
$P_Flags2	   equ	byte ptr $P_Flags+1 ;AN038; to reference second byte flags only

;in second byte of $P_Flags, referenced as $P_Flags2:
$P_equ		   equ	01h	      ;AN000; "=" packed in string buffet
$P_Neg		   equ	02h	      ;AN000; Negative value
$P_Time12	   equ	04h	      ;AN000; set when PM is specified
$P_Key_Cmp	   equ	08h	      ;AN000; set when keyword compare
$P_SW_Cmp	   equ	10h	      ;AN000; set when switch compare
$P_Extra	   equ	20h	      ;AN000; set when extra delimiter found
$P_SW		   equ	40h	      ;AN000; set when switch found (tm08)
$P_Signed	   equ	80h	      ;AN000; signed numeric specified

;in first byte of $P_Flags, referenced as $P_Flags1:
$P_time12am	   equ	01h	      ;AN038; set when AM is specified on time
$P_TIME_AGAIN	   EQU	02H	      ;AN039; SET WHEN READY TO RE-PARSE TIME

$P_SaveSI_Cmpx	   dw	0		;AN000; save si for later use by complex
$P_KEYorSW_Ptr	   dw	0		;AN000; points next to "=" or ":" code
$P_Save_EOB	   dw	0		;AN000; save pointer to EOB
$P_Found_SYNONYM   dw	0		;AN000; es:@ points to found synonym

$P_STRING_BUF	   db	128 dup(0)	;AN000; Pick a operand from command line
$P_STRING_BUF_END  equ	$		;AN000;
IF		   TimeSw		;AN039; For TIME only
$P_ORIG_ORD	   DW	0		;AN039; ORIGINAL ORDINAL FROM CX
$P_ORIG_STACK	   DW	0		;AN039; ORIGINAL VALUE OF STACK FROM SP
$P_ORIG_SI	   DW	0		;AN039; ORIGINAL START PARSE POINTER FROM SI
ENDIF					;AN039;
IF		   DateSw+TimeSw	;AN000;(Check if date or time format is supported)
;------------------------------
;
$P_Got_Time	   db	0		;AN023; if 1, use Time delimiters
$P_NeedToBeRead    equ	0ffffh		;AN000;

$P_COUNTRY_INFO    $P_CDI <$P_NeedToBeRead> ;AN000;
;
$P_1st_Val	   dw	0		;AN000; used when process date or time
$P_2nd_Val	   dw	0		;AN000; used when process date or time
$P_3rd_Val	   dw	0		;AN000; used when process date or time
$P_4th_Val	   dw	0		;AN000; used when process date or time
;------------------------------
ENDIF					;AN000;(of DateSW+TimeSW)
$P_Char_CAP_Ptr    db	0ffh		;AN000; info id
		   dw	0		;AN000; offset	of char case map table
		   dw	0		;AN000; segment of char case map table
IF		   CAPSW		;AN000;(Check if uppercase conversion is supported)
$P_File_CAP_Ptr    db	0ffh		;AN000; info id
		   dw	0		;AN000; offset	of file case map table
		   dw	0		;AN000; segment of file case map table
ENDIF					;AN000;(of CAPSW)
; (tm06) IF	   FileSW		;AN000;(Check if file spec is supported)
IF		   FileSW+DrvSW 	;AN000;(Check if file spec is supported)
$P_FileSp_Char	   db	'[]|<>+=;"'     ;AN000; delimitter of file spec
$P_FileSp_Len	   equ	$-$P_FileSp_Char ;AN000;
ENDIF					;AN000;(of FileSW)
; (tm05) IF	   QusSW		;AN000;(Check if quoted string is supported)
;(deleted ;AN025;) IF		      QusSW+CmpxSW	   ; (tm05) ;AN000;(Check if quoted string is supported)
;(deleted ;AN025;) $P_SorD_Quote      db   0		   ;AN000; keep double or single quote
;(deleted ;AN025;) ENDIF				   ;AN000;(of QueSW)
IF		   KeySW		;AN029; if keywords supported
$P_count_to_eol    dw	0		;AN029; count of chars not including EOL
;	REGISTER EQUATES - SPECIAL USAGE FOR REGISTERS
$P_REG_BH_CG_SW    EQU	BH		;AN029;0="NO CHANGES MADE", FF=CHANGES MADE
$P_REG_BL_DQ_SW    EQU	BL		;AN029;0=NOT IN QUOTES,FF=IN QUOTES

$P_DOUBLE_QUOTE    EQU	""""            ;AN029;
$P_BL_EQ	   EQU	" ="            ;AN029;
$P_EQ_BL	   EQU	"= "            ;AN029;
$P_TB_EQ	   EQU	093DH		;AN029; ;"<TAB>="
$P_EQ_TB	   EQU	3D09H		;AN029; ;"=<TAB>"
ENDIF					;AN029; IF KeySW Supported

; delimiter parsing
$P_colon_period    equ	01		;AN032; check for colon & period
$P_period_only	   equ	02		;AN032; check only for period

;filespec error flag
$P_err_flag	   db	00		;AN033; flag set if filespec parsing error
					;AN033;  was detected.
$P_error_filespec  equ	01		;AN033; mask to set flag
;***********************************************************************
