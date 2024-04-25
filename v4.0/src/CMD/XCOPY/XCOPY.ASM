	PAGE,	132			;
TITLE	XCOPY	WITH FULL MEMORY USE - Ver. 4.00

;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: XCOPY
;
; DESCRIPTIVE NAME: selectively copy groups of files, which can include
;		    lower level subdirectories.
;
; FUNCTION:  The modules of XCOPY will be placed in the following order -
;	     SSEG, DSEG(MAIN DATA, MAIN MSG), CSEG (MAIN + INIT),
;	     DSEG_INIT(INIT DATA, INIT MSG)
;
;	     HEADER - informations needed about the file, subdirectory ...
;		      Continue_Info -> 0 - a whole single file in this header
;		      segment, or dir.
;		      1 - Continuation of a small file.
;		      2 - Continuation of a Big file
;		      3 - Eof of continuation
;	     Next_Ptr	   -> points to the next header segment
;	     Before_Ptr    -> points to the old header segment
;
;	     By optionally using the Archive bit in the directory of each
;	     file, XCOPY can be used as an alternative method of creating
;	     backup files which can be accessed directly by DOS and its
;	     applications without the need to "restore" the backup files.
;
;	     XCOPY is especially useful when several files are being copied
;	     and there is a generous amount of RAM available, because XCOPY
;	     will fill the memory with all the source files it can read in
;	     before starting to create output files.  If the memory is not
;	     enough to hold all the source, this cycle will be repeated until
;	     the process is completed.	For single drive systems, this maximum
;	     usage of the memory greatly reduces the amount of diskette
;	     swapping that would be required by the usual COPY command.
;
; ENTRY POINT: MAIN
;
; INPUT: (DOS COMMAND LINE PARAMETERS)
;
;	      SOURCE OPERAND:			   TARGET OPERAND:
;
;	      [d:] [path] filename[.ext]	   [d:] [path] [filename[.ext]]
;		or
;	      [d:] path [filename[.ext]]
;		or
;	      d: [path] [filename[.ext]]
;
;
;	      SWITCHES:
;
;	      /A /D /E /M /P /S /V /W
;
;The /A switch will copy only those files whose archive bit of the attribute is
;set to one.  The attribute of the source file is not changed.	This option is
;useful when making multiple backups when doing the non-final backup.
;The archive bit is one when a file has be created or Revised since the last
;time the bit was turned off.  XCOPY /M or BACKUP /M will turn this bit off.
;The ATTRIB command can also be used to change the setting of the archive bit.
;
;The /D switch will copy only those files whose date is the same or later than
;the date specified.  Depending on the country code you selected using the
;COUNTRY command, the date is specified in the format corresponding to the
;indicated country.
;
;The /E switch will create subdirectories on the target even if they end up
;being empty after all copying is over.  If /E is not specified, empty
;subdirectories are not created.
;
;The /M switch will copy only those files whose archive bit is set in its
;attribute.  Unlike the /A switch, /M will cause the archive bit in the source
;file to be turned off.  This allows XCOPY to be used in making a final backup.
;The archive bit is one when a file has be created or Revised since the last
;time the bit was turned off.  XCOPY /M or BACKUP /M will turn this bit off.
;The ATTRIB command can also be used to change the setting of the archive bit.
;
;The /P switch will prompt the operator before copying each file.  In this
;situation, each file is copied onto the target before reading in the next
;file. The multi-file copy into a large memory buffer is not done.  The prompt
;displays the complete filespec it proposes to copy and asks for (Y/N)
;response, which is then read in from the standard input device.
;
;The /S switch will not only copy the files in the current source directory but
;also those in all the subdirectories below the current one, with XCOPY
;following the Tree of the subdirectories to access these files.  /S does not
;create an empty subdirectory on the target (unless /E is also specified).
;If the /S switch is not specified, XCOPY works only within the specified (or
;current) subdirectory of the source.
;
;The /V switch will cause DOS to verify that the sectors written on the target
;are recorded properly.  This option has been provided so you can verify that
;critical data has been correctly recorded.  This option will cause XCOPY to
;run more slowly, due to the additional overhead of verification.
;
;The /W switch will instruct XCOPY to pause before actually starting the
;movement of data, thus permit the copying of diskettes that do not actually
;have XCOPY available on them.	The diskette containing XCOPY can be mounted
;first, the XCOPY command given with the /W option, then when the prompt
;requesting permission to continue is given, that diskette can then be removed
;and the source diskette mounted in its place, then the operator can press any
;key to continue after the pause.  This feature is especially useful in a
;non-hardfile system.
;
; EXIT-NORMAL:	ERRORLEVEL_0 - This is the normal completion code.
;		ERRORLEVEL_2 - This is due to termination via Control-Break.
;		ERRORLEVEL_4 - This is used to indicate an error condition.
;
;    There are many types of problems that are detected and result in this
;    return code, such as:
;
;    write failure due to hard disk error
;    disk full
;    conflict between name of new subdirectory and existing filename
;    access denied
;    too many open files
;    sharing violation
;    lock violation
;    general failure
;    file not found
;    path not found
;    directory full
;    invalid parms
;    reserved file name as source
;    insufficient memory
;    incorrect DOS version
;
;
; INTERNAL REFERENCES:
;
;    ROUTINES:
;
;
;    DATA AREAS:
;
;
; EXTERNAL REFERENCES:
;
;    ROUTINES:
;
;
;    DATA AREAS:
;
;
; NOTES: This module should be processed with the SALUT pre-processor
;	 with the re-alignment not requested, as:
;
;		SALUT XCOPY,NUL,;
;
;	 To assemble these modules, the sequential
;	 ordering of segments may be used.
;
;	 For LINK instructions:
;		link  profile ..\lib
;
; REVISION HISTORY: A000 Version 4.00: add PARSER, System Message Handler,
;			 Remove the BELL char.,turn off APPEND during TREE
;			 search,Extended Attribute processing, Uppercasing
;			 and "Out Of Space" during write to standard out.
;		    A001 PTM0011 XCOPY not handling path >63 characters.
;			 CHK_MAX_LENGTH proc(XCPYINIT) is Revised to err if
;			 >63 chrs.
;		    A002 PTM0012 XCOPY unnecessarily accessing current drive.
;			 ORG_S_T_DEF is Revised to ignore CHDIR if drive
;			 is not TARGET or SOURCE.
;		    A003 PTM0088 XCOPY (\) missing in 'FILE SHARING ERROR'.
;			 This problem is fixed with incorporation of the
;			 new message services.
;		    A004 PTM0700 9/02/87 Avoid duplicate switches and
;			 display parm in error.
;		    A005 DCR0201 9/11/87 Incorperate new format for EXTENDED
;			 ATTRIBUTES.
;		    A006 PTM1490 10/04/87 XCOPY /D CAUSES "INVALID PARAMETER"
;			 MSG AND SHOULD BE "INVALID NUMBER OF PARAMETERS" ALSO
;			 DATE IS NOT VALIDATED.
;		    A007 PTM1657 10/14/87 XCOPY INVALIDLY FAILS TO READ A READ
;			 ONLY FILE, AND OUTPUTS THE WRONG MSG.
;		    A008 PTM1688 10/15/87 XCOPY NOT CREATING EMPTY SUBDIRS IF
;			 THE SOURCE DIR. IS EMPTY.
;		    A009 PTM2199 11/02/87 XCOPY NOT HANDELING FILENAMES GREATER
;			 THAN 12 CHARACTERS.
;		    A010 PTM2203 11/03/87 XCOPY NOT HANDELING DBCS PATH NAMES
;			 PROPERLY. (INCORP. CHK. IF 1st BYTE IS DBCS)
;		    A011 PTM2271 11/04/87 XCOPY NOT HANDELING FILENAMES GREATER
;			 THAN 12 CHARACTERS.(S_FILE BUFFER OVERFLOWES).
;		    A012 PTM2347 11/09/87 XCOPY SETTING THE CODE PAGE OF A DEV.
;			 AND A DEV. IS NOT ALLOWED FOR A TARGET.
;		    A013 PTM2565 11/17/87 XCOPY HANGS AUTOTEST. SET EXTENDED
;			 ATTRIBUTE CALL TO DOS POINTS TO INVALID BUFFER.
;		    A014 PTM2597 11/20/87 XCOPY REPORTS FILE CREATION ERROR
;			 IF TARGET FILE IS GREATER THAN 12 CHARACTERS.
;		    A015 PTM2782 12/04/87 XCOPY FILENAME (EXTENSION)
;			 TRUNCATION ERROR. INCREASE HEADER BUFFER TO 3 PARA.
;		    A016 PTM2783 12/09/87 XCOPY ALLOWS 'ASSIGN' DRIVES TO
;			 BE COPIED ONTO THEMSELVS. ADD NEW CODE TO INIT.
;		    A017 PTM3139 01/15/88 XCOPY HANGS WHEN TRYING TO OUTPUT
;			 "INSUFFICIENT DISK SPACE" FOR MAKE DIRECTORY.
;		    A018 PTM3283 02/01/88 XCOPY NEEDS TO CHANGE 'FILE NOT
;			 FOUND' MSG TO EXTENDED ERROR MSG FORMAT. ALSO
;			 DELETED DEF 28 IN XCOPY.SKL & XMAINMSG.EQU
;		    A019 PTM3395 02/08/88 XCOPY FAILING TO SUSPEND THE
;			 'APPEND /X' FUNCTION. FIX IN XCOPY.SAL, XCOPY.EQU,
;			 AND DOS.EQU.
;		    A020 PTM3344 02/09/88 XCOPY READING PAST TOP_OF_MEMORY,
;			 OVER-WRITING VIDIO BUFFER SET BY MODE 13H ON PS2s.
;		    A021 PTM3513 02/19/88 XCOPY READING PAST TOP_OF_MEMORY,
;			 OVER-WRITING VIDIO BUFFER SET BY MODE 13H ON PS2s.
;		    A022 PTM3933 03/18/88 XCOPY NOT RESTORING DIRECTORY OF
;			 DEFAULT DRIVE. FIX IN XCOPY.SAL.
;		    A023 PTM3904 03/18/88 XCOPY NOT USING PARSE 03 MSG. FOR
;			 'INVALID SWITCH'. FIX IN XCOPY.SKL & XCPYINIT.SAL.
;		    A024 PTM3958 03/22/88 XCOPY MSGS DO NOT CONFORM TO SPEC.
;			 NEED NULL DELIMITER IN XCPYINIT.SAL.
;		    A025 PTM3965 03/23/88 XCOPY LEAVING CURRENT TARGET DIR.
;			 CHANGED. FIX IN XCPYINIT.SAL.
;		    A026 PTM4920 05/19/88 XCOPY NOT OVERLAYING FILES ON FULL
;			 TARGET DISK. FIX IN XCOPY.SAL.
;		    A027 PTM5022 06/03/88 'PATH TOO LONG' MSG. WITH TWO CHAR.
;			 SOURCE SUBDIR. FILESPEC. FIX IN XCPYINIT.SAL.
;
;     Label: "The DOS XCOPY Utility"
;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Program Property of Microsoft"
;
;****************** END OF SPECIFICATIONS *****************************

;--------------------------------
;   Include Files
;--------------------------------
INCLUDE XMAINMSG.EQU			;AN000;message file
INCLUDE DOS.EQU 			;AN000;
INCLUDE XCOPY.EQU			;AN000;

INCLUDE SYSMSG.INC			;AN000;

MSG_UTILNAME <XCOPY>			;AN000;

;-------------------------------
;    Structures
;-------------------------------
;HEADER - informations needed about the file, subdirectory ...
;Continue_Info -> 0 - a whole single file in this header segment, or dir.
;		  1 - Continuation of a small file.
;		  2 - Continuation of a Big file
;		  3 - EOF of continuation
;Next_Ptr      -> points to the next header segment
;Before_Ptr    -> points to the old header segment

HEADER	STRUC
	CONTINUE_INFO DB      0 	;set for filesize bigger then 0FFD0h
	NEXT_PTR DW	 ?		;next buffer ptr in para
	BEFORE_PTR DW	   ?		;before ptr in para
	DIR_DEPTH DB	  ?		;same as S_DEPTH
	CX_BYTES DW	 0		;actual # of bytes in this buffer seg.
	ATTR_FOUND DB	   ?		;attribute found
	FILE_TIME_FOUND DW	?
	FILE_DATE_FOUND DW	?
	LOW_SIZE_FOUND DW      ?
	HIGH_SIZE_FOUND DW	?
	TARGET_DRV_LET DB      " :"	;used for writing
	FILENAME_FOUND DB      13 DUP (0) ;AC015; FILENAME
	TERMINATE_STRING DB    16 DUP (0) ;AC015;TERM FILENAME STRING FOR DOS
	ATTRIB_LIST DW	 ?		;AC005;EXTENDED ATTRIBUTE BUFFER
;-------------------------------------------------------------------
;	extended attribute list used by extended open & get extended
;-------------------------------------------------------------------
;	ATTRIB_LIST LABEL BYTE		 extended attribute buffer
;
;EA		STRUC		; EXTENDED ATTRIBUTE
;EA_TYPE	DB	?	; TYPE
;EAISUNDEF	EQU	0	; UNDEFINED TYPE	      (ATTRIB SKIPS)
;				;   (OR TYPE NOT APPLICABLE)
;				;   LENGTH: 0 TO 64K-1 BYTES
;EAISLOGICAL	EQU	1	; LOGICAL (0 OR 1)	      (ATTRIB DISPLAYS) 				  ;   LENGTH: 1 BYTE
;EAISBINARY	EQU	2	; BINARY INTEGER	      (ATTRIB DISPLAYS)
;				;   LENGTH: 1, 2, 4 BYTES
;EAISASCII	EQU	3	; ASCII TYPE		      (ATTRIB DISPLAYS)
;				;   LENGTH: 0 TO 128 BYTES
;EAISDATE	EQU	4	; DOS FILE DATE FORMAT	      (ATTRIB DISPLAYS)
;				;   LENGTH: 2 BYTES
;EAISTIME	EQU	5	; DOS FILE TIME FORMAT	      (ATTRIB DISPLAYS)
;				;   LENGTH: 2 BYTES
;				; OTHER VALUES RESERVED
;EA_FLAGS	DW	?	; FLAGS
;EASYSTEM	EQU	8000H	; EA IS SYSTEM DEFINED
;				; (BUILTIN, NOT APPLICATION DEFINED)
;EAREADONLY	EQU	4000H	; EA IS READ ONLY (CANT BE CHANGED)
;EAHIDDEN	EQU	2000H	; EA IS HIDDEN FROM ATTRIB
;EACREATEONLY	EQU	1000H	; EA IS SETABLE ONLY AT CREATE TIME
;				; OTHER BITS RESERVED
;EA_RC		DB	?	; FAILURE REASON CODE (SET BY DOS)
;EARCNOTFOUND	EQU	1	; NAME NOT FOUND
;EARCNOSPACE	EQU	2	; NO SPACE TO HOLD NAME OR VALUE
;EARCNOTNOW	EQU	3	; NAME CAN'T BE SET ON THIS FUNCTION
;EARCNOTEVER	EQU	4	; NAME CAN'T BE SET
;EARCUNDEF	EQU	5	; NAME KNOWN TO THIS FS BUT NOT SUPPORTED
;EARCDEFBAD	EQU	6	; EA DEFINTION BAD (TYPE, LENGTH, ETC)
;EARCACCESS	EQU	7	; EA ACCESS DENIED
;EARCUNKNOWN	EQU	-1	; UNDETERMINED CAUSE
;EA_NAMELEN	DB	?	; LENGTH OF NAME
;EA_VALLEN	DW	?	; LENGTH OF VALUE
;EA_NAME	DB	?	; FIRST BYTE OF NAME
;
;EA_VALUE	DB	?	; FIRST BYTE OF VALUE
;
HEADER	ENDS

SUB_LIST STRUC
	DB	11			;AN000;
	DB	0			;AN000;
DATA_OFF DW	0			;AN000; offset of data to be inserted
DATA_SEG DW	0			;AN000; offset of data to be inserted
MSG_ID	DB	0			;AN000; n of %n
FLAGS	DB	0			;AN000; Flags
MAX_WIDTH DB	0			;AN000; Maximum field width
MIN_WIDTH DB	0			;AN000; Minimum field width
PAD_CHAR DB	0			;AN000; character for pad field

SUB_LIST ENDS




;******************************************************************************
SSEG	SEGMENT PARA STACK
	DB	64     DUP ('STACK   ') ;256 words
SSEG	ENDS



;******************************************************************************
DGROUP	GROUP	DSEG,DSEG_INIT		;FOR CONVENIENT ADDRESSIBLITY OF
					;DSEG_INIT in INIT routine
;******************************************************************************
DSEG	SEGMENT PARA PUBLIC		; DATA Segment
;--- EXTERNAL VARIABLES ---
EXTRN	PARM_FLAG: BYTE
EXTRN	COMMAND_LINE: BYTE		;AN000;THE COMMAND LINE FOR THE PARSER
;--- PUBLIC VARIABLES ---
PUBLIC	ERRORLEVEL

PUBLIC	DISP_S_PATH
PUBLIC	DISP_T_PATH
PUBLIC	S_DRV
PUBLIC	S_DRV_1
PUBLIC	T_DRV
PUBLIC	T_DRV_1
PUBLIC	T_DRV_2
PUBLIC	S_DRV_PATH
PUBLIC	S_PATH
PUBLIC	T_DRV_PATH
PUBLIC	T_PATH
PUBLIC	S_FILE
PUBLIC	T_FILENAME
PUBLIC	T_TEMPLATE
PUBLIC	T_MKDIR_LVL
PUBLIC	S_ARC_DRV
PUBLIC	S_ARC_PATH
;
PUBLIC	PSP_SEG
PUBLIC	SAV_DEFAULT_DRV
PUBLIC	SAV_DEFAULT_DIR
PUBLIC	SAV_S_DRV
PUBLIC	SAV_S_CURDIR
PUBLIC	SAV_T_DRV
PUBLIC	SAV_T_CURDIR
PUBLIC	S_DRV_NUMBER
PUBLIC	T_DRV_NUMBER
PUBLIC	TOP_OF_MEMORY
PUBLIC	BUFFER_PTR
PUBLIC	BUFFER_BASE
PUBLIC	BUFFER_LEFT
PUBLIC	MAX_BUFFER_SIZE
PUBLIC	MAX_CX
;
PUBLIC	MY_FLAG
PUBLIC	SYS_FLAG
PUBLIC	COPY_STATUS
PUBLIC	OPTION_FLAG
PUBLIC	INPUT_DATE
PUBLIC	INPUT_TIME

PUBLIC	SUBST_COUNT			;AN000;
PUBLIC	MSG_CLASS			;AN000;
PUBLIC	INPUT_FLAG			;AN000;
PUBLIC	MSG_NUM 			;AN000;

PUBLIC	SUBLIST1			;AN000;MSG SUBLIST USED BY INIT


;--- VARIABLES DEFINED ---

	MSG_SERVICES <MSGDATA>		;AN000;

ERRORLEVEL DB	0			;errorlevel
INPUT_DATE DW	0
INPUT_TIME DW	0
PSP_SEG DW	?
SAV_DEFAULT_DRV DB ?			;1 = A, 2 = B etc. saved default
SAV_DEF_DIR_ROOT DB '\'
SAV_DEFAULT_DIR DB 80 DUP (0)
SAV_S_DRV DB	'A:\'
SAV_S_CURDIR DB 80 DUP (0)
SAV_T_DRV DB	'B:\'
SAV_T_CURDIR DB 80 DUP (0)
;

DISP_S_PATH DB	67 DUP (0)		;mirror image of source path. used for display message when copying
DISP_S_FILE DB	13 DUP (0)
DISP_T_PATH DB	67 DUP (0)		;mirror image of target path
DISP_T_FILE DB	13 DUP (0)
;
B_SLASH DB	'\',0			;AN000;


