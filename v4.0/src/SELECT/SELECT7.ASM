

PAGE 55,132							;AN000;
NAME	SELECT							;AN000;
TITLE	SELECT - DOS - SELECT.EXE				;AN000;
SUBTTL	SELECT7.asm						;AN000;
.ALPHA								;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SELECT7.ASM : Copyright 1988 Microsoft
;
;	DATE:	 August 8/87
;
;	COMMENTS: Assemble with MASM 3.0 (using the /A option)
;
;		  Panel flow is defined in the following files:
;
;		      � SELECT1.ASM
;		      ;AN000; SELECT2.ASM
;		      ;AN000; SELECT3.ASM
;		      ;AN000; SELECT4.ASM
;		      ;AN000; SELECT5.ASM
;		      ;AN000; SELECT6.ASM
;
;
;  Module contains code for :
;	- Format the drives
;	- Copy files
;
;	CHANGE HISTORY:
;
;	;AN009; DT  added support for creation of the DOSSHELL.BAT as a
;		    separately installed file.	(D233)
;	;AN002; GHG for P1146
;	;AN003; GHG for D234
;	;AN004; GHG for P65
;	;AN005; DT for single drive support
;	;AN006; JW for dos location choice (global or path only)
;	;AN007; JW fixed deletion of select.* when installation is to the root
;	;AN072; DT Overlay parser and pcinput if memory = 256KB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	SEGMENT BYTE PUBLIC 'DATA'                              ;AN000;
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
	INCLUDE    MACROS7.INC					;AN009;DT
	INCLUDE    EXT.INC					;AN000;
	INCLUDE    VARSTRUC.INC 				;AN000;
	INCLUDE    ROUT_EXT.INC 				;AN000;
.LIST								;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
								;
	EXTRN	DEALLOCATE_HELP:FAR				;AN000;DT
	EXTRN	DEALLOCATE_BLOCK:FAR				;AN000;DT
	EXTRN	ALLOCATE_BLOCK:FAR				;AN000;DT
	EXTRN	DEALLOCATE_MEMORY_CALL:FAR			;AN000;DT
	EXTRN	ALLOCATE_MEMORY_CALL:FAR			;AN000;DT
								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	SEGMENT PARA PUBLIC 'SELECT'                            ;AN000;
	ASSUME	CS:SELECT,DS:DATA				;AN000;
								;
	INCLUDE CASEXTRN.INC					;AN000;
								;
	EXTRN	EXIT_SELECT:near				;AN000;
	EXTRN	CREATE_CONFIG_SYS:NEAR				;AN000;
	EXTRN	CREATE_AUTOEXEC_BAT:NEAR			;AN000;
	EXTRN	CREATE_SHELL_BAT:NEAR				;AN009;DT
								;
	EXTRN	EXIT_DOS:near					;AN004;GHG
	EXTRN	INSTALL_ERROR:near				;AN004;GHG
	EXTRN	EXIT_SELECT:NEAR				;AN004;GHG
	EXTRN	PROCESS_ESC_F3:near				;AN004;GHG
	EXTRN	EXIT_DOS_CONT:NEAR				;AN004;GHG
								;
	PUBLIC	CONTINUE_360					;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	CODE CONTINUES.....
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;INSTALL 360KB DISKETTE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Display copying files from INSTALL diskette
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CONTINUE_360:							;AN000;
							      ;;;
							      ;;;
     .IF < N_DISKETTE_A eq E_DISKETTE_360 > near		;AN000;
								;
	INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	PREPARE_PANEL		SUB_COPYING			;AN000; prepare copying from diskette 2 message
	DISPLAY_PANEL						;AN000;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   DEALLOCATE_MEMORY					;AN000;DT
	.ENDIF							;AN000;DT
								;
	;;;S_STR120_1 = "a:*.* c:\path /a  parameter for REPLACE
	MERGE_STRING	     S_STR120_1,M_STR120_1,S_A_STARS,S_INSTALL_PATH ;AN000;
	APPEND_STRING	     S_STR120_1,M_STR120_1,S_SLASH_A	;AN000;
								;
