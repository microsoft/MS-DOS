

	page 58,132
;******************************************************************************
	title	MEMM386 - main module for MEMM
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;	Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;	Module: MEMM386 - main module
;
;	Version: 0.04
;
;	Date:	May 24,1986
;
;	Author:
;
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;	04/24/86 Original	From EMML LIM driver.
;	06/26/86 0.02		Put CLD in Inst_Chk
;	06/28/86 0.02		Name change from MEMM386 to MEMM.
;	07/05/86 0.04		Changed segment to R_CODE
;	06/07/88		exclude VDISK header info's since we are
;				using INT-15 method now (Paul Chan)
;	06/21/88		Removed VDISK stuff.
;
;******************************************************************************
;   Functional Description:
;	MEMM is an Expanded Memory Manager which implements expanded memory
;   on the MICROSOFT 386 machine.  MEMM uses Virtual mode and paging on
;   the 386 to make Extended memory useable as expanded memory.  The are two
;   basic functional parts of MEMM;  the Virtual DOS Monitor (VDM) and the
;   Expanded Memory Manager (EMM).  VDM simulates the 386 Real mode under the
;   386 Virtual mode.  EMM provides the software functionality for a EMM as
;   described in the Lotus-Intel-Microsoft (LIM) specification for expanded
;   memory.
;	This module contains the Device Driver header, stategy, and interrupt
;   routines required by a LIM standard EMM.
;	This device driver is a .EXE file and may be invoked as a DOS utility
;   program as well as loaded as a device driver.  When it is loaded as a
;   DOS utility, MEMM has three command line options: ON,OFF and AUTO.
;   The OFF options disables MEMM and exits to MS-DOS in real mode.
;   The ON option enables MEMM and exits to MS-DOS in virtual mode (only
;   if the MEMM.EXE driver has been loaded).  The AUTO option puts
;   MEMM in "auto mode".  In this mode, MEMM will enable and disable
;   itself automatically, depending on accesses to the EMM functions.
; 	The general device driver CONFIG.SYS options are described below.
;
;    Syntax:
;
; device=[d]:[<path>]MEMM.EXE [SIZE] [Mx] [ON | OFF | AUTO]
;
;
;    NOTE: SUNILP - See if we need the /X option for excluding segments from
;    being mappable.  This turned out to be quite useful in ps2emm and since
;    here we are dealing with different hardware this option may turn out
;    essential here**** WISH001
;
;    The following sections describe the optional arguments which the
;    user may specify for MEMM.EXE at load time (in the CONFIG.SYS
;    file).  These arguments are placed after the device driver name
;    in the CONFIG.SYS file.
;
;    MEMM arguments in the CONFIG.SYS file must be separated by spaces
;    or tabs.  Arguments may appear in any order; however, any redundant
;    or excessive instances are ignored and only the first valid instance
;    of an argument is used.  Invalid or extraneous arguments produce an
;    error message.
;
;    [SIZE]
;
;    The argument SIZE is the amount of expanded memory desired in 
;    K bytes.  The default amount of expanded memory, 256K, is available
;    without using any extended memory.  To use more than 256K of
;    expanded memory, the 386 system must have extended memory.  When
;    If there is not enough memory available
;    to provide SIZE kbytes of expanded memory, MEMM will adjust SIZE to
;    provide as much expanded memory as possible.
;
;	- The valid range for SIZE is 16K - 8192K.  Value outside this range
;	  are converted to the default of 256K.
;
;	- If SIZE is not a multiple of 16K (size of an EMM page), then SIZE
;	  is rounded down to the nearest multiple of 16K.
;
;    [Mx]
;
;    The argument [Mx] specifies the address of the 64k EMM page frame.
;    This argument is optional since MEMM can choose an appropriate
;    location for the page frame when it is loaded. To choose a location
;    the 386 EMM driver scans memory addresses above video memory for
;    an appropriate 64K address range for the EMM page frame.  For a
;    default page frame base address MEMM looks for option ROMs and
;    RAM in the EMM addressing range and chooses a 64K slot of memory
;    for the page frame which apparently does not confict with existing
;    memory.  The user may override the 386 EMM driver's choice by
;    specifying the beginning address with the Mx argument.  If the
;    user specifies a page frame base address which conflicts with an
;    option ROM or RAM, MEMM displays a warning message and uses the
;    specified page frame base address.
;
;    The following options are possible:
;			Page Frame Base Address
;		M1 => 0C0000 Hex
;		M2 => 0C4000 Hex
;		M3 => 0C8000 Hex
;		M4 => 0CC000 Hex
;		M5 => 0D0000 Hex
;
;    [ ON | OFF | AUTO ]
;
;    The argument [ON | OFF | AUTO] specifies the state of the 386 when
;    MEMM returns to DOS after the driver INIT routine finishes.  If this
;    argument is ON, then MEMM returns to DOS in virtual mode and
;    expanded memory is available.  If this argument is OFF, then MEMM
;    returns to DOS in real mode and expanded memory is not available
;    until MEMM is turned ON.  The default for this argument is AUTO
;    mode.  In AUTO mode, the MEMM.EXE device driver will exit to
;    DOS in the OFF state; afterwards, MEMM will enable and disable
;    itself automatically.   In the AUTO mode, MEMM will be enabled
;    only while the expanded memory manager is in use.
;
;
;******************************************************************************
.lfcond
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************

