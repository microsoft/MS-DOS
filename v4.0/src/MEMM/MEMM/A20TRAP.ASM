

page	58,132
;******************************************************************************
	title	A20TRAP.ASM - I/O trap handlers for watching the A20 line.
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   A20TRAP.ASM - I/O trap handlers for watching the A20 line.
;
;   Version:  0.03
;
;   Date:     June 1, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   07/03/86  0.03	From ChkDisA20 routine in VMINST.
;
;******************************************************************************
;
;   Functional Description:
;	This module contains the I/O trap handlers for the A20 line watching
;   logic.
;
;
;   COMMENTS: This module displays weaknesses due to carryover from previous
;	      sources.	A lot of the code here can be shifted to the LAST
;	      segment.	There is a duplication of routines for getting the a20
;	      state. (ISP)
;******************************************************************************
.lfcond 				; list false conditionals
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	A20_Handler
	public	A20_Trap_Init
	public	EnableA20
	public	DisableA20
	public	togl_A20
	public	get_a20_state
	public	estb_a20_state
	public	get_init_a20_state


;
;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************
	include VDMseg.inc
	include VDMsel.inc
;
_DATA	segment
;	(none)
_DATA	ends

_TEXT	segment

	extrn	PortTrap:near

_TEXT	ends
	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
FALSE	equ	0
TRUE	equ	not FALSE

YesLLdone	equ	1
KbdDataEnb	equ	2

A20CmdBit	equ	02h		; high is enabled
A20DsbCmd	equ	0DDh
A20EnbCmd	equ	0DFh

KbdCmdPort	equ	64h		; 8042 cmd port
KbdWrtData	equ	0D1h		; Enable write to data port
KbdDataPort	equ	60h		; 8042 data port
KbdStatusPort	equ	64h		; 8042 cmd port
KbdBufFull	equ	2		; Buffer bull(data not received) status

; equates for the state_a20 flag

A20_ON		equ	A20CmdBit	;
A20_OFF 	equ	0		;
;
; equate for the bit which will toggle the state of
;
WRAP_BIT	equ	00100000h	; page table entry bit
;
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************
;

;
;  _DATA segment
;
_DATA	segment

KbdComd db	0	; last CMD written to port 64h
state_a20   db	0	; A20 line state: A20_ON is on, A20_OFF is off

_DATA	ends

;
	page
;------------------------------------------------------------------------------
_TEXT	segment
	assume	cs:_TEXT, ds:DGROUP, es:DGROUP, ss:DGROUP
;
;******************************************************************************
;			L O C A L   D A T A   A R E A
;******************************************************************************
;

;******************************************************************************
;   A20_Handler - I/O trap handler for Address line 20 modification
;
;   ENTRY: Protected Mode Ring 0
;		AL = byte to output to port.
;		BX == 2 * port address(either KbdDataPort or KbdCmdPort)
;		DX == 0  => Emulate input
;		   <> 0  => Emulate output
;		DS = DGROUP
;		SS:BP = points to stack frame on entry to GP fault handler
;
;   EXIT:
;		CLC => I/O emulated.
;		STC => I/O NOT emulated.
;
;   USED:  BX,Flags
;   STACK:
;------------------------------------------------------------------------------
A20_Handler	proc	near
	or	dx,dx			;Q: Output ?
	jnz	A20_Write		;  Y: check for write to output port
	stc				;  N: don't bother to emulate it
	ret
A20_Write:
	cmp	bx,KbdDataPort*2	;Q: Keyboard data port?
	jne	Kbd_C_Handler		;  N: Go handle Kybd Command output
					;  Y: Go handle Kybd Data output

;  keyboard data write
Kbd_D_Dwrite:
	cmp	[KbdComd],KbdWrtData		;Q: write to output port?
	mov	[KbdComd],0			; data port write => no CMD
	je	Kbd_D_out			;  Y: filter client's data
	stc					;  N: don't bother to emulate it
	ret
;
;   here if Output Port write
;
Kbd_D_out:
	push	ax				; Set A20 cmd bit
	call	check_a20_togl			; do we need to toggle the
						; the a20 state
	jz	skip_togl			; N: Skip routine to toggle
	call	togl_a20
skip_togl:
	or	al, A20CmdBit			;   to leave A20 enabled
	out	KbdDataPort,al			; "emulate" it
	pop	ax				; restore client's byte
	clc					;  emulated
	ret

;Output to Keyboard command port
Kbd_C_Handler:
;
	mov	[KbdComd],al		;  Y: save new port 64 byte
	stc				; don't bother to emulate it
	ret
;
A20_Handler	endp


