	PAGE	,132
	SUBTTL	DOS - Message Retriever - SYSTEM CONTROL file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS -- Message Retriever
;; (c) Copyright 1988 Microsoft
;;
;; File Name:	SYSMSG.INC
;; ----------
;;
;; Description: Message retriever functions are included into source code
;; ------------ by referencing a MSG_SERVICES macro. That macro is defined
;;		here as well as the logic to include necessary .ASM and .INC
;;		files.
;;
;;
;; Documentation Reference:
;; ------------------------
;;		DOS -Message Retriever I0 Document - Feb. ?? 1987
;;		DOS -Message Retriever I1 Document - Mar. ?? 1987
;;		DOS -Message Retriever I2 Document - Mar. ?? 1987
;;		DOS -Final Functional Specification Document - Mar ?? 1987
;;
;; Procedures Contained in This File:
;; ---------------------------------
;;		None
;;
;; Include Files Required:
;; -----------------------
;;		MSGSERV.INC	   := All message services
;;		????		   := ????
;;
;; External Procedure References:
;; ------------------------------
;;		None
;;
;; Linkage Instructions:
;; --------------------
;;		None
;;
;; Change History:
;; ---------------
;;		CREATED 	March, 1987	RPS
;;
;; Psuedocode:
;; -----------
;;		None
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
INCLUDE        VERSIONA.INC	       ;;AN003;;

FALSE	       = 0		       ;;
TRUE	       = NOT FALSE	       ;;    List message services and flags
				       ;;

; Control Characters For Message Skeleton file

NULL			EQU	00H    ;; Null
BELL			EQU	07H    ;; Bell
TAB			EQU	09H    ;; Tab
LF			EQU	0AH    ;; Line Feed
HOME			EQU	0BH    ;; Home
FORMFD			EQU	0CH    ;; Form Feed
CR			EQU	0DH    ;; Carriage Return
COLON			EQU	3AH    ;; Colon

; SYSDISPMSG and SYSGETMSG Equates

MSG_SER_CLASS		EQU	00H    ;; Message Service Class (reserved)
EXT_ERR_CLASS		EQU	01H    ;; DOS Extended error class
PARSE_ERR_CLASS 	EQU	02H    ;; Parse error class
UTILITY_MSG_CLASS	EQU	0FFH   ;; Utility message class

NO_HANDLE		EQU	0FFFFH ;; No handle specified (Use DOS functions 01H-09H only)

NO_REPLACE		EQU	0000H  ;; No replacable parameters

; SUBLIST Equates

  Sublist_Length	EQU	11     ;; Length of sublist structure
  Reserved		EQU	0      ;; Reserved byte field

  Left_Align		EQU	0      ;;00xxxxxx
  Right_Align		EQU	80h    ;;10xxxxxx

  Char_type		EQU	0      ;;axxx0000 - Character type
  Char_Field_Char	EQU	0      ;;a0000000
  Char_Field_ASCIIZ	EQU	10h    ;;a0010000

  Unsgn_Bin_Type	EQU	01h    ;;axxx0001 - Unsigned Binary to Decimal character
  Unsgn_Bin_Byte	EQU	11h    ;;a0010001
  Unsgn_Bin_Word	EQU	21h    ;;a0100001
  Unsgn_Bin_DWord	EQU	31h    ;;a0110001

  Sgn_Bin_Type		EQU	02h    ;;axxx0010 - Signed Binary to Decimal character
  Sgn_Bin_Byte		EQU	12h    ;;a0010010
  Sgn_Bin_Word		EQU	22h    ;;a0100010
  Sgn_Bin_DWord 	EQU	32h    ;;a0110010

  Bin_Hex_Type		EQU	03h    ;;axxx0011 - Unsigned Binary to Hexidecimal character
  Bin_Hex_Byte		EQU	13h    ;;a0010011
  Bin_Hex_Word		EQU	23h    ;;a0100011
  Bin_Hex_DWord 	EQU	33h    ;;a0110011

  Date_Type		EQU	04h    ;;axxx0100 - Date to character using current country format
  Date_MD		EQU	14h    ;;a0010100
  Date_MDY_2		EQU	24h    ;;a0100100
  Date_MDY_4		EQU	34h    ;;a0110100

  Time_Cty_Type 	EQU	05h    ;;axxx0101 - Time to character using current country format
  Time_HHMM_Cty 	EQU	05h    ;;a0000101
  Time_HHMMSS_Cty	EQU	15h    ;;a0010101
  Time_HHMMSSHH_Cty	EQU	25h    ;;a0100101

  Time_24_Type		EQU	06h    ;;axxx0110 - Time to character using 24 hour format
  Time_HHMM_24		EQU	06h    ;;a0000110
  Time_HHMMSS_24	EQU	16h    ;;a0010110
  Time_HHMMSSHH_24	EQU	26h    ;;a0100110

  $M_EXTPAR_Type	EQU	08h    ;;axxx1000 - Special case for extended parse replace format

