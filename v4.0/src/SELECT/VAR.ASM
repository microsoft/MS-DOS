PAGE	60,132				   ;AN000;
NAME	SELECT				   ;AN000;
TITLE	VARIABLES - DOS - SELECT.EXE	   ;AN000;
SUBTTL	var.asm				   ;AN000;
.ALPHA					   ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	VAR.ASM:  Copyright 1988 Microsoft
;
;	DATE:	 August 8/87
;
;	COMMENTS: Assemble with MASM 3.0 (using the /A option)
;
;		  Module contains variables used by SELECT.
;
;	CHANGE HISTORY:
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;
	       INCLUDE	SYSMSG.INC		;AN000;
	       MSG_UTILNAME <SELECT>		;AN000;
						;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	SEGMENT BYTE PUBLIC 'DATA'              ;AN000;
		INCLUDE VARSTRUC.INC		;AN000;
		INCLUDE SEL_FILE.INC		;AN000;
						;
		PUBLIC	E_ENTER,E_TAB,E_ESCAPE	;AN000;
						;
ESCAPE		EQU	27			;AN000;
ENTER		EQU	13			;AN000;
TAB		EQU	 9			;AN000;
F1		EQU	59			;AN000;
F3		EQU	61			;AN000;
SPACE		EQU	32			;AN000;
						;
		PUBLIC	DRIVE_A,DRIVE_B 	;AN000;JW
DRIVE_A 	EQU	0			;AN000;JW
DRIVE_B 	EQU	1			;AN000;JW
						;
MSG_SERVICES <MSGDATA>				;AN000;
						;
		PUBLIC	SUPPORT_STATUS		;AN000;
SUPPORT_STATUS	DW	?			;AN000;
		DW	?			;AN000;
		DW	?			;AN000;
		DW	?			;AN000;
		DW	?			;AN000;
		DW	?			;AN000;
		DW	?			;AN000;
		DW	?			;AN000;
		DW	?			;AN000;
		DW	?			;AN000;
						;
		PUBLIC	I_USER_INDEX		;AN000;
I_USER_INDEX	DW	?			;AN000; Index value for scroll list
						;
		PUBLIC	N_USER_NUMERIC,MIN_INPUT_VAL,MAX_INPUT_VAL;AN000;
N_USER_NUMERIC	DW	?			;AN000; Input value for numeric fields
MIN_INPUT_VAL	DW	?			;AN000; Minimum value of input
MAX_INPUT_VAL	DW	?			;AN000; Maximum value of input
						;
		PUBLIC	S_USER_STRING,P_USER_STRING,M_USER_STRING;AN000;
S_USER_STRING	DW	M_USER_STRING		;AN000; Length of string
P_USER_STRING	DB	120 DUP(?)		;AN000; Actual string
M_USER_STRING	EQU	$ - P_USER_STRING	;AN000;
						;
		PUBLIC	N_VALID_KEYS		;AN000;
N_VALID_KEYS	DW	?			;AN000; Valid keys for current input
						;
		PUBLIC	N_USER_FUNC, E_ENTER, E_ESCAPE, E_TAB, E_F3, E_SPACE ;AN000;
N_USER_FUNC	DW	?			      ;AN000; Function type entered by user
E_ENTER 	=	ENTER			      ;AN000; Enter key
E_ESCAPE	=	ESCAPE			      ;AN000; Escape key
E_TAB		=	TAB			      ;AN000; Tab key
E_F3		=	F3*256			      ;AN000; Function key 3  (F3,0)
E_SPACE 	=	SPACE ;AN000;		      ;
						      ;
		PUBLIC	FK_ENT_F3, FK_ENT_F3_LEN      ;AN000;
FK_ENT_F3	DB	ENTER,0,F3		      ;AN000; Enter, F3
FK_ENT_F3_LEN	EQU	($-FK_ENT_F3)		      ;AN000;
						      ;
		PUBLIC	FK_ENT_ESC, FK_ENT_ESC_LEN    ;AN000;
FK_ENT_ESC	DB	ENTER,ESCAPE		      ;AN000; Enter, Esc
FK_ENT_ESC_LEN	EQU	($-FK_ENT_ESC)		      ;AN000;
						      ;
		PUBLIC	FK_ENT_ESC_F3, FK_ENT_ESC_F3_LEN ;AN000;
FK_ENT_ESC_F3	DB	ENTER,ESCAPE,0,F3	      ;AN000; Enter, Esc
FK_ENT_ESC_F3_LEN  EQU	($-FK_ENT_ESC_F3)	      ;AN000;
						      ;
		PUBLIC	FK_ENT, FK_ENT_LEN	      ;AN000;
FK_ENT		DB	ENTER			      ;AN000; Enter
FK_ENT_LEN	EQU	($-FK_ENT)		      ;AN000;
						      ;
		PUBLIC	FK_TEXT, FK_TEXT_LEN	      ;AN000;
FK_TEXT 	DB	ENTER,ESCAPE,0,F1,0,F3	      ;AN000; Enter, ESC, F1, F3
FK_TEXT_LEN	EQU	($-FK_TEXT)		      ;AN000;
						      ;
		PUBLIC	FK_SCROLL, FK_SCROLL_LEN      ;AN000;
FK_SCROLL	DB	ENTER,ESCAPE,0,F1,0,F3	      ;AN000; Enter,ESC, F1, F3
FK_SCROLL_LEN	EQU	($-FK_SCROLL)		      ;AN000;
						      ;
		PUBLIC	FK_TAB, FK_TAB_LEN	      ;AN000;
FK_TAB		DB	TAB,ENTER,ESCAPE,0,F1,0,F3    ;AN000;Enter, ESC, F1, F3, Tab
FK_TAB_LEN	EQU	($-FK_TAB)		      ;AN000;
						      ;
		PUBLIC	FK_REVIEW, FK_REVIEW_LEN      ;AN000;
FK_REVIEW	DB	ENTER,SPACE,ESCAPE,0,F1,0,F3  ;AN000;Enter,ESC,F1,F3,SPACE
FK_REVIEW_LEN	EQU	($-FK_REVIEW)		      ;AN000;
						      ;
		PUBLIC	FK_DATE, FK_DATE_LEN	      ;AN000;
FK_DATE 	DB	TAB,ENTER,0,F1		      ;AN000; Enter, ESC, F1, Tab
FK_DATE_LEN	EQU	($-FK_DATE)		      ;AN000;
						      ;
		PUBLIC	FK_FORMAT, FK_FORMAT_LEN      ;AN000;
FK_FORMAT	DB	ENTER,0,F1		      ;AN000;
FK_FORMAT_LEN	EQU	($-FK_FORMAT)		      ;AN000;
						      ;
		PUBLIC	FK_REBOOT, FK_REBOOT_LEN      ;AN000;
FK_REBOOT	DB	?			      ;AN000; only CTRL+ALT+DEL keys valid
FK_REBOOT_LEN	EQU	0			      ;AN000;
						      ;
		PUBLIC	ERROR_KEYS,ERROR_KEYS_LEN,E_QUIT,E_RETURN ;AN000;
ERROR_KEYS	DB    0,F3,ENTER		      ;AN000;
ERROR_KEYS_LEN	EQU   $-ERROR_KEYS		      ;AN000;
E_QUIT		EQU	1			      ;AN000;
E_RETURN	EQU	2			      ;AN000;
						      ;
		PUBLIC	E_YES, E_NO, E_NA	      ;AN000;
E_YES		EQU	1			      ;AN000;
E_NO		EQU	2			      ;AN000;
E_NA		EQU	6			      ;AN000;
						      ;
		PUBLIC	N_SELECT_MODE, E_SELECT_MENU, E_SELECT_FDISK, E_SELECT_INV ;AN000;
N_SELECT_MODE	DW	?			      ;AN000; SELECT command line mode
E_SELECT_MENU	EQU	0			      ;AN000; MENU mode
E_SELECT_FDISK	EQU	1			      ;AN000; FDISK mode
E_SELECT_INV	EQU	0FFH			      ;AN000; Invalid parameter
						      ;
		PUBLIC	N_FORMAT_MODE,E_FORMAT_SELECT,E_FORMAT_NEW,E_FORMAT_USED ;AN000;
N_FORMAT_MODE	DW	?			      ;AN000; FORMAT mode specified on command line
E_FORMAT_SELECT EQU	1			      ;AN000; new disk - select to format all partitions
E_FORMAT_NEW	EQU	2			      ;AN000; new disk - user to format all partitions
E_FORMAT_USED	EQU	3			      ;AN000; used disk - user to format all partitions
						      ;
		PUBLIC	S_SPACE 		      ;AN000;
S_SPACE 	DW	M_SPACE 		      ;AN000;
P_SPACE 	DB	' '                           ;AN000;
M_SPACE 	EQU	$ - P_SPACE		      ;AN000;
						      ;
		PUBLIC	S_OFF			      ;AN000;
