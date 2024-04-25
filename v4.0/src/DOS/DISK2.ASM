;	SCCSID = @(#)disk2.asm	1.3 85/06/19
;	SCCSID = @(#)disk2.asm	1.3 85/06/19
TITLE	DISK2 - Disk utility routines
NAME	Disk2
; Low level Read and write routines for local SFT I/O on files and devs
;
;   DskRead
;   DWRITE
;   DSKWRITE
;   HarderrRW
;   SETUP
;   BREAKDOWN
;   READ_LOCK_VIOLATION
;   WRITE_LOCK_VIOLATION
;   DISKREAD
;   SET_ACC_ERR_DS
;   SET_ACC_ERR
;   SETSFT
;   SETCLUS
;   AddRec
;
;   Revision history:
;
;    AN000  version 4.00 Jan. 1988
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
include version.inc
.cref
.list

Installed = TRUE

	i_need	THISSFT,DWORD
	i_need	DMAADD,DWORD
	i_need	NEXTADD,WORD
	i_need	ThisDrv,BYTE
	i_need	SecClusPos,BYTE
	i_need	ClusNum,WORD
	i_need	ReadOp,BYTE
	i_need	Trans,BYTE
	i_need	BytPos,4
	i_need	SecPos,DWORD		 ; DOS 4.00 >32mb			;AN000;
	i_need	BytSecPos,WORD
	i_need	BytCnt1,WORD
	i_need	BytCnt2,WORD
	i_need	SecCnt,WORD
	i_need	ThisDPB,DWORD
	i_need	LastPos,WORD
	i_need	EXTERRPT,DWORD
	i_need	CALLVIDRW,DWORD
	i_need	ALLOWED,BYTE
	i_need	DEVCALL,BYTE
	i_need	CALLSCNT,WORD
	i_need	DISK_FULL,BYTE		  ; disk full flag for ran blk wrt
	i_need	FSeek_drive,BYTE	  ; DOS 4.00	  ;AN000;
	i_need	FSeek_firclus,WORD	  ; DOS 4.00	  ;AN000;
	i_need	HIGH_SECTOR,WORD	  ; F.C. >32mb	  ;AN000;
	i_need	TEMP_VAR2,WORD		  ; LB. 	  ;AN000;
	i_need	TEMP_VAR,WORD		  ; LB. 	  ;AN000;
	i_need	IFS_DRIVER_ERR,WORD	  ; LB. 	  ;AN000;
	i_need	CurHashEntry,DWORD	     ; DOS 4.00 current Hash entry	;AN000;
	i_need	BUF_HASH_PTR,DWORD	     ; DOS 4.00 Hash table pointer	;AN000;
	i_need	BUF_HASH_COUNT,WORD	     ; DOS 4.00 Hash table entries	;AN000;
	i_need	LastBuffer,DWORD
	i_need	FIRST_BUFF_ADDR,WORD	     ; first buffer address		;AN000;

IF	BUFFERFLAG
	EXTRN	SAVE_MAP:NEAR
	EXTRN	RESTORE_MAP:NEAR
	EXTRN	SAVE_USER_MAP:NEAR
	EXTRN	RESTORE_USER_MAP:NEAR
	i_need	BUF_EMS_SAFE_FLAG,BYTE
	i_need	BUF_EMS_MODE,BYTE
	i_need	CURADD,WORD
ENDIF


Break	<DSKREAD -- PHYSICAL DISK READ>

; Inputs:
;	DS:BX = Transfer addr
;	CX = Number of sectors
;	[HIGH_SECTOR] = Absolute record number (HIGH)
;	DX = Absolute record number	       (LOW)
;	ES:BP = Base of drive parameters
; Function:
;	Call BIOS to perform disk read
; Outputs:
;	DI = CX on entry
;	CX = Number of sectors unsuccessfully transfered
;	AX = Status word as returned by BIOS (error code in AL if error)
;	Zero set if OK (from BIOS) (carry clear)
;	Zero clear if error (carry clear)
; SI Destroyed, others preserved

	procedure   DskRead,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	Assert	ISDPB,<ES,BP>,"DskRead"
	PUSH	CX
	MOV	AH,ES:[BP.dpb_media]
	MOV	AL,ES:[BP.dpb_UNIT]
	PUSH	BX
	PUSH	ES
	invoke	SETREAD
	JMP	DODSKOP

Break	<DWRITE -- SEE ABOUT WRITING>

; Inputs:
;	DS:BX = Transfer address
;	CX = Number of sectors
;	[HIGH_SECTOR] = Absolute record number (HIGH)
;	DX = Absolute record number	       (LOW)
;	ES:BP = Base of drive parameters
;	[ALLOWED] must be set in case HARDERR called
; Function:
;	Calls BIOS to perform disk write. If BIOS reports
;	errors, will call HARDERRRW for further action.
; Output:
;	Carry set if error (currently, user FAILed to I 24)
; BP preserved. All other registers destroyed.

	entry	DWRITE
ASSUME	DS:NOTHING,ES:NOTHING

	Assert	ISDPB,<ES,BP>,"DWrite"
	CALL	DSKWRITE
	retz			; Carry clear
	MOV	BYTE PTR [READOP],1
	invoke	HARDERRRW
	CMP	AL,1		; Check for retry
	JZ	DWRITE
	CMP	AL,3		; Check for FAIL
	CLC
	JNZ	NO_CAR2 	; Ignore
	STC
NO_CAR2:
	return

Break	<DSKWRITE -- PHYSICAL DISK WRITE>

; Inputs:
;	DS:BX = Transfer addr
;	CX = Number of sectors
;	DX = Absolute record number	       (LOW)
;	[HIGH_SECTOR] = Absolute record number (HIGH)
;	ES:BP = Base of drive parameters
; Function:
;	Call BIOS to perform disk read
; Outputs:
;	DI = CX on entry
;	CX = Number of sectors unsuccessfully transfered
;	AX = Status word as returned by BIOS (error code in AL if error)
;	Zero set if OK (from BIOS) (carry clear)
;	Zero clear if error (carry clear)
; SI Destroyed, others preserved

	entry	DSKWRITE
ASSUME	DS:NOTHING,ES:NOTHING

	Assert	ISDPB,<ES,BP>,"DskWrite"
	PUSH	CX
	MOV	AH,ES:[BP.dpb_media]
	MOV	AL,ES:[BP.dpb_UNIT]
	PUSH	BX
	PUSH	ES
	invoke	SETWRITE
DODSKOP:
	MOV	CX,DS		; Save DS
	POP	DS		; DS:BP points to DPB
	PUSH	DS
	LDS	SI,DS:[BP.dpb_driver_addr]
	invoke	DEVIOCALL2
	MOV	DS,CX		; Restore DS
	POP	ES		; Restore ES
	POP	BX
	MOV	CX,[CALLSCNT]	; Number of sectors transferred
	POP	DI
	SUB	CX,DI
	NEG	CX		; Number of sectors not transferred
	MOV	AX,[DEVCALL.REQSTAT]
	MOV	[IFS_DRIVER_ERR],AX ;IFS. save it for IFS			;AN000;
	TEST	AX,STERR
	return
EndProc DskRead



Break	<HardErrRW - map extended errors and call harderr>

; Inputs:
;	AX is error code from read or write
;	Other registers set as per HARDERR
; Function:
;	Checks the error code for special extended
;	errors and maps them if needed. Then invokes
;	Harderr
; Outputs:
;	Of HARDERR
; AX may be modified prior to call to HARDERR.
; No other registers altered.

	procedure   HARDERRRW,near
ASSUME	DS:NOTHING,ES:NOTHING

	CMP	AL,error_I24_wrong_disk
	JNZ	DO_ERR				; Nothing to do
	PUSH	DS
	PUSH	SI
	LDS	SI,[CALLVIDRW]			; Get pointer from dev
	MOV	WORD PTR [EXTERRPT+2],DS	; Set ext err pointer
	MOV	WORD PTR [EXTERRPT],SI
	POP	SI
	POP	DS
DO_ERR:
	invoke	HARDERR
	return

EndProc HARDERRRW

Break	<SETUP -- SETUP A DISK READ OR WRITE FROM USER>

; Inputs:
;	ES:DI point to SFT (value also in THISSFT)
;	[DMAADD] contains transfer address
;	CX = Byte count
;   WARNING Stack must be clean, two ret addrs on stack, 1st of caller,
;		2nd of caller of caller.
; Outputs:
;	    CX = byte count
;	    [THISDPB] = Base of drive parameters if file
;		      = Pointer to device header if device or NET
;	    ES:DI Points to SFT
;	    [NEXTADD] = Displacement of disk transfer within segment
;	    [TRANS] = 0 (No transfers yet)
;	    [BYTPOS] = Byte position in file
;
;	The following fields are relevant to local files (not devices) only:
;
;	    [SECPOS] = Position of first sector (local files only)
;	    [BYTSECPOS] = Byte position in first sector (local files only)
;	    [CLUSNUM] = First cluster (local files only)
;	    [SECCLUSPOS] = Sector within first cluster (local files only)
;	    [THISDRV] = Physical unit number (local files only)
;
;      RETURNS ONE LEVEL UP WITH:
;	   CX = 0
;	   CARRY = Clear
;	IF AN ERROR IS DETECTED
; All other registers destroyed

	procedure   SETUP,NEAR
	DOSAssume   CS,<DS>,"SetUp"
	ASSUME	ES:NOTHING

	Assert	    ISSFT,<ES,DI>,"SetUp"
	LDS	SI,ES:[DI.sf_devptr]
ASSUME	DS:NOTHING
	MOV	WORD PTR [THISDPB+2],DS
	context DS
	MOV	WORD PTR [THISDPB],SI
	MOV	BX,WORD PTR [DMAADD]
	MOV	[NEXTADD],BX		;Set NEXTADD to start of Xaddr
	MOV	BYTE PTR [TRANS],0	;No transferes
	MOV	AX,WORD PTR ES:[DI.sf_Position]
	MOV	DX,WORD PTR ES:[DI.sf_Position+2]
	MOV	WORD PTR [BYTPOS+2],DX	;Set it
	MOV	WORD PTR [BYTPOS],AX
	TEST	ES:[DI.sf_flags],sf_isnet + devid_device
	JNZ	NOSETSTUFF		;Following not done on devs or NET
	PUSH	ES
	LES	BP,[THISDPB]		;Point at the DPB
	Assert	ISDPB,<ES,BP>,"Setup"
	MOV	BL,ES:[BP.dpb_drive]
	MOV	[THISDRV],BL		;Set THISDRV
	MOV	BX,ES:[BP.dpb_sector_size]
;	CMP	DX,BX		; See if divide will overflow
;	JNC	EOFERR		; for 16 bit sector
;; 32 bit divide
	invoke	DIV32			      ; F.C. >32mb   ;AN000;
	MOV	WORD PTR [SECPOS],AX	      ; F.C. >32mb   ;AN000;
	MOV	BX,[HIGH_SECTOR]	      ; F.C. >32mb   ;AN000;
	MOV	WORD PTR [SECPOS+2],BX	      ; F.C. >32mb   ;AN000;

	MOV	[BYTSECPOS],DX
	MOV	DX,AX
	AND	AL,ES:[BP.dpb_cluster_mask]
	MOV	[SECCLUSPOS],AL
	MOV	AX,CX		; Save byte count
;	MOV	CL,ES:[BP.dpb_cluster_shift]
	PUSH	WORD PTR [SECPOS+2]	     ; F.C. >32mb	   ;AN000;
	POP	[HIGH_SECTOR]		     ; F.C. >32mb	   ;AN000;
	PUSH	AX			     ; F.C. >32mb save ax  ;AN000;
	MOV	AX,DX			     ; F.C. >32mb ax=dx    ;AN000;
	invoke	SHR32			     ; F.C. >32mb shift ax ;AN000;
	MOV	DX,AX			     ; F.C. >32mb dx=ax    ;AN000;
	POP	AX			     ; F.C. >32mb restore dx ;AN000;

;	SHR	DX,CL
	CMP	DX,ES:[BP.dpb_max_cluster]   ;>32mb  if > disk size ;AN000;	;AN000;
	JA	EOFERR			     ;>32mb    then EOF     ;AN000;	;AN000;

	MOV	[CLUSNUM],DX
	POP	ES		; ES:DI point to SFT
	MOV	CX,AX		; Put byte count back in CX
NOSETSTUFF:
	MOV	AX,CX		; Need it in AX too
	ADD	AX,WORD PTR [DMAADD]	 ; See if it will fit in one segment
	JNC	OK		; Must be less than 64K
	MOV	AX,WORD PTR [DMAADD]
	NEG	AX		; Amount of room left in segment (know
				;    less than 64K since max value of CX
				;    is FFFF).
	JNZ	NoDec
	DEC	AX
NoDec:
	MOV	CX,AX		; Can do this much
	JCXZ	NOROOM		; Silly user gave Xaddr of FFFF in segment
OK:
	return

EOFERR:
	POP	ES		; ES:DI point to SFT
	XOR	CX,CX		; No bytes read
;;;;;;;;;;; 7/18/86
;	MOV	BYTE PTR [DISK_FULL],1	    ; set disk full flag
;;;;;;;;;;;
NOROOM:
	POP	BX		; Kill return address
	CLC
	return			; RETURN TO CALLER OF CALLER
EndProc SETUP

Break	<BREAKDOWN -- CUT A USER READ OR WRITE INTO PIECES>

; Inputs:
;	CX = Length of disk transfer in bytes
;	ES:BP = Base of drive parameters
;	[BYTSECPOS] = Byte position witin first sector
; Outputs:
;	[BYTCNT1] = Bytes to transfer in first sector
;	[SECCNT] = No. of whole sectors to transfer
;	[BYTCNT2] = Bytes to transfer in last sector
; AX, BX, DX destroyed. No other registers affected.

	procedure   BREAKDOWN,near
	DOSAssume   CS,<DS>,"BreakDown"
	ASSUME	ES:NOTHING

	Assert	    ISDPB,<ES,BP>,"BreakDown"
	MOV	AX,[BYTSECPOS]
	MOV	BX,CX
	OR	AX,AX
	JZ	SAVFIR		; Partial first sector?
	SUB	AX,ES:[BP.dpb_sector_size]
	NEG	AX		; Max number of bytes left in first sector
	SUB	BX,AX		; Subtract from total length
	JAE	SAVFIR
	ADD	AX,BX		; Don't use all of the rest of the sector
	XOR	BX,BX		; And no bytes are left
SAVFIR:
	MOV	[BYTCNT1],AX
	MOV	AX,BX
	XOR	DX,DX
	DIV	ES:[BP.dpb_sector_size]  ; How many whole sectors?
	MOV	[SECCNT],AX
	MOV	[BYTCNT2],DX	; Bytes remaining for last sector
	OR	DX,[BYTCNT1]
	retnz			; NOT (BYTCNT1 = BYTCNT2 = 0)
	CMP	AX,1
	retnz
	MOV	AX,ES:[BP.dpb_sector_size]	 ; Buffer EXACT one sector I/O
	MOV	[BYTCNT2],AX
	MOV	[SECCNT],DX		; DX = 0
RET45:
	return
EndProc BreakDown

; ES:DI points to SFT. This entry used by NET_READ
; Carry set if to return error (CX=0,AX=error_sharing_violation).
; Else do retrys.
; ES:DI,DS,CX preserved

	procedure READ_LOCK_VIOLATION,NEAR
	DOSAssume   CS,<DS>,"Read_Lock_Violation"
	ASSUME	ES:NOTHING

	Assert	    ISSFT,<ES,DI>,"ReadLockViolation"

	MOV	[READOP],0
ERR_ON_CHECK:
	TEST	ES:[DI.sf_mode],sf_isfcb
	JNZ	HARD_ERR
	PUSH	CX
	MOV	CL,BYTE PTR ES:[DI.sf_mode]
	AND	CL,sharing_mask
	CMP	CL,sharing_compat
	POP	CX
	JNE	NO_HARD_ERR
HARD_ERR:
	invoke	LOCK_VIOLATION
	retnc				; User wants Retrys
NO_HARD_ERR:
	XOR	CX,CX			;No bytes transferred
	MOV	AX,error_lock_violation
	STC
	return

EndProc READ_LOCK_VIOLATION

; Same as READ_LOCK_VIOLATION except for READOP.
; This entry used by NET_WRITE
	procedure WRITE_LOCK_VIOLATION,NEAR
	DOSAssume   CS,<DS>,"Write_Lock_Violation"
	ASSUME	ES:NOTHING
	Assert	    ISSFT,<ES,DI>,"WriteLockViolation"

	MOV	[READOP],1
	JMP	ERR_ON_CHECK

EndProc WRITE_LOCK_VIOLATION


Break	<DISKREAD -- PERFORM USER DISK READ>

; Inputs:
;	Outputs of SETUP
; Function:
;	Perform disk read
; Outputs:
;    Carry clear
;	CX = No. of bytes read
;	ES:DI point to SFT
;	SFT offset and cluster pointers updated
;    Carry set
;	CX = 0
;	ES:DI point to SFT
;	AX has error code

	procedure   DISKREAD,NEAR
	DOSAssume   CS,<DS>,"DiskRead"
	ASSUME	ES:NOTHING

	Assert	ISSFT,<ES,DI>,"DISKREAD"
	PUSH	ES:[DI.sf_firclus]	; set up 1st cluster # for FastSeek
	POP	[FSeek_firclus] 	; 11/5/86

	MOV	AX,WORD PTR ES:[DI.sf_size]
	MOV	BX,WORD PTR ES:[DI.sf_size+2]
	SUB	AX,WORD PTR [BYTPOS]
	SBB	BX,WORD PTR [BYTPOS+2]
	JB	RDERR			;Read starts past EOF
	JNZ	ENUF			;More than 64k to EOF
	OR	AX,AX
	JZ	RDERR			;Read starts at EOF
	CMP	AX,CX
	JAE	ENUF			;I/O fits
	MOV	CX,AX			;Limit read to up til EOF
ENUF:
	invoke	CHECK_READ_LOCK 	;IFS. check read lock			 ;AN000;
	JNC	Read_Ok 		; There are no locks
	return

READ_OK:
	LES	BP,[THISDPB]
	Assert	ISDPB,<ES,BP>,"DISKREAD/ReadOK"
	MOV	AL,ES:[BP.dpb_drive]	; set up drive # for FastSeek
	MOV	[FSeek_drive],AL	; 11/5/86  ;AN000;

	CALL	BREAKDOWN
	MOV	CX,[CLUSNUM]
	invoke	FNDCLUS
;------------------------------------------------------------------------
IF	NOT IBMCOPYRIGHT
	JC	SET_ACC_ERR_DS		; fix to take care of I24 fail
					; migrated from 330a - HKN
ENDIF
;------------------------------------------------------------------------
	OR	CX,CX
	JZ	SKIPERR
RDERR:
	MOV	[DISK_FULL],1		;MS. EOF detection  ;AN000;
	MOV	AH,0EH			;MS. read/data/fail ;AN000;
	transfer WRTERR22
RDLASTJ:JMP	RDLAST
SETSFTJ2: JMP	SETSFT

CANOT_READ:
	POP	CX		; Clean stack
	POP	CX
	POP	BX

	entry	SET_ACC_ERR_DS
ASSUME	DS:NOTHING,ES:NOTHING
	Context DS

	entry	SET_ACC_ERR
	DOSAssume   CS,<DS>,"SET_ACC_ERR"

	XOR	CX,CX
	MOV	AX,error_access_denied
	STC
	return

SKIPERR:
	MOV	[LASTPOS],DX
	MOV	[CLUSNUM],BX
	CMP	[BYTCNT1],0
	JZ	RDMID
	invoke	BUFRD
	JC	SET_ACC_ERR_DS
RDMID:
	CMP	[SECCNT],0
	JZ	RDLASTJ
	invoke	NEXTSEC
	JC	SETSFTJ2
	MOV	BYTE PTR [TRANS],1	; A transfer is taking place
ONSEC:
	MOV	DL,[SECCLUSPOS]
	MOV	CX,[SECCNT]
	MOV	BX,[CLUSNUM]
RDLP:
	invoke	OPTIMIZE
	JC	SET_ACC_ERR_DS
	PUSH	DI
	PUSH	AX
	PUSH	BX
	MOV	[ALLOWED],allowed_RETRY + allowed_FAIL + allowed_IGNORE
	MOV	DS,WORD PTR [DMAADD+2]
ASSUME	DS:NOTHING
	PUSH	DX
	PUSH	CX
	invoke	SET_RQ_SC_PARMS 	 ;LB. do this for SC		       ;AN000;

IF	BUFFERFLAG
	pushf
	cmp	[BUF_EMS_SAFE_FLAG], 1
	je	safe_read
	call	save_map
	call	restore_user_map
safe_read:
	popf
ENDIF

	invoke	DREAD

IF	BUFFERFLAG
	pushf
	cmp	[BUF_EMS_SAFE_FLAG], 1
	je	safe_mapping
	call	save_user_map
	call	restore_map
safe_mapping:
	popf
ENDIF

	POP	BX
	POP	DX
	JNC	SKP_CANOT_READ
	JMP	CANOT_READ
SKP_CANOT_READ:
	MOV	[TEMP_VAR],BX		  ;LB. save sector count		;AN000;
	MOV	[TEMP_VAR2],DX		  ;LB. 1st sector			;AN000;
SCAN_NEXT:
;;;;;;; invoke	GETCURHEAD		  ;LB. get buffer header		;AN000;
	PUSH	DX			  ;LB. save regs			;AN000;
	PUSH	AX			  ;LB.					;AN000;
	PUSH	BX			  ;LB.					;AN000;
	MOV	AX,DX			  ;LB.
;	MOV	DX,[HIGH_SECTOR]	  ;LB. HASH(sector#) and get entry #	;AN000;
	XOR	DX,DX			  ;LB. to avoid divide overflow 	;AN000;
	DIV	[BUF_HASH_COUNT]	  ;LB. get remainder			;AN000;
	ADD	DX,DX			  ;LB. 8 bytes per entry		;AN000;
	ADD	DX,DX			  ;LB.					;AN000;
	ADD	DX,DX			  ;LB. times 8				;AN000;

	LDS	DI,[BUF_HASH_PTR]	  ;LB. get Hash Table addr		;AN000;
	ADD	DI,DX			  ;LB position to entry 		;AN000;
	CMP	[DI.Dirty_Count],0	  ;LB dirty hash entry ?		;AN000;
	JNZ	yesdirty		  ;LB yes and map it			;AN000;
	POP	BX			  ;LB.					;AN000;
	POP	AX			  ;LB.					;AN000;
	POP	DX			  ;LB.					;AN000;

IF	NOT	BUFFERFLAG
	JMP	SHORT end_scan		  ;LB.					;AN000;
ELSE
	JMP	END_SCAN
ENDIF

yesdirty:
	MOV	WORD PTR [CurHashEntry+2],DS ;LB. update current Hash entry ptr ;AN000;
	MOV	WORD PTR [CurHashEntry],DI ;LB. 				;AN000;
	MOV	WORD PTR [LASTBUFFER],-1   ;LB. invalidate last buffer		;AN000;
	MOV	BX,[DI.EMS_PAGE_NUM]	  ;LB. logical page			;AN000;

IF	NOT	BUFFERFLAG
	LDS	DI,[DI.BUFFER_BUCKET]	  ;LB. ds:di is 1st buffer addr 	;AN000;
	MOV	[FIRST_BUFF_ADDR],DI	  ;LB. save first buff addr 1/19/88	;AN000;
	invoke	SET_MAP_PAGE		  ;LB. activate handle if EMS there	;AN000;
ELSE
;	int	3
	push	ds
	push	di		; save hash ptr

	LDS	DI,[DI.BUFFER_BUCKET]	  ;ds:di is 1st buffer addr
	POP	AX		; Recall transfer address
	PUSH	AX
	PUSH	DI		; Save search environment
	PUSH	DX		     ; F.C. no need for high sector, <64K
	push	cx

	MOV	DX,[TEMP_VAR2]	     ;LB. get 1st sector #
	SUB	DX,WORD PTR [DI.buf_sector]   ; How far into transfer?
	NEG	DX
	MOV	DI,AX
	MOV	AX,DX
	MOV	CX,ES:[BP.dpb_sector_size]
	MUL	CX
	ADD	DI,AX		; Put the buffer here
	mov	[CURADD], di
	
	pop	cx
	pop	dx
	pop	di

	invoke	SET_MAP_PAGE		  ;LB. activate handle if EMS there	;AN000;
	pop	di			; restore hash ptr.
	pop	ds
	LDS	DI,[DI.BUFFER_BUCKET]	  ;LB. ds:di is 1st buffer addr 	;AN000;
	MOV	[FIRST_BUFF_ADDR],DI	  ;LB. save first buff addr 1/19/88	;AN000;
ENDIF
										;AN000;
	POP	BX			  ;LB.					;AN000;
	POP	AX			  ;LB.					;AN000;
	POP	DX			  ;LB.					;AN000;


	Assert	ISDPB,<ES,BP>,"DISKREAD/RdLp"
	MOV	AL,ES:[BP.dpb_drive]
NXTBUF: 			; Must see if one of these sectors is buffered
	invoke	BUFF_RANGE_CHECK			   ;F.C. >32mb
	JNC	inrange 		   ;LB. 				;AN000;
	mov	DI,[DI.buf_next]	   ;LB. get next buffer 1/19/88 	;AN000;
	JMP	DONXTBUF		   ;LB. 				;AN000;
inrange:
	TEST	[DI.buf_flags],buf_dirty
	JZ	CLBUFF			; Buffer is clean, so OK
; A sector has been read in when a dirty copy of it is in a buffer
; The buffered sector must now be read into the right place
	POP	AX		; Recall transfer address
	PUSH	AX
	PUSH	DI		; Save search environment
	PUSH	DX		     ; F.C. no need for high sector, <64K

	MOV	DX,[TEMP_VAR2]	     ;LB. get 1st sector #
	SUB	DX,WORD PTR [DI.buf_sector]   ; How far into transfer?
	NEG	DX
	MOV	SI,DI
	MOV	DI,AX
	MOV	AX,DX
	MOV	CX,ES:[BP.dpb_sector_size]
	MUL	CX
	ADD	DI,AX		; Put the buffer here
	LEA	SI,[SI].BUFINSIZ
	SHR	CX,1
	PUSH	ES
	MOV	ES,WORD PTR [DMAADD+2]
	REP	MOVSW
	JNC	EVENMOV
	MOVSB
EVENMOV:
	POP	ES
	POP	DX
	POP	DI
	MOV	AL,ES:[BP.dpb_drive]
	invoke	SCANPLACE		 ;LB. done with this chain		;AN000;
	JMP	SHORT end_scan		 ;LB.					;AN000;
CLBUFF:
	invoke	SCANPLACE
DONXTBUF:
	CMP	DI,[FIRST_BUFF_ADDR]	 ;LB. end of buffers			;AN000;
	JNZ	NXTBUF
end_scan:
	ADD	DX,1			 ;LB. next sector #			;AN000;
	ADC	[HIGH_SECTOR],0 	 ;LB.					;AN000;
	DEC	[TEMP_VAR]		 ;LB. decrement count			;AN000;
	JZ	SCAN_DONE		 ;LB. scan next sector			;AN000;
	JMP	SCAN_NEXT		 ;LB. scan next sector			;AN000;
SCAN_DONE:
	Context DS
	POP	CX
	POP	CX
	POP	BX
	JCXZ	RDLAST
	invoke	IsEOF			; test for eof on fat size
	JAE	SETSFT
	MOV	DL,0
	INC	[LASTPOS]	; We'll be using next cluster
	JMP	RDLP

RDLAST:
	MOV	AX,[BYTCNT2]
	OR	AX,AX
	JZ	SETSFT
	MOV	[BYTCNT1],AX
	invoke	NEXTSEC
	JC	SETSFT
	MOV	[BYTSECPOS],0
	invoke	BUFRD
	JNC	SETSFT
	JMP	SET_ACC_ERR_DS

; Inputs:
;	[NEXTADD],[CLUSNUM],[LASTPOS] set to determine transfer size
;		and set cluster fields
; Function:
;	Update [THISSFT] based on the transfer
; Outputs:
;	sf_position, sf_lstclus, and sf_cluspos updated
;	ES:DI points to [THISSFT]
;	CX No. of bytes transferred
;	Carry clear

	entry	SETSFT
	DOSAssume   CS,<DS>,"SetSFT"
	ASSUME	ES:NOTHING

	LES	DI,[THISSFT]

; Same as SETSFT except ES:DI already points to SFT
	entry	SETCLUS
	DOSAssume   CS,<DS>,"SetClus"
	ASSUME	ES:NOTHING

	Assert	ISSFT,<ES,DI>,"SetClus"
	MOV	CX,[NEXTADD]
	SUB	CX,WORD PTR [DMAADD]	 ; Number of bytes transfered
	TEST	ES:[DI.sf_flags],devid_device
	JNZ	ADDREC			 ; don't set clusters if device
	MOV	AX,[CLUSNUM]
	MOV	ES:[DI.sf_lstclus],AX
	MOV	AX,[LASTPOS]
	MOV	ES:[DI.sf_cluspos],AX

; Inputs:
;	ES:DI points to SFT
;	CX is No. Bytes transferred
; Function:
;	Update the SFT offset based on the transfer
; Outputs:
;	sf_position updated to point to first byte after transfer
;	ES:DI points to SFT
;	CX No. of bytes transferred
;	Carry clear

	entry	AddRec
	DOSAssume   CS,<DS>,"AddRec"
	ASSUME	ES:NOTHING

	Assert	ISSFT,<ES,DI>,"AddRec"
	JCXZ	RET28		; If no records read,  don't change position
	ADD	WORD PTR ES:[DI.sf_position],CX  ; Update current position
	ADC	WORD PTR ES:[DI.sf_position+2],0
RET28:	CLC
	return
EndProc DISKREAD

CODE	ENDS
    END