NO_INPUT		EQU	00H    ;; No input characters
DOS_KEYB_INP		EQU	01H    ;; DOS INT 21H - AH=01H := Keyboard Input
DOS_DIR_CON_INP 	EQU	07H    ;; DOS INT 21H - AH=07H := Direct Console Input Without Echo
DOS_CON_INP		EQU	08H    ;; DOS INT 21H - AH=08H := Console Input Without Echo (Check CTL-BK)
DOS_BUF_KEYB_INP	EQU	0AH    ;; DOS INT 21H - AH=0AH := Buffered Keyboard Input
DOS_CLR_KEYB_BUF	EQU	0CH    ;; DOS INT 21H - AH=0CH := Clear keyboard buffer
DOS_WRITE_HANDLE	EQU	40H    ;; DOS INT 21H - AH=40H := Write to a DOS handle
DOS_DISP_STRING 	EQU	09H    ;; DOS INT 21H - AH=09H := Display $ terminated string
DOS_DISP_CHAR		EQU	02H    ;; DOS INT 21H - AH=02H := Display Character
LOWEST_4CH_VERSION	EQU	0002H  ;; First DOS version to allow AH = 4CH Exit (VERSION 2.00)

DOS_GET_DBCS_INFO	EQU   6300H    ;; DOS INT 21H - AX=6507H := Get DBCS Vector Table
DOS_GET_EXT_ERROR	EQU	59H    ;; DOS INT 21H - AH=59H := Get Extended Error
DOS_GET_EXT_ERROR_BX	EQU	00H    ;; DOS INT 21H - BX=0000H := Version 0

DOS_EXTENDED_OPEN	EQU   6C00H    ;AN003; DOS INT 21H - AX=6C00H := Extended Open
NO_CRIT_OPEN		EQU   2000H    ;AN003; Extended Open Mode bit
NOT_EX_FAIL_EX_OPEN	EQU   0101H    ;AN003; Extended Open Flag
DOS_LSEEK_FILE		EQU   4200H    ;AN003; DOS INT 21H - AX=4200H := LSEEK file
DOS_READ_BYTE		EQU	3FH    ;AN003; DOS INT 21H - AH=3FH   := Read byte block
DOS_CLOSE_FILE		EQU	3EH    ;AN003; DOS INT 21H - AH=3EH   := Close file handle

IFSFUNC_INSTALL_CHECK	EQU   0500H    ;AN006; IFSFUNC Installation Check
IFS_GET_ERR_TEXT	EQU   0502H    ;AN006; IFSFUNC Get Extended Error Text
IFSFUNC_INSTALLED	EQU    0FFH    ;AN006; Return code if IFSFUNC is installed

EXT_ERR_39		EQU	39     ;; Insufficent Disk Space EXTENDED ERROR (changed from hex to decimal - eg d201)
ERROR_CLASS_39		EQU	01H    ;;   Error Class = 1
ACTION_39		EQU	04H    ;;   Suggested Action = 4
LOCUS_39		EQU	01H    ;;   Locus = 1