;******************************************************************************
;   A20_Trap_Init - turn on I/O bit map trapping for A20 line watching
;
;   ENTRY: DS -> DGROUP   - real,virtual, or protected mode
;	   ES -> TSS segment
;	   IOTrap_Tab already has address of A20_Handler for KbdDataPort and
;			    KbdCmdPort
;
;   EXIT: IO_BitMap Updated to trap ports used to change A20 line
;
;   USED:  AX,Flags
;   STACK:
;------------------------------------------------------------------------------
A20_Trap_Init  proc    near
;
;  reset flag
;
	mov	[KbdComd],0
;
;   Set IOBM traps to look for client's disabling of the A20 line
;
	mov	bh, 80h 		    ; set every 1k
	mov	ax, KbdDataPort
	call	PortTrap		    ; set traps on keyboard ports
	mov	ax, KbdCmdPort		    ; in case client
	call	PortTrap		    ; tries to disable A20
	ret
;
A20_Trap_Init  endp
;
;*****************************************************************************;
;***	EnableA20 - switch 20th address line				      ;
;									      ;
;	This routine is used to enable the 20th address line in 	      ;
;	the system.							      ;
;									      ;
;	In general when in real mode we want the A20 line disabled,	      ;
;	when in protected mode enabled. However if there is no high	      ;
;	memory installed we can optimise out unnecessary switching	      ;
;	of the A20 line. Unfortunately the PC/AT ROM does not allow	      ;
;	us to completely decouple mode switching the 286 from gating	      ;
;	the A20 line.							      ;
;									      ;
;	In real mode we would want A20 enabled if we need to access	      ;
;	high memory, for example in a device driver. We want it 	      ;
;	disabled while running arbitrary applications because they	      ;
;	may rely on the 1 meg address wrap feature which having the	      ;
;	A20 line off provides.						      ;
;									      ;
;	This code is largely duplicated from the PC/AT ROM BIOS.	      ;
;	See Module "BIOS1" on page 5-155 of the PC/AT tech ref. 	      ;
;									      ;
;	ENTRY	none		;ds = DGROUP				      ;
;	EXIT	A20 line enabled					      ;
;	USES	ax, flags modified					      ;
;									      ;
;	WARNING:							      ;
;									      ;
;	The performance characteristics of these routines		      ;
;	are not well understood. There may be worst case		      ;
;	scenarios where the routine could take a relatively		      ;
;	long time to complete.						      ;
;									      ;
;	TO BE ADDED:							      ;
;									      ;
;	8042 error handling						      ;
;*****************************************************************************;
EnableA20 proc near
	mov	ah,0dfh 		; code for enable
	jmp	a20common		; jump to common code

EnableA20 endp

;*****************************************************************************;
;***	DisableA20 - switch 20th address line				      ;
;									      ;
;	This routine is used to disable the 20th address line in	      ;
;	the system.							      ;
;									      ;
;	ENTRY	none		;ds = DATA				      ;
;	EXIT	A20 line disabled					      ;
;		[state_a20] = 0 					      ;
;	USES	ax, flags modified					      ;
;*****************************************************************************;

DisableA20 proc near
	mov	ah,0ddh 		; code for disable
	jmp	a20common		; jump to common code

DisableA20 endp


a20common proc near

;	This is entered via a jmp from one of the two procedural
;	entry points above.

	call	empty_8042		; ensure 8042 input buffer empty
	jnz	com1			; 8042 error return
	mov	al,0d1h 		; 8042 cmd to write output port
	out	KbdCmdPort,al		; send cmd to 8042
	call	empty_8042		; wait for 8042 to accept cmd
	jnz	com1			; 8042 error return
	mov	al,ah			; 8042 port data
	out	KbdDataPort,al		; output port data to 8042
	call	empty_8042
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; AST P/386 needs the delay for their
; A20 switch settle. If not, it won't work !
; PC (10/03/88)
;
	push	cx
	mov	cx, 0100h
ASTloop:
	loop	ASTloop
	pop	cx
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

com1:
	ret
a20common endp

;*****************************************************************************;
;***	empty_8042 - wait for 8042 input buffer to drain		      ;
;									      ;
;	ENTRY	none							      ;
;	EXIT	al=0, z=0 => 8042 input buffer empty			      ;
;		al=2, z=1 => timeout, input buffer full 		      ;
;	USES	none							      ;
;*****************************************************************************;
empty_8042 proc near
	push	cx			; save it
	sub	cx,cx			; cx = 0, timeout loop counter
emp1:
	in	al,KbdStatusPort	; read 8042 status port
	and	al,KbdBufFull		   ; test buffer full bit
	loopnz	emp1
	pop	cx
	ret
empty_8042 endp

;*****************************************************************************;
;***	check_a20_togl - check if a20 state emulated needs to be toggled      ;
;									      ;
;	ENTRY	[state_a20] = A20 emulated state			      ;
;		al	    = byte to output to kbd data port		      ;
;	EXIT	Z set if A20 not to be toggled				      ;
;		   clear if A20 to be toggled				      ;
;	USES	Flags							      ;
;									      ;
;*****************************************************************************;
check_a20_togl	proc	near
;
	push	ax
	and	al,A20CmdBit		; make all other bits 0
	xor	al,[state_a20]		; does the state of the a20 bit match
					; Y: then Z is set
					; N: then Z is not set
	pop	ax
	ret