FILE_COUNT LABEL WORD			;AN000;
FILE_CNT_LOW DW 0			;copied file count
FILE_CNT_HIGH DW 0
;

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPENDFLAG DW	0			;AN000;append /X status save area
FOUND_FILE_FLAG DB 0			;used for showing the message "File not found"
;
S_DRV_NUMBER DB 0			;source, target drv #
T_DRV_NUMBER DB 0
;
S_DRV_PATH LABEL BYTE			;source drv, path used for single_drv_copy
S_DRV	DB	'A:\'
S_PATH	DB	80 DUP (0)		;AN000;Initialized by calling GET CUR DIR
S_DEPTH DB	0
S_DRV_1 DB	'A:'
S_FILE	DB	'????????.???',0	;default filename to find file
S_FILE_OVERFLO DB 20 DUP (0)		;AN011;BUFFER IF MORE THAN 12 CHARS.
S_DIR	DB	'????????.???',0	;to find any subdirectory name
S_DIR_OVERFLO DB 20 DUP (0)		;AN011;BUFFER IF MORE THAN 12 CHARS.

S_PARENT DB	'..',0			;source parent used for non single_drv_copy
S_HANDLE DW	0			;file handle opened

S_ARC_DRV_PATH LABEL BYTE		;informations used to change source file's
S_ARC_DRV DB	'A:\'			;archieve bits.
S_ARC_PATH DB	64 DUP (0)
S_ARC_DEPTH DB	0

T_DRV_PATH LABEL BYTE			;target drv, path used all the time
T_DRV	DB	'B:\'
T_PATH	DB	80 DUP (0)		;AC016;init by call GET CUR DIR in INIT
T_DEPTH DB	0
T_FILE	LABEL	BYTE			;target filename for file creation
T_DRV_1 DB	'B:'			;target drv letter
T_FILENAME DB	15 DUP (0)		;target filename
T_TEMPLATE DB	15 DUP (0)		;if global chr entered, this will be used instead of filename.

T_PARENT LABEL	BYTE
T_DRV_2 DB	'B:'
T_PARENT_1 DB	'..',0
T_HANDLE DW	0			;target handle created
T_MKDIR_LVL DB	0			;# of target starting directories created.
;
;------------------------------------------
; PRINT_STDOUT input parameter save area
;------------------------------------------
SUBST_COUNT DW	0			;AN000; message substitution count
MSG_CLASS DB	0			;AN000; message class
INPUT_FLAG DB	0			;AN000; Type of INT 21 used for KBD input
MSG_NUM DW	0			;AN000; message number


INPUT_BUFF db	20  dup(0)		;AN000; keyboard input buffer used
					;for user response (Y/N)

;--------------------------------------------------------------
; Following three sublists are used by the  Message Retriever
;--------------------------------------------------------------
SUBLIST1 LABEL	DWORD			;AN000;SUBSTITUTE LIST 1
	DB	11			;AN000;sublist size
	DB	0			;AN000;reserved
	DD	0			;AN000;substition data Offset
	DB	1			;AN000;n of %n
	DB	0			;AN000;data type
	DB	0			;AN000;maximum field width
	DB	0			;AN000;minimum field width
	DB	0			;AN000;characters for Pad field


SUBLIST2 LABEL	DWORD			;AN000;SUBSTITUTE LIST 2
	DB	11			;AN000;sublist size
	DB	0			;AN000;reserved
	DD	0			;AN000;substition data Offset
	DB	2			;AN000;n of %n
	DB	0			;AN000;data type
	DB	0			;AN000;maximum field width
	DB	0			;AN000;minimum field width
	DB	0			;AN000;characters for Pad field


SUBLIST3 LABEL	DWORD			;AN000;SUBSTITUTE LIST 3
	DB	11			;AN000;sublist size
	DB	0			;AN000;reserved
	DD	0			;AN000;substition data Offset
	DB	3			;AN000;n of %n
	DB	0			;AN000;data type
	DB	0			;AN000;maximum field width
	DB	0			;AN000;minimum field width
	DB	0			;AN000;characters for Pad field


FILE_SEARCH_ATTR DW NORM_ATTR
DIR_SEARCH_ATTR DW INCL_H_S_DIR_ATTR
;
OPEN_MODE DB	Read_Only_Deny_Write	;READ_ONLY_DENY_WRITE	 ;access, sharing mode
;
;Equates are defined in XCOPY.EQU

MY_FLAG DB	0			;informations for a tree walk
;	find_first_flag    equ	   01h	;set MY_FLAG by "OR"
;	findfile_flag	   equ	   02h
;	no_more_file	   equ	   04h
;	single_copy_flag   equ	   08h	;single copy instead of multi copy
;	visit_parent_flag  equ	   10h	;visit parent node
;	found_flag	   equ	   20h	;found flag - for find subdir
;	missing_link_flag  equ	   40h	;insuffiecient info. for not creating empty dir
;	is_source_flag	   equ	   80h	;if set, dealing with source
;	reset_find_first   equ	  0FEh	;reset by AND
;	reset_findfile	   equ	  0FDh
;	reset_no_more	   equ	  0FBh
;	reset_visit_parent equ	  0EFh
;	reset_found	   equ	  0DFh
;	reset_missing_link equ	  0BFh
;	reset_is_source    equ	  07Fh

FILE_FLAG DB	0
;	cont_flag	   equ	   01h
;	eof_flag	   equ	   02h
;	big_file_flag	   equ	   04h
;	file_bigger_flag   equ	   08h
;	created_flag	   equ	   10h
;	reset_cont	   equ	  0FEh
;	reset_eof	   equ	  0FDh
;	reset_big_file	   equ	  0FBh
;	reset_file_bigger  equ	  0F7h
;	reset_created	   equ	  0EFh
;	reset_readfile	   equ	  0F0h	;reset FILE_FLAG for read a file
;
COPY_STATUS DB	0
;	open_error_flag    equ	   01h
;	read_error_flag    equ	   02h
;	create_error_flag  equ	   04h
;	write_error_flag   equ	   08h
;	mkdir_error_flag   equ	   10h
;	chdir_error_flag   equ	   20h
;	maybe_itself_flag  equ	   40h
;	disk_full_flag	   equ	   80h
;	reset_open_error   equ	  0FEh
;	reset_read_error   equ	  0FDh
;	reset_create_error equ	  0FBh
;	reset_write_error  equ	  0F7h
;	reset_close_error  equ	  0EFh
;	reset_chdir_error  equ	  0DFh
;
ACTION_FLAG DB	0
;	reading_flag	   equ	  01h	;display "Reading source files..."
;	reset_reading	   equ	  0FEh	;do not display.
;
SYS_FLAG DB	0			;system information
;	one_disk_copy_flag   equ   01h	;xcopy with only one logical drive.
;	default_drv_set_flag equ   02h	;default drive has been changed by this program
;	default_s_dir_flag   equ   04h	;source current directory saved.
;	default_t_dir_flag   equ   08h	;target current directory saved.
;	removalble_drv_flag  equ   10h
;	sharing_source_flag  equ   20h	;source shared
;	sharing_target_flag  equ   40h
;	turn_verify_off_flag equ   80h	;turn the verify off when exit to dos
;	reset_default_s_dir  equ  0FBh	;reset default_s_dir_flag
;
OPTION_FLAG DB	0
;	slash_a 	   equ	  01h	;soft archieve ?
;	slash_d 	   equ	  02h	;date?
;	slash_e 	   equ	  04h	;create empty dir?
;	slash_m 	   equ	  08h	;hard archieve ? (turn off source archieve bit)
;	slash_p 	   equ	  10h	;prompt?
;	slash_s 	   equ	  20h	;walk the tree?
;	slash_v 	   equ	  40h	;verify on?
;	slash_w 	   equ	  80h	;show "Press any key to begin copying" msg)
;	reset_slash_a	   equ	 0FEh	;turn off soft archieve
;	reset_slash_m	   equ	 0F7h	;turn off hard archieve

MAX_CX	DW	0			;less than 0FFD0h
ACT_BYTES DW	0			;actual bytes read.
HIGH_FILE_SIZE DW 0
LOW_FILE_SIZE DW 0
;
TOP_OF_MEMORY DW 0			;para
BUFFER_BASE DW	0			;para
MAX_BUFFER_SIZE DW 0			;para.	BUFFER_LEFT at INIT time.
BUFFER_LEFT DW	0			;para
BUFFER_PTR DW	0			;para. If buffer_left=0 then invalid value
DATA_PTR DW	0			;buffer_ptr + HEADER
OLD_BUFFER_PTR DW 0			;last buffer_ptr
SIZ_OF_BUFF DW	?			;AN005;para. EXTENDED ATTRIB BUFF SIZE
BYTS_OF_HDR DW	?			;AN005;bytes TOTAL HEADER SIZE
PARA_OF_HDR DW	3			;AC008;para. TOTAL HDR SIZE INIT TO 3
OPEN_FILE_COUNT DW ?			;AN005;TRACKING OF OPEN FLS FOR BUFFER
;					      ;SIZE CALCULATION.
DBCSEV_OFF DW	0			;AN010; remember where dbcs vector is
DBCSEV_SEG DW	0			;AN010;next time I don't have to look
;
;structured data storage allocation
FILE_DTA Find_DTA <>			;DTA for find file
DTAS	Find_DTA 32 dup (<>)		;DTA STACK for find dir
;** Througout the program BP will be used for referencing fieldsname in DTAS.
;For example, DS:[BP].dta_filename.
DSEG	ENDS

;******************************************************************************

CSEG	SEGMENT PUBLIC
	ASSUME	CS:CSEG, DS:DGROUP, SS:SSEG

	MSG_SERVICES <LOADmsg,GETmsg,DISPLAYmsg,INPUTmsg,CHARmsg,NUMmsg> ;AN000;
	MSG_SERVICES <XCOPY.CLA,XCOPY.CL1,XCOPY.CL2> ;AN000;




;--- EXTERNAL PROCEDURES ---
EXTRN	INIT:	NEAR			;INIT PROC
;
;--- PUBLIC   PROCEDURES ---		;USED BY INIT
PUBLIC	SET_BUFFER_PTR
PUBLIC	STRING_LENGTH
PUBLIC	CONCAT_ASCIIZ
PUBLIC	LAST_DIR_OUT
PUBLIC	CHK_DRV_LETTER
PUBLIC	COMPRESS_FILENAME
PUBLIC	PRINT_STDOUT
PUBLIC	PRINT_STDERR
PUBLIC	SET_DEFAULT_DRV
PUBLIC	MAIN_EXIT
PUBLIC	MAIN_EXIT_A
PUBLIC	CTRL_BREAK_EXIT
PUBLIC	SWITCH_DS_ES
PUBLIC	MY_INT24

;--- INT 24 ADDR ----------
PUBLIC	SAV_INT24_OFF
PUBLIC	SAV_INT24_SEG

PUBLIC	SYSLOADMSG			;AN000;
PUBLIC	SYSDISPMSG
PUBLIC	SYSGETMSG

SAV_INT24 LABEL DWORD
SAV_INT24_OFF DW 0			;original int 24 addr holder
SAV_INT24_SEG DW 0
;--- START OF A PROGRAM ---
	ASSUME	DS:NOTHING		;AN000;
	ASSUME	ES:NOTHING		;AN000;
MAIN	PROC	FAR
	PUSH	AX			;AN000;PRESERVE FOR INIT DRV VALIDITY
	MOV	BX,DGROUP
	MOV	ES,BX			;AN000;SET UP ADDRESS OF DSEG IN ES
	ASSUME	ES:DGROUP		;AN000;
	MOV	SI,81H			;AN000;POINT TO THE INPUT STRING
	LEA	DI,COMMAND_LINE 	;AN000;POINT TO THE SAVE AREA IN PARSER
	MOV	CX,127			;AN000;GET ALL THE DATA(LOOP COUNT)
	REP	MOVSB			;AN000;MOVE IT
	MOV	PSP_SEG,DS		;AN000;REMEMBER WHERE THE PSP IS
	MOV	DS,BX			;AN000;SET UP ADDRESS OF DSEG IN DS
	ASSUME	DS:DGROUP		;AN000;

	CALL	SYSLOADMSG		;AN000; preload all messages
	jnc	XCOPY_INIT		;AN000; no error, do xcopy init

	CALL	SYSDISPMSG		;AN000; else display error message
	POP	AX			;AN000;WAS PRESERVED FOR DRV VALIDATION
	JMP	JUST_EXIT		;AN000; exit

XCOPY_INIT:
	POP	AX			;AN000;WAS PRESERVED FOR DRV VALIDATION
	CALL	INIT			;initialization
	JC	MAIN_EXIT		;error. (Already message has been displayed)
	MOV	BP, OFFSET DTAS 	;initialize BP
	OR	ACTION_FLAG, READING_FLAG ;set reading flag for copy message

;Before walking the tree, find out the /X status of APPEND and save it.
;Then terminate the /X feature.  After the tree search, restore the
;original /X status. This is done at EXIT time.

	MOV	AX,CHK_APPEND		;AN000;CHECK IF APPEND INSTALLED
	INT	2FH			;AN000;
	OR	AL,AL			;AN000;INSTALLED?
;	$IF	NZ			;AN000;YES
	JZ $$IF1
	    MOV     AX,VER_APPEND	;AN019;ASK IF DOS VERSION OF APPEND
	    INT     2FH 		;AN019;CALL THE FUNCTION
	    CMP     AX,D_V_APPEND	;AN000;DOS VERSION?
;	    $IF     E			;AN000;YES
	    JNE $$IF2
		MOV	AX,GET_APPEND	;AN000;GET THE APPEND STATE
		INT	2FH		;AN000;
		MOV	APPENDFLAG,BX	;AN000;SAVE THE STATE TO RESTORE
		TEST	APPENDFLAG,F_APPEND  ;AN019;IS THE /X BIT ON?
;		$IF	NZ		;AN000;YES
		JZ $$IF3
		    MOV     AX,SET_APPEND ;AN000;SET THE APPEND STATE
		    MOV     BX,APPENDFLAG ;AN000;GET THE SAVED STATE
		    XOR     BX,F_APPEND ;AN000;TURN OFF THE /X BIT
		    INT     2FH 	;AN000;DO IT
;		$ENDIF			;AN000;
$$IF3:
;	    $ENDIF			;AN000;
$$IF2:
;	$ENDIF				;AN000;
$$IF1:

	CALL	TREE_COPY
	CALL	ORG_S_DEF		;restore the original source default dir
	CALL	WRITE_FROM_BUFFER	;write from buffer if we missed it.

MAIN_EXIT:
	MOV	BX, DGROUP
	MOV	DS, BX			;re initialize ds, es
	MOV	ES, BX			;exit here if the status of source, target or default drv has been changed.
	CALL	CHK_FILE_NOT_FOUND	;if no files has been found, show the message.
					;
; Set message substitution list
	LEA	SI,SUBLIST1		;AN000; get addressability to sublist
	LEA	DX,FILE_COUNT		;AN000; offset to file count
	MOV	[SI].DATA_OFF,DX	;AN000; save data offset
	MOV	[SI].DATA_SEG,DS	;AN000; save data segment
	MOV	[SI].MSG_ID,1		;AN000; message ID
	MOV	[SI].FLAGS,RIGHT_ALIGN+UNSGN_BIN_DWORD ;AN018;
	MOV	[SI].MAX_WIDTH,9	;AN018; MAXIMUM FIELD WITH
	MOV	[SI].MIN_WIDTH,9	;AN018; MINIMUM FIELD WITH
	MOV	[SI].PAD_CHAR,SPACE	;AN018; MINIMUM FIELD WITH

; Set message parameters
	MOV	AX,MSG_FILES_COPIED	;AN000; message number
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,PARM_SUBST_ONE ;AN000; one message substitution
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,NO_INPUT	;AN000; no user input
	CALL	PRINT_STDOUT		;AN000; display file count

MAIN_EXIT_A:
	MOV	BX, DGROUP
	MOV	DS, BX			;re initialize ds, es
	MOV	ES, BX			;exit here if the status of source, target or default drv has been changed.
	CALL	CHK_MKDIR_LVL		;starting target directory has been created?
	CALL	ORG_S_T_DEF		;restore original target, source, default drv, and verify status

JUST_EXIT:				;unconditional immediate exit

; Restore the original status of APPEND if active.


	MOV	BX,APPENDFLAG		;AN000;GET THE STATUS WORD
	OR	BX,BX			;AN019;IF FLAGS SAVED, THIS IS DOS VER.
;	$IF	NZ			;AN019;IF ACTIVE,
	JZ $$IF7
	    MOV     AX,SET_APPEND	;AN000;SET TO THE ORIGINAL STATE
	    INT     2FH 		;AN000; turn on the /X feature
;	$ENDIF				;AN000;
$$IF7:
;
	MOV	AH, 4Ch 		;return to dos
	MOV	AL, ERRORLEVEL		;set return code whatever
	INT	21H
CTRL_BREAK_EXIT:
	MOV	ERRORLEVEL, 2		;set errorlevel to 2 for control break
	JMP	MAIN_EXIT_A

MAIN	ENDP
;


;----------------- SUBROUTINES ---------------------------------------------

TREE_COPY PROC	NEAR

;Walk the source tree to read files and subdirectories

	OR	MY_FLAG, FINDFILE_FLAG	;deals with files
	OR	MY_FLAG, FIND_FIRST_FLAG ;find first
	CALL	SET_MY_DTA		;set DTA to FILE_DTA
;	$DO
$$DO9:
	    CALL    FIND_FILE		;find first (next)
	    TEST    MY_FLAG, NO_MORE_FILE ;no more file?
;	$LEAVE	NZ			;then exit loop
	JNZ $$EN9
	    CALL    READ_INTO_BUFFER	;else read the file into the buffer
;	$ENDDO
	JMP SHORT $$DO9
$$EN9:

	TEST	OPTION_FLAG, SLASH_S	;walk the tree?
;	$IF	NZ,LONG
	JNZ $$XL1
	JMP $$IF12
$$XL1:

	    AND     MY_FLAG, RESET_FINDFILE ;now, deals with directory
	    OR	    MY_FLAG, FIND_FIRST_FLAG ;find first
;	    $DO
$$DO13:
		CALL	SET_MY_DTA	;set DTA to DTAS according to BP
		CALL	FIND_DIR	;find first (next)
		TEST	MY_FLAG, NO_MORE_FILE ;no more subdirectory?
;	    $LEAVE  NZ			;then leave this loop to return to caller
	    JNZ $$EN13
		LEA	DI, S_DRV_PATH
		LEA	SI, [BP].DTA_FILENAME
		CMP	S_PATH, 0	;root directory?
;		$IF	E
		JNE $$IF15
		    MOV     AL, 0FFh	;then '\' is already provided. Just concat.
;		$ELSE
		JMP SHORT $$EN15
$$IF15:
		    MOV     AL, PATH_DELIM ;put delimiter
;		$ENDIF
$$EN15:
		CALL	CONCAT_ASCIIZ	;make new path
		test	option_flag, slash_p ;prompt mode?
;		$IF	NZ
		JZ $$IF18
		    call    p_concat_display_path
;		$ENDIF
$$IF18:
		INC	S_DEPTH 	;increase depth
		CALL	MAKE_HEADER	;make header in the buffer
		OR	MY_FLAG, IS_SOURCE_FLAG ;dealing with source
		AND	MY_FLAG, RESET_VISIT_PARENT ;going to visit child node
		CALL	CHANGE_S_DIR	;change source dir
		ADD	BP, type FIND_DTA ;increase DTAS stack pointer
		CALL	TREE_COPY	;tree copy the sub directory
;	    $ENDDO
	    JMP SHORT $$DO13
$$EN13:

	    CMP     S_DEPTH, 0		;starting directory? then exit
;	    $IF     NE			;else
	    JE $$IF21
		DEC	S_DEPTH 	;dec depth
		TEST	OPTION_FLAG, SLASH_E ;copy subdirectories even if empty?
;		$IF	Z
		JNZ $$IF22
		    CALL    DEL_EMPTY	;then check the old_buffer_ptr and
					;if it is a directory, then restore
					;buffer_ptr to old.
;		$ENDIF
$$IF22:
		LEA	DI, S_DRV_PATH
		CALL	LAST_DIR_OUT	;change environments
		test	option_flag, slash_p ;prompt mode?
;		$IF	NZ
		JZ $$IF24
		    call    p_cut_display_path
;		$ENDIF
$$IF24:
		LEA	DX, S_DRV_PATH	;before returning to the caller
		OR	MY_FLAG, IS_SOURCE_FLAG
		OR	MY_FLAG, VISIT_PARENT_FLAG
		CALL	CHANGE_S_DIR
		SUB	BP, type FIND_DTA
;	    $ENDIF
$$IF21:
;	$ENDIF				;walk the tree
$$IF12:
	RET
TREE_COPY ENDP
;

