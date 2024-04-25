;	SCCSID = @(#)handle.asm 1.1 85/04/10
TITLE	HANDLE - Handle-related system calls
NAME	HANDLE
;
; Handle related system calls for MSDOS 2.X.  Only top-level system calls
; are present.	I/O specs are defined in DISPATCH.  The system calls are:
;
;   $Close     written
;   $Commit    written		  DOS 3.3  F.C. 6/4/86
;   $ExtHandle written		  DOS 3.3  F.C. 6/4/86
;   $Read      written
;   Align_Buffer		  DOS 4.00
;   $Write     written
;   $LSeek     written
;   $FileTimes written
;   $Dup       written
;   $Dup2      written
;
;   Revision history:
;
;	Created: MZ 28 March 1983
;		 MZ 15 Dec   1982 Jeff Harbers and Multiplan hard disk copy
;				  rely on certain values in AX when $CLOSE
;				  succeeds even though we document it as
;				  always trashing AX.
;
;	A000  version 4.00  Jan. 1988
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
include EA.inc
include version.inc
.cref
.list
.sall

	EXTRN	DOS_Read:NEAR, DOS_Write:NEAR

IF	BUFFERFLAG
	extrn	save_user_map:near
	extrn	restore_user_map:near
	extrn	Setup_EMS_Buffers:near
ENDIF

	I_need	ThisSFT,DWORD		; pointer to SFT entry
	I_need	DMAAdd,DWORD		; old-style DMA address
	I_Need	EXTERR_LOCUS,byte	; Extended Error Locus
	I_need	FailErr,BYTE		; failed error flag
	I_need	User_ID,WORD		; current effective user_id
	i_need	JShare,DWORD		; jump table
	I_need	CurrentPDB,WORD 	; current process data block
	I_need	EXTOPEN_ON,BYTE 	;AN000;FT. flag for extended open
;	I_need	XA_device,BYTE		;AN000; XA device
	I_need	XA_type,BYTE		;AN000; extended open subfunction
;	I_need	XA_handle,WORD		;AN000; handle
	I_need	THISCDS,DWORD		;AN000;
	I_need	DUMMYCDS,128		;AN000;
	I_need	SAVE_ES,WORD		;AN000; saved ES
	I_need	SAVE_DI,WORD		;AN000; saved DI
	I_need	SAVE_DS,WORD		;AN000; saved DS
	I_need	SAVE_SI,WORD		;AN000; saved SI
	I_need	SAVE_CX,WORD		;AN000; saved CX

IF	BUFFERFLAG

	I_need	BUF_EMS_MODE,BYTE
	I_need	BUF_EMS_LAST_PAGE,DWORD
	I_need	BUF_EMS_FIRST_PAGE,DWORD
	I_need	BUF_EMS_SAFE_FLAG,BYTE
	I_need	BUF_EMS_NPA640,WORD
	I_need	BUF_EMS_PAGE_FRAME,WORD
	I_need	BUF_EMS_PFRAME,WORD
	I_need	LASTBUFFER,DWORD

ENDIF

;	I_need	XA_ES,WORD		;AN000; extended find
;	I_need	XA_BP,WORD		;AN000; extended find
;	I_need	XA_from,BYTE		;AN000; for filetimes
if debug
	I_need	BugLev,WORD
	I_need	BugTyp,WORD
include bugtyp.asm
endif

BREAK <$Close - return a handle to the system>

;
;   Assembler usage:
;	    MOV     BX, handle
;	    MOV     AH, Close
;	    INT     int_command
;
;   Error return:
;	    AX = error_invalid_handle
;
;   No registers returned

Procedure   $Close,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	fmt TypSysCall,LevLog,<"$p Close\n">
	fmt TypSysCall,LevArgs,<"$p  Handle = $x\n">,<BX>
;
; Grab the SFT pointer from the JFN.
;
	call	CheckOwner		; get system file entry
	JC	CloseError		; error return
	fmt TypAccess,LevSFN,<"$p  Close SFT $x:$x\n">,<es,di>
	context DS			; For DOS_CLOSE
	MOV	WORD PTR [ThisSFT],DI	; save offset of pointer
	MOV	WORD PTR [ThisSFT+2],ES ; save segment value
;
; DS:SI point to JFN table entry.
; ES:DI point to SFT
;
; We now examine the user's JFN entry; If the file was a 70-mode file (network
; FCB, we examine the ref count on the SFT;  if it was 1, we free the JFN.
; If the file was not a net FCB, we free the JFN too.
;
	CMP	ES:[DI].sf_ref_count,1	; will the SFT become free?
	JZ	FreeJFN 		; yes, free JFN anyway.
	MOV	AL,BYTE PTR ES:[DI].sf_mode
	AND	AL,sharing_mask
	CMP	AL,sharing_net_fcb
	JZ	PostFree		; 70-mode and big ref count => free it
;
; The JFN must be freed.  Get the pointer to it and replace the contents with
; -1.
;
FreeJFN:
	Invoke	pJFNFromHandle		;   d = pJFN (handle);
	fmt TypAccess,LevSFN,<"$p  Close jfn pointer $x:$x\n">,<es,di>
	MOV	BYTE PTR ES:[DI],0FFh	; release the JFN
PostFree:
;
; ThisSFT is correctly set, we have DS = DOSGROUP.  Looks OK for a DOS_CLOSE!
;
	invoke	DOS_Close
;
; DOS_Close may return an error.  If we see such an error, we report it but
; the JFN stays closed because DOS_Close always frees the SFT!
;
	JC	CloseError
	fmt TypSysCall,LevLog,<"$p: Close ok\n">
	MOV	AH,close		; MZ Bogus multiplan fix
	transfer    Sys_Ret_OK
CloseError:
	ASSUME	DS:NOTHING
	fmt TypSysCall,LevLog,<"$p: Close error $x\n">,<AX>
	transfer    Sys_Ret_Err
EndProc $Close

BREAK <$Commit - commit the file>

;
;   Assembler usage:
;	    MOV     BX, handle
;	    MOV     AH, Commit
;	    INT     int_command
;
;   Error return:
;	    AX = error_invalid_handle
;
;   No registers returned

Procedure   $Commit,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
;
; Grab the SFT pointer from the JFN.
;
	call	CheckOwner		; get system file entry
	JC	Commiterror		; error return
	context DS			; For DOS_COMMIT
	MOV	WORD PTR [ThisSFT],DI	; save offset of pointer
	MOV	WORD PTR [ThisSFT+2],ES ; save segment value
;
; ES:DI point to SFT
;
;
; ThisSFT is correctly set, we have DS = DOSGROUP.  Looks OK for a DOS_COMMIT
;
	invoke	DOS_COMMIT
;
;
	JC	Commiterror
	MOV	AH,Commit		;
	transfer    Sys_Ret_OK
Commiterror:
	ASSUME	DS:NOTHING
	transfer    Sys_Ret_Err
EndProc $Commit


BREAK <$ExtHandle - extend handle count>

;
;   Assembler usage:
;	    MOV     BX, Number of Opens Allowed (MAX=65534;66535 is
;	    MOV     AX, 6700H			 reserved to mark SFT
;	    INT     int_command 		 busy )
;
;   Error return:
;	    AX = error_not_enough_memory
;		 or error_too_many_open_files
;   No registers returned

Procedure   $ExtHandle,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
;
;
;
	XOR	BP,BP			; 0: enlarge   1: shrink  2:psp
	CMP	BX,FilPerProc		;  < 20
	JAE	getpdb			;  no
	MOV	BX,FilPerProc		;  bx = 20

getpdb:
	MOV	ES,[CurrentPDB] 	; get user process data block
	MOV	CX,ES:[PDB_JFN_Length]	; get number of handle allowed
	CMP	BX,CX			; the requested == current
	JE	ok_done 		; yes and exit
	JA	larger			; go allocate new table

	MOV	BP,1			; shrink
	MOV	DS,WORD PTR ES:[PDB_JFN_Pointer+2] ;
	MOV	SI,BX			;
	SUB	CX,BX			; get difference
chck_handles:
	CMP	BYTE PTR DS:[SI],-1	; scan through handles to ensure close
	JNZ	too_many_files		; status
	INC	SI
	LOOP	chck_handles
	CMP	BX,FilPerProc		; = 20
	JA	larger			; no

	MOV	BP,2			; psp
	MOV	DI,PDB_JFN_Table	; es:di -> jfn table in psp
	PUSH	BX
	JMP	movhandl

larger:
	CMP	BX,-1			; 65535 is not allowed
	JZ	invalid_func
	CLC
	PUSH	BX			; save requested number
	ADD	BX,0FH			; adjust to paragraph boundary
	MOV	CL,4
	RCR	BX,CL			; DOS 4.00 fix				;AC000;
	AND	BX,1FFFH		; clear most 3 bits

	PUSH	BP
	invoke	$ALLOC			; allocate memory
	POP	BP
	JC	no_memory		; not enough meory

	MOV	ES,AX			; es:di points to new table memory
	XOR	DI,DI
movhandl:
	MOV	DS,[CurrentPDB] 	; get user PDB address

	TEST	BP,3			; enlarge ?
	JZ	enlarge 		; yes
	POP	CX			; cx = the amount you shrink
	PUSH	CX
	JMP	copy_hand
ok_done:
	transfer    Sys_Ret_OK
too_many_files:
	MOV	AL,error_too_many_open_files
	transfer    Sys_Ret_Err
enlarge:
	MOV	CX,DS:[PDB_JFN_Length]	  ; get number of old handles
copy_hand:
	MOV	DX,CX
	LDS	SI,DS:[PDB_JFN_Pointer]   ; get old table pointer
ASSUME DS:NOTHING
	REP	MOVSB			; copy infomation to new table

	POP	CX			; get new number of handles
	PUSH	CX			; save it again
	SUB	CX,DX			; get the difference
	MOV	AL,-1			; set availability to handles
	REP	STOSB

	MOV	DS,[CurrentPDB] 	; get user process data block
	CMP	WORD PTR DS:[PDB_JFN_Pointer],0  ; check if original table pointer
	JNZ	update_info		; yes, go update PDB entries
	PUSH	BP
	PUSH	DS			; save old table segment
	PUSH	ES			; save new table segment
	MOV	ES,WORD PTR DS:[PDB_JFN_Pointer+2] ; get old table segment
	invoke	$DEALLOC		; deallocate old table meomory
	POP	ES			; restore new table segment
	POP	DS			; restore old table segment
	POP	BP

update_info:
	TEST	BP,2			; psp?
	JZ	non_psp 		; no
	MOV	WORD PTR DS:[PDB_JFN_Pointer],PDB_JFN_Table   ; restore
	JMP	final
non_psp:
	MOV	WORD PTR DS:[PDB_JFN_Pointer],0  ; new table pointer offset always 0
final:
	MOV	WORD PTR DS:[PDB_JFN_Pointer+2],ES  ; update table pointer segment
	POP	DS:[PDB_JFN_Length]	 ; restore new number of handles
	transfer   Sys_Ret_Ok
no_memory:
	POP	BX			; clean stack
	MOV	AL,error_not_enough_memory
	transfer    Sys_Ret_Err
invalid_func:
	MOV	AL,error_invalid_function
	transfer    Sys_Ret_Err
EndProc $ExtHandle

BREAK <$READ - Read from a file handle>
;
;   Assembler usage:
;	    LDS     DX, buf
;	    MOV     CX, count
;	    MOV     BX, handle
;	    MOV     AH, Read
;	    INT     int_command
;	  AX has number of bytes read
;   Errors:
;	    AX = read_invalid_handle
;	       = read_access_denied
;
;   Returns in register AX

procedure   $READ,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	fmt TypSysCall,LevLog,<"Read\n">
	fmt TypSysCall,LevArgs,<" Handle $x Cnt $x Buf $x:$x\n">,<BX,CX,DS,DX>
	MOV	SI,OFFSET DOSGROUP:DOS_Read
ReadDo:
	invoke	pJFNFromHandle
	JC	ReadError
	MOV	AL,ES:[DI]
	call	CheckOwner		; get the handle
	JNC	ReadSetup		; no errors do the operation
ReadError:
	fmt TypSysCall,LevLog,<"Read/Write error $x\n">,<AX>
	transfer    SYS_RET_ERR 	; go to error traps
ReadSetup:
	MOV	WORD PTR [ThisSFT],DI	; save offset of pointer
	MOV	WORD PTR [ThisSFT+2],ES ; save segment value
;; Extended Open
	TEST	ES:[DI.sf_mode],INT_24_ERROR  ;AN000;;EO. need i24
	JZ	needi24 		      ;AN000;;EO. yes
	OR	[EXTOPEN_ON],EXT_OPEN_I24_OFF ;AN000;;EO. set it off
needi24:				      ;AN000;

;; Extended Open
	SaveReg <<WORD PTR [DMAAdd]>, <WORD PTR [DMAAdd+2]>>
;;;;;	BAD SPOT FOR 286!!! SEGMENT ARITHMETIC!!!
	CALL	Align_Buffer		;AN000;MS. align user's buffer
;;;;;	END BAD SPOT FOR 286!!! SEGMENT ARITHMETIC!!!

IF	BUFFERFLAG

;	int	3
;	cmp	[BUF_EMS_MODE], -1
;	jz	dos_call
;	call	choose_buf_page
;	jc	ReadError
;	call	save_user_map

;dos_call:
ENDIF
	context DS			; go for DOS addressability
	CALL	SI			; indirect call to operation
	RestoreReg <<WORD PTR [DMAAdd+2]>, <WORD PTR [DMAAdd]>>

IF	BUFFERFLAG
	pushf
	push	ax
	push	bx

	cmp	cs:[BUF_EMS_MODE], -1
	jz	dos_call_done
	call	restore_user_map
	mov	ax, word ptr cs:[BUF_EMS_LAST_PAGE]
	cmp	cs:[BUF_EMS_PFRAME], ax
	je	dos_call_done
	mov	word ptr cs:[LASTBUFFER], -1
	mov	cs:[BUF_EMS_PFRAME], ax
	mov	ax, word ptr cs:[BUF_EMS_LAST_PAGE+2]
	mov	cs:[BUF_EMS_PAGE_FRAME], ax
	mov	cs:[BUF_EMS_SAFE_FLAG], 1
	call	Setup_EMS_Buffers

dos_call_done:
	pop	bx
	pop	ax
	popf
ENDIF

IF	NOT	BUFFERFLAG
	JC	ReadError		; if error, say bye bye
ELSE
	jmp	tmp_rerr
tmp_rerr:
	jc	ReadError
ENDIF

	MOV	AX,CX			; get correct return in correct reg
	fmt TypSysCall,LevLog,<"Read/Write cnt done $x\n">,<AX>
	transfer    sys_ret_ok		; successful return
EndProc $READ

;
;   Input: DS:DX points to user's buffer addr
;   Function: rearrange segment and offset for READ/WRITE buffer
;   Output: [DMAADD] set
;
;

procedure   Align_Buffer,NEAR		;AN000;
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP  ;AN000;
	MOV	BX,DX			; copy offset
	SaveReg <CX>			; don't stomp on count
	MOV	CL,4			; bits to shift bytes->para
	SHR	BX,CL			; get number of paragraphs
	RestoreReg  <CX>		; get count back
	MOV	AX,DS			; get original segment
	ADD	AX,BX			; get new segment
	MOV	DS,AX			; in seg register
	AND	DX,0Fh			; normalize offset
	MOV	WORD PTR [DMAAdd],DX	; use user DX as offset
	MOV	WORD PTR [DMAAdd+2],DS	; use user DS as segment for DMA
	return				;AN000;
EndProc Align_Buffer			;AN000;

BREAK <$WRITE - write to a file handle>

;
;   Assembler usage:
;	    LDS     DX, buf
;	    MOV     CX, count
;	    MOV     BX, handle
;	    MOV     AH, Write
;	    INT     int_command
;	  AX has number of bytes written
;   Errors:
;	    AX = write_invalid_handle
;	       = write_access_denied
;
;   Returns in register AX

procedure   $WRITE,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	fmt TypSysCall,LevLog,<"Write\n">
	fmt TypSysCall,LevArgs,<" Handle $x Cnt $x Buf $x:$x\n">,<BX,CX,DS,DX>
	MOV	SI,OFFSET DOSGROUP:DOS_Write
	JMP	ReadDo
EndProc $Write

BREAK <$LSEEK - move r/w pointer>

;
;   Assembler usage:
;	    MOV     DX, offsetlow
;	    MOV     CX, offsethigh
;	    MOV     BX, handle
;	    MOV     AL, method
;	    MOV     AH, LSeek
;	    INT     int_command
;	  DX:AX has the new location of the pointer
;   Error returns:
;	    AX = error_invalid_handle
;	       = error_invalid_function
;   Returns in registers DX:AX

procedure   $LSEEK,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	call	CheckOwner		; get system file entry
LSeekError:

IF	BUFFERFLAG
	JC	TMP_RERR
ELSE
	JC	ReadError		; error return
ENDIF
	CMP	AL,2			; is the seek value correct?
	JBE	LSeekDisp		; yes, go dispatch
	MOV	EXTERR_LOCUS,errLoc_Unk ; Extended Error Locus
	error	error_invalid_function	; invalid method
LSeekDisp:
	CMP	AL,1			; best way to dispatch; check middle
	JB	LSeekStore		; just store CX:DX
	JA	LSeekEOF		; seek from end of file
	ADD	DX,WORD PTR ES:[DI.SF_Position]
	ADC	CX,WORD PTR ES:[DI.SF_Position+2]
LSeekStore:
	MOV	AX,CX			; AX:DX
	XCHG	AX,DX			; DX:AX is the correct value
LSeekSetpos:
	MOV	WORD PTR ES:[DI.SF_Position],AX
	MOV	WORD PTR ES:[DI.SF_Position+2],DX
	invoke	Get_user_stack
	MOV	DS:[SI.User_DX],DX	; return DX:AX
	transfer    SYS_RET_OK		; successful return

LSeekEOF:
	TEST	ES:[DI.sf_flags],sf_isnet
	JNZ	Check_LSeek_Mode	; Is Net
LOCAL_LSeek:
	ADD	DX,WORD PTR ES:[DI.SF_Size]
	ADC	CX,WORD PTR ES:[DI.SF_Size+2]
	JMP	LSeekStore		; go and set the position

Check_LSeek_Mode:
	TEST	ES:[DI.sf_mode],sf_isfcb
	JNZ	LOCAL_LSeek		; FCB treated like local file
	MOV	AX,ES:[DI.sf_mode]
	AND	AX,sharing_mask
	CMP	AX,sharing_deny_none
	JZ	NET_LSEEK		; LSEEK exported in this mode
	CMP	AX,sharing_deny_read
	JNZ	LOCAL_LSeek		; Treated like local Lseek
NET_LSEEK:
;	 JMP	 LOCAL_LSeek
; REMOVE ABOVE INSTRUCTION TO ENABLE DCR 142
	CallInstall Net_Lseek,multNet,33
	JNC	LSeekSetPos
	transfer    SYS_RET_ERR

EndProc $LSeek

BREAK <FileTimes - modify write times on a handle>

;
;   Assembler usage:
;	    MOV AH, FileTimes (57H)
;	    MOV AL, func
;	    MOV BX, handle
;	; if AL = 1 then then next two are mandatory
;	    MOV CX, time
;	    MOV DX, date
;	    INT 21h
;	; if AL = 0 then CX/DX has the last write time/date
;	; for the handle.
;
;	AL=02		 get extended attributes
;	   BX=handle
;	   CX=size of buffer (0, return max size )
;	   DS:SI query list (si=-1, selects all EA)
;	   ES:DI buffer to hold EA list
;
;	AL=03		 get EA name list
;	   BX=handle
;	   CX=size of buffer (0, return max size )
;	   ES:DI buffer to hold name list
;
;	AL=04		 set extended attributes
;	   BX=handle
;	   ES:DI buffer of EA list
;
;
;
;
;   Error returns:
;	    AX = error_invalid_function
;	       = error_invalid_handle
;

procedure   $File_Times,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	CMP	AL,2			; correct subfunction?
	JAE	gsetxa
	JMP	filetimes_ok		; Yes, continue
;;;; DOS 4.00				;AN000;
gsetxa: 				;AN000;
	EnterCrit   critSFT		;AN000;;FT. enter critical section
	CMP	AL,4			;AN000;;FT. =4
	JBE	gshandle		;AN000;;FT. 2,3,4   do get/set by handle
funcerr:				;AN000;
	JMP	inval_func		;AN000;;FT. invalid function
					;AN000;
gshandle:				;AN000;
	MOV	[SAVE_ES],ES		;AN000;;FT. save regs
	MOV	[SAVE_DI],DI		;AN000;;FT.
	MOV	[SAVE_DS],DS		;AN000;;FT. save regs
	MOV	[SAVE_SI],SI		;AN000;;FT.
	MOV	[SAVE_CX],CX		;AN000;;FT.
	MOV	[XA_TYPE],AL		;AN000;;FT.
					;AN000;
;	MOV	[XA_handle],BX		;AN000;    ;FT. save handle
	CALL	CheckOwner		;AN000;    ;FT. get sf pointer
	JNC	getsetit		;AN000;    ;FT. good handle
	LeaveCrit   critSFT		;AN000;    ;FT. leave critical section
	JMP	LSeekError		;AN000;    ;FT. turkey handle
					;AN000;
getsetit:				;AN000;
	MOV	WORD PTR [ThisSFT],DI	;AN000;       ;FT. set ThisSFT
	MOV	WORD PTR [ThisSFT+2],ES ;AN000;       ;FT. set ThisSFT
;	TEST	ES:[DI.sf_mode],INT_24_ERROR   ;AN000;;FT. mask INT 24
;	JZ	nomask			       ;AN000;;FT. no
;	OR	[EXTOPEN_ON],EXT_OPEN_I24_OFF  ;AN000;;FT. set bit for I24 handler
nomask: 				       ;AN000;
	TEST	ES:[DI.sf_flags],sf_isnet      ;AN000;;FT. remote handle
	JZ	localhandle		       ;AN000;;FT. no
	LeaveCrit   critSFT		       ;AN000;;FT. doesn't support Network

	MOV	BL,[XA_TYPE]		       ;AN000;;FT.
IFSsearch:				       ;AN000;
	MOV	AX,(multNET SHL 8) or 45       ;AN000;;FT. Get/Set XA support
	INT	2FH			       ;AN000;
	JC	getseterror		       ;AN000;;FT. error
	transfer    SYS_RET_OK		       ;AN000;;FT.
localhandle:				       ;AN000;
;	TEST	ES:[DI.sf_flags],devid_device  ;AN000;;FT. device
;	JZ	getsetfile8		       ;AN000;;FT. no
;	MOV	[XA_device],1		       ;AN000;;FT. indicating device
;	JMP	SHORT doXA		       ;AN000;;FT. do XA
getsetfile8:				       ;AN000;
;	MOV	[XA_device],0		       ;AN000;;FT. indicating File
;	LES	BP,ES:[DI.sf_devptr]	       ;AN000;;FT. ES:BP -> DPB

doXA:					       ;AN000;
;	MOV	[XA_from],By_XA 	       ;AN000;;FT. from get/set XA
;	PUSH	[SAVE_ES]		       ;AN000;;FT. save XA list
;	PUSH	[SAVE_DI]		       ;AN000;;FT. save XA list

	invoke	GetSet_XA		       ;AN000;;FT. issue Get/Set XA
;	POP	SI			       ;AN000;;FT. DS:SI -> XA list
;	POP	DS			       ;AN000;
	JC	getexit 		       ;AN000;;FT. error
;	CMP	[XA_device],0		       ;AN000;;FT. device ?
;	JNZ	ftok			       ;AN000;;FT. yes, exit
;	MOV	AX,4			       ;AN000;;FT. function 4 for ShSU
;	CMP	[XA_type],4		       ;AN000;;FT. set XA
;	JNZ	ftok			       ;AN000;;FT. no
;
;
;	LES	DI,[ThisSFT]		       ;AN000;;FT. es:di -> sft
;	CMP	WORD PTR [SI],0 	       ;AN000;;FT. null list ?
;	JNZ	do_share		       ;AN000;;FT. no
	JMP	SHORT ftok		       ;AN000;;FT. return
getexit:				       ;AN000;;FT.
	LeaveCrit   critSFT		       ;AN000;;FT. leave critical section


getseterror:				       ;AN000;
	transfer    SYS_RET_ERR 	       ;AN000;;FT. mark file as dirty
inval_func:

;;;;; DOS 4.00
	MOV	EXTERR_LOCUS,errLoc_Unk ; Extended Error Locus
	error	error_invalid_function	; give bad return
filetimes_ok:
	call	CheckOwner		; get sf pointer
	JNC	gsdt
	JMP	LSeekError		; turkey handle
gsdt:
	OR	AL,AL			; is it Get?
	JNZ	filetimes_set		; no, go set the time
	CLI
	MOV	CX,ES:[DI.sf_Time]	; suck out time
	MOV	DX,ES:[DI.sf_Date]	; and date
	STI
	invoke	Get_user_stack		; obtain place to return it
	MOV	[SI.user_CX],CX 	; and stash in time
	MOV	[SI.user_DX],DX 	; and stask in date
ext_done:
	transfer    SYS_RET_OK		; and say goodnight
filetimes_set:
	EnterCrit   critSFT
	MOV	ES:[DI.sf_Time],CX	; drop in new time
	MOV	ES:[DI.sf_Date],DX	; and date
	XOR	AX,AX
do_share:
if installed
	Call	JShare + 14 * 4
else
	Call	ShSU
endif
datetimeflg:
	AND	ES:[DI.sf_Flags],NOT devid_file_clean
	OR	ES:[DI.sf_Flags],sf_close_nodate
ftok:
	LeaveCrit   critSFT
	transfer    SYS_RET_OK		; mark file as dirty and return
EndProc $File_Times

BREAK <$DUP - duplicate a jfn>
;
;   Assembler usage:
;	    MOV     BX, fh
;	    MOV     AH, Dup
;	    INT     int_command
;	  AX has the returned handle
;   Errors:
;	    AX = dup_invalid_handle
;	       = dup_too_many_open_files
Procedure   $DUP,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	MOV	AX,BX			; save away old handle in AX
	invoke	JFNFree 		; free handle? into ES:DI, new in BX
DupErrorCheck:
	JC	DupErr			; nope, bye
	SaveReg <ES,DI> 		; save away SFT
	RestoreReg  <SI,DS>		; into convenient place DS:SI
	XCHG	AX,BX			; get back old handle
	call	CheckOwner		; get sft in ES:DI
	JC	DupErr			; errors go home
	invoke	DOS_Dup_Direct
	invoke	pJFNFromHandle		; get pointer
	MOV	BL,ES:[DI]		; get SFT number
	MOV	DS:[SI],BL		; stuff in new SFT
	transfer    SYS_RET_OK		; and go home
DupErr: transfer    SYS_RET_ERR

EndProc $Dup

BREAK <$DUP2 - force a dup on a particular jfn>
;
;   Assembler usage:
;	    MOV     BX, fh
;	    MOV     CX, newfh
;	    MOV     AH, Dup2
;	    INT     int_command
;   Error returns:
;	    AX = error_invalid_handle
;
Procedure   $Dup2,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	SaveReg <BX,CX> 		; save source
	MOV	BX,CX			; get one to close
	invoke	$Close			; close destination handle
	RestoreReg  <BX,AX>		; old in AX, new in BX
	invoke	pJFNFromHandle		; get pointer
	JMP	DupErrorCheck		; check error and do dup
EndProc $Dup2

Break	<CheckOwner - verify ownership of handles from server>

;
;   CheckOwner - Due to the ability of the server to close file handles for a
;   process without the process knowing it (delete/rename of open files, for
;   example), it is possible for the redirector to issue a call to a handle
;   that it soes not rightfully own.  We check here to make sure that the
;   issuing process is the owner of the SFT.  At the same time, we do a
;   SFFromHandle to really make sure that the SFT is good.
;
;   Inputs:	BX has the handle
;		User_ID is the current user
;   Output:	Carry Clear => ES:DI points to SFT
;		Carry Set => AX has error code
;   Registers modified: none
;

Procedure   CheckOwner,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
	invoke	SFFromHandle
	retc
	push	ax
	mov	ax,user_id
	cmp	ax,es:[di].sf_UID
	pop	ax
	retz
	mov	al,error_invalid_handle
	stc
	return
EndProc CheckOwner

;-------------------------------------------------------------------------
;	Function name	: 	choose_buf_page
;	Inputs		:	DMAADD = Xaddr
;				cx = # of bytes to transfer
;	Outputs		:	if NC
;
;				SAFE_FLAG - 0 ==> page is safe. no need to
;						  detect collision between
;						  user & system buffer.
;				SAFE_FLAG - 1 ==> page is unsafe. Must check
;						  for collision
;
;				CY - error
;
;
;	High Level Alogrithm:
;
;	1. If Xaddr. is above the first physical page above 640K
;	   2. choose that page
;	   3. set safe flag
;	4. else
;	   5. choose highest page above 640K
;	   6. If 6 or more pages above 640k
;	      7. Set safe flag				
;	   8. else
;	      9. if Xaddr. + # of bytes to transfer does not spill into the
;	     	 chosen page
;		 10. set safe flag
;	      11.else
;		 12. clear safe flag
;	      13.endif
;	   14.endif
;	15.endif
;
;----------------------------------------------------------------------------
;Procedure 	choose_buf_page,near
;
;	assume cs:dosgroup, ds:nothing, es:nothing, ss:dosgroup
;
;	push	cx
;	push	bx
;	push	dx
;	push	si
;	push	ds
;	push	ax
;
;	mov	ax, word ptr [DMAADD+2]
;	and	ax, 0fc00h  	; page segment of transfer segment
;
;	cmp	ax, word ptr [BUF_EMS_FIRST_PAGE]
;	ja	pick_first
;	
;	cmp	[BUF_EMS_NPA640], 6
;	jae	safe_pick_last
;
;	add	cx, word ptr [DMAADD]	; get final offset 
;	mov	bx, cx
;
;	mov	cl, 4
;	shr	bx, cl		; get # of paragraphs
;	mov	ax, word ptr [DMAADD+2]	; get initial segment
;	add	ax, bx		; get final segment
;
;	and	ax, 0fc00h
;	cmp	ax, word ptr [BUF_EMS_LAST_PAGE]
;	jne	safe_pick_last
;
;	mov	[BUF_EMS_SAFE_FLAG], 0
;	jmp	fin_choose_page
;
;safe_pick_last:
;	mov	[BUF_EMS_SAFE_FLAG], 1
;	jmp	fin_choose_page
;
;;pick_last:
;;	mov	ax, word ptr [BUF_EMS_LAST_PAGE]
;;	mov	[BUF_EMS_PFRAME], ax
;;	mov	ax, word ptr [BUF_EMS_LAST_PAGE+2]
;;	mov	[BUF_EMS_PAGE_FRAME], ax
;;	xor	ax, ax
;;	jmp	fin_choose_page
;
;pick_first:
;	mov	ax, word ptr [BUF_EMS_FIRST_PAGE]
;	cmp	[BUF_EMS_PFRAME], ax
;	je	fin_choose_page
;	mov	word ptr [LASTBUFFER], -1
;	mov	[BUF_EMS_PFRAME], ax
;	mov	ax, word ptr [BUF_EMS_FIRST_PAGE+2]
;	mov	[BUF_EMS_PAGE_FRAME], ax
;	mov	[BUF_EMS_SAFE_FLAG], 1
;	call	Setup_EMS_Buffers
;	jmp	fin_choose_page
;
;err_choose_page:
;	stc
;
;fin_choose_page:
;	clc
;
;	pop	ax
;	pop	ds
;	pop	si
;	pop	dx
;	pop	bx
;	pop	cx
;	return
;
;EndProc	choose_buf_page	
;

CODE	ENDS
END
