	PAGE,	132			;AN000;
TITLE	XCOPY	WITH FULL MEMORY USE ;AN000;

; ##### R E A D   M E #####
;
; This file contains a copy of the XCOPY code.  The code has been
; Revised (additions and many parts commented out) to conform to the
; needs of SELECT.
;
; #########################

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
;		    A005 DCR0201 10/9/87 Incorperate new format for EXTENDED
;			 ATTRIBUTES.
;
;
;     Label: "DOS XCOPY Utility"
;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Program Property of Microsoft"
;
;****************** END OF SPECIFICATIONS *****************************

CLEAR_SCREEN2	MACRO;AN000;
	MOV	CX,0			;;AN000;
	MOV	DX,184Fh		;;AN000;  scroll screen from (0,0) tO (24,79)
	MOV	AX,0600h		;;AN000;  AH = 6, Scroll Function
					;;  AL = 0, Clear scroll area
	MOV	BH,7			;;AN000;  video I/O interrupt
	INT	10H			;;AN000;
	MOV	DX,0			;;AN000; RKJ-set cursor posn to top right hand corner
	MOV	BH,0			;;AN000; RKJ
	MOV	AH,2			;;AN000; RKJ
	INT	10H			;;AN000; RKJ
	ENDM				;;AN000;
;--------------------------------
;   Include Files
;--------------------------------
INCLUDE STRUC.INC			;AN000; SAR
INCLUDE XMAINMSG.EQU			;AN000;message file
INCLUDE DOS.EQU        ;AN000;
INCLUDE XCOPY.EQU      ;AN000;
INCLUDE PAN-LIST.INC			;AN111;JW
INCLUDE PANEL.MAC			;AN111;JW
INCLUDE CASEXTRN.INC			;AN111;JW


EXTRN	 FK_ENT:BYTE			;AN111;JW
EXTRN	 FK_ENT_LEN:ABS 		;AN111;JW
EXTRN	 E_RETURN:ABS			;AN111;JW
EXTRN	 S_DOS_SHEL_DISK:WORD		;AN111;JW
EXTRN	 S_DOS_SEL_360:WORD		;AN111;JW
EXTRN	 E_FILE_ATTR:ABS		;AN111;JW

EXTRN	 FIND_FILE_ROUTINE:FAR		;AN111;JW
EXTRN	 EXIT_SELECT:near		;AN111;JW

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

HEADER	STRUC		  ;AN000;
	CONTINUE_INFO DB      0 	;AN000;set for filesize bigger then 0FFD0h
	NEXT_PTR DW	 ?		;AN000;next buffer ptr in para
	BEFORE_PTR DW	   ?		;AN000;before ptr in para
	DIR_DEPTH DB	  ?		;AN000;same as S_DEPTH
	CX_BYTES DW	 0		;AN000;actual # of bytes in this buffer seg.
	ATTR_FOUND DB	   ?		;AN000;attribute found
	FILE_TIME_FOUND DW	?;AN000;
	FILE_DATE_FOUND DW	?;AN000;
	LOW_SIZE_FOUND DW      ?;AN000;
	HIGH_SIZE_FOUND DW	?;AN000;
	TARGET_DRV_LET DB      " :"     ;AN000;used for writing
	FILENAME_FOUND DB      13 DUP (0) ;AN000; FILENAME
	ATTRIB_LIST DB	 ?		;AC005;EXTENDED ATTRIBUTE BUFFER
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
HEADER	ENDS	     ;AN000;

;;;;SUB_LIST STRUC		  ; SAR
;;;;	    DB	    11		  ; SAR 	;AN000;
;;;;	    DB	    0		  ; SAR 	;AN000;
;;;;DATA_OFF DW     0		  ; SAR 	;AN000; offset of data to be inserted
;;;;DATA_SEG DW     0		  ; SAR 	;AN000; offset of data to be inserted
;;;;MSG_ID  DB	    0		  ; SAR 	;AN000; n of %n
;;;;FLAGS   DB	    0		  ; SAR 	;AN000; Flags
;;;;MAX_WIDTH DB    0		  ; SAR 	;AN000; Maximum field width
;;;;MIN_WIDTH DB    0		  ; SAR 	;AN000; Minimum field width
;;;;PAD_CHAR DB     0		  ; SAR 	;AN000; character for pad field
;;;;				  ; SAR
;;;;SUB_LIST ENDS		  ; SAR
;******************************************************************************
DATA	SEGMENT BYTE PUBLIC  'DATA'     ;AN000; DATA Segment

INCLUDE  DOSFILES.INC		       ;AN000; SAR

;; ERRORLEVEL DB   0			; SAR	;errorlevel
;; INPUT_DATE DW   0			; SAR
;; INPUT_TIME DW   0			; SAR
PSP_SEG DW	?		   ;AN000;
SAV_DEFAULT_DRV DB ?			;AN000;1 = A, 2 = B etc. saved default
SAV_DEF_DIR_ROOT DB '\';AN000;
SAV_DEFAULT_DIR DB 64 DUP (0);AN000;
SAV_S_DRV DB	'A:\'     ;AN000;
SAV_S_CURDIR DB 64 DUP (0);AN000;
SAV_T_DRV DB	'B:\'     ;AN000;
SAV_T_CURDIR DB 64 DUP (0);AN000;

	PUBLIC SOURCE_PANEL, DEST_PANEL, CHECK_FILE  ;AN111;JW
SOURCE_PANEL DW ?				     ;AN111;JW
DEST_PANEL   DW ?				     ;AN111;JW
CHECK_FILE   DW ?				     ;AN111;JW

SOURCE_IN    DB ?				     ;AN111;JW
YES	     EQU 0				     ;AN111;JW
NO	     EQU 1				     ;AN111;JW

OLD_DTA_SEG  DW ?				     ;AN111;JW
OLD_DTA_OFF  DW ?				     ;AN111;JW

;

;; DISP_S_PATH DB  67 DUP (0)	   ; SAR   ;mirror image of source path. used for display message when copying
;; DISP_S_FILE DB  13 DUP (0)	   ; SAR
;; DISP_T_PATH DB  67 DUP (0)	   ; SAR   ;mirror image of target path
;; DISP_T_FILE DB  13 DUP (0)	   ; SAR
;
;;B_SLASH DB	  '\',0            ; SAR


FILE_COUNT LABEL WORD	  ;AN000;
FILE_CNT_LOW DW 0			;AN000;copied file count
FILE_CNT_HIGH DW 0  ;AN000;
;

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;; APPENDFLAG DW   0			; SAR	 ;append /X status save area
FOUND_FILE_FLAG DB 0			;AN000;used for showing the message "File not found"
;
S_DRV_NUMBER DB 0			;AN000;source, target drv #
T_DRV_NUMBER DB 0   ;AN000;
;
S_DRV_PATH LABEL BYTE			;AN000;source drv, path used for single_drv_copy
S_DRV	DB	'A:\'          ;AN000;
S_PATH	DB	80 DUP (0)		;AN000;Initialized by calling GET CUR DIR
S_DEPTH DB	0	   ;AN000;
S_DRV_1 DB	'A:'       ;AN000;
S_FILE	DB	'????????.???',0        ;AN000;default filename to find file
;; S_DIR   DB	   '????????.???',0     ; SAR   ;to find any subdirectory name

;; S_PARENT DB	   '..',0               ; SAR   ;source parent used for non single_drv_copy
S_HANDLE DW	0			;AN000;file handle opened

;; S_ARC_DRV_PATH LABEL BYTE		   ; SAR ;informations used to change source file's
;; S_ARC_DRV DB    'A:\'                   ; SAR ;archieve bits.
;; S_ARC_PATH DB   64 DUP (0)		   ; SAR
;; S_ARC_DEPTH DB  0			   ; SAR

T_DRV_PATH LABEL BYTE			;AN000;target drv, path used all the time
T_DRV	DB	'B:\'          ;AN000;
T_PATH	DB	64 DUP (0)		;AN000;initialized by calling GET CUR DIR in INIT
T_DEPTH DB	0	   ;AN000;

;; T_FILE  LABEL   BYTE 		; SAR	;target filename for file creation
;; T_DRV_1 DB	   'B:'                 ; SAR   ;target drv letter
;; T_FILENAME DB   13 DUP (0)		; SAR	;target filename
;; T_TEMPLATE DB   11 DUP (0)		; SAR	;if global chr entered, this will be used instead of filename.

;; T_PARENT LABEL  BYTE 		; SAR
;; T_DRV_2 DB	   'B:'                 ; SAR
;; T_PARENT_1 DB   '..',0               ; SAR
T_HANDLE DW	0			;AN000;target handle created
;; T_MKDIR_LVL DB  0			; SAR	;# of target starting directories created.
;
;------------------------------------------
; PRINT_STDOUT input parameter save area
;------------------------------------------
;; SUBST_COUNT DW  0			; SAR	;AN000; message substitution count
;; MSG_CLASS DB    0			; SAR	;AN000; message class
;; INPUT_FLAG DB   0			; SAR	;AN000; Type of INT 21 used for KBD input
;; MSG_NUM DW	   0			; SAR	;AN000; message number

;----------------------------------------------
; Parameter list used by extended open DOS call
;----------------------------------------------
PARAM_LIST LABEL WORD;AN000;
E_A_LST DD	0			;AN005; E A LIST POINTER
	DW	1			;AN005; number of additional parameters
	DB	6			;AN005; ID for IO mode = WORD VALUE
	DW	1			;AN005; IO mode = PURE SEQUENTIAL


;; INPUT_BUFF db   20  dup(0)		; SAR	;AN000; keyboard input buffer used
					;for user response (Y/N)

;--------------------------------------------------------------
; Following three sublists are used by the  Message Retriever
;--------------------------------------------------------------
;;SUBLIST1 LABEL  DWORD 		  ; SAR ;AN000;SUBSTITUTE LIST 1
;;	  DB	  11			  ; SAR ;AN000;sublist size
;;	  DB	  0			  ; SAR ;AN000;reserved
;;	  DD	  0			  ; SAR ;AN000;substition data Offset
;;	  DB	  1			  ; SAR ;AN000;n of %n
;;	  DB	  0			  ; SAR ;AN000;data type
;;	  DB	  0			  ; SAR ;AN000;maximum field width
;;	  DB	  0			  ; SAR ;AN000;minimum field width
;;	  DB	  0			  ; SAR ;AN000;characters for Pad field
;;					  ; SAR
;;					  ; SAR
;;SUBLIST2 LABEL  DWORD 		  ; SAR ;AN000;SUBSTITUTE LIST 2
;;	  DB	  11			  ; SAR ;AN000;sublist size
;;	  DB	  0			  ; SAR ;AN000;reserved
;;	  DD	  0			  ; SAR ;AN000;substition data Offset
;;	  DB	  2			  ; SAR ;AN000;n of %n
;;	  DB	  0			  ; SAR ;AN000;data type
;;	  DB	  0			  ; SAR ;AN000;maximum field width
;;	  DB	  0			  ; SAR ;AN000;minimum field width
;;	  DB	  0			  ; SAR ;AN000;characters for Pad field
;;					  ; SAR
;;					  ; SAR
;;SUBLIST3 LABEL  DWORD 		  ; SAR ;AN000;SUBSTITUTE LIST 3
;;	  DB	  11			  ; SAR ;AN000;sublist size
;;	  DB	  0			  ; SAR ;AN000;reserved
;;	  DD	  0			  ; SAR ;AN000;substition data Offset
;;	  DB	  3			  ; SAR ;AN000;n of %n
;;	  DB	  0			  ; SAR ;AN000;data type
;;	  DB	  0			  ; SAR ;AN000;maximum field width
;;	  DB	  0			  ; SAR ;AN000;minimum field width
;;	  DB	  0			  ; SAR ;AN000;characters for Pad field
;;


FILE_SEARCH_ATTR DW NORM_ATTR;AN000;
;; DIR_SEARCH_ATTR DW INCL_H_S_DIR_ATTR     ; SAR
;
OPEN_MODE DB	Read_Only_Deny_Write	;AN000;READ_ONLY_DENY_WRITE	 ;access, sharing mode
;
;Equates are defined in XCOPY.EQU

MY_FLAG DB	0			;AN000;informations for a tree walk
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

FILE_FLAG DB	0 ;AN000;
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
COPY_STATUS DB	0;AN000;
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
ACTION_FLAG DB	0;AN000;
;	reading_flag	   equ	  01h	;display "Reading source files..."
;	reset_reading	   equ	  0FEh	;do not display.
;
SYS_FLAG DB	0			;AN000;system information
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
OPTION_FLAG DB	0;AN000;
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

