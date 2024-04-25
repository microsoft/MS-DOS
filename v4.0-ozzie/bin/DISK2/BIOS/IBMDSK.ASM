TITLE	DISK - MS-DOS 4.0 disk drivers for IBM
NAME	DISK

	PAGE	,132

;DEBUGFLG=1

.xlist
	INCLUDE DEFDBUG.INC
.list

; Constants

ErrLim=		5			; Number of retries on error

; Floppy delay constants

DelayLoad=	35			; 35 milliseconds to load head

; Constants for floppy disk controller

Rate99=		000H		; Step rate 96tpi disk in 96tpi drive
Rate49=		001H		; Step rate 48tpi disk in 96tpi drive
Rate44=		002H		; Step rate 48tpi disk in 48tpi drive

; Commands to floppy disk controller

FD_CRESET=	007H		; Recalibrate drive
FD_CSENSE=	008H		; Sense interrupt status
FD_CSEEK=	00FH		; Seek to another track
FD_CREAD=	046H		; MFM read, skip deleted data
FD_CWRITE=	045H		; MFM write, skip deleted data
FD_CSPEC=	003H		; Special - step rate, head load/unload

; Status codes

FD_SDIO=	01000000B	; Transfer direction (0 -> controller)
FD_SRQM=	10000000B	; Controller ready for next data

; Hard disk controller commands
HD_CSENS=	03H		; request sense block
HD_CREAD=	08H		; read
HD_CWRITE=	0AH		; write

HDcontrolbyte=	05H		; step rate = 70 us.

; I/O ports

FD_PSEL=	03F2H		; Controls drive select and motors
FD_PDAT=	03F5H		; Data transfer to/from controller
FD_PSTAT=	03F4H		; Controller status
FD_PCMD=	03F7H		; Controller command register

HD_PDAT=	0320H		; read/write data
HD_PSTAT=	0321H		; controller status
HD_PSEL=	0322H		; controller select
HD_PMSK=	0323H		; DMA and interrupt mask bits

PDMA=		0		; Base of ports for DMA control
PDMAX=		7FH		; Address extension regs for DMA
				;NOTE base address suitable for ch. 2 & 3 only
FD_DMA=		2		; floppy disk DMA channel
HD_DMA=		3		; hard disk DMA channel

DMA_READ=	44H		; DMA read command
DMA_WRITE=	48H		; DMA write command

; Misc

DORmask=	00CH		; Not reset, enable DMA & interrupt



SUBTTL	Data for performing requests
PAGE	+

;*	Dos Request Packet structure

DosPacket   STRUC
	RqCmdLen DB	0		; Length of this command
	RqUnit	DB	0		; Unit in this driver
	RqCmd	DB	0		; Command to do
	RqStatus DW	0		; Status of request
		DD	0
		DD	0		; Not used
	RqMedia DB	0		; Media descriptor
	RqAddr	DW	0		; Offset of data
		DW	0		; Segment of data
	RqCount DW	0		; Number of sectors
	RqFirst DW	0		; First sector to do
DosPacket	ENDS

;	The disk drivers work as a state machine performing the various actions
;  that make up disk I/O.

; Driver states
;	The following states are common to both drivers
Start=	0			; Starting I/O
Calc=	1			; Calculate position on disk
Done=	7			; I/O is done
Idle=	8			; Drive is inactive
Error=	9			; Have an error
;	The following states are used by the floppy driver only
Select= 2			; Select drive, start motor, seek
Recal=	3			; Drive was just recalibrated
Seek=	4			; Seek just finished
Settle= 5			; Head has settled
RdWri=	6			; Read/write is done
;	The following states are used by the fixed driver only
Verify= 6			; Start verify portion of write


DeviceStruc STRUC
	State	DW	Idle		; Current drive state
	Current DW	-1		; Current active drive
	ErrCnt	DB	0		; # of errors in doing request
	Flags	DB	0		; Various bit flags, see below
	DOR	DB	0		; Copy of select/motor reg
; Following values are set by Setup from the request packet and are
; updated after each transfer is completed.
	Unit	DB	0		; Unit
	First	DW	0		; 1st sector of request
	RealAddr DD	0		; Real addr of data when Addr is
					; scratch buffer.
	Count	DW	0		; Number of sectors to xfer
; Following values are set by MapSector.
	Cyl	DW	0		; Cylinder
	Sector	DB	0		; Sector - zero based
	Head	DB	0		; Head
	NumSectors DW	0		; Number of sectors to do
	NumBytes DW	0		; Number of bytes
	Addr	DD	0		; Pointer to data buffer
; Device dependent data
	ST0	DB	0		; floppy controller ST0
	ST1	DB	0		; floppy controller ST1
	ST2	DB	0		; floppy controller ST2
	CHRN	DB	0,0,0,0		; other floppy status returns
DeviceStruc	ENDS
	DCB	EQU	ST0		; Fixed disk Device Control Block

; Bits in Flags

    Factive=		1		; Actively working on something
    F2step=		2		; Must double step when seeking
    Fwrite=		4		; This is a write, not a read
    Fverify=		8		; This is a verify, not a rd/wr
    Fwrap1=		010H		; We are currently using ScratchBuffer
    Fwrap2=		020H		; We have used ScratchBuffer in this req

BiosSeg GROUP	Code,BiosInit

Code	SEGMENT BYTE PUBLIC	'CODE'
    ASSUME	CS:BiosSeg

IFDEF	DEBUGFLG
	EXTRN	BUGBITS:BYTE,DPRINTF:NEAR
ENDIF

SUBTTL	Device data
PAGE	+

Floppy	DeviceStruc	<>
Fixed	DeviceStruc	<>

;*	Per drive information, including BPBs

DriveStruc  STRUC
	BPBsecsiz	DW	512	; Physical sector size
	BPBsecpau	DB	1	; Sectors/Allocation unit
	BPBressec	DW	1	; Reserved sectors for DOS
	BPBnfat		DB	2	; # of allocation tables
	BPBndir		DW	64	; # of directory entries
	BPBnsec		DW	9*40	; Number of sectors
	BPBmediab	DB	0FCH	; Media descriptor
	BPBnfatsec	DW	2	; # of FAT sectors
	BPBtrksiz	DW	9	; # of sectors/track
	BPBnhead	DW	1	; # of heads
	BPBhidsec	DW	0	; Hidden sector count
	Timer		DB	0	; Countdown for motor off
	DrvFlag		DB	1	; Per-drive flags, see below
	TPI		DB	0	; Drive TPI= Not present, 48, 96
	CurCyl		DW	-1	; Current cylinder
DriveStruc	ENDS

;   DrvFlag values
Frestor=	1			; restore needed
Fmotoron=	2			; motor is on

DriveA	DriveStruc	<>		; floppy drive 0
DriveB	DriveStruc	<>		; floppy drive 1 or 0
DriveC	DriveStruc	<>		; hard drive 0 or floppy drive 2
DriveD	DriveStruc	<>		; hard drive 1 or floppy drive 3

FDinfo	DW	DriveA
	DW	DriveB
HDinfo	DW	DriveC
	DW	DriveD


; Structure of parameter block for floppy pointed to by 0:4*1E

FloppyParameter STRUC
	Spec1	DB	0		;  0  1st byte for specify cmd
	Spec2	DB	0		;  1  2nd byte for specify cmd
	DelayOff DB	0		;  2  # of Ticks(1/18.2) until
					;	motor shut off
	SectorSize DB	0		;  3  Sector size(128,256,512,1024)
					;	= (O,1,2,3 are put here)
	CylSize DB	0		;  4  Number of sectors/cylinder
	DataGap DB	0		;  5  Gap length of read/write
	ValueDTL DB	0		;  6  Data length (ignored)
	FormatGap DB	0		;  7  Gap for format operation
	FormatFill DB	0		;  8  Fill char for format
	DelaySettle DB	0		;  9  Head settle time in msec
	DelayMotor DB	0		; 10  Motor start time in 1/8 sec
FloppyParameter ENDS


ScratchBuffer	DB 512 DUP(?)	; Scratch buffer for when DMA fails
					; Hope we don't handle >512 sector
					; size

;*	Miscellaneous data

Single		DB	0		; non-zero if 1 floppy disk system
					;    in this case, NumFloppy will be 2

SUBTTL	Data for interface to 4.0
PAGE	+

	EXTRN	DosFunction:DWORD	; Addr of DOS function routine

; Dos helper functions used by disk driver

    PullRequest =	2		; Pull a request from the queue
    PushRequest =	4		; Add a request to the queue
    BlockProcess =	9		; Block process until I/O done
    ContinueProcess =  10		; I/O done, continue process

int_savregs=	32H			; interrupt routine which saves all regs


SwapSem1	DB	0		; non-zero if waiting to swap disks
SwapSem2	DB	0		; non-zero if waiting to prompt for swap
ScratchBufSem	DB	0		; semaphore controlling ScratchBuffer

SEM_WANT=	2
SEM_BUSY=	1

SemWait Macro	wchan
local	l1,l2
	pushf
l1:	cli
	test	wchan,SEM_BUSY		;;semaphore busy?
	jz	l2			;;no
	or	wchan,SEM_WANT		;;say we want it
	mov	ax,cs
	mov	bx,OFFSET wchan
	xor	cx,cx
	mov	dx,BlockProcess
	call	[DosFunction]		;;wait till semaphore released
	jmp	l1
l2:	or	wchan,SEM_BUSY		;;claim semaphore
	popf
	endm

SemSig	Macro	wchan
local	l
	test	wchan,SEM_WANT		;;anyone waiting on semaphore?
	jz	l
	mov	ax,cs
	mov	bx,OFFSET wchan
	mov	dx,ContinueProcess
	call	[DosFunction]
l:	and	wchan,NOT (SEM_WANT+SEM_BUSY)
	endm


FloppyQueue	DD  0			; List of requests for floppy
FixedQueue	DD  0			; List of requests for fixed disk

; Device driver headers

      PUBLIC	FloppyDevice
FloppyDevice	LABEL	WORD
	DD	FixedDevice		; Next device is hard disk
	DW	100000B			; This is 4.0 driver
	DW	JustReturn		; Strategy does nothing
	DW	FloppyRequest		; Interrupt does the work
NumFloppy	DB	4		; Handle 4 floppys maximum
	DB	0			; can be addressed as word also

	EXTRN	Com1Dev:NEAR

FixedDevice	LABEL	WORD
	DD	Com1Dev			; Next device is comm port 1
	DW	100000B			; This is 4.0 driver
	DW	JustReturn		; Strategy does nothing
	DW	FixedRequest		; Interrupt does work (misnomer)
NumFixed	DB	0		; Handle 2 hard disks maximum


; Utility routines which reside in the BIOS main module

	EXTRN	Interrupt:NEAR		; BIOS interrupt routine(misnomer)
	EXTRN	CmdErr:NEAR
	EXTRN	StatusDevReady:NEAR
	EXTRN	StatusComplete:NEAR
	EXTRN	StatusError:NEAR
	EXTRN	SetStatus:NEAR

JustReturn	PROC	FAR
	RET
JustReturn	ENDP

FloppyRequest	PROC	FAR
	debug	4,2,<FloppyRequest, es:bx $x:$x, cmd $d\n>,<es,bx,<word ptr es:[bx.RqCmd]>>
	PUSH	SI
	LEA	SI,FloppyFunction	; 4.0 function routines
	JMP	Interrupt		; Let BIOS figure out what to do
