
;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;  AX001 - P3976: Need to have all pieces of messages in MODE.SKL so have to
;		  implement the SYSGETMSG method of getting addressability to
;		  the pieces.  This means that the code does a SYSGETMSG call
;		  which returns a pointer (DS:SI) to the message piece.  The
;		  address is then put in the sublist block for the message
;		  being issued.

;  AC002 - P3258: PS/2 only COM parameters were being allowed on non-PS/2
;		  machines.  Added checks for baud=19200, parity=mark or space,
;		  data=5 or 6, stop=1.5 for both keyword and positional forms
;		  in MODEPARSE.ASM.  Had to enlarge the possible parm size for
;		  "Function not supported on this computer - ?????????????"

;บ											  บ
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;PUBLICs for the sublists are handled in modemes.asm
PUBLIC	 Utility_Msg_Class		  ;AN001;

;บ											  บ
;ศอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออผ


;
;*****************************************************************************
; External data declarations
;*****************************************************************************



;
;*****************************************************************************
; Message Retriever equates
;*****************************************************************************
;

INCLUDE  common.stc	   ;contains the following structure

;sublist_def  STRUC

;	      db  ?  ;Sublist Length, fixed
;	      db  ?  ;Reserved, not used yet		       ;AN000;
;	      dw  ?  ;offset
;sublist_seg  dw  ?  ;segment part of pointer to piece of message
;	      db  ?  ;number of this piece of the message,0 indicates special end of message format ;AN000;
;	      db  ?  ;flags
;	      db  ?  ;maximum field width
;	      db  ?  ;minimum field width
;	      db  ?  ;character to use for padding

;sublist_def  ENDS



INCLUDE  modequat.inc	   ;contains the following two equates for this file

;FLAGS field bit(s) values

;Left_Align		 equ	 0	 ;00xxxxxx
;Right_Align		 equ	 80h	 ;10xxxxxx

Char_Field_Char    equ	   0		 ;a0000000
Char_Field_ASCIIZ  equ	   00010000B	 ;a0010000

;Unsgn_Bin_Byte    equ	   11h	   ;a0010001
Unsgn_Bin_Word	  equ	  21h	  ;a0100001
Unsgn_Bin_DWord   equ	  31h	  ;a0110001

Sgn_Bin_Byte	  equ	  12h	  ;a0010010
Sgn_Bin_Word	  equ	  22h	  ;a0100010
Sgn_Bin_DWord	  equ	  32h	  ;a0110010

Bin_Hex_Byte	     equ     13h     ;a0010011
Bin_Hex_Word	     equ     23h     ;a0100011
Bin_Hex_DWord	     equ     33h     ;a0110011



Blank			equ	" "
No_Function		equ	0
No_Replace		equ	0

Msg_Ser_Class		equ	0
Ext_Err_Class		equ	1
Parse_Error_Class	equ	2
Utility_Msg_Class	equ	0FFh

Reserved		equ	0

Sublist_Length		equ	TYPE sublist_def

to_be_filled_in 	EQU	 77H	  ;conspicious number



;
;*****************************************************************************
; Message Sublist Tables
;*****************************************************************************
;
;The  following  control  blocks  are	used   for   messages  with
;replaceable  paramters.  These  control  blocks  are  used by	the
;SysDispMsg routine.
;

;---------------------------			;
first_sublist  LABEL BYTE

sublist_invalid_switch	    label byte		;AN000;description of %0
sublist_invalid_parameter   label byte		;AN000;description of %0
						;
	db		Sublist_Length		;fixed				;AN000;
	db		Reserved		;not used yet			;AN000;
offending_parameter_ptr LABEL WORD
	dw		offset	 offending_parameter	 ;pointer to string or binary value	;AN000;
	dw		to_be_filled_in 	;
	db		0			;ID, special end of message format ;AN000;
sub_typ db		Left_Align+char_field_ASCIIZ ;maybe changed	     ;AN000;
	db		0			;Max width 123, 128-"MODE "    ;AN000;
	db		1			;May be one char long	       ;AN000;
	db		Blank			;				;AN000;
;---------------------------			;

sublist_err1		label byte		;AN000;description of %0
						;
	db		Sublist_Length		;fixed				;AN000;
	db		Reserved		;not used yet			;AN000;
illegal_device_ptr	LABEL WORD
	dw		?			;pointer to device name string filled in by modecom;AN000;
	dw		to_be_filled_in 	;
	db		0			;ID, special end of message format ;AN000;
	db		Left_Align+char_field_ASCIIZ ;		;AN000;
	db		5			;Max width, "LPT1:"    ;AN000;
	db		4			;"COM3"                        ;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
