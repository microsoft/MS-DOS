	PAGE	90,132			;A2
	TITLE	DISKCOPY.SAL - DISKETTE DUPLICATION UTILITY ;
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: DISKCOPY

; DESCRIPTIVE NAME: Diskette to diskette complete copy Utility

;FUNCTION: DISKCOPY is to copy the contents of the diskette in the
;	   specified source drive to the diskette in the target
;	   drive.  If necessary, the target diskette is also
;	   formatted.


;	   Multiple copies may be performed with one load of DISKCOPY.
;	   A prompt, "Copy another (Y/N)?" permits additional
;	   executions, all with the same drive specifications.

; ENTRY POINT: "DISKCOPY" at ORG 100h, jumps to "BEGIN".

; INPUT: (DOS command line parameters)
;	 [d:][path]DISKCOPY [d: [D:]][/1]

;	 Where

;	 [d:][path] before DISKCOPY to specify the drive and path that
;		    contains the DISKCOPY command file.

;	 [d:]	    to specify the source drive id

;	 [D:]	    to specify the destination drive id

;	 [/1]	    to request single sided operations only

; EXIT-NORMAL: Errorlevel = 0
;	      Function completed successfully.

; EXIT-ERROR: Errorlevel = 1
;	      Abnormal termination due to error, wrong DOS,
;	      invalid parameters, unrecoverable I/O errors on
;	      the diskette.
;
;	      Errorlevel = 2
;	      Termination requested by Cntrl-Break.

; EFFECTS: The entire source diskette is copied, including the unused
;	   sectors.  There is no awareness of the separate files
;	   involved.  A unique volume serial number is generated
;	   for the target diskette.

; INCLUDED FILES:
;	INCLUDE DCPYMACR.INC		;(formerly called MACRO.DEF)
;	INCLUDE DISKCOPY.EQU		;EQUATES
;	INCLUDE BOOTFORM.INC		;DEFINE EXT_BPB_INFO & EXT_IBMBOOT_HEADER
;	INCLUDE PATHMAC.INC		;PATHGEN MACRO

; INTERNAL REFERENCES:
;    ROUTINES:
;	 BEGIN - VERSION CHECK, SYSMSG INIT, EXIT TO DOS
;	 SET_LOGICAL_DRIVE - SET LOG. DRV LETTER THAT OWNS DRIVE
;	 COPY - COPY THE DISKETTE IMAGE
;	 TEST_REPEAT - SEE IF USER WANTS TO COPY ANOTHER
;	 READ_SOURCE - READ FROM SOURCE AS MUCH AS POSSIBLE
;	 WRITE_TARGET - WRITE DATA FROM MEMORY TO TARGET DISKETTE
;	 READ_WRITE_TRACK - READ A TRACK AND STORE IT INTO MEMORY
;	 READ_OP - IOCTL READ A TRACK OPERATION
;	 MAYBE_ADJUST_SERIAL - MAKE NEW SERIAL IN BOOT
;	 WRITE_OP - IOCTL WRITE A TRACK OPERATION
;	 FORMAT_ALL - FORMATS ALL TRACKS TO END
;	 FORMAT_TRACK - IOCTL FORMAT A TRACK
;	 CHECK_SOURCE - CHECK SOURCE DISKETTE TYPE
;	 READ_A_SECTOR - GET ONE SECTOR WITH IOCTL READ
;	 CALC_TRACK_SIZE - GET MEM SIZE TO STORE ONE TRACK
;	 CHECK_MEMORY_SIZE - VERIFY WE HAVE ENUF TO COPY 1 TRACK
;	 SET_FOR_THE_OLD  - SET BPB FOR BEFORE-2.0 FMTTED MEDIA
;	 SET_TRACKLAYOUT - MOVE DATA TO TRACK IMAGE
;	 CHECK_TARGET - READ TARGET BOOT RCD, NEEDS FORMAT?
;	 CHK_MULTI_MEDIA - CHECK IF DRIVE IS MULTI-MEDIA
;	 SET_DRV_PARM_DEF - SET DRIVE PARMS VIA IOCTL
;	 CHK_MEDIATYPE - DETERMINE MEDIATYPE OF TARGET FOR FORMAT
;	 GENERIC_IOCTL - COMMUNICATE WITH THE DEVICE DRIVER
;	 EXTENDED_ERROR_HANDLER - RESPOND TO DOS ERRORS
;	 TRY_FORMAT - ATTEMPT TRACK FORMAT, TRY FOR ERROR RECOVERY
;	 ERROR_MESSAGE - SAY WHAT AND WHERE FAILURE
;	 SENDMSG - PASS IN REGS DATA FROM MSG DESCRIPTOR TO DISP MSG
;	 YESNO - DETERMINE IF A RESPONSE IS YES OR NO
;(DELETED ;AN013;)READ_VOLSER - OBTAIN OLD VOLUME SERIAL NUMBER FROM SOURCE
;	 WRITE_VOLSER - PUT NEW VOL SER NUMBER TO TARGET
;    DATA AREAS:
;	PSP - Contains the DOS command line parameters.
;	WORKAREA - Temporary storage

; EXTERNAL REFERENCES:
;    ROUTINES:
;	SYSDISPMSG - Uses the MSG parm lists to construct the messages
;		 on STDOUT.
;	SYSLOADMSG - Loads messages, makes them accessable.
;	SYSPARSE - Processes the DOS Command line, finds parms.

;    DATA AREAS:
;	 DCOPYSM.SAL - Defines the control blocks that describe the messages
;	 DCOPYPAR.SAL - Defines the control blocks that describe the
;		DOS Command line parameters.

; NOTES:
;	 This module should be processed with the SALUT preprocessor
;	 with the re-alignment not requested, as:

;		SALUT DISKCOPY,NUL

;	 To assemble these modules, the alphabetical or sequential
;	 ordering of segments may be used.

;	 Sample LINK command:

; LINK @DISKCOPY.ARF

; Where the DISKCOPY.ARF is defined as:

;	 DISKCOPY+
;	 DCOPYSM+
;	 DCOPYP+
;	 DCOPYPAR+
;	 COPYINIT

;	 These modules must be linked in this order.  The load module is
;	 a COM file, to be converted to COM with EXE2BIN.

; REVISION HISTORY:
;	     A000 Version 4.00: add PARSER, System Message Handler,
;		  Make new unique vol serial number on new diskette.
;	     A001 DCR 27, display vol serial number, if present.
;	     A002 ptm473 Flag duplicate switches as error
;	     A003 Display parm in error
;	     A004 PTR752 Add close door to drive not ready
;	     A005 PTR756 After bad parms, specify help info
;	     A006 DCR210 SELECT, if present, handles all msgs
;	     A007 PTM1100 Clear keyboard buffer before input response
;	     A008 PTM1434 CR,LF MISSING FROM MSGS 22 AND 23
;	     A009 PTM1406 USE 69H INSTEAD OF IOCTL FOR GET/SET MEDIA ID
;	     A010 PTM1821 Move INCLUDE COPYRIGH.INC into MSG_SERVICE macro.
;	     A011 PTM1837 ADD CHECK FOR UNKNOWN MEDIA TO TRIGGER FORMAT
;	     A012 PTM2441 COPY FROM 360 TO 1.2 CLOBBERS 1.2
;	     A013 PTM3184 SUPPORT OS/2 1.0/1.1 TYPE BOOT RECORDS ALSO
;			REMOVE USE OF GET/SET MEDIA ID
;	     A014 PTM3262 specify BASESW EQU 1 before PARSE.ASM
;	     A015 PTM3512 PATHGEN
;
; COPYRIGHT: The following notice is found in the OBJ code generated from
;	     the "DCOPYSM.SAL" module:

;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Property of Microsoft  "

;PROGRAM AUTHOR: Original written by: JK
;		 4.00 modifications by: EMK
;****************** END OF SPECIFICATIONS *****************************
	IF1				;
	    %OUT    COMPONENT=DISKCOPY, MODULE=DISKCOPY.SAL ;
	ENDIF				;

;*****************************************************************************
;									     *
;			     D I S K C O P Y				     *
;									     *
;  UPDATE HISTORY: 7-31, 8-3, 8-5A, 8-6, 8-7, 8-8, 8-10, 8-11, 8-13, 8-14    *
;		   8-16, 8-17, 8-18, 8-20, 8-28, 9-3, 9-11, 10-6, 10-11      *
;		   11-7,11-12, 11-17, 11-18, 12-19, 2-16-84, 3-27, 4-5, 4-7  *
;		   6-20,7-23,10-31,3-27,4-24				     *
;									     *
;*****************************************************************************



;*****************************************************************************
;									     *
;			     MACRO DEFINITION				     *
;									     *
;*****************************************************************************

	INCLUDE PATHMAC.INC		;AN015;PATHGEN MACRO
	INCLUDE DCPYMACR.INC		;(formerly called MACRO.DEF)
	INCLUDE DISKCOPY.EQU		;EQUATES

;	       $salut (4,16,22,36) ;AN000;
MY_BPB	       STRUC		   ;
CBYTE_SECT     DW    0		   ; 200H  BYTES / SECTOR
CSECT_CLUSTER  DB    0		   ; 2h    SECTORS / CLUSTER
CRESEV_SECT    DW    0		   ; 1h    RESERVED SECTORS
CFAT	       DB    0		   ; 2h    # OF FATS
CROOTENTRY     DW    0		   ; 70h   # OF ROOT ENTRIES
CTOTSECT       DW    0		   ; 02D0h TOTAL # OF SECTORS INCLUDING
				   ; BOOT SECT, DIRECTORIES ...
MEDIA_DESCRIP  DB    0		   ;0FDh   MEDIA DISCRIPTOR
CSECT_FAT      DW    0		   ; 2h    SECTORS / FAT
CSECT_TRACK    DW    0		   ;
CHEAD	       DW    0		   ;
CHIDDEN_SECT   DD    0		   ;
BIG_TOT_SECT   DD    0		   ;
	       DB    6 DUP (0)	   ;
MY_BPB	       ENDS		   ;

	       INCLUDE BOOTFORM.INC ;AN013;DEFINE EXT_BPB_INFO & EXT_IBMBOOT_HEADER

CSEG	       SEGMENT PARA PUBLIC 'CODE' ;AN000;
	       ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG ;

;*****************************************************************************
;									     *
;			EXTERNAL VARIABLES				     *
;									     *
;*****************************************************************************
;$salut (4,2,9,36)		   ;AN000;
 EXTRN	SYSLOADMSG	    :NEAR  ;AN000;SYSTEM MSG HANDLER INTIALIZATION
 EXTRN	SYSDISPMSG	    :NEAR  ;AN000;SYSTEM MSG HANDLER DISPLAY

 EXTRN	INIT		    :NEAR  ;INITIALIZATION ROUTINE
.XLIST				   ;
;EXTRN	PRINTF		    :NEAR  ;MESSAGE DISPLAY ROUTINE
;EXTRN	PROMPT		    :NEAR  ;MESSAGE DISPLAY AND KEYBOARD INPUT ROUTINE
;EXTRN	ERROR_MESSAGE	    :NEAR  ;ERROR MESSAGE DISPLAY ROUTINE
;EXTRN	MSG_SOURCE_BAD_PTR  :BYTE
;EXTRN	YES		    :BYTE
;EXTRN	NO		    :BYTE
.LIST				   ;
 EXTRN	ASCII_DRV1_ID	    :BYTE  ;AN000;SOURCE DRIVE LETTER CHARACTER
 EXTRN	ASCII_DRV2_ID	    :BYTE  ;AN000;TARGET DRIVE LETTER CHARACTER
 EXTRN	MSG_TRACKS	    :WORD  ;AN000;NUMBER OF TRACKS
 EXTRN	MSG_SECTRK	    :WORD  ;AN000;SECTORS PER TRACK
 EXTRN	MSG_SIDES	    :WORD  ;AN000;NUMBER OF SIDES
 EXTRN	ERROR_SIDE_NUMBER   :WORD  ;AN000;NUMBER OF SIDES (SUBFIELD OF MSG 19)
 EXTRN	ERROR_TRACK_NUMBER  :WORD  ;AN000;NUMBER OF TRACKS (SUBFIELD OF MSG 19)

 EXTRN	MSGNUM_EXTERR	    :WORD  ;AN000;EXTENDED ERROR MSG DESCRIPTOR
 EXTRN	MSGNUM_HARD_ERROR_READ:WORD ;AN000;"Unrecoverable read/write error on drive %1",CR,LF
 EXTRN	MSGNUM_HARD_ERROR_WRITE:WORD ;AN000;"Side %2, track %3" ;
 EXTRN	MSGNUM_LOAD_SOURCE   :WORD ;AC000;"Insert SOURCE diskette in drive %2:"
 EXTRN	MSGNUM_LOAD_TARGET   :WORD ;AC000;"Insert TARGET diskette in drive %2:"
 EXTRN	MSGNUM_TARGET_MB_UNUSABLE :WORD ;AC000;"Target diskette may be unusable"
 EXTRN	MSGNUM_NOT_COMPATIBLE :WORD ;AC000;"Drive types or diskette types",CR,LF
				   ;"not compatible"
 EXTRN	MSGNUM_BAD_SOURCE  :WORD   ;AC000;"SOURCE diskette bad or incompatible"
 EXTRN	MSGNUM_BAD_TARGET  :WORD   ;AC000;"TARGET diskette bad or incompatible"
 EXTRN	MSGNUM_COPY_ANOTHER :WORD  ;AC000;"Copy another diskette (Y/N)?"
 EXTRN	MSGNUM_FORMATTING  :WORD   ;AC000;"Formatting while copying"
 EXTRN	MSGNUM_GET_READY   :WORD   ;AC000;"Drive not ready - %0"
 EXTRN	MSGNUM_CLOSE_DOOR  :WORD   ;AN004;"Make sure a diskette is inserted into
				   ; the drive and the door is closed"
 EXTRN	MSGNUM_FATAL_ERROR :WORD   ;AC000;"Copy process ended"
 EXTRN	MSGNUM_UNSUF_MEMORY:WORD   ;AC000;"Insufficient memory"
 EXTRN	MSGNUM_COPYING	   :WORD   ;AC000;"Copying %1 tracks",CR,LF
				   ;"%2 Sectors/Track, %3 Side(s)"
 EXTRN	MSGNUM_STRIKE	   :WORD   ;AC000;"Press any key to continue . . ."
 EXTRN	MSGNUM_WRITE_PROTECT :WORD ;AC000;"Attempt to write to write-protected diskette"
 EXTRN	MSGNUM_CR_LF	   :WORD   ;AC000;
 EXTRN	MSGNUM_SERNO	    :WORD  ;AN001;"VOLUME SERIAL NUMBER IS %1-%0"
 EXTRN	SUBLIST_26A	    :WORD  ;AN001;POINTS TO FIRST PART OF SERIAL NUMBER
 EXTRN	SUBLIST_26B	    :WORD  ;AN001;POINTS TO SECND PART OF SERIAL NUMBER

 EXTRN	DRIVE_LETTER	   :BYTE   ;AN000;
;*****************************************************************************
;									     *
;			     PUBLIC VARIABLES				     *
;									     *
;*****************************************************************************

 PUBLIC RECOMMENDED_BYTES_SECTOR   ;
 PUBLIC COPY			   ;
 PUBLIC S_OWNER_SAVED		   ;
 PUBLIC T_OWNER_SAVED		   ;
 PUBLIC SOURCE_DRIVE		   ;
 PUBLIC TARGET_DRIVE		   ;
 PUBLIC S_DRV_SECT_TRACK	   ;
 PUBLIC S_DRV_HEADS		   ;
 PUBLIC S_DRV_TRACKS		   ;
 PUBLIC T_DRV_SECT_TRACK	   ;
 PUBLIC T_DRV_HEADS		   ;
 PUBLIC T_DRV_TRACKS		   ;
 PUBLIC USER_OPTION		   ;
 PUBLIC COPY_TYPE		   ;
 PUBLIC BUFFER_BEGIN		   ;
 PUBLIC BUFFER_END		   ;
 PUBLIC TRACK_TO_READ		   ;
 PUBLIC TRACK_TO_WRITE		   ;
 PUBLIC SIDE			   ;
 PUBLIC USER_INPUT		   ;
 PUBLIC MAIN_EXIT		   ;

 PUBLIC IO_ERROR		   ;

 PUBLIC DS_IOCTL_DRV_PARM	   ;PLACE HOLDER FOR DEFAULT SOURCE DRV PARM
 PUBLIC DT_IOCTL_DRV_PARM	   ;PLACE HOLDER FOR DEFAULT TARGET DRV PARM
 PUBLIC DS_specialFunctions	   ;AND THEIR CONTENTS
 PUBLIC DT_specialFunctions	   ;
 PUBLIC DS_deviceType		   ;
 PUBLIC DT_deviceType		   ;
 PUBLIC DS_deviceAttributes	   ;
 PUBLIC DT_deviceAttributes	   ;
 PUBLIC DS_numberOfCylinders	   ;
 PUBLIC DT_numberOfCylinders	   ;
 PUBLIC DS_mediaType		   ;
 PUBLIC DT_mediaType		   ;
 PUBLIC DS_BPB_PTR		   ;
 PUBLIC DT_BPB_PTR		   ;

 PUBLIC MS_IOCTL_DRV_PARM	   ;DRIVE PARM FROM SOURCE MEDIUM
 PUBLIC MT_IOCTL_DRV_PARM	   ;DRIVE PARM FROM TARGET MEDIUM

