
;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป				   ;AN000;
;บ											  บ				   ;AN000;
															   ;AN000;
;  AC000 - P3200: Was displaying a message that Sam Nunn had deleted from the
;		  USA.MSG file because it looked like a common message.  Now
;		  I use a different (better) message.

;  AX001 - P3976: Need to have all pieces of messages in MODE.SKL so have to
;		  implement the SYSGETMSG method of getting addressability to
;		  the pieces.  This means that the code does a SYSGETMSG call
;		  which returns a pointer (DS:SI) to the message piece.  The
;		  address is then put in the sublist block for the message
;		  being issued.


;บ											  บ				   ;AN000;
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ				   ;AN000;
															   ;AN000;
Stdin			equ	0
StdOut			equ	1
StdErr			equ	2
No_Handle		equ	-1


Msg_Ser_Class		equ	0
Ext_Err_Class		equ	1
Parse_Error_Class	equ	2
Utility_Msg_Class	equ	0FFh

N_A		 equ	 0

No_Input		equ	0
DOS_keyb_input		EQU   01
clear_buffer		EQU   0C0H
;
;*****************************************************************************
; Macro's
;*****************************************************************************
;

Define_Msg macro Message_Name			;				;AN000;
						;
Create_Msg Message_Name,Message_Number,Handle,Sublist,Count,Class,Function,Input;AN000;
						;
	endm					;				;AN000;

;-----------------------------------------------------------------------------

Create_Msg macro Parm1,Parm2,Parm3,Parm4,Parm5,Parm6,Parm7,Parm8		;AN000;

Parm1	label	word				;				;AN000;
	dw	Parm2				;				;AN000;
	dw	Parm3				;				;AN000;
	dw	OFFSET Parm4			       ;			       ;AN000;
	dw	Parm5				;				;AN000;
	db	Parm6				;				;AN000;
	db	Parm7				;				;AN000;
	dw	Parm8				;				;AN000;
	endm					;				;AN000;


;
;*****************************************************************************
; Message Description Tables
;*****************************************************************************
;

;---------------------- 			;
Message_Number	= 3				;CR,LF,"Invalid switch - %1",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_invalid_switch
Count		= 1				;				;AN000;
Class		= Parse_Error_Class		;resident in COMMAND		;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	invalid_switch		;				;AN000;
;---------------------- 			;
Message_Number	= 1				;COMMON1 "Incorrect DOS Version"
Handle		= STDERR			;				;AN000;
Sublist 	= No_Replace		;			       ;AN000;
Count		= N_A				;				;AN000;
Class		= msg_ser_Class 	    ;				    ;AN000;
Function	= No_Input			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	wrong_version		;				;AN000;
;---------------------- 			;
Message_Number	= 2				;				;AN000;
Handle		= STDERR			;extend1			;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= ext_err_Class 	    ;				    ;AN000;
Function	= No_Input			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgOutOfMemory		;				;AN000;
;---------------------- 			;
Message_Number	= 3				;CR,LF,"Must specify COM1, COM2, COM3 or COM4",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Input			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	com1_or_com2		;				;AN000;
;---------------------- 			;
Message_Number	= 4				;CR,LF,"Resident portion of MODE loaded",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Input			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	moved_msg		;				;AN000;
;---------------------- 			;
Message_Number	= 5				;CR,LF,"Illegal device name",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_err1			;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Input			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	ERR1			;				;AN000;
;---------------------- 			;
Message_Number	= 6				;CR,LF,"Printer error",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Input			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	ERR2			;				;AN000;
;---------------------- 			;
Message_Number	= 7				;CR,LF,"LPT%1: set for 80",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_PT80			;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Input			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	PT80			;				;AN000;
;---------------------- 			;
Message_Number	= 8				;CR,LF,"LPT%1: set for 132",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_PT132 		;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	PT132			;				;AN000;
;---------------------- 			;
Message_Number	= 9				;CR,LF,"Printer lines per inch set",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg   PTLINES			;				;AN000;
;---------------------- 			;
Message_Number	= 10				;CR,LF,"Invalid baud rate specified",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	RATEMSG 		;				;AN000;
;---------------------- 			;
Message_Number	= 11				;CR,LF,"COM%1: %2,%3,%4,%5,%6",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_INITMSG		;				;AN000;
Count		= 6				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	INITMSG 		;				;AN000;
;---------------------- 			;
Message_Number	= 12				;"0123456789",EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	NUMBERS 		;				;AN000;
;---------------------- 			;
Message_Number	= 13				;CR,LF,"Do you see the %1? (",YES,"/",NO,")",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_SHIFT_MSG		;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= clear_buffer+DOS_keyb_input	;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	SHIFT_MSG		;				;AN000;
;---------------------- 			;
;Message_Number  = 14				 ;CR,LF,"Invalid parameters",BEEP,CR,LF,EOM
;Handle 	 = STDOUT			 ;				 ;AC000;
;Sublist	 = No_replace			 ;				 ;AC000;
;Count		 = N_A				 ;****	Now use message 54 ***** ;AC000;
;Class		 = Utility_Msg_Class		 ;				 ;AC000;
;Function	 = No_Function			 ;				 ;AC000;
;Input		 = N_A				 ;				 ;AC000;
;	 Define_Msg	 MSGI			 ;				 ;AC000;
;---------------------- 			;
Message_Number	= 15				;CR,LF,"LPT%1: rerouted to COM%2:",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_REDIRMSG		;				;AN000;
Count		= 2				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	REDIRMSG		;				;AN000;
;---------------------- 			;
Message_Number	= 16				;CR,LF,"LPT%1: not rerouted",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_NOTREMSG		;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	NOTREMSG		;			      ;AN000;
;---------------------- 			;
Message_Number	= 17				;CR,LF,"%1 retry on parallel printer time-out",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_RETPARTO		;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	RETPARTO		;				;AN000;
;---------------------- 			;
Message_Number	= 18				;CR,LF,"      Unable to shift screen %1",CR,LF,BEEP,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_CANT_SHIFT		;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	CANT_SHIFT		;				;AN000;
;---------------------- 			;
Message_Number	= 19				;CR,LF,"Invalid parameter - %1",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_invalid_parameter
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	invalid_parameter      ;			       ;AN000;
;---------------------- 			;
Message_Number	= 20				;CR,LF,'Invalid number of parameters',BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
     Define_Msg   invalid_number_of_parameters	;			     ;AN000;