DOS_GET_COUNTRY 	EQU	38H    ;; DOS INT 21H - AH=38H := Get Country Dependant Information
DOS_GET_VERSION 	EQU	30H    ;; DOS INT 21H - AH=30H := Get DOS Version number
DOS_IOCTL_GET_INFO	EQU	4400H  ;; DOS INT 21H - AH=4400H := I/O control for devices
DOS_IOCTL_SET_INFO	EQU	4401H  ;; DOS INT 21H - AH=4401H := I/O control for devices
DOS_GET_EXT_PARSE_ADD	EQU	122EH  ;; DOS INT 2FH - AX=122EH := Get Extended/Parse error address
DOS_GET_EXTENDED	EQU	00     ;; DOS INT 2FH - AX=122EH - DL=00 := Get Extended address
DOS_GET_PARSE		EQU	02     ;; DOS INT 2FH - AX=122EH - DL=02 := Get Parse address
DOS_GET_CRITICAL	EQU	04     ;; DOS INT 2FH - AX=122EH - DL=04 := Get Critical address
DOS_GET_FILE		EQU	06     ;; DOS INT 2FH - AX=122EH - DL=06 := Get File system dependant
DOS_GET_ADDR		EQU	08     ;; DOS INT 2FH - AX=122EH - DL=08 := Get Address of READ_DISK_PROC
DOS_SET_ADDR		EQU	09     ;; DOS INT 2FH - AX=122EH - DL=09 := Set Address of READ_DISK_PROC
LOW_NIB_MASK		EQU	0FH    ;; Mask out the high byte
DOS_CLR_KEYB_BUF_MASK	EQU	0C0H   ;; Check if high nibble is C Hex
$M_CON_INP		EQU	-1     ;; If DOS INT 21H Function 06H - DL := 0FFH for input
$M_CRIT_LO		EQU	19     ;; First Extended Error considered CRITICAL
$M_CRIT_HI		EQU	39     ;; Last Extended Error considered CRITICAL (EG - D191)
$M_AM			EQU	"a"    ;; Time format AM indicator
$M_PM			EQU	"p"    ;; Time format PM indicator
$M_NEG_SIGN		EQU	"-"    ;; Signed decimal number format negative indicator
$M_DEF_TIME_FORM	EQU	 1     ;; Default Time format - 24 hour
$M_DEF_DATE_FORM	EQU	 0     ;; Default Time format - 0 := USA format
$M_DEF_TIME_SEP 	EQU	":"    ;; Default Time separator - ":"
$M_DEF_DATE_SEP 	EQU	"-"    ;; Default Time separator - "-"
$M_DEF_DECI_SEP 	EQU	"."    ;; Default Time hundreds separator - "."
$M_TIMEDATE_PAD 	EQU	"0"    ;; Time/Date PAD character - "0" (ie 12:03p)
$M_MAX_2_YEAR		EQU	99     ;; Maximum 2 digit year
$M_SINGLE_CHAR		EQU	1      ;; A single character is this long      ^
$M_SPECIAL_CASE 	EQU	30H    ;; Special case for replacable parameters %0
$M_UNLIM_W		EQU	0      ;; Unlimited width character
$M_COMMA		EQU	","    ;; Default Thousand separate
$M_CR_LF		EQU	0A0DH  ;; Default CR/LF
$M_SPACE_HYP		EQU	"- "   ;; Default Space/Hyphan
$M_SPACE		EQU	" "    ;; Default Space
$M_NULL 		EQU	0      ;; Null
$M_FIRST_THOU		EQU	3      ;; Location of first thousand separator
$M_SECOND_THOU		EQU	6      ;; Location of second thousand separator
$M_THIRD_THOU		EQU	9      ;; Location of third thousand separator
$M_BASE10		EQU	10     ;; Base 10 for arthmetic
$M_BASE16		EQU	16     ;; Base 16 for arthmetic
$M_CLASS_NOT_EXIST	EQU	 0     ;; Does class exist?
$M_TERMINATING_FLAG	EQU	-1     ;; Is there any more classes?
$M_ADDR_SZ_NEAR 	EQU	2      ;; Size to increment if NEAR
$M_ADDR_SZ_FAR		EQU	4      ;; Size to increment if FAR
$M_SL			EQU   DS:[SI]  ;; Refer to SUBLIST as $M_SL
$M_NO_HANDLE		EQU	-1     ;; No handle flag
$M_TEMP_BUF_SZ		EQU	64     ;; Size of temporary buffer	 ;AN003;
$M_NEXT_DBCS_VECTOR	EQU	2      ;; Amount to increment to get next vector
$M_DBCS_TERM		EQU    0000    ;; DBCS vector table terminating flag
$M_SPECIAL_MSG_NUM	EQU    0FFFFH  ;; Special generic message number
$M_CRLF_SIZE		EQU    2       ;; Size of the CR LF message
$M_NO_CRLF_MASK 	EQU  10000000B ;; Mask to supress CR LF
$M_ONE_REPLACE		EQU    1       ;; Indicate one replacement
$M_CRIT_ERR_MASK	EQU  00000001B ;; Mask to allow EOF/EOI Crit error
				       ;;
