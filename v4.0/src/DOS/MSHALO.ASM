;	SCCSID = @(#)ibmhalo.asm	1.1 85/04/10
;   On 2K (800h) boundaries beginning at address C0000h and ending at EF800h
;   there is a header that describes a block of rom program.  This header
;   contains information needed to initialize a module and to provide PCDOS
;   with a set of reserved names for execution.
;
;   This header has the following format:
;
;   rom_header	STRUC
;	Signature1  DB	55h
;	Signature2  DB	AAh
;	rom_length  DB	?		; number of 512 byte pieces
;	init_jmp    DB	3 dup (?)
;	name_list   name_struc <>
;   rom_header	ENDS
;
;   name_struc	STRUC
;	name_len    DB	?
;	name_text   DB	? DUP (?)
;	name_jmp    DB	3 DUP (?)
;   name_struc	ENDS
;
;   The name list is a list of names that are reserved by a particular section
;   of a module.  This list of names is terminated by a null name (length
;   is zero).
;
;   Consider now, the PCDOS action when a user enters a command:
;
;	COMMAND.COM has control.
;	o   If location FFFFEh has FDh then
;	o	Start scanning at C0000h, every 800h for a byte 55h followed
;		    by AAh, stop scan if we get above or = F0000H
;	o	When we've found one, compare the name entered by the user
;		    with the one found in the rom.  If we have a match, then
;		    set up the environment for execution and do a long jump
;		    to the near jump after the found name.
;	o	If no more names in the list, then continue scanning the module
;		    for more 55h followed by AAh.
;	o   We get to this point only if there is no matching name in the
;		rom.  We now look on disk for the command.
;
;   This gives us the flexibility to execute any rom cartridge without having
;   to 'hard-code' the name of the cartridge into PCDOS.  Rom modules that
;   want to be invisible to the DOS should not have any names in their lists
;   (i.e. they have a single null name).
;
;   Consider a new release of BASIC, say, that patches bugs in the ROM version.
;   Clearly this version will be available on disk.  How does a user actually
;   invoke this new BASIC??  He cannot call it BASIC on the disk because the
;   EXEC loader will execute the ROM before it even looks at the disk!	Only
;   solution:
;
;   o	Keep things consistent and force the user to have his software named
;	differently from the ROM names (BASIC1, BASIC2, etc).

rom_header  STRUC
    Signature1	DB  ?
    Signature2	DB  ?
    rom_length	DB  ?
    init_jmp	DB  3 dup (?)
    name_list	DB  ?
rom_header  ENDS

name_struc  STRUC
    name_len	DB  ?
    name_text	DB  1 DUP (?)
    name_jmp	DB  3 DUP (?)
name_struc  ENDS

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;
; Check for IBM HALO rom cartrides. DS:DX is a pointer to name
;
ROM_SCAN:
	PUSH	ES
	PUSH	SI
	PUSH	DI
	PUSH	CX
	PUSH	AX
	PUSH	BX
;
; check for halo signature in rom
;
	MOV	AX,0F000h
	MOV	ES,AX
	CMP	BYTE PTR ES:[0FFFEh],0FDh
	JZ	SCAN_IT
NO_ROM:
	CLC
ROM_RET:
	POP	BX
	POP	AX
	POP	CX
	POP	DI
	POP	SI
	POP	ES
	RET
SCAN_IT:
;
; start scanning at C000
;
	MOV	AX,0C000h
SCAN_ONE:
	MOV	ES,AX
	XOR	DI,DI
SCAN_MODULE:
;
; check for a valid header
;
	CMP	WORD PTR ES:[DI],0AA55h
	JZ	SCAN_LIST
	ADD	AX,080h
SCAN_END:
	CMP	AX,0F000h
	JB	SCAN_ONE
	JMP	NO_ROM
;
; trundle down list of names
;
SCAN_LIST:
	MOV	BL,ES:[DI].rom_length	; number of 512-byte jobbers
	XOR	BH,BH			; nothing in the high byte
	SHL	BX,1
	SHL	BX,1			; number of paragraphs
	ADD	BX,7Fh
	AND	BX,0FF80h		; round to 2k

	MOV	DI,name_list
SCAN_NAME:
	MOV	CL,ES:[DI]		; length of name
	INC	DI			; point to name
	XOR	CH,CH
	OR	CX,CX			; zero length name
	JNZ	SCAN_TEST		; nope... compare
	ADD	AX,BX			; yep, skip to next block
	JMP	SCAN_END
;
; compare a single name
;
SCAN_TEST:
	MOV	SI,DX
	INC	SI
	REPE	CMPSB			; compare name
	JZ	SCAN_FOUND		; success!
SCAN_NEXT:
	ADD	DI,CX			; failure, next name piece
	ADD	DI,3
	JMP	SCAN_NAME
;
; found a name. save entry location
;
SCAN_FOUND:
	CMP	BYTE PTR DS:[SI],'?'
	JZ	SCAN_SAVE
	CMP	BYTE PTR DS:[SI],' '
	JNZ	SCAN_NEXT
SCAN_SAVE:
	MOV	[rom_cs],ES
	MOV	[ROM_ip],DI
	STC
	JMP	ROM_RET

;
; execute a rom-placed body of code. allocate largest block
;
ROM_EXEC:
	MOV	BX,0FFFFh
	MOV	AH,ALLOC
	INT	int_command
	MOV	AH,ALLOC
	INT	int_command
	PUSH	BX
	PUSH	AX
;
; set terminate addresses
;
	MOV	AX,(set_interrupt_vector SHL 8) + int_terminate
	PUSH	DS
	MOV	DS,[RESSEG]
	ASSUME	DS:RESGROUP
	MOV	DX,OFFSET RESGROUP:EXEC_WAIT
	INT	int_command
	MOV	DX,DS
	MOV	ES,DX
	ASSUME	ES:RESGROUP
	POP	DS
	ASSUME	DS:NOTHING
;
; and create program header and dup all jfn's
;
	POP	DX
	MOV	AH,DUP_PDB
	INT	int_command
;
; set up dma address
;
	MOV	DS,DX
	MOV	DX,080h
	MOV	AH,SET_DMA
	INT	int_command
;
; copy in environment info
;
	MOV	AX,[ENVIRSEG]
	MOV	DS:[PDB_environ],AX
;
; set up correct size of block
;
	POP	BX			; BX has size, DS has segment
	MOV	DX,DS
	ADD	DX,BX
	MOV	DS:[PDB_block_len],DX
;
; change ownership of block
;
	MOV	DX,DS
	DEC	DX
	MOV	DS,DX
	INC	DX
	MOV	DS:[arena_owner],DX
	MOV	DS,DX
;
; set up correct stack
;
	CMP	BX,1000h
	JB	GOT_STACK
	XOR	BX,BX
GOT_STACK:
	MOV	CL,4
	SHL	BX,CL
	MOV	DX,DS
	MOV	SS,DX
	MOV	SP,BX
	XOR	AX,AX
	PUSH	AX
;
; set up initial registers and go to the guy
;
	NOT	AX
	PUSH	[ROM_CS]
	PUSH	[ROM_IP]
	MOV	ES,DX
ASSUME ES:NOTHING
FOOBAR	PROC	FAR
	RET
FOOBAR	ENDP
