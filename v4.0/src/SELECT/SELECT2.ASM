

PAGE	55,132							;AN000;
NAME	SELECT							;AN000;
TITLE	SELECT - DOS - SELECT.EXE				;AN000;
SUBTTL	SELECT2.asm						;AN000;
.ALPHA								;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SELECT2.ASM : Copyright 1988 Microsoft
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
;
;  Module contains code for :
;	- Program/Memory workspace screen
;	- Predefined country/keyboard screen
;	- Country screen
;	- Keyboard screen
;	- Alternate Keyboard screen
;	- Load the specified keyboard
;	- Install drive screen
;	- DOS location screen
;
;	CHANGE HISTORY:
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	SEGMENT BYTE PUBLIC 'DATA'                              ;AN000;
	EXTRN  EXEC_ERR:BYTE					;
DATA	       ENDS						;AN000;
								;
.XLIST								;AN000;
	INCLUDE    PANEL.MAC					;AN000;
	INCLUDE    SELECT.INC					;AN000;
	INCLUDE    CASTRUC.INC					;AN000;
	INCLUDE    STRUC.INC					;AN000;
	INCLUDE    MACROS.INC					;AN000;
	INCLUDE    EXT.INC					;AN000;
	INCLUDE    VARSTRUC.INC 				;AN000;
	INCLUDE    ROUT_EXT.INC 				;AN000;
	INCLUDE    PAN-LIST.INC 				;AN000;
.LIST								;AN000;
								;
	PUBLIC	WORKSPACE_SCREEN				;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	SEGMENT PARA PUBLIC 'SELECT'                            ;AN000;
	ASSUME	CS:SELECT,DS:DATA				;AN000;
								;
	INCLUDE CASEXTRN.INC					;AN000;
								;
	EXTRN	EXIT_DOS:NEAR					;AN000;
	EXTRN	EXIT_SELECT:NEAR				;AN000;
	EXTRN	PROCESS_ESC_F3:NEAR				;AN000;
	EXTRN	INTRO_SCREEN:NEAR				;AN000;
	EXTRN	DOS_LOC_SCREEN:NEAR				;AN000;
	EXTRN	DEALLOCATE_MEMORY_CALL:FAR			;AN000;DT
	EXTRN	GET_OVERLAY:NEAR				;AN000;DT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �WORKSPACE_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The User Function and Memory Workspace Needs Screen is always presented.
