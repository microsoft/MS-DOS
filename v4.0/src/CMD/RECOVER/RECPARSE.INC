
const	segment public para 'const' ;AC000;bgb
;***************************************************************************
; Equates
;***************************************************************************
;
;Match Flags
Numeric_Value		equ	8000h		; AN000
Signed_Numeric_Value	equ	4000h		; AN000
Simple_String		equ	2000h		; AN000
Date_String		equ	1000h		; AN000
Time_String		equ	0800h		; AN000
Complex_List		equ	0400h		; AN000
Filespec		equ	0200h		; AN000
Drive_Only		equ	0100h		; AN000
Quoted_String		equ	0080h		; AN000
Ignore_Colon		equ	0010h		; AN000
Repeats_Allowed 	equ	0002h		; AN000
Optional		equ	0001h		; AN000

;Function_Flags

File_Table_Capitalize	equ	1		; AN000
Char_Table_Capitalize	equ	2		; AN000
Remove_Colon		equ	10h		; AN000

;Extra delimeters and EOL

No_Extra_Delimiters	equ	00h		; AN000;SM
Delimiters_Only 	equ	1		; AN000
EOL_Or_Delimiters	equ	2		; AN000

Semi_Colon		equ	";"             ; AN000
Tab			equ	09h		; AN000
Colon			equ	":"             ; AN000


;Parse Errors

No_Error		equ	0		; AN000
Too_Many_Operands	equ	1		; AN000
Operand_Missing 	equ	2		; AN000
Not_In_Switch_List	equ	3		; AN000
Not_In_Keyword_List	equ	4		; AN000
Out_Of_Range		equ	6		; AN000
Not_In_Value_List	equ	7		; AN000
Not_In_String_List	equ	8		; AN000
Syntax_Error		equ	9		; AN000
End_Of_Parse		equ	-1		; AN000

;Return types

Type_Reserved		equ	0		;				;AN000;
Type_Number		equ	1		;				;AN000;
Type_List_Index 	equ	2		;				;AN000;
Type_String		equ	3		;				;AN000;
Type_Complex		equ	4		;				;AN000;
Type_Filespec		equ	5		;				;AN000;
Type_Drive		equ	6		;				;AN000;
Type_Date		equ	7		;				;AN000;
Type_Time		equ	8		;				;AN000;
Type_Quoted_String	equ	9		;				;AN000;


;Other

None			equ	0		; AN000
No_Error		equ	0		; AN000
Switch_Found		equ	0FFFFh		; AN000
Range_Ok		equ	1		; AN000
Command_Line_Parms	equ	81h		; AN000
const	ends  ;AC000;bgb

data	segment public para 'DATA'  ;AC000;bgb
;***************************************************************************** ;AN000;bgb
;***************************************************************************** ;AN000;bgb
; Parse Tables								       ;AN000;bgb
;***************************************************************************** ;AN000;bgb
;***************************************************************************** ;AN000;bgb
;									       ;AN000;bgb
;The following parse control block can be used for any command which	       ;AN000;bgb
;needs only one optional file specification an operand.  Returns a	       ;AN000;bgb
;pointer to the unverified string in PARSE1_OUTPUT.  Currently used	       ;AN000;bgb
;for the RECOVER command.						       ;AN000;bgb
;***************************************************************************** ;AN000;bgb
;;;;db 'PARSE TABLE AREA'                                                      ;AN000;bgb
 public parms_input_block, parms_ext_block, control_block, value_list_block
 public results_block, parse_type, parse_code, parse_addr,
									       ;AN000;bgb
;***************************************************************************** ;AN000;bgb
; This is the parms input block pointed to by es:di before calling sysparse.   ;AN000;bgb
; it is the top level table.						       ;AN000;bgb
parms_input_block LABEL   BYTE						       ;AN000;bgb
		DW	dg:parms_ext_block	  ; addr of parms extension block ;AN000;bgb
		DB	0			; no delimiters or eol chars   ;AN000;bgb
									       ;AN000;bgb
;***************************************************************************** ;AN000;bgb
; This is the parms extension block pointed to by the parms input block.       ;AN000;bgb
; it defines the number and type of parameters allowed in the command line.    ;AN000;bgb
parms_ext_block LABEL	BYTE						       ;AN000;bgb
		DB	1,1			; only one positional parm     ;AN000;bgb
		DW	dg:control_block       ; addr of positional control block ;AN000;bgb
		DB	0			;	 no switches	       ;AN000;bgb
		DB	0			;	 no keywords	       ;AN000;bgb
