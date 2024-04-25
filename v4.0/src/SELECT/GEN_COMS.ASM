PAGE	55,132						;AN000;
NAME	SELECT						;AN000;
TITLE	SELECT - SELECT.EXE				;AN000;
SUBTTL	GEN_COMS					;AN000;
.ALPHA							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	GEN_COMS.ASM : Copyright 1988 Microsoft
;
;	DATE:	 August 8/87
;
;	COMMENTS: Assemble with MASM 3.0 (using the -A option)
;
;	Module contains code for :
;		- creation of AUTOEXEC file
;		- creation of CONFIG file
;		- creation of DOSSHELL.BAT
;
;	CHANGE HISTORY:
;
;	;AN000;  for	      DT
;	;AN001;  for PTM1181  GHG
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	 DATA SEGMENT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	SEGMENT BYTE PUBLIC 'DATA'                              ;AN000;
								;
SC_CD		DW	MC_CD					;AN000;
PC_CD		DB	'@CD '                                  ;AN000;
MC_CD		EQU	$ - PC_CD				;AN000;
								;
SC_BREAK	DW	MC_BREAK				;AN000;
PC_BREAK	DB	'BREAK='                                ;AN000;
MC_BREAK	EQU	$ - PC_BREAK				;AN000;
								;
SC_CPSW 	DW	MC_CPSW 				;AN000;
PC_CPSW 	DB	'CPSW='                                 ;AN000;
MC_CPSW 	EQU	$ - PC_CPSW				;AN000;
								;
SC_VERIFY	DW	MC_VERIFY				;AN000;
PC_VERIFY	DB	'VERIFY '                               ;AN000;
MC_VERIFY	EQU	$ - PC_VERIFY				;AN000;
								;
SC_COUNTRY	DW	MC_COUNTRY				;AN000;
PC_COUNTRY	DB	'COUNTRY='                              ;AN000;
MC_COUNTRY	EQU	$ - PC_COUNTRY				;AN000;
								;
SC_COUNTRY_SYS	DW	MC_COUNTRY_SYS				;AN000;
PC_COUNTRY_SYS	DB	'COUNTRY.SYS'                           ;AN000;
MC_COUNTRY_SYS	EQU	$ - PC_COUNTRY_SYS			;AN000;
								;
SC_BUFFERS	DW	MC_BUFFERS				;AN000;
PC_BUFFERS	DB	'BUFFERS='                              ;AN000;
MC_BUFFERS	EQU	$ - PC_BUFFERS				;AN000;
								;
SC_SLASH_X	DW	MC_SLASH_X				;AC046;SEH changed from /E
PC_SLASH_X	DB	' /X'                                   ;AC046;SEH
MC_SLASH_X	EQU $ - PC_SLASH_X				;AC046;SEH
								;
SC_FCBS 	DW	MC_FCBS 				;AN000;
PC_FCBS 	DB	'FCBS='                                 ;AN000;
MC_FCBS 	EQU	$ - PC_FCBS				;AN000;
								;
SC_FILES	DW	MC_FILES				;AN000;
PC_FILES	DB	'FILES='                                ;AN000;
MC_FILES	EQU	$ - PC_FILES				;AN000;
								;
SC_LASTDRIVE	DW	MC_LASTDRIVE				;AN000;
PC_LASTDRIVE	DB	'LASTDRIVE='                            ;AN000;
MC_LASTDRIVE	EQU	$ - PC_LASTDRIVE			;AN000;
								;
SC_STACKS	DW	MC_STACKS				;AN000;
PC_STACKS	DB	'STACKS='                               ;AN000;
MC_STACKS	EQU	$ - PC_STACKS				;AN000;
								;
SC_SHELL	DW	MC_SHELL				;AN000;
PC_SHELL	DB	'SHELL='                                ;AN000;
MC_SHELL	EQU	$ - PC_SHELL				;AN000;
								;
SC_SHELL_1	DW	MC_SHELL_1				;AN000;
PC_SHELL_1	DB	'COMMAND.COM'                           ;AC037; SEH  Split the original SC_SHELL_1 into
MC_SHELL_1	EQU	$ - PC_SHELL_1				;AC037; SEH    3 parts
								;
SC_SHELL_2	DW	MC_SHELL_2				;AN037; SEH  Used for diskettes only
PC_SHELL_2	DB	' /MSG'                                 ;AN037; SEH
MC_SHELL_2	EQU	$ - PC_SHELL_2				;AN037; SEH
								;
SC_SHELL_3	DW	MC_SHELL_3				;AN037; SEH  Use for diskettes and hardfile
PC_SHELL_3	DB	' /P /E:256  '                          ;AN037; SEH  Two spaces required for CR and LF
MC_SHELL_3	EQU	$ - PC_SHELL_3 - 2			;AN037; SEH
								;
SC_DEVICE	DW	MC_DEVICE				;AN000;
PC_DEVICE	DB	'DEVICE='                               ;AN000;
MC_DEVICE	EQU	$ - PC_DEVICE				;AN000;
								;
SC_XMAEM_SYS	DW	MC_XMAEM_SYS				;AN000;
PC_XMAEM_SYS	DB	'XMAEM.SYS '                            ;AN000;
MC_XMAEM_SYS	EQU	$ - PC_XMAEM_SYS			;AN000;
								;
SC_XMA2EMS_SYS	DW	MC_XMA2EMS_SYS				;AN000;
PC_XMA2EMS_SYS	DB	'XMA2EMS.SYS '                          ;AN000;
MC_XMA2EMS_SYS	EQU	$ - PC_XMA2EMS_SYS			;AN000;
								;
SC_ANSI_SYS	DW	MC_ANSI_SYS				;AN000;
PC_ANSI_SYS	DB	'ANSI.SYS '                             ;AN000;
MC_ANSI_SYS	EQU	$ - PC_ANSI_SYS 			;AN000;
								;
SC_VDISK_SYS	DW	MC_VDISK_SYS				;AN000;
PC_VDISK_SYS	DB	'RAMDRIVE.SYS '                         ;AN000;
MC_VDISK_SYS	EQU	$ - PC_VDISK_SYS			;AN000;
								;
SC_DISPLAY_SYS	DW	MC_DISPLAY_SYS				;AN000;
PC_DISPLAY_SYS	DB	'DISPLAY.SYS CON=('                     ;AN000;
MC_DISPLAY_SYS	EQU	$ - PC_DISPLAY_SYS			;AN000;
								;
		PUBLIC	SC_DISPLAY_EGA				;AN000;
SC_DISPLAY_EGA	DW	MC_DISPLAY_EGA				;AN000;
PC_DISPLAY_EGA	DB	'EGA.CPI)'                              ;AN000;
MC_DISPLAY_EGA	EQU	$ - PC_DISPLAY_EGA			;AN000;
								;
		PUBLIC	SD_DISPLAY_EGA				;AN001;GHG
