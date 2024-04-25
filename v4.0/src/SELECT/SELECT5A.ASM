

PAGE 55,132							;AN000;
NAME	SELECT							;AN000;
TITLE	SELECT - DOS - SELECT.EXE				;AN000;
SUBTTL	SELECT5A.asm						;AN000;
.ALPHA								;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SELECT5A.ASM : Copyright 1988 Microsoft
;
;	DATE:	 August 8/87
;
;	COMMENTS: Assemble with MASM 3.0 (using the /A option)
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
;  Module contains code for :
;	- Date/Time screen
;
;	CHANGE HISTORY:
;
;		;AN002;  for DCR225
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	SEGMENT BYTE PUBLIC 'DATA'                              ;AN000;
	EXTRN	SEL_FLG:BYTE					;AN000;
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	SEGMENT PARA PUBLIC 'SELECT'                            ;AN000;segment for far routine
	ASSUME	CS:SELECT,DS:DATA				;AN000;
								;
	INCLUDE CASEXTRN.INC					;AN000;
								;
	EXTRN	CREATE_AUTOEXEC_BAT:NEAR			;AN000;
	EXTRN	CREATE_CONFIG_SYS:NEAR				;AN000;
	EXTRN	CREATE_SHELL_BAT:NEAR				;AN000;DT
	EXTRN	SCAN_INFO_CALL:NEAR				;AN000;DT
								;
	PUBLIC	DATE_TIME_SCREEN				;AN000;
	EXTRN	PROCESS_ESC_F3:near				;AN000;
	EXTRN	FORMAT_DISK_SCREEN:near 			;AN000;
	EXTRN	EXIT_DOS:near					;AN000;
	EXTRN	INSTALL_ERROR:near				;AN000;
	EXTRN	EXIT_SELECT:NEAR				;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �DATE_TIME_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The INSTALL DATE and TIME SCREEN is presented if the active date is 1/1/80.
;  If the user is installing to drive C: , this is the first screen presented
;  after the system is reboot due to the execution of FDISK.
;  The user cannot go back to the previous screen or terminate the
;  install process from this screen.
;  If the user did not change the date or time presented on the screen,
;  no action is taken.
;  Valid keys are ENTER, F1, and numeric characters.
;  If installing from 360KB diskettes, must prompt for INSTALL diskette
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATE_TIME_SCREEN:						;AN000;
								;
	.IF < N_SELECT_MODE eq E_SELECT_FDISK > and		;AN000;DT
	.IF < N_DISKETTE_A eq E_DISKETTE_360 >			;AN000;DT
	   CALL 		CURSOROFF			;AN082;SEH
	   INSERT_DISK		SUB_INSTALL_COPY, S_SELECT_TMP	;AN000;JW
	   CALL 		SCAN_INFO_CALL			;AN000;DT
	.ENDIF							;AN000;DT
								;
	INIT_VAR		STACK_INDEX, 0			;AN000; clear SELECT STACK
								;
	CHECK_WRITE_PROTECT	DRIVE_A, N_RETCODE		;AC000;JW
	.IF c							;AN000;
	   GOTO 		INSTALL_ERROR			;AN000;
	.ELSE							;AN000;
	   OR  SEL_FLG,INSTALLRW				;AN000; indicate INSTALL diskette is R/W
	.ENDIF							;AN000;
								;
	GET_DATE		N_YEAR, N_MONTH, N_DAY		;AN000; get system date
	.IF c							;AN000; if system date is 1/1/1980
	   GOTO 		FORMAT_DISK_SCREEN		;AN000;    goto next screen (FORMAT_DISK)
	.ENDIF							;AN000;
								;
	GET_TIME		N_HOUR, N_MINUTE, N_SECOND	;AN000; get system time
								;
	COPY_WORD		N_WORD_1, N_YEAR		;AN000; copy year to temp var
	COPY_WORD		N_WORD_2, N_MONTH		;AN000; copy month to temp var
	COPY_WORD		N_WORD_3, N_DAY 		;AN000; copy day to temp var
	COPY_WORD		N_WORD_4, N_HOUR		;AN000; copy hour to temp var
	COPY_WORD		N_WORD_5, N_MINUTE		;AN000; copy minute to temp var
	COPY_WORD		N_WORD_6, N_SECOND		;AN000; copy second to temp var
								;
	INIT_PQUEUE		PAN_DATE_TIME			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_NUMERIC		NUM_YEAR,N_WORD_1,MAX_YEAR,S_STR120_1 ;AN000; display current year
	INIT_NUMERIC		NUM_MONTH,N_WORD_2,MAX_MONTH,S_STR120_2     ;AN000; display current month
	INIT_NUMERIC		NUM_DAY,N_WORD_3,MAX_DAY,S_STR120_3   ;AN000; display current day
	INIT_NUMERIC		NUM_HOUR,N_WORD_4,MAX_HOUR,SC_LINE    ;AN000; display current hour
	INIT_NUMERIC		NUM_MINUTE,N_WORD_5,MAX_MINUTE,S_MODE_PARM  ;AN000; display current minute
	INIT_NUMERIC		NUM_SECOND,N_WORD_6,MAX_SECOND,S_CP_DRIVER  ;AN000; display current second
	CALL			CURSORON			;AN082;SEH
	DISPLAY_PANEL						;AN000;
								;
	INIT_VAR		N_COUNTER, 1			;AN000; set counter = 1
								;
