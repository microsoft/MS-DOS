	PAGE	,132
	TITLE	VDISK - Virtual Disk Device Driver

;VDISK simulates a disk drive, using Random Access Memory as the storage medium.

;This program is meant to serve as an example of a device driver.  It does not
;reflect the current level of VDISK.SYS.

;(C) Copyright 1988 Microsoft
;Licensed Material - Program Property of Microsoft

;Add the following statement to CONFIG.SYS
;	DEVICE=[d:][path]VDISK.SYS bbb sss ddd [/E:m]

;   where:  bbb is the desired buffer size (in kilobytes)
;		minimum 1KB, maximum is size of available memory,
;		default is 64KB.

;		VDISK will leave at least 64KB of available memory,
;		although subsequent device drivers (other than VDISK)
;		other programs that make themselves resident, and
;		COMMAND.COM will result in less than 64KB as shown
;		by CHKDSK.

;		Must be large enough for 1 boot sector + FAT sectors
;		+ 1 directory sector + at least 1 data cluster,
;		or the device driver won't be installed.

;	    sss is the desired sector size (in bytes)
;		128, 256, or 512, default is 128.
;		Will be adjusted if number of FAT entries > 0FE0H

;	    ddd is the desired number of directory entries
;		Minimum 2, maximum 512, default 64.
;		Will be rounded upward to sector size boundary.

;	    /E may only be used if extended memory above 1 megabyte
;	    is to be used.  INT 15H functions 87H and 88H are used
;	    to read and write this extended memory.
;	    The m parameter in the /E option specifies the maximum
;	    number of sectors that the VDISK will transfer at a time.
;	    Optional values are 1,2,3,4,5,6,7 or 8 sectors, the default
;	    is 8 sectors.

;	    Brackets indicate optional operands.


; Samples:
;	DEVICE=\path\VDISK.SYS 160 512 64
;	results in a 160KB VDISK, with 512 byte sectors, 64 directory entries

;	DEVICE=VDISK.SYS Buffersize 60 Sectorsize 128 Directory entries 32
;	(since only numbers are interpreted, you may comment the line with
;	non-numeric characters)

	SUBTTL	Structure Definitions
	PAGE
;-----------------------------------------------------------------------;
;	Request Header (Common portion) 				;
;-----------------------------------------------------------------------;
RH	EQU	DS:[BX] 	;addressability to Request Header structure

RHC	STRUC			;fields common to all request types
	   DB	?		;length of Request Header (including data)
	   DB	?		;unit code (subunit)
RHC_CMD    DB	?		;command code
RHC_STA    DW	?		;status
	   DQ	?		;reserved for DOS
RHC	ENDS			;end of common portion

CMD_INPUT  EQU	4		;RHC_CMD is INPUT request

;status values for RHC_STA

STAT_DONE   EQU 01H		;function complete status (high order byte)
STAT_CMDERR EQU 8003H		;invalid command code error
STAT_CRC    EQU 8004H		;CRC error
STAT_SNF    EQU 8008H		;sector not found error
STAT_BUSY   EQU 0200H		;busy bit (9) for Removable Media call
;-----------------------------------------------------------------------;
;	Request Header for INIT command 				;
;-----------------------------------------------------------------------;
RH0	STRUC
	   DB	(TYPE RHC) DUP (?)	;common portion
RH0_NUN    DB	?		;number of units
				;set to 1 if installation succeeds,
				;set to 0 to cause installation failure
RH0_ENDO   DW	?		;offset  of ending address
RH0_ENDS   DW	?		;segment of ending address
RH0_BPBO   DW	?		;offset  of BPB array address
RH0_BPBS   DW	?		;segment of BPB array address
RH0_DRIV   DB	?		;drive code (DOS 3 only)
RH0	ENDS

RH0_BPBA   EQU	DWORD PTR RH0_BPBO	;offset/segment of BPB array address
;Note: RH0_BPBA at entry to INIT points to all after DEVICE= on CONFIG.SYS stmt

;-----------------------------------------------------------------------;
;	Request Header for MEDIA CHECK Command				;
;-----------------------------------------------------------------------;
RH1	STRUC
	   DB	(TYPE RHC) DUP (?)	;common portion
	   DB	?		;media descriptor
RH1_RET    DB	?		;return information
RH1	ENDS
;-----------------------------------------------------------------------;
;	Request Header for BUILD BPB Command				;
;-----------------------------------------------------------------------;
RH2	STRUC
	   DB	(TYPE RHC) DUP(?)	;common portion
	   DB	?		;media descriptor
	   DW	?		;offset  of transfer address
	   DW	?		;segment of transfer address
RH2_BPBO   DW	?		;offset  of BPB table address
RH2_BPBS   DW	?		;segment of BPB table address
RH2	ENDS
;-----------------------------------------------------------------------;
;	Request Header for INPUT, OUTPUT, and OUTPUT with verify	;
;-----------------------------------------------------------------------;
RH4	STRUC
	   DB	(TYPE RHC) DUP (?)	;common portion
	   DB	?		;media descriptor
RH4_DTAO   DW	?		;offset  of transfer address
RH4_DTAS   DW	?		;segment of transfer address
RH4_CNT    DW	?		;sector count
RH4_SSN    DW	?		;starting sector number
RH4	ENDS

RH4_DTAA   EQU	DWORD PTR RH4_DTAO ;offset/segment of transfer address

;-----------------------------------------------------------------------;
;	Segment Descriptor (part of Global Descriptor Table)		;
;-----------------------------------------------------------------------;
DESC	STRUC			;data segment descriptor
DESC_LMT   DW	0		;segment limit (length)
DESC_BASEL DW	0		;bits 15-0 of physical address
DESC_BASEH DB	0		;bits 23-16 of physical address
	   DB	0		;access rights byte
	   DW	0		;reserved
DESC	ENDS

	SUBTTL	Equates and Macro Definitions
	PAGE

MEM_SIZE   EQU	12H		;BIOS memory size determination INT
				;returns system size in KB in AX

EM_INT	   EQU	15H		;extended memory BIOS interrupt INT
EM_BLKMOVE EQU	87H		;block move function
EM_MEMSIZE EQU	88H		;memory size determination in KB

BOOT_INT   EQU	19H		;bootstrap DOS

DOS	   EQU	21H		;DOS request INT
DOS_PCHR   EQU	02H		;print character function
DOS_PSTR   EQU	09H		;print string function
DOS_VERS   EQU	30H		;get DOS version

TAB	   EQU	09H		;ASCII tab
LF	   EQU	0AH		;ASCII line feed
CR	   EQU	0DH		;ASCII carriage return
BEL	   EQU	07H		;ASCII bell

PARA_SIZE  EQU	16		;number of bytes in one 8088 paragraph
DIR_ENTRY_SIZE EQU 32		;number of bytes per directory entry
MAX_FATE   EQU	0FE0H		;largest number of FAT entries allowed

;default values used if parameters are omitted

DFLT_BSIZE EQU	64		;default VDISK buffer size (KB)
DFLT_SSZ   EQU	128		;default sector size
DFLT_DIRN  EQU	64		;default number of directory entries
DFLT_ESS   EQU	8		;default maximum sectors to transfer

MIN_DIRN   EQU	2		;minimum number of directory entries
MAX_DIRN   EQU	512		;maximum number of directory entries

STACK_SIZE EQU	512		;length of stack during initialization

;-----------------------------------------------------------------------;
;	MSG invokes the console message subroutine			;
;-----------------------------------------------------------------------;

MSG	MACRO	TEXT
	PUSH	DX		;;save DX across call
	MOV	DX,OFFSET TEXT	;;point to message
	CALL	SHOW_MSG	;;issue message
	POP	DX
	ENDM


	SUBTTL	Resident Data Area
	PAGE
;-----------------------------------------------------------------------;
;	Map INT 19H vector in low storage				;
;-----------------------------------------------------------------------;
INT_VEC SEGMENT AT 00H
	ORG	4*BOOT_INT
BOOT_VEC   LABEL DWORD
BOOT_VECO  DW	?		;offset
BOOT_VECS  DW	?		;segment
INT_VEC ENDS


CSEG	SEGMENT PARA PUBLIC 'CODE'
	ASSUME	CS:CSEG
;-----------------------------------------------------------------------;
;	Resident data area.						;
;									;
;	All variables and constants required after initialization	;
;	part one are defined here.					;
;-----------------------------------------------------------------------;

START	   EQU	$		;begin resident VDISK data & code

;DEVICE HEADER - must be at offset zero within device driver
	   DD	-1		;becomes pointer to next device header
	   DW	0800H		;attribute (IBM format block device)
				;supports OPEN/CLOSE/RM calls
	   DW	OFFSET STRATEGY ;pointer to device "strategy" routine
	   DW	OFFSET IRPT	;pointer to device "interrupt handler"
	   DB	1		;number of block devices
	   DB	7 DUP (?)	;7 byte filler (remainder of 8-byte name)
;END OF DEVICE HEADER

;This volume label is placed into the directory of the new VDISK
;This constant is also used to determine if a previous extended memory VDISK
;has been installed.

VOL_LABEL  DB	'VDISK      '   ;00-10 volume name (shows program level)
	   DB	28H		;11-11 attribute (volume label)
	   DT	0		;12-21 reserved
	   DW	6000H		;22-23 time=12:00 noon
	   DW	0986H		;24-25 date=12/06/84
VOL_LABEL_LEN  EQU  $-VOL_LABEL ;length of volume label

;The following field, in the first extended memory VDISK device driver,
;is the 24-bit address of the first free byte of extended memory.
;This address is not in the common offset/segment format.
;The initial value, 10 0000H, is 1 megabyte.

AVAIL_LO   DW	0		;address of first free byte of
AVAIL_HI   DB	10H		;extended memory

;The INT 19H vector is "stolen" by the first VDISK installed in extended memory.
;The original content of the interrupt vector is saved here.

INTV19	   LABEL DWORD
INTV19O    DW	?		;offset
INTV19S    DW	?		;segment


PARAS_PER_SECTOR  DW	?	;number of 16-byte paragraphs in one sector

START_BUFFER_PARA DW	?	;segment address of start of VDISK buffer
				;for extended memory, this segment address
				;is the end of the VDISK device driver.

EM_SW	DB	0		;non-zero if Extended Memory

EM_STAT DW	0		;AX from last unsuccessful extended memory I/O

START_EM_LO DW	?		;24-bit address of start of VDISK buffer
START_EM_HI DB	?		;(extended memory only)

WPARA_SIZE DW	PARA_SIZE	;number of bytes in one paragraph

MAX_CNT    DW	?		;(0FFFFH/BPB_SSZ) truncated, the maximum
				;number of sectors that can be transferred
				;without worrying about 64KB wrap

SECT_LEFT  DW	?		;sectors left to transfer

IO_SRCA    LABEL DWORD		;offset/segment of source
IO_SRCO    DW	?		;offset
IO_SRCS    DW	?		;segment

IO_TGTA    LABEL DWORD		;offset/segment of target
IO_TGTO    DW	?		;offset
IO_TGTS    DW	?		;segment

;-----------------------------------------------------------------------;
;	BIOS Parameter Block (BPB)					;
;-----------------------------------------------------------------------;
;This is where the characteristics of the virtual disk are established.
;A copy of this block is moved into the boot record of the virtual disk.
;DEBUG can be used to read sector zero of the virtual disk to examine the
;boot record copy of this block.

