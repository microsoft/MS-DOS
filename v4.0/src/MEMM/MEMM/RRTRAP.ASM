

page	58,132
;******************************************************************************
	title	RRTRAP.ASM - Return To Real Trap
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   RRTRAP.ASM - Return to Real Trap
;
;   Version:  0.04
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
;   06/01/86  Original
;   06/28/86  0.02	Name changed from MEMM386 to MEMM
;   07/03/86  0.03	Changed to P84/85 Handlers
;   07/06/86  0.04	Moved JumpReal to R_CODE and far label
;   07/06/86  0.04	Changed assume to DGROUP
;
;******************************************************************************
;
;   Functional Description:
;	This module traps ports 85h and 84h and watches for an application
;   to output the Return-to-Real code to these ports.  If a 84h=0Fh is output,
;   then 85h=0h is output, the code in this module returns the system
;   to real mode.
;
;
;******************************************************************************
.lfcond 				; list false conditionals
.386p
	page

;******************************************************************************
;			I N C L U D E	F I L E S
;
	include VDMseg.inc
	include VDMsel.inc
	include desc.inc
	include INSTR386.INC
	include VM386.INC
;
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;
	public	RRP_Handler
	public	RR_Trap_Init
	public	RRProc
	public	JumpReal
;
;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;
_TEXT	segment
extrn	RetReal:near
extrn	PortTrap:near
_TEXT	ends

	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;
FALSE	equ	0
TRUE	equ	not FALSE

RR85_Value	equ	00h
RR84_Value	equ	0Fh

FLAGS_IF	equ	0200h
FLAGS_TF	equ	0100h

RR_MASK equ	NOT	(FLAGS_IF+FLAGS_TF)	; mask off IF and TF bits

RTC_CMD 	equ	70h	; real time clock command port
DISABLE_NMI	equ	80h	; cmd to disable NMI
ENABLE_NMI	equ	00h	; cmd to enable NMI

;
;******************************************************************************
;		D A T A   S E G M E N T   D E F I N I T I O N S
;
ABS0	segment at 0000h
ABS0	ends
;
_DATA	segment
RR_Last 	db	0		; last RR port trapped
RR85save	db	0FFh
RR84save	db	0FFh
_DATA	ends

;
;------------------------------------------------------------------------------
;	_TEXT code
;------------------------------------------------------------------------------
_TEXT	segment
	assume	cs:_TEXT, ds:DGROUP, es:DGROUP, ss:DGROUP

	page
;******************************************************************************
;   RRP_Handler - I/O Trap handler for return to real ports 84h and 85h
;
;   ENTRY: Protected Mode Ring 0
;		AL = byte to output to port.
;		BX = 2 * port addr
;		DX == 0 => input
;		   <> 0 => output
;		DS = DGROUP
;		SS:SP pts to: IP, saved DS, saved DX, IP ,
;			      saved DX,saved BX,saved ESI,saved EBX,saved EBP,
;			then GP fault stack frame with error code.
;		SS:BP = points to stack frame on entry to GP fault handler
;
;   EXIT: Protected Mode Ring 0
;		CLC => I/O emulated.
;		STC => I/O NOT emulated.
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
RRP_Handler	proc	near
	or	dx,dx		;Q: Output ?
	jz	RRP_Bye 	;  N: then leave
	cmp	bx,84h*2
	je	P84_Handler	; Process port 84h
	cmp	bx,85h*2
	je	P85_Handler	; Process port 85h
RRP_Bye:
	stc			; don't bother to emulate it
	ret
RRP_Handler	endp

;******************************************************************************
;   P84_Handler - I/O Trap handler for port 84h
;
;   ENTRY: Protected Mode Ring 0
;		AL = byte to output to port.
;		BX = 2 * port addr
;		DX == 0 => input
;		   <> 0 => output
;		DS = DGROUP
;		SS:SP pts to: IP, saved DS, saved DX, IP ,
;			      saved DX,saved BX,saved ESI,saved EBX,saved EBP,
;			then GP fault stack frame with error code.
;		SS:BP = points to stack frame on entry to GP fault handler
;
;   EXIT: Protected Mode Ring 0
;		CLC => I/O emulated.
;		STC => I/O NOT emulated.
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
P84_Handler	proc	near
;
	mov	[RR84save],al	;  Y: save value written to 84
	mov	[RR_Last],84h	; save this RR port #
	stc			; don't bother to emulate it
	ret