DEL_EMPTY PROC	NEAR
;If buffer is not full, and the tree walk is going to return to the parents,
;this routine should be called.
;If old_buffer_ptr points to a directory, then set buffer_ptr to this, and
;increase buffer_left by HEADER (para) and set old_buffer_ptr to that of
;BEFORE_PTR. i.e. delete the empty directory entry from the buffer.

	PUSH	ES

	PUSH	CS
	POP	AX
	CMP	OLD_BUFFER_PTR, AX	;buffer is empty?
	JE	DE_EXIT 		;yes, exit

	MOV	ES, OLD_BUFFER_PTR
	TEST	ES:ATTR_FOUND, 10h	;directory?
	JZ	DE_EXIT 		;if not, exit
	MOV	AX, OLD_BUFFER_PTR
	MOV	BUFFER_PTR, AX		;set new BUFFER_PTR
	MOV	AX, ES:BEFORE_PTR
	MOV	OLD_BUFFER_PTR, AX	;set new OLD_BUFFER_PTR
	MOV	AX, PARA_OF_HDR 	;AN005;GET THE HEADER SIZE (para.)
	ADD	BUFFER_LEFT, AX 	;AC005;dir entry must be only hdr SIZE.

DE_EXIT:
	POP	ES
	RET
DEL_EMPTY ENDP
;


P_concat_display_path proc near
;concatenate subdirectory name found from DTAS to the
;DISP_S_PATH which will be used for prompts
;DS - data seg
	MOV	DI, OFFSET DISP_S_PATH
	LEA	SI, [BP].DTA_FILENAME
	CMP	S_DEPTH, 0		;this will be the first subdir?
;	$IF	E
	JNE $$IF28
	    MOV     AL, 0FFh		;then do not put '\'
;	$ELSE
	JMP SHORT $$EN28
$$IF28:
	    MOV     AL, Path_delim
;	$ENDIF
$$EN28:
	CALL	CONCAT_ASCIIZ
	RET
P_concat_display_path endp
;


P_cut_display_path proc near
;take the last dir out from the DISP_S_PATH for prompt.
;DS,ES - data seg
	MOV	SI, OFFSET DISP_S_PATH
	MOV	DI, OFFSET DISP_S_PATH
	CALL	LAST_DIR_OUT
;	$IF	C
	JNC $$IF31
	    CALL    CHK_DRV_LETTER
;	    $IF     NC
	    JC $$IF32
		MOV	BYTE PTR DS:[SI], 0
;	    $ELSE
	    JMP SHORT $$EN32
$$IF32:
		MOV	BYTE PTR [DI], 0
;	    $ENDIF
$$EN32:
;	$ELSE
	JMP SHORT $$EN31
$$IF31:
	    CMP     S_DEPTH, 0
;	    $IF     E
	    JNE $$IF36
		MOV	DI, AX
		DEC	DI
		MOV	BYTE PTR [DI], '\'
		MOV	BYTE PTR [DI+1], 0
;	    $ENDIF
$$IF36:
;	$ENDIF
$$EN31:
	RET
P_cut_display_path endp
;


READ_INTO_BUFFER PROC NEAR
;Read *** a *** file	into buffer
	TEST	MY_FLAG, SINGLE_COPY_FLAG ;single copy?
;	$IF	Z,AND			;no, multi copy
	JNZ $$IF39
	TEST	ACTION_FLAG, READING_FLAG ;show message?
;	$IF	NZ			;yes.
	JZ $$IF39
	    MOV     AX,MSG_READING_SOURCE ;AN000; message number
	    MOV     MSG_NUM,AX		;AN000; set message number
	    MOV     SUBST_COUNT,NO_SUBST ;AN000; no message substitution
	    MOV     MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	    MOV     INPUT_FLAG,NO_INPUT ;AN000; no input
	    CALL    PRINT_STDOUT	;AN000;show message "Reading source files"

	    AND     ACTION_FLAG, RESET_READING ;reset it
;	$ENDIF
$$IF39:

	AND	FILE_FLAG, RESET_READFILE ;reset file_flag to read a file
	MOV	AX,FILE_DTA.DTA_FILE_SIZE_HIGH
	MOV	HIGH_FILE_SIZE, AX
	MOV	AX,FILE_DTA.DTA_FILE_SIZE_LOW
	MOV	LOW_FILE_SIZE, AX
	CALL	CMP_FILESIZE_TO_BUFFER_LEFT ;compare sizes

	MOV	AX, PARA_OF_HDR 	;AN005;GET THE HEADER SIZE (para.)
	CMP	MAX_BUFFER_SIZE, AX	;AN005;IS EA BUFFER TOO LARGE?
;	$IF	B
	JNB $$IF41
	    CLC 			;AN005;CLEAR CARRY
	    MOV     AX, MSG_INSUF_MEMORY ;AC005;GET THE MESSAGE ID
	    MOV     MSG_NUM,AX		;AN005;NEED MESSAGE ID FOR PRINT
	    MOV     SUBST_COUNT,NO_SUBST ;AN005;NO SUBSTITUTION TEXT
	    MOV     INPUT_FLAG,NO_INPUT ;AN005;NO INPUT = 0
	    MOV     MSG_CLASS,UTILITY_MSG_CLASS ;AN005;MESSAGE CLASS = -1
	    CALL    PRINT_STDERR	;AN005;print error. AX points to msg ID
;	$ENDIF				;AN005;WE HAVE ENOUGH MEMORY
$$IF41:
	MOV	AX, PARA_OF_HDR 	;AN005;GET THE HEADER SIZE (para.)
	CMP	MAX_BUFFER_SIZE,AX	;AN005;IS EA BUFFER TOO LARGE?
	JB	RIB_ERROR		;AN005;CLOSE THE FILE AND GET THE NEXT

	TEST	FILE_FLAG, FILE_BIGGER_FLAG ;filesize > buffer_left - HEADER ?
	JZ	RIB_SMALL		;if not, then small file
	MOV	BX, S_HANDLE		;AN005;
	CALL	CLOSE_A_FILE		;AN005;ONLY OPENED TO GET BUFFER SIZE
	CALL	WRITE_FROM_BUFFER
	CALL	CMP_FILESIZE_TO_BUFFER_LEFT ;compare again
	TEST	FILE_FLAG, FILE_BIGGER_FLAG ;still bigger?
	JNZ	RIB_BIG 		;yes.  Big file
RIB_SMALL:
	CALL	SMALL_FILE
	JC	RIB_ERROR
	JMP	RIB_EXIT
RIB_BIG:
	MOV	BX, S_HANDLE		;AN005;
	CALL	CLOSE_A_FILE		;AN005;ONLY OPENED TO GET BUFFER SIZE
	CALL	BIG_FILE
	JNC	RIB_EXIT
RIB_ERROR:
	TEST	COPY_STATUS, OPEN_ERROR_FLAG ;open error?
	JNZ	RIB_EXIT		;just exit. find next file
	MOV	BX, S_HANDLE		;else write error
	CALL	CLOSE_A_FILE		;close the troubled file
					;and find next file
RIB_EXIT:
	TEST	MY_FLAG, SINGLE_COPY_FLAG ;single copy?
;	$IF	NZ
	JZ $$IF43
	    CALL    WRITE_FROM_BUFFER	;then write a file
;	$ENDIF
$$IF43:
	RET
READ_INTO_BUFFER ENDP
;


SMALL_FILE PROC NEAR
;handles a file smaller than max_buffer_size or buffer_left, i.e. fit in memory.
;This routine will call MAKE_HEADER, SET_BUFFER_PTR< READ_A_FILE,
;CALC_FILE_SIZE, CMP_FILE_FFD0h, CLOSE_A_FILE.

SMF_CONT:
	CALL	CMP_FILE_FFD0h		;filesize > 0FFD0h ?
	TEST	FILE_FLAG, FILE_BIGGER_FLAG
	JZ	SMF_EOF 		;filesize <= 0FFD0h
	OR	FILE_FLAG, CONT_FLAG	;filesize > 0FFD0h. set cont_flag
	MOV	CX, 0FFD0h		;# of bytes to read
	CALL	READ_A_FILE
	JC	SMF_ERROR		;unsuccessful read?
	CALL	MAKE_HEADER		;else make header and ready for next
	CALL	CALC_FILE_SIZE		;filesize = filesize - bytes read
	JMP	SMF_CONT		;loop. compare again with the rest

SMF_EOF:
	MOV	CX, LOW_FILE_SIZE	;rest of the bytes to read
	OR	FILE_FLAG, EOF_FLAG	;AN000;set EOF
	CALL	READ_A_FILE
	JC	SMF_ERROR
	CALL	MAKE_HEADER
	MOV	BX, S_HANDLE
	CALL	CLOSE_A_FILE
	JMP	SMF_EXIT
SMF_ERROR:
					;
SMF_EXIT:
	RET
SMALL_FILE ENDP
;


BIG_FILE PROC	NEAR
;handles a file which is bigger than max_buffer_size
;Needs 2 file handles open concurrently for read and write

	OR	FILE_FLAG, BIG_FILE_FLAG
	OR	FILE_FLAG, CONT_FLAG
	CALL	OPEN_A_FILE
	JC	BIF_ERROR		;error in open?
	CMP	MAX_BUFFER_SIZE, 0FFFh	;max buffer size > 0FFFh in para ?
	JA	BIF_BIG 		;yes. large buffer system
					;else small buffer
	MOV	CX, MAX_CX		;CX = max_buffer_size * 16 - HEADER
BIF_SM:
	CALL	READ_A_FILE
	JC	BIF_ERROR		;read error?
	CALL	MAKE_HEADER
	CALL	WRITE_FROM_BUFFER
	JC	BIF_ERROR		;write error?
	TEST	FILE_FLAG, EOF_FLAG	;end of file set by READ_A_FILE?
	JZ	BIF_SM			;if not, read again
	MOV	BX, S_HANDLE
	CALL	CLOSE_A_FILE
	JMP	BIF_EXIT		;finished.
BIF_BIG:
	MOV	CX, 0FFD0h		;max # of data bytes this program supports
BIF_BIG1:
	CALL	READ_A_FILE
	JC	BIF_ERROR
	CALL	MAKE_HEADER
	CALL	CALC_FILE_SIZE		;modify file size
BIF_BIG2:
	CALL	CMP_FILESIZE_TO_BUFFER_LEFT ;filesize > buffer_left?
	TEST	FILE_FLAG, FILE_BIGGER_FLAG ;yes.
	JZ	BIF_END 		;if it is not, call small_file
	MOV	AX, PARA_OF_HDR 	;AN021;GET THE ATTR. HDR SIZE
	ADD	AX, 0FFFh		;AN021;
	CMP	BUFFER_LEFT, AX 	;AC021;BUFFER_LEFT >= 0FFF0h+HDR SIZE?
	JAE	BIF_BIG 		;then loop again.
	MOV	AX, PARA_OF_HDR 	;AN021;GET THE ATTR. HDR SIZE
	ADD	AX, 140H		;AN021;
	CMP	BUFFER_LEFT, AX 	;AC021;BUFFER_LEFT >= 5Kbytes+HDR SIZE?
					;minimum buffer size this pgm supports.
	JL	BIF_BIG3		;then flush buffer and try again. **IF system buffer left < 5 K then infinit loop can happen.
	MOV	AX,BUFFER_LEFT
	SUB	AX,PARA_OF_HDR		;AC005;FOR HEADER SIZE para.
	MOV	CX,16
	MUL	CX			;AN020;MAKE IT NUMBER OF BYTES
	MOV	CX,AX			;AN020;FOR READ
	JMP	BIF_BIG1		;read again
BIF_BIG3:
	CALL	WRITE_FROM_BUFFER
	JC	BIF_ERROR
	JMP	BIF_BIG2		;flush buffer and compare again.
BIF_END:
	CALL	SMALL_FILE		;when filesize <= buffer_left then SMALL_FILE will finish it.
	JC	BIF_ERROR		;something wrong?
	CALL	WRITE_FROM_BUFFER	;else finish copying this file
	JNC	BIF_EXIT
BIF_ERROR:
					;what happened?
BIF_EXIT:
	RET
BIG_FILE ENDP
;


MAKE_HEADER PROC NEAR
;When called by READ_A_FILE after the data had been read into the buffer, this
;routine will put the header which is just below the data area where the
;current BUFFER_PTR points.  The header E.A.BUFFER SIZE + (3 para) long. And
;this routine will also call SET_BUFFER_PTR to set the BUFFER_PTR, BUFFER_LEFT
;for the next process.
;If called by TREE_COPY for a SUBDIRECTORY handle, this routine should
;check the BUFFER_LEFT (when called by READ_A_FILE, the caller is assumed
;to check the size of buffer_left before calling.)  In this case, this
;routine will set the next BUFFER_PTR, BUFFER_LEFT, OLD_BUFFER_PTR
;instead of SET_BUFFER_PTR routine.
;Informations are obtained from the DTA area (for file - FILE_DTA.xxx
;dir - DS:[BP].xxx ) and stored into the header by referencing ES:field;s name.
;DS - Program Data area
;ES - will be used for a header segment in the buffer.
;
	PUSH	ES			;save ES
	PUSH	AX

MH_AGAIN:
	MOV	AX,BUFFER_PTR		;buffer_ptr is a segment
	MOV	ES, AX			;now, ES is a header seg.
;

	MOV	AX, PARA_OF_HDR 	;AN005;GET THE HEADER SIZE (para.)
	CMP	BUFFER_LEFT,AX		;AC005;buffer_left=less than NEEDED?
	JAE	MH_START
	CALL	WRITE_FROM_BUFFER	;if so, flush buffer
	JC	MH_ERROR_BRIDGE 	;write error?
	JMP	SHORT MH_AGAIN		;reinitialize ES to new buffer ptr
MH_START:
	TEST	MY_FLAG, FINDFILE_FLAG	;identify caller.
	JNZ	MH_FILE 		;if a file, jmp to MH_FILE
					;else deals with directory.
	MOV	ES:CONTINUE_INFO, 0	;not a continuation.
	MOV	AX,OLD_BUFFER_PTR
	MOV	ES:BEFORE_PTR, AX	;set before_ptr in header
	MOV	AX,BUFFER_PTR
	MOV	OLD_BUFFER_PTR, AX	;set variable OLD_BUFFER_PTR
	ADD	AX,PARA_OF_HDR		;AC005;AX = BUFFER_PTR+HEADER(para)
	MOV	BUFFER_PTR, AX		;set new BUFFER_PTR
	MOV	ES:NEXT_PTR, AX 	;set NEXT_PTR in the header
	MOV	AX, PARA_OF_HDR 	;AN005;GET THE HEADER SIZE (para.)
	SUB	BUFFER_LEFT,AX		;AC005;adjust BUFFER_LEFT
	CMP	BUFFER_LEFT,AX		;AC005;less than HEADER SIZE (para) ?
;	$IF	B
	JNB $$IF45
	    MOV     BUFFER_LEFT, 0	;indicate buffer_full
;	$ENDIF
$$IF45:
	MOV	AL, S_DEPTH
	MOV	ES:DIR_DEPTH, AL	;now save other info's
	MOV	AL, DS:[BP].DTA_ATTRIBUTE
	MOV	ES:ATTR_FOUND, AL	;in this case, DIR
	MOV	AL, BYTE PTR T_DRV
	MOV	ES:TARGET_DRV_LET, AL	;mov target drive letter
	MOV	ES:TARGET_DRV_LET+1, DRV_delim ; ':'
	MOV	CX, 13
	LEA	SI, [BP].DTA_FILENAME	;DS:SI
	MOV	DI, OFFSET ES:FILENAME_FOUND ;ES:DI
	REP	MOVSB			;mov sting until cx = 0
	JMP	MH_EXIT
MH_ERROR_BRIDGE: JMP MH_ERROR
MH_FILE:				;handles a file header hereafter.
	TEST	FILE_FLAG, CONT_FLAG	;continuation?
	JZ	MH_WHOLE_FILE		;no, just a whole file
	TEST	FILE_FLAG, EOF_FLAG	;Eof flag set?
	JNZ	MH_CONT_END		;yes, must be end of continuation
	TEST	FILE_FLAG, BIG_FILE_FLAG ;Is this a big file?
	JNZ	MH_BIG			;yes
	MOV	ES:CONTINUE_INFO, 1	;else small file continuation.
	JMP	MH_A_FILE
MH_WHOLE_FILE:
	MOV	ES:CONTINUE_INFO, 0
	JMP	MH_A_FILE
MH_CONT_END:
	MOV	ES:CONTINUE_INFO, 3
	JMP	MH_A_FILE
MH_BIG:
	MOV	ES:CONTINUE_INFO, 2
MH_A_FILE:
	MOV	AX,FILE_DTA.DTA_FILE_TIME
	MOV	ES:FILE_TIME_FOUND, AX
	MOV	AX, FILE_DTA.DTA_FILE_DATE
	MOV	ES:FILE_DATE_FOUND, AX
	MOV	AX, FILE_DTA.DTA_FILE_SIZE_LOW
	MOV	ES:LOW_SIZE_FOUND, AX
	MOV	AX, FILE_DTA.DTA_FILE_SIZE_HIGH
	MOV	ES:HIGH_SIZE_FOUND, AX
	MOV	AL, BYTE PTR T_DRV
	MOV	ES:TARGET_DRV_LET, AL
	MOV	ES:TARGET_DRV_LET+1, DRV_DELIM
	MOV	CX, 13
	MOV	SI, OFFSET FILE_DTA.DTA_FILENAME
	MOV	DI, OFFSET ES:FILENAME_FOUND
	REP	MOVSB

; Get Extended Attribute list of the opened file and save in attribute buff.

	MOV	BX,S_HANDLE		;AN005; BX = handle
	MOV	SI,ALL_ATTR		;AN005; SELECT ALL ATTRIBUTES SIZE
	MOV	CL, PARAGRAPH		;AN005; PARAGRAPH = 4 FOR DIV BY 16
	MOV	AX,SIZ_OF_BUFF		;AN005; GET THE SIZE EXPRESSED IN para.
	SHL	AX, CL			;AN005; GET # OF BYTES FROM para.
	MOV	CX, AX			;AN005; NEEDS TO BE IN CX
	MOV	DI, OFFSET ES:ATTRIB_LIST ;AN005; ES:DI = E A LIST IN BUFFER
	MOV	AX, GET_ATTRIB		;AN005; extended attribute code 5702H
	INT	21H			;AN005; get extended attribute list

	JC	MH_ERROR		;AN000; jump if error

	MOV	AX, OLD_BUFFER_PTR
	MOV	ES:BEFORE_PTR, AX
	MOV	AX, ACT_BYTES
	MOV	ES:CX_BYTES, AX
	CALL	SET_BUFFER_PTR		;set buffer_ptr for next. AX is already set.
	MOV	AX, BUFFER_PTR
	MOV	ES:NEXT_PTR, AX 	;next buffer_ptr is next_ptr
	MOV	AL, S_DEPTH
	MOV	ES:DIR_DEPTH, AL	;same as source depth
	MOV	AL, FILE_DTA.DTA_ATTRIBUTE
	MOV	ES:ATTR_FOUND, AL	;attribute found
	JMP	MH_EXIT 		;AN000;
MH_ERROR:
	OR	COPY_STATUS, OPEN_ERROR_FLAG ;AN000;
	CALL	EXTENDED_ERROR_HANDLER	;AN000;
MH_EXIT:
	POP	AX
	POP	ES
	RET
MAKE_HEADER ENDP
;


OPEN_A_FILE PROC NEAR

;-------------------------------------------------------------------------
; Use extended open DOS call to open source file,
; if successfully open, then save filehand to S_HANDLE.
; And update the open file count.
;-------------------------------------------------------------------------

	LEA	SI,FILE_DTA.DTA_FILENAME ;AN005; DS:SI-->NAME TO OPEN
	MOV	DX,OPN_FLAG		;AN000; flag = 0101H
	MOV	CX,OPN_ATTR		;AN000; attribute = 0
	MOV	BX,OPN_MODE		;AN007; open mode = 0000H (READ)
	MOV	DI, NUL_LIST		;AN005; ES:DI = -1
	MOV	AX, Ext_Open		;AN000; = 6Ch
	INT	21H			;AN000; OPEN SOURCE FILE

	JC	OF_ERROR
	MOV	S_HANDLE, AX		;save filehandle
	INC	OPEN_FILE_COUNT 	;AN005;UPDATE THE OPEN FILE COUNTER

	JMP	OF_EXIT 		;AN000; exit

