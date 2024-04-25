

PAGE 60,132							;AN000;
NAME	SELECT							;AN000;
TITLE	SELECT - DOS - SELECT.EXE				;AN000;
SUBTTL	SELECT3.asm						;AN000;
.ALPHA								;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SELECT3.ASM : Copyright 1988 Microsoft
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
;  The following screens are contained in this module:
;	- External diskette parameters
;	- Review selection choice
;	- Review selections for fixed disk
;	- Review selections for diskette
;
;
;	;AN001;  GHG changes for 0 Parallel/Serial printer ports
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	SEGMENT BYTE PUBLIC 'DATA'                              ;AN000; Dummy DATA Seg
	EXTRN	 SEG_LOC:WORD					;AN000;
	EXTRN	 NAMES_OFF:WORD 				;AN000;
	EXTRN	 N_PRN_NAMES:WORD				;AN000;
	EXTRN	 MAX_NAME:WORD					;AN000;
	EXTRN	 SIZE_NAMES:ABS 				;AN000;
DATA	ENDS							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Continuation of code ...
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	SEGMENT PARA PUBLIC 'SELECT'                            ;AN000;
	ASSUME	CS:SELECT,DS:DATA				;AN000;
								;
	INCLUDE CASEXTRN.INC					;AN000;
								;
	EXTRN	EXIT_SELECT:NEAR				;AN000;
	EXTRN	INSTALL_ERROR:NEAR				;AN000;
	EXTRN	PROCESS_ESC_F3:NEAR				;AN000;
	EXTRN	DOS_PARAMETERS_SCREEN:NEAR			;AN000;
	EXTRN	EXIT_DOS:NEAR					;AN000;
	EXTRN	FIRST_DISK_SCREEN:NEAR				;AN000;
	PUBLIC	choose_shell_screen	 			;AC020; SEH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �choose_shell_screen			�
;  �					�
;  ��������������������������������������
;
;  The CHOOSE SHELL SCREEN is always presented.
;  This screen allows the user to decide whether or not the DOS 
;  shell will be installed.
;  Valid keys are ENTER, ESC, F1, F3 and numeric 1 and 2.
;----
; Note:  This screen (and, hence, all shell support) can be eradicated
;	by defining the symbol NOSHELL.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
choose_shell_screen:						;AN000;
IFNDEF NOSHELL
	INIT_PQUEUE		PAN_choose_shell		;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		SCR_choose_shell, f_shell	;AN000;
	DISPLAY_PANEL						;AN000; display CHOOSE SHELL SCREEN
								;
	GET_SCROLL		SCR_choose_shell, f_shell, FK_SCROLL ;AN000; get new shell option
								;
	.IF < N_USER_FUNC eq E_ENTER >				;AN000; if user entered ENTER key
	.THEN							;AN000;
	   COPY_WORD		f_shell, I_USER_INDEX		;AN000;    save new shell option
	   PUSH_HEADING 	choose_shell_screen		;AN000;    save address on SELECT STACK
	   GOTO 		REVIEW_SELECTION_SCREEN		;AN000;    goto the next screen (REVIEW_SELECTION)
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ESC or F3, take action
	.ENDIF							;AN000;
