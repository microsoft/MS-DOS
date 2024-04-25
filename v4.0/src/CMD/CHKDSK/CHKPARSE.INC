										;an000;bgb
										;an000;bgb
										;an000;bgb
										;an000;bgb
data	segment public para 'DATA'                                              ;an000;bgb     ;AN000;
										;an000;bgb
										;an000;bgb
;										;an000;bgb
;*****************************************************************************	;an000;bgb
; Publics									;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
;	Public	Drive_Letter_Buffer						;an000;bgb
	Public	SwBuffer							;an000;bgb
	Public	Switch_F_Buffer 						;an000;bgb
;	Public	FileSpec_Buffer 						;an000;bgb
	public	buffer								;an000;bgb
	public	sw_v, sw_f							;an000;bgb;an020;bgb
										;an000;bgb
;										;an000;bgb
;***************************************************************************	;an000;bgb
; Equates									;an000;bgb
;***************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
;Match Flags									;an000;bgb
										;an000;bgb
Numeric_Value		equ	8000h		;				;an000;bgb;AN000;
Signed_Numeric_Value	equ	4000h		;				;an000;bgb;AN000;
Simple_String		equ	2000h		;				;an000;bgb;AN000;
Date_String		equ	1000h		;				;an000;bgb;AN000;
Time_String		equ	0800h		;				;an000;bgb;AN000;
Complex_List		equ	0400h		;				;an000;bgb;AN000;
Quoted_String		equ	0080h		;				;an000;bgb;AN000;
Ignore_Colon		equ	0010h		;				;an000;bgb;AN000;
Repeats_Allowed 	equ	0002h		;				;an000;bgb;AN000;
Optional		equ	0001h		;				;an000;bgb;AN000;
Filespec		equ	0200h		;				;an000;bgb;AN000;
Drive_Only		equ	0100h		;				;an000;bgb;AN000;
										;an000;bgb
;Function_Flags 								;an000;bgb
										;an000;bgb
File_Table_Capitalize	equ	1		;				;an000;bgb;AN000;
Char_Table_Capitalize	equ	2		;				;an000;bgb;AN000;
Remove_Colon		equ	10h		;				;an000;bgb;AN000;
										;an000;bgb
;Extra delimeters and EOL							;an000;bgb
										;an000;bgb
Delimiters_Only 	equ	1		;				;an000;bgb;AN000;
EOL_Or_Delimiters	equ	2		;				;an000;bgb;AN000;
										;an000;bgb
Semi_Colon		equ	";"             ;                               ;an000;bgb;AN000;
Tab			equ	09h		;				;an000;bgb;AN000;
Colon			equ	":"             ;                               ;an000;bgb;AN000;
										;an000;bgb
										;an000;bgb
;Parse Errors									;an000;bgb
										;an000;bgb
No_Error		equ	0		;				;an000;bgb;AN000;
Too_Many_Operands	equ	1		;				;an000;bgb;AN000;
Operand_Missing 	equ	2		;				;an000;bgb;AN000;
Not_In_Switch_List	equ	3		;				;an000;bgb;AN000;
Not_In_Keyword_List	equ	4		;				;an000;bgb;AN000;
Out_Of_Range		equ	6		;				;an000;bgb;AN000;
Not_In_Value_List	equ	7		;				;an000;bgb;AN000;
Not_In_String_List	equ	8		;				;an000;bgb;AN000;
Syntax_Error		equ	9		;				;an000;bgb;AN000;
End_Of_Parse		equ	-1		;				;an000;bgb;AN000;
										;an000;bgb
;Return types									;an000;bgb
										;an000;bgb
Type_Reserved		equ	0		;				;an000;bgb;AN000;
Type_Number		equ	1		;				;an000;bgb;AN000;
Type_List_Index 	equ	2		;				;an000;bgb;AN000;
Type_String		equ	3		;				;an000;bgb;AN000;
Type_Complex		equ	4		;				;an000;bgb;AN000;
Type_Filespec		equ	5		;				;an000;bgb;AN000;
Type_Drive		equ	6		;				;an000;bgb;AN000;
Type_Date		equ	7		;				;an000;bgb;AN000;
Type_Time		equ	8		;				;an000;bgb;AN000;
Type_Quoted_String	equ	9		;				;an000;bgb;AN000;
										;an000;bgb
;Other										;an000;bgb
										;an000;bgb
None			equ	0		;				;an000;bgb;AN000;
No_Error		equ	0		;				;an000;bgb;AN000;
Switch_Found		equ	0FFFFh		;				;an000;bgb;AN000;
Range_Ok		equ	1		;				;an000;bgb;AN000;
Command_Line_Parms	equ	81h		;				;an000;bgb;AN000;
										;an000;bgb
;										;an000;bgb
;*****************************************************************************	;an000;bgb
; Parse Structures								;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
Control 	 struc								;an000;bgb
										;an000;bgb
Match_Flags	dw	?							;an000;bgb
Function_Flags	dw	?							;an000;bgb
Result		dw	?							;an000;bgb
Values		dw	?							;an000;bgb
Num_Keywords	db	?							;an000;bgb
Keyword 	db	?							;an000;bgb
										;an000;bgb
