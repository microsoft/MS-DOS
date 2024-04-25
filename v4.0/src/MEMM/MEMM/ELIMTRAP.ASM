

;******************************************************************************
        title	DMATRAP.ASM - Trap handlers for DMA ports
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:   DMATRAP.ASM - Trap Handlers for DMA ports
;
;   Version:  0.04
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
;   06/18/86  0.01	Modified LIM_Map to handle all 4 boards and call
;			page mapping routine in EMMLIB.LIB
;   06/27/86  0.02	Made _page_frame_address indexing dword (was word)
;
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;   07/01/86  0.03	Added DMA support routines
;   07/02/86  0.03	Fixed CNT size vs. length problem
;   07/06/86  0.04	Made _pft386 a ptr to _pft386 array
;   07/06/86  0.04	now sets _window array also
;   08/11/86  0.05	moved IO_Trap code for LIM DMA trapping here
;   06/09/88		remove IOT_LIM, LIMMap, and InitELIM since we don't
;			have any EMM hardware to trap and emulate now (Paulch)
;   07/26/88		reintroduced initelim removing iab port trap (ISP)
;
;   07/27/88            Started rewriting the DMA port trap handlers - similar to the
;			code in VDMAD.ASM in Win/386 V2.03
;			 - Jaywant H Bharadwaj
;
;*****************************************************************************


;******************************************************************************
;
;   Functional Description:
;
;   Monitors writes/reads to the DMA ports.
;   Reads are simple - return the value saved in DMARegSav structure.
;   On a write to Page/Base/count Reg port -
;   user specifies a linear address. DMAs can handle only physical addresses.
;   Therefore, the actual physical address has to be written into the Page and
;   base Address Reg. Also the DMA transfer area may not be physically contiguous.
;   If it isn't we should remap the linear address so that it is physically 
;   contiguous.
;
;   We never know when a DMA is started. Hence on every access to the Page/Base
;   or count Register we make sure that the linear address specified by the user
;   maps to a physical address which is contiguous over the DMA transfer area.
;   This has to be done even if the count register is altered since the user
;   might be relying on the previous contents of Page/Addr Regs which may not be
;   contiguous anymore.
;
;   All routines except InitDMA are entered through protected mode only.
;
;******************************************************************************

.lfcond 				; list false conditionals
.386p

	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************

;
; routines called from C
;
	public	_GetPte
	public	_SetPte
	public	_GetCRSEntry
	public	_GetDMALinAdr
	public	_Exchange16K
        public  _FatalError

	public	InitELIM		; initialization routine for LIMulator
	public	InitDMA 		; init DMA register save area
	public	DMARegSav
	public	_DMA_Pages
	public	DMA_Pages
	public	_DMA_PAGE_COUNT
	public	DMA_PAGE_COUNT



        public  DMA_DMAFixup
	public	DMABase0
	public	DMABase1
	public	DMABase2
	public	DMABase3
	public	DMABase5
	public	DMABase6
	public	DMABase7

	public	DMACnt0
	public	DMACnt1
	public	DMACnt2
	public	DMACnt3
	public	DMACnt5
	public	DMACnt6
	public	DMACnt7
	public	DMAPg0
	public	DMAPg1
	public	DMAPg2
	public	DMAPg3
	public	DMAPg5
	public	DMAPg6
	public	DMAPg7
	public	DMAClrFF1
	public	DMAClrFF2
	public	DMAMode1
	public	DMAMode2


	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
	include VDMseg.inc
	include VDMsel.inc
	include desc.inc
	include elim.inc
	include mach_id.inc
	include page.inc
	include oemdep.inc
	include instr386.inc
	include vm386.inc
	include emmdef.inc

;******************************************************************************
;
; Get_FRS_window - get pointer to Fast Register Set window
;
;	ENTRY:	Reg - points to an FRS_struc
;
;	EXIT:	Reg - points to FRS_window entry in the structure
;
;	USES:	Reg
;
;******************************************************************************
Get_FRS_window	MACRO	Reg

	mov	Reg, word ptr [CurRegSet]	; just offset (assume dgroup)
	add	Reg, FRS_window			; points to FRS window entries
	ENDM

;****************************************************************************
;
;    InitDMARegSav - MACRO for initialising save area for channels
;
;	ENTRY:	   chan_num = channel number (1,2,3,5,6,7)
;		   ES -> DGROUP
;
;-----------------------------------------------------------------------------

InitDMARegSav	MACRO	chan_num

	lea	di,[DMARegSav.Chnl&chan_num]	; pt to channel's save area

	xor	eax, eax
	in	al,DMA_P&chan_num	; page register for channel
	jmp	$+2
	jmp	$+2			; timing
	shl	eax,16			; high EAX = high word of linear addr

					; flip-flop already reset by the caller
	
	in	al,DMA_B&chan_num	; get low byte of base
	jmp	$+2
	jmp	$+2			; timing
	mov	ah,al
	in	al,DMA_B&chan_num	; get high byte of base
	xchg	ah,al
					; EAX = LINEAR BASE address

	stosd				; store LINEAR BASE address

	stosd				; store PHYSICAL BASE address

	xor	eax, eax		; clear EAX
	jmp	$+2
	jmp	$+2			; timing
	in	al,DMA_C&chan_num	; get low byte of count
	jmp	$+2
	jmp	$+2			; timing
	mov	ah,al
	in	al,DMA_C&chan_num	; get high byte of count
	xchg	ah,al
					; EAX = count

	stosd				; store count

	add	di, 4			; skip 4 bytes - 3 ports+mode byte

	ENDM


