

page	58,132
;******************************************************************************
	title	MOVEB - move block emulator
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   MOVEB - move block code for MEMM
;
;   Version:  0.05
;
;   Date:     05/22/86
;
;   Author:
;
;*************************************************************************
;	CHANGE LOG:
; DATE	    VERSION	Description
;---------  --------	--------------------------------------------------
; 05/15/86		Check source/target selector using verr,verw
;			and add parity handler
; 06/09/86		Added MapLinear call
; 06/17/86		Added code to detect and "handle" writes to
;			diag byte location.
; 06/28/86  0.02	Name changed from MEMM386 to MEMM
; 07/06/86  0.04	DiagByte moved to _DATA
; 07/06/86  0.04	changed assume to DGROUP
; 07/10/86  0.05	Added Real Mode patch code
;*************************************************************************
.386p


;****************************************
;	P U B L I C S
;****************************************
	public	Move_Block
	public	MB_Exit
	public	MB_Stat
	public	i15_Entry
	public	MB_Flag
	public	i15_Old

	page
;****************************************
;	D E F I N E S
;****************************************
	include vdmseg.inc
	include vdmsel.inc
	include desc.inc
	include instr386.inc
	include oemdep.inc
	include vm386.inc

TRUE	equ	0FFh
FALSE	equ	00h

D_G_BIT 	equ	80h		; granularity bit in high status bits

FLAGS_CY	equ	0001h
FLAGS_ZF	equ	0040h
FLAGS_IF	equ	0200h

	; 386 data descriptor format
DATA_DESC_386	struc
DD386_Limit_lo	dw	?		; low word of seg limit
DD386_Base_lo	dw	?		; low 24 bits of seg base addr
		db	?		;
DD386_Access	db	?		; access byte
DD386_L_Stat	db	?		; high 4 bits of seg limit
					; and futher status
DD386_Base_hi	db	?		; high 8 bits of seg base addr
DATA_DESC_386	ends

	; format of move block descriptor table passed on entry
MB_GDT	struc
MG_dummy	dd 2 dup (?)		; dummy descriptor entry
MG_GDT		dd 2 dup (?)		; GDT entry
MG_Source	dd 2 dup (?)		; source segment entry
MG_Target	dd 2 dup (?)		; target segment entry
MB_GDT	ends

;************************************************************
;	DescrMap - map address in descriptor
;	ENTRY: ES:DI = descriptor
;	EXIT:  descriptor's address is mapped by MapLinear
;	USED:	EAX
;************************************************************
DescrMap	MACRO
	mov	ah,ES:[di.DD386_Base_hi]	; ah = high 8 bits of address
	mov	al,byte ptr ES:[di.DD386_Base_lo+2] ; al = bits 16-23 of addr
	OP32
	shl	ax,16				; high addr word into high EAX
	mov	ax,ES:[di.DD386_Base_lo]	; EAX = 32 bit address
	call	MapLinear			; map linear address
	mov	ES:[di.DD386_Base_lo],ax	; store low word of address
	OP32
	shr	ax,16				; ax = high word of address
	mov	byte ptr ES:[di.DD386_Base_lo+2],al	;   store
	mov	ES:[di.DD386_Base_hi],ah		;  high word of address
	ENDM

;*******************************************************************************
;	 E X T E R N A L   R E F E R E N C E S
;*******************************************************************************
_TEXT	segment

	extrn	MapLinear:near
	extrn	Set_Par_Vect:near
	extrn	Rest_Par_Vect:near
	extrn	togl_A20:near
	extrn	get_a20_state:near

_TEXT	ends

_DATA	segment

	extrn	Active_Status:byte	; non-zero if in VM

_DATA	ends


	page
;*******************************************************************************
;	D A T A   S E G M E N T
;*******************************************************************************
_DATA	segment

MB_Stat 	db	0		; move block status
Toggle_st	db	0

_DATA	ends

	page
