	PAGE	,132			;
TITLE	XCPYINIT - XCOPY INITIALIZATION PROGRAM - Ver. 4.00

;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: XCPYINIT
;
; DESCRIPTIVE NAME: Called by XCOPY(MAIN) to perform initialization
;		    functions.
;
; FUNCTION:  Performs Parsing, Resource validation and Tagging, Error
;	     hooking and then returns to XCOPY(MAIN). This code will
;	     then be overwritten, providing additional memory for the
;	     copy process.
;
; ENTRY POINT: INIT
;
; INPUT: (DOS COMMAND LINE PARAMETERS)
;
;	      SOURCE OPERAND:			   TARGET OPERAND:
;
;	      [d:] [path] filename[.ext]	   [d:] [path] [filename[.ext]]
;		or
;	      [d:] path [filename[.ext]]
;		or
;	      d: [path] [filename[.ext]]
;
;	      SWITCHES:
;
;	      /A /D /E /M /P /S /V /W
;
; EXIT-NORMAL:	ERRORLEVEL_0 - This is the normal completion code.
;		ERRORLEVEL_2 - This is due to termination via Control-Break.
;		ERRORLEVEL_4 - This is used to indicate an error condition.
;
; INTERNAL REFERENCES:
;
;    ROUTINES:
;
;    DATA AREAS:
;
;
; EXTERNAL REFERENCES:
;
;    ROUTINES:
;
;    DATA AREAS:
;
;
; NOTES: This module should be processed with the SALUT pre-processor
;	 with the re-alignment not requested, as:
;
;		SALUT XCOPY,NUL,;
;
;	 To assemble these modules, the sequential
;	 ordering of segments may be used.
;
;	 For LINK instructions:
;		link  profile ..\lib
;
; REVISION HISTORY: A000 Version 4.00: add PARSER, System Message Handler,
;			 Remove the BELL char.,turn off APPEND during TREE
;			 search,Extended Attribute processing, Uppercasing
;			 and "Out Of Space" during write to standard out.
;		    NOTE: SEE XCOPY.SAL FOR TOTAL HISTORY.
;
;     Label: "The DOS XCOPY Utility"
;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Program Property of Microsoft"
;
;****************** END OF SPECIFICATIONS *****************************
;EQUATES
INCLUDE XCOPY.EQU
INCLUDE DOS.EQU
include versiona.inc

;
CSEG	SEGMENT PUBLIC			;PLACE HOLDER FOR INIT CODE
CSEG	ENDS

;******************************************************************************

DGROUP	GROUP	DSEG, DSEG_INIT
DSEG	SEGMENT PARA	PUBLIC
;--- EXTERNAL VARIABLES ---
EXTRN	ERRORLEVEL:BYTE
EXTRN	PSP_SEG:WORD			;PSP segment ** USE OF ES SHOULD BE EXAMINED FURTHER
EXTRN	SAV_DEFAULT_DRV:BYTE		;1 = A, 2 = B ...
EXTRN	SAV_DEFAULT_DIR:BYTE
EXTRN	SAV_S_DRV:BYTE
EXTRN	SAV_S_CURDIR:BYTE
EXTRN	SAV_T_DRV:BYTE
EXTRN	SAV_T_CURDIR:BYTE
EXTRN	TOP_OF_MEMORY:WORD
EXTRN	S_DRV_NUMBER:BYTE		;source drive number, 1 = A, 2 = B ...
EXTRN	T_DRV_NUMBER:BYTE		;target drive number
EXTRN	SO_DRIVE:BYTE			;AN000;S DRIVE LETTER SPECIFIED IN PARSE
EXTRN	S_DRV:BYTE
EXTRN	S_DRV_1:BYTE
EXTRN	S_DRV_PATH:BYTE 		;formal source drv, path
EXTRN	S_PATH:BYTE
EXTRN	T_DRV_PATH:BYTE 		;formal target drv, path
EXTRN	T_PATH:BYTE
EXTRN	TAR_DRIVE:BYTE			;AN000;T DRIVE LETTER SPECIFIED IN PARSE
EXTRN	PARMS:DWORD			;AN000;PARSER PARAMETER CONTROL BLOCK
EXTRN	CURRENT_PARM:WORD		;AN004;POINTER TO NEXT CMD LINE OPERAND
EXTRN	T_DRV:BYTE			;target drv letter
EXTRN	T_DRV_1:BYTE			;target drv letter
EXTRN	T_DRV_2:BYTE
EXTRN	S_FILE:BYTE			;source filename
EXTRN	T_FILENAME:BYTE
EXTRN	T_TEMPLATE:BYTE
EXTRN	DISP_S_PATH:BYTE		;input mirror image source path
EXTRN	DISP_T_PATH:BYTE		;input mirror image target path
EXTRN	BUFFER_PTR:WORD
EXTRN	BUFFER_BASE:WORD
EXTRN	BUFFER_LEFT:WORD
EXTRN	MAX_BUFFER_SIZE:WORD
EXTRN	MAX_CX:WORD
EXTRN	S_ARC_DRV:BYTE			;source drv, path for archieve bit handling
EXTRN	S_ARC_PATH:BYTE
EXTRN	T_MKDIR_LVL:BYTE		;# of target starting directories created.
EXTRN	MSG_NUM:WORD			;AN000;MESSAGE NUMBER
EXTRN	MSG_CLASS:BYTE			;AN000;MESSAGE CLASS
EXTRN	INPUT_FLAG:BYTE 		;AN000;TYPE INT21 USED FOR KBD INPUT
EXTRN	SUBST_COUNT:WORD		;AN000;MESSAGE SUBSTITUTION COUNT
EXTRN	SUBLIST1:DWORD			;AN000;MSG SUBLIST USED BY INIT & MAIN
;
EXTRN	MY_FLAG:BYTE
EXTRN	SYS_FLAG:BYTE
EXTRN	COPY_STATUS:BYTE
EXTRN	OPTION_FLAG:BYTE
;
EXTRN	INPUT_DATE:WORD
EXTRN	INPUT_TIME:WORD
;
;
DSEG	ENDS
;
DSEG_INIT SEGMENT PARA PUBLIC		;AN000;
;--- Local variables for INIT which will be free into memory after init.
;----include file(s)------
INCLUDE XINITMSG.EQU			;AN000;xcopy initialization, prompt msg
;----variables------------
S_INPUT_PARM DB 80 DUP (0)		;source image of input parm
T_INPUT_PARM DB 80 DUP (0)		;target image of input parm
T_TRANS_PATH DB 128 DUP (0)		;AN016;TARGET BUFFER FOR NAME TRANSLATE
S_TRANS_PATH DB 128 DUP (0)		;AN016;SOURCE BUFFER FOR NAME TRANSLATE

PUBLIC	PARM_FLAG
PARM_FLAG DB	0
;	first_parm_flag equ	01h	;first parm entered in input parm
;	second_parm_flag equ	 02h	;second parm entered.
;	end_of_parm_flag equ	 04h	;end of parm reached
;	copy_onto_itself_flag equ     08h ;copy onto itself flag
;	cyclic_flag equ     10h 	;cyclic copy flag
;	inv_time_flag equ     20h	;invalid time
;	inv_date_flag equ     40h	;invalid date
;	init_error_flag equ    80h	;critical initialization error. Should abort.

PARM1_FLAG DB	0
;	inv_s_path_flag equ	01h	;invalid source path (path not found)
;	inv_t_path_flag equ	02h	;invalid target path
;	s_file_flag equ     04h 	;source filename entered
;	t_file_flag equ     08h 	;target filename entered
;	INV_SW_flag equ     10h 	;AN004;DUPLICATE OR INVALID SW ENTERED
;
TEMP_T_FILENAME DB 15 DUP (0)		;temporary target filename holder
FILENAME_FOR_PROMPT DB 15 DUP (0)	;upper case lettered TEMP_T_FILENAME for prompts
;** The following definitions are used for "Does ... specify a file name
;** or directory name (F:file, D:directory)?.
ALPHA_FILE DW	?			;AN000;THIS IS THE TRANSLATION OF 'F'
ALPHA_DIR DW	?			;AN000;THIS IS THE TRANSLATION OF 'D'
USER_INPUT DW	?			;AC000;KEYBOARD SAVE - MAY BE DBCS -

Maxdays db	31,28,31,30,31,30,31,31,30,31,30,31 ;Max days per month
Day	db	?			;
Month	db	?			;
Year	dw	?			;
Parmdate dw	?			;date parameter used in file date
;
COUNTRY_INFO DB 34 DUP (0)
;-------------------------------
;    Structures
;-------------------------------

SUB_LIST STRUC				;AN000;MSG RETRIEVER SUBSTITUTION LST
	DB	11			;AN000;
	DB	0			;AN000;
DATA_OFF DW	0			;AN000; offset of data to be inserted
DATA_SEG DW	0			;AN000; offset of data to be inserted
MSG_ID	DB	0			;AN000; n of %n
FLAGS	DB	0			;AN000; Flags
MAX_WIDTH DB	0			;AN000; Maximum field width
MIN_WIDTH DB	0			;AN000; Minimum field width
PAD_CHAR DB	0			;AN000; character for pad field

SUB_LIST ENDS				;AN000;

DSEG_INIT ENDS
;*******************************************************************************

CSEG	SEGMENT PUBLIC			;ATTACHED TO MAIN PROGRAM
	ASSUME	CS:CSEG, DS:DGROUP, ES:DGROUP
;
;--- PUBLIC   PROCEDURES ---		;USED BY PARSER
PUBLIC	GET_PARMS			;AN000;
;---------------------------

;--- EXTERNAL PROCEDURES ---
EXTRN	SET_BUFFER_PTR:NEAR
EXTRN	STRING_LENGTH:NEAR
EXTRN	CONCAT_ASCIIZ:NEAR
EXTRN	LAST_DIR_OUT:NEAR
EXTRN	CHK_DBCS:NEAR			;AN010;NEEDED TO PARSE THE PATH STRING
EXTRN	COMPRESS_FILENAME:NEAR
EXTRN	CHK_DRV_LETTER:NEAR
EXTRN	SET_DEFAULT_DRV:NEAR
EXTRN	PRINT_STDOUT:NEAR
EXTRN	PRINT_STDERR:NEAR
EXTRN	MAIN_EXIT:NEAR
EXTRN	MAIN_EXIT_A:NEAR
EXTRN	CTRL_BREAK_EXIT:NEAR
EXTRN	PARSER:NEAR			;AN000;PROCESS THE KBD INPUT STRING
EXTRN	SYSGETMSG:NEAR			;AN000;TO GET THE 'F'ILE or 'D'IRECTORY
EXTRN	MY_INT24:WORD
;---
EXTRN	SAV_INT24_OFF:WORD		;int 24, critical error handler addr.
EXTRN	SAV_INT24_SEG:WORD
;
;--- PARSER REFERENCES ---
;
EXTRN	RESULT1:BYTE			;AN000;
EXTRN	RESULT_PTR1:DWORD		;AN000;
EXTRN	TYPE1:BYTE			;AN000;
EXTRN	RESULT2:BYTE			;AN000;
EXTRN	RESULT_PTR2:DWORD		;AN000;
EXTRN	TYPE2:BYTE			;AN000;
EXTRN	RESULTSW1:BYTE			;AN000;
EXTRN	RESULTSWSYN:WORD		;AN000;
EXTRN	SW_A:BYTE			;AN000;
EXTRN	SW_E:BYTE			;AN000;
EXTRN	SW_M:BYTE			;AN000;
EXTRN	SW_P:BYTE			;AN000;
EXTRN	SW_S:BYTE			;AN000;
EXTRN	SW_V:BYTE			;AN000;
EXTRN	SW_W:BYTE			;AN000;
EXTRN	SW_D:BYTE			;AN000;
EXTRN	DATE_YEAR:WORD			;AN000;
EXTRN	DATE_MONTH:BYTE 		;AN000;
EXTRN	DATE_DAY:BYTE			;AN000;
;---

