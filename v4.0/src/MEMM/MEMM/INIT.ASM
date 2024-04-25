

	page 58,132
;******************************************************************************
	TITLE	INIT - initialization code for MEMM
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:	INIT - initialization code for MEMM
;
;   Version:	0.05
;
;   Date:	May 24,1986
;
;   Author:
;
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;	05/24/86 Original
;	06/18/86 0.01		Added AUTO as a valid config line parameter.
;	06/25/86 0.02		Added call to debug init.
;	06/27/86 0.02		Check for Mx length = 2 and only 2
;	06/28/86 0.02		Change name from MEMM386 to MEMM
;	06/29/86 0.02		Size > 8192 were used instead of converted
;				to 256
;	07/03/86 0.04		Added TEXT_Seg
;	07/06/86 0.04		changed assume to DGROUP
;	07/06/86 0.04		moved init messages to LAST
;	07/10/86 0.05		added int15 patch and int67 patch here
;	07/20/88		removed debugger codes (pc)
;	07/29/88		removed ON/OFF/AUTO support
;
;******************************************************************************
;   Functional Description:
;	This module allocates the pool of extended memory to be used for
;   expanded memory, then call routines to initialize the data structures
;   for EMM and VDM.
;
;******************************************************************************
.lfcond
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	Init_MEMM386

	public	pool_size
	public	msg_flag
	public	Active_Status
	public	Auto_Mode
	public	dos_version
	public	TEXT_Seg
	public	STACK_Seg
	public	GDT_Seg
	public	IDT_Seg
	public	TSS_Seg
	public	driver_end
	public	powr10


	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
	include vdmseg.inc
	include vdmsel.inc	; for Deb386 Init
	include desc.inc	; "   "      "
	include emm386.inc
	include driver.equ
	include driver.str
	include ascii_sm.equ
;
;  maximum value for SIZE parameter
;
MAX_SIZE	equ	32 * 1024	; 32K => 32Meg

;
MS_DOS		equ	21h
PRINT_STRING	equ	09h
GET_VERSION	equ	30h
;
FALSE	equ	0
TRUE	equ	not FALSE
DOS3X_ADJ	equ	1		; DOS 3.x base memory adjustment

;
;   macro for printing messages located in LAST segment
;	ENTRY: DX = offset LAST:message
;
PRINT_MSG	macro
	push	ds
	push	seg LAST
	pop	ds		; ds = LAST
	mov	ah,PRINT_STRING
	int	MS_DOS		; output init message
	pop	ds
	ENDM


;******************************************************************************
;			E X T E R N A L    R E F E R E N C E S
;******************************************************************************
;
;
_DATA	segment

	extrn	PF_Base:word
;	 extrn	 himem_use:byte      ;* this is defined in oemproc.asm since it
				    ;  deals with memory so oem dependent
	extrn	ext_size:word	    ; size of extended memory allocated
	extrn	sys_size:word	    ; size of system memory allocated

_DATA	ends

ABS0	segment use16 at 0
	org 4*15h		; int 15h vector
i15_vector	dw	0
		dw	0

	org 4*67h		; int 67h vector
i67_vector	dw	0
		dw	0
ABS0	ends

;
R_CODE	segment
extrn	i15_Entry:near		; int15h patch code
extrn	EMM_rEntry:near 	; int67h patch code
extrn	i15_Old:word		; old int15 vector
R_CODE	ends

;
_TEXT	segment

	extrn	Inst_chk_f:far		; check for MEMM already installed
	extrn	FarGoVirtual:far	; go to virtual mode
	extrn	get_token:near		; get token from command line

_TEXT	ends
;
LAST	segment

	extrn	VerifyMachine:near
	extrn	InitMess:byte
	extrn	InstallMess:byte
	extrn	ISizeMess:byte
	extrn	ExtSizeMess:byte
	extrn	SysSizeMess:byte
	extrn	PFBAMess:byte
	extrn	ActiveMess:byte
	extrn	InactiveMess:byte
	extrn	AutoMess:byte
	extrn	InvParm:byte
	extrn	InvPFBA:byte
	extrn	InvMRA:byte
	extrn	Adj_Size:byte
	extrn	InsfMem:byte
	extrn	Incorrect_DOS:byte
	extrn	Incorrect_PRT:byte
	extrn	Already_Inst:byte
	extrn	No_PF_Avail:byte
	extrn	PFWarning:byte

	extrn	Is386:far		; check for 386
	extrn	EMM_Init:near		; initialization for EMM data structs
	extrn	AllocMem:near		; allocate extended memory routine
	extrn	InitTab:near		; OEM init code for tables
	extrn	VDM_Init:near		; initialize VDM
	extrn	DeallocMem:near 	; deallocate hi/extended memory routine

	extrn	find_phys_pages:near	; find the mappable pages in 0-1M range
	extrn	exclude_segments:near	; exclude segments within a range
	extrn	estb_mach_state:near	; establish machine environment