SD_DISPLAY_EGA	DW	MD_DISPLAY_EGA				;AN001;GHG
PD_DISPLAY_EGA	DB	'EGA'                                   ;AN001;GHG
MD_DISPLAY_EGA	EQU	$ - PD_DISPLAY_EGA			;AN001;GHG
								;
		PUBLIC	SC_DISPLAY_LCD				;AN000;
SC_DISPLAY_LCD	DW	MC_DISPLAY_LCD				;AN000;
PC_DISPLAY_LCD	DB	'LCD.CPI)'                              ;AN000;
MC_DISPLAY_LCD	EQU	$ - PC_DISPLAY_LCD			;AN000;
								;
		PUBLIC	SD_DISPLAY_LCD				;AN001;GHG
SD_DISPLAY_LCD	DW	MD_DISPLAY_LCD				;AN001;GHG
PD_DISPLAY_LCD	DB	'LCD'                                   ;AN001;GHG
MD_DISPLAY_LCD	EQU	$ - PD_DISPLAY_LCD			;AN001;GHG
								;
SC_PRINTER_SYS	DW	MC_PRINTER_SYS				;AN000;
PC_PRINTER_SYS	DB	'PRINTER.SYS '                          ;AN000;
MC_PRINTER_SYS	EQU	$ - PC_PRINTER_SYS			;AN000;
								;
SC_LPT		DW	MC_LPT					;AN000;
PC_LPT		DB	'LPT'                                   ;AN000;
MC_LPT		EQU	$ - PC_LPT				;AN000;
								;
SC_COM		DW	MC_COM					;AN011; SEH
PC_COM		DB	'COM'                                   ;AN011; SEH
MC_COM		EQU	$ - PC_COM				;AN011; SEH
								;
SC_EQUAL_OPEN	DW	MC_EQUAL_OPEN				;AN000;
PC_EQUAL_OPEN	DB	'=('                                    ;AN000;
MC_EQUAL_OPEN	EQU	$ - PC_EQUAL_OPEN			;AN000;
								;
SC_437		DW	MC_437					;AN000;
PC_437		DB	',437,'                                 ;AN000;
MC_437		EQU	$ - PC_437				;AN000;
								;
SC_COMMA	DW	MC_COMMA				;AN000;
PC_COMMA	DB	','                                     ;AN000;
MC_COMMA	EQU	$ - PC_COMMA				;AN000;
								;
SC_INSTALL	DW	MC_INSTALL				;AN000;
PC_INSTALL	DB	'INSTALL='                              ;AN000;
MC_INSTALL	EQU	$ - PC_INSTALL				;AN000;
								;
SC_KEYB_C	DW	MC_KEYB_C				;AN000;
PC_KEYB_C	DB	'KEYB.COM '                             ;AN000;
MC_KEYB_C	EQU	$ - PC_KEYB_C				;AN000;
								;
SC_KEYBOARD_SYS DW	MC_KEYBOARD_SYS 			;AN000;
PC_KEYBOARD_SYS DB	'KEYBOARD.SYS'                          ;AN000;
MC_KEYBOARD_SYS EQU	$ - PC_KEYBOARD_SYS			;AN000;
								;
SC_KEYB_SWITCH	DW	MC_KEYB_SWITCH				;AN002;JW
PC_KEYB_SWITCH	DB	' /ID:'                                 ;AN002;JW
MC_KEYB_SWITCH	EQU	$ - PC_KEYB_SWITCH			;AN002;JW
								;
SC_SHARE	DW	MC_SHARE				;AN000;
PC_SHARE	DB	'SHARE.EXE '                            ;AN000;
MC_SHARE	EQU	$ - PC_SHARE				;AN000;
								;
SC_FASTOPEN	DW	MC_FASTOPEN				;AN000;
PC_FASTOPEN	DB	'FASTOPEN.EXE '                         ;AN000;
MC_FASTOPEN	EQU	$ - PC_FASTOPEN 			;AN000;
								;
SC_NLSFUNC	DW	MC_NLSFUNC				;AN000;
PC_NLSFUNC	DB	'NLSFUNC.EXE '                          ;AN000;
MC_NLSFUNC	EQU	$ - PC_NLSFUNC				;AN000;
								;
SC_ECHO 	DW	MC_ECHO 				;AN000;
PC_ECHO 	DB	'@ECHO OFF  '                           ;AN000;  TWO SPACES REQUIRED FOR CR,LF
MC_ECHO 	EQU	$ - PC_ECHO - 2 			;AN000;
								;
SC_PATH 	DW	MC_PATH 				;AN000;
PC_PATH 	DB	'PATH '                                 ;AN000;
MC_PATH 	EQU	$ - PC_PATH				;AN000;
								;
SC_APPEND	DW	MC_APPEND				;AN000;
PC_APPEND	DB	'APPEND '                               ;AN000;
MC_APPEND	EQU	$ - PC_APPEND				;AN000;
								;
SC_PROMPT	DW	MC_PROMPT				;AN000;
PC_PROMPT	DB	'PROMPT '                               ;AN000;
MC_PROMPT	EQU	$ - PC_PROMPT				;AN000;
								;
SC_SET_COMSPEC	DW	MC_SET_COMSPEC				;AN000;
PC_SET_COMSPEC	DB	'SET COMSPEC='                          ;AN000;
MC_SET_COMSPEC	EQU	$ - PC_SET_COMSPEC			;AN000;
								;
SC_COMMAND_COM	DW	MC_COMMAND_COM				;AN000;
PC_COMMAND_COM	DB	'COMMAND.COM'                           ;AN000;
MC_COMMAND_COM	EQU	$ - PC_COMMAND_COM			;AN000;
								;
SC_GRAPHICS	DW	MC_GRAPHICS				;AN000;
PC_GRAPHICS	DB	'GRAPHICS '                             ;AN000;
MC_GRAPHICS	EQU	$ - PC_GRAPHICS 			;AN000;
								;
SC_GRAFTABL	DW	MC_GRAFTABL				;AN000;
PC_GRAFTABL	DB	'GRAFTABL '                             ;AN000;
MC_GRAFTABL	EQU	$ - PC_GRAFTABL 			;AN000;
								;
;SC_DATE	 DW	 MC_DATE				;
;PC_DATE	 DB	 'DATE  '                               ;  TWO SPACES REQUIRED FOR CR,LF
;MC_DATE	 EQU	 $ - PC_DATE - 2			;
								;
;SC_TIME	 DW	 MC_TIME				;
;PC_TIME	 DB	 'TIME  '                               ;  TWO SPACES REQUIRED FOR CR,LF
;MC_TIME	 EQU	 $ - PC_TIME - 2			;
								;