MAX_CX	DW	0			;AN000;less than 0FFD0h
ACT_BYTES DW	0			;AN000;actual bytes read.
HIGH_FILE_SIZE DW 0;AN000;
LOW_FILE_SIZE DW 0;AN000;
;
TOP_OF_MEMORY DW 0			;AN000;para
BUFFER_BASE DW	0			;AN000;para
MAX_BUFFER_SIZE DW 0			;AN000;para.	BUFFER_LEFT at INIT time.
BUFFER_LEFT DW	0			;AN000;para
BUFFER_PTR DW	0			;AN000;para. If buffer_left=0 then invalid value
DATA_PTR DW	0			;AN000;buffer_ptr + 2 (32 bytes)
OLD_BUFFER_PTR DW 0			;AN000;last buffer_ptr
SIZ_OF_BUFF DW	?			;AN005;para. EXTENDED ATTRIB BUFF SIZE
BYTS_OF_HDR DW	?			;AN005;bytes TOTAL HEADER SIZE
PARA_OF_HDR DW	?			;AN005;para. TOTAL HEADER SIZE
OPEN_FILE_COUNT DW ?			;AN005;TRACKING OF OPEN FLS FOR BUFFER
;					      ;SIZE CALCULATION.
;
;structured data storage allocation
FILE_DTA Find_DTA <>			;AN000;DTA for find file
DTAS	Find_DTA 32 dup (<>)		;AN000;DTA STACK for find dir
;** Througout the program BP will be used for referencing fieldsname in DTAS.
;For example, DS:[BP].dta_filename.
DATA	ENDS		      ;AN000;

;******************************************************************************

SELECT	    SEGMENT PARA PUBLIC 'SELECT';AN000;
	ASSUME	CS:SELECT, DS:DATA ;AN000;

;--- START OF A PROGRAM ---

PUBLIC	 MOD_XCOPY	    ;AN000;
MOD_XCOPY    PROC    NEAR		     ;AN000; SAR


    PUSH ES				    ;AN000; SAR
    PUSH BP				    ;AN000; SAR
					    ; SAR
    PUSH DS				    ;AN000; SAR
    POP  ES				    ;AN000; SAR
    MOV  SP_SAVE, SP			    ;AN000; SAR
					    ; SAR
    MOV  SOURCE_IN,YES			    ;AN111;JW
    .IF < AL eq 1 >	     ;AN000;
       MOV  AL,2	     ;AN000;
    .ELSEIF < AL eq 2 >      ;AN000;
       MOV  AL,1	     ;AN000;
    .ENDIF		     ;AN000;
    MOV  DEST,AL			    ;AN000; SAR
    MOV  TABLE_OFFSET, BX		    ;AN000; SAR
    MOV  NUMBER_OF_FILES, CX		    ;AN000; SAR
    MOV  PATH_OFFSET, SI		    ;AN000; SAR
    CALL SAVE_DTA	      ;AN000;

    MOV  AH, 62H			    ;AN000; SAR
    INT  21H				    ;AN000; SAR
    MOV  PSP_SEG, BX			    ;AN000; SAR

    CALL ALLOCATE			    ;AN000; SAR
    .IF < C >				    ;AN000; SAR
	 JMP  JUST_EXIT 		    ;AN000; SAR
    .ENDIF				    ;AN000; SAR

XCOPY_INIT:	  ;AN000;
	CALL	INIT			;AN000;initialization
	JC	MAIN_EXIT		;AN000;error. (Already message has been displayed)

	MOV	BP, OFFSET DTAS 	;AN000;initialize BP
	OR	ACTION_FLAG, READING_FLAG ;AN000;set reading flag for copy message

	CALL	TREE_COPY		;AN000;

	CALL	ORG_S_DEF		;AN000;restore the original source default dir

	CALL	WRITE_FROM_BUFFER	;AN000;write from buffer if we missed it.

	CALL	SWITCH_DTAS		;AN111;JW

    CLC 				;AN000; SAR
    JMP  RESTORE_DIRS			;AN000; SAR

MAIN_EXIT:		;AN000;
;;;;;	MOV	BX, DATA		; SAR
;;;;;	MOV	DS, BX			; SAR re initialize ds, es
;;;;;	MOV	ES, BX			; SAR exit here if the status of source, target or default drv has been changed.
;;;;;	CALL	CHK_FILE_NOT_FOUND	; SAR if no files has been found, show the message.

MAIN_EXIT_A:		;AN000;
    STC 				;AN000; SAR

RESTORE_DIRS:;AN000;
	MOV	BX, DATA		;AN000; SAR
	MOV	DS, BX			;AN000;re initialize ds, es
	MOV	ES, BX			;AN000;exit here if the status of source, target or default drv has been changed.
;;;;;	CALL	CHK_MKDIR_LVL		; SAR starting target directory has been created?
    PUSHF				;AN000; SAR
	CALL	ORG_S_T_DEF		;AN000;restore original target, source, default drv, and verify status
    POPF				;AN000; SAR
    JMP  DO_DEALLOCATE			;AN000; SAR
JUST_EXIT:				;AN000;unconditional immediate exit
    MOV  AX, DATA			;AN000; SAR
    MOV  DS, AX 			;AN000; SAR
    STC 				;AN000; SAR

DO_DEALLOCATE:				;AN000; SAR
; Restore the original status of APPEND if active.
    CALL DEALLOCATE			;AN000; SAR
    .IF < NC >				;AN000; SAR
	 .IF < NOT_FOUND_FLAG EQ 1 >	;AN000; SAR
	       STC			;AN000; SAR
	  .ELSE 			;AN000; SAR
	       CLC			;AN000; SAR
	  .ENDIF			;AN000; SAR
    .ENDIF				;AN000; SAR
    MOV  SP, SP_SAVE			;AN000; SAR
    POP  BP				;AN000; SAR
    POP  ES				;AN000; SAR
    RET 				;AN000; SAR

;	MOV	AH, 4Ch 		;return to dos
;	MOV	AL, ERRORLEVEL		;set return code whatever
;	INT	21H

MOD_XCOPY    ENDP;AN000;
;


;----------------- SUBROUTINES ---------------------------------------------

ALLOCATE PROC NEAR			    ;AN000; SAR
					    ; SAR
    MOV  BX, 0FFFFH			    ;AN000; SAR     Attempt to allocate as much as possible
    MOV  AH, 48H			    ;AN000; SAR
    INT  21H				    ;AN000; SAR
    MOV  AH, 48H			    ;AN000; SAR     BX contains the amount of memory available
    INT  21H				    ;AN000; SAR
    MOV  ALLOCATE_START, AX		    ;AN000; SAR
					    ; SAR
    RET 				    ;AN000; SAR
					    ; SAR
ALLOCATE ENDP				    ;AN000; SAR
					    ; SAR
DEALLOCATE    PROC NEAR 		    ;AN000; SAR
					    ; SAR
    PUSHF				    ;AN000; SAR
    PUSH ES				    ;AN000; SAR
    MOV  AX, ALLOCATE_START		    ;AN000; SAR
    MOV  ES, AX 			    ;AN000; SAR
    MOV  AH, 49H			    ;AN000; SAR
    INT  21H				    ;AN000; SAR
    POP  ES				    ;AN000; SAR
    POPF				    ;AN000; SAR
					    ; SAR
    RET 				    ;AN000; SAR
					    ; SAR
DEALLOCATE    ENDP			    ;AN000; SAR




TREE_COPY PROC	NEAR	  ;AN000;

;Walk the source tree to read files and subdirectories

    .IF < DEST EQ 1 >				 ;AN000; SAR Copying to drive b?
	 MOV  SI, OFFSET B_TARGET		 ;AN000; SAR Yes! Copy the drive information
	 MOV  CX, LENGTH_B_TARGET		 ;AN000; SAR
    .ELSEIF < DEST EQ 3 >	    ;AN111;JW	 ; SAR Copying to drive A?
	 MOV  SI, OFFSET A_TARGET   ;AN111;JW	 ; SAR Yes! Copy the drive information
	 MOV  CX, LENGTH_A_TARGET   ;AN111;JW	 ; SAR
    .ELSE					 ;AN000; SAR
	 MOV  SI, PATH_OFFSET			 ;AN000; SAR No! Copy to this directory.
	 MOV  CX, WORD PTR [SI] 		 ;AN000; SAR
	 ADD  SI, 2				 ;AN000; SAR Adjust for the length word
    .ENDIF					 ;AN000; SAR
    MOV     DI,OFFSET T_DRV_PATH		 ;AN000; SAR
    CLD 					 ;AN000; SAR
    REP MOVSB					 ;AN000; SAR



	OR	MY_FLAG, FINDFILE_FLAG	;AN000;deals with files
	OR	MY_FLAG, FIND_FIRST_FLAG ;AN000;find first

    MOV  NOT_FOUND_FLAG, 0				   ;AN000; SAR
							   ; SAR
NEXT_PASS:						   ;AN000; SAR
							   ; SAR
	MOV	SI, TABLE_OFFSET			   ;AN000; SAR
	MOV	DOS_FILE_PTR,SI 			   ;AN000; SAR
	MOV	FILE_NUM,1				   ;AN000; SAR

	CALL	SET_MY_DTA		;AN000;set DTA to FILE_DTA
;	$DO
$$DO1:		  ;AN000;
	    AND     MY_FLAG, RESET_NO_MORE		   ;AN000; SAR
	    CALL    LOAD_DOS_FILENAME			   ;AN000; SAR
	    TEST    MY_FLAG, NO_MORE_FILE		   ;AN000; SAR
;	$LEAVE NZ					   ; SAR
	JNZ $$EN1			      ;AN000;

	    .IF < SOURCE_IN EQ NO > AND       ;AN000;
	    .IF < DEST EQ 3 >		      ;AN000;
	       CALL GET_SOURCE		      ;AN000;
	    .ENDIF			      ;AN000;

	    CALL    FIND_FILE		;AN000;find first (next) ; SAR
	    .IF < BIT MY_FLAG NAND NO_MORE_FILE >	   ;AN000; SAR
		 CALL	READ_INTO_BUFFER		   ;AN000; SAR
	    .ELSE					   ;AN000; SAR
		 MOV	NOT_FOUND_FLAG, 1		   ;AN000; SAR
	    .ENDIF					   ;AN000; SAR
;	$ENDDO						   ; SAR
	JMP SHORT $$DO1   ;AN000;
$$EN1:		   ;AN000;
	CLC						   ;AN000; SAR

;   SAR 
;;;;;;	TEST	OPTION_FLAG, SLASH_S	;walk the tree?
;	$IF	NZ,LONG
;
;	    AND     MY_FLAG, RESET_FINDFILE ;now, deals with directory
;	    OR	    MY_FLAG, FIND_FIRST_FLAG ;find first
;	    $DO
;		CALL	SET_MY_DTA	;set DTA to DTAS according to BP
;		CALL	FIND_DIR	;find first (next)
;		TEST	MY_FLAG, NO_MORE_FILE ;no more subdirectory?
;	    $LEAVE  NZ			;then leave this loop to return to caller
;		LEA	DI, S_DRV_PATH
;		LEA	SI, [BP].DTA_FILENAME
;		CMP	S_PATH, 0	;root directory?
;		$IF	E
;		    MOV     AL, 0FFh	;then '\' is already provided. Just concat.
;		$ELSE
;		    MOV     AL, PATH_DELIM ;put delimiter
;		$ENDIF
;		CALL	CONCAT_ASCIIZ	;make new path
;		test	option_flag, slash_p ;prompt mode?
;		$IF	NZ
;		    call    p_concat_display_path
;		$ENDIF
;		INC	S_DEPTH 	;increase depth
;		CALL	MAKE_HEADER	;make header in the buffer
;		OR	MY_FLAG, IS_SOURCE_FLAG ;dealing with source
;		AND	MY_FLAG, RESET_VISIT_PARENT ;going to visit child node
;		CALL	CHANGE_S_DIR	;change source dir
;		ADD	BP, type FIND_DTA ;increase DTAS stack pointer
;		CALL	TREE_COPY	;tree copy the sub directory
;	    $ENDDO
;
;	    CMP     S_DEPTH, 0		;starting directory? then exit
;	    $IF     NE			;else
;		DEC	S_DEPTH 	;dec depth
;		TEST	OPTION_FLAG, SLASH_E ;copy subdirectories even if empty?
;		$IF	Z
;		    CALL    DEL_EMPTY	;then check the old_buffer_ptr and
;					;if it is a directory, then restore
;					;buffer_ptr to old.
;		$ENDIF
;		LEA	DI, S_DRV_PATH
;		CALL	LAST_DIR_OUT	;change environments
;		test	option_flag, slash_p ;prompt mode?
;		$IF	NZ
;		    call    p_cut_display_path
;		$ENDIF
;		LEA	DX, S_DRV_PATH	;before returning to the caller
;		OR	MY_FLAG, IS_SOURCE_FLAG
;		OR	MY_FLAG, VISIT_PARENT_FLAG
;		CALL	CHANGE_S_DIR
;		SUB	BP, type FIND_DTA
;	    $ENDIF
;;;;;;; $ENDIF				;walk the tree
	RET	    ;AN000;
TREE_COPY ENDP;AN000;