PUBLIC	INIT
INIT	PROC	NEAR
	CMP	AX, 0			;check drv validity
;	$IF	NE
	JE $$IF1
	    MOV     DX, MSG_INVALID_DRV ;AC000;GET THE MESSAGE ID
	    OR	    PARM_FLAG, INIT_ERROR_FLAG ;critical error. Abort
;	$ELSE
	JMP SHORT $$EN1
$$IF1:
	    CALL    HOOK_CTRL_BREAK	;hooks control break
	    CALL    SAV_HOOK_INT24	;hooks critical err handler
	    CALL    GET_CUR_DRV 	;save current default drv
	    MOV     DL, SAV_DEFAULT_DRV
	    LEA     SI, SAV_DEFAULT_DIR
	    CALL    GET_CUR_DIR 	;save current default dir
	    CALL    PARSE_INPUT_PARM
	    TEST    PARM_FLAG, INIT_ERROR_FLAG
;	    $IF     Z			;no error
	    JNZ $$IF3
		CALL	TOP_OF_MEM	;set top_of_memory
		CALL	INIT_BUFFER	;init buffer information

		MOV	DL, S_DRV_NUMBER
		DEC	DL
		CALL	SET_DEFAULT_DRV ;set source as a default drv
;	    $ENDIF
$$IF3:
;	$ENDIF
$$EN1:
	TEST	PARM_FLAG, INIT_ERROR_FLAG ;any error?
;	$IF	NZ			;yes. critical error
	JZ $$IF6
	    CMP     DX,MSG_INV_SW	;AN004;MSG REQUIRES SUB LIST
;	    $IF     NE,AND		;AC023;NO SUBLIST REQUIRED
	    JE $$IF7
	    CMP     DX,MSG_INVALID_PARM ;AN004;MSG REQUIRES SUB LIST
;	    $IF     NE,AND		;AC023;NO SUBLIST REQUIRED
	    JE $$IF7
	    CMP     DX,MSG_INV_NUM_PARM ;AN004;MSG REQUIRES SUB LIST
;	    $IF     NE			;AC023;NO SUBLIST REQUIRED
	    JE $$IF7
		MOV	SUBST_COUNT,NO_SUBST ;AN000;NO SUBSTITUTION TEXT
		CMP	DX,SYSPRM_MISSING_OP ;AN024;OPERANDS MISSING(2) ERR?
;		$IF	E		;AN024;
		JNE $$IF8
		    MOV DX,MSG_INV_NUM_PARM ;AN024;NO SUBLIST REQUIRED
;		$ENDIF			;AN024;
$$IF8:
		MOV	MSG_NUM,DX	;AN000;NEED MESSAGE ID FOR PRINT
;	    $ELSE			;AN004;SUBST LIST REQUIRED
	    JMP SHORT $$EN7
$$IF7:
		MOV	MSG_NUM,DX	;AN004;NEED MESSAGE ID FOR PRINT
		MOV	SUBST_COUNT,PARM_SUBST_ONE ;AN004;PARM SUBST COUNT=1
;
		MOV	DX,CURRENT_PARM ;AN004;OFFSET TO BAD SWITCH
		LEA	SI,SUBLIST1	;AN004; address to sublist
		MOV	[SI].DATA_OFF,DX ;AN004; save data offset
		MOV	[SI].DATA_SEG,DS ;AN004; save data segment
		MOV	[SI].MSG_ID,0	;AN023; message ID
		MOV	[SI].FLAGS,010H ;AN004; ASCIIZ str,l align
		MOV	[SI].MAX_WIDTH,0 ;AN004; MAXIMUM FIELD WITH
		MOV	[SI].MIN_WIDTH,0 ;AN004; MINIMUM FIELD WITH
;	    $ENDIF			;AN004;
$$EN7:
	    MOV     INPUT_FLAG,NO_INPUT ;AN000;NO INPUT = 0
	    MOV     MSG_CLASS,UTILITY_MSG_CLASS ;AN000;MESSAGE CLASS = -1
	    CALL    PRINT_STDERR	;AN000;print error. AX point to msg ID
	    MOV     ERRORLEVEL, 4	;error ending
	    STC 			;set carry and exit to the main_exit
;	$ELSE
	JMP SHORT $$EN6
$$IF6:
	    CLC
;	$ENDIF
$$EN6:
	RET
INIT	ENDP

;
PARSE_INPUT_PARM PROC NEAR
;
	CALL	PARSER		    ;AN000;the PARSER interface routine
;	$IF	C		    ;AC000;if no non_delimiter chr?
	JNC $$IF14
	    TEST    PARM_FLAG,INIT_ERROR_FLAG ;AN000;PARM ERR HAS OCCURRED
;	    $IF     Z		    ;AN000;NO, MUST BE PARSER ERROR
	    JNZ $$IF15
		OR	PARM_FLAG,INIT_ERROR_FLAG ;AN000;SET THE FLAG
		CMP	AX,SYSPRM_EX_MANY ;AN000;TOO MANY OPERANDS (1) ERR?
;		$IF	E	    ;AN000;
		JNE $$IF16
		    MOV     BYTE PTR [SI],NUL ;AN024;DELIMIT BAD PARM
		    MOV     DX,MSG_INV_NUM_PARM ;AN000;MSG NUM = 21
;		$ELSE		    ;AN000;
		JMP SHORT $$EN16
$$IF16:
		    CMP     AX,SYSPRM_DUP_SW ;AN004;DUPLICATE SW REQUESTED
;		    $IF     E	    ;AN004;
		    JNE $$IF18
			MOV	BYTE PTR [SI],NUL ;AN004;DELIMIT BAD PARM
			MOV	DX,MSG_INV_SW ;AN004;MSG NUM = 35
;		    $ELSE	    ;AN004;
		    JMP SHORT $$EN18
$$IF18:
			CMP	AX,SYSPRM_MISSING_OP ;AN006;MISSING PARM=2
;			$IF	E   ;AN006;
			JNE $$IF20
			    MOV     DX,AX     ;AN024 ;MSG NUM=21-NO SUBLIST
;			$ELSE	    ;AN006;
			JMP SHORT $$EN20
$$IF20:
			    MOV     BYTE PTR [SI],NUL ;AN024;DELIMIT BAD PARM
			    MOV     DX,MSG_INVALID_PARM ;AN000;MSG NUM = 3
;			$ENDIF	    ;AN006;
$$EN20:
;		    $ENDIF	    ;AN004;
$$EN18:
;		$ENDIF		    ;AN000;
$$EN16:
;	    $ELSE		    ;AN006;INIT_ERROR_FLAG ALSO SET
	    JMP SHORT $$EN15
$$IF15:
		TEST	PARM_FLAG,INV_DATE_FLAG ;AN006;WAS DATE INVALID?
;		$IF	NZ	    ;AN006;THE DATE IS INVALID
		JZ $$IF26
		    MOV     DX,MSG_INVALID_DATE ;AN006;MSG NUM = 9
;		$ENDIF		    ;AN006;
$$IF26:
;	    $ENDIF		    ;AN000;
$$EN15:
;	$ELSE			    ;AN000;
	JMP SHORT $$EN14
$$IF14:
	    CALL    GET_DRIVES	    ;get source, target drive
	    TEST    PARM_FLAG, INIT_ERROR_FLAG ;critical syntax error?
;	    $IF     Z		    ;if not,
	    JNZ $$IF30
		CALL	CHK_SLASH_W ;with /w, show "Press any key to begin ... " msg.
		call	save_for_display ;save source, target parm for display purposes
		CALL	CHK_SET_PARMS ;check and set each parms.
		TEST	PARM_FLAG, INIT_ERROR_FLAG ;critical syntax error?
;		$IF	Z	    ;no
		JNZ $$IF31
		    call    modify_for_display ;set the source, target parm for display
;		$ENDIF
$$IF31:
;	    $ENDIF
$$IF30:
;	$ENDIF
$$EN14:
	MOV	AL, 0
	LEA	DI, S_PATH
	CALL	STRING_LENGTH		;cx - # of chr
	LEA	SI, S_PATH
	LEA	DI, S_ARC_PATH
	REP	MOVSB			;s_path => s_arc_path
	RET
PARSE_INPUT_PARM ENDP
;

CHK_SLASH_W PROC NEAR
;if /W option is specified, then
;show "Press any key to begin copying file(z)" message and wait for a key stroke.


	TEST	OPTION_FLAG, SLASH_W	;/W option taken?
;	$IF	NZ			;yes.
	JZ $$IF35
	    PUSH    AX			;AN000;
	    MOV     AX, MSG_TO_BEGIN	;AC000;GET THE MESSAGE ID
	    MOV     MSG_NUM,AX		;AN000;SET THE MESSAGE NUMBER
	    MOV     SUBST_COUNT,NO_SUBST ;AN000;NO SUBSTITUTION TEXT
	    MOV     INPUT_FLAG,DOS_KEYB_INP ;AN000;RESPONSE EXPECTED = 1
	    MOV     MSG_CLASS,UTILITY_MSG_CLASS ;AN000;MESSAGE CLASS = -1
	    CALL    PRINT_STDOUT	;AN000;MSG AX points to message ID

	    MOV     AX,MSG_CR_LF_STR	;AN000; JUST CR,LF
	    MOV     MSG_NUM,AX		;AN000; set message number
	    MOV     INPUT_FLAG,NO_INPUT ;AN000; NO INPUT
	    CALL    PRINT_STDOUT	;AN000; Display message

	    POP     AX			;AN000;
;	$ENDIF
$$IF35:
	RET

CHK_SLASH_W ENDP
;
PROMPT_TO_USER PROC NEAR
;guide the user to enter the input parameters
;get user input to S_INPUT_PARM, T_INPUT_PARM for source, target parms.
;INPUT: ES - PSP seg
;	DS - data seg
;	SAV_DEFAULT_DRV
;
	MOV	dx, msg_inv_num_parm	;AC000;GET THE MESSAGE ID
	or	parm_flag, init_error_flag
	RET
