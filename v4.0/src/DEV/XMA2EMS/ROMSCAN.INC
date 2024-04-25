
	page
;-------------------------------------------------------------------
;
;	This file contains the code to do a pseudo-rom scan looking
;	for possible EMS holes
;
;-------------------------------------------------------------------



romscan proc	near

	push	ax
	push	dx
	push	cx
	push	di

	push	cs			; make es and ds point to segment where messages are
	pop	es

	push	cs
	pop	ds

;	must do rom scan with interrupts disabled

	cli

;------------------------

	cmp	map_count,0		; no segments specified, do rom scan
	je	no_pages_spec

	mov	cx,map_count		; number of segments to check
	xor	di,di			; use di as pointer into table

check_segs:
	mov	ax,map_table.phys_page_segment[di]

	call	CHK_FREE_SEGMENT	; check a 16K block
	jnc	segment_ok

;	display the error

	mov	segment_error,1 	; set segment error flag


;	display conflict message

	push	ax			; save some regs
	push	dx
	push	di

	MOV	DI,OFFSET confl_address ; ascii string page frame
	CALL	CNVHEXAT

	MOV	DX,OFFSET conflict_msg	; start of message
	MOV	AH,9			; dos prt string
	INT	21H			;

	pop	di			; restore some regs
	pop	dx
	pop	ax

segment_ok:
	add	di,type mappable_phys_page_struct
	loop	check_segs

;------------------------
;	if there were no conflicts, then exit with no error

	cmp	segment_error,0
	je	rom_scan_no_error	; exit with no error (carry = 0)

;------------------------

	MOV	DX,OFFSET CRLF		; skip a blank line
	MOV	AH,9			; dos prt string
	INT	21H			;

	jmp	rom_scan_code

;	display no pages message

no_pages_spec:
	MOV	DX,OFFSET NO_PAGES_MSG	; skip a blank line
	MOV	AH,9			; dos prt string
	INT	21H

	MOV	DX,OFFSET CRLF		; skip a blank line
	MOV	AH,9			; dos prt string
	INT	21H			;

;-------------------------------------------------------------------
;
;	This routine scans the address range from c000 - FFFF looking
;	for 16 K gaps.
;
;-------------------------------------------------------------------

rom_scan_code:

	mov	ax,0c000h		; start at c000
	xor	bx,bx			; bx holds count of contiguous pages
	mov	cx,15			; loop counter
	mov	dx,ax			; dx holds start of frame

fam2_loop:
	call	CHK_FREE_SEGMENT	; check a 16K block
	jc	bad_seg

;	good 16 segment

	call	FoundBlock

	add	bx,1			; add another page to frame counter
	cmp	bx,4			; 4 means frame is found
	jne	no_frame_yet

;	a frame has been found

	mov	bx,100			; make sure we don't look for more frames

no_frame_yet:
	add	ax,0400h		; point to next segment
	jmp	continue_loop

;	bad 16 segment

bad_seg:
	add	ax,0400h		; point to next segment
	cmp	bx,100
	jae	continue_loop		; don't reset frame info if one has been found

	xor	bx,bx			; clear contiguous page counter
	mov	dx,ax			; make frame pointer point to next page

continue_loop:

	loop	fam2_loop
	jmp	rom_scan_exit


rom_scan_no_error:
	clc
	jmp	clean_exit


;-------------------------------------------------------------------

rom_scan_exit:

;	display frame if found

	cmp	bx,100			; >= 100 means frame was found
	jb	no_frame_exit

	mov	ax,dx			; get frame address in ax
	call	FoundFrame		; display frame address


no_frame_exit:
	STC				; carry = 1 means error

clean_exit:
	sti


	pop	di
	pop	dx
	pop	cx
	pop	ax

	ret

romscan endp



;-------------------------------------------------------------------
;
;	FoundBlock assumes AX = segment address of good 16 K block
;
;-------------------------------------------------------------------

FoundBlock	proc	near

	push	ax
	push	dx
	push	es
	push	di

	push	cs
	pop	es

	push	cs
	pop	ds

	MOV	DI,OFFSET hole_address	; ascii string page frame
	CALL	CNVHEXAT

	MOV	DX,OFFSET hole_msg	; start of message
	MOV	AH,9			; dos prt string
	INT	21H			;


	pop	di
	pop	es
	pop	dx
	pop	ax

	ret

