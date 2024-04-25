

PAGE 55,132							;AN000;
NAME	SELECT							;AN000;
TITLE	SELECT - DOS - SELECT.EXE				;AN000;
SUBTTL	SELECT5.asm						;AN000;
.ALPHA								;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SELECT5.ASM : Copyright 1988 Microsoft
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
;	- VDISK screen
;	- CONFIG.SYS screen
;	- Fixed disk partition screen
;	- Date/Time screen
;
;	CHANGE HISTORY:
;
;		;AN002;  for DCR225 by G.G.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	SEGMENT BYTE PUBLIC 'DATA'                              ;AN000;
	EXTRN	SEL_FLG:BYTE					;AN000;
	EXTRN	EXEC_DEALLOC:BYTE				;AN000;
	EXTRN	EXEC_FDISK:BYTE 				;AN000;DT
	EXTRN	EXEC_ERR:BYTE					;AN000;DT
	EXTRN	BCHAR:BYTE					;AN000;DT
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
								;
	EXTRN	DEALLOCATE_HELP:FAR				;AN000;DT
	EXTRN	ALLOCATE_HELP:FAR				;AN000;DT
	EXTRN	DEALLOCATE_BLOCK:FAR				;AN000;DT
	EXTRN	ALLOCATE_BLOCK:FAR				;AN000;DT
	EXTRN	DEALLOCATE_MEMORY_CALL:FAR			;AN000;DT
	EXTRN	ALLOCATE_MEMORY_CALL:FAR			;AN000;DT
	EXTRN	PM_BASECHAR:BYTE				;AN000;
	EXTRN	PM_BASEATTR:BYTE				;AN000;
	EXTRN	CRD_CCBVECOFF:WORD				;AN000;
	EXTRN	CRD_CCBVECSEG:WORD				;AN000;
								;
								;
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
	EXTRN	DATE_TIME_SCREEN:NEAR				;AN000;DT
								;
	PUBLIC	FIRST_DISK_SCREEN				;AN000;
	PUBLIC	VDISK_SCREEN					;AN000;
	EXTRN	PROCESS_ESC_F3:near				;AN000;
	EXTRN	FORMAT_DISK_SCREEN:near 			;AN000;
	EXTRN	EXIT_DOS:near					;AN000;
	EXTRN	INSTALL_ERROR:near				;AN000;
	EXTRN	EXIT_SELECT:NEAR				;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �VDISK_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The VDISK PARAMETERS SCREEN is presented if the user selected to