;*****************************************************************************
 ORG	100H			   ;PROGRAM ENTRY POINT

DISKCOPY:			   ;
 JMP	BEGIN			   ;
;*****************************************************************************

;INTERNAL STACK AREA
 EVEN				   ;AN000;MAKE STACK WORD ALIGNED
 DB	64 DUP ('STACK   ')	   ;512 BYTES
MY_STACK_PTR LABEL WORD 	   ;

;*****************************************************************************
;									     *
;			INTERNAL VARIABLES				     *
;									     *
;*****************************************************************************
;		     $salut (4,22,26,36) ;AN000;
; INPUT PARMETERS FROM INIT SUBROUTINE:

S_OWNER_SAVED	     DB  0	   ;DRIVE LETTER THAT OWNED SOUCE DRIVE OWNERSHIP
T_OWNER_SAVED	     DB  0	   ;

RECOMMENDED_BYTES_SECTOR DW 0	   ;RECOMMENED BYTES/SECTOR FROM DEVICE PARA
SOURCE_DRIVE	     DB  0	   ;SOURCE DRIVE ID: 1=DRV A, 2=DRV B ETC.
TARGET_DRIVE	     DB  0	   ;TARGET DRIVE ID
USER_OPTION	     DB  0	   ;=1 OF /1 OPTION IS ENTERED
COPY_TYPE	     DB  1	   ;SINGLE DRV COPY=1, DOUBLE DRIVE COPY=2
BUFFER_BEGIN	     DW  1000H	   ;BEGINNING OF BUFFER ADDR [IN SEGMENT]
BUFFER_END	     DW  3FF0H	   ;END OF BUFFER ADDR [IN SEGMENT]
S_DRV_SECT_TRACK     DB  ?	   ;SECT/TRACK, device informations.
S_DRV_HEADS	     DB  ?	   ;# OF HEADS
S_DRV_TRACKS	     DB  ?	   ;# OF TRACKS
T_DRV_SECT_TRACK     DB  ?	   ;
T_DRV_HEADS	     DB  ?	   ;
T_DRV_TRACKS	     DB  ?	   ;

;DEFAULT BPB FOR OLD MEDIA
;5.25, 48 TPI BPB SINGLE SIDE (9 SECTORS/TRACK)
BPB48_SINGLE	     DW  512	   ;BYTES/SECTOR
		     DB  1	   ;SECTOR/CLUSTER
		     DW  1	   ;# OF RESERVED SECTORS
		     DB  2	   ;# OF FATS
		     DW  40h	   ;# OF ROOT ENTRY
		     DW  168h	   ;TOTAL # OF SECTORS IN THE MEDIA
		     DB  0FCh	   ;MEDIA BYTE
		     DW  2	   ;SECTORS/FAT

;5.25, 48 TPI BPB DOUBLE SIDE (9 SECTORS/TRACK)
BPB48_DOUBLE	     DW  512	   ;BYTES/SECTOR
		     DB  2	   ;SECTOR/CLUSTER
		     DW  1	   ;# OF RESERVED SECTORS
		     DB  2	   ;# OF FATS
		     DW  70h	   ;# OF ROOT ENTRY
		     DW  2D0h	   ;TOTAL # OF SECTORS IN THE MEDIA
		     DB  0FDh	   ;MEDIA BYTE
		     DW  2	   ;SECTORS/FAT

;5.25, 96 TPI BPB DOUBLE SIDE (15 SECTORS/TRACK)
BPB96		     DW  512	   ;BYTES/SECTOR
		     DB  1	   ;SECTOR/CLUSTER
		     DW  1	   ;# OF RESERVED SECTORS
		     DB  2	   ;# OF FATS
		     DW  0E0h	   ;# OF ROOT ENTRY
		     DW  960h	   ;TOTAL # OF SECTORS IN THE MEDIA
		     DB  0F9h	   ;MEDIA BYTE
		     DW  7	   ;SECTORS/FAT
BPB96_LENG	     EQU $-BPB96   ;THIS LENGTH WILL BE USED FOR BPB48 ALSO.

;			LOCAL VARIABLES:
VOLSER_FLAG	     DB  0	   ;AN000;0=EITHER MEDIA NOT READ YET, OR
;				    SOURCE VOL SER ID NOT AVAILABLE
;				    1=TARGET NEEDS VOL SER WRITTEN
SERIAL		     DD  0	   ;AN013;SERIAL NUMBER OF NEW DISKETTE
EXITFL		     DB  EXOK	   ;AN000;ERRORLEVEL VALUE
		     PUBLIC EXITFL ;AN000;
		     PUBLIC EXPAR  ;AN000;
EXCBR		     EQU 2	   ;AN000;CONTROL BREAK
EXVER		     EQU 1	   ;AN000;BAD DOS VERSION ERRORLEVEL CODE
EXPAR		     EQU 1	   ;AN000; BAD PARMS, OR OTHER ERRORS
EXOK		     EQU 0	   ;AN000;NORMAL ERRORLEVEL RET CODE

S_DRV_SET_FLAG	     DB  0	   ;1 = SOURCE DRIVE PARM HAD BEEN SET
T_DRV_SET_FLAG	     DB  0	   ;1 = TARGET DRIVE PARM HAD BEEN SET

IOCTL_SECTOR	     DW  1	   ;used for READ_A_SECTOR routine.
IOCTL_TRACK	     DW  0	   ;IN THE TRACK
IOCTL_HEAD	     DW  0	   ;HEAD 0
SAV_CSECT	     DW  0	   ;TEMPORARY SAVING PLACE
SAV_CN1 	     DW  0	   ;
SAV_CB1 	     DW  0	   ;
SAV_CYLN	     DW  0	   ;

BOOT_SECT_TRACK      DW  0	   ;TEMP SAVING PLACE OF SECTOR/TRACK
BOOT_TOT_TRACK	     DW  0	   ;FOUND FROM THE BOOT SECTOR. max # of tracks
BOOT_NUM_HEAD	     DW  0	   ;NUMBER OF HEADS
BOOT_BYTE_SECTOR     DW  0	   ;BYTES / SECTOR

READ_S_BPB_FAILURE   DB  0	   ;GET MEDIA BPB. SUCCESS=0, FAILURE=1
READ_T_BPB_FAILURE   DB  0	   ;

;*** Informations from CHECK_SOURCE.
;*** These will be used as a basis for the copy process.
LAST_TRACK	     DB  79	   ;LAST CYLINDER OF THE DASD (39 OR 79)
END_OF_TRACK	     DB  15	   ;END OF TRACK, 8,9 OR 15 CURRENTLY.
bSECTOR_SIZE	     DW  512	   ;BYTES/SECTOR in bytes
NO_OF_SIDES	     DB  ?	   ;0=SINGLE SIDED, 1=DOUBLE SIDED

FORMAT_FLAG	     DB  0	   ;(ON/OFF) FORMAT BEFORE WRITE IF TURNED ON
TRACK_TO_READ	     DB  0	   ;NEXT TRACK TO READ
TRACK_TO_WRITE	     DB  0	   ;NEXT TRACK TO WRITE
TRACK_TO_FORMAT      DB  0	   ;STARTS FORMAT WITH THIS TRACK
				   ; TO THE LAST TRACK
TRACK_SIZE	     DW  ?	   ;BYTES/CYLINDER [IN SEGMENTS]
SECTOR_SIZE	     DB  ?	   ;BYTES/SECTOR [IN SEGMENTS]
BUFFER_PTR	     DW  ?	   ;BUFFER POINTER FOR READ/WRITE OP
COPY_ERROR	     DB  0	   ;=0 IF NO ERROR, >0 IF ERROR DETECTED
SIDE		     DB  ?	   ;NEXT SIDE TO READ/WRITE (0,1)
SIDE_TO_FORMAT	     DB  0	   ;NEXT SIDE TO FORMAT (0, 1)
OPERATION	     DB  ?	   ;READ/WRITE/VERIFY OPERATION
COPY_STATUS	     DB  ?	   ;(OK OR FATAL) ABORT COPY PROCESS IF FATAL
USER_INPUT	     DB  ?	   ;DISKCOPY AGAIN?
IO_ERROR	     DB  0	   ;SET BY EXTENDED_ERROR_HANDLER
UKM_ERR 	     DB  0	   ;AN011;IF ON, HARD ERROR IS TYPE: "UNKNOWN MEDIA"
MSG_FLAG	     DB  ?	   ;USED TO INDICATE IF READ/WRITE ERROR MESSAGE
				   ;IS TO BE DISPLAYED (ON/OFF)
TARGET_OP	     DB  0	   ;FLAG TO INDICATE ANY OPERATIONS ON TARGET
TRY_FORMAT_FLAG      DB  0	   ;FLAG TO INDICATE "TRY_FORMAT" PROCEDURE TO
				   ; CHECK THE "TIME OUT ERROR"
TIME_OUT_FLAG	     DB  0	   ;FLAG TO INDICATE THE "TIME OUT" ERROR
				   ; WAS A REAL "TIME OUT ERROR"
SELECT_FLAG	     DB  0	   ;INDICATES SELECT IS PRESENT
		     PAGE	   ;
;		    DEVICE PARAMETER TABLE
;the returned info. still has the following format.

DS_IOCTL_DRV_PARM    LABEL BYTE    ;PLACE HOLDER FOR DEFAULT TARGET DRV PARM
DS_specialFunctions  db  ?	   ;
DS_deviceType	     db  ?	   ;0 - 5.25"(48tpi), 1 - 5.25"(96tpi),
				   ; 2 - 3.5"(720KB)
DS_deviceAttributes  dw  ?	   ;0001h - NOT REMOVABLE,
				   ; 0002h - CHANGE LINE SUPPORTED
DS_numberOfCylinders dw  ?	   ;
DS_mediaType	     db  ?	   ;
DS_BPB_PTR	     LABEL BYTE    ;
DS_deviceBPB	     my_bpb <>	   ;
DS_trackLayout	     LABEL WORD    ;AC000;
		     my_trackLayout ;AC000;
;---------------------------------------

DT_IOCTL_DRV_PARM    LABEL BYTE    ;
DT_specialFunctions  db  ?	   ;
DT_deviceType	     db  ?	   ;
DT_deviceAttributes  dw  ?	   ;0001h - NOT REMOVABLE,
				   ; 0002h - CHANGE LINE SUPPORTED
DT_numberOfCylinders dw  ?	   ;
DT_mediaType	     db  ?	   ;
DT_BPB_PTR	     LABEL BYTE    ;
DT_deviceBPB	     my_bpb <>	   ;
DT_trackLayout	     LABEL WORD    ;AC000;
		     my_trackLayout ;AC000;

;---------------------------------------

MS_IOCTL_DRV_PARM    LABEL BYTE    ;DRIVE PARM FROM SOURCE MEDIUM
MS_specialFunctions  db  ?	   ;
MS_deviceType	     db  ?	   ;
MS_deviceAttributes  dw  ?	   ;0001h - NOT REMOVABLE,
				   ; 0002h - CHANGE LINE SUPPORTED
MS_numberOfCylinders dw  ?	   ;
MS_mediaType	     db  ?	   ;
MS_BPB_PTR	     LABEL BYTE    ;
MS_deviceBPB	     my_bpb <>	   ;
MS_deviceBPB_leng    equ $-MS_deviceBPB ;
MS_trackLayout	     LABEL WORD    ;AC000;
		     my_trackLayout ;AC000;
;---------------------------------------
MT_IOCTL_DRV_PARM    LABEL BYTE    ;DRIVE PARM FROM TARGET MEDIUM
MT_specialFunctions  db  ?	   ;
MT_deviceType	     db  ?	   ;
MT_deviceAttributes  dw  ?	   ;0001h - NOT REMOVABLE,
				   ; 0002h - CHANGE LINE SUPPORTED
MT_numberOfCylinders dw  ?	   ;
MT_mediaType	     db  ?	   ;
MT_BPB_PTR	     LABEL BYTE    ;
MT_deviceBPB	     my_bpb <>	   ;
MT_trackLayout	     LABEL WORD    ;AC000;
		     my_trackLayout ;AC000;


;		IOCTL  format a track function control string.
IOCTL_FORMAT	     LABEL BYTE    ;
FspecialFunctions    db  0	   ;
FHead		     dw  ?	   ;
FCylinder	     dw  ?	   ;

;		IOCTL read/write a track.
IOCTL_R_W	     LABEL BYTE    ;
specialFunctions     db  0	   ;
Head		     dw  ?	   ;
Cylinder	     dw  ?	   ;
FirstSectors	     dw  ?	   ;
numberOfSectors      dw  ?	   ;
TAddress_off	     dw  ?	   ;
TAddress_seg	     dw  ?	   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
;		GET/SET MEDIA ID - FUNCTION OF GENERIC IOCTL
;			(USED BY VOLSER PROC)
;(Deleted ;AN013;) MEDIA_ID_BUF A_MEDIA_ID_INFO <> ;				;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =
		     PATHLABL DISKCOPY ;AN015;
		     HEADER <BEGIN - VERSION CHECK, SYSMSG INIT, EXIT TO DOS> ;AN000;
		     PUBLIC DISKCOPY_BEGIN ;
DISKCOPY_BEGIN	     LABEL NEAR    ;

;*****************************************************************************
;									     *
;		 D I S K C O P Y   M A I N   P R O G R A M		     *
;									     *
;*****************************************************************************
;  $salut (4,4,10,36)		   ;AN000;
BEGIN PROC NEAR 		   ;
   PUBLIC BEGIN 		   ;AN000;
;OUTPUT - "EXITFL" HAS ERRORLEVEL RETURN CODE

   MOV	 SP, OFFSET MY_STACK_PTR   ;MOVE SP TO MY STACK PTR
   CALL  SYSLOADMSG		   ;AN000;INIT SYSMSG HANDLER

;  $IF	 C			   ;AN000;IF THERE WAS A PROBLEM
   JNC $$IF1
       CALL  SYSDISPMSG 	   ;AN000;LET HIM SAY WHY HE HAD A PROBLEM

       MOV   EXITFL,EXVER	   ;AN000;TELL ERRORLEVEL BAD DOS VERSION
;  $ELSE			   ;AN000;SINCE SYSDISPMSG IS HAPPY
   JMP SHORT $$EN1
$$IF1:
       CALL  INIT		   ;RUN INITIALIZATION ROUTINE

       CMP   DX,FINE		   ;CHECK FOR ERROR DURING INIT
;      $IF   E			   ;IF NO ERROR THEN PROCEED TO COPY
       JNE $$IF3
;	   $DO			   ;
$$DO4:
	       CALL  COPY	   ;PERFORM DISKCOPY

	       CALL  TEST_REPEAT   ;COPY ANOTHER ?

;	   $ENDDO C		   ;
	   JNC $$DO4
				   ;NORMAL RETURN CODE ALREADY IN "EXITFL"
;      $ELSE			   ;ELSE IF ERROR DETECTED IN INIT
       JMP SHORT $$EN3
$$IF3:
.XLIST				   ;
;      PUSH  DX
;      PUSH  CS
;      CALL  PRINTF		   ;DISPLAY ERROR MESSAGE
.LIST				   ;
	   MOV	 DI,DX		   ;PASS NUMBER OF ERROR MSG, IF ANY		;AD000;
				   ;DI HAS OFFSET OF MESSAGE DESCRIPTOR
	   CALL  SENDMSG	   ;AC000;DISPLAY THE ERROR MESSAGE

	   MOV	 EXITFL,EXVER	   ;AC000;ERROR RETURN CODE
;      $ENDIF			   ;
$$EN3:
       JMP   SHORT EXIT_TO_DOS	   ;

MAIN_EXIT:			   ;COME HERE AFTER CONTROL-BREAK
       MOV   EXITFL,EXCBR	   ;AC000;  FOR CONTROL-BREAK EXIT

EXIT_TO_DOS:			   ;
       XOR   BX, BX		   ;

       MOV   BL, S_OWNER_SAVED	   ;RESTORE ORIGINAL SOURCE,
				   ; TARGET DRIVE OWNER.
       CALL  SET_LOGICAL_DRIVE	   ;

       MOV   BL, T_OWNER_SAVED	   ;
       CALL  SET_LOGICAL_DRIVE	   ;

       CMP   S_DRV_SET_FLAG, 0	   ;
;      $IF   NE 		   ;AN000;
       JE $$IF8
	   MOV	 BL, SOURCE_DRIVE  ;
	   MOV	 DS_specialFunctions, SET_SP_FUNC_DOS ;=0
	   MOV	 DX, OFFSET DS_IOCTL_DRV_PARM ;
	   CALL  SET_DRV_PARM_DEF  ;RESTORE SOURCE DRIVE PARM

