

PAGE	55,132							;AN000;
NAME	SELECT							;AN000;
TITLE	SELECT - DOS - SELECT.EXE				;AN000;
SUBTTL	SELECT2A.asm						;AN000;
.ALPHA								;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SELECT2A.ASM : Copyright 1988 Microsoft
;
;	DATE:	 August 8/87
;
;	COMMENTS: Assemble with MASM 3.0 (using the -A option)
;
;		  Panel flow is defined in the following files:
;
;		      � SELECT1.ASM
;		      � SELECT2.ASM
;		      � SELECT3.ASM
;		      � SELECT4.ASM
;		      � SELECT5.ASM
;		      � SELECT6.ASM
;
;	CHANGE HISTORY:
;
;	mrw0	6/16/88 Added panel for shell selection...
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	SEGMENT BYTE PUBLIC 'DATA'                              ;AN000; Dummy data segment
	EXTRN	 SEG_LOC:WORD					;AN000;
	EXTRN	 NAMES_OFF:WORD 				;AN000;
	EXTRN	 N_PRN_NAMES:WORD				;AN000;
	EXTRN	 MAX_NAME:WORD					;AN000;
	EXTRN	 SIZE_NAMES:ABS 				;AN000;
DATA	       ENDS						;AN000;
								;
.XLIST								;AN000;
	INCLUDE    PANEL.MAC					;AN000;
	INCLUDE    SELECT.INC					;AN000;
	INCLUDE    PAN-LIST.INC 				;AN000;
	INCLUDE    CASTRUC.INC					;AN000;
	INCLUDE    STRUC.INC					;AN000;
	INCLUDE    MACROS.INC					;AN000;
	INCLUDE    EXT.INC					;AN000;
	INCLUDE    VARSTRUC.INC 				;AN000;
	INCLUDE    ROUT_EXT.INC 				;AN000;
.LIST								;AN000;
	PUBLIC	DOS_LOC_SCREEN					;AN000;
	PUBLIC	PRINTER_SCREEN					;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	SEGMENT PARA PUBLIC 'SELECT'                            ;AN000;
	ASSUME	CS:SELECT,DS:DATA				;AN000;
								;
	INCLUDE CASEXTRN.INC					;AN000;
								;
	EXTRN	INSTALL_ERROR:NEAR				;AN000;
	EXTRN	EXIT_DOS:NEAR					;AN000;
	EXTRN	EXIT_SELECT:NEAR				;AN000;
								;
	EXTRN	PROCESS_ESC_F3:NEAR				;AN000;
	EXTRN	INTRO_SCREEN:NEAR				;AN000;
	EXTRN	choose_shell_screen:NEAR			;mrw0 ;AC020;SEH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �DOS_LOC_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The DOS LOCATION screen is presented only if DOS is to be installed
;  on drive C:.
;  The maximum length of the install path will be limited to 40 characters.
;  This restriction is imposed so that when generating commands
;  for the CONFIG.SYS and AUTOEXEC.BAT files, the command line length will not
;  exceed 128 characters.
;  When the screen is presented for the first time, the default install
;  path displayed will be "DOS".  On subsequent presentations, the user
;  selected path will be displayed.
;  Valid keys are ENTER, ESC, F1, F3 and ASCII characters A to Z.
;?????????????????????????????update?????????????????????????????????
;  The Functional Specification dated 5 May 1987, states that the APPEND
;  and PATH commands will be generated if the user selected to minimize workspace
;  or maximize workspace but not if the user selected balance workspace.  Since
;  this assumption does not seem logical, the check has been revised to
;  generate the commands if the install destination is drive C:.  Also, the
;  PC/DOS parameters screen does not check for the workspace definition.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DOS_LOC_SCREEN: 						;AN000;
	.IF < I_DEST_DRIVE ne E_DEST_DRIVE_C >			;AN111; if install destination is drive A: or B: JW
	.THEN							;AN000;
	   INIT_VAR		F_PROMPT, E_PROMPT_NO		;AN000;    set prompt = no
	   INIT_VAR		F_PATH, E_PATH_NO		;AN000;    set path = no
	   INIT_VAR		F_APPEND, E_APPEND_NO		;AN000;    set append = no
	   GOTO 		PRINTER_SCREEN			;AN000;    goto next screen (PRINTER)
	.ENDIF							;AN000;
								;
	INIT_PQUEUE		PAN_DOS_LOC			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_STRING		STR_DOS_LOC,S_DOS_LOC,M_DOS_LOC ;AN000;
	.IF < N_DISK1_MODE ne E_DISK1_INSTALL > 		;AN000; if this is not a new fixed disk   JW
	.THEN							;AN000; then				  JW
	   INIT_SCROLL		   SCR_COPY_DEST,I_DESTINATION	;AN000;   initialize destination choice   JW
	   INIT_SCROLL_COLOUR	   SCR_COPY_DEST,2		;AN026;   set field to not active color
	.ENDIF							;AN000; endif				  JW
	DISPLAY_PANEL						;AN000; display DOS_LOC panel
								;
	COPY_STRING		S_STR120_1,M_STR120_1,S_DOS_LOC ;AN000;
								;