;****************************************
;	C O D E    S E G M E N T   _TEXT
;****************************************
_TEXT	segment
	assume	cs:_TEXT, ds:DGROUP, es:DGROUP

	page
;*************************************************************************
;***	Move_Block - Mimics the 286 ROM function Move Block ( int15h AH=87h ).
;		    Move a block of data (copy it) to/from anywhere in
;		24bits of linear address space.  Normally used to move
;		data to/from extended memory (past 1M) since real mode
;		can only address the first meg of memory.
;
;
;	ENTRY	PROTECTED MODE
;		AH = 87h
;		CX = # of words to move ( max 8000h ).
;		ES:SI = ptr to a descriptor table containing segment descriptors
;			for the source and target memory of the transfer.
;
;	EXIT	PROTECTED MODE
;		AH = 00 if OK
;		     01 if parity error 	*** currently not checked ***
;		     02 if exception error
;		     03 if gate address bit A20 fails.
;		if no error:
;			ZF and NC in client's flags
;		if error:
;			NZ and CY in client's flags
;
;
;	USES	AX, FLAGS -> CLD.
;
;		Descriptor Table Format
;	ES:SI --->	+-------------------------------+
;			|	Dummy descriptor	|
;			+-------------------------------+
;			|	GDT descriptor		|
;			+-------------------------------+
;			| Source segment descriptor	|
;			+-------------------------------+
;			| Target segment descriptor	|
;			+-------------------------------+
;
;*************************************************************************
Move_Block	proc	near
;
	push	ds
	push	es
	PUSH_EAX
	push	cx
	push	si
	push	di
;
	cld
;
	mov	ax,VDMD_GSEL		; get data selector
	mov	ds,ax			; DS = DGROUP
	mov	[MB_Stat],0		; init status of move block to OK.
;
; check word count field
;
	cmp	cx,8000h		;Q: word count too high
	jbe	MB_chk_length		;  N: check length of segments
	jmp	MB_Excp_Error		;  Y: report exception error

;
; check source and target descriptor's lengths against transfer count
;   only need check low word since caller set up a 286 descriptor
;
MB_chk_length:
	mov	ax,cx
	shl	ax,1			; AX = # of bytes to transfer(0=>8000h)
	dec	ax			; convert to seg limit type value
					;  ( 0FFFFh => 64K )
	cmp	ax,ES:[si.MG_Source.DD386_Limit_lo] ;Q: source seg limit low ?
	jbe	MB_chk_tarl		;	       N: chk target length
	jmp	MB_Excp_Error		;	       Y: return excp error.

MB_chk_tarl:
	cmp	ax,ES:[si.MG_Target.DD386_Limit_lo] ;Q: tar seg too small ?
	jbe	MB_setup		;	       N: seg limits OK.
	jmp	MB_Excp_Error		;	       Y: return excp error
;
; source and target descriptors OK, set up scratch selector descriptors
;

MB_setup:
	push	cx		; save copy count

	push	es
	pop	ds		; set DS:SI to input descriptor table
	mov	ax,GDTD_GSEL
	mov	es,ax		; ES:0 pts to GDT
	mov	di,MBSRC_GSEL	; ES:DI pts to source work descriptor in GDT
	push	si		; save input descr table ptr
	lea	si,[si.MG_Source]; DS:SI pts to input source descr
	mov	cx,4
	rep movsw		; set move block source work descr
	pop	si		; restore input descr table ptr
	mov	di,MBSRC_GSEL	; ES:DI pts to source work descriptor in GDT
	call	MB_Map_Src
	DescrMap		; fixup this descriptor's linear address

	mov	di,MBTAR_GSEL	; ES:DI pts to target work descr in GDT
	push	si		; save input descr table ptr
	lea	si,[si.MG_Target] ; DS:SI pts to input target descr
	mov	cx,4
	rep movsw		; set move blk target work descr
	pop	si		; restore input descr table ptr
	mov	di,MBTAR_GSEL	; ES:DI pts to target work descr in GDT
	call	MB_Map_Dest
	DescrMap	; fixup this descriptor's linear address