GET_SOURCE	PROC	NEAR;AN000;

	CALL SWITCH_DTAS;AN000;

	.REPEAT     ;AN000;

	   INIT_PQUEUE		PAN_INST_PROMPT 		;AN000; initialize queue
	   PREPARE_PANEL	SOURCE_PANEL			;AN000; remove select from A: & insert DOS
	   PREPARE_PANEL	PAN_HBAR			;AN000;
	   PREPARE_CHILDREN					;AN000; prepare child panels
	   DISPLAY_PANEL					;AN000;
								;
	   GET_FUNCTION 	FK_ENT				;AN000;

	   .IF < SOURCE_PANEL eq SUB_REM_DOS_A >		;AN000;
	      LEA  DI, S_DOS_SEL_360				;AN000;
	   .ELSE						;AN000;
	      LEA  DI, S_DOS_SHEL_DISK				;AN000;
	   .ENDIF						;AN000;
	   MOV	CX, E_FILE_ATTR 				;AN000;
	   CALL FIND_FILE_ROUTINE				;AN000;
	   .LEAVE < nc >					;AN000;
								;
	   HANDLE_ERROR 	ERR_DOS_DISK, E_RETURN		;AN000;
								;
	.UNTIL							;AN000;

	;;;copying files from diskette 1 screen 		;
	INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	PREPARE_PANEL		SUB_COPYING			;AN000; prepare copying from diskette 1 message
	DISPLAY_PANEL						;AN000;

	MOV  SOURCE_IN,YES ;AN000;

	CALL SWITCH_DTAS   ;AN000;

	RET		   ;AN000;
GET_SOURCE	ENDP	 ;AN000;

GET_DEST	PROC	NEAR  ;AN000;


	INIT_PQUEUE	     PAN_INST_PROMPT		     ;AN000; initialize queue
	PREPARE_PANEL	     DEST_PANEL 		     ;AN000; remove select from A: & insert DOS
	PREPARE_PANEL	     PAN_HBAR			     ;AN000;
	PREPARE_CHILDREN				     ;AN000; prepare child panels
	DISPLAY_PANEL					     ;AN000;
							     ;
	GET_FUNCTION	     FK_ENT			     ;AN000;
								;

	;;;copying files from diskette 1 screen 		;
	INIT_PQUEUE		PAN_INSTALL_DOS 		;AN000; initialize queue
	PREPARE_PANEL		SUB_COPYING			;AN000; prepare copying from diskette 1 message
	DISPLAY_PANEL						;AN000;

	MOV  SOURCE_IN,NO  ;AN000;
;	SUB  DOS_FILE_PTR,12
;	DEC  FILE_NUM

	RET		   ;AN000;
GET_DEST	ENDP	   ;AN000;
;
;******************************************************************************
; Subroutine: LOAD_DOS_FILENAME - Load the next filename into S_FILE.
; INPUT:
;	 SI - Points to the start of the filename
;
; OUTPUT:
;	 The S_FILE field in the data segment is updated.
;Registers Affected:
;	 SI - At the end, SI points to the end of the filename.  It therefore
;	      also points to the beginning of the next filename.
;
;******************************************************************************
LOAD_DOS_FILENAME	PROC	NEAR;AN000;

	PUSH	DI	      ;AN000;
	PUSH	ES	      ;AN000;

	OR	MY_FLAG, FIND_FIRST_FLAG	;AN000; Find first in the directory

	MOV	SI,DOS_FILE_PTR 	;AN000;

LDF_SEE_IF_DONE:	     ;AN000;
	;
	; See if we are finished this pass of the files
	;
    OR	 MY_FLAG, NO_MORE_FILE			 ;AN000; For now, assume there are not files found
    MOV  DX, NUMBER_OF_FILES			 ;AN000; Get the number of files in the table
    .IF < FILE_NUM BE DX >			 ;AN000; Search while there are still more files
	 AND  MY_FLAG, RESET_NO_MORE   ;AN000; Indicate that there are more files
	 LEA  DI,S_FILE 	       ;AN000; Where to put the name
	 MOV  CX,12		       ;AN000; Number of bytes
	 CLD		    ;AN000;
	 REP  MOVSB	    ;AN000;
	 INC  FILE_NUM	    ;AN000;
    .ENDIF	     ;AN000;

     MOV     DOS_FILE_PTR,SI		     ;AN000; Save the pointer to the files
     POP     ES 		   ;AN000;
     POP     DI 		   ;AN000;
     RET			   ;AN000;

LOAD_DOS_FILENAME	ENDP		 ;AN000;
;
READ_INTO_BUFFER PROC NEAR	   ;AN000;
;Read *** a *** file	into buffer

;   SAR 
;	TEST	MY_FLAG, SINGLE_COPY_FLAG ;single copy?
;	$IF	Z,AND			;no, multi copy
;	TEST	ACTION_FLAG, READING_FLAG ;show message?
;	$IF	NZ			;yes.
;	    MOV     AX,MSG_READING_SOURCE ;AN000; message number
;	    MOV     MSG_NUM,AX		;AN000; set message number
;	    MOV     SUBST_COUNT,0	;AN000; no message substitution
;	    MOV     MSG_CLASS,-1	;AN000; message class
;	    MOV     INPUT_FLAG,0	;AN000; no input
;	    MOV     AX,MSG_READING_SOURCE
;	    CALL    PRINT_STDOUT	;show message "Reading source files"
;
;	    AND     ACTION_FLAG, RESET_READING ;reset it
;;;;;;; $ENDIF

	AND	FILE_FLAG, RESET_READFILE ;AN000;reset file_flag to read a file
	MOV	AX,FILE_DTA.DTA_FILE_SIZE_HIGH;AN000;
	MOV	HIGH_FILE_SIZE, AX	  ;AN000;
	MOV	AX,FILE_DTA.DTA_FILE_SIZE_LOW;AN000;
	MOV	LOW_FILE_SIZE, AX	  ;AN000;

	MOV	AX, PARA_OF_HDR 	;AN005;GET THE HEADER SIZE (para.)
	CMP	MAX_BUFFER_SIZE,AX	;AN005;IS EA BUFFER TOO LARGE?
	JB	RIB_ERROR		;AN005;CLOSE THE FILE AND GET THE NEXT

	CALL	CMP_FILESIZE_TO_BUFFER_LEFT ;AN000;compare sizes
	TEST	FILE_FLAG, FILE_BIGGER_FLAG ;AN000;filesize > buffer_left - header?
	JZ	RIB_SMALL		;AN000;if not, then small file
	MOV	BX, S_HANDLE		;AN005;
	CALL	CLOSE_A_FILE		;AN005;ONLY OPENED TO GET BUFFER SIZE
	CALL	WRITE_FROM_BUFFER;AN000;

	.IF < SOURCE_IN EQ NO > AND	;AN111;JW
	.IF < DEST EQ 3 >		;AN111;JW
	   CALL GET_SOURCE		;AN111;JW  put source diskette in A:
	.ENDIF				;AN111;JW

;	JC	RIB_ERROR		;any problem with writing?
	CALL	CMP_FILESIZE_TO_BUFFER_LEFT ;AN000;compare again
	TEST	FILE_FLAG, FILE_BIGGER_FLAG ;AN000;still bigger?
	JNZ	RIB_BIG 		;AN000;yes.  Big file
RIB_SMALL:     ;AN000;
	CALL	SMALL_FILE;AN000;
	JC	RIB_ERROR  ;AN000;
	JMP	RIB_EXIT  ;AN000;
RIB_BIG:       ;AN000;
	MOV	BX, S_HANDLE		;AN005;
	CALL	CLOSE_A_FILE		;AN005;ONLY OPENED TO GET BUFFER SIZE
	CALL	BIG_FILE      ;AN000;
	JNC	RIB_EXIT       ;AN000;
RIB_ERROR:	    ;AN000;
	TEST	COPY_STATUS, OPEN_ERROR_FLAG ;AN000;open error?
	JNZ	RIB_EXIT		;AN000;just exit. find next file
	MOV	BX, S_HANDLE		;AN000;else write error
	CALL	CLOSE_A_FILE		;AN000;close the troubled file
					;and find next file
RIB_EXIT:	    ;AN000;
	TEST	MY_FLAG, SINGLE_COPY_FLAG ;AN000;single copy?
;	$IF	NZ
	JZ $$IF4		       ;AN000;
	    CALL    WRITE_FROM_BUFFER	;AN000;then write a file
;	$ENDIF
$$IF4:			       ;AN000;
	RET			      ;AN000;
READ_INTO_BUFFER ENDP	       ;AN000;
;

SMALL_FILE PROC NEAR	       ;AN000;
;handles a file smaller than max_buffer_size or buffer_left, i.e. fit in memory.
;This routine will call MAKE_HEADER, SET_BUFFER_PTR< READ_A_FILE, OPEN_A_FIEL
;CALC_FILE_SIZE, CMP_FILE_FFD0h, CLOSE_A_FILE.

	TEST	FILE_FLAG, BIG_FILE_FLAG ;AN000;called from BIG_FILE?
	JNZ	SMF_CONT		;AN000;then need not open a file again
	CALL	OPEN_A_FILE		;AN000;open a file using FILE_DTA
	JC	SMF_ERROR		;AN000;open error?
SMF_CONT:      ;AN000;
	CALL	CMP_FILE_FFD0h		;AN000;filesize > 0FFD0h ?
	TEST	FILE_FLAG, FILE_BIGGER_FLAG;AN000;
	JZ	SMF_EOF 		;AN000;filesize <= 0FFD0h
	OR	FILE_FLAG, CONT_FLAG	;AN000;filesize > 0FFD0h. set cont_flag
	MOV	CX, 0FFD0h		;AN000;# of bytes to read
	CALL	READ_A_FILE;AN000;
	JC	SMF_ERROR		;AN000;unsuccessful read?
	CALL	MAKE_HEADER		;AN000;else make header and ready for next
	CALL	CALC_FILE_SIZE		;AN000;filesize = filesize - bytes read
	JMP	SMF_CONT		;AN000;loop. compare again with the rest

SMF_EOF:       ;AN000;
	MOV	CX, LOW_FILE_SIZE	;AN000;rest of the bytes to read
	OR	FILE_FLAG, EOF_FLAG	;AN000;set EOF
	CALL	READ_A_FILE	  ;AN000;
	JC	SMF_ERROR	    ;AN000;
	CALL	MAKE_HEADER	  ;AN000;
	MOV	BX, S_HANDLE	   ;AN000;
	CALL	CLOSE_A_FILE	  ;AN000;
	JMP	SMF_EXIT	   ;AN000;
SMF_ERROR:		;AN000;
					;
SMF_EXIT:		;AN000;
	RET		       ;AN000;
SMALL_FILE ENDP 	;AN000;
;

BIG_FILE PROC	NEAR	  ;AN000;
;handles a file which is bigger than max_buffer_size
;Needs 2 file handles open concurrently for read and write

	OR	FILE_FLAG, BIG_FILE_FLAG;AN000;
	OR	FILE_FLAG, CONT_FLAG;AN000;
	CALL	OPEN_A_FILE	  ;AN000;
	JC	BIF_ERROR		;AN000;error in open?
	CMP	MAX_BUFFER_SIZE, 0FFFh	;AN000;max buffer size > 0FFFh in para ?
	JA	BIF_BIG 		;AN000;yes. large buffer system
					;else small buffer
	MOV	CX, MAX_CX		;AN000;CX = max_buffer_size * 16 - 32
BIF_SM: 	 ;AN000;
	CALL	READ_A_FILE;AN000;
	JC	BIF_ERROR		;AN000;read error?
	CALL	MAKE_HEADER;AN000;
	CALL	WRITE_FROM_BUFFER;AN000;
	JC	BIF_ERROR		;AN000;write error?
	TEST	FILE_FLAG, EOF_FLAG	;AN000;end of file set by READ_A_FILE?
	JZ	BIF_SM			;AN000;if not, read again
	MOV	BX, S_HANDLE;AN000;
	CALL	CLOSE_A_FILE;AN000;
	JMP	BIF_EXIT		;AN000;finished.
BIF_BIG:       ;AN000;
	MOV	CX, 0FFD0h		;AN000;max # of data bytes this program supports
BIF_BIG1:	 ;AN000;
	CALL	READ_A_FILE;AN000;
	JC	BIF_ERROR    ;AN000;
	CALL	MAKE_HEADER;AN000;
	CALL	CALC_FILE_SIZE		;AN000;modify file size
BIF_BIG2:	      ;AN000;
	CALL	CMP_FILESIZE_TO_BUFFER_LEFT ;AN000;filesize > buffer_left?
	TEST	FILE_FLAG, FILE_BIGGER_FLAG ;AN000;yes.
	JZ	BIF_END 		;AN000;if it is not, call small_file
	CMP	BUFFER_LEFT, 0FFFh	;AN000;BUFFER_LEFT >= 0FFF0h in bytes?
	JAE	BIF_BIG 		;AN000;then loop again.
	CMP	BUFFER_LEFT, 140H	;AN000;else BUFFER_LEFT >= 5 K in bytes? ;minimum buffer size this program supports.
	JL	BIF_BIG3		;AN000;then flush buffer and try again. **IF system buffer left < 5 K then infinit loop can happen.
	MOV	AX,BUFFER_LEFT;AN000;
	SUB	AX,PARA_OF_HDR		;AC005;FOR HEADER SIZE para.
	MOV	CX,BYTS_OF_HDR		;AN005;FOR HEADER SIZE bytes.
	JMP	BIF_BIG1		;AN000;read again