FloppyRequest	ENDP

; Dispatch table for actions of the floppy requested by 4.0

FloppyFunction	LABEL	WORD
	DW	FloppyInit		;  0  Initialize
	DW	FloppyCheck		;  1  Check media
	DW	FloppyBuild		;  2  Build BPB
	DW	CmdErr			;  3  IOCTL input
	DW	FloppyRead		;  4  Read
	DW	StatusDevReady		;  5  Non-destructive read
	DW	StatusComplete		;  6  Input status
	DW	StatusComplete		;  7  Input flush
	DW	FloppyWrite		;  8  Write
	DW	FloppyWriteV		;  9  Write with verify
	DW	CmdErr			; 10  Output status
	DW	CmdErr			; 11  Output flush
	DW	CmdErr			; 12  IOCTL output
	DW	CmdErr			; 13  Device open
	DW	CmdErr			; 14  Device close
	DW	CmdErr			; 15  Removable media
	DW	CmdErr			; 16  Generic IOCTL request

FixedRequest	PROC	FAR
	debug	8,2,<FixedRequest, es:bx $x:$x, cmd $d\n>,<es,bx,<word ptr es:[bx.RqCmd]>>
	PUSH	SI
	LEA	SI,FixedFunction	; 4.0 function routines
	JMP	Interrupt		; Let BIOS figure out what to do
FixedRequest	ENDP

; Dispatch table for actions of the hard disk requested by 4.0

FixedFunction	LABEL	WORD
	DW	FixedInit		;  0  Initialize
	DW	FixedCheck		;  1  Check media
	DW	FixedBuild		;  2  Build BPB
	DW	CmdErr			;  3  IOCTL input
	DW	FixedRead		;  4  Read
	DW	StatusDevReady		;  5  Non-destructive read
	DW	StatusComplete		;  6  Input status
	DW	StatusComplete		;  7  Input flush
	DW	FixedWrite		;  8  Write
	DW	FixedWriteV		;  9  Write with verify
	DW	CmdErr			; 10  Output status
	DW	CmdErr			; 11  Output flush
	DW	CmdErr			; 12  IOCTL output
	DW	CmdErr			; 13  Device open
	DW	CmdErr			; 14  Device close
	DW	CmdErr			; 15  Removable media
	DW	CmdErr			; 16  Generic IOCTL request


SUBTTL	Data for routines that make direct Int 13 requests
PAGE	+


RealInt13Vec	dw	0		; Used to make Int 13 requests
		dw	0
OldIntDVec	dw	0		; Must be reset when Int 13's on hard
		dw	0		;  disk.
OldIntEVec	dw	0		; Must be reset when Int 13's on floppy
		dw	0		;  disk.
SemDiskIO	db	0		; Semaphore controlling disk io
SemInt13	db	0		; Semaphore controlling Int 13's


SUBTTL	4.0 device driver routines (system entry points)
PAGE	+

BiosInit	SEGMENT PARA PUBLIC	'CODE'
    ASSUME	CS:BiosSeg

	PUBLIC	Disk_Init
Disk_Init	PROC
;**************************************************************
;	This routine performs device dependent initialization
;	during the BIOS initialization.	 Not to be confused
;	with the device initialization entry points which are
;	called later on and perform different functions.
;
;	AFTER THE EQUIPMENT CALL (INT 11H) BITS 6&7 WILL TELL
;	THE NUMBER OF FLOPPY DISKS IN THE SYSTEM.
;	THE INDICATIONS ARE AS FOLLOWS:
;
;	BITS	7	6	DRIVES
;		0	0	1
;		0	1	2
;		1	0	3
;		1	1	4
;**************************************************************

	debug	12,1,<Performing disk driver pre-DOS initialization\n>,<>
	PUSH	CS
	POP	DS

    ASSUME	DS:BiosSeg
	INT	11H			;GET EQUIPMENT STATUS
	rol	al,1			; rotate around to low order bits
	rol	al,1
	AND	AL,11B			;MASK DRIVE BITS
	JNZ	NOTSNGL		;Zero means single drive system
	INC	[SINGLE]	;REMEMBER THIS
	inc	al		; make it look like two-drive system
NOTSNGL:
	inc	al
	MOV	[NumFloppy],AL		;Remember how many drives
	MOV	AH,8
	MOV	DL,80H
	INT	13H		;Request number of hardfiles attached
	JC	ENDDRV		;Carry indicates old rom, so no hardfile
	MOV	[NumFixed],DL
	test	dl,dl			; any specified?
	jz	ENDDRV			; no
	cmp	NumFloppy,2		; too many floppies?
	jbe	ENDDRV
	mov	NumFloppy,2		; limit to two floppies max.
ENDDRV:

;*	Initialize the hard disk BPBs

	MOV	DL,80H
	MOV	DI,OFFSET DriveC
	CMP	[NumFixed],0
	JLE	ITSOK
	CALL	SETHRD		;SET UP FIRST HARDFILE

	MOV	DL,81H		;SET UP FOR NEXT CALL
	MOV	DI,OFFSET DriveD
	JC	NOTOK
	CMP	[NumFixed],2
	JZ	SETIT
	JMP	SHORT ITSOK
NOTOK:
	MOV	DI,OFFSET DriveC
	DEC	[NumFixed]
	CMP	[NumFixed],0
	JZ	ITSOK
SETIT:	CALL	SETHRD		;SET UP SECOND HARDFILE
	JNC	ITSOK
	DEC	[NumFixed]
ITSOK:
	cmp	[NumFixed],0	; any hard disks found?
	jnz	itsok2		; yes
	mov	ax,[FixedDevice]  ; no, patch device chain to skip fixed disk
	mov	[FloppyDevice],ax
itsok2:
	push	es			; Install Int 13 handler and save the
	xor	ax,ax			;  old value of the interrupt vector.
	mov	es,ax
	mov	ax,es:[4*13h]
	mov	[RealInt13Vec],ax
	mov	ax,OFFSET Int13Handler
	mov	es:[4*13H],ax
	mov	ax,es:[4*13h+2]
	mov	[RealInt13Vec+2],ax
	mov	es:[4*13H+2],cs
	mov	ax,es:[4*0dh]		; Save original Int D vector
	mov	[OldIntDVec],ax
	mov	ax,es:[4*0dh+2]
	mov	[OldIntDVec+2],ax
	mov	ax,es:[4*0eh]		; Save original Int E vector
	mov	[OldIntEVec],ax
	mov	ax,es:[4*0eh+2]
	mov	[OldIntEVec+2],ax
	pop	es
	ret
Disk_Init	ENDP

;
;	READ A BOOT RECORD INTO Scratch buffer
;
GETBOOT:
	MOV	CX,1
	MOV	AX,0201H
	push	CS
	pop	es
	mov	BX,OFFSET ScratchBuffer
	xor	DH,DH
	INT	13H
	JC	SETRET
	CMP	WORD PTR ES:[BX+1FEH],0AA55H
	JNZ	SETRET
	RET
;
;	SETUP VARIABLE SIZED HARDFILE
;	ON ENTRY DL=DRIVE NUMBER (80 OR 81)
;		DI=PTR TO B.P.B
;
SETHRD: PUSH	DX
	MOV	AH,8		;GET DRIVE PARAMETERS
	INT	13H
	INC	DH
	MOV	BYTE PTR [DI].BPBnhead,DH
	POP	DX
	JC	SETRET
	AND	CL,3FH
	MOV	BYTE PTR [DI].BPBtrksiz,CL
	CALL	GETBOOT		;GET THE BOOT RECORD
	JC	SETRET
	add	BX,1C2H
	mov	cx,4
SET1:	CMP	BYTE PTR ES:[BX],1
	JZ	SET2
	ADD	BX,16
	loop	SET1
SETRET: STC			;NOT FOUND SO USE DEFAULTS
	debug	8,3,<Sethrd err rtn: drive $x stat $x\n>,<dx,ax>
	RET

SET2:	MOV	AX,ES:[BX+4]
	MOV	DS:[DI].BPBhidsec,AX	;SET HIDDEN SECTOR COUNT
	MOV	AX,ES:[BX+8]
	CMP	AX,64			;HAS TO BE AT LEAST 32K
	JB	SETRET
	MOV	DS:[DI].BPBnsec,AX	;SAVE LOGICAL SECTOR COUNT
	MOV	CX,0100H		;SET CLUS SIZE AND SHIFT COUNT
	MOV	DX,64			;SET NUMBER OF DIR ENTRIES
	CMP	AX,512
	JBE	SET3

	ADD	CH,CH
	INC	CL
	MOV	DX,112
	CMP	AX,2048
	JBE	SET3

	ADD	CH,CH
	INC	CL
	MOV	DX,256
	CMP	AX,8192
	JBE	SET3

	ADD	CH,CH
	INC	CL
	ADD	DX,DX
	CMP	AX,32680	;NOT 32768! MAX NUMBER OF CLUSTERS=4085
	JBE	SET3

	ADD	CH,CH
	INC	CL
	ADD	DX,DX
SET3:
;
;	DX=NUMBER OF DIR ENTRIES, CH=NUMBER OF SECTORS PER CLUSTER
;				  CL=LOG BASE 2 OF CH
;
;	NOW CALCULATE SIZE OF FAT TABLE
;
	MOV	[DI].BPBndir,DX		;SAVE NUMBER OF DIR ENTRIES
	MOV	[DI].BPBsecpau,CH	;SAVE SECTORS PER CLUSTER
	XOR	BX,BX
	MOV	BL,CH
	DEC	BX
	ADD	BX,AX
	SHR	BX,CL			;DIVIDE BY SECTORS/CLUSTER
	INC	BX
	AND	BL,11111110B		;MAKE SURE COUNT IS EVEN
	MOV	SI,BX
	SHR	BX,1
	ADD	BX,SI			;MULTIPY BY 1.5
	ADD	BX,511
	SHR	BH,1
	MOV	BYTE PTR [DI].BPBnfatsec,BH	;SAVE NUMBER OF FAT SECTORS
	MOV	[DI].BPBmediab,0F8H	; set media byte
	CLC
	RET
BiosInit	ENDS

    ASSUME	CS:BiosSeg,DS:NOTHING,ES:NOTHING

FloppyInit	PROC
	debug	4,3,<Diskette initialization>,<>
	push	ds			; install floppy interrupt routine
	xor	ax,ax
	mov	ds,ax
	mov	ax,OFFSET FloppyInterrupt
	mov	ds:[4*0eH],ax
	mov	ds:[4*0eH+2],cs
	pop	ds
	call	Rst765
	mov	ah,[NumFloppy]
	mov	di,OFFSET FDinfo
DBBEG	4,3
	jmp	SHORT iniret
DBEND
	jmp	bpbret
ELSE
	jmp	SHORT bpbret
ENDIF
FloppyInit	ENDP

FixedInit	PROC
	debug	8,3,<Hard disk initialization>,<>
	push	ds			; install fixed disk interrupt routine
	xor	ax,ax
	mov	ds,ax
	mov	ax,OFFSET FixedInterrupt
	mov	ds:[4*0dH],ax
	mov	ds:[4*0dH+2],cs
	pop	ds
	in	al,21H			; unmask fixed disk interrupts
	and	al,0DFH
	out	21H,al
	mov	dx,HD_PMSK		; set interrupt and DMA mask bits
	mov	al,3
	out	dx,al
	mov	ah,[NumFixed]
	mov	di,OFFSET HDinfo