;      $ENDIF			   ;AN000;
$$IF8:

       CMP   T_DRV_SET_FLAG, 0	   ;
;      $IF   NE 		   ;AN000;
       JE $$IF10
	   MOV	 BL, TARGET_DRIVE  ;
	   MOV	 DT_specialFunctions, SET_SP_FUNC_DOS ;=0
	   MOV	 DX, OFFSET DT_IOCTL_DRV_PARM ;
	   CALL  SET_DRV_PARM_DEF  ;RESTORE TARGET DRIVE PARM

;      $ENDIF			   ;AN000;
$$IF10:
EXIT_PROGRAM:			   ;

;  $ENDIF			   ;AN000;OK WITH SYSDISPMSG?
$$EN1:
   MOV	 AL,EXITFL		   ;AN000;PASS BACK ERRORLEVEL RET CODE
   DOSCALL RET_CD_EXIT		   ;AN000;RETURN TO DOS WITH RET CODE

   INT	 20H			   ;AN000;IF ABOVE NOT WORK,
BEGIN ENDP			   ;AN000;
; = = = = = = = = = = = = = = = = =
   HEADER <SET_LOGICAL_DRIVE - SET LOG. DRV LETTER THAT OWNS DRIVE> ;AN000;
   PUBLIC SET_LOGICAL_DRIVE	   ;
;*****************************************************************************
SET_LOGICAL_DRIVE PROC NEAR	   ;
;	*** SET THE LOGICAL DRIVE LETTER THAT WILL BE THE OWNER OF THE DRIVE
;	INPUT: BL - DRIVE LETTER
;	OUTPUT: OWNER WILL BE SET ACCORDINGLY.
;*****************************************************************************
   CMP	 BL, 0			   ;
;  $IF	 NE			   ;IF BL = 0, THEN JUST RETURN
   JE $$IF13
				   ;ELSE SET BL AS AN OWNER OF THAT DRIVE
       MOV   AX,(IOCTL_FUNC SHL 8)+SET_LOGIC_DRIVE ;AC000;
       INT   21H		   ;
;  $ENDIF			   ;
$$IF13:
   RET				   ;
SET_LOGICAL_DRIVE ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <COPY - COPY THE DISKETTE IMAGE> ;AN000;
;*****************************************************************************
;MODULE NAME:  COPY							     *
;									     *
;      INPUT:  COPY_TYPE  BYTE	1=SINGLE DRIVE COPY			     *
;				2=DOUBLE DRIVE COPY			     *
;									     *
;     OUTPUT:  NONE							     *
;*****************************************************************************
COPY PROC NEAR			   ;COPY DISKETTE IMAGE
   MOV	 VOLSER_FLAG,0		   ;AN000;RESET MEDIA ID VOL SERIAL NUMBER FLAG
   MOV	 COPY_ERROR,0		   ;RESET COPY ERROR FLAG
   MOV	 COPY_STATUS,OK 	   ;RESET COPY STATUS BYTE
   MOV	 TARGET_OP, OFF 	   ;
   MOV	 TRY_FORMAT_FLAG, OFF	   ;
   MOV	 TIME_OUT_FLAG, OFF	   ;
   MOV	 FORMAT_FLAG,OFF	   ;ASSUME FORMAT IS NOT REQUIRED
   MOV	 READ_S_BPB_FAILURE, 0	   ;RESET GET BPB FAILURE FLAG
   MOV	 READ_T_BPB_FAILURE, 0	   ;
   MOV	 AX, RECOMMENDED_BYTES_SECTOR ;
   MOV	 bSECTOR_SIZE, AX	   ;USE RECOMMENDED SECTOR SIZE TO READ A SECTOR
   CMP	 COPY_TYPE,2		   ;IF TWO DRIVE COPY
;  $IF	 E			   ;
   JNE $$IF15
       PRINT MSGNUM_LOAD_SOURCE    ;AC000;OUTPUT LOAD SOURCE DISKETTE MESSAGE
				   ;"INSERT SOURCE DISKETTE INTO DRIVE X:"

       PRINT MSGNUM_LOAD_TARGET    ;AC000;"INSERT TARGET DISKETTE INTO DRIVE X:"

       CALL  PRESS_ANY_KEY	   ;AC000;"PRESS ANY KEY TO CONTINUE" (WAIT FOR KEYB)

;  $ENDIF			   ;
$$IF15:
   MOV	 TRACK_TO_READ,0	   ;INITIALIZE TRACK NUMBERS
   MOV	 TRACK_TO_WRITE,0	   ;

COPY_TEST_END:			   ;
;  $SEARCH			   ;
$$DO17:
       MOV   AL,TRACK_TO_WRITE	   ;WHILE TRACK_TO_WRITE<=LAST_TRACK
       CMP   AL,LAST_TRACK	   ;
;  $LEAVE A			   ;
   JA $$EN17
       CALL  READ_SOURCE	   ;READ AS MANY TRACK AS POSSIBLE

       CMP   COPY_STATUS,FATAL	   ;MAKE SURE DRIVES WERE COMPATIBLE
;  $EXITIF E,NUL,OR		   ;
   JE $$SR17
       CALL  WRITE_TARGET	   ;WRITE THE CONTENT OF BUFFER TO TARGET

       CMP   COPY_STATUS,FATAL	   ;MAKE SURE TARGET AND SOURCE
;  $EXITIF E,NUL		   ;
   JE $$SR17
;  $ENDLOOP			   ;
   JMP SHORT $$DO17
$$EN17:

       CMP   COPY_ERROR,FALSE	   ;IF ERROR IN COPY
;      $IF   NE 		   ;
       JE $$IF21
				   ;CR,LF,"Target diskette may be unusable",CR,LF
	   PRINT MSGNUM_TARGET_MB_UNUSABLE ;AC000;

;      $ENDIF			   ;
$$IF21:
;  $ENDSRCH			   ;
$$SR17:
   CMP	 COPY_STATUS,FATAL	   ;WAS COPY ABORTED ?
;  $IF	 E			   ;
   JNE $$IF24
				   ;CR,LF,"Copy process ended",CR,LF
       PRINT MSGNUM_FATAL_ERROR    ;AC000;IF SO THEN TELL USER

;  $ELSE			   ;AN000;SINCE NOT ABORTED,
   JMP SHORT $$EN24
$$IF24:
       CALL  WRITE_VOLSER	   ;AN000;GO CHANGE VOLID OF TARGET

;  $ENDIF			   ;
$$EN24:
   RET				   ;

COPY ENDP			   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <TEST_REPEAT - SEE IF USER WANTS TO COPY ANOTHER> ;AN000;
;*****************************************************************************
;									     *
   PUBLIC TEST_REPEAT		   ;AN000;MAKE ENTRY IN LINK MAP
TEST_REPEAT PROC NEAR		   ;TEST IF USER WANTS TO COPY ANOTHER		*
;				 DISKETTE				     *
; INPUT : USER_INPUT ("Y" OR "N")
; OUTPUT: NC = COPY AGAIN						     *
;	  CY = EXIT TO DOS						     *
;*****************************************************************************
;  $SEARCH COMPLEX		   ;AC000;REPEAT THIS PROMPT UNTIL (Y/N) RESPONDED
   JMP SHORT $$SS27
$$DO27:
       PRINT MSGNUM_CR_LF	   ;AC000;

;  $STRTSRCH			   ;AN000;
$$SS27:
				   ;CR,LF,"Copy another diskette (Y/N)?"
       PRINT MSGNUM_COPY_ANOTHER   ;AC000;SEE IF USER WANTS TO COPY ANOTHER
				   ; AND READ RESPONSE TO AL
       PUSH  AX 		   ;AN000;SAVE THE RESPONSE
       PRINT MSGNUM_CR_LF	   ;AC000;

       POP   DX 		   ;AN000;RESTORE THE REPONSE CHAR TO DL
       CALL  YESNO		   ;AN000;CHECK FOR (Y/N)
				   ;AX=0,NO; AX=1,YES; AX=2,INVALID
;  $EXITIF C,NUL		   ;AN000;IF CARRY SET, PROBLEM,PRETEND "NO"
   JC $$SR27

       CMP   AX,BAD_YESNO	   ;AN000;WAS THE RESPONSE INVALID?
;  $ENDLOOP B			   ;AN000;QUIT IF OK ANSWER (AX=0 OR 1)
   JNB $$DO27
       CMP   AL,YES		   ;AN000;WAS "YES" SPECIFIED
;      $IF   E			   ;AN000;IF "YES"
       JNE $$IF31
	   CLC			   ;AN000;CLEAR CARRY TO INDICATE COPY AGAIN
;      $ELSE			   ;AN000;SINCE NOT "YES"
       JMP SHORT $$EN31
$$IF31:
	   STC			   ;AN000;SET CARRY TO INDICATE NO REPEAT
;      $ENDIF			   ;AN000;
$$EN31:
;  $ENDSRCH			   ;AN000;
$$SR27:
.XLIST				   ;
;	MOV   AL,USER_INPUT
;	AND   AL,11011111B	    ;MAKE USER INPUT UPPER CASE
;	CMP   AL,YES		    ;IF YES THEN COPY AGAIN
;   $EXITIF E
;	CLC			    ;CLEAR CARRY TO INDICATE COPY AGAIN
;   $ORELSE
;	CMP   AL,NO		    ;IF NOT "N" OR "Y" THEN PROMPT AGAIN
;   $ENDLOOP E
;	STC			    ;SET CARRY TO INDICATE NO REPEAT
;   $ENDSRCH
.LIST				   ;
   RET				   ;

TEST_REPEAT ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <READ_SOURCE - READ FROM SOURCE AS MUCH AS POSSIBLE> ;AN000;
;*****************************************************************************
;									     *
   PUBLIC READ_SOURCE		   ;AN000;MAKE ENTRY IN LINK MAP		   *
READ_SOURCE PROC NEAR		   ;READ AS MANY TRACKS AS POSSIBLE FROM SOURCE*
;			    ;DISKETTE TO FILL THE AVAILABLE BUFFER SPACE     *
;*****************************************************************************

   CMP	 COPY_TYPE,1		   ;IF SINGLE DRIVE COPY
;  $IF	 E			   ;PROMPT MSG
   JNE $$IF35
       PRINT MSGNUM_LOAD_SOURCE    ;AN000;"INSERT SOURCE DISKETTE INTO DRIVE X:"

       CALL  PRESS_ANY_KEY	   ;AC000;"PRESS ANY KEY TO CONTINUE" (WAIT FOR KEYB)

;  $ENDIF			   ;
$$IF35:
   CMP	 TRACK_TO_READ,0	   ;1ST TRACK ?
;  $IF	 NE,OR			   ;IF NOT
   JNE $$LL37

   CALL  CHECK_SOURCE		   ;DO NECESSARY CHECKING

   CALL  CALC_TRACK_SIZE	   ;

   CALL  CHECK_MEMORY_SIZE	   ;

   CMP	 COPY_STATUS,FATAL	   ;
;  $IF	 NE			   ;
   JE $$IF37
$$LL37:
;(deleted ;AN013;) CALL  READ_VOLSER ;GO READ THE MEDIA ID TO GET SERIAL NUMBER ;AN000;

       MOV   BX,BUFFER_BEGIN	   ;
       MOV   BUFFER_PTR,BX	   ;INITIALIZE BUFFER POINTER

;      $DO			   ;
$$DO38:
	   MOV	 AL,TRACK_TO_READ  ;DID WE FINISH READING ALL TRACKS?
	   CMP	 AL,LAST_TRACK	   ;
;      $LEAVE A 		   ;
       JA $$EN38
	   MOV	 AX,BUFFER_PTR	   ;DID WE RUN OUT OF BUFFER SPACE
	   ADD	 AX,TRACK_SIZE	   ;
	   CMP	 AX,BUFFER_END	   ;
;      $LEAVE A 		   ;
       JA $$EN38
	   MOV	 OPERATION,READ_FUNC ;
	   CALL  READ_WRITE_TRACK  ;NO, GO READ ANOTHER TRACK

	   INC	 TRACK_TO_READ	   ;
;      $ENDDO			   ;
       JMP SHORT $$DO38
$$EN38:
;  $ENDIF			   ;
$$IF37:
   RET				   ;
READ_SOURCE ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <WRITE_TARGET - WRITE DATA FROM MEMORY TO TARGET DISKETTE> ;AN000;
;*****************************************************************************
;									     *
   PUBLIC WRITE_TARGET		   ;AN000;MAKE ENTRY IN LINK MAP
WRITE_TARGET PROC		   ;WRITE DATA FROM MEMORY TO TARGET DISKETTE*
;									     *
;*****************************************************************************

   CMP	 COPY_TYPE,1		   ;IF SINGLE DRIVE COPY
;  $IF	 E			   ;PROMPT MSG
   JNE $$IF43
       PRINT MSGNUM_LOAD_TARGET    ;AC000;"INSERT TARGET DISKETTE INTO DRIVE X:"

       CALL  PRESS_ANY_KEY	   ;AC000;"PRESS ANY KEY TO CONTINUE" (WAIT FOR KEYB)

;  $ENDIF			   ;
$$IF43:
   MOV	 TARGET_OP, ON		   ;INDICATE A OPERATION ON TARGET
   MOV	 BX,BUFFER_BEGIN	   ;
   MOV	 BUFFER_PTR,BX		   ;INITIALIZE BUFFER POINTER
   CMP	 TRACK_TO_WRITE,0	   ;IF TRK 0, CHECK COMPATIBILITY
;  $IF	 NE,OR			   ;
   JNE $$LL45

   MOV	 SIDE, 0		   ;
   CALL  CHECK_TARGET		   ;

   CMP	 COPY_STATUS,FATAL	   ;IF INCOMPATIBLE, THEN EXIT
;  $IF	 NE			   ;
   JE $$IF45
$$LL45:

;      $DO			   ;
$$DO46:
	   MOV	 AL,TRACK_TO_WRITE ;DID WE FINISH WRITING ALL TRACKS?
	   CMP	 AL,LAST_TRACK	   ;
;      $LEAVE A 		   ;
       JA $$EN46
	   MOV	 AX,BUFFER_PTR	   ;DID WE RUN OUT OF BUFFER SPACE
	   ADD	 AX,TRACK_SIZE	   ;
	   CMP	 AX,BUFFER_END	   ;
;      $LEAVE A 		   ;
       JA $$EN46
	   MOV	 OPERATION,WRITE_FUNC ;
	   CALL  READ_WRITE_TRACK  ;NO, GO WRITE ANOTHER TRACK

	   CMP	 COPY_STATUS,FATAL ;IF INCOMPATIBLE, THEN EXIT
;      $LEAVE E 		   ;
       JE $$EN46
	   INC	 TRACK_TO_WRITE    ;
;      $ENDDO			   ;
       JMP SHORT $$DO46
$$EN46:
;  $ENDIF			   ;
$$IF45:
   MOV	 TARGET_OP, OFF 	   ;
   RET				   ;
WRITE_TARGET ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <READ_WRITE_TRACK - READ A TRACK AND STORE IT INTO MEMORY> ;AN000;
;*****************************************************************************
;									     *
   PUBLIC READ_WRITE_TRACK	   ;AN000;MAKE ENTRY IN LINK MAP
READ_WRITE_TRACK PROC NEAR	   ;READ A TRACK AND STORE IT INTO MEMORY   *
;									     *
;INPUT:  OPERATION = 61h THEN READ OPERATION				     *
;		     41h THEN WRITE OPERATION				     *
;*****************************************************************************

   MOV	 SIDE, 0		   ;
;  $DO				   ;
$$DO52:
       MOV   MSG_FLAG, ON	   ;
       CMP   OPERATION, READ_FUNC  ;
;      $IF   E			   ;
       JNE $$IF53
	   CALL  READ_OP	   ;

;      $ELSE			   ;
       JMP SHORT $$EN53
$$IF53:
	   CALL  WRITE_OP	   ;

	   CMP	 COPY_STATUS, FATAL ;
	   JE	 RWT_EXIT	   ;

;      $ENDIF			   ;
$$EN53:
       CMP   NO_OF_SIDES, 0	   ;SINGLE SIDE COPY?
;      $IF   E			   ;YES
       JNE $$IF56
	   MOV	 AX, TRACK_SIZE    ;
;      $ELSE			   ;NO, DOUBLE SIDE
       JMP SHORT $$EN56
$$IF56:
	   XOR	 DX, DX 	   ;
	   MOV	 AX, TRACK_SIZE    ;
	   MOV	 CX, 2		   ;
	   DIV	 CX		   ;AX / 2
;      $ENDIF			   ;
$$EN56:
       ADD   BUFFER_PTR, AX	   ;
       INC   SIDE		   ;NEXT SIDE
       MOV   AL, SIDE		   ;
       CMP   AL, NO_OF_SIDES	   ;FINISHED WITH THE LAST SIDE?
;  $ENDDO G			   ;
   JNG $$DO52
