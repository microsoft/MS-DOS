;	SCCSID = @(#)ctrlc.asm	1.4 85/08/16
; Low level routines for detecting special characters on CON input,
;	the ^C exit/int code, the Hard error INT 24 code, the
;	process termination code, and the INT 0 divide overflow handler.
;
;   FATAL
;   FATAL1
;   reset_environment
;   DSKSTATCHK
;   SPOOLINT
;   STATCHK
;   CNTCHAND
;   DIVOV
;   CHARHARD
;   HardErr
;
;   Revision history:
;
;	AN000	version 4.0   Jan 1988
;	A002	PTM    -- dir >lpt3 hangs
;	A003	PTM 3957- fake version for IBMCAHE.COM

;
; get the appropriate segment definitions
;
.xlist
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
include version.inc
.cref
.list

	I_need	SFN,WORD
	I_NEED	pJFN,DWORD
	i_need	DevIOBuf,BYTE
	i_need	DidCTRLC,BYTE
	i_need	INDOS,BYTE
	i_need	DSKSTCOM,BYTE
	i_need	DSKSTCALL,BYTE
	i_need	DSKSTST,WORD
	i_need	BCON,DWORD
	i_need	DSKCHRET,BYTE
	i_need	DSKSTCNT,WORD
	i_need	IDLEINT,BYTE
	i_need	CONSWAP,BYTE
	i_need	user_SS,WORD
	i_need	user_SP,WORD
	i_need	User_In_AX,WORD
	i_need	ERRORMODE,BYTE
	i_need	ConC_spsave,WORD
	i_need	Exit_type,BYTE
	i_need	PFLAG,BYTE
	i_need	ExitHold,DWORD
	i_need	WPErr,BYTE
	i_need	ReadOp,BYTE
	i_need	CONTSTK,WORD
	i_need	Exit_Code,WORD
	i_need	CurrentPDB,WORD
	i_need	DIVMES,BYTE
	i_need	DivMesLen,WORD
	i_need	ALLOWED,BYTE
	i_need	FAILERR,BYTE
	i_need	EXTERR,WORD
	i_need	ERR_TABLE_24,BYTE
	I_need	ErrMap24,BYTE
	I_need	ErrMap24End,BYTE
	I_need	fAborting,BYTE
	I_need	AUXStack,BYTE
	I_need	SCAN_FLAG,BYTE
	I_need	EXTOPEN_ON,BYTE 	      ;AN000; DOS 4.0
	I_need	InterCon,BYTE		      ;AN000; DOS 4.0
	I_need	DOS34_FLAG,WORD 	      ;AN000; DOS 4.0
	I_need	ACT_PAGE,WORD		      ;AN000; DOS 4.0
	I_need	Special_Version,WORD	      ;AN007; DOS 4.0
if debug
	I_need	BugLev,WORD
	I_need	BugTyp,WORD
include bugtyp.asm
endif
IF	BUFFERFLAG
	extrn	restore_user_map:near
ENDIF

Break	<Checks for ^C in CON I/O>

ASSUME	DS:NOTHING,ES:NOTHING

	procedure   DSKSTATCHK,NEAR	; Check for ^C if only one level in
	CMP	BYTE PTR [INDOS],1
	retnz				; Do NOTHING
	PUSH	CX
	PUSH	ES
	PUSH	BX
	PUSH	DS
	PUSH	SI
	PUSH	CS
	POP	ES
	Context DS
	DOSAssume   CS,<DS>,"DskStatChk"
	MOV	BYTE PTR [DSKSTCOM],DEVRDND
	MOV	BYTE PTR [DSKSTCALL],DRDNDHL
	MOV	[DSKSTST],0
 IF  DBCS				;AN000;
	MOV	AL, [InterCon]		;AN000;get type of status read 2/13/KK
	MOV	BYTE PTR [DSKCHRET],AL	;AN000; load interim flag into packet
 ENDIF					;AN000;
	MOV	BX,OFFSET DOSGROUP:DSKSTCALL
	LDS	SI,[BCON]
ASSUME	DS:NOTHING
	invoke	DEVIOCALL2
	TEST	[DSKSTST],STBUI
	JZ	GotCh			; No characters available
	XOR	AL,AL			; Set zero
RET36:
	POP	SI
	POP	DS
	POP	BX
	POP	ES
	POP	CX
	return

GotCh:
	MOV	AL,BYTE PTR [DSKCHRET]
DSK1:
	CMP	AL,"C"-"@"
	JNZ	RET36
	MOV	BYTE PTR [DSKSTCOM],DEVRD
	MOV	BYTE PTR [DSKSTCALL],DRDWRHL
	MOV	BYTE PTR [DSKCHRET],CL
	MOV	[DSKSTST],0
	MOV	[DSKSTCNT],1
	invoke	DEVIOCALL2		; Eat the ^C
	POP	SI
	POP	DS
	POP	BX			; Clean stack
	POP	ES
	POP	CX
	JMP	CNTCHAND

NOSTOP:
	CMP	AL,"P"-"@"
	JNZ	check_next
	CMP	BYTE PTR [SCAN_FLAG],0	      ; ALT_Q ?
	JZ	INCHKJ			      ; no
	return
check_next:
	IF	NOT TOGLPRN
	CMP	AL,"N"-"@"
	JZ	INCHKJ
	ENDIF

	CMP	AL,"C"-"@"
	JZ	INCHKJ
check_end:
	return

INCHKJ:
	JMP	INCHK

EndProc DSKSTATCHK

;
; SpoolInt - signal processes that the DOS is truly idle.  We are allowed to
; do this ONLY if we are working on a 1-12 system call AND if we are not in
; the middle of an INT 24.
;
procedure   SPOOLINT,NEAR
	PUSHF
	test	IdleInt,-1
	jz	POPFRet
	test	ErrorMode,-1
	jnz	POPFRet
;
; Note that we are going to allow an external program to issue system calls
; at this time.  We MUST preserve IdleInt across this.
;
	PUSH	WORD PTR IdleInt
	INT	int_spooler
	POP	WORD PTR IdleInt
POPFRET:
	POPF
	return
EndProc SPOOLINT

	procedure   STATCHK,NEAR

	invoke	DSKSTATCHK		; Allows ^C to be detected under
					; input redirection
	PUSH	BX
	XOR	BX,BX
	invoke	GET_IO_SFT
	POP	BX
	retc
	MOV	AH,1
	invoke	IOFUNC
	JZ	SPOOLINT
	CMP	AL,"S"-"@"
	JNZ	NOSTOP

	CMP	BYTE PTR [SCAN_FLAG],0	      ;AN000; ALT_R ?
	JNZ	check_end		      ;AN000; yes
	XOR	AH,AH
	invoke	IOFUNC			; Eat Cntrl-S
	JMP	SHORT PAUSOSTRT
PRINTOFF:
PRINTON:
	NOT	BYTE PTR [PFLAG]
	PUSH	BX
	MOV	BX,4
	invoke	GET_IO_SFT
	POP	BX
	retc
	PUSH	ES
	PUSH	DI
	PUSH	DS
	POP	ES
	MOV	DI,SI			; ES:DI -> SFT
	TEST	ES:[DI.sf_flags],sf_net_spool
	JZ	NORM_PR 		; Not redirected, echo is OK
	Callinstall NetSpoolEchoCheck,MultNet,38,<AX>,<AX> ; See if allowed
	JNC	NORM_PR 		; Echo is OK
	MOV	BYTE PTR [PFLAG],0	; If not allowed, disable echo
	Callinstall NetSpoolClose,MultNet,36,<AX>,<AX> ; and close
	JMP	SHORT RETP6

NORM_PR:
	CMP	BYTE PTR [PFLAG],0
	JNZ	PRNOPN
	invoke	DEV_CLOSE_SFT
	JMP	SHORT RETP6

PRNOPN:
	invoke	DEV_OPEN_SFT
RETP6:
	POP	DI
	POP	ES
	return

PAUSOLP:
	CALL	SPOOLINT
PAUSOSTRT:
	MOV	AH,1
	invoke	IOFUNC
	JZ	PAUSOLP
INCHK:
	PUSH	BX
	XOR	BX,BX
	invoke	GET_IO_SFT
	POP	BX
	retc
	XOR	AH,AH
	invoke	IOFUNC
	CMP	AL,"P"-"@"
;;;;;  7/14/86	ALT_Q key fix

	JZ	PRINTON 		      ; no! must be CTRL_P

NOPRINT:
;;;;;  7/14/86	ALT_Q key fix
	IF	NOT TOGLPRN
	CMP	AL,"N"-"@"
	JZ	PRINTOFF
	ENDIF
	CMP	AL,"C"-"@"
	retnz
EndProc STATCHK

	procedure   CNTCHAND,NEAR
; Ctrl-C handler.
; "^C" and CR/LF is printed.  Then the user registers are restored and the
; user CTRL-C handler is executed.  At this point the top of the stack has 1)
; the interrupt return address should the user CTRL-C handler wish to allow
; processing to continue; 2) the original interrupt return address to the code
; that performed the function call in the first place.	If the user CTRL-C
; handler wishes to continue, it must leave all registers unchanged and RET
; (not IRET) with carry CLEAR.	If carry is SET then an terminate system call
; is simulated.
	TEST	[DOS34_FLAG],CTRL_BREAK_FLAG  ;AN002; from RAWOUT
	JNZ	around_deadlock 	      ;AN002;
	MOV	AL,3			; Display "^C"
	invoke	BUFOUT
	invoke	CRLF