;	.IF < I_DESTINATION eq E_ENTIRE_DISK >			;AN006;JW
;	.THEN							;AN006;
;	   ;;;S_STR120_3 = "a:*.* c:\ /s /r  parameter for REPLACE
;	   COPY_STRING	     S_STR120_3,M_STR120_3,S_REPLACE_PAR1     ;AN006;JW
;	.ELSE							;AN006;
	   ;;;S_STR120_3 = "a:*.* c:\<path> parameter for REPLACE
	   MERGE_STRING      S_STR120_3,M_STR120_3,S_A_STARS,S_INSTALL_PATH ;AN006;JW
	   APPEND_STRING     S_STR120_3,M_STR120_3,S_SLASH_R	;AN000;JW
;	.ENDIF							;AN006;
								;
	;;;change attributes of some files so they are not copied
	CHANGE_ATTRIBUTE     HIDE_STARTUP, E_HIDE_STARTUP	;AN000;
								;
	;;;replace files in drive C: with new files on INSTALL diskette
	EXEC_PROGRAM	     S_REPLACE,S_STR120_3,PARM_BLOCK,EXEC_DIR	 ;AN006;JW
	.IF c							;AN000;
	  .IF < MEM_SIZE eq 256 >				;AN000;DT
	     CALL  GET_OVERLAY					;AN000;DT Get panels
	  .ENDIF						;AN000;
	   HANDLE_ERROR        ERR_COPY_DISK, E_RETURN		;AN000;
	   RESTORE_ATTRIBUTE	HIDE_STARTUP,E_HIDE_STARTUP	;AN000;
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = "a:*.* C:\<path> /A"                    ;
	;;;copy NEW files on INSTALL diskette to install path	 ;
	EXEC_PROGRAM	     S_REPLACE,S_STR120_1,PARM_BLOCK,EXEC_DIR ;AN000; copy new files
	.IF c							;AN000;
	   .IF < MEM_SIZE eq 256 >				;AN000;DT
	      CALL  GET_OVERLAY 				;AN000;DT Get panels
	   .ENDIF						;AN000;
	   HANDLE_ERROR        ERR_COPY_DISK, E_RETURN		;AN000;
	   RESTORE_ATTRIBUTE	HIDE_STARTUP,E_HIDE_STARTUP	;AN000;
	.ENDIF							;AN000;
								;
	RESTORE_ATTRIBUTE    HIDE_STARTUP,E_HIDE_STARTUP	;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Prompt the user to remove the INSTALL (source) diskette