;  The screen allows the user to define the memory requirements for
;  the install process.  Default values for DOS commands will be assigned based
;  on user input.
;  Valid keys are ENTER, ESC, F1, cursor up/down and numeric 1 to 3.
;
;  All values are re-initialized the second time round only if the new option
;  is different from the previously selected option.
;
; �����������������������������������������������������������������Ŀ
; �		 �  I_WORKSPACE=1 �  I_WORKSPACE=2 �  I_WORKSPACE=3 �
; �����������������������������������������������������������������Ĵ
; � P_BREAK	 �  'ON'          �  'ON'          �  'ON'          �
; � P_BUFFERS	 �  ' '           �  '20'          �  '50,4'        �
; � P_CPSW	 �  'OFF'         �  'OFF'         �  'OFF'         �
; � F_CPSW	 �  no		  �  no 	   �  no	    �
; � P_FCBS	 �  ' '           �  ' '           �  '20,8'        �
; � P_FILES	 �  '8'           �  '20'          �  '20'          �
; � P_LASTDRIVE  �  'E'           �  'E'           �  'E'           �
; � P_STACKS	 �  ' '           �  ' '           �  ' '           �
; � P_VERIFY	 �  'OFF'         �  'OFF'         �  'OFF'         �
; � P_PROMPT	 �  '$P$G'        �  '$P$G'        �  '$P$G'        �
; � F_PROMPT	 �  no		  �  no 	   �  no	    �
; � P_PATH	 �  ' '           �  ' '           �  ' '           �
; � F_PATH	 �  no		  �  no 	   �  no	    �
; � P_APPEND	 �  ' '           �  ' '           �  ' '           �
; � F_APPEND	 �  no		  �  no 	   �  no	    �
; � P_ANSI	 �  ' '           �  ' '           �  '/X'          �
; � F_ANSI	 �  no		  �  yes	   �  yes	    �
; � P_FASTOPEN	 �  ' '           �  'C:=(50,25)'  �  'C:=(100,200)'�
; � F_FASTOPEN	 �  no		  �  yes	   �  yes	    �
; � F_GRAFTABL	 �  no		  �  no 	   �  no	    �
; � P_GRAPHICS	 �  ' '           �  ' '           �  ' '           �
; � F_GRAPHICS	 �  no		  �  yes	   �  yes	    �
; � P_SHARE	 �  ' '           �  ' '           �  ' '           �
; � F_SHARE	 �  no		  �  no 	   �  no	    �
; � P_SHELL	 �  '/R'          �  '/R'          �  '/R'          �
; � F_SHELL	 �  yes 	  �  yes	   �  yes	    �
; � P_VDISK	 �  ' '           �  ' '           �  ' '           �
; � F_VDISK	 �  no		  �  no 	   �  no	    �
; � P_XMAEM	 �  ' '           �  ' '           �  ' '           �
; � DOS_LOC	 �  'DOS'         �  'DOS'         �  'DOS'         �
; � F_XMA	 �  yes 	  �  yes	   �  yes	    �
; � P_XMA2EMS	 �  'FRAME=D000 P254=C800 P255=CC00' for all options�
; �������������������������������������������������������������������
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WORKSPACE_SCREEN:						;AN000;
	INIT_PQUEUE		PAN_WORKSPACE			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		SCR_DOS_SUPPORT,I_WORKSPACE	;AN000;
	DISPLAY_PANEL						;AN000; display WORKSPACE panel
								;
	GET_SCROLL		SCR_DOS_SUPPORT,I_WORKSPACE,FK_SCROLL ;AN000; get user entered option
	.IF < N_USER_FUNC eq E_F3 >				;AN027;SEH  Added to prevent going to Intro Screen
	    GOTO	     EXIT_DOS				;AN027;SEH     when F3 hit
	.ELSEIF < N_USER_FUNC eq E_ENTER > near 		;AN000; if user entered ENTER key
	.THEN							;AN000;
	   PUSH_HEADING 	WORKSPACE_SCREEN		;AN000;    save screen address on SELECT STACK
	   COMP_WORDS		N_WORK_PREV, I_USER_INDEX	;AN000;    compare previous and new options
	   .IF nz  near 					;AN000;    if new option is different
	   .THEN						;AN000;
	      COPY_WORD 	I_WORKSPACE, I_USER_INDEX	;AN000;       set current option = new option
	      COPY_WORD 	N_WORK_PREV, I_USER_INDEX	;AN000;       set previous option = new option
								;
	      .SELECT						;AN000;
								;
	      .WHEN < I_WORKSPACE eq E_WORKSPACE_MIN > near	;AN000;       option =	minimize DOS functions
		 INIT_VAR_MINIMIZE				;AN000; 	  initialize variables
								;
	      .WHEN < I_WORKSPACE eq E_WORKSPACE_BAL > near	;AN000;       option =	balance DOS functions
		 INIT_VAR_BALANCE				;AN000; 	 initialize variables
								;
	      .OTHERWISE					;AN000;       option = maximize DOS functions
		 INIT_VAR_MAXIMIZE				;AN000; 	  initialize variables
								;
	      .ENDSELECT					;AN000;
								;
	   .ENDIF						;AN000;
	   GOTO 		CTY_KYBD_SCREEN 		;AN000;    goto the next screen (CTY-KYBD)
	.ELSE							;AN000;
	   GOTO 		INTRO_SCREEN			;AN001;GHG; user entered ENTER or ESC, take action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �CTY_KYBD_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The COUNTRY and KEYBOARD support screen is always presented.
