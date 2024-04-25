
	PAGE	,132			;
	TITLE	MODE COMMAND - COMMAND PARSING
.XLIST							;AN000;
   INCLUDE STRUC.INC					;AN000;
.LIST							;AN000;
;.SALL							;AN000;


;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  P R O L O G  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º											  º

;  AC001 - P3259: When "/STATUS" was only parameter was returning "Invalid
;		  number of parameters".  When "/STATUS" was first parameter
;		  the device name was not being recognized.

;  AC002 - P3258, PS/2 only COM parameters were being allowed on non-PS/2
;	   P3540: machines.  Added checks for baud=19200, parity=mark or space,
;		  data=5 or 6, stop=1.5 for both keyword and positional forms.

;  AC003 - P3451: Wasn't treating semicolons as a valid blank-like delimeter.


;  AC004 - P3456: /STAT wasn't included in all checks for valid forms of /STATUS.
;		  "BW" and "CO" were being accepted as valid parms.

;  AC005 - P3796: PRN /STA returned "Invalid parameter -" when worked OK for
;		  LPT1.

;  AC006 - P3932: Was issuing "Invalid parameter - ???" for switches that are
;		  not valid, now issue "Invalid switch - ???".

;  AC007 - P3931: "CON SEL=850" acts like a status request, should return
;		  "Invalid number of parameters" because user forgot "CP".

;  AX008 - P5183: Was denying 19200 baud on PS/2 model 30s and 25s and VAILs.

;º											  º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  P R O L O G  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼



;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  M A C R O S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º											  º


BREAK	MACRO	X					;AN000;
   JMP	   endcase_&X					;AN000;
ENDM							;AN000;

;-------------------------------------------------------------------------------

DISPLAY MACRO	MESSAGE 				;AN000;
	MOV	DX,MESSAGE				;AN000;
	CALL	PRINTF					;AN000;
ENDM

;-------------------------------------------------------------------------------

check_for_lpt_keyword	MACRO		 ;AN000;

MOV   DL,number_of_lpt_keywords     ;;AN000;Initialize
MOV   number_of_keywords,DL	    ;;AN000;		for call to check_for_keyword
MOV   BP,OFFSET start_lpt_keyword_ptrs	;;AN000;start_of_keyword_ptrs=[BP]
CALL  check_for_keyword 		 ;AN000;

ENDM					 ;AN000;

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³
;³ DELETE_PARSER_VALUE_LIST_ENTRY
;³ -------------------------------
;³
;³ As the logic in PARSE_PARAMETERS proceeds the posibilities for the next parm
;³ become apparent and the parser control blocks need to be changed to correctly
;³ parse the next parm.  This MACRO is the interface to the approptiate routine which
;³ modifies the list of strings or keywords in the VALUES block.
;³
;³
;³
;³
;³
;³  INPUT: item_type - scalar indicating that a string or keyword is to be deleted
;³
;³	   item   - A scalar immediate that indicates the string or keyword to
;³		     be "deleted"
;³
;³
;³  RETURN: none
;³
;³
;³  MESSAGES: none
;³
;³
;³
;³
;³  REGISTER
;³  USAGE:     "item" is put into BX.
;³
;³
;³
;³  CONVENTIONS:
;³
;³
;³
;³  ASSUMPTIONS: All the input are valid.
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³  SIDE EFFECT:
;³
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

delete_parser_value_list_entry	 MACRO item_type,item		;AN000;

;MOV   BX,item				;AN000;
CALL  item_type 		       ;AN000;

ENDM								;AN000;


;-------------------------------------------------------------------------------

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³
;³ MODIFY_PARSER_CONTROL_BLOCK
;³ ---------------------------
;³
;³ As the logic in PARSE_PARAMETERS proceeds the posibilities for the next parm
;³ become apparent and the parser control blocks need to be changed to correctly
;³ parse the next parm.  This MACRO is the interface to the routines that modify
;³ those control blocks.
;³
;³
;³
;³
;³
;³  INPUT: control_structure - A scalar immediate indicating the control block
;³			       to be modified, and the routine to call.
;³
;³	   action - A scalar immediate that indicates the nature
;³		      of the modification to be made.
;³
;³	   item   - A scalar immediate that indicates the string, number,
;³		      keywords, switch, or match flags mask involved.
;³
;³  RETURN: none
;³
;³
;³  MESSAGES: none
;³
;³
;³
;³
;³  REGISTER
;³  USAGE:	 The scalar value for the modifier will be put in a register
;³		 for passing to the routine that actually does the work.
;³
;³
;³  CONVENTIONS:
;³
;³
;³
;³  ASSUMPTIONS: All the input are valid.
;³
;³
;³  SIDE EFFECT:
;³
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

modify_parser_control_block  MACRO    control_structure,action,item	;AN000;

PUSH  BX								;AN000;

MOV   BX,action 			  ;AN000;
MOV   AL,item				  ;AN000;
CALL  control_structure 		  ;AN000;

POP   BX								;AN000;

ENDM									;AN000;

;-------------------------------------------------------------------------------


;º											  º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  M A C R O S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼



;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  E Q U A T E S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º											  º


INCLUDE modequat.inc


addd		     EQU   0  ;;AN000;used for "seperator_list"
binary_to_ASCII      EQU   30H	    ;AN000;used to convert bytes from binary to ASCII
blank		     EQU   " ";;AN000;used for "seperator_list"
both		     EQU   2	    ;AN000;value of rate_and_delay_found when both have been found
comma		     EQU   ","      ;AN000;used to tell the difference between a blank delimeter and missing parm, see LPTX,:
current_parm	     EQU   0  ;;AN000;scalar for parser control block modifing routine "keywords"
current_parm_DI     EQU     DI	    ;;AN000;index for parm_list array
delete		     EQU   1  ;AN000;;used for "seperator_list"
deleted        EQU	0     ;AN000;;used to make keywords unmatchable and strings of length zero
end_of_line_char_0D  EQU   0DH	    ;AN000;put at end of the command line by the loader
end_of_line_char_00  EQU   00H	    ;AN000;put at end of the complex parm by the parser
i_CL		     EQU   CL	    ;;AN000;loop index
include_string_list  EQU   3	    ;;AN000;number of value definitions so strings are included
include_number_list  EQU   2	    ;;AN000;See "nrng" in description of "values" block input for generalized parser
keyword 	     EQU   58H	    ;;AN000;indicator parms are in keyword form vs positional, value for parms_form
first_com_keyword    EQU   SI	    ;;AN000;holder for "first_com_keyword_ptr"
last_com_keyword     EQU   SI	    ;;AN000;holder for "last_com_keyword_ptr"
first_LPT_keyword    EQU   SI	    ;;AN000;holder for "first_LPT_keyword_ptr"
last_LPT_keyword     EQU   SI	    ;;AN000;holder for "last_LPT_keyword_ptr"
first_CON_keyword    EQU   SI	    ;;AN000;holder for "first_con_keyword_ptr"
last_CON_keyword     EQU   SI	    ;;AN000;holder for "last_con_keyword_ptr"
max_parms	     EQU   16	    ;;AN000;con cp prep=((1,2,3,4,5,6,7,8,9,10,11,12) filespec.cpi)
min_codepage_value   EQU   0	     ;AN000;
max_codepage_value   EQU   999	    ;;AN000;three digits
max_number_of_codepages EQU   12     ;AN000;assure that user does not specify too many code page numbers
min_number_of_codepages EQU   1      ;AN000;
min_old_com_pos_parms  EQU	0    ;AN000;could have nothing else meaning status request
max_old_com_pos_parms  EQU	5    ;AN000; ;baud, parity, data bits, stop bits, P
max_switches	     EQU   1  ;AN000;;only switch is /status
no_message	     EQU   0  ;AN000;indicate to message handler interface that no message to issue
none_found	     EQU   0  ;AN000;;if keyword_switch_ptr is returned as zero then parser did not encounter a keyword or switch
not_in_switch_list   EQU   3	    ;AC006;
number_of_printer_status_qualifiers    EQU   4	;;AN000;codepage, prepare, select, RETRY
parm_list	     EQU   [BX] 		 ;AN000;
parms_BX	     EQU   [BX] 		 ;AN000;
parser_return_code_AX	EQU   AX		 ;AN000;
PS2		     EQU   44H			;AC002;flag for "type_of_machine"
result_BP	     EQU   [BP] 		 ;AN000;
range_item_tag	     EQU   55H	    ;AN000;;marker for checks in memory, otherwise just a holder
ranges_only	     EQU   1  ;;AN000;See "nrng" in description of "values" block input for generalized parser
start_of_keyword_ptrs	EQU   [BP]	  ;AN000;;used for indexing the list of offsets in check_for_keyword
tab			EQU   09	  ;AC006;
unspecified		EQU   0FFH	  ;AN000;item tag of parm not specified: skipped optional positional parm


;possible values for "parm_type", the type of parm returned by parser

complx		     EQU   4		  ;AN000;
number		     EQU   1		  ;AN000;
string		     EQU   3		  ;AN000;

;possible values for "return_code_AX"

no_error	     EQU   0		  ;AN000;;not the same as "noerror"
operand_missing      EQU   2		  ;AN000;
syntax_error_rc      EQU   9		  ;AN000;
end_of_command_line  EQU   -1		  ;AN000;
end_of_complex	     EQU   -1		  ;AN000;found 0 that parser wrote over closing ")" of complex



;possible values of "device_type"

COMX				 EQU   09CH	;AN000;
;CON				  EQU	0	;AN000;
LPTX				 EQU   09BH	;AN000;
;LPT1				  EQU	0	;AN000;


;possible values of "request_type"

max_request_type		 EQU   09AH	;AN000;;must be same as following value
all_con_status			 EQU   09AH	;AN000;
codepage_prepare		 EQU   099H	;AN000;
codepage_refresh		 EQU   098H	;AN000;
codepage_select 		 EQU   097H	;AN000;
codepage_status 		 EQU   096H	;AN000;
codepage_prepared_status	 EQU   095H	;AN000;
codepage_selected_status	 EQU   094H	;AN000;
com_status			 EQU   093H	;AN000;
initialize_com_port		 EQU   092H	;AN000;
initialize_printer_port 	 EQU   091H	;AN000;
old_initialize_printer_port	 EQU   090H	;AN000;;found traditional syntax
old_video_mode_set		 EQU   08FH	;AN000;;found traditional syntax
printer_reroute 		 EQU   08EH	;AN000;
printer_status			 EQU   08DH	;AN000;
set_con_features		 EQU   08CH	;AN000;
status_for_everything		 EQU   08BH	;AN000;
turn_off_reroute		 EQU   08AH	;AN000;
last_request_type		 EQU   08AH	;AN000;;must be same as previous value


;possible codepage requests, used by modecp

select	       EQU   086H			;AN000;
prepare        EQU   085H			;AN000;
refresh        EQU   084H			;AN000;
;status 		;AN000;;see request_type possibilities



;possible values of "looking_for"


codepage					  EQU	  6FH		;AN000;
codepage_prms					  EQU	  6EH		;AN000;
com_keyword					  EQU	  6DH		;AN000;
com_keyword_or_baud				  EQU	  6CH		;AN000;
CON_keyword					  EQU	  6BH		;AN000;
con_kwrd_status_or_cp				  EQU	  6AH		;AN000;
databits_or_null				  EQU	  69H		;AN000;
device_name_or_eol				  EQU	  68H		;AN000;
eol						  EQU	  67H	;;AN000;end of line
first_parm					  EQU	  66H	 ;AN000;
li_or_null					  EQU	  65H	 ;AN000;
P						  EQU	  64H	 ;AN000;
parity_or_null					  EQU	  63H	 ;AN000;
prn_kw_status_cp_cl_null			  EQU	  62H	 ;AN000;
sd_or_dl					  EQU	  61H	 ;AN000;
sd_or_dl_or_eol 				  EQU	  60H	 ;AN000;
status_or_eol					  EQU	  5FH	 ;AN000;
stopbits_or_null				  EQU	  5EH	 ;AN000;
T_or_EOL					  EQU	  5DH	 ;AN000;

max_looking_for     EQU     6FH     ;AN000;;used for calculating the displacement into jump table for "CASE looking_for="




;item tags for COM port names strings

COM1_item_tag	     EQU   1	       ;;AN000;these values must be 1 through 4 because
COM2_item_tag	     EQU   2	       ;;AN000;parsing for COM special cases depends
COM3_item_tag	     EQU   3	       ;;AN000;on it.
COM4_item_tag	     EQU   4

;item tags for paritys

first_parity_item_tag	EQU   86H	;AN000;
mark_item_tag		EQU   86H	;AN000;
space_item_tag		EQU   85H	;AN000;
none_item_tag		EQU   84H	;AN000;
odd_item_tag		EQU   83H	;AN000;
even_item_tag		EQU   82H	;AN000;
last_parity_item_tag	EQU   82H	;AN000;


;item tags for printer port names

PRN_item_tag	     EQU   5		;AN000;
LPT1_item_tag	     EQU   6		;AN000;
LPT2_item_tag	     EQU   7		;AN000;
LPT3_item_tag	     EQU   8		;AN000;

;item tags for screen modes

first_screen_mode_item_tag    EQU   9	;AN000;
BW40_item_tag	     EQU   0BH		;AN000;
BW80_item_tag	     EQU   0CH		;AN000;
CO40_item_tag	     EQU   0DH		;AN000;
CO80_item_tag	     EQU   0EH		;AN000;
eighty_item_tag      EQU   0FH		;AN000;
fourty_item_tag      EQU   10H		;AN000;
MONO_item_tag	     EQU   11H		;AN000;
last_screen_mode_item_tag     EQU   11H ;AN000;

con_item_tag	     EQU   12H		;AN000;


;item tags for LPT special cases

first_lpt_special_case_item_tag  EQU   13H   ;;AN000;following value must be the same as this one
LPT1132_item_tag     EQU   13H		      ;AN000;
LPT2132_item_tag     EQU   14H		      ;AN000;
LPT3132_item_tag     EQU   15H		      ;AN000;
LPT180_item_tag      EQU   16H		      ;AN000;
LPT280_item_tag      EQU   17H		      ;AN000;
LPT380_item_tag      EQU   18H		      ;AN000;
last_lpt_special_case_item_tag	 EQU   18H   ;;AN000;this value must be the same as the previous

P_item_tag	     EQU   19H		      ;AN000;
RETRY_item_tag	     EQU   1AH		      ;AN000;
B_item_tag	     EQU   1BH		      ;AN000;
E_item_tag	     EQU   1CH		      ;AN000;
R_item_tag	     EQU   1DH		      ;AN000;

codepage_item_tag    EQU   1EH		  ;;AN000;for the range defining codepage possibilities
PREPARE_item_tag     EQU   1FH		   ;AN000;
SELECT_item_tag      EQU   20H		   ;AN000;
REFRESH_item_tag     EQU   21H		   ;AN000;

COLUMNS_item_tag     EQU   23H		   ;AN000;
DELAY_item_tag	     EQU   24H		   ;AN000;
LINES_item_tag	     EQU   25H		   ;AN000;
RATE_item_tag	     EQU   26H		   ;AN000;

COM_item_tag	     EQU   27H		   ;AN000;

ON_item_tag	     EQU   28H		   ;AN000;
OFF_item_tag	     EQU   29H		   ;AN000;

L_item_tag	     EQU   2AH		   ;AN000;
T_item_tag	     EQU   2BH		   ;AN000;

;item tags for numbers not in other lists

zero_item_tag		       EQU  2CH    ;AN000;
first_stopbit_item_tag	       EQU  2DH    ;AN000;
one_item_tag		       EQU  2EH    ;AN000;
one_point_five_item_tag        EQU  2FH    ;AN000;
two_item_tag		       EQU  30H    ;AN000;
last_stopbit_item_tag	       EQU  31H    ;AN000;
three_item_tag		       EQU  32H    ;AN000;
four_item_tag		       EQU  33H    ;AN000;
first_databit_item_tag	       EQU  34H    ;AN000;
five_item_tag		       EQU  35H    ;AN000; ;data bit, typamatic rate
six_item_tag		       EQU  36H    ;AN000;
seven_item_tag		       EQU  37H    ;AN000;
eight_item_tag		       EQU  38H    ;AN000;
last_databit_item_tag	       EQU  39H    ;AN000;
nine_item_tag		       EQU  3AH    ;AN000;
ten_item_tag		       EQU  3BH    ;AN000;
eleven_item_tag 	       EQU  3CH    ;AN000;;first two chars of 110
twelve_item_tag 	       EQU  3DH    ;AN000;
thirteen_item_tag	       EQU  3EH    ;AN000;
fourteen_item_tag	       EQU  3FH    ;AN000;
fifteen_item_tag	       EQU  40H    ;AN000;;abbreviated form of 150, 15 is also a RATE= candidate
sixteen_item_tag	       EQU  41H    ;AN000;
seventeen_item_tag	       EQU  42H    ;AN000;
eighteen_item_tag	       EQU  43H    ;AN000;
nineteen_item_tag	       EQU  44H    ;AN000;;used for baud rates and RATE=
twenty_item_tag 	       EQU  45H    ;AN000;
twentyone_item_tag	       EQU  46H    ;AN000;
twentytwo_item_tag	       EQU  47H    ;AN000;
twentythree_item_tag	       EQU  48H    ;AN000;
twentyfour_item_tag	       EQU  49H    ;AN000;    ;24 is also a typamatic rate
twentyfive_item_tag	       EQU  4AH    ;AN000;
twentysix_item_tag	       EQU  4BH    ;AN000;
twentyseven_item_tag	       EQU  4CH    ;AN000;
twentyeight_item_tag	       EQU  4DH    ;AN000;
twentynine_item_tag	       EQU  4EH    ;AN000;
thirty_item_tag 	       EQU  4FH    ;AN000;
thirtyone_item_tag	       EQU  50H    ;AN000;
thirtytwo_item_tag	       EQU  51H    ;AN000;
fourtythree_item_tag	       EQU  52H    ;AN000;
fifty_item_tag		       EQU  53H    ;AN000;
sixty_item_tag		       EQU  54H    ;AN000;
oneten_item_tag 	       EQU  55H    ;AN000;
onethirtytwo_item_tag	       EQU  56H    ;AN000;
onefifty_item_tag	       EQU  57H    ;AN000;
threehundred_item_tag	       EQU  58H    ;AN000;
sixhundred_item_tag	       EQU  59H    ;AN000;
twelvehundred_item_tag	       EQU  5AH    ;AN000;
twentyfourhundred_item_tag     EQU  5BH    ;AN000;
fourtyeighthundred_item_tag    EQU  5CH    ;AN000;
ninetysixhundred_item_tag      EQU  5DH    ;AN000;
nineteentwohundred_item_tag    EQU  5EH    ;AN000;


;mask values for function_flags

capitalize     EQU   0001H     ;AN000;capitalize by file table


;mask values for match flags

numeric        EQU   8000H		   ;AN000;
simple_string  EQU   2000H		   ;AN000;
complex        EQU   0400H		   ;AN000;
filespec       EQU   0200H		   ;AN000;
ignore_colon   EQU   0010H		   ;AN000;
optional       EQU   0001H		   ;AN000;
clear_all      EQU   0000H		   ;AN000;

;delete_simple_string	 EQU   0CFFFH	;AN000;;NOT (simple_string), to turn off simple_string bit in the match_flags




;º											  º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  E Q U A T E S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼



;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  S T R U C T U R E S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º											  º


des_strt_packet   STRUC
   des_strt_pkfl  DW	0000	       ;assume a filename specified
   des_strt_pklen DW	02	       ;start with size of 'des_strt_pknum'
   des_strt_pknum DW	0	       ;number of cp numbers in the packet
   des_strt_pkcp1 DW	-1	       ;code page number for 1st slot
   des_strt_pkcp2 DW	-1
   des_strt_pkcp3 DW	-1
   des_strt_pkcp4 DW	-1
   des_strt_pkcp5 DW	-1
   des_strt_pkcp6 DW	-1
   des_strt_pkcp7 DW	-1
   des_strt_pkcp8 DW	-1
   des_strt_pkcp9 DW	-1
   des_strt_pkcpA DW	-1
   des_strt_pkcpB DW	-1
   des_strt_pkcpC DW	-1	       ;code page number for 12th slot
des_strt_packet   ENDS


INCLUDE  COMMON.STC	;contains the following strucs, needed in invoke also


;parm_list_entry   STRUC
;
;parm_type	      DB       bogus
;item_tag	      DB       0FFH
;value1 	      DW       bogus
;value2 	      DW       bogus
;keyword_switch_ptr   DW    0
;
;parm_list_entry   ENDS


;codepage_parms STRUC
;   cp_device	   DW	 ?
;   des_pack_ptr   DW	 ?
;   font_filespec  DW	 ?
;   request_typ    DW	 ?
;codepage_parms ENDS


parms_def      STRUC			  ;AN000;

parmsx_ptr	  DW	  bogus 	  ;AN000;changed as the possibilities for parms following are determined
		  DB	  1		  ;AN000;have extra delimiter list