$M_ALIGN_MASK		EQU  10000000b ;; Mask for align
$M_TYPE_MASK		EQU  00001111b ;; Mask for types
$M_SIZE_MASK		EQU  00110000b ;; Mask for types
$M_TIME_MASK		EQU  00000001b ;; Mask for TIME
$M_DATE_MASK		EQU  00010000b ;; Mask for TIME
$M_BYTE 		EQU  00010000b ;; BYTE indicator
$M_WORD 		EQU  00100000b ;; WORD indicator
$M_DWORD		EQU  00110000b ;; DWORD indicator

; Standard reserved DOS handles

STDIN			EQU	0000H  ;; Standard Input device handle
STDOUT			EQU	0001H  ;; Standard Output device handle
STDERR			EQU	0002H  ;; Standard Error Output device handle
STDAUX			EQU	0003H  ;; Standard Auxiliary device handle
STDPRN			EQU	0004H  ;; Standard Printer device handle

; Reserved Message Service equates

NEARmsg 		 =	TRUE   ;; \
NOVERCHECKmsg		 =	FALSE  ;;  |
MSGDATA 		 =	FALSE  ;;  |
FARmsg			 =	FALSE  ;;  |
GETmsg			 =	FALSE  ;;  |
LOADmsg 		 =	FALSE  ;;  |
DISPLAYmsg		 =	FALSE  ;;   } Set default cases
SETSTDIO		 =	FALSE  ;;  |
NOCHECKSTDIN		 =	FALSE  ;;  |
NOCHECKSTDOUT		 =	FALSE  ;;  |
DISK_PROC		 =	FALSE  ;;  |			       ;AN003;
INPUTmsg		 =	FALSE  ;;  |
CHARmsg 		 =	FALSE  ;;  |
NUMmsg			 =	FALSE  ;;  |
TIMEmsg 		 =	FALSE  ;;  |
DATEmsg 		 =	FALSE  ;; /

IF1				       ;;
COMR			 =	FALSE  ;;  COMMAND.COM Cases (resident)
COMT			 =	FALSE  ;;		     (transient)
ENDIF				       ;;

$M_STRUC		 =	TRUE   ;; Internal message service defaults
$M_LOAD 		 =	TRUE   ;;
$M_SUBS 		 =	TRUE   ;;
$M_REPLACE		 =	TRUE   ;;
$M_REPL_DONE		 =	FALSE  ;;
$M_CHAR_ONLY		 =	TRUE   ;;
$M_PARSE_FLAG		 =	TRUE   ;;
$M_EXT_ERR_FLAG 	 =	TRUE   ;;
$M_MSGDATA_ONLY 	 =	TRUE   ;;
$M_END			 =	FALSE  ;;
$M_EXT_CLS		 =	TRUE   ;;
$M_PAR_CLS		 =	TRUE   ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	$M_POPF 	     Macro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

