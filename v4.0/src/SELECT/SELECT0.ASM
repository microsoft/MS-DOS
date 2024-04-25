

PAGE	60,132							;AN000;
NAME	SELECT							;AN000;
TITLE	SELECT0 - DOS - SELECT.EXE				;AN000;
SUBTTL	select0.asm						;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SELECT0.ASM : Copyright 1988 Microsoft
;
;	DATE:	 July 4/87
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
;	CHANGE HISTORY:
;
;	This module contains the change history for the entire SELECT
;	component as of 1/25/88.  Some changes before this date are
;	listed in the individual modules.
;
;	A000 - 1/25/88, designates original 4.00 level source.
;	A001-A009, All changes made prior to 1/25/88, these descriptions
;	       exist in the individual modules which were Revised.
;	A111 - D353, 12/28/87, added support for A: to A: installation on
;	       systems with only one diskette drive.  J.W.
;	A010 - D407, 1/25/88, changed install to one directory to not
;	       copy over system files. J.W.
;	A011 - P3231, 1/26/88, add 'PRINT /D:LPTx' or 'PRINT /D:COMx' to
;	       autoexec.bat file for balanced and max. DOS function. S. H.
;	A012 - P3238, 1/27/88, add /DATE as default shell invocation switch.
;	       S. H.
;	A013 - P3239, 1/27/88, changed text of prompt setting in DOSSHELL.BAT
;	       file.  J.W.
;	A014 - P3275, 1/29/87, added check for minimum DOS function. S. H.
;	A015 - P3310, 2/1/88, Removed PRINT invocation from diskette based
;	       system. J.W.
;	A016 - D445, 2/4/88, removed /REF from DOSSHELL.BAT file. S. H.
;	A017 - P3339, 2/4/88, Added check for read-only .BAT and .340 files,
;	       J.W.
;	A018 - D418, 2/4/88, removed the default /TEXT option on a model 25
;	       or 30. S. H.
;	A019 - D443, 2/4/88, changed 'SHELL.BAT' to DOSSHELL.BAT'. S. H.
;	A020 - D438, 2/5/88, removed EXT_DISKETTE_SCREEN and EXT_DISK_PARMS_SCREEN
;	       and other code related to supporting external diskette drives.
;	       S. H.
;	A021 - D442, 2/8/88, Added selection of SHARE when >32M partition
;	       exists.	J.W.
;	A022 - P3403, 2/8/88, edited Welcome Screen to inform PS/2 users they
;	       can use 1 or 2 MB 3.5" blank diskette.  S. H.
;	A023 - P3292, 2/8/88, implemented error level check on FDISK to detect
;	       a disk with no primary DOS partition defined.  J.W.
;	A024 - D463, 2/9/88, changed method for reading and writing the
;	       SELECT.DAT file.  File can now be compressed.  Eliminated
;	       the large and slow CAS routines.  J.W./D.T.
;	A025 - P3460, 2/10/88, Changed printer panel number and panel list
;	       to remove unused panels.  J.W.
;	A026 - P3450, 2/11/88, added color change to unselected fields on
;	       the DOS location panel.	J.W.
;	A027 - P3459, 2/15/88, set the carry flag in HANDLE_F3 in order to
;	       eliminate an endless loop in GET_FUNCTION_CALL. S. H.
;	A028 - P3592, 2/22/88, Add text to direct users to Getting Started With
;	       DOS 4.00 book.  J.W.
;	A029 - P3529, 2/17/88, Corrected GRAPHICS parameter initialization
;	       problem.  J.W.
;	A030 - P3527, 2/17/88, Changed incorrect diskette error panel to be
;	       more descriptive. J.W.
;	A031 - P3546, 2/17/88, changed code to allow a semi-colon as the last
;	       character entered in DOS or APPEND PATH.  S. H.
;	A032 - P3576, 2/22/88, changed code to flash message on screen if
;	       user does not put SELECT diskette in to start SELECT (360KB
;	       diskettes only).  S. H.
;	A033 - P3620, 2/24/88, saved the value in I_DESTINATION so that it
;	       is not wiped out upon reboot.  S. H.
;	A034 - P3618, 2/25/88, changed code so that user does not have to reboot
;	       if he makes no changes to the partition.  S. H.
;	A035 - P3654, 2/29/88, updated help texts #18 and #19 received from I.D.
;	       S. H.
;	A036 - P3666, 3/1/88, added GRAPHICS to the SELECT.PRT file for
;	       Quietwriter II and Pageprinter.	
;	A037 - P3672, 3/1/88, removed /MSG from SHELL= statement in CONFIG.SYS
;	       for installs to hard disk (for purposes of code reduction in
;	       COMMAND.COM).  
;	A038 - P3700, 3/2/88, changed second scroll option on DOS Location
;	       Screen to let user know system files not copied.  
;	A039 - D496, 3/3/88, added a dummy file for the user of the SHELL
;	       tutorial to copy and delete.  
;	A040 - P3741, 3/4/88, changed D_XMA2EMS_1 values.  
;	A041 - P3747, 3/4/88, changed initialization values for D_BUFFERS_2
;	       and D_FASTOPEN_2 (max. DOS utilization)	
;	A042 - P3737, 3/9/88, changed FDISK.EXE to FDISK.COM.  
;	A043 - P3813, 3/10/88, moved the COMSPEC statement in the AUTOEXEC.BAT
;	       after the @ECHO OFF statement.  
;	A044 - P3852, 3/14/88, changed D_XMA2EMS_1 values again.  
;	A045 - D503, 3/15/88, changed MAJOR_DOS_VER to 4 and MINOR_DOS_VER to
;	       00 for DOS 4.00 build. Everything visible to user still says
;	       DOS 4.00.  
;	A046 - D474, 3/16/88, changed the /E parameter for buffers to /X.
;	       
;	A047 - P3924, 3/17/88, SELECT now includes VERSIONA.INC for the DOS
;	       version check---check formerly made in MAC_EQU.INC.  
;	A048 - P3857, 3/18/88, changed code for 360KB install to hardfile on
;	       256KB machine to deallocate memory before COMMAND.COM is
;	       read in.  
;	A049 - P4017, 3/25/88, changed capital "W" to a small "w" in the
;	       Getting Started with DOS 4.00 title in panels.  
;	A050 - P4020, 3/25/88, removed quote marks and spaces between 1 MB
;	       and 2 MB on Welcome Screen.  
;	A051 - P3992, 3/26/88, edited code for DOS Location Screen so that
;	       ESC (hit from any field) takes you back to previous screen.
;	       
;	A052 - P4015, 3/28/88, stated diskette size user needs when installing
;	       to a single 3.5 inch diskette.  
;	A053 - D505, 3/28/88, redesigned the Dos Location screen.  
;	A054 - P4006, 3/28/88, turned off blinking cursor on early SELECT
;	       screens (enhanced color display used).  
;	A055 - D508, 3/29/88, put SHARE.EXE on 720 Install diskette.  
;	A056 - P4047, 3/29/88, revised installation complete panel for
;	       720 to 720 installation.  
;	A057 - P3866, strengthened panel msg referring user to Getting Started
;	       with DOS 4.00.  
;	A058 - P3945, corrected code that creates install path when putting
;	       DOSSHELL.BAT in the root.  
;	A059 - P4056, 3/30/88, corrected input routines to flush buffer before
;	       read.  
;	A060 - P4008, 3/30/88, added error message for help access when install
;	       disk not in drive.  
;	A061 - P4000, 3/30/88, corrected problem with allowable return key
;	       strings.  
;	A062 - P4059, 3/30/88, added FORMAT.COM to SELECT and OPERATING
;	       diskettes; moved IFSFUNC from OPERATING to INSTALL diskette.
;	       
;	A063 - P3950, 4/1/88, added code to enable SELECT to install to a
;	       256KB 2-drive convertible.  
;	A064 - D514, 4/6/88, revised two Installation Complete panels.
;	       
;	A065 - D501, 4/6/88, added code to check for OS/2 and rename its
;	       config.sys and autoexec.bat to config.os2 and autoexec.os2.
;	       
;	A066 - P4179, D519, 4/6/88, moved the print statement to next to last
;	       in the autoexec.bat file.  
;	A067 - P4290, 4/13/88, output message to user if SELECT encounters
;	       insufficient memory to install DOS.  
;	A068 - P4325, 4/14/88, updated CASTRUC.INC to match G:\CASSFAR\PCSLCTP.
;	       
;	A069 - P4364, 4/18/88, updated SELECT to match new PCINPUT file.  
;	A070 - P4401, 4/19/88, changed Latin America's default code page to 850.
;	       
;	A071 - P4428, 4/22/88, removed the /PRE parameter from the DOSSHELL.BAT.
;	       
;	A072 - P3950, overlay PARSER and PCINPUT segments if on a 256KB machine.
;	       
;	A073 - P4409, 5/2/88, corrected problem of SELECT using different default
;	       drives on different machines---variable not assigned.  
;	A074 - P4568, 5/2/88, disallow user to end SELECT by pressing CTRL-BREAK.  
;	A075 - P4720, 5/6/88, changed "INSTALL COPY" diskette name to "SELECT
;	       COPY".  
;	A076 - P4718, 5/6/88, capitalized the sentence in the INSTALLATION
;	       COMPLETE panels which points the user to the Getting Started
;	       with DOS 4.00 book.  
;	A077 - P4772, 5/6/88, added /PROMPT as default startup parameter for
;	       DOS Shell for 256K machine.  
;	A078 - P4782, 5/9/88, changed FASTOPEN defaults for maximum DOS
;	       function to 150,150.  
;	A079 - P4744, 5/10/88, made panel and scroll field change for Installation
;	       Option screen.  
;	A080 - P4832, 5/11/88, changed SELECT.SKL and USA.MSG to reflect the
;	       change of "INSTALL COPY" to "SELECT COPY" diskette (see P4720).
;	       
;	A081 - P4848, 5/12/88, spaced over the keys at the bottom of the help
;	       panel to allow more room for translation; exported it on this
;	       ptm to export help text changes.  
;	A082 - P4916, 5/18/88, turned cursor off following FDISK reboot.
;	       
;	A083 - P4917, 5/19/88, stopped typomatic effect of pressing enter key
;	       too long during installation.  
;	A084 - P4906, 5/19/88, corrected mode 40 machine installation hang.
;	       
;	A085 - P4926, 5/19/88, homed the cursor before call to format so that
;	       message stating % of diskette formatted is at top of screen.
;	       
;	A086 - P4934, 5/20/88, changed the 16h value used for INT 2Fh when
;	       checking for ANSI presence to 1Ah to avoid MICROSOFT collision.
;	       
;	A087 - P4955, 5/23/88, adjusted the spacing between the ENTER and F1
;	       keys on the bottom of panels 31 (Time and Date) and 32 (Format
;	       Fixed Disk Drive) to give more room for translation.  
;	A088 - P5064, 6/9/88, replaced a call to clear the input buffer in
;	       PCINCHA_CALL (see A059).  
;	A089 - P5048, 6/9/88, increased the value of MAX_NUM_PRINTER_DEFS to
;	       allow more printers in the SELECT.PRT file.  
;	A090 - P5127, 6/17/88, changed default index for alternate keyboards
;	       to be second (old) keyboard.  J. Wright
;	A091 - P5142, 6/30/88, reduced memory allocation for panels from 64KB
;	       to 62KB to allow more room for foreign versions of SELECT to
;	       run.  S. Holahan
;	A092 - P5173, 7/15/88, added @BREAK=OFF" after :COMMON statement
;	       in DOSSHELL.BAT file.  S. Holahan
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CODE	  SEGMENT PARA PUBLIC 'CODE'                            ;AN000; Segment for CASS libraries
CODE	  ENDS							;AN000;
								;