GET_DOS_LOCATION:						;AN000;
	GET_STRING		STR_DOS_LOC,S_STR120_1,M_DOS_LOC,FK_TAB     ;AN000;get new install path
								;
	PROCESS_F3						;AN000; if user entered F3, exit to DOS
	PROCESS_ESC						;AN000; if user entered ESC, goto previous screen
								;
	COPY_STRING		S_STR120_1,M_STR120_1,S_USER_STRING   ;AN000;
	CHECK_PATH		S_STR120_1,0, 0 		;AN000;
	.IF nc	near						;AN000; if path is valid
	.THEN							;AN000;
	   COPY_STRING		S_DOS_LOC,M_DOS_LOC,S_USER_STRING     ;AN000;  save new DOS install path
	   COPY_STRING		S_STR120_2, M_STR120_2, S_INSTALL_PATH;AN000;save old install path
	   MERGE_STRING 	S_INSTALL_PATH,M_INSTALL_PATH,S_DEST_DRIVE,S_DOS_LOC ;AN000; add 'C:\' to install path
	   COMPARE_STRINGS	S_INSTALL_PATH, S_STR120_2	;AN000;    compare old and new paths
	   .IF c						;AN000;    if paths different
	   .THEN						;AN000;
	      INIT_VAR		F_APPEND, E_APPEND_YES		;AN000;       set APPEND = yes
	      COPY_STRING	S_APPEND,M_APPEND,S_INSTALL_PATH;AN000;      set new APPEND path
	      INIT_VAR		F_PATH, E_PATH_YES		;AN000;       set PATH = yes
	      COPY_STRING	S_PATH, M_PATH, S_INSTALL_PATH	;AN000;       set new DOS path
	   .ELSEIF < S_APPEND eq 0 >				;AN000;
	   .THEN						;AN000;
	      COPY_STRING	S_APPEND,M_APPEND,S_INSTALL_PATH;AN000;
	      INIT_VAR		F_APPEND, E_APPEND_YES		;AN000;
	   .ENDIF						;AN000;
	   .IF < I_WORKSPACE eq E_WORKSPACE_MIN >		;AN000;    if workspace option = minimize
	   .THEN						;AN000;
	      INIT_VAR		S_APPEND, 0			;AN000;       set APPEND= null
	   .ENDIF						;AN000;
	   INIT_VAR		F_PROMPT, E_PROMPT_YES		;AN000;    set PROMPT = yes
	.ELSE							;AN000; else
	   HANDLE_ERROR 	ERR_BAD_PATH, E_RETURN		;AN000;    pop error message
	   GOTO 		GET_DOS_LOCATION		;AN000;    goto get DOS location again
	.ENDIF							;AN000;
								;
	.IF < N_DISK1_MODE ne E_DISK1_INSTALL > AND		;AN000; if this is not a new fixed disk    JW
	.IF < N_USER_FUNC eq E_TAB >				;AN000; if user tabbed to the scroll field JW
	.THEN							;AN000; 				   JW
	   GET_SCROLL		SCR_COPY_DEST,I_DESTINATION,FK_TAB    ;AN000;				   JW
	   PROCESS_F3						;AN000; if user entered F3, exit to DOS    JW
	   PROCESS_ESC						;AN000; 				   JW
	   COPY_WORD		I_DESTINATION, I_USER_INDEX	;AN000; save new install destination drive JW
	   .IF < N_USER_FUNC eq E_TAB > 			;AN000; if user entered ESC		   JW
	   .THEN						;AN000; 				   JW
	      SET_SCROLL	SCR_COPY_DEST,I_DESTINATION	;AN026; Set to not active
	      GOTO		GET_DOS_LOCATION		;AC051;SEH ;AN000 Go get dos location	   JW
	   .ENDIF						;AN000; 				   JW
	.ENDIF							;AN000; 				   JW
	PUSH_HEADING		DOS_LOC_SCREEN			;AC051;SEH ;AN000;    save screen address on SELECT STACK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �PRINTER_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The PRINTER SCREEN is always presented.