PROMPT_TO_USER ENDP
;
GET_PARMS PROC	NEAR
;Get the first parameter(s), second parameter(s) and option(s).
;Not checking correct character entered.
;The logic is:
;1). Find the first non_delim from the Parser control block. This is the
;    start of the first parm. Validate the length and put into S_INPUT_PARM.
; Note that this routine currently does not check the S_INPUT_PARM to see
;    if it is valid or not.
;2). Find the next non_delim from the Parser control block. This is the
;    start of the second parm. Validate the length and put into T_INPUT_PARM.
; Note that this routine currently does not check the T_INPUT_PARM to see
;    if it is valid or not.
;3). Find the switch(es) from the parser control block and set the
;    corresponding bit in the option flag word(OPTION_FLAG) by calling
;    GET_OPTIONS.
;
;INPUT:
;      BX - PARSER OPERAND POINTER

	PUSH	DS			;AN000;
	CMP	BX,OFFSET DGROUP:RESULT1 ;AN000;WAS FIRST FILESPEC SPECIFIED?
;	$IF	E			;AN000;IF FIRST FILESPEC SPECIFIED,
	JNE $$IF37
	    LDS     SI,RESULT_PTR1	;AN000;GET WHERE THE STRING IS
	    ASSUME  DS:NOTHING		;AN000;
	    CMP     DS:BYTE PTR [SI]+BYTE,COLON ;AN000;DOES FILESPEC START WITH
					;DRIVE?
;	    $IF     E			;AN000;STARTS WITH DRIVE
	    JNE $$IF38
		LODSW			;AN000;GET JUST THE DRIVE LETTER AND
		MOV	ES:SO_DRIVE,AL	;AN000;ALSO ADJUSTS WHERE THE STRING IS
		LEA	DI,ES:S_INPUT_PARM ;AN000;MOVE PARM TO SOURCE FILESPEC
		STOSW			;AN000;MOVE DRIVE TO FILESPEC
;	    $ELSE			;AN000;DOES NOT START WITH DRIVE
	    JMP SHORT $$EN38
$$IF38:
		LEA	DI,ES:S_INPUT_PARM ;AN000;MOVE PARM TO SOURCE FILESPEC
;	    $ENDIF			;AN000;FILESPEC HAVE DRIVE?
$$EN38:
	    CMP     DGROUP:TYPE1,5	;AN000;FILESPEC ?
;	    $IF     E			;AN000;MORE THAN JUST DRIVE
	    JNE $$IF41
					;MOVE PARM TO WHERE FIND FIRST/NEXT
					; WILL KNOW WHERE TO START
		PUSH	BX		;AN000;SAVE THE DATABASE POINTER
		XOR	BX,BX		;AN000;ZERO FOR THE PARAMETER LENGTH
;		$DO	COMPLEX 	;AN000;
		JMP SHORT $$SD42
$$DO42:
		    INC     BX		;AN000;CALCULATE LENGTH
		    STOSB		;AN000;MOVE CHAR TO FILESPEC
;		$STRTDO 		;AN000;
$$SD42:
		    LODSB		;AN000;GET NEXT CHAR FROM COMMAND LINE
		    CMP     AL,NUL	;AN000;IS THAT THE END OF THE STRING
;		$ENDDO	E		;AN000;GOT IT ALL, QUIT
		JNE $$DO42
		CALL	CHK_MAX_LENGTH	;AN000;LENGTH OF STRING <=64
		POP	BX		;AN000;RESTORE THE DATA BASE POINTER
;		$IF	NC		;no, less than or equal
		JC $$IF45
		    OR	    PARM_FLAG, FIRST_PARM_FLAG
;		$ELSE			;AN000;
		JMP SHORT $$EN45
$$IF45:
		    MOV     DX, MSG_LONG_PATH ;AN000;ADDRESS OF MESSAGE TXT
		    OR	    PARM_FLAG, INIT_ERROR_FLAG ;AN000;
;		$ENDIF			;AN000;CRITICAL ERROR INDICATED
$$EN45:
;	    $ENDIF			;AN000;MOVE ALL DONE
$$IF41:
;	$ELSE				;AN000;IF SECOND FILESPEC SPECIFIED,
	JMP SHORT $$EN37
$$IF37:
	    CMP     BX,OFFSET DGROUP:RESULT2 ;AN000;WAS 2nd FILESPEC SPECIFIED?
;	    $IF     E			;AN000;IF SECOND FILESPEC SPECIFIED
	    JNE $$IF50
		LDS	SI,RESULT_PTR2	;AN000;GET WHERE THE STRING IS
		ASSUME	DS:NOTHING	;AN000;
		CMP	DS:BYTE PTR [SI]+BYTE,COLON ;AN000;DOES FILESPEC START
					;WITH DRIVE?
;		$IF	E		;AN000;STARTS WITH DRIVE
		JNE $$IF51
		    LODSW		;AN000;GET JUST THE DRIVE LETTER AND
		    MOV     ES:TAR_DRIVE,AL ;AN000;ALSO ADJUSTS WHERE THE STRING IS
		    LEA     DI,ES:T_INPUT_PARM ;AN000;MOVE PARM TO TARGET FILESPEC
		    STOSW		;AN000;MOVE DRIVE TO FILESPEC
;		$ELSE			;AN000;DOES NOT START WITH DRIVE
		JMP SHORT $$EN51
$$IF51:
		    LEA     DI,ES:T_INPUT_PARM ;AN000;MOVE PARM TO TARGET FILESPEC
;		$ENDIF			;AN000;FILESPEC HAVE DRIVE?
$$EN51:
		CMP	DGROUP:TYPE2,5	;AN000;FILESPEC ?
;		$IF	E		;AN000;MORE THAN JUST DRIVE
		JNE $$IF54
					;AN000;MOVE PARM TO WHERE FIND FIRST/NEXT
					;AN000; WILL KNOW WHERE TO START
		    PUSH    BX		;AN000;SAVE THE DATABASE POINTER
		    XOR     BX,BX	;AN000;ZERO FOR THE PARAMETER LENGTH
;		    $DO     COMPLEX	;AN000;
		    JMP SHORT $$SD55
$$DO55:
			INC	BX	;AN000;CALCULATE LENGTH
			STOSB		;AN000;MOVE CHAR TO FILESPEC
;		    $STRTDO		;AN000;
$$SD55:
			LODSB		;AN000;GET NEXT CHAR FROM COMMAND LINE
			CMP	AL,NUL	;AN000;IS THAT THE END OF THE STRING
;		    $ENDDO  E		;AN000;GOT IT ALL, QUIT
		    JNE $$DO55
		    CALL    CHK_MAX_LENGTH ;AN000;LENGTH OF STRING <=64
		    POP     BX		;AN000;RESTORE THE DATA BASE POINTER
;		    $IF     NC
		    JC $$IF58
			OR	PARM_FLAG, SECOND_PARM_FLAG
;		    $ELSE
		    JMP SHORT $$EN58
$$IF58:
			MOV	DX, MSG_LONG_PATH ;AN000;ADDRESS OF MESSAGE TXT
			OR	PARM_FLAG, INIT_ERROR_FLAG ;AN000;
;		    $ENDIF		;AN000;CRITICAL ERROR INDICATED
$$EN58:
;		$ENDIF			;AN000;SECOND FILESPEC
$$IF54:
;	    $ELSE			;AN000;FILESPEC NOT SPECIFIED
	    JMP SHORT $$EN50
$$IF50:
		CALL	GET_OPTIONS	;AN000;PROCESS THE SWITCHES
;	    $ENDIF			;AN000;MOVE ALL DONE
$$EN50:
;	$ENDIF				;AN000;FILESPEC?
$$EN37:
	POP	DS			;AN000;
	ASSUME	DS:DGROUP		;AN000;
	RET
GET_PARMS ENDP
;
SAVE_FOR_DISPLAY PROC NEAR
;save first parm, second parm into DISP_S_PATH, DISP_T_PATH.
;at this time, this is not gauranteed to be a path. They may
;contains filename in it.
;input: S_INPUT_PARM, T_INPUT_PARM, PARM_FLAG
;	DS: data seg
;	ES: psp

	PUSH	ES			;save ES
	PUSH	DS
	POP	ES			;ES = DS
	TEST	PARM_FLAG, FIRST_PARM_FLAG ;first parm entered?
;	$IF	NZ			;yes
	JZ $$IF65
	    MOV     AL, 0		;asciiz
	    LEA     DI, S_INPUT_PARM
	    CALL    STRING_LENGTH	;now CX has length
	    LEA     SI, S_INPUT_PARM
	    LEA     DI, DISP_S_PATH	;source path for display
	    CALL    MOV_STRING		;AC000;s_input_parm => disp_s_path

;	$ENDIF
$$IF65:
	TEST	PARM_FLAG, SECOND_PARM_FLAG ;second parm entered?
;	$IF	NZ
	JZ $$IF67
	    MOV     AL, 0
	    LEA     DI, T_INPUT_PARM
	    CALL    STRING_LENGTH
	    LEA     SI, T_INPUT_PARM
	    LEA     DI, DISP_T_PATH
	    CALL    MOV_STRING		;AC000;s_input_parm => disp_s_path
;	$ENDIF
$$IF67:
	POP	ES
	RET
SAVE_FOR_DISPLAY ENDP
;
MOV_STRING PROC NEAR			;AN000;
; move string from DS:SI to ES:DI
; CX should indicate string length
	cld
;	$DO
$$DO69:
	    CMP     CX, 0
;	$LEAVE	Z
	JZ $$EN69
	    LODSB			;[si] => AL
	    STOSB			;AL => [di]
	    DEC     CX
;	$ENDDO
	JMP SHORT $$DO69
$$EN69:
	RET
MOV_STRING ENDP 			;AN000;
;
MODIFY_FOR_DISPLAY PROC NEAR
;finally trims DISP_S_PATH, DISP_T_PATH into good shape.
;input: DS, ES = data seg. S_FILE_FLAG, T_FILE_FLAG

	LEA	DI, DISP_S_PATH
	LEA	SI, DISP_S_PATH
	TEST	PARM1_FLAG, S_FILE_FLAG ;source filename entered?
	JZ	MFD_NO_FILE1		;no
	CALL	MASSAGE_DISP_PATH	;yes, entered.
	JMP	SHORT MFD_TARGET
MFD_NO_FILE1:				;no source filename
	CALL	CHK_DRV_LETTER		;using [si]
	JC	MFD_CHK_TAIL1
	CMP	BYTE PTR [SI], 0	;D:,0 case
	JE	MFD_TARGET		;OK
	CMP	BYTE PTR [SI], '\'
	JNE	MFD_CHK_TAIL1		;D:dir... case
	CMP	BYTE PTR [SI+1], 0	;D:\,0 case
	JE	MFD_TARGET		;OK
MFD_CHK_TAIL1:				;else check tail
	CALL	CHK_TAIL_CHR		;chk tail and put \ at the end. using di
MFD_TARGET:
	LEA	DI, DISP_T_PATH
	LEA	SI, DISP_T_PATH
	TEST	PARM1_FLAG, T_FILE_FLAG
	JZ	MFD_NO_FILE2
	CALL	MASSAGE_DISP_PATH
	JMP	SHORT MFD_EXIT
