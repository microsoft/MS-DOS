

	page 58,132
;******************************************************************************
	title	EMM - Expanded Memory Manager interface for MEMM
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;    Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;    Module:	EMM - Expanded Memory Manager interface
;
;    Version:	0.05
;
;    Date:	June 14, 1986
;
;    Author:
;
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;	06/14/86 original
;	06/28/86 0.02		Name change from MEMM386 to MEMM
;	06/29/86 0.02		Protect port 84/85 from ints
;	07/05/86 0.04		moved EMM_rEntry to R_CODE
;	07/06/86 0.04		Changed assume to DGROUP
;	07/08/86 0.04		Changed EMM_pEntry to call EMM functions
;				directly
;	07/10/86 0.05		jmp $+2 before "POPF"
;	07/10/86 0.05		added EMM_Flag
;	06/09/88		remove _map_known since there is no map now (pc)
;	07/20/88		remove debugger code (pc)
;
;******************************************************************************
;   Functional Description:
;	The module contains code for calling the EMM functions and a routine
;   for managing the AUTO mode of MEMM.
;	There are two EMM entry points in this module; one for real/virtual
;   mode entry and one for protected mode (IDT entry points here).   When
;   MEMM is ON (system in Virtual mode),  INT 67H calls transition to protected
;   mode and the EMM_pEntry entry point.  EMM_pEntry sets up the same stack
;   conditions as the generic int67_Entry dispatcher and calls the appropriate
;   EMM function.   Some EMM functions cannot be executed in protected mode.
;   These functions are called by reflecting the INT 67H to the real/virtual
;   mode entry point.	EMM functions which are executed in PROTECTED mode
;   will take less time (they don't suffer the extra time to reflect the
;   INT 67H).
;
;******************************************************************************
.lfcond
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	EMM_pEntry		; protected mode entry point
	public	EMM_rEntry		; real mode entry point
	public	EMM_rEfix		; label for far jump to int67_entry
	public	_AutoUpdate		; update auto mode of VDM/EMM
	public	EMM_Flag		; flag for EMM calls

	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
	include vdmseg.inc
	include vdmsel.inc
	include vm386.inc
;	include instr386.inc
	include oemdep.inc
	include emmdef.inc

FALSE	equ	0
TRUE	equ	not FALSE

;
;   these EMM functions are handled in protected mode
;
EMM_MAP_PAGE		equ	44h	; map handle page
EMM_RESTORE		equ	48h	; restore page map
EMM_GET_SET		equ	4Eh	; get/set page map
EMM_GET_SET_PARTIAL	equ	4Fh	; get/set partial page map
EMM_MAP_PAGE_ARRAY	equ	50h	; map handle page array
EMM_ALTER_MAP_JUMP	equ	55h	; alter mapping and jump
EMM_ALTER_MAP_CALL	equ	56h	; alter mapping and call
EMM_MOVE_XCHG_MEM	equ	57h	; move/xchg memory region
EMM_ALTER_MAP_REG_SET	equ	5Bh	; alternate map register set

EMM_HW_MALFUNCTION	equ	81h	;

;******************************************************************************
;			E X T E R N A L    R E F E R E N C E S
;******************************************************************************
;
ABS0	segment use16 at 0000h

	org	67h * 4 	; EMM function interrupt
EMMVec	dw	?		; offset of vector
	dw	?		; segment of vector

ABS0	ends

_DATA	segment

extrn	_EMMstatus:word
extrn	Active_Status:byte	; current VDM status
extrn	Auto_Mode:byte		; current Auto mode status
;extrn	_map_known:byte 	; non-zero => I/O map known to a user
extrn	_handle_count:word	; number of active EMM handles
extrn	_regp:word		; pointer to args on stack

_DATA	ends

_TEXT	segment

extrn	int67_Entry:far		; it's far because we need CS on stack too
extrn	GoVirtual:near
extrn	ErrHndlr:near
extrn	hw_int:near
extrn	RRProc:near