;  The screen allows the user to indicate the number of printers attached.
;  Valid keys are ENTER, ESC, F1, F3 and numeric 0 to 7.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINTER_SCREEN: 						;AN000;
	.IF < N_PARALLEL eq 0 > and				;AN000; if zero parallel and
	.IF < N_SERIAL eq 0 >					;AN000; and zero serial printers
	.THEN							;AN000;
	   INIT_VAR		F_GRAPHICS, E_GRAPHICS_NO	;AN000;    set GRAPHICS = no  JW
	   GOTO 		choose_shell_screen		;mrw0 ;AC020;SEH goto next screen
	.ENDIF							;AN000;
								;
	;;;display panel to get number of printers		;
	INIT_PQUEUE		PAN_PRINTER			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_NUMERIC		NUM_PRINTER,N_NUMPRINT,MAX_NUMPRINT,S_STR120_1;AN000;
	DISPLAY_PANEL						;AN000;
								;
	;;;get number of printers				;
	GET_NUMERIC		NUM_PRINTER,N_NUMPRINT,MIN_NUMPRINT,MAX_NUMPRINT,FK_TEXT,S_STR120_1;AN000;
								;
	;;;save number of printers and goto next screen 	;
	.IF < N_USER_FUNC eq E_ENTER >				;AN000; if user entered ENTER key
	.THEN							;AN000;
	   COPY_WORD		N_NUMPRINT, N_USER_NUMERIC	;AN000;    save number of printers
	   PUSH_HEADING 	PRINTER_SCREEN			;AN000;    save screen address on SELECT STACK
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ESC or F3, take action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �PRINTER_TYPE_SCREEN 		�
;  �					�
;  ��������������������������������������
;
;	Get type of printer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINTER_TYPE_SCREEN:						;AN000;
	.IF < N_NUMPRINT eq MIN_NUMPRINT >			;AN000; if zero printers specified
	.THEN							;AN000;
	   INIT_VAR		F_GRAPHICS, E_GRAPHICS_NO	;AN000; set GRAPHICS = no  JW
	   GOTO 		choose_shell_screen	 	;mrw0 ;AC020; SEH goto next screen
	.ENDIF							;AN000;
								;
	GET_PRINTER_TITLES	S_PRINT_FILE			;AN000; read printer titles from SELECT.PRT
	.IF c							;AN000; if error reading file
	.THEN							;AN000;
	   INIT_VAR		N_NUMPRINT, MIN_NUMPRINT	;AN000;    set no of printers = 0
	   HANDLE_ERROR 	ERR_BAD_PFILE, E_RETURN 	;AN000;    popup error message
	   GOTO 		choose_shell_screen		;mrw0 ;AC020; SEH goto next screen
	.ENDIF							;AN000;
								;
	INIT_VAR		N_COUNTER, 1			;AN000; set printer no = 1
	.IF < I_WORKSPACE ne E_WORKSPACE_MIN >			;AN014; SEH if not minimum DOS workspace
	.THEN							;AN014;
	   INIT_VAR		F_GRAPHICS, E_GRAPHICS_YES	;AN000; set GRAPHICS = yes SEH
	.ENDIF							;AN014; SEH
								;
