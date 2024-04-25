;	SCCSID = @(#)fat.asm	1.3 85/08/15
;	SCCSID = @(#)fat.asm	1.3 85/08/15
TITLE	FAT - FAT maintenance routines
NAME	FAT
; Low level local device routines for performing disk change sequence,
;   setting cluster validity, and manipulating the FAT
;
;   IsEof
;   UNPACK
;   PACK
;   MAPCLUSTER
;   FATREAD_SFT
;   FATREAD_CDS
;   FAT_operation
;
;   Revision history:
;
;   AN000  version Jan. 1988
;    A001  PTM	      -- disk changed for look ahead buffers
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
.cref
.list

FastDiv = TRUE

	i_need	CURBUF,DWORD
	i_need	CLUSSPLIT,BYTE
	i_need	CLUSSAVE,WORD
	i_need	CLUSSEC,DWORD		;F.C. >32mb  ;AN000;
	i_need	THISDRV,BYTE
	i_need	THISDPB,DWORD
	i_need	DEVCALL,BYTE
	i_need	CALLMED,BYTE
	i_need	CALLRBYT,BYTE
	i_need	BUFFHEAD,DWORD
	i_need	CALLXAD,DWORD
	i_need	CALLBPB,DWORD
	i_need	CDSADDR,DWORD
	i_need	CDSCOUNT,BYTE
	i_need	EXTERR,WORD
	i_need	EXTERRPT,DWORD
	i_need	CALLVIDM,DWORD
	i_need	ReadOp,BYTE
	i_need	FAILERR,BYTE
	i_need	ALLOWED,BYTE
	i_need	VOLCHNG_FLAG,BYTE
	i_need	HIGH_SECTOR,WORD
	i_need	BUF_HASH_COUNT,WORD
	i_need	BUF_HASH_PTR,DWORD
	i_need	FIRST_BUFF_ADDR,WORD
	i_need	SC_CACHE_COUNT,WORD	       ;AN001;
	i_need	CURSC_DRIVE,BYTE	       ;AN001;


Break <IsEOF - check the quantity in BX for EOF>

;
; IsEOF - check the fat value in BX for eof.
;
;   Inputs:	ES:BP point to DPB
;		BX has fat value
;   Outputs:	JAE eof
;   Registers modified: none
Procedure IsEof,NEAR
	ASSUME	SS:DOSGROUP,CS:DOSGROUP,DS:NOTHING,ES:NOTHING
	Assert	    ISDPB,<ES,BP>,"IsEOF"
	CMP	ES:[BP.dpb_max_cluster],4096-10 ; is this 16 bit fat?
	JAE	EOF16			; yes, check for eof there
;J.K. 8/27/86
;Modified to accept 0FF0h as an eof. This is to handle the diskfull case
;of any media that has "F0"(Other) as a MediaByte.
;Hopely, this does not create any side effect for those who may use any value
;other than "FF8-FFF" as an Eof for their own file.
	cmp	bx,0FF0h
	je	IsEOF_other
	CMP	BX,0FF8h		; do the 12 bit compare
IsEOF_other:
	return
EOF16:
	CMP	BX,0FFF8h		; 16 bit compare
	return
EndProc IsEof

Break	<UNPACK -- UNPACK FAT ENTRIES>

; Inputs:
;	BX = Cluster number (may be full 16-bit quantity)
;	ES:BP = Base of drive parameters
; Outputs:
;	DI = Contents of FAT for given cluster (may be full 16-bit quantity)
;	Zero set means DI=0 (free cluster)
;	Carry set means error (currently user FAILed to I 24)
; SI Destroyed, No other registers affected. Fatal error if cluster too big.

	procedure   UNPACK,NEAR
	DOSAssume   CS,<DS>,"UnPack"
	ASSUME	ES:NOTHING

	Assert	    ISDPB,<ES,BP>,"Unpack"
	CMP	BX,ES:[BP.dpb_max_cluster]
	JA	HURTFAT
	CALL	MAPCLUSTER
ASSUME	DS:NOTHING
	jc	DoContext
	MOV	DI,[DI]
	JNZ	High12			; MZ if high 12 bits, go get 'em
	MOV	SI,ES:[BP.dpb_max_cluster]  ; MZ is this 16-bit fat?
	CMP	SI,4096-10
	JB	Unpack12		; MZ No, go 'AND' off bits
	OR	DI,DI			; MZ set zero condition code, clears carry
	JMP	SHORT DoContext 	; MZ go do context

High12:
	SHR	DI,1
	SHR	DI,1
	SHR	DI,1
	SHR	DI,1
Unpack12:
	AND	DI,0FFFH		; Clears carry
DoContext:
	PUSH	SS
	POP	DS
	return

HURTFAT:
	MOV	ES:[BP.dpb_free_cnt],-1 ; Err in FAT must force recomp of freespace
	PUSH	AX
	MOV	AH,allowed_fail + 80h
	MOV	Allowed,allowed_fail
;
; Signal Bad FAT to INT int_fatal_abort handler.  We have an invalid cluster.
;
	MOV	DI,0FFFH		; In case INT int_fatal_abort returns (it shouldn't)
	invoke	FATAL
	CMP	AL,3
	CLC
	JNZ	OKU_RET 		; Try to ignore bad FAT
	STC				; User said FAIL
OKU_RET:
	POP	AX
	return
EndProc UNPACK

Break	<PACK -- PACK FAT ENTRIES>

; Inputs:
;	BX = Cluster number
;	DX = Data
;	ES:BP = Pointer to drive DPB
; Outputs:
;	The data is stored in the FAT at the given cluster.
;	SI,DX,DI all destroyed
;	Carry set means error (currently user FAILed to I 24)
;	No other registers affected

	procedure   PACK,NEAR
	DOSAssume   CS,<DS>,"Pack"
	ASSUME	ES:NOTHING

	Assert	    ISDPB,<ES,BP>,"Pack"
	CALL	MAPCLUSTER
ASSUME	DS:NOTHING
	JC	DoContext
	MOV	SI,[DI]
	JZ	Aligned 		; byte (not nibble) aligned
	PUSH	CX			; move data to upper 12 bits
	MOV	CL,4
	SHL	DX,CL
	POP	CX
	AND	SI,0FH			; leave in original low 4 bits
	JMP	SHORT PACKIN
ALIGNED:
	CMP	ES:[BP.dpb_max_cluster],4096-10 ; MZ 16 bit fats?
	JAE	Pack16			; MZ yes, go clobber original data
	AND	SI,0F000H		; MZ leave in upper 4 bits of original
	AND	DX,0FFFh		; MZ store only 12 bits
	JMP	SHORT PackIn		; MZ go store
Pack16:
	XOR	SI,SI			; MZ no original data
PACKIN:
	OR	SI,DX
	MOV	[DI],SI
	LDS	SI,[CURBUF]
	TEST	[SI.buf_flags],buf_dirty  ;LB. if already dirty 		;AN000;
	JNZ	yesdirty		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	[SI.buf_flags],buf_dirty  ;LB.					;AN000;
yesdirty:				  ;LB.					;AN000;
	CMP	BYTE PTR [CLUSSPLIT],0
	Context DS
	retz				; Carry clear
	PUSH	AX
	PUSH	BX
	PUSH	CX
	MOV	AX,[CLUSSAVE]
	MOV	DS,WORD PTR [CURBUF+2]
ASSUME	DS:NOTHING
	ADD	SI,BUFINSIZ
	MOV	[SI],AH
	Context DS
	PUSH	AX
	MOV	DX,WORD PTR [CLUSSEC+2] 	   ;F.C. >32mb		       ;AN000;
	MOV	WORD PTR [HIGH_SECTOR],DX	   ;F.C. >32mb		       ;AN000;

	MOV	DX,WORD PTR [CLUSSEC]
	MOV	SI,1
	XOR	AL,AL
	invoke	GETBUFFRB
	POP	AX
	JC	POPP_RET
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	TEST	[DI.buf_flags],buf_dirty  ;LB. if already dirty 		;AN000;
	JNZ	yesdirty2		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	[DI.buf_flags],buf_dirty
yesdirty2:
	ADD	DI,BUFINSIZ
	DEC	DI
	ADD	DI,ES:[BP.dpb_sector_size]
	MOV	[DI],AL
	CLC
POPP_RET:
	PUSH	SS
	POP	DS
	POP	CX
	POP	BX
	POP	AX
	return

EndProc PACK

Break	<MAPCLUSTER - BUFFER A FAT SECTOR>

; Inputs:
;	ES:BP Points to DPB
;	BX Is cluster number
; Function:
;	Get a pointer to the cluster
; Outputs:
;	DS:DI Points to contents of FAT for given cluster
;	DS:SI Points to start of buffer
;	Zero Not set if cluster data is in high 12 bits of word
;	Zero set if cluster data is in low 12 or 16 bits
;	Carry set if failed.
; SI is destroyed.

	procedure   MAPCLUSTER,NEAR
	DOSAssume   CS,<DS>,"MapCluster"
	ASSUME	ES:NOTHING

	Assert	    ISDPB,<ES,BP>,"MapCluster"
	MOV	BYTE PTR [CLUSSPLIT],0
	SaveReg <AX,BX,CX,DX>
	MOV	AX,BX			; AX = BX
	MOV	CX,4096-10
	CMP	ES:[BP.dpb_max_cluster],CX  ; MZ 16 bit fat?
	JAE	Map16			; MZ yes, do 16 bit algorithm
	SHR	AX,1			; AX = BX/2
Map16:					; MZ skip prev => AX=2*BX
	XOR	DI,DI			; >32mb     fat 			;AN000;
	ADD	AX,BX			; AX = 1.5*fat = byte offset in fat
	ADC	DI,0			; >32mb     fat 			;AN000;
DoConvert:
	MOV	CX,ES:[BP.dpb_sector_size]
IF FastDiv
;
; Gross hack:  99% of all disks have 512 bytes per sector.  We test for this
; case and apply a really fast algorithm to get the desired results
;
; Divide method takes 158 (XOR and DIV)
; Fast method takes 20
;
; This saves a bunch.
;
	CMP	CX,512			; 4	Is this 512 byte sector?
	JZ	Nodiv			;F.C. >32mb				;AN000;
	JMP	DoDiv			; 4/16	No, go do divide
Nodiv:					;F.C. >32mb				;AN000;
	MOV	DX,AX			; 2	get set for remainder
	AND	DX,512-1		; 4	Form remainder
	MOV	AL,AH			; 2
	SHR	AL,1			; 2
	CBW				; 2	Fast divide by 512
	OR	DI,DI			;>32mb	>64k ?				;AN000;
	JZ	g64k			;>32mb	no				;AN000;
	OR	AX,80H			;>32mb					;AN000;
g64k:
ELSE
	XOR	DX,DX			; 3
	DIV	CX			; 155 AX is FAT sector # DX is sector index
ENDIF
DivDone:
	ADD	AX,ES:[BP.dpb_first_FAT]
	DEC	CX			; CX is sector size - 1
	SaveReg <AX,DX,CX>
	MOV	DX,AX
	MOV	[HIGH_SECTOR],0 	;F.C. >32mb  low sector #
	XOR	AL,AL
	MOV	SI,1
	invoke	GETBUFFRB
	RestoreReg  <CX,AX,DX>		; CX is sec siz-1, AX is offset in sec
	JC	MAP_POP
	LDS	SI,[CURBUF]
ASSUME	DS:NOTHING
	LEA	DI,[SI.BufInSiz]
	ADD	DI,AX
	CMP	AX,CX
	JNZ	MAPRET
	MOV	AL,[DI]
	Context DS
	INC	BYTE PTR [CLUSSPLIT]
	MOV	BYTE PTR [CLUSSAVE],AL
	MOV	WORD PTR [CLUSSEC],DX
	MOV	WORD PTR [CLUSSEC+2],0	      ;F.C. >32mb			;AN000;
	INC	DX
	MOV	[HIGH_SECTOR],0 	      ;F.C. >32mb  FAT sector <32mb	;AN000;
	XOR	AL,AL
	MOV	SI,1
	invoke	GETBUFFRB
	JC	MAP_POP
	LDS	SI,[CURBUF]
ASSUME	DS:NOTHING
	LEA	DI,[SI.BufInSiz]
	MOV	AL,[DI]
	Context DS
	MOV	BYTE PTR [CLUSSAVE+1],AL
	MOV	DI,OFFSET DOSGROUP:CLUSSAVE
MAPRET:
	RestoreReg  <DX,CX,BX>
	XOR	AX,AX			; MZ allow shift to clear carry
	CMP	ES:[BP.dpb_max_cluster],4096-10 ; MZ is this 16-bit fat?
	JAE	MapSet			; MZ no, set flags
	MOV	AX,BX
MapSet:
	TEST	AL,1			; set zero flag if not on boundary
	RestoreReg  <AX>
	return

MAP_POP:
	RestoreReg  <DX,CX,BX,AX>
	return
IF FastDiv
DoDiv:
	XOR	DX,DX			; 3
	DIV	CX			; 155 AX is FAT sector # DX is sector index
	JMP	DivDone 		;15 total=35
ENDIF

EndProc MAPCLUSTER

Break	<FATREAD_SFT/FATREAD_CDS -- CHECK DRIVE GET FAT>

; Inputs:
;	ES:DI points to an SFT for the drive of intrest (local only,
;		giving a NET SFT will produce system crashing results).
;	DS DOSGROUP
; Function:
;	Can be used by an SFT routine (like CLOSE) to invalidate buffers
;	if disk changed.
;	In other respects, same as FATREAD_CDS.
;	(note ES:DI destroyed!)
; Outputs:
;	Carry set if error (currently user FAILed to I 24)
; NOTE: This routine may cause FATREAD_CDS to "miss" a disk change
;	as far as invalidating curdir_ID is concerned.
;	Since getting a true disk changed on this call is a screw up
;	anyway, that's the way it goes.

	procedure  FATREAD_SFT,NEAR
	DOSAssume   CS,<DS>,"FATRead_SFT"
	ASSUME	ES:NOTHING

	LES	BP,ES:[DI.sf_devptr]
	Assert	    ISDPB,<ES,BP>,"FatReadSFT"
	MOV	AL,ES:[BP.dpb_drive]
	MOV	[THISDRV],AL
	invoke	GOTDPB			;Set THISDPB
	CALL	FAT_GOT_DPB
	return
EndProc FATREAD_SFT

; Inputs:
;	DS:DOSGROUP
;	ES:DI points to an CDS for the drive of intrest (local only,
;		giving a NET or NUL CDS will produce system crashing results).
; Function:
;	If disk may have been changed, media is determined and buffers are
;	flagged invalid. If not, no action is taken.
; Outputs:
;	ES:BP = Drive parameter block
;	[THISDPB] = ES:BP
;	[THISDRV] set
;	Carry set if error (currently user FAILed to I 24)
; DS preserved , all other registers destroyed

	procedure   FATREAD_CDS,NEAR
	DOSAssume   CS,<DS>,"FATRead_CDS"
	ASSUME	ES:NOTHING

	PUSH	ES
	PUSH	DI
	LES	BP,ES:[DI.curdir_devptr]
	Assert	ISDPB,<ES,BP>,"FatReadCDS"
	MOV	AL,ES:[BP.dpb_drive]
	MOV	[THISDRV],AL
	invoke	GOTDPB			;Set THISDPB
	CALL	FAT_GOT_DPB
	POP	DI			;Get back CDS pointer
	POP	ES
	retc
	JNZ	NO_CHANGE		;Media NOT changed
; Media changed. We now need to find all CDS structures which use this
; DPB and invalidate their ID pointers.
MED_CHANGE:
	XOR	AX,AX
	DEC	AX			;AX = -1
	PUSH	DS
	MOV	CL,[CDSCOUNT]
	XOR	CH,CH			; CX is number of structures
	LDS	SI,ES:[DI.curdir_devptr] ; Find all CDS with this devptr
ASSUME	DS:NOTHING
	LES	DI,[CDSADDR]		; Start here
CHECK_CDS:
	TEST	ES:[DI.curdir_flags],curdir_isnet
	JNZ	NEXTCDS 		; Leave NET guys alone!!
	PUSH	ES
	PUSH	DI
	LES	DI,ES:[DI.curdir_devptr]
	invoke	POINTCOMP
	POP	DI
	POP	ES
	JNZ	NEXTCDS 		; CDS not for this drive
	TEST	ES:[DI.curdir_ID],AX
	JZ	NEXTCDS 		; If root, leave root
	MOV	ES:[DI.curdir_ID],AX	; else invalid
NEXTCDS:
	ADD	DI,SIZE curdir_list	; Point to next CDS
	LOOP	CHECK_CDS
	POP	DS
	DOSAssume   CS,<DS>,"FAT/NextCDS"
NO_CHANGE:
	LES	BP,[THISDPB]
	CLC
	return
EndProc FATREAD_CDS

Break	<Fat_Operation - miscellaneous fat stuff>

	procedure   FAT_operation,NEAR
FATERR:
	DOSAssume   CS,<DS>,"FATERR"
	MOV	ES:[BP.dpb_free_cnt],-1 ; Err in FAT must force recomp of freespace
	AND	DI,STECODE		; Put error code in DI
	MOV	[ALLOWED],allowed_FAIL + allowed_RETRY
	MOV	AH,2 + allowed_FAIL + allowed_RETRY ; While trying to read FAT
	MOV	AL,BYTE PTR [THISDRV]	 ; Tell which drive
	invoke	FATAL1
	LES	BP,[THISDPB]
	CMP	AL,3
	JNZ	FAT_GOT_DPB		; User said retry
	STC				; User said FAIL
	return

FAT_GOT_DPB:
	Context DS
	MOV	AL,DMEDHL
	MOV	AH,ES:[BP.dpb_UNIT]
	MOV	WORD PTR [DEVCALL],AX
	MOV	BYTE PTR [DEVCALL.REQFUNC],DEVMDCH
	MOV	[DEVCALL.REQSTAT],0
	MOV	AL,ES:[BP.dpb_media]
	MOV	BYTE PTR [CALLMED],AL
	PUSH	ES
	PUSH	DS
	MOV	BX,OFFSET DOSGROUP:DEVCALL
	LDS	SI,ES:[BP.dpb_driver_addr]  ; DS:SI Points to device header
ASSUME	DS:NOTHING
	POP	ES			; ES:BX Points to call header
	invoke	DEVIOCALL2
	Context DS
	POP	ES			; Restore ES:BP
	MOV	DI,[DEVCALL.REQSTAT]
	TEST	DI,STERR
	JNZ	FATERR
	XOR	AH,AH
	XCHG	AH,ES:[BP.dpb_first_access] ; Reset dpb_first_access
	MOV	AL,BYTE PTR [THISDRV]	; Use physical unit number
; See if we had changed volume id by creating one on the diskette
	cmp	[VOLCHNG_FLAG],AL
	jnz	CHECK_BYT
	mov	[VOLCHNG_FLAG],-1
	jmp	GOGETBPB		; Need to get device driver to read in
					; new volume label.
CHECK_BYT:
	OR	AH,BYTE PTR [CALLRBYT]
	JNS	CHECK_ZR		; ns = 0 or 1
	JMP	NEWDSK

CHECK_ZR:
	JZ	CHKBUFFDIRT		; jump if I don't know
	CLC
	return				; If Media not changed (NZ)

DISK_CHNG_ERR:
ASSUME	DS:NOTHING
	PUSH	ES
	PUSH	BP
	LES	BP,ES:[BP.dpb_driver_addr]  ; Get device pointer
	TEST	ES:[BP.SDEVATT],DEVOPCL ; Did it set vol id?
	POP	BP
	POP	ES
	JZ	FAIL_OPJ2		; Nope, FAIL
	PUSH	DS			; Save buffer pointer for ignore
	PUSH	DI
	Context DS
	MOV	[ALLOWED],allowed_FAIL + allowed_RETRY
	PUSH	ES
	LES	DI,[CALLVIDM]		; Get volume ID pointer
	MOV	WORD PTR [EXTERRPT+2],ES
	POP	ES
	MOV	WORD PTR [EXTERRPT],DI
	MOV	AX,error_I24_wrong_disk
	MOV	[READOP],1		; Write
	invoke	HARDERR
	POP	DI			; Get back buffer for ignore
	POP	DS
ASSUME	DS:NOTHING
	CMP	AL,3
FAIL_OPJ2:
	JZ	FAIL_OP
	JMP	FAT_GOT_DPB		; Retry

CHKBUFFDIRT:
	DOSAssume   CS,<DS>,"FAT/ChkBuffDirt"
;	LDS	DI,[BUFFHEAD]
ASSUME	DS:NOTHING
	XOR	DX,DX				 ;LB.				;AN000;
	LDS	DI,[BUF_HASH_PTR]		 ;LB. scan from 1st entry	;AN000;
	MOV	CX,[BUF_HASH_COUNT]		 ;LB. get Hash entry count	;AN000;

scan_dirty:
	CMP	[DI.Dirty_Count],0		 ;LB. if not dirty		;AN000;
	JZ	GETNEXT 			 ;LB.	 get next hash entry	;AN000;
	PUSH	DS				 ;LB. save hash entry addr	;AN000;
	PUSH	DI				 ;LB.				;AN000;
	invoke	Map_Entry			 ;LB.				;AN000;
NBUFFER:				; Look for dirty buffers
	CMP	AL,[DI.buf_ID]
	JNZ	LFNXT			; Not for this unit
	TEST	[DI.buf_flags],buf_dirty
	JZ	LFNXT
	POP	DI				  ;LB. restore regs		 ;AN000;
	POP	DS				  ;LB.				 ;AN000;
	Context DS
	CLC
	return				; There is a dirty buffer, assume Media OK (NZ)

FAIL_OP:
	Context DS
	STC
	return

ASSUME	DS:NOTHING
LFNXT:
	mov	DI,[DI.buf_next]	    ;; 1/19/88
	CMP	DI,[FIRST_BUFF_ADDR]	    ;; 1/19/88
	JNZ	NBUFFER
	POP	DI				  ;LB. restore regs		 ;AN000;
	POP	DS				  ;LB.				 ;AN000;
GETNEXT:
	ADD	DI,size BUFFER_HASH_ENTRY	  ;LB. next entry		 ;AN000;
	LOOP	scan_dirty			  ;LB. scan next entry		 ;AN000;
; If no dirty buffers, assume Media changed
NEWDSK:
	MOV	ES:[BP.dpb_free_cnt],-1 ; Media changed, must re-compute
					; NOTE: It is TECHNICALLY more correct
ASSUME DS:NOTHING
	XOR	DX,DX			;LB.					  ;AN000;
	MOV	[HIGH_SECTOR],DX	;LB. scan from 1st entry		  ;AN000;
	MOV	CX,[BUF_HASH_COUNT]	;LB. get Hash entry count		  ;AN000;

NxtHash:
	invoke	GETCURHEAD		;LB. get Hash entry buffer header	  ;AN000;
					;  to do this AFTER the check for
ASSUME	DS:NOTHING
NXBUFFER:
	CMP	AL,[DI.buf_ID]		; For this drive?
	JZ	OLDDRV2 		;LB.  yes				  ;AN000;
	mov	DI,[DI.buf_next]	;LB.  get next buffer  1/19/88		  ;AN000;
	JMP	SHORT SKPBUFF		;LB.					  ;AN000;
OLDDRV2:
	TEST	[DI.buf_flags],buf_dirty
	JZ	OldDrv
	JMP	Disk_Chng_Err		; Disk changed but dirty buffers
OLDDRV:
	MOV	WORD PTR [DI.buf_ID],(buf_visit SHL 8) OR 0FFH	; Free up buffer
	invoke	SCANPLACE
SKPBUFF:
	CMP	DI,[FIRST_BUFF_ADDR]	;LB.  end of chain  1/19/88		  ;AN000;
	JNZ	NXBUFFER		;LB.  no				  ;AN000;
	INC	DX			;LB.					  ;AN000;
	LOOP	NxtHash 		;LB.					  ;AN000;
	CMP	[SC_CACHE_COUNT],0	;LB.  look ahead buffers ?		  ;AN001;
	JZ	GOGETBPB		;LB.  no				  ;AN001;
	CMP	AL,[CURSC_DRIVE]	;LB.  same as changed drive		  ;AN001;
	JNZ	GOGETBPB		;LB.  no				  ;AN001;
	MOV	[CURSC_DRIVE],-1	;LB.  invalidate look ahead buffers	  ;AN000;
GOGETBPB:
	LDS	DI,ES:[BP.dpb_driver_addr]
	TEST	[DI.SDEVATT],ISFATBYDEV
	JNZ	GETFREEBUF
	context DS
	MOV	BX,2
	CALL	UNPACK			; Read the first FAT sector into CURBUF
FAIL_OPJ:
	JC	FAIL_OP
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	JMP	SHORT GOTGETBUF

GETFREEBUF:
ASSUME	DS:NOTHING
	PUSH	ES			; Get a free buffer for BIOS to use
	PUSH	BP
;	LDS	DI,[BUFFHEAD]
	XOR	DX,DX			     ;LB.  fake to get 1st		  ;AN000;
	MOV	[HIGH_SECTOR],DX	     ;LB.  buffer addr			  ;AN000;
	invoke	GETCURHEAD		     ;LB.				  ;AN000;

	invoke	BUFWRITE
	POP	BP
	POP	ES
	JC	FAIL_OPJ
GOTGETBUF:
	ADD	DI,BUFINSIZ
	MOV	WORD PTR [CALLXAD+2],DS
	Context DS
	MOV	WORD PTR [CALLXAD],DI
	MOV	AL,DBPBHL
	MOV	AH,BYTE PTR ES:[BP.dpb_UNIT]
	MOV	WORD PTR [DEVCALL],AX
	MOV	BYTE PTR [DEVCALL.REQFUNC],DEVBPB
	MOV	[DEVCALL.REQSTAT],0
	MOV	AL,BYTE PTR ES:[BP.dpb_media]
	MOV	[CALLMED],AL
	PUSH	ES
	PUSH	DS
	PUSH	WORD PTR ES:[BP.dpb_driver_addr+2]
	PUSH	WORD PTR ES:[BP.dpb_driver_addr]
	MOV	BX,OFFSET DOSGROUP:DEVCALL
	POP	SI
	POP	DS			; DS:SI Points to device header
ASSUME	DS:NOTHING
	POP	ES			; ES:BX Points to call header
	invoke	DEVIOCALL2
	POP	ES			; Restore ES:BP
	Context DS
	MOV	DI,[DEVCALL.REQSTAT]
	TEST	DI,STERR
	JNZ	FATERRJ
	MOV	AL,BYTE PTR ES:[BP.dpb_media]
	LDS	SI,[CALLBPB]
ASSUME	DS:NOTHING
	MOV	ES:[BP].DPB_next_free,0 ; recycle scanning pointer
	invoke	$SETDPB
	LDS	DI,[CALLXAD]		; Get back buffer pointer
	MOV	AL,BYTE PTR ES:[BP.dpb_FAT_count]
	MOV	[DI.buf_wrtcnt-BUFINSIZ],AL   ;>32mb				;AN000;
	MOV	AX,ES:[BP.dpb_FAT_size]       ;>32mb				;AC000;
	MOV	[DI.buf_wrtcntinc-BUFINSIZ],AX	 ;>32mb Correct buffer info	;AC000;

	Context DS
	XOR	AL,AL			;Media changed (Z), Carry clear
	return

FATERRJ: JMP	FATERR

EndProc FAT_operation

CODE	ENDS
    END
