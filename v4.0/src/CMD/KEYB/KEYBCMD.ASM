
	PAGE	,132
	TITLE	DOS - KEYB Command  -  Transient Command Processing

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBCMD.ASM
;; ----------
;;
;; Description:
;; ------------
;;	 Contains transient command processing modules for KEYB command.
;;
;; Documentation Reference:
;; ------------------------
;;	 PC DOS 3.3 Detailed Design Document - May ?? 1986
;;
;; Procedures contained in this file:
;; ----------------------------------
;;	 KEYB_COMMAND:	 Main routine for command processing.
;;	 PARSE_PARAMETERS:  Validate syntax of parameters included
;;	     on command line.
;;	 BUILD_PATH: Find KEYBOARD.SYS file and validate language and/or
;;	     code page.
;;	 INSTALL_INT_VECTORS:  Install our INT 9, INT 2F, INT48 Drivers
;;	 REMOVE_INT_VECTORS:  Remove our INT 9, INT 2F, INT48 Drivers
;;	 NUMLK_ON:  Turn on the NUM LOCK LED
;;	 FIND_FIRST_CP: Determine first code page for given language in the
;;	     Keyboard Definition file.
;;
;; Include Files Required:
;; -----------------------
;;	   KEYBMSG.INC
;;	   KEYBEQU.INC
;;	   KEYBSYS.INC
;;	   KEYBI9C.INC
;;	   KEYBI9.INC
;;	   KEYBI2F.INC
;;	   KEYBI48.INC
;;	   KEYBSHAR.INC
;;	   KEYBDCL.INC
;;	   KEYBTBBL.INC
;;	   COMMSUBS.INC
;;	   KEYBCPSD.INC
;;	   POSTEQU.INC
;;	   DSEG.INC
;;
;; External Procedure References:
;; ------------------------------
;;	 FROM FILE  KEYBTBBL.ASM:
;;	      TABLE_BUILD - Create the shared area containing all keyboard tables.
;;	      STATE_BUILD - Build all states within the table area
;;	 FROM FILE  KEYBMSG.ASM:
;;	      KEYB_MESSAGES - All messages
;;
;; Change History:
;;
;;  Revised for DOS 4.00 -   NickS
;;			      A000 - WilfR
;;			      AN002- DCR ???? -KEYBAORD SECURITY LOCK - CNS
;;
;;
;;			      an003  PTM 3906 - KEYB messages do not conform
;;						to spec. Error message does
;;			      3/24/88		not pass back the bogus command
;;						line argument.	      - CNS
;;
;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
	PUBLIC KEYB_COMMAND	       ;;
				       ;;
;*****************CNS********************
	PUBLIC ID_TAB_OFFSET	       ;AN000;
;*****************CNS********************
	PUBLIC CP_TAB_OFFSET	       ;;
	PUBLIC STATE_LOGIC_OFFSET      ;;
	PUBLIC SYS_CODE_PAGE	       ;;
	PUBLIC KEYBCMD_LANG_ENTRY_PTR  ;;
	PUBLIC DESIG_CP_BUFFER	       ;;
	PUBLIC DESIG_CP_OFFSET	       ;;
	PUBLIC KEYBSYS_FILE_HANDLE     ;;
	PUBLIC NUM_DESIG_CP	       ;;
	PUBLIC TB_RETURN_CODE	       ;;
	PUBLIC FILE_BUFFER	       ;;
	PUBLIC FILE_BUFFER_SIZE
	PUBLIC FB		       ;;
;*****************CNS********************
	PUBLIC ID_PTR_SIZE	       ;AN000;
	PUBLIC LANG_PTR_SIZE	       ;AN000;
	PUBLIC CP_PTR_SIZE	       ;AN000;
	PUBLIC NUM_ID		       ;AN000;
	PUBLIC NUM_LANG 	       ;AN000;
	PUBLIC NUM_CP		       ;AN000;
	PUBLIC SHARED_AREA_PTR	       ;;
;*****************CNS********************
	PUBLIC SD_SOURCE_PTR	       ;;
	PUBLIC TEMP_SHARED_DATA        ;;
				       ;;
	PUBLIC FOURTH_PARM	       ;AN000;					    ;AN000
	PUBLIC ONE_PARMID	       ;AN000;					    ;AN000
	PUBLIC FTH_PARMID	       ;AN000;					    ;AN000
	PUBLIC ID_FOUND 	       ;AN000;					    ;AN000
	PUBLIC BAD_ID		       ;AN000;					    ;AN000
	PUBLIC ALPHA		       ;AN000;					    ;AN000
	EXTRN  PARSE_PARAMETERS:NEAR   ;AN000;					    ;AN000
;***CNS
	EXTRN  SECURE_FL:BYTE	       ;an002;
	EXTRN  CUR_PTR:WORD	       ;an003;
	EXTRN  OLD_PTR:WORD	       ;an003;
	EXTRN  ERR_PART:WORD		;an003;
;***CNS
.xlist
	INCLUDE STRUC.INC	       ;AN000;;; WGR structured macros			   ;AN000
	INCLUDE SYSMSG.INC	       ;AN000;;; WGR message retriever			   ;AN000
.list
				       ;;
MSG_UTILNAME <KEYB>		       ;AN000;;; WGR identify to message retriever	   ;AN000
				       ;;
CODE	SEGMENT PUBLIC 'CODE'          ;;
				       ;;
.xlist				       ;;
	INCLUDE KEYBEQU.INC	       ;;
	INCLUDE KEYBSYS.INC	       ;;
	INCLUDE KEYBI9.INC	       ;;
	INCLUDE KEYBI9C.INC	       ;;
	INCLUDE KEYBI2F.INC	       ;;
	INCLUDE KEYBI48.INC	       ;;
	INCLUDE KEYBSHAR.INC	       ;;
	INCLUDE KEYBDCL.INC	       ;;
	INCLUDE KEYBTBBL.INC	       ;;
	INCLUDE COMMSUBS.INC	       ;;
	INCLUDE KEYBCPSD.INC	       ;;
.xlist
	INCLUDE POSTEQU.INC	       ;;
	INCLUDE DSEG.INC	       ;;
				       ;;
.list
	ASSUME	CS:CODE,DS:CODE        ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: KEYB_COMMAND
;;
;; Description:
;;     Main routine for transient command processing.
;;
;; Input Registers:
;;     DS - points to our data segment
;;
;; Output Registers:
;;     Upon termination, if an error has occurred in which a keyboard table
;;     was not loaded, the AL register will contain the a error flag. This
;;     flag is defined as follows:
;;	      AL:= 1 - Invalid language, code page, or syntax
;;		   2 - Bad or missing Keyboard Definition File
;;		   3 - KEYB could not create a table in resident memory
;;		   4 - An error condition was received when communicating
;;		       with the CON device
;;		   5 - Code page requested has not been designated
;;		   6 - The keyboard table for the requested code page cannot
;;		       be found in resident keyboard table.
;;
;; Logic:
;;     IF KEYB has NOT been previously loaded THEN
;;	  Set SHARED_AREA_PTR to TEMP_SHARED_AREA
;;	  INSTALLED_KEYB := 0
;;	  Get HW_TYPE (set local variable)
;;     ELSE
;;	  Set SHARED_AREA_PTR to ES:SHARED_AREA
;;	  Get HW_TYPE (set local variable)
;;	  Set TABLE_OK := 0
;;	  INSTALLED_KEYB := 1
;;
;;     IF CPS-CON has been loaded THEN
;;	  INSTALLED_CON := 1
;;
;;*********************************** CNS *************************************
;;     Call PARSE_PARAMETERS := Edit ID or language, code page,
;;					    and path parameters,ID on command line
;;*********************************** CNS *************************************
;;     Check all return codes:
;;     IF any parameters are invalid THEN
;;	  Display ERROR message
;;     ELSE
;;	  IF no language parm specified
;;				 AND code page is not invalid
;;						     AND syntax is valid THEN
;;	     Process QUERY:
;;	     IF KEYB is installed THEN
;;		 Get and display active language from SHARED_DATA_AREA
;;		 Get invoked code page from SHARED_DATA_AREA
;;		 Convert to ASCII
;;		 Display ASCII representation of code page, CR/LF
;;*********************************** CNS *************************************
;;	     IF ALTERNATE FLAG SET
;;		 Get and display active ID from SHARED_DATA_AREA
;;		 Convert to ASCII
;;		 Display ASCII representation of ID, CR/LF
;;*********************************** CNS *************************************
;;	     IF CPS-CON is installed THEN
;;		 Get selected code page info from CON
;;		 Convert to ASCII
;;		 Display ASCII representation of code page, CR/LF
;;	     EXIT without staying resident
;;
;;	  ELSE
;;	     Call BUILD_PATH := Determine location of Keyboard definition file
;;	     Open the file
;;	     IF error in opening file THEN
;;		Display ERROR message and EXIT
;;	     ELSE
;;		Save handle
;;		Set address of buffer
;;		READ header of Keyboard definition file
;;		IF error in reading file THEN
;;		   Display ERROR message and EXIT
;;		ELSE
;;		   Check signature for correct file
;;		   IF file signature is correct THEN
;;		      READ language table
;;		      IF error in reading file THEN
;;			  Display ERROR message and EXIT
;;		      ELSE
;;			  Use table to verify language parm
;;			  Set pointer values
;;			  IF code page was specified
;;			      READ language entry
;;			      IF error in reading file THEN
;;				   Display ERROR message and EXIT
;;			      ELSE
;;				   READ Code page table
;;				   IF error in reading file THEN
;;				       Display ERROR message and EXIT
;;				   ELSE
;;				       Use table to verify code page parm
;;				       Set pointer values
;;     IF CPS-CON is not installed THEN
;;	    Set number of code pages = 1
;;	    IF CODE_PAGE_PARM was specified THEN
;;	       Copy CODE_PAGE_PARM into table of code pages to build
;;	    ELSE
;;	       Call FIND_FIRST_CP := Define the system code page (1st in Keyb Def file)
;;	       Copy SYSTEM_CP into table of code pages to build
;;     ELSE
;;	    Issue INT 2F ; 0AD03H  to get table of Designated code pages
;;	    Set number of designated code pages (HWCP + Desig CP)
;;	    Issue INT 2F ; 0AD02H  to get invoked code page
;;	    IF CODE_PAGE_PARM was specified THEN
;;	       Check that CODE_PAGE_PARM is in the list of designated code pages
;;	       IF CODE_PAGE_PARM is in the list of designated code pages THEN
;;		    Copy specified CP into table of code pages to build
;;		    IF a CP has been selected AND is inconsistent with specified CP
;;			Issue WARNING message
;;	       ELSE
;;		    Display ERROR message
;;	    ELSE
;;	       IF a code page has been invoked THEN
;;		    Copy invoked code page into table of code pages to build
;;	       ELSE
;;		    Call FIND_FIRST_CP := Define the system code page (1st in Keyb Def file)
;;		    Copy SYSTEM_CP into table of code pages to build
;;
;;     IF KEYB has not been previously installed THEN
;;	  Call FIND_SYS_TYPE := Determine system type
;;	  IF system type is PCjr THEN
;;	      IF multilingual ROM is present THEN
;;		   Set language code
;;		   EXIT without staying resident
;;	  Call INSTALL_INT_9 := Install INT 9 handler
;;	  Call FIND_KEYB_TYPE := Determine the keyboard type
;;
;;     Call TABLE_BUILD := Build the TEMP_SHARED_DATA_AREA
;;
;;     IF return codes from TABLE_BUILD are INVALID THEN
;;	  IF KEYB_INSTALLED := 0 THEN
;;	      Call REMOVE_INT_9
;;	  Display corresponding ERROR message
;;	  EXIT without staying resident
;;     ELSE
;;	  IF any of the designated CPs were invalid in the build THEN
;;	      Issue WARNING message
;;	  Close the Keyboard definition file
;;	  IF KEYB had NOT already been installed THEN
;;	      IF keyboard is a Ferrari_G AND system is not an XT THEN
;;	      Call NUMLK_ON := Turn the NUM LOCK LED on
;;	      IF extended INT 16 support required THEN
;;		 Install extended INT 16 support
;;	      Call INSTALL_INT_9_NET := Let network know about INT 9
;;	      Call INSTALL_INT_2F_48 := Install the INT 2F and INT 48 drivers
;;	      Activate language
;;	      Get resident end and copy TEMP_SHARED_DATA_AREA into SHARED_DATA_AREA
;;	      EXIT but stay resident
;;	  ELSE
;;	      IF this was not a query call AND exit code was valid THEN
;;		 Activate language
;;		 Get resident end and copy TEMP_SHARED_DATA_AREA into SHARED_DATA_AREA
;;	      EXIT without staying resident
;;     END
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
INVALID_PARMS	     EQU  1	       ;;  EXIT return codes
BAD_KEYB_DEF_FILE    EQU  2	       ;;
MEMORY_OVERFLOW      EQU  3	       ;;
CONSOLE_ERROR	     EQU  4	       ;;
CP_NOT_DESIGNATED    EQU  5	       ;;
KEYB_TABLE_NOT_LOAD  EQU  6	       ;;
BAD_DOS_VER	     EQU  7	       ;AN000;;; WGR					   ;AN000
				       ;;
