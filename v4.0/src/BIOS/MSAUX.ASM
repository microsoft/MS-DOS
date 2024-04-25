	TITLE MSAUX - DOS 3.3
;----------------------------------------------------------------
;								:
;	     A U X - AUXILARY DEVICE DRIVER			:
;								:
;								:
;   This file contains the Auxilary Device Driver.  The 	:
; auxilary driver handles calls to and from the RS-232 port.	:
; Three devices uses this code: AUX, COM1, and COM2.  AUX and	:
; COM1 talk to the zero RS-232 card and COM2 talks to the	:
; 'one' RS-232 card.  The beginning of the interrupt entry      :
; point for these devices sets the variable AUXNUM in the	:
; msbio.asm module.  If the value is 0 the routines in this	:
; file will talk to the the 'zero' card.  If the value in       :
; AUXNUM is 1 the routines will talk to the 'one' card.         :
; The procedure GETDX is called to put the value 0 or 1 in	:
; the DX register depending on the value in AUXBUF.		:
;								:
;   The routines in this files are:				:
;								:
;	routine 		function			:
;	------- 		--------			:
;	AUX$READ		Read characters from the	:
;				  specified device.		:
;	AUX$RDND		Non-desrucrtive read with	:
;				  no waiting.			:
;	AUX$FLSH		Flush specified device input	:
;				  buffer.			:
;	AUX$WRIT		Write characters to the 	:
;				  specified device.		:
;	AUX$WRST		Get status of specified 	:
;				  device			:
;								:
;  These routines are not called directly.  Call are made via	:
; the strategy and interrupt entry point (see Device Header).	:
;								:
;  Data structure:						:
;    The Aux Device has a two byte buffer called AUXBUF.  The	:
;  first byte is for the zero card, the second byte is for the	:
;  one card.  A zero value in the byte indicates the buffer is	:
;  empty.  The routines use GETBX to get the address of the	:
;  buffer.							:
;								:
;----------------------------------------------------------------

;;Ver 3.30 modification ---------------------------
	itest=0
	INCLUDE MSGROUP.INC	;DEFINE CODE SEGMENT
	INCLUDE JUMPMAC.INC
	INCLUDE MSMACRO.INC

	EXTRN ERR$CNT:NEAR	;MSBIO1
	EXTRN GETDX:NEAR	;MSBIO1
	EXTRN RDEXIT:NEAR	;MSCON
	EXTRN EXIT:NEAR 	;MSBIO1
	EXTRN BUS$EXIT:NEAR	;MSBIO1
				;DATA
	EXTRN AUXBUF:BYTE	;MSDATA

;		VALUES IN AH, REQUESTING FUNCTION OF INT 14H IN ROM BIOS
AUXFUNC_SEND	 EQU	1	;TRANSMIT
AUXFUNC_RECEIVE  EQU	2	;READ
AUXFUNC_STATUS	 EQU	3	;REQUEST STATUS

;		ERROR FLAGS, REPORTED BY INT 14H

;	 THESE FLAGS REPORTED IN AH:
FLAG_DATA_READY  EQU	01H	;DATA READY
FLAG_OVERRUN	 EQU	02H	;OVERRUN ERROR
FLAG_PARITY	 EQU	04H	;PARITY ERROR
FLAG_FRAME	 EQU	08H	;FRAMING ERROR
FLAG_BREAK	 EQU	10H	;BREAK DETECT
FLAG_TRANHOL_EMP EQU	20H	;TRANSMIT HOLDING REGISTER EMPTY
FLAG_TRANSHF_EMP EQU	40H	;TRANSMIT SHIFT REGISTER EMPTY
FLAG_TIMEOUT	 EQU	80H	;TIMEOUT