Control 	ends								;an000;bgb
										;an000;bgb
;Drive_Letter_Return	 struc			 ;				;an000;bgb ;AN000;
;Drive_Type		 db	 0			 ;			;an000;bgb	   ;AN000;
;Drive_Item_Tag 	 db	 0			 ;			;an000;bgb	   ;AN000;
;Drive_Pointer		 dw	 0			 ;			;an000;bgb	   ;AN000;
;Drive_Number		 db	 0			 ;A=1, B=2, C=3 	;an000;bgb	   ;AN000;
;Drive_debug		 db	 8 dup(0)					;an000;bgb
;Drive_Letter_Return	 ends			 ;				;an000;bgb ;AN000;
;										;an000;bgb
;Filespec_Return struc				 ;AN000;SM			;an000;bgb
;Filespec_Type		 db	 0		 ;AN000;SM			;an000;bgb
;FileSpec_Item		 db	 0		 ;AN000;SM			;an000;bgb
;FileSpec_Pointer	 dw	 0		 ;AN000;SM			;an000;bgb
;Filespec_String_Off	 dw	 0		 ;AN000;SM			;an000;bgb
;FileSpec_String_Seg	 dw	 0						;an000;bgb
;FileSpec_Return ends								;an000;bgb
										;an000;bgb
single_Return struc			      ;AN000;SM 			;an000;bgb
dftype		  db	  0		  ;AN000;SM				;an000;bgb
Item		  db	  0		  ;AN000;SM				;an000;bgb
Pointer 	  dw	  0		  ;AN000;SM				;an000;bgb
drnum_stroff	  dw	  0		  ;AN000;SM				;an000;bgb
return_strseg		 dw	 0						;an000;bgb
single_return	ends								;an000;bgb
										;an000;bgb
										;an000;bgb
Switch_Return	 struc				;				;an000;bgb;AN000;
Switch_Type	db	0			;				;an000;bgb;AN000;
Switch_Item_Tag db	0			;				;an000;bgb;AN000;
Switch_Pointer	dw	0			;				;an000;bgb;AN000;
Switch_Debug	db	4 dup(0)						;an000;bgb
Switch_Return	 ends				;				;an000;bgb;AN000;
										;an000;bgb
Switch_Num_Return    struc			;				;an000;bgb;AN000;
Switch_Num_Type     db	    0			    ;				;an000;bgb    ;AN000;
Switch_Num_Item_Tag db	    0			    ;				;an000;bgb    ;AN000;
Switch_Num_Pointer  dw	    0			    ;				;an000;bgb    ;AN000;
Switch_Number_Low   dw	    0		    ;				    ;AN0;an000;bgb00;
Switch_Number_High  dw	    0		    ;				    ;AN0;an000;bgb00;
Switch_Num_Return    ends			;				;an000;bgb;AN000;
										;an000;bgb
Switch_String_Return   struc			;				;an000;bgb;AN000;
Switch_String_Type     db      0		       ;			;an000;bgb	 ;AN000;
Switch_String_Item_Tag db      0		       ;			;an000;bgb	 ;AN000;
Switch_String_Pointer  dw      0		       ;			;an000;bgb	 ;AN000;
Switch_String_Off	dw	0		;				;an000;bgb;AN000;
Switch_String_Seg	dw	0		;				;an000;bgb;AN000;
Switch_String_Return ends			;				;an000;bgb;AN000;
										;an000;bgb
										;an000;bgb
;										;an000;bgb
;**************************************************************************	;an000;bgb
; Parse tables									;an000;bgb
;**************************************************************************	;an000;bgb
;										;an000;bgb
Public	input_Table								;an000;bgb
input_Table	 label	 byte		 ;				 ;AN000;;an000;bgb
										;an000;bgb
	dw	offset dg:ext_table		;Point to next level	      ;A;an000;bgbN000;
	db	Delimiters_Only 		;				;an000;bgb;AN000;
	db	1				;				;an000;bgb;AN000;
	db	Semi_Colon			;				;an000;bgb;AN000;
										;an000;bgb
Drive_Table		label	byte						;an000;bgb;AN000;
						;				;an000;bgb
	dw	offset dg:Drive_Control_Definition ;Point to next level 	;an000;bgb   ;AN000;
	db	Delimiters_Only 		;				;an000;bgb;AN000;
	db	1				;				;an000;bgb;AN000;
	db	Semi_Colon			;				;an000;bgb;AN000;
										;an000;bgb
;										;an000;bgb
;**************************************************************************	;an000;bgb
;Define Positionals, Switches and Keywords					;an000;bgb
;**************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
Public	ext_table								;an000;bgb
ext_table		   label   byte 	;				;an000;bgb;AN000;
						;				;an000;bgb
	db	0,1			;up to one parm, either drive or file	;an000;bgb;an026;bgb
	dw	dg:dfcontrol			     ;Pointer to control table	;an000;bgb     ;AN000;
	db	1				;1 switch  def			;an000;bgb;AN020;bgb
	dw	dg:SwControl		;switch control block			;an000;bgb;AN020;bgb
	db	None				;No Keywords (maxk)		;an000;bgb;AN000;
						;				;an000;bgb