EXIT_RET_CODE	     DB   0	       ;;
;******************** CNS ***********  ;AN000;;;
ID_VALID	     EQU  0	       ;AN000;;;
ID_INVALID	     EQU  1	       ;AN000;;;
NO_ID		     EQU  2	       ;AN000;;;
LANGUAGE_VALID	     EQU  0	       ;AN000;;;
LANGUAGE_INVALID     EQU  1	       ;AN000;;;  Return Codes
NO_LANGUAGE	     EQU  2	       ;AN000;;;    from
NO_IDLANG	     EQU  3	       ;AN000;;;
;******************** CNS ***********  ;;
CODE_PAGE_VALID      EQU  0	       ;;     EDIT_LANGUAGE_CODE
CODE_PAGE_INVALID    EQU  1	       ;;
NO_CODE_PAGE	     EQU  2	       ;;
VALID_SYNTAX	     EQU  0	       ;;
INVALID_SYNTAX	     EQU  1	       ;;;;;;;
					    ;;
ACT_KEYB	     EQU  2		    ;AC000;;; WGR				   ;AN000
ACT_ID		     EQU  3		    ;AC000;;; WGR				   ;AN000
ACT_KEYB_CP	     EQU  4		    ;AC000;;; WGR				   ;AN000
ACT_CON_CP	     EQU  5		    ;AC000;;; WGR				   ;AN000
INV_L		     EQU  6		    ;AC000;;; WGR message numbers...		   ;AN000
INV_I		     EQU  7		    ;AC000;;; WGR				   ;AN000
INV_CP		     EQU  8		    ;AC000;;; WGR				   ;AN000
INV_S		     EQU  18		    ;AC000;;; WGR				   ;AN000
INV_FN		     EQU  9		    ;AC000;;; WGR				   ;AN000
INV_KEYB_Q	     EQU  10		    ;AC000;;; WGR				   ;AN000
INV_CON_Q	     EQU  11		    ;AC000;;; WGR				   ;AN000
NOT_DESIG	     EQU  12		    ;AC000;;; WGR				   ;AN000
NOT_SUPP	     EQU  13		    ;AC000;;; WGR				   ;AN000
NOT_VALID	     EQU  14		    ;AC000;;; WGR				   ;AN000
WARNING_1	     EQU  15		    ;AC000;;; WGR				   ;AN000
INV_COMBO	     EQU  16		    ;AC000;;; WGR				   ;AN000
MEMORY_OVERF	     EQU  17		    ;AC000;;; WGR				   ;AN000
CR_LF		     DB   10,13,'$'         ;; WGR                                  ;AN000
					    ;;
FOURTH_PARM    DB	0		    ;AN000;;; WGR switch was specified		   ;AN000
ONE_PARMID     DB	0		    ;AN000;;; WGR id given as positional	   ;AN000
FTH_PARMID     DB	0		    ;AN000;;; WGR id given as switch		   ;AN000
ID_FOUND       DB	0		    ;AN000;;; WGR id was good (in k.d. file)	   ;AN000
BAD_ID	       DB	0		    ;AN000;;; WGR id was bad (from parse)	   ;AN000
ALPHA	       DB	0		    ;AN000;;; WGR first parm a language id	   ;AN000
					    ;;
ID_DISPLAYED   DB	0		    ;AN000;;; WGR Indicating ID already displayed  ;AN000
					    ;; WGR				    ;AN000
SUBLIST_NUMBER LABEL BYTE		    ;AN000;;; WGR sublist for numbers		   ;AN000
	       DB	11		    ;AN000;;; WGR size				   ;AN000
	       DB	0		    ;AN000;;; WGR				   ;AN000
PTR_TO_NUMBER  DW	?		    ;AN000;;; WGR offset ptr			   ;AN000
SEG_OF_NUMBER  DW	?		    ;AN000;;; WGR segment			   ;AN000
	       DB	1		    ;AN000;;; WGR				   ;AN000
	       DB	10100001B	    ;AN000;;; WGR flag				   ;AN000
	       DB	3		    ;AN000;;; WGR max width			   ;AN000
	       DB	1		    ;AN000;;; WGR min width			   ;AN000
	       DB	" "                 ;AN000;;; WGR filler                           ;AN000
					    ;AN000;;; WGR
					    ;AN000;;; WGR
SUBLIST_ASCIIZ LABEL BYTE		    ;AN000;;; WGR sublist for asciiz		   ;AN000
	       DB	11		    ;AN000;;; WGR size				   ;AN000
	       DB	0		    ;AN000;;; WGR				   ;AN000
PTR_TO_ASCIIZ  DW	?		    ;AN000;;; WGR offset ptr			   ;AN000
SEG_OF_ASCIIZ  DW	?		    ;AN000;;; WGR segment			   ;AN000
	       DB	1		    ;AN000;;; WGR				   ;AN000
	       DB	00010000B	    ;AN000;;; WGR flag				   ;AN000
	       DB	2		    ;AN000;;; WGR max width			   ;AN000
	       DB	2		    ;AN000;;; WGR min width			   ;AN000
	       DB	" "                 ;AN000;;; WGR filler                           ;AN000
					    ;AN000;;; WGR				   ;AN000
NUMBER_HOLDER  DW	?		    ;AN000;;; WGR used for message retriever	   ;AN000
;***CNS
SUBLIST_COMLIN LABEL BYTE		    ;an003;;; WGR sublist for asciiz		   ;AN000
	       DB	11		    ;an003;;; WGR size				   ;AN000
	       DB	0		    ;an003;;; WGR				   ;AN000
PTR_TO_COMLIN  DW	?		    ;an003;;; WGR offset ptr			   ;AN000
SEG_OF_COMLIN  DW	?
	       DB	0		    ;an003;;; WGR				   ;AN000
	       DB	LEFT_ALIGN+CHAR_FIELD_ASCIIZ  ;AN000;;; WGR flag			     ;AN000

	       DB	0		    ;an003;;; WGR max width			   ;AN000
	       DB	1		    ;an003;;; WGR min width			   ;AN000
	       DB	" "                 ;an003;;; WGR filler                           ;AN000


STRING_HOLDER  DB	64 DUP(0)
;***CNS 				    ;;
					    ;;
FILE_BUFFER_SIZE     EQU  50*6
FILE_BUFFER	     DB   FILE_BUFFER_SIZE DUP(0) ;AC000;;; Buffer for Keyboard Def file
FB		     EQU  FILE_BUFFER	    ;AC000;m for 32 language entries)
DESIG_CP_BUFFER      DW   28 DUP(?)	    ;; (Room for 25 code pages)
DESIG_CP_BUF_LEN     DW   $-DESIG_CP_BUFFER ;;	Length of code page buffer
NUM_DESIG_CP	     DW   0		    ;;
CP_TAB_OFFSET	     DD   ?		    ;;
;******************  CNS  ******************;AN000;
TOTAL_SIZE	     DW   0		    ;AN000;
PASS_LANG	     DW   0		    ;AN000;
ID_TAB_OFFSET	     DD   ?		    ;AN000;
;******************  CNS  ******************;;
STATE_LOGIC_OFFSET   DD   -1		    ;;
KEYBSYS_FILE_HANDLE  DW   ?		    ;;;;;;;;;;;
TB_RETURN_CODE	     DW   1			     ;;
DESIG_CP_OFFSET      DW   OFFSET DESIG_CP_BUFFER     ;;
SYS_CODE_PAGE	     DW   0			     ;;
DESIG_LIST	     DW   0			     ;;
QUERY_CALL	     DB   0			     ;;
						     ;;
KB_MASK 	     EQU  02h			     ;;
						     ;;
SIGNATURE	     DB   0FFh,'KEYB   '             ;;
SIGNATURE_LENGTH     DW   8			     ;;
;******************  CNS  ***************************;AN000;
NUM_ID		     DW   0			     ;AN000;
ERR4ID		     DB   0			     ;AN000;
NUM_LANG	     DW   0			     ;AN000;
NUM_CP		     DW   0			     ;AN000;
ID_PTR_SIZE	     DW   SIZE KEYBSYS_ID_PTRS	     ;AN000;
;******************  CNS  *****************************
LANG_PTR_SIZE	     DW   SIZE KEYBSYS_LANG_PTRS     ;;
CP_PTR_SIZE	     DW   SIZE KEYBSYS_CP_PTRS	     ;;
KEYBCMD_LANG_ENTRY_PTR DD ?			     ;;
						     ;;
KEYB_INSTALLED	     DW   0			     ;;
CON_INSTALLED	     DW   0			     ;;
SHARED_AREA_PTR      DD   0			     ;;
GOOD_MATCH	     DW   0			     ;;
;******************  CNS  ***************************;;
LANGUAGE_ASCII	     DB   '??',0                     ;; WGR                         ;AC000
						     ;;
CMD_PARM_LIST	     PARM_LIST <>		     ;;
						     ;;
JR_LANGUAGE_CODES    DW   'FR','GR','IT','SP','UK'   ;;
						     ;;
JR_NUM_CODES	     EQU   5			     ;;
						     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;----------  TABLES FOR EXTENDED KEYBOARD SUPPORT CTRL CASE  ---------	   RWV 11-06-85 ;;
											;;
RPL_K8	LABEL	BYTE			;-------- CHARACTERS ---------			;;
	DB	27,-1,00,-1,-1,-1	; Esc, 1, 2, 3, 4, 5				;;
	DB	30,-1,-1,-1,-1,31	; 6, 7, 8, 9, 0, -				;;
	DB	-1,127,148,17,23,5	; =, Bksp, Tab, Q, W, E 			;;
	DB	18,20,25,21,09,15	; R, T, Y, U, I, O				;;
	DB	16,27,29,10,-1,01	; P, [, ], Enter, Ctrl, A			;;
	DB	19,04,06,07,08,10	; S, D, F, G, H, J				;;
	DB	11,12,-1,-1,-1,-1	; K, L, ;, ', `, LShift                         ;;
	DB	28,26,24,03,22,02	; \, Z, X, C, V, B				;;
	DB	14,13,-1,-1,-1,-1	; N, M, ,, ., /, RShift 			;;
	DB	150,-1,' ',-1           ; *, Alt, Space, CL                             ;;
					;--------- FUNCTIONS ---------			;;
	DB	94,95,96,97,98,99	; F1 - F6					;;
	DB	100,101,102,103,-1,-1	; F7 - F10, NL, SL				;;
	DB	119,141,132,142,115,143 ; Home, Up, PgUp, -, Left, Pad5 		;;
	DB	116,144,117,145,118,146 ; Right, +, End, Down, PgDn, Ins		;;
	DB	147,-1,-1,-1,137,138	; Del, SysReq, Undef, WT, F11, F12		;;
L_CTRL_TAB	EQU	$-RPL_K8							;;
											;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						    ;;
KEYB_COMMAND  PROC NEAR 			    ;;
						    ;;
	CALL  SYSLOADMSG			    ;AN000;load messages		 ;AN000
	JNC   VERSION_OK			    ;AN000;if no carry then version ok	 ;AN000
	CALL  SYSDISPMSG			    ;AN000;error..display version error  ;AN000
	MOV   AL,BAD_DOS_VER			    ;AN000;bad DOS version		 ;AN000
	MOV   EXIT_RET_CODE,AL			    ;AN000;				 ;AN000
	JMP   KEYB_EXIT_NOT_RESIDENT		    ;AN000;exit..non resident		 ;AN000
VERSION_OK:					    ;; WGR				 ;AN000
	MOV   SEG_OF_NUMBER,CS			    ;AN000;initialize.. 		 ;AN000
	MOV   SEG_OF_ASCIIZ,CS			    ;AN000;  ..sublists 		 ;AN000
	MOV   BP,OFFSET CMD_PARM_LIST		    ;AN000;pointer for parm list
	MOV   WORD PTR SHARED_AREA_PTR,ES	    ;AN000; ES segment
						    ;;
KEYB_INSTALL_CHECK:				    ;;
	MOV   AX,0AD80H 			    ;; KEYB install check
	INT   2FH				    ;;
	CMP   AL,-1				    ;; If flag is not 0FFh THEN
	JE    INSTALLED_KEYB			    ;;
	MOV   WORD PTR SHARED_AREA_PTR+2,OFFSET TSD ;;
	JMP   CON_INSTALL_CHECK 		    ;;
					    ;;;;;;;;;;
INSTALLED_KEYB: 			    ;;
	MOV   KEYB_INSTALLED,1		    ;;	Set KEYB_INSTALLED flag = YES
	MOV   WORD PTR SHARED_AREA_PTR,ES   ;;	Save segment of SHARED_DATA_AREA
	MOV   WORD PTR SHARED_AREA_PTR+2,DI ;;	Save offset of SHARED_DATA_AREA
	MOV   AX,ES:[DI].KEYB_TYPE	    ;;
	MOV   HW_TYPE,AX		    ;;
	MOV   ES:[DI].TABLE_OK,0	    ;;	Do not allow processing
	PUSH  CS			    ;;		  while building table
	POP   ES			    ;;	Reset ES until required
					    ;;
