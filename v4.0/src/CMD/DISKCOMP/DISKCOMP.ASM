	PAGE	90,132			;A2
	TITLE	DISKCOMP.SAL - COPY COMPLETE DISKETTE
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: DISKCOMP

; DESCRIPTIVE NAME: Diskette to diskette complete compare Utility

;FUNCTION: DISKCOMP is to compare the contents of the diskette in the
;	   specified first drive to the diskette in the second
;	   drive.  If the first drive has a vol serial number, that
;	   field in both diskettes is ignored in the comparison
;	   of that one sector, because DISKCOPY will create a unique
;	   volume serial number when it duplicates a diskette.

;	   Multiple compares may be performed with one load of DISKCOMP.
;	   A prompt, "Compare another (Y/N)?" permits additional
;	   executions, all with the same drive specifications.

; ENTRY POINT: "DISKCOMP" at ORG 100h, jumps to "BEGIN".

; INPUT: (DOS command line parameters)

;	      [d:][path] DISKCOMP  [d: [d:]] [/1] [/8]

;	 WHERE
;	      [d:][path] - Path where the DISKCOMP command resides.

;	      [d:] - To specify the First drive
;
;	      [d:] - To specify the Second drive
;
;	      [/1] - To compare only the first side of the diskette,
;		     regardless of the diskette or drive type.

;	      [/8] - To compare only the first 8 sectors per track,
;		     even if the first diskette contains 9/15 sectors
;		     per track.
;
; EXIT-NORMAL: Errorlevel = 0
;	      Function completed successfully.

; EXIT-ERROR: Errorlevel = 1
;	      Abnormal termination due to error, wrong DOS,
;	      invalid parameters, unrecoverable I/O errors on
;	      the diskette.
;	      Errorlevel = 2
;	      Termination requested by CTRL-BREAK.

; EFFECTS: The entire diskette is compared, including the unused
;	   sectors.  There is no awareness of the separate files
;	   involved.  A unique volume serial number is ignored
;	   for the comparison of the first sector.

; INCLUDED FILES:
;	   PATHMAC.INC - PATHGEN MACRO
;	   INCLUDE DCMPMACR.INC 	   ;(FORMERLY CALLED MACRO.DEF)
;	   INCLUDE DISKCOMP.EQU 	   ;EQUATES

; INTERNAL REFERENCES:
;    ROUTINES:
;	 BEGIN - entry point from DOS
;	 SET_LOGICAL_DRIVE - set log. drive letter as owner of drive
;	 COMP - compare the diskette image
;	 TEST_REPEAT - see if user wants to compare another
;	 READ_SOURCE - read from first drive as much as possible
;	 CHECK_SOURCE - determine first diskette type
;	 READ_A_SECTOR - use IOCTL read to get a sector
;	 CALC_TRACK_SIZE - find mem size to hold one track
;	 CHECK_MEMORY_SIZE - be sure enuf memory to compare 1 track
;	 COMP_TARGET - compare memory data with secon diskette
;	 CHECK_TARGET - compare second disk boot record
;	 SET_DRV_PARM - request IOCTL to set device parm
;	 COMP_TRACK - read and compare specified track
;	 SWAP_DRIVE - setup for diskette swapping
;	 READ_TRACK - read a track to memory
;	 READ_OP - IOCTL to read a track
;	 SET_FOR_THE_OLD - use pre 2.0 BPB
;	 SET_TRACKLAYOUT - determine sectors per track
;	 GENERIC_IOCTL - perform specified IOCTL function
;	 EXTENDED_ERROR_HANDLER - determine and service extended errors
;	 SET_DRV_PARM_DEF - set drive parms via IOCTL
;
;	 VOLSER - during compare of first sector, avoid vol ser #
;	 SENDMSG - passes parms to regs and invokes the system message routine.

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
;	 DCOMPSM.SAL - Defines the control blocks that describe the messages
;	 DCOMPPAR.SAL - Defines the control blocks that describe the
;		DOS Command line parameters.

; NOTES:
;	 This module should be processed with the SALUT preprocessor
;	 with the re-alignment not requested, as:

;		SALUT DISKCOMP,NUL

;	 To assemble these modules, the alphabetical or sequential
;	 ordering of segments may be used.

;	 Sample LINK command:

; LINK @DISKCOMP.ARF

; Where the DISKCOMP.ARF is defined as:

;	 DISKCOMP+
;	 DCOMPSM+
;	 DCOMPP+
;	 DCOMPPAR+
;	 COMPINIT

;	 These modules must be linked in this order.  The load module is
;	 a COM file, to be converted to COM with EXE2BIN.

; REVISION HISTORY:
;	     A000 Version 4.00: add PARSER, System Message Handler,
;		  Ignore vol serial number differences.
;	     A001 386 Support
;	     A002 Avoid duplicate switches
;	     A003 PTM 540 Show parm in error
;	     A004 PTM 752 Add close door after drive not ready
;	     A005 PTM 756 Add help msg after parm error message
;	     A006 PTM1100 Clear keyboard buffer before input response
;	     A007 PTM1464 Delete unused msgs: 22,23,24
;	     A008 PTM1406 USE 69H INSTEAD OF IOCTL FOR GET/SET MEDIA ID
;	     A009 PTM1605 PUT A BLANK LINE OUT BEFORE PRESS ANY KEY MSG
;	     A010 PTM1821 move INCLUDE COPYRIGH.INC to MSG_SERVICE macro
;	     A011 PTM3184 SUPPORT OS/2 1.0/1.1 TYPE BOOT RECORDS ALSO
;			REMOVE USE OF GET/SET MEDIA ID
;	     A012 PTM3262 Specify BASESW EQU 1 before PARSE.ASM
;	     A013 PTM3512 PATHGEN
;
; COPYRIGHT: The following notice is found in the OBJ code generated from
;	     the "DCOMPSM.SAL" module:

;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Property of Microsoft  "

;PROGRAM AUTHOR: Original written by: Jin K.
;		 4.00 modifications by: Edwin M. K.
;****************** END OF SPECIFICATIONS *****************************
	IF1				;					;AN000;
	    %OUT    COMPONENT=DISKCOMP, MODULE=DISKCOMP.SAL
	ENDIF				;					;AN000;
;*****************************************************************************
;									     *
;			     D I S K C O M P				     *
;									     *
;  UPDATE HISTORY: 8-21, 8-22, 8-30, 9-4, 9-20, 9-21, 12-19		     *
;		   2-15-84, 2-17, 4-29, 6-20,7-24,3-27-85		     *
;									     *
;*****************************************************************************

	INCLUDE PATHMAC.INC		;AN013;
	INCLUDE DCMPMACR.INC		;(FORMERLY CALLED MACRO.DEF)
	INCLUDE DISKCOMP.EQU		;EQUATES

;	       $salut (4,16,22,36) ;						;AN000;
;THIS MESSAGE DESCRIPTOR CONTROL BLOCK IS GENERATED, ONE PER MESSAGE,
;TO DEFINE THE SEVERAL PARAMETERS THAT ARE EXPECTED TO BE PASSED IN
;CERTAIN REGISTERS WHEN THE SYSDISPMSG FUNCTION IS TO BE INVOKED.

MSG_DESC       STRUC		   ;						;AN000;
MSG_NUM        DW    ?		   ;MESSAGE NUMBER (TO AX)			;AN000;
MSG_HANDLE     DW    ?		   ;HANDLE OF OUTPUT DEVICE (TO BX)		;AN000;
MSG_SUBLIST    DW    ?		   ;POINTER TO SUBLIST (TO SI)			;AN000;
MSG_COUNT      DW    ?		   ;SUBSTITUTION COUNT (TO CX)			;AN000;
MSG_CLASS      DW    ?		   ;MESSAGE CLASS (IN HIGH BYTE, TO DH) 	;AN000;
				   ;LOW BYTE HAS 0 (FUNCTION "NO INPUT", TO DL) ;AN000;
MSG_DESC       ENDS		   ;						;AN000;

MY_BPB	       STRUC
CBYTE_SECT     DW    0		   ; 200H  ;BYTES / SECTOR
CSECT_CLUSTER  DB    0		   ; 2h    ;SECTORS / CLUSTER
CRESEV_SECT    DW    0		   ; 1h    ;RESERVED SECTORS
CFAT	       DB    0		   ; 2h    ;# OF FATS
CROOTENTRY     DW    0		   ; 70h   ;# OF ROOT ENTRIES
CTOTSECT       DW    0		   ; 02D0h ;TOTAL # OF SECTORS INCLUDING
				   ;	     BOOT SECT, DIRECTORIES
MEDIA_DESCRIP  DB    0		   ;0FDh   ;MEDIA DISCRIPTOR
CSECT_FAT      DW    0		   ; 2h    ;SECTORS / FAT
CSECT_TRACK    DW    0		   ;
CHEAD	       DW    0		   ;
CHIDDEN_SECT   DD    0		   ;
BIG_TOT_SECT   DD    0		   ;
	       DB    6 DUP (0)	   ;
MY_BPB	       ENDS

CSEG	       SEGMENT PARA PUBLIC 'CODE' ;					;AN000;
	       ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

;*****************************************************************************
;									     *
;			EXTERNAL VARIABLES				     *
;									     *
;*****************************************************************************
;$salut (4,2,9,36)

.XLIST
;EXTRN	PROMPT	      :NEAR	   ;MESSAGE DISPLAY AND KEYBOARD INPUT ROUTINE
;EXTRN	ERROR_MESSAGE :NEAR	   ;ERROR MESSAGE DISPLAY ROUTINE
;EXTRN	COMPAT_ERROR  :NEAR
;EXTRN	PRINTF	      :NEAR	   ;MESSAGE DISPLAY ROUTINE
;EXTRN	YES		    :BYTE
;EXTRN	NO		    :BYTE
;EXTRN	MSG_FIRST_BAD_PTR   :BYTE
.LIST

 EXTRN	SYSLOADMSG    :NEAR	   ;SYSTEM MSG HANDLER INTIALIZATION		;AN000;
 EXTRN	SYSDISPMSG    :NEAR	   ;SYSTEM MSG HANDLER DISPLAY			;AN000;

 EXTRN	INIT	      :NEAR	   ;INITIALIZATION ROUTINE

 EXTRN	MSG_TRACKS	   :WORD   ;						;AN000;
 EXTRN	MSG_SECTRK	   :WORD   ;						;AN000;
 EXTRN	MSG_SIDES	   :WORD   ;						;AN000;

 EXTRN	ASCII_DRV1_ID	   :BYTE   ;						;AN000;
 EXTRN	ASCII_DRV2_ID	   :BYTE   ;						;AN000;

 EXTRN	SUBLIST_78	   :WORD   ;						;AN000;
 EXTRN	SUBLIST_17B	   :WORD   ;						;AN000;

 EXTRN	MSGNUM_EXTERR	   :WORD   ;EXTENDED ERROR MSG DESCRIPTOR		;AN000;
 EXTRN	MSGNUM_LOAD_FIRST  :BYTE   ;						;AC000;
 EXTRN	MSGNUM_LOAD_SECOND :BYTE   ;						;AC000;
 EXTRN	MSGNUM_NOT_COMPATIBLE:BYTE ;						;AC000;
 EXTRN	MSGNUM_COMP_ANOTHER:BYTE   ;						;AC000;
 EXTRN	MSGNUM_GET_READY   :BYTE   ;						;AC000;
 EXTRN	MSGNUM_CLOSE_DOOR  :BYTE   ;						;AN004;
 EXTRN	MSGNUM_FATAL_ERROR :BYTE   ;						;AC000;
 EXTRN	MSGNUM_UNSUF_MEMORY:BYTE   ;						;AC000;
 EXTRN	MSGNUM_BAD_FIRST   :BYTE   ;						;AC000;
 EXTRN	MSGNUM_BAD_SECOND  :BYTE   ;						;AC000;
 EXTRN	MSGNUM_HARD_ERROR_READ :BYTE ;						;AC000;
 EXTRN	MSGNUM_HARD_ERROR_COMP :BYTE ;						;AC000;
 EXTRN	MSGNUM_COMPARING   :BYTE   ;						;AC000;
 EXTRN	MSGNUM_STRIKE	   :BYTE   ;						;AC000;
 EXTRN	MSGNUM_WRITE_PROTECT:BYTE  ;						;AC000;
 EXTRN	MSGNUM_COMP_OK	   :BYTE   ;						;AC000;
 EXTRN	MSGNUM_NEWLINE	   :BYTE   ;
 EXTRN	DRIVE_LETTER	   :BYTE   ;
 EXTRN	SKIP_MSG	   :BYTE   ;NULL REPLACEMENT FOR DRIVE LETTER		;AN000;
 PAGE