S_OFF		DW	M_OFF			      ;AN000; OFF parameter
P_OFF		DB	'OFF'                         ;AN000;
M_OFF		EQU	$ - P_OFF		      ;AN000;
						      ;
		PUBLIC	S_ON			      ;AN000;
S_ON		DW	M_ON			      ;AN000; ON parameter
P_ON		DB	'ON'                          ;AN000;
M_ON		EQU	$ - P_ON		      ;AN000;
						      ;
		PUBLIC	I_WORKSPACE,N_WORK_PREV,E_WORKSPACE_BAL,E_WORKSPACE_MIN,E_WORKSPACE_MAX ;AN000;
I_WORKSPACE	DW	?			      ;AN000; user workspace option
N_WORK_PREV	DW	?			      ;AN000; previous workspace option
E_WORKSPACE_MIN EQU	1			      ;AN000; minimize DOS functions
E_WORKSPACE_BAL EQU	2			      ;AN000; balance DOS function
E_WORKSPACE_MAX EQU	3			      ;AN000; maximize DOS functions
						      ;
		PUBLIC	S_ANSI,M_ANSI,F_ANSI,E_ANSI_YES,D_ANSI_1,E_ANSI_B,E_ANSI_C,E_ANSI_NO ;AN000;
S_ANSI		DW	M_ANSI			      ;AN000; ANSI command
P_ANSI		DB	2 DUP(?)		      ;AN000;
M_ANSI		EQU	$ - P_ANSI		      ;AN000;
D_ANSI_1	DW	2			      ;AN000;
		DB	'/X'                          ;AN000;
F_ANSI		DW	?			      ;AN000; ANSI support required indicator
E_ANSI_NO	=	E_NO			      ;AN000; ANSI support not required
E_ANSI_YES	=	E_YES			      ;AN000; include ANSI.SYS command
E_ANSI_B	EQU	2			      ;AN000;
E_ANSI_C	EQU	3			      ;AN000;
						      ;
		PUBLIC	S_APPEND, F_APPEND, E_APPEND_YES, E_APPEND_NO, M_APPEND ;AN000;
		PUBLIC	S_APPEND_P, M_APPEND_P	      ;AN000;JW
S_APPEND	DW	M_APPEND		      ;AN000; APPEND command
P_APPEND	DB	120 DUP(?)		      ;AN000;
M_APPEND	EQU	$ - P_APPEND		      ;AN000;
S_APPEND_P	DW	2			      ;AN000; APPEND command paramters	 JW
P_APPEND_P	DB	'/E'                          ;AN000; Default parameter          JW
		DB	38 DUP(' ')                   ;AN000;                            JW
M_APPEND_P	EQU	$ - P_APPEND_P		      ;AN000;			   JW
F_APPEND	DW	?			      ;AN000; APPEND support indicator
E_APPEND_NO	=	E_NO			      ;AN000; APPEND support not required
E_APPEND_YES	=	E_YES			      ;AN000; include APPEND command
						      ;
		PUBLIC	S_BREAK, M_BREAK, ST_BREAK, MT_BREAK ;AN000;
S_BREAK 	DW	M_BREAK 		      ;AN000; BREAK command
P_BREAK 	DB	3 DUP(?)		      ;AN000;
M_BREAK 	EQU	$ - P_BREAK		      ;AN000;
ST_BREAK	DW	MT_BREAK		      ;AN000; temp location for BREAK command
PT_BREAK	DB	M_BREAK DUP(?)		      ;AN000;
MT_BREAK	EQU	$ - PT_BREAK		      ;AN000;
						      ;
		PUBLIC	S_BUFFERS,M_BUFFERS,D_BUFFERS_1,D_BUFFERS_2,ST_BUFFERS,MT_BUFFERS ;AN000;
S_BUFFERS	DW	M_BUFFERS		      ;AN000; BUFFERS command
P_BUFFERS	DB	7 DUP(?)		      ;AN000;
M_BUFFERS	EQU	$ - P_BUFFERS		      ;AN000;
D_BUFFERS_1	DW	2			      ;AN000;
		DB	'20'                          ;AN000;
D_BUFFERS_2	DW	4			      ;AN000;
		DB	'25,8'                        ;AC041;SEH for optimal performance
ST_BUFFERS	DW	MT_BUFFERS		      ;AN000; temp location for BUFFERS parameters
PT_BUFFERS	DB	M_BUFFERS DUP(?)	      ;AN000;
MT_BUFFERS	EQU	$ - PT_BUFFERS		      ;AN000;
						      ;
		PUBLIC	S_CPSW, M_CPSW, F_CPSW, E_CPSW_YES, E_CPSW_NO, E_CPSW_NA ;AN000;
		PUBLIC	E_CPSW_B, E_CPSW_C, ST_CPSW, MT_CPSW ;AN000;
		PUBLIC	N_CPSW, E_CPSW_NOT_VAL, E_CPSW_NOT_REC, E_CPSW_VALID ;AN000;
S_CPSW		DW	M_CPSW			      ;AN000; CPSW command
P_CPSW		DB	3 DUP(?)		      ;AN000;
M_CPSW		EQU	$ - P_CPSW		      ;AN000;
F_CPSW		DW	?			      ;AN000; CPSW support indicator
E_CPSW_NO	=	E_NO			      ;AN000; CPSW support not required
E_CPSW_YES	=	E_YES			      ;AN000; include CPSW command
E_CPSW_NA	=	E_NA			      ;AN000; CPSW not available
E_CPSW_B	EQU	1			      ;AN000;
E_CPSW_C	EQU	1			      ;AN000;
ST_CPSW 	DW	MT_CPSW 		      ;AN000; temp location for CPSW command
PT_CPSW 	DB	M_CPSW DUP(?)		      ;AN000;
MT_CPSW 	EQU	$ - PT_CPSW		      ;AN000;
N_CPSW		DW	?			      ;AN000; code page switching indicator for country
E_CPSW_NOT_VAL	EQU	0			      ;AN000; code page switching not allowed
E_CPSW_NOT_REC	EQU	1			      ;AN000; code page switching not recommended
E_CPSW_VALID	EQU	2			      ;AN000; code page switching recommended
						      ;
		PUBLIC	S_FASTOPEN, M_FASTOPEN, F_FASTOPEN, E_FASTOPEN_YES ;AN000;
		PUBLIC	E_FASTOPEN_NO, D_FASTOPEN_1, D_FASTOPEN_2, E_FASTOPEN_C ;AN000;
S_FASTOPEN	DW	M_FASTOPEN		      ;AN000; FASTOPEN command
P_FASTOPEN	DB	60 DUP(?)		      ;AN000;
M_FASTOPEN	EQU	$ - P_FASTOPEN		      ;AN000;
D_FASTOPEN_1	DW	10			      ;AN000;
		DB	'C:=(50,25)'                  ;AN000;
D_FASTOPEN_2	DW	12			      ;AN000;
		DB	'C:=(150,150)'                ;AC078; SEH changed from 200,200 to 150,150 due to expanded mem problems ;AC041; SEH for optimal performance
F_FASTOPEN	DW	?			      ;AN000; FASTOPEN support indicator
E_FASTOPEN_NO	=	E_NO			      ;AN000; FASTOPEN support not required
E_FASTOPEN_YES	=	E_YES			      ;AN000; include FASTOPEN command
E_FASTOPEN_C	EQU	4			      ;AN000;
						      ;
		PUBLIC	S_FCBS, M_FCBS, D_FCBS_1, ST_FCBS, MT_FCBS ;AN000;
S_FCBS		DW	M_FCBS			      ;AN000; FCBS command
P_FCBS		DB	7 DUP(?)		      ;AN000;
M_FCBS		EQU	$ - P_FCBS		      ;AN000;
D_FCBS_1	DW	4			      ;AN000;
		DB	'20,8'                        ;AN000;
ST_FCBS 	DW	MT_FCBS 		      ;AN000; temp location for FCBS command
PT_FCBS 	DB	M_FCBS DUP(?)		      ;AN000;
MT_FCBS 	EQU	$ - PT_FCBS		      ;AN000;
						      ;
		PUBLIC	S_FILES, M_FILES, D_FILES_1, D_FILES_2, ST_FILES, MT_FILES ;AN000;
S_FILES 	DW	M_FILES 		      ;AN000; FILES command
P_FILES 	DB	3 DUP(?)		      ;AN000;
M_FILES 	EQU	$ - P_FILES		      ;AN000;
D_FILES_1	DW	2			      ;AN000;
		DB	'20'                          ;AN000;
D_FILES_2	DW	1			      ;AN000;
		DB	'8'                           ;AN000;
ST_FILES	DW	MT_FILES		      ;AN000; temp location for FILES command
PT_FILES	DB	M_FILES DUP(?)		      ;AN000;
MT_FILES	EQU	$ - PT_FILES		      ;AN000;
						      ;
		PUBLIC	S_GRAPHICS, M_GRAPHICS, F_GRAPHICS, E_GRAPHICS_YES ;AN000;
		PUBLIC	E_GRAPHICS_NO, E_GRAPHICS_B, E_GRAPHICS_C ;AN000;