around_deadlock:			      ;AN002;
	Context DS
	CMP	BYTE PTR [CONSWAP],0
	JZ	NOSWAP
	invoke	SWAPBACK
NOSWAP:
	CLI				; Prepare to play with stack
	MOV	SS,[user_SS]		; User stack now restored
ASSUME	SS:NOTHING
	MOV	SP,[user_SP]
	invoke	restore_world		; User registers now restored
ASSUME	DS:NOTHING
	MOV	BYTE PTR [INDOS],0	; Go to known state
	MOV	BYTE PTR [ERRORMODE],0
	MOV	[ConC_spsave],SP	; save his SP
	CLC
	INT	int_ctrl_c		; Execute user Ctrl-C handler
;
; The user has returned to us.	The circumstances we allow are:
;
;   IRET	We retry the operation by redispatching the system call
;   CLC/RETF	POP the stack and retry
;   ... 	Exit the current process with ^C exit
;
; User's may RETURN to us and leave interrupts on.  Turn 'em off just to be
; sure
;
	CLI
	MOV	[user_IN_AX],ax 	; save the AX
	PUSHF				; and the flags (maybe new call)
	POP	AX
;
; See if the input stack is identical to the output stack
;
	CMP	SP,[ConC_spsave]
	JNZ	ctrlc_try_new		; current SP not the same as saved SP