CON_INSTALL_CHECK:		       ;;;;;;;
	MOV   AX,0AD00H 	       ;; CONSOLE install check
	INT   2FH		       ;;
	CMP   AL,-1		       ;; If flag is not 0FFh THEN
	JE    INSTALLED_CON	       ;;
	JMP   CALL_FIRST_STAGE	       ;;
				       ;;
INSTALLED_CON:			       ;;
	MOV   CON_INSTALLED,1	       ;;    Set CON_INSTALLED flag = YES
				       ;;
CALL_FIRST_STAGE:		       ;;
	PUSH  CS		       ;;
	POP   ES		       ;;
	CALL  PARSE_PARAMETERS	       ;; Validate parameter list
				       ;;
BEGIN_PARM_CHECK:		       ;; CHECK ALL RETURN CODES
	MOV   DL,[BP].RET_CODE_3       ;;
	CMP   DL,1		       ;; Check for invalid syntax
	JNE   VALID1		       ;;
	JMP   ERROR3		       ;;
				       ;;
VALID1: 			       ;;
	MOV   DL,[BP].RET_CODE_1       ;; Check for invalid language parm
	CMP   DL,1		       ;;
	JNE   VALID2		       ;;
	JMP   ERROR1		       ;;
				       ;;
VALID2: 			       ;;
	MOV   DL,[BP].RET_CODE_2       ;; Check for invalid code page parm
	CMP   DL,1		       ;;
	JNE   VALID3		       ;;
	JMP   ERROR2		       ;;
				       ;;
VALID3: 			       ;;
	MOV   DL,[BP].RET_CODE_1       ;; Check for query command
	CMP   DL,2		       ;;
	JE    QUERY		       ;;
;******************************* CNS **;;
	MOV   DL,[BP].RET_CODE_1       ;AN000;k for query command
	CMP   DL,3		       ;AN000;;; Get a status of the codepage
	JE    QUERY		       ;AN000;;; language, and possible ID code
;******************************* CNS **;;
	JMP   NOT_QUERY 	       ;;
				       ;; IF QUERY is requested THEN
QUERY:				       ;;
	MOV   QUERY_CALL,DL	       ;;
	MOV   AX,KEYB_INSTALLED        ;;     If KEYB is installed THEN
	CMP   AX,0		       ;;
	JE    QUERY_CONTINUE1	       ;;;;;;;;;;;;;;;;
						     ;;
	MOV   DI,WORD PTR SHARED_AREA_PTR+2	     ;; Get offset of
	MOV   ES,WORD PTR SHARED_AREA_PTR	     ;; 	 shared area
	MOV   BX,WORD PTR ES:[DI].ACTIVE_LANGUAGE    ;; Get active language
	CMP   BX,0				     ;; WGR if no language..		 ;AN000
	JE    I_MESSAGE 			     ;; WGR then id was specified	 ;AN000
						     ;;
					   ;;;;;;;;;;;;
L_MESSAGE:				   ;;
	MOV   WORD PTR LANGUAGE_ASCII,BX   ;AC000;;;  Display Language
	LEA   SI,LANGUAGE_ASCII 	   ;AN000;;; WGR sublist points to...			;AN000
	MOV   PTR_TO_ASCIIZ,SI		   ;AN000;;; WGR language code asciiz string		;AN000
	MOV   AX,ACT_KEYB		   ;AC000;;; WGR display 'Current keyboard code'        ;AN000
	MOV   BX,STDOUT 		   ;AN000;;; WGR to standard out			;AN000
	MOV   CX,1			   ;AN000;;; WGR one replacement			;AN000
	MOV   DH,UTILITY_MSG_CLASS	   ;AN000;;; WGR utility message			;AN000
	XOR   DL,DL			   ;AN000;;; WGR no input				;AN000
	LEA   SI,SUBLIST_ASCIIZ 	   ;AN000;;; WGR ptr to sublist 			;AN000
	CALL  SYSDISPMSG		   ;AN000;;; WGR					;AN000
	JMP   KEYB_L_FINISHED		   ;;
					   ;;;;;;;
I_MESSAGE:					;;
	MOV   BX,WORD PTR ES:[DI].INVOKED_KBD_ID;AN000;;; WGR get id code.			;AN000
	MOV   NUMBER_HOLDER,BX			;AN000;;; WGR transfer number to temp loc.	;AN000
	LEA   SI,NUMBER_HOLDER			;AN000;;; WGR sublist points to...		;AN000
	MOV   PTR_TO_NUMBER,SI			;AN000;;; WGR code page word			;AN000
	MOV   AX,ACT_ID 			;AN000;;; WGR display 'Current ID:  '           ;AN000
	MOV   BX,STDOUT 			;AN000;;; WGR to standard out			;AN000
	MOV   CX,1				;AN000;;; WGR one replacement			;AN000
	MOV   DH,UTILITY_MSG_CLASS		;AN000;;; WGR utility message			;AN000
	XOR   DL,DL				;AN000;;; WGR no input				;AN000
	LEA   SI,SUBLIST_NUMBER 		;AN000;;; WGR ptr to sublist			;AN000
	CALL  SYSDISPMSG			;AN000;;; WGR					;AN000
	MOV   ID_DISPLAYED,1			;AN000;;; WGR ID was displayed. 		;AN000
	JMP   KEYB_L_FINISHED			;AN000;;; WGR					;AN000
				       ;;;;;;;;;;;
QUERY_CONTINUE1:		       ;;
	MOV   AX,INV_KEYB_Q	       ;AC000;;; WGR						;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR Else					;AN000
	XOR   CX,CX		       ;AC000;;; WGR	Display message that KEYB		;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR	  has not been installed		;AN000
	XOR   DL,DL		       ;AN000;;; WGR						;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR						;AN000
	JMP   KEYB_CP_FINISHED	       ;AC000;;;
				       ;;;;;;;;;;;
KEYB_L_FINISHED:				;;
	MOV   BX,ES:[DI].INVOKED_CP_TABLE	;; Get invoked code page
						;;
	MOV   NUMBER_HOLDER,BX			;AN000;;; WGR transfer number to temp loc.	;AN000
	LEA   SI,NUMBER_HOLDER			;AN000;;; WGR sublist points to...		;AN000
	MOV   PTR_TO_NUMBER,SI			;AN000;;; WGR code page word			;AN000
	MOV   AX,ACT_KEYB_CP			;AC000;;; WGR display '  code page: '           ;AN000
	MOV   BX,STDOUT 			;AN000;;; WGR to standard out			;AN000
	MOV   CX,1				;AN000;;; WGR one replacement			;AN000
	MOV   DH,UTILITY_MSG_CLASS		;AN000;;; WGR utility message			;AN000
	XOR   DL,DL				;AN000;;; WGR no input				;AN000
	LEA   SI,SUBLIST_NUMBER 		;AN000;;; WGR ptr to sublist			;AN000
	CALL  SYSDISPMSG			;AN000;;; WGR					;AN000
	CMP   ID_DISPLAYED,1			;AN000;;; WGR was id displayed? 		;AN000
	JE    KEYB_CP_FINISHED			;AN000;;; WGR yes..continue.			;AN000
						;;
	MOV   BX,WORD PTR ES:[DI].INVOKED_KBD_ID;AN000;;; WGR get id code.			;AN000
	CMP   BX,0				;AN000;;; WGR no id given..			;AN000
	JE    KEYB_CP_FINISHED			;AN000;;; WGR					;AN000
						;;
	MOV   NUMBER_HOLDER,BX			;AN000;;; WGR transfer number to temp loc.	;AN000
	LEA   SI,NUMBER_HOLDER			;AN000;;; WGR sublist points to...		;AN000
	MOV   PTR_TO_NUMBER,SI			;AN000;;; WGR code page word			;AN000
	MOV   AX,ACT_ID 			;AC000;;; WGR display 'Current ID:  '           ;AN000
	MOV   BX,STDOUT 			;AN000;;; WGR to standard out			;AN000
	MOV   CX,1				;AN000;;; WGR one replacement			;AN000
	MOV   DH,UTILITY_MSG_CLASS		;AN000;;; WGR utility message			;AN000
	XOR   DL,DL				;AN000;;; WGR no input				;AN000
	LEA   SI,SUBLIST_NUMBER 		;AN000;;; WGR ptr to sublist			;AN000
	CALL  SYSDISPMSG			;AN000;;; WGR					;AN000
	MOV   AH,09H				;AC000;;; WGR need a CR_LF here.		;AN000
	MOV   DX,OFFSET CR_LF			;AC000;;; WGR					;AN000
	INT   21H				;; WGR					 ;AN000
				       ;;;;;;;;;;;
KEYB_CP_FINISHED:		       ;;
	MOV   AX,CON_INSTALLED	       ;;  If CON has been installed THEN
	CMP   AX,0		       ;;
	JNE   GET_ACTIVE_CP	       ;;
	JMP   CON_NOT_INSTALLED        ;;
				       ;;
GET_ACTIVE_CP:			       ;;
	MOV   AX,0AD02H 	       ;;  Get active code page
	INT   2FH		       ;;	  information from the console
	JNC   DISPLAY_ACTIVE_CP        ;;
	JMP   ERROR5		       ;;
				       ;;
DISPLAY_ACTIVE_CP:		       ;;
	MOV   NUMBER_HOLDER,BX	       ;AC000;;; WGR transfer number to temp loc.		;AN000
	LEA   SI,NUMBER_HOLDER	       ;AC000;;; WGR sublist points to...			;AN000
	MOV   PTR_TO_NUMBER,SI	       ;AC000;;; WGR code page word				;AN000
	MOV   AX,ACT_CON_CP	       ;AN000;;; WGR display 'Current CON code page: '          ;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR to standard out				;AN000
	MOV   CX,1		       ;AN000;;; WGR one replacement				;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR utility message				;AN000
	XOR   DL,DL		       ;AN000;;; WGR no input					;AN000
	LEA   SI,SUBLIST_NUMBER        ;AN000;;; WGR ptr to sublist				;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR						;AN000
				       ;;
	JMP   KEYB_EXIT_NOT_RESIDENT   ;;  Exit from Proc
				       ;;
CON_NOT_INSTALLED:		       ;; ELSE
	MOV   AX,INV_CON_Q	       ;AC000;WGR					     ;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR Else					;AN000
	XOR   CX,CX		       ;AN000;;; WGR	Display message that CON does		;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR	  not have active code page		;AN000
	XOR   DL,DL		       ;AN000;;; WGR						;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR						;AN000
	JMP   KEYB_EXIT_NOT_RESIDENT   ;; Exit from Proc
				       ;;
NOT_QUERY:			       ;; IF not a query function requested
	CALL  BUILD_PATH	       ;; Determine location of KEYBOARD.SYS
				       ;; WGR ...and open file. 			 ;AC000
				       ;;
	JNC   VALID4		       ;; If no error in opening file then
	JMP   ERROR4		       ;;
				       ;;
VALID4: 			       ;;
	MOV   KEYBSYS_FILE_HANDLE,AX   ;; Save handle
	MOV   BP,OFFSET CMD_PARM_LIST  ;; Set base pointer for structures
	MOV   BX,KEYBSYS_FILE_HANDLE   ;; Retrieve the file handle
	MOV   DX,OFFSET FILE_BUFFER    ;; Set address of buffer
;************************* CNS ********;;
	cmp   [BP].RET_CODE_4,ID_VALID ;AN000;	 ;; CNS is there an ID available
	je    ID_TYPED		       ;AN000;	 ;; if so go find out if it is
	jmp   GET_LANG		       ;AN000;	 ;; a 1st or 4th parm, if not must
				       ;AN000;	 ;; must be a language
ID_TYPED:			       ;AN000;

	call  SCAN_ID		       ;AN000;	 ;; scan the table for the ID
	cmp   ID_FOUND,1	       ;AN000;	 ;; if a legal ID check and see if
	jne   LOST_ID		       ;AN000;	 ;; it is a first or fourth parm
	cmp   FTH_PARMID,1	       ;AN000;	 ;; if it is a fourth parm go
	je    GET_ID		       ;AN000;	 ;; check for language compatibility
	jmp   Language_found	       ;AN000;	 ;; otherwise it must be a first
					  ;; parm id value

LOST_ID:			       ;AN000;	 ;; otherwise must be a bogus match
					  ;; between language and ID codes
					  ;; or the ID code does not exist
	jmp   ERR1ID		       ;AN000;	 ;; in the table
;************************* CNS ***********;;
GET_LANG:				  ;; Must be a language/or a 1st parm ID
				       ;;;;;
				       ;;
	XOR   DI,DI		       ;; Set number
	LEA   CX,[DI].KH_NUM_LANG+2    ;;	 bytes to read header
				       ;;
	MOV   AH,3FH		       ;; Read header of the Keyb Def file
	INT   21H		       ;;
	JNC   VALID5		       ;; If no error in opening file then
	JMP   ERROR4		       ;;
				       ;;;;