Drive_Control_Definition  label   byte		;				;an000;bgb;AN000;
						;				;an000;bgb
	db	0,1				;Only drive letter positional	;an000;bgb;AN000;
	dw	dg:dfControl		    ;Pointer to control table	    ;AN0;an000;bgb00;
	db	None				;0 switches			;an000;bgb;AN000;
	db	None				;No Keywords (maxk)		;an000;bgb;AN000;
						;				;an000;bgb
										;an000;bgb
										;an000;bgb
;										;an000;bgb
;**************************************************************************	;an000;bgb
; Define Positionals, Switches and Keywords					;an000;bgb
;**************************************************************************	;an000;bgb
;										;an000;bgb
;this is the new control block for both drive letters and filespecs		;an000;bgb
Public	dfControl								;an000;bgb
dfControl	 label	 byte		 ;				 ;AN000;;an000;bgb
	dw	drive_only+FileSpec+Optional		   ;			;an000;bgb	     ;AN000;
	dw	None				;				;an000;bgb;AN000;
	dw	dg:Buffer	       ;			       ;AN000;	;an000;bgb
	dw	dg:No_Value			;				;an000;bgb;AN000;
	db	None				;				;an000;bgb;AN000;
										;an000;bgb
Public	SwControl							   ;an02;an000;bgb0;bgb
SwControl	 label	 byte		 ;				 ;AN020;;an000;bgbbgb
	dw	None				;				;an000;bgb;AN000;
	dw	None				;				;an000;bgb;AN000;
	dw	dg:SwBuffer		 ;				 ;AN000;;an000;bgb
	dw	dg:No_Value							;an000;bgb   ;AN000;
	db	2				;				;an000;bgb;AN020;bgb
sw_v	db	"/V",0                          ;                               ;an000;bgb;AN020;bgb
sw_f	db	"/F",0                          ;                               ;an000;bgb;AN020;bgb
						;				;an000;bgb
										;an000;bgb
;										;an000;bgb
;*****************************************************************************	;an000;bgb
; Value lists									;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
No_Value	db	0			 ;				;an000;bgb;AN000;
										;an000;bgb
										;an000;bgb
;										;an000;bgb
;************************************************************************	;an000;bgb
; PARSE Return Buffers								;an000;bgb
;************************************************************************	;an000;bgb
;										;an000;bgb
; these buffers were replaced by a single buffer due to the parser bug		;an000;bgb
;Drive_Letter_Buffer	 Drive_Letter_Return	 <>  ;Example of structure	;an000;bgb ;AN000;
;FileSpec_Buffer	 FileSpec_Return	 <>  ;				;an000;bgb
SwBuffer		Switch_Return		<>  ;				;an000;bgb;AN000;
Switch_F_Buffer 	Switch_Return		<>  ;				;an000;bgb;AN000;
buffer			single_return		<>  ; new results buffer	;an000;bgb
data	ends					;				;an000;bgb;AN000;
										;an000;bgb
;										;an000;bgb
;*****************************************************************************	;an000;bgb
; SysParse Routines								;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
										;an000;bgb
code	segment public	para 'CODE'                                             ;an000;bgb
										;an000;bgb
FarSW	equ	Not_Include			;				;an000;bgb;AN000; ;AN000;
DateSW	equ	Not_Include			;				;an000;bgb;AN000;
TimeSW	equ	Not_Include			;				;an000;bgb;AN000;
FileSW	equ	Do_Include			;				;an000;bgb;AN000;
CAPSW	equ	Not_Include			;				;an000;bgb;AN000;
CmpxSW	equ	Not_Include			;				;an000;bgb;AN000;
NumSW	equ	Not_Include			;				;an000;bgb;AN000;
KeySW	equ	Not_Include			;				;an000;bgb;AN000;
SwSW	equ	Do_Include			;				;an000;bgb;AN000;
Val1SW	equ	Not_Include			;				;an000;bgb;AN000;
Val2SW	equ	Not_Include			;				;an000;bgb;AN000;
Val3SW	equ	Not_Include			;				;an000;bgb;AN000;
DrvSW	equ	Do_Include			;				;an000;bgb;AN000;
QusSW	equ	Not_Include			;				;an000;bgb;AN000;
basesw	equ	1 ;use ds as the default register				;an025;bgb
incsw	equ	0 ;include psdata myself					;an028;bgb
code	ends									;an028;bgb


data	segment PUBLIC para 'DATA'                                              ;an028;bgb
include psdata.inc								;an028;bgb
data	ends									;an028;bgb

code	segment PUBLIC para 'CODE'                                              ;an028;bgb
pathlabl parser 								;an028;bgb
INCLUDE PARSE.ASM				;AN000; 			;an028;bgb
pathlabl parser 								;an028;bgb
code	ends									;an000;bgb