S_GRAPHICS	DW	M_GRAPHICS		      ;AN000; GRAPHICS command
P_GRAPHICS	DB	80 DUP(?)		      ;AN000;
M_GRAPHICS	EQU	$ - P_GRAPHICS		      ;AN000;
F_GRAPHICS	DW	?			      ;AN000; GRAPHICS support indicator
E_GRAPHICS_NO	=	E_NO			      ;AN000; GRAPHICS support not required
E_GRAPHICS_YES	=	E_YES			      ;AN000; include GRAPHICS command
E_GRAPHICS_B	EQU	4			      ;AN000;
E_GRAPHICS_C	EQU	6			      ;AN000;
						      ;
		PUBLIC	F_GRAFTABL, E_GRAFTABL_YES, E_GRAFTABL_NO, E_GRAFTABL_NA ;AN000;
		PUBLIC	E_GRAFTABL_B, E_GRAFTABL_C ;AN000;
F_GRAFTABL	DW	?			      ;AN000; GRAFTABL support indicator
E_GRAFTABL_NO	=	E_NO			      ;AN000; GRAFTABL support not required
E_GRAFTABL_YES	=	E_YES			      ;AN000; include GRAFTABL command
E_GRAFTABL_NA	=	E_NA			      ;AN000; GRAFTABL not available
E_GRAFTABL_B	EQU	3			      ;AN000;
E_GRAFTABL_C	EQU	5			      ;AN000;
						      ;
		PUBLIC	S_LASTDRIVE,M_LASTDRIVE,D_LASTDRIVE_1,ST_LASTDRIVE,MT_LASTDRIVE ;AN000;
S_LASTDRIVE	DW	M_LASTDRIVE		      ;AN000; LASTDRIVE command
P_LASTDRIVE	DB	1 DUP(?)		      ;AN000;
M_LASTDRIVE	EQU	$ - P_LASTDRIVE 	      ;AN000;
D_LASTDRIVE_1	DW	1			      ;AN000;
		DB	'E'                           ;AN000;
ST_LASTDRIVE	DW	MT_LASTDRIVE		      ;AN000; temp location for LASTDRIVE command
PT_LASTDRIVE	DB	M_LASTDRIVE DUP(?)	      ;AN000;
MT_LASTDRIVE	EQU	$ - PT_LASTDRIVE	      ;AN000;
						      ;
		PUBLIC	S_PATH, M_PATH, F_PATH, E_PATH_YES, E_PATH_NO ;AN000;
S_PATH		DW	M_PATH			      ;AN000; PATH command
P_PATH		DB	120 DUP(?)		      ;AN000;
M_PATH		EQU	$ - P_PATH		      ;AN000;
F_PATH		DW	?			      ;AN000; PATH support indicator
E_PATH_NO	=	E_NO			      ;AN000; PATH support not required
E_PATH_YES	=	E_YES			      ;AN000; include PATH command
						      ;
		PUBLIC	S_PROMPT,M_PROMPT,F_PROMPT,E_PROMPT_YES,E_PROMPT_NO,D_PROMPT_1 ;AN000;
S_PROMPT	DW	M_PROMPT		      ;AN000; PROMPT command
P_PROMPT	DB	120 DUP(?)		      ;AN000;
M_PROMPT	EQU	$ - P_PROMPT		      ;AN000;
D_PROMPT_1	DW	4			      ;AN000;
		DB	'$P$G'                        ;AN000;
F_PROMPT	DW	?			      ;AN000; PROMPT command indicator
E_PROMPT_NO	=	E_NO			      ;AN000; PROMPT command not to be included
E_PROMPT_YES	=	E_YES			      ;AN000; include PROMPT command
						      ;
		PUBLIC	S_SHARE,M_SHARE,F_SHARE,E_SHARE_YES,E_SHARE_NO,E_SHARE_C ;AN000;
S_SHARE 	DW	M_SHARE 		      ;AN000; SHARE command
P_SHARE 	DB	15 DUP(?)		      ;AN000;
M_SHARE 	EQU	$ - P_SHARE		      ;AN000;
F_SHARE 	DW	?			      ;AN000; SHARE support indicator
E_SHARE_NO	=	E_NO			      ;AN000; SHARE support not required
E_SHARE_YES	=	E_YES			      ;AN000; include SHARE command
E_SHARE_C	EQU	7			      ;AN000;
						      ;
		PUBLIC	S_SHELL, M_SHELL, F_SHELL, E_SHELL_YES, E_SHELL_NO ;AN000;
		PUBLIC	D_SHELL_1, D_SHELL_2, E_SHELL_B, E_SHELL_C	   ;AC018;SEH ;AC000;JW
S_SHELL 	DW	M_SHELL 		      ;AN000; SHELL command
P_SHELL 	DB	115 DUP(?)		      ;AN000;
M_SHELL 	EQU	$ - P_SHELL		      ;AN000;
D_SHELL_1	DW	M_SHELL_1		      ;AN000;
P_SHELL_1	DB	'/TRAN/MAINT/MENU/EXIT/SND/PROMPT'  ;AC077;SEH ;AC000;JW
M_SHELL_1	EQU	$ - P_SHELL_1		      ;AN000;
D_SHELL_2	DW	M_SHELL_2		      ;AN000;
P_SHELL_2	DB	'/TRAN/COLOR/DOS/MENU/MUL'                 ;AC071;SEH ;AC016;SEH  ;AC000;JW
		DB	'/SND/MEU:SHELL.MEU/CLR:SHELL.CLR/PROMPT/MAINT/EXIT/SWAP/DATE'  ;AC012;SEH  ;AC000;JW
M_SHELL_2	EQU	$ - P_SHELL_2		      ;AN000;
F_SHELL 	DW	?			      ;AN000; SHELL support indicator
E_SHELL_NO	=	E_NO			      ;AN000; SHELL support not required
E_SHELL_YES	=	E_YES			      ;AN000; include SHELL command
E_SHELL_B	=	5
E_SHELL_C	=	8
						      ;
		PUBLIC	MACHINE_TYPE, PS2_FLAG, MOD25_OR_MOD30	;AN000;JW
MACHINE_TYPE	DB	?			      ;AN000;JW
PS2_FLAG	DB	?			      ;AN000;JW
MOD25_OR_MOD30	EQU	0FAH			      ;AN000;JW
						      ;
		PUBLIC	S_STACKS,M_STACKS,ST_STACKS,MT_STACKS ;AN000;
S_STACKS	DW	M_STACKS		      ;AN000; STACKS command
P_STACKS	DB	6 DUP(?)		      ;AN000;
M_STACKS	EQU	$ - P_STACKS		      ;AN000;
ST_STACKS	DW	MT_STACKS		      ;AN000; temp location for STACKS command
PT_STACKS	DB	M_STACKS DUP(?) 	      ;AN000;
MT_STACKS	EQU	$ - PT_STACKS		      ;AN000;
						      ;
		PUBLIC	S_VDISK,M_VDISK,F_VDISK,E_VDISK_YES,E_VDISK_NO,E_VDISK_B,E_VDISK_C ;AN000;
S_VDISK 	DW	M_VDISK 		      ;AN000; VDISK command
P_VDISK 	DB	20 DUP(?)		      ;AN000;
M_VDISK 	EQU	$ - P_VDISK		      ;AN000;
F_VDISK 	DW	?			      ;AN000; VDISK support indicator
E_VDISK_NO	=	E_NO			      ;AN000; VDISK support not required
E_VDISK_YES	=	E_YES			      ;AN000; include VDISK command
E_VDISK_B	EQU	6			      ;AN000;
E_VDISK_C	EQU	9			      ;AN000;
						      ;
		PUBLIC	S_VERIFY, M_VERIFY, ST_VERIFY, MT_VERIFY ;AN000;
S_VERIFY	DW	M_VERIFY		      ;AN000; VERIFY command
P_VERIFY	DB	3 DUP(?)		      ;AN000;
M_VERIFY	EQU	$ - P_VERIFY		      ;AN000;
ST_VERIFY	DW	MT_VERIFY		      ;AN000; temp location for VERIFY command
PT_VERIFY	DB	M_VERIFY DUP(?) 	      ;AN000;
MT_VERIFY	EQU	$ - PT_VERIFY		      ;AN000;
						      ;
		PUBLIC	S_XMAEM, M_XMAEM	      ;AN000;
S_XMAEM 	DW	M_XMAEM 		      ;AN000; XMAEM command
P_XMAEM 	DB	40 DUP(?)		      ;AN000;
M_XMAEM 	EQU	$ - P_XMAEM		      ;AN000;
						      ;
		PUBLIC	S_XMA2EMS, M_XMA2EMS, D_XMA2EMS_1, F_XMA, E_XMA_NO, E_XMA_NA ;AN000;
		PUBLIC	E_XMA_YES, E_XMA_C, N_XMA, E_XMA_ABSENT, E_XMA_PRESENT ;AN000;