MFD_NO_FILE2:
	CALL	CHK_DRV_LETTER
	JC	MFD_CHK_TAIL2
	CMP	BYTE PTR [SI], 0
	JE	MFD_EXIT
	CMP	BYTE PTR [SI], '\'
	JNE	MFD_CHK_TAIL2
	CMP	BYTE PTR [SI+1], 0
	JE	MFD_EXIT
MFD_CHK_TAIL2:
	CALL	CHK_TAIL_CHR
MFD_EXIT:
	RET
MODIFY_FOR_DISPLAY ENDP
;
CHK_TAIL_CHR PROC NEAR
;check the last chr of ASCIIZ string pointed by DI.
;if it is \,0 then OK, else put \ there.
;DS, ES = data seg
;DI points to string.
;OUTPUT: Revised string.
;AX, BX, CX - destroyed
	MOV	AL, 0			;asciiz
	PUSH	DI			;save di
	CALL	STRING_LENGTH		;now cx got the length including 0
	POP	DI			;restore di
	DEC	CX
	DEC	CX
	MOV	BX, CX
	CMP	BYTE PTR [DI][BX], '\'	;last chr before 0
	JE	CTC_EXIT		;\,0 case
	MOV	BYTE PTR [DI][BX+1], '\' ;change 0 to '\'
	MOV	BYTE PTR [DI][BX+2], 0	;make it asciiz again.
CTC_EXIT:
	RET
CHK_TAIL_CHR ENDP
;
MASSAGE_DISP_PATH PROC NEAR
;INPUT: DS, ES = data seg
;	DI = points to source. Used for LAST_DIR_OUT
;	SI = points to source. Used for CHK_DRV_LETTER routine
;OUTPUT: Revised source string

	CALL	LAST_DIR_OUT
;	$IF	C			;failure? no '\' found
	JNC $$IF72
	    CALL    CHK_DRV_LETTER	;drive letter?
;	    $IF     NC			;yes. "D:filename",0 case
	    JC $$IF73
		MOV	BYTE PTR DS:[SI], 0 ;make it "D:",0 since SI now points to the next chr
;	    $ELSE			;no. "filename",0 case
	    JMP SHORT $$EN73
$$IF73:
		MOV	BYTE PTR [DI], 0 ;set DISP_S_PATH to 0
;	    $ENDIF
$$EN73:
;	$ELSE				;found '\' and last '\' became 0
	JMP SHORT $$EN72
$$IF72:
	    MOV     DI, AX		;we want to restore '\' and put 0 just after that.
	    DEC     DI			;for ex, "D:\filename"=>"D:"=>"D:\"
	    MOV     BYTE PTR [DI], '\'	;	 "D:dir1\dir2"=>"D:dir1"=>"D:dir1\"
	    MOV     BYTE PTR [DI+1], 0
;	$ENDIF
$$EN72:
	RET
MASSAGE_DISP_PATH ENDP
;
CHK_MAX_LENGTH PROC NEAR
;Check the length of the source or target input string although this does not
;gaurantee the validity of the length of path.	This will just check/reduce
;the possibilities of long path.
;If the path string is longer than 64 (this includes 0 at the end of the string)
;then, carry will be set.
;INPUT: ds - data seg
;	es - psp seg
;	SI - points to the starting chr of the string.
;	BX - length of the string
;OUTPUT:
;	carry will set if the length if longer than we expected.

	PUSH	BX			;AN000;
	PUSH	DI
	PUSH	SI
					;AC001;DELETED CODE FOR PTM0011
	CMP	BYTE PTR [SI], '\'	;SI points to '\'?
	JNE	CML_LENGTH		;no, now compare the length
	DEC	BX			;AC000;decrease length by 1 for '\'
CML_LENGTH:
	CMP	BX, 63			;AC000;length of string > 63?
	JG	CML_CARRY		;AC027;WORK WITH ONLY + CMP RESULT
	CLC				;NO.  OK.
	JMP	CML_EXIT
CML_CARRY:
	STC				;not OK
CML_EXIT:
	POP	SI
	POP	DI
	POP	BX			;AN000;
	RET

CHK_MAX_LENGTH ENDP
;
;
GET_OPTIONS PROC NEAR
;get options from the PARSER and
;set OPTION_FLAG.
;INPUT:
;      BX - PARSER OPERAND POINTER
;
	CMP	BX,OFFSET DGROUP:RESULTSW1 ;AN000;WAS SW 1 THROUGH 7 SPECIFIED?
	MOV	DI,RESULTSWSYN		;AN000;GET THE SYNONYM POINTER [ES]

;	$IF	E,LONG			;AN000;IF SWITCH SPECIFIED
	JE $$XL1
	JMP $$IF78
$$XL1:
	    CMP     BYTE PTR ES:[DI+BYTE],ALPHA_S ;AC000;"S"
	    JNE     GO_A
	    OR	    OPTION_FLAG, SLASH_S ;set the walk the tree bit on.
	    MOV     SW_S,SPACE		;AN004;DISALLOW DUPLICATE SWITCHES
	    JMP     GO_EXIT		;AC000;
GO_A:
	    CMP     BYTE PTR ES:[DI+BYTE],ALPHA_A ;AN000;"A"
	    JNE     GO_M
	    MOV     SW_A,SPACE		;AN004;DISALLOW DUPLICATE SWITCHES
	    TEST    OPTION_FLAG, SLASH_M ;hard archieve already on?
	    JZ	    GO_A1		;if not, continue
	    AND     OPTION_FLAG, RESET_SLASH_M ;else turn it off
GO_A1:
	    OR	    OPTION_FLAG, SLASH_A ;set soft archieve
	    JMP     GO_EXIT		;AC000;
GO_M:
	    CMP     BYTE PTR ES:[DI+BYTE],ALPHA_M ;AN000;"M"
	    JNE     GO_P
	    MOV     SW_M,SPACE		;AN004;DISALLOW DUPLICATE SWITCHES
	    TEST    OPTION_FLAG, SLASH_A ;soft archieve already on?
	    JZ	    GO_M1		;if not, skip this part
	    AND     OPTION_FLAG, RESET_SLASH_A ;else turn off the soft archieve bit
GO_M1:
	    OR	    OPTION_FLAG, SLASH_M ;turn on the hard archieve bit.
	    JMP     GO_EXIT		;AC000;
GO_P:
	    CMP     BYTE PTR ES:[DI+BYTE],ALPHA_P ;AN000;"P"
	    JNE     GO_E
	    MOV     SW_P,SPACE		;AN004;DISALLOW DUPLICATE SWITCHES
	    OR	    OPTION_FLAG, SLASH_P
	    OR	    MY_FLAG, SINGLE_COPY_FLAG ;if user want prompt, then should be single copy (not a multi copy).
	    JMP     SHORT  GO_EXIT	;AC000;
GO_E:
	    CMP     BYTE PTR ES:[DI+BYTE],ALPHA_E ;AN000;"E"
	    JNE     GO_V
	    MOV     SW_E,SPACE		;AN004;DISALLOW DUPLICATE SWITCHES
	    OR	    OPTION_FLAG, SLASH_E ;turn on "creating empty dir" bit.
	    JMP     SHORT  GO_EXIT	;AC000;
GO_V:
	    CMP     BYTE PTR ES:[DI+BYTE],ALPHA_V ;AN000;"V"
	    JNE     GO_W
	    MOV     SW_V,SPACE		;AN004;DISALLOW DUPLICATE SWITCHES
	    MOV     AH, 54h		;get verify setting
	    INT     21H
	    CMP     AL, 0
	    JNE     GO_EXIT		;AC000;if not 0, then already on.
	    MOV     AX, 2E01h		;else set it on
	    INT     21h
	    OR	    SYS_FLAG, TURN_VERIFY_OFF_FLAG ;don't forget it off when exit to dos.
	    JMP     SHORT   GO_EXIT	;AC000;
GO_W:
	    OR	    OPTION_FLAG, SLASH_W
	    MOV     SW_W,SPACE		;AN004;DISALLOW DUPLICATE SWITCHES
	    JMP     SHORT   GO_EXIT	;AC000;
;	$ELSE				;AN000;SINCE SWITCH 1 - 7 NOT SPECIFIED
	JMP SHORT $$EN78
$$IF78:
					; IT MUST BE THE DATE SWITCH
	    CALL    GET_INPUT_DATE	;AN000;get date from parser control block
	    OR	    OPTION_FLAG, SLASH_D
	    MOV     SW_D,SPACE		;AN004;DISALLOW DUPLICATE SWITCHES
;	$ENDIF				;AN000;
$$EN78:
GO_EXIT:
	RET
GET_OPTIONS ENDP

GET_INPUT_DATE PROC NEAR
;get the input date from the parser and save it to  INPUT_DATE form which
;it can be used for comparison with FILE_DATE_DTA.
;INPUT:
;
;
;OUTPUT:
;
;
;

	CALL	VALIDATE_INPUT_DATE	;AN006;GO CHECK THE DATE
;	$IF	C			;AN006;SET IF THE DATE WAS INVALID
	JNC $$IF81
	    OR	    PARM_FLAG,INV_DATE_FLAG ;AN006;SET THE FLAG FOR DATE ERROR
	    OR	    PARM_FLAG,INIT_ERROR_FLAG ;AN006;SET THE FLAG FOR ERROR
;	$ELSE				;AN006;DATE WAS OK
	JMP SHORT $$EN81
$$IF81:
	    MOV     AX,DATE_YEAR	;AN000;GET YEAR FROM PARSER CTRL BLOCK
	    SUB     AX,1980		;AN000;SUBTRACT THE BASE YEAR
	    mov     cl,4		;AN000;SHIFT REG COUNT = 4
	    shl     ax,cl		;AN000;Shift it over 4
	    xor     dh,dh		;AN000;CLEAR THE AREA
	    mov     dl,DATE_MONTH	;AN000;GET MONTH FROM PARSER CTRL BLOCK
	    add     ax,dx		;AN000;Add in the Month
	    inc     cl			;AN000;BUMP SHIFT COUNT
	    shl     ax,cl		;AN000;Shift it over 5
	    xor     dh,dh		;AN000;CLEAR THE AREA
	    mov     dl,DATE_DAY 	;AN000;GET DAY FROM PARSER CTRL BLOCK
	    add     ax,dx		;AN000;Add in the Day
	    mov     INPUT_DATE,ax	;AN000;Store the date in DOS FCB format
	    CLC 			;AN000;CLEAR THE CARRY
;	$ENDIF				;AN006;
$$EN81:
	RET