DBBEG	8,3
iniret: debug	12,3,< - Num=$x BPB table=$x:$x\n>,<ax,cs,di>
DBEND
ENDIF
	jmp	SHORT bpbret
FixedInit	ENDP

FloppyBuild	PROC
	mov	ah,byte ptr es:[di]
	call	FDGetBPB
bpbret: mov	[bx.RqMedia],ah
	mov	[bx.RqCount],di
	mov	[bx.RqCount+2],CS
	jmp	StatusComplete
FloppyBuild	ENDP

FixedBuild	PROC
	mov	ah,byte ptr es:[di]
	call	HDGetBPB
	jmp	SHORT bpbret
FixedBuild	ENDP

;***	FloppyCheck - check to see if the disk may have been changed.
;
;	ENTRY	AL = unit #
;		AH = media byte
;	EXIT	Return value in request header set to one of:
;			1	Media may have been changed
;			0	Media not changed
;			-1	Media was probably changed
;

FloppyCheck	PROC
	MOV	DL,1			; Assume not changed
	cmp	AH,0f8H			; Is disk removable?
	JE	FloppyCheckDone		; No, can't be changed then
	cmp	Single,0		; single drive system?
	je	flchk1			; no, check drive state
	cmp	Floppy.Unit,al		; unit = current drive?
	je	flchk1			; yes, check drive state
	mov	DL,-1			; say media changed for sure
	jmp	FloppyCheckDone
flchk1: MOV	CX,AX
	XOR	CH,CH
	MOV	SI,CX
	ADD	SI,SI
	MOV	SI,FDinfo[SI]		; Get pointer to drive info
	TEST	CS:[SI].DrvFlag,Fmotoron	; Is motor on?
	JNZ	FloppyCheckDone		; Yes, media not changed then
	XOR	DL,DL			; No, might have been changed
FloppyCheckDone:
	MOV	BYTE PTR DS:[BX].RqAddr,DL
	JMP	StatusComplete		; Return whether media changed
FloppyCheck	ENDP


FixedCheck	PROC
	MOV	DL,1
	JMP	FloppyCheckDone
FixedCheck	ENDP
;***	FloppyRead, FloppyWrite, FloppyWriteV - Basic I/O entry points
;
;	FloppyRead, FloppyWrite and FloppyWriteV are the basic I/O
;	routines used by the DOS.  They really do not do much except
;	queue the request and start the device if it is idle.
;	For single drive floppy systems, they also handle the
;	switching of disks when I/O changes from A to B or vice-versa.
;
;	ENTRY	DS:BX	Packet address
;		ES:DI	Transfer address
;		AL	Unit #
;		AH	Media Byte
;		CX	# of sectors
;		DX	Starting sector
;
;	EXIT	DS:BX	Packet Addr
;		CX	# of sectors left to do
;
;	USES	SI

FloppyRead	LABEL	NEAR
FloppyWrite	LABEL	NEAR
FloppyWriteV	PROC
	debug	4,2,<Fl rd/wt/ver  Req $x:$x  unit $b  sec $d  nsec $d\n>,<ds,bx,ax,dx,cx>
	call	BlockIfLocked
	push	di
	call	FDGetBPB		; cs:di => BPB
	mov	si,dx
	add	si,cx			; compute last sector + 1
	cmp	si,cs:[di.BPBnsec]
	mov	si,di
	pop	di
	jbe	flrw1
	mov	al,8			; ERROR - Sector not found
	jmp	StatusError

flrw1:	OR	CX,CX			; Anything to do?
	JNZ	flrw2			; Yes
	JMP	StatusComplete		; No, all done now
flrw2:
	CMP	Single,0		; Is this a single drive system?
	JE	flrw3			; No, don't check for drive change
	CALL	FloppyChange		; See if should change disks
flrw3:
	call	CheckWrap
	push	ds
	pop	es			; ES:BX = Request addr
	push	cs
	pop	ds
	LEA	SI,FloppyQueue		; DS:SI = ptr to head of queue
	MOV	DX,PushRequest
	CALL	DosFunction		; Add request to list
	push	es
	pop	ds			; Back to DS:BX is request
	pushf
	cli				; interrupts off while testing state
	TEST	Floppy.Flags,Factive	; Is driver active?
	JNE	FloppyActive		; Yes, driver will get to it
	PUSH	DS
	PUSH	BX			; Save some regs
	OR	Floppy.Flags,Factive
	MOV	Floppy.State,Start	; Want to start I/O
	CALL	FloppyExecute		; Start up the driver
	POP	BX
	POP	DS			; Restore regs
flrw4:	test	DS:[BX].RqStatus,0100H	; IO completed?
	JNZ	FloppyIOdone		; yes

FloppyActive:
	MOV	AX,DS			; AX:BX = request
	xor	cx,cx
	push	bx
	MOV	DX,BlockProcess
	CALL	DosFunction		; Block until I/O is done
	pop	bx
	jmp	flrw4			; test completion status again
FloppyIOdone:
	popf
	MOV	AX,DS:[BX].RqStatus	; Need AX = status
	MOV	CX,DS:[BX].RqCount	; Need CX = count left to do
	debug	4,2,<Fl rd/wt/ver DONE	Req $x:$x  stat $x  resid $d\n>,<ds,bx,ax,cx>
	JMP	SetStatus		; Return to DOS with results
FloppyWriteV	ENDP


FixedRead	LABEL	NEAR
FixedWrite	LABEL	NEAR
FixedWriteV	PROC
	debug	8,2,<Fix rd/wt/ver  Req $x:$x  unit $b	sec $d	nsec $d\n>,<ds,bx,ax,dx,cx>
	call	BlockIfLocked
	push	di
	call	HDGetBPB		; cs:di => BPB
	mov	si,dx
	add	si,cx			; compute last sector + 1
	cmp	si,cs:[di.BPBnsec]
	mov	si,di
	pop	di
	jbe	fxrw1
	mov	al,8			; ERROR - Sector not found
	jmp	StatusError

fxrw1:	OR	CX,CX			; Anything to do?
	JNZ	fxrw2			; Yes
	JMP	StatusComplete		; No, all done now
fxrw2:
	call	CheckWrap
	push	ds
	pop	es			; ES:BX = Request addr
	push	cs
	pop	ds
	LEA	SI,FixedQueue		; DS:SI = ptr to head of queue
	MOV	DX,PushRequest
	CALL	DosFunction		; Add request to list
	push	es
	pop	ds			; Back to DS:BX is request
	pushf
	cli				; interrupts off while testing state
	TEST	Fixed.Flags,Factive	; Is driver active?
	JNE	FixedActive		; Yes, driver will get to it
	PUSH	DS
	PUSH	BX			; Save some regs
	OR	Fixed.Flags,Factive
	MOV	Fixed.State,Start	; Want to start I/O
	CALL	FixedExecute		; Start up the driver
	POP	BX
	POP	DS			; Restore regs
fxrw4:	test	DS:[BX].RqStatus,0100H	; IO completed?
	JNZ	FixedIOdone		; yes

FixedActive:
	MOV	AX,DS			; AX:BX = request
	xor	cx,cx
	push	bx
	MOV	DX,BlockProcess
	CALL	DosFunction		; Block until I/O is done
	pop	bx
	jmp	fxrw4			; test completion status again
FixedIOdone:
	popf
	MOV	AX,DS:[BX].RqStatus	; Need AX = status
	MOV	CX,DS:[BX].RqCount	; Need CX = count left to do
	debug	8,2,<Fx rd/wt/ver DONE	Req $x:$x  stat $x  resid $d\n>,<ds,bx,ax,cx>
	JMP	SetStatus		; Return to DOS with results
FixedWriteV	ENDP

;***	CheckWrap - check whether a request crosses a 64Kb boundary
;
;	CheckWrap will check whether the request given in DS:BX
;	crosses a 64Kb boundary.  A portion of such requests must
;	be done using ScratchBuffer for a single sector transfer.
;	This routine ensures that only one such request is put into
;	either of the request queues at any time.
;
;	ENTRY	DS:BX	Request header
;		ES:DI	Transfer address
;		CS:SI	Pointer to BPB
;		CX	Sector count
;	EXIT	When it's safe to proceed.
;	USES	AX,BP

CheckWrap	PROC
	push	dx
	push	cx
	mov	ax,cx
	mul	cs:[si.BPBsecsiz]
	mov	dx,es			; compute offset
	mov	cl,4
	shl	dx,cl
	add	dx,di
	clc				; now see if offset+nbytes overflows
	add	dx,ax
	jnc	chkw8
	debug	12,10h,<CheckWrap $x $x:$x	>,<ax,es,di>
	push	bx
	SemWait ScratchBufSem		; wait for ScratchBuffer to be available
	pop	bx

chkw8:	pop	cx
	pop	dx
	ret
CheckWrap	ENDP


;***	FloppyChange - check whether floppy disk must be changed
;
;	FloppyChange is called on a single drive system to simulate a
;	two drive system.  The current request for I/O is checked against
;	what the driver considers to be the current drive.  If they are
;	the same, FloppyChange just returns.  Otherwise, SwapSem2 is set
;	and the current process is blocked on SwapSem2.	 Any process that
;	attempts I/O while SwapSem2 is set is blocked on SwapSem1.  When
;	SwapSem2 is cleared, these processes are continued.  When the
;	driver becomes idle and SwapSem2 is set, the Idle state continues
;	the blocked process.  This process then puts out the message about
;	switching disks and waits for a user reply.  When it is given,
;	FloppyChange clears SwapSem1 and causes the I/O to be started.
;
;	ENTRY	DS:BX	Pointer to I/O request
;
;	USES	AX,DX
;


FloppyChange	PROC
	push	cx
	pushf
	push	bx
	SemWait SwapSem1		; Currently waiting to switch disk?
	pop	bx

flcha1: and	SwapSem1,NOT SEM_BUSY	; reset BUSY for now
	MOV	AL,DS:[BX].RqUnit	; Get desired unit
	CMP	AL,Floppy.Unit		; Switching A and B drive?
	JE	flcha7			; No, keep using this drive
	CLI				; ** Disable interrupts
	OR	SwapSem1,SEM_BUSY	; Flag waiting to switch
	test	Floppy.Flags,Factive	; Is driver idle?
	JE	flcha2			; Yes, don't need to wait
	push	bx
	SemWait SwapSem2
	pop	bx
	jmp	flcha1
flcha2:
	popf				; restore interrupt state
	pushf
	ADD	AL,"A"			; Convert to drive letter
	MOV	CS:DriveLetter,AL	; Set the letter
	PUSH	DS
	PUSH	SI
	push	bx
	push	cs
	pop	ds
	LEA	SI,SwitchMsg
flcha4:
	LODSB
	OR	AL,AL			; End of message?
	JZ	flcha5			; Yes
	INT	29H			; No, output char
	JMP	flcha4			; Put out whole msg

flcha5:
	mov	ah,1			; Flush keyboard input
	int	16H
	jz	flcha5
	XOR	AH,AH
	INT	16H			; Wait for a char
	pop	bx
	POP	SI
	POP	DS
