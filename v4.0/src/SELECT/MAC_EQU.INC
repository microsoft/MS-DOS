INCLUDE VERSIONA.INC				;AN047;SEH check DOS version in VERSIONA.INC instead of in MAC_EQU.INC

TRUE			=	  1		;AN000;
FALSE			=	  0		;AN000;

; Equates from PRN_DEF.ASM

ERR_NOT_ENOUGH_MEM	EQU	  1		;AN000; There was not enough memory to build the names table
ERR_OPENING_FILE	EQU	  2		;AN000; Error opening a file
ERR_READING_FILE	EQU	  3		;AN000; Error reading from a file
ERR_FINDING_VALUE	EQU	  4		;AN000; Error finding the number of prn defs at the beginning of the file
ERR_LINE_TOO_LONG	EQU	  5		;AN000; There was a line too long for the buffer
ERR_FINDING_NAME	EQU	  6		;AN000; There was an error locating a printer name after a P or S
ERR_ACCESSING_FILE	EQU	  7		;AN000; There was an error updating the file pointer
ERR_TOO_MANY_DEFS	EQU	  8		;AN000; There are too many defintion in the file
ERR_NUMBER_MATCH	EQU	  9		;AN000; The number of actual definition do not match the number expected
ERR_ALLOCATING_MEM	EQU	  10		;AN000; There was an error allocating memory
ERR_CDP_CPP		EQU	  11		;AN000; A prn defn had either a CDP or CPP but not both
ERR_PRN_DEFN		EQU	  12		;AN000; There was an error in a printer definition

; Equates from MACROS.INC			;
; Equates from MACROS2.INC			;
;MAJOR_DOS_VER		 EQU	   4		;AC047;SEH check now done in VERSIONA.INC ;AC045;SEH
;MINOR_DOS_VER		 EQU	   00		;AC047;SEH ;AC045;SEH version update to DOS 4.00
						;
; Equates from MACROS3.INC			;
PRESENT_WITH_PART	EQU	  2		;AN000;
PRESENT_WITHOUT_PART	EQU	  1		;AN000;
NOT_PRESENT		EQU	  0		;AN000;
NO_EDOS_SPACE		EQU	  0		;AN000;
FREE_EDOS_SPACE 	EQU	  1		;AN000;
NO_EDOS_BUT_SPACE	EQU	  2		;AN000;
						;
M_DOS_EXISTS		EQU	  1H		;AN000;
M_EDOS_EXISTS		EQU	  2H		;AN000;
M_LOGICAL_EXISTS	EQU	  4H		;AN000;
M_EDOS_SPACE		EQU	  8H		;AN000;
M_FREE_SPACE		EQU	 10H		;AN000;
M_DOS_EDOS_PART 	EQU	  3H		;AN000;
						;
DISKETTES_EXIST 	EQU	  1		;AN000;
MAX_NUM_DISKETTE	EQU	  2		;AN000;
						;
TABLE_ONE		EQU	  1		;AN000;
TABLE_TWO		EQU	  2		;AN000;
						;
DATA_VALID		EQU	  0		;AN000;
DATA_INVALID		EQU	  1		;AN000;
						;
USE_DEFAULT		EQU	  0		;AN000;
DO_NOT_USE_DEFAULT	EQU	  1		;AN000;
						;
DEF_DEST_A		EQU	  3		;AN111;JW
DEF_DEST_B		EQU	  2		;AN000;
DEF_DEST_C		EQU	  1		;AN000;
						;
E_1440_TRACKS		EQU	  80		;AN000;
E_1440_SECTORS		EQU	  18		;AN000;
						;
; Equates from MACROS4.INC			;
; Equates from MACROS5.INC			;
B_DRIVE 		EQU	  1		;AN000;
C_DRIVE 		EQU	  2		;AN000;
A_DRIVE 		EQU	  3		;AN111;JW
LEN_ALT_KYBD_ID 	EQU	  3		;AN000;
; Equates from MACROS6.INC			;
						;
						;
; Equates from ROUTINES.ASM			;
STDOUT			EQU	  1		;AN000;
STDERR			EQU	  2		;AN000;
EXEC_DIR		EQU	  1		;AN000;
EXEC_NO_DIR		EQU	  0		;AN000;
						;
; Equates from SELECT.SKL			;
MSG_INV_DOS		    EQU       1 	;AN000;
MSG_INV_BOOT_MEDIA	    EQU       4 	;AN000;
MSG_INV_DISK_MEDIA	    EQU       5 	;AN000;
MSG_INV_PARMS		    EQU       6 	;AN000;
MSG_INV_INSTALL 	    EQU       7 	;AN000;
MSG_LOADING		    EQU       8 	;AN000;
MSG_RELOADING		    EQU       9 	;AN000;
						;
; Equates for SEL_FLG (DB) in PRN_DEF.ASM
; SEL_FLG   DB	0
INSTALLRW		EQU	  80H		;AN000;The INSTALL diskette is read/write

