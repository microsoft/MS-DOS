;	SCCSID = @(#)lock.asm	1.1 85/04/10
TITLE	LOCK ROUTINES - Routines for file locking
NAME	LOCK

;
;   LOCK_CHECK
;   LOCK_VIOLATION
;   $LockOper
;
;   Revision history:
;     A000   version 4.00   Jan. 1988
;
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xlist
.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
include lock.inc		     ;AN000;
.cref
.list

AsmVars <IBM, Installed>

Installed = TRUE

	i_need	THISSFT,DWORD
	i_need	THISDPB,DWORD
	i_need	EXTERR,WORD
	i_need	ALLOWED,BYTE
	i_need	RetryCount,WORD
	I_need	fShare,BYTE
	I_Need	EXTERR_LOCUS,BYTE	; Extended Error Locus
	i_need	JShare,DWORD
	i_need	Lock_Buffer,DWORD	;AN000; DOS 4.00
	i_need	Temp_Var,WORD		;AN000; DOS 4.00

BREAK <$LockOper - Lock Calls>

;
;   Assembler usage:
;	    MOV     BX, Handle	       (DOS 3.3)
;	    MOV     CX, OffsetHigh
;	    MOV     DX, OffsetLow
;	    MOV     SI, LengthHigh
;	    MOV     DI, LengthLow
;	    MOV     AH, LockOper
;	    MOV     AL, Request
;	    INT     21h
;
;   Error returns:
;	    AX = error_invalid_handle
;	       = error_invalid_function
;	       = error_lock_violation
;
;   Assembler usage:
;	    MOV     AX, 5C??	       (DOS 4.00)
;
;				    0? lock all
;				    8? lock write
;				    ?2 lock multiple
;				    ?3 unlock multiple
;				    ?4 lock/read
;				    ?5 write/unlock
;				    ?6 add (lseek EOF/lock/write/unlock)
;	    MOV     BX, Handle
;	    MOV     CX, count or size
;	    LDS     DX, buffer
;	    INT     21h
;
;   Error returns:
;	    AX = error_invalid_handle
;	       = error_invalid_function
;	       = error_lock_violation

	procedure   $LockOper,NEAR
ASSUME	DS:NOTHING,ES:NOTHING
;	MOV	BP,AX			;MS. BP=AX				;AN000;
;	AND	BP,7FH			;MS. clear bit 7			;AN000;
;	CMP	BP,Lock_add		;MS. supported function ?		;AN000;
;	JA	lock_bad_func		;MS. no,				;AN000;

	CMP	AL,1			;AN000;;MS. no,
	JA	lock_bad_func		;AN000;;MS. no,

	PUSH	DI			       ; Save LengthLow
	invoke	SFFromHandle		       ; ES:DI -> SFT
	JNC	lock_do 		       ; have valid handle
	POP	DI			       ; Clean stack
	error	error_invalid_handle
lock_bad_func:
	MOV	EXTERR_LOCUS,errLoc_Unk        ; Extended Error Locus
	error	error_invalid_function

; Align_buffer call has been deleted, since it corrupts the DTA  (6/5/88) P5013

lock_do:
;	PUSH	AX			;AN000;;MS. save ax
;	PUSH	BX			;AN000;;MS. save handle
;	MOV	[Temp_Var],DX		;AN000;;MS. save DX
;	invoke	Align_Buffer		;AN000;;MS. align ds:dx and set DMAADD
;	POP	BX			;AN000;;MS. restore handle
;	POP	AX			;AN000;;MS. save ax
					;AN000;
;	CMP	BP,Unlock_all		;AN000;;MS. old function 0 or 1 ?
;	JA	chk_lock_mul		;AN000;;MS. no, new function
;	TEST	AL,80H			;AN000;;MS. 80H bit on ?
;	JZ	old_33			;AN000;;MS. no, old DOS 3.3 interface
;	MOV	CX,1			;AN000;;MS. adjust for new interface
;	ADD	BP,2			;AN000;;MS.
;	JMP	SHORT chk_lock_mul	;AN000;;MS.
old_33:
	MOV	BX,AX			;AN000;;MS. save AX
					;AN000;
;;	MOV	DX,[Temp_Var]		;AN000;;MS. retore DX  (P5013) 6/5/88

	MOV	BP, OFFSET DOSGROUP:Lock_Buffer ;AN000;;MS. get DOS LOCK buffer
	MOV	WORD PTR [BP.Lock_position],DX	;AN000;;MS. set low offset
	MOV	WORD PTR [BP.Lock_position+2],CX;AN000;;MS. set high offset
	POP	CX				;AN000;;MS. get low length
	MOV	WORD PTR [BP.Lock_length],CX	;AN000;;MS. set low length
	MOV	WORD PTR [BP.Lock_length+2],SI	;AN000;;MS. set high length
	MOV	CX,1				;AN000;;MS. one range
	PUSH	CS				;AN000;;MS.
	POP	DS				;AN000;;MS. DS:DX points to
	MOV	DX,BP				;AN000;;MS.   Lock_Buffer
	TEST	AL,Unlock_all			;AN000;;MS. function 1
	JNZ	DOS_Unlock			;AN000;;MS. yes
	JMP	DOS_Lock			;AN000;;MS. function 0
;;chk_lock_mul: 				;AN000;
;	POP	SI				;AN000;;MS. pop low length
;	TEST	ES:[DI.sf_flags],sf_isnet	;AN000;;MS. net handle?
;	JZ	LOCAL_DOS_LOCK			;AN000;;MS. no
;	invoke	OWN_SHARE			;AN000;;MS. IFS owns share ?
;	JNZ	LOCAL_DOS_LOCK			;AN000;;MS. no
;	MOV	BX,AX				;AN000;;MS. BX=AX
;	CallInstall NET_XLock,multNet,10	;AN000;;MS. issue Net Extended Lock
;	MOV	[Temp_Var],CX			;AN000;;MS. cx= retuened from IFS
;	JMP	ValChk				;AN000;;MS. check return
;LOCAL_DOS_LOCK:				;AN000;
;	CMP	BP,Lock_mul_range		;AN000;;MS. lock mul range?
;	JNZ	unmul				;AN000;;MS. lock mul range?
;	JMP	LOCAL_LOCK			;AN000;;MS. yes
;unmul:
;	CMP	BP,Unlock_mul_range		;AN000;;MS. unlock mul range?
;	JZ	LOCAL_UNLOCK			;AN000;;MS. yes
;	CMP	BP,Lock_read			;AN000;;MS. lock read?
;	JNZ	chk_write_unlock		;AN000;;MS. no
;	CALL	Set_Lock_Buffer 		;AN000;;MS. set DOS lock buffer
;	CALL	Set_Lock			;AN000;;MS. set the lock
;	JC	lockerror			;AN000;;MS. error
;	invoke	$READ				;AN000;;MS. do read
;	JC	lockerror			;AN000;;MS. error
;lockend:					;AN000;
;	transfer SYS_RET_OK			;AN000;;MS. return
;chk_write_unlock:				;AN000;
;	CMP	BP,Write_unlock 		;AN000;;MS. write unlock ?
;	JNZ	Lock_addf			;AN000;;MS. no
;	CALL	Set_Lock_Buffer 		;AN000;;MS. set DOS lock buffer
;WriteUnlock:					;AN000;
;	PUSH	AX				;AN000;;MS. save AX for unlock
;	invoke	$WRITE				;AN000;;MS. do write
;	MOV	[Temp_Var],AX			;AN000;;MS. save number of bytes writ
;	POP	AX				;AN000;;MS. restore AX
;	JC	lockerror			;AN000;;MS. error
;	MOV	CX,1				;AN000;;MS. one range unlock
;	PUSH	CS				;AN000;;MS.
;	POP	DS				;AN000;;MS. DS:DX points to
;	MOV	DX,OFFSET DOSGROUP:Lock_Buffer	;AN000;;MS.  Lock_BUffer
;	JMP	LOCAL_UNLOCK			;AN000;;MS. do unlock
;Lock_addf:					;AN000;
;	MOV	SI,WORD PTR ES:[DI.SF_Size]	 ;AN000;;MS. must be lock add
;	MOV	WORD PTR ES:[DI.SF_Position],SI  ;AN000;;MS. set file position to
;	MOV	SI,WORD PTR ES:[DI.SF_Size+2]	 ;AN000;;MS. EOF
;	MOV	WORD PTR ES:[DI.SF_Position+2],SI;AN000;;MS.
;	CALL	Set_Lock_Buffer 		 ;AN000;;MS. set DOS lock buffer
;	CALL	Set_Lock			 ;AN000;;MS. set the lock
;	JC	lockerror			 ;AN000;;MS. error
;	JMP	WriteUnlock			 ;AN000;;MS. do write unlock
						 ;AN000;;MS.
DOS_Unlock:
	TEST	ES:[DI.sf_flags],sf_isnet
	JZ	LOCAL_UNLOCK
;;	invoke	OWN_SHARE			 ;AN000;;MS. IFS owns share ?
;;	JNZ	LOCAL_UNLOCK			 ;AN000;;MS. no

	CallInstall Net_Xlock,multNet,10
	JMP	SHORT ValChk
LOCAL_UNLOCK:
if installed
	Call	JShare + 7 * 4
else
	Call	clr_block
endif
ValChk:
	JNC	Lock_OK
lockerror:
	transfer SYS_RET_ERR
Lock_OK:
	MOV	AX,[Temp_VAR]			 ;AN000;;MS. AX= number of bytes
	transfer SYS_Ret_OK
DOS_Lock:
	TEST	ES:[DI.sf_flags],sf_isnet
	JZ	LOCAL_LOCK
;;	invoke	OWN_SHARE			 ;AN000;;MS. IFS owns share ?
;;	JNZ	LOCAL_LOCK			 ;AN000;;MS. no
	CallInstall NET_XLock,multNet,10
	JMP	ValChk
LOCAL_LOCK:
if installed
	Call	JShare + 6 * 4
else
	Call	Set_Block
endif
	JMP	ValChk

EndProc $LockOper

BREAK <Set_Lock>

;   Input:
;	   BP = Lock_Buffer addr
;	   CX = lock length
;   Function:
;	   set the lock
;   Output:
;	   carry clear ,Lock is set
;			DS:DX = addr of
;	   carry set Lock is not set
;	   DS,DX,CX preserved

;	procedure   Set_Lock,NEAR						;AN000;
;ASSUME  DS:NOTHING,ES:NOTHING							 ;AN000;
										;AN000;
;	PUSH	DS			    ;MS. save regs			;AN000;
;	PUSH	DX			    ;MS.				;AN000;
;	PUSH	CX			    ;MS.				;AN000;
;										;AN000;
;	PUSH	CS			    ;MS.				;AN000;
;	POP	DS			    ;MS. DS:DX poits to Lock_Buffer	;AN000;
;	MOV	DX,BP			    ;MS.				;AN000;
;	PUSH	BX			    ;MS. save handle			;AN000;
;	PUSH	AX			    ;MS. save functions 		;AN000;
;	MOV	CX,1			    ;MS. set one lock			;AN000;
;if installed									 ;AN000;
;	Call	JShare + 6 * 4		    ;MS. call share set block		;AN000;
;else										 ;AN000;
;	Call	Set_Block		    ;MS.				;AN000;
;endif										 ;AN000;
;	POP	AX			    ;MS. restore regs			;AN000;
;	POP	BX			    ;MS.				;AN000;
;	POP	CX			    ;MS.				;AN000;
;	POP	DX			    ;MS.				;AN000;
;	POP	DS			    ;MS.				;AN000;
;	return				    ;MS.				;AN000;
;										;AN000;
;EndProc Set_Lock								 ;AN000;

BREAK <Set_Lock_Buffer>

;   Input:
;	   ES:DI = addr of SFT
;	   CX = lock length
;   Function:
;	   set up the lock buffer
;   Output:
;	   Lock_Buffer is filled with position and lock length
;	   BP = Lock_Buffer addr
;

;	procedure   Set_Lock_Buffer,NEAR
;ASSUME  DS:NOTHING,ES:NOTHING
;
;	MOV	BP, OFFSET DOSGROUP:Lock_Buffer   ;MS. move file position	;AN000;
;	MOV	SI,WORD PTR ES:[DI.sf_position]   ;MS. to DOS lock_buffer	;AN000;
;	MOV	WORD PTR [BP.Lock_position],SI	  ;MS.				;AN000;
;	MOV	SI,WORD PTR ES:[DI.sf_position+2] ;MS.				;AN000;
;	MOV	WORD PTR [BP.Lock_position+2],SI  ;MS.				;AN000;
;	MOV	WORD PTR [BP.Lock_length],CX	  ;MS. move cx to lock_buffer	;AN000;
;	MOV	WORD PTR [BP.Lock_length+2],0	  ;MS.				;AN000;
;	return					  ;MS.				;AN000;
;
;EndProc Set_Lock_Buffer

; Inputs:
;	Outputs of SETUP
;	[USER_ID] Set
;	[PROC_ID] Set
; Function:
;	Check for lock violations on local I/O
;	Retries are attempted with sleeps in between
; Outputs:
;    Carry clear
;	Operation is OK
;    Carry set
;	A lock violation detected
; Outputs of SETUP preserved

	procedure   LOCK_CHECK,NEAR
	DOSAssume   CS,<DS>,"Lock_Check"
	ASSUME	ES:NOTHING

	MOV	BX,RetryCount		; Number retries
LockRetry:
	SaveReg <BX,AX> 		; MS. save regs 			;AN000;
if installed
	call	JShare + 8 * 4
else
	Call	chk_block
endif
	RestoreReg  <AX,BX>		; MS. restrore regs			;AN000;
	retnc				; There are no locks
	Invoke	Idle			; wait a while
	DEC	BX			; remember a retry
	JNZ	LockRetry		; more retries left...
	STC
	return
EndProc LOCK_CHECK

; Inputs:
;	[THISDPB] set
;	[READOP] indicates whether error on read or write
; Function:
;	Handle Lock violation on compatibility (FCB) mode SFTs
; Outputs:
;	Carry set if user says FAIL, causes error_lock_violation
;	Carry clear if user wants a retry
;
; DS, ES, DI, CX preserved, others destroyed

	procedure   LOCK_VIOLATION,NEAR
	DOSAssume   CS,<DS>,"Lock_Violation"
	ASSUME	ES:NOTHING

	PUSH	DS
	PUSH	ES
	PUSH	DI
	PUSH	CX
	MOV	AX,error_lock_violation
	MOV	[ALLOWED],allowed_FAIL + allowed_RETRY
	LES	BP,[THISDPB]
	MOV	DI,1				; Fake some registers
	MOV	CX,DI
	MOV	DX,ES:[BP.dpb_first_sector]
	invoke	HARDERR
	POP	CX
	POP	DI
	POP	ES
	POP	DS
	CMP	AL,1
	retz			; 1 = retry, carry clear
	STC
	return

EndProc LOCK_VIOLATION

IF  INSTALLED
;
; do a retz to return error
;
Procedure   CheckShare,NEAR
	ASSUME	CS:DOSGROUP,ES:NOTHING,DS:NOTHING,SS:NOTHING
	CMP	fShare,0
	return
EndProc CheckShare
ENDIF

CODE	ENDS
    END
