

page	58,132
;******************************************************************************
	title	EM386LL - 386 routine to emulate 386 LOADALL
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   EM386LL - 386 routine to emulate 386 LOADALL
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
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   06/29/86  0.02	Fixed error handler call. Error handler called
;			only on attempt to set VM bit in EFLAGS
;   06/30/86  0.02	Jmp to error routine (instead of calling)
;   07/03/86  0.03	Removed logic to enable A20 line watch
;   07/05/86  0.04	JumpReal in R_CODE
;   07/06/86  0.04	Changed assume to DGROUP
;   07/08/86  0.04	added DB67 NOPs to avoid B1 errata
;
;******************************************************************************
;
;   Functional Description:
;
;   386 LOADALL is emulated by building a buffer for a
;   386 LOADALL from the client's 386 LOADALL buffer and executing the 386
;   LOADALL.
;
;		check DR6/DR7 for addresses > 1meg ?
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	EM386ll
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
; Desc3Copy
;	Macro for copying a 386 Loadall descriptor cache entry to a
;	386 Loadall descriptor cache entry.
;   ENTRY: DS:ESI pts to client's 386 Loadall descriptor entry
;	   ES:DI pts to our 386 Loadall descriptor entry
;
;   EXIT:  DS:ESI pts to byte after client's 386 ll descr entry (next entry).
;	   ES:DI pts to byte after 386 Loadall descriptor entry (next entry).
;		*** The access rights byte in set to DPL 3 for virtual mode ***
;
;   USED:  EAX
;
Desc3Copy	MACRO
	OP32
	EA32				; EAX = dword from DS:[ESI]
	lodsw				; get access rights

	or	ah,D_DPL3		;* set DPL 3 for virtual mode access

	OP32
	stosw				; store access rights

	OP32
	EA32				; EAX = dword from DS:[ESI]
	lodsw				; 32 bits of Base Addr from 386 entry

	call	MapLinear		; map this linear addr by page tables

	OP32
	stosw				; store Base Addr for 386 entry

	OP32
	EA32				; EAX = dword from DS:[ESI]
	lodsw				; get 32 bits of limit

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
;			L O C A L   D A T A   A R E A
;******************************************************************************

_DATA	 segment
extrn	ELOff:word		; offset of 386 loadall buffer
_DATA	 ends


R_CODE	segment
extrn	JumpReal:far		; continue client in real mode (rrtrap.asm)
R_CODE	ends

_TEXT	segment
extrn	MapLinear:near		; maps linear addresses	 (maplin.asm)
extrn	PortTrap:near		; IOBM trap set function (vminit.asm)
extrn	ErrHndlr:near		; error handler		 (errhndlr.asm)
_TEXT	ends


	page
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************
;
_TEXT	 segment
	ASSUME CS:_TEXT,DS:DGROUP,ES:DGROUP

;******************************************************************************
;	EM386ll - emulate 386 Loadall
;	The basic approach here is to filter the client's loadall buffer into
;	a temporary buffer, setting our values for the parameters we don't want
;	him to change and then executing the 386 loadall from our buffer.
;
;	ENTRY:	Protected Mode
;		BP points to bottom of client's GPfault stack frame
;		ES(in GP frame):EDI points to the client's loadall buffer info
;		 on stack: ESI,EBX,EBP
;
;	EXIT:	via Loadall to virtual mode
;		The 386 Loadall buffer is emulated with the following
;		exceptions:
;		  The VM bit is set in EFLAGS.
;		  The TR, IDT descriptor cache, & TSS descriptor cache are
;			pointed to the VDM entries.
;
;	USED:	Not applicable...  loadall reloads all registers
;
;******************************************************************************
EM386ll proc	near
;
	PUSH_EAX
	PUSH_ECX
	PUSH_EDI

;   Build a descriptor to client's 386 loadall buffer

	mov	bx,GDTD_GSEL		; get GDT data alias
	mov	ds,bx			; DS -> GDT
	mov	bx, [bp.VTFOE+VMTF_ES]	; Get VM ES from GP stack frame
	mov	ax,bx
	shl	bx,4			; BX = low 16 bits of base
	mov	ds:[VM1_GSEL+2],bx	; place in descriptor
	shr	ax, 4			; AH = high 8 bits of base
	mov	ds:[VM1_GSEL+4],ah	; place in descriptor

;   Point DS:ESI to start of client's 386 loadall buffer
	mov	bx,VM1_GSEL
	mov	ds,bx
	OP32
	mov	si,di
	ASSUME	ds:nothing

;   Point ES:EDI to start of our 386 loadall buffer

	mov	ax,VDMD_GSEL
	mov	es,ax
	OP32
	xor	di,di			; clear EDI
	mov	di,ES:[ELOff]		; ES:EDI pts to our 386 loadall buffer