SC_VER		DW	MC_VER					;AN000;
PC_VER		DB	'VER  '                                 ;AN000;  TWO SPACES REQUIRED FOR CR,LF
MC_VER		EQU	$ - PC_VER - 2				;AN000;
								;
SC_MODE_CON	DW	MC_MODE_CON				;AN000;
PC_MODE_CON	DB	'MODE CON CP PREP=(('                   ;AN000;
MC_MODE_CON	EQU	$ - PC_MODE_CON 			;AN000;
								;
SC_MODE_COM	DW	MC_MODE_COM				;AN000;
PC_MODE_COM	DB	'MODE COM'                              ;AN000;
MC_MODE_COM	EQU	$ - PC_MODE_COM 			;AN000;
								;
SC_MODE_LPT	DW	MC_MODE_LPT				;AN000;
PC_MODE_LPT	DB	'MODE LPT'                              ;AN000;
MC_MODE_LPT	EQU	$ - PC_MODE_LPT 			;AN000;
								;
SC_EQUAL_COM	DW	MC_EQUAL_COM				;AN000;
PC_EQUAL_COM	DB	'=COM'                                  ;AN000;
MC_EQUAL_COM	EQU	$ - PC_EQUAL_COM			;AN000;
								;
SC_PREPARE	DW	MC_PREPARE				;AN000;
PC_PREPARE	DB	' CP PREP=(('                           ;AN000;
MC_PREPARE	EQU	$ - PC_PREPARE				;AN000;
								;
SC_CLOSE_BRAC	DW	MC_CLOSE_BRAC				;AN000;
PC_CLOSE_BRAC	DB	') '                                    ;AN000;
MC_CLOSE_BRAC	EQU	$ - PC_CLOSE_BRAC			;AN000;
								;
SC_KEYB_A	DW	MC_KEYB_A				;AN000;
PC_KEYB_A	DB	'KEYB '                                 ;AN000;
MC_KEYB_A	EQU	$ - PC_KEYB_A				;AN000;
								;
SC_COMMAS	DW	MC_COMMAS				;AN000;
PC_COMMAS	DB	',,'                                    ;AN000;
MC_COMMAS	EQU	$ - PC_COMMAS				;AN000;
								;
SC_CHCP 	DW	MC_CHCP 				;AN000;
PC_CHCP 	DB	'CHCP '                                 ;AN000;
MC_CHCP 	EQU	$ - PC_CHCP				;AN000;
								;
SC_DRIVE_C	DW	MC_DRIVE_C				;AN013;JW
PC_DRIVE_C	DB	'@C:  '                                 ;AN013;JW
MC_DRIVE_C	EQU	$ - PC_DRIVE_C - 2			;AN013;JW
								;
SC_SHELLC_1	DW	MC_SHELLC_1				;AN000;
PC_SHELLC_1	DB	'@SHELLB DOSSHELL',E_CR,E_LF            ;AC019;SEH
		DB	'@IF ERRORLEVEL 255 GOTO END',E_CR,E_LF ;AN000;
		DB	':COMMON  '				;AN000;
MC_SHELLC_1	EQU	$ - PC_SHELLC_1 - 2			;AN000; 2 SPACES FOR ASCII-Z CONVERSION
								;
SC_SHELLC_2	DW	MC_SHELLC_2				;AN000;
PC_SHELLC_2	DB	':END  '                                ;AN000;
MC_SHELLC_2	EQU	$ - PC_SHELLC_2 - 2			;AN000;
								;
SC_SHELLC	DW	MC_SHELLC				;AN000;
PC_SHELLC	DB	'@SHELLC '                              ;AN000;
MC_SHELLC	EQU	$ - PC_SHELLC				;AN000;
								;
SC_SHELLP	DW	MC_SHELLP				;AN000;
PC_SHELLP	DB	'DOSSHELL  '                            ;AC019;SEH
MC_SHELLP	EQU	$ - PC_SHELLP - 2			;AN000;
								;
SC_PRINT_COM	DW	MC_PRINT_COM				;AN000;
PC_PRINT_COM	DB	'PRINT /D:'                             ;AC011; SEH
MC_PRINT_COM	EQU	$ - PC_PRINT_COM			;AN011; SEH
								;
SC_AT_SIGN	DW	MC_AT_SIGN				;AN000;
PC_AT_SIGN	DB	'@'                                     ;AN000;
MC_AT_SIGN	EQU	$ - PC_AT_SIGN				;AN000;
								;
S_DOS_PATH	DW	M_DOS_PATH				;AN000;
P_DOS_PATH	DB	50 DUP(?)				;AN000;
M_DOS_PATH	EQU	$ - P_DOS_PATH				;AN000;
								;
