

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
;	SEL_FILE.INC :	Copyright 1988 Microsoft
;
;	DATE:	 August 8/87
;
;	COMMENT: Module contains variables used by SELECT.
;
;	CHANGE HISTORY:
;
;	;AN002;   Removal of SHELL.BAT from copying from SHELL (Source)
;		  diskette (D233)!
;
;	;AN004;   360KB support (D65)
;
;	;AN005;JW - P2145, Had to move chkdsk to shell due to growth of dos files
;
;	;AN006;JW - P2261, Removal of unused utilities on startup disk
;
;	;AN007;JW - D354, Removal of FASTOPEN and RECOVER from startup disk
;
;	;AN008;JW - P	 , SELECT.HLP was not being hidden before copy
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Files found on INSTALL diskette
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
								;
	PUBLIC	COPY_SEL_EGA,E_SEL_EGA				;AN000;
COPY_SEL_EGA	LABEL	BYTE					;AN000;
	DB	'EGA.CPI     '                                  ;AN000;
E_SEL_EGA	EQU ( $ - COPY_SEL_EGA ) / 12			;AN000;
								;
	PUBLIC	COPY_SEL_LCD,E_SEL_LCD				;AN000;
COPY_SEL_LCD	LABEL	BYTE					;AN000;
	DB	'LCD.CPI     '                                  ;AN000;
E_SEL_LCD	EQU ( $ - COPY_SEL_LCD ) / 12			;AN000;
								;
	PUBLIC	COPY_SEL_SHEL,E_SEL_SHEL			;AN000;
COPY_SEL_SHEL	LABEL	BYTE					;AN000;
	DB	'COMMAND.COM '                                  ;AN000;
E_SEL_SHEL	EQU ( $ - COPY_SEL_SHEL) / 12			;AN000;
								;
	PUBLIC	COPY_INST_1200_1440,E_INST_1200_1440		;AN000;
COPY_INST_1200_1440	LABEL	BYTE				;AN000; this will copy files for 1.44M diskettes
								;
	DB	'ANSI.SYS    '                                  ;AN000;
	DB	'COMMAND.COM '                                  ;AN000;
	DB	'COUNTRY.SYS '                                  ;AN000;
	DB	'DISKCOPY.COM'                                  ;AN001;GHG
	DB	'DISPLAY.SYS '                                  ;AN000;
	DB	'DRIVER.SYS  '                                  ;AN000;
	DB	'EGA.CPI     '
	DB	'FORMAT.COM  '                                  ;AN000;
	DB	'GRAFTABL.COM'
	DB	'GRAPHICS.COM'
	DB	'GRAPHICS.PRO'
	DB	'KEYB.COM    '                                  ;AN000;
	DB	'KEYBOARD.SYS'                                  ;AN000;
	DB	'LCD.CPI     '
	DB	'MODE.COM    '                                  ;AN000;
	DB	'NLSFUNC.EXE '
	DB	'PRINT.COM   '
	DB	'PRINTER.SYS '                                  ;AN000;
	DB	'RAMDRIVE.SYS'                                  ;AN000;
	DB	'4201.CPI    '                                  ;AN000;
	DB	'5202.CPI    '                                  ;AN000;
	DB	'4208.CPI    '                                  ;AN000
	DB	'REPLACE.EXE '
	DB	'SHARE.EXE   '                                  ;AC055
	DB	'SYS.COM     '                                  ;AN000;
								;
E_INST_1200_1440 EQU	( $ - COPY_INST_1200_1440 ) / 12 	;AN000; end of list for 1.44M diskettes
								;
								;
		PUBLIC	HIDE_SEL,E_HIDE_SEL			;AN000;
HIDE_SEL	DB	'AUTOEXEC.BAT',?,?                      ;AN000;
		DB	'CONFIG.SYS  ',?,?                      ;AN000;
		DB	'SELECT.PRT  ',?,?                      ;AN000;
		DB	'SELECT.EXE  ',?,?                      ;AN000;
		DB	'SELECT.DAT  ',?,?                      ;AN000;
		DB	'SELECT.HLP  ',?,?                      ;AN008;JW
E_HIDE_SEL	EQU	($ - HIDE_SEL) / 14			;AN000;
								;
		PUBLIC	HIDE_STARTUP,E_HIDE_STARTUP		;AN000;
HIDE_STARTUP	DB	'AUTOEXEC.BAT',?,?                      ;AN000;
		DB	'CONFIG.SYS  ',?,?                      ;AN000;
		DB	'SELECT.COM  ',?,?                      ;AN000;
		DB	'SELECT.HLP  ',?,?                      ;AN000;
		DB	'SELECT.PRT  ',?,?                      ;AN000;
