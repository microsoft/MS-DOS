

PAGE 55,132							;AN000;
NAME	SELECT							;AN000;
TITLE	SELECT - DOS - SELECT.EXE				;AN000;
SUBTTL	SELECT8.asm						;AN000;
.ALPHA								;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SELECT8.ASM : Copyright 1988 Microsoft
;
;	DATE:	 August 8/87
;
;	COMMENTS: Assemble with MASM 3.0 (using the /A option)
;
;
;	CHANGE HISTORY:
;
;	;AN000; DT  added support for creation of the DOSSHELL.BAT as a
;		    separately installed file.	(D233)
;	;AN002; GHG for P1146
;	;AN003; GHG for D234
;	;AN004; GHG for P65
;	;AN005; DT for single drive support
;	;AN006; JW correct critical error problems during format/copy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	SEGMENT BYTE PUBLIC 'DATA'                              ;AN000;
	EXTRN	   EXEC_ERR:BYTE				;AN063;SEH
	EXTRN	   BCHAR:BYTE					;AN000;DT
	EXTRN	DSKCPY_ERR:BYTE 				;AN000;DT
	EXTRN	DSKCPY_WHICH:BYTE				;AN000;DT
	EXTRN	DSKCPY_OPTION:BYTE				;AN000;DT
	EXTRN	DSKCPY_PAN1:WORD				;AN000;DT
	EXTRN	DSKCPY_PAN2:WORD				;AN000;DT
	EXTRN	DSKCPY_PAN3:WORD				;AN000;DT
	EXTRN	DSKCPY_SOURCE:WORD				;AN000;DT
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
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	EXTRN	ALLOCATE_MEMORY_CALL:FAR			;AN063;SEH
	EXTRN	DEALLOCATE_MEMORY_CALL:FAR			;AN063;SEH
	EXTRN	ALLOCATE_BLOCK:FAR				;AN000;DT
	EXTRN	PM_BASECHAR:BYTE				;AN000;
	EXTRN	PM_BASEATTR:BYTE				;AN000;
	EXTRN	CRD_CCBVECOFF:WORD				;AN000;
	EXTRN	CRD_CCBVECSEG:WORD				;AN000;