OF_ERROR:
	OR	COPY_STATUS, OPEN_ERROR_FLAG
	CALL	EXTENDED_ERROR_HANDLER
OF_EXIT:
	RET
OPEN_A_FILE ENDP
;


CMP_FILE_FFD0h PROC NEAR
;check whether the filesize in HIGH_FILE_SIZE, LOW_FILE_SIZE is bigger than
;0FFD0h.  If it is, then set FILE_BIGGER_FLAG, else reset it.
	CMP	HIGH_FILE_SIZE, 0
;	$IF	E,AND
	JNE $$IF47
	CMP	LOW_FILE_SIZE, 0FFD0h
;	$IF	BE
	JNBE $$IF47
	    AND     FILE_FLAG, RESET_FILE_BIGGER ;filesize <= 0FFD0h
;	$ELSE
	JMP SHORT $$EN47
$$IF47:
	    OR	    FILE_FLAG, FILE_BIGGER_FLAG
;	$ENDIF
$$EN47:
	RET
CMP_FILE_FFD0h ENDP
;

CALC_FILE_SIZE PROC NEAR
;subtract the bytes read (ACT_BYTES) from the filesize in HIGH_FILE_SIZE,
;LOW_FILE_SIZE.
	MOV	AX, ACT_BYTES
	SUB	LOW_FILE_SIZE, AX
	SBB	HIGH_FILE_SIZE, 0
	RET
CALC_FILE_SIZE ENDP
;


READ_A_FILE PROC NEAR
;read a file.
;if after reading, AX < CX or AX = 0 the set EOF_FLAG.
;INPUT:CX - # of bytes to read
;      BUFFER_PTR
;      S_HANDLE
;OUTPUT: ACT_BYTES

	PUSH	DS			;save program data seg
	MOV	AH, Read
	MOV	BX, S_HANDLE
	MOV	DX, BUFFER_PTR		;current buffer header seg
	ADD	DX, PARA_OF_HDR 	;AC005;skip the header part
	MOV	DS, DX			;now DS = buffer_ptr + HDR, data area
	XOR	DX, DX			;offset DX = 0
	INT	21H
	POP	DS			;restore program data area
	JC	RF_ERROR		;read error?
	CMP	AX, CX
	JE	RF_OK
	OR	FILE_FLAG, EOF_FLAG	;EOF reached. AX = 0 or AX < CX
RF_OK:
	CLC				;clear carry caused from CMP
	MOV	ACT_BYTES, AX		;save actual bytes read
	JMP	RF_EXIT
RF_ERROR:
	OR	COPY_STATUS, READ_ERROR_FLAG
	CALL	EXTENDED_ERROR_HANDLER
RF_EXIT:
	RET
READ_A_FILE ENDP
;


FIND_IT PROC	NEAR
;set first or next depending on FIND_FIRST_FLAG.
;once called, reset FIND_FIRST_FLAG.
	TEST	MY_FLAG, FIND_FIRST_FLAG
;	$IF	NZ			;yes
	JZ $$IF50
	    MOV     AH, Find_First
;	$ELSE
	JMP SHORT $$EN50
$$IF50:
	    MOV     AH, Find_Next
;	$ENDIF
$$EN50:
	AND	MY_FLAG, RESET_FIND_FIRST ;reset FIND_FIRST_FLAG
	INT	21H
	RET
FIND_IT ENDP
;


FIND_FILE PROC	NEAR
;find a file
;set NO_MORE_FILE if carry.
;	$SEARCH
$$DO53:
	    TEST    MY_FLAG, FIND_FIRST_FLAG ;find first ?
;	    $IF     NZ
	    JZ $$IF54
		MOV	DX, OFFSET S_FILE
		MOV	CX, File_Search_Attr ;normal = 0
;	    $ELSE
	    JMP SHORT $$EN54
$$IF54:
		MOV	DX, OFFSET FILE_DTA
;	    $ENDIF
$$EN54:
	    CALL    FIND_IT
;	$EXITIF C
	JNC $$IF53
	    OR	    MY_FLAG, NO_MORE_FILE ;no more file in this directory
;	$ORELSE
	JMP SHORT $$SR53
$$IF53:
	    MOV     FOUND_FILE_FLAG, 1	;set the flag for "File not found" msg.
	    CALL    FILTER_FILES	;found. filter it with options
	    TEST    MY_FLAG, FOUND_FLAG
;	$ENDLOOP NZ			;if found, leave this loop else start again
	JZ $$DO53
	    AND     MY_FLAG, RESET_NO_MORE
;	$ENDSRCH
$$SR53:
	RET
FIND_FILE ENDP
;
FIND_DIR PROC	NEAR
;find directory entry
;set NO_MORE_FLAG if carry.
;	$SEARCH
$$DO61:
	    TEST    MY_FLAG, FIND_FIRST_FLAG
;	    $IF     NZ
	    JZ $$IF62
		MOV	DX, OFFSET  S_DIR
		MOV	CX, DIR_SEARCH_ATTR
;	    $ELSE
	    JMP SHORT $$EN62
$$IF62:
		MOV	DX, BP
;	    $ENDIF
$$EN62:
	    CALL    FIND_IT
;	$EXITIF C			;no more file
	JNC $$IF61
	    OR	    MY_FLAG, NO_MORE_FILE ;set MY_FLAG and exit this loop
;	$ORELSE 			;otherwise found a file
	JMP SHORT $$SR61
$$IF61:
	    CMP     DS:[BP].DTA_ATTRIBUTE, Is_subdirectory ; directory?
;	    $IF     E,AND
	    JNE $$IF67
	    CMP     DS:[BP].DTA_FILENAME, A_dot ;starts with . ?
;	    $IF     NE			;if not, then desired subdir
	    JE $$IF67
		OR	MY_FLAG, FOUND_FLAG ;found
;	    $ELSE
	    JMP SHORT $$EN67
$$IF67:
		AND	MY_FLAG, RESET_FOUND
;	    $ENDIF
$$EN67:
	    TEST    MY_FLAG, FOUND_FLAG
;	$ENDLOOP NZ			;if found, leave this loop else start again
	JZ $$DO61
	    AND     MY_FLAG, RESET_NO_MORE ;found. set my_flag and exit
;	$ENDSRCH
$$SR61:
	RET
FIND_DIR ENDP
;


FILTER_FILES PROC NEAR
;FILE_DTA.XXX HAS INFORMATIONS
;this routine also show the prompt of source path, filename, if SLASH_P is on.

	TEST	OPTION_FLAG, SLASH_A	;soft archieve?
	JNZ	SLASH_AM_RTN		;yes
	TEST	OPTION_FLAG, SLASH_M	;then hard archieve?
	JNZ	SLASH_AM_RTN		;yes
FF_D:
	TEST	OPTION_FLAG, SLASH_D	;date?
	JNZ	SLASH_D_RTN
FF_P:
	TEST	OPTION_FLAG, SLASH_P	;prompt mode? ** this should be placed last.
	JNZ	SLASH_P_RTN
	JMP	SHORT FF_FOUND		;no more selective options. copy this file.
SLASH_AM_RTN:				;soft or hard archieve.
	CALL	CHK_ARCHIEVE_BIT
	JC	FF_NOT_FOUND
	JMP	SHORT FF_D		;check other options
SLASH_D_RTN:
	CALL	CHK_DATE_FILE		;check file's date
	JC	FF_NOT_FOUND
	JMP	SHORT FF_P
slash_p_rtn:
	call	prompt_path_file	;show message and get input from the user
	jc	ff_not_found		;user does not want this file
FF_FOUND:
	OR	MY_FLAG, FOUND_FLAG	;set found_flag
	JMP	SHORT FF_EXIT
FF_NOT_FOUND:
	AND	MY_FLAG, RESET_FOUND	;this file is not what we want to copy
FF_EXIT:
	RET
FILTER_FILES ENDP
;
CHK_ARCHIEVE_BIT PROC NEAR
;check the current FILE.DTA area and if archieve bit is on, found.
	TEST	FILE_DTA.DTA_ATTRIBUTE, 20h ;archieve on?
;	$IF	NZ			;yes
	JZ $$IF72
	    CLC 			;clear carry
;	$ELSE
	JMP SHORT $$EN72
$$IF72:
	    STC 			;archieve bit is off. Don't
;	$ENDIF				;have to copy this file
$$EN72:
	RET
CHK_ARCHIEVE_BIT ENDP
;
CHK_DATE_FILE PROC NEAR
;
	MOV	CX, FILE_DTA.DTA_FILE_DATE
	CMP	CX, INPUT_DATE		;FILE_DATE < INPUT_DATE
;	$IF	B
	JNB $$IF75
	    STC 			;not found
;	$ELSE
	JMP SHORT $$EN75
$$IF75:
	    CLC 			;found desired file
;	$ENDIF
$$EN75:
	RET
CHK_DATE_FILE ENDP
;


PROMPT_PATH_FILE PROC NEAR

;show the current source path, filename found, and get the user input.
;if it is yes, then reset carry, no, set carry otherwise show
;the whole message again.
;DS, ES - data seg

	MOV	CX, 13			;13 max
	LEA	SI, FILE_DTA.DTA_FILENAME
	MOV	DI, OFFSET DISP_S_FILE
	REP	MOVSB			;filename => disp_s_file
PPF_AGAIN:
	LEA	SI,SUBLIST1		;AN000; get addressability to sublist
	LEA	DX,DISP_S_PATH		;AN000; offset to PATH NAME
	MOV	[SI].DATA_OFF,DX	;AN000; save offset
	MOV	[SI].DATA_SEG,DS	;AN000; save data segment
	MOV	[SI].MSG_ID,1		;AN000; message ID
	MOV	[SI].FLAGS,010H 	;AN000; ASCIIZ string, left align
	MOV	[SI].MAX_WIDTH,0	;AN000; MAXIMUM FIELD WITH
	MOV	[SI].MIN_WIDTH,0	;AN000; MINIMUM FIELD WITH

	LEA	SI,SUBLIST2		;AN000; get addressability to sublist
	LEA	DX,DISP_S_FILE		;AN000; offset to FILE NAME
	MOV	[SI].DATA_OFF,DX	;AN000; save offset
	MOV	[SI].DATA_SEG,DS	;AN000; save data segment
	MOV	[SI].MSG_ID,2		;AN000; message ID
	MOV	[SI].FLAGS,010H 	;AN000; ASCIIZ string, left align
	MOV	[SI].MAX_WIDTH,0	;AN000; MAXIMUM FIELD WITH
	MOV	[SI].MIN_WIDTH,0	;AN000; MINIMUM FIELD WITH
	LEA	SI,SUBLIST1		;AN000;

	CMP	S_DEPTH,0		;now dealing with starting dir?
	JE	PATH_FILE_QUERY 	;ask (Y/N)
	JMP	PPF_1

PATH_FILE_QUERY:

	MOV	AX,P_S_PATH_FILE0	;no back slash, since it is already there
	JMP	PPF_PRT 		;AN000;

PPF_1:

	MOV	AX,P_S_PATH_FILE1	; Path and file name with
					; back slash delemeter
PPF_PRT:
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,PARM_SUBST_TWO ;AN000; substitution count
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,DOS_KEYB_INP ;AN000; Y or N INPUT
	CALL	PRINT_STDOUT		;AN000; Display message
	PUSH	AX			;AN000; SAVE IT

	MOV	AX,MSG_CR_LF_STR	;AN000; JUST CR,LF
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,NO_SUBST	;AN000; substitution count = 0
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,NO_INPUT	;AN000; NO INPUT
	CALL	PRINT_STDOUT		;AN000; Display message

	POP	AX			;AN000; GET IT BACK
; On return from prompt msg, AX contains Y or N response character
	MOV	DL,AL			;AN000;
	MOV	AH,65H			;AN000;
	MOV	AL,023H 		;AN000; Y/N check function
	INT	21H			;AN000; Issue Extended country to
					;	 capitalize  the Y/N response
	JC	PPF_RETRY		;AN000; NOT Y OR N, ASK AGAIN
	CMP	AX,1			;AN000; look for Y
	JG	PPF_RETRY		;AN000; NOT Y OR N, ASK AGAIN

	CMP	AX,0			;AN000; look for N
	JE	PPF_NO			;AN000;
PPF_YES:
	CLC				;AN000;CLEAR CARRY
	JMP	SHORT PPF_EXIT
PPF_RETRY:
	JMP	PPF_AGAIN		;AN000;ASK AGAIN
PPF_NO:
	STC				;AN000;set carry
PPF_EXIT:
	RET
PROMPT_PATH_FILE ENDP
;



SET_MY_DTA PROC NEAR
;set DS:DX for find_first(next). If MY_FLAG is set to FINDFILE_FLAG then
;set it to the offset FILE_DTA, otherwise to BP.
;DS should be set to the area whre FILE_DTA, DTAS are.
	PUSH	DX			;save current DX
	TEST	MY_FLAG, FINDFILE_FLAG	;handling file?
;	$IF	NZ
	JZ $$IF78
	    MOV     DX, OFFSET FILE_DTA
;	$ELSE
	JMP SHORT $$EN78
$$IF78:
	    MOV     DX, BP
;	$ENDIF
$$EN78:
	MOV	AH, Set_DTA
	INT	21H
	POP	DX
	RET
SET_MY_DTA ENDP
;

CHANGE_S_DIR PROC NEAR
;change source directory
;DS points to program data seg.

	CMP	S_DRV[2], 0		;LAST_DIR_OUT have took '\' out?
;	$IF	E
	JNE $$IF81
	    MOV     S_DRV[2], '\'	;then restore '\' for root dir
	    MOV     S_DRV[3], 0
;	$ENDIF
$$IF81:

	TEST	SYS_FLAG, ONE_DISK_COPY_FLAG ;one drive letter copy?
;	$IF	NZ,OR			;yes
	JNZ $$LL83
	TEST	OPTION_FLAG, SLASH_M	;hard archive option? (should use full path
;	$IF	NZ			; since hard archieve operation will corrupt the current directory)
	JZ $$IF83
$$LL83:
	    MOV     DX, OFFSET S_DRV_PATH ;always use full path
;	$ELSE
	JMP SHORT $$EN83
$$IF83:
	    TEST    MY_FLAG, VISIT_PARENT_FLAG ;now going toward the root?
;	    $IF     NZ			;yes
	    JZ $$IF85
		MOV	DX, OFFSET S_PARENT ;just '..',0
;	    $ELSE
	    JMP SHORT $$EN85
$$IF85:
		LEA	DX, [BP].DTA_FILENAME ;use the subdir name just found
;	    $ENDIF
$$EN85:
;	$ENDIF
$$EN83:
	MOV	AH, Chdir		; = 3Bh
	INT	21H
;	$IF	C
	JNC $$IF89
	    OR	    COPY_STATUS, CHDIR_ERROR_FLAG ;chdir error in source. critical
	    CALL    EXTENDED_ERROR_HANDLER
;	$ENDIF
$$IF89:

	RET
CHANGE_S_DIR ENDP
;

CHANGE_T_DIR PROC NEAR
;change target dir according to t_drv_path.
;Since this routine is called by WRITE_FROM_BUFFER and DS now points
;to buffer area while ES points to the program data area, we set DS
;to data seg again here for the function call Chdir.
	PUSH	DS			;save current buffer seg
	PUSH	ES			;currentpy es is a data seg
	POP	DS			;restore DS value as program data seg

	CMP	T_DRV[2], 0		;LAST_DIR_OUT took '\' out?
;	$IF	E
	JNE $$IF91
	    MOV     T_DRV[2], '\'	;then put it back for root dir
	    MOV     T_DRV[3], 0
;	$ENDIF
$$IF91:

	MOV	DX, OFFSET T_DRV_PATH
	MOV	AH, CHDIR
	INT	21H

	POP	DS			;restore caller's DS value
	RET
CHANGE_T_DIR ENDP
;

CMP_FILESIZE_TO_BUFFER_LEFT PROC NEAR
;Compare buffer_left (paragraph) with filesize (high_file_size, low_file_size.)
;if filesize is bigger than buffer_left, then set FILE_BIGGER_FLAG
;indicating filesize > buffer_left.
;
	PUSH	DX
	PUSH	AX

	CMP	OPEN_FILE_COUNT,NUL	;AN005;ARE THERE ANY OPEN FILES
;	$IF	Z			;AN005;NO, THEN GO AHEAD AND OPEN
	JNZ $$IF93
	    CALL    OPEN_A_FILE 	;AN005;OPEN A FILE USING FILE_DTA

; Get extended Attribute list size.

	    MOV     BX,S_HANDLE 	;AN005; BX = handle
	    MOV     AX, GET_ATTRIB	;AN005; extended attribute code 5702H
	    MOV     SI,ALL_ATTR 	;AN005; SELECT ALL ATTRIBUTES SIZE
	    XOR     CX,CX		;AN005; JUST QUERY SIZE NEEDED
	    MOV     DI,NUL_LIST 	;AN005; DI = LIST FOR NO DATA RETURNED
	    INT     21H 		;AN005; get extended attribute SIZE
	    ADD     CX,PARA_BOUND	;AN005; TO FIGURE THE NEXT PARAGRAPH
	    MOV     AX,CX		;AN005;
	    MOV     CL,PARAGRAPH	;AN005; GET PARAGRAPHS (DIV BY 16)
	    SHR     AX,CL		;AN005;
	    MOV     SIZ_OF_BUFF,AX	;AN005;SAVE BUFF SIZE FOR THE HEADER
	    ADD     AX,FIXD_HD_SIZ	;AN005;GET THE TOTAL HEADER SIZE
	    MOV     PARA_OF_HDR,AX	;AN005;SAVE FOR LATER
	    SHL     AX, CL		;AN005;CONVERT BACK TO TOTAL BYTES
	    MOV     BYTS_OF_HDR,AX	;AN005;SAVE FOR LATER
;	$ENDIF				;AN005;
$$IF93:

	AND	FILE_FLAG, RESET_FILE_BIGGER
	MOV	AX,PARA_OF_HDR		;AN005;GET THE HEADER SIZE (para.)
	CMP	BUFFER_LEFT,AX		;AC005;buffer_left >= HEADER SIZE
;	$IF	AE
	JNAE $$IF95
	    MOV     AX, BUFFER_LEFT	;buffer_left in para
	    SUB     AX,PARA_OF_HDR	;AC005;consider header size in advance
	    MOV     CX, 16
	    MUL     CX			;* 16. result in DX;AX
	    CMP     HIGH_FILE_SIZE, DX
;	    $IF     A			;if high_filesize > dx
	    JNA $$IF96
		OR	FILE_FLAG, FILE_BIGGER_FLAG
;	    $ELSE
	    JMP SHORT $$EN96
$$IF96:
;		$IF	E
		JNE $$IF98
		    CMP     LOW_FILE_SIZE, AX
;		    $IF     A
		    JNA $$IF99
			OR	FILE_FLAG, FILE_BIGGER_FLAG
;		    $ENDIF
$$IF99:
;		$ENDIF
$$IF98:
;	    $ENDIF
$$EN96:
;	$ELSE
	JMP SHORT $$EN95
$$IF95:
	    OR	    FILE_FLAG, FILE_BIGGER_FLAG ;buffer_left < HEADER SIZE
;	$ENDIF
$$EN95:

	POP	AX
	POP	DX
	RET
CMP_FILESIZE_TO_BUFFER_LEFT ENDP
;

SET_BUFFER_PTR PROC NEAR
;set BUFFER_PTR, BUFFER_LEFT, OLD_BUFFER_PTR in paragraph boundary
;to be used when reading a file into buffer.
;this routine uses current BUFFER_PTR to figure out the next BUFFER_PTR.
;So, at initialization time set BUFFER_PTR to CS, and set AX to the offset
;of INIT,  then the resultant BUFFER_PTR indicates the BUFFER_BASE and
;OLD_BUFFER_PTR indicates CS.(This means if old_buffer_ptr = cs, then
;it is the start of buffer)
;To get the next BUFFER_PTR during multi-copy, just set the AX to the
;number of bytes read. This routine will add E.A.BUFFER SIZE + 3 para.
;for header size and will set the next BUFFER_PTR.
;input: AX - offset of buffer
;	Top_of_memory	in segment
;	current BUFFER_PTR
;	current OLD_BUFFER_PTR
;	current BUFFER_LEFT
;output: BUFFER_PTR	for next reading
;	 OLD_BUFFER_PTR
;	 BUFFER_LEFT (Top_of_memory - Buffer_Ptr. If it is 0, then indicates
;		      the BUFFER is FULL.  In this case, the BUFFER_PTR is
;		      invalid, but OLD_BUFFER_PTR keep the former buffer_ptr
;		      value which says that it is the last header in the buffer)
;** Currently this program support maxium top of memory in seg 0FFFF - resident
;   area.  This routine will check the overflow case to gaurd the next buffer_ptr
;   not to exceed FFFF.

	PUSH	CX
	MOV	CX, BUFFER_PTR
	MOV	OLD_BUFFER_PTR, CX	;set old_buffer_ptr
	MOV	CL, 4
	SHR	AX, CL			;get paragraphs
	INC	AX			;get next paragraph
	ADD	AX,PARA_OF_HDR		;AC005;consider header size
	ADD	BUFFER_PTR, AX		;add this to the current buffer_ptr