E_HIDE_STARTUP	EQU	($ - HIDE_STARTUP) / 14 		;AN000;
								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Files found on OPERATE diskette
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
								;
	PUBLIC	COPY_OPER_1200_1440,E_OPER_1200_1440		;AN000;
COPY_OPER_1200_1440	LABEL	BYTE				;AN000; this will copy files to 1.2M $ 1.44M diskettes
								;
	DB	'APPEND.EXE  '                                  ;AN000;
	DB	'ASSIGN.COM  '                                  ;AN000;
	DB	'ATTRIB.EXE  '                                  ;AN000;
	DB	'BACKUP.COM  '
	DB	'CHKDSK.COM  '
	DB	'COMP.COM    '                                  ;AN000;
	DB	'DEBUG.COM   '                                  ;AN000;
	DB	'DISKCOMP.COM'                                  ;AN000;
	DB	'EDLIN.COM   '                                  ;AN000;
	DB	'EXE2BIN.EXE '
	DB	'FC.EXE      '
	DB	'FILESYS.EXE '
	DB	'FIND.EXE    '                                  ;AN000;
	DB	'GWBASIC.EXE '
	DB	'IFSFUNC.EXE '
	DB	'JOIN.EXE    '                                  ;AN000;
	DB	'LABEL.COM   '                                  ;AN000;
	DB	'LINK.EXE    '
	DB	'MEM.EXE     '                                  ;AN000;
	DB	'MODE.COM    '                                  ;AN000;
	DB	'MORE.COM    '                                  ;AN000;
	DB	'RECOVER.COM '                                  ;AN000;
	DB	'RESTORE.COM '
	DB	'SORT.EXE    '                                  ;AN000;
	DB	'SUBST.EXE   '                                  ;AN000;
	DB	'TREE.COM    '                                  ;AN000;
	DB	'XCOPY.EXE   '
E_OPER_1200_1440 EQU	( $ - COPY_OPER_1200_1440 ) / 12	;AN000;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Files found on MS-SHELL diskette
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
								;
	PUBLIC	COPY_SHELL_1200_1440,E_SHELL_1200_1440		;AN000;
COPY_SHELL_1200_1440	LABEL	BYTE				;AN000; this will copy files to 1.2M $ 1.44M diskettes
								;
	DB	'SHELL.CLR   '                                  ;AN000;
	DB	'SHELL.HLP   '                                  ;AN000;
	DB	'SHELL.MEU   '                                  ;AN000;
	DB	'SHELLB.COM  '                                  ;AN000;
	DB	'SHELLC.EXE  '                                  ;AN000;
	DB	'DOSUTIL.MEU '                                  ;AN000;DT
E_SHELL_1200_1440 EQU	( $ - COPY_SHELL_1200_1440 ) / 12	;AN000;
								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Files which will be unique on ship/install diskettes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		PUBLIC	S_DOS_SHEL_DISK 			;AN000;
S_DOS_SHEL_DISK DW	M_DOS_SHEL_DISK 			;AN000;
P_DOS_SHEL_DISK DB	'SHELLC.EXE '                           ;AN000;
M_DOS_SHEL_DISK EQU	$ - P_DOS_SHEL_DISK - 1 		;AN000;
								;
		PUBLIC	S_DOS_SEL_360				;AN000;GHG
S_DOS_SEL_360	DW	M_DOS_SEL_360				;AN000;GHG
P_DOS_SEL_360	DB	'SELECT.EXE '                           ;AN000;GHG
M_DOS_SEL_360	EQU	$ - P_DOS_SEL_360 - 1			;AN000;GHG
								;GHG
		PUBLIC	S_DOS_UTIL1_DISK			;AN000;GHG
S_DOS_UTIL1_DISK DW	 M_DOS_UTIL1_DISK			;AN000;GHG
P_DOS_UTIL1_DISK DB	 'ATTRIB.EXE '                          ;AN000;GHG
M_DOS_UTIL1_DISK EQU	 $ - P_DOS_UTIL1_DISK - 1		;AN000;GHG
								;GHG
		PUBLIC	S_DOS_UTIL2_DISK			;AN000;GHG
S_DOS_UTIL2_DISK DW	 M_DOS_UTIL2_DISK			;AN000;GHG
P_DOS_UTIL2_DISK DB	 'GWBASIC.EXE '                          ;AN000;GHG
M_DOS_UTIL2_DISK EQU	 $ - P_DOS_UTIL2_DISK - 1		;AN000;GHG
								;GHG
		PUBLIC	S_DOS_UTIL3_DISK			;AN000;GHG