DATA		ENDS						;AN000;DATA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	INCLUDE EXT.INC 					;AN000;
	INCLUDE STRUC.INC					;AN000;
	INCLUDE MACROS.INC					;AN000;
	INCLUDE ROUT_EXT.INC					;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	SEGMENT PARA PUBLIC 'SELECT'                            ;AN000;segment for far routine
	ASSUME	CS:SELECT,DS:DATA				;AN000;
								;
	PUBLIC	CREATE_CONFIG_SYS				;AN000;
	PUBLIC	CREATE_AUTOEXEC_BAT				;AN000;
	PUBLIC	CREATE_SHELL_BAT				;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Create AUTOEXEC.BAT file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CREATE_AUTOEXEC_BAT	PROC					;AN000;
								;
	;;;install to B:, install path	= null			;
	;;;install to root of C:, install path = c:\		;
	;;;install to directory in C:, install path = c:\path\	;
	.IF < I_DEST_DRIVE eq E_DEST_DRIVE_B >			;AN000; if install to drive B:
	.THEN							;AN000;
	   INIT_VAR		S_DOS_PATH,0			;AN000;    set path = null
	.ELSE							;AN000; else
	   COPY_STRING		S_DOS_PATH,M_DOS_PATH,S_INSTALL_PATH;AN000;set path = user defined path
	   .IF < S_DOS_PATH gt M_DEST_DRIVE >			;AN000;   if install is not to root of drive C:
	   .THEN						;AN000;
	      APPEND_STRING	S_DOS_PATH,M_DOS_PATH,S_SLASH	;AN000;      append back slash
	   .ENDIF						;AN000;
	.ENDIF							;AN000;
								;
	;;;write @ECHO OFF					;
	WRITE_LINE		SC_ECHO 			;AN000; write ECHO OFF command
								;
	;;;write SET COMSPEC=<path>\COMMAND.COM 		;
	.IF < I_DEST_DRIVE ne E_DEST_DRIVE_C >			;AC043;SEH COMSPEC formerly after PROMPT ;AN111; if install destination is drive B: or A: JW
	   MERGE_STRING 	   SC_LINE,MC_LINE,SC_SET_COMSPEC,S_DRIVE_A  ;AC043;SEH ;AN000;JW
	.ELSE							;AC043;SEH ;AN000;JW
	   MERGE_STRING 	   SC_LINE,MC_LINE,SC_SET_COMSPEC,S_DOS_PATH	 ;AC043;SEH ;AN000;JW
	.ENDIF							;AC043;SEH ;AN000;JW
	APPEND_STRING		SC_LINE,MC_LINE, SC_COMMAND_COM ;AC043;SEH ;AN000;
	WRITE_LINE		SC_LINE 			;AC043;SEH ;AN000; write SET COMSPEC command
								;
	;;;write VERIFY <parameter>				;
	.IF < S_VERIFY gt 0 >					;AN000; if field length > zero
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_VERIFY,S_VERIFY;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write VERIFY command
	.ENDIF							;AN000;
								;
	;;;write PATH <parameter>				;
	.IF < F_PATH eq E_PATH_YES > and			;AN000; if PATH command required
	.IF < S_PATH gt 0 >					;AN000; and field length > zero
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_PATH, S_PATH ;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write PATH command
	.ENDIF							;AN000;
								;
	;;;write APPEND <parameter>				;AN000;JW
	;;;write APPEND <path>					;
	.IF < F_APPEND eq E_APPEND_YES >			;AN000; if APPEND command required
	   .IF < S_APPEND_P gt 0 >				;AN000; and field length > zero    JW
	   .THEN						;AN000; 			   JW
	      MERGE_STRING	   SC_LINE,MC_LINE,SC_APPEND,S_APPEND_P 		     ;AN000;JW
	      WRITE_LINE	   SC_LINE			;AN000;    write APPEND command    JW
	   .ENDIF						;AN000; 			   JW
	   .IF < S_APPEND gt 0 >				;AN000; and field length > zero
	   .THEN						;AN000;
	      MERGE_STRING	   SC_LINE,MC_LINE,SC_APPEND,S_APPEND;AN000;
	      WRITE_LINE	   SC_LINE			;AN000;    write APPEND command
	   .ENDIF						;AN000;
	.ENDIF							;AN000;JW
								;
	;;;write PROMPT <parameter>				;
	.IF < F_PROMPT eq E_PROMPT_YES > and			;AN000; if PROMPT command required
	.IF < S_PROMPT gt 0 >					;AN000; and field length > zero
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_PROMPT,S_PROMPT;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write PROMPT command
	.ENDIF							;AN000;
								;
	;;;write <path>\GRAPHICS <parameter>			;
	.IF < F_GRAPHICS eq E_GRAPHICS_YES >			;AN000; if GRAPHICS command is to be included
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,S_DOS_PATH,SC_GRAPHICS;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE, S_GRAPHICS	;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write GRAPHICS command
	.ENDIF							;AN000;
								;
	;;;init S_STR120_1 to primary code page 		;
	;;;init S_STR120_2 to secondary code page		;
	WORD_TO_CHAR		N_CP_PRI, S_STR120_1		;AN000; primary code page in ASCII-N format
	WORD_TO_CHAR		N_CP_SEC, S_STR120_2		;AN000; secondary code page in ASCII-N format
								;
	;;;write <path>\GRAFTABL <primary code page>		;
	.IF < F_GRAFTABL eq E_GRAFTABL_YES >			;AN000; if GRAFTABL command required
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,S_DOS_PATH,SC_GRAFTABL;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE, S_STR120_1	;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write GRAFTABL command
	.ENDIF							;AN000;
								;
	;;;write VER						;
	WRITE_LINE		SC_VER				;AN000; write VER command
								;
	;;;S_STR120_1 = primary code page			;
	;;;S_STR120_2 = secondary code apge			;
	;;;init S_STR120_3 to code page list			;
	INIT_VAR	     S_STR120_3, 0			;AN000;
	.IF < N_CP_PRI eq 0 > or				;AN000;   if primary code page is 0 or 437
	.IF < N_CP_PRI eq 437 > 				;AN000;
	.THEN							;AN000;      no action
	.ELSE							;AN000;   else
	   APPEND_STRING	S_STR120_3,M_STR120_3,S_STR120_1;AN000;      append code page to cp list
	.ENDIF							;AN000;
								;
	.IF < N_CP_SEC eq 0 > or				;AN000;   if secondary code page is 0 or 437
	.IF < N_CP_SEC eq 437 > 				;AN000;
	.THEN							;AN000;      no action
	.ELSE							;AN000;   else
	   .IF < S_STR120_3 ne 0 >				;AN000;      if primary code page is in cp list
	   .THEN						;AN000;
	      APPEND_STRING	S_STR120_3, M_STR120_3, S_SPACE ;AN000; 	append space to cp list
	   .ENDIF						;AN000;
	   APPEND_STRING	S_STR120_3,M_STR120_3,S_STR120_2;AN000;      append code page to cp list
	.ENDIF							;AN000;
								;
	;;;S_STR120_3 = code page list				;
	;;;write MODE CON CODEPAGE PREPARE ((<cp list>) <path>\<display>.CPI
	.IF < F_CPSW eq E_CPSW_YES > near			;AN000; if code page switching required
	.THEN							;AN000;
	   .IF < S_STR120_3 ne 0 > near 			;AN000;   if primary/secondary code pages are not 0 or 437
	   .THEN						;AN000;
	      MERGE_STRING	SC_LINE,MC_LINE,SC_MODE_CON,S_STR120_3;AN000;
	      APPEND_STRING	SC_LINE, MC_LINE, SC_CLOSE_BRAC ;AN000;      append close bracket
	      APPEND_STRING	SC_LINE, MC_LINE,S_DOS_PATH	;AN000;      append path
	      .IF < ACTIVE eq EGA > or				;AN000;      if EGA adaptor
	      .IF < ALTERNATE eq EGA >				;AN000;
	      .THEN						;AN000;
		 APPEND_STRING	SC_LINE, MC_LINE, SC_DISPLAY_EGA;AN000; 	append	EGA.CPI)
	      .ELSEIF < ACTIVE eq LCD > or			;AN000;      if LCD adaptor
	      .IF < ALTERNATE eq LCD >				;AN000;
	      .THEN						;AN000;
		 APPEND_STRING	SC_LINE, MC_LINE, SC_DISPLAY_LCD;AN000; 	append LCD.CPI)
	      .ENDIF						;AN000;
	      WRITE_LINE	SC_LINE 			;AN000;      write MODE CON CODEPAGE command
	   .ENDIF						;AN000;
	.ENDIF							;AN000;
								;
	;;;S_STR120_3 = cp list 				;
	;;;write MODE LPT1 CODEPAGE PREPARE=((<cp list>) <path>\<cp paramaeters.CPI>)
	;;;write MODE LPT2 CODEPAGE PREPARE=((<cp list>) <path>\<cp paramaeters.CPI>)
	;;;write MODE LPT3 CODEPAGE PREPARE=((<cp list>) <path>\<cp paramaeters.CPI>)
	;;;N_WORD_1 = parallel port number			;
	INIT_VAR		N_WORD_1, 1			;AN000; set port number = 1
	.IF < F_CPSW eq E_CPSW_YES > near			;AN000; if code page switching required
	.THEN							;AN000;
	   .REPEAT						;AN000;    repeat code block
	      GET_PRINTER_PARAMS 0, N_WORD_1, N_RETCODE 	;AN000;       get printer parameters
	      .IF < N_RETCODE eq 1 > and near			;AN000;       if valid return
	      .IF < N_PRINTER_TYPE eq E_PARALLEL > and near	;AN000; 	 and parallel printer
	      .IF < S_CP_DRIVER gt 0 > and near 		;AN000; 	 and driver and prepare
	      .IF < S_CP_PREPARE gt 0 > near			;AN000; 	 parameters valid
	      .THEN						;AN000;
		 COPY_STRING	SC_LINE, MC_LINE, SC_MODE_LPT	;AN000; 	 append MODE LPT
		 WORD_TO_CHAR	N_WORD_1, S_STR120_2		;AN000;
		 APPEND_STRING	SC_LINE, MC_LINE, S_STR120_2	;AN000; 	 append lpt number
		 APPEND_STRING	SC_LINE, MC_LINE, SC_PREPARE	;AN000; 	 append CODEPAGE PREPARE
		 APPEND_STRING	SC_LINE, MC_LINE, S_STR120_3	;AN000; 	 append cp list
		 APPEND_STRING	SC_LINE, MC_LINE, SC_CLOSE_BRAC ;AN000; 	 append close bracket
		 APPEND_STRING	SC_LINE, MC_LINE, S_DOS_PATH	;AN000; 	 append path
		 APPEND_STRING	SC_LINE, MC_LINE, S_CP_PREPARE	;AN000; 	 append driver parameters
		 APPEND_STRING	SC_LINE, MC_LINE, SC_CLOSE_BRAC ;AN000; 	 append close bracket
		 WRITE_LINE	SC_LINE 			;AN000;    write PRINTER.SYS command
	      .ENDIF						;AN000;
	      INC_VAR		N_WORD_1			;AN000;       inc printer number
	   .UNTIL < N_WORD_1 gt 3 > near			;AN000;    end of repeat block
	.ENDIF							;AN000;
								;
	;;;write serial printer parameters and redirection command
	;;;write MODE COMx:<parameter>				;
	;;;write MODE LPTy=COMx 				;
	;;;N_WORD_1 = serial port number			;
	INIT_VAR		N_WORD_1, 4			;AN000; set port number = 4
	INIT_VAR		N_WORD_2, 1			;AN000; set serial port number = 1
	.REPEAT 						;AN000; repeat code block
	   GET_PRINTER_PARAMS 0, N_WORD_1, N_RETCODE		;AN000;    get printer parameters
	   .IF < N_RETCODE eq 1 > and near			;AN000;    if valid return
	   .IF < N_PRINTER_TYPE eq E_SERIAL > and near		;AN000;       and serial printer
	   .IF < S_MODE_PARM gt 0 > near			;AN000;       and mode parameters present
	   .THEN						;AN000;
	      COPY_STRING	SC_LINE, MC_LINE, SC_MODE_COM	;AN000;       append MODE COM
	      WORD_TO_CHAR	N_WORD_2, S_STR120_3		;AN000;       S_STR120_3 = serial port number
	      APPEND_STRING	SC_LINE, MC_LINE, S_STR120_3	;AN000;       append serial port number
	      APPEND_STRING	SC_LINE, MC_LINE, S_COLON	;AN000;       append colon
	      APPEND_STRING	SC_LINE, MC_LINE, S_MODE_PARM	;AN000;       append mode parameters
	      WRITE_LINE	SC_LINE 			;AN000;       write MODE COMx command
	      .IF < I_REDIRECT gt 1 >				;AN000;       if printer redirection
	      .THEN						;AN000;
		 COPY_STRING	SC_LINE,MC_LINE,SC_MODE_LPT	;AN000; 	 append MODE LPT
		 DEC_VAR	I_REDIRECT			;AN000; 	 first item in list is 'None'
		 WORD_TO_CHAR	I_REDIRECT, S_STR120_2		;AN000; 	 convert LPT no to chars
		 APPEND_STRING	SC_LINE,MC_LINE,S_STR120_2	;AN000; 	 append parallel port
		 APPEND_STRING	SC_LINE,MC_LINE,SC_EQUAL_COM	;AN000; 	 append =COM
		 APPEND_STRING	SC_LINE,MC_LINE,S_STR120_3	;AN000; 	 append serial port number
		 WRITE_LINE	SC_LINE 			;AN000; 	 write MODE LPTx=COMy command
	      .ENDIF						;AN000;
	   .ENDIF						;AN000;
	   INC_VAR		N_WORD_1			;AN000;    inc printer number
	   INC_VAR		N_WORD_2			;AN000;    inc serial port number
	.UNTIL < N_WORD_1 gt 7 > near				;AN000; end of repeat block
								;
	;;;write KEYB <keyboard>,,<path>\KEYBOARD.SYS		;
	.IF < N_KYBD_VAL eq E_KYBD_VAL_YES > near		;AN000;    if kybd id is valid
	.THEN							;AN000;
	   COPY_STRING	     SC_LINE, MC_LINE, SC_KEYB_A	;AN000;       copy KEYB
	   APPEND_STRING     SC_LINE, MC_LINE, S_KEYBOARD	;AN000;       append kybd id
	   APPEND_STRING     SC_LINE, MC_LINE, SC_COMMAS	;AN000;       append ,,
	   APPEND_STRING     SC_LINE,MC_LINE, S_DOS_PATH	;AN000;       append install path
	   APPEND_STRING     SC_LINE,MC_LINE,SC_KEYBOARD_SYS	;AN000;       append \KEYBOARD.SYS
	   .IF < N_KYBD_ALT ne E_KYBD_ALT_NO > and		;AN002;       if alternate keyboard valid	 JW
	   .IF < I_KYBD_ALT eq 2 >				;AN002;       and not default setting		 JW
	   .THEN						;AN002; 					 JW
	      APPEND_STRING	SC_LINE, MC_LINE,SC_KEYB_SWITCH ;AN002;       append keyb id switch '/ID:'       JW
	      APPEND_STRING	SC_LINE, MC_LINE, S_KYBD_ALT	;AN002;       append alternate keyboard id	 JW
	      APPEND_STRING	SC_LINE, MC_LINE, S_SPACE	;AN090;JPW add space so last char not overwritten
	   .ENDIF						;AN002; 					 JW
	   WRITE_LINE	     SC_LINE				;AN000;       write KEYB command
	.ENDIF							;AN000;
								;
	;;;write CHCP <primary code page>			;
	.IF < F_CPSW eq E_CPSW_YES >				;AN000; if code page switching required
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_CHCP,S_STR120_1;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write CHCP command
	.ENDIF							;AN000;
								;
	;;;write 'PRINT /D:LPTx' or 'PRINT /D:COMx'             ;AC066;SEH moved print stmt.  NOTE: PRINT AND SHELL STMTS MUST BE LAST IN AUTOEXEC.BAT
	.IF < I_WORKSPACE ne E_WORKSPACE_MIN > and near 	;AC066;SEH ;AN011; SEH
	.IF < I_DEST_DRIVE eq E_DEST_DRIVE_C > and near 	;AC066;SEH ;AN015; JW	 If install to fixed disk
	.IF < N_NUMPRINT gt 0 > near				;AC066;SEH ;AN011; SEH
	.THEN							;AC066;SEH ;AN011; SEH
	   GET_PRINTER_PARAMS	1, 0, N_RETCODE 		;AC066;SEH ;AN011; SEH	 get parameters for 1st printer selected
	   .IF < N_RETCODE ne 0 > near				;AC066;SEH ;AN011; SEH	 if valid return
	   .THEN						;AC066;SEH ;AN011; SEH
	      .IF < N_PRINTER_TYPE eq E_PARALLEL >		;AC066;SEH ;AN011; SEH	 LPT1, LPT2 or LPT3
	      .THEN						;AC066;SEH ;AN011; SEH
		 MERGE_STRING	SC_LINE, MC_LINE, SC_PRINT_COM, SC_LPT;AC066;SEH ;AN011; SEH   'PRINT /D:LPT'
		 COPY_WORD	N_WORD_1, I_PORT		;AC066;SEH ;AN011; SEH	 get LPT number (1-3)
	      .ELSE						;AC066;SEH ;AN011; SEH	 serial printer
		 .IF < I_REDIRECT gt 1 >			;AC066;SEH ;AN011; SEH	 check if redirected to LPT
		 .THEN						;AC066;SEH ;AN011; SEH
		    MERGE_STRING   SC_LINE, MC_LINE, SC_PRINT_COM, SC_LPT  ;AC066;SEH ;AN011; SEH   'PRINT /D:LPT'
		    COPY_WORD	N_WORD_1, I_REDIRECT		;AC066;SEH ;AN011; SEH	 gives LPT printer redirected to ---
		    DEC 	N_WORD_1			;AC066;SEH ;AN011; SEH	 but must subtract off value 'none' to get port#
		 .ELSE						;AC066;SEH ;AN011; SEH	 serial port that hasn't been redirected
		    MERGE_STRING   SC_LINE, MC_LINE, SC_PRINT_COM, SC_COM  ;AC066;SEH ;AN011; SEH   'PRINT /D:COM'
		    COPY_WORD	N_WORD_1, I_PORT		;AC066;SEH ;AN011; SEH	 value of COM port
		 .ENDIF 					;AC066;SEH ;AN011; SEH
	      .ENDIF						;AC066;SEH ;AN011; SEH
	      WORD_TO_CHAR	N_WORD_1, S_STR120_3		;AC066;SEH ;AN011; SEH
	      APPEND_STRING	SC_LINE, MC_LINE, S_STR120_3	;AC066;SEH ;AN011; SEH	 add on the com or lpt number to the string
	      WRITE_LINE	SC_LINE 			;AC066;SEH ;AN011; SEH	 write 'PRINT /D:LPTx' or 'PRINT /D:COMx'  x=number
	   .ENDIF						;AC066;SEH ;AN011; SEH
	.ENDIF							;AC066;SEH ;AN011; SEH
								;
	;;;write SHELL <parameter>				;
	.IF < N_DEST eq E_DEST_SHELL > and			;AN000; if preparing for SHELL diskette
	.IF < F_SHELL eq E_SHELL_YES >				;AN000; if SHELL support required
	.THEN							;AN000;
	   WRITE_LINE		SC_SHELLP			;AN000;
	.ENDIF							;AN000;
								;
	RET							;AN000;
