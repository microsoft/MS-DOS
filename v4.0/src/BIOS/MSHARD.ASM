;***
;	Title:	Disk
;	C:	(C) Copyright 1988 by Microsoft corp.
;	Date:	1/11/85
;
;		There is a bug in some versions of IBM's AT ROM BIOS.
;		Interrupts are not disabled during read operations.
;
;	Use:	This program should be chained in line with the disk
;		interupt 13h, it intercepts read calls to the hard disk
;		and handles them appropriately.  For other functions it
;		passes controll to OLD13, which should contain the
;		address of the AT ROM disk routine. The entry point for
;		this program is IBM_DISK_IO.
;


	.286c		;Use 80286 non-protected mode

BIOSEG		= 040h		;Segment for ROM BIOS Data
ROMSEG		= 0F000h	;Segment of ROM


BAD_DISK 	= 01

HF_PORT 	= 01F0h
HF_REG_PORT 	= 03F6h

;*	Offsets into Fixed disk parameter table
FDP_PRECOMP	= 5
FDP_CONTROL 	= 8

DATA	SEGMENT AT BIOSEG	;ROM BIOS data segment

	ORG 42h
CMD_BLOCK	DB 6 DUP (?)

;*	Offsets into CMD_BLOCK for registers
PRE_COMP = 0	;Write Pre-compensation
SEC_CNT	 = 1	;Sector count
SEC_NUM	 = 2	;Sector number
CYL_LOW	 = 3	;Cylinder number, low part
CYL_HIGH = 4	;Cylinder number, high part
DRV_HEAD = 5	;Drive/Head (Bit 7 = ECC mode, Bit 5 = 512 byte sectors, 
		;            Bit 4 = drive number, Bits 3-0 have head number)
CMD_REG  = 6	;Command register


	ORG 074h

DISK_STATUS1 	DB ?
HF_NUM		DB ?
CONTROL_BYTE	DB ?

DATA	ENDS



;***	Define where the ROM routines are actually located
ROM	SEGMENT AT ROMSEG

	ORG 02E1Eh
ROMCOMMAND PROC FAR
ROMCOMMAND ENDP

	ORG 02E7Fh
ROMWAIT	PROC FAR
ROMWAIT	ENDP

	ORG 02EE2h
ROMWAIT_DRQ PROC FAR
ROMWAIT_DRQ ENDP

	ORG 02EF8h
ROMCHECK_STATUS PROC FAR
ROMCHECK_STATUS ENDP

	ORG 02F69h
ROMCHECK_DMA PROC FAR
ROMCHECK_DMA ENDP

	ORG 02F8Eh
ROMGET_VEC PROC FAR
ROMGET_VEC ENDP

	ORG 0FF65h
ROMFRET PROC FAR	;Far return at F000:FF65 in AT ROM.
ROMFRET ENDP

ROM	ENDS


CODE	SEGMENT BYTE PUBLIC 'code'

EXTRN	OLD13:DWORD		;Link to AT bios int 13h

PUBLIC	IBM_DISK_IO	


	ASSUME CS:CODE
	ASSUME DS:DATA


;***	IBM_DISK_IO - main routine, fixes AT ROM bug
;
;	ENTRY:	(AH) = function, 02 or 0A for read.
;		(DL) = drive number (80h or 81h).
;		(DH) = head number.
;		(CH) = cylinder number.
;		(CL) = Sector number (high 2 bits has cylinder number).
;		(AL) = number of sectors.
;		(ES:BX) = address of read buffer.
;		For more on register contents see ROM BIOS listing.
;		Stack set up for return by an IRET.
;
;	EXIT:	(AH) = status of current operation.
;		(CY) = 1 IF failed, 0 if successful.
;		For other register contents see ROM BIOS listing.
;
;	USES:	
;
;
;	WARNING: Uses OLD13 vector for non-read calls.
;		Does direct calls to the AT ROM.
;		Does segment arithmatic.
;
;	EFFECTS: Performs DISK I/O operation.
;
IBM_DISK_IO PROC FAR
	CMP DL, 80h
	JB  ATD1		;Pass through floppy disk calls.
	CMP AH, 02
	JE  ATD2		;Intercept call 02 (read sectors).
	CMP AH, 0Ah
	JE  ATD2		;and call 0Ah (read long).
ATD1:
	JMP OLD13		;Use ROM INT 13h handler.
