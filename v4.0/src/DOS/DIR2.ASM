;	SCCSID = @(#)dir2.asm	1.2 85/07/23
;	SCCSID = @(#)dir2.asm	1.2 85/07/23
TITLE	DIR2 - Directory and path cracking
NAME	Dir2
; Main Path cracking routines, low level search routines and device
;   name detection routines
;
;   GETPATH
;   GetPathNoSet
;   CHKDEV
;   ROOTPATH
;   FINDPATH
;   StartSrch
;   MatchAttributes
;   DEVNAME
;   Build_device_ent
;   Validate_CDS
;   CheckThisDevice
;
;   Revision history:
;
;	A000  version 4.00  Jan. 1988
;	A001  PTM 3564 -- search using fastopen

;
; get the appropriate segment definitions
;
.xlist
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xcref
include dossym.inc
include devsym.inc
include fastopen.inc		       ;DOS 3.3
.cref
.list

asmvar	Kanji

	i_need	NoSetDir,BYTE
	i_need	EntFree,WORD
	i_need	DirStart,WORD
	i_need	LastEnt,WORD
	i_need	WFP_START,WORD
	i_need	CURR_DIR_END,WORD
	i_need	CurBuf,DWORD
	i_need	THISCDS,DWORD
	i_need	Attrib,BYTE
	i_need	SAttrib,BYTE
	i_need	VolID,BYTE
	i_need	Name1,BYTE
	i_need	ThisDPB,DWORD
	i_need	EntLast,WORD
	i_need	Creating,BYTE
	i_need	NULDEV,DWORD
	i_need	DEVPT,DWORD
	i_need	DEVFCB,BYTE
	i_need	ALLOWED,BYTE
	i_need	EXTERR_LOCUS,BYTE
	I_need	FastOpenFlg,BYTE	  ;DOS 3.3
	I_need	FastOpenTable,BYTE	  ;DOS 3.3
	I_need	Dir_Info_Buff,BYTE	  ;DOS 3.3
	I_need	FastOpen_Ext_Info,BYTE	  ;DOS 3.3
	I_need	CLUSNUM,WORD		  ;DOS 3.3
	I_need	Next_Element_Start,WORD   ;DOS 3.3
	I_need	HIGH_SECTOR,WORD	  ;AN000;>32mb
	I_need	DOS34_FLAG,WORD 	  ;AN000;>32mb


Break	<GETPATH -- PARSE A WFP>

; Inputs:
;	[WFP_START] Points to WFP string ("d:\" must be first 3 chars, NUL
;		terminated; d:/ (note forward slash) indicates a real device).
;	[CURR_DIR_END] Points to end of Current dir part of string
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[THISCDS] Points to CDS being used
;	[SATTRIB] Is attribute of search, determines what files can be found
;	[NoSetDir] set
;	[THISDPB] set to DPB if disk otherwise garbage.
; Function:
;	Crack the path
; Outputs:
;	Sets EXTERR_LOCUS = errLOC_Disk if disk file
;	Sets EXTERR_LOCUS = errLOC_Unk if char device
;	ID1 field of [THISCDS] updated appropriately
;	[ATTRIB] = [SATTRIB]
;	ES:BP Points to DPB
;	Carry set if bad path
;	   SI Points to path element causing failure
;	   Zero set
;	      [DIRSTART],[DIRSEC],[CLUSNUM], and [CLUSFAC] are set up to
;	      start a search on the last directory
;	      CL is zero if there is a bad name in the path
;	      CL is non-zero if the name was simply not found
;		 [ENTFREE] may have free spot in directory
;		 [NAME1] is the name.
;		 CL = 81H if '*'s or '?' in NAME1, 80H otherwise
;	   Zero reset
;	      File in middle of path or bad name in path or attribute mismatch
;		or path too long or malformed path
;	ELSE
;	   [CurBuf] = -1 if root directory
;	   [CURBUF] contains directory record with match
;	   [CURBUF+2]:BX Points into [CURBUF] to start of entry
;	   [CURBUF+2]:SI Points into [CURBUF] to dir_first field for entry
;	   AH = device ID
;	      bit 7 of AH set if device SI and BX
;	      will point DOSGROUP relative The firclus
;	      field of the device entry contains the device pointer
;	   [NAME1] Has name looked for
;	   If last element is a directory zero is set and:
;	      [DIRSTART],[SECCLUSPOS],[DIRSEC],[CLUSNUM], and [CLUSFAC]
;	      are set up to start a search on it.
;	      unless [NoSetDir] is non zero in which case the return is
;	      like that for a file (except for zero flag)
;	   If last element is a file zero is reset
;	      [DIRSEC],[CLUSNUM],[CLUSFAC],[NXTCLUSNUM],[SECCLUSPOS],
;	      [LASTENT], [ENTLAST] are set to continue search of last
;	      directory for furthur matches on NAME1 via the NEXTENT
;	      entry point in FindEntry (or GETENT entry in GETENTRY in
;	      which case [NXTCLUSNUM] and [SECCLUSPOS] need not be valid)
; DS preserved, Others destroyed

	procedure   GETPATH,near
	DOSAssume   CS,<DS>,"GetPath"
	ASSUME	ES:NOTHING

	MOV	WORD PTR [CREATING],0E500H  ; Not Creating, not DEL *.*

;Same as GetPath only CREATING and DELALL already set
	entry	GetPathNoSet
	MOV	[EXTERR_LOCUS],errLOC_Disk
	MOV	WORD PTR CurBuf,-1	; initial setting
;
; See if the input indicates a device that has already been detected.  If so,
; go build the guy quickly.  Otherwise, let findpath find the device.
;
	MOV	DI,Wfp_Start		; point to the beginning of the name
	CMP	WORD PTR [DI+1],'\' SHL 8 + ':'
	JZ	CrackIt
;
; Let ChkDev find it in the device list
;
	ADD	DI,3
	MOV	SI,DI			; let CHKDEV see the original name
	CALL	CHKDEV
	JC	InternalError
Build_devJ:
	MOV	AL,SAttrib
	MOV	Attrib,AL
	MOV	[EXTERR_LOCUS],errLOC_Unk ; In the particular case of
					; "finding" a char device
					; set LOCUS to Unknown. This makes
					; certain idiotic problems reported
					; by a certain 3 letter OEM go away.
;
; Take name in name1 and pack it back into where wfp_start points.  This
; guarantees wfp_start pointing to a canonical representation of a device.
; We are allowed to do this as GetPath is *ALWAYS* called before entering a
; wfp into the share set.
;
; We copy chars from name1 to wfp_start remembering the position of the last
; non-space seen +1.  This position is kept in DX.
;
	Context ES
	mov	si,offset DOSGroup:Name1
	mov	di,wfp_start
	mov	dx,di
	mov	cx,8			; 8 chars in device name
MoveLoop:
	lodsb
	stosb
	cmp	al," "
	jz	nosave
 IF  DBCS				;AN000;;
;	cmp	al,81h			;AN000;; 2/23/KK
;	jne	notKanji		;AN000;; 2/23/KK
;	cmp	cx,1			;AN000; 2/23/KK
;	je	notKanji		;AN000; 2/23/KK
;	cmp	byte ptr [si],40h	;AN000; 2/23/KK
;	jne	notKanji		;AN000;; 2/23/KK
;	lodsb				;AN000;; 2/23/KK
;	stosb				;AN000;; 2/23/KK
;	dec	cx			;AN000;; 2/23/KK
;	jmp	nosave			;AN000;; 2/23/KK
;notKanji:				;AN000;; 2/23/KK
 ENDIF
	mov	dx,di
NoSave:
	loop	MoveLoop
;
; DX is the position of the last seen non-space + 1.  We terminate the name
; at this point.
;
	mov	di,dx
	mov	byte ptr [di],0 	; end of string
	invoke	Build_device_ent	; Clears carry sets zero
	INC	AL			; reset zero
	return

	assume	es:nothing

InternalError:
	JMP	InternalError		; freeze

;
; Start off at the correct spot.  Optimize if the current dir part is valid.
;
CrackIt:
	MOV	SI,[CURR_DIR_END]	; get current directory pointer
	CMP	SI,-1			; valid?
	JNZ	LOOK_SING		; Yes, use it.
	LEA	SI,[DI+3]		; skip D:\
LOOK_SING:
	Assert	ISDPB,<<WORD PTR THISDPB+2>,<WORD PTR THISDPB>>,"Crackit"
	MOV	Attrib,attr_directory+attr_system+attr_hidden
					; Attributes to search through Dirs
	LES	DI,[THISCDS]
	MOV	AX,-1
	MOV	BX,ES:[DI.curdir_ID]
	MOV	SI,[CURR_DIR_END]
;
; AX = -1
; BX = cluster number of current directory.  THis number is -1 if the media
;      has been uncertainly changed.
; SI = offset in DOSGroup into path to end of current directory text.  This
;      may be -1 if no current directory part has been used.
;
	CMP	SI,AX			; if Current directory is not part
	JZ	NO_CURR_D		; then we must crack from root
	CMP	BX,AX			; is the current directory cluster valid

; DOS 3.3  6/25/86
	JZ	NO_CURR_D		; no, crack form the root
	TEST	[FastOpenFlg],FastOpen_Set     ; for fastopen ?
	JZ	GOT_SEARCH_CLUSTER	       ; no
	PUSH	ES			; save registers
	PUSH	DI
	PUSH	CX
	PUSH	[SI-1]			; save \ and 1st char of next element
	PUSH	SI
	PUSH	BX

	MOV	BYTE PTR [SI-1],0	; call fastopen to look up cur dir info
	MOV	SI,[Wfp_Start]
	MOV	BX,OFFSET DOSGROUP:FastOpenTable
	MOV	DI,OFFSET DOSGROUP:Dir_Info_Buff
	MOV	CX,OFFSET DOSGROUP:FastOpen_Ext_Info
	MOV	AL,FONC_look_up
	PUSH	DS
	POP	ES
	CALL	DWORD PTR [BX.FASTOPEN_NAME_CACHING]
	JC	GO_Chk_end1			;fastopen not installed, or wrong drive. Go to Got_Srch_cluster
	CMP	BYTE PTR [SI],0 		;fastopen has current dir info?
	JE	GO_Chk_end			;yes. Go to got_serch_cluster
	stc
	jmp	short GO_Chk_end		;Go to No_Curr_D
GO_Chk_end1:
	clc
GO_Chk_end:					; restore registers
	POP	BX
	POP	SI
	POP	[SI-1]
	POP	CX
	POP	DI
	POP	ES
	JNC	GOT_SEARCH_CLUSTER		; crack based on cur dir

; DOS 3.3  6/25/86
;
; We must cract the path beginning at the root.  Advance pointer to beginning
; of path and go crack from root.
;
NO_CURR_D:
	MOV	SI,[WFP_START]
	LEA	SI,[SI+3]		; Skip "d:/"
	LES	BP,[THISDPB]		; Get ES:BP
	JMP	ROOTPATH
;
; We are able to crack from the current directory part.  Go set up for search
; of specified cluster.
;
GOT_SEARCH_CLUSTER:
	LES	BP,[THISDPB]		; Get ES:BP
	invoke	SETDIRSRCH
	JC	SETFERR
	JMP	FINDPATH

SETFERR:
	XOR	CL,CL			; set zero
	STC
	Return

EndProc GETPATH

; Check to see if the name at DS:DI is a device.  Returns carry set if not a
;   device.
; Blasts CX,SI,DI,AX,BX

Procedure   ChkDev,NEAR
	ASSUME	ES:Nothing,DS:NOTHING

	MOV	SI,DI
	MOV	DI,SS
	MOV	ES,DI
	ASSUME	ES:DOSGroup		; Now here is where ES is DOSGroup

	MOV	DI,OFFSET DOSGROUP:NAME1
	MOV	CX,9
TESTLOOP:
	invoke	GETLET
 IF  DBCS				;AN000;
	invoke	Testkanj		;AN000;; 2/13/KK
	jz	Notkanja		;AN000;; 2/13/KK
	stosb				;AN000;; Skip second byte   2/13/KK
	dec	cx			;AN000;; 2/13/KK
	jcxz	notdev			;AN000;; 2/13/KK
	lodsb				;AN000;; 2/13/KK
	jmp	short stowit		;AN000;; 2/13/KK
Notkanja:				;AN000;
 ENDIF					;AN000;
	CMP	AL,'.'
	JZ	TESTDEVICE
	invoke	PATHCHRCMP
	JZ	NOTDEV
	OR	AL,AL
	JZ	TESTDEVICE
stowit:
	STOSB
	LOOP	TESTLOOP
NOTDEV:
	STC
	return

TESTDEVICE:
	ADD	CX,2
	MOV	AL,' '
	REP	STOSB
	MOV	AX,SS
	MOV	DS,AX
	invoke	DEVNAME
	return
EndProc ChkDev

Break	<ROOTPATH, FINDPATH -- PARSE A PATH>

; Inputs:
;	Same as FINDPATH but,
;	SI Points to asciz string of path which is assumed to start at
;		the root (no leading '/').
; Function:
;	Search from root for path
; Outputs:
;	Same as FINDPATH but:
;	If root directory specified, [CURBUF] and [NAME1] are NOT set, and
;	[NoSetDir] is ignored.

	procedure   ROOTPATH,near

	DOSAssume   CS,<DS>,"RootPath"
	ASSUME	ES:NOTHING

	invoke	SETROOTSRCH
	CMP	BYTE PTR [SI],0
	JNZ	FINDPATH

; Root dir specified
	MOV	AL,SAttrib
	MOV	Attrib,AL
	XOR	AH,AH			; Sets "device ID" byte, sets zero
					; (dir), clears carry.
	return

; Inputs:
;	[ATTRIB] Set to get through directories
;	[SATTRIB] Set to find last element
;	ES:BP Points to DPB
;	SI Points to asciz string of path (no leading '/').
;	[SECCLUSPOS] = 0
;	[DIRSEC] = Phys sec # of first sector of directory
;	[CLUSNUM] = Cluster # of next cluster
;	[CLUSFAC] = Sectors per cluster
;	[NoSetDir] set
;	[CURR_DIR_END] Points to end of Current dir part of string
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[THISCDS] Points to CDS being used
;	[CREATING] and [DELALL] set
; Function:
;	Parse path name
; Outputs:
;	ID1 field of [THISCDS] updated appropriately
;	[ATTRIB] = [SATTRIB]
;	ES:BP Points to DPB
;	[THISDPB] = ES:BP
;	Carry set if bad path
;	   SI Points to path element causing failure
;	   Zero set
;	      [DIRSTART],[DIRSEC],[CLUSNUM], and [CLUSFAC] are set up to
;	      start a search on the last directory
;	      CL is zero if there is a bad name in the path
;	      CL is non-zero if the name was simply not found
;		 [ENTFREE] may have free spot in directory
;		 [NAME1] is the name.
;		 CL = 81H if '*'s or '?' in NAME1, 80H otherwise
;	   Zero reset
;	      File in middle of path or bad name in path
;		or path too long or malformed path
;	ELSE
;	   [CURBUF] contains directory record with match
;	   [CURBUF+2]:BX Points into [CURBUF] to start of entry
;	   [CURBUF+2]:SI Points to fcb_FIRCLUS field for entry
;	   [NAME1] Has name looked for
;	   AH = device ID
;	      bit 7 of AH set if device SI and BX
;	      will point DOSGROUP relative The firclus
;	      field of the device entry contains the device pointer
;	   If last element is a directory zero is set and:
;	      [DIRSTART],[SECCLUSPOS],[DIRSEC],[CLUSNUM], and [CLUSFAC]
;	      are set up to start a search on it,
;	      unless [NoSetDir] is non zero in which case the return is
;	      like that for a file (except for zero flag)
;	   If last element is a file zero is reset
;	      [DIRSEC],[CLUSNUM],[CLUSFAC],[NXTCLUSNUM],[SECCLUSPOS],
;	      [LASTENT], [ENTLAST] are set to continue search of last
;	      directory for furthur matches on NAME1 via the NEXTENT
;	      entry point in FindEntry (or GETENT entry in GETENTRY in
;	      which case [NXTCLUSNUM] and [SECCLUSPOS] need not be valid)
; Destroys all other registers

    entry   FINDPATH
	DOSAssume   CS,<DS>,"FindPath"
	ASSUME	ES:NOTHING

	Assert	ISDPB,<ES,BP>,"FindPath"
	PUSH	ES			; Save ES:BP
	PUSH	SI
	MOV	DI,SI
	MOV	CX,[DIRSTART]		; Get start clus of dir being searched
	CMP	[CURR_DIR_END],-1
	JZ	NOIDS			; No current dir part
	CMP	DI,[CURR_DIR_END]
	JNZ	NOIDS			; Not to current dir end yet
	LES	DI,[THISCDS]
	MOV	ES:[DI.curdir_ID],CX	; Set current directory currency
NOIDS:
;
; Parse the name off of DS:SI into NAME1.  AL = 1 if there was a meta
; character in the string.  CX,DI  may be destroyed.
;
;	invoke	NAMETRANS
;	MOV	CL,AL
;
; The above is the slow method.  The name has *already* been munged by
; TransPath so no special casing needs to be done.  All we do is try to copy
; the name until ., \ or 0 is hit.
;
	MOV	AX,SS
	MOV	ES,AX
	MOV	DI,OFFSET DOSGroup:Name1
	MOV	AX,'  '
	STOSB
	STOSW
	STOSW
	STOSW
	STOSW
	STOSW
	MOV	DI,OFFSET DOSGroup:Name1
	XOR	AH,AH			; bits for CL
 IF  DBCS				;AN000;
;-------------------------- Start of DBC;AN000;S 2/13/KK
	XOR	CL,CL			;AN000;; clear count for volume id
	LODSB				;AN000;;IBMJ fix 9/04/86
	CMP	AL,05h			;AN000;;IBMJ fix 9/04/86
	JNE	GetNam2 		;AN000;;IBMJ fix 9/04/86
	PUSH	AX			;AN000;        ;IBMJ fix 9/04/86
	MOV	AL,0E5h 		;AN000;;IBMJ fix 9/04/86
	Invoke	TestKanj		;AN000;;IBMJ fix 9/04/86
	POP	AX			;AN000;        ;IBMJ fix 9/04/86
	JZ	Notkanjb		;AN000;        ;IBMJ fix 9/04/86
	JMP	SHORT GetNam3		;AN000;;IBMJ fix 9/04/86
;-------------------------- End of DBCS ;AN000;2/13/KK
 ENDIF
GetNam:
	INC	CL			;AN000; KK incrment volid count
	LODSB
 IF  DBCS				;AN000;
GetNam2:				;AN000;; 2/13/KK
	invoke	Testkanj		;AN000;; 2/13/KK
	jz	Notkanjb		;AN000;; 2/13/KK
GetNam3:				;AN000;; 2/13/KK
	STOSB				;AN000;; 2/13/KK
	INC	CL			;AN000;; KK incrment volid count
	LODSB				;AN000;; 2/13/KK
	TEST	[DOS34_FLAG],DBCS_VOLID ;AN000;; 2/13/KK
	JZ	notvol			;AN000;; 2/13/KK
	CMP	CL,8			;AN000;; 2/13/KK
	JNZ	notvol			;AN000;; 2/13/KK
	CMP	AL,'.'                  ;AN000;; 2/13/KK
	JNZ	notvol			;AN000;; 2/13/KK
	LODSB				;AN000;; 2/13/KK
notvol: 				;AN000;
	jmp	short StoNam		;AN000;; 2/13/KK
Notkanjb:				;AN000;; 2/13/KK
 ENDIF					;AN000;
	CMP	AL,'.'
	JZ	setExt
	OR	AL,AL
	JZ	GetDone
	CMP	AL,'\'
	JZ	GetDone
	CMP	AL,'?'
	JNZ	StoNam
	OR	AH,1
StoNam: STOSB
	JMP	GetNam
SetExt:
	MOV	DI,OFFSET DOSGroup:Name1+8
GetExt:
	LODSB
 IF  DBCS				;AN000;
	invoke	TestKanj		;AN000;; 2/13/KK
	jz	Notkanjc		;AN000;; 2/13/KK
	STOSB				;AN000;; 2/13/KK
	LODSB				;AN000;; 2/13/KK
	jmp	short StoExt		;AN000;; 2/13/KK
Notkanjc:				;AN000;; 2/13/KK
 ENDIF					;AN000;
	OR	AL,AL
	JZ	GetDone
	CMP	AL,'\'
	JZ	GetDone
	CMP	AL,'?'
	JNZ	StoExt
	OR	AH,1
StoExt: STOSB
	JMP	GetExt
GetDone:
	DEC	SI
	MOV	CL,AH


	OR	CL,80H
	POP	DI			; Start of this element
	POP	ES			; Restore ES:BP
	CMP	SI,DI
	JNZ	check_device
	JMP	BADPATH 		; NUL parse (two delims most likely)
check_device:
	PUSH	SI			; Start of next element
	MOV	AL,BYTE PTR [SI]
	OR	AL,AL
	JNZ	NOT_LAST

;
; for last element of the path switch to the correct search attributes
;
	MOV	BH,SAttrib
	MOV	Attrib,BH
NOT_LAST:

;
; check name1 to see if we have a device...
;
	PUSH	ES			; Save ES:BP
	context ES
	invoke	DevName 		; blast BX
	POP	ES			; Restore ES:BP
	ASSUME	ES:NOTHING
	JC	FindFile		; Not a device
	OR	AL,AL			; Test next char again
	JZ	GO_BDEV
	JMP	FileInPath		; Device name in middle of path

GO_BDEV:
	POP	SI			; Points to NUL at end of path
	JMP	Build_devJ

FindFile:
	ASSUME	ES:NOTHING
;;;; 7/28/86
	CMP	BYTE PTR [NAME1],0E5H	; if 1st char = E5
	JNZ	NOE5			; no
	MOV	BYTE PTR [NAME1],05H	; change it to 05
NOE5:

;;;; 7/28/86
	PUSH	DI			; Start of this element
	PUSH	ES			; Save ES:BP
	PUSH	CX			; CL return from NameTrans
;DOS 3.3 FastOPen 6/12/86 F.C.

	CALL	LookupPath		; call fastopen to get dir entry
	JNC	DIR_FOUND		; found dir entry

;DOS 3.3 FastOPen 6/12/86 F.C.
	invoke	FINDENTRY
DIR_FOUND:
	POP	CX
	POP	ES
	POP	DI
	JNC	LOAD_BUF
	JMP	BADPATHPOP

LOAD_BUF:
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	TEST	BYTE PTR [BX+dir_attr],attr_directory
	JNZ	GO_NEXT 		; DOS 3.3
	JMP	FileInPath		; Error or end of path
;
; if we are not setting the directory, then check for end of string
;
GO_NEXT:
	CMP	BYTE PTR [NoSetDir],0
	JZ	SetDir
	MOV	DX,DI			; Save pointer to entry
	MOV	CX,DS
	context DS
	POP	DI			; Start of next element
	TEST   [FastOpenFlg],FastOpen_Set     ;only DOSOPEN can take advantage of
	JZ     nofast			      ; the FastOpen
	TEST   [FastOpenFlg],Lookup_Success   ; Lookup just happened
	JZ     nofast			      ; no
	MOV    DI,[Next_Element_Start]	      ; no need to insert it again
nofast:
	CMP	BYTE PTR [DI],0
	JNZ	NEXT_ONE		; DOS 3.3
	JMP	SetRet			; Got it
NEXT_ONE:
	PUSH	DI			; Put start of next element back on stack
	MOV	DI,DX
	MOV	DS,CX			; Get back pointer to entry
ASSUME	DS:NOTHING

SetDir:
	MOV	DX,[SI] 		; Dir_first

;DOS 3.3 FastOPen 6/12/86 F.C.

	PUSH	DS		      ; save [curbuf+2]
	context DS		      ; set DS Dosgroup
	TEST	[FastOpenFlg],Lookup_Success   ;
	JZ	DO_NORMAL	      ; fastopen not in memory or path not
	MOV	BX,DX		      ; not found
	MOV	DI,[CLUSNUM]	      ; clusnum was set in LookupPath
	PUSH	AX		      ; save device id (AH)
	invoke	SETDIRSRCH
	POP	AX		      ; restore device id (AH)
	ADD	SP,2		      ; pop ds in stack
	JMP	FAST_OPEN_SKIP

DO_NORMAL:
ASSUME	DS:NOTHING
	POP	DS			; DS = [curbuf + 2]
;DOS 3.3 FastOPen 6/12/86 F.C.

	SUB	BX,DI			; Offset into sector of start of entry
	SUB	SI,DI			; Offset into sector of dir_first
	PUSH	BX
	PUSH	AX
	PUSH	SI
	PUSH	CX
	PUSH	WORD PTR [DI.buf_sector]     ;AN000;>32mb
	PUSH	WORD PTR [DI.buf_sector+2]   ;AN000;>32mb
	MOV	BX,DX
	context DS
	invoke	SETDIRSRCH		; This uses UNPACK which might blow
					; the entry sector buffer
	POP	[HIGH_SECTOR]
	POP	DX
	JC	SKIP_GETB
	MOV	[ALLOWED],allowed_RETRY + allowed_FAIL
	XOR	AL,AL
	invoke	GETBUFFR		; Get the entry buffer back
SKIP_GETB:
	POP	CX
	POP	SI
	POP	AX
	POP	BX
	JNC	SET_THE_BUF
	POP	DI			; Start of next element
	MOV	SI,DI			; Point with SI
	JMP	SHORT BADPATH

SET_THE_BUF:
	invoke	SET_BUF_AS_DIR
	MOV	DI,WORD PTR [CURBUF]
	ADD	SI,DI			; Get the offsets back
	ADD	BX,DI
; DOS 3.3 FasOpen 6/12/86  F.C.

FAST_OPEN_SKIP:

	POP	DI			; Start of next element
	CALL   InsertPath	     ; insert dir entry info

; DOS 3.3 FasOpen 6/12/86  F.C.


	MOV	AL,[DI]
	OR	AL,AL
	JZ	SETRET			; At end
	INC	DI			; Skip over "/"
	MOV	SI,DI			; Point with SI
	invoke	PATHCHRCMP
	JNZ	find_bad_name		; oops
	JMP	FINDPATH		; Next element

find_bad_name:
	DEC	SI			; Undo above INC to get failure point
BADPATH:
	XOR	CL,CL			; Set zero
	JMP	SHORT BADPRET

FILEINPATH:
	POP	DI			; Start of next element
	context DS			; Got to from one place with DS gone
; DOS 3.3 FastOpen

	TEST	[FastOpenFlg],FastOpen_Set  ; do this here is we don't want to
	JZ	NO_FAST 		    ; device info to fastopen
	TEST	[FastOpenFlg],Lookup_Success
	JZ	NO_FAST
	MOV	DI,[Next_Element_Start]  ; This takes care of one time lookup
					 ; success
NO_FAST:

; DOS 3.3 FastOpen

	MOV	AL,[DI]
	OR	AL,AL
	JZ	INCRET
	MOV	SI,DI			; Path too long
	JMP	SHORT BADPRET

INCRET:
; DOS 3.3 FasOpen 6/12/86  F.C.

	CALL   InsertPath	     ; insert dir entry info

; DOS 3.3 FasOpen 6/12/86  F.C.
	INC	AL			; Reset zero
SETRET:
	return

BADPATHPOP:
	POP	SI			; Start of next element
	MOV	AL,[SI]
	MOV	SI,DI			; Start of bad element
	OR	AL,AL			; zero if bad element is last, non-zero if path too long
BADPRET:
	MOV	AL,SAttrib
	MOV	Attrib,AL		; Make sure return correct
	STC
	return
EndProc ROOTPATH

Break	<STARTSRCH -- INITIATE DIRECTORY SEARCH>

; Inputs:
;	[THISDPB] Set
; Function:
;	Set up a search for GETENTRY and NEXTENTRY
; Outputs:
;	ES:BP = Drive parameters
;	Sets up LASTENT, ENTFREE=ENTLAST=-1, VOLID=0
; Destroys ES,BP,AX

	procedure   StartSrch,NEAR
	DOSAssume   CS,<DS>,"StartSrch"
	ASSUME	ES:NOTHING

	Assert	ISDPB,<<WORD PTR THISDPB+2>,<WORD PTR THISDPB>>,"StartSrch"
	LES	BP,[THISDPB]
	XOR	AX,AX
	MOV	[LASTENT],AX
	MOV	BYTE PTR [VOLID],AL	; No volume ID found
	DEC	AX
	MOV	[ENTFREE],AX
	MOV	[ENTLAST],AX
	return
EndProc StartSrch

BREAK <MatchAttributes - the final check for attribute matching>

;
; Input:    [Attrib] = attribute to search for
;	    CH = found attribute
; Output:   JZ <match>
;	    JNZ <nomatch>
; Registers modified: noneski
	procedure MatchAttributes,near
	ASSUME	DS:NOTHING,ES:NOTHING
	PUSH	AX
	MOV	AL,Attrib		; AL <- SearchSet
	NOT	AL			; AL <- SearchSet'
	AND	AL,CH			; AL <- SearchSet' and FoundSet
	AND	AL,attr_all		; AL <- SearchSet' and FoundSet and Important
;
; the result is non-zero if an attribute is not in the search set
; and in the found set and in the important set. This means that we do not
; have a match.  Do a JNZ <nomatch> or JZ <match>
;
	POP	AX
	return
EndProc MatchAttributes

Break <DevName - Look for name of device>

; Inputs:
;	DS,ES:DOSGROUP
;	Filename in NAME1
;	ATTRIB set so that we can error out if looking for Volume IDs
; Function:
;	Determine if file is in list of I/O drivers
; Outputs:
;	Carry set if not a device
;	ELSE
;	Zero flag set
;	BH = Bit 7,6 = 1, bit 5 = 0 (cooked mode)
;	     bits 0-4 set from low byte of attribute word
;	DEVPT = DWORD pointer to Device header of device
; BX destroyed, others preserved

	procedure   DEVNAME,NEAR
	DOSAssume   CS,<ES,DS>,"DevName"

	PUSH	SI
	PUSH	DI
	PUSH	CX
	PUSH	AX

; E5 special code
	PUSH	WORD PTR [NAME1]
	CMP	[NAME1],5
	JNZ	NOKTR
	MOV	[NAME1],0E5H
NOKTR:

	TEST	Attrib,attr_volume_id	; If looking for VOL id don't find devs
	JNZ	RET31
	MOV	SI,OFFSET DOSGROUP:NULDEV
LOOKIO:
ASSUME	DS:NOTHING
	TEST	[SI.SDEVATT],DEVTYP
	JZ	SKIPDEV 		; Skip block devices (NET and LOCAL)
	MOV	AX,SI
	ADD	SI,SDEVNAME
	MOV	DI,OFFSET DOSGROUP:NAME1
	MOV	CX,4			; All devices are 8 letters
	REPE	CMPSW			; Check for name in list
	MOV	SI,AX
	JZ	IOCHK			; Found it?
SKIPDEV:
	LDS	SI,DWORD PTR [SI]	; Get address of next device
	CMP	SI,-1			; At end of list?
	JNZ	LOOKIO
RET31:	STC				; Not found
RETNV:	MOV	CX,SS
	MOV	DS,CX
	ASSUME	DS:DOSGroup
	POP	WORD PTR [NAME1]
	POP	AX
	POP	CX
	POP	DI
	POP	SI
	RET

IOCHK:
ASSUME	DS:NOTHING
	MOV	WORD PTR [DEVPT+2],DS	; Save pointer to device
	MOV	BH,BYTE PTR [SI.SDEVATT]
	OR	BH,0C0H
	AND	BH,NOT 020H		; Clears Carry
	MOV	WORD PTR [DEVPT],SI
	JMP	RETNV
EndProc DevName

BREAK <Build_device_ent - Make a Directory entry>

; Inputs:
;	[NAME1] has name
;	BH is attribute field (supplied by DEVNAME)
;	[DEVPT] points to device header (supplied by DEVNAME)
; Function:
;	Build a directory entry for a device at DEVFCB
; Outputs:
;	BX points to DEVFCB
;	SI points to dir_first field
;	AH = input BH
;	AL = 0
;	dir_first = DEVPT
;	Zero Set, Carry Clear
; DS,ES,BP preserved, others destroyed

	procedure Build_device_ent,near
	DOSAssume   CS,<ES,DS>,"Build_Device_Ent"

	MOV	AX,"  "
	MOV	DI,OFFSET DOSGROUP:DEVFCB+8 ; Point to extent field
;
; Fill dir_ext
;
	STOSW
	STOSB				; Blank out extent field
	MOV	AL,attr_device
;
; Fill Dir_attr
;
	STOSB				; Set attribute field
	XOR	AX,AX
	MOV	CX,10
;
; Fill dir_pad
;
	REP	STOSW			; Fill rest with zeros
	invoke	DATE16
	MOV	DI,OFFSET DOSGROUP:DEVFCB+dir_time
	XCHG	AX,DX
;
; Fill dir_time
;
	STOSW
	XCHG	AX,DX
;
; Fill dir_date
;
	STOSW
	MOV	SI,DI			; SI points to dir_first field
	MOV	AX,WORD PTR [DEVPT]
;
; Fill dir_first
;
	STOSW				; Dir_first points to device
	MOV	AX,WORD PTR [DEVPT+2]
;
; Fill dir_size_l
;
	STOSW
	MOV	AH,BH			; Put device atts in AH
	MOV	BX,OFFSET DOSGROUP:DEVFCB
	XOR	AL,AL			; Set zero, clear carry
	return
EndProc Build_device_ent

Break	<ValidateCDS - given a CDS, validate the media and the current directory>

;
;   ValidateCDS - Get current CDS.  Splice it.	Call FatReadCDS to check
;   media.  If media has been changed, do DOS_Chdir to validate path.  If
;   invalid, reset original CDS to root.
;
;   Inputs:	ThisCDS points to CDS of interest
;		SS:DI points to temp buffer
;   Outputs:	The current directory string is validated on the appropriate
;		    drive
;		ThisDPB changed
;		ES:DI point to CDS
;		Carry set if error (currently user FAILed to I 24)
;   Registers modified: all

Procedure   ValidateCDS,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
Public DIR2001S,DIR2001E
DIR2001S:
	LocalVar    Temp,WORD
	LocalVar    SaveCDS,DWORD
DIR2001E:
	Enter
	MOV	Temp,DI
	LDS	SI,ThisCDS
	MOV	SaveCDSL,SI
	MOV	SaveCDSH,DS
	EnterCrit   critDisk
	TEST	[SI].curdir_flags,curdir_isnet	; Clears carry
	JZ	DoSplice
	JMP	FatFail
DoSplice:
	XOR	DL,DL
	XCHG	DL,NoSetDir
	Context ES
	Invoke	FStrcpy
	MOV	SI,Temp
	Context DS
	Invoke	Splice
	ASSUME	DS:NOTHING
	Context DS			;   FatReadCDS (ThisCDS);
	MOV	NoSetDir,DL
	LES	DI,ThisCDS
	SaveReg <BP>
	Invoke	FatRead_CDS
	RestoreReg  <BP>
	JC	FatFail
	LDS	SI,ThisCDS		;   if (ThisCDS->ID == -1) {
	ASSUME	DS:NOTHING
	CMP	[SI].curdir_ID,-1
	JNZ	RestoreCDS
	Context ES
	SaveReg <wfp_Start>		;	t = wfp_Start;
	CMP	SI,SaveCDSL		; if not spliced
	JNZ	DoChdir
	MOV	DI,Temp
	MOV	wfp_Start,DI		;	wfp_start = d;
	Invoke	FStrCpy 		;	strcpy (d, ThisCDS->Text);
DoChdir:
	Context DS
	SaveReg <<WORD PTR SAttrib>,BP> ;	c = DOSChDir ();
	Invoke	DOS_ChDir
	RestoreReg  <BP,BX,wfp_start>	;	wfp_Start = t;
	MOV	SAttrib,BL
	LDS	SI,SaveCDS
	ASSUME	DS:NOTHING
	JNC	SetCluster		;	if (c == -1) {
	MOV	WORD PTR ThisCDS,SI	;	    ThisCDS = TmpCDS;
	MOV	WORD PTR ThisCDS+2,DS
	XOR	CX,CX			;	    TmpCDS->text[3] = c = 0;
	MOV	[SI+3],CL		;	    }
SetCluster:
	MOV	[SI].curdir_ID,-1	;	TmpCDS->ID = -1;
	LDS	SI,ThisCDS		;	ThisCDS->ID = c;
	TEST	[SI].curdir_flags,curdir_splice      ;AN000;;MS.  for Join and Subst
	JZ	setdirclus			     ;AN000;;MS.
	MOV	CX,-1				     ;AN000;;MS.
setdirclus:
	MOV	[SI].curdir_ID,CX	;	}
RestoreCDS:
	LES	DI,SaveCDS
	MOV	WORD PTR ThisCDS,DI
	MOV	WORD PTR ThisCDS+2,ES
	CLC
FatFail:
	LeaveCrit   critDisk
	LES	DI,SaveCDS
	Leave
	return
EndProc ValidateCDS

Break	<CheckThisDevice - Check for being a device>

;
;   CheckThisDevice - Examine the area at DS:SI to see if there is a valid
;   device specified.  We will return carry if there is a device present.  The
;   forms of devices we will recognize are:
;
;	[path]device
;
;   Note that the drive letter has *already* been removed.  All other forms
;   are not considered to be devices.  If such a device is found we change the
;   source pointer to point to the device component.
;
;   Inputs:	ES is DOSGroup
;		DS:SI contains name
;   Outputs:	ES is DOSGroup
;		DS:SI point to name or device
;		Carry flag set if device was found
;		Carry flag reset otherwise
;   Registers Modified: all except ES:DI, DS

if FALSE
Procedure   CheckThisDevice,NEAR
	DOSAssume CS,<ES>,"CheckThisDevice"
	ASSUME	DS:NOTHING
	SaveReg <DI,SI>
;
; Advance to after the final path character.
;
	MOV	DI,SI			; remember first character
PathSkip:
	LODSB
	OR	AL,AL
	JZ	FoundEnd
 IF  DBCS			;AN000;
	invoke	Testkanj	;AN000;; 2/13/KK
	jz	Notkanje	;AN000;; 2/13/KK
	lodsb			;AN000;; 2/13/KK
	or	al,al		;AN000;; Skip second byte 2/13/KK  removed
	jz	FoundEnd	;AN000;; 2/13/KK		   removed
	jmp	Short Pathskip	;AN000;; Ignore missing second byte for now.
NotKanje:			;AN000;
  ENDIF 			;AN000;
;kanji load of next char too	  2/13/KK
IF Kanji
 kanji load of next char too
ENDIF
	invoke	PathChrCmp		; is it a path char?
	JNZ	PathSkip
	MOV	DI,SI
	JMP	PathSkip
FoundEnd:
	MOV	SI,DI
;
; Parse the name
;
	SaveReg <DS,SI> 		; preserve the source pointer
	invoke	NameTrans		; advance DS:SI
	CMP	BYTE PTR [SI],0 	; parse entire string?
	STC				; simulate a Carry return from DevName
	JNZ	SkipSearch		; no parse.  simulate a file return.
	Context DS
	Invoke	DevName
	ASSUME	DS:NOTHING
SkipSearch:
	RestoreReg  <SI,DS>
;
; DS:SI points to the beginning of the potential device.  If we have a device
; then we do not change SI.  If we have a file, then we reset SI back to the
; original value.  At this point Carry set indicates FILE.
;
	RestoreReg  <DI>		; get original SI
	JNC	CheckDone		; if device then do not reset pointer
	MOV	SI,DI
CheckDone:
	RestoreReg  <DI>
	CMC				; invert carry.  Carry => device
	return
else
Procedure   CheckThisDevice,NEAR
	DOSAssume CS,<ES>,"CheckThisDevice"
	ASSUME	DS:NOTHING
	SaveReg <DI,SI>
	MOV	DI,SI
;
; Check for presence of \dev\ (Dam multiplan!)
;
	MOV	AL,[SI]
	Invoke	PathChrCmp		; is it a path char?
	JNZ	ParseDev		; no, go attempt to parse device
	INC	SI			; simulate LODSB
;
; We have the leading path separator.  Look for DEV part.
;
	LODSW
	OR	AX,2020h
	CMP	AX,"e" SHL 8 + "d"
	JNZ	NotDevice		; not "de", assume not device
	LODSB
	OR	AL,20h
	CMP	AL,"v"                  ; Not "v", assume not device
	JNZ	NotDevice
	LODSB
	invoke	PathChrCmp		; do we have the last path separator?
	JNZ	NotDevice		; no. go for it.
;
; DS:SI now points to a potential drive.  Preserve them as NameTrans advances
; SI and DevName may destroy DS.
;
ParseDev:
	SaveReg <DS,SI> 		; preserve the source pointer
	invoke	NameTrans		; advance DS:SI
	CMP	BYTE PTR [SI],0 	; parse entire string?
	STC				; simulate a Carry return from DevName
	JNZ	SkipSearch		; no parse.  simulate a file return.
	Context DS
	Invoke	DevName
	ASSUME	DS:NOTHING
SkipSearch:
	RestoreReg  <SI,DS>
;
; SI points to the beginning of the potential device.  If we have a device
; then we do not change SI.  If we have a file, then we reset SI back to the
; original value.  At this point Carry set indicates FILE.
;
CheckReturn:
	RestoreReg  <DI>		; get original SI
	JNC	CheckDone		; if device then do not reset pointer
	MOV	SI,DI
CheckDone:
	RestoreReg  <DI>
	CMC				; invert carry.  Carry => device
	return
NotDevice:
	STC
	JMP	CheckReturn
endif

EndProc CheckThisDevice

BREAK <LookupPath - call fastopen to get dir entry info>

;
; Output  DS:SI -> path name,
;	  ES:DI -> dir entry info buffer
;	  ES:CX -> extended dir info buffer
;
;	  carry flag clear : tables pointed by ES:DI and ES:CX are filled by
;			     FastOpen, DS:SI points to char just one after
;			     the last char of path name which is fully or
;			     partially found in FastOPen
;	  carry flag set : FastOpen not in memory or path name not found
;
	procedure LookupPath,NEAR
	ASSUME	ES:NOTHING

;	PUSH	AX
	TEST	[FastOpenFlg],FastOpen_Set	    ; flg is set in DOSPEN
	JNZ	FASTINST			    ; and this routine is
NOLOOK:
	JMP	NOLOOKUP			    ; executed once
FASTINST:
	TEST	[FastOpenFlg],No_Lookup 	    ; no more lookup?
	JNZ	NOLOOK				    ; yes

	MOV	BX,OFFSET DOSGROUP:FastOpenTable    ; get fastopen related tab
	MOV	SI,[Wfp_Start]			    ; si points to path name
	MOV	DI,OFFSET DOSGROUP:Dir_Info_Buff
	MOV	CX,OFFSET DOSGROUP:FastOpen_Ext_Info
	MOV	AL,FONC_look_up 		    ; al = 1
	PUSH	DS
	POP	ES
	CALL	DWORD PTR [BX.FASTOPEN_NAME_CACHING] ;call fastopen
	JC	NOTFOUND			    ; fastopen not in memory

	LEA	BX,[SI-2]
	CMP	BX,[Wfp_Start]			    ; path found ?
	JZ	NOTFOUND			    ; no
						    ; fully or partially found
	CMP	BYTE PTR [SI],0 		    ;AN000;FO.
	JNZ	parfnd				    ;AN000;FO.; partiallyfound
	PUSH	CX				    ;AN000;FO.; is attribute matched ?
	MOV	CL,Attrib			    ;AN000;FO.;
	MOV	CH,Sattrib			    ;AN000;FO.; attrib=sattrib
	MOV	Attrib,CH			    ;AN000;FO.;
	MOV	CH,ES:[DI.dir_attr]		    ;AN000;FO.;
	invoke	Matchattributes 		    ;AN000;FO.;
;;;	MOV	Attrib,CL			    ;AN001;FO.; retore attrib
	POP	CX				    ;AN000;FO.;
	JNZ	NOLOOKUP			    ;AN000;FO.; not matched
parfnd:
	MOV	[Next_Element_Start],SI 		   ; save si
	MOV	BX,CX
	MOV	AX,[BX.FEI_lastent]		    ;AN000;;FO. restore lastentry
	MOV	[LASTENT],AX			    ;AN000;;FO.
	MOV	AX,[BX.FEI_dirstart]		    ;AN001;;FO. restore dirstart
	MOV	[DIRSTART],AX			    ;AN001;;FO.
	MOV	AX,[BX.FEI_clusnum]		    ; restore next cluster num
	MOV	[CLUSNUM],AX			    ;

	PUSH	ES				    ; save ES
	LES	BX,[THISDPB]			    ; put drive id
	MOV	AH,ES:[BX.dpb_drive]		    ; in AH for DOOPEN
	POP	ES				    ; pop ES

	MOV	WORD PTR [CURBUF+2],ES		    ; [curbuf+2].bx points to
	MOV	BX,DI				    ; start of entry
	LEA	SI,[DI.dir_first]		    ; [curbuf+2]:si points to
						    ; dir_first field in the
						    ; dir entry
	OR	[FastOpenFlg],Lookup_Success + set_for_search
;	POP	AX
	RET
NOTFOUND:
	CMP	AX,-1				    ; not in memory ?
	JNZ	Partial_Success 		    ; yes, in memory
	MOV	[FastOpenFlg],0 		    ; no more fastopen
Partial_Success:
	AND	[FastOpenFlg],Special_Fill_Reset
NOLOOKUP:
;	POP	AX
	STC
	RET
EndProc LookupPath

BREAK <InsertPath - call fastopen to insert dir entry info>

;
; Input:  FastOpen_Set flag set when from DOSOPEN otherwise 0
;	  Lookup_Success flag set when got dir entry info from FASTOPEN
;	  DS = DOSGROUP
; Output: FastOPen_Ext_Info is set and path dir info is inserted
;
	procedure InsertPath,NEAR
	ASSUME	ES:NOTHING

	PUSHF
	TEST   [FastOpenFlg],FastOpen_Set     ;only DOSOPEN can take advantage of
	JZ     GET_NEXT_ELEMENT 	      ; the FastOpen
	TEST   [FastOpenFlg],Lookup_Success   ; Lookup just happened
	JZ     INSERT_DIR_INFO		      ; no
	AND    [FastOpenFlg],Lookup_Reset     ; we got dir info from fastopen so
	MOV    DI,[Next_Element_Start]	      ; no need to insert it again
	JMP    GET_NEXT2
INSERT_DIR_INFO:			      ; save registers
	PUSH   DS
	PUSH   ES
	PUSH   BX
	PUSH   SI
	PUSH   DI
	PUSH   CX
	PUSH   AX
;  int 3
	LDS    DI,[CURBUF]		; DS:DI -> buffer header
ASSUME DS:NOTHING
	MOV    SI,OFFSET DOSGROUP:FastOpen_Ext_Info
	MOV    AX,WORD PTR [DI.buf_sector]  ; get directory sector
	MOV    WORD PTR CS:[SI.FEI_dirsec],AX ;AN000; >32mb save dir sector
	MOV    AX,WORD PTR [DI.buf_sector+2]  ;AN000; >32mb
	context DS
	MOV    WORD PTR [SI.FEI_dirsec+2],AX  ;AN000;>32mb save high dir sector
	MOV    AX,[CLUSNUM]		; save next cluster number
	MOV    [SI.FEI_clusnum],AX
	MOV    AX,[LASTENT]		;AN000;FO. save lastentry for search first
	MOV    [SI.FEI_lastent],AX	;AN000;FO.
	MOV    AX,[DIRSTART]		;AN001;FO. save  for search first
	MOV    [SI.FEI_dirstart],AX	;AN001;FO.

	MOV    AX,BX
	ADD    DI,BUFINSIZ		; DS:DI -> start of data in buffer
	SUB    AX,DI			; AX=BX relative to start of sector
	MOV    CL,SIZE dir_entry
;invoke debug_DOS
	DIV    CL
	MOV    [SI.FEI_dirpos],AL	; save directory entry # in buffer

	PUSH   DS
	POP    ES

	MOV    DS,WORD PTR [CURBUF+2]
	MOV    DI,BX			; DS:DI -> dir entry info
ASSUME DS:NOTHING
	CMP    DS:[DI.dir_first],0	; never insert info when file is empty
	JZ     SKIP_INSERT		; e.g. newly created file

	PUSH   SI			; ES:BX -> extended info
	POP    BX

	MOV    AL,FONC_insert		; call fastopen insert operation
	MOV    SI,OFFSET DOSGROUP:FastOpenTable
	CALL   DWORD PTR ES:[SI.FASTOPEN_NAME_CACHING]

	CLC
SKIP_INSERT:
	POP    AX
	POP    CX			; restore registers
	POP    DI
	POP    SI
	POP    BX
	POP    ES
	POP    DS
GET_NEXT2:
	OR     [FastOpenFlg],No_Lookup	      ; we got dir info from fastopen so
GET_NEXT_ELEMENT:
	POPF
	RET
EndProc InsertPath

CODE	ENDS
    END