Sublist_PT80		label byte		;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		offset PT80N		;where the printer number is stashed ;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;ID, only one sublist		;AN000;
	db		Left_Align+Char_Field_Char ;			   ;AN000;
	db		1			;				;AN000;
	db		1			;				;AN000;
	db		Blank			;no filler needed but still have this field to fill
;---------------------------			;
Sublist_PT132		label byte		;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		offset PT132N		;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_Char ;			   ;AN000;
	db		1			;				;AN000;
	db		1			;				;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
Sublist_initmsg 	label byte		;CR,LF,"COM%c: %3s,%c,%c,%c,%c",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		offset device		;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;first of 6		       ;AN000;
	db		Left_Align+char_field_char			      ;AN000;
	db		1			;				;AN000;
	db		1			;one char number between 1 and 4;AN000;
	db		Blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
pbaud_ptr   label byte
	dw		offset pbaud		;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		2			;second of 6			;AN000;
	db		Left_Align+char_field_ASCIIZ			      ;AN000;
	db		0;RPS			;19200				;AN000;
	db		3			;110, 300 etc the shortest
	db		Blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
pparity_ptr LABEL BYTE				;allow access from invoke
	dw		offset pparity		;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		3			;third of 6		       ;AN000;
	db		Left_Align+char_field_char			      ;AN000;
	db		1			;				;AN000;
	db		1			;one char, n, o, e.
	db		Blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		offset pdata		;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		4			;fourth of 6			;AN000;
	db		Left_Align+char_field_char			      ;AN000;
	db		1			;				;AN000;
	db		1			;one char number between 6 and 8;AN000;
	db		blank			;never used, will display at least the default data bits

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
pstop_ptr   LABEL BYTE
	dw		offset pstop		;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		5			;fifth of 6		       ;AN000;
	db		Left_Align+char_field_ASCIIZ			      ;AN000;
	db		0			;big enough for "1.5"           ;AN000;
	db		1			;one char number between 1 and 2;AN000;
	db		Blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		offset pparm		;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		6			;last of 6		      ;AN000;
	db		Left_Align+char_field_char			      ;AN000;
	db		1			;				;AN000;
	db		1			;one char "P" or "-"
	db		Blank			;				;AN000;
;---------------------------			;
Sublist_shift_msg	label byte		;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
lftm_or_rghtm_ptr	label word
;AC001; dw		offset leftmost   ;filled in with pointer to "leftmost 0?" or "rightmost 9?"
	dw		?		  ;AC001;filled in with pointer to "leftmost 0?" or "rightmost 9?"
	dw		to_be_filled_in 	;				;AN000;
	db		1			;only 1 sub list			       ;AN000;
	db		Left_Align+char_field_ASCIIZ			  ;AN000;
	db		0;RPS			;rightmost 9?		       ;AN000;
	db		10			;leftmost 0?		       ;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
Sublist_redirmsg	label byte		;AN000; CR,LF,"LPT%1: rerouted to COM%2:",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		Offset REDPT		;filled with printer number
	dw		to_be_filled_in
	db		1			;first of 2			;AN000;
	db		Left_Align+char_field_char ;			  ;AN000;
	db		1			;				;AN000;
	db		1
	db		Blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		Offset REDCOM		;filled with COM port number
	dw		to_be_filled_in
	db		2			;second of 2			 ;AN000;
	db		Left_Align+char_field_char ;			  ;AN000;
	db		1			;				;AN000;
	db		1
	db		Blank			;				;AN000;

;---------------------------			;
Sublist_notremsg	label byte		;AN000; CR,LF,"LPT%1: not rerouted",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		Offset NOTREDPT 	;filled with printer number
	dw		to_be_filled_in
	db		1			;only one
	db		Left_Align+char_field_char ;			  ;AN000;
	db		1			;				;AN000;
	db		1
	db		Blank			;				;AN000;

;---------------------------			;
Sublist_retparto	label byte	  ;	;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
;AC001;inf_or_no_ptr	       LABEL WORD	       ;filled in with pointer to "No" or "infinit"
;AC001; dw		offset infinite      ;				     ;AN000;
	dw		?			;AC001;filled in with pointer to "No" or "infinit"
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ			   ;AN000;
	db		0;RPS			;				;AN000;
	db		2			;				;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
Sublist_cant_shift	label byte	    ;"Unable to shift screen ...." ;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
LEFT_OR_RIGHT_PTR	LABEL WORD						;AN000;
;AC001; dw		offset left		;FILLED WITH OFFSET OF 'left' or 'right'
	dw		?			;AC001;FILLED WITH OFFSET OF 'left' or 'right'
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ			   ;AN000;
	db		0;RPS			;				;AN000;
	db		4			;				;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