;  The screen allows the user to choose the pre-defined country and
;  keyboard displayed or to select a country specific support.
;  When the screen is presented for the first time, the pre-defined
;  country is the country code in the CONFIG.SYS file obtained by a DOS call.
;  The pre-defined keyboard is the
;  default keyboard associated with the pre-defined country.  If there is no
;  valid keyboard association, "None" is displayed.  Subsequent presentation of
;  this screen will display the user selected support.
;  Two keyboards are associated with the Swiss country code; French and
;  German.  The keyboard code to be used will be identified during translation
;  and will be saved in the form of a panel.
;  Valid keys are ENTER, ESC, F1, F3, cursor up/down, numeric 1 to 2.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CTY_KYBD_SCREEN:						;AN000;
	COPY_WORD		N_WORD_1, I_COUNTRY		;AN000; scroll list item = country index
	.IF < N_CTY_LIST eq E_CTY_LIST_2 >			;AN000; if country list = 2
	.THEN							;AN000;
	   ADD_WORD		N_WORD_1, CTY_A_ITEMS		;AN000;    add items in list 1
	.ENDIF							;AN000;
								;
	.IF < N_KYBD_ALT eq E_KYBD_ALT_NO > near		;AN000; if no alt kyb id
	.THEN							;AN000;
	   COPY_WORD		N_WORD_2, I_KEYBOARD		;AN000;    scroll list item = keyboard index
	   .IF < N_KYBD_LIST eq E_KYBD_LIST_2 > 		;AN000;    if kybd list = 2
	   .THEN						;AN000;
	      ADD_WORD		N_WORD_2, KYBD_A_ITEMS		;AN000;       add items in list 1
	   .ENDIF						;AN000;
	.ELSE							;AN000; else
								;
	   INIT_VAR		N_WORD_2, KYBD_A_ITEMS		;AN000;    scroll list item = items in list 1
	   ADD_WORD		N_WORD_2, KYBD_B_ITEMS		;AN000; 		      + items in list 2
	   ADD_WORD		N_WORD_2, 1			;AN000; 	    + 1st item in French alt kybd
	   .IF < ALT_KYB_ID gt ALT_FRENCH >			;AN000;    if alt kybd id > French
	   .THEN						;AN000;
	      ADD_WORD		N_WORD_2, ALT_FR_ITEMS		;AN000;       add items in French alt kybd to list
	   .ENDIF						;AN000;GHG
	   .IF < ALT_KYB_ID gt ALT_ITALIAN >			;AN000;GHG if alt kybd id > Italian
	   .THEN						;AN000;
	      ADD_WORD		N_WORD_2, ALT_IT_ITEMS		;AN000;       add items in Italian alt kybd to list
	   .ENDIF						;AN000;
								;
	    DEC 		    N_WORD_2			;AN090;GHG  These two lines were moved inside the
	    ADD_WORD		    N_WORD_2, I_KYBD_ALT	;AN090;GHG    ELSE clause.
								;
	.ENDIF							;AN000;
								;
								;
	INIT_PQUEUE		PAN_CTY_KYB			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		SCR_ACC_CTY, N_WORD_1		;AN000; display current country
	INIT_SCROLL		SCR_ACC_KYB, N_WORD_2		;AN000; display current keyboard
	INIT_SCROLL		SCR_CTY_KYB, I_CTY_KYBD 	;AN000;
	DISPLAY_PANEL						;AN000; display screen
								;
	GET_SCROLL		SCR_CTY_KYB,I_CTY_KYBD,FK_SCROLL;AN000; get new option
								;
	.IF < N_USER_FUNC eq E_ENTER >				;AN000; if user entered ENTER key
	.THEN							;AN000;
	   COPY_WORD		I_CTY_KYBD, I_USER_INDEX	;AN000;    save new option
	   PUSH_HEADING 	CTY_KYBD_SCREEN 		;AN000;    save screen address on SELECT STACK
	   GOTO 		COUNTRY_SCREEN			;AN000;    goto the next screen (COUNTRY)
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ESC or F3, take action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �COUNTRY_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The COUNTRY CODE screen is presented if the user selected to define
;  country specific support (CTY_KYBD_SCREEN).
;  When this screen is presented for the first time, the current
;  country obtained from DOS will be highlighted.  Subsequent presentations
;  of this screen will highlight the user selected country.
;  Code Page to be used will be determined by the selected country code.
;  Valid keys are ENTER, ESC, F1, F3, cursor up/down.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COUNTRY_SCREEN: 						;AN000;
	.IF < I_CTY_KYBD eq E_CTY_KB_PREDEF >			;AN000; if accept pre-defined support
	.THEN							;AN000;
	   GOTO 		LOAD_KEYBOARD			;AN000;    goto load specified kybd id
	.ENDIF							;AN000;
								;
	INIT_PQUEUE		PAN_COUNTRY			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		SCR_CTY_1, 0			;AN000; init 1st scroll list
	INIT_SCROLL		SCR_CTY_2, 0			;AN000; init 2nd scroll list
	DISPLAY_PANEL						;AN000; display COUNTRY panel
								;
	.IF < N_CTY_LIST eq E_CTY_LIST_1 >			;AN000; if country is in list 1
	.THEN							;AN000;
	   GET_SCROLL		SCR_CTY_1,I_COUNTRY, FK_SCROLL	;AN000;    highlight country in list 1 & get new choice
	.ELSE							;AN000; else
	   GET_SCROLL		SCR_CTY_2, I_COUNTRY, FK_SCROLL ;AN000;     highlight country in list 2 & get new choice
	.ENDIF							;AN000;
								;
	.REPEAT 						;AN000; repeat code block: CASS cannot do this automatically
	   .IF < N_USER_FUNC eq UPARROW > near			;AN000; if user entered cursor up
	   .THEN						;AN000;
	      .IF < N_CTY_LIST eq E_CTY_LIST_1 > near		;AN000;    if country list = 1
	      .THEN						;AN000;
		 INIT_VAR	N_CTY_LIST, E_CTY_LIST_2	;AN000;       set country list = 2
		 GET_SCROLL	SCR_CTY_2,CTY_B_ITEMS,FK_SCROLL ;AN000;       point to last item in list 2
	      .ELSE  near					;AN000;    else
		 INIT_VAR	N_CTY_LIST, E_CTY_LIST_1	;AN000;       set country list = 1
		 GET_SCROLL	SCR_CTY_1,CTY_A_ITEMS,FK_SCROLL ;AN000;       point to last item in list 1
	      .ENDIF						;AN000;
	   .ELSEIF < N_USER_FUNC EQ DNARROW > near		;AN000; else if user entered cursor down
	   .THEN						;AN000;
	      .IF < N_CTY_LIST eq E_CTY_LIST_1 > near		;AN000;    if country list = 1
	      .THEN						;AN000;
		 INIT_VAR	N_CTY_LIST, E_CTY_LIST_2	;AN000;       set country list = 2
		 GET_SCROLL	SCR_CTY_2, 1, FK_SCROLL 	;AN000;       point to 1st item in list 2
	      .ELSE  near					;AN000;    else
		 INIT_VAR	N_CTY_LIST, E_CTY_LIST_1	;AN000;       set country list = 1
		 GET_SCROLL	SCR_CTY_1, 1, FK_SCROLL 	;AN000;       point to 1st item in list 1
	      .ENDIF						;AN000;
	   .ELSE near						;AN000; else
	      .LEAVE						;AN000;    break away from repeat loop
	   .ENDIF						;AN000;
	.UNTIL							;AN000; end of repeat block
								;
	.IF < N_USER_FUNC eq E_ENTER > near			;AN000; if user entered ENTER key
	.THEN							;AN000;
	   COPY_WORD		I_COUNTRY, I_USER_INDEX 	;AN000;    save new country
	   PUSH_HEADING 	COUNTRY_SCREEN			;AN000;    save screen address on SELECT STACK
	   GET_COUNTRY_DEFAULTS N_CTY_LIST, I_COUNTRY		;AN000;    get country default parameters
	   .IF < N_DISPLAY eq E_CPSW_DISP >			;AN000;
	   .THEN						;AN000;
	      .IF < N_CPSW eq E_CPSW_NOT_VAL >			;AN000;    if cpsw not valid
	      .THEN						;AN000;
		 INIT_VAR	F_CPSW, E_CPSW_NA		;AN000;       set cpsw = not available
	      .ELSEIF < N_CPSW eq E_CPSW_NOT_REC >		;AN000;    else if cpsw not recommended
	      .THEN						;AN000;
		 INIT_VAR	F_CPSW, E_CPSW_NO		;AN000;       set cpsw = no
	      .ELSE						;AN000;    else
		 INIT_VAR	F_CPSW, E_CPSW_YES		;AN000;       set cpsw = yes
	      .ENDIF						;AN000;
	   .ELSE						;AN000;
	      INIT_VAR		F_CPSW, E_CPSW_NA		;AN000;
	   .ENDIF						;AN000;
								;
	   ;;; get keyboard from input field if country = Swiss ;
	   COMPARE_STRINGS	S_KEYBOARD,S_SWISS		;AN000;GHG is default KB=SF?
	   .IF <NC>						;AN000;GHG
	   .THEN						;AN000;GHG
	      RETURN_STRING	STR_SWISS_KEYB,S_KEYBOARD,M_KEYBOARD+2;AN000;GHG
	   .ENDIF						;AN000;GHG
								;
	   GET_KEYBOARD_INDEX	S_KEYBOARD,N_KYBD_LIST,I_KEYBOARD,N_KYBD_ALT ;AN000; get index into keyboard tables
	   GOTO 		KEYBOARD_SCREEN 		;AN000;    goto the next screen (KEYBOARD)
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ESC or F3, action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �KEYBOARD_SCREEN			�
;  �					�
;  ��������������������������������������
;  The KEYBOARD CODE screen is presented if the user had selected to
;  define country specific support and the country code selected has a valid
;  keyboard code association.
;  The keyboard code associated with the selected country code will be
;  highlighted.
;  For keyboards that have more than one valid keyboard code, a second
;  level keyboard code screen will be presented to the user.
;  Valid keys are ENTER, ESC, F1, F3, cursor up/down.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
KEYBOARD_SCREEN:						;AN000;
	.IF < N_KYB_LOAD eq E_KYB_LOAD_ERR >			;AN000; if KEYB load status is error
	.THEN							;AN000;
	   INIT_VAR		N_KYB_LOAD, E_KYB_LOAD_UND	;AN000;    set KEYB loaded status = undefined
	   POP_HEADING						;AN000;    goto previous screen
	.ENDIF							;AN000;
								;
	.IF < N_KYBD_VAL eq E_KYBD_VAL_NO >			;AN000; if keyboard id not valid
	.THEN							;AN000;
	   GOTO 		LOAD_KEYBOARD			;AN000;    goto load specified kybd id
	.ENDIF							;AN000;
								;
	INIT_PQUEUE		PAN_KEYBOARD			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		SCR_KYB_1, 0			;AN000; init 1st scroll list
	INIT_SCROLL		SCR_KYB_2, 0			;AN000; init 2nd scroll list
	DISPLAY_PANEL						;AN000; display KEYBOARD panel
								;
	.IF < N_KYBD_LIST eq E_KYBD_LIST_1 >			;AN000; if keyboard is in list 1
	.THEN							;AN000;
	   GET_SCROLL		SCR_KYB_1,I_KEYBOARD, FK_SCROLL ;AN000;    highlight kybd in list 1 & get new choice
	.ELSE							;AN000; else
	   GET_SCROLL		SCR_KYB_2,I_KEYBOARD, FK_SCROLL ;AN000;     highlight kybd in list 2 & get new choice
	.ENDIF							;AN000;
								;
	.REPEAT 						;AN000; repeat code block: CASS cannot do this automatically
	   .IF < N_USER_FUNC eq UPARROW > near			;AN000; if user entered cursor up
	   .THEN						;AN000;
	      .IF < N_KYBD_LIST eq E_KYBD_LIST_1 > near 	;AN000;    if kybd list = 1
	      .THEN						;AN000;
		 INIT_VAR	N_KYBD_LIST, E_KYBD_LIST_2	;AN000;       set kybd list = 2
		 GET_SCROLL	SCR_KYB_2,KYBD_B_ITEMS,FK_SCROLL;AN000;       point to last item in list 2
	      .ELSE  near					;AN000;    else
		 INIT_VAR	N_KYBD_LIST, E_KYBD_LIST_1	;AN000;       set kybd list = 1
		 GET_SCROLL	SCR_KYB_1,KYBD_A_ITEMS,FK_SCROLL;AN000;      point to last item in list 1
	      .ENDIF						;AN000;
	   .ELSEIF < N_USER_FUNC EQ DNARROW > near		;AN000; else if user entered cursor down
	   .THEN						;AN000;
	      .IF < N_KYBD_LIST eq E_KYBD_LIST_1 > near 	;AN000;    if kybd list = 1
	      .THEN						;AN000;
		 INIT_VAR	N_KYBD_LIST, E_KYBD_LIST_2	;AN000;       set kybd list = 2
		 GET_SCROLL	SCR_KYB_2, 1, FK_SCROLL 	;AN000;       point to 1st item in list 2
	      .ELSE  near					;AN000;    else
		 INIT_VAR	N_KYBD_LIST, E_KYBD_LIST_1	;AN000;       set kybd list = 1
		 GET_SCROLL	SCR_KYB_1, 1, FK_SCROLL 	;AN000;       point to 1st item in list 1
	      .ENDIF						;AN000;
	   .ELSE     near					;AN000; else
	      .LEAVE						;AN000;    break away from repeat loop
	   .ENDIF						;AN000;
	.UNTIL							;AN000; end of repeat block
								;
	.IF < N_USER_FUNC eq E_ENTER >	near			;AN000; if user entered ENTER key
	.THEN							;AN000;
	   COPY_WORD		I_KEYBOARD, I_USER_INDEX	;AN000;    save new kybd
	   PUSH_HEADING 	KEYBOARD_SCREEN 		;AN000;    save screen address on SELECT STACK
	   GET_KEYBOARD 	N_KYBD_LIST,I_KEYBOARD,S_KEYBOARD,N_KYBD_ALT ;AN000; get keyboard code
	   GOTO 		ALT_KYB_SCREEN			;AN000;    goto next screen (ALT_KYBD)
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ENTER or ESC, take action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �ALT_KYB_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The ALTERNATE KEYBOARD CODE screen is presented if the selected keyboard
;  has different keyboard layouts.
;  The screen allows the user to enter the desired keyboard when the
;  language supports different keyboard layouts.  The following languages
;  have different keyboard layouts:
;	 French
;	 Italian
;	 UK English
;  Valid keys are ENTER, ESC, F1, F3, cursor up/down.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ALT_KYB_SCREEN: 						;AN000;
	.IF < N_KYB_LOAD eq E_KYB_LOAD_ERR >			;AN000; if KEYB load status is error
	.THEN							;AN000;
	   POP_HEADING						;AN000;    goto previous screen
	.ENDIF							;AN000;
								;
	.IF < N_KYBD_ALT eq E_KYBD_ALT_NO >			;AN000; if no alternate keyboard
	.THEN							;AN000;
	   GOTO 		LOAD_KEYBOARD			;AN000;    goto load specified kybd id
	.ENDIF							;AN000;
								;
	GET_ALT_KYBD_TABLE	S_KEYBOARD, ALT_TAB_PTR, ALT_KYB_ID   ;AN000; get alternate keyboard id
								;
	.SELECT 						;AN000;
								;
	.WHEN < ALT_KYB_ID eq ALT_FRENCH >			;AN000; kybd id = French
	   INIT_VAR		N_WORD_1, SCR_FR_KYB		;AN000;   set scroll list id = French
								;
	.WHEN < ALT_KYB_ID eq ALT_ITALIAN >			;AN000; kybd id = Italian
	   INIT_VAR		N_WORD_1, SCR_IT_KYB		;AN000;   set scroll list id = Italian
								;
	.OTHERWISE						;AN000; kybd id = UK English
	   INIT_VAR		N_WORD_1, SCR_UK_KYB		;AN000;   set scroll list id = UK English
								;
	.ENDSELECT						;AN000;
								;
	COMP_BYTES		ALT_KYB_ID, ALT_KYB_ID_PREV	;AN000; if current alt kyb id different
	.IF nz							;AN000;
	.THEN							;AN000;
	   INIT_VAR		I_KYBD_ALT, 2			;AN090;    set index into list = 1
	   COPY_BYTE		ALT_KYB_ID_PREV, ALT_KYB_ID	;AN000;    set prev id = current id
	.ENDIF							;AN000;
								;
	INIT_PQUEUE		PAN_KYBD_ALT			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		N_WORD_1, 0			;AN000; init scroll list
	DISPLAY_PANEL						;AN000; display ALTERNATE keyboard panel
								;
	GET_SCROLL		N_WORD_1, I_KYBD_ALT, FK_SCROLL ;AN000; get new alt kyb id
								;
	.IF < N_USER_FUNC eq  E_ENTER > 			;AN000; if user entered ENTER key
	.THEN							;AN000;
	   COPY_WORD		I_KYBD_ALT, I_USER_INDEX	;AN000;    save new alternate keyboard
	   PUSH_HEADING 	ALT_KYB_SCREEN			;AN000;    push screen address on SELECT STACK
	   GET_ALT_KEYBOARD	ALT_TAB_PTR,ALT_KYB_ID,I_KYBD_ALT,S_KYBD_ALT ;AN000;get alternate keyboard code
	   GOTO 		LOAD_KEYBOARD			;AN000;    goto load specified kybd id
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ESC or F3, take action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   � � � � � � � � � � � � � � � � � � �
;  � LOAD_KEYBOARD			 �
;
;  �	This will execute the keyboard	 �
;	program to load the requested
;  �	keyboard routine.		 �
;   � � � � � � � � � � � � � � � � � � �
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOAD_KEYBOARD:							;AN000;
	.IF < N_KYBD_LIST eq E_KYBD_LIST_2 > and		;AN000; if kybd is none
	.IF < I_KEYBOARD eq KYBD_B_ITEMS >			;AN000;
	.THEN							;AN000;
	   INIT_VAR		N_KYBD_VAL, E_KYBD_VAL_DEF	;AN000;    set kybd id = default id
	.ENDIF							;AN000;
								;
	.IF < N_KYBD_VAL eq E_KYBD_VAL_YES > near		;AN000; if kybd id is valid
	.THEN							;AN000;
	   .IF < N_KYBD_ALT eq E_KYBD_ALT_NO >			;AN000;    if alt kybd not valid
	   .THEN						;AN000;
	      COPY_STRING	S_STR120_1,M_STR120_1,S_KEYBOARD;AN000;       set par = kybd id
	   .ELSE						;AN000;    else
	      COPY_STRING	S_STR120_1,M_STR120_1,S_KYBD_ALT;AN000;       set par = alt kybd id
	   .ENDIF						;AN000;
	   INIT_VAR		N_WORD_1, E_KYB_LOAD_SUC	;AN000;
	.ELSE							;AN000;
	   COPY_STRING		S_STR120_1,M_STR120_1,S_US	;AN000;
	   INIT_VAR		N_WORD_1, E_KYB_LOAD_US 	;AN000;
	.ENDIF							;AN000;
								;
	.IF < N_KYB_LOAD eq E_KYB_LOAD_US > and 		;AN000;
	.IF < N_WORD_1 eq E_KYB_LOAD_US >			;AN000;
	.THEN							;AN000;
	.ELSE near						;AN000;
								;
	   .IF < MEM_SIZE eq 256 >				;AN000;DT this includes support for PC Convertible  (SEH)
	      DEALLOCATE_MEMORY 				;AN000;DT
	   .ENDIF						;AN000;DT
								;
	   CALL HOOK_INT_24					;AN000;
	   EXEC_PROGRAM 	S_KEYB,S_STR120_1,PARM_BLOCK,EXEC_DIR ;AN000;  load specified kybd id
	   .IF < MEM_SIZE eq 256 >				;AN063;SEH
	       CALL GET_OVERLAY 				;AN063;SEH
	   .ENDIF						;AN063;SEH
	   .IF < EXEC_ERR eq TRUE >				;AC063;SEH ;AN000;
	   .THEN						;AN000;
	      HANDLE_ERROR	ERR_KEYB,E_RETURN		;AN000;
	      INIT_VAR		N_KYB_LOAD, E_KYB_LOAD_ERR	;AN000;
	      POP_HEADING					;AN000;
	   .ENDIF						;AN000;
	   CALL RESTORE_INT_24					;AN000;
	   COPY_WORD		N_KYB_LOAD, N_WORD_1		;AN000;
								;
	   .IF < MEM_SIZE eq 256 > and				;AC063;SEH ;AN000;DT
	   .IF < N_DISKETTE_A ne E_DISKETTE_720 >		;AN063;SEH
	      INSERT_DISK	SUB_REM_DOS_A, S_DOS_COM_360	;AN000;JW Insert the INSTALL diskette
	   .ENDIF						;AN000;DT
								;
	.ENDIF							;AN000;
								;
	.IF < N_KYBD_LIST eq E_KYBD_LIST_2 > and		;AN000; if kybd is US ENGLISH	       JW
	.IF < I_KEYBOARD eq 8 > 				;AN000; 			       JW
	.THEN							;AN000; 			       JW
	   INIT_VAR		N_KYBD_VAL, E_KYBD_VAL_YES	;AN000;    set kybd id = US KEYBOARD   JW
	.ENDIF							;AN000; 			       JW
								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �DEST_DRIVE_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The DESTINATION DRIVE screen is presented when there is an option for