S_XMA2EMS	DW	M_XMA2EMS		      ;AN000; XMA2EMS command
P_XMA2EMS	DB	40 DUP(?)		      ;AN000;
M_XMA2EMS	EQU	$ - P_XMA2EMS		      ;AN000;
D_XMA2EMS_1	DW	30			      ;AN000;
		DB	'FRAME=D000 P254=C000 P255=C400'    ;AC044;SEH ;AC040;SEH ;AN000;JW
F_XMA		DW	?			      ;AN000; Expanded Memory support indicator
E_XMA_NO	=	E_NO			      ;AN000; Expanded Memory support not required
E_XMA_YES	=	E_YES			      ;AN000; include XMAEM, XMA2EMS commands
E_XMA_NA	=	E_NA			      ;AN000; Expanded memory not available
E_XMA_C 	EQU	2			      ;AN000;
N_XMA		DW	?			      ;AN000; Expanded memory presence indicator
E_XMA_ABSENT	EQU	0			      ;AN000; expanded memory not present
E_XMA_PRESENT	EQU	1			      ;AN000; expanded memory is present
						      ;
		PUBLIC	N_MOD80, E_IS_MOD80, E_NOT_MOD80 ;AN000;JW
N_MOD80 	DW	?			      ;AN000; Model 80 indicator
E_NOT_MOD80	EQU	0			      ;AN000; is not a model 80
E_IS_MOD80	EQU	1			      ;AN000; is a model 80
						      ;
		PUBLIC	I_DEST_DRIVE, E_DEST_DRIVE_A, E_DEST_DRIVE_B, E_DEST_DRIVE_C ;AN111;JW
I_DEST_DRIVE	DW	?			      ;AN000; Install destination drive - set by CHECK_VALID_MEDIA
E_DEST_DRIVE_C	EQU	1			      ;AN000; drive C:
E_DEST_DRIVE_B	EQU	2			      ;AN000; drive B:
E_DEST_DRIVE_A	EQU	3			      ;AN111; drive A:
						      ;
		PUBLIC	N_DRIVE_OPTION, E_OPTION_B_C, E_OPTION_A_C ;AN111;JW
N_DRIVE_OPTION	DW	?			      ;AN111; Which options to choose from JW
E_OPTION_B_C	EQU	1			      ;AN111; install to B or C 	     JW
E_OPTION_A_C	EQU	2			      ;AN111; install to A or C 	     JW
						      ;
		PUBLIC	N_DEST_DRIVE, E_DEST_SELECT, E_DEST_USER ;AN000;
N_DEST_DRIVE	DB	?			      ;AN000; destination drive determined by user or SELECT
E_DEST_SELECT	EQU	0			      ;AN000; SELECT will determine default drive
E_DEST_USER	EQU	1			      ;AN000; user will select destination drive
						      ;
		PUBLIC	N_DISKETTE_TOT, N_ZERO_DISKETTE, N_DISKETTE_A, N_DISKETTE_B ;AN000;
		PUBLIC	E_DISKETTE_INV, E_DISKETTE_360, E_DISKETTE_720, E_DISKETTE_1200, E_DISKETTE_1440 ;AN000;
N_DISKETTE_TOT	DB	?			      ;AN000; number of diskette drives
N_ZERO_DISKETTE EQU	0			      ;AN000;
N_DISKETTE_A	DB	?			      ;AN000; drive A: diskette status
N_DISKETTE_B	DB	?			      ;AN000; drive B: diskette status
E_DISKETTE_INV	EQU	0FFH			      ;AN000; diskette not present
E_DISKETTE_360	EQU	0			      ;AN000; diskette media is 360K (5.25 inch)
E_DISKETTE_1200 EQU	1			      ;AN000; diskette media is 1.2M (5.25 inch)
E_DISKETTE_720	EQU	2			      ;AN000; diskette media is 720K (3.5 inch)
E_DISKETTE_1440 EQU	7			      ;AN000; diskette media is 1.44M (3.5 inch)
						      ;
		PUBLIC	S_DEST_DRIVE,M_DEST_DRIVE,S_DRIVE_A ;AN000;
S_DEST_DRIVE	DW	M_DEST_DRIVE		      ;AN000; Destination drive to install DOS
P_DEST_DRIVE	DB	'C:\'                         ;AN000;
M_DEST_DRIVE	EQU	$ - P_DEST_DRIVE	      ;AN000;
S_DRIVE_A	DW	M_DRIVE_A		      ;AN000;
P_DRIVE_A	DB	'A:\'                         ;AN000;
M_DRIVE_A	EQU	$ - P_DRIVE_A		      ;AN000;
						      ;
		PUBLIC	S_C_DRIVE,S_A_DRIVE,S_B_DRIVE ;AC039;SEH;AN000;JW
S_C_DRIVE	DW	M_C_DRIVE		      ;AN000; Destination drive w/o backslash JW
P_C_DRIVE	DB	'C:'                          ;AN000;
M_C_DRIVE	EQU	$ - P_C_DRIVE		      ;AN000;
S_A_DRIVE	DW	M_A_DRIVE		      ;AN039;SEH Destination drive w/o backslash
P_A_DRIVE	DB	'A:'                          ;AN039;SEH
M_A_DRIVE	EQU	$ - P_A_DRIVE		      ;AN039;SEH
S_B_DRIVE	DW	M_B_DRIVE		      ;AN039;SEH Destination drive w/o backslash
P_B_DRIVE	DB	'B:'                          ;AN039;SEH
M_B_DRIVE	EQU	$ - P_B_DRIVE		      ;AN039;SEH
						      ;
		PUBLIC	S_DOS_LOC, M_DOS_LOC, D_DOS_LOC_1 ;AN000;
S_DOS_LOC	DW	M_DOS_LOC		      ;AN000; user defined DOS location path for drive C:
P_DOS_LOC	DB	37 DUP(?)		      ;AN000;
M_DOS_LOC	EQU	$ - P_DOS_LOC		      ;AN000;
D_DOS_LOC_1	DW	3			      ;AN000;
		DB	'DOS'                         ;AN000;
						      ;
		PUBLIC	S_INSTALL_PATH, M_INSTALL_PATH ;AN000;
S_INSTALL_PATH	DW	M_INSTALL_PATH		      ;AN000; install path including drive
P_INSTALL_PATH	DB	40 DUP( )		      ;AN000;
M_INSTALL_PATH	EQU	$ - P_INSTALL_PATH	      ;AN000;
						      ;
		PUBLIC	I_CTY_KYBD, E_CTY_KB_PREDEF, E_CTY_KB_USER ;AN000;
I_CTY_KYBD	DW	?			      ;AN000; index for country and keyboard screen
E_CTY_KB_PREDEF EQU	1			      ;AN000; Use predefined country/keyboard
E_CTY_KB_USER	EQU	2			      ;AN000; user specified country/keyboard to be used
						      ;
		PUBLIC	N_CTY_LIST, E_CTY_LIST_1, E_CTY_LIST_2 ;AN000;
N_CTY_LIST	DW	?			      ;AN000; Country code scroll list identifier
E_CTY_LIST_1	EQU	1			      ;AN000; code 001 - 046
E_CTY_LIST_2	EQU	2			      ;AN000; code 047 - 972
						      ;
		PUBLIC	I_COUNTRY, N_COUNTRY	      ;AN000;
I_COUNTRY	DW	?			      ;AN000; Index into country code list
N_COUNTRY	DW	?			      ;AN000; Country Code
						      ;
		PUBLIC	N_KYBD_LIST, E_KYBD_LIST_1, E_KYBD_LIST_2 ;AN000;
N_KYBD_LIST	DW	?			      ;AN000; Keyboard code scroll list identifier
E_KYBD_LIST_1	EQU	1			      ;AN000; code BE - NO
E_KYBD_LIST_2	EQU	2			      ;AN000; code PO - none
						      ;
		PUBLIC	I_KEYBOARD		      ;AN000;
I_KEYBOARD	DW	?			      ;AN000; Index into keyboard code list
						      ;
		PUBLIC	S_KEYBOARD,N_KYBD_VAL,E_KYBD_VAL_YES,E_KYBD_VAL_NO ;AN000;
		PUBLIC	M_KEYBOARD,E_KYBD_VAL_DEF     ;AN000;
S_KEYBOARD	DW	M_KEYBOARD		      ;AN000;
P_KEYBOARD	DB	2 DUP(?)		      ;AN000; Keyboard code
M_KEYBOARD	EQU	$ - P_KEYBOARD		      ;AN000;
N_KYBD_VAL	DB	?			      ;AN000; Keyboard code valid indicator
E_KYBD_VAL_NO	EQU	0			      ;AN000; Keyboard code is not valid
E_KYBD_VAL_YES	EQU	1			      ;AN000; Keyboard code is valid
E_KYBD_VAL_DEF	EQU	2			      ;AN000; Default keyboard (US) is to be used
						      ;       This state is defined so that keyboard screen
						      ;       will be displayed with "None" option
						      ;
		PUBLIC	N_DESIGNATES, N_CP_PRI, N_CP_SEC, N_CTY_RES ;AN000;