extrn	_GetStatus:near
extrn	_GetPageFrameAddress:near
extrn	_GetUnallocatedPageCount:near
extrn	_AllocatePages:near
extrn	_MapHandlePage:near
extrn	_DeallocatePages:near
extrn	_GetEMMVersion:near
extrn	_SavePageMap:near
extrn	_RestorePageMap:near
extrn	_GetPageMappingRegisterIOArray:near
extrn	_GetLogicalToPhysicalPageTrans:near
extrn	_GetEMMHandleCount:near
extrn	_GetEMMHandlePages:near
extrn	_GetAllEMMHandlePages:near
extrn	_GetSetPageMap:near

extrn	_GetSetPartial:near
extrn	_MapHandleArray:near
extrn	_AlterMapAndJump:near
extrn	_AlterMapAndCall:near
extrn	_MoveExchangeMemory:near
extrn	_AlternateMapRegisterSet:near

_TEXT	ends

	page
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************
;
_DATA	segment
EMM_Flag	db	0	; non-zero => EMM function called by our code
_DATA	ends

	page
;******************************************************************************
;
;	_TEXT Code Segment
;
;******************************************************************************
;
_TEXT	segment
	assume	cs:_TEXT, ds:DGROUP, es:DGROUP
;******************************************************************************
;	protected mode dispatch table
;   allocate(43h)/deallocate(45h) pages  and get I/O map (49h)
;	MUST be reflected to Virtual mode
;	MapHandlePage,RestorePageMap,GetSetPageMap,GetSetPartial,
;	MapHandleArray,MoveExchangeMemory,AlterMapAndJump,
;	AlterMapAndCall and AlternateMapRegisterSet are protected mode ONLY.
;******************************************************************************
EpE_Dispatch	label	word
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:_MapHandlePage		;44h
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:_RestorePageMap		;48h
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:_GetSetPageMap		;4eh
	dw	offset _TEXT:_GetSetPartial		;4fh
	dw	offset _TEXT:_MapHandleArray		;50h
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:_AlterMapAndJump		;55h
	dw	offset _TEXT:_AlterMapAndCall		;56h
	dw	offset _TEXT:_MoveExchangeMemory	;57h
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:_AlternateMapRegisterSet	;5bh
	dw	offset _TEXT:EpE_Null
	dw	offset _TEXT:EpE_Null

	page
;******************************************************************************
;	EMM_pEntry - protected mode entry point for EMM function calls
;
;	ENTRY:	Protected mode
;		DGROUP:[EMM_Flag] = zero => reflect this int
;		SS:[SP] pointing to virtual mode INT stack frame
;
;	EXIT:	Protected mode
;		if this EMM function is to be handled in protected mode,
;			registers as set by EMM functions
;		else
;			reflect int 67 to virtual mode EMM code
;
;	NOTE: *****
;		Allocate(43h)/deallocate(44h) pages and get I/O map (49h)
;		MUST be reflected to Virtual mode.
;
;	USED:	none
;
;******************************************************************************
;
;  reflect EMM function to real mode
;
EpE_reflect:
	push	67h		; refect
	jmp	hw_int		; it...
;
;
;  client not in Virtual mode
;
EpE_not_VM:
	pop	ebp				;     N: call error handler

	mov	ax,ExcpErr			; exception error
	mov	bx,ErrINTProt			; invalid software interrupt
	call	ErrHndlr
;
;  function entry
;
EMM_pEntry	proc	near
;
	push	ebp
	mov	bp,sp
	test	[bp.VTFO+VMTF_EFLAGShi],2	;Q:client in Virtual mode ?
	jz	EpE_not_VM			;  N: handle it
						;  Y: check flag
	push	VDMD_GSEL
	pop	ds				; DS = DGROUP
	push	VDMD_GSEL
	pop	es				; ES = DGROUP
	cmp	[EMM_Flag],0			;Q: did we do this int67 ?
	je	EpE_Reflect			;  N: reflect it
	mov	[EMM_Flag],0			;  Y: clear EMM_Flag for next
						;     time and handle function
						;     in protected mode.