;
;   R_CODE publics
;
	public	strategy
	public	interrupt
	public	MEMM_Entry

;
;   _TEXT publics
;
	public	ELIM_EXE		; .EXE execution entry point
	public	ELIM_link
	public	Inst_chk		; Check to see if MEMM already installed
	public	Inst_chk_f		; Far call version of above

	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
	include	driver.equ
	include	driver.str
	include	vdmseg.inc

FALSE	equ	0
TRUE	equ	not FALSE

MS_DOS	equ	21h			; DOS interrupt
GET_PSP equ	62h			; get program segment prefix

NULL		EQU		0FFFFH			;Null address pointer

dospsp_str	struc
		db	80h dup (?)
cmd_len		db	?		; length of command line
cmd_line	db	?		; commande line
dospsp_str	ends

;******************************************************************************
;			E X T E R N A L    R E F E R E N C E S
;******************************************************************************
;
abs0	segment use16 at 0000h

	org	67h*4		; EMM function interrupt
int67	dw	?		; offset of vector
	dw	?		; segment of vector
abs0	ends

LAST	segment
extrn	Init_MEMM386:far		; initializes VDM,EMM, and driver
LAST	ends

R_CODE	segment
extrn	ELIM_Entry:far		; general entry point for MEMM functions
R_CODE	ends

_TEXT	segment
extrn	onf_func:near		; perform on, off, or auto checking for elim.exe
_TEXT	ends

	page
;******************************************************************************
;			S E G M E N T   D E F I N I T I O N
;******************************************************************************
;
;******************************************************************************
;
;	R_CODE Code Segment
;
;******************************************************************************
;
R_CODE	segment
	assume	cs:R_CODE, ds:R_CODE, es:R_CODE, ss:R_CODE

Start:
;******************************************************************************
;  Device driver header
;******************************************************************************
;
	DW		NULL			;Null segment address
	DW		NULL			;Null offset address
	DW		CHAR_DEV+IOCTL_SUP	;Attribute - Char
	DW		OFFSET STRATEGY 	;Strategy routine entry
	DW		OFFSET INTERRUPT	;Interrupt routine entry
	DB		'EMMXXXX0'              ;Character device name
;
;******************************************************************************
;		GENERAL FUNCTIONS ENTRY POINT
;	R_CODE:ELIM_Entry is a entry point for executing general MEMM
;			functions. (e.g. ON, OFF function).
;******************************************************************************
;
MEMM_Entry	dw	offset	ELIM_Entry		; general entry point

;******************************************************************************
;	       MEMM signature
;******************************************************************************
memmsig	db	'MICROSOFT EXPANDED MEMORY MANAGER 386'
SIG_LENGTH	equ	(this byte - memmsig)

	page
;******************************************************************************
;			L O C A L   D A T A   A R E A
;******************************************************************************