;  install virtual disk support and the user wants to view/change parameters.
;  Note.The view/change parameters condition is not specified in the May 5, 1987
;  Functional Specification.
;  The screen gets parameters for the VDISK command.
;  Valid keys are ENTER, ESC, F1, F3 and ASCII characters.
;  Note.User entered parameter values are not checked for validity.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VDISK_SCREEN:							;AN000;
	.IF < F_VDISK eq E_VDISK_NO >				;AN000; if VDISK support not required
	   GOTO 		CONFIG_SYS_SCREEN		;AN000;    goto the next screen (CONFIG.SYS)
	.ENDIF							;AN000;
								;
	INIT_PQUEUE		PAN_VDISK			;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_STRING		STR_VDISK,S_VDISK,M_VDISK	;AN000; get new parameters for VDISK
	DISPLAY_PANEL						;AN000; display VDISK panel
								;
	GET_STRING		STR_VDISK,S_VDISK,M_VDISK,FK_TEXT     ;AN000; get new parameters for VDISK
								;
	.IF < N_USER_FUNC eq E_ENTER >				;AN000; if user entered ENTER key
	   COPY_STRING		S_VDISK, M_VDISK, S_USER_STRING ;AN000;    save new parameters for VDISK
	   PUSH_HEADING 	VDISK_SCREEN			;AN000;    save screen address on SELECT STACK
	   GOTO 		CONFIG_SYS_SCREEN		;AN000;    goto the next screen (CONFIG.SYS)
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ESC or F3, take action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �CONFIG_SYS_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The CONFIG.SYS PARAMETERS SCREEN is presented if the user selected to
;  view/change SELECT generated commands ( F_REVIEW = 2 ).
;  The screen gets parameters for CONFIG.SYS commands ( BREAK, BUFFERS,
;  FCBS, FILES, LASTDRIVE, STACKS, VERIFY ).
;  The TAB key is used to move to the next item on the parameter list.
;  If the cursor is on the last item in the parameter list, TAB key
;  will cause the cursor to wrap around to the first item of the parameter list.
;  When the TAB key is depressed, the current parameter value is saved in
;  a temporary location.  The temporary parameter values are copied to actual
;  values only when the ENTER key is depressed.
;  Valid keys are ENTER, ESC, F1, F3, TAB and ASCII characters.
;  Note.User entered parameter values are not checked for validity.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CONFIG_SYS_SCREEN:						;AN000;
	COPY_STRING		ST_BREAK, MT_BREAK, S_BREAK	;AN000; copy BREAK par to temp location
	COPY_STRING		ST_BUFFERS,MT_BUFFERS,S_BUFFERS ;AN000; copy BUFFERS par to temp location
	COPY_STRING		ST_FCBS, MT_FCBS, S_FCBS	;AN000; copy FCBS par to temp location
	COPY_STRING		ST_FILES, MT_FILES, S_FILES	;AN000; copy FILES par to temp location
	COPY_STRING		ST_LASTDRIVE,MT_LASTDRIVE,S_LASTDRIVE ;AN000; copy LASTDRIVE par to temp location
	COPY_STRING		ST_STACKS, MT_STACKS, S_STACKS	;AN000; copy STACKS par to temp location
	COPY_STRING		ST_VERIFY, MT_VERIFY, S_VERIFY	;AN000; copy VERIFY par to temp location
								;
	INIT_PQUEUE		PAN_CONFIG_PARS 		;AN000; initialize queue
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_STRING		STR_BREAK, ST_BREAK, MT_BREAK	;AN000; display BREAK parameters
	INIT_STRING		STR_BUFFERS,ST_BUFFERS,MT_BUFFERS     ;AN000; display BUFFERS parameters
	INIT_STRING		STR_FCBS, ST_FCBS, MT_FCBS	;AN000; display FCBS parameters
	INIT_STRING		STR_FILES, ST_FILES, MT_FILES	;AN000; display FILES parameters
	INIT_STRING		STR_LASTDRIVE,ST_LASTDRIVE,MT_LASTDRIVE      ;AN000; display LASTDRIVE parameters
	INIT_STRING		STR_STACKS,ST_STACKS, MT_STACKS ;AN000; display STACKS parameters
	INIT_STRING		STR_VERIFY,ST_VERIFY, MT_VERIFY ;AN000; display VERIFY parameters
	DISPLAY_PANEL						;AN000; display CONFIG.SYS parameters panel
								;
	INIT_VAR		N_COUNTER, 1			;AN000;
								;
	.REPEAT 						;AN000; repeat code block
								;
	   .SELECT						;AN000;
								;
	   .WHEN < N_COUNTER eq 1 >				;AN000;
	      GET_STRING	STR_BREAK,ST_BREAK,MT_BREAK,FK_TAB    ;AN000; get new parameter for BREAK
	      COPY_STRING	ST_BREAK,MT_BREAK,S_USER_STRING ;AN000;    save new BREAK parameter
								;
	   .WHEN < N_COUNTER eq 2 >				;AN000;
	      GET_STRING	STR_BUFFERS,ST_BUFFERS,MT_BUFFERS,FK_TAB    ;AN000; get new parameter for BUFFERS
	      COPY_STRING	ST_BUFFERS,MT_BUFFERS,S_USER_STRING   ;AN000; save new BUFFERS parameter
								;
	   .WHEN < N_COUNTER eq 3 >				;AC000;JW
	      GET_STRING	STR_FCBS,ST_FCBS,MT_FCBS,FK_TAB ;AN000;    get new parameter for FCBS
	      COPY_STRING	ST_FCBS, MT_FCBS, S_USER_STRING ;AN000;    save new FCBS parameter
								;
	   .WHEN < N_COUNTER eq 4 >				;AC000;JW;
	      GET_STRING	STR_FILES,ST_FILES,MT_FILES,FK_TAB    ;AN000; get new parameter for FILES
	      COPY_STRING	ST_FILES,MT_FILES,S_USER_STRING ;AN000;  save new FILES parameter
								;
	   .WHEN < N_COUNTER eq 5 >				;AC000;JW;
	      GET_STRING	STR_LASTDRIVE,ST_LASTDRIVE,MT_LASTDRIVE, FK_TAB ;AN000; get new parameter for LASTDRIVE
	      COPY_STRING	ST_LASTDRIVE,MT_LASTDRIVE,S_USER_STRING 	;AN000;save new LASTDRIVE parameter
								;
	   .WHEN < N_COUNTER eq 6 >				;AC000;JW;
	      GET_STRING	STR_STACKS,ST_STACKS,MT_STACKS,FK_TAB ;AN000;get new parameter for STACKS
	      COPY_STRING	ST_STACKS,MT_STACKS,S_USER_STRING     ;AN000;  save new STACKS parameter
								;
	   .OTHERWISE						;AN000;
	      GET_STRING	STR_VERIFY,ST_VERIFY,MT_VERIFY,FK_TAB ;AN000;get new parameter for VERIFY
	      COPY_STRING	ST_VERIFY,MT_VERIFY,S_USER_STRING     ;AN000;	 save new VERIFY parameter
								;
	   .ENDSELECT						;AN000;
								;
	   INC_VAR		N_COUNTER			;AN000;    inc counter
								;
	   .IF < N_COUNTER a 7 >				;AC000;JW;    if counter > 8
	      INIT_VAR		N_COUNTER, 1			;AN000;       set counter = 1
	   .ENDIF						;AN000;
								;
	.UNTIL < N_USER_FUNC eq E_ENTER > or near		;AN000; break if loop if ENTER entered
	.UNTIL < N_USER_FUNC eq E_ESCAPE > or near		;AN000; or ESCAPE entered
	.UNTIL < N_USER_FUNC eq E_F3 > near			;AN000; or F3 entered
								;
	.IF < N_USER_FUNC eq E_ENTER > near			;AN000; if user entered ENTER key
	   COPY_STRING		S_BREAK, M_BREAK, ST_BREAK	;AN000;    save BREAK  parameter
	   COPY_STRING		S_BUFFERS,M_BUFFERS, ST_BUFFERS ;AN000;   save BUFFERS parameter
	   COPY_STRING		S_FCBS, M_FCBS, ST_FCBS 	;AN000;    save FCBS parameter
	   COPY_STRING		S_FILES, M_FILES, ST_FILES	;AN000;    save FILES parameter
	   COPY_STRING		S_LASTDRIVE,M_LASTDRIVE,ST_LASTDRIVE  ;AN000;save LASTDRIVE  parameter
	   COPY_STRING		S_STACKS, M_STACKS, ST_STACKS	;AN000;    save STACKS parameter
	   COPY_STRING		S_VERIFY, M_VERIFY, ST_VERIFY	;AN000;    save VERIFY parameter
	   PUSH_HEADING 	CONFIG_SYS_SCREEN		;AN000;    save screen address on SELECT STACK
	   GOTO 		FIRST_DISK_SCREEN		;AN000;    goto the first fixed disk screen
	.ELSE							;AN000;
	   GOTO 		PROCESS_ESC_F3			;AN000; user entered ESC or F3, take action
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �FIRST_DISK_SCREEN			�
;  �					�
;  ��������������������������������������
;
;  The PARTITION FIXED DISK SCREEN is presented if the first fixed drive
;  exists and is completely unused.
;  When SELECT is invoked, the system configuration is checked and if fixed
;  disks exist, the fixed disk status is obtained and variables are initialized.
;  The screen allows the user to create partitions for the fixed drive.
;  If the user chooses to let SELECT define partition sizes, the first fixed
;  disk will be partitioned as follows:
;     -  A Primary DOS partition is created using the entire disk.
;  SELECT will partition the second fixed disk if it exists as follows:
;     - An Extended DOS partition is created using the entire disk space and a
;	logical drive is created using the entire Extended DOS partition.
;  Valid keys are ENTER, ESC, F1, F3, cursor up/down, 1/2.
;  Note.After FDISK, the partitions have to formatted.	Since the system is going
;  to reboot, SELECT must know if the user had created his own partitions or not
;  so that the partitions can be automatically formatted. The MENU parameter
;  in the AUTOEXEC.BAT file is changed FDISK.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FIRST_DISK_SCREEN:						;AN000;
	.IF < I_DEST_DRIVE ne E_DEST_DRIVE_C >	or		;AC111;JW
	.IF < N_DISK_1 eq E_DISK_INV >				;AN000; if first fixed disk not present
	   GOTO 		DATE_TIME_SCREEN		;AN000;    goto DATE_TIME screen
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �MAKE_BACKUP_DISKETTE		�
;  �					�
;  �					�
;  ��������������������������������������
;
;	WE NEED TO MAKE A DUPLICATE OF THE SELECT/SHELL DISKETTE 
;	FOR R/W PURPOSES!
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAKE_BACKUP_DISKETTE:						;AN000;
								;
	   .REPEAT						;AN000;JW
	      .REPEAT						;AN000;
								;
		 INIT_PQUEUE	      PAN_INSTALL_DOS		;AN000; initialize queue
		 PREPARE_PANEL	      PAN_DISKCOPY		;AN000;
		 PREPARE_PANEL	      PAN_HBAR			;AN000;
		 PREPARE_CHILDREN				;AN000;
		 DISPLAY_PANEL					;AN000;
								;
		 GET_FUNCTION	      FK_ENT_ESC_F3		;AN002;GHG get user entered function (ENTER or ESC )
								;
		.IF < N_USER_FUNC ne E_ENTER >			;AN002;GHG if user entered ENTER key
		   GOTO 		 PROCESS_ESC_F3 	;AN002;GHG    exit to DOS command line
		.ENDIF						;AN002;GHG
								;
		FIND_FILE	     S_AUTO_REBOOT, E_FILE_ATTR ;AN000;DT Look for AUTOEXEC.BAT (INSTALL diskette)
		   .LEAVE < nc >				;AN000;DT
		   HANDLE_ERROR 	ERR_DOS_DISK, E_RETURN	;AN000;DT
								;
	      .UNTIL						;AN000;DT
								;
	      .IF < MEM_SIZE ne 256 > near			;AN000;DT
		 CALL	 HOOK_INT_2F				;AN000;GHG
	      .ELSE						;AN000;
		 DEALLOCATE_MEMORY				;AN000;
		 CALL	 HOOK_INT_2F_256KB			;AN000;
	      .ENDIF						;AN000;
								;
	      INIT_VAR		   N_DSKCPY_ERR,E_DSKCPY_OK	;AN000;JW
	      EXEC_PROGRAM	   S_DISKCOPY,S_DISKCOPY_PARM,PARM_BLOCK,EXEC_NO_DIR;AN000; control will not return
	      .IF < c > 					;AN000;
		 MOV   EXEC_ERR,TRUE				;AN000;
	      .ENDIF						;AN000;
	      CALL	RESTORE_INT_2F				;AN000;GHG
								;
	   .UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY > near	;AN000;JW
								;
	   .IF < MEM_SIZE eq 256 > near 			;AN000;DT
	       CLEAR_SCREEN					;AN000;
	       DISPLAY_MESSAGE 12				;AN000;DT Insert SELECT diskette
	       .REPEAT						;AN000;
		   CALL GET_ENTER_KEY				;AN000; get user entered function
		   FIND_FILE		S_DOS_SEL_360, E_FILE_ATTR    ;AN000;
		   .LEAVE < nc >				;AN000;
		      DISPLAY_MESSAGE 11			;AN000;DT Beep
	       .UNTIL						;AN000;
	       ALLOCATE_MEMORY					;AN000;
	       CALL    INITIALIZE				;AN000;DT and read them in
	       INITIALIZE_BCHAR BCHAR				;AN000;Initialize the background character
	       INSERT_DISK	SUB_INSTALL_COPY, S_DOS_COM_360 ;AN000;JW
	   .ENDIF						;AN000;
	   .IF < EXEC_ERR eq TRUE >				;AN000;
	      HANDLE_ERROR	ERR_GENERAL, E_RETURN		;AN000;
	      GOTO		MAKE_BACKUP_DISKETTE		;AN000;
	   .ENDIF						;AN000;
	   CALL 		CURSOROFF			;AN000; set cursor off
								;
	OR  SEL_FLG,INSTALLRW					;AN000; indicate INSTALL diskette is R/W
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; � Create the CONFIG.340, AUTOEXEC.340, and SHELL.BAT on the	�
; � INSTALL COPY diskette in drive A:				�
;  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	CREATE_CONFIG		S_CONFIG_NEW, N_RETCODE 	;AN000;
	.IF c							;AN000;
	   GOTO 		INSTALL_ERROR			;AN000;
	.ENDIF							;AN000;
								;
	INIT_VAR		N_HOUSE_CLEAN,E_CLEAN_YES	;AN000; set to perform cleanup on exit
								;
	CREATE_AUTOEXEC 	S_AUTO_NEW,E_DEST_SHELL,N_RETCODE     ;AN000; create autoexec with SHELL commands
	.IF c							;AN000;
	   GOTO 		INSTALL_ERROR			;AN000;
	.ENDIF							;AN000;
								;
	CREATE_SHELL   S_SHELL_NEW, N_RETCODE			;AN000;DT
	.IF c							;AN000;DT
	   GOTO        INSTALL_ERROR				;AN000;DT
	.ENDIF							;AN000;DT
								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  ������������������������������������Ŀ
