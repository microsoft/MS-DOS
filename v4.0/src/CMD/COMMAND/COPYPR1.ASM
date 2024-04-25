 page 80,132
;	SCCSID = @(#)copypr1.asm	1.1 85/05/14
;	SCCSID = @(#)copypr1.asm	1.1 85/05/14
	INCLUDE comsw.asm

.xlist
.xcref
	INCLUDE DOSSYM.INC
;	INCLUDE DEVSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm
.list
.cref


TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	DEVWMES_ptr:word
	EXTRN	ext_open_parms:byte	;AN000;
	EXTRN	ext_open_seg:word	;AN000;
	EXTRN	ext_open_off:word	;AN000;
	EXTRN	Extend_buf_sub:byte	;AN000;
	EXTRN	LOSTERR_ptr:word
	EXTRN	NOSPACE_ptr:word
	EXTRN	OVERWR_ptr:word
TRANDATA ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	ASCII:BYTE
	EXTRN	BINARY:BYTE
	EXTRN	CFLAG:BYTE
	EXTRN	CONCAT:BYTE
	EXTRN	concat_xa:byte		;AC000;
	EXTRN	DESTBUF:BYTE
	EXTRN	DESTCLOSED:BYTE
	EXTRN	DESTHAND:WORD
	EXTRN	DESTISDEV:BYTE
	EXTRN	DESTSWITCH:WORD
	EXTRN	INEXACT:BYTE
	EXTRN	NOWRITE:BYTE
	EXTRN	NXTADD:WORD
	EXTRN	plus_comma:byte 	;AN000;
	EXTRN	RDEOF:BYTE
	EXTRN	src_xa_seg:word 	;AN000;
	EXTRN	SRCISDEV:BYTE
	EXTRN	string_ptr_2:word	;AN000;
	EXTRN	TERMREAD:BYTE
	EXTRN	TPA:WORD
	EXTRN	WRITTEN:WORD
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

	EXTRN	ENDCOPY:NEAR

	PUBLIC	FLSHFIL
	PUBLIC	TRYFLUSH

ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING

TRYFLUSH:
	mov	al,[CONCAT]
	push	ax
	call	FLSHFIL
	pop	ax
	cmp	al,[CONCAT]
	return

FLSHFIL:
;
; Write out any data remaining in memory.
; Inputs:
;	[NXTADD] = No. of bytes to write
;	[CFLAG] <> 0 if file has been created
; Outputs:
;	[NXTADD] = 0
;
	MOV	[TERMREAD],0
	cmp	[CFLAG],0
	JZ	NOTEXISTS
	JMP	EXISTS

NOTEXISTS:
	invoke	BUILDDEST			; Find out all about the destination
	invoke	COMPNAME			; Source and dest. the same?
	JNZ	PROCDEST			; If not, go ahead
	CMP	[SRCISDEV],0
	JNZ	PROCDEST			; Same name on device OK
	CMP	[CONCAT],0			; Concatenation?
	MOV	DX,OFFSET TRANGROUP:OVERWR_ptr
	JNZ	NO_CONCAT_ERR			;AC000; If not, overwrite error
	JMP	COPERR				;AC000;

NO_CONCAT_ERR:					;AC000;
	MOV	[NOWRITE],1			; Flag not writting (just seeking)

PROCDEST:
	MOV	AX,EXTOPEN SHL 8		;AC000; open the file
	mov	si,offset trangroup:destbuf	;AN030; get file name
	mov	di,-1				;AN030; indicate no parameters
	cmp	src_xa_seg,no_xa_seg		;AN030; is there an XA segment?
	jz	cont_no_xa			;AN030; no - no parameters
	mov	di,offset trangroup:Ext_open_parms ;AN030; get parameters
	mov	bx,src_xa_seg			;AN030; get extended attribute segment
	mov	ext_open_seg,bx 		;AN030; put it in parameter list
	mov	ext_open_off,0			;AN030; offset is 0

cont_no_xa:					;AN030;
	mov	bx,write_open_mode		;AN000; get open mode for COPY
	xor	cx,cx				;AN000; no special files
	mov	dx,write_open_flag		;AN000; set up open flags

	CMP	[NOWRITE],0
	JNZ	DODESTOPEN		; Don't actually create if NOWRITE set
	mov	dx,creat_open_flag		;AC000; set up create flags

DODESTOPEN:
	INT	int_command
;
; We assume that the error is normal.  TriageError will correct the DX value
; appropriately.
;
	JNC	dest_open_okay			;AC030;

xa_set_error:					;AN030; error occurred on XA
	invoke	set_ext_error_msg		;AN030; get extended error

ext_err_set:					;AN030;
	mov	string_ptr_2,offset trangroup:destbuf ;AN000; get address of failed string
	mov	Extend_buf_sub,one_subst	;AN030; put number of subst in control block

COPERRJ2:					;AN030;
	jmp	COPERR				;AN030; go issue message

dest_open_okay: 				;AC030
	mov	[DESTHAND],ax			; Save handle
	mov	[CFLAG],1			; Destination now exists
	mov	bx,ax
	mov	cx,bx				;AN030; get handle into CX
	invoke	set_file_code_page		;AN030; set the code page for the target
	jc	ext_err_set			;AN030; if no error, continue

	mov	[concat_xa],0			;AN000; set first file flag off
	mov	ax,(IOCTL SHL 8)
	INT	int_command			; Get device stuff
	mov	[DESTISDEV],dl			; Set dest info
	test	dl,devid_ISDEV
	jz	exists				;AC030; Dest a device

	mov	al,BYTE PTR [DESTSWITCH]
	AND	AL,SwitchA+SwitchB
	JNZ	TESTBOTH
	MOV	AL,[ASCII]			; Neither set, use current setting
	OR	AL,[BINARY]
	JZ	EXSETA				; Neither set, default to ASCII

TESTBOTH:
	JPE	EXISTS				; Both are set, ignore
	test	AL,SwitchB
	jz	EXISTS				; Leave in cooked mode
	mov	ax,(IOCTL SHL 8) OR 1
	xor	dh,dh
	or	dl,devid_RAW
	mov	[DESTISDEV],dl			; New value
	INT	int_command			; Set device to RAW mode
	jmp	short EXISTS

COPERRJ:
	jmp	SHORT COPERR

EXSETA:
;
; What we read in may have been in binary mode, flag zapped write OK
;
	mov	[ASCII],SwitchA 		; Set ASCII mode
	or	[INEXACT],SwitchA		; ASCII -> INEXACT

EXISTS:
	cmp	[NOWRITE],0
	jnz	NOCHECKING			; If nowrite don't bother with name check
	cmp	plus_comma,1			;g  don't check if just doing +,,
	jz	NOCHECKING			;g
	invoke	COMPNAME			; Source and dest. the same?
	JNZ	NOCHECKING			; If not, go ahead
	CMP	[SRCISDEV],0
	JNZ	NOCHECKING			; Same name on device OK
;
; At this point we know in append (would have gotten overwrite error on first
; destination create otherwise), and user trying to specify destination which
; has been scribbled already (if dest had been named first, NOWRITE would
; be set).
;
	MOV	DX,OFFSET TRANGROUP:LOSTERR_ptr ; Tell him he's not going to get it
	invoke	std_Eprintf			;AC022;
	MOV	[NXTADD],0			; Set return
	INC	[TERMREAD]			; Tell Read to give up

RET60:
	return

NOCHECKING:
	mov	bx,[DESTHAND]			; Get handle
	XOR	CX,CX
	XCHG	CX,[NXTADD]
	JCXZ	RET60				; If Nothing to write, forget it
	INC	[WRITTEN]			; Flag that we wrote something
	CMP	[NOWRITE],0			; If NOWRITE set, just seek CX bytes
	JNZ	SEEKEND
	XOR	DX,DX
	PUSH	DS
	MOV	DS,[TPA]
ASSUME	DS:NOTHING
	MOV	AH,WRITE
	INT	int_command
	POP	DS
ASSUME	DS:TRANGROUP
	MOV	DX,OFFSET TRANGROUP:NOSPACE_ptr
	JC	xa_set_error_Jmp		;AC022; Failure
	sub	cx,ax
	retz					; Wrote all supposed to
	test	[DESTISDEV],devid_ISDEV
	jz	COPERR				; Is a file, error
	test	[DESTISDEV],devid_RAW
	jnz	DEVWRTERR			; Is a raw device, error
	cmp	[INEXACT],0
	retnz					; INEXACT so OK
	dec	cx
	retz					; Wrote one byte less (the ^Z)

DEVWRTERR:
	MOV	DX,OFFSET TRANGROUP:DEVWMES_ptr

PUBLIC COPERR
COPERR:
	INVOKE	std_Eprintf			;AC022;

COPERRP:
	inc	[DESTCLOSED]
	cmp	[CFLAG],0
	jz	ENDCOPYJ			; Never actually got it open
	MOV	bx,[DESTHAND]
	CMP	BX,0
	JLE	NoClose
	MOV	AH,CLOSE			; Close the file
	INT	int_command

NoClose:
	MOV	DX,OFFSET TRANGROUP:DESTBUF
	MOV	AH,UNLINK
	INT	int_command			; And delete it
	MOV	[CFLAG],0

ENDCOPYJ:
	JMP	ENDCOPY

XA_SET_ERROR_JMP:				;AN022; Go set up error message
	jmp	xa_set_error			;AN022;

SEEKEND:
	xor	dx,dx				; Zero high half of offset
	xchg	dx,cx				; cx:dx is seek location
	mov	ax,(LSEEK SHL 8) OR 1
	INT	int_command			; Seek ahead in the file
	cmp	[RDEOF],0
	retz
;
; If a ^Z has been read we must set the file size to the current
; file pointer location
;
	MOV	AH,WRITE
	INT	int_command			; CX is zero, truncates file
	jc	xa_set_error_Jmp		;AC022; Failure
	return

TRANCODE ENDS
	 END
