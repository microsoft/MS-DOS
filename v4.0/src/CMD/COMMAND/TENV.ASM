 page 80,132
;	SCCSID = @(#)tenv.asm	4.2 85/08/16
;	SCCSID = @(#)tenv.asm	4.2 85/08/16
TITLE	Part6 COMMAND Transient routines.

;	Environment utilities and misc. routines

	INCLUDE comsw.asm

.xlist
.xcref
	INCLUDE DOSSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm
	INCLUDE DOSCNTRY.INC		;AN000;
.list
.cref


DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	comdrv:byte
	EXTRN	comspec_end:word
	EXTRN	comspec_print:word
	EXTRN	cpdrv:byte
	EXTRN	dbcs_vector_addr:dword	;AN000;
	EXTRN	ENVIRSEG:WORD
	EXTRN	fucase_addr:word	;AC000;
	EXTRN	RESTDIR:BYTE
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg_buf_ptr:word
	EXTRN	comspec:byte
	EXTRN	comspec_flag:byte
	EXTRN	comspecstr:byte
	EXTRN	ENVERR_PTR:WORD
	EXTRN	PATH_TEXT:byte
	EXTRN	PROMPT_TEXT:byte
	EXTRN	SYNTMES_PTR:WORD
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	Arg_Buf:BYTE
	EXTRN	RESSEG:WORD
	EXTRN	USERDIR1:BYTE
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC byte

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	cerror:near

	PUBLIC	add_name_to_environment
	PUBLIC	add_prompt
	PUBLIC	delete_path
	PUBLIC	find_name_in_environment
	PUBLIC	find_path
	PUBLIC	find_prompt
	PUBLIC	move_name
	PUBLIC	restudir
	PUBLIC	restudir1
	PUBLIC	scan_double_null
	PUBLIC	scasb2
	PUBLIC	store_char
	PUBLIC	Testkanj		;AN000;  3/3/KK
	PUBLIC	upconv

BREAK	<Environment utilities>
ASSUME DS:TRANGROUP

	break	Prompt command
assume	ds:trangroup,es:trangroup

ADD_PROMPT:
	CALL	DELETE_PROMPT			; DELETE ANY EXISTING PROMPT
	CALL	SCAN_DOUBLE_NULL

ADD_PROMPT2:
	PUSH	SI
	CALL	GETARG
	POP	SI
	retz					; PRE SCAN FOR ARGUMENTS
	CALL	MOVE_NAME			; MOVE IN NAME
	CALL	GETARG
	PUSH	SI
	JMP	SHORT ADD_NAME


	break	The SET command
assume	ds:trangroup,es:trangroup

;
; Input: DS:SI points to a CR terminated string
; Output: carry flag is set if no room
;	  otherwise name is added to environment
;

DISP_ENVj:
	jmp	DISP_ENV

ADD_NAME_TO_ENVIRONMENT:
	CALL	GETARG
	JZ	DISP_ENVj
;
; check if line contains exactly one equals sign
;
	XOR	BX,BX				;= COUNT IS 0
	PUSH	SI				;SAVE POINTER TO BEGINNING OF LINE

EQLP:
	LODSB					;GET A CHAR
	CMP	AL,13				;IF CR WE'RE ALL DONE
	JZ	QUEQ
	CMP	AL,'='                          ;LOOK FOR = SIGN
	JNZ	EQLP				;NOT THERE, GET NEXT CHAR
	INC	BL				;OTHERWISE INCREMENT EQ COUNT
	CMP	BYTE PTR [SI],13		;LOOK FOR CR FOLLOWING = SIGN
	JNZ	EQLP
	INC	BH				;SET BH=1 MEANS NO PARAMETERS
	JMP	EQLP				;AND LOOK FOR MORE

QUEQ:
	POP	SI				;RESTORE BEGINNING OF LINE
	DEC	BL				;ZERO FLAG MEANS ONLY ONE EQ
	JZ	ONEQ				;GOOD LINE
	MOV	DX,OFFSET TRANGROUP:SYNTMES_ptr
	JMP	CERROR

ONEQ:
	PUSH	BX
	CALL	DELETE_NAME_IN_ENVIRONMENT
	POP	BX
	DEC	BH
	retz

	CALL	SCAN_DOUBLE_NULL
	mov	bx,di				; Save ptr to beginning of env var name
	CALL	MOVE_NAME
	push	si
	xchg	bx,di				; Switch ptrs to beginning and end of
						;  env var name
;
; We want to special-case COMSPEC.  This is to reduce the amount of code
; necessary in the resident for re-reading the transient.  Let's look for
; COMSPEC=
;
	mov	si,offset trangroup:comspecstr	; Load ptr to string "COMSPEC"
	mov	cx,4				; If the new env var is comspec, set
	repz	cmpsw				;  the comspec_flag
;
; Zero set => exact match
;
	jnz	not_comspec
	mov	comspec_flag,1

not_comspec:
	mov	di,bx				; Load ptr to end of env var name

ADD_NAME:					; Add the value of the new env var
	pop	si				;  to the environment.
	push	si

add_name1:
	LODSB
	CMP	AL,13
	jz	add_name_ret
	CALL	STORE_CHAR
	JMP	ADD_NAME1

add_name_ret:
	pop	si
	cmp	comspec_flag,0			; If the new env var is comspec,
	retz					;  copy the value into the
;
; We have changed the COMSPEC variable.  We need to update the resident
; pieces necessary to reread in the info.  First, skip all delimiters
;
	invoke	ScanOff
	mov	es,[resseg]			;  comspec var in the resident
	assume	es:resgroup
;
; Make sure that the printer knows where the beginning of the string is
;
	mov	di,offset resgroup:comspec
	mov	bx,di
;
; Generate drive letter for display
;
	xor	ax,ax				;g assume no drive first
	mov	comdrv,al			;g
	push	ax				;AN000;  3/3/KK
	mov	al,[si] 			;AN000;  3/3/KK
	call	testkanj			;AN000;  3/3/KK
	pop	ax				;AN000;  3/3/KK
	jnz	GotDrive
	cmp	byte ptr [si+1],':'             ; drive specified?
	jnz	GotDrive
	mov	al,[si] 			; get his specified drive
	call	UpConv				; convert to uppercase
	sub	al,'A'                          ; convert to 0-based
	add	di,2
	inc	al				; convert to 1-based number
	mov	comdrv,al
;
; Stick the drive letter in the prompt message.  Nothing special needs to be
; done here..
;

	add	al,'A'-1

GotDrive:					;g
	mov	comspec_print,di		;g point to beginning of name after drive
	mov	es:cpdrv,al
;
; Copy chars until delim
;

	mov	di,bx

copy_comspec:
	lodsb
	invoke	Delim
	jz	CopyDone
	cmp	al,13
	jz	CopyDone
	stosb
	jmp	short copy_comspec

CopyDone:
	xor	al,al				; Null terminate the string and quit
	stosb
	mov	comspec_flag,0
	dec	di
	mov	comspec_end,di

	ret

DISP_ENV:
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	DS,[ENVIRSEG]
ASSUME	DS:NOTHING
	XOR	SI,SI

PENVLP:
	CMP	BYTE PTR [SI],0
	retz
	mov	di,offset trangroup:arg_buf

PENVLP2:
	LODSB
	stosb
	OR	AL,AL
	JNZ	PENVLP2
	mov	dx,offset trangroup:arg_buf_ptr
	push	ds
	push	es
	pop	ds
	invoke	printf_crlf
	pop	ds
	JMP	PENVLP

ASSUME	DS:TRANGROUP

DELETE_PATH:
	MOV	SI,OFFSET TRANGROUP:PATH_TEXT
	JMP	SHORT DELETE_NAME_IN_environment

DELETE_PROMPT:
	MOV	SI,OFFSET TRANGROUP:PROMPT_TEXT

DELETE_NAME_IN_environment:
;
; Input: DS:SI points to a "=" terminated string
; Output: carry flag is set if name not found
;	  otherwise name is deleted
;
	PUSH	SI
	PUSH	DS
	CALL	FIND				; ES:DI POINTS TO NAME
	JC	DEL1
	MOV	SI,DI				; SAVE IT
	CALL	SCASB2				; SCAN FOR THE NUL
	XCHG	SI,DI
	CALL	GETENVSIZ
	SUB	CX,SI
	PUSH	ES
	POP	DS				; ES:DI POINTS TO NAME, DS:SI POINTS TO NEXT NAME
	REP	MOVSB				; DELETE THE NAME

DEL1:
	POP	DS
	POP	SI
	return

FIND_PATH:
	MOV	SI,OFFSET TRANGROUP:PATH_TEXT
	JMP	SHORT FIND_NAME_IN_environment

FIND_PROMPT:
	MOV	SI,OFFSET TRANGROUP:PROMPT_TEXT

FIND_NAME_IN_environment:
;
; Input: DS:SI points to a "=" terminated string
; Output: ES:DI points to the arguments in the environment
;	  zero is set if name not found
;	  carry flag is set if name not valid format
;
	CALL	FIND				; FIND THE NAME
	retc					; CARRY MEANS NOT FOUND
	JMP	SCASB1				; SCAN FOR = SIGN
;
; On return of FIND1, ES:DI points to beginning of name
;
FIND:
	CLD
	CALL	COUNT0				; CX = LENGTH OF NAME
	MOV	ES,[RESSEG]
ASSUME	ES:RESGROUP
	MOV	ES,[ENVIRSEG]
ASSUME	ES:NOTHING
	XOR	DI,DI

FIND1:
	PUSH	CX
	PUSH	SI
	PUSH	DI

FIND11:
	LODSB
	CALL	TESTKANJ
	JZ	NOTKANJ3
	DEC	SI
	LODSW
	INC	DI
	INC	DI
	CMP	AX,ES:[DI-2]
	JNZ	FIND12
	DEC	CX
	LOOP	FIND11
	JMP	SHORT FIND12

NOTKANJ3:
	CALL	UPCONV
	INC	DI
	CMP	AL,ES:[DI-1]
	JNZ	FIND12
	LOOP	FIND11

FIND12:
	POP	DI
	POP	SI
	POP	CX
	retz
	PUSH	CX
	CALL	SCASB2				; SCAN FOR A NUL
	POP	CX
	CMP	BYTE PTR ES:[DI],0
	JNZ	FIND1
	STC					; INDICATE NOT FOUND
	return

COUNT0:
	PUSH	DS
	POP	ES
	MOV	DI,SI

COUNT1:
	PUSH	DI				; COUNT NUMBER OF CHARS UNTIL "="
	CALL	SCASB1
	JMP	SHORT COUNTX

COUNT2:
	PUSH	DI				; COUNT NUMBER OF CHARS UNTIL NUL
	CALL	SCASB2

COUNTX:
	POP	CX
	SUB	DI,CX
	XCHG	DI,CX
	return

MOVE_NAME:
	CMP	BYTE PTR DS:[SI],13
	retz
	LODSB

;;;;	IF	KANJI			3/3/KK
	CALL	TESTKANJ
	JZ	NOTKANJ1
	CALL	STORE_CHAR
	LODSB
	CALL	STORE_CHAR
	JMP	SHORT MOVE_NAME

NOTKANJ1:
;;;;	ENDIF				3/3/KK

	CALL	UPCONV
	CALL	STORE_CHAR
	CMP	AL,'='
	JNZ	MOVE_NAME
	return

GETARG:
	MOV	SI,80H
	LODSB
	OR	AL,AL
	retz
	invoke	SCANOFF
	CMP	AL,13
	return

;
; Point ES:DI to the final NULL string.  Note that in an empty environment,
; there is NO double NULL, merely a string that is empty.
;
SCAN_DOUBLE_NULL:
	MOV	ES,[RESSEG]
ASSUME	ES:RESGROUP
	MOV	ES,[ENVIRSEG]
ASSUME	ES:NOTHING
	XOR	DI,DI
;
; Top cycle-point.  If the string here is empty, then we are done
;
SDN1:
	cmp	byte ptr es:[di],0		; nul string?
	retz					; yep, all done
	CALL	SCASB2
	JMP	SDN1

SCASB1:
	MOV	AL,'='                          ; SCAN FOR AN =
	JMP	SHORT SCASBX
SCASB2:
	XOR	AL,AL				; SCAN FOR A NUL
SCASBX:
	MOV	CX,100H
	REPNZ	SCASB
	return

TESTKANJ:
	push	ds				;AN000;  3/3/KK
	push	si				;AN000;  3/3/KK
	push	ax				;AN000;  3/3/KK
	mov	ds,cs:[resseg]			;AN000;  Get resident segment
	assume	ds:resgroup			;AN000;
	lds	si,dbcs_vector_addr		;AN000;  get DBCS vector
ktlop:						;AN000;  3/3/KK
	cmp	word ptr ds:[si],0		;AN000;  end of Table	3/3/KK
	je	notlead 			;AN000;  3/3/KK
	pop	ax				;AN000;  3/3/KK
	push	ax				;AN000;  3/3/KK
	cmp	al, byte ptr ds:[si]		;AN000;  3/3/KK
	jb	notlead 			;AN000;  3/3/KK
	inc	si				;AN000;  3/3/KK
	cmp	al, byte ptr ds:[si]		;AN000;  3/3/KK
	jbe	islead				;AN000;  3/3/KK
	inc	si				;AN000;  3/3/KK
	jmp	short ktlop			;AN000;  try another range ; 3/3/KK
Notlead:					;AN000;  3/3/KK
	xor	ax,ax				;AN000;  set zero 3/3/KK
	jmp	short ktret			;AN000;  3/3/KK
Islead: 					;AN000;  3/3/KK
	xor	ax,ax				;AN000;  reset zero  3/3/KK
	inc	ax				;AN000;  3/3/KK
ktret:						;AN000;  3/3/KK
	pop	ax				;AN000;  3/3/KK
	pop	si				;AN000;  3/3/KK
	pop	ds				;AN000;  3/3/KK
	return					;AN000;  3/3/KK
;-------------------------------------		;3/3/KK


; ****************************************************************
; *
; * ROUTINE:	 UPCONV     (ADDED BY EMG 4.00)
; *
; * FUNCTION:	 This routine returns the upper case equivalent of
; *		 the character in AL from the file upper case table
; *		 in DOS if character if above  ascii 128, else
; *		 subtracts 20H if between "a" and "z".
; *
; * INPUT:	 AL	      char to be upper cased
; *		 FUCASE_ADDR  set to the file upper case table
; *
; * OUTPUT:	 AL	      upper cased character
; *
; ****************************************************************

assume	ds:trangroup				;AN000;

upconv	proc	near				;AN000;

	cmp	al,80h				;AN000;  see if char is > ascii 128
	jb	oth_fucase			;AN000;  no - upper case math
	sub	al,80h				;AN000;  only upper 128 chars in table
	push	ds				;AN000;
	push	bx				;AN000;
	mov	ds,[resseg]			;AN000;  get resident data segment
assume	ds:resgroup				;AN000;
	lds	bx,dword ptr fucase_addr+1	;AN000;  get table address
	add	bx,2				;AN000;  skip over first word
	xlat	ds:byte ptr [bx]		;AN000;  convert to upper case
	pop	bx				;AN000;
	pop	ds				;AN000;
assume	ds:trangroup				;AN000;
	jmp	short upconv_end		;AN000;  we finished - exit

oth_fucase:					;AN000;
	cmp	al,small_a			;AC000; if between "a" and "z",
	jb	upconv_end			;AC000;     subtract 20h to get
	cmp	al,small_z			;AC000;    upper case equivalent.
	ja	upconv_end			;AC000;
	sub	al,20h				;AC000; Change lower-case to upper

upconv_end:					;AN000;
	ret

upconv	endp					;AN000;


;
; STORE A CHAR IN environment, GROWING IT IF NECESSARY
;
STORE_CHAR:
	PUSH	CX
	PUSH	BX
	PUSH	ES				;AN056;
	PUSH	DS				;AN056; Save local DS
	MOV	DS,[RESSEG]			;AN056; Get resident segment
	ASSUME	DS:RESGROUP			;AN056;
	MOV	ES,[ENVIRSEG]			;AN056; Get environment segment
	ASSUME	ES:NOTHING			;AN056;
	POP	DS				;AN056; Get local segment back
	ASSUME	DS:TRANGROUP			;AN056;
	CALL	GETENVSIZ
	MOV	BX,CX
	SUB	BX,2				; SAVE ROOM FOR DOUBLE NULL
	CMP	DI,BX
	JB	STORE1

	PUSH	AX
	PUSH	CX
	PUSH	BX				; Save Size of environment
	invoke	FREE_TPA
	POP	BX
	ADD	BX,2				; Recover true environment size

	CMP	BX, 8000H			; Don't let environment grow > 32K
	JB	ENVSIZ_OK
BAD_ENV_SIZE:					;AN056;
	STC
	JMP	ENVNOSET
ENVSIZ_OK:

	MOV	CL,4
	SHR	BX,CL				; Convert back to paragraphs
	INC	BX				; Try to grow environment by one para
	MOV	CX,ES				;AN056; Get environment segment
	ADD	CX,BX				;AN056; Add in size of environment
	ADD	CX,020H 			;AN056; Add in some TPA
	MOV	AX,CS				;AN056; Get the transient segment
	CMP	CX,AX				;AN056; Are we hitting the transient?
	JNB	BAD_ENV_SIZE			;AN056; Yes - don't do it!!!
	MOV	AH,SETBLOCK
	INT	int_command
ENVNOSET:
	PUSHF
	PUSH	ES
	MOV	ES,[RESSEG]
	invoke	ALLOC_TPA
	POP	ES
	POPF
	POP	CX
	POP	AX
	JNC	STORE1
	POP	ES				;AN056;
	MOV	DX,OFFSET TRANGROUP:ENVERR_ptr
	JMP	CERROR
STORE1:
	STOSB
	MOV	WORD PTR ES:[DI],0		; NULL IS AT END
	POP	ES				;AN056;
	POP	BX
	POP	CX
	return

GETENVSIZ:
;Get size of environment in bytes, rounded up to paragraph boundry
;ES has environment segment
;Size returned in CX, all other registers preserved

	PUSH	ES
	PUSH	AX
	MOV	AX,ES
	DEC	AX				;Point at arena
	MOV	ES,AX
	MOV	AX,ES:[arena_size]
	MOV	CL,4
	SHL	AX,CL				;Convert to bytes
	MOV	CX,AX
	POP	AX
	POP	ES
	return


ASSUME	DS:TRANGROUP


RESTUDIR1:
	PUSH	DS
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	CMP	[RESTDIR],0
	POP	DS
ASSUME	DS:TRANGROUP
	retz

RESTUDIR:
	MOV	DX,OFFSET TRANGROUP:USERDIR1
	MOV	AH,CHDIR
	INT	int_command			; Restore users DIR
	XOR	AL,AL
	invoke	SETREST
RET56:
	return

trancode    ends
	    end