;*****************************************************************************
;									     *
;			     PUBLIC VARIABLES				     *
;									     *
;*****************************************************************************

 PUBLIC DISKCOMP_BEGIN
 PUBLIC DISKCOMP_END
 PUBLIC RECOMMENDED_BYTES_SECTOR
 PUBLIC S_OWNER_SAVED
 PUBLIC T_OWNER_SAVED
 PUBLIC COMP
 PUBLIC SOURCE_DRIVE
 PUBLIC TARGET_DRIVE
 PUBLIC S_DRV_SECT_TRACK
 PUBLIC S_DRV_HEADS
 PUBLIC S_DRV_TRACKS
 PUBLIC T_DRV_SECT_TRACK
 PUBLIC T_DRV_HEADS
 PUBLIC T_DRV_TRACKS
 PUBLIC USER_OPTION
 PUBLIC COPY_TYPE
 PUBLIC END_OF_TRACK
 PUBLIC BUFFER_BEGIN
 PUBLIC START_BUFFER
 PUBLIC BUFFER_END
 PUBLIC TRACK_TO_READ
 PUBLIC TRACK_TO_COMP
 PUBLIC SIDE
 PUBLIC USER_INPUT
 PUBLIC MAIN_EXIT

 PUBLIC NO_OF_SIDES
 PUBLIC USER_OPTION_8
 PUBLIC ORG_SOURCE_DRIVE
 PUBLIC ORG_TARGET_DRIVE
 PUBLIC COMP_STATUS
 PUBLIC OPERATION

 PUBLIC IO_ERROR

 PUBLIC DS_IOCTL_DRV_PARM	   ;PLACE HOLDER FOR DEFAULT SOURCE DRV PARM
 PUBLIC DT_IOCTL_DRV_PARM	   ;PLACE HOLDER FOR DEFAULT TARGET DRV PARM
 PUBLIC DS_specialFunctions	   ;AND THEIR CONTENTS
 PUBLIC DT_specialFunctions
 PUBLIC DS_deviceType
 PUBLIC DT_deviceType
 PUBLIC DS_deviceAttributes
 PUBLIC DT_deviceAttributes
 PUBLIC DS_numberOfCylinders
 PUBLIC DT_numberOfCylinders
 PUBLIC DS_mediaType
 PUBLIC DT_mediaType
 PUBLIC DS_BPB_PTR
 PUBLIC DT_BPB_PTR

 PUBLIC MS_IOCTL_DRV_PARM	   ;DRIVE PARM FROM SOURCE MEDIUM
 PUBLIC MT_IOCTL_DRV_PARM	   ;DRIVE PARM FROM TARGET MEDIUM

;*****************************************************************************
 ORG	100H			   ;PROGRAM ENTRY POINT 			       ;

DISKCOMP:
 JMP	BEGIN
;*****************************************************************************
 EVEN				   ;PUT STACK ONTO A WORD ALIGNMENT BOUNDARY	;AN000;
;INTERNAL STACK AREA

 DB	64 DUP	('STACK   ')	   ;512 BYTES

MY_STACK_PTR LABEL WORD
 PAGE
;*****************************************************************************
;									     *
;			INTERNAL VARIABLES				     *
;									     *
;*****************************************************************************

;		     $salut (4,22,26,36) ;					;AN000;
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



; INPUT PARMETERS FROM INIT SUBROUTINE:

S_OWNER_SAVED	     DB  0	   ;DRIVE LETTER THAT OWNED
				   ; SOURCE DRIVE OWNERSHIP
T_OWNER_SAVED	     DB  0
RECOMMENDED_BYTES_SECTOR DW 0	   ;RECOMMENED BYTES/SECTOR FROM DEVICE PARA

;IT IS ASSUMED THE NEXT TWO BYTES ARE CONSECUTIVE,
;AND DEFINED IN SOURCE/TARGET ORDER, BY DCOMPPAR.SAL.
SOURCE_DRIVE	     DB  0	   ;1=A:, 2=B:,...
TARGET_DRIVE	     DB  0

ORG_SOURCE_DRIVE     DB  ?	   ;ORIGINAL SOURCE DRIVE
ORG_TARGET_DRIVE     DB  ?	   ;ORIGINAL TARGET DRIVE

USER_OPTION	     DB  0
COPY_TYPE	     DB  1
START_BUFFER	     DW  0
BUFFER_BEGIN	     DW  1000H	   ;BEGINNING OF BUFFER ADDR [IN SEGMENT]
BUFFER_END	     DW  3FF0H	   ;END OF BUFFER ADDR [IN SEGMENT]
USER_OPTION_8	     DB  ?
SECT_TRACK_LAYOUT    DW  0

S_DRV_SECT_TRACK     DB  ?	   ;SECT/TRACK, device informations.
S_DRV_HEADS	     DB  ?	   ;# OF HEADS
S_DRV_TRACKS	     DB  ?	   ;# OF TRACKS
T_DRV_SECT_TRACK     DB  ?
T_DRV_HEADS	     DB  ?
T_DRV_TRACKS	     DB  ?

;LOCAL VARIABLES:
FIRST_TIME	     DB  0	   ;SWITCH TO ACTIVATE VOLSER CHECK		;AN000;
EXITFL		     DB  EXOK	   ;ERRORLEVEL VALUE				;AN000;
		     PUBLIC EXITFL ;						;AN000;
EXCBR		     EQU 2	   ;CONTROL-BREAK REQUESTED TERMINATION 	;AN000;
EXVER		     EQU 1	   ;BAD DOS VERSION ERRORLEVEL CODE		;AN000;
EXPAR		     EQU 1	   ;ERROR IN INPUT PARMS IN COMMAND LINE	;AN000;
EXOK		     EQU 0	   ;NORMAL ERRORLEVEL RET CODE			;AN000;
		     PUBLIC EXPAR  ;						;AN000;

IOCTL_SECTOR	     DW  1	   ;used for READ_A_SECTOR routine.
IOCTL_TRACK	     DW  0	   ;IN THE TRACK
IOCTL_HEAD	     DW  0	   ;HEAD 0
SAV_CSECT	     DW  0	   ;TEMPORARY SAVING PLACE

BOOT_SECT_TRACK      DW  0	   ;TEMP SAVING PLACE OF SECTOR/TRACK
BOOT_TOT_TRACK	     DW  0	   ;FOUND FROM THE BOOT SECTOR. max # of tracks
BOOT_NUM_HEAD	     DW  0	   ;NUMBER OF HEADS
BOOT_BYTE_SECTOR     DW  0	   ;BYTES / SECTOR

READ_S_BPB_FAILURE   DB  0	   ;GET MEDIA BPB. SUCCESS=0, FAILURE=1
READ_T_BPB_FAILURE   DB  0

;*** Informations gotten from CHECK_SOURCE.
;*** These will be used as a basis for the comp process.
LAST_TRACK	     DB  79	   ;LAST CYLINDER OF THE DASD (39 OR 79)
END_OF_TRACK	     DB  15	   ;END OF TRACK
bSECTOR_SIZE	     DW  512	   ;BYTES/SECTOR in bytes
NO_OF_SIDES	     DB  ?	   ;0=SINGLE SIDED, 1=DOUBLE SIDED

TRACK_TO_READ	     DB  0
TRACK_TO_COMP	     DB  0
TRACK_SIZE	     DW  0	   ;BYTES/CYLINDER [IN SEGMENTS]
SECTOR_SIZE	     DB  0	   ;BYTES/SECTOR [IN SEGMENTS]
BYTES_IN_TRACK	     DW  ?	   ;BYTES/ONE SIDE TRACK (USED IN COMP_TRACK)
BUFFER_PTR	     DW  ?
COMP_ERROR	     DB  0
SIDE		     DB  ?
OPERATION	     DB  ?
COMP_STATUS	     DB  ?
USER_INPUT	     DB  ?	   ;DISKCOMP AGAIN?
SEC_BUFFER	     DW  ?	   ;SECONDARY BUFFER SEG ADDR
COMPARE_PTR	     DW  ?	   ;COMPARE POINTER
IO_ERROR	     DB  0	   ;USED TO INDICATE IF READ/WRITE ERROR MESSAGE
MSG_FLAG	     DB  ?
S_DRV_SET_FLAG	     DB  0	   ;SOURCE DEVICE PARM HAS BEEN SET?
T_DRV_SET_FLAG	     DB  0

;---------------------------------------
;DEVICE PARAMETER TABLE
;the returned info. still has the following format.

DS_IOCTL_DRV_PARM    LABEL BYTE    ;PLACE HOLDER FOR DEFAULT TARGET DRV PARM
DS_specialFunctions  db  ?
DS_deviceType	     db  ?	   ;0=5.25, 1=5.25 96 TPI, 2=3.5" 720 KB
				   ;3=8" SINGLE, 4=8" DOUBLE, 5=HARD DISK
DS_deviceAttributes  dw  ?	   ;0001h - NOT REMOVABLE, 0002h - CHANGE
				   ; LINE SUPPORTED
DS_numberOfCylinders dw  ?
DS_mediaType	     db  ?
DS_BPB_PTR	     LABEL BYTE
DS_deviceBPB	     my_bpb <>
DS_trackLayout	     LABEL WORD    ;						;AC000;
		     my_trackLayout ;						;AC000;
;---------------------------------------

DT_IOCTL_DRV_PARM    LABEL BYTE
DT_specialFunctions  db  ?
DT_deviceType	     db  ?	   ;0=5.25, 1=5.25 96 TPI, 2=3.5" 720 KB
				   ;3=8" SINGLE, 4=8" DOUBLE, 5=HARD DISK
DT_deviceAttributes  dw  ?	   ;0001h - NOT REMOVABLE, 0002h - CHANGE
				   ; LINE SUPPORTED
DT_numberOfCylinders dw  ?
DT_mediaType	     db  ?
DT_BPB_PTR	     LABEL BYTE
DT_deviceBPB	     my_bpb <>
DT_trackLayout	     LABEL WORD    ;						;AC000;
		     my_trackLayout ;						;AC000;

;---------------------------------------

MS_IOCTL_DRV_PARM    LABEL BYTE    ;DRIVE PARM FROM SOURCE MEDIUM
MS_specialFunctions  db  ?
MS_deviceType	     db  ?	   ;0=5.25, 1=5.25 96 TPI, 2=3.5" 720 KB
				   ;3=8" SINGLE, 4=8" DOUBLE, 5=HARD DISK
MS_deviceAttributes  dw  ?	   ;0001h - NOT REMOVABLE, 0002h - CHANGE
				   ; LINE SUPPORTED
MS_numberOfCylinders dw  ?
MS_mediaType	     db  ?
MS_BPB_PTR	     LABEL BYTE
MS_deviceBPB	     my_bpb <>
MS_deviceBPB_leng    equ $-MS_deviceBPB
MS_trackLayout	     LABEL WORD    ;						;AC000;
		     my_trackLayout ;						;AC000;
;---------------------------------------
MT_IOCTL_DRV_PARM    LABEL BYTE    ;DRIVE PARM FROM TARGET MEDIUM
MT_specialFunctions  db  ?
MT_deviceType	     db  ?	   ;0=5.25, 1=5.25 96 TPI, 2=3.5" 720 KB
				   ;3=8" SINGLE, 4=8" DOUBLE, 5=HARD DISK
MT_deviceAttributes  dw  ?	   ;0001h - NOT REMOVABLE, 0002h - CHANGE
				   ; LINE SUPPORTED
MT_numberOfCylinders dw  ?
MT_mediaType	     db  ?
MT_BPB_PTR	     LABEL BYTE
MT_deviceBPB	     my_bpb <>
MT_trackLayout	     LABEL WORD    ;						;AC000;
		     my_trackLayout ;						;AC000;

;IOCTL read/write a track.
IOCTL_R_W	     LABEL BYTE
specialFunctions     db  0
Head		     dw  ?
Cylinder	     dw  ?
FirstSectors	     dw  ?
numberOfSectors      dw  ?
TAddress_off	     dw  ?
TAddress_seg	     dw  ?

;(deleted ;AN011;) MEDIA_ID_BUFFER A_MEDIA_ID_INFO <> ;BUFFER FOR GET/SET MEDIA ID ;AN000;
		     PATHLABL DISKCOMP ;AN013;
		     HEADER <BEGIN - VERSION CHECK, SYSMSG INIT, EXIT TO DOS> ; ;AN000;
		     PUBLIC DISKCOMP_BEGIN ;					;AN000;
DISKCOMP_BEGIN	     LABEL BYTE
;*****************************************************************************
;									     *
;		 D I S K C O M P   M A I N   P R O G R A M		     *
;									     *
;*****************************************************************************

;  $salut (4,4,10,36)		   ;						;AN000;
BEGIN PROC NEAR
   PUBLIC BEGIN 		   ;						;AN000;