;
; install NMI/parity exception handler
;
	call	Set_Par_Vect	       ; restore the parity interrupt handler

;
; copy the data
;

;
; check if a20 line is to be enabled or not
;
	call	get_a20_state
	jnz	a20_is_enb
;
; a20 line is currently disabled. we need to enable the a20
;
	call	togl_a20
	mov	[toggle_st],0ffh
a20_is_enb:
;
	pop	cx		; restore copy count

	xor	di,di
	xor	si,si
	mov	ax,MBSRC_GSEL
	verr	ax		;Q: source selector valid ?
	jnz	MB_Excp_Error	;  N: return exception error
	mov	ds,ax		;  Y: DS:SI pts to source segment
	mov	ax,MBTAR_GSEL
	verw	ax		;Q: target selector valid ?
	jnz	MB_Excp_Error	;  N: return exception error
	mov	es,ax		;  Y: ES:DI pts to target segment
	jmp	MB_move_block	;     and go ahead
;
;   Error reporting
;
MB_Excp_Error:
	mov	ax,VDMD_GSEL		; get data selector
	mov	ds,ax			; DS = DGROUP
	mov	[MB_Stat],2
	jmp	MB_Exit
;
; move the block
;
MB_move_block:

	call	MB_Start

;
;   MOVE the BLOCK - dwords
;
	test	cx,01h			;Q: move an odd # of words?
	jz	MB_moved		;  N: move dwords
	movsw				;  Y: move the first one => dwords now
MB_moved:
	shr	cx,1			; move CX dwords...
	OP32
	rep movsw			; REP MOVSD

	mov	ax,VDMD_GSEL		; get data selector
	mov	ds,ax			; DS = DGROUP

; restore a20 state to what it was before this routine
;
	test	[toggle_st],0ffh	; do we need to toggle the a20 back?
	jz	a20_restored		; N: skip toggling
	call	togl_a20		; Y: else toggle the A20 line
a20_restored:
	mov	[toggle_st],0		; clear this flag

	jmp	MB_Exit
Move_Block	endp

;*************************************************************************
; This is special JUMP entry point for parity handler
;
MB_Exit proc	near
;
;  reset NMI handler
;

	call	Rest_Par_Vect		; restore the parity interrupt handler

;
;
MB_leave:
	pop	di
	pop	si
	pop	cx
	POP_EAX
	mov	ah,[MB_Stat]
;
; set client's flags to no error
;
	or	[bp.VTFOE+VMTF_EFLAGS],FLAGS_ZF 	; ZF
	and	[bp.VTFOE+VMTF_EFLAGS],NOT FLAGS_CY	; NC

	or	ah,ah		;Q: error occured ?
	jz	MB_ret		;  N: continue
				;  Y: set error in client's flags
	and	[bp.VTFOE+VMTF_EFLAGS],NOT FLAGS_ZF	; NZ
	or	[bp.VTFOE+VMTF_EFLAGS],FLAGS_CY 	; CY
;
MB_ret:
	pop	es
	pop	ds
	ret
;
MB_Exit endp

_TEXT	ends

	page
;****************************************
;	C O D E    S E G M E N T   R_CODE
;****************************************
R_CODE	segment
	assume	cs:R_CODE, ds:DGROUP, es:DGROUP

;*************************************************************************
;		local	data
;*************************************************************************
I15_Old 	dd	0		; old Int 15h handler
MB_Flag 	db	0		; non-zero => do move block in ring 0
Exit_Flags	dw	0		; flags for int15 exit
;
ext_mem_size	dw	0		; we are using new int 15 allocation
					; scheme now whereby we have to lower
					; the size reported by int 15 function
					; 88h to grab some memory for ourself
					; The extended memory allocate routine
					; in allocmem.asm fills in the approp.
					; size here.

	page