;									       ;AN000;bgb
;PARSE control block for an optional file specification (upper cased)	       ;AN000;bgb
;or drive number							       ;AN000;bgb
;									       ;AN000;bgb
;***************************************************************************** ;AN000;bgb
; This is the control block for either drive letter "c:", or filename.ext, or  ;AN000;bgb
; both "c:filename.ext" entered in the command line. it is pointed to by the   ;AN000;bgb
; parms extension block.						       ;AN000;bgb
control_block	LABEL	BYTE						       ;AN000;bgb
		Dw	$p_file_spc+$p_drv_only ; allowable return values	;AN000;bgb
						; 0200 = filespec	       ;AN000;bgb
						; 0100 = drive only	       ;AN000;bgb
		DW	1			; capitalize - file table	;AN000;bgb
		DW	dg:results_block	   ; points to reults block	   ;AN000;bgb
		DW	dg:value_list_block	   ; point to valu list block	   ;AN000;bgb
		DB	0			; no keyword synonyms		;AN000;bgb
;										;AN000;bgb
;Indicates no value list for PARSE.						;AN000;bgb
;*****************************************************************************	;AN000;bgb
; This is the value list block pointed to by the control block.  This table is	;AN000;bgb
; used to define the type of numeric or string parameters expected.  Since no	;AN000;bgb
; parameters with numerics or strings are used, this block is set to zero.	;AN000;bgb
value_list_block DW	 0			 ;AN000;  no values		;AN000;bgb
										;AN000;bgb
;										;AN000;bgb
;Common output blocks for PARSE number, complex, or string values.		;AN000;bgb
;*****************************************************************************	;AN000;bgb
; This is the results block pointed to by the control block.			;AN000;bgb
; both "c:filename.ext" entered in the command line. it is pointed to by the    ;AN000;bgb
; parms extension block.							;AN000;bgb
results_block	LABEL	BYTE			;AN000; 			;AN000;bgb
PARSE_TYPE     DB      0		       ; type of parm returned		;AN000;bgb
PARSE_CODE     DB      0		       ; matched item tag / return valu ;AN000;bgb
PARSE_SYN      DW      0		       ;	es offset of synonym	;AN000;bgb
PARSE_ADDR     DD      0		       ; either a numeric value, or	;AN000;bgb
	       dd      0 ;parser puts in too many;the offset of string value	;AN000;bgb

;;;;DB 'PARSE AREA ENDS'
data	ends									;AN000;bgb
										;AN000;bgb
;										;AN000;
code	segment PUBLIC para 'CODE'   ;AC000;bgb                                 ;AN000;
;*****************************************************************************	;AN000;
; SysParse Routines								;AN000;
;*****************************************************************************	;AN000;
FarSW	equ	Not_Include			;				;AN000;
DateSW	equ	Not_Include			;				;AN000;
TimeSW	equ	Not_Include			;				;AN000;
FileSW	equ	Do_Include			;				;AN000;
CAPSW	equ	Not_Include			;				;AN000;
CmpxSW	equ	Not_Include			;				;AN000;
NumSW	equ	Not_Include			;				;AN000;
KeySW	equ	Not_Include			;				;AN000;
SwSW	equ	Not_Include			;				;AN000;
Val1SW	equ	Not_Include			;				;AN000;
Val2SW	equ	Not_Include			;				;AN000;
Val3SW	equ	Not_Include			;				;AN000;
DrvSW	equ	Do_Include			;				;AN000;
QusSW	equ	Not_Include			;
basesw	equ	1 ;use ds as the default register				;an040;bgb
incsw	equ	0 ;include psdata myself					;an040;bgb
code	ends									;an040;bgb
										;an040;bgb
										;an040;bgb
data	segment PUBLIC para 'DATA'                                              ;an040;bgb
include psdata.inc								;an040;bgb
data	ends									;an040;bgb
										;an040;bgb
code	segment PUBLIC para 'CODE'                                              ;an040;bgb
pathlabl parser 								;an040;bgb
INCLUDE PARSE.ASM				;AN000; 			;an040;bgb
pathlabl parser 								;an040;bgb
code	ends									;an040;bgb