;  �DISK_PARTITION_OPTION		�
;  �					�
;  �					�
;  ��������������������������������������
;
;	If the first fixed disk is not new (existing partition)
;	goto different screen.	Else present screen with partition
;	options.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.IF < N_DISK_1 eq E_DISK_VAL_PART >			;AN000; if first disk has partitions
	   GOTO 		BOTH_DISK_SCREEN		;AN000;    goto next screen (BOTH_DISK)
	.ENDIF							;AN000;
								;
DISK_PARTITION_OPTION:						;AN000;
	INIT_VAR		N_DISK_NUM, '1'                 ;AN000;JW
	INIT_CHAR		N_DISK_NUM, E_DISK_ROW, E_DISK_COL, SUB_FIXED_1 ;AN000; display the disk number     JW
								;
	INIT_PQUEUE		PAN_FIXED_FIRST 		;AN000; initialize queue
	PREPARE_PANEL		SUB_FIXED_1			;AN000; prepare fixed disk 1 message
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		SCR_FIXED_FIRST, F_PARTITION	;AN000;
	DISPLAY_PANEL						;AN000; display first fixed disk partition screen
								;
	GET_SCROLL		SCR_FIXED_FIRST,F_PARTITION,FK_SCROLL ;AN000; get user selected option for creating partitions
								;
	PROCESS_F3						;AN000;
	PROCESS_ESC						;AN000;
								;
	COPY_WORD		F_PARTITION, I_USER_INDEX	;AN000;
	.IF < F_PARTITION eq E_PART_DEFAULT >			;AN000;
	   INIT_VAR		N_FORMAT_MODE, E_FORMAT_SELECT	;AN000;
	.ELSE							;AN000;
	   INIT_VAR		N_FORMAT_MODE, E_FORMAT_NEW	;AN000;
	.ENDIF							;AN000;
								;
	SAVE_PARAMETERS 	S_SELECT_TMP, N_RETCODE 	;AN000;
	.IF c							;AN000;
	   GOTO        INSTALL_ERROR				;AN000;
	.ENDIF							;AN000;
								;
	CHANGE_AUTOEXEC 	S_AUTO_REBOOT, S_AUTO_FDISK	;AN000;
	.IF c							;AN000;
	   GOTO        INSTALL_ERROR				;AN000;
	.ENDIF							;AN000;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	    DEALLOCATE_MEMORY					;AN000;
	.ENDIF							;AN000;DT
								;
	.IF < F_PARTITION eq E_PART_USER > near 		;AN000; if user selected to define his own partition sizes
								;
	   SAVE_PANEL_LIST					;AN000;     save panel list for test team
	   INIT_VAR		S_STR120_1, 0			;AN000;
	   APPEND_STRING	S_STR120_1,M_STR120_1,S_SLASH_Q ;AN000;DT add /Q parameter (no insert disk at end)
	   CALL 		CURSORON			;AN000;     set cursor to show
	   EXEC_PROGRAM 	S_FDISK,S_STR120_1,PARM_BLOCK,EXEC_NO_DIR   ;AN000; control will not return
	   .IF c						;AN000;
	      GOTO		FDISK_ERROR			;AN000;
	   .ENDIF						;AN000;
								;
	   GOTO 		FDISK_REBOOT			;AN000;DT
       .ENDIF							;AN000;
								;
	INIT_VAR		N_WORD_1, 1			;AN000;
	SCAN_DISK_TABLE 	E_DISK_1, N_WORD_1, N_RETCODE	;AN000;
	.IF < N_RETCODE eq 0 > and				;AN000;
	.IF < N_NAME_PART eq E_FREE_MEM_DISK >			;AN000;
	   WORD_TO_CHAR 	N_SIZE_PART, S_STR120_2 	;AN000;
	   MERGE_STRING 	S_STR120_1,M_STR120_1,SC_1,SC_PRI     ;AN000;
	   APPEND_STRING	S_STR120_1,M_STR120_1,S_STR120_2;AN000;
	   APPEND_STRING	S_STR120_1,M_STR120_1,S_SLASH_Q ;AN000;DT add /Q parameter (no insert disk at end)
	   EXEC_PROGRAM 	S_FDISK,S_STR120_1,PARM_BLOCK,EXEC_NO_DIR   ;AN000;
	   .IF c						;AN000;
	      GOTO		FDISK_ERROR			;AN000;
	   .ENDIF						;AN000;
	.ENDIF							;AN000;
								;
	.IF < N_DISK_2 eq E_DISK_NO_PART > near 		;AN000;
	   INIT_VAR		N_WORD_1, 1			;AN000;
	   SCAN_DISK_TABLE	E_DISK_2, N_WORD_1, N_RETCODE	;AN000;
	   .IF < N_RETCODE eq 0 > and near			;AN000;
	   .IF < N_NAME_PART eq E_FREE_MEM_DISK > near		;AN000;
	      WORD_TO_CHAR	N_SIZE_PART, S_STR120_2 	;AN000;
	      MERGE_STRING	S_STR120_1,M_STR120_1,SC_2,SC_EXT     ;AN000;
	      APPEND_STRING	S_STR120_1,M_STR120_1,S_STR120_2;AN000;
	      APPEND_STRING	S_STR120_1,M_STR120_1,SC_LOG	;AN000;
	      APPEND_STRING	S_STR120_1,M_STR120_1,S_STR120_2;AN000;
	      APPEND_STRING	S_STR120_1,M_STR120_1,S_SLASH_Q ;AN000;DT add /Q parameter (no insert disk at end)
	      EXEC_PROGRAM	S_FDISK,S_STR120_1,PARM_BLOCK,EXEC_NO_DIR   ;AN000;
	      .IF c						;AN000;
		 GOTO		FDISK_ERROR			;AN000;
	      .ENDIF						;AN000;
	   .ENDIF						;AN000;
	.ENDIF							;AN000;
								;
