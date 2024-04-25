

;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
;
;   Module:   INSTR386 - 386 Instruction Macro Declaration file
;
;   Version:  0.03
;
;   Date:     May 11, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   05/11/86  Original
;   06/01/86		Added operand/address size overide defines
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   07/01/86  0.03	Added 32 arithmetic defines
;
;******************************************************************************
ifndef INC_LIST
.xlist
endif

;***	OP32_IRET - 32 bit mode iret
OP32_IRET	macro
	db	66h
	iret
	endm

;***	OP32 - instruction prefix to invert sense of operand size attribute

OP32	macro
	db	66h
	endm


;***	EA32 - instruction prefix to invert sense of effective addr attribute

EA32	macro
	db	67h
	endm


;*** FS and GS overides
FSOVER	macro
	db	64h
	endm
GSOVER	macro
	db	65h
	endm

;   *** General Register 32 bit moves ***

MOV_EBX_EAX	macro
	db  66h
	mov bx, ax
	endm

MOV_EAX_EBX	macro
	db  66h
	mov ax, bx
	endm

MOV_ECX_EAX	macro
	db  66h
	mov cx, ax
	endm

MOV_EAX_ECX	macro
	db  66h
	mov ax, cx
	endm

MOV_EDX_EAX	macro
	db  66h
	mov dx, ax
	endm

MOV_EAX_EDX	macro
	db  66h
	mov ax, dx
	endm

MOV_EDI_EAX	macro
	db  66h
	mov di, ax
	endm

MOV_EAX_EDI	macro
	db  66h
	mov ax, di
	endm

MOV_ESI_EAX	macro
	db  66h
	mov si, ax
	endm

MOV_EAX_ESI	macro
	db  66h
	mov ax, si
	endm

MOV_EBP_EAX	macro
	db  66h
	mov bp, ax
	endm

MOV_EAX_EBP	macro
	db  66h
	mov ax, bp
	endm

MOV_ESP_EAX	macro
	db  66h
	mov sp, ax
	endm

MOV_EAX_ESP	macro
	db  66h
	mov ax, sp
	endm

;   *** Special Register/EAX 32 bit moves ***

MOV_CR0_EAX	macro
	db	0Fh,22h,0C0h
	endm

MOV_CR0_EBX	macro
	db	0Fh,22h,0C3h
	endm

MOV_CR0_ECX	macro
	db	0Fh,22h,0C1h
	endm

MOV_CR0_EDX	macro
	db	0Fh,22h,0C2h
	endm

MOV_CR0_ESP	macro
	db	0Fh,22h,0C4h
	endm

MOV_CR0_EBP	macro
	db	0Fh,22h,0C5h
	endm

MOV_CR0_ESI	macro
	db	0Fh,22h,0C6h
	endm

MOV_CR0_EDI	macro
	db	0Fh,22h,0C7h
	endm

MOV_EAX_CR0	macro
	db	0Fh,20h,0C0h
	endm

MOV_EBX_CR0	macro
	db	0Fh,20h,0C3h
	endm

MOV_ECX_CR0	macro
	db	0Fh,20h,0C1h
	endm

MOV_EDX_CR0	macro
	db	0Fh,20h,0C2h
	endm

MOV_ESP_CR0	macro
	db	0Fh,20h,0C4h
	endm

MOV_EBP_CR0	macro
	db	0Fh,20h,0C5h
	endm

MOV_ESI_CR0	macro
	db	0Fh,20h,0C6h
	endm

MOV_EDI_CR0	macro
	db	0Fh,20h,0C7h
	endm

MOV_CR2_EAX	macro
	db	0Fh,22h,0D0h
	endm

MOV_EAX_CR2	macro
	db	0Fh,20h,0D0h
	endm

MOV_CR3_EAX	macro
	db	0Fh,22h,0D8h
	endm

MOV_EAX_CR3	macro
	db	0Fh,20h,0D8h
	endm

MOV_DR0_EAX	macro
	db	0Fh,23h,0C0h
	endm

MOV_DR0_EBX	macro
	db	0Fh,23h,0C3h
	endm

MOV_DR1_EAX	macro
	db	0Fh,23h,0C8h
	endm

MOV_DR2_EAX	macro
	db	0Fh,23h,0D0h
	endm

MOV_DR3_EAX	macro
	db	0Fh,23h,0D8h
	endm

MOV_DR6_EAX	macro
	db	0Fh,23h,0F0h
	endm

MOV_DR7_EAX	macro
	db	0Fh,23h,0F8h
	endm

MOV_EAX_DR0	macro
	db	0Fh,21h,0C0h
	endm

MOV_ECX_DR0	macro
	db	0Fh,21h,0C1h
	endm

MOV_EDX_DR0	macro
	db	0Fh,21h,0C2h
	endm

MOV_EAX_DR1	macro
	db	0Fh,21h,0C8h
	endm

MOV_EAX_DR2	macro
	db	0Fh,21h,0D0h
	endm

MOV_EAX_DR3	macro
	db	0Fh,21h,0D8h
	endm

MOV_EAX_DR6	macro
	db	0Fh,21h,0F0h
	endm

MOV_EAX_DR7	macro
	db	0Fh,21h,0F8h
	endm