;
; Repeat the operation by redispatching the system call.
;
ctrlc_repeat:
	MOV	AX,User_In_AX
	transfer    COMMAND
;
; The current SP is NOT the same as the input SP.  Presume that he RETF'd
; leaving some flags on the stack and examine the input
;
ctrlc_try_new:
	ADD	SP,2			; pop those flags
	TEST	AX,f_carry		; did he return with carry?
	JZ	Ctrlc_Repeat		; no carry set, just retry
;
; Well...  time to abort the user.  Signal a ^C exit and use the EXIT system
; call..
;
ctrlc_abort:
	MOV	AX,(EXIT SHL 8) + 0
	MOV	DidCTRLC,-1
	transfer    COMMAND		; give up by faking $EXIT

EndProc CNTCHAND

Break	<DIVISION OVERFLOW INTERRUPT>

; Default handler for division overflow trap
	procedure   DIVOV,NEAR
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	MOV	SI,OFFSET DOSGROUP:DIVMES
	MOV	BX,DivMesLen
	MOV	AX,CS
	MOV	SS,AX
	MOV	SP,OFFSET DOSGROUP:AUXSTACK ; Enough stack for interrupts
	CALL	OutMes
	JMP	ctrlc_abort		; Use Ctrl-C abort on divide overflow
