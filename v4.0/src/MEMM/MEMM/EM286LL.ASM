

page	58,132
;******************************************************************************
	title	EM286LL - 386 routine to emulate 286 LOADALL
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   EMM286LL - 286 loadall emulation routine
;
;   Version:  0.04
;
;   Date:     April 11,1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   04/16/86  Original
;   05/12/86  A	Cleanup and segment reorganization
;   06/18/86  0.01	Moved EL_Off before buffer
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   06/28/86  0.02	Modified CR0 logic & Edi for LL3 buffer
;   07/03/86  0.03	Removed logic for enabling A20 watch
;   07/06/86  0.04	Change assume to DGROUP
;
;******************************************************************************
;
;   Functional Description:
;
;   286 LOADALL is emulated by building a buffer for a
;   386 LOADALL from the 286 LOADALL buffer (@80:0) and executing the 386
;   LOADALL.
;
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	EM286ll
	public	ELOff
;
	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
	include loadall.inc
	include VDMseg.inc
	include desc.inc
	include VDMsel.inc
	include instr386.inc
	include vm386.inc
	include	oemdep.inc

FALSE	equ	0
TRUE	equ	not FALSE

;
; DescCopy
;	Macro for copying a 286 Loadall descriptor cache entry to a
;	386 Loadall descriptor cache entry.
;   ENTRY: DS:SI pts to 286 Loadall descriptor entry
;	   ES:DI pts to 386 Loadall descriptor entry
;
;   EXIT:  DS:SI unchanged.
;	   ES:DI pts to byte after 386 Loadall descriptor entry (next entry).
;		*** The access rights byte in set to DPL 3 for virtual mode ***
;
;   USED:  EAX
;
DescCopy	MACRO
	XOR_EAX_EAX			; clear EAX
	mov	ax,word ptr [si.dc2_BASEhi]	; AL = junk, AH = Access rights
	or	ah,D_DPL3		;* set DPL 3 for virtual mode access
	OP32
	stosw				; store: junk->AR1,AR->AR2,0->AR3 & AR4
	OP32
	mov	ax,[si] 		; 24 bits of Base Addr from 286 entry
	OP32
	and	ax,0FFFFh		; AND EAX,00FFFFFFh
	dw	000FFh			; clear high byte of base addr
	call	MapLinear		; Map address according to page tables
	OP32
	stosw				; store Base Addr for 386 entry
	XOR_EAX_EAX			; clear EAX
	mov	ax,[si.dc2_LIMIT]	; get low 16 bits of limit
	OP32
	stosw				; store 32 bit LIMIT into 386 entry
	ENDM
;
; CurCopy
;	Macro for copying a current descriptor cache entry to a
;	386 Loadall descriptor cache entry.
;   ENTRY: DS:BX pts to current descriptor
;	   ES:DI pts to 386 Loadall descriptor entry
;
;   EXIT:  DS:BX unchanged.
;	   ES:DI pts to byte after 386 Loadall descriptor entry (next entry).
;		*** The access rights byte in set to DPL 3 for virtual mode ***
;
;   USED:  EAX
;
CurCopy 	MACRO
	OP32
	mov	ax,[bx+4]		; get AR info
	or	ah,D_DPL3		;* set DPL 3 for virtual mode access
	OP32
	stosw				; store into cache entry
	mov	ah,[bx+7]		; AX = Base[31..16]
	OP32
	shl	ax,16			; high word of EAX = Base[31..16]
	mov	ax,[bx+2]		; EAX = Base[31..0]
	OP32
	stosw
	mov	al,[bx+6]		; LIMIT[19..16] in low bits of AL
	and	ax,0Fh
	OP32
	shl	ax,16			; high word of EAX = LIMIT[31..16]
					; NOTE: VDM does not use page
					;  granularity for limit field !!
	mov	ax,[bx] 		; EAX = LIMIT[31..0]
	OP32
	stosw				; store into cache for 386 buffer
	ENDM
;******************************************************************************
;			E X T E R N A L    R E F E R E N C E S
;******************************************************************************
;
L286BUFF	segment at 80h
;
;  Source 286 LoadAll buffer
;
SLBuff	LoadAllBuf286	<>			; 286 loadall buffer

L286BUFF	ends

_TEXT	segment

	extrn	MapLinear:near		; map linear address
	extrn	PortTrap:near		; IOBM trap set function (VMINIT)

_TEXT	ends

;
;******************************************************************************
;			L O C A L   D A T A   A R E A
;******************************************************************************

_DATA	 segment

ELOff	dw		offset ELbuff	; offset of 386 loadall buffer
ELbuff	LoadAllBuf386	<>		; 386 loadall buffer
	dd		0		; filler - allow dword align

;(0.03)extrn	A20watch:byte			; Loadall/KBD A20 disable flag

_DATA	 ends

	page
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************
;
_TEXT	 segment
	ASSUME CS:_TEXT,DS:DGROUP,ES:DGROUP

;******************************************************************************
;	EM286ll - emulate 286 Loadall
;
;	ENTRY:	Protected Mode
;		physical address 80:0 holds 286 loadall buffer info
;
;	EXIT:	via Loadall to virtual mode
;		The 286 Loadall buffer is emulated with the following
;		exceptions:
;		  The VM bit is set in EFLAGS.
;		  The TR, IDT descriptor cache, & TSS descriptor cache are
;			pointed to the VDM entries.
;
;	USED:
;
;******************************************************************************
EM286ll proc	near
	mov	bx,GDTD_GSEL		; get GDT data alias
	mov	ds,bx			; DS -> GDT
	mov	bx,800h 		; BX = VM CS (segment form)
	mov	ds:[VM1_GSEL+2],bx	; place in descriptor
	xor	bx,bx
	mov	ds:[VM1_GSEL+4],bh	; place in descriptor
	mov	bx,VM1_GSEL
	mov	ds,bx			; DS:0 points to 286 loadall buffer
	ASSUME	DS:L286BUFF