;
	cld

;   Walk through the two buffers in parallel, copying the client's values
;   when appropriate

;
;   CR0 entry
;
	EA32
	OP32
	lodsw				; get client's CR0

;(0.02)	OP32
;(0.02)	test	ax,0001h		;    TEST EAX,80000001h
;(0.02)	dw	8000h			; Q: PG or PE bit set ?
;(0.02)	jz	CR0_OK			;   N: continue
;(0.02)	call	Em386_Err		;   Y: error
;
CR0_OK:
	MOV_ECX_CR0
	OP32
	and	cx,0011h		; and ECX,80000011h
	dw	8000h			; save only PG,ET, & PE bits
	OP32
	or	ax,cx			; or EAX,ECX
	OP32
	stosw				;  store CR0 for 386 buffer
	XOR_ECX_ECX			; clear ECX
;
;  EFLAGS
;
	EA32
	OP32
	lodsw				; get EFLAGS
;
	OP32
	test	ax,0000h
	dw	0002h			;Q: client's VM bit set ?
	jz	EF_OK			;  N: continue
	jmp	Em386_Err		;  Y: error handler - won't return here
EF_OK:
	and	ax,0FFFh		; clear IOPL & NT bits
	OP32
	or	ax,3000h
	dw	0002h			; set VM bit and IOPL = 3
	OP32
	stosw				;  store EFLAGS for 386 buffer
;
;   Copy the client's EIP, EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX, DR6 & DR7
;   register images from his 386 loadall buffer to our 386 loadall buffer
;
	mov	cx,11			; copy 11 register contents
	OP32				; dwords from DS:[ESI] to ES:[EDI]
	EA32
	rep movsw			; copy 11 dwords

	EA32
	nop		; this avoids a B1 errata
;
;   store TR and LDTR
;
	XOR_EAX_EAX			; clear EAX
	mov	ax,TSS_GSEL		; get current TR for VDM's TSS !!!
	OP32
	stosw				;  store TR for 386 buffer
;
	sldt	ax			; use current LDT
	OP32
	stosw				;  store LDTR for 386 buffer
;
;   Copy the client's GS, FS, DS, SS, CS, ES register images from
;   his 386 loadall buffer to our 386 loadall buffer
;
	add	si,offset ll3_GS - offset ll3_TSSR
	mov	cx,6
	OP32				; dwords from DS:[ESI] to ES:[EDI]
	EA32
	rep movsw			; copy 6 dwords

	EA32
	nop		; this avoids a B1 errata
;
;   Copy the current TSS, GDT, IDT, LDT  descriptors from the GDT table to
;   our 386 loadall buffer
;
	push	ds			; save client's buffer selector
	mov	ax,GDTD_GSEL
	mov	ds,ax

	mov	cx, 4
	mov	bx, TSS_GSEL
	push	word ptr LDTD_GSEL
	push	word ptr GDTD_GSEL
	push	word ptr IDTD_GSEL

CopyCur:				; Copy current descriptors
	CurCopy 			; DS:[BX] points to current descriptor
	pop	bx
	loop	CopyCur
	mov	ds, bx			; restore client's buffer selector

					; DS:SI pts to 386 GS cache entry
;
;   Copy the client's GS, FS, DS, SS, CS, ES register cache images from
;   his 386 loadall buffer to our 386 loadall buffer
;
	add	si,offset ll3_GScache - offset ll3_TSScache
	mov	cx,6
CopyCac:				; ES:DI pts to our 386 buf cache entry
	Desc3Copy			;   store his cache in our 386 buffer
	loop	CopyCac 		; DS:SI pts to client's buf cache entry

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
	xor	di,di			    ; XOR EDI,EDI - clear EDI
	mov	di,ES:[ELOff]		    ; ES:EDI pts to loadall buffer
	dw	LODAL386		    ; execute 386 LOADALL

	ASSUME	DS:DGROUP
;
;
EM386ll endp

	page
;******************************************************************************
;	Em386_Err - handle 386 ll emulation error
;		This routine is currently called only on attempts to set the
;	VM bit via loadall.
;******************************************************************************
Em386_Err	proc	near
	push	ax
	push	bx
	mov	ax, PrivErr
	mov	bx, Err3LL
	call	ErrHndlr
	pop	bx
	pop	bx
;
;  continue client in real mode
;
	POP_EDI		; restore used regs
	POP_ECX
	POP_EAX
			; stack back to VmFault exit condition

	jmp	JumpReal	; "jump" to real mode and continue interrupted
				;    code.

Em386_Err	endp
;
_TEXT	 ends
	end