;
check_a20_togl	endp


;*****************************************************************************;
;***	get_a20_state	- see if virtualised a20 is enabled or not	      ;
;									      ;
;	ENTRY	[state_a20] = A20 emulated state			      ;
;									      ;
;	EXIT	ZF set if A20 disabled					      ;
;		ZF not set if A20 enabled				      ;
;									      ;
;	USES	Flags							      ;
;*****************************************************************************;

get_a20_state	proc	near
;
	test	[state_a20], A20_ON
	ret
get_a20_state	endp


;*****************************************************************************;
;***	togl_A20 - toggle emulated A20 state.				      ;
;									      ;
;	ENTRY	[state_a20] = A20 emulated state			      ;
;		PROTECTED MODE ONLY					      ;
;		DS:DGROUP						      ;
;									      ;
;	EXIT	[state_a20] toggled					      ;
;		page table entries for the 1M --> 1M + 64k area toggled       ;
;									      ;
;	USES	Flags							      ;
;									      ;
;									      ;
;*****************************************************************************;
togl_A20    proc    near
;
	push	es
	push	di
	push	cx
	push	eax
;
; get addressability to page table
;
	push	PAGET_GSEL
	pop	es
;
; and offset into entries for the 64k block at 1M
;
	mov	di,100h*4	; 1024k/4k = 256 entries, each 4 bytes long
	mov	cx,10h		; 64k/4k = 16 entries
	cld
;
; for all the entries flip the bit which will make the entries either wrap
; around for 1M-1M+64k to either 1M-1M+64k or 0-64k. This bit is the 1M bit
; in the base address.
;
w64_loop:
	xor	dword ptr es:[di], WRAP_BIT
	add	di,4
	loop	w64_loop
;
; flush the tlb
;
	mov	eax,cr3
	mov	cr3,eax
;
; toggle a20 state
;
	xor	[state_a20],A20_ON
;
; restore the registers
;
	pop	eax
	pop	cx
	pop	di
	pop	es
	ret
;
togl_A20    endp



_TEXT	ends				; end of segment

LAST   segment

	assume	cs:LAST, ds:DGROUP, es:DGROUP, ss:DGROUP


;******************************************************************************
;***estb_a20_state							      ;
;									      ;
; since we are fixing the a20 state to be always enabled we need to implement ;
; a logical a20 state independent of the physical one.	this routine inits    ;
; this state.  we do this comparing 3 double words at 0:80 and 1M:80. if these;
; compare the a20 is disabled thus causing a wraparound.		      ;
;									      ;
; INPUTS:								      ;
;									      ;
; OUTPUTS:	[state_a20] .. A20_ON  if a20 is on currently		      ;
;			    .. A20_OFF if a20 is off currently		      ;
;									      ;
; USES: flags								      ;
;									      ;
; AUTHOR: ISP.  Shifted in from smartdrv sources. 8/29/88.     ;
;									      ;
;*****************************************************************************;
; A20 address line state determination addresses
;
	low_mem label	dword
		dw	20h*4
		dw	0

	high_mem label	dword
		dw	20h*4 + 10h
		dw	0ffffh

estb_a20_state	proc	near
	push	cx
	push	ds
	push	es
	push	si
	push	di
    ;
    ; initialise a20 to off
    ;
	mov	[state_a20],A20_OFF
    ;
    ; compare 3 dwords at 0:80h and 1M:80h.  if these are equal then
    ; we can assume that a20 is off
    ;
	lds	si,cs:low_mem
	ASSUME	DS:NOTHING
	les	di,cs:high_mem
	ASSUME	ES:NOTHING
	mov	cx,3
	cld
repe	cmpsd
	pop	di
	pop	si
	pop	es
	pop	ds
	ASSUME	DS:DGROUP,ES:DGROUP
	jcxz	not_enabled
    ;
    ; a20 is on
    ;
	mov	[state_a20],A20_ON
not_enabled:
	pop	cx
	ret
estb_a20_state	endp

;*****************************************************************************;
;***	get_init_a20_state   - see if virtualised a20 is enabled or not       ;
;									      ;
;	ENTRY	[state_a20] = A20 state at startup			      ;
;									      ;
;	EXIT	ZF set if A20 disabled					      ;
;		ZF not set if A20 enabled				      ;
;									      ;
;	USES	Flags							      ;
;*****************************************************************************;

	ASSUME	DS:DGROUP,ES:NOTHING

get_init_a20_state   proc    near
;
	test	[state_a20], A20_ON
	ret
get_init_a20_state   endp

LAST   ends

	end				; end of module