VALID5: 				 ;;
	CLD				 ;; WGR all moves/scans forward 		 ;AN000
	MOV   CX,SIGNATURE_LENGTH	 ;;
	MOV   DI,OFFSET SIGNATURE	 ;; Verify matching
	MOV   SI,OFFSET FB.KH_SIGNATURE  ;;	     signatures
	REPE  CMPSB			 ;;
	JE    LANGUAGE_SPECIFIED	 ;;
	JMP   ERROR4		       ;;;;
				       ;; READ the language table
LANGUAGE_SPECIFIED:		       ;;
	MOV   AX,FB.KH_NUM_LANG        ;;
	MOV   NUM_LANG,AX	       ;; Save the number of languages
	MUL   LANG_PTR_SIZE	       ;; Determine # of bytes to read
	MOV   DX,OFFSET FILE_BUFFER    ;; Establish beginning of buffer
	MOV   CX,AX		       ;;
	CMP   CX,FILE_BUFFER_SIZE      ;; Make sure buffer is not to small
	JBE   READ_LANG_TAB	       ;;
	JMP   ERROR4		       ;;
				       ;;
READ_LANG_TAB:			       ;;
	MOV   AH,3FH		       ;; Read language table from
	INT   21H		       ;;	       Keyb Def file
	JNC   READ_VALID	       ;; If no error in opening file then
	JMP   ERROR4		       ;; Else display ERROR message
				       ;;
READ_VALID:			       ;;
	MOV   CX,NUM_LANG	       ;;    Number of valid codes
	MOV   DI,OFFSET FILE_BUFFER    ;;    Point to correct word in table
				       ;;
SCAN_LANG_TABLE:		       ;; FOR language parm
	MOV   AX,[BP].LANGUAGe_PARM    ;;    Get parameter
	CMP   [DI].KP_LANG_CODE,AX     ;;    Valid Code ??
	JE    LANGUAGE_FOUND	       ;; If not found AND more entries THEN
	ADD   DI,LANG_PTR_SIZE	       ;;    Check next entry
	DEC   CX		       ;;    Decrement count of entries
	JNE   SCAN_LANG_TABLE	       ;; Else
	JMP   ERROR1		       ;;    Display error message
					;;;;;;;;;;;;;;
;**************************** CNS ****;;;;
GET_ID: 				;AN000;;; CNS - Must be an ID value
	mov	cx,1			;AN000;;; initialize ctr value for # of ids
					;;
SEARCH_ID:				;AN000;;; minimum per country
;.WHILE  <cx ne 0>			;AN000;;; There is atleast 1 ID for each country
	cmp	cx,0			;AN000;;; Check for any more IDs left to check
	jne	FINDID			;AN000;;; Country has more than one ID check
	jmp	END_IDCHK		;AN000;;; Country & ID has been found or value
					;; is zero
FINDID: 				;AN000;

	push	di			;AN000;;; save the current language entry ptr
	push	cx			;AN000;;; save the minimum # of ids before
					;; reading the table data from the disk
;**************************** CNS *****************;;
LANGUAGE_FOUND: 				   ;;
	MOV   CX,WORD PTR [DI].KP_ENTRY_PTR+2	   ;; Get offset of lang entry
	MOV   DX,WORD PTR [DI].KP_ENTRY_PTR	   ;;	in the Keyb Def file
	MOV   WORD PTR KEYBCMD_LANG_ENTRY_PTR,DX   ;; Save
	MOV   WORD PTR KEYBCMD_LANG_ENTRY_PTR+2,CX ;;	offset
	MOV   AH,42H				   ;; Move file pointer to
	MOV   AL,0			      ;;;;;;;	location of language
	INT   21H			      ;;	    entry
	JNC   LSEEK_VALID		      ;;
	JMP   ERROR4			      ;;
					      ;;
LSEEK_VALID:				      ;;
	MOV   DI,AX			      ;;
	MOV   CX,SIZE KEYBSYS_LANG_ENTRY-1    ;; Set number
					      ;;	bytes to read header
	MOV   DX,OFFSET FILE_BUFFER    ;;;;;;;;;
	MOV   AH,3FH		       ;; Read language entry in
	INT   21H		       ;;	 Keyb Def file
	JNC   VALID6a		       ;; If no error in file then
	JMP   ERROR4		       ;;;;;;;;;;
;**************************** CNS **********************************************


valid6a:
	cmp   FOURTH_PARM,1		;AN000;;; Is the ID a 4th Parm
	jne   VALID6			;AN000;;; if not get out of routine, otherwise
	pop	cx			;AN000;;;restore # of ids for the country
      ; .IF <cx eq 1>			;AN000;;;Check to see if this is the first
					;AN000;;;time checking the primary ID
	cmp	cx,1			;AN000;;;if there is just one ID check to make
	jne	CHK4PARM		;AN000;;;sure both flags are not set
					;AN000;;; this should not be necessary w/ new parser
	cmp	 FTH_PARMID,1		;AN000;;; is the ID flag for switch set
	jne	 CHK1N4 		;AN000;;; is the flag set only for the 4th
	cmp	 FOURTH_PARM,1		;AN000;;; if set only for the switch proceed
	jne	 CHK1N4 		;AN000;;; if not must be a positional
	mov	 cl,fb.kl_num_id	;AN000;;; get the number of IDs available from the table
	mov	 FTH_PARMID,0		;AN000;;; turn switch flag off so the table
					;AN000;;; counter will not be reset

						   ;;ids available for the
CHK1N4: 				;AN000; 	  ;;country
	cmp ONE_PARMID,1		;AN000; 	  ;; this was to be done if
	jne CHK4PARM			;AN000; 	  ;; two the positional
	cmp FOURTH_PARM,0		;AN000; 	  ;; and switch was specified
	jne CHK4PARM			;AN000; 	  ;; this should never happen
	pop di				;AN000; 	  ;; if the parser is intact
	jmp error3			;AN000; 	  ;; report error & exit

CHK4PARM:				;AN000; 	   ;; check on the first ID
      ; .IF <FOURTH_PARM EQ 1>		;AN000; 	   ;;switch specified
      ;     call IDLANG_CHK		;AN000; 	   ;;check the lang-id combo
      ; .ELSE				;AN000;
      ;     xor  cx,cx			;AN000; 	   ;;clear to exit loop
      ; .ENDIF				;AN000;
      ;
	   cmp FOURTH_PARM,1		;AN000; 	   ;; ID was a switch
	   jne ABORT_LOOP		;AN000; 	   ;; otherwise get out of routine
	   call IDLANG_CHK		;AN000; 	   ;; check the ID
	   jmp ADVANCE_PTR		;AN000; 	   ;; advance to the next position

ABORT_LOOP:				;AN000;
	   xor	 cx,cx			;AN000; 	   ;; end loop

ADVANCE_PTR:				;AN000;
	   pop di			;AN000; 	   ;;restore entry value

	   dec cx			;AN000; 	   ;;# of ids left to check
	   cmp cx,0			;AN000; 	   ;; if at 0 don't advance to next
	   je NO_ADVANCE		;AN000; 	   ;; table position
	   cmp GOOD_MATCH,1		;AN000; 	   ;; check to see if ID matched language
	   je NO_ADVANCE		;AN000; 	   ;; if equal do not advance
	   add di,LANG_PTR_SIZE 	;AN000; 	   ;;step to the next entry
						    ;;in the table

NO_ADVANCE:				;AN000;

	   jmp SEARCH_ID		;AN000; 	   ;;for the country

;.ENDWHILE					     ;;end of ID check for country

END_IDCHK:				;AN000;

	   cmp	  FOURTH_PARM,1 	;AN000; 	    ;; see if id was found
	   jne	  VALID6		;AN000;
	   cmp	  GOOD_MATCH,0		;AN000; 	    ;; none found
	   jne	  VALID6		;AN000; 	    ;; report error
	   mov	  [bp].ret_code_4,1	;AN000; 	    ;; incompatible lang code
	   mov	  al,[bp].ret_code_4	;AN000; 	    ;; id combo
	   jmp	  err2id		;AN000;

						    ;; otherwise found it
						    ;; continue to build tbl
;**************************** CNS **********************************************
					       ;;
VALID6: 				       ;;
	MOV   AX,WORD PTR FB.KL_LOGIC_PTR      ;; Save the offset of the state
	MOV   WORD PTR STATE_LOGIC_OFFSET,AX   ;;      logic section
	MOV   AX,WORD PTR FB.KL_LOGIC_PTR+2    ;; Save the offset of the state
	MOV   WORD PTR STATE_LOGIC_OFFSET+2,AX ;;      logic section
					       ;;
	MOV   DL,[BP].RET_CODE_2       ;;;;;;;;;; IF code page was specified
	CMP   DL,2		       ;;
	JNE   CODE_PAGE_SPECIFIED      ;;
	JMP   DONE		       ;;
				       ;;
CODE_PAGE_SPECIFIED:		       ;;  Then
;************************** CNS ***********************************************
	xor   ah,ah		       ;AN000;
	MOV   Al,FB.KL_NUM_CP	       ;AN000;;;
;************************** CNS ***********************************************
	MOV   NUM_CP,AX 	       ;; Save the number of code pages
	MUL   CP_PTR_SIZE	       ;; Determine # of bytes to read
	MOV   DX,OFFSET FILE_BUFFER    ;; Establish beginning of buffer
	MOV   CX,AX		       ;;
	CMP   CX,FILE_BUFFER_SIZE      ;; Make sure buffer is not to small
	JBE   VALID7		       ;;
	JMP   ERROR4		       ;;
				       ;;
VALID7: 			       ;;
	MOV   AH,3FH		       ;; Read code page table from
	INT   21H		       ;;	       Keyb Def file
	JNC   VALID8		       ;; If no error in opening file then
	JMP   ERROR4		       ;;
				       ;;
VALID8: 			       ;;
	MOV   CX,NUM_CP 	       ;;    Number of valid codes
	MOV   DI,OFFSET FILE_BUFFER    ;;    Point to correct word in table
				       ;;
SCAN_CP_TABLE:			       ;; FOR code page parm
	MOV   AX,[BP].CODE_PAGE_PARM   ;;    Get parameter
	CMP   [DI].KC_CODE_PAGE,AX     ;;    Valid Code ??
	JE    CODE_PAGE_FOUND	       ;; If not found AND more entries THEN
	ADD   DI,CP_PTR_SIZE	       ;;    Check next entry
	DEC   CX		       ;;    Decrement count of entries
	JNE   SCAN_CP_TABLE	       ;; Else
	JMP   ERROR2		       ;;    Display error message
				       ;;;;;;;;;
CODE_PAGE_FOUND:			      ;;
	MOV   AX,WORD PTR [DI].KC_ENTRY_PTR   ;;
	MOV   WORD PTR CP_TAB_OFFSET,AX       ;;
	MOV   AX,WORD PTR [DI].KC_ENTRY_PTR+2 ;;
	MOV   WORD PTR CP_TAB_OFFSET+2,AX     ;;
					  ;;;;;;
DONE:					  ;;
	MOV   SI,OFFSET DESIG_CP_BUFFER   ;;
					  ;;
	MOV   AX,CON_INSTALLED	       ;;;;;  If CON is NOT installed THEN
	CMP   AX,0		       ;;
	JE    SYSTEM_CP 	       ;;
	JMP   GET_DESIG_CPS	       ;;
				       ;;
SYSTEM_CP:			       ;;
	MOV   CX,1		       ;;
	MOV   NUM_DESIG_CP,CX	       ;;    Set number of CPs = 1
	MOV   [SI].NUM_DESIGNATES,CX   ;;
				       ;;
	MOV   DL,[BP].RET_CODE_2       ;;    Check if code page parm
	CMP   DL,0		       ;;			was specified
	JNE   SET_TO_SYSTEM_CP	       ;;
	MOV   DX,[BP].CODE_PAGE_PARM   ;;
	MOV   [SI].DESIG_CP_ENTRY,DX   ;;    Load specified code page into
	JMP   READY_TO_BUILD_TABLE     ;;      designated code page list
				       ;;
SET_TO_SYSTEM_CP:		       ;;
	CALL  FIND_FIRST_CP	       ;;   Call routine that sets the first
	CMP   AX,0		       ;;     table found in the Keyb Def file
	JE    SET_TO_SYSTEM_CP2        ;;	to the system code page
	JMP   ERROR4		       ;;
				       ;;
SET_TO_SYSTEM_CP2:		       ;;
	MOV   SYS_CODE_PAGE,BX	       ;;
	MOV   [BP].CODE_PAGE_PARM,BX   ;;
	MOV   [SI].DESIG_CP_ENTRY,BX   ;;    Move sys CP into desig list
	JMP   READY_TO_BUILD_TABLE     ;;
				       ;;
