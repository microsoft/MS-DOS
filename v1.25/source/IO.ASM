; I/O System for 86-DOS version 1.20 and later. Revised 8-02-82.
;
; Assumes a CPU Support card at F0 hex for character I/O,
; with disk drivers for SCP, Tarbell, or Cromemco controllers.
;
; Select whether console input is interrupt-driven or polled.
INTINP:		EQU	1
;
; Select whether the auxiliary port is the Support Card parallel port
; or on channel 1 of a Multiport Serial card addressed at 10H.
PARALLELAUX:	EQU	1
SERIALAUX:	EQU	0
;
; Select whether the printer is connected to the Support card parallel
; output port (standard) or channel 0 of a Multiport Serial card
; addressed at 10H.
PARALLELPRN:	EQU	1
SERIALPRN:	EQU	0
;
; If the Multiport Serial was chosen for either the auxiliary or the
; printer, select the baud rate here. Refer to Multiport Serial manual
; page 11 to pick the correct value for a given baud rate.
PRNBAUD:EQU	7		; 1200 baud
AUXBAUD:EQU	0FH		; 19200 baud
;
; Select disk controller here.
SCP:		EQU	1
TARBELLSD:	EQU	0
TARBELLDD:	EQU	0
CROMEMCO4FDC:	EQU	0
CROMEMCO16FDC:	EQU	0
;
; Select if you want a special conversion version which can read/write
; both the new Microsoft format and the old SCP format.
; For a two drive system, drives A and B are the new Microsoft format,
; and drives C and D are the old SCP format (where C is the same physical
; drive as A, and D is the same drive as B).  CONVERT has no effect
; on 5.25-inch drives.
CONVERT:EQU	1
;
; Select disk configuration:
LARGE:	EQU	1		; Large drives.
COMBIN:	EQU	0		; Two 8-inch and one 5.25-inch.
SMALL:	EQU	0		; Three 5.25-inch drives.
CUSTOM:	EQU	0		; User defined.
;
; If 8-inch drives are PerSci, select FASTSEEK here:
; (Fastseek with Tarbell controllers doesn't work yet).
FASTSEEK:	EQU	1
;
; For double-density controllers, select double-sided operation of
; 8-inch disks in double-density mode.
LARGEDS:	EQU	0
;
; For double-density controllers, select double-sided operation of
; 5.25-inch disks in double-density mode.
SMALLDS:	EQU	0
;
; Use table below to select head step speed. Step times for 5" drives
; are double that shown in the table. Times for Fast Seek mode (using
; PerSci drives) is very small - 200-400 microseconds.
;
; Step value	1771	1793
;
;     0		 6ms	 3ms
;     1		 6ms	 6ms
;     2		10ms	10ms
;     3		20ms	15ms
;
STPSPD:	EQU	0
;
; ****** End of selections ********************************************
;
BIOSSEG:EQU	40H		; I/O system segment.
BIOSLEN:EQU	2048		; Maximum length of I/O system.
DOSLEN:	EQU	8192		; Maximum length of MS-DOS.
QSIZE:	EQU	80		; Input queue size.
PBUFSIZ:EQU	128		; Size of print buffer
BASE:	EQU	0F0H		; CPU Support card base port number.
SIOBASE:EQU	10H		; Base port number of Multiport Serial card.
STAT:	EQU	BASE+7		; Serial I/O status port.
DATA:	EQU	BASE+6		; Serial I/O data port.
DAV:	EQU	2		; Data available bit.
TBMT:	EQU	1		; Transmitter buffer empty bit.
SERIAL:	EQU	SERIALPRN+SERIALAUX
STCDATA:EQU	BASE+4		; Ports for 9513 Timer chip.
STCCOM:	EQU	BASE+5

	IF	SERIALAUX
AUXSTAT:EQU	SIOBASE+3
AUXDATA:EQU	SIOBASE+2
	ENDIF

	IF	PARALLELAUX
AUXSTAT:EQU	BASE+13
AUXDATA:EQU	BASE+12
	ENDIF

	IF	SERIALPRN
PRNSTAT:EQU	SIOBASE+1
PRNDATA:EQU	SIOBASE+0
	ENDIF

	IF	PARALLELPRN
PRNSTAT:EQU	BASE+13
PRNDATA:EQU	BASE+12
	ENDIF

	ORG	0
	PUT	100H

	JMP	INIT
	JMP	STATUS
	JMP	INP
	JMP	OUTP
	JMP	PRINT
	JMP	AUXIN
	JMP	AUXOUT
	JMP	READ
	JMP	WRITE
	JMP	DSKCHG
	JMP	SETDATE
	JMP	SETTIME
	JMP	GETTIME
	JMP	FLUSH
	JMP	MAPDEV
MAPDEV:
	RET	L

INIT:
	XOR	BP,BP		; Set up stack just below I/O system.
	MOV	SS,BP
	MOV	SP,BIOSSEG*16

	IF	INTINP-1
	MOV	AL,0FFH		; Mask all interrupts.
	OUTB	BASE+3
	ENDIF

	IF	INTINP
	DI			; Set up keyboard interrupt vector.
	MOV	[BP+64H],KBINT
	MOV	[BP+66H],CS
	EI
	ENDIF

	MOV	[BP+4*38H],PRNFCB
	MOV	[BP+4*38H+2],CS
	PUSH	CS
	POP	DS
;
; Initialize time-of-day clock.
;
	MOV	SI,STCTAB
	MOV	CX,4		;Initialize 4 registers
	UP
INITSTC:
	LODB
	OUT	STCCOM		;Select register to initialize
	LODB
	OUT	STCDATA
	LODB
	OUT	STCDATA
	LOOP	INITSTC

	IF	SERIAL
	MOV	CX,4
SERINIT:
	LODB
	OUT	SIOBASE+1
	OUT	SIOBASE+3
	LOOP	SERINIT
	LODB			;Baud rate for channel 0
	OUT	SIOBASE+8
	LODB			;Baud rate for channel 1
	OUT	SIOBASE+9
	ENDIF
;
; Move MS-DOS down to the first segment just above the I/O system.
;
	MOV	SI,BIOSLEN	; Source points to where MS-DOS currently is.
	MOV	AX,DOSSEG	; Destination is beginning of DOSSEG.
	MOV	ES,AX
	SUB	DI,DI
	MOV	CX,DOSLEN/2	; CX is number of words to move.
	REP
	MOVSW

	MOV	SI,INITTAB
	MOV	DX,1		; Do auto memory scan.
	CALL	0,DOSSEG
;
; Change disk read and write vectors (INT 37 and INT 38) to go to
; DIRECTREAD and DIRECTWRITE rather than READ and WRITE.
;
	SUB	BP,BP
	MOV	W,[BP+37*4],DIRECTREAD
	MOV	W,[BP+38*4],DIRECTWRITE

	MOV	DX,100H
	MOV	AH,26		;Set DMA address
	INT	33
	MOV	CX,[6]		;Get size of segment
	MOV	BX,DS		;Save segment for later
;
; DS must be set to CS so we can point to the FCB.
;
	MOV	AX,CS
	MOV	DS,AX
	MOV	DX,FCB		;File Control Block for COMMAND.COM
	MOV	AH,15
	INT	33		;Open COMMAND.COM
	OR	AL,AL
	JNZ	COMERR		;Error if file not found
	XOR	AX,AX
	MOV	[FCB+33],AX	; Set 4-byte Random Record field to
	MOV	[FCB+35],AX	;  beginning of file.
	INC	AX
	MOV	[FCB+14],AX	;Set record length field
	MOV	AH,39		;Block read (CX already set)
	INT	33
	JCXZ	COMERR		;Error if no records read
	TEST	AL,1
	JZ	COMERR		;Error if not end-of-file
;
; Make all segment registers the same.
;
	MOV	DS,BX
	MOV	ES,BX
	MOV	SS,BX
	MOV	SP,5CH		;Set stack to standard value
	XOR	AX,AX
	PUSH	AX		;Put zero on top of stack for return
	MOV	DX,80H
	MOV	AH,26
	INT	33		;Set default transfer address (DS:0080)
	PUSH	BX		;Put segment on stack
	MOV	AX,100H
	PUSH	AX		;Put address to execute within segment on stack
	RET	L		;Jump to COMMAND

COMERR:
	MOV	DX,BADCOM
	MOV	AH,9		;Print string
	INT	33
	EI
STALL:	JP	STALL

STCTAB:	DB	17H		;Select master mode register
	DW	84F3H		;Enable time-of-day
	DB	1		;Counter 1 mode register
	DW	0138H
	DB	2
	DW	0038H
	DB	3
	DW	0008H		;Set counter 3 to count days

	IF	SERIAL
	DB	0B7H, 77H, 4EH, 37H, PRNBAUD, AUXBAUD
	ENDIF

BADCOM:	DB	13,10,"Error in loading Command Interpreter",13,10,"$"
FCB:	DB	1,"COMMAND COM"
	DS	25
;
; ************ Time and Date ************
;
GETTIME:
	MOV	AL,0A7H		;Save counters 1,2,3
	OUT	STCCOM
	MOV	AL,0E0H		;Enable data pointer sequencing
	OUT	STCCOM
	MOV	AL,19H		;Select hold 1 / hold cycle
	OUT	STCCOM
	CALL	STCTIME		;Get seconds & 1/100's
	XCHG	AX,DX
	CALL	STCTIME		;Get hours & minutes
	XCHG	AX,CX
	IN	STCDATA
	MOV	AH,AL
	IN	STCDATA
	XCHG	AL,AH		;Count of days
	JP	POINTSTAT

STCTIME:
	CALL	STCBYTE
	MOV	CL,AH
STCBYTE:
	IN	STCDATA
	MOV	AH,AL
	SHR	AH
	SHR	AH
	SHR	AH
	SHR	AH
	AND	AL,0FH		;Unpack BCD digits
	AAD			;Convert to binary
	MOV	AH,AL
	MOV	AL,CL
	RET

SETTIME:
	PUSH	CX
	PUSH	DX
	CALL	LOAD0		;Put 0 into load registers to condition timer
	MOV	AL,43H		;Load counters 1 & 2
	OUT	STCCOM
	POP	DX
	POP	CX
	CALL	LOAD
	MOV	AL,43H
	OUT	STCCOM		;Load counters 1&2
	CALL	LOAD0
	MOV	AL,27H		;Arm counters 1,2,3
	OUT	STCCOM
	JP	POINTSTAT

LOAD0:
	XOR	CX,CX
	MOV	DX,CX
LOAD:
	MOV	AL,09		;Counter 1 load register
	CALL	OUTDX
	MOV	AL,0AH		;Counter 2 load register
	MOV	DX,CX
OUTDX:
	OUT	STCCOM		;Select a load register
	MOV	AL,DL
	CALL	OUTBCD
	MOV	AL,DH
OUTBCD:
	AAM			;Convert binary to unpacked BCD
	SHL	AH
	SHL	AH
	SHL	AH
	SHL	AH
	OR	AL,AH		;Packed BCD
	OUT	STCDATA
	RET

SETDATE:
	XCHG	AX,DX		;Put date in DX
	MOV	AL,0BH		;Select Counter 3 load register
	OUT	STCCOM
	XCHG	AX,DX
	OUT	STCDATA
	MOV	AL,AH
	OUT	STCDATA
	MOV	AL,44H		;Load counter 3
	OUT	STCCOM
POINTSTAT:
	PUSH	AX
	MOV	AL,1FH		;Point to status register
	OUT	STCCOM		;   so power-off glitches won't hurt
	POP	AX
	RET	L
;
; ************ CONSOLE INPUT ************
;

	IF	INTINP-1	; Non-interrupt driven input.
STATUS:
	IN	STAT
	AND	AL,DAV
	JZ	NOTHING		; Jump if nothing there.
	PUSHF			; Save Z flag.
	INB	DATA
	AND	AL,7FH
	SEG	CS
	MOV	[QUEUE],AL	; Put new character in buffer.
	POPF			; Return with Z flag clear.
	RET	L
NOTHING:
	SEG	CS
	MOV	AL,[QUEUE]	; See if there's anything in the buffer.
	NOT	AL		; Set up the Z flag.
	TEST	AL,80H
	PUSHF
	NOT	AL
	POPF
	RET	L

INP:
	MOV	AL,-1
	SEG	CS
	XCHG	AL,[QUEUE]	; Remove the character from the buffer.
	AND	AL,AL
	JNS	INRET		; Return if we have a character.
INLOOP:
	IN	STAT		; Wait till a character is available.
	AND	AL,DAV
	JZ	INLOOP
	IN	DATA
	AND	AL,7FH
INRET:
FLUSH:
	RET	L

QUEUE:	DB	-1		; For storing characters from STATUS to INP.
	ENDIF

	IF	INTINP		; Interrupt-driven input.
;
; Console keyboard interrupt handler.
;
KBINT:
	PUSH	AX
	PUSH	SI
	MOV	AL,20H		;End of Interrupt command
	OUT	BASE+2		;Send to slave
	IN	DATA		;Get the character
	AND	AL,7FH
	CMP	AL,"C"-"@"
	JZ	FLSH
	CMP	AL,"S"-"@"
	JZ	FLSH
	CMP	AL,"F"-"@"
	JNZ	SAVKY
FLSH:
	CALL	13*3,BIOSSEG	; Call I/O system keyboard buffer flush.
SAVKY:
	SEG	CS
	MOV	SI,[REAR]	;Pointer to rear of queue
	CALL	INCQ
	SEG	CS
	CMP	SI,[FRONT]	;Any room in queue?
	JZ	QFULL
	SEG	CS
	MOV	[SI],AL		;Put character in queue
	SEG	CS
	MOV	[REAR],SI	;Save pointer
LEAVINT:
	POP	SI
	POP	AX
	IRET
QFULL:
	MOV	AL,7		; BELL character.
	CALL	3*3,BIOSSEG	; Call I/O system console output function.
	JMPS	LEAVINT

STATUS:
	PUSH	SI
;See if printer ready
	IN	PRNSTAT
	AND	AL,TBMT
	JZ	NOPRN
	SEG	CS
	MOV	SI,[PFRONT]
	SEG	CS
	CMP	SI,[PREAR]	;Anything in print queue?
	JNZ	SENDPRN
	SEG	CS
	CMP	B,[PRNFCB],-1	;Print spooling in progress?
	JZ	NOPRN		;If not, nothing to print
;Print spooling in progress. Get next buffer
	PUSH	DS
	PUSH	CS
	POP	DS
	PUSH	AX
	PUSH	CX
	PUSH	DX
	PUSH	[STKSAV]
	PUSH	[STKSAV+2]
	PUSH	[DMAADD]
	PUSH	[DMAADD+2]
	MOV	DX,PQUEUE
	MOV	AH,26		;Set DMA address
	INT	33
	MOV	DX,PRNFCB
	MOV	CX,PBUFSIZ
	MOV	AH,39		;Read buffer
	INT	33
	OR	AL,AL
	JZ	NOTEOF
	MOV	B,[PRNFCB],-1	;Turn off print spooling at EOF
NOTEOF:
	POP	[DMAADD+2]
	POP	[DMAADD]
	POP	[STKSAV+2]
	POP	[STKSAV]
	MOV	SI,CX
	POP	DX
	POP	CX
	POP	AX
	POP	DS
	OR	SI,SI
	JZ	NOPRN
	ADD	SI,PQUEUE-1
	SEG	CS
	MOV	[PREAR],SI
	MOV	SI,ENDPQ-1
SENDPRN:
	CALL	INCPQ
	SEG	CS
	MOV	[PFRONT],SI
	SEG	CS
	LODSB			;Get character to print
	OUT	PRNDATA
NOPRN:
	DI			; Disable interrupts while checking queue.
	SEG	CS
	MOV	SI,[FRONT]
	SEG	CS
	CMP	SI,[REAR]	; Anything in queue?
	JZ	NOCHR		; Jump if nothing in queue.
	CALL	INCQ
	SEG	CS
	LODSB			;Get character (if there is one)
	OR	SI,SI		;Reset zero flag
NOCHR:
	EI
	POP	SI
	RET	L		;Zero clear if we have a character

INP:
	CALL	STATUS,BIOSSEG	; Get I/O system console input status.
	JZ	INP
	PUSH	SI
	DI			; Disable interrupts while changing queue pointers.
	SEG	CS
	MOV	SI,[FRONT]
	CALL	INCQ		; Permanently remove char from queue
	SEG	CS
	MOV	[FRONT],SI
	EI
	POP	SI
	RET	L

FLUSH:
	DI
	SEG	CS
	MOV	[REAR],QUEUE
	SEG	CS
	MOV	[FRONT],QUEUE
	EI
	RET	L

INCQ:
	INC	SI
	CMP	SI,ENDQ		;Exceeded length of queue?
	JB	RET
	MOV	SI,QUEUE
	RET

INCPQ:
	INC	SI
	CMP	SI,ENDPQ	;Exceeded length of queue?
	JB	RET
	MOV	SI,PQUEUE
	RET

FRONT:	DW	QUEUE
REAR:	DW	QUEUE
QUEUE:	DS	QSIZE
ENDQ:	EQU	$
PFRONT:	DW	PQUEUE
PREAR:	DW	PQUEUE
PQUEUE:	DS	PBUFSIZ
ENDPQ:	EQU	$
PRNFCB:	DB	-1
	DS	36
	ENDIF

;
; ************ Console and Printer Output ************
;
OUTP:
	PUSH	AX
OUTLP:
	IN	STAT
	AND	AL,TBMT
	JZ	OUTLP
	POP	AX
	OUT	DATA
	RET	L

PRINT:
	PUSH	SI
	SEG	CS
	MOV	SI,[PREAR]
	CALL	INCPQ
PRINLP:
	SEG	CS
	CMP	SI,[PFRONT]
	JNZ	PRNCHR
;Print queue is full
	PUSH	AX
	CALL	STATUS,BIOSSEG	;Poll and maybe print something
	POP	AX
	JMPS	PRINLP
PRNCHR:
	SEG	CS
	MOV	[PREAR],SI
	SEG	CS
	MOV	[SI],AL
	POP	SI
	RET	L
;
; ************ Auxiliary I/O ************
;
AUXIN:
	IN	AUXSTAT
	AND	AL,DAV
	JZ	AUXIN
	IN	AUXDATA
	RET	L

AUXOUT:
	PUSH	AX
AUXLP:
	IN	AUXSTAT
	AND	AL,TBMT
	JZ	AUXLP
	POP	AX
	OUT	AUXDATA
	RET	L
;
; ************ 1771/1793-type controller disk I/O ************
;
TARBELL:EQU	TARBELLSD+TARBELLDD
CROMEMCO:EQU	CROMEMCO4FDC+CROMEMCO16FDC

WD1791:	EQU	SCP+TARBELLDD+CROMEMCO16FDC
WD1771:	EQU	TARBELLSD+CROMEMCO4FDC

	IF	WD1791
READCOM:EQU	80H
WRITECOM:EQU	0A0H
	ENDIF

	IF	WD1771
READCOM:EQU	88H
WRITECOM:EQU	0A8H
	ENDIF

	IF	SCP
SMALLBIT:EQU	10H
BACKBIT:EQU	04H
DDENBIT:EQU	08H
DONEBIT:EQU	01H
DISK:	EQU	0E0H
	ENDIF

	IF	TARBELL
BACKBIT:EQU	40H
DDENBIT:EQU	08H
DONEBIT:EQU	80H
DISK:	EQU	78H
	ENDIF

	IF	CROMEMCO
SMALLBIT:EQU	10H
BACKBIT:EQU	0FDH		; Send this to port 4 to select back.
DDENBIT:EQU	40H
DONEBIT:EQU	01H
DISK:	EQU	30H
	ENDIF

	IF	SMALLDS-1
SMALLDDSECT:	EQU	8
	ENDIF

	IF	SMALLDS
SMALLDDSECT:	EQU	16
	ENDIF

	IF	LARGEDS-1
LARGEDDSECT:	EQU	8
	ENDIF

	IF	LARGEDS
LARGEDDSECT:	EQU	16
	ENDIF
;
; Disk change function.
; On entry:
;	AL = disk drive number.
; On exit:
;	AH = -1 (FF hex) if disk is changed.
;	AH = 0 if don't know.
;	AH = 1 if not changed.
;
;	CF clear if no disk error.
;	AL = disk I/O driver number.
;
;	CF set if disk error.
;	AL = disk error code (see disk read below).
;
	IF	WD1771
DSKCHG:
	MOV	AH,0		; AH = 0 in case we don't know.
	SEG	CS
	CMP	AL,[CURDRV]
	JNZ	RETL
	PUSH	AX		; Save drive number.

	IF	CROMEMCO
	INB	DISK+4
	ENDIF

	IF	TARBELL
	INB	DISK
	ENDIF

	AND	AL,20H		; Look at head load bit
	POP	AX
	JZ	RETL
	MOV	AH,1		; AH = 1, disk not changed.
RETL:
	CLC			; No disk error.
	RET	L
	ENDIF			; End of 1771 DSKCHG.

	IF	WD1791
DSKCHG:
	MOV	AH,0		; AH = 0 in case we don't know.
	SEG	CS
	CMP	AL,[CURDRV]
	JNZ	DENSCHK		; Check density if not same drive.
	PUSH	AX

	IF	SCP+CROMEMCO
	INB	DISK+4
	ENDIF

	IF	TARBELL
	INB	DISK
	ENDIF

	AND	AL,20H		; Look at head load bit
	POP	AX
	JZ	DENSCHK		; Check density if head not loaded.
	MOV	AH,1		; AH = 1, disk not changed.
	MOV	BX,PREVDENS
	SEG	CS
	XLAT			; Get previous density
	CLC			; No disk error.
	RET	L
DENSCHK:
	CALL	CHKNEW		; Unload head if selecting new drive.
	CBW
	XCHG	AX,SI
	ADD	SI,PREVDENS
	MOV	CX,4		; Try each density twice
	MOV	AH,0		; Disk may not have been changed.
CHKDENS:
	SEG	CS
	MOV	AL,[SI]		; Get previous disk I/O driver number.
	MOV	BX,DRVTAB
	SEG	CS
	XLAT			; Get drive select byte for previous density

	IF	CROMEMCO16FDC
	CALL	MOTOR		; Wait for motor to come up to speed.
	ENDIF

	OUT	DISK+4		; Select disk
	MOV	AL,0C4H		; READ ADDRESS command
	CALL	DCOM
	AND	AL,98H
	IN	DISK+3		; Eat last byte to reset DRQ
	JZ	HAVDENS		; Jump if no error in reading address.
	NOT	AH		; AH = -1 (disk changed) if new density works.
	SEG	CS
	XOR	B,[SI],1	; Try other density
	LOOP	CHKDENS
	MOV	AX,2		; Couldn't read disk at all, AH = 0 for don't 
	STC			;  know if disk changed, AL = error code 2 -
	RET	L		;  disk not ready, carry set to indicate error.

HAVDENS:
	SEG	CS
	LODSB			; AL = disk I/O driver number.
	CLC			; No disk error.
	RET	L

PREVDENS:DB	1,3,5,7,9,11,13	; Table of previous disk I/O driver numbers.
	ENDIF			; End of 1793 DSKCHG function.

CHKNEW:
	MOV	AH,AL		; Save disk drive number in AH.
	SEG	CS		; AL = previous disk drive number,
	XCHG	AL,[CURDRV]	;  make new drive current.
	CMP	AL,AH		; Changing drives?
	JZ	RET
;
; If changing drives, unload head so the head load delay one-shot will
; fire again. Do it by seeking to the same track with the H bit reset.
;
	IN	DISK+1		; Get current track number
	OUT	DISK+3		; Make it the track to seek to
	MOV	AL,10H		; Seek and unload head
	CALL	DCOM
	MOV	AL,AH		; Restore current drive number
	RET

	IF	CROMEMCO16FDC
MOTOR:
	PUSH	AX
	MOV	AH,AL
	IN	DISK+4		; See if the motor is on.
	TEST	AL,08H
	MOV	AL,AH
	OUTB	DISK+4		; Select drive & start motor.
	JNZ	MOTORSON	; No delay if motors already on.
	PUSH	CX
	MOV	CX,43716	; Loop count for 1 second.
MOTORDELAY:			;  (8 MHz, 16-bit memory).
	AAM			; 83 clocks.
	AAM			; 83 clocks.
	LOOP	MOTORDELAY	; 17 clocks.
	POP	CX
MOTORSON:
	POP	AX
	RET
	ENDIF
;
; Disk read function.
;
; On entry:
;	AL = Disk I/O driver number
;	BX = Disk transfer address in DS
;	CX = Number of sectors to transfer
;	DX = Logical record number of transfer
; On exit:
;	CF clear if transfer complete
;
;	CF set if hard disk error.
;	CX = number of sectors left to transfer.
;	AL = disk error code
;		0 = write protect error
;		2 = not ready error
;		4 = "data" (CRC) error
;		6 = seek error
;		8 = sector not found
;	       10 = write fault
;	       12 = "disk" (none of the above) error
;
READ:
	CALL	SEEK		;Position head
	JC	ERROR
	PUSH	ES		; Make ES same as DS.
	MOV	BX,DS
	MOV	ES,BX
RDLP:
	CALL	READSECT	;Perform sector read
	JC	POPESERROR
	INC	DH		;Next sector number
	LOOP	RDLP		;Read each sector requested
	CLC			; No errors.
	POP	ES		; Restore ES register.
	RET	L
;
; Disk write function.
; Registers same on entry and exit as read above.
;
WRITE:
	CALL	SEEK		;Position head
	JC	ERROR
WRTLP:
	CALL	WRITESECT	;Perform sector write
	JC	ERROR
	INC	DH		;Bump sector counter
	LOOP	WRTLP		;Write CX sectors
	CLC			; No errors.
WRITERET:
	RET	L

POPESERROR:
	POP	ES		; Restore ES register.
ERROR:
	MOV	BL,-1
	SEG	CS
	MOV	[DI],BL		; Indicate we don't know where head is.
	MOV	SI,ERRTAB
GETCOD:
	INC	BL		; Increment to next error code.
	SEG	CS
	LODB
	TEST	AH,AL		; See if error code matches disk status.
	JZ	GETCOD		; Try another if not.
	MOV	AL,BL		; Now we've got the code.
	SHL	AL		; Multiply by two.
	STC
	RET	L

ERRTAB:
	DB	40H		;Write protect error
	DB	80H		;Not ready error
	DB	8		;CRC error
	DB	2		;Seek error
	DB	10H		;Sector not found
	DB	20H		;Write fault
	DB	7		;"Disk" error
;
; Direct disk read and write from INT 37 and INT 38.  Subroutine GETIODRIVER
; calls DSKCHG to convert disk drive number to I/O driver number.
;
; Setting CURDRV to -1 before calling DSKCHG forces DSKCHG to check the disk's
; density before returning the I/O driver number.  This is necessary because
; programs such as FORMAT could change the density of a disk and leave the
; head loaded.  If the head is loaded DSKCHG assumes the disk hasn't been
; changed and returns the old I/O driver number which could be wrong.
;
; CURDRV is set to -1 before returning so when DSKCHG is called by the
; operating system, it will tell the operating system the disk may have
; been changed (because it may have been).
;
DIRECTREAD:

	IF	WD1791
	CALL	GETIODRIVER	; Convert drive number to I/O driver number.
	JC	DIRECTRET	; Return if DSKCHG returned error.
	ENDIF

	CALL	7*3,BIOSSEG	; Call READ.
	JMPS	DIRECTRET

DIRECTWRITE:

	IF	WD1791
	CALL	GETIODRIVER	; Convert drive number to I/O driver number.
	JC	DIRECTRET	; Return if DSKCHG returned error.
	ENDIF

	CALL	8*3,BIOSSEG	; Call WRITE.
DIRECTRET:
	SEG	CS
	MOV	B,[CURDRV],-1	; Force DSKCHG to do density check.
	RET	L

	IF	WD1791
GETIODRIVER:
	SEG	CS
	MOV	B,[CURDRV],-1	; Force DSKCHG to do density check.
	PUSH	BX
	PUSH	CX
	CALL	9*3,BIOSSEG	; Call DSKCHG.
	POP	CX
	POP	BX
	RET
	ENDIF
;
; Function:
;	Seeks to proper track.
; On entry:
;	Same as for disk read or write above.
; On exit:
;	AH = Drive select byte
;	DL = Track number
;	DH = Sector number
;	SI = Disk transfer address in DS
;	DI = pointer to drive's track counter in CS
;	CX unchanged (number of sectors)
;
SEEK:
	MOV	SI,BX		; Save transfer address
	CBW
	MOV	BX,AX		; Prepare to index on drive number

	IF	WD1791		; If two disk formats per drive.
	SHR	AL		; Convert to physical disk drive number.
	ENDIF

	CALL	CHKNEW		; Unload head if changing drives.
	SEG	CS
	MOV	AL,[BX+DRVTAB]	; Get drive-select byte.

	IF	CROMEMCO16FDC
	CALL	MOTOR		; Wait for the motors to come up to speed.
	ENDIF

	OUTB	DISK+4		; Select drive.

	IF	CROMEMCO
	OR	AL,80H		; Set auto-wait bit.
	ENDIF

	MOV	AH,AL		; Save drive-select byte in AH.
	XCHG	AX,DX		; AX = logical sector number.
	MOV	DL,26		; 26 sectors/track unless changed below

	IF	SCP
	TEST	DH,SMALLBIT	; Check if small disk.
	JZ	BIGONE		; Jump if big disk.
	MOV	DL,18		; Assume 18 sectors on small track.
	TEST	DH,DDENBIT	; Check if double-density.
	JZ	HAVSECT		; Jump if not.
	MOV	DL,SMALLDDSECT	; Number of sectors on small DD track.
	JP	HAVSECT
BIGONE:
	TEST	DH,DDENBIT	; Check if double-density.
	JZ	HAVSECT		; Jump if not.
	MOV	DL,LARGEDDSECT	; Number of sectors on big DD track.
	ENDIF

	IF	TARBELLDD	; Tarbell DD controller.
	TEST	DH,DDENBIT	; Check for double-density.
	JZ	HAVSECT
	MOV	DL,LARGEDDSECT	; Number of sectors on DD track.
	ENDIF

	IF	CROMEMCO4FDC
	TEST	DH,SMALLBIT	; Check if small disk.
	JNZ	HAVSECT		; Jump if not.
	MOV	DL,18		; 18 sectors on small disk track.
	ENDIF

	IF	CROMEMCO16FDC
	TEST	DH,SMALLBIT	; Check if small disk.
	JNZ	BIGONE		; Jump if big disk.
	MOV	DL,18		; Assume 18 sectors on small track.
	TEST	DH,DDENBIT	; Check if double-density.
	JZ	HAVSECT		; Jump if not.
	MOV	DL,SMALLDDSECT	; Number of sectors on small DD track.
	JP	HAVSECT
BIGONE:
	TEST	DH,DDENBIT	; Check if double-density.
	JZ	HAVSECT		; Jump if not.
	MOV	DL,LARGEDDSECT	; Number of sectors on big DD track.
	ENDIF

HAVSECT:
	DIV	AL,DL		; AL = track, AH = sector.
	XCHG	AX,DX		; AH has drive-select byte, DX = track & sector.
	INC	DH		; Sectors start at one, not zero.
	SEG	CS
	MOV	BL,[BX+TRKPT]	; Get this drive's displacement into track table.
	ADD	BX,TRKTAB	; BX now points to track counter for this drive.
	MOV	DI,BX
	MOV	AL,DL		; Move new track number into AL.
	SEG	CS
	XCHG	AL,[DI]		; Xchange current track with desired track
	OUT	DISK+1		; Inform controller chip of current track
	CMP	AL,DL		; See if we're at the right track.
	JZ	RET
	MOV	BH,2		; Seek retry count
	CMP	AL,-1		; Head position known?
	JNZ	NOHOME		; If not, home head
TRYSK:
	CALL	HOME
	JC	SEEKERR
NOHOME:
	MOV	AL,DL		; AL = new track number.
	OUT	DISK+3
	MOV	AL,1CH+STPSPD	; Seek command.
	CALL	MOVHEAD
	AND	AL,98H		; Accept not ready, seek, & CRC error bits.
	JZ	RET
	JS	SEEKERR		; No retries if not ready
	DEC	BH
	JNZ	TRYSK
SEEKERR:
	MOV	AH,AL		; Put status in AH.
	TEST	AL,80H		; See if it was a Not Ready error.
	STC
	JNZ	RET		; Status is OK for Not Ready error.
	MOV	AH,2		; Everything else is seek error.
	RET

SETUP:
	MOV	BL,DH		; Move sector number to BL to play with

	IF	SCP+CROMEMCO16FDC
	TEST	AH,DDENBIT	; Check for double density.
	JZ	CHECKSMALL	; Not DD, check size for SD.
	ENDIF

	IF	TARBELLDD
	TEST	AH,DDENBIT	; Check for double density.
	JZ	CHECK26		; Not DD.
	ENDIF

	IF	WD1791

	IF	(SCP+TARBELL)*LARGEDS+SCP*SMALLDS
	MOV	AL,AH		; Select front side of disk.
	OUT	DISK+4
	ENDIF

	IF	CROMEMCO*(LARGEDS+SMALLDS)
	MOV	AL,0FFH		; Select front side of disk.
	OUT	04H
	ENDIF

	CMP	BL,8		; See if legal DD sector number.
	JBE	PUTSEC		; Jump if ok.

	IF	(LARGEDS-1)*((SMALLDS*(SCP+CROMEMCO))-1)
	JP	STEP		; If only SS drives, we gotta step.
	ENDIF

	IF	SCP*LARGEDS*(SMALLDS-1)
	TEST	AH,SMALLBIT	; Check for 5.25 inch disk.
	JNZ	STEP		; Jump if small because SMALLDS is off.
	ENDIF

	IF	SCP*SMALLDS*(LARGEDS-1)
	TEST	AH,SMALLBIT	; Check for 8 inch disk.
	JZ	STEP		; Jump if large because LARGEDS is off.
	ENDIF

	IF	CROMEMCO16FDC*LARGEDS*(SMALLDS-1)
	TEST	AH,SMALLBIT	; Check for 5.25 inch disk.
	JZ	STEP		; Jump if small because SMALLDS is off.
	ENDIF

	IF	CROMEMCO16FDC*SMALLDS*(LARGEDS-1)
	TEST	AH,SMALLBIT	; Check for 8 inch disk.
	JNZ	STEP		; Jump if large because LARGEDS is off.
	ENDIF

	IF	LARGEDS+SMALLDS*(SCP+CROMEMCO)
	SUB	BL,8		; Find true sector for back side.
	CMP	BL,8		; See if ok now.
	JA	STEP		; Have to step if still too big.

	IF	SCP+TARBELLDD
	MOV	AL,AH		; Move drive select byte into AL.
	OR	AL,BACKBIT	; Select back side.
	OUT	DISK+4
	ENDIF

	IF	CROMEMCO16FDC
	MOV	AL,BACKBIT	; Select back side.
	OUT	04H
	ENDIF

	JP	PUTSEC
	ENDIF

	ENDIF

	IF	SCP
CHECKSMALL:
	TEST	AH,SMALLBIT	; See if big disk.
	JZ	CHECK26		; Jump if big.
	ENDIF

	IF	CROMEMCO
CHECKSMALL:
	TEST	AH,SMALLBIT	; See if big disk.
	JNZ	CHECK26		; Jump if big.
	ENDIF

	IF 	SCP+CROMEMCO
	CMP	BL,18		; See if legal small SD/SS sector.
	JA	STEP		; Jump if not.
	ENDIF

CHECK26:
	CMP	BL,26		; See if legal large SD/SS sector.
	JBE	PUTSEC		; Jump if ok.
STEP:
	INC	DL		; Increment track number.
	MOV	AL,58H		; Step in with update.
	CALL	DCOM
	SEG	CS
	INC	B,[DI]		; Increment the track pointer.
	MOV	DH,1		; After step, do first sector.
	MOV	BL,DH		; Fix temporary sector number also.
PUTSEC:
	MOV	AL,BL		; Output sector number to controller.
	OUT	DISK+2
	DI			; Interrupts not allowed until I/O done

	IF	SCP+CROMEMCO
	INB	DISK+4		; Get head-load bit.
	ENDIF

	IF	TARBELL
	INB	DISK
	ENDIF

	NOT	AL
	AND	AL,20H		; Check head load status
	JZ	RET
	MOV	AL,4
	RET

READSECT:
	CALL	SETUP
	MOV	BL,10		; Retry count for hard error.
	XCHG	DI,SI		; Transfer address to DI.
	PUSH	DX		; Save track & sector number.
	MOV	DL,DISK+3	; Disk controller data port.
RDAGN:
	OR	AL,READCOM
	OUT	DISK

	IF	CROMEMCO
	MOV	AL,AH		; Turn on auto-wait.
	OUT	DISK+4
	ENDIF

	MOV	BP,DI		; Save address for retry.
	JMPS	RLOOPENTRY
RLOOP:
	STOB			; Write into memory.
RLOOPENTRY:

	IF	SCP
	IN	DISK+5		; Wait for DRQ or INTRQ.
	ENDIF

	IF	TARBELL+CROMEMCO
	IN	DISK+4
	ENDIF

	IF	TARBELL
	SHL	AL
	INB	DX		; Read data from disk controller chip.
	JC	RLOOP
	ENDIF

	IF	SCP+CROMEMCO
	SHR	AL
	INB	DX		; Read data from disk controller chip.
	JNC	RLOOP
	ENDIF

	EI			; Interrupts OK now
	CALL	GETSTAT
	AND	AL,9CH
	JZ	RDPOP
	MOV	DI,BP		; Get origainal address back for retry.
	MOV	BH,AL		; Save error status for report
	MOV	AL,0
	DEC	BL
	JNZ	RDAGN
	MOV	AH,BH		; Put error status in AH.
	STC
RDPOP:
	POP	DX		; Get back track & sector number.
	XCHG	SI,DI		; Address back to SI.

	IF	TARBELL
FORCINT:
	MOV	AL,0D0H		; Tarbell controllers need this Force Interrupt
	OUT	DISK		;  so that Type I status is always available
	MOV	AL,10		;  at the 1771/1793 status port so we can find
INTDLY:				;  out if the head is loaded.  SCP and Cromemco
	DEC	AL		;  controllers have head-load status available
	JNZ	INTDLY		;  at the DISK+4 status port.
	ENDIF

	RET

WRITESECT:
	CALL	SETUP
	MOV	BL,10
	PUSH	DX		; Save track & sector number.
	MOV	DL,DISK+3	; Disk controller data port.
WRTAGN:
	OR	AL,WRITECOM
	OUT	DISK

	IF	CROMEMCO
	MOV	AL,AH		; Turn on auto-wait.
	OUT	DISK+4
	ENDIF

	MOV	BP,SI
WRLOOP:

	IF	SCP
	INB	DISK+5
	ENDIF

	IF	TARBELL+CROMEMCO
	INB	DISK+4
	ENDIF

	IF	SCP+CROMEMCO
	SHR	AL
	LODB			; Get data from memory.
	OUTB	DX		; Write to disk.
	JNC	WRLOOP
	ENDIF

	IF	TARBELL
	SHL	AL
	LODB			; Get data from memory.
	OUTB	DX		; Write to disk.
	JC	WRLOOP
	ENDIF

	EI			; Interrupts OK now.
	DEC	SI
	CALL	GETSTAT
	AND	AL,0FCH
	JZ	WRPOP
	MOV	SI,BP
	MOV	BH,AL
	MOV	AL,0
	DEC	BL
	JNZ	WRTAGN
	MOV	AH,BH		; Error status to AH.
	STC
WRPOP:
	POP	DX		; Get back track & sector number.

	IF	TARBELL
	JMPS	FORCINT
	ENDIF

	IF	SCP+CROMEMCO
	RET
	ENDIF
;
; Subroutine to restore the read/write head to track 0.
;
	IF	SCP+CROMEMCO+TARBELL*(FASTSEEK-1)
HOME:
	ENDIF

	IF	FASTSEEK*CROMEMCO
	TEST	AH,SMALLBIT	; Check for large disk.
	JNZ	RESTORE		; Big disks are fast seek PerSci.
	ENDIF

	MOV	BL,3
TRYHOM:

	IF	SCP*FASTSEEK
	MOV	AL,AH		; Turn on Restore to PerSci.
	OR	AL,80H
	OUTB	DISK+4
	ENDIF

	MOV	AL,0CH+STPSPD	; Restore with verify command.
	CALL	DCOM
	AND	AL,98H

	IF	SCP*FASTSEEK
	MOV	AL,AH		; Restore off.
	OUTB	DISK+4
	ENDIF

	JZ	RET
	JS	HOMERR		; No retries if not ready
	MOV	AL,58H+STPSPD	; Step in with update
	CALL	DCOM
	DEC	BL
	JNZ	TRYHOM
HOMERR:
	STC
	RET
;
; RESTORE for PerSci drives.
; Doesn't exist yet for Tarbell controllers.
;
	IF	FASTSEEK*TARBELL
HOME:
RESTORE:
	RET
	ENDIF

	IF	FASTSEEK*CROMEMCO4FDC
RESTORE:
	MOV	AL,0C4H		;READ ADDRESS command to keep head loaded
	OUT	DISK
	MOV	AL,77H
	OUT	4
CHKRES:
	IN	4
	AND	AL,40H
	JZ	RESDONE
	IN	DISK+4
	TEST	AL,DONEBIT
	JZ	CHKRES
	IN	DISK
	JP	RESTORE		;Reload head
RESDONE:
	MOV	AL,7FH
	OUT	4
	CALL	GETSTAT
	MOV	AL,0
	OUT	DISK+1		;Tell 1771 we're now on track 0
	RET
	ENDIF

	IF	FASTSEEK*CROMEMCO16FDC
RESTORE:
	MOV	AL,0D7H		; Turn on Drive-Select and Restore.
	OUTB	4
	PUSH	AX
	AAM			; 10 uS delay.
	POP	AX
RESWAIT:
	INB	4		; Wait till Seek Complete is active.
	TEST	AL,40H
	JNZ	RESWAIT
	MOV	AL,0FFH		; Turn off Drive-Select and Restore.
	OUTB	4
	SUB	AL,AL		; Tell 1793 we're on track 0.
	OUTB	DISK+1
	RET
	ENDIF
;
; Subroutine to move the read/write head to the desired track.
; Usually falls through to DCOM unless special handling for
; PerSci drives is required in which case go to FASTSK.
;
	IF	SCP+CROMEMCO+TARBELL*(FASTSEEK-1)
MOVHEAD:
	ENDIF

	IF	CROMEMCO*FASTSEEK
	TEST	AH,SMALLBIT	; Check for PerSci.
	JNZ	FASTSK
	ENDIF

DCOM:
	OUT	DISK
	PUSH	AX
	AAM			;Delay 10 microseconds
	POP	AX
GETSTAT:
	IN	DISK+4
	TEST	AL,DONEBIT

	IF	TARBELL
	JNZ	GETSTAT
	ENDIF

	IF	SCP+CROMEMCO
	JZ	GETSTAT
	ENDIF

	IN	DISK
	RET
;
; Fast seek code for PerSci drives.
; Tarbell not installed yet.
;
	IF	FASTSEEK*TARBELL
MOVHEAD:
FASTSK:
	RET
	ENDIF

	IF	FASTSEEK*CROMEMCO
FASTSK:
	MOV	AL,6FH
	OUT	4
	MOV	AL,18H
	CALL	DCOM
SKWAIT:
	IN	4
	TEST	AL,40H
	JNZ	SKWAIT
	MOV	AL,7FH
	OUT	4
	MOV	AL,0
	RET
	ENDIF

CURDRV:	DB	-1
;
; Explanation of tables below.
;
; DRVTAB is a table of bytes which are sent to the disk controller as drive-
; select bytes to choose which physical drive is selected for each disk I/O
; driver.  It also selects whether the disk is 5.25-inch or 8-inch, single-
; density or double-density.  Always select side 0 in the drive-select byte if
; a side-select bit is available.  There should be one entry in the DRVTAB
; table for each disk I/O driver.  Exactly which bits in the drive-select byte
; do what depends on which disk controller is used.
;
; TRKTAB is a table of bytes used to store which track the read/write
; head of each drive is on.  Each physical drive should have its own
; entry in TRKTAB.
;
; TRKPT is a table of bytes which indicates which TRKTAB entry each
; disk I/O driver should use.  Since each physical drive may be used for
; more than one disk I/O driver, more than one entry in TRKPT may point
; to the same entry in TRKTAB.  Drives such as PerSci 277s which use
; the same head positioner for more than one drive should share entrys
; in TRKTAB.
;
; INITTAB is the initialization table for 86-DOS as described in the
; 86-DOS Programer's Manual under "Customizing the I/O System."
;
	IF	SCP*COMBIN*FASTSEEK
;
; A PerSci 277 or 299 and one 5.25-inch drive.
;
DRVTAB:	DB	00H,08H,01H,09H,10H,18H,00H,08H,01H,09H
TRKPT:	DB	0,0,0,0,1,1,0,0,0,0
TRKTAB:	DB	-1,-1
INITTAB:
	IF	CONVERT-1
	DB	6		; Number of disk I/O drivers.
	ENDIF

	IF	CONVERT
	DB	10
	ENDIF

	DB	0		; Disk I/O driver 0 uses disk drive 0.
	DW	LSDRIVE		; Disk I/O driver 0 is 8-inch single-density.
	DB	0		; Disk I/O driver 1 uses disk drive 0.
	DW	LDDRIVE		; Disk I/O driver 1 is 8-inch double-density.
	DB	1		; Etc.
	DW	LSDRIVE
	DB	1
	DW	LDDRIVE
	DB	2
	DW	SSDRIVE
	DB	2
	DW	SDDRIVE

	IF	CONVERT
	DB	3
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLDDRIVE
	DB	4
	DW	OLDLSDRIVE
	DB	4
	DW	OLDLDDRIVE
	ENDIF
	ENDIF

	IF	SCP*LARGE*FASTSEEK
;
; PerSci 277 or 299.
;
DRVTAB:	DB	00H,08H,01H,09H,00H,08H,01H,09H
TRKPT:	DB	0,0,0,0,0,0,0,0
TRKTAB:	DB	-1
INITTAB:
	IF	CONVERT-1
	DB	4
	ENDIF

	IF	CONVERT
	DB	8
	ENDIF

	DB	0
	DW	LSDRIVE
	DB	0
	DW	LDDRIVE
	DB	1
	DW	LSDRIVE
	DB	1
	DW	LDDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	2
	DW	OLDLDDRIVE
	DB	3
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLDDRIVE
	ENDIF
	ENDIF

	IF	TARBELLDD
;
; Two 8-inch Shugart-type drives.
;
DRVTAB:	DB	0,8,10H,18H,0,8,10H,18H
TRKPT:	DB	0,0,1,1,0,0,1,1
TRKTAB:	DB	-1,-1
INITTAB:

	IF	CONVERT-1
	DB	4
	ENDIF

	IF	CONVERT
	DB	8
	ENDIF

	DB	0
	DW	LSDRIVE
	DB	0
	DW	LDDRIVE
	DB	1
	DW	LSDRIVE
	DB	1
	DW	LDDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	2
	DW	OLDLDDRIVE
	DB	3
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLDDRIVE
	ENDIF
	ENDIF

	IF	TARBELLSD
;
; Four 8-inch Shugart-type drives.
;
DRVTAB:	DB	0F2H,0E2H,0F2H,0E2H
TRKPT:	DB	0,1,0,1
TRKTAB:	DB	-1,-1
INITTAB:

	IF	CONVERT-1
	DB	2
	ENDIF

	IF	CONVERT
	DB	4
	ENDIF

	DB	0
	DW	LSDRIVE
	DB	1
	DW	LSDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLSDRIVE
	ENDIF
	ENDIF
;
; Cromemco drive select byte is derived as follows:
;	Bit 7 = 0
;	Bit 6 = 1 if double density (if 16FDC)
;	Bit 5 = 1 (motor on)
;	Bit 4 = 0 for 5", 1 for 8" drives
;	Bit 3 = 1 for drive 3
;	Bit 2 = 1 for drive 2
;	Bit 1 = 1 for drive 1
;	Bit 0 = 1 for drive 0
;
	IF	CROMEMCO4FDC*LARGE
;
; PerSci 277 drive.
;
DRVTAB:	DB	31H,32H,31H,32H
TRKPT:	DB	0,0,0,0
TRKTAB:	DB	-1
INITTAB:

	IF	CONVERT-1
	DB	2
	ENDIF

	IF	CONVERT
	DB	4
	ENDIF

	DB	0
	DW	LSDRIVE
	DB	1
	DW	LSDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLSDRIVE
	ENDIF
	ENDIF

	IF	CROMEMCO4FDC*COMBIN
;
; A PerSci 277 and one 5.25-inch drive.
;
DRVTAB:	DB	31H,32H,24H,31H,32H
TRKPT:	DB	0,0,1,0,0
TRKTAB:	DB	-1,-1
INITTAB:

	IF	CONVERT-1
	DB	3
	ENDIF

	IF	CONVERT
	DB	5
	ENDIF

	DB	0
	DW	LSDRIVE
	DB	1
	DW	LSDRIVE
	DB	2
	DW	SSDRIVE

	IF	CONVERT
	DB	3
	DW	OLDLSDRIVE
	DB	4
	DW	OLDLSDRIVE
	ENDIF
	ENDIF

	IF	CROMEMCO4FDC*SMALL
;
; Three 5.25-inch drives.
;
DRVTAB:	DB	21H,22H,24H
TRKPT:	DB	0,1,2
TRKTAB:	DB	-1,-1,-1
INITTAB:DB	3
	DB	0
	DW	SSDRIVE
	DB	1
	DW	SSDRIVE
	DB	2
	DW	SSDRIVE
	ENDIF

	IF	CUSTOM
;
; Cromemco 4FDC with two 8-inch Shugart-type drives.
;
DRVTAB:	DB	31H,32H,31H,32H
TRKPT:	DB	0,1,0,1
TRKTAB:	DB	-1,-1
INITTAB:
	IF	CONVERT-1
	DB	2
	ENDIF

	IF	CONVERT
	DB	4
	ENDIF

	DB	0
	DW	LSDRIVE
	DB	1
	DW	LSDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLSDRIVE
	ENDIF
	ENDIF

	IF	CROMEMCO16FDC*SMALL
;
; Three 5.25-inch drives.
;
DRVTAB:	DB	21H,61H,22H,62H,24H,64H
TRKPT:	DB	0,0,1,1,2,2
TRKTAB:	DB	-1,-1,-1
INITTAB:DB	6
	DB	0
	DW	SSDRIVE
	DB	0
	DW	SDDRIVE
	DB	1
	DW	SSDRIVE
	DB	1
	DW	SDDRIVE
	DB	2
	DW	SSDRIVE
	DB	2
	DW	SDDRIVE
	ENDIF

	IF	CROMEMCO16FDC*COMBIN
;
; A PerSci 277 or 299 and one 5.25-inch drive.
;
DRVTAB:	DB	31H,71H,32H,72H,24H,64H,31H,71H,32H,72H
TRKPT:	DB	0,0,0,0,1,1,0,0,0,0
TRKTAB:	DB	-1,-1
INITTAB:
	IF	CONVERT-1
	DB	6
	ENDIF

	IF	CONVERT
	DB	10
	ENDIF

	DB	0
	DW	LSDRIVE
	DB	0
	DW	LDDRIVE
	DB	1
	DW	LSDRIVE
	DB	1
	DW	LDDRIVE
	DB	2
	DW	SSDRIVE
	DB	2
	DW	SDDRIVE

	IF	CONVERT
	DB	3
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLDDRIVE
	DB	4
	DW	OLDLSDRIVE
	DB	4
	DW	OLDLDDRIVE
	ENDIF
	ENDIF

	IF	CROMEMCO16FDC*LARGE
;
; A PerSci 277 or 299.
;
DRVTAB:	DB	31H,71H,32H,72H,31H,71H,32H,72H
TRKPT:	DB	0,0,0,0,0,0,0,0
TRKTAB:	DB	-1
INITTAB:
	IF	CONVERT-1
	DB	4
	ENDIF

	IF	CONVERT
	DB	8
	ENDIF

	DB	0
	DW	LSDRIVE
	DB	0
	DW	LDDRIVE
	DB	1
	DW	LSDRIVE
	DB	1
	DW	LDDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	2
	DW	OLDLDDRIVE
	DB	3
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLDDRIVE
	ENDIF
	ENDIF

	IF	SMALL+COMBIN
SSDRIVE:
	DW	128		; Sector size in bytes.
	DB	2		; Sector per allocation unit.
	DW	54		; Reserved sectors.
	DB	2		; Number of allocation tables.
	DW	64		; Number of directory entrys.
	DW	720		; Number of sectors on the disk.

	IF	SMALLDS-1
SDDRIVE:			; This is the IBM Personal Computer
	DW	512		; disk format.
	DB	1
	DW	1
	DB	2
	DW	64
	DW	320
	ENDIF

	IF	SMALLDS
SDDRIVE:
	DW	512
	DB	2
	DW	1
	DB	2
	DW	112
	DW	640
	ENDIF
	ENDIF			; End of small drive DPTs.

	IF	COMBIN+LARGE
LSDRIVE:
	DW	128		; Size of sector in bytes.
	DB	4		; Sectors per allocation unit.
	DW	1		; Number of reserved sectors.
	DB	2		; Number of File Allocation Tables.
	DW	68		; Number of directory entrys.
	DW	77*26		; Number of sectors on the disk.

	IF	CONVERT
OLDLSDRIVE:
	DW	128
	DB	4
	DW	52		; Old format had two tracks reserved.
	DB	2
	DW	64		; 64 directory entrys.
	DW	77*26
	ENDIF

	IF	LARGEDS-1
OLDLDDRIVE:
LDDRIVE:
	DW	1024
	DB	1
	DW	1
	DB	2
	DW	96
	DW	77*8
	ENDIF

	IF	LARGEDS
LDDRIVE:
	DW	1024
	DB	1
	DW	1
	DB	2
	DW	192		; 192 directory entrys in new 8-inch DD/DS format.
	DW	77*8*2

	IF	CONVERT
OLDLDDRIVE:
	DW	1024
	DB	1
	DW	1
	DB	2
	DW	128		; 128 directory entrys in old 8-inch DD/DS format.
	DW	77*8*2
	ENDIF
	ENDIF

	ENDIF			; End of large drive DPTs.

DOSSEG:	EQU	($+15)/16+BIOSSEG	; Compute segment to use for 86-DOS.
DOSDIF:	EQU	16*(DOSSEG-BIOSSEG)
STKSAV:	EQU	1701H+DOSDIF
DMAADD:	EQU	15B4H+DOSDIF
	END