;
P84_Handler	endp

	page
;******************************************************************************
;   P85_Handler - I/O Trap handler for port 85h
;
;   ENTRY: Protected Mode Ring 0
;		AL = byte to output to port.
;		BX = 2 * port addr
;		DX == 0 => input
;		   <> 0 => output
;		DS = DGROUP
;		SS:SP pts to: IP, saved DS, saved DX, IP ,
;			      saved DX,saved BX,saved ESI,saved EBX,saved EBP,
;			then GP fault stack frame with error code.
;		SS:BP = points to stack frame on entry to GP fault handler
;
;   EXIT: If output to 85h => return to Real
;		RRTrap emulates the output to 85h
;		RRTrap returns to real, fixes the segments and stack, and
;		       returns to the instruction past the output in real mode.
;	  If output does not imply return to Real
;		Protected Mode Ring 0
;		CLC => I/O emulated.
;		STC => I/O NOT emulated.
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
P85_Handler	proc	near
;
	mov	[RR85save],al	;  Y: save value for 85h
	cmp	al,RR85_Value	;    Q: return to real value output to 85 ?
	jne	P85_Exit	;      N: save port # and leave
	cmp	[RR_Last],84h	;      Y: Q: was last 84h last RR port output ?
	jne	P85_Exit	;	   N: save port # and leave
	cmp	[RR84Save],RR84_Value	;  Y: Q: was 84h value RR value ?
	jne	P85_Exit	;		N: save port # and leave
	out	85h,al		;		Y: emulate output and
	jmp	RR_GoReal	;		  return to real(we're in real)
P85_Exit:
	mov	[RR_Last],85h	; save this RR port addr
	stc			; don't bother to emulate it
	ret
;
P85_Handler	endp

	page
;******************************************************************************
;	RR_GoReal - return client to real after 84/85 trap
;
;    This is the return to real code.  First we return to real mode.
;    Then we set up the stack, restore the registers and return to
;    the instruction following the out to 85h.
;**************
;NOTE: the following depends on the entry stack for P85_Handler
;      the same.
;	ENTRY:
;		SS:SP pts to: IP, saved DS, saved DX, IP ,
;			      saved DX,saved BX,saved ESI,saved EBX,saved EBP,
;			then GP fault stack frame with error code.
;**************
;******************************************************************************
;
RR_GoReal:
	push	ax
	mov	al,DISABLE_NMI
	out	RTC_CMD,al		; disable NMIs
	pop	ax

	call	RetReal 		; return to real mode, DS,ES = DGROUP
;
;   now start resetting registers from the stack
;
;
	add	sp,8			; skip IP,DS,DX, and IP
	pop	dx
	pop	bx			; last pushed by OUT emulator
;
;   now back to stack presented by VmFault's jmp to instr handler
;
;	   on to JumpReal code and continue in Real mode
;
	jmp	FAR PTR JumpReal

;******************************************************************************
;
;	RRProc	    Force processor into real mode
;
;	entry:
;
;	exit:	    Processor is in real mode
;
;	used:	    AX
;
;	stack:
;
;******************************************************************************
RRProc		proc near
	pushf
	cli				; protect this sequence
	mov	al,RR84_Value		;
	out	84h,al			; port 84/85 return to real
	mov	al,RR85_Value		;     sequence ...
	out	85h,al			;
	jmp	$+2			; clear prefetch/avoid race cond
	popf
	ret
RRProc		endp

;******************************************************************************
;
;	RR_Trap_Init Initialize data structure for return to real trapping
;
;	description: This routine is called when the processor is put in
;		    virtual mode.  It should initialize anything that is
;		    used by the RRTrap code. It assumes that the handler
;		    addresses for ports 84h and 85h in IOTrap_Tab are set
;		    up to point to RRP_Handler.
;
;	entry:	    DS pts to DGROUP
;
;	exit:	    Return to real trapping data structure initialized
;
;	used:	    AX, BX
;
;	stack:
;
;******************************************************************************
RR_Trap_Init	 proc	 near
	mov	[RR_Last],0		    ; reset Return to real trap vars
	mov	[RR85save],0FFh
	mov	[RR84save],0FFh
	mov	bh, 00h 		    ; only set for 0084h and 0085h
	mov	ax, 84h
	call	PortTrap		    ; set traps on both return to real
	mov	ax, 85h 		    ; ports in case client tries to
	call	PortTrap		    ; return to real
	ret
RR_Trap_Init	 endp

_TEXT	ends				    ; end of segment

;------------------------------------------------------------------------------
;	R_CODE code
;------------------------------------------------------------------------------
R_CODE	segment
	assume	cs:R_CODE, ds:DGROUP, es:DGROUP, ss:DGROUP
;
;******************************************************************************
;			L O C A L   D A T A   A R E A
;******************************************************************************
;
RR_Jump 	label	dword		; ret addr for instr after out 84
RR_JOff 	dw	0
RR_JSeg 	dw	0

RR_DS		dw	0		; DS for return
RR_SS		dw	0		; SS for return
RR_SP		dw	0		; SP for return

RR_Flags	dw	0		; low word of flags for return

;******************************************************************************
;
; NAME: JumpReal - jump into faulting code and continuing executing in Real
;	mode.	When a virtual mode process causes a GP fault, then wishes
;	to continue executing in Real mode afterwards, VDM returns to real
;	mode then calls this routine to "unwind" the stack and continue
;	the process in real mode.
;
;		THIS IS A FAR JUMP ***
;
; ENTRY:	REAL MODE
;		SS:[BP] -> points to GP fault stack frame
;		SS:[SP]   = saved client's ESI
;		SS:[SP+4] = saved client's EBX
;		SS:[SP+8] = saved client's EBP
;
; EXIT: 	REAL MODE
;		continues execution of process specified in GP fault stack
;		frame.
;
;******************************************************************************
JumpReal	label	far
	push	cs
	pop	ds		; set DS= CS = R_CODE
	ASSUME	DS:R_CODE
					; set up return address
	mov	bx,[bp.VTFOE+VMTF_EIP]	; get return IP
	mov	[RR_JOff],bx		; save it
	mov	bx,[bp.VTFOE+VMTF_CS]	; get return CS
	mov	[RR_JSeg],bx		; save it
;
	mov	bx,[bp.VTFOE+VMTF_EFLAGS]	; get flags
	mov	[RR_Flags],bx			; and save
	and	[bp.VTFOE+VMTF_EFLAGS],RR_MASK	; mask off certain bits
;
	mov	bx,[bp.VTFOE+VMTF_DS]	; get DS
	mov	[RR_DS],bx		; save it

	mov	bx,[bp.VTFOE+VMTF_SS]	; get SS
	mov	[RR_SS],bx		; save it
	mov	bx,[bp.VTFOE+VMTF_ESP]	; get SP
	mov	[RR_SP],bx		; save it
;
; restore regs pushed by VM_Fault entry
;
	POP_ESI
	POP_EBX
	POP_EBP 			; ALL regs except SEGMENT and SP are
					; restored.
	add	sp,4+VMTF_ES		; skip error code and GP fault stack
					;   up to ES

	pop	es			; reset ES for return
	add	sp,6			; skip high word of ES segment
					; and DS dword

	POP_FS				; reset FS for return
	add	sp,2			; skip high word of segment

	POP_GS				; reset GS for return
;
;  now set flags, DS, stack, and jump to return.
;
	test	[RR_Flags],FLAGS_IF	;Q: IF bit set in return flags ?
	jz	RR_CLIexit		;  N: then just return
	push	[RR_Flags]		;  Y: enable interrupts on return
	popf				; set flags
	push	[RR_DS]
	pop	ds			; set DS for exit
	push	ax
	mov	al,ENABLE_NMI
	out	RTC_CMD,al		; enable NMIs
	pop	ax
					;*** there is a small window here
					; --- NMI could occur with invalid
					;     STACK

	mov	ss,CS:[RR_SS]		; restore SS
	mov	sp,CS:[RR_SP]		; restore SP
	sti				; enable ints
	jmp	CS:[RR_Jump]		;  and return

RR_CLIexit:
	push	[RR_Flags]		; leave interrupts disabled on return
	popf				; set flags
	push	[RR_DS]
	pop	ds			; set DS for exit
	push	ax
	mov	al,ENABLE_NMI
	out	RTC_CMD,al		; enable NMIs
	pop	ax
					;*** there is a small window here
					; --- NMI could occur with invalid
					;     STACK

	mov	ss,CS:[RR_SS]		; restore SS
	mov	sp,CS:[RR_SP]		; restore SP
	jmp	CS:[RR_Jump]		; far jump for return
;
R_CODE	ends				; end of segment
;
	end				; end of module