seperators_len	  DB	  1		  ;AN000;length of extra delimiter list
seperators	  DB	  ";"             ;AC003;EXTRA DELIMITER LIST
		  DB	  8 DUP (" ")     ;AC003; extra blanks for adding more delimeters (. " \ [ ] : + =)

parms_def      ENDS			  ;AN000;



result_def     STRUC			  ;AN000;

ret_type  DB	   0			  ;AN000;
ret_tag   DB	   0FFH 		  ;AN000;
synonym   DW	   0			  ;AN000;
ret_value1 DW	    bogus		  ;AN000;
ret_value2 DW	    bogus		  ;AN000;

result_def     ENDS			  ;AN000;







;º											  º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  S T R U C T U R E S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼



	PAGE							;AN000;
PRINTF_CODE SEGMENT PUBLIC					;AN000;
	ASSUME	CS:PRINTF_CODE,DS:PRINTF_CODE,SS:PRINTF_CODE	;AN000;


;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  P U B L I C S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º											  º

PUBLIC	 all_con_status 					;AN000;
PUBLIC	 baud_equal						;AN000;
PUBLIC	 B_item_tag	   ;needed by modecom			;AN000;
PUBLIC	 B_str							;AN000;
PUBLIC	 BW40_item_tag						;AN000;
PUBLIC	 BW80_item_tag						;AN000;
PUBLIC	 codepage_index_holder	    ;make available to invoke	;AN000;
PUBLIC	 codepage_item_tag					;AN000;
PUBLIC	 codepage_prepare					;AN000;
PUBLIC	 codepage_prepared_status				;AN000;
PUBLIC	 codepage_refresh					;AN000;
PUBLIC	 codepage_selected_status				;AN000;
PUBLIC	 COM_status						;AN000;
PUBLIC	 COMX			    ;make available to rescode	;AN000;
PUBLIC	 CON_str	      ;AN000;make available to invoke for messages
PUBLIC	 CO40_item_tag	      ;AN000;
PUBLIC	 CO80_item_tag	      ;AN000;
PUBLIC	 codepage_item_tag    ;AN000;
PUBLIC	 codepage_select      ;AN000;
PUBLIC	 codepage_status      ;AN000;
PUBLIC	 columns_equal	      ;AN000;
PUBLIC	 COLS_equal	      ;AN000;
PUBLIC	 columns_item_tag     ;AN000;
PUBLIC	 COM1_str	      ;AN000;
PUBLIC	 COM2_str	      ;AN000;
PUBLIC	 COM3_str	      ;AN000;
PUBLIC	 COM4_str	      ;AN000;
PUBLIC	 data_equal	      ;AN000;used by invoke
PUBLIC	 delay_equal	      ;AN000;
PUBLIC	 del_equal	      ;AN000;
PUBLIC	 des_start_packet     ;AN000;
PUBLIC	 device_name	      ;AN000;
PUBLIC	 device_type	      ;AN000;make available to rescode
PUBLIC	 E_item_tag		    ;needed by modecom		;AN000;
PUBLIC	 E_str		      ;AN000;
PUBLIC	 eight_item_tag       ;AN000;used by setcom
PUBLIC	 eighty_item_tag      ;AN000;
PUBLIC	 eighty_str	      ;AN000;
PUBLIC	 even_item_tag	      ;AN000;used by setcom
PUBLIC	 five_item_tag	      ;AN000;used in setcom
PUBLIC	 fourtyeighthundred_item_tag	  ;used by setcom;AN000;
PUBLIC	 fourtyeighthundred_str 	  ;used by setcom;AN000;
PUBLIC	 fourty_item_tag				 ;AN000;
PUBLIC	 fourty_str					 ;AN000;
PUBLIC	 initialize_com_port				 ;AN000;
PUBLIC	 initialize_printer_port			 ;AN000;
PUBLIC	 keyword	      ;AN000;make available to invoke.asm
PUBLIC	 len_COMX_str	      ;AN000;make available to invoke.asm
PUBLIC	 len_CON_str	      ;AN000;make available to invoke.asm for message service
PUBLIC	 len_LPTX_str	      ;AN000;make available to invoke.asm
PUBLIC	 lines_equal	      ;AN000;
PUBLIC	 lines_item_tag       ;AN000;
PUBLIC	 L_item_tag	      ;AN000;
PUBLIC	 LPTX		      ;AN000;make available to rescode
PUBLIC	 LPT1_str	      ;AN000;
PUBLIC	 LPT2_str	      ;AN000;
PUBLIC	 LPT3_str	      ;AN000;
PUBLIC	 mark_item_tag	      ;AN000;used in setcom
PUBLIC	 max_request_type     ;AN000;
PUBLIC	 mono_item_tag	      ;AN000;
PUBLIC	 new_com_initialize		  ;AC002;make available for modecom
PUBLIC	 nineteentwohundred_item_tag	   ;AN000;used by modecom
PUBLIC	 nineteentwohundred_str 	   ;AN000;used by modecom
PUBLIC	 ninetysixhundred_item_tag	   ;AN000;
PUBLIC	 ninetysixhundred_str ;AN000;
PUBLIC	 none_item_tag	      ;AN000;used in invoke
PUBLIC	 NONE_str	      ;AN000;
PUBLIC	 OFF_item_tag	      ;AN000;
PUBLIC	 OFF_str	      ;AN000;
PUBLIC	 odd_item_tag	      ;AN000;  ;used by setcom
PUBLIC	 old_initialize_printer_port   ;AN000;
PUBLIC	 old_video_mode_set	       ;AN000;
PUBLIC	 one_item_tag		    ;used in setcom	;AN000;
PUBLIC	 one_point_five_item_tag    ;used in setcom	;AN000;
PUBLIC	 one_point_five_str	    ;used in setcom	;AN000;
PUBLIC	 onefifty_item_tag	    ;used in setcom	;AN000;
PUBLIC	 onefifty_str		    ;used in setcom	;AN000;
PUBLIC	 oneten_item_tag	    ;used in modecom	;AN000;
PUBLIC	 oneten_str		    ;used in modecom	;AN000;
PUBLIC	 onethirtytwo_item_tag				;AN000;
PUBLIC	 ON_item_tag					;AN000;
PUBLIC	 ON_str 					;AN000;
PUBLIC	 P_item_tag		    ;make available to modecom	;AN000;
PUBLIC	 parity_equal		    ;used in analyze_and_invoke ;AN000;
PUBLIC	 parm_lst		    ;used in modecom.asm	;AN000;
PUBLIC	 parms_form		    ;make available to invoke	;AN000;
PUBLIC	 parse_parameters					;AN000;
PUBLIC	 prepare						;AN000;
PUBLIC	 prepare_item_tag					;AN000;
PUBLIC	 printer_reroute					;AN000;
PUBLIC	 printer_status 					;AN000;
PUBLIC	 R_item_tag						;AN000;
PUBLIC	 R_str							;AN000;
PUBLIC	 rate_equal						;AN000;
PUBLIC	 refresh						;AN000;
PUBLIC	 request_type						;AN000;
PUBLIC	 reroute_requested	      ;make available to rescode;AN000;
PUBLIC	 retry_equal_str	       ;make available to invoke;AN000;
PUBLIC	 retry_item_tag 					;AN000;
PUBLIC	 retry_requested	    ;make available to rescode	;AN000;
PUBLIC	 select 						;AN000;
PUBLIC	 select_item_tag					;AN000;
PUBLIC	 set_con_features					;AN000;
PUBLIC	 seven_item_tag 	    ;used by setcom		;AN000;
PUBLIC	 sixhundred_item_tag	    ;used by setcom		;AN000;
PUBLIC	 sixhundred_str 	    ;used by setcom		;AN000;
PUBLIC	 six_item_tag		    ;used by setcom		;AN000;
PUBLIC	 space_item_tag 	    ;used by setcom		;AN000;
PUBLIC	 status_for_everything					;AN000;
PUBLIC	 stop_equal						;AN000;
PUBLIC	 T_item_tag						;AN000;
PUBLIC	 threehundred_item_tag	    ;used by setcom		;AN000;
PUBLIC	 threehundred_str	    ;used by setcom		;AN000;
PUBLIC	 turn_off_reroute					;AN000;
PUBLIC	 twelvehundred_item_tag      ;used by setcom		;AN000;
PUBLIC	 twelvehundred_str	     ;used by setcom		;AN000;
PUBLIC	 twentyfourhundred_item_tag	 ;used by setcom	;AN000;
PUBLIC	 twentyfourhundred_str		 ;used by setcom	;AN000;
PUBLIC	 two_item_tag		    ;used by setcom		;AN000;

;º											  º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  P U B L I C S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼


;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  E X T R N S	ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º											  º

;EXTRN	 command_line:BYTE		 ;AN000;PARM AREA
;EXTRN	 command_line_length:BYTE	 ;AN000;NUMBER OF BYTES OF PARM AREA
EXTRN	com1_or_com2:BYTE	    ;AN000;see modedefs.inc
EXTRN	cp_cb:WORD	      ;AN000;codepage_parms <> ;codepage subroutine parameter block
EXTRN	CRLF:WORD		       ;displayed before "Invalid parameter - " for consistent spacing                      ;AN000;
EXTRN	DES_STRT_FL_CART:ABS		     ;AN000;;CARTRIDGE prepare
EXTRN	device:BYTE		       ;AN000;holder for com number, used in setcom
EXTRN	first_char_in_command_line:BYTE ;AN000;location of the command line parameters
EXTRN	 function_not_supported:BYTE   ;AN000;see modedefs.inc
EXTRN	get_machine_type:NEAR		;AN000;get model and sub-model bytes
EXTRN	invalid_parameter:BYTE		;AN000;CR,LF,"Invalid parameter - '????'"CR,LF,BEEP
EXTRN	LPTNO:BYTE	      ;AN000;holder of ASCII version of printer number, see first_parm_case and modeprin
EXTRN	machine_type:BYTE	    ;AN000;see get_machine_type
EXTRN	modecp:NEAR		    ;AN000;
EXTRN	move_destination:ABS	    ;AN000;location of res code after it has been moved
EXTRN	noerror:BYTE	    ;AN000;
EXTRN	 not_supported_ptr:WORD     ;AN000;holder of address of string that describes what is not supported, see modedefs.inc
EXTRN	 offending_parameter:BYTE	  ;AC006;the holder of the text string that was wrong.
EXTRN	offending_parameter_ptr:WORD	   ;AN000;;see MODEMES
EXTRN	printer_no:BYTE 	       ;AN000;;see modeprin
EXTRN	PRINTF:NEAR		       ;AN000;
EXTRN	rate_and_delay_together:BYTE   ;AN000;RATE and DELAY must be specified together
EXTRN	 syntax_error_ptr:WORD	       ;AN000;pointer to parameter with bad format

;possible values of "message"

EXTRN	baud_rate_required:BYTE        ;AN000;
EXTRN	invalid_number_of_parameters:WORD    ;AN000;
EXTRN	Invalid_switch:BYTE
EXTRN	syntax_error:BYTE


;º											  º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  E X T R N S	ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼


;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  D A T A	ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º											  º

code_page_numbers_encountered	 DB    0
current_packet_cp_number   DW	 -2  ;adjustment for accessing current 'des_strt_pkcp?' in 'des_start_packet'
EOL_found		DB	 false
looking_for		DB	 bogus	  ;semantic analysis state, can be one of:
match_not_found 	DB	 true	  ;indication that a token was found in the list of keywords



des_start_packet	des_strt_packet <>

;----------------------------	   NEW DATA  ---------------------------------



baud_specified		DB    false	  ;AN000;
codepage_index_holder	DW    bogus	  ;AN000;;holder for index in parm_list of the selected code page
colon			DB    ":"         ;AN000;
command_line		DW    0081H	  ;AN000;  ;holder for pointer to unparsed part of the command line, see "parse_parm"
device_name		DW    0 	  ;AN000;;OFFSET device name string, see "analyze_and_invoke" in invoke.asm
device_type		DB    bogus	  ;AN000;
end_of_seperator_list	DW    bogus	  ;AN000;;loop terminator,word because compared with DI
match_found		DB    false	  ;AN000;   ;boolean loop terminator
message 		DW    no_message  ;AN000;
new_com_initialize	DB    false	  ;AC002;flag for modecom to indicate PS/2 only parm specified
number_of_keywords	DB    0 	  ;AN000;;input for check_for_keyword
parms_form		DB    0 	  ;AN000;;holder for indicator of whether the parms were in keyword or positonal form
ordinal 		DW    0 	  ;AN000;
rate_and_delay_found	DB    false	  ;AN000;need to have both, this byte keeps track of what has been found
request_type		DB    bogus	  ;AN000;
reroute_requested	DB    false	  ;AN000;
retry_requested 	DB    false	  ;AN000;
search_stop		DB    0 	  ;AN000;;loop stopper for search_item_tags
status_found		DB    false	  ;AN000;;boolean indicator that /status has been found
status_request		DB    bogus	  ;AN000;;furthur clarification. possible values are: bogus, true, and false
terminating_delimeter	DB    bogus	  ;AN000;;save return from sysparse
type_of_machine 	DB    bogus	  ;AC000;"get_machine_type" determines "machine_type", this byte is general flag for PS/2s


;	PARSER interface data
;---------------------------------------

start_com_keyword_ptrs	LABEL WORD			;AN000;
first_com_keyword_ptr	DW    OFFSET   baud_equal	;AN000;
			DW    OFFSET   parity_equal	;AN000;
			DW    OFFSET   data_equal	;AN000;
			DW    OFFSET   stop_equal	;AN000;
last_com_keyword_ptr	DW    OFFSET   retry_equal_str	    ;AN000;
number_of_com_keywords	EQU   ($ - start_com_keyword_ptrs)/2	;AN000;


start_LPT_keyword_ptrs	LABEL WORD			;AN000;
first_LPT_keyword_ptr	DW    OFFSET   retry_equal_str	    ;AN000;
			DW    OFFSET   COLUMNS_equal	;AN000;
			DW    OFFSET   COLS_equal	;AN000;
last_LPT_keyword_ptr	DW    OFFSET   LINES_equal	;AN000;
number_of_LPT_keywords	EQU   ($ - start_LPT_keyword_ptrs)/2	;AN000;


start_CON_keyword_ptrs	LABEL WORD			;AN000;
first_CON_keyword_ptr	DW    OFFSET   COLUMNS_equal	;AN000;
			DW    OFFSET   COLS_equal	;AN000;
			DW    OFFSET   LINES_equal	;AN000;
			DW    OFFSET   RATE_equal	;AN000;
			DW    OFFSET   DELAY_equal	;AN000;
last_CON_keyword_ptr	DW    OFFSET   DEL_equal	;AN000;
number_of_CON_keywords	EQU   ($ - start_CON_keyword_ptrs)/2	;AN000;



parms	 parms_def<>		 ;AN000;set up for first_parm_case, except parmsx_ptr needs to be set


parmsx	 LABEL	BYTE		 ;AN000;

   DB	    0		       ;AN000;how many non-switch/non-keyword parms are required
   DB	    3		       ;AN000;max pos parms for this parmsx, use others for further parms
   DW	    first_pos_control  ;AN000;control block for every possible (non-mutatant) first positional parm
   DW	    second_pos_control ;AN000;
   DW	    third_pos_control  ;AN000;

   DB	    max_switches		  ;AN000;
   DW	    max_switches DUP (Sw_control) ;AN000;

   DB	    max_keywords	 ;AN000;number of unique keywords for all options

start_keyword_list   LABEL BYTE  ;AN000;

   DW	    LPT1_colon_equal_control   ;AN000;
   DW	    LPT1_equal_control	       ;AN000;
   DW	    LPT2_colon_equal_control   ;AN000;
   DW	    LPT2_equal_control	       ;AN000;
   DW	    LPT3_colon_equal_control   ;AN000;
   DW	    LPT3_equal_control	       ;AN000;

   DW	    RETRY_equal_control  ;AN000;for parallel and serial printers

   DW	    COLUMNS_equal_control   ;AN000;
   DW	    LINES_equal_control     ;AN000;;this and previous MUST OCCUR IN THIS ORDER
   DW	    PREPARE_equal_control   ;AN000;
   DW	    SELECT_equal_control    ;AN000;

max_keywords   EQU   ($ - start_keyword_list) / 2   ;AN000;two bytes per entry



con_parmsx   LABEL  BYTE	     ;AN000;for keyword form of con support

   DB	    0		       ;AN000;no positional parms required after CON
   DB	    2		       ;AN000;CP and REFRESH allowed
   DW	    first_CON_pos_control    ;AN000;control block for CP
   DW	    second_CON_pos_control  ;AN000;control block for REFRESH

   DB	    max_switches		  ;AN000;
   DW	    max_switches DUP (Sw_control) ;AN000;

   DB	    number_of_CON_keywords	   ;AN000;number of unique keywords for CON

start_con_keyword_list	 LABEL BYTE  ;AN000;

   DW	    COLUMNS_equal_control   ;AN000;
   DW	    LINES_equal_control     ;AN000;
   DW	    PREPARE_equal_control   ;AN000;
   DW	    SELECT_equal_control    ;AN000;

   DW	    DELAY_equal_control     ;AN000;
   DW	    RATE_equal_control	    ;AN000;

number_of_con_keywords	 EQU   ($ - start_con_keyword_list) / 2   ;AN000;two bytes per entry


old_con_parmsx	 LABEL	BYTE		 ;AN000;

   DB	    0		       ;AN000;no positional parms required after 80, co40 etc.
   DB	    2		       ;AN000;shift direction and "T" allowed
   DW	    first_old_CON_pos_control	 ;AN000;shift direction and display lines
   DW	    second_old_CON_pos_control	;AN000;control block for T

   DB	    0				  ;AN000;no switches

   DB	    0				  ;AN000;no keywords for old CON


lpt_parmsx   LABEL  BYTE	     ;AN664;for the second thru 4th parms, [[chars/line][[,lines/inch][[,P]]]]

   DB	    0		       ;AN000;how many non-switch/non-keyword parms are required
   DB	    3		       ;AN000;max pos parms for this parmsx, use others for further parms
   DW	    first_lpt_pos_control  ;AN000;control block for every possible chars per line value
   DW	    second_lpt_pos_control ;AN000;
   DW	    third_lpt_pos_control  ;AN000;

   DB	    max_switches		  ;AN000;
   DW	    max_switches DUP (Sw_control) ;AN000;

   DB	    max_lpt_keywords	     ;AN000;number of unique keywords for all options

start_lpt_keyword_list	 LABEL BYTE  ;AN000;

   DW	    RETRY_equal_control  ;AN000;for parallel printers

   DW	    COLUMNS_equal_control   ;AN000;
   DW	    LINES_equal_control     ;AN000;;this and previous MUST OCCUR IN THIS ORDER
   DW	    PREPARE_equal_control   ;AN000;
   DW	    SELECT_equal_control    ;AN000;

max_lpt_keywords   EQU	 ($ - start_keyword_list) / 2	;AN000;two bytes per entry


prepare_equal_parmsx LABEL BYTE 				;AN000;

   prepare_min_parms LABEL BYTE 				;AN000;changed by hardware cp code to allow no filename
   DB	    min_number_of_codepages				;AN000;
   DB	    max_number_of_codepages				;AN000;
   DW	    max_number_of_codepages DUP (prepare_equal_control) ;AN000;
   DB	    max_switches					;AN000;
   DW	    max_switches DUP (Sw_control)			;AN000;
   DB	    0				  ;AN000;no more keywords allowed

com_parmsx   LABEL  BYTE					;AN000;

		    DB	     min_old_com_pos_parms	;AN000;nothing or /STATUS
		    DB	     max_old_com_pos_parms	;AN000;baud, parity, data, stop, p
		    DW	     baud_control		;AN000;
		    DW	     old_com_parity_control	;AN000;
		    DW	     old_com_databits_control	;AN000;control block for old com data bits
		    DW	     old_com_stopbits_control	;AN000;
retry_control_ptr   DW	     old_com_retry_control	;AN000;

		    DB	     max_switches				 ;AN000;
		    DW	     max_switches DUP (Sw_control)		 ;AN000;

		    DB	     number_of_com_keywords			 ;AN000;

start_com_keyword_list	 LABEL BYTE			;AN000;

		    DW	     BAUD_control				 ;AN000;
		    DW	     PARITY_equal_control			 ;AN000;
		    DW	     DATA_equal_control 			 ;AN000;
		    DW	     STOP_equal_control 			 ;AN000;
		    DW	     RETRY_equal_control	;AN000;same as for printers

number_of_com_keywords	 EQU   ($ - start_com_keyword_list) / 2  ;AN000;two bytes per entry


com_keywords_parmsx   LABEL  BYTE			 ;AC663;

   DB	    0			       ;AC663;no positional parms valid
   DB	    0			       ;AC663;

   DB	    0						;AC663;

   DB	    number_of_com_keywords			;AC663;

   DW	    BAUD_control				;AC663;
   DW	    PARITY_equal_control			;AC663;
   DW	    DATA_equal_control				;AC663;
   DW	    STOP_equal_control				;AC663;
   DW	    RETRY_equal_control        ;AC663;same as for printers



mutant_com_parmsx   LABEL  BYTE 	     ;AN000;for trash like COM19600

   DB	  2			    ;AN000;;must find "COM" and a baud rate
   DB	  2			    ;AN000;;"COM", baud
   DW	  COM_control		    ;AN000;
   DW	  baud_control	    ;AN000;use same as other com parmsx

   DB	    0			       ;AN000;no switches

   DB	    0			       ;AN000;no keywords

com_control  LABEL BYTE 	       ;AN000;for mutant_com_parmsx

	       DW	simple_string	 ;AN000;"COM", not optional
	       DW	0		  ;AN000;don't capitalize, leave colon
	       DW	result		  ;AN000;
	       DW	com_value	  ;AN000;
	       DB	0		  ;AN000;no synonyms



old_com_parity_control	LABEL BYTE	  ;AC000;

	       DW	simple_string+optional	;AC000;n, o, e are strings
	       DW	0			;AC000;don't capitalize, leave colon
	       DW	result			;AC000;
	       DW	PARITY_values		;AC000;
	       DB	0			;AC000;;no synonyms


old_com_DATAbits_control   LABEL BYTE		;AC000;

	       DW	simple_string+optional	;AC000;
	       DW	0			;AC000;;don't capitalize, leave colon
	       DW	result			;AC000;
	       DW	DATA_values		;AC000;
	       DB	0			;AC000;



old_com_STOPbits_control   LABEL BYTE		;AC000;

	       DW	simple_string+optional	;AC000;
	       DW	0			;AC000;;don't capitalize, leave colon
	       DW	result			;AC000;
	       DW	STOP_values		;AC000;
	       DB	0			;AC000;



old_com_RETRY_control	LABEL BYTE		;AC000;

	       DW	simple_string+optional	;AC000;;all that is legal for RETRY is P for old com format
	       DW	0			;AC000;;don't capitalize, never need to display to user
	       DW	result			;AC000;
	       DW	RETRY_values		;AC000;
	       DB	0			;AC000;


com_value    LABEL    BYTE	     ;AC000;"COM" for mutant_com_parmsx

   DB	    include_string_list      ;AC000;have list of strings

   DB	    0			     ;AC000;

   DB	    0			     ;AC000;no number choices

   DB	    1			     ;AC000;just "COM"

   DB	    COM_item_tag	     ;AC000;
   DW	    OFFSET COM_str	     ;AC000;


first_pos_control  LABEL BYTE		     ;AN000;initialized for first_parm_case

match_flags    DW	simple_string+optional	 ;***  +ignore_colon  *** ;AN000;2011, all that is legal for non-/status first parm
function_flags DW	0010H			;AN000;don't capitalize, remove colon at end
	       DW	result			;AN000;
values_ptr     DW	first_pos_values	;AN000;
	       DB	0		     ;AN000;no keywords as positionals


second_pos_control  LABEL BYTE		      ;AN000;initialized for first_parm_case

match_flags2	  DW	   simple_string+optional+ignore_colon	;AN000;2011, all that is legal for non-/status first parm
function_flags2   DW	   0010H		   ;AN000;don't capitalize, remove colon at end
		  DW	   result		;AN000;
values_ptr2	  DW	   second_pos_values	;AN000;
		  DB	   0			;AN000;;no keywords as positionals

third_pos_control  LABEL BYTE		     ;AN000;initialized for first_parm_case

match_flags3	  DW	   simple_string+optional+ignore_colon	;AN000;2011, all that is legal for non-/status first parm
function_flags3   DW	   0010H		   ;AN000;don't capitalize, remove colon at end
		  DW	   result		;AN000;
values_ptr3	  DW	   third_pos_values	;AN000;
		  DB	   0			;AN000;;no keywords as positionals

first_lpt_pos_control  LABEL BYTE		 ;AN000;chars per line

	       DW	simple_string+optional	;AN000;2001, all that is legal for chars per line
	       DW	0000H			;AN000;don't capitalize
	       DW	result			;AN000;
	       DW	first_lpt_pos_values	;AN000;
	       DB	0		     ;AN000;no keywords as positionals


second_lpt_pos_control	LABEL BYTE		  ;AN000;lines per inch

		  DW	   simple_string+optional  ;AN000;2001, all that is legal for chars per line
		  DW	   0000H		   ;AN000;don't capitalize
		  DW	   result		;AN000;
		  DW	   second_lpt_pos_values    ;AN000;
		  DB	   0			;AN000;;no keywords as positionals

third_lpt_pos_control  LABEL BYTE		 ;AN000;P

		  DW	   simple_string+optional  ;AN000;2001, all that is legal for retry settings
		  DW	   0000H		   ;AN000;don't capitalize
		  DW	   result		;AN000;
		  DW	   third_lpt_pos_values     ;AN000;
		  DB	   0			;AN000;;no keywords as positionals



BAUD_control  LABEL BYTE		  ;AN000;used for positional and keyword form

	       DW	simple_string	  ;AN000;required
	       DW	0			;AN000;don't capitalize
	       DW	result		    ;AN000;
	       DW	BAUD_values	    ;AN000;
	       DB	1		    ;AN000;;only one form of the keyword

BAUD_equal     DB    "BAUD=",0                      ;AN000;


parity_equal_control  LABEL BYTE		    ;AN000;initialized for first_parm_case

	       DW	simple_string		;AN000;n, o, even, m, space etc are strings
	       DW	0			;AN000;don't capitalize, leave colon
	       DW	result			;AN000;
	       DW	PARITY_values		;AN000;
	       DB	2			;two ways to specify it

parity_equal   DB    "PARITY=",0                ;AN000;
par_equal      DB    "PAR=",0                   ;AN000;



DATA_equal_control   LABEL BYTE 		;AN000;

	       DW	simple_string
	       DW	0			;AN000;;don't capitalize, leave colon
	       DW	result			;AN000;
	       DW	DATA_values		;AN000;
	       DB	1			;AN000;

data_equal     DB    "DATA=",0                  ;AN000;



STOP_equal_control   LABEL BYTE 		;AN000;

	       DW	simple_string		;AN000;
	       DW	0			;AN000;;don't capitalize, leave colon
	       DW	result			;AN000;
	       DW	STOP_values		;AN000;
	       DB	1			;AN000;

stop_equal     DB    "STOP=",0                  ;AN000;



RETRY_equal_control   LABEL BYTE		;AN000;

	       DW	simple_string		;AN000;;all that is legal for RETRY is on and off
	       DW	0			;AN000;;don't capitalize, never need to display to user
	       DW	result			;AN000;
	       DW	RETRY_values		;AN000;
	       DB	1			;AN000;

retry_equal_str DB    "RETRY=",0                 ;AN000;



PREPARE_equal_control	LABEL BYTE		;AN000;

prepare_equal_match_flags  LABEL WORD		;AN000;
	       DW	numeric+complex+filespec  ;AN000;has to be complex at first, then numbers and filespec inside the parens
	       DW	capitalize	  ;AN000;capitalize the filespec
	       DW	result		  ;AN000;
	       DW	prepare_values	  ;AN000;
	       DB	2		  ;AN000;

prepare_equal  DB    "PREPARE=",0         ;AN000;
prep_equal     DB    "PREP=",0            ;AN000;


SELECT_equal_control   LABEL BYTE	  ;AN000;

	       DW	numeric 	  ;AN000;range of codepage numbers
	       DW	0		  ;AN000;don't capitalize, leave colon
	       DW	result		  ;AN000;
	       DW	SELECT_values	  ;AN000;
	       DB	2	       ;AN000;no keywords as positionals

select_equal   DB    "SELECT=",0       ;AN000;
sel_equal      DB    "SEL=",0          ;AN000;


DELAY_equal_control   LABEL BYTE       ;AN000;

	       DW	numeric        ;AN000;	;takes less space than number definitions
	       DW	0	       ;AN000;	;don't capitalize, leave colon
	       DW	result	       ;AN000;
	       DW	DELAY_values   ;AN000;
	       DB	2	       ;AN000;

del_equal      DB    "DEL=",0          ;AN000;
delay_equal    DB    "DELAY=",0        ;AN000;


RATE_equal_control   LABEL BYTE        ;AN000;

	       DW	numeric        ;AN000;
	       DW	0	       ;AN000;	;don't capitalize, leave colon
	       DW	result	       ;AN000;
	       DW	RATE_values    ;AN000;
	       DB	1	       ;AN000;

rate_equal     DB    "RATE=",0         ;AN000;



LINES_equal_control   LABEL BYTE       ;AN000;

LINES_match_flag  DW	   numeric     ;AN000;	   ;setup for CON, changed if find LPTX
		  DW	   0	       ;AN000;	   ;don't capitalize, leave colon
		  DW	   result      ;AN000;
LINES_value_ptr   DW	   CON_LINES_values ;AN000;
		  DB	   1		    ;AN000;

lines_equal	  DB	"LINES=",0          ;AN000;



COLUMNS_equal_control	LABEL BYTE	    ;AN000;

COLUMNS_match_flag   DW       numeric	    ;AN000;   ;setup for CON changed when find LPTX
		     DW       0 	    ;AN000;   ;don't capitalize, leave colon
		     DW       result	    ;AN000;
COLUMNS_value_ptr    DW       CON_COLUMNS_values      ;AN000;setup for CON, changed if find LPTX
		     DB       2 		      ;AN000;

COLUMNS_equal	     DB    "COLUMNS=",0      ;AN000;printer keyword
COLS_equal	     DB    "COLS=",0         ;AN000;


LPT1_colon_equal_control   LABEL BYTE	     ;AN000;

	       DW	simple_string+ignore_colon   ;AN000;COM?[:] is all that is valid
	       DW	0		 ;AN000;;don't capitalize, leave colon
	       DW	result		 ;AN000;
	       DW	reroute_values	 ;AN000;
	       DB	1		 ;AN000;

LPT1_colon_equal  DB "LPT1:=",0          ;AN000;



LPT1_equal_control   LABEL BYTE 	 ;AN000;

	       DW	simple_string+ignore_colon   ;AN000;COM?[:] is all that is valid
	       DW	0			;AN000;don't capitalize, leave colon
	       DW	result			;AN000;
	       DW	reroute_values		;AN000;
	       DB	1			;AN000;

LPT1_equal	  DB "LPT1=",0                  ;AN000;



LPT2_colon_equal_control   LABEL BYTE		;AN000;

	       DW	simple_string+ignore_colon   ;AN000;COM?[:] is all that is valid
	       DW	0		 ;AN000;don't capitalize, leave colon
	       DW	result		 ;AN000;
	       DW	reroute_values	 ;AN000;
	       DB	1		 ;AN000;

LPT2_colon_equal  DB "LPT2:=",0          ;AN000;



LPT2_equal_control   LABEL BYTE 	 ;AN000;

	       DW	simple_string+ignore_colon   ;AN000;;COM?[:] is all that is valid
	       DW	0		 ;AN000;don't capitalize, leave colon
	       DW	result		 ;AN000;
	       DW	reroute_values	 ;AN000;
	       DB	1		 ;AN000;

LPT2_equal	  DB "LPT2=",0           ;AN000;



LPT3_colon_equal_control   LABEL BYTE	 ;AN000;

	       DW	simple_string+ignore_colon   ;AN000;COM?[:] is all that is valid
	       DW	0		 ;AN000;don't capitalize, leave colon
	       DW	result		 ;AN000;
	       DW	reroute_values	 ;AN000;
	       DB	1		 ;AN000;

LPT3_colon_equal  DB "LPT3:=",0          ;AN000;



LPT3_equal_control   LABEL BYTE 	 ;AN000;

	       DW	simple_string+ignore_colon   ;AN000;COM?[:] is all that is valid
	       DW	0		  ;AN000;don't capitalize, leave colon
	       DW	result		  ;AN000;
	       DW	reroute_values	  ;AN000;
	       DB	1		  ;AN000;

LPT3_equal	  DB "LPT3=",0            ;AN000;

first_con_pos_control	LABEL BYTE	    ;AN000;

	       DW	simple_string	  ;AN000;CP, code, codepage
	       DW	0		  ;AN000;don't capitalize, leave colon
	       DW	result		  ;AN000;
	       DW	OFFSET	 first_CON_pos_values	 ;AN000;
	       DB	0		  ;AN000;no synonyms


second_con_pos_control	 LABEL BYTE	     ;AN000;

	       DW	simple_string	  ;AN000;REFRESH
	       DW	0		  ;AN000;don't capitalize, leave colon
	       DW	result		  ;AN000;
	       DW	OFFSET	 second_CON_pos_values	  ;AN000;
	       DB	0		  ;AN000;no synonyms

first_old_con_pos_control   LABEL BYTE		;AN000;

	       DW	simple_string+numeric  ;AN000;r, l or screen lines request
	       DW	0		  ;AN000;don't capitalize
	       DW	result		  ;AN000;
	       DW	OFFSET	 first_old_CON_pos_values    ;AN000;
	       DB	0		  ;AN000;no synonyms


second_old_con_pos_control   LABEL BYTE 	 ;AN000;

	       DW	simple_string+optional	   ;AN000;T
	       DW	0		  ;AN000;don't capitalize
	       DW	result		  ;AN000;
	       DW	OFFSET	 second_old_CON_pos_values    ;AN000;
	       DB	0		  ;AN000;no synonyms

first_old_CON_pos_values    LABEL    BYTE      ;all valid forms of shift direction, and screen line values ;AN000;

   DB	    include_string_list      ;AN000;have list of strings

   DB	    0			     ;no number ranges		;AN000;

   DB	    number_of_CON_lines_numbers      ;number of rows choices;AN000;

   DB	    twentyfive_item_tag 				;AN000;
   DD	    25							;AN000;
   DB	    fourtythree_item_tag				;AN000;
   DD	    43							;AN000;
   DB	    fifty_item_tag					;AN000;
   DD	    50							;AN000;

   DB	    number_of_shift_forms      ;number of shift strings AN000;

   start_shift_forms   LABEL	BYTE			  ;AN000;


   DB	    R_item_tag		 ;AN000;
   DW	    OFFSET R_str	 ;AN000;
   DB	    L_item_tag		 ;AN000;
   DW	    OFFSET L_str	 ;AN000;


   number_of_shift_forms  EQU	($ - start_shift_forms)/3	;3 bytes per entry;AN000;


second_old_CON_pos_values    LABEL    BYTE	;all valid forms of T	;AN000;

   DB	    include_string_list      ;AN000;have list of strings

   DB	    0			     ;no number ranges		;AN000;

   DB	    0			    ;no number list		;AN000;

   DB	    number_of_T_forms	   ;number of T strings AN000;

   start_T_forms   LABEL    BYTE		      ;AN000;


   DB	    T_item_tag		 ;AN000;
   DW	    OFFSET T_str	 ;AN000;


   number_of_T_forms  EQU   ($ - start_T_forms)/3	;3 bytes per entry;AN000;


first_CON_pos_values	LABEL	 BYTE	   ;all valid forms of codepage;AN000;

   DB	    include_string_list      ;AN000;have list of strings

   DB	    0			     ;no number ranges		;AN000;

   DB	    0			    ;no number list		;AN000;

   DB	    number_of_CP_forms	    ;number of cp strings AN000;

   start_CP_forms   LABEL    BYTE		       ;AN000;


   ;codepage strings

   DB	    CODEPAGE_item_tag	 ;AN000;
   DW	    OFFSET CODE_str	 ;AN000;
   DB	    CODEPAGE_item_tag	 ;AN000;
   DW	    OFFSET CODEPAGE_str  ;AN000;
   DB	    CODEPAGE_item_tag	 ;AN000;
   DW	    OFFSET CP_str	 ;AN000;

   ;invalid choice, included for usable error reporting: if come across refresh right after CON then issue invalid number of parms

   DB	    REFRESH_item_tag	 ;AC007;
   DW	    OFFSET REF_str	 ;AC007;
   DB	    REFRESH_item_tag	 ;AC007;
   DW	    OFFSET REFRESH_str	 ;AC007;

   number_of_CP_forms  EQU   ($ - start_CP_forms)/3	  ;3 bytes per entry;AN000;


second_CON_pos_values	 LABEL	  BYTE	    ;all valid forms of REFRESH;AN000;

   DB	    include_string_list      ;AN000;have list of strings

   DB	    0			     ;no number ranges		;AN000;

   DB	    0			    ;no number list		;AN000;

   DB	    number_of_REFRESH_forms	 ;number of REFRESH strings AN000;

   start_REFRESH_forms	 LABEL	  BYTE			    ;AN000;

   DB	    REFRESH_item_tag	 ;AN000;
   DW	    OFFSET REF_str	 ;AN000;
   DB	    REFRESH_item_tag	 ;AN000;
   DW	    OFFSET REFRESH_str	 ;AN000;

   number_of_REFRESH_forms  EQU   ($ - start_REFRESH_forms)/3	    ;3 bytes per entry;AN000;


BAUD_values    LABEL	BYTE		 ;AN000;;all valid baud rates

   DB	    include_string_list      ;AN000;have list of numbers and two strings

   DB	    0			     ;AN000;

   DB	    0			 ;AN000;no numeric representations

   DB	    number_of_baud_strings   ;AN000;number of baud rates that are being used for other parameters also

   start_baud_strings	LABEL	 BYTE	  ;AN000;

   DB	    oneten_item_tag		  ;AN000;
   DW	    OFFSET oneten_str		  ;AN000;
   DB	    oneten_item_tag		  ;AN000;
   DW	    OFFSET eleven_str	;AN000;;"11" first two chars of 110
   DB	    onefifty_item_tag	;AN000;
   DW	    OFFSET fifteen_str	;AN000;
   DB	    onefifty_item_tag	;AN000;
   DW	    OFFSET onefifty_str ;AN000;
   DB	    threehundred_item_tag      ;AN000;
   DW	    OFFSET thirty_str	       ;AN000;
   DB	    threehundred_item_tag      ;AN000;
   DW	    OFFSET threehundred_str    ;AN000;
   DB	    sixhundred_item_tag        ;AN000;
   DW	    OFFSET sixty_str	       ;AN000;
   DB	    sixhundred_item_tag        ;AN000;
   DW	    OFFSET sixhundred_str      ;AN000;
   DB	    twelvehundred_item_tag     ;AN000;
   DW	    OFFSET twelve_str	       ;AN000;
   DB	    twelvehundred_item_tag     ;AN000;
   DW	    OFFSET twelvehundred_str   ;AN000;
   DB	    twentyfourhundred_item_tag ;AN000;
   DW	    OFFSET twentyfour_str      ;AN000;24 is also a typamatic rate
   DB	    twentyfourhundred_item_tag ;AN000;
   DW	    OFFSET twentyfourhundred_str     ;AN000;
   DB	    fourtyeighthundred_item_tag      ;AN000;
   DW	    OFFSET fourtyeight_str	     ;AN000;
   DB	    fourtyeighthundred_item_tag      ;AN000;
   DW	    OFFSET fourtyeighthundred_str    ;AN000;
   DB	    ninetysixhundred_item_tag	     ;AN000;
   DW	    OFFSET ninetysix_str	     ;AN000;
   DB	    ninetysixhundred_item_tag	     ;AN000;
   DW	    OFFSET ninetysixhundred_str      ;AN000;
   DB	    nineteentwohundred_item_tag      ;AN000;;item tag
   DW	    OFFSET nineteentwohundred_str ;AN000;;pointer to string
   DB	    nineteentwohundred_item_tag   ;AN000;;item tag
   DW	    OFFSET nineteen_point_two_str ;AN000;
   DB	    nineteentwohundred_item_tag   ;AN000;  ;item tag
   DW	    OFFSET nineteen_str 	  ;AN000;   ;used for RATE= also
   DB	    nineteentwohundred_item_tag   ;AN000;  ;item tag
   DW	    OFFSET nineteen_point_two_K_str ;AN000;pointer to string "19.2K"

   number_of_baud_strings  EQU	 ($ - start_baud_strings)/3  ;AN000;3 bytes per entry



PARITY_values	 LABEL	  BYTE		    ;AN000;all valid paritys

   DB	    include_string_list      ;AN000;have list of strings

   DB	    0			     ;AN000;

   DB	    0			;AN000;;no number choices

   DB	    number_of_paritys	;AN000;;number of valid paritys

   start_paritys   LABEL    BYTE       ;AN000;

   DB	    none_item_tag	       ;AN000;
   DW	    OFFSET N_str	       ;AN000;
   DB	    none_item_tag	       ;AN000;
   DW	    OFFSET NONE_str	       ;AN000;
   DB	    even_item_tag	       ;AN000;
   DW	    OFFSET EVEN_str	       ;AN000;
   DB	    even_item_tag	       ;AN000;
   DW	    OFFSET E_str	       ;AN000;
   DB	    odd_item_tag	       ;AN663;
   DW	    OFFSET O_str	       ;AN663;
   DB	    odd_item_tag	       ;AN000;
   DW	    OFFSET ODD_str	       ;AN000;
   DB	    MARK_item_tag	       ;AN663;
   DW	    OFFSET m_str	       ;AN663;
   DB	    MARK_item_tag	       ;AN000;
   DW	    OFFSET mark_str	       ;AN000;
   DB	    SPACE_item_tag	       ;AN663;
   DW	    OFFSET s_str	       ;AN663;
   DB	    SPACE_item_tag	       ;AN000;
   DW	    OFFSET space_str	       ;AN000;

   number_of_paritys  EQU   ($ - start_paritys)/3 ;AN000;3 bytes per entry


DATA_values    LABEL	BYTE		  ;AN000;all valid DATA values

   DB	    include_string_list  ;AC663;have list of numbers

   DB	    0			 ;AN000;no number ranges

   DB	    0			 ;AN000;no number choices

   DB	    number_of_databits	 ;AN000;string choices

   start_databits   LABEL    BYTE   ;AN000;

   DB	    five_item_tag	    ;AN000;
   DW	    OFFSET five_str	    ;AN000;
   DB	    six_item_tag	    ;AN000;
   DW	    OFFSET six_str	    ;AN000;
   DB	    seven_item_tag	    ;AN000;
   DW	    OFFSET seven_str	    ;AN000;
   DB	    eight_item_tag	    ;AN000;
   DW	    OFFSET eight_str	    ;AN000;

   number_of_databits  EQU   ($ - start_databits)/3 ;AN000;3 bytes per entry


STOP_values    LABEL	BYTE		 ;AN000;;all valid stop bits

   DB	    include_string_list      ;AN000;have list of numbers and list of strings

   DB	    0			     ;AN000;

   DB	    0			      ;AN000; ;no number choices

   DB	    number_of_stopbit_strings  ;AN000;;choices in string form

   start_stopbit_strings   LABEL    BYTE    ;AN000;

   DB	    one_item_tag		    ;AN000;
   DW	    OFFSET one_str		    ;AN000;
   DB	    one_point_five_item_tag	    ;AN000;
   DW	    OFFSET one_point_five_str	    ;AN000;
   DB	    two_item_tag		    ;AN000;
   DW	    OFFSET two_str		    ;AN000;

   number_of_stopbit_strings  EQU   ($ - start_stopbit_strings)/3  ;AN000;3 bytes per entry



RETRY_values	LABEL	 BYTE		  ;AN000;;all valid RETRY settings

   DB	    include_string_list      ;AN000;have list of strings

   DB	    0			     ;AN000;

   DB	    0			;AN000;;no number choices

   DB	    number_of_retry_settings   ;AN000;

   start_retry_settings   LABEL    BYTE   ;AN000;

   DB	    B_item_tag			  ;AN000;
   DW	    OFFSET B_str		  ;AN000;
   DB	    E_item_tag			  ;AN000;
   DW	    OFFSET E_str		  ;AN000;
   DB	    R_item_tag			  ;AN000;
   DW	    OFFSET R_str		  ;AN000;
   DB	    NONE_item_tag		  ;AN663;
   DW	    OFFSET N_str		  ;AN663;
   DB	    NONE_item_tag		  ;AN000;
   DW	    OFFSET NONE_str		  ;AN000;
   DB	    P_item_tag			  ;AN000;
   DW	    OFFSET P_str		  ;AN000;

   number_of_retry_settings  EQU   ($ - start_retry_settings)/3 ;AN000;3 bytes per entry



PREPARE_values	  LABEL    BYTE        ;AN000;almost any numeric value is valid

   DB	    ranges_only 	       ;AN000;;have range of numbers

   DB	    1			       ;AN000;;one range

   DB	    codepage_item_tag	       ;AN000;
   DD	    min_codepage_value	       ;AN000;
   DD	    max_codepage_value	       ;AN000;




SELECT_values	 LABEL	  BYTE		    ;AN000;all valid baud rates

   DB	    ranges_only 	;AN000;;have range of numbers

   DB	    1			;AN000;

   DB	    codepage_item_tag	;AN000;;item tag for the range
   DD	    min_codepage_value	;AN000;
   DD	    max_codepage_value	;AN000;


DELAY_values	LABEL	 BYTE		  ;AN000;;all valid delay rates

   DB	    ranges_only 	;AN000;;have range of numbers

   DB	    1			;AN000;;1 range
   DB	    range_item_tag	;AN000;;don't ever need this item tag
   DD	    1			;AN000;;smallest valid delay value
   DD	    4			;AN000;;largest valid delay value



RATE_values    LABEL	BYTE		 ;AN000;;all valid typamatic rates

   DB	    ranges_only 	;AN000;;have range of numbers

   DB	    1			;AN000;;1 range
   DB	    range_item_tag	;AN000;;never used
   DD	    1			;AN000;;smallest valid rate
   DD	    32			;AN000;;largest valid rate




CON_COLUMNS_values    LABEL    BYTE ;AN000;all valid columns values for the screen

   DB	    include_number_list     ;AN000;    ;have list of numbers

   DB	    0			    ;AN000;only numeric representations

   DB	    number_of_CON_columns_numbers   ;AN000;choices represented as numbers

   start_CON_columns_numbers   LABEL	BYTE   ;AN000;

   DB	    fourty_item_tag		       ;AN000;
   DD	    40				       ;AN000;
   DB	    eighty_item_tag	    ;	       ;AN000;
   DD	    80			     ;AN000;numbers because used in call to IOCTL

   number_of_CON_columns_numbers  EQU	($ - start_CON_columns_numbers)/5	;5 bytes per entry;AN000;



CON_LINES_values    LABEL    BYTE      ;all valid LINES= values for the screen;AN000;

   DB	    include_number_list 	   ;have list of numbers;AN000;

   DB	    0							;AN000;

   DB	    number_of_CON_lines_numbers 	     ; number ch;AN000;

   start_CON_lines_numbers   LABEL    BYTE			;AN000;

   DB	    twentyfive_item_tag 				;AN000;
   DD	    25							;AN000;
   DB	    fourtythree_item_tag				;AN000;
   DD	    43							;AN000;
   DB	    fifty_item_tag					;AN000;
   DD	    50							;AN000;

   number_of_CON_lines_numbers	EQU   ($ - start_CON_lines_numbers)/5	    ;5 bytes per entry;AN000;




LPT_COLUMNS_values    LABEL    BYTE ;AN000;all valid columns values for parallel printers

   DB	    include_string_list     ;AN000;;have list of strings

   DB	    0			    ;AN000;

   DB	    0			    ;AN000;no numeric representations

   DB	    number_of_lpt_columns_strings  ;AN000;;choices represented as strings

   start_LPT_columns_strings   LABEL	BYTE	;AN000;

   DB	    eighty_item_tag	    ;		;AN000;
   DW	    OFFSET eighty_str	    ;AN000;;strings because values also used as positional parms
   DB	    onethirtytwo_item_tag   ;AN000;
   DW	    OFFSET onethirtytwo_str ;AN000;

   number_of_LPT_columns_strings  EQU	($ - start_LPT_columns_strings)/3	;3 bytes per entry;AN000;



LPT_LINES_values    LABEL    BYTE ;AN000;all valid LINES= values for the screen

   DB	    include_string_list       ;AN000;have list of strings

   DB	    0			      ;AN000;

   DB	    0			      ;AN000;	 ;no number choices

   DB	    number_of_LPT_lines_strings   ;AN000;

   start_LPT_lines_strings   LABEL    BYTE   ;AN000;

   DB	    six_item_tag		 ;AN000;;for printer
   DW	    OFFSET six_str		 ;AN000;
   DB	    eight_item_tag		 ;AN000;;for printer
   DW	    OFFSET eight_str		 ;AN000;

   number_of_LPT_lines_strings	EQU   ($ - start_LPT_lines_strings)/3 ;AN000;3 bytes per entry


reroute_values	  LABEL    BYTE    ;AN000;;all valid destination devices for parallel printer reroute

   DB	    include_string_list    ;AN000; ;have list of numbers and one string

   DB	    0			   ;AN000;

   DB	    0			;AN000;;no number choices

   DB	    number_of_reroute_strings	  ;AN000;

   start_reroute_strings   LABEL    BYTE  ;AN000;

   DB	    COM1_item_tag		  ;AN000;
   DW	    OFFSET COM1_str		  ;AN000;
   DB	    COM2_item_tag		  ;AN000;
   DW	    OFFSET COM2_str		  ;AN000;
   DB	    COM3_item_tag		  ;AN000;
   DW	    OFFSET COM3_str		  ;AN000;
   DB	    COM4_item_tag		  ;AN000;
   DW	    OFFSET COM4_str		  ;AN000;

   number_of_reroute_strings  EQU   ($ - start_reroute_strings)/3 ;AN000;3 bytes per entry




Sw_control  LABEL BYTE						  ;AN000;

	       DW	0		  ;AN000;no values allowed on /STATUS
function_flag  DW	0		  ;AN000;no values allowed on /STATUS
	       DW	result		  ;AN000;same buffer as for other parms
	       DW	Sw_values	  ;AN000;
num_synonyms   DB	3		  ;AN000;3 ways to specify /STATUS
slash_sta      DB	"/STA",0          ;AN000;
slash_stat     DB	"/STAT",0         ;AN000;
slash_status   DB	"/STATUS",0       ;AN000;






Sw_values   LABEL    BYTE		  ;AN000;

   DB	 0		;AN000;no values allowed on /STATUS


first_pos_values    LABEL BYTE	 ;AN000;value list for all positional parameters that appear first

   DB	    include_string_list  ;AN000;   ;have string values

   DB	    0			 ;AN000;numerics treated as strings

   DB	    0			 ;AN000;no number choices

   DB	    number_of_first_positional_strings		;AN000;

   start_first_positional_strings   LABEL    BYTE     ;used to calculate previous field;AN000;

   ;screen modes

   DB	    BW40_item_tag     ;AC000;
   DW	    OFFSET BW40_str   ;AC000;
   DB	    BW80_item_tag     ;AC000;
   DW	    OFFSET BW80_str   ;AC000;
   DB	    CO40_item_tag     ;AC000;
   DW	    OFFSET CO40_str   ;AC000;
   DB	    CO80_item_tag     ;AC000;
   DW	    OFFSET CO80_str   ;AC000;
   DB	    MONO_item_tag     ;AC000;
   DW	    OFFSET MONO_str   ;AC000;
   DB	    fourty_item_tag   ;AC000;
   DW	    OFFSET fourty_str ;AC000;
   DB	    eighty_item_tag   ;AC000;
   DW	    OFFSET eighty_str ;AC000;


   DB	    con_item_tag      ;AN000;
   DW	    OFFSET con_str    ;AN000;

   ;com port names

   DB	    COM1_item_tag     ;AN000;
   DW	    OFFSET COM1_str   ;AN000;
   DB	    COM2_item_tag     ;AN000;
   DW	    OFFSET COM2_str   ;AN000;
   DB	    COM3_item_tag     ;AN000;
   DW	    OFFSET COM3_str   ;AN000;
   DB	    COM4_item_tag     ;AN000;
   DW	    OFFSET COM4_str   ;AN000;

   ;printer port names

   DB	    PRN_item_tag      ;AN000;
   DW	    OFFSET PRN_str    ;AN000;
   DB	    LPT1_item_tag     ;AN000;
   DW	    OFFSET LPT1_str   ;AN000;
   DB	    LPT2_item_tag     ;AN000;
   DW	    OFFSET LPT2_str   ;AN000;
   DB	    LPT3_item_tag     ;AN000;
   DW	    OFFSET LPT3_str   ;AN000;

   ;LPT special cases

   DB	    LPT1132_item_tag  ;AN000;
   DW	    OFFSET LPT1132_str;AN000;
   DB	    LPT2132_item_tag  ;AN000;
   DW	    OFFSET LPT2132_str;AN000;
   DB	    LPT3132_item_tag  ;AN000;
   DW	    OFFSET LPT3132_str;AN000;
   DB	    LPT180_item_tag   ;AN000;
   DW	    OFFSET LPT180_str ;AN000;
   DB	    LPT280_item_tag   ;AN000;
   DW	    OFFSET LPT280_str ;AN000;
   DB	    LPT380_item_tag   ;AN000;
   DW	    OFFSET LPT380_str ;AN000;


number_of_first_positional_strings  EQU   ($ - start_first_positional_strings)/3 ;each entry is 3 bytes (byte, word);AN000;



second_pos_values    LABEL BYTE  ;AN000;;value list for all positional parameters that appear second

   DB	    include_string_list  ;AN000;   ;have string values

   DB	    0			 ;AN000;numerics treated as strings

   DB	    0			 ;AN000;no number choices

   DB	    number_of_second_positional_strings 	;AN000;

   start_second_positional_strings   LABEL    BYTE     ;used to calculate previous field;AN000;


   ;codepage strings

   DB	    CODEPAGE_item_tag	 ;AN000;
   DW	    OFFSET CODE_str	 ;AN000;
   DB	    CODEPAGE_item_tag	 ;AN000;
   DW	    OFFSET CODEPAGE_str  ;AN000;
   DB	    CODEPAGE_item_tag	 ;AN000;
   DW	    OFFSET CP_str	 ;AN000;

   ;invalid choice, included for usable error reporting: if come across refresh right after CON then issue invalid number of parms

   DB	    REFRESH_item_tag	 ;AC007;
   DW	    OFFSET REF_str	 ;AC007;
   DB	    REFRESH_item_tag	 ;AC007;
   DW	    OFFSET REFRESH_str	 ;AC007;

   ;shift directions

   DB	    L_item_tag		 ;AN000;
   DW	    OFFSET L_str	 ;AN000;
   DB	    R_item_tag		 ;AN000;
   DW	    OFFSET R_str	 ;AN000;


   ;columns values

;  DB	    eighty_item_tag	 ;AN000;
;  DW	    OFFSET eighty_str	 ;AN000;   ;strings because values also used as positional parms
   DB	    onethirtytwo_item_tag;AN000;
   DW	    OFFSET onethirtytwo_str    ;AN000;

number_of_second_positional_strings  EQU   ($ - start_second_positional_strings)/3 ;each entry is 3 bytes (byte, word);AN000;


third_pos_values    LABEL BYTE	 ;AN000;value list for all positional parameters that appear third

   DB	    include_string_list  ;AN000;   ;have string values

   DB	    0			 ;AN000;numerics treated as strings

   DB	    0			 ;AN000;no number choices

   DB	    number_of_third_positional_strings			;AN000;

   start_third_positional_strings   LABEL    BYTE     ;used to calculate previous field;AN000;

number_of_third_positional_strings  EQU   ($ - start_third_positional_strings)/3 ;each entry is 3 bytes (byte, word);AN000;


first_lpt_pos_values	LABEL BYTE   ;AN000;value list for all possible chars per line

   DB	    include_string_list  ;AN000;   ;have string values

   DB	    0			 ;AN000;numerics treated as strings

   DB	    0			 ;AN000;no number choices

   DB	    number_of_first_lpt_positional_strings	    ;AN000;

   start_first_lpt_positional_strings	LABEL	 BYTE	  ;used to calculate previous field;AN000;

   DB	    eighty_item_tag
   DW	    OFFSET eighty_str
   DB	    onethirtytwo_item_tag
   DW	    OFFSET onethirtytwo_str	;AN000;
   DB	    CODEPAGE_item_tag
   DW	    OFFSET CODE_str	 ;AN000;
   DB	    CODEPAGE_item_tag	 ;AN000;
   DW	    OFFSET CODEPAGE_str  ;AN000;
   DB	    CODEPAGE_item_tag	 ;AN000;
   DW	    OFFSET CP_str	 ;AN000;

   ;invalid choice, included for usable error reporting: if come across refresh right after CON then issue invalid number of parms

   DB	    REFRESH_item_tag	 ;AC007;
   DW	    OFFSET REF_str	 ;AC007;
   DB	    REFRESH_item_tag	 ;AC007;
   DW	    OFFSET REFRESH_str	 ;AC007;

number_of_first_lpt_positional_strings	EQU   ($ - start_first_lpt_positional_strings)/3 ;each entry is 3 bytes (byte, word);AN000;


second_lpt_pos_values	 LABEL BYTE   ;AN000;value list for all possible lines per inch

   DB	    include_string_list  ;AN000;   ;have string values

   DB	    0			 ;AN000;numerics treated as strings

   DB	    0			 ;AN000;no number choices

   DB	    number_of_second_lpt_positional_strings	     ;AN000;

   start_second_lpt_positional_strings	 LABEL	  BYTE	   ;used to calculate previous field;AN000;

   DB	    eight_item_tag		  ;AN000;
   DW	    OFFSET eight_str		  ;AN000;
   DB	    six_item_tag		  ;AN000;
   DW	    OFFSET six_str     ;AN000;
   DB	    REFRESH_item_tag	 ;AN000;
   DW	    OFFSET REF_str	 ;AN000;
   DB	    REFRESH_item_tag	 ;AN000;
   DW	    OFFSET REFRESH_str	 ;AN000;

number_of_second_lpt_positional_strings  EQU   ($ - start_second_lpt_positional_strings)/3 ;3 bytes per entry (byte,word);AN000;


third_lpt_pos_values	LABEL BYTE   ;AN000;value list for all possible retry settings

   DB	    include_string_list  ;AN000;   ;have string values

   DB	    0			 ;AN000;no numeric ranges

   DB	    0			 ;AN000;no number choices

   DB	    number_of_third_lpt_positional_strings	    ;AN000;

   start_third_lpt_positional_strings	LABEL	 BYTE	  ;used to calculate previous field;AN000;

   DB	    B_item_tag			  ;AN000;
   DW	    OFFSET B_str		  ;AN000;
   DB	    E_item_tag			  ;AN000;
   DW	    OFFSET E_str		  ;AN000;
   DB	    R_item_tag			  ;AN000;
   DW	    OFFSET R_str		  ;AN000;
   DB	    NONE_item_tag		  ;AN663;
   DW	    OFFSET N_str		  ;AN663;
   DB	    NONE_item_tag		  ;AN000;
   DW	    OFFSET NONE_str		  ;AN000;
   DB	    OFF_item_tag		  ;AN000;
   DW	    OFFSET OFF_str		  ;AN000;
   DB	    P_item_tag
   DW	    OFFSET P_str

number_of_third_lpt_positional_strings	EQU   ($ - start_third_lpt_positional_strings)/3 ;each entry is 3 bytes (byte, word);AN000;



;strings

					  ;AN000;
zero_str		  DB  "0",0       ;AN000;
one_str 		  DB  "1",0       ;AN000;
one_point_five_str	  DB  "1.5",0     ;AN000;
two_str 		  DB  "2",0       ;AN000;
three_str		  DB  "3",0       ;AN000;
four_str		  DB  "4",0       ;AN000;
five_str		  DB  "5",0       ;AN000;  ;data bit, typamatic rate
six_str 		  DB  "6",0       ;AN000;
seven_str		  DB  "7",0       ;AN000;
eight_str		  DB  "8",0       ;AN000;
nine_str		  DB  "9",0       ;AN000;
eleven_str		  DB  "11",0      ;AN000; ;first two chars of 110
twelve_str		  DB  "12",0      ;AN000;
fifteen_str		  DB  "15",0      ;AN000; ;abbreviated form of 150, 15 is also a RATE= candidate
nineteen_str		  DB  "19",0      ;AN000; ;used for baud rates and RATE=
nineteen_point_two_str	  DB  "19.2",0    ;AN000;
nineteen_point_two_K_str  DB  "19.2K",0   ;AN000; ;mutant baud rate
twentyfour_str		  DB  "24",0      ;AN000; ;24 is also a typamatic rate
thirty_str		  DB  "30",0      ;AN000;
fourty_str		  DB  "40",0      ;AN000;
fourtyeight_str 	  DB  "48",0      ;AN000;
sixty_str		  DB  "60",0      ;AN000;
eighty_str		  DB  "80",0      ;AN000;
ninetysix_str		  DB  "96",0      ;AN000;
oneten_str		  DB  "110",0     ;AN000;
onethirtytwo_str	  DB  "132",0     ;AN000;
onefifty_str		  DB  "150",0     ;AN000;
threehundred_str	  DB  "300",0     ;AN000;
sixhundred_str		  DB  "600",0     ;AN000;
twelvehundred_str	  DB  "1200",0    ;AN000;
twentyfourhundred_str	  DB  "2400",0    ;AN000;
fourtyeighthundred_str	  DB  "4800",0    ;AN000;
ninetysixhundred_str	  DB  "9600",0    ;AN000;
nineteentwohundred_str	  DB  "19200",0   ;AN000;
B_str			  DB  "B",0       ;AN000;
BW40_str		  DB  "BW40",0    ;AN000;
BW80_str		  DB  "BW80",0    ;AN000;
CO40_str		  DB  "CO40",0    ;AN000;
CO80_str		  DB  "CO80",0    ;AN000;
CODE_str		  DB  "CODE",0    ;AN000;
CODEPAGE_str		  DB  "CODEPAGE",0;AN000;
COM_str 		  DB  "COM",0     ;AN000;
start_COM1_str	  LABEL BYTE		  ;AN000;  ;used to calculate len_COMX_str, see invoke
COM1_str		  DB  "COM1",0    ;AN000;
len_COMX_str	  EQU	$ - start_COM1_str;AN000;  ;all COMX strings are the same length
COM2_str		  DB  "COM2",0    ;AN000;
COM3_str		  DB  "COM3",0    ;AN000;
COM4_str		  DB  "COM4",0    ;AN000;
CON_str 		  DB  "CON",0
len_CON_str	  EQU  ($ - (OFFSET CON_str))						  ;AN000;
CP_str			  DB  "CP",0                                                      ;AN000;
E_str			  DB  "E",0             ;RETRY=setting                            ;AN000;
EVEN_str		  DB  "EVEN",0                                                    ;AN000;
L_str			  DB  "L",0                                                       ;AN000;
start_LPT1_str	  LABEL BYTE		     ;used to calculate len_LPTX_str, see invoke  ;AN000;
LPT1_str		  DB  "LPT1",0                                                    ;AN000;
len_LPTX_str	  EQU	$ - start_LPT1_str   ;all LPTX strings are the same length	  ;AN000;
LPT2_str		  DB  "LPT2",0                                                    ;AN000;
LPT3_str		  DB  "LPT3",0                                                    ;AN000;
LPT1132_str		  DB  "LPT1132",0                                                 ;AN000;
LPT2132_str		  DB  "LPT2132",0                                                 ;AN000;
LPT3132_str		  DB  "LPT3132",0                                                 ;AN000;
LPT180_str		  DB  "LPT180",0                                                  ;AN000;
LPT280_str		  DB  "LPT280",0                                                  ;AN000;
LPT380_str		  DB  "LPT380",0                                                  ;AN000;
M_str			  DB  "M",0
MARK_str		  DB  "MARK",0                                                    ;AN000;
MONO_str		  DB  "MONO",0                                                    ;AN000;
N_str			  DB  "N",0                                                       ;AN000;
NONE_str		  DB  "NONE",0                                                    ;AN000;
O_str			  DB  "O",0                                                       ;AN000;
ODD_str 		  DB  "ODD",0                                                     ;AN000;
OFF_str 		  DB  "OFF",0                                                     ;AN000;
ON_str			  DB  "ON",0                                                      ;AN000;
P_str			  DB  "P",0                                                       ;AN000;
PRN_str 		  DB  "PRN",0                                                     ;AN000;
R_str			  DB  "R",0                                                       ;AN000;
REF_str 		  DB  "REF",0                                                     ;AN000;
REFRESH_str		  DB  "REFRESH",0                                                 ;AN000;
S_str			  DB  "S",0
SPACE_str		  DB  "SPACE",0                                                   ;AN000;
T_str			  DB  "T",0                                                       ;AN000;


result	     result_def<>					;AN000;

parm_lst    parm_list_entry  max_parms DUP (<>) 		;AN000;



;º											  º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  D A T A	ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼


;
;******************************************************************************************

;-------------------------------------------------------------------------------
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³
;³ SEARCH_ITEM_TAGS
;³ ----------------
;³  Search the item tags in input value list for the input item tag.
;³
;³
;³
;³
;³
;³
;³  INPUT: i_CL - first item tag in the group
;³	   search_stop - last item_tag in the group, the sentinal for the REPEAT
;³			 loop.
;³
;³
;³  RETURN: match_found indicates that the item tag returned by the parser was
;³	    found in the group passed in.
;³
;³
;³  MESSAGES: none
;³
;³
;³
;³
;³  REGISTER
;³  USAGE:	 To be determined at I2 time.
;³
;³
;³  CONVENTIONS:
;³
;³
;³
;³
;³  ASSUMPTIONS:
;³
;³
;³  SIDE EFFECT:
;³
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

search_item_tags  PROC	NEAR			      ;AN000;


MOV   match_found,false 			      ;AN000;
.REPEAT
   .IF <parm_list[current_parm_DI].item_tag EQ i_CL> THEN   ;AN000;
      MOV   match_found,true		      ;AN000;
      MOV   i_CL,last_databit_item_tag		 ;AN000;set end of loop trigger
   .ENDIF				      ;AN000;
   INC	 i_CL				      ;AN000;
.UNTIL <i_CL GT search_stop>	  ;AN000;

RET

search_item_tags  ENDP				      ;AN000;

;-------------------------------------------------------------------------------
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³
;³ CHECK_FOR_KEYWORD
;³ ---------------------
;³
;³ Scan the list of keywords (OFFSETS) looking for a match with
;³ parm_list[current_parm_DI].keyword_switch_ptr.
;³
;³
;³
;³  INPUT: uses global variables.
;³
;³
;³  RETURN: match_found is set to true if a match is found.
;³
;³
;³  MESSAGES: none
;³
;³
;³
;³  REGISTER
;³  USAGE:	 DX - loop index
;³		 SI - displacement into the list of pointers
;³		 CX - holder of pointer to keywords for compare
;³
;³
;³
;³  CONVENTIONS:
;³
;³
;³
;³
;³
;³
;³  ASSUMPTIONS: The list of con_keyword pointers is consecutive words.
;³		 number_of_keywords has the number of OFFSETS in the list
;³		 start_of_keyword_ptrs has the first OFFSET in the list and can
;³		 be addressed off of.
;³
;³
;³
;³  SIDE EFFECT: DL - lost
;³		 SI - lost
;³		 CX - lost
;³		 match_found - lost
;³
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

check_for_keyword   PROC  NEAR			      ;AN000;

MOV   match_found,false 			   ;AN000;
MOV   SI,0					      ;AN000;
MOV   DL,0			    ;AN000;;index for the loop
.WHILE <DL LT number_of_keywords> AND	 ;AN000;;check each pointer in the list
.WHILE <match_found EQ false> DO     ;AN000;
   MOV	 CX,start_of_keyword_ptrs[SI]	 ;AN000;
   .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ CX> THEN ;AN000;IF synonym ptr=CON keyword ptr THEN
       MOV   match_found,true			       ;AN000;
   .ENDIF		      ;AN000;
   INC	 SI	     ;AN000;					 ;AN000;
   INC	 SI		    ;AN000;				 ;AN000;
   INC	 DL			   ;AN000;;increment loop counter
.ENDWHILE	     ;AN000;

RET				   ;AN000;

check_for_keyword   ENDP	   ;AN000;

;-------------------------------------------------------------------------------

setup_invalid_parameter  PROC  NEAR	;AN000;

PUBLIC setup_invalid_parameter

MOV   message,OFFSET CRLF	 ;AN000;the common message doesn't have a CR,LF in it and all my other messages do
PUSH  parser_return_code_AX	 ;AC006;AX destroyed by sysdispmsg
display  message		 ;AN000;
POP   parser_return_code_AX


MOV   BP,command_line		;AN000;BP points to end of current (invalid) parm
.IF <<BYTE PTR [BP]> NE end_of_line_char_0D> AND    ;AN000;IF a whitespace char or comma in the string
.IF <<BYTE PTR [BP]> NE end_of_line_char_00> THEN   ;AN000;THEN
   DEC	 BP				     ;AN000;don't include the delimeter in the display of the invalid parm
.ENDIF
MOV   BYTE PTR [BP],0		;AN000;make the string an ASCIIZ

;offending_parameter is where the text of the bad parm is,
;offending_parameter_ptr is the address of offending_parameter By incrementing
;offending_parameter_ptr the first characters of the text string are skipped.
;This is done to skip leading whitespace.


MOV   BP,offending_parameter_ptr       ;AC006;BP=>first char in the text string
.WHILE <<BYTE PTR [BP]> EQ tab> OR	 ;AC006;WHILE the char in the text string
.WHILE <<BYTE PTR [BP]> EQ " "> DO       ;AC006;      is white space DO
   INC	 offending_parameter_ptr       ;AC006;point past the whitespace char
   INC	 BP			       ;AC006;index next char in the string
.ENDWHILE			       ;AC006;

.IF <parser_return_code_AX EQ syntax_error_rc> THEN   ;AN000;syntax error, like "RETRY= E"
   MOV	 message,OFFSET syntax_error			;AN000;
   PUSH  offending_parameter_ptr			  ;AN000;
   POP	 syntax_error_ptr				;AN000;point to the offending parameter
.ELSEIF <parser_return_code_AX EQ not_in_switch_list> THEN ;AN000;
   MOV	 message,OFFSET Invalid_switch
.ELSE
   MOV	 message,OFFSET Invalid_parameter ;AN000;user mispelled, misordered etc.
.ENDIF								;AN000;
MOV   noerror,false					 ;AN000;

RET

setup_invalid_parameter  ENDP		;AN000;

;-------------------------------------------------------------------------------

setup_for_not_supported    PROC  NEAR	  ;AC002;prepare replacable parm for "Function not supported on this machine - ????".

MOV   CX,offending_parameter_ptr;AN000;
MOV   not_supported_ptr,CX	;AN000;point to string describing what is not supported for message
MOV   BP,command_line		;AN000;BP points to end of current (invalid) parm
.IF <<BYTE PTR [BP]> NE end_of_line_char_0D> AND    ;AN000;IF a whitespace char or comma in the string
.IF <<BYTE PTR [BP]> NE end_of_line_char_00> THEN   ;AN000;THEN
   DEC	 BP				     ;AN000;don't include the delimeter in the display of the invalid parm
.ENDIF
MOV   BYTE PTR [BP],0		;AN000;make the string an ASCIIZ
MOV   message,OFFSET function_not_supported ;AN000;"Function not supported on the computer - mark"
MOV   noerror,false		;AN000;
MOV   looking_for,eol

RET

setup_for_not_supported    ENDP 	  ;AC002;


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³
;³ PARSE_PARAMETERS
;³ ----------------
;³
;³ All parameters entered on the command line are reduced to a list of values
;³ which completely describes the parms.  The syntactic and semantic correctness
;³ will be checked.  The routines that use the lists created by this routine
;³ can have complete trust in the validity of the parms.
;³
;³ Most of the states of looking_for allow null, even if it is not mentioned in
;³ the name of the value looking_for is assigned.
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³  INPUT: none, uses global variables.
;³
;³
;³  RETURN: noerror is set to false if an error is encountered.
;³
;³
;³  MESSAGES: "Invalid parameter  'bdprm'", where "bdprm" is the first 5 or less
;³	      characters of the parameter that is incorrect or unexpected.
;³
;³	      "Must specify COM1, COM2, COM3 or COM4"
;³
;³	      "Illegal device name"
;³
;³	      "Invalid baud rate specified"
;³
;³
;³
;³
;³  REGISTER
;³  USAGE:	 To be determined at I2 time.
;³
;³
;³  CONVENTIONS: "looking_for" indicates the valid possibilities for the next parm.
;³
;³		 "current_parm" refers to the parm just returned.  It can be an
;³			      item tag, a type.
;³
;³		 When "/STATUS" is a valid possibility it is checked for even
;³		 though the value of "looking_for" may not indicate it as a
;³		 choice.
;³
;³		 When possible the parser control blocks will be modified at
;³		 the case where looking_for is being checked for rather than
;³		 where looking_for was set.  This will save code when more than
;³		 one place sets looking_for to the same state.
;³
;³
;³
;³
;³  ASSUMPTIONS: The parser control blocks are setup to be the following:
;³		 seperators are defaults and colon (:)
;³		 match_flags=2011 (simple string, ignore colon, optional)
;³		 function_flags=0
;³		 keyword/switch list has only /STATUS
;³		 nval (number of value definitions) is 3
;³		 Initially no number choices.  Most numeric values will treated as strings.
;³		   This is because for most of them the numeric value doesn't
;³		   mean anything. Since we do not want to restrict the choices
;³		   code pages they cannot be enumerated, so a range will be used.
;³		 The list of strings in the values block contains all the
;³		   device names, all the screen modes, all the status qualifiers,
;³		   and all numeric values that have no meaning in binary form,
;³		   can be enumerated, or are non-integer.
;³
;³
;³  SIDE EFFECT:
;³
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

parse_parameters PROC		   ;AN000;

;determine if on a PS/2 for checking COMx parameters

.IF <machine_type EQ PS2Model30> OR		       ;AC002;
.IF <machine_type EQ PS2Model50> OR		       ;AC002;
.IF <machine_type EQ PS2Model60> OR		       ;AC002;
.IF <machine_type EQ PS2Model80> THEN  ;AC002;IF the machine is a PS/2 THEN
   MOV	 type_of_machine,PS2			       ;AC002;set flag
.ENDIF


MOV   looking_for,first_parm	 ;AN000;looking_for:=first_parm

.WHILE <eol_found NE true> AND NEAR    ;AN000;
.WHILE <noerror EQ true> NEAR DO ;AN000;WHILE (NOT EOL) AND noerror=true DO

;  CASE looking_for=

   ;calculate the displacement for the jump to appropriate case
   XOR	 AX,AX		   ;AN000;
   MOV	 AL,max_looking_for	 ;AN000;see the list of equates for looking_for
   SUB	 AL,looking_for        ;AN000;AX=byte displacement into table of OFFSETS
   SHL	 AX,1			;AN000;each displacement is 2 bytes
   MOV	 SI,AX			;AN000;SI=appropriate displacement into table of offsets
   JMP	 jump_table1[SI]	    ;AN000;jump to case

   jump_table1	  LABEL    WORD    ;AN000;    ;these entries must be in same order as the values in list of equates for looking_for

   DW OFFSET codepage_case		   ;AN000;
   DW OFFSET codepage_prms_case 	  ;AN000;
   DW OFFSET COM_keyword_case		   ;AN000;
   DW OFFSET com_keyword_or_baud_case	   ;AN000;
   DW OFFSET CON_keyword_case		     ;AN000;
   DW OFFSET con_kwrd_status_or_cp_case    ;AN000;
   DW OFFSET databits_or_null_case	   ;AN000;
   DW OFFSET device_name_or_eol_case	   ;AN000;
   DW OFFSET eol_case			   ;AN000;
   DW OFFSET first_parm_case		   ;AN000;
   DW OFFSET li_or_null_case		   ;AN000;
   DW OFFSET P_case			   ;AN000;
   DW OFFSET parity_or_null_case	   ;AN000;
   DW OFFSET prn_kw_status_cp_cl_null_case   ;AN000;
   DW OFFSET sd_or_dl_case		   ;AN000;
   DW OFFSET sd_or_dl_or_eol_case	   ;AN000;
   DW OFFSET status_or_eol_case 	   ;AN000;
   DW OFFSET stopbits_or_null_case	   ;AN000;
   DW OFFSET T_or_eol_case		   ;AN000;


      com_keyword_or_baud_case: 	     ;AN000;

PUBLIC	    com_keyword_or_baud_case

	 ;The com keywords are in "com_parmsx", as well as the values for the
	 ;positional and keyword forms of the com parameters.  If
	 ;keyword_switch_ptr comes back from parse_parm nonzero then a valid
	 ;com keyword or /STATUS was found.

	 CALL  parse_parm     ;AN000;/status allowed

	 ;CASE current_parm=


;	    /status:

		  .IF <parser_return_code_AX EQ no_error> AND					      ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_sta>> OR	   ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_stat>> OR   ;AC004;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_status>> THEN   ;AN000;

;	       MOV   slash_status,deleted	;AN000;make it so /status again is an error,also deletes /STA
;	       MOV   slash_stat,deleted 	;AN000;
;	       MOV   slash_sta,deleted		;AN000;
	       MOV   looking_for,eol		;AN000;eol only valid
	       MOV   request_type,com_status			     ;AN000;

	       BREAK  1 		  ;AN000;

		  .ENDIF		  ;AN000;


;	    eol:

		  .IF <parser_return_code_AX EQ end_of_command_line> THEN   ;AN000;

	       MOV   request_type,com_status			     ;AN000;
	       MOV   eol_found,true				      ;AN000;
	       BREAK 1						;AN000;

		  .ENDIF					;AN000;


;	    com_keyword:

		  .IF <parser_return_code_AX EQ no_error> AND					      ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr NE 0> THEN  ;AN000;wasn't /STATUS so must be a keyword

	       .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET baud_equal>> THEN	 ;AN000;IF synonym ptr=> BAUD= THEN
		  MOV	baud_specified,true			   ;AN000;
	       .ENDIF							;AN000;
	       delete_parser_value_list_entry keywords,current_parm ;AN000;
	       MOV   looking_for,com_keyword				;AN000;
	       MOV   parms_form,keyword 				;AN000;tell analyze_and_invoke how to look at the parms
	       BREAK 1							;AN000;

		  .ENDIF						;AN000;


;	    baud:    ;found a number that is a valid baud, know that have old com style com request



		  .IF <parser_return_code_AX EQ no_error> THEN	 ;AN000;IF have a baud rate THEN (none of above, must be baud rate)

	       .IF <parm_list[current_parm_DI].item_tag EQ nineteentwohundred_item_tag> THEN	;AC002;IF PS2 only baud rate AND
		  MOV	new_com_initialize,true
		  .IF <type_of_machine NE PS2> THEN						;AC002;not on PS/2
		     CALL  setup_for_not_supported  ;AC002;set up for "Function not supported on this computer" message
		  .ENDIF					;AN000;
	       .ENDIF						;AN008;
;AD008;        .ELSE
	       MOV   looking_for,parity_or_null 		;AN000;
	       MOV   request_type,initialize_com_port		  ;AN000;
;AD008;        .ENDIF
	       BREAK 1						;AN000;

		  .ELSE 		  ;AN000;


;	    otherwise:

	       CALL  setup_invalid_parameter		     ;AN000;
;	       BREAK 1

		  .ENDIF

	 ENDCASE_1:

	 BREAK 0			  ;AN000;



      com_keyword_case:

	 ;At this point the com keywords are in the keyword list, the only valid
	 ;parms that can follow are com keywords.  Assume that one and only one
	 ;com keyword has been found and removed from the list of keywords.

PUBLIC com_keyword_case

	 MOV   parms.parmsx_ptr,OFFSET com_keywords_parmsx ;AN000;only com keywords are in the control blocks
	 MOV   i_CL,1					   ;AN000;
	 .WHILE <i_CL LE number_of_com_keywords> AND NEAR  ;AN000;one iteration more than number of parms left so will find eol
	 .WHILE <eol_found EQ false> AND NEAR			      ;AN000;
	 .WHILE <noerror EQ true> DO NEAR			;AN000;

	    .SELECT		       ;AC002;check for PS/2 specific parms
	    .WHEN <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET baud_equal>> THEN	;AC002;IF synonym ptr=> BAUD= THEN
	       .IF <parm_list[current_parm_DI].item_tag EQ nineteentwohundred_item_tag> THEN	;AC002;IF PS2 only baud rate AND
		  MOV	new_com_initialize,true
		  .IF <type_of_machine NE PS2> THEN						;AC002;not on PS/2
		     CALL  setup_for_not_supported  ;AC002;set up for "Function not supported on this computer" message
		  .ENDIF
	       .ENDIF
	    .WHEN <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET parity_equal>> THEN   ;AC002;IF parity= THEN
	       .IF <parm_list[current_parm_DI].item_tag EQ mark_item_tag> OR	  ;AC002;IF PS2 only parity
	       .IF <parm_list[current_parm_DI].item_tag EQ space_item_tag> THEN    ;AC002;IF PS2 only parity AND
		  MOV	new_com_initialize,true
		  .IF <type_of_machine NE PS2> THEN						;AC002;not on PS/2
		     CALL  setup_for_not_supported  ;AC002;set up for "Function not supported on this computer" message
		  .ENDIF
	       .ENDIF
	    .WHEN <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET data_equal>> THEN	;AC002;IF data= THEN
	       .IF <parm_list[current_parm_DI].item_tag EQ five_item_tag> OR	  ;AC002;IF PS2 only data bits
	       .IF <parm_list[current_parm_DI].item_tag EQ six_item_tag> THEN	 ;AC002;IF PS2 only data bits AND
		  MOV	new_com_initialize,true
		  .IF <type_of_machine NE PS2> THEN						;AC002;not on PS/2
		     CALL  setup_for_not_supported  ;AC002;set up for "Function not supported on this computer" message
		  .ENDIF
	       .ENDIF
	    .WHEN <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET stop_equal>> THEN	;AC002;IF stop= THEN
	       .IF <parm_list[current_parm_DI].item_tag EQ one_point_five_item_tag> THEN    ;AC002;IF PS2 only stop bits AND
		  MOV	new_com_initialize,true
		  .IF <type_of_machine NE PS2> THEN						;AC002;not on PS/2
		     CALL  setup_for_not_supported  ;AC002;set up for "Function not supported on this computer" message
		  .ENDIF
	       .ENDIF
	    .ENDSELECT

	    PUSH  CX			     ;save the loop index
	    CALL  parse_parm					;AN000;
	    POP   CX

	    .IF <noerror EQ true> AND
	    .IF <parser_return_code_AX EQ no_error> THEN	;AN000;

	       .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET baud_equal>> THEN	 ;AN000;IF synonym ptr=> BAUD= THEN
		  MOV	baud_specified,true			   ;AN000;
	       .ENDIF							;AN000;
	       delete_parser_value_list_entry keywords,current_parm ;AN000;
	       INC   i_CL						;AN000;

	    .ELSEIF <parser_return_code_AX EQ end_of_command_line> THEN ;AN000;

	       .IF <baud_specified EQ true> THEN		;AN000;
		  MOV	request_type,initialize_com_port	     ;AN000;
	       .ELSE						     ;AN000;
		  MOV	message,OFFSET baud_rate_required		    ;AN000;
		  MOV	noerror,false
	       .ENDIF						     ;AN000;
	       MOV   eol_found,true			   ;AN000;

	    .ELSE NEAR			      ;AN000;

	       CALL  setup_invalid_parameter		     ;AN000;

	    .ENDIF					;AN000;

	 .ENDWHILE							;AN000;

	 MOV   looking_for,eol		 ;AN000;if haven't already encountered an error then check for extraneous parms

	 BREAK 0    ;AN000;com_keyword


      status_or_eol_case:

;     status_or_eol:	;Have found the only or the last status qualifier, must find /STATUS or eol_found NExt
			;Assume that /STATUS is the only switch in the appropriate parser control block
			;Assume that request_type has already been set

	 CALL  parse_parm		  ;AN000;

	 .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_sta>> OR		 ;AN000;
	 .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_stat>> OR	 ;AC004;
	 .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_status>> THEN   ;AN000;found /status

	    MOV   looking_for,eol			     ;AN000;

	 .ELSEIF <parser_return_code_AX EQ end_of_command_line> THEN ;AN000;encountered EOL

	    MOV   eol_found,true		;AN000;

	 .ELSE			;AN000;

	    CALL  setup_invalid_parameter      ;AN000;

	 .ENDIF

	 BREAK 0   ;status_or_eol			;AN000;



      parity_or_null_case:

PUBLIC	 parity_or_null_case

	 ;the parser control blocks have paritys as strings
	 ;modify parser control blocks list of valid paritys based on the
	 ;machine type.


	 CALL  parse_parm				;AN000;
	 .IF <parser_return_code_AX EQ operand_missing> THEN   ;AN000;valid null
	    MOV   looking_for,databits_or_null	    ;AN000;can't have baud,,eol
	 .ELSE						;AN000;
;	    CASE current_parm=


;	       eol:

		     .IF <parser_return_code_AX EQ end_of_command_line> THEN   ;AN000;valid

		  MOV	request_type,initialize_com_port
		  MOV	eol_found,true		   ;AN000;
		  BREAK 5		     ;AN000;

		     .ENDIF

;	       parity:

		     .IF <parser_return_code_AX EQ no_error> THEN    ;AN000;IF have a parity THEN (none of above, must be parity)

		  MOV	looking_for,databits_or_null			;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ mark_item_tag> OR     ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ space_item_tag> THEN   ;AN000;
		     MOV   new_com_initialize,true
		     .IF <type_of_machine NE PS2> THEN	;AN000;IF not Roundup or later
			CALL  setup_for_not_supported  ;AC002;set up for "Function not supported on this computer" message
		     .ENDIF				;AN000; 		    ;AN000;
		  .ENDIF				;AN000;

		     .ELSE

;	       otherwise:

		  CALL	setup_invalid_parameter       ;AN000;
;		  BREAK

		     .ENDIF						 ;AN000;

	    ENDCASE_5:		 ;current_parm

	 .ENDIF 							;AN000;
	 BREAK 0  ;AN000;parity_or_null




      databits_or_null_case:


PUBLIC	    databits_or_null_case

	 ;parser control blocks have all databits (as strings).
	 ;modify parser control blocks to handle list of valid databits
	 ;based on the machine type.

;AC002;  .IF <type_of_machine NE PS2> THEN  ;AN000;IF not Roundup or later
;AC002;     MOV   five_str,deleted     ;delete parser value list entry ;AN000;
;AC002;     MOV   six_str,deleted	   ;delete_parser_value_list_entry ;AN000;
;AC002;  .ENDIF 							;AN000;

	 ;the parser control blocks have data bits valid for this machine
	 CALL  parse_parm					;AN000;
	 .IF <parser_return_code_AX EQ operand_missing> THEN   ;AN000;valid null
	    MOV   looking_for,stopbits_or_null		  ;can't have databits,,eol
	 .ELSE								;AN000;
;	    CASE current_parm=


;	       eol:

		     .IF <parser_return_code_AX EQ end_of_command_line> THEN   ;AN000;valid

		  MOV	request_type,initialize_com_port		;AN000;
		  MOV	eol_found,true			      ;AN000;
		  BREAK 6						;AN000;

		     .ENDIF						;AN000;


;	       databits:

		     .IF <parser_return_code_AX EQ no_error> THEN    ;AN000;IF have a parity THEN (none of above, must be parity)

		  MOV	looking_for,stopbits_or_null			;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ five_item_tag> OR      ;AC002;
		  .IF <parm_list[current_parm_DI].item_tag EQ six_item_tag> THEN    ;AC002;
		     MOV   new_com_initialize,true
		     .IF <type_of_machine NE PS2> THEN	;AC002;IF not Roundup or later
			CALL  setup_for_not_supported  ;AC002;set up for "Function not supported on this computer" message
		     .ENDIF				;AC002; 		    ;AN000;
		  .ENDIF				;AC002;
;		  BREAK 6						;AN000;

		     .ELSE					       ;AN000;


;	       otherwise:

		  CALL	setup_invalid_parameter       ;AN000;
;		  BREAK

		     .ENDIF

	    ENDCASE_6: ;current_parm

	 .ENDIF 							;AN000;
	 BREAK 0  ;AN000;databits_or_null



      stopbits_or_null_case:


PUBLIC	    stopbits_or_null_case

	 ;parser control blocks have all stopbits (as strings).
	 ;modify parser control blocks to handle list of valid stopbits
	 ;based on the machine type.

;AC002;  .IF <type_of_machine NE PS2> THEN  ;AN000;IF not Roundup or later
;AC002;     MOV   one_point_five_str,deleted   ;delete_parser_value_list_entry	;AN000;
;AC002;  .ENDIF 							;AN000;


	 CALL  parse_parm						;AN000;
	 .IF <parser_return_code_AX EQ operand_missing> THEN   ;AN000;valid null
	    MOV   looking_for,P 		;AN000;no null just before eol
	 .ELSE					;AN000;
;	    CASE current_parm=


;	       eol:

		     .IF <parser_return_code_AX EQ end_of_command_line> THEN   ;AN000;valid

		  MOV	BYTE PTR request_type,initialize_com_port	 ;AN000;
		  MOV	eol_found,true			      ;AN000;
		  BREAK 7				;AN000;

		     .ENDIF


;	       stopbits:


		     .IF <parser_return_code_AX EQ no_error> THEN    ;AN000;IF have a parity THEN (none of above, must be parity)

		  MOV	looking_for,P		  ;AN000;P or eol valid next
		  .IF <parm_list[current_parm_DI].item_tag EQ one_point_five_item_tag> THEN    ;AC002;
		     MOV   new_com_initialize,true
		     .IF <type_of_machine NE PS2> THEN	;AC002;IF not Roundup or later
			CALL  setup_for_not_supported  ;AC002;set up for "Function not supported on this computer" message
		     .ENDIF				;AC002; 		    ;AN000;
		  .ENDIF				;AC002;

		     .ELSE


;	       otherwise:

		  CALL	setup_invalid_parameter       ;AN000;
;		  BREAK

		     .ENDIF

	    ENDCASE_7: ;current_parm

	 .ENDIF 					;AN000;
	 BREAK 0 ;AN000;stopbits_or_null




      P_case:		;P or eol valid


PUBLIC P_case

	 ;P is in the parser control blocks' list of strings.

	 CALL parse_parm						;AN000;
;	 CASE current_parm=





;	    eol:

		  .IF <parser_return_code_AX EQ end_of_command_line> THEN   ;AN000;valid

	       MOV   eol_found,true		   ;AN000;
	       BREAK 8			     ;AN000;

		  .ENDIF



;	    P:

		  .IF <parser_return_code_AX EQ no_error> THEN	 ;AN000;found one of: p,e,b,r,n,none,off

	       MOV   looking_for,eol	  ;AN000;found last positional
	       MOV   retry_requested,true

		  .ELSE


;	    otherwise:

	       CALL  setup_invalid_parameter	   ;AN000;

		  .ENDIF


	 ENDCASE_8: ;current_parm

	 BREAK 0  ;AN000;P



;m
      prn_kw_status_cp_cl_null_case:

      PUBLIC   prn_kw_status_cp_cl_null_case

      ;Have encountered only LPTX so far, so any printer stuff including codepage
      ;requests can follow. All necessary keywords and switches are in the control blocks.


	 CALL  parse_parm				       ;AN000;

;	 CASE current_parm=

;	    LPT_mode_keyword:		   ;nothing but printer keywords allowed


		  .IF <parser_return_code_AX EQ no_error> AND NEAR				      ;AN000;
;		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET COLUMNS_equal>> OR   ;AN000;
;		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET COLS_equal>> OR   ;AN000;
;		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET lines_equal>> OR  ;AN000;
;		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET retry_equal_str>> THEN ;AN000;found a printer keyword


		  check_for_lpt_keyword      ;check for COLS= or LINES= or RETRY=, return results in match_found
		  .IF <match_found EQ true> THEN NEAR

	       delete_parser_value_list_entry keywords,current_parm  ;AN000;
	       MOV   parms_form,keyword 		;AN000;indicate to modeprin how to deal with retry
	       CALL  parse_parm 			     ;AN000;
	       MOV   DL,1			;AN000;one keyword found so far

	       .REPEAT

;		  CASE return_code=

;		     LPT_keyword:


			   .IF <parser_return_code_AX EQ no_error> AND					       ;AN000;
			   PUSH  DX			;save loop index
			   check_for_lpt_keyword      ;return results in match_found
			   POP	 DX
			   .IF <match_found EQ true> THEN

			.IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET retry_equal_str>> AND
			.IF <parm_list[current_parm_DI].item_tag NE NONE_item_tag> THEN
			   MOV	 retry_requested,true	;set up for rescode
			.ENDIF
			delete_parser_value_list_entry keywords,current_parm  ;AN000;
			INC   DL		;AN000;found another keyword
			BREAK 9 		;AN000;

			   .ENDIF


;		     eol:

			   .IF <parser_return_code_AX EQ end_of_command_line> THEN   ;AN000;valid

			;had at least one keyword
			MOV   request_type,initialize_printer_port     ;AN000;
			MOV   eol_found,true			      ;AN000;
			BREAK 9 				;AN000;

			   .ENDIF


;		     otherwise:     ;wrong type of keywords, /STATUS etc.

			CALL  setup_invalid_parameter	    ;AN000;
;			BREAK

		  ENDCASE_9:

		  PUSH	DX
		  CALL	parse_parm				;AN000;
		  POP	DX

	       .UNTIL <DL EQ number_of_LPT_keywords> OR 	     ;AN000;
	       .UNTIL <eol_found EQ true> OR				      ;AN000;
	       .UNTIL <noerror EQ false>				;AN000;

;	       .IF <eol_found NE true> AND
	       .IF <noerror EQ true> AND				;AN000;
	       .IF <DL EQ number_of_LPT_keywords> THEN		    ;AN000;
		  MOV	looking_for,eol 	  ;AN000;check for extraneous parms
	       .ENDIF						;AN000;

	       BREAK 10

		  .ENDIF   ;AN000;LPT_keyword


;	    /STATUS:

		  .IF <parser_return_code_AX EQ no_error> AND		;make sure don't have /STA:value  ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_sta>> OR	 ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_stat>> OR   ;AC004;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_status>> THEN  ;AN000;found /STATUS

	       MOV   looking_for,eol  ;AN000;look for RETRY or codepage
	       MOV   slash_status,deleted				;AN000;
	       MOV   slash_stat,deleted 				;AN000;
	       MOV   slash_sta,deleted					;AN000;
	       MOV   request_type,printer_status			;AN000;
	       BREAK 10 ;AN000;keyword

		  .ENDIF   ;/STATUS found				;AN000;


;	    codepage:


		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ 0> AND		  ;AC007;wasn't SEL=cpnum or PREP=cpnum
		  .IF <parm_list[current_parm_DI].item_tag EQ codepage_item_tag> THEN	  ;AN000;IF found "codepage" or "cp" THEN

	       MOV   looking_for,codepage_prms				;AN000;
	       MOV   codepage_str,deleted				;AN000;
	       MOV   code_str,deleted					;AN000;
	       MOV   cp_str,deleted					;AC007;
	       BREAK 10 ;AN000;

		  .ENDIF						;AN000;



;	    cl:

		  .IF <parm_list[current_parm_DI].item_tag EQ onethirtytwo_item_tag> OR ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ eighty_item_tag> THEN ;AN000;

	       MOV   REFRESH_str,deleted			;AC007;no codepage stuff legal
	       MOV   REF_str,deleted				;AC007;
	       MOV   SEL_equal,deleted				;AN007;
	       MOV   SELECT_equal,deleted			;AN007;
	       MOV   PREP_equal,deleted 			;AN007;
	       MOV   PREPARE_equal,deleted			;AN007;
	       MOV   slash_status,deleted				;AN007;
	       MOV   slash_stat,deleted 				;AN007;
	       MOV   slash_sta,deleted					;AN007;
	       MOV   looking_for,li_or_null				;AN000;
	       MOV   request_type,old_initialize_printer_port		;AN000;found enough to know that it isn't status or keyword
	       BREAK 10 						;AN000;

		  .ENDIF						;AN000;



;	    eol:


		  .IF <parser_return_code_AX EQ end_of_command_line> THEN   ;AN000;valid

	       MOV   request_type,turn_off_reroute ;compatible with previous MODE     ;AN000;
	       MOV   eol_found,true		   ;AN000;
	       BREAK 10 						;AN000;

		  .ENDIF						;AN000;



;	    codepage_keyword_out_of_order:


		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET PREPARE_equal>> OR  ;AC007;if got here and have
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET PREP_equal>> OR 	;AC007;one of the codepage
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET SEL_equal>> OR		;AC007;keywords then user
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET SELECT_equal>> THEN	;AC007;forgot "CP"

	       MOV   message,OFFSET Invalid_number_of_parameters				  ;AC007;
	       MOV   noerror,false								  ;AC007;
	       BREAK 10  ;AN000;CON_keyword

		  .ENDIF



;	    REFRESH_out_of_order:   ;AC007;forgot to include "CP"


		  .IF <parm_list[current_parm_DI].item_tag EQ REFRESH_item_tag> THEN  ;AC007;

	       MOV   message,OFFSET Invalid_number_of_parameters				  ;AC007;
	       MOV   noerror,false								  ;AC007;
	       BREAK 10

		  .ENDIF						;AC007;



;	    null:

		  .IF <parser_return_code_AX EQ no_error> AND	 ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ unspecified> THEN   ;AN007;valid null

	       MOV   REFRESH_str,deleted			;AC007;no codepage stuff legal
	       MOV   REF_str,deleted				;AC007;
	       MOV   SEL_equal,deleted				;AN007;
	       MOV   SELECT_equal,deleted			;AN007;
	       MOV   PREP_equal,deleted 			;AN007;
	       MOV   PREPARE_equal,deleted			;AN007;
	       MOV   slash_status,deleted				;AN007;
	       MOV   slash_stat,deleted 				;AN007;
	       MOV   slash_sta,deleted					;AN007;
	       MOV   looking_for,li_or_null				;AN000;
	       MOV   request_type,old_initialize_printer_port		;AN000;found enough to know that it isn't status or keyword



;	    otherwise:

		  .ELSE 						;AN000;

	       CALL  setup_invalid_parameter	   ;AN000;
;	       BREAK							;AN000;

		  .ENDIF						;AN000;


	 ENDCASE_10: ;current_parm=					;AN000;
	 BREAK 0   ;AN000;prn_kw_status_cp_cl_null_case:




      li_or_null_case:			     ;look for lines per inch or null, eol valid

PUBLIC li_or_null_case


	 CALL  parse_parm		     ;AN000;
;	 CASE current_parm=

;	    li:

		  .IF <parm_list[current_parm_DI].item_tag EQ six_item_tag> OR	       ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ eight_item_tag> THEN     ;AN000;IF found 6 or 8 THEN

	       MOV   looking_for,P					;AN000;
	       BREAK 11

		  .ENDIF


;	    eol:

		  .IF <parser_return_code_AX EQ end_of_command_line> THEN   ;AN000;valid

	       MOV   request_type,old_initialize_printer_port		    ;AN000;
	       MOV   eol_found,true			      ;AN000;
	       BREAK 11 						;AN000;

		  .ENDIF


;	    null:

		  .IF <parser_return_code_AX EQ no_error> AND	 ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ unspecified> THEN   ;AN007;valid null

	       MOV   looking_for,P				     ;AN000;
	       BREAK 11 						;AN000;

		  .ENDIF


;	    otherwise:

	       CALL  setup_invalid_parameter	   ;AN000;
;	       BREAK


	 ENDCASE_11:  ;current_parm				;AN000;
	 BREAK 0   ;AN000;li_or_null


;m
      codepage_prms_case:


	 ;The desired codepage parameters are in the parser control blocks, such
	 ;as: the keywords, PREPARE, REFRESH, and /STATUS.
	 CALL  parse_parm						;AN000;
;	 CASE current_parm=


;	    REFRESH:

		  .IF <parm_list[current_parm_DI].item_tag EQ REFRESH_item_tag> THEN  ;AN000;

	       MOV   request_type,codepage_refresh		       ;AN000;
	       MOV   looking_for,eol
	       BREAK 12

		  .ENDIF


;	    PREPARE=:


	       ;Have to parse ((cplist) [filename])

		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET PREPARE_equal>> OR  ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET PREP_equal>> THEN NEAR	;AN000;IF PREPARE= THEN

	       .IF <parm_list[current_parm_DI].parm_type EQ complx> THEN NEAR  ;AN000;should have found ((cplist) filename)
		  PUSH	SI  ;AN000;save pointer to first char past the closing right paren
		  MOV	AX,parm_list[current_parm_DI].value1	;AN000;
		  MOV	command_line,AX 			;AN000;point at first char past the left paren
		  SUB	DI,TYPE parm_list_entry 		;AN000;not parm, just indication of complex, delete from parm list
		  MOV	parms.parmsx_ptr,OFFSET prepare_equal_parmsx
		  MOV	prepare_equal_match_flags,complex     ;AN000;only thing valid next
		  CALL	parse_parm		;AN000;
		  .IF <parser_return_code_AX EQ no_error> AND		;AN000;
		  .IF <parm_list[current_parm_DI].parm_type EQ complx> THEN	  ;AN000;assume have ((cplist) filename)
		     PUSH  SI  ;AN000;save pointer to first char past the closing right paren
		     MOV   AX,parm_list[current_parm_DI].value1    ;AN000;
		     MOV   command_line,AX			   ;AN000;point at first char past the left paren
		     SUB   DI,TYPE parm_list_entry		;AN000;not parm, just indication of complex, delete from parm list
		     MOV   prepare_equal_match_flags,numeric+optional ;AN000;number or delimeter only things valid next
		     MOV   ordinal,0		     ;AN000;zap parms count,make parser count codepage numbers
		     .REPEAT			   ;AN000;
			CALL  parse_parm	   ;AN000;
			.IF <parser_return_code_AX EQ no_error> THEN	;AN000;  ;AN000;
			   ADD	 des_start_packet.des_strt_pklen,2     ;increment size of parm block for another cp number
			   INC	 des_start_packet.des_strt_pknum       ;increment number of cp numbers
			   ADD	 current_packet_cp_number,2	       ;address next code page number slot
			   MOV	 SI,current_packet_cp_number
			   MOV	 BP,OFFSET des_start_packet
			   .IF <parm_list[current_parm_DI].item_tag EQ codepage_item_tag> THEN	;AN000;IF not skipped slot THEN
			      MOV   DX,parm_list[current_parm_DI].value1  ;AN000;store the number if one specified for this slot
			      MOV   [SI][BP].des_strt_pkcp1,DX		  ;put the number in the slot for the cp number
			   .ENDIF   ;AN000;not valid skipped codepage number, i.e. not (,850,,865) for example
			.ELSEIF <parser_return_code_AX EQ end_of_complex> THEN ;AN000;
			   SUB	 DI,TYPE parm_list_entry	;don't want an entry in the parm list for the zeroed out ")"
			.ELSE
			   CALL  setup_invalid_parameter       ;AN000;
			.ENDIF				;AN000;
		     .UNTIL <parser_return_code_AX EQ end_of_complex> OR ;AN000;came to end of the cplist
		     .UNTIL <noerror EQ false>
		     POP   command_line      ;AN000;resume just after the closing paren of (cplist), should be at ) or filename
		  .ELSE    ;AN000;must be an error
		     MOV   message,OFFSET invalid_number_of_parameters	       ;AN000;
		     MOV   noerror,false				;AN000;
		  .ENDIF
		  .IF <noerror EQ true> THEN	;AN000;IF successfully broke down cplist and file name THEN
		     MOV   prepare_equal_match_flags,filespec+optional ;AN000;only thing valid is filespec
		     MOV   ordinal,0					;AN000;don't need parser to count the parms anymore
		     MOV   prepare_min_parms,0			;AN000;filename is optional