BPB	 LABEL	BYTE		;BIOS Parameter Block (BPB)
BPB_SSZ    DW	0		;number of bytes per disk sector
BPB_AUSZ   DB	1		;sectors per allocation unit
BPB_RES    DW	1		;number of reserved sectors (for boot record)
BPB_FATN   DB	1		;number of File Allocation Table (FAT) copies
BPB_DIRN   DW	0		;number of root directory entries
BPB_SECN   DW	1		;total number of sectors
				;computed from buffer size and sector size
				;(this includes reserved, FAT, directory,
				;and data sectors)
BPB_MCB    DB	0FEH		;media descriptor byte
BPB_FATSZ  DW	1		;number of sectors occupied by a single FAT
				;computed from BPBSSZ and BPBSECN
BPB_LEN    EQU	$-BPB		;length of BIOS parameter block

BPB_PTR    DW	BPB		;BIOS Parameter Block pointer array (1 entry)
;-----------------------------------------------------------------------;
;	Request Header (RH) address, saved here by "strategy" routine   ;
;-----------------------------------------------------------------------;
RH_PTRA    LABEL DWORD
RH_PTRO    DW	?		;offset
RH_PTRS    DW	?		;segment
;-----------------------------------------------------------------------;
;	Global Descriptor Table (GDT), used for extended memory moves	;
;-----------------------------------------------------------------------;
;Access Rights Byte (93H) is
;	P=1	(segment is mapped into physical memory)
;	E=0	(data segment descriptor)
;	D=0	(grow up segment, offsets must be <= limit)
;	W=1	(data segment may be written into)
;	DPL=0	(privilege level 0)

GDT	LABEL	BYTE		;begin global descriptor table
	DESC	<>		;dummy descriptor
	DESC	<>		;descriptor for GDT itself
SRC	DESC	<,,,93H,>	;source descriptor
TGT	DESC	<,,,93H,>	;target descriptor
	DESC	<>		;BIOS CS descriptor
	DESC	<>		;stack segment descriptor

	SUBTTL	INT 19H (boot) interrupt handler
	PAGE
;-----------------------------------------------------------------------;
;	INT 19H Interrupt Handler routine				;
;-----------------------------------------------------------------------;
;The INT 19H vector is altered by VDISK initialization to point to this
;routine within the first extended memory VDISK device driver.

;The vector points to the device driver so that subsequent VDISKs installed
;in extended memory can find the first one to determine what memory has
;already been allocated to VDISKs.

;This routine restores the original INT 19H vector's content, then jumps
;to the original routine.

;INT 19H, the "Boot" INT, is always altered when DOS is booted.

;This routine is entered with interrupts disabled.

VDISK_INT19 PROC		;INT 19H received
	PUSH	DS		;save registers we're going to alter
	PUSH	AX

	XOR	AX,AX
	MOV	DS,AX		;set DS = 0
	ASSUME	DS:INT_VEC

	MOV	AX,CS:INTV19O	;get offset of saved vector
	MOV	DS:BOOT_VECO,AX ;store offset in interrupt vector

	MOV	AX,CS:INTV19S	;get segment of saved vector
	MOV	DS:BOOT_VECS,AX ;store segment in interrupt vector

	POP	AX
	POP	DS

	JMP	CS:INTV19	;go to original interrupt routine

VDISK_INT19 ENDP

	ASSUME	DS:NOTHING

	SUBTTL	Device Strategy & interrupt entry points
	PAGE
;-----------------------------------------------------------------------;
;	Device "strategy" entry point                                   ;
;									;
;	Retain the Request Header address for use by Interrupt routine	;
;-----------------------------------------------------------------------;
STRATEGY PROC	FAR
	MOV	CS:RH_PTRO,BX	;offset
	MOV	CS:RH_PTRS,ES	;segment
	RET
STRATEGY ENDP
;-----------------------------------------------------------------------;
;	Table of command processing routine entry points		;
;-----------------------------------------------------------------------;
CMD_TABLE LABEL WORD
	   DW	OFFSET INIT_P1		; 0 - Initialization
	   DW	OFFSET MEDIA_CHECK	; 1 - Media check
	   DW	OFFSET BLD_BPB		; 2 - Build BPB
	   DW	OFFSET INPUT_IOCTL	; 3 - IOCTL input
	   DW	OFFSET INPUT		; 4 - Input
	   DW	OFFSET INPUT_NOWAIT	; 5 - Non destructive input no wait
	   DW	OFFSET INPUT_STATUS	; 6 - Input status
	   DW	OFFSET INPUT_FLUSH	; 7 - Input flush
	   DW	OFFSET OUTPUT		; 8 - Output
	   DW	OFFSET OUTPUT_VERIFY	; 9 - Output with verify
	   DW	OFFSET OUTPUT_STATUS	;10 - Output status
	   DW	OFFSET OUTPUT_FLUSH	;11 - Output flush
	   DW	OFFSET OUTPUT_IOCTL	;12 - IOCTL output
	   DW	OFFSET DEVICE_OPEN	;13 - Device OPEN
	   DW	OFFSET DEVICE_CLOSE	;14 - Device CLOSE
MAX_CMD    EQU	($-CMD_TABLE)/2 	;highest valid command follows
	   DW	OFFSET REMOVABLE_MEDIA	;15 - Removable media

;-----------------------------------------------------------------------;
;	Device "interrupt" entry point                                  ;
;-----------------------------------------------------------------------;
IRPT	PROC	FAR		;device interrupt entry point
	PUSH	DS		;save all registers Revised
	PUSH	ES
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	SI
				;BP isn't used, so it isn't saved
	CLD			;all moves forward

	LDS	BX,CS:RH_PTRA	;get RH address passed to "strategy" into DS:BX

	MOV	AL,RH.RHC_CMD	;command code from Request Header
	CBW			;zero AH (if AL > 7FH, next compare will
				;catch that error)

	CMP	AL,MAX_CMD	;if command code is too high
	JA	IRPT_CMD_HIGH	;jump to error routine

	MOV	DI,OFFSET IRPT_CMD_EXIT ;return addr from command processor
	PUSH	DI		;push return address onto stack
				;command routine issues "RET"

	ADD	AX,AX		;double command code for table offset
	MOV	DI,AX		;put into index register for JMP

	XOR	AX,AX		;initialize return to "no error"

;At entry to command processing routine:

;	DS:BX	= Request Header address
;	CS	= VDISK code segment address
;	AX	= 0

;	top of stack is return address, IRPT_CMD_EXIT

	JMP	CS:CMD_TABLE[DI]	;call routine to handle the command


IRPT_CMD_ERROR: 		;CALLed for unsupported character mode commands

INPUT_IOCTL:			;IOCTL input
INPUT_NOWAIT:			;Non-destructive input no wait
INPUT_STATUS:			;Input status
INPUT_FLUSH:			;Input flush

OUTPUT_IOCTL:			;IOCTL output
OUTPUT_STATUS:			;Output status
OUTPUT_FLUSH:			;Output flush

	POP	AX		;pop return address off stack

IRPT_CMD_HIGH:			;JMPed to if RHC_CMD > MAX_CMD
	MOV	AX,STAT_CMDERR	;"invalid command" and error

IRPT_CMD_EXIT:			;return from command routine
				;AX = value to OR into status word
	LDS	BX,CS:RH_PTRA	;restore DS:BX as Request Header pointer
	OR	AH,STAT_DONE	;add "done" bit to status word
	MOV	RH.RHC_STA,AX	;store status into request header
	POP	SI		;restore registers
	POP	DI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	POP	ES
	POP	DS
	RET
IRPT	ENDP

	SUBTTL	Command Processing routines
	PAGE
;-----------------------------------------------------------------------;
;	Command Code 1 - Media Check					;
;	At entry, DS:BX point to request header, AX = 0 		;
;-----------------------------------------------------------------------;
MEDIA_CHECK PROC
	MOV	RH.RH1_RET,1	;indicate media not changed
	RET			;AX = zero, no error
MEDIA_CHECK ENDP
;-----------------------------------------------------------------------;
;	Command Code 2 - Build BPB					;
;	At entry, DS:BX point to request header, AX = 0 		;
;-----------------------------------------------------------------------;
BLD_BPB PROC
	MOV	RH.RH2_BPBO,OFFSET BPB	;return pointer to our BPB
	MOV	RH.RH2_BPBS,CS
	RET				;AX = zero, no error
BLD_BPB ENDP
;-----------------------------------------------------------------------;
;	Command Code 13 - Device Open					;
;	Command Code 14 - Device Close					;
;	Command Code 15 - Removable media				;
;	At entry, DS:BX point to request header, AX = 0 		;
;-----------------------------------------------------------------------;
REMOVABLE_MEDIA PROC
	MOV	AX,STAT_BUSY		;set status bit 9 (busy)
					;indicating non-removable media
DEVICE_OPEN:				;NOP for device open
DEVICE_CLOSE:				;NOP for device close
	RET
REMOVABLE_MEDIA ENDP			;fall thru to return
;-----------------------------------------------------------------------;
;	Command Code 4 - Input						;
;	Command Code 8 - Output 					;
;	Command Code 9 - Output with verify				;
;	At entry, DS:BX point to request header, AX = 0 		;
;-----------------------------------------------------------------------;
INOUT	PROC
INPUT:
OUTPUT:
OUTPUT_VERIFY:

;Make sure I/O is entirely within the VDISK sector boundaries

	MOV	CX,CS:BPB_SECN		;get total sector count
	MOV	AX,RH.RH4_SSN		;starting sector number
	CMP	AX,CX			;can't exceed total count
	JA	INOUT_E1		;jump if start > total

	ADD	AX,RH.RH4_CNT		;start + sector count
	CMP	AX,CX			;can't exceed total count
	JNA	INOUT_A 		;jump if start + count <= total

INOUT_E1:				;I/O not within VDISK sector boundaries
	MOV	RH.RH4_CNT,0		;set sectors transferred to zero
	MOV	AX,STAT_SNF		;indicate 'Sector not found' error
	RET				;return with error status in AX

INOUT_A:				;I/O within VDISK bounds
	MOV	AX,RH.RH4_CNT		;get sector count
	MOV	CS:SECT_LEFT,AX 	;save as sectors left to process

	CMP	CS:EM_SW,0		;extended memory mode?
	JNE	INOUT_EM		;jump to extended memory I/O code

;Compute offset and segment of VDISK buffer for starting segment in CX:SI

	MOV	AX,RH.RH4_SSN		;starting sector number
	MUL	CS:PARAS_PER_SECTOR	;* length of one sector in paragraphs
	ADD	AX,CS:START_BUFFER_PARA ;+ segment of VDISK buffer sector 0
	MOV	CX,AX			;segment address to CX
	XOR	SI,SI			;offset is zero

;Compute address of caller's Data Transfer Addr in DX:AX with smallest offset,
;so that there is no possibility of overflowing a 64KB boundary moving MAX_CNT
;sectors.

	MOV	AX,PARA_SIZE		;16
	MUL	RH.RH4_DTAS		;* segment of caller's DTA in DX,AX
	ADD	AX,RH.RH4_DTAO		;+ offset of caller's DTA
	ADC	DL,0			;carry in from addition
	DIV	CS:WPARA_SIZE		;AX is segment of caller's DTA
					;DX is smallest offset possible
					;AX:DX = DTA address

;AX:DX is caller's DTA segment:offset, CX:SI is VDISK buffer segment:offset