S_DOS_UTIL3_DISK DW	 M_DOS_UTIL3_DISK			;AN000;GHG
P_DOS_UTIL3_DISK DB	 'DRIVER.SYS '                          ;AN000;GHG
M_DOS_UTIL3_DISK EQU	 $ - P_DOS_UTIL3_DISK - 1		;AN000;GHG

		PUBLIC	S_DOS_COM_360				;AN000;GHG
S_DOS_COM_360	DW	M_DOS_COM_360				;AN000;GHG
P_DOS_COM_360	DB	'SELECT.COM '                           ;AN000;GHG
M_DOS_COM_360	EQU	$ - P_DOS_COM_360 - 1			;AN000;GHG
								;GHG
		PUBLIC	E_FILE_ATTR				;AN000;
E_FILE_ATTR	EQU	00H					;AN000; attribute not important
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		PUBLIC	S_COMMAND_COM				;AN017;
S_COMMAND_COM	DW	M_COMMAND_COM				;AN017;
P_COMMAND_COM	DB	'C:\COMMAND.COM '                       ;AN017;
M_COMMAND_COM	EQU	$ - P_COMMAND_COM - 1			;AN017;
								;
		PUBLIC	S_SELECT_TMP				;AN000;
S_SELECT_TMP	DW	M_SELECT_TMP				;AN000;
P_SELECT_TMP	DB	'SELECT.TMP '                           ;AN000;
M_SELECT_TMP	EQU	$ - P_SELECT_TMP - 1			;AN000; space for ASCII-Z conversion
								;
		PUBLIC	S_PRINT_FILE,M_PRINT_FILE		;AN000;
S_PRINT_FILE	DW	M_PRINT_FILE				;AN000;GHG  NAME OF THE SELECT PRINTER
P_PRINT_FILE	DB	'SELECT.PRT '                           ;AN000;GHG  PROFILE. - space for ASCII-Z conversion
M_PRINT_FILE	EQU	$-P_PRINT_FILE-1			;AN000;GHG
								;
		PUBLIC	S_AUTO_NEW, S_CONFIG_NEW		;AN000;
S_AUTO_NEW	DW	M_AUTO_NEW				;AN000;
P_AUTO_NEW	DB	'AUTOEXEC.400 '                         ;AN003;GHG Temporary
M_AUTO_NEW	EQU	$ - P_AUTO_NEW - 1			;AN003;GHG AUTOEXEC.BAT
								;
S_CONFIG_NEW	DW	M_CONFIG_NEW				;AN000;
P_CONFIG_NEW	DB	'CONFIG.400 '                           ;AN003;GHG Temporary
M_CONFIG_NEW	EQU	$ - P_CONFIG_NEW - 1			;AN003;GHG CONFIG
								;
		PUBLIC	S_OS2_CONFIG_C, S_OS2_AUTO_C		;AN065;SEH
S_OS2_CONFIG_C	DW	M_OS2_CONFIG_C				;AN065;SEH rename OS2's config.sys
P_OS2_CONFIG_C	DB	'C:\CONFIG.OS2 '                        ;AN065;SEH
M_OS2_CONFIG_C	EQU	$ - P_OS2_CONFIG_C - 1			;AN065;SEH
								;
S_OS2_AUTO_C	DW	M_OS2_AUTO_C				;AN065;SEH rename OS2's autoexec.bat
P_OS2_AUTO_C	DB	'C:\AUTOEXEC.OS2 '                      ;AN065;SEH
M_OS2_AUTO_C	EQU	$ - P_OS2_AUTO_C - 1			;AN065;SEH
								;
		PUBLIC	S_SHELL_NEW				;AN000;DT
S_SHELL_NEW	DW	M_SHELL_NEW				;AN000;DT
P_SHELL_NEW	DB	'DOSSHELL.BAT '                         ;AC019;SEH ;AN000;DT space for ASCII-Z conversion
M_SHELL_NEW	EQU	$ - P_SHELL_NEW - 1			;AN000;DT
								;
		PUBLIC	S_SHELL_NEW_B				;AN000;DT
S_SHELL_NEW_B	DW	M_SHELL_NEW_B				;AN000;DT
P_SHELL_NEW_B	DB	'B:\DOSSHELL.BAT '                      ;AC019;SEH ;AN000;DT space for ASCII-Z conversion
M_SHELL_NEW_B	EQU	$ - P_SHELL_NEW_B - 1			;AN000;DT
								;
		PUBLIC	S_AUTO_NEW_B, S_CONFIG_NEW_B		;AN000;
S_AUTO_NEW_B	DW	M_AUTO_NEW_B				;AN000;
P_AUTO_NEW_B	DB	'B:\AUTOEXEC.BAT '                      ;AN000; space for ASCII-Z conversion
M_AUTO_NEW_B	EQU	$ - P_AUTO_NEW_B - 1			;AN000;
								;