ATD2:
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH DI
	PUSH DS
	PUSH ES
	PUSH AX
	MOV  AX,BIOSEG		;Establish BIOS segment addressing.
	MOV  DS,AX
	MOV  DISK_STATUS1, 0	;Initially no error code.
	AND  DL, 07fh		;Mask to hard disk number
	CMP  DL, HF_NUM
	JB   ATD3		;Disk number in range
	MOV  DISK_STATUS1, BAD_DISK
	JMP  SHORT ATD4		;Disk number out of range error, return

ATD3:
	PUSH BX
	MOV  AX, ES		;Make ES:BX to Seg:000x form.
	SHR  BX, 4
	ADD  AX, BX
	MOV  ES, AX
	POP  BX
	AND  BX,000Fh
	PUSH CS
	CALL CHECK_DMA
	JC   ATD4		;Abort if DMA across segment boundary

	POP  AX			;Restore AX register for SETCMD
	PUSH AX
	CALL SETCMD		;Set up command block for disk op
	MOV  DX, HF_REG_PORT
	OUT  DX, AL		;Write out command modifier
	CALL DOCMD		;Carry out command
ATD4:
;;  Old code - Carry cleared after set by logical or opearation
;;	POP  AX
;;	MOV  AH,DISK_STATUS1	;On return AH has error code
;;	STC
;;	OR   AH,AH
;;	JNZ  ATD5 		;Carry set if error
;;	CLC
;;---------------------------------------------------
;;  New Code - Let Logical or clear carry and then set carry if ah!=0
;;             And save a couple bytes while were at it.
	POP  AX
	MOV  AH,DISK_STATUS1	;On return AH has error code
	OR   AH,AH
	JZ   ATD5 		;Carry set if error
	STC

ATD5:
	POP  ES
	POP  DS
	POP  DI
	POP  DX
	POP  CX
	POP  BX
	RET  2			;Far return, dropping flags
IBM_DISK_IO ENDP