;******************************************************************************
;   DMA_WADDR_TO_BADDR - convert internal DMA word address to a byte address
;
;   ENTRY:  386 PROTECTED MODE
;	    DS -> DGROUP
;	    ES -> DGROUP
;	    EAX    - Word Address
;
;   EXIT:   EAX - Byte address
;
;   USED:
;------------------------------------------------------------------------------
DMA_WADDR_TO_BADDR	MACRO
	LOCAL	Not_AT

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
;	    DS -> DGROUP
;	    ES -> DGROUP
;	    EAX    - Word Address
;
;   EXIT:   EAX - Byte address
;
;   USED:
;------------------------------------------------------------------------------
DMA_BADDR_TO_WADDR	MACRO
	LOCAL	Not_AT

	cmp	[ROM_BIOS_Machine_ID], RBMI_Sys80
	jbe	short Not_AT			; If running on EBIOS machine

	shr	eax, 1				; Adjust for implied 'A0'
	push	ax				; Save A16-A1
	xor	ax, ax
	shl	eax, 1				; Adjust for unused Pg Reg D0
	pop	ax				; Restore A16-A1
Not_At:
        ENDM

;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************

_DATA	segment
extrn	ROM_BIOS_Machine_ID:byte
extrn	_page_frame_base:word
extrn	CurRegSet:word
extrn	Page_Dir:word		
SaveAL  db      ?
_DATA	ends

_TEXT	segment

extrn	PortTrap:near		; set port bit in I/O bit Map
extrn	MapLinear:near
extrn   ErrHndlr:near
;
; Swap pages so that DMA Xfer area is physically contiguous.
; defined in mapdma.c
;
extrn	_SwapDMAPages:near	

_TEXT	ends

;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************

_DATA	segment

DMARegSav   DMARegBuf	<>		; DMA Register buffer

DMAP_Page label word
;	dw	DMA_P0			; DMA page registers
	dw	DMA_P1
	dw	DMA_P2
	dw	DMA_P3
	dw	DMA_P5
	dw	DMA_P6
	dw	DMA_P7
;	 dw	 DMA_P4
;	 dw	 DMA_P0+10h		; page regs mapped to here also
	dw	DMA_P1+10h
	dw	DMA_P2+10h
	dw	DMA_P3+10h
	dw	DMA_P5+10h
	dw	DMA_P6+10h
	dw	DMA_P7+10h
;	 dw	 DMA_P4+10h
DMAP_Addr label word
;	dw	DMA_B0			; DMA base registers
	dw	DMA_B1
	dw	DMA_B2
	dw	DMA_B3
	dw	DMA_B5
	dw	DMA_B6
	dw	DMA_B7
DMAP_Count label word
;	dw	DMA_C0			; DMA count registers
	dw	DMA_C1
	dw	DMA_C2
	dw	DMA_C3
	dw	DMA_C5
	dw	DMA_C6
	dw	DMA_C7
	dw	DMA1_CLR_FF		; reset flip-flop commands
	dw	DMA2_CLR_FF
DMAP_Mode label word
	dw	DMA1_MODE
	dw	DMA2_MODE

LIMDMAP_CNT	   =	   ($ - DMAP_Page) / 2
;
;    DMA_Pages - EMM Pages for DMA relocation. Each is an index into pft386.
;	To access actual entry in pft386 you need to multiply index by 4.
;	If eight contingous 16k EMM pages are not available - the unavailable
;	entries are left at NULL_PAGE.
;	This array should be initialized at boot time.
;
_DMA_Pages	LABEL	WORD
DMA_Pages	dw	8 dup (NULL_PAGE)   ; null for start
_DMA_PAGE_COUNT	LABEL	WORD
DMA_PAGE_COUNT	dw	0		    ; number of above initialised


_DATA	ends

	page

;------------------------------------------------------------------------------

_TEXT	segment
	assume	cs:_TEXT, ds:DGROUP, es:DGROUP, ss:DGROUP

;******************************************************************************
;
;   InitDMA - initialize internal values for DMA registers of each channel
;
;   ENTRY: Real Mode
;	   DS = DGROUP
;
;   EXIT:  Real Mode
;	   DGROUP:[DMARegSav] = DMA register save area initialized
;
;------------------------------------------------------------------------------

InitDMA	proc	near

	push	eax
	push	di
	push	es
	
	pushf
	cli
	cld
	
	push	ds
	pop	es		; ES = DGROUP
	
	xor	al,al
	out	DMA1_CLR_FF, al		; clear FF on first controller
	mov	[DMARegSav.DMAFF1], al	; reset S/W FF
	jmp	$+2
	jmp	$+2			; timing
;
;	initialize regs for channels 1,2,3
;
	InitDMARegSav 1
	InitDMARegSav 2
	InitDMARegSav 3

	xor	al,al
	out	DMA2_CLR_FF, al		; clear FF on second controller
	mov	[DMARegSav.DMAFF2], al	; reset S/W FF
	jmp	$+2
	jmp	$+2			; timing