$M_POPF    MACRO
	   LOCAL   $M_MYRET
	   JMP	   $+3
$M_MYRET   LABEL   NEAR
	   IRET
	   PUSH    CS
	   CALL    $M_MYRET
ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Message Retreiver requests
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;
MSG_UTILNAME  Macro   utilname	       ;
				       ;
   INCLUDE &utilname.CTL	       ;  Include the control file for the utility
   $M_STRUC = TRUE		       ;
   INCLUDE MSGSERV.ASM		       ;  Get structure definitions
				       ;
ENDM				       ;
				       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	MSG_SERVICES		Macro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					  ;
MSG_SERVICES Macro   varlist		  ;  MACRO used in source routine
					  ;
   $M_SERVICE = FALSE			  ;  Reset service flag
   IRP	   var,<varlist>		  ;  FOR each variable in the list
     $M_INCLUDE = TRUE			  ;  Reset include flag
					  ;	For each service predefined

IRP  serv,<MSGDATA,LOADmsg,NOVERCHECKmsg,DISPLAYmsg,GETmsg,INPUTmsg,CHARmsg,NUMmsg,TIMEmsg,DATEmsg,NEARmsg,FARmsg,COMR,COMT>

	 IFDIF <var>,<serv>		  ;	  IF it IS a service (defined above)
	 ELSE				  ;
	   IFDIF <var>,<MSGDATA>	  ;	    IF it is NOT the message data space request
	     $M_MSGDATA_ONLY = FALSE	  ;	       Instruct the assembler to include all services
	   ENDIF			  ;	    ENDIF
	   IRP	repl,<CHARmsg,NUMmsg,TIMEmsg,DATEmsg>  ; IF it is a replace service
	     IFIDN  <var>,<repl>	  ;
	       $M_REPLACE = TRUE	  ;	       Set replace flag
	     ENDIF			  ;
	   ENDM 			  ;
	   serv = TRUE			  ;	    Let the assembler know about the service
	   $M_SERVICE = TRUE		  ;	    Let the macro know it was a service
	   $M_INCLUDE = FALSE		  ;	    Let the macro know it wasn't a class
	 ENDIF				  ;	  ENDIF
      ENDM				  ;	NEXT service

MSG_SERVICES2  <varlist>
					  ; Continue further checks (If we add any more predefined
					  ;  function to the above IRP command, it generates a
					  ;  syntax error. We must continue the processing in another
					  ;  MACRO called MSG_SERVICES2)

      IF $M_INCLUDE			  ;	IF message class was requested
	 $M_INC var			  ;	   Include it as a message class
      ENDIF				  ;	ENDIF
   ENDM 				  ;  NEXT variable
					  ;
   IF $M_SERVICE			  ;	IF it any services were requested THEN
     INCLUDE MSGSERV.ASM		  ;	   THEN include module to get service
   ENDIF				  ;	ENDIF

ENDM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	MSG_SERVICES2		Macro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					  ;
MSG_SERVICES2 Macro   varlist2		  ;  MACRO used in source routine
					  ;
					    ;  FOR each variable in the list
   IRP	   var2,<varlist2>
						       ; For each service predefined
      IRP  serv2,<SETSTDIO,NOCHECKSTDIN,NOCHECKSTDOUT,DISK_PROC>
					    ;AN003; IF it IS a service (defined above)
	 IFDIF <var2>,<serv2>
	 ELSE				  ;
	   serv2 = TRUE 		   ;	     Let the assembler know about the service
	   $M_SERVICE = TRUE		  ;	    Let the macro know it was a service
	   $M_INCLUDE = FALSE		  ;	    Let the macro know it wasn't a class
	 ENDIF				  ;	  ENDIF
      ENDM				  ;	NEXT service
   ENDM 				  ;  NEXT variable
