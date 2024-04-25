

PAGE 55,132
NAME	SELECT
TITLE	SELECT - DOS - SELECT.EXE
SUBTTL	SELECT9.asm
.ALPHA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SELECT9.ASM : Copyright 1988 Microsoft
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
;
;  Module contains code for :
;	- Format the drives
;	- Copy files
;
;	CHANGE HISTORY:
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	SEGMENT BYTE PUBLIC 'DATA'
	EXTRN	DSKCPY_ERR:BYTE
	EXTRN	DSKCPY_WHICH:BYTE
	EXTRN	DSKCPY_OPTION:BYTE
	EXTRN	DSKCPY_PAN1:WORD
	EXTRN	DSKCPY_PAN2:WORD
	EXTRN	DSKCPY_PAN3:WORD
	EXTRN	DSKCPY_SOURCE:WORD
DATA	ENDS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Define dummy segment to calculate end of program
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PARSER	 SEGMENT PARA PUBLIC 'PARSER'
PARSER	 ENDS

SET_BLOCK	equ	4AH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.XLIST
	INCLUDE    PANEL.MAC
	INCLUDE    SELECT.INC
	INCLUDE    PAN-LIST.INC
	INCLUDE    CASTRUC.INC
	INCLUDE    STRUC.INC
	INCLUDE    MACROS.INC
	INCLUDE    MACROS7.INC
	INCLUDE    MACROS8.INC
	INCLUDE    EXT.INC
	INCLUDE    VARSTRUC.INC
	INCLUDE    ROUT_EXT.INC