SELECT	SEGMENT PARA PUBLIC 'SELECT'                            ;AN000;
	ASSUME	CS:SELECT,DS:DATA				;AN000;
								;
	INCLUDE CASEXTRN.INC					;AN000;
								;
	EXTRN	EXIT_SELECT:near				;AN000;
	EXTRN	CREATE_CONFIG_SYS:NEAR				;AN000;
	EXTRN	CREATE_AUTOEXEC_BAT:NEAR			;AN000;
	EXTRN	CREATE_SHELL_BAT:NEAR				;AN000;DT
	EXTRN	DEALLOCATE_HELP:FAR				;AN007;JW
								;
	EXTRN	INSTALL_TO_360_DRIVE:NEAR			;AN000;DT
	EXTRN	INSTALL_ERROR:NEAR				;AN000;
	EXTRN	EXIT_DOS:NEAR					;AN000;
	EXTRN	PROCESS_ESC_F3:NEAR				;AN000;
	EXTRN	EXIT_DOS_CONT:NEAR				;AN000;
	EXTRN	GET_ENTER_KEY:NEAR				;AN063;SEH
	EXTRN	GET_OVERLAY:NEAR				;AN063;SEH
	extrn	Free_Parser:near
	PUBLIC	DISKETTE_INSTALL				;AN111;JW
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Install is to drive B: or drive A:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DISKETTE_INSTALL:						;AC111;JW
								;
	INIT_VAR	     F_PATH, E_PATH_NO			;AN000;
	INIT_VAR	     F_APPEND, E_APPEND_NO		;AN000;
	INIT_VAR	     F_PROMPT, E_PROMPT_NO		;AN000;
	INIT_VAR	     F_XMA, E_XMA_NO			;AN000;
	INIT_VAR	     F_FASTOPEN, E_FASTOPEN_NO		;AN000;
	INIT_VAR	     F_SHARE, E_SHARE_NO		;AN000;
	INIT_VAR	     S_INSTALL_PATH,0			;AN000;set install path field = 0
								;
	.IF < N_DISKETTE_A eq E_DISKETTE_360 >			;AN111;JW
	   GOTO 		INSTALL_TO_360_DRIVE		;AN111;JW
	.ENDIF							;AN111;JW
								;
	.IF < N_DISKETTE_A eq E_DISKETTE_720 >			;AN111;JW
	    GOTO		 INSTALL_TO_720_DRIVE		;AN111;JW
	.ENDIF							;AN111;JW
								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	install is to 1.44M drives
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;Introduction to 1440KB install			;
	INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	PREPARE_PANEL		PAN_START1440			;AN000;
	PREPARE_PANEL		PAN_HBAR			;AN000;
	PREPARE_CHILDREN					;AN000; prepare child panels
	DISPLAY_PANEL						;AN000;
								;
	GET_FUNCTION		FK_ENT				;AN000;
								;
	.IF < I_DEST_DRIVE eq E_DEST_DRIVE_B > near		;AN111;JW
	   ;;;insert startup diskette in drive B:		;
	   INIT_PQUEUE		   PAN_INST_PROMPT		;AN000; initialize queue
	   PREPARE_PANEL	   SUB_INS_START_B		;AN000; insert startup diskette in drive B:
	   PREPARE_PANEL	   PAN_HBAR			;AN000; prepare horizontal bar
	   PREPARE_CHILDREN					;AN000; prepare child panels
	   DISPLAY_PANEL					;AN000; display panel
								;
	   GET_FUNCTION 	   FK_ENT			;AN000;
								;
	   ;;;formatting disk screen				;
	   INIT_PQUEUE		   FORMAT_DISKET		;AN000; initialize queue
	   DISPLAY_PANEL					;AN000;
								;
	   ;;;format startup diskette in drive B:		;
	   .REPEAT						;AN006;JW
	      EXEC_PROGRAM	      S_FORMAT,S_FORMAT_B,PARM_BLOCK,EXEC_NO_DIR;AN000; format startup disket & copy system files
	      .LEAVE nc 					;AN006;JW
	      HANDLE_FORMAT_ERROR				;AN000;JW
	   .UNTIL						;AN006;JW
								;
	   ;;;create config and autoexec files on startup diskette ;
	   CREATE_CONFIG	   S_CONFIG_NEW_B, N_RETCODE	;AN000; create CONFIG.SYS file
	   .IF c						;AN000;
	      GOTO	  INSTALL_ERROR 			;AN000;
	   .ENDIF						;AN000;
	   CREATE_AUTOEXEC	   S_AUTO_NEW_B,E_DEST_SHELL,N_RETCODE;AN000; create AUTOEXEC.BAT file with SHELL pars
	   .IF < c > near					;AN000;
	      GOTO	  INSTALL_ERROR 			;AN000;
	   .ENDIF						;AN000;
								;
	.ELSE near						;AN111; install is to 1.44 meg A: drive     JW
								;
	   ;;;format startup diskette in drive A:		;
	   ;;;use format int2f call to display panels		;
	   INIT_VAR	   FORMAT_WHICH,STARTUP 		;AN111;JW
	   .REPEAT						;AN006;JW
	      HOOK_2F_FORMAT					;AN111;JW
	      EXEC_PROGRAM    S_FORMAT,S_FORMAT_A,PARM_BLOCK,EXEC_NO_DIR    ;AN000; format startup disket & copy system files
	      .LEAVE nc 					;AN006;JW
	      UNHOOK_2F 					;AN111;JW
	      HANDLE_FORMAT_ERROR				;AN000;JW
	      INSERT_DISK     SUB_REM_DOS_A, S_DOS_SEL_360	;AN000;
	   .UNTIL						;AN006;JW
	   UNHOOK_2F						;AN111;JW
								;
	   ;;;create config and autoexec files on startup diskette ;
	   CREATE_CONFIG	   S_CONSYS_C, N_RETCODE	;AN000; create CONFIG.SYS file
	   .IF c						;AN000;
	      GOTO	  INSTALL_ERROR 			;AN000;
	   .ENDIF						;AN000;
	   CREATE_AUTOEXEC  S_AUTOEX_C,E_DEST_SHELL,N_RETCODE	;AN000; create AUTOEXEC.BAT file with SHELL pars
	   .IF c						;AN000;
	      GOTO	  INSTALL_ERROR 			;AN000;
	   .ENDIF						;AN000;
								;
	   ;;; insert the INSTALL diskette in drive A:		;
	   INSERT_DISK		   SUB_REM_DOS_A, S_DOS_SEL_360 ;AN000;
								;
	.ENDIF							;AN000;
								;
	;;;copying files screen 				;
	INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	PREPARE_PANEL		SUB_COPYING			;AN111; prepare copying files message JW
	DISPLAY_PANEL						;AN000;
								;
	.IF < I_DEST_DRIVE eq E_DEST_DRIVE_A >			;AN111;JW
	   INIT_VAR	  SOURCE_PANEL, SUB_REM_DOS_A		;AN000;
	   INIT_VAR	  DEST_PANEL, SUB_INS_STARTT_S360	;AN000;
	.ENDIF							;AN000;
								;
	;;;copy all files from INSTALL diskette to STARTUP diskette
	COPY_FILES     I_DEST_DRIVE,COPY_INST_1200_1440,E_INST_1200_1440;AN000;
	.IF c							;AN000;
	   GOTO        INSTALL_ERROR				;AN000;
	.ENDIF							;AN000;
								;
	;;; insert OPERATING diskette in A:			;
	INSERT_DISK	SUB_REM_SEL_A, S_DOS_UTIL1_DISK		;AN000;
								;
	;;;copying files screen 				;
	INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	PREPARE_PANEL		SUB_COPYING			;AN000; prepare copying files message
	DISPLAY_PANEL						;AN000;
								;
	.IF < I_DEST_DRIVE eq E_DEST_DRIVE_A >			;AN111;JW
	   INIT_VAR	  SOURCE_PANEL, SUB_REM_SEL_A		;AN111;JW
	   INIT_VAR	  DEST_PANEL, SUB_INS_STARTT_S360	;AN111;JW
	.ENDIF							;AN000;
								;
	;;;copy all files from OPERATING diskette to STARTUP diskette;
	COPY_FILES	  I_DEST_DRIVE,COPY_OPER_1200_1440,E_OPER_1200_1440;AN000;
	.IF c							;AN000;
	   GOTO 	  INSTALL_ERROR 			;AN000;
	.ENDIF							;AN000;

	.if < f_shell eq e_shell_yes > near			; install the shell?

	   ;;; insert MS-SHELL diskette in A:			;
	   INSERT_DISK	SUB_INS_MSSHELL_A, S_DOS_SHEL_DISK		;AN000;
								;
	   ;;;copying files screen 				;
	   INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	   PREPARE_PANEL		SUB_COPYING			;AN000; prepare copying files message
	   DISPLAY_PANEL						;AN000;
								;
	   .IF < I_DEST_DRIVE eq E_DEST_DRIVE_A >			;AN111;JW
	      INIT_VAR	  SOURCE_PANEL, SUB_INS_MSSHELL_A		;AN111;JW
	      INIT_VAR	  DEST_PANEL, SUB_INS_STARTT_S360	;AN111;JW
	   .ENDIF							;AN000;
								;
	   ;;;copy all files from OPERATING diskette to STARTUP diskette;
	   COPY_FILES	  I_DEST_DRIVE,COPY_SHELL_1200_1440,E_SHELL_1200_1440;AN000;
	   .IF c							;AN000;
	      GOTO 	  INSTALL_ERROR 			;AN000;
	   .ENDIF							;AN000;

	.endif		; installing the shell
								;
	.IF < I_DEST_DRIVE eq E_DEST_DRIVE_B >			;AN111;JW
	   CREATE_SHELL   S_SHELL_NEW_B, N_RETCODE		;AN000;DT
	   .IF c						;AN000;DT
	      GOTO	  INSTALL_ERROR 			;AN000;DT
	   .ENDIF						;AN000;DT
	.ELSE							;AN000;
	   CREATE_SHELL   S_SHELL_NEW, N_RETCODE		;AN000;DT
	   .IF c						;AN000;DT
	      GOTO	  INSTALL_ERROR 			;AN000;DT
	   .ENDIF						;AN000;DT
	.ENDIF							;AN000;
								;
	;;;installation complete screen 			;
	INIT_PQUEUE		PAN_COMPLETE2			;AN000; initialize queue
	PREPARE_PANEL		SUB_COMP_KYS_1C 		;AN000;
	DISPLAY_PANEL						;AN000;
	SAVE_PANEL_LIST 					;AN000;
								;
	GET_FUNCTION		FK_REBOOT			;AN000;