ENDM					  ;
					  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; $M_INC		Macro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						 ;
$M_INC	Macro	ext				 ;
						 ;
INCLUDE &ext					 ;
						 ;
ENDM						 ;
						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; $M_BUILD_PTRS	Macro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						 ;
$M_BUILD_PTRS Macro nummsg			 ;
						 ;
    $M_INDEX =	    0				 ;
IF COMR 				     ; IF this is resident COMMAND.COM
    $M_MAKE_COMR			     ;
ELSE						 ; ELSE
  IF COMT				     ;	 IF this is transient COMMAND.COM
    $M_MAKE_COMT			     ;
  ELSE						 ;   ELSE
						 ;
    $M_INDEX =	    0				 ;
    $M_COUNT =	    0				 ;     Build normal utilities
						 ;
    REPT    nummsg				 ;
    $M_COUNT =	    $M_COUNT + 1		 ;
    $M_MAKE %$M_COUNT				 ;
    ENDM					 ;
  ENDIF 					 ;
ENDIF						 ;
ENDM						 ;
						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; $M_MAKE		Macro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						 ;
$M_MAKE Macro $m_append 			 ;
IF  FARmsg					 ;
    CALL    FAR PTR $M_CLS_&$m_append		 ;  Get addressibilty to class &$M_APPEND (ES:DI)
    MOV     WORD PTR $M_RT.$M_CLASS_ADDRS+$M_INDEX+2,ES ;  Move into first avaliable table location
    MOV     WORD PTR $M_RT.$M_CLASS_ADDRS+$M_INDEX,DI ;
ELSE						 ;
    CALL    $M_CLS_&$m_append			 ;  Get addressibilty to class &$M_APPEND (ES:DI)
    MOV     WORD PTR $M_RT.$M_CLASS_ADDRS+$M_INDEX,DI ;
ENDIF						 ;
$M_INDEX =  $M_INDEX + 4			 ;  Set next available table location
						 ;
ENDM						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; $M_MAKE_COMR     Macro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						 ;
$M_MAKE_COMR   macro			     ;
						 ;
    CALL    $M_CLS_3				 ;  Get addressibilty to class A
    MOV     WORD PTR $M_RT.$M_CLASS_ADDRS+$M_INDEX,DI ;
$M_INDEX =  $M_INDEX + 4			 ;  Set next available table location
						 ;
    CALL    $M_CLS_4				 ;  Get addressibilty to class B
    MOV     WORD PTR $M_RT.$M_CLASS_ADDRS+$M_INDEX,DI ;
$M_INDEX =  $M_INDEX + 4			 ;  Set next available table location
						 ;
    CALL    $M_CLS_5				 ;  Get addressibilty to class C
    MOV     WORD PTR $M_RT.$M_CLASS_ADDRS+$M_INDEX,DI ;
$M_INDEX =  $M_INDEX + 4			 ;  Set next available table location
						 ;
    CALL    $M_CLS_6				 ;  Get addressibilty to class D
    MOV     WORD PTR $M_RT.$M_CLASS_ADDRS+$M_INDEX,DI ;
$M_INDEX =  $M_INDEX + 4			 ;  Set next available table location
						 ;
    CALL    $M_CLS_7				 ;  Get addressibilty to class E
    MOV     WORD PTR $M_RT.$M_CLASS_ADDRS+$M_INDEX,DI ;
$M_INDEX =  $M_INDEX + 4			 ;  Set next available table location
						 ;
ENDM						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; $M_MAKE_COMT     Macro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						 ;
$M_MAKE_COMT  macro			     ;
						 ;
    CALL    $M_CLS_8				 ;  Get addressibilty to class A
    MOV     WORD PTR $M_RT.$M_CLASS_ADDRS+$M_INDEX,DI ;
$M_INDEX =  $M_INDEX + 4			 ;  Set next available table location
						 ;
ENDM						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