flcha7:
	push	bx
	SemSig	SwapSem1		; Allow blocked processes to continue
	pop	bx
flcha8:
	popf
	pop	cx
	RET

FloppyChange	ENDP


SwitchMsg	LABEL	WORD
	DB	13,10,"Insert diskette for drive "
DriveLetter	LABEL	BYTE
	DB	"A: and strike",13,10,"any key when ready",13,10,10,0


Int13Handler	Proc	Far
	push	dx			; Save regs used in local processing
	push	cx
	push	bx
	push	ax
	pushf
LockCheck:
	cli				; If any Int 13 request is already
	cmp	SemInt13,0		;  pending, block this process until
	jz	NotLocked		;  the previous one finishes.
	mov	ax,cs
	mov	bx,offset SemInt13
	xor	cx,cx
	mov	dx,BlockProcess
	call	DosFunction
	jmp	LockCheck
NotLocked:
	mov	SemInt13,1		; Lock out other disk requests
	popf
	pushf
BusyCheck:
	cli
	cmp	SemDiskIO,0		; If the disks are busy, block this
	jz	DiskFree		;  process till they free up.
	mov	ax,cs
	mov	bx,offset SemDiskIO
	xor	cx,cx
	mov	dx,BlockProcess
	call	DosFunction
	jmp	BusyCheck
DiskFree:
	popf
	sti
	pop	ax			; Restore regs for call
	pop	bx
	pop	cx
	pop	dx
	push	dx
	push	cx
	push	bx
	pushf
	call	dword ptr [RealInt13Vec]
	mov	SemInt13,0
	push	ax
	pushf
	mov	ax,cs			; Unblock anything that is waiting
	mov	bx,offset SemInt13
	mov	dx,ContinueProcess
	call	DosFunction
	popf				; Restore user regs
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	ret	2
Int13Handler	endp


SUBTTL	Fixed disk startup routine
PAGE	+

;	FixedExecute processes a disk request after it has been set up.	 When the
;  disk is inactive (State = Idle), it is called to start the device.  For all
;  subsequent events, it is called on the disk interrupt which signaled the
;  completion of that subfunction.  Some states do not involve waiting for an
;  interrupt to occur.	This routine runs entirely off the 'Fixed' data structure

FixedDispatch	LABEL	WORD
	DW	FxExStart
	DW	FxExCalc
	DW	FxExError		;; BUGBUG really error in state machine
	DW	FxExError		;; BUGBUG really error in state machine
	DW	FxExError		;; BUGBUG really error in state machine
	DW	FxExError		;; BUGBUG really error in state machine
	DW	FxExVerify
	DW	FxExDone
	DW	FxExIdle
	DW	FxExError

FixedExecute	PROC
	push	cs			; CS -> DS
	pop	ds
    ASSUME	DS:BiosSeg
	MOV	BX,Fixed.State		; Get current state
	debug	8,4,<FxEx state $d	>,<bx>
	ADD	BX,BX
	JMP	FixedDispatch[BX]	; Dispatch to correct routine


;*	Fixed state Start
;
;	Do setup calculations to figure out sector, start
;  up motor, advance to Calc state.
;
;  Entered on initially picking up a new request to do and on error retries.
;  If error retries start here, then multiple sector requests will always start
;  at the beginning rather than at the point of the error! Why?

FxExStart:
	mov	si,OFFSET Fixed		; SI = pointer to per-device info.
	les	bx,FixedQueue		; ES:BX = pointer to current request
	mov	al,es:[bx].RqUnit
	call	HDGetBPB		; DI = drive parameters
	CALL	Setup			; Do setup calculations
	MOV	Fixed.State,Calc	; Advance to next state
	JMP	FixedExecute		; Now return to do Calc code



;*	Fixed state Calc
;
;	Calculate cylinder, head and sector, wait for motor
;  start or head load, advance to Select state.
;
;  Entered after Start state and also on further sectors of a multiple sector
;  request.

FxExCalc:
	mov	si,OFFSET Fixed		; SI = pointer to per-device info.
	les	bx,FixedQueue		; ES:BX = pointer to current request
	mov	al,es:[bx].RqUnit
	call	HDGetBPB		; DI = drive parameters
	CALL	MapSector		; Get head, cylinder and sector
	test	Fixed.Flags,Fwrite
	jnz	fxxc1
	mov	al,DMA_read
	mov	Fixed.DCB,HD_CREAD
	jmp	SHORT fxxc2
fxxc1:	mov	al,DMA_write
	mov	Fixed.DCB,HD_CWRITE
fxxc2:	mov	ah,HD_DMA
	call	DMAsetup		; set up DMA transfer
	mov	al,Fixed.Unit
	mov	cl,5
	shl	ax,cl
	or	al,Fixed.Head
	mov	Fixed.DCB+1,al		; set head/unit
	mov	ax,Fixed.cyl
	mov	Fixed.DCB+3,al		; set low cylinder
	shr	ax,1
	shr	ax,1
	and	al,0C0H
	or	al,Fixed.Sector
	mov	Fixed.DCB+2,al		; set high cylinder/sector
	mov	al,BYTE PTR Fixed.Numsectors
	mov	Fixed.DCB+4,al		; set sector count
	mov	Fixed.DCB+5,HDcontrolbyte	;BUGBUG - what do we want here?
	mov	al,3
	call	HDCommand
	mov	al,Done			; assume next state is Done
	test	Fixed.Flags,Fverify
	jz	fxxc3
	mov	al,Verify
fxxc3:	mov	BYTE PTR Fixed.State,al		; set next state
	ret


;*	Fixed state Verify
;
;	Have executed a write function, must now verify.
; BUGBUG	For now just go to done state.

FxExVerify:
	mov	Fixed.State,Done
	jmp	FixedExecute



;*	Fixed state Done
;
;	If whole request is now complete, mark the request
;  as done and then start the next one if there is one.	 If the request is not
;  yet done, adjust values to show the amount of the request done and then go
;  back to the Calc state to do next part.

FxExDone:
	MOV	AL,Fixed.Flags
	AND	AL,Fwrite+Fwrap1	; Only interested in these bits
	CMP	AL,Fwrap1		; Just read into scratch?
	JNE	fxxd1			; No
	PUSH	DS
	PUSH	ES
	MOV	CX,Fixed.NumBytes	; CS = # bytes to write from scr
	LES	DI,Fixed.RealAddr	; ES:DI = real buffer
	LDS	SI,Fixed.Addr		; DS:SI = scratch buffer
	CLD
  REP	MOVSB				; Copy into real buffer
	POP	ES
	POP	DS
fxxd1:
	MOV	AX,Fixed.NumSectors	; AX = # of sectors we did
	SUB	Fixed.Count,AX		; Adjust count to number left
	JZ	fxxd3		; Request is done, tell DOS
	ADD	Fixed.First,AX		; Advance sector number
	MOV	AX,Fixed.NumBytes	; Number of bytes handled
	ADD	WORD PTR Fixed.RealAddr,AX ; Advance data address
	MOV	Fixed.State,Calc	; Go to Calc state
fxexj4: JMP	FixedExecute

fxxd3:
	mov	DI,OFFSET Fixed
	mov	SI,OFFSET FixedQueue	; DS:SI = head of queue
	call	DoneRequest
	JMP	fxexj4


;*	Fixed state Idle
;
;	Nothing hapenning, become inactive.

FxExIdle:
	and	Fixed.Flags,NOT Factive
	RET


;*	Fixed state Error
;
;	Entered when a non-recoverable error is detected.
;	A sense block has been requested and put into the
;	DCB.

FxExError:
	MOV	Fixed.State,Done	; Request is done
; Set error bits in request packet
	MOV	AL,Fixed.DCB		; Get status byte
	mov	bl,al			; isolate error type as word address
	and	bx,0030h
	mov	cl,3
	shr	bx,cl
	mov	bx,HDErrType[BX]	; index into error table by type
	and	ax,0Fh			; get error code
	cmp	al,ds:[bx]		; outside range of table?
	jae	fxxe1
	add	bx,ax
	mov	ah,ds:[bx+1]		; translate error code
	jmp	SHORT fxxe2
fxxe1:
	mov	ah,12
fxxe2:	dbbeg	8,4
	mov	di,OFFSET Fixed.DCB
	debug	8,4,<HD error: sense $b$b$b$b code $x\n>,<<[di]>,<[di+1]>,<[di+2]>,<[di+3]>,ax>
	dbend
	endif
	PUSH	ES
	LES	DI,FixedQueue		; Get ptr to request
	MOV	AL,ah
	MOV	AH,10000001B
	MOV	ES:[DI].RqStatus,AX	; Set error and code
	POP	ES
	JMP	fxxd3		; Advance to Done state
FixedExecute	ENDP

;*	Traslation of controller error codes to DOS error codes

HDErrType	DW	HDErrTyp0
		DW	HDErrTyp1
		DW	HDErrTyp2
		DW	HDErrTyp3

HDErrTyp0	DB	9, 12, 2, 6,10, 2,12, 6,12, 6
HDErrTyp1	DB	10, 4, 4, 8,12, 8, 6,12,12, 4, 6
HDErrTyp2	DB	2,  3, 8
HDErrTyp3	DB	3,  4, 4, 4

    ASSUME	CS:BiosSeg,DS:NOTHING,ES:NOTHING

FixedInterrupt	PROC	FAR
	debug	8,8,<FxIntr\n>,<>
	cmp	word [SemDiskIO],0001h
	jnz	fxinot13
	cmp	SemInt13,0		; If a direct Int13 request is being
	jz	fxinot13		;  made call the ROM floppy interrupt
	cmp	SemDiskIO,0		;  routine to handle it.
	jnz	fxinot13
	int	int_savregs
;;	in	al,21H			; Mask fixed disk interrupts
;;	or	al,20h
;;	out	21H,al
	pushf
	call	dword ptr [OldIntDVec]
	in	al,21H			; Unmask fixed disk interrupts
	and	al,0DFH
	out	21H,al
	mov	dx,HD_PMSK		; set interrupt and DMA mask bits
	mov	al,3
	out	dx,al
	iret
fxinot13:
	TEST	Fixed.Flags,Factive	; device active?
	JZ	fxinret			; no, go away
	INT	int_savregs		; save registers
	mov	dx,HD_PDAT
	in	al,dx			; get status reg.
;;	mov	ah,al
;;	mov	dx,HD_PMSK
;;	xor	al,al
;;	out	dx,al			; turn off intr. and DMA.
;;	test	ah,02h			; error bit set?
	test	al,02h			; error bit set?
	jz	fxin4			; no
;* error occurred.  see if retry, else get error code.
	push	cs
	pop	ds
    ASSUME	ds:BiosSeg
	CMP	Fixed.ErrCnt,ErrLim	; Reach error limit?
	JAE	fxin0			; Yes, request fails
	INC	Fixed.ErrCnt		; We are doing another try
	MOV	Fixed.State,Start	; Restart the request
	JMP	fxin4
fxin0:	mov	Fixed.DCB,HD_CSENS	; send sense command
	xor	al,al			; reset intr. & DMA masks
	call	HDCommand
	push	cs
	pop	es
	mov	di,OFFSET Fixed.DCB
	mov	cx,5
