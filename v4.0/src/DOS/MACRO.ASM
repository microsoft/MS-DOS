;	SCCSID = @(#)macro.asm	1.2 85/07/11
TITLE	MACRO - Pathname and macro related internal routines
NAME	MACRO
;
;   $AssignOper     written
;   FIND_DPB	    written
;   InitCDS	    written
;   $UserOper	    written
;   GetVisDrv	    written
;   GetThisDrv	    written
;   GetCDSFromDrv   written
;
;   Revision history:
;
;	Created: MZ 4 April 1983
;		 MZ 18 April 1983   Make TransFCB handle extended FCBs
;		 AR 2 June 1983     Define/Delete macro for NET redir.
;		 MZ 3 Nov 83	    Fix InitCDS to reset length to 2
;		 MZ 4 Nov 83	    Fix NetAssign to use STRLEN only
;		 MZ 18 Nov 83	    Rewrite string processing for subtree
;				    aliasing.
;
;   MSDOS performs several types of name translation.  First, we maintain for
;   each valid drive letter the text of the current directory on that drive.
;   For invalid drive letters, there is no current directory so we pretend to
;   be at the root.  A current directory is either the raw local directory
;   (consisting of drive:\path) or a local network directory (consisting of
;   \\machine\path.  There is a limit on the point to which a ..  is allowed.
;
;   Given a path, MSDOS will transform this into a real from-the-root path
;   without .  or ..  entries.	Any component that is > 8.3 is truncated to
;   this and all * are expanded into ?'s.
;
;   The second part of name translation involves subtree aliasing.  A list of
;   subtree pairs is maintained by the external utility SUBST.	The results of
;   the previous 'canonicalization' are then examined to see if any of the
;   subtree pairs is a prefix of the user path.  If so, then this prefix is
;   replaced with the other subtree in the pair.
;
;   A third part involves mapping this "real" path into a "physical" path.  A
;   list of drive/subtree pairs are maintained by the external utility JOIN.
;   The output of the previous translation is examined to see if any of the
;   subtrees in this list are a prefix of the string.  If so, then the prefix
;   is replaced by the appropriate drive letter.  In this manner, we can
;   'mount' one device under another.
;
;   The final form of name translation involves the mapping of a user's
;   logical drive number into the internal physical drive.  This is
;   accomplished by converting the drive number into letter:CON, performing
;   the above translation and then converting the character back into a drive
;   number.
;
;   curdir_list     STRUC
;   curdir_text     DB	    DIRSTRLEN DUP (?) ; text of assignment and curdir
;   curdir_flags    DW	    ?		    ; various flags
;   curdir_devptr   DD	    ?		    ; local pointer to DPB or net device
;   curdir_ID	    DW	    ?		    ; cluster of current dir (net ID)
;		    DW	    ?
;   curdir_end	    DW	    ?		    ; end of assignment
;   curdir_list     ENDS
;   curdir_netID    EQU     DWORD PTR curdir_ID
;   ;Flag word masks
;   curdir_isnet    EQU     1000000000000000B
;   curdir_inuse    EQU     0100000000000000B
;
;   There are two main entry points:  TransPath and TransFCB.  TransPath will
;   take a path and form the real text of the pathname with all .  and ..
;   removed.  TransFCB will translate an FCB into a path and then invoke
;   TransPath.
;
;   Implementation note:  CURDIR_End field points to the point in the text
;   string where the user may back up to via ..  It is the location of a
;   separator character.  For the root, it points at the leading /.  For net
;   assignments it points at the end (nul) of the initial assignment:
;   A:/     \\foo\bar	    \\foo\bar\blech\bozo
;     ^ 	     ^		     ^
; A: -> d: /path/ path/ text
;
;   A000    version 4.00  Jan. 1988

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
.sall

Installed = TRUE

	I_need	ThisCDS,DWORD		; pointer to CDS used
	I_need	CDSAddr,DWORD		; pointer to CDS table
	I_need	CDSCount,BYTE		; number of CDS entries
	I_need	CurDrv,BYTE		; current macro assignment (old
					; current drive)
	I_need	NUMIO,BYTE		; Number of physical drives
	I_need	fSharing,BYTE		; TRUE => no redirection allowed
	I_need	DummyCDS,80h		; buffer for dummy cds
	I_need	DIFFNAM,BYTE		; flag for MyName being set
	I_need	MYNAME,16		; machine name
	I_need	MYNUM,WORD		; machine number
	I_need	DPBHEAD,DWORD		; beginning of DPB chain
	I_need	EXTERR_LOCUS,BYTE	; Extended Error Locus
	I_need	DrvErr,BYTE		; drive error

BREAK <$AssignOper -- Set up a Macro>

; Inputs:
;	AL = 00 get assign mode 		    (ReturnMode)
;	AL = 01 set assign mode 		    (SetMode)
;	AL = 02 get attach list entry		    (GetAsgList)
;	AL = 03 Define Macro (attch start)
;	    BL = Macro type
;	       = 0 alias
;	       = 1 file/device
;	       = 2 drive
;	       = 3 Char device -> network
;	       = 4 File device -> network
;	    DS:SI -> ASCIZ source name
;	    ES:DI -> ASCIZ destination name
;	AL = 04 Cancel Macro
;	    DS:SI -> ASCIZ source name
;	AL = 05 Modified get attach list entry
;	AL = 06 Get ifsfunc item
;	AL = 07 set in_use of a drive's CDS
;	     DL = drive number, 0=default  0=A,,
;	AL = 08 reset in_use of a drive's CDS
;	     DL = drive number, 0=A, 1=B,,,
; Function:
;	Do macro stuff
; Returns:
;	Std Xenix style error return

	procedure   $AssignOper,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	CMP	AL,7				      ; set in_use ?		;AN000;
	JNZ	chk08				      ; no			;AN000;
srinuse:									;AN000;
	PUSH	AX				      ; save al 		;AN000;
	MOV	AL,DL				      ; AL= drive id		;AN000;
	CALL	GetCDSFromDrv			      ; ds:si -> cds		;AN000;
	POP	AX				      ; 			;AN000;
	JC	baddrv				      ; bad drive		;AN000;
	CMP	WORD PTR [SI.curdir_devptr],0	      ; dpb ptr =0 ?		;AN000;
	JZ	baddrv				      ;     no			;AN000;
	CMP	AL,7				      ; set ?			;AN000;
	JNZ	resetdrv			      ; no			;AN000;
	OR	[SI.curdir_flags],curdir_inuse	      ; set in_use		;AN000;
	JMP	SHORT okdone			      ; 			;AN000;
resetdrv:									;AN000;
	AND	[SI.curdir_flags],NOT curdir_inuse    ; reset in_use		;AN000;
	JMP	SHORT okdone			      ; 			;AN000;
baddrv: 									;AN000;
	MOV	AX,error_invalid_drive		      ; error			;AN000;
	JMP	SHORT ASS_ERR			      ; 			;AN000;
chk08:										;AN000;
	CMP	AL,8				      ; reset inuse ?		;AN000;
	JZ	srinuse 			      ; yes			;AN000;

	IF	NOT INSTALLED
	transfer NET_ASSOPER
	ELSE
	PUSH	AX
	MOV	AX,(multnet SHL 8) OR 30
	INT	2FH
	POP	BX			; Don't zap error code in AX
	JC	ASS_ERR
okdone:
	transfer SYS_RET_OK

ASS_ERR:
	transfer SYS_RET_ERR
	ENDIF

EndProc $AssignOper

Break <FIND_DPB - Find a DPB from a drive number>

;   Inputs:	AL has drive number A = 0
;   Outputs:	Carry Set
;		    No DPB for this drive number
;		Carry Clear
;		    DS:SI points to DPB for drive
;   registers modified: DS,SI
Procedure FIND_DPB,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	LDS	SI,[DPBHEAD]
DPB_LOOP:
	CMP	SI,-1
	JZ	NO_DPB
	CMP	AL,[SI.dpb_drive]
	retz				; Carry clear
	LDS	SI,[SI.dpb_next_dpb]
	JMP	DPB_LOOP

NO_DPB:
	STC
	return
EndProc FIND_DPB

Break <InitCDS - set up an empty CDS>

;   Inputs:	ThisCDS points to CDS
;		AL has uppercase drive letter
;   Outputs:	ThisCDS is now empty
;		ES:DI point to CDS
;		Carry set if no DPB associated with drive
;   registers modified: AH,ES,DI
Procedure InitCDS,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	AH,':'
	PUSH	AX
	SUB	AL,"A"-1                ; A = 1
	CMP	[NUMIO],AL
	POP	AX
	LES	DI,[THISCDS]
	MOV	ES:[DI.curdir_flags],0	; "free" CDS
	JB	RET_OK			; Drive does not map a physical drive
	MOV	WORD PTR ES:[DI.curdir_text],AX
	PUSH	AX
	MOV	AX,"\"
	MOV	WORD PTR ES:[DI.curdir_text+2],AX   ; NUL terminate
	POP	AX
	OR	ES:[DI.curdir_flags],curdir_inuse
	MOV	ES:[DI.curdir_END],2	; MZ 3 Nov 83
	MOV	ES:[DI.curdir_ID],0
	MOV	ES:[DI.curdir_ID+2],0
	PUSH	AX
	PUSH	DS
	PUSH	SI
	SUB	AL,"A"                  ; A = 0
	invoke	FIND_DPB
	JC	PRET			; OOOOPPPPPSSSS!!!!
	MOV	WORD PTR ES:[DI.curdir_devptr],SI
	MOV	WORD PTR ES:[DI.curdir_devptr+2],DS
PRET:
	POP	SI
	POP	DS
	POP	AX
RET_OK: return
EndProc InitCDS

Break <$UserOper - get/set current user ID (for net)>

;
;   $UserOper - retrieve or initiate a user id string.	MSDOS will only
;	maintain this string and do no verifications.
;
;   Inputs:	AL has function type (0-get 1-set 2-printer-set 3-printer-get
;				      4-printer-set-flags,5-printer-get-flags)
;		DS:DX is user string pointer (calls 1,2)
;		ES:DI is user buffer (call 3)
;		BX is assign index (calls 2,3,4,5)
;		CX is user number (call 1)
;		DX is flag word (call 4)
;   Outputs:	If AL = 0 then the current user string is written to DS:DX
;			and user CX is set to the user number
;		If AL = 3 then CX bytes have been put at input ES:DI
;		If AL = 5 then DX is flag word

Procedure   $UserOper,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	PUSH	AX
	SUB	AL,1			; quick dispatch on 0,1
	POP	AX
	JB	UserGet 		; return to user the string
	JZ	UserSet 		; set the current user
	CMP	AL,5			; test for 2,3,4 or 5
	JBE	UserPrint		; yep
	MOV	EXTERR_LOCUS,errLoc_Unk ; Extended Error Locus
	error	error_Invalid_Function	; not 0,1,2,3

UserGet:
; Transfer MYNAME to DS:DX
; Set Return CX to MYNUM
	PUSH	DS			; switch registers
	POP	ES
	MOV	DI,DX			; destination
	MOV	CX,[MYNUM]		; Get number
	invoke	get_user_stack
	MOV	[SI.User_CX],CX 	; Set number return
	Context DS			; point to DOSGroup
ASSUME	DS:DOSGROUP
	MOV	SI,OFFSET DOSGroup:MyName   ; point source to user string
UserMove:
ASSUME	DS:NOTHING
	MOV	CX,15
	REP	MOVSB			; blam.
	XOR	AX,AX			; 16th byte is 0
	STOSB
UserBye:
	transfer    sys_ret_ok		; no errors here

UserSet:
ASSUME	DS:NOTHING
; Transfer DS:DX to MYNAME
; CX to MYNUM
	MOV	[MYNUM],CX
	MOV	SI,DX			; user space has source
	Context ES
	MOV	DI,OFFSET DOSGroup:MyName   ; point dest to user string
	INC	[DiffNam]		  ; signal change
	JMP	UserMove

UserPrint:
	ASSUME	ES:NOTHING
IF NOT Installed
	transfer PRINTER_GETSET_STRING
ELSE
	PUSH	AX
	MOV	AX,(multNET SHL 8) OR 31
	INT	2FH
	POP	DX			; Clean stack
	JNC	OKPA
	transfer SYS_RET_ERR

OKPA:
	transfer SYS_RET_OK
ENDIF

EndProc $UserOper

Break	<GetVisDrv - return visible drive>

;
;   GetVisDrv - correctly map non-spliced inuse drives
;
;   Inputs:	AL has drive identifier (0=default)
;   Outputs:	Carry Set - invalid drive/macro
;		Carry Clear - AL has physical drive (0=A)
;		    ThisCDS points to CDS
;   Registers modified: AL

Procedure   GetVisDrv,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	CALL	GetThisDrv		; get inuse drive
	retc
	SaveReg <DS,SI>
	LDS	SI,ThisCDS
	TEST	[SI].curdir_flags,curdir_splice
	RestoreReg  <SI,DS>
	retz				; if not spliced, return OK
	MOV	[DrvErr],error_invalid_drive ;IFS.				;AN000;
	STC				; signal error
	return
EndProc GetVisDrv

Break <Getthisdrv - map a drive designator (0=def, 1=A...)>

;
;   GetThisDrv - look through a set of macros and return the current drive and
;	macro pointer
;
;   Inputs:	AL has drive identifier (1=A, 0=default)
;   Outputs:
;		Carry Set - invalid drive/macro
;		Carry Clear - AL has physical drive (0=A)
;		   ThisCDS points to macro
;   Registers modified: AL

Procedure   GetThisDrv,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	OR	AL,AL			; are we using default drive?
	JNZ	GetMap			; no, go get the CDS pointers
	MOV	AL,[CurDrv]		; get the current drive
	INC	AL			; Counteract next instruction
GetMap:
	DEC	AL			; 0 = A
	SaveReg <DS,SI> 		; save world
	mov	[EXTERR_LOCUS],errLOC_Disk
	TEST	fSharing,-1		; Logical or Physical?
	JZ	Not_SRVC		; Logical
	SaveReg <AX,ES,DI>
	MOV	WORD PTR ThisCDS,OFFSET DOSGroup:DummyCDS
	MOV	WORD PTR ThisCDS+2,CS	;	ThisCDS = &DummyCDS;
	ADD	AL,'A'
	CALL	InitCDS 		;	InitCDS(c);
	TEST	ES:[DI.curdir_flags],curdir_inuse	; Clears carry
	RestoreReg  <DI,ES,AX>
	JZ	GetBerr 		; Not a physical drive.
	JMP	SHORT GetBye		; carry clear

Not_SRVC:
	invoke	GetCDSFromDrv
	JC	GetBerr2		; Unassigned CDS -> return error already set
	TEST	[SI.curdir_flags],curdir_inuse	; Clears Carry
	JNZ	GetBye			; carry clear
GetBerr:
	MOV	AL,error_not_DOS_disk	;AN000;IFS. Formatted IFS drive
	CMP	WORD PTR [SI.curdir_devptr],0	 ;AN000;IFS. dpb ptr =0 ?
	JNZ	notfat			;AN000;IFS. no
GetBerr2:
	MOV	AL,error_invalid_drive	;AN000;;IFS. invalid FAT drive
notfat: 				;AN000;
	MOV	[DrvErr],AL		;AN000;;IFS. save this for IOCTL
	mov	[EXTERR_LOCUS],errLOC_UNK
	STC
GetBye: RestoreReg  <SI,DS>		; restore world
	return
EndProc GetThisDrv

Break <GetCDSFromDrv - convert a drive number to a CDS pointer>

;
;   GetCDSFromDrv - given a physical drive number, convert it to a CDS
;	pointer, returning an error if the drive number is greater than the
;	number of CDS's
;
;   Inputs:	AL is physical unit # A=0...
;   Outputs:	Carry Set if Bad Drive
;		Carry Clear
;		    DS:SI -> CDS
;		    [THISCDS] = DS:SI
;   Registers modified: DS,SI

Procedure   GetCDSFromDrv,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	CMP	AL,[CDSCount]		; is this a valid designator
	JB	GetCDS			; yes, go get the macro
	STC				; signal error
	return				; bye
GetCDS:
	SaveReg <BX,AX>
	LDS	SI,[CDSAddr]		; get pointer to table
	MOV	BL,SIZE CurDir_list	; size in convenient spot
	MUL	BL			; get net offset
	ADD	SI,AX			; convert to true pointer
	MOV	WORD PTR [ThisCDS],SI	; store convenient offset
	MOV	WORD PTR [ThisCDS+2],DS ; store convenient segment
	RestoreReg  <AX,BX>
	CLC				; no error
	return				; bye!
EndProc GetCDSFromDrv

CODE ends
END
