	PAGE	,132				; 					 ;AN000;
;	SCCSID = @(#)ifsfsym.inc 1.0 87/05/11						 ;AN000;

;************************************************************************************
;
; IFSFUNC Symbols
;
; Modification history:
;   Created: MAY 11 1987
;
; LOD = 80 (IFS added)
; REVISION HISTORY:
;	A000	Original version  4.00		  May 1987
;	A001	DCR 188 - design correction of Get IFSFUNC Item 	  8/87 RGAZZIA
;	A002	PTM ??? - 80H bit on Lock functions ignorred		 10/27 FEIGENBAUM
;	A003	PTM 2270- filesys/network attach problem		 11/27 RGAZZIA
;	A004	DCR 285 - remove Extended Attribute/Lock support	  1/88 RGAZZIA
;	A005	PTM 2827- error msg problems				  1/88 RMG
;	A006	PTM 3334- new ifsresetenv call				  2/88 RMG
;	A007	PTM 3657- don't want val code page in flag                2/88 RGazzia
;	A008	PTM 3692- net use xxx /d error msg wrong		  3/88 RGazzia
;	A009	PTM 3673- filesys problems again, undo a003		  3/14/88 RMG
;	A010	PTM 3968- time/date stamping problems			  3/25/88 RMG
;	A011	PTM 4140- INT 2F 5 interface change			  4/12/88 RMG
;	A012	PTM 5006- need save original device ptr - new dfl field   6/02/88 RMG
;
;************************************************************************************
;											 ;AN000;
; Old Redirector Stuff									 ;AN000;
;											 ;AN000;
TRUE	    EQU 0FFFFh									 ;AN000;
FALSE	    EQU 0									 ;AN000;
											 ;AN000;
PATHGEN = TRUE										 ;AN000;
DEBUG = FALSE										 ;AN000;
REDIRECTOR = TRUE									 ;AN000;
Installed = TRUE									 ;AN000;
											 ;AN000;
MSNET_TIMING = FALSE									 ;AN000;
											 ;AN000;
											 ;AN000;
IF1											 ;AN000;
	IF MSNET_TIMING 								 ;AN000;
		%out  MSNET_TIMING version						 ;AN000;
	ENDIF										 ;AN000;
	IF DEBUG									 ;AN000;
		%out  DEBUGGING version 						 ;AN000;
	ENDIF										 ;AN000;
		%out  INSTALLED version 						 ;AN000;
ENDIF											 ;AN000;
; Structures and equates for the network support					 ;AN000;
											 ;AN000;
;Net call interrupt - used to generate critical sections				 ;AN000;
NET_CALL_INT	EQU	2AH								 ;AN000;
											 ;AN000;
;Max size of PRINT_PRE_STRING								 ;AN000;
MAX_PRE_STRING	EQU	64								 ;AN000;
											 ;AN000;
											 ;AN000;
;AH function code for $GET_IN_VARS INT 21 function					 ;AN000;
GET_IN_VAR	EQU	52H								 ;AN000;
											 ;AN000;
											 ;AN000;
; The following EQUates control the replacement of the FCB SFT cache by 		 ;AN000;
;   IFSFUNC. If the current FCB Cache Size,Keepcount is DefNumFCB,DefKeepVal		 ;AN000;
;   then IFSFUNC will set up a new cache of NewNumFCB,NewKeepVal.			 ;AN000;
DefNumFCB	EQU	4								 ;AN000;
DefKeepVal	EQU	0								 ;AN000;
											 ;AN000;
NewNumFCB	EQU    16								 ;AN000;
NewKeepVal	EQU	8								 ;AN000;
											 ;AN000;
SUBTTL	IFSFUNC Data									 ;AN000;
PAGE											 ;AN000;
; miscellaneous IFS equates								 ;AN000;
MINUS_ONE	EQU	-1								 ;AN000;
NULL_PTR	EQU	-1								 ;AN000;
ERROR_INFO_NOT_SET EQU	-1								 ;AN000;
CHECK_REMOVABLE EQU	4408H								 ;AN000;
ICOLON		EQU	":"                                                              ;AN000;
ZERO		EQU	0								 ;AN000;
OLDOPEN_MODE	EQU   2180H								 ;AN000;
OLDOPEN_FLAG	EQU   0101H								 ;AN000;
OLDCREATE_MODE	EQU   0002H								 ;AC007;
OLDCREATE_FLAG	EQU   0112H								 ;AC007;
OLDCREATENEW_FLAG EQU	10H								 ;AN000;
;INT21AL_LOCK_READ    EQU  4								 ;AD004;
;INT21AL_WRITE_UNLOCK EQU  5								 ;AD004;
IFSFINSTALLED	EQU    0FFH								 ;AN000;
GET_TRUNCATE_FLAG EQU	7								 ;AN000;
SET_TRUNCATE_FLAG EQU	8								 ;AN000;
;;;alias COMPLEX  EQU	  4								 ;AN000;
PARSE_ERR_1	EQU	1								 ;AN000;
PARSE_ERR_5	EQU	5								 ;AN000;
PARSE_ERR_6	EQU	6								 ;AN000;
PARSE_ERR_10	EQU	10								 ;AN000;
COMMON_ERR_2	EQU	2								 ;AN000;
COMMON_ERR_3	EQU	3								 ;AN000;
UTIL_ERR_4	EQU	4								 ;AN000;
RETRY		EQU	1								 ;AN000;
I2F5_MsgRet	EQU	2								 ;AN011;
											 ;AN000;
; ifsproc flags 									 ;AN000;
IsCDS		EQU	80H								 ;AN000;
IsSFT		EQU	40H								 ;AN000;
IsSEQ		EQU	20H								 ;AN000;
IsGet		EQU	10H	; vs. set						 ;AN000;
IsOldOpen	EQU	10H								 ;AN000;
IsOldCreate	EQU	08H								 ;AN000;
IsCreate	EQU	8000H	; used in IFS_OPEN in setting sf date/time		 ;AN010;
IsClose 	EQU	10H	; vs. commit						 ;AN000;
IsRen		EQU	10H	; vs. delete						 ;AN000;
;IsLockRead	 EQU	 10H								 ;AD005;
;IsWriteUnlock	 EQU	 08H								 ;AD005;
;IsAdd		 EQU	 04H								 ;AD005;
THISIFS_SET	EQU	02H								 ;AN000;
IsShare 	EQU	80H	; used by auto-attach					 ;AN000;
IsCTLFCN	EQU	01H	; used by IFS_UPDATE_CB@				 ;AN000;
IsCritIFS	EQU	02H	; indicates ifs cs					 ;AN000;
Print_On	EQU	80H	; sess							 ;AN000;
SetDeviceCB	EQU	0100H	; indicates to sft_to_sff to set ifs_device_cb@ 	 ;AN000;
IsDummyCDS	EQU	0200H	; used to indicate dummy cds (AttStrt/CDS-CD)		 ;AN000;
IsNetwork	EQU	0400H	; indicates types 3 or 4 attach 			 ;AN001;
SetBP		EQU	0800H	; set if return lsn					 ;AN001;
Filesys_Status	EQU	1000H	; indicates new style get ifsfunc item			 ;AN001;
;Filesys_Network_Attach EQU 1000H ; flag used to determine if move ptr direct to parms	 ;AN003;;AD009;
;IsWOLock	 EQU	 2000H	 ; write operation only lock - flag moved RMG		 ;AD004;
IsInit		EQU	2000H	; this set in AutoAttach for CI-error area		 ;AN005;
IsResetEnvirn	EQU	4000H	; used in sess - diff abort from reset environment	 ;AN006;
IsMsgRet	EQU	8000H	; used in ifserror - int2f5 to distinguish msg ret	 ;AN011;
				;		     from command.com			 ;AN011;
; ifsfunc flags 									 ;AN000;
UNC_INSTALLED	EQU	80H	; unc file system installed				 ;AN000;
NO_IFS_DRIVERS	EQU	40H	; no ifs drivers installed				 ;AN000;

; ifs semaphores IFSSEM equates 							 ;AN011;
MR_ERRMSG_SEM	EQU	80H	; used by ifserror INT2F AH=5 as gate for msgret entry	 ;AN011;
;											 ;AN000;
; DFL -  This structure stores IFS/NETUSE/ALIAS Device information			 ;AN000;
;	 to IFS driver. 								 ;AN000;

DFLL_LIST	STRUC									 ;AN000;
DFLL_FLAGS	DB	?		  ; Flags					 ;AN000;
DFLL_TYPE	DB	?		  ; 1=IFS, 3=NETUSE, 0=ALIAS			 ;AN000;
DFLL_DEV_NAME	DB	8 DUP (?)	  ; Device name 				 ;AN000;
DFLL_USER_WORD	DW	?		  ; attach user word				 ;AN001;
DFLL_ALIAS_INDEX DW	?		  ; Byte index into alias names list (resv)	 ;AN000;
DFLL_IFS_HDR	DD	?		  ; Pointer to IFSHDR				 ;AN000;
DFLL_FSDA	DB	8 DUP (?)	  ; File System Dependent Data Area		 ;AN000;
DFLL_DEVPTR	DD	?		  ; sft_devptr					 ;AN012;
DFLL_LIST	ENDS									 ;AN000;
											 ;AN000;
; dfl flags										 ;AN000;
DFL_INPROG	EQU	80H		  ; in progress 				 ;AN000;
DFL_INUSE	EQU	40H		  ; in use					 ;AN000;
DFL_PAUSED	EQU	20H		  ; device is paused				 ;AN000;
DFL_DEV_REAL	EQU	10H		  ; device is real				 ;AN000;
											 ;AN000;
; error codes										 ;AN000;
device_not_attached	equ	0FH	  ;						 ;AC008;
fs_driver_not_found	equ	67	  ;						 ;AN000;
error_out_of_structs	equ	56	  ;						 ;AN000;