S_CONFIG_NEW_B	DW	M_CONFIG_NEW_B				;AN000;
P_CONFIG_NEW_B	DB	'B:\CONFIG.SYS '                        ;AN000; space for ASCII-Z conversion
M_CONFIG_NEW_B	EQU	$ - P_CONFIG_NEW_B - 1			;AN000;
								;
		PUBLIC	S_AUTO_REN, S_CONFIG_REN		;AN000;
S_AUTO_REN	DW	M_AUTO_REN				;AN000;
P_AUTO_REN	DB	'C:\AUTOEXEC.400 '                      ;AN003;GHG
M_AUTO_REN	EQU	$ - P_AUTO_REN - 1			;AN000;
								;
S_CONFIG_REN	DW	M_CONFIG_REN				;AN000;
P_CONFIG_REN	DB	'C:\CONFIG.400 '                        ;AN003;GHG
M_CONFIG_REN	EQU	$ - P_CONFIG_REN - 1			;AN000;
								;
		PUBLIC	S_AUTO_C, S_CONFIG_C			;AN000;
S_AUTO_C	DW	M_AUTO_C				;AN000;
P_AUTO_C	DB	'C:\AUTOEXEC.BAT '                      ;AN000; space for ASCII-Z conversion
M_AUTO_C	EQU	$ - P_AUTO_C - 1			;AN000;
								;
S_CONFIG_C	DW	M_CONFIG_C				;AN000;
P_CONFIG_C	DB	'C:\CONFIG.SYS '                        ;AN000; space for ASCII-Z conversion
M_CONFIG_C	EQU	$ - P_CONFIG_C - 1			;AN000;
								;
		PUBLIC	S_AUTO_NEW_C, S_CONFIG_NEW_C		;AN000;
S_AUTO_NEW_C	DW	M_AUTO_NEW_C				;AN000;
P_AUTO_NEW_C	DB	'C:AUTOEXEC.BAT '                       ;AN000; space for ASCII-Z conversion
M_AUTO_NEW_C	EQU	$ - P_AUTO_NEW_C - 1			;AN000;
								;
S_CONFIG_NEW_C	DW	M_CONFIG_NEW_C				;AN000;
P_CONFIG_NEW_C	DB	'C:CONFIG.SYS '                         ;AN000; space for ASCII-Z conversion
M_CONFIG_NEW_C	EQU	$ - P_CONFIG_NEW_C - 1			;AN000;
								;
		PUBLIC	S_AUTO_REBOOT				;AN000;
S_AUTO_REBOOT	DW	M_AUTO_REBOOT				;AN000;
P_AUTO_REBOOT	DB	'AUTOEXEC.BAT '                         ;AN000;
M_AUTO_REBOOT	EQU	$ - P_AUTO_REBOOT - 1			;AN000;
								;
		PUBLIC	S_AUTO_MENU				;AN000;
S_AUTO_MENU	DW	M_AUTO_MENU				;AN000;
P_AUTO_MENU	DB	'MENU'                                  ;AN000;
M_AUTO_MENU	EQU	$ - P_AUTO_MENU 			;AN000;
								;
		PUBLIC	S_AUTO_FDISK				;AN000;
S_AUTO_FDISK	DW	M_AUTO_FDISK				;AN000;
P_AUTO_FDISK	DB	'FDISK'                                 ;AN000;
M_AUTO_FDISK	EQU	$ - P_AUTO_FDISK			;AN000;
								;
		PUBLIC	S_CONFIG_AUTO, E_FILES			;AN000;
S_CONFIG_AUTO	DB	'CONFIG.400  '                          ;AN000;
		DB	'AUTOEXEC.400'                          ;AN000;
E_FILES 	EQU	($ - S_CONFIG_AUTO) / 12		;AN000;
								;
		PUBLIC	S_SHELL2, SH_FILES			;AN000;
S_SHELL2	DB	'DOSSHELL.BAT'                          ;AC019;SEH ;AN000;
SH_FILES	EQU	($ - S_SHELL2) / 12			;AN000;
								;
		PUBLIC	S_KEYB					;AN000;
S_KEYB		DW	M_KEYB					;AN000;
P_KEYB		DB	'KEYB.COM '                             ;AN000; KEYB command - space at end for ASCII-Z
M_KEYB		EQU	$ - P_KEYB - 1				;AN000;
								;
		PUBLIC	S_FDISK 				;AN000;
S_FDISK 	DW	M_FDISK 				;AN000;
P_FDISK 	DB	'FDISK.EXE '                            ;AC042;SEH ;AN000; FDISK command - space at end for ASCII-Z
M_FDISK 	EQU	$ - P_FDISK - 1 			;AN000;
								;
		PUBLIC	S_DISKCOPY				;AN000;