;
;	initialize regs for channels 5,6,7
;
	InitDMARegSav 5
	InitDMARegSav 6
	InitDMARegSav 7
	
	popf
	pop	es
	pop	di
	pop	eax
	ret

InitDMA	endp

;******************************************************************************
;
;   DMABase(0-7) - Write/Read DMA Channel N Base Register
;
;   ENTRY: 
;       AL = byte to output to port
;       BX = port * 2
;       DH = 0 => Emulate Input
;          <>0 => Emulate Output
;
;   EXIT:  
;       AL = emulated input/output value from port.
;       CLC => I/O emulated or performed
;
;------------------------------------------------------------------------------
DMABase0to7   proc    near

DMABase4:                                    ; I/O port C0h
DMABase5:                                    ; I/O port C4h
DMABase6:                                    ; I/O port C8h
DMABase7:                                    ; I/O port CCh
        push    ax
        push    bx
        push    cx
        push    dx
        push	si
;
; Now, BX = port * 2 and DX = IO code
; Code ported from Win/386 expects DX = port and BH = IO code
;
	xchg	dx, bx
	shr     dx, 1
	xchg	bh,bl                        ; move IO code to bh

        mov     si, dx
        sub     si, 0B0h                     ; SI = Channel * 4
        shl     si, 2                        ; SI = Channel * 16
        mov     bl, [DMARegSav.DMAFF2]       ; get flip-flop
        xor     [DMARegSav.DMAFF2], 1        ; and toggle it
        jmp     short DMABaseN                        ;

DMABase0:                                    ; I/O port 00h
DMABase1:                                    ; I/O port 02h
DMABase2:                                    ; I/O port 04h
DMABase3:                                    ; I/O port 06h
        push    ax
        push    bx
        push    cx
        push    dx
        push	si
;
; Now, BX = port * 2 and DX = IO code
; Code ported from Win/386 expects DX = port and BH = IO code
;
	xchg	dx, bx
	shr     dx, 1
	xchg	bh,bl                        ; move IO code to bh

        mov     si, dx                       ; SI = Channel * 2
        shl     si, 3                        ; SI = Channel * 16
        mov     bl, [DMARegSav.DMAFF1]       ; get flip-flop
        xor     [DMARegSav.DMAFF1], 1        ; and toggle it

;
; FALL THROUGH!!!
;

;******************************************************************************
;
;   DMABaseN - Write/Read DMA Channel N Base Register
;
;   ENTRY: As above plus
;          SI = 16 * channel #
;
;------------------------------------------------------------------------------
DMABaseN:
        and     bl, 1                           ; Look at bit0 only - safety

        or      bh,bh                           ;Q: Input ?
        jz      short Base_rd_port              ;  Y: do Read operation
                                                ;  N: save value "written"
        mov     [SaveAL], al                    ; save AL in Save area.
	xor	bh, bh             		; Make BX = Flip Flop state
        mov     byte ptr DMARegSav.DMALinAdr[bx][si], al

	in	al, dx				; Just a Dummy I/O to
						; toggle the real flip-flop
						; to match DMAFF above
	jmp	$+2
	jmp	$+2
	xor	bl,1				; and the s/w one

        call    DMA_DMAFixup                    ; Translate Lin to Phys
						; & Update DMARegSav
	call	DMA_WrtAdrReg 		        ; emulate the write
	jmp	short DBExit

Base_rd_port:
        in      al, dx                          ; Toggle the real flop-flip
;
; bh is already zero, therefore BX = flip flop state
;
        mov     al,byte ptr DMARegSav.DMALinAdr[bx][si]
        mov     [SaveAL], al
DBExit:
	pop	si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        mov     al, [SaveAL]
        clc
        ret

DMABase0to7  endp

        page

;******************************************************************************
;
;   DMACnt(0-7) - Write/Read DMA Channel N Count Register
;
;ENTRY: 
;       AL = byte to output to port.
;       BX = port * 2
;       DH = 0 => Emulate Input.
;          <>0 => Emulate Output.
;
;EXIT: 
;       AL = emulated input/output value from port.
;       CLC => I/O emulated or performed
;
;------------------------------------------------------------------------------

DMACnt0to7   proc    near

DMACnt4:                                     ; I/O port C2h
DMACnt5:                                     ; I/O port C6h
DMACnt6:                                     ; I/O port CAh
DMACnt7:                                     ; I/O port CEh
        push    ax
        push    bx
        push    cx
        push    dx
        push	si
;
; Now, BX = port * 2 and DX = IO code
; Code ported from Win/386 expects DX = port and BH = IO code
;
	xchg	dx, bx
	shr     dx, 1
	xchg	bh,bl                          ; move IO code to bh

        mov     si, dx
        sub     si, 0B2h                       ; SI = 4 * channel #
        shl     si, 2                          ; si = 16 * channel #
        mov     bl, [DMARegSav.DMAFF2]         ; get flip-flop
        xor     [DMARegSav.DMAFF2], 1          ; toggle our flip-flop
        jmp     short DMACntN

DMACnt0:                                       ; I/O port 01h
DMACnt1:                                       ; I/O port 03h
DMACnt2:                                       ; I/O port 05h
DMACnt3:                                       ; I/O port 07h
        push    ax
        push    bx
        push    cx
        push    dx
        push	si
