;	SCCSID = @(#)mscode.asm 1.2 85/07/23
;
; MSCODE.ASM -- MSDOS code
;

.xlist
.xcref
include dossym.inc
include devsym.inc
include dosseg.asm
include ifssym.inc
include fastopen.inc
include fastxxxx.inc
.cref
.list

AsmVars <Kanji, Debug>

CODE	SEGMENT BYTE PUBLIC 'CODE'

ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

    I_need  InDos,BYTE			; TRUE => we are in dos, no interrupt
    I_need  OpenBuf,128 		; temp name buffer
    I_need  ExtErr,WORD 		; extended error code
    I_need  User_SS,WORD		; stack segment from user
    I_need  User_SP,WORD		; stack pointer from user
    I_need  DskStack,BYTE		; stack segment inside DOS
    I_need  ThisCDS,DWORD		; Currently referenced CDS pointer
    I_need  ThisDPB,DWORD		; Currently referenced DPB pointer
    I_need  Err_Table_21		; allowed return map table for errors
    I_need  FailErr,BYTE		; TRUE => system call is being failed
    I_need  ExtErr_Action,BYTE		; recommended action
    I_need  ExtErr_Class,BYTE		; error classification
    I_need  ExtErr_Locus,BYTE		; error location
    I_need  I21_Map_E_Tab,BYTE		; mapping extended error table
    I_need  User_In_AX,WORD		; initial input user AX
    I_need  FOO,WORD			; return address for dos 2f dispatch
    I_need  DTAB,WORD			; dos 2f dispatch table
    I_need  HIGH_SECTOR,WORD		; >32mb
    I_need  IFS_DRIVER_ERR,WORD 	; >32mb
    I_need  FastOpenFlg,BYTE		;
    I_need  FastSeekFlg,BYTE		;
    I_need  CURSC_DRIVE,BYTE		;

BREAK <NullDev -- Driver for null device>

procedure   SNULDEV,FAR
ASSUME DS:NOTHING,ES:NOTHING,SS:NOTHING
	OR	ES:[BX.REQSTAT],STDON	; Set done bit
entry INULDEV
	RET				; MUST NOT BE A RETURN!
EndProc SNULDEV

BREAK <AbsDRD, AbsDWRT -- INT int_disk_read, int_disk_write handlers>


TABLE	SEGMENT
Public MSC001S,MSC001E
MSC001S label byte
	IF	IBM
; Codes returned by BIOS
ERRIN:
	DB	2			; NO RESPONSE
	DB	6			; SEEK FAILURE
	DB	12			; GENERAL ERROR
	DB	4			; BAD CRC
	DB	8			; SECTOR NOT FOUND
	DB	0			; WRITE ATTEMPT ON WRITE-PROTECT DISK
ERROUT:
; DISK ERRORS RETURNED FROM INT 25 and 26
	DB	80H			; NO RESPONSE
	DB	40H			; Seek failure
	DB	2			; Address Mark not found
	DB	10H			; BAD CRC
	DB	4			; SECTOR NOT FOUND
	DB	3			; WRITE ATTEMPT TO WRITE-PROTECT DISK

NUMERR	EQU	$-ERROUT
	ENDIF
MSC001E label byte

TABLE	ENDS

;   AbsSetup - setup for abs disk functions

Procedure   AbsSetup,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	INC	INDOS
	STI
	CLD
	PUSH	DS
	Context DS
	CALL	GETBP
	JC	errdriv 		;PM. error drive			;AN000;
	MOV	ES:[BP.dpb_free_cnt],-1 ; do not trust user at all.
errdriv:
	POP	DS
ASSUME	DS:NOTHING
	retc

	MOV	[HIGH_SECTOR],0 	;>32mb	from API			;AN000;
	CALL	RW32_CONVERT		;>32mb convert 32bit format to 16bit	;AN000;
	retc

	invoke	SET_RQ_SC_PARMS 	;LB. set up SC parms			;AN000;
	PUSH	DS
	PUSH	SI
	PUSH	AX
	Context DS
	MOV	SI,OFFSET DOSGROUP:OPENBUF
	MOV	[SI],AL
	ADD	BYTE PTR [SI],"A"
	MOV	WORD PTR [SI+1],003AH	; ":",0
	MOV	AX,0300H
	CLC
	INT	int_IBM 		; Will set carry if shared
	POP	AX
	POP	SI
	POP	DS
ASSUME	DS:NOTHING
	retnc
	MOV	ExtErr,error_not_supported
	return
EndProc AbsSetup

; Interrupt 25 handler.  Performs absolute disk read.
; Inputs:	AL - 0-based drive number
;		DS:BX point to destination buffer
;		CX number of logical sectors to read
;		DX starting  logical sector number (0-based)
; Outputs:	Original flags still on stack
;		Carry set
;		    AH error from BIOS
;		    AL same as low byte of DI from INT 24

	procedure   ABSDRD,FAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:NOTHING

	CLI
	MOV	[user_SS],SS
	MOV	[user_SP],SP
	PUSH	CS
	POP	SS
ASSUME	SS:DOSGROUP
	MOV	SP,OFFSET DOSGROUP:DSKSTACK
	invoke	Save_World		      ;>32mb save all regs		;AN000;
	PUSH	ES
	CALL	AbsSetup
	JC	ILEAVE
if not ibmcopyright
; Here is a gross temporary fix to get around a serious design flaw in
;  the secondary cache.  The secondary cache does not check for media
;  changed (it should).  Hence, you can change disks, do an absolute
;  read, and get data from the previous disk.  To get around this,
;  we just won't use the secondary cache for absolute disk reads.
;                                                      -mw 8/5/88
	EnterCrit   critDisk
	MOV	[CURSC_DRIVE],-1	      ; invalidate SC			;AN000;
	LeaveCrit   critDisk
endif
	invoke	DSKREAD
TLEAVE:
	JZ	ILEAVE

	IF	IBM
; Translate the error code to ancient 1.1 codes
	PUSH	ES
	PUSH	CS
	POP	ES
	XOR	AH,AH			; Nul error code
	MOV	CX,NUMERR		; Number of possible error conditions
	MOV	DI,OFFSET DOSGROUP:ERRIN    ; Point to error conditions
	REPNE	SCASB
	JNZ	LEAVECODE		; Not found
	MOV	AH,ES:[DI+NUMERR-1]	; Get translation
LEAVECODE:
	POP	ES
	ENDIF
	MOV	[IFS_DRIVER_ERR],AX	;>32mb save error
	STC
ILEAVE:
	POP	ES
	invoke	Restore_World		     ;>32mb				;AN000;
	CLI
	DEC	INDOS
	MOV	SS,[user_SS]
ASSUME	SS:NOTHING
	MOV	SP,[user_SP]
	MOV	AX,[IFS_DRIVER_ERR]	     ;>32mb restore error		;AN000;
	STI
	RET				; This must not be a RETURN!
EndProc ABSDRD

; Interrupt 26 handler.  Performs absolute disk write.
; Inputs:	AL - 0-based drive number
;		DS:BX point to source buffer
;		CX number of logical sectors to write
;		DX starting  logical sector number (0-based)
; Outputs:	Original flags still on stack
;		Carry set
;		    AH error from BIOS
;		    AL same as low byte of DI from INT 24

	procedure   ABSDWRT,FAR
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

	CLI
	MOV	[user_SS],SS
	MOV	[user_SP],SP
	PUSH	CS
	POP	SS
ASSUME	SS:DOSGROUP
	MOV	SP,OFFSET DOSGROUP:DSKSTACK
	invoke	Save_World		      ;>32mb save all regs		;AN000;

	PUSH	ES
	CALL	AbsSetup
	JC	ILEAVE

	EnterCrit   critDisk
	MOV	[CURSC_DRIVE],-1	      ; invalidate SC			;AN000;
	CALL	Fastxxx_Purge		      ; purge fatopen			;AN000;
	LeaveCrit   critDisk

	invoke	DSKWRITE
	JMP	TLEAVE
EndProc ABSDWRT

; Inputs:
;	AL = Logical unit number (A = 0)
; Function:
;	Find Drive Parameter Block
; Outputs:
;	ES:BP points to DPB
;	[THISDPB] = ES:BP
;	Carry set if unit number bad or unit is a NET device.
;		Later case sets extended error error_I24_not_supported
; No other registers altered

Procedure GETBP,NEAR
	DOSAssume   CS,<DS>,"GetBP"
	ASSUME	ES:NOTHING

	PUSH	AX
	ADD	AL,1			; No increment; need carry flag
	JC	SkipGet
	invoke	GetThisDrv
	JNC	SkipGet 		   ;PM. good drive			;AN000;
	XOR	AH,AH			   ;DCR. ax= error code 		;AN000;
	CMP	AX,error_not_dos_disk	   ;DCR. is unknown media ?		;AN000;
	JZ	SkipGet 		   ;DCR. yes, let it go 		;AN000;
	STC				   ;DCR.				;AN000;
	MOV	ExtErr,AX		   ;PM. invalid drive or Non DOS drive	;AN000;
	MOV	[IFS_DRIVER_ERR],0201H	   ;PM. other errors/unknown unit	;AN000;
SkipGet:
	POP	AX
	retc
	LES	BP,[THISCDS]
	TEST	ES:[BP.curdir_flags],curdir_isnet   ; Clears carry
	JZ	GETBP_CDS
	LES	BP,ES:[BP.curdir_ifs_hdr]	    ;IFS. if remote file	;AN000;
	TEST	ES:[BP.ifs_attribute],IFSREMOTE     ;IFS.			;AN000;
	LES	BP,[THISCDS]
	JZ	GETBP_CDS			    ;IFS. then error		;AN000;
	MOV	ExtErr,error_not_supported
	STC
	return

GETBP_CDS:
	LES	BP,ES:[BP.curdir_devptr]

	entry	GOTDPB
	DOSAssume   CS,<DS>,"GotDPB"
; Load THISDPB from ES:BP

	MOV	WORD PTR [THISDPB],BP
	MOV	WORD PTR [THISDPB+2],ES
	return
EndProc GetBP

BREAK <SYS_RET_OK SYS_RET_ERR CAL_LK ETAB_LK set system call returns>

ASSUME	SS:DOSGROUP

;
; These are the general system call exit mechanisms.  All internal system
; calls will transfer (jump) to one of these at the end.  Their sole purpose
; is to set the user's flags and set his AX register for return.
;

procedure   SYS_RETURN,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING
entry	SYS_RET_OK
	invoke	FETCHI_CHECK		; TAG checking for FETCHI
	invoke	get_user_stack
	AND	[SI.user_F],NOT f_Carry ; turn off user's carry flag
	JMP	SHORT DO_RET		; carry is now clear

entry	SYS_RET_ERR
	XOR	AH,AH			; hack to allow for smaller error rets
	invoke	ETAB_LK 		; Make sure code is OK, EXTERR gets set
	CALL	ErrorMap
entry	From_GetSet
	invoke	get_user_stack
	OR	[SI.user_F],f_Carry	; signal carry to user
	STC				; also, signal internal error
DO_RET:
	MOV	[SI.user_AX],AX 	; Really only sets AH
	return

	entry	FCB_RET_OK
	entry	CPMFunc
	XOR	AL,AL
	return

	entry	FCB_RET_ERR
	XOR	AH,AH
	mov	exterr,AX
	CALL	ErrorMap
	MOV	AL,-1
	return

	entry	errorMap
	PUSH	SI
	MOV	SI,OFFSET DOSGROUP:ERR_TABLE_21
	CMP	[FAILERR],0		; Check for SPECIAL case.
	JZ	EXTENDED_NORMAL 	; All is OK.
	MOV	[EXTERR],error_FAIL_I24 ; Ooops, this is the REAL reason
	MOV	SI,OFFSET DOSGROUP:ERR_TABLE_21
EXTENDED_NORMAL:
	invoke	CAL_LK			; Set CLASS,ACTION,LOCUS for EXTERR
	POP	SI
	return

EndProc SYS_RETURN

; Inputs:
;	SI is OFFSET in DOSGROUP of CLASS,ACTION,LOCUS Table to use
;		(DS NEED not be DOSGROUP)
;	[EXTERR] is set with error
; Function:
;	Look up and set CLASS ACTION and LOCUS values for GetExtendedError
; Outputs:
;	[EXTERR_CLASS] set
;	[EXTERR_ACTION] set
;	[EXTERR_LOCUS] set  (EXCEPT on certain errors as determined by table)
; Destroys SI, FLAGS

	procedure   CAL_LK,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	PUSH	DS
	PUSH	AX
	PUSH	BX
	Context DS		; DS:SI -> Table
	MOV	BX,[EXTERR]	; Get error in BL
TABLK1:
	LODSB
	CMP	AL,0FFH
	JZ	GOT_VALS	; End of table
	CMP	AL,BL
	JZ	GOT_VALS	; Got entry
	ADD	SI,3		; Next table entry
	JMP	TABLK1

GOT_VALS:
	LODSW			; AL is CLASS, AH is ACTION
	CMP	AH,0FFH
	JZ	NO_SET_ACT
	MOV	[EXTERR_ACTION],AH     ; Set ACTION
NO_SET_ACT:
	CMP	AL,0FFH
	JZ	NO_SET_CLS
	MOV	[EXTERR_CLASS],AL      ; Set CLASS
NO_SET_CLS:
	LODSB			; Get LOCUS
	CMP	AL,0FFH
	JZ	NO_SET_LOC
	MOV	[EXTERR_LOCUS],AL
NO_SET_LOC:
	POP	BX
	POP	AX
	POP	DS
	return
EndProc CAL_LK

; Inputs:
;	AX is error code
;	[USER_IN_AX] has AH value of system call involved
; Function:
;	Make sure error code is appropriate to this call.
; Outputs:
;	AX MAY be mapped error code
;	[EXTERR] = Input AX
; Destroys ONLY AX and FLAGS

	procedure   ETAB_LK,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	PUSH	DS
	PUSH	SI
	PUSH	CX
	PUSH	BX
	Context DS
	MOV	[EXTERR],AX		; Set EXTERR with "real" error
	MOV	SI,OFFSET DOSGROUP:I21_MAP_E_TAB
	MOV	BH,AL			; Real code to BH
	MOV	BL,BYTE PTR [USER_IN_AX + 1]	; Sys call to BL
TABLK2:
	LODSW
	CMP	AL,0FFH 		; End of table?
	JZ	NOT_IN_TABLE		; Yes
	CMP	AL,BL			; Found call?
	JZ	GOT_CALL		; Yes
	XCHG	AH,AL			; Count to AL
	XOR	AH,AH			; Make word for add
	ADD	SI,AX			; Next table entry
	JMP	TABLK2

NOT_IN_TABLE:
	MOV	AL,BH			; Restore original code
	JMP	SHORT NO_MAP

GOT_CALL:
	MOV	CL,AH
	XOR	CH,CH			; Count of valid err codes to CX
CHECK_CODE:
	LODSB
	CMP	AL,BH			; Code OK?
	JZ	NO_MAP			; Yes
	LOOP	CHECK_CODE
NO_MAP:
	XOR	AH,AH			; AX is now valid code
	POP	BX
	POP	CX
	POP	SI
	POP	DS
	return

EndProc ETAB_LK

BREAK <DOS 2F Handler and default NET 2F handler>

IF installed

;
; SetBad sets up info for bad functions
;
Procedure   SetBad,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	MOV	AX,error_invalid_function	; ALL NET REQUESTS get inv func
	MOV	ExtErr_LOCUS,errLoc_UNK
	STC
	ret
EndProc SetBad
;
; BadCall is the initial routine for bad function calls
;
procedure   BadCall,FAR
	call	SetBad
	ret
EndProc BadCall
;
; OKCall always sets carry to off.
;
Procedure   OKCall,FAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	CLC
	ret
EndProc OKCall

; INT 2F handler works as follows:
;   PUSH    AX
;   MOV     AX,multiplex:function
;   INT     2F
;   POP     ...
; The handler itself needs to make the AX available for the various routines.

PUBLIC	Int2F
INT2F	PROC	FAR

INT2FNT:
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	STI
	CMP	AH,multNET
	JNZ	INT2FSHR
TestInstall:
	OR	AL,AL
	JZ	Leave2F
BadFunc:
	CALL	SetBad
	entry	Leave2F
	RET	2			; long return + clear flags off stack

INT2FSHR:
	CMP	AH,multSHARE		; is this a share request
	JZ	TestInstall		; yes, check for installation

INT2FNLS:
	CMP	AH,NLSFUNC		; is this a DOS 3.3 NLSFUNC request
	JZ	TestInstall		; yes check for installation

INT2FDOS:
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	CMP	AH,multDOS
	JZ	DispatchDOS
	IRET				; This assume that we are at the head
					; of the list
INT2F	ENDP

DispatchDOS:
	PUSH	FOO			; push return address
	PUSH	DTab			; push table address
	PUSH	AX			; push index
	PUSH	BP
	MOV	BP,SP
; stack looks like:
;   0	BP
;   2	DISPATCH
;   4	TABLE
;   6	RETURN
;   8	LONG-RETURN
;   c	FLAGS
;   e	AX

	MOV	AX,[BP+0Eh]		; get AX value
	POP	BP
	Invoke	TableDispatch
	JMP	BadFunc 		; return indicates invalid function

Procedure   INT2F_etcetera,NEAR
	entry	DosGetGroup
	PUSH	CS
	POP	DS
	return

	entry	DOSInstall
	MOV	AL,0FFh
	return
EndProc INT2F_etcetera

ENDIF
;Input: same as ABSDRD and ABSDWRT
;	 ES:BP -> DPB
;Functions: convert 32bit absolute RW input parms to 16bit input parms
;Output: carry set when CX=-1 and drive is less then 32mb
;	 carry clear, parms ok
;
Procedure   RW32_CONVERT,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	CMP	CX,-1			     ;>32mb  new format ?		;AN000;
	JZ	new32format		     ;>32mb  yes			;AN000;
	PUSH	AX			     ;>32mb  save ax			;AN000;
	PUSH	DX			     ;>32mb  save dx			;AN000;
	MOV	AX,ES:[BP.dpb_max_cluster]   ;>32mb  get max cluster #		;AN000;
	MOV	DL,ES:[BP.dpb_cluster_mask]  ;>32mb				;AN000;
	CMP	DL,0FEH 		     ;>32mb  removable ?		;AN000;
	JZ	letold			     ;>32mb  yes			;AN000;
	INC	DL			     ;>32mb				;AN000;
	XOR	DH,DH			     ;>32mb  dx = sector/cluster	;AN000;
	MUL	DX			     ;>32mb  dx:ax= max sector #	;AN000;
	OR	DX,DX			     ;>32mb  > 32mb ?			;AN000;
letold:
	POP	DX			     ;>32mb  retore dx			;AN000;
	POP	AX			     ;>32mb  restore ax 		;AN000;
	JZ	old_style		     ;>32mb  no 			;AN000;
	MOV	[IFS_DRIVER_ERR],0207H	     ;>32mb  error			;AN000;
	STC				     ;>32mb				;AN000;
	return				     ;>32mb				;AN000;
new32format:
	MOV	DX,WORD PTR [BX.SECTOR_RBA+2];>32mb				;AN000;
	MOV	[HIGH_SECTOR],DX	     ;>32mb				;AN000;
	MOV	DX,WORD PTR [BX.SECTOR_RBA]  ;>32mb				;AN000;
	MOV	CX,[BX.ABS_RW_COUNT]	     ;>32mb				;AN000;
	LDS	BX,[BX.BUFFER_ADDR]	     ;>32mb				;AN000;
old_style:				     ;>32mb				;AN000;
	CLC				     ;>32mb				;AN000;
	return				     ;>32mb				;AN000;
EndProc RW32_CONVERT


;Input: None
;Functions: Purge Fastopen/seek Cache Buffers
;Output: None
;
;
Procedure   Fastxxx_Purge,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSH	AX			      ; save regs.			;AN000;
	PUSH	SI								;AN000;
	PUSH	DX								;AN000;
	TEST	FastSeekflg,Fast_yes	      ; fastseek installed ?		;AN000;
	JZ	topen			      ; no				;AN000;
	MOV	AH,FastSeek_ID		      ; set fastseek id 		;AN000;
	JMP	SHORT dofast		      ; 				;AN000;
topen:
	TEST	FastOpenflg,Fast_yes	      ; fastopen installed ?		;AN000;
	JZ	nofast			      ; no				;AN000;
	MOV	AH,FastOpen_ID		      ; set fastseek installed		;AN000;
dofast:
	MOV	AL,FONC_purge		      ; purge				;AN000;
	MOV	DL,ES:[BP.dpb_drive]	      ; set up drive number		;AN000;
	invoke	Fast_Dispatch		      ; call fastopen/seek		;AN000;
nofast:
	POP	DX								;AN000;
	POP	SI			      ; restore regs			;AN000;
	POP	AX			      ; 				;AN000;

	return				      ; exit				;AN000;
EndProc Fastxxx_Purge

CODE	ENDS