Sublist_CPMSG2		label byte		;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
CPMSGLST2DEV		LABEL WORD		;filled with pointer to device name
	dw		?
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0			;				;AN000;
	db		3			;				;AN000;
	db		Blank			;				;AN000;

;---------------------------			;
Sublist_CPMSG6		label byte		;"Active codepage for device %S is %D",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
CPMSGLST6DEV		LABEL WORD		;filled with pointer to device name
	dw		?
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0			;				;AN000;
	db		3			;				;AN000;
	db		Blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		OFFSET CPMSGLST6CP	;pointer to area FILLED IN BY "QUERY" ROUTINE WITH CODEPAGE ID
	dw		to_be_filled_in 	;				;AN000;
	db		2			;2nd of 2			;AN000;
	db		Left_Align+Unsgn_Bin_Word ;AN000;00100001B
	db		5			;codepage numbers could be 5 digits long
	db		1			;theoretically could be 1 digit ;AN000;
	db		Blank			;				;AN000;

;---------------------------			;
Sublist_CPMSG7		label byte		;"Device %1 not prepared",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
CPMSGLST7DEV		LABEL WORD		;FILLED IN BY "QUERY" ROUTINE WITH PTR TO DEVICE NAME
	dw		?
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0			;don't know how long the device name
	db		3			;				;AN000;
	db		Blank			;				;AN000;

;---------------------------			;
Sublist_CPMSG8		label byte		;"%1 codepages:",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		?			;filled in with OFFSET TO "HARDWARE" OR "PREPARED"
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS			; both "Hardware" and                  ;AC001;
	db		8			;	"Prepared" are 8 chars long    ;AC001;
	db		Blank			;				;AN000;


;---------------------------			;
Sublist_CPMSG9		label byte		;"  Codepage %d",CR,LF,EOM

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		OFFSET CPMSGLST9CP	;pointer to area filled in by "DISPLAY_CPID" in modecp.sal
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Unsgn_Bin_Word ;00100001B
	db		3
	db		3			;				;AN000;
	db		Blank			;				;AN000;

;---------------------------			;
Sublist_CPMSG10 	label byte		;"MODE %1 Codepage function completed",CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		?			;;FILLED IN TO POINT TO:
						;	     "Status",EOM
						;	     "Prepare",EOM
						;	     "Select",EOM
						;	     "Refresh",EOM
						;	     "Global",EOM
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS
	db		5			;				;AN000;
	db		Blank			;				;AN000;

;---------------------------			;
Sublist_CPMSG13 	label byte		;"   %D - %S Codepage",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
CPMSGLST13CP   LABEL WORD			;FILLED IN WITH CODEPAGE ID
	dw		?
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS			;				;AN000;
	db		3			;				;AN000;
	db		Blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
CPMSGLST13TYP  LABEL WORD			;FILLED IN TO POINT TO:
							       ; "Selected",EOM
							       ; "System",EOM
	dw		?
	dw		to_be_filled_in 	;				;AN000;
	db		2			;2nd of 2			;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS			;all codepage numbers are 3 chars long
	db		6			;				;AN000;
	db		Blank			;				;AN000;


;---------------------------			;
Sublist_CPMSG17 	label byte		;"Device error during %1",BEEP,CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		?			;;FILLED IN TO POINT TO:
						;     "Status",EOM
						;     "Prepare",EOM
						;     "Select",EOM
						;     "Refresh",EOM
						;     "write of font file to device",EOM
	dw		to_be_filled_in
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS			;"write of font file to device",EOM
	db		6			;"Status",EOM
	db		Blank			;				;AN000;


;---------------------------			;
Sublist_LINES_equal	label byte		;"LINES=%1",CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
ROW_PTR   LABEL  WORD		;FILLED IN TO POINT TO: "NONE", or a row value
	dw		?			;
	dw		to_be_filled_in 	;filled in at initialization time with PRINTF_CODE
	db		1			;				;AN000;
row_type db		Right_Align+Char_Field_ASCIIZ ; 		    ;AN000;
	db		0;RPS			;"NONE"
	db		2			;25, 43, 50			;AN000;
	DB		blank

;---------------------------			;
Sublist_COLUMNS_equal	  label byte		  ;"COLUMNS=%1",CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
COLUMNS_PTR   LABEL  WORD	    ;FILLED IN TO POINT TO: "NONE", or a columns value
	dw		?			;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