;	$IF	NC,AND			;not exceed 16 bit.
	JC $$IF105
	MOV	AX, Top_of_memory
	SUB	AX, BUFFER_PTR		;AX = Top_of_memory - Buffer_ptr
;	$IF	A			;if buffer_left > 0
	JNA $$IF105
	    MOV     BUFFER_LEFT, AX
;	$ELSE
	JMP SHORT $$EN105
$$IF105:
	    MOV     BUFFER_LEFT, 0	;indication of buffer full
;	$ENDIF
$$EN105:
	POP	CX
	RET
SET_BUFFER_PTR ENDP
;

WRITE_FROM_BUFFER PROC NEAR
;Write from the first header starting at buffer_base until finishes
;the last header which, actually, happens to be the old_buffer_ptr
;at the time of the call.  After the writing, reset the buffer_ptr
;to buffer_base again for the next read_into_buffer.
;If continue_info is 1 or 2 (Continue of small, bigfile) then after
;the creation of a target file, it will set the CREATED_FLAG.
;This flag will be reset when it found the continue_info to be 3
;(End of contine).
;For convenience of use of function call, ES will be used for
;the program data seg while DS will be used for the BUFFER seg.
;
	PUSH	DS
	PUSH	ES			;save ds, es

	PUSH	DS
	POP	ES			;set ES to program data seg

	OR	ACTION_FLAG, READING_FLAG ;show reading message next time
;	AND	ES:MY_FLAG, RESET_IS_SOURCE	;now, deals with target
					;set this for change_dir
	MOV	AX, ES:BUFFER_BASE
	MOV	DS, AX
	PUSH	CS
	POP	AX
	CMP	ES:OLD_BUFFER_PTR, AX	;if old_buffer_ptr = CS then
					;buffer is empty. Just exit
	JE	WFB_EXIT_BRIDGE
WFB_CD:
	CALL	CHANGE_T_DIR
	JC	WFB_ERROR_BRIDGE	;error?
WFB_CHATT:
	CMP	DS:ATTR_FOUND, Is_subdirectory ;a subdirectory? = 10H
	JNE	WFB_FILE		;no. a file
WFB_CMP_DEPTH:
	MOV	AH, ES:T_DEPTH		;yes. a subdir.
	CMP	DS:DIR_DEPTH, AH	;DIR_DEPTH > T_DEPTH ?
	JBE	WFB_DEC_DEPTH		;if not, go to parent node
	LEA	DI, ES:T_DRV_PATH	;else goto child node
	LEA	SI, DS:FILENAME_FOUND
	CMP	ES:T_PATH, 0		;root directory?
;	$IF	E
	JNE $$IF108
	    MOV     AL, 0FFh		;then don't need to put delim since it is already there
;	$ELSE
	JMP SHORT $$EN108
$$IF108:
	    MOV     AL, Path_delim	;path_delim '\'
;	$ENDIF
$$EN108:
	CALL	CONCAT_ASCIIZ
	call	concat_display_path	;modify the path for display
	INC	ES:T_DEPTH
	CALL	MAKE_DIR		;try to make a new sub directory
	JC	WFB_EXIT_A_BRIDGE	;there exists a file with same name.
	MOV	AX, DS			;current buffer seg = old_buffer_ptr?
	CMP	ES:OLD_BUFFER_PTR, AX
	JNE	WFB_NEXT		;not finished yet. jmp to next
	OR	ES:MY_FLAG, MISSING_LINK_FLAG ;Finished. Missing link condition occurred regarding empty sub dir
	JMP	WFB_EXIT_A		;check archieve options.
WFB_NEXT:
	MOV	DS, DS:NEXT_PTR 	;let's handles next header.
	JMP	WFB_CD			;change directory first.
WFB_EXIT_BRIDGE: JMP WFB_EXIT
WFB_ERROR_BRIDGE: JMP WFB_ERROR
WFB_EXIT_A_BRIDGE: JMP WFB_EXIT_A
WFB_DEC_DEPTH:
	LEA	DI, ES:T_DRV_PATH
	CALL	RM_EMPTY_DIR		;check flags and remove empty dir
	CALL	LAST_DIR_OUT		;take off the last dir from path
	call	cut_display_path	;modify path for display purpose
	DEC	ES:T_DEPTH		;and decrease depth
	JMP	WFB_CD			;CHANGE DIR AND compare the depth again.

WFB_FILE:				;Handling a file
	AND	ES:MY_FLAG, RESET_MISSING_LINK ;if found a file, then current dir is not empty.
	TEST	ES:FILE_FLAG, CREATED_FLAG ; A file handle is created ?
	JNZ	WFB_WRITE		;yes, skip create again.
	CALL	CREATE_A_FILE		;create a file in the cur dir
	JC	WFB_ERROR		;file creation error?
WFB_WRITE:
	CALL	WRITE_A_FILE
	JC	WFB_EXIT_A		;target file has been already deleted.
	CMP	DS:CONTINUE_INFO, 0
;	$IF	E,OR			;if continue_info = 0 or 3
	JE $$LL111
	CMP	DS:CONTINUE_INFO, 3
;	$IF	E
	JNE $$IF111
$$LL111:
	    MOV     BX, ES:T_HANDLE
	    CALL    SET_FILE_DATE_TIME	;then set file's date, time
	    PUSH    DS			;AN005;SAVE THE BUFFER PTR
	    PUSH    ES			;AN005;WE NEED THE DATA PTR
	    POP     DS			;AN005;DS = THE DATA PTR
	    CALL    CLOSE_A_FILE	;and close the handle
	    POP     DS			;AN005;DS = THE BUFFER PTR AGAIN
	    CALL    RESTORE_FILENAME_FOUND ;if filename_found has been changed, restore it for reset_s_archieve.
	    AND     ES:FILE_FLAG, RESET_CREATED ;and reset created_flag
	    CALL    INC_FILE_COUNT	;increase file count
;	$ENDIF
$$IF111:
	MOV	AX, DS
	CMP	ES:OLD_BUFFER_PTR, AX	;current header is the last one?
	JE	WFB_EXIT_A		;then exit
	MOV	DS, DS:NEXT_PTR 	;else set ds to the next ptr
	JMP	WFB_CHATT		;handle the next header
WFB_ERROR:
	jmp	main_exit		;meaningful when MKDIR failed because
					;of there already exist same named file,
					;or disk_full case.
WFB_EXIT_A:
	test	ES:option_flag, slash_m ;hard archieve ? - turn off source archieve bit.
	jz	wfb_exit_B		;no, chk error flag and exit
	call	reset_s_archieve	;reset source file(s) archieve bit using header info(s).
WFB_EXIT_B:
	test	ES:copy_status, mkdir_error_flag ;mkdir error happened?
	JNZ	WFB_ERROR		;yes, exit
	test	ES:copy_status, disk_full_flag ;disk full happened?
	JNZ	WFB_ERROR		;yes, exit
WFB_EXIT:
	MOV	ES:OLD_BUFFER_PTR, CS	;set old_buffer_ptr to CS
	MOV	AX, ES:BUFFER_BASE
	MOV	ES:BUFFER_PTR, AX	;set buffer_ptr to base
	MOV	AX, ES:MAX_BUFFER_SIZE
	MOV	ES:BUFFER_LEFT, AX	;set buffer_left
	POP	ES
	POP	DS
	TEST	SYS_FLAG, ONE_DISK_COPY_FLAG ;one drive letter copy?
;	$IF	NZ			;yes
	JZ $$IF113
	    CALL    CHANGE_S_DIR	;then change current dir to s dir
;	$ENDIF
$$IF113:
	RET
WRITE_FROM_BUFFER ENDP
;
INC_FILE_COUNT PROC NEAR
;increase the file count by one.
;increase file_cnt_low, file_cnt_high.
;input: DS - buffer
;	ES - data seg
	INC	ES:FILE_CNT_LOW
	JNZ	IFC_EXIT
	INC	ES:FILE_CNT_HIGH	;if carry over, then inc file_cnt_high
IFC_EXIT:
	RET
INC_FILE_COUNT ENDP
;
RM_EMPTY_DIR PROC NEAR
;check the slash_E option, missing_link_flag.  Remove the empty directory
;from the target disk.
;INPUT: DS - buffer
;	ES - data seg
;	DI - points to the current target drv, path

	TEST	ES:OPTION_FLAG, SLASH_E ;user want to copy empty subdir?
	JNZ	RED_EXIT		;then exit
	TEST	ES:MY_FLAG, MISSING_LINK_FLAG ;missing informations for not to copying empty dir
					;at the tree travesal phase?
	JZ	RED_EXIT		;no.
	CALL	SWITCH_DS_ES		;ds - data, es - buffer
	MOV	DX, OFFSET T_PARENT	;chdir to parent dir
	MOV	AH, 3Bh 		;Chdir
	INT	21h
	PUSH	DI
	POP	DX			;DS:DX points to drv, path
	MOV	AH, 3Ah 		;REMOVE SUBDIR
	INT	21h
	CALL	SWITCH_DS_ES		;restore ds, es
RED_EXIT:
	RET
RM_EMPTY_DIR ENDP
;
RESTORE_FILENAME_FOUND PROC NEAR
;when the filename_found has been Revised according to the user's specified
;input parm, then restore the original source filename in filename_found.
;This will be used when reset_s_archieve routine reset the source file's
;archieve bit.
;input: DS - buffer
;	ES - data seg

	CMP	ES:T_FILENAME, 0	;if t_filename ot t_template is not blank,
;	$IF	NE,OR			;then filename_found has been Revised.
	JNE $$LL115
	CMP	ES:T_TEMPLATE, 0
;	$IF	NE
	JE $$IF115
$$LL115:
	    CALL    SWITCH_DS_ES	;DS - data seg, ES - buffer
	    MOV     CX, 13
	    LEA     SI, DS:DISP_S_FILE	;we know filename_found has been save into DISP_S_FILE when create the file.
	    LEA     DI, ES:FILENAME_FOUND ;use this to restore source filename this time.
	    REP     MOVSB		;disp_s_file => filename_found
	    CALL    SWITCH_DS_ES	;restore ds, es
;	$ENDIF
$$IF115:
	RET
RESTORE_FILENAME_FOUND ENDP
;
RESET_S_ARCHIEVE PROC NEAR
;INPUT: DS - buffer
;	ES - data seg

	TEST	ES:COPY_STATUS, DISK_FULL_FLAG ;called when disk full?
	JZ	RSA_START		;no, just goto start
					;else disk_full.
	MOV	AX, DS			;current DS when called
	CMP	ES:BUFFER_BASE, AX	;current DS(BUFFER) is the first one?
	JE	RSA_EXIT_BRIDGE 	;yes, just exit
	MOV	AX, DS:BEFORE_PTR	;set old_buffer_ptr to the header
	MOV	ES:OLD_BUFFER_PTR, AX	;that is just before the troubled one.
RSA_START:
	MOV	AX, ES:BUFFER_BASE
	MOV	DS, AX			;set DS to buffer base again to start traveling
RSA_CD:
	CALL	CHANGE_ARC_S_DIR	;change souce dir
RSA_CHATT:
	CMP	DS:ATTR_FOUND, Is_subdirectory ; = 10h
	JNE	RSA_FILE		;no a file
RSA_CMP_DEPTH:
	MOV	AH, ES:S_ARC_DEPTH	;yes, a subdir
	CMP	DS:DIR_DEPTH, AH	;dir_depth > s_arc_depth?
	JBE	RSA_DEC_DEPTH		;if not, goto parent node
	LEA	DI, ES:S_ARC_DRV_PATH
	LEA	SI, DS:FILENAME_FOUND
	CMP	ES:S_ARC_PATH, 0	;root dir?
;	$IF	E
	JNE $$IF117
	    MOV     AL, 0FFh
;	$ELSE
	JMP SHORT $$EN117
$$IF117:
	    MOV     AL, Path_delim	;path_delim '\'
;	$ENDIF
$$EN117:
	CALL	CONCAT_ASCIIZ
	INC	ES:S_ARC_DEPTH
	MOV	AX, DS
	CMP	ES:OLD_BUFFER_PTR, AX
	JE	RSA_EXIT_A		;finished. Set the source current dir and return to caller
	MOV	DS, DS:NEXT_PTR 	;else let's handles next header
	JMP	RSA_CD			;chdir first.
RSA_EXIT_A:
	CALL	CHANGE_ARC_S_DIR	;to restore the same current source dir
					;as that of the READ_INTO_BUFFER proc.
RSA_EXIT_BRIDGE:JMP RSA_EXIT
RSA_DEC_DEPTH:
	LEA	DI, ES:S_ARC_DRV_PATH
	CALL	LAST_DIR_OUT
	DEC	ES:S_ARC_DEPTH
	JMP	RSA_CD
RSA_FILE:
	CMP	DS:CONTINUE_INFO, 0
;	$IF	E,OR
	JE $$LL120
	CMP	DS:CONTINUE_INFO, 3
;	$IF	E
	JNE $$IF120
$$LL120:
	    CALL    CHANGE_S_FILEMODE	;change source file mode
;	$ENDIF
$$IF120:
	MOV	AX, DS
	CMP	ES:OLD_BUFFER_PTR, AX	;current header is the last one?
	JE	RSA_EXIT
	MOV	DS, DS:NEXT_PTR
	JMP	RSA_CHATT
RSA_EXIT:
	OR	ES:SYS_FLAG, DEFAULT_S_DIR_fLAG ;this is for restoring default source dir before exit to DOS.
	RET				;return to caller
RESET_S_ARCHIEVE ENDP
;
CHANGE_S_FILEMODE PROC NEAR
;input: DS - buffer
;	ES - data seg

	LEA	DX, DS:FILENAME_FOUND
	MOV	AH, 43h 		;chmod
	MOV	AL, 0			;get attribute in CX
	INT	21h
	MOV	AH, 43h
	MOV	AL, 1
	AND	CX, 0FFDFh		;turn off the archieve bit
	INT	21h
	RET
CHANGE_S_FILEMODE ENDP
;
CHANGE_ARC_S_DIR PROC NEAR
;change the source directory according to S_ARC_DRV_PATH
;INPUT: DS - buffer
;	ES - data seg
	call	switch_ds_es
	CMP	S_ARC_DRV[2], 0
;	$IF	E
	JNE $$IF122
	    MOV     S_ARC_DRV[2], '\'	;LAST_DIR_OUT have took '\' out?
	    MOV     S_ARC_DRV[3],0	;then restore it
;	$ENDIF
$$IF122:
	MOV	DX, OFFSET S_ARC_DRV_PATH ;use full drv, path
	MOV	AH, CHDIR		; = 3Bh
	INT	21h
;	$IF	C
	JNC $$IF124
	    OR	    COPY_STATUS, CHDIR_ERROR_FLAG
	    CALL    EXTENDED_ERROR_HANDLER
;	$ENDIF
$$IF124:
	call	switch_ds_es
	RET
CHANGE_ARC_S_DIR ENDP

;
CONCAT_DISPLAY_PATH PROC NEAR
;concatenate subdirectory name found from the header to DISP_S_PATH which
;will be used for display copying file messages.
;if slash_p option has been set, then just return.
;DS: buffer header
;ES: data seg
;
	TEST	ES:OPTION_FLAG, SLASH_P ;prompt option?
;	$IF	Z			;no
	JNZ $$IF126
	    LEA     DI, ES:DISP_S_PATH
	    LEA     SI, DS:FILENAME_FOUND
	    CMP     ES:T_DEPTH, 0	;this will be the first child directory?
;	    $IF     E			;yes
	    JNE $$IF127
		MOV	AL, 0FFh	;then do not put '\' between them
;	    $ELSE
	    JMP SHORT $$EN127
$$IF127:
		MOV	AL, Path_delim	;else put '\'
;	    $ENDIF
$$EN127:
	    CALL    CONCAT_ASCIIZ
;	$ENDIF				;else just return
$$IF126:
	RET
CONCAT_DISPLAY_PATH ENDP
;
CUT_DISPLAY_PATH PROC NEAR
;take the last dir out from the DISP_S_PATH for display copy messages.
;if prompt option has been set, just return.
;INPUT: DS - buffer header
;	ES - data seg
;

	TEST	ES:OPTION_FLAG, SLASH_P ;prompt?
;	$IF	Z			;no.
	JNZ $$IF131
	    PUSH    DS			;save DS
	    PUSH    ES
	    POP     DS			;ds = es = data seg
	    MOV     SI, OFFSET DISP_S_PATH ;for CHK_DRV_LETTER
	    MOV     DI, OFFSET DISP_S_PATH ;for LASR_DIR_OUT

	    CALL    LAST_DIR_OUT
;	    $IF     C			;failure? no '\' found
	    JNC $$IF132
		CALL	CHK_DRV_LETTER	;drive letter?
;		$IF	NC		;yes. "D:filename",0 case
		JC $$IF133
		    MOV     BYTE PTR DS:[SI], 0 ;make it "D:",0 since SI now points to the next chr
;		$ELSE			;no. "filename",0 case
		JMP SHORT $$EN133
$$IF133:
		    MOV     BYTE PTR [DI], 0 ;set DISP_S_PATH to 0
;		$ENDIF
$$EN133:
;	    $ELSE			;found '\' and last '\' became 0
	    JMP SHORT $$EN132
$$IF132:
		CMP	T_DEPTH, 1	;now going to the starting path?
;		$IF	E		;yes. restore it for concat_display_path routine.
		JNE $$IF137
		    MOV     DI, AX	;we want to restore '\' and put 0 just after that.
		    DEC     DI		;for ex, "D:\DIR1"=>"D:"=>"D:\" -- original starting path
		    MOV     BYTE PTR [DI], '\' ; "D:dir1\dir2"=>"D:dir1"(starting path) => "D:dir1\"
		    MOV     BYTE PTR [DI+1], 0
;		$ENDIF
$$IF137:
;	    $ENDIF
$$EN132:
	    POP     DS			;restore ds to buffer header
;	$ENDIF
$$IF131:
	RET
CUT_DISPLAY_PATH ENDP
;


;***************************************************************************
CHK_DRV_LETTER PROC NEAR
; ** CHECK CURRENT CHR IS ALPHA CHR FOLLOWED BY COLON.			   *
; INPUT: DS:SI POINTS TO THE CURRENT CHR TO BE CHECKED. 		   *
; OUTPUT: FOUND - SI POINTS TO THE NEXT CHR.				   *
;		  IF THIS HAD BEEN A LAST WORD, ZERO FLAG WILL BE SET.	   *
;	  NOT FOUND - CARRY IS SET. DI, CX UNCHANGED.			   *
;***************************************************************************

	PUSH	AX
	PUSH	SI			;AN010;IN CASE DRIVE LETTER NOT FOUND
;	$DO				;AN010;
$$DO141:
	    CLC 			;AN010;INITIALIZE TO NOT DBCS
	    MOV     AL,DS:BYTE PTR [SI] ;AN010;GET THE 1st CHAR TO TEST
	    CALL    CHK_DBCS		;AN010;SEE IF WE ARE IN DBCS
;	$LEAVE	NC			;AN010;THIS IS NOT DBCS
	JNC $$EN141
	    INC     SI			;AN010;GO TO THE NEXT CHAR TO CHECK
	    INC     SI			;AN010;DITO
;	$ENDDO				;AN010;
	JMP SHORT $$DO141