;
;	Define the command dispatch table for the driver functions
;
Cmd_Table	LABEL		NEAR
	DW		Init_Call		;0 - Initialization
	DW		Null_Exit		;1 - Media Check
	DW		Null_Exit		;2 - Get BPB
	DW		Null_Exit		;3 - IOCTL input
	DW		Null_Exit		;4 - Input (Destructive)
	DW		Null_Exit		;5 - No wait input
	DW		Null_Exit		;6 - Input status
	DW		Null_Exit		;7 - Input buffer flush
	DW		Null_Exit		;8 - Output (Write)
	DW		Null_Exit		;9 - Output with verify
	DW		Null_Exit		;A - Output status
	DW		Null_Exit		;B - Output buffer flush
	DW		Null_Exit		;C - IOCTL output
TBL_LENGTH	EQU		(THIS BYTE-CMD_TABLE)/2 ;Dispatch table length

	public	ReqPtr
ReqPtr		label	dword	; dword ptr to Request Header
ReqOff		dw	0	; saved offset of Request Header
ReqSeg		dw	0	; saved segment of Request Header

	page
;******************************************************************************
;	Strategy - strategy routine for MEMM
;
;	ENTRY: ES:BX = pointer to Request Header
;
;	EXIT: CS:ReqOff, CS:ReqSeg - saved pointer to Request Header
;
;	USED: none
;
;******************************************************************************
Strategy	proc		far
	mov		CS:[ReqOff],bx 	;Save header offset
	mov		CS:[ReqSeg],es 	;Save header segment
	ret
Strategy	endp

;******************************************************************************
;	Interrupt - device driver interrupt routine for MEMM
;
;	ENTRY: CS:ReqPtr = pointer to request header.
;
;	EXIT: Request completed.
;
;	USED: none
;
;******************************************************************************
Interrupt	proc		far
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	cld					;All strings forward
	lds	bx,CS:[ReqPtr]	 		;DS:BX pts to Request Header
	mov	al,[bx.COMMAND_CODE]		;Get the command code
	cmp	al,TBL_LENGTH			;Check for validity
	jae	Invalid 			;Jump if command invalid
	cbw					;Command to a full word
	shl	ax,1				;Compute dispatch index
	mov	si,OFFSET Cmd_Table		;Point to dispatch table
	add	si,ax				;Index based on command
	call	CS:[si] 			;Call correct routine

;
;   ENTRY:	AX = Status field for Request Header
;
Finish:
	lds	bx,CS:[ReqPtr] 	;Get request header ptr.
	or	ah,DON			;Set done bit in status
	mov	DS:[bx.STATUS_WORD],ax	;Save status in header
	pop	es			;Restore the ES register
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret			
Invalid:
	mov	al,UNK_COMMAND		; unknown command
	mov	ah,ERR			; error
	stc
	jmp	SHORT Finish		;Go return to caller
Interrupt	endp

;******************************************************************************
;	Null_Exit: do nothing
;
;	ENTRY: DS:BX pts to request header
;
;	EXIT:	No error returned.
;		CLC
;
;******************************************************************************
Null_Exit	proc	near
;
	xor	ax,ax
	clc
	ret
;
Null_Exit	endp

;******************************************************************************
;	Init_Call - call initialization routine
;
;	ENTRY: DS:BX pts to request header
;
;	EXIT: AX = status field for request header
;
;******************************************************************************
Init_Call	proc	near
;
	call	Init_MEMM386
	ret
;
Init_Call	endp

;******************************************************************************
	db	'SBP'
	db	'BMT'
;******************************************************************************
;

R_CODE	ends

	page
;******************************************************************************
;
;	_TEXT Code Segment
;
;******************************************************************************
_TEXT	segment
	assume	cs:_TEXT, ds:_TEXT, es:_TEXT, ss:_TEXT

FarLink	dd	0		; far pointer to installed memm386 entry point
				; OK as writeable because it is only used
				; during .EXE execution.

;
rh	db	23,0,0,0,0,8 dup (0)
	db	10 dup (0)
;
MEMM:
;******************************************************************************
;
;	ELIM_EXE - .EXE entry point - when MEMM.EXE is invoked as a DOS
;		   utility.
;
;******************************************************************************