;		     A filespec may be next so colon cannot be a delimeter.
		     modify_parser_control_block seperator_list,delete,colon  ;AN000;want to find a keyword so don't stop on colons
		     CALL  parse_parm					   ;AN000;
		     .IF <parser_return_code_AX EQ no_error> THEN	   ;AN000;
			MOV   AX,parm_list[current_parm_DI].value1	   ;AN000;AX=OFFSET of filespec just encountered
			MOV   cp_cb.font_filespec,AX		   ;AN000;set up pointer to filespec for modecp
		     .ELSEIF <parser_return_code_AX EQ end_of_complex> THEN  ;AN000;cartridge prepare, no filename
			MOV   des_start_packet.des_strt_pkfl,DES_STRT_FL_CART	  ; 0001H=CARTRIDGE PREPARE,
		     .ELSE						   ;AN000;
			CALL  setup_invalid_parameter	    ;AN000;
		     .ENDIF					;AN000;
		     MOV   request_type,codepage_prepare		;AN000;if encountered an error won't continue anyways
		  .ENDIF						;AN000;
		  POP	command_line	     ;AN000;continue parsing after the origional complex, should be eol
	       .ELSE							;AN000;
		  MOV	message,OFFSET invalid_number_of_parameters ;AN000;should have found a complex
		  MOV	noerror,false					;AN000;
	       .ENDIF

	       MOV   looking_for,eol	  ;AN000;

	       BREAK 12 						;AN000;

		  .ENDIF


