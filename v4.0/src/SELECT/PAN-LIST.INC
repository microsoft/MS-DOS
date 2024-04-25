;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	PAN-LIST.INC
;
;
;
;	OASIS PANEL ASSOCATION TABLE
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PAN_WELCOME	EQU	 1	;AN000; Welcome screen
PAN_INTRO	EQU	 2	;AN000; Introduction screen
PAN_CONFIRM	EQU	 3	;AN000; Confirmation screen
PAN_WORKSPACE	EQU	 4	;AN000; User memory needs screen
PAN_CTY_KYB	EQU	 5	;AN000; Country/Keyboard support screen
PAN_COUNTRY	EQU	 6	;AN000; Country Code Choice screen
PAN_KEYBOARD	EQU	 7	;AN000; Keyboard Code Choice screen
PAN_KYBD_ALT	EQU	 8	;AN000; Alternate keyboard screen
PAN_DEST_DRIVE	EQU	 9	;AN000; Destination Drive screen
PAN_DOS_LOC	EQU	10	;AN000; DOS Location screen
PAN_PRINTER	EQU	11	;AN000; Printer Selection Screen
PAN_PRT_TYPE	EQU	12	;AN000; Printer type screen
PAN_PARALLEL	EQU	13	;AN000; Parallel printer port selection screen
PAN_SERIAL	EQU	14	;AN000; Serial printer port selection screen
PAN_REVIEW	EQU	15	;AN000; Review Selections Screen
PAN_FUNC_DISK	EQU	16	;AN000; Review selections made by SELECT - drive C:
PAN_FUNC_DISKET EQU	16	;AN000; Review selections made by SELECT - drive B:
ERR_PRT_NO_HDWR EQU	17	;AN000;
PAN_DOS_PARAM	EQU	18	;AN000; PC/DOS parameters screen
PAN_SHELL	EQU	19	;AN000; SHELL parameters screen
ERR_EXIT	EQU	20	;AN000; Unrecoverable error - exit
PAN_FASTOPEN	EQU	21	;AN000; FASTOPEN support screen
PAN_SHARE	EQU	22	;AN000; SHARE support screen
PAN_GRAPHICS	EQU	23	;AN000; GRAPHICS support screen
PAN_EXP_MEMORY	EQU	24	;AN000; Expanded Memory support screen
PAN_VDISK	EQU	25	;AN000; Virtual Disk support screen
PAN_CONFIG_PARS EQU	26	;AN000; CONFIG.SYS parameter screen
PAN_FIXED_FIRST EQU	27	;AN000; Partitions support for first disk only
PAN_FIXED_BOTH	EQU	28	;AN000; Partitions support for both disks
PAN_REBOOT	EQU	29	;AN000; Reboot screen
PAN_DATE_TIME	EQU	30	;AN000; Install Date/Time support screen
PAN_FORMAT	EQU	31	;AN000; Format Fixed Disk partition screen
PAN_INST_PROMPT EQU	32	;AN000; Installing PC DOS prompt screen
PAN_INSTALL_DOS EQU	32	;AN000; Installing PC DOS screen
ERR_KEYB	EQU	33	;AN000; Error in running the KEYB command
PAN_COMPLETE1	EQU	34	;AN000; Installing complete screen - disk
PAN_COMPLETE2	EQU	34	;AN000; Installing complete screen - diskette 720KB
PAN_COMPLETE3	EQU	34	;AN000; Installing complete screen - diskette 360KB
SUB_COMP_KYS_1C EQU	35	;AN000; message for reboot; diskette COMBINED (1.44MB)
PAN_HPAN	EQU	36	;AN000; contextual help panel
PAN_HBAR	EQU	37	;AN000; HORIZONTAL BAR
SUB_CONT_OPTION EQU	38	;AN000; Enter to continue or Esc to cancel
SUB_PRINTER_1	EQU	39	;AN000; printer no 1

CHILD_F3EXIT	EQU	40	;AN000; f3 exit child panel
SUB_FIXED_1	EQU	41	;AN000; fixed disk 1
SUB_LOG_DRIVE	EQU	42	;AN000; logical drive JW
SUB_REBOOT_KEYS EQU	43	;AN000; ctrl+alt+del to reboot line
SUB_INSTALL_1	EQU	44	;AN000; copying from diskette 1
SUB_INSTALL_2	EQU	45	;AN000; copying from diskette 2
SUB_COMP_VER	EQU	46	;AN000; install of DOS 4.00 complete
SUB_COMP_KYS_1	EQU	47	;AN000; message before reboot - disk
SUB_COMP_KYS_2	EQU	48	;AN000; message before reboot - diskette
				;