;OUTPUT - "EXITFL" HAS ERRORLEVEL RETURN CODE

   MOV	 SP, OFFSET MY_STACK_PTR   ;MOVE SP TO MY STACK AREA
   CALL  SYSLOADMSG		   ;INIT SYSMSG HANDLER 			;AN000;

;  $IF	 C			   ;IF THERE WAS A PROBLEM			;AN000;
   JNC $$IF1
       CALL  SYSDISPMSG 	   ;LET HIM SAY WHY HE HAD A PROBLEM		;AN000;

       MOV   EXITFL,EXVER	   ;TELL ERRORLEVEL BAD DOS VERSION		;AN000;
;  $ELSE			   ;SINCE SYSDISPMSG IS HAPPY			;AN000;
   JMP SHORT $$EN1
$$IF1:
       CALL  INIT		   ;RUN INITIALIZATION ROUTINE

       CMP   DX,FINE		   ;CHECK FOR ERROR DURING INIT
;      $IF   E			   ;IF NO ERROR THEN PROCEED TO COMP
       JNE $$IF3
;	   $DO
$$DO4:
	       CALL  COMP	   ;PERFORM DISKCOMP

	       CALL  TEST_REPEAT   ;COMP ANOTHER ?

;	   $ENDDO C
	   JNC $$DO4
				   ;NORMAL RETURN CODE ALREADY IN "EXITFL"
;      $ELSE			   ;ELSE IF ERROR DETECTED IN INIT
       JMP SHORT $$EN3
$$IF3:
	   MOV	 DI,DX		   ;PASS NUMBER OF ERROR MSG, IF ANY		;AD000;
				   ;DI HAS OFFSET OF MESSAGE DESCRIPTOR
	   CALL  SENDMSG	   ;DISPLAY THE ERROR MESSAGE			;AC000;

	   MOV	 EXITFL,EXVER	   ;ERROR RETURN CODE				;AC000;
;      $ENDIF
$$EN3:
       JMP   SHORT EXIT_TO_DOS

MAIN_EXIT:			   ;COME HERE AFTER CONTROL-BREAK
       MOV   EXITFL,EXCBR	   ;  FOR CONTROL-BREAK EXIT			;AC000;

EXIT_TO_DOS:
       XOR   BX, BX

       MOV   BL, S_OWNER_SAVED	   ;RESTORE ORIGINAL SOURCE,
				   ; TARGET DRIVE OWNER.
       CALL  SET_LOGICAL_DRIVE

       MOV   BL, T_OWNER_SAVED
       CALL  SET_LOGICAL_DRIVE

       CMP   S_DRV_SET_FLAG, 0
;      $IF   NE 		   ;						;AN000;
       JE $$IF8
	   MOV	 BL, S_OWNER_SAVED
	   MOV	 DS_specialFunctions, SET_SP_FUNC_DOS ;=0
	   MOV	 DX, OFFSET DS_IOCTL_DRV_PARM
	   CALL  SET_DRV_PARM_DEF  ;RESTORE SOURCE DRIVE PARM

;      $ENDIF			   ;						;AN000;
$$IF8:

       CMP   T_DRV_SET_FLAG, 0
;      $IF   NE 		   ;						;AN000;
       JE $$IF10
	   MOV	 BL, T_OWNER_SAVED
	   MOV	 DT_specialFunctions, SET_SP_FUNC_DOS ;=0
	   MOV	 DX, OFFSET DT_IOCTL_DRV_PARM
	   CALL  SET_DRV_PARM_DEF  ;RESTORE TARGET DRIVE PARM

;      $ENDIF			   ;						;AN000;
$$IF10:
EXIT_PROGRAM:
       MOV   AL,EXITFL		   ;PASS ERRORLEVEL RET CODE			;AN000;
;  $ENDIF			   ;OK WITH SYSDISPMSG? 			;AN000;
$$EN1:
   MOV	 AL,EXITFL		   ;PASS BACK ERRORLEVEL RET CODE		;AN000;
   DOSCALL RET_CD_EXIT		   ;RETURN TO DOS WITH RET CODE 		;AN000;

   INT	 20H			   ;IF ABOVE NOT WORK,				;AN000;
BEGIN ENDP			   ;						;AN000;
; = = = = = = = = = = = = = = = = =
   HEADER <MORE_INIT - FINISH INIT, DO COMP> ;					;AN000;
MORE_INIT PROC NEAR		   ;						;AN000;
   RET				   ;RETURN TO CALLER				;AN000;
MORE_INIT ENDP			   ;						;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <SET_LOGICAL_DRIVE - SET LOG. DRV LETTER THAT OWNS DRIVE> ;		;AN000;
   PUBLIC SET_LOGICAL_DRIVE
;*****************************************************************************
SET_LOGICAL_DRIVE PROC NEAR
;	*** SET THE LOGICAL DRIVE LETTER THAT WILL BE THE OWNER OF THE DRIVE
;	INPUT: BL - DRIVE LETTER
;	OUTPUT: OWNER WILL BE SET ACCORDINGLY.
;*****************************************************************************
   CMP	 BL, 0			   ;IS THIS DRIVE ZERO?
				   ;IF BL = 0, THEN JUST RETURN
;  $IF	 NE
   JE $$IF13
       DOSCALL IOCTL_FUNC,SET_LOG_DRIVE ;					;AC000;
				   ;SET BL AS AN OWNER OF THAT DRIVE
;  $ENDIF
$$IF13:
   RET
SET_LOGICAL_DRIVE ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <COMP - PERFORM THE OVERALL COMPARISON> ;				;AN000;
;*****************************************************************************
COMP PROC NEAR
;*****************************************************************************
   MOV	 AL,ORG_SOURCE_DRIVE	   ;INITIALIZE THE FIRST AND SECOND
   MOV	 SOURCE_DRIVE,AL	   ;DRIVE IN THE ORDER THE USER
   MOV	 AL,ORG_TARGET_DRIVE	   ;ENTERED ON THE COMMAND LINE
   MOV	 TARGET_DRIVE,AL
   MOV	 AX, RECOMMENDED_BYTES_SECTOR
   MOV	 bSECTOR_SIZE, AX	   ;USE RECOMMENDED SECTOR SIZE
				   ; TO READ A SECTOR
   MOV	 READ_S_BPB_FAILURE, 0	   ;RESET GET BPB FAILURE FLAG
   MOV	 READ_T_BPB_FAILURE, 0
   MOV	 COMP_ERROR,0		   ;RESET COMPARE ERROR COUNT
   MOV	 COMP_STATUS,OK 	   ;RESET COMP STATUS BYTE
   CMP	 COPY_TYPE,2		   ;IF TWO DRIVE COMP
;  $IF	 E
   JNE $$IF15
       CALL  DISPLAY_LOAD_FIRST    ;"Insert FIRST diskette in drive %1:"	;AN000;

       CALL  DISPLAY_LOAD_SECOND   ;"Insert SECOND diskette in drive %1:"	;AN000;

       CALL  PRESS_ANY_KEY	   ;"Press any key to continue . . ."		;AC009;

;  $ENDIF
$$IF15:
   MOV	 TRACK_TO_READ,0	   ;INITIALIZE TRACK NUMBERS
   MOV	 TRACK_TO_COMP,0

COMP_TEST_END:
   MOV	 AL,TRACK_TO_COMP	   ;WHILE TRACK_TO_COMP<=LAST_TRACK
   CMP	 AL,LAST_TRACK
   JA	 COMP_END

   CALL  READ_SOURCE

   CMP	 COMP_STATUS,FATAL	   ;MAKE SURE DRIVES WERE COMPATIBLE
   JE	 COMP_EXIT

   CALL  COMP_TARGET

   CMP	 COMP_STATUS,FATAL	   ;MAKE SURE TARGET AND SOURCE
   JE	 COMP_EXIT		   ;DISKETTES ARE COMPATIBLE

   JMP	 COMP_TEST_END

COMP_END:
   CMP	 COMP_ERROR,0		   ;IF ERROR IN COMP
;  $IF	 E			   ;WARN USER
   JNE $$IF17
       PRINT MSGNUM_COMP_OK	   ;"Compare OK"				;AC000;

;kiser note: this is a warning????

;  $ENDIF
$$IF17:

COMP_EXIT:
   CMP	 COMP_STATUS,FATAL	   ;WAS COMP ABORTED ?
;  $IF	 E
   JNE $$IF19
				   ;"Compare process ended"
       PRINT MSGNUM_FATAL_ERROR    ;IF SO THEN TELL USER			;AC000;

;  $ENDIF
$$IF19:
   RET

COMP ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <DISPLAY_LOAD_FIRST - MOUNT FIRST DISKETTE> ; 			;AN000;
DISPLAY_LOAD_FIRST PROC NEAR	   ;						;AN000;
   PUBLIC DISPLAY_LOAD_FIRST	   ;						;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =

   MOV	 SUBLIST_78.SUB_VALUE,OFFSET ASCII_DRV1_ID ;PASS CHAR DRIVE ID		;AN000;
				   ;"Insert FIRST diskette in drive %1:"
   PRINT MSGNUM_LOAD_FIRST	   ;OUTPUT LOAD FIRST DISKETTE MESSAGE		;AC000;

   MOV	 MSG_FLAG,SECOND
   RET				   ;RETURN TO CALLER				;AN000;
DISPLAY_LOAD_FIRST ENDP 	   ;						;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <DISPLAY_SECOND  - MOUNT FIRST DISKETTE> ;				;AN000;
DISPLAY_LOAD_SECOND PROC NEAR	   ;						;AN000;
   PUBLIC DISPLAY_LOAD_SECOND	   ;						;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =

   MOV	 SUBLIST_78.SUB_VALUE,OFFSET ASCII_DRV2_ID ;PASS CHAR DRIVE ID		;AN000;
				   ;CR,LF,"Insert SECOND diskette in drive %1:",CR,LF
   PRINT MSGNUM_LOAD_SECOND	   ;OUTPUT LOAD SECOND DISKETTE MESSAGE 	;AC000;

   MOV	 MSG_FLAG,FIRST
   RET				   ;RETURN TO CALLER				;AN000;
DISPLAY_LOAD_SECOND ENDP	   ;						;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <TEST_REPEAT - PROMPT FOR ANOTHER COMPARE> ;				;AN000;
;*****************************************************************************
;									     *
   PUBLIC TEST_REPEAT		   ;MAKE ENTRY IN LINK MAP			;AN000;
TEST_REPEAT PROC NEAR		   ;TEST IF USER WANTS TO COMP ANOTHER	     *
;				 DISKETTE				     *
; INPUT : USER_INPUT ("Y" OR "N")
; OUTPUT: NC = COMP AGAIN						     *
;	  CY = EXIT TO DOS						     *
;*****************************************************************************
;  $SEARCH			   ;REPEAT THIS PROMPT UNTIL (Y/N) RESPONDED	;AC000;
$$DO21:
				   ;"Compare another diskette (Y/N)?"
       PRINT MSGNUM_COMP_ANOTHER   ;SEE IF USER WANTS TO COMPARE ANOTHER	;AC000;
				   ; AND READ RESPONSE TO AL
       PUSH  AX 		   ;SAVE THE RESPONSE				;AN000;
       PRINT MSGNUM_NEWLINE	   ;CR,LF,LF					;AC000;

       POP   DX 		   ;RESTORE THE REPONSE CHAR TO DL		;AN000;
       CALL  YESNO		   ;CHECK FOR (Y/N)				;AN000;

;  $EXITIF C,NUL		   ;QUIT IF OK ANSWER				;AN000;
   JC $$SR21
       CMP   AL,BAD_YESNO	   ;WAS THE RESPONSE INVALID?			;AN000;
;  $ENDLOOP B			   ;QUIT IF OK ANSWER (AX=0 OR 1)		;AN000;
   JNB $$DO21
       CMP   AL,YES		   ;WAS "YES" SPECIFIED 			;AN000;
;      $IF   E			   ;IF "YES"					;AN000;
       JNE $$IF24
	   MOV	 FIRST_TIME,ZERO   ;SET UP TO DO ANOTHER VOLSER CHECK		;AN000;
	   CLC			   ;CLEAR CARRY TO INDICATE COMPARE AGAIN	;AN000;
;      $ELSE			   ;SINCE NOT "YES"				;AN000;
       JMP SHORT $$EN24
$$IF24:
	   STC			   ;SET CARRY TO INDICATE NO REPEAT		;AN000;
;      $ENDIF			   ;						;AN000;
$$EN24:
;  $ENDSRCH			   ;						;AN000;
$$SR21:
   RET

TEST_REPEAT ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <READ_SOURCE - FILL AVAIL MEM WITH FIRST DISKETTE> ;			;AN000;
;*****************************************************************************
;									     *
   PUBLIC READ_SOURCE		   ;MAKE ENTRY IN LINK MAP			;AN000;