EndProc DIVOV

;
; OutMes: perform message output
; Inputs:   SS:SI points to message
;	    BX has message length
; Outputs:  message to BCON
;
procedure   OutMes,NEAR

	Context ES			; get ES addressability
	Context DS			; get DS addressability

	MOV	BYTE PTR [DskStCom],DevWrt
	MOV	BYTE PTR [DskStCall],DRdWrHL
	MOV	[DskSTST],0
	MOV	[DskStCnt],BX
	MOV	BX,OFFSET DOSGROUP:DskStCall
	MOV	WORD PTR [DskChRet+1],SI    ; transfer address (need an EQU)
	LDS	SI,[BCON]
ASSUME	DS:NOTHING
	invoke	DEVIOCALL2
	MOV	WORD PTR [DskChRet+1],OFFSET DOSGROUP:DevIOBuf
	MOV	[DskStCnt],1
	return
EndProc OutMes

Break	<CHARHRD,HARDERR,ERROR -- HANDLE DISK ERRORS AND RETURN TO USER>

	procedure   CHARHARD,NEAR
ASSUME	DS:NOTHING,ES:NOTHING,SS:DOSGROUP

; Character device error handler
; Same function as HARDERR

	OR	AH,allowed_FAIL + allowed_IGNORE + allowed_RETRY
	MOV	Allowed,AH
	MOV	WORD PTR [EXITHOLD+2],ES
	MOV	WORD PTR [EXITHOLD],BP
	PUSH	SI
	AND	DI,STECODE
	MOV	BP,DS			; Device pointer is BP:SI
	CALL	FATALC
	POP	SI
	return
EndProc CHARHARD

; Hard disk error handler. Entry conditions:
;	DS:BX = Original disk transfer address
;	DX = Original logical sector number
;	CX = Number of sectors to go (first one gave the error)
;	AX = Hardware error code
;	DI = Original sector transfer count
;	ES:BP = Base of drive parameters
;	[READOP] = 0 for read, 1 for write
;	[ALLOWED] Set with allowed responses to this error (other bits MUST BE 0)
; Output:
;	[FAILERR] will be set if user responded FAIL

	procedure   HardErr,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING

	XCHG	AX,DI			; Error code in DI, count in AX
	AND	DI,STECODE		; And off status bits
	CMP	DI,error_I24_write_protect ; Write Protect Error?
	JNZ	NOSETWRPERR
	PUSH	AX
	MOV	AL,ES:[BP.dpb_drive]
	MOV	BYTE PTR [WPERR],AL	; Flag drive with WP error
	POP	AX
NOSETWRPERR:
	SUB	AX,CX			; Number of sectors successfully transferred
	ADD	DX,AX			; First sector number to retry
	PUSH	DX
	MUL	ES:[BP.dpb_sector_size] ; Number of bytes transferred
	POP	DX
	ADD	BX,AX			; First address for retry
	XOR	AH,AH			; Flag disk section in error
	CMP	DX,ES:[BP.dpb_first_FAT]    ; In reserved area?
	JB	ERRINT
	INC	AH			; Flag for FAT
	CMP	DX,ES:[BP.dpb_dir_sector]   ; In FAT?
	JAE	TESTDIR 		; No
	MOV	ES:[BP.dpb_free_cnt],-1 ; Err in FAT must force recomp of freespace
	JMP	SHORT ERRINT

TESTDIR:
	INC	AH
	CMP	DX,ES:[BP.dpb_first_sector] ; In directory?
	JB	ERRINT
	INC	AH			; Must be in data area
ERRINT:
	SHL	AH,1			; Make room for read/write bit
	OR	AH,BYTE PTR [READOP]	; Set bit 0