;If this is an OUTPUT request, exchange the source and target addresses

	CMP	RH.RHC_CMD,CMD_INPUT	;INPUT operation?
	JE	INOUT_B 		;jump if INPUT operation

	XCHG	AX,CX			;swap source and target segment
	XCHG	DX,SI			;swap source and target offset

INOUT_B:				;CX:SI is source, AX:DX is target
	MOV	CS:IO_SRCS,CX		;save source segment
	MOV	CS:IO_SRCO,SI		;save source offset
	MOV	CS:IO_TGTS,AX		;save target segment
	MOV	CS:IO_TGTO,DX		;save target offset

	JMP	SHORT INOUT_E		;AX := SECT_LEFT, test for zero
INOUT_C:				;SECT_LEFT in AX, non-zero

;  Compute number of sectors to transfer in a single move,
;  AX = minimum of (SECT_LEFT, MAX_CNT)

;  MAX_CNT is the maximum number of sectors that can be moved without
;  spanning a 64KB boundary (0FFFFH / Sector size, remainder truncated)

	MOV	CX,CS:MAX_CNT		;MAX sectors with one move
	CMP	AX,CX			;if SECT_LEFT cannot span 64KB boundary
	JBE	INOUT_D 		;then move SECT_LEFT sectors

	MOV	AX,CX			;else move MAX_CNT sectors
INOUT_D:
	SUB	CS:SECT_LEFT,AX 	;reduce number of sectors left to move

;Move AX sectors from source to target

	MUL	CS:BPB_SSZ		;sectors * sector size = byte count
					;(cannot overflow into DX)
	SHR	AX,1			;/2 = word count
	MOV	CX,AX			;word count to CX for REP MOVSW

	LDS	SI,CS:IO_SRCA		;source segment/offset to DS:SI
	LES	DI,CS:IO_TGTA		;target segment/offset to ES:DI

	REP	MOVSW			;move MOV_CNT sectors

;Update source and target paragraph addresses
;AX has number of words moved

	SHR	AX,1			;words moved / 8 = paragraphs moved
	SHR	AX,1
	SHR	AX,1

	ADD	CS:IO_SRCS,AX		;add paragraphs moved to source segment
	ADD	CS:IO_TGTS,AX		;add paragraphs moved to target segment

;Determine if more sectors need to be transferred

INOUT_E:				;do while SECT_LEFT <> zero
	MOV	AX,CS:SECT_LEFT 	;get sectors left to transfer
	OR	AX,AX			;set flags
	JNZ	INOUT_C 		;go back to transfer some sectors
	RET				;AX = zero, all sectors transferred

	SUBTTL	Extended Memory I/O routine
	PAGE
;-----------------------------------------------------------------------;
;	Extended Memory I/O routine					;
;-----------------------------------------------------------------------;
INOUT_EM:				;Extended memory I/O routine
					;change to larger stack
	MOV	SI,SS			;save old SS in SI
	MOV	DX,SP			;save old SP in DX
	CLI				;disable interrupts
	MOV	AX,CS
	MOV	SS,AX			;set SS = CS
	MOV	SP,OFFSET EM_STACK	;point to new stack
	STI				;enable interrupts
	PUSH	SI			;save old SS at top of new stack
	PUSH	DX			;save old SP on new stack

	MOV	SI,RH.RH4_DTAO		;caller's DTA offset

;Compute 24-bit address of VDISK sector in CX (hi) and SI (low)

	MOV	AX,RH.RH4_SSN		;starting sector number
	MUL	CS:BPB_SSZ		;* sector size = offset within buffer
	ADD	AX,CS:START_EM_LO	;+ base address of this VDISK buffer
	ADC	DL,CS:START_EM_HI
	MOV	CX,DX			;save high byte
	MOV	SI,AX			;save low word

;Compute 24-bit address of caller's DTA in DX (hi) and AX (low)

	MOV	AX,PARA_SIZE		;16
	MUL	RH.RH4_DTAS		;* segment of caller's DTA
	ADD	AX,RH.RH4_DTAO		;+ offset of caller's DTA
	ADC	DL,0			;carry in from addition

;Caller's DTA address is in CX,SI, VDISK buffer address is in DX,AX.

;If this is an OUTPUT request, exchange the source and target addresses

	CMP	RH.RHC_CMD,CMD_INPUT	;INPUT operation?
	JE	INOUT_EM_B		;jump if INPUT operation

	XCHG	DX,CX			;swap source and target high byte
	XCHG	AX,SI			;swap source and target low word

INOUT_EM_B:				;CX,SI is source, DX,AX is target

	MOV	SRC.DESC_BASEL,SI	;low 16 bits of source address
	MOV	SRC.DESC_BASEH,CL	;high 8 bits of source address

	MOV	TGT.DESC_BASEL,AX	;low 16 bits of target address
	MOV	TGT.DESC_BASEH,DL	;high 8 bits of target address

	JMP	SHORT INOUT_EM_E	;AX := SECT_LEFT, test for zero
INOUT_EM_C:				;SECT_LEFT in AX, non-zero

;  Compute number of sectors to transfer in a single move,
;  AX = minimum of (SECT_LEFT, MAX_CNT)

;  MAX_CNT is the maximum number of sectors that can be moved without
;  spanning a 64KB boundary (0FFFFH / Sector size, remainder truncated)

	MOV	CX,CS:MAX_CNT		;MAX sectors with one move
	CMP	AX,CX			;if SECT_LEFT cannot span 64KB boundary
	JBE	INOUT_EM_D		;then move SECT_LEFT sectors

	MOV	AX,CX			;else move MAX_CNT sectors
INOUT_EM_D:
	SUB	CS:SECT_LEFT,AX 	;reduce number of sectors left to move

;Move AX sectors from source to target

	MUL	CS:BPB_SSZ		;sectors * sector size = byte count
					;(cannot overflow into DX)
	MOV	TGT.DESC_LMT,AX 	;store segment limit (byte count)
	MOV	SRC.DESC_LMT,AX

	PUSH	AX			;preserve byte count on stack

	SHR	AX,1			;/2 = word count
	MOV	CX,AX			;word count to CX

	PUSH	CS
	POP	ES			;set ES = CS
	MOV	SI,OFFSET GDT		;ES:SI point to GDT

	MOV	AH,EM_BLKMOVE		;function is block move
	INT	EM_INT			;move an even number of words

	POP	CX			;get byte count back from stack

	OR	AH,AH			;get error code

	JNZ	INOUT_EM_XE		;jump if I/O error encountered

;Update source and target addresses

	ADD	SRC.DESC_BASEL,CX	;add bytes moved to source
	ADC	SRC.DESC_BASEH,0	;pick up any carry

	ADD	TGT.DESC_BASEL,CX	;add bytes moved to target
	ADC	TGT.DESC_BASEH,0	;pick up any carry

;Determine if more sectors need to be transferred

INOUT_EM_E:				;do while SECT_LEFT <> zero
	MOV	AX,CS:SECT_LEFT 	;get sectors left to transfer
	OR	AX,AX			;set flags
	JNZ	INOUT_EM_C		;go back to transfer some sectors

INOUT_EM_X2:				;revert to original stack
	POP	DI			;get old SP
	POP	SI			;get old SS
	CLI				;disable interrupts
	MOV	SS,SI			;restore old SS
	MOV	SP,DI			;restore old SP
	STI				;enable interrupts
	RET				;return to IRPT_EXIT

INOUT_EM_XE:				;some error with INT 15H
	MOV	CS:EM_STAT,AX		;save error status for debugging
	MOV	RH.RH4_CNT,0		;indicate no sectors transferred
	MOV	AX,STAT_CRC		;indicate CRC error
	JMP	INOUT_EM_X2		;fix stack and exit
INOUT	ENDP

	DW	40 DUP (?)		;stack for extended memory I/O
EM_STACK LABEL	WORD

	SUBTTL	Boot Record
	PAGE
;-----------------------------------------------------------------------;
;	Adjust the assembly-time instruction counter to a paragraph	;
;	boundary							;
;-----------------------------------------------------------------------;

	IF	($-START) MOD 16
	ORG	($-START) + 16 - (($-START) MOD 16)
	ENDIF

VDISK	   EQU	$			;start of virtual disk buffer
VDISKP	   EQU	($-START) / PARA_SIZE	;length of program in paragraphs
;-----------------------------------------------------------------------;
;	If this VDISK is in extended memory, this address is passed	;
;	back to DOS as the end address that is to remain resident.	;
;									;
;	It this VDISK is not in extended memory, the VDISK buffer	;
;	begins at this address, and the address passed back to DOS	;
;	as the end address that is to remain resident is this address	;
;	plus the length of the VDISK buffer.				;
;-----------------------------------------------------------------------;

BOOT_RECORD LABEL BYTE		;Format of Boot Record documented in
				;DOS Technical Reference Manual
	   DB	0,0,0		;3-byte jump to boot code (not bootable)
	   DB	'VDISK   '      ;8-byte vendor identification
BOOT_BPB LABEL	BYTE		;boot record copy of BIOS parameter block
	   DW	?		;number of bytes per disk sector
	   DB	?		;sectors per allocation unit
	   DW	?		;number of reserved sectors (for boot record)
	   DB	?		;number of File Allocation Table (FAT) copies
	   DW	?		;number of root directory entries
	   DW	?		;total number of sectors
	   DB	?		;media descriptor byte
	   DW	?		;number of sectors occupied by a single FAT
;end of boot record BIOS Parameter block

;The following three words mean nothing to VDISK, they are placed here
;to conform to the DOS standard for boot records.
	   DW	8		;sectors per track
	   DW	1		;number of heads
	   DW	0		;number of hidden sectors
;The following word is the 16-bit kilobyte address of the first byte in
;extended memory that is not occupied by a VDISK buffer
;It is placed into this location so that other users of extended memory
;may find where all the VDISKs end.

;This field may be accessed by moving the boot record of the First extended
;memory VDISK from absolute location 10 0000H.	Before assuming that the
;value below is valid, the vendor ID (constant VDISK) should be verified
;to make sure that SOME VDISK has been installed.

;For example, if two VDISKs are installed, one 320KB and one 64KB, the
;address calculations are as follows:

;Extended memory start address	= 100000H (1024KB)
;Start addr of 1st VDISK buffer = 100000H (1024KB)
;Length of 1st VDISK buffer	= 050000H ( 320KB)
;End addr of 1st VDISK buffer	= 14FFFFH
;Start addr of 2nd VDISK buffer = 150000H (1344KB)
;Length of 2nd VDISK buffer	= 010000H (  64KB)
;End addr of 2nd VDISK buffer	= 15FFFFH
;First byte after all VDISKs	= 160000H (1408KB)
;Divide by 1024 		=   0580H (1408D)

;Content of BOOT_EM		=   0580H

BOOT_EM_OFF EQU $-BOOT_RECORD	;offset from 10 0000H of the following word
BOOT_EM    DW	1024		;KB addr of first free byte of extended memory
;-----------------------------------------------------------------------;
;	Part 2 of Initialization (executed last)			;
;-----------------------------------------------------------------------;
;Initialization is divided into two parts.

;INIT_P1 is overlaid by the virtual disk buffer

;INIT_P1 is executed first, then jumps to INIT_P2.  INIT_P2 returns to caller.

;Exercise caution if extending the initialization part 2 code.
;It overlays the area immediately following the boot sector.
;If this section of code must be expanded, make sure it fits into the minimum
;sector size of 128 bytes.
;Label TEST_LENGTH must equate to a non-negative value (TEST_LENGTH >= 0).
;If this code it must be extended beyond the 128 byte length of the boot sector,
;move all of INIT_P2 before label VDISK.