S_DISKCOPY	DW	M_DISKCOPY				;AN000;
P_DISKCOPY	DB	'DISKCOPY.COM '                         ;AN000; DISKCOPY command - space at end for ASCII-Z
M_DISKCOPY	EQU	$ - P_DISKCOPY - 1			;AN000;
								;
		PUBLIC	S_DISKCOPY_PARM 			;AN000;
S_DISKCOPY_PARM DW	M_DISKCOPY_PARM 			;AN000;
P_DISKCOPY_PARM DB	' A: A:'                                ;AN000;
M_DISKCOPY_PARM EQU	$ - P_DISKCOPY_PARM			;AN000;
								;
		PUBLIC	SC_1, SC_2				;AN000;
SC_1		DW	MC_1					;AN000; disk number 1
PC_1		DB	'1 '                                    ;AN000;
MC_1		EQU	$ - PC_1				;AN000;
SC_2		DW	MC_2					;AN000; disk number 2
PC_2		DB	'2 '                                    ;AN000;
MC_2		EQU	$ - PC_2				;AN000;
								;
		PUBLIC	SC_PRI,SC_EXT,SC_LOG			;AN000;
SC_PRI		DW	MC_PRI					;AN000; DOS parameter for FDSIK command
PC_PRI		DB	' /PRI:'                                ;AN000;
MC_PRI		EQU	$ - PC_PRI				;AN000;
SC_EXT		DW	MC_EXT					;AN000;
PC_EXT		DB	' /EXT:'                                ;AN000;
MC_EXT		EQU	$ - PC_EXT				;AN000;
SC_LOG		DW	MC_LOG					;AN000;
PC_LOG		DB	' /LOG:'                                ;AN000;
MC_LOG		EQU	$ - PC_LOG				;AN000;
								;
		PUBLIC	S_FORMAT				;AN000;
S_FORMAT	DW	M_FORMAT				;AN000;
P_FORMAT	DB	'FORMAT.COM '                           ;AN000; FORMAT command - space at end for ASCII-Z
M_FORMAT	EQU	$ - P_FORMAT - 1			;AN000;
								;
		PUBLIC	S_DRIVE_C				;AN000;
S_DRIVE_C	DW	M_DRIVE_C				;AN000;
P_DRIVE_C	DB	'C:'                                    ;AN000;
M_DRIVE_C	EQU	$ - P_DRIVE_C				;AN000;
								;
		PUBLIC	S_FORMAT_B				;AN000;
S_FORMAT_B	DW	M_FORMAT_B				;AN000;
P_FORMAT_B	DB	'B: /S /V:DOS400 /SELECT '              ;AN000;
M_FORMAT_B	EQU	$ - P_FORMAT_B				;AN000;
								;
		PUBLIC	S_FORMAT_A				;AN111;JW
S_FORMAT_A	DW	M_FORMAT_A				;AN111;JW
P_FORMAT_A	DB	'A: /S /V:DOS400 /SELECT '              ;AN111;JW
M_FORMAT_A	EQU	$ - P_FORMAT_A				;AN111;JW
								;
		PUBLIC	S_REPLACE				;AN000;
S_REPLACE	DW	M_REPLACE				;AN000;
P_REPLACE	DB	'REPLACE.EXE '                          ;AN000; space at end for ASCIII-Z string
M_REPLACE	EQU	$ - P_REPLACE - 1			;AN000;
								;
		PUBLIC	S_REPLACE_PAR1				;AN000;
S_REPLACE_PAR1	DW	M_REPLACE_PAR1				;AN000;
P_REPLACE_PAR1	DB	'A:*.* C:\ /S /R '                      ;AC000;JW
M_REPLACE_PAR1	EQU	$ - P_REPLACE_PAR1			;AN000;
								;
		PUBLIC	S_SLASH_R				;AN000;JW
S_SLASH_R	DW	M_SLASH_R				;AN000;JW
P_SLASH_R	DB	' /R'                                   ;AN000;JW
M_SLASH_R	EQU	$ - P_SLASH_R				;AN000;JW
								;
		PUBLIC	S_A_STARS				;AN000;
S_A_STARS	DW	M_A_STARS				;AN000;
P_A_STARS	DB	'A:*.* '                                ;AN000;
M_A_STARS	EQU	$ - P_A_STARS				;AN000;
								;
		PUBLIC	S_SLASH_A				;AN000;
S_SLASH_A	DW	M_SLASH_A				;AN000;
P_SLASH_A	DB	' /A'                                   ;AN000;
M_SLASH_A	EQU	$ - P_SLASH_A				;AN000;
								;
		PUBLIC	S_SLASH_S				;AN000;
