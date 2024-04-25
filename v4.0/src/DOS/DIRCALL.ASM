;	SCCSID = @(#)dircall.asm	1.1 85/04/10
;	SCCSID = @(#)dircall.asm	1.1 85/04/10
TITLE DIRCALL - Directory manipulation internal calls
NAME  DIRCALL
; Low level directory manipulation routines for making removing and
;   verifying local or NET directories
;
;   DOS_MKDIR
;   DOS_CHDIR
;   DOS_RMDIR
;
;   Modification history:
;
;	Created: ARR 30 March 1983
;

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
INCLUDE FASTOPEN.INC
INCLUDE FASTXXXX.INC
.cref
.list

Installed = TRUE

	i_need	THISSFT,DWORD
	i_need	THISCDS,DWORD
	i_need	NoSetDir,BYTE
	i_need	CURBUF, DWORD
	i_need	DIRSTART,WORD
	i_need	THISDPB,DWORD
	i_need	NAME1,BYTE
	i_need	LASTENT,WORD
	i_need	SATTRIB,BYTE
	i_need	ATTRIB,BYTE
	i_need	ALLOWED,BYTE
	i_need	FAILERR,BYTE
	i_need	RenBuf,BYTE
	i_need	FastOpenFlg,BYTE		  ; DOS 3.3
	i_need	FastOpenTable,BYTE		  ; DOS 3.3
	i_need	WFP_START,WORD			  ; DOS 3.3
	i_need	HIGH_SECTOR,WORD		  ; F.C. >32mb

BREAK <DOS_MkDir - Make a directory entry>

; Inputs:
;	[WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL
;		terminated)
;	[CURR_DIR_END] Points to end of Current dir part of string
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[THISCDS] Points to CDS being used
;		(Low word = -1 if NUL CDS (Net direct request))
; Function:
;	Make a new directory
; Returns:
;	Carry Clear
;		No error
;	Carry Set
;	    AX is error code
;		error_path_not_found
;			Bad path (not in curr dir part if present)
;		error_bad_curr_dir
;			Bad path in current directory part of path
;		error_access_denied
;			Already exists, device name
; DS preserved, Others destroyed

	procedure   DOS_MKDIR,NEAR
	DOSAssume   CS,<DS>,"DOS_MkDir"
	ASSUME	ES:NOTHING

	Invoke	TestNet
	JNC	local_mkdir
IF NOT Installed
	transfer NET_MKDIR
ELSE
	MOV	AX,(multNET SHL 8) OR 3
	INT	2FH
	return
ENDIF

NODEACCERRJ:
	MOV	AX,error_access_denied
BadRet:
	STC
	LeaveCrit   critDisk
	return

PATHNFJ:
	LeaveCrit   critDisk
	transfer SET_MKND_ERR		; Map the MakeNode error and return

LOCAL_MKDIR:
	EnterCrit   critDisk
;
; MakeNode requires an SFT to fiddle with.  We Use a temp spot (RENBUF)
;
	MOV	WORD PTR [THISSFT+2],SS
	MOV	WORD PTR [THISSFT],OFFSET DOSGroup:RenBuf
;
;  NOTE: Need WORD PTR because MASM takes type of
;   TempSFT (byte) instead of type of sf_mft (word).
;
	MOV	WORD PTR RenBuf.sf_mft,0    ; make sure SHARER won't complain.
	MOV	AL,attr_directory
	invoke	MAKENODE

	JC	PATHNFJ
	CMP	AX,3
	JZ	NODEACCERRJ	; Can't make a device into a directory
	LES	BP,[THISDPB]	; Makenode zaps this
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	SUB	SI,DI
	PUSH	SI		; Pointer to dir_first
	PUSH	WORD PTR [DI.buf_sector+2]	    ;F.C. >32mb

	PUSH	WORD PTR [DI.buf_sector] ; Sector of new node
	context DS
	PUSH	[DIRSTART]	; Parent for .. entry
	XOR	AX,AX
	MOV	[DIRSTART],AX	; Null directory
	invoke	NEWDIR
	JC	NODEEXISTSPOPDEL    ; No room
	invoke	GETENT		; First entry
	JC	NODEEXISTSPOPDEL    ; Screw up
	LES	DI,[CURBUF]

	TEST	ES:[DI.buf_flags],buf_dirty  ;LB. if already dirty		;AN000;
	JNZ	yesdirty		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	ES:[DI.buf_flags],buf_dirty
yesdirty:
	ADD	DI,BUFINSIZ	; Point at buffer
	MOV	AX,202EH	; ". "
	MOV	DX,[DIRSTART]	; Point at itself
	invoke	SETDOTENT
	MOV	AX,2E2EH	; ".."
	POP	DX		; Parent
	invoke	SETDOTENT
	LES	BP,[THISDPB]
	MOV	[ALLOWED],allowed_FAIL + allowed_RETRY
	POP	DX		; Entry sector
	POP	[HIGH_SECTOR]	;F.C. >32mb

	XOR	AL,AL		; Pre read
	invoke	GETBUFFR
	JC	NODEEXISTSP
	MOV	DX,[DIRSTART]
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	OR	[DI.buf_flags],buf_isDIR
	POP	SI		; dir_first pointer
	ADD	SI,DI
	MOV	[SI],DX
	XOR	DX,DX
	MOV	[SI+2],DX	; Zero size
	MOV	[SI+4],DX
DIRUP:
	TEST	[DI.buf_flags],buf_dirty  ;LB. if already dirty 		;AN000;
	JNZ	yesdirty2		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	[DI.buf_flags],buf_dirty	; Dirty buffer
yesdirty2:
	context DS
	MOV	AL,ES:[BP.dpb_drive]
	invoke	FLUSHBUF
	MOV	AX,error_access_denied
	LeaveCrit   critDisk
	return

NODEEXISTSPOPDEL:
	POP	DX		; Parent
	POP	DX		; Entry sector
	POP	[HIGH_SECTOR]	; F.C. >32mb

	LES	BP,[THISDPB]
	MOV	[ALLOWED],allowed_FAIL + allowed_RETRY
	XOR	AL,AL		; Pre read
	invoke	GETBUFFR
	JC	NODEEXISTSP
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	OR	[DI.buf_flags],buf_isDIR
	POP	SI		; dir_first pointer
	ADD	SI,DI
	SUB	SI,dir_first	;Point back to start of dir entry
	MOV	BYTE PTR [SI],0E5H    ; Free the entry
	CALL	DIRUP		; Error doesn't matter since erroring anyway
NODEEXISTS:
	JMP	NODEACCERRJ

NODEEXISTSP:
	POP	SI		; Clean stack
	JMP	NODEEXISTS

EndProc DOS_MKDIR

BREAK <DOS_ChDir -- Verify a directory>

; Inputs:
;	[WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL
;		terminated)
;	[CURR_DIR_END] Points to end of Current dir part of string
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[THISCDS] Points to CDS being used May not be NUL
; Function:
;	Validate the path for potential new current directory
; Returns:
;	NOTE:
;	    [SATTRIB] is modified by this call
;	Carry Clear
;	    CX is cluster number of the DIR, LOCAL CDS ONLY
;		Caller must NOT set ID fields on a NET CDS.
;	Carry Set
;	    AX is error code
;		error_path_not_found
;			Bad path
;		error_access_denied
;			device or file name
; DS preserved, Others destroyed

	procedure   DOS_CHDIR,NEAR
	DOSAssume   CS,<DS>,"DOS_Chdir"
	ASSUME	ES:NOTHING

	Invoke	TestNet
	JNC	LOCAL_CHDIR
IF NOT Installed
	transfer NET_CHDIR
ELSE
	MOV	AX,(multNET SHL 8) OR 5
	INT	2FH
	return
ENDIF

LOCAL_CHDIR:
	EnterCrit   critDisk
	TEST	ES:[DI.curdir_flags],curdir_splice ;PTM.
	JZ	nojoin				   ;PTM.
	MOV	ES:[DI.curdir_ID],0FFFFH	   ;PTM.
nojoin:
	MOV	[NoSetDir],FALSE
	MOV	[SATTRIB],attr_directory+attr_system+attr_hidden
				; Dir calls can find these
; DOS 3.3  6/24/86 FastOpen

	OR	[FastOpenFlg],FastOpen_Set	   ; set fastopen flag
	invoke	GetPath
	PUSHF									;AN000;
	AND	[FastOpenFlg],Fast_yes		   ; clear it all		;AC000;
	POPF									;AN000;
; DOS 3.3  6/24/86 FastOpen
	MOV	AX,error_path_not_found
	JC	ChDirDone
	JNZ	NOTDIRPATH	; Path not a DIR
	MOV	CX,[DIRSTART]	; Get cluster number
	CLC
ChDirDone:
	LeaveCrit   critDisk
	return

EndProc DOS_CHDIR

BREAK <DOS_RmDir -- Remove a directory>

; Inputs:
;	[WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL
;		terminated)
;	[CURR_DIR_END] Points to end of Current dir part of string
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[THISCDS] Points to CDS being used
;		(Low word = -1 if NUL CDS (Net direct request))
; Function:
;	Remove a directory
;	NOTE: Attempt to remove current directory must be detected by caller
; Returns:
;	NOTE:
;	    [SATTRIB] is modified by this call
;	Carry Clear
;		No error
;	Carry Set
;	    AX is error code
;		error_path_not_found
;			Bad path (not in curr dir part if present)
;		error_bad_curr_dir
;			Bad path in current directory part of path
;		error_access_denied
;			device or file name, root directory
;			Bad directory ('.' '..' messed up)
; DS preserved, Others destroyed

	procedure   DOS_RMDIR,NEAR
	DOSAssume   CS,<DS>,"DOS_RmDir"
	ASSUME	ES:NOTHING

	Invoke	TestNet
	JNC	Local_RmDIR
IF NOT Installed
	transfer NET_RMDIR
ELSE
	MOV	AX,(multNET SHL 8) OR 1
	INT	2FH
	return
ENDIF

LOCAL_RMDIR:
	EnterCrit   critDisk
	MOV	[NoSetDir],0
	MOV	[SATTRIB],attr_directory+attr_system+attr_hidden
				; Dir calls can find these
	invoke	GetPath
	JC	NOPATH		; Path not found
	JNZ	NOTDIRPATH	; Path not a DIR
	MOV	DI,[DIRSTART]
	OR	DI,DI		; Root ?
	JNZ	rmdir_get_buf	; No
	JMP	SHORT NOTDIRPATH

NOPATH:
	MOV	AX,error_path_not_found
	JMP	BadRet

NOTDIRPATHPOP:
	POP	AX			  ;F.C. >32mb
	POP	AX
NOTDIRPATHPOP2:
	POP	AX
NOTDIRPATH:
	JMP	NodeAccErrJ

rmdir_get_buf:
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	SUB	BX,DI		; Compute true offset
	PUSH	BX		; Save entry pointer
	PUSH	WORD PTR [DI.buf_sector+2] ;F.C. >32mb
	PUSH	WORD PTR [DI.buf_sector] ; Save sector number
	context DS
	context ES
	MOV	DI,OFFSET DOSGROUP:NAME1
	MOV	AL,'?'
	MOV	CX,11
	REP	STOSB
	XOR	AL,AL
	STOSB			; Nul terminate it
	invoke	STARTSRCH	; Set search
	invoke	GETENTRY	; Get start of directory
	JC	NOTDIRPATHPOP	; Screw up
	MOV	DS,WORD PTR [CURBUF+2]
ASSUME	DS:NOTHING
	MOV	SI,BX
	LODSW
	CMP	AX,(' ' SHL 8) OR '.'   ; First entry '.'?
	JNZ	NOTDIRPATHPOP		; Nope
	ADD	SI,(SIZE dir_entry) - 2 ; Next entry
	LODSW
	CMP	AX,('.' SHL 8) OR '.'   ; Second entry '..'?
	JNZ	NOTDIRPATHPOP		; Nope
	context DS
	MOV	[LASTENT],2		; Skip . and ..
	invoke	GETENTRY		; Get next entry
	JC	NOTDIRPATHPOP		; Screw up
	MOV	[ATTRIB],attr_directory+attr_hidden+attr_system
	invoke	SRCH			; Do a search
	JNC	NOTDIRPATHPOP		; Found another entry!
	CMP	[FAILERR],0
	JNZ	NOTDIRPATHPOP		; Failure of search due to I 24 FAIL
	LES	BP,[THISDPB]
	MOV	BX,[DIRSTART]
;; FastSeek 10/27/86
	invoke	Delete_FSeek		; delete the fastseek entry
;; FastSeek 10/27/86
	invoke	RELEASE 		; Release data in sub dir
	JC	NOTDIRPATHPOP		; Screw up
	POP	DX			; Sector # of entry
	POP	[HIGH_SECTOR]		; F.C. >32mb

	MOV	[ALLOWED],allowed_FAIL + allowed_RETRY
	XOR	AL,AL			; Pre read
	invoke	GETBUFFR		; Get sector back
	JC	NOTDIRPATHPOP2		; Screw up
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	OR	[DI.buf_flags],buf_isDIR
	POP	BX			; Pointer to start of entry
	ADD	BX,DI			; Corrected
	MOV	BYTE PTR [BX],0E5H	; Free the entry

;DOS 3.3 FastOpen  6/16/86  F.C.
	PUSH	DS
	context DS
	invoke	FastOpen_Delete 	; call fastopen to delete an entry
	POP	DS
;DOS 3.3 FastOpen  6/16/86  F.C.

	JMP	DIRUP			; In MKDIR, dirty buffer and flush

EndProc DOS_RMDIR

CODE	ENDS
    END