; If we have a write protect error when writing on a critical area on disk,
; do not allow a retry as this may write out garbage on any subsequent disk.
	;test	ah,1
	;jz	Not_Crit
	;cmp	ah,5
	;ja	Not_Crit
	;and	[ALLOWED],NOT Allowed_RETRY
Not_Crit:
	OR	AH,[ALLOWED]		; Set the allowed_ bits
	entry	FATAL
	MOV	AL,ES:[BP.dpb_drive]	; Get drive number
	entry	FATAL1
	MOV	WORD PTR [EXITHOLD+2],ES
	MOV	WORD PTR [EXITHOLD],BP	; The only things we preserve
	LES	SI,ES:[BP.dpb_driver_addr]
	MOV	BP,ES			; BP:SI points to the device involved
;
; DI has the INT-24-style extended error.  We now map the error code for this
; into the normalized get extended error set by using the ErrMap24 table as an
; translate table.  Note that we translate ONLY the device returned codes and
; leave all others beyond the look up table alone.
;
FATALC:
	call	SET_I24_EXTENDED_ERROR
	CMP	DI,error_I24_gen_failure
	JBE	GOT_RIGHT_CODE		; Error codes above gen_failure get
	MOV	DI,error_I24_gen_failure ; mapped to gen_failure. Real codes
					;  Only come via GetExtendedError

	entry	NET_I24_ENTRY
; Entry point used by REDIRector on Network I 24 errors.
;
;	ASSUME	DS:NOTHING,ES:NOTHING,SS:DOSGROUP
;
; ALL I 24 regs set up. ALL Extended error info SET. ALLOWED Set.
;     EXITHOLD set for restore of ES:BP.

GOT_RIGHT_CODE:
	CMP	BYTE PTR [ERRORMODE],0	; No INT 24s if already INT 24
	JZ	NoSetFail
	MOV	AL,3
	JMP	FailRet
NoSetFail:
IF	BUFFERFLAG
	invoke	RESTORE_USER_MAP		;AN000;LB. restore user's EMS map
ENDIF
	MOV	[CONTSTK],SP
	Context ES
	fmt TypINT24,LevLog,<"INT 24: AX = $x DI = $x\n">,<AX,DI>
;
; Wango!!!  We may need to free some user state info...  In particular, we
; may have locked down a JFN for a user and he may NEVER return to us.	Thus,
; we need to free it here and then reallocate it when we come back.
;
	CMP	SFN,-1
	JZ	NoFree
	SaveReg <DS,SI>
	LDS	SI,pJFN
	MOV	BYTE PTR [SI],0FFH
	RestoreReg  <SI,DS>
NoFree:
	CLI				; Prepare to play with stack
	INC	BYTE PTR [ERRORMODE]	; Flag INT 24 in progress
	DEC	BYTE PTR [INDOS]	; INT 24 handler might not return
;; Extneded Open hooks
	TEST	[DOS34_FLAG],Force_I24_Fail   ;AN000;IFS. form IFS Call Back	      ;AN000;
	JNZ	faili24 		      ;AN000;IFS.			      ;AN000;
	TEST	[EXTOPEN_ON],EXT_OPEN_I24_OFF ;AN000;IFS.I24 error disabled	      ;AN000;
	JZ	i24yes			      ;AN000;IFS.no			      ;AN000;
faili24:				      ;AN000;
	MOV	AL,3			      ;AN000;IFS.fake fail		      ;AN000;
	JMP	passi24 		      ;AN000;IFS.exit			      ;AN000;
i24yes: 				      ;AN000;

;; Extended Open hooks
	MOV	SS,[user_SS]
ASSUME	SS:NOTHING
	MOV	SP,ES:[user_SP] 	; User stack pointer restored
	INT	int_fatal_abort 	; Fatal error interrupt vector, must preserve ES
	MOV	ES:[user_SP],SP 	; restore our stack
	MOV	ES:[user_SS],SS
	MOV	BP,ES
	MOV	SS,BP