S_SLASH_S	DW	M_SLASH_S				;AN000;
P_SLASH_S	DB	' /S'                                   ;AN000;
M_SLASH_S	EQU	$ - P_SLASH_S				;AN000;
								;
		PUBLIC	S_SLASH_Q				;AN000;
S_SLASH_Q	DW	M_SLASH_Q				;AN000;
P_SLASH_Q	DB	' /Q'                                   ;AN000;
M_SLASH_Q	EQU	$ - P_SLASH_Q				;AN000;
								;
		PUBLIC	S_COLON 				;AN000;
S_COLON 	DW	M_COLON 				;AN000;
P_COLON 	DB	':'                                     ;AN000;
M_COLON 	EQU	$ - P_COLON				;AN000;
								;
		PUBLIC	S_SYS_C 				;AN000;
S_SYS_C 	DW	M_SYS_C 				;AN000;
P_SYS_C 	DB	'SYS.COM '                              ;AN000; space dor ASCII-Z conversion
M_SYS_C 	EQU	$ - P_SYS_C - 1 			;AN000;
								;
		PUBLIC	S_VOL_SEL				;AN000;
S_VOL_SEL	DW	M_VOL_SEL				;AN000;
P_VOL_SEL	DB	' /V:DOS400 /SELECT '                   ;AN000;
M_VOL_SEL	EQU	$ - P_VOL_SEL				;AN000;
								;
		PUBLIC	S_PREP_EGA				;AN000;
S_PREP_EGA	DW	M_PREP_EGA				;AN000;
P_PREP_EGA	DB	'CON CP PREP=((850) EGA.CPI)'           ;AN000;
M_PREP_EGA	EQU	$ - P_PREP_EGA				;AN000;
								;
		PUBLIC	S_PREP_LCD				;AN000;
S_PREP_LCD	DW	M_PREP_LCD				;AN000;
P_PREP_LCD	DB	'CON CP PREP=((850) LCD.CPI)'           ;AN000;
M_PREP_LCD	EQU	$ - P_PREP_LCD				;AN000;
								;
		PUBLIC	S_CP_SEL				;AN000;
S_CP_SEL	DW	M_CP_SEL				;AN000;
P_CP_SEL	DB	'CON CP SEL=850'                        ;AN000;
M_CP_SEL	EQU	$ - P_CP_SEL				;AN000;
								;
		PUBLIC	S_MODE					;AN000;
S_MODE		DW	M_MODE					;AN000;
P_MODE		DB	'MODE.COM '                             ;AN000; Space at end of ASCII-Z conversion
M_MODE		EQU	$ - P_MODE-1				;AN000;
								;
		PUBLIC	S_SLASH 				;AN000;DT
S_SLASH 	DW	M_SLASH 				;AN000;DT
P_SLASH 	DB	'\'                                     ;AN000;DT
M_SLASH 	EQU	$ - P_SLASH				;AN000;DT
								;AN000;DT
		PUBLIC	S_DSKCPY_TO_B				;AN000;
S_DSKCPY_TO_B DW      M_DSKCPY_TO_B				;AN000;
P_DSKCPY_TO_B DB      ' A: B:'                                  ;AN000;
M_DSKCPY_TO_B EQU     $ - P_DSKCPY_TO_B 			;AN000;
								;
		PUBLIC	S_SELCOM_NEW_B				;AN004;DT
S_SELCOM_NEW_B	DW	M_SELCOM_NEW_B				;AN004;DT
P_SELCOM_NEW_B	DB	'B:\SELECT.COM '                        ;AN004;DT space for ASCII-Z conversion
M_SELCOM_NEW_B	EQU	$ - P_SELCOM_NEW_B - 1			;AN004;DT
								;AN004;DT
		PUBLIC	S_SELHLP_NEW_B				;AN004;DT
S_SELHLP_NEW_B	DW	M_SELHLP_NEW_B				;AN004;DT
P_SELHLP_NEW_B	DB	'B:\SELECT.HLP '                        ;AN004;DT space for ASCII-Z conversion
M_SELHLP_NEW_B	EQU	$ - P_SELHLP_NEW_B - 1			;AN004;DT
								;AN004;DT
		PUBLIC	S_SELPRT_NEW_B				;AN004;DT
S_SELPRT_NEW_B	DW	M_SELPRT_NEW_B				;AN004;DT
P_SELPRT_NEW_B	DB	'B:\SELECT.PRT '                        ;AN004;DT space for ASCII-Z conversion
M_SELPRT_NEW_B	EQU	$ - P_SELPRT_NEW_B - 1			;AN004;DT
								;
		PUBLIC	S_SELEXE_NEW_B				;AN004;DT