GET_DESIG_CPS:			       ;;  ELSE
	MOV   AX,0AD03H 	       ;;
	PUSH  CS		       ;;    Make sure ES is set
	POP   ES		       ;;
	LEA   DI,DESIG_CP_BUFFER       ;;
	MOV   CX,DESIG_CP_BUF_LEN      ;;
	INT   2FH		       ;;     Get all designated code pages
	JNC   SET_DESIG_VARIABLES      ;;	from console
	JMP   ERROR5		       ;;
				       ;;
SET_DESIG_VARIABLES:		       ;;
	MOV   CX,[SI].NUM_DESIGNATES   ;;
	ADD   CX,[SI].NUM_HW_CPS       ;;
	MOV   NUM_DESIG_CP,CX	       ;;     Set number of Designated CPs
				       ;;
BUFFER_CREATED: 		       ;;
	MOV   AX,0AD02H 	       ;;
	INT   2FH		       ;;     Get invoked code page
				       ;;
SET_TO_CP_INVOKED:		       ;;
	MOV   DL,[BP].RET_CODE_2       ;; IF code page parm was specified
	CMP   DL,0		       ;;
	JNE   SET_TO_INVOKED_CP        ;;
	MOV   CX,NUM_DESIG_CP	       ;;
	MOV   DESIG_LIST,SI	       ;;
	JMP   TEST_IF_DESIGNATED       ;;
				       ;;
SET_TO_INVOKED_CP:		       ;;
	CMP   AX,1		       ;;    IF a code page has been invoked
	JNE   SET_TO_INVOKED_CP3       ;;
	CALL  FIND_FIRST_CP	       ;;    Call the routine that sets the
	CMP   AX,0		       ;;     first code page in the Keyb Def
	JE    SET_TO_INVOKED_CP2       ;;      file to the system code page
	JMP   ERROR4		       ;;
				       ;;
SET_TO_INVOKED_CP2:		       ;;
	MOV   [BP].CODE_PAGE_PARM,BX   ;;
	MOV   SYS_CODE_PAGE,BX	       ;;
				       ;;
	JMP   TEST_IF_DESIGNATED       ;;
				       ;;
SET_TO_INVOKED_CP3:		       ;;
	MOV   [BP].CODE_PAGE_PARM,BX   ;;
				       ;;
TEST_IF_DESIGNATED:		       ;;
	MOV   DX,[BP].CODE_PAGE_PARM   ;;
	CMP   [SI].DESIG_CP_ENTRY,DX   ;;  Is Code page specified in the list
	JE    CODE_PAGE_DESIGNATED     ;;    of designated code pages ?
				       ;;
NEXT_DESIG_CP:			       ;;
	ADD   SI,2		       ;;  Check next code page
	DEC   CX		       ;;  If all designated code pages have
	JNZ   TEST_IF_DESIGNATED       ;;    been checked Then ERROR
	JMP   ERROR6		       ;;
				       ;;
CODE_PAGE_DESIGNATED:		       ;;
	CMP   SYS_CODE_PAGE,0	       ;;
	JNE   READY_TO_BUILD_TABLE     ;;
	CMP   AX,1		       ;;   IF a code page has been invoked
	JE    READY_TO_BUILD_TABLE     ;;
	CMP   [BP].CODE_PAGE_PARM,BX   ;;     IF Invoked CP <>	Specified CP
	JE    READY_TO_BUILD_TABLE     ;;	 Issue warning
;;***************************************************************************
	PUSH  BX		       ;AN000;;; WGR						;AN000
	PUSH  CX		       ;AN000;;; WGR						;AN000
	MOV   AX,WARNING_1	       ;AN000;;; WGR						;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR						;AN000
	XOR   CX,CX		       ;AN000;;; WGR						;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR						;AN000
	XOR   DL,DL		       ;AN000;;; WGR						;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR						;AN000
	POP   CX		       ;AN000;;; WGR						;AN000
	POP   BX		       ;AN000;;; WGR						;AN000
;;***************************************************************************
				       ;;
READY_TO_BUILD_TABLE:		       ;;
				       ;;
	MOV   AX,KEYB_INSTALLED        ;;
	CMP   AX,0		       ;; Else if KEYB has not been installed
	JNE   BUILD_THE_TABLE	       ;;
				       ;;
	CALL  FIND_SYS_TYPE	       ;; Determine system type for INT 9 use
				       ;;
	TEST  SD.SYSTEM_FLAG,PC_JR     ;; IS THIS ROM MULTILINGUAL? (JR.)  AAD
	JZ    CONTINUE_INSTALL		;  NO, LOAD THE NEW INT9 CODE
					; SEE IF MULTILINGUAL OPTION IS PRESENT
	MOV	AH,5			; ADDRESS THE MULTILINGUAL SUPPORT
	MOV	AL,80H			; REQUEST CURRENT LANGUAGE BE IDENTIFIED
	INT	16H			; CALL KEYBOARD TO IDENTIFY ITSELF

;IF THE MULTILINGUAL OPTION IS NOT PRESENT, THE ROM DOES NOT RECOGNIZE THE
;OPTION 5 AND JUST RETURNS THE REGS INTACT.
;RESPONSE IN AL INDICATES THE CURRENT LANGUAGE:

	CMP	AL,80H			; DID I GET BACK JUST WHAT I SENT?
	JE	CONTINUE_INSTALL	; SINCE RESPONSE WAS THE SAME MUST NOT BE
					; MULTILINGUAL, RELOCATE RESIDENT KBD ROUTINE

;I AM GOING TO IGNORE WHAT LANGUAGE IS CURRENTLY SET.  I WILL SET THE
;MULTILINGUAL KEYBOARD TO BECOME MY LANGUAGE.

	MOV	AX,[BP].LANGUAGE_PARM	     ;;
	XCHG	AH,AL			     ;;
	MOV	DI,OFFSET JR_LANGUAGE_CODES  ;;
	MOV	CX,JR_NUM_CODES 	     ;;
	PUSH	CS			     ;;
	POP	ES			     ;;
	REPNE	SCASW			     ;;
	JNE	CONTINUE_INSTALL	     ;;
					     ;;
	MOV	AH,5			; ADDRESS THE MULTILINGUAL KEYBOARD
	MOV	AL,JR_NUM_CODES 	; SELECT MY LANGUAGE
	SUB	AL,CL		       ;;
	INT	16H			; SET THE KEYBOARD ACCORDINGLY
	INT	20H			; JOB DONE, ROM IS MULTILINGUAL
					; NO NEED TO STAY RESIDENT
				       ;;
;------ LOAD IN SPECIAL INT 9 HANDLER AND SPECIAL TABLES (IF NEEDED)

CONTINUE_INSTALL:		       ;;
	CALL  INSTALL_INT_9	       ;; Install INT 9
				       ;;
	CALL  FIND_KEYB_TYPE	       ;; Determine keyboard type table use
				       ;;
BUILD_THE_TABLE:		       ;;
	CALL  TABLE_BUILD	       ;; Build the TEMP_SHARED_DATA_AREA
				       ;;
CHECK_ERRORS:			       ;;
	XOR   CX,CX		       ;; Take appropriate action considering
	MOV   CX,TB_RETURN_CODE        ;;	  return codes from TABLE_BUILD
	CMP   CX,0		       ;;
	JE    CHECK_FOR_INV_CP	       ;; If return code is not 0
				       ;;
	MOV   AX,KEYB_INSTALLED        ;;
	CMP   AX,0		       ;; If KEYB has not been installed
	JNE   CHECK_ERROR_CONTINUE     ;;
	CALL  REMOVE_INT_9	       ;;     remove installed vector
				       ;;
CHECK_ERROR_CONTINUE:		       ;;
	CMP   CX,1		       ;; If return code = 1
	JNE   CHECK_ERROR2	       ;;
	JMP   ERROR1		       ;;     display error message
				       ;;
CHECK_ERROR2:			       ;;
	CMP   CX,2		       ;; If return code = 2
	JNE   CHECK_ERROR3	       ;;
	JMP   ERROR2		       ;;
				       ;;
CHECK_ERROR3:			       ;;
	CMP   CX,3		       ;; If return code = 3
	JNE   CHECK_ERROR4	       ;;
	JMP   ERROR3		       ;;     display error message
				       ;;
CHECK_ERROR4:			       ;;
	CMP   CX,4		       ;; If return code = 4
	JNE   CHECK_ERROR5A	       ;;
	JMP   ERROR4		       ;;     display error message
				       ;;
CHECK_ERROR5A:			       ;;
	CMP   CX,5		       ;; If return code = 5
	JNE   CHECK_ERROR6A	       ;;
	JMP   ERROR5A		       ;;     display error message
				       ;;
CHECK_ERROR6A:			       ;;
	JMP   ERROR6A		       ;; If return code not 0,1,2,3,4 then
				       ;;      display error message
CHECK_FOR_INV_CP:		       ;;
	MOV   CX,CPN_INVALID	       ;; Check if any CPs were not loaded
	CMP   CX,0		       ;;
	JE    TERMINATE 	       ;;   If some were invalid, issue
				       ;;	warning message
;;***************************************************************************
	PUSH  BX		       ;AN000;;; WGR						;AN000
	PUSH  CX		       ;AN000;;; WGR						;AN000
	MOV   AX,NOT_SUPP	       ;AN000;;; WGR						;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR WARNING					;AN000
	XOR   CX,CX		       ;AN000;;; WGR  MESSAGE					;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR						;AN000
	XOR   DL,DL		       ;AN000;;; WGR						;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR						;AN000
	POP   CX		       ;AN000;;; WGR						;AN000
	POP   BX		       ;AN000;;; WGR						;AN000
;;***************************************************************************
				       ;;
TERMINATE:			       ;;
	MOV   AH,3EH		       ;;  Close the KEYBOARD.SYS file
	MOV   BX,KEYBSYS_FILE_HANDLE   ;;  if open
	CMP   BX,0		       ;;
	JE    KEYB_EXIT 	       ;;
	INT   21H		       ;;
				       ;;
	MOV   AX,KEYB_INSTALLED        ;;
	CMP   AX,0		       ;;
	JE    KEYB_EXIT 	       ;;
	JMP   KEYB_EXIT_NOT_RESIDENT   ;;
				       ;;
KEYB_EXIT:			       ;;
	TEST  SD.KEYB_TYPE,G_KB        ;; Q..FERRARI G??
	JZ    NO_FERRARI_G	       ;; N..LEAVE NUMLK ALONE
	TEST  SD.SYSTEM_FLAG,PC_XT     ;;   Q..PC/XT?
	JNZ   NO_FERRARI_G	       ;;   Y..LEAVE NUMLK ALONE
	TEST  SD.KEYB_TYPE,P_KB        ;;      Q..FERRARI P??		***RPS
	JNZ   NO_FERRARI_G	       ;;      Y..LEAVE NUMLK ALONE	***RPS
;***CNS
	CMP   SECURE_FL,1	       ;AN002;; IF SECURITY FLAG SET
	JNE   NO_FERRARI_G	       ;AN002;; DON'T TURN ON NUM_LK

;***CNS
	CALL  NUMLK_ON		       ;;      N..TURN NUMLK ON
				       ;;
NO_FERRARI_G:			       ;;
	TEST  SD.SYSTEM_FLAG,EXT_16    ;; extended INT 16 support?
	JZ    SKIP_CTRL_COPY	       ;;
				       ;; Yes, load extened CTRL case table
	MOV	CX,L_CTRL_TAB	       ;; CX = LENGTH OF EXTENDED TABLE
	MOV	SI,OFFSET CS:RPL_K8    ;; POINT TO EXT. CTRL TABLES
	MOV	DI,OFFSET CS:K8        ;; POINT TO REGULAR CTRL TABLE
	CLD			       ;;
	REP	MOVSB		       ;; OVERLAY WITH EXT. CTRL TABLE
				       ;;
SKIP_CTRL_COPY: 		       ;;
	CALL  INSTALL_INT_9_NET        ;; Let the network know about INT 9
				       ;;     (if the network is installed)
	CALL  INSTALL_INT_2F_48        ;; Install INT 2F and INT 48 (If PCjr)
				       ;;
	MOV   AX,0AD82H 	       ;; Activate language
	MOV   BL,-1		       ;;
	INT   2FH		       ;;
				       ;;
	MOV   DX,ES:TSD.RESIDENT_END   ;; Get resident end
	MOV   CL,4		       ;; Convert into paragrahs
	SHR   DX,CL		       ;;
	INC   DX		       ;;
	MOV   AH,31H		       ;; Function call to terminate but stay
	XOR   AL,AL		       ;;   resident
				       ;;
	MOV   DI,OFFSET SD_DEST_PTR    ;; Initialize destination ptr
	MOV   SI,OFFSET SD_SOURCE_PTR  ;; Initialize source ptr
	XOR   BP,BP		       ;;
	LEA   BX,[BP].ACTIVE_LANGUAGE  ;;
	ADD   DI,BX		       ;; Adjust for portion not copied
	ADD   SI,BX		       ;; Adjust for portion not copied
				       ;;
	MOV   CX,SD_LENGTH	       ;; Set length of SHARED_DATA_AREA
	SUB   CX,BX		       ;; Adjust for portion not copied
				       ;;
	JMP   COPY_SD_AREA	       ;; Jump to proc that copies area in new
				       ;;	part of memory