LAST	ends

	page
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************

	page
;******************************************************************************
;	Data segment
;******************************************************************************
_DATA	segment
;
dos_version	db	0h	; MS-DOS version
pool_size	dw	0	; size of EMM Pages Pool in kbytes
msg_flag	dw	0	; Message flag byte

driver_end	dw	0	; end of driver -> driver brk address
		dw	seg LAST
powr10		dw	1,10,100,1000,10000
max_arg_len	equ	11		; maximum length of argument on cmd line
arg_str 	db	max_arg_len+1	dup(0)
;
;  Active_Status is used to signal the termination condition for the
;	driver.  After the driver installs, Active_Status holds the
;	current status (ON or OFF).
;  Auto_Mode is set when MEMM is running in AUTO mode.
;
Active_Status	db	0FFh	; 0 => OFF , non-zero => ON
Auto_Mode	db	0h	; non-zero => auto mode

;
;  The following pointers are segment addresses for various segments
;
TEXT_Seg	dw	seg _TEXT	; current segment for _TEXT
STACK_Seg	dw	seg STACK	; current segment for STACK
GDT_Seg 	dw	seg GDT 	; current segment for GDT
IDT_Seg 	dw	seg IDT 	; current segment for IDT
TSS_Seg 	dw	seg TSS 	; current segment for TSS

_DATA	ends


;******************************************************************************
;
;	Code Segments
;
;******************************************************************************
;
_TEXT	segment
	assume	cs:_TEXT


;*************************************************************************
;
;	get_token_far	call get_token which must be near since it is
;			also part of a .COM file
;
;*************************************************************************
get_token_far		proc	far
	call	get_token
	ret
get_token_far		endp
_TEXT	ends

LAST	segment
	assume	cs:LAST, ds:DGROUP, es:DGROUP

	page
;******************************************************************************
;	Init - Initialization routine for MEMM.
;
;	ENTRY: DS:BX pts to INIT request header.
;
;	EXIT:  AX = INIT status for request header
;		if NO errors :
;			MEMM initialized.
;			if [ON] parameter specified on command line
;			    exit in Virtual mode and MEMM active.
;			else ( [OFF] parameter specified )
;			    exit in Real mode and MEMM inactive.
;		if errors:
;			Real Mode
;	USED: none
;
;******************************************************************************
Init_MEMM386	proc	far
	push	bx		; BP+10
	push	dx		; BP+8
	push	bp		; BP+6
	push	di		; BP+4
	push	ds		; BP+2
	push	es		; BP+0
	mov	bp,sp
;
;  set up DS = DGROUP and ES:BX to request header
;
	push	ds
	pop	es			; ES:BX pts to req hdr
	mov	ax,seg DGROUP
	mov	ds,ax			; DS = DGROUP

;
;	initialize break address to not install
;
	mov	word ptr ES:[bx.BRK_OFF],0000	; set it
	mov	ax,seg R_CODE		; get brk addr segment
	inc	ax			; reserve dos link pointer
	mov	ES:[bx.BRK_SEG],ax	; break addr = cs - don't install
	mov	byte ptr es:[bx.NUM_UNITS],0	; 0 - don't install
;
;	verify that MEMM is not already installed
;
	call	Inst_chk_f
	or	ax,ax			; q: already installed?
	jz	chk_pt			; n: go check processor type
	or	[msg_flag],INS_ERR_MSG	; y: error
	jmp	IE_exit 		; quit
;
;  verify processor type
;
chk_pt:
	call	Is386			;Q: is this a 386 ?
	jnz	inc_prc 		;  N: no, set error
					;  Y: check machine type
;
;  verify machine type
;
chk_mt:
	stc				; Indicate this is verify from INIT
	call	VerifyMachine		;Q: is this a good machine to run on?
	jnc	chk_dos 		; y: ok so far. go check dos version
inc_prc:
	or	[msg_flag],INC_PRC_MSG	; n: incorrect processor type
	jmp	IE_exit 		; quit
