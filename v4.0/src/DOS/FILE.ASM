;	SCCSID = @(#)file.asm	1.2 85/07/23
;	SCCSID = @(#)file.asm	1.2 85/07/23
TITLE	FILE - Pathname related system calls
NAME	FILE

;
; Pathname related system calls.  These will be passed direct text of the
; pathname from the user.  They will need to be passed through the macro
; expander prior to being sent through the low-level stuff.  I/O specs are
; defined in DISPATCH.	The system calls are:
;
;   $Open	      written
;   $Creat	      written
;   $ChMod	      written
;   $Unlink	      written
;   $Rename	      written
;   $CreateTempFile   written
;   $CreateNewFile    written
;   $Extended_Open    written  DOS 4.00
;   GetIOParms	      written  DOS 4.00
;
;   Revision history:
;
;	Created: MZ 4 April 1983
;	A000   version 4.00  Jan. 1988

.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGroup,CS:DOSGroup

.xcref
include dossym.inc
include devsym.inc
include fastopen.inc
include EA.inc			     ;AN000;
include version.inc
.cref
.list
.sall

	EXTRN	DOS_OPEN:NEAR,DOS_CREATE:NEAR,DOS_Create_New:NEAR

IF 	NOT IBMCOPYRIGHT
	extrn	Set_EXT_mode:near
ENDIF

	I_need	WFP_Start,WORD		; pointer to beginning of expansion
	I_Need	ThisCDS,DWORD		; pointer to curdir in use
	I_need	ThisSft,DWORD		; SFT pointer for DOS_Open
	I_need	pJFN,DWORD		; temporary spot for pointer to JFN
	I_need	JFN,WORD		; word JFN for process
	I_need	SFN,WORD		; word SFN for process
	I_Need	OpenBuf,128		; buffer for filename
	I_Need	RenBuf,128		; buffer for filename in rename
	I_need	Sattrib,BYTE		; byte attribute to search for
	I_need	Ren_WFP,WORD		; pointer to real path
	I_need	cMeta,BYTE
	I_need	EXTERR,WORD		; extended error code
	I_need	EXTERR_LOCUS,BYTE	; Extended Error Locus
	i_need	JShare,DWORD		; share jump table
	I_need	fSharing,BYTE		; TRUE => via ServerDOSCall
	I_need	FastOpenTable,BYTE
	I_need	CPSWFLAG,BYTE		;AN000;FT. cpsw falg
	I_need	EXTOPEN_FLAG,WORD	;AN000;FT. extended file open flag
	I_need	EXTOPEN_ON,BYTE 	;AN000;FT. extended open flag
	I_need	EXTOPEN_IO_MODE,WORD	;AN000;FT. IO mode
	I_need	XA_from,BYTE		;AN000;;FT. for get/set XA
	I_need	SAVE_ES,WORD		;AN000;;FT. for get/set XA
	I_need	SAVE_DI,WORD		;AN000;;FT. for get/set XA
	I_need	SAVE_DS,WORD		;AN000;;FT. for get/set XA
	I_need	SAVE_SI,WORD		;AN000;;FT. for get/set XA
	I_need	SAVE_DX,WORD		;AN000;;FT. for get/set XA
	I_need	SAVE_BX,WORD		;AN000;;FT. for get/set XA
	I_need	SAVE_CX,WORD		;AN000;;FT. for get/set XA
	I_need	NO_FILTER_DPATH,DWORD	;AN000;; pointer to original path of dest
	I_need	Temp_Var,WORD		;AN000;;
	I_need	DOS34_FLAG,WORD 	;AN000;;
	I_need	Temp_Var2,WORD		;AN000;;
if debug
	I_need	BugLev,WORD
	I_need	BugTyp,WORD
include bugtyp.asm
endif

BREAK <$Open - open a file from a path string>

;
;   $Open - given a path name in DS:DX and an open mode in AL, access the file
;	and return a handle
;   Inputs:	DS:DX - pointer to asciz name
;		AL - open mode
;   Outputs:	Carry Set - AX has error code for invalid open
;		Carry Clear - AX has per process handle number
;   Registers modified: most

Procedure   $Open,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	fmt TypSysCall,LevLog,<"Open\n">
	fmt TypSysCall,LevArgs,<" Mode = $x file = '$S'\n">,<AX,DS,DX>
	XOR	AH,AH
Entry $Open2				;AN000;
	mov	ch,attr_hidden+attr_system+attr_directory
	call	SetAttrib
	MOV	CX,OFFSET DOSGroup:DOS_Open ; address of routine to call
	SaveReg <AX>			; Save mode on stack
IF DBCS 				;AN000;
	MOV	[Temp_Var],0		;AN000;KK. set variable with 0
ENDIF					;AN000;

AccessFile:
;
; Grab a free SFT.
;
IF  DBCS				;AN000;
	TEST	[Temp_Var],8		;AN000;;KK. volume id bit set		       ;AN000;
	JZ	novol			;AN000;;KK. no				       ;AN000;
	OR	[DOS34_FLAG],DBCS_VOLID ;AN000;;KK. set bit for transpath	       ;AN000;
novol:					;AN000;
ENDIF					;AN000;
	EnterCrit   critSFT
	invoke	SFNFree 		; get a free sfn
	LeaveCrit   critSFT
	JC	OpenFailJ		; oops, no free sft's
	MOV	SFN,BX			; save the SFN for later
	fmt	TypAccess,LevSFN,<"AccessFile setting SFN to $x\n">,<BX>
	MOV	WORD PTR [ThisSFT],DI	; save the SF offset
	MOV	WORD PTR [ThisSFT+2],ES ; save the SF segment
;
; Find a free area in the user's JFN table.
;
	invoke	JFNFree 		; get a free jfn
	JNC	SaveJFN
OpenFailJ:
	JMP	OpenFail		; there were free JFNs... try SFN
SaveJFN:
	MOV	WORD PTR [pJFN],DI	; save the jfn offset
	MOV	WORD PTR [pJFN+2],ES	; save the jfn segment
	MOV	[JFN],BX		; save the jfn itself
;
; We have been given an JFN.  We lock it down to prevent other tasks from
; reusing the same JFN.
;
	MOV	BX,SFN
	MOV	ES:[DI],BL		; assign the JFN
	MOV	SI,DX			; get name in appropriate place
	MOV	DI,OFFSET DOSGroup:OpenBuf  ; appropriate buffer
	SaveReg <CX>			; save routine to call
	invoke	TransPath		; convert the path
	RestoreReg  <BX>		; restore routine to call
	LDS	SI,ThisSFT
	ASSUME	DS:NOTHING
	JC	OpenCleanJ		; no error, go and open file
	CMP	cMeta,-1
	JZ	SetSearch
	MOV	AL,error_file_not_found ; no meta chars allowed
OpenCleanJ:
	JMP	OpenClean
SetSearch:
	RestoreReg  <AX>		; Mode (Open), Attributes (Create)
;
; We need to get the new inheritance bits.
;
	xor	cx,cx
	CMP	BX,OFFSET DOSGroup:DOS_OPEN
	JNZ	DoOper
	TEST	AL,sharing_no_inherit	; look for no inher
	JZ	DoOper
	AND	AL,07Fh 		; mask off inherit bit
	MOV	CX,sf_no_inherit
DoOper:
	MOV	[SI].sf_mode,0		; initialize mode field to 0
	MOV	[SI.SF_mft],0		; clean out sharing info
;
;------------------------------------------------------------HKN 8/7/88
;	Check if this is an extended open. If so you must set the 
;	modes in sf_mode. Call Set_EXT_mode to do all this. See
;	Set_EXT_mode in creat.asm
;
IF	NOT IBMCOPYRIGHT

	push	es	; set up es:di to point to SFT
	push	di
	push	ds
	pop	es
	push	si
	pop	di
	call	Set_EXT_mode
	pop	di
	pop	es

ENDIF

;-----------------------------------------------------------------------

	Context DS
	SaveReg <CX>
	CALL	BX			; blam!
	RestoreReg  <CX>
	LDS	SI,ThisSFT
	ASSUME	DS:NOTHING
	JC	OpenE2			;AN000;FT. chek extended open hooks first
;
; The SFT was successfully opened.  Remove busy mark.
;
OpenOK:
	ASSUME	DS:NOTHING
;	MOV	AL,[SI].sf_attr_hi	;AN000;FT. save file type for EXEC
;	MOV	BYTE PTR [Temp_Var2],AL ;AN000;FT.
	MOV	[SI].sf_ref_count,1
	OR	[SI].sf_flags,CX	; set no inherit bit if necessary
;
; If the open mode is 70, we scan the system for other SFT's with the same
; contents.  If we find one, then we can 'collapse' thissft onto the already
; opened one.  Otherwise we use this new one.  We compare uid/pid/mode/mft
;
; Since this is only relevant on sharer systems, we stick this code into the
; sharer.
;
	MOV	AX,JFN
if installed
	Call	JShare + 12 * 4
else
	Call	ShCol
endif
	fmt	TypAccess,LevSFN,<"AccessFile setting SFN to -1\n">
	MOV	SFN,-1			; clear out sfn pointer
	fmt	TypSysCall,LevLog,<"Open/CreateXX: return $x\n">,<AX>
	transfer    Sys_Ret_OK		; bye with no errors
;Extended Open hooks check
OpenE2: 				   ;AN000;;EO.
	CMP	AX,error_invalid_parameter ;AN000;;EO. IFS extended open ?
	JNZ	OpenE			   ;AN000;;EO. no.
	JMP	OpenCritLeave		   ;AN000;;EO. keep handle

;Extended Open hooks check
;
; AL has error code.  Stack has argument to dos_open/dos_create.
;
OpenClean:
	fmt TypSysCall,LevLog,<"Return value from transpath $x\n">,<AX>
	RestoreReg  <bx>		; clean off stack
OpenE:
	MOV	[SI.SF_Ref_Count],0	; release SFT
	LDS	SI,pJFN
	MOV	BYTE PTR [SI],0FFh	; free the SFN...
	JMP	SHORT OpenCritLeave

OpenFail:
	STI
	RestoreReg  <CX>		; Clean stack
OpenCritLeave:
	MOV	SFN,-1			; remove mark.
	fmt TypSysCall,LevLog,<"Open/CreateXX: error $x\n">,<AX>
;; File Tagging DOS 4.00
	CMP	CS:[EXTERR],error_Code_Page_Mismatched	;AN000;;FT. code page mismatch
	JNZ	NORERR					;AN000;;FT. no
	transfer From_GetSet				;AN000;;FT. yes
NORERR: 						;AN000;

;; File Tagging DOS 4.00
	transfer    Sys_Ret_Err 	; no free, return error

EndProc $Open

BREAK <$Creat - create a brand-new file>

;
;   $Creat - create the directory entry specified in DS:DX and give it the
;	initial attributes contained in CX
;   Inputs:	DS:DX - ASCIZ path name
;		CX - initial attributes
;   Outputs:	Carry set - AX has error code
;		Carry reset - AX has handle
;   Registers modified: all

Procedure   $Creat,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	fmt TypSysCall,LevLog,<"Create\n">
	fmt TypSysCall,LevArgs,<" Att = $x file = '$S'\n">,<CX,DS,DX>
IF DBCS 				;AN000;
	MOV	[Temp_Var],CX		;AN000;KK. set variable with attribute	      ;AN000;
ENDIF					;AN000;
	SaveReg <CX>			; Save attributes on stack
	MOV	CX,OFFSET DOSGroup:DOS_Create; routine to call
AccessSet:
	mov	SAttrib,attr_hidden+attr_system
	JMP	AccessFile		; use good ol' open
EndProc $Creat

BREAK <$CHMOD - change file attributes>
;
;   Assembler usage:
;	    LDS     DX, name
;	    MOV     CX, attributes
;	    MOV     AL,func (0=get, 1=set)
;	    INT     21h
;   Error returns:
;	    AX = error_path_not_found
;	    AX = error_access_denied
;

	procedure $CHMOD,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	DI,OFFSET DOSGroup:OpenBuf  ; appropriate buffer
	SaveReg <AX,CX> 		; save function and attributes
	MOV	SI,DX			; get things in appropriate places
	invoke	TransPathSet		; get correct path
	RestoreReg  <CX,AX>		; and get function and attrs back
	JC	ChModErr		; errors get mapped to path not found
	Context DS			; set up for later possible calls
	CMP	cMeta,-1
	JNZ	ChModErr
	MOV	[SAttrib],attr_hidden+attr_system+attr_directory
	SUB	AL,1			; fast way to discriminate
	JB	ChModGet		; 0 -> go get value
	JZ	ChModSet		; 1 -> go set value
	MOV	EXTERR_LOCUS,errLoc_Unk ; Extended Error Locus
	error	error_invalid_function	; bad value
ChModGet:
	invoke	Get_File_Info		; suck out the ol' info
	JC	ChModE			; error codes are already set for ret
	invoke	Get_User_stack		; point to user saved vaiables
	MOV	[SI.User_CX],AX 	; return the attributes
	transfer    Sys_Ret_OK		; say sayonara
ChModSet:
	MOV	AX,CX			; get attrs in position
	invoke	Set_File_Attribute	; go set
	JC	ChModE			; errors are set
	transfer    Sys_Ret_OK
ChModErr:
	mov	al,error_path_not_found
ChmodE:
	Transfer    SYS_RET_ERR
EndProc $ChMod

BREAK <$UNLINK - delete a file entry>
;
;   Assembler usage:
;	    LDS     DX, name
;	    IF VIA SERVER DOS CALL
;	     MOV     CX,SEARCH_ATTRIB
;	    MOV     AH, Unlink
;	    INT     21h
;
;   Error returns:
;	    AX = error_file_not_found
;	       = error_access_denied
;

	procedure $UNLINK,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	SaveReg <CX>			; Save possible CX input parm
	MOV	SI,DX			; Point at input string
	MOV	DI,OFFSET DOSGroup:OpenBuf  ; temp spot for path
	invoke	TransPathSet		; go get normalized path
	RestoreReg <CX>
	JC	ChModErr		; badly formed path
	CMP	cMeta,-1		; meta chars?
	JNZ	NotFound
	Context DS
	mov	ch,attr_hidden+attr_system   ; unlink appropriate files
	call	SetAttrib
	invoke	DOS_Delete		; remove that file
	JC	UnlinkE 		; error is there


	transfer    Sys_Ret_OK		; okey doksy
NotFound:
	MOV	AL,error_path_not_found
UnlinkE:
	transfer    Sys_Ret_Err 	; bye
EndProc $UnLink

BREAK <$RENAME - move directory entries around>
;
;   Assembler usage:
;	    LDS     DX, source
;	    LES     DI, dest
;	    IF VIA SERVER DOS CALL
;	     MOV     CX,SEARCH_ATTRIB
;	    MOV     AH, Rename
;	    INT     21h
;
;   Error returns:
;	    AX = error_file_not_found
;	       = error_not_same_device
;	       = error_access_denied

	procedure $RENAME,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	SaveReg <CX,DS,DX>		; save source and possible CX arg
	PUSH	ES
	POP	DS			; move dest to source
	MOV	SI,DI			; save for offsets
	MOV	DI,OFFSET DOSGroup:RenBuf

	MOV	WORD PTR [NO_FILTER_DPATH],SI	;AN000;;IFS. save them for IFS
	MOV	WORD PTR [NO_FILTER_DPATH+2],DS ;AN000;;IFS.

	invoke	TransPathSet		; munge the paths
	PUSH	WFP_Start		; get pointer
	POP	Ren_WFP 		; stash it
	RestoreReg <SI,DS,CX>		; get back source and possible CX arg
epjc2:	JC	ChModErr		; get old error
	CMP	cMeta,-1
	JNZ	NotFound
	SaveReg <CX>			; Save possible CX arg
	MOV	DI,OFFSET DOSGroup:OpenBuf  ; appropriate buffer
	invoke	TransPathSet		; wham
	RestoreReg <CX>
	JC	EPJC2
	Context DS
	CMP	cMeta,-1
	JB	NotFound

	PUSH	WORD PTR [THISCDS]	   ;AN000;;MS.save thiscds
	PUSH	WORD PTR [THISCDS+2]	   ;AN000;;MS.
	MOV	DI,OFFSET DOSGROUP:OpenBuf ;AN000;;MS.
	PUSH	SS			   ;AN000;;MS.
	POP	ES			   ;AN000;;MS.es:di-> source
	XOR	AL,AL			   ;AN000;;MS.scan all CDS
rnloop: 				   ;AN000;
	invoke	GetCDSFromDrv		   ;AN000;;MS.
	JC	dorn			   ;AN000;;MS.	end of CDS
	invoke	StrCmp			   ;AN000;;MS.	current dir ?
	JZ	rnerr			   ;AN000;;MS.	yes
	INC	AL			   ;AN000;;MS.	next
	JMP	rnloop			   ;AN000;;MS.
rnerr:					   ;AN000;
	ADD	SP,4			   ;AN000;;MS. pop thiscds
	error	error_current_directory    ;AN000;;MS.
dorn:					   ;AN000;
	POP	WORD PTR SS:[THISCDS+2]    ;AN000;;MS.
	POP	WORD PTR SS:[THISCDS]	   ;AN000;;MS.
	Context DS
	mov	ch,attr_directory+attr_hidden+attr_system; rename appropriate files
	call	SetAttrib
	invoke	DOS_Rename		; do the deed
	JC	UnlinkE 		; errors


	transfer    Sys_Ret_OK
EndProc $Rename

Break <$CreateNewFile - Create a new directory entry>

;
;   CreateNew - Create a new directory entry.  Return a file handle if there
;	was no previous directory entry, and fail if a directory entry with
;	the same name existed previously.
;
;   Inputs:	DS:DX point to an ASCIZ file name
;		CX contains default file attributes
;   Outputs:	Carry Clear:
;		    AX has file handle opened for read/write
;		Carry Set:
;		    AX has error code
;   Registers modified: All

	Procedure $CreateNewFile,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	fmt TypSysCall,LevLog,<"CreateNew\n">
	fmt TypSysCall,LevArgs,<" Att = $x file = '$S'\n">,<CX,DS,DX>
IF DBCS 				;AN000;
	MOV	[Temp_Var],CX		;AN000;KK. set variable with attribute
ENDIF					;AN000;
	SaveReg <CX>			; Save attributes on stack
	MOV	CX,OFFSET DOSGroup:DOS_Create_New   ; routine to call
	JMP	AccessSet		; use good ol' open
EndProc $CreateNewFile

Break	<HexToAsciz - convert a number to hex and store it in memory>

;
;   HexToAsciz - used to convert register into a hex number.
;
;   Inputs:	AX contains the number
;		ES:DI point to destination
;   Outputs:	ES:DI updated
;   Registers modified: DI,CX

Procedure   HexToAsciz,NEAR
	mov	cx,4			; 4 digits in AX
GetDigit:
	SaveReg <CX>			; preserve count
	mov	cl,4
	ROL	AX,CL			; move leftmost nibble into rightmost
	SaveReg <AX>			; preserve remainder of digits
	AND	AL,0Fh			; grab low nibble
	ADD	AL,'0'                  ; turn into digit
	CMP	AL,'9'                  ; bigger than 9
	JBE	DoStore 		; no, stash it
	ADD	AL,'A'-'0'-10           ; convert into uppercase letter
DoStore:
	STOSB				; drop in the character
	RestoreReg <AX,CX>		; regain the number and count
	loop	GetDigit		; while there's more digits, go do 'em
	return
EndProc HexToAsciz

Break	<$CreateTempFile - create a unique name>

;
;   $CreateTemp - given a directory, create a unique name in that directory.
;	Method used is to get the current time, convert to a name and attempt
;	a create new.  Repeat until create new succeeds.
;
;   Inputs:	DS:DX point to a null terminated directory name.
;		CX  contains default attributes
;   Outputs:	Unique name is appended to DS:DX directory.
;		AX has handle
;   Registers modified: all

	Procedure $CreateTempFile,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	fmt TypSysCall,LevLog,<"CreateTmp\n">
	fmt TypSysCall,LevArgs,<" Att = $x dir = '$S'\n">,<CX,DS,DX>
PUBLIC FILE001S,FILE001E
FILE001S:
	LocalVar    EndPtr,DWORD
	LocalVar    FilPtr,DWORD
	LocalVar    Attr,WORD
FILE001E:
	Enter
	TEST	CX,NOT attr_changeable
	JZ	OKatts			; Ok if no non-changeable bits set
;
; We need this "hook" here to detect these cases (like user sets one both of
; vol_id and dir bits) because of the structure of the or $CreateNewFile loop
; below.  The code loops on error_access_denied, but if one of the non
; changeable attributes is specified, the loop COULD be infinite or WILL be
; infinite because CreateNewFile will fail with access_denied always.  Thus we
; need to detect these cases before getting to the loop.
;
	MOV	AX,error_access_denied
	JMP	SHORT SETTMPERR

OKatts:
	MOV	attr,CX 		; save attribute
	MOV	FilPtrL,DX		; pointer to file
	MOV	FilPtrH,DS
	MOV	EndPtrH,DS		; seg pointer to end of dir
	PUSH	DS
	POP	ES			; destination for nul search
	MOV	DI,DX
	MOV	CX,DI
	NEG	CX			; number of bytes remaining in segment
 IF  DBCS				;AN000;
Kloop:					;AN000;; 2/13/KK
	MOV	AL, BYTE PTR ES:[DI]	;AN000;; 2/13/KK
	INC	DI			;AN000;; 2/13/KK
	OR	AL,AL			;AN000;; 2/13/KK
	JZ	GOTEND			;AN000;; 2/13/KK
	invoke	testkanj		;AN000;; 2/13/KK
	jz	Kloop			;AN000;; 2/13/KK
	inc	di			;AN000;; Skip over second kanji byte 2/13/KK
	CMP	BYTE PTR ES:[DI],0	;AN000;; 2/13/KK
	JZ	STOREPTH		;AN000; When char before NUL is sec Kanji byte
					;AN000; do not look for path char. 2/13/KK
	jmp	Kloop			;AN000; 2/13/KK
GOTEND: 				;AN000; 2/13/KK
 ELSE					;AN000;
	OR	CX,CX			;AN000;MS.  cx=0 ? ds:dx on segment boundary
	JNZ	okok			;AN000;MS.  no
	MOV	CX,-1			;AN000;MS.
okok:					;AN000;
	XOR	AX,AX			;AN000;
	REPNZ	SCASB			;AN000;
 ENDIF					;AN000;
	DEC	DI			; point back to the null
	MOV	AL,ES:[DI-1]		; Get char before the NUL
	invoke	PathChrCmp		; Is it a path separator?
	JZ	SETENDPTR		; Yes
STOREPTH:
	MOV	AL,'\'
	STOSB				; Add a path separator (and INC DI)
SETENDPTR:
	MOV	EndPtrL,DI		; pointer to the tail
CreateLoop:
	Context DS			; let ReadTime see variables
	SaveReg <BP>
	invoke	ReadTime		; go get time
	RestoreReg  <BP>
;
; Time is in CX:DX.  Go drop it into the string.
;
	les	di,EndPtr		; point to the string
	mov	ax,cx
	call	HexToAsciz		; store upper word
	mov	ax,dx
	call	HexToAsciz		; store lower word
	xor	al,al
	STOSB				; nul terminate
	LDS	DX,FilPtr		; get name
ASSUME	DS:NOTHING
	MOV	CX,Attr 		; get attr
	SaveReg <BP>
	CALL	$CreateNewFile		; try to create a new file
	RestoreReg  <BP>
	JNC	CreateDone		; failed, go try again
;
; The operation failed and the error has been mapped in AX.  Grab the extended
; error and figure out what to do.
;
	mov	ax,ExtErr
	cmp	al,error_file_exists
	jz	CreateLoop		; file existed => try with new name
	cmp	al,error_access_denied
	jz	CreateLoop		; access denied (attr mismatch)

;	CMP	AL,error_file_exists	; certain errors cause failure
;	JZ	CreateLoop
;	CMP	AL,error_access_denied
;	JNZ	SETTMPERR		; Error out
;	CMP	[EXTERR],error_cannot_make  ; See if it's REALLY an att mismatch
;	JNZ	CreateLoop		; It was, try again
;	MOV	AL,error_cannot_make	; Return this "extended" error

SETTMPERR:
	STC
CreateDone:
	Leave
	JC	CreateFail
	transfer    Sys_Ret_OK		; success!
CreateFail:
	transfer    Sys_Ret_Err
EndProc $CreateTempFile

Break	<SetAttrib - set the search attrib>

;
;   SetAttrib will set the search attribute (SAttrib) either to the normal
;   (CH) or to the value in CL if the current system call is through
;   serverdoscall.
;
;   Inputs:	fSharing == FALSE => set sattrib to CH
;		fSharing == TRUE => set sattrib to CL
;   Outputs:	none
;   Registers changed:	CX

procedure   SetAttrib,NEAR
	assume	ds:nothing,es:nothing
	test	fSharing,-1
	jnz	Set
	mov	cl,ch
Set:
	mov	SAttrib,cl
	return
EndProc SetAttrib


Break	<Extended_Open- Extended open the file>

; Input: AL= 0 reserved  AH=6CH
;	 BX= mode
;	 CL= create attribute  CH=search attribute (from server)
;	 DX= flag
;	 DS:SI = file name
;	 ES:DI = parm list
;			   DD  SET EA list (-1) null
;			   DW  n  parameters
;			   DB  type (TTTTTTLL)
;			   DW  IOMODE
; Function: Extended Open
; Output: carry clear
;		     AX= handle
;		     CX=1 file opened
;			2 file created/opened
;			3 file replaced/opened
;	  carry set: AX has error code
;


procedure   $Extended_Open,NEAR 			       ;AN000;
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP  ;AN000;

	MOV	[XA_from],0		  ;AN000;EO. init for set XA
	MOV	[EXTOPEN_FLAG],DX	  ;AN000;EO. save ext. open flag
	MOV	[EXTOPEN_IO_MODE],0	  ;AN000;EO. initialize IO mode
	TEST	DX,reserved_bits_mask	  ;AN000;EO. reserved bits 0  ?
	JNZ	ext_inval2		  ;AN000;EO. no
	MOV	AH,DL			  ;AN000;EO. make sure flag is right
	CMP	DL,0			  ;AN000;EO. all fail ?
	JZ	ext_inval2		  ;AN000;EO. yes, error
	AND	DL,exists_mask		  ;AN000;EO. get exists action byte
	CMP	DL,2			  ;AN000;EO, > 02
	JA	ext_inval2		  ;AN000;EO. yes ,error
	AND	AH,not_exists_mask	  ;AN000;EO. get no exists action byte
	CMP	AH,10H			  ;AN000;EO. > 10
	JA	ext_inval2		  ;AN000;EO. yes error

;	CMP	DI,-1			  ;AN000;EO. null parm list
;	JZ	no_parm 		  ;AN000;EO. yes
;					  ;AN000;EO
;	PUSH	CX			  ;AN000;EO.
;					  ;AN000;EO.
;	MOV	CX,ES:[DI.EXT_NUM_OF_PARM];AN000;EO. get number of parms
;	OR	CX,CX			  ;AN000;EO. 0 pamrs ?
;	JZ	parmend 		  ;AN000;EO. yes
;	PUSH	SI			  ;AN000;EO.
;	PUSH	DS			  ;AN000;EO.
;	MOV	SI,DI			  ;AN000;EO.
;	ADD	SI,size EXT_OPEN_PARM	  ;AN000;EO. position to 1st parm
;	PUSH	ES			  ;AN000;EO.
;	POP	DS			  ;AN000;EO. ds:si -> parm list
;	CALL	GetIOParms		  ;AN000;EO.
;	POP	DS			  ;AN000;EO.
;	POP	SI			  ;AN000;EO.
;parmend:				  ;AN000;EO
;	POP	CX			  ;AN000;EO. restore CX
;no_parm:				  ;AN000;EO.
	MOV	[SAVE_ES],ES		  ;AN000;EO. save API parms
	MOV	[SAVE_DI],DI		  ;AN000;EO.
	PUSH	[EXTOPEN_FLAG]		  ;AN000;EO.
	POP	[SAVE_DX]		  ;AN000;EO.
	MOV	[SAVE_CX],CX		  ;AN000;EO.
	MOV	[SAVE_BX],BX		  ;AN000;EO.
	MOV	[SAVE_DS],DS		  ;AN000;EO.
	MOV	[SAVE_SI],SI		  ;AN000;EO.
	MOV	DX,SI			  ;AN000;EO. ds:dx points to file name
	MOV	AX,BX			  ;AN000;EO. ax= mode

;	TEST	[EXTOPEN_FLAG],no_code_page_check    ;AN000;EO. check no  code page
;	JNZ	no_cdpg_chk			 ;AN000;;EO.  no
	JMP	SHORT goopen2			 ;AN000;;EO.  do nromal
ext_inval2:					 ;AN000;;EO.
	error	error_Invalid_Function		 ;AN000;EO..  invalid function
ext_inval_parm: 				 ;AN000;EO..
	POP	CX				 ;AN000;EO..  pop up satck
	POP	SI				 ;AN000;EO..
	error	error_Invalid_data		 ;AN000;EO..  invalid parms
error_return:					 ;AN000;EO.
	ret					 ;AN000;EO..  return with error
;no_cdpg_chk:						EO.
;	MOV	[CPSWFLAG],0			 ;AN000;EO..  set CPSW flag off
goopen2:					 ;AN000;
	TEST	BX,int_24_error 		 ;AN000;EO..  disable INT 24 error ?
	JZ	goopen				 ;AN000;EO..  no
	OR	[EXTOPEN_ON],EXT_OPEN_I24_OFF	 ;AN000;EO..  set bit to disable

goopen: 					 ;AN000;
	OR	[EXTOPEN_ON],EXT_OPEN_ON	 ;AN000;EO..  set Extended Open active
	AND	[EXTOPEN_FLAG],0FFH		 ;AN000;EO.create new ?
	CMP	[EXTOPEN_FLAG],ext_exists_fail + ext_nexists_create ;AN000;FT.
	JNZ	chknext 			 ;AN000;;EO.  no
	invoke	$CreateNewFile			 ;AN000;;EO.  yes
	JC	error_return			 ;AN000;;EO.  error
	CMP	[EXTOPEN_ON],0			 ;AN000;;EO.  IFS does it
	JZ	ok_return2			 ;AN000;;EO.  yes
	MOV	[EXTOPEN_FLAG],action_created_opened ;AN000;EO. creted/opened
	MOV	[XA_from],By_Create		 ;AN000;;EO.  for set xa
	JMP	setXAttr			 ;AN000;;EO.  set XAs
ok_return2:
	transfer SYS_RET_OK			 ;AN000;;EO.
chknext:
	TEST	[EXTOPEN_FLAG],ext_exists_open	 ;AN000;;EO.  exists open
	JNZ	exist_open			 ;AN000;;EO.  yes
	invoke	$Creat				 ;AN000;;EO.  must be replace open
	JC	error_return			 ;AN000;;EO.  return with error
	CMP	[EXTOPEN_ON],0			 ;AN000;;EO.  IFS does it
	JZ	ok_return2			 ;AN000;;EO.  yes
	MOV	[EXTOPEN_FLAG],action_created_opened  ;AN000;EO. prsume create/open
	MOV	[XA_from],By_Create		 ;AN000;EO.  for set xa
	TEST	[EXTOPEN_ON],ext_file_not_exists      ;AN000;;EO. file not exists ?
	JNZ	setXAttr			      ;AN000;;EO. no
	MOV	[EXTOPEN_FLAG],action_replaced_opened ;AN000;;EO. replaced/opened
	MOV	[XA_from],0			      ;AN000;EO. for set xa
	JMP	SHORT setXAttr			      ;AN000;;EO. set XAs
error_return2:
	ret					 ;AN000;;EO.  return with error
						 ;AN000;
exist_open:					 ;AN000;
	test	fSharing,-1			 ;AN000;;EO. server doscall?
	jz	noserver			 ;AN000;;EO. no
	MOV	CL,CH				 ;AN000;;EO. cl=search attribute

noserver:
	invoke	$Open2				 ;AN000;;EO.  do open
	JNC	ext_ok				 ;AN000;;EO.
	CMP	[EXTOPEN_ON],0			 ;AN000;;EO.  error and IFS call
	JZ	error_return2			 ;AN000;;EO.  return with error
local_extopen:

	CMP	AX,error_file_not_found 	 ;AN000;;EO.  file not found error
	JNZ	error_return2			 ;AN000;;EO.  no,
	TEST	[EXTOPEN_FLAG],ext_nexists_create;AN000;;EO.  want to fail
	JNZ	do_creat			 ;AN000;;EO.  yes
	JMP	extexit 			 ;AN000;;EO.  yes
do_creat:
	MOV	[XA_from],By_Create		 ;AN000;;EO.  for set xa
	MOV	CX,[SAVE_CX]			 ;AN000;;EO.  get ds:dx for file name
	LDS	SI,DWORD PTR [SAVE_SI]		 ;AN000;;EO.  cx = attribute
	MOV	DX,SI				 ;AN000;;EO.
	invoke	$Creat				 ;AN000;;EO.  do create
	JC	extexit 			 ;AN000;;EO.  error
	MOV	[EXTOPEN_FLAG],action_created_opened  ;AN000;;EO. is created/opened
	JMP	SHORT setXAttr			      ;AN000;;EO.   set XAs

ext_ok:
	CMP	[EXTOPEN_ON],0			 ;AN000;;EO.  IFS call ?
	JZ	ok_return			 ;AN000;;EO.  yes
	MOV	[EXTOPEN_FLAG],action_opened	 ;AN000;;EO.  opened
setXAttr:
;	LES	DI,DWORD PTR [SAVE_DI]	;AN000;EO.
	PUSH	AX			;AN000;;EO. save handle for final
;	MOV	BX,AX			;AN000;;EO. bx= handle
;	MOV	AX,04H			;AN000;;EO. set extended attr by handle
;	PUSH	DS			;AN000;;EO. save file name addr
;	PUSH	DX			;AN000;;EO.
;	CMP	DI,-1			;AN000;;EO. null parm list
;	JZ	nosetea 		;AN000;;EO. yes
;	CMP	WORD PTR ES:[DI],-1	;AN000;;EO. null set list
;	JZ	nosetea 		;AN000;;EO. yes
;	LES	DI,DWORD PTR ES:[DI]	;AN000;;EO. es:di -> set list
;	invoke	$File_times		;AN000;;EO.
;nosetea:				;AN000; EO
;	POP	DX			;AN000;;EO. restore file name addr
;	POP	DS			;AN000;;EO.
;	JC	extexit2		;AN000;;EO.
	invoke	get_user_stack		;AN000;;EO.
	MOV	AX,[EXTOPEN_FLAG]	;AN000;;EO.
	MOV	[SI.USER_CX],AX 	;AN000;;EO. set action code for cx
	POP	AX			;AN000;;EO.
	MOV	[SI.USER_AX],AX 	;AN000;;EO. set handle for ax

ok_return:				;AN000;
	transfer SYS_RET_OK		;AN000;;EO.

extexit2:				;AN000; ERROR RECOVERY

	POP	BX			;AN000;EO. close the handle
	PUSH	AX			;AN000;EO. save error code from set XA
	CMP	[EXTOPEN_FLAG],action_created_opened	;AN000;EO. from create
	JNZ	justopen		;AN000;EO.
	LDS	SI,DWORD PTR [SAVE_SI]		 ;AN000;EO.  cx = attribute
	LDS	DX,DWORD PTR [SI]		 ;AN000;EO.
	invoke	$UNLINK 		;AN000;EO. delete the file
	JMP	SHORT reserror		;AN000;EO.

justopen:				;AN000;
	invoke	$close			;AN000;EO. pretend never happend
reserror:				;AN000;
	POP	AX			;AN000;EO. retore error code from set XA
	JMP	SHORT extexit		;AN000;EO.


ext_file_unfound:			;AN000;
	MOV	AX,error_file_not_found ;AN000;EO.
	JMP	SHORT extexit		;AN000;EO.
ext_inval:				 ;AN000;
	MOV	AX,error_invalid_function;AN000;EO.
extexit:
	transfer SYS_RET_ERR		;AN000;EO.

EndProc $Extended_Open			;AN000;


Break	<GetIOParms - get IO parms form extended open parm list>

;
;
;   Inputs: DS:SI -> IO parm list
;	    CX= number of parms
;   Function: get IO parms from parm list
;   Outputs:  [EXT_IOMODE]= IO mode parm

;procedure   GetIOParms,NEAR
;	assume	ds:nothing,es:nothing
;
;	LODSB					; get parm type 		;AN000;
;	CMP	AL,0*100B+10B			; have IOMODE			;AN000;
;	JE	SET_IOMODE							;AN000;
;	AND	AL,00000011B			; decode it			;AN000;
;	JZ	SKIP_ASCIIZ							;AN000;
;	DEC	AL								;AN000;
;	JZ	SKIP_LEN							;AN000;
;;	DEC	AL								;AN000;
;	JZ	SKIP_WORD							;AN000;
;SKIP_DWORD:					 ; copy DWORD parm		 ;AN000;
;	LODSW									;AN000;
;SKIP_WORD:					 ; copy WORD parm		 ;AN000;
;	LODSW									;AN000;
;	JMP	SHORT NEXT_PARM 						;AN000;
;SET_IOMODE:					 ; copy IOMODE			 ;AN000;
;	LODSW									;AN000;
;	MOV	[EXTOPEN_IO_MODE],AX						;AN000;
;	JMP	SHORT NEXT_PARM 						;AN000;
;SKIP_LEN:					 ; copy LENGTH parm		 ;AN000;
;	LODSW									;AN000;
;	ADD	SI,AX								;AN000;
;	JMP	SHORT NEXT_PARM 						;AN000;
;SKIP_ASCIIZ:					 ; copy ASCIIZ parm		 ;AN000;
;	LODSB									;AN000;
;	OR	AL,AL								;AN000;
;	JNE	SKIP_ASCIIZ							;AN000;
;NEXT_PARM:									 ;AN000;
;	LOOP	GetIOParms							;AN000;
;	return									;AN000;
;EndProc GetIOParms								 ;AN000;


CODE ENDS
END