CODE_FAR  SEGMENT PARA PUBLIC 'CODE'                            ;AN000; Segment for miscellaneous routines
CODE_FAR  ENDS							;AN000;
								;
_TEXT	segment byte public 'CODE'                              ;AN000;
_TEXT	ends							;AN000;
_DATA	segment word public 'DATA'                              ;AN000;
_DATA	ends							;AN000;
CONST	segment word public 'CONST'                             ;AN000;
CONST	ends							;AN000;
_BSS	segment word public 'BSS'                               ;AN000;
_BSS	ends							;AN000;
								;
								;
DATA	  SEGMENT BYTE PUBLIC 'DATA'                            ;AN000; Segment for Data values
DATA	  ENDS							;AN000;
								;
SELECT	SEGMENT PARA PUBLIC 'SELECT'                            ;AN000;
SELECT	  ENDS							;AN000;

SERVICE   SEGMENT PARA PUBLIC 'SERVICE'                         ;AN000; Segment for CAS_SERVICE routines
SERVICE   ENDS							;AN000;
								;
OUR_STACK SEGMENT BYTE	STACK					;AN000; Segment for Local Stack
	  DB   512  DUP('IBM ')                                 ;AN000;
LAST_STACK EQU $						;AN000;
OUR_STACK ENDS							;AN000;
								;