$$EN141:
	CMP	AL, 'A'
	JB	CK_DR_1 		;LESS THAN 'A', THEN NOT FOUND.
	CMP	AL, 'Z'
	JA	CK_DR_1 		;ABOVE 'Z', THEN NOT FOUND.
	MOV	AL, DS:BYTE PTR [SI+1]	;LOOK AHEAD THE FOLLOWING CHR.
	CMP	AL, ':' 		;SHOULD BE A COLON.
	JNZ	CK_DR_1 		;NOT FOUND.
	POP	AX			;AN010;THROW AWAY SAVED SI
	INC	SI			;FOUND. SI TO THE NEXT CHR.
	INC	SI
	JMP	CK_DR_2
CK_DR_1:
	STC				;SET CARRY
	POP	SI			;AN010;RESTORE SI TO ENTRY VALUE
CK_DR_2:
	POP	AX
	RET
CHK_DRV_LETTER ENDP
;


CREATE_A_FILE PROC NEAR
;create a file in the header and return the file handle in T_HANDLE.
;Set CREATED_FLAG.  This will be reset by WRITE_FROM_BUFFER when it
;close the handle.
;this routine will check the T_FILENAME and T_TEMPLATE if any target
;filename has been entered.  If T_FILENAME is there, then DX will
;points to this (This is the case when the user has specified non_global
;chr filename and any source filename be changed to this name.)
;If T_TEMPLATE is present, then modify the filename found in the
;header part.
;Also, this routine show copy messages just before a file creation using
;FILENAME_FOUND.
;ES - data seg
;DS - buffer seg

	PUSH	DS
	PUSH	ES

					;save the original filename from the header
	MOV	CX, 13			;max 13 chr
	LEA	SI, DS:FILENAME_FOUND	;original source file name
	LEA	DI, ES:DISP_S_FILE	;filename to be displayed
	REP	MOVSB			;filename_found => disp_s_file
	test	es:option_flag, slash_p
;	$IF	Z
	JNZ $$IF144
	    CALL    SHOW_COPY_MESSAGE	;show the source path, file
;	$ENDIF
$$IF144:

	CMP	ES:T_FILENAME, 0
;	$IF	NE			;non_global target filename entered.
	JE $$IF146
	    TEST    ES:COPY_STATUS, MAYBE_ITSELF_FLAG
;	    $IF     NZ
	    JZ $$IF147
		LEA	SI, DS:FILENAME_FOUND
		LEA	DI, ES:T_FILENAME
		CALL	COMP_FILENAME	;compare it. if same then show
					;file cannot be copied onto itself and
					;abort
;	    $ENDIF
$$IF147:

	    CALL    SWITCH_DS_ES	;now ds - data, es - buffer
	    MOV     CX, 13
	    LEA     SI, DS:T_FILENAME
	    LEA     DI, ES:FILENAME_FOUND
	    REP     MOVSB		; t_filename => filename_found
	    MOV     AL, NUL		;AN014;DOS NEEDS A NUL TO TERM.
	    MOV     ES:TERMINATE_STRING,AL ;AN014;PUT IT IN THE HEADER
	    CALL    SWITCH_DS_ES	;now ds - buffer, es - data seg

;	$ELSE
	JMP SHORT $$EN146
$$IF146:
	    CMP     ES:T_TEMPLATE, 0	;global chr target filename entered?
;	    $IF     NE			;yes, entered. modify the filename found
	    JE $$IF150
		CALL	MODIFY_FILENAME
		TEST	ES:COPY_STATUS, MAYBE_ITSELF_FLAG
;		$IF	NZ
		JZ $$IF151
		    LEA     SI, DS:FILENAME_FOUND ;compare the Revised filename
		    LEA     DI, ES:DISP_S_FILE ;with original name
		    CALL    COMP_FILENAME ;if same, then issue error message and exit
;		$ENDIF
$$IF151:
;	    $ELSE
	    JMP SHORT $$EN150
$$IF150:
		TEST	ES:COPY_STATUS, MAYBE_ITSELF_FLAG ;*.* CASE
;		$IF	NZ
		JZ $$IF154
		    PUSH    ES
		    POP     DS		;ds - data seg

					; Set message parameters
		    MOV     AX,MSG_COPY_ITSELF ;AN000;
		    MOV     MSG_NUM,AX	;AN000; set message number
		    MOV     SUBST_COUNT,NO_SUBST ;AN000; no message subst.
		    MOV     MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
		    MOV     INPUT_FLAG,NO_INPUT ;AN000; no user input
		    CALL    PRINT_STDERR ;AN000; display error
		    JMP     MAIN_EXIT
;		$ENDIF
$$IF154:
;	    $ENDIF
$$EN150:
;	$ENDIF
$$EN146:
;-------------------------------------------------------------------------
; Use extended open DOS call to create the target file, use attribute list
; obtained from the previous Get Extended attribute DOS call
;-------------------------------------------------------------------------
	MOV	AX, Ext_Open		;AN000; = 6Ch
	MOV	BX,CREATE_MODE		;AN000;CREATE MODE = 0002H
	MOV	CX,CREATE_ATTR		;AN000; attribute = 0
	MOV	DX,CREATE_FLAG		;AN000; flag = 0112H
	MOV	SI,OFFSET TARGET_DRV_LET ;AN005; DS:SI-->NAME TO CREATE
	MOV	DI,NUL_LIST		;AN012; ES:DI = -1
	INT	21H			;AN000; create file

	JC	CAF_ERROR		;AN000;
	MOV	ES:T_HANDLE, AX 	;AN000;save handle

	CALL	CHK_T_RES_DEVICE	;check target handle is a reserved dev

	MOV	AX,SET_ATTRIB		;AN012;5704H
	CALL	SWITCH_DS_ES		;AN013;now ds - data, es - buffer
	MOV	BX,T_HANDLE		;AC013;THE FILE HANDLE
	LEA	DI,ES:ATTRIB_LIST	;AN013;PARAMETER LIST (ES:DI)
	INT	21H			;AN012;SET EXTENDED ATTRIBUTES
	CALL	SWITCH_DS_ES		;AN013;now es - data, ds - buffer
	JC	CAF_ERROR		;AN012;

	OR	ES:FILE_FLAG, CREATED_FLAG ;set created_flag
	JMP	CAF_EXIT
CAF_ERROR:
	PUSH	DS
	PUSH	ES
	POP	DS
	OR	COPY_STATUS, CREATE_ERROR_FLAG
	CALL	EXTENDED_ERROR_HANDLER
	POP	DS
CAF_EXIT:
	POP	ES
	POP	DS
	RET
CREATE_A_FILE ENDP
;
chk_t_res_device proc near
;check the target handle if it is for reserved device
;input: ES - data seg
;	DS - buffer
;	AX - filehandle created

	cmp	es:t_filename,0 	;if no user specified filename
	jne	ctrd_ioctl		;then should not be a reserved device name
	cmp	es:t_template,0
	je	ctrd_exit
ctrd_ioctl:
	mov	bx, ax			;file handle
	mov	ax, 4400h		;IOCTL get device info.
	int	21h
	test	dx, 80h 		;is device? (not a block device?)
	jz	ctrd_exit
	PUSH	ES			;AN000;
	POP	DS			;AN000;ds - data seg

; Set message parameters
	MOV	AX,MSG_RES_T_NAME	;AN000; message number
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,NO_SUBST	;AN000; no message substitution
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,NO_INPUT	;AN000; no input
	CALL	PRINT_STDOUT		;AN000; display message
	jmp	main_exit
ctrd_exit:
	ret
chk_t_res_device endp
;
MODIFY_FILENAME PROC NEAR
;modify the filename in the header using T_TEMPLATE.
;INPUT:
;DS: BUFFER
;ES: DATA SEG

	PUSH	DS			;save ds, es = data seg
	PUSH	ES

	PUSH	DS
	PUSH	ES
	MOV	ES, ES:PSP_SEG		;ES points to PSP
	MOV	DI, PSPFCB2_DRV 	;DI points to FCB2, 6c
	MOV	SI, OFFSET DS:TARGET_DRV_LET ;filename found, DS = buffer header
	MOV	AH, 29H 		;parse a filename
	MOV	AL, 0			;control bits
	INT	21h			;unfold the filename found into PSP FCB2 area

	POP	DS			;now DS=data seg, ES=PSP seg
	MOV	SI, OFFSET T_TEMPLATE	;SI points to template
	MOV	DI, PSPFCB2_DRV
	INC	DI			;DI points to the formatted filename
	MOV	CX, 11
	CLD
;	$DO
$$DO158:
	    CMP     CX, 0		;done?
;	$LEAVE	E			;yes. exit
	JE $$EN158
	    LODSB			;[SI] => AL, SI = SI + 1
	    CMP     AL, '?'		;global chr?
;	    $IF     E			;yes
	    JNE $$IF160
		INC	DI		;just skip the corresponding target chr
;	    $ELSE			;no
	    JMP SHORT $$EN160
$$IF160:
		STOSB			;change the target chr to this. DI = DI + 1
;	    $ENDIF
$$EN160:
	    DEC     CX
;	$ENDDO
	JMP SHORT $$DO158
$$EN158:

	POP	ES			;now ES = Buffer
	MOV	DI, OFFSET ES:FILENAME_FOUND ; di points to filename in the header
	MOV	DS, PSP_SEG		;DS = PSP seg
	MOV	SI, PSPFCB2_DRV
	INC	SI			;di points to Revised filename
	CALL	COMPRESS_FILENAME	;fold it

	POP	ES
	POP	DS
	RET
MODIFY_FILENAME ENDP
;

COMP_FILENAME PROC NEAR
;this routine is called when MAYBE_COPY_ITSELF flag in on.
;SI, DI asciiz string will be compared and if they are identical
;the show "Cannot copy onto itself" msg and jmp to main_exit.
;INPUT: DS - buffer
;	ES - data seg

	CLD
	MOV	AL, 0
	PUSH	DI			;save DI
	CALL	STRING_LENGTH		;CX get the length of string
	MOV	BX, CX			;now, BX got the length of the target filename entered.
	PUSH	BX			;save BX
	PUSH	ES			;save ES

	PUSH	DS
	POP	ES			;now ES set to DS
	PUSH	SI
	POP	DI			;now DI points to the source filename found.

	MOV	AL, 0
	CALL	STRING_LENGTH		;CX got the length of the string

	POP	ES			;restore ES
	POP	BX			;restore BX
	POP	DI			;restore DI

	CMP	BX, CX			;COMPARE LENGTH
	JNE	CF_EXIT 		;IF THEY ARE DIFFERENT, EXIT

	REPE	CMPSB			;compare SI, DI until not equal,
	CMP	CX, 0			;finish at cx = 0?
	JE	CF_SAME
	JMP	SHORT CF_EXIT
CF_SAME:
	PUSH	ES
	POP	DS			;ds = data seg

; Set message parameters
	MOV	AX,MSG_COPY_ITSELF	;AN000; message number
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,NO_SUBST	;AN000; no message substitution
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,NO_INPUT	;AN000; no input
	CALL	PRINT_STDERR		;AN000; display error message
	JMP	MAIN_EXIT
CF_EXIT:
	RET
COMP_FILENAME ENDP

;
SHOW_COPY_MESSAGE PROC NEAR
;show the source path, filename that is ready for creation in the target disk.
;INPUT: ES - data seg
;	DS - buffer header seg
	PUSH	DS			;save DS

	PUSH	ES
	POP	DS			;DS = data seg

	LEA	SI,SUBLIST1		;AN000; get addressability to list
	LEA	DX,DISP_S_PATH		;AN000; offset to path name
	MOV	[SI].DATA_OFF,DX	;AN000; save offset
	MOV	[SI].DATA_SEG,DS	;AN000; save data segment
	MOV	[SI].MSG_ID,1		;AN000; message ID
	MOV	[SI].FLAGS,010H 	;AN000; ASCIIZ string, left align
	MOV	[SI].MAX_WIDTH,0	;AN000; MAXIMUM FIELD WITH
	MOV	[SI].MIN_WIDTH,0	;AN000; MINIMUM FIELD WITH

	LEA	SI,SUBLIST2		;AN000; get addressability to list
	LEA	DX,DISP_S_FILE		;AN000; offset to file name
	MOV	[SI].DATA_OFF,DX	;AN000; save offset
	MOV	[SI].DATA_SEG,DS	;AN000; save data segment
	MOV	[SI].MSG_ID,2		;AN000; message ID
	MOV	[SI].FLAGS,010H 	;AN000; ASCIIZ string, left align
	MOV	[SI].MAX_WIDTH,0	;AN000; MAXIMUM FIELD WITH
	MOV	[SI].MIN_WIDTH,0	;AN000; MINIMUM FIELD WITH

	LEA	SI,SUBLIST1		;AN000;
	CMP	ES:T_DEPTH, 0		;starting directory?
;	$IF	E			;yes
	JNE $$IF164
	    MOV     AX,S_PATH_FILE0	;AN000;NO BACK SLASH BETWEEN PATH,FNAME

;	$ELSE
	JMP SHORT $$EN164
$$IF164:
	    MOV     AX,S_PATH_FILE1	;AN000;BACK SLASH IS BETWEEN PATH,FNAME

;	$ENDIF
$$EN164:
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,PARM_SUBST_TWO ;AN000; substitution count = 2
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,NO_INPUT	;AN000; no input
	CALL	PRINT_STDOUT		;show message "Reading source
	POP	DS			;restore DS
	RET
SHOW_COPY_MESSAGE ENDP
;
WRITE_A_FILE PROC NEAR
;write a file from the data area in the buffer.
;Remember the caller is WRITE_FROM_BUFFER which use ES for
;the program data area and DS for the header in the buffer.

	MOV	AH, Write		; = 40h
	MOV	BX, ES:T_HANDLE 	;handle saved in the program data area
	MOV	DX, ES:BYTS_OF_HDR	;AC005;skip header
	MOV	CX, DS:CX_BYTES 	;get the # from the header
	INT	21h
	JC	WAF_ERROR		;write error
	CMP	AX, DS:CX_BYTES
	JNE	WAF_DISKFULL
	JMP	WAF_EXIT
WAF_ERROR:
	CALL	CLOSE_DELETE_FILE	;close delete troubled file
	OR	COPY_STATUS, WRITE_ERROR_FLAG
	CALL	SWITCH_DS_ES		;AN000;DS = DATA SEG, ES = BUFFER
	CALL	EXTENDED_ERROR_HANDLER
	CALL	SWITCH_DS_ES		;AN000;ES = DATA SEG, DS = BUFFER
WAF_DISKFULL:
	MOV	ERRORLEVEL, 4		;set errorlevel

; Set message parameters
; Target disk full, critical error

	PUSH	DS			;AN000;DS = BUFFER
	PUSH	ES			;AN000;ES = DATA SEG
	POP	DS			;AN000;ES => DS = DATA SEG
	MOV	AX,MSG_DISK_FULL	;AN000; message number
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,NO_SUBST	;AN000; no message substitution
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,NO_INPUT	;AN000; no input
	CALL	PRINT_STDERR		;AN000; display error message
	OR	COPY_STATUS, DISK_FULL_FLAG ;set disk_full_flag
	POP	DS			;AN000;RESTORE DS = BUFFER
	CALL	CLOSE_DELETE_FILE
	STC				;set carry and return to caller
WAF_EXIT:
	RET
WRITE_A_FILE ENDP
;
SET_FILE_DATE_TIME PROC NEAR
;input: BX - target file handle
;
	MOV	AH, File_date_time	; = 57h
	MOV	AL, Set_file_time	; = 1
	MOV	CX, DS:FILE_TIME_FOUND
	MOV	DX, DS:FILE_DATE_FOUND
	INT	21h
	RET
SET_FILE_DATE_TIME ENDP
;
CLOSE_A_FILE PROC NEAR
;
;CLOSE A FILE AND UPDATE COUNT OF OPEN FILES
;
;INPUT: BX - file handle to be closed
;
	CMP	OPEN_FILE_COUNT,NUL	;AN005;ARE THERE ANY OPEN FILES?
;	$IF	A			;AN005;
	JNA $$IF167
	    DEC     OPEN_FILE_COUNT	;AN005;IF SO, REDUCE THE COUNT BY 1.
;	$ENDIF				;AN005;
$$IF167:
	MOV	AH, Close		; = 3Eh
	INT	21H
	RET
CLOSE_A_FILE ENDP
;
DELETE_A_FILE PROC NEAR
;input: DS:DX - points to ASCIIZ string

	MOV	AH, 41h 		; = 41h
	INT	21H
	RET
DELETE_A_FILE ENDP
;
MAKE_DIR PROC	NEAR
;make a subdirectory in the current target directory.
;The directory name is in the header part Target_drv_Let
;with the drive letter.
;input:DS - buffer
;      ES - data seg

	MOV	AH, Mkdir		; = 39h
	MOV	DX, OFFSET DS:TARGET_DRV_LET ;target drv and filename
	INT	21h
	JC	MD_ERROR
	JMP	MD_EXIT
MD_ERROR:
;cannot distinguish between cases of: 1. already there exists a directory.
; 2. there has been a file exist with the same name in the target.
; 3. no disk space to make dir.
; Case 1, should ignore and just exit this routine
; Case 2, critical error.
; Case 3, critical error.
	call	chk_disk_full		;check disk full condition first
	jc	MD_EXIST		;AC026;yes, disk full, check if exist
	push	es			;else check a file with the same name.
	push	ds
	push	dx
	mov	ah, 2fH 		;get current DTA addr in ES:BX
	int	21h
	mov	ds, es:psp_seg
	mov	dx, 80h
	mov	ah, 1ah
	int	21h			;set dta to psp default dta area
	pop	dx			;restore DX - target drv and filename
	pop	ds			;restore DS - buffer
	mov	cx, 6			;HIDDEN + SYSTEM inclusive search
	mov	ah, 4Eh 		;FIND FIRST MATCHING FILE
	int	21h
	jc	md_ok			;not found. There exists subdir. ignore
	stc				;else found a file with same name.
	jmp	short MD_RESTORE

MD_OK:
	clc				;else there exists dir., ignore error.
MD_RESTORE:
	pushf
	push	ds			;save ds again	- buffer
	push	es			;es - save dta seg
	pop	ds			;ds = saved DTA seg
	mov	dx, bx			;     saved DTA off
	mov	ah, 1ah
	int	21h			;restore DTA
	pop	ds			;restore ds
	popf
	pop	es			;restore ES
	jnc	md_exit 		;if no error, then exit
	jmp	md_err			;AN026;

;else check a file with the same name.

MD_EXIST:
	push	es			;AN026;
	push	ds			;AN026;
	push	dx			;AN026;
	mov	ah, 2fH 		;AN026;get current DTA addr in ES:BX
	int	21h			;AN026;
	mov	ds, es:psp_seg		;AN026;
	mov	dx, 80h 		;AN026;
	mov	ah, 1ah 		;AN026;
	int	21h			;AN026;set dta to psp default dta area
	pop	dx			;AN026;restore DX - tar drv and filenm
	pop	ds			;AN026;restore DS - buffer
	mov	cx, 10h 		;AN026;sub-directory search
	mov	ah, 4Eh 		;AN026;FIND FIRST MATCHING dir.
	int	21h			;AN026;

	pushf				;AN026;save carry state
	push	ds			;AN026;save ds again  - buffer
	push	es			;AN016;es - save dta seg
	pop	ds			;AN026;ds = saved DTA seg
	mov	dx, bx			;AN026;     saved DTA off
	mov	ah, 1ah 		;AN026;
	int	21h			;AN026;restore DTA
	pop	ds			;AN026;restore ds
	popf				;AN026;get carry state from find
	pop	es			;AN026;restore ES
	jnc	md_exit 		;AN026;if no error, then dir. exits

MD_ERR:
	call	switch_ds_es		;switch ds, es
	mov	errorlevel, 4		;set the errorlevel to 4
	test	copy_status, disk_full_flag ;disk full?
	jnz	MD_FULL 		;yes, full.
	mov	ax,msg_unable_create	; else make dir fails because of
					; the same file name
	or	copy_status, mkdir_error_flag ;set make dir error flag
	jmp	short MD_PRT
MD_FULL:
	mov	ax,msg_disk_full
MD_PRT:
; Set message parameters
	PUSH	ES			;AN017;ES = BUFFER
	PUSH	DS			;AN017;DS = DATA SEG
	POP	ES			;AN017;DS => ES = DATA SEG
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,NO_SUBST	;AN000; no  message substitution
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,NO_INPUT	;AN000; no input
	CALL	PRINT_STDERR		;AN000; display message
	POP	ES			;AN017;RESTORE ES = BUFFER

	call	switch_ds_es		;restore ds, es
	stc				;error - set carry
