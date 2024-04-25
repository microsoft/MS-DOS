;	SCCSID = @(#)srvcall.asm	1.4 85/08/02
TITLE SRVCALL - Server DOS call
NAME  SRVCALL
;
; Server DOS call functions
;
;
;   $ServerCall
;
;   Modification history:
;
;	Created: ARR 08 August 1983
;

.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
.cref
.list

AsmVars <Installed>

include dpl.asm

Installed = TRUE

	i_need	USER_ID,WORD
	i_need	PROC_ID,WORD
	i_need	SaveBX,WORD
	i_need	SaveDS,WORD
	i_need	SWAP_START,BYTE
	i_need	SWAP_ALWAYS,BYTE
	i_need	SWAP_END,BYTE
	I_Need	ThisSFT,DWORD
	I_need	fSharing,BYTE
	i_need	OpenBuf,128
	I_Need	ExtErr,WORD
	I_Need	ExtErr_Action,BYTE
	I_Need	ExtErrPt,DWORD
	I_Need	EXTERR_LOCUS,BYTE	; Extended Error Locus
	i_need	JShare,DWORD
	i_need	SWAP_AREA_TABLE,BYTE
	i_need	SWAP_ALWAYS_AREA,DWORD
	i_need	SWAP_ALWAYS_AREA_LEN,WORD
	i_need	SWAP_AREA_LEN,WORD

BREAK <ServerCall -- Server DOS call>

TABLE	SEGMENT
Public SRVC001S,SRVC001E
SRVC001S label byte

ServerTab	DW	DOSGroup:Server_Disp
SERVERLEAVE	DW	DOSGROUP:ServerReturn
SERVER_DISP	DB	(SERVER_DISP_END-SERVER_DISP-1)/2
		DW	OFFSET DOSGROUP:SRV_CALL	; 0
		DW	OFFSET DOSGROUP:COMMIT_ALL	; 1
		DW	OFFSET DOSGROUP:CLOSE_NAME	; 2
		DW	OFFSET DOSGROUP:CLOSE_UID	; 3
		DW	OFFSET DOSGROUP:CLOSE_UID_PID	; 4
		DW	OFFSET DOSGROUP:GET_LIST	; 5
		DW	OFFSET DOSGROUP:GET_DOS_DATA	; 6
		DW	OFFSET DOSGROUP:SPOOL_OPER	; 7
		DW	OFFSET DOSGROUP:SPOOL_OPER	; 8
		DW	OFFSET DOSGROUP:SPOOL_OPER	; 9
		DW	OFFSET DOSGroup:$setExtendedError   ; 10
SERVER_DISP_END LABEL	BYTE

SRVC001E label byte

TABLE	ENDS

; Inputs:
;	DS:DX -> DPL  (except calls 7,8,9)
; Function:
;	AL=0	Server DOS call
;	AL=1	Commit All files
;	AL=2	Close file by name (SHARING LOADED ONLY) DS:DX in DPL -> name
;	AL=3	Close all files for DPL_UID
;	AL=4	Close all files for DPL_UID/PID_PID
;	AL=5	Get open file list entry
;		    IN: BX File Index
;			CX User Index
;		    OUT:ES:DI -> Name
;			BX = UID
;		    CX = # locked blocks held by this UID
;	AL=6	Get DOS data area
;		    OUT: DS:SI -> Start
;			CX size in bytes of swap if indos
;			DX size in bytes of swap always
;	AL=7	Get truncate flag
;	AL=8	Set truncate flag
;	AL=9	Close all spool files
;	AL=10	SetExtendedError
;	AL=11	DOS4.00 Get DOS data area
;		    DS:SI -> swap table

	procedure   $ServerCall,NEAR
ASSUME	DS:NOTHING,ES:NOTHING
	CMP	AL,7
	JB	SET_STUFF
	CMP	AL,9
	JBE	NO_SET_ID		; No DPL on calls 7,8,9
	CMP	AL,11				   ;IFS.			;AN000;
	JNZ	SET_STUFF			   ;IFS.			;AN000;
	MOV	DI,OFFSET DOSGROUP:SWAP_AREA_TABLE ;IFS.			;AN000;
	PUSH	SS				   ;IFS.			;AN000;
	POP	ES				   ;IFS.			;AN000;
	invoke	GET_USER_STACK			   ;IFS.			;AN000;
	MOV	[SI.user_DS],ES 		   ;IFS.   ds:si -> swap tab	;AN000;
	MOV	[SI.user_SI],DI 		   ;IFS.			;AN000;
	transfer SYS_RET_OK			   ;IFS.			;AN000;
SET_STUFF:
	MOV	SI,DX			; Point to DPL with DS:SI
	MOV	BX,[SI.DPL_UID]
	MOV	[USER_ID],BX		; Set UID
	MOV	BX,[SI.DPL_PID]
	MOV	[PROC_ID],BX		; Set process ID
NO_SET_ID:
	PUSH	SERVERLEAVE		; push return address
	PUSH	ServerTab		; push table address
	PUSH	AX
	Invoke	TableDispatch
	MOV	EXTERR_LOCUS,errLoc_Unk ; Extended Error Locus
	error	error_invalid_function
ServerReturn:
	return

; Commit - iterate through the open file list and make sure that the
; directory entries are correctly updated.

COMMIT_ALL:
ASSUME	DS:NOTHING,ES:NOTHING
	XOR	BX,BX			;   for (i=0; ThisSFT=getSFT(i); i++)
	Context DS
	EnterCrit   critSFT		; Gonna scan SFT cache, lock it down
CommitLoop:
	SaveReg <BX>
	Invoke	SFFromSFN
	JC	CommitDone
	CMP	ES:[DI].sf_Ref_Count,0	;	if (ThisSFT->refcount != 0)
	JZ	CommitNext
	CMP	ES:[DI].sf_Ref_Count,sf_busy  ; BUSY SFTs have god knows what
	JZ	CommitNext		      ;   in them.
;	TEST	ES:[DI].sf_flags,sf_isnet
	invoke	Test_IFS_Remote 	;IFS.					;AN000;
	JNZ	CommitNext		;  Skip Network SFTs so the SERVER
					;	doesn't deadlock
	MOV	WORD PTR ThisSFT,DI
	MOV	WORD PTR ThisSFT+2,ES
	Invoke	DOS_Commit		;	    DOSCommit ();
CommitNext:
	RestoreReg  <BX>
	INC	BX
	JMP	CommitLoop
CommitDone:
	LeaveCrit   critSFT
	RestoreReg  <BX>
	transfer    Sys_Ret_OK

CLOSE_NAME:
ASSUME	DS:NOTHING,ES:NOTHING

if installed
	Call	JShare + 5 * 4
else
	Call	MFTcloN
endif
CheckReturns:
	JC	func_err
	transfer SYS_RET_OK
func_err:
	transfer SYS_RET_ERR

CLOSE_UID:
ASSUME	DS:NOTHING,ES:NOTHING

if installed
	Call	JShare + 3 * 4
else
	Call	MFTclU
endif
	JMP	CheckReturns

CLOSE_UID_PID:
ASSUME	DS:NOTHING,ES:NOTHING

if installed
	Call	JShare + 4 * 4
else
	Call	MFTCloseP
endif
	JMP	CheckReturns

GET_LIST:
ASSUME	DS:NOTHING,ES:NOTHING
if installed
	Call	JShare + 9 * 4
else
	Call	MFT_get
endif
	JC	func_err
	invoke	get_user_stack
	MOV	[SI.user_BX],BX
	MOV	[SI.user_DI],DI
	MOV	[SI.user_ES],ES
SetCXOK:
	MOV	[SI.user_CX],CX
	transfer    SYS_RET_OK

SRV_CALL:
ASSUME	DS:NOTHING,ES:NOTHING
	POP	AX			; get rid of call to $srvcall
	SaveReg <DS,SI>
	invoke	GET_USER_STACK
	RestoreReg  <DI,ES>
;
; DS:SI point to stack
; ES:DI point to DPL
;
	invoke	XCHGP
;
; DS:SI point to DPL
; ES:DI point to stack
;
; We now copy the registers from DPL to save stack
;
	SaveReg <SI>
	MOV	CX,6
	REP	MOVSW			; Put in AX,BX,CX,DX,SI,DI
	INC	DI
	INC	DI			; Skip user_BP
	MOVSW				; DS
	MOVSW				; ES
	RestoreReg  <SI>		; DS:SI -> DPL
	MOV	AX,[SI.DPL_AX]
	MOV	BX,[SI.DPL_BX]
	MOV	CX,[SI.DPL_CX]
	MOV	DX,[SI.DPL_DX]
	MOV	DI,[SI.DPL_DI]
	MOV	ES,[SI.DPL_ES]
	PUSH	[SI.DPL_SI]
	MOV	DS,[SI.DPL_DS]
	POP	SI
	MOV	[SaveDS],DS
	MOV	[SaveBX],BX
	MOV	fSharing,-1		; set no redirect flag
	transfer REDISP

GET_DOS_DATA:
ASSUME	DS:NOTHING,ES:NOTHING
	LES	DI,[SWAP_ALWAYS_AREA]	     ;IFS. get beginning addr of swap ;AC000;
	MOV	DX,[SWAP_ALWAYS_AREA_LEN]    ;IFS. get swap always area len   ;AC000;
	AND	DX,7FFFH		     ;IFS. clear high bit	      ;AC000;
	MOV	CX,[SWAP_AREA_LEN]	     ;IFS. get swap len 	      ;AC000;
	invoke	GET_USER_STACK
	MOV	[SI.user_DS],ES 	     ;	set user regs
	MOV	[SI.user_SI],DI 	     ;
	MOV	[SI.user_DX],DX 	     ;
	JMP	SetCXOK 		     ;				      ;AN000;

SPOOL_OPER:
ASSUME	DS:NOTHING,ES:NOTHING
	CallInstall NETSpoolOper,multNet,37,AX,BX
	JC	func_err2
	transfer SYS_RET_OK
func_err2:
	transfer SYS_RET_ERR

Break	<$SetExtendedError - set extended error for later retrieval>

;
; $SetExtendedError takes extended error information and loads it up for the
; next extended error call.  This is used by interrupt-level proccessors to
; mask their actions.
;
;   Inputs: DS:SI points to DPL which contains all registers
;   Outputs: none
;

$SetExtendedError:
	ASSUME	DS:NOTHING,ES:NOTHING
	MOV	AX,[SI].dpl_AX
	MOV	[EXTERR],AX
	MOV	AX,[SI].dpL_di
	MOV	WORD PTR ExtErrPt,AX
	MOV	AX,[SI].dpL_ES
	MOV	WORD PTR ExtErrPt+2,AX
	MOV	AX,[SI].dpL_BX
	MOV	WORD PTR [EXTERR_ACTION],AX
	MOV	AX,[SI].dpL_CX
	MOV	[EXTERR_LOCUS],AH
	return
EndProc $ServerCall

CODE	ENDS
    END
