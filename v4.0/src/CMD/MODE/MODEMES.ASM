	  PAGE	,132	;
	  TITLE MODEMES - MESSAGES DISPLAYED ON CONSOLE BY MODE

;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;  AC001 - P3976: Need to have all pieces of messages in MODE.SKL so have to
;		  implement the SYSGETMSG method of getting addressability to
;		  the pieces.  This means that the code does a SYSGETMSG call
;		  which returns a pointer (DS:SI) to the message piece.  The
;		  address is then put in the sublist block for the message
;		  being issued.

;บ											  บ
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ

PRINTF_CODE SEGMENT PUBLIC
	  ASSUME CS:PRINTF_CODE,DS:PRINTF_CODE
;
CR	  EQU	13	;CARRIAGE RETURN
LF	  EQU	10	;LINE FEED
BEEP	  EQU	7	;AUDIBLE TONE
EOM	  EQU	0	;NULL TERMINATOR, REQUIRED BY PRINTF

IF1
   %OUT including  MODESUBS.INC
   %OUT including  MODEDEFS.INC
ENDIF
INCLUDE  MODESUBS.INC
INCLUDE  MODEDEFS.INC

;
PUBLIC	 first_sublist
PUBLIC	 number_of_sublists

 PUBLIC    MOVED_MSG, ERR1, ERR2, PT80, PT80N, PT132, PT132N
 PUBLIC    PTLINES, RATEMSG, INITMSG, REDIRMSG, SHIFT_MSG, sublist_shift_msg
 PUBLIC    NOTREMSG, RETPARTO, sublist_retparto, CANT_SHIFT, sublist_cant_shift
 PUBLIC    NUMBERS, ;AC001;INF_OR_NO_ptr
 PUBLIC    Invalid_number_of_parameters, COM1_or_COM2, net_error
 PUBLIC    Invalid_parameter, not_supported, offending_parameter
 PUBLIC  offending_parameter_ptr
 PUBLIC    INITMSG, device,pbaud,pparity,pdata,pstop,pparm,pbaud,baud_19200
 PUBLIC  pstop_ptr
 PUBLIC  pparity_ptr
	       PUBLIC CPMSG1
		PUBLIC CPMSG2,CPMSGLST2DEV
		PUBLIC CPMSG3
		PUBLIC CPMSG4
		PUBLIC CPMSG5
		PUBLIC CPMSG6,CPMSGLST6CP,CPMSGLST6DEV
		PUBLIC CPMSG7,CPMSGLST7DEV
;AC001; 	PUBLIC CPMSGLST8HD
		PUBLIC sublist_cpmsg8
		PUBLIC CPMSG8
		PUBLIC CPMSG8_HW
;AC001; 	PUBLIC CPMSG8_PR
		PUBLIC CPMSG9,CPMSGLST9CP
		PUBLIC CPMSG10
		PUBLIC sublist_cpmsg10
;AC001; 	PUBLIC CPMSGLST10FUN
;AC001; 	PUBLIC CPMSG10_QUERY
;AC001; 	PUBLIC CPMSG10_DES
;AC001; 	PUBLIC CPMSG10_REFRESH
;AC001; 	PUBLIC CPMSG10_SELECT
;AC001; 	PUBLIC CPMSG10_GLOBAL
		PUBLIC CPMSG12
		PUBLIC CPMSG13
		PUBLIC CPMSGLST13CP
		PUBLIC CPMSGLST13TYP
;AC001; 	PUBLIC CPMSG13_ACT
;AC001; 	PUBLIC CPMSG13_SYS
		PUBLIC CPMSG14
		PUBLIC CPMSG15
		PUBLIC CPMSG16
		PUBLIC CPMSG17
		PUBLIC sublist_CPMSG17
;AC001; 	PUBLIC CPMSGLST17FUN
;AC001; 	PUBLIC CPMSG17_QUERY
;AC001; 	PUBLIC CPMSG17_PREP
;AC001; 	PUBLIC CPMSG17_REFRESH
;AC001; 	PUBLIC CPMSG17_ACT
;AC001; 	PUBLIC CPMSG17_WRIT
		PUBLIC CPMSG18
		PUBLIC CPMSG19
		PUBLIC CPMSG20
		PUBLIC CPMSG21
		PUBLIC dev_name_size	     ;used by invoke for msg srv
		PUBLIC stat_dev_ptr	     ;used by invoke for msg srv
		PUBLIC long_underline	     ;used by invoke for msg srv
		PUBLIC five_char_underline	  ;used by invoke for msg srv
		PUBLIC four_char_underline	  ;used by invoke for msg srv
		PUBLIC row_ptr
		PUBLIC status_for_device
		PUBLIC notredpt
;AC001; 	PUBLIC noretry
;AC001; 	PUBLIC LEFT
;AC001; 	PUBLIC RIGHT
		PUBLIC row_type
		PUBLIC lines_equal_msg		;used by analyze_and_invoke, "LINES=%1" definition
		PUBLIC	redcom
;AC001; 	PUBLIC	rightmost
;AC001; 	PUBLIC	leftmost
;AC001; 	PUBLIC	infinite
		PUBLIC	REDPT
		PUBLIC	PBAUD_PTR
;		PUBLIC BLINK_type
		PUBLIC COLUMNS_ptr
		PUBLIC COLUMNS_equal_msg
		PUBLIC columns_type
		PUBLIC delay_type
		PUBLIC delay_ptr
		PUBLIC rate_ptr
		PUBLIC rate_type
		PUBLIC function_not_supported
		PUBLIC Required_font_not_loaded
		PUBLIC ANSI_not_loaded
		PUBLIC Baud_rate_required
		PUBLIC RETRY_type_ptr
		PUBLIC RETRY_equal
		PUBLIC Baud_rate_required
		PUBLIC	not_supported_ptr
		PUBLIC	Illegal_device_ptr
		PUBLIC	syntax_error
		PUBLIC	syntax_error_ptr
		PUBLIC	rate_and_delay_together
		PUBLIC	CRLF
		PUBLIC	Invalid_switch
		PUBLIC	rightmost
		PUBLIC	leftmost
		PUBLIC	noretry
		PUBLIC	infinite
		PUBLIC	left
		PUBLIC	right
		PUBLIC	cpmsg8_pr
		PUBLIC	cpmsgxx_query
		PUBLIC	cpmsgxx_prep
		PUBLIC	cpmsgxx_select
		PUBLIC	cpmsgxx_refresh
		PUBLIC	cpmsg17_writ
		PUBLIC	cpmsg13_act
		PUBLIC	cpmsg13_sys

PRINTF_CODE	ENDS
		END