MD_EXIT:
	RET
MAKE_DIR ENDP
;
CHK_DISK_FULL PROC NEAR
;check target disk space, and if no more clusters then set carry, disk_full_flag.
;this routine is called by MAKE_DIR routine.
;INPUT: DS - buffer
;	ES - data seg
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	MOV	AH, 36h 		;GET DISK FREE SPACE
	MOV	DL, ES:T_DRV_NUMBER	;OF TARGET
	INT	21h
	CMP	BX, 0			;NO MORE CLUSTER?
	JE	CDF_FULL
	CLC
	JMP	SHORT CDF_EXIT
CDF_FULL:
	OR	ES:COPY_STATUS, DISK_FULL_FLAG ;SET DISK FULL FLAG
	STC				;SET CARRY
CDF_EXIT:
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET

CHK_DISK_FULL ENDP
;

CHK_FILE_NOT_FOUND PROC NEAR
;if FILE_CNT_LOW=FILE_CNT_HIGH=FOUND_FILE_FLAG=0 AND NO INIT ERROR,
; then show "File not found" msg
;INPUT: ES, DS = data seg

	TEST	PARM_FLAG, INIT_ERROR_FLAG
;	$IF	Z,AND			;no init error
	JNZ $$IF169
	CMP	FILE_CNT_LOW, 0
;	$IF	E,AND
	JNE $$IF169
	CMP	FILE_CNT_HIGH, 0
;	$IF	E,AND
	JNE $$IF169
	CMP	FOUND_FILE_FLAG, 0
;	$IF	E
	JNE $$IF169
	    MOV     ES, PSP_SEG 	;use PSP area for parsing
	    MOV     DI, PSPFCB1_DRV
	    MOV     SI, OFFSET S_FILE
	    MOV     AH, 29h
	    MOV     AL, 0		;control byte
	    INT     21h
	    CALL    SWITCH_DS_ES	;now, ds - psp seg, es - data seg
	    MOV     DI,OFFSET DISP_S_FILE
	    MOV     SI,PSPFCB1_DRV
	    INC     SI			;now SI points to the formatted filename area
	    CALL    COMPRESS_FILENAME	;[pspfcb1_drv+1] => disp_s_file
	    PUSH    ES
	    POP     DS			;now DS=ES=data seg
	    LEA     SI,SUBLIST1 	;AN000;
	    MOV     DI,OFFSET DISP_S_FILE ;AN000;
	    MOV     [SI].DATA_OFF,DI	;AN000; SI-->File name
	    MOV     [SI].DATA_SEG,DS	;AN000; DS-->Segment
	    MOV     [SI].MSG_ID,0	;AN018; message ID
	    MOV     [SI].FLAGS,010H	;AN000; ASCIIZ string, left align
	    MOV     [SI].MAX_WIDTH,0	;AN000; MAXIMUM FIELD WITH
	    MOV     [SI].MIN_WIDTH,0	;AN000; MINIMUM FIELD WITH
	    MOV     AX,MSG_FILE_NOT_ERR ;AN018;
	    MOV     MSG_NUM,AX		;AN000; set message number
	    MOV     SUBST_COUNT,PARM_SUBST_ONE ;AN000; substitution count
	    MOV     MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	    MOV     INPUT_FLAG,NO_INPUT ;AN000; no input
	    CALL    PRINT_STDOUT	;AN000; display message
;	$ENDIF
$$IF169:

	RET

CHK_FILE_NOT_FOUND ENDP

;
subttl	string_length
page
;******************************************************************************
;PURPOSE: Get the length of a string pointed by ES:DI until it encounters
;	  the same character given by the user in AL.
;	  The length will be an output in CX.  The number includes the
;	  charater found.
;	  For example, if you want to determine the length of an ASCIIZ string,
;	  set ES:DI to that string and set AL to 0.  The output CX is the
;	  total length of the ASCIIZ string including 0.
;	  So, if the first character pointed by DI is the same as that of AL,
;	  then the length will be 1.
;	  !!! It is the user's responsibility to make it sure that the string
;	      contains the character given in AL.  If not, unpredictable
;	      results will occur.!!!
;
; DATA INPUT
;   REGISTERS: AL - ASCII CHARACTER
;	       ES:DI - POINTER TO THE STRING.
; DATA OUTPUT
;   REGISTERS: AX,DX,SI etc - PRESERVED.
;	       BX - DISTROYED
;	       CX - STRING LENGTH UNTIL FOUND THE GIVEN CHARACTER.
;	       DI - POINTS TO THE NEXT CHARACTER AFTER THE STRING.
;	       DIRECTION FLAG -  CLEARED
;	       ZERO FLAG - RESET
;******************************************************************************
;
STRING_LENGTH PROC NEAR
PUBLIC	STRING_LENGTH
	CLD				;CLEAR DIRECTION
	MOV	BX,DI			;SAVE ORIGINAL DI VALUE
	MOV	CX,80H			;TRY MAX 128 BYTES
	REPNE	SCASB			;SCAN THE STRING UNTIL FOUND
	PUSH	DI			;SAVE CURRENT DI VALUE WHICH POINTS TO NEXT CHR AFTER STRING
	SUB	DI,BX			;GET THE LENGTH
	MOV	CX,DI			;MOV THE LENGTH TO CX
	POP	DI
	RET
STRING_LENGTH ENDP
;
subttl	concat_asciiz
page
;******************************************************************************
;PURPOSE: Concatenate two ASCIIZ string into one ASCIIZ string.
;	  The ASCIIZ string pointed by DS:SI will be concatenated to
;	  the one pointed by ES:DI.  The result string will be pointed by
;	  ES:DI.
;	  AL is used to put the delimeter character in between the strings.
;	  If you *DON'T* like to put the delimeter ***make AL to 0FFh***.
;	  For example, assume sting1 "ABCDE",0 pointed by DI and string2
;	  "FGHI",0 pointed by SI.
;	  If you want a delimeter "\" between two string, set AL to "\"
;	  before calling.  The result will "ABCDE\FGHI",0 pointed by DI.
;	  If you set AL to "0FFh", then it becomes "ABCDEFGHI",0.
;	  This feature is useful for handling PATH if you set AL to "\"
;	  and, for any general string processes if you set AL to "0FFh".
;	  This routine will call subroutine STRING_LENGTH.
;DATA INPUT
;  REGISTERS: AL - DELIMETER OR 0FFh
;	      ES:DI - POINTER TO THE DESTINATION STRING.
;	      DS:SI - POINTER TO THE SOURCE TO BE CONCATENATED.
;DATA OUTPUT
;  REGISTERS: AL, DX - preserved
;	      DI - preserved. POINTER TO THE RESULT STRING
;	      SI - DISTROYED
;	      CX - RESULT ASCIIZ STRING LENGTH INCLUDE 0
;	      DIRECTION FLAG - CLEARED
;******************************************************************************
CONCAT_ASCIIZ PROC NEAR

PUBLIC	CONCAT_ASCIIZ
	PUSH	DI			;SAVE POINTER VALUE WHICH WILL BE RETRUNED TO CALLER.
	PUSH	AX			;SAVE VALUE IN AL.
	MOV	AL, 0			;DEALING WITH ASCIIZ STRING
	CALL	STRING_LENGTH		;LET DI POINTS TO THE NEXT CHR AFTER THIS STRING
					;DIRECTION WILL BE CLEARED.
	DEC	DI			;MAKE DI POINT TO THE LAST CHARACTER 0
	POP	AX			;RESTORE AL.
	CMP	AL, 0FFh
;	$IF	NE			;IF THE USER WANTS TO PUT DIMIMETER,
	JE $$IF171
	    STOSB			;  REPLACE 0 WITH IT.
;	$ELSE
	JMP SHORT $$EN171
$$IF171:
	    DEC     CX			;ELSE DECREASE LENGTH BY 1
;	$ENDIF
$$EN171:
;	$DO
$$DO174:
	    LODSB			;MOV [SI] TO AL
	    STOSB			;STORE AL TO [DI]
	    INC     CX			;INCREASE LENGTH
	    CMP     AL, 0		;WAS IT A LAST CHARACTER?
;	$ENDDO	E			;THEN EXIT THIS LOOP
	JNE $$DO174
	POP	DI
	RET
CONCAT_ASCIIZ ENDP
;

subttl	last_dir_out
page
;******************************************************************************
;PURPOSE: Take off the last directory name from the path pointed by DI.
;	  This routine assumes the pattern of a path to be an ASCIIZ string
;	  in the form of "[d:][\]dir1\dir2".  Notice that this path does not
;	  have entailing "\".	This routine will simply travel the string
;	  until it found last "\" which will, then, be replaced with 0.
;	  If no "\" found, then carry will be set.
;	  *** This should be not be used for the path in the form of
;	  *** "d:\", 0 for the root directory, since in this case the returned
;	  *** string will be "d:",0 and AX value returned be meaningless (Just
;	  *** points to 0.)
;DATA INPUT
; REGISTERS: DI - points to an ASCIIZ path string.
;	     ES - assumed default segment for DI
;DATA OUTPUT
; REGISTERS: DI - points to the resultant path string.
;	     AX - offset value of the last subdirectory name taken out, in case
;		  of the user's need.
;	     Other register will be unchanged.
; CARRY FLAG WILL SET IF NOT FOUND.
;******************************************************************************

LAST_DIR_OUT PROC NEAR
PUBLIC	LAST_DIR_OUT

	PUSH	DI
	PUSH	SI			;save current DI, SI
	CLD				;clear direction
	MOV	SI, 0FFFFh		;used as a not_found flag if unchanged.
;	$DO
$$DO176:
;	    $DO 			;AN010;
$$DO177:
		CLC			;AN010;INITIALIZE TO NOT DBCS
		MOV	AL,BYTE PTR [DI] ;AN010;GET THE 1st CHAR TO TEST
		CALL	CHK_DBCS	;AN010;SEE IF WE ARE IN DBCS
;	    $LEAVE  NC			;AN010;THIS IS NOT DBCS
	    JNC $$EN177
		INC	DI		;AN010;GO TO THE NEXT CHAR TO CHECK
		INC	DI		;AN010;DITO
;	    $ENDDO			;AN010;
	    JMP SHORT $$DO177
$$EN177:
	    MOV     AL, 0
	    SCASB
;	$LEAVE	Z			;if [DI] = 0, then end of string. Ends this loop.
	JZ $$EN176
	    DEC     DI			;if [DI] <> 0, then go back and scan char again
	    MOV     AL, "\"		;to see it was a back slash.
	    SCASB
;	    $IF     Z			;if it was, then save the addr to SI.
	    JNZ $$IF181
		PUSH	DI
		POP	SI

		DEC	SI
;	    $ENDIF			;else do loop again.
$$IF181:
;	$ENDDO
	JMP SHORT $$DO176
$$EN176:
	CLC				;clear carry flag.
	CMP	SI, 0FFFFh		;Had SI been changed?
;	$IF	E
	JNE $$IF184
	    STC 			;No, set the carry. Not found.
;	$ELSE
	JMP SHORT $$EN184
$$IF184:
	    MOV     BYTE PTR ES:[SI], 0 ;Yes, replace "\" with 0. Seg override to get default DI seg.
	    MOV     AX, SI
	    INC     AX			;let AX have the last dir offset value.
	    CLC 			;clear carry
;	$ENDIF
$$EN184:
	POP	SI			;restore original value
	POP	DI			;original string offset
	RET
LAST_DIR_OUT ENDP
;
;	HEADER	<CHK_DBCS -SEE IF SPECIFIED BYTE IS A DBCS LEAD BYTE>
;*****************************************************************************
; Check DBCS environment
;*****************************************************************************

; Function: Check if a specified byte is in ranges of the DBCS lead bytes
; Input:    AL = Code to be examined
; Output:   If CF is on then a lead byte of DBCS
; Register: FL is used for the output, others are unchanged.

	PUBLIC	CHK_DBCS
Chk_DBCS PROC				;AN010;
	PUSH	DS			;AN010; save these regs, about to be clobbered
	PUSH	SI			;AN010;
	CMP	DBCSEV_SEG,0		;AN010; ALREADY SET ?
;	$IF	E			;AN010; if the vector not yet found
	JNE $$IF187
	    PUSH    AX			;AN010;
	    MOV     AX,6300H		;AN010; GET DBCS EV CALL
	    INT     21H 		;AN010; ds:si points to the dbcs vector

	    ASSUME  DS:NOTHING		;AN010; that function clobbered old DS

	    MOV     DBCSEV_OFF,SI	;AN010; remember where the dbcs vector is
	    MOV     DBCSEV_SEG,DS	;AN010;  so next time I don't have to look for it
	    POP     AX			;AN010;
;	$ENDIF				;AN010;
$$IF187:
	LDS	SI,DWORD PTR DBCSEV_OFF ;AN010;SET DS:SI TO POINT TO THE DBCS VECTOR
;	$SEARCH 			;AN010;
$$DO189:
	    CMP     WORD PTR [SI],0	;AN010; vector ends with a nul terminator entry
;	$LEAVE	E			;AN010; if that was the terminator entry, quit
	JE $$EN189
	    CMP     AL,[SI]		;AN010; look at LOW value of vector
;	$EXITIF NB,AND			;AN010; if this byte is in range with respect to LOW
	JB $$IF189
	    CMP     AL,[SI+1]		;AN010; look at HIGH value of vector
;	$EXITIF NA			;AN010; if this byte is still in range
	JA $$IF189
	    STC 			;AN010; set flag to say, found a DBCS char.
;	$ORELSE 			;AN010; since char not in this vector
	JMP SHORT $$SR189
$$IF189:
	    ADD     SI,2		;AN010; go look at next vector in dbcs table
;	$ENDLOOP			;AN010; go back and check out new vector entry
	JMP SHORT $$DO189
$$EN189:
	    CLC 			;AN010; set flag to say, this is not a DBCS character
;	$ENDSRCH			;AN010;
$$SR189:
	POP	SI			;AN010; restore the regs
	POP	DS			;AN010;

;	ASSUME	DS:DSEG 		;AN010; tell masm, DS back to normal

	RET				;AN010;
chk_DBCS ENDP				;AN010;
;
;

subttl	Compress_Filename
page

;
;******************************************************************************
;
; PURPOSE:
; --------
;  Compress the FCB style filename into an ASCIIZ packed name.
;  For example, 'ABC?????EXE' = > 'ABC?????.EXE',0
;	    or	'ABC     EXE' = > 'ABC.EXE',0
;  Note that the length of the source is *** 11 *** byte long.
;  The max length of result is *** 13 *** bytes long.
;  In the usual practice, the source filename with extention can be obtained
;  by using function call 29h (Parse a Filename).  So this routine is
;  an inverse function of fun. 29h except DI should be the *** starting point
;  of destination string *** instead of that of an unopened FCB (When you use
;  fun 29h together with this routine, keep this thing in mind. Also if ES, DS
;  values are different in your program, be careful to use them correctly.)
;------------------------------------------------------------------------------
; REGISTERS INPUT
; ----------------
; AX:
; BX:
; CX:
; DX:
; SI: offset of source unpacked filename with extention
; DI: offset where the resultant asciiz filename(.ext) will be placed.
; SP:
; BP:
; DS: source seg
; ES: result seg
; SS:
;
; DATA INPUT
; -----------
; Memory_Label -
;
;-----------------------------------------------------------------------------
; REGISTERS OUTPUT
; ----------------
; AX:
; BX:
; CX:
; DX:
; SI:
; DI:
; SP:
; BP:
; DS:
; ES:
; SS:
;
; DATA OUTPUT
; -----------
;
; FLAG OUTPUT
; -----------
;******************************************************************************

COMPRESS_FILENAME PROC NEAR
PUBLIC	COMPRESS_FILENAME
	PUSH	DI
	XOR	CX, CX			;CX = 0
;	$DO
$$DO195:
	    LODSB			;[SI] => AL, SI = SI + 1
	    CMP     CX, 10		;CX > 10 then exit
;	$LEAVE	A
	JA $$EN195
	    CMP     CX,  8		;filename extention position
;	    $IF     B			;CX < 8. handling filename
	    JNB $$IF197
		CMP	AL, ' ' 	;AL = blank ?
;		$IF	E
		JNE $$IF198
		    MOV     AX, 7
		    SUB     AX, CX
		    ADD     SI, AX	;SI = SI + (7 - CX)
		    MOV     CX, 8	;then skip to handles extention
;		$ELSE
		JMP SHORT $$EN198
$$IF198:
		    STOSB		;AL => [DI], DI = DI + 1
		    INC     CX		;CX = CX + 1
;		$ENDIF
$$EN198:
;	    $ELSE			;extention part
	    JMP SHORT $$EN197
$$IF197:
		CMP	AL, ' '
;		$IF	E
		JNE $$IF202
		    MOV     CX, 11	;exit this loop
;		$ELSE
		JMP SHORT $$EN202
$$IF202:
		    CMP     CX, 8	;the first chr of extention?
;		    $IF     E		;yes
		    JNE $$IF204
			PUSH	AX	;save cur chr
			MOV	AL, '.' ;and put a dot
			STOSB		; . => [DI], DI = DI + 1
			POP	AX	;restore AX
;		    $ENDIF
$$IF204:
		    STOSB		;AL => [DI], DI = DI + 1
		    INC     CX		;CX = CX + 1
;		$ENDIF
$$EN202:
;	    $ENDIF
$$EN197:
;	$ENDDO
	JMP SHORT $$DO195
$$EN195:
	MOV	AL, 0
	STOSB				;put 0 at the current [DI]

	POP	DI			;restore DI
	RET
COMPRESS_FILENAME ENDP
;


SET_DEFAULT_DRV PROC NEAR
;change source drv as a default drv for conveniece of find, read operation
;of source. (handling target should be more specific as for as drive letter
;goes.)
;input: DL - drive # (0 = A, 1 = B ...)

	MOV	AH, Select_Disk 	; = 0Eh
	INT	21H
	OR	SYS_FLAG, DEFAULT_DRV_SET_FLAG ;indicates default drv has been changed
					;Used for exit the program to restore default drv
	RET
SET_DEFAULT_DRV ENDP
;


ORG_S_DEF PROC	NEAR
;restore the original source directory.
	PUSH	ES
	PUSH	DS

	PUSH	DS
	POP	ES			;DS=ES=data seg

	TEST	SYS_FLAG, DEFAULT_S_DIR_FLAG ;source default direcotry saved?
;	$IF	NZ
	JZ $$IF209
	    MOV     DX, OFFSET SAV_S_DRV ;saved source drive letter & directory
	    MOV     AH, 3Bh
	    INT     21h 		;restore source
	    AND     SYS_FLAG, RESET_DEFAULT_S_DIR ;reset the flag
;	$ENDIF
$$IF209:

	POP	DS
	POP	ES

	RET
ORG_S_DEF ENDP
;
ORG_S_T_DEF PROC NEAR
;retore original target, source and default drv and directory
;check default_s(t)_dir_flag, default_drv_set_flag to restore source,
;or target directory and default drive.

	TEST	SYS_FLAG, TURN_VERIFY_OFF_FLAG ;turn off verify?
;	$IF	NZ			;yes
	JZ $$IF211
	    MOV     AX, 2E00h		;turn it off
	    INT     21H
;	$ENDIF
$$IF211:
	TEST	SYS_FLAG, DEFAULT_DRV_SET_FLAG ;default drive has been changed?
;	$IF	NZ			;yes
	JZ $$IF213
	    MOV     DL, SAV_DEFAULT_DRV
	    DEC     DL
	    CALL    SET_DEFAULT_DRV	;restore default drv.

; Following is a fix for PTR 0000012 . The fix is to skip changing default
; drive directory if source drive is not the default drive.

	    MOV     AL, S_DRV_NUMBER	;AN002; get source drive number
	    CMP     AL, SAV_DEFAULT_DRV ;AN002; src drive is the default drv ?
;	    $IF     NE			;AC022;NO, SO SEE IF DEF. DRV. IS CHGD.
	    JE $$IF214
		TEST	SYS_FLAG, DEFAULT_DRV_SET_FLAG ;AN022;DEF DRV CHGD?
;		$IF	NZ		;AN022;YES, RESET IT
		JZ $$IF215
		    MOV     DX, OFFSET SAV_DEF_DIR_ROOT ;AN022;GET THE SETTING
		    MOV     AH, Chdir	;AN022;MAKE THE CALL
		    INT     21H 	;AN022;