;---------------------- 			;
Message_Number	= 21				;CR,LF,'NET 042: Unable to do requested command',BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	net_error		;				;AN000;
;---------------------- 			;
Message_Number	= 22				;CR,LF,'Infinite retry not supported on Network printer',beep,cr,lf,eom
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	not_supported		;				;AN000;
;---------------------- 			;
Message_Number	= 23				;CR,LF,"Failure to access Codepage Font File",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg1			;				;AN000;
;---------------------- 			;
Message_Number	= 24				;CR,LF,"Failure to access device: %1",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_cpmsg2		;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	cpmsg2			;				;AN000;
;---------------------- 			;
Message_Number	= 25				;CR,LF,"Device or codepage missing from font file",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg3			;				;AN000;
;---------------------- 			;
Message_Number	= 26				;CR,LF,"Font file contents invalid",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg4			;				;AN000;
;---------------------- 			;
Message_Number	= 27				;CR,LF,"Previously prepared codepage replaced",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg5
;---------------------- 			;
Message_Number	= 28				;CR,LF,"Active codepage for device %1 is %2",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_cpmsg6		;				;AN000;
Count		= 2				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg6
;---------------------- 			;
Message_Number	= 29				;CR,LF,"Device %1 not prepared",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_cpmsg7		;				;AN000;
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg7
;---------------------- 			;
Message_Number	= 30				;"%1 codepages:",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_cpmsg8
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg8
;---------------------- 			;
Message_Number	= 31				;"  Codepage %1",CR,LF,EOM       ;FILLED IN BY "QUERY" ROUTINE WITH CODEPAGE ID
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_cpmsg9
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg9
;---------------------- 			;
Message_Number	= 32				;CR,LF,"MODE %1 Codepage function completed",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_cpmsg10		;				;AN000;
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg10
;---------------------- 			;
Message_Number	= 33				;CR,LF,"Current Codepage settings:",CR,LF,EOM  ;table header
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg12
;---------------------- 			;
Message_Number	= 34				;"   %1 - %2 Codepage",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_cpmsg13
Count		= 2
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg13
;---------------------- 			;
Message_Number	= 35				;"  Codepage not prepared",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= no_replace
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg14
;---------------------- 			;
Message_Number	= 36				;"Codepage operation not supported on this device",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg15
;---------------------- 			;
Message_Number	= 37				;"No codepage has been SELECTED",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg16
;---------------------- 			;
Message_Number	= 38				;"Device error during %1",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_cpmsg17
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg17
;---------------------- 			;
Message_Number	= 39				;"Codepage not prepared",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg18
;---------------------- 			;
Message_Number	= 40				;CR,LF,"Current keyboard does not support this Codepage",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg19
;---------------------- 			;
Message_Number	= 41				;CR,LF,"Error during read of font file",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg20
;---------------------- 			;
Message_Number	= 42				;CR,LF,"Unable to perform REFRESH operation",BEEP,CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg21
;---------------------- 			;
Message_Number	= 43				;CR,LF
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    CRLF
;---------------------- 			;
Message_Number	= 44				;"Status for device %1:",CR,LF,EOM
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_status_for_device
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    status_for_device
;---------------------- 			;
Message_Number	= 45				;"------------------" underline for status report header
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    long_underline
;---------------------- 			;
Message_Number	= 46				;"----" underline for "CON:"
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    four_char_underline
;---------------------- 			;
Message_Number	= 47				;"-----" underline for "COMX:" and "LPTX:"
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    five_char_underline
;---------------------- 			;
Message_Number	= 48				;"LINES=%1"
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_LINES_equal		;				;AN000;
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    LINES_equal_msg
;---------------------- 			;
Message_Number	= 49				;"COLUMNS=%1"
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_COLUMNS_equal 		;				;AN000;
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    COLUMNS_equal_msg
;---------------------- 			;
Message_Number	= 50				;CR,LF,"RATE and DELAY must be specified together",BELL,CR,LF
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    RATE_and_DELAY_together
;---------------------- 			;
Message_Number	= 51				;"RATE=%1"
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_RATE_equal		       ;			       ;AN000;
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    RATE_equal
;---------------------- 			;
Message_Number	= 52				;"DELAY=%1"
Handle		= STDOUT			;				;AN000;
Sublist 	= sublist_DELAY_equal			;				;AN000;
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    DELAY_equal
;---------------------- 			;
Message_Number	= 53				;"Function not supported on this machine"
Handle		= STDOUT			;				;AN000;
Sublist 	= Sublist_Not_supported       ; 			      ;AN000;
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    Function_not_supported
;---------------------- 			;
Message_Number	= 54				;"Required font not loaded"
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    Required_font_not_loaded
;---------------------- 			;
Message_Number	= 55				;"ANSI.SYS must be installed to perform requested function",BELL,CR,LF
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    ANSI_not_loaded
;---------------------- 			;
Message_Number	= 56				;CR,LF,"Baud rate required",BELL,CR,LF
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    Baud_rate_required
;---------------------- 			;
Message_Number	= 57				;"RETRY=%1",CR,LF
Handle		= STDOUT			;				;AN000;
Sublist 	= Sublist_retry_equal	      ; 			      ;AN000;
Count		= 1
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    retry_equal
;---------------------- 			;
Message_Number	= 58				;"Syntax error - ",CR,LF
Handle		= STDOUT			;				;AN000;
Sublist 	= Sublist_syntax_error	      ; 			      ;AN000;
Count		= 1
Class		= Utility_msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    syntax_error
;---------------------- 			;