ASSUME	SS:DOSGROUP
passi24:				;AN000;
	MOV	SP,[CONTSTK]
	INC	BYTE PTR [INDOS]	; Back in the DOS
	MOV	BYTE PTR [ERRORMODE],0	; Back from INT 24
	STI
;;	MOV	[ACT_PAGE],-1		;LB. invalidate DOS active page 	;AN000;
;;	invoke	SAVE_MAP		;LB. save user's EMS map                ;AN000;
	fmt TypINT24,LevLog,<"INT 24: User reply = $x\n">,<AX>
FAILRET:
	LES	BP,[EXITHOLD]
ASSUME	ES:NOTHING
;
; Triage the user's reply.
;
	CMP	AL,1
	JB	CheckIgnore		; 0 => ignore
	JZ	CheckRetry		; 1 => retry
	CMP	AL,3			; 3 => fail
	JNZ	DoAbort 		; 2, invalid => abort
;
; The reply was fail.  See if we are allowed to fail.
;
	TEST	[ALLOWED],allowed_FAIL	; Can we?
	JZ	DoAbort 		; No, do abort
DoFail:
	MOV	AL,3			; just in case...
	TEST	[EXTOPEN_ON],EXT_OPEN_I24_OFF ;AN000;EO. I24 error disabled
	JNZ	cleanup 		      ;AN000;EO. no
	INC	[FAILERR]		; Tell everybody
CleanUp:
	MOV	WpErr,-1
	CMP	SFN,-1
	retz
	SaveReg <DS,SI,AX>
	MOV	AX,SFN
	LDS	SI,pJFN
	MOV	[SI],AL
	RestoreReg  <AX,SI,DS>
	return
;
; The reply was IGNORE.  See if we are allowed to ignore.
;
CheckIgnore:
	TEST	[ALLOWED],allowed_IGNORE ; Can we?
	JZ	DoFail			; No, do fail
	JMP	CleanUp
;
; The reply was RETRY.	See if we are allowed to retry.
;
CheckRetry:
	TEST	[ALLOWED],allowed_RETRY ; Can we?
	JZ	DoFail			; No, do fail
	JMP	CleanUp
;
; The reply was ABORT.
;
DoAbort:
	Context DS
	CMP	BYTE PTR [CONSWAP],0
	JZ	NOSWAP2
	invoke	SWAPBACK
NOSWAP2:
;
; See if we are to truly abort.  If we are in the process of aborting, turn
; this abort into a fail.
;
	TEST	fAborting,-1
	JNZ	DoFail
;
; Set return code
;
	MOV	BYTE PTR [exit_Type],Exit_hard_error
	XOR	AL,AL
;
; we are truly aborting the process.  Go restore information from the PDB as
; necessary.
;
	Transfer    exit_inner
;
; reset_environment checks the DS value against the CurrentPDB.  If they are
; different, then an old-style return is performed.  If they are the same,
; then we release jfns and restore to parent.  We still use the PDB at DS:0 as
; the source of the terminate addresses.
;
; Some subtlety:  We are about to issue a bunch of calls that *may* generate
; INT 24s.  We *cannot* allow the user to restart the abort process; we may
; end up aborting the wrong process or turn a terminate/stay/resident into a
; normal abort and leave interrupt handlers around.  What we do is to set a
; flag that will indicate that if any abort code is seen, we just continue the
; operation.  In essence, we dis-allow the abort response.
;
; output:   none.
;
	entry	reset_environment
	ASSUME	DS:NOTHING,ES:NOTHING

	invoke	Reset_Version		;AN007;MS. reset version number
	PUSH	DS			; save PDB of process

;
; There are no critical sections in force.  Although we may enter here with
; critical sections locked down, they are no longer relevant.  We may safely
; free all allocated resources.
;
	MOV	AH,82h
	INT	int_IBM

	MOV	fAborting,-1		; signal abort in progress

	CallInstall NetResetEnvironment, multNet, 34  ;DOS 4.00 doesn't need it
					; Allow REDIR to clear some stuff
					;   On process exit.
	MOV	AL,int_Terminate
	invoke	$Get_interrupt_vector	; and who to go to

	POP	CX			; get ThisPDB
	SaveReg <ES,BX> 		; save return address

	MOV	BX,[CurrentPDB] 	; get currentPDB
	MOV	DS,BX
	MOV	AX,DS:[PDB_Parent_PID]	; get parentPDB