;Registers at entry to INIT_P2 (set up at end of INIT_P1):
;	BL = media control byte from BPB (for FAT)
;	CX = number of FAT copies
;	DX = number of bytes in one FAT - 3
;	SI = OFFSET of Volume Label field
;	ES:DI = VDISK buffer address of first FAT sector
;	CS = DS = VDISK code segment

INIT_P2 PROC				;second part of initialization
	ASSUME	DS:CSEG 		;DS set in INIT_P1

;Initialize File Allocation Table(s) (FATs)

INIT_P2_FAT:				;set up one FAT, sector number in AX

	PUSH	CX			;save loop counter on stack
	MOV	AL,BL			;media control byte
	STOSB				;store media control byte, increment DI
	MOV	AX,0FFFFH		;bytes 2 and 3 of FAT are 0FFH
	STOSW

	MOV	CX,DX			;FAT size in bytes - 3
	XOR	AX,AX			;value to store in remainder of FAT
	REP	STOSB			;clear remainder of FAT

	POP	CX			;get loop counter off stack
	LOOP	INIT_P2_FAT		;loop for all copies of the FAT

;Put the volume label in the first directory entry

	MOV	CX,VOL_LABEL_LEN	;length of volume directory entry
	REP	MOVSB			;move volume id to directory

;Zero the remainder of the directory

	MOV	AX,DIR_ENTRY_SIZE	;length of 1 directory entry
	MUL	BPB_DIRN		;* number entries = bytes of directory
	SUB	AX,VOL_LABEL_LEN	;less length of volume label
	MOV	CX,AX			;length of rest of directory
	XOR	AX,AX
	REP	STOSB			;clear directory to nulls
	RET				;return with AX=0
INIT_P2 ENDP

PATCH_AREA DB	5 DUP ('PATCH AREA ')
TEST_LENGTH EQU 128-($-VDISK)		;if negative, boot record has too much
					;data area, move some fields below VDISK
;-----------------------------------------------------------------------;
;	All fields that must remain resident after device driver	;
;	initialization must be defined before this point.		;
;-----------------------------------------------------------------------;
	   DB	'MS DOS Version 4.00 - Virtual Disk Device Driver'
	   DB	'-------- Licensed Material ---------'
	   DB	'Program Property of Microsoft Corporation.   '
	   DB	'(C)Copyright 1988 Microsoft'
	   DB	'Thank You For Your '
	   DB	'    Support    '

MAXSEC_TRF DW	0		;maximum number of sectors to transfer when
				;in extended memory

BUFF_SIZE  DW	0		;desired VDISK buffer size in kilobytes

MIN_MEMORY_LEFT DW	64	;minimum amount of system memory (kilobytes)
				;that must remain after VDISK is installed

FIRST_EM_SW DB	?		;0FFH if this is the first device driver
				;to be installed in extended memory
				;00H if another VDISK extended memory driver
				;has been installed

FIRST_VDISK DW	?		;segment address of 1st VDISK device driver
PARA_PER_KB DW	1024/PARA_SIZE	;paragraphs in one kilobyte
C1024	   DW	1024		;bytes in one kilobyte
DIRE_SIZE  DW	DIR_ENTRY_SIZE	;bytes in one directory entry
DIR_SECTORS DW	?		;number of sectors of directory

ERR_FLAG   DB	0		;error indicators to condition messages
ERR_BSIZE  EQU	80H		;buffer size adjusted
ERR_SSZ    EQU	40H		;sector size adjusted
ERR_DIRN   EQU	20H		;number of directory entries adjusted
ERR_PASS   EQU	10H		;some adjustment made that requires
				;recomputation of values previously computed
ERR_SSZB   EQU	ERR_SSZ+ERR_PASS	;sector size altered this pass
ERR_SYSSZ  EQU	08H		;system storage too small for VDISK
ERR_SWTCH  EQU	04H		;invalid switch character
ERR_EXTSW  EQU	02H		;extender card switches don't match memory size
ERR_ESIZE  EQU	01H		;Transfer size adjusted

; additional errors added - kwc

major_version	    equ     4	;Major DOS version
minor_version	    equ     00	;Minor DOS Version

expected_version    equ     (MINOR_VERSION SHL 8)+MAJOR_VERSION

err_flag2	    db	    0
err_baddos	    equ     01h ; Invalid DOS Version

	SUBTTL	Initialization, Part one
	PAGE
;-----------------------------------------------------------------------;
;	Command Code 0 - Initialization 				;
;	At entry, DS:BX point to request header, AX = 0 		;
;-----------------------------------------------------------------------;
;Initialization is divided into two parts.
;This part, executed first, is later overlaid by the VDISK buffer.

INIT_P1 PROC			;first part of initialization
	MOV	DX,SS		;save stack segment register
	MOV	CX,SP		;save stack pointer register
	CLI			;inhibit interrupts while changing SS:SP
	MOV	AX,CS		;move CS to SS through AX
	MOV	SS,AX
	MOV	SP,OFFSET MSGEND ;end of VDISKMSG
	ADD	SP,STACK_SIZE	;+ length of our stack
	STI			;allow interrupts
	PUSH	DX		;save old SS register on new stack
	PUSH	CX		;save old SP register on new stack

	push bx 		;secure registers before DOS int
	push cx 		;secure registers before DOS int

; add version check - kwc

	mov	ah,030h
	int	21h
	pop	cx	   ;restore pointer values
	pop	bx	   ;restore pointer values
	cmp	ax,expected_version
	je	okdos

	or	cs:err_flag2,err_baddos

okdos:
	CALL	GET_PARMS	;get parameters from CONFIG.SYS line

	PUSH	CS
	POP	DS		;set DS = CS
	ASSUME	DS:CSEG

	CALL	APPLY_DEFAULTS	;supply any values not specified
	CALL	DETERMINE_START ;compute start address of VDISK buffer
	CALL	VALIDATE	;validate parameters
	CALL	COPY_BPB	;Copy BIOS Parameter Block to boot record

	CALL	VERIFY_EXTENDER ;Verify that extender card switches are right

	TEST	ERR_FLAG,ERR_EXTSW	;are switches wrong?
	JNZ	INIT_P1_A	;if so, exit with messages

	test	CS:err_flag2,err_baddos
	jnz	init_p1_a

	CMP	EM_SW,0 	;extended memory requested?
	JE	INIT_P1_A	;jump if not

	TEST	ERR_FLAG,ERR_SYSSZ	;is system too small for VDISK?
	JNZ	INIT_P1_A	;if so, don't do extended memory init

	CALL	UPDATE_AVAIL	;update AVAIL_HI and AVAIL_LO to reflect
				;addition of extended memory VDISK
	CALL	FORMAT_VDISK	;construct a boot record, FATs and
				;directory in storage immediately
				;following this device driver
	CALL	MOVE_VDISK	;move formatted boot record, FATs,
				;and directory to extended memory
	CALL	UPDATE_BOOT	;place the end address of ALL VDISKs
				;in the boot record of the first VDISK
	CMP	FIRST_EM_SW,0	;is this the first extended memory VDISK?
	JE	INIT_P1_A	;no, exit

	CALL	STEAL_INT19	;point INT 19H to this VDISK
INIT_P1_A:
	CALL	FILL_RH 	;fill in INIT request header
	CALL	WRITE_MESSAGES	;display all messages
	POP	CX		;get old SP from stack
	POP	DX		;get old SS from stack
	CLI			;disable interrupts while changing SS:SP
	MOV	SS,DX		;restore stack segment register
	MOV	SP,CX		;restore stack pointer register
	STI			;enable interrupts
;-----------------------------------------------------------------------;
;	INIT_P2 must be short enough to fit into the boot sector	;
;	(minimum size of boot sector is 128 bytes), so we set up	;
;	as many pointers as we can to help keep INIT_P2 short.		;
;									;
;	ES:DI = storage address of first FAT sector			;
;	BL = media control byte 					;
;	CX = number of FAT copies					;
;	DX = number of bytes in one FAT, less 3 			;
;	SI = offset of VOL label field					;
;-----------------------------------------------------------------------;
	MOV	ES,START_BUFFER_PARA	;start paragraph of VDISK buffer

	MOV	AX,BPB_RES		;number of reserved sectors
	MUL	BPB_SSZ 		;* sector size
	MOV	DI,AX			;ES:DI point to FAT start

	MOV	BL,BPB_MCB		;media control byte

	MOV	CL,BPB_FATN		;number of FAT copies
	XOR	CH,CH

	MOV	AX,BPB_FATSZ		;FAT size in sectors
	MUL	BPB_SSZ 		;* sector size = total FAT bytes

	SUB	AX,3			;-3 (FEFFFF stored by code)
	MOV	DX,AX

	MOV	SI,OFFSET VOL_LABEL	;point to VOL label directory entry
	JMP	INIT_P2 		;jump to second part of initialization
					;this is redundant if the VDISK is in
					;extended memory, but is executed anyway

	SUBTTL	GET_PARMS Parameter Line Scan
	PAGE
;-----------------------------------------------------------------------;
;GET_PARMS gets the parameters from the CONFIG.SYS statement		;
;									;
;Register usage:							;
;	DS:SI indexes parameter string					;
;	AL contains character from parameter string			;
;	CX value from GET_NUMBER					;
;-----------------------------------------------------------------------;
	ASSUME	DS:NOTHING	;DS:BX point to Request Header
GET_PARMS PROC			;get parameters from CONFIG.SYS line
	PUSH	DS		;save DS
	LDS	SI,RH.RH0_BPBA	;DS:SI point to all after DEVICE=
				;in CONFIG.SYS line
	XOR	AL,AL		;not at end of line

;Skip until first delimiter is found.  There may be digits in the path string.

;DS:SI points to  \pathstring\VDISK.SYS nn nn nn
;The character following VDISK.SYS may have been changed to a null (00H).
;All letters have been changed to uppercase.

GET_PARMS_A:			;skip to DOS delimiter character
	CALL	GET_PCHAR	;get parameter character into AL
	JZ	GET_PARMS_X	;get out if end of line encountered
	OR	AL,AL		;test for null
	JZ	GET_PARMS_C	;
	CMP	AL,' '
	JE	GET_PARMS_C	;
	CMP	AL,','
	JE	GET_PARMS_C	;
	CMP	AL,';'
	JE	GET_PARMS_C	;
	CMP	AL,'+'
	JE	GET_PARMS_C	;
	CMP	AL,'='
	JE	GET_PARMS_C	;
	CMP	AL,TAB
	JNE	GET_PARMS_A	;skip until delimiter or CR



GET_PARMS_C:
	PUSH	SI		;save to rescan
	MOV	CS:EM_SW,0	;indicate no /E found
	JMP	GET_SLASH	;see if current character is an slash

GET_PARMS_D:			;scan for /
	CALL	GET_PCHAR
	JZ	GET_PARMS_B	;exit if end of line

GET_SLASH:			;check for slash
	CMP	AL,'/'          ;found slash?
	JNE	GET_PARMS_D	;no, continue scan

	CALL	GET_PCHAR	;get char following slash
	CMP	AL,'E'          ;don't have to test for lower case E,
				;letters have been changed to upper case
	JNE	GET_PARMS_E	;not 'E'
	MOV	CS:EM_SW,AL	;indicate /E found

	CALL	GET_PCHAR	;get char following E
	CMP	AL,':'          ;is it a delimeter ?
	JNE	GET_PARMS_D	;not a ':'


	CALL	GET_MAXSIZE	;get maximum sector size


	JMP	GET_PARMS_D	;continue forward scan