;	THESE FLAGS REPORTED IN AL:
FLAG_DELTA_CTS	 EQU	01H	;DELTA CLEAR TO SEND
FLAG_DELTA_DSR	 EQU	02H	;DELTA DATA SET READY
FLAG_TRAIL_RING  EQU	04H	;TRAILING EDGE RING INDICATOR
FLAG_DELTA_SIG	 EQU	08H	;DELTA RECEIVE LINE SIGNAL DETECT
FLAG_CTS	 EQU	10H	;CLEAR TO SEND
FLAG_DSR	 EQU	20H	;DATA SET READY
FLAG_RING	 EQU	40H	;RING INDICATOR
FLAG_REC_SIG	 EQU	80H	;RECEIVE LINE SIGNAL DETECT
;;End of modification ------------------


;----------------------------------------------------------------
;								  :
;	Read zero or more characters from Auxilary Device	  :
;								  :
;	input:es:[di] points to area to receive aux data	  :
;	      cx has number of bytes to be read 		  :
;	      "auxnum" first byte has number of aux device (rel 0):
;								  :
;----------------------------------------------------------------
	PUBLIC AUX$READ
AUX$READ PROC NEAR
	ASSUME	DS:CODE 	; SET BY AUX DEVICE DRIVER ENTRY ROUTINE
	jcxz	EXVEC2		; if no characters, get out
	call	GETBX		; put address of AUXBUF in BX
	xor	AX,AX		; clear AX register
	xchg	AL,[BX] 	; Get character , if any, from
				;   buffer and clear buffer
	or	AL,AL		; if AL is nonzero there was a
				;   character in the buffer
	jnz	AUX2		; if so skip AUXIN call
AUX1:				;
	call	AUXIN		; get character from port
AUX2:				;
	stosb			; store character
	loop	AUX1		; if more character, go around again
EXVEC2: 			;
	Jump	EXIT		; all done, successful exit
AUX$READ ENDP

;
; AUXIN: make a call on ROM BIOS to read character from
;	 the auxilary device, then do some error checking.
;	 If an error occurs then AUXIN jumps to ERR$CNT and
;	 does NOT return to where it was called from.
;

AUXIN	PROC	NEAR

	mov	ah,AUXFUNC_RECEIVE
	call	AUXOP
	 			;check for Frame, Parity, or Overrun errors
	 			;WARNING: these error bits are unpredictable 
	 			;         if timeout (bit 7) is set
	test	ah,FLAG_FRAME or FLAG_PARITY or FLAG_OVERRUN
	jz	AROK		;No error if all bits are clear

	 ;Error getting character
	add	sp,+2		;Remove rtn address (near call)
	xor	al,al
	or	al,FLAG_REC_SIG or FLAG_DSR or FLAG_CTS

	JUMP	ERR$CNT
AROK:
	RET			;CHAR JUST READ IS IN AL, STATUS IS IN AH
AUXIN	ENDP

;----------------------------------------------------------------
;								:
;	Aux non-destructive read with no waiting		:
;								:
;	input: es:[di] points to area to receive aux data	:
;								:
;----------------------------------------------------------------
;
	PUBLIC	AUX$RDND
AUX$RDND PROC	NEAR
	ASSUME	DS:CODE 	; SET BY AUX DEVICE DRIVER ENTRY ROUTINE
	call	GETBX		; have BX point to AUXBUF
	mov	AL,[BX] 	; copy contents of buffer to AL
	or	AL,AL		; if AL is non-zero (char in buffer)
	jnz	AUXRDX		;   then return character
	call	AUXSTAT 	;   if not, get status of AUX device
	TEST	AH,FLAG_DATA_READY ;TEST DATA READY
	jz	AUXBUS		;   then device is busy (not ready)

	TEST	AL,FLAG_DSR	;TEST DATA SET READY
	jz	AUXBUS		;   then device is busy (not ready)
	call	AUXIN		;   else aux is ready, get character
	call	GETBX		; have bx point to AUXBUF
	mov	[BX],AL 	; save character in buffer
AUXRDX: 			;
	Jump	RDEXIT		; return character

