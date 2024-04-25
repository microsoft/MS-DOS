;	SCCSID = @(#)path.asm	1.1 85/04/10
TITLE	PATH - Directory related system calls
NAME	PATH

;
; Directory related system calls.  These will be passed direct text of the
; pathname from the user.  They will need to be passed through the macro
; expander prior to being sent through the low-level stuff.  I/O specs are
; defined in DISPATCH.	The system calls are:
;
;   $CURRENT_DIR  Written
;   $RMDIR	  Written
;   $CHDIR	  Written
;   $MKDIR	  Written
;
;
;   Modification history:
;
;	Created: ARR 4 April 1983
;		 MZ 10 May 1983     CurrentDir implemented
;		 MZ 11 May 1983     RmDir, ChDir, MkDir implemented
;		 EE 19 Oct 1983     RmDir no longer allows you to delete a
;				    current directory.
;		 MZ 19 Jan 1983     Brain damaged applications rely on success
;				    values of AL.
.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGroup,CS:DOSGroup

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
.cref
.list

	EXTRN	DOS_MkDir:NEAR,DOS_RmDir:NEAR

	I_Need	ThisCDS,DWORD		; pointer to Current CDS
	I_Need	WFP_Start,WORD		; pointer to beginning of directory text
	I_Need	Curr_Dir_End,WORD	; offset to end of directory part
	I_Need	OpenBuf,128		; temp spot for translated name
	I_need	fSplice,BYTE		; TRUE => do splice
	I_Need	NoSetDir,BYTE		; TRUE => no exact match on splice
	I_Need	cMeta,BYTE
	I_Need	DrvErr,BYTE							;AN000;

BREAK <$CURRENT_DIR - dump the current directory into user space>
;
;   Assembler usage:
;		LDS	SI,area
;		MOV	DL,drive
;		INT	21h
;	    ; DS:SI is a pointer to 64 byte area that contains drive
;	    ; current directory.
;   Error returns:
;	    AX = error_invalid_drive
;

	procedure $CURRENT_DIR,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:NOTHING
	EnterCrit   critDisk
	MOV	AL,DL			; get drive number (0=def, 1=A)
	Invoke	GetVisDrv		; grab it
	JNC	CurrentValidate 	; no error -> go and validate dir
CurdirErr:
	LeaveCrit   critDisk
	MOV	AL,[DrvErr]		;IFS.					;AN000;
	transfer SYS_RET_ERR		;IFS. make noise			;AN000;
CurrentValidate:
	SaveReg <DS,SI> 		; save destination
	LDS	SI,ThisCDS
	TEST	[SI].curdir_flags,curdir_isnet
	JNZ	DoCheck
; Random optimization nuked due to some utilities using GetCurrentDir to do
; media check.
;	CMP	[SI].curdir_id,0
;	JZ	GetDst
DoCheck:
	MOV	NoSetDir,0		; interested only in contents
	MOV	DI,OFFSET DOSGroup:OpenBuf
	Invoke	ValidateCDS		; output is ES:DI -> CDS
	SaveReg <ES,DI> 		; swap source and destination
	RestoreReg  <SI,DS>
GetDst:
	RestoreReg  <DI,ES>		; get real destination
	JC	CurdirErr
	ADD	SI,curdir_text
	ADD	SI,[SI.curdir_END]
	CMP	BYTE PTR [SI],'\'       ; root or subdirs present?
	JNZ	CurrentCopy
	INC	SI
CurrentCopy:
;	Invoke	FStrCpy
;; 10/29/86 E5 char
	PUSH	AX
	LODSB			      ; get char
	OR	AL,AL
	JZ	FOK
	CMP	AL,05
	JZ	FCHANGE
	JMP	FFF
FCPYNEXT:
	LODSB			      ; get char
FFF:
	CMP	AL,'\'                ; beginning of directory
	JNZ	FOK		      ; no
	STOSB			      ; put into user's buffer
	LODSB			      ; 1st char of dir is 05?
	CMP	AL,05H
	JNZ	FOK		      ; no
FCHANGE:
	MOV	AL,0E5H 	      ; make it E5
FOK:
	STOSB			      ; put into user's buffer
	OR	AL,AL		      ; final char
	JNZ	FCPYNEXT	      ; no
	POP	AX

;; 10/29/86 E5 char
	xor	AL,AL			; MZ 19 Jan 84
	LeaveCrit   critDisk
	transfer    Sys_Ret_OK		; no more, bye!
EndProc $Current_Dir

BREAK <$RmDir -- Remove a directory>

; Inputs:
;	DS:DX Points to asciz name
; Function:
;	Delete directory if empty
; Returns:
;	STD XENIX Return
;	AX = error_path_not_found If path bad
;	AX = error_access_denied If
;		Directory not empty
;		Path not directory
;		Root directory specified
;		Directory malformed (. and .. not first two entries)
;		User tries to delete a current directory
;	AX = error_current_directory

	procedure $RMDIR,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup

	push	dx			; Save ptr to name
	push	ds
	mov	si,dx			; Load ptr into si
	mov	di,offset DOSGroup:OpenBuf	; di = ptr to buf for trans name
	push	di
	Invoke	TransPathNoSet		; Translate the name
	pop	di			; di = ptr to buf for trans name
	jnc	rmlset			; If transpath succeeded, continue
	pop	ds
	pop	dx			; Restore the	 name
	error	error_path_not_found	; Otherwise, return an error

rmlset:
	CMP	cMeta,-1		;   if (cMeta >= 0)
	Jnz	rmerr			;	return (-1);
	Context ES
	xor	al,al			; al = 0 , ie drive a:
rmloop: Invoke	GetCDSFromDrv		; Get curdir for drive in al
	jc	rmcont			; If error, exit loop & cont normally
	Invoke	StrCmp			; Are the 2 paths the same?
	jz	rmerr			; Yes, report error.
	inc	al			; No, inc al to next drive number
	jmp	rmloop			; Go check next drive.

rmerr:
	pop	ds
	pop	dx			; Restore the	 name
	error	error_current_directory ;  error

rmcont:
	pop	ds
	pop	dx			; Restore the	 name
	MOV	SI,OFFSET DOSGroup:DOS_RmDIR
	JMP	DoDirCall
EndProc $RMDIR

BREAK <$ChDir -- Change current directory on a drive>

;
; $ChDir - Top-level change directory system call.  This call is responsible
; for setting up the CDS for the specified drive appropriately.  There are
; several cases to consider:
;
;   o	Local, simple CDS.  In this case, we take the input path and convert
;	it into a WFP.	We verify the existance of this directory and then
;	copy the WFP into the CDS and set up the ID field to point to the
;	directory cluster.
;   o	Net CDS.  We form the path from the root (including network prefix)
;	and verify its existance (via DOS_Chdir).  If successful, we copy the
;	WFP back into the CDS.
;   o	SUBST'ed CDS.  This is no different than the local, simple CDS.
;   o	JOIN'ed CDS.  This is trouble as there are two CDS's at work.  If we
;	call TransPath, we will get the PHYSICAL CDS that the path refers to
;	and the PHYSICAL WFP that the input path refers to.  This is perfectly
;	good for the validation but not for currency.  We call TransPathNoSet
;	to process the path but to return the logical CDS and the logical
;	path.  We then copy the logical path into the logical CDS.
;
; Inputs:
;	DS:DX Points to asciz name
; Returns:
;	STD XENIX Return
;	AX = chdir_path_not_found if error

	procedure $CHDIR,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	DI,OFFSET DOSGroup:OpenBuf  ; spot for translated name
	MOV	SI,DX			; get source
	Invoke	TransPath		; go munge the path and get real CDS
	JNC	ChDirCrack		; no errors, try path
ChDirErrP:
	MOV	AL,error_path_not_found
ChdirErr:
	transfer    SYS_Ret_Err 	; oops!

ChDirCrack:
	Assume	DS:DOSGroup
	CMP	cMeta,-1		; No meta chars allowed.
	JNZ	ChDirErrP
;
; We cannot do a ChDir (yet) on a raw CDS.  This is treated as a path not
; found.
;
	LES	DI,ThisCDS
	CMP	DI,-1			;   if (ThisCDS == NULL)
	JZ	ChDirErrP		;	error ();
 ;
 ; Find out if the directory exists.
 ;
	Invoke	DOS_ChDir
	JC	ChDirErr
;
; Get back CDS to see if a join as seen.  Set the currency pointer (only if
; not network).  If one was seen, all we need to do is copy in the text
;
	LES	DI,ThisCDS
	TEST	ES:[DI].curdir_flags,curdir_splice
	JZ	GotCDS
;
; The CDS was joined.  Let's go back and grab the logical CDS.
;
	SaveReg <ES,DI,CX>		; save CDS and cluster...
	Invoke	Get_User_Stack		; get original text
	ASSUME	DS:NOTHING
	MOV	DI,[SI.User_DX]
	MOV	DS,[SI.User_DS]
	MOV	SI,OFFSET DOSGroup:OpenBuf  ; spot for translated name
	XCHG	SI,DI
	XOR	AL,AL			; do no splicing
	SaveReg <DI>
	Invoke	TransPathNoSet		; Munge path
	RestoreReg  <SI>
	Assume	DS:DOSGroup
;
; There should NEVER be an error here.
;
IF FALSE
	JNC SKipErr
	fmt <>,<>,<"$p: Internal CHDIR error\n">
SkipErr:
ENDIF
	LES	DI,ThisCDS		; get new CDS
	MOV	ES:[DI].curdir_ID,-1	; no valid cluster here...
	RestoreReg  <CX,DI,ES>
;
; ES:DI point to the physical CDS, CX is the ID (local only)
;
GotCDS:
;
; wfp_start points to the text.  See if it is long enough
;
	CALL	Check_PathLen		;PTM.					;AN000;
	JA	ChDirErrP
	TEST	ES:[DI].curdir_flags,curdir_isnet
	JNZ	SkipRecency
	TEST	ES:[DI].curdir_flags,curdir_splice   ;PTM. for Join and Subst	;AN000;
	JZ	setdirclus			     ;PTM.			;AN000;
	MOV	CX,-1				     ;PTM.			;AN000;
setdirclus:
	MOV	ES:[DI].curdir_id,CX
	LES	DI,ThisCDS		; get logical CDS
SkipRecency:
	invoke	FStrCpy
	XOR	AL,AL
	transfer    Sys_Ret_OK
EndProc $CHDIR

BREAK <$MkDir - Make a directory entry>
; Inputs:
;	DS:DX Points to asciz name
; Function:
;	Make a new directory
; Returns:
;	STD XENIX Return
;	AX = mkdir_path_not_found if path bad
;	AX = mkdir_access_denied  If
;		Directory cannot be created
;		Node already exists
;		Device name given
;		Disk or directory(root) full

	procedure $MKDIR,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	SI,OFFSET DOSGroup:DOS_MkDir
DoDirCall:
	MOV	DI,OFFSET DOSGroup:OpenBuf  ; spot for translated name
	SaveReg <SI>
	MOV	SI,DX			; get source
	Invoke	TransPath		; go munge the path
	RestoreReg  <SI>
	JNC	MkDirCrack		; no errors, try path
MkErrP:
	MOV	AL,error_Path_Not_Found    ; oops!
MkErr:
	transfer    Sys_Ret_Err
MkDirCrack:
	CMP	cMeta,-1
	JNZ	MkErrP

	PUSH	SI			;PTM.					;AN000;
	CALL	Check_PathLen		;PTM.  check path len > 67 ?		;AN000;
	POP	SI			;PTM.					;AN000;
	JBE	pathok			;PTM.					;AN000;
	MOV	AL,error_Access_Denied	;PTM. ops!
	transfer Sys_Ret_Err		;PTM.
pathok:
	CALL	SI			; go get file
	ASSUME	ES:NOTHING
	JC	MkErr			; no errors
	transfer    Sys_Ret_OK
EndProc $MKDIR

; Inputs:
;	nothing
; Function:
;	check if final path length greater than 67
; Returns:
;	Above flag set if > 67

	procedure Check_PathLen,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup

	MOV	SI,Wfp_Start
  entry Check_PathLen2
	Context <DS>
	SaveReg <CX>
	invoke	DStrLen
	CMP	CX,DirStrLen
	RestoreReg  <CX>
	ret
EndProc Check_PathLen
CODE ENDS
END