RWT_EXIT:			   ;
   RET				   ;
READ_WRITE_TRACK ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <READ_OP - IOCTL READ A TRACK OPERATION> ;AN000;
;*****************************************************************************
;									     *
   PUBLIC READ_OP		   ;AN000;MAKE ENTRY IN LINK MAP
READ_OP PROC NEAR		   ;IOCTL READ A TRACK OPERATION	*
;									     *
;*****************************************************************************

;  $SEARCH			   ;
$$DO60:
       XOR   AX, AX		   ;
       MOV   AL, SIDE		   ;
       MOV   Head, AX		   ;HEAD TO READ
       MOV   AL, TRACK_TO_READ	   ;
       MOV   Cylinder, AX	   ;TRACK TO READ
       MOV   FirstSectors, 0	   ;???? SHOULD BE 1 BUT CURRENTLY 0 ???
       MOV   AX, BUFFER_PTR	   ;
       MOV   Taddress_seg, AX	   ;BUFFER ADDRESS
       MOV   Taddress_off, 0	   ;
       XOR   BX, BX		   ;
       MOV   BL, SOURCE_DRIVE	   ;
       MOV   CL, READ_FUNC	   ;=61h
       MOV   DX, OFFSET IOCTL_R_W  ;
       CALL  GENERIC_IOCTL	   ;

       CMP   IO_ERROR, NO_ERROR    ;OK?
;  $EXITIF E			   ;AC013;IF NO ERROR SO FAR, GOOD
   JNE $$IF60
       CMP   CYLINDER,0 	   ;AN013;IS THIS THE FIRST READ?
;      $IF   E,AND		   ;AN013;IF THIS IS THE FIRST TRACK, AND
       JNE $$IF62
       CMP   HEAD,0		   ;AN013;IS THIS THE FIRST SIDE?
;      $IF   E			   ;AN013;AND IF THIS IS THE FIRST SIDE
       JNE $$IF62
	   CALL  MAYBE_ADJUST_SERIAL ;AN013;IF BOOT HAS SERIAL, GENERATE NEW ONE

;      $ENDIF			   ;AN013;FIRST TRACK AND HEAD?
$$IF62:
;  $ORELSE			   ;AN013;SINCE SOME KIND OF ERROR, OOPS
   JMP SHORT $$SR60
$$IF60:
       CMP   IO_ERROR, SOFT_ERROR  ;TRY AGAIN?
;  $ENDLOOP NE			   ;
   JE $$DO60

       CMP   MSG_FLAG, ON	   ;ELSE HARD ERROR. SEE IF
				   ; MESSAGE TO BE DISPLAYED
;      $IF   E			   ;
       JNE $$IF66

	   MOV	 AH, READ_FUNC	   ;
	   mov	 dl, source_drive  ;
	   CALL  ERROR_MESSAGE	   ;

	   INC	 COPY_ERROR	   ;INCREASE COPY_ERROR COUNT
	   MOV	 MSG_FLAG, OFF	   ;
;      $ENDIF			   ;
$$IF66:
;  $ENDSRCH			   ;
$$SR60:
   RET				   ;
READ_OP ENDP			   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <MAYBE_ADJUST_SERIAL - MAKE NEW SERIAL IN BOOT> ;AN013;
MAYBE_ADJUST_SERIAL PROC NEAR	   ;AN013;
;INPUT: TADDRESS_OFF/_SEG HAS TRACK BUFFER WHICH HAS BOOT RECORD
;	"VOLSER_FLAG" IS FALSE.
;OUTPUT:SERIAL NUMBER FIELD IS MODIFIED TO HAVE NEW SERIAL NUMBER
;	A COPY OF WHICH IS PRESERVED IN "SERIAL" FOR LATER DISPLAY IN MSG.
;	"VOLSER_FLAG" SET TO TRUE TO INDICATE NEW SERIAL GENERATED.
;	IF THIS BOOT DOES NOT HAVE A SERIAL, NO CHANGE MADE, AND
;	"VOLSER_FLAG" LEFT AS FALSE.

;	A BOOT RECORD IS ASSUMED TO HAVE A SERIAL NUMBER IF:
;	EBPB_MEDIADESCRIPTOR=0F?H AND EXT_BOOT_SIG IS EITHER 28H OR 29H.

   PUSH  ES			   ;AN013;SAVE EXTRA SEG REG TEMPORARILY
   PUSH  BX			   ;AN013;AND SAVE THE BASE POINTER
   PUSH  SI			   ;AN013; AND THE INDEX
   LES	 BX,DWORD PTR TADDRESS_OFF ;AN013;POINT TO BUFFER AREA CONTAINING BOOT RECORD
   LEA	 SI,ES:[BX].EXT_BOOT_BPB   ;AN013;POINT TO BPB PORTION OF BOOT RECORD
   MOV	 AL,ES:[SI].EBPB_MEDIADESCRIPTOR ;AN013;GET TYPE OF MEDIA
   AND	 AL,0F0H		   ;AN013;SAVE LEFT NIBBLE ONLY
   CMP	 AL,0F0H		   ;AN013;IF DISKETTE HAS PROPER DESCRIPTOR
;  $IF	 E			   ;AN013;IF OK DESCRIPTOR
   JNE $$IF69
       MOV   AL,ES:[BX].EXT_BOOT_SIG ;AN013;GET "SIGNATURE" OF BOOT RECORD
       CMP   AL,28H		   ;AN013;IS THIS BOOT STYLE OF OS/2 1.0 OR 1.1?
;      $IF   E,OR		   ;AN013;YES, IS A BOOT WITH A SERIAL IN IT
       JE $$LL70
       CMP   AL,29H		   ;AN013;IS THIS A BOOT STYLE OF OS/S 1.2?
;      $IF   E			   ;AN013;YES, IS A BOOT WITH A SERIAL IN IT
       JNE $$IF70
$$LL70:
;		GET CURRENT DATE
	   DOSCALL GET_DATE	   ;AN013;READ SYSTEM DATE
				   ;OUTPUT: DL = DAY (1-31)
				   ;  AL = DAY OF WEEK (0=SUN,6=SAT)
				   ;  CX = YEAR (1980-2099)
				   ;  DH = MONTH (1-12)
	   PUSH  CX		   ;AN013;SAVE THESE FOR
	   PUSH  DX		   ;AN013; INPUT INTO HASH ALGORITHM
;		GET CURRENT TIME
	   DOSCALL GET_TIME	   ;AN013;READ SYSTEM TIME CLOCK
				   ;OUTPUT: CH = HOUR (0-23)
				   ;  CL = MINUTES (0-59)
				   ;  DH = SECONDS (0-59)
				   ;  DL = HUNDREDTHS (0-99)

;		   HASH THESE INTO A UNIQUE 4 BYTE NEW VOLUME SERIAL NUMBER:
;			   SERIAL+0 = DX FROM DATE + DX FROM TIME
;			   SERIAL+2 = CX FROM DATE + CX FROM TIME

	   POP	 AX		   ;AN013;GET THE DX FROM DATE
	   ADD	 AX,DX		   ;AN013;ADD IN THE DX FROM TIME
	   MOV	 WORD PTR SERIAL,AX ;AN013;SAVE FIRST RESULT OF HASH
	   MOV	 WORD PTR ES:[BX].EXT_BOOT_SERIAL,AX ;AN013;AND IN BOOT RECORD ITSELF

	   POP	 AX		   ;AN013;GET THE CX FROM DATE
	   ADD	 AX,CX		   ;AN013;ADD IN THE CX FROM TIME
	   MOV	 WORD PTR SERIAL+WORD,AX ;AN013;SAVE SECOND RESULT OF HASH
	   MOV	 WORD PTR ES:[BX].EXT_BOOT_SERIAL+WORD,AX ;AN013;AND IN BOOT RECORD

	   MOV	 VOLSER_FLAG,TRUE  ;AN013;REQUEST THE NEW VOL SERIAL NUMBER BE WRITTEN

;      $ENDIF			   ;AN013;BOOT HAVE SERIAL?
$$IF70:
;  $ENDIF			   ;AN013;PROPER DESCRIPTOR?
$$IF69:
   POP	 SI			   ;AN013;RESTORE THE INDEX REG
   POP	 BX			   ;AN013;RESTORE THE BASE POINTER
   POP	 ES			   ;AN013;RESTORE EXTRA SEG REG
   RET				   ;AN013;RETURN TO CALLER
MAYBE_ADJUST_SERIAL ENDP	   ;AN013;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <WRITE_OP - IOCTL WRITE A TRACK OPERATION> ;AN000;
;*****************************************************************************
;									     *
   PUBLIC WRITE_OP		   ;AN000;MAKE ENTRY IN LINK MAP
WRITE_OP PROC NEAR		   ;IOCTL WRITE A TRACK OPERATION	*
;									     *
;*****************************************************************************

WO_AGAIN:			   ;
;  $SEARCH			   ;
$$DO73:
       XOR   AX, AX		   ;
       MOV   AL, SIDE		   ;
       MOV   Head, AX		   ;HEAD TO WRITE
       MOV   AL, TRACK_TO_WRITE    ;
       MOV   Cylinder, AX	   ;TRACK TO WRITE
       MOV   FirstSectors, 0	   ;???? SHOULD BE 1 BUT CURRENTLY 0 ???
       MOV   AX, BUFFER_PTR	   ;
       MOV   Taddress_seg, AX	   ;BUFFER ADDRESS
       MOV   Taddress_off, 0	   ;
       XOR   BX, BX		   ;
       MOV   BL, TARGET_DRIVE	   ;
       MOV   CL, WRITE_FUNC	   ;= 41h
       MOV   DX, OFFSET IOCTL_R_W  ;
       CALL  GENERIC_IOCTL	   ;

       CMP   IO_ERROR, NO_ERROR    ;OK?
;  $LEAVE E			   ;YES, SUCCESS. EXIT THIS ROUTINE
   JE $$EN73

       CMP   IO_ERROR, SOFT_ERROR  ;TRY AGAIN?
       JE    WO_AGAIN		   ;
				   ;ELSE HARD ERROR
				   ;WRITE FAILURE, LET'S TRY TO FORMAT.
       CMP   FORMAT_FLAG, ON	   ;WAS THIS TRACK FORMATTED BEFORE?
;  $EXITIF E			   ;YES, GIVE UP WRITING AND
   JNE $$IF73
				   ; CHECK WHEN IT HAPPENDED.
				   ;GIVE UP WRITING AND SHOW ERROR MESSAGE.
       INC   COPY_ERROR 	   ;INDICATE ERROR OCCURS DURING COPY.
       MOV   AH, WRITE_FUNC	   ;
       mov   dl, target_drive	   ;
       CALL  ERROR_MESSAGE	   ;SHOW MESSAGE 'WRITE ERROR SIDE, TRACK...'

       MOV   MSG_FLAG, OFF	   ;
;  $ORELSE			   ;ELSE TRY FORMAT AND TRY WRITE AGAIN
   JMP SHORT $$SR73
$$IF73:

				   ;CR,LF,"Formatting while copying",CR,LF
       PRINT MSGNUM_FORMATTING	   ;AN000;SHOW MESSAGE

       MOV   FORMAT_FLAG, ON	   ;FORMAT ALL TRACKS FROM THIS TRACK
       CALL  FORMAT_ALL 	   ;format all the rest of the tracks

       CMP   COPY_STATUS, FATAL    ;
;  $ENDLOOP E			   ;
   JNE $$DO73
$$EN73:
.XLIST				   ;
;this next is dead code, nobody calls WO_FATAL, so the move copy_status
;and the print not compatible msg should be removed, and just the JMP WO_EXIT
;will no longer be needed to skip stuff that is not there.  Kiser
;   JMP   WO_EXIT		    ;AND EXIT THIS ROUTINE
;WO_FATAL:
;   MOV   COPY_STATUS, FATAL	    ;WE ARE GOING TO ABORT PROGRAM
;   PRINT MSG_NOT_COMPATIBLE	    ;SHOW NOT COMPATIABLE MESSAGE
.LIST				   ;
;  $ENDSRCH			   ;
$$SR73:
WO_EXIT:			   ;
   RET				   ;

WRITE_OP ENDP			   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <FORMAT_ALL - FORMATS ALL TRACKS TO END> ;AN000;
;*****************************************************************************
;									     *
   PUBLIC FORMAT_ALL		   ;AN000;MAKE ENTRY IN LINK MAP
FORMAT_ALL PROC NEAR		   ;
;									     *
;Format all tracks starting from TRACK_TO_WRITE to the end.		     *
;This routine will set MT_deviceBPB to that of MS_deviceBPB.		     *
;trackLayout had been all set correctly.				     *
;If error, then fail to diskcopy.					     *
;*****************************************************************************

   MOV	 CX, MS_deviceBPB_leng	   ;set length of BPB
   MOV	 SI, OFFSET MS_deviceBPB   ;
   MOV	 DI, OFFSET MT_deviceBPB   ;
   REP	 MOVSB			   ;
   CALL  CHK_MEDIATYPE		   ;set MT_mediaTYPE for FORMAT operation

   MOV	 MT_specialFunctions, SET_SP_BF_FORM ;=00000101B
   MOV	 CL, SETDEVPARM 	   ;=40h
   MOV	 DX, OFFSET MT_IOCTL_DRV_PARM ;
   XOR	 BX, BX 		   ;
   mov	 bl, last_track 	   ;patch 3/27/86 for 3.2 diskcopy. J.K.
   inc	 bl			   ;
   mov	 MT_numberOfCylinders, bx  ;make sure target # of cyl.
   MOV	 BL, TARGET_DRIVE	   ;
   CALL  GENERIC_IOCTL		   ;

   JC	 FA_FATAL		   ;

   MOV	 FspecialFunctions, STATUS_CHK ;check to see if the parameters set
				   ;by "SET DEVICE PARM" func above are
				   ; supported or not.
   MOV	 AX,(IOCTL_FUNC SHL 8)+GENERIC_IOCTL_CODE ;AC000;(440DH)
   MOV	 CH, MAJOR_CODE 	   ;=8
   MOV	 CL, FORMAT_FUNC	   ;=42H
   XOR	 BX, BX 		   ;
   MOV	 BL, TARGET_DRIVE	   ;
   MOV	 DX, OFFSET IOCTL_FORMAT   ;result is in Fspecialfunction
   INT	 21H			   ;0 - Thre is ROM support of AH=18h, INT 13h, and
				   ; it is a valid combination

   MOV	 AL, FspecialFunctions	   ;1 - No ROM support. 2 - There is ROM support,
				   ; but invalid combination
   MOV	 FspecialFunctions, FORMAT_SP_FUNC ;restore specialfunction value
   CMP	 AL, 2			   ;ROM support, but this combination is not valid?
   JE	 FA_FATAL		   ;

   MOV	 AL, TRACK_TO_WRITE	   ;
   MOV	 TRACK_TO_FORMAT, AL	   ;
   MOV	 AL, SIDE		   ;
   MOV	 SIDE_TO_FORMAT, AL	   ;
   CMP	 AL, NO_OF_SIDES	   ;
   JE	 FA_SIDE_WHILE		   ;STARTS WITH THE OTHER SIDE TO FORMAT

FA_TRACK_WHILE: 		   ;
   MOV	 AL, LAST_TRACK 	   ;
   CMP	 TRACK_TO_FORMAT, AL	   ;
   JA	 FA_DONE		   ;

FA_SIDE_WHILE:			   ;
   MOV	 AL, NO_OF_SIDES	   ;
   CMP	 SIDE_TO_FORMAT, AL	   ;
   JA	 FA_NEXT_TRACK		   ;

   CALL  FORMAT_TRACK		   ;FORMAT THIS TRACK

   CMP	 IO_ERROR, HARD_ERROR	   ;
   JNE	 FA_NEXT_SIDE		   ;

   CMP	 SIDE_TO_FORMAT, 1	   ;HARD ERROR AT SIDE 1?
   JNE	 FA_TARGET_BAD		   ;THEN ASSUME TARGET DISKETTE BAD

   CMP	 TRACK_TO_FORMAT, 0	   ;AT CYLINDER 0?
   JNE	 FA_TARGET_BAD		   ;

   JMP	 FA_FATAL		   ;THEN, SOURCE IS TWO SIDED AND
				   ; TARGET IS SINGLE SIDE DISKETTE

FA_NEXT_SIDE:			   ;
   INC	 SIDE_TO_FORMAT 	   ;
   JMP	 FA_SIDE_WHILE		   ;

FA_NEXT_TRACK:			   ;
   MOV	 SIDE_TO_FORMAT, 0	   ;RESET SIDE_TO_FORMAT
   INC	 TRACK_TO_FORMAT	   ;
   JMP	 FA_TRACK_WHILE 	   ;

FA_FATAL:			   ;
   MOV	 COPY_STATUS, FATAL	   ;WE ARE GOING TO ABORT PROGRAM
				   ;"Drive types or diskette types"
				   ;"not compatible"
   PRINT MSGNUM_NOT_COMPATIBLE	   ;AC000;SHOW NOT COMPATIBLE MESSAGE

   JMP	 SHORT FA_DONE		   ;