N_DESIGNATES	DW	?			      ;AN000; number of designates
N_CP_PRI	DW	?			      ;AN000; Primary code page
N_CP_SEC	DW	?			      ;AN000; Secondary code page
N_CTY_RES	DB	?			      ;AN000; reserved byte from country table
						      ;
		PUBLIC	I_KYBD_ALT, S_KYBD_ALT, M_KYBD_ALT, N_KYBD_ALT ;AN000;
		PUBLIC	E_KYBD_ALT_NO, E_KYBD_ALT_YES ;AN000;
I_KYBD_ALT	DW	?			      ;AN000; Index into alternate keyboard code list
S_KYBD_ALT	DW	M_KYBD_ALT		      ;AN000;
P_KYBD_ALT	DB	2 DUP(?)		      ;AN000; Keyboard code
M_KYBD_ALT	EQU	$ - P_KYBD_ALT		      ;AN000;
N_KYBD_ALT	DB	?			      ;AN000; Alternate keyboards present indicator
E_KYBD_ALT_NO	EQU	0			      ;AN000; no alternate keyboards
E_KYBD_ALT_YES	EQU	1			      ;AN000; are alternate keyboards are present
						      ;
		PUBLIC	N_KYB_LOAD,E_KYB_LOAD_SUC,E_KYB_LOAD_ERR,E_KYB_LOAD_US,E_KYB_LOAD_UND ;AN000;
N_KYB_LOAD	DW	?			      ;AN000; KEYB load status
E_KYB_LOAD_SUC	EQU	1			      ;AN000; no error from KEYB
E_KYB_LOAD_ERR	EQU	2			      ;AN000; error from KEYB
E_KYB_LOAD_US	EQU	3			      ;AN000; US keyboard loaded
E_KYB_LOAD_UND	EQU	4			      ;AN000; undefined keyboard loaded
						      ;
;	Country code association with Keyboard code & Code Page
		PUBLIC	CTY_TAB_A,CTY_TAB_A_1,CTY_A_ITEMS ;AN000;
CTY_TAB_A	DB	CTY_A_ITEMS		      ;AN000; no of entries in table
CTY_TAB_A_1	CTY_DEF < 001,E_KYBD_VAL_DEF,'  ',437,850,1,E_CPSW_NOT_REC,0> ;AN000; (01) United States
		CTY_DEF < 002,E_KYBD_VAL_YES,'CF',863,850,2,E_CPSW_VALID  ,0> ;AN000; (02) Canada (French)
		CTY_DEF < 003,E_KYBD_VAL_YES,'LA',850,437,1,E_CPSW_VALID  ,0> ;AC070;SEH ;AN000; (03) Latin America
		CTY_DEF < 031,E_KYBD_VAL_YES,'NL',437,850,1,E_CPSW_VALID  ,0> ;AN000; (04) Netherlands
		CTY_DEF < 032,E_KYBD_VAL_YES,'BE',850,437,1,E_CPSW_VALID  ,0> ;AN000; (05) Belgium
		CTY_DEF < 033,E_KYBD_VAL_YES,'FR',437,850,1,E_CPSW_VALID  ,1> ;AN000; (06) France
		CTY_DEF < 034,E_KYBD_VAL_YES,'SP',850,437,1,E_CPSW_VALID  ,0> ;AN000; (07) Spain
		CTY_DEF < 039,E_KYBD_VAL_YES,'IT',437,850,1,E_CPSW_VALID  ,2> ;AN000; (08) Italy
		CTY_DEF < 041,E_KYBD_VAL_YES,'SF',850,437,1,E_CPSW_VALID  ,0> ;AN000; (09) Switzerland
		CTY_DEF < 044,E_KYBD_VAL_YES,'UK',437,850,1,E_CPSW_VALID  ,3> ;AN000; (10) United Kingdom
		CTY_DEF < 045,E_KYBD_VAL_YES,'DK',850,865,2,E_CPSW_VALID  ,0> ;AN000; (11) Denmark
		CTY_DEF < 046,E_KYBD_VAL_YES,'SV',437,850,1,E_CPSW_VALID  ,0> ;AN000; (12) Sweden
CTY_A_ITEMS	EQU	($ - CTY_TAB_A_1) / TYPE CTY_DEF ;AN000; no of items
						      ;
		PUBLIC	CTY_TAB_B,CTY_TAB_B_1,CTY_B_ITEMS ;AN000;
CTY_TAB_B	DB	CTY_B_ITEMS		      ;AN000; no of entries in table
CTY_TAB_B_1	CTY_DEF < 047,E_KYBD_VAL_YES,'NO',850,865,2,E_CPSW_VALID  ,0 > ;AN000; (01) Norway
		CTY_DEF < 049,E_KYBD_VAL_YES,'GR',437,850,1,E_CPSW_VALID  ,0 > ;AN000; (02) Germany
		CTY_DEF < 061,E_KYBD_VAL_YES,'US',437,850,1,E_CPSW_VALID  ,0 > ;AN000; (03) Australia
		CTY_DEF < 081,E_KYBD_VAL_NO ,'  ',000,000,0,E_CPSW_NOT_VAL,0 > ;AN000; (04) Japan
		CTY_DEF < 082,E_KYBD_VAL_NO ,'  ',000,000,0,E_CPSW_NOT_VAL,0 > ;AN000; (05) Korea
		CTY_DEF < 086,E_KYBD_VAL_NO ,'  ',000,000,0,E_CPSW_NOT_VAL,0 > ;AN000; (06) Republic of China
		CTY_DEF < 088,E_KYBD_VAL_NO ,'  ',000,000,0,E_CPSW_NOT_VAL,0 > ;AN000; (07) Taiwan
		CTY_DEF < 351,E_KYBD_VAL_YES,'PO',850,860,2,E_CPSW_VALID  ,0 > ;AN000; (08) Portugal
		CTY_DEF < 358,E_KYBD_VAL_YES,'SU',850,437,1,E_CPSW_VALID  ,0 > ;AN000; (09) Finland
		CTY_DEF < 785,E_KYBD_VAL_NO ,'  ',000,000,0,E_CPSW_NOT_VAL,0 > ;AN000; (10) Arabic Speaking
		CTY_DEF < 972,E_KYBD_VAL_NO ,'  ',000,000,0,E_CPSW_NOT_VAL,0 > ;AN000; (11) Hebrew Speaking
CTY_B_ITEMS	EQU	($ - CTY_TAB_B_1) / TYPE CTY_DEF  ;AN000; no of items
						      ;
;		Keyboard Codes supported
		PUBLIC	KYBD_TAB_A,KYBD_TAB_A_1,KYBD_A_ITEMS ;AN000;
KYBD_TAB_A	DB	KYBD_A_ITEMS	;AN000; no of entries in table
KYBD_TAB_A_1	KYB_DEF < 'BE', E_KYBD_ALT_NO >       ;AN000; (01) Flemish
		KYB_DEF < 'CF', E_KYBD_ALT_NO >       ;AN000; (02) Canadian French
		KYB_DEF < 'DK', E_KYBD_ALT_NO >       ;AN000; (03) Danish
		KYB_DEF < 'FR', E_KYBD_ALT_YES>       ;AN000; (04) French
		KYB_DEF < 'GR', E_KYBD_ALT_NO >       ;AN000; (05) German
		KYB_DEF < 'IT', E_KYBD_ALT_YES>       ;AN000; (06) Italian
		KYB_DEF < 'LA', E_KYBD_ALT_NO >       ;AN000; (07) Latin American (Spanish)
		KYB_DEF < 'NL', E_KYBD_ALT_NO >       ;AN000; (08) Dutch
		KYB_DEF < 'NO', E_KYBD_ALT_NO >       ;AN000; (09) Norwegian
KYBD_A_ITEMS	EQU	($ - KYBD_TAB_A_1) / TYPE KYB_DEF ;AN000; no of items in table
						      ;
		PUBLIC	KYBD_TAB_B,KYBD_TAB_B_1,KYBD_B_ITEMS ;AN000;
KYBD_TAB_B	DB	KYBD_B_ITEMS		      ;AN000; no of entries in table
KYBD_TAB_B_1	KYB_DEF < 'PO', E_KYBD_ALT_NO >       ;AN000; (01) Portuguese
		KYB_DEF < 'SF', E_KYBD_ALT_NO >       ;AN000; (02) Swiss (French)
		KYB_DEF < 'SG', E_KYBD_ALT_NO >       ;AN000; (03) Swiss (German)
		KYB_DEF < 'SP', E_KYBD_ALT_NO >       ;AN000; (04) Spanish
		KYB_DEF < 'SU', E_KYBD_ALT_NO >       ;AN000; (05) Finnish
		KYB_DEF < 'SV', E_KYBD_ALT_NO >       ;AN000; (06) Swedish
		KYB_DEF < 'UK', E_KYBD_ALT_YES>       ;AN000; (07) UK English
		KYB_DEF < 'US', E_KYBD_ALT_NO >       ;AN000; (08) US English
		KYB_DEF < '  ', E_KYBD_ALT_NO >       ;AN000; (09) none of the above