.LIST
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	SEGMENT PARA PUBLIC 'SELECT'
	ASSUME	CS:SELECT,DS:DATA

	INCLUDE CASEXTRN.INC

	EXTRN	EXIT_SELECT:near
	EXTRN	CREATE_CONFIG_SYS:NEAR
	EXTRN	CREATE_AUTOEXEC_BAT:NEAR
	EXTRN	CREATE_SHELL_BAT:NEAR
	EXTRN	DEALLOCATE_HELP:FAR
	EXTRN	DEALLOCATE_MEMORY_CALL:FAR
	EXTRN	ALLOCATE_BLOCK:FAR
	EXTRN	ALLOCATE_LVB:FAR
	EXTRN	GET_OVERLAY:NEAR
	EXTRN	ALLOCATE_MEMORY_CALL:FAR

	PUBLIC	INSTALL_TO_360_DRIVE
	PUBLIC	INSTALL_ERROR
	PUBLIC	EXIT_DOS,PROCESS_ESC_F3
	PUBLIC	EXIT_DOS_CONT
	public	Free_Parser

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INSTALL_TO_360_DRIVE:
	 .IF < MEM_SIZE eq 256 >
	    DEALLOCATE_MEMORY
	    call  Free_Parser
	    .IF   < C >
		GOTO	INSTALL_ERROR
	    .ENDIF
	    CALL  GET_OVERLAY
	    INSERT_DISK   SUB_REM_DOS_A, S_DOS_COM_360
	 .ENDIF

	 ;;;Introduction to 360KB install
	 INIT_PQUEUE		 PAN_INSTALL_DOS
	 PREPARE_PANEL		 PAN_START360
	 PREPARE_PANEL		 PAN_HBAR
	 PREPARE_CHILDREN
	 DISPLAY_PANEL

	 GET_FUNCTION		 FK_ENT

	 CALL DEALLOCATE_HELP

	.IF < I_DEST_DRIVE eq E_DEST_DRIVE_A > near

	    ;;;diskcopy INSTALL diskette to WORKING1
	    DISKCOPY_TO 	    DSKCPY_TO_A_360,NO_SOURCE1,S_DOS_COM_360
	    DISKCOPY_PANELS	    SUB_REM_DOS_A,SUB_COPYING,SUB_INS_WORK1_S360
	    .REPEAT
	       INIT_VAR 	    N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		    HOOK_INT_2F
	       EXEC_PROGRAM	    S_DISKCOPY,S_DISKCOPY_PARM,PARM_BLOCK,EXEC_NO_DIR
	       CALL		    RESTORE_INT_2F
	       .IF < c >
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	    .UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY >
	    ERASE_FILE		    S_AUTOEX_C
	    ERASE_FILE		    S_CONSYS_C
	    ERASE_FILE		    S_SELCOM_C
	    ERASE_FILE		    S_SELHLP_C
	    ERASE_FILE		    S_SELPRT_C

	    ;;;diskcopy OPERATING1 diskette to WORKING2
	    DISKCOPY_TO 	    DSKCPY_TO_A_360,SOURCE1,S_DOS_UTIL1_DISK
	    DISKCOPY_PANELS	    SUB_REM_SELECT_360,SUB_COPYING,SUB_INS_WORK2_S360
	    .REPEAT
	       INIT_VAR 	    N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		    HOOK_INT_2F
	       EXEC_PROGRAM	    S_DISKCOPY,S_DISKCOPY_PARM,PARM_BLOCK,EXEC_NO_DIR
	       CALL		    RESTORE_INT_2F
	       .IF c
	       .THEN
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	       .LEAVE < N_DSKCPY_ERR ne E_DSKCPY_RETRY >
	       INSERT_DISK	SUB_REM_DOS_A, S_DOS_COM_360
	    .UNTIL

	    ;;;diskcopy OPERATING 2 diskette to WORKING3
	    .REPEAT
	       INSERT_DISK	SUB_REM_DOS_A, S_DOS_COM_360
	       DISKCOPY_TO	DSKCPY_TO_A_360,NO_SOURCE1,S_DOS_UTIL2_DISK
	       DISKCOPY_PANELS	SUB_INS_OPER2,SUB_COPYING,SUB_INS_WORK3_A
	       INIT_VAR 	N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		HOOK_INT_2F
	       EXEC_PROGRAM	S_DISKCOPY,S_DISKCOPY_PARM,PARM_BLOCK,EXEC_NO_DIR
	       CALL		RESTORE_INT_2F
	       .IF c
	       .THEN
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	    .UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY > near

	    ;;;diskcopy OPERATING 3 diskette to STARTUP
	    .REPEAT
		INSERT_DISK	    SUB_REM_DOS_A, S_DOS_COM_360
		DISKCOPY_TO 	    DSKCPY_TO_A_360,SOURCE1,S_DOS_UTIL3_DISK
		DISKCOPY_PANELS	    SUB_REM_UTIL1_360,SUB_COPYING,SUB_INS_STARTT_S360
	       INIT_VAR 	    N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		    HOOK_INT_2F
	       EXEC_PROGRAM	    S_DISKCOPY,S_DISKCOPY_PARM,PARM_BLOCK,EXEC_NO_DIR
	       CALL		    RESTORE_INT_2F
	       .IF c
	       .THEN
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	    .UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY > near
	    ERASE_FILE		 S_RECOVER_C
	    ERASE_FILE		 S_FASTOPEN_C
	    ;;;create config and autoexec files on startup diskette
	    CREATE_CONFIG	    S_CONSYS_C, N_RETCODE
	    .IF c
	       GOTO	   INSTALL_ERROR
	    .ENDIF
	    CREATE_AUTOEXEC	    S_AUTOEX_C,E_DEST_DOS,N_RETCODE
	    .IF c near
	       GOTO	   INSTALL_ERROR
	    .ENDIF

	   .IF < ACTIVE eq EGA > or
	   .IF < ALTERNATE eq EGA > or
	   .IF < ACTIVE eq LCD > or
	   .IF < ALTERNATE eq LCD > near
	   .THEN
		.IF < F_VDISK eq E_VDISK_NO >
		   ERASE_FILE	 S_VDISK_C
		   .IF c
		      GOTO	  INSTALL_ERROR
		   .ENDIF
		.ENDIF
		.IF < F_ANSI eq E_ANSI_NO >
		   ERASE_FILE	 S_ANSI_C
		   .IF c
		      GOTO	  INSTALL_ERROR
		   .ENDIF
		.ENDIF
		.IF < F_APPEND eq E_APPEND_NO >
		   ERASE_FILE	 S_APPEND_C
		   .IF c
		      GOTO	  INSTALL_ERROR
		   .ENDIF
		.ENDIF
		.IF < F_GRAFTABL eq E_GRAFTABL_NO > or
		.IF < F_GRAFTABL eq E_GRAFTABL_NA >
		   ERASE_FILE	 S_GRAFTABL_C
		   .IF c
		      GOTO	  INSTALL_ERROR
		   .ENDIF
		.ENDIF
		.IF < F_GRAPHICS eq E_GRAPHICS_NO >
		   ERASE_FILE	 S_GRAPHICS_C
		   ERASE_FILE	 S_GRAPHPRO_C
		   .IF c
		      GOTO	  INSTALL_ERROR
		   .ENDIF
		.ENDIF
		;;;Insert SELECT diskette in drive A:
		INSERT_DISK	SUB_REM_SHELL_360, S_DOS_SEL_360

		;;;copying files from INSTALL diskette screen
		INIT_PQUEUE		PAN_INSTALL_DOS
		PREPARE_PANEL		SUB_COPYING
		DISPLAY_PANEL

		INIT_VAR       SOURCE_PANEL, SUB_REM_SHELL_360
		INIT_VAR       DEST_PANEL, SUB_INS_STARTT_S360

		.IF < ACTIVE eq EGA > or
		.IF < ALTERNATE eq EGA > near
		.THEN
		   .IF < MEM_SIZE eq 256 >
		      DEALLOCATE_MEMORY
		   .ENDIF
		   COPY_FILES2	     I_DEST_DRIVE,COPY_SEL_EGA,E_SEL_EGA,S_INSTALL_PATH
		   .IF c near
		      .IF < MEM_SIZE eq 256 >
			 ALLOCATE_MEMORY
			 CALL	 INITIALIZE
		      .ENDIF
		      HANDLE_ERROR   ERR_COPY_DISK, E_RETURN
		   .ENDIF
		   .IF < MEM_SIZE eq 256 > near
		      ALLOCATE_MEMORY
		      CALL    INITIALIZE
		   .ENDIF
		.ELSE near
		   COPY_FILES2	     I_DEST_DRIVE,COPY_SEL_LCD,E_SEL_LCD,S_INSTALL_PATH ;AC111; copy files to f-disk  JW
		   .IF c near
		      HANDLE_ERROR   ERR_COPY_DISK, E_RETURN
		   .ENDIF
		.ENDIF
	   .ENDIF

	   ;;;diskcopy MS-SHELL diskette to SHELL
	   .if <f_shell eq e_shell_yes > near
	    .REPEAT
		INSERT_DISK	    SUB_REM_DOS_A, S_DOS_COM_360
		DISKCOPY_TO 	    DSKCPY_TO_A_360,SOURCE1,S_DOS_SHEL_DISK
		DISKCOPY_PANELS	    SUB_INS_MSSHELL_A,SUB_COPYING,SUB_INS_SHELL_S360
	       INIT_VAR 	    N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		    HOOK_INT_2F
	       EXEC_PROGRAM	    S_DISKCOPY,S_DISKCOPY_PARM,PARM_BLOCK,EXEC_NO_DIR
	       CALL		    RESTORE_INT_2F
	       .IF c
	       .THEN
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	    .UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY > near
	    CREATE_SHELL   S_SHELL_NEW, N_RETCODE
	    .IF c near
	       GOTO	   INSTALL_ERROR
	    .ENDIF
	   .endif

	.ELSE near

	    ;;;diskcopy INSTALL diskette to WORKING 1
	    DISKCOPY_TO 	    DSKCPY_TO_B,SOURCE1,S_DOS_COM_360
	    DISKCOPY_PANELS	    SUB_INS_WORK1_360,SUB_COPYING,NOPANEL
	    .REPEAT
	       INIT_VAR 	    N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		    HOOK_INT_2F
	       EXEC_PROGRAM	    S_DISKCOPY,S_DSKCPY_TO_B,PARM_BLOCK,EXEC_NO_DIR
	       CALL		    RESTORE_INT_2F
	       .IF c
	       .THEN
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	    .UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY >
	    ERASE_FILE		    S_AUTO_NEW_B
	    ERASE_FILE		    S_CONFIG_NEW_B
	    ERASE_FILE		    S_SELCOM_NEW_B
	    ERASE_FILE		    S_SELHLP_NEW_B
	    ERASE_FILE		    S_SELPRT_NEW_B

	    ;;;diskcopy OPERATING 1 diskette to WORKING 2
	    DISKCOPY_TO 	    DSKCPY_TO_B,SOURCE1,S_DOS_UTIL1_DISK
	    DISKCOPY_PANELS	    SUB_INS_WORK2_360,SUB_COPYING,NOPANEL
	    .REPEAT
	       INIT_VAR 	    N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		    HOOK_INT_2F
	       EXEC_PROGRAM	    S_DISKCOPY,S_DSKCPY_TO_B,PARM_BLOCK,EXEC_NO_DIR
	       CALL		    RESTORE_INT_2F
	       .IF c
	       .THEN
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	       .LEAVE < N_DSKCPY_ERR ne E_DSKCPY_RETRY >
	       INSERT_DISK	SUB_REM_DOS_A, S_DOS_COM_360
	    .UNTIL

	    ;;;diskcopy OPERATING 2 diskette to WORKING3
	    .REPEAT
	       INSERT_DISK	SUB_REM_DOS_A, S_DOS_COM_360
	       DISKCOPY_TO	DSKCPY_TO_B,SOURCE1,S_DOS_UTIL2_DISK
	       DISKCOPY_PANELS	SUB_INS_WORK3_360,SUB_COPYING,NOPANEL
	       INIT_VAR 	N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		HOOK_INT_2F
	       EXEC_PROGRAM	S_DISKCOPY,S_DSKCPY_TO_B,PARM_BLOCK,EXEC_NO_DIR
	       CALL		RESTORE_INT_2F
	       .IF c
	       .THEN
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	    .UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY > near

	    ;;;diskcopy OPERATING 3 diskette to STARTUP
	    .REPEAT
	       INSERT_DISK	SUB_REM_DOS_A, S_DOS_COM_360
	       DISKCOPY_TO	DSKCPY_TO_B,SOURCE1,S_DOS_UTIL3_DISK
	       DISKCOPY_PANELS	SUB_INS_START_360,SUB_COPYING,NOPANEL
	       INIT_VAR 	N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		HOOK_INT_2F
	       EXEC_PROGRAM	S_DISKCOPY,S_DSKCPY_TO_B,PARM_BLOCK,EXEC_NO_DIR
	       CALL		RESTORE_INT_2F
	       .IF c
	       .THEN
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	    .UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY > near
	    ERASE_FILE		 S_RECOVER_B
	    ERASE_FILE		 S_FASTOPEN_B
	    ;;;create config and autoexec files on startup diskette
	    CREATE_CONFIG	    S_CONFIG_NEW_B, N_RETCODE
	    .IF c
	       GOTO	   INSTALL_ERROR
	    .ENDIF
	    CREATE_AUTOEXEC	    S_AUTO_NEW_B,E_DEST_DOS,N_RETCODE
	    .IF c
	       GOTO	   INSTALL_ERROR
	    .ENDIF
	    .IF < ACTIVE eq EGA > or
	    .IF < ALTERNATE eq EGA > or
	    .IF < ACTIVE eq LCD > or
	    .IF < ALTERNATE eq LCD > near
	    .THEN
	       .IF < F_VDISK eq E_VDISK_NO >
		  ERASE_FILE	S_VDISK_B
		  .IF c
		     GOTO	 INSTALL_ERROR
		  .ENDIF
	       .ENDIF
	       .IF < F_ANSI eq E_ANSI_NO >
		  ERASE_FILE	S_ANSI_B
		  .IF c
		     GOTO	 INSTALL_ERROR
		  .ENDIF
	       .ENDIF
	       .IF < F_APPEND eq E_APPEND_NO >
		  ERASE_FILE	S_APPEND_B
		  .IF c
		     GOTO	 INSTALL_ERROR
		  .ENDIF
	       .ENDIF
	       .IF < F_GRAFTABL eq E_GRAFTABL_NO > or
	       .IF < F_GRAFTABL eq E_GRAFTABL_NA >
		  ERASE_FILE	S_GRAFTABL_B
		  .IF c
		     GOTO	 INSTALL_ERROR
		  .ENDIF
	       .ENDIF
	       .IF < F_GRAPHICS eq E_GRAPHICS_NO >
		  ERASE_FILE	S_GRAPHICS_B
		  ERASE_FILE	S_GRAPHPRO_B
		  .IF c
		     GOTO	 INSTALL_ERROR
		  .ENDIF
	       .ENDIF
	       ;;;Insert SELECT diskette in drive A:
	       INSERT_DISK	SUB_INS_INSTALL_360, S_DOS_SEL_360
	       ;;;copying files from INSTALL diskette screen
	       INIT_PQUEUE	       PAN_INSTALL_DOS
	       PREPARE_PANEL	       SUB_COPYING
	       DISPLAY_PANEL
	       .IF < ACTIVE eq EGA > or
	       .IF < ALTERNATE eq EGA > near
		  .IF < MEM_SIZE eq 256 >
		      DEALLOCATE_MEMORY
		  .ENDIF
		  COPY_FILES2	    I_DEST_DRIVE,COPY_SEL_EGA,E_SEL_EGA,S_INSTALL_PATH ;AC111; copy files to f-disk  JW
		  .IF c near
		      .IF < MEM_SIZE eq 256 >
			 ALLOCATE_MEMORY
			 CALL	 INITIALIZE
		      .ENDIF
		     HANDLE_ERROR	 ERR_COPY_DISK, E_RETURN
		  .ENDIF
		  .IF < MEM_SIZE eq 256 >
		      ALLOCATE_MEMORY
		      CALL    INITIALIZE
		  .ENDIF
	       .ELSEIF < ACTIVE eq LCD > or
	       .IF < ALTERNATE eq LCD >
	          COPY_FILES2    I_DEST_DRIVE,COPY_SEL_LCD,E_SEL_LCD,S_INSTALL_PATH ;AC111; copy files to f-disk JW
	          .IF c near
	       		HANDLE_ERROR	    ERR_COPY_DISK, E_RETURN
	          .ENDIF
	       .ENDIF
	    .ENDIF

	   .if <f_shell eq e_shell_yes > near
	    ;;;diskcopy MS-SHELL to SHELL
	    .REPEAT
	       INSERT_DISK	SUB_REM_DOS_A, S_DOS_COM_360
	       DISKCOPY_TO	DSKCPY_TO_B,SOURCE1,S_DOS_SHEL_DISK
	       DISKCOPY_PANELS	SUB_INS_SHELL_DISKS,SUB_COPYING,NOPANEL
	       INIT_VAR 	N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		HOOK_INT_2F
	       EXEC_PROGRAM	S_DISKCOPY,S_DSKCPY_TO_B,PARM_BLOCK,EXEC_NO_DIR
	       CALL		RESTORE_INT_2F
	       .IF c
	       .THEN
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	    .UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY > near
	    CREATE_SHELL   S_SHELL_NEW_B, N_RETCODE
	    .IF c
	       GOTO	   INSTALL_ERROR
	    .ENDIF
	   .endif			; copy to shell

	.ENDIF

	;;;installation complete and change diskettes screen
	INIT_PQUEUE		PAN_COMPLETE3
	PREPARE_PANEL		SUB_COMP_KYS_3
	DISPLAY_PANEL
	SAVE_PANEL_LIST
	GET_FUNCTION		FK_REBOOT