;;;;;;;;control will not return here. user has to reboot;;;;;;;;; end of install to 1.44M drive
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;    Install to 720K drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INSTALL_TO_720_DRIVE:
	.IF < MEM_SIZE eq 256 >
	   DEALLOCATE_MEMORY
	   call  Free_Parser
	   .IF   < C >
		GOTO	INSTALL_ERROR
	   .ENDIF
	   CALL  GET_OVERLAY
	   INSERT_DISK   SUB_REM_DOS_A, S_DOS_COM_360
	.ENDIF

	;;;Introduction to 720KB install
	INIT_PQUEUE		PAN_INSTALL_DOS
	PREPARE_PANEL		PAN_START720
	PREPARE_PANEL		PAN_HBAR
	PREPARE_CHILDREN
	DISPLAY_PANEL

	GET_FUNCTION		FK_ENT

	CALL DEALLOCATE_HELP

	.IF < I_DEST_DRIVE eq E_DEST_DRIVE_A > near

	    ;;;diskcopy INSTALL diskette to STARTUP diskette
	    DISKCOPY_TO 	    DSKCPY_TO_A_360,NO_SOURCE1,S_DOS_SEL_360
	    DISKCOPY_PANELS	    SUB_REM_DOS_A,SUB_COPYING,SUB_INS_STARTT_S360
	    .REPEAT
	       INIT_VAR 	    N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		    HOOK_INT_2F
	       EXEC_PROGRAM	    S_DISKCOPY,S_DISKCOPY_PARM,PARM_BLOCK,EXEC_NO_DIR
	       CALL		    RESTORE_INT_2F
	       .IF < c >
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	    .UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY >
	    ; delete unneeded files
	    ERASE_FILE		    S_AUTOEX_C
	    ERASE_FILE		    S_CONSYS_C
	    ERASE_FILE		    S_SELEXE_C
	    ERASE_FILE		    S_SELHLP_C
	    ERASE_FILE		    S_SELPRT_C
	    ERASE_FILE		    S_SELDAT_C
	    ; make config.sys and autoexec.bat
	    create_config	s_consys_c, n_retcode
	    .if c
	    	goto install_error
	    .endif
	    create_autoexec	s_autoex_c, e_dest_dos, n_retcode
	    .if c
	    	goto install_error
	    .endif

	    ;;; diskcopy OPERATE diskette to WORKING diskette
	    .REPEAT
		DISKCOPY_TO 	    DSKCPY_TO_A_360,SOURCE1,S_DOS_UTIL1_DISK
		DISKCOPY_PANELS	    SUB_REM_SEL_A,SUB_COPYING,SUB_INS_WORKING_A
	       INIT_VAR 	    N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		    HOOK_INT_2F
	       EXEC_PROGRAM	    S_DISKCOPY,S_DISKCOPY_PARM,PARM_BLOCK,EXEC_NO_DIR
	       CALL		    RESTORE_INT_2F
	       .IF < c >
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	       .LEAVE < N_DSKCPY_ERR ne E_DSKCPY_RETRY >
	       INSERT_DISK	SUB_REM_DOS_A, S_DOS_SEL_360
	    .UNTIL

	    ;;;perhaps diskcopy MS-SHELL to SHELL
	    .IF < f_shell eq e_shell_yes > near
		.REPEAT
		    INSERT_DISK		SUB_REM_DOS_A, S_DOS_SEL_360
		    DISKCOPY_TO		DSKCPY_TO_A_360,SOURCE1,S_DOS_SHEL_DISK
		    DISKCOPY_PANELS	SUB_INS_MSSHELL_A,SUB_COPYING,SUB_INS_SHELL_S360
		    INIT_VAR		N_DSKCPY_ERR,E_DSKCPY_OK
		    CALL		HOOK_INT_2F
		    EXEC_PROGRAM	S_DISKCOPY,S_DISKCOPY_PARM,PARM_BLOCK,EXEC_NO_DIR
		    CALL		RESTORE_INT_2F
		    .IF < c >
			GOTO		INSTALL_ERROR
		    .ENDIF
		.UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY >
		; make config.sys and autoexec.bat
		create_config	s_consys_c, n_retcode
		.if c
		    goto install_error
		.endif
		create_autoexec	s_autoex_c, e_dest_shell, n_retcode
		.if c
		    goto install_error
		.endif
		create_shell		s_shell_new, n_retcode
		.IF c near
		    goto install_error
		.ENDIF
	    .ENDIF

	.ELSE  near 		; This is a two floppy system.  Install from A to B.

	    ;;;diskcopy INSTALL diskette to STARTUP diskette
	    DISKCOPY_TO 	    DSKCPY_TO_B,SOURCE1,S_DOS_SEL_360
	    DISKCOPY_PANELS	    SUB_INS_START_B,SUB_COPYING,NOPANEL
	    .REPEAT
	       INIT_VAR 	    N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		    HOOK_INT_2F
	       EXEC_PROGRAM	    S_DISKCOPY,S_DSKCPY_TO_B,PARM_BLOCK,EXEC_NO_DIR
	       CALL		    RESTORE_INT_2F
	       .IF < c >
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	    .UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY >
	    ; delete unneeded files
	    ERASE_FILE		    S_AUTO_NEW_B
	    ERASE_FILE		    S_CONFIG_NEW_B
	    ERASE_FILE		    S_SELEXE_NEW_B
	    ERASE_FILE		    S_SELHLP_NEW_B
	    ERASE_FILE		    S_SELPRT_NEW_B
	    ERASE_FILE		    S_SELDAT_NEW_B
	    ; make config.sys and autoexec.bat
	    create_config	s_config_new_b, n_retcode
	    .if c
	    	goto install_error
	    .endif
	    create_autoexec	s_auto_new_b, e_dest_dos, n_retcode
	    .if c
	    	goto install_error
	    .endif

	    ;;; diskcopy OPERATE diskette to WORKING diskette
	    .REPEAT
		DISKCOPY_TO 	    DSKCPY_TO_B,SOURCE1,S_DOS_UTIL1_DISK
		DISKCOPY_PANELS	    SUB_INS_OP_WORK,SUB_COPYING,NOPANEL
	       INIT_VAR 	    N_DSKCPY_ERR,E_DSKCPY_OK
	       CALL		    HOOK_INT_2F
	       EXEC_PROGRAM	    S_DISKCOPY,S_DSKCPY_TO_B,PARM_BLOCK,EXEC_NO_DIR
	       CALL		    RESTORE_INT_2F
	       .IF < c >
		  GOTO	      INSTALL_ERROR
	       .ENDIF
	       .LEAVE < N_DSKCPY_ERR ne E_DSKCPY_RETRY >
	       INSERT_DISK	SUB_REM_DOS_A, S_DOS_SEL_360
	    .UNTIL

	    ;;;perhaps diskcopy MS-SHELL to SHELL
	    .IF < f_shell eq e_shell_yes > near
		.REPEAT
		    INSERT_DISK		SUB_REM_DOS_A, S_DOS_SEL_360
		    DISKCOPY_TO		DSKCPY_TO_B,SOURCE1,S_DOS_SHEL_DISK
		    DISKCOPY_PANELS	SUB_INS_SHELL_DISKS,SUB_COPYING,NOPANEL
		    INIT_VAR		N_DSKCPY_ERR,E_DSKCPY_OK
		    CALL		HOOK_INT_2F
		    EXEC_PROGRAM	S_DISKCOPY,S_DSKCPY_TO_B,PARM_BLOCK,EXEC_NO_DIR
		    CALL		RESTORE_INT_2F
		    .IF < c >
			GOTO		INSTALL_ERROR
		    .ENDIF
		.UNTIL < N_DSKCPY_ERR ne E_DSKCPY_RETRY >
		; make config.sys and autoexec.bat
		create_config	s_config_new_b, n_retcode
		.if c
		    goto install_error
		.endif
		create_autoexec	s_auto_new_b, e_dest_shell, n_retcode
		.if c
		    goto install_error
		.endif
		create_shell		s_shell_new_b, n_retcode
		.if c
		    goto install_error
		.endif
	    .ENDIF
	.ENDIF		; end if two drive 720 installation


	;;;installation complete and change diskettes screen
	INIT_PQUEUE		PAN_COMPLETE2
	PREPARE_PANEL		SUB_COMP_KYS_2
	DISPLAY_PANEL
	SAVE_PANEL_LIST
	GET_FUNCTION		FK_REBOOT
;;;;;;;;control will not return here. user has to reboot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	ENDS
	END