COLUMNS_type db 	    Right_Align+Char_Field_ASCIIZ ;			;AN000;
	db		0;RPS
	db		2			;				;AN000;
	DB		blank
;---------------------------			;
Sublist_RATE_equal     label byte	       ;"RATE=%1",CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
RATE_PTR   LABEL  WORD		 ;FILLED IN TO POINT TO: "NONE", or a rate value
	dw		?			;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
RATE_type db		 Right_Align+Char_Field_ASCIIZ ;		     ;AN000;
	db		0;RPS
	db		2			;				;AN000;
	DB		blank
;---------------------------			;
Sublist_DELAY_equal	label byte		;"DELAY=%1",CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
DELAY_PTR   LABEL  WORD 	  ;FILLED IN TO POINT TO: "NONE", or a delay value
	dw		?			;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
DELAY_type db		  Right_Align+Char_Field_ASCIIZ ;		      ;AN000;
	db		0;RPS
	db		1			;				;AN000;
	DB		blank
;---------------------------			;
Sublist_not_supported	label byte		;"Function not supported on this computer -%1"
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
not_supported_PTR   LABEL  WORD 		;FILLED IN TO POINT TO: the parameter that is not supported
	dw		OFFSET nada	     ;
	dw		to_be_filled_in 	;filled with segment of the .COM file	;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS			;AC002;maximum length of the string
	db		1			;				;AN000;
	DB		blank
;---------------------------			;
Sublist_status_for_device label byte		  ;"Status for device %1:"
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
stat_dev_ptr   LABEL  WORD	     ;FILLED IN TO POINT TO ONE of the device names in parse.asm
	dw		?			;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Char_Field_ASCIIZ ; 		    ;AN000;
dev_name_size	  db	4			;changed by invoke: 3 for CON, 4 for others
	db		3			;				;AN000;
	db		Blank			;				;AN000;

;---------------------------			;

Sublist_retry_equal label byte			;"RETRY=%1"
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
retry_type_ptr	  LABEL BYTE
	dw		?			;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Char_Field_ASCIIZ ; 		    ;AN000;
	db		0;RPS			;max size, "NONE"
	db		1			;min size, "E"                  ;AN000;
	db		Blank			;				;AN000;

;---------------------------			;
sublist_syntax_error   label byte	   ;AN000;description of %0
						;
	db		Sublist_Length		;fixed				;AN000;
	db		Reserved		;not used yet			;AN000;
syntax_error_ptr	LABEL WORD
	dw		offset	 offending_parameter	 ;pointer to string or binary value	;AN000;
	dw		to_be_filled_in 	;
	db		0			;ID, special end of message format ;AN000;
	db		Left_Align+char_field_ASCIIZ	   ;AN000;
	db		0			;Max width 123, 128-"MODE "    ;AN000;
	db		1			;May be one char long	       ;AN000;
	db		Blank			;				;AN000;







Number_of_sublists   EQU   (($ - first_sublist) / (TYPE sublist_def))



;		    MESSAGE PIECES
;-------------------------------------------------------

PT80N		DB  " "   ;PT80 - CR,LF,"LPT%c: set for 80",CR,LF,EOM

PT132N		DB  " "   ;PT132 - CR,LF,"LPT%c: set for 132",CR,LF,EOM

;INITMSG - CR,LF,"COM%c: %3s,%c,%c,%c,%c",CR,LF,EOM
DEVICE	       DB  " "
pBAUD	       DB  5 DUP(" "),EOM
pPARITY        DB  "e"        ;DEFAULT IS EVEN PARITY
pDATA	       DB  "7"        ;DEFAULT IS 7 DATA BITS PER BYTE
pSTOP	       DB  "1",EOM    ;DEFAULT FOR BAUD > 110, CHANGED TO 2 FOR 110
Pparm	       DB  " "
baud_19200     DB   "19200",EOM

;REDIRMSG - CR,LF,"LPT%c: rerouted to COM%c:",CR,LF,EOM
REDPT		DB  " "
REDCOM		DB  " "

;NOTREMSG - CR,LF,"LPT%c: not rerouted",CR,LF,EOM
NOTREDPT	DB  " "

OFFENDING_PARAMETER  DB 123 DUP (EOM)

nada	    DB	  8,8,8,"   ",0        ;backspace over the " - "

CPMSGLST6CP    DW    44H   ;AC665;FILLED IN BY "QUERY" ROUTINE WITH CODEPAGE ID


CPMSGLST9CP    DW    99H		 ;FILLED IN BY "QUERY" ROUTINE WITH CODEPAGE ID


row_value      DB    ?	   ;filled in by invoke.asm with screen lines requested or current setting