;
; Now, BX = port * 2 and DX = IO code
; Code ported from Win/386 expects DX = port and BH = IO code
;
	xchg	dx, bx
	shr     dx, 1
	xchg	bh,bl                          ; move IO code to bh

        mov     si, dx
        dec     si
        shl     si, 3                           ; si = 16 * channel #
        mov     bl, [DMARegSav.DMAFF1]          ; get flip-flop
        xor     [DMARegSav.DMAFF1], 1           ; toggle our flip-flop
;
; FALL THROUGH!!!
;

;******************************************************************************
;
;   DMACntN - Write/Read DMA Channel N Count Register
;
;   ENTRY: As DMACnt1to7 plus
;          si = 16 * channel #
;
;------------------------------------------------------------------------------
DMACntN:
        and     bl, 1                           ; Look at bit0 only - Safety

        or      bh,bh                           ;Q: Input ?
        jz      short DMA_CntN_rd               ;  Y: do Read operation
						;  N: save value "written"
        mov     [SaveAL], al                    ; save AL in Save area.
	xor	bh, bh				; make BX = Flip Flop state
        mov     byte ptr DMARegSav.DMACount[bx][si], al       ; save cnt
        out     dx, al                          ; do the I/O

	xor	bl,1				; Toggle flip-flop for Wrt
        call    DMA_DMAFixup                    ; Translate Lin to Phys
						; & Update DMARegSav
	call	DMA_WrtAdrReg 		        ; emulate the write
        call    DMALoadCount

	jmp	short DCExit
DMA_CntN_rd:
        xor	bh,bh                           ; make BX = Flip Flop state
	in	al, dx				; Toggle the real flip-flop
                                                ; to match bx above
        mov     [SaveAL], al
						
	jmp	$+2
	jmp	$+2
	xor	bl,1				; and the s/w one
;
; get current count values from cntlr
;
        in      al, dx                          ; get 2nd byte of Count reg
        jmp     $+2                             ; timing ...
        jmp     $+2                             ; timing ...
        mov     byte ptr DMARegSav.DMACount[bx][si], al  ; save it
        xor     bl, 1                           ; flip to other byte
        in      al, dx                          ; get 1st byte of Count reg
        mov     byte ptr DMARegSav.DMACount[bx][si], al  ; save it
DCExit:
	pop	si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        mov     al, [SaveAL]

        clc                                     ; I/O emulated, return
        ret

DMACnt0to7   endp

        page
;******************************************************************************
;
;   DMAPgN - Write/Read DMA Channel N Page Register
;
;   ENTRY: 
;       AL = byte to output to port
;       BX = port * 2
;       DX = 0 => Emulate Input
;          <>0 => Emulate Output
;       si = 2 * Channel #
;
;   EXIT:
;       AL = emulated input/output value from port.
;       CLC => I/O emulated or performed
;
;   USED:  EBX,Flags
;   STACK:
;
;   NOTES:     For channels 0-4, DMACount is in Bytes, and
;              DMALinAdr holds the address as:
;
;              +-----------+-----------+----------------------+
;              |   31-24   |   23-16   |         15-0         |
;              +-----------+-----------+----------------------+
;              | 0000 0000 |  A23-A16  |        A15-A0        |
;              +-----------+-----------+----------------------+
;
;              For channels 5-7, DMACount is in Words, and
;              DMALinAdr holds the address as:
;
;              +-----------+-----------+----------------------+
;              |   31-24   |23-17 | 16 |         15-0         |
;              +-----------+-----------+----------------------+
;              | 0000 0000 |A23-A17 |0 |        A16-A1        |
;              +-----------+-----------+----------------------+
;
;
;------------------------------------------------------------------------------
DMAPg0to7            proc    near

DMAPg0:
	push 	si
        mov     si,0*16                         ; si = 16 * channel #
        jmp     short DMAPgN
DMAPg1:
	push 	si
        mov     si,1*16                         ; si = 16 * channel #
        jmp     short DMAPgN
DMAPg2:
	push 	si
        mov     si,2*16                         ; si = 16 * channel #
        jmp     short DMAPgN
DMAPg3:
	push 	si
        mov     si,3*16                         ; si = 16 * channel #
        jmp     short DMAPgN
DMAPg5:
	push 	si
        mov     si,5*16                         ; si = 16 * channel #
        jmp     short DMAPgN
DMAPg6:
	push 	si
        mov     si,6*16                         ; si = 16 * channel #
        jmp     short DMAPgN
DMAPg7:
	push 	si
        mov     si,7*16                         ; si = 16 * channel #
; FALL THROUGH

;----------------------------------------------------------------------
;       DMAPgN - Common Page Code
;
;       ENTRY: As above plus
;               si = 16 * Channel #
;
;----------------------------------------------------------------------

DMAPgN:
        push    ax
        push    bx
        push    cx
        push    dx
;
; Now, BX = port * 2 and DX = IO code
; Code ported from Win/386 expects DX = port and BH = IO code
;
	xchg	dx, bx
	shr     dx, 1
	xchg	bh,bl                          ; move IO code to bh

        or      bh,bh                           ;Q: Input ?
        jz      short Pg_rd_port                ;  Y: do Read operation

        mov     [SaveAL], al                    ; save AL in Save area.
;	
; Get s/w FF for WrtAdrReg
;
	mov	bl, [DMARegSav.DMAFF1]		; Assume Chan 1 FF
	cmp	si, 4*16			; Q: Addr for 2nd controller
	jb	short PgN_FF			; A: No, FF is correct
	mov	bl, [DMARegSav.DMAFF2]		; Chan 2 FF