BIF_BIG3:      ;AN000;
	CALL	WRITE_FROM_BUFFER;AN000;
	JC	BIF_ERROR  ;AN000;
	JMP	BIF_BIG2		;AN000;flush buffer and compare again.
BIF_END:       ;AN000;
	CALL	SMALL_FILE		;AN000;when filesize <= buffer_left then SMALL_FILE will finish it.
	JC	BIF_ERROR		;AN000;something wrong?
	CALL	WRITE_FROM_BUFFER	;AN000;else finish copying this file
	JNC	BIF_EXIT	   ;AN000;
BIF_ERROR:		;AN000;
					;what happened?
BIF_EXIT:		;AN000;
	RET		       ;AN000;
BIG_FILE ENDP		;AN000;
;
MAKE_HEADER PROC NEAR	;AN000;
;When called by READ_A_FILE after the data had been read into the buffer, this
;routine will put the header which is just below the data area where the
;current BUFFER_PTR points.  The header is 32 (2 para) byte long. And this
;routine will also call SET_BUFFER_PTR to set the BUFFER_PTR, BUFFER_LEFT
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
	PUSH	ES			;AN000;save ES
	PUSH	AX   ;AN000;

MH_AGAIN:  ;AN000;
	MOV	AX,BUFFER_PTR		;AN000;buffer_ptr is a segment
	MOV	ES, AX			;AN000;now, ES is a header seg.
;
	MOV	AX, PARA_OF_HDR 	;AN005;GET THE HEADER SIZE (para.)
	CMP	BUFFER_LEFT,AX		;AC005;buffer_left=less than NEEDED?
	JAE	MH_START	;AN000;
	CALL	WRITE_FROM_BUFFER	;AN000;if so, flush buffer
	JC	MH_ERROR_BRIDGE 	;AN000;write error?
	JMP	SHORT MH_AGAIN		;AN000;reinitialize ES to new buffer ptr
MH_START:	     ;AN000;
	TEST	MY_FLAG, FINDFILE_FLAG	;AN000;identify caller.
	JNZ	MH_FILE 		;AN000;if a file, jmp to MH_FILE
					;else deals with directory.
	MOV	ES:CONTINUE_INFO, 0	;AN000;not a continuation.
	MOV	AX,OLD_BUFFER_PTR   ;AN000;
	MOV	ES:BEFORE_PTR, AX	;AN000;set before_ptr in header
	MOV	AX,BUFFER_PTR	  ;AN000;
	MOV	OLD_BUFFER_PTR, AX	;AN000;set variable OLD_BUFFER_PTR
	ADD	AX,PARA_OF_HDR		;AC005;AX = BUFFER_PTR+HEADER(para)
	MOV	BUFFER_PTR, AX		;AN000;set new BUFFER_PTR
	MOV	ES:NEXT_PTR, AX 	;AN000;set NEXT_PTR in the header
	MOV	AX, PARA_OF_HDR 	;AN005;GET THE HEADER SIZE (para.)
	SUB	BUFFER_LEFT,AX		;AC005;adjust BUFFER_LEFT
	CMP	BUFFER_LEFT,AX		;AC005;less than HEADER SIZE (para) ?
;	$IF	B
	JNB $$IF6	    ;AN000;
	    MOV     BUFFER_LEFT, 0	;AN000;indicate buffer_full
;	$ENDIF
$$IF6:			    ;AN000;
	MOV	AL, S_DEPTH	       ;AN000;
	MOV	ES:DIR_DEPTH, AL	;AN000;now save other info's
	MOV	AL, DS:[BP].DTA_ATTRIBUTE;AN000;
	MOV	ES:ATTR_FOUND, AL	;AN000;in this case, DIR
	MOV	AL, BYTE PTR T_DRV;AN000;
	MOV	ES:TARGET_DRV_LET, AL	;AN000;mov target drive letter
	MOV	ES:TARGET_DRV_LET+1, DRV_delim ;AN000; ':'
	MOV	CX, 13			       ;AN000;
	LEA	SI, [BP].DTA_FILENAME	;AN000;DS:SI
	MOV	DI, OFFSET ES:FILENAME_FOUND ;AN000;ES:DI
	REP	MOVSB			;AN000;mov sting until cx = 0
	JMP	MH_EXIT ;AN000;
MH_ERROR_BRIDGE: JMP MH_ERROR;AN000;
MH_FILE:				;AN000;handles a file header hereafter.
	TEST	FILE_FLAG, CONT_FLAG	;AN000;continuation?
	JZ	MH_WHOLE_FILE		;AN000;no, just a whole file
	TEST	FILE_FLAG, EOF_FLAG	;AN000;Eof flag set?
	JNZ	MH_CONT_END		;AN000;yes, must be end of continuation
	TEST	FILE_FLAG, BIG_FILE_FLAG ;AN000;Is this a big file?
	JNZ	MH_BIG			;AN000;yes
	MOV	ES:CONTINUE_INFO, 1	;AN000;else small file continuation.
	JMP	MH_A_FILE	    ;AN000;
MH_WHOLE_FILE:		 ;AN000;
	MOV	ES:CONTINUE_INFO, 0 ;AN000;
	JMP	MH_A_FILE	    ;AN000;
MH_CONT_END:		 ;AN000;
	MOV	ES:CONTINUE_INFO, 3 ;AN000;
	JMP	MH_A_FILE	    ;AN000;
MH_BIG: 		 ;AN000;
	MOV	ES:CONTINUE_INFO, 2 ;AN000;
MH_A_FILE:		 ;AN000;
	MOV	AX,FILE_DTA.DTA_FILE_TIME;AN000;
	MOV	ES:FILE_TIME_FOUND, AX;AN000;
	MOV	AX, FILE_DTA.DTA_FILE_DATE;AN000;
	MOV	ES:FILE_DATE_FOUND, AX;AN000;
	MOV	AX, FILE_DTA.DTA_FILE_SIZE_LOW;AN000;
	MOV	ES:LOW_SIZE_FOUND, AX;AN000;
	MOV	AX, FILE_DTA.DTA_FILE_SIZE_HIGH;AN000;
	MOV	ES:HIGH_SIZE_FOUND, AX;AN000;
	MOV	AL, BYTE PTR T_DRV  ;AN000;
	MOV	ES:TARGET_DRV_LET, AL;AN000;
	MOV	ES:TARGET_DRV_LET+1, DRV_DELIM;AN000;
	MOV	CX, 13		    ;AN000;
	MOV	SI, OFFSET FILE_DTA.DTA_FILENAME;AN000;
	MOV	DI, OFFSET ES:FILENAME_FOUND;AN000;
	REP	MOVSB		    ;AN000;

; Get Extended Attribute list of the opened file and save in attribute buff.

; old method
;	MOV	AX,INT_ORDINAL		;AN000; SET THE ORDINAL TO 0
;	MOV	ES:QUERY_LIST,AX	;AN000; PUT IT IN THE BUFFER
;	MOV	AX,SIZ_OF_BUFF		;AN000; SET THE SIZE TO 510 BYTES
;	MOV	ES:BUFR_SIZ,AX		;AN000; PUT IT IN THE BUFFER
;
;	MOV	BX,S_HANDLE		;AN000; BX = handle
;	MOV	AX, QUY_ATTRIB		;AN000; extended attribute code 5703H
;	MOV	DI, OFFSET QUERY_LIST	;AN000; ES:DI-->QUERY list
;	INT	21H			;AN000; get extended attribute list
;
	MOV	BX,S_HANDLE		;AN005; BX = handle
	MOV	SI,ALL_ATTR		;AN005; SELECT ALL ATTRIBUTES SIZE
	MOV	CL, PARAGRAPH		;AN005; PARAGRAPH = 4 FOR DIV BY 16
	MOV	AX,SIZ_OF_BUFF		;AN005; GET THE SIZE EXPRESSED IN para.
	SHL	AX, CL			;AN005; GET # OF BYTES FROM para.
	MOV	CX, AX			;AN005; NEEDS TO BE IN CX
	MOV	DI, OFFSET ES:ATTRIB_LIST ;AN005; ES:DI = E A LIST IN BUFFER
	MOV	AX, GET_ATTRIB		;AN005; extended attribute code 5702H
	INT	21H			;AN005; get extended attribute list

;	JC	MH_ERROR		;AN000; jump if error

	MOV	AX, OLD_BUFFER_PTR;AN000;
	MOV	ES:BEFORE_PTR, AX;AN000;
	MOV	AX, ACT_BYTES;AN000;
	MOV	ES:CX_BYTES, AX;AN000;
	CALL	SET_BUFFER_PTR		;AN000;set buffer_ptr for next. AX is already set.
	MOV	AX, BUFFER_PTR	 ;AN000;
	MOV	ES:NEXT_PTR, AX 	;AN000;next buffer_ptr is next_ptr
	MOV	AL, S_DEPTH	 ;AN000;
	MOV	ES:DIR_DEPTH, AL	;AN000;same as source depth
	MOV	AL, FILE_DTA.DTA_ATTRIBUTE;AN000;
	MOV	ES:ATTR_FOUND, AL	;AN000;attribute found
	JMP	MH_EXIT 		;AN000;
MH_ERROR:      ;AN000;
	OR	COPY_STATUS, OPEN_ERROR_FLAG ;AN000;
	CALL	EXTENDED_ERROR_HANDLER	;AN000;
MH_EXIT:		     ;AN000;
	POP	AX			;AN000;
	POP	ES			;AN000;
	RET			    ;AN000;
MAKE_HEADER ENDP	     ;AN000;
;

OPEN_A_FILE PROC NEAR	     ;AN000;

;-------------------------------------------------------------------------
; Use extended open DOS call to open source file,
; if successfully open, then save filehand to S_HANDLE.
;-------------------------------------------------------------------------
; Set  drive letter and file name pointer in parameter list
	LEA	SI,FILE_DTA.DTA_FILENAME ;AN005; DS:SI-->NAME TO OPEN
	MOV	DX,OPN_FLAG		;AN000; flag = 0101H
	MOV	CX,OPN_ATTR		;AN000; attribute = 0
	MOV	BX,OPN_MODE		;AN000; open mode = 0002H
	MOV	DI, NUL_LIST		;AN005; ES:DI = -1
	MOV	AX, Ext_Open		;AN000; = 6Ch
	INT	21H			;AN000; OPEN SOURCE FILE

	JC	OF_ERROR;AN000;
	MOV	S_HANDLE, AX		;AN000;save filehandle
	INC	OPEN_FILE_COUNT 	;AN005;UPDATE THE OPEN FILE COUNTER


	JMP	OF_EXIT 		;AN000; exit

OF_ERROR:      ;AN000;
	OR	COPY_STATUS, OPEN_ERROR_FLAG;AN000;
	CALL	EXTENDED_ERROR_HANDLER;AN000;
OF_EXIT:       ;AN000;
	RET	      ;AN000;
OPEN_A_FILE ENDP;AN000;
;


CMP_FILE_FFD0h PROC NEAR;AN000;
;check whether the filesize in HIGH_FILE_SIZE, LOW_FILE_SIZE is bigger than
;0FFD0h.  If it is, then set FILE_BIGGER_FLAG, else reset it.
	CMP	HIGH_FILE_SIZE, 0;AN000;
;	$IF	E,AND
	JNE $$IF8     ;AN000;
	CMP	LOW_FILE_SIZE, 0FFD0h;AN000;
;	$IF	BE
	JNBE $$IF8    ;AN000;
	    AND     FILE_FLAG, RESET_FILE_BIGGER ;AN000;filesize <= 0FFD0h
;	$ELSE
	JMP SHORT $$EN8 			 ;AN000;
$$IF8:					  ;AN000;
	    OR	    FILE_FLAG, FILE_BIGGER_FLAG   ;AN000;
;	$ENDIF
$$EN8:					  ;AN000;
	RET					 ;AN000;
CMP_FILE_FFD0h ENDP			  ;AN000;
;

CALC_FILE_SIZE PROC NEAR		  ;AN000;
;subtract the bytes read (ACT_BYTES) from the filesize in HIGH_FILE_SIZE,
;LOW_FILE_SIZE.
	MOV	AX, ACT_BYTES			     ;AN000;
	SUB	LOW_FILE_SIZE, AX		     ;AN000;
	SBB	HIGH_FILE_SIZE, 0		     ;AN000;
	RET					 ;AN000;
CALC_FILE_SIZE ENDP			  ;AN000;
;

READ_A_FILE PROC NEAR			  ;AN000;
;read a file.
;if after reading, AX < CX or AX = 0 the set EOF_FLAG.
;INPUT:CX - # of bytes to read
;      BUFFER_PTR
;      S_HANDLE
;OUTPUT: ACT_BYTES