AUXBUS: 			;
	Jump	BUS$EXIT	; jump to device busy exit
AUX$RDND ENDP

;----------------------------------------------------------------
;								:
;		Aux Output Status				:
;								:
;----------------------------------------------------------------
	PUBLIC AUX$WRST
AUX$WRST PROC	NEAR
	ASSUME	DS:CODE 	; SET BY AUX DEVICE DRIVER ENTRY ROUTINE
	call	AUXSTAT 	; get status of AUX in AX
				; now test to see if device is busy
				; if this bit is not set,
;;Ver 3.30 modification -----------------------
	TEST	AL,FLAG_DSR	;TEST DATA SET READY
	jz	AUXBUS		;   then device is busy (not ready)
	TEST	AH,FLAG_TRANHOL_EMP ;TEST TRANSMIT HOLD REG EMPTY
;;End of modification -------------------------
	jz	AUXBUS		;   then device is busy (not ready)
	Jump	Exit

AUX$WRST ENDP

;
; AUXSTAT makes a call on the ROM-BIOS to determine the status
;	  of the auxilary device
;	  Outputs:
;		AX is filled with status of port.
;		DX is changes to specify which card - either 0, 1 (, 2, 3) ;ba
;		NO other registers are modified
;

AUXSTAT	proc near
	mov	ah,AUXFUNC_STATUS
	call	AUXOP
	ret
AUXSTAT endp

AUXOP	PROC	NEAR
				;AH=FUNCTION CODE
				;0=INIT, 1=SEND, 2=RECEIVE, 3=STATUS
	call	GETDX		; have DX point to proper card
	int	14h		; call rom-bios for status
	ret
AUXOP	ENDP

;----------------------------------------------------------------
;								:
;  Flush AUX Input buffer - set contents of AUXBUF to zero	:
;								:
;----------------------------------------------------------------
	PUBLIC AUX$FLSH
AUX$FLSH PROC	NEAR
	ASSUME	DS:CODE 	; SET BY AUX DEVICE DRIVER ENTRY ROUTINE
	call	GETBX		; get BX to point to AUXBUF
	mov	BYTE PTR [BX],0 ; zero out buffer
	Jump	Exit		; all done, successful return
AUX$FLSH ENDP



;----------------------------------------------------------------
;								:
;		Write to Auxilary Device			:
;								:
;----------------------------------------------------------------
	PUBLIC	AUX$WRIT
AUX$WRIT PROC	NEAR
	ASSUME	DS:CODE 	; SET BY AUX DEVICE DRIVER ENTRY ROUTINE
	jcxz	EXVEC2		; if CX is zero, no characters
				;   to be written, jump to exit
AUX$LOOP:
	mov	AL,ES:[DI]	; get character to be written
	inc	DI		; move DI pointer to next character
;;Ver 3.30 modification ---------------------------
	MOV	AH,AUXFUNC_SEND ;VALUE=1, INDICATES A WRITE
	CALL	AUXOP		;SEND CHARACTER OVER AUX PORT

	TEST	AH,FLAG_TIMEOUT ;CHECK FOR ERROR
;;End of modification ---------------------------
	jz	AWOK		;   then no error
	mov	AL,10		;   else indicate write fault
	Jump	ERR$CNT 	; call error routines

				; if CX is non-zero, still more
AWOK:
	loop	AUX$LOOP	; more characrter to print
	Jump	Exit		; all done, successful return
AUX$WRIT ENDP


;
;  GETBX puts the address of AUXBUF (the Auxilary Device buffer)
;	 in BX.  After calling GETBX, a routine can get to AUXBUF
;	 with [BX].
;
;  NOTE: The getdx routine is in msbio1 and looks like:
;	mov	dx,word ptr cs:[auxnum]
;
GETBX	PROC	NEAR
	call	GETDX
	mov	BX,DX
	add	BX,OFFSET AUXBUF
	ret
GETBX	ENDP

CODE	ENDS
	END