;***	SETCMD - Set up CMD_BLOCK for the disk operation
;
;	ENTRY:	(DS) = BIOS Data segment.
;		(ES:BX) in seg:000x form.
;		Other registers as in INT 13h call
;	
;	EXIT:	CMD_BLOCK set up for disk read call.
;		CONTROL_BYTE set up for disk operation.
;		(AL) = Control byte modifier
;
;
;	Sets the fields of CMD_BLOCK using the register contents
;	and the contents of the disk parameter block for the given drive.
;
;	WARNING: (AX) destroyed.
;		Does direct calls to the AT ROM.
;
SETCMD	PROC NEAR
	MOV  CMD_BLOCK[SEC_CNT], AL
	MOV  CMD_BLOCK[CMD_REG], 020h	;Assume function 02
	CMP  AH, 2
	JE   SETC1			;CMD_REG = 20h if function 02 (read)
	MOV  CMD_BLOCK[CMD_REG], 022h   ;CMD_REG = 22h if function 0A (" long)
SETC1:					;No longer need value in AX
	MOV  AL, CL
	AND  AL, 03fh			;Mask to sector number
	MOV  CMD_BLOCK[SEC_NUM], AL
	MOV  CMD_BLOCK[CYL_LOW], CH
	MOV  AL, CL
	SHR  AL, 6			;Get two high bits of cylender number
	MOV  CMD_BLOCK[CYL_HIGH], AL
	MOV  AX, DX
	SHL  AL, 4			;Drive number
	AND  AH, 0Fh
	OR   AL, AH			;Head number
	OR   AL, 0A0h			;Set ECC and 512 bytes per sector
	MOV  CMD_BLOCK[DRV_HEAD], AL
	PUSH ES				;GET_VEC destroys ES:BX
	PUSH BX
	PUSH CS
	CALL GET_VEC
	MOV  AX, ES:FDP_PRECOMP[BX]	;Write pre-comp from disk parameters
	SHR  AX, 2
	MOV  CMD_BLOCK[PRE_COMP],AL	;Only use low part
	MOV  AL, ES:FDP_CONTROL[BX]	;Control byte modifier
	POP  BX
	POP  ES
	MOV  AH, CONTROL_BYTE
	AND  AH, 0C0h			;Keep disable retry bits
	OR   AH, AL
	MOV  CONTROL_BYTE, AH
	RET
SETCMD	ENDP	



;***	DOCMD - Carry out READ operation to AT hard disk
;
;	ENTRY:	(ES:BX) = address for read in data.
;		CMD_BLOCK set up for disk read.
;
;	EXIT:	Buffer at (ES:BX) contains data read.
;		DISK_STATUS1 set to error code (0 if success).
;
;	
;
;	WARNING: (AX), (BL), (CX), (DX), (DI) destroyed.
;		No check is made for DMA boundary overrun.
;
;	EFFECTS: Programs disk controller.
;		Performs disk input.
;
DOCMD	PROC NEAR
	MOV  DI, BX		;(ES:DI) = data buffer addr.
	PUSH CS
	CALL COMMAND
	JNZ  DOC3
DOC1:
	PUSH CS
	CALL WAITT		;Wait for controller to complete read
	JNZ  DOC3
	MOV  CX, 100h		;256 words per sector
	MOV  DX, HF_PORT
	CLD			;String op goes up
	CLI			;Disable interrupts (BUG WAS FORGETTING THIS)
  REPZ  INSW			;Read in sector
  	STI
	TEST CMD_BLOCK[CMD_REG], 02
	JZ   DOC2		;No ECC bytes to read.
	PUSH CS
	CALL WAIT_DRQ
	JC   DOC3
	MOV  CX, 4		;4 bytes of ECC
	MOV  DX, HF_PORT
	CLI
  REPZ  INSB			;Read in ECC
  	STI
DOC2:
	PUSH CS
	CALL CHECK_STATUS
	JNZ  DOC3		;Operation failed
	DEC  CMD_BLOCK[SEC_CNT]	
	JNZ  DOC1		;Loop while more sectors to read
DOC3:
	RET
DOCMD	ENDP



;***	GET_VEC - Get pointer to hard disk parameters.
;
;	ENTRY:	(DL) = Low bit has hard disk number (0 or 1).
;
;	EXIT:	(ES:BX) = address of disk parameters table.
;
;	USES:	AX for segment computation.
;
;	Loads ES:BX from interrupt table in low memory, vector 46h (disk 0)
;	or 70h (disk 1).
;	
;	WARNING: (AX) destroyed.
;		This does a direct call to the AT ROM.
;
GET_VEC	PROC NEAR
	PUSH OFFSET ROMFRET
	JMP  ROMGET_VEC
GET_VEC ENDP



;***	COMMAND - Send contents of CMD_BLOCK to disk controller.
;
;	ENTRY:	Control_byte 
;		CMD_BLOCK - set up with values for hard disk controller.
;
;	EXIT:	DISK_STATUS1 = Error code.
;		NZ if error, ZR for no error.
;
;
;	WARNING: (AX), (CX), (DX) destroyed.
;		Does a direct call to the AT ROM.
;
;	EFFECTS: Programs disk controller.
;
COMMAND	PROC NEAR
	PUSH OFFSET ROMFRET
	JMP  ROMCOMMAND
COMMAND ENDP



;***	WAITT - Wait for disk interrupt
;
;	ENTRY:	Nothing.
;
;	EXIT:	DISK_STATUS1 = Error code.
;		NZ if error, ZR if no error.
;
;
;	WARNING: (AX), (BL), (CX) destroyed.
;		Does a direct call to the AT ROM.
;		
;	EFFECTS: Calls int 15h, function 9000h.
;
WAITT	PROC NEAR
	PUSH OFFSET ROMFRET 
	JMP  ROMWAIT
WAITT	ENDP



;***	WAIT_DRQ - Wait for data request.
;
;	ENTRY:	Nothing.
;
;	EXIT:	DISK_STATUS1 = Error code.
;		CY if error, NC if no error.
;
;
;	WARNING: (AL), (CX), (DX) destroyed.
;		Does a direct call to the AT ROM.
;
WAIT_DRQ PROC NEAR
	PUSH OFFSET ROMFRET
	JMP  ROMWAIT_DRQ
WAIT_DRQ ENDP



;***	CHECK_STATUS - Check hard disk status.
;
;	ENTRY:	Nothing.
;
;	EXIT:	DISK_STATUS1 = Error code.
;		NZ if error, ZR if no error.
;
;
;	WARNING: (AX), (CX), (DX) destroyed.
;		Does a direct call to the AT ROM.
;
CHECK_STATUS PROC NEAR
	PUSH OFFSET ROMFRET
	JMP  ROMCHECK_STATUS
CHECK_STATUS ENDP



;***	CHECK_DMA - check for DMA overrun 64k segment.
;
;	ENTRY:	(ES:BX) = addr. of memory buffer in seg:000x form.
;		CMD_BLOCK set up for operation.
;
;	EXIT:	DISK_STATUS1 - Error code.
;		CY if error, NC if no error.
;
;
;	WARNING: Does a direct call to the AT ROM.
;
CHECK_DMA PROC NEAR
	PUSH OFFSET ROMFRET
	JMP  ROMCHECK_DMA
CHECK_DMA ENDP


CODE	ENDS
	END