;	    SELECT=:


dummy1:
PUBLIC DUMMY1
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET SEL_equal>> OR	;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET SELECT_equal>> THEN ;AN000;

	       .IF <parser_return_code_AX EQ no_error> THEN		;AN000;
		  MOV	codepage_index_holder,current_parm_DI		;AN000;save index of the codepage parm list entry for invoke
		  MOV	request_type,codepage_select			;AN000;
		  MOV	looking_for,eol 				;AN000;
	       .ELSE							;AN000;
		  CALL	setup_invalid_parameter       ;AN000;
	       .ENDIF

	       BREAK 12 						;AN000;

		  .ENDIF



;	    /STATUS:


		  .IF <parser_return_code_AX EQ no_error> AND		;make sure don't have /STA:value  ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_STA>> OR	;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_stat>> OR   ;AC002;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_STATUS>> THEN ;AN000;

	       MOV   request_type,codepage_status		;AN000;
;AX322;        .IF   <device_name EQ <OFFSET CON_str>> THEN
		  MOV	looking_for,eol 			;AC322;
;AX322;        .ELSE
;AX322; 	  MOV	looking_for,eol 			;AN000;
;AX322;        .ENDIF
	       BREAK 12 					;AN000;

		  .ENDIF


;	    eol:

		  .IF <parser_return_code_AX EQ end_of_command_line> THEN ;AN000;

	       MOV   request_type,codepage_status			;AN000;
	       MOV   eol_found,true		   ;AN000;
	       BREAK 12 						;AN000;

		  .ENDIF