PgN_FF:
	xor	bh, bh				; make BX = flip-flop state

        mov     byte ptr DMARegSav.DMALinAdr.HighWord[si], al ; save value
        call    DMA_DMAFixup                    ; Translate Lin to Phys
						; & Update DMARegSav
	call	DMA_WrtAdrReg 		        ; emulate the write
	jmp	short DPExit
Pg_rd_port:
        mov     al, byte ptr DMARegSav.DMALinAdr.HighWord[si]
        mov     [SaveAL], al
DPExit:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
	pop	si
        mov     al, [SaveAL]
        clc
        ret

DMAPg0to7            endp

        page

;******************************************************************************
;
;   DMAClrFF1 - Reset Controller 1's FlipFlop
;   DMAClrFF2 - Reset Controller 2's FlipFlop
;
;   ENTRY: 
;       AL = byte to output to port.
;       BX = port * 2
;       DH = 0 => Emulate Input.
;          <>0 => Emulate Output.
;
;   EXIT:  
;       AL = emulated input/output value from port.
;       CLC => I/O emulated or performed
;
;------------------------------------------------------------------------------

DMAClrFF1    proc    near
        push    ax
        push    bx
        push    cx
        push    dx
;
; Now, BX = port * 2 and DX = IO code
; Code ported from Win/386 expects DX = port and BH = IO code
;
	xchg	bx, dx
	shr     dx, 1
	xchg	bh,bl                          ; move IO code to bh

        or      bh,bh                           ;Q: Input ?
        jz      short DMA_CLF_RdEm              ;  Y: Let it go
        out     dx, al                          ;  N: do it
        mov     [DMARegSav.DMAFF1], 0
        jmp     short DMACFFexit
DMA_CLF_RdEm:
        in      al,dx                           ; do the read
DMACFFexit:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        clc
        ret

DMAClrFF1    endp

DMAClrFF2    proc    near

        push    ax
        push    bx
        push    cx
        push    dx
;
; Now, BX = port * 2 and DX = IO code
; Code ported from Win/386 expects DX = port and BH = IO code
;
	xchg	bx, dx
	shr     dx, 1
	xchg	bh,bl                          ; move IO code to bh

        or      bh,bh                           ;Q: Input ?
        jz      DMA_CLF_RdEm                    ;  Y: Let it go
        out     dx, al                          ;  N: do it
        mov     [DMARegSav.DMAFF2], 0
        jmp     DMACFFexit

DMAClrFF2    endp

        page
;******************************************************************************
;
;   DMAMode1 - Track Controller 1's Mode Register
;   DMAMode2 - Track Controller 2's Mode Register
;
;   ENTRY: 
;       AL = byte to output to port.
;       BX = port * 2
;       DX = 0 => Emulate Input.
;          <>0 => Emulate Output.
;
;   EXIT:  
;       AL = emulated input/output value from port.
;       CLC => I/O emulated or performed
;
;------------------------------------------------------------------------------

DMAMode1    proc    near
        push    ax
        push    bx
        push    cx
        push    dx
        push	si
;
; Now, BX = port * 2 and DX = IO code
; Code ported from Win/386 expects DX = port and BH = IO code
;
	xchg	bx, dx
	shr     dx, 1
	xchg	bh,bl                          ; move IO code to bh

        or      bh,bh				;Q: Input ?
        jz      short DMA_Mread		        ;  Y: Let it go

        mov     [SaveAL], al                    ; save AL in Save area.
	xor	ah, ah
	mov	si, ax
	and	si, DMA_M_CHANNEL
	mov	bl, al
	and	bl, NOT DMA_M_16BIT		; 8 bit xfers for controller 1
DMA_Mboth:
	shl	si, 4				; Channel * 16
	mov	[DMARegSav.DMAMode][si], bl
        out     dx, al                          ;  N: do it
	jmp	short DMExit

DMA_Mread:
        in      al, dx				; do the read
        mov     [SaveAL], al
DMExit:
	pop	si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        mov     al, [SaveAL]
        clc
        ret
DMAMode1    endp

DMAMode2    proc    near

        push    ax
        push    bx
        push    cx
        push    dx
        push	si
;
; Now, BX = port * 2 and DX = IO code
; Code ported from Win/386 expects DX = port and BH = IO code
;
	xchg	bx, dx
	shr     dx, 1
	xchg	bh,bl                          ; move IO code to bh

        or      bh,bh				;Q: Input ?
        jz      DMA_Mread			;  Y: Let it go

        mov     [SaveAL], al                    ; save AL in Save area.
	xor	ah, ah
	mov	si, ax
	and	si, DMA_M_CHANNEL
	add	si, 4				; Channel 4 to 7
	mov	bl, al
	or	bl, DMA_M_16BIT			; 16 bit for controller 2
	jmp	DMA_Mboth

DMAMode2    endp

;	INCLUDE VDMAD2.ASM

        page