GET_PARMS_E:			;/ found, not 'E'
	OR	CS:ERR_FLAG,ERR_SWTCH	;indicate invalid switch character
	JMP	GET_PARMS_D	;continue scan



GET_PARMS_B:			;now pointing to first delimiter
	POP	SI		;get pointer, used to rescan for /E
	XOR	AL,AL		;not at EOL now
	CALL	GET_PCHAR	;get first character
	CALL	SKIP_TO_DIGIT	;skip to first digit
	JZ	GET_PARMS_X	;found EOL, no digits remain

	CALL	GET_NUMBER	;extract digits, convert to binary
	MOV	CS:BUFF_SIZE,CX ;store buffer size

	CALL	SKIP_TO_DIGIT	;skip to next digit
	JZ	GET_PARMS_X	;found EOL, no digits remain

	CALL	GET_NUMBER	;extract digits, convert to binary
	MOV	CS:BPB_SSZ,CX	;store sector size

	CALL	SKIP_TO_DIGIT	;skip to next digit
	JZ	GET_PARMS_X	;found EOL, no digits remain

	CALL	GET_NUMBER	;extract digits, convert to binary
	MOV	CS:BPB_DIRN,CX	;store number of directory entries



GET_PARMS_X:			;premature end of line
	POP	DS		;restore DS
	RET



GET_MAXSIZE PROC		;get maximum sector size

	CALL	GET_PCHAR	;get next character
	CALL	CHECK_NUM	;is it a number ?
	JZ	GET_NEXTNUM	;yes, go get next number
	OR	CS:ERR_FLAG,ERR_ESIZE	;indicate invalid sector size
	RET			;
GET_NEXTNUM:			;get next number
	CALL GET_NUMBER 	;extract digits and convert to binary
	MOV CS:MAXSEC_TRF,CX	;save maximum sector size to transfer
	RET
GET_MAXSIZE ENDP



GET_PCHAR PROC			;internal proc to get next character into AL
	CMP	AL,CR		;carriage return already encountered?
	JE	GET_PCHAR_X	;don't read past end of line
	CMP	AL,LF		;line feed already encountered?
	JE	GET_PCHAR_X	;don't read past end of line
	LODSB			;get char from DS:SI, increment SI
	CMP	AL,CR		;is the char a carriage return?
	JE	GET_PCHAR_X	;yes, set Z flag at end of line
	CMP	AL,LF		;no, is it a line feed?
GET_PCHAR_X:			;attempted read past end of line
	RET
GET_PCHAR ENDP			;returns char in AL


CHECK_NUM PROC			;check AL for ASCII digit
	CMP	AL,'0'          ;< '0'?
	JB	CHECK_NUM_X	;exit if it is

	CMP	AL,'9'          ;> '9'?
	JA	CHECK_NUM_X	;exit if it is

	CMP	AL,AL		;set Z flag to indicate numeric
CHECK_NUM_X:
	RET			;Z set if numeric, NZ if not numeric
CHECK_NUM ENDP


SKIP_TO_DIGIT PROC		;skip to first numeric character
	CALL	CHECK_NUM	;is current char a digit?
	JZ	SKIP_TO_DIGIT_X ;if so, skip is complete

	CALL	GET_PCHAR	;get next character from line
	JNZ	SKIP_TO_DIGIT	;loop until first digit or CR or LF
	RET			;character is CR or LF

SKIP_TO_DIGIT_X:
	CMP	AL,0		;digit found, force NZ
	RET
SKIP_TO_DIGIT ENDP

C10	   DW	10
GN_ERR	   DB	?		;zero if no overflow in accumulation

GET_NUMBER PROC 		;convert string of digits to binary value
	XOR	CX,CX		;accumulate number in CX
	MOV	CS:GN_ERR,CL	;no overflow yet
GET_NUMBER_A:			;accumulate next digit
	SUB	AL,'0'          ;convert ASCII to binary
	CBW			;clear AH
	XCHG	AX,CX		;previous accumulation in AX, new digit in CL
	MUL	CS:C10		;DX:AX := AX*10
	OR	CS:GN_ERR,DL	;set GN_ERR <> 0 if overflow
	ADD	AX,CX		;add new digit from
	XCHG	AX,CX		;number now in CX
	DEC	SI		;back up to prior entry
	MOV	AL,' '          ;blank out prior entry
	MOV	[SI],AL 	;
	INC	SI		;set to current entry
	CALL	GET_PCHAR	;get next character
	CALL	CHECK_NUM	;see if it was numeric
	JZ	GET_NUMBER_A	;continue accumulating
	CMP	CS:GN_ERR,0	;did we overflow?
	JE	GET_NUMBER_B	;if not, we're done
	XOR	CX,CX		;return zero (always invalid) if overflow
GET_NUMBER_B:
	RET			;number in CX, next char in AL
GET_NUMBER ENDP

GET_PARMS ENDP

	SUBTTL	APPLY_DEFAULTS
	PAGE
;-----------------------------------------------------------------------;
;	APPLY_DEFAULTS supplies any parameter values that the user	;
;	failed to specify						;
;-----------------------------------------------------------------------;
	ASSUME	DS:CSEG
APPLY_DEFAULTS	PROC
	XOR	AX,AX
	CMP	BUFF_SIZE,AX		;is buffer size zero?
	JNE	APPLY_DEFAULTS_A	;no, user specified something

	MOV	BUFF_SIZE,DFLT_BSIZE	;supply default buffer size
	OR	ERR_FLAG,ERR_BSIZE	;indicate buffersize adjusted

APPLY_DEFAULTS_A:
	CMP	BPB_SSZ,AX		;is sector size zero?
	JNE	APPLY_DEFAULTS_B	;no, user specified something

	MOV	BPB_SSZ,DFLT_SSZ	;supply default sector size
	OR	ERR_FLAG,ERR_SSZ	;indicate sector size adjusted

APPLY_DEFAULTS_B:
	CMP	BPB_DIRN,AX		;are directory entries zero?
	JNE	APPLY_DEFAULTS_C	;no, user specified something

	MOV	BPB_DIRN,DFLT_DIRN	;supply default directory entries
	OR	ERR_FLAG,ERR_DIRN	;indicate directory entries adjusted

APPLY_DEFAULTS_C:			;
	CMP	EM_SW,0 		;extended memory ?
	JE	APPLY_DEFAULTS_D	;no, jump around
	CMP	MAXSEC_TRF,AX		;is maximum sectors zero?
	JNE	APPLY_DEFAULTS_D	;no, user specified something

	MOV	MAXSEC_TRF,DFLT_ESS	;supply default maximum number of
					;sector to transfer
	OR	ERR_FLAG,ERR_ESIZE	;indicate transfer size adjusted
APPLY_DEFAULTS_D:
	RET
APPLY_DEFAULTS	ENDP

	SUBTTL	DETERMINE_START address of VDISK buffer
	PAGE
;-----------------------------------------------------------------------;
;	DETERMINE_START figures out the starting address of the VDISK	;
;	buffer								;
;-----------------------------------------------------------------------;
	ASSUME	DS:CSEG
DETERMINE_START PROC

;If extended memory is NOT being used, the VDISK buffer immediately
;follows the resident code.

;If extended memory IS being used, START_BUFFER_PARA becomes the
;end of device driver address passed back to DOS.

	MOV	AX,CS			;start para of VDISK code
	ADD	AX,VDISKP		;+ length of resident code
	MOV	START_BUFFER_PARA,AX	;save as buffer start para

	CMP	EM_SW,0 		;is extended memory requested?
	JE	DETERMINE_START_X	;if not, we're done here

;If this is the first extended memory VDISK device driver to be installed,
;the start address for I/O is 1 megabyte.

;If one or more extended memory VDISK device drivers have been installed,
;the start address for I/O for THIS device driver is acquired from the
;fields AVAIL_LO and AVAIL_HI in the FIRST VDISK device driver.

;The first extended memory VDISK device driver is located by INT 19H's vector.

	MOV	FIRST_EM_SW,0FFH	;indicate first VDISK device driver
	MOV	FIRST_VDISK,CS		;segment addr of first VDISK

	PUSH	DS			;preserve DS
	XOR	AX,AX
	MOV	DS,AX			;set DS = 0
	ASSUME	DS:INT_VEC

	MOV	AX,DS:BOOT_VECS 	;get segment addr of INT 19H routine
	MOV	DS,AX			;to DS
	ASSUME	DS:NOTHING

	PUSH	CS
	POP	ES			;set ES = CS
	MOV	SI,OFFSET VOL_LABEL	;DS:SI point to VOL label field
					;in first VDISK (if present)
	MOV	DI,SI			;ES:DI point to VOL label field of
					;this VDISK

	MOV	CX,VOL_LABEL_LEN	;length of volume label
	REP	CMPSB			;does INT 19H vector point to a VDISK
					;device driver?
	JNE	DETERMINE_START_A	;jump if this is the first VDISK

;Another extended memory VDISK device driver has been installed.
;Its AVAIL_LO and AVAIL_HI are the first free byte of extended memory.

	MOV	CS:FIRST_EM_SW,0	;indicate not first device driver
	MOV	CS:FIRST_VDISK,DS	;save pointer to 1st device driver

;Copy AVAIL_LO and AVAIL_HI from first VDISK to this VDISK

	MOV	SI,OFFSET AVAIL_LO	;DS:SI point to AVAIL_LO in first VDISK
	MOV	DI,SI			;ES:DI point to AVAIL_LO in this VDISK
	MOVSW				;copy AVAIL_LO from first to this VDISK
	MOVSB				;copy AVAIL_HI

DETERMINE_START_A:			;copy AVAIL_LO and AVAIL_HI to START_EM
	POP	DS			;set DS = CS

	MOV	SI,OFFSET AVAIL_LO	;source offset
	MOV	DI,OFFSET START_EM_LO	;destination offset

	MOVSW				;move AVAIL_LO to START_EM_LO
	MOVSB				;move AVAIL_HI to START_EM_HI
DETERMINE_START_X:
	RET
DETERMINE_START ENDP

	SUBTTL	VALIDATE parameters
	PAGE
;-----------------------------------------------------------------------;
;	VALIDATE adjusts parameters as necessary			;
;-----------------------------------------------------------------------;
VAL_SSZ_TBL LABEL WORD			;table of valid sector sizes
VAL_SSZ_S  DW	128			;smallest valid sector size
	   DW	256
VAL_SSZ_L  DW	512			;largest valid sector size
VAL_SSZ_N  EQU	($-VAL_SSZ_TBL)/2	;number of table entries

	ASSUME	DS:CSEG
VALIDATE	PROC			;validate parameters
	MOV	BPB_AUSZ,1		;initial allocation unit is 1 sector

	CALL	VAL_BSIZE		;validate buffer size

	CALL	VAL_SSZ 		;validate (adjust if necessary) BPB_SSZ