;------------------------------------------------------------------------------
; NOTE** SUNILP .. Paulch changed this to load it as an terminate and stay
;	 resident.  This entry should only be to turn an existing MEMM ON
;	 OFF or AUTO.  Once the driver is debugged change this back to the
;	 original code given here in comments. Also remove the above rh
;	 storage block. WISH002
;ELIM_EXE	 proc	 near
;;
;	 push	 cs
;	 pop	 ds			 ; ds = cs
;	 mov	 ah,GET_PSP		 ; get segment of PSP
;	 int	 MS_DOS
;	 mov	 es,bx			 ; DOS call returned seg in bx
;	 mov	 di,offset cmd_line	 ; es:di = command line
;	 call	 onf_func		 ; look for on, off, or auto
;	 mov	 ax,4c00h		 ; exit to DOS
;	 int	 MS_DOS
;;
;ELIM_EXE	 endp
;;
;------------------------------------------------------------------------------

ELIM_EXE	proc	near
;
	extrn	exe_stack:byte

	push	seg STACK
	pop	ss
	mov	sp, offset STACK:exe_stack
	push	cs
	pop	ds
	mov	ah,GET_PSP
	int	MS_DOS
	mov	es,bx
	mov	di,offset cmd_line

	mov	bx,seg rh
	mov	ds,bx
	mov	bx,offset rh
	mov	[bx+20],es
	mov	[bx+18],di

	push	ds
	pop	es
	call	Strategy
	call	Interrupt

	mov	bx,seg rh
	mov	es,bx
	mov	bx,offset rh
	mov	dx,es:[bx+16]
	sub	dx,es:[bx+20]
	mov	ah,31h
	int	21h
;
	
;	push	cs			
;	pop	ds			; ds = cs
;	mov	ah,GET_PSP		; get segment of PSP
;	int	MS_DOS
;	mov	es,bx			; DOS call returned seg in bx
;	mov	di,offset cmd_line	; es:di = command line
;	call	onf_func		; look for on, off, or auto
	mov	ax,4c00h		; exit to DOS
	int	MS_DOS
;
ELIM_EXE	endp
;
;******************************************************************************
;	Inst_chk_f - call Inst_chk
;
;	ENTRY: see Inst_chk
;
;	EXIT: see Inst_chk
;
;	USED: none
;
;******************************************************************************
Inst_chk_f 	proc		far
	call	Inst_chk
	ret
Inst_chk_f	endp

;******************************************************************************
;	Inst_chk - Check to see if MEMM is already installed
;
;	ENTRY: int 67 vector
;
;	EXIT: ax = 0 if not already installed
;	      ax = 1 if MEMM is already installed
;	      _TEXT:[FarLink] = far address for installed MEMM entry point
;
;	USED: none
;
;******************************************************************************
Inst_chk 	proc		near
	push	di			; save di
	push	si			; and si
	push	ds			; and ds
	push	es			; and es
	push	cx			; and cx
;
	xor	ax,ax			; put segment 0000h in ds
	mov	ds,ax		
	ASSUME	DS:abs0			; assume ds is abs0
	mov	ax,[int67+2]		; get segment pointed to by int 67
	mov	es,ax
	ASSUME	ES:R_CODE

	push	seg R_CODE
	pop	ds			; set DS = R_CODE
	assume	DS:R_CODE		; update assume

	mov	di,offset memmsig	; memm386 signature
	mov	si,di			; save for source string
	xor	ax,ax			; initialize to not found
	mov	cx,SIG_LENGTH		; length to compare
	cld				;  strings foward
	repe	cmpsb			; q: is the memm386 signature out there?
	jne	not_inst		; n: return zero
	inc	ax  			; y: return one
	mov	word ptr CS:[FarLink+2],es	; set segment of far call
	mov	cx,ES:[MEMM_Entry]		; get offset for far call
	mov	word ptr CS:[FarLink],cx	; set offset of far call
not_inst:

	ASSUME	DS:_TEXT, ES:_TEXT

	pop	cx
	pop	es
	pop	ds
	pop	si
	pop	di
	ret
Inst_chk	endp

;******************************************************************************
;	ELIM_link - Link to Installed MEMM's ELIM_Entry
;
;	ENTRY: see ELIM_Entry
;		and
;		_TEXT:[FarLink] = far address of installed MEMM ELIM_Entry
;
;	EXIT: see ELIM_Entry
;
;	USED: none
;
;******************************************************************************
ELIM_link	proc	near
	call	CS:[FarLink]
	ret
ELIM_link	endp


_TEXT	ends

	end	MEMM