;*************************************************************************
;	i15_Entry - real/virtual mode patch code for int 15h
;
;	    This function patches the real mode IDT for MEMM.	If it is
;	entered for a move block, this code sets a flag to tell MEMM to
;	pick up the move block, then i15_Entry lets MEMM do it.  Otherwise
;	MEMM jumps to the previous code. For function 88h it reports the
;	the new size of extended memory.
;
;	ENTRY	Real/Virtual mode
;		see int15h entry parameters in ROM spec
;
;	EXIT
;
;	87h:	Real/Virtual mode
;		AH = 00 if OK
;		     01 if parity error 	*** currently not checked ***
;		     02 if exception error
;		     03 if gate address bit A20 fails.
;		if no error:
;			ZF and NC in client's flags
;		if error:
;			NZ and CY in client's flags
;
;	88h:	Real/Virtual mode
;		AX = Size of extended memory in KB
;
;
;	USES	AX, FLAGS -> CLD.
;
; NOTE:**ISP This routine was modified to implement the new INT15 allocation
;	     scheme whereby MEMM by lowering the size of extended memory could
;	     grab the difference between the old size and the new size reported
;	     for itself.
;*************************************************************************
i15_flags	equ	6
i15_cs		equ	4
i15_ip		equ	2
i15_bp		equ	0

i15_Entry	proc	near
;
	cli				;  in case of pushf/call far
	pushf				; save entry flags
;
;  Check to see if it is the extended memory size request
;
	cmp	ah,88h			;Q: extended memory size request?
	jne	chk_blk_move		;  N: go to check for move block call
; 	
;  Implement int15 allocation scheme by reporting a lowered value of extended
;  memory.
	popf
	mov	ax,cs:[ext_mem_size]	; report new extended memory size
	iret				;
;
;  Checking for move block call
;
chk_blk_move:
	cmp	ah,87h			;Q: move block call ?
	jne	i15_jmpf		;  N: jmp to old code
	push	ds
	push	seg DGROUP		;
	pop	ds			;  DS -> DOSGROUP
	cmp	[Active_Status],0	;  Y: Q: in Virtual mode ?
	pop	ds			; reset DS
	je	i15_jmpf		;	N: jmp to old code
					;	Y: VM move block
	mov	CS:[MB_Flag],TRUE	;		let MEMM have it ...
	popf				; retrieve entry flags (IF cleared!!!)
	int	15h			;  give it to MEMM
					; MEMM will reset MB_Flag
	cli				; just in case
	push	bp			; save bp
	mov	bp,sp
	push	ax			; save ax
	pushf
	pop	ax			; AX = exit flags
	xchg	ax,[bp+i15_Flags]	; AX = entry flag, exit flags on stack
	and	ax,FLAGS_IF		;  save only IF bit of entry
	or	[bp+i15_Flags],ax	; set IF state in flags on stack
	pop	ax
	pop	bp
	iret				; and leave
;
;  far jump to old code
;
i15_jmpf:
	popf				; retrieve entry flags
	jmp	CS:[i15_Old]
;
i15_Entry	endp

R_CODE	ends


LAST	SEGMENT
;
    ASSUME  CS:LAST
;
public	set_ext
;
;*************************************************************************
;	set_ext  - to fill up size of extended memory reported by int 15
;
;	This function fills up the size of extended memory reported by the
;	int 15 real/virtual mode patch.
;
;	ENTRY	Real Mode
;		bx=size of extended memory in Kb
;
;	EXIT	None.  R_CODE:ext_mem_size filled.
;
;	USES	None.
;
;	WRITTEN 7/25/88 ISP
;
;*************************************************************************

set_ext     proc    near
;
    ASSUME  DS:NOTHING,ES:NOTHING

    push    ax
    push    ds
;
    mov     ax,seg R_CODE
    mov     ds,ax
;
    ASSUME  DS:R_CODE
;
    mov     [ext_mem_size],bx
;
    pop     ds
    pop     ax
;
    ASSUME  DS:NOTHING
;
    ret
;
set_ext     endp
;

LAST ENDS
	end
