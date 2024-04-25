	PAGE	,132				; 					 ;AN000;
;	SCCSID = @(#)ifssess.asm	1.0 87/05/11					 ;AN000;
TITLE	IFSFUNC SESSION ROUTINES - IFS Attach Routines					 ;AN000;
NAME	IFSSESS 									 ;AN000;
;************************************************************************************
;
; IFSSESS
;
; Session related IFS calls    (Session = attachment)
;
;   IFS_ASSOPER
;   RETURN_ASSIGN_MODE
;   SET_ASSIGN_MODE
;   GET_IFSFUNC_ITEM
;   ATTACH_START
;   ATTACH_END
;   IFS_RESET_ENVIRONMENT
;   IFS_ABORT
;   GET_IFS_DRIVER_NAME
;   FIND_IFS_DRIVER
;   AssignOn/AssignOff
;   PrintOn/PrintOff
;   GET_UNC_ITEM_INFO
;
; REVISION HISTORY:
;	A000	Original version  4.00		  May 1987
;	A001	DCR 158 - merge unc info in attach start/status requests  8/87 RGAZZIA
;	A002	DCR 187 - ctrl req renumber, make attach type byte	  8/87 RGAZZIA
;	A003	DCR 188 - design correction of Get IFSFUNC Item 	  8/87 RGAZZIA
;	A004	PTM 764 - Printer attach problems			  8/87 RGAZZIA
;	A005	DCR 213 - SFT Serial Number				  9/87 RGazzia
;	A006	PTM 849 - Printer open problems 			  9/87 RGazzia
;	A007	P242 - IFSFUNC hangs on 2nd install.	  8/87 rg
;	A008	P1244- Net Print problems		  8/87 rg
;	A009	P1411- Net Use erroneous pause		 10/87 rg
;	A010	P2270- Filesys network drive problems	 11/87 RG
;	A011	P2312- Allow Net Use status to show FILESYSed network devices	11/87 RG
;		       Do this via user word: 0001 without password
;					      8001 with password
;	A012	P2307- Critical error problems		 11/87 RG
;	A013	P2379- Filesys status fails without network installed  11/87 RGazzia
;	A014	P2952- dfl problem			 1/88 RG
;	A015	P3251- net trans problem (library.exe)	 1/88 RG
;	A016	P3334- new abort subfunc - reset environment   2/88 RMG
;	A017	P3673- Filesys problems again. A010 not fixed right....3/14/88 RMG
;	A018	Austin deviceless attach problems		       3/29/88 RMG
;	A019	P4188- names=0 problems 			       4/08/88 RMG
;	A020	Austin garbage attach problem			       4/11/88 RMG
;	A021	P4140  dos ext err msgs enhancement		       4/19/88 RMG
;	A022	P4249  filesys problems related to gii bx ret on user stack 4/21/88 RMG
;	A023	P4540  fAssign,fPrint out of swappable area	       4/28/88 RMG
;	A024	P4731  find ifs driver must check for none	       5/4/88  RMG
;	A025	P4839  ctrl ptrsc problems			       5/13/88 RMG
;	A026	P4789  message problems w/no ifs drivers loaded        5/18/88 RMG
;	A027	P4791  Don't overwrite ax on error                     5/19/88 RMG
;	A028	       Error code problems w/no ifs drivers	       5/20/88 RMG
;	A029	       GII error path fixup			       5/24/88 RMG
;	A030	P5005  Print stream problems			       6/1/88  RMG
;
;   LOC - 871
;   LOD -  63
;
;************************************************************************************
											 ;AN000;
.xlist											 ;AN000;
.xcref											 ;AN000;
INCLUDE IFSSYM.INC									 ;AN000;
INCLUDE IFSFSYM.INC									 ;AN000;
INCLUDE DOSSYM.INC									 ;AN000;
INCLUDE DEVSYM.INC									 ;AN000;
.cref											 ;AN000;
.list											 ;AN000;
											 ;AN000;
AsmVars <IBM, Installed, DEBUG> 							 ;AN000;
											 ;AN000;
; define the base code segment of the network support first				 ;AN000;
											 ;AN000;
IFSSEG	SEGMENT BYTE PUBLIC 'IFSSEG'                                                     ;AN000;
IFSSEG	ENDS										 ;AN000;
											 ;AN000;
;											 ;AN000;
; NOTE: We cannot include DOSSEG here because the START seg is not declared		 ;AN000;
;	as PARA aligned in DOSSEG.							 ;AN000;
;											 ;AN000;
											 ;AN000;
START		SEGMENT PARA PUBLIC 'START'                                              ;AN000;
START		ENDS									 ;AN000;
											 ;AN000;
CONSTANTS	SEGMENT WORD PUBLIC 'CONST'                                              ;AN000;
CONSTANTS	ENDS									 ;AN000;
											 ;AN000;
DATA		SEGMENT WORD PUBLIC 'DATA'                                               ;AN000;
DATA		ENDS									 ;AN000;
											 ;AN000;
TABLE		SEGMENT BYTE PUBLIC 'TABLE'                                              ;AN000;
TABLE		ENDS									 ;AN000;
											 ;AN000;
CODE		SEGMENT BYTE PUBLIC 'CODE'                                               ;AN000;
CODE		ENDS									 ;AN000;
											 ;AN000;
LAST		SEGMENT PARA PUBLIC 'LAST'                                               ;AN000;
LAST		ENDS									 ;AN000;
											 ;AN000;
DOSGROUP    GROUP   START,CONSTANTS,DATA,TABLE,CODE,LAST				 ;AN000;
											 ;AN000;
											 ;AN000;
DATA		SEGMENT WORD PUBLIC 'DATA'                                               ;AN000;
	;DOSGROUP Data									 ;AN000;
	Extrn	CurrentPDB:WORD 							 ;AN000;
	Extrn	THISCDS:DWORD								 ;AN000;
	Extrn	CDSAddr:DWORD								 ;AN000;
	Extrn	CDSCount:BYTE								 ;AN000;
	Extrn	MYNAME:BYTE								 ;AN000;
	Extrn	DummyCDS:BYTE								 ;AN000;
	Extrn	sftFCB:DWORD								 ;AN000;
	Extrn	THISSFT:DWORD								 ;AN000;
	Extrn	SysInitTable:BYTE							 ;AN000;
	Extrn	EXIT_TYPE:BYTE								 ;AN000;
	Extrn	IFS_HEADER:DWORD							 ;AN000;
if debug										 ;AN000;
	Extrn	BugLev:WORD								 ;AN000;
	Extrn	BugTyp:WORD								 ;AN000;
	include bugtyp.asm								 ;AN000;
endif											 ;AN000;
DATA		ENDS									 ;AN000;
											 ;AN000;
											 ;AN000;
; define our own code segment								 ;AN000;
											 ;AN000;
IFSSEG	SEGMENT BYTE PUBLIC 'IFSSEG'                                                     ;AN000;
	ASSUME	SS:DOSGROUP,CS:IFSSEG							 ;AN000;
											 ;AN000;
	;IFS Data - external								 ;AN000;
	Extrn	TEMPBUF:BYTE								 ;AN000;
											 ;AN000;
	;IFS Data - public - *** IFSFUNC SWAPPABLE DATA AREA ***			 ;AN000;
											 ;AN000;
PUBLIC	IFSF_SWAP_START 								 ;AN000;
IFSF_SWAP_START      LABEL BYTE 							 ;AN000;
											 ;AN000;
	PUBLIC	THISIFS 								 ;AN000;
THISIFS 	DD	-1								 ;AN000;

	PUBLIC	THISDFL 								 ;AN000;
THISDFL 	DD	-1								 ;AN000;

	PUBLIC	IFSR									 ;AN000;
IFSR		DB	72 DUP (0)							 ;AN000;

	PUBLIC	SFF1									 ;AN000;
SFF1		DB	62 DUP (0)							 ;AN000;

	PUBLIC	CD1									 ;AN000;
CD1		DW	84 DUP (0)							 ;AN000;

	PUBLIC	DF1									 ;AN000;
DF1		DW	18 DUP (0)							 ;AN000;

	PUBLIC	IFSPROC_FLAGS								 ;AN000;
IFSPROC_FLAGS	DW	0								 ;AN000;

; Number of net drive (0=A) for use on net I 24 					 ;AN000;
	PUBLIC	IFSDRV									 ;AN000;
IFSDRV		DB	-1								 ;AN000;

	PUBLIC	DEVICE_CB@_OFFSET							 ;AN000;
; This used to set offset of ifsr_device_cb@ in common routine cds_to_cd		 ;AN000;
; in ifsutil.  If not used, offset always 1EH since that's what it is at                 ;AN000;
; ifsutil assembly time.  This not good for control fcns (attstart,attstat).		 ;AN000;
DEVICE_CB@_OFFSET DW	0			; offset in ifsrh of device cb@ 	 ;AN000;

	PUBLIC	SAVE_CB@								 ;AN000;
; This used by SFT_TO_SFF and SFF_TO_SFT routines in IFSUTIL to save cds ptr.		 ;AN000;
SAVE_CB@	DD	-1								 ;AN000;

	PUBLIC	IFSSEM									 ;AN021;
; This used as byte of semaphores.							 ;AN021;
IFSSEM		DB	0								 ;AN021;

IFSF_SWAP_END	 LABEL	 BYTE								 ;AN000;
PUBLIC	IFSF_SWAP_END									 ;AN000;
											 ;AN000;
	;IFS Data - public								 ;AN000;
											 ;AN000;
	PUBLIC	DFLAddr 								 ;AN000;
DFLAddr 	DD	-1								 ;AN000;

	PUBLIC	DFLCount								 ;AN000;
DFLCount	DB	0								 ;AN000;

;;;aliasPUBLIC	NLAddr									 ;AN000;
;;;aliasNLAddr		DD	-1							 ;AN000;

;;;aliasPUBLIC	NLSIZE									 ;AN000;
;;;aliasNLSIZE		DW	0							 ;AN000;

	PUBLIC	CDSAlt									 ;AN000;
CDSAlt		DD	-1								 ;AN000;

	PUBLIC	UNC_FS_HDR								 ;AN000;
UNC_FS_HDR	DD	-1								 ;AN000;

	PUBLIC	IFSFUNC_FLAGS								 ;AN000;
IFSFUNC_FLAGS	DW	0								 ;AN000;

	PUBLIC	IFS_ATTRS								 ;AN000;
IFS_ATTRS	DW	0			; all ifs_attribute words from ifs	 ;AN000;
						; headers or'ed together (ifsinit)       ;AN000;
	PUBLIC	DOSCALL@								 ;AN000;
DOSCALL@	DD	0			; IFS_DOSCALL@ set by ibmbio		 ;AN000;

	PUBLIC	SFT_SERIAL_NUMBER							 ;AN005;
SFT_SERIAL_NUMBER DW	0			; to get sfts unique for fcb reasons	 ;AN005;

	PUBLIC	fAssign 								 ;AC023;
fAssign 	DB	-1								 ;AC023;

	PUBLIC	fPrint									 ;AC023;
fPrint		DB	-1								 ;AC023;

	PUBLIC	TRUNCATE_FLAG								 ;AC030;moved out of swap
TRUNCATE_FLAG	DB	0								 ;AC030;    "   "


	;IFS Data - local								 ;AN000;
											 ;AN000;
;SetBP		DB	0			; flag indicates whether to return	 ;AD003;
						; LSN on getuncitem call (GII)		 ;AN000;
;ERROR_STATUS	DW	1			; Status returned on error return	 ;AD029;
ERROR_STATUS	DB	"ERROR",0               ; from fs (GII)                          ;AC029;
											 ;AN000;
											 ;AN000;
BREAK <IFS_ASSOPER -- Do the $Assignoper call>						 ;AN000;
											 ;AN000;
copyright	db	" IFSFUNC.EXE                  "                                 ;AN000;
INCLUDE copyrigh.inc

;************************************************************************************	 ;AN000;
;											 ;AN000;
; IFS_ASSOPER										 ;AN000;
;											 ;AN000;
; Called by: IFSFUNC dispatcher 							 ;AN000;
;											 ;AN000;
; Routines called:									 ;AN000;
;	      RETURN_ASSIGN_MODE							 ;AN000;
;	      SET_ASSIGN_MODE								 ;AN000;
;	      GET_IFSFUNC_ITEM								 ;AN000;
;	      ATTACH_START								 ;AN000;
;	      ATTACH_END								 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	AL = 00 get / 01 set - redir assign mode    (Return/Set Mode)			 ;AN000;
;	AL = 02 get attach list entry		    (Get ifsfunc item)			 ;AN000;
;	AL = 03 Define Macro  (attach start)						 ;AN000;
;	AL = 04 Cancel Attach (attach end)						 ;AN000;
;	AL = 05 Revised get assign list entry	    (Getifsfuncitem2)			 ;AN000;
;	AL = 06 Get IFSFUNC Item		    (Getifsfuncitem3)			 ;AN003;
; Function:										 ;AN000;
;	IF	AL=0 call RETURN_ASSIGN_MODE						 ;AN000;
;	ELSE IF AL=1 call SET_ASSIGN_MODE						 ;AN000;
;	ELSE IF AL=2 call GET_IFSFUNC_ITEM						 ;AN000;
;	ELSE IF AL=3 call ATTACH_START							 ;AN000;
;	ELSE IF AL=4 call ATTACH_END							 ;AN000;
;											 ;AN000;
; Outputs:										 ;AN000;
;	see subroutines 								 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
AO_TABLE LABEL	WORD									 ;AN000;
	DW	RETURN_ASSIGN_MODE							 ;AN000;
	DW	SET_ASSIGN_MODE 							 ;AN000;
	DW	GET_IFSFUNC_ITEM							 ;AN000;
	DW	ATTACH_START								 ;AN000;
	DW	ATTACH_END								 ;AN000;
	DW	GET_IFSFUNC_ITEM2							 ;AN000;
	DW	GET_IFSFUNC_ITEM3							 ;AN003;
											 ;AN000;
	Procedure   IFS_ASSOPER,NEAR							 ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING								 ;AN000;
											 ;AN000;
	TEST	CS:IFSFUNC_FLAGS,no_ifs_drivers
	JZ	AO_20
AO_10:
	MOV	AX,error_not_supported
	transfer ifs_980
AO_20:
	CMP	AL,0
	JNE	AO_40
	CMP	AL,1
	JNE	AO_40
	TEST	CS:IFSFUNC_FLAGS,unc_installed
	JZ	AO_10
AO_40:
	MOV	CS:IFSPROC_FLAGS,ZERO							 ;AN000;
	PUSH	BX				; save macro type			 ;AN000;
	XOR	AH,AH									 ;AN000;
	SHL	AL,1				; AL x 2				 ;AN000;
	MOV	BX,AX									 ;AN000;
	JMP	CS:AO_TABLE[BX] 							 ;AN000;
											 ;AN000;
EndProc IFS_ASSOPER									 ;AN000;
											 ;AN000;
BREAK <RETURN_ASSIGN_MODE -- Return Assign Mode>					 ;AN000;
											 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; RETURN_ASSIGN_MODE									 ;AN000;
;											 ;AN000;
; Called by:  IFS_ASSOPER								 ;AN000;
;											 ;AN000;
; Routines called:	DOS: Get_User_Stack						 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	    BL = macro type								 ;AN000;
; Function:										 ;AN000;
;	If macro type = 3 (network printer) THEN					 ;AN000;
;	   BX = fPrint .AND. 1								 ;AN000;
;	Elseif macro type = 4 (network disk) THEN					 ;AN000;
;	   BX = fAssign .AND. 1 							 ;AN000;
;	Else set error_invalid_function 						 ;AN000;
;											 ;AN000;
; Output:										 ;AN000;
;	IF AL==0 BX value on user stack 						 ;AN000;
;											 ;AN000;
; Notes:  This routine is used only for UNC file system.  This is the			 ;AN000;
;	  only FS that supports pause.							 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
	Procedure   RETURN_ASSIGN_MODE,NEAR						 ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING								 ;AN000;
											 ;AN000;
	POP	BX			; macro type					 ;AN000;
	CMP	BL,3			; if (type == drive)				 ;AN000;
	JZ	GAM_20									 ;AN000;
	CMP	BL,4									 ;AN000;
	JNZ	GAM_60									 ;AN000;
	MOV	BH,fAssign		;    t = fAssign;				 ;AN000;
	JMP	Short GAM_40		; else						 ;AN000;
											 ;AN000;
GAM_20: 				; if (type == print)				 ;AN000;
	MOV	BH,fPrint		;    t = fPrint;				 ;AN000;
GAM_40: 										 ;AN000;
	AND	BH,1			;   return t&1; 				 ;AN000;
	CallInstall Get_User_Stack,multDOS,24						 ;AN000;
	MOV	[SI].User_BX,BX 							 ;AN000;
	transfer ifs_990		; go to general good ret in util		 ;AN000;
											 ;AN000;
GAM_60: 										 ;AN000;
	MOV	AL,error_invalid_function						 ;AN000;
	transfer ifs_980		; go to general bad ret in util 		 ;AN000;
											 ;AN000;
											 ;AN000;
EndProc RETURN_ASSIGN_MODE								 ;AN000;
											 ;AN000;
BREAK <SET_ASSIGN_MODE -- set assign mode>						 ;AN000;
											 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; SET_ASSIGN_MODE									 ;AN000;
;											 ;AN000;
; Called by: IFS_ASSOPER								 ;AN000;
;											 ;AN000;
; Routines called:									 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	    BL = macro type								 ;AN000;
;	    BH = assign mode   (0 = off - pause, 1 = on - no pause)			 ;AN000;
;											 ;AN000;
; Function:										 ;AN000;
;											 ;AN000;
; Output:										 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
	Procedure   SET_ASSIGN_MODE,NEAR						 ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING								 ;AN000;
											 ;AN000;
	POP	BX			; restore macro type (3 or 4)			 ;AN000;
											 ;AN000;
	CMP	BL,3			; check if printer or drive			 ;AN000;
	JNZ	SAM_40			;						 ;AN000;
	OR	BH,BH			; printer - check mode				 ;AN000;
	JZ	SAM_20			; off - go pause				 ;AN000;
	CMP	BH,1									 ;AN000;
	JNZ	SAM_80			; jump on parm error				 ;AN000;
	CALL	PrintOn 		; turn print on 				 ;AN000;
	transfer ifs_990		; go to general good ret in util		 ;AN000;
											 ;AN000;
SAM_20: 				; print off - pause				 ;AN000;
	CALL	PrintOff								 ;AN000;
	transfer ifs_990		; go to general good ret in util		 ;AN000;
											 ;AN000;
SAM_40: 				; Drive 					 ;AN000;
	CMP	BL,4									 ;AN000;
	JNZ	SAM_80			; jump on parm error				 ;AN000;
	OR	BH,BH									 ;AN000;
	JZ	SAM_60									 ;AN000;
	CMP	BH,1									 ;AN000;
	JNZ	SAM_80			; jump on parm error				 ;AN000;
	CALL	AssignOn		; drive on					 ;AN000;
	transfer ifs_990		; go to general good ret in util		 ;AN000;
											 ;AN000;
SAM_60: 				; drive off					 ;AN000;
	invoke	AssignOff		; turn drives off (pause)			 ;AN000;
	transfer ifs_990		; go to general good ret in util		 ;AN000;
											 ;AN000;
											 ;AN000;
SAM_80: 										 ;AN000;
	MOV	AX,error_invalid_parameter						 ;AN000;
	invoke	SET_EXTERR_INFO 							 ;AN000;
	transfer ifs_980		; go to general bad ret in util 		 ;AN000;
											 ;AN000;
											 ;AN000;
EndProc SET_ASSIGN_MODE 								 ;AN000;
											 ;AN000;
BREAK <GET_IFSFUNC_ITEM -- for get attach list >					 ;AN000;
											 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; GET_IFSFUNC_ITEM									 ;AN000;
;											 ;AN000;
; Called by: IFS_ASSOPER								 ;AN000;
;											 ;AN000;
; Routines called:									 ;AN000;
;	     GET_IFS_DRIVER_NAME	DOS: STRCPY					 ;AN000;
;	     CDS_TO_CD			     GET_USER_STACK				 ;AN000;
;	     DFL_TO_DF									 ;AN000;
;	     CALL_IFS									 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	    BL = redirection index							 ;AN000;
;	    DS:SI -> Device name buffer 						 ;AN000;
;	    ES:DI -> Target buffer:  old - net path string			   ;AN000;
;				     new - dw file system driver name
;					   dw # parms
;					   db parms
; Function:										 ;AN000;
;	     STRUCTURE = 1st CDS							 ;AN000;
;	     INDEX = 0									 ;AN000;
;	     WHILE CDS structures							 ;AN000;
;	       DO									 ;AN000;
;		 IF curdir_isIFS TRUE THEN						 ;AN000;
;		    DO									 ;AN000;
;		      IF INDEX = BL THEN						 ;AN000;
;			DO								 ;AN000;
;			  DS:SI   = Letter version of Index (0=A:, 1=B:, ...)		 ;AN000;
;			  IF IFS .NOT. UNC THEN 					 ;AN000;
;			    DO								 ;AN000;
;			      ES:[DI] = IFS name  (retrieved from CURDIR_IFSR_HDR)	 ;AN000;
;			      Send ATTACH_STAT request to IFS for parms 		 ;AN000;
;			      ES:DI+2 = IFS parms					 ;AN000;
;			      FOUND = true						 ;AN000;
;			      TYPE = 2							 ;AN000;
;			      LEAVE WHILE						 ;AN000;
;			    ENDDO							 ;AN000;
;			  ELSE DO							 ;AN000;
;				 Send ATTACH_STAT request to REDIR.SYS for parms	 ;AN000;
;				 Move parms into one buffer and point with ES:DI	 ;AN000;
;				 FOUND = true						 ;AN000;
;				 TYPE = 4						 ;AN000;
;				 LEAVE WHILE						 ;AN000;
;			       ENDDO							 ;AN000;
;		      ELSE DO								 ;AN000;
;			     IF IFS UNC THEN						 ;AN000;
;			       DO							 ;AN000;
;				 INDEX=INDEX+1						 ;AN000;
;				 IF INDEX = BL THEN					 ;AN000;
;				    DO							 ;AN000;
;				      DS:SI   = Letter version of Index (0=A:, 1=B:,	 ;AN000;
;				      ES:DI = "REDIR"                                    ;AN000;
;				      FOUND = true					 ;AN000;
;				      TYPE  = 2 					 ;AN000;
;				      LEAVE WHILE					 ;AN000;
;				    ENDDO						 ;AN000;
;				 ENDIF							 ;AN000;
;			       ENDDO							 ;AN000;
;			     ENDIF							 ;AN000;
;			   ENDDO							 ;AN000;
;		      ENDIF								 ;AN000;
;		    ENDDO								 ;AN000;
;		 ENDIF									 ;AN000;
;		 Get next CDS structure 						 ;AN000;
;	       ENDDO									 ;AN000;
;	     ENDWHILE									 ;AN000;
;	     IF FOUND = false THEN							 ;AN000;
;		DO									 ;AN000;
;		  STRUCTURE = 1st DFL							 ;AN000;
;		  WHILE DFL structures							 ;AN000;
;		    DO									 ;AN000;
;		      IF INDEX = BL THEN						 ;AN000;
;			 DO								 ;AN000;
;			   DS:SI = name pointed to by DFLL_NAME_PTR			 ;AN000;
;			   IF IFS .NOT. UNC THEN					 ;AN000;
;			     DO 							 ;AN000;
;			       ES:[DI] = IFS name  (retrieved from DFLL_IFSR_HDR)	 ;AN000;
;			       Send ATTACH_STAT request to IFS for parms		 ;AN000;
;			       ES:DI+2 = IFS parms					 ;AN000;
;			       FOUND = true						 ;AN000;
;			       TYPE = 1 						 ;AN000;
;			       LEAVE WHILE						 ;AN000;
;			     ENDDO							 ;AN000;
;			   ELSE DO							 ;AN000;
;				  Send ATTACH_STAT request to REDIR.SYS for parms	 ;AN000;
;				  Move parms into one buffer and point with ES:DI	 ;AN000;
;				  FOUND = true						 ;AN000;
;				  TYPE = 3						 ;AN000;
;				  LEAVE WHILE						 ;AN000;
;				ENDDO							 ;AN000;
;		      ELSE DO								 ;AN000;
;			     IF IFS UNC THEN						 ;AN000;
;				DO							 ;AN000;
;				  INDEX=INDEX+1 					 ;AN000;
;				  IF INDEX = BL THEN					 ;AN000;
;				     DO 						 ;AN000;
;				       ES:DI = "REDIR"                                   ;AN000;
;				       FOUND = true					 ;AN000;
;				       TYPE  = 3					 ;AN000;
;				       LEAVE WHILE					 ;AN000;
;				     ENDDO						 ;AN000;
;				  ENDIF 						 ;AN000;
;				ENDDO							 ;AN000;
;			     ENDIF							 ;AN000;
;			   ENDDO							 ;AN000;
;		      ENDIF								 ;AN000;
;		      Get next DFL structure						 ;AN000;
;		    ENDWHILE								 ;AN000;
;		ENDDO									 ;AN000;
;	     ENDIF									 ;AN000;
;	     IF FOUND = FALSE THEN							 ;AN000;
;		DO									 ;AN000;
;		  Set carry								 ;AN000;
;		  AX = 18								 ;AN000;
;		ENDDO									 ;AN000;
;	     ELSE Clear carry								 ;AN000;
;	     ENDIF									 ;AN000;
;
;	     IFSRH for Attach Start:
;	       *  IFSR_LENGTH	   DW	  32	   ; Request length
;	       *  IFSR_FUNCTION    DB	   3	   ; Attach Start
;		+ IFSR_RETCODE	   DW	   0
;		+ IFSR_RETCLASS    DB	   ?
;		  IFSR_RESV1	   DB	  16 DUP(0)
;		+ IFSR_TYPE	   DB	   ?	   ; BL (1,2,3,or 4)
;		  IFSR_RESV2	   DB	   ?
;	       *+ IFSR_PARMS@	   DD	   PARMS   ; See below
;	       *+ IFSR_DEVICE_CB@  DD	   ?	   ; CD or DF (See below)
;		+ IFSR_USER_WORD   DW	   ?
;		+ IFSR_MAX_XMITT_SIZE DW   ?
;		+ IFSR_NET_NAME_ID DW	   ?
;		+ IFSR_LSN	   DW	   ?
;		+ IFSR_DEVICE_STATUS  DB   ?
;		  IFSR_RESV3	   DB	   ?
;
;
;
;	       *+ PARMS 	  LABEL   WORD
;				  DW	  PARMCOUNT ; Number of parms. (only for new style)
;				  DB	  ASCIIZ,...; Parms
;
;											 ;AN000;
; Outputs:										 ;AN000;
;	 No Carry - BH = device status flag						 ;AN000;
;			 bit 0=0 is device valid					 ;AN000;
;			       1 if device invalid					 ;AN000;
;		    BL = device type							 ;AN000;
;		    DS:SI = ASCIIZ local device name					 ;AN000;
;		    ES:DI = ASCIIZ network name 					 ;AN000;
;		For old style call:
;		    CX = user word							 ;AN000;
;		    DX = max xmitt size
;		    BP = Low 8 bits has LSN from NCB_LIST if input AL ^=0
;		    AX = Net name ID
;
;	 Carry	  - AX = Error code							 ;AN000;
;			 18 - end of list						 ;AN000;
; Regs: 										 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
	USER_WORD	DW	0		; i give in - temp storage
											 ;AN000;
	Procedure   GET_IFSFUNC_ITEM							 ;AC003;
ASSUME	DS:NOTHING,ES:NOTHING								 ;AC003;
						; get_ifsfunc_item and get_ifsfunc_item2 ;AC003;
	MOV	CS:IFSPROC_FLAGS,ZERO		; are old style - types 3,4 only	 ;AC003;
	JMP	SHORT GII_20								 ;AC003;
											 ;AC003;
	entry	GET_IFSFUNC_ITEM2							 ;AC003;
	MOV	CS:IFSPROC_FLAGS,SetBP		; set this to get lsn			 ;AC003;
	JMP	SHORT GII_20								 ;AC003;
											 ;AC003;
	entry	GET_IFSFUNC_ITEM3		; new style get ifsfunc item		 ;AC003;
	MOV	CS:IFSPROC_FLAGS,Filesys_Status ; gets types 1,2,3,4			 ;AC003;
											 ;AC003;
;----------------------------------------------------------------------------------------;AC003;
;   drive  loop 									 ;AC003;
;----------------------------------------------------------------------------------------;AC003;
											 ;AC003;
GII_20: 										 ;AC003;
	ifsr_fcn_def  ATTSTAT			; define ifsr for attach status 	 ;AC003;
	MOV	CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@					 ;AN006;
											 ;AC003;
	POP	BX				; index 				 ;AC003;
	XOR	AX,AX				; ax will be counter through CDSs	 ;AC003;
	SaveReg <DS,SI> 			; save device/drive name buffer 	 ;AC003;
GII_40: 										 ;AC003;
	CMP	AL,SS:[CDSCount]		; if run out of CDSs,			 ;AC003;
	JB	GII_60				;    go to devices			 ;AC003;
	XOR	AL,AL				; reset for dfl count			 ;AC003;
	JMP	GII_400 								 ;AC003;
GII_60: 										 ;AC003;
	SaveReg <BX,AX> 			; save ax-cds count, bx-index		 ;AC003;
											 ;AC003;
	LDS	SI,[CDSAddr]			; Point ds:si to correct CDS entry	 ;AC003;
	CMP	[fAssign],ZERO			; if pause in effect, must use		 ;AC003;
	JNZ	GII_80				; alternate cds list			 ;AC003;
	LDS	SI,[CDSAlt]								 ;AC003;
											 ;AC003;
GII_80: 										 ;AC003;
	MOV	BL,SIZE CurDir_list		; size in convenient spot		 ;AC003;
	MUL	BL				; get net offset			 ;AC003;
	ADD	SI,AX				; convert to true pointer		 ;AC003;
	RestoreReg  <AX,BX>								 ;AC003;
	TEST	[SI].curdir_flags,curdir_isnet	; make sure ifs drive			 ;AC003;
	JNZ	GII_100 								 ;AC003;
	JMP	GII_280 			; next drive				 ;AC003;
GII_100:										 ;AC003;
	SUB	BX,1				; jae jumps if CF=0, CF=1 when		 ;AC003;
						; index hit				 ;AC003;
	JB	GII_120 								 ;AC003;
	JMP	GII_280 			; next drive				 ;AC003;
GII_120:										 ;AC003;
	TEST	CS:IFSPROC_FLAGS,Filesys_Status ; check old vs. new style		 ;AC003;
	JNZ	GII_140 								 ;AC003;
	CMP	[SI.CURDIR_TYPE],TYPE_NET_DRIVE ; old style: check for type 4		 ;AC003;
	JE	GII_140 								 ;AC003;
	JMP	GII_280 			; not type 4, go get next one		 ;AC003;
GII_140:										 ;AC003;
	RestoreReg  <DX,CX>			; get devname ptr into es:di,		 ;AC003;
	SaveReg <CX,DX> 			; (push back for end ds:si setup)	 ;AC003;
	SaveReg <ES,DI> 			;   while preserving es:di - target	 ;AC003;
	MOV	ES,CX									 ;AC003;
	MOV	DI,DX									 ;AC003;
	ADD	AL,'A'                          ; storing d:0 in devname buffer          ;AC003;
	STOSB										 ;AC003;
	MOV	AX,(0 SHL 8) + ':'                                                       ;AC003;
	STOSW										 ;AC003;
	RestoreReg <DI,ES>			; restore target ptr			 ;AC003;
											 ;AC003;
	MOV	BL,[SI.CURDIR_TYPE]		; set bx=type (1,2,3,4) 		 ;AC003;
	XOR	BH,BH									 ;AC003;
	TEST	CS:IFSPROC_FLAGS,Filesys_status ; target different for new style	 ;AC003;
	JNZ	GII_150 								 ;AC003;
	PUSH	[SI.CURDIR_USER_WORD]							 ;AC003;
	POP	CS:[USER_WORD]								 ;AC003;
	JMP	GII_160 								 ;AC003;
GII_150:										 ;AC003;
	PUSH	DI				; ifs drive; save target offset 	 ;AC003;
	MOV	DI,ES:[DI]			; es:di -> FS name buffer		 ;AC003;
	OR	IFSPROC_FLAGS,ISCDS		; get ifs driver name into target	 ;AC003;
	CALL	GET_IFS_DRIVER_NAME							 ;AC003;
											 ;AC003;
	POP	DI				; retrieve target offset from stack	 ;AC003;
	PUSH	DI									 ;AC003;
	INC	DI				; es:di -> parm buffer			 ;AC003;
	INC	DI									 ;AC003;
											 ;AC003;
GII_160:										 ;AC003;
	SaveReg <ES,BX> 			; save target segment, type		 ;AC003;
						; go to IFS to fill in rest of tgt	 ;AC003;
	invoke	PREP_IFSR			; init ifsr				 ;AC003;
											 ;AC003;
	MOV	DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@					 ;AC003;
	invoke	CDS_TO_CD			; CDS: sets [THISIFS]			 ;AC003;
						;	    ES:BX -> IFSRH		 ;AC003;
						;	    IFSR_DEVICE_CB@		 ;AC003;
						;	    ds - IFSSEG 		 ;AC003;
	MOV	ES:[BX.IFSR_LENGTH],LENGTH_ATTSTAT					 ;AC003;
	MOV	ES:[BX.IFSR_FUNCTION],IFSATTSTAT					 ;AC003;
	POP	AX				; type (BX)				 ;AC003;
	MOV	ES:[BX.IFSR_TYPE],AL							 ;AC003;
	POP	DX				; target segment (ES)			 ;AC003;
											 ;AC003;
	TEST	IFSPROC_FLAGS,Filesys_status						 ;AC003;
	JNZ	GII_180 								 ;AC003;
	PUSH	CS									 ;AC003;
	POP	DS									 ;AC003;
ASSUME	DS:IFSSEG									 ;AC003;
	MOV	SI,OFFSET TEMPBUF							 ;AC003;
	MOV	WORD PTR ES:[BX.IFSR_PARMS@],SI 					 ;AC003;
	MOV	WORD PTR ES:[BX.IFSR_PARMS@+2],DS					 ;AC003;
	PUSH	DI				; push tgt offset here for later pop	 ;AC003;
	JMP	GII_200 								 ;AC003;
GII_180:										 ;AC003;
	MOV	WORD PTR ES:[BX.IFSR_PARMS@],DI 					 ;AC003;
	MOV	WORD PTR ES:[BX.IFSR_PARMS@+2],DX					 ;AC003;
GII_200:										 ;AC003;
	PUSH	AX				; push type back (BX)			 ;AC003;
											 ;AC003;
;***********************************************************************************************
	invoke	CALL_IFS			; call fs with attach status request	 ;AC003;
;***********************************************************************************************
											 ;AC003;
	JNC	GII_220 								 ;AC003;
						; attach status error:			 ;AC003;
	RestoreReg <BX,DI>			; type,target offset			 ;AC003;
	MOV	ES,DX									 ;AC003;
	SaveReg <DI>				; put "ERROR" in parms display           ;AC003;
	TEST	CS:IFSPROC_FLAGS,Filesys_status ; don't add  if net use                  ;AN029;
	JZ	GII_210 								 ;AN029;
	ADD	DI,2									 ;AC003;
	MOV	AX,1									 ;AC003;
	STOSW										 ;AC003;
GII_210:										 ;AN029;
	PUSH	CS									 ;AC003;
	POP	DS									 ;AC003;
ASSUME	DS:IFSSEG									 ;AC003;
	MOV	SI,OFFSET ERROR_STATUS							 ;AC003;
	MOV	CX,4									 ;AC003;
	REP	MOVSW									 ;AC003;
	RestoreReg <DI,SI,DS>								 ;AC003;;AC029;
	transfer ifs_1000			; go to general ret in util		 ;AC003;
											 ;AC003;
GII_220:										 ;AC003;
	RestoreReg <AX,DI>			; device type, target offset		 ;AC003;
	TEST	IFSPROC_FLAGS,Filesys_status						 ;AC003;
	JZ	GII_240 								 ;AC003;
;;;;;;;;RestoreReg <SI,DS>			; IFS drive - devname ptr		 ;AC003;;AD022;
;	MOV	ES,DX				; target				 ;AC003;;AD022;
;	MOV	BX,AX									 ;AC003;;AD022;
;;;;;;;;transfer ifs_1000								 ;AC003;;AD022;
	JMP	GII_630 			; want user bx set			 ;AN022;
											 ;AC003;
GII_240:					; NET drive:				 ;AC003;
	JMP	GII_640 			; go down to net device processing-	 ;AC003;
						; does the same thing			 ;AC003;
GII_280:										 ;AC003;
	INC	AX				; next drive				 ;AC003;
	JMP	GII_40									 ;AC003;
											 ;AC003;
;----------------------------------------------------------------------------------------;AC003;
;   device loop 									 ;AC003;
;----------------------------------------------------------------------------------------;AC003;
											 ;AC003;
GII_400:					; Device loop				 ;AC003;
	CMP	AL,CS:[DFLCount]		; if run out of devices 		 ;AC003;
	JB	GII_460 								 ;AC003;
	JMP	GII_800 			;    go set no_more error		 ;AC003;
GII_460:										 ;AC003;
	SaveReg <BX,AX> 			; save ax-dfl count, bx-index		 ;AC003;
	LDS	SI,CS:[DFLAddr] 		; Point ds:si to correct DFL entry	 ;AC003;
	MOV	BL,SIZE DFLL_list		; size in convenient spot		 ;AC003;
	MUL	BL				; get net offset			 ;AC003;
	ADD	SI,AX				; convert to true pointer		 ;AC003;
	RestoreReg  <AX,BX>								 ;AC003;
	TEST	[SI.DFLL_FLAGS],DFL_INUSE	; is dfl active???			 ;AC003;
	JNZ	GII_480 								 ;AC003;
	JMP	GII_680 								 ;AC003;
GII_480:										 ;AC003;
	TEST	CS:IFSPROC_FLAGS,Filesys_Status ; check old vs. new style		 ;AC003;
	JNZ	GII_520 								 ;AC003;
	CMP	[SI.DFLL_TYPE],TYPE_NET_DEVICE	; old style: check for type 3		 ;AC003;
	JE	GII_520 								 ;AC003;
	JMP	GII_680 			; not type 4, go get next one		 ;AC003;
GII_520:										 ;AC003;
	SUB	BX,1									 ;AC003;
	JB	GII_540 								 ;AC003;
	JMP	GII_680 			; next device				 ;AC003;
GII_540:										 ;AC003;
	MOV	WORD PTR CS:[THISDFL],SI	; set thisdfl = dssi			 ;AN014;
	PUSH	DS									 ;AN014;
	POP	WORD PTR CS:[THISDFL+2] 						 ;AN014;
	RestoreReg  <DX,CX>			; get devname ptr into es:di,		 ;AC003;
	SaveReg <CX,DX> 			; (push back for end ds:si setup)	 ;AC003;
	SaveReg <ES,DI> 			;   while preserving es:di - target	 ;AC003;
	MOV	ES,CX									 ;AC003;
	MOV	DI,DX									 ;AC003;
	PUSH	SI				; save DFL offset			 ;AC003;
	ADD	SI,DFLL_DEV_NAME 							 ;AC003;
	MOV	CX,8									 ;AC003;
GII_545:					; store device name in asciiz format	 ;AC003;
	LODSB										 ;AC003;
	CMP	AL," "                                                                   ;AC003;
	JE	GII_550 								 ;AC003;
	STOSB										 ;AC003;
	LOOP	GII_545 								 ;AC003;
GII_550:										 ;AC003;
	XOR	AL,AL									 ;AC003;
	STOSB										 ;AC003;
	RestoreReg <SI,DI,ES>			; restore target ptr & DFL offset	 ;AC003;
											 ;AC003;
	MOV	BL,[SI.DFLL_TYPE]							 ;AC003;
	XOR	BH,BH									 ;AC003;
	TEST	CS:IFSPROC_FLAGS,Filesys_Status 					 ;AC003;
	JNZ	GII_555 								 ;AC003;
	PUSH	[SI.DFLL_USER_WORD]							 ;AC003;
	POP	[USER_WORD]								 ;AC003;
	JMP	GII_560 								 ;AC003;
GII_555:										 ;AC003;
	PUSH	DI				; ifs device; save target offset	 ;AC003;
	MOV	DI,ES:[DI]			; es:di -> FS name buffer		 ;AC003;
	invoke	GET_IFS_DRIVER_NAME							 ;AC003;
											 ;AC003;
	POP	DI				; retrieve target offset from stack	 ;AC003;
	PUSH	DI									 ;AC003;
	INC	DI				; es:di -> parm buffer			 ;AC003;
	INC	DI									 ;AC003;
											 ;AC003;
GII_560:										 ;AC003;
	SaveReg <ES,BX> 			; save target segment, type		 ;AC003;
						; now go to IFS to fill in rest of target;AC003;
	invoke	PREP_IFSR			; init ifsr				 ;AC003;
	invoke	DFL_TO_DF			; DFL: sets [THISIFS]			 ;AC003;
						;	    ES:BX -> IFSRH		 ;AC003;
						;	    IFSR_DEVICE_CB@		 ;AC003;
						;	    ds - IFSSEG 		 ;AC003;
	MOV	ES:[BX.IFSR_LENGTH],LENGTH_ATTSTAT					 ;AC003;
	MOV	ES:[BX.IFSR_FUNCTION],IFSATTSTAT					 ;AC003;
	POP	AX				; type (BX)				 ;AC003;
	MOV	ES:[BX.IFSR_TYPE],AL							 ;AC003;
	POP	DX				; target segment (ES)			 ;AC003;
											 ;AC003;
	TEST	CS:IFSPROC_FLAGS,Filesys_Status 					 ;AC003;
	JNZ	GII_580 								 ;AC003;
	PUSH	CS									 ;AC003;
	POP	DS									 ;AC003;
ASSUME	DS:IFSSEG									 ;AC003;
	MOV	SI,OFFSET TEMPBUF							 ;AC003;
	MOV	WORD PTR ES:[BX.IFSR_PARMS@],SI 					 ;AC003;
	MOV	WORD PTR ES:[BX.IFSR_PARMS@+2],DS					 ;AC003;
	PUSH	DI				; push tgt offset here for later pop	 ;AC003;
	JMP	GII_600 								 ;AC003;
GII_580:										 ;AC003;
	MOV	WORD PTR ES:[BX.IFSR_PARMS@],DI 					 ;AC003;
	MOV	WORD PTR ES:[BX.IFSR_PARMS@+2],DX					 ;AC003;
GII_600:										 ;AC003;
	PUSH	AX				; push type back (BX)			 ;AC003;
											 ;AC003;
;***********************************************************************************************
	invoke	CALL_IFS			; call fs with attach status request	 ;AC003;
;***********************************************************************************************
											 ;AC003;
	JNC	GII_620 								 ;AC003;
	RestoreReg <BX,DI>			; type,target offset,devname ptr	 ;AC003;
	MOV	ES,DX				; target				 ;AC003;
	SaveReg <DI>				; put "ERROR" in parms display           ;AC003;
	TEST	CS:IFSPROC_FLAGS,Filesys_status ; don't add  if net use                  ;AN029;
	JZ	GII_610 								 ;AN029;
	ADD	DI,2									 ;AC003;
	MOV	AX,1									 ;AC003;
	STOSW										 ;AC003;
GII_610:										 ;AN029;
	PUSH	CS									 ;AC003;
	POP	DS									 ;AC003;
ASSUME	DS:IFSSEG									 ;AC003;
	MOV	SI,OFFSET ERROR_STATUS							 ;AC003;
	MOV	CX,4									 ;AC003;
	REP	MOVSW									 ;AC003;
	RestoreReg <DI,SI,DS>								 ;AC003;;AC027;
	transfer ifs_1000			; go to general ret in util		 ;AC003;
											 ;AC003;
GII_620:										 ;AC003;
	RestoreReg <AX,DI>			; device type, target offset		 ;AC003;
	TEST	IFSPROC_FLAGS,Filesys_Status						 ;AC003;
	JZ	GII_640 			; IFS device:				 ;AC003;
GII_630:										 ;AN022;
	CallInstall Get_User_Stack,MULTdos,24,<AX>,<AX> 				 ;AN022;
	MOV	AH,ES:[BX.IFSR_DEVICE_STATUS]						 ;AN022;
	MOV	[SI].USER_BX,AX 							 ;AN022;
	RestoreReg <SI,DS>			; target offset,devname ptr		 ;AC003;
	MOV	ES,DX				; target				 ;AC003;
;;;;;;;;MOV	BX,AX									 ;AC003;;AD022;
	transfer ifs_1000								 ;AC003;
											 ;AC003;
GII_640:					; NET device:				 ;AC003;
	CallInstall Get_User_Stack,multDOS,24,<AX>,<AX> 				 ;AC003;
	PUSH	CS:[USER_WORD]							 ;AC003;
	POP	[SI].User_CX		; User Word					 ;AC003;
	PUSH	ES:[BX.IFSR_MAX_XMITT_SIZE]						 ;AC003;
	POP	[SI].User_DX		; Max Xmitt size				 ;AC003;
	PUSH	ES:[BX.IFSR_NET_NAME_ID]					      ;AC003/AC008/AC009
	PUSH	ES:[BX.IFSR_NET_NAME_ID] ; leave this on stack for later pop into ax	 ;AC009;
	POP	[SI].User_AX		; Net name ID					 ;AC003/AC008;
;;;;;;;;PUSH	AX									 ;AN008/AD009;

	MOV	CH,ES:[BX.IFSR_DEVICE_STATUS]						 ;AC003;
	MOV	CL,AL									 ;AC003;
	MOV	[SI].User_BX,CX 	; Bits and macro type				 ;AC003;
	TEST	CS:IFSPROC_FLAGS,SetBP							 ;AC003;
	JZ	GII_660 								 ;AC003;
	PUSH	ES:[BX.IFSR_LSN]							 ;AC003;
	POP	[SI].User_BP		; LSN						 ;AC003;
GII_660:										 ;AC003;
	MOV	SI,ES:WORD PTR [BX.IFSR_PARMS@] 					 ;AC003;
	MOV	DS,ES:WORD PTR [BX.IFSR_PARMS@+2]					 ;AC003;
	INC	SI				; ds:si -> parms returned by redir	 ;AC003;
	INC	SI									 ;AC003;
	MOV	ES,DX				; es:di -> input target buffer		 ;AC003;
	SaveReg <DI>				; save offset				 ;AC003;
	CallInstall StrCpy,MultDOS,17							 ;AC003;
	RestoreReg <DI,AX,SI,DS>		; tgt offset,netpath id,devname ptr	 ;AC003/AC008;
	transfer ifs_990								 ;AC003;
											 ;AC003;
GII_680:										 ;AC003;
	INC	AX				; next drive				 ;AC003;
	JMP	GII_400 								 ;AC003;
											 ;AC003;
											 ;AC003;
GII_800:					; end of CDSs & devices 		 ;AC003;
						; now check deviceless attaches 	 ;AC003;
;----------------------------------------------------------------------------------------;AC003;
;   deviceless loop									 ;AC003;
;----------------------------------------------------------------------------------------;AC003;
											 ;AC003;
	CALL	GET_UNC_ITEM_INFO							 ;AC003;
	JC	GII_820 								 ;AC003;
	RestoreReg <SI,DS>			; set dev ptr null			     ;AC003;
	MOV	BYTE PTR DS:[SI],ZERO							 ;AC003;
	transfer ifs_990								 ;AC003;
GII_820:										 ;AC003;
	MOV	AX,error_no_more_files							 ;AC003;
	RestoreReg <SI,DI>			; restore regs				 ;AC003;
											 ;AC003;
	return										 ;AC003;
											 ;AC003;
EndProc GET_IFSFUNC_ITEM								 ;AC003;
											 ;AN000;
											 ;AN000;
BREAK <ATTACH_START -- Attach drive/device to IFS>					 ;AN000;
											 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; ATTACH_START										 ;AN000;
;											 ;AN000;
; Called by: IFS_ASSOPER								 ;AN000;
;											 ;AN000;
; Routines called:  CALL_IFS		DOS: GetCDSFromDrv				 ;AN000;
;		    CDS_TO_CD								 ;AN000;
;		    CD_TO_CDS								 ;AN000;
;		    CREATE_DFL_ENTRY							 ;AN000;
;		    DELETE_DFL_ENTRY							 ;AN000;
;		    DFL_MATCH								 ;AN000;
;		    DFL_TO_DF								 ;AN000;
;		    DF_TO_DFL								 ;AN000;
;		    CALL_IFS								 ;AN000;
;		    FIND_IFS_DRIVER							 ;AN000;
;;; alias	    PROCESS_ALIAS							 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	    BL = Macro type								 ;AN000;
;;; alias      = 0 alias								 ;AN000;
;	       = 1 device/file								 ;AN000;
;	       = 2 drive								 ;AN000;
;	       = 3 Char device -> network						 ;AN000;
;	       = 4 File device -> network						 ;AN000;
;	    DS:SI -> ASCIIZ source name 						 ;AN000;
;	    ES:DI -> Target driver to attach to and parms.				 ;AN000;
;			    DW ASCIIZ  -  asciiz name of driver 			 ;AN000;
;			    DW n       -  number of parms				 ;AN000;
;			    DW ASCIIZ,... parms 					 ;AN000;
;											 ;AN000;
;	    CX is reserved (user word for REDIR)					 ;AN000;
;											 ;AN000;
; Function:										 ;AN000;
;	     IF BL > 0 THEN								 ;AN000;
;		DO									 ;AN000;
;		  Check that IFS driver exists						 ;AN000;
;		  IF found, set IFS header to that found				 ;AN000;
;		  ELSE set error_file_system_not_found					 ;AN000;
;		ENDDO									 ;AN000;
;	     IF (BL=2 .OR. BL=4) & no error THEN					 ;AN000;
;		DO									 ;AN000;
;		  Find CDS for this drive						 ;AN000;
;		  IF none exists, then set error_invalid_parameter			 ;AN000;
;		  ELSE Call CDS_TO_CD							 ;AN000;
;		END									 ;AN000;
;	     ELSE DO									 ;AN000;
;		    IF source name not in DFL THEN					 ;AN000;
;			 Call CREATE_DFL_ENTRY						 ;AN000;
;		    ELSE  Set error_device_already_attached				 ;AN000;
;		    ENDIF								 ;AN000;
;		  ENDDO 								 ;AN000;
;	     IF no error THEN								 ;AN000;
;		DO									 ;AN000;
;		  Prep IFSRH for Attach Start:						 ;AN000;
;		    *  IFSR_LENGTH	DW     34	; Request length		 ;AN000;
;		    *  IFSR_FUNCTION	DB	2	; Attach Start			 ;AN000;
;		       IFSR_RETCODE	DW	0					 ;AN000;
;		       IFSR_RETCLASS	DB	?					 ;AN000;
;		       IFSR_RESV1	DB     16 DUP(0)				 ;AN000;
;		    *  IFSR_TYPE	DB	?	; BL (0,1,2,3,or 4)		 ;AN000;
;		       IFSR_RESV2	DB	?	;
;		    *  IFSR_PARMS@	DD	PARMS	; See below			 ;AN000;
;		    *  IFSR_DEVICE_CB@	DD	?	; CD or DF (See below)		 ;AN000;
;		    *  IFSR_USER_WORD	DW	?	; for deviceless attach 	 ;AN000;
;											 ;AN000;
;		    *  PARMS	       LABEL   WORD					 ;AN000;
;				       DW      PARMCOUNT ; Number of parms. May be 0.	 ;AN000;
;				       DB      ASCIIZ,...; Parms			 ;AN000;
;		ENDDO									 ;AN000;
;	       IF no error THEN 							 ;AN000;
;		  DO									 ;AN000;
;		    CALL routine, CALL_IFS, with pointer to IFS header			 ;AN000;
;		    IF IFSR_RETCODE = 0 THEN						 ;AN000;
;		       DO								 ;AN000;
;			 IF DFL flag set THEN						 ;AN000;
;			    DO								 ;AN000;
;			      Call DF_TO_DFL						 ;AN000;
;			      Set DFLL_PTR to IFS header 				 ;AN000;
;			    ENDDO							 ;AN000;
;			 ELSE DO							 ;AN000;
;				Call CD_TO_CDS						 ;AN000;
;				Set CDS_IFSR_PTR to IFS header				 ;AN000;
;			      ENDDO							 ;AN000;
;			 ENDIF								 ;AN000;
;			 Clear carry							 ;AN000;
;		       ENDDO								 ;AN000;
;		    ELSE DO								 ;AN000;
;			   IF DFL flag set THEN 					 ;AN000;
;			      Call DELETE_DFL_ENTRY					 ;AN000;
;			   Set carry							 ;AN000;
;			 ENDDO								 ;AN000;
;		    ENDIF								 ;AN000;
;		  ENDDO 								 ;AN000;
;	       ELSE  Set carry								 ;AN000;
;	       ENDIF									 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
	Procedure   ATTACH_START,NEAR							 ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING								 ;AN000;
											 ;AN000;
	ifsr_fcn_def  ATTSTART								 ;AN000;
	MOV	CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@					 ;AN000;
											 ;AN000;
	POP	BX									 ;AN000;
	XOR	BH,BH				; not interested in bh, but should	 ;AN000;
						; be 0 since later move type as word	 ;AN000;
AS_10:											 ;AN000;
	CMP	BL,TYPE_DRIVE			; check ifs vs. network 		 ;AN000;
	JLE	AS_20									 ;AN000;
	CMP	BL,TYPE_NET_DRIVE							 ;AN000;
	JLE	AS_30									 ;AN000;
											 ;AN000;
AS_15:											 ;AN000;
	MOV	AX,error_invalid_function	; invalid fcn type			 ;AN000;
	transfer ifs_980			; go ret w/carry			 ;AN000;
											 ;AN000;
AS_20:						; IFS device/drive			 ;AN000;
	SaveReg <ES,DI> 			; save target ptr for parms@		 ;AN000;
	MOV	DI,ES:[DI]			; set ES:DI -> driver name		 ;AN000;
	invoke	FIND_IFS_DRIVER 		; sets [THISIFS]			 ;AN000;
	JC	AS_25									 ;AN000;
	SaveReg <CX>				; save cx since next destroys		 ;AN000;
	invoke	SET_CATEGORY			; do this to determine unc or not	 ;AN000;
	OR	CL,CL				; cl=1 unc  else ifs			 ;AN000;
	RestoreReg <CX> 			; restore before branch - zf preserved	 ;AN000;
	JZ	AS_50				; jmp if not unc			 ;AN000;
	ADD	BL,2				; change type from 1/2 to 3/4		 ;AN000;
	RestoreReg <DI,ES>			; retrieve orig target ptr		 ;AN010;
;;;;;;;;OR	CS:IFSPROC_FLAGS,Filesys_Network_Attach 				 ;AN010;;AD017;
	CMP	WORD PTR ES:[DI+2],2		; if # parms=2 then have password	 ;AN011;
	JE	AS_22									 ;AN011;
	MOV	CX,0001H			; User word without password		 ;AN011;
	JMP	SHORT AS_23			; go process as unc			 ;AN011;;AC017;
AS_22:											 ;AN011;
	MOV	CX,8001H			; User word with password		 ;AN011;
AS_23:											 ;AN017;
	ADD	DI,4				; skip over ifs name offset & #parms	 ;AN017;
	JMP	SHORT AS_33			; go process as unc			 ;AN000;

AS_25:						; ifs driver not found			 ;AN000;
	POP	DI				; error, restore stack and return	 ;AN000;
	POP	ES									 ;AN000;
	transfer ifs_1000								 ;AN000;
											 ;AN000;
AS_30:						; NETWORK device/drive			 ;AN000;
	TEST	CS:IFSFUNC_FLAGS,UNC_INSTALLED	; check that unc installed		 ;AN000;
	JZ	AS_15									 ;AN000;
AS_33:						; this label for unc already checked	 ;AN000;
	OR	IFSPROC_FLAGS,IsNetwork 	; set network bit			 ;AN000;
	CMP	BL,TYPE_NET_DRIVE		; check pause status			 ;AN000;
	JNE	AS_35									 ;AN000;
	CMP	CS:fAssign,-1								 ;AN000;
	JMP	SHORT AS_37								 ;AN000;
AS_35:											 ;AN000;
	CMP	CS:fPrint,-1								 ;AN000;
AS_37:											 ;AN000;
	JE	AS_40				; bad pause status			 ;AN000;
	MOV	AX,72				; set error and ret w/carry		 ;AN000;
AS_38:											 ;AN020;
	PUSH	CS									 ;AN000;
	POP	DS									 ;AN000;
ASSUME	DS:IFSSEG									 ;AN000;
	invoke	SET_EXTERR_INFO 							 ;AN000;
	transfer ifs_980								 ;AN000;
											 ;AN000;
AS_40:											 ;AN000;
	invoke	SET_THISIFS_UNC 							 ;AN000;
	SaveReg <CX>									 ;AN004;;AC015;
	invoke	NET_TRANS								 ;AN000;
	RestoreReg <CX> 								 ;AN004;;AC015;
	JNC	SHORT AS_55								 ;AC020;
	MOV	AX,error_path_not_found 	; net trans failure = path not found	 ;AN020;
	JMP	AS_38									 ;AN020;
											 ;AN000;
AS_50:											 ;AN000;
	RestoreReg <DI,ES>			; restore target parm ptr		 ;AN000;
AS_55:											 ;AN000;
	OR	CS:IFSPROC_FLAGS,THISIFS_SET	; do this so wont do in CDS_TO_CD	 ;AN000;
						; or DFL_TO_DF				 ;AN000;
	CMP	BL,TYPE_DEVICE								 ;AN000;
	JNE	AS_55_0 								 ;AN000;
	JMP	AS_200									 ;AN000;
AS_55_0:										 ;AN000;
	CMP	BL,TYPE_NET_DEVICE							 ;AN000;
	JNE	AS_55_1 								 ;AN000;
	JMP	AS_200									 ;AN000;
AS_55_1:										 ;AN000;
	CMP	BL,TYPE_NET_DRIVE		; deviceless attach check		 ;AN000;
	JNE	AS_56				; jmp if no				 ;AN000;
	CMP	BYTE PTR [SI],0 		; DEVICELESS ATTACH			 ;AN000;
	JNZ	AS_56				;   Set dummy CDS and flag		 ;AN000;
	Context DS									 ;AN000;
	MOV	SI,OFFSET DOSGROUP:DummyCDS						 ;AN000;
	MOV	WORD PTR [THISCDS+2],DS 						 ;AN000;
	MOV	WORD PTR [THISCDS],SI							 ;AN000;
	OR	IFSPROC_FLAGS,ISDUMMYCDS						 ;AN000;
	JMP	SHORT AS_100								 ;AN000;
											 ;AN000;
AS_56:						; DRIVE ATTACH				 ;AN000;
	CMP	WORD PTR [SI+1],ICOLON		;   if 2nd char not ":" - error          ;AN000;
	JE	AS_60				;   else - find CDS			 ;AN000;
AS_57:											 ;AN000;
	MOV	AX,error_invalid_drive							 ;AN000;
	transfer ifs_980								 ;AN000;
											 ;AN000;
AS_60:											 ;AN000;
	LODSB										 ;AN000;
	Context DS				; get addressability to DOSGROUP	 ;AN000;
	OR	AL,20H									 ;AN000;
	SUB	AL,"a"                          ;   0=A,1=B,...                          ;AN000;
	CallInstall GetCDSFromDrv,multDOS,23,AX,AX					 ;AN000;
ASSUME	DS:NOTHING									 ;AN000;
	JC	AS_57				; no cds - error			 ;AN000;
	TEST	[SI.curdir_flags],curdir_inuse	; DS:SI -> CDS				 ;AN000;
	JZ	AS_100									 ;AN000;
	TEST	[SI.curdir_flags],curdir_isnet + curdir_splice + curdir_local		 ;AN000;
	JZ	AS_100									 ;AN000;
	MOV	AX,error_already_assigned	; error - CDS already assigned		 ;AN000;
	transfer ifs_980			; go return with carry			 ;AN000;
											 ;AN000;
AS_100: 										 ;AN000;
	SaveReg <DS,SI,ES,DI>	; save real cds and target parm ptr			 ;AN000;
				; If all goes OK this will be the "REAL" CDS             ;AN000;
	Context ES									 ;AN000;
	MOV	DI,OFFSET DOSGROUP:DummyCDS						 ;AN000;
	SaveReg <DI,CX> 		; dummy cds offset, input user word		 ;AC001;
	MOV	CX,SIZE curdir_list							 ;AN000;
	REP	MOVSB									 ;AN000;
	RestoreReg <CX> 		; input user word				 ;AN001;
	PUSH	ES									 ;AN000;
	POP	DS									 ;AN000;
	POP	SI		; DS:SI -> dummy CDS					 ;AN000;
	MOV	[SI.curdir_flags],curdir_isnet + curdir_inuse				 ;AN000;
											 ;AN000;
	MOV	AX,WORD PTR [THISIFS]		; set ifs ptr in cds			 ;AN000;
	MOV	DS:WORD PTR [SI.CURDIR_IFS_HDR],AX					 ;AN000;
	MOV	AX,WORD PTR [THISIFS+2] 						 ;AN000;
	MOV	DS:WORD PTR [SI.CURDIR_IFS_HDR+2],AX					 ;AN000;
											 ;AN000;
	MOV	DS:[SI.CURDIR_TYPE],BL		; set CDS type				 ;AN000;
	MOV	DS:[SI.CURDIR_USER_WORD],CX	; set CDS user word			 ;AN001;
	MOV	AX,CX
											 ;AN000;
	RestoreReg <DX,CX>			; get target parm ptr off stack 	 ;AN000;
	SaveReg <DS,SI,BX>			; save type and dummy cds ptr		 ;AN000;
	invoke	PREP_IFSR			; clear ifsrh				 ;AN000;
	invoke	CDS_TO_CD			; CDS: sets ES:BX -> IFSRH		 ;AN000;
						;	    IFSR_DEVICE_CB@		 ;AN000;
						;	    ds - IFSSEG 		 ;AN000;
	OR	IFSPROC_FLAGS,ISCDS							 ;AN000;
	TEST	IFSPROC_FLAGS,ISDUMMYCDS
	JZ	AS_120
	MOV	ES:[BX.IFSR_USER_WORD],AX
AS_120:
	POP	AX				; restore type in AL			 ;AN000;
	MOV	ES:[BX.IFSR_TYPE],AL							 ;AC002;
	SaveReg <CX,DX> 			; put target parm ptr back on stack	 ;AN000;
	JMP	SHORT AS_400			; go prep IFSRH 			 ;AN000;
											 ;AN000;
AS_200: 					; DEVICE ATTACH:			 ;AN000;
	invoke	DFL_MATCH			; check if device already assigned	 ;AN000;
	JC	AS_220				; cf-0 match, cf-set no match		 ;AN000;
	MOV	AX,error_already_assigned						 ;AN000;
	transfer ifs_980			; go return with carry			 ;AN000;
											 ;AN000;
AS_220: 										 ;AN000;
	SaveReg <ES,DI,BX>			; save target parm ptr & type		 ;AN000;
	invoke	CREATE_DFL_ENTRY		; DFL: sets ES:BX -> IFSRH		 ;AN000;
						;	    IFSR_DEVICE_CB@		 ;AN000;
						;	    ds - IFSSEG 		 ;AN000;
	JNC	AS_240									 ;AN000;
	RestoreReg <BX,DI,ES>			; restore stack 			 ;AC019;
	invoke	CONSIST_SFT								 ;AN000;
	transfer ifs_980			;  error ret				 ;AC019;
AS_240: 										 ;AN000;
	POP	AX				; restore type in AL			 ;AN000;moved ;AM019;
	MOV	ES:[BX.IFSR_TYPE],AL							 ;AC002;
											 ;AN000;
											 ;AN000;
AS_400: 						; prep IFSRH			 ;AN000;
	MOV	ES:[BX.IFSR_LENGTH],LENGTH_ATTSTART					 ;AN000;
	MOV	ES:[BX.IFSR_FUNCTION],IFSATTSTART					 ;AN000;
	POP	AX					; old target DI 		 ;AN000;
;;;;;;;;TEST	IFSPROC_FLAGS,Filesys_Network_Attach					 ;AN010;;AD017;
;	JZ	AS_405									 ;AN010;;AD017;
;	ADD	AX,4					; filesys-net  skip name offset  ;AN010;;AD017;
;;;;;;;;JMP	SHORT AS_410				; and # parms - just want net path;AN010;;AD017;
;AS_405:										 ;AN010;;AD017;
	TEST	IFSPROC_FLAGS,IsNetwork 						 ;AN000;
	JNZ	AS_410									 ;AN000;
	INC	AX									 ;AN000;
	INC	AX									 ;AN000;
AS_410:
	MOV	ES:WORD PTR [BX.IFSR_PARMS@],AX 					 ;AN000;
	POP	AX					; old target ES 		 ;AN000;
	MOV	ES:WORD PTR [BX.IFSR_PARMS@+2],AX					 ;AN000;

;***********************************************************************************************
	invoke	CALL_IFS								 ;AN000;
;***********************************************************************************************

	JNC	AS_440									 ;AN000;
											 ;AN000;
											 ;AN000;
	TEST	IFSPROC_FLAGS,ISCDS			; ifs error:			 ;AN000;
	JZ	AS_420									 ;AN000;
	RestoreReg <DS,SI,DS,SI>			; pop dummy & real cds		 ;AN000;
	transfer ifs_980								 ;AN000;
AS_420: 										 ;AN000;
	SaveReg <AX>					; preserve error code		 ;AN027;
	invoke	DELETE_DFL_ENTRY							 ;AN000;
	invoke	CONSIST_SFT								 ;AN025;
	RestoreReg <AX> 								 ;AN027;
	transfer ifs_980								 ;AN000;
											 ;AN000;
AS_440: 						; successful attach		 ;AN000;
	TEST	IFSPROC_FLAGS,ISCDS							 ;AN000;
	JZ	AS_460									 ;AN000;
	RestoreReg <DI,ES>				; restore ES:DI -> dummy cds	 ;AN000;
	invoke	CD_TO_CDS								 ;AN000;
	RestoreReg <SI,DS>				; ds:si - real cds		 ;AN000;
	invoke	XCHGP									 ;AN000;
	MOV	CX,SIZE CURDIR_LIST							 ;AN000;
	OR	DS:[SI.CURDIR_FLAGS],CURDIR_ISIFS	; make sure this flag set	 ;AN000;
	REP	MOVSB									 ;AN000;
	transfer ifs_990								 ;AN000;
											 ;AN000;
AS_460: 										 ;AN000;
	invoke	DF_TO_DFL								 ;AN000;
	invoke	CONSIST_SFT								 ;AN025;
	transfer ifs_990								 ;AN000;
											 ;AN000;
											 ;AN000;
EndProc ATTACH_START									 ;AN000;
											 ;AN000;
											 ;AN000;
BREAK <ATTACH_END -- break attachment>							 ;AN000;
											 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; ATTACH_END										 ;AN000;
;											 ;AN000;
; Called by: IFS_ASSOPER								 ;AN000;
;											 ;AN000;
; Routines called:  DFL_MATCH	      DOS: StrCpy					 ;AN000;
;		    DFL_TO_DF		   DriveFromText				 ;AN000;
;		    DF_TO_DFL		   GetThisDrv					 ;AN000;
;		    CDS_TO_CD		   InitCDS					 ;AN000;
;		    CD_TO_CDS								 ;AN000;
;		    SET_EXTERR_INFO							 ;AN000;
;		    CALL_IFS								 ;AN000;
;		    DELETE_DFL_ENTRY							 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	    DS:SI -> ASCIZ source name							 ;AN000;
; Function:										 ;AN000;
;	     Prep IFSRH:								 ;AN000;
;	     *	IFSR_LENGTH	 DW	30	 ; Request length			 ;AN000;
;	     *	IFSR_FUNCTION	 DB	 4	 ; End Attach				 ;AN000;
;		IFSR_RETCODE	 DW	 ?						 ;AN000;
;		IFSR_RETCLASS	 DB	 ?						 ;AN000;
;		IFSR_RESV1	 DB	16 DUP(0)					 ;AN000;
;	     *	IFSR_DEVICE_CB@  DD	 ?	 ; CD or DF				 ;AN000;
;	     *	IFSR_NAME@	 DD	 ?	 ; for deviceless detach (unc)		 ;AN000;
;											 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
	Procedure   ATTACH_END,NEAR							 ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING								 ;AN000;
											 ;AN000;
	ifsr_fcn_def  ATTEND								 ;AN000;
											 ;AN000;
	POP	BX									 ;AN000;
											 ;AN000;
	MOV	CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@					 ;AN000;
	MOV	CS:IFSPROC_FLAGS,0							 ;AN000;
	invoke	PREP_IFSR								 ;AN000;
											 ;AN000;
	PUSH	DS									 ;AN000;
	POP	ES									 ;AN000;
	MOV	DI,SI				; ES:DI=DS:SI=source name		 ;AN000;
	PUSH	SI				; Save SI				 ;AN000;
	CallInstall StrCpy,multDOS,17		; "Beautify" input string                ;AN000;
						;   (converts to uppercase &		 ;AN000;
						;     / to \)				 ;AN000;
	POP	SI				; Recover string pointer		 ;AN000;
	CMP	WORD PTR [SI],"\\"              ; Special Case -                         ;AN000;
	JZ	AE_300				;	   deviceless detach		 ;AN000;
	CMP	WORD PTR [SI+1],":"             ; check for drive                        ;AN000;
	JNZ	AE_200				; no, go to device check		 ;AN000;
	CMP	fAssign,-1			; BREAK DRIVE ATTACH			 ;AN000;
	JZ	AE_20									 ;AN000;
AE_10:											 ;AN000;
	MOV	AX,72				; pause error				 ;AN000;
	PUSH	CS									 ;AN000;
	POP	DS									 ;AN000;
ASSUME	DS:IFSSEG									 ;AN000;
	invoke	SET_EXTERR_INFO 							 ;AN000;
	transfer ifs_980								 ;AN000;
AE_20:											 ;AN000;
	CallInstall DriveFromText,multDOS,26	; AL = drive # (0-not drive		 ;AN000;
	context DS				;      -1=a,1=b,2=c,...)		 ;AN000;
	CallInstall GetThisDrv,multDOS,25,AX,BX ; ES:DI->CDS				 ;AN000;
	JNC	AE_40									 ;AN000;
	MOV	AX,error_invalid_drive							 ;AN000;
	transfer ifs_1000								 ;AN000;
AE_40:											 ;AN000;
	LES	DI,[THISCDS]								 ;AN000;
	TEST	ES:[DI.curdir_flags],curdir_isnet					 ;AN000;
	JNZ	AE_60									 ;AN000;
	MOV	AX,error_invalid_drive		; not redirected			 ;AN000;
	transfer ifs_980								 ;AN000;
AE_60:											 ;AN000;
	PUSH	AX				; drive #				 ;AN000;
	PUSH	ES									 ;AN000;
	POP	DS									 ;AN000;
	MOV	SI,DI				; move cds ptr to ds:si 		 ;AN000;
	invoke	CDS_TO_CD								 ;AN000;
	OR	IFSPROC_FLAGS,ISCDS							 ;AN000;
	JMP	SHORT AE_400								 ;AN000;
											 ;AN000;
AE_200: 					; BREAK DEVICE ATTACH			 ;AN000;
	CMP	fPrint,-1			; check for pause error 		 ;AN000;
	JZ	AE_210									 ;AN000;
	JMP	AE_10									 ;AN000;
AE_210: 										 ;AN000;
	CALL	DFL_MATCH								 ;AN000;
	JNC	AE_220									 ;AN000;
	MOV	AX,device_not_attached							 ;AN000;
	transfer ifs_1000								 ;AN000;
AE_220: 										 ;AN000;
	MOV	SI,WORD PTR [THISDFL]							 ;AN000;
	MOV	DS,WORD PTR [THISDFL+2] 						 ;AN000;
											 ;AN000;
	TEST	DS:[SI.DFLL_FLAGS],DFL_DEV_REAL						 ;AN000;
;	???????????? check with baf on what reverting to ...				 ;AN000;
											 ;AN000;
	invoke	DFL_TO_DF			; DFL: sets [THISIFS]			 ;AN000;
						;	    ES:BX -> IFSRH		 ;AN000;
						;	    IFSR_DEVICE_CB@		 ;AN000;
						;	    ds - IFSSEG 		 ;AN000;
	JMP	SHORT AE_400								 ;AN000;
											 ;AN000;
AE_300: 					; deviceless detach			 ;AN000;
	SaveReg <CS>				;  restore es to ifsr & set seq flag	 ;AN018;
	RestoreReg <ES> 								 ;AN018;
	OR	CS:IFSPROC_FLAGS,IsSeq							 ;AN018;
	CMP	fAssign,-1								 ;AN000;
	JZ	AE_320									 ;AN000;
	JMP	AE_10				; jump to pause error			 ;AN000;
AE_320: 										 ;AN000;
	SaveReg <ES,BX,DS>			; ifsr ptr				 ;AC004;
	RestoreReg <ES> 			; set esdi = dssi = net path		 ;AC004;
ASSUME	ES:NOTHING									 ;AC004;
	MOV	DI,SI									 ;AC004;
	invoke	NET_TRANS								 ;AC004;
	SaveReg <ES>									 ;AC004;
	RestoreReg <AX> 			; name string segment			 ;AC004;
	MOV	SI,DI				; name string offset			 ;AC004;
	RestoreReg <BX,ES>			; ifsr pointer				 ;AC004;
ASSUME	ES:IFSSEG									 ;AC004;
	MOV	WORD PTR ES:[BX.IFSR_NAME@],DI						 ;AC004;
	MOV	WORD PTR ES:[BX.IFSR_NAME@+2],AX					 ;AC004;
	SaveReg <CS>									 ;AC004;
	RestoreReg <DS> 								 ;AN000;
ASSUME	DS:IFSSEG									 ;AN000;
											 ;AN000;
AE_400: 					; call ifs				 ;AN000;
	MOV	ES:[BX.IFSR_LENGTH],LENGTH_ATTEND					 ;AN000;
	MOV	ES:[BX.IFSR_FUNCTION],IFSATTEND 					 ;AN000;
											 ;AN000;
;***********************************************************************************************
	invoke	CALL_IFS								 ;AN000;
;***********************************************************************************************
											 ;AN000;
	JNC	AE_410									 ;AN000;
	TEST	IFSPROC_FLAGS,ISCDS		; att end error:			 ;AN000;
	JZ	AE_405									 ;AN000;
	ADD	SP,2				; clear ax (drive #) off stack		 ;AN000;
AE_405: 										 ;AN000;
	transfer ifs_980								 ;AN000;
AE_410: 										 ;AN000;
	TEST	CS:IFSPROC_FLAGS,ISCDS							 ;AN000;
	JZ	AE_420									 ;AN000;
											 ;AN000;
	POP	AX				; drive 				 ;AN000;
	ADD	AL,'A'                                                                   ;AN000;
	CallInstall InitCDS,multDOS,31,AX,AX						 ;AN000;
	transfer ifs_990								 ;AN000;
AE_420: 										 ;AN000;
	TEST	CS:IFSPROC_FLAGS,IsSeq							 ;AN018;
	JNZ	AE_440									 ;AN018;
	CALL	DELETE_DFL_ENTRY							 ;AN000;
AE_440: 										 ;AN018;
	transfer ifs_990								 ;AN000;
											 ;AN000;
											 ;AN000;
EndProc ATTACH_END									 ;AN000;
											 ;AN000;

BREAK <IFS_RESET_ENVIRONMENT -- reset IFS environment>					 ;AN016;

;***********************************************************************************
;
; IFS_RESET_ENVIRONMENT
;
; Called by:	   IFSFUNC Dispatcher
;
; Routines called:
;	jumps into ifs_abort
;
; Inputs:
;	[CurrentPDB] set to PID of process aborting
;
; Function:
;	Get address of IFS driver chain.
;	FOR I = 1 to last IFS driver
;	    Send request below to IFS driver
;
;	IFSRH:
;	*  IFSR_LENGTH	    DW	   42	    ; Request length
;	*  IFSR_FUNCTION    DB	    4	    ; Execute API function
;	   IFSR_RETCODE     DW	    ?
;	   IFSR_RETCLASS    DB	    ?
;	   IFSR_RESV1	    DB	   16 DUP(0)
;	*  IFSR_APIFUNC     DB	   18	    ; End of Process
;	   IFSR_ERROR_CLASS DB	    ?
;	   IFSR_ERROR_ACTION DB     ?
;	   IFSR_ERROR_LOCUS DB	    ?
;	   IFSR_ALLOWED     DB	    ?
;	   IFSR_I24_RETRY   DB	    ?
;	   IFSR_I24_RESP    DB	    ?
;	   IFSR_RESV2	    DB	    ?
;	   IFSR_DEVICE_CB@  DD	    ?	    ; CD
;	   IFSR_OPEN_CB@    DD	    ?
;	*  IFSR_PID	    DW	    ?	    ; process ID
;	*  IFSR_SUBFUNC     DB	    2	    ; 0=normal exit  1=abort exit
;					    ; 2=reset environment
;	   IFSR_RESV3	    DB	    ?
;
;	Call all IFSs with this info.
;	Scan through SFTFCB
;	IF (ref_count ^= 0 .AND. ^busy .AND. isifs .AND. SF_PID = currentPDB) THEN
;	   Call SF_IFS_HDR with close request
;	ENDIF
;
; Outputs: None
; DS Preserved, All others destroyed
;
;************************************************************************************

	procedure   IFS_RESET_ENVIRONMENT,NEAR							     ;AN016;
ASSUME	DS:DOSGROUP,ES:NOTHING								 ;AN016;

	ifsr_fcn_def EXECAPI								 ;AN016;
	ifsr_api_def EOP								 ;AN016;

	MOV	CS:IFSPROC_FLAGS,IsResetEnvirn						 ;AN016;
	Context DS				; make sure ds=ss=dosgroup		 ;AN016;
	JMP	IA_70									 ;AN016;

EndProc IFS_RESET_ENVIRONMENT								 ;AN016;


BREAK <IFS_ABORT -- Send CLOSE all files for process>					 ;AN016;
											 ;AN016;
;************************************************************************************
;
; IFS_ABORT
;
; Called by:	   IFSFUNC Dispatcher
;
; Routines called:
;	CALL_IFS
;	IFS_CLOSE
;
; Inputs:
;	[CurrentPDB] set to PID of process aborting
;
; Function:
;	Get address of IFS driver chain.
;	FOR I = 1 to last IFS driver
;	    Send request below to IFS driver
;
;	IFSRH:
;	*  IFSR_LENGTH	    DW	   42	    ; Request length
;	*  IFSR_FUNCTION    DB	    4	    ; Execute API function
;	   IFSR_RETCODE     DW	    ?
;	   IFSR_RETCLASS    DB	    ?
;	   IFSR_RESV1	    DB	   16 DUP(0)
;	*  IFSR_APIFUNC     DB	   18	    ; End of Process
;	   IFSR_ERROR_CLASS DB	    ?
;	   IFSR_ERROR_ACTION DB     ?
;	   IFSR_ERROR_LOCUS DB	    ?
;	   IFSR_ALLOWED     DB	    ?
;	   IFSR_I24_RETRY   DB	    ?
;	   IFSR_I24_RESP    DB	    ?
;	   IFSR_RESV2	    DB	    ?
;	   IFSR_DEVICE_CB@  DD	    ?	    ; CD
;	   IFSR_OPEN_CB@    DD	    ?
;	*  IFSR_PID	    DW	    ?	    ; process ID
;	*  IFSR_SUBFUNC     DB	    ?	    ; 0=normal exit  1=abort exit
;					    ; 2=reset environment
;	   IFSR_RESV3	    DB	    ?
;
;	Call all IFSs with this info.
;	Scan through SFTFCB
;	IF (ref_count ^= 0 .AND. ^busy .AND. isifs .AND. SF_PID = currentPDB) THEN
;	   Call SF_IFS_HDR with close request
;	ENDIF
;
; Outputs: None
; DS Preserved, All others destroyed
;
;************************************************************************************

	procedure   IFS_ABORT,NEAR							 ;AN000;
ASSUME	DS:DOSGROUP,ES:NOTHING								 ;AN000;
											 ;AN000;
	ifsr_fcn_def EXECAPI								 ;AN000;
	ifsr_api_def EOP								 ;AN000;

	MOV	CS:IFSPROC_FLAGS,ZERO
											 ;AN000;
;   Scan the FCB Cache and close any NET FCBs						 ;AN000;
;   belonging to this process. The reason we must do this is that			 ;AN000;
;   NET FCBs are well behaved and must be closed on EXIT.				 ;AN000;
											 ;AN000;
	LES	DI,[SFTFCB]								 ;AN000;
	MOV	CX,ES:[DI].sfCount							 ;AN000;
	LEA	DI,[DI].sfTable 							 ;AN000;
	JCXZ	IA_70									 ;AN000;
IA_20:					; Loop through sftfcb's                          ;AN000;
	CMP	ES:[DI].sf_ref_count,0							 ;AN000;
	JZ	IA_60			; Ignore Free ones				 ;AN000;
	CMP	ES:[DI].sf_ref_count,sf_busy						 ;AN000;
	JZ	IA_60			; Ignore busy ones				 ;AN000;
	TEST	ES:[DI].sf_flags,sf_isnet						 ;AN000;
	JZ	IA_60			; Ignore non NET ones				 ;AN000;
	MOV	AX,[CurrentPDB] 							 ;AN000;
	CMP	AX,ES:[DI].sf_PID							 ;AN000;
	JNZ	IA_60			; Ignore FCBs not for this proc 		 ;AN000;
	MOV	WORD PTR [THISSFT],DI							 ;AN000;
	MOV	WORD PTR [THISSFT+2],ES 						 ;AN000;
	PUSH	CX									 ;AN000;
IA_40:					; CLOSE 					 ;AN000;
	invoke	IFS_CLOSE		; IGNORE ANY ERRORS ON THIS.			 ;AN000;
	CMP	ES:[DI].sf_ref_count,0	; Make sure it gets closed			 ;AN000;
	JNE	IA_40			; Loop until closed				 ;AN000;
	POP	CX									 ;AN000;
IA_60:											 ;AN000;
	ADD	DI,size sf_entry							 ;AN000;
	LOOP	IA_20									 ;AN000;
;											 ;AN000;
; Now loop through all ifs drivers with end of process request				 ;AN000;
;											 ;AN000;
IA_70:											 ;AN000;
	LDS	SI,IFS_HEADER								 ;AN000;
ASSUME	DS:NOTHING									 ;AN000;
	JMP	SHORT IA_100		; go check if null				 ;AN007;
											 ;AN000;
IA_80:											 ;AN000;
	MOV	CS:WORD PTR [THISIFS],SI	; Send end of process request		 ;AN000;
	MOV	CS:WORD PTR [THISIFS+2],DS	; to all fs drivers.			 ;AN000;
	invoke	PREP_IFSR			; sets esbx -> ifsrh			 ;AN000;
	MOV	ES:[BX.IFSR_LENGTH],LENGTH_EOP						 ;AN000;
	MOV	ES:[BX.IFSR_FUNCTION],IFSEXECAPI					 ;AN000;
	MOV	ES:[BX.IFSR_APIFUNC],IFSEOP						 ;AN000;
	MOV	AX,[CurrentPDB] 							 ;AN000;
	MOV	ES:[BX.IFSR_PID],AX		 ; ?????				 ;AN000;
	MOV	AL,[EXIT_TYPE]								 ;AN000;
	MOV	ES:[BX.IFSR_SUBFUNC],AL 						 ;AN000;
	TEST	CS:IFSPROC_FLAGS,IsResetEnvirn						 ;AN016;
	JZ	IA_90									 ;AN016;
	MOV	ES:[BX.IFSR_SUBFUNC],RESET_ENVIRONMENT					 ;AN016;
IA_90:											 ;AN016;
	SaveReg <DS,SI,CS>			; dssi - ifs driver			 ;AC012;
	RestoreReg <DS> 			; ds - ifsseg				 ;AN000;
											 ;AN000;
;***********************************************************************************************
	invoke	CALL_IFS								 ;AN000;
;***********************************************************************************************
											 ;AN000;
	RestoreReg <SI,DS>			; dssi - ifs driver			 ;AC012;
	LDS	SI,[SI.IFS_NEXT]		; check next fs driver			 ;AN000;
IA_100: 										 ;AN007;
	CMP	SI,NULL_PTR			; if ptr null, no more			 ;AN000;
	JNE	IA_80									 ;AN000;
	PUSH	DS									 ;AN000;
	POP	AX									 ;AN000;
	CMP	AX,NULL_PTR								 ;AN000;
	JNE	IA_80									 ;AN000;
											 ;AN000;
											 ;AN000;
IA_1000:										 ;AN000;
	SaveReg <SS>				; dosgroup				 ;AN000;
	RestoreReg <DS> 								 ;AN000;
	return				;????????? may need redir ioctl to		 ;AN000;
					; consist_refs					 ;AN000;
											 ;AN000;
EndProc IFS_ABORT									 ;AN000;
											 ;AN000;
											 ;AN000;
BREAK <GET_IFS_DRIVER_NAME -- get IFS driver name>					 ;AN000;
											 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; GET_IFS_DRIVER_NAME									 ;AN000;
;											 ;AN000;
; Called by: GET_IFSFUNC_ITEM								 ;AN000;
;											 ;AN000;
; Routines called:									 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	    DS:SI -> CDS/DFL								 ;AN000;
;	    ES:DI =  buffer to place name						 ;AN000;
; Function:										 ;AN000;
;	Find FS name in IFS header pointed to by CDS or DFL				 ;AN000;
;	Place name in buffer pointed to by ES:DI					 ;AN000;
; Output:										 ;AN000;
;	buffer filled, hopefully with ifs name						 ;AN000;
;	pointer not checked for valid ifs driver hdr ptr				 ;AN000;
; Regs: all preserved									 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
	Procedure   GET_IFS_DRIVER_NAME,NEAR						 ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING								 ;AN000;
											 ;AN000;
	SaveReg <DS,SI,CX,DI>			; preserve cds/dfl ptr, cx, buffer	 ;AN000;
						; offset				 ;AN000;
	TEST	CS:IFSPROC_FLAGS,ISCDS		; get ifs hdr ptr from			 ;AN000;
	JZ	GIDN_20 								 ;AN000;
	LDS	SI,[SI.CURDIR_IFS_HDR]		; cds					 ;AN000;
	JMP	GIDN_40 								 ;AN000;
GIDN_20:										 ;AN000;
	LDS	SI,[SI.DFLL_IFS_HDR]		; dfl					 ;AN000;
GIDN_40:										 ;AN000;
	invoke	MOVE_DRIVER_NAME		; move ifs driver name into buffer	 ;AN000;
											 ;AN000;
	RestoreReg <DI,CX,SI,DS>		; restore cds/dfl ptr, cx, buffer	 ;AN000;
						; offset				 ;AN000;
	return										 ;AN000;
											 ;AN000;
EndProc GET_IFS_DRIVER_NAME								 ;AN000;
											 ;AN000;
BREAK <FIND_IFS_DRIVER -- get IFS driver>						 ;AN000;
											 ;AN000;
;************************************************************************************
;
; FIND_IFS_DRIVER
;
; Called by:		ATTACH_START
;
; Routines called:	CHECK_END_SPACE
;
; Inputs:
;	    ES:DI -> IFS driver name
; Function:
;	Loop through IFS driver chain until name match.
;	If match found - set [THISIFS] and clear carry
;	Else set carry.
; Output:
;	carry clear - match found,[THISIFS] set
;	carry set   - no match found
;
; Regs: all but ax preserved
;
;************************************************************************************
											 ;AN000;
	Procedure   FIND_IFS_DRIVER							 ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING								 ;AN000;
											 ;AN000;
	SaveReg <DS,SI,BX,ES,DI>		; save registers  (except ax for error)  ;AC026;
											 ;AN000;
	TEST	CS:IFSFUNC_FLAGS,NO_IFS_DRIVERS ; check for no drivers first		 ;AN024;
	JZ	FID_10									 ;AN024;
	JMP	FID_30									 ;AN024;
FID_10: 										 ;AN024;

	SaveReg <SS>				; get addressability to dosgroup	 ;AN000;
	RestoreReg <DS> 			;  to get ifs driver chain		 ;AN000;
	LDS	SI,IFS_HEADER								 ;AN000;
ASSUME	DS:NOTHING				; ds:si -> 1st ifs driver		 ;AN000;
											 ;AN000;
FID_20: 										 ;AN000;
	SaveReg <DS,SI,ES,DI,CS>		; save ds,si,es,di			 ;AN000;
	RestoreReg <ES> 			; set es=cs				 ;AN000;
ASSUME	ES:IFSSEG									 ;AN000;
	MOV	DI,OFFSET TEMPBUF		; move ifs driver name into tempbuf	 ;AN000;
	SaveReg <SI,DI> 			; so that can be asciiz form before	 ;AN000;
	invoke	MOVE_DRIVER_NAME		; strcmp				 ;AN000;
	RestoreReg <SI,DI>			; dssi -> tempbuf (ifs driver asciiz	 ;AN000;
	SaveReg <ES>				; name) 				 ;AN000;
	RestoreReg <DS,DI,ES>			; esdi -> ifs driver name (input)	 ;AN000;
	CALL	CHECK_END_SPACE 		; make sure ^ has no blanks		;AN000;

	CallInstall StrCmp,multDOS,30		; check for match (regs preserved)	 ;AN000;
	RestoreReg <SI,DS>			; (ifs driver)				 ;AN000;
	JZ	FID_40				; if match, go set thisifs & return	 ;AN000;
	LDS	SI,[SI.IFS_NEXT]		; else check next fs driver		 ;AN000;
	CMP	SI,MINUS_ONE			; if ptr null, no more = error		 ;AN000;
	JNE	FID_20									 ;AN000;
	PUSH	DS									 ;AN000;
	POP	AX									 ;AN000;
	CMP	AX,MINUS_ONE								 ;AN000;
	JNE	FID_20									 ;AN000;
FID_30: 										 ;AN024;
	MOV	AX,fs_driver_not_found							 ;AN000;
	JMP	SHORT FID_980								 ;AN000;
FID_40: 										 ;AN000;
	MOV	WORD PTR CS:[THISIFS],SI	    ; match.  Set [THISIFS] to this	 ;AN000;
	MOV	WORD PTR CS:[THISIFS+2],DS	    ; driver				 ;AN000;
	JMP	FID_990 								 ;AN000;
											 ;AN000;
											 ;AN000;
FID_980:					; Return area				 ;AN000;
	STC										 ;AN000;
	JMP	SHORT FID_1000								 ;AN000;
FID_990:										 ;AN000;
	CLC										 ;AN000;
FID_1000:										 ;AN000;
	RestoreReg <DI,ES,BX,SI,DS>		; restore registers			 ;AC026;
	return										 ;AN000;
											 ;AN000;
EndProc FIND_IFS_DRIVER 								 ;AN000;
											 ;AN000;
											 ;AN000;
BREAK <ASSIGN_MODE_FUNCTIONS -- drive/print on/off>					 ;AN000;
											 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; AssignOn/AssignOff									 ;AN000;
;											 ;AN000;
; Called by: SET_ASSIGN_MODE								 ;AN000;
;											 ;AN000;
; AssignOn and AssignOFF copied from Network Redirector code				 ;AN000;
; PrintOn and PrintOff IFSFUNC new code 						 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;											 ;AN000;
; Function:										 ;AN000;
;											 ;AN000;
; Output:										 ;AN000;
;											 ;AN000;
; Regs: none preserved									 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
Procedure AssignOn,Near 								 ;AN000;
ASSUME ES:NOTHING, DS:NOTHING								 ;AN000;
	EnterCrit CritNet								 ;AN000;
	CMP	fAssign,-1		;   if (fAssign)				 ;AN000;
	JZ	CrLvA			;	return; 				 ;AN000;
	MOV	fAssign,-1		;   fAssign = TRUE;				 ;AN000;
	LDS	SI,CDSAlt		;   s = CDSAlt; 				 ;AN000;
	LES	DI,CDSAddr		;   d = CDSAddr;				 ;AN000;
	MOV	AL,CDSCount								 ;AN000;
	MOV	DX,SIZE curdir_list							 ;AN000;
OnLoop: 										 ;AN000;
	TEST	[SI].curdir_flags,curdir_isnet						 ;AN000;
	JNZ	RestCDS 		; Restore this NET guy				 ;AN000;
	ADD	SI,DX			; Skip to next CDS				 ;AN000;
	ADD	DI,DX									 ;AN000;
NextCDS:										 ;AN000;
	DEC	AL									 ;AN000;
	JNZ	OnLoop									 ;AN000;
CrLvA:											 ;AN000;
	LeaveCrit CritNet								 ;AN000;
	return										 ;AN000;
											 ;AN000;
RestCDS:										 ;AN000;
	MOV	CX,DX									 ;AN000;
	REP	MOVSB			;   strcpy (d, s);				 ;AN000;
	JMP	NextCDS 								 ;AN000;
EndProc AssignOn									 ;AN000;
											 ;AN000;
Procedure AssignOff,Near								 ;AN000;
	ASSUME	ES:NOTHING, DS:NOTHING							 ;AN000;
	EnterCrit CritNet								 ;AN000;
	CMP	fAssign,0		;   if (!fAssign)				 ;AN000;
	JZ	CrLvB			;	return; 				 ;AN000;
	LES	DI,CDSAlt		;   d = CDSAlt; 				 ;AN000;
	LDS	SI,CDSAddr		;   s = CDSAddr;				 ;AN000;
	MOV	AL,CDSCount								 ;AN000;
	CBW				; always less or = 26				 ;AN000;
	MOV	CX,SIZE curdir_list							 ;AN000;
	MUL	CX									 ;AN000;
	MOV	CX,AX									 ;AN000;
	REP	MOVSB			;   Save current CDS state			 ;AN000;
	XOR	AL,AL									 ;AN000;
OffLoop:				;   for (i=0; p1=getcds(i); i++)		 ;AN000;
	CallInstall GetCDSFromDrv,multDOS,23,AX,AX  ; Set THISCDS for possible		 ;AN000;
					;	call to InitCDS 			 ;AN000;
	JC	OffDone 		;						 ;AN000;
	TEST	[SI].curdir_flags,curdir_isnet						 ;AN000;
	JZ	OffInc									 ;AN000;
	SaveReg <AX>									 ;AN000;
	ADD	AX,'A'                                                                   ;AN000;
	CallInstall InitCDS,multDOS,31,AX,AX ;	     initcds (p1);			 ;AN000;
	RestoreReg  <AX>								 ;AN000;
OffInc: INC	AL									 ;AN000;
	JMP	OffLoop 								 ;AN000;
											 ;AN000;
OffDone:										 ;AN000;
	MOV	fAssign,0		;   fAssign = FALSE;				 ;AN000;
CrLvB:											 ;AN000;
	LeaveCrit CritNet								 ;AN000;
	return										 ;AN000;
EndProc AssignOff									 ;AN000;
											 ;AN000;
;****************************************************************************** 	 ;AN000;
;											 ;AN000;
; PrintOn/PrintOff									 ;AN000;
;											 ;AN000;
; Called by: SET_ASSIGN_MODE								 ;AN000;
;											 ;AN000;
; Routines called:  CALL_IFS								 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;											 ;AN000;
; Function:										 ;AN000;
;	Print on - loop through dfl entries resetting pause flag to zero		 ;AN000;
;	Print off- loop through dfl entries, set pause flag if unc			 ;AN000;
;											 ;AN000;
;	Prep IFSRH:									 ;AN000;
;	*  IFSR_LENGTH	    DW	   48	    ; Request length				 ;AN000;
;	*  IFSR_FUNCTION    DB	    4	    ; Execute API function			 ;AN000;
;	   IFSR_RETCODE     DB	    ?							 ;AN000;
;	   IFSR_RETCLASS    DB	    ?							 ;AN000;
;	   IFSR_RESV1	    DB	   17 DUP(0)						 ;AN000;
;	*  IFSR_APIFUNC     DB	   16	    ; IFS dependent IOCTL			 ;AN000;
;	   IFSR_ERROR_CLASS DB	    ?							 ;AN000;
;	   IFSR_ERROR_ACTION DB     ?							 ;AN000;
;	   IFSR_ERROR_LOCUS DB	    ?							 ;AN000;
;	   IFSR_ALLOWED     DB	    ?							 ;AN000;
;	   IFSR_I24_RETRY   DB	    ?							 ;AN000;
;	   IFSR_I24_RESP    DB	    ?							 ;AN000;
;	   IFSR_RESV2	    DB	    ?							 ;AN000;
;	   IFSR_DEVICE_CB@  DD	    ?							 ;AN000;
;	   IFSR_OPEN_CB@    DD	    ?							 ;AN000;
;	*  IFSR_FUNC	    DB	    0	    ; 0 generic ioctl				 ;AN000;
;	   IFSR_RESV2	    DB	    0							 ;AN000;
;	*  IFSR_BUFFER@     DD	    ?	    ; al-2 es:di, else ds:dx			 ;AN000;
;	*  IFSR_BUFSIZE     DW	    ?	    ; al-2 cx, else ??? 			 ;AN000;
;	*  IFSR_CATEGORY    DB	    1	    ; 1 for UNC 				 ;AN000;
;	*  IFSR_CTLFUNC     DB	    ?	    ; x - print on, y - print off		 ;AN000;
;											 ;AN000;
;											 ;AN000;
;	CALL routine, CALL_IFS, with pointer to IFS header				 ;AN000;
;											 ;AN000;
;   Outputs: none									 ;AN000;
;											 ;AN000;
;   Regs: nothing preserved								 ;AN000;
;											 ;AN000;
;****************************************************************************** 	 ;AN000;
											 ;AN000;
Procedure PrintOn,Near									 ;AN000;
	ASSUME DS:NOTHING, ES:NOTHING							 ;AN000;
											 ;AN000;
	EnterCrit CritNet								 ;AN000;
	CMP	fPrint,-1			;   if (fPrint) 			 ;AN000;
	JNE	PON_20									 ;AN000;
	JMP	POF_1000			;	return; 			 ;AN000;
PON_20: 										 ;AN000;
	MOV	fPrint,-1			;   fPrint = TRUE;			 ;AN000;
	MOV	CS:IFSPROC_FLAGS,PRINT_ON						 ;AN000;
	JMP	POF_20				; finish in printoff routine		 ;AN000;
											 ;AN000;
											 ;AN000;
EndProc PrintOn 									 ;AN000;
											 ;AN000;
Procedure   PrintOff,NEAR								 ;AN000;
	ASSUME DS:NOTHING, ES:NOTHING							 ;AN000;
											 ;AN000;
	EnterCrit CritNet								 ;AN000;
	CMP	fPrint,0			; quit if already off			 ;AN000;
	JZ	POF_1000			;	return				 ;AN000;
	MOV	fPrint,0			; set off				 ;AN000;
	MOV	CS:IFSPROC_FLAGS,ZERO		; init processing flags 		 ;AN000;
											 ;AN000;
POF_20: 					; (welcome print on)			 ;AN000;
	PUSH	CS				; get addressability to IFSSEG		 ;AN000;
	POP	DS									 ;AN000;
ASSUME	DS:IFSSEG,ES:NOTHING								 ;AN000;
											 ;AN000;
	MOV	CL,[DFLCount]			; Prep loop through DFL list		 ;AN000;
	XOR	CH,CH				; For all unc devices, set pause	 ;AN000;
	XOR	DH,DH				; flag					 ;AN000;
	MOV	DL,SIZE DFLL_LIST							 ;AN000;
	LDS	SI,[DFLAddr]								 ;AN000;
POF_40: 					; *** loop on setting pause flag	 ;AN000;
	TEST	IFSPROC_FLAGS,PRINT_ON		;     on print on, just reset all	 ;AN000;
	JNZ	POF_50									 ;AN000;
	LES	DI,DS:[SI.DFLL_IFS_HDR]		;     only set pause on unc devices	 ;AN000;
	OR	DI,DI				; make sure this dfl taken		 ;AN000;
	JNZ	POF_45									 ;AN000;
	SaveReg <AX,ES> 								 ;AN000;
	RestoreReg <AX> 								 ;AN000;
	OR	AX,AX									 ;AN000;
	RestoreReg <AX> 								 ;AN000;
	JZ	POF_60									 ;AN000;
POF_45: 										 ;AN000;
	TEST	ES:[DI.IFS_ATTRIBUTE],IFSUNC						 ;AN000;
	JZ	POF_60									 ;AN000;
	OR	DS:[SI.DFLL_FLAGS],DFL_PAUSED						 ;AN000;
	JMP	SHORT POF_60								       ;AN000;
POF_50: 										 ;AN000;
	AND	DS:[SI.DFLL_FLAGS],NOT DFL_PAUSED					 ;AN000;
POF_60: 										 ;AN000;
	ADD	SI,DX				; prep for next dfl			 ;AN000;
	LOOP	POF_40				; go process next dfl			 ;AN000;
						; now go tell unc, device pause 	 ;AN000;
						; is in effect				 ;AN000;
	invoke	PREP_IFSR			; init ifsr				 ;AN000;
											 ;AN000;
	ifsr_fcn_def	EXECAPI 		; define ifsr for dep ioctl		 ;AN000;
	ifsr_api_def	DEPIOCTL							 ;AN000;
											 ;AN000;
	invoke	SET_DEPIOCTL_IFSR							 ;AN000;
	TEST	IFSPROC_FLAGS,PRINT_ON							 ;AN000;
	JZ	POF_80									 ;AN000;
	MOV	ES:[BX.IFSR_CTLFUNC],CTLFUNC_PRINT_ON					 ;AN000;
	JMP	SHORT POF_100								 ;AN000;
POF_80: 										 ;AN000;
	MOV	ES:[BX.IFSR_CTLFUNC],CTLFUNC_PRINT_OFF					 ;AN000;
POF_100:										 ;AN000;
	MOV	ES:[BX.IFSR_CATEGORY],1 						 ;AN000;
	invoke	SET_THISIFS_UNC 							 ;AN000;

;***********************************************************************************************
	invoke	CALL_IFS			; call ifs driver w/request		 ;AN000;
;***********************************************************************************************

	invoke	CONSIST_SFT							       ;AN000;
											 ;AN000;
POF_1000:										 ;AN000;
	LeaveCrit CritNet								 ;AN000;
	return										 ;AN000;
											 ;AN000;
EndProc PrintOff									 ;AN000;
											 ;AN000;
											 ;AN000;
BREAK <GET_UNC_ITEM_INFO  -- resv bits, net name id, user word, max xmitt sz>		 ;AC000;

;******************************************************************************
;
; GET_UNC_ITEM_INFO
;
; Called by:  GET_IFSFUNC_ITEM
;
; Routines called:  CALL_IFS
;
; Inputs:
;	    BL = redirection index
;	    ES:DI -> Target buffer:  old - net path string			   ;AN00
;				     new - dw file system driver name
;					   dw # parms
;					   db parms
;
; Function:
;
;	Prep IFSRH:
;	*  IFSR_LENGTH	    DW	   48	    ; Request length
;	*  IFSR_FUNCTION    DB	    4	    ; Execute API function
;	   IFSR_RETCODE     DB	    ?
;	   IFSR_RETCLASS    DB	    ?
;	   IFSR_RESV1	    DB	   17 DUP(0)
;	*  IFSR_APIFUNC     DB	   16	    ; IFS dependent IOCTL
;	   IFSR_ERROR_CLASS DB	    ?
;	   IFSR_ERROR_ACTION DB     ?
;	   IFSR_ERROR_LOCUS DB	    ?
;	   IFSR_ALLOWED     DB	    ?
;	   IFSR_I24_RETRY   DB	    ?
;	   IFSR_I24_RESP    DB	    ?
;	   IFSR_RESV2	    DB	    ?
;	   IFSR_DEVICE_CB@  DD	    ?
;	   IFSR_OPEN_CB@    DD	    ?
;	*  IFSR_FUNC	    DB	    0	    ; 0 generic ioctl
;	   IFSR_RESV2	    DB	    0
;	*  IFSR_BUFFER@     DD	    ?	    ; unc item info buffer
;	   IFSR_BUFSIZE     DW	    10
;	*  IFSR_CATEGORY    DB	    1	    ; 1 for UNC
;	*  IFSR_CTLFUNC     DB	    ?	    ; 4 - get unc item
;
;	buffer:  dw	index  (bx)
;		 dw	user word
;		 dw	max xmitt size
;		 dw	net name ID
;		 dw	lower 8 bits lsn from ncb_list
;		 db	redir reserved bits
;		 db	net path...(asciiz)
;
;
;	CALL routine, CALL_IFS, with pointer to IFS header
;
;   Outputs: user stack contains info
;		cx - user word
;		bx - bits and macro type
;		dx - max xmitt size
;		ax - net name id
;		bp - lsn (if specified)
;
;   Regs: nothing preserved
;
;******************************************************************************
											 ;AC003;
	Procedure   GET_UNC_ITEM_INFO,NEAR						 ;AC003;
											 ;AC003;
	TEST	CS:IFSFUNC_FLAGS,UNC_INSTALLED						 ;AN013;
	JNZ	GUI_05									 ;AN013;
	transfer ifs_980								 ;AN013;

GUI_05: 										 ;AN013;
	SaveReg <ES,DI,BX>			; target ptr and index			 ;AC003;
											 ;AC003;
	invoke	PREP_IFSR			; init ifsr				 ;AC003;
	SaveReg <CS>				; prep ds for call ifs call		 ;AC003;
	RestoreReg <DS> 								 ;AC003;
ASSUME	DS:IFSSEG									 ;AC003;
											 ;AC003;
	invoke	SET_DEPIOCTL_IFSR		; prep IFSRH				 ;AC003;
	invoke	SET_THISIFS_UNC 		; prep IFSRH				 ;AC003;
	MOV	ES:[BX.IFSR_CATEGORY],1 						 ;AC003;
	MOV	ES:[BX.IFSR_CTLFUNC],CTLFUNC_GET_UNC_ITEM				 ;AC003;
											 ;AC003;
	MOV	SI,OFFSET TEMPBUF							 ;AC003;
	MOV	WORD PTR ES:[BX.IFSR_BUFFER@],SI					 ;AC003;
	MOV	WORD PTR ES:[BX.IFSR_BUFFER@+2],DS					 ;AC003;
	RestoreReg <AX> 			; index 				 ;AN003;
	MOV	WORD PTR DS:[SI],AX							 ;AN003;

;***********************************************************************************************
	invoke	CALL_IFS			; call redir w/get unc item request	 ;AC003;
;***********************************************************************************************

											 ;AC003;
	JNC	GUI_10									 ;AC003;
	RestoreReg <DI,ES>								 ;AC003;
	return										 ;AC003;
GUI_10: 										 ;AC003;
	MOV	SI,WORD PTR ES:[BX.IFSR_BUFFER@]					 ;AC003;
	MOV	DS,WORD PTR ES:[BX.IFSR_BUFFER@+2]					 ;AC003;
	SaveReg <SI>
	ADD	SI,2				; space to user word (skip index)	;AN018;
	LODSW					; user word				 ;AC003;
	MOV	CX,AX									 ;AC003;
	LODSW					; max xmitt size			 ;AC003;
	MOV	DX,AX									 ;AC003;
	LODSW					; net name id				 ;AC003;
	PUSH	AX									 ;AC003;
	LODSW					; lsn					 ;AC003;
	MOV	BP,AX									 ;AC003;
	LODSB					; redir bits				 ;AC003;
	MOV	BH,AL									 ;AC003;
	MOV	BL,4									 ;AC003;
	POP	AX				; net name id				 ;AC003;
	SaveReg <DS,SI> 								 ;AC003;
	CallInstall Get_User_Stack,multDOS,24,<AX>,<AX> 				 ;AC003;
	MOV	[SI].User_CX,CX 	; User Word					 ;AC003;
	MOV	[SI].User_BX,BX 	; Bits and macro type				 ;AC003;
	MOV	[SI].User_DX,DX 	; Max Xmitt size				 ;AC003;
	MOV	[SI].User_AX,AX 	; Net name ID					 ;AC003;
	TEST	CS:IFSPROC_FLAGS,SetBP							 ;AC003;
	JZ	GUI_15									 ;AC003;
	MOV	[SI].User_BP,BP 	; LSN						 ;AC003;
GUI_15: 										 ;AN003;
	RestoreReg <SI,DS>
	TEST	IFSPROC_FLAGS,Filesys_status						 ;AC003;
	JNZ	GUI_20									 ;AC003;
	ADD	SP,2			; old si
	RestoreReg <DI,ES>		; buffer/target ptr	(dssi - 18)	       ;AC003;;AC018;
	SaveReg <AX,DI> 								 ;AC003;;AC008;
	JMP	SHORT GUI_40								 ;AC003;
											 ;AC003;
GUI_20: 				; new style					 ;AC003;
	RestoreReg <SI> 		; offset path
	ADD	SI,11									 ;AC003;
	RestoreReg <DI,ES>		; target - dw fsname				 ;AC003;
					;	   dw # parms				 ;AC003;
					;	   db asciiz,...			 ;AC003;
	SaveReg <DI>									 ;AC003;
	MOV	DI,ES:[DI]								 ;AC003;
	invoke	GET_UNC_FS_NAME 							 ;AC003;
	RestoreReg <DI> 								 ;AC003;
	SaveReg <AX,DI> 								 ;AC003;
	INC	DI									 ;AC003;
	INC	DI									 ;AC003;
	MOV	WORD PTR ES:[DI],1							 ;AC003;
	INC	DI									 ;AC003;
	INC	DI									 ;AC003;
											 ;AC003;
GUI_40: 										 ;AC003;
	CallInstall StrCpy,MultDOS,17							 ;AC003;
	RestoreReg <DI> 								 ;AC003;
;;;;;;;;TEST	CS:IFSPROC_FLAGS,FILESYS_STATUS 					 ;AN008;;AD018;
;;;;;;;;JZ	GUI_1000								 ;AN008;;AD018;
	RestoreReg <AX> 								 ;AN008;

GUI_1000:
	return										 ;AC003;
											 ;AC003;
											 ;AC003;
EndProc GET_UNC_ITEM_INFO								 ;AC003;
											 ;AN000;

BREAK <CHECK_END_SPACE -- check esdi string for blanks> 				 ;AN000;
											 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; CHECK_END_SPACE									 ;AN000;
;											 ;AN000;
; Called by:		FIND_IFS_DRIVER 						 ;AN000;
;											 ;AN000;
; Routines called:
;											 ;AN000;
; Inputs:										 ;AN000;
;	    ES:DI -> IFS driver name							 ;AN000;
; Function:										 ;AN000;
;	Replace any blanks in asciiz ifs driver name with 0's.                           ;AN000;
; Output:										 ;AN000;
;	none
;											 ;AN000;
; Regs: all preserved									 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
	Procedure   CHECK_END_SPACE							 ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING								 ;AN000;
											 ;AN000;
	SaveReg <AX,DS,SI,ES>			; save registers			 ;AN000;
	RestoreReg <DS> 			; set dssi -> asciiz ifs name		 ;AN000;
	MOV	SI,DI									 ;AN000;
	CLD					; clear dir flag to count forward	 ;AN000;
CES_20: 					; search LOOP				 ;AN000;
	LODSB					; put char in al			 ;AN000;
	OR	AL,AL				; check for end of string		 ;AN000;
	JZ	CES_1000			; if so go quit 			 ;AN000;
	CMP	AL," "                          ; check for blank                        ;AN000;
	JNE	CES_20				; cont loop if not			 ;AN000;
	MOV	BYTE PTR DS:[SI-1],0		; replace blank with zero		 ;AN000;
											 ;AN000;
											 ;AN000;
CES_1000:										 ;AN000;
	RestoreReg <SI,DS,AX>			; restore registers			 ;AN000;
	return										 ;AN000;
											 ;AN000;
EndProc CHECK_END_SPACE 								 ;AN000;

											 ;AN000;
											 ;AN000;
IFSSEG	ENDS										 ;AN000;
    END 										 ;AN000;