;	.IF < SOURCE_IN EQ NO > AND
;	.IF < DEST EQ 3 >
;	   CALL GET_SOURCE
;	.ENDIF

	PUSH	DS			;AN000;save program data seg
	MOV	AH, Read;AN000;
	MOV	BX, S_HANDLE;AN000;
	MOV	DX, BUFFER_PTR		;AN000;current buffer header seg
	ADD	DX, PARA_OF_HDR 	;AC005;skip the header part
	MOV	DS, DX			;AN000;now DS = buffer_ptr + 2, data area
	XOR	DX, DX			;AN000;offset DX = 0
	INT	21H	 ;AN000;
	POP	DS			;AN000;restore program data area
	JC	RF_ERROR		;AN000;read error?
	CMP	AX, CX	 ;AN000;
	JE	RF_OK	  ;AN000;
	OR	FILE_FLAG, EOF_FLAG	;AN000;EOF reached. AX = 0 or AX < CX
RF_OK:			;AN000;
	CLC				;AN000;clear carry caused from CMP
	MOV	ACT_BYTES, AX		;AN000;save actual bytes read
	JMP	RF_EXIT        ;AN000;
RF_ERROR:	    ;AN000;
	OR	COPY_STATUS, READ_ERROR_FLAG;AN000;
	CALL	EXTENDED_ERROR_HANDLER;AN000;
RF_EXIT:	    ;AN000;
	RET		   ;AN000;
READ_A_FILE ENDP    ;AN000;
;

FIND_IT PROC	NEAR   ;AN000;
;set first or next depending on FIND_FIRST_FLAG.
;once called, reset FIND_FIRST_FLAG.
	TEST	MY_FLAG, FIND_FIRST_FLAG;AN000;
;	$IF	NZ			;yes
	JZ $$IF11	   ;AN000;
	    MOV     AH, Find_First;AN000;
;	$ELSE
	JMP SHORT $$EN11   ;AN000;
$$IF11: 	    ;AN000;
	    MOV     AH, Find_Next;AN000;
;	$ENDIF
$$EN11: 	    ;AN000;
	AND	MY_FLAG, RESET_FIND_FIRST ;AN000;reset FIND_FIRST_FLAG
	INT	21H			  ;AN000;
	RET			      ;AN000;
FIND_IT ENDP		       ;AN000;
;
FIND_FILE PROC	NEAR		;AN000;
;find a file
;set NO_MORE_FILE if carry.
;	$SEARCH

;	PUSH	DS
;	MOV	DX,DATA
;	MOV	DS,DX
;	.IF < SOURCE_IN EQ NO > AND
;	.IF < DEST EQ 3 >
;	   CALL GET_SOURCE
;	.ENDIF
;	POP	DS

$$DO14: 		       ;AN000;
	    TEST    MY_FLAG, FIND_FIRST_FLAG ;AN000;find first ?
;	    $IF     NZ
	    JZ $$IF15			     ;AN000;
		MOV	DX, OFFSET S_FILE		;AN000;
		MOV	CX, File_Search_Attr ;AN000;normal = 0
;	    $ELSE
	    JMP SHORT $$EN15	  ;AN000;
$$IF15: 		   ;AN000;
		MOV	DX, OFFSET FILE_DTA  ;AN000;
;	    $ENDIF
$$EN15: 		   ;AN000;
	    CALL    FIND_IT	  ;AN000;
;	$EXITIF C
	JNC $$IF14		  ;AN000;
	    OR	    MY_FLAG, NO_MORE_FILE ;AN000;no more file in this directory
;	$ORELSE
	JMP SHORT $$SR14		 ;AN000;
$$IF14: 			  ;AN000;
	    MOV     FOUND_FILE_FLAG, 1	;AN000;set the flag for "File not found" msg.
	    OR	    MY_FLAG,  FOUND_FLAG	 ;AN000; SAR
;;;;;;;     CALL    FILTER_FILES	;found. filter it with options
	    TEST    MY_FLAG, FOUND_FLAG  ;AN000;
;	$ENDLOOP NZ			;if found, leave this loop else start again
	JZ $$DO14			 ;AN000;
	    AND     MY_FLAG, RESET_NO_MORE;AN000;
;	$ENDSRCH
$$SR14: 			  ;AN000;
	RET				 ;AN000;
FIND_FILE ENDP			  ;AN000;
;
SET_MY_DTA PROC NEAR		  ;AN000;
;set DS:DX for find_first(next). If MY_FLAG is set to FINDFILE_FLAG then
;set it to the offset FILE_DTA, otherwise to BP.
;DS should be set to the area whre FILE_DTA, DTAS are.
	PUSH	DX			;AN000;save current DX
	TEST	MY_FLAG, FINDFILE_FLAG	;AN000;handling file?
;	$IF	NZ
	JZ $$IF22		    ;AN000;
	    MOV     DX, OFFSET FILE_DTA;AN000;
;	$ELSE
	JMP SHORT $$EN22	    ;AN000;
$$IF22: 		     ;AN000;
	    MOV     DX, BP	    ;AN000;
;	$ENDIF
$$EN22: 		     ;AN000;
	MOV	AH, Set_DTA		;AN000;
	INT	21H			;AN000;
	POP	DX			;AN000;
	RET			    ;AN000;
SET_MY_DTA ENDP 	     ;AN000;
;
;
SAVE_DTA PROC NEAR	     ;AN000;
; Save old DTA address
	PUSH	ES		       ;AN000;
	PUSH	BX		       ;AN000;
	MOV	AH, Get_DTA		;AN000;
	INT	21H			;AN000;
	MOV	OLD_DTA_SEG,ES		;AN000;
	MOV	OLD_DTA_OFF,BX		;AN000;
	POP	BX			;AN000;
	POP	ES			;AN000;
	RET			    ;AN000;
SAVE_DTA ENDP		     ;AN000;
;
;
SWITCH_DTAS PROC NEAR	     ;AN000;
; SWITCH DTA ADDRESSES
	 PUSH DS		    ;AN000;
	 PUSH DX		    ;AN000;
	 PUSH OLD_DTA_SEG	    ;AN000;
	 PUSH OLD_DTA_OFF	    ;AN000;
	 CALL SAVE_DTA		    ;AN000;
	 POP  DX		    ;AN000;
	 POP  DS		    ;AN000;
	 MOV  AH, Set_DTA	    ;AN000;
	 INT  21H		    ;AN000;
	 POP  DX		    ;AN000;
	 POP  DS		    ;AN000;
SWITCH_DTAS ENDP	     ;AN000;
;
;
CHANGE_T_DIR PROC NEAR	     ;AN000;
;change target dir according to t_drv_path.
;Since this routine is called by WRITE_FROM_BUFFER and DS now points
;to buffer area while ES points to the program data area, we set DS
;to data seg again here for the function call Chdir.
	PUSH	DS			;AN000;save current buffer seg
	PUSH	ES			;AN000;currentpy es is a data seg
	POP	DS			;AN000;restore DS value as program data seg

	CMP	T_DRV[2], 0		;AN000;LAST_DIR_OUT took '\' out?
;	$IF	E
	JNE $$IF25	 ;AN000;
	    MOV     T_DRV[2], '\'       ;AN000;then put it back for root dir
	    MOV     T_DRV[3], 0 	;AN000;
;	$ENDIF
$$IF25: 			 ;AN000;

	MOV	DX, OFFSET T_DRV_PATH	    ;AN000;
	MOV	AH, CHDIR		    ;AN000;
	INT	21H			    ;AN000;

	POP	DS			;AN000;restore caller's DS value
	RET	 ;AN000;
CHANGE_T_DIR ENDP;AN000;
;

CMP_FILESIZE_TO_BUFFER_LEFT PROC NEAR;AN000;
;Compare buffer_left (paragraph) with filesize (high_file_size, low_file_size.)
;if filesize is bigger than buffer_left, then set FILE_BIGGER_FLAG
;indicating filesize > buffer_left.
	PUSH	DX  ;AN000;
	PUSH	AX  ;AN000;

	CMP	OPEN_FILE_COUNT,NUL	;AN005;ARE THERE ANY OPEN FILES
;	$IF	Z			;AN005;NO, THEN GO AHEAD AND OPEN
	JNZ	$$IF28A 	    ;AN000;
	    CALL    OPEN_A_FILE 	;AN005;OPEN A FILE USING FILE_DTA

; Get extended Attribute list size.

	    MOV     BX,S_HANDLE 	;AN005; BX = handle
	    MOV     AX, GET_ATTRIB	;AN005; extended attribute code 5702H
	    MOV     SI,ALL_ATTR 	;AN005; SELECT ALL ATTRIBUTES SIZE
	    XOR     CX,CX		;AN005; JUST QUERY SIZE NEEDED
	    MOV     DI, OFFSET NUL_LIST ;AN005; DI = LIST FOR NO DATA RETURNED
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
	    MOV     BX,S_HANDLE 	;AN005;
	    CALL    CLOSE_A_FILE	;AN005;CLOSE THE FILE OPENED
;	$ENDIF
$$IF28A:		  ;AN000;

	AND	FILE_FLAG, RESET_FILE_BIGGER;AN000;
	MOV	AX,PARA_OF_HDR		;AN005;GET THE HEADER SIZE (para.)
	CMP	BUFFER_LEFT,AX		;AC005;buffer_left >= HEADER SIZE
;	$IF	AE
	JNAE $$IF27	    ;AN000;
	    MOV     AX, BUFFER_LEFT	;AN000;buffer_left in para
	    SUB     AX,PARA_OF_HDR	;AC005;consider header size in advance
	    MOV     CX, 16	   ;AN000;
	    MUL     CX			;AN000;* 16. result in DX;AX
	    CMP     HIGH_FILE_SIZE, DX;AN000;
;	    $IF     A			;if high_filesize > dx
	    JNA $$IF28	 ;AN000;
		OR	FILE_FLAG, FILE_BIGGER_FLAG;AN000;
;	    $ELSE
	    JMP SHORT $$EN28;AN000;
$$IF28: 	  ;AN000;
;		$IF	E
		JNE $$IF30	;AN000;
		    CMP     LOW_FILE_SIZE, AX;AN000;
;		    $IF     A
		    JNA $$IF31	;AN000;
			OR	FILE_FLAG, FILE_BIGGER_FLAG;AN000;
;		    $ENDIF
$$IF31: 	  ;AN000;
;		$ENDIF
$$IF30: 	  ;AN000;
;	    $ENDIF
$$EN28: 	  ;AN000;
;	$ELSE
	JMP SHORT $$EN27 ;AN000;
$$IF27: 	  ;AN000;
	    OR	    FILE_FLAG, FILE_BIGGER_FLAG ;AN000;buffer_left < 2
;	$ENDIF
$$EN27: 				;AN000;
	POP	AX				   ;AN000;
	POP	DX				   ;AN000;
	RET				       ;AN000;
CMP_FILESIZE_TO_BUFFER_LEFT ENDP	;AN000;
;

SET_BUFFER_PTR PROC NEAR		;AN000;
;set BUFFER_PTR, BUFFER_LEFT, OLD_BUFFER_PTR in paragraph boundary
;to be used when reading a file into buffer.
;this routine uses current BUFFER_PTR to figure out the next BUFFER_PTR.
;So, at initialization time set BUFFER_PTR to CS, and set AX to the offset
;of INIT,  then thr resultant BUFFER_PTR indicates the BUFFER_BASE and
;OLD_BUFFER_PTR indicates CS.(This means if old_buffer_ptr = cs, then
;it is the start of buffer)
;To get the next BUFFER_PTR during multi-copy, just set the AX to the
;number of bytes read. This routine will add 32 bytes for header size and
;will set the next BUFFER_PTR.
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

	PUSH	CX				  ;AN000;
	MOV	CX, BUFFER_PTR			   ;AN000;
	MOV	OLD_BUFFER_PTR, CX	;AN000;set old_buffer_ptr
	MOV	CL, 4		   ;AN000;
	SHR	AX, CL			;AN000;get paragraphs
	INC	AX			;AN000;get next paragraph
	ADD	AX,PARA_OF_HDR		;AC005;consider header size
	ADD	BUFFER_PTR, AX		;AN000;add this to the current buffer_ptr

;	$IF	NC,AND			;not exceed 16 bit.
	JC $$IF37	    ;AN000;
	MOV	AX, Top_of_memory;AN000;
	SUB	AX, BUFFER_PTR		;AN000;AX = Top_of_memory - Buffer_ptr
;	$IF	A			;if buffer_left > 0
	JNA $$IF37	    ;AN000;
	    MOV     BUFFER_LEFT, AX;AN000;
;	$ELSE
	JMP SHORT $$EN37    ;AN000;
$$IF37: 	     ;AN000;
	    MOV     BUFFER_LEFT, 0	;AN000;indication of buffer full
;	$ENDIF
$$EN37: 		    ;AN000;
	POP	CX		       ;AN000;
	RET			   ;AN000;
SET_BUFFER_PTR ENDP	    ;AN000;
;

WRITE_FROM_BUFFER PROC NEAR ;AN000;
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
	PUSH	DS		      ;AN000;
	PUSH	ES			;AN000;save ds, es

	PUSH	DS   ;AN000;
	POP	ES			;AN000;set ES to program data seg

	OR	ACTION_FLAG, READING_FLAG ;AN000;show reading message next time
