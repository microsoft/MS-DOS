	PAGE	,132				;
;	SCCSID = @(#)ifssym.inc 1.0 87/05/11
;******************************************************************************
;   IFS Symbol File
;
; REVISION HISTORY:
;	A000	Original version  4.00		  May 1987
;	A001	DCR 158 - merge unc info in attach start/status requests      8/87 RGAZZIA
;	A002	DCR 187 - ctrl req renumber, make attach type byte	      8/87 RGAZZIA
;	A003	PTM 764 - printer attach problems			      8/87 RGAZZIA
;	A004	PTM ???? - Write Only locks on Read/Write		     10/27 FEIGENBAUM
;	A005	DCR 285 - remove Extended Attribute/Lock support	      1/88 RG
;	A006	PTM 2827  error proc					      1/88 RG
;	A007	PTM 3334- reset envirn subfunc to eop			      2/88 RMG
;	A008	PTM 3745- commit across net problem due to sft flags problem  3/88 RMG
;	A009	PTM 3810- new sft unique id in sff			      3/88 RMG
;	A010	PTM 4392- ditch sf_iomode,cp				      4/18/88 RMG
;
;   LOD - 414
;
;******************************************************************************
											 ;AN000;
SUBTTL	IFS Driver Header								 ;AN000;
PAGE											 ;AN000;
											 ;AN000;
IFSHEADER	STRUC									 ;AN000;
IFS_NEXT	DD	-1	; Next header in list (-1=end)				 ;AN000;
IFS_NAME	DB	"        " ; IFS name                                            ;AN000;
IFS_ATTRIBUTE	DW	?	; Attributes						 ;AN000;
IFS_VERSION	DW	0	; Request level supported				 ;AN000;
IFS_DOSCALL@	DD	?	; DOS interface routine 				 ;AN000;
				;   (set by TUPPER before the init call)		 ;AN000;
IFS_CALL@	DW	?	; Function entry point					 ;AN000;
IFSHEADER	ENDS									 ;AN000;
											 ;AN000;
; ifs_attribute equates 								 ;AN000;
											 ;AN000;
IFSDEVICE	EQU	8000H	;  Supports single device/file functions		 ;AN000;
IFSDISK 	EQU	4000H	;  Supports multi-file functions			 ;AN000;
IFSUNC		EQU	2000H	;  Support UNC (nameless) connection			 ;AN000;
IFSREMOTE	EQU	0800H	;  File system is remote				 ;AN000;
IFSFILTER	EQU	0400H	;  FS will filter (if off, use DOS			 ;AN000;
				;    standard, cap & 8.3)				 ;AN000;
IFSIOCTL	EQU	0002H	;  Supports IOCTL functions				 ;AN000;
IFSUSESHARE	EQU	0001H	;  Uses DOS share support (vs own share)		 ;AN000;
											 ;AN000;
											 ;AN000;
SUBTTL	IFSRH - IFS Request Header							 ;AN000;
PAGE											 ;AN000;
											 ;AN000;
; IFS Request Header									 ;AN000;
											 ;AN000;
IFSRH		STRUC									 ;AN000;
IFSR_LENGTH	DW    ? 		; Total length of request			 ;AN000;
IFSR_FUNCTION	DB    ? 		; Requested function				 ;AN000;
IFSR_RETCODE	DW    ? 		; Explicit error				 ;AN000;
IFSR_RETCLASS	DB    ? 		; Error class					 ;AN000;
IFSR_RESV1	DB    16 DUP(0) 	; DOS reserved					 ;AN000;
IFSR_FCN_PARMS	DB    50 DUP(0) 	; Additional parameters 			 ;AN000;
IFSRH		ENDS									 ;AN000;
											 ;AN000;
; IFSR_FUNCTION codes									 ;AN000;
;	Control requests:								 ;AN000;
IFSINIT        EQU     1								 ;AN000;
IFSATTSTART    EQU     2								 ;AN000;
IFSATTSTAT     EQU     3								 ;AC002;
IFSATTEND      EQU     4								 ;AC002;
IFSEXECAPI     EQU     5								 ;AC002;
IFSCRITMSG     EQU     6								 ;AC002;
IFSUPDATECB    EQU     7								 ;AC002;
											 ;AN000;
; IFSR_APIFUNC	codes:									 ;AN000;
;      Int 21 mapped requests:								 ;AN000;
IFSDRIVERESET	   EQU	 1								 ;AN000;
IFSDISKATTR	   EQU	 2								 ;AN000;
IFSMKDIR	   EQU	 3								 ;AN000;
IFSRMDIR	   EQU	 4								 ;AN000;
IFSCHDIR	   EQU	 5								 ;AN000;
IFSDELFILE	   EQU	 6								 ;AN000;
IFSRENFILE	   EQU	 7								 ;AN000;
IFSSEARCHFILE	   EQU	 8								 ;AN000;
IFSOPENFILE	   EQU	 9								 ;AN000;
IFSLSEEKFILE	   EQU	10								 ;AN000;
IFSREADFILE	   EQU	11								 ;AN000;
IFSWRITEFILE	   EQU	12								 ;AN000;
IFSLOCKFILE	   EQU	13								 ;AN000;
IFSCLOSEFILE	   EQU	14								 ;AN000;
IFSFILEATTR	   EQU	15								 ;AN000;
IFSDEPIOCTL	   EQU	16								 ;AN000;
IFSDEVIOCTL	   EQU	17								 ;AN000;
IFSEOP		   EQU	18								 ;AN000;
IFSEOCID	   EQU	19								 ;AN000;
											 ;AN000;
SUBTTL	Control Request Parameter Macro 						 ;AN000;
PAGE											 ;AN000;
											 ;AN000;
IFSR_FCN_DEF	    MACRO  fcn								 ;AN000;
											 ;AN000;
		    IFIDN  <fcn>,<INIT> 						 ;AN000;
 IFSR_PARMS@	    =  DWORD PTR  IFSR_FCN_PARMS    ; command parameters		 ;AN000;
 IFSR_RESSIZE	    =  WORD  PTR  IFSR_FCN_PARMS+4  ; driver total size 		 ;AN000;
 LENGTH_INIT	    EQU IFSR_RESSIZE-IFSRH+2						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<ATTSTART>						 ;AN000;
 IFSR_TYPE	    =  BYTE  PTR  IFSR_FCN_PARMS    ; attach type			 ;AC001;
 IFSR_PARMS@	    =  DWORD PTR  IFSR_FCN_PARMS+2  ; command parameters		 ;AN000;
 IFSR_DEVICE_CB@    =  DWORD PTR  IFSR_FCN_PARMS+6  ; CD/DF				 ;AN000;
 IFSR_USER_WORD     =  WORD  PTR  IFSR_FCN_PARMS+10 ; for unc deviceless attach 	 ;AN001;
 LENGTH_ATTSTART    EQU IFSR_USER_WORD-IFSRH+2						 ;AC001;/;AC004;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<ATTSTAT>						 ;AN000;
 IFSR_TYPE	    =  BYTE  PTR  IFSR_FCN_PARMS    ; attach type			 ;AC001;
 IFSR_PARMS@	    =  DWORD PTR  IFSR_FCN_PARMS+2  ; command parameters		 ;AN000;
 IFSR_DEVICE_CB@    =  DWORD PTR  IFSR_FCN_PARMS+6  ; CD/DF				 ;AN000;
 IFSR_USER_WORD     =  WORD  PTR  IFSR_FCN_PARMS+10 ; for unc deviceless attach 	 ;AN001;
 IFSR_MAX_XMITT_SIZE = WORD  PTR  IFSR_FCN_PARMS+12 ; redir-maximum transmit size	 ;AN001;
 IFSR_NET_NAME_ID   =  WORD  PTR  IFSR_FCN_PARMS+14 ; redir-net name id 		 ;AN001;
 IFSR_LSN	    =  WORD  PTR  IFSR_FCN_PARMS+16 ; redir-low byte=local session #	 ;AN001;
 IFSR_DEVICE_STATUS =  BYTE  PTR  IFSR_FCN_PARMS+18 ; redir-interesting bits		 ;AN001;
 LENGTH_ATTSTAT     EQU IFSR_DEVICE_STATUS-IFSRH+2					 ;AC001;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<ATTEND>						 ;AN000;
 IFSR_DEVICE_CB@    =  DWORD PTR  IFSR_FCN_PARMS    ; CD/DF				 ;AN000;
 IFSR_NAME@	    =  DWORD PTR  IFSR_FCN_PARMS+4  ; UNC deviceless detach		 ;AN000;
 LENGTH_ATTEND	    EQU IFSR_NAME@-IFSRH+4						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<EXECAPI>						 ;AN000;
 IFSR_APIFUNC	    =  BYTE  PTR  IFSR_FCN_PARMS    ; API function code 		 ;AN000;
 IFSR_ERROR_CLASS   =  BYTE  PTR  IFSR_FCN_PARMS+1  ; DOS extended error class		 ;AN000;
 IFSR_ERROR_ACTION  =  BYTE  PTR  IFSR_FCN_PARMS+2  ; DOS extended error action 	 ;AN000;
 IFSR_ERROR_LOCUS   =  BYTE  PTR  IFSR_FCN_PARMS+3  ; DOS extended error locus		 ;AN000;
 IFSR_ALLOWED	    =  BYTE  PTR  IFSR_FCN_PARMS+4  ; DOS extended error locus		 ;AN000;
 IFSR_I24_COUNT     =  BYTE  PTR  IFSR_FCN_PARMS+5  ; critical error retry count	 ;AN000;
						    ;  0=first time			 ;AN000;
 IFSR_I24_RESP	    =  BYTE  PTR  IFSR_FCN_PARMS+6  ; critical error response		 ;AN000;
						    ;	 0=ignore  1=retry		 ;AN000;
 IFSR_DEVICE_CB@    =  DWORD PTR  IFSR_FCN_PARMS+8  ; device (CD or DF) 		 ;AN000;
 IFSR_OPEN_CB@	    =  DWORD PTR  IFSR_FCN_PARMS+12 ; open file instance  (SF)		 ;AN000;
 IFSR_API_PARMS     =  BYTE  PTR  IFSR_FCN_PARMS+16					 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<CRITMSG>						 ;AN000;
 IFSR_MSG@	    =  DWORD PTR  IFSR_FCN_PARMS    ; message buffer address		 ;AN000;
 IFSR_MSG_TYPE	    =  BYTE  PTR  IFSR_FCN_PARMS+4  ; message type			 ;AN000;
						 ; 1=message is printed in form 	 ;AN000;
						 ;    <message> 			 ;AN000;
						 ;    Abort,Retry,Ignore,Fail		 ;AN000;
						 ; 0=message is printed in form 	 ;AN000;
				 ; <message> error (read/writ)ing (drive/device) XXX ;	 ;AN000;
				 ; Abort,Retry,Ignore,Fail				 ;AN000;
											 ;AN000;
 LENGTH_CRITMSG     EQU IFSR_MSG_TYPE-IFSRH+2						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<UPDATECB>						 ;AN000;
 IFSR_CB@	    =  DWORD PTR      IFSR_FCN_PARMS	; control block address 	 ;AN000;
 IFSR_TYPE	    =  BYTE  PTR      IFSR_FCN_PARMS+4	; control block type		 ;AN000;
 IFSOPEN	    EQU   0		  ; open instance (SFT) entry			 ;AN000;
 IFSCB		    EQU   -1		  ; see control block type field		 ;AN000;
 LENGTH_UPDATECB    EQU IFSR_TYPE-IFSRH+2						 ;AN000;
											 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDM								 ;AN000;
											 ;AN000;
SUBTTL	INT 21H Mapped Request Parameter Macro						 ;AN000;
PAGE											 ;AN000;
											 ;AN000;
IFSR_API_DEF	    MACRO  fcn								 ;AN000;
											 ;AN000;
		    IFIDN  <fcn>,<DRIVERESET>						 ;AN000;
 IFSR_FUNC	    =  BYTE  PTR  IFSR_API_PARMS    ; 0=flush				 ;AN000;
 LENGTH_DRIVERESET  EQU IFSR_FUNC-IFSRH+2						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<DISKATTR>						 ;AN000;
 IFSR_ALLOCUNITS    =  WORD  PTR  IFSR_API_PARMS    ; # allocation units		 ;AN000;
 IFSR_ALLOCSIZE     =  WORD  PTR  IFSR_API_PARMS+2  ; allocation unit sectors		 ;AN000;
 IFSR_SECTSIZE	    =  WORD  PTR  IFSR_API_PARMS+4  ; sector size			 ;AN000;
 IFSR_AVAILALLOC    =  WORD  PTR  IFSR_API_PARMS+6  ; free allocation units		 ;AN000;
 IFSR_FSID	    =  BYTE  PTR  IFSR_API_PARMS+8  ; file system media id		 ;AN000;
 LENGTH_DISKATTR    EQU IFSR_FSID-IFSRH+2						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<MKDIR>						 ;AN000;
 IFSR_NAME@	    =  DWORD PTR  IFSR_API_PARMS    ; asciiz name to process		 ;AN000;
 LENGTH_MKDIR	    EQU IFSR_NAME@-IFSRH+4						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<RMDIR>						 ;AN000;
 IFSR_NAME@	    =  DWORD PTR  IFSR_API_PARMS    ; asciiz name to process		 ;AN000;
 LENGTH_RMDIR	    EQU IFSR_NAME@-IFSRH+4						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<CHDIR>						 ;AN000;
 IFSR_NAME@	    =  DWORD PTR  IFSR_API_PARMS    ; asciiz name to process		 ;AN000;
 LENGTH_CHDIR	    EQU IFSR_NAME@-IFSRH+4						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<DELFILE>						 ;AN000;
 IFSR_MATCHATTR_47  =  WORD  PTR  IFSR_API_PARMS    ; format 00000000e0a00shr		 ;AN000;
 IFSR_NAME@	    =  DWORD PTR  IFSR_API_PARMS+2  ; file to delete			 ;AN000;
 LENGTH_DELFILE     EQU IFSR_NAME@-IFSRH+4						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<RENFILE>						 ;AN000;
 IFSR_MATCHATTR     =  WORD  PTR  IFSR_API_PARMS    ; format 00000000e0a00shr		 ;AN000;
 IFSR_NAME1@	    =  DWORD PTR  IFSR_API_PARMS+2  ; file to rename			 ;AN000;
 IFSR_NAME2@	    =  DWORD PTR  IFSR_API_PARMS+6  ; new file name			 ;AN000;
 LENGTH_RENFILE     EQU IFSR_NAME2@-IFSRH+4						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<SEARCHFILE>						 ;AN000;
 IFSR_SUBFUNC	    =  BYTE  PTR  IFSR_API_PARMS    ; 1=first, 2=next			 ;AN000;
 IFSR_CONTINFO@     =  DWORD PTR  IFSR_API_PARMS+2  ; continuation info addr		 ;AN000;
 IFSR_MATCHATTR     =  WORD  PTR  IFSR_API_PARMS+6  ; format 0000000re0advshr  (1st)	 ;AN000;
 IFSR_NAME@	    =  DWORD PTR  IFSR_API_PARMS+8  ; asciiz name to process   (1st)	 ;AN000;
 LENGTH_SEARCHFILE  EQU IFSR_NAME@-IFSRH+4						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<OPENFILE>						 ;AN000;
 IFSR_MODE	    =  WORD  PTR  IFSR_API_PARMS    ; open mode 			 ;AN000;
						 ;  format: 0WF0000CISSS0AAA		 ;AN000;
						 ;  AAA=access code 0=read,1=write	 ;AN000;
						 ;		    2=read/write	 ;AN000;
						 ;  SSS=sharing mode 0=compatibility	 ;AN000;
						 ;	1=deny r/w, 2=deny write	 ;AN000;
						 ;	3=deny read, 4=deny none	 ;AN000;
						 ;  I 0=pass handle to child, 1=no inheri;AN000;t
						 ;  C 0=validate cp, 1=no cp check	 ;AN000;
						 ;  F 0=int 24H, 1=return error on	 ;AN000;
						 ;  this open & any I/O to this handle	 ;AN000;
						 ;  W 0=no commit, 1=auto-commit on	 ;AN000;
						 ;		     write		 ;AN000;
 IFSR_FLAG	    =  WORD  PTR  IFSR_API_PARMS+2  ; function control;  format=CE	 ;AN000;
						 ; C=does not exist action		 ;AN000;
						 ; 0=fail, 1=create			 ;AN000;
						 ; E=exists action			 ;AN000;
						 ; 0=fail, 1=open, 2=replace/open	 ;AN000;
 IFSR_CP	    =  WORD  PTR  IFSR_API_PARMS+4  ; global code page			 ;AN000;
 IFSR_CPSW	    =  BYTE  PTR  IFSR_API_PARMS+6  ; CPSW flag 			 ;AN000;
 IFSR_NAME@	    =  DWORD PTR  IFSR_API_PARMS+8  ; asciiz name to open		 ;AN000;
 IFSR_PARMS@	    =  DWORD PTR  IFSR_API_PARMS+12 ; format:
						 ;	     DD  EA address
						 ;	     DW  #parms
						 ;	     DB  IOMODE ID		 ;AN000;
						 ;	     DW  IO Mode		 ;AN000;
 IFSR_MATCHATTR     =  WORD  PTR  IFSR_API_PARMS+16 ; format 00000000e0advshr		 ;AN000;
 IFSR_ACTION	    =  WORD  PTR  IFSR_API_PARMS+18					 ;AN000;
 LENGTH_OPENFILE    EQU IFSR_ACTION-IFSRH+2						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<LSEEKFILE>						 ;AN000;
 IFSR_MODE	    =  BYTE  PTR  IFSR_API_PARMS    ; see INT 21H AH=42H		 ;AN000;
 IFSR_POSITION	    =  DWORD PTR  IFSR_API_PARMS+2  ; displacement of LSEEK		 ;AN000;
 LENGTH_LSEEKFILE   EQU IFSR_POSITION-IFSRH+4						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<READFILE>						 ;AN000;
;IFSR_MODE	    =  BYTE  PTR  IFSR_API_PARMS					 ;AD005;
 IFSR_COUNT	    =  WORD  PTR  IFSR_API_PARMS+2					 ;AN000;
 IFSR_BUFFER@	    =  DWORD PTR  IFSR_API_PARMS+4					 ;AN000;
 LENGTH_READFILE    EQU IFSR_BUFFER@-IFSRH+4						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<WRITEFILE>						 ;AN000;
;IFSR_MODE	    =  BYTE  PTR  IFSR_API_PARMS					 ;AD005;
 IFSR_COUNT	    =  WORD  PTR  IFSR_API_PARMS+2					 ;AN000;
 IFSR_BUFFER@	    =  DWORD PTR  IFSR_API_PARMS+4					 ;AN000;
 LENGTH_WRITEFILE   EQU IFSR_BUFFER@-IFSRH+4						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<LOCKFILE>						 ;AN000;
;IFSR_MODE	    =  BYTE  PTR  IFSR_API_PARMS    ;  bit 0: 0=lock all operations	 ;AD005;
						    ;  1=lock only write operations	 ;AD005;
 IFSR_FUNC	    =  BYTE  PTR  IFSR_API_PARMS    ; 0=LOCK, 1=UNLOCK			 ;AC005;
;IFSR_COUNT	    =  WORD  PTR  IFSR_API_PARMS+2					 ;AD005;
;IFSR_RANGE@	    =  DWORD PTR  IFSR_API_PARMS+4					 ;AD005;
 IFSR_LK_POSITION   =  DWORD PTR  IFSR_API_PARMS+2					 ;AN005;
 IFSR_LK_LENGTH     =  DWORD PTR  IFSR_API_PARMS+6					 ;AN005;
 LENGTH_LOCKFILE    EQU IFSR_LK_LENGTH-IFSRH+4						 ;AC005;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<CLOSEFILE>						 ;AN000;
 IFSR_FUNC	    =  BYTE  PTR  IFSR_API_PARMS    ; 0=CLOSE, 1=COMMIT 		 ;AN000;
 LENGTH_CLOSEFILE   EQU IFSR_FUNC-IFSRH+2						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<FILEATTR>						 ;AN000;
 IFSR_FUNC	    =  BYTE  PTR  IFSR_API_PARMS    ; 0=get, 1=set by handle		 ;AN000;
						    ; 2=get, 3=set by name		 ;AN000;
 IFSR_SUBFUNC	    =  BYTE  PTR  IFSR_API_PARMS+2  ; 0=none,2=EA List, 3-EA names	 ;AN000;
						    ; 2,3 used only on IFSR_FUNC=0,1	 ;AN000;
 IFSR_BUFFER1@	    =  DWORD PTR  IFSR_API_PARMS+4  ; if IFSR_TYPE=2,3			 ;AN000;
 IFSR_BUFFER2@	    =  DWORD PTR  IFSR_API_PARMS+8  ; if IFSR_TYPE=2			 ;AN000;
 IFSR_COUNT	    =  WORD  PTR  IFSR_API_PARMS+12 ; if IFSR_TYPE=2,3			 ;AN000;
 ; Following present only if IFSR_FUNC=2,3						 ;AN000;
 IFSR_MATCHATTR     =  WORD  PTR  IFSR_API_PARMS+14 ; format 0000000re0advshr		 ;AN000;
 IFSR_NAME@	    =  DWORD PTR  IFSR_API_PARMS+16 ; ASCIIZ file name			 ;AN000;
 IFSR_SIZE	    =  DWORD PTR  IFSR_API_PARMS+20 ; file size 			 ;AN000;
 IFSR_DATE	    =  WORD  PTR  IFSR_API_PARMS+24 ; file date 			 ;AN000;
 IFSR_TIME	    =  WORD  PTR  IFSR_API_PARMS+26 ; file time 			 ;AN000;
 IFSR_ATTR	    =  WORD  PTR  IFSR_API_PARMS+28 ; format 0000000re0advshr		 ;AN000;
 LENGTH_FILEATTR    EQU IFSR_ATTR-IFSRH+2						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<DEPIOCTL>						 ;AN000;
 IFSR_FUNC	    =  BYTE  PTR  IFSR_API_PARMS    ; 00 Generic IOCTL by device #	 ;AN000;
						    ; 01 Generic IOCTL by handle	 ;AN000;
						    ; 02 FS IOCTL query OS type 	 ;AN000;
 IFSR_BUFFER@	    =  DWORD PTR  IFSR_API_PARMS+2  ; set on queries			 ;AN000;
 IFSR_BUFSIZE	    =  WORD  PTR  IFSR_API_PARMS+6  ; Buffer size set for IFSR_FUNC=2	 ;AN000;
 ; FUNC dependent parameters								 ;AN000;
 ; For generic										 ;AN000;
 IFSR_CATEGORY	    =  BYTE  PTR  IFSR_API_PARMS+8  ; generic subfunctions		 ;AN000;
 IFSR_CTLFUNC	    =  BYTE  PTR  IFSR_API_PARMS+9  ; see INT 21H AH=6BH		 ;AN000;
 LENGTH_DEPIOCTL    EQU IFSR_CTLFUNC-IFSRH+1						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<DEVIOCTL>						 ;AN000;
 IFSR_FUNC	    =  BYTE  PTR  IFSR_API_PARMS    ; 00 Generic IOCTL by device #	 ;AN000;
						 ; 01 Generic IOCTL by handle		 ;AN000;
						 ; 02 FS IOCTL query OS type		 ;AN000;
 IFSR_BUFFER@	    =  DWORD PTR  IFSR_API_PARMS+2  ; set on queries			 ;AN000;
 IFSR_BUFSIZE	    =  WORD  PTR  IFSR_API_PARMS+6  ; buffer size set for IFSR_FUNC=2	 ;AN000;
 ; FUNC dependent parameters								 ;AN000;
 ; For generic										 ;AN000;
 IFSR_CATEGORY	    =  BYTE  PTR  IFSR_API_PARMS+8  ; generic subfunctions		 ;AN000;
 IFSR_CTLFUNC	    =  BYTE  PTR  IFSR_API_PARMS+9  ; see INT 21H AH=6BH		 ;AN000;
 LENGTH_DEVIOCTL    EQU IFSR_CTLFUNC-IFSRH+1						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<EOP>							 ;AN000;
 IFSR_PID	    =  WORD  PTR  IFSR_API_PARMS    ; process ID			 ;AN000;
 IFSR_SUBFUNC	    =  BYTE  PTR  IFSR_API_PARMS+2  ; 0=NORMAL EXIT, 1=ABORT EXIT	 ;AN000;
 LENGTH_EOP	    EQU IFSR_SUBFUNC-IFSRH+2						 ;AN000;
											 ;AN000;
		    ELSE								 ;AN000;
		    IFIDN  <fcn>,<EOCID>						 ;AN000;
 IFSR_UID	    =  WORD  PTR  IFSR_API_PARMS    ; process ID			 ;AN000;
 LENGTH_EOCID	    EQU IFSR_UID-IFSRH+2						 ;AN000;
											 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDIF								 ;AN000;
		    ENDM								 ;AN000;
											 ;AN000;
SUBTTL	Request Data									 ;AN000;
PAGE											 ;AN000;
											 ;AN000;
;	     Attach types								 ;AN000;
;;;aliasTYPE_ALIAS	EQU	0							 ;AN000;
TYPE_DEVICE	EQU	1								 ;AN000;
TYPE_DRIVE	EQU	2								 ;AN000;
TYPE_NET_DEVICE EQU	3								 ;AN000;
TYPE_NET_DRIVE	EQU	4								 ;AN000;
;	     Attach cmds								 ;AN000;
GET_MODE	EQU	0								 ;AN000;
SET_MODE	EQU	1								 ;AN000;
GET_ASSIGN_LIST EQU	2								 ;AN000;
DEFINE_MACRO	EQU	3								 ;AN000;
CANCEL_ATTACH	EQU	4								 ;AN000;
											 ;AN000;
ATTACH_PARMS	STRUC									 ;AN000;
AP_COUNT	DW	?								 ;AN000;
AP_STRING	DB	?								 ;AN000;
ATTACH_PARMS	ENDS									 ;AN000;
											 ;AN000;
;	     Critical Error Message types						 ;AN000;
CRIT_MSG_TYPE_1 	equ	1
TYPE1		EQU	1								 ;AN000;
TYPE0		EQU	0								 ;AN000;
											 ;AN000;
;	     Control Block types							 ;AN000;
CBTYPE_SFF	EQU	0								 ;AN000;
CBTYPE_CD	EQU	1								 ;AN000;
CBTYPE_DF	EQU	2								 ;AN000;
CBTYPE_DUMMYCD	EQU	3								 ;AN000;
											 ;AN000;
;	     Drive Reset equates							 ;AN000;
FUNC_FLUSH		EQU	0							 ;AN000;
FUNC_FLUSH_INVALIDATE	EQU	1							 ;AN000;
											 ;AN000;
;	     Search File equates							 ;AN000;
IFSSEARCH_FIRST EQU	1								 ;AN000;
IFSSEARCH_NEXT	EQU	2								 ;AN000;
											 ;AN000;
;	     Open/Create type								 ;AN000;
TYPE_NONE	EQU	0								 ;AN000;
NOTEXIST_ACT_FAIL      = 0						   ;+BAF
NOTEXIST_ACT_CREATE    = 1						   ;+BAF
EXIST_ACT_FAIL	       = 0						   ;+BAF
EXIST_ACT_OPEN	       = 1						   ;+BAF
EXIST_ACT_REP_OPEN     = 2						   ;+BAF

FILE_OPENED	       = 1
FILE_CREATED	       = 2
FILE_REPLACED	       = 3
											 ;AN000;
;	     Read/Write equates 							 ;AN000;
;MODE_READ	   EQU	 0								 ;AD005;
;MODE_WRITE	   EQU	 0								 ;AD005;
;MODE_LOCK_READ    EQU	1								 ;AD005;
;MODE_WRITE_UNLOCK EQU	1								 ;AD005;
;MODE_WRITE_SFPOS  EQU	  00H								 ;AD005;
;MODE_WRITE_SFSIZE EQU	  02H								 ;AD005;
;MODE_ADD_MASK	      EQU  00000010B	 ; do I need this???				 ;AD005;
											 ;AN000;
;	     Lock equates								 ;AN000;
;MODE_LOCK_ALL	      EQU  0								 ;AD005;
;MODE_LOCK_WRITE      EQU  1								 ;AD005;
FUNC_LOCK	     EQU  0								 ;AN000;
FUNC_UNLOCK	     EQU  1								 ;AN000;
;MODE_ADD_MASK	      EQU  00000010B							 ;AD005;
;MODE_WO_MASK	      EQU  10000000B							 ;AN004; BAF ;AD005;
;LOCK_RANGE_STRUC	 STRUC								 ;AD005;
;   IFSR_LOCK_POSITION	 DD	 ?							 ;AD005;
;   IFSR_LOCK_LENGTH	 DD	 ?							 ;AD005;
;LOCK_RANGE_STRUC	 ENDS								 ;AD005;

											 ;AN000;
;	     Close equates								 ;AN000;
FUNC_CLOSE	  EQU	0								 ;AN000;
FUNC_COMMIT	  EQU	1								 ;AN000;
											 ;AN000;
;	     LSeek equates								 ;AN000;
MODE2		  EQU	2								 ;AN000;
											 ;AN000;
;	     File Attribute equates							 ;AN000;
FUNC_GET_BY_HANDLE	EQU	0							 ;AN000;
FUNC_SET_BY_HANDLE	EQU	1							 ;AN000;
FUNC_GET_BY_NAME	EQU	2							 ;AN000;
FUNC_SET_BY_NAME	EQU	3							 ;AN000;
SUBFUNC_INLINE		EQU	0							 ;AN000;
SUBFUNC_EA		EQU	2							 ;AN000;
SUBFUNC_EA_NAMES	EQU	3							 ;AN000;
											 ;AN000;
;	     FS Dependent IOCTL 							 ;AN000;
GEN_IOCTL_BY_DEVNUM	    EQU     0							 ;AN000;
GEN_IOCTL_BY_HANDLE	    EQU     1							 ;AN000;
QUERY_OS_TYPE		    EQU     2							 ;AN000;
CATEGORY_FS		    EQU     0							 ;AN000;
CATEGORY_REDIR		    EQU     1							 ;AN000;
PRINTER_SET_STRING	    EQU     2							 ;AN000;
PRINTER_GET_STRING	    EQU     3							 ;AN000;
PRINTER_SET_FLAGS	    EQU     4							 ;AN000;
PRINTER_GET_FLAGS	    EQU     5							 ;AN000;
CTLFUNC_PRINTER_SET_STRING  EQU   00100001B						 ;AN000;
CTLFUNC_PRINTER_GET_STRING  EQU   00000001B						 ;AN000;
CTLFUNC_PRINTER_SET_FLAGS   EQU   00100010B						 ;AN000;
CTLFUNC_PRINTER_GET_FLAGS   EQU   00000010B						 ;AN000;
CTLFUNC_DEVECHOCHECK	    EQU   00000011B						 ;AN000;
CTLFUNC_GET_UNC_ITEM	    EQU   00000100B						 ;AN000;
CTLFUNC_DEVCLOSE	    EQU   00000101B						 ;AN000;
CTLFUNC_DEVOPER 	    EQU   00000110B						 ;AN000;
CTLFUNC_PRINT_ON	    EQU   00100111B						 ;AN000;
CTLFUNC_PRINT_OFF	    EQU   00000111B						 ;AN000;
CLOSE_SPOOL_FILES	    EQU     9							 ;AN000;
LENGTH_DEVECHOCHECK_BUFFER  EQU 1							 ;AN000;
											 ;AN000;
;	     FS Device IOCTL								 ;AN000;
READ_DEVICE		    EQU     2							 ;AN000;
WRITE_DEVICE		    EQU     3							 ;AN000;
CHAR_GENERIC		    EQU     0CH 						 ;AN000;
BLOCK_GENERIC		    EQU     0DH 						 ;AN000;
											 ;AN000;
;	     End of Process equates							 ;AN000;
EOP_NORMAL	EQU	0								 ;AN000;
EOP_ABORT	EQU	1								 ;AN000;
RESET_ENVIRONMENT EQU	2
											 ;AN000;
SUBTTL	Request Return Classes/Codes							 ;AN000;
PAGE											 ;AN000;
											 ;AN000;
;  IFS Request Return Codes							 ;AN000;
IFSR_NO_ERROR		EQU	0							 ;AN000;
IFSR_NONSPEC_ERROR	EQU	1							 ;AN000;
IFSR_NOT_FOUND_ERROR	EQU	2							 ;AN000;
IFSR_ACCESS_DENIED	EQU	3							 ;AN000;
IFSR_DEVICE_TYPE_MISMATCH EQU	4							 ;AN000;
IFSR_NO_SUBFCN_SUPPORT	EQU    -2							 ;AN000;
IFSR_NO_FCN_SUPPORT	EQU    -1							 ;AN000;
											 ;AN000;
;  IFS Request Return Classes								 ;AN000;
IFSR_INT21H_ERROR	EQU	1							 ;AN000;
IFSR_DRIVER_ERROR	EQU	2							 ;AN000;
IFSR_INT21H_CRITER	EQU	3							 ;AN000;
IFSR_DEVICE_ERROR	EQU	4							 ;AN006;
IFSR_BAD_FORMAT 	EQU    -1							 ;AN000;

;
;  Int 24H
NO_RETRY	=	0
I24_RESP_IGNORE =	0
I24_RESP_RETRY	=	1

											 ;AN000;
;  IFS_DOSCALL@ function equates							 ;AN000;
;  Block Device Driver Requests 							 ;AN000;
CALL_INTERRUPT_ROUTINE	EQU	1							 ;AN000;
READ_SECTORS		EQU	2							 ;AN000;
WRITE_SECTORS		EQU	3							 ;AN000;
FIND_SECTOR		EQU	8							 ;AN000;
MARK_SECTOR_CHANGED	EQU	9							 ;AN000;
;  Buffer Cache Requests								 ;AN000;
WRITE_DOS_BUFFER	EQU	10							 ;AN000;
READ_DOS_BUFFER 	EQU	11							 ;AN000;
FREE_DOS_BUFFER 	EQU	12							 ;AN000;
FLUSH_DOS_BUFFERS	EQU	13							 ;AN000;
;  Get DOS Variable									 ;AN000;
GET_DOS_VALUE		EQU	32							 ;AN000;
ACTIVE_PROCESS_INFO	EQU	1							 ;AN000;
CPSW_INFORMATION	EQU	2							 ;AN000;
BREAK_INFORMATION	EQU	3							 ;AN000;
VERIFY_INFORMATION	EQU	4							 ;AN000;
CONFIG_SYS_VALUES	EQU	5							 ;AN000;
    DOS_VALUE_BUFFER	    STRUC							 ;AN000;
       VAL_BUF_SIZE    DW      14							 ;AN000;
       VAL_BUF_FILES   DW      0							 ;AN000;
       VAL_BUF_FCBS    DW      0							 ;AN000;
		       DW      0							 ;AN000;
       VAL_BUF_BUFS    DW      0							 ;AN000;
		       DW      0							 ;AN000;
       VAL_BUF_LDRV    DW      0							 ;AN000;
       VAL_BUF_SSZ     DW      0							 ;AN000;
    DOS_VALUE_BUFFER	    ENDS							 ;AN000;
MACHINE_NAME		EQU	6							 ;AN000;
COUNTRY_INFO		EQU	7							 ;AN000;
SHARE_RETRY_COUNT	EQU	8							 ;AN000;
;  Get Assign Mode									 ;AN000;
GET_ASSIGN_MODE 	EQU	33							 ;AN000;
DEVICE_MACRO	=	3
DRIVE_MACRO    =	4
PAUSE_MODE_ON	=	1
PAUSE_MODE_OFF	=	0
;
DOS2NET_DATE	=	34
NET2DOS_DATE	=	35
DOS_STRCMP	=	36
DOS_STRCPY	=	37
USE_SYSTEM_TIMEDATE  =	0
USE_USER_TIMEDATE    =	1
;
											 ;AN000;
											 ;AN000;
SUBTTL	Pseudo Block Structures: SF, CD, DF						 ;AN000;
PAGE											 ;AN000;
; SFF - Pseudo SFT									 ;AN000;
;	 This structure is used to pass pertinent SFT information			 ;AN000;
;	 to IFS driver. 								 ;AN000;
											 ;AN000;
SFF		 STRUC			  ; Open File Control Block			 ;AN000;
SFF_TYPE	 DB	0,0		  ; Identifies SFF				 ;AN000;
SFF_FLAGS	 DW	 ?		  ; Control flags				 ;AN000;
					  ;   4000H=don't set date/time on close         ;AN009;
					  ;   0080H=device (vs file)			 ;AN009;
					  ;   0040H=File clean				 ;AN008;
SFF_MODE	 DW	 ?		  ; Mode of access.				 ;AN000;
					  ;   8000H=FCB (vs handle)[this moved from flags];AC008;
SFF_RESV1	 DW	 ?		  ; IO mode.					 ;AC023; iomode
SFF_ATTR	 DW	 ?		  ; File attr.FORMAT : 0000000re0advshr 	 ;AN000;
SFF_UID 	 DW	 ?		  ; User ID					 ;AN000;
SFF_PID 	 DW	 ?		  ; Process ID					 ;AN000;
SFF_SIZE	 DD	 ?		  ; File size					 ;AN000;
SFF_POSITION	 DD	 ?		  ; Read/Write pointer				 ;AN000;
SFF_TIME	 DW	 ?		  ; File time					 ;AN000;
SFF_DATE	 DW	 ?		  ; File date					 ;AN000;
SFF_NAME	 DB	 8 DUP (?)	  ; Name					 ;AN000;
SFF_EXT 	 DB	 3 DUP (?)	  ; Extension					 ;AN000;
SFF_RESV2	 DW	 0		  ; Code page					 ;AC024; cp
SFF_SF_ID	 DW	 0		  ; Unique SFT entry identifier 		 ;AN009;
SFF_RESV	 DB	12 DUP(0)	  ; Reserved					 ;AC009;
SFF_FSDA	 DB	 8 DUP(?)	  ; File System Dependent Data Area		 ;AN000;
SFF		ENDS									 ;AN000;
											 ;AN000;
; sff_flags bits
SFF_Close_NoDate EQU	4000H		  ;   4000H=don't set date/time on close         ;AN009;
SFF_IsDevice	 EQU	0080H		  ;   0080H=device (vs file)			 ;AN009;
SFF_FileClean	 EQU	0040H		  ;   0040H=File clean				 ;AN008;
SFF_Device_Raw	 EQU	0020H		  ;   0020H=Device raw				 ;AN008;
SFF_Net_Spool	 EQU	0000100000000000B
; sff_mode  bits
SFF_IsFCB	 EQU	8000H		  ;   8000H=FCB (vs handle)[this moved from flags];AC008;

; CD  - Pseudo CDS									 ;AN000;
;	 This structure is used to pass pertinent CDS information			 ;AN000;
;	 to IFS driver. 								 ;AN000;
											 ;AN000;
CD		STRUC									 ;AN000;
CD_TYPE 	DB	1,0		  ; Identifies CD				 ;AN000;
CD_END		DW	?		  ; End of assignment in CD_TEXT		 ;AN000;
CD_TEXT 	DB	67 DUP (?)	  ; Text of assignment and curdir		 ;AN000;
CD_RESV 	DB	5 DUP(0)	  ; Reserved					 ;AN000;
CD_FSDA 	DB	8 DUP(?)	  ; File System Dependent Data Area		 ;AN000;
CD		ENDS									 ;AN000;
											 ;AN000;
; DF  - Pseudo DFL									 ;AN000;
;	 This structure is used to pass pertinent DFL information			 ;AN000;
;	 to IFS driver. 								 ;AN000;

DFL		STRUC									 ;AN000;
DFL_TYPE 	DB	2,0		  ; Identifies DFL				 ;AN000;
DFL_DEV_NAME	DB	8 DUP (?)	  ; Device name 				 ;AN000;
DFL_FSDA 	DB	8 DUP (?)	  ; File System Dependent Data Area		 ;AN000;
DFL		ENDS									 ;AN000;
											 ;AN000;
SUBTTL	Search Continuation Information 						 ;AN000;
PAGE											 ;AN000;
CONTINFO	STRUC									 ;AN000;
CI_SEARCH_FN	DB	8 DUP(?)   ; SEARCH FILE NAME					 ;AN000;
CI_SEARCH_FN_EXT DB	3 DUP(?)   ; SEARCH FILE EXTENSION				 ;AN000;
CI_SEARCH_ATTR	DB	?	   ; SEARCH ATTRIBUTE					 ;AN000;
CI_FSDA 	DB	8 DUP(?)   ; FSDA						 ;AN000;
				   ; Directory entry:					 ;AN000;
CI_FOUND_FN	DB	8 DUP(?)   ; FOUND FILE NAME					 ;AN000;
CI_FOUND_FN_EXT DB	3 DUP(?)   ; FOUND FILE EXTENSION				 ;AN000;
CI_FOUND_ATTRL	DB	?	   ; FOUND ATTRIBUTE LOW  ??? DB/DD			 ;AN000;
CI_CP		DW	?	   ; FILE CODE PAGE (OR 0)				 ;AN000;
CI_RESV1	DW	?	   ; RESERVED						 ;AN000;
CI_FOUND_ATTRH	DB	?	   ; FOUND ATTRIBUTE HIGH				 ;AN000;
CI_RESV2	DB	5  DUP(?)  ; RESERVED						 ;AN000;
CI_FILE_TIME	DW	?	   ; FILE TIME						 ;AN000;
CI_FILE_DATE	DW	?	   ; FILE DATE						 ;AN000;
CI_FSWORD	DW	?	   ; MEANING FILE SYSTEM SPECIFIC			 ;AN000;
				   ; (STARTING CLUSTER IN FAT)				 ;AN000;
CI_FILE_SIZE	DD	?	   ; FILE SIZE						 ;AN000;
CONTINFO	ENDS									 ;AN000;


CATEGORY_PRINTER       EQU	5

CTLFUNC_SELECT	       EQU	4AH
CTLFUNC_QUERY_SELECTED EQU	6AH
CTLFUNC_QUERY_PREPLIST EQU	6BH

DEV_OPER_BUFFER        STRUC
  OPER_FUNC	DB	?
  TRUNC_FLAG	DB	?
DEV_OPER_BUFFER        ENDS

PACKET		       STRUC	; device ioctl buffer info
  PACKLEN	DW	2	; length of packet in bytes
  PACKCPID	DW	?	; code page id
PACKET		       ENDS