;***************************** CNS *********************************************
ERR1ID: 			       ;AN000;
;;***************************************************************************
	MOV   AX,INV_I		       ;AN000;;; WGR invalid ID message 			;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR to standard out				;AN000
	XOR   CX,CX		       ;AN000;;; WGR no substitutions				;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR utility message				;AN000
	XOR   DL,DL		       ;AN000;;; WGR no input					;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR display message				;AN000
	MOV   AL,INVALID_PARMS	       ;AN000;;;				   |
	MOV   EXIT_RET_CODE,AL	       ;AN000;;;				   |
;;***************************************************************************
	JMP   KEYB_EXIT_NOT_RESIDENT   ;;
ERR2ID:
;;***************************************************************************
	MOV   AX,INV_COMBO	       ;AN000;;; WGR invalid combination message		;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR to standard out				;AN000
	XOR   CX,CX		       ;AN000;;; WGR no substitutions				;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR utility message				;AN000
	XOR   DL,DL		       ;AN000;;; WGR no input					;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR display message				;AN000
	MOV   AL,INVALID_PARMS	       ;AN000;;;				   |
	MOV   EXIT_RET_CODE,AL	       ;AN000;;;				   |
;;***************************************************************************
	JMP   KEYB_EXIT_NOT_RESIDENT   ;;
;***************************** CNS *********************************************
ERROR1:
;;***************************************************************************
	MOV   AX,INV_L		       ;AN000;;; WGR invalid language code			;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR to standard out				;AN000
	XOR   CX,CX		       ;AN000;;; WGR no substitutions				;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR utility message				;AN000
	XOR   DL,DL		       ;AN000;;; WGR no input					;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR display message				;AN000
	MOV   AL,INVALID_PARMS	       ;AN000;;;				   |
	MOV   EXIT_RET_CODE,AL	       ;AN000;;;				   |
;;***************************************************************************
	JMP   KEYB_EXIT_NOT_RESIDENT   ;;
ERROR2:
;;***************************************************************************
	MOV   AX,INV_CP 	       ;AN000;;; WGR invalid code page message			;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR to standard out				;AN000
	XOR   CX,CX		       ;AN000;;; WGR no substitutions				;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR utility message				;AN000
	XOR   DL,DL		       ;AN000;;; WGR no input					;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR display message				;AN000
	MOV   AL,INVALID_PARMS	       ;AN000;;;				   |
	MOV   EXIT_RET_CODE,AL	       ;AN000;;;				   |
;;***************************************************************************
	JMP   KEYB_EXIT_NOT_RESIDENT   ;;
ERROR3:
;;***************************************************************************
	MOV   AX,INV_S		       ;AN000;;; WGR invalid syntax message			;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR to standard out				;AN000
;***CNS

	LEA   DI,STRING_HOLDER	      ;AN003;Set PTR to look at the STRING
	PUSH  SI		      ;AN003;Save current SI index
	PUSH  AX
	MOV   AX,OLD_PTR	      ;AN003;Last locale of the end of a PARAM
	SUB   CUR_PTR,AX		   ;AN003;Get the length via the PSP
	MOV   SI,CUR_PTR
	MOV   CX,SI		      ;AN003;Save it in CX to move in the chars
	POP   AX		      ;AN003;Restore the PTR to the command line position

	MOV   SI,OLD_PTR	      ;AN003;Last locale of the end of a PARAM
	REP   MOVSB		      ;AN003;Move in the chars until no more

	LEA   DI,STRING_HOLDER	      ;AN003;Set PTR to look at the STRING


	POP   SI		      ;AN003;Restore the PTR to the command line position

	MOV   CX,1		       ;AN003;One replacement
	MOV   PTR_TO_COMLIN,DI	       ;AN003;;; WGR language code asciiz string	    ;AN000


	PUSH  AX		       ;AN003;
	MOV   AX,DS		       ;AN003;;; WGR language code asciiz string	    ;AN000
	MOV   SEG_OF_COMLIN,AX	       ;AN003;
	POP   AX		       ;AN003;
       ;XOR   CX,CX		       ;AN000;;; WGR no substitutions				;AN000

	MOV   AX,ERR_PART	       ;AN003;
	LEA   SI,SUBLIST_COMLIN        ;AN003;
;	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR parse error message			;AN000
	MOV   DH,PARSE_ERR_CLASS      ;AN000;;; WGR parse error message 		       ;AN000
	XOR   DL,DL		       ;AN000;;; WGR no input					;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR display message				;AN000
	MOV   AL,INVALID_PARMS	       ;AN000;;;				   |
	MOV   EXIT_RET_CODE,AL	       ;AN000;;;				   |
;;***************************************************************************
	JMP   KEYB_EXIT_NOT_RESIDENT   ;;
ERROR4:
;;***************************************************************************
	MOV   AX,INV_FN 	       ;AN000;;; WGR bad or missing file message		;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR to standard out				;AN000
	XOR   CX,CX		       ;AN000;;; WGR no substitutions				;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR utility message				;AN000
	XOR   DL,DL		       ;AN000;;; WGR no input					;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR display message				;AN000
	MOV   AL,BAD_KEYB_DEF_FILE     ;AN000;;;				   |
	MOV   EXIT_RET_CODE,AL	       ;AN000;;;				   |
;;***************************************************************************
	JMP   KEYB_EXIT_NOT_RESIDENT   ;;
ERROR5:
;;***************************************************************************
	MOV   AX,INV_CON_Q	       ;AC000;;; WGR CON code page not available.		;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR to standard out				;AN000
	XOR   CX,CX		       ;AN000;;; WGR no substitutions				;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR utility message				;AN000
	XOR   DL,DL		       ;AN000;;; WGR no input					;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR display message				;AN000
	MOV   AL,CONSOLE_ERROR	       ;AN000;;;				   |
	MOV   EXIT_RET_CODE,AL	       ;AN000;;;				   |
;;***************************************************************************
	JMP   KEYB_EXIT_NOT_RESIDENT   ;;
ERROR5A:
;;***************************************************************************
	MOV   AX,MEMORY_OVERF	       ;AC000;;; WGR not enough resident memory.		;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR to standard out				;AN000
	XOR   CX,CX		       ;AN000;;; WGR no substitutions				;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR utility message				;AN000
	XOR   DL,DL		       ;AN000;;; WGR no input					;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR display message				;AN000
	MOV   AL,MEMORY_OVERFLOW       ;AN000;;;				   |
	MOV   EXIT_RET_CODE,AL	       ;AN000;;;				   |
;;***************************************************************************
	JMP   KEYB_EXIT_NOT_RESIDENT   ;;
ERROR6:
;;***************************************************************************
	MOV   AX,NOT_DESIG	       ;AC000;;; WGR code page not prepared.			;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR to standard out				;AN000
	XOR   CX,CX		       ;AN000;;; WGR no substitutions				;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR utility message				;AN000
	XOR   DL,DL		       ;AN000;;; WGR no input					;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR display message				;AN000
	MOV   AL,CP_NOT_DESIGNATED     ;AN000;;;				   |
	MOV   EXIT_RET_CODE,AL	       ;AN000;;;				   |
;;***************************************************************************
	JMP   KEYB_EXIT_NOT_RESIDENT   ;;
ERROR6A:
;;***************************************************************************
	MOV   NUMBER_HOLDER,BX	       ;AN000;;; WGR transfer number to temp loc.		;AN000
	LEA   SI,NUMBER_HOLDER	       ;AN000;;; WGR sublist points to...			;AN000
	MOV   PTR_TO_NUMBER,SI	       ;AN000;;; WGR code page word				;AN000
	MOV   AX,NOT_VALID	       ;AN000;;; WGR display 'Code page requested....'          ;AN000
	MOV   BX,STDOUT 	       ;AN000;;; WGR to standard out				;AN000
	MOV   CX,1		       ;AN000;;; WGR one replacement				;AN000
	MOV   DH,UTILITY_MSG_CLASS     ;AN000;;; WGR utility message				;AN000
	XOR   DL,DL		       ;AN000;;; WGR no input					;AN000
	LEA   SI,SUBLIST_NUMBER        ;AN000;;; WGR ptr to sublist				;AN000
	CALL  SYSDISPMSG	       ;AN000;;; WGR						;AN000
	MOV   AL,KEYB_TABLE_NOT_LOAD   ;AN000;;;				   |
	MOV   EXIT_RET_CODE,AL	       ;AN000;;;				   |
;;***************************************************************************
				       ;;
KEYB_EXIT_NOT_RESIDENT: 	       ;;
	MOV   AH,04CH		       ;;
	MOV   AL,QUERY_CALL	       ;; Check if this was a query call
	CMP   AL,0		       ;;
	JNE   KEYB_EXIT3	       ;;  IF yes then EXIT
	MOV   AL,EXIT_RET_CODE	       ;; Check if return code was valid
	CMP   AL,0		       ;;
	JNE   KEYB_EXIT3	       ;;  IF not then EXIT
				       ;;
COPY_INTO_SDA:			       ;;
	MOV   AX,0AD82H 	       ;; Activate language
	MOV   BL,-1		       ;;
	INT   2FH		       ;;
				       ;;
	MOV   AH,04CH		       ;;;;;;;;;;;
	MOV   AL,EXIT_RET_CODE			;;
	MOV   DI,WORD PTR SHARED_AREA_PTR+2	;; Initialize destination ptr
	MOV   ES,WORD PTR SHARED_AREA_PTR	;;
	MOV   DX,[BP].RESIDENT_END     ;;;;;;;;;;;
	MOV   CL,4		       ;; Calculate resident end in paragraphs
	SHR   DX,CL		       ;;
	INC   DX		       ;;
				       ;;
	MOV   SI,OFFSET SD_SOURCE_PTR  ;; Initialize source ptr
	XOR   BP,BP		       ;;
	LEA   BX,[BP].ACTIVE_LANGUAGE  ;;
	ADD   DI,BX		       ;;
	ADD   SI,BX		       ;;
	MOV   CX,SD_LENGTH	       ;; Set length of SHARED_DATA_AREA
	SUB   CX,BX		       ;;
				       ;;
	JMP   COPY_SD_AREA	       ;; Jump to proc that copies area in new
				       ;;
KEYB_EXIT3:			       ;;;;;;;;;;;
	MOV   AL,EXIT_RET_CODE			;;
	MOV   DI,WORD PTR SHARED_AREA_PTR+2	;; Initialize destination ptr
	MOV   ES,WORD PTR SHARED_AREA_PTR	;;
	MOV   ES:[DI].TABLE_OK,1		;;
	INT   21H		       ;;;;;;;;;;;
				       ;;
KEYB_COMMAND  ENDP		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Procedure: NUMLK_ON
;;
;; Description:
;;     Turn  Num Lock On.
;;
;; Input Registers:
;;     N/A
;;
;; Output Registers:
;;     N/A
;;
;; Logic:
;;     Set Num Lock bit in BIOS KB_FLAG
;;     Issue Int 16 to update lights
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
NUMLK_ON     PROC		       ;;
				       ;;
	PUSH	ES		       ;;
	PUSH	AX		       ;;
				       ;;
	MOV	AX,DATA 	       ;;
	MOV	ES,AX		       ;;
				       ;;
	OR	ES:KB_FLAG,NUM_STATE   ;; Num Lock state active
	MOV	AH,1		       ;; Issue keyboard query call to
	INT	16H		       ;;  have BIOS update the lights
				       ;;
	POP	AX		       ;;
	POP	ES		       ;;
	RET			       ;;
				       ;;
NUMLK_ON   ENDP 		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: INSTALL_INT_9
;;
;; Description:
;;     Install our INT 9 driver.
;;
;; Input Registers:
;;     DS - points to our data segment
;;     BP - points to ES to find SHARED_DATA_AREA
;;
;; Output Registers:
;;     DS - points to our data segment
;;     AX, BX, DX, ES  Trashed
;;
;; Logic:
;;	Get existing vector
;;	Install our vector
;;	Return
;;
;; Notes:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
REPLACE_INT_SEGMENT1 DW  ?	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					    ;;
INSTALL_INT_9	     PROC		    ;;
					    ;;
	PUSH  ES			    ;;
					    ;;
	MOV   AH,35H			    ;; Get int 9 vector
	MOV   AL,9			    ;;
	INT   21H			    ;; Vector in ES:BX
	MOV   REPLACE_INT_SEGMENT1,ES	    ;;
	PUSH  CS			    ;;
	POP   ES			    ;;
	MOV   WORD PTR ES:SD.OLD_INT_9,BX   ;; Offset
	MOV   AX,REPLACE_INT_SEGMENT1	    ;;
	MOV   WORD PTR ES:SD.OLD_INT_9+2,AX ;; Segment
	MOV   AH,25H			    ;;
	MOV   AL,9			    ;;
	MOV   DX,OFFSET KEYB_INT_9	    ;; Let DOS know about our handler
	INT   21H			    ;;
					    ;;
	POP   ES			    ;;
	RET				    ;;
					    ;;
