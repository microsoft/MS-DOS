	 PAGE	 ,132				; 					 ;AN000;
;	SCCSID = @(#)ifshand.asm	1.0 87/05/11					 ;AN000;
TITLE	IFSFUNC HANDLE ROUTINES - Routines for FS dispatch				 ;AN000;
NAME	IFSHANDLE									 ;AN000;
;******************************************************************************
;
; HANDLE (SFT) related FS calls
;
;
;   IFS_CLOSE
;   IFS_COMMIT
;   IFS_LSEEK
;   IFS_READ
;   IFS_WRITE
;   IFS_LOCK
;   IFS_XATTR
;
;   REVISION HISTORY:
;	A000	Original version 4.00   May 1987
;	A001	P635 - Correct Read problem - restore es:di -> sft
;		RG Sept 1,1987
;	A002	P659 - Copy cmd problems (xattr)
;		RG Sept 1,1987
;	A003	P868 - Lock problems	 R.G
;	A004	P849 - Printer problems  R.G
;	A005	P1601- lock/xattr problems R.G
;	A006	P????- Write Only Lock support in Lock Read/Write    10/27 FEIGENBAUM
;	A007	P2339- Not getting count back to user in xattr call  11/09 RG
;	A008	P2433- redir copy problem (Xattr)		   11/17 RG
;	A009	P2566- xattrs not propagated across network	   12/3  RG
;		       (due to size check on set that does not offer size)
;	A010	D285 - Remove Extended Attributes/Lock		   1/88 RG
;	A011	P2994- double close problem			   1/88 RG 
;	A012	P3149- basica file redirection - seek problem	   1/88 RMG
;	A013	P3185- get ea cx check				   1/88 RMG
;	A014	P3249- lock problem				   1/88 RMG
;	A015	P3432- copy to remote ptr problem - write	   2/88 RMG
;	A016	P3513- return cx on xattr wrong 		   2/88 RMG
;	A017	P3968- set sf time/date on close		   3/25/88 RMG
;	A018	P4839- fcb open/ren/term problem on abort close    5/13/88 RMG
;	A019	P4791- don't overwrite ax on error                 5/19/88 RMG
;	A020	P5003- LSEEK hang using Austin Test tool	   6/01/88 RPS
;
;   LOC - 251
;   Programming note:  In the prologues to the routines, the input/output are
;		       accurate.  The pseudocode, however, is outdated and does
;		       not reflect the code.
;
;******************************************************************************
											 ;AN000;
.xlist											 ;AN000;
.xcref											 ;AN000;
INCLUDE IFSSYM.INC									 ;AN000;
INCLUDE IFSFSYM.INC									 ;AN000;
INCLUDE DOSSYM.INC									 ;AN000;
INCLUDE DEVSYM.INC									 ;AN000;
											 ;AN000;
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
; include THE REST of the segment definitions for normal MSDOS				 ;AN000;
											 ;AN000;
include dosseg.asm									 ;AN000;
											 ;AN000;
DATA		SEGMENT WORD PUBLIC 'DATA'                                               ;AN000;
	;DOSGROUP Data									 ;AN000;
	Extrn	THISSFT:DWORD								 ;AN000;
	Extrn	DMAADD:DWORD								 ;AN000;
	Extrn	CurrentPDB:WORD 							 ;AN000;
	Extrn	SAVE_BX:WORD
	Extrn	SAVE_CX:WORD
	Extrn	SAVE_DS:WORD
	Extrn	SAVE_SI:WORD
	Extrn	SAVE_ES:WORD
	Extrn	SAVE_DI:WORD
DATA		ENDS									 ;AN000;
											 ;AN000;
											 ;AN000;
; define our own code segment								 ;AN000;
											 ;AN000;
IFSSEG	SEGMENT BYTE PUBLIC 'IFSSEG'                                                     ;AN000;
	ASSUME	SS:DOSGROUP,CS:IFSSEG							 ;AN000;
											 ;AN000;
	;IFS Data									 ;AN000;
	Extrn	THISDFL:DWORD								 ;AN000;
	Extrn	THISIFS:DWORD								 ;AN000;
	Extrn	IFSPROC_FLAGS:WORD							 ;AN000;
	Extrn	IFSR:WORD								 ;AN000;
	Extrn	DEVICE_CB@_OFFSET:WORD							 ;AN000;
											 ;AN000;
BREAK <IFS_CLOSE Close a FS SFT>							 ;AN000;
											 ;AN000;
;****************************************************************************** 	 ;AN000;
;											 ;AN000;
; IFS_CLOSE - see IFS_COMMIT for details						 ;AN000;
;											 ;AN000;
;****************************************************************************** 	 ;AN000;
											 ;AN000;
	procedure   IFS_CLOSE,NEAR							 ;AN000;
ASSUME	DS:DOSGROUP,ES:NOTHING								 ;AN000;
											 ;AN000;
	ifsr_fcn_def  EXECAPI			; define ifsr for close 		 ;AN000;
	ifsr_api_def  CLOSEFILE 							 ;AN000;
											 ;AN000;
	TEST	ES:[DI.SF_FLAGS],devid_file_clean + sf_close_nodate			 ;AN017;
	JNZ	C_05									 ;AN017;
	CallInstall DATE16,MultDOS,13		; set sf date/time on close		 ;AN017;
	MOV	ES:[DI.SF_DATE],AX							 ;AN017;
	MOV	ES:[DI.SF_TIME],DX							 ;AN017;
C_05:											 ;AN017;

	SaveReg <ES,DI> 			; save SFT ptr				 ;AN000;
	CallInstall FREE_SFT,MultDOS,8		; set SFT busy				 ;AN000;
	PUSH	AX				; save old ref count			 ;AN000;
											 ;AN000;
	TEST	ES:[DI.SF_MODE],SF_ISFCB	; always close fcb			 ;AN011;
	JNZ	C_10				; only do real close when		 ;AN011;
	CMP	AX,1				; sft being freed			 ;AN011;
	JE	C_10									 ;AN011;
	JMP	C_80									 ;AN011;
C_10:											 ;AN011;
	MOV	CS:IFSPROC_FLAGS,ISCLOSE + SETDEVICECB					 ;AN000;
						; 2nd flag causes sft_to_sff to 	 ;AN000;
						; set device cb@			 ;AN000;
	JMP	C_20				; cont. in ifs_commit			 ;AN000;
											 ;AN000;
EndProc IFS_CLOSE									 ;AN000;
											 ;AN000;
BREAK <IFS_COMMIT Commit a FS SFT>							 ;AN000;
											 ;AN000;
;****************************************************************************** 	 ;AN000;
;											 ;AN000;
; IFS_COMMIT										 ;AN000;
;											 ;AN000;
; Called by:	   IFSFUNC dispatcher							 ;AN000;
;											 ;AN000;
; Routines called: CALL_IFS	DRIVE_FROM_SFT						 ;AN000;
;		   SFT_TO_SFF								 ;AN000;
;		   SFF_TO_SFT								 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	[THISSFT] set to the SFT for the file being used				 ;AN000;
;	ES:DI = [THISSFT] (date time are NOT correct)					 ;AN000;
;		SFT must never be for an FCB on commit (error not detected)		 ;AN000;
;											 ;AN000;
; Function:										 ;AN000;
;	Prep IFSRH:									 ;AN000;
;	*  IFSR_LENGTH	    DW	   40	    ; Total length of request			 ;AN000;
;	*  IFSR_FUNCTION    DB	    4	    ; Execute API function			 ;AN000;
;	 + IFSR_RETCODE     DW	    ?							 ;AN000;
;	 + IFSR_RETCLASS    DB	    ?							 ;AN000;
;	   IFSR_RESV1	    DB	   16 DUP(0)						 ;AN000;
;	*  IFSR_APIFUNC     DB	   14	    ; Close/commit file 			 ;AN000;
;	 + IFSR_ERROR_CLASS DB	    ?							 ;AN000;
;	 + IFSR_ERROR_ACTION DB     ?							 ;AN000;
;	 + IFSR_ERROR_LOCUS DB	    ?							 ;AN000;
;	 + IFSR_ALLOWED     DB	    ?							 ;AN000;
;	 + IFSR_I24_RETRY   DB	    ?							 ;AN000;
;	 + IFSR_I24_RESP    DB	    ?							 ;AN000;
;	   IFSR_RESV2	    DB	    ?							 ;AN000;
;	*+ IFSR_DEVICE_CB@  DD	    ?							 ;AN000;
;	*+ IFSR_OPEN_CB@    DD	    ?	    ; SF					 ;AN000;
;	*  IFSR_FUNC	    DB	    ?	    ; 0=CLOSE, 1=COMMIT 			 ;AN000;
;	   IFSR_RESV2	    DB	    0							 ;AN000;
;											 ;AN000;
;	IF  close  THEN 								 ;AN000;
;	   IFSR_FUNC = 0								 ;AN000;
;	ELSE  IFSR_FUNC = 1								 ;AN000;
;	CALL routine, CALL_IFS, with pointer to SF_IFS_HDR				 ;AN000;
;	IF IFSR_RETCODE = 0 THEN							 ;AN000;
;	   DO										 ;AN000;
;	     Call SFF_TO_SFT								 ;AN000;
;	     Decrement SF_REF_COUNT if close						 ;AN000;
;	     Clear carry								 ;AN000;
;	   ENDDO									 ;AN000;
;	ELSE DO     {error}								 ;AN000;
;	       AX = IFSR_RETCODE							 ;AN000;
;	       Set carry								 ;AN000;
;	     ENDDO									 ;AN000;
;	ENDIF										 ;AN000;
;											 ;AN000;
; Outputs:										 ;AN000;
;	sf_ref_count decremented on close unless FAIL					 ;AN000;
;		(AX has old value for COMMIT)						 ;AN000;
;	ES:DI point to SFT								 ;AN000;
;	Carry set if error (file deleted or disk changed)				 ;AN000;
;											 ;AN000;
; DS preserved, others destroyed							 ;AN000;
;											 ;AN000;
;****************************************************************************** 	 ;AN000;
											 ;AN000;
	procedure   IFS_COMMIT,NEAR							 ;AN000;
ASSUME	DS:DOSGROUP,ES:NOTHING								 ;AN000;
											 ;AN000;
	ifsr_fcn_def  EXECAPI								 ;AN000;
	ifsr_api_def  CLOSEFILE 							 ;AN000;
											 ;AN000;
	MOV	CS:IFSPROC_FLAGS,SETDEVICECB	; set ifsproc_flags			 ;AN000;
C_20:						; (welcome ifs_close)			 ;AN000;
	invoke	DRIVE_FROM_SFT			; set IFSDRV for possible criter	 ;AN000;
	invoke	PREP_IFSR			; clear ifsrh				 ;AN000;
	MOV	DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@					 ;AN000;
	invoke	SFT_TO_SFF			; sets: [THISIFS]			 ;AN000;
						;	ES:BX -> IFSRH			 ;AN000;
						;	IFSR_OPEN_CB@			 ;AN000;
						;	ds - IFSSEG			 ;AN000;
											 ;AN000;
	MOV	ES:[BX.IFSR_LENGTH],LENGTH_CLOSEFILE	; prep IFSRH			 ;AN000;
	MOV	ES:[BX.IFSR_FUNCTION],IFSEXECAPI					 ;AN000;
	MOV	ES:[BX.IFSR_APIFUNC],IFSCLOSEFILE					 ;AN000;
	XOR	AL,AL									 ;AN000;
	TEST	IFSPROC_FLAGS,ISCLOSE							 ;AN000;
	JNZ	C_40									 ;AN000;
	INC	AL									 ;AN000;
C_40:											 ;AN000;
	MOV	ES:[BX.IFSR_FUNC],AL							 ;AN000;
											 ;AN000;
	invoke	CALL_IFS			; *** call fs with close request	 ;AN000;
											 ;AN000;
	JNC	C_60									 ;AN000;
	TEST	IFSPROC_FLAGS,ISCLOSE		; ifs error				 ;AN000;
	JZ	C_980				; return w/carry, if close		 ;AN000;
;;;;;;;;ADD	SP,6				; restore stack first			 ;AD018;
	RestoreReg <CX,DI,ES>			; old ref count & sft			 ;AN018;;AC019;
	CMP	CX,1									 ;AN018;;AC019;
	JNE	C_980									 ;AN018;
	MOV	ES:[DI.sf_ref_count],0		; If freeing, need to zap		 ;AN018;
	JMP	C_980									 ;AN000;
C_60:											 ;AN000;
	invoke	SFF_TO_SFT								 ;AN000;
	TEST	IFSPROC_FLAGS,ISCLOSE							 ;AN000;
	JZ	C_990				; finished w/commit			 ;AN000;
C_80:											 ;AN011;
	RestoreReg <AX,DI,ES>			; old ref count & sft			 ;AN000;
	CMP	AX,1									 ;AN000;
	JNE	C_990									 ;AN000;
	MOV	ES:[DI.sf_ref_count],0		; If freeing, need to zap		 ;AN000;
	JMP	C_990				; busy mark				 ;AN000;
											 ;AN000;
											 ;AN000;
C_980:						; Return area				 ;AN000;
	STC										 ;AN000;
	JMP	C_1000									 ;AN000;
C_990:											 ;AN000;
	CLC										 ;AN000;
C_1000: 					; preserve ds - dosgroup		 ;AN000;
	PUSH	SS									 ;AN000;
	POP	DS									 ;AN000;
	return										 ;AN000;
											 ;AN000;
EndProc IFS_COMMIT									 ;AN000;
											 ;AN000;
BREAK <IFS_LSEEK Seek on a NET SFT>							 ;AN000;
											 ;AN000;
;****************************************************************************** 	 ;AN000;
;											 ;AN000;
; IFS_LSEEK										 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	ES:DI -> SFT									 ;AN000;
;	CX:DX = Input CX:DX to $Lseek (offset)						 ;AN000;
;	NOTE: THIS LSEEK IS ALWAYS ASSUMED TO BE A TYPE 2 (relative to EOF)		 ;AN000;
; Function:										 ;AN000;
;     Prep IFSRH:									 ;AN000;
;     *  IFSR_LENGTH	  DW	 44	  ; Request length				 ;AN000;
;     *  IFSR_FUNCTION	  DB	  4	  ; Execute API function			 ;AN000;
;      + IFSR_RETCODE	  DW	  ?							 ;AN000;
;      + IFSR_RETCLASS	  DB	  ?							 ;AN000;
;	 IFSR_RESV1	  DB	 16 DUP(0)						 ;AN000;
;     *  IFSR_APIFUNC	  DB	 10	  ; Lseek file					 ;AN000;
;      + IFSR_ERROR_CLASS DB	  ?							 ;AN000;
;      + IFSR_ERROR_ACTION DB	  ?							 ;AN000;
;      + IFSR_ERROR_LOCUS DB	  ?							 ;AN000;
;      + IFSR_ALLOWED	  DB	  ?							 ;AN000;
;      + IFSR_I24_RETRY   DB	  ?							 ;AN000;
;      + IFSR_I24_RESP	  DB	  ?							 ;AN000;
;	 IFSR_RESV2	  DB	  ?							 ;AN000;
;	 IFSR_DEVICE_CB@  DD	  ?							 ;AN000;
;     *+ IFSR_OPEN_CB@	  DD	  ?	  ; Call SFT_TO_SFFto convert SFT to SF 	 ;AN000;
;					  ; and set this as pointer to it.		 ;AN000;
;     *  IFSR_MODE	  DB	  2	  ; Position mode: - BL 			 ;AN000;
;					  ;   2 = ptr moved eof + offset		 ;AN000;
;	 IFSR_RESV2	  DB	  0							 ;AN000;
;     *  IFSR_POSITION	  DD	  ?	  ; displacement of LSEEK - CX:DX		 ;AN000;
;											 ;AN000;
;     CALL routine, CALL_IFS, with pointer to SF_IFSR_HDR				 ;AN000;
;     IF IFSR_RETCODE = 0 THEN								 ;AN000;
;	 DO										 ;AN000;
;	   Call SFF_TO_SFT								 ;AN000;
;	   Set DX:AX = IFSR_POSITION							 ;AN000;
;	   Clear carry									 ;AN000;
;	 ENDDO										 ;AN000;
;     ELSE DO	  {error}								 ;AN000;
;	     AX = IFSR_RETCODE								 ;AN000;
;	     Set carry									 ;AN000;
;	   ENDDO									 ;AN000;
;     ENDIF										 ;AN000;
; Returns:										 ;AN000;
;	ES:DI -> SFT									 ;AN000;
;	Carry clear									 ;AN000;
;		DX:AX return as with local $Lseek					 ;AN000;
;	Carry Set									 ;AN000;
;		AX is error code							 ;AN000;
; All destroyed 									 ;AN000;
;											 ;AN000;
;****************************************************************************** 	 ;AN000;
											 ;AN000;
	procedure   IFS_LSEEK,NEAR							 ;AN000;
ASSUME	DS:Nothing,ES:NOTHING			; Initially DS is unknown		 ;AN020;
											 ;AN000;
	ifsr_fcn_def  EXECAPI			; define ifsr for lseek 		 ;AN000;
	ifsr_api_def  LSEEKFILE 							 ;AN000;
											 ;AN000;
	PUSH	SS				; Set DS to DOSGROUP			 ;AN020;
	POP	DS				;					 ;AN020;
ASSUME	DS:DOSGROUP				;					 ;AN020;

	MOV	CS:IFSPROC_FLAGS,SETDEVICECB	; init processing flags 		 ;AN000;
	MOV	WORD PTR [THISSFT],DI							 ;AN020;
	MOV	WORD PTR [THISSFT+2],ES 						 ;AN020;
	SaveReg <ES,DI> 			; save for later restore before leave	 ;AN012;;AN020;

	invoke	PREP_IFSR								 ;AN000;
											 ;AN000;
	invoke	DRIVE_FROM_SFT			; set IFSDRV for possible criter	 ;AN000;
	MOV	CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@					 ;AN000;
	invoke	SFT_TO_SFF			; sets: [THISIFS]			 ;AN000;
						;	ES:BX -> IFSRH			 ;AN000;
						;	IFSR_OPEN_CB@			 ;AN000;
						;	ds - IFSSEG			 ;AN000;
											 ;AN000;
	MOV	ES:[BX.IFSR_LENGTH],LENGTH_LSEEKFILE	; prep IFSRH			 ;AN000;
	MOV	ES:[BX.IFSR_FUNCTION],IFSEXECAPI					 ;AN000;
	MOV	ES:[BX.IFSR_APIFUNC],IFSLSEEKFILE					 ;AN000;
	MOV	ES:[BX.IFSR_MODE],MODE2 						 ;AN000;
	MOV	WORD PTR ES:[BX.IFSR_POSITION],DX					 ;AN000;
	MOV	WORD PTR ES:[BX.IFSR_POSITION+2],CX					 ;AN000;
											 ;AN000;
	invoke	CALL_IFS			; call fs with lseek request		 ;AN000;
											 ;AN000;
	JC	LS_1000 								 ;AN000;
	MOV	AX,WORD PTR ES:[BX.IFSR_POSITION]					 ;AN000;
	MOV	DX,WORD PTR ES:[BX.IFSR_POSITION+2]					 ;AN000;
	invoke	SFF_TO_SFT								 ;AN000;
											 ;AN000;
	CLC										 ;AN000;
LS_1000:										 ;AN000;
	RestoreReg <DI,ES>			; restore sft ptr for ibmdos		 ;AN012;
	return										 ;AN000;
											 ;AN000;
EndProc IFS_LSEEK									 ;AN000;
											 ;AN000;
BREAK <IFS_READ Read from a NET SFT>							 ;AN000;
											 ;AN000;
;****************************************************************************** 	 ;AN000;
;											 ;AN000;
; IFS_READ										 ;AN000;
;											 ;AN000;
; Called by:	   IFSFUNC dispatcher							 ;AN000;
;											 ;AN000;
; Routines called: CALL_IFS								 ;AN000;
;		   SFT_TO_SFF								 ;AN000;
;		   SFF_TO_SFT								 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	Outputs of SETUP:								 ;AN000;
;	    CX = byte count								 ;AN000;
;	    ES:DI Points to SFT 							 ;AN000;
;	    [DMAADD] = transfer addr							 ;AN000;
;	SFT checked for access mode							 ;AN000;
; Function:										 ;AN000;
;     Prep IFSRH:									 ;AN000;
;     *  IFSR_LENGTH	  DW	 46	  ; Total length of request			 ;AN000;
;     *  IFSR_FUNCTION	  DB	  4	  ; Execute API function			 ;AN000;
;      + IFSR_RETCODE	  DW	  ?							 ;AN000;
;      + IFSR_RETCLASS	  DB	  ?							 ;AN000;
;	 IFSR_RESV1	  DB	 16 DUP(0)						 ;AN000;
;     *  IFSR_APIFUNC	  DB	 11	  ; Read Byte Block				 ;AN000;
;      + IFSR_ERROR_CLASS DB	  ?							 ;AN000;
;      + IFSR_ERROR_ACTION DB	  ?							 ;AN000;
;      + IFSR_ERROR_LOCUS DB	  ?							 ;AN000;
;      + IFSR_ALLOWED	  DB	  ?							 ;AN000;
;      + IFSR_I24_RETRY   DB	  ?							 ;AN000;
;      + IFSR_I24_RESP	  DB	  ?							 ;AN000;
;	 IFSR_RESV2	  DB	  ?							 ;AN000;
;     *+ IFSR_DEVICE_CB@  DD	  ?	  ; CD/DF - specified in SF_DEVPTR		 ;AN000;
;     *+ IFSR_OPEN_CB@	  DD	  ?	  ; Call SFT_TO_SFFto convert SFT to SF 	 ;AN000;
;					  ; and set this as pointer to it.		 ;AN000;
;	 IFSR_RESV3	  DW	  0							 ;AN000;
;	 IFSR_COUNT	  DW	  0							 ;AN000;
;     *+ IFSR_BUFFER@	  DD	  ?	  ; [DMAADD]					 ;AN000;
;											 ;AN000;
;     CALL routine, CALL_IFS, with pointer to SF_IFSR_HDR				 ;AN000;
;     IF IFSR_RETCODE = 0 THEN								 ;AN000;
;	 DO										 ;AN000;
;	   Call SFF_TO_SFT								 ;AN000;
;	   CX = IFSR_COUNT								 ;AN000;
;	   ES:DI -> SFT 								 ;AN000;
;	 ENDDO										 ;AN000;
;     ELSE DO	  {error}								 ;AN000;
;	     AX = IFSR_RETCODE								 ;AN000;
;	     CX = 0									 ;AN000;
;	     ES:DI -> SFT								 ;AN000;
;	     Set carry									 ;AN000;
;	   ENDDO									 ;AN000;
;     ENDIF										 ;AN000;
; Outputs:										 ;AN000;
;    Carry clear									 ;AN000;
;	SFT Position updated								 ;AN000;
;	CX = No. of bytes read								 ;AN000;
;	ES:DI point to SFT								 ;AN000;
;	[DMAADD] filled with info read							 ;AN000;
;    Carry set										 ;AN000;
;	AX is error code								 ;AN000;
;	CX = 0										 ;AN000;
;	ES:DI point to SFT								 ;AN000;
; DS preserved, all other registers destroyed						 ;AN000;
;											 ;AN000;
;****************************************************************************** 	 ;AN000;
											 ;AN000;
	procedure   IFS_READ,NEAR							 ;AN000;
ASSUME	DS:DOSGROUP,ES:NOTHING								 ;AN000;
											 ;AN000;
	ifsr_fcn_def  EXECAPI			; define ifsr for read			 ;AN000;
	MOV	CS:IFSPROC_FLAGS,SetDeviceCB						 ;AN000;
	MOV	WORD PTR [THISSFT],DI		; set thissft				 ;AN000;
	MOV	WORD PTR [THISSFT+2],ES 						 ;AN000;
											 ;AN000;
R_20:						; (welcome lock/read)			 ;AN000;
	ifsr_api_def  READFILE								 ;AN000;
	invoke	PREP_IFSR			; zero out ifsr, es:bx -> ifsr		 ;AN000;
	MOV	ES:[BX.IFSR_LENGTH],LENGTH_READFILE	; prep IFSRH			 ;AN000;
	MOV	ES:[BX.IFSR_APIFUNC],IFSREADFILE					 ;AN000;
;	XOR	AL,AL				; for now, set mode = read (0)		 ;AD010;
;	TEST	CS:IFSPROC_FLAGS,ISLOCKREAD						 ;AD010;
;	JZ	W_80									 ;AD010;
;	INC	AL				; inc mode to mode_lock_read		 ;AD010;
	JMP	W_80				; cont. read/write common code		 ;AN000;
						;  in ifs_write below			 ;AN000;
											 ;AN000;
EndProc IFS_READ									 ;AN000;
											 ;AN000;
BREAK <IFS_WRITE Write to a NET SFT>							 ;AN000;
											 ;AN000;
;****************************************************************************** 	 ;AN000;
;											 ;AN000;
; IFS_WRITE										 ;AN000;
;											 ;AN000;
; Called by:	   IFSFUNC dispatcher							 ;AN000;
;											 ;AN000;
; Routines called: CALL_IFS								 ;AN000;
;		   SFT_TO_SFF								 ;AN000;
;		   SFF_TO_SFT								 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	Outputs of SETUP:								 ;AN000;
;	    CX = byte count								 ;AN000;
;	    ES:DI Points to SFT 							 ;AN000;
;	    [DMAADD] = transfer addr							 ;AN000;
;	SFT checked for access mode							 ;AN000;
; Function:										 ;AN000;
;     Prep IFSRH:									 ;AN000;
;     *  IFSR_LENGTH	  DW	 46	  ; Length of request				 ;AN000;
;     *  IFSR_FUNCTION	  DB	  4	  ; Execute API function			 ;AN000;
;      + IFSR_RETCODE	  DW	  ?							 ;AN000;
;      + IFSR_RETCLASS	  DB	  ?							 ;AN000;
;	 IFSR_RESV1	  DB	 16 DUP(0)						 ;AN000;
;     *  IFSR_APIFUNC	  DB	 12	  ; Write Byte Block				 ;AN000;
;      + IFSR_ERROR_CLASS DB	  ?							 ;AN000;
;      + IFSR_ERROR_ACTION DB	  ?							 ;AN000;
;      + IFSR_ERROR_LOCUS DB	  ?							 ;AN000;
;      + IFSR_ALLOWED	  DB	  ?							 ;AN000;
;      + IFSR_I24_RETRY   DB	  ?							 ;AN000;
;      + IFSR_I24_RESP	  DB	  ?							 ;AN000;
;	 IFSR_RESV2	  DB	  ?							 ;AN000;
;     *+ IFSR_DEVICE_CB@  DD	  ?							 ;AN000;
;     *+ IFSR_OPEN_CB@	  DD	  ?	  ; call SFT_TO_SFF & set this as ptr		 ;AN000;
;	 IFSR_RESV3	  DW	  0							 ;AN000;
;     *  IFSR_COUNT	  DW	  ?	  ; # bytes to write - CX			 ;AN000;
;     *  IFSR_BUFFER@	  DD	  ?	  ; Data buffer - [DMAADD]			 ;AN000;
;											 ;AN000;
;     CALL routine, CALL_IFS, with pointer to SF_IFSR_HDR				 ;AN000;
;     IF IFSR_RETCODE = 0 THEN								 ;AN000;
;	 DO										 ;AN000;
;	   Call SFF_TO_SFT								 ;AN000;
;	   CX = IFSR_COUNT								 ;AN000;
;	   ES:DI -> SFT 								 ;AN000;
;	   Clear carry									 ;AN000;
;	 ENDDO										 ;AN000;
;     ELSE DO	  {error}								 ;AN000;
;	     AX = IFSR_RETCODE								 ;AN000;
;	     CX = 0									 ;AN000;
;	     ES:DI -> SFT								 ;AN000;
;	     Set carry									 ;AN000;
;	   ENDDO									 ;AN000;
;     ENDIF										 ;AN000;
; Outputs:										 ;AN000;
;    Carry clear									 ;AN000;
;	SFT Position updated								 ;AN000;
;	CX = No. of bytes written							 ;AN000;
;	ES:DI point to SFT								 ;AN000;
;    Carry set										 ;AN000;
;	AX is error code								 ;AN000;
;	CX = 0										 ;AN000;
;	ES:DI point to SFT								 ;AN000;
; DS preserved, all other registers destroyed						 ;AN000;
;											 ;AN000;
;****************************************************************************** 	 ;AN000;
											 ;AN000;
	procedure   IFS_WRITE,NEAR							 ;AN000;
ASSUME	DS:DOSGROUP,ES:NOTHING								 ;AN000;
											 ;AN000;
	ifsr_fcn_def  EXECAPI			; define ifsr for write 		 ;AN000;
	MOV	CS:IFSPROC_FLAGS,SetDeviceCB	; init processing flags 		 ;AN000;
	MOV	WORD PTR [THISSFT],DI		; set thissft				 ;AN000;
	MOV	WORD PTR [THISSFT+2],ES 						 ;AN000;
											 ;AN000;
W_20:						; (welcome write/unlock)		 ;AN000;
	ifsr_api_def  WRITEFILE 							 ;AN000;
	invoke	PREP_IFSR								 ;AN000;
	MOV	ES:[BX.IFSR_LENGTH],LENGTH_WRITEFILE	; prep IFSRH			 ;AN000;
	MOV	ES:[BX.IFSR_APIFUNC],IFSWRITEFILE					 ;AN000;
;	XOR	AL,AL				; for now set mode to write (bit0=0)	 ;AD010;
;	TEST	CS:IFSPROC_FLAGS,ISWRITEUNLOCK						 ;AD010;
;	JZ	W_40									 ;AD010;
;	INC	AL				; set mode to write/unlock (bit0=1)	 ;AD010;
;W_40:											 ;AD010;
;	TEST	CS:IFSPROC_FLAGS,ISADD							 ;AD010;
;	JZ	W_80									 ;AD010;
;	OR	AL,MODE_ADD_MASK		; set mode to add (bit 1)		 ;AD010;
;W_80:						 ; (welcome read)			 ;AD010;
;	TEST	CS:IFSPROC_FLAGS,ISWOLOCK						 ;AD010; BAF
;	JZ	W_90									 ;AD010; BAF
;	OR	AL,MODE_WO_MASK 		; set mode to Write Only Lock		 ;AD010; BAF
;W_90:											 ;AD010; BAF
;	MOV	ES:[BX.IFSR_MODE],AL							 ;AD010;
W_80:						; (welcome read)			 ;AN010;
	MOV	CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@					 ;AC015;
	MOV	ES:[BX.IFSR_FUNCTION],IFSEXECAPI					 ;AN000;
	MOV	ES:[BX.IFSR_COUNT],CX							 ;AN000;
											 ;AN000;
	MOV	AX,WORD PTR [DMAADD]		; to access dmaadd			 ;AN000;
	MOV	WORD PTR ES:[BX.IFSR_BUFFER@],AX					 ;AN000;
	MOV	AX,WORD PTR [DMAADD+2]							 ;AN000;
	MOV	WORD PTR ES:[BX.IFSR_BUFFER@+2],AX					 ;AN000;
											 ;AN000;
	invoke	DRIVE_FROM_SFT			; set IFSDRV for possible criter	 ;AN000;
	invoke	SFT_TO_SFF			; sets: [THISIFS]			 ;AN000;
						;	ES:BX -> IFSRH			 ;AN000;
						;	IFSR_OPEN_CB@			 ;AN000;
						;	ds - IFSSEG			 ;AN000;
											 ;AN000;
	invoke	CALL_IFS			; *** call fs with read/write request	 ;AN000;
											 ;AN000;
	JNC	W_100									 ;AN000;
	Context DS				; restore ds-dosgroup			 ;AN001;
	LES	DI,[THISSFT]			; restore esdi-sft			 ;AN001;
	transfer ifs_1000			; transfer to general ret as carry set	 ;AC001;
W_100:											 ;AN000;
	MOV	CX,ES:[BX.IFSR_COUNT]		; prep reg output			 ;AN000;
	invoke	SFF_TO_SFT								 ;AN000;

	Context DS				; restore ds-dosgroup			 ;AN001;
	LES	DI,[THISSFT]			; restore esdi-sft			 ;AN001;
	transfer ifs_990			; transfer to general good ret in util	 ;AN001;
											 ;AN000;
EndProc IFS_WRITE									 ;AN000;
											 ;AN000;
BREAK <IFS_XLOCK Lock a FS SFT> 							 ;AN000;
											 ;AN000;
;****************************************************************************** 	 ;AN000;
;											 ;AN000;
; IFS_XLOCK										 ;AN000;
;											 ;AN000;
; Called by:	     IFSFUNC dispatcher 						 ;AN000;
;											 ;AN000;
; Routines called:   CALL_IFS		DRIVE_FROM_SFT					 ;AN000;
;		     SFT_TO_SFF 							 ;AN000;
;		     SFF_TO_SFT 							 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	BL = 80H bit: 0  lock all operations						 ;AN000;
;		      1  lock write operations only					 ;AN000;
;	     0	Lock
;	     1	Unlock
;	     2	lock multiple range							 ;AN000;
;	     3	unlock multiple range							 ;AN000;
;	     4	lock/read								 ;AN000;
;	     5	write/unlock								 ;AN000;
;	     6	add (lseek eof/lock/write/unlock)					 ;AN000;
;	ES:DI -> SFT									 ;AN000;
;	CX = count/size  Number of ranges/block size					 ;AN000;
;	DS:DX -> BUFFER  LABEL	DWORD							 ;AN000;
;			 DD	POSITION  ; lock range, repeats CX times		 ;AN000;
;			 DD	LENGTH	  ;						 ;AN000;
;											 ;AN000;
;											 ;AN000;
; Function:										 ;AN000;
;	Prep IFSRH:									 ;AN000;
;	*  IFSR_LENGTH	    DW	   46+	    ; Length of request 			 ;AN000;
;	*  IFSR_FUNCTION    DB	    4	    ; Execute API function			 ;AN000;
;	 + IFSR_RETCODE     DW	    ?							 ;AN000;
;	 + IFSR_RETCLASS    DB	    ?							 ;AN000;
;	   IFSR_RESV1	    DB	   16 DUP(0)						 ;AN000;
;	*  IFSR_APIFUNC     DB	   13	    ; Lock Function				 ;AN000;
;	 + IFSR_ERROR_CLASS DB	    ?							 ;AN000;
;	 + IFSR_ERROR_ACTION DB     ?							 ;AN000;
;	 + IFSR_ERROR_LOCUS DB	    ?							 ;AN000;
;	 + IFSR_ALLOWED     DB	    ?							 ;AN000;
;	 + IFSR_I24_RETRY   DB	    ?							 ;AN000;
;	 + IFSR_I24_RESP    DB	    ?							 ;AN000;
;	   IFSR_RESV2	    DB	    ?							 ;AN000;
;	*+ IFSR_DEVICE_CB@  DD	    ?							 ;AN000;
;	*+ IFSR_OPEN_CB@    DD	    ?	    ; Call SFT_TO_SFFto convert SFT to SFF	 ;AN000;
;					    ; and set this as pointer to it.		 ;AN000;
;	*  IFSR_FUNC	    DB	    subfunction     ; 0=LOCK, 1=UNLOCK			 ;AN000;
;	   IFSR_RESV3	    DB	    DOS reserved					 ;AN000;
;	*  IFSR_POSITION    DD	    range start     ; single range			 ;AN000;
;	*  IFSR_LENGTH	    DD	    range length					 ;AN000;
;											 ;AN000;
;	CALL routine, CALL_IFS, with pointer to SF_IFSR_HDR				 ;AN000;
;	IF IFSR_RETCODE = 0 THEN							 ;AN000;
;	   DO										 ;AN000;
;	     Call SFF_TO_SFT								 ;AN000;
;	     Clear carry								 ;AN000;
;	   ENDDO									 ;AN000;
;	ELSE DO     {error}								 ;AN000;
;	       AX = IFSR_RETCODE							 ;AN000;
;	       Set carry								 ;AN000;
;	     ENDDO									 ;AN000;
;	ENDIF										 ;AN000;
;											 ;AN000;
; Outputs:										 ;AN000;
;	AX set on error: Lock conflict							 ;AN000;
;			 Too many locks 						 ;AN000;
;											 ;AN000;
;****************************************************************************** 	 ;AN000;
											 ;AN000;
	procedure   IFS_XLOCK,NEAR							 ;AN000;
											 ;AN000;
	ifsr_fcn_def  EXECAPI								 ;AN000;
	ifsr_api_def  LOCKFILE								 ;AN000;
											 ;AN000;
	SaveReg <BX>				; save input bl 			 ;AN014;
	MOV	CS:IFSPROC_FLAGS,SetDeviceCB						 ;AC002;
;;;;;;;;TEST	BL,80H									 ;AN006;AD010;
;	JZ	L_10									 ;AN006;AD010;
;	OR	CS:IFSPROC_FLAGS,IsWOLock	; This is Write Only lock		 ;AN006;AD010;
;L_10:											 ;AN006;AD010;
;	SaveReg <BX>				; save function (int 21h al value)	 ;AD010;
;	AND	BL,07FH 			; ditch 80h bit for now 		 ;AD010;
;	CMP	BL,INT21AL_LOCK_READ		; Check for special case locks		 ;AD010;
;	JB	L_60				; these generate different		 ;AD010;
;	JNE	L_20				; ifsrh's.                               ;AD010;
;	OR	CS:IFSPROC_FLAGS,IsLockRead	; This is lock/read request		 ;AD010;
;	RestoreReg <BX> 			; restore bx with 80 bit		 ;AD010;
;	Context DS									 ;AD010;
;	JMP	R_20				; let ifs_read above handle this	 ;AD010;
;L_20:											 ;AD010;
;	CMP	BL,INT21AL_WRITE_UNLOCK 						 ;AD010;
;	RestoreReg <BX> 			; restore bx with 80 bit		 ;AD010;
;	JNE	L_40									 ;AD010;
;	OR	CS:IFSPROC_FLAGS,IsWriteUnlock	; This is write/unlock request		 ;AD010;
;	JMP	SHORT L_50			; cont. ifs_write above 		 ;AD010;
;L_40:											 ;AD010;
;	OR	IFSPROC_FLAGS,IsAdd							 ;AD010;
;L_50:											 ;AD010;
;	Context DS									 ;AD010;
;;;;;;;;JMP	W_20				; cont. in ifs_write above		 ;AD010;
											 ;AN000;
L_60:											 ;AN000;
	SaveReg <DS>				; save input ds (buffer ptr)		 ;AN000;
	Context DS				; ds-dosgroup to access thissft 	 ;AN000;
	MOV	WORD PTR [THISSFT],DI		; set [THISSFT] 			 ;AN000;
	MOV	WORD PTR [THISSFT+2],ES 						 ;AN000;
	invoke	DRIVE_FROM_SFT			; set IFSDRV for possible criter	 ;AN000;
	invoke	PREP_IFSR			; clear ifsrh				 ;AM003;
	MOV	CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@					 ;AN000;
	invoke	SFT_TO_SFF			; sets: [THISIFS]			 ;AN000;
						;	ES:BX -> IFSRH			 ;AN000;
						;	IFSR_OPEN_CB@			 ;AN000;
						;	ds - IFSSEG			 ;AN000;
	MOV	ES:[BX.IFSR_LENGTH],LENGTH_LOCKFILE	; prep IFSRH			 ;AN000;
	MOV	ES:[BX.IFSR_FUNCTION],IFSEXECAPI					 ;AN000;
	MOV	ES:[BX.IFSR_APIFUNC],IFSLOCKFILE					 ;AN000;
;;;;;;;;MOV	ES:[BX.IFSR_COUNT],CX							 ;AN003;AD010;
	RestoreReg <DS> 			; range segment, mode (input bl)	 ;AC003;AC010;
;;;;;;;;MOV	AL,CL									 ;AN003;AD010;
;	AND	AL,07FH 			; mask off hi 80 bit			 ;AN003;AD010;
;	CMP	AL,2									 ;AN003;AD010;
;	JGE	L_70									 ;AN003;AD010;
;	ADD	CL,2									 ;AN003;AD010;
;L_70:											 ;AN003;AD010;
;	MOV	ES:[BX.IFSR_MODE],CL							 ;AN000;AD010;
;	AND	ES:[BX.IFSR_MODE],80H		; ditch input bl in low nibble		 ;AN005;AD010;
;	AND	CL,07FH 								 ;AN003;AD010;
;;;;;;;;SUB	CL,2				; set func (0-lock,1-unlock)		 ;AC003;AD010;
	RestoreReg <AX> 			; restore input bl into al		 ;AN014;
	MOV	ES:[BX.IFSR_FUNC],AL							 ;AC003;AC010;
;;;;;;;;MOV	WORD PTR ES:[BX.IFSR_RANGE@],DX 					 ;AD010;
;;;;;;;;MOV	WORD PTR ES:[BX.IFSR_RANGE@+2],DS					 ;AD010;
	SaveReg <SI,DX> 								 ;AN010;
	RestoreReg <SI> 								 ;AN010;
	MOV	AX,WORD PTR DS:[SI]							 ;AN010;
	MOV	WORD PTR ES:[BX.IFSR_LK_POSITION],AX					 ;AN010;
	MOV	AX,WORD PTR DS:[SI+2]							 ;AN010;
	MOV	WORD PTR ES:[BX.IFSR_LK_POSITION+2],AX					 ;AN010;
	MOV	AX,WORD PTR DS:[SI+4]							 ;AN010;
	MOV	WORD PTR ES:[BX.IFSR_LK_LENGTH],AX					 ;AN010;
	MOV	AX,WORD PTR DS:[SI+6]							 ;AN010;
	MOV	WORD PTR ES:[BX.IFSR_LK_LENGTH+2],AX					 ;AN010;
	RestoreReg <SI>
	SaveReg <CS>				; set ds=ifsseg for ifs call		 ;AN003;
	RestoreReg <DS> 								 ;AN003;

	invoke	CALL_IFS			; *** call fs with lock request 	 ;AN000;
											 ;AN000;
	JNC	L_100									 ;AN000;
	transfer ifs_1000			; go to general return	 (util) 	 ;AN000;
L_100:											 ;AN000;
	invoke	SFF_TO_SFT								 ;AN000;
	transfer ifs_990			; go to general good ret (util) 	 ;AN000;
											 ;AN000;
											 ;AN000;
EndProc IFS_XLOCK									 ;AN000;
											 ;AN000;
BREAK <IFS_FILE_XATTRIBUTES Get/Set File Extended Attributes by handle> 		 ;AN000;

;******************************************************************************
;
; IFS_FILE_XATTRIBUTES
;
; Called by:	     IFSFUNC dispatcher
;
; Routines called:   CALL_IFS	  DRIVE_FROM_SFT
;		     SFT_TO_SFF
;		     SFF_TO_SFT
;
; Inputs:
;	[THISSFT] Points to SFT being used
;	[SAVE_ES:DI] -> Buffer for EA or EA names list
;	[SAVE_DS:SI] -> Query List  (BL=2)
;	[SAVE_CX] = buffer size     (BL=2,3)
;	BL	  = function - 2=Get EA
;			3=Get EA Names
;			4=Set EA
;
; Function:
;	This call is driven by the new INT 21H call 57H.  *** REMOVED
;	     Prep IFSRH:
;	     *	IFSR_LENGTH	 DW	50	 ; Total length of request
;	     *	IFSR_FUNCTION	 DB	 4	 ; Execute API function
;	      + IFSR_RETCODE	 DW	 ?
;	      + IFSR_RETCLASS	 DB	 ?
;		IFSR_RESV1	 DB	16 DUP(0)
;	     *	IFSR_APIFUNC	 DB	15	 ; File Attributes - get/set by name
;	      + IFSR_ERROR_CLASS DB	 ?
;	      + IFSR_ERROR_ACTION DB	 ?
;	      + IFSR_ERROR_LOCUS DB	 ?
;	      + IFSR_ALLOWED	 DB	 ?
;	      + IFSR_I24_RETRY	 DB	 ?
;	      + IFSR_I24_RESP	 DB	 ?
;		IFSR_RESV2	 DB	 ?
;		IFSR_DEVICE_CB@  DD	 ?
;	     *+ IFSR_OPEN_CB@	 DD	 ?
;	     *	IFSR_FUNC	 DB	 ?	 ; 0-get 1-set
;	     *	IFSR_SUBFUNC	 DB	 ?	 ; 2-EA  3-EA names
;	     *+ IFSR_BUFFER1@	 DD	 ?	 ; Query List
;	     *+ IFSR_BUFFER2@	 DD	 ?	 ; EA List
;	     *+ IFSR_COUNT	 DW	 ?	 ; count
;
;	     CALL routine, CALL_IFS, with pointer to SF_IFSR_HDR
;	     IF IFSR_RETCODE = 0 THEN
;		DO
;		  Call SFF_TO_SFT
;		  Clear carry
;		ENDDO
;	     ELSE DO
;		    AX = IFSR_RETCODE
;		    Set carry
;		  ENDDO
;	     ENDIF
;	   ENDDO
;
; Outputs:
;	Carry clear:  On Get:
;			QUERY LIST or LIST filled in.
;		      On Set:
;			Extended attributes set.  All SFTs are updated.
;	CARRY SET
;	Carry set:    AX is error code
;		error_file_not_found
;			Last element of path not found
;		error_path_not_found
;			Bad path (not in curr dir part if present)
;		error_access_denied
;			Attempt to set an attribute which cannot be set
;			(attr_directory, attr_volume_ID)
;		error_sharing_violation
;			Sharing mode of file did not allow the change
;			(this request requires exclusive write/read access)
;			(INT 24H generated)
; DS preserved, others destroyed
;
;******************************************************************************
											 ;AN000;
	procedure   IFS_FILE_XATTRIBUTES,NEAR						 ;AN000;
											 ;AN000;
;;;;;;;;ifsr_fcn_def  EXECAPI			; define ifsr for fileattr		 ;AN000;
;	ifsr_api_def  FILEATTR								 ;AN000;
;											 ;AN000;
;	MOV	CS:IFSPROC_FLAGS,SetDeviceCB	; init processing flags 		 ;AN000;
;	SaveReg <BX>				; save input function (2,3,4)		 ;AN000;
;											 ;AN000;
;	invoke	PREP_IFSR			; init ifsr				 ;AN000;
;	Context DS				; ds - dosgroup 			 ;AN000;
;											 ;AN000;
;	invoke	DRIVE_FROM_SFT			; set IFSDRV for possible criter	 ;AN000;
;	MOV	CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@					 ;AN000;
;	MOV	ES:[BX.IFSR_LENGTH],LENGTH_FILEATTR	; prep IFSRH			 ;AN000;
;	MOV	ES:[BX.IFSR_FUNCTION],IFSEXECAPI					 ;AN000;
;	MOV	ES:[BX.IFSR_APIFUNC],IFSFILEATTR					 ;AN000;
;	MOV	AL,FUNC_GET_BY_HANDLE		; start ifsr_func with get		 ;AN000;
;;;;;;;;RestoreReg <CX> 			; get original BX - func		 ;AN000;

	CMP	BL,4				;					 ;AC010;
	JNE	XFA_40				;					 ;AC010;
	JMP	C_990				; just ret success if set		 ;AC010;
XFA_40: 										 ;AN000;

;;;;;;;;MOV	ES:[BX.IFSR_FUNC],AL							 ;AN000;
;	MOV	AL,SUBFUNC_EA			; start ifsr_subfunc w/ea list		 ;AN000;
;	CMP	CL,3				; (input get ea names)			 ;AN000;
;	JNE	XFA_80									 ;AN000;
;	INC	AL				; inc ifsr_subfunc to ea names		 ;AN000;
;FA_80: 										 ;AN000;
;	MOV	ES:[BX.IFSR_SUBFUNC],AL 						 ;AN000;
;	CMP	CL,4				; no size offered on set so don't check  ;AN009;
;	JE	XFA_82									 ;AN009;
;
;FA_82: 										 ;AN009;
;	MOV	AX,[SAVE_DI]								 ;AN000;
;	MOV	WORD PTR ES:[BX.IFSR_BUFFER2@],AX   ; get     list ptr into buffer2@	 ;AC002;
;	MOV	AX,[SAVE_ES]								 ;AN000;
;	MOV	WORD PTR ES:[BX.IFSR_BUFFER2@+2],AX ; get     list ptr into buffer2@	 ;AC002;
;FA_85: 										 ;AN008;
;	CMP	CL,2				    ; get ea list with qlist		 ;AN000;
;	JNE	XFA_90									 ;AN000;
;	MOV	AX,[SAVE_SI]								 ;AN000;
;	CMP	AX,NULL_PTR			    ; if null, don't set buffer1         ;AN005;
;	JE	XFA_90									 ;AN005;
;	MOV	WORD PTR ES:[BX.IFSR_BUFFER1@],AX   ; get     list ptr into buffer2@	 ;AC002;
;	MOV	AX,[SAVE_DS]								 ;AN000;
;	MOV	WORD PTR ES:[BX.IFSR_BUFFER1@+2],AX ; get     list ptr into buffer2@	 ;AC002;
;FA_90: 										 ;AN000;
;	PUSH	[SAVE_CX]			    ; buffer size			 ;AN000;
;	POP	ES:[BX.IFSR_COUNT]							 ;AN000;
;	invoke	SFT_TO_SFF			; sets: [THISIFS]			 ;AN000;
;						;	ES:BX -> IFSRH			 ;AN000;
;						;	IFSR_OPEN_CB@			 ;AN000;
;						;	ds - IFSSEG			 ;AN000;
;************************************************
;	invoke	CALL_IFS			; *** call fs with fileattr request	 ;AN000;
;************************************************
;	JNC	XFA_100 								 ;AN000;
;	JMP	C_1000									 ;AN000;
;FA_100:										 ;AN000;
;;;;;;;;invoke	SFF_TO_SFT								 ;AN000;


	Context DS				; on get - set size to 2 and count=0	 ;AN010;
	MOV	AX,[SAVE_CX]			; if count < 2 than no buffer2		 ;AN008;;AC013;
	CMP	AX,2									 ;AN008;;AC013;
	JGE	XFA_120 								 ;AN008;;AC013;
	XOR	AX,AX
	JMP	SHORT XFA_140
XFA_120:										 ;AN013;
	PUSH	[SAVE_ES]								 ;AN010;
	POP	ES									 ;AN010;
	MOV	DI,[SAVE_DI]								 ;AN010;
	XOR	AX,AX									 ;AN010;
	STOSW					; count in buffer			 ;AN010;
	MOV	AX,2									 ;AN007;AC010;
XFA_140:										 ;AN013;
	SaveReg <AX>				; preserve future cx			 ;AN016;
	CallInstall Get_User_Stack,multDOS,24	; put size  in user cx			 ;AN007;
	RestoreReg <AX> 			; restore future cx			 ;AN016;
	MOV	DS:[SI.USER_CX],AX							 ;AN007;
	JMP	C_990				; go ret in close to get ds-dosgroup	 ;AN000;
											 ;AN000;
											 ;AN000;
EndProc IFS_FILE_XATTRIBUTES								 ;AN000;
											 ;AN000;
											 ;AN000;
IFSSEG	ENDS										 ;AN000;
    END 										 ;AN000;