KYBD_B_ITEMS	EQU	($ - KYBD_TAB_B_1) / TYPE KYB_DEF ;AN000; no of items in table
						      ;
		PUBLIC	ALT_TAB_PTR		      ;AN000;
ALT_TAB_PTR	DW	?			      ;AN000; pointer keyboard table
						      ;
		PUBLIC	ALT_KYB_ID, ALT_FRENCH, ALT_ITALIAN, ALT_UK, ALT_KYB_ID_PREV ;AN000;
ALT_KYB_ID	DB	?			      ;AN000; keyboard code identifier
ALT_KYB_ID_PREV DB	?			      ;AN000; previous keyboard code identifier
ALT_FRENCH	EQU	1			      ;AN000; French keyboard
ALT_ITALIAN	EQU	2			      ;AN000; Italian keyboard
ALT_UK		EQU	3			      ;AN000; UK English keyboard
						      ;
		PUBLIC	ALT_KYB_TABLE, ALT_KYB_TAB_1, ALT_KYB_ITEMS ;AN000;
ALT_KYB_TABLE	DB	ALT_KYB_ITEMS				    ;AN000; no of items in table
ALT_KYB_TAB_1	ALT_KYB_DEF  < 'FR', ALT_KYBD_FR, ALT_FRENCH  >     ;AN000; French keyboard
		ALT_KYB_DEF  < 'IT', ALT_KYBD_IT, ALT_ITALIAN >     ;AN000; Italian keyboard
		ALT_KYB_DEF  < 'UK', ALT_KYBD_UK, ALT_UK      >     ;AN000; UK English
ALT_KYB_ITEMS	EQU	($ - ALT_KYB_TAB_1) / TYPE ALT_KYB_DEF	    ;AN000; no of items
						      ;
		PUBLIC	ALT_KYBD_FR, ALT_KYBD_FR_1, ALT_FR_ITEMS ;AN000;
ALT_KYBD_FR	DB	ALT_FR_ITEMS		      ;AN000; Alternate French Keyboard-no of entries in table
ALT_KYBD_FR_1	FR_STRUC  <'120'>                     ;AN000;
		FR_STRUC  <'189'>                     ;AC000;JW
ALT_FR_ITEMS	EQU	($ - ALT_KYBD_FR_1) / TYPE FR_STRUC ;AN000;
						      ;
		PUBLIC	ALT_KYBD_IT, ALT_KYBD_IT_1, ALT_IT_ITEMS ;AN000;
ALT_KYBD_IT	DB	ALT_IT_ITEMS		      ;AN000; Alternate Italian keyboard-no of entries in table
ALT_KYBD_IT_1	IT_STRUC  <'142'>                     ;AC090;JW Switched with '141
		IT_STRUC  <'141'>                     ;AC090;JW
ALT_IT_ITEMS	EQU	($ - ALT_KYBD_IT_1) / TYPE IT_STRUC ;AN000;
						      ;
		PUBLIC	ALT_KYBD_UK, ALT_KYBD_UK_1, ALT_UK_ITEMS ;AN000;
ALT_KYBD_UK	DB	ALT_UK_ITEMS		      ;AN000; no of entries in table
ALT_KYBD_UK_1	UK_STRUC  <'168'>                     ;AN000;
		UK_STRUC  <'166'>                     ;AC000;JW
ALT_UK_ITEMS	EQU	($ - ALT_KYBD_UK_1) / TYPE UK_STRUC ;AN000;
						      ;
		PUBLIC	ALT_ID_DEF		      ;AN000;
ALT_ID_DEF	DB	0			      ;AN000;DT
						      ;
		PUBLIC	S_US			      ;AN000;
S_US		DW	M_US			      ;AN000;
P_US		DB	'US'                          ;AN000;
M_US		EQU	$ - P_US		      ;AN000;
						      ;
		PUBLIC	S_SWISS 		      ;AN000;
S_SWISS 	DW	M_SWISS 		      ;AN000;
P_SWISS 	DB	'SF'                          ;AN000;
M_SWISS 	EQU	$ - P_SWISS		      ;AN000;
						      ;
		PUBLIC	PRINTER_TABLES		      ;AN000;
PRINTER_TABLES	EQU	$			      ;AN000;
		PRINTER_DEF < > 		      ;AN000; LPT1
		PRINTER_DEF < > 		      ;AN000; LPT2
		PRINTER_DEF < > 		      ;AN000; LPT3
		PRINTER_DEF < > 		      ;AN000; COM1
		PRINTER_DEF < > 		      ;AN000; COM2
		PRINTER_DEF < > 		      ;AN000; COM3
		PRINTER_DEF < > 		      ;AN000; COM4
						      ;
		PUBLIC	N_NUMPRINT, MIN_NUMPRINT, MAX_NUMPRINT ;AN000;
N_NUMPRINT	DW	?			      ;AN000; No. of printers to install
MIN_NUMPRINT	EQU	0			      ;AN000;
MAX_NUMPRINT	EQU	7			      ;AN000;
						      ;
		PUBLIC	N_SERIAL, N_PARALLEL	      ;AN000;
N_PARALLEL	DW	?			      ;AN000;
N_SERIAL	DW	?			      ;AN000;
						      ;
		PUBLIC	I_PORT, I_REDIRECT, I_PRINTER ;AN000;
I_PORT		DW	?			      ;AN000; port number
I_REDIRECT	DW	?			      ;AN000; serial port redirection
I_PRINTER	DW	?			      ;AN000; index into printer list
						      ;
		PUBLIC	N_PRINTER_TYPE, E_SERIAL, E_PARALLEL ;AN000;
N_PRINTER_TYPE	DB	?			      ;AN000; printer type
E_SERIAL	EQU	53H			      ;AN000; Serial 'S'
E_PARALLEL	EQU	50H			      ;AN000; Parallel 'P'
						      ;
		PUBLIC	S_MODE_PARM, M_MODE_PARM      ;AN000;
S_MODE_PARM	DW	M_MODE_PARM		      ;AN000;
P_MODE_PARM	DB	40 DUP(?)		      ;AN000;
M_MODE_PARM	EQU	$ - P_MODE_PARM 	      ;AN000;
						      ;
		PUBLIC	S_CP_DRIVER, M_CP_DRIVER      ;AN000;
S_CP_DRIVER	DW	M_CP_DRIVER		      ;AN000;
P_CP_DRIVER	DB	22 DUP(?)		      ;AN000;
M_CP_DRIVER	EQU	$ - P_CP_DRIVER 	      ;AN000;
						      ;
		PUBLIC	S_CP_PREPARE, M_CP_PREPARE    ;AN000;
S_CP_PREPARE	DW	M_CP_PREPARE		      ;AN000;
P_CP_PREPARE	DB	12 DUP(?)		      ;AN000;
M_CP_PREPARE	EQU	$ - P_CP_PREPARE	      ;AN000;
						      ;
		PUBLIC	S_GRAPH_PARM, M_GRAPH_PARM    ;AN000;
S_GRAPH_PARM	DW	M_GRAPH_PARM		      ;AN000;
P_GRAPH_PARM	DB	20 DUP(?)		      ;AN000;
M_GRAPH_PARM	EQU	$ - P_GRAPH_PARM	      ;AN000;
						      ;
		PUBLIC	F_REVIEW, E_REVIEW_ACCEPT, E_REVIEW_VIEW ;AN000;
F_REVIEW	DW	?			      ;AN000; Review selection screen index
E_REVIEW_ACCEPT EQU	1			      ;AN000; user will accept selections made by SELECT
E_REVIEW_VIEW	EQU	2			      ;AN000; user wants to view/change selections made by SELECT
						      ;
		PUBLIC	N_DISPLAY, E_CPSW_DISP, E_NOCPSW_DISP ;AN000;
N_DISPLAY	DB	?			      ;AN000; display type indicator
E_CPSW_DISP	EQU	0			      ;AN000; display type will support CPSW
E_NOCPSW_DISP	EQU	1			      ;AN000; display type will not support CPSW
						      ;
		PUBLIC	N_YEAR, MIN_YEAR, MAX_YEAR    ;AN000;
N_YEAR		DW	?			      ;AN000; calender year
MIN_YEAR	EQU	1980			      ;AN000;
MAX_YEAR	EQU	2079			      ;AN000;
						      ;
		PUBLIC	N_MONTH, MIN_MONTH, MAX_MONTH ;AN000;