fxin1:	call	HDWaitReq		; get the sense block back
	mov	dx,HD_PDAT
	in	al,dx
	stosb
	loop	fxin1
	mov	Fixed.State,Error

    ASSUME	ds:NOTHING
fxin4:	CALL	FixedExecute
fxinret: push	ax
	MOV	AL,20H			; send EOI to 8259
	OUT	20H,AL
	pop	ax
	IRET
FixedInterrupt	ENDP

SUBTTL	Floppy disk startup routine
PAGE	+

;	FloppyExecute processes a disk request after it has been set up.
;	When the disk is inactive (State = Idle), it is called to start
;	the device.  For all subsequent events, it is called on the disk
;	interrupt which signaled the completion of that subfunction.
;	Some states do not involve waiting for an interrupt to occur.
;	This routine runs entirely off the 'Floppy' data structure

FloppyDispatch	LABEL	WORD
	DW	FlExStart
	DW	FlExCalc
	DW	FlExSelect
	DW	FlExRecal
	DW	FlExSeek
	DW	FlExSettle
	DW	FlExRdWri
	DW	FlExDone
	DW	FlExIdle
	DW	FlExError

FloppyExecute	PROC
	push	cs			; CS -> DS
	pop	ds
    ASSUME	DS:BiosSeg
	MOV	BX,Floppy.State		; Get current state
	debug	4,4,<FlEx state $d	>,<bx>
	ADD	BX,BX
	JMP	FloppyDispatch[BX]	; Dispatch to correct routine


;*	Floppy state Start
;
;	Do setup calculations to figure out sector, start
;  up motor, advance to Calc state.
;
;  Entered on initially picking up a new request to do and on error retries.
;  If error retries start here, then multiple sector requests will always start
;  at the beginning rather than at the point of the error! Why?

FlExStart:
	mov	si,OFFSET Floppy	; SI = pointer to per-device info.
	les	bx,FloppyQueue		; ES:BX = pointer to current request
	mov	al,es:[bx].RqUnit
	mov	ah,es:[bx].RqMedia
	call	FDGetBPB		; DI = drive parameters
	CALL	Setup			; Do setup calculations
	MOV	DX,FD_PCMD
	MOV	AL,Rate44
	OUT	DX,AL			; Set step rate
	MOV	Floppy.State,Calc	; Advance to next state
flexj1: JMP	FloppyExecute		; Now return to do Calc code



;*	Floppy state Calc
;
;	Calculate cylinder, head and sector, wait for motor
;  start or head load, advance to Select state.
;
;  Entered after Start state and also on further sectors of a multiple sector
;  request.

FlExCalc:
	mov	si,OFFSET Floppy	; SI = pointer to per-device info.
	les	bx,FloppyQueue		; ES:BX = pointer to current request
	mov	al,es:[bx].RqUnit
	mov	ah,es:[bx].RqMedia
	call	FDGetBPB			; DI = drive parameters
	CALL	MapSector		; Get head, cylinder and sector
	MOV	Floppy.State,Select	; Will advance to Select state
	CALL	Sel765			; Select the drive and maybe wait
	JNC	FloppyExecute		; Did select with no waiting
	RET				; Have set a timer, get out



;*	Floppy state Select
;
;	Recalibrate the drive if needed.  If Seek is
;  needed, start it and advance to Seek state.	Otherwise advance to Settle
;  state.

FlExSelect:
	call	GetDrivePtr
	OR	[BX].DrvFlag,Fmotoron	; we've been selected, so motor is on
	TEST	[BX].DrvFlag,Frestor	; Is a restore needed?
	JE	NoRestore		; No
	call	SetTimer2		; set a sanity/motor stop timer
	MOV	Floppy.State,Recal	; Next state will be recalibrate
	CALL	Rcl765			; Start the recalibrate
	RET				; Done until floppy interrupt arrives

NoRestore:				; Start the seek if any
	CALL	Seek765			; Start the seek to cylinder
	JNC	SeekOK			; Already on correct cylinder
	MOV	Floppy.State,Seek	; Next state is Seek
	call	GetDrivePtr
	call	SetTimer2		; set sanity timer
	RET				; Done until interrupt on seek done



;*	Floppy state Recal
;
;	If error, set state is Error.  Else, load drive
;  specs into controller and advance to Select state.

FlExRecal:
	CALL	Sense765
	OR	AX,AX			; Error in recal?
	JNZ	SeekErr			; Yes
RecalOK:
	CALL	Spec765			; Load drive specs
	MOV	Floppy.State,Select	; Back to select state now
flexj2: JMP	flexj1



;*	Floppy state Seek
;
;	If error, advance to Error state.  Otherwise, wait
;  for head to settle and advance to Settle state.

FlExSeek:
	CALL	Sense765		; Get status of seek
	OR	AX,AX			; Any error?
	JZ	SeekOK			; No
SeekErr:
	CALL	GetDrivePtr
	OR	[BX].DrvFlag,Frestor	; flag restore needed
	MOV	Floppy.State,Error	; Yes, next state is Error
	or	Floppy.ST1,8		; indicate seek error in an unused bit
	JMP	flexj2

SeekOK:
	MOV	Floppy.State,Settle	; Next state is Settle
	MOV	AL,DelaySettle
	CALL	GetFloppyParam		; Get the settle time in Msecs
	xor	ah,ah
	CALL	SetTimer1		; Set the timer
	JNC	flexj2
	RET



;*	Floppy state Settle
;
;	Start the read/write request and advance to the RdWri state.

FlExSettle:
	MOV	Floppy.State,RdWri	; Advance to read/write state
	CALL	RdWr765			; Start the I/O
	call	GetDrivePtr
	call	SetTimer2		; set sanity timer
	RET				; Done until floppy interrupt



;*	Floppy state RdWri
;
;	If error, next state is Error.	Otherwise next state is Done.

FlExRdWri:
	CALL	Fini765			; Get status of I/O
	OR	AX,AX			; Any error?
	JZ	RdWriOK			; No
	MOV	Floppy.State,Error	; Yes, go to error state
	JMP	flexj2

RdWriOK:
	MOV	Floppy.State,Done	; I/O is done
flexj3: JMP	flexj2



;*	Floppy state Done
;
;	If whole request is now complete, mark the request
;  as done and then start the next one if there is one.	 If the request is not
;  yet done, adjust values to show the amount of the request done and then go
;  back to the Calc state to do next part.

FlExDone:
	MOV	AL,Floppy.Flags
	AND	AL,Fwrite+Fverify+Fwrap1	; Only interested in these bits
	CMP	AL,Fwrap1		; Just read into scratch?
	JNE	DoneNotWrap		; No
	PUSH	DS
	PUSH	ES
	MOV	CX,Floppy.NumBytes	; CS = # bytes to write from scr
	LES	DI,Floppy.RealAddr	; ES:DI = real buffer
	LDS	SI,Floppy.Addr		; DS:SI = scratch buffer
	CLD
  REP	MOVSB				; Copy into real buffer
	POP	ES
	POP	DS
DoneNotWrap:
	AND	AL,Fwrite+Fverify	; Just want to see these bits
	CMP	AL,Fwrite+Fverify	; Just do write part of write+verify?
	JNE	DoneNotWritePart	; No
	AND	Floppy.Flags,NOT Fwrite ; Yes, do verify next
	mov	Floppy.State,Settle	;   don't need to calc or seek
	jmp	flexj3

DoneNotWritePart:
	CMP	AL,Fverify		; Just do verify part of write+verify?
	JNE	DoneNotVerify		; No
	OR	Floppy.Flags,Fwrite	; Yes, flip write back up for next
DoneNotVerify:
	MOV	AX,Floppy.NumSectors	; AX = # of sectors we did
	SUB	Floppy.Count,AX		; Adjust count to number left
	JZ	flxd3		; Request is done, tell DOS
	ADD	Floppy.First,AX		; Advance sector number
	MOV	AX,Floppy.NumBytes	; Number of bytes handled
	ADD	WORD PTR Floppy.RealAddr,AX ; Advance data address
	MOV	Floppy.State,Calc	; Go to Calc state
flexj4: JMP	flexj3

flxd3:
	mov	di,OFFSET Floppy
	mov	SI,OFFSET FloppyQueue	; DS:SI = head of floppy queue
	call	DoneRequest
	JMP	flexj4


;*	Floppy state Idle
;
;	Nothing hapenning except possible motor off timeout.

FlExIdle:
	call	GetDrivePtr
	CALL	SetTimer2		; Set the motor timer
	and	Floppy.Flags,NOT Factive
	SemSig	SwapSem2		; someone waiting to switch drive?
	RET


;*	Floppy state Error
;
;	If error count not exceeded, restore the drive and start
;  the request over again.  Otherwise set error in the packet and
;  advance to the Done state.

FlExError:
	CALL	Rst765			; Reset the controller
	CMP	Floppy.ErrCnt,ErrLim	; Reach error limit?
	JAE	FloppyFails		; Yes, request fails
	INC	Floppy.ErrCnt		; We are doing another try
	MOV	Floppy.State,Start	; Restart the request
	JMP	flexj4		; Back to state machine loop

FloppyFails:
	call	GetDrivePtr
	OR	CS:[BX].DrvFlag,Frestor ; Set drive needs a restore
	MOV	Floppy.State,Done	; Request is done
; Set error bits in request packet
	MOV	AX, WORD PTR Floppy.ST0 ; Get ST0, ST1
	mov	BL,2			; Drive not ready?
	test	AL,0cH
	jne	ErrorFound
	MOV	BL,6			; Bad seek?
	TEST	AH,8
	JNE	ErrorFound
	MOV	BL,4			; CRC error?
	TEST	AH,30H
	JNE	ErrorFound
	MOV	BL,8			; Sector not found?
	TEST	AH,85H
	JNE	ErrorFound
	MOV	BL,0			; Write protect?
	TEST	AH,2
	JNE	ErrorFound
	MOV	BL,12			; Catch-all error
ErrorFound:
	debug	4,4,<FD error: status $x code $b\n>,<ax,bx>
	PUSH	ES
	LES	DI,FloppyQueue		; Get ptr to request
	MOV	AL,BL
	MOV	AH,10000001B
	MOV	ES:[DI].RqStatus,AX	; Set error and code
	POP	ES
	JMP	flxd3			; Advance to Done state (via shortcut)

FloppyExecute	ENDP


    ASSUME	CS:BiosSeg,DS:NOTHING,ES:NOTHING

FloppyInterrupt PROC	FAR
	debug	4,8,<FlIntr\n>,<>
	cmp	SemInt13,0		; If a direct Int13 request is being
	jz	flinot13		;  made call the ROM floppy interrupt
	cmp	SemDiskIO,0		;  routine to handle it.
	jnz	flinot13
	int	int_savregs
	pushf
	call	dword ptr [OldIntEVec]
	iret
flinot13:
	TEST	Floppy.Flags,Factive	; device active?
	JZ	flinret			; no, go away
	INT	int_savregs		; save registers
	CALL	FloppyExecute
flinret: push	ax
	MOV	AL,20H			; send EOI to 8259
	OUT	20H,AL
	pop	ax
	IRET
FloppyInterrupt ENDP

SUBTTL	Timing routines for floppy disk
PAGE	+

;*  Data for timers
TimerActive	DB	0		; bit flags for active timers
TimerConv	DB	50		; conversion factor for ms => ticks
Timer1	DB	0			; One-shot time till restart intr. rtn.
Timer2	DB	0			; Repetitive 1 Hz timer
Timer2count	=	20		; Reload value for timer2