;;;;;;;;control will not return here. user has to reboot;;;;;;;;; end of install to 1.2M or 1.44M drive
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Process the ESC/F3 keys.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PROCESS_ESC_F3:
	.IF < N_USER_FUNC eq E_ESCAPE >
	   POP_HEADING
	.ENDIF
EXIT_DOS:
	CLEAR_SCREEN2
EXIT_DOS_CONT:
	.IF < I_DEST_DRIVE eq E_DEST_DRIVE_C > and
	.IF < N_HOUSE_CLEAN eq E_CLEAN_YES >
	   ERASE_FILE	   S_AUTO_NEW
	   ERASE_FILE	   S_CONFIG_NEW
	   ERASE_FILE	   S_SHELL_NEW
	   ERASE_FILE	   S_SELECT_TMP
	   CHANGE_AUTOEXEC S_AUTO_REBOOT, S_AUTO_MENU
	.ENDIF

	GOTO	EXIT_SELECT

INSTALL_ERROR:

	.IF < DSKCPY_ERR ne DSKCPY_EXIT >
	    HANDLE_ERROR    ERR_EXIT, E_QUIT
	.ENDIF

	GOTO	EXIT_DOS

Free_Parser:
	    MOV   AH,62H
	    INT   21H
	    MOV   AX,BX
	    MOV   BX,PARSER
	    MOV   ES,AX
	    SUB   BX,AX
	    MOV   AH,SET_BLOCK
	    DOSCALL
	    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	ENDS
	END