;******************************************************************************
;DMA_GetLinAdr - return Linear Address, count and mode from DMARegSave area
;
;   ENTRY: 
;               si = channel # * 16
;               DS assume DGROUP
;
;   EXIT:  
;               EAX = linear Base Address
;               ECX = SIZE of transfer (bytes)
;		 DL = Mode register
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
DMA_GetLinAdr proc    near

        mov     eax, dword ptr DMARegSav.DMALinAdr[si]
        mov     ecx, dword ptr DMARegSav.DMACount[si]
        mov     dl, byte ptr DMARegSav.DMAMode[si]
        inc     ecx                             ; ECX = SIZE of transfer
	test	dl, DMA_M_16BIT			; Word transfer?
        jz      short GLexit                    ; N: no special treatment

        DMA_WADDR_TO_BADDR			; Y: fixup values from regs
GLexit:
        ret

DMA_GetLinAdr endp

        page
;******************************************************************************
;   DMA_SetPhyAdr - Load the Page and Base DMA registers with the input
;               Physical Address and save this addr as current phy addr.
;
;   ENTRY: 
;               EAX = physical address
;               SI = DMA channel # * 16
;               DS -> DGROUP
;
;   USED:  Flags
;------------------------------------------------------------------------------
DMA_SetPhyAdr proc    near
;
        push    eax
        push    bx
        push    dx

	xor	bh, bh
        mov     bl, [DMARegSav.DMAFF1]
        cmp     si,4*16				; 2nd cntlr?
        jb      short DMA_SPA1
        mov     bl, [DMARegSav.DMAFF2]		;   yes, other flip-flop
DMA_SPA1:
	test	[DMARegSav.DMAMode][si], DMA_M_16BIT	; word transfer?
	jz	short SaveIt			;   no, no translation
        DMA_BADDR_TO_WADDR
SaveIt:
        mov     dword ptr DMARegSav.DMAPhyAdr[si], eax

        ; set page register
	xor	dh, dh
        mov     dl, byte ptr DMARegSav.DMAPagePort[si]
        mov     al, byte ptr DMARegSav.DMAPhyAdr.HighWord[si]
        out     dx, al

        ; set base address register
        mov     dl, byte ptr DMARegSav.DMABasePort[si]
        mov     al, byte ptr DMARegSav.DMAPhyAdr[si][bx]
        out     dx,al                           ; send out 1st byte
        xor     bl,1                            ; toggle FF
        jmp     $+2
        jmp     $+2
        mov     al, byte ptr DMARegSav.DMAPhyAdr[si][bx]
        out     dx,al                           ; send out other byte
        xor     bl,1                            ; toggle FF to original state

        pop     dx
        pop     bx
        pop     eax
        ret
;
DMA_SetPhyAdr endp

        page
;******************************************************************************
;   DMALoadCount - Load the Count DMA register with the input
;
;   ENTRY: 
;               si = DMA channel # * 16
;
;------------------------------------------------------------------------------
DMALoadCount  proc    near
        push    bx
        push    ax
        push    dx

	xor	bh, bh
        mov     bl, byte ptr [DMARegSav.DMAFF1]
        cmp     si,4*16                         ;Q: Adrs from 2nd cntlr
        jb      short DMA_SC1                   ; N: save it as is
        mov     bl, byte ptr [DMARegSav.DMAFF2]

DMA_SC1:
        mov     dl, byte ptr DMARegSav.DMACntPort[si]
	xor	dh, dh
        mov     al, byte ptr DMARegSav.DMACount[bx][si]
        out     dx, al
        jmp     $+2
        jmp     $+2
        xor     bl, 1
        mov     al, byte ptr DMARegSav.DMACount[bx][si]
        out     dx, al

        pop     dx
        pop     ax
        pop     bx
        ret

DMALoadCount  endp

        page
;******************************************************************************
;   DMA_DMAFixup - Fixup Linear to Physical mapping for DMA
;
;   ENTRY: 
;               SI = 16 * channel #
;               DS assume DGROUP
;
;   EXIT:  
;               DMARegSav is updated
;
;   USED:  flags, registers (calls a C program, so most registers are trashed)
;
;  Check to see if DMA Page fixup is needed.
;  We test for the following cases for optimization:
;       Lin Base Add == Lin Page Reg == 0, assume that transfer addr
;               is not yet valid
;
;------------------------------------------------------------------------------
DMA_DMAFixup  proc    near
                                                ;Q: LinAddr = 0?

        mov     eax, dword ptr DMARegSav.DMALinAdr[si]
        or      eax,eax                         
        jz      short DMA_nofixup               ; Y:DMA not programmed yet
                                                ;Do the fixup.....
	pushfd					; ENABLE INTERRUPTS!
        push    bx                              ; C code trashes these regs
        push    es
;
; long SwapDMAPages(LinAdr, Len, XferSize);
; long LinAdr, Len;
; unsigned XferSize; 0/1 Byte/word Xfer
;
	movzx	eax, [DMARegSav.DMAMode][si]
	and	al, DMA_M_16BIT			; Non-zero for 16bit transfer
	push	ax                              ; push XferSize

        call    DMA_GetLinAdr
	push	ecx				; push count
        push    eax                             ; push LinAdr
;
; C code saves di si bp ds ss sp

	call	_SwapDMAPages 		        ; C program to do the dirty work

        xchg    ax, dx
        shl     eax, 16
        mov     ax, dx                          ; eax = returned value

	add	sp, 10				; clean up stack

        pop     es
        pop     bx
        popfd					; Restore original FLAGS state

	test	[DMARegSav.DMAMode][si], DMA_M_16BIT	; word transfer?
	jz	short SavIt				;   no, no translation
	DMA_BADDR_TO_WADDR			; Y: Put in special format
