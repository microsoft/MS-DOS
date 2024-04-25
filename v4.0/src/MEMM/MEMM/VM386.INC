

;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
;
;   Module:   VM386.INC
;
;   Version:  0.03
;
;   Date:     May 12, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;	      Original
;   05/12/86  A 	Cleanup and segment reorganization
;   06/08/86  B 	Added Disable A20 equates
;   06/14/86  C 	Added MOV_CDTR_FRAME, PROT_INS_FRAME, and changed
;			VTFO from 2 to 4 to reflect push of EBP from BP
;   06/15/86  D 	Added GPFAULT_FRAME
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   07/01/86  0.03	Added structures for accessing memory
;
;******************************************************************************
ifndef INC_LIST
.xlist
endif

;
;   Structures for accessing memory
;
WordS	struc
	LowByte 	db	?
	HighByte	db	?
WordS	ends

DwordS	struc
	LowWord 	dw	?
	HighWord	dw	?
DwordS	ends

;
;   Structure for accessing stack frame pushed during trap exit from VM
;

VM_TRAP_FRAME	struc
VMTF_EIP	dw	?		; EIP (low)
		dw	?		; EIP (high)
VMTF_CS 	dw	?		; CS
		dw	?		;   (padding)
VMTF_EFLAGS	dw	?		; EFLAGS (low)
VMTF_EFLAGShi	dw	?		; EFLAGS (high)
VMTF_ESP	dw	?		; ESP (low)
		dw	?		; ESP (high)
VMTF_SS 	dw	?		; SS
		dw	?		;   (padding)
VMTF_ES 	dw	?		; ES
		dw	?		;   (padding)
VMTF_DS 	dw	?		; DS
		dw	?		;   (padding)
VMTF_FS 	dw	?		; FS
		dw	?		;   (padding)
VMTF_GS 	dw	?		; GS
		dw	?		;   (padding)
VM_TRAP_FRAME	ends
;
					; Used in EmMovCDTR (vminst.asm)
MOV_CDTR_FRAME	 struc
MCF_WBP 	dw	?		; Work BP
MCF_WES 	dw	?		; Work ES
MCF_EAX 	dw	?		; EAXlo
		dw	?		; EAXhi
MCF_ESI 	dw	?		; ESIlo
		dw	?		; ESIhi
MCF_EBX 	dw	?		; EBXlo
		dw	?		; EBXhi
MCF_EBP 	dw	?		; EBPlo
		dw	?		; EBPhi
MCF_VMERR	dw	?		; VM Error Code (low)
		dw	?		; VM Error Code (high)
MCF_VMEIP	dw	?		; VM EIP (low)
		dw	?		; VM EIP (high)
MCF_VMCS	dw	?		; VM CS
		dw	?		;   (padding)
MCF_VMEFLAGS	dw	?		; VM EFLAGS (low)
MCF_VMEFLAGShi	dw	?		; VM EFLAGS (high)
MCF_VMESP	dw	?		; VM ESP (low)
		dw	?		; VM ESP (high)
MCF_VMSS	dw	?		; VM SS
		dw	?		;   (padding)
MCF_VMES	dw	?		; VM ES
		dw	?		;   (padding)
MCF_VMDS	dw	?		; VM DS
		dw	?		;   (padding)
MCF_VMFS	dw	?		; VM FS
		dw	?		;   (padding)
MCF_VMGS	dw	?		; VM GS
		dw	?		;   (padding)
MOV_CDTR_FRAME	 ends
;
					; Used in EmProtIns (vminst.asm)
PROT_INS_FRAME	 struc
PIF_WBP 	dw	?		; Work BP
PIF_WES 	dw	?		; Work ES
PIF_AX		dw	?		; EAXlo
PIF_DX		dw	?		; EDXlo
PIF_ESI 	dw	?		; ESIlo
		dw	?		; ESIhi
PIF_EBX 	dw	?		; EBXlo
		dw	?		; EBXhi
PIF_EBP 	dw	?		; EBPlo
		dw	?		; EBPhi
PIF_VMERR	dw	?		; VM Error Code (low)
		dw	?		; VM Error Code (high)