MOFFDELAY=	2			; turn off motor after 2 sec. inactivity

;***	SetTimer1 - Arm timer 1
;
;	SetTimer1 will arm the Timer1.	Input parameter
;	values in milliseconds will be converted to timer
;	ticks.
;
;	ENTRY	AX = delay value in milliseconds
;	EXIT	AL = timer ticks
;		CF set if timer armed
;		CF clear if zero count passed
;	USES	AX

SetTimer1	PROC
	TEST	AX,AX			; zero count?
	JNZ	sett10			; no
	CLC
	RET

sett10: DIV	TimerConv
	TEST	AH,AH			; remainder?
	JZ	sett11
	INC	AL			; yes, round up
sett11: MOV	Timer1,AL
	OR	TimerActive,1
	debug	4,8,<SetTimer1 $b\n>,<ax>
	STC
	RET
SetTimer1	ENDP

;***	SetTimer2 - Arm timer 2
;
;	SetTimer2 will set a motor off timeout for the
;	drive whose parameter block is pointed to by
;	CS:BX
;
;	ENTRY	CS:BX = pointer to per drive info.
;	EXIT
;	USES	NONE

SetTimer2	PROC
	TEST	TimerActive,2
	JNZ	sett21
	MOV	Timer2,Timer2Count
	OR	TimerActive,2
sett21: MOV	CS:[BX].Timer,MOFFDELAY
	debug	4,8,<SetTimer2\n>,<>
	RET
SetTimer2	ENDP



;	FloppyTimer is called every scheduler tick to perform
;  time related services for the floppy driver.	 There are
;  two services performed; rescheduling of interrupt time
;  service after a head load or motor startup delay, and
;  a motor turn off service when a drive is not active.
;
;  It's assumed that all registers have been saved by the
;  caller.

	ASSUME	CS:BiosSeg,DS:NOTHING,ES:NOTHING

	PUBLIC	FloppyTimer
FloppyTimer	PROC	FAR
	TEST	TimerActive,0ffH	; any timers active?
	JNZ	fltim1			; yes
	RET				; no, return quickly
fltim1: TEST	TimerActive,1		; Timer1 active?
	JZ	fltim3			; no
	DEC	Timer1			; Timer1 expired?
	JNZ	fltim3			; no
;*  Perform Timer1 service
	debug	4,8,<Timer 1 expired\n>,<>
	AND	TimerActive,NOT 1
	CALL	FloppyExecute		; push the states around a while
	RET				; don't do Timer2 service this time.

fltim3: TEST	TimerActive,2		; Timer2 active?
	JZ	fltim4			; no
	DEC	Timer2			; 1 Hz clock time?
	JZ	fltim5			; no
fltim4: JMP	fltim9
fltim5:
	debug	4,8,<Timer 2 expired\n>,<>
	MOV	BL,Timer2count		; reload the counter
	MOV	Timer2,BL

;*  Perform Timer2 service
	XOR	CH,CH			; No active timeouts seen
	XOR	DI,DI			; Start with drive A
TimeOutLoop:
	MOV	BX,DI
	ADD	BX,BX
	MOV	BX,FDinfo[BX]		; Get ptr to drive info
	TEST	CS:[BX].DrvFlag,Fmotoron	; motor on?
	JZ	fltim8			; no
	CMP	CS:[BX].Timer,0		; Is timer active for drive?
	JZ	fltim8			; No
	DEC	CS:[BX].Timer		; Yes, another tick has passed
	JNZ	fltim7
	cmp	di,Floppy.Current	; Current drive?
	jnz	fltim6			; no
	test	Floppy.Flags,Factive	; device active?
	jz	fltim6			; no, go ahead
	mov	Floppy.State,Error
	mov	Floppy.ErrCnt,ErrLim	; don't retry this one
	mov	Floppy.ST0,048H		; set not ready error
	call	FloppyExecute		; oops, sanity timeout
	jmp	fltim9
fltim6:
	AND	CS:[BX].DrvFlag,NOT Fmotoron	; stop drive motor
	MOV	AX,DI
	MOV	CL,AL
	ADD	CL,4
	MOV	AL,1
	SHL	AL,CL			; Get bit mask for motor on
	TEST	Floppy.DOR,AL		; Is motor already off?
	JE	fltim8			; Yes, go on to next drive
	NOT	AL			; Get all bits except this motor
	AND	Floppy.DOR,AL		; Clear this motor on
	MOV	DX,FD_PSEL
	MOV	AL,Floppy.DOR
	OUT	DX,AL			; Turn off motor
;;	cmp	di,Floppy.Current	; Current drive?
;;	jnz	fltim8			; no
;;	test	Floppy.Flags,Factive	; device active
;;	jz	fltim8			; no, go on to next drive
;;	call	DumpRegs		; oops, sanity timeout

fltim7: INC	CH			; Flag still active
fltim8: INC	DI			; Advance to next drive
	CMP	DI,WORD PTR NumFloppy	; Any more to check?
	JNE	TimeOutLoop		; Yes, do them
	OR	CH,CH			; Need to keep timer active?
	JNZ	fltim9			; Yes
	AND	TimerActive,NOT 2	; No, clear timeout is active
fltim9: RET

FloppyTimer	ENDP


IFDEF	DEBUGFLG
DumpRegs	PROC
	push	cs
	pop	ds
	debug	4,0fh,<Sanity Timeout!!\n>,<>
	mov	di,OFFSET Floppy
	debug	4,0fh,<Floppy struct\n	$x $x $x $x  $x $x $x $x\n>,<[di],[di.2],[di.4],[di.6],[di.8],[di.10],[di.12],[di.14]>
	debug	4,0fh,<	 $x $x $x $x  $x $x $x $x\n>,<[di.10h],[di.12h],[di.14h],[di.16h],[di.18h],[di.1ah],[di.1ch],[di.1eh]>
	call	GetDrivePtr
	debug	4,0fh,<Drive struct\n  $x $x $x $x  $x $x $x $x\n>,<[bx],[bx.2],[bx.4],[bx.6],[bx.8],[bx.10],[bx.12],[bx.14]>
	debug	4,0fh,<	 $x $x $x $x\n>,<[bx.16],[bx.18],[bx.20],[bx.22]>
	debug	4,0fh,<	 IMR IRR ISR	8259 status\n>,<>
	mov	al,0ah
	out	20h,al
	in	al,20h
	mov	bl,al

	mov	al,0bh
	out	20h,al
	in	al,20h
	mov	cl,al
	in	al,21h
	debug	4,0fh,<	 $b  $b	 $b\n>,<ax,bx,cx>
	debug	4,0fh,<765 status, data\n>,<>
	mov	dx,FD_PSTAT
	in	al,dx
	mov	bl,al
	mov	dx,FD_PDAT
	in	al,dx
	debug	4,0fh,<	    $b	    $b\n>,<bx,ax>
	sti
dmpr0:	jmp	dmpr0
DumpRegs	ENDP
ENDIF	;DEUBGFLAG

SUBTTL	Routines shared between Floppy and Hard disk drivers
PAGE	+

;***	Setup - Set request parameters into local structure.
;
;	Setup sets the Unit, First, Addr, Count and Flags fields in the
;	device structure which are used to drive the I/O.  The following
;	flags are affected:
;		Fwrite	This is a write request, not a read
;		Fverify This is a write with verify (verify when write
;			is cleared).
;	Other fields are copied from the DOS request packet.
;
;	ENTRY	SI	Pointer to device variables
;		ES:BX	Current request
;		AL	Unit number
;		DI	BPB for drive
;		DS	CS
;
;	EXIT	The following variables are set
;			[SI].Unit
;			[SI].First	The hidden sectors are added
;			[SI].RealAddr
;			[SI].Count
;			[SI].Flags

    ASSUME	CS:BiosSeg,DS:BiosSeg

Setup	PROC
	MOV	AX,ES:[BX].RqCount
	MOV	[SI].Count,AX		; Set number of sectors to do
	MOV	AX,ES:[BX].RqAddr
	MOV	WORD PTR [SI].RealAddr,AX
	MOV	AX,ES:[BX].RqAddr+2
	MOV	WORD PTR [SI].RealAddr+2,AX  ; Copy data address
	MOV	AL,ES:[BX].RqUnit	; Get unit number
	MOV	[SI].Unit,AL		; Set drive needed
	MOV	AX,ES:[BX].RqFirst	; Get the starting sector number
	ADD	AX,[DI].BPBhidsec	; Add # of hidden sectors
	MOV	[SI].First,AX		; Set 1st sector of I/O
	and	[SI].Flags,Factive+F2step	; mask excess flags
	CMP	ES:[BX].RqCmd,4		; Is this a read?
	JE	SetupDone		; Yes, all done
	OR	[SI].Flags,Fwrite	; No, flag this is a read
	CMP	ES:[BX].RqCmd,9		; Write with verify?
	JNE	SetupDone		; No, just write
	OR	[SI].Flags,Fverify	; Yes, set to verify too
SetupDone:
	RET
Setup	ENDP


;***	MapSector - compute head, sector, cylinder
;
;	MapSector takes the fields set up by Setup and figures out the
;	head, cylinder and sector involved.  If the request involves
;	multiple sectors, it figures out how many can be done at once
;	based on the number of sectors left on the track and that the
;	target address' offset does not wrap around 64k (the DMA on the
;	PC uses a 20 bit address, but the high 4 bits do not change when
;	the low 16 cycle back to 0).  If the request wraps around 64k, it
;	is split into 2 or 3 pieces which are all data before wrap, after
;	wrap and the wrap itself.  The wrap itself is transferred via a temp
;	buffer (ScratchBuffer).
;
;	ENTRY	SI	Pointer to device variables
;		ES:BX	Current request
;		AL	Unit number
;		DI	BPB for drive
;		DS	CS
;	EXIT	The following variables are set
;			[SI].Flags
;			[SI].Head
;			[SI].Cyl
;			[SI].Sector
;			[SI].NumSectors
;			[SI].NumBytes
;			[SI].Addr
;	USES	AX,CX,DX,DI
;

MapSector	PROC
	PUSH	ES
	les	CX,[SI].RealAddr
	MOV	WORD PTR [SI].Addr,CX		; copy RealAddr to Addr
	MOV	WORD PTR [SI].Addr+2,ES
	AND	[SI].Flags,NOT Fwrap1		; Clear buffer wrap flag

; Calculate the head, cylinder and sector of the start of the request
; from [SI].First
	POP	ES
	MOV	AX,[SI].First
	XOR	DX,DX
	DIV	[DI].BPBtrksiz		; Divide by sectors/track
;;	INC	DL
	MOV	[SI].Sector,DL		; Set sector to start at
	XOR	DX,DX
	DIV	[DI].BPBnhead		; Divide by number of heads
	MOV	[SI].Head,DL		; Set head number
	MOV	[SI].Cyl,AX		; Set cylinder number
	debug	8,4,<Cyl $d  Hd $b  Sec $b	>,<ax,dx,<word ptr [SI].Sector>>
;
; Now see how many sectors of request can be done.  The floppy
; controller will not advance tracks, but will allow reading or
; writing the remaining sectors on the track.
;
	MOV	AX,[DI].BPBtrksiz
	SUB	AL,[SI].Sector		; AL = # of sectors left on
					; track after desired.
	XOR	AH,AH