PARSER	  SEGMENT PARA PUBLIC 'PARSER'                          ;AN000; Segment for PARSE code
PARSER	  ENDS							;AN000;

PCINPUT   SEGMENT PARA PUBLIC 'PCINPUT'                         ;AN072;
PCINPUT   ENDS							;AN072;
								;
ZSEG	  SEGMENT PARA PUBLIC 'ZSEG'                            ;AN000; Dummy segment for End-of-Code
ZSEG	  ENDS							;AN000;
								;
AGROUP GROUP CODE,CODE_FAR,DATA,PARSER,SERVICE,SELECT,OUR_STACK,ZSEG  ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.XLIST								;AN000;
	INCLUDE PANEL.MAC					;AN000;
	INCLUDE STRUC.INC					;AN000;
	INCLUDE MACROS.INC					;AN000;
	INCLUDE SYSMSG.INC					;AN000;
	INCLUDE ROUT_EXT.INC					;AN000;
	INCLUDE EXT.INC 					;AN000;
	INCLUDE PAN-LIST.INC					;AN000;
.LIST								;AN000;
								;
	EXTRN	DEALLOCATE_MEMORY_CALL:FAR			;AN000;
	EXTRN	CHECK_VERSION:NEAR				;AN000;
								;
	PUBLIC	INSTALL 					;AN000;
	PUBLIC	SYSDISPMSG					;AN000;
	PUBLIC	EXIT_SELECT					;AN000;
	PUBLIC	EXIT_SELECT2					;AN000;
	PUBLIC	INITIALIZATION					;AN000;
	PUBLIC	ABORT_SELECT					;AN000;
								;
	MSG_UTILNAME <SELECT>					;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	SEGMENT PARA PUBLIC 'SELECT'                            ;AN000;
	ASSUME	CS:SELECT,DS:DATA,SS:our_STACK			;AN000;
								;