CHILD_F1HELP	EQU	49	;AN000; help child panel
CHILD_F9KEYS	EQU	50	;AN000; keys child panel
CHILD_QUIT	EQU	51	;AN000; escape child panel
CHILD_ENTER	EQU	52	;AN000; enter child panel
SUB_COMP_REP	EQU	53	;AN000; Replacement of DOS 4.00 complete
				;
PAN_WRITE_PROT	EQU	54	;AN000;
PAN_DRIVE_ERROR EQU	55	;AN000;
PAN_BAD_DISKET	EQU	56	;AN000;
ERR_COPY_DISK	EQU	57	;AN000;
				;
SUB_INS_START_B EQU	58	;AN000;
SUB_REM_SEL_A	EQU	59	;AN000;
SUB_REM_START_B EQU	60	;AN000;
SUB_REM_DOS_A	EQU	61	;AN000;
				;
ERR_BAD_PATH	EQU	62	;AN000;
ERR_BAD_PFILE	EQU	63	;AN000;
ERR_BAD_PPRO	EQU	64	;AN000;
FORMAT_DISK	EQU	65	;AN000;
FORMAT_DISKET	EQU	66	;AN000;
ERR_BORDER	EQU	67	;AN000;
ERR_DOS_DISK	EQU	68	;AN000;
ERR_GENERAL	EQU	69	;AN000;
PAN_DISKCOPY	EQU	70	;AN000;
PAN_DSKCPY_SRC	EQU	71	;AN000;
PAN_DSKCPY_TAR	EQU	72	;AN000;
PAN_DSKCPY_CPY	EQU	73	;AN000;
PAN_PARTIAL	EQU	74	;AC010;

FORMAT_SHELL	EQU	75	;AN000;DT One drive format of SHELL diskette
FORMAT_STARTUP	EQU	76	;AN000;DT One drive format of STARTUP diskette
SUB_REM_SHELL_360 EQU	77	;AN001;GHG D65 360KB
SUB_REM_SELECT_360 EQU	78	;AN001;GHG D65 360KB
SUB_REM_UTIL1_360 EQU	79	;AN001;GHG D65 360KB
SUB_COPYING	EQU	80	;AN001;GHG D65 360KB

SUB_INS_WORK1_360 EQU	81	;AN000;DT 2 drive 360 installation
SUB_INS_WORK2_360 EQU	82	;AN000;DT	  "
SUB_INS_WORK3_360 EQU	83	;AN000;DT	  "
SUB_INS_START_360 EQU	84	;AN000;DT	  "
SUB_INS_INSTALL_360 EQU 85	;AN000;DT	  "
				;
SUB_INS_WORK1_S360   EQU 86	;AN000;DT 1 drive 360 installation
SUB_INS_WORK2_S360   EQU 87	;AN000;DT	  "
SUB_INS_SHELL_S360   EQU 88	;AN000;DT	  "
SUB_INS_STARTT_S360  EQU 89	;AN000;DT	  "

PAN_START360	     EQU 90	;AN000;DT	  "
SUB_COMP_KYS_3	     EQU 91	;AN000;DT message before reboot - diskette

SUB_INSTALL_COPY     EQU 92	;AN000;DT insert INSTALL copy
SUB_INS_OPER2	     EQU 93	;AN000;DT
PAN_EXP_MEMORY2      EQU 94	;AN000;JW Expanded Memory support screen
PAN_START720	     EQU 95	;AN000;DT Diskette introduction 720KB
PAN_START1440	     EQU 96	;AN000;DT Diskette introduction 1440KB
ERR_INS_INSTALL      EQU 97	;AN060;JW Insert the install diskette
PAN_CHOOSE_SHELL     EQU 98	; MS-DOS Shell option
SUB_INS_WORKING_A    EQU 99	; Insert the WORKING disk in drive A
SUB_INS_MSSHELL_A    EQU 100	; Insert the MS-SHELL disk in drive A
SUB_INS_SHELL_DISKS  EQU 101	; Ins. MS-SHELL in A; SHELL in B
SUB_INS_OP_WORK      EQU 102	; Ins. OPERATING in A; WORKING in B
SUB_INS_WORK3_A	     EQU 103	; Ins. WORKING3 in drive A