;
;  get DOS version - accept >= 3.1
;
chk_dos:
	push	bx
	mov	ah,GET_VERSION
	int	MS_DOS			; get dos version #
	mov	[dos_version],al	; save it.
	pop	bx
	cmp	ax,4			;Q: DOS 4.00
	je	IE_parse		;  Y: OK - continue install
	cmp	al,3			;Q: DOS 3.xx ?
	jl	IE_dos_err		;  N: return error
	cmp	ah,10			;Q: current DOS >= 3.10 ?
	jae	IE_parse		;  Y: OK - continue install
IE_dos_err:
	or	[msg_flag],INC_DOS_MSG	;  N: set error and exit
	jmp	IE_exit
;
;  parse command line for
;	(1) requested size for expanded memory
;	(2) page frame base address
;	(3) I/O addresses for board emulations
;	(4) Driver exit mode (virtual or real)
;
IE_parse:
	les	di,ES:[bx.ARG_PTR]	; ES:DI pts to config.sys command
					;	line parameters
	call	parser			; parse the parameters
	test	[msg_flag],KILLER_MSG	;Q: any killer messages?
	jz	IE_mach_state		;  N: go to establish machine state
	jmp	IE_exit 		;  Y: exit with error

IE_mach_state:
;
	push	ds
	pop	es			; ES:DGROUP
;
	call	estb_mach_state 	; since we are an environment, we need
					; to find the state we exist in right
					; now and maintain it.
	test	[msg_flag],KILLER_MSG	;Q: any killer messages?
	jz	IE_find_phys		;  N:go to find physical pages
	jmp	IE_exit 		;  Y: exit with error
;
IE_find_phys:
	call	find_phys_pages 	; find mappable physical pages
					; and page frame
	test	[msg_flag],KILLER_MSG	;Q: any killer messages
	jz	IE_alloc		;  N: Go to find and allocate log. pages
	jmp	IE_exit 		;  Y: exit with error
;
;  find and allocate logical emm pages
;
IE_alloc:
	call	AllocMem
	test	[msg_flag],KILLER_MSG	;Q: any killer messages?
	jz	IE_InitEMM		;  N: init EMM
	jmp	IE_exit 		;  Y: exit
;
;  init EMM data
;
IE_InitEMM:

	call	EMM_Init
	test	[msg_flag],KILLER_MSG	;Q: any killer messages?
	jz	IE_InitVDM		;  N: init VDM
	jmp	IE_exit 		;  Y: exit
;
;  init VDM - GDT,IDT,TSS,Page Tables
;
IE_InitVDM:
	call	VDM_Init
	test	[msg_flag],KILLER_MSG	;Q: any killer messages?
	jz	IE_InitTAB		;  N: init TABLES
	jmp	IE_exit 		;  Y: exit
;
;  set up segment pointers to Tables & OEM table init
;
IE_InitTAB:
	call	InitTab
	jnc	IE_InitT_Good		;Q: any memory allocation error?
	or	[msg_flag],MEM_ERR_MSG	;  Y: Some serious memory error
IE_InitT_Good:
	test	[msg_flag],KILLER_MSG	;Q: any killer messages?
	jz	IE_chkbase		;  N: check base memory left
	jmp	IE_exit 		;  Y: exit
;
;	Verify that we will have at least 64k of base memory after MEMM
;	is loaded
;
IE_chkbase:
	int	12h			; get base memory size
	push	ax			; save it
	mov	ax,[driver_end] 	; get offset of end of MEMM resident
	add	ax,15			; convert to paragraphs
	shr	ax,4
	add	ax,[driver_end+2]	; add in segment of brk address
	add	ax,63			; round up to kbytes (64 paras per K)
	shr	ax,6			; AX = kbytes to end of MEMM resident
	add	ax,DOS3X_ADJ+64 	; add in dos 3.xx adjustment and 64k
	pop	dx			; get base memory back
	cmp	dx,ax			; q: do we have enough?
	jae	IE_setbrk		; y: continue
	or	[msg_flag],MEM_ERR_MSG	; n: set memory error
	jmp	IE_exit 		;    and exit

;
;   set driver break addr in Init Request Header
;
IE_setbrk:
	mov	bx,[bp+2]		; get entry DS from stack
	mov	es,bx
	mov	bx,[bp+10]		; ES:BX pts to req hdr
	mov	ax,[driver_end] 	; get brk addr offset
	mov	ES:[bx.BRK_OFF],ax	; set it
	mov	ax,[driver_end+2]	; get brk addr segment
	mov	ES:[bx.BRK_SEG],ax	; set it
