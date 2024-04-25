	PAGE	,132				; 					 ;AN000;
;	SCCSID = @(#)IFSERROR.INC	1.0 87/05/11					 ;AN000;
TITLE	IFSFUNC ERROR ROUTINES								 ;AN000;
NAME	IFSERROR									 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; IFS error Routines									 ;AN000;
;											 ;AN000;
;   INT_2F_5										 ;AN000;
;											 ;AN000;
;   IFS_I24										 ;AN000;
;   SET_EXTERR_INFO									 ;AN000;
;   PHONEY_DPB										 ;AN000;
;											 ;AN000;
; REVISION HISTORY:									 ;AN000;
;	Evolved from Network Redirector NETERROR:  MAY 11 1987				 ;AN000;
;	A000 - Original version 4.00	MAY 1987					 ;AN000;
;	A001 - PTM 842	Messages
;	A002 - PTM 1602 INT 2f-5 interface ds bug   RG 10/87
;	A003 - PTM 1683/1769 error msg problems     RG 10/87
;	A004 - PTM 2827 error proc chgs 	    RG 1/88
;	A005 - PTM 4140 int 2f 5 interface change   RMG 4/12/88
;	A006 - P4789  message problems w/no ifs drivers loaded	      5/18/88 RMG
;	A007 - P4962 I24 AH not set right for printer		      5/24/88 RMG
;	A008 - P5030 I24 tempbuf conflict			      6/03/88 RMG
;											 ;AN000;
; LOC - 167										 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
.xlist											 ;AN000;
.xcref											 ;AN000;
INCLUDE IFSSYM.INC									 ;AN000;
INCLUDE IFSFSYM.INC									 ;AN000;
INCLUDE DOSSYM.INC									 ;AN000;
INCLUDE DEVSYM.INC									 ;AN000;
INCLUDE SYSMSG.INC
msg_utilname <IFSFUNC>
.cref											 ;AN000;
.list											 ;AN000;
											 ;AN000;
AsmVars <IBM, Installed, Debug> 							 ;AN000;
											 ;AN000;
; define the base code segment of the network support  first				 ;AN000;
											 ;AN000;
IFSSEG	SEGMENT BYTE PUBLIC 'IFSSEG'                                                     ;AN000;
IFSSEG	ENDS										 ;AN000;
											 ;AN000;
; include the rest of the segment definitions for normal MSDOS				 ;AN000;
											 ;AN000;
include dosseg.asm									 ;AN000;
											 ;AN000;
DATA		SEGMENT WORD PUBLIC 'DATA'                                               ;AN000;
	; DOSGROUP Data 								 ;AN000;
	Extrn	THISDPB:DWORD								 ;AN000;
	Extrn	EXTERR:WORD								 ;AN000;
	Extrn	EXTERR_ACTION:BYTE							 ;AN000;
	Extrn	EXTERR_CLASS:BYTE							 ;AN000;
	Extrn	EXTERR_LOCUS:BYTE							 ;AN000;
	Extrn	ALLOWED:BYTE								 ;AN000;
	Extrn	ExitHold:DWORD								 ;AN000;
	Extrn	ERR_TABLE_21:BYTE
DATA		ENDS									 ;AN000;
											 ;AN000;
IFSSEG	SEGMENT BYTE PUBLIC 'IFSSEG'                                                     ;AN000;
	ASSUME	SS:DOSGROUP,CS:IFSSEG							 ;AN000;
											 ;AN000;
	; IFS Data									 ;AN000;
	Extrn	IFSDRV:BYTE								 ;AN000;
	Extrn	IFSR:WORD								 ;AN000;
	Extrn	TEMPBUF:BYTE								 ;AN003;
	Extrn	IFSPROC_FLAGS:WORD							 ;AN003;
	Extrn	SYSGetMsg:NEAR
	Extrn	IFSSEM:BYTE
	Extrn	THISIFS:DWORD								 ;AN006;
											 ;AN000;
; Phoney DPB used by IFS Share/Lock errors						 ;AN000;
											 ;AN000;
DUMMY_DPB LABEL BYTE									 ;AN000;
	DB	0   ; dpb_drive 							 ;AN000;
	DB	0   ; dpb_UNIT								 ;AN000;
	DW	512 ; dpb_sector_size							 ;AN000;
	DB	0   ; dpb_cluster_mask							 ;AN000;
	DB	0   ; dpb_cluster_shift 						 ;AN000;
	DW	1   ; dpb_first_FAT							 ;AN000;
	DB	1   ; dpb_FAT_count							 ;AN000;
	DW	16  ; dpb_root_entries							 ;AN000;
	DW	3   ; dpb_first_sector							 ;AN000;
	DW	3   ; dpb_max_cluster							 ;AN000;
	DB	1   ; dpb_FAT_size							 ;AN000;
	DW	2   ; dpb_dir_sector							 ;AN000;
	DD	?   ; dpb_driver_addr							 ;AN000;
	DB	0F8H ; dpb_media							 ;AN000;
	DB	-1  ; dpb_first_access							 ;AN000;
	DW	-1  ; dpb_next_dpb low							 ;AN000;
	DW	-1  ; dpb_next_dpb high 						 ;AN000;
	DW	0   ; dpb_next_free							 ;AN000;
	DW	-1  ; dpb_free_cnt							 ;AN000;
											 ;AN000;
; Phoney device headers used by IFS INT 24H						 ;AN000;
											 ;AN000;
PHONEY_BLOCK	LABEL  BYTE								 ;AN000;
	DD	?			; Pointer					 ;AN000;
	DW	ISNET			; Block net dev 				 ;AN000;
	DW	?			; Strat entry					 ;AN000;
	DW	?			; Int entry					 ;AN000;
	DB	8 DUP (0)								 ;AN000;
											 ;AN000;
PHONEY_DEVICE	LABEL  BYTE								 ;AN000;
	DD	?			; Pointer					 ;AN000;
	DW	DEVTYP + ISNET		; Char net dev					 ;AN000;
	DW	?			; Strat entry					 ;AN000;
	DW	?			; Int entry					 ;AN000;
											 ;AN000;
	PUBLIC	PHONEY_NAME								 ;AN000;
PHONEY_NAME	DB	"        "                                                       ;AN000;
											 ;AN000;
											 ;AN000;
NEXT_2F_5	DD	?								 ;AN000;
PUBLIC	NEXT_2F_5									 ;AN000;
											 ;AN000;
;											 ;AN000;
;											 ;AN000;
MAXERR	EQU	89		; Don't know errors above 79                             ;AN000;
											 ;AN000;
	PUBLIC	 RODS_LABEL
RODS_LABEL	LABEL	BYTE
.xcref											 ;AN000;
.xlist
MSG_SERVICES <IFSFUNC.CL1>
.cref											 ;AN000;
.list

;
; The following table defines CLASS ACTION and LOCUS info for the INT 21H/24H
; errors.  Each entry is 5 bytes long:
;
;	Err#,Class,Action,Locus,Allowed_Val
;

ERR_TABLE_IFS	LABEL	BYTE
  DB errCLASS_BadFmt,  errACT_User,   errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;50	  ;AN003;
  DB errCLASS_TempSit, errACT_DlyRet, errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;51	  ;AN003;
  DB errCLASS_Already, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;52	  ;AN003;
  DB errCLASS_NotFnd,  errACT_User,   errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;53	  ;AN003;
  DB errCLASS_TempSit, errACT_DlyRet, errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;54	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;55	  ;AN003;
  DB errCLASS_OutRes,  errACT_DlyRet, errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;56	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;57	  ;AN003;
  DB errCLASS_BadFmt,  errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;58	  ;AN003;
  DB errCLASS_SysFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;59	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;60	  ;AN003;
  DB errCLASS_OutRes,  errACT_DlyRet, errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;61	  ;AN003;
  DB errCLASS_OutRes,  errACT_DlyRet, errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;62	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;63	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;64	  ;AN003;
  DB errCLASS_Auth,    errACT_User,   errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;65	  ;AN003;
  DB errCLASS_BadFmt,  errACT_User,   errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;66	  ;AN003;
  DB errCLASS_NotFnd,  errACT_User,   errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;67	  ;AN003;
  DB errCLASS_OutRes,  errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;68	  ;AN003;
  DB errCLASS_OutRes,  errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;69	  ;AN003;
  DB errCLASS_TempSit, errACT_DlyRet, errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;70	  ;AN003;
  DB errCLASS_BadFmt,  errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;71	  ;AN003;
  DB errCLASS_TempSit, errACT_Retry,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;72	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;73	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;74	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;75	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;76	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;77	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;78	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;79	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;80	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;81	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;82	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;83	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;84	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;85	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;86	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;87	  ;AN003;
  DB errCLASS_HrdFail, errACT_Abort,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;88	  ;AN003;
  DB errCLASS_Unk,     errACT_Panic,  errLOC_Disk, Allowed_FAIL+Allowed_RETRY	;??	  ;AN003;

;
; We need to map old int 24 errors and device driver errors into the new set
; of errors.  The following table is indexed by the new errors
;
ErrMap24    Label   BYTE
    DB	error_write_protect		;   0
    DB	error_bad_unit			;   1
    DB	error_not_ready 		;   2
    DB	error_bad_command		;   3
    DB	error_CRC			;   4
    DB	error_bad_length		;   5
    DB	error_Seek			;   6
    DB	error_not_DOS_disk		;   7
    DB	error_sector_not_found		;   8
    DB	error_out_of_paper		;   9
    DB	error_write_fault		;   A
    DB	error_read_fault		;   B
    DB	error_gen_failure		;   C
    DB	error_gen_failure		;   D	RESERVED
    DB	error_gen_failure		;   E	RESERVED
    DB	error_wrong_disk		;   F

ErrMap24End LABEL   BYTE


BREAK <INT_2F_5 -- Routine for Extended error messages>

;************************************************************************************
;
; INT_2F_5
;
; Called by:	   COMMAND.COM
;
; Routines called: CALL_IFS
;
; Input:  [THISIFS] set
;	  BX = extended error number							;AN005;
;	  AL = component ID  0 - install check						;AN005;
;			     1 - command.com						;AN005;
;			     2 - message retriever					;AN005;
; Function:
; This handler uses 2F multiplex number 5. It allows the INT 24H
; Handler in COMMAND to get message texts for NET extended errors.
;
;   IF AH = 5 THEN
;     DO
;      IF AL < 0F8H  THEN
;	  DO
;	  ³ IF AL .NE. 0 THEN
;	  ³    DO
;	  ³    ³ IF AL >= 50 .AND. AL <= 74 THEN    /* or AL = 88 */
;	  ³    ³    DO
;	  ³    ³    ³ Prep IFSRH below
;	  ³    ³    ³	*  IFSR_LENGTH	    DW	   28	    ; Request length
;	  ³    ³    ³	*  IFSR_FUNCTION    DB	    6	    ; Get Criter Text
;	  ³    ³    ³	*+ IFSR_RETCODE     DB	    ?	    ; AL
;	  ³    ³    ³	   IFSR_RETCLASS    DB	    ?
;	  ³    ³    ³	   IFSR_RESV1	    DB	   17 DUP(0)
;	  ³    ³    ³	*+ IFSR_MSG@	    DD	    ?	    ; Msg buffer address
;	  ³    ³    ³	*+ IFSR_MSG_TYPE    DB	    ?	    ; Msg type
;	  ³    ³    ³	   IFSR_RESV2	    DB	    ?
;	  ³    ³    ³
;	  ³    ³    ³ Call IFS specified in [THISIFS]
;	  ³    ³    ³ IF IFSR_RETCODE = 0 THEN
;	  ³    ³    ³	 DO
;	  ³    ³    ³	   ES:DI = IFSR_MSG@
;	  ³    ³    ³	   AL = IFSR_MSG_TYPE
;	  ³    ³    ³	 ENDDO
;	  ³    ³    ³ ELSE  get ifsfunc standard msg
;	  ³    ³    ³ ENDIF
;	  ³    ³    ³ RET 2
;	  ³    ³    ENDDO
;	  ³    ³ ELSE  RET 2
;	  ³    ³ ENDIF
;	  ³    ENDDO
;	  ³ ELSE DO
;	  ³	   AL = 0FFH  /* install check */
;	  ³	   iret
;	  ³	 ENDDO
;	  ³ ENDIF
;	  ENDDO
;      ELSE  iret
;      ENDIF
;     ENDDO
; ELSE	jump far to [NEXT_2F_5]
; ENDIF
;
; Output:  carry clear - AL = msg type (0 or 1)
;			   If EType is 1 then message is printed in form
;				<message>
;				Abort, Retry Ignore
;			   If EType is 0 then message is printed in form
;				<message> error (read/writ)ing (drive/device) XXX
;				Abort, Retry Ignore
;			   The message is ASCIZ and DOES NOT
;			   include a trailing CR,LF
;			 ES:DI -> message text
;			 carry set   - no message
;
; Notes:   all destroyed
;
;************************************************************************************
											 ;AN000;
	procedure INT_2F_5,FAR								 ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING						 ;AN000;
											 ;AN000;
	ifsr_fcn_def  CRITMSG								 ;AN000;
											 ;AN000;
	CMP	AH,5				; check for IFS error 2F call		 ;AN000;
	JZ	I2F5_20 								 ;AN000;
	JMP	[NEXT_2F_5]								 ;AN000;
											 ;AN000;
I2F5_20:					; call ok				 ;AN000;
	STI					; INTs OK				 ;AN000;
	CMP	AL,0F8H 								 ;AN000;
	JB	I2F5_40 								 ;AN000;
	IRET					; IRET on reserved functions		 ;AN000;
I2F5_40:										 ;AN000;
	OR	AL,AL									 ;AN000;
	JNZ	I2F5_60 								 ;AN000;
	MOV	AL,0FFH 			; Tell Ellen I'm here                    ;AN000;
	IRET										 ;AN000;
I2F5_60:										 ;AN000;
;;;;;;;;CMP	AL,error_NET_write_fault	 ; check for special error		 ;AN000;
;;;;;;;;JE	I2F5_80 								 ;AN000;
	CMP	BX,50									 ;AC005;
	JAE	I2F5_70
	JMP	I2F5_1000			; Carry set				 ;AN000;
I2F5_70:
	CMP	BX,MAXERR								 ;AC005;
	JBE	I2F5_80 								 ;AN000;
I2F5_75:										 ;AN005;
	STC										 ;AN000;
	JMP	I2F5_1000								 ;AN000;
											 ;AN000;
I2F5_80:										 ;AN000;
	CMP	WORD PTR CS:[THISIFS+2],NULL_PTR ;if no ifs driver set, quit w/carry	 ;AN006;
	JNE	I2F5_85 								 ;AN006;
	CMP	WORD PTR CS:[THISIFS],NULL_PTR						 ;AN006;
	JZ	I2F5_75 								 ;AN006;
I2F5_85:										 ;AN006;
	TEST	CS:IFSSEM,MR_ERRMSG_SEM 	; if already in msgret loop, exit fast	 ;AN005;
	JNZ	I2F5_75 								 ;AN005;
	MOV	CS:IFSPROC_FLAGS,0							 ;AN005;
	CMP	AL,I2F5_MsgRet								 ;AN005;
	JNE	I2F5_90 								 ;AN005;
	OR	CS:IFSPROC_FLAGS,IsMsgRet						 ;AN005;
	OR	CS:IFSSEM,MR_ERRMSG_SEM 	; set msgret error msg semaphore	 ;AN005;
I2F5_90:										 ;AN005;
	SaveReg <DS,SI,BX,CS>			; save command.com regs 		 ;AN002;AC003;
	RestoreReg <DS> 			; set ds-ifsseg 			 ;AN002;
	MOV	AX,BX				; whole ax now ext error		 ;AN003;;AC005;
	SaveReg <AX>				; save ext err #			 ;AN000;
	invoke	PREP_IFSR			; zero out ifsr, sets es:bx -> ifsr	 ;AN000;
	MOV	ES:[BX.IFSR_LENGTH],LENGTH_CRITMSG					 ;AN000;
	MOV	ES:[BX.IFSR_FUNCTION],IFSCRITMSG					 ;AN000;
	MOV	ES:[BX.IFSR_RETCODE],AX 						 ;AN003;

;***********************************************************************************************
	invoke	CALL_IFS			; call ifs with chance to set errmsg	 ;AN000;
;***********************************************************************************************

	JNC	I2F5_200								 ;AN000;
	POP	AX				; fs error set - get ifsfunc msg	 ;AN000;
	TEST	CS:IFSPROC_FLAGS,IsMsgRet	;   if msg ret don't call msg ret for    ;AN005;
	JZ	I2F5_95 			;   default msg - just fail		 ;AN005;
	STC										 ;AN005;
	JMP	SHORT I2F5_220								 ;AN005;
I2F5_95:										 ;AN005;
	MOV	DH,1									 ;AN000;
	CALL	SYSGETMSG			; puts msg in dssi,cx=msg size		 ;AN000;
	MOV	AH,1				; set al = msg type 0 or 1		 ;AN000;
	CMP	AL,55				; all but 55,64,65,88 are 1		 ;AN000;
	JL	I2F5_120								 ;AN000;
	JE	I2F5_100								 ;AN000;
	CMP	AL,64									 ;AN000;
	JL	I2F5_120								 ;AN000;
	JE	I2F5_100								 ;AN000;
	CMP	AL,65									 ;AN000;
	JE	I2F5_100								 ;AN000;
	CMP	AL,88									 ;AN000;
	JNE	I2F5_120								 ;AN000;
											 ;AN000;
I2F5_100:										 ;AN000;
	DEC	AH									 ;AN000;
											 ;AN000;
I2F5_120:										 ;AN000;
	MOV	AL,AH									 ;AN000;
	SaveReg <CS>				; msg ret has 0D0A24 at end of msg	 ;AN003;
	RestoreReg <ES> 			; must change this to asciiz		 ;AN003;
	MOV	DI,OFFSET CS:TEMPBUF+80 	; move to temp buff and put 0 at 0DH	 ;AN003;;AC008;(80)
	SaveReg <DI,AX> 			; preserve msg offset and msg type	 ;AN003;
	REP	MOVSB				; move msg to temp buff 		 ;AN003;
	XOR	AL,AL									 ;AN003;
	STOSB					; store zero at end			 ;AN003;
I2F5_160:										 ;AN003;
	RestoreReg <AX,DI>			; msg type/ msg offset			 ;AN003;
	JMP	SHORT I2F5_220								 ;AN000;
											 ;AN000;
											 ;AN000;
I2F5_200:					; fs supplies error msg 		 ;AN000;
	MOV	AL,ES:[BX.IFSR_MSG_TYPE]	; grab ifs msg info			 ;AN000;
	MOV	DI,WORD PTR ES:[BX.IFSR_MSG@]						 ;AN000;
	MOV	ES,WORD PTR ES:[BX.IFSR_MSG@+2] 					 ;AN000;
	ADD	SP,2				; restore stack 			 ;AN000;
I2F5_220:										 ;AN000;
	PUSHF					; save carry				 ;AN005;
	TEST	CS:IFSPROC_FLAGS,IsMsgRet	; if msgret reset semaphore		 ;AN005;
	JZ	I2F5_240								 ;AN005;
	AND	CS:IFSSEM,NOT MR_ERRMSG_SEM						 ;AN005;
I2F5_240:										 ;AN005;
	POPF					; restore carry 			 ;AN005;
	RestoreReg <BX,SI,DS>			; retrieve command.com regs		 ;AN002;AC003;
											 ;AN000;
I2F5_1000:										 ;AN000;
	RET	2				; Fakey IRET				 ;AN000;
											 ;AN000;
EndProc INT_2F_5									 ;AN000;
											 ;AN000;
ASSUME	SS:DOSGROUP									 ;AN000;
											 ;AN000;
											 ;AN000;
											 ;AN000;
BREAK <SET_EXTERR_INFO -- Set IBMDOS error info>					 ;AN000;
											 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; SET_EXTERR_INFO									 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	AL is extended error								 ;AN000;
;	IFSR										 ;AN000;
;											 ;AN000;
; Function:										 ;AN000;
;	Set all the EXTERR stuff and ALLOWED						 ;AN000;
;											 ;AN000;
; Outputs:										 ;AN000;
;	following set:									 ;AN000;
;	EXTERR		word								 ;AN000;
;	EXTERR_ACTION	byte								 ;AN000;
;	EXTERR_CLASS	 "                                                               ;AN000;
;	EXTERR_LOCUS	 "                                                               ;AN000;
;	ALLOWED 	 "                                                               ;AN000;
;											 ;AN000;
; Regs: all preserved									 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
	procedure SET_EXTERR_INFO,NEAR							 ;AN000;
    ASSUME  DS:IFSSEG,ES:NOTHING							 ;AN000;
											 ;AN000;
	ifsr_fcn_def  EXECAPI								 ;AN000;
											 ;AN000;
	PUSHF										 ;AN000;
	SaveReg <AX,CX,SI,DS>								 ;AC003;
											 ;AN000;
	XOR	AH,AH				; set unknown ah=0			 ;AN003;
	MOV	SS:[EXTERR],AX			; Set extended error			 ;AC003;
	MOV	SI,OFFSET ERR_TABLE_IFS 						 ;AC003;
	SaveReg <CS>									 ;AN003;
	RestoreReg <DS> 			; ds-ifsseg to access err_table_ifs	 ;AN003;
	CMP	AL,50				; if err not in range, set to ??	 ;AN003;
	JL	SEI_10									 ;AN003;
	CMP	AL,88									 ;AN003;
	JLE	SEI_20									 ;AN003;
SEI_10: 										 ;AN003;
	MOV	AL,89									 ;AN003;
											 ;AN003;
SEI_20: 										 ;AN003;
	SUB	AL,50				; space to correct table entry		 ;AN003;
	MOV	CL,4
	MUL	CL									 ;AN003;
	ADD	SI,AX									 ;AN003;

SEI_40: 										 ;AN003;
	LODSW					; AL is CLASS, AH is ACTION		 ;AN003;
	MOV	[EXTERR_ACTION],AH		; Set ACTION				 ;AN003;
	MOV	[EXTERR_CLASS],AL		; Set CLASS				 ;AN003;
	LODSW					; al- LOCUS ah- ALLOWED 		 ;AN003;
	TEST	IFSPROC_FLAGS,ISCDS							 ;AN003;
	JNZ	SEI_50									 ;AN003;
	ADD	AL,2									 ;AN003;
SEI_50: 										 ;AN003;
	MOV	[EXTERR_LOCUS],AL							 ;AN003;
	MOV	[ALLOWED],AH								 ;AN003;
											 ;AN003;
	MOV	SI,BX				; Set ds:si -> ifsr so can use		 ;AN003;
	SaveReg <ES>				; lodsw to get cl,act,loc,allowed	 ;AN003;
	RestoreReg <DS> 								 ;AN003;
	ADD	SI,IFSR_ERROR_CLASS							 ;AN003;
						; only set if ifs set (not -1)		 ;AN000;
	LODSW					; AH = action,	AL = class		 ;AN000;
	CMP	AL,ERROR_INFO_NOT_SET							 ;AN000;
	JE	SEI_60									 ;AN000;
	MOV	[EXTERR_CLASS],AL		; set class				 ;AN000;
SEI_60: 										 ;AN000;
	CMP	AH,ERROR_INFO_NOT_SET							 ;AN000;
	JE	SEI_80									 ;AN000;
	MOV	[EXTERR_ACTION],AH		; set action				 ;AN000;
SEI_80: 										 ;AN000;
	LODSW					; AH = allowed, AL = locus		 ;AN000;
	CMP	AL,ERROR_INFO_NOT_SET							 ;AN000;
	JE	SEI_100 								 ;AN000;
	MOV	[EXTERR_LOCUS],AL		; Set locus				 ;AN000;
SEI_100:										 ;AN000;
	CMP	AH,ERROR_INFO_NOT_SET							 ;AN000;
	JE	SEI_1000								 ;AN000;
	MOV	[ALLOWED],AH								 ;AN000;

SEI_1000:										 ;AN003;
	RestoreReg <DS,SI,CX,AX>							 ;AN000;
	POPF										 ;AN000;
	return										 ;AN000;

EndProc SET_EXTERR_INFO 								 ;AN000;


BREAK <DEVICE2EXTERR   -- Convert device error to extended error >			       ;AN004;

;************************************************************************************
;
; DEVICE2EXTERR
;
; Inputs:
;	AX is device error
;
; Function:
;	Convert device error to extended error
;	This is essentially the same routine as in IBMDOS
;
; Outputs:
;	AX = extended error
;
; Regs: all preserved
;
;************************************************************************************

	procedure DEVICE2EXTERR,NEAR							 ;AN004;
											 ;AN004;
	SaveReg <DI>									 ;AN004;
	MOV	DI,AX									 ;AN004;
	MOV	AX,OFFSET ErrMap24End							 ;AN004;
	SUB	AX,OFFSET ErrMap24		; AX is the index of the first		 ;AN004;
						; unavailable error.			 ;AN004;
						; Do not translate if >= AX.		 ;AN004;
	CMP	DI,AX									 ;AN004;
	MOV	AX,DI									 ;AN004;
	JAE	D2E_20									 ;AN004;
	MOV	AL,ErrMap24[DI] 							 ;AN004;
	XOR	AH,AH									 ;AN004;
D2E_20: 										 ;AN004;
	RestoreReg <DI> 								 ;AN004;
	return										 ;AN004;
											 ;AN004;
EndProc DEVICE2EXTERR									 ;AN004;

BREAK <IFS_I24 -- Do an INT 24 error>							 ;AN000;
											 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; IFS_I24										 ;AN000;
;											 ;AN000;
; Called by: CALL_IFS									 ;AN000;
;											 ;AN000;
; Routines called:  DOS: NET_I24_ENTRY							 ;AN000;
;											 ;AN000;
; Inputs:										 ;AN000;
;	[IFSDRV] set (-1 = device, PHONEY_NAME set)					 ;AN000;
;	[EXTERR...] Set 								 ;AN000;
;	[ALLOWED] Set									 ;AN000;
;	IFSR										 ;AN000;
;											 ;AN000;
; Function:										 ;AN000;
;	DI = Mapped I 24 error code (0-12)						 ;AN000;
;	AH is bit info (if block)							 ;AN000;
;	Perform I 24 error to get user response 					 ;AN000;
;											 ;AN000;
; Outputs:										 ;AN000;
;	AL = 0										 ;AN000;
;	    Ignore									 ;AN000;
;	AL = 1										 ;AN000;
;	    Retry									 ;AN000;
;	AL = 3										 ;AN000;
;	    Fail									 ;AN000;
;											 ;AN000;
; Regs: DI, AX Revised 								 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
	procedure IFS_I24,NEAR								 ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING								 ;AN000;
											 ;AN000;
	XOR	AH,AH				; AL - extended error (retcode) 	 ;AD007;
	MOV	DI,AX				; set DI = i24 error code C-general fail ;AC007;
	MOV	WORD PTR [EXITHOLD+2],ES	; save es:bp here since fetchi		 ;AN000;
	MOV	WORD PTR [EXITHOLD],BP		; restores in NET_I24_ENTRY		 ;AN000;
	PUSH	CS									 ;AN000;
	POP	BP				; BP=seg part of BP:SI dev ptr		 ;AN000;
											 ;AN000;
	MOV	AL,[IFSDRV]			; set dev hdr offset			 ;AN000;
	CMP	AL,-1									 ;AN000;
	JZ	I24_20									 ;AN000;
	MOV	SI,OFFSET PHONEY_BLOCK		;     block device			 ;AN000;
	JMP	SHORT I24_40								 ;AN000;
I24_20: 										 ;AN000;
	MOV	SI,OFFSET PHONEY_DEVICE 	;     char device			 ;AN000;
	MOV	AH,87H				;     char dev, write, data area	 ;AN007;
											 ;AN000;
I24_40: 										 ;AN000;
	OR	AH,ES:[BX.IFSR_ALLOWED] 	; bit 7 = 0-disk or 1(other),...	 ;AC007;
											 ;AN000;
	CallInstall NET_I24_ENTRY,MultDOS,6,<AX>,<SI>					 ;AN000;
											 ;AN000;
	return										 ;AN000;
											 ;AN000;
EndProc IFS_I24 									 ;AN000;
											 ;AN000;
BREAK <PHONEY_DPB -- Set up a phoney DPB for sharing NET INT 24 errors> 		 ;AN000;
											 ;AN000;
;************************************************************************************	 ;AN000;
;											 ;AN000;
; PHONEY_DPB										 ;AN000;
;											 ;AN000;
; Input:										 ;AN000;
;	[IFSDRV] Set									 ;AN000;
;											 ;AN000;
; Function:										 ;AN000;
;	Build a phoney DPB for IFS Share/Lock errors					 ;AN000;
;											 ;AN000;
; Outputs:										 ;AN000;
;	[THISDPB] Set									 ;AN000;
;											 ;AN000;
; Regs: ALL preserved									 ;AN000;
;											 ;AN000;
;************************************************************************************	 ;AN000;
											 ;AN000;
	procedure PHONEY_DPB,NEAR							 ;AN000;
ASSUME	DS:DOSGROUP,ES:NOTHING								 ;AN000;
											 ;AN000;
	PUSH	AX									 ;AN000;
	MOV	WORD PTR [THISDPB],OFFSET DUMMY_DPB					 ;AN000;
	MOV	WORD PTR [THISDPB+2],CS 						 ;AN000;
	MOV	AL,[IFSDRV]								 ;AN000;
	MOV	BYTE PTR [DUMMY_DPB + dpb_drive],AL					 ;AN000;
	MOV	WORD PTR [DUMMY_DPB + dpb_driver_addr],OFFSET PHONEY_BLOCK		 ;AN000;
	MOV	WORD PTR [DUMMY_DPB + dpb_driver_addr + 2],CS				 ;AN000;
	POP	AX									 ;AN000;
	return										 ;AN000;
											 ;AN000;
EndProc PHONEY_DPB									 ;AN000;

include msgdcl.inc											 ;AN000;
											 ;AN000;
IFSSEG	ENDS										 ;AN000;
    END 										 ;AN000;