CREATE_AUTOEXEC_BAT	ENDP					;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Create CONFIG.SYS file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CREATE_CONFIG_SYS	PROC					;AN000;
								;
	;;;install to B:, install path	= null			;
	;;;install to root of C:, install path = c:\		;
	;;;install to directory in C:, install path = c:\path\	;
	.IF < I_DEST_DRIVE eq E_DEST_DRIVE_B >			;AN000; if install to drive B:
	.THEN							;AN000;
	   INIT_VAR		S_DOS_PATH,0			;AN000;    set path = null
	.ELSE							;AN000; else
	   COPY_STRING		S_DOS_PATH,M_DOS_PATH,S_INSTALL_PATH;AN000;set path = user defined path
	   .IF < S_DOS_PATH gt M_DEST_DRIVE >			;AN000;    if install is not under root of C:
	   .THEN						;AN000;
	      APPEND_STRING	S_DOS_PATH,M_DOS_PATH,S_SLASH	;AN000;       append back slash to path
	   .ENDIF						;AN000;
	.ENDIF							;AN000;
								;
	;;;write BREAK=<parameter>				;
	.IF < S_BREAK gt 0 >					;AN000; if field length > zero
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_BREAK,S_BREAK;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write BREAK command
	.ENDIF							;AN000;
								;
	;;;write COUNTRY=<country>,,<path>\COUNTRY.SYS		;
	.IF < N_COUNTRY eq 1 >					;AN000; if country is US (001)
	.THEN							;AN000;    no action
	.ELSE							;AN000; else
	   WORD_TO_CHAR 	N_COUNTRY, S_STR120_1		;AN000;    S_STR120_1 = country in ASCII
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_COUNTRY,S_STR120_1;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE, SC_COMMAS	;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE,S_DOS_PATH	;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE,SC_COUNTRY_SYS ;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write COUNTRY command
	.ENDIF							;AN000;
								;
	;;;write BUFFERS=<parameter>				;
	;;;write BUFFERS=<parameter> /E if expanded memory support
	.IF < S_BUFFERS gt 0 >					;AN000; if field lengh > zero
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_BUFFERS,S_BUFFERS;AN000;
	   .IF < N_XMA eq E_XMA_PRESENT > and			;AN000;    if expanded memory present
	   .IF < F_XMA eq E_XMA_YES >				;AN000;       and is to be used
	   .THEN						;AN000;
	      APPEND_STRING	SC_LINE, MC_LINE, SC_SLASH_X	;AC046;SEH    append /X to command   (formerly /E)
	   .ENDIF						;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write BUFFERS command
	.ENDIF							;AN000;
								;
	;;;write FCBS=<parameter>				;
	.IF < S_FCBS gt 0 >					;AN000; if field length > zero
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE, SC_FCBS,S_FCBS ;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write FCBS command
	.ENDIF							;AN000;
								;
	;;;write FILES=<parameter>				;
	.IF < S_FILES gt 0 >					;AN000; if field length > zero
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_FILES,S_FILES;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write FILES command
	.ENDIF							;AN000;
								;
	;;;write LASTDRIVE=<parameter>				;
	.IF < S_LASTDRIVE gt 0 >				;AN000; if field length > zero
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_LASTDRIVE,S_LASTDRIVE;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write LASTDRIVE command
	.ENDIF							;AN000;
								;
	;;;write STACKS=<parameter>				;
	.IF < S_STACKS gt 0 >					;AN000; if field length > zero
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_STACKS,S_STACKS;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write STACKS command
	.ENDIF							;AN000;
								;
	;;;write SHELL=<path>\COMMAND.COM /MSG /P /E:256	;
	.IF < I_DEST_DRIVE ne E_DEST_DRIVE_C >			;AN111; if install destination is drive B: or A: JW
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_SHELL,S_DRIVE_A    ;AN000;JW
	   APPEND_STRING	SC_LINE,MC_LINE,SC_SHELL_1	;AN037;SEH
	   APPEND_STRING	SC_LINE,MC_LINE,SC_SHELL_2	;AN037;SEH Only diskettes get /MSG in SHELL command
	.ELSE							;AN000;JW
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_SHELL,S_DOS_PATH   ;AN000;JW
	   APPEND_STRING	SC_LINE,MC_LINE,SC_SHELL_1	;AC037;SEH
	.ENDIF							;AN000;JW
	APPEND_STRING		SC_LINE, MC_LINE, SC_SHELL_3	;AC037;SEH
	WRITE_LINE		SC_LINE 			;AN000; write SHELL command
								;
	;;;init S_STR120_1 to DEVICE=<path>\			;
	MERGE_STRING		S_STR120_1,M_STR120_1,SC_DEVICE,S_DOS_PATH;AN000;
								;
	;;;S_STR120_1 = DEVICE=<path>\				;
	;;;write DEVICE=<path>\XMAEM.SYS<parameter>		;
	;;;write DEVICE=<path>\XMA2EMS.SYS<parameter>		;
	.IF < N_XMA eq E_XMA_PRESENT > near and 		;AC000; if expanded memory present JW
	.IF < F_XMA eq E_XMA_YES >				;AN000;    and support to be included
	.THEN							;AN000;
	   .IF < N_MOD80 eq E_IS_MOD80 >			;AN000;JW
	   .THEN						;AN000;JW
	      MERGE_STRING	   SC_LINE,MC_LINE,S_STR120_1,SC_XMAEM_SYS;AN000;
	      APPEND_STRING	   SC_LINE, MC_LINE, S_XMAEM	;AN000;
	      WRITE_LINE	   SC_LINE			;AN000; write XMAEM command
	   .ENDIF						;AN000;JW
	   MERGE_STRING 	SC_LINE,MC_LINE,S_STR120_1,SC_XMA2EMS_SYS;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE, S_XMA2EMS	;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write XMA2EMS command
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = DEVICE=<path>\				;
	;;;write DEVICE=<path>\ANSI.SYS 			;
	;;;write DEVICE=<path>\ANSI.SYS /X ,additional parameter based on workspace option
	.IF < F_ANSI eq E_ANSI_YES >				;AN000; if ANSI support required
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,S_STR120_1,SC_ANSI_SYS;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE, S_ANSI	;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write ANSI command
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = DEVICE=<path>\				;
	;;;write DEVICE=<path>\RAMDRIVE.SYS <parameter>		;
	.IF < F_VDISK eq E_VDISK_YES >				;AN000; if VDISK support required
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,S_STR120_1,SC_VDISK_SYS;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE, S_VDISK	;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write VDISK command
	.ENDIF							;AN000;
								;
	;;;init S_STR120_2 to number of designates		;
	WORD_TO_CHAR		N_DESIGNATES, S_STR120_2	;AN000; set S_STR120_2 = no. of designates
								;
	;;;S_STR120_1 = DEVICE=<path>\				;
	;;;write DEVICE=<path>\DISPLAY.SYS CON=(<display>,437,<desig>)
	.IF < F_CPSW eq E_CPSW_YES > near			;AN000; if code page switching required
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,S_STR120_1,SC_DISPLAY_SYS;AN000;
	   .IF < ACTIVE eq EGA > or				;AN000;    if EGA adaptor
	   .IF < ALTERNATE eq EGA >				;AN000;
	   .THEN						;AN000;
	      APPEND_STRING	SC_LINE, MC_LINE, SD_DISPLAY_EGA;AN001;GHG    set display to EGA
	   .ELSEIF < ACTIVE eq LCD > or 			;AN000;    if LCD adaptor
	   .IF < ALTERNATE eq LCD >				;AN000;
	   .THEN						;AN000;
	      APPEND_STRING	SC_LINE, MC_LINE, SD_DISPLAY_LCD;AN001;GHG    set display to LCD
	   .ENDIF						;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE, SC_437	;AN000;    append hardware code page
	   APPEND_STRING	SC_LINE, MC_LINE, S_STR120_2	;AN000;    append no of designates
	   APPEND_STRING	SC_LINE, MC_LINE, SC_CLOSE_BRAC ;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write DISPLAY.SYS command
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = DEVICE=<path>\				;
	;;;S_STR120_2 = number of designates			;
	;;;write DEVICE=<path>\PRINTER.SYS LPT1=(<cdp parameters>,437,<desig>)
	;;;				   LPT2=(<cdp parameters>,437,<desig>)
	;;;				   LPT3=(<cdp parameters>,437,<desig>)
	;;;N_WORD_1 = parallel port number			;
	;;;N_WORD_2 set if driver is prepared			;
	INIT_VAR		N_WORD_1, 1			;AN000; set port number = 1
	INIT_VAR		N_WORD_2, 0			;AN000; set driver status = false
	.IF < F_CPSW eq E_CPSW_YES > near			;AN000; if code page switching required
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,S_STR120_1,SC_PRINTER_SYS;AN000;
	   .REPEAT						;AN000;    repeat code block
	      GET_PRINTER_PARAMS 0, N_WORD_1, N_RETCODE 	;AN000;       get printer parameters
	      .IF < N_RETCODE eq 1 > and near			;AN000;       if valid return
	      .IF < S_CP_DRIVER gt 0 > and near 		;AN000; 	 and driver and prepare
	      .IF < S_CP_PREPARE gt 0 > near			;AN000; 	 parameters valid
	      .THEN						;AN000;
		 APPEND_STRING	SC_LINE, MC_LINE, SC_LPT	;AN000; 	 append LPT
		 WORD_TO_CHAR	N_WORD_1, S_STR120_3		;AN000;
		 APPEND_STRING	SC_LINE, MC_LINE, S_STR120_3	;AN000; 	 append lpt number
		 APPEND_STRING	SC_LINE, MC_LINE, SC_EQUAL_OPEN ;AN000; 	 append =(
		 APPEND_STRING	SC_LINE, MC_LINE, S_CP_DRIVER	;AN000; 	 append driver parameters
		 APPEND_STRING	SC_LINE, MC_LINE, SC_COMMA	;AN000; 	 append comma
		 APPEND_STRING	SC_LINE, MC_LINE, S_STR120_2	;AN000; 	 append no of designates
		 APPEND_STRING	SC_LINE, MC_LINE, SC_CLOSE_BRAC ;AN000; 	 append close bracket
		 INIT_VAR	N_WORD_2, 1			;AN000; 	 set driver status = valid
	      .ENDIF						;AN000;
	      INC_VAR		N_WORD_1			;AN000;       inc printer number
	   .UNTIL < N_WORD_1 gt 3 > near			;AN000;    end of repeat block
	   .IF < N_WORD_2 eq 1 >				;AN000; if driver status is valid
	   .THEN						;AN000;
	      WRITE_LINE	SC_LINE 			;AN000;    write PRINTER.SYS command
	   .ENDIF						;AN000;
	.ENDIF							;AN000;
								;
	;;;init S_STR120_1 to INSTALL=<path>\			;
	MERGE_STRING		S_STR120_1,M_STR120_1,SC_INSTALL,S_DOS_PATH	 ;AN000;
								;
	;;;write INSTALL=<path>\KEYB.COM US,,<path>\KEYBOARD.SYS
	COMPARE_STRINGS 	S_KEYBOARD, S_US		;AN000;
	.IF < c > and						;AN000; if keyboard not US (will be handled in autoexec)
	.IF < N_KYBD_VAL eq E_KYBD_VAL_YES > near		;AN000; if keyboard is valid
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,S_STR120_1,SC_KEYB_C ;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE, S_US		;AN000;    append keyboard id = US
	   APPEND_STRING	SC_LINE, MC_LINE, SC_COMMAS	;AN000;    append comma
	   APPEND_STRING	SC_LINE, MC_LINE,S_DOS_PATH	;AN000;    append install path
	   APPEND_STRING	SC_LINE,MC_LINE,SC_KEYBOARD_SYS ;AN000;    append KEYBOARD.SYS
	   WRITE_LINE		SC_LINE 			;AN000;    write KEYB command
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = INSTALL=<path>\ 			;
	;;;write INSTALL=<path>\SHARE <parameter>		;
	.IF < F_SHARE eq E_SHARE_YES >				;AN000; if SHARE support required
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,S_STR120_1,SC_SHARE;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE, S_SHARE	;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write SHARE command
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = INSTALL=<path>\ 			;
	;;;write INSTALL=<path>\FASTOPEN <parameter>		;
	.IF < F_FASTOPEN eq E_FASTOPEN_YES >			;AN000; if FASTOPEN support required
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,S_STR120_1,SC_FASTOPEN;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE, S_FASTOPEN	;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write FASTOPEN command
	.ENDIF							;AN000;
								;
	;;;S_STR120_1 = INSTALL=<path>\ 			;
	;;;write INSTALL=<path>\NLSFUNC <path>\COUNTRY.SYS	;
	.IF < F_CPSW eq E_CPSW_YES >				;AN000; if code page switching support required
	.THEN							;AN000;
	   MERGE_STRING 	SC_LINE,MC_LINE,S_STR120_1,SC_NLSFUNC;AN000;
	   APPEND_STRING	SC_LINE,MC_LINE,S_DOS_PATH	;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE,SC_COUNTRY_SYS ;AN000;
	   WRITE_LINE		SC_LINE 			;AN000;    write NLSFUNC command
	.ENDIF							;AN000;
								;
	RET							;AN000;
CREATE_CONFIG_SYS	ENDP					;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Create DOSSHELL.BAT file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CREATE_SHELL_BAT     PROC					;AN000;DT
								;AN000;DT
	;;;write SHELL <parameter>				;AN000;DT
	.IF < I_DEST_DRIVE eq E_DEST_DRIVE_C >			;AN000; If install fixed disk ;AN111;JW
	   WRITE_LINE		SC_DRIVE_C			;AN013;JW
	   COPY_STRING		SC_LINE, MC_LINE, SC_CD 	;AN000;
	   APPEND_STRING	SC_LINE, MC_LINE, S_INSTALL_PATH ;AN000;
	   WRITE_LINE		SC_LINE 			;AN000; write CD path command
	.ENDIF							;AN000;
								;
	WRITE_LINE	     SC_SHELLC_1			;AN000;DT
	MERGE_STRING	     SC_LINE,MC_LINE,SC_AT_SIGN,SC_BREAK      ;AN092;SEH break=off
	APPEND_STRING	     SC_LINE,MC_LINE,S_OFF		;AN092;SEH
	WRITE_LINE	     SC_LINE				;AN092;SEH
	MERGE_STRING	     SC_LINE,MC_LINE,SC_SHELLC,S_SHELL	;AN000;DT
	WRITE_LINE	     SC_LINE				;AN000;DT    write SHELL command
	WRITE_LINE	     SC_SHELLC_2			;AN000;DT
								;
	;;;restore BREAK=<parameter>				;
	.IF < S_BREAK gt 0 >					;AN000;JW if field length > zero
	   MERGE_STRING 	SC_LINE,MC_LINE,SC_AT_SIGN,SC_BREAK ;AN000;JW
	   APPEND_STRING	SC_LINE,MC_LINE,S_BREAK 	;AN000;JW
	   WRITE_LINE		SC_LINE 			;AN000;JW    write BREAK command
	.ENDIF							;AN000;JW
								;
								;
	RET							;AN000;DT
CREATE_SHELL_BAT     ENDP					;AN000;DT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SELECT	 ENDS							;AN000;
	 END							;AN000;