GET_INPUT_DATE ENDP
;
VALIDATE_INPUT_DATE PROC NEAR
;CHECK FOR VALID DATE.
;
;OUTPUT: INVALID DATE = CARRY SET
;
;
;
;
	MOV	AH,GET_DATE		;AN006;DOS INT 2AH
	INT	21H			;AN006;MAKE THE CALL
	PUSH	CX			;AN006;YEAR
	PUSH	DX			;AN006;MONTH,DAY
	MOV	AH,SET_DATE		;AN006;DOS INT 2BH
	MOV	CX,DATE_YEAR		;AN006;GET YEAR FROM PARSER CTL BLOCK
	MOV	DH,DATE_MONTH		;AN006;GET MONTH FROM PARSER CTL BLOCK
	MOV	DL,DATE_DAY		;AN006;GET DAY FROM PARSER CTL BLOCK
	INT	21H			;AN006;MAKE THE CALL
	POP	DX			;AN006;GET THE SYSTEM MONTH,DAY
	POP	CX			;AN006;GET THE SYSTEM YEAR
	OR	AL,AL			;AN006;WAS MY INPUT DATE VALID?
	STC				;AN006;SET THE CARRY
	JNZ	ERR_DATE		;AN006;GET OUT WITH C SET
	CLC				;AN006;CLEAR THE CARRY, NO ERROR
	MOV	AH,SET_DATE		;AN006;RESTORE THE SYSTEM DATE
	INT	21H			;AN006;MAKE THE CALL
ERR_DATE:				;AN006;
	RET				;AN006;
;
VALIDATE_INPUT_DATE ENDP
;
CHK_SET_PARMS PROC NEAR
;This does a semantic checking on the given S_INPUT_PARM, T_INPUT_PARM and
;sets each of the starting drv path into S_PATH, T_PATH.
;The basic logic is:
;1). Try to change dir to a given S_INPUT_PARM.
;    if a success, then it must be the path. Chdir to it and get current
;    source directory using S_DRV_NUMBER by issuing GET_Current_directory call,
;    which starts from the root of the source drive.  In this way, you don't
;    have to worry about what type of path for the source has been entered.
;    You just try to chdir according to S_INPUT_PARM and
;    then call get_cur_dir to get the S_PATH which will always start
;    from the root of the source drive.
;    if not, then there must be the filename at the end, or there might be
;    garbage in the path.  So, take the last path name (which is, hopely,
;    a filename) and try chdir again.  If a success, then current source dir
;    is determined. Otherwise, error. Issue "Invalid direcory name". If a
;    success, then check the saved filename to make sure that there are no
;    invalid chr's in it. (When you try to take the last_dir_out, and
;    it has failed (carry set), then it was a filename candidate itself
;    (sometimes together with an drive id d:).	In this case, you have to
;    check the filename candidate if it has a drive id in front of it.
;    if it is, then take the drive id d: off from it and reshape the
;    filename candidate.  And check the invalid characters if any. Of cause
;    in this case, current direcory of source drv becomes S_PATH.
;2). Try to change dir to a given T_INPUT_PARM, if any. (If no T_INPUT_PARM
;    entered, then set current directory to the starting path of target using
;    T_DRV_NUMBER.)
;    If a success, then no problem.  It is a strating target path.
;    If not, then take the last dir out and try again.	If a failure, then
;    error "Invalid directory".
;    If a success, then check the saved filename to see if any illigal
;    characters in it.	If they are, then error. Else issue fun.29h
;    to see if there are any global characters in it.  If there
;    are, then assume a filename.  If there are not, then ask user
;    "Is XXXXX a filename in the target? (n)" If no, then it is a
;    subdirectory name.  Make a new subdirectory in the target and
;    concatenate a new directory name to the T_INPUT_PARM and chdir to
;    the new path (, which is the original path in fact) again.
;INPUT:
;	ES - PSP seg ; this will be changed to DS within this routine
;	DS - data seg

	PUSH	DS
	POP	ES			;set ES to DS
	TEST	PARM_FLAG, FIRST_PARM_FLAG ;first parm entered?
;	$IF	Z,AND			;NO
	JNZ $$IF84
	TEST	PARM_FLAG, SECOND_PARM_FLAG ;second parm entered?
;	$IF	Z			;NO
	JNZ $$IF84
	    MOV     DX, MSG_INV_NUM_PARM ;AC000;GET THE MESSAGE ID
	    OR	    PARM_FLAG, INIT_ERROR_FLAG ;critical error. exit program
;	$ELSE
	JMP SHORT $$EN84
$$IF84:

	    MOV     DL, S_DRV_NUMBER
	    LEA     SI, SAV_S_CURDIR
	    CALL    GET_CUR_DIR 	;get and save current source directory
	    OR	    SYS_FLAG, DEFAULT_S_DIR_FLAG ;indicates source dir saved
	    TEST    PARM_FLAG, FIRST_PARM_FLAG ;first parm only entered?
;	    $IF     Z			;no first parm
	    JNZ $$IF86
		LEA	SI, S_PATH	;then make current source dir as S_PATH
		CALL	GET_CUR_DIR
;	    $ELSE			;else first parm entered. check it
	    JMP SHORT $$EN86
$$IF86:
		LEA	DX, S_INPUT_PARM ;try to chdir to S_INPUT_PARM
		MOV	AH, Chdir	;= 3Bh
		INT	21h
;		$IF	NC		;success?
		JC $$IF88
		    MOV     DL, S_DRV_NUMBER
		    LEA     SI, S_PATH	;get current dir and save it
		    CALL    GET_CUR_DIR ;as a starting dir to S_PATH
;		$ELSE
		JMP SHORT $$EN88
$$IF88:
		    LEA     BX, S_INPUT_PARM
		    LEA     DX, S_FILE	;source filename
		    CALL    TAKE_PATH_TAIL ;take out the tail part of S_INPUT_PARM
		    LEA     DX, S_INPUT_PARM
		    MOV     AH, Chdir	;= 3Bh
		    INT     21h 	;try chdir again
;		    $IF     NC,AND	;success?
		    JC $$IF90
		    CMP     S_FILE, 0	;check s_file if something is there
;		    $IF     NE		;yes, filename entered.
		    JE $$IF90
			MOV	DL, S_DRV_NUMBER
			LEA	SI, S_PATH
			CALL	GET_CUR_DIR ;save current dir
			OR	PARM1_FLAG, S_FILE_FLAG ;source filename entered
			call	chk_s_reserved_name ;is it a reserved name?
;		    $ELSE
		    JMP SHORT $$EN90
$$IF90:
			MOV	DX, MSG_INVALID_PATH ;AC000;GET THE MESSAGE ID
			OR	PARM_FLAG, INIT_ERROR_FLAG ;critical error
;		    $ENDIF
$$EN90:
;		$ENDIF
$$EN88:
;	    $ENDIF
$$EN86:
;	$ENDIF
$$EN84:
	TEST	PARM_FLAG, INIT_ERROR_FLAG
;	$IF	Z,LONG			;no error so far,
	JZ $$XL2
	JMP $$IF96
$$XL2:
	    TEST    SYS_FLAG, ONE_DISK_COPY_FLAG ;if one disk copy
;	    $IF     NZ			;then saved source default directory
	    JZ $$IF97
		LEA	DX, SAV_S_DRV	;is the same as target current dir
		MOV	AH, Chdir	;=3Bh
		INT	21h		;so restore target default dir.
;	    $ENDIF
$$IF97:
	    MOV     DL, T_DRV_NUMBER
	    LEA     SI, SAV_T_CURDIR
	    CALL    GET_CUR_DIR 	;save current target directory
	    OR	    SYS_FLAG, DEFAULT_T_DIR_FLAG ;indicates target dir saved
	    TEST    PARM_FLAG, SECOND_PARM_FLAG ;second parm has been entered?
;	    $IF     Z			;second parm not entered
	    JNZ $$IF99
		LEA	SI, T_PATH
		CALL	GET_CUR_DIR	;make the current target dir as T_PATH
;	    $ELSE			;then deals with the second parm
	    JMP SHORT $$EN99
$$IF99:

		LEA	DX, T_INPUT_PARM ;try to chdir according to T_INPUT
		MOV	AH, Chdir
		INT	21h		;= 3Bh
;		$IF	C		;FAILURE?
		JNC $$IF101
		    CALL    PARSE_SECOND_PARM
;		$ENDIF
$$IF101:

		TEST	PARM_FLAG, INIT_ERROR_FLAG ;no error so far?
;		$IF	Z		;no error
		JNZ $$IF103
		    MOV     DL, T_DRV_NUMBER
		    LEA     SI, T_PATH
		    CALL    GET_CUR_DIR ;save target starting dir
		    CMP     TEMP_T_FILENAME, 0 ;any non_global target file name entered?
;		    $IF     NE		;yes
		    JE $$IF104
			MOV	CX, 13	;maximum 13 char.
			LEA	SI, TEMP_T_FILENAME
			LEA	DI, T_FILENAME ;then move it to T_FILENAME while convert it to capital letter.
			CALL	MOV_STRING ;AC000; SI => DI
;		    $ENDIF
$$IF104:
;		$ENDIF			;end - no error so far
$$IF103:
;	    $ENDIF			;end - second parm not entered
$$EN99:
;	$ENDIF
$$IF96:

	TEST	PARM_FLAG, INIT_ERROR_FLAG
;	$IF	Z			;no error
	JNZ $$IF109
	    CALL    CHK_CYCLIC_COPY	;check source, target parms
	    TEST    PARM_FLAG, INIT_ERROR_FLAG ;cyclic copy?
;	    $IF     Z,AND		;no
	    JNZ $$IF110
	    TEST    SYS_FLAG, ONE_DISK_COPY_FLAG ;if one disk drv letter copy
;	    $IF     NZ			;then set the starting dir
	    JZ $$IF110
		LEA	DX, S_DRV_PATH	;to that of source.
		MOV	AH, Chdir	; = 3Bh
		INT	21H		;should succeed since alreay tested.
;	    $ENDIF
$$IF110:
;	$ENDIF
$$IF109:

	RET
CHK_SET_PARMS ENDP
;
PARSE_SECOND_PARM PROC NEAR
;called after the initial chdir to T_INPUT_PARM failed.  Remember the second parm should
;exist when you call this routine.
;INPUT: DS, ES - data seg
;OUTPUT:if error, init_error_flag will be set.
;
	LEA	SI, T_INPUT_PARM
	CALL	CHK_HEAD_PARM		;check the head part of parm. SI will points
					;to the next chr after the header.
	TEST	PARM_FLAG, INIT_ERROR_FLAG
	JNZ	PSP_EXIT		;YES, ERROR.
	CALL	NEXT_PATH_DELIM 	;Let SI points to the next path delim "\" or 0
	LEA	DX, T_INPUT_PARM
	CALL	PARSING_T_PATH		;chdir for every directory starting from the
					;first. If it fails, then create a directory
					;and chdir to it.
PSP_EXIT:
	RET
PARSE_SECOND_PARM ENDP
;
NEXT_PATH_DELIM PROC NEAR
;starting from SI, check every chr until it is '\' or 0 or ':'.
;if the starting chr is '\' or 0 or ':', then SI won't change.
;the caller should be sure that it is an ASCIIZ string.
;INPUT: DS, ES - data seg
;	SI - starting point
;OUTPUT:
;	SI - next path delimeter

	CLD
	PUSH	DI
	PUSH	SI
	POP	DI			;NOW DI POINTS TO THE STARTING CHR
NPD_LOOP:
;	$DO				;AN010;
$$DO113:
	    CLC 			;AN010;INITIALIZE TO NOT DBCS
	    MOV     AL,BYTE PTR [DI]	;AN010;GET THE 1st CHAR TO TEST
	    CALL    CHK_DBCS		;AN010;SEE IF WE ARE IN DBCS