;
	mov	ax,VDMD_GSEL
	mov	es,ax
	mov	di,ES:[ELOff]		; ES:DI pts to 386 loadall buffer
;
	cld
;
	MOV_EAX_CR0			; mov EAX,CR0
	and	ax,0FFF1h		;clear current TS,EM, & MP bits
	mov	cx,[SLBuff.ll2_MSW]	; CX = 286 ll_buff MSW
	and	cx,000Eh		;retain 286 TS,EM, & MP bits
	or	ax,cx			; set client's TS,EM, & MP bits
	OP32
	stosw				;  store CR0 for 386 buffer
;
	OP32
	mov	ax,0000h
	dw	0002h			; VM bit on
	mov	ax,[SLBuff.ll2_FLAGS]	; get low word of flags
	or	ax,3000h		; set IOPL to 3
	OP32
	stosw				;  store EFLAGS for 386 buffer
;
	XOR_EAX_EAX			; clear EAX
	mov	ax,[SLBuff.ll2_IP]	; get 286 IP - high word of EAX clear
	OP32
	stosw				;  store EIP for 386 buffer
;
;   Copy the client's EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX
;   register images from his 386 loadall buffer to our 386 loadall buffer
;
	mov	si,offset ll2_DI	; DS:SI pts to DI in 286 buffer
	mov	cx,8
CopyGen:				; Copy General Purpose Registers
	lodsw				; EAX = reg image from client's buffer
	OP32
	stosw				;  store it in our 386 buffer
	loop	CopyGen

;
;   386 debug registers
;
	MOV_EAX_DR6
	OP32
	stosw				;  store DR6 in our 386 buffer

	MOV_EAX_DR7
	OP32
	stosw				;  store DR7 in our 386 buffer
;
	XOR_EAX_EAX			; clear EAX
;
	mov	ax,TSS_GSEL		; get current TR for VDM's TSS !!!
	OP32
	stosw				;  store TR for 386 buffer
;
	mov	si,offset ll2_LDT	; DS:SI pts to LDT in 286 buffer
	lodsw				; get LDT entry from 286 buffer
	OP32
	stosw				;  store LDT for 386 buffer

	OP32
	stosw				;  store junk into GS for 386 buffer

	OP32
	stosw				;  store junk into FS for 386 buffer

;
;   Copy the client's DS, SS, CS, ES register images from his 286 loadall
;   buffer to our 386 loadall buffer
;
	mov	cx,4
CopySeg:				; Copy Segment Registers
	lodsw				; get seg image from client's buffer
	OP32
	stosw				;  store it in our 386 buffer
	loop	CopySeg

					; ES:DI pts to 386 TSS cache entry
;
;   Copy the current TSS, IDT, & GDT descriptors from the GDT table to
;   our 386 loadall buffer
;
	push	ds			; save client's buffer selector
	mov	ax,GDTD_GSEL
	mov	ds,ax

	mov	cx, 3
	mov	bx, TSS_GSEL
	push	word ptr GDTD_GSEL
	push	word ptr IDTD_GSEL

CopyCur:				; Copy current descriptors
	CurCopy 			; DS:[BX] points to current descriptor
	pop	bx
	loop	CopyCur
	mov	ds, bx			; restore client's buffer selector

;
					; ES:DI pts to 386 LDT cache entry
	mov	si,offset ll2_LDTcache	; DS:SI pts to 286 LDT cache entry
	DescCopy			;   store LDT cache for 386 buffer
;
	XOR_EAX_EAX			; clear EAX- use 0 for GS/FS caches

	OP32
	stosw				;   store GS cache for 386 buffer
	OP32
	stosw
	OP32
	stosw
;
	OP32
	stosw				;   store FS cache for 386 buffer
	OP32
	stosw
	OP32
	stosw
;
;   Copy the client's DS, SS, CS, ES register cache images from
;   his 286 loadall buffer to our 386 loadall buffer
;
	mov	si,offset ll2_DScache	; DS:SI pts to 286 DS cache entry
	mov	cx,4
CopyCac:				; ES:DI pts to our 386 ll cache entry
	DescCopy			;   store his cache in our 386 buffer
	sub	si,06h			; DS:SI pts to client's cache entry
	loop	CopyCac
;
;   386 Loadall buffer complete
;

;(0.03)	push	es
;(0.03)	mov	ax, TSSD_GSEL		    ; Point ES to TSS for PortTrap
;(0.03)	mov	es, ax
;(0.03)	mov	bh, 80h 		    ; set every 1k
;(0.03)	mov	ax, KbdDataPort
;(0.03)	call	PortTrap		    ; set traps on keyboard ports
;(0.03)	mov	ax, KbdCmdPort		    ; in case client
;(0.03)	call	PortTrap		    ; tries to disable A20
;(0.03)	pop	es
;(0.03)	mov	es:[A20watch], YesLLdone    ; set A20 watch flag

	HwTabLock			    ; Hardware lock the high ram

	OP32
	xor	di,di			; clear EDI
	mov	di,ES:[ELOff]		; ES:EDI pts to loadall buffer
	dw	LODAL386		; execute 386 LOADALL

	ASSUME	DS:DGROUP
;
EM286ll endp

_TEXT	 ends
	end