;	    otherwise:

	       CALL  setup_invalid_parameter	   ;AN000;
;	       BREAK


	 ENDCASE_12: ;current_parm=


	 BREAK 0							;AN000;




      codepage_case:	   ;found PRN, only valid parms are CODEPAGE, and /STATUS
			   ;/STATUS is in the the parser control blocks

	 CALL  parse_parm						;AN000;
;	 CASE current_parm=

;	    CODEPAGE:

		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ 0> AND		  ;AC007;wasn't SEL=cpnum or PREP=cpnum
		  .IF <parm_list[current_parm_DI].item_tag EQ codepage_item_tag> THEN	  ;AN000;IF found "codepage" or "cp" THEN

	       ;set up for codepage_prms_case
;	       modify_parser_control_block keywords,addd,codepage_keywords  ;AN000;codepage parms handler assumes keywords setup
	       MOV   looking_for,codepage_prms			       ;AN000;
	       BREAK 13 						;AN000;

		  .ENDIF


;	    /STATUS:	   ;only CODEPAGE or end of line valid next

		  .IF <parser_return_code_AX EQ no_error> AND		;make sure don't have /STA:value  ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_STA>> OR	;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_stat>> OR   ;AC004;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_STATUS>> THEN ;AN000;

	       CALL  parse_parm 					;AN000;
	       .IF <parm_list[current_parm_DI].item_tag EQ codepage_item_tag> THEN  ;AN000;
		  MOV	looking_for,eol ;AN000;
		  MOV	status_request,true
		  MOV	request_type,codepage_status	;AN000;
	       .ELSEIF <parser_return_code_AX EQ end_of_command_line> THEN   ;AN000;
		  MOV	eol_found,true					;AC005;
		  MOV	status_request,true				;AC005;
		  MOV	request_type,codepage_status	;AC005;
	       .ELSE						;AN000;
		  CALL	setup_invalid_parameter       ;AN000;
	       .ENDIF
	       BREAK 13 						;AN000;

		  .ENDIF


