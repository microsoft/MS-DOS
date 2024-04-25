 page 80,132
;	SCCSID = @(#)command2.asm	4.3 85/10/16
;	SCCSID = @(#)command2.asm	4.3 85/10/16
TITLE	COMMAND2 - resident code for COMMAND.COM part II
NAME	COMMAND2
.XCREF
.XLIST
	INCLUDE DOSSYM.INC
	INCLUDE comsw.asm
	INCLUDE comequ.asm
	INCLUDE resmsg.equ		;AN000;
.LIST
.CREF

tokenized = FALSE

CODERES 	SEGMENT PUBLIC BYTE	;AC000;
CODERES ENDS

DATARES SEGMENT PUBLIC BYTE
	EXTRN	append_state:word	;AN020;
	EXTRN	append_flag:byte	;AN020;
	EXTRN	COMDRV:BYTE
	EXTRN	comprmt1_block:byte	;AN000;
	EXTRN	comprmt1_subst:byte	;AN000;
	EXTRN	COMSPEC:BYTE
	EXTRN	cpdrv:byte
	EXTRN	envirseg:word
	EXTRN	EXTCOM:BYTE
	EXTRN	HANDLE01:WORD
	EXTRN	InitFlag:BYTE
	EXTRN	INT_2E_RET:DWORD	;AC000;
	EXTRN	IO_SAVE:WORD
	EXTRN	LOADING:BYTE
	EXTRN	LTPA:WORD
	EXTRN	MEMSIZ:WORD
	EXTRN	number_subst:byte	;AN000;
	EXTRN	OldTerm:DWORD		;AC000;
	EXTRN	PARENT:WORD		;AC000;
	EXTRN	PERMCOM:BYTE
	EXTRN	RDIRCHAR:BYTE
	EXTRN	RES_TPA:WORD
	EXTRN	RETCODE:WORD
	EXTRN	rsrc_xa_seg:word	;AN030;
	EXTRN	RSWITCHAR:BYTE
	EXTRN	SAVE_PDB:WORD
	EXTRN	SINGLECOM:WORD
	EXTRN	SUM:WORD
	EXTRN	TRANS:WORD
	EXTRN	TranVarEnd:BYTE
	EXTRN	TRANVARS:BYTE
	EXTRN	TRNSEG:WORD
	EXTRN	VERVAL:WORD
DATARES ENDS

BATARENA	SEGMENT PUBLIC PARA	;AC000;
BATARENA ENDS

BATSEG		SEGMENT PUBLIC PARA	;AC000;
BATSEG	 ENDS

ENVARENA	SEGMENT PUBLIC PARA	;AC000;
ENVARENA  ENDS

ENVIRONMENT SEGMENT PUBLIC PARA 	; Default COMMAND environment
ENVIRONMENT ENDS

INIT	SEGMENT PUBLIC PARA
	EXTRN	envsiz:word
	EXTRN	oldenv:word
	EXTRN	resetenv:byte
	EXTRN	usedenv:word
INIT	ENDS

TAIL	SEGMENT PUBLIC PARA
TAIL	ENDS

TRANCODE	SEGMENT PUBLIC PARA
TRANCODE	ENDS

TRANDATA	SEGMENT PUBLIC BYTE
	EXTRN	TRANDATAEND:BYTE
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE
	EXTRN	TRANSPACEEND:BYTE
	EXTRN	HEADCALL:DWORD
TRANSPACE	ENDS

TRANTAIL	SEGMENT PUBLIC PARA
TRANTAIL	ENDS

RESGROUP  GROUP CODERES,DATARES,BATARENA,BATSEG,ENVARENA,ENVIRONMENT,INIT,TAIL
TRANGROUP GROUP TRANCODE,TRANDATA,TRANSPACE,TRANTAIL

; START OF RESIDENT PORTION

CODERES 	SEGMENT PUBLIC BYTE	;AC000;

	PUBLIC	CHKSUM
	PUBLIC	endinit
	PUBLIC	GETCOMDSK2
	PUBLIC	INT_2E
	PUBLIC	LOADCOM
	PUBLIC	LODCOM
	PUBLIC	LODCOM1
	PUBLIC	RESTHAND
	PUBLIC	SAVHAND
	PUBLIC	SETVECT
	PUBLIC	THEADFIX
	PUBLIC	TREMCHECK
	PUBLIC	tjmp

ASSUME	CS:RESGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	contc:near
	EXTRN	DSKERR:NEAR
	EXTRN	rstack:word
;
; If we cannot allocate enough memory for the transient or there was some
; other allocation error, we display a message and then die.
;
BADMEMERR:				; Allocation error loading transient
	MOV	DX,BMEMMES		;AC000; get message number
FATALC:
	PUSH	CS
	POP	DS
	ASSUME	DS:ResGroup
	invoke	RPRINT
;
; If this is NOT a permanent (top-level) COMMAND, then we exit; we can't do
; anything else!
;
	CMP	PERMCOM,0
	JZ	FATALRET
;
; We are a permanent command.  If we are in the process of the magic interrupt
; (Singlecom) then exit too.
;
	CMP	SINGLECOM,0		; If PERMCOM and SINGLECOM
	JNZ	FATALRET		; Must take INT_2E exit
;
; Permanent command.  We can't do ANYthing except halt.
;
	MOV	DX,HALTMES		;AC000; get message number
	invoke	RPRINT
	STI
STALL:
	JMP	STALL			; Crash the system nicely

FATALRET:
	MOV	DX,FRETMES		;AC000; get message number
	invoke	RPRINT
FATALRET2:
	CMP	[PERMCOM],0		; If we get here and PERMCOM,
	JNZ	RET_2E			; must be INT_2E
	invoke	reset_msg_pointers	;AN000; reset critical & parse error messages
	MOV	AX,[PARENT]
	MOV	WORD PTR CS:[PDB_Parent_PID],AX
	MOV	AX,WORD PTR OldTerm
	MOV	WORD PTR CS:[PDB_Exit],AX
	MOV	AX,WORD PTR OldTerm+2
	MOV	WORD PTR CS:[PDB_Exit+2],AX
	MOV	AX,(EXIT SHL 8) 	; Return to lower level
	INT	int_command

RET_2E:
	PUSH	CS
	POP	DS
ASSUME	DS:RESGROUP,ES:NOTHING,SS:NOTHING
	MOV	[SINGLECOM],0		; Turn off singlecom
	MOV	ES,[RES_TPA]
	MOV	AH,DEALLOC
	INT	int_command		; Free up space used by transient
	MOV	BX,[SAVE_PDB]
	MOV	AH,SET_CURRENT_PDB
	INT	int_command		; Current process is user
	MOV	AX,[RETCODE]
	CMP	[EXTCOM],0
	JNZ	GOTECODE
	XOR	AX,AX			; Internals always return 0
GOTECODE:
	MOV	[EXTCOM],1		; Force external
	JMP	[INT_2E_RET]		;"IRET"

INT_2E: 				; Magic command executer
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	POP	WORD PTR [INT_2E_RET]
	POP	WORD PTR [INT_2E_RET+2] ;Get return address
	POP	AX			;Chuck flags
	PUSH	CS
	POP	ES
	MOV	DI,80H
	MOV	CX,64
	REP	MOVSW
	MOV	AH,GET_CURRENT_PDB
	INT	int_command		; Get user's header
	MOV	[SAVE_PDB],BX
	MOV	AH,SET_CURRENT_PDB
	MOV	BX,CS
	INT	int_command		; Current process is me
	MOV	[SINGLECOM],81H
	MOV	[EXTCOM],1		; Make sure this case forced

LODCOM: 				; Termination handler
	CMP	[EXTCOM],0
	jz	lodcom1 		; if internal, memory already allocated
	mov	bx,0ffffh
	MOV	AH,ALLOC
	INT	int_command
	CALL	SetSize
	ADD	AX,20H
	CMP	BX,AX			; Is less than 512 byte buffer worth it?
	JNC	MEMOK
BADMEMERRJ:
	JMP BADMEMERR			; Not enough memory

; SetSize - get transient size in paragraphs
Procedure   SetSize,NEAR
	MOV	AX,OFFSET TRANGROUP:TRANSPACEEND + 15
	MOV	CL,4
	SHR	AX,CL
	return
EndProc SetSize

MEMOK:
	MOV	AH,ALLOC
	INT	int_command
	JC	BADMEMERRJ		; Memory arenas probably trashed
	MOV	[EXTCOM],0		; Flag not to ALLOC again
	MOV	[RES_TPA], AX		; Save current TPA segment
	AND	AX, 0F000H
	ADD	AX, 01000H		; Round up to next 64K boundary
	JC	BAD_TPA 		; Memory wrap if carry set
; Make sure that new boundary is within allocated range
	MOV	DX, [RES_TPA]
	ADD	DX, BX			; Compute maximum address
	CMP	DX, AX			; Is 64K address out of range?
	JBE	BAD_TPA
; Must have 64K of usable space.
	SUB	DX, AX			; Compute the usable space
	CMP	DX, 01000H		; Is space >= 64K ?
	JAE	LTPASET
BAD_TPA:
	MOV	AX, [RES_TPA]
LTPASET:
	MOV	[LTPA],AX		; Usable TPA is 64k buffer aligned
	MOV	AX, [RES_TPA]		; Actual TPA is buffer allocated
	ADD	BX,AX
	MOV	[MEMSIZ],BX
	CALL	SetSize
	SUB	BX,AX
	MOV	[TRNSEG],BX		; Transient starts here
LODCOM1:
	MOV	AX,CS
	MOV	SS,AX
ASSUME	SS:RESGROUP
	MOV	SP,OFFSET RESGROUP:RSTACK
	MOV	DS,AX
ASSUME	DS:RESGROUP
	CALL	HEADFIX 		; Make sure files closed stdin and stdout restored
	XOR	BP,BP			; Flag command ok
	MOV	AX,-1
	XCHG	AX,[VERVAL]
	CMP	AX,-1
	JZ	NOSETVER
	MOV	AH,SET_VERIFY_ON_WRITE	; AL has correct value
	INT	int_command
NOSETVER:
	CMP	[SINGLECOM],-1
	JNZ	NOSNG
	JMP	FATALRET2		; We have finished the single command
NOSNG:
	CALL	CHKSUM			; Check the transient
	CMP	DX,[SUM]
	JZ	HAVCOM			; Transient OK
BOGUS_COM:
	MOV	[LOADING],1		; Flag DSKERR routine
	CALL	LOADCOM
CHKSAME:

	CALL	CHKSUM
	CMP	DX,[SUM]
	JZ	HAVCOM			; Same COMMAND
ALSO_BOGUS:
	CALL	WRONGCOM
	JMP	SHORT CHKSAME
HAVCOM:
	MOV	AX,CHAR_OPER SHL 8
	INT	int_command
	MOV	[RSWITCHAR],DL
	CMP	DL,'/'
	JNZ	USESLASH
	mov	cl,'\'
	MOV	[RDIRCHAR],cl		; Select alt path separator
USESLASH:
	MOV	[LOADING],0		; Flag to DSKERR
	MOV	SI,OFFSET RESGROUP:TRANVARS
	MOV	DI,OFFSET TRANGROUP:HEADCALL
	MOV	ES,[TRNSEG]
	CLD
	MOV	CX,OFFSET ResGroup:TranVarEnd
	SUB	CX,SI
	REP	MOVSB			; Transfer INFO to transient
	MOV	AX,[MEMSIZ]
	MOV	WORD PTR DS:[PDB_block_len],AX	; Adjust my own header

; Just a public label so this spot can be found easily.
tjmp:
	JMP	DWORD PTR [TRANS]

; Far call to REMCHECK for TRANSIENT
TREMCHECK PROC	 FAR
	CALL	REMCHECK
	RET
TREMCHECK ENDP

REMCHECK:
;All registers preserved. Returns ZF set if media removable, NZ if fixed
; AL is drive (0=DEF, 1=A,...).
	SaveReg <AX,BX>
	MOV	BX,AX
	MOV	AX,(IOCTL SHL 8) + 8
	INT	21h
	jnc	RCcont			; If an error occurred, assume the media
	or	ax,ax			;  is NON-removable.
					;  AX contains the non-zero error code
					;  from the INT 21, so the OR AX,AX sets
					;  Non-zero. This behavior makes Network
					;  drives appear to be non-removable.
	jmp	SHORT ResRegs
RCcont:
	AND	AX,1
	NOT	AX
ResRegs:
	RestoreReg  <BX,AX>
	return

; Far call to HEADFIX for TRANSIENT
THEADFIX PROC	FAR
	CALL	HEADFIX
	RET
THEADFIX ENDP

HEADFIX:
	CALL	SETVECT
	XOR	BX,BX			; Clean up header
	MOV	CX,[IO_SAVE]
	MOV	DX,WORD PTR DS:[PDB_JFN_Table]
	CMP	CL,DL
	JZ	CHK1			; Stdin matches
	MOV	AH,CLOSE
	INT	int_command
	MOV	DS:[PDB_JFN_Table],CL	; Restore stdin
CHK1:
	INC	BX
	CMP	CH,DH			; Stdout matches
	JZ	CHKOTHERHAND
	MOV	AH,CLOSE
	INT	int_command
	MOV	DS:[PDB_JFN_Table+1],CH ; Restore stdout
CHKOTHERHAND:
	ADD	BX,4			; Skip 2,3,4
	MOV	CX,FilPerProc - 5	; Already done 0,1,2,3,4
CLOSELOOP:
	MOV	AH,CLOSE
	INT	int_command
	INC	BX
	LOOP	CLOSELOOP
	push	ds			;AN020; save data segment
	push	cs			;AN020; Get local segment into DS
	pop	ds			;AN020;
	cmp	append_flag,-1		;AN020; Do we need to reset APPEND?
	jnz	append_fix_end		;AN030; no - just exit
	mov	ax,AppendSetState	;AN020; Set the state of Append
	mov	bx,Append_state 	;AN020;     back to the original state
	int	2fh			;AN020;
	mov	append_flag,0		;AN020; Set append flag to invalid
append_fix_end: 			;AN030;
	cmp	[rsrc_xa_seg],no_xa_seg ;AN030; Is there any active XA segment?
	jz	xa_fix_end		;AN030; no - exit
	push	es			;AN030; Yes - deallocate it
	mov	es,rsrc_xa_seg		;AN030;
	mov	ax,(Dealloc SHL 8)	;AN030; Deallocate memory call
	int	int_command		;AN030;
	pop	es			;AN030;
	mov	[rsrc_xa_seg],no_xa_seg ;AN030; reset to no segment
xa_fix_end:
	pop	ds			;AN020; get data segment back
	return

SAVHAND:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSH	DS
	PUSH	BX			; Set stdin to sterr, stdout to stderr
	PUSH	AX
	MOV	AH,GET_CURRENT_PDB
	INT	int_command		; Get user's header
	MOV	DS,BX
	LDS	BX,DS:[PDB_JFN_POINTER] ; get pointer to JFN table...
	MOV	AX,WORD PTR DS:[BX]
	MOV	[HANDLE01],AX		; Save user's stdin, stdout
	MOV	AL,CS:[PDB_JFN_Table+2] ; get COMMAND stderr
	MOV	AH,AL
	MOV	WORD PTR DS:[BX],AX	; Dup stderr
	POP	AX
	POP	BX
	POP	DS
	return

ASSUME	DS:RESGROUP
GETCOMDSK2:
	CALL	GETCOMDSK
	JMP	LODCOM1 		; Memory already allocated

RESTHAND:
	PUSH	DS
	PUSH	BX			; Restore stdin, stdout to user
	PUSH	AX
	MOV	AH,GET_CURRENT_PDB
	INT	int_command		; Point to user's header
	MOV	AX,[HANDLE01]
	MOV	DS,BX
ASSUME DS:NOTHING
	LDS	BX,DS:[PDB_JFN_POINTER] ; get pointer to JFN table...
	MOV	WORD PTR DS:[BX],AX	; Stuff his old 0 and 1
	POP	AX
	POP	BX
	POP	DS
	return
ASSUME DS:RESGROUP,SS:RESGROUP

HOPELESS:
	MOV	DX,COMBAD		;AC000;
	JMP	FATALC

GETCOMDSK:
	mov	al,[comdrv]
	CALL	REMCHECK
	jNZ	HOPELESS		;Non-removable media
getcomdsk3:
	cmp	dx,combad		;AC000;
	jnz	getcomdsk4
	mov	dx,combad		;AN000; get message number
	invoke	RPRINT			; Say command is invalid
getcomdsk4:
	cmp	[cpdrv],0		;g is there a drive in the comspec?
	jnz	users_drive		;g yes - use it
	mov	ah,Get_default_drive	;g use default drive
	int	21h			;g
	add	al,"A"                  ;g convert to ascii
	mov	[cpdrv],al		;g put in message to print out

users_drive:				;g
	mov	dx,comprmt1		;AC000; Prompt for diskette containing command
IF tokenized
	or	byte ptr [si],80h
endif
	MOV	AL,COMPRMT1_SUBST	;AN000; get number of substitutions
	MOV	SI,OFFSET RESGROUP:COMPRMT1_BLOCK ;AN000; get address of subst block
	MOV	NUMBER_SUBST,AL 	;AN000;
	invoke	rprint
if tokenized
	and	byte ptr [si],NOT 80h
endif
	mov	dx,prompt		;AN047; Tell the user to strike a key
	invoke	rprint			;AN047;
	CALL	GetRawFlushedByte
	return

; flush world and get raw input
GetRawFlushedByte:
	MOV	AX,(STD_CON_INPUT_FLUSH SHL 8) OR RAW_CON_INPUT
	INT	int_command		; Get char without testing or echo
	MOV	AX,(STD_CON_INPUT_FLUSH SHL 8) + 0
	INT	int_command
	return

LOADCOM:				; Load in transient
	INC	BP			; Flag command read
	MOV	DX,OFFSET RESGROUP:COMSPEC
	MOV	AX,OPEN SHL 8
	INT	int_command		; Open COMMAND.COM
	JNC	READCOM
	CMP	AX,error_too_many_open_files
	JNZ	TRYDOOPEN
	MOV	DX,NOHANDMES		;AC000;
	JMP	FATALC			; Fatal, will never find a handle

TRYDOOPEN:
	CALL	GETCOMDSK
	JMP	LOADCOM

READCOM:
	MOV	BX,AX			; Handle
	MOV	DX,OFFSET RESGROUP:TRANSTART
	XOR	CX,CX			; Seek loc
	MOV	AX,LSEEK SHL 8
	INT	int_command
	JC	WRONGCOM1
	MOV	CX,OFFSET TRANGROUP:TRANSPACEEND - 100H

	PUSH	DS
	MOV	DS,[TRNSEG]
ASSUME	DS:NOTHING
	MOV	DX,100H
	MOV	AH,READ
	INT	int_command
	POP	DS
ASSUME	DS:RESGROUP
WRONGCOM1:
	PUSHF
	PUSH	AX
	MOV	AH,CLOSE
	INT	int_command		; Close COMMAND.COM
	POP	AX
	POPF
	JC	WRONGCOM		; If error on READ
	CMP	AX,CX
	retz				; Size matched
WRONGCOM:
	MOV	DX,COMBAD		;AC000;
	CALL	GETCOMDSK
	JMP	LOADCOM 		; Try again

CHKSUM: 				; Compute transient checksum
	PUSH	DS
	MOV	DS,[TRNSEG]
	MOV	SI,100H
	MOV	CX,OFFSET TRANGROUP:TranDataEnd  - 100H

CHECK_SUM:
	CLD
	SHR	CX,1
	XOR	DX,DX
CHK:
	LODSW
	ADD	DX,AX
	ADC	DX,0
	LOOP	CHK
	POP	DS
	return

SETVECT:				; Set useful vectors
	MOV	DX,OFFSET RESGROUP:LODCOM
	MOV	AX,(SET_INTERRUPT_VECTOR SHL 8) OR 22H
	MOV	WORD PTR DS:[PDB_EXIT],DX
	MOV	WORD PTR DS:[PDB_EXIT+2],DS
	INT	int_command
	MOV	DX,OFFSET RESGROUP:CONTC
	INC	AL
	INT	int_command
	MOV	DX,OFFSET RESGROUP:DSKERR
	INC	AL
	INT	int_command
	return


;
;  This routine moves the environment to a newly allocated segment
;  at the end of initialization
;

ENDINIT:
	push	ds			;g save segments
	push	es			;g
	push	cs			;g get resident segment to DS
	pop	ds			;g
	ASSUME	DS:RESGROUP
	mov	cx,usedenv		;g get number of bytes to move
	mov	es,envirseg		;g get target environment segment

	ASSUME	ES:NOTHING
	mov	DS:[PDB_environ],es	;g put new environment in my header	   ;AM067;
	mov	ds,oldenv		;g source environment segment		   ;AM067;
	ASSUME	DS:NOTHING							   ;AM067;
	xor	si,si			;g set up offsets to start of segments	   ;AM067;
	xor	di,di			;g					   ;AM067;
	cld				;g make sure we move the right way!	   ;AM067;
	rep	movsb			;g move it				   ;AM067;
	xor	ax,ax			;g					   ;AM067;
	stosb				;g make sure there are double 0 at end	   ;AM067;

	cmp	resetenv,1		;eg Do we need to setblock to env end?
	jnz	noreset 		;eg no - we already did it
	mov	bx,envsiz		;eg get size of environment in paragraphs
	push	es			;eg save environment - just to make sure
	mov	ah,SETBLOCK		;eg
	int	int_command		;eg
	pop	es			;eg

noreset:
	mov	InitFlag,FALSE		;AC042; Turn off init flag
	pop	es			;g
	pop	ds			;g
	jmp	lodcom			;g allocate transient

CODERES ENDS

; This TAIL segment is used to produce a PARA aligned label in the resident
; group which is the location where the transient segments will be loaded
; initial.

TAIL	SEGMENT PUBLIC PARA
	ORG	0
	PUBLIC	TranStart
TRANSTART	LABEL	WORD
TAIL	ENDS

; This TAIL segment is used to produce a PARA aligned label in the transient
; group which is the location where the exec segments will be loaded
; initial.

TRANTAIL    SEGMENT PUBLIC PARA
	ORG	0
EXECSTART   LABEL   WORD
TRANTAIL    ENDS

	END
