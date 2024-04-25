;	SCCSID = @(#)abort.asm	1.4 85/10/02
TITLE   DOS_ABORT - Internal SFT close all files for proc call for MSDOS
NAME    DOS_ABORT

; Internal Abort call closes all handles and FCBs associated with a process.
;  If process has NET resources a close all is sent out over the net.
;
;   DOS_ABORT
;
;   Modification history:
;
;       Created: ARR 30 March 1983
;

;
; get the appropriate segment definitions
;

include dosseg.asm

CODE    SEGMENT BYTE PUBLIC  'CODE'
	ASSUME  SS:DOSGROUP,CS:DOSGROUP

.xlist
.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
.cref
.list

Installed = TRUE

	I_Need  PROC_ID,WORD            ; current process ID
	I_Need  USER_ID,WORD            ; current user ID
	i_need  CurrentPDB,WORD
	i_need  sft_addr,DWORD
	i_need  THISSFT,DWORD
	i_need  JSHARE,DWORD
	I_need  sftFCB,DWORD            ; pointer to SFTs for FCB cache

Break   <DOS_ABORT -- CLOSE all files for process>

; Inputs:
;       [CurrentPDB] set to PID of process aborting
; Function:
;       Close all files and free all SFTs for this PID
; Returns:
;       None
; All destroyed except stack

	Procedure   DOS_ABORT,NEAR
	ASSUME  DS:NOTHING,ES:NOTHING

	MOV     ES,[CurrentPDB]
	MOV     CX,ES:[PDB_JFN_Length]  ; Number of JFNs
reset_free_jfn:
	MOV     BX,CX
	PUSH    CX
	DEC     BX                      ; get jfn (start with last one)

	invoke  $close
	POP     CX
	LOOP    reset_free_jfn          ; and do 'em all
;
; Note:  We do need to explicitly close FCBs.  Reasons are as follows:  If we
; are running in the no-sharing no-network environment, we are simulating the
; 2.0 world and thus if the user doesn't close the file, that is his problem
; BUT...  the cache remains in a state with garbage that may be reused by the
; next process.  We scan the set and blast the ref counts of the FCBs we own.
;
; If sharing is loaded, then the following call to close process will
; correctly close all FCBs.  We will then need to walk the list AFTER here.
;
; Finally, the following call to NET_Abort will cause an EOP to be sent to all
; known network resources.  These resources are then responsible for cleaning
; up after this process.
;
; Sleazy, eh?
;
	context DS
	CallInstall Net_Abort, multNet, 29
if installed
	call    JShare + 4 * 4
else
	call    mftCloseP
endif
	assume  ds:nothing
;
; Scan the FCB cache for guys that belong to this process and zap their ref
; counts.
;
	les     di,sftFCB               ; grab the pointer to the table
	mov     cx,es:[di].sfCount
	jcxz    FCBScanDone
	LEA     DI,[DI].sfTable         ; point at table
	mov     ax,proc_id
FCBTest:
	cmp     es:[di].sf_PID,ax       ; is this one of ours
	jnz     FCBNext                 ; no, skip it
	mov     es:[di].sf_ref_count,0  ; yes, blast ref count
FCBNext:
	add     di,size sf_Entry
	loop    FCBTest
FCBScanDone:

;
; Walk the SFT to eliminate all busy SFT's for this process.
;
	XOR     BX,BX
Scan:
	push    bx
	invoke  SFFromSFN
	pop     bx
	retc
	cmp     es:[di].sf_ref_count,0
	jz      next
;
; we have a SFT that is not free.  See if it is for the current process
;
	mov     ax,proc_id
	cmp     es:[di].sf_pid,ax
	jnz     next
	mov     ax,user_id
	cmp     es:[di].sf_uid,ax
	jnz     next
;
; This SFT is labelled as ours.
;
	mov     es:[di].sf_ref_count,0
next:
	inc     bx
	jmp     scan

EndProc DOS_Abort

CODE    ENDS
    END