FA_TARGET_BAD:			   ;
   MOV	 COPY_STATUS, FATAL	   ;WE ARE GOING TO ABORT PROGRAM
				   ;CR,LF,"TARGET diskette bad or incompatible"
   PRINT MSGNUM_BAD_TARGET	   ;AC000;SHOW TARGET BAD MESSAGE

FA_DONE:			   ;
   XOR	 BX, BX 		   ;
   MOV	 BL, TARGET_DRIVE	   ;
   MOV	 T_DRV_SET_FLAG, 1	   ;INDICATE TARGET DRIVE PARM HAS BEEN SET
   MOV	 DX, OFFSET MT_IOCTL_DRV_PARM ;
   MOV	 MT_specialFunctions, SET_SP_FUNC_DEF ;
   CALL  SET_DRV_PARM_DEF	   ;SET IT BACK FOR WRITING.

   RET				   ;
FORMAT_ALL ENDP 		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <FORMAT_TRACK - IOCTL FORMAT A TRACK> ;AN000;
;******************************************************************************
; SUBROUTINE NAME :  FORMAT_TRACK     -  IOCTL FORMAT A TRACK		      *
;					 (BOTH SIDES IF 2-SIDED DSKT)	      *
;									      *
; INPUT 	  :   TRACK_TO_FORMAT					      *
;		  :   SIDE	       BYTE  0, 1  (HEAD NUMBER)	      *
;		  :   END_OF_TRACK     BYTE  8, 9, 15			      *
;		  :   TARGET_DRIVE     BYTE  1 = A, 2 = B, ETC		      *
;									      *
; OUTPUT	  :   none. This routine does not report format error.	      *
;		      Write routine will detect the error consequently.       *
; REGISTER(S) AFFECTED: 						      *
;******************************************************************************
   PUBLIC FORMAT_TRACK		   ;AN000;MAKE ENTRY IN LINK MAP
FORMAT_TRACK PROC NEAR		   ;

FT_AGAIN:			   ;
;  $DO				   ;
$$DO79:
       XOR   AX, AX		   ;
       MOV   AL, SIDE_TO_FORMAT    ;
       MOV   FHead, AX		   ;HEAD TO FORMAT
       MOV   AL, TRACK_TO_FORMAT   ;
       MOV   FCylinder, AX	   ;TRACK TO FORMAT

       XOR   BX, BX		   ;
       MOV   BL, TARGET_DRIVE	   ;DRIVE TO FORMAT
       MOV   CL, FORMAT_FUNC	   ;=42h
       MOV   DX, OFFSET IOCTL_FORMAT ;
       CALL  GENERIC_IOCTL	   ;

       CMP   IO_ERROR, SOFT_ERROR  ;TRY FORMAT AGAIN?
				   ; (DRIVE NOT READY OR WRITE PROTECTED)
;  $ENDDO NE			   ;
   JE $$DO79

   RET				   ;
FORMAT_TRACK ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <CHECK_SOURCE - CHECK SOURCE DISKETTE TYPE> ;AN000;
;*****************************************************************************
;									     *
   PUBLIC CHECK_SOURCE		   ;AN000;MAKE ENTRY IN LINK MAP
CHECK_SOURCE PROC NEAR		   ;CHECK SOURCE DISKETTE TYPE		     *
;				   SET END_OF_TRACK, LAST_TRACK 	     *
;				   NO_OF_SIDES, bSECTOR_SIZE		     *
; ** this routine will call "Get dev parm" with "BUILD BPB BIT" on.  If it   *
; ** fails to get that info, then the source medium must be bad(vergin) or   *
; ** below DOS 2.0 level diskette, and will jmp to the old logic.	     *
; ** For compatibility reasons (in case of non IBM formatted media), this    *
; ** routine covers old diskcopy routines.  But this will only supports
; ** 5.25" 48 tpi 8, 9 sectors, 40 tracks and 5.25" 96 tpi, 15 sectors, 80 tracks
; ** media.  Other non IBM formatted media which are formatted differenty
; ** from those values will result in unpreditable copy process.
;*****************************************************************************

;  $DO				   ;
$$DO81:
       XOR   BX, BX		   ;
       MOV   BL, SOURCE_DRIVE	   ;
       MOV   MS_specialFunctions, GET_SP_FUNC_MED ;=00000001b
       MOV   CL, GETDEVPARM	   ;=60h
       MOV   DX, OFFSET MS_IOCTL_DRV_PARM ;
       CALL  GENERIC_IOCTL	   ;TRY TO GET MEDIA BPB INFO TOGETHER
				   ;WITH DEFAULT DEVICE INFO.
       CMP   IO_ERROR, SOFT_ERROR  ;TRY AGAIN?