;;	inc	ax
	CMP	AX,[SI].Count		; Is whole request on this cyl?
	JB	maps2		; No, can only do what is left
	MOV	AX,[SI].Count		; Yes, use the actual # wanted
maps2:
	MOV	[SI].Numsectors,AX	; Set number to do this time
;
; Now have to normalize offset (add in paragraph) and then see if adding
; [SI].Numsectors causes overflow.  If it does, DMA will trash memory, so
; decrement Numsectors and loop.
;
	MOV	AX,WORD PTR([SI].Addr+2)
	MOV	CL,4
	SHL	AX,CL			; Convert para to offset
	ADD	AX,WORD PTR [SI].Addr	; Add in offset
	MOV	CX,AX			; Save offset of buffer
maps4:
	MOV	AX,[DI].BPBsecsiz
	MUL	[SI].NumSectors		; Get # bytes in transfer
	MOV	[SI].NumBytes,AX	; Set # bytes involved
	ADD	AX,CX			; Get final offset
	JAE	maps6			; No overflow, DMA will be ok
	OR	[SI].Flags,Fwrap2	; Flag we will be using scratch
	DEC	[SI].NumSectors		; Overflow, try using one less
	JNZ	maps4
;
; If we got here, no sectors can be transferred before the 64K
; boundary.  One sector must be transferred through a scratch buffer.
;
	debug	12,10h,<MapSector $x $x >,<ax,cx>
	INC	[SI].NumSectors		; Doing 1 sector of I/O
	OR	[SI].Flags,Fwrap1	; Flag we are using scratch
	MOV	AX,CS
	MOV	DI,OFFSET ScratchBuffer
	MOV	WORD PTR([SI].Addr),DI
	MOV	WORD PTR([SI].Addr+2),AX  ; Change buffer to scratch
	TEST	[SI].Flags,Fwrite	; Doing a write?
	JE	maps6			; No, All done
	PUSH	ES
	PUSH	DS
	PUSH	SI
	MOV	ES,AX			; ES:DI = scratch buffer
	mov	cx,[SI].NumBytes
	LDS	SI,[SI].RealAddr	; DS:SI = Data buffer
	CLD
REP	MOVSB				; Copy the write buffer
	POP	SI
	POP	DS
	POP	ES
maps6:
	RET
MapSector	ENDP




;***	DMAsetup - Set the DMA channel up to do the I/O
;
;	ENTRY	AL = DMA mode
;		AH = DMA channel number (2 or 3 only)
;		SI = pointer to device parameters
;	USES	AX,CX,DX
;