ENDIF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �REVIEW_SELECTION_SCREEN		�
;  �					�
;  ��������������������������������������
;
;  The REVIEW SELECTION SCREEN is always presented.
;  The screen asks the user if SELECT generated choices are to be presented.
;  Valid keys are ENTER, ESC, F1, F3 and numeric 1 and 2.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
REVIEW_SELECTION_SCREEN:					;AN000;
	INIT_PQUEUE		PAN_REVIEW			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		SCR_REVIEW, F_REVIEW		;AN000;
	DISPLAY_PANEL						;AN000; display REVIEW SELECTION SCREEN
								;
	GET_SCROLL		SCR_REVIEW, F_REVIEW, FK_SCROLL ;AN000; get new review option
								;
	.IF < N_USER_FUNC eq E_ENTER >				;AN000; if user entered ENTER key
	.THEN							;AN000;
	   COPY_WORD		F_REVIEW, I_USER_INDEX		;AN000;    save new review option
	   PUSH_HEADING 	REVIEW_SELECTION_SCREEN 	;AN000;    save address on SELECT STACK
	   GOTO 		REVIEW_DISK_SCREEN		;AN000;    goto the next screen (REVIEW_FUNCTIONS)
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ESC or F3, take action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �REVIEW_DISK_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The REVIEW SELECT DOS FUNCTIONS SELECTION SCREEN is presented if
;  the user selected to view/change the selections generated by
;  SELECT ( F_REVIEW = 2 )
;  The screen asks the user to select functions required from the
;  displayed list.  Functions are Code Page Switching, Expanded Memory Support,
;  ANSI.SYS support, FASTOPEN support, GRAFTABL support, GRAPHICS support,
;  SHARE support, and VDISK support.
;  There are two versions of this screen.  The screen version displayed
;  will depend on whether the install destination is drive B:/A: or drive C:.
;  This screen version will be presented if install destination is drive C:.
;  The screen lists the parameters for which selections have been made by
;  SELECT.  The user may accept these choices (yes/no)
;  or change them by cursoring to the parameter and pressing the SPACE key.
;  The SPACE key will toggle the choice for the selected parameter.
;  The cursor key is used to move to the next item on the parameter list.
;  If the cursor is on the last item in the parameter list, cursor down key
;  will cause the cursor to wrap around to the first item of the parameter list.
;  If the cursor is on the first item in the parameter list, cursor up key
;  will cause the cursor to wrap around to the last item of the parameter list.
;  When the SPACE key is depressed, the current parameter value is saved in
;  a temporary location.  The temporary parameter values are copied to actual
;  values only when the ENTER key is depressed.
;  Valid keys are ENTER, ESC, F1, F3, SPACE, cursor up and cursor down.
;  If a parameter is not supported due to the hardware environment, the
;  choice presented to the user will be NO but internally will be stored as N/A.
;  a N/A choice would not be toggled by the user and a beep would be issued
;  instead.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
REVIEW_DISK_SCREEN:						;AN000;
	.IF < F_REVIEW eq E_REVIEW_ACCEPT >			;AN000; if accept SELECT generated commands
	.THEN							;AN000;
	   GOTO 		FIRST_DISK_SCREEN		;AN000;    skip related screens
	.ENDIF							;AN000;
								;
	.IF < I_DEST_DRIVE ne E_DEST_DRIVE_C >			;AC000; if install to drive B: or A: JW
	.THEN							;AN000;
	   GOTO 		REVIEW_DISKETTE_SCREEN		;AN000;    goto disket functions screen
	.ENDIF							;AN000;
								;
	INIT_PQUEUE		PAN_FUNC_DISK			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		SCR_FUNC_DISK, 0		;AN000;
	INIT_SUPPORT		SUPPORT_STATUS,E_CPSW_C, F_CPSW ;AN000;    cpsw support
	INIT_SUPPORT		SUPPORT_STATUS, E_XMA_C, F_XMA	;AN000;    expanded memory support
	INIT_SUPPORT		SUPPORT_STATUS,E_ANSI_C, F_ANSI ;AN000;    ANSI.SYS support
	INIT_SUPPORT		SUPPORT_STATUS,E_FASTOPEN_C,F_FASTOPEN;AN000; FASTOPEN support
	INIT_SUPPORT		SUPPORT_STATUS,E_GRAFTABL_C,F_GRAFTABL;AN000; GRAFTABL support
	INIT_SUPPORT		SUPPORT_STATUS,E_GRAPHICS_C,F_GRAPHICS;AN000; GRAPHICS support
	INIT_SUPPORT		SUPPORT_STATUS,E_SHARE_C,F_SHARE;AN000;   SHARE support
	INIT_SUPPORT		SUPPORT_STATUS,E_SHELL_C,F_SHELL;AN000;   SHELL support
	INIT_SUPPORT		SUPPORT_STATUS,E_VDISK_C,F_VDISK;AN000;   VDISK support
	INIT_SCROLL_STATUS	SCR_FUNC_DISK,SUPPORT_STATUS	;AN000;
	DISPLAY_PANEL						;AN000; display functions list screen
								;
	INIT_VAR		I_USER_INDEX, 1 		;AN000; set counter = 1
								;
	.REPEAT 						;AN000; repeat code block
								;
	   GET_SCROLL		SCR_FUNC_DISK,I_USER_INDEX,FK_REVIEW  ;AN000; get new value
								;
	   .IF < N_USER_FUNC eq E_SPACE >			;AN000;    if user entered TAB
	   .THEN						;AN000;
	      TOGGLE_SUPPORT	SUPPORT_STATUS, I_USER_INDEX	;AN000;       toggle support of parameter
	   .ELSE						;AN000;    else
	      .LEAVE						;AN000;        break from repeat loop
	   .ENDIF						;AN000;
								;
	.UNTIL							;AN000; end of repeat loop
								;
	.IF < N_USER_FUNC eq E_ENTER > near			;AN000; if user entered ENTER key
	.THEN							;AN000;    get revised values for
	   RET_SUPPORT		SUPPORT_STATUS,E_CPSW_C, F_CPSW ;AN000;       cpsw support
	   RET_SUPPORT		SUPPORT_STATUS, E_XMA_C, F_XMA	;AN000;       expanded memory support
	   RET_SUPPORT		SUPPORT_STATUS,E_ANSI_C, F_ANSI ;AN000;       ANSI.SYS support
	   RET_SUPPORT		SUPPORT_STATUS,E_FASTOPEN_C,F_FASTOPEN;AN000; FASTOPEN support
	   RET_SUPPORT		SUPPORT_STATUS,E_GRAFTABL_C,F_GRAFTABL;AN000; GRAFTABL support
	   RET_SUPPORT		SUPPORT_STATUS,E_GRAPHICS_C,F_GRAPHICS;AN000; GRAPHICS support
	   RET_SUPPORT		SUPPORT_STATUS,E_SHARE_C,F_SHARE;AN000;      SHARE support
	   RET_SUPPORT		SUPPORT_STATUS,E_SHELL_C,F_SHELL;AN000;      SHELL support
	   RET_SUPPORT		SUPPORT_STATUS,E_VDISK_C,F_VDISK;AN000;      VDISK support
	   PUSH_HEADING 	REVIEW_DISK_SCREEN		;AN000;    save screen address on SELECT STACK
	   GOTO 		DOS_PARAMETERS_SCREEN		;AN000;    goto the next screen (DOS_PARAMETERS)
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ESCAPE or F3, take action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �REVIEW_DISKETTE_SCREEN		�
;  �					�
;  ��������������������������������������
;
;  The REVIEW SELECT DOS FUNCTIONS SELECTION SCREEN is presented if
;  the user selected to view/change the selections generated by
;  SELECT ( F_REVIEW = 2 )
;  This screen version will be presented if install destination is drive A:/B:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
REVIEW_DISKETTE_SCREEN: 					;AN000;
	INIT_PQUEUE		PAN_FUNC_DISKET 		;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		SCR_FUNC_DISKET, 0		;AN000;
	INIT_SUPPORT		SUPPORT_STATUS,E_CPSW_B, F_CPSW ;AN000;    cpsw support
	INIT_SUPPORT		SUPPORT_STATUS,E_ANSI_B, F_ANSI ;AN000;    ANSI.SYS support
	INIT_SUPPORT		SUPPORT_STATUS,E_GRAFTABL_B,F_GRAFTABL;AN000; GRAFTABL support
	INIT_SUPPORT		SUPPORT_STATUS,E_GRAPHICS_B,F_GRAPHICS;AN000; GRAPHICS support
	INIT_SUPPORT		SUPPORT_STATUS,E_SHELL_B,F_SHELL;AN000;   SHELL support
	INIT_SUPPORT		SUPPORT_STATUS,E_VDISK_B,F_VDISK;AN000;   VDISK support
	INIT_SCROLL_STATUS	SCR_FUNC_DISKET, SUPPORT_STATUS ;AN000;
	DISPLAY_PANEL						;AN000; display functions list screen
								;
	INIT_VAR		I_USER_INDEX, 1 		;AN000; set counter = 1
								;
	.REPEAT 						;AN000; repeat code block
								;
	   GET_SCROLL		SCR_FUNC_DISKET,I_USER_INDEX,FK_REVIEW;AN000; get new value
								;
	   .IF < N_USER_FUNC eq E_SPACE >			;AN000;    if user entered TAB
	   .THEN						;AN000;
	      TOGGLE_SUPPORT	SUPPORT_STATUS, I_USER_INDEX	;AN000;       toggle support of parameter
	   .ELSE						;AN000;
	      .LEAVE						;AN000;    else
	   .ENDIF						;AN000;        break from loop
								;
	.UNTIL							;AN000; end of repeat block
								;
	.IF < N_USER_FUNC eq E_ENTER > near			;AN000; if user entered ENTER key
	.THEN							;AN000;    get revised values
	   RET_SUPPORT		SUPPORT_STATUS,E_CPSW_B, F_CPSW ;AN000;       cpsw support
	   RET_SUPPORT		SUPPORT_STATUS,E_ANSI_B, F_ANSI ;AN000;       ANSI.SYS support
	   RET_SUPPORT		SUPPORT_STATUS,E_GRAFTABL_B,F_GRAFTABL;AN000; GRAFTABL support
	   RET_SUPPORT		SUPPORT_STATUS,E_GRAPHICS_B,F_GRAPHICS;AN000; GRAPHICS support
	   RET_SUPPORT		SUPPORT_STATUS,E_SHELL_B,F_SHELL;AN000;      SHELL support
	   RET_SUPPORT		SUPPORT_STATUS,E_VDISK_B,F_VDISK;AN000;      VDISK support
	   PUSH_HEADING 	REVIEW_DISKETTE_SCREEN		;AN000; save screen address onto SELECT STACK
	   GOTO 		DOS_PARAMETERS_SCREEN		;AN000; goto the next screen (DOS_PARAMETERS)
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ESC or E3, take action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	ENDS							;AN000;
	END							;AN000;