;
;   check exit status of VDM/MEMM  (now with lim 4.0) exit must be ON
;
;	 cmp	 [Auto_Mode],0		 ;Q: exit in Auto mode ?
;	 je	 IE_chkOFF		 ;  N: then continue
;	 mov	 [Active_Status],0	 ;  Y: exit in OFF state
;IE_chkOFF:
;	 cmp	 [Active_Status],0	 ;Q: exit in real mode - OFF
;	 je	 IE_Exit		 ;  Y: continue

; Initialize DEBX_GSEL GDT Selector and Deb386
;
	push	ds
	push	es
	push	ax
	push	bx
	push	cx
	push	si
	push	di

	push	[IDT_Seg]
	pop	es				; ES:DI <-- IDT
	push	[GDT_Seg]
	pop	ds				; DS:SI <-- GDT
	mov	bx, DEBX_GSEL
	and	bl, SEL_LOW_MASK
	mov	word ptr [bx], 1800h		; Limit = 20M
	mov	word ptr [bx + 2], 0	
	mov	byte ptr [bx + 4], 0		; Base = 0
	mov	byte ptr [bx + 5], D_DATA0	; Ring 0 Data
	mov	byte ptr [bx + 6], 80h		; Page Granularity

	mov	ax, 4400h			; Initialize Deb386
	mov	bx, DEBX_GSEL			; BIG selector for all addresses
	mov	cx, DEB1_GSEL			; start of 5 working Selector
	xor	si, si
	xor	di, di
	int	68h

	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	pop	es
	pop	ds

	call	FarGoVirtual		;  N: go into virtual mode

;
;  exit - display status messages and set exit status
;
IE_exit:
;
;  display signon message first
;
	mov	dx,offset LAST:InitMess
	PRINT_MSG
;
; check for messages to display
;
IE_Install:
	mov	cx,MAX_MSG		; number of potential msgs
	mov	si,offset msg_tbl	; table of messages
m_loop:
	test	[msg_flag],01		; q:is this one set?
	jz	m_inc_ptr		; n: increment table pointer
	mov	dx,cs:[si]		; y: display message
	PRINT_MSG
	cmp	cx,KILL_MSG		; q: is this one a killer?
	jbe	m_inc_ptr		; n: continue
	jmp	IE_not_installed	; y: don't install
m_inc_ptr:
	inc	si			; increment msg table ptr
	inc	si
	shr	[msg_flag],1		; look for next flag
	loop	m_loop
;
	mov	ax,[pool_size]		; size of EMM page pool in Kbytes
	mov	di,offset LAST:ISizeMess; store decimal size in ASCII here.
	call	b2asc10 		; convert to ASCII...
;
	mov	ax,[ext_size]
IFNDEF	NOHIMEM
	add	ax,[hi_size]
endif
	mov	di,offset LAST:ExtSizeMess ; store decimal size of ext/hi alloc
					   ; here
	call	b2asc10

	mov	ax,[sys_size]
	mov	di,offset LAST:SysSizeMess ; system memory allocated
	call	b2asc10
;
	mov	ax,[PF_Base]		; page frame base addr
	shr	ax,8			; shift right to get significant digits
	mov	di,offset LAST:PFBAMess+1; where to put ascii base address
base_loop:
	push	ax			; save all digits
	and	ax,0fh			; get one digit
	cmp	ax,9			; q: digit <=9
	jbe	skip_dig_adj		; y: don't adjust
	add	ax,'A'-':'
skip_dig_adj:
	add	ax,'0'			; make it ascii
	mov	CS:[di],al		; store in message
	dec	di			; update pointer
	pop	ax			; get all digits back
					; shift right for next digit
	shr	ax,4			; q: done?
	jnz	base_loop		; n: do another
;					  y: print it
	mov	dx,offset LAST:InstallMess
	PRINT_MSG