DMAsetup	PROC
	PUSH	AX
	XCHG	AH,AL
	OR	AL,4
	OUT	PDMA+10,AL		; set channel's mask bit
	OUT	PDMA+12,AL		; clear byte pointer F/F
	pop	ax
	push	ax			; restore AH, AL
	OR	AL,AH			; add channel number to command
	OUT	PDMA+11,AL		; Set DMA mode
	MOV	DX,PDMA
	ROL	AH,1
	ADD	DL,AH
	MOV	AX,WORD PTR [SI].Addr+2 ; Get segment of addr
	MOV	CL,4
	ROL	AX,CL			; Convert para to bytes
	MOV	CH,AL			; CH = 4 bits ROLed around
	AND	AL,0F0H			; Lose high bits rotated around
	ADD	AX,WORD PTR [SI].Addr	; Add in offset value
	ADC	CH,0			; Add in any carry
	OUT	DX,AL			; Output low byte of address
	MOV	AL,AH
	OUT	DX,AL			; Output high byte of address
	inc	dx			; address `word' count register
	MOV	AX,[SI].NumBytes	; # bytes in request
	dec	ax
	OUT	DX,AL
	MOV	AL,AH
	OUT	DX,AL			; Tell DMA how many bytes
	pop	ax			; get back channel number
	mov	dl,PDMAX
	add	dl,ah
	MOV	AL,CH
	AND	AL,0FH			; Only 4 bits are good
	OUT	DX,AL			; Output highest 4 bits of address
	MOV	AL,AH			; Channel to start
	OUT	PDMA+10,AL		; Clear channel's mask bit
	RET
DMAsetup	ENDP

;***	DoneRequest - Mark a request complete, setup to start next one
;
;	DoneRequest does common processing needed when a request
;	has been completed.  It will reset the device state,
;	dequeue the request, mark it complete, restart the
;	process and restart any process waiting on ScratchBuffer
;	if this request had reserved it.
;
;	ENTRY	SI	Pointer to head of queue
;		DI	Pointer to device information
;	EXIT	ES:BX	Next request
;	USES	AX,BX,DX,BP,ES


DoneRequest	PROC
	push	cs
	pop	ds
    ASSUME	ds:BiosSeg
	MOV	[DI].ErrCnt,0		; Reset error count
	MOV	[DI].State,Idle		; Assume will be idle
	MOV	DX,PullRequest
	CALL	DosFunction		; Pull the current request out
	JZ	dnrq2			; Nothing really completed
	MOV	AX,[DI].Count		; Get I/O left to do
	SUB	ES:[BX].RqCount,AX	; Adjust requested count by residual
	OR	ES:[BX].RqStatus,0100h	; set done bit
	MOV	AX,ES			; AX:BX = Request completed
	MOV	DX,ContinueProcess
	CALL	DosFunction		; Make process run again
	CMP	WORD PTR [SI]+2,0	; Is there another request to do?
	JZ	dnrq2			; No, let device shut down
	MOV	[DI].State,Start	; Yes, start up next request
dnrq2:
	test	[DI].Flags,Fwrap2	; had this request used ScratchBuffer?
	jz	dnrq4			; no
	SemSig	ScratchBufSem		; let anyone waiting proceed
	and	[DI].Flags,NOT Fwrap2
dnrq4:					; If both the fixed and floppy drivers
	push	bx			;  are idle, reset the busy flag and
	cmp	Floppy.State,Idle	;  continue any processes that were
	jne	dnrq5			;  waiting for it.
	cmp	Fixed.State,Idle
	jne	dnrq5
	mov	SemDiskIO,0
	mov	ax,ds
	mov	bx,offset SemDiskIO
	mov	dx,ContinueProcess
	call	DosFunction
dnrq5:
	pop	bx
	ret
DoneRequest	ENDP


;	FDGetBPB returns a pointer to the floppy disk BPB for the
;  selected media byte.	 The BPB contains various drive parameters
;  such as physical disk dimensions and the size of FATs and the
;  root directory.
;
;  Input:	AH =	Media byte
;		AL =	Drive number
;  Destroys:	None
;  Output:	CS:DI = Pointer to BPB

	ASSUME	DS:NOTHING,ES:NOTHING

FDGetBPB	PROC

	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX			; Save regs
	MOV	CL,AH			; Copy media value
	AND	CL,0F8H			; Look at just top 5 bits
	CMP	CL,0F8H			; Valid media byte?
	JE	BPBGood			; Yes
	MOV	AH,0FEH			; No, make it 8 sector 1 sided
BPBgood:
	MOV	BL,AL			; Get pointer to per drive info.
	XOR	BH,BH
	ADD	BX,BX
	MOV	DI,CS:FDinfo[BX]
	CMP	AH,CS:[DI].BPBmediab	; already set?
	JE	BPBdone			; yes, don't bother rebuilding
	MOV	AL,1			; Assume will have 1 FAT sector
	MOV	BX,64*256+8		; Assume # dir = 64,  8 sector
	MOV	CX,40*8			; Assume 320 sectors/disk
	MOV	DX,1*256+1		; Assume 1 head, 1 sector/allocate
	TEST	AH,2			; Is drive 8 or 9 sector?
	JNZ	BPBKnowSectors		; It's 8, we assumed right
	INC	AL			; 9 sector, incr # of FAT sectors
	INC	BL			; Set we have 9 sectors/cylinder
	ADD	CX,40			; Increase size to 360 sectors
BPBKnowSectors:
	TEST	AH,1			; Is disk double sided?
	JE	BPBKnowHeads		; No, we guessed right
	ADD	CX,CX			; Double size of disk
	MOV	BH,112			; Increase # of directory entries
	INC	DH			; Set 2 sectors/allocation unit
	INC	DL			; Set 2 heads
BPBKnowHeads:
	MOV	CS:[DI].BPBsecpau,DH		; Set sectors/allocation unit
	MOV	BYTE PTR CS:[DI].BPBndir,BH	; Set # of directory entries
	MOV	CS:[DI].BPBnsec,CX		; Set size of disk in sectors
	MOV	CS:[DI].BPBmediab,AH		; Set media byte
	MOV	BYTE PTR CS:[DI].BPBnfatsec,AL	; Set number of FAT sectors
	MOV	BYTE PTR CS:[DI].BPBtrksiz,BL	; Set sectors/track
	MOV	BYTE PTR CS:[DI].BPBnhead,DL	; Set # of heads
BPBdone:
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET
FDGetBPB	ENDP


;	HDGetBPB returns a pointer to the hard disk BPB for the
;  selected unit.  The BPB contains various drive parameters
;  such as physical disk dimensions and the size of FATs and the
;  root directory.
;
;  Input:	AL =	Drive number
;  Destroys:	None
;  Output:	CS:DI = Pointer to BPB

	ASSUME	DS:NOTHING,ES:NOTHING

HDGetBPB	PROC
	PUSH	BX
	MOV	BL,AL			; Get pointer to per drive info.
	XOR	BH,BH
	ADD	BX,BX
	MOV	DI,CS:HDinfo[BX]
	POP	BX
	RET
HDGetBPB	ENDP


	ASSUME	DS:NOTHING,ES:NOTHING

BlockIfLocked	Proc	Near		; Block the current process if it has
	pushf				;  been locked out by an Int 13 request.
bifl1:	cli				;  Otherwise, set the busy flag to block
	cmp	SemInt13,0		;  out Int 13 requests.
	jz	bifl2
	push	dx
	push	cx
	push	bx
	push	ax
	mov	ax,cs
	mov	bx,offset SemInt13
	xor	cx,cx
	mov	dx,BlockProcess
	call	DosFunction
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	jmp	bifl1
bifl2:
	mov	SemDiskIO,1
	popf
	ret
BlockIfLocked	endp

SUBTTL	Routines that interface to hard disk controller
PAGE	+

;***	HDCommand - send a command to the hard disk controller
;
;	HDCommand will send the previously set up command block
;	to the hard disk controller.
;
;	ENTRY	AL = value to be put in interrupt/DMA mask
;	EXIT	AL = status port value
;	USES	AX,CX,DX,SI

HDCommand	PROC
	mov	dx,HD_PSEL		; point to select port
	out	dx,al
;;	mov	cx,10			;BUGBUG - timing prob. w/ expansion box?
;;hdcom0: loop	hdcom0			;BUGBUG - timing prob. w/ expansion box?
	inc	dx			; point to mask port
	out	dx,al
	mov	dx,HD_PSTAT
hdcom1: in	al,dx			; get status
	and	al,0FH
	cmp	al,0DH			; test for busy, command/data, request
	jnz	hdcom1
	mov	si,OFFSET Fixed.DCB
	mov	cx,6
	cld
	dec	dx			; point to data port
hdcom2: lodsb
	out	dx,al
	loop	hdcom2
	inc	dx
;;	mov	cx,10			;BUGBUG - timing prob. w/ expansion box?
;;hdcom3: loop	hdcom3			;BUGBUG - timing prob. w/ expansion box?
	in	al,dx
	ret
HDCommand	ENDP

;***	HDWaitReq - wait for request bit in status register
;
;	HDWaitReq will pause until the request bit in the hard disk
;	status register is set.
;
;	ENTRY
;	EXIT	AL = status byte
;	USES	AX,DX

HDWaitReq	PROC
	mov	dx,HD_PSTAT
	in	al,dx
	test	al,01h			; request bit?
	jz	HDWaitReq
	ret
HDWaitReq	ENDP
SUBTTL	Routines that interface to floppy disk controller
PAGE	+

;***	GetDrivePtr - compute ptr to per drive info.
;
;	GetDrivePtr returns a pointer to the per-drive information
;	for the current drive.	Should not be called before the
;	current drive is set up by Sel765 in state CALC.
;
;	EXIT	BX = pointer to per drive table
;	USES	BX

GetDrivePtr	PROC
	mov	bx,cs:Floppy.Current
	add	bx,bx
	mov	bx,cs:FDinfo[bx]
	ret
GetDrivePtr	ENDP


;	GetFloppyParam is called to get a disk parameter from the parameter
;  block set up by the BIOS.  This block allows disk parameters to be changed
;  from the standard.
;
;  Input:	AL = parameter desired (see FloppyParam structure)
;  Destroys:	AX
;  Output:	AL = parameter byte desired

GetFloppyParam	PROC
	PUSH	DS
	PUSH	BX
	XOR	AH,AH
	MOV	BX,AX
	XOR	AX,AX
	MOV	DS,AX			; Point to INT area
	LDS	AX,DWORD PTR DS:(4*1EH) ; Get pointer to param block
	ADD	BX,AX			; Add in block offset
	MOV	AL,[BX]
	POP	BX
	POP	DS
	RET
GetFloppyParam	ENDP



;	Recalibrate the current drive.	Clear Restore flag, set cylinder to
;  unknown and issue command to controller.
;
;  Destroys:	AX,BX,DX
;

Rcl765	PROC
	AND	CS:[BX].DrvFlag,NOT Frestor	; Have restored drive
	MOV	CS:[BX].CurCyl,-1	; Flag don't know where we are
	MOV	AL,FD_CRESET
	CALL	Put765			; Put out reset command
	MOV	AX,Floppy.Current	; Get current drive
	CALL	Put765			; Tell controller which drive
	RET
Rcl765	ENDP


;	Reset the controller.
;
;  Destroys:	AX,CX,DX
;

Rst765	PROC
	MOV	AL,CS:Floppy.DOR
	AND	AL,NOT(DORmask)
	MOV	DX,FD_PSEL
	OUT	DX,AL
	MOV	CX,10000
RstDelayLoop:
	loop	RstDelayLoop
	OR	AL,DORmask
	MOV	CS:Floppy.DOR,AL		; Update value
	OUT	DX,AL
	RET
Rst765	ENDP


;	Load the drive specs into the controller.
;
;  Destroys:	AX,DX
;

Spec765 PROC
	MOV	AL,FD_CSPEC
	CALL	Put765
	MOV	AL,Spec1
	CALL	GetFloppyParam
	CALL	Put765
	MOV	AL,Spec2
	CALL	GetFloppyParam
	CALL	Put765
	RET
Spec765 ENDP


;	Get the interrupt status from the controller and into AX
;
;  Destroys:	AX,CX,DX
;

Sense765	PROC
	MOV	AL,FD_CSENSE		; Get status
	CALL	Put765
	CALL	Get765			; Read ST0
	PUSH	AX			; Save status
	CALL	Get765			; Read PCN (present cylinder number)
	POP	AX			; Restore status
	MOV	CL,6
	SHR	AL,CL			; Shift bits down
	AND	AX,3			; Leave only error bits
	RET
Sense765	ENDP


;	Select the current drive.  Return carry set if must wait until drive is
;  ready. FloppyExecute will be called again when the drive is ready.  The
;  code must wait either for a motor start or head load delay, otherwise it
;  returns with carry clear.
;
;  Destroys:	AX,BX,CX,DX
;

Sel765	PROC
	MOV	DX,FD_PSEL		; set DX = Digital Output Register
	MOV	CL,Floppy.Unit		; Get unit we want to use
	XOR	CH,CH			; CX = wanted unit
	CMP	Single,0		; Single drive system?
	JE	Sel765Double		; No, Unit is accurate
	MOV	CL,CH			; Yes, there is only drive 0
Sel765Double:
	CMP	CX,Floppy.Current	; Wanted same as current?
	MOV	Floppy.Current,CX	; Set new current unit
	JNE	SelectUnit		; No, must select new drive
	ADD	CL,4
	MOV	AL,1
	SHL	AL,CL			; AL = Bit for drive's motor on
	TEST	AL,Floppy.DOR		; Is the drive's motor still on?
	JE	SelectUnit		; No, must turn it back on
	MOV	AL,Floppy.DOR
	OUT	DX,AL			; ? For some reason output value again
	CLC				; Clear carry, don't have to wait
	RET

SelectUnit:
	MOV	AL,NOT(3)		; Drive select is low 2 bits
	AND	AL,Floppy.DOR		; Lose old select bits
	OR	AL,DORmask
	MOV	CL,BYTE PTR Floppy.Current ; get unit number
	OR	AL,CL			; Put in new select bits
	MOV	Floppy.DOR,AL		; Save new bits
	ADD	CL,4
	MOV	AL,1
	SHL	AL,CL			; Get bit for motor is on
	TEST	AL,Floppy.DOR		; Is drive's motor on?
	JE	SelectStartMotor	; No, must start motor
	MOV	AL,Floppy.DOR
	OUT	DX,AL			; Load the head
	MOV	AX,DelayLoad		; Load head delay
	CALL	SetTimer1
	RET

SelectStartMotor:
	OR	Floppy.DOR,AL		; Add in motor start bit
	MOV	AL,Floppy.DOR
	OUT	DX,AL			; Start the motor
	MOV	AL,DelayMotor
	CALL	GetFloppyParam		; Get the proper delay time in 1/8 sec
	mov	cl,125
	mul	cl			; convert to milliseconds
	CALL	SetTimer1		; Set timer for motor startup
	RET
Sel765	ENDP


;	Seek to the correct cylinder.  Set carry if have to wait for operation
;  to complete (we are not on right cylinder).
;
;  Destroys:	AX,BX,DX
;

Seek765 PROC
	MOV	AX,Floppy.Cyl		; Get cylinder wanted
	CMP	AX,CS:[BX].CurCyl	; Already on cylinder?
	JE	SeekDone		; Yes, return with carry clear
	MOV	CS:[BX].CurCyl,AX	; Set the new current cylinder
	MOV	AL,FD_CSEEK
	CALL	Put765			; Seek command
	MOV	AL,Floppy.Head		; Get head desired
	SHL	AL,1
	SHL	AL,1			; Move head # 2 bits left
	ADD	AL,BYTE PTR Floppy.Current	; Low 2 bits are unit (hhuu)
	CALL	Put765			; Put out drive and head select
	MOV	AX,Floppy.Cyl
	TEST	Floppy.Flags,F2step	; Need to double step?
	JE	SeekNoDouble		; No
	ADD	AX,AX			; Yes, double cylinder number
SeekNoDouble:
	CALL	Put765			; Give controller the cylinder
	STC				; Set carry, must wait for seek intr.
SeekDone:
	RET
Seek765 ENDP



;	Start the Read/write.  Set up the DMA channel and give a read or write
;  command to the controller depending on flag.
;
;  Destroys:	AX,CX,DX
;

RdWr765 PROC
	mov	ah,FD_DMA
	mov	si,OFFSET Floppy
	TEST	Floppy.Flags,Fwrite	; Is this a write?
	JNE	WriteSetup		; Yes
	MOV	AL,DMA_READ		; No, read
	CALL	DMAsetup		; Set up the DMA
	MOV	AL,FD_CREAD		; Want to read
	JMP	SHORT RdWrLoc		; Now put out rest of command

WriteSetup:
	MOV	AL,DMA_WRITE
	CALL	DMAsetup		; Set DMA up for write
	MOV	AL,FD_CWRITE		; Want to write
RdWrLoc:
	CALL	Put765			; Put out command
	MOV	AL,Floppy.Head
	ADD	AL,AL
	ADD	AL,AL			; Form HHxx Binary
	ADD	AL,BYTE PTR Floppy.Current	; Form HHUU
	CALL	Put765			; Output unit and head
	MOV	AX,Floppy.Cyl
	CALL	Put765			; Output cylinder
	MOV	AL,Floppy.Head
	CALL	Put765			; Output head again?
	MOV	AL,Floppy.Sector
	inc	al
	CALL	Put765			; Output sector
	MOV	AL,SectorSize
	CALL	GetFloppyParam		; Get sector size code
	CALL	Put765			; Tell controller sector size
	MOV	AL,CylSize
	CALL	GetFloppyParam		; Get number of sectors/cylinder
	CALL	Put765			; Tell controller
	MOV	AL,DataGap		; Gap length for read/write
	CALL	GetFloppyParam
	CALL	Put765			; Tell controller gap length
	MOV	AL,ValueDTL
	CALL	GetFloppyParam		; Get value for DTL
	CALL	Put765			; Since bytes/sector#0, this is a
					; meaningless value, but controller
					; wants to see something
	RET
RdWr765 ENDP



;	Fini765 gets the completion status.
;
;  Destroys:	AX,CX,DX
;  Returns:	AL
;

Fini765 PROC
	push	es
	push	di
	push	cs
	pop	es
	mov	di,OFFSET Floppy.ST0
	MOV	CX,7
fini1:	CALL	Get765
	stosb
	loop	fini1
	mov	al,Floppy.ST0
	mov	cl,6
	SHR	AL,CL
	AND	AX,3			; Mask down to value to return
	pop	di
	pop	es
	RET
Fini765 ENDP



;	Put765 writes a command to the controller.
;
;  Input:	AL = value
;  Destroys:	AX,DX
;

Put765	PROC
	PUSH	AX			; Save the value to write
PutWaitLoop:
	MOV	DX,FD_PSTAT
	IN	AL,DX			; Get status
	AND	AL,FD_SDIO+FD_SRQM
	CMP	AL,FD_SRQM			; Controller ready for data?
	JNE	PutWaitLoop		; No, keep waiting
	POP	AX			; Get value back
	MOV	DX,FD_PDAT
	OUT	DX,AL			; Put out value
	RET
Put765	ENDP


;	Get765 gets a value back from the controller into AL.
;
;  Destroys:	AX,DX
;  Returns:	AL
;

Get765	PROC
	MOV	DX,FD_PSTAT
	IN	AL,DX			; Get status
	AND	AL,FD_SDIO+FD_SRQM
	CMP	AL,FD_SDIO+FD_SRQM		; Controller data available?
	JNE	Get765			; No, wait for it
	MOV	DX,FD_PDAT
	IN	AL,DX			; Get value from controller
	ret
Get765	ENDP

Code	ENDS
	END