;  the destination drive. Possible options are:
;		B or C
;		A or C
;  Valid keys are ENTER, ESC, F1, F3, cursor up/down, numeric 1 to 2.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEST_DRIVE_SCREEN:						;AN000;
	.IF < N_DEST_DRIVE eq E_DEST_SELECT >			;AN000; if default destination drive
	.THEN							;AN000;
	   GOTO 		DOS_LOC_SCREEN			;AN000;    goto next screen (DOS_LOC)
	.ENDIF							;AN000;
								;
	.IF < N_DRIVE_OPTION eq E_OPTION_B_C >			;AN111;JW
	   INIT_VAR		N_WORD_1, SCR_DEST_B_C		;AN111;JW
	.ELSE							;AN111;JW
	   INIT_VAR		N_WORD_1, SCR_DEST_A_C		;AN111;JW
	.ENDIF							;AN111;JW
								;
	INIT_PQUEUE		PAN_DEST_DRIVE			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		N_WORD_1, I_DEST_DRIVE		;AN000; init scroll list
	DISPLAY_PANEL						;AN000; display DEST_DRIVE panel
								;
	GET_SCROLL		N_WORD_1,I_DEST_DRIVE,FK_SCROLL ;AN000; get new install destination
								;
	.IF < N_USER_FUNC eq E_ENTER >				;AN000; if user entered ENTER key
	.THEN							;AN000;
	   .IF < N_DRIVE_OPTION eq E_OPTION_A_C > and		;AN111;JW
	   .IF < I_USER_INDEX eq 2 >				;AN111;JW
	      INIT_VAR		   I_DEST_DRIVE, E_DEST_DRIVE_A ;AN111;JW
	   .ELSE						;AN111;JW
	      COPY_WORD 	   I_DEST_DRIVE, I_USER_INDEX	;AN000;    save new install destination drive
	   .ENDIF						;AN111;JW
	   PUSH_HEADING 	DEST_DRIVE_SCREEN		;AN000;    save screen address on the SELECT STACK
	   GOTO 		DOS_LOC_SCREEN			;AN000;    goto the next screen (DOS_LOC)
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ESC OR F3, take action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	ENDS							;AN000;
	END							;AN000;