INSTALL_INT_9	     ENDP		    ;;
					    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: INSTALL_INT_9_NET
;;
;; Description:
;;
;;
;; Input Registers:
;;     DS - points to our data segment
;;     BP - points to ES to find SHARED_DATA_AREA
;;
;; Output Registers:
;;     DS - points to our data segment
;;     AX, BX, DX, ES  Trashed
;;
;; Logic:
;;	IF network is installed THEN
;;	  Let it know about our INT 9
;;	Return
;;
;; Notes:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
INSTALL_INT_9_NET    PROC	       ;;
				       ;;
	PUSH  ES		       ;;
				       ;;
	TEST  SD.SYSTEM_FLAG,PC_NET    ;; TEST FOR PC_NETWORK
	JNZ   NET_HAND_SHAKE	       ;; JUMP IF NETWORK INSTALLED
	JMP   INSTALL_9_DONE_NET       ;; SKIP THE PC NETWORK HANDSHAKE
				       ;;
NET_HAND_SHAKE: 		       ;;
				       ;; ES:BX TO CONTAIN INT 9 ADDR
	MOV   BX,OFFSET KEYB_INT_9     ;;
	MOV   AX,0B808H 	       ;; FUNCTION FOR PC NETWORK TO INSTALL
				       ;; THIS ADDRESS FOR THEIR JUMP TABLE
	INT   02FH		       ;; TELL PC_NET TO USE MY ADDR TO CHAIN TO
				       ;;
INSTALL_9_DONE_NET:		       ;;
	POP   ES		       ;;
	RET			       ;;
				       ;;
INSTALL_INT_9_NET    ENDP	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: INSTALL_INT_2F_48
;;
;; Description:
;;     Install our INT 2F, INT 48 drivers.
;;
;; Input Registers:
;;     DS - points to our data segment
;;     BP - points to ES to find SHARED_DATA_AREA
;;
;; Output Registers:
;;     DS - points to our data segment
;;     AX, BX, DX, ES  Trashed
;;
;; Logic:
;;	Get existing vectors
;;	Install our vectors
;;	Return
;;
;; Notes:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
REPLACE_INT_SEGMENT2 DW  ?	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					     ;;
INSTALL_INT_2F_48    PROC		     ;;
					     ;;
	MOV   AH,35H			     ;; Get int 2f vector
	MOV   AL,2FH			     ;;
	INT   21H			     ;; Vector in ES:BX
	MOV   REPLACE_INT_SEGMENT2,ES	     ;;
	PUSH  CS			     ;;
	POP   ES			     ;;
	MOV   WORD PTR ES:SD.OLD_INT_2F,BX   ;; Offset
	MOV   AX,REPLACE_INT_SEGMENT2	     ;;
	MOV   WORD PTR ES:SD.OLD_INT_2F+2,AX ;; Segment
	MOV   AH,25H			     ;; Set int 9 vector
	MOV   AL,2FH			     ;;
	MOV   DX,OFFSET KEYB_INT_2F	     ;; Vector in DS:DX
	INT   21H			     ;;
					     ;;
ARE_WE_A_PCJR:				     ;;
					     ;;
	MOV   AX,SD.SYSTEM_FLAG 	     ;; Test if we are a PCjr
	CMP   AX,PC_JR			     ;;
	JNE   INSTALL_DONE		     ;;  IF yes then
	MOV   AH,35H			     ;;    Get int 48 vector
	MOV   AL,48H			     ;;
	INT   21H			     ;;    Vector in ES:BX
	MOV   REPLACE_INT_SEGMENT2,ES	     ;;
	PUSH  CS			     ;;
	POP   ES			     ;;
	MOV   WORD PTR ES:SD.OLD_INT_48,BX   ;;    Offset
	MOV   AX,REPLACE_INT_SEGMENT2	     ;;
	MOV   WORD PTR ES:SD.OLD_INT_48+2,AX ;;    Segment
	MOV   AH,25H			     ;;    Set int 48 vector
	MOV   AL,48H			     ;;
	MOV   DX,OFFSET KEYB_INT_48	     ;;    Vector in DS:DX
	INT   21H			     ;;
					     ;;
INSTALL_DONE:				     ;;


	RET				     ;;
					     ;;
INSTALL_INT_2F_48    ENDP		     ;;
					     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: REMOVE_INT_9
;;
;; Description:
;;     Remove our INT 9 driver.
;;
;; Input Registers:
;;     DS - points to our data segment
;;     BP - points to ES to find SHARED_DATA_AREA
;;
;; Output Registers:
;;     DS - points to our data segment
;;     AX, BX, DX, ES  Trashed
;;
;; Logic:
;;	Get old vector
;;	Install old vector
;;	Return
;;
;; Notes:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					      ;;
REMOVE_INT_9	    PROC		      ;;
					      ;;
	PUSH  DS			      ;;
	PUSH  ES			      ;;
	MOV   ES,WORD PTR SHARED_AREA_PTR     ;;
	MOV   AX,WORD PTR ES:SD.OLD_INT_9+2   ;; int 9 vector - segment
	MOV   DS,AX			      ;;
	MOV   DX,WORD PTR ES:SD.OLD_INT_9     ;; int 9 vector - offset
					      ;;
	MOV   AH,25H		       ;;;;;;;;; Set int 9 vector
	MOV   AL,9		       ;;
	INT   21H		       ;;
				       ;;
REMOVE_9_DONE:			       ;;
	POP   ES		       ;;
	POP   DS		       ;;
	RET			       ;;
				       ;;
REMOVE_INT_9		 ENDP	       ;;
				       ;;
;*********************** CNS **********;;
PURPOSE:			       ;;
INPUT:				       ;;
OUTPUT: 			       ;;
;**************************************;;
				       ;AN000;;;
				       ;AN000;;;
				       ;AN000;;;
    IDLANG_CHK	PROC	NEAR	       ;AN000;;;
				       ;AN000;;;
	mov	ax,fb.kl_id_code       ;AN000;;;get the id code from the table
	cmp	ax,[bp].id_parm        ;AN000;;;;;;;;;;;compare it to value taken
	jne	end_match	       ;AN000;	       ;from the switch-- if found
	cmp	ALPHA,0 	       ;AN000;	       ;a keyboard code was specified
	je	a_match 	       ;AN000;	       ;no lang & a match
				       ;AN000;	       ;
	mov	ax,fb.kl_lang_code     ;AN000;	       ;compare lang codes
	cmp	ax,[BP].LANGUAGE_PARM  ;AN000;	       ;they are equal
	je	a_match 	       ;AN000;	       ;
				       ;AN000;	       ;
	jmp	end_match	       ;AN000;	       ;if not found go check next
				       ;AN000;	       ;id for the same country
				       ;AN000;	       ;
    a_match:			       ;AN000;	       ;
						;
	mov	good_match,1	       ;AN000;	       ;report the ids match
						;
    end_match:			       ;AN000;	       ;
						;
	ret			       ;AN000;	       ;
						;
    IDLANG_CHK	ENDP		       ;AN000;	       ;
;*********************** CNS *******************;
;**********************************SCAN_ID***********************;
; New variables defined - NUM_ID,ADRSS_LANG,ID_PTR_SIZE,ID_FOUND ;
;****************************************************************;
								 ;
								 ;
	SCAN_ID     PROC	NEAR				 ;
								 ;
	xor	di,di		;AN000;;clear di to set at the
				;AN000;;beginning of KEYBSYS STRUCTURE
				;;;;;;;;;;
					 ;
	lea	cx,[di].kh_num_ID+4	 ;AN000;; set number of bytes to read header
					 ;
	mov	ah,3fh			 ;AN000;;
	int	21h			 ;AN000;;
	jnc	VAL5ID			 ;AN000;;
	jmp	BAD_TAB 		 ;AN000;;;bad table message
					  ;
 VAL5ID:				 ;AN000; ;
					  ;
	mov	cx,SIGNATURE_LENGTH	 ;AN000; ;
	mov	di,offset SIGNATURE	 ;AN000; ;
	mov	si,offset FB.KH_SIGNATURE;AN000; ;
	repe	CMPSB			 ;AN000; ;
	je	ID_SPECIFIED		 ;AN000; ;
	jmp	BAD_TAB 		 ;AN000; ;
					  ;
					  ;
					  ;
 ID_SPECIFIED:				 ;AN000; ;
					  ;
	mov	ax,FB.KH_NUM_ID 	 ;AN000; ;;;;;;;;;;;;;;;
	mov	NUM_ID,ax		 ;AN000; ;save # of IDs
	mul	ID_PTR_SIZE		 ;AN000; ;determine # of bytes to read
	push	ax			 ;AN000; ;save current # of bytes to read for
					 ;AN000; ;ID values only
	mov	ax,FB.KH_NUM_LANG	 ;AN000; ;add on lang data in table
	mul	LANG_PTR_SIZE		 ;AN000; ;data that comes before the ID data
	mov	cx,ax			 ;AN000; ;save that value for the size compare
	mov	PASS_LANG,cx		 ;AN000; ;
	pop	ax			 ;AN000; ;restore the info for # of ID bytes to read
	add	cx,ax			 ;AN000; ;add that value to get total in CX
	mov	TOTAL_SIZE,cx		 ;AN000; ;save the total size
	cmp	cx,FILE_BUFFER_SIZE	 ;AN000; ;
	jbe	READ_ID_TAB		 ;AN000; ;
	jmp	BAD_TAB 		 ;AN000; ;
					  ;
					  ;
  READ_ID_TAB:				 ;AN000; ;
					  ;
	mov	dx,offset FILE_BUFFER	 ;AN000; ;
	mov	ah,3fh			;;AN000;read language table from
	int	21h			;;AN000;keyb defn file
	jnc	READ_IDVAL		;;AN000;
	jmp	BAD_TAB 		;;AN000;
					;
  READ_IDVAL:				;;AN000;
					;;AN000;
	mov	cx,NUM_ID		;;AN000;
	mov	di,offset FILE_BUFFER	;;AN000;;;;;;;;;;
	add	di,PASS_LANG		 ;AN000;	;
						 ;
  SCAN_ID_TAB:				 ;AN000;	;
						 ;
	mov	ax,[bp].ID_PARM 	 ;AN000;	;
	cmp	[di].KP_ID_CODE,ax	 ;AN000;	;
	je	ID_HERE 		 ;AN000;	;
	add	di,ID_PTR_SIZE		 ;AN000;	;
	dec	cx			 ;AN000;	;
	jne	SCAN_ID_TAB		 ;AN000;	;
	jmp	FINALE			 ;AN000;	;
					 ;
  BAD_TAB:				 ;AN000;;
						 ;
	mov	ERR4ID,1		 ;AN000;	;
	jmp	FINALE			 ;AN000;	;
						 ;
						 ;
						 ;
   ID_HERE:				 ;AN000;	;
						 ;
	mov	ID_FOUND,1	;AN000;;reset ptr for	;
				;AN000;;current country ;
						 ;

						 ;
   FINALE:			;AN000; 		;
						 ;
	ret			;AN000; 		;
						 ;
						 ;
	SCAN_ID 	ENDP	;AN000; 		;
						 ;
;*******************************SCAN_ID END******;
;;
;; Module: BUILD_PATH
;;
;; Description:
;;     Build the complete filename of the Keyboard Definition File
;;*************************************WGR*********************
;;     and open the file.
;;+++++++++++++++++++++++++++++++++++++WGR+++++++++++++++++++++
;;
;; Input Registers:
;;     DS - points to our data segment
;;     ES - points to our data segment
;;     BP - offset of parmeter list
;;
;; Output Registers:
;;************************************WGR**********************
;;     CARRY CLEAR
;;	    AX = HANDLE
;;     CARRY SET (ERROR)
;;	    NONE
;;++++++++++++++++++++++++++++++++++++WGR++++++++++++++++++++++
;;    The complete filename will be available in FILE_NAME
;;
;; Logic:
;;
;;    Determine whether path parameter was specified
;;    IF length is zero THEN
;;****************************************WGR******************
;;	Try to open file in ACTIVE directory
;;	IF failed THEN
;;	  Try to open file in ARGV(0) directory
;;	  IF failed THEN
;;	    Try to open file in ROOT directory (for DOS 3.3 compatibility)
;;	    ENDIF
;;	  ENDIF
;;	ENDIF
;;    ELSE
;;	Copy path from PSP to FILE_NAME memory area
;;	Try to open USER SPECIFIED file
;;++++++++++++++++++++++++++++++++++++++++WGR++++++++++++++++++
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
KEYBOARD_SYS	DB   '\KEYBOARD.SYS',00  ;AN000;;;
KEYB_SYS_ACTIVE DB   'KEYBOARD.SYS',00   ;AN000;;; WGR                                     ;AN000
KEYB_SYS_LENG	EQU  14 		 ;AN000;;;
KEYB_SYS_A_LENG EQU  13 		 ;AN000;;; WGR					   ;AN000
					 ;;
