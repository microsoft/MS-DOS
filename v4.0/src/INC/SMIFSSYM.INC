
	PAGE	60,132
;	SCCSID = @(#)smifssym.inc 1.0 87/05/11
;
;   Modification history:
;	Created: May 11 1987 
;
;	SMifssym is only for IBMBIO.  It will only has definitions
;	for IFSHEADER, IFSRH of INIT function.
;	When ifssym.inc is Revised, make sure that SMifssym.inc
;	is also correct. - JK.
;

;==================
;IFS drive header
;=================

    IFSDEVICE	EQU	8000H	;  Supports single device/file functions
    IFSDISK	EQU	4000H	;  Supports multi-file functions
    IFSUNC	EQU	2000H	;  Support UNC (nameless) connection
    IFSREMOTE	EQU	0800H	;  File system is remote
    IFSFILTER	EQU	0400H	;  FS will filter (if off, use DOS
				;    standard, cap & 8.3)
    IFSIOCTL	EQU	0002H	;  Supports IOCTL functions
    IFSUSESHARE EQU	0001H	;  Uses DOS share support (vs own share)

IFSHEADER	STRUC
IFS_NEXT	DD	-1	; Next header in list (-1=end)
IFS_NAME	DB	"        " ; IFS name
IFS_ATTRIBUTE	DW	?	; Attributes
IFS_VERSION	DW	0	; Request level supported
IFS_DOSCALL@	DD	?	; DOS interface routine
				;   (set by TUPPER before the init call)
IFS_CALL@	DW	?	; Function entry point
IFSHEADER	ENDS

;=====================
; IFS Request Header
;=====================

IFSRH		STRUC
IFSR_LENGTH	DW    ? 		; Total length of request
IFSR_FUNCTION	DB    ? 		; Requested function
IFSR_RETCODE	DB    ? 		; Explicit error
IFSR_RETCLASS	DB    ? 		; Error class
IFSR_RESV1	DB    17 DUP(0) 	; DOS reserved
IFSR_FCN_PARMS	DB    38 DUP(0) 	; Additional parameters
IFSRH		ENDS

; IFSR_FUNCTION codes
;	Control requests:
IFSINIT        EQU     1
IFSATTSTART    EQU     2
IFSATTEND      EQU     3
IFSEXECAPI     EQU     4
IFSCRITMSG     EQU     5
IFSCBUPDATE    EQU     6
; INIT function.
IFSR_PARMS@	   =  DWORD PTR  IFSR_FCN_PARMS    ; command parameters
IFSR_RESSIZE	   =  WORD  PTR  IFSR_FCN_PARMS+4  ; driver total size
LENGTH_INIT	   EQU IFSR_RESSIZE-IFSRH+2

