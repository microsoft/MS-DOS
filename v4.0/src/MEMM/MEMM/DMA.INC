

;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
;
;   Module:   ELIM.INC - include for LIM I/O traps (DMA ports)
;
;   Version:  0.03
;
;   Date:     April 9, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   04/09/86  Original
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   07/01/86  0.03	DMA trapping related equates added
;
;     DATE    AUTHOR			DESCRIPTION
;   -------   --------	-------------------------------------------------------
;   06/21/88  ISP	Removed the Intel Above Board Port Definitions
;   07/27/88  JHB       Added Channel 4 ports, ports for Mode Regs and changed 
;                       DMARegRec and DMARegBuf structure definitions - lifted
;                       from vdmad.inc in Win386/2.03.
;                       - Jaywant H Bharadwaj
;
;******************************************************************************
ifndef INC_LIST
.xlist
endif
;
;
; DMA related ports
;
DMA_P0		equ	0087h		; DMA page register for Channel 0
DMA_P1		equ	0083h		; DMA page register for Channel 1
DMA_P2		equ	0081h		; DMA page register for Channel 2
DMA_P3		equ	0082h		; DMA page register for Channel 3
DMA_P5		equ	008Bh		; DMA page register for Channel 5
DMA_P6		equ	0089h		; DMA page register for Channel 6
DMA_P7		equ	008Ah		; DMA page register for Channel 7
DMA_P4		equ	0080h		; dummy page reg for channel 4

DMA_B0		equ	0000h		; DMA base register for Channel 0
DMA_C0		equ	0001h		; DMA count register for Channel 0
DMA_B1		equ	0002h		; DMA base register for Channel 1
DMA_C1		equ	0003h		; DMA count register for Channel 1
DMA_B2		equ	0004h		; DMA base register for Channel 2
DMA_C2		equ	0005h		; DMA count register for Channel 2
DMA_B3		equ	0006h		; DMA base register for Channel 3
DMA_C3		equ	0007h		; DMA count register for Channel 3
DMA_B4		equ	00C0h		; DMA base register for Channel 4
DMA_C4		equ	00C2h		; DMA count register for Channel 4
DMA_B5		equ	00C4h		; DMA base register for Channel 5
DMA_C5		equ	00C6h		; DMA count register for Channel 5
DMA_B6		equ	00C8h		; DMA base register for Channel 6
DMA_C6		equ	00CAh		; DMA count register for Channel 6
DMA_B7		equ	00CCh		; DMA base register for Channel 7
DMA_C7		equ	00CEh		; DMA count register for Channel 7

DMA1_CLR_FF	equ	000Ch		; clear flip-flop cmd for channels 0-3
DMA2_CLR_FF	equ	00D8h		; clear flip-flop cmd for channels 5-7


DMA1_MODE	equ	000Bh		; Mode register for channels 0-3
DMA2_MODE	equ	00D6h		; Mode register for channels 4-7

DMA_M_CHANNEL	equ	03h		; Mask for channel
DMA_M_OPERATION equ	0Ch		; Mask for operation
DMA_M_16BIT	equ	040h		; 16bit transfers (PS/2 ext mode)

DMA_M_VERIFY	equ	0		; Verify operation
DMA_M_WRITE	equ	4		; Write


;**************************************************************************
;  New defintions for DMARegRec and DMARegBuf - 7/27/88
;
;
;   DMA Register Save Structure
;

;
;   note: the DMA code in ELIMTRAP.ASM is tuned to this structure's size = 16
;         if you change the size, you had better change the code !
;   LinAdr and PhysAdr have to be dwords
;   count though 16 bits long is left as a dword since the rest of the ported
;   386 code is dependent on this structure being 16 bytes long.
;

DMARegRec	struc
DMALinAdr	dd	00000000	; Channel Linear Base Register
DMAPhyAdr	dd	00000000	; Channel Physical Base Register
DMACount	dd	00000000	; Channel Count Register
DMAPagePort	db	?		; byte addr of page reg
DMABasePort	db	?		; byte addr of base addr reg
DMACntPort	db	?		; byte addr of cnt addr reg
DMAMode 	db	?		; Mode register
DMARegRec	ends