;
;	 mov	 dx,offset LAST:AutoMess	 ; assume AUTO
;	 cmp	 [Auto_Mode],0			 ;Q: auto mode ?
;	 jne	 print_mode			 ;  Y: display message
;	 mov	 dx,offset LAST:InactiveMess	 ;  N: assume OFF
;	 cmp	 [Active_Status],0		 ; q: OFF specified?
;	 jz	 print_mode			 ; y
;	 mov	 dx,offset LAST:ActiveMess	 ; n
;print_mode:
;	 PRINT_MSG
;
;   Ok, now we can patch int15h - must be careful not to install
;	patch when Active_Status set, but not in virtual mode
;
	pushf
	cli				; clear ints
	xor	ax,ax
	mov	ds,ax				; DS -> 0:0
	ASSUME	DS:ABS0
	les	bx,dword ptr [i15_vector]	; DS:BX -> pts to old one
	mov	ax,offset R_CODE:i15_Entry
	mov	[i15_vector],ax 		; set new ip
	mov	ax,seg R_CODE			;
	mov	[i15_vector+2],ax		; set new cs
	mov	ds,ax				; DS -> R_CODE
	ASSUME	DS:R_CODE
	mov	[i15_Old],bx			; save old IP
	mov	[i15_Old+2],es			; save old CS
	popf					; restore IF
	mov	ax,seg DGROUP
	mov	ds,ax				; DS -> dgroup
	ASSUME	DS:DGROUP
;
;   now patch int67 for EMM functions
;
	pushf
	cli				; clear ints
	xor	ax,ax
	mov	ds,ax				; DS -> 0:0
	ASSUME	DS:ABS0
	mov	ax,offset R_CODE:EMM_rEntry
	mov	[i67_vector],ax 		; set new ip
	mov	ax,seg R_CODE			;
	mov	[i67_vector+2],ax		; set new cs
	popf					; restore IF
	mov	ax,seg DGROUP
	mov	ds,ax				; DS -> dgroup
	ASSUME	DS:DGROUP
;
; all done with no errors
;
	xor	ax,ax			; NO errors
;
IE_leave:
	pop	es
	pop	ds
	pop	di
	pop	bp
	pop	dx
	pop	bx
	ret
;
IE_not_installed:
	call	DeallocMem		; put back any memory we took
	mov	ax,ERROR		; error return
	jmp	IE_leave
;
Init_MEMM386	endp

;
page
;******************************************************************************
;
;	parser - parse out MEMM parameters and set appropriate values
;		 for expanded memory size ([pool_size]), page frame base
;		 address ([PF_Base])
;
;			entry:	es:di ==  config.sys command line parameters
;				ds = DGROUP
;
;			exit:	[pool_size] = expanded memory size
;				[PF_Base] = page frame base address
;				[Active_Status] =flag for virtual/real mode exit
;				[msg_flag] = appropriate messages to display
;
;			used:	none
;
;******************************************************************************
;
parser	proc	near
	push	ax		; BP+16
	push	bx		; BP+14
	push	cx		; BP+12
	push	dx		; BP+10
	push	si		; BP+8
	push	di		; BP+6
	push	bp		; BP+4
	push	ds		; BP+2
	push	es		; BP+0
	mov	bp,sp		;
	cld			; make sure we go forward
	xor	ax,ax		; clear accumulator
;
;	Skip past MEMM.EXE in command line
;
parm1_loop:				; find 1st parameter
	mov	al,es:[di]
	cmp	al,' '			; q: find end of MEMM.exe?
	jbe	ploop1			; y: start parsing
	inc	di			; n: try next one
	jmp	short parm1_loop
jmp_def:
	jmp	set_def
;
jmp_PF:
	jmp	chk_PF
;
;jmp_onf:
;	 jmp	 chk_onf
;
;jmp_auto:
;	 jmp	 chk_auto
;
jmp_Hx:
	jmp	chk_Hx
;
jmp_Xs:
	jmp	chk_Xs

ploop1:
	mov	si,offset DGROUP:arg_str; ds:si = storage for argument
	mov	cx,max_arg_len		; maximum length of argument
	call	get_token_far		; get next token
	or	cx,cx			; q: anything there?
	jz	jmp_def 		; n: go set default values
	lodsb				; y: get 1st char
	cmp	al,'m'			; q: PF base address?
	je	jmp_PF			;   maybe: go validate it
	cmp	al,'h'			; q: Himem enable /disable?
	je	jmp_Hx			;   maybe: go validate it
	cmp	al,'x'			; q: Exclude segment parameter
	je	jmp_Xs			;   maybe: go validate it
;	 cmp	 al,'o' 		 ; q: ON/OFF?
;	 je	 jmp_onf		 ;   maybe: go validate it
;	 cmp	 al,'a' 		 ; q: AUTO?
;	 je	 jmp_auto		 ;   maybe: go validate it

	cmp	al,'0'			; q: is it a digit (size)
	jb	inv_parm		; n: invalid
	cmp	al,'9'			; q: is it a digit?
	jbe	chk_siz 		; y: validate the size