;	and insert the OPERATING 1 (source) diskette.
;
;;;;;;;;;;SHELL 360KB DISKETTE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   CALL  GET_OVERLAY					;AN000;DT Get panels
	.ENDIF							;AN000;
								;
	;;;insert OPERATING 1 diskette in drive A:		;
	INSERT_DISK	SUB_REM_SELECT_360, S_DOS_UTIL1_DISK	;AN000;JW
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Display copying files
;
;	NOTE:  The REPLACE command is now issued from the hard disk
;	       (since it is not found on any other disk)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	PREPARE_PANEL		SUB_COPYING			;AN000; prepare copying from diskette 2 message
	DISPLAY_PANEL						;AN000;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   DEALLOCATE_MEMORY					;AN000;DT
	.ENDIF							;AN000;DT
								;
	;;;S_STR120_1 = "a:*.* c:\path /a  parameter for REPLACE
	MERGE_STRING	     S_STR120_1,M_STR120_1,S_A_STARS,S_INSTALL_PATH ;AN000;
	APPEND_STRING	     S_STR120_1,M_STR120_1,S_SLASH_A	;AN000;
								;
	COMPARE_STRINGS      S_INSTALL_PATH, S_DEST_DRIVE	;AN000; compare to C:\
	.IF < nc >						;AN000; if the same
	    MERGE_STRING	 S_STR120_2,M_STR120_2,S_INSTALL_PATH,S_REPLACE   ;AN000;
	.ELSE							;AN000;
	    MERGE_STRING	 S_STR120_2,M_STR120_2,S_INSTALL_PATH,S_SLASH	  ;AN000;
	    APPEND_STRING	 S_STR120_2,M_STR120_2,S_REPLACE;AN000;
	.ENDIF							;AN000;
								;
	;;;replace files in drive C: with new files on OPERATING 1 diskette
	EXEC_PROGRAM	     S_STR120_2,S_STR120_3,PARM_BLOCK,EXEC_DIR	 ;AN006;JW
	.IF c							;AN000;
	  .IF < MEM_SIZE eq 256 >				;AN000;DT
	     CALL  GET_OVERLAY					;AN000;DT Get panels
	  .ENDIF						;AN000;
	   HANDLE_ERROR        ERR_COPY_DISK, E_RETURN		;AN000;
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = "a:*.* C:\<path> /A"                    ;
	;;;copy NEW files on OPERATING 1 diskette to install path
	EXEC_PROGRAM	     S_STR120_2,S_STR120_1,PARM_BLOCK,EXEC_DIR ;AN000; copy new files
	.IF c							;AN000;
	     .IF < MEM_SIZE eq 256 >				;AN000;DT
		CALL  GET_OVERLAY				;AN000;DT Get panels
	     .ENDIF						;AN000;
	      HANDLE_ERROR	  ERR_COPY_DISK, E_RETURN	;AN000;
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	insert the OPERATING #2 diskette.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   CALL  GET_OVERLAY					;AN000;DT Get panels
	.ENDIF							;AN000;DT
								;
	;;; insert OPERATING #2 diskette in drive A:		;
	INSERT_DISK		SUB_INS_OPER2, S_DOS_UTIL2_DISK	;AN000;JW
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	  Display copying files from OPERATING #2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	PREPARE_PANEL		SUB_COPYING			;AN000; prepare copying from diskette 1 message
	DISPLAY_PANEL						;AN000;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   DEALLOCATE_MEMORY					;AN000;DT
	.ENDIF							;AN000;DT
								;
	;;;replace files in drive C: with new files on OPERATING 2 diskette
	EXEC_PROGRAM	     S_STR120_2,S_STR120_3,PARM_BLOCK,EXEC_DIR ;AN006;JW
	.IF c							;AN000;
	  .IF < MEM_SIZE eq 256 >				;AN000;DT
	     CALL  GET_OVERLAY					;AN000;DT Get panels
	  .ENDIF						;AN000;
	   HANDLE_ERROR        ERR_COPY_DISK, E_RETURN		;AN000;
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = "a:*.* C:\<path> /A "                   ;
	;;;copy NEW files on OPERATING 2 diskette to install path
	EXEC_PROGRAM	     S_STR120_2,S_STR120_1,PARM_BLOCK,EXEC_DIR ;AN000; copy new files
	.IF c							;AN000;
	     .IF < MEM_SIZE eq 256 >				;AN000;DT
		CALL  GET_OVERLAY				;AN000;DT Get panels
	     .ENDIF						;AN000;
	      HANDLE_ERROR	  ERR_COPY_DISK, E_RETURN	;AN000;
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	insert the OPERATING #3 diskette.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   CALL  GET_OVERLAY					;AN000;DT Get panels
	.ENDIF							;AN000;DT
								;
	;;; insert OPERATING #3 diskette in drive A:		;
	INSERT_DISK		SUB_REM_UTIL1_360, S_DOS_UTIL3_DISK	;AN000;JW
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	  Display copying files from OPERATING #3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	PREPARE_PANEL		SUB_COPYING			;AN000; prepare copying from diskette 1 message
	DISPLAY_PANEL						;AN000;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   DEALLOCATE_MEMORY					;AN000;DT
	.ENDIF							;AN000;DT
								;
	;;;replace files in drive C: with new files on OPERATING 2 diskette
	EXEC_PROGRAM	     S_STR120_2,S_STR120_3,PARM_BLOCK,EXEC_DIR ;AN006;JW
	.IF c							;AN000;
	  .IF < MEM_SIZE eq 256 >				;AN000;DT
	     CALL  GET_OVERLAY					;AN000;DT Get panels
	  .ENDIF						;AN000;
	   HANDLE_ERROR        ERR_COPY_DISK, E_RETURN		;AN000;
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = "a:*.* C:\<path> /A "                   ;
	;;;copy NEW files on OPERATING 2 diskette to install path
	EXEC_PROGRAM	     S_STR120_2,S_STR120_1,PARM_BLOCK,EXEC_DIR ;AN000; copy new files
	.IF c							;AN000;
	     .IF < MEM_SIZE eq 256 >				;AN000;DT
		CALL  GET_OVERLAY				;AN000;DT Get panels
	     .ENDIF						;AN000;
	      HANDLE_ERROR	  ERR_COPY_DISK, E_RETURN	;AN000;
	.ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	insert the SELECT diskette.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   CALL  GET_OVERLAY					;AN000;DT Get panels
	.ELSE							;AN000;DT
	   ;;; insert the SELECT diskette in drive A		;
	   INSERT_DISK	SUB_REM_SHELL_360, S_DOS_SEL_360	;AN000;JW
	.ENDIF							;AN000;DT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	  Display copying files from SELECT diskette
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	PREPARE_PANEL		SUB_COPYING			;AN000; prepare copying from diskette 1 message
	DISPLAY_PANEL						;AN000;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   DEALLOCATE_MEMORY					;AN000;DT
	.ENDIF							;AN000;DT
								;
	;;;replace files in drive C: with new files on SELECT diskette
	EXEC_PROGRAM	     S_STR120_2,S_STR120_3,PARM_BLOCK,EXEC_DIR	 ;AN006;JW
	.IF c							;AN000;
	  .IF < MEM_SIZE eq 256 >				;AN000;DT
	     CALL  GET_OVERLAY					;AN000;DT Get panels
	  .ENDIF						;AN000;
	   HANDLE_ERROR        ERR_COPY_DISK, E_RETURN		;AN000;
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = "a:*.* C:\<path> /A "                   ;
	;;;copy new files on SELECT diskette to install path	;
	EXEC_PROGRAM	     S_STR120_2,S_STR120_1,PARM_BLOCK,EXEC_DIR;AN000; copy new files
	.IF c							;AN000;
	     .IF < MEM_SIZE eq 256 >				;AN000;DT
		CALL  GET_OVERLAY				;AN000;DT Get panels
	     .ENDIF						;AN000;
	      HANDLE_ERROR	  ERR_COPY_DISK, E_RETURN	;AN000;
	.ENDIF							;AN000;
								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	maybe insert the SHELL diskette.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.IF < f_shell eq e_shell_yes > near
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   CALL  GET_OVERLAY					;AN000;DT Get panels
	.ENDIF							;AN000;DT
								;
	INSERT_DISK	SUB_INS_MSSHELL_A, S_DOS_SHEL_DISK	;AN000;JW
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	  Display copying files from SHELL diskette
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	PREPARE_PANEL		SUB_COPYING			;AN000; prepare copying from diskette 1 message
	DISPLAY_PANEL						;AN000;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   DEALLOCATE_MEMORY					;AN000;DT
	.ENDIF							;AN000;DT
								;
	;;;replace files in drive C: with new files on SHELL diskette
	EXEC_PROGRAM	     S_STR120_2,S_STR120_3,PARM_BLOCK,EXEC_DIR	 ;AN006;JW
	.IF c							;AN000;
	  .IF < MEM_SIZE eq 256 >				;AN000;DT
	     CALL  GET_OVERLAY					;AN000;DT Get panels
	  .ENDIF						;AN000;
	   HANDLE_ERROR        ERR_COPY_DISK, E_RETURN		;AN000;
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = "a:*.* C:\<path> /A "                   ;
	;;;copy NEW files on SHELL diskette to install path
	EXEC_PROGRAM	     S_STR120_2,S_STR120_1,PARM_BLOCK,EXEC_DIR;AN000; copy new files
	.IF c							;AN000;
	     .IF < MEM_SIZE eq 256 >				;AN000;DT
		CALL  GET_OVERLAY				;AN000;DT Get panels
	     .ENDIF						;AN000;
	      HANDLE_ERROR	  ERR_COPY_DISK, E_RETURN	;AN000;
	.ENDIF							;AN000;

	.endif  	; optional shell support
								

	;Delete select files from C: drive			;
	COMPARE_STRINGS      S_INSTALL_PATH, S_DEST_DRIVE	;AN007; compare to C:\
	.IF <  nc >						;AN007; if installed to the root
	   MERGE_STRING 	S_STR120_1,M_STR120_1,S_C_DRIVE,S_SELDAT_C  ;AN000;
	   ERASE_FILE		S_STR120_1			;AN000;DT
	   MERGE_STRING 	S_STR120_1,M_STR120_1,S_C_DRIVE,S_SELEXE_C  ;AN000;
	   ERASE_FILE		S_STR120_1			;AN000;DT
	.ELSE near						;AN007; else installed to a directory
	   MERGE_STRING 	S_STR120_1,M_STR120_1,S_INSTALL_PATH,S_SELDAT_C   ;AN000;
	   ERASE_FILE		S_STR120_1			;AN000;DT
	   MERGE_STRING 	S_STR120_1,M_STR120_1,S_INSTALL_PATH,S_SELEXE_C   ;AN000;
	   ERASE_FILE		S_STR120_1			;AN000;DT
	   MERGE_STRING 	S_STR120_1,M_STR120_1,S_INSTALL_PATH,S_AUTOEX_C   ;AN000;
	   ERASE_FILE		S_STR120_1			;AN000;DT
	   MERGE_STRING 	S_STR120_1,M_STR120_1,S_INSTALL_PATH,S_CONSYS_C   ;AN000;
	   ERASE_FILE		S_STR120_1			;AN000;DT
	.ENDIF							;AN007;
								;
     .ENDIF							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;360KB;;;;360KB;;;;360KB;;;;360KB;;;;360KB;;;;360KB;;;;360KB;;