FoundBlock	endp

;-------------------------------------------------------------------
;
;	FoundFrame assumes AX = segment address of good 64 K block
;
;-------------------------------------------------------------------

FoundFrame	proc	near

	push	ax
	push	dx
	push	es
	push	di

	push	cs
	pop	es

	push	cs
	pop	ds

	MOV	DI,OFFSET frame_address  ; ascii string page frame
	CALL	CNVHEXAT

	MOV	DX,OFFSET frame_msg	 ; start of message
	MOV	AH,9			; dos prt string
	INT	21H			;


	pop	di
	pop	es
	pop	dx
	pop	ax

	ret

FoundFrame	endp






;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;------------------------------------------------------------------------
;							    03/04/88 jwg:
;  PROCEDURE NAME:  CHK_FREE_SEGMENT					:
;									:
;  THIS PROCEDURE CHECKS EACH OF THE 2K BOUNDARIES IN THE 16K SEGMENT	:
;  TO DETERMINE IF A ROM SEGMENT IS EMPTY.  IT VERIFIES THAT NO ROM	:
;  FROM A PRECEEDING ADDRESS EXTENDS INTO THIS 16K SEGMENT.  ALSO THE	:
;  16K BLOCK IS CHECKED FOR THE PRESENCE OF ANY RESPONDING CARD.	:
;									:
;  ENTRY: AX - CONTAINS 16K SEGMENT ADDRESS				:
;  EXIT: CARRY FLAG = 0 - SEGMENT FREE					:
;	 CARRY FLAG = 1 - SEGMENT IN USE				:
;									:
;------------------------------------------------------------------------

ROM_SCAN	EQU	0AA55H
CARD_SEL_PORT	EQU	091h		; CARD SELECTED LATCH PORT


CHK_FREE_SEGMENT    PROC  NEAR

	PUSH	AX			; Save work registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	ES			; Save data segment register
	MOV	BX,AX			; Save segment start address
	MOV	CX,AX			; Save in work register
	ADD	CX,0400h		; Determine End segment address of FIFE
;	MOV	DX,0C000h-00100h	; Get address of start of ROM area
	mov	dx,ax			; gga
	sub	dx,0100h		; gga
CHK_FREE_NEXT:
	ADD	DX,00100h		; Add offset to get next 2K segment
	CMP	DX,CX			; Check for past end of 16K ROM area
	JAE	CHK_FREE_OK		; IF (NC) then Exit, segment was free

					;	CHECK FOR ROM BLOCK SIGNATURE
	MOV	ES,DX			; Change to new ROM segment
	CMP	ES:WORD PTR [0],ROM_SCAN; Check if a ROM module is present
	JE	CHK_FREE_SIZE		; Go check length if ROM SCAN signature

	CMP	BX,DX			; Check if into the target segment yet
	JA	CHK_FREE_NEXT		; Loop and check next 2K block in not

					;	CHECK FOR CARD RESPONDING IN 2K
	NOP				; Following sequence can not be traced..
;;;;;	CALL	CARD_SEL_NOW		; Reset CARD SELECTED FEED BACK latch  .
	XOR	DI,DI			; Clear source pointer		       .
	MOV	AX,0FFFFh		; Get expected floating bus pattern    .
	PUSH	CX			; Save CX			       .
	MOV	CX,00400h		; Get count of 1 K words (2K bytes)    .
	REPE	SCASW			; Check for all bits on in block ES:DI .
	POP	CX			; Recover end segment address	       .
	JNE	CHK_FREE_ERROR		; Exit if anything there	       .

;;;;;;	cmp	rom_scan_type,family1	; gga only do the card select check on PS2's
;;;;;;	je	skip_ps2_check

;;;;;;	CALL	CARD_SEL_NOW		; Check for a CARD SELECTED by scan    .
;;;;;;	JC	CHK_FREE_ERROR		; Exit (CY) if a card responded ........

;;;;;;skip_ps2_check:
	JMP	CHK_FREE_NEXT		; ELSE check next 2K address