inv_parm:
	or	[msg_flag],INV_PARM_MSG ; set invalid parameter flag
	jmp	short ploop1		; continue
chk_siz:
	mov	bx,cx			; bx = number of digits
	mov	byte ptr [bx+si-1],' '	; terminate string
	mov	cx,10			; decimal multiplier
	xor	dx,dx			; clear upper 16 bits
	xor	bx,bx			; clear temporary accumulator
	cmp	[pool_size],0		; q: have we already done this?
	jz	dig_loop		; n: continue
	mov	dx,1			; y: skip all of this
dig_loop:
	or	dx,dx			; q: overflow?
	jnz	new_digit		; y: just skip rest of digits
	sub	al,'0'			; get ones value
	xchg	ax,bx			; swap accumulated value to ax
	mul	cx			; times 10
	add	ax,bx			; add in ones value
	adc	dx,0			; carry to dx
	xchg	ax,bx			; temporary value to bx
;
new_digit:
	lodsb				; get new char into al
	cmp	al,'0'			; q: between 0 & 9?
	jb	dig_exit		; n: done
	cmp	al,'9'
	ja	dig_exit
	jmp	dig_loop		; y: process it
;
dig_exit:
	cmp	al,' '			; q: any invalid digits?
	jne	ck_inv_parm		; y: invalid parameter
	or	dx,dx			; q: something wrong?
	jz	chk_siz1		; n: not yet
	cmp	[pool_size],0		; q: is this the second time for size?
	jz	siz_adj 		; n: they just asked for too much
ck_inv_parm:
	or	[msg_flag],INV_PARM_MSG ; y: only let them do it once
	jmp	ploop1			; continue
chk_siz1:
	cmp	bx,16			;q: did they ask for too little?
	jb	siz_adj 		; y: go adjust it
	cmp	bx,MAX_SIZE		;q: too much?
	ja	siz_adj 		; y: adjust it
	mov	dx,0fh			; n: make sure it was a multiple of 16k
	and	dx,bx			;q: was it?
	jz	set_siz 		; y: no problem
	sub	bx,dx			; n: drop it down
	jmp	siz_msg 		; and give them the message
siz_adj:
	mov	bx,256			; default value for size
siz_msg:
	or	[msg_flag],SIZE_ADJ_MSG ; size adjusted
set_siz:
	mov	[pool_size],bx		; save it
	jmp	ploop1			; go check more parameters


;
;	Check page frame base address
;
chk_PF:
	cmp	cx,2			; q: 2 and only 2 chars in argument?
	jne	inv_prm 		; n: error
	lodsb				; get Mx specifier
	cmp	[PF_Base],0ffffh	; q: have they already specified this?
	jnz	inv_prm 		; y: don't let them do it again
	cmp	al,'0'			; q: between 1 & 8?
	jb	inv_prm 		; n: invalid
	cmp	al,'8'
	ja	inv_prm 		; n: invalid
	sub	al,'0'			; make zero relative
	xor	ah,ah			; zero out hi bits
	shl	ax,1			; make word offset
	mov	[PF_Base],ax		; store address
	jmp	ploop1			; get next parameter

;
; supporting use of Hi Ram.  We are providing a command line option for this
; the parameter is specified as He for himem enable or Hd for Himem disable
; this parameter may be specified only once in a command line.	Also
;
chk_Hx:
;	 cmp	 cx,2			 ; q: 2 and only 2 chars in argument
;	 jne	 inv_prm		 ; n: error
;	 lodsb				 ; get Hx specifier
;;
;	 cmp	 [himem_use],0ffh	 ; has this already been specified
;	 jnz	 inv_parm
;;
;	 cmp	 al,'e' 		 ; is user asking us to enable
;	 jne	 Hx$1			 ; no, go to check enable
;;
;	 mov	 [himem_use],01h	 ; enable himem use
;	 jmp	 ploop1
;Hx$1:
;	 cmp	 al,'d'
;	 jne	 inv_parm		 ; if neither d or e it is invalid
;;
;	 mov	 [himem_use],00h
	jmp	ploop1

;
inv_prm:
	or	[msg_flag],INV_PARM_MSG ; invalid
	jmp	ploop1			; get next parameter
;
;
; check for exclusion of segments.  this parameter is specfied thusly:
;
;	X:nnnn-mmmm where nnnn is lo segment and mmmm is hi segment of range to
;		    be excluded from being mappable.
;
; more than one of these may be specified.
;
chk_Xs:
	call	handle_Xswitch
	jc	inv_parm
	jmp	ploop1
