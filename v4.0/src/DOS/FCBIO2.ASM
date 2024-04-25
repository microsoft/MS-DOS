;	SCCSID = @(#)fcbio2.asm 1.2 85/07/23
;	SCCSID = @(#)fcbio2.asm 1.2 85/07/23
TITLE	FCBIO2 - FCB system calls
NAME	FCBIO2

;
; Ancient 1.0 1.1 FCB system calls
;				    regen   save
;   GetRR
;   GetExtent
;   SetExtent
;   GetExtended
;   GetRecSize
;   FCBIO
;   $FCB_OPEN		    written ACC     ACC
;   $FCB_CREATE 	    written ACC     ACC
;   $FCB_RANDOM_WRITE_BLOCK written fcbio   fcbio
;   $FCB_RANDOM_READ_BLOCK  written fcbio   fcbio
;   $FCB_SEQ_READ	    written fcbio   fcbio
;   $FCB_SEQ_WRITE	    written fcbio   fcbio
;   $FCB_RANDOM_READ	    written fcbio   fcbio
;   $FCB_RANDOM_WRITE	    written fcbio   fcbio
;
;   Revision history:
;
;	Created: ARR 4 April 1983
;		 MZ  6 June  1983 completion of functions
;		 MZ 15 Dec   1983 Brain damaged programs close FCBs multiple
;				  times.  Change so successive closes work by
;				  always returning OK.	Also, detect I/O to
;				  already closed FCB and return EOF.
;		 MZ 16 Jan   1984 More braindamage.  Need to separate info
;				  out of sft into FCB for reconnection
;
;	A000	version 4.00  Jan. 1988
;
.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
include version.inc
.cref
.list

	EXTRN	DOS_Read:NEAR, DOS_Write:NEAR
	EXTRN	DOS_Open:NEAR, DOS_Create:NEAR

	I_need	DMAAdd,DWORD		; current user's DMA address
	I_need	OpenBuf,128		; buffer for translating paths
	I_need	ThisSFT,DWORD		; SFT in use
	I_need	sftFCB,DWORD		; pointer to SFTs for FCB cache
	I_need	FCBLRU,WORD		; least recently used count
	I_need	DISK_FULL,BYTE		; flag for disk full
if debug
	I_need	BugLev,WORD
	I_need	BugTyp,WORD
	include bugtyp.asm
endif

IF	BUFFERFLAG

	I_need	BUF_EMS_MODE,BYTE
	I_need	BUF_EMS_LAST_PAGE,DWORD
	I_need	BUF_EMS_FIRST_PAGE,DWORD
	I_need	BUF_EMS_SAFE_FLAG,BYTE
	I_need	BUF_EMS_NPA640,WORD
	I_need	BUF_EMS_PAGE_FRAME,WORD
	I_need	BUF_EMS_PFRAME,WORD
	I_need	LASTBUFFER,DWORD

	extrn	restore_user_map:near
	extrn	Setup_EMS_Buffers:near

ENDIF


; Defintions for FCBOp flags

Random	=   2				; random operation
FCBRead =   4				; doing a read
Block	=   8				; doing a block I/O

Break <GetRR - return the random record field in DX:AX>

;
;   GetRR - correctly load DX:AX with the random record field (3 or 4 bytes)
;	from the FCB pointed to by DS:SI
;
;   Inputs:	DS:SI point to an FCB
;		BX has record size
;   Outputs:	DX:AX contain the contents of the random record field
;   Registers modified: none

Procedure   GetRR,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	MOV	AX,WORD PTR [SI.FCB_RR] ; get low order part
	MOV	DX,WORD PTR [SI.FCB_RR+2]   ; get high order part
	CMP	BX,64			; ignore MSB of RR if recsiz > 64
	JB	GetRRBye
	XOR	DH,DH
GetRRBye:
	return
EndProc GetRR

Break <GetExtent - retrieve next location for sequential IO>

;
;   GetExtent - Construct the next record to perform I/O from the EXTENT and
;	NR fields in the FCB.
;
;   Inputs:	DS:SI - point to FCB
;   Outputs:	DX:AX contain the contents of the random record field
;   Registers modified: none

Procedure   GetExtent,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	MOV	AL,[SI.fcb_NR]		; get low order piece
	MOV	DX,[SI.fcb_EXTENT]	; get high order piece
	SHL	AL,1
	SHR	DX,1
	RCR	AL,1			; move low order bit of DL to high order of AH
	MOV	AH,DL
	MOV	DL,DH
	XOR	DH,DH
	return
EndProc GetExtent

Break <SetExtent - update the extent/NR field>

;
;   SetExtent - change the position of an FCB by filling in the extent/NR
;	fields
;
;   Inputs:	DS:SI point to FCB
;		DX:AX is a record location in file
;   Outputs:	Extent/NR fields are filled in
;   Registers modified: CX

Procedure SetExtent,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	SaveReg <AX,DX>
	MOV	CX,AX
	AND	AL,7FH			; next rec field
	MOV	[SI.fcb_NR],AL
	AND	CL,80H			; save upper bit
	SHL	CX,1
	RCL	DX,1			; move high bit of CX to low bit of DX
	MOV	AL,CH
	MOV	AH,DL
	MOV	[SI.fcb_EXTENT],AX	; all done
	RestoreReg  <DX,AX>
	return
EndProc SetExtent

Break <GetExtended - find FCB in potential extended fcb>

;
;   GetExtended - Make DS:SI point to FCB from DS:DX
;
;   Inputs:	DS:DX point to a possible extended FCB
;   Outputs:	DS:SI point to the FCB part
;		zeroflag set if not extended fcb
;   Registers modified: SI

Procedure   GetExtended,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	MOV	SI,DX			; point to Something
	CMP	BYTE PTR DS:[SI],-1	; look for extention
	JNZ	GetBye			; not there
	ADD	SI,7			; point to FCB
GetBye:
	CMP	SI,DX			; set condition codes
	return
EndProc GetExtended

Break <GetRecSize - return in BX the FCB record size>

;
;   GetRecSize - return in BX the record size from the FCB at DS:SI
;
;   Inputs:	DS:SI point to a non-extended FCB
;   Outputs:	BX contains the record size
;   Registers modified: None

Procedure   GetRecSize,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	BX,[SI.fcb_RECSIZ]	; get his record size
	OR	BX,BX			; is it nul?
	retnz
	MOV	BX,128			; use default size
	MOV	[SI.fcb_RECSIZ],BX	; stuff it back
	return
EndProc GetRecSize

BREAK <FCBIO - do internal FCB I/O>

;
;   FCBIO - look at FCBOP and merge all FCB operations into a single routine.
;
;   Inputs:	FCBOP flags which operations need to be performed
;		DS:DX point to FCB
;		CX may have count of number of records to xfer
;   Outputs:	AL has error code
;   Registers modified: all

Procedure   FCBIO,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
PUBLIC FCBIO001S,FCBIO001E
FCBIO001S:
	LocalVar    FCBErr,BYTE
	LocalVar    cRec,WORD
	LocalVar    RecPos,DWORD
	LocalVar    RecSize,WORD
	LocalVar    bPos,DWORD
	LocalVar    cByte,WORD
	LocalVar    cResult,WORD
	LocalVar    cRecRes,WORD
	LocalVar    FCBOp,BYTE
FCBIO001E:
	Enter

FEOF	EQU	1
FTRIM	EQU	2
	MOV	FCBOp,AL
	MOV	FCBErr,0		;   FCBErr = 0;
	invoke	GetExtended		;   FCB = GetExtended ();
	TEST	FCBOp,BLOCK		;   if ((OP&BLOCK) == 0)
	JNZ	GetPos
	MOV	CX,1			;	cRec = 1;
GetPos:
	MOV	cRec,CX 		;*Tail coalesce
	invoke	GetExtent		;   RecPos = GetExtent ();
	invoke	GetRecSize		;   RecSize = GetRecSize ();
	MOV	RecSize,BX
	TEST	FCBOp,RANDOM		;   if ((OP&RANDOM) <> 0)
	JZ	GetRec
	invoke	GetRR			;	RecPos = GetRR ();
GetRec:
	MOV	RecPosL,AX		;*Tail coalesce
	MOV	RecPosH,DX
	invoke	SetExtent		;   SetExtent (RecPos);
	MOV	AX,RecPosH		;   bPos = RecPos * RecSize;
	MUL	BX
	MOV	DI,AX
	MOV	AX,RecPosL
	MUL	BX
	ADD	DX,DI
	MOV	bPosL,AX
	MOV	bPosH,DX
	MOV	AX,cRec 		;   cByte = cRec * RecSize;
	MUL	BX
	MOV	cByte,AX
	ADD	AX,WORD PTR DMAAdd	;   if (cByte+DMA > 64K) {
	ADC	DX,0
	JZ	DoOper
	MOV	FCBErr,FTRIM		;	FCBErr = FTRIM;
	MOV	AX,WORD PTR DMAAdd	;	cRec = (64K-DMA)/RecSize;
	NEG	AX
	JNZ	DoDiv
	DEC	AX
DoDiv:
	XOR	DX,DX
	DIV	BX
	MOV	cRec,AX
	MUL	BX			;	cByte = cRec * RecSize;
	MOV	cByte,AX		;	}
DoOper:
	XOR	BX,BX
	MOV	cResult,BX		;   cResult = 0;
	CMP	cByte,BX		;   if (cByte <> 0 ||
	JNZ	DoGetExt
	TEST	FCBErr,FTRIM		;	(FCBErr&FTRIM) == 0) {
IF debug
	JZ	DoGetExt
	JMP	SkipOp
ELSE
	JZ	SKP_SkipOp
	JMP	SkipOp
SKP_SkipOp:
ENDIF
DoGetExt:
	invoke	SFTFromFCB		;	if (!SFTFromFCB (SFT,FCB))
	JNC	ContinueOp
FCBDeath:
	invoke	FCB_Ret_Err		; signal error, map for extended
	MOV	cRecRes,0		; no bytes transferred
	MOV	FCBErr,FEOF		;	    return FTRIM;
	JMP	FCBSave 		; bam!
ContinueOp:
	Assert	ISSFT,<ES,DI>,"ContinueOP"
	MOV	AX,WORD PTR [SI].fcb_filsiz
	MOV	WORD PTR ES:[DI].sf_size,AX
	MOV	AX,WORD PTR [SI].fcb_filsiz+2
	MOV	WORD PTR ES:[DI].sf_size+2,AX
	MOV	AX,bPosL
	MOV	DX,bPosH
	MOV	WORD PTR ES:[DI.sf_position],AX
	XCHG	WORD PTR ES:[DI.sf_position+2],DX
	PUSH	DX			; save away Open age.
	MOV	CX,cByte		;	cResult =

;	int	3

	MOV	DI,OFFSET DOSGroup:DOS_Read ;	    *(OP&FCBRead ? DOS_Read
	TEST	FCBOp,FCBRead		;			 : DOS_Write)(cRec);
	JNZ	DoContext
	MOV	DI,OFFSET DOSGroup:DOS_Write
DoContext:
	SaveReg <BP,DS,SI>
	Context DS
;; Fix for disk full
	CALL	DI
	RestoreReg  <SI,DS,BP>
	ASSUME	DS:NOTHING

IF	BUFFERFLAG
	pushf
	push	ax
	push	bx

	cmp	cs:[BUF_EMS_MODE], -1
	jz	dos_fcb_call_done
	call	restore_user_map
	mov	ax, word ptr cs:[BUF_EMS_LAST_PAGE]
	cmp	cs:[BUF_EMS_PFRAME], ax
	je	dos_fcb_call_done
	mov	word ptr cs:[LASTBUFFER], -1
	mov	cs:[BUF_EMS_PFRAME], ax
	mov	ax, word ptr cs:[BUF_EMS_LAST_PAGE+2]
	mov	cs:[BUF_EMS_PAGE_FRAME], ax
	mov	cs:[BUF_EMS_SAFE_FLAG], 1
	call	Setup_EMS_Buffers

dos_fcb_call_done:
	pop	bx
	pop	ax
	popf
ENDIF

	JC	FCBDeath

	CMP	BYTE PTR [DISK_FULL],0	; treat disk full as error
	JZ	NODSKFULL
	MOV	BYTE PTR [DISK_FULL],0	; clear the flag
	MOV	FCBerr,FEOF		; set disk full flag
NODSKFULL:
;; Fix for disk full
	MOV	cResult,CX
	invoke	SaveFCBInfo		;	SaveFCBInfo (FCB);
	Assert	ISSFT,<ES,DI>,"FCBIO/SaveFCBInfo"
%out WARNING!!! Make sure sf_position+2 is OpenAGE
	POP	WORD PTR ES:[DI].sf_Position+2	; restore open age
	MOV	AX,WORD PTR ES:[DI].sf_size
	MOV	WORD PTR [SI].fcb_filsiz,AX
	MOV	AX,WORD PTR ES:[DI].sf_size+2
	MOV	WORD PTR [SI].fcb_filsiz+2,AX
					;	}
SkipOp:
	MOV	AX,cResult		;   cRecRes = cResult / RecSize;
	XOR	DX,DX
	DIV	RecSize
	MOV	cRecRes,AX
	ADD	RecPosL,AX		;   RecPos += cRecResult;
	ADC	RecPosH,0
;
; If we have not gotten the expected number of records, we signal an EOF
; condition.  On input, this is EOF.  On output this is usually disk full.
; BUT...  Under 2.0 and before, all device output IGNORED this condition.  So
; do we.
;
	CMP	AX,cRec 		;   if (cRecRes <> cRec)
	JZ	TryBlank
	TEST	FCBOp,FCBRead		;	if (OP&FCBRead || !DEVICE)
	JNZ	SetEOF
	TEST	ES:[DI].sf_flags,devid_device
	JNZ	TryBlank
SetEOF:
	MOV	FCBErr,FEOF		;	FCBErr = FEOF;
TryBlank:				;
	OR	DX,DX			;   if (cResult%RecSize <> 0) {
	JZ	SetExt
	ADD	RecPosL,1		;	RecPos++;
	ADC	RecPosH,0
	TEST	FCBOp,FCBRead		;	if(OP&FCBRead) <> 0) {
	JZ	SetExt
	INC	cRecRes 		;	cRecRes++;
	MOV	FCBErr,FTRIM + FEOF	;	FCBErr = FTRIM | FEOF;
	MOV	CX,RecSize		;	Blank (RecSize-cResult%RecSize,
	SUB	CX,DX			;	       DMA+cResult);
	XOR	AL,AL
	LES	DI,DMAAdd
	ADD	DI,cResult
	REP	STOSB			;   }	}
SetExt:
	MOV	DX,RecPosH
	MOV	AX,RecPosL
	TEST	FCBOp,RANDOM		;   if ((OP&Random) == 0 ||
	JZ	DoSetExt
	TEST	FCBOp,BLOCK		;	(OP&BLOCK) <> 0)
	JZ	TrySetRR
DoSetExt:
	invoke	SetExtent		;	SetExtent (RecPos, FCB);
TrySetRR:
	TEST	FCBOp,BLOCK		;   if ((op&BLOCK) <> 0)
	JZ	TryReturn
	MOV	WORD PTR [SI.FCB_RR],AX ;	FCB->RR = RecPos;
	MOV	BYTE PTR [SI.FCB_RR+2],DL
	CMP	[SI.fcb_RECSIZ],64
	JAE	TryReturn
	MOV	[SI+fcb_RR+2+1],DH	; Set 4th byte only if record size < 64
TryReturn:
	TEST	FCBOP,FCBRead		;   if (!(FCBOP & FCBREAD)) {
	JNZ	FCBSave
	SaveReg <DS>			;	FCB->FDate = date;
	Invoke	Date16			;	FCB->FTime = time;
	RestoreReg  <DS>
	MOV	[SI].FCB_FDate,AX
	MOV	[SI].FCB_FTime,DX	;	}
FCBSave:
	TEST	FCBOp,BLOCK		;   if ((op&BLOCK) <> 0)
	JZ	DoReturn
	MOV	CX,cRecRes		;	user_CX = cRecRes;
	invoke	Get_User_Stack
	MOV	[SI.User_CX],CX
DoReturn:
	MOV	AL,FCBErr		;   return (FCBERR);
	Leave
	return
EndProc FCBIO

Break <$FCB_Open - open an old-style FCB>

;
;   $FCB_Open - CPM compatability file open.  The user has formatted an FCB
;	for us and asked to have the rest filled in.
;
;   Inputs:	DS:DX point to an unopenned FCB
;   Outputs:	AL indicates status 0 is ok FF is error
;		FCB has the following fields filled in:
;		    Time/Date Extent/NR Size

Procedure $FCB_Open,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	MOV	AX,sharing_Compat+Open_For_Both
	MOV	CX,OFFSET DOSGroup:DOS_Open
;
; The following is common code for Creation and openning of FCBs.  AX is
; either attributes (for create) or open mode (for open)...  DS:DX points to
; the FCB
;
DoAccess:
	SaveReg <DS,DX,CX,AX>		; save FCB pointer away
	MOV	DI,OFFSET DOSGroup:OpenBuf
	invoke	TransFCB		; crunch the fcb
	RestoreReg  <AX,CX,DX,DS>	; get fcb
	JNC	FindFCB 		; everything seems ok
FCBOpenErr:
;
; AL has error code
;
	transfer    FCB_Ret_Err
FindFCB:
	invoke	GetExtended		; DS:SI will point to FCB
	invoke	LRUFCB			; get a sft entry (no error)
	JC	HardMessage
	ASSUME	ES:NOTHING

;	Message 1,"Entering "
;	MessageNum  ES
;	Message 1,":"
;	MessageNum  DI
;	Message 1,<13,10>

	MOV	ES:[DI].sf_mode,sf_ISFCB
	SaveReg <DS,SI,BX>		; save fcb pointer
	MOV	SI,CX
	Context DS			; let DOS_Open see variables
	CALL	SI			; go open the file
	RestoreReg  <BX,SI,DS>		; get fcb
	ASSUME	DS:NOTHING
	LES	DI,ThisSFT		; get sf pointer
	JNC	FCBOK			; operation succeeded
	Assert	ISSFT,<ES,DI>,"DeadFCB"
failopen:
	PUSH	AX
	MOV	AL,"R"                  ; clear out field (free sft)
	invoke	BlastSFT
	POP	AX
	CMP	AX,error_too_many_open_files
	JZ	HardMessage
	CMP	AX,error_sharing_buffer_exceeded
	jnz	DeadFCB
HardMessage:
	PUSH	AX
	invoke	FCBHardErr
	POP	AX
DeadFCB:
	transfer    FCB_Ret_Err
FCBOK:
	invoke	IsSFTNet		       ;AN007;F.C. >32mb  Non Fat file?
	JNZ	FCBOK2			       ;AN007;F.C. >32mb  yes
	invoke	CheckShare		       ;AN000;F.C. >32mb  share around?
	JNZ	FCBOK2			       ;AN000;F.C. >32mb  yes
	CMP	WORD PTR ES:[DI].sf_dirsec+2,0 ;AN000;F.C. >32mb  if dirsec >32mb
	JZ	FCBOK2			       ;AN000;F.C. >32mb    then error
	MOV	AX,error_sys_comp_not_loaded   ;AN000;F.C. >32mb
	JMP	failopen		       ;AN000;F.C. >32mb
FCBOK2:

	INC	ES:[DI].sf_ref_count	; increment reference count
	invoke	SaveFCBInfo
	Assert	ISSFT,<ES,DI>,"FCBOK"
	invoke	SetOpenAge
	Assert	ISSFT,<ES,DI>,"FCBOK/SetOpenAge"
	TEST	ES:[DI].sf_flags,devid_device
	JNZ	FCBNoDrive		; do not munge drive on devices
	MOV	AL,DS:[SI]		; get drive byte
	invoke	GetThisDrv		; convert
	INC	AL
	MOV	DS:[SI],AL		; stash in good drive letter
FCBNoDrive:
	MOV	[SI].FCB_RecSiz,80h	; stuff in default record size
	MOV	AX,ES:[DI].SF_Time	; set time
	MOV	[SI].FCB_FTime,AX
	MOV	AX,ES:[DI].SF_Date	; set date
	MOV	[SI].FCB_FDate,AX
	MOV	AX,WORD PTR ES:[DI].SF_Size ; set sizes
	MOV	[SI].FCB_FILSIZ,AX
	MOV	AX,WORD PTR ES:[DI].SF_Size+2
	MOV	[SI].FCB_FILSIZ+2,AX
	XOR	AX,AX			; convenient zero
	MOV	[SI].FCB_Extent,AX	; point to beginning of file
;
; We must scan the set of FCB SFTs for one that appears to match the current
; one.	We cheat and use CheckFCB to match the FCBs.
;
	LES	DI,SFTFCB		; get the pointer to head of the list
	MOV	AH,BYTE PTR ES:[DI].sfCount ; get number of SFTs to scan
OpenScan:
	CMP	AL,[SI].fcb_sfn 	; don't compare ourselves
	JZ	SkipCheck
	SaveReg <AX>			; preserve count
	invoke	CheckFCB		; do they match
	RestoreReg  <AX>		; get count back
	JNC	OpenFound		; found a match!
SkipCheck:
	INC	AL			; advance to next FCB
	CMP	AL,AH			; table full?
	JNZ	OpenScan		; no, go for more
OpenDone:
	xor	al,al			; return success
	return
;
; The SFT at ES:DI is the one that is already in use for this FCB.  We set the
; FCB to use this one.	We increment its ref count.  We do NOT close it at all.
; Consider:
;
;   open (foo)	delete (foo) open (bar)
;
; This causes us to recycle (potentially) bar through the same local SFT as
; foo even though foo is no longer needed; this is due to the server closing
; foo for us when we delete it.  Unfortunately, we cannot see this closure.
; If we were to CLOSE bar, the server would then close the only reference to
; bar and subsequent I/O would be lost to the redirector.
;
; This gets solved by NOT closing the sft, but zeroing the ref count
; (effectively freeing the SFT) and informing the sharer (if relevant) that
; the SFT is no longer in use.	Note that the SHARER MUST keep its ref counts
; around.  This will allow us to access the same file through multiple network
; connections and NOT prematurely terminate when the ref count on one
; connection goes to zero.
;
OpenFound:
	MOV	[SI].fcb_SFN,AL 	; assign with this
	INC	ES:[DI].sf_ref_count	; remember this new invocation
	MOV	AX,FCBLRU		; update LRU counts
	MOV	ES:[DI].sf_LRU,AX
;
; We have an FCB sft that is now of no use.  We release sharing info and then
; blast it to prevent other reuse.
;
	context DS
	LES	DI,ThisSFT
	DEC	ES:[DI].sf_ref_count	; free the newly allocated SFT
	invoke	ShareEnd
	Assert	ISSFT,<ES,DI>,"Open blasting"
	MOV	AL,'C'
	invoke	BlastSFT
	JMP	OpenDone
EndProc $FCB_Open

BREAK	<$FCB_Create - create a new directory entry>

;
;   $FCB_Create - CPM compatability file create.  The user has formatted an
;	FCB for us and asked to have the rest filled in.
;
;   Inputs:	DS:DX point to an unopenned FCB
;   Outputs:	AL indicates status 0 is ok FF is error
;		FCB has the following fields filled in:
;		    Time/Date Extent/NR Size

Procedure $FCB_Create,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	CX,OFFSET DOSGroup:DOS_Create	; routine to call
	XOR	AX,AX			; attributes to create
	invoke	GetExtended		; get extended FCB
	JZ	DoAccessJ		; not an extended FCB
	MOV	AL,[SI-1]		; get attributes
DoAccessJ:
	JMP	DoAccess		; do dirty work
EndProc $FCB_Create

BREAK <$FCB_Random_write_Block - write a block of records to a file >

;
;   $FCB_Random_Write_Block - retrieve a location from the FCB, seek to it
;	and write a number of blocks from it.
;
;   Inputs:	DS:DX point to an FCB
;   Outputs:	AL = 0 write was successful and the FCB position is updated
;		AL <> 0 Not enough room on disk for the output
;

Procedure $FCB_Random_Write_Block,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	AL,Random+Block
	JMP	FCBIO
EndProc $FCB_Random_Write_Block

BREAK <$FCB_Random_Read_Block - read a block of records to a file >

;
;   $FCB_Random_Read_Block - retrieve a location from the FCB, seek to it
;	and read a number of blocks from it.
;
;   Inputs:	DS:DX point to an FCB
;   Outputs:	AL = error codes defined above
;

Procedure $FCB_Random_Read_Block,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	AL,Random+FCBRead+Block
	JMP	FCBIO
EndProc $FCB_Random_Read_Block

BREAK <$FCB_Seq_Read - read the next record from a file >

;
;   $FCB_Seq_Read - retrieve the next record from an FCB and read it into
;	memory
;
;   Inputs:	DS:DX point to an FCB
;   Outputs:	AL = error codes defined above
;

Procedure $FCB_Seq_Read,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	AL,FCBRead
	JMP	FCBIO
EndProc $FCB_Seq_Read

BREAK <$FCB_Seq_Write - write the next record to a file >

;
;   $FCB_Seq_Write - retrieve the next record from an FCB and write it to the
;	file
;
;   Inputs:	DS:DX point to an FCB
;   Outputs:	AL = error codes defined above
;

Procedure $FCB_Seq_Write,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	AL,0
	jmp	FCBIO
EndProc $FCB_SEQ_WRITE

BREAK <$FCB_Random_Read - Read a single record from a file >

;
;   $FCB_Random_Read - retrieve a location from the FCB, seek to it and read a
;	record from it.
;
;   Inputs:	DS:DX point to an FCB
;   Outputs:	AL = error codes defined above
;

Procedure $FCB_Random_Read,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	AL,Random+FCBRead
	jmp	FCBIO			; single block
EndProc $FCB_RANDOM_READ

BREAK <$FCB_Random_Write - write a single record to a file >

;
;   $FCB_Random_Write - retrieve a location from the FCB, seek to it and write
;	a record to it.
;
;   Inputs:	DS:DX point to an FCB
;   Outputs:	AL = error codes defined above
;

Procedure $FCB_Random_Write,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	AL,Random
	jmp	FCBIO
EndProc $FCB_RANDOM_WRITE

CODE ENDS
END