;	    eol:

		  .IF <parser_return_code_AX EQ end_of_command_line> THEN ;AN000;

	       MOV   request_type,codepage_status			;AN000;
	       MOV   eol_found,true		   ;AN000;
	       BREAK 13 					;AN000;

		  .ENDIF



;	    codepage_keyword_out_of_order:


		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET PREPARE_equal>> OR  ;AC007;if got here and have
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET PREP_equal>> OR 	;AC007;one of the codepage
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET SEL_equal>> OR		;AC007;keywords then user
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET SELECT_equal>> THEN	;AC007;forgot "CP"

	       MOV   message,OFFSET Invalid_number_of_parameters				  ;AC007;
	       MOV   noerror,false								  ;AC007;
	       BREAK 13  ;AN000;CON_keyword

		  .ENDIF



;	    REFRESH_out_of_order:   ;AC007;forgot to include "CP"


		  .IF <parm_list[current_parm_DI].item_tag EQ REFRESH_item_tag> THEN  ;AC007;

	       MOV   message,OFFSET Invalid_number_of_parameters				  ;AC007;
	       MOV   noerror,false								  ;AC007;
;	       BREAK 13

		  .ELSE 					;AC007;



;	    otherwise:

	       CALL  setup_invalid_parameter	   ;AN000;