;
;
;	Check for ON/OFF
;
;chk_onf:
;	 lodsb				 ; get next char
;	 cmp	 [Active_Status],1	 ; q: have they already specified this?
;	 jbe	 inv_prm		 ; y: ignore and set error flag
;	 cmp	 [Auto_Mode],1		 ; n:q: have they specified auto_mode?
;	 je	 inv_prm		 ;   y: ignore and set error flag
;	 cmp	 al,'n' 		 ; q: on?
;	 jne	 onf_cont		 ; n: continue
;	 cmp	 cx,2			 ; y: is that all there is?
;	 jne	 inv_prm		 ; n: error
;	 mov	 [Active_Status],1	 ; y: set on
;	 mov	 [Auto_Mode],0		 ;    clear Auto mode
;	 jmp	 ploop1 		 ; get next parameter
;onf_cont:
;	 cmp	 al,'f' 		 ; q: OF?
;	 jne	 inv_prm		 ; n: invalid
;	 lodsb				 ; y: get next char
;	 cmp	 al,'f' 		 ; q: OFF?
;	 jne	 inv_prm		 ; n: invalid
;	 cmp	 cx,3			 ; q: is that all there is?
;	 jne	 inv_prm		 ; n: error
;	 mov	 [Active_Status],0	 ; y: set OFF
;	 mov	 [Auto_Mode],0		 ;    clear Auto mode
;	 jmp	 ploop1 		 ; get next parameter
;
;	Check for AUTO
;
;chk_auto:
;	 cmp	 [Active_Status],1	 ; q: have they already specified ON/OFF?
;	 jbe	 inv_prm		 ; y: ignore and set error flag
;	 cmp	 [Auto_Mode],1		 ; n:q: have they specified auto_mode?
;	 je	 inv_prm		 ;   y: ignore and set error flag
;	 cmp	 cx,AUTO_LEN		 ;   n: q: parameter correct length ?
;	 jne	 inv_prm		 ;	n: ignore and set error flag
;	 push	 es			 ;	y: check for 'AUTO'
;	 push	 di
;	 dec	 si			 ;  DS:SI pts to begin of arg
;	 mov	 di,offset LAST:AUTO_parm
;	 push	 cs
;	 pop	 es			 ; ES:DI pts to 'AUTO'
;	 cld
;	 repe cmpsb			 ;Q: do CX bytes compare ?
;	 pop	 di			 ; restore DI
;	 pop	 es			 ; restore ES
;	 jne	 inv_prm		 ; N: invalid parameter message
;	 mov	 [Auto_Mode],1		 ; Y: set AUTO mode
;	 jmp	 ploop1 		 ; get next parameter
;
;	Set default values for those items that were not specified
;
set_def:

    ;
    ; default pool size if not defined is 256k
    ;
set_pool_size:
	cmp	[pool_size],0		; q: did they specify size?
	jnz	set_himem		; y: ok
	mov	[pool_size],256 	; n: set default
	or	[msg_flag],SIZE_ADJ_MSG ; display size adjusted

    ;
    ; default of use of hi system ram is that it should not be used
    ;
set_himem:
;	 cmp	 [himem_use],0ffh	 ; q:did they specify himem enb/dsb
;	 jnz	 parse_xit		 ; y: ok
;	 mov	 [himem_use],0		 ; n: set default that it is not used

parse_xit:				; restore registers and exit
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
parser	endp
;
;   parser local data
;
;AUTO_parm	 db	 "auto"
;AUTO_LEN	 equ	 $-AUTO_parm


msg_tbl 	label	word
		dw	offset LAST:Incorrect_PRT ; Incorrect Processor Type
		dw	offset LAST:Incorrect_DOS ; Incorrect Version of DOS
		dw	offset LAST:InsfMem	  ; Insufficient Memory
		dw	offset LAST:Already_Inst  ; Already Installed
		dw	offset LAST:No_PF_Avail   ; No Page Frame Space Avail
kill_end	label	word		; End of messages that kill driver
		dw	offset LAST:Adj_Size	; Pool Size Adjusted
		dw	offset LAST:InvPFBA	; Page Frame Base Addr Adjusted
		dw	offset LAST:InvMRA	; Map Register Adjusted
		dw	offset LAST:InvParm	; Invalid Parameter msg
		dw	offset LAST:PFWarning	; Page Frame warning message
MAX_MSG 	equ	(this byte - msg_tbl)/2 ; # of messages to display
KILL_MSG	equ	(this byte - kill_end)/2; 1st four will abort driver
;

