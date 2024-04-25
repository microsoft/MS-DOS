;	SCCSID = @(#)dir.asm	1.1 85/04/10
;	SCCSID = @(#)dir.asm	1.1 85/04/10
TITLE	DIR - Directory and path cracking
NAME	Dir
; Main Path cracking routines, low level search routines
;
;   FindEntry
;   SEARCH
;   Srch
;   NEXTENT
;   MetaCompare
;   NEXTENTRY
;   GETENTRY
;   GETENT
;   SETDIRSRCH
;   SETROOTSRCH
;
;   Revision history:
;
;	A000   version 4.00    Jan. 1988
;

;
; get the appropriate segment definitions
;
.xlist
include dosseg.asm
include fastopen.inc

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xcref
include dossym.inc
.cref
.list

asmvar	Kanji

	i_need	EntFree,WORD
	i_need	DirStart,WORD
	i_need	LastEnt,WORD
	i_need	ClusNum,WORD
	i_need	CurBuf,DWORD
	i_need	Attrib,BYTE
	i_need	DelAll,BYTE
	i_need	VolID,BYTE
	i_need	Name1,BYTE
	i_need	ThisDPB,DWORD
	i_need	EntLast,WORD
	i_need	Creating,BYTE
	i_need	SecClusPos,BYTE
	i_need	ClusFac,BYTE
	i_need	NxtClusNum,WORD
	i_need	DirSec,DWORD			;AN000;
	I_need	FastOpenFlg,BYTE		;AN000;
	I_need	HIGH_SECTOR,WORD		;AN000;

Break	<FINDENTRY -- LOOK FOR AN ENTRY>

; Inputs:
;	[THISDPB] set
;	[SECCLUSPOS] = 0
;	[DIRSEC] = Starting directory sector number
;	[CLUSNUM] = Next cluster of directory
;	[CLUSFAC] = Sectors/Cluster
;	[NAME1] = Name to look for
; Function:
;	Find file name in disk directory.
;	"?" matches any character.
; Outputs:
;	Carry set if name not found
;	ELSE
;	Zero set if attributes match (always except when creating)
;	AH = Device ID (bit 7 set if not disk)
;	[THISDPB] = Base of drive parameters
;	DS = DOSGROUP
;	ES = DOSGROUP
;	[CURBUF+2]:BX = Pointer into directory buffer
;	[CURBUF+2]:SI = Pointer to First Cluster field in directory entry
;	[CURBUF] has directory record with match
;	[NAME1] has file name
;	[LASTENT] is entry number of the entry
; All other registers destroyed.

	procedure   SEARCH,near

	entry	FindEntry
	DOSAssume   CS,<DS>,"FindEntry"
	ASSUME	ES:NOTHING

	invoke	STARTSRCH
	MOV	AL,Attrib
	AND	AL,NOT attr_ignore	; Ignore useless bits
	CMP	AL,attr_volume_id	; Looking for vol ID only ?
	JNZ	NOTVOLSRCH		; No
	CALL	SETROOTSRCH		; Yes force search of root
NOTVOLSRCH:
	CALL	GETENTRY
	JNC	Srch
	JMP	SETESRET

	entry	Srch

	PUSH	DS
	MOV	DS,WORD PTR [CURBUF+2]
ASSUME	DS:NOTHING
	MOV	AH,BYTE PTR [BX]
	OR	AH,AH			; End of directory?
	JZ	FREE
	CMP	AH,BYTE PTR [DELALL]	; Free entry?
	JZ	FREE
	TEST	BYTE PTR [BX+11],attr_volume_id
					; Volume ID file?
	JZ	CHKFNAM 		; NO
	INC	BYTE PTR [VOLID]
CHKFNAM:
;	Context ES
	ASSUME	ES:DOSGroup
	MOV	SI,SS
	MOV	ES,SI
	MOV	SI,BX
	MOV	DI,OFFSET DOSGROUP:NAME1
;;;;; 7/29/86
	CMP	BYTE PTR [NAME1],0E5H	 ; special char check
	JNZ	NO_E5
	MOV	BYTE PTR [NAME1],05H
NO_E5:
;;;;; 7/29/86
	CALL	MetaCompare
	JZ	FOUND
	POP	DS

	entry	NEXTENT
	DOSAssume   CS,<DS>,"NextEnt"

	Assert	ISDPB,<<WORD PTR THISDPB+2>,<WORD PTR THISDPB>>,"NextEnt"
	LES	BP,[THISDPB]
ASSUME	ES:NOTHING
	CALL	NEXTENTRY
	JNC	SRCH
	JMP	SHORT SETESRET

FREE:
	POP	DS
	DOSAssume   CS,<DS>,"DIR/Free"
	MOV	CX,[LASTENT]
	CMP	CX,[ENTFREE]
	JAE	TSTALL
	MOV	[ENTFREE],CX
TSTALL:
	CMP	AH,BYTE PTR [DELALL]	; At end of directory?
NextEntJ:
	JZ	NEXTENT 		; No - continue search
	MOV	[ENTLAST],CX
	STC
	JMP	SHORT SETESRET

FOUND:
;
; We have a file with a matching name.	We must now consider the attributes:
; ATTRIB	Action
; ------	------
; Volume_ID	Is Volume_ID in test?
; Otherwise	If no create then Is ATTRIB+extra superset of test?
;		If create then Is ATTRIB equal to test?
;
	MOV	CH,[SI] 		; Attributes of file
	POP	DS
	DOSAssume   CS,<DS>,"DIR/found"
	MOV	AH,Attrib		; Attributes of search
	AND	AH,NOT attr_ignore
	LEA	SI,[SI+Dir_First-Dir_Attr]  ; point to firclus field
	TEST	CH,attr_volume_id	; Volume ID file?
	JZ	check_one_volume_id	; Nope check other attributes
	TEST	AH,attr_volume_id	; Can we find Volume ID?
	JZ	NEXTENTJ		; Nope, (not even $FCB_CREATE)
	XOR	AH,AH			; Set zero flag for $FCB_CREATE
	JMP	SHORT RETFF		; Found Volume ID
check_one_volume_id:
	CMP	AH,attr_volume_id	; Looking only for Volume ID?
	JZ	NEXTENTJ		; Yes, continue search
	invoke	MatchAttributes
	JZ	RETFF
	TEST	BYTE PTR [CREATING],-1	; Pass back mismatch if creating
	JZ	NEXTENTJ		; Otherwise continue searching
RETFF:
	LES	BP,[THISDPB]
	MOV	AH,ES:[BP.dpb_drive]
SETESRET:
	PUSH	SS
	POP	ES
	return
EndProc Search

; Inputs:
;	DS:SI -> 11 character FCB style name NO '?'
;	    Typically this is a directory entry.  It MUST be in upper case
;	ES:DI -> 11 character FCB style name with possible '?'
;	    Typically this is a FCB or SFT.  It MUST be in upper case
; Function:
;	Compare FCB style names allowing for ? match to any char
; Outputs:
;	Zero if match else NZ
; Destroys CX,SI,DI all others preserved

	procedure   MetaCompare,near
ASSUME	DS:NOTHING,ES:NOTHING
	MOV	CX,11
 IF  DBCS				;AN000;
;-------------------- Start of DBCS	;AN000;
	CMP	BYTE PTR DS:[SI],05H	;AN000;; Special case for lead byte of 05h
	JNE	WILDCRD2		;AN000;; Compare as normal if not an 05h
	CMP	BYTE PTR ES:[DI],0E5H	;AN000;; 05h and 0E5h equivalent for lead byte
	JNE	WILDCRD2		;AN000;; Compare as normal if not an 05h
	DEC	CX			;AN000;; One less byte to compare
	INC	SI			;AN000;; Bypass lead byte in source and
	INC	DI			;AN000;;  destination when 05h and 0E5h found.
WILDCRD2:				;AN000;
	PUSH	AX			;AN000;;KK. save ax
cagain: 				;AN000;;KK.
	CMP	CX,0			;AN000;;KK. end of compare ?
	JLE	metaend2		;AN000;;KK. yes
	MOV	AL,[SI] 		;AN000;;KK. is it a Kanji
	invoke	testkanj		;AN000;;KK.
	JZ	notdb			;AN000;;KK. no
	MOV	AX,'??'                 ;AN000;;KK.
	CMP	ES:[DI],AX		;AN000;;KK. is es:di pointing to '??'
	JNZ	metaend3		;AN000;;KK. no
	ADD	SI,2			;AN000;;KK.
	ADD	DI,2			;AN000;;KK. update pointers and count
subcx:					;AN000;
	SUB	CX,2			;AN000;;KK.
	JMP	cagain			;AN000;;KK.
metaend3:				;AN000;;KK.
	CMPSW				;AN000;;KK.
	JNZ	metaend2		;AN000;;KK.
	JMP	subcx			;AN000;;KK.
notdb:					;AN000;
	CMPSB				;AN000;;KK. same code ?
	JZ	sameco			;AN000;;KK. yes
	CMP	BYTE PTR ES:[DI-1],"?"  ;AN000;;KK. ?
	JNZ	metaend2		;AN000;;KK. no
sameco: 				;AN000;
	DEC	CX			;AN000;;KK. decrement count
	JMP	cagain			;AN000;;KK.

metaend2:				;AN000;
	POP	AX			;AN000;;KK.
;-------------------- End of DBCS	;AN000; KK.
 ELSE					;AN000;
WILDCRD:
	REPE	CMPSB
	JZ	MetaRet 		; most of the time we will fail.
CHECK_META:
	CMP	BYTE PTR ES:[DI-1],"?"
	JZ	WildCrd
MetaRet:
 ENDIF					;AN000;
	return				; Zero set, Match
EndProc MetaCompare

Break	<NEXTENTRY -- STEP THROUGH DIRECTORY>

; Inputs:
;	Same as outputs of GETENTRY, above
; Function:
;	Update BX, and [LASTENT] for next directory entry.
;	Carry set if no more.

Procedure NextEntry
	DOSAssume   CS,<DS>,"NextEntry"
	ASSUME	ES:NOTHING

	MOV	AX,[LASTENT]
	CMP	AX,[ENTLAST]
	JZ	NONE
	INC	AX
	LEA	BX,[BX+32]
	CMP	BX,DX
	JB	HAVIT
	MOV	BL,BYTE PTR [SECCLUSPOS]
	INC	BL
	CMP	BL,BYTE PTR [CLUSFAC]
	JB	SAMECLUS
	MOV	BX,[NXTCLUSNUM]
	Invoke	IsEOF
	JAE	NONE
	CMP	BX,2
	JB	NONE
	JMP	GETENT

NONE:
	STC
	return

HAVIT:
	MOV	[LASTENT],AX
	CLC
	return

SAMECLUS:
	MOV	BYTE PTR [SECCLUSPOS],BL
	MOV	[LASTENT],AX
	PUSH	DS
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	MOV	DX,WORD PTR [DI.buf_sector+2]	;AN000; >32mb
	MOV	[HIGH_SECTOR],DX		;AN000; >32mb
	MOV	DX,WORD PTR [DI.buf_sector]	;AN000; >32mb

	ADD	DX,1				;AN000; >32mb
	ADC	[HIGH_SECTOR],0 		;AN000; >32mb
	POP	DS
	DOSAssume   CS,<DS>,"DIR/SameClus"
	invoke	FIRSTCLUSTER
	XOR	BX,BX
	JMP	SETENTRY
EndProc NextEntry

; Inputs:
;	[LASTENT] has directory entry
;	ES:BP points to drive parameters
;	[DIRSEC],[CLUSNUM],[CLUSFAC],[ENTLAST] set for DIR involved
; Function:
;	Locates directory entry in preparation for search
;	GETENT provides entry for passing desired entry in AX
; Outputs:
;	[CURBUF+2]:BX = Pointer to next directory entry in CURBUF
;	[CURBUF+2]:DX = Pointer to first byte after end of CURBUF
;	[LASTENT] = New directory entry number
;	[NXTCLUSNUM],[SECCLUSPOS] set via DIRREAD
;	Carry set if error (currently user FAILed to I 24)

Procedure GETENTRY,NEAR
	DOSAssume   CS,<DS>,"GetEntry"
	ASSUME	ES:NOTHING

	MOV	AX,[LASTENT]

	entry	GETENT

	Assert	ISDPB,<ES,BP>,"GetEntry/GetEnt"
	MOV	[LASTENT],AX
;
; Convert the entry number in AX into a byte offset from the beginning of the
; directory.
;
	mov	cl,5			; shift left by 5 = mult by 32
	rol	ax,cl			; keep hight order bits
	mov	dx,ax
	and	ax, NOT (32-1)		; mask off high order bits
	and	dx, 32-1		; mask off low order bits
;
; DX:AX contain the byte offset of the required directory entry from the
; beginning of the directory.  Convert this to a sector number.  Round the
; sector size down to a multiple of 32.
;
	MOV	BX,ES:[BP.dpb_sector_size]
	AND	BL,255-31		; Must be multiple of 32
	DIV	BX
	MOV	BX,DX			; Position within sector
	PUSH	BX
	invoke	DIRREAD
	POP	BX
	retc
SETENTRY:
	MOV	DX,WORD PTR [CURBUF]
	ADD	DX,BUFINSIZ
	ADD	BX,DX
	ADD	DX,ES:[BP.dpb_sector_size]  ; Always clears carry
	return
EndProc GetEntry

Break	<SETDIRSRCH SETROOTSRCH -- Set Search environments>

; Inputs:
;	BX cluster number of start of directory
;	ES:BP Points to DPB
;	DI next cluster number from fastopen extended info. DOS 3.3 only
; Function:
;	Set up a directory search
; Outputs:
;	[DIRSTART] = BX
;	[CLUSFAC],[CLUSNUM],[SECCLUSPOS],[DIRSEC] set
;	Carry set if error (currently user FAILed to I 24)
; destroys AX,DX,BX

	procedure SETDIRSRCH
	DOSAssume   CS,<DS>,"SetDirSrch"
	ASSUME	ES:NOTHING

	Assert	ISDPB,<ES,BP>,"SetDirSrch"
	OR	BX,BX
	JZ	SETROOTSRCH
	MOV	[DIRSTART],BX
	MOV	AL,ES:[BP.dpb_cluster_mask]
	INC	AL
	MOV	BYTE PTR [CLUSFAC],AL
; DOS 3.3 for FastOPen	F.C. 6/12/86
	SaveReg <SI>
	TEST	[FastOpenFlg],Lookup_Success
	JNZ	UNP_OK

; DOS 3.3 for FastOPen	F.C. 6/12/86
	invoke	UNPACK
	JNC	UNP_OK
	RestoreReg  <SI>
	return

UNP_OK:
	MOV	[CLUSNUM],DI
	MOV	DX,BX
	XOR	BL,BL
	MOV	BYTE PTR [SECCLUSPOS],BL
	invoke	FIGREC
	RestoreReg  <SI>
	PUSH	DX			   ;AN000; >32mb
	MOV	DX,[HIGH_SECTOR]	   ;AN000; >32mb
	MOV	WORD PTR [DIRSEC+2],DX	   ;AN000; >32mb
	POP	DX			   ;AN000; >32mb
	MOV	WORD PTR [DIRSEC],DX
	CLC
	return

entry	SETROOTSRCH
	DOSAssume   CS,<DS>,"SetRootSrch"
	ASSUME	ES:NOTHING
	XOR	AX,AX
	MOV	[DIRSTART],AX
	MOV	BYTE PTR [SECCLUSPOS],AL
	DEC	AX
	MOV	[CLUSNUM],AX
	MOV	AX,ES:[BP.dpb_first_sector]
	MOV	DX,ES:[BP.dpb_dir_sector]
	SUB	AX,DX
	MOV	BYTE PTR [CLUSFAC],AL
	MOV	WORD PTR [DIRSEC],DX		      ;F.C. >32mb
	MOV	WORD PTR [DIRSEC+2],0		      ;F.C. >32mb
	CLC
	return
EndProc SETDIRSRCH

CODE	ENDS
    END