DATE_TIME_LOOP: 						;AN000;
								;
	.REPEAT 						;AN000; repeat code block
								;
	   .SELECT						;AN000;
								;
	   .WHEN < N_COUNTER eq 1 >				;AN000;    counter = 1
	      GET_NUMERIC	NUM_YEAR,N_WORD_1,MIN_YEAR,MAX_YEAR,FK_DATE,S_STR120_1	      ;AN000; get new year value
	      COPY_WORD 	N_WORD_1, N_USER_NUMERIC	;AN000;    save new year value
								;
	   .WHEN < N_COUNTER eq 2 >				;AN000;    counter = 2
	      GET_NUMERIC	NUM_MONTH,N_WORD_2,MIN_MONTH,MAX_MONTH,FK_DATE,S_STR120_2     ;AN000; get new month value
	      COPY_WORD 	N_WORD_2, N_USER_NUMERIC	;AN000;    save new month value
								;
	   .WHEN < N_COUNTER eq 3 >				;AN000;    counter = 3
	      GET_NUMERIC	NUM_DAY,N_WORD_3,MIN_DAY,MAX_DAY,FK_DATE,S_STR120_3	      ;AN000; get new day value
	      COPY_WORD 	N_WORD_3, N_USER_NUMERIC	;AN000;    save new day value
								;
	   .WHEN < N_COUNTER eq 4 >				;AN000;    counter = 4
	      GET_NUMERIC	NUM_HOUR,N_WORD_4,MIN_HOUR,MAX_HOUR,FK_DATE,SC_LINE	      ;AN000; get new hour value
	      COPY_WORD 	N_WORD_4, N_USER_NUMERIC	;AN000;    save new hour value
								;
	   .WHEN < N_COUNTER eq 5 >				;AN000;    counter = 5
	      GET_NUMERIC	NUM_MINUTE,N_WORD_5,MIN_MINUTE,MAX_MINUTE,FK_DATE,S_MODE_PARM ;AN000; get new minute value
	      COPY_WORD 	N_WORD_5, N_USER_NUMERIC	;AN000;    save new minute value
								;
	   .OTHERWISE						;AN000;    counter = 6
	      GET_NUMERIC	NUM_SECOND,N_WORD_6,MIN_SECOND,MAX_SECOND,FK_DATE,S_CP_DRIVER ;AN000; get new second value
	      COPY_WORD 	N_WORD_6, N_USER_NUMERIC	;AN000;    save new second value
								;
	   .ENDSELECT						;AN000;
								;
	   INC_VAR		N_COUNTER			;AN000;    inc counter
								;
	   .IF < N_COUNTER a 6 >				;AN000;    if counter > 6
	      INIT_VAR		N_COUNTER, 1			;AN000;       set counter = 1
	   .ENDIF						;AN000;
								;
	.UNTIL < N_USER_FUNC eq E_ENTER > near			;AN000; break loop if user entered ENTER
								;
	CHECK_DATE_CHANGE	N_WORD_1,N_WORD_2,N_WORD_3,N_YEAR,N_MONTH,N_DAY     ;AN000; check if new date is different
	.IF c							;AN000; if new date different
	   SET_DATE		N_WORD_1, N_WORD_2, N_WORD_3	;AN000;    set new system date
	   .IF c						;AN000;    if new date invalid
	      INIT_VAR		N_COUNTER, 3			;AN000;       set counter = 3
	      GOTO		DATE_TIME_LOOP			;AN000;       goto get day again
	   .ENDIF						;AN000;
	.ENDIF							;AN000;
								;
	CHECK_TIME_CHANGE	N_WORD_4,N_WORD_5,N_WORD_6,N_HOUR,N_MINUTE,N_SECOND ;AN000; check if new time is different
	.IF c							;AN000; if new time is different
	   SET_TIME		N_WORD_4, N_WORD_5, N_WORD_6	;AN000;    set new system time
	.ENDIF							;AN000;
								;
	GOTO			FORMAT_DISK_SCREEN		;AN000; goto next screen (FORMAT_DISK)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	ENDS							;AN000;
	END							;AN000;