PIF_VMEIP	dw	?		; VM EIP (low)
		dw	?		; VM EIP (high)
PIF_VMCS	dw	?		; VM CS
		dw	?		;   (padding)
PIF_VMEFLAGS	dw	?		; VM EFLAGS (low)
PIF_VMEFLAGShi	dw	?		; VM EFLAGS (high)
PIF_VMESP	dw	?		; VM ESP (low)
		dw	?		; VM ESP (high)
PIF_VMSS	dw	?		; VM SS
		dw	?		;   (padding)
PIF_VMES	dw	?		; VM ES
		dw	?		;   (padding)
PIF_VMDS	dw	?		; VM DS
		dw	?		;   (padding)
PIF_VMFS	dw	?		; VM FS
		dw	?		;   (padding)
PIF_VMGS	dw	?		; VM GS
		dw	?		;   (padding)
PROT_INS_FRAME	 ends
;
GPFAULT_FRAME	struc
GPF_ESI 	dw	?		; ESIlo
		dw	?		; ESIhi
GPF_EBX 	dw	?		; EBXlo
		dw	?		; EBXhi
GPF_EBP 	dw	?		; EBPlo
		dw	?		; EBPhi
GPFAULT_FRAME	ends
;
;   The following constants define the offset of the Virtual Mode trap stack
;   frame (from current SP assuming BP has been pushed) for the two cases:
;   1) exceptions that don't push error codes and 2) those that do.
;
VTFO		equ	4		; offset of VM trap stack frame
VTFOE		equ	VTFO + 4	; as above, but including error code
;
;   These constants are used to sanity-check the value of SP when one of
;   the exception handlers has been entered:
;
STACK	segment
	extrn	kstack_top:byte
STACK	ends

  ; Trap/no error
VMT_STACK	equ	offset STACK:kstack_top - size VM_TRAP_FRAME - VTFO
  ; Trap w/error
VMTERR_STACK	equ	offset STACK:kstack_top - size VM_TRAP_FRAME - VTFOE

;******************************************************************************
;			    E R R O R	 C O D E S
;******************************************************************************
;
PrivErr 	equ	0000h	    ; Privileged Operation Error class
ErrLGDT 	equ	0000h	    ; Client tried to execute a LGDT
ErrLIDT 	equ	0001h	    ; Client tried to execute a LIDT
ErrLMSW 	equ	0002h	    ; Client tried to execute a LMSW
Err2LL		equ	0003h	    ; Client tried to execute a 286 Loadall
Err3LL		equ	0004h	    ; Client tried to execute a 386 Loadall
ErrMovCR	equ	0005h	    ; Client tried to execute a CRn mov
ErrMovDR	equ	0006h	    ; Client tried to execute a DRn mov
ErrMovTR	equ	0007h	    ; Client tried to execute a TRn mov

ExcpErr 	equ	0001h	    ; Exception Error class
ErrDIV		equ	0000h	    ; Divide Error
ErrINT1 	equ	0001h	    ; Debug Exception
ErrNMI		equ	0002h	    ; NMI
ErrINT3 	equ	0003h	    ; Int 3
ErrINTO 	equ	0004h	    ; Int O error
ErrBounds	equ	0005h	    ; Array Bounds Check
ErrOpCode	equ	0006h	    ; Invalid Opcode
ErrCoPNA	equ	0007h	    ; Coprocessor Device not available
ErrDouble	equ	0008h	    ; Double Fault
ErrCoPseg	equ	0009h	    ; Coprocessor Segment Overrun
ErrTSS		equ	000Ah	    ; Invalid TSS
ErrSegNP	equ	000Bh	    ; Segment not Present
ErrStack	equ	000Ch	    ; Stack Fault
ErrGP		equ	000Dh	    ; General Protection Fault
ErrPage 	equ	000Eh	    ; Page Fault
ErrCoPerr	equ	0010h	    ; Coprocessor Error
ErrWrite	equ	0020h	    ; Attempt to write to protected area
ErrDMA		equ	0021h	    ; Attempt to DMA into page frame (not for user)
ErrINTProt	equ	0022h	    ; General Protected interrupt error

.list	; end of VM386.INC
