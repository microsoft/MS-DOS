
%OUT MSBDS.INC...
;	SCCSID = @(#)IBMBDS.ASM 1.9 85/09/16
;==============================================================================
;REVISION HISTORY:
;AN000 - New for DOS Version 4.00 - J.K.
;AC000 - Changed for DOS Version 4.00 - J.K.
;AN00x - PTM number for DOS Version 4.00 - J.K.
;==============================================================================
;AN001; D113 Disable I/O access to unformatted media		    9/03/87 J.K.
;==============================================================================

; VALUES FOR VARIOUS FLAGS IN BDS.FLAGS.

FNON_REMOVABLE	    EQU     01H 	;FOR NON-REMOVABLE MEDIA
FCHANGELINE	    EQU     02H 	;IF CHANGELINE SUPPORTED ON DRIVE
RETURN_FAKE_BPB     EQU     04H 	; WHEN SET, DON'T DO A BUILD BPB
					; JUST RETURN THE FAKE ONE
GOOD_TRACKLAYOUT    EQU     08H 	; THE TRACK LAYOUT HAS NO FUNNY SECTORS
; FCHANGED_BY_FORMAT  EQU	    08H
FI_AM_MULT	    EQU     10H 	;IF MORE THAN ONE LOGICAL FOR THIS PHYSICAL
FI_OWN_PHYSICAL     EQU     20H 	;SIGNIFY LOGICAL OWNER OF THIS PHYSICAL
FCHANGED	    EQU     40H 	;INDICATES MEDIA CHANGED
SET_DASD_TRUE	    EQU     80H 	; SET DASD BEFORE NEXT FORMAT
FCHANGED_BY_FORMAT  EQU    100H 	;MEDIA CHANGED BY FORMAT
UNFORMATTED_MEDIA   EQU    200H 	;AN001; Fixed disk only

;
; VARIOUS FORM FACTORS TO DESCRIBE MEDIA
;
FF48TPI 	    EQU     0
FF96TPI 	    EQU     1
FFSMALL 	    EQU     2
FFHARDFILE	    EQU     5
FFOTHER 	    EQU     7

BDS_TYPE	STRUC
LINK		DD		?	; LINK TO NEXT BDS
DRIVENUM	DB		?	; INT 13 DRIVE NUMBER
DRIVELET	DB		?	; DOS DRIVE NUMBER
BYTEPERSEC	DW		?	; NUMBER OF BYTES/SEC
SECPERCLUS	DB		?	; SEC PER ALLOCATION UNIT
RESSEC		DW		?	; NUMBER OF RESERVED SECTORS
CFAT		DB		?	; NUMBER OF FATS
CDIR		DW		?	; NUMBER OF DIRECTORY ENTRIES
DRVLIM		DW		?	; NUMBER OF SECTORS ON MEDIUM
MEDIAD		DB		?	; MEDIA DESCRIPTOR BYTE
CSECFAT 	DW		?	; NUMBER OF SECTORS/FAT
SECLIM		DW		?	; SECTORS PER TRACK
HDLIM		DW		?	; MAX NUMBER OF HEADS
HIDSEC_L	DW		?	; NUMBER OF HIDDEN SECTORS
HIDSEC_H	dw		0	;J.K.87
DRVLIM_L	dw		0	;J.K.87
DRVLIM_H	dw		0	;J.K.87
FATSIZ		DB		?	; FLAGS...
OPCNT		DW		?	; OPEN REF. COUNT
FORMFACTOR	DB		?	; FORM FACTOR INDEX
FLAGS		DW		?	; VARIOUS FLAGS
CCYLN		DW		?	; MAX NUMBER OF CYLINDERS
RBYTEPERSEC	DW		?	; RECOMMENDED BPB
RSECPERCLUS	DB		?
RRESSEC 	DW		?
RCFAT		DB		?
RCDIR		DW		?
RDRVLIM 	DW		?
RMEDIAD 	DB		?
RCSECFAT	DW		?
RSECLIM 	DW		?
RHDLIM		DW		?
RHIDSEC_L	DW		?
RHIDSEC_H	DW		0	;J.K.87
RDRVLIM_L	dw		0	;J.K.87
RDRVLIM_H	dw		0	;J.K.87
RESERVE 	DB		6 DUP (?)	; RESERVED FOR FUTURE
TRACK		DB		?	; LAST TRACK ACCESSED ON DRIVE
TIM_LO		DW		?	; TIME OF LAST ACCESS. KEEP
TIM_HI		DW		?	; THESE CONTIGUOUS.
VOLID		DB		12 DUP (?)	; VOLUME ID OF MEDIUM
VOL_SERIAL	dd	0	  ;J.K.87 Current volume serial number from Boot record
FILESYS_Id	db	9 dup (0) ;J.K.87 Current file system id from Boot record
BDS_TYPE	ENDS

BPBSIZE     =	TRACK - RBYTEPERSEC ; SIZE IN BYTES OF RECBPB AREA IN THE BDS


;*********************************************************************
;	BDS structure for mini disk - J.K. 4/7/86
;*********************************************************************

BDSM_type	struc
mlink		DW	-1			;Link to next structure
		DW	?
mdriveNum	DB	80			;Int 13 Drive Number
mdriveLet	DB	3			;Logical Drive Number
mBytePerSec	DW	512
mSecPerClus	DB	1			;Sectors/allocation unit
mRESSEC 	DW	1			;Reserved sectors for DOS
mcFAT		DB	2			;No. of allocation tables
mcDIR		DW	16			;Number of directory entries
mDRVLIM 	DW	0			;Number of sectors (at 512 bytes each)
mMediad 	DB	11111000B		;Media descriptor
mcSecFat	DW	1			;Number of FAT sectors
mSECLIM 	DW	0			;Sector limit
mHDLIM		DW	0			;Head limit
mHIDSEC_L	DW	0			;Hidden sector count
mHidsec_H	dw	0			;J.K.87
mDrvlim_L	dw	0			;J.K.87
mDrvlim_H	dw	0			;J.K.87
mFatSiz 	DB	0			;TRUE => bigfat
mOPCNT		DW	0			;Open Ref. Count
mFormFactor	DB	3			;Form Factor
mFLAGS		DW	0020H			;Various Flags
mcCyln		dw	40			;max number of cylinders
mRecBPB 	db	31 dup (0)		;Recommended BPB for drive
mTrack		db	-1
IsMini		dw	1			;Overlapping TIM_LOH
Hidden_Trks	dw	0			;Overlapping TIM_HIH
mVOLID		DB	"NO NAME    "           ;Volume ID for this disk
		DB	0			;ASCIZII for "NO NAME    "
mVol_Serial	dd	0	   ;Current volume serial number from Boot record
mFileSys_Id	db	"FAT12   " ;Current file system id from Boot record
		db	0

BDSM_type	ENDS
;******************************************************************************
Max_mini_dsk_num = 23	      ;J.K. 4/7/86 - max # of mini disk ibmbio can support
;