SCR_DOS_SUPPORT EQU	 1	;AN000; memory workspace list
SCR_CTY_KYB	EQU	 2	;AN000; type of country/keyboard list
SCR_CTY_1	EQU	 3	;AN000; list of countries - code 001 to 046
SCR_CTY_2	EQU	 4	;AN000; list of countries - code 047 to 972
SCR_KYB_1	EQU	 5	;AN000; list of keyboards - code BE to NO
SCR_KYB_2	EQU	 6	;AN000; list of keyboards - code PO to none
SCR_FR_KYB	EQU	 7	;AN000; list of alternate French keyboards
SCR_IT_KYB	EQU	 8	;AN000; list of alternate Italian keyboards
SCR_UK_KYB	EQU	 9	;AN000; list of alternate UK keyboards
SCR_DEST_B_C	EQU	10	;AN111; install drive list JW
SCR_PRT_TYPE	EQU	11	;AN000; list of printers supported
SCR_PARALLEL	EQU	12	;AN000; list of parallel printer ports
SCR_SERIAL	EQU	13	;AN000; list of serial printer ports
SCR_PRT_REDIR	EQU	14	;AN000; list of redirected parallel printer ports
SCR_REVIEW	EQU	15	;AN000; accept/view SELECT generated options
SCR_FUNC_DISK	EQU	16	;AN000; list of functions supported - disk
SCR_FUNC_DISKET EQU	17	;AN000; list of functions supported - diskette
SCR_FIXED_FIRST EQU	18	;AN000; first fixed disk unused - partition support list
SCR_FIXED_BOTH	EQU	19	;AN000; first fixed disk used - partition support list
SCR_FORMAT	EQU	20	;AN000; fixed disk partition format
SCR_CONTEXT_HLP EQU	21	;AN000;
SCR_INDEX_HLP	EQU	21	;AN000;
SCR_TITLE_HLP	EQU	22	;AN000;
SCR_ACC_CTY	EQU	23	;AN000;
SCR_ACC_KYB	EQU	24	;AN000;
SCR_ACC_PRT	EQU	25	;AN000;
SCR_COPY_DEST	EQU	26	;AN000;JW DOS location choices
SCR_DEST_A_C	EQU	27	;AN111; install drive list JW
SCR_CHOOSE_SHELL EQU	28	; MS-DOS Shell option
				;
STR_DOS_LOC	EQU	 1	;AN000; DOS location field
STR_EXT_PARMS	EQU	 2	;AN000; external diskette parameters
STR_DOS_PATH	EQU	 3	;AN000; DOS path
STR_DOS_APPEND	EQU	 4	;AN000; APPEND path
STR_DOS_PROMPT	EQU	 5	;AN000; PROMPT path
STR_SHELL	EQU	 6	;AN000; SHELL parameters
STR_KSAM	EQU	 7	;AN000; KSAM parameters
STR_FASTOPEN	EQU	 8	;AN000; FASTOPEN parameters
STR_SHARE	EQU	 9	;AN000; SHARE parameters
STR_GRAPHICS	EQU	10	;AN000; GRAPHICS parameters
STR_XMAEM	EQU	11	;AN000; XMAEM expanded memory parameter
STR_XMA2EMS	EQU	12	;AN000; XMA2EMS expanded memory parameter
STR_VDISK	EQU	13	;AN000; VDISK parameter
STR_BREAK	EQU	14	;AN000; BREAK parameter
STR_BUFFERS	EQU	15	;AN000; BUFFERS parameter
STR_DOS_APPEND_P EQU	 16	;AN000; APPEND parameter   JW
STR_FCBS	EQU	17	;AN000; FCBS parameter
STR_FILES	EQU	18	;AN000; FILES parameter
STR_LASTDRIVE	EQU	19	;AN000; LASTDRIVE parameter
STR_STACKS	EQU	20	;AN000; STACKS parameter
STR_VERIFY	EQU	21	;AN000; VERIFY parameter

NUM_PRINTER	EQU	22	;AN000; no of printers
NUM_EXT_DISK	EQU	23	;AN000; no of external diskettes
NUM_YEAR	EQU	24	;AN000; YEAR
NUM_MONTH	EQU	25	;AN000; MONTH
NUM_DAY 	EQU	26	;AN000; DAY
NUM_HOUR	EQU	27	;AN000; HOUR
NUM_MINUTE	EQU	28	;AN000; MINUTE
NUM_SECOND	EQU	29	;AN000; SECOND
STR_DEF_CP	EQU	30	;AN000; Default CodePage for the SELECT.DAT file
STR_SWISS_KEYB	EQU	31	;AN000; Default SWISS Keyboard
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