;	$LEAVE	NC			;AN010;THIS IS NOT DBCS
	JNC $$EN113
	    INC     DI			;AN010;GO TO THE NEXT CHAR TO CHECK
	    INC     DI			;AN010;DITO
;	$ENDDO				;AN010;
	JMP SHORT $$DO113
$$EN113:
	MOV	AL, 0
	SCASB				;0 - ES:[DI], DI=DI+1
	JZ	NPD_FOUND
	DEC	DI			;check it again if it is '\'
	MOV	AL, '\'
	SCASB
	JZ	NPD_FOUND
	DEC	DI
	MOV	AL, ':' 		;is it a filename terminator not filter before?
	SCASB
	JZ	NPD_FOUND
	JMP	SHORT NPD_LOOP
NPD_FOUND:
	DEC	DI			;adjust DI to the chr found
	PUSH	DI
	POP	SI			;now SI points to the chr
	POP	DI			;restore DI
	RET
NEXT_PATH_DELIM ENDP
;

CHK_HEAD_PARM PROC NEAR
;check the starting header part of parameter pointed by SI to eliminate
;error such as A:\\..., A:\.., \\, \.. etc.
;This routine will change the current target directory to the root
;when "d:\" or "\" has been found.
;The parameter string should be ASCIIZ and should exist.
;INPUT: DS, ES - DATA SEG
;	SI - POINTS TO THE PARAMETER
;OUTPUT:SI POINTS TO THE NEXT VALID PATH
;	DX WILL POINTS TO THE ERROR MESSAGE

	CALL	CHK_DRV_LETTER		;si points to the next chr after drv letter, if found.
	CMP	BYTE PTR [SI], 0	;"A:0" case
;	$IF	E
	JNE $$IF116
	    MOV     BYTE PTR [SI], '.'
	    INC     SI
	    MOV     BYTE PTR [SI], 0	;make it "A:.0"
;	$ELSE
	JMP SHORT $$EN116
$$IF116:
	    CMP     BYTE PTR [SI], '\'
;	    $IF     E			;A:\--- or \--- cases
	    JNE $$IF118
		INC	SI
		CLC			;AN010;INITIALIZE TO NOT DBCS
		MOV	AL,DS:BYTE PTR [SI] ;AN010;GET THE 1st CHAR TO TEST
		CALL	CHK_DBCS	;AN010;SEE IF WE ARE IN DBCS
;		$IF	NC		;AN010;THIS IS NOT DBCS
		JC $$IF119
		    CMP     BYTE PTR [SI], '\'
;		    $IF     E		;A:\\--- or \\--- cases ; ERROR
		    JNE $$IF120
			MOV	DX, MSG_INVALID_PATH ;AC000;GET THE MESSAGE ID
			OR	PARM_FLAG, INIT_ERROR_FLAG
;		    $ELSE
		    JMP SHORT $$EN120
$$IF120:
			CMP	BYTE PTR [SI], '.'
;			$IF	E	;A:\.--- or \.--- cases
			JNE $$IF122
			    INC     SI
			    MOV     AL,DS:BYTE PTR [SI] ;AN010;GET 1st CHAR
					;      TO TEST
			    CALL    CHK_DBCS ;AN010;SEE IF WE ARE IN
					;      DBCS
;			    $IF     NC	;AN010;THIS IS NOT DBCS
			    JC $$IF123
				CMP	BYTE PTR [SI], '.'
;				$IF	E,OR
				JE $$LL124
				CMP	BYTE PTR [SI], '\'
;				$IF	NE ;if not A:\.\--- or \.\--- cases
				JE $$IF124
$$LL124:
				    MOV     DX, MSG_INVALID_PATH ;AC000;MSG ID
				    OR	    PARM_FLAG, INIT_ERROR_FLAG
;				$ENDIF
$$IF124:
;			    $ENDIF	;AN010;END OF DBCS TEST
$$IF123:
			    CLC 	;AN010;
;			$ENDIF
$$IF122:
;		    $ENDIF
$$EN120:
		    LEA     DX, T_DRV
		    MOV     AH, Chdir
		    INT     21h 	;"Chdir to root" is no problem.
;		$ENDIF			;AN010;DBCS TEST END
$$IF119:
		CLC			;AN010;
;	    $ENDIF
$$IF118:
;	$ENDIF
$$EN116:
	RET
CHK_HEAD_PARM ENDP
;
PARSING_T_PATH PROC NEAR
;chdir to every path element from the first. If fails, create the directory and
;try to chdir again.  T_MKDIR_LVL will increase when new starting directory is created
;INPUT: DX - OFFSET OF T_INPUT_PARM
;	SI - points to '\' or 0, or ':'
;OUTPUT: directories are created if necessary.
;	 DX points to the last path entry
;	 if fails to create a directory, then INIT_ERROR_FLAG set and
;	 DX points to MSG_NOT_CREATE_DIR msg.

	PUSH	DX			;save DX
	MOV	DL, T_DRV_NUMBER
	DEC	DL
	CALL	SET_DEFAULT_DRV 	;set target drive as a default
	POP	DX			;restore DX
PTP_NEXT:
	CMP	BYTE PTR [SI], 0	;end of string? the last path element?
	JE	PTP_LAST
	CMP	BYTE PTR [SI], ':'	;filename terminator not checked before?
	JNE	PTP_CHDIR		;else it is '\'.
	MOV	BYTE PTR [SI], 0	;change ':' to 0 for termination.
PTP_LAST:
	CALL	LAST_T_PATH
	JMP	PTP_EXIT
PTP_CHDIR:
	MOV	BYTE PTR [SI], 0	;replace '\' with 0
	MOV	AH, Chdir		;=38h
	INT	21h
	JC	PTP_MKDIR
	MOV	BYTE PTR [SI], '\'	;restore '\'
	INC	SI			;SI points to next to old '\'
	MOV	DX, SI			;DX points to next path entry
	CALL	NEXT_PATH_DELIM
	JMP	PTP_NEXT		;handles next path element
PTP_MKDIR:
	MOV	AH, Mkdir		;=39h
	INT	21h
	JC	PTP_ERROR		;cannot make directory
	INC	T_MKDIR_LVL		;# of MKDIR for the starting directory.
	JMP	PTP_CHDIR		;try again to chdir
PTP_ERROR:
	MOV	DX, MSG_NOT_CREATE_DIR	;AC000;GET THE MESSAGE ID
	OR	PARM_FLAG, INIT_ERROR_FLAG ;critical error
PTP_EXIT:
	RET

PARSING_T_PATH ENDP
;
LAST_T_PATH PROC NEAR
;called when the second parm reached last. *** this routine is the same as the old routine ***
;and the initial try to chdir to the given T_INPUT_PARM has been failed.
;INPUT: ES, DS - data seg
;	DX - points to the last path entry
;OUTPUT:target starting directory.

	MOV	AH, Chdir		;try to chdir to the last path entry
	INT	21h
;	$IF	C,LONG			;if fail.
	JC $$XL3
	JMP $$IF132
$$XL3:

	    LEA     BX, T_INPUT_PARM
	    LEA     DX, TEMP_T_FILENAME ;take the last path element into TEMP_T_FILENAME
	    CALL    TAKE_PATH_TAIL
	    CMP     TEMP_T_FILENAME, 0	;any filename candidate entered?
;	    $IF     NE,LONG		;yes. let's check it has any global chr.
	    JNE $$XL4
	    JMP $$IF133
$$XL4:
		PUSH	ES
		MOV	AH, 29h
		LEA	SI, TEMP_T_FILENAME
		MOV	ES, PSP_SEG	;ES - psp seg
		MOV	DI, PSPFCB2_DRV ;use this area for this test purposes
		MOV	AL, 0		;control bit
		INT	21h
		POP	ES
		CMP	AL, 0		;no global filename entered?
;		$IF	E		;yes, no globals
		JNE $$IF134
		    CALL    PROMPT_CREATE_DIR ;then ask the user, it is a filename or subdir name?
		    MOV     DX,USER_INPUT ;AN000;SET UP FOR COMPAIR
		    CMP     DX, alpha_dir ;directory?
;		    $IF     E		;yes, a subdir name.
		    JNE $$IF135
			LEA	DX, TEMP_T_FILENAME
			MOV	AH, Mkdir ;=39h
			INT	21h	;create a new subdir
;			$IF	NC
			JC $$IF136
			    INC     T_MKDIR_LVL ;one more directory has been made.
			    MOV     AH, Chdir
			    INT     21h ;Chdir to a new dir. This time it should be a success.
			    MOV     TEMP_T_FILENAME, 0 ;mark temp_t_filename that it is empty
;			$ELSE		;ERROR IN CREATING DIRECTORY
			JMP SHORT $$EN136
$$IF136:
			    MOV     DX, MSG_NOT_CREATE_DIR ;AC000;GET THE MESSAGE ID
			    OR	    PARM_FLAG, INIT_ERROR_FLAG
;			$ENDIF
$$EN136:
;		    $ELSE		;USER ANSWERED IT A FILENAME
		    JMP SHORT $$EN135
$$IF135:
			OR	PARM1_FLAG, T_FILE_FLAG ;set target file entered.
;		    $ENDIF		;use TEMP_T_FILENAME as a filename
$$EN135:
;		$ELSE			;GLOBALS IN THE FILENAME
		JMP SHORT $$EN134
$$IF134:
		    MOV     TEMP_T_FILENAME, 0 ;mark it to 0 since we don;t need this.
		    CALL    MAKE_TEMPLATE ;make a template of the target filename
		    OR	    PARM1_FLAG, T_FILE_FLAG ;set target file entered flag
;		$ENDIF			;GLOBAL TEST
$$EN134:
;	    $ENDIF			;NO, FILENAME NOT ENTERED. TEMP_T_FILENAME = 0
$$IF133:
;	$ENDIF				;CHDIR FAIL
$$IF132:
	RET
LAST_T_PATH ENDP
;
;
CHK_S_RESERVED_NAME PROC NEAR
;check the source filename entered, and if it does not have any global chr,
;then check it whether it is reserved filename or not.
;input: es,ds - data seg

	mov	ax, 3d00h		;let's try to open it
	lea	dx, s_drv_1		;'A:S_FILE'
	int	21h
	jc	csrn_exit		;open failure? jmp to exit
	mov	bx, ax			;else ax has file handle
	mov	ax, 4400h		;get device info.
	int	21h			;ioctl fun call
	test	dx, 80h 		;ISDEV ?
	jz	csrn_close		;no, block device. close handle and exit
	PUSH	AX			;AN000;
	MOV	AX, msg_res_s_name	;AC000;reserved file name as a source"
	MOV	MSG_NUM,AX		;AN000;NEED MESSAGE ID FOR PRINT
	MOV	SUBST_COUNT,NO_SUBST	;AN000;NO SUBSTITUTION TEXT
	MOV	INPUT_FLAG,NO_INPUT	;AN000;NO INPUT = 0
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000;MESSAGE CLASS = -1
	CALL	PRINT_STDERR		;AN000;print error. AX points to msg ID
	POP	AX			;AN000;
	mov	errorlevel, 4		;abnormal termination
	or	parm_flag, init_error_flag ;set init_error_flag
	jmp	main_exit