;		$ENDIF			;AN022;
$$IF215:
;	    $ELSE			;AN022;SRC IS DEF DRIVE!
	    JMP SHORT $$EN214
$$IF214:
		MOV	DX, OFFSET SAV_DEF_DIR_ROOT
		MOV	AH, Chdir
		INT	21H		    ;restore current dir of default dir
;	    $ENDIF			;AN022;
$$EN214:
;	$ENDIF
$$IF213:


	TEST	SYS_FLAG, DEFAULT_S_DIR_FLAG ;source default direcotry saved?
;	$IF	NZ
	JZ $$IF220
	    MOV     DX, OFFSET SAV_S_DRV ;saved source drive letter & directory
	    MOV     AH, 3Bh
	    INT     21h 		;restore source. This is for the case of ERROR exit.
;	$ENDIF
$$IF220:

	TEST	SYS_FLAG, DEFAULT_T_DIR_FLAG ;target default directory saved?
;	$IF	NZ			;then assume both source, target default saved
	JZ $$IF222
	    MOV     DX, OFFSET SAV_T_DRV ;saved target drive letter & directory
	    MOV     AH, 3Bh
	    INT     21h 		;restore target
;	$ENDIF
$$IF222:

	RET
ORG_S_T_DEF ENDP
;

CHK_MKDIR_LVL PROC NEAR
;if starting target directories has been created, and no files has been found to copy,
;and /E option is not specified, then remove the directories created.
;
	CMP	T_MKDIR_LVL, 0		;target starting directory created?
;	$IF	A,AND			;yes.
	JNA $$IF224
	TEST	OPTION_FLAG, SLASH_E	;/E option taken?
;	$IF	Z,AND			;no.
	JNZ $$IF224
	CMP	FOUND_FILE_FLAG, 0	;found any file?
;	$IF	E
	JNE $$IF224
	    CALL    T_RM_STARTING_DIR	;then, remove created directories.
;	$ENDIF
$$IF224:
	RET
CHK_MKDIR_LVL ENDP
;

T_RM_STARTING_DIR PROC NEAR
;based on the current target directory, remove directories T_MKDIR_LVL times
;INPUT: T_MKDIR_LVL
;	T_DRV_NUMBER
;	T_DRV_PATH
;	T_PATH


	MOV	DL, T_DRV_NUMBER
	LEA	SI, T_PATH
	MOV	AH, Get_Current_Directory
	INT	21h

TRSD_AGAIN:
	MOV	DX, OFFSET T_PARENT	;chdir to the parent directory
	MOV	AH, 3Bh 		;Chdir
	INT	21h
	MOV	DX, OFFSET T_DRV_PATH
	MOV	AH, 3Ah 		;Rmdir
	INT	21h
	MOV	DI, OFFSET T_DRV_PATH
	CALL	LAST_DIR_OUT		;take out the last removed dir name
	DEC	T_MKDIR_LVL		;decrease the number
	CMP	T_MKDIR_LVL, 0		;no more?
	JA	TRSD_AGAIN

	RET
T_RM_STARTING_DIR ENDP
;


;************************************************************
;*
;*   SUBROUTINE NAME:	   PRINT_STDOUT
;*
;*   SUBROUTINE FUNCTION:
;*	   Display the requested message to the specified handle
;*
;*   INPUT:
;*	     Paramters in parater storage area
;*	     DS:SI-->Substitution List
;*	     ES:DI-->PTR to input buffer if buffered keyboard
;*		     input is specified (DL = 0A)
;*   OUTPUT:
;*	     AX =   Single character entered if DL=01
;*		OR
;*	     ES:DI-->input buffer where string is returned if DL=0A
;*
;*	The message corresponding to the requested msg number will
;*	be written to Standard Out. Message substitution will
;*	be performed if specified
;*
;*   NORMAL EXIT:
;*	Message will be successfully written to requested handle.
;*
;*   ERROR EXIT:
;*	None.  Note that theoretically an error can be returned from
;*	SYSDISPMSG, but there is nothing that the application can do.
;*
;*   INTERNAL REFERENCES:    SysDispMsg
;*
;*   EXTERNAL REFERENCES:
;*	None
;*
;************************************************************
PRINT_STDOUT PROC NEAR			;AN000:

	PUSH	BX			;AN000;
	PUSH	CX			;AN000;
	PUSH	DX

	MOV	AX,MSG_NUM		;AN000; Message ID
	MOV	BX,STDOUT		;AN000; standard input message handle
	MOV	CX,SUBST_COUNT		;AN000; message substitution count
	MOV	DH,MSG_CLASS		;AN000; message class
	MOV	DL,INPUT_FLAG		;AN000; Type of INT 10 for KBD input

	CALL	SYSDISPMSG		;AN000:  AX=Extended key value if wait
					;for key
	JNC	DISP_DONE		;AN000:  If CARRY SET then registers
					;will contain extended error info
					;	AX - Extended error Number
					;	BH - Error Class
					;	BL - Suggested action
DISP_DONE:				;AN000: CH - Locus
	POP	DX
	POP	CX			;AN000;
	POP	BX			;AN000;

	RET				;AN000:
PRINT_STDOUT ENDP			;AN000:




;************************************************************
;*
;*   SUBROUTINE NAME:	   PRINT_STDERR
;*
;*   FUNCTION: Display the requested message to Standard Out
;*
;*   INPUT:
;*	     Parameters in parameter storage area
;*	     DS:SI-->Substitution List
;*	     ES:DI-->PTR to input buffer if buffered keyboard
;*		     input is specified (DL = 0A)
;*
;*   OUTPUT:
;*	     AX =   Single character entered if DL=01
;*		OR
;*	     ES:DI-->input buffer where string is returned if DL=0A
;*	The message corresponding to the requested msg number will
;*	be written to the Standard Error. Message substitution will
;*	be performed if specified
;*
;*   NORMAL EXIT:
;*	Message will be successfully written to requested handle.
;*
;*   ERROR EXIT:
;*	None.  Note that theoretically an error can be returned from
;*	SYSDISPMSG, but there is nothing that the application can do.
;*
;*   INTERNAL REFERENCES:    SysDispMsg
;*
;*   EXTERNAL REFERENCES:    None
;*
;************************************************************
PRINT_STDERR PROC NEAR			;AN000:

	PUSH	AX			;AN000;
	PUSH	BX			;AN000;
	PUSH	CX			;AN000;
	PUSH	DX

	MOV	AX,MSG_NUM		;AN000;  Message ID
	MOV	BX,STDERR		;AN000;  Handle
	MOV	CX,SUBST_COUNT		;AN000;  message substitution count
	MOV	DH,MSG_CLASS		;AN000;  message class
	MOV	DL,INPUT_FLAG		;AN000;  INT 10 KBD input type

	CALL	SYSDISPMSG		;AN000:  AX=Extended key value if wait
					;for key
	JNC	DISP_EXIT		;AN000:  If CARRY SET then registers
					;will contain extended error info
					;	AX - Extended error Number
					;	BH - Error Class
					;	BL - Suggested action
DISP_EXIT:				;AN000: CH - Locus
	POP	DX
	POP	CX			;AN000;
	POP	BX			;AN000;
	POP	AX			;AN000;
	RET				;AN000:

PRINT_STDERR ENDP			;AN000:





;
EXTENDED_ERROR_HANDLER PROC NEAR
;This routine calls fun 59(Get extended error) and
;check the actions returned.  If it is Immediate exit, then jmp to JUST_EXIT
;If it is abort, then jmp to MAIN_EXIT.
;Or else, it check the COPY_STATUS flag.  If is not open, read, create or
;write, then it is considered as a critical error and jmp to MAIN_EXIT.
;If access denied
;   too many open files
;   sharing violation
;   lock violation
;   general failure
;then show the message and jmp to the MAIN_EXIT.
; *** Currently, this routine directly jump to the main_exit instead of
; *** returing to the caller.  The reason is we regard the above error conditions
; *** as being not suitable to continue copying and, hence, to simplify
; *** the error process.
;INPUT:
;      DS - DATA SEG
;OUTPUT:
;      ALL THE REG PRESERVED

	PUSH	ES			;save ES
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DS			;AN000;
	POP	ES			;AN000;DS = ES = DATA SEG
	PUSHF				;save flags

	PUSH	ES
	MOV	AH, 59h 		;get extended error
	MOV	BX, 0			;version 3.0
	INT	21h
	POP	ES

	MOV	ERRORLEVEL, 4		;error in operation
	TEST	COPY_STATUS, OPEN_ERROR_FLAG ;open error?
	JNZ	OPEN_ERROR_RTN		;yes
	TEST	COPY_STATUS, READ_ERROR_FLAG ;read error?
	JNZ	READ_ERROR_RTN
	TEST	COPY_STATUS, CREATE_ERROR_FLAG ;create error?
	JNZ	CREATE_ERROR_RTN
	TEST	COPY_STATUS, WRITE_ERROR_FLAG ;write error?
	JNZ	WRITE_ERROR_RTN
	TEST	COPY_STATUS, CHDIR_ERROR_FLAG ;chdir error?
	JNZ	CHDIR_ERROR_RTN
	JMP	SHORT GOTO_MAIN_EXIT

OPEN_ERROR_RTN: 			;open error. show error message and exit
	CALL	SHOW_S_PATH_FILE_ERR	;show the troubled path filename
	CALL	SHOW_ERROR_MESSAGE
	JMP	SHORT GOTO_MAIN_EXIT	;abort

READ_ERROR_RTN:
	CALL	SHOW_S_PATH_FILE_ERR
	CALL	SHOW_ERROR_MESSAGE	;show message and abort
	JMP	SHORT GOTO_MAIN_EXIT

CREATE_ERROR_RTN:
	CMP	AX, 2			;"file not found" to create?
	JNE	CER_1
; Set message parameters
	MOV	AX,MSG_FILE_CREATE_ERR	;AN000; message number
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,NO_SUBST	;AN000; no  message substitution
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,NO_INPUT	;AN000; no input
	CALL	PRINT_STDERR		;show "File creation error" message
					;instead of "File not found"
	JMP	SHORT GOTO_MAIN_EXIT
CER_1:
	CALL	SHOW_ERROR_MESSAGE	;show error_message
	JMP	SHORT GOTO_MAIN_EXIT
WRITE_ERROR_RTN:
	CALL	SHOW_ERROR_MESSAGE	;show message
	JMP	SHORT GOTO_MAIN_EXIT
CHDIR_ERROR_RTN:

	PUSH	AX			;AN000;
; Set substitution list
	LEA	SI,SUBLIST1		;AN000; get addressability to sublist
	LEA	DX,S_DRV_PATH		;AN000; offset to PATH NAME
	MOV	[SI].DATA_OFF,DX	;AN000; save offset
	MOV	[SI].DATA_SEG,DS	;AN000; save data segment
	MOV	[SI].MSG_ID,1		;AN000; message ID
	MOV	[SI].FLAGS,010H 	;AN000; ASCIIZ string, left align
	MOV	[SI].MAX_WIDTH,0	;AN000; MAXIMUM FIELD WITH
	MOV	[SI].MIN_WIDTH,0	;AN000; MINIMUM FIELD WITH

; Set message parameters
	MOV	AX,DISPLAY_S_PATH	;AN000; message number
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,PARM_SUBST_ONE ;AN000; one message substitution
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,NO_INPUT	;AN000; no input
	CALL	PRINT_STDERR		;show source drv,path
	POP	AX			;AN000;
	CALL	SHOW_ERROR_MESSAGE	;display error message

GOTO_MAIN_EXIT:
	JMP	MAIN_EXIT		;restore conditions
					;and exit
QUICK_EXIT:
	JMP	JUST_EXIT		;immediate exit

EEH_EXIT:
	MOV	ERRORLEVEL, 0		;reset errorlevel
	POPF
	POP	CX
	POP	BX
	POP	AX
	POP	ES
	RET

EXTENDED_ERROR_HANDLER ENDP
;


SHOW_ERROR_MESSAGE PROC NEAR
;called immediately after Get_extended error
;This will show simple error message according to error_code in AX
;If the message is not what it wanted, just exit without message- Set carry.
;input: DS - data seg
;output: Carry flag is distroyed.

	clc				;clear carry
	CMP	AX, 5			;access denied?
	JE	ACCESS_DENIED_MESSAGE
	CMP	AX, 4			;too many open files?
	JE	TOO_MANY_OPEN_MESSAGE
	CMP	AX, 31			;general failure?
	JE	GENERAL_FAIL_MESSAGE
	CMP	AX, 32			;sharing violation?
	JE	SHARING_VIOL_MESSAGE
	CMP	AX, 33			;lock violation?
	JE	LOCK_VIOL_MESSAGE
	CMP	AX, 3			;path not found?
	JE	PATH_NOT_MESSAGE
	CMP	AX, 2			;file not found error?
	JE	FILE_NOT_ERR_MESSAGE
	CMP	AX, 65			;access denied on the network?
	JE	ACCESS_DENIED_MESSAGE
	CMP	AX, 82			;no more directory entry to create a file?
	JE	FILE_CREATE_ERR_MESSAGE

	STC				;else set carry


	JMP	GOTO_MAIN_EXIT		;and exit

ACCESS_DENIED_MESSAGE:
	MOV	AX, MSG_ACCESS_DENIED	;AN000;
	JMP	SHORT SHOW_MESSAGE
TOO_MANY_OPEN_MESSAGE:
	MOV	AX, MSG_TOO_MANY_OPEN	;AN000;
	JMP	SHORT SHOW_MESSAGE
GENERAL_FAIL_MESSAGE:
	MOV	AX, MSG_GENERAL_FAIL	;AN000;
	JMP	SHORT SHOW_MESSAGE
SHARING_VIOL_MESSAGE:
	MOV	AX, MSG_SHARING_VIOL	;AN000;
	JMP	SHORT SHOW_MESSAGE
LOCK_VIOL_MESSAGE:
	MOV	AX, MSG_LOCK_VIOL	;AN000;
	JMP	SHORT SHOW_MESSAGE
PATH_NOT_MESSAGE:
	MOV	AX, MSG_PATH_NOT	;AN000;

	JMP	SHORT SHOW_MESSAGE
FILE_NOT_ERR_MESSAGE:
	MOV	AX, MSG_FILE_NOT_ERR	;AN000;
	JMP	SHORT SHOW_MESSAGE
FILE_CREATE_ERR_MESSAGE:
	MOV	AX, MSG_FILE_CREATE_ERR ;AN000;


SHOW_MESSAGE:				; Display error message
; Set message parameters
	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	SUBST_COUNT,NO_SUBST	;AN000; NO message substitution
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,NO_INPUT	;AN000; no input
	CALL	PRINT_STDERR		;AN000; print it
	RET

SHOW_ERROR_MESSAGE ENDP
;


SHOW_S_PATH_FILE_ERR PROC NEAR
;show current source path(drv, full path), and filename to the
;standard error display device.
;input: ds: data seg
	PUSH	ES			;save ES
	PUSH	AX			;save ERROR_CODE
	push	ds
	pop	es			;es = ds
	MOV	DI,OFFSET S_DRV_PATH
	CALL	STRING_LENGTH		;cx got the length
	MOV	SI,OFFSET S_DRV_PATH	;full path of source
	MOV	DI,OFFSET DISP_S_PATH
	REP	MOVSB			;S_DRV_PATH => DISP_S_PATH
	MOV	CX, 13			;max 13 chr
	MOV	SI,OFFSET FILE_DTA.DTA_FILENAME
	MOV	DI,OFFSET DISP_S_FILE
	REP	MOVSB			;dta_filename => disp_s_file

	LEA	SI,SUBLIST1		;AN000; get addressability to list
	LEA	DX,DISP_S_PATH		;AN000; offset to path name
	MOV	[SI].DATA_OFF,DX	;AN000; save offset
	MOV	[SI].DATA_SEG,DS	;AN000; save data segment
	MOV	[SI].MSG_ID,1		;AN000; message ID
	MOV	[SI].FLAGS,010H 	;AN000; ASCIIZ string, left align
	MOV	[SI].MAX_WIDTH,0	;AN000; MAXIMUM FIELD WITH
	MOV	[SI].MIN_WIDTH,0	;AN000; MINIMUM FIELD WITH

	LEA	SI,SUBLIST2		;AN000; get addressability to list
	LEA	DX,DISP_S_FILE		;AN000; offset to file name
	MOV	[SI].DATA_OFF,DX	;AN000; save offset
	MOV	[SI].DATA_SEG,DS	;AN000; save data segment
	MOV	[SI].MSG_ID,2		;AN000; message ID
	MOV	[SI].FLAGS,010H 	;AN000; ASCIIZ string, left align
	MOV	[SI].MAX_WIDTH,0	;AN000; MAXIMUM FIELD WITH
	MOV	[SI].MIN_WIDTH,0	;AN000; MINIMUM FIELD WITH


	CMP	S_DEPTH,0		;AN000;it happened, when dealing with the starting dir?
;	$IF	E
	JNE $$IF226
	    LEA     SI,SUBLIST2 	;AN007;PIONT TO THE FIRST LIST
	    MOV     [SI].MSG_ID,1	;AN007; message ID
	    MOV     AX,DISPLAY_S_PATH	;AC007;ITS ONLY A FILE NAME
	    MOV     SUBST_COUNT,PARM_SUBST_ONE ;AN007; ONE message sub
;	$ELSE
	JMP SHORT $$EN226
$$IF226:
	    LEA     SI,SUBLIST1 	;AN007;PIONT TO THE FIRST LIST
	    MOV     AX,S_PATH_FILE1	;AN000;put '\'
	    MOV     SUBST_COUNT,PARM_SUBST_TWO ;AN007;TWO message subs
;	$ENDIF
$$EN226:

; Set message parameters

	MOV	MSG_NUM,AX		;AN000; set message number
	MOV	MSG_CLASS,UTILITY_MSG_CLASS ;AN000; message class
	MOV	INPUT_FLAG,NO_INPUT	;AN000; no input
	CALL	PRINT_STDERR		;display error message

	POP	AX			;restore ERROR_CODE
	POP	ES
	RET

SHOW_S_PATH_FILE_ERR ENDP
;


CLOSE_DELETE_FILE PROC NEAR
;when writing error occurs, then this routine is called to
;clean up the troubled target file.
;INPUT: DS - buffer seg
;	ES - data seg

	MOV	BX, ES:T_HANDLE 	;close target file
	PUSH	DS			;AN005;SAVE THE BUFFER PTR
	PUSH	ES			;AN005;WE NEED THE DATA PTR
	POP	DS			;AN005;DS = THE DATA PTR
	CALL	CLOSE_A_FILE		;and close the handle
	POP	DS			;AN005;DS = THE BUFFER PTR AGAIN
	LEA	DX, DS:target_drv_let	;target drv, filename
	CALL	DELETE_A_FILE		;delete it
	RET
CLOSE_DELETE_FILE ENDP
;
;

SWITCH_DS_ES PROC NEAR
; switch DS, ES
	PUSH	DS
	PUSH	ES
	POP	DS
	POP	ES
	RET
SWITCH_DS_ES ENDP



MY_INT24:
	CMP	CS:INT24_ABORT_CNT, 0	;if aborted more than once, then just exit.
	JNE	MI_JUST_EXIT
	PUSHF				;we are calling interrupt handler
	CALL	DWORD PTR CS:SAV_INT24	;call original int 24 handler
	CMP	AL, 1			;retry?
	JE	MI_RETRY
	CMP	AL, 0			;ignore? Cannot ignore. Try again
	JE	MI_RETRY
	POP	CX			;remove IP, CS, FLAGS
	POP	CX			;since we are not going back
	POP	CX			;to the place int 24 was called.
	CMP	AL, 2			;abort?
	JE	MI_ABORT
	CMP	AL, 3			;AN000;fail?
	JE	MI_ABORT
	JMP	MAIN_EXIT		;show files copied message
					;restore default value and exit
MI_ABORT:
	INC	CS:INT24_ABORT_CNT	;increase the count of int24_abort
	JMP	MAIN_EXIT_A		;restore default value and exit
MI_JUST_EXIT:
	POP	CX
	POP	CX
	POP	CX
	JMP	JUST_EXIT
MI_RETRY:
	IRET				;return where it happened
					;and retry that operation.
;
INT24_ABORT_CNT DB 0
;
include msgdcl.inc

CSEG	ENDS
DSEG_INIT SEGMENT PARA PUBLIC		;AN000;
DSEG_INIT ENDS				;AN000;
	END	MAIN