;
; AX = parentPDB, BX = CurrentPDB, CX = ThisPDB
; Only free handles if AX <> BX and BX = CX and [exit_code].upper is not
; Exit_keep_process
;
	CMP	AX,BX
	JZ	reset_return		; parentPDB = CurrentPDB
	CMP	BX,CX
	JNZ	reset_return		; CurrentPDB <> ThisPDB
	PUSH	AX			; save parent
	CMP	BYTE PTR [exit_type],Exit_keep_process
	JZ	reset_to_parent 	; keeping this process
;
; We are truly removing a process.  Free all allocation blocks belonging to
; this PDB
;
	invoke	arena_free_process
;
; Kill off remainder of this process.  Close file handles and signal to
; relevant network folks that this process is dead.  Remember that CurrentPDB
; is STILL the current process!
;
	invoke	DOS_ABORT

reset_to_parent:
	POP	[CurrentPDB]		; set up process as parent

reset_return:				; come here for normal return
	PUSH	CS
	POP	DS
	ASSUME	DS:DOSGROUP
	MOV	AL,-1
;
; make sure that everything is clean In this case ignore any errors, we cannot
; "FAIL" the abort, the program being aborted is dead.
;
	EnterCrit   critDisk
	invoke	FLUSHBUF
	LeaveCrit   critDisk
;
; Decrement open ref. count if we had done a virtual open earlier.
;
	invoke	CHECK_VIRT_OPEN
IF	BUFFERFLAG
	invoke	RESTORE_USER_MAP		;AN000;LB. restore user's EMS map
ENDIF
	CLI
	MOV	BYTE PTR [INDOS],0	; Go to known state
	MOV	BYTE PTR [WPERR],-1	; Forget about WP error
	MOV	fAborting,0		; let aborts occur
	POP	WORD PTR ExitHold
	POP	WORD PTR ExitHold+2
;
; Snake into multitasking... Get stack from CurrentPDB person
;
	MOV	DS,[CurrentPDB]
	ASSUME	DS:NOTHING
	MOV	SS,WORD PTR DS:[PDB_user_stack+2]
	MOV	SP,WORD PTR DS:[PDB_user_stack]

	ASSUME	SS:NOTHING
	invoke	restore_world
	ASSUME	ES:NOTHING
	MOV	User_SP,AX
	POP	AX			; suck off CS:IP of interrupt...
	POP	AX
	POP	AX
	MOV	AX,0F202h		; STI
	PUSH	AX
	PUSH	WORD PTR [EXITHOLD+2]
	PUSH	WORD PTR [EXITHOLD]
	MOV	AX,User_SP
	IRET				; Long return back to user terminate address
EndProc HardErr

;
; This routine handles extended error codes.
; Input : DI = error code from device
; Output: All EXTERR fields are set
;
Procedure SET_I24_EXTENDED_ERROR,NEAR
	PUSH	AX
	MOV	AX,OFFSET DOSGroup:ErrMap24End
	SUB	AX,OFFSET DOSGroup:ErrMap24
;
; AX is the index of the first unavailable error.  Do not translate if
; greater or equal to AX.
;
	CMP	DI,AX
	MOV	AX,DI
	JAE	NoTrans
	MOV	AL,ErrMap24[DI]
	XOR	AH,AH
NoTrans:
	MOV	[EXTERR],AX
	POP	AX
;
; Now Extended error is set correctly.	Translate it to get correct error
; locus class and recommended action.
;
	PUSH	SI
	MOV	SI,OFFSET DOSGROUP:ERR_TABLE_24
	invoke	CAL_LK			; Set other extended error fields
	POP	SI
	ret
EndProc SET_I24_EXTENDED_ERROR

CODE	ENDS
    END