VALIDATE_A:
	AND	ERR_FLAG,255-ERR_PASS	;indicate nothing changed this pass

	MOV	AX,BPB_SSZ		;sector size
	CWD				;clear DX for division
	DIV	WPARA_SIZE		;sector size/para size
	MOV	PARAS_PER_SECTOR,AX	;number of paragraphs/sector

	MOV	AX,BUFF_SIZE		;requested buffersize in KB
	MUL	C1024			;DX:AX = buffer size in bytes
	DIV	BPB_SSZ 		;/sector size = # sectors
	MOV	BPB_SECN,AX		;store number of sectors

	CALL	VAL_DIRN		;validate number of directory entries

	TEST	ERR_FLAG,ERR_PASS	;may have reset sector size
	JNZ	VALIDATE_A		;recompute directory & FAT sizes

	CALL	VAL_FAT 		;compute FAT entries, validity test

	TEST	ERR_FLAG,ERR_PASS	;if cluster size altered this pass
	JNZ	VALIDATE_A		;recompute directory & FAT sizes

;Make certain buffer size is large enough to contain:
;	boot sector(s)
;	FAT sector(s)
;	directory sector(s)
;	at least 1 data cluster

	MOV	AL,BPB_FATN		;number of FAT copies
	CBW				;clear AH
	MUL	BPB_FATSZ		;* sectors for 1 FAT = FAT sectors
	ADD	AX,BPB_RES		;+ reserved sectors
	ADD	AX,DIR_SECTORS		;+ directory sectors
	MOV	CL,BPB_AUSZ		;get sectors/cluster
	XOR	CH,CH			;CX = sectors in one cluster
	ADD	AX,CX			;+ one data cluster
	CMP	BPB_SECN,AX		;compare with sectors available
	JAE	VALIDATE_X		;jump if enough sectors

	CMP	DIR_SECTORS,1		;down to 1 directory sector?
	JBE	VALIDATE_C		;can't let it go below 1

	MOV	AX,BPB_SSZ		;sector size
	CWD				;clear DX for division
	DIV	DIRE_SIZE		;sectorsize/dir entry size = entries/sector
	SUB	BPB_DIRN,AX		;reduce directory entries by 1 sector

	OR	ERR_FLAG,ERR_DIRN	;indicate directory entries adjusted
	JMP	VALIDATE_A		;retry with new directory entries number

VALIDATE_C:				;not enough space for any VDISK
	OR	ERR_FLAG,ERR_SYSSZ
VALIDATE_X:
	RET

	SUBTTL	VAL_BSIZE Validate buffer size
	PAGE
;-----------------------------------------------------------------------;
;	VAL_BSIZE adjusts the buffer size as necessary			;
;-----------------------------------------------------------------------;
VAL_BSIZE	PROC
	CALL	GET_MSIZE		;determine memory available to VDISK
					;returns available KB in AX
	OR	AX,AX			;is any memory available at all?
	JNZ	VAL_BSIZE_B		;yes, continue

	OR	ERR_FLAG,ERR_SYSSZ	;indicate system too small for VDISK
	MOV	BUFF_SIZE,1		;set up minimal values to continue init
	MOV	AX,VAL_SSZ_S		;smallest possible sector size
	MOV	BPB_SSZ,AX
	MOV	BPB_DIRN,4		;4 directory entries
	RET

VAL_BSIZE_B:				;some memory is available
	CMP	AX,BUFF_SIZE		;is available memory >= requested?
	JAE	VAL_BSIZE_C		;if so, we're done

	MOV	BUFF_SIZE,AX		;give all available memory
	OR	ERR_FLAG,ERR_BSIZE	;indicate buffersize adjusted
VAL_BSIZE_C:
	RET


GET_MSIZE	PROC			;determine memory available to VDISK
					;returns KB available in AX
	CMP	EM_SW,0 		;extended memory?
	JE	GET_MSIZE_2		;use non-extended memory routine

	MOV	AH,EM_MEMSIZE		;function code to AH
	INT	EM_INT			;get extended memory size in AX
	JC	GET_MSIZE_Z		;if error, no extended memory installed

	MUL	C1024			;DX,AX = bytes of extended memory
	ADD	DX,10H			;DX,AX = high addr of extended memory+1
	SUB	AX,AVAIL_LO		;- address of first available byte
	SBB	DL,AVAIL_HI		;is number of free bytes
	DIV	C1024			;AX = number of whole free kilobytes
	RET

GET_MSIZE_2:				;non-extended memory size determination

;Compute AX = total system size, - (VDISK end address + 64KB)

	MOV	AX,START_BUFFER_PARA	;paragraph end of VDISK code
	XOR	DX,DX			;clear for division
	DIV	PARA_PER_KB		;KB address of load point
	ADD	DX,0FFFFH		;round upward to KB boundary
	ADC	AX,MIN_MEMORY_LEFT	;pick up CY and the 64KB we should leave
	PUSH	AX			;save across interrupt
	INT	MEM_SIZE		;get total system size
	POP	DX			;amount of total that we can't use
	SUB	AX,DX			;available space to VDISK
	JNC	GET_MSIZE_X		;exit if positive

GET_MSIZE_Z:
	XOR	AX,AX			;indicate no memory available
GET_MSIZE_X:				;exit from memory size determination
	RET
GET_MSIZE	ENDP

VAL_BSIZE	ENDP

	SUBTTL	VAL_SSZ Validate Sector Size
	PAGE
;-----------------------------------------------------------------------;
;	VAL_SSZ validates sector size, adjusting if necessary		;
;-----------------------------------------------------------------------;
VAL_SSZ PROC				;validate sector size
	CMP	CS:EM_SW,0		;extended memory ?
	JE	VAL_SSZ_ST		;no,go check sector size
	MOV	BX,MAXSEC_TRF		;move number of sectors to transfer
	CMP	BX,1			;> or equal to 1 ?
	JB	DFLT_TRF		;set default if it is
	CMP	BX,8			;> than 8 ?
	JA	DFLT_TRF		;set default if it is
	JMP	VAL_SSZ_ST		;continue processing

DFLT_TRF:				;set default
	MOV	MAXSEC_TRF,DFLT_ESS	;
	MOV	BX,MAXSEC_TRF		;
	OR	CS:ERR_FLAG,ERR_ESIZE	;indicate transfer size adjusted

VAL_SSZ_ST:				;validate sector size
	MOV	MAX_CNT,BX		;initialize maximum number of sectors
					;to transfer for extended memory case
	MOV	BX,BPB_SSZ		;requested sector size
	MOV	CX,VAL_SSZ_N		;number of table entries
	MOV	SI,OFFSET VAL_SSZ_TBL	;DS:SI point to table start
VAL_SSZ_A:
	LODSW				;get table entry, step table pointer
	CMP	AX,BX			;is value in table?
	JE	VAL_SSZ_X		;exit if value found
	LOOP	VAL_SSZ_A		;loop until table end

	MOV	BX,DFLT_SSZ		;get default sector size
	MOV	BPB_SSZ,BX		;set sector size to default value
	OR	ERR_FLAG,ERR_SSZ	;indicate sector size adjusted
VAL_SSZ_X:

;Compute the maximum number of sectors that can be moved in 64KB (less one)
;Restricting moves to this amount avoids 64KB boundary problems.

	CMP	CS:EM_SW,0		;extended memory ?
	JNE	SIZE_DONE		;yes, we are done
	XOR	DX,DX
	MOV	AX,0FFFFH		;64KB - 1
	DIV	BX			;/sector size
	MOV	MAX_CNT,AX		;max sectors in one move
SIZE_DONE:
	RET
VAL_SSZ ENDP

	SUBTTL	VAL_DIRN Validate number of directory entries
	PAGE
;-----------------------------------------------------------------------;
;	VAL_DIRN validates and adjusts the number of directory entries. ;
;									;
;	Minimum is MIN_DIRN, maximum is MAX_DIRN.  If outside these	;
;	limits, DFLT_DIRN is used.					;
;									;
;	The number of directory entries is rounded upward to fill	;
;	a sector							;
;-----------------------------------------------------------------------;
VAL_DIRN PROC
	MOV	AX,BPB_DIRN		;requested directory entries
	CMP	AX,MIN_DIRN		;if less than minimum
	JB	VAL_DIRN_A		;use default instead

	CMP	AX,MAX_DIRN		;if <= maximum
	JBE	VAL_DIRN_B		;accept value as provided

VAL_DIRN_A:
	MOV	AX,DFLT_DIRN		;use default directory entries
	OR	ERR_FLAG,ERR_DIRN	;indicate directory entries adjusted
VAL_DIRN_B:				;AX is number of directory entries
	MUL	DIRE_SIZE		;* 32 = bytes of directory requested
	DIV	BPB_SSZ 		;/ sector size = # of directory sectors
	OR	DX,DX			;test remainder for zero
	JZ	VAL_DIRN_C		;jump if exact fit

	INC	AX			;increment directory sectors
	OR	ERR_FLAG,ERR_DIRN	;indicate directory entries adjusted
VAL_DIRN_C:				;make sure enough sectors available
	MOV	DX,BPB_SECN		;total sectors on media
	SUB	DX,BPB_RES		;less reserved sectors
	SUB	DX,2			;less minimum FAT and 1 data sector
	CMP	AX,DX			;if directory sectors <= available
	JLE	VAL_DIRN_D		;use requested amount

	MOV	AX,1			;use only one directory sector
	OR	ERR_FLAG,ERR_DIRN	;indicate directory entries adjusted
VAL_DIRN_D:
	MOV	DIR_SECTORS,AX		;save number of directory sectors
	MUL	BPB_SSZ 		;dir sectors * sector size = dir bytes
	DIV	DIRE_SIZE		;dir bytes / entry size = entries
	MOV	BPB_DIRN,AX		;store adjusted directory entries
	RET
VAL_DIRN ENDP

	SUBTTL	VAL_FAT Validate File Allocation Table (FAT)
	PAGE
;-----------------------------------------------------------------------;
;VAL_FAT computes:							;
;BPB_FATSZ, the number of sectors required per FAT copy 		;
;									;
;Each FAT entry is 12 bits long, for a maximum of 4095 FAT entries.	;
;(A few FAT entries are reserved, so the highest number of FAT entries	;
;we permit is 0FE0H.)  With large buffer sizes and small sector sizes,	;
;we have more allocation units to describe than a 12-bit entry will	;
;describe.  If the number of FAT entries is too large, the sector size	;
;is increased (up to a maximum of 512 bytes), and then the allocation	;
;unit (cluster) size is doubled, until we have few enough allocation	;
;units to be properly described in 12 bits.				;
;									;
;This computation is slightly conservative in that the FAT entries	;
;necessary to describe the FAT sectors are included in the computation. ;
;-----------------------------------------------------------------------;
VAL_FAT PROC
	MOV	AX,BPB_SECN		;total number of sectors
	SUB	AX,BPB_RES		;don't count boot sector(s)
	SUB	AX,DIR_SECTORS		;don't count directory sectors
	JG	VAL_FAT_A		;jump if some remaining
	MOV	BPB_SSZ,DFLT_SSZ	;force default sector size
	OR	ERR_FLAG,ERR_SSZ+ERR_PASS  ;indicate sector size adjusted
	JMP	SHORT VAL_FAT_X 	;recompute all values
VAL_FAT_A:
	XOR	DX,DX			;clear DX for division
	MOV	CL,BPB_AUSZ		;CX = sectors/cluster
	XOR	CH,CH
	DIV	CX			;whole number of clusters in AX
	ADD	DX,0FFFFH		;set carry if remainder
	ADC	AX,0			;increment AX if remainder
	CMP	AX,MAX_FATE		;number of FAT entries too large?
	JBE	VAL_FAT_C		;no, continue

	MOV	AX,BPB_SSZ		;pick up current sector size
	CMP	AX,VAL_SSZ_L		;already at largest permitted?
	JE	VAL_FAT_B		;yes, can't make it any larger

	SHL	BPB_SSZ,1		;double sector size
	OR	ERR_FLAG,ERR_SSZB	;indicate sector size adjusted
	JMP	SHORT VAL_FAT_X 	;recompute all sizes with new BPBSSZ