;
;  dispatch EMM function OR reflect to real/vm dispatcher
;
EpE_chk_func:
	HwTabUnlock		; unlock ROM

	push	[bp.VTFO+VMTF_FS]		; client FS
	push	[bp.VTFO+VMTF_GS]		; client GS
	push	[bp.VTFO+VMTF_ES]		; client ES
	push	[bp.VTFO+VMTF_DS]		; client DS
	push	[bp.VTFO+VMTF_EFLAGS]		; client Flag
	push	[bp.VTFO+VMTF_CS]		; client CS
	push	word ptr [bp.VTFO+VMTF_EIP]	; client IP (low word of EIP)
				; stack has - IP,CS,PFlag,DS,ES,GS,FS
	pushad			; all regs saved
	mov	bp,sp		; SS:BP -> to stack args (see r67_Frame struc)
	mov	[_regp],sp	; regp points to regs on stack
	mov	[_regp+2],ss	; regp now has a far ptr to regs

	push	ax
	mov	ax, PFLAG_VIRTUAL		; Faked VM bit
	or	[bp.PFlag], ax			; Incorpated in PFlag
	pop	ax
	;
	; validate function code
	;
	sub	ah,40h		; check if entry code too small
	jb	EpE_inv_exit	; if so, error exit
	cmp	ah,(5Dh-40h)	; check if entry code too big
	ja	EpE_inv_exit	; if so, error exit
				;	else, AH = 0 base function #
	;
	; call through the jump table
	;
EpE_jump:
	xchg	ah,al		; AL = function code
	mov	si,ax
	xchg	ah,al		; AH = function code again
	and	si,00FFh	; SI = function #
	shl	si,1		; SI = table offset
	call	CS:EpE_Dispatch[si] ; call function

	;
	; check to see if we need to patch CS:IP on the iretd stack frame
	;
EpE_Exit:
	test	word ptr [bp.PFlag], PFLAG_PATCH_CS_IP
	jz	EpE_No_Patch

	mov	bp, sp		; use bp to address stack
	;
	; patch iretd's CS:EIP to new CS:IP on stack
	;
	mov	ax, [bp.retaddr]	; get return IP
	mov	[bp.rFS+6], ax		; iretd's IP (6 bytes beyond FS)
	xor	ax, ax
	mov	[bp.rFS+8], ax		; zero high word of EIP
	mov	ax, [bp.rCS]		; get return CS
	mov	[bp.rFS+10], ax		; iretd's CS

EpE_No_Patch:
	popad			; restore regs
	add	sp, 6		; throw away return addr cs and ip and flags
	pop	[bp.VTFO+VMTF_DS]		; client DS
	pop	[bp.VTFO+VMTF_ES]		; client ES
	pop	[bp.VTFO+VMTF_GS]		; client GS
	pop	[bp.VTFO+VMTF_FS]		; client FS


	pop	ebp		; restore bp

	HwTabLock		; lock ROM

	iretd			; return to virtual mode caller
;
;  Null function - do nothing (should not get to here)
EpE_Null:
	ret			; return after doing nothing
;
; EMM error handling
;
EpE_inv_exit:				; set invalid function code error
	mov	byte ptr [bp.rAX+1],INVALID_FUNCTION
	jmp	EpE_Exit

EMM_pEntry	endp

	page
;******************************************************************************
;	EMM_rLink - real/virtual mode link for EMM function calls from
;			R_CODE segment.
;
;	ENTRY:	real/virtual mode
;		all registers as set by user
;
;	EXIT:	real/virtual mode
;		registers as set by EMM functions
;
;	USED:	none
;
;******************************************************************************
EMM_rLINK	proc	far

	;
	;   check for protected mode ONLY function
	;
	cmp	ah,EMM_MAP_PAGE 	;Q: map handle page function ?
	je	ErE_GoProt		;  Y: do it in protected mode
	cmp	ah,EMM_RESTORE		;Q: restore page map function ?
	je	ErE_GoProt		;  Y: do it in protected mode
	cmp	ah,EMM_GET_SET		;Q: get/set page map function ?
	je	ErE_GoProt		;  Y: do it in protected mode
	cmp	ah,EMM_GET_SET_PARTIAL	;Q: get/set partial function ?
	je	ErE_GoProt		;  Y: do it in protected mode
	cmp	ah,EMM_MAP_PAGE_ARRAY	;Q: map handle page array ?
	je	ErE_GoProt		;  Y: do it in protected mode
	cmp	ah,EMM_ALTER_MAP_JUMP	;Q: alter map and jump ?
	je	ErE_GoProt		;  Y: do it in protected mode
	cmp	ah,EMM_ALTER_MAP_CALL	;Q: alter map and call ?
	je	ErE_GoProt		;  Y: do it in protected mode
	cmp	ah,EMM_MOVE_XCHG_MEM	;Q: move/xchg memory region ?
	je	ErE_GoProt		;  Y: do it in protected mode
	cmp	ah,EMM_ALTER_MAP_REG_SET;Q: alternate map register set ?
	je	ErE_GoProt		;  Y: do it in protected mode
					;  N: do it in real/virtual mode
	;
	;   here for real/virtual mode functions
	;
	push	fs
	push	gs
	push	es
	push	ds
	push	00		; PFlag => real mode call to EMM functions
	push	seg DGROUP
	pop	ds		; set DS = DGROUP
	call	int67_Entry	;   call dispatcher
	add	sp,2		; drop PFlag arg
	pop	ds		; restore seg regs
	pop	es
	pop	gs
	pop	fs
	ret			; and return

	;
	;   Here if protected mode function called via real IDT
	;	- set EMM flag and go for it...
	;