Message_Number	= 59 ;"rightmost 9"                  ;AN001;
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    rightmost 		    ;AN001;
;---------------------- 			;
Message_Number	= 60 ;"leftmost 0"                   ;AN001;LEFTMOST        DB
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    leftmost
;---------------------- 			;
;RETPARTO - CR,LF,;"%s retry on parallel printer time-out",CR,LF,EOM

Message_Number	= 61 ;"No"                           ;AN001;NORETRY         DB
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    noretry
;---------------------- 			;
Message_Number	= 62 ;"Infinite"                     ;AN001;INFINITE        DB
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    infinite
;---------------------- 			;
;CANT_SHIFT - CR,LF,;"      Unable to shift screen %s",CR,LF,BEEP,EOM

Message_Number	= 63 ;"left"                                ;AN001;LEFT            DB
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    left
;---------------------- 			;
Message_Number	= 64 ;"right"                               ;AN001;RIGHT           DB
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    right
;---------------------- 			;
;CPMSG8 	DB    ;"%S codepages:",CR,LF,EOM

Message_Number	= 65 ;"Hardware"             ;AN001;CPMSG8_HW      DB
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg8_hw
;---------------------- 			;
Message_Number	= 66 ;"Prepared"             ;AN001;CPMSG8_PR      DB
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg8_pr
;---------------------- 			;
;CPMSG10	 DB    ;"MODE %S Codepage function completed",CR,LF,EOM
;CPMSG17	 DB	;"Device error during %S",BEEP,CR,LF,EOM

Message_Number	= 67 ;"status"          ;AN001;CPMSG17_QUERY   CPMSG10_QUERY
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsgxx_query
;---------------------- 			;
Message_Number	= 68 ;"prepare"         ;AN001;CPMSG17_PREP    CPMSG10_DES
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsgxx_prep
;---------------------- 			;
Message_Number	= 69 ;"select"          ;AN001;CPMSG17_ACT     CPMSG10_SELECT
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsgxx_select
;---------------------- 			;
Message_Number	= 70 ;"refresh"         ;AN001;CPMSG17_REFRESH CPMSG10_REFRESH
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsgxx_refresh
;---------------------- 			;

;CPMSG17	 DB	;"Device error during %S",BEEP,CR,LF,EOM

Message_Number	= 71 ;"write of font file to device",EOM   ;AN001;CPMSG17_WRIT
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg17_writ
;---------------------- 			;
;CPMSG13	 DB    ;"   %D - %S Codepage",CR,LF,EOM

Message_Number	= 72 ;"selected"        ;AN001;CPMSG13_ACT
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg13_act
;---------------------- 			;
Message_Number	= 73 ;"system"          ;AN001;CPMSG13_SYS
Handle		= STDOUT			;				;AN000;
Sublist 	= No_Replace		      ; 			      ;AN000;
Count		= N_A
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg    cpmsg13_sys