page
;******************************************************************************
; handle_Xswitch - processes the X switch to make some segments non-mappable  ;
;									      ;
; entry: ds:di string with X switch parameters in form "X:nnnn-mmmm"	      ;
;	 cx is length of string
;									      ;
; exit:  CY set if invalid parameter					      ;
;	 CY clear if parameter processed				      ;
;	    and non-mappable segments excluded				      ;
;									      ;
; uses: flags,ax,cx,si							      ;
;									      ;
; author: ISP 8/24/88					      ;
;									      ;
;*****************************************************************************;
handle_XSwitch	proc	near
;
	cmp	cx,5	    ; must have atleast 5 symbols
	jb	error_Xs    ;
;
	lodsb		    ; get the next letter ":"
	sub	cx,2	    ;
;
	cmp	al,":"	    ; is it ":"
	jne	error_Xs    ; if not it is a bad parameter
;
	call	htoi	    ; convert hex to integer
	jcxz	error_Xs    ; if we have run out we have a bad parameter
;
	mov	bx,ax	    ; save in bx the start segment to be excluded
;
	lodsb		    ; get the next letter
	dec	cx	    ;
	jcxz	error_Xs
	cmp	al,"-"	    ; is it the letter "-"
	jnz	error_Xs    ;
;
	call	htoi	    ; convert hex to mappable
	call	exclude_segments

	clc		    ; set success and
	ret		    ; return
error_Xs:
	stc		    ; set error and
	ret		    ; return
;
handle_XSwitch	endp

;-----------------------------------------------------------------------;
; htoi									;
; 									;
; Converts a string to an integer.					;
; 									;
; Arguments:								;
; 	DS:SI = string							;
; 	CX    = length							;
; Returns:								;
; 	AX    = integer							;
; 	DS:SI = remaining string					;
; 	CX    = remaining length					;
; Alters:								;
; 	nothing								;
; Calls:								;
; 	nothing								;
; History:								;
; 									;
; ISP (isp) 8/24/88 shifted from ps2emm srces		;
;-----------------------------------------------------------------------;


htoi	proc	near
	push	bx
	xor	ax,ax
	mov	bx,ax
htoi_loop:
	jcxz	htoi_done

; get the next character

	mov	bl,[si]
	inc	si
	dec	cx

; see if it's a digit

	sub	bl,'0'
	cmp	bl,9
	jbe	have_hvalue
	sub	bl,'A'-'0'
	cmp	bl,'F'-'A'
	jbe	have_hvalue_but_10
	sub	bl,'a'-'A'
	cmp	bl,'F'-'A'
	ja	htoi_not_digit
have_hvalue_but_10:
	add	bl,10
have_hvalue:

; shift and add

	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	add	ax,bx
	jmp	htoi_loop
htoi_not_digit:
	inc	cx			; give back the character
	dec	si
htoi_done:
	pop	bx
	ret
htoi	endp



page
;******************************************************************************
;
;	b2asc10 - converts binary to ascii decimal and store at CS:DI
;		  stores 5 ascii chars (decimal # is right justified and
;		  filled on left with blanks)
;
;	entry:	ax = binary number
;		DS = DGROUP
;		CS:di = place to store ascii chars.
;
;	exit:	ASCII decimal representation of number stored at DS:DI
;
;	used:	none
;
;	stack:
;
;******************************************************************************
;
b2asc10 proc	near
;
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
;
	mov	si,8			; pointer to base 10 table
	xor	bl,bl			; leading zeroes flag
;
;   convert binary number to decimal ascii
;
b2_loop:
	xor	dx,dx			; clear word extension
	mov	cx,powr10[si]
	div	cx			; divide by power of 10
	or	bl,bl
	jnz	b2_ascii
;
	or	ax,ax			; q: zero result?
	jnz	b2_ascii		;  n: go convert to ascii
;
	mov	al,' '			;  y: go blank fill
	jmp	b2_make_strg		;
;
b2_ascii:
	add	al,'0'			; put into ascii format
	mov	bl,1			; leading zeroes on
;
b2_make_strg:
	mov	CS:[di],al		; put ascii number into string
	xchg	ax,dx
	inc	di			; increment buffer string pointer
	dec	si			; decrement power of 10 pointer
	dec	si			;
	jge	b2_loop 		; Q: Last digit?  N: Jump if not
;
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret				; *** return ***
;
b2asc10 endp
;

LAST	ends				; End of segment
;

	end				; End of module