S_SELEXE_NEW_B	DW	M_SELEXE_NEW_B				;AN004;DT
P_SELEXE_NEW_B	DB	'B:\SELECT.EXE '                        ;AN004;DT space for ASCII-Z conversion
M_SELEXE_NEW_B	EQU	$ - P_SELEXE_NEW_B - 1			;AN004;DT
								;
		PUBLIC	S_SELDAT_NEW_B				;AN004;DT
S_SELDAT_NEW_B	DW	M_SELDAT_NEW_B				;AN004;DT
P_SELDAT_NEW_B	DB	'B:\SELECT.DAT '                        ;AN004;DT space for ASCII-Z conversion
M_SELDAT_NEW_B	EQU	$ - P_SELDAT_NEW_B - 1			;AN004;DT
								;
		PUBLIC	S_SELDAT_C				;AN004;DT  Used to erase from C: after 360KB install
S_SELDAT_C	DW	M_SELDAT_C				;AN004;DT
P_SELDAT_C	DB	'\SELECT.DAT '                          ;AN004;DT space for ASCII-Z conversion
M_SELDAT_C	EQU	$ - P_SELDAT_C - 1			;AN004;DT
								;
		PUBLIC	S_SELCOM_C				;AN004;DT
S_SELCOM_C	DW	M_SELCOM_C				;AN004;DT
P_SELCOM_C	DB	'\SELECT.COM '                          ;AN004;DT space for ASCII-Z conversion
M_SELCOM_C	EQU	$ - P_SELCOM_C - 1			;AN004;DT
								;
		PUBLIC	S_SELHLP_C				;AN004;DT
S_SELHLP_C	DW	M_SELHLP_C				;AN004;DT
P_SELHLP_C	DB	'\SELECT.HLP '                          ;AN004;DT space for ASCII-Z conversion
M_SELHLP_C	EQU	$ - P_SELHLP_C - 1			;AN004;DT
								;
		PUBLIC	S_SELPRT_C				;AN004;DT
S_SELPRT_C	DW	M_SELPRT_C				;AN004;DT
P_SELPRT_C	DB	'\SELECT.PRT '                          ;AN004;DT space for ASCII-Z conversion
M_SELPRT_C	EQU	$ - P_SELPRT_C - 1			;AN004;DT
								;
		PUBLIC	S_SELEXE_C				;AN004;DT
S_SELEXE_C	DW	M_SELEXE_C				;AN004;DT
P_SELEXE_C	DB	'\SELECT.EXE '                          ;AN004;DT space for ASCII-Z conversion
M_SELEXE_C	EQU	$ - P_SELEXE_C - 1			;AN004;DT
								;
		PUBLIC	S_AUTOEX_C				;AN004;DT
S_AUTOEX_C	DW	M_AUTOEX_C				;AN004;DT
P_AUTOEX_C	DB	'\AUTOEXEC.BAT '                        ;AN004;DT space for ASCII-Z conversion
M_AUTOEX_C	EQU	$ - P_AUTOEX_C - 1			;AN004;DT
								;
		PUBLIC	S_CONSYS_C				;AN004;DT
S_CONSYS_C	DW	M_CONSYS_C				;AN004;DT
P_CONSYS_C	DB	'\CONFIG.SYS '                          ;AN004;DT space for ASCII-Z conversion
M_CONSYS_C	EQU	$ - P_CONSYS_C - 1			;AN004;DT
								;
		PUBLIC	S_VDISK_B				;AN006;JW
S_VDISK_B	DW	M_VDISK_B				;AN006;JW
P_VDISK_B	DB	'B:\RAMDRIVE.SYS '                      ;AN006;JW space for ASCII-Z conversion
M_VDISK_B	EQU	$ - P_VDISK_B - 1			;AN006;JW
								;
		PUBLIC	S_ANSI_B				;AN006;JW
S_ANSI_B	DW	M_ANSI_B				;AN006;JW
P_ANSI_B	DB	'B:\ANSI.SYS '                          ;AN006;JW space for ASCII-Z conversion
M_ANSI_B	EQU	$ - P_ANSI_B - 1			;AN006;JW
								;
		PUBLIC	S_APPEND_B				;AN006;JW
S_APPEND_B	DW	M_APPEND_B				;AN006;JW
P_APPEND_B	DB	'B:\APPEND.EXE '                        ;AN006;JW space for ASCII-Z conversion
M_APPEND_B	EQU	$ - P_APPEND_B - 1			;AN006;JW
								;
		PUBLIC	S_GRAFTABL_B				;AN006;JW
S_GRAFTABL_B	DW	M_GRAFTABL_B				;AN006;JW
P_GRAFTABL_B	DB	'B:\GRAFTABL.COM '                      ;AN006;JW space for ASCII-Z conversion
M_GRAFTABL_B	EQU	$ - P_GRAFTABL_B - 1			;AN006;JW
								;
		PUBLIC	S_GRAPHICS_B				;AN006;JW