MOV_TR6_EAX	macro
	db	0Fh,26h,0F0h
	endm

MOV_EAX_TR6	macro
	db	0Fh,24h,0F0h
	endm

MOV_TR7_EAX	macro
	db	0Fh,26h,0F8h
	endm

MOV_EAX_TR7	macro
	db	0Fh,24h,0F8h
	endm

;   *** 32 bit Register/Immediate moves ***

MOV_EAX_	macro	imm
	db	66h, 0B8h
	dd	imm
	endm

MOV_EBX_	macro	imm
	db	66h, 0BBh
	dd	imm
	endm

MOV_ECX_	macro	imm
	db	66h, 0B9h
	dd	imm
	endm

MOV_EDX_	macro	imm
	db	66h, 0BAh
	dd	imm
	endm

MOV_EDI_	macro	imm
	db	66h, 0BFh
	dd	imm
	endm

MOV_ESI_	macro	imm
	db	66h, 0BEh
	dd	imm
	endm

MOV_EBP_	macro	imm
	db	66h, 0BDh
	dd	imm
	endm

MOV_ESP_	macro	imm
	db	66h, 0BCh
	dd	imm
	endm

;   *** 32-bit immediate arithmetic instructions

ADD_EAX_	macro	imm
	db	66h,05h
	dd	imm
	endm

ADD_EBX_	macro	imm
	db	66h,81h,0C3h
	dd	imm
	endm

ADD_ECX_	macro	imm
	db	66h,81h,0C1h
	dd	imm
	endm

ADD_EDX_	macro	imm
	db	66h,81h,0C2h
	dd	imm
	endm

SUB_EAX_	macro	imm
	db	66h,2Dh
	dd	imm
	endm

SUB_EBX_	macro	imm
	db	66h,81h,0EBh
	dd	imm
	endm

SUB_ECX_	macro	imm
	db	66h,81h,0E9h
	dd	imm
	endm

SUB_EDX_	macro	imm
	db	66h,81h,0EAh
	dd	imm
	endm

CMP_EAX_	macro	imm
	db	66h,3Dh
	dd	imm
	endm

CMP_EBX_	macro	imm
	db	66h,81h,0FBh
	dd	imm
	endm

CMP_ECX_	macro	imm
	db	66h,81h,0F9h
	dd	imm
	endm

CMP_EDX_	macro	imm
	db	66h,81h,0FAh
	dd	imm
	endm

;   *** New Segment Register/AX moves ***

MOV_FS_AX	macro
	db	8Eh,0E0h
	endm

MOV_AX_FS	macro
	db	8Ch,0E0h
	endm

MOV_GS_AX	macro
	db	8Eh,0E8h
	endm

MOV_AX_GS	macro
	db	8Ch,0E8h
	endm

;   *** New Segment Register pushes & pops ***

PUSH_FS 	macro
	db	0Fh,0A0h
	endm

PUSH_GS 	macro
	db	0Fh,0A8h
	endm

POP_FS		macro
	db	0Fh,0A1h
	endm

POP_GS		macro
	db	0Fh,0A9h
	endm

;   *** New Segment Register offset 16 memory moves ***

MOV_off16_FS	macro	off16
	db	8Ch,26h
	dw	off16
	endm

MOV_FS_off16	macro	off16
	db	8Eh,26h
	dw	off16
	endm

MOV_off16_GS	macro	off16
	db	8Ch,2Eh
	dw	off16
	endm

MOV_GS_off16	macro	off16
	db	8Eh,2Eh
	dw	off16
	endm

;   *** General Register 32 bit pushes & pops ***

PUSH_EAX	macro
	db  66h
	push	ax
	endm

POP_EAX 	macro
	db  66h
	pop	ax
	endm

PUSH_EBX	macro
	db  66h
	push	bx
	endm

POP_EBX 	macro
	db  66h
	pop	bx
	endm

PUSH_ECX	macro
	db  66h
	push	cx
	endm

POP_ECX 	macro
	db  66h
	pop	cx
	endm

PUSH_EDX	macro
	db  66h
	push	dx
	endm

POP_EDX 	macro
	db  66h
	pop	dx
	endm

PUSH_EDI	macro
	db  66h
	push	di
	endm

POP_EDI 	macro
	db  66h
	pop	di
	endm

PUSH_ESI	macro
	db  66h
	push	si
	endm

POP_ESI 	macro
	db  66h
	pop	si
	endm

PUSH_EBP	macro
	db  66h
	push	bp
	endm

POP_EBP 	macro
	db  66h
	pop	bp
	endm

PUSH_ESP	macro
	db  66h
	push	sp
	endm

POP_ESP 	macro
	db  66h
	pop	sp
	endm


;   *** General Register 32 bit xors ***

XOR_EAX_EAX	macro
	db	66h
	xor	ax, ax
	endm

XOR_EBX_EBX	macro
	db	66h
	xor	bx, bx
	endm

XOR_ECX_ECX	macro
	db	66h
	xor	cx, cx
	endm

XOR_EDX_EDX	macro
	db	66h
	xor	dx, dx
	endm

XOR_EBP_EBP	macro
	db	66h
	xor	bp, bp
	endm

.list	; end of INSTR386.INC