ErE_GoProt:
	push	ds
	push	seg DGROUP
	pop	ds			; DS = DGROUP
	cmp	[Active_Status],0	;Q: are we in Virtual Mode ?
	jne	ErE_Pcall		;  Y: call protected mode function
;	mov	[_map_known],TRUE	;  N: set global auto mode flag
	call	_AutoUpdate		;      go into virtual mode
					;      and call function
ErE_Pcall:
	mov	[EMM_Flag],TRUE 	; set flag
	pop	ds			; restore DS
	int	67h			; go for it ...
	ret				; then return

EMM_rLINK	endp

	page
;******************************************************************************
;	_AutoUpdate - updates the EMM status when in AutoMode
;
;	ENTRY:	REAL or VIRTUAL mode ONLY
;		DS = DGROUP segment
;		DS:[Auto_Mode] = non-zero => system currently in auto mode
;		DS:[Active_Status] = non-zero => system currently ON
;		DS:[_map_known] = non-zero => I/O map has been given to a user
;
;	EXIT: exits in real or virtual depending on the state variables
;		DS:[Active_Status] = current ON/OFF status
;
;	USED:	none
;
;******************************************************************************
_AutoUpdate	proc	near
;
	cmp	[Auto_Mode],0		;Q: in Auto mode now ?
	je	AU_exit 		;  N: exit
	cmp	[Active_Status],0	;  Y:Q: ON now ?
	je	AU_chkoff		;	N: check OFF state status
;
;   here if we are currently ON
;
;	cmp	[_map_known],0		;	Y:Q: map known ?
;	jne	AU_exit 		;	    Y: then stay ON...
	cmp	[_handle_count],0	;	    N:Q: any active handles ?
	jne	AU_exit 		;		Y: then stay ON...
	mov	[Active_Status],0	;		N: go to OFF state
	push	ax
	call	RRProc			; Force processor into real mode
	pop	ax
	jmp	AU_exit 		; and leave in real mode
;
;   here if we are currently OFF
;
AU_chkoff:
	cmp	[_handle_count],0	;Q: any active handles ?
	je	AU_exit			;  N: stay off

;	cmp	[_map_known],0		;;  Q: is the map known ?
;	je	AU_exit 		;;    N: then stay OFF...

AU_ON:					;  Y: turn ON EMM
	mov	[Active_Status],1	; go to ON state,
	call	GoVirtual		;  and go to virtual mode (ON)
AU_exit:
	ret
;
_AutoUpdate	endp

_TEXT	ends

	page
;******************************************************************************
;
;	R_CODE Code Segment
;
;******************************************************************************
;
R_CODE	segment
	assume	cs:R_CODE, ds:DGROUP, es:DGROUP

	page
;******************************************************************************
;	EMM_rEntry - real/virtual mode entry point for EMM function calls
;
;	ENTRY:	real/virtual mode
;		all registers as set by user
;
;	EXIT:	real/virtual mode
;		registers as set by EMM functions
;
;	USED:	none
;
;******************************************************************************
EMM_rEntry	proc	near
;
	cli			; just in case pushf/call far

EMM_rEfix:
	call	EMM_rLink	; call _TEXT segment link
	iret			; return to caller
;
EMM_rEntry	endp


R_CODE	ends

	end

