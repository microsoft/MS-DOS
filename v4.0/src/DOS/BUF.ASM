;	SCCSID = @(#)buf.asm	1.1 85/04/09
TITLE	BUF - MSDOS buffer management
NAME	BUF
; Low level routines for buffer cache management
;
;   GETCURHEAD
;   SET_MAP_PAGE
;   SAVE_MAP
;   RESTORE_MAP
;   SETVISIT
;   ScanPlace
;   PLACEBUF
;   PLACEHEAD
;   PointComp
;   GETBUFFR
;   GETBUFFRB
;   FlushBuf
;   BufWrite
;   SKIPVISIT
;   SET_RQ_SC_PARMS
;
;   Revision history:
;
;	AN000  version 4.00  Jan. 1988
;	A004   PTM 3765 -- Disk reset failed

;	NEW PROCS FOR BUFFERS FIX:

;		SAVE_USER_MAP
;		RESTORE_USER_MAP
;		DETECT_COLLISION
;		SETUP_EMS_BUFFERS
;


;
; get the appropriate segment definitions
;
.xlist
INCLUDE dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
include version.inc
.cref
.list

Installed = TRUE

	i_need	BuffHead,DWORD
	i_need	PreRead,WORD
	i_need	LastBuffer,DWORD
	i_need	CurBuf,DWORD
	i_need	WPErr,BYTE
	i_need	ALLOWED,BYTE
	i_need	FAILERR,BYTE
	i_need	HIGH_SECTOR,WORD	     ; DOS 4.00 >32mb			;AN000;
	i_need	CurHashEntry,DWORD	     ; DOS 4.00 current Hash entry	;AN000;
	i_need	BUF_HASH_PTR,DWORD	     ; DOS 4.00 Hash table pointer	;AN000;
	i_need	BUF_HASH_COUNT,WORD	     ; DOS 4.00 Hash table entries	;AN000;
	i_need	SC_CACHE_PTR,DWORD	     ; DOS 4.00 seconadary cache table	;AN000;
	i_need	SC_CACHE_COUNT,WORD	     ; DOS 4.00 secondary cache entries	;AN000;
	i_need	BUF_EMS_MODE,BYTE	     ; DOS 4.00 EMS mode 		;AN000;
	i_need	BUF_EMS_HANDLE,WORD	     ; DOS 4.00 buffer EMS handle	;AN000;
	i_need	SC_SECTOR_SIZE,WORD	     ; DOS 4.00 sector size		;AN000;
	i_need	SC_DRIVE,BYTE		     ; DOS 4.00 drive			;AN000;
	i_need	ACT_PAGE,WORD		     ; DOS 4.00 active logical EMS page	;AN000;
	i_need	DOS34_FLAG,WORD 	     ; DOS 4.00 common flag		;AN000;
	i_need	BUF_EMS_SEG_CNT,WORD	     ; DOS 4.00 EMS seg count		;AN000;
	i_need	BUF_EMS_MAP_BUFF,BYTE	     ; DOS 4.00 EMS map buffer		;AN000;
	i_need	FIRST_BUFF_ADDR,WORD	     ; DOS 4.00 beginning of the chain	;AN000;
	i_need	BUF_EMS_PAGE_FRAME,WORD      ; DOS 4.00 EMS page frame		;AN000;

IF	BUFFERFLAG
	i_need	BUF_EMS_PFRAME,WORD
	i_need 	BUF_EMS_LAST_PAGE,WORD
	i_need	BUF_EMS_FIRST_PAGE,WORD
	i_need	BUF_EMS_SAFE_FLAG,byte
	i_need	BUF_EMS_NPA640,WORD
	i_need	NEXTADD,WORD
	i_need	DMAADD,DWORD
	i_need	BYTCNT1,WORD
	i_am	BUF_EMS_MAP_BUF,12,<0,0,0,0,0,0,0,0,0,0,0,0>	     
	i_am	CURADD,WORD
	i_am	low_ems_buf,512
	extrn	SAVE_USER_MAP:near
	extrn	RESTORE_USER_MAP:near
ENDIF


Break	<GETCURHEAD -- Get current buffer header>

; Inputs:
;	DX= sector number (LOW)
;	[HIGH_SECTOR]= sector number (HIGH)
; Function:
;	Hash into a buffer group and activate the extended memory if
;	necessary
; Outputs:
;	[CurHashEntry] = current Hash entry addr
;	DS:DI = 1st buffer addr of the current Hash entry
; No other registers altered

	procedure   GETCURHEAD,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING

	PUSH	DX			  ;LB. save regs			;AN000;
	PUSH	AX			  ;LB.					;AN000;
	PUSH	BX			  ;LB.					;AN000;
	MOV	AX,DX			  ;LB.					;AN000;
;	MOV	DX,[HIGH_SECTOR]	  ;LB. HASH(sector#) and get entry #	;AN000;
	XOR	DX,DX			  ;LB. to avoid divide overflow 	;AN000;
	DIV	[BUF_HASH_COUNT]	  ;LB. get remainder			;AN000;
	ADD	DX,DX			  ;LB. 8 bytes per entry		;AN000;
	ADD	DX,DX			  ;LB.					;AN000;
	ADD	DX,DX			  ;LB. times 8				;AN000;

	LDS	DI,[BUF_HASH_PTR]	  ;LB. get Hash Table addr		;AN000;
	ADD	DI,DX			  ;LB position to entry 		;AN000;
Map_Entry2:
	MOV	WORD PTR [CurHashEntry+2],DS ;LB. update current Hash entry ptr ;AN000;
	MOV	WORD PTR [CurHashEntry],DI ;LB. 				;AN000;
	MOV	WORD PTR [LASTBUFFER],-1   ;LB. invalidate last buffer		;AN000;
	MOV	BX,[DI.EMS_PAGE_NUM]	  ;LB. logical page			;AN000;

IF	NOT	BUFFERFLAG
	LDS	DI,[DI.BUFFER_BUCKET]	  ;LB. ds:di is 1st buffer addr 	;AN000;
	MOV	[FIRST_BUFF_ADDR],DI	  ;LB. 1/19/88 save first buffer addr	;AN000;
	CALL	SET_MAP_PAGE		  ;LB. activate handle if EMS there	;AN000;
ELSE
	push	ax
	mov	ax, [NEXTADD]
	mov	[CURADD], ax
	pop	ax
	CALL	SET_MAP_PAGE		  ;LB. activate handle if EMS there	;AN000;
	LDS	DI,[DI.BUFFER_BUCKET]	  ;LB. ds:di is 1st buffer addr 	;AN000;
	MOV	[FIRST_BUFF_ADDR],DI	  ;LB. 1/19/88 save first buffer addr	;AN000;
ENDIF

										;AN000;
	POP	BX			  ;LB.					;AN000;
	POP	AX			  ;LB.					;AN000;
	POP	DX			  ;LB.					;AN000;
	return				  ;LB.					;AN000;
EndProc GETCURHEAD								;AN000;

										;AN000;
Break	<SET_MAP_PAGE - map handle and page >					;AN000;
; Inputs:									;AN000;
;	BX= logical page							;AN000;
; Function:									;AN000;
;	Map handle and logical page to frame 0 page 0				;AN000;
; Outputs:									;AN000;
;	AH=0 success								;AN000;
; No other registers altered							;AN000;
										;AN000;
Procedure   SET_MAP_PAGE,NEAR							;AN000;
	ASSUME	DS:NOTHING,ES:NOTHING						;AN000;

;	int	3
										;AN000;
	CMP	[BUF_EMS_MODE],-1	  ;LB. EMS support			;AN000;
	JZ	No_map			  ;LB. no				;AN000;

IF	NOT BUFFERFLAG
	CMP	[ACT_PAGE],BX		  ;LB. already mapped ? 		;AN000;
	JZ	No_map			  ;LB. yes				;AN000;
ENDIF
	MOV	[ACT_PAGE],BX		  ;LB. save active page mapped		;AN000;

IF	BUFFERFLAG	
	cmp	[BUF_EMS_SAFE_FLAG], 1
	je	no_coll
;	int	3
	call	detect_collision
no_coll:
ENDIF

	MOV	DX,[BUF_EMS_HANDLE]	  ;LB.					;AN000;
	MOV	AH,44H			  ;LB. activate current handle		;AN000;
	MOV	AL,BYTE PTR [BUF_EMS_PAGE_FRAME]  ;LB. page frame number	;AN000;
	INT	67H			  ;LB.					;AN000;
No_map: 									;AN000;
	return									;AN000;
EndProc SET_MAP_PAGE								;AN000;
										;AN000;

IF	BUFFERFLAG

Break	<SAVE_MAP - save map >							;AN000;
; Inputs:									;AN000;
;	none									;AN000;
; Function:									;AN000;
;	save map								;AN000;
; Outputs:									;AN000;
;	none									;AN000;
; No other registers altered							;AN000;
										;AN000;
Procedure   SAVE_MAP,NEAR							 ;AN000;
	ASSUME	DS:NOTHING,ES:NOTHING						;AN000;
										;AN000;
	CMP	[BUF_EMS_MODE],-1	  ;LB. EMS support			;AN000;
	JZ	No_save 		  ;LB. no				;AN000;
	MOV	[ACT_PAGE],-1		  ;LB. invalidate active page		;AN000;
	MOV	WORD PTR [LASTBUFFER],-1  ;LB.	and last buffer pointer 	;AN000;
	PUSH	AX			  ;LB. save regs			;AN000;
	PUSH	DS			  ;LB. save regs			;AN000;
	PUSH	ES			  ;LB.					;AN000;
	PUSH	SI			  ;LB.					;AN000;
	PUSH	DI			  ;LB.					;AN000;
	MOV	SI,OFFSET DOSGROUP:BUF_EMS_SEG_CNT     ;LB.			;AN000;
	MOV	DI,OFFSET DOSGROUP:BUF_EMS_MAP_BUF     ;LB.			;AN000;

	PUSH	CS
	POP	ES
	PUSH	CS			  ;LB.					;AN000;
	POP	DS			  ;LB. ds:si -> ems seg count		;AN000;

	MOV	AX,4F00H		  ;LB. save map 			;AN000;
	EnterCrit  critDisk		  ;LB. enter critical section		;AN000;
	INT	67H			  ;LB.					;AN000;
	LeaveCrit  critDisk		  ;LB. leave critical section		;AN000;
	POP	DI			  ;LB.					;AN000;
	POP	SI			  ;LB. restore regs			;AN000;
	POP	ES			  ;LB.					;AN000;
	POP	DS			  ;LB.					;AN000;
	POP	AX			  ;LB. restore				;AN000;
No_save:									 ;AN000;
	return									;AN000;
EndProc SAVE_MAP								 ;AN000;
										;AN000;

Break	<RESTORE_MAP- retore map >						;AN000;
; Inputs:									;AN000;
;	none									;AN000;
; Function:									;AN000;
;	restore_map								;AN000;
; Outputs:									;AN000;
;	none									;AN000;
; No other registers altered							;AN000;
										;AN000;
Procedure   RESTORE_MAP,NEAR							 ;AN000;
	ASSUME	DS:NOTHING,ES:NOTHING						;AN000;
										;AN000;
	CMP	[BUF_EMS_MODE],-1	  ;LB. EMS support			;AN000;
	JZ	No_restore		  ;LB. no				;AN000;
	PUSH	AX			  ;LB. save regs			;AN000;
	PUSH	DS			  ;LB. save regs			;AN000;
	PUSH	SI			  ;LB.					;AN000;
	MOV	SI,OFFSET DOSGROUP:BUF_EMS_MAP_BUF     ;LB.			;AN000;

	PUSH	CS
	POP	DS
	MOV	AX,4F01H		  ;LB. restore map			;AN000;
	EnterCrit  critDisk		  ;LB. enter critical section		;AN000;
	INT	67H			  ;LB.					;AN000;
	LeaveCrit  critDisk		  ;LB. leave critical section		;AN000;
	POP	SI			  ;LB. restore regs			;AN000;
	POP	DS			  ;LB.					;AN000;
	POP	AX			  ;LB.					;AN000;
No_restore:									 ;AN000;
	return									;AN000;
EndProc RESTORE_MAP								 ;AN000;

ENDIF
										;AN000;
										;AN000;

Break	<SCANPLACE, PLACEBUF -- PUT A BUFFER BACK IN THE POOL>

; Inputs:
;	Same as PLACEBUF
; Function:
;	Save scan location and call PLACEBUF
; Outputs:
;	DS:DI Points to saved scan location
; SI destroyed, other registers unchanged

	procedure   ScanPlace,near
ASSUME	DS:NOTHING,ES:NOTHING

;;	PUSH	ES
;;	LES	SI,[DI.buf_link]	; Save scan location
	MOV	SI,[DI.buf_next]	; Save scan location
	CALL	PLACEBUF
;;	PUSH	ES
;;	POP	DS			; Restore scan location
	MOV	DI,SI
;;	POP	ES
	return
EndProc ScanPlace

; Rewritten PLACEBUF (LKR), eliminates loops
;
; Input:
;	DS:DI points to buffer (DS->BUFFINFO array, DI=offset in array)
; Function:
;	Remove buffer from queue and re-insert it in proper place.
; NO registers altered

	procedure   PLACEBUF,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

;	invoke	save_world
	push	AX				;Save only regs we modify	;AN000;
	push	BX								;AN000;
	push	SI								;AN000;
	push	ES								;AN000;

	les	SI,[CurHashEntry]		;ES:SI -> Current Hash entry	;AN000;
	mov	BX,word ptr ES:[SI.BUFFER_BUCKET] ;BX = offset of head of list	;AN000;

	cmp	[DI.buf_next],BX		;Buf = last?			;AN000;
	je	nret				;Yes, special case		;AN000;
	cmp	DI,BX				;Buf = first?			;AN000;
	je	bufloop 			;Yes, special case		;AN000;
	mov	SI,[DI.buf_prev]		;No, SI = prior Buf		;AN000;
	mov	AX,[DI.buf_next]		;Now delete Buf from list	;AN000;
	mov	[SI.buf_next],AX						;AN000;
	push	SI				;Save si			;AN000;
	mov	SI,[DI.buf_next]		;Update backward pointer	;AN000;
	mov	AX,[DI.buf_prev]		;				;AN000;
	mov	[SI.buf_prev],AX		;				;AN000;
	pop	si				;Restore si			;AN000;
lookend:				;(label is now a misnomer)		;AN000;
	mov	SI,[BX.buf_prev]		;SI-> last buffer		;AN000;
	mov	[SI.buf_next],DI		;Add Buf to end of list 	;AN000;
	mov	[BX.buf_prev],DI						;AN000;
	mov	[DI.buf_prev],SI		;Update linkage in Buf too	;AN000;
	mov	[DI.buf_next],BX						;AN000;
nret:										;AN000;
										;AN000;
;	invoke	restore_world							;AN000;
	pop	ES				;Restore regs we modified	;AN000;
	pop	SI								;AN000;
	pop	BX								;AN000;
	pop	AX								;AN000;
										;AN000;
	cmp	[DI.buf_ID],-1			; Buffer FREE?			;AN000;
	retnz					; No				;AN000;
	invoke	PLACEHEAD			; Buffer is free, belongs at hea;AN000;
	return									;AN000;
bufloop:				;(label is now a misnomer)		;AN000;
	mov	BX,[DI.buf_next]		;Set new head position		;AN000;
	mov	word ptr ES:[SI.BUFFER_BUCKET],BX				;AN000;
	jmp	nret				;Continue with repositioning	;AN000;

EndProc PLACEBUF

; SAME AS PLACEBUF except places buffer at head
;  NOTE:::::: ASSUMES THAT BUFFER IS CURRENTLY THE LAST
;	ONE IN THE LIST!!!!!!!
; Rewritten PLACEBUF, takes buffer from end of list to head of list

	procedure   PLACEHEAD,NEAR						;AN000;
ASSUME	DS:NOTHING,ES:NOTHING							;AN000;
	push	ES								;AN000;
	push	SI								;AN000;
	les	SI,[CurHashEntry]						;AN000;
	mov	word ptr ES:[SI.BUFFER_BUCKET],DI				;AN000;
	pop	SI								;AN000;
	pop	ES								;AN000;
	return									;AN000;
EndProc PLACEHEAD								;AN000;


Break	<POINTCOMP -- 20 BIT POINTER COMPARE>

; Compare DS:SI to ES:DI (or DS:DI to ES:SI) for equality
; DO NOT USE FOR < or >
; No Registers altered

	procedure   PointComp,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	CMP	SI,DI
	retnz
	PUSH	CX
	PUSH	DX
	MOV	CX,DS
	MOV	DX,ES
	CMP	CX,DX
	POP	DX
	POP	CX
	return
EndProc PointComp

Break	<GETBUFFR -- GET A SECTOR INTO A BUFFER>

; Input:
;	AL = 0 means sector must be pre-read
;	   ELSE no pre-read
;	DX = Desired physical sector number	      (LOW)
;	[HIGH_SECTOR]= Desired physical sector number (HIGH)
;	ES:BP = Pointer to drive parameters
;	[ALLOWED] set in case of INT 24
; Function:
;	Get the specified local sector into one of the I/O buffers
;	And shuffle the queue
; Output:
;	[CURBUF] Points to the Buffer for the sector
;	THE BUFFER TYPE FIELD OF buf_flags = 0, caller must set it
;	Carry set if error (currently user FAILed to INT 24)
; DS,DX,ES:BP unchanged, all other registers destroyed

	procedure   GETBUFFR,NEAR
	DOSAssume   CS,<DS>,"GetBuffr"
	ASSUME	ES:NOTHING

	XOR	SI,SI

	entry	GETBUFFRB

	Assert	ISDPB,<ES,BP>,"GetBuffr"
	MOV	[PREREAD],AX
	MOV	AL,ES:[BP.dpb_drive]
	LDS	DI,[LASTBUFFER]
ASSUME	DS:NOTHING
	MOV	CX,[HIGH_SECTOR]		; F.C. >32mb			;AN000;
	CMP	DI,-1				; Recency pointer valid?
	JZ	SKBUF				; No

	CMP	DX,WORD PTR [DI.buf_sector]
	JNZ	SKBUF				; Wrong sector
	CMP	CX,WORD PTR [DI.buf_sector+2]	; F.C. >32mb			;AN000;
	JNZ	SKBUF				; F.C. >32mb			;AN000;
	CMP	AL,[DI.buf_ID]
	JNZ	SKBUF				; Wrong Drive

	JMP	JUSTBUF 			; Just asked for same buffer
SKBUF:
	CALL	GETCURHEAD			;LB. get cuurent Hash entry	;AN000;
;	LDS	DI,[BUFFHEAD]
NXTBFF:
	CMP	DX,WORD PTR [DI.buf_sector]	; F.C. >32mb			;AN000;
	JNZ	BUMP
	CMP	CX,WORD PTR [DI.buf_sector+2]	; F.C. >32mb			;AN000;
	JNZ	BUMP				; F.C. >32mb			;AN000;
	CMP	AL,[DI.buf_ID]
if	not bufferflag
	JZ	SETINF
else
	jnz	bump
	jmp	setinf
endif
BUMP:
	mov	DI,[DI.buf_next]		;;;;;;1/19/88			;AN000;
	cmp	DI,[FIRST_BUFF_ADDR]		;;;;;;1/19/88			;AN000;
	JNZ	NXTBFF
;;;;	LDS	DI,[CurHashEntry]		;LB. secondary cache's use      ;AN000;
;;;;	LDS	DI,[DI.BUFFER_BUCKET]		;LB.				;AN000;
 ;	LDS	DI,[BUFFHEAD]
	PUSH	[HIGH_SECTOR]			;F.C. >32mb			;AN000;
	PUSH	SI
	PUSH	DX
	PUSH	BP
	PUSH	ES
	CALL	BUFWRITE	; Write out the dirty buffer
	POP	ES
	POP	BP
	POP	DX
	POP	SI
	POP	[HIGH_SECTOR]			;F.C. >32mb			;AN000;
if 	not bufferflag
	JC	GETBERR
else
	jnc	skip_getberr
	jmp	getberr
skip_getberr:
endif
	CALL	SET_RQ_SC_PARMS 		;LB. set parms			;AN000;
	XOR	AH,AH			; initial flags
	TEST	BYTE PTR [PREREAD],-1	; Read in the new sector
	JNZ	SETBUF
	LEA	BX,[DI.BufInSiz]	; Point at buffer
	MOV	CX,1
	PUSH	SI
	PUSH	DI
	PUSH	DX
; Note:  As far as I can tell, all disk reads into buffers go through this point.  -mrw 10/88
if	bufferflag
;	int	3
	cmp	[buf_ems_mode], -1
	jz	normread
	push	bx
	push	ds		; save ds:bx --> ems_buffer
	push	cs
	pop	ds
	mov	bx, offset dosgroup:low_ems_buf	; ds:bx --> low_ems_buffer
normread:
endif
	OR	SI,SI
	JZ	NORMSEC
	invoke	FATSECRD
	MOV	AH,buf_isFAT		; Set buf_flags
	JMP	SHORT GOTTHESEC 	; Buffer is marked free if read barfs
NORMSEC:
	invoke	DREAD			; Buffer is marked free if read barfs
	MOV	AH,0			; Set buf_flags to no type, DO NOT XOR!
GOTTHESEC:				; Carry set by either FATSECRD or DREAD
if	bufferflag
	pushf
	jc	skipreadtrans
	cmp	[buf_ems_mode], -1
	je	skipreadtrans

	popf
	pop	ds
	pop	bx		; restore ems_buffer pointer
	pushf

	push	cx		; save regs to be used by rep mov
	push	ds
	push	es

	mov	di, bx
	push	ds		
	pop	es		; es:di --> ems_buf
	mov	si, offset dosgroup:low_ems_buf
	push	cs
	pop	ds		; ds:si --> low_ems_buf
	mov	cx, 512/2
	rep movsw

	pop	es		; restore regs.
	pop	ds
	pop	cx
skipreadtrans:
	popf
endif
	POP	DX
	POP	DI
	POP	SI
	JC	GETBERR
SETBUF:
	MOV	CX,[HIGH_SECTOR]	       ; F.C. >32mb			;AN000;
	MOV	WORD PTR [DI.buf_sector+2],CX  ; F.C. >32mb			;AN000;
	MOV	WORD PTR [DI.buf_sector],DX    ; F.C. >32mb			;AN000;
	MOV	WORD PTR [DI.buf_DPB],BP
	MOV	WORD PTR [DI.buf_DPB+2],ES
	MOV	AL,ES:[BP.dpb_drive]
	MOV	WORD PTR [DI.buf_ID],AX 	; Sets buf_flags too, to AH
SETINF:
	MOV	[DI.buf_wrtcnt],1		; Default to not a FAT sector	;AC000;
	XOR	AX,AX				;>32mb				;AN000;
	OR	SI,SI
	JZ	SETSTUFFOK
	MOV	AL,ES:[BP.dpb_FAT_count]
	MOV	[DI.buf_wrtcnt],AL		;>32mb				;AN000;
	MOV	AX,ES:[BP.dpb_FAT_size]
SETSTUFFOK:
	MOV	[DI.buf_wrtcntinc],AX		;>32mb				;AC000;
	CALL	PLACEBUF
JUSTBUF:
	MOV	WORD PTR [CURBUF+2],DS
	MOV	WORD PTR [LASTBUFFER+2],DS
	MOV	WORD PTR [CURBUF],DI
	MOV	WORD PTR [LASTBUFFER],DI
	CLC
GETBERR:
	Context DS
	return
EndProc GETBUFFR

Break	<FLUSHBUF -- WRITE OUT DIRTY BUFFERS>

; Input:
;	DS = DOSGROUP
;	AL = Physical unit number local buffers only
;	   = -1 for all units and all remote buffers
; Function:
;	Write out all dirty buffers for unit, and flag them as clean
;	Carry set if error (user FAILed to I 24)
;	    Flush operation completed.
; DS Preserved, all others destroyed (ES too)

	procedure   FlushBuf,NEAR
	DOSAssume   CS,<DS>,"FlushBuf"
	ASSUME	ES:NOTHING

	MOV	AH,-1
;	LDS	DI,[BUFFHEAD]
ASSUME	DS:NOTHING

	LDS	DI,[BUF_HASH_PTR]	  ;LB. get Hash Table addr		;AN000;
	MOV	CX,[BUF_HASH_COUNT]	  ;LB. get Hash entry count		;AN000;
	XOR	DX,DX			  ;LB. set initial index to 0		;AN000;

NXTBUFF2:
	PUSH	CX			     ;LB. save Hash entry count 	;AN000;
	TEST	[DOS34_FLAG],FROM_DISK_RESET ;MS. from disk reset		;AN004;
	JNZ	Zapzap			     ;MS. yes				;AN004;
	CMP	[DI.Dirty_Count],0	     ;LB. dirty entry ? 		;AN000;
	JZ	getnext 		     ;LB. no				;AN000;
Zapzap: 									;AN004;
	PUSH	DS			     ;LB. save regs			;AN000;
	PUSH	DI			     ;LB.				;AN000;
	invoke	Map_Entry		     ;LB. ds:di -> first buffer addr	;AN000;
NXTBUFF:
	CALL	CHECKFLUSH	; Ignore Carry return from CHECKFLUSH.
				; FAILERR is set if user FAILed.
	PUSH	AX
	MOV	AL,[DI.buf_ID]
	CMP	AL,BYTE PTR [WPERR]
	JZ	ZAP
	TEST	[DOS34_FLAG],FROM_DISK_RESET ;MS. from disk reset		;AN000;
	JNZ	Zap			     ;MS. yes				;AN000;

NOZAP:
	POP	AX
	mov	DI,[DI.buf_next]	     ;;;;1/19/88			;AN000;
	CMP	DI,[FIRST_BUFF_ADDR]	     ;;;;1/19/88			;AN000;
	JNZ	NXTBUFF

	POP	DI			     ;LB.				;AN000;
	POP	DS			     ;LB.				;AN000;
getnext:
	ADD	DI,size BUFFER_HASH_ENTRY    ;LB. position to next entry	;AN000;
	POP	CX			     ;LB. restore entry count		;AN000;
	LOOP	NXTBUFF2		     ;LB. get next entry buffer 	;AN000;
	Context DS
	CMP	[FAILERR],0
	JNZ	FLSHBad 	; Carry clear if JMP
	return
FlshBad:
	STC			; Return error if user FAILed
	return
Zap:
	MOV	WORD PTR [DI.buf_ID],00FFH ; Invalidate buffer, it is inconsistent
	JMP	NoZap

EndProc FlushBuf

	procedure CHECKFLUSH,NEAR
ASSUME	DS:NOTHING,ES:NOTHING
; Carry set if problem (currently user FAILed to I 24)

	Assert	ISBUF,<DS,DI>,"CheckFlush"
	CMP	[DI.buf_ID],AH
	retz				; Skip free buffers, carry clear
	CMP	AH,AL
	JZ	DOBUFFER		; Do all dirty buffers
	CMP	AL,[DI.buf_ID]
	CLC
	retnz				; Buffer not for this unit or SFT
DOBUFFER:
	TEST	[DI.buf_flags],buf_dirty
	retz				; Buffer not dirty, carry clear by TEST
	PUSH	AX
	PUSH	WORD PTR [DI.buf_ID]
	CALL	BUFWRITE
	POP	AX
	JC	LEAVE_BUF		; Leave buffer marked free (lost).
	AND	AH,NOT buf_dirty	; Buffer is clean, clears carry
	MOV	WORD PTR [DI.buf_ID],AX
LEAVE_BUF:
	POP	AX			; Search info
	return
EndProc CHECKFLUSH

Break	<BUFWRITE -- WRITE OUT A BUFFER IF DIRTY>

; Input:
;	DS:DI Points to the buffer
; Function:
;	Write out all the buffer if dirty.
; Output:
;	Buffer marked free
;	Carry set if error (currently user FAILed to I 24)
; DS:DI Preserved, ALL others destroyed (ES too)

	procedure   BufWrite,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	Assert	ISBUF,<DS,DI>,"BufWrite"
	MOV	AX,00FFH
	XCHG	AX,WORD PTR [DI.buf_ID] ; Free, in case write barfs
	CMP	AL,0FFH
	retz				; Buffer is free, carry clear.
	TEST	AH,buf_dirty
	retz				; Buffer is clean, carry clear.
	invoke	DEC_DIRTY_COUNT 	; LB. decrement dirty count
	CMP	AL,BYTE PTR [WPERR]
	retz				; If in WP error zap buffer
	MOV	[SC_DRIVE],AL		;LB. set it for invalidation		;AN000;
	LES	BP,[DI.buf_DPB]
	LEA	BX,[DI.BufInSiz]	; Point at buffer
	MOV	DX,WORD PTR [DI.buf_sector]	;F.C. >32mb			;AN000;
	MOV	CX,WORD PTR [DI.buf_sector+2]	;F.C. >32mb			;AN000;
	MOV	[HIGH_SECTOR],CX		;F.C. >32mb			;AN000;
	MOV	CL,[DI.buf_wrtcnt]		;>32mb				;AC000;
;	MOV	AL,CH			; [DI.buf_wrtcntinc]
	XOR	CH,CH
	MOV	AX,[DI.buf_wrtcntinc]		;>32mb				;AC000;
	MOV	[ALLOWED],allowed_RETRY + allowed_FAIL
	TEST	[DI.buf_flags],buf_isDATA
	JZ	NO_IGNORE
	OR	[ALLOWED],allowed_IGNORE
NO_IGNORE:
	PUSH	DI		; Save buffer pointer
	XOR	DI,DI		; Indicate failure
WRTAGAIN:
	SaveReg <DI,CX,AX>
	MOV	CX,1
	SaveReg <BX,DX,DS>
; Note:  As far as I can tell, all disk reads into buffers go through this point.  -mrw 10/88

if	bufferflag
;	int	3
	cmp	[buf_ems_mode], -1
	jz	skipwritetrans

	push	es
	push	di
	push	si
	push	cx

	mov	si, bx		; ds:si --> ems_buffer
	mov	di, offset dosgroup:low_ems_buf
	push	cs
	pop	es		; es:di --> low_ems_buffer
	mov	cx, 512/2
	rep	movsw

	pop	cx
	pop	si
	pop	di
	pop	es

	push	ds
	push	bx
	mov	bx, offset dosgroup:low_ems_buf
	push	cs
	pop	ds		; ds:bx --> low_ems_buffer
skipwritetrans:
endif

	invoke	DWRITE		; Write out the dirty buffer

if	bufferflag
	pushf			; save carry flag from DWRITE
	cmp	[buf_ems_mode], -1
	jz	normwrite
	popf			; need to get at stack
	pop	bx		; ds:bx --> ems_buffer
	pop	ds
	pushf			; put it back, so we can pop it
normwrite:
	popf			; restore carry flag
endif

	RestoreReg  <DS,DX,BX>
	RestoreReg  <AX,CX,DI>
	JC	NOSET
	INC	DI		; If at least ONE write succeedes, the operation
NOSET:				;	succeedes.
	ADD	DX,AX
	LOOP	WRTAGAIN
	OR	DI,DI		; Clears carry
	JNZ	BWROK		; At least one write worked
	STC			; DI never got INCed, all writes failed.
BWROK:
	POP	DI
	return
EndProc BufWrite

Break	<SET_RQ_SC_PARMS-set requesting drive for SC>

; Input:
;	ES:BP = drive parameter block
; Function:
;	Set requesting drive, and sector size
; Output:
;	[SC_SECTOR_SIZE]= drive sector size
;	[SC_DRIVE]= drive #
;
; All registers preserved

	procedure   SET_RQ_SC_PARMS,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	CMP	[SC_CACHE_COUNT],0  ;LB. do it only secondary cache exists	;AN000;
	JZ	nosec		    ;LB.					;AN000;
	PUSH	DX		    ;LB. save dx				;AN000;
	MOV	DX,ES:[BP.dpb_sector_size]	      ;LB. save sector size	;AN000;
	MOV	[SC_SECTOR_SIZE],DX		      ;LB.			;AN000;
	MOV	DL,ES:[BP.dpb_drive]		      ;LB. save drive # 	;AN000;
	MOV	[SC_DRIVE],DL			      ;LB.			;AN000;
										;AN000;
	POP	DX				      ;LB. restore dx		;AN000;

nosec:
	return
EndProc SET_RQ_SC_PARMS 			      ;LB. return		;AN000;

Break	<INC_DIRTY_COUNT-increment dirty count>

; Input:
;	none
; Function:
;	increment dirty buffers count
; Output:
;	dirty buffers count in the current hash entry is incremented
;
; All registers preserved

	procedure   INC_DIRTY_COUNT,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	PUSH	DS		    ;LB. save regs				;AN000;
	PUSH	SI		    ;LB.					;AN000;
	LDS	SI,[CurHashEntry]   ;LB. get current hash entry 		;AN000;
	INC	[SI.Dirty_Count]    ;LB. add 1					;AN000;
	POP	SI		    ;LB. restore regs				;AN000;
	POP	DS		    ;LB.					;AN000;
	return
EndProc INC_DIRTY_COUNT 	    ;LB. return 				;AN000;

Break	<DEC_DIRTY_COUNT-decrement dirty count>

; Input:
;	none
; Function:
;	decrement dirty buffers count
; Output:
;	dirty buffers count in the current hash entry is decremented
;
; All registers preserved

	procedure   DEC_DIRTY_COUNT,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	PUSH	DS		    ;LB. save regs				;AN000;
	PUSH	SI		    ;LB.					;AN000;
	LDS	SI,[CurHashEntry]   ;LB. get current hash entry 		;AN000;
	CMP	[SI.Dirty_Count],0  ;LB. in case if 0				;AN000;
	JZ	nodec		    ;LB. do nothing				;AN000;
	DEC	[SI.Dirty_Count]    ;LB. sub 1					;AN000;
nodec:
	POP	SI		    ;LB. restore regs				;AN000;
	POP	DS		    ;LB.					;AN000;
	return
EndProc DEC_DIRTY_COUNT 	    ;LB. return 				;AN000;


Break	<MAP_ENTRY- map the buffers of this entry>

; Input:
;	DS:DI ponits to hash entry
; Function:
;	map the buferrs of this entry
; Output:
;	the buffers are mapped
;
; All registers preserved

	procedure   Map_Entry,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	PUSH	DX			  ;LB. save regs			;AN000;
	PUSH	AX			  ;LB.					;AN000;
	PUSH	BX			  ;LB.					;AN000;
	JMP	Map_Entry2		  ;LB.					;AN000;
EndProc Map_Entry			  ;LB.					;AN000;


IF	BUFFERFLAG

;-------------------------------------------------------------------------
;	Procedure name	:	detect collision
;	Inputs		:	[DMAADD] - user Xaddr
;				[CURADD] - current offset
;				[BYTCNT1] - for partial sector read
;				SAFE_FLAG - cleared - indicating that the
;				current page is unsafe.
;
;	Outputs		:	es - physical page segment to use
;				di - corresponding page number
;				SAFE_FLAG is set is a collision is detected
;				and the current page is switched form 
;				LAST_PAGE to FIRST_PAGE.
;---------------------------------------------------------------------------
;				

Procedure	detect_collision, near
ASSUME	DS:NOTHING,ES:NOTHING

	push	ax
	push	bx
	push	cx

	cmp	[BUF_EMS_MODE], -1
	jz	fin_detect_coll

	mov	ax, [CURADD]	; current offset 

	cmp	[BYTCNT1], 0
	je	no_partial_sector
	add	ax, [BYTCNT1]

no_partial_sector:
	mov	cl, 4
	shr	ax, cl		; convert to paragraphs
	mov	bx, word ptr [DMAADD+2]	; get original segment 
	add	ax, bx		; get current segment

	and	ax, 0fc00h	; get ems page of current segment
	cmp	ax, [BUF_EMS_LAST_PAGE]	; is the current segment = last segment
	jne	fin_detect_coll	; page is still safe

;	int	3
	push	ax
	mov	ax, word ptr [DMAADD]
	mov	ax, [NEXTADD]
	mov	ax, [CURADD]
	mov	ax, [BYTCNT1]
	pop	ax

	call	restore_user_map
	mov	word ptr [LASTBUFFER], -1
	mov	ax, [BUF_EMS_FIRST_PAGE]
	mov	[BUF_EMS_PFRAME], ax
	mov	ax, [BUF_EMS_FIRST_PAGE+2]
	mov	[BUF_EMS_PAGE_FRAME], ax
	mov	[BUF_EMS_SAFE_FLAG], 1
	call	Setup_EMS_buffers
	call	save_user_map

fin_detect_coll:
	pop	cx
	pop	bx
	pop	ax
	ret

EndProc	detect_collision

Procedure Setup_EMS_Buffers,Near
	ASSUME	DS:NOTHING,ES:NOTHING						;AN000;

	cmp	[BUF_EMS_MODE], -1
	jz	setup_ems_ret

	push	bx
	push	cx
	push	ax
	push	ds
	push	di

	mov	bx, [BUF_HASH_COUNT]	; # of hash table entries
	lds	di, [BUF_HASH_PTR]	; ds:di -> hash table

	xor	cx, cx

next_bucket:
	mov	ax, [BUF_EMS_PFRAME]
	mov	word ptr ds:[di.BUFFER_BUCKET+2], ax
	add	di, 8			; next has entry.
	inc	cx
	cmp	cx, bx
	jne	next_bucket

	pop	di
	pop	ds
	pop	ax
	pop	cx
	pop	bx

setup_ems_ret:
	ret

EndProc	Setup_EMS_Buffers

ENDIF


CODE	ENDS
    END