READ_SOURCE PROC NEAR		   ;FILL ALL AVAILABLE MOMORY WITH SOURCE DATA
;									     *
;*****************************************************************************

   CMP	 TRACK_TO_READ,0	   ;1ST TRACK ?
;  $IF	 E			   ;IF SO
   JNE $$IF28
       CMP   COPY_TYPE,1	   ;IF SINGLE DRIVE COMP
;      $IF   E			   ;PROMPT MSG
       JNE $$IF29
	   CALL  DISPLAY_LOAD_FIRST ;"Insert FIRST diskette in drive %1:"	;AN000;

	   CALL  PRESS_ANY_KEY	   ;"Press any key to continue . . ."		;AC000;

;      $ENDIF
$$IF29:
       CALL  CHECK_SOURCE	   ;DO NECESSARY CHECKING

       CALL  CALC_TRACK_SIZE

       CALL  CHECK_MEMORY_SIZE

       CMP   COMP_STATUS,FATAL
       JE    RS_EXIT

;  $ENDIF
$$IF28:
   MOV	 BX,BUFFER_BEGIN
   MOV	 BUFFER_PTR,BX		   ;INITIALIZE BUFFER POINTER

;  $DO
$$DO32:
       MOV   AL,TRACK_TO_READ	   ;DID WE FINISH READING ALL TRACKS?
       CMP   AL,LAST_TRACK
;  $LEAVE A
   JA $$EN32

       MOV   AX,BUFFER_PTR	   ;DID WE RUN OUT OF BUFFER SPACE
       ADD   AX,TRACK_SIZE
       CMP   AX,BUFFER_END
;  $LEAVE A
   JA $$EN32

       CALL  READ_TRACK 	   ;NO, GO READ ANOTHER TRACK

       INC   TRACK_TO_READ
;  $ENDDO
   JMP SHORT $$DO32
$$EN32:

RS_EXIT:
   RET

READ_SOURCE ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <CHECK_SOURCE - DETERMINE FIRST DISKETTE TYPE> ;			;AN000;
;*****************************************************************************
;									     *
   PUBLIC CHECK_SOURCE		   ;MAKE ENTRY IN LINK MAP			;AN000;
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

CS_AGAIN:
   XOR	 BX, BX
   MOV	 BL, SOURCE_DRIVE
   MOV	 MS_specialFunctions, GET_SP_FUNC_MED ;=00000001b
   MOV	 CL, GETDEVPARM 	   ;=60h
   MOV	 DX, OFFSET MS_IOCTL_DRV_PARM
   CALL  GENERIC_IOCTL		   ;TRY TO GET MEDIA BPB INFO TOGETHER
				   ;WITH DEFAULT DEVICE INFO.
   CMP	 IO_ERROR, SOFT_ERROR	   ;TRY AGAIN?
   JE	 CS_AGAIN

   CMP	 IO_ERROR, HARD_ERROR	   ;CANNOT GET MEDIA BPB?
   JNE	 CS_NEW 		   ;						;AC000;
CS_OLD_BRIDGE:
   JMP	 CS_OLD 		   ;ASSUME OLD FORMATTED DISKETTE, FIRST.	;AC000;