GET_PRINTER_TYPE:						;AN000; repeat loop to get printer info
								;
	.IF < N_COUNTER eq 0 >					;AN000;    if printer no = zero
	.THEN							;AN000;
	   RELEASE_PRINTER_INFO 				;AN000;       release memory
	   .IF c						;AN000;
	   .THEN						;AN000;
	      GOTO		INSTALL_ERROR			;AN000;
	   .ENDIF						;AN000;
	   POP_HEADING						;AN000;       goto previous screen
	.ENDIF							;AN000;
								;
	.SELECT 						;AN000;    get printer no sub panel
								;
	.WHEN < N_COUNTER eq 1 >				;AN000;
	   INIT_VAR		N_BYTE_1, '1'                   ;AC025;
								;
	.WHEN < N_COUNTER eq 2 >				;AN000;
	   INIT_VAR		N_BYTE_1, '2'                   ;AC025;
								;
	.WHEN < N_COUNTER eq 3 >				;AN000;
	   INIT_VAR		N_BYTE_1, '3'                   ;AC025;
								;
	.WHEN < N_COUNTER eq 4 >				;AN000;
	   INIT_VAR		N_BYTE_1, '4'                   ;AC025;
								;
	.WHEN < N_COUNTER eq 5 >				;AN000;
	   INIT_VAR		N_BYTE_1, '5'                   ;AC025;
								;
	.WHEN < N_COUNTER eq 6 >				;AN000;
	   INIT_VAR		N_BYTE_1, '6'                   ;AC025;
								;
	.OTHERWISE						;AN000;
	   INIT_VAR		N_BYTE_1, '7'                   ;AC025;
								;
	.ENDSELECT						;AN000;
								;
	GET_PRINTER_PARAMS	N_COUNTER, 0, N_RETCODE 	;AN000;    based on printer #
								;
	;;;N_BYTE_1 = printer number				;
	INIT_CHAR		N_BYTE_1, E_DISK_ROW, E_DISK_COL, SUB_PRINTER_1 ;AN025; display the printer number
	INIT_PQUEUE		PAN_PRT_TYPE			;AN000;    initialize queue
	PREPARE_PANEL		SUB_PRINTER_1			;AC025;    printer no
	PREPARE_PANEL		PAN_HBAR			;AN000;    prepare horizontal bar
	PREPARE_CHILDREN					;AN000;    prepare child panels
	INIT_SCROLL_W_LIST	SCR_PRT_TYPE,SEG_LOC,NAMES_OFF,N_PRN_NAMES,SIZE_NAMES,MAX_NAME,I_PRINTER;AN000;
	DISPLAY_PANEL						;AN000;
								;
	GET_SCROLL		SCR_PRT_TYPE,I_PRINTER,FK_SCROLL;AN000;    get printer type
								;
	PROCESS_F3						;AN000;    take action if F3 entered
								;
	.IF < N_USER_FUNC eq E_ESCAPE > 			;AN000;    if user entered ESC
	.THEN							;AN000;
	   DEC			N_COUNTER			;AN000;       dec printer number
	   GOTO 		GET_PRINTER_TYPE		;AN000;       goto previous printer
	.ENDIF							;AN000;
								;
	COPY_WORD		I_PRINTER, I_USER_INDEX 	;AN000;    save printer type
								;
	GET_PRINTER_INFO	I_PRINTER			;AN000;    get printer info from SELECT.PRT
	.IF c							;AN000;    if error
	.THEN							;AN000;
	   HANDLE_ERROR 	ERR_BAD_PPRO, E_RETURN		;AN000;       popup error message
	   GOTO 		GET_PRINTER_TYPE		;AN000;       goto get printer type
	.ENDIF							;AN000;
								;
	.IF < N_PRINTER_TYPE eq E_PARALLEL > and		;AN000;
	.IF < N_PARALLEL eq 0 > 				;AN000;
	.THEN							;AN000;
	   HANDLE_ERROR 	ERR_PRT_NO_HDWR, E_RETURN	;AN000;
	   GOTO 		GET_PRINTER_TYPE		;AN000;
	.ENDIF							;AN000;
								;
	.IF < N_PRINTER_TYPE eq E_SERIAL > and			;AN000;
	.IF < N_SERIAL eq 0 >					;AN000;
	.THEN							;AN000;
	   HANDLE_ERROR 	ERR_PRT_NO_HDWR, E_RETURN	;AN000;
	   GOTO 		GET_PRINTER_TYPE		;AN000;
	.ENDIF							;AN000;
								;
	.SELECT 						;AN000;
								;
	.WHEN < N_PRINTER_TYPE eq E_PARALLEL > near		;AN000;    if parallel printer
	   INIT_CHAR		N_BYTE_1, E_DISK_ROW, E_DISK_COL, SUB_PRINTER_1 ;AN025; display the printer number
	   INIT_PQUEUE		PAN_PARALLEL			;AN000;       initialize queue
	   PREPARE_PANEL	SUB_PRINTER_1			;AC025;
	   PREPARE_PANEL	PAN_HBAR			;AN000;       prepare horizontal bar
	   PREPARE_CHILDREN					;AN000;       prepare child panels
	   INIT_SCROLL_W_LIST	SCR_ACC_PRT,SEG_LOC,NAMES_OFF,N_PRN_NAMES,SIZE_NAMES,MAX_NAME,I_PRINTER;AN000;
	   INIT_SCROLL_W_NUM	SCR_PARALLEL,N_PARALLEL,I_PORT	;AN000;
	   DISPLAY_PANEL					;AN000;       display panel
								;
	   GET_SCROLL		SCR_PARALLEL, I_PORT, FK_SCROLL ;AN000;
	   COPY_WORD		I_PORT, I_USER_INDEX		;AN000;
								;
	.OTHERWISE  near					;AN000;    if serial printer
								;
	   INIT_CHAR		N_BYTE_1, E_DISK_ROW, E_DISK_COL, SUB_PRINTER_1 ;AN025; display the printer number
	   INIT_PQUEUE		PAN_SERIAL			;AN000;       initialize queue
	   PREPARE_PANEL	SUB_PRINTER_1			;AN025;
	   PREPARE_PANEL	PAN_HBAR			;AN000;       prepare horizontal bar
	   PREPARE_CHILDREN					;AN000;       prepare child panels
	   INIT_SCROLL_W_LIST	SCR_ACC_PRT,SEG_LOC,NAMES_OFF,N_PRN_NAMES,SIZE_NAMES,MAX_NAME,I_PRINTER;AN000;
	   INIT_SCROLL_W_NUM	SCR_SERIAL,N_SERIAL,I_PORT	;AN000;
	   INIT_SCROLL		SCR_PRT_REDIR, I_REDIRECT	;AN000;
	   INIT_SCROLL_COLOUR	SCR_PRT_REDIR, 2		;AN000;
	   DISPLAY_PANEL					;AN000;
								;
	   .REPEAT						;AN000;
	      SET_SCROLL	SCR_PRT_REDIR, I_REDIRECT	;AN000;
	      GET_SCROLL	SCR_SERIAL, I_PORT, FK_TAB	;AN000;
	      COPY_WORD 	I_PORT, I_USER_INDEX		;AN000;
	      .IF < N_USER_FUNC eq E_TAB > near 		;AN000;
	      .THEN						;AN000;
		 SET_SCROLL	SCR_SERIAL, I_PORT		;AN000;
		 GET_SCROLL	SCR_PRT_REDIR,I_REDIRECT,FK_TAB ;AN000;
		 COPY_WORD	I_REDIRECT, I_USER_INDEX	;AN000;
	      .ENDIF						;AN000;
								;
	   .UNTIL < N_USER_FUNC eq E_ENTER > or near		;AN000;
	   .UNTIL < N_USER_FUNC eq E_ESCAPE > or near		;AN000;
	   .UNTIL < N_USER_FUNC eq E_F3 >			;AN000;
								;
	.ENDSELECT						;AN000;
								;
	PROCESS_F3						;AN000;
								;
	.IF < N_USER_FUNC eq E_ESCAPE > 			;AN000; if user entered ESC
	.THEN							;AN000;
	   GOTO 		GET_PRINTER_TYPE		;AN000;    goto get printer type
	.ENDIF							;AN000;
	SAVE_PRINTER_PARAMS	N_COUNTER			;AN000; save printer parameters
	INC_VAR 		N_COUNTER			;AN000; inc printer number
	COMP_WORDS		N_COUNTER, N_NUMPRINT		;AN000; if printer no > no of printers
	.IF nc and						;AN000;
	.IF nz							;AN000;
	.THEN							;AN000;
	   RELEASE_PRINTER_INFO 				;AN000;    release memory
	   .IF c						;AN000;    if error
	   .THEN						;AN000;
	      GOTO		INSTALL_ERROR			;AN000;       :::::::
	   .ENDIF						;AN000;
	   GOTO 		choose_shell_screen		;mrw0 ;AC020; SEH goto next screen
	.ELSE							;AN000;
	   GOTO 		GET_PRINTER_TYPE		;AN000;
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	ENDS							;AN000;
	END							;AN000;
