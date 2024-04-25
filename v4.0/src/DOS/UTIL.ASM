;	SCCSID = @(#)util.asm	1.1 85/04/10
TITLE   UTIL - Handle utilities
NAME    UTIL
;
; Handle related utilities for MSDOS 2.X.
;
;   pJFNFromHandle  written
;   SFFromHandle    written
;   SFFromSFN       written
;   JFNFree         written
;   SFNFree         written
;
;   Modification history:
;
;       Created: MZ 1 April 1983
;

.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

CODE    SEGMENT BYTE PUBLIC  'CODE'
	ASSUME  SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
.cref
.list
.sall

	I_need  CurrentPDB,WORD         ; current process data block location
	I_need  SFT_Addr,DWORD          ; pointer to beginning of table
	I_Need  PROC_ID,WORD            ; current process ID
	I_Need  USER_ID,WORD            ; current user ID
if debug
	I_need  BugLev,WORD
	I_need  BugTyp,WORD
include bugtyp.asm
endif

BREAK   <pJFNFromHandle - return pointer to JFN table entry>

;
;   pJFNFromHandle - Given a handle, return the pointer to the JFN location
;       in the user's data space
;   Inputs:     BX - Handle
;   Outputs:    Carry Set
;                   AX has error code
;               Carry reset
;                   ES:DI point to the handle spot
;   Registers modified:
;               If no error, ES:DI, else AX,ES
; NOTE:
;   This routine is called from $CREATE_PROCESS_DATA_BLOCK which is called
;       at DOSINIT time with SS NOT DOSGROUP
procedure   pJFNFromHandle,NEAR
	ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	MOV     ES,[CurrentPDB]         ; get user process data block
	CMP     BX,ES:[PDB_JFN_Length]  ; is handle greater than allocated
	JB      JFNAdd                  ; no, get offset
	fmt     TypAccess,LevSFN,<"$p: Illegal JFN %x\n">,<BX>
	MOV     AL,error_invalid_handle ; appropriate error
ReturnCarry:
	STC                             ; signal error
	return                          ; go back
JFNAdd: LES     DI,ES:[PDB_JFN_Pointer] ; get pointer to beginning of table
	ADD     DI,BX                   ; add in offset
ReturnNoCarry:
	CLC                             ; no holes
	return                          ; bye!
EndProc pJFNFromHandle

BREAK <SFFromHandle - return pointer (or error) to SF entry from handle>

;
; SFFromHandle - Given a handle, get JFN and then index into SF table
;
;   Input:      BX has handle
;   Output:     Carry Set
;                   AX has error code
;               Carry Reset
;                   ES:DI has pointer to SF entry
;   Registers modified: If error, AX,ES, else ES:DI
; NOTE:
;   This routine is called from $CREATE_PROCESS_DATA_BLOCK which is called
;       at DOSINIT time with SS NOT DOSGROUP
procedure   SFFromHandle,NEAR
	ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	CALL    pJFNFromHandle          ; get jfn pointer
	retc                            ; return if error
	CMP     BYTE PTR ES:[DI],-1     ; unused handle
	JNZ     GetSF                   ; nope, suck out SF
	fmt     TypAccess,LevSFN,<"$p: Illegal SFN $x:$x\n">,<ES,DI>
	MOV     AL,error_invalid_handle ; appropriate error
	jump    ReturnCarry             ; signal it
GetSF:
	SaveReg <BX>                    ; save handle
	MOV     BL,BYTE PTR ES:[DI]     ; get SFN
	XOR     BH,BH                   ; ignore upper half
	CALL    SFFromSFN               ; get real sf spot
	RestoreReg  <BX>                ; restore
	return                          ; say goodbye
EndProc SFFromHandle

BREAK <SFFromSFN - index into SF table for SFN>

;
; SFFromSFN - index into SF tables for SFN.
;
;   Input:      BX has SF index
;   Output:     ES:DI points to SF entry
;   Registers modified: ES:DI, BX only
; NOTE:
;   This routine is called from SFFromHandle which is called
;       at DOSINIT time with SS NOT DOSGROUP
procedure   SFFromSFN,NEAR
	ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	LES     DI,[SFT_Addr]           ; get pointer to beginning of table
ScanLoop:
	CMP     BX,ES:[DI].SFCount      ; is handle in this table?
	JB      GetOffset               ; yes, go grab it
	SUB     BX,ES:[DI].SFCount
	LES     DI,ES:[DI].SFLink       ; get next table segment
	CMP     DI,-1                   ; end of tables?
	JNZ     ScanLoop                ; no, try again
	STC                             ; error...
	JMP     SHORT Restore           ; go restore
GetOffset:
	SaveReg <AX>                    ; save AX
	MOV     AX,SIZE SF_Entry        ; put it in a nice place
	MUL     BL                      ; times size
	ADD     DI,AX                   ; offset by size
	RestoreReg  <AX>                ; get world back
	ADD     DI,SFTable              ; offset into structure
	CLC                             ; no holes
Restore:
	return                          ; bye!
EndProc SFFromSFN

BREAK <JFNFree - return a jfn pointer if one is free>

;
; JFNFree - scan through the JFN table and return a pointer to a free slot
;
;   Input:  None.
;   Output: Carry Set
;               AX has error code, BX,ES,DI garbage
;           Carry Reset
;               BX has new handle, ES:DI is pointer to JFN slot
;   Registers modified: As above only.
procedure   JFNFree,NEAR
	ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	XOR     BX,BX                   ; try starting low
JFNScan:
	CALL    pJFNFromHandle          ; get the appropriate handle
	JC      JFNNone                 ; no more handles
	CMP     BYTE PTR ES:[DI],-1     ; free?
	JZ      JFNFound                ; yes, carry is clear
	INC     BX                      ; no, next handle
	JMP     JFNScan                 ; and try again
JFNNone:
	MOV     AL,error_too_many_open_files
JFNFound:
	return                          ; bye
EndProc JFNFree

BREAK <SFNFree - find a free SFN>

;
;   SFNFree - scan through the sf table looking for free entries
;   Inputs:     none
;   Outputs:    Carry Set - AX has error code, BX destroyed
;               Carry Clear - BX has SFN
;                   ES:DI - pointer to SFT
;                   SFT_ref_count is set to 1
;   Registers modified: none

Procedure SFNFree,NEAR
	ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	XOR     BX,BX                   ; start at beginning
SFNFreeLoop:
	SaveReg <BX>                    ; Next call zaps BX
	CALL    SFFromSFN               ; get the potential handle
	RestoreReg  <BX>
	JNC     SFNCheck                ; no carry, check to see if its free
	MOV     AL,error_too_many_open_files    ; appropriate error
	JMP     SFNDone
SFNCheck:
	CMP     ES:[DI.sf_Ref_Count],0  ; free?
IF NOT DEBUG
	JZ      SFNGot                  ; yep, got return him
ELSE
	JNZ     NoGot
	JMP     SFNGot
NoGot:
ENDIF
	CMP     ES:[DI.sf_ref_count],sf_busy
	JNZ     SFNNext                 ; not marked busy...
	fmt     TypAccess,LevSFN,<"$p: SFT $x:$x($x)is busy, owner $x:$x\n">,<ES,DI,BX,ES:[DI].sf_UID,ES:[DI].sf_pid>
	SaveReg <BX>
	MOV     BX,User_ID
	CMP     ES:[DI.sf_UID],BX
	JNZ     SFNNextP
	MOV     BX,Proc_ID
	CMP     ES:[DI.sf_PID],BX
	JZ      SFNGotP
SFNNextP:
	fmt     TypAccess,LevSFN,<"$p: SFT unusable\n">
	RestoreReg  <BX>
SFNNext:
	INC     BX                      ; no, try next sf number
	JMP     SFNFreeLoop             ; and go until it fails
SFNGot:
	SaveReg <BX>
SFNGotP:
	CLC                             ; no error
	fmt     TypAccess,LevSFN,<"$p: SFT $x:$x($x) marked busy\n">,<ES,DI,BX>
	MOV     ES:[DI.sf_ref_count],sf_busy    ; make sure that this is allocated
	MOV     BX,User_ID
	MOV     ES:[DI.sf_UID],BX
	MOV     BX,Proc_ID
	MOV     ES:[DI.sf_PID],BX
	RestoreReg  <BX>
SFNDone:
	return                          ; bye
EndProc SFNFree

CODE    ENDS
END