N_MONTH 	DW	?			      ;AN000; calender month
MIN_MONTH	EQU	1			      ;AN000;
MAX_MONTH	EQU	12			      ;AN000;
						      ;
		PUBLIC	N_DAY, MIN_DAY, MAX_DAY       ;AN000;
N_DAY		DW	?			      ;AN000; calender day
MIN_DAY 	EQU	1			      ;AN000;
MAX_DAY 	EQU	31			      ;AN000;
						      ;
		PUBLIC	N_HOUR, MIN_HOUR, MAX_HOUR    ;AN000;
N_HOUR		DW	?			      ;AN000; hour
MIN_HOUR	EQU	0			      ;AN000;
MAX_HOUR	EQU	23			      ;AN000;
						      ;
		PUBLIC	N_MINUTE, MIN_MINUTE, MAX_MINUTE ;AN000;
N_MINUTE	DW	?			      ;AN000; minute
MIN_MINUTE	EQU	0			      ;AN000;
MAX_MINUTE	EQU	59			      ;AN000;
						      ;
		PUBLIC	N_SECOND, MIN_SECOND, MAX_SECOND ;AN000;
N_SECOND	DW	?			      ;AN000; second
MIN_SECOND	EQU	0			      ;AN000;
MAX_SECOND	EQU	59			      ;AN000;
						      ;
		PUBLIC	PARM_BLOCK, CMD_BUFF	      ;AN000;
PARM_BLOCK	LABEL	WORD			      ;AN000; parameter block for EXEC_PROGRAM
		DW	0			      ;AN000; use parent environment
		DW	OFFSET CMD_BUFF 	      ;AN000; pointer to commnad line
		DW	?			      ;AN000; segment for command line
		DW	5CH			      ;AN000; default FCB
		DW	?			      ;AN000; segment for FCB
		DW	6CH			      ;AN000; default FCB
		DW	?			      ;AN000; segment for FCB
PARM_BLOCK_END	EQU	$			      ;AN000;
						      ;
CMD_BUFF	LABEL	BYTE			      ;AN000; command line passed to EXEC_PROGRAM
		DB	?			      ;AN000; length of command line - excluding carrier return
		DB	80 DUP(?)		      ;AN000;
CMD_BUFF_END	EQU	$			      ;AN000;
						      ;
		PUBLIC	S_STR40, P_STR40, M_STR40     ;AN000;JW
S_STR40 	DW	M_STR40 		      ;AN000; Temporary variable for string field
P_STR40 	DB	40 DUP(?)		      ;AN000;JW
M_STR40 	EQU	$ - P_STR40		      ;AN000;JW
						      ;
		PUBLIC	S_STR120_1, P_STR120_1, M_STR120_1 ;AN000;
S_STR120_1	DW	M_STR120_1		      ;AN000; Temporary variable for string field
P_STR120_1	DB	120 DUP(?)		      ;AN000;
M_STR120_1	EQU	$ - P_STR120_1		      ;AN000;
						      ;
		PUBLIC	S_STR120_2, M_STR120_2	      ;AN000;
S_STR120_2	DW	M_STR120_2		      ;AN000; Temporary variable for string field
P_STR120_2	DB	120 DUP(?)		      ;AN000;
M_STR120_2	EQU	$ - P_STR120_2		      ;AN000;
						      ;
		PUBLIC	S_STR120_3, M_STR120_3	      ;AN000;
S_STR120_3	DW	M_STR120_3		      ;AN000; Temporary variable for string field
P_STR120_3	DB	120 DUP(?)		      ;AN000;
M_STR120_3	EQU	$ - P_STR120_3		      ;AN000;
						      ;
		PUBLIC	S_STR120_4, M_STR120_4	      ;AN039;SEH
S_STR120_4	DW	M_STR120_4		      ;AN039;SEH  Temporary variable for string field
P_STR120_4	DB	120 DUP(?)		      ;AN039;SEH
M_STR120_4	EQU	$ - P_STR120_4		      ;AN039;SEH
						      ;
		PUBLIC	SC_LINE, MC_LINE	      ;AN000;
SC_LINE 	DW	MC_LINE 		      ;AN000; Temporary variable for string field
PC_LINE 	DB	130 DUP(?)		      ;AN000;
MC_LINE 	EQU	$ - PC_LINE - 2 	      ;AN000;
						      ;
		PUBLIC	N_HANDLE		      ;AN000;
N_HANDLE	DW	?			      ;AN000; save location for file handle
						      ;
		PUBLIC	N_WRITE_HANDLE, N_WRITE_ERR_CODE ;AN000;
N_WRITE_HANDLE	DW	?			      ;AN000; File handle for prepared file
N_WRITE_ERR_CODE DW	?			      ;AN000; error code for prepared file
						      ;
		PUBLIC	N_RETCODE, N_COUNTER	      ;AN000;
N_RETCODE	DW	?			      ;AN000; Return code if execution not a success
N_COUNTER	DW	?			      ;AN000; Loop counter
						      ;
		PUBLIC	N_WORD_1, N_WORD_2, N_WORD_3, N_WORD_4, N_WORD_5, N_WORD_6,N_BYTE_1 ;AN000;
N_WORD_1	DW	?			      ;AN000; temp variable
N_WORD_2	DW	?			      ;AN000; temp variable
N_WORD_3	DW	?			      ;AN000; temp variable
N_WORD_4	DW	?			      ;AN000; temp variable
N_WORD_5	DW	?			      ;AN000; temp variable
N_WORD_6	DW	?			      ;AN000; temp variable
N_BYTE_1	DB	?			      ;AN025; temp variable
						      ;
		PUBLIC	SAVE_AREA		      ;AN000;
SAVE_AREA	DB	4 DUP(?)		      ;AN000; save area for stack pointer before EXEC program
						      ;
		PUBLIC	N_HOUSE_CLEAN,E_CLEAN_YES,E_CLEAN_NO ;AN000;
N_HOUSE_CLEAN	DB	?			      ;AN000;
E_CLEAN_YES	EQU	1			      ;AN000; erase temp files
E_CLEAN_NO	EQU	0			      ;AN000; no temp files to erase
						      ;
		PUBLIC	N_DSKCPY_ERR,E_DSKCPY_RETRY,E_DSKCPY_OK  ;AN000;JW
N_DSKCPY_ERR	DB	0			      ;AN000;JW
E_DSKCPY_RETRY	EQU	1			      ;AN000; retry diskcopy
E_DSKCPY_OK	EQU	0			      ;AN000; diskcopy successful
						      ;
		PUBLIC	E_CR, E_LF		      ;AN000;
E_CR		EQU	0DH			      ;AN000;
E_LF		EQU	0AH			      ;AN000;
						      ;
;		EQUATES FOR FIELD TYPES DEFINED IN DISK STATUS STRUCTURE
;		EQUATES FOR N_PART_NAME ; Partition name
		PUBLIC	E_PART_PRI_DOS, E_PART_EXT_DOS, E_PART_LOG_DRI ;AN000;
		PUBLIC	E_FREE_MEM_EDOS, E_FREE_MEM_DISK, E_PART_OTHER ;AN000;
E_PART_PRI_DOS	EQU	1			      ;AN000; Primary DOS partition
E_PART_EXT_DOS	EQU	2			      ;AN000; Extended DOS partition
E_PART_LOG_DRI	EQU	3			      ;AN000; Logical Drive
E_FREE_MEM_EDOS EQU	4			      ;AN000; Free space in Extended DOS partition
E_FREE_MEM_DISK EQU	5			      ;AN000; Free disk space - undefined partition
E_PART_OTHER	EQU	6			      ;AN000; other partition types i.e not DOS or EDOS

;		EQUATES FOR N_PART_STATUS ; Partition status
		PUBLIC	E_PART_UNFORMAT, E_PART_FORMAT ;AN000;
E_PART_UNFORMAT EQU	0			      ;AN000; partition is unformatted
E_PART_FORMAT	EQU	1			      ;AN000; partition is formatted
						      ;
;		EQUATES FOR N_PART_TYPE ; Partition type
		PUBLIC	E_PART_FAT, E_PART_KSAM, E_PART_UNDEF, E_PART_IGNORE ;AN000;
E_PART_FAT	EQU	1			      ;AN000; FAT
E_PART_KSAM	EQU	2			      ;AN000; KSAM
E_PART_UNDEF	EQU	3			      ;AN000; not assigned
E_PART_IGNORE	EQU	4			      ;AN000; other partition types i.e not FAT or KSAM
						      ;
		PUBLIC	N_DISK_1, E_DISK_1, N_DISK_2, E_DISK_2 ;AN000;
		PUBLIC	E_DISK_INV, E_DISK_NO_PART, E_DISK_VAL_PART ;AN000;