OLD_STACK_SEG	DW	?					;AN000;
OLD_STACK_OFF	DW	?					;AN000;
								;
	INCLUDE CASEXTRN.INC					;AN000;
								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Beginning of code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INSTALL PROC	FAR						;AN000;
	CLI							;AN000;
	MOV	AX,SS						;AN000;
	MOV	OLD_STACK_SEG,AX				;AN000;
	MOV	OLD_STACK_OFF,SP				;AN000;
	mov	ax,our_stack					;AN000;
	mov	ss,ax						;AN000;
	mov	sp,512*4					;AN000;
	STI							;AN000;
								;
	MOV	AX,DATA 					;AN000;
	MOV	DS,AX						;AN000;
	JMP	INITIALIZATION					;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	CODE TO LEAVE SELECT WITH!!!!
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EXIT_SELECT:							;AN000;
								;
	FIND_FILE	     S_AUTO_REBOOT, 0			;AN000;DT Make sure INSTALL disk in drive
	.IF < c >						;AN000;DT
	   .REPEAT						;AN000;DT make sure diskette
	      CLEAR_SCREEN					;AN000;DT with COMMAND.COM in drive
	      DISPLAY_MESSAGE  19				;AN000;DT Insert INSTALL diskette
	      GET_FUNCTION	   FK_ENT			;AN000;DT
	      FIND_FILE 	   S_AUTO_REBOOT, 0		;AN000;DT
		 .LEAVE < nc >					;AN000;DT
		  HANDLE_ERROR	       ERR_DOS_DISK, 2		;AN000;DT
	   .UNTIL						;AN000;DT
	   CLEAR_SCREEN2					;AN000;JW
	.ENDIF							;AN000;
								;
EXIT_SELECT2:							;AN000;
								;
	DEALLOCATE_MEMORY					;AN000;free up allocated segment
	.IF < NC >						;AN000;
	   CALL    RESTORE_INT_23				;AN074;SEH restore ctrl-break before exiting
	   MOV	   AX,OLD_STACK_SEG				;AN000;
	   MOV	   SS,AX					;AN000;
	   MOV	   SP,OLD_STACK_OFF				;AN000;
	   CALL    CURSORON					;AN000;
	   MOV	   AX,4C00H					;AN000;
	   INT	   21H						;AN000;
	 .ELSE							;AN000;
ABORT_SELECT:							;AN000;exit without handling allocated memory
	   CALL    RESTORE_INT_23				;AN074;SEH restore ctrl-break before exiting
	   MOV	   AX,OLD_STACK_SEG				;AN000;
	   MOV	   SS,AX					;AN000;
	   MOV	   SP,OLD_STACK_OFF				;AN000;
	   CALL    CURSORON					;AN000;
	   MOV	   AX,4C00H					;AN000;
	   INT	   21H						;AN000;
	.ENDIF							;AN000;
INSTALL ENDP							;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Message Retriever code inserted at this point....
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 MSG_SERVICES <NOVERCHECKmsg, FARmsg, GETmsg, DISPLAYmsg, LOADmsg>    ;AN000;
 MSG_SERVICES <SELECT.CLA,SELECT.CLB>				      ;AN000;
 MSG_SERVICES <SELECT.CL1,SELECT.CL2>				      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Start of SELECT.EXE code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INITIALIZATION: 						;AN000;
	LOAD_MESSAGES						;AN000;
	JMP	CHECK_VERSION					;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SELECT	ENDS							;AN000;

include msgdcl.inc

	END	INSTALL 					;AN000;