;  $ENDDO NE			   ;
   JE $$DO81

   CMP	 IO_ERROR, HARD_ERROR	   ;CANNOT GET MEDIA BPB?
   JE	 CS_OLD 		   ;ASSUME OLD FORMATTED DISKETTE, FIRST.

   cmp	 ms_deviceBPB.csect_track,0 ;patch 1/16/86
   je	 cs_old 		   ;

   cmp	 ms_deviceBPB.chead,0	   ;cannot trust the info from dos
   je	 cs_old 		   ;sanity check for divide by 0

   MOV	 AX, MS_deviceBPB.CTOTSECT ;
   CWD				   ;CONVERT IT TO A DOUBLE WORD
   DIV	 MS_deviceBPB.CSECT_TRACK  ;
   DIV	 MS_deviceBPB.CHEAD	   ;(TOTAL SECTORS / # OF TRACKS) / # OF HEADS
   CMP	 AL, T_DRV_TRACKS	   ;SOURCE MEDIA # OF TRACK > TARGET
				   ; DEVICE # OF TRACKS?
   JA	 CS_FATAL		   ;THEN, NOT COMPATIBLE.

   DEC	 AX			   ;DECREASE BY 1 FOR THE USE OF THIS PROGRAM.
   MOV	 LAST_TRACK, AL 	   ;SET LAST_TRACK
   MOV	 AX, MS_deviceBPB.CSECT_TRACK ;
   CMP	 AL, T_DRV_SECT_TRACK	   ;SOURCE MEDIA # OF SECT/TRACK > TARGET
				   ; DEVICE # OF SECT/TRACK?
   JA	 CS_FATAL		   ;THEN, NOT COMPATIBLE

   MOV	 END_OF_TRACK, AL	   ;
   MOV	 AX, MS_deviceBPB.CBYTE_SECT ;
   MOV	 bSECTOR_SIZE, AX	   ;set the sector size in bytes.
   CMP	 USER_OPTION, 1 	   ;
   JE	 CS_OPTION_1		   ;

   MOV	 AX, MS_deviceBPB.CHEAD    ;HEAD=1, 2
   CMP	 AL, T_DRV_HEADS	   ;COMPARE SOURCE MEDIA SIDE WITH
				   ; TARGET DRIVE HEAD NUMBER
   JA	 CS_FATAL		   ;SOURCE MEDIUM IS DOUBLE SIDED AND
				   ; TARGET DRIVE IS SINGLE SIDED.

   DEC	 AX			   ;
   MOV	 NO_OF_SIDES, AL	   ;NO_OF_SIDES=0, 1
   JMP	 CS_SET_TABLE		   ;
;  =  =  =  =  =  =  =	=  =  =  =
CS_FATAL:			   ;
   MOV	 COPY_STATUS, FATAL	   ;
				   ;CR,LF,"Drive types or diskette types",CR,LF
				   ;"not compatible",CR,LF
   PRINT MSGNUM_NOT_COMPATIBLE	   ;AC000;
   JMP	 CS_EXIT		   ;

;  =  =  =  =  =  =  =	=  =  =  =
CS_BAD: 			   ;
   MOV	 COPY_STATUS, FATAL	   ;
   PRINT MSGNUM_BAD_SOURCE	   ;CR,LF,"SOURCE diskette bad or incompatible"

   JMP	 CS_EXIT		   ;

;  =  =  =  =  =  =  =	=  =  =  =
CS_OLD: 			   ;
   MOV	 READ_S_BPB_FAILURE, 1	   ;SET FLAG
   MOV	 bSECTOR_SIZE, 512	   ;OLD SECTOR SIZE MUST BE 512 BYTES
   XOR	 BX, BX 		   ;
   MOV	 BL, SOURCE_DRIVE	   ;
   MOV	 IOCTL_TRACK, 0 	   ;TRACK=0
   MOV	 IOCTL_SECTOR, 8	   ;SECTOR=8
   MOV	 IOCTL_HEAD, 0		   ;HEAD = 0
   CALL  READ_A_SECTOR		   ;

   JC	 CS_BAD 		   ;SOURCE BAD

   MOV	 IOCTL_SECTOR, 9	   ;TRY TO READ SECTOR=9
   CALL  READ_A_SECTOR		   ;

   JC	 CS_SECT8		   ;YES, 8 SECTORS. ASSUME 40 TRACKS

   MOV	 IOCTL_SECTOR, 15	   ;try to read sector=15
   CALL  READ_A_SECTOR		   ;

   JC	 CS_SECT9		   ;**REMEMBER THIS ROUTINE DOES NOT COVER 3.5" MEDIA

   JMP	 SHORT CS_SECT15	   ;

;  =  =  =  =  =  =  =	=  =  =  =
CS_OPTION_1:			   ;
   MOV	 NO_OF_SIDES, 0 	   ;1 SIDE COPY
   JMP	 SHORT CS_SET_TABLE	   ;

;  =  =  =  =  =  =  =	=  =  =  =
CS_SECT15:			   ;
   MOV	 END_OF_TRACK, 15	   ;ELSE END_OF_TRACK = 15
   MOV	 LAST_TRACK, 79 	   ;
   JMP	 SHORT CS_CHK_SIDE	   ;

;  =  =  =  =  =  =  =	=  =  =  =
CS_SECT8:			   ;
   MOV	 END_OF_TRACK, 8	   ;SOURCE 8 SECTORS
   MOV	 LAST_TRACK,  39	   ;ASSUME 40 TRACKS.
   JMP	 SHORT CS_CHK_SIDE	   ;

;  =  =  =  =  =  =  =	=  =  =  =
CS_SECT9:			   ;
   MOV	 END_OF_TRACK, 9	   ;
   MOV	 LAST_TRACK, 39 	   ;ASSUME 5.25 DISKETTE
   JMP	 SHORT CS_CHK_SIDE	   ;

;  =  =  =  =  =  =  =	=  =  =  =
CS_CHK_SIDE:			   ;
   CMP	 USER_OPTION, 1 	   ;
   JE	 CS_OPTION_1		   ;

   MOV	 IOCTL_HEAD, 1		   ;HEAD 1
   XOR	 AX, AX 		   ;
   MOV	 AL, END_OF_TRACK	   ;READ MATCHING END_OF_TRACK
				   ; OF THE OTHER SURFACE.
   MOV	 IOCTL_SECTOR, AX	   ;
   CALL  READ_A_SECTOR		   ;

   JC	 CS_OPTION_1		   ;1 SIDED SOURCE

   MOV	 NO_OF_SIDES, 1 	   ;2 SIDED SOURCE
   CMP	 T_DRV_HEADS, 2 	   ;SOUCE=2 SIDED MEDIUM. IS TARGET
				   ; DOUBLE SIDED DRV?
   JE	 CS_SET_TABLE		   ;

   JMP	 CS_FATAL		   ;NOT COMPATIBLE

;  =  =  =  =  =  =  =	=  =  =  =
CS_SET_TABLE:			   ;
   CMP	 READ_S_BPB_FAILURE, 1	   ;DISKETTE WITHOUT BPB INFO?
;  $IF	 E			   ;
   JNE $$IF83
       CALL  SET_FOR_THE_OLD	   ;

;  $ENDIF			   ;
$$IF83:
   MOV	 BX, OFFSET MS_trackLayout ;SET TRACKLAYOUT OF SOURCE
   CALL  SET_TRACKLAYOUT	   ;

   MOV	 BX, OFFSET MT_trackLayout ;YES, ASSUME TARGET IS SAME
   CALL  SET_TRACKLAYOUT	   ;

   MOV	 S_DRV_SET_FLAG, 1	   ;
   XOR	 BX, BX 		   ;
   MOV	 BL, SOURCE_DRIVE	   ;
   MOV	 MS_specialFunctions, SET_SP_FUNC_DEF ;=00000100B
   MOV	 DX, OFFSET MS_IOCTL_DRV_PARM ;
   CALL  SET_DRV_PARM_DEF	   ;NOW, SET SOURCE DRIVE PARM
				   ; FOR READ OPERATION.

   XOR	 AX, AX 		   ;
   MOV	 AL, END_OF_TRACK	   ;
   MOV	 numberOfSectors, AX	   ;SET NUMBEROFSECTORS IN IOCTL_R_W TABLE

   MOV	 AL, LAST_TRACK 	   ;NOW, SHOW THE MESSAGE "COPYING ..."
   INC	 AL			   ;
.XLIST				   ;
;  MOV	 BYTE PTR MSG_COPYING_PTR+2, AL ;HOW MANY TRACKS?
.LIST				   ;
   MOV	 BYTE PTR MSG_TRACKS, AL   ;AC000;HOW MANY TRACKS?

   MOV	 AL, END_OF_TRACK	   ;
.XLIST				   ;
;  MOV	 BYTE PTR MSG_COPYING_PTR+4, AL ;HOW MANY SECTORS?
.LIST				   ;
   MOV	 BYTE PTR MSG_SECTRK,AL    ;AC000;HOW MANY SECTORS?

   MOV	 AL, NO_OF_SIDES	   ;TELL USER HOW MANY SIDE TO COPY
   INC	 AL			   ;
.XLIST				   ;
;  MOV	 BYTE PTR MSG_COPYING_PTR+6, AL
.LIST				   ;
   MOV	 BYTE PTR MSG_SIDES,AL	   ;AC000;HOW MANY SIDES?
				   ;CR,LF,"Copying %1 tracks",CR,LF
				   ;"%2 Sectors/Track, %3 Side(s)",CR,LF
   PRINT MSGNUM_COPYING 	   ;AC000;

CS_EXIT:			   ;
   RET				   ;

CHECK_SOURCE ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <READ_A_SECTOR - GET ONE SECTOR WITH IOCTL READ> ;AN000;
;******************************************************************************
   PUBLIC READ_A_SECTOR 	   ;AN000;MAKE ENTRY IN LINK MAP
READ_A_SECTOR PROC NEAR 	   ;
;									      *
;TRY TO READ A SECTOR USING IOCTL READ FUNCTION CALL.			      *
;THIS ROUTINE WILL STEAL "IOCTL_R_W" TABLE TEMPORARILY. 		      *
;INPUT: BX - LOGICAL DRIVE NUMBER					      *
;	IOCTL_SECTOR - SECTOR TO READ					      *
;	IOCTL_TRACK - TRACK						      *
;	IOCTL_HEAD - HEAD TO READ					      *
;	bSECTOR_SIZE - SECTOR SIZE IN BYTES				      *
;OUTPUT:								      *
;	IF NOT A SUCCESS, CARRY WILL BE SET				      *
;	ALL REGISTORS SAVED						      *
;
;******************************************************************************

   PUSH  AX			   ;
   PUSH  BX			   ;
   PUSH  CX			   ;
   PUSH  DX			   ;

   MOV	 AX, numberOfSectors	   ;SAVE IOCTL_R_W TABLE VALUES
   MOV	 SAV_CSECT, AX		   ;

;RAS_AGAIN:
;  $DO				   ;
$$DO85:
       MOV   AX, IOCTL_HEAD	   ;
       MOV   Head, AX		   ;SURFACE TO READ
       MOV   AX, IOCTL_TRACK	   ;
       MOV   Cylinder, AX	   ;TRACK TO READ
       MOV   AX, IOCTL_SECTOR	   ;
       dec   ax 		   ;????? currently
				   ; firstsector=0 => 1st sector ????
       MOV   FirstSectors, AX	   ;SECTOR TO READ
       MOV   numberOfSectors, 1    ;read just one sector
       MOV   AX, offset INIT	   ;READ IT INTO INIT
				   ; (CURRELTLY, MAX 1K)
       MOV   TAddress_off, AX	   ;
       MOV   TAddress_seg, DS	   ;
       MOV   CL, READ_FUNC	   ;
       MOV   DX, OFFSET IOCTL_R_W  ;POINTS TO CONTROL TABLE
       call  generic_ioctl	   ;

       CMP   IO_ERROR, SOFT_ERROR  ;TRY ONCE MORE?
;  $ENDDO NE			   ;
   JE $$DO85

   CMP	 IO_ERROR, HARD_ERROR	   ;HARD ERROR?
;  $IF	 NE			   ;
   JE $$IF87

       CLC			   ;READ SUCCESS
;  $ELSE			   ;
   JMP SHORT $$EN87
$$IF87:
       STC			   ;SET CARRY
;  $ENDIF			   ;
$$EN87:
   MOV	 AX, SAV_CSECT		   ;RESTORE ORIGINAL IOCTL_R_W TABLE
   MOV	 numberOfSectors, AX	   ;
   POP	 DX			   ;
   POP	 CX			   ;
   POP	 BX			   ;
   POP	 AX			   ;
   RET				   ;

READ_A_SECTOR ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <CALC_TRACK_SIZE - GET MEM SIZE TO STORE ONE TRACK> ;AN000;
;*****************************************************************************
   PUBLIC CALC_TRACK_SIZE	   ;AN000;MAKE ENTRY IN LINK MAP
CALC_TRACK_SIZE PROC NEAR	   ;CALCULATE MEMORY SIZE REQUIRED TO STORE ONE
;			      TRACK (IN SEGMENTS)			     *
;
;CALCULATE SECTOR_SIZE IN PARA FROM bSECTOR_SIZE.  IF bSECTOR_SIZE CANNOT BE *
;CHANGED TO SECTOR_SIZE IN PARA EXACTLY, THEN ADD 1 TO THE SECTOR_SIZE.      *
;SECTOR_SIZE IS USED FOR MEMORY MANAGEMANT ONLY.  THE ACTUAL COPY OR FORMAT  *
;SHOULD BE DEPENDS ON bSECTOR_SIZE TO FIGURE OUT HOW BIG A SECTOR IS.	     *
;ALSO, CURRENTLY, THIS ROUTINE ASSUME A BSECTOR SIZE BE LESS THAN 0FFFh.     *
;*****************************************************************************

   PUSH  AX			   ;
   PUSH  BX			   ;
   PUSH  CX			   ;

   MOV	 AX, bSECTOR_SIZE	   ;
   MOV	 CL, 16 		   ;
   DIV	 CL			   ;AX / 16 = AL ... AH
   CMP	 AH, 0			   ;NO REMAINER?
;  $IF	 NE			   ;
   JE $$IF90

       INC   AL 		   ;THERE REMAINER IS.	INC AL

;  $ENDIF			   ;
$$IF90:
   MOV	 SECTOR_SIZE, AL	   ;SECTOR_SIZE+ IN PARA.
   MOV	 AL,NO_OF_SIDES 	   ;TRACK_SIZE = (NO OF SIDES
   INC	 AL			   ;		  + 1)
   MUL	 END_OF_TRACK		   ;		  * END_OF_TRACK
   MOV	 BL,SECTOR_SIZE 	   ;		  * SECTPR_SIZE
   MUL	 BL			   ;AMOUNT OF MEMORY REQUIRED (IN SEG)
   MOV	 TRACK_SIZE,AX		   ;TO STORE A TRACK
   POP	 CX			   ;
   POP	 BX			   ;
   POP	 AX			   ;

   RET				   ;
CALC_TRACK_SIZE ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <CHECK_MEMORY_SIZE - VERIFY WE HAVE ENUF TO COPY 1 TRACK> ;AN000;
;*****************************************************************************
   PUBLIC CHECK_MEMORY_SIZE	   ;AN000;MAKE ENTRY IN LINK MAP
CHECK_MEMORY_SIZE PROC NEAR	   ;MAKE SURE WE HAVE ENOUGH TO COPY 1 TRACK INTO
;			      TO BUFFER ELSE ABORT COPY 		     *
;*****************************************************************************
   MOV	 AX,BUFFER_END		   ;CALCULATE AVAILABLE MEMORY
   SUB	 AX,BUFFER_BEGIN	   ;IN SEGMENTS
   CMP	 AX,TRACK_SIZE		   ;DO WE HAVE ENOUGH TO STORE A CYLINDER?
;  $IF	 B			   ;
   JNB $$IF92
       MOV   COPY_STATUS,FATAL	   ;NO, ABORT COPY
       PRINT MSGNUM_UNSUF_MEMORY   ;AC000;AND TELL USER WHY

;  $ENDIF			   ;
$$IF92:
   RET				   ;

CHECK_MEMORY_SIZE ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <SET_FOR_THE_OLD  - SET BPB FOR BEFORE-2.0 FMTTED MEDIA> ;AN000;
;*****************************************************************************
   PUBLIC SET_FOR_THE_OLD	   ;AN000;MAKE ENTRY IN LINK MAP
SET_FOR_THE_OLD PROC NEAR	   ;

;set MS_deviceBPB for before-2.0 formatted media
;*****************************************************************************
   PUSH  AX			   ;

   CMP	 END_OF_TRACK,9 	   ;IF SECTORS/TRACK <= 9, THEN CHECK
				   ;NO_OF_SIDES. IF SINGLE SIDE
				   ; COPY THEN USE BPB48_SINGLE
				   ;ELSE USE BPB48_DOUBLE.
;  $IF	 A			   ;SECTORS/TRACK > 9 THEN USE BPB96 TABLE
   JNA $$IF94
       MOV   SI, OFFSET BPB96	   ;
;  $ELSE			   ;
   JMP SHORT $$EN94
$$IF94:
       CMP   NO_OF_SIDES, 0	   ;SINGLE SIDE COPY?
;      $IF   NE 		   ;IF NOT,
       JE $$IF96
	   MOV	 SI, OFFSET BPB48_DOUBLE ;USE BPB48 DOUBLE
;      $ELSE			   ;
       JMP SHORT $$EN96
$$IF96:
	   MOV	 SI, OFFSET BPB48_SINGLE ;
;      $ENDIF			   ;
$$EN96:
;  $ENDIF			   ;
$$EN94:
   XOR	 AX, AX 		   ;
   MOV	 AL, END_OF_TRACK	   ;

   MOV	 MS_deviceBPB.CSECT_TRACK,AX ;SET # OF SECTORS IN IOCTL_DRV_PARM
   MOV	 DI, OFFSET MS_deviceBPB   ;
   MOV	 CX, BPB96_LENG 	   ;
   REP	 MOVSB			   ;OLD DEFAULT BPB INFO => MS_deviceBPB

   POP	 AX			   ;
   RET				   ;
SET_FOR_THE_OLD ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <SET_TRACKLAYOUT - MOVE DATA TO TRACK IMAGE> ;AN000;
;*****************************************************************************
   PUBLIC SET_TRACKLAYOUT	   ;AN000;MAKE ENTRY IN LINK MAP
SET_TRACKLAYOUT PROC NEAR	   ;

;INPUT: BX - POINTER TO DESTINATION
;*****************************************************************************

   XOR	 CX, CX 		   ;
   MOV	 CL, END_OF_TRACK	   ;
   MOV	 WORD PTR [BX], CX	   ;SET CSECT_F TO THE NUMBER OF
				   ; SECTORS IN A TRACK
   ADD	 BX, 2			   ;NOW BX POINTS TO
				   ; THE FIRST SECTORNUMBER
   MOV	 CX, 1			   ;
   MOV	 AX, bSECTOR_SIZE	   ;

;  $DO				   ;
$$DO100:
       CMP   CL, END_OF_TRACK	   ;
;  $LEAVE A			   ;
   JA $$EN100

       MOV   WORD PTR [BX], CX	   ;
       INC   BX 		   ;
       INC   BX 		   ;
       MOV   WORD PTR [BX], AX	   ;
       INC   BX 		   ;
       INC   BX 		   ;

       INC   CX 		   ;
;  $ENDDO			   ;
   JMP SHORT $$DO100
$$EN100:

   RET				   ;
SET_TRACKLAYOUT ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <CHECK_TARGET - READ TARGET BOOT RCD, NEEDS FORMAT?> ;AN000;
;*****************************************************************************
   PUBLIC CHECK_TARGET		   ;AN000;MAKE ENTRY IN LINK MAP
CHECK_TARGET PROC NEAR		   ;					*
;   ** THIS ROUTINE WILL TRY TO READ TARGET MEDIA BOOT RECORD.		     *
;   ** IF A SUCCESS,THEN COMPARES BPB INFO WITH THAT OF SOURCE MEDIA.	     *
;   ** IF THEY ARE DIFFERENT, THEN SET FORMAT_FLAG AND RETURN.		     *
;   ** IF FAILED TO READ A BOOT, THEN TRY OLD LOGICS BEFORE DOS 3.2 FOR      *
;   ** COMPATIBILITY REASON.						     *
;*****************************************************************************

;  $DO				   ;
$$DO103:
       XOR   BX, BX		   ;
       MOV   BL, TARGET_DRIVE	   ;
       MOV   MT_specialFunctions, GET_SP_FUNC_MED ;=00000001b
       MOV   CL, GETDEVPARM	   ;=60h
       MOV   DX, OFFSET MT_IOCTL_DRV_PARM ;
       CALL  GENERIC_IOCTL	   ;TRY TO GET MEDIA BPB INFO TOGETHER
				   ;WITH DEFAULT DEVICE INFO.
       CMP   IO_ERROR, SOFT_ERROR  ;TRY AGAIN?
;  $ENDDO NE			   ;
   JE $$DO103

   CMP	 IO_ERROR, HARD_ERROR	   ;CANNOT GET MEDIA BPB?
   JE	 CT_OLD 		   ;ASSUME OLD FORMATTED DISKETTE, FIRST.

   cmp	 mt_deviceBPB.csect_track,0 ;patch 1/16/86 for 3.2 diskcopy
   je	 ct_old 		   ;

   cmp	 mt_deviceBPB.chead,0	   ;cannot belive the info from dos
   je	 ct_old 		   ;sanity check for divide by 0.

   MOV	 AX, MT_deviceBPB.CTOTSECT ;
   CWD				   ;CONVERT IT TO A DOUBLE WORD
   DIV	 MT_deviceBPB.CSECT_TRACK  ;
   DIV	 MT_deviceBPB.CHEAD	   ;(TOTAL SECTORS / # OF TRACKS) / # OF HEADS
   DEC	 AX			   ;DECREASE BY 1 FOR THIS PROGRAM.
   CMP	 LAST_TRACK, AL 	   ;COMPARE WITH THE LAST TRACK OF SOURCE
   JE	 CT_SECTOR_TRACK	   ;IF SAME, THEN CHECK SECTOR PER TRACK
				   ;SINCE NOT THE SAME, CONTINUE...

   CMP	 MT_deviceBPB.CSECT_TRACK,0FH ;AN012;IS TARGET 15 SEC / TRK?
   JNE	 CT_FORMAT		   ;AN012;NO, SOMETHING ELSE...
				   ;YES, 15 SEC/TRACK, CONTINUE...

   CMP	 LAST_TRACK,27H 	   ;AN012;IS SOURCE ORIGINALLY 40 TRACK?
   JNE	 CT_FORMAT		   ;AN012;NO, SOMETHING ELSE...
				   ;YES, 40 TRACK, CONTINUE...
   JMP	 CT_FATAL		   ;AN012;ABORT THIS, DO NOT MESS UP THE 1.2M
				   ; WITH NOBLE ATTEMPTS TO FORMAT
CT_SECTOR_TRACK:		   ;
   MOV	 AX, MT_deviceBPB.CSECT_TRACK ;
   CMP	 END_OF_TRACK, AL	   ;
   JNE	 CT_FORMAT		   ;

CT_BYTE_SECTOR: 		   ;
   MOV	 AX, MT_deviceBPB.CBYTE_SECT ;
   CMP	 AX, bSECTOR_SIZE	   ;
   JNE	 CT_FORMAT		   ;

CT_HEAD:			   ;
   MOV	 AX, MT_deviceBPB.CHEAD    ;
   DEC	 AX			   ;
   CMP	 AL, NO_OF_SIDES	   ;
   JB	 CT_FORMAT		   ;IF TARGET SIDE < SOURCE SIDE
				   ; THEN FORMAT IT.

   JMP	 CT_SET_DRV		   ;TARGET IS O.K. SET DRIVE PARM
				   ; AND EXIT

CT_FORMAT:			   ;
   PRINT MSGNUM_FORMATTING	   ;AC000;"Formatting while copying"

   MOV	 FORMAT_FLAG, ON	   ;
   CALL  FORMAT_ALL		   ;FORMAT ALL TRACKS STARTING
				   ; FROM TRACK_TO_WRITE
   JMP	 CT_EXIT		   ;

CT_OLD: 			   ;AC011;
   CMP	 UKM_ERR,ON		   ;AN011;IS THIS HARD ERROR "UNKNOWN MEDIA"?
   JE	 CT_FORMAT		   ;AN011; IF SO, GO TRY FORMATTING
				   ;SAME OLD... ;AGAIN, THIS DOES
				   ; NOT RECOGNIZE 3.5 MEDIA
   MOV	 READ_T_BPB_FAILURE, 1	   ;SET THE FLAG
   XOR	 BX, BX 		   ;
   MOV	 BL, TARGET_DRIVE	   ;
   MOV	 IOCTL_TRACK, 0 	   ;
   MOV	 IOCTL_SECTOR, 8	   ;
   MOV	 IOCTL_HEAD, 0		   ;TRY TO READ HEAD 0, TRACK 0, SECTOR 8
   CALL  READ_A_SECTOR		   ;

   JC	 CT_FORMAT		   ;ASSUME TARGET MEDIA NOT FORMATTED.

   MOV	 IOCTL_SECTOR, 9	   ;TRY TO READ SECTOR 9
   CALL  READ_A_SECTOR		   ;

   JC	 CT_8_SECTOR		   ;TARGET IS 8 SECTOR MEDIA

   MOV	 IOCTL_SECTOR, 15	   ;
   CALL  READ_A_SECTOR		   ;

   JC	 CT_9_SECTOR		   ;TARGET IS 9 SECTOR MEDIA

;CT_15_SECTOR:				;TARGET IS 15 SECTOR MEDIA
   CMP	 END_OF_TRACK, 15	   ;IS SOURCE ALSO 96 TPI?
   JNE	 CT_FATAL		   ;NO, FATAL ERROR

   JMP	 CT_EXIT_OLD		   ;OK

CT_8_SECTOR:			   ;
   CMP	 END_OF_TRACK, 15	   ;
   JE	 CT_FATAL		   ;IF SOURCE IS 96 TPI, THEN FATAL ERROR

   CMP	 END_OF_TRACK, 9	   ;
   JE	 CT_FORMAT		   ;IF SOURCE IS 9 SECTOR, THEN
				   ; SHOULD FORMAT TARGET

   JMP	 CT_EXIT_OLD		   ;ELSE ASSUME SOURCE IS 8 SECTOR.

CT_9_SECTOR:			   ;
   CMP	 END_OF_TRACK, 15	   ;IS SOURCE 96 TPI ?
   JNE	 CT_EXIT_OLD		   ;NO. SOUCE IS 8 OR 9
				   ; SECTORED 48 TPI DISKETTE

CT_FATAL:			   ;
   MOV	 COPY_STATUS, FATAL	   ;
				   ;"Drive types or diskette types"
   PRINT MSGNUM_NOT_COMPATIBLE	   ;AC000;"not compatible"

   JMP	 SHORT	 CT_EXIT	   ;

CT_EXIT_OLD:			   ;
   MOV	 CX, MS_deviceBPB_leng	   ;
   MOV	 SI, OFFSET MS_deviceBPB   ;
   MOV	 DI, OFFSET MT_deviceBPB   ;
   REP	 MOVSB			   ;set MT_deviceBPB to MS_deviceBPB
CT_SET_DRV:			   ;
   MOV	 T_DRV_SET_FLAG, 1	   ;INDICATE THE TARGET DEFAULT
				   ; DEVICE PARM HAS BEEN SET.
   XOR	 BX, BX 		   ;
   mov	 bl, last_track 	   ;patch for 3.2 diskcopy, 3/27/86 J.K.
   inc	 bl			   ;
   mov	 MT_numberOfCylinders, bx  ;make sure the # of cyl of the target
   MOV	 BL, TARGET_DRIVE	   ;
   MOV	 DX, OFFSET MT_IOCTL_DRV_PARM ;
   MOV	 MT_specialFunctions, SET_SP_FUNC_DEF ;
   CALL  SET_DRV_PARM_DEF	   ;

CT_EXIT:			   ;
   RET				   ;

CHECK_TARGET ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <CHK_MULTI_MEDIA - CHECK IF DRIVE IS MULTI-MEDIA> ;AN000;
;*****************************************************************************
   PUBLIC CHK_MULTI_MEDIA	   ;AN000;MAKE ENTRY IN LINK MAP
CHK_MULTI_MEDIA PROC NEAR	   ;
;IF THE SOURCE IS 96 TPI DISKETTE, AND TARGET IS 48 TPI
;DISKETTE, OR VICE VERSA, THEN SET THE CARRY BIT.
;THIS ROUTINE BE CALLED WHEN BPB INFORMATIONS OF TARGET HAS BEEN SUCCESSFULLY
;READ.
;*** CURRENTLY, ONLY 96 TPI DRIVE IN PC_AT CAN HAVE MULTI_MEDIA.
;INPUT: AX - TARGET MEDIA CYLINDER NUMBER - 1
;	LAST_TRACK - SOURCE MEDIA CYLINDER NUMBER - 1
;*****************************************************************************
   CLC				   ;CLEAR CARRY
   CMP	 LAST_TRACK, 39 	   ;SOURCE IS 48 TPI MEDIA?
;  $IF	 E,AND			   ;
   JNE $$IF105
   CMP	 AL, 79 		   ;AND TARGET IS 96 TPI MEDIA?
;  $IF	 E			   ;
   JNE $$IF105
       STC			   ;THEN SET CARRY
;  $ELSE			   ;
   JMP SHORT $$EN105
$$IF105:
       CMP   LAST_TRACK, 79	   ;SOURCE IS 96 TPI MEDIA?
;      $IF   E,AND		   ;
       JNE $$IF107
       CMP   AL, 39		   ;AND TARGET IS 48 TPI?
;      $IF   E			   ;
       JNE $$IF107
	   STC			   ;
;      $ENDIF			   ;
$$IF107:
;  $ENDIF			   ;
$$EN105:
   RET				   ;
CHK_MULTI_MEDIA ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <SET_DRV_PARM_DEF - SET DRIVE PARMS VIA IOCTL> ;AN000;
;*****************************************************************************
   PUBLIC SET_DRV_PARM_DEF	   ;AN000;MAKE ENTRY IN LINK MAP
SET_DRV_PARM_DEF PROC NEAR	   ;
;SET THE DRV PARMAMETERS
;INPUT: BL - DRIVE NUMBER
;	DX - POINTER TO THE DEFAULT PARAMETER TABLE
;	specialfunc should be set before calling this routine
;*****************************************************************************
   MOV	 CL, SETDEVPARM 	   ;=40H
   CALL  GENERIC_IOCTL		   ;

   RET				   ;
SET_DRV_PARM_DEF ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <CHK_MEDIATYPE - DETERMINE MEDIATYPE OF TARGET FOR FORMAT> ;AN000;
;*****************************************************************************
   PUBLIC CHK_MEDIATYPE 	   ;AN000;MAKE ENTRY IN LINK MAP
CHK_MEDIATYPE PROC NEAR 	   ;
;SET THE mediaType OF IOCTL_DRV_PARM FOR TARGET DRIVE IN CASE OF FORMAT.
;IF TARGET IS A MULTI-MEDIA DEVICE, mediaType SHOULD BE SET CORRECTLY
;TO FORMAT THE TARGET MEDIA.
;IF EITHER OF LAST_TRACK OR END_OF_TRACK IS LESS THAN THAT OF TARGET
;DRIVE, THEN mediaType WILL BE SET TO 1. OTHERWISE, IT WILL BE 0 FOR
;THE DEFAULT VALUE.
;*****************************************************************************

   MOV	 AL, T_DRV_TRACKS	   ;TARGET DEVICE MAXIUM TRACKS
   DEC	 AL			   ;
   CMP	 LAST_TRACK, AL 	   ;COMPARE SOURCE MEDIA # OF TRACKS TO IT
;  $IF	 B,OR			   ;
   JB $$LL110
   MOV	 AL, T_DRV_SECT_TRACK	   ;
   CMP	 END_OF_TRACK, AL	   ;SOURCE # OF SECT/TRACK < TARGET DEVICE?
;  $IF	 B			   ;
   JNB $$IF110
$$LL110:
       MOV   MT_mediaType, 1	   ;
;  $ENDIF			   ;
$$IF110:
   RET				   ;
CHK_MEDIATYPE ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <GENERIC_IOCTL - COMMUNICATE WITH THE DEVICE DRIVER> ;AN000;
;*****************************************************************************
   PUBLIC GENERIC_IOCTL 	   ;AN000;MAKE ENTRY IN LINK MAP
GENERIC_IOCTL PROC NEAR 	   ;
;INPUT: CL - MINOR CODE; 60 - GET DEVICE PARM, 40 - SET DEVICE PARM
;			 61 - READ TRACK, 41 - WRITE TRACK,
;			 42 - FORMAT AND VERIFY TRACK, 43 - SET MEDIA ID
;			 62 - VERIFY TRACK, 63 - GET MEDIA ID
;	BL - LOGICAL DRIVE LETTER
;	DS:DX - POINTER TO PARAMETERS
;*****************************************************************************
   MOV	 IO_ERROR, NO_ERROR	   ;reset io_error
   MOV	 CH, MAJOR_CODE 	   ;MAJOR CODE, REMOVABLE = 08H
   DOSCALL IOCTL_FUNC,GENERIC_IOCTL_CODE ;AC000;(440DH) CALL THE DEVICE DRIVER

;  $IF	 C			   ;
   JNC $$IF112
       CALL  EXTENDED_ERROR_HANDLER ;ERROR, SEE WHAT IT IS!

;  $ENDIF			   ;
$$IF112:
   RET				   ;
GENERIC_IOCTL ENDP		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <EXTENDED_ERROR_HANDLER - RESPOND TO DOS ERRORS> ;AN000;
;*****************************************************************************
   PUBLIC EXTENDED_ERROR_HANDLER   ;AN000;MAKE ENTRY IN LINK MAP
EXTENDED_ERROR_HANDLER PROC NEAR   ;
;INPUT: BL - LOGICAL DRIVE LETTER
;*****************************************************************************

   PUSHF			   ;
   PUSH  AX			   ;
   PUSH  BX			   ;
   PUSH  CX			   ;
   PUSH  DX			   ;
   PUSH  SI			   ;
   PUSH  DI			   ;
   PUSH  ES			   ;
   PUSH  DS			   ;
   PUSH  BX			   ;

   MOV	 AH, EXTENDED_ERROR	   ;59H
   MOV	 BX, 0			   ;
   INT	 21H			   ;

   POP	 BX			   ;RESTORE BL FOR DRIVE LETTER
   POP	 DS			   ;
   POP	 ES			   ;

   CMP	 AX, 21 		   ;DRIVE NOT READY? (TIME_OUT ERROR?)
   JE	 EEH_CHK_TIMEOUT	   ;

   CMP	 AX, 19 		   ;ATTEMP TO WRITE ON WRITE_PROTECTED?
   JE	 WARN_USER_2		   ;

   JMP	 EEH_HARD_ERROR 	   ;OTHERWISE, HARD_ERROR

EEH_CHK_TIMEOUT:		   ;BECAUSE OF THE INACCURACY
				   ; OF TIME OUT ERROR,
				   ;IN READING AND WRITING OPERATION,
				   ; CHECK OUT CAREFULLY WITH "FORMAT"
   CMP	 FORMAT_FLAG, ON	   ;AFTER OR DURING FORMAT OPERATION,
   JE	 WARN_USER_1		   ; TIME OUT ERROR IS
				   ; ASSUMED TO BE CORRECT.

   CMP	 TRY_FORMAT_FLAG, ON	   ;HAPPENED AT "TRY_FORMAT" PROCEDURE?
   JE	 EEH_TIMEOUT		   ;

   CMP	 TARGET_OP, ON		   ;HAPPENED ON TARGET DRIVE?
   JNE	 WARN_USER_1		   ;IF NOT, THEN ASSUME TIME OUT ERROR

   MOV	 TRY_FORMAT_FLAG, ON	   ;
   CALL  TRY_FORMAT		   ;JUST TRY TO FORMAT THE TRACK.

   MOV	 TRY_FORMAT_FLAG, OFF	   ;
   CMP	 TIME_OUT_FLAG, ON	   ;REAL TIME OUT?
   JE	 WARN_USER_1		   ;YES, A SOFT ERROR.

   CMP	 IO_ERROR, SOFT_ERROR	   ;IT HAPPENED AT TRY_FORMAT PROC AND
				   ; PC_AT WHEN THE DRIVE DOOR OPENED ABRUPTLY.
   JE	 EEH_EXIT		   ;IT WAS WRITE PROTECTED ERROR.

   JMP	 EEH_HARD_ERROR 	   ;NO, "ADDRESS MARK NOT OUT". A HARD ERROR.

EEH_TIMEOUT:			   ;
   MOV	 TIME_OUT_FLAG, ON	   ;SET TIME_OUT_FLAG AND EXIT THIS ROUTINE
   JMP	 EEH_EXIT		   ;

WARN_USER_1:			   ;
   MOV	 DRIVE_LETTER, 'A'	   ;
   DEC	 BL			   ;CHANGE LOGICAL TO PHYSICAL
   ADD	 DRIVE_LETTER, BL	   ;
   PRINT MSGNUM_GET_READY	   ;AC000;"Drive not ready - %0"

   PRINT MSGNUM_CLOSE_DOOR	   ;AN004;"Make sure a diskette is inserted into
				   ;  the drive and the door is closed"
   JMP	 WAIT_FOR_USER		   ;

WARN_USER_2:			   ;
   PRINT MSGNUM_WRITE_PROTECT	   ;AC000;"Attempt to write to write-protected diskette"

WAIT_FOR_USER:			   ;
				   ;"Press any key when ready . . ."
   CALL  PRESS_ANY_KEY		   ;AC000; THEN WAIT FOR ANY RESPONSE

   MOV	 IO_ERROR, SOFT_ERROR	   ;INDICATE THE CALLER TO TRY AGAIN
   JMP	 SHORT EEH_EXIT 	   ;

EEH_HARD_ERROR: 		   ;
   MOV	 IO_ERROR, HARD_ERROR	   ;
   MOV	 UKM_ERR,OFF		   ;AN011;ASSUME NOT "UNKNOWN MEDIA" TYPE ERROR
   CMP	 AX,26			   ;AN011;IS THE ERROR TYPE IS "UNKNOWN MEDIA"?
;  $IF	 E			   ;AN011;IF "UNKNOWN MEDIA" TYPE ERROR
   JNE $$IF114
       MOV   UKM_ERR,ON 	   ;AN011;SET FLAG TO INDICATE "UNKNOWN MEDIA"
				   ; TO CAUSE FORMATTING OF TARGET DISKETTE
;  $ENDIF			   ;AN011;
$$IF114:

EEH_EXIT:			   ;
   POP	 DI			   ;
   POP	 SI			   ;
   POP	 DX			   ;
   POP	 CX			   ;
   POP	 BX			   ;
   POP	 AX			   ;
   POPF 			   ;
   RET				   ;
.XLIST				   ;
;EEH_JUST_EXIT:
;   JMP   EXIT_PROGRAM		    ;UNCONDITIONAL EXIT (IN MAIN PROC)
.LIST				   ;
EXTENDED_ERROR_HANDLER ENDP	   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <TRY_FORMAT - ATTEMPT TRACK FORMAT, TRY FOR ERROR RECOVERY> ;AN000;
;*****************************************************************************
   PUBLIC TRY_FORMAT		   ;AN000;MAKE ENTRY IN LINK MAP
TRY_FORMAT PROC NEAR		   ;
;*** TRY TO FORMAT A TRACK.
;*** CALLED BY "EXTENDED_ERROR_HANDLER" TO CHECK THE TIME OUT ERROR IS A REAL
;*** ONE OR CAUSED BY "ADDR MARK NOT FOUND" ERROR.(THIS IS HARDWARE ERROR THAT
;*** DOES NOT GIVE CORRECT ERROR CODE).
;*** THIS ROUTINE WILL CALL "GENERIC_IOCTL" WHICH IN TURN WILL CALL "EXTENDED_
;*** ERROR_HANDLER" WHERE THE ERROR WILL BE REEXAMINED.
;*****************************************************************************
   PUSH  ES			   ;

   PUSH  DS			   ;
   POP	 ES			   ;

   MOV	 CX, MS_deviceBPB_leng	   ;set length of BPB
   MOV	 SI, OFFSET MS_deviceBPB   ;
   MOV	 DI, OFFSET MT_deviceBPB   ;
   REP	 MOVSB			   ;
   CALL  CHK_MEDIATYPE		   ;set MT_mediaTYPE for FORMAT operation

   MOV	 MT_specialFunctions, SET_SP_BF_FORM ;=00000101B
   MOV	 CL, SETDEVPARM 	   ;=40h
   MOV	 DX, OFFSET MT_IOCTL_DRV_PARM ;
   XOR	 BX, BX 		   ;
   MOV	 BL, TARGET_DRIVE	   ;
   CALL  GENERIC_IOCTL		   ;

   XOR	 AX, AX 		   ;
   MOV	 AL, SIDE		   ;SIDE TO FORMAT
   MOV	 Fhead, AX		   ;
   MOV	 AL, TRACK_TO_WRITE	   ;TRACK TO FORMAT
   MOV	 Fcylinder, AX		   ;

   XOR	 BX, BX 		   ;
   MOV	 BL, TARGET_DRIVE	   ;
   MOV	 CL, FORMAT_FUNC	   ;=42h
   MOV	 DX, OFFSET IOCTL_FORMAT   ;
   CALL  GENERIC_IOCTL		   ;

   MOV	 AL, IO_ERROR		   ;SAVE IO_ERROR, IN CASE FOR PC_AT CASE.
   PUSH  AX			   ;

   XOR	 BX, BX 		   ;
   MOV	 BL, TARGET_DRIVE	   ;
   MOV	 T_DRV_SET_FLAG, 1	   ;INDICATE TARGET DRIVE PARM HAS BEEN SET
   MOV	 DX, OFFSET MT_IOCTL_DRV_PARM ;
   MOV	 MT_specialFunctions, SET_SP_FUNC_DEF ;
   CALL  SET_DRV_PARM_DEF	   ;SET IT BACK FOR NORMAL
				   ; OPERATION, EX. WRITING

   POP	 AX			   ;
   MOV	 IO_ERROR, AL		   ;RESTORE IO_ERROR

   POP	 ES			   ;

   RET				   ;

TRY_FORMAT ENDP 		   ;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <ERROR_MESSAGE - SAY WHAT AND WHERE FAILURE> ;AN000;
;*****************************************************************************
;									     *
ERROR_MESSAGE PROC NEAR 	   ;DISPLAY ERROR MESSAGE		     *
   PUBLIC ERROR_MESSAGE 	   ;AN000;MAKE ENTRY IN LINK MAP
;									     *
;  FUNCTION: THIS SUBROUTINE DISPLAYS WHAT OPERATION FAILED (READ OR WRITE)  *
;	     AND WHERE IT FAILED (TRACK NO. AND SIDE).			     *
;									     *
;  INPUT: AH = IOCTL I/O COMMAND CODE  (3=READ, 4=WRITE)		     *
;									     *
;*****************************************************************************
   CMP	 AH,READ_FUNC		   ;ERROR DURING READ ?
.XLIST				   ;
;	$IF	E
;	    MOV     BX,OFFSET READ_ERROR
;	    MOV     MSG_HARD_ERR_TYPE,BX ;ERROR DURING READ OP
;	    MOV     BL,TRACK_TO_READ	;SAVE BAD TRACK NUMBER FOR READ
;	$ELSE
;	    MOV     BX,OFFSET WRITE_ERROR
;	    MOV     MSG_HARD_ERR_TYPE,BX ;ERROR DURING WRITE OP
;	    MOV     BL,TRACK_TO_WRITE	;SAVE BAD TRACK NUMBER FOR WRITE
;	$ENDIF
.LIST				   ;
;  $IF	 E			   ;AN000;YES, READ ERROR
   JNE $$IF116
       MOV   BL,TRACK_TO_READ	   ;SAVE BAD TRACK NUMBER FOR READ
       MOV   DI,OFFSET MSGNUM_HARD_ERROR_READ ;AN000;
;  $ELSE			   ;AN000;NO, NOT READ, MUST BE WRITE ERROR
   JMP SHORT $$EN116
$$IF116:
       MOV   BL,TRACK_TO_WRITE	   ;SAVE BAD TRACK NUMBER FOR WRITE
       MOV   DI,OFFSET MSGNUM_HARD_ERROR_WRITE ;AN000;
;  $ENDIF			   ;AN000;READ ERROR?
$$EN116:
   MOV	 AL,SIDE		   ;
   MOV	 DRIVE_LETTER,"A"	   ;
   dec	 dl			   ;change logical drive letter to physical one.
   ADD	 DRIVE_LETTER,DL	   ;SHOW DRIVE LETTER
.XLIST				   ;
;	MOV	BYTE PTR MSG_HARD_ERROR_PTR+8,AL ;SIDE NUMBER
;	MOV	BYTE PTR MSG_HARD_ERROR_PTR+10,BL ;TRACK NUMBER WHERE THE ERROR
.LIST				   ;
   MOV	 BYTE PTR ERROR_SIDE_NUMBER,AL ;AC000;SIDE NUMBER
   MOV	 BYTE PTR ERROR_TRACK_NUMBER,BL ;AC000;TRACK NUMBER WHERE THE ERROR
				   ;CR,LF,"Unrecoverable read/write error on drive %1",CR,LF
   CALL  SENDMSG		   ;"Side %2, track %3",CR,LF			;ACN000;

   RET				   ;
ERROR_MESSAGE ENDP		   ;
.XLIST				   ;
; HEADER <PROMPT - READ RESPONSE FROM KEYBOARD>
;KB_INPUT_FUNC EQU 0C01H		 ;DOS KEYBOARD INPUT
;*****************************************************************************
;									     *
;PROMPT  PROC	 NEAR			 ;DISPLAY MESSAGE		     *
;					   AND GET A USER INPUT CHARACTER    *
;	 PUBLIC  PROMPT 						     *
;									     *
;	INPUT:	DX = MESSAGE POINTER					     *
;	OUTPUT: BYTE USER_INPUT 					     *
;									     *
;*****************************************************************************
;	 PUSH	 AX
;	 MOV	 AX,KB_INPUT_FUNC	 ;KEYBOARD INPUT
;	 INT	 21H
;	 MOV	 USER_INPUT,AL		 ;SAVE USER'S RESPONSE
;	 POP	 AX
;	 RET
;PROMPT  ENDP
;   HEADER <CALL_PRINTF - COMMON DRIVER TO PRINTF, DISPLAY MESSAGE>
;CALL_PRINTF PROC NEAR
;   PUBLIC CALL_PRINTF
;INPUT - DX HAS OFFSET INTO DS OF MESSAGE PARM LIST
;   PUSH  DX
;   PUSH  CS
;   CALL  PRINTF

;   RET
;CALL_PRINTF ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
.list				   ;
   HEADER <SENDMSG - PASS IN REGS DATA FROM MSG DESCRIPTOR TO DISP MSG> ;AN000;
SENDMSG PROC NEAR		   ;AN000;
   PUBLIC SENDMSG		   ;AN000;
; INPUT - DI=POINTER TO MSG_DESC STRUC FOR THIS MESSAGE
; OUTPUT - IF CARRY SET, EXTENDED ERROR MSG ATTEMPTED DISPLAYED
;	   IF CARRY CLEAR, ALL OK
;	   IN EITHER CASE, DI AND AX ALTERED, OTHERS OK
;  =  =  =  =  =  =  =	=  =  =  =  =

   PUSH  BX			   ;AN000;SAVE CALLER'S REGS
   PUSH  CX			   ;AN000;
   PUSH  DX			   ;AN000;
   PUSH  SI			   ;AN000;

;		 PASS PARMS TO MESSAGE HANDLER IN
;		 THE APPROPRIATE REGISTERS IT NEEDS.
   MOV	 BX,[DI].MSG_NUM	   ;AC006;MESSAGE NUMBER
   MOV	 SI,[DI].MSG_SUBLIST	   ;AN000;OFFSET IN ES: OF SUBLIST, OR 0 IF NONE
   MOV	 CX,[DI].MSG_COUNT	   ;AN000;NUMBER OF %PARMS, 0 IF NONE
   MOV	 DX,[DI].MSG_CLASS	   ;AN000;CLASS IN HIGH BYTE, INPUT FUNCTION IN LOW
   MOV	 AX,SELECT_MPX		   ;AN006;REQUEST THE SELECT MULTIPLEXOR, IF PRESENT
   INT	 MULTIPLEXOR		   ;AN006;CALL THE MULTIPLEXOR FUNCTION

   CMP	 AL,SELECT_PRESENT	   ;AN006;CHECK MULTIPLEXOR RESPONSE CODE
;  $IF	 NE			   ;AN006;IF SELECT HAS NOT HANDLED THE MESSAGE
   JE $$IF119
       MOV   AX,[DI].MSG_NUM	   ;AN000;MESSAGE NUMBER
       MOV   BX,[DI].MSG_HANDLE    ;AN006;HANDLE TO DISPLAY TO
       CALL  SYSDISPMSG 	   ;AN000;DISPLAY THE MESSAGE

;      $IF   C			   ;AN000;IF THERE IS A PROBLEM
       JNC $$IF120
				   ;AX=EXTENDED ERROR NUMBER			;AN000;
	   LEA	 DI,MSGNUM_EXTERR  ;AN000;GET REST OF ERROR DESCRIPTOR
	   MOV	 BX,[DI].MSG_HANDLE ;AN000;HANDLE TO DISPLAY TO
	   MOV	 SI,[DI].MSG_SUBLIST ;AN000;OFFSET IN ES: OF SUBLIST, OR 0 IF NONE
	   MOV	 CX,[DI].MSG_COUNT ;AN000;NUMBER OF %PARMS, 0 IF NONE
	   MOV	 DX,[DI].MSG_CLASS ;AN000;CLASS IN HIGH BYTE, INPUT FUNCTION IN LOW
	   CALL  SYSDISPMSG	   ;AN000;TRY TO SAY WHAT HAPPENED

	   STC			   ;AN000;REPORT PROBLEM
;      $ENDIF			   ;AN000;PROBLEM WITH DISPLAY?
$$IF120:
;  $ELSE			   ;AN006;SINCE SELECT DID THE MESSAGE
   JMP SHORT $$EN119
$$IF119:
       MOV   SELECT_FLAG,TRUE	   ;AN006;INDICATE SELECT IS DOING THE MESSAGES
       CLC			   ;AN006;GENERATE A "NO PROBLEM" RESPONSE
;  $ENDIF			   ;AN006;DID SELECT HANDLE THE MESSAGE?
$$EN119:

   POP	 SI			   ;AN000;RESTORE CALLER'S REGISTERS
   POP	 DX			   ;AN000;
   POP	 CX			   ;AN000;
   POP	 BX			   ;AN000;

   RET				   ;AN000;
SENDMSG ENDP			   ;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <YESNO - DETERMINE IF A RESPONSE IS YES OR NO> ;AN000;
YESNO PROC NEAR 		   ;AN000;
   PUBLIC YESNO 		   ;AN000;MAKE ENTRY IN LINK MAP
;INPUT: DL=CHAR WITH Y OR N EQUIVALENT CHAR TO BE TESTED
;	SELECT_FLAG - IF SELECT IS DOING MESSAGES, ALWAYS ASSUME "NO"
;OUTPUT: AX=0=NO; AX=1=YES ; AX=2=INVALID RESPONSE, NEITHER Y NOR N
;	IF CARRY SET, PROBLEM WITH THE FUNCTION, CALLER SHOULD ASSUME "NO"
;  =  =  =  =  =  =  =	=  =  =  =  =

   CMP	 SELECT_FLAG,TRUE	   ;AN006;IS SELECT DOING THE MESSAGES?
;  $IF	 NE			   ;AN006;IF SELECT HAS NOT HANDLED THE MESSAGE
   JE $$IF124
				   ;AL=SUBFUNCTION, AS:
				   ;  20H=CAPITALIZE SINGLE CHAR
				   ;  21H=CAPITALIZE STRING
				   ;  22H=CAPITALIZE ASCIIZ STRING
				   ;  23H=YES/NO CHECK
				   ;  80H BIT 0=USE NORMAL UPPER CASE TABLE
				   ;  80H BIT 1=USE FILE UPPER CASE TABLE
				   ;DL=CHAR TO CAP (FUNCTION 23H)		;AN000;
       MOV   AX,(GET_EXT_CNTRY_INFO SHL 8) + YESNO_CHECK ;AN000;(6523H) GET EXTENDED
				   ; COUNTRY INFORMATION, (Y/N)
       INT   21H		   ;AN000;SEE IF Y OR N

;  $ELSE			   ;AN006;SINCE SELECT IS NOT PRESET
   JMP SHORT $$EN124
$$IF124:
       MOV   AX,NO		   ;AN006;ASSUME RESPONSE WAS 'NO'
;  $ENDIF			   ;AN006;
$$EN124:
   RET				   ;AN000;RETURN TO CALLER
YESNO ENDP			   ;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =
;(deleted ;AN013;)   HEADER <READ_VOLSER - OBTAIN OLD VOLUME SERIAL NUMBER FROM SOURCE> ;AN000;
;(deleted ;AN013;) READ_VOLSER PROC NEAR	      ; 			;AN000;
;(deleted ;AN013;)    PUBLIC READ_VOLSER	      ; 			;AN000;
;(deleted ;AN013;) ;IF THE SOURCE DISKETTE SUPPORTED A VOL SERIAL NUMBER, THEN MAKE A NEW ONE
;(deleted ;AN013;) ; AND SEND IT TO THE TARGET DISKETTE.  FOR OLD STYLE DISKETTES THAT DID NOT
;(deleted ;AN013;) ; HAVE ANY VOL SERIAL NUMBER, MAKE NO CHANGE AFTER THE TRADITIONAL FULL COPY.
;(deleted ;AN013;) ;INPUT: SOURCE AND TARGET DRIVE ID
;(deleted ;AN013;) ;	   THE TARGET DISKETTE IS A COMPLETE COPY OF THE SOURCE.
;(deleted ;AN013;) ;REFERENCED: A_MEDIA_ID_INFO STRUC (DEFINED IN DISKCOPY.EQU)
;(deleted ;AN013;) ; = = = = = = = = = = = = = = = = = =
;(deleted ;AN013;) ;		  ISSUE GET MEDIA ID FROM SOURCE
;(deleted ;AN013;)    MOV BH,ZERO		 ;BH=0, RES		   ;AN000;
;(deleted ;AN013;)    MOV BL,SOURCE_DRIVE	 ;BL=DRIVE NUM (1=A:, 2=B:, ETC);AN000;
;(deleted ;AN013;)    MOV DX,OFFSET MEDIA_ID_BUF ;DS:DX=BUFFER (see A_MEDIA_ID_INFO STRUC);AN000;
;(deleted ;AN013;)    DOSCALL GSET_MEDIA_ID,GET_ID ;(6900H) GET MEDIA ID	;AC009;
;(deleted ;AN013;)				 ;CARRY SET ON ERROR (OLD STYLE BOOT RECORD)
;(deleted ;AN013;)
;(deleted ;AN013;)    $IF NC			 ;IF THERE IS NO PROBLEM	;AN000;
;(deleted ;AN013;) ;	     GET CURRENT DATE
;(deleted ;AN013;)	  DOSCALL GET_DATE	 ;READ SYSTEM DATE		;AN000;
;(deleted ;AN013;)				 ;OUTPUT: DL = DAY (1-31)
;(deleted ;AN013;)				 ;  AL = DAY OF WEEK (0=SUN,6=SAT)
;(deleted ;AN013;)				 ;  CX = YEAR (1980-2099)
;(deleted ;AN013;)				 ;  DH = MONTH (1-12)
;(deleted ;AN013;)	  PUSH	CX		 ;SAVE THESE FOR		;AN000;
;(deleted ;AN013;)	  PUSH	DX		 ; INPUT INTO HASH ALGORITHM	;AN000;
;(deleted ;AN013;) ;	      GET CURRENT TIME
;(deleted ;AN013;)	  DOSCALL GET_TIME	 ;READ SYSTEM TIME CLOCK	;AN000;
;(deleted ;AN013;)				 ;OUTPUT: CH = HOUR (0-23)
;(deleted ;AN013;)				 ;  CL = MINUTES (0-59)
;(deleted ;AN013;)				 ;  DH = SECONDS (0-59)
;(deleted ;AN013;)				 ;  DL = HUNDREDTHS (0-99)
;(deleted ;AN013;)
;(deleted ;AN013;) ; HASH THESE INTO A UNIQUE 4 BYTE NEW VOLUME SERIAL NUMBER:
;(deleted ;AN013;) ;	      MI_SERIAL+0 = DX FROM DATE + DX FROM TIME
;(deleted ;AN013;) ;	      MI_SERIAL+2 = CX FROM DATE + CX FROM TIME
;(deleted ;AN013;)
;(deleted ;AN013;)	  POP	AX		 ;GET THE DX FROM DATE		;AN000;
;(deleted ;AN013;)	  ADD	AX,DX		 ;ADD IN THE DX FROM TIME	;AN000;
;(deleted ;AN013;)	  MOV	WORD PTR MEDIA_ID_BUF.MI_SERIAL,AX ;SAVE FIRST RESULT OF HASH;AN000;
;(deleted ;AN013;)
;(deleted ;AN013;)	  POP	AX		 ;GET THE CX FROM DATE		;AN000;
;(deleted ;AN013;)	  ADD	AX,CX		 ;ADD IN THE CX FROM TIME	;AN000;
;(deleted ;AN013;)	  MOV	WORD PTR MEDIA_ID_BUF.MI_SERIAL+WORD,AX ;SAVE SECOND RESULT OF HASH;AN000;
;(deleted ;AN013;)
;(deleted ;AN013;)	  MOV	VOLSER_FLAG,TRUE ;REQUEST THE NEW VOL SERIAL NUMBER BE WRITTEN;AN000;
;(deleted ;AN013;)    $ENDIF			 ;				;AN000;
;(deleted ;AN013;)    RET			 ;RETURN TO CALLER		;AN000;
;(deleted ;AN013;) READ_VOLSER ENDP		 ;				;AN000;
; = = = = = = = = = = = = = = = = = = =
   HEADER <WRITE_VOLSER - PUT NEW VOL SER NUMBER TO TARGET> ;AN000;
WRITE_VOLSER PROC NEAR		   ;AN000;
   PUBLIC WRITE_VOLSER		   ;AN000;MAKE ENTRY IN LINK MAP
   CMP	 VOLSER_FLAG,TRUE	   ;AN000;IF NEW NUMBER READY TO BE WRITTEN
;  $IF	 E			   ;AN000;THEN WRITE IT
   JNE $$IF127

;NOTE FOR ;AN013;
;THERE IS NO NEED TO DO A SET MEDIA ID TO WRITE OUT THE MODIFIED SERIAL NUMBER
;BECAUSE THAT NUMBER WAS CHANGED IN THE IMAGE OF THE BOOT RECORD WHEN THE
;ORIGINAL BOOT RECORD WAS READ IN, SO WHEN THAT TRACK IMAGE WAS WRITTEN,
;IT CONTAINED THE NEW SERIAL NUMBER ALREADY.

;(deleted ;AN013;) ;	 ISSUE SET MEDIA ID TO TARGET
;(deleted ;AN013;)  MOV   BH,ZERO		;BH=0, RES			;AN000;
;(deleted ;AN013;)  MOV   BL,TARGET_DRIVE	;BL=DRIVE NUM			;AN000;
;(deleted ;AN013;)  MOV   DX,OFFSET MEDIA_ID_BUF ;DS:DX=BUFFER (see STRUC above);AN000;
;(deleted ;AN013;)  DOSCALL GSET_MEDIA_ID,SET_ID ;(6901H) SET MEDIA ID		;AC009;

; NOTE: IN THE FOLLOWING TWO SUBLISTS, WE ARE GOING TO DISPLAY, IN HEX,
; A CONSECUTIVE SET OF 4 BYTES, THE VOLUME SERIAL NUMBER.  THE ORDER OF
; THESE TWO WORDS OF HEX IS, LEAST SIGNIFICANT WORD FIRST, THEN THE
; MOST SIGNIFICANT WORD.  WHEN DISPLAYED, THE MOST SIGNIFICANT IS TO BE
; DISPLAYED FIRST, SO THE VALUE AT SERIAL+2 GOES TO THE 26A SUBLIST,
; AND THE LEAST SIGNIFICANT VALUE AT SERIAL+0 GOES TO THE SECOND POSITION,
; REPRESENTED BY THE 26B SUBLIST.

       LEA   AX,SERIAL		   ;AC013;GET POINTER TO DATA TO BE PRINTED
       MOV   SUBLIST_26B.SUB_VALUE,AX ;AN001; INTO THE SUBLIST

       LEA   AX,SERIAL+WORD	   ;AC013;GET POINTER TO DATA TO BE PRINTED
       MOV   SUBLIST_26A.SUB_VALUE,AX ;AN001; INTO THE SUBLIST

       PRINT MSGNUM_CR_LF	   ;AN000;SKIP A SPACE

				   ;"Volume Serial Number is %1-%2"
       PRINT MSGNUM_SERNO	   ;AN001;DISPLAY THE NEW SERIAL NUMBER

;  $ENDIF			   ;AN000;
$$IF127:
   RET				   ;AN000;RETURN TO CALLER
WRITE_VOLSER ENDP		   ;AN000;
; = = = = = = = = = = = = = = = = = = =
   HEADER <PRESS_ANY_KEY - PUTS A BLANK LINE BEFORE PROMPT> ;AN000;
PRESS_ANY_KEY PROC NEAR 	   ;
;THE CANNED MESSAGE "PRESS ANY KEY..." DOES NOT START WITH CR,LF.
;THIS PUTS OUT THE CR LF TO CAUSE SEPARATION OF THIS PROMP FROM
;PRECEEDING MESSAGES.
;  =  =  =  =  =  =  =	=  =  =  =  =
   PRINT MSGNUM_CR_LF		   ;AN000;SKIP A SPACE

   PRINT MSGNUM_STRIKE		   ;AN000;"Press any key when ready..."

   RET				   ;AN000;RETURN TO CALLER
PRESS_ANY_KEY ENDP		   ;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =
   PUBLIC DISKCOPY_END		   ;
DISKCOPY_END LABEL NEAR 	   ;

   PATHLABL DISKCOPY		   ;AN015;
CSEG ENDS			   ;
   END	 DISKCOPY		   ;