N_DISK_1	DW	?			      ;AN000; first fixed disk status
N_DISK_2	DW	?			      ;AN000; second fixed disk status
E_DISK_1	EQU	1			      ;AN000;
E_DISK_2	EQU	2			      ;AN000;
E_DISK_INV	EQU	0			      ;AN000; fixed disk not present
E_DISK_NO_PART	EQU	1			      ;AN000; fixed disk present : no DOS or EDOS partitions
E_DISK_VAL_PART EQU	2			      ;AN000; fixed disk present : DOS or EDOS partitions exist
						      ;
		PUBLIC	N_DISK_1_S1,N_DISK_2_S1,E_DISK_PRI,E_DISK_EXT_DOS ;AN000;
		PUBLIC	E_DISK_LOG_DRI,E_DISK_EDOS_MEM,E_DISK_FREE_MEM ;AN000;
N_DISK_1_S1	DW	?			      ;AN000; detailed status of first fixed drive
N_DISK_2_S1	DW	?			      ;AN000; detailed status or second fixed drive
E_DISK_PRI	EQU	01H			      ;AN000; Primary DOS partition exists
E_DISK_EXT_DOS	EQU	02H			      ;AN000; Extended DOS partitions exists
E_DISK_LOG_DRI	EQU	04H			      ;AN000; Logical drives exist in Extended Dos partitions
E_DISK_EDOS_MEM EQU	08H			      ;AN000; Free space exists in Extended DOS partition
E_DISK_FREE_MEM EQU	10H			      ;AN000; Free disk space exists
						      ;
		PUBLIC	N_DISK_1_S2, N_DISK_2_S2,E_SPACE_NONE,E_SPACE_EDOS,E_SPACE_DISK ;AN000;
N_DISK_1_S2	DW	0			      ;AN000;
N_DISK_2_S2	DW	0			      ;AN000;
E_SPACE_NONE	EQU	0			      ;AN000; no free space in EDOS and DISK
E_SPACE_EDOS	EQU	1			      ;AN000; free space in EDOS
E_SPACE_DISK	EQU	2			      ;AN000; no EDOS but free space in disk
						      ;
		PUBLIC	F_PARTITION, E_PART_DEFAULT, E_PART_USER ;AN000;
F_PARTITION	DW	1			      ;AN000; partition size division option
E_PART_DEFAULT	EQU	1			      ;AN000; default partition sizes are to be used
E_PART_USER	EQU	2			      ;AN000; user will define partition sizes
						      ;
		PUBLIC	I_DESTINATION, E_ENTIRE_DISK, E_PATH_ONLY ;AN000;JW
I_DESTINATION	DW	1			      ;AN000; destination on c: disk option	   JW
E_ENTIRE_DISK	EQU	1			      ;AN000; replace files across entire disk	   JW
E_PATH_ONLY	EQU	2			      ;AN000; replace files in dos path only	   JW
						      ;
		PUBLIC	F_FORMAT, E_FORMAT_FAT, E_FORMAT_NO ;AN000;
F_FORMAT	DW	?			      ;AN000;
E_FORMAT_FAT	EQU	1			      ;AN000; format partition with FAT
E_FORMAT_NO	EQU	2			      ;AN000; do not format partition
						      ;
		PUBLIC	N_DISK1_MODE, E_DISK1_INSTALL, E_DISK1_REPLACE ;AN000;
N_DISK1_MODE	DW	?			      ;AN000; install mode for fixed disk
E_DISK1_INSTALL EQU	1			      ;AN000; install DOS-no partitions
E_DISK1_REPLACE EQU	2			      ;AN000; replace DOS-partitions exist
						      ;
		PUBLIC	DISK_1_TABLE,DISK_1_VAL_ITEM,DISK_1_START,M_DISK_1_ITEMS ;AN000;
DISK_1_TABLE	DB	M_DISK_1_ITEMS		      ;AN000; maximum no of items in table
DISK_1_VAL_ITEM DB	0			      ;AN000; number of valid entries in table
DISK_1_START	DB	(100*TYPE DISK_STATUS) DUP (0) ;AN000;
M_DISK_1_ITEMS	EQU	($ - DISK_1_START) / TYPE DISK_STATUS ;AN000;
						      ;
		PUBLIC	DISK_2_TABLE,DISK_2_VAL_ITEM,DISK_2_START,M_DISK_2_ITEMS ;AN000;
DISK_2_TABLE	DB	M_DISK_2_ITEMS		      ;AN000; maximum no of items in table
DISK_2_VAL_ITEM DB	0			      ;AN000; number of valid entries in table
DISK_2_START	DB	(100*TYPE DISK_STATUS) DUP (0) ;AN000;
M_DISK_2_ITEMS	EQU	($ - DISK_2_START) / TYPE DISK_STATUS ;AN000;
						      ;
		PUBLIC	N_NAME_PART,N_SIZE_PART,N_STATUS_PART,P_DRIVE_PART,N_TYPE_PART,N_LEVEL1_PART,N_LEVEL2_PART,N_LEVEL3_PART,N_LEVEL4_PART ;AC065;SEH add check for version number ;AN000;
N_NAME_PART	DB	0			      ;AN000; partition name
N_SIZE_PART	DW	0			      ;AN000; partition size
N_STATUS_PART	DB	0			      ;AN000; partition status
N_TYPE_PART	DB	0			      ;AN000; partition type
P_DRIVE_PART	DB	' '                           ;AN000; drive letter assigned
N_LEVEL1_PART	DB	0			      ;AN065; SEH version number (1st part) for DOS 4.00 1st part = blank
N_LEVEL2_PART	DB	0			      ;AN065; SEH version number (2nd part) for DOS 4.00 2nd part = 4
N_LEVEL3_PART	DB	0			      ;AN065; SEH version number (3rd part) for DOS 4.00 3rd part = .
N_LEVEL4_PART	DB	0			      ;AN065; SEH version number (4th part) for DOS 4.00 4th part = 0
						      ;
		PUBLIC	N_DISK_NUM,E_DISK_ROW,E_DISK_COL,E_DRIVE_ROW,E_DRIVE_COL ;AN000;
N_DISK_NUM	DB	?			      ;AN000; holder for ascii disk number
E_DISK_ROW	EQU	0			      ;AN000; row for fixed disk number   (0 based)
E_DISK_COL	EQU	19			      ;AN000; column for fixed disk number
E_DRIVE_ROW	EQU	0			      ;AN000; row for logical drive letter    (0 based)
E_DRIVE_COL	EQU	19			      ;AN000; column for logical drive letter
						      ;
		PUBLIC	STACK_INDEX, SELECT_STACK, STACK_SIZE ;AN000;
STACK_INDEX	DB	00H			      ;AN000; no. of entries in stack
SELECT_STACK	DW	50  DUP(?)		      ;AN000; stack entries
STACK_SIZE	EQU	$ - SELECT_STACK	      ;AN000; size of SELECT stack
						      ;
		PUBLIC	N_DEST,E_DEST_DOS,E_DEST_SHELL ;AN000;
N_DEST		DB	?			      ;AN000;
E_DEST_DOS	EQU	1			      ;AN000;
E_DEST_SHELL	EQU	2			      ;AN000;
						      ;
; Variables which return information if a critical error occurs.
; INT_24_ERROR returns the error code from the critical error routine
; INT_24_FLAG is set if a critical error occurs.  It is not enough
; to check if INT_24_ERROR is non-zero, since a value of zero is a critical error.
PUBLIC	INT_24_ERROR, INT_24_FLAG		      ;AN000;
INT_24_ERROR	   DW	     0			      ;AN000;
INT_24_FLAG	   DB	     0			      ;AN000;
						      ;
; Area to save the old interrupt 23h vector for restoration when the program is done.
PUBLIC	OLD_INT_23				      ;AN074;SEH ctrl-break
OLD_INT_23	   DD	     0			      ;AN074;SEH
; Area to save the old interrupt 24h vector for restoration when the program is done.
PUBLIC	OLD_INT_24				      ;AN000;
OLD_INT_24	   DD	     0			      ;AN000;
; Area to save the old interrupt 2Fh vector for restoration when the program is done.
PUBLIC	OLD_INT_2F				      ;AN000;
OLD_INT_2F	   DD	     0			      ;AN000;
						      ;
PUBLIC MEM_SIZE 				      ;AN000;
MEM_SIZE	   DW	     0			      ;AN000;DT installed memory in machine
						      ;
	PUBLIC FORMAT_WHICH, STARTUP, SHELL	      ;AN000;
FORMAT_WHICH	DB	?			      ;AN111; indicator for which disk (720) to format JW
STARTUP 	EQU	0			      ;AN111; format startup
SHELL		EQU	1			      ;AN111; format shell
						      ;
	PUBLIC DISK_PANEL, SEARCH_FILE		      ;AN000;JW
DISK_PANEL	DW	?			      ;AN000;JW Holds panel number for INSERT_DISK
SEARCH_FILE	DW	?			      ;AN000;JW Holds offset of file to search for

	PUBLIC	SUB_ERROR			      ;AN000;JW Holds error code of sub process
SUB_ERROR	DB	?			      ;AN000;JW

include msgdcl.inc
						      ;
DATA	ENDS					      ;AN000;
	END					      ;AN000;
