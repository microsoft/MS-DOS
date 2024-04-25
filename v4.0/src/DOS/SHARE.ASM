;	SCCSID = @(#)share.asm	1.1 85/04/10
TITLE   SHARING ROUTINES - Routines for file Sharing
NAME    SHARE

include dosseg.asm

CODE    SEGMENT BYTE PUBLIC  'CODE'
	ASSUME  SS:DOSGROUP,CS:DOSGROUP

.xlist
.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
.cref
.list

AsmVars <IBM, Installed>

Installed = True

	i_need  THISDPB,DWORD
	i_need  EXTERR,WORD
	i_need  ReadOp,BYTE
	i_need  ThisSFT,DWORD
	i_need  ALLOWED,BYTE
	I_need  RetryCount,WORD
	i_need  JShare,DWORD

; Inputs:
;       [THISSFT] Points to filled in local file/device SFT for new
;               instance of file sf_mode ALWAYS has mode (even on FCB SFTs)
;       [WFP_START] has full path of name
;       [USER_ID] Set
;       [PROC_ID] Set
; Function:
;       Check for sharing violations on local file/device access
; Outputs:
;    Carry clear
;       Sharing approved
;    Carry set
;       A sharing violation detected
;           AX is error code
; USES    ALL but DS

	procedure   SHARE_CHECK,NEAR
	DOSAssume   CS,<DS>,"Share_Check"
	ASSUME  ES:NOTHING

if installed
	call    JShare + 1 * 4
else
	Call    MFT_Enter
endif
	return

EndProc SHARE_CHECK

; Inputs:
;       [THISDPB] Set
;       AX has error code
; Function:
;       Handle Sharing errors
; Outputs:
;       Carry set if user says FAIL, causes error_sharing_violation
;       Carry clear if user wants a retry
;
; DS, ES, DI preserved, others destroyed

	procedure   SHARE_VIOLATION,NEAR
	DOSAssume   CS,<DS>,"Share_Violation"
	ASSUME  ES:NOTHING

	PUSH    DS
	PUSH    ES
	PUSH    DI
	MOV     [READOP],0                      ; All share errors are reading
	MOV     [ALLOWED],allowed_FAIL + allowed_RETRY
	LES     BP,[THISDPB]
	MOV     DI,1                            ; Fake some registers
	MOV     CX,DI
	MOV     DX,ES:[BP.dpb_dir_sector]
	invoke  HARDERR
	POP     DI
	POP     ES
	POP     DS
	CMP     AL,1
	retz                    ; 1 = retry, carry clear
	STC
	return

EndProc SHARE_VIOLATION

;   ShareEnd - terminate sharing info on a particular SFT/UID/PID.  This does
;       NOT perform a close, it merely asserts that the sharing information
;       for the SFT/UID/PID may be safely released.
;
;   Inputs:     ES:DI points to an SFT
;   Outputs:    None
;   Registers modified: all except DS,ES,DI

	procedure   ShareEnd,Near
	DOSAssume   CS,<DS>,"ShareEnd"
	ASSUME  ES:NOTHING

if installed
	Call    JShare + 2 * 4
else
	Call    MFTClose
endif
	return

EndProc ShareEnd

break <ShareEnter - attempt to enter a node into the sharing set>

;
;   ShareEnter - perform a retried entry of a nodde into the sharing set.  If
;   the max number of retries is exceeded, we notify the user via int 24.
;
;   Inputs:     ThisSFT points to the SFT
;               WFP_Start points to the WFP
;   Outputs:    Carry clear => successful entry
;               Carry set => failed system call
;   Registers modified: all

Procedure   ShareEnter,NEAR
	DOSAssume   CS,<DS>,"ShareEnter"
	assume  es:nothing

	SaveReg <CX>
retry:
	mov     cx,RetryCount
attempt:
	les     di,ThisSFT              ; grab sft
	XOR     AX,AX
	MOV     ES:[DI.sf_MFT],AX       ; indicate free SFT
	SaveReg <CX>
	call    Share_Check             ; attempt to enter into the sharing set
	RestoreReg  <CX>
	jnc     done                    ; success, let the user see this
	invoke  Idle                    ; wait a while
	loop    attempt                 ; go back for another attempt
	call    Share_violation         ; signal the problem to the user
	jnc     retry                   ; user said to retry, go do it
done:
	RestoreReg  <CX>
	return
EndProc ShareEnter

CODE    ENDS
    END