DMARegBuf	struc
Chnl0	db	(size DMARegRec - 4) dup (00), DMA_P0, DMA_B0, DMA_C0, 0
Chnl1	db	(size DMARegRec - 4) dup (00), DMA_P1, DMA_B1, DMA_C1, 0
Chnl2	db	(size DMARegRec - 4) dup (00), DMA_P2, DMA_B2, DMA_C2, 0
Chnl3	db	(size DMARegRec - 4) dup (00), DMA_P3, DMA_B3, DMA_C3, 0
Chnl4	db	(size DMARegRec - 4) dup (00), DMA_P4, DMA_B4, DMA_C4, DMA_M_16BIT
Chnl5	db	(size DMARegRec - 4) dup (00), DMA_P5, DMA_B5, DMA_C5, DMA_M_16BIT
Chnl6	db	(size DMARegRec - 4) dup (00), DMA_P6, DMA_B6, DMA_C6, DMA_M_16BIT
Chnl7	db	(size DMARegRec - 4) dup (00), DMA_P7, DMA_B7, DMA_C7, DMA_M_16BIT
DMAFF1	db	00		; Controller 1 FlipFlop State
DMAFF2	db	00		; Controller 2 FlipFlop State
DMA_Xfun	db	0	; Extended Operation Function
DMA_Xchn	db	0	; Extended Operation Channel
DMARegBuf	ends

DMAREG_CTRL2_INDEX	equ	4 * 2	; 2 * 1st channel # on 2nd cntlr


;**************************************************************************
;
; Macros taken from PS2.INC in Win/386 2.03
;
;--------------------------------------------------------------------------

;   STANDARD ROM BIOS MACHINE TYPES used in ROM_BIOS_Machine_ID

RBMI_PC 		equ	0FFh
RBMI_PCXT		equ	0FEh
RBMI_PCjr		equ	0FDh
RBMI_PCAT		equ	0FCh
RBMI_PCConvertible	equ	0F9h
RBMI_Sys80		equ	0F8h
RBMI_CompaqPortable	equ	000h

;******************************************************************************
;   DMA_WADDR_TO_BADDR - convert internal DMA word address to a byte address
;
;   ENTRY:  386 PROTECTED MODE
;	    DS -> 0
;	    ES -> 0
;	    EAX    - Word Address
;
;   EXIT:   EAX - Byte address
;
;   USED:
;------------------------------------------------------------------------------
DMA_WADDR_TO_BADDR	MACRO
	LOCAL	Not_AT
extrn	ROM_BIOS_Machine_ID:byte

	cmp	[ROM_BIOS_Machine_ID], RBMI_Sys80
	jbe	short Not_AT			; If running on EBIOS machine

	ror	eax,16				; AX = high word
	shr	al,1				; adjust for D0 null in page reg
	rol	eax,17				; EAX = address w/ adjust for
						; 'A0' offset
Not_At:
	shl	ecx, 1				; Adjust for word units
	ENDM


;******************************************************************************
;   DMA_BADDR_TO_WADDR - convert internal DMA byte address to a word address
;
;   ENTRY:  386 PROTECTED MODE
;	    DS -> 0
;	    ES -> 0
;	    EAX    - Word Address
;
;   EXIT:   EAX - Byte address
;
;   USED:
;------------------------------------------------------------------------------
DMA_BADDR_TO_WADDR	MACRO
	LOCAL	Not_AT
extrn	ROM_BIOS_Machine_ID:byte

	cmp	[ROM_BIOS_Machine_ID], RBMI_Sys80
	jbe	short Not_AT			; If running on EBIOS machine

	shr	eax, 1				; Adjust for implied 'A0'
	push	ax				; Save A16-A1
	xor	ax, ax
	shl	eax, 1				; Adjust for unused Pg Reg D0
	pop	ax				; Restore A16-A1
Not_At:
	ENDM



;****************************************************************************
;  Old definitions for memm LIM 3.2 - not used anymore - 7/27/88
;
;   DMA Register Save Structure
;
;Chnl1Idx	equ	0		; Address offset in Address tables
;Chnl2Idx	equ	2		; Address offset in Address tables
;Chnl3Idx	equ	4		; Address offset in Address tables
;Chnl5Idx	equ	6		; Address offset in Address tables
;Chnl6Idx	equ	8		; Address offset in Address tables
;Chnl7Idx	equ	10		; Address offset in Address tables
;
;DMARegRec	struc
;DMALinAdr	dd	00000000	; Channel Linear Base Register
;DMAPhyAdr	dd	00000000	; Channel Physical Base Register
;DMACount	dd	00000000	; Channel Count Register
;DMAChnlIdx	db	?		; Channel identifier index
;DMARegRec	ends
;
;DMARegBuf	struc
;Chnl1		db	(size DMARegRec - 1) dup (00), Chnl1Idx
;Chnl2		db	(size DMARegRec - 1) dup (00), Chnl2Idx
;Chnl3		db	(size DMARegRec - 1) dup (00), Chnl3Idx
;Chnl5		db	(size DMARegRec - 1) dup (00), Chnl5Idx
;Chnl6		db	(size DMARegRec - 1) dup (00), Chnl6Idx
;Chnl7		db	(size DMARegRec - 1) dup (00), Chnl7Idx
;DMAFF1		db	00		; Controller 1 FlipFlop State
;DMAFF2		db	00		; Controller 2 FlipFlop State
;DMARegBuf	ends
;
;******************************************************************************


.list	; end of ELIM.INC