FDISK_REBOOT:							;AN000;
       .IF < MEM_SIZE eq 256 >					;AN000;DT
	    CLEAR_SCREEN					;AN000;
	    DISPLAY_MESSAGE 9					;AN000;
	.ELSE							;AN000;
	    CALL		 CURSOROFF			;AN000;      set to hide cursor
	    INIT_PQUEUE 	    PAN_REBOOT			;AN000; initialize queue
	    PREPARE_PANEL	    SUB_REBOOT_KEYS		;AN000;
	    DISPLAY_PANEL					;AN000;
	    SAVE_PANEL_LIST					;AN000;     save panel list for test team
	.ENDIF							;AN000;
								;
	GET_FUNCTION		FK_REBOOT			;AN000; Reboot
								;
FDISK_ERROR:							;AN000;
       .IF < MEM_SIZE eq 256 > near				;AN000;DT
	  CLEAR_SCREEN						;AN000;
	  DISPLAY_MESSAGE 12					;AN000;DT Insert SELECT diskette
								;
	  .REPEAT						;AN000;
	     GET_FUNCTION	     FK_ENT			;AN000; get user entered function
	     FIND_FILE		  S_DOS_SEL_360, E_FILE_ATTR	;AN000;
	    .LEAVE < nc >					;AN000;
	       DISPLAY_MESSAGE 11				;AN000;DT Beep
	  .UNTIL						;AN000;
								;
	  ALLOCATE_MEMORY					;AN000;
	  CALL	  INITIALIZE					;AN000;DT and read them in
	.ENDIF							;AN000;
	.IF < SUB_ERROR eq 1 >					;AN023; If error is because no Primary DOS partition
	   CALL 	  CURSOROFF				;AN023;   set cursor off
	   GOTO 	  DISK_PARTITION_OPTION 		;AN023;   return to partition options
	.ENDIF							;AN023;
	GOTO	       INSTALL_ERROR				;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  ������������������������������������Ŀ