;	AND	ES:MY_FLAG, RESET_IS_SOURCE	;now, deals with target
					;set this for change_dir
	MOV	AX, ES:BUFFER_BASE	 ;AN000;
	MOV	DS, AX			 ;AN000;
	PUSH	CS			;AN000;
	POP	AX			 ;AN000;
	CMP	ES:OLD_BUFFER_PTR, AX	;AN000;if old_buffer_ptr = CS then
					;buffer is empty. Just exit
	JE	WFB_EXIT_BRIDGE        ;AN000;

	PUSH	DS		     ;AN000;
	MOV	DX,DATA 	      ;AN000;
	MOV	DS,DX		      ;AN000;
	.IF < DEST eq 3 >	  ;AN000;
	   CALL GET_DEST	  ;AN000;
	.ENDIF			  ;AN000;
	POP	DS		      ;AN000;

WFB_CD: 		   ;AN000;
	CALL	CHANGE_T_DIR	     ;AN000;
	JC	WFB_ERROR_BRIDGE	;AN000;error?
WFB_CHATT:	     ;AN000;
	CMP	DS:ATTR_FOUND, Is_subdirectory ;AN000;a subdirectory? = 10H
	JNE	WFB_FILE		;AN000;no. a file

WFB_CMP_DEPTH: ;AN000;
;   SAR  
;;;;;;;
;	MOV	AH, ES:T_DEPTH		;yes. a subdir.
;	CMP	DS:DIR_DEPTH, AH	;DIR_DEPTH > T_DEPTH ?
;	JBE	WFB_DEC_DEPTH		;if not, go to parent node
;	LEA	DI, ES:T_DRV_PATH	;else goto child node
;	LEA	SI, DS:FILENAME_FOUND
;	CMP	ES:T_PATH, 0		;root directory?
;	$IF	E
;	    MOV     AL, 0FFh		;then don't need to put delim since it is already there
;	$ELSE
;	    MOV     AL, Path_delim	;path_delim '\'
;	$ENDIF
;	CALL	CONCAT_ASCIIZ
;	call	concat_display_path	;modify the path for display
;	INC	ES:T_DEPTH
;	CALL	MAKE_DIR		;try to make a new sub directory
;	JC	WFB_EXIT_A_BRIDGE	;there exists a file with same name.
;	MOV	AX, DS			;current buffer seg = old_buffer_ptr?
;	CMP	ES:OLD_BUFFER_PTR, AX
;	JNE	WFB_NEXT		;not finished yet. jmp to next
;	OR	ES:MY_FLAG, MISSING_LINK_FLAG ;Finished. Missing link condition occurred regarding empty sub dir
;	JMP	WFB_EXIT_A		;check archieve options.
WFB_NEXT:      ;AN000;
;	MOV	DS, DS:NEXT_PTR 	;let's handles next header.
;	JMP	WFB_CD			;change directory first.
WFB_EXIT_BRIDGE: JMP WFB_EXIT;AN000;
WFB_ERROR_BRIDGE: JMP WFB_ERROR;AN000;
WFB_EXIT_A_BRIDGE: JMP WFB_EXIT_A;AN000;
WFB_DEC_DEPTH: ;AN000;
;	LEA	DI, ES:T_DRV_PATH
;	CALL	RM_EMPTY_DIR		;check flags and remove empty dir
;	CALL	LAST_DIR_OUT		;take off the last dir from path
;	call	cut_display_path	;modify path for display purpose
;;;;;;	DEC	ES:T_DEPTH		;and decrease depth
	JMP	WFB_CD			;AN000;CHANGE DIR AND compare the depth again.


WFB_FILE:				;AN000;Handling a file
	AND	ES:MY_FLAG, RESET_MISSING_LINK ;AN000;if found a file, then current dir is not empty.
	TEST	ES:FILE_FLAG, CREATED_FLAG ;AN000; A file handle is created ?
	JNZ	WFB_WRITE		;AN000;yes, skip create again.
	CALL	CREATE_A_FILE		;AN000;create a file in the cur dir
	JC	WFB_ERROR		;AN000;file creation error?
WFB_WRITE:     ;AN000;
	CALL	WRITE_A_FILE;AN000;
	JC	WFB_EXIT_A		;AN000;target file has been already deleted.
	CMP	DS:CONTINUE_INFO, 0;AN000;
;	$IF	E,OR			;if continue_info = 0 or 3
	JE $$LL40      ;AN000;
	CMP	DS:CONTINUE_INFO, 3;AN000;
;	$IF	E
	JNE $$IF40     ;AN000;
$$LL40: 	;AN000;
	    MOV     BX, ES:T_HANDLE;AN000;
	    CALL    SET_FILE_DATE_TIME	;AN000;then set file's date, time
	    PUSH    DS			;AN005;SAVE THE BUFFER PTR
	    PUSH    ES			;AN005;WE NEED THE DATA PTR
	    POP     DS			;AN005;DS = THE DATA PTR
	    CALL    CLOSE_A_FILE	;AN000;and close the handle
	    POP     DS			;AN005;DS = THE BUFFER PTR AGAIN
;;;;;;;     CALL    RESTORE_FILENAME_FOUND ; SAR  if filename_found has been changed, restore it for reset_s_archieve.
	    AND     ES:FILE_FLAG, RESET_CREATED ;AN000;and reset created_flag
	    CALL    INC_FILE_COUNT	;AN000;increase file count
;	$ENDIF
$$IF40: 		    ;AN000;
	MOV	AX, DS		       ;AN000;
	CMP	ES:OLD_BUFFER_PTR, AX	;AN000;current header is the last one?
	JE	WFB_EXIT_A		;AN000;then exit
	MOV	DS, DS:NEXT_PTR 	;AN000;else set ds to the next ptr
	JMP	WFB_CHATT		;AN000;handle the next header
WFB_ERROR:	;AN000;
	jmp	main_exit		;AN000;meaningful when MKDIR failed because
					;of there already exist same named file,
					;or disk_full case.
WFB_EXIT_A:	;AN000;
	test	ES:option_flag, slash_m ;AN000;hard archieve ? - turn off source archieve bit.
	jz	wfb_exit_B		;AN000;no, chk error flag and exit
;;;;	call	reset_s_archieve	; SAR reset source file(s) archieve bit using header info(s).
WFB_EXIT_B:	;AN000;
	test	ES:copy_status, mkdir_error_flag ;AN000;mkdir error happened?
	JNZ	WFB_ERROR		;AN000;yes, exit
	test	ES:copy_status, disk_full_flag ;AN000;disk full happened?
	JNZ	WFB_ERROR		;AN000;yes, exit
WFB_EXIT:	;AN000;
	MOV	ES:OLD_BUFFER_PTR, CS	;AN000;set old_buffer_ptr to CS
	MOV	AX, ES:BUFFER_BASE    ;AN000;
	MOV	ES:BUFFER_PTR, AX	;AN000;set buffer_ptr to base
	MOV	AX, ES:MAX_BUFFER_SIZE;AN000;
	MOV	ES:BUFFER_LEFT, AX	;AN000;set buffer_left
	POP	ES		   ;AN000;
	POP	DS		   ;AN000;
;;;;	TEST	SYS_FLAG, ONE_DISK_COPY_FLAG ; SAR one drive letter copy?
;  ;	$IF	NZ			     ; SAR yes
;  ;	    CALL    CHANGE_S_DIR	     ; SAR then change current dir to s dir
;;;;	$ENDIF
	RET		       ;AN000;
WRITE_FROM_BUFFER ENDP	;AN000;
;
INC_FILE_COUNT PROC NEAR;AN000;
;increase the file count by one.
;increase file_cnt_low, file_cnt_high.
;input: DS - buffer
;	ES - data seg
	INC	ES:FILE_CNT_LOW    ;AN000;
	JNZ	IFC_EXIT	   ;AN000;
	INC	ES:FILE_CNT_HIGH	;AN000;if carry over, then inc file_cnt_high
IFC_EXIT:	      ;AN000;
	RET		     ;AN000;
INC_FILE_COUNT ENDP   ;AN000;
;
CREATE_A_FILE PROC NEAR;AN000;
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

	PUSH	DS		;AN000;
	PUSH	ES		;AN000;

;    SAR 			;save the original filename from the header
;;;;;	MOV	CX, 13			;max 13 chr
;	LEA	SI, DS:FILENAME_FOUND	;original source file name
;	LEA	DI, ES:DISP_S_FILE	;filename to be displayed
;	REP	MOVSB			;filename_found => disp_s_file
;;;;;	test	es:option_flag, slash_p ; SAR
;;;;;	$IF	Z			; SAR
;;;;;	    CALL    SHOW_COPY_MESSAGE	; SAR  he source path, file
;;;;;	$ENDIF				; SAR
;
;	CMP	ES:T_FILENAME, 0
;	$IF	NE			;non_global target filename entered.
;	    TEST    ES:COPY_STATUS, MAYBE_ITSELF_FLAG
;	    $IF     NZ
;		LEA	SI, DS:FILENAME_FOUND
;		LEA	DI, ES:T_FILENAME
;		CALL	COMP_FILENAME	;compare it. if same then show
;					;file cannot be copied onto itself and
;					;abort
;	    $ENDIF
;
;	    CALL    SWITCH_DS_ES	;now ds - data, es - buffer
;	    MOV     CX, 13
;	    LEA     SI, DS:T_FILENAME
;	    LEA     DI, ES:FILENAME_FOUND
;	    REP     MOVSB		; t_filename => filename_found
;	    CALL    SWITCH_DS_ES	;now ds - buffer, es - data seg
;
;	$ELSE
;	    CMP     ES:T_TEMPLATE, 0	;global chr target filename entered?
;	    $IF     NE			;yes, entered. modify the filename found
;;;;;		CALL	MODIFY_FILENAME ; SAR
;		TEST	ES:COPY_STATUS, MAYBE_ITSELF_FLAG
;		$IF	NZ
;		    LEA     SI, DS:FILENAME_FOUND ;compare the Revised filename
;		    LEA     DI, ES:DISP_S_FILE ;with original name
;		    CALL    COMP_FILENAME ;if same, then issue error message and exit
;		$ENDIF
;	    $ELSE
;		TEST	ES:COPY_STATUS, MAYBE_ITSELF_FLAG ;*.* CASE
;		$IF	NZ
;		    PUSH    ES
;		    POP     DS		;ds - data seg
;
;					; Set message parameters
;;;;;		    MOV     AX,MSG_COPY_ITSELF	 ; SAR
;		    MOV     MSG_NUM,AX		 ; SAR ;AN000; set message number
;		    MOV     SUBST_COUNT,0	 ; SAR	AN000; no message subst.
;		    MOV     MSG_CLASS,-1	 ; SAR	AN000; message class
;		    MOV     INPUT_FLAG,0	 ; SAR	AN000; no user input
;		    CALL    PRINT_STDERR	 ; SAR	AN000; display error
;		    JMP     MAIN_EXIT
;		$ENDIF
;	    $ENDIF
;;;;;;	$ENDIF

;-------------------------------------------------------------------------
; Use extended open DOS call to create the target file, use attribute list
; obtained from the previous Get Extended attribute DOS call
;-------------------------------------------------------------------------

; SET ATTRIBUTE LIST POINTER IN PARAMETER LIST
	MOV	DX, OFFSET DS:ATTRIB_LIST ;AN005;E A BUFFER IN HEADER
	MOV	WORD PTR ES:E_A_LST,DX	;AN005; set offset
	MOV	WORD PTR ES:E_A_LST+WORD,DS ;AN005; set segment

	MOV	AX, Ext_Open		;AN000; = 6Ch
	MOV	DX,CREATE_FLAG		;AN000; flag = 0111H
	MOV	BX,CREATE_MODE		;AN000;CREATE MODE = 0011H
	MOV	CX,CREATE_ATTR		;AN000; attribute = 0
	MOV	SI,OFFSET TARGET_DRV_LET ;AN005; DS:SI-->NAME TO CREATE
	LEA	DI,ES:PARAM_LIST	;AN005;PARAMETER LIST (ES:DI)
	INT	21H			;AN000; create file

	JC	CAF_ERROR		;AN000;
	MOV	ES:T_HANDLE, AX 	;AN000;save handle

;;;;;	CALL	CHK_T_RES_DEVICE	; SAR check target handle is a reserved dev

	OR	ES:FILE_FLAG, CREATED_FLAG ;AN000;set created_flag
	JMP	CAF_EXIT		  ;AN000;
CAF_ERROR:		       ;AN000;
	PUSH	DS			 ;AN000;
	PUSH	ES			 ;AN000;
	POP	DS			  ;AN000;
	OR	COPY_STATUS, CREATE_ERROR_FLAG;AN000;
	CALL	EXTENDED_ERROR_HANDLER	 ;AN000;
	POP	DS			  ;AN000;
CAF_EXIT:		       ;AN000;
	POP	ES			  ;AN000;
	POP	DS			  ;AN000;
	RET			      ;AN000;