csrn_close:
	mov	ah, 3eh 		;close filehandle in bx
	int	21h
csrn_exit:
	ret
CHK_S_RESERVED_NAME ENDP
;
PROMPT_CREATE_DIR PROC NEAR
;DS, ES - data seg
	PUSH	AX			;AN000;
	mov	cx, 13
	lea	si, temp_t_filename
	lea	di, filename_for_prompt
	call	mov_STRING		;AC000;

;CALL GET MESSAGE TO DETERMINE WHAT THIS COUNTRY INPUT FOR 'F' OR 'D' IS.

	PUSH	DS			;AN000;
	ASSUME	DS:NOTHING		;AN000;TELL THE ASSEMBLER
	MOV	AX,MSG_F_D		;AN000;MESSAGE NUMBER = 29 = 'F D '
	MOV	DH,UTILITY_MSG_CLASS	;AN000;MESSAGE DEFINED FOR XCPYINIT
	CALL	SYSGETMSG		;AN000;GET THE MESSAGE
	LODSW				;AN000;'F'PART OF MSG (DS:SI => AX)
	CMP	AH,SPACE		;AN000;NOT 'SPACE' THEN IT IS DBCS !
;	$IF	E			;AN000;IGNORE THE NEXT WORD
	JNE $$IF145
	    MOV     AH,NUL		;AN000;THE END OF THE STRING
;	$ENDIF				;AN000;NOW GET TRANSLATION OF 'D'
$$IF145:
	MOV	ES:ALPHA_FILE,AX	;AN000;TRANSLATED CHAR FOR 'F' TO BUFF
	LODSW				;AN000;'D'PART OF MSG (DS:SI => AX)
	CMP	AH,SPACE		;AN000;NOT 'SPACE' THEN IT IS DBCS !
;	$IF	E			;AN000;IGNORE THE NEXT WORD
	JNE $$IF147
	    MOV     AH,NUL		;AN000;REMOVE SPACE CHARACTER
;	$ENDIF				;AN000;NOW GET TRANSLATION OF 'D'
$$IF147:
	MOV	ES:ALPHA_DIR,AX 	;AN000;TRANSLATED CHAR FOR 'D' TO BUFF
	POP	DS			;AN000;RESTORE AFTER CALL TO MSG HANDLR
	ASSUME	DS:DGROUP		;AN000;TELL THE ASSEMBLER
					;remember this may be DBCS
PCD_AGAIN:
; Set message substitution list
	LEA	SI,SUBLIST1		;AN000; get addressability to sublist
	LEA	DX,FILENAME_FOR_PROMPT	;AN000; offset to file name
	MOV	[SI].DATA_OFF,DX	;AN000; save data offset
	MOV	[SI].DATA_SEG,DS	;AN000; save data segment
	MOV	[SI].MSG_ID,1		;AN000; message ID
	MOV	[SI].FLAGS,010H 	;AN000; ASCIIZ string, left align
	MOV	[SI].MAX_WIDTH,0	;AN000; MAXIMUM FIELD WITH
	MOV	[SI].MIN_WIDTH,0	;AN000; MINIMUM FIELD WITH

	MOV	AX,MSG_CREATE_DIR	;AN000;ID OF MESSAGE TO BE DISPLAYED
	MOV	MSG_NUM,AX		;AN000;SET THE MESSAGE NUMBER
	MOV	SUBST_COUNT,PARM_SUBST_ONE ;AN000;PARM SUBSTITUTION COUNT=1
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000;MESSAGE CLASS = -1
	MOV	INPUT_FLAG,KEYBOARD_INPUT ;AN000;KEYBOARD INPUT EXPECTED FUNCTION
	CALL	PRINT_STDOUT		;show prompt and get user input

	MOV	USER_INPUT,AX		;AN000;RESPONSE BUFF FOR CAPITALIZATION

	MOV	AX,MSG_CR_LF_STR	;AN000; JUST CR,LF
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,NO_SUBST	;AN000;NO PARAMETER SUBSTITUTION
	MOV	INPUT_FLAG,NO_INPUT	;AN000; NO INPUT
	CALL	PRINT_STDOUT		;AN000; Display message

	MOV	AX,UPPER_CASE_STRING	;AN000;AX = 6521H GET EXT CTRY INFO
	LEA	DX,USER_INPUT		;AN000;RESPONSE BUFF FOR CAPITALIZATION
	MOV	CX,2			;AN000;TWO CHARACTERS, ONE WORD
	INT	21H			;AN000;ISSUE INT TO CAP STRING (DBCS?)
	MOV	AX,USER_INPUT		;AN000;SO I CAN DO THE COMPARE
	CMP	AX,ALPHA_FILE		;AN000;KEYBOARD INPUT AX = 'F' ?
	JE	PCD_EXIT
	CMP	AX,ALPHA_DIR		;AN000;KEYBOARD INPUT AX = 'D' ?
	JE	PCD_EXIT
	JMP	SHORT  PCD_AGAIN
PCD_EXIT:

	POP	AX			;AN000;
	RET
PROMPT_CREATE_DIR ENDP
;
TAKE_PATH_TAIL PROC NEAR
;check the tail of the source input parm.
;Call LAST_DIR_OUT
;If carry set
;	then check the drive letter
;	     if entered, then save the rest of the string after drv: into
;	     a tempory filename holder, and put "." after the drive letter
;	     (For ex, if the input had been 'A:name1',0 then no change after
;	      LAST_DIR_OUT.  This has to be changed to 'A:.',0 and name1.)
;	else save the last dir into a filename, and
;	     check the result path
;	     if it is a drive only, then put "\" ( For ex, if the input
;	     had been 'A:\name1',0 then after LAST_DIR_OUT, it will be changed
;	     to 'A:',0 and 'name1',0.  In this case, we have to change the
;	     path to A:\)
;	     else OK.
;INPUT: DS - data seg
;	ES - data seg
;	BX - offset value of S_INPUT_PARM or T_INPUT_PARM
;	DX - offset value of TEMP_S_FILENAME or TEMP_T_FILENAME


	MOV	DI, BX			;offset of S(T)_INPUT_PARM
	CALL	LAST_DIR_OUT
;	$IF	C			;Not found a "\"
	JNC $$IF149
	    MOV     SI, DI		;set si = di
	    CALL    CHK_DRV_LETTER	;if drv letter:, then SI will
					;point to next chr. Otherwise no change
	    cmp     byte ptr [si], 0	;only drv letter has entered. No filename
;	    $IF     NE			;filename entered
	    JE $$IF150
		push	si		;save si
		MOV	CX, 13		;max # of filename in ASCIIZ
		MOV	DI, DX
		REP	MOVSB		;save it to temporay name holder
		pop	si		;restore si
;	    $ENDIF
$$IF150:
	    mov     byte ptr [si], A_dot ;to be used for Chdir fun call
	    mov     byte ptr [si+1], 0	;make it ASCIIZ
;	$ELSE				;at least found a "\"
	JMP SHORT $$EN149
$$IF149:
	    mov     cx, 13		;let's save tail into filename holder first
	    mov     si, ax		;AX is an offset value of the tail
	    mov     di, DX		;TEMP_FILENAME
	    rep     movsb
	    mov     si, BX		;return to the Revised input
	    CALL    CHK_DRV_LETTER	;it starts with drv letter?
	    cmp     byte ptr [si], 0	;si points to the end of string?
;	    $IF     E
	    JNE $$IF153
		MOV	byte ptr [SI], '\' ;then add '\' in the Revised S_INPUT_PARM
		MOV	byte ptr [SI+1], 0
;	    $ENDIF
$$IF153:
;	$ENDIF
$$EN149:
	RET

TAKE_PATH_TAIL ENDP
;
CHK_CYCLIC_COPY PROC NEAR
;With the one_disk_copy case, if the starting source path is a member of
;parent directory of the startind target path, then infinite copy cycle
;can occur.  This routine prevents that situation.
;ES: data seg
;DS: data seg

	PUSH	DS
	POP	ES			;set ES to DS (ES = DS)
	CALL	TRANS_NAMES		;AN016;CHK ASSIGN, JOIN & SUBST CONDITN
	TEST	SYS_FLAG, ONE_DISK_COPY_FLAG ;source, target drv let same
;	$IF	NZ			;if they are, then check below facts
	JZ $$IF156
	    MOV     DI, OFFSET DGROUP:T_TRANS_PATH ;AC025;
	    MOV     AL, 0
	    CALL    STRING_LENGTH
	    MOV     DX, CX		;save the length of S_PATH
	    MOV     DI, OFFSET DGROUP:S_TRANS_PATH ;AC025;
	    CALL    STRING_LENGTH
	    CMP     DX,CX		;compare the length
;	    $IF     AE			;if target length >= source length
	    JNAE $$IF157
		MOV	SI, OFFSET DGROUP:S_TRANS_PATH ;AC025;
		MOV	DI, OFFSET DGROUP:T_TRANS_PATH ;AC025;
		DEC	CX		;get the actual length of chr's
		DEC	DX
		CLD
;		$SEARCH 		;current CX = source length
$$DO158:
		    CMP     CX, 0
;		$EXITIF E		;exit if cx = 0
		JNE $$IF158
		    CMP     DX, 0	;target length = 0 too?
;		    $IF     E		;yes, source = target
		    JNE $$IF160
			TEST	OPTION_FLAG, SLASH_S ; tree copy?
;			$IF	NZ,OR	;yes
			JNZ $$LL161
			TEST	OPTION_FLAG, SLASH_E
;			$IF	NZ
			JZ $$IF161
$$LL161:
			    MOV     DX, MSG_CYCLIC_COPY ;AC000;GET THE MESSAGE ID
			    OR	    PARM_FLAG, INIT_ERROR_FLAG ;critical error
;			$ELSE		;same length, but not a tree copy.
			JMP SHORT $$EN161
$$IF161:
			    OR	    COPY_STATUS, MAYBE_ITSELF_FLAG ;possibly, copy onto itself.
;			$ENDIF		;cannot fully determine this time until file creation time
$$EN161:
;		    $ELSE		;target > source
		    JMP SHORT $$EN160
$$IF160:
			TEST	OPTION_FLAG, SLASH_S ;tree copy?
;			$IF	NZ,OR
			JNZ $$LL165
			TEST	OPTION_FLAG, SLASH_E
;			$IF	NZ
			JZ $$IF165
$$LL165:
			    CMP     BYTE PTR [DI], '\' ;source = d:\abc, target = d:\abc\def case
;			    $IF     E,OR
			    JE $$LL166
			    CMP     BYTE PTR [DI-1], '\' ;source = d:\, target=d:\abc case
;			    $IF     E
			    JNE $$IF166
$$LL166:
				MOV	DX, MSG_CYCLIC_COPY ;AC000;GET THE MESSAGE ID
				OR	PARM_FLAG, INIT_ERROR_FLAG ; critical error