SavIt:
        mov     dword ptr DMARegSav.DMAPhyAdr[si], eax
	clc					; Done fixup
	ret
DMA_nofixup:
	stc
	ret

DMA_DMAFixup  endp

        page
;******************************************************************************
;   DMA_WrtAdrReg - Write registers associated with DMA address
;
;   ENTRY: 
;               BX = Flip Flop State, 0 or 1
;               SI = channel # * 16
;               DS assume DGROUP
;               Uses Values in DMARegSav
;
;   EXIT:  
;
;   USED:  Flags, EAX
;   STACK:
;------------------------------------------------------------------------------
DMA_WrtAdrReg proc    near

; Must Update Page and Base registers simultaneously when remapping occurs...
	push	bx
	push	dx

        and     bx, 1                           ; Lose extra bit just in case...
						; Base Register...
	xor	dh, dh				; clear high byte

						; NOTE: Internal flip-
						; flop flag not updated,
						; since we write twice....
                                                ; BX = flip flop state

        mov     dl, byte ptr DMARegSav.DMABasePort[si]
        mov     al, byte ptr DMARegSav.DMAPhyAdr[bx][si]
        out     dx, al                          ; output the byte
        jmp     $+2                             ; timing
        jmp     $+2                             ; timing
        xor     bx, 1                           ; toggle flip-flop

        mov     al, byte ptr DMARegSav.DMAPhyAdr[bx][si]
        out     dx, al                          ; output the byte
        jmp     $+2                             ; timing
        jmp     $+2                             ; timing
        xor     bx, 1                           ; toggle flip-flop

						; Page Register...
        mov     al, byte ptr DMARegSav.DMAPhyAdr.HighWord[si] ; fetch value
        mov     dl, byte ptr DMARegSav.DMAPagePort[si]
        out     dx,al                           ; output the byte

	pop	dx
	pop	bx
        ret

DMA_WrtAdrReg endp

	page
;******************************************************************************
;   InitELIM - initialize LIM h/w trapping data structures and
;		I/O bit map for this ports.
;
;		NOTE: this is a FAR routine
;
;   ENTRY: Real Mode
;
;   EXIT:  Real Mode
;	   TSS:[IOBitMap] - LIM addresses entered in I/O bit map
;
;   USED:  Flags
;   STACK:
;------------------------------------------------------------------------------
InitELIM proc	 far

	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	ds
	push	es

	cld

	mov	ax,seg DGROUP
	mov	ds,ax
;
; now set entries in I/O Bit Map
;
	mov	ax,TSS
	mov	es,ax				; ES -> TSS
;
;   now set DMA ports in I/O Bit Map
;
	mov	cx,LIMDMAP_CNT
	mov	si,offset DGROUP:DMAP_Page	; DS:SI -> DMA ports
	mov	bx,8000h			; trap it every 1k
IE_maploop:
	lodsw					; AX = port to trap
	call	PortTrap			; set bit(s) for this port
	loop	IE_maploop			;if more ...

	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret

InitELIM endp


;
; C callable routines for manipulating page table entries.
; and Current FRS - CurRegSet


;
; Equates for picking up arguments passed in from C code.
; Arg1 - word Arg,
; Arg2 - word or dword Arg
;

Arg1	equ	[BP+4]
Arg2	equ	[BP+6]


;*****************************************************************************
;
;  _GetPte - called from C code
;
;  return pte in dx:ax
;
;  long GetPte(PTIndex)
;  unsigned PTIndex;
;
;  Written: JHB Aug 10,1988
;  Modif:   ISP Aug 12,1988 parameter should be returned in dx:ax not eax
;			    removed some of pushes and pops
;			    added cld before load just to be safe
;			    offset specified in DGROUP
;
;           JHB Aug 21 88   changed input param to PTIndex
;
;*****************************************************************************

_GetPte	proc	near

	push	bp
	mov	bp, sp
	push	si
	push	ds
	
        mov     ax, PAGET_GSEL
        mov     ds, ax

        mov     si, WORD PTR Arg1
        shl     si, 2                   ; dword entries in the PT

	cld
        lodsw                   ; get low word
        mov     dx, ax          ; into dx
        lodsw                   ; get hiword 
        xchg    dx, ax          ; dx:ax = long return value

	pop	ds
	pop	si
	pop	bp
	ret
_GetPte	endp

;*****************************************************************************
;
; _SetPte - called from C code
;
; Locate the PT entry for given EmmPhyPage and set it to pte.
;
; SetPte(PTIndex, pte)
; unsigned PTIndex;
; long pte;
;
; WRITTEN:  JHB Aug 10,1988
; MODIF:    ISP Aug 12,1988 pushes and pops removed
;			    cld added for safety
;			    offset specified in DGROUP
;			    pushed poped eax (check on this)
;
;           JHB Aug 21, 1988 changed first input param to PTIndex
;
;*****************************************************************************


_SetPte	proc	near
	
	push	bp
	mov	bp, sp
        push    di
        push    es

        mov     ax, PAGET_GSEL
        mov     es, ax
        mov     di, WORD PTR Arg1
        shl     di, 2

	mov	eax, DWORD PTR Arg2 
	and	ax, 0F000H	                ; clear low 12 bits
	or 	ax, P_AVAIL	; page control bits - user, present, write

	cld
      	stosd