VAL_FAT_B:				;sector size is at maximum
	SHL	BPB_AUSZ,1		;double allocation unit size
	OR	ERR_FLAG,ERR_PASS	;indicate another pass required
	JMP	SHORT VAL_FAT_X 	;recompute values

VAL_FAT_C:				;FAT size =  1.5 * number of clusters
	MOV	CX,AX			;number of clusters
	SHL	AX,1			;* 2
	ADD	AX,CX			;* 3
	SHR	AX,1			;* 1.5
	ADC	AX,3			;add 3 bytes for first 2 FAT entries
					;(media descriptor and FFFFH), and CY
	XOR	DX,DX			;clear DX for division
	DIV	BPB_SSZ 		;FAT size/sector size
	ADD	DX,0FFFFH		;set carry if remainder
	ADC	AX,0			;round upward
	MOV	BPB_FATSZ,AX		;number of sectors for 1 FAT copy
VAL_FAT_X:
	RET
VAL_FAT ENDP


VALIDATE	ENDP

	SUBTTL	COPY_BPB Copy BPB to Boot Record
	PAGE
;-----------------------------------------------------------------------;
;	COPY_BPB copies the BIOS Parameter Block (BPB)			;
;	to the VDISK Boot Record					;
;-----------------------------------------------------------------------;
	ASSUME	DS:CSEG
COPY_BPB	PROC			;Copy BBP to Boot Record
	PUSH	DS
	POP	ES			;set ES = DS

	MOV	CX,BPB_LEN		;length of BPB
	MOV	SI,OFFSET BPB		;source offset
	MOV	DI,OFFSET BOOT_BPB	;target offset
	REP	MOVSB			;copy BPB to boot record
	RET
COPY_BPB	ENDP

	SUBTTL	VERIFY_EXTENDER
	PAGE
;-----------------------------------------------------------------------;
;	VERIFY_EXTENDER makes sure that if an Expansion Unit is 	;
;	installed, the memory size switches on the Extender Card	;
;	are correctly set.						;
;-----------------------------------------------------------------------;


	ASSUME	DS:CSEG
EXT_P210  EQU	0210H		;write to latch expansion bus data
				;read to verify expansion bus data
EXT_P213  EQU	0213H		;Expansion Unit status

VERIFY_EXTENDER PROC

	NOP

	MOV	DX,EXT_P210	;Expansion bus data port address

	MOV	AX,5555H	;set data pattern
	OUT	DX,AL		;write 55H to control port
	PUSH	DX
	POP	DX

	JMP	SHORT $+2	;Let the I/O circuits catch up
	IN	AL,020h 	;Clear the CMOS bus drivers!

	IN	AL,DX		;recover data
	CMP	AH,AL		;did we recover the same data?
	JNE	VERIFY_EXTENDER_X	;if not, no extender card

	NOT	AX		;set AX = 0AAAAH
	OUT	DX,AL		;write 0AAH to control port
	PUSH	DX		;load data line
	POP	DX		;load data line

	JMP	SHORT $+2	;Let the I/O circuits catch up
	IN	AL,020h 	;Clear the CMOS bus drivers!

	IN	AL,DX		;recover data
	CMP	AH,AL		;did we recover the same data?
	JNE	VERIFY_EXTENDER_X	;if not, no extender card

;Expansion Unit is present.

;Determine what the switch settings should be on the Extender Card

	INT	MEM_SIZE	;get system memory size in KB in AX
	ADD	AX,63D		;memory size + 63K
	MOV	CL,6		;2^6 = 64
	SHR	AX,CL		;divide by 64
				;AX is highest segment address
	MOV	AH,AL		;save number of segments

;Read Expander card switch settings

	MOV	DX,EXT_P213	;expansion unit status
	IN	AL,DX		;read status
				;bits 7-4 (hi nibble) are switches
	MOV	CL,4		;shift count
	SHR	AL,CL		;shift switches to bits 3-0 of AL

	CMP	AH,AL		;do switches match memory size?
	JE	VERIFY_EXTENDER_X	;yes, exit normally

	OR	ERR_FLAG,ERR_EXTSW	;indicate switch settings are wrong

VERIFY_EXTENDER_X:
	RET
VERIFY_EXTENDER ENDP

	SUBTTL	UPDATE_AVAIL
	PAGE
;-----------------------------------------------------------------------;
;	UPDATE_AVAIL updates the address of the first byte in extended	;
;	memory not used by any VDISK buffer				;
;-----------------------------------------------------------------------;
UPDATE_AVAIL	PROC		;update AVAIL_LO and AVAIL_HI of first VDISK
	MOV	AX,BUFF_SIZE	;number of KB of VDISK buffer
	MUL	C1024		;DX,AX = number of bytes of VDISK buffer

	PUSH	DS
	MOV	DS,FIRST_VDISK	;set DS to first VDISK
	ADD	DS:AVAIL_LO,AX	;update first available byte location
	ADC	DS:AVAIL_HI,DL
	POP	DS
	RET
UPDATE_AVAIL	ENDP

	SUBTTL	FORMAT_VDISK
	PAGE
;-----------------------------------------------------------------------;
;	This Request Header is used by MOVE_VDISK to move the		;
;	first few sectors of the virtual disk (boot, FAT, and		;
;	Directory) into extended memory.				;
;-----------------------------------------------------------------------;

MOVE_RH    DB	MOVE_RH_L		;length of request header
	   DB	0			;sub unit
	   DB	8			;output operation
	   DW	0			;status
	   DQ	?			;reserved for DOS
	   DB	?			;media descriptor byte
MOVE_RHO   DW	?			;offset of data transfer address
MOVE_RHS   DW	?			;segment of data transfer address
MOVE_RHCNT DW	?			;count of sectors to transfer
	   DW	0			;starting sector number
MOVE_RH_L  EQU	$-MOVE_RH		;length of request header

;-----------------------------------------------------------------------;
;	FORMAT_VDISK formats the boot sector, FAT, and directory of an	;
;	extended memory VDISK in storage immediately following		;
;	VDISK code, in preparation for moving to extended memory.	;
;-----------------------------------------------------------------------;
FORMAT_VDISK	PROC			;format boot record, FATs and directory

	MOV	AX,CS			;compute 20-bit address
	MUL	WPARA_SIZE		;16 * segment
	ADD	AX,OFFSET MSGEND	;+ offset
	ADC	DL,0			;pick up carry
	ADD	AX,STACK_SIZE		;plus stack size
	ADC	DL,0			;pick up carry

	DIV	WPARA_SIZE		;split into segment(AX)&offset(DX)
	MOV	MOVE_RHS,AX		;save in Request Header for move
	MOV	MOVE_RHO,DX

	MOV	DI,DX			;offset to DI
	MOV	ES,AX			;segment to ES

;copy the boot record

	MOV	SI,OFFSET BOOT_RECORD	;point to source field
	MOV	AX,BPB_RES		;number of reserved sectors
	MUL	BPB_SSZ 		;* sector size = length of boot records
	MOV	CX,AX			;length to CX for move
	REP	MOVSB			;move boot record(s)

;format the FAT(s)

	MOV	CL,BPB_FATN		;number of FATs
	XOR	CH,CH
FORMAT_VDISK_A: 			;set up one FAT
	PUSH	CX			;save loop counter on stack
	MOV	AL,BPB_MCB		;media control byte
	STOSB				;store media control byte, increment DI
	MOV	AX,0FFFFH		;bytes 2 and 3 of FAT are 0FFH
	STOSW
	MOV	AX,BPB_FATSZ		;number of sectors per FAT
	MUL	BPB_SSZ 		;* sector size = length of FAT in bytes
	SUB	AX,3			;less the 3 bytes we've stored
	MOV	CX,AX			;count to CX
	XOR	AX,AX
	REP	STOSB			;clear remainder of FAT
	POP	CX			;get loop counter off stack
	LOOP	FORMAT_VDISK_A		;loop for all copies of the FAT

;Format the directory

	MOV	SI,OFFSET VOL_LABEL	;point to volume label
	MOV	CX,VOL_LABEL_LEN	;length of volume directory entry
	REP	MOVSB			;move volume id to directory
	MOV	AX,DIR_ENTRY_SIZE	;length of 1 directory entry
	MUL	BPB_DIRN		;* number entries = bytes of directory
	SUB	AX,VOL_LABEL_LEN	;less length of volume label
	MOV	CX,AX			;CX = length of rest of directory
	XOR	AX,AX
	REP	STOSB			;clear directory to nulls
	RET
FORMAT_VDISK	ENDP

	SUBTTL	MOVE_VDISK
	PAGE
;-----------------------------------------------------------------------;
;	MOVE_VDISK moves the formatted boot sector, FAT, and directory	;
;	into extended memory.						;
;-----------------------------------------------------------------------;

MOVE_VDISK	PROC
	MOV	AL,BPB_FATN		;number of FAT copies
	CBW				;clear AH
	MUL	BPB_FATSZ		;number of FAT sectors
	ADD	AX,BPB_RES		;+ reserved sectors
	ADD	AX,DIR_SECTORS		;+ directory sectors
	MOV	MOVE_RHCNT,AX		;store as I/O length

	MOV	BX,OFFSET MOVE_RH	;DS:BX point to request header
	PUSH	DS			;make sure DS gets preserved
	CALL	INOUT			;move to extended memory
	POP	DS
	RET
MOVE_VDISK	ENDP

	SUBTTL	UPDATE_BOOT
	PAGE
;-----------------------------------------------------------------------;
;	UPDATE_BOOT updates the BOOT_EM word in the first extended	;
;	memory VDISK (address 10 001EH) to show the kilobyte address	;
;	of the first extended memory byte not used by any VDISK buffer. ;
;-----------------------------------------------------------------------;
UPDATE_BOOT	PROC
	PUSH	DS
	MOV	DS,FIRST_VDISK		;set DS to first VDISK
	MOV	AX,DS:AVAIL_LO		;24-bit end address of all VDISKs
	MOV	DL,DS:AVAIL_HI
	XOR	DH,DH
	POP	DS
	DIV	C1024			;address / 1024
	MOV	BOOT_EM,AX		;store in temporary location

	MOV	AX,2			;length of block move is 2 bytes
	MOV	TGT.DESC_LMT,AX
	MOV	SRC.DESC_LMT,AX

	MOV	AX,PARA_SIZE		;16
	MOV	CX,CS			;our segment address
	MUL	CX			;16 * segment address
	ADD	AX,OFFSET BOOT_EM	;+ offset of source data
	ADC	DL,0			;pick up any carry

	MOV	SRC.DESC_BASEL,AX	;store source base address
	MOV	SRC.DESC_BASEH,DL

	MOV	TGT.DESC_BASEL,BOOT_EM_OFF	;offset of BOOT_EM
	MOV	TGT.DESC_BASEH,10H	;1 megabyte

	MOV	CX,1			;move 1 word

	PUSH	CS
	POP	ES
	MOV	SI,OFFSET GDT		;ES:DI point to global descriptor table

	MOV	AH,EM_BLKMOVE		;function code
	INT	EM_INT			;move BOOT_EM to 10 001EH
	RET
UPDATE_BOOT	ENDP

	SUBTTL	STEAL_INT19
	PAGE