CHK_FREE_SIZE:				;	CHECK LENGTH INTO 16K SEGMENT
	push	cx			; gga
	MOV	AL,ES:BYTE PTR [2]	; Get ROM module length in 512 bytes
	MOV	AH,0			; Clear high byte
	mov	cl,5			; gga
	SHL	AX,cl			; gga convert to segment length (16 byte)
	pop	cx			; gga
	ADD	AX,DX			; Determine ending segment size
	CMP	BX,AX			; Does ROM extend into this 16K segment
	JNB	CHK_FREE_NEXT		; IF not then continue search

CHK_FREE_ERROR:
	STC				; ELSE (CY), Exit with segment not free
CHK_FREE_OK:
	POP	ES			; restore segment register
	POP	DI
	POP	DX
	POP	CX			; restore all registers
	POP	BX
	POP	AX
	RET				; EXIT (NC) if segment free to test

CHK_FREE_SEGMENT    ENDP


;------------------------------------------------------------------------
;							    03/04/88 jwg:
;  PROCEDURE NAME:  CARD_SEL_FBK					:
;									:
;  THIS PROCEDURE CHECKS THE CARD SELECTED FEEDBACK LINE AND LATCH	:
;  TO VERIFY THAT THIS LINE WAS ACTIVATED.  METHOD IS TO CLEAR THE	:
;  LATCH AND READ A LOCATION USING THE PASSED SEGMENT ADDRESS.	IF	:
;  ANY CARD RESPONDS THE LATCH WILL BE SET ON.				:
;									:
;    NOTE:  These routines can not be traced with a debug-er		:
;	    as VIDEO updates also set the card selected latch.		:
;									:
; ENTRY: AX - ADDRESS OF SELECTED SEGMENT				:
;									:
;  EXIT: CARRY FLAG = 0 - CARD SELECTED LATCH WAS NOT SET (OFF) 	:
;	 CARRY FLAG = 1 - CARD SELECTED LATCH WAS SET BY TEST		:
;									:
;------------------------------------------------------------------------

;;;;;CARD_SEL_FBK    PROC    NEAR	     ;	     TEST CARD SELECTED FEED BACK

;;;;;	     CLI			     ; Block interrupts during operation
;;;;;	     CALL    CARD_SEL_NOW	     ; Read current port value to clear
;;;;;	     PUSH    DS 		     ; Save segment register
;;;;;	     MOV     DS,AX		     ; Set segment
;;;;;	     CMP     DS:BYTE PTR [0],AL      ; Read first byte with dummy compare
;;;;;	     POP     DS 		     ; Restore segment selector
;;;;;	     CALL    CARD_SEL_NOW	     ; Read current port value and clear
;;;;;	     STI			     ; Enable interrupts
;;;;;	     RET			     ; RETurn (CY)= 1 if latch	set by read

;;;;;CARD_SEL_FBK    ENDP

;------------------------------------------------------------------------
;							    03/04/88 jwg:
;  PROCEDURE NAME:  CARD_SEL_NOW  (CURRENT VALUE)			:
;									:
;  THIS PROCEDURE READS AND RESETS THE CURRENT CARD SELECTED FEEDBACK	:
;  LATCH AND RETURNS THE STATUS.					:
;									:
;    NOTE:  This routine can not be traced with a debug-er		:
;	    as VIDEO updates also set the card selected latch.		:
;									:
; ENTRY: NONE								:
;									:
;  EXIT: CARRY FLAG = 0 - CARD SELECTED LATCH WAS NOT SET (OFF) 	:
;	 CARRY FLAG = 1 - CARD SELECTED LATCH WAS SET ON WHEN READ	:
;									:
;------------------------------------------------------------------------

;;;;;CARD_SEL_NOW    PROC    NEAR	     ;	     READ CARD SELECTED FEED BACK

;;;;;	     PUSH    AX 		     ; Save segment address
;;;;;	     IN      AL,CARD_SEL_PORT	     ; Read current port value and clear
;;;;;	     RCR     AL,1		     ; Move bit 0 into CY flag
;;;;;	     POP     AX 		     ; Recover segment address
;;;;;	     RET			     ; RETurn (CY)= 0 if latch set

;;;;;CARD_SEL_NOW    ENDP