;
;   reload CR3 to flush TLB 
;
        mov     eax, CR3
        mov     CR3, eax
        
;	mov	eax,dword ptr [Page_Dir]        ; mov EAX,dword ptr [Page_Dir]
;	db	0Fh,22h,18h		        ; mov CR3,EAX

        pop     es
        pop     di
	pop	bp
	ret
_SetPte	endp

;*****************************************************************************
;
; _GetCRSEntry - called from C code
;
; return the Emm page mapped to the EmmPhyPage by looking up CurRegSet.
;
; unsigned GetCRSEntry(EmmPhyPage)
; unsigned EmmPhyPage
;
; WRITTEN:  JHB Aug 10,1988
; MODIF:    ISP Aug 12,1988 pushes and pops removed
;			    Offset specified in DGROUP
;			    cld added for safety
;*****************************************************************************

_GetCRSEntry	proc near

	push	bp
	mov	bp, sp
	push	di
	
	mov	bx, WORD PTR Arg1
	shl	bx, 1		                ; each FRS entry is a word
	Get_FRS_Window	DI	                ; di = address of Current FRS
	add	di, bx
	mov	ax, word ptr [di]               ; load FRS entry

	pop	di
	pop	bp
	ret
_GetCRSEntry	endp

;
; Equates for picking up long Arguments from C code
; LArg1 - long Arg
; Larg2 - long Arg when the first Arg is also long
;

LArg1	equ	[BP+4]
LArg2	equ	[BP+8]

;*****************************************************************************
;
; _GetDMALinAdr - called from C code
;
; returns the Lin Adr for the DMA buffer whose physical adr is given
;
; long GetDMALinAdr(DMAPhyAdr)
; long DMAPhyAdr;
; 
; Get the Linear address for DMAPhyAdr. There is a pte which always 
; maps to this always. MapLinear translates DMAPhyAdr to a linear adr.
;
;
; 8/12/88       JHB     removed _Copy16K, changed it to this routine.
;
;*****************************************************************************

_GetDMALinAdr proc near

	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds
;
; convert the DMAPhyAdr into a linear address.
;
	mov	eax, dword ptr LArg1
	call	MapLinear
;
;	eax = 32 bit linear adr for the DMA Xfer area.
;
        ror     eax, 16
        mov     dx, ax
        ror     eax, 16         ; dx:ax 32 bit linear adr to be returned

	pop	ds
	pop	di
	pop	si
	pop	bp
	ret
_GetDMALinAdr	endp
	
;******************************************************************************
;
;	set_selector - set up a selector address/attrib
;
;	ENTRY:	EAX = address for GDT selector - a linear address
;		DI = GDT selector
;	EXIT:	selector in DI is writeable data segment,128k long and points
;		to desired address.
;
;******************************************************************************

set_selector	proc	near

	push	eax
	push	di
	push	es

	and	di,NOT 07h		; just in case... GDT entry
	push	GDTD_GSEL
	pop	es			; ES:DI -> selector entry

	mov	es:[di+2],ax		; low word of base address

	shr	eax,16			; AX = high word of address
	mov	es:[di+4],al		; low byte of high word of address
	xor	al,al			; clear limit/G bit
	or	al, 1			; set LSB0 i.e. Limit16 bit for 128K Xfer
	mov	es:[di+6],ax		; set high byte of high word of addr
					;   and high nibble of limit/G bit
                                        ;   and Limit Bit 16 for 128K transfer
	mov	ax,0FFFFh
	mov	es:[di],ax		; set limit bits 0-15
	
	mov	al,D_DATA0		; writeable DATA seg / ring 0
	mov	es:[di+5],al

	pop	es	
	pop	di
	pop	eax

	ret

set_selector	endp

;****************************************************************************
; _Exchange16K - called from C 
;
; Exchange contents of the pages at LinAdr1 and LinAdr2
; 
; Exchange16K(LinAdr1, LinAdr2)
; long	LinAdr1, LinAdr2;
;
; Written:  JHB Aug 11, 1988
;	    ISP Aug 12, 1988	    Added cld.
;				    DWORD PTR mentioned explicitly
;*****************************************************************************

_Exchange16K proc near

	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds

	mov	di,MBSRC_GSEL			; source selector
	mov	eax,dword ptr LArg1		; load linear adr
	call	set_selector			; set up a selector in GDT
	mov	es,di

	mov	di,MBTAR_GSEL			; destination selector
	mov	eax,dword ptr LArg2
	call	set_selector			; set up selector
	mov	ds,di
	mov	cx,1000h			; 16k bytes (4 at a time)
	xor	di,di				; initialize index
	cld
sloop:
	mov	eax,dword ptr es:[di]		; pick a dword at LArg1
	xchg	eax,dword ptr ds:[di]		; swap with dword at LArg2
	stosd					; store new dword at LArg1
	loop	sloop				

	pop	ds
	pop	di
	pop	si
	pop	bp
	ret

_Exchange16K endp

; 
; signals an exception error
;
_FatalError proc near

	push	bp
	mov	bp, sp

        mov     ax, 1
        mov     bx, 3
        call    ErrHndlr

	pop	bp
	ret

_FatalError endp

_TEXT	ends				        ; end of segment

end				                ; end of module
 