;  �BOTH_DISK_SCREEN			�
;  �					�
;  �					�
;  ��������������������������������������
;
;	Ask user if they want to change the existing partition
;	layout or leave it the same (for both disks if 2nd exists).
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BOTH_DISK_SCREEN:						;AN000;
BOTH_DISK_PART_OPTION:						;AN000;
								;
	.IF < N_DISK_1_S2 eq E_SPACE_EDOS > or			;AN000;
	.IF < N_DISK_1_S2 eq E_SPACE_DISK >			;AN000;
	   INIT_VAR		N_DISK_NUM, '1'                 ;AN000;JW
	.ELSEIF < N_DISK_2_S2 eq E_SPACE_EDOS > or		;AN000;
	.IF < N_DISK_2_S2 eq E_SPACE_DISK >			;AN000;
	   INIT_VAR		N_DISK_NUM, '2'                 ;AN000;JW
	.ELSE							;AN000;
	   GOTO 		DATE_TIME_SCREEN		;AN000; no more partitions to be created
	.ENDIF							;AN000;
								;
	INIT_CHAR		N_DISK_NUM, E_DISK_ROW, E_DISK_COL, SUB_FIXED_1 ;AN000; display the disk number     JW
	INIT_PQUEUE		PAN_FIXED_BOTH			;AN000; initialize queue
	PREPARE_PANEL		SUB_FIXED_1			;AN000; prepare fixed disk message JW
	PREPARE_PANEL		PAN_HBAR			;AN000; prepare horizontal bar
	PREPARE_CHILDREN					;AN000; prepare child panels
	INIT_SCROLL		SCR_FIXED_BOTH, F_PARTITION	;AN000;
	DISPLAY_PANEL						;AN000; display first fixed disk partition screen
								;
	GET_SCROLL		SCR_FIXED_BOTH,F_PARTITION,FK_SCROLL  ;AN000; get user selected option for creating partitions
								;
	PROCESS_ESC						;AN000;
	PROCESS_F3						;AN000;
								;
	COPY_WORD		F_PARTITION, I_USER_INDEX	;AN000;
	CHANGE_AUTOEXEC 	S_AUTO_REBOOT, S_AUTO_FDISK	;AN000;
	.IF c							;AN000;
	   GOTO 		INSTALL_ERROR			;AN000;
	.ENDIF							;AN000;
								;
	.IF < F_PARTITION eq E_PART_USER > near 		;AN000; if user will define his own partition
								;
	   .IF < MEM_SIZE eq 256 >				;AN000;DT
	      DEALLOCATE_MEMORY 				;AN000;
	   .ENDIF						;AN000;DT
								;
	   INIT_VAR		N_FORMAT_MODE, E_FORMAT_USED	;AN000;
	   SAVE_PARAMETERS	S_SELECT_TMP, N_RETCODE 	;AN000;
	   SAVE_PANEL_LIST					;AN000;     save panel list for test team
	   INIT_VAR		S_STR120_1, 0			;AN000;
	   APPEND_STRING	S_STR120_1,M_STR120_1,S_SLASH_Q ;AN000;DT add /Q parameter (no insert disk at end)
	   CALL 		CURSORON			;AN000;     set to show cursor
	   EXEC_PROGRAM 	S_FDISK,S_STR120_1,PARM_BLOCK,EXEC_NO_DIR   ;AN000; control will not return
	   .IF c						;AN000;
	      .IF < SUB_ERROR eq 2 >				;AN034; SEH If user made no changes to partition
		 CALL		CURSOROFF			;AN034; SEH Set cursor off
		 GOTO		BOTH_DISK_SCREEN		;AN034; SEH Go to previous screen
	      .ELSE						;AN034; SEH
		 GOTO		FDISK_ERROR			;AN000;
	      .ENDIF						;AN034; SEH
	   .ENDIF						;AN000;
								;
	   GOTO 		FDISK_REBOOT			;AN000;DT
	.ELSE							;AN000;
	   GOTO 		DATE_TIME_SCREEN		;AN000; no more partitions to be created
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  GET KEY ROUTINE (256KB)
;
; Input: none
;
; Output: none
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PUBLIC GET_ENTER_KEY						;AN063;SEH
GET_ENTER_KEY PROC NEAR 					;AN000;DT
GEKEY_AGN:							;AN000;DT
	MOV	AH,0						;AN000;DT
	INT	16H						;AN000;DT get keystroke
	CMP	AL,13						;AN000;DT If ENTER the continue
	JE	GEKEY_EXIT					;AN000;DT
	DISPLAY_MESSAGE  11					;AN000;DT BEEP
	JMP	GEKEY_AGN					;AN000;DT
								;
GEKEY_EXIT:							;AN000;DT
	RET							;AN000;DT
GET_ENTER_KEY ENDP						;AN000;DT
								;
								;
SELECT	ENDS							;AN000;
	END							;AN000;