;
;			End of 360KB support
;
;	Installation completed.  inform user to reboot
;
;	Search for the installed CONFIG.340 , and
;	we issue a different panel to describe the '.340' files.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
								;
	.IF < MEM_SIZE eq 256 > 				;AN000;DT
	   ALLOCATE_MEMORY					;AN000;DT
	   CALL    INITIALIZE					;AN000;DT and read them in
	.ENDIF							;AN000;DT
								;
	INIT_PQUEUE		PAN_COMPLETE1			;AN000; initialize queue
	.IF < I_DESTINATION ne E_ENTIRE_DISK >			;AN010;JW
	   PREPARE_PANEL	PAN_PARTIAL			;AN010;JW
	.ELSE							;AN010;JW
	   FIND_FILE		   S_CONFIG_REN, E_FILE_ATTR	;AN003;GHG Look for '.340' files
	   .IF < c >						;AN003;GHG
	      PREPARE_PANEL	   SUB_COMP_VER 		;AN003;GHG prepare DOS install message
	   .ELSE						;AN003;GHG
	      PREPARE_PANEL	   SUB_COMP_REP 		;AN003;GHG prepare DOS Replace message
	   .ENDIF						;AN003;GHG
	.ENDIF							;AN010;
								;
	PREPARE_PANEL		SUB_COMP_KYS_1			;AN000;
	DISPLAY_PANEL						;AN000;
	SAVE_PANEL_LIST 					;AN000;
								;
	GET_FUNCTION		FK_REBOOT			;AN000; User has to reboot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PUBLIC GET_OVERLAY						;AN000;
GET_OVERLAY	PROC NEAR					;AN000;
	   .IF < N_DISKETTE_A ne E_DISKETTE_720 >		;AN063;SEH
	       CLEAR_SCREEN					;AN000;
	       DISPLAY_MESSAGE 12				;AN000;DT Insert SELECT diskette
	       .REPEAT						;AN000;
		   GET_FUNCTION 	   FK_ENT		;AN000; get user entered function
		   FIND_FILE		S_DOS_SEL_360, E_FILE_ATTR    ;AN000;
		   .LEAVE < nc >				;AN000;
			DISPLAY_MESSAGE 11			;AN000;DT Beep
	       .UNTIL						;AN000;
	   .ENDIF						;AN063;SEH
	   ALLOCATE_MEMORY					;AN000;DT
	   CALL    INITIALIZE					;AN000;DT and read them in
	   RET							;AN000;
GET_OVERLAY	ENDP						;AN000;
								;
SELECT	ENDS							;AN000;
	END							;AN000;