CS_NEW: 			   ;						;AN000;
   cmp	 ms_deviceBPB.csect_track,0 ;patch 1/16/86 J.K.
   je	 cs_old_BRIDGE

   cmp	 ms_deviceBPB.chead,0	   ;cannot trust the info. from DOS.
   je	 cs_old 		   ;sanity check for devide by 0.

   MOV	 AX, MS_deviceBPB.CTOTSECT
   CWD				   ;CONVERT IT TO A DOUBLE WORD
   DIV	 MS_deviceBPB.CSECT_TRACK
   DIV	 MS_deviceBPB.CHEAD	   ;(TOTAL SECTORS / # OF TRACKS) / # OF HEADS
   CMP	 AL, T_DRV_TRACKS	   ;IF # OF TRACKS FOR SOURCE MEDIA > # OF
				   ; TRACKS FOR TARGET DEVICE
   JA	 CS_FATAL		   ;THEN, NOT COMPATIBLE

   DEC	 AX			   ;DECREASE BY 1 FOR THIS PROGRAM'S USE.
   MOV	 LAST_TRACK, AL 	   ;SET LAST_TRACK
   MOV	 AX, MS_deviceBPB.CSECT_TRACK
   MOV	 SECT_TRACK_LAYOUT, AX	   ;VARIABLE FOR MS, MT_trackLayout.CSECT_F
   CMP	 USER_OPTION_8, ON	   ;/8 OPTION SPECIFIED?
   JNE	 CS_GO_ON

   CMP	 AX, 8			   ;SOURCE MEDIA # OF SECTORS/TRACK < 8 ?
   JB	 CS_FATAL		   ;IF IT IS, THEN FATAL ERROR.

   MOV	 AX, 8			   ;ELSE SET IT TO 8
CS_GO_ON:
   CMP	 AL, T_DRV_SECT_TRACK
   JA	 CS_FATAL

   MOV	 END_OF_TRACK, AL	   ;SET END_OF_TRACK
   MOV	 AX, MS_deviceBPB.CBYTE_SECT
   MOV	 bSECTOR_SIZE, AX	   ;set the sector size in bytes.
   CMP	 USER_OPTION, 1
   JE	 CS_OPTION_1

   MOV	 AX, MS_deviceBPB.CHEAD    ;HEAD=1, 2
   CMP	 AL, T_DRV_HEADS	   ;COMPARE SOURCE MEDIA SIDE WITH TARGET
				   ; DRIVE HEAD NUMBER
   JA	 CS_FATAL		   ;SOURCE MEDIUM IS DOUBLE SIDED AND
				   ; TARGET DRIVE IS SINGLE SIDED.

   DEC	 AX
   MOV	 NO_OF_SIDES, AL	   ;NO_OF_SIDES=0, 1
   JMP	 CS_SET_TABLE

CS_FATAL:
   MOV	 COMP_STATUS, FATAL
				   ;"Drive types or diskette types"
				   ;"not compatible"
   PRINT MSGNUM_NOT_COMPATIBLE	   ;						;AC000;

   JMP	 CS_EXIT

CS_BAD:
   MOV	 COMP_STATUS, FATAL
   PRINT MSGNUM_BAD_FIRST	   ;"FIRST diskette bad or incompatible"	;AC000;

   JMP	 CS_EXIT

CS_OLD:

   MOV	 READ_S_BPB_FAILURE, 1	   ;SET FLAG
   MOV	 bSECTOR_SIZE, 512	   ;OLD SECTOR SIZE MUST BE 512 BYTES
   XOR	 BX, BX
   MOV	 BL, SOURCE_DRIVE
   MOV	 IOCTL_TRACK, 0 	   ;TRACK=0
   MOV	 IOCTL_SECTOR, 8	   ;SECTOR=8
   MOV	 IOCTL_HEAD, 0		   ;HEAD = 0
   CALL  READ_A_SECTOR

   JC	 CS_BAD 		   ;SOURCE BAD

   MOV	 IOCTL_SECTOR, 9	   ;TRY TO READ SECTOR=9
   CALL  READ_A_SECTOR

   JC	 CS_SECT8		   ;YES, 8 SECTORS. ASSUME 40 TRACKS

   MOV	 IOCTL_SECTOR, 15	   ;try to read sector=15
   CALL  READ_A_SECTOR

   JC	 CS_SECT9		   ;**REMEMBER THIS ROUTINE DOES NOT COVER 3.5" MEDIA

   JMP	 CS_SECT15

CS_OPTION_1:
   MOV	 NO_OF_SIDES, 0 	   ;1 SIDE COPY
   JMP	 CS_SET_TABLE

CS_SECT15:
   MOV	 SECT_TRACK_LAYOUT, 15	   ;VARIABLE FOR MS, MT_trackLayout.CSECT_F
   MOV	 END_OF_TRACK, 15	   ;ELSE END_OF_TRACK = 15
   MOV	 LAST_TRACK, 79
   JMP	 CS_OPTIONS

CS_SECT8:
   MOV	 SECT_TRACK_LAYOUT, 8	   ;VARIABLE FOR MS, MT_trackLayout.CSECT_F
   MOV	 END_OF_TRACK, 8	   ;SOURCE 8 SECTORS
   MOV	 LAST_TRACK,  39	   ;ASSUME 40 TRACKS.
   JMP	 CS_OPTIONS

CS_SECT9:
   MOV	 SECT_TRACK_LAYOUT, 9	   ;VARIABLE FOR MS, MT_trackLayout.CSECT_F
   MOV	 END_OF_TRACK, 9
   MOV	 LAST_TRACK, 39 	   ;ASSUME 5.25 DISKETTE
CS_OPTIONS:
   CMP	 USER_OPTION_8, ON
   JNE	 CS_CHK_SIDE

   MOV	 END_OF_TRACK, 8
CS_CHK_SIDE:
   CMP	 USER_OPTION, 1
   JE	 CS_OPTION_1

   MOV	 IOCTL_HEAD, 1		   ;HEAD 1
   XOR	 AX, AX
   MOV	 AL, END_OF_TRACK	   ;READ MATCHING END_OF_TRACK
				   ; OF THE OTHER SURFACE.
   MOV	 IOCTL_SECTOR, AX
   CALL  READ_A_SECTOR

   JC	 CS_OPTION_1		   ;1 SIDED SOURCE

   MOV	 NO_OF_SIDES, 1 	   ;2 SIDED SOURCE
   CMP	 T_DRV_HEADS, 2 	   ;SOUCE=2 SIDED MEDIUM. IS TARGET
				   ; DOUBLE SIDED DRV?
   JE	 CS_SET_TABLE

   JMP	 CS_FATAL		   ;NOT COMPATIBLE

CS_SET_TABLE:
   CMP	 READ_S_BPB_FAILURE, 1	   ;diskette without BPB info?
   JNE	 CS_SET_TABLE_NEXT

   CALL  SET_FOR_THE_OLD	   ;set deviceBPB info for before 2.0 level

CS_SET_TABLE_NEXT:
   MOV	 BX, OFFSET MS_trackLayout ;SET TRACKLAYOUT OF SOURCE
   CALL  SET_TRACKLAYOUT

   MOV	 S_DRV_SET_FLAG, 1	   ;indicate SOURCE DRIVE
				   ; PARAMETER HAS BEEN SET
   XOR	 BX, BX
   MOV	 BL, SOURCE_DRIVE
   MOV	 DX, OFFSET MS_IOCTL_DRV_PARM
   MOV	 MS_specialFunctions, SET_SP_FUNC_DEF
   CALL  SET_DRV_PARM_DEF	   ;set device parameter for read

   XOR	 AX, AX
   MOV	 AL, END_OF_TRACK
   MOV	 numberOfSectors, AX	   ;SET NUMBEROFSECTORS IN IOCTL_R_W TABLE

   MOV	 AL, LAST_TRACK 	   ;NOW, SHOW THE MESSAGE "COMPARING ..."
   INC	 AL
   MOV	 BYTE PTR MSG_TRACKS,AL    ;HOW MANY TRACKS?				;AC000;

   MOV	 AL, END_OF_TRACK
   MOV	 BYTE PTR MSG_SECTRK,AL    ;HOW MANY SECTORS?				;AC000;

   MOV	 AL, NO_OF_SIDES	   ;TELL USER HOW MANY SIDE TO COPY
   INC	 AL
   MOV	 BYTE PTR MSG_SIDES,AL	   ;						;AC000;
				   ;CR,LF,"Comparing %1 tracks",CR,LF
				   ;"%2 Sectors/Track, %3 Side(s)",CR,LF
   PRINT MSGNUM_COMPARING	   ;						;AC000;

CS_EXIT:
   RET

CHECK_SOURCE ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <READ_A_SECTOR - USE IOCTL READ TO GET A SECTOR> ;			;AN000;
;*****************************************************************************
   PUBLIC READ_A_SECTOR 	   ;MAKE ENTRY IN LINK MAP			;AN000;
READ_A_SECTOR PROC NEAR
;
;TRY TO READ A SECTOR USING IOCTL READ FUNCTION CALL.
;THIS ROUTINE WILL STEAL "IOCTL_R_W" TABLE TEMPORARILY.
;INPUT: BX - LOGICAL DRIVE NUMBER
;	IOCTL_SECTOR - SECTOR TO READ
;	IOCTL_TRACK - TRACK
;	IOCTL_HEAD - HEAD TO READ
;	bSECTOR_SIZE - SECTOR SIZE IN BYTES
;OUTPUT:
;	IF NOT A SUCCESS, CARRY WILL BE SET
;	ALL REGISTORS SAVED
;*****************************************************************************
   PUSH  AX
   PUSH  BX
   PUSH  CX
   PUSH  DX

   MOV	 AX, numberOfSectors	   ;SAVE IOCTL_R_W TABLE VALUES
   MOV	 SAV_CSECT, AX

;  $DO
$$DO36:
       MOV   AX, IOCTL_HEAD
       MOV   Head, AX		   ;SURFACE TO READ
       MOV   AX, IOCTL_TRACK
       MOV   Cylinder, AX	   ;TRACK TO READ
       MOV   AX, IOCTL_SECTOR
       dec   ax 		   ;????? currently firstsector=0 =>
				   ; 1st sector ????
       MOV   FirstSectors, AX	   ;SECTOR TO READ
       MOV   numberOfSectors, 1    ;read just one sector
       MOV   AX, offset INIT	   ;READ IT INTO INIT (CURRELTLY, MAX 1K)
       MOV   TAddress_off, AX
       MOV   TAddress_seg, DS
       MOV   CL, READ_FUNC
       MOV   DX, OFFSET IOCTL_R_W  ;POINTS TO CONTROL TABLE
       call  generic_ioctl

       CMP   IO_ERROR, SOFT_ERROR  ;TRY ONCE MORE?
;  $ENDDO NE
   JE $$DO36

   CMP	 IO_ERROR, HARD_ERROR	   ;HARD ERROR?
;  $IF	 NE
   JE $$IF38

       CLC			   ;READ SUCCESS
;  $ELSE
   JMP SHORT $$EN38
$$IF38:

       STC			   ;READ FAILURE, SET CARRY
;  $ENDIF
$$EN38:
   MOV	 AX, SAV_CSECT		   ;RESTORE ORIGINAL IOCTL_R_W TABLE
   MOV	 numberOfSectors, AX
   POP	 DX
   POP	 CX
   POP	 BX
   POP	 AX
   RET
READ_A_SECTOR ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <CALC_TRACK_SIZE - FIND MEM SIZE TO HOLD ONE TRACK> ; 		;AN000;
;*****************************************************************************
;									     *
   PUBLIC CALC_TRACK_SIZE	   ;MAKE ENTRY IN LINK MAP			;AN000;
CALC_TRACK_SIZE PROC NEAR	   ;CALCULATE MEMORY SIZE REQUIRED TO STORE ONE
;				   TRACK (IN SEGMENTS)			     *
;CALCULATE SECTOR_SIZE IN PARA FROM bSECTOR_SIZE.  IF bSECTOR_SIZE CANNOT BE
;CHANGED TO SECTOR_SIZE IN PARA EXACTLY, THEN ADD 1 TO THE SECTOR_SIZE.
;SECTOR_SIZE IS USED FOR MEMORY MANAGEMANT ONLY.  THE ACTUAL COPY OR FORMAT
;SHOULD BE DEPENDS ON bSECTOR_SIZE TO FIGURE OUT HOW BIG A SECTOR IS.
;ALSO, CURRENTLY, THIS ROUTINE ASSUME A BSECTOR SIZE BE LESS THAN 0FFFh.
;*****************************************************************************

   PUSH  AX
   PUSH  BX
   PUSH  CX

   MOV	 AX, bSECTOR_SIZE
   XOR	 DX, DX
   XOR	 BX, BX
   MOV	 BL, END_OF_TRACK
   MUL	 BX			   ;ASSUME DX=0
   MOV	 BYTES_IN_TRACK,AX	   ;BYTES/TRACK ON A SIDE OF THE DISKETTE

   MOV	 AX, bSECTOR_SIZE
   MOV	 CL, 16
   DIV	 CL			   ;AX / 16 = AL ... AH
   CMP	 AH, 0			   ;NO REMAINER?
;  $IF	 NE
   JE $$IF41

       INC   AL 		   ;THERE REMAINER IS.	INC AL
;  $ENDIF
$$IF41:
   MOV	 SECTOR_SIZE, AL	   ;SECTOR_SIZE+ IN PARA.
   MOV	 AL,NO_OF_SIDES 	   ;TRACK_SIZE = (NO OF SIDES
   INC	 AL			   ;		  + 1)
   MUL	 END_OF_TRACK		   ;		  * END_OF_TRACK
   MOV	 BL,SECTOR_SIZE 	   ;		  * SECTPR_SIZE
   MUL	 BL			   ;AMOUNT OF MEMORY REQUIRED (IN SEG)
   MOV	 TRACK_SIZE,AX		   ;TO STORE A TRACK

   MOV	 BX,START_BUFFER	   ;SET SECONDARY AT START OF BUFFER SPACE
   MOV	 SEC_BUFFER,BX		   ;SET THE SECONDARY BUFFER SEG ADDR
   ADD	 BX,AX			   ;MOVE THE PRIMARY BUFFER BELOW THE
   MOV	 BUFFER_BEGIN,BX	   ;SECONDARY BUFFER
   POP	 CX
   POP	 BX
   POP	 AX

   RET

CALC_TRACK_SIZE ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <CHECK_MEMORY_SIZE - BE SURE ENUF ME TO COMPARE 1 TRACK> ;		;AN000;
;*****************************************************************************
;									     *
   PUBLIC CHECK_MEMORY_SIZE	   ;MAKE ENTRY IN LINK MAP			;AN000;
CHECK_MEMORY_SIZE PROC NEAR	   ;MAKE SURE WE HAVE ENOUGH TO COMP 1 TRACK INTO
;			      TO BUFFER ELSE ABORT COMP 		     *
;*****************************************************************************
   MOV	 AX,BUFFER_END
   SUB	 AX,BUFFER_BEGIN
   CMP	 AX,TRACK_SIZE
;  $IF	 B
   JNB $$IF43
       MOV   COMP_STATUS,FATAL
				   ;"Insufficient memory"
       PRINT MSGNUM_UNSUF_MEMORY   ;						;AC000;

;  $ENDIF
$$IF43:
   RET

CHECK_MEMORY_SIZE ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <COMP_TARGET - COMPARE MEM DATA WITH SECOND DISKETTE> ;		;AN000;
;*****************************************************************************
;									     *
   PUBLIC COMP_TARGET		   ;MAKE ENTRY IN LINK MAP			;AN000;
COMP_TARGET PROC NEAR		   ;COMPARE DATA FROM MEMORY TO TARGET DISKETTE
;									     *
;*****************************************************************************

   CMP	 COPY_TYPE,1		   ;IF SINGLE DRIVE COMP
;  $IF	 E			   ;PROMPT MSG
   JNE $$IF45
       CMP   MSG_FLAG,SECOND
;      $IF   E
       JNE $$IF46
	   CALL  DISPLAY_LOAD_SECOND ;"Insert SECOND diskette in drive %1:"	;AN000;

;      $ELSE
       JMP SHORT $$EN46
$$IF46:
	   CALL  DISPLAY_LOAD_FIRST ;"Insert FIRST diskette in drive %1:"	 ;AN000;

;      $ENDIF
$$EN46:
       CALL  PRESS_ANY_KEY	   ;"Press any key to continue . . ."		;AC009;

;  $ENDIF
$$IF45:
   MOV	 BX,BUFFER_BEGIN
   MOV	 COMPARE_PTR,BX 	   ;INITIALIZE BUFFER POINTER
   CMP	 TRACK_TO_COMP,0	   ;IF TRK 0, CHECK COMPATIBILITY
;  $IF	 E
   JNE $$IF50
       CALL  CHECK_TARGET

       CMP   COMP_STATUS,FATAL	   ;IF INCOMPATIBLE, THEN EXIT
       JE    CT_EXIT

;  $ENDIF
$$IF50:

   CALL  SWAP_DRIVE

;  $DO
$$DO52:
       CALL  COMP_TRACK 	   ;NO, GO READ ANOTHER TRACK

       INC   TRACK_TO_READ
       MOV   AL,TRACK_TO_READ	   ;DID WE FINISH READING ALL TRACKS?
       CMP   AL,LAST_TRACK
;  $LEAVE A
   JA $$EN52

       MOV   AX,COMPARE_PTR	   ;DID WE RUN OUT OF BUFFER SPACE
       ADD   AX,TRACK_SIZE
       CMP   AX,BUFFER_END
;  $ENDDO A
   JNA $$DO52
$$EN52:

CT_EXIT:
   RET
COMP_TARGET ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <CHECK_TARGET - COMPARE SECOND DISK BOOT RECORD> ;			;AN000;
;*****************************************************************************
   PUBLIC CHECK_TARGET		   ;MAKE ENTRY IN LINK MAP			;AN000;
CHECK_TARGET PROC NEAR		   ;					*
;   ** CHECK_SOURCE PROCEDURE ALREADY CHECKS OUT THE INCOMPATIBILITY BETWEEN *
;   ** SOURCE MEDIA AND TARGET DRIVE.  (CHECKING SOURCE MEDIA SECTOR/TRACK   *
;   ** EXCEEDS TARGET DRV SECTOR/TRACK, AND SOURCE MEDIA # OF TRACKS WITH    *
;   ** THAT OF TARGET DRV.)						     *
;   ** THIS ROUTINE WILL TRY TO READ TARGET MEDIA BOOT RECORD.		     *
;   ** IF A SUCCESS,THEN COMPARE BPB INFO WITH THAT OF SOURCE MEDIA.	     *
;   ** IF THEY ARE DIFFERENT, THEN ERROR - NOT COMPATIBLE		     *
;   ** IF FAILED TO READ A BOOT, THEN TRY OLD LOGICS BEFORE DOS 3.2 FOR      *
;   ** COMPATIBILITY REASONS.						     *
;*****************************************************************************
;  $DO
$$DO55:
       XOR   BX, BX
       MOV   BL, TARGET_DRIVE
       MOV   MT_specialFunctions, GET_SP_FUNC_MED ;=00000001b
       MOV   CL, GETDEVPARM
       MOV   DX, OFFSET MT_IOCTL_DRV_PARM
       CALL  GENERIC_IOCTL	   ;TRY TO GET MEDIA BPB INFO TOGETHER
				   ;WITH THE DEFAULT DEVICE INFO.
       CMP   IO_ERROR, SOFT_ERROR  ;TRY AGAIN?
;  $ENDDO NE
   JE $$DO55

   CMP	 IO_ERROR, HARD_ERROR	   ;ASSUME OLD DISKTETTE. OR DISKETTE BAD
   JE	 CHT_OLD

   cmp	 mt_deviceBPB.csect_track,0 ;patch 1/16/86, J.K.
   je	 cht_old

   cmp	 mt_deviceBPB.chead,0	   ;cannot trust the info from DOS.
   je	 cht_old		   ;sanity check for devide by 0

   MOV	 AX, MT_deviceBPB.CTOTSECT
   CWD				   ;CONVERT IT TO A DOUBLE WORD
   DIV	 MT_deviceBPB.CSECT_TRACK
   DIV	 MT_deviceBPB.CHEAD	   ;(TOTAL SECTORS / # OF TRACKS) / # OF HEADS
   DEC	 AX			   ;DECREASE BY 1 FOR THIS PROGRAM
   CMP	 LAST_TRACK, AL 	   ;COMPARE WITH SOURCE LAST TRACK
   JNE	 CHT_FATAL_BRIDGE	   ;IF LAST_TRACK IS DIFFERENT,
				   ; THEN INCOMPATIBLE.

   MOV	 AX, MT_deviceBPB.CSECT_TRACK
   MOV	 SECT_TRACK_LAYOUT, AX	   ;VARIBLE FOR MT_trackLayout.CSECT_F
CHT_GO_ON:
   CMP	 END_OF_TRACK, AL
   JA	 CHT_FATAL_BRIDGE	   ;IF SOURCE END_OF_TRACK > TARGET
				   ; END_OF_TRACK, THEN ERROR

				   ;8 SECTORED SOURCE AND 9 SECTORED TARGET
				   ; IS OK AS FAR AS THE COMPATIBILITY GOES.
   MOV	 AX, MT_deviceBPB.CBYTE_SECT
   CMP	 AX, bSECTOR_SIZE	   ;IF SECTOR SIZE ARE DIFFERENT, THEN
				   ; NOT COMPATIBLE
   JNE	 CHT_FATAL_BRIDGE

   CMP	 NO_OF_SIDES, 1 	   ;TWO SIDED COPY?
   JNE	 CHT_SET_BRIDGE 	   ;NO, ONE SIDED. DON'T
				   ; CARE ABOUT TARGET SIDES.

   CMP	 MT_deviceBPB.CHEAD, 2	   ;TARGET FORMATTED INTO TWO SIDES?
   JNE	 CHT_FATAL_BRIDGE	   ;NO, NOT COMPATIBLE

   JMP	 CHT_SET_DRV		   ;OK. SOURCE, TARGET MEDIA ARE MATCHING. SET
				   ; DRV PARM FOR READING

CHT_SET_BRIDGE:
   JMP	 CHT_SET_DRV

CHT_FATAL_BRIDGE:
   JMP	 CHT_FATAL

CHT_SECOND_BAD:
   MOV	 COMP_STATUS, FATAL
   PRINT MSGNUM_BAD_SECOND	   ;"SECOND diskette bad or incompatible"	 ;AC000;

   JMP	 CHT_EXIT

CHT_OLD:			   ;SAME OLD. ;AGAIN, THIS DOES
				   ; NOT RECOGNIZE 3.5 MEDIA
   MOV	 READ_T_BPB_FAILURE, 1	   ;SET THE FLAG.
   XOR	 BX, BX
   MOV	 BL, TARGET_DRIVE
   MOV	 IOCTL_TRACK, 0
   MOV	 IOCTL_SECTOR, 8
   MOV	 IOCTL_HEAD, 0		   ;TRY TO READ HEAD 0, TRACK 0, SECTOR 8
   CALL  READ_A_SECTOR

   JC	 CHT_SECOND_BAD 	   ;ASSUME TARGET MEDIA NOT FORMATTED.

   MOV	 IOCTL_SECTOR, 9	   ;TRY TO READ SECTOR 9
   CALL  READ_A_SECTOR

   JC	 CHT_8_SECTOR		   ;TARGET IS 8 SECTOR MEDIA

   MOV	 IOCTL_SECTOR, 15
   CALL  READ_A_SECTOR

   JC	 CHT_9_SECTOR		   ;TARGET IS 9 SECTOR MEDIA

;CHT_15_SECTOR: 			 ;TARGET IS 15 SECTOR MEDIA
   MOV	 SECT_TRACK_LAYOUT, 15
   CMP	 END_OF_TRACK, 15	   ;IS SOUCE ALSO 96 TPI?
   JNE	 CHT_FATAL		   ;NO, FATAL ERROR

   JMP	 SHORT CHT_CHK_SIDE	   ;YES, OK.

CHT_8_SECTOR:
   MOV	 SECT_TRACK_LAYOUT, 8
   CMP	 END_OF_TRACK, 15
   JE	 CHT_FATAL		   ;IF SOURCE IS 96 TPI, THEN FATAL ERROR

   CMP	 END_OF_TRACK, 9
   JE	 CHT_FATAL		   ;IF SOURCE IS 9 SECTOR, THEN
				   ; SHOULD FORMAT TARGET

   JMP	 SHORT CHT_CHK_SIDE	   ;ELSE ASSUME SOURCE IS 8 SECTOR.

CHT_9_SECTOR:
   MOV	 SECT_TRACK_LAYOUT, 9
   CMP	 END_OF_TRACK, 15	   ;IS SOURCE 96 TPI? THEN ERROR
   JE	 CHT_FATAL		   ;ELSE SOUCE IS 8 OR 9 SECTORED
				   ; 48 TPI DISKETTE

CHT_CHK_SIDE:			   ;CHECK THE TARGET DISKETTE # OF SIDES
   CMP	 NO_OF_SIDES, 0 	   ;1 SIDE COMP?
   JE	 CHT_EXIT_OLD		   ;

   MOV	 IOCTL_HEAD, 1		   ;ELSE TWO SIDE COMP
   XOR	 AX, AX
   MOV	 AL, END_OF_TRACK	   ;TRY TO READ MATCHING TARGET SECTOR
   MOV	 IOCTL_SECTOR, AX	   ;OF THE OTHERSIDE
   CALL  READ_A_SECTOR

   JNC	 CHT_EXIT_OLD		   ;SUCCESS? OK

CHT_FATAL:
   CALL  COMPAT_ERROR

   JMP	 SHORT	 CHT_EXIT

CHT_EXIT_OLD:
   CALL  SET_FOR_THE_OLD	   ;SET MT_deviceBPB INFO.

CHT_SET_DRV:
   MOV	 BX, OFFSET MT_trackLayout ;SET TARGET TRACK LAYOUT
   CALL  SET_TRACKLAYOUT

   JC	 CHT_FATAL		   ;IF FAILED, THEN, NOT COMPATIBLE

   MOV	 T_DRV_SET_FLAG, 1	   ;INDICATES THE TARGET DEFAULT
				   ; DEVICE PARM HAS BEEN SET
   XOR	 BX, BX
   mov	 bl, last_track 	   ;To make sure the number of
				   ; cyl. of target. 3/27/86,J.K.
   inc	 bl
   mov	 MT_numberOfCylinders, bx
   MOV	 BL, TARGET_DRIVE
   MOV	 DX, OFFSET MT_IOCTL_DRV_PARM
   MOV	 MT_specialFunctions, SET_SP_FUNC_DEF
   CALL  SET_DRV_PARM_DEF

CHT_EXIT:
   RET

CHECK_TARGET ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <SET_DRV_PARM - REQUEST IOCTL TO SET DEVICE PARM> ;			;AN000;
;*****************************************************************************
   PUBLIC SET_DRV_PARM_DEF	   ;MAKE ENTRY IN LINK MAP			;AN000;
SET_DRV_PARM_DEF PROC NEAR
;INPUT: BL - DRIVE NUMBER
;	DX - POINTER TO THE PARAMETER TABLE
;	specialFunction should be set before this call
;*****************************************************************************

   MOV	 CL, SETDEVPARM 	   ;=40H
   CALL  GENERIC_IOCTL

   RET

SET_DRV_PARM_DEF ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <COMP_TRACK - READ AND COMPARE SPECIFIED TRACK> ;			;AN000;
;*****************************************************************************
;									     *
   PUBLIC COMP_TRACK		   ;MAKE ENTRY IN LINK MAP			;AN000;
COMP_TRACK PROC NEAR		   ;COMPARE TRACK SPECIFIED IN TRACK_TO_COMP
;									     *
;*****************************************************************************
   MOV	 AX,SEC_BUFFER		   ;READ IN THE TRACK TO BE COMPARED
   MOV	 BUFFER_PTR,AX		   ;INTO THE SECONDARY BUFFER
   CALL  READ_TRACK

   MOV	 SIDE,0 		   ;START ON SIDE ZERO
   MOV	 CX,BYTES_IN_TRACK	   ;GET NUMBER TO COMPARE
   PUSH  DS
   PUSH  ES
   MOV	 ES,COMPARE_PTR 	   ;SET DESTINATION SEG ADDR
   MOV	 DS,SEC_BUFFER		   ;SET SOURCE SEG ADDR

   ASSUME ES:NOTHING
   ASSUME DS:NOTHING

   XOR	 DI,DI			   ;SET TO START OF TRACK
   XOR	 SI,SI
   CMP	 FIRST_TIME,ZERO	   ;IF THIS IS THE FIRST SECTOR TO BE COMPARED	;AN000;
;  $IF	 E			   ;						;AN000;
   JNE $$IF57
       CALL  VOLSER		   ;SPECIAL HANDLING FOR VOL SER #		;AN000;

       MOV   FIRST_TIME,ONE	   ;FLAG FIRST TIME AS "DONE"			;AN000;
;  $ENDIF			   ;						;AN000;
$$IF57:
   CALL  DO_COMPARE		   ;COMPARE STRING				;AN000;

   POP	 ES
   POP	 DS

   ASSUME ES:CSEG
   ASSUME DS:CSEG

;  $IF	 NZ
   JZ $$IF59
       PUSH  AX 		   ;SAVE AX SINCE ERROR_MESSAGE WILL DESTROY IT
       MOV   OPERATION,COMPARE_FUNC
       CALL  ERROR_MESSAGE

       INC   COMP_ERROR
       POP   AX
;  $ENDIF
$$IF59:
   CMP	 NO_OF_SIDES,1		   ;TWO SIDED COMPARE?
;  $IF	 E			   ;YES
   JNE $$IF61
       MOV   SIDE,1		   ;MARK IT AS SUCH
       MOV   SI,BYTES_IN_TRACK	   ;BUMP UP BUFFER POINTERS
       MOV   DI,BYTES_IN_TRACK	   ;TO START OF SECOND SIDE
       MOV   CX,BYTES_IN_TRACK	   ;GET NUMBER TO COMPARE
       PUSH  DS
       PUSH  ES
       MOV   ES,COMPARE_PTR	   ;SET DESTINATION SEG ADDR
       MOV   DS,SEC_BUFFER	   ;SET SOURCE SEG ADDR
       CALL  DO_COMPARE 	   ;COMPARE STRING				;AN000;

       POP   ES
       POP   DS
;      $IF   NZ
       JZ $$IF62
	   PUSH  AX		   ;SAVE AX SINCE ERROR_MESSAGE WILL DESTROY IT
	   MOV	 OPERATION,COMPARE_FUNC
	   CALL  ERROR_MESSAGE

	   INC	 COMP_ERROR
	   POP	 AX
;      $ENDIF
$$IF62:
;  $ENDIF
$$IF61:
   MOV	 AX,TRACK_SIZE		   ;ADVANCE COMPARE POINTER
   ADD	 COMPARE_PTR,AX
   RET
COMP_TRACK ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <DO_COMPARE - PERFORM THE COMPARISON> ;				;AN000;
DO_COMPARE PROC NEAR		   ;						;AN000;
   PUBLIC DO_COMPARE		   ;ADD ENTRY TO LINK MAP			;AN000;
;INPUT: DS:[SI] POINTS TO ONE BUFFER, ES:[DI] POINTS TO THE OTHER
;	CX HAS THE BYTE COUNT
;OUTPUT:CONDITION CODE IN CONDITION FLAGS REFLECT RESULT OF COMPARISON
;  =  =  =  =  =  =  =	=  =  =  =  =
   SHR	 CX,1			   ;DIVIDE BY TWO, CHANGE TO WORD COUNT 	;AN000;

   PUBLIC PATCH_386		   ;SO INIT CAN DO FIXUP			;AN001;
PATCH_386 LABEL BYTE
   SHR	 CX,1			   ;CONVERT WORD COUNT TO DWORD COUNT		;AN001;
   DB	 66H			   ;PREFIX FOR A DWORD COMPARE			;AN001;
; END OF PATCH AREA.  IF THIS IS NOT A 386, THE ABOVE 3 BYTES ARE CHANGED
; TO NOP BY DISKINIT.SAL DURING INITIALIZATION.

   REPE  CMPSW			   ;PERFORM THE COMPARISON			;AN000;

   RET				   ;RETURN TO CALLER				;AN000;
DO_COMPARE ENDP 		   ;						;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <SWAP_DRIVE - SETUP FOR DISKETTE SWAPPING> ;				;AN000;
;*****************************************************************************
   PUBLIC SWAP_DRIVE		   ;MAKE ENTRY IN LINK MAP			;AN000;
SWAP_DRIVE PROC NEAR		   ;SWAP SOURCE, TARGET DRIVE
;*****************************************************************************
   MOV	 AL,SOURCE_DRIVE
   XCHG  AL,TARGET_DRIVE
   MOV	 SOURCE_DRIVE,AL
   MOV	 AL,TRACK_TO_COMP
   XCHG  AL,TRACK_TO_READ
   MOV	 TRACK_TO_COMP,AL
   RET

SWAP_DRIVE ENDP
   HEADER <READ_TRACK - READ A TRACK TO MEMORY> ;				;AN000;
;*****************************************************************************
;									     *
   PUBLIC READ_TRACK		   ;MAKE ENTRY IN LINK MAP			;AN000;
READ_TRACK PROC NEAR		   ;READ A TRACK AND STORE IT INTO MEMORY
;									     *
;*****************************************************************************

   MOV	 SIDE, 0
;  $DO
$$DO65:
       CALL  READ_OP

       CMP   NO_OF_SIDES, 0	   ;SINGLE SIDE COPY?
;      $IF   E			   ;YES
       JNE $$IF66
	   MOV	 AX, TRACK_SIZE
;      $ELSE			   ;NO, DOUBLE SIDE
       JMP SHORT $$EN66
$$IF66:
	   XOR	 DX, DX
	   MOV	 AX, TRACK_SIZE
	   MOV	 CX, 2
	   DIV	 CX		   ;AX / 2
;      $ENDIF
$$EN66:
       ADD   BUFFER_PTR, AX
       INC   SIDE		   ;NEXT SIDE
       MOV   AL, SIDE
       CMP   AL, NO_OF_SIDES	   ;FINISHED WITH THE LAST SIDE?
;  $ENDDO G
   JNG $$DO65
   RET

READ_TRACK ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <READ_OP - IOCTL TO READ A TRACK> ;					;AN000;
;*****************************************************************************
;									     *
   PUBLIC READ_OP		   ;MAKE ENTRY IN LINK MAP			;AN000;
READ_OP PROC NEAR		   ;IOCTL READ A TRACK OPERATION
;									     *
;*****************************************************************************
;  $SEARCH
$$DO70:
RO_AGAIN:
       XOR   AX, AX
       MOV   AL, SIDE
       MOV   Head, AX		   ;HEAD TO READ
       MOV   AL, TRACK_TO_READ
       MOV   Cylinder, AX	   ;TRACK TO READ
       MOV   FirstSectors, 0	   ;???? SHOULD BE 1 BUT CURRENTLY 0 ???
       MOV   AX, BUFFER_PTR
       MOV   Taddress_seg, AX	   ;BUFFER ADDRESS
       MOV   Taddress_off, 0
       XOR   BX, BX
       MOV   BL, SOURCE_DRIVE
       MOV   CL, READ_FUNC	   ;=61h
       MOV   DX, OFFSET IOCTL_R_W
       CALL  GENERIC_IOCTL

       CMP   IO_ERROR, NO_ERROR    ;OK?
;  $EXITIF E,NUL
   JE $$SR70

       CMP   IO_ERROR, SOFT_ERROR  ;TRY AGAIN?
;  $ENDLOOP NE
   JE $$DO70

       MOV   OPERATION, READ_FUNC
       PUSH  AX
       CALL  ERROR_MESSAGE

       POP   AX
       INC   COMP_ERROR 	   ;INCREASE COPY_ERROR COUNT
;  $ENDSRCH
$$SR70:
   RET
READ_OP ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <SET_FOR_THE_OLD - USE PRE 2.0 BPB> ; 				;AN000;
;*****************************************************************************
   PUBLIC SET_FOR_THE_OLD	   ;MAKE ENTRY IN LINK MAP			;AN000;
SET_FOR_THE_OLD PROC NEAR
;set MS_deviceBPB or MT_deviceBPB for before-2.0 formatted media.
;*****************************************************************************
   PUSH  AX

   CMP	 SECT_TRACK_LAYOUT,9	   ;IF SECTORS/TRACK <= 9, THEN CHECK
				   ;NO_OF_SIDES. IF SINGLE SIDE COPY
				   ; THEN USE BPB48_SINGLE
				   ;ELSE USE BPB48_DOUBLE.
;  $IF	 A			   ;SECTORS/TRACK > 9 THEN USE BPB96 TABLE
   JNA $$IF74
       MOV   SI, OFFSET BPB96
;  $ELSE
   JMP SHORT $$EN74
$$IF74:
       CMP   NO_OF_SIDES, 0	   ;SINGLE SIDE COPY?
;      $IF   NE
       JE $$IF76
	   MOV	 SI, OFFSET BPB48_DOUBLE ;ELSE USE BPB48 DOUBLE
;      $ELSE
       JMP SHORT $$EN76
$$IF76:
	   MOV	 SI, OFFSET BPB48_SINGLE
;      $ENDIF
$$EN76:
;  $ENDIF
$$EN74:
   MOV	 AX, SECT_TRACK_LAYOUT
   CMP	 READ_S_BPB_FAILURE, 1	   ;FAILURE ON THE SOURCE?
;  $IF	 E
   JNE $$IF80
       MOV   MS_deviceBPB.CSECT_TRACK,AX ;SET # OF SECTORS IN IOCTL_DRV_PARM
       MOV   DI, OFFSET MS_deviceBPB
       MOV   CX, BPB96_LENG
       REP   MOVSB		   ;OLD DEFAULT BPB INFO => MS_deviceBPB
;  $ELSE
   JMP SHORT $$EN80
$$IF80:
       CMP   READ_T_BPB_FAILURE, 1 ;FAILURE ON THE TARGET?
;      $IF   E
       JNE $$IF82
	   MOV	 MT_deviceBPB.CSECT_TRACK,AX
	   MOV	 DI, OFFSET MT_deviceBPB
	   MOV	 CX, BPB96_LENG
	   REP	 MOVSB		   ;OLD DEFAULT BPB INTO => MT_deviceBPB
;      $ENDIF
$$IF82:
;  $ENDIF
$$EN80:
   POP	 AX
   RET
SET_FOR_THE_OLD ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <SET_TRACKLAYOUT - DETERMINE SECTORS PER TRACK> ;			;AN000;
;*****************************************************************************
   PUBLIC SET_TRACKLAYOUT	   ;MAKE ENTRY IN LINK MAP			;AN000;
SET_TRACKLAYOUT PROC NEAR
;INPUT: BX - POINTER TO DESTINATION
;	SECT_TRACK_LAYOUT
;*****************************************************************************
   MOV	 CX, SECT_TRACK_LAYOUT	   ;MEDIA SECTORS/TRACK
   MOV	 WORD PTR [BX], CX	   ;SET CSECT_F TO THE NUMBER OF SECTORS
				   ; IN A TRACK
   ADD	 BX, 2			   ;NOW BX POINTS TO THE FIRST SECTORNUMBER
   MOV	 CX, 1
   MOV	 AX, bSECTOR_SIZE

;  $DO
$$DO85:
       CMP   CX, SECT_TRACK_LAYOUT
;  $LEAVE A
   JA $$EN85

       MOV   WORD PTR [BX], CX
       INC   BX
       INC   BX
       MOV   WORD PTR [BX], AX
       INC   BX
       INC   BX

       INC   CX
;  $ENDDO
   JMP SHORT $$DO85
$$EN85:

   RET
SET_TRACKLAYOUT ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <GENERIC_IOCTL - PERFORM SPECIFIED IOCTL FUNCTION> ;			;AN000;
PUBLIC GENERIC_IOCTL
;******************************************************************************
GENERIC_IOCTL PROC NEAR
;INPUT: CL - MINOR CODE; 60 - GET DEVICE PARM, 40 - SET DEVICE PARM
;			 61 - READ TRACK, 41 - WRITE TRACK,
;			 42 - FORMAT AND VERIFY TRACK
;			 62 - VERIFY TRACK
;	BL - LOGICAL DRIVE LETTER
;	DS:DX - POINTER TO PARAMETERS
;******************************************************************************

   MOV	 IO_ERROR, NO_ERROR	   ;reset io_error
   MOV	 AH, IOCTL_FUNC 	   ;IOCTL FUNC = 44H
   MOV	 AL, GENERIC_IOCTL_CODE    ;GENERIC IOCTL REQUEST = 0DH
   MOV	 CH, MAJOR_CODE 	   ;MAJOR CODE=08H, REMOVABLE
   INT	 21H
;  $IF	 C
   JNC $$IF88
       CALL  EXTENDED_ERROR_HANDLER ;ERROR, SEE WHAT IT IS!

;  $ENDIF
$$IF88:
   RET
GENERIC_IOCTL ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <EXTENDED_ERROR - DETERMINE AND SERVICE EXTENDED ERRORS> ;		;AN000;
;******************************************************************************
   PUBLIC EXTENDED_ERROR_HANDLER   ;MAKE ENTRY IN LINK MAP			;AN000;
EXTENDED_ERROR_HANDLER PROC NEAR
;INPUT: BL - LOGICAL DRIVE LETTER
;******************************************************************************
   PUSHF
   PUSH  AX
   PUSH  BX
   PUSH  CX
   PUSH  DX
   PUSH  SI
   PUSH  DI
   PUSH  ES
   PUSH  DS
   PUSH  BX

   MOV	 AH, 59H
   MOV	 BX, 0
   INT	 21H

;	 CMP	 BL, 5			 ;ACTION=IMMEDIATE EXIT?
;	 JE	 EEH_JUST_EXIT

   POP	 BX			   ;RESTORE BL FOR DRIVE LETTER
   POP	 DS
   POP	 ES

   CMP	 AX, 21 		   ;DRIVE NOT READY?
   JE	 WARN_USER_1

   CMP	 AX, 19 		   ;ATTEMP TO WRITE ON WRITE_PROTECTED?
   JE	 WARN_USER_2

   JMP	 EEH_HARD_ERROR 	   ;OTHERWISE, HARD_ERROR

WARN_USER_1:
   MOV	 DRIVE_LETTER, 'A'
   DEC	 BL			   ;CHANGE LOGICAL TO PHYSICAL
   ADD	 DRIVE_LETTER, BL
				   ;"Drive not ready - X:"
   PRINT MSGNUM_GET_READY	   ;						;AC000;

   PRINT MSGNUM_CLOSE_DOOR	   ;"Make sure a diskette is inserted into      ;AN004;
				   ; the drive and the door is closed"
   JMP	 WAIT_FOR_USER

WARN_USER_2:
				   ;"Attempt to write to write-protected diskette"
   PRINT MSGNUM_WRITE_PROTECT	   ;						;AC000;

WAIT_FOR_USER:
   CALL  PRESS_ANY_KEY		   ;"Press any key to continue . . ."		;AC009;

EEH_SOFT_ERROR:
   MOV	 IO_ERROR, SOFT_ERROR	   ;INDICATE THE CALLER TO TRY AGAIN
   JMP	 SHORT EEH_EXIT

EEH_HARD_ERROR:
   MOV	 IO_ERROR, HARD_ERROR

EEH_EXIT:
   POP	 DI
   POP	 SI
   POP	 DX
   POP	 CX
   POP	 BX
   POP	 AX
   POPF
   RET

;EEH_JUST_EXIT:
;   JMP   EXIT_PROGRAM		    ;UNCONDITIONAL EXIT

EXTENDED_ERROR_HANDLER ENDP
.XLIST
;   HEADER <CALL_PRINTF - COMMON DRIVER TO PRINTF, DISPLAY MESSAGE>
;CALL_PRINTF PROC NEAR
;   PUBLIC CALL_PRINTF
;;INPUT - DX HAS OFFSET INTO DS OF MESSAGE PARM LIST
;   PUSH  DX
;   PUSH  CS
;   CALL  PRINTF
;
;   RET
;CALL_PRINTF ENDP
.LIST
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <ERROR_MESSAGE - DISPLAY THE ERROR MESSAGE> ; 			;AN000;
ERROR_MESSAGE PROC NEAR 	   ;DISPLAY ERROR MESSAGE
   PUBLIC ERROR_MESSAGE
;
;  FUNCTION: THIS SUBROUTINE DISPLAYS WHAT OPERATION FAILED (READ OR WRITE)
;	     AND WHERE IT FAILED (TRACK NO. AND SIDE).
;
;  INPUT: OPERATION = IOCTL DISKETTE READ(=61H) OR COMPARE_FUNC(59H)
;  =  =  =  =  =  =  =	=  =  =  =  =

   CMP	 OPERATION,READ_FUNC	   ;ERROR DURING READ ?
;  $IF	 E
   JNE $$IF90
.XLIST
;	     MOV     BX,OFFSET READ_ERROR ;TELL USER ERROR DURING READ OP
;	     MOV     MSG_HARD_ERROR_PTR+2,BX
.LIST
       MOV   DL,SOURCE_DRIVE	   ;WHICH DRIVE IS BAD
       dec   dl 		   ;change logical letter to phisical
       ADD   DL,"A"		   ;CORRESPONDANT ALPHABET
       MOV   DRIVE_LETTER,DL
       MOV   SUBLIST_17B.SUB_VALUE,OFFSET DRIVE_LETTER ;

       MOV   BL,TRACK_TO_READ	   ;SAVE BAD TRACK NUMBER FOR READ
				   ;CR,LF,"Unrecoverable read error on drive %2",CR,LF
				   ;"side %3, track %4",CR,LF
				   ;%2 IS "DRIVE_LETTER", AND
				   ;"MSG_SIDES" AND "MSG_TRACKS" ARE %3 AND %4.
       MOV   DI,OFFSET MSGNUM_HARD_ERROR_READ ; 				;AN000;
;  $ELSE
   JMP SHORT $$EN90
$$IF90:
.XLIST
;	     MOV     BX,OFFSET COMPARE_ERROR ;TELL USER ERROR DURING COMPARE OP
;	     MOV     MSG_HARD_ERROR_PTR+2,BX
.LIST
       MOV   BL,TRACK_TO_READ	   ;SAVE BAD TRACK NUMBER FOR WRITE
				   ;CR,LF,"Compare error on",CR,LF
				   ;"side %3, track %4",CR,LF
				   ;"MSG_SIDES" AND "MSG_TRACKS" ARE %3 AND %4.
       MOV   DI,OFFSET MSGNUM_HARD_ERROR_COMP ; 				;AN000;
;  $ENDIF
$$EN90:

   MOV	 AL,SIDE
   MOV	 BYTE PTR MSG_SIDES,AL
   MOV	 BYTE PTR MSG_TRACKS,BL
   CALL  SENDMSG		   ;PRINT MSG SELECTED ABOVE			;AN000;

   RET
ERROR_MESSAGE ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <COMBAT_ERROR - DISPLAY INCOMPATIBLE MSG> ;				;AN000;
COMPAT_ERROR PROC NEAR		   ;DISPLAY COMPAT MSG
   PUBLIC COMPAT_ERROR
;  =  =  =  =  =  =  =	=  =  =  =  =

   MOV	 COMP_STATUS,FATAL	   ;INCOMPATIBLE, ABORT
				   ;"Drive types or diskette types"
				   ;"not compatible"
   PRINT MSGNUM_NOT_COMPATIBLE

   RET
COMPAT_ERROR ENDP
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <PRESS_ANY_KEY - PUTS A BLANK LINE BEFORE PROMPT> ;			  ;AN009;
PRESS_ANY_KEY PROC NEAR 	   ;
;THE CANNED MESSAGE "PRESS ANY KEY..." DOES NOT START WITH CR,LF.
;THIS PUTS OUT THE CR LF TO CAUSE SEPARATION OF THIS PROMP FROM
;PRECEEDING MESSAGES.
;  =  =  =  =  =  =  =	=  =  =  =  =
   PRINT MSGNUM_NEWLINE 	   ;SKIP A SPACE			       ;AN009;

   PRINT MSGNUM_STRIKE		   ;"Press any key when ready..."	       ;AN009;

   RET				   ;RETURN TO CALLER			       ;AN009;
PRESS_ANY_KEY ENDP		   ;					       ;AN009;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <SENDMSG - PASS IN REGS DATA FROM MSG DESCRIPTOR TO DISP MSG> ;	;AN000;
SENDMSG PROC NEAR		   ;						;AN000;
   PUBLIC SENDMSG		   ;						;AN000;
; INPUT - DI=POINTER TO MSG_DESC STRUC FOR THIS MESSAGE
; OUTPUT - IF CARRY SET, EXTENDED ERROR MSG ATTEMPTED DISPLAYED
;	   IF CARRY CLEAR, ALL OK
;	   IN EITHER CASE, DI AND AX ALTERED, OTHERS OK

;  =  =  =  =  =  =  =	=  =  =  =  =

   PUSH  BX			   ; SAVE CALLER'S REGS                         ;AN000;
   PUSH  CX			   ;						;AN000;
   PUSH  DX			   ;						;AN000;
   PUSH  SI			   ;						;AN000;

;		 PASS PARMS TO MESSAGE HANDLER IN
;		 THE APPROPRIATE REGISTERS IT NEEDS.
   MOV	 AX,[DI].MSG_NUM	   ;MESSAGE NUMBER				;AN000;
   MOV	 BX,[DI].MSG_HANDLE	   ;HANDLE TO DISPLAY TO			;AN000;
   MOV	 SI,[DI].MSG_SUBLIST	   ;OFFSET IN ES: OF SUBLIST, OR 0 IF NONE	;AN000;
   MOV	 CX,[DI].MSG_COUNT	   ;NUMBER OF %PARMS, 0 IF NONE 		;AN000;
   MOV	 DX,[DI].MSG_CLASS	   ;CLASS IN HIGH BYTE, INPUT FUNCTION IN LOW	;AN000;
   CALL  SYSDISPMSG		   ;DISPLAY THE MESSAGE 			;AN000;

;  $IF	 C			   ;IF THERE IS A PROBLEM			;AN000;
   JNC $$IF93
				   ;AX=EXTENDED ERROR NUMBER			;AN000;
       LEA   DI,MSGNUM_EXTERR	   ;GET REST OF ERROR DESCRIPTOR		;AN000;
       MOV   BX,[DI].MSG_HANDLE    ;HANDLE TO DISPLAY TO			;AN000;
       MOV   SI,[DI].MSG_SUBLIST   ;OFFSET IN ES: OF SUBLIST, OR 0 IF NONE	;AN000;
       MOV   CX,[DI].MSG_COUNT	   ;NUMBER OF %PARMS, 0 IF NONE 		;AN000;
       MOV   DX,[DI].MSG_CLASS	   ;CLASS IN HIGH BYTE, INPUT FUNCTION IN LOW	;AN000;
       CALL  SYSDISPMSG 	   ;TRY TO SAY WHAT HAPPENED			;AN000;

       STC			   ;REPORT PROBLEM				;AN000;
;  $ENDIF			   ;PROBLEM WITH DISPLAY?			;AN000;
$$IF93:

   POP	 SI			   ;RESTORE CALLER'S REGISTERS                  ;AN000;
   POP	 DX			   ;						;AN000;
   POP	 CX			   ;						;AN000;
   POP	 BX			   ;						;AN000;

   RET				   ;RETURN TO CALLER				;AN000;
SENDMSG ENDP			   ;						;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <YESNO - DETERMINE IF A RESPONSE IS YES OR NO> ;			;AN000;
YESNO PROC NEAR 		   ;						;AN000;
   PUBLIC YESNO 		   ;MAKE ENTRY IN LINK MAP			;AN000;
;INPUT: DL=CHAR WITH Y OR N EQUIVALENT CHAR TO BE TESTED
;OUTPUT: AX=0=NO; AX=1=YES ; AX=2=INVALID RESPONSE, NEITHER Y NOR N
;	IF CARRY SET, PROBLEM WITH THE FUNCTION, CALLER SHOULD ASSUME "NO"
;  =  =  =  =  =  =  =	=  =  =  =  =
				   ;AL=SUBFUNCTION, AS:
				   ;  20H=CAPITALIZE SINGLE CHAR
				   ;  21H=CAPITALIZE STRING
				   ;  22H=CAPITALIZE ASCIIZ STRING
				   ;  23H=YES/NO CHECK
				   ;  80H BIT 0=USE NORMAL UPPER CASE TABLE
				   ;  80H BIT 1=USE FILE UPPER CASE TABLE
				   ;DL=CHAR TO CAP (FUNCTION 23H)		;AN000;
   MOV	 AX,(GET_EXT_CNTRY_INFO SHL 8) + YESNO_CHECK ;(6523H) GET EXTENDED	;AN000;
				   ; COUNTRY INFORMATION, (Y/N)
   INT	 21H			   ;SEE IF Y OR N				;AN000;

   RET				   ;RETURN TO CALLER				;AN000;
YESNO ENDP			   ;						;AN000;
;  =  =  =  =  =  =  =	=  =  =  =  =
   HEADER <VOLSER - VERIFY FIRST SECTOR, IGNORE VOL SER #> ;			 ;AN000;
VOLSER PROC NEAR		   ;VERIFY FIRST SECTOR, IGNORING VOL SER #	;AN000;
   PUBLIC VOLSER		   ;						;AN000;
;IF THE FIRST DISKETTE SUPPORTED A VOL SERIAL NUMBER, THEN
;COPY IT TO THE SECOND DISKETTE BUFFER AREA (NOT THE DISKETTE).
;INPUT: FIRST DRIVE NUMBER
;	DS:=SEGID OF BUFFER OF FIRST DISKETTE, FIRST SECTOR, SIDE 0
;	ES:=SEGID OF BUFFER OF SECOND DISKETTE, FIRST SECTOR, SIDE 0
;	SI AND DI = 0, INDEX OF WHERE IN BUFFERS TO START LOOKING
;	CX="BYTES_IN_TRACK"; NUMBER OF BYTES TO BE EVENTUALLY COMPARED
;OUTPUT: BUFFER OF 2ND DISKETTE ALTERED TO MATCH THE VOL SERIAL NUMBER OF 1ST.
; = = = = = = = = = = = = = = = = = =

   ASSUME DS:NOTHING		   ;BUFFER OF FIRST DISKETTE			;AN000;
   ASSUME ES:NOTHING		   ;BUFFER OF SECOND DISKETTE			;AN000;

   PUSH  CX			   ;SAVE CALLER'S REGS                          ;AN000;
   PUSH  SI			   ;						;AN000;
   PUSH  DI			   ;						;AN000;
;(deleted ;AN011;)   PUSH  DS			     ;SAVE BUFFER OF FIRST DISKETTE		  ;AN000;

;(deleted ;AN011;)   PUSH  CS			     ;RESTORE ADDRESSABILITY TO COMMON SEG	  ;AN000;
;(deleted ;AN011;)   POP   DS			     ; TO ACCESS GET MEDIA ID BUFFER AREA	  ;AN000;
;(deleted ;AN011;)   ASSUME DS:CSEG		     ;AN000;

;(deleted ;AN011;);		 ISSUE GET MEDIA ID FROM SOURCE
;(deleted ;AN011;)   MOV   BH,0 		     ;BH=0, RES 				  ;AN000;
;(deleted ;AN011;)   MOV   BL,SOURCE_DRIVE	     ;BL=DRIVE NUM (A:=1, B:=2, ETC.)		  ;AN000;
;(deleted ;AN011;)   MOV   DX,OFFSET MEDIA_ID_BUFFER ;DS:DX=BUFFER
;(deleted ;AN011;)   DOSCALL GSET_MEDIA_ID,GET_ID    ;(6900H) GET MEDIA ID			  ;AC008;
;(deleted ;AN011;)				     ;CARRY SET ON ERROR (OLD STYLE BOOT RECORD)
;(deleted ;AN011;)   POP   DS			     ;RESTORE THIS BACK TO BUFFER OF FIRST DISKETTE;AN000;
;(deleted ;AN011;)   ASSUME DS:NOTHING		     ; LIKE IT WAS AT ENTRY TO THIS PROC	  ;AN000;

;(deleted ;AN011;)   $IF   NC			     ;IF THERE IS NO PROBLEM			  ;AN000;
;(deleted ;AN011;)				     ; THEN THIS DISKETTE HAS A VOL SER #

   PUSH  BX			   ;AN011;
   LEA	 BX,DS:[DI].EXT_BOOT_BPB   ;AN011;POINT TO BPB PORTION OF BOOT RECORD
   MOV	 AL,DS:[BX].EBPB_MEDIADESCRIPTOR ;AN011;GET TYPE OF MEDIA
   AND	 AL,0F0H		   ;AN011;SAVE LEFT NIBBLE ONLY
   CMP	 AL,0F0H		   ;AN011;IF DISKETTE HAS PROPER DESCRIPTOR
;  $IF	 E			   ;AN011;
   JNE $$IF95
       MOV   AL,DS:[DI].EXT_BOOT_SIG ;AN011;GET "SIGNATURE" OF BOOT RECORD
       CMP   AL,28H		   ;AN011;IS THIS BOOT STYLE OF OS/2 1.0 OR 1.1?
;      $IF   E,OR		   ;AN011;YES, IS A BOOT WITH A SERIAL IN IT
       JE $$LL96
       CMP   AL,29H		   ;AN011;IS THIS A BOOT STYLE OF OS/S 1.2?
;      $IF   E			   ;AN011;YES, IS A BOOT WITH A SERIAL IN IT
       JNE $$IF96
$$LL96:

;THE PURPOSE HERE IS TO CAUSE DISKCOMP TO IGNORE ANY DIFFERENCES IN THE
;VOL SERIAL NUMBER FIELD.  THIS IS DONE BY TAKING ONE VOL SERIAL NUMBER
;FROM ONE BUFFER, ALREADY LOADED WITH THE FIRST TRACK OF ONE DISKETTE,
;AND MOVING THAT SERIAL NUMBER TO THE CORRESPONDING POSITION IN THE OTHER
;BUFFER, ALREADY LOADED WITH THE SIMILAR TRACK FROM THE OTHER DISKETTE.
;WHEN THIS RETURNS TO THE MAIN ROUTINE, THE ENTIRE TRACK (INCUDING THIS
;VOL SERIAL NUMBER FIELD) WILL BE COMPARED.  IF THERE ARE ANY DIFFERENCES,
;THEY WILL BE OTHER THAN IN THE VOL SERIAL NUMBERS.

	   MOV	 SI,OFFSET VOL_SERIAL ;GET WHERE VOL SERIAL NUMBER IS
	   MOV	 DI,OFFSET VOL_SERIAL ;GET WHERE VOL SERIAL NUMBER IS
	   MOV	 CX,TYPE VOL_SERIAL ;GET NUMBER BYTES IN VOL SER FIELD
	   REP	 MOVSB		   ;FORCE THE SERIAL NUMBERS TO BE ALIKE

;      $ENDIF			   ;						;AN000;
$$IF96:
;  $ENDIF			   ;AN011;
$$IF95:
   POP	 BX			   ;AN011;
   POP	 DI
   POP	 SI
   POP	 CX			   ;RESTORE COUNT
   RET				   ;RETURN TO CALLER				;AN000;
VOLSER ENDP			   ;AN000;
; = = = = = = = = = = = = = = = = = = =
DISKCOMP_END LABEL BYTE
   PATHLABL DISKCOMP		   ;AN013;
CSEG ENDS
   END	 DISKCOMP
