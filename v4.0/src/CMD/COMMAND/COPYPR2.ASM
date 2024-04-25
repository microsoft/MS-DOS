 page 80,132
;	SCCSID = @(#)copypr2.asm	1.1 85/05/14
;	SCCSID = @(#)copypr2.asm	1.1 85/05/14
	INCLUDE comsw.asm

.xlist
.xcref
	INCLUDE DOSSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm
.list
.cref


TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	FulDir_ptr:word 	;AN052;
TRANDATA ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	ASCII:BYTE
	EXTRN	BINARY:BYTE
	EXTRN	CONCAT:BYTE
	EXTRN	DESTBUF:BYTE
	EXTRN	DESTFCB:BYTE
	EXTRN	DESTINFO:BYTE
	EXTRN	DESTISDIR:BYTE
	EXTRN	DESTTAIL:WORD
	EXTRN	DESTVARS:BYTE
	EXTRN	DIRBUF:BYTE
	EXTRN	DIRCHAR:BYTE
	EXTRN	FIRSTDEST:BYTE
	EXTRN	INEXACT:BYTE
	EXTRN	MELCOPY:BYTE
	EXTRN	NXTADD:WORD
	EXTRN	PLUS:BYTE
	EXTRN	SDIRBUF:BYTE
	EXTRN	SRCINFO:BYTE
	EXTRN	srcxname:byte
	EXTRN	TPA:WORD
	EXTRN	trgxname:byte
	EXTRN	USERDIR1:BYTE
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

	EXTRN	BADPATH_ERR:NEAR	;AN022;
	EXTRN	COPERR:NEAR		;AN052;
	EXTRN	EXTEND_SETUP:NEAR	;AN022;

	PUBLIC	BUILDPATH
	PUBLIC	SETSTARS
	PUBLIC	SETASC

ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING

SETASC:
;
; Given switch vector in AX,
;	Set ASCII switch if A is set
;	Clear ASCII switch if B is set
;	BINARY set if B specified
;	Leave ASCII unchanged if neither or both are set
; Also sets INEXACT if ASCII is ever set. AL = ASCII on exit, flags set
;
	AND	AL,SwitchA+SwitchB
	JPE	LOADSW				; PE means both or neither are set
	PUSH	AX
	AND	AL,SwitchB
	MOV	[BINARY],AL
	POP	AX
	AND	AL,SwitchA
	MOV	[ASCII],AL
	OR	[INEXACT],AL

LOADSW:
	MOV	AL,[ASCII]
	OR	AL,AL
	return

public builddest
BUILDDEST:
	cmp	[DESTISDIR],-1
	jnz	KNOWABOUTDEST			; Already done the figuring
	MOV	DI,OFFSET TRANGROUP:USERDIR1
	mov	bp,offset trangroup:DESTVARS
	call	BUILDPATH
	invoke	RESTUDIR1

; Now know all about the destination

KNOWABOUTDEST:
	xor	al,al
	xchg	al,[FIRSTDEST]
	or	al,al
	jnz	FIRSTDST
	jmp	NOTFIRSTDEST

FIRSTDST:
	mov	si,[DESTTAIL]			; Create an FCB of the original DEST
	mov	di,offset trangroup:DESTFCB
	mov	ax,PARSE_FILE_DESCRIPTOR SHL 8
	INT	int_command
	CMP	BYTE PTR [SI],0
	JZ	GoodParse
;AD052; MOV	BYTE PTR [DI+1],"|"             ; must be illegal file name character
	mov	dx,offset trangroup:fuldir_ptr	;AN052; Issue "File creation error"
	jmp	coperr				;AN052;

GoodParse:
	mov	ax,word ptr [DESTBUF]		; Get drive
	cmp	ah,':'
	jz	DRVSPEC4
	mov	al,'@'

DRVSPEC4:
	MOV	CL,[ASCII]			; Save current ASCII setting
	or	al,20h
	sub	al,60h
	mov	[DESTFCB],al
	mov	al,[DESTINFO]
	mov	ah,[SRCINFO]
	and	ax,0202H
	or	al,al
	jz	NOTMELCOPY
	cmp	al,ah
	jnz	NOTMELCOPY
	cmp	[PLUS],0
	jz	NOTMELCOPY
	inc	[MELCOPY]			; ambig source, ambig dest, and pluses
	xor	al,al
	jmp	short SETCONC

NOTMELCOPY:
	xor	al,2				; al=2 if unambig dest, =0 if ambig dest
	and	al,ah
	shr	al,1				; al=1 if unambig dest AND ambig sorce
						;   Implies concatenation
SETCONC:
	or	al,[PLUS]			; al=1 if concat
	mov	[CONCAT],al
	shl	al,1
	shl	al,1
	mov	[INEXACT],al			; Concat -> inexact copy
	cmp	[BINARY],0
	jnz	NOTFIRSTDEST			; Binary explicitly given, all OK
	mov	[ASCII],al			; Concat -> ASCII
	or	cl,cl
	jnz	NOTFIRSTDEST			; ASCII flag set before, DATA read correctly
	or	al,al
	JZ	NOTFIRSTDEST			; ASCII flag did not change states
;
; At this point there may already be binary read data in the read buffer.
; We need to find the first ^Z (if there is one) and trim the amount
; of data in the buffer correctly.
;
	MOV	CX,[NXTADD]
	JCXZ	NOTFIRSTDEST			; No data, everything OK
	MOV	AL,1AH
	PUSH	ES
	XOR	DI,DI
	MOV	ES,[TPA]
	REPNE	SCASB				; Scan for EOF
	POP	ES
	JNZ	NOTFIRSTDEST			; No ^Z in buffer, everything OK
	DEC	DI				; Point at ^Z
	MOV	[NXTADD],DI			; New buffer

NOTFIRSTDEST:
	mov	bx,offset trangroup:DIRBUF+1	; Source of replacement chars
	cmp	[CONCAT],0
	jz	GOTCHRSRC			; Not a concat
	mov	bx,offset trangroup:SDIRBUF+1	; Source of replacement chars

GOTCHRSRC:
	mov	si,offset trangroup:DESTFCB+1	; Original dest name
	mov	di,[DESTTAIL]			; Where to put result

public buildname
BUILDNAME:
	mov	cx,8

BUILDMAIN:
	lodsb
	cmp	al,'?'
	jnz	NOTAMBIG
	mov	al,byte ptr [BX]

NOTAMBIG:
	cmp	al,' '
	jz	NOSTORE
	stosb

NOSTORE:
	inc	bx
	loop	BUILDMAIN
	mov	cl,3
	mov	al,' '
	cmp	byte ptr [SI],al
	jz	ENDDEST 			; No extension
	mov	al,dot_chr
	stosb

BUILDEXT:
	lodsb
	cmp	al,'?'
	jnz	NOTAMBIGE
	mov	al,byte ptr [BX]

NOTAMBIGE:
	cmp	al,' '
	jz	NOSTOREE
	stosb

NOSTOREE:
	inc	bx
	loop	BUILDEXT
ENDDEST:
	xor	al,al
	stosb					; NUL terminate
	return

BUILDPATH:
	test	[BP.INFO],2
	jnz	NOTPFILE			; If ambig don't bother with open
	mov	dx,bp
	add	dx,BUF				; Set DX to spec

	push	di				;AN000;
	MOV	AX,EXTOPEN SHL 8		;AC000; open the file
	mov	bx,read_open_mode		;AN000; get open mode for COPY
	xor	cx,cx				;AN000; no special files
	mov	si,dx				;AN030; get file name offset
	mov	di,-1				;AN030; no parm list
	mov	dx,read_open_flag		;AN000; set up open flags
	INT	int_command
	pop	di				;AN000;
	jnc	pure_file			;AN022; is pure file
	invoke	get_ext_error_number		;AN022; get the extended error
	cmp	ax,error_file_not_found 	;AN022; if file not found - okay
	jz	notpfile			;AN022;
	cmp	ax,error_path_not_found 	;AN022; if path not found - okay
	jz	notpfile			;AN022;
	cmp	ax,error_access_denied		;AN022; if access denied - okay
	jz	notpfile			;AN022;
	jmp	extend_setup			;AN022; exit with error

pure_file:
	mov	bx,ax				; Is pure file
	mov	ax,IOCTL SHL 8
	INT	int_command
	mov	ah,CLOSE
	INT	int_command
	test	dl,devid_ISDEV
	jnz	ISADEV				; If device, done
	test	[BP.INFO],4
	jz	ISSIMPFILE			; If no path seps, done

NOTPFILE:
	mov	dx,word ptr [BP.BUF]
	cmp	dl,0				;AN034; If no drive specified, get
	jz	set_drive_spec			;AN034;    default drive dir
	cmp	dh,':'
	jz	DRVSPEC5

set_drive_spec: 				;AN034;
	mov	dl,'@'

DRVSPEC5:
	or	dl,20h
	sub	dl,60h				; A = 1
	invoke	SAVUDIR1
	jnc	curdir_ok			;AN022; if error - exit
	invoke	get_ext_error_number		;AN022; get the extended error
	jmp	extend_setup			;AN022; exit with error

curdir_ok:					;AN022;
	mov	dx,bp
	add	dx,BUF				; Set DX for upcomming CHDIRs
	mov	bh,[BP.INFO]
	and	bh,6
	cmp	bh,6				; Ambig and path ?
	jnz	CHECKAMB			; jmp if no
	mov	si,[BP.TTAIL]
	mov	bl,':'
	cmp	byte ptr [si-2],bl
	jnz	KNOWNOTSPEC
	mov	[BP.ISDIR],2			; Know is d:/file
	jmp	short DOPCDJ

KNOWNOTSPEC:
	mov	[BP.ISDIR],1			; Know is path/file
	dec	si				; Point to the /

DOPCDJ:
	jmp	DOPCD				;AC022; need long jump

CHECKAMB:
	cmp	bh,2
	jnz	CHECKCD

ISSIMPFILE:
ISADEV:
	mov	[BP.ISDIR],0			; Know is file since ambig but no path
	return

CHECKCD:
	invoke	SETREST1
	mov	ah,CHDIR
	INT	int_command
	jc	NOTPDIR
	mov	di,dx
	xor	ax,ax
	mov	cx,ax
	dec	cx

Kloop:						;AN000;  3/3/KK
	MOV	AL,ES:[DI]			;AN000;  3/3/KK
	INC	DI				;AN000;  3/3/KK
	OR	AL,AL				;AN000;  3/3/KK
	JZ	Done				;AN000;  3/3/KK
	xor	ah,ah				;AN000;  3/3/KK
	invoke	Testkanj			;AN000;  3/3/KK
	JZ	Kloop				;AN000;  3/3/KK
	INC	DI				;AN000;  3/3/KK
	INC	AH				;AN000;  3/3/KK
	jmp	Kloop				;AN000;  3/3/KK

Done:						;AN000;  3/3/KK
	dec	di
	mov	al,[DIRCHAR]
	mov	[bp.ISDIR],2			; assume d:/file
	OR	AH, AH				;AN000; 3/3/KK
	JNZ	Store_pchar			;AN000; 3/3/KK	 this is the trailing byte of ECS code
	cmp	al,[di-1]
	jz	GOTSRCSLSH

Store_pchar:					;AN000; 3/3/KK
	stosb
	mov	[bp.ISDIR],1			; know path/file

GOTSRCSLSH:
	or	[bp.INFO],6
	call	SETSTARS
	return


NOTPDIR:
	invoke	get_ext_error_number		;AN022; get the extended error
	cmp	ax,error_path_not_found 	;AN022; if path not found - okay
	jz	notpdir_try			;AN022;
	cmp	ax,error_access_denied		;AN022; if access denied - okay
	jnz	extend_setupj			;AN022; otherwise - exit error

notpdir_try:					;AN022;
	mov	[bp.ISDIR],0			; assume pure file
	mov	bh,[bp.INFO]
	test	bh,4
	retz					; Know pure file, no path seps
	mov	[bp.ISDIR],2			; assume d:/file
	mov	si,[bp.TTAIL]
	cmp	byte ptr [si],0
	jz	BADCDERRJ2			; Trailing '/'
	mov	bl,dot_chr
	cmp	byte ptr [si],bl
	jz	BADCDERRJ2			; If . or .. pure cd should have worked
	mov	bl,':'
	cmp	byte ptr [si-2],bl
	jz	DOPCD				; Know d:/file
	mov	[bp.ISDIR],1			; Know path/file
	dec	si				; Point at last '/'

DOPCD:
	xor	bl,bl
	xchg	bl,[SI] 			; Stick in a NUL
	invoke	SETREST1
	CMP	DX,SI				;AN000;  3/3/KK
	JAE	LookBack			;AN000;  3/3/KK
	PUSH	SI				;AN000;  3/3/KK
	PUSH	CX				;AN000;  3/3/KK
	MOV	CX,SI				;AN000;  3/3/KK
	MOV	SI,DX				;AN000;  3/3/KK

Kloop2: 					;AN000;  3/3/KK
	LODSB					;AN000;  3/3/KK
	invoke	TestKanj			;AN000;  3/3/KK
	jz	NotKanj4			;AN000;  3/3/KK
	LODSB					;AN000;  3/3/KK
	CMP	SI,CX				;AN000;  3/3/KK
	JB	Kloop2				;AN000;  3/3/KK
	POP	CX				;AN000;  3/3/KK
	POP	SI				;AN000;  3/3/KK
	JMP	SHORT DoCdr			;AN000;  3/3/KK  Last char is ECS code, don't check for
						;		 trailing path sep
NotKanj4:					;AN000;  3/3/KK
	CMP	SI,CX				;AN000;  3/3/KK
	JB	Kloop2				;AN000;  3/3/KK
	POP	CX				;AN000;  3/3/KK
	POP	SI				;AN000;  3/3/KK

LookBack:					;AN000;  3/3/KK
	CMP	BL,[SI-1]			; if double slash, then complain.
	JZ	BadCDErrJ2

DoCdr:						;AN000;  3/3/KK
	mov	ah,CHDIR
	INT	int_command
	xchg	bl,[SI]
	retnc
	invoke	get_ext_error_number		;AN022; get the extended error

EXTEND_SETUPJ:					;AN022;
	JMP	EXTEND_SETUP			;AN022; go issue the error message

BADCDERRJ2:
	jmp	badpath_err			;AC022; go issue path not found message

SETSTARS:
	mov	[bp.TTAIL],DI
	add	[bp.SIZ],12
	mov	ax,dot_qmark
	mov	cx,8
	rep	stosb
	xchg	al,ah
	stosb
	xchg	al,ah
	mov	cl,3
	rep	stosb
	xor	al,al
	stosb
	return

PUBLIC CompName
COMPNAME:

	mov	si,offset trangroup:DESTBUF	;g do name translate of target
	mov	di,offset trangroup:TRGXNAME	;g save for name comparison
	mov	ah,xnametrans			;g
	int	int_command			;g

	MOV	si,offset trangroup:SRCXNAME	;g get name translate of source
	MOV	di,offset trangroup:TRGXNAME	;g get name translate of target


	invoke	STRCOMP

	return

TRANCODE ENDS
	 END