CREATE_A_FILE ENDP	       ;AN000;
;
;COMP_FILENAME PROC NEAR
;;this routine is called when MAYBE_COPY_ITSELF flag in on.
;;SI, DI asciiz string will be compared and if they are identical
;;the show "Cannot copy onto itself" msg and jmp to main_exit.
;;INPUT: DS - buffer
;;	 ES - data seg
;
;	 CLD
;	 MOV	 AL, 0
;	 PUSH	 DI			 ;save DI
;	 CALL	 STRING_LENGTH		 ;CX get the length of string
;	 MOV	 BX, CX 		 ;now, BX got the length of the target filename entered.
;	 PUSH	 BX			 ;save BX
;	 PUSH	 ES			 ;save ES
;
;	 PUSH	 DS
;	 POP	 ES			 ;now ES set to DS
;	 PUSH	 SI
;	 POP	 DI			 ;now DI points to the source filename found.
;
;	 MOV	 AL, 0
;	 CALL	 STRING_LENGTH		 ;CX got the length of the string
;
;	 POP	 ES			 ;restore ES
;	 POP	 BX			 ;restore BX
;	 POP	 DI			 ;restore DI
; ;;
;	 CMP	 BX, CX 		 ;COMPARE LENGTH
;	 JNE	 CF_EXIT		 ;IF THEY ARE DIFFERENT, EXIT
;
;	 REPE	 CMPSB			 ;compare SI, DI until not equal,
;	 CMP	 CX, 0			 ;finish at cx = 0?
;	 JE	 CF_SAME
;	 JMP	 SHORT CF_EXIT
;CF_SAME:
;	 PUSH	 ES
;	 POP	 DS			 ;ds = data seg
;
;; Set message parameters
;;;;;;	 MOV	 AX,MSG_COPY_ITSELF	 ; SAR ;AN000; message number
;;	 MOV	 MSG_NUM,AX		 ; SAR	AN000; set message number
;;	 MOV	 SUBST_COUNT,0		 ; SAR	AN000; no message substitution
;;	 MOV	 MSG_CLASS,-1		 ; SAR	AN000; message class
;;;	  MOV	  INPUT_FLAG,0		  ; SAR  AN000; no input
;;	 CALL	 PRINT_STDERR		 ; SAR	AN000; display error message
;	 JMP	 MAIN_EXIT
;CF_EXIT:
;	 RET
;COMP_FILENAME ENDP
;;
WRITE_A_FILE PROC NEAR	       ;AN000;
;write a file from the data area in the buffer.
;Remember the caller is WRITE_FROM_BUFFER which use ES for
;the program data area and DS for the header in the buffer.
	MOV	AH, Write		;AN000; = 40h
	MOV	BX, ES:T_HANDLE 	;AN000;handle saved in the program data area
	MOV	DX, ES:BYTS_OF_HDR	;AC005;skip header
	MOV	CX, DS:CX_BYTES 	;AN000;get the # from the header
	INT	21h		 ;AN000;
	JC	WAF_ERROR		;AN000;write error
	CMP	AX, DS:CX_BYTES;AN000;
	JNE	WAF_DISKFULL;AN000;
	JMP	WAF_EXIT  ;AN000;
WAF_ERROR:     ;AN000;
	CALL	CLOSE_DELETE_FILE	;AN000;close delete troubled file
	OR	COPY_STATUS, WRITE_ERROR_FLAG;AN000;
	CALL	SWITCH_DS_ES		;AN000;DS = DATA SEG, ES = BUFFER
	CALL	EXTENDED_ERROR_HANDLER;AN000;
	CALL	SWITCH_DS_ES		;AN000;ES = DATA SEG, DS = BUFFER
WAF_DISKFULL:	    ;AN000;
;	MOV	ERRORLEVEL, 4		; SAR ;set errorlevel

; Set message parameters
; Target disk full, critical error

	PUSH	DS			;AN000;DS = BUFFER
	PUSH	ES			;AN000;ES = DATA SEG
	POP	DS			;AN000;ES => DS = DATA SEG
;;;;;	MOV	AX,MSG_DISK_FULL	; SAR	  ;AN000; message number
;	MOV	MSG_NUM,AX		; SAR	  AN000; set message number
;	MOV	SUBST_COUNT,0		; SAR	  AN000; no message substitution
;	MOV	MSG_CLASS,UTILITY_MSG_CLASS ; SAR AN000; message class
;	MOV	INPUT_FLAG,0		; SAR	  AN000; no input
;	CALL	PRINT_STDERR		; SAR	  AN000; display error message
	OR	COPY_STATUS, DISK_FULL_FLAG ;AN000;set disk_full_flag
	POP	DS			;AN000;RESTORE DS = BUFFER
	CALL	CLOSE_DELETE_FILE;AN000;
	STC				;AN000;set carry and return to caller
WAF_EXIT:;AN000;
	RET    ;AN000;
WRITE_A_FILE ENDP;AN000;
;
SET_FILE_DATE_TIME PROC NEAR;AN000;
;input: BX - target file handle
;
	MOV	AH, File_date_time	;AN000; = 57h
	MOV	AL, Set_file_time	;AN000; = 1
	MOV	CX, DS:FILE_TIME_FOUND;AN000;
	MOV	DX, DS:FILE_DATE_FOUND;AN000;
	INT	21h		  ;AN000;
	RET		      ;AN000;
SET_FILE_DATE_TIME ENDP;AN000;
;
CLOSE_A_FILE PROC NEAR ;AN000;
;INPUT: BX - file handle to be closed
	CMP	OPEN_FILE_COUNT,NUL	;AN005;ARE THERE ANY OPEN FILES?
;	$IF	A			;AN005;
	JNA	$$IF42A 	    ;AN000;
	    DEC     OPEN_FILE_COUNT	;AN005;IF SO, REDUCE THE COUNT BY 1.
;	$ENDIF				;AN005;
$$IF42A:		     ;AN000;
	MOV	AH, Close	    ;AN000; = 3Eh
	INT	21H	      ;AN000;
	RET		  ;AN000;
CLOSE_A_FILE ENDP  ;AN000;
;
DELETE_A_FILE PROC NEAR;AN000;
;input: DS:DX - points to ASCIIZ string

	MOV	AH, 41h 		;AN000; = 41h
	INT	21H	  ;AN000;
	RET	      ;AN000;
DELETE_A_FILE ENDP;AN000;
;
;
;CHK_DISK_FULL PROC NEAR
;check target disk space, and if no more clusters then set carry, disk_full_flag.
;this routine is called by MAKE_DIR routine.
;INPUT: DS - buffer
;	ES - data seg
;	 PUSH	 AX
;	 PUSH	 BX
;	 PUSH	 CX
;	 PUSH	 DX
;	 MOV	 AH, 36h		 ;GET DISK FREE SPACE
;	 MOV	 DL, ES:T_DRV_NUMBER	 ;OF TARGET
;	 INT	 21h
;	 CMP	 BX, 0			 ;NO MORE CLUSTER?
;	 JE	 CDF_FULL
;	 CLC
;	 JMP	 SHORT CDF_EXIT
;CDF_FULL:
;	 OR	 ES:COPY_STATUS, DISK_FULL_FLAG ;SET DISK FULL FLAG
;	 STC				 ;SET CARRY
;CDF_EXIT:
;	 POP	 DX
;	 POP	 CX
;	 POP	 BX
;	 POP	 AX
;	 RET
;
;CHK_DISK_FULL ENDP
;;
;;subttl  string_length
;page
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
;STRING_LENGTH PROC NEAR
;PUBLIC  STRING_LENGTH
;	 CLD				 ;CLEAR DIRECTION
;	 MOV	 BX,DI			 ;SAVE ORIGINAL DI VALUE
;	 MOV	 CX,80H 		 ;TRY MAX 128 BYTES
;	 REPNE	 SCASB			 ;SCAN THE STRING UNTIL FOUND
;	 PUSH	 DI			 ;SAVE CURRENT DI VALUE WHICH POINTS TO NEXT CHR AFTER STRING
;	 SUB	 DI,BX			 ;GET THE LENGTH
;	 MOV	 CX,DI			 ;MOV THE LENGTH TO CX
;	 POP	 DI
;	 RET
;STRING_LENGTH ENDP
;
;subttl  concat_asciiz
;page
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
;CONCAT_ASCIIZ PROC NEAR
;
;PUBLIC  CONCAT_ASCIIZ
;	 PUSH	 DI			 ;SAVE POINTER VALUE WHICH WILL BE RETRUNED TO CALLER.
;	 PUSH	 AX			 ;SAVE VALUE IN AL.
;	 MOV	 AL, 0			 ;DEALING WITH ASCIIZ STRING
;	 CALL	 STRING_LENGTH		 ;LET DI POINTS TO THE NEXT CHR AFTER THIS STRING
;					 ;DIRECTION WILL BE CLEARED.
;	 DEC	 DI			 ;MAKE DI POINT TO THE LAST CHARACTER 0
;	 POP	 AX			 ;RESTORE AL.
;	 CMP	 AL, 0FFh
;;	 $IF	 NE			 ;IF THE USER WANTS TO PUT DIMIMETER,
;	 JE $$IF42
;	     STOSB			 ;  REPLACE 0 WITH IT.
;;	 $ELSE
;	 JMP SHORT $$EN42
;$$IF42:
;	     DEC     CX 		 ;ELSE DECREASE LENGTH BY 1
;;	 $ENDIF
;$$EN42:
;;	 $DO
;$$DO45:
;	     LODSB			 ;MOV [SI] TO AL
;	     STOSB			 ;STORE AL TO [DI]
;	     INC     CX 		 ;INCREASE LENGTH
;	     CMP     AL, 0		 ;WAS IT A LAST CHARACTER?
;;	 $ENDDO  E			 ;THEN EXIT THIS LOOP
;	 JNE $$DO45
;	 POP	 DI
;	 RET
;CONCAT_ASCIIZ ENDP
;;
;
;subttl  last_dir_out
;page
;******************************************************************************
;PURPOSE: Take off the last directory name from the path pointed by DI.
;	  This routine assumes the pattern of a path to be an ASCIIZ string
;	  in the form of "[d:][\]dir1\dir2".  Notice that this path does not
;	  have entailing "\".   This routine will simply travel the string
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
;
;LAST_DIR_OUT PROC NEAR
;PUBLIC  LAST_DIR_OUT
;
;	 PUSH	 DI
;	 PUSH	 SI			 ;save current DI, SI
;	 CLD				 ;clear direction
;	 MOV	 SI, 0FFFFh		 ;used as a not_found flag if unchanged.
;;	 $DO
;$$DO47:
;	     MOV     AL, 0
;	     SCASB
;;	 $LEAVE  Z			 ;if [DI] = 0, then end of string. Ends this loop.
;	 JZ $$EN47
;	     DEC     DI 		 ;if [DI] <> 0, then go back and scan char again
;	     MOV     AL, "\"             ;to see it was a back slash.
;	     SCASB
;;	     $IF     Z			 ;if it was, then save the addr to SI.
;	     JNZ $$IF49
;		 PUSH	 DI
;		 POP	 SI
;
;		 DEC	 SI
;;	     $ENDIF			 ;else do loop again.
;$$IF49:
;;	 $ENDDO
;	 JMP SHORT $$DO47
;$$EN47:
;	 CLC				 ;clear carry flag.
;	 CMP	 SI, 0FFFFh		 ;Had SI been changed?
;;	 $IF	 E
;	 JNE $$IF52
;	     STC			 ;No, set the carry. Not found.
;;	 $ELSE
;	 JMP SHORT $$EN52
;$$IF52:
;	     MOV     BYTE PTR ES:[SI], 0 ;Yes, replace "\" with 0. Seg override to get default DI seg.
;	     MOV     AX, SI
;	     INC     AX 		 ;let AX have the last dir offset value.
;	     CLC			 ;clear carry
;;	 $ENDIF
;$$EN52:
;	 POP	 SI			 ;restore original value
;	 POP	 DI			 ;original string offset
;	 RET
;LAST_DIR_OUT ENDP
;;
;
SET_DEFAULT_DRV PROC NEAR;AN000;
;change source drv as a default drv for conveniece of find, read operation
;of source. (handling target should be more specific as for as drive letter
;goes.)
;input: DL - drive # (0 = A, 1 = B ...)

	MOV	AH, Select_Disk 	;AN000; = 0Eh
	INT	21H		 ;AN000;
	OR	SYS_FLAG, DEFAULT_DRV_SET_FLAG ;AN000;indicates default drv has been changed
					;Used for exit the program to restore default drv
	RET				  ;AN000;
SET_DEFAULT_DRV ENDP		   ;AN000;
;
ORG_S_DEF PROC	NEAR		    ;AN000;
;restore the original source directory.
	PUSH	ES			     ;AN000;
	PUSH	DS			     ;AN000;

	PUSH	DS			     ;AN000;
	POP	ES			;AN000;DS=ES=data seg

	TEST	SYS_FLAG, DEFAULT_S_DIR_FLAG ;AN000;source default direcotry saved?
;	$IF	NZ
	JZ $$IF55			  ;AN000;
	    MOV     DX, OFFSET SAV_S_DRV ;AN000;saved source drive letter & directory
	    MOV     AH, 3Bh		 ;AN000;
	    INT     21h 		;AN000;restore source
	    AND     SYS_FLAG, RESET_DEFAULT_S_DIR ;AN000;reset the flag