;-----------------------------------------------------------------------;
;	STEAL_INT19 changes the INT 19H vector to point to this VDISK	;
;	so that subsequent extended memory VDISKS may locate the	;
;	AVAIL_HI and AVAIL_LO fields to determine their buffer start	;
;	addresses.							;
;-----------------------------------------------------------------------;
STEAL_INT19	PROC
	PUSH	DS
	XOR	AX,AX
	MOV	DS,AX			;set DS = 0
	ASSUME	DS:INT_VEC
	CLI				;disable interrupts
	LES	DI,DS:BOOT_VEC		;get original vector's content
	MOV	CS:INTV19O,DI		;save original vector
	MOV	CS:INTV19S,ES
	MOV	DS:BOOT_VECO,OFFSET VDISK_INT19 ;offset of new INT routine
	MOV	DS:BOOT_VECS,CS 	;segment of new INT routine
	STI				;enable interrupts again
	POP	DS			;restore DS
	RET
STEAL_INT19	ENDP

	SUBTTL	FILL_RH Fill in Request Header
	PAGE
;-----------------------------------------------------------------------;
;	FILL_RH fills in the Request Header returned to DOS		;
;-----------------------------------------------------------------------;
	ASSUME	DS:CSEG
FILL_RH PROC				;fill in INIT Request Header fields
	MOV	CX,START_BUFFER_PARA	;segment end of VDISK resident code
	MOV	AX,PARAS_PER_SECTOR	;paragraphs per sector
	MUL	BPB_SECN		;* number of sectors
	ADD	AX,CX			;+ starting segment
	MOV	DX,AX			;DX is segment of end VDISK buffer
	CMP	EM_SW,0 		;if extended memory not requested
	JE	FILL_RH_A		;skip DX adjustment

	MOV	DX,CX			;end of code segment addr
FILL_RH_A:				;DX is proper ending segment address
	MOV	AL,1			;number of units
	test	CS:err_flag2,err_baddos
	jnz	dont_install

	TEST	ERR_FLAG,ERR_SYSSZ+ERR_EXTSW	;if bypassing install
	JZ	FILL_RH_B		;jump if installing driver

dont_install:
	MOV	DX,CS			;segment of end address
	XOR	AL,AL			;number of units is zero
FILL_RH_B:
	PUSH	DS			;preserve DS
	LDS	BX,RH_PTRA		;get Request Header addr in DS:BX
	MOV	RH.RH0_NUN,AL		;store number of units (0 or 1)
	MOV	RH.RH0_ENDO,0		;end offset is always zero
	MOV	RH.RH0_ENDS,DX		;end of VDISK or end of buffer
	MOV	RH.RH0_BPBO,OFFSET BPB_PTR
	MOV	RH.RH0_BPBS,CS		;BPB array address
	POP	DS			;restore DS
	RET
FILL_RH ENDP

	SUBTTL	WRITE_MESSAGES and associated routines
	PAGE
;-----------------------------------------------------------------------;
;	WRITE_MESSAGE writes a series of messages to the standard	;
;	output device showing the VDISK parameter values actually used. ;
;-----------------------------------------------------------------------;

CHAR4	   DB	'nnnn$'         ;build 4 ASCII decimal digits

	ASSUME	DS:CSEG
WRITE_MESSAGES	PROC		;display all messages

	MSG	IMSG		;'VDISK virtual disk $'

	test	CS:err_flag2,err_baddos
	jz	check_dos_version

	msg	errm8
	ret

;If DOS Version 3.x is in use, the Request Header contains a drive code
;that is displayed to show which drive letter was assigned to this
;VDISK.  This field is not present in the DOS Version 2 Request Header.

check_dos_version:
	MOV	AH,DOS_VERS	;get DOS version call
	INT	DOS		;invoke DOS

	CMP	AL,3		;DOS Version 3 or greater?
	JB	WRITE_MESSAGES_A	;no, bypass drive letter

	PUSH	DS		;preserve DS
	LDS	BX,RH_PTRA	;get Request Header Address
	MOV	DL,RH.RH0_DRIV	;get drive code
	ADD	DL,'A'          ;convert to drive letter
	POP	DS		;restore DS

	MOV	AH,DOS_PCHR	;function code to write character in DL
	INT	DOS		;display drive letter

	MOV	DL,':'          ;display trailing colon
	INT	DOS

WRITE_MESSAGES_A:
	MSG	MSGCRLF 	;end the first line

;If any of the user specified values has been adjusted, issue an
;appropriate message

	TEST	ERR_FLAG,ERR_BSIZE	;was buffersize adjusted?
	JZ	WRITE_MESSAGES_B	;if not, skip message

	MSG	ERRM1			;buffer size adjusted

WRITE_MESSAGES_B:
	TEST	ERR_FLAG,ERR_SSZ	;was sector size adjusted?
	JZ	WRITE_MESSAGES_C	;if not, skip message

	MSG	ERRM2			;sector size adjusted

WRITE_MESSAGES_C:
	TEST	ERR_FLAG,ERR_DIRN	;were directory entries adjusted?
	JZ	WRITE_MESSAGES_D0	;if not, skip message

	MSG	ERRM3			;directory entries adjusted

WRITE_MESSAGES_D0:
	TEST	ERR_FLAG,ERR_ESIZE	;was transfer size adjusted?
	JZ	WRITE_MESSAGES_D	;if not, skip message

	MSG	ERRM7			;transfer size adjusted

WRITE_MESSAGES_D:
	TEST	ERR_FLAG,ERR_SWTCH	;was an invalid switch character found?
	JZ	WRITE_MESSAGES_E	;if not, skip message

	MSG	ERRM5			;invalid switch character

WRITE_MESSAGES_E:
	TEST	ERR_FLAG,ERR_SYSSZ	;is system size too small to install?
	JZ	WRITE_MESSAGES_F	;if not, bypass error message

	MSG	ERRM4			;too large for system storage
	RET				;skip messages showing adjusted sizes

WRITE_MESSAGES_F:
	TEST	ERR_FLAG,ERR_EXTSW	;extender card switches wrong?
	JZ	WRITE_MESSAGES_G	;if not, bypass error message

	MSG	ERRM6			;extender card switches wrong msg
	RET				;skip remaining messages

WRITE_MESSAGES_G:			;display adjusted size messages
	MSG	MSG1			;buffer size:

	MOV	DX,BUFF_SIZE		;buffer size in binary
	CALL	STOR_SIZE		;convert  binary to ASCII decimal
	MSG	CHAR4			;print 4 decimals
	MSG	MSG2			;KB,CR,LF

	MSG	MSG3			;sector size:
	MOV	DX,BPB_SSZ
	CALL	STOR_SIZE		;convert binary to ASCII decimal
	MSG	CHAR4			;print 4 decimals
	MSG	MSGCRLF 		;finish off line

	MSG	MSG4			;directory entries:
	MOV	DX,BPB_DIRN		;number of directory entries
	CALL	STOR_SIZE
	MSG	CHAR4			;print 4 decimals
	MSG	MSGCRLF 		;finish off the line

	CMP	CS:EM_SW,0		;extended memory ?
	JE	END_LINE		;
	MSG	MSG5			;transfer size:
	MOV	DX,MAXSEC_TRF
	CALL	STOR_SIZE		;convert binary to ASCII decimal
	MSG	CHAR4			;print 4 decimals
	MSG	MSGCRLF 		;finish off line

END_LINE:
	MSG	MSGCRLF 		;one more blank line to set it off
	RET				;return to INIT_P1

;SHOW_MSG displays a string at DS:DX on the standard output device
;String is terminated by a $

SHOW_MSG	PROC			;display string at DS:DX
	PUSH	AX			;preserve AX across call
	MOV	AH,DOS_PSTR		;DOS function code
	INT	DOS			;invoke DOS print string function
	POP	AX			;restore AX
	RET
SHOW_MSG	ENDP

;STOR_SIZE converts the content of DX to 4 decimal characters in CHAR4
;(DX must be <= 9999)

STOR_SIZE PROC			;convert DX to 4 decimals in CHAR4
				;develop 4 packed decimal digits in AX
	XOR	AX,AX		;clear result register
	MOV	CX,16		;shift count
STOR_SIZE_B:
	SHL	DX,1		;shift high bit into carry
	ADC	AL,AL		;double AL, carry in
	DAA			;adjust for packed decimal
	XCHG	AL,AH
	ADC	AL,AL		;double high byte, carry in
	DAA
	XCHG	AL,AH
	LOOP	STOR_SIZE_B	;AX contains 4 packed decimal digits

	PUSH	CS
	POP	ES		;point ES:DI to output string
	MOV	DI,OFFSET CHAR4

	MOV	CX,1310H	;10H in CL is difference between blank and zero
				;13H in CH is decremented and ANDed to force
				;last character not to be zero suppressed
	PUSH	AX		;save AX on stack
	MOV	DL,AH		;2 decimals to DL
	CALL	STOR_SIZE_2	;display DL as 2 decimal characters
	POP	DX		;bring low 2 decimals into DL
STOR_SIZE_2:			;display DL as 2 decimal characters
	MOV	DH,DL		;save 2 decimals in DH
	SHR	DL,1		;shift high order decimal right to low position
	SHR	DL,1
	SHR	DL,1
	SHR	DL,1
	CALL	STOR_SIZE_1	;display low nibble of DL
	MOV	DL,DH		;get low decimal from pair
STOR_SIZE_1:			;display low nibble of DL as 1 decimal char
	AND	DL,0FH		;clear high nibble
	JZ	STOR_SIZE_Z	;if digit is significant,
	XOR	CL,CL		;defeat zero suppression
STOR_SIZE_Z:
	DEC	CH		;decrement zero suppress counter
	AND	CL,CH		;always display least significant digit
	OR	DL,'0'          ;convert packed decimal to ASCII
	SUB	DL,CL		;zero suppress (nop or change '0' to ' ')
	MOV	AL,DL		;char to DL
	STOSB			;store char at ES:DI, increment DI
	RET
STOR_SIZE ENDP

WRITE_MESSAGES	ENDP

INIT_P1 ENDP			;end of INIT part one

;-----------------------------------------------------------------------;
;	VDISK Message  definitions					;
;-----------------------------------------------------------------------;

IMSG	DB	'VDISK virtual disk ','$'

ERRM1	DB	'   Buffer size adjusted',CR,LF,'$'
ERRM2	DB	'   Sector size adjusted',CR,LF,'$'
ERRM3	DB	'   Directory entries adjusted',CR,LF,'$'
ERRM4	DB	'   VDISK not installed - insufficient memory'
	DB	CR,LF,CR,LF,BEL,'$'
ERRM5	DB	'   Invalid switch character',CR,LF,'$'
ERRM6	DB	'   VDISK not installed - Extender Card switches'
	DB	CR,LF
	DB	'   do not match system memory size'
	DB	CR,LF,CR,LF,BEL,'$'
ERRM7	DB	'   Transfer size adjusted',CR,LF,'$'
ERRM8	DB	'   VDISK not installed - Incorrect DOS version'
	DB	CR,LF,CR,LF,BEL,'$'

MSG1	DB	'   Buffer size:       $'
MSG2	DB	' KB'
MSGCRLF DB	CR,LF,'$'
MSG3	DB	'   Sector size:       $'
MSG4	DB	'   Directory entries: $'
MSG5	DB	'   Transfer size:     $'
MSGEND	LABEL	BYTE				; End of message text

CSEG	ENDS
	END