S_GRAPHICS_B	DW	M_GRAPHICS_B				;AN006;JW
P_GRAPHICS_B	DB	'B:\GRAPHICS.COM '                      ;AN006;JW space for ASCII-Z conversion
M_GRAPHICS_B	EQU	$ - P_GRAPHICS_B - 1			;AN006;JW
								;
		PUBLIC	S_GRAPHPRO_B				;AN006;JW
S_GRAPHPRO_B	DW	M_GRAPHPRO_B				;AN006;JW
P_GRAPHPRO_B	DB	'B:\GRAPHICS.PRO '                      ;AN006;JW space for ASCII-Z conversion
M_GRAPHPRO_B	EQU	$ - P_GRAPHPRO_B - 1			;AN006;JW
								;
		PUBLIC	S_RECOVER_B				;AN007;JW
S_RECOVER_B	DW	M_RECOVER_B				;AN007;JW
P_RECOVER_B	DB	'B:\RECOVER.COM '                       ;AN007;JW space for ASCII-Z conversion
M_RECOVER_B	EQU	$ - P_RECOVER_B - 1			;AN007;JW
								;
		PUBLIC	S_FASTOPEN_B				;AN007;JW
S_FASTOPEN_B	DW	M_FASTOPEN_B				;AN007;JW
P_FASTOPEN_B	DB	'B:\FASTOPEN.EXE '                      ;AN007;JW space for ASCII-Z conversion
M_FASTOPEN_B	EQU	$ - P_FASTOPEN_B - 1			;AN007;JW
								;
		PUBLIC	S_VDISK_C				;AN006;JW
S_VDISK_C	DW	M_VDISK_C				;AN006;JW
P_VDISK_C	DB	'\RAMDRIVE.SYS '                        ;AN006;JW space for ASCII-Z conversion
M_VDISK_C	EQU	$ - P_VDISK_C - 1			;AN006;JW
								;
		PUBLIC	S_ANSI_C				;AN006;JW
S_ANSI_C	DW	M_ANSI_C				;AN006;JW
P_ANSI_C	DB	'\ANSI.SYS '                            ;AN006;JW space for ASCII-Z conversion
M_ANSI_C	EQU	$ - P_ANSI_C - 1			;AN006;JW
								;
		PUBLIC	S_APPEND_C				;AN006;JW
S_APPEND_C	DW	M_APPEND_C				;AN006;JW
P_APPEND_C	DB	'\APPEND.EXE '                          ;AN006;JW space for ASCII-Z conversion
M_APPEND_C	EQU	$ - P_APPEND_C - 1			;AN006;JW
								;
		PUBLIC	S_GRAFTABL_C				;AN006;JW
S_GRAFTABL_C	DW	M_GRAFTABL_C				;AN006;JW
P_GRAFTABL_C	DB	'\GRAFTABL.COM '                        ;AN006;JW space for ASCII-Z conversion
M_GRAFTABL_C	EQU	$ - P_GRAFTABL_C - 1			;AN006;JW
								;
		PUBLIC	S_GRAPHICS_C				;AN006;JW
S_GRAPHICS_C	DW	M_GRAPHICS_C				;AN006;JW
P_GRAPHICS_C	DB	'\GRAPHICS.COM '                        ;AN006;JW space for ASCII-Z conversion
M_GRAPHICS_C	EQU	$ - P_GRAPHICS_C - 1			;AN006;JW
								;
		PUBLIC	S_GRAPHPRO_C				;AN006;JW
S_GRAPHPRO_C	DW	M_GRAPHPRO_C				;AN006;JW
P_GRAPHPRO_C	DB	'\GRAPHICS.PRO '                        ;AN006;JW space for ASCII-Z conversion
M_GRAPHPRO_C	EQU	$ - P_GRAPHPRO_C - 1			;AN006;JW
								;
		PUBLIC	S_RECOVER_C				;AN007;JW
S_RECOVER_C	DW	M_RECOVER_C				;AN007;JW
P_RECOVER_C	DB	'\RECOVER.COM '                         ;AN007;JW space for ASCII-Z conversion
M_RECOVER_C	EQU	$ - P_RECOVER_C - 1			;AN007;JW
								;
		PUBLIC	S_FASTOPEN_C				;AN007;JW
S_FASTOPEN_C	DW	M_FASTOPEN_C				;AN007;JW
P_FASTOPEN_C	DB	'\FASTOPEN.EXE '                        ;AN007;JW space for ASCII-Z conversion
M_FASTOPEN_C	EQU	$ - P_FASTOPEN_C - 1			;AN007;JW
								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