;	$ENDIF
$$IF55: 				   ;AN000;

	POP	DS				      ;AN000;
	POP	ES				      ;AN000;

	RET					  ;AN000;
ORG_S_DEF ENDP				   ;AN000;
;
ORG_S_T_DEF PROC NEAR			   ;AN000;
;retore original target, source and default drv and directory
;check default_s(t)_dir_flag, default_drv_set_flag to restore source,
;or target directory and default drive.

	TEST	SYS_FLAG, TURN_VERIFY_OFF_FLAG ;AN000;turn off verify?
;	$IF	NZ			;yes
	JZ $$IF57			    ;AN000;
	    MOV     AX, 2E00h		;AN000;turn it off
	    INT     21H        ;AN000;
;	$ENDIF
$$IF57: 		;AN000;

	TEST	SYS_FLAG, DEFAULT_DRV_SET_FLAG ;AN000;default drive has been changed?
;	$IF	NZ			;yes
	JZ $$IF59			    ;AN000;
	    MOV     DL, SAV_DEFAULT_DRV     ;AN000;
	    DEC     DL			    ;AN000;
	    CALL    SET_DEFAULT_DRV	;AN000;restore default drv.

; Following is a fix for PTR 0000012 . The fix is to skip changing default
; drive directory if source drive is not the default drive.

	    MOV     AL, S_DRV_NUMBER	;AN002; get source drive number
	    CMP     AL, SAV_DEFAULT_DRV ;AN002; src drive is the default drv ?
	    JNE     SKIP_CH_DIR 	;AN002; no, dont change directory

	    MOV     DX, OFFSET SAV_DEF_DIR_ROOT;AN000;
	    MOV     AH, Chdir	 ;AN000;
	    INT     21H 		;AN000;restore current dir of default dir
SKIP_CH_DIR:	   ;AN000;
;	$ENDIF
$$IF59: 	   ;AN000;

	TEST	SYS_FLAG, DEFAULT_S_DIR_FLAG ;AN000;source default direcotry saved?
;	$IF	NZ
	JZ $$IF61			  ;AN000;
	    MOV     DX, OFFSET SAV_S_DRV ;AN000;saved source drive letter & directory
	    MOV     AH, 3Bh		 ;AN000;
	    INT     21h 		;AN000;restore source. This is for the case of ERROR exit.
;	$ENDIF
$$IF61: 	   ;AN000;

	TEST	SYS_FLAG, DEFAULT_T_DIR_FLAG ;AN000;target default directory saved?
;	$IF	NZ			;then assume both source, target default saved
	JZ $$IF63			  ;AN000;
	    MOV     DX, OFFSET SAV_T_DRV ;AN000;saved target drive letter & directory
	    MOV     AH, 3Bh		 ;AN000;
	    INT     21h 		;AN000;restore target
;	$ENDIF
$$IF63: 	   ;AN000;

	RET		  ;AN000;
ORG_S_T_DEF ENDP   ;AN000;
;
EXTENDED_ERROR_HANDLER PROC NEAR;AN000;
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

GOTO_MAIN_EXIT:    ;AN000;
	JMP	MAIN_EXIT		;AN000;restore conditions
					;and exit
QUICK_EXIT:	;AN000;
	JMP	JUST_EXIT		;AN000;immediate exit

	RET	       ;AN000;

EXTENDED_ERROR_HANDLER ENDP;AN000;
;
CLOSE_DELETE_FILE PROC NEAR;AN000;
;when writing error occurs, then this routine is called to
;clean up the troubled target file.
;INPUT: DS - buffer seg
;	ES - data seg

	MOV	BX, ES:T_HANDLE 	;AN000;close target file
	PUSH	DS			;AN005;SAVE THE BUFFER PTR
	PUSH	ES			;AN005;WE NEED THE DATA PTR
	POP	DS			;AN005;DS = THE DATA PTR
	CALL	CLOSE_A_FILE;AN000;
	POP	DS			;AN005;DS = THE BUFFER PTR AGAIN
	LEA	DX, DS:target_drv_let	;AN000;target drv, filename
	CALL	DELETE_A_FILE		;AN000;delete it
	RET		    ;AN000;
CLOSE_DELETE_FILE ENDP;AN000;
;
;

SWITCH_DS_ES PROC NEAR;AN000;
; switch DS, ES
	PUSH	DS	       ;AN000;
	PUSH	ES	       ;AN000;
	POP	DS		;AN000;
	POP	ES		;AN000;
	RET		    ;AN000;
SWITCH_DS_ES ENDP    ;AN000;
;
;
INIT	PROC	NEAR	   ;AN000;

	CALL	GET_CUR_DRV	    ;AN000;save current default drv
	MOV	DL, SAV_DEFAULT_DRV;AN000;
	LEA	SI, SAV_DEFAULT_DIR;AN000;

	CALL	GET_CUR_DIR	    ;AN000;save current default dir
	CALL	GET_DRIVES	    ;AN000; SAR
	CALL	TOP_OF_MEM	;AN000;set top_of_memory
	CALL	INIT_BUFFER	;AN000;init buffer information

	MOV	DL, T_DRV_NUMBER			   ;AN000; SAR
	.IF < DL AE 3 > 				   ;AN000; SAR
	     LEA     SI, SAV_T_CURDIR			   ;AN000; SAR
	     CALL    GET_CUR_DIR			   ;AN000; SAR
	     OR      SYS_FLAG, DEFAULT_T_DIR_FLAG	   ;AN000; SAR
	.ELSE						   ;AN000; SAR
	     AND     SYS_FLAG, NOT DEFAULT_T_DIR_FLAG	   ;AN000; SAR
	.ENDIF						   ;AN000; SAR


	MOV	DL, S_DRV_NUMBER;AN000;
	DEC	DL	   ;AN000;
	CALL	SET_DEFAULT_DRV ;AN000;set source as a default drv
	CLC		     ;AN000;
	RET		     ;AN000;
INIT	ENDP		 ;AN000;
;
GET_DRIVES PROC NEAR  ;AN000;
;get source and target phisical drive letter from parser area.
;set ONE_DISK_COPY_FLAG, if the user XCOPY using the same drive letter.

;;;;;	MOV	AL, SO_DRIVE		;AN000;source drive letter
;	CMP	AL,SPACE		;AN000;IS DRIVE LETTER BLANK?
;	$IF	E			;AN000;YES, GET THE DEFAULT
;	    MOV     AL, SAV_DEFAULT_DRV ;(1=A, 2=B,...)
;	$ELSE				;AN000;NO, CHANGE FROM CHAR TO #
;	    SUB     AL,BASE_OF_ALPHA_DRV ;AN000;NEED THE DRV # HERE
;	$ENDIF

	MOV	AL, 1			;AN000; SAR	A is the source drive
	MOV	S_DRV_NUMBER, AL	;AN000;SAVE DRV #
	ADD	AL, BASE_OF_ALPHA_DRV;AN000;

	MOV	S_DRV, AL		;AN000;save source drive letter
	MOV	S_DRV_1, AL;AN000;
;;	MOV	S_ARC_DRV, AL		; SAR
	MOV	SAV_S_DRV, AL;AN000;

	.IF < DEST eq 3 >		;AN111;JW
	   MOV	   AL,0 		;AN111;JW
	.ELSE				;AN111;JW
	   MOV	   AL, DEST		;AN000; SAR  target drive letter
	.ENDIF				;AN111;JW
	INC	AL			;AN000; SAR
;;;;;	CMP	AL,SPACE		;AN000;IS DRIVE LETTER BLANK?
;   ;	$IF	E			;AN000;YES, GET THE DEFAULT
;   ;	    MOV     AL, SAV_DEFAULT_DRV ;(1=A, 2=B,...)
;   ;	$ELSE				;AN000;NO, CHANGE FROM CHAR TO #
;   ;	    SUB     AL,BASE_OF_ALPHA_DRV ;AN000;NEED THE DRV # HERE
;;;;;	$ENDIF
	MOV	T_DRV_NUMBER, AL	;AN000;save target drv #

;;;;;	CMP	S_DRV_NUMBER, AL	;s_drv_number = t_drv_number?
;   ;	$IF	E
;   ;	    OR	    SYS_FLAG, ONE_DISK_COPY_FLAG ;same logical drv copy
;;;;;	$ENDIF

	ADD	AL, BASE_OF_ALPHA_DRV	;AN000;make target drv # to drive letter
	MOV	T_DRV, AL		;AN000;target drive letter
;;	MOV	T_DRV_1, AL		; SAR
;;	MOV	T_DRV_2, AL		; SAR
	MOV	SAV_T_DRV, AL;AN000;
	RET	       ;AN000;
GET_DRIVES ENDP ;AN000;
;
GET_CUR_DRV PROC NEAR;AN000;
;get the current default drive number (0 = A, 1 = B ..),
;change it to BIOS drive number and save it.
	MOV	AH, Current_Disk	;AN000; = 19h
	INT	21h		 ;AN000;
	INC	AL			;AN000;(1 = A, 2 = B ..)
	MOV	SAV_DEFAULT_DRV, AL	;AN000;save it
	RET			;AN000;
GET_CUR_DRV ENDP	 ;AN000;
;
GET_CUR_DIR PROC NEAR	 ;AN000;
;get current directory and save it
;input: DL - drive # (0 = default, 1 = A etc)
;	DS:SI - pointer to 64 byte user memory

	MOV	AH, Get_Current_Directory;AN000;
	INT	21H		    ;AN000;
	RET			;AN000;
GET_CUR_DIR ENDP	 ;AN000;
;
TOP_OF_MEM PROC NEAR	 ;AN000;
;set Top_of_memory
	PUSH	ES		   ;AN000;
	MOV	BX, PSP_SEG	    ;AN000;
	MOV	ES, BX		    ;AN000;
	MOV	AX, ES:2		;AN000;PSP top of memory location
	SUB	AX, 100H		;AN000;subtract dos transient area (4k)
	MOV	TOP_OF_MEMORY, AX	;AN000;save it for buffer top
	POP	ES		  ;AN000;
	RET		      ;AN000;
TOP_OF_MEM ENDP        ;AN000;

INIT_BUFFER PROC NEAR  ;AN000;
;initialize buffer information
;set buffer_base, max_buffer_size
;	call	set_block		;SET BLOCK FOR BUFFR (for new 3.2 linker)
	MOV	AX, 0			;AN000; SAR
;;;;	PUSH	CS			; SAR cs segment is the highest segment in this program
;;;;	POP	DX			; SAR
	MOV	DX, ALLOCATE_START	;AN000; SAR
	MOV	BUFFER_PTR, DX	   ;AN000;
	CALL	SET_BUFFER_PTR	  ;AN000;
	MOV	AX, BUFFER_PTR	   ;AN000;
	MOV	BUFFER_BASE, AX 	;AN000;set buffer_base
	MOV	AX, BUFFER_LEFT  ;AN000;
	CMP	AX, 140h		;AN000;BUFFER_LEFT < 5K which is the minimum size this program supports?
	JAE	IB_CONT   ;AN000;
;;;;;;	PUSH	AX			    ; SAR  ;AN000;
;	MOV	AX, MSG_INSUF_MEMORY	    ; SAR  ;AC000;GET THE MESSAGE ID
;	MOV	MSG_NUM,AX		    ; SAR  ;AN000;NEED MESSAGE ID FOR PRINT
;	MOV	SUBST_COUNT,NUL 	    ; SAR  ;AN000;NO SUBSTITUTION TEXT
;	MOV	INPUT_FLAG,NUL		    ; SAR  ;AN000;NO INPUT = 0
;	MOV	MSG_CLASS,UTILITY_MSG_CLASS ; SAR  ;AN000;MESSAGE CLASS = -1
;	CALL	PRINT_STDERR		    ; SAR  ;print error. AX points to message ID
;	POP	AX			    ; SAR  ;AN000;
;	MOV	ERRORLEVEL, 4		    ; SAR  ;abnormal termination
	JMP	MAIN_EXIT_A		;AN000;terminate this program
IB_CONT:	  ;AN000;
	MOV	MAX_BUFFER_SIZE, AX	;AN000;set max buffer size in para
	CMP	AX, 0FFFh		;AN000;max_buffer_size > 64 K in para ?
;	$IF	B
	JNB $$IF65     ;AN000;
	    MOV     CX, 16;AN000;
	    MUL     CX			;AN000;AX = AX * 16 (DX part will be 0)
	    SUB     AX, 544		;AN000;AN000;subtrack header size
	    MOV     MAX_CX, AX		;AN000;this will be max_cx
;	$ELSE
	JMP SHORT $$EN65	;AN000;
$$IF65: 		 ;AN000;
	    MOV     MAX_CX, 0FFD0h	;AN000;else max_cx = fff0 - 32 bytes
					;which is the max # this program can support.
;	$ENDIF				;(min # this program support for buffer is 5 k
$$EN65: 		    ;AN000;
					; which has been decided by BIG_FILE )
	RET			   ;AN000;
INIT_BUFFER ENDP	    ;AN000;



SELECT	    ENDS	     ;AN000;

	END			   ;AN000;