;			    $ENDIF
$$IF166:
;			$ENDIF
$$IF165:
;		    $ENDIF
$$EN160:
;		$ORELSE
		JMP SHORT $$SR158
$$IF158:
		    LODSB		;[SI] => AL, SI = SI + 1
		    SCASB		;AL vs. [DI], DI = DI + 1
;		$LEAVE	NE		;leave if not same
		JNE $$EN158
		    DEC     CX
		    DEC     DX		;decrease target length, too
;		$ENDLOOP
		JMP SHORT $$DO158
$$EN158:
;		$ENDSRCH
$$SR158:
;	    $ENDIF
$$IF157:
;	$ENDIF
$$IF156:
	RET

CHK_CYCLIC_COPY ENDP
;
TRANS_NAMES PROC NEAR
;TRANSLATE THE INPUT TARGET AND SOURCE PATH TO DETERMINE
;IF ASSIGN, JOIN OR SUBSD WAS USET TO MODIFY HIDE THE TRUE
;PATH. THIS INFO. WILL BE USED TO DETERMINE CYCLIC COPY.
;INPUT: T_DRV_PATH, S_DRV_PATH

	PUSH	SI			;AN016;SI WILL BE DESTROYED
	PUSH	DI			;AN016;DI WILL BE DESTROYED

	MOV	SI,OFFSET DGROUP:T_DRV_PATH    ;AN016;DO NAME TRANSLATE OF TAR
	MOV	DI,OFFSET DGROUP:T_TRANS_PATH  ;AN025;SAVE FOR COMPARE
	MOV	AH,60h			;AN016;NAMETRANSLATE
	INT	21h			;AN016;EXECUTE

	MOV	SI,OFFSET DGROUP:S_DRV_PATH    ;AN016;DO NAME TRANSLATE OF SRC
	MOV	DI,OFFSET DGROUP:S_TRANS_PATH  ;AN025;SAVE FOR COMPARE
	MOV	AH,60h			;AN016;NAMETRANSLATE
	INT	21h			;AN016;EXECUTE

;NOW COMPARE THE TRANSLATED NAMES

	MOV	SI,OFFSET DGROUP:T_TRANS_PATH  ;AN025;GET THE TAR FOR COMPARE
	MOV	DI,OFFSET DGROUP:S_TRANS_PATH  ;AN025;GET THE SRC FOR COMPARE
	CALL	STR_COMP		;AN016;DO THE COMPARE
;	$IF	Z			;AN016;STRING DID COMPARE
	JNZ $$IF176
	   OR	SYS_FLAG, ONE_DISK_COPY_FLAG ;AN016;source, target drv let same
;	$ENDIF				;AN016;
$$IF176:

	POP	DI			;AN016;restore DI
	POP	SI			;AN016;restore SI
	RET
TRANS_NAMES ENDP
;
STR_COMP PROC NEAR
;COMPARE ASCIIZ DS:SI WITH ES:DI
;DI,SI ARE DESTROYED

STRCOMP:
	CMPSB				;AN016;ONE BYTE AT A TIME
;	$IF NZ				;AN016;DID NOT COMPARE
	JZ $$IF178
	    RET 			;AN016;NZ = DIFFERENCE
;	$ENDIF				;AN016;
$$IF178:
	CMP	BYTE PTR [SI-1],NUL	;AN016;CHK FOR END OF THE STRING
;	$IF Z				;ANO16;IT IS E O S
	JNZ $$IF180
	    RET 			;AN016;IT COMPARED
;	$ENDIF				;AN016;
$$IF180:
	JMP	SHORT STRCOMP		;AN016;GO AGAIN
STR_COMP ENDP

MAKE_TEMPLATE PROC NEAR
;copy the formatted filename into the T_TEMPLATE which will be
;used to name a new filename.
;INPUT: PSP FCB 6ch for filename which have global chr.
;
	PUSH	DS			;ES = DS = DATA SEG

	MOV	DS, PSP_SEG		;DS = PSP_SEG

	MOV	SI, PSPFCB2_DRV
	INC	SI
	LEA	DI, T_TEMPLATE
	MOV	CX, 11
	REP	MOVSB			;filename => t_template

	POP	DS			;restore DS
	RET
MAKE_TEMPLATE ENDP

GET_DRIVES PROC NEAR
;get source and target phisical drive letter from parser area.
;set ONE_DISK_COPY_FLAG, if the user XCOPY using the same drive letter.

	MOV	AL, SO_DRIVE		;AN000;source drive letter
	CMP	AL,SPACE		;AN000;IS DRIVE LETTER BLANK?
;	$IF	E			;AN000;YES, GET THE DEFAULT
	JNE $$IF182
	    MOV     AL, SAV_DEFAULT_DRV ;(1=A, 2=B,...)
;	$ELSE				;AN000;NO, CHANGE FROM CHAR TO #
	JMP SHORT $$EN182
$$IF182:
	    SUB     AL,BASE_OF_ALPHA_DRV ;AN000;NEED THE DRV # HERE
;	$ENDIF
$$EN182:
	MOV	S_DRV_NUMBER, AL	;SAVE DRV #
	ADD	AL, BASE_OF_ALPHA_DRV
	MOV	S_DRV, AL		;save source drive letter
	MOV	S_DRV_1, AL
	MOV	S_ARC_DRV, AL
	MOV	SAV_S_DRV, AL

	MOV	AL, TAR_DRIVE		;AN000;target drive letter
	CMP	AL,SPACE		;AN000;IS DRIVE LETTER BLANK?
;	$IF	E			;AN000;YES, GET THE DEFAULT
	JNE $$IF185
	    MOV     AL, SAV_DEFAULT_DRV ;AN000;(1=A, 2=B,...)
;	$ELSE				;AN000;NO, CHANGE FROM CHAR TO #
	JMP SHORT $$EN185
$$IF185:
	    SUB     AL,BASE_OF_ALPHA_DRV ;AN000;NEED THE DRV # HERE
;	$ENDIF
$$EN185:
	MOV	T_DRV_NUMBER, AL	;save target drv #

	CMP	S_DRV_NUMBER, AL	;s_drv_number = t_drv_number?
;	$IF	E
	JNE $$IF188
	    OR	    SYS_FLAG, ONE_DISK_COPY_FLAG ;same logical drv copy
;	$ENDIF
$$IF188:

	ADD	AL, BASE_OF_ALPHA_DRV	;make target drv # to drive letter
	MOV	T_DRV, AL		;target drive letter
	MOV	T_DRV_1, AL
	MOV	T_DRV_2, AL
	MOV	SAV_T_DRV, AL
	RET
GET_DRIVES ENDP
;
;
GET_CUR_DRV PROC NEAR
;get the current default drive number (0 = A, 1 = B ..),
;change it to BIOS drive number and save it.
	MOV	AH, Current_Disk	; = 19h
	INT	21h
	INC	AL			;(1 = A, 2 = B ..)
	MOV	SAV_DEFAULT_DRV, AL	;save it
	RET
GET_CUR_DRV ENDP
;
GET_CUR_DIR PROC NEAR
;get current directory and save it
;input: DL - drive # (0 = default, 1 = A etc)
;	DS:SI - pointer to 64 byte user memory

	MOV	AH, Get_Current_Directory
	INT	21H
	RET
GET_CUR_DIR ENDP
;
TOP_OF_MEM PROC NEAR
;set Top_of_memory

	PUSH	ES
	MOV	BX, PSP_SEG
	MOV	ES, BX
	MOV	AX, ES:2		;PSP top of memory location
	SUB	AX, 140H		;subtract dos transient area (5k)
	MOV	TOP_OF_MEMORY, AX	;save it for buffer top
	POP	ES
	RET
TOP_OF_MEM ENDP

INIT_BUFFER PROC NEAR
;initialize buffer information
;set buffer_base, max_buffer_size
;	call	set_block		;SET BLOCK FOR BUFFR (for new 3.2 linker)
	MOV	AX, OFFSET INIT
	PUSH	CS			;cs segment is the highest segment in this program
	POP	DX
	MOV	BUFFER_PTR, DX
	CALL	SET_BUFFER_PTR
	MOV	AX, BUFFER_PTR
	MOV	BUFFER_BASE, AX 	;set buffer_base
	MOV	AX, BUFFER_LEFT
	CMP	AX, 140h		;BUFFER_LEFT < 5K which is the minimum size this program supports?
	JAE	IB_CONT
	PUSH	AX			;AN000;
	MOV	AX, MSG_INSUF_MEMORY	;AC000;GET THE MESSAGE ID
	MOV	MSG_NUM,AX		;AN000;NEED MESSAGE ID FOR PRINT
	MOV	SUBST_COUNT,NO_SUBST	;AN000;NO SUBSTITUTION TEXT
	MOV	INPUT_FLAG,NO_INPUT	;AN000;NO INPUT = 0
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000;MESSAGE CLASS = -1
	CALL	PRINT_STDERR		;AN000;print error. AX points to msg ID
	POP	AX			;AN000;
	MOV	ERRORLEVEL, 4		;abnormal termination
	JMP	MAIN_EXIT_A		;terminate this program
IB_CONT:
	MOV	MAX_BUFFER_SIZE, AX	;set max buffer size in para
	CMP	AX, 0FFFh		;max_buffer_size > 64 K in para ?
;	$IF	B
	JNB $$IF190
	    MOV     CX, 16
	    MUL     CX			;AX = AX * 16 (DX part will be 0)
	    SUB     AX, 544		;AN000;subtract header size
	    MOV     MAX_CX, AX		;this will be max_cx
;	$ELSE
	JMP SHORT $$EN190
$$IF190:
	    MOV     MAX_CX, 0FFD0h	;else max_cx = fff0 - 32 bytes
					;which is the max # this program can support.
;	$ENDIF				;(min # this program support for buffer is 5 k
$$EN190:
					; which has been decided by BIG_FILE )
	RET
INIT_BUFFER ENDP
;
HOOK_CTRL_BREAK PROC NEAR
;
	PUSH	DS			;save DS
	PUSH	CS
	POP	DS			;ds = cs
	MOV	AX, 2523h
	MOV	DX, OFFSET CTRL_BREAK_EXIT
	INT	21H
	POP	DS			;restore ds
	RET
HOOK_CTRL_BREAK ENDP
;
SAV_HOOK_INT24 PROC NEAR
;sav the int_24 addr, and hooks it to my_int24
	PUSH	ES
	MOV	AH, 35h
	MOV	AL, 24h 		;get critical error handler addr
	INT	21h
	MOV	SAV_INT24_OFF, BX	;offset ip
	MOV	SAV_INT24_SEG, ES	;seg cs
	POP	ES
	PUSH	DS			;save DS
	PUSH	CS
	POP	DS			;ds = cs
	MOV	AH, 25h
	MOV	AL, 24h
	MOV	DX, OFFSET MY_INT24	;now DS:DX contains the addr.
	INT	21h			;hook it to my_int24 routine
	POP	DS			;restore ds
	RET
SAV_HOOK_INT24 ENDP
;
CSEG	ENDS
	END