;	       BREAK

		  .ENDIF						;AC007;

	 ENDCASE_13:

	 BREAK 0  ;AN000;



      con_kwrd_status_or_cp_case:

      PUBLIC   con_kwrd_status_or_cp_case

	 MOV   parms.parmsx_ptr,OFFSET con_parmsx
	 CALL  parse_parm					;AN000;

;	 CASE current_parm=



;	    codepage:

		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ 0> AND		  ;AC007;wasn't SEL=cpnum or PREP=cpnum
		  .IF <parm_list[current_parm_DI].item_tag EQ codepage_item_tag> THEN	  ;AN000;IF found "codepage" or "cp" THEN

	       MOV   looking_for,codepage_prms			       ;AN000;
	       BREAK 14 					;AN000;

		  .ENDIF


;	    eol:

		  .IF <parser_return_code_AX EQ end_of_command_line> THEN   ;AN000;

	       MOV   request_type,all_con_status	;AN000;found only CON on the command line
	       MOV   eol_found,true		;AN000;
	       BREAK 14 				;AN000;

		  .ENDIF



;	    /STATUS:

		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_STA>> OR	;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_stat>> OR   ;AC004;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_STATUS>> THEN ;AN000;

	       MOV   slash_status,deleted  ;AN000;
	       MOV   slash_stat,deleted 	;AN000;
	       MOV   slash_sta,deleted	;AN000;
	       MOV   request_type,all_con_status	;AN000;found only CON on the command line
	       MOV   looking_for,eol			;AC665;have MODE CON /STATUS, must find eol now
	       BREAK 14 					;AN000;

		  .ENDIF



;	    con_keyword:


		  .IF <parser_return_code_AX EQ no_error> AND		;make sure invalid value not specified ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr NE 0> THEN  ;not pointing to /sta, not 0, must be a keyword

	       .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET rate_equal>> OR				   ;AN000;
	       .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET del_equal>> OR				   ;AN000;
	       .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET delay_equal>> THEN 			   ;AN000;
		  INC	rate_and_delay_found		;found one, needs to be 2 before valid;AN000;
	       .ELSEIF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET PREPARE_equal>> OR  ;AC007;if got here and have
	       .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET PREP_equal>> OR	     ;AC007;one of the codepage
	       .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET SEL_equal>> OR	     ;AC007;keywords then user
	       .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET SELECT_equal>> THEN     ;AC007;forgot "CP"
		  MOV	message,OFFSET Invalid_number_of_parameters				     ;AC007;
		  MOV	noerror,false								     ;AC007;
	       .ELSE
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr NE <OFFSET COLUMNS_equal>> AND  ;AC007;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr NE <OFFSET COLS_equal>> AND  ;AC007;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr NE <OFFSET lines_equal>> THEN ;AC007;
		     CALL  setup_invalid_parameter	 ;AC007;keyword other than LINES=, COLS=, RATE= or DELAY= would require CP
		  .ENDIF				 ;AC007;and be handled above
	       .ENDIF													   ;AN000;
	       delete_parser_value_list_entry keywords,current_parm ;AN000;doesn't affect anything if invalid parm
	       MOV   looking_for,CON_keyword				;AN000;doesn't affect anything if invalid parm
	       BREAK 14  ;AN000;CON_keyword

		  .ENDIF



;	    REFRESH:		    ;AC007;forgot to include "CP"


		  .IF <parm_list[current_parm_DI].item_tag EQ REFRESH_item_tag> THEN  ;AC007;

	       MOV   message,OFFSET Invalid_number_of_parameters				  ;AC007;
	       MOV   noerror,false								  ;AC007;
;	       BREAK

		  .ELSE 				;AC007;



;	    otherwise:

	       CALL  setup_invalid_parameter	   ;AN000;
;	       BREAK

		  .ENDIF				;AC007;



	 ENDCASE_14:
	 BREAK 0   ;AN000;con_kwrd_status_or_cp_case:




      con_keyword_case: 	 ;found one, it has been deleted from the parser control blocks
      PUBLIC con_keyword_case

	 MOV   slash_status,deleted  ;AN000;remove /STA /STAT and STATUS
	 MOV   slash_stat,deleted	  ;AN000;
	 MOV   slash_sta,deleted  ;AN000;

	 MOV   i_CL,1					   ;AN000;
	 .WHILE <i_CL LT number_of_con_keywords> AND	   ;AN000;
	 .WHILE <eol_found EQ false> AND			      ;AN000;
	 .WHILE <noerror EQ true> DO				;AN000;
	    PUSH  CX

	    CALL  parse_parm					;AN000;

;	    CASE return_code=

;	       con_keyword:

		     .IF <parser_return_code_AX EQ no_error> AND	   ;make sure don't have /STA:value  ;AN000;
		     .IF <parm_list[current_parm_DI].keyword_switch_ptr NE 0> THEN  ;not 0, must be a keyword		   ;AN000;

		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET rate_equal>> OR 			   ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET del_equal>> OR				   ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET delay_equal>> THEN			   ;AN000;
		     INC   rate_and_delay_found 	   ;found one, needs to be 2 before valid;AN000;
		  .ENDIF
		  delete_parser_value_list_entry keywords,current_parm ;AN000;
		  INC	i_CL						   ;AN000;
		  BREAK 15						;AN000;

		     .ENDIF						   ;AN000;


;	       eol:

		     .IF <parser_return_code_AX EQ end_of_command_line> THEN ;AN000;

		  .IF <rate_and_delay_found EQ both> OR 		;IF both OR neither found THEN
		  .IF <rate_and_delay_found EQ false> THEN
		     MOV   request_type,set_con_features		   ;AN000;
		     MOV   eol_found,true		     ;AN000;
		  .ELSE
		     MOV   message,OFFSET rate_and_delay_together	;RATE and DELAY must be specified together
		     MOV   noerror,false
		  .ENDIF
		  BREAK 15						;AN000;

		     .ENDIF


;	       otherwise:

		  CALL	setup_invalid_parameter       ;AN000;
;		  BREAK

	    ENDCASE_15:

	    POP   CX

	 .ENDWHILE			  ;AN000;

	 MOV   looking_for,eol		 ;AN000;check for extraneous parms

	 BREAK 0 ;AN000;CON_keyword




      sd_or_dl_or_eol_case:

PUBLIC sd_or_dl_or_eol_case

	 ;have found a screen mode, now may find sd, dl, or eol

	 CALL	parse_parm						;AN000;
;	 CASE current_parm=

;	    sd: 		       ;found R or L

		  .IF <parm_list[current_parm_DI].item_tag EQ L_item_tag> OR   ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ R_item_tag> THEN ;AN000;

	       MOV   looking_for,T_or_EOL			;AN000;request_type already set
	       BREAK 17 					;AN000;

		  .ENDIF

;	    dl:

		  .IF <parm_list[current_parm_DI].item_tag EQ fourtythree_item_tag> OR ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ fifty_item_tag> OR   ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ twentyfive_item_tag> THEN ;AN000;

	       MOV   looking_for,eol		;AN000;request_type already set
	       BREAK 17 					;AN000;

		  .ENDIF



;	    eol:

		  .IF <parser_return_code_AX EQ end_of_command_line> THEN ;AN000;

	       MOV   eol_found,true		      ;AN000;request_type already set
	       BREAK 17 						;AN000;

		  .ENDIF


;	    otherwise:	   regardless of what follows must have a parm here, didn't so yell

	       .IF <parser_return_code_AX EQ operand_missing> THEN	;AN000;two commas with nothing in between
		  MOV	message,OFFSET Invalid_number_of_parameters   ;AN000;
		  MOV	noerror,false					;AN000;
	       .ELSE							;AN000;
		  CALL	setup_invalid_parameter 		      ;AN000;some bogus value or string
	       .ENDIF							;AN000;

;	       BREAK


	 ENDCASE_17:
	 BREAK 0  ;AN000;sd_or_dl_or_null



      sd_or_dl_case:

PUBLIC sd_or_dl_case

	 ;have no first parm, now must find shift direction or screen lines


	 CALL	parse_parm						;AN000;
;	 CASE current_parm=

;	    sd:

		  .IF <parm_list[current_parm_DI].item_tag EQ L_item_tag> OR   ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ R_item_tag> THEN ;AN000;

	       MOV   looking_for,T_or_EOL				;AN000;
	       MOV   request_type,old_video_mode_set		       ;AN000;
	       BREAK 18 						;AN000;

		  .ENDIF


;	    dl:

		  .IF <parm_list[current_parm_DI].item_tag EQ fourtythree_item_tag> OR ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ fifty_item_tag> OR   ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ twentyfive_item_tag> THEN ;AN000;

	       MOV   request_type,old_video_mode_set	 ;AN000;
	       MOV   looking_for,eol		      ;AN000;
	       BREAK 18 						;AN000;

		  .ENDIF



;	    eol:

		  .IF <parser_return_code_AX EQ end_of_command_line> THEN ;AN000;

	       MOV   message,OFFSET invalid_number_of_parameters	       ;AN000;
	       MOV   noerror,false					;AN000;
	       MOV   eol_found,true			      ;AN000;
	       BREAK 18 						;AN000;

		  .ENDIF


;	    otherwise:

	       .IF <parser_return_code_AX EQ operand_missing> THEN	;AN000;two commas with nothing in between
		  MOV	message,OFFSET Invalid_number_of_parameters   ;AN000;
		  MOV	noerror,false					;AN000;
	       .ELSE							;AN000;
		  CALL	setup_invalid_parameter 		      ;AN000;some bogus value or string
	       .ENDIF							;AN000;
;	       BREAK

	 ENDCASE_18:
	 BREAK 0   ;AN000;sd_or_dl



      T_or_EOL_case:


	 CALL  parse_parm					;AN000;

;	 CASE current_parm=

;	    T:

		  .IF <parm_list[current_parm_DI].item_tag EQ T_item_tag> THEN ;AN000;

	       MOV   looking_for,eol	  ;AN000;request_type already set
	       BREAK 19 					;AN000;

		  .ENDIF

;	    eol:

		  .IF <parser_return_code_AX EQ end_of_command_line> THEN ;AN000;

	       MOV   eol_found,true		;AN000;request_type already set
	       BREAK 19 					;AN000;

		  .ENDIF


;	    otherwise:

	       CALL  setup_invalid_parameter	   ;AN000;
;	       BREAK

	 ENDCASE_19:
	 BREAK 0	      ;AN000;



      device_name_or_eol_case:	      ;have only /status so far

	 ;The device names are in the parser control blocks

	 CALL	parse_parm
;	 CASE current_parm=

;	    COM?:

		  MOV  device_name,OFFSET COM1_str				  ;AC001;
		  .IF <parm_list[current_parm_DI].item_tag EQ COM1_item_tag> OR   ;AN000;
		  MOV  device_name,OFFSET COM2_str				  ;AC001;
		  .IF <parm_list[current_parm_DI].item_tag EQ COM2_item_tag> OR   ;AN000;
		  MOV  device_name,OFFSET COM3_str				  ;AC001;
		  .IF <parm_list[current_parm_DI].item_tag EQ COM3_item_tag> OR   ;AN000;
		  MOV  device_name,OFFSET COM4_str				  ;AC001;
		  .IF <parm_list[current_parm_DI].item_tag EQ COM4_item_tag> THEN ;AN000;

	       MOV   looking_for,eol				     ;AN000;
	       MOV   request_type,com_status			     ;AN000;

	       BREAK 20 					      ;AN000;

		  .ENDIF


;	    LPT?,
	    PRN:

		  MOV  device_name,OFFSET LPT1_str				  ;AC001;
		  .IF <parm_list[current_parm_DI].item_tag EQ PRN_item_tag> OR	  ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT1_item_tag> OR   ;AN000;
		  MOV  device_name,OFFSET LPT2_str				  ;AC001;
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT2_item_tag> OR   ;AN000;
		  MOV  device_name,OFFSET LPT3_str				  ;AC001;
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT3_item_tag> THEN ;AN000;

	       MOV   looking_for,eol	    ;AN000;
	       MOV   request_type,printer_status			;AN000;
	       BREAK 20 						;AN000;

		  .ENDIF



;	    CON:

		  .IF <parm_list[current_parm_DI].item_tag EQ CON_item_tag> THEN ;AN000;

	       MOV   looking_for,eol				  ;AN000;
	       MOV   request_type,all_con_status			   ;AN000;
	       BREAK 20 						;AN000;

		  .ENDIF


;	    eol:

		  .IF <parser_return_code_AX EQ end_of_command_line> THEN ;AN000;

	       MOV   request_type,status_for_everything 	       ;AN000;
	       MOV   eol_found,true			      ;AN000;
	       BREAK 20 						;AN000;

		  .ENDIF


;	    otherwise:

	       CALL  setup_invalid_parameter	   ;AN000;
;	       BREAK

	 ENDCASE_20:
	 BREAK 0  ;AN000;device_name_or_eol


      first_parm_case:				;AN000;


PUBLIC	 first_parm_case

	 ;set up for calls to system parser

	 MOV   command_line,OFFSET first_char_in_command_line	;AN000;start parser at beginning of the command line
	 MOV   BX,OFFSET parm_lst      ;set up parm_list	;AN000;
	 XOR   DI,DI						;AN000;
	 SUB   DI,TYPE parm_list_entry	     ;AN000;DI is negative, set up for first call to parse_parm

	 MOV   parms.parmsx_ptr,OFFSET parmsx	   ;AN000;set up parms block for parser input

	 CALL	parse_parm     ;AN000;parse first parm, fill in "parm_list[current_parm_DI]" with the results

;	 CASE current_parm=

dummy5:
PUBLIC	 dummy5

;	    /status:

		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_STA>> OR	;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_stat>> OR   ;AC004;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET slash_STATUS>> THEN ;AN000;

	       MOV   slash_status,deleted				;AN000;make it so /status again is an error
	       MOV   slash_stat,deleted 	;AN000;
	       MOV   slash_sta,deleted
	       MOV   looking_for,device_name_or_eol			;AN000;
	       BREAK 21 						;AN000;

		  .ENDIF


;	    null:		 ;no first parm

		  .IF <parser_return_code_AX EQ no_error> AND	 ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag EQ unspecified> THEN   ;AN000;valid null

	       MOV   looking_for,sd_or_dl			;AN000;
	       MOV   parms.parmsx_ptr,OFFSET old_con_parmsx
	       MOV   ordinal,0					;AN000;start over with new parmsx block
	       MOV   device_name,OFFSET CON_str
	       MOV   request_type,old_video_mode_set		;AN000;
	       BREAK 21 					;AN000;

		  .ENDIF


	    screen_modes:	  ;first parm is 80, BW80, MONO etc.

	    PUBLIC   screen_modes

		  .IF <parm_list[current_parm_DI].item_tag GE first_screen_mode_item_tag> AND ;AN000;
		  .IF <parm_list[current_parm_DI].item_tag LE last_screen_mode_item_tag> THEN ;AN000;

	       MOV   parms.parmsx_ptr,OFFSET old_con_parmsx
	       MOV   ordinal,0					;AN000;start over with new parmsx block
	       MOV   device_name,OFFSET CON_str
	       MOV   looking_for,sd_or_dl_or_eol		;AN000;
	       MOV   request_type,old_video_mode_set		;AN000;
	       BREAK 21 					;AN000;

		  .ENDIF



;	    LPT?132,
;	    LPT?80:

		  MOV	device_name,OFFSET LPT1_str			  ;AN000;assume LPT1
		  MOV	device,"1"                              ;AC664;set up message
		  MOV	LPTNO,"1"                  ;see modeprin
		  MOV	parm_list[current_parm_DI+TYPE parm_list_entry].item_tag,onethirtytwo_item_tag   ;AN000;save chars/line
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT1132_item_tag> OR ;AN000;
		  MOV	device_name,OFFSET LPT2_str			  ;AN000;assume LPT2
		  MOV	LPTNO,"2"                  ;see modeprin
		  MOV	device,"2"                              ;AC664;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT2132_item_tag> OR ;AN000;
		  MOV	device_name,OFFSET LPT3_str			  ;AN000;assume LPT3
		  MOV	LPTNO,"3"                  ;see modeprin
		  MOV	device,"3"                              ;AC664;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT3132_item_tag> OR ;AN000;
		  MOV	device_name,OFFSET LPT1_str			  ;AN000;assume LPT1
		  MOV	device,"1"                              ;AC664;set up message
		  MOV	LPTNO,"1"                  ;see modeprin
		  MOV	parm_list[current_parm_DI+TYPE parm_list_entry].item_tag,eighty_item_tag	  ;AN000;save chars/line
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT180_item_tag > OR ;AN000;
		  MOV	device_name,OFFSET LPT2_str			  ;AN000;assume LPT2
		  MOV	LPTNO,"2"                  ;see modeprin
		  MOV	device,"2"                              ;AC664;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT280_item_tag > OR ;AN000;
		  MOV	device_name,OFFSET LPT3_str			  ;AN000;assume LPT3
		  MOV	LPTNO,"3"                  ;see modeprin
		  MOV	device,"3"                              ;AC664;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT380_item_tag > THEN ;AN000;


	       ADD   DI,TYPE parm_list_entry			;AN000;already have chars per line so skip to next element in list
	       MOV   parms.parmsx_ptr,OFFSET lpt_parmsx 	;AN000;
	       MOV   REFRESH_str,deleted			;AN007;no codepage stuff legal
	       MOV   REF_str,deleted				;AN007;
	       MOV   SEL_equal,deleted				;AN007;
	       MOV   SELECT_equal,deleted			;AN007;
	       MOV   PREP_equal,deleted 			;AN007;
	       MOV   PREPARE_equal,deleted			;AN007;
	       MOV   ordinal,1				;AN000;already found chars per line (cl)
	       MOV   looking_for,li_or_null			;AN000;
	       MOV   device_type,LPTX				;AN000;
	       MOV   request_type,old_initialize_printer_port	;AN000;
	       BREAK 21 					;AN000;

		  .ELSE 		  ;AN000;clean up after dorking the next parameter
		     ADD   DI,TYPE parm_list_entry	;AN000;point to next entry, the one that needs to be reinitialized
		     CALL  reset_parm_pointer		;AN000;reinitialize the second parm entry, DEC DI
		  .ENDIF