FILE_NAME	DB   128 DUP(0) 	 ;AN000;;;
					 ;;
FILE_NOT_FOUND	EQU  2			 ;AN000;;; WGR					   ;AN000
PATH_NOT_FOUND	EQU  3			 ;AN000;;; WGR					   ;AN000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
BUILD_PATH    PROC  NEAR	       ;;
	CLD			       ;AN000;;; WGR					   ;AN000
	MOV	DI,OFFSET FILE_NAME    ;; Get the offset of the filename
	MOV	CX,[BP].PATH_LENGTH    ;; If path is specified then
	CMP	CX,0		       ;;
	JE	APPEND_KEYB_SYS        ;;
	MOV	SI,[BP].PATH_OFFSET    ;;   Get the offset of the path
				       ;;
	REPE	MOVSB		       ;AC000;;;   Copy each char of the specified
	MOV	AX,3D00H	       ;AC000;;; WGR Open the KEYBOARD.SYS file 	   ;AN000
	MOV	DX,OFFSET FILE_NAME    ;AC000;;; WGR					   ;AN000
	INT	21H		       ;AC000;;; WGR					   ;AN000
	RET			       ;;   path into the filename location
				       ;;
APPEND_KEYB_SYS:		       ;;;;;
	MOV	SI,OFFSET KEYB_SYS_ACTIVE ;AC000;;; WGR  copy name for active directory    ;AN000
	MOV	CX,KEYB_SYS_A_LENG     ;AC000;;;;;; WGR  to file name variable. 	   ;AN000
	REPE	MOVSB		       ;AC000;;; WGR					   ;AN000
	MOV	AX,3D00H	       ;AC000;;; WGR try to open it.			   ;AN000
	MOV	DX,OFFSET FILE_NAME    ;AC000;;; WGR					   ;AN000
	INT	21H		       ;AC000;;; WGR					   ;AN000
	.IF C			       ;AC000;;; WGR error in opening...was it..	   ;AN000
	  .IF <AX EQ PATH_NOT_FOUND> OR ;AN000;;; WGR path or.. 			   ;AN000
	  .IF <AX EQ FILE_NOT_FOUND>   ;AN000;;; WGR file not found?... 		   ;AN000
	    CALL   COPY_ARGV0	       ;AC000;;; WGR yes....try ARGV(0) directory.	   ;AN000
	    MOV    AX,3D00H	       ;AC000;;; WGR					   ;AN000
	    MOV    DX,OFFSET FILE_NAME ;AC000;;; WGR					   ;AN000
	    INT    21H		       ;AC000;;; WGR					   ;AN000
	    .IF C		       ;AC000;;; WGR error in opening....was it..	   ;AN000
	      .IF <AX EQ PATH_NOT_FOUND> OR ;AC000;;; WGR path or..			   ;AN000
	      .IF <AX EQ FILE_NOT_FOUND> ;AC000;;; WGR file not found?			   ;AN000
		MOV	SI,OFFSET KEYBOARD_SYS ;AC000;;; WGR try ROOT directory.	   ;AN000
		MOV	DI,OFFSET FILE_NAME    ;AC000;;; WGR				   ;AN000
		MOV	CX,KEYB_SYS_LENG       ;AC000;;; WGR				   ;AN000
		REPE	MOVSB		       ;AC000;;; WGR				   ;AN000
		MOV	AX,3D00H	       ;AC000;;; WGR				   ;AN000
		MOV	DX,OFFSET FILE_NAME    ;AC000;;; WGR				   ;AN000
		INT	21H		       ;AC000;;; WGR				   ;AN000
	      .ELSE			       ;AC000;;; WGR if failed then carry set..    ;AN000
		STC			      ;AC000;;; WGR some other error..set flag	   ;AN000
	      .ENDIF			     ;AC000;;; WGR				   ;AN000
	    .ENDIF			    ;AC000;;; WGR				   ;AN000
	  .ELSE 			   ;AN000;;; WGR				   ;AN000
	    STC 			  ;AN000;;; WGR some other error..set flag.	   ;AN000
	  .ENDIF			 ;AN000;;; WGR					   ;AN000
	.ENDIF				;AN000;;; WGR					   ;AN000
				       ;;
	RET			       ;AN000;;;
				       ;;
BUILD_PATH	     ENDP	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; WGR
;;					  WGR
;; Module Name: 			  WGR
;;   COPY_ARGV0 			  WGR
;;					  WGR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; WGR
				       ;; WGR
				       ;; WGR
COPY_ARGV0  PROC		       ;; WGR					    ;AN000
				       ;; WGR					    ;AN000
  PUSH	 ES			       ;AN000;;; WGR					   ;AN000
  PUSH	 DI			       ;AN000;;; WGR					   ;AN000
  PUSH	 SI			       ;AN000;;; WGR					   ;AN000
  PUSH	 CX			       ;AN000;;; WGR					   ;AN000
				       ;AN000;;; WGR					   ;AN000
  MOV	 DI,2CH 		       ;AN000;;; WGR Locate environment string		   ;AN000
  MOV	 ES,[DI]		       ;AN000;;; WGR					   ;AN000
  XOR	 SI,SI			       ;AN000;;; WGR					   ;AN000
  .WHILE <<WORD PTR ES:[SI]> NE 0>     ;AN000;;; WGR find ARGV(0) string.		   ;AN000
     INC   SI			       ;AN000;;; WGR					   ;AN000
  .ENDWHILE			       ;AN000;;; WGR					   ;AN000
  ADD	 SI,4			       ;AN000;;; WGR					   ;AN000
  LEA	 DI,FILE_NAME		       ;AN000;;; WGR move string to work area		   ;AN000
  .REPEAT			       ;AN000;;; WGR					   ;AN000
     MOV    AL,ES:[SI]		       ;AN000;;; WGR					   ;AN000
     MOV    [DI],AL		       ;AN000;;; WGR					   ;AN000
     INC    SI			       ;AN000;;; WGR					   ;AN000
     INC    DI			       ;AN000;;; WGR					   ;AN000
  .UNTIL <<BYTE PTR ES:[SI]> EQ 0>     ;AN000;;; WGR					   ;AN000
  .REPEAT			       ;AN000;;; WGR					   ;AN000
     DEC    DI			       ;AN000;;; WGR					   ;AN000
  .UNTIL <<BYTE PTR [DI]> EQ '\'> OR   ;AN000;;; WGR                                       ;AN000
  .UNTIL <<BYTE PTR [DI]> EQ 0>        ;AN000;;; WGR scan back to..			   ;AN000
  INC	 DI			       ;AN000;;; WGR first character after "\"             ;AN000
  PUSH	 CS			       ;AN000;;; WGR					   ;AN000
  POP	 ES			       ;AN000;;; WGR					   ;AN000
  LEA	 SI,KEYB_SYS_ACTIVE	       ;AN000;;; WGR copy in "KEYBOARD.SYS"                ;AN000
  MOV	 CX,KEYB_SYS_A_LENG	       ;AN000;;; WGR					   ;AN000
  REPE	 MOVSB			       ;AN000;;; WGR					   ;AN000
				       ;AN000;;; WGR					   ;AN000
  POP	    CX			       ;AN000;;; WGR					   ;AN000
  POP	    SI			       ;AN000;;; WGR					   ;AN000
  POP	    DI			       ;AN000;;; WGR					   ;AN000
  POP	    ES			       ;AN000;;; WGR					   ;AN000
  RET				       ;AN000;;; WGR					   ;AN000
				       ;AN000;;; WGR					   ;AN000
COPY_ARGV0  ENDP		       ;AN000;;;
				       ;AN000;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: FIND_FIRST_CP
;;
;; Description:
;;     Check the keyboard definition file for the first code page
;;
;; Input Registers:
;;     DS - points to our data segment
;;     ES - points to our data segment
;;     BP - offset of parmeter list
;;
;; Output Registers:
;;	    NONE
;;
;; Logic:
;;   Open the file
;;   IF error in opening file THEN
;;	Display ERROR message and EXIT
;;   ELSE
;;	Save handle
;;	Set address of buffer
;;	READ header of Keyboard definition file
;;	IF error in reading file THEN
;;	   Display ERROR message and EXIT
;;	ELSE
;;	   Check signature for correct file
;;	   IF file signature is correct THEN
;;	      READ language table
;;	      IF error in reading file THEN
;;		  Display ERROR message and EXIT
;;	      ELSE
;;		  Use table to verify language parm
;;		  Set pointer values
;;		  IF code page was specified
;;		      READ language entry
;;		      IF error in reading file THEN
;;			   Display ERROR message and EXIT
;;		      ELSE
;;			   READ first code page
;;			   IF error in reading file THEN
;;			       Display ERROR message and EXIT
;;   RET
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						   ;;
FIND_FIRST_CP PROC  NEAR			   ;;
						   ;;
	PUSH  CX				   ;; Save everything that
	PUSH  DX				   ;;  that will be changed
	PUSH  SI				   ;;
	PUSH  DI				   ;;
						   ;;
	MOV   BX,KEYBSYS_FILE_HANDLE		   ;; Get handle
	MOV   DX,WORD PTR KEYBCMD_LANG_ENTRY_PTR   ;; LSEEK file pointer
	MOV   CX,WORD PTR KEYBCMD_LANG_ENTRY_PTR+2 ;;  to top of language entry
	MOV   AH,42H				   ;;
	MOV   AL,0		       ;;;;;;;;;;;;;; If no problem with
	INT   21H		       ;;		     Keyb Def file Then
	JNC   FIND_FIRST_BEGIN	       ;;
	JMP   FIND_FIRST_CP_ERROR4     ;;
				       ;;;;;;;;;
FIND_FIRST_BEGIN:			      ;;
	MOV   DI,AX			      ;;
	MOV   CX,SIZE KEYBSYS_LANG_ENTRY-1    ;; Set number
					      ;;	bytes to read header
	MOV   DX,OFFSET FILE_BUFFER    ;;;;;;;;;
	MOV   AH,3FH		       ;; Read language entry in
	INT   21H		       ;;	 keyboard definition file
	JNC   FIND_FIRST_VALID4        ;; If no error in opening file then
	JMP   FIND_FIRST_CP_ERROR4     ;;
				       ;;
FIND_FIRST_VALID4:		       ;;
;************************** CNS *******;;
	xor   ah,ah		       ;AC000;;;
	MOV   Al,FB.KL_NUM_CP	       ;AC000;;;
;************************** CNS *******;;
	MUL   CP_PTR_SIZE	       ;; Determine # of bytes to read
	MOV   DX,OFFSET FILE_BUFFER    ;; Establish beginning of buffer
	MOV   CX,AX		       ;;
	CMP   CX,FILE_BUFFER_SIZE      ;; Make sure buffer is not to small
	JBE   FIND_FIRST_VALID5        ;;
	JMP   FIND_FIRST_CP_ERROR4     ;;
				       ;;
FIND_FIRST_VALID5:		       ;;
	MOV   AH,3FH		       ;; Read code page table from
	INT   21H		       ;;	     keyboard definition file
	JNC   FIND_FIRST_VALID6        ;; If no error in opening file then
	JMP   FIND_FIRST_CP_ERROR4     ;;
				       ;;
FIND_FIRST_VALID6:		       ;;
	MOV   CX,NUM_CP 	       ;;    Number of valid codes
	MOV   DI,OFFSET FILE_BUFFER    ;;    Point to correct word in table
				       ;;
	MOV   BX,[DI].KC_CODE_PAGE     ;;    Get parameter
	XOR   AX,AX		       ;;
	JMP   FIND_FIRST_RETURN        ;;
				       ;;
FIND_FIRST_CP_ERROR4:		       ;;
	MOV  AX,4		       ;;
				       ;;
FIND_FIRST_RETURN:		       ;;
	POP  DI 		       ;;
	POP  SI 		       ;;
	POP  DX 		       ;;
	POP  CX 		       ;;
				       ;;
	RET			       ;;
				       ;;
FIND_FIRST_CP	     ENDP	       ;;
				       ;;;;;;;;;;;;;
.xlist						  ;;
MSG_SERVICES <MSGDATA>				  ;AN000;;; WGR 			   ;AN000
MSG_SERVICES <LOADmsg,DISPLAYmsg,CHARmsg,NUMmsg>  ;AN000;;; WGR 			   ;AN000
MSG_SERVICES <KEYB.CL1> 			  ;AN000;;; WGR 			   ;AN000
MSG_SERVICES <KEYB.CL2> 			  ;AN000;;; WGR 			   ;AN000
MSG_SERVICES <KEYB.CLA> 			  ;AN000;;; WGR 			   ;AN000
.list						  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Temp Shared Data Area
;; Contains data which is required by
;; both the resident and transient KEYB code.
;; All keyboard tables are stored in this area
;; Structures for this area are in file KEYBSHAR.INC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
 db 'TEMP SHARED DATA'                 ;;
SD_SOURCE_PTR	  LABEL     BYTE       ;;
TEMP_SHARED_DATA   SHARED_DATA_STR <>  ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE	ENDS

include msgdcl.inc

	END