;	    LPT1:=,
;	    LPT1=,
;	    LPT2:=,
;	    LPT2=,
;	    LPT3:=,
;	    LPT3=:


		  ;have control blocks set up to find COM strings as value of keyword

		  MOV  lptno,0				   ;lptno=BIOS digestable printer number for LPT1 set up for modeecho
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET LPT1_colon_equal>> OR  ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET LPT1_equal>> OR  ;AN000;
		  MOV	lptno,1 									  ;set up for modeecho
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET LPT2_colon_equal>> OR  ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET LPT2_equal>> OR  ;AN000;
		  MOV	lptno,2 									  ;set up for modeecho
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET LPT3_colon_equal>> OR  ;AN000;
		  .IF <parm_list[current_parm_DI].keyword_switch_ptr EQ <OFFSET LPT3_equal>> THEN      ;AN000;
		     MOV   device,"1"                                                    ;set up for call to modeecho
		     .IF <parm_list[current_parm_DI].item_tag EQ COM1_item_tag> OR   ;AN000;
		     MOV   device,"2"                                                    ;set up for call to modeecho
		     .IF <parm_list[current_parm_DI].item_tag EQ COM2_item_tag> OR   ;AN000;
		     MOV   device,"3"                                                    ;set up for call to modeecho
		     .IF <parm_list[current_parm_DI].item_tag EQ COM3_item_tag> OR   ;AN000;
		     MOV   device,"4"                                                    ;set up for call to modeecho
		     .IF <parm_list[current_parm_DI].item_tag EQ COM4_item_tag> THEN ;AN000;

	       MOV   looking_for,eol			     ;AN000;
	       MOV   request_type,printer_reroute		    ;AN000;
	       MOV   reroute_requested,true			     ;AN000;
	       MOV   device_type,LPTX
	       BREAK 21 						;AN000;

		     .ELSE						      ;AN000;
			MOV   message,OFFSET com1_or_com2      ;AN000;"Must specify COM1, COM2, COM3 or COM4"
		     .ENDIF
		  .ENDIF



;	    LPTX,:		       found "LPTX," so chars per line has been skipped

		  .IF <terminating_delimeter EQ comma> AND NEAR ;AC007;handle other cases later, looking only for "LPTX," now
		  MOV	device_name,OFFSET LPT1_str			  ;AN000;assume LPT1
		  MOV	device,"1"                              ;AC664;set up message
		  MOV	LPTNO,"1"                  ;see modeprin
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT1_item_tag> OR   ;AN000;
		  MOV	device_name,OFFSET LPT2_str			  ;AN000;assume LPT2
		  MOV	LPTNO,"2"                  ;see modeprin
		  MOV	device,"2"                              ;AC664;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT2_item_tag> OR   ;AN000;
		  MOV	device_name,OFFSET LPT3_str			  ;AN000;assume LPT3
		  MOV	LPTNO,"3"                  ;see modeprin
		  MOV	device,"3"                              ;AC664;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT3_item_tag> THEN ;AN000;

	       MOV   parms.parmsx_ptr,OFFSET lpt_parmsx 	;AN000;
	       MOV   lines_value_ptr,OFFSET LPT_lines_values		;AN000;
	       MOV   lines_match_flag,simple_string		;AN000;printer lines values are strings
	       MOV   REFRESH_str,deleted			;AN007;no codepage stuff legal
	       MOV   REF_str,deleted				;AN007;
	       MOV   SEL_equal,deleted				;AN007;
	       MOV   SELECT_equal,deleted			;AN007;
	       MOV   PREP_equal,deleted 			;AN007;
	       MOV   PREPARE_equal,deleted			;AN007;
	       MOV   ordinal,1					;AN000;new parmsx, skip chars per line positional
	       ADD   DI,TYPE parm_list_entry			;create entry for skipped chars per line     ;AN000;
	       MOV   looking_for,li_or_null			;AN000;
	       MOV   device_type,LPTX				;for rescode
	       MOV   request_type,old_initialize_printer_port	;AN000;
	       BREAK 21 						;AN000;

		  .ENDIF




;		  need to use colon as a delimeter in following cases

		  modify_parser_control_block seperator_list,addd,colon  ;AN000;want to stop on colons

		  CALL	reset_parm_pointer	;reset to first entry in the parm list
		  MOV	ordinal,0		;start with the first parm again
		  MOV	command_line,OFFSET first_char_in_command_line	;look at first part of command line again
		  CALL	parse_parm	     ;AN000;parse the first parm again


;	    COM?:


		  MOV	device_name,OFFSET COM1_str			  ;AN000;assume COM1
		  MOV	device,"1"                              ;AN000;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ COM1_item_tag> OR   ;AN000;
		  MOV	device_name,OFFSET COM2_str			  ;AN000;assume COM2
		  MOV	device,"2"                              ;AN000;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ COM2_item_tag> OR   ;AN000;
		  MOV	device_name,OFFSET COM3_str			  ;AN000;assume COM3
		  MOV	device,"3"                              ;AN000;;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ COM3_item_tag> OR   ;AN000;
		  MOV	device_name,OFFSET COM4_str			  ;AN000;assume COM4
		  MOV	device,"4"                              ;AN000;;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ COM4_item_tag> THEN ;AN000;

	       MOV   parms.parmsx_ptr,OFFSET com_parmsx 	;AN000;
	       MOV   ordinal,0				;AN000;new parmsx, start with new number of positionals, start at first one
	       MOV   looking_for,com_keyword_or_baud		;AN000;
	       MOV   device_type,COMX			 ;AN000;;set up for rescode
	       BREAK 21 					;AN000;

		  .ENDIF



;	    LPT?:

		  MOV	device_name,OFFSET LPT1_str			  ;AN000;assume LPT1
		  MOV	device,"1"                              ;AC664;set up message
		  MOV	LPTNO,"1"                  ;see modeprin
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT1_item_tag> OR   ;AN000;
		  MOV	device_name,OFFSET LPT2_str			  ;AN000;assume LPT2
		  MOV	LPTNO,"2"                  ;see modeprin
		  MOV	device,"2"                              ;AC664;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT2_item_tag> OR   ;AN000;
		  MOV	device_name,OFFSET LPT3_str			  ;AN000;assume LPT3
		  MOV	LPTNO,"3"                  ;see modeprin
		  MOV	device,"3"                              ;AC664;set up message
		  .IF <parm_list[current_parm_DI].item_tag EQ LPT3_item_tag> THEN ;AN000;

	       MOV   parms.parmsx_ptr,OFFSET lpt_parmsx 	;AN000;
	       MOV   columns_value_ptr,OFFSET LPT_columns_values	;AN000;
	       MOV   lines_value_ptr,OFFSET LPT_lines_values		;AN000;
	       MOV   columns_match_flag,simple_string		;AN000;printer columns values are strings
	       MOV   lines_match_flag,simple_string		;AN000;printer lines values are strings
	       MOV   ordinal,0					;AN000;new parmsx so start over counting positionals
	       MOV   looking_for,prn_kw_status_cp_cl_null  ;AN000;
	       MOV   device_type,LPTX				;for rescode
	       BREAK 21 						;AN000;

		  .ENDIF


;	    PRN:

		  .IF <parm_list[current_parm_DI].item_tag EQ PRN_item_tag> THEN  ;AN000;

	       MOV   looking_for,codepage		;AN000;
	       MOV   device_name,OFFSET LPT1_str	;AN000;
	       BREAK 21 				;AN000;

		  .ENDIF


;	    CON:

		  .IF <parm_list[current_parm_DI].item_tag EQ CON_item_tag> THEN ;AN000;

	       MOV   parms.parmsx_ptr,OFFSET con_parmsx 	;AN000;set up for con parms
	       MOV   ordinal,0					;AN000;start over with new parmsx block
	       MOV   looking_for,BYTE PTR con_kwrd_status_or_cp   ;AN000;
	       MOV   device_name,OFFSET CON_str
	       BREAK 21

		  .ENDIF



;	    eol:		 ;no parms specified

		  .IF <parser_return_code_AX EQ end_of_command_line> THEN ;AN000;

	       MOV   request_type,status_for_everything 	       ;AN000;
	       MOV   eol_found,true			      ;AN000;
	       BREAK 21 						;AN000;

		  .ENDIF



;	    COM?baud:


		  MOV	parms.parmsx_ptr, OFFSET mutant_COM_parmsx
		  ;for i in 1 through 4 see if the parm is COMi
		  MOV	match_found,false		       ;AN000;
		  MOV	i_CL,0				   ;AN000;CL:="1"
		  .WHILE <i_CL LT 4> AND		;AN000;
		  .WHILE <match_found EQ false> DO		 ;AN000;
		     CALL  reset_parm_pointer		   ;AN000;prepare to reparse the parm
		     INC   i_CL        ;AN000;use next number as a delimeter
		     MOV   parm_list[current_parm_DI].item_tag,i_CL	   ;AN000;depends on COM1 thru 4 item tags being 1 thru 4
		     PUSH  CX					;AN000;save the loop counter (the binary form)
		     ADD   i_CL,binary_to_ASCII 		;CL=ASCII representation of the index
		     modify_parser_control_block seperator_list,addd,i_CL   ;AN000;make the number (1 to 4)a seperator
		     MOV   ordinal,0					;AN000;look at first parm each time
		     MOV   command_line,OFFSET first_char_in_command_line   ;set parser up at start of the command line each time
		     PUSH  CX				   ;AN000;save the delimeter (ASCII form)
		     CALL   parse_parm				      ;AN000;
;		     .IF <parm_list[current_parm_DI].item_tag EQ COM_item_tag> THEN ;AN000;isloated "COM" so found "COM?"
		     .IF <parser_return_code_AX EQ no_error> THEN ;AN000;isloated "COM" so found "COMx"
			MOV   match_found,true				   ;AN000;
		     .ENDIF
		     POP   CX				      ;AN000;restore the ASCII delimeter
		     modify_parser_control_block seperator_list,delete,i_CL  ;AN000;fix parser control blocks
		     POP   CX				      ;restore the loop counter
		  .ENDWHILE						   ;AN000;
		  .IF <match_found EQ true> THEN   ;AN000;IF have COMX THEN look for valid baud
		     .IF <i_CL EQ 1> THEN			;AN000;
			MOV   device_name,OFFSET COM1_str	;AN000;
			MOV   parm_list[current_parm_DI].value1,OFFSET COM1_str ;AN000;setup for modecom existence check
			MOV   device,"1"                              ;AN000;set up message
		     .ELSEIF <i_CL EQ 2> THEN			;AN000;
			MOV   device_name,OFFSET COM2_str	;AN000;
			MOV   parm_list[current_parm_DI].value1,OFFSET COM2_str ;AN000;setup for modecom existence check
			MOV   device,"2"                              ;AN000;set up message
		     .ELSEIF <i_CL EQ 3> THEN			;AN000;
			MOV   device_name,OFFSET COM3_str	;AN000;
			MOV   parm_list[current_parm_DI].value1,OFFSET COM3_str ;AN000;setup for modecom existence check
			MOV   device,"3"                              ;AN000;set up message
		     .ELSE;IF <i_CL EQ 4> THEN			;AN000;
			MOV   device_name,OFFSET COM4_str	;AN000;
			MOV   parm_list[current_parm_DI].value1,OFFSET COM4_str ;AN000;setup for modecom existence check
			MOV   device,"4"                              ;AN000;set up message
		     .ENDIF					;AN000;

	       MOV   parms.parmsx_ptr,OFFSET com_parmsx 	;AN000;
	       MOV   ordinal,0				;AN000;start with baud in new parmsx
	       MOV   looking_for,com_keyword_or_baud		     ;AN000;
	       MOV   device_type,COMX				;set up for rescode
	       BREAK 21 					     ;AN000;


;	    otherwise:		  ;first parm was nothing recognizable

		  .ELSE

dummy4:
PUBLIC	 dummy4

	       MOV   ordinal,0					  ;AN000;parse first parm again
	       MOV   command_line,OFFSET first_char_in_command_line   ;set parser up at start of the command line one more time
	       modify_parser_control_block seperator_list,addd,"."    ;AN000;want to stop on periods
	       modify_parser_control_block seperator_list,addd,'"'    ;AN000;want to stop on quotes
	       modify_parser_control_block seperator_list,addd,'\'    ;AN000;want to stop on back slashes
	       modify_parser_control_block seperator_list,addd,'['    ;AN000;want to stop on left brackets
	       modify_parser_control_block seperator_list,addd,']'    ;AN000;want to stop on right brackets
	       modify_parser_control_block seperator_list,addd,'+'    ;AN000;want to stop on plus signs
;AC003;        modify_parser_control_block seperator_list,addd,';'    ;AN000;want to stop on semicolons

	       CALL  parse_parm
	       CALL  setup_invalid_parameter	      ;AN000;
;	       BREAK

		  .ENDIF

	 ENDCASE_21:

	 BREAK 0  ;AN000;first_parm



      eol_case:

	 CALL	parse_parm						;AN000;
	 .IF <parser_return_code_AX NE end_of_command_line> THEN	;AN000;
	    MOV   message,OFFSET invalid_number_of_parameters		       ;AN000;
	    MOV   noerror,false 					;AN000;
	 .ELSE NEAR						;AN000;
	    MOV   eol_found,true				;AN000;
	 .ENDIF
;	 BREAK



   ENDCASE_0: ;AN000;looking_for=

.ENDWHILE		      ;AN000;

.IF <message NE no_message> THEN
   display  message
.ENDIF

RET

parse_parameters  ENDP







;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³
;³ SEPERATOR_LIST
;³ --------------
;³
;³ As the logic in PARSE_PARAMETERS proceeds the posibilities for the next parm
;³ become apparent and the parser control blocks need to be changed to correctly
;³ parse the next parm.  This procedure is responsible for manipulating the
;³ list of seperators as requested.
;³
;³
;³
;³
;³  INPUT: action (in BX) - A scalar immediate indicating whether the seperator
;³			     is to be added or deleted.
;³
;³	   seperator_charactor (in AL) - The seperator character to be added or
;³					  deleted from the seperator list
;³
;³
;³  RETURN: none
;³
;³
;³  MESSAGES: none
;³
;³
;³
;³  REGISTER
;³  USAGE:
;³
;³
;³
;³  CONVENTIONS:
;³
;³
;³  ASSUMPTIONS: The character exists in the list before it is deleted.
;³		 A character being added is not already in the list.
;³		 There is no "extra end of line list".
;³		 Direction flag is cleared so REPs will increment index reg
;³		 ES and DS are the same and address data
;³
;³
;³
;³
;³
;³
;³  SIDE EFFECT:
;³
;³
;³
;³
;³
;³  LOGIC:
;³
;³
;³  CASE action=
;³
;³     add:
;³
;³	  skip to end of seperators list  ;use parms.seperators_len to find end
;³	  overwrite zero with AL
;³	  overwrite blank space holder in the delimeter list with AL
;³	  INC	parms.seperators_len
;³	  BREAK
;³
;³
;³     delete:
;³
;³	  DEC	parms.seperators_len
;³	  scan to seperator char to be deleted
;³	  shift remaining chars to left
;³	  put zero at end for length of the extra EOL list
;³	  BREAK
;³
;³  ENDCASE
;³
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ


seperator_list	PROC  NEAR

;CASE modifier=

SHL   BX,1			 ;AN000;BX=word displacement into jump table
JMP   jump_table2[BX]		 ;AN000;jump to appropriate jump

jump_table2 LABEL WORD

DW    OFFSET add_case		  ;AN000;
DW    OFFSET delete_case	  ;AN000;


   add_case:


      XOR   BX,BX
      MOV   BL,parms.seperators_len	  ;AN000;BX=length of seperators list
      ADD   BX,OFFSET parms
      MOV   [BX].seperators,AL		  ;AN000;overwrite blank with AL
      INC   parms.seperators_len	  ;AN000;adjust for added seperator
      BREAK 22				  ;AN000;


   delete_case:

      ;scan to seperator char to be deleted

      PUSH  DI

      MOV   DI,OFFSET parms
      ADD   DI,OFFSET seperators       ;ES:DI=>seperator list
      REPNE SCASB
      DEC   DI			       ;AN000;DI=>char to be deleted
      MOV   ES:[DI],BYTE PTR blank		;duplicate but harmless blank

      POP   DI

      BREAK 22				     ;AN000;

ENDCASE_22:

RET

seperator_list	ENDP


;-------------------------------------------------------------------------------
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³
;³ KEYWORDS
;³ --------
;³
;³ As the logic in PARSE_PARAMETERS proceeds the posibilities for the next parm
;³ become apparent and the parser control blocks need to be changed to correctly
;³ parse the next parm.  This procedure is responsible for manipulating the
;³ list of keywords as requested.
;³
;³
;³
;³
;³# INPUT: action (in BX) - A scalar immediate indicating whether the keyword
;³#			      is to be added or deleted.
;³#
;³#
;³#	   string (in RL) - A scalar immediate or OFFSET, indicating/pointing
;³#			      to the keyword or set of keywords to be added
;³#			      or deleted.
;³
;³
;³
;³  RETURN: none
;³
;³
;³  MESSAGES: none
;³
;³
;³
;³
;³  REGISTER
;³  USAGE:
;³
;³
;³
;³  CONVENTIONS:
;³
;³
;³
;³
;³  ASSUMPTIONS:
;³
;³
;³
;³
;³  SIDE EFFECT:
;³
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ


keywords PROC NEAR

;	    use result.synonym to find the the keyword to delete

	    MOV   SI,parm_list[current_parm_DI].keyword_switch_ptr	;SI=>the keyword string to be deleted
	    MOV   BYTE PTR ES:[SI],deleted	  ;AN000;zilch out first byte of the keyword string


   RET

keywords  ENDP

;-------------------------------------------------------------------------------


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³
;³ PARSE_PARM
;³ ----------
;³
;³ Add the parm found to the parm_list.  Save the pointer to the current parm
;³ for use by CALL  reset_parm_pointer.  When a reset call from  reset_parm
;³ happens the pointer to the last entry in the parm list is decremented, which
;³ will put the results of the next parse over that entry.
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³  INPUT:
;³
;³
;³  RETURN: The next parm list entry is filled with the results of the call to
;³	    the parser.  If the parser returns an error other than "end of
;³	    command line" the entry is not filled in.  If the parser returns
;³	    "end of command line" the .type field is set to end_of_command_line.
;³
;³
;³  MESSAGES: none
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³  REGISTER
;³  USAGE:
;³
;³
;³
;³  CONVENTIONS:
;³
;³
;³
;³
;³
;³
;³
;³  ASSUMPTIONS:
;³
;³
;³
;³
;³
;³
;³
;³
;³  SIDE EFFECT:
;³
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

parse_parm  PROC

PUBLIC	 PARSE_PARM

   ADD	 current_parm_DI, TYPE parm_list_entry

   PUSH  current_parm_DI	  ;save index into parsed parms list
   PUSH  BX			 ;save the address of the parsed parms list

   MOV	   DI,OFFSET PARMS	   ; ES:DI=>PARSE CONTROL DEFINITON
   MOV	   SI,COMMAND_line	   ; DS:SI=>unparsed portion of the command line
   MOV	   DX,0 		   ; RESERVED
   MOV	   CX,ordinal		   ; OPERAND ORDINAL
   EXTRN   SYSPARSE:NEAR
   CALL    SYSPARSE		    ;AX=return code, DX=>result buffer
   MOV	   ordinal,CX		    ;save for next call
   MOV	   terminating_delimeter,BL ;save the character that delimited the parm

   POP	 BX			 ;restore parm_list
   POP	 current_parm_DI	 ;nothing returned in DI anyway

   MOV	 CX,command_line	    ;AN000;CX=>first char of the bad parm
   MOV	 offending_parameter_ptr,CX ;AN000;set pointer in message

;  .IF <parser_return_code_AX EQ no_error> THEN
      MOV   command_line,SI	       ;save pointer to remainder of the command line
      .IF <parser_return_code_AX NE end_of_command_line> THEN
	 MOV   DL,result.ret_type
	 MOV   parm_list[current_parm_DI].parm_type,DL
	 MOV   DL,result.item_tag
	 MOV   parm_list[current_parm_DI].item_tag,DL
	 MOV   DX,result.ret_value1
	 MOV   parm_list[current_parm_DI].value1,DX
	 MOV   DX,result.ret_value2
	 MOV   parm_list[current_parm_DI].value2,DX
	 MOV   DX,result.synonym
	 MOV   parm_list[current_parm_DI].keyword_switch_ptr,DX
      .ENDIF
;  .ELSE			       ;AN000;encountered an error
;     MOV   CX,command_line	       ;AN000;CX=>first char of the bad parm
;     MOV   offending_parameter_ptr,CX ;AN000;set pointer in message
;     MOV   BYTE PTR [SI],0	       ;AN000;make the offending parm an ASCIIZ string
;  .ENDIF			       ;AN000;leave the call to msg services to the calling routine

   RET

parse_parm  ENDP



;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³
;³ RESET_PARM_POINTER
;³ ------------------
;³
;³
;³
;³ The last entry in the parm list is decremented, which
;³ will put the results of the next parse over that entry.
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³  INPUT:
;³
;³
;³  RETURN: The current parm list entry is filled with recognizable trash
;³
;³
;³
;³
;³  MESSAGES: none
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³
;³  REGISTER
;³  USAGE:
;³
;³
;³
;³  CONVENTIONS:
;³
;³
;³
;³
;³
;³
;³
;³  ASSUMPTIONS:
;³
;³
;³
;³
;³
;³
;³
;³
;³  SIDE EFFECT:
;³
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
									;AN000;
reset_parm_pointer  PROC



   MOV	 parm_list[current_parm_DI].parm_type,bogus			;AN000;
   MOV	 parm_list[current_parm_DI].item_tag,0FFH			;AN000;
   MOV	 parm_list[current_parm_DI].synonym,bogus			;AN000;
   MOV	 parm_list[current_parm_DI].value1,bogus			;AN000;
   MOV	 parm_list[current_parm_DI].value2,bogus			;AN000;
   MOV	 parm_list[current_parm_DI].keyword_switch_ptr,0		;AN000;
   SUB	 current_parm_DI,TYPE parm_list_entry				;AN000;
   DEC	 ordinal							;AN000;


   RET

reset_parm_pointer ENDP 						;AN000;


PRINTF_CODE ENDS							;AN000;
	END								;AN000;
