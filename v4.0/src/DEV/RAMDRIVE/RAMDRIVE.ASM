	TITLE	EXTENDED MEMORY RAMDRIVE

PAGE	58,132

;
; Will use IBM extended memory on PC-AT or
;      use Above Board on PC, XT, or AT or
;      use main memory on PC, XT, or AT
;
;
;	device = ramdrive.sys [bbbb] [ssss] [dddd] [/E | /A]
;
;		bbbb  First numeric argument, if present, is disk size
;			in K bytes. Default value is 64. Min is 16. Max
;			is 4096 (4 Meg).
;
;		ssss  Second numeric argument, if present, is sector size
;			in bytes. Default value is 512. Allowed values are
;			128, 256, 512, 1024.
;		      NOTE: In the case of IBM PC DOS the MAX value is 512.
;			If 1024 is specified the device will not be installed.
;			This "error" is detected by DOS and is not due to
;			the code in RAMDrive.
;			The 1024 byte size is included for those MS-DOS systems
;			where it might be allowed.
;
;		dddd  Third numeric argument, if present, is the number of
;			root directory entries. Default is 64. Min is 2
;			max is 1024. The value is rounded up to the nearest
;			sector size boundary.
;		      NOTE: In the event that there is not enough memory
;			to create the RAMDrive volume, RAMDrive will try to make
;			a DOS volume with 16 directory entries. This may
;			result in a volume with a different number of directory
;			entries than the dddd parameter specifies.
;
;		/E    Specifies that PC AT Extended Memory is to be used.
;			It is an error if /E is specified on a machine other
;			than an IBM PC AT.
;		      NOTE: Information on RAMDrive drives in PC AT extended memory
;			will be lost at system re-boot (warm or cold). This is
;			due to the fact that the IBM PC AT ROM bootstrap code
;			zeroes all of memory.
;		      NOTE: There is 1k of RAMDrive overhead. That is to say,
;			if there are 512k bytes of extended memory, there
;			will be 511k bytes available for assignment to RAMDrive
;			drives. This 1k overhead is fixed and does not depend
;			on the number of RAMDrive drives installed.
;
;		/A    Specifies that Above Board memory is to be used. It
;			is an error if the above board device driver is not
;			present.
;		      NOTE: Information on RAMDrive drives in Above Board memory
;			will be lost at system re-boot (warm or cold). This is
;			due to the fact that the EMM device driver performs a
;			destructive test when it is installed which zeros all
;			of the Above Board memory.
;
;		Neither /A or /E Specifies drive is to be set up below the
;			640K boundary in main memory.
;		      The RAMDRIVE.SYS program looks for memory to assign to the RAMDrive
;			drives by looking for functioning system RAM between the
;			"end of memory" as determined by the INT 12H ROM BIOS
;			function, and the start of the video RAM (0A000:0H).
;		      If RAM is found by the above scan, it is assigned to
;			RAMDrive and managed in the same way as extended memory
;			is when the /E switch is used. As with /E there is
;			1k of RAMDrive overhead. That is to say, if there are 256k
;			bytes of memory above the INT 12 memory size, there
;			will be 255k bytes available for assignment to RAMDrive
;			drives. This 1k overhead is fixed and does not depend
;			on the number of RAMDrive drives installed.
;			Information on such RAMDrive drives will NOT be lost on
;			a "warm boot" (INT 19H or Ctrl-Alt-DEL).
;		      If RAM is NOT found by the above scan, RAMDrive will attempt
;			to allocate memory for the device AS PART OF THE DEVICE.
;			In other words the device starts immediately after the
;			RAMDrive resident code.
;			Information on such RAMDrive drives WILL BE lost on
;			a "warm boot" (INT 19H or Ctrl-Alt-DEL).
;
;
;
; MODIFICATION HISTORY
;
;	1.00	5/30/85 ARR Initial version.
;
;	1.01	6/03/85 ARR Added CSIZE home code in INIDRV. Does a better
;			    job of computing good CSIZE value.
;
;	1.10	6/05/85 ARR Changed name of program from VDISK to RAMDRIVE
;
;	1.11	6/06/85 ARR Changed BAD_AT message
;
;	1.12	6/06/85 ARR Fixed bug in /A BLKMOV code. Was forgetting
;			    to save and restore page mapping context
;
;	1.13	6/14/85 ARR Was using 32 bit shifts to do div/mul by
;			    powers of two. As it turns out, using the
;			    DIV or MUL instruction is faster. This is
;			    so even for small numbers like 16. This is
;			    due to the fact that the LOOP involved in
;			    doing a 32 bit shift is expensive.
;
;	1.14	6/14/85 ARR dddd param minimum changed from 4 to 2
;			    to be IBM compatible. Code added to round
;			    up to sector size boundaries.
;
;	1.15	6/24/85 ARR Assorted clean up, mostly in Above Board
;			    code.
;
;	1.16	7/09/85 ARR Align code more closely to the G.L.
;			    coding standard.
;
;			    Changed ITOA routine. Smaller and will print any
;			    16 bit value.
;
;			    DISK_ABORT would run through EMM_CTRL reset code
;			    on a RESMEM_SPECIAL driver. Added code
;			    to skip if this type of driver.
;
;			     Added check in CHECK_DOS_VOL in event valid BPB
;			     is found to make sure SSIZE and DIRNUM values
;			     match. If you edit DEVICE = to change these
;			     values on an existing drive and re-boot
;			     RAMDrive would ignore you and suck up old
;			     values.
;
;		11/12/85 ARR DEBUG EQU added and some RESMEM debug code
;			     stuck in to discover that the HP Vectra is
;			     not as AT compatible as HP thinks.
;
;		02/11/86 ARR Message area identified by "TRANSLATION"
;			     and translation notes added to several
;			     messages
;
;		04/03/86 ARR Changed use of SIDT to set GDT descriptor
;			     in /E init code to SGDT. Previous masm wouldn't
;			     assemble SGDT, new one works OK.
;
;	1.17	5/26/86  ARR New version for "above" insignificgant changes. And
;			     fixed major oops in /e RESET_SYSTEM code which would
;			     hang the system if an interrupt occured at the wrong
;			     time.
;
;	1.19	3/4/87	 SP  Fixed CSIZ homing oscillation bug. Shifted Ramdriv
;			     configuration display code before relocation code
;			     to facilitate creation of message module. Shifted
;			     translatable messages to message module.
;
;	2.00	8/23/87  sp  386 support ( both prot mode transfer and int15 )
;			     286 loadall kludge
;			     new int15 allocation
;			     new above_blkmov routine (to handle overlapping
;			     transfers in above board memory
;			     olivetti support
;			     removed int 9 trapping
;			     reset code different for extended memory
;
;	2.01	9/28/87  sp  Fixed bug in parsing for /u option
;
;	2.02	3/02/88  sp  Extended PS2 model 80 recognition to more than
;			     one sub-model
;	2.03	5/13/88  SP  extended version check to include dos 4.00
;
;	2.04	5/23/88  SP  reworked messages to mention expanded memory
;
;	2.10	6/13/88  CHIPA Merged in HP Vectra stuff
;		11/20/87 RCP Fixed a20 enabling/disabling problems on
;			     Vectra machines.
;
;	2.12	7/26/88  SP  Ramdrives installed between int12 and A000 are
;			     no longer attempted.

BREAK	MACRO	subtitle
	SUBTTL	subtitle
	PAGE
ENDM

.286p				; Use some 286 instructions in /E code

DEBUG	EQU	0

IF1
    IF DEBUG
	%out DEBUG VERSION!!!!!!
    ENDIF
ENDIF

.xlist
	include devsym.inc
	include syscall.inc
	include dirent.inc
	include mi.inc
.list

; The RAMDrive device driver has 4 basic configurations.
;
;	TYPE 1 - /E configuration using PC-AT extended memory and the LOADALL
;		instruction.
;
;	TYPE 2 - /A configuration using Above Board memory and EMM device
;		driver.
;
;	TYPE 3 - Neither /A or /E (RESMEM) configuration using main memory
;		and normal 8086 addressing, RAMDrive memory is located
;		somewhere AFTER the "end of memory" as indicated by the
;		INT 12H memory size.
;
;	TYPE 4 - RESMEM configuration as TYPE 3 EXCEPT that the RAMDrive
;		memory is part of the RAMDrive device driver.
;
; The TYPE 2 driver uses the Above Board EMM device driver via INT 67H
;    to control access to, and to access the available memory.
;
; The TYPE 4 driver needs no external help to control access to the available
;    memory since the RAMDrive memory is part of the device driver and
;    immediately follows the RAMDrive code in memory.
;
; The TYPE 1 and TYPE 3 configurations use the EMM control sector to
;    control access to the available memory

	include emm.inc

	include loadall.inc

	include above.inc

	include ab_macro.inc

BREAK	<I/O Packet offset declarations>

;
; Define I/O packet offsets for useful values.
;
; SEE ALSO
;	MS-DOS Technical Reference manual section on Installable Device Drivers
;
; MACHINE ID EQUATES
S_OLIVETTI	EQU	01H		; Olivetti 6300 PLUS machine
S_VECTRA	EQU	02H		; Vectra PC machine

; READ/WRITE PACKET OFFSETS
RW_COUNT	EQU	WORD PTR (SIZE SRHEAD) + 5
RW_TRANS	EQU	DWORD PTR (SIZE SRHEAD) + 1
RW_START	EQU	WORD PTR (SIZE SRHEAD) + 7

; MEDIA CHECK PACKET OFFSETS
MCH_RETVAL	EQU	BYTE PTR (SIZE SRHEAD) + 1
MCH_MEDIA	EQU	BYTE PTR (SIZE SRHEAD) + 0

; BUILD BPB PACKET OFFSETS
BPB_BUFFER	EQU	DWORD PTR (SIZE SRHEAD) + 1
BPB_MEDIA	EQU	BYTE PTR (SIZE SRHEAD) + 0
BPB_BPB 	EQU	DWORD PTR (SIZE SRHEAD) + 5

; INIT PACKET OFFSETS
INIT_NUM	EQU	BYTE PTR (SIZE SRHEAD) + 0
INIT_BREAK	EQU	DWORD PTR (SIZE SRHEAD) + 1
INIT_BPB	EQU	DWORD PTR (SIZE SRHEAD) + 5
INIT_DOSDEV	EQU	BYTE PTR (SIZE SRHEAD) + 9

BREAK	<some segment definitions>

;; In order to address memory above 1 MB on the AT&T 6300 PLUS, it is
;; necessary to use the special OS-MERGE hardware to activate lines
;; A20 to A23.  However, these lines can be disabled only by resetting
;; the processor.  The return address offset and segment can be found 
;; at 40:a2, noted here as RealLoc1.
;;
BiosSeg	segment at 40h		;; Used to locate 6300 PLUS reset address
	org	00a2h
RealLoc1 dd	0
BiosSeg	ends
;
R_Mode_IDT  segment at 0h
R_mode_IDT  ends
;

BREAK	<Device header>

RAMCODE SEGMENT
ASSUME	CS:RAMCODE,DS:NOTHING,ES:NOTHING,SS:NOTHING

;**
;
;	RAMDRIVE DEVICE HEADER
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;
;	SEE ALSO
;	  MS-DOS Technical Reference manual section on
;	  Installable Device Drivers
;

RAMDEV	LABEL	WORD
	DW	-1,-1
DEVATS	DW	DEVOPCL
	DW	STRATEGY
	DW	RAM$IN
	DB	1			;1 RAMDRIVE


BREAK	<Command dispatch table>

;**
;
; This is the device driver command dispatch table.
;
; The first byte indicates the size of the table and therefore defines
; which device function codes are valid.
;
; The entries in the table are NEAR word addresses of the appropriate
; device routine. Thus the address of the routine to handle device function
; 3 is:
;	WORD at ((RAMTBL + 1) + (2 * 3))
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;
;

RAMTBL	LABEL	WORD
	DB	15			; Max allowed command code
	DW	RAM$INIT
	DW	MEDIA$CHK
	DW	GET$BPB
	DW	CMDERR
	DW	RAM$READ
	DW	DEVEXIT
	DW	DEVEXIT
	DW	DEVEXIT
	DW	RAM$WRIT
	DW	RAM$WRIT
	DW	DEVEXIT
	DW	DEVEXIT
	DW	DEVEXIT
	DW	DEVEXIT
	DW	DEVEXIT
	DW	RAM$REM


BREAK	<BPB and boot sector for installed device>

;**  RAMDRIVE BIOS PARAMETER BLOCK AND BOGUS BOOT SECTOR
;
;	This region is a valid DOS 2.X 3.X "boot sector" which contains
;	the BPB. This is used for signiture verification of a valid
;	RAMDrive as well as for storage of the relevant BPB parameters.
;
;	The BOOT_START code is a very simple stub which does nothing
;	except go into an infinite loop. THIS "CODE" SHOULD NEVER
;	BE EXECUTED BY ANYONE.
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;
;

BOOT_SECTOR	LABEL	BYTE
	JMP	BOOT_START
	DB	"RDV 1.20"

RDRIVEBPB:
SSIZE	DW	512		; Physical sector size in bytes
CSIZE	DB	0		; Sectors/allocation unit
RESSEC	DW	1		; Reserved sectors for DOS
FATNUM	DB	1		; No. allocation tables
DIRNUM	DW	64		; Number directory entries
SECLIM	DW	0		; Number sectors
	DB	0F8H		; Media descriptor
FATSEC	DW	1		; Number of FAT sectors
	DW	1		; Number of sectors per track
	DW	1		; Number of heads
	DW	0		; Number of hidden sectors

SEC_SHFT DB	8		; Shifting number of
				;  sectors LEFT by this
				;  many bits yields #words
				;  in that many sectors.
				;  128	 6
				;  256	 7
				;  512	 8
				;  1024  9

BOOT_START:
	JMP	BOOT_START

BOOT_SIG	LABEL BYTE
	DB	(128 - (OFFSET BOOT_SIG - OFFSET BOOT_SECTOR)) DUP ("A")

;
; The following label is used to determine the size of the boot record
;		OFFSET BOOT_END - OFFSET BOOT_SECTOR
;
BOOT_END LABEL BYTE

BREAK	<Common Device code>

;	RAMDRIVE DEVICE ENTRY POINTS - STRATEGY, RAM$IN
;
;	This code is standard DOS device driver function dispatch
;	code. STRATEGY is the device driver strategy routine, RAM$IN
;	is the driver interrupt routine.
;
;	RAM$IN uses RAMTBL to dispatch to the appropriate handler
;	for each device function. It also does standard packet
;	unpacking.
;
;	SEE ALSO
;	  MS-DOS Technical Reference manual section on
;	  Installable Device Drivers
;

ASSUME	CS:RAMCODE,DS:NOTHING,ES:NOTHING,SS:NOTHING

PTRSAV	DD	0			; Storage location for packet addr

;**	STRATEGY - Device strategy routine
;
;	Standard DOS 2.X 3.X device driver strategy routine. All it does
;	is save the packet address in PTRSAV.
;
;	ENTRY	ES:BX -> Device packet
;	EXIT	NONE
;	USES	NONE
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;
;

STRATP	PROC	FAR

STRATEGY:
	MOV	WORD PTR [PTRSAV],BX	; Save packet addr
	MOV	WORD PTR [PTRSAV+2],ES
	RET

STRATP	ENDP

;**	RAM$IN - Device interrupt routine
;
;	Standard DOS 2.X 3.X device driver interrupt routine.
;
;
;	ENTRY	PTRSAV has packet address saved by previous STRATEGY call.
;	EXIT	Dispatch to appropriate function handler
;			CX = Packet RW_COUNT
;			DX = Packet RW_START
;			ES:DI = Packet RW_TRANS
;			DS = RAMCODE
;			STACK has saved values of all regs but FLAGS
;		    All function handlers must return through one of
;			the standard exit points
;	USES	FLAGS
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;
;

RAM$IN:
	PUSH	SI
	PUSH	AX
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	BP
	PUSH	DS
	PUSH	ES
	PUSH	BX

	LDS	BX,[PTRSAV]	       ;GET POINTER TO I/O PACKET
    ;
    ; Set up registers for READ or WRITE since this is the most common case
    ;
	MOV	CX,DS:[BX.RW_COUNT]	;CX = COUNT
	MOV	DX,DS:[BX.RW_START]	;DX = START SECTOR
	MOV	AL,DS:[BX.REQFUNC]	; Command code
	MOV	AH,BYTE PTR [RAMTBL]	; Valid range
	CMP	AL,AH
	JA	CMDERR			; Out of range command code
	MOV	SI,OFFSET RAMTBL + 1	; Table of routines
	CBW				; Make command code a word
	ADD	SI,AX			; Add it twice since one word in
	ADD	SI,AX			;  table per command.

	LES	DI,DS:[BX.RW_TRANS]	; ES:DI transfer address

	PUSH	CS
	POP	DS

ASSUME	DS:RAMCODE

	JMP	WORD PTR [SI]		; GO DO COMMAND

;**	EXIT - ALL ROUTINES RETURN THROUGH ONE OF THESE PATHS
;
;	Exit code entry points:
;
;	SEE ALSO
;	  MS-DOS Technical Reference manual section on
;	  Installable Device Drivers
;
;	GENERAL ENTRY for all entry points
;		All packet values appropriate to the specific device function
;		filled in except for the status word in the static request
;		header.
;
;	CMDERR - Used when an invalid device command is detected
;
;		ENTRY Stack has frame set up by RAM$IN
;		EXIT  Standard Device driver with error 3
;		USES  FLAGS
;
;	ERR$CNT - Used when READ or WRITE wants to return with error code.
;		   The packet RW_COUNT field is zeroed
;
;		ENTRY AL is error code for low byte of packet status word
;		      Stack has frame set up by RAM$IN
;		EXIT  Standard Device driver with error AL
;		USES  FLAGS
;
;	ERR$EXIT - Used when a function other that READ or WRITE wants to
;			return an error
;
;		ENTRY AL is error code for low byte of packet status word
;		      Stack has frame set up by RAM$IN
;		EXIT  Standard Device driver with error AL
;		USES  FLAGS
;
;	DEVEXIT - Used when a function wants to return with no error
;
;		ENTRY AL is value for low byte of packet status word
;		       NOTE: Typically there is no meaningful value
;			in the AL register when EXITing through here.
;			This is OK as the low 8 bits of the status word
;			have no meaning unless an error occured.
;		      Stack has frame set up by RAM$IN
;		EXIT  Standard Device driver with no error
;		USES  FLAGS
;
;	ERR1 - Used when a function wants to return with a value
;			for the whole status word
;
;		ENTRY AX is value for packet status word
;		      Stack has frame set up by RAM$IN
;		EXIT  Standard Device driver with or without error
;		USES  FLAGS
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;
;

ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

CMDERR:
	MOV	AL,3			;UNKNOWN COMMAND ERROR
	JMP	SHORT ERR$EXIT

ERR$CNT:
	LDS	BX,[PTRSAV]
	MOV	[BX.RW_COUNT],0 	; NO sectors transferred
ERR$EXIT:				; Error in AL
	MOV	AH,(STERR + STDON) SHR 8  ;MARK ERROR RETURN
	JMP	SHORT ERR1

EXITP	PROC	FAR

DEVEXIT:
	MOV    AH,STDON SHR 8
ERR1:
	LDS	BX,[PTRSAV]
	MOV	[BX.REQSTAT],AX 	; Set return status

	POP	BX
	POP	ES
	POP	DS
	POP	BP
	POP	DI
	POP	DX
	POP	CX
	POP	AX
	POP	SI
	RET				;RESTORE REGS AND RETURN
EXITP	ENDP


;**	MEDIA$CHK - Device Driver Media check routine
;
;	RAMDRIVE Media check routine. ALWAYS returns media not changed
;
;	SEE ALSO
;	  MS-DOS Technical Reference manual section on
;	  Installable Device Drivers
;
;	ENTRY from RAM$IN
;	EXIT through DEVEXIT
;	USES DS,BX
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

MEDIA$CHK:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	LDS	BX,[PTRSAV]
ASSUME	DS:NOTHING
	MOV	[BX.MCH_RETVAL],1	; ALWAYS NOT CHANGED
	JMP	DEVEXIT

;**	GET$BPB - Device Driver Build BPB routine
;
;	RAMDRIVE Build BPB routine. Returns pointer to BPB at RDRIVEBPB
;
;	SEE ALSO
;	  MS-DOS Technical Reference manual section on
;	  Installable Device Drivers
;
;	ENTRY from RAM$IN
;	EXIT through DEVEXIT
;	USES DS,BX
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

GET$BPB:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	LDS	BX,[PTRSAV]
ASSUME	DS:NOTHING
	MOV	WORD PTR [BX.BPB_BPB],OFFSET RDRIVEBPB
	MOV	WORD PTR [BX.BPB_BPB + 2],CS
	JMP	DEVEXIT

;**	RAM$REM - Device Driver Removable Media routine
;
;	RAMDRIVE Removable Media routine. ALWAYS returns media not removable
;	NOTE: This routine is never called if running on DOS 2.X
;
;	SEE ALSO
;	  MS-DOS Technical Reference manual section on
;	  Installable Device Drivers
;
;	ENTRY from RAM$IN
;	EXIT through ERR1
;	USES AX
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

RAM$REM:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	MOV	AX,STBUI + STDON	; Media NOT removable
	JMP	ERR1

;**	RAM$READ - Device Driver READ routine
;
;	RAMDRIVE READ routine. Perform device READ by calling MEMIO
;
;	SEE ALSO
;	  MS-DOS Technical Reference manual section on
;	  Installable Device Drivers
;
;	DO_OP entry point used by RAM$WRITE
;
;	ENTRY from RAM$IN
;		ES:DI is transfer address
;		CX is sector transfer count
;		DX is start sector number
;	EXIT through DEVEXIT or ERR$CNT
;	USES ALL
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

RAM$READ:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	XOR	BH,BH
DO_OP:
	CALL	MEMIO
	JC	T_ERR
	JMP	DEVEXIT

T_ERR:					; AL has error number
	JMP	ERR$CNT

;**	RAM$WRITE - Device Driver WRITE routine
;
;	RAMDRIVE WRITE routine. Perform device WRITE by calling MEMIO
;
;	SEE ALSO
;	  MS-DOS Technical Reference manual section on
;	  Installable Device Drivers
;
;	ENTRY from RAM$IN
;		ES:DI is transfer address
;		CX is sector transfer count
;		DX is start sector number
;	EXIT Jump to DO_OP to call MEMIO with BH = 1 (WRITE)
;	USES BH
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

RAM$WRIT:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	MOV	BH,1
	JMP	DO_OP

;**	MEMIO - Perform READ or WRITE to RAMDrive
;
;	This routine performs common pre-amble code for the BLKMOV
;	routine which is the one which does the real work. It checks
;	the I/O parameters for validity and sets up the inputs to
;	BLKMOV. What it does is convert the sector count in CX to
;	the number of words in that many sectors or 8000H which ever
;	is less. It also converts the start sector number in DX into
;	a 32 bit byte offset equal to that many sectors.
;
;	NOTE that we convert the number of sectors to transfer
;	to a number of words to transfer.
;		Sector size is always a power of two, therefore a multiple
;			of two so there are no "half word" problems.
;		DOS NEVER asks for a transfer larger than 64K bytes except
;			in one case where we can ignore the extra anyway.
;
;	ENTRY:
;	    ES:DI is packet transfer address.
;	    CX is number of sectors to transfer.
;	    DX is starting sector number
;	    BH is 1 for WRITE, 0 for READ
;	EXIT:
;	    If error detected
;		Carry Set
;			Error on operation, AL is error number
;	    else
;		through BLKMOV
;		    ES:DI is packet transfer address.
;		    CX is number of words to transfer.
;		    DX:AX is 32 bit start byte offset (0 = sector 0 of RAMDrive drive)
;		    BH is 1 for WRITE, 0 for READ
;	USES:
;	    AX, DX, CX, FLAGS
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

SEC_NOT_FOUND:
	MOV	AL,8			; Sector not found error
	STC
	RET

MEMIO:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	CMP	DX,[SECLIM]		; Check for valid I/O
	JAE	SEC_NOT_FOUND		; Start is beyond end
	MOV	AX,DX
	ADD	AX,CX
	CMP	AX,[SECLIM]
	JA	SEC_NOT_FOUND		; End is beyond end
    ;
    ; Convert sector count to word count
    ;
	MOV	AX,CX
	MOV	CL,[SEC_SHFT]
	SHL	AX,CL			; AX is # words to move
	JNC	CNT_SET 		; Overflow???
	MOV	AX,8000H		; Limit to 64K bytes
CNT_SET:
	MOV	CX,AX
    ;
    ; Now compute start offset of I/O
    ;
	MOV	AX,DX
	MUL	[SSIZE] 		; DX:AX is byte offset of start
	JMP	BLKMOV			; Perform I/O

BREAK	<Work Area for Ramdrive>

S5_FLAG 	DB	0	;; S_OLIVETTI means 6300 PLUS machine
				;; S_VECTRA means Vectra machine

A20On	dw	0DF90h
A20Off	dw	0DD00h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Unfortunately the code in ramdrive is very machine dependent
; necessitating the use of a system flag to store the machine
; configuration. The system flag is initialised during init time
; and used when the caching services are requested. One bit which
; is set and tested during caching is the state of the a20 line
; when the cache code is entered. This is used because there are
; applications which enable the a20 line and leave it enabled 
; throughout the duration of execution.  Since ramdrive is a device
; driver it shouldn't change the state of the environment.
;
; The system flag bit assignments are:
;
;	-------------------------------------------------
;	|  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |
;	-------------------------------------------------
;	   |-----|     |     |	   |	 |     |     |
;	      |        |     |	   |	 |     |     -----286 (and AT)
;	      |        |     |	   |	 |     -----------386 (later than B0)
;	     not       |     |	   |	 -----------------PS/2 machine
;	    used       |     |	   -----------------------Olivetti (not used)
;		       |     -----------------------------A20 state (enabled ?)
;		       -----------------------------------DOS 3.x >= 3.3

; The Olivetti guys have defined a flag of their own. This should be removed
; and the bit assigned out here for them should be used. 
;
sys_flg	db	?
;
;	equates used for the system flag
;
M_286	equ	00000001B
M_386	equ	00000010B
M_PS2	equ	00000100B
M_OLI	equ	00001000B
A20_ST	equ	00010000B
DOS_33	equ	00100000B
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; A20 address line state determination addresses
;
low_mem label	dword
	dw	20h*4
	dw	0

high_mem label	dword
	dw	20h*4 + 10h
	dw	0ffffh

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; A20 PS2 equates
;
PS2_PORTA   equ 0092h
GATE_A20    equ 010b

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   386 working areas
start_gdt	label	byte
nul_des desc	<>
cs_des	desc	<0FFFFh,0,0,09Fh,0,0>
ss_des	desc	<0FFFFh,0,0,093h,0,0>
ds_des	desc	<0FFFFh,0,0,093h,0,0>
es_des	desc	<0FFFFh,0,0,093h,0,0>
end_gdt 	label	byte

emm_gdt gdt_descriptor <end_gdt-start_gdt,0,0>
;
;   int 15 gdt
;
int15_gdt   label   byte
	    desc    <>	    ;dummy descriptor
	    desc    <>	    ;descriptor for gdt itself
src	    desc    <0ffffh,,,93h,,>
tgt	    desc    <0ffffh,,,93h,,>
	    desc    <>			;bios cs descriptor
	    desc    <>			;stack segment descriptor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BREAK	<Drive code for /E driver>

;
; The following label defines the start of the I/O code which is driver type
; specific.
;
; THE TYPE 2 driver must REPLACE this code with code appropriate
;	to the driver type.
;
		EVEN		; Force start of drive code to word boundary

DRIVE_CODE	LABEL	WORD

EXTMEM_LOW	EQU	0000H	; 24 bit addr of start of extended memory
EXTMEM_HIGH	EQU	0010H

;**	BASE_ADDR data element
;
; The next value defines the 24 bit address of the start of the memory for
;  the cache. It is equal to the EMM_BASE value in the
;  EMM_REC structure for the cache.
;
;  NOTE THAT IT IS INITIALIZED TO THE START OF EXTENDED MEMORY. This is
;  because BLKMOV is used to read the EMM_CTRL sector during initialization
;  of a TYPE 1 driver.
;
; NOTE: This data element is shared by TYPE 1, 2 drivers, but
;	its meaning and correct initial value are driver type specific.
;

;; NOTE: The value at BASE_ADDR is patched during initialization when
;;	 loading a RAMDrive into upper extended memory on a PLUS
;;
BASE_ADDR	LABEL	DWORD	; 24 bit address of start of this RAMDRV
		DW	EXTMEM_LOW
		DW	EXTMEM_HIGH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;**	BLKMOV - Perform transfer for TYPE 1 driver
;
;	This routine is the transfer routine for moving bytes
;	to and from the AT extended memory in real mode using
;	the LOADALL instruction. The LOADALL instruction is used
;	to set up a segment descriptor which has a 24 bit address.
;	During the time the LOADALL 24 bit segment descriptor is
;	in effect we must have interrupts disabled. If a real mode
;	8086 interrupt handler was given control it might perform
;	a segment register operation which would destroy the special
;	segment descriptor set up by LOADALL. This is prevented by
;	doing a CLI during the "LOADALL time".
;
;	WARNING NUMBER ONE:
;	    THIS CODE WILL NOT WORK ON ANY 80286 MACHINE WHERE THE NMI
;	    INTERRUPT IS ANYTHING BUT A FATAL, SYSTEM HALTING ERROR.
;
;	Since it is bad to leave interrupts disabled for a long
;	time, the I/O is performed 256 words at a time enabling
;	interrupts between each 256 word piece. This keeps the time
;	interrupts are disabled down to a reasonable figure in the 100mSec
;	range.
;
;	To use the LOADALL instruction 102 bytes at location 80:0 must
;	be used. INT13 copies the contents of 80:0 into its own buffer,
;	copies in the LOADALL info, performs the LOADALL, and then copies
;	back the previous contents of 80:0. These operations are all
;	performed during the time interrupts are disabled for each 256 word
;	block. This must be done with interrupts disabled because this area
;	on DOS 2.X and 3.X contains variable BIOS data.
;
;	In order to gain full 24 bit addressing it is also required
;	that address line 20 be enabled. This effects 8086 compatibility
;	on 80286 systems. This code leaves address line 20 enabled
;	for the ENTIRE duration of the I/O because it is too time
;	expensive to disable/enable it for each 256 word block.
;
;	WARNING NUMBER TWO:
;	    IF A MULTITASKING PRE-EMPTIVE SYSTEM SCHEDULES AND RUNS
;	    AN APPLICATION WHICH RELIES ON THE 1 MEG ADDRESS WRAP
;	    PROPERTY OF THE 8086 AND 8088 DURING THE TIME INT13
;	    IS IN THE MIDDLE OF DOING AN I/O WITH ADDRESS LINE 20 ENABLED,
;	    THE APPLICATION WILL NOT RUN PROPERLY AND MAY DESTRUCT THE
;	    INT13 MEMORY.
;
;	METHOD:
;	    Perform various LOADALL setup operations
;	    Enable address line 20
;	    While there is I/O to perform
;		Do "per 256 word block" LOADALL setup operations
;		Set up copy of 80:0 to INT13 buffer
;		CLI
;		copy 80:0 to INT13 buffer
;		copy LOADALL info to 80:0
;		LOADALL
;		do 256 word transfer
;		copy INT13 80:0 buffer back to 80:0
;		STI
;	    Disable address line 20
;
;	SEE ALSO
;	    INTEL special documentation of LOADALL instruction
;
;	ENTRY:
;	    ES:DI is packet transfer address.
;	    CX is number of words to transfer.
;	    DX:AX is 32 bit start byte offset (0 = start of cache)
;	    BH is 1 for WRITE, 0 for READ
;
;	    BASE_ADDR set to point to start of cache memory
;		This "input" is not the responsibility of the caller. It
;		is up to the initialization code to set it up when the
;		device is installed
;
;	EXIT:
;	    Carry Clear
;		    OK, operation performed successfully
;	    Carry Set
;		    Error during operation, AL is error number (INT 13 error)
;
;	USES:
;	    ALL
;
;	This routine is specific to TYPE 1 driver
;
;	sunilp - incorporated blkmov_386 (thanks to gregh)
;		 incorporated loadall_286 trick (thanks to scottra)
;		 added new a20 functionality
;		 ideally the code should be all relocatable abd the 386
;		 blkmov should be relocated on the 286 blkmov for the
;		 386 case. Also the A20 routines for the Olivetti or PS/2
;		 should also ideally be relocated on top of the normal A20

BLKMOV:
ASSUME	DS:ramcode,ES:NOTHING,SS:NOTHING
	test	[sys_flg],M_386
	je     blkmov_286
	jmp	blkmov_386
    ;
    ; Compute 32 bit address of start of I/O
    ;
blkmov_286:
	ADD	AX,WORD PTR [BASE_ADDR]
	ADC	DX,WORD PTR [BASE_ADDR + 2]
    ;
    ; Dispatch on function
    ;
	OR	BH,BH
	JZ	READ_IT
    ;
    ; Write
    ;
	MOV	WORD PTR [ESDES.SEG_BASE],AX
	MOV	BYTE PTR [ESDES.SEG_BASE + 2],DL
;	 MOV	 [LSI],DI
	mov	[lbx],di	;sp
	MOV	[LDI],0
	MOV	SI,OFFSET DSDES
	JMP	SHORT SET_TRANS

READ_IT:
	MOV	WORD PTR [DSDES.SEG_BASE],AX
	MOV	BYTE PTR [DSDES.SEG_BASE + 2],DL
	MOV	[LDI],DI
;	 MOV	 [LSI],0	   ;sp
	mov	[lbx],0
	MOV	SI,OFFSET ESDES
SET_TRANS:
	MOV	AX,ES
	CALL	SEG_SET 		; Set ES or DS segreg
    ;
    ; Set stack descriptor
    ;
	MOV	AX,SS
	MOV	[LSSS],AX
	MOV	SI,OFFSET SSDES
	CALL	SEG_SET
	MOV	[LSP],SP
;	 SUB	 [LSP],2		 ; CX is on stack at LOADALL
;
;	the loadall kludge
;
	mov	ax,cs			;sp
	inc	ax			;sp
	mov	[lcss],ax		;sp
	mov	si,offset CSDES 	;sp
	mov	ax,cs			;sp
	call	seg_set 		;sp
    ;
    ; Set Other LOADALL stuff
    ;
	SMSW	[LDSW]
	SIDT	FWORD PTR [IDTDES]
	SGDT	FWORD PTR [GDTDES]
    ;
    ; NOW The damn SXXX instructions store the desriptors in a
    ;	  different order than LOADALL wants
    ;
	MOV	SI,OFFSET IDTDES
	CALL	FIX_DESCRIPTOR
	MOV	SI,OFFSET GDTDES
	CALL	FIX_DESCRIPTOR
    ;
    ; Enable address line 20
    ;

;;
;; Enable address line 20 on the PC AT or activate A20-A23 on the 6300 PLUS.
;; The former can be done by placing 0dfh in AH and activating the keyboard
;; processor.  On the PLUS, 90h goes in AL and the port at 03f20h is written.
;; So the combined value of 0df90h can be used for both machines with
;; appropriate coding of the called routine A20.
;;

;;	MOV	AH,0DFH
	mov	ax,cs:[A20On]		;; set up for PLUS or AT
	CALL	A20
	Jc	NR_ERR
;	 JMP	 SHORT IO_START 	;sp
	jmp	short move_main_loop	;sp

NR_ERR:
	MOV	AL,02			; Drive not ready error
	STC
	RET
io_donej:   jmp io_done
;IOLOOP:				;sp
;	 PUSH	 CX			;sp

move_main_loop: 			;sp
assume ds:nothing			;sp
	jcxz	io_donej		;sp
	mov	cs:[ldx],cx		   ;sp
	MOV	AX,80H
	MOV	DS,AX
	PUSH	CS
	POP	ES
	XOR	SI,SI
	MOV	DI,OFFSET cs:[SWAP_80]
	MOV	CX,102/2
	mov	cs:[ssSave],ss
	CLD
	CLI				; Un interruptable
	test	[sys_flg],dos_33	; is it dos 3.3 or above
	jne	mml$1			; if so we don't need to store contents
					; of 80:0
	REP	MOVSW			; Save contents of 80:0
mml$1:
	PUSH	DS
	PUSH	ES
	POP	DS
	POP	ES
	XOR	DI,DI
	MOV	SI,OFFSET cs:LOADALL_TBL
	MOV	CX,102/2
	REP	MOVSW			; Transfer in LOADALL info
	 DW	 050FH			 ; LOADALL INSTRUCTION
AFTER_LOADALL:
; set up stack for moving 80:0 information back again
;
	xor	bp,bp
	mov	ss,ax
	mov	si,offset cs:[swap_80]
	mov	cx,102/2
	test	[sys_flg],dos_33
	jne	mml$2
move_loop:
	lods	word ptr cs:[si]
	mov	ss:[bp],ax
	inc	bp
	inc	bp
	loop	move_loop
mml$2:
	mov	ss,cs:[ssSave]
	mov	cx,dx
	mov	si,bx
;critical code
	sti
	rep	movsw
	cli		    ; bugfix sunilp
	mov	ax,cs
	dec	ax
	push	ax
	mov	ax,offset    io_done
	push	ax
	db	0cbh
;
	db	16 dup (0fah) ; bugfix sunilp
	mov	ax,cs
	dec	ax
	push	ax
	mov	ax,offset    resume_int
	push	ax
	db	0cbh
;
resume_int:
	mov	cs:[ldi],di
	mov	cs:[lbx],si
	jmp	move_main_loop

;	 REP	 MOVSW			 ; Move data
;IO_START:
;	 JCXZ	 IODN
;	 MOV	 WORD PTR [LCX],256	 ; ASSUME full block
;	 SUB	 CX,256
;	 JNC	 IOLOOP 		 ; OK
;	 ADD	 [LCX],CX		 ; OOPs, partial block
;	 XOR	 CX,CX			 ; This is the last block
;	 JMP	 IOLOOP

;IODN:
io_done:
	sti				; bugfix sunilp
	MOV	CX,800H 		; Retry this many times
OFFLP:

;;
;; Reset of line A20 on the PC AT requires writing 0ddh to the keyboard
;; processor.  On the PLUS, the appropriate value is 00.
;;

;;	MOV	AH,0DDH
	mov	ax,cs:[A20Off]	;; setup for PLUS or AT. ah for IBM, al for PLUS
	CALL	A20		; Disable address line 20
	jnc	dis_done
	LOOP	OFFLP
dis_done:
	CLC
	RET

;**	A20 - ENABLE/DISABLE ADDRESS LINE 20 ON IBM PC-AT
;
;	This routine enables/disables address line 20 by twiddling bits
;	in one of the keyboard controller registers.
;
;	SEE ALSO
;	    IBM Technical Reference Personal Computer AT Manual #1502243
;		Page 5-155
;
;	ENTRY
;	    AH = 0DDH to disable A20
;	    AH = 0DFH to enable A20
;	EXIT
;	    CY Failed
;	    NC Succeeded
;	USES
;	    AL, FLAGS
;
; WARNING If this routine is called in a CLI state this routine has
;	the side effect of enabling interrupts.
;
;	This routine is specific to TYPE 1 driver
;

A20:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
;; CS override needed on S5_FLAG to avoid phase errors on
;; forward declaration of this variable.
	cmp	cs:[S5_FLAG],S_OLIVETTI ;; test for 6300 PLUS
	jne    test_vec 	       ;; yes, do this code
	jmp	a20s5
test_vec:
	cmp	cs:[S5_FLAG],S_VECTRA
	jne	test_ps2
	jmp	VecA20
test_ps2:
	test	cs:[sys_flg],M_PS2	; is it a ps2 machine
	jne	a20ps2			 ; if yes it has separate a20 routine
old_a20:
	CLI
	call	check_a20		; check to see if it can be enb /disb
	jc	a20suc		       ; no it may not be toggled
	CALL	E_8042
	JNZ	a20err
	MOV	AL,0D1H
	OUT	64H,AL
	CALL	E_8042
	JNZ	a20err
	MOV	AL,AH
	OUT	60H,AL
	CALL	E_8042
	JNZ	a20err
    ;
    ;	We must wait for the a20 line to settle down, which (on an AT)
    ;	 may not happen until up to 20 usec after the 8042 has accepted
    ;	 the command.  We make use of the fact that the 8042 will not
    ;	 accept another command until it is finished with the last one.
    ;	 The 0FFh command does a NULL 'Pulse Output Port'.  Total execution
    ;	 time is on the order of 30 usec, easily satisfying the IBM 8042
    ;	 settling requirement.	(Thanks, CW!)
    ;
	mov	al,0FFh 		;* Pulse Output Port (pulse no lines)
	out	64H,al			;* send cmd to 8042
	CALL	E_8042			;* wait for 8042 to accept cmd
	jnz	A20Err

A20Suc: sti
	clc
	RET
A20Err: sti
	stc
	ret
;
; Helper routine for A20. It waits for the keyboard controller to be "ready".
;
E_8042:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSH	CX
	XOR	CX,CX
E_LOOP:
	IN	AL,64H
	AND	AL,2
	LOOPNZ	E_LOOP
	POP	CX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	A20 status checking. If request is to enable a20 we must check to
;	see if it is already enabled. If so we just set the sys_flg to
;	indicate this. On disabling the routine checks to see if disabling
;	is allowed
;
check_a20:
assume ds:nothing,es:nothing,ss:nothing
	cmp	ah,0ddh     ; is it a disable operation
	jne	check_a20_enable
;
;   check if a20 disabling allowed
;
	test	cs:[sys_flg],a20_st
	jne	no_toggle
toggle: clc
	ret
;
;   a20 enabling, check if allowed
;
check_a20_enable:
	and	cs:[sys_flg], not A20_ST
	push	cx
	push	ds
	push	si
	push	es
	push	di
	lds	si,cs:low_mem
	les	di,cs:high_mem
	mov	cx,3
	cld
repe	cmpsw
	pop	di
	pop	es
	pop	si
	pop	ds
	jcxz	not_enabled
	pop	cx
	or	cs:[sys_flg],A20_ST
no_toggle:
	stc
	ret
not_enabled:
	pop	cx
	clc
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; A20 routine for PS2s. The PS2 A20 hardware has shifted and toggling
; a bit in the system port is all that is required.
A20PS2:
assume	ds:nothing,es:nothing,ss:nothing
	cli
;
;   first separate disable operation from enable operation
;
	cmp	ah,0ddh
	je	disbl_PS2
;
;   enabling the a20
;
	and	cs:[sys_flg],not A20_ST
	in	al,PS2_PORTA	; input a20 status
	test	al,GATE_A20	; is the a20 line set
	je	set_it		;
	or	cs:[sys_flg],A20_ST ; indicate that it was already set
ps2a20suc:
	clc
	sti
	ret

set_it: push	cx
	xor	cx,cx
	or	al,GATE_A20
	out	PS2_PORTA,al	; set it
see_agn:
	in	al,PS2_PORTA	; read status again
	test	al,GATE_A20
	loopz	see_agn
	pop	cx
	jz	ps2err
	clc
	sti
	ret
;
;	disabling the ps2
;
disbl_PS2:
	test	cs:[sys_flg],A20_ST
	jne	ps2a20suc
;
	push	cx
	xor	cx,cx
	in	al,PS2_PORTA
	and	al,not GATE_A20
	out	PS2_PORTA,al
see_agn1:
	in	al,PS2_PORTA
	test	al,GATE_A20
	loopnz	see_agn1
	pop	cx
	jnz	ps2err
	clc
	sti
	ret
;
ps2err:
	stc
	sti
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;*	VECA20 - Address enable/disable routine for Vectra family computers
;;
;;	This routine does the same function as A20 for Vectra machines.
;;	Vectra machines require writing single byte as opposed to
;;	double byte commands to the 8041.  This is due to a bug
;;	in older versions in the Vectra 8041 controllers.  IBM
;;	machines must use double byte commands due to lack of
;;	implementation of single byte commands in some of their machines.
;;
;;	Uses	al, flags
;;	Has same results as A20
;;
VecA20:
	CLI
	call	check_a20
	jc	VecA20Suc
	call	E_8042
	jnz	VecA20Err
	mov	al,ah			;sigle byte command is code passed
	out	64H,al
	call	E_8042
	jnz	VecA20Err
;
;	See A20 for a description of the following code.  It simply makes
;	sure that the previous command has been completed. We cannot
;	pulse the command reg since there is a bug in some Vectra 8041s
;	instead we write the command again knowing that when the second
;	command is accepted the first was already processed.
	mov	al,ah			; send command again
	out	64H,al
	call	E_8042
	jnz	VecA20Err
VecA20Suc:
	sti
	clc
	ret
VecA20Err:
	sti
	stc
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;*	A20S5 - Address enable/disable routine for the 6300 PLUS.
;;
;;	This routine enables lines A20-A23 on the PLUS by writing
;;	to port 03f20h.  Bit 7 turns the lines on, and bit 4 sets
;;	the power-up bit.  To disable the lines, the processor
;;	must be reset.  This is done by saving the world and 
;;	jumping to the ROM 80286 reset code.  Since the power-up bit
;;	is set, the data segment is set to the BiosSeg at 40h
;;	and a jump is then made to the address at RealLoc1.  
;;	At RealLoc1, one can find the CS:IP where the code
;;	is to continue.
;;	 
;;	Uses ax, flags.
;;	Returns with zero flag set.
;;
A20S5:
;	test	[reboot_flg],0ffh	;; sunilp
;	jne	a20s5boot		;; sunilp
	cli
	or	al,al			;; if zero, then resetting processor
	jnz	A20S5Next
	call	RSet			;; must return with entry value of ax
A20S5Next:
	push	dx			;; set/reset port
	mov	dx,3f20h
	out	dx,al
	pop	dx
	clc				;; sunilp modification cy flag now important
        STI
        RET

;;* a20S5BOOT -	This code bypasses the processor reset on a reboot
;;		of the 6300 PLUS.  Otherwise the machine hangs.
a20s5BOOT:				;; use this code before reboot
	cli
	jmp short a20s5next

OldStackSeg	dw	0		;; used during PLUS processor reset
					;; to save the stack segment

;;* Rset -	Reset the 80286 in order to turn off the address lines
;;		on the 6300 PLUS.  Only way to do this on the
;;		current hardware.  The processor itself can be
;;		reset by reading or writing prot 03f00h
;;
;;  Uses flags.
;;
RSet:
	pusha				;; save world
	push	ds			;; save segments
	push	es
	mov	ax,BiosSeg		;; point to the bios segment
	mov	ds,ax			;; ds -> 40h
assume	ds:BiosSeg
	push	word ptr [RealLoc1]	;; save what might have been here
	push	word ptr [RealLoc1+2]
	mov	word ptr [RealLoc1],cs:[offset ReturnBack] ;; load our return address
	mov	word ptr [RealLoc1+2],cs
assume ds:nothing
	mov	[OldStackSeg],ss	;; save the stack segment, too
	mov	dx,03f00h		;; reset the processor
	in	ax,dx
	nop				
	nop
	nop
	cli
	hlt				;; should never get here
ReturnBack:
	mov	ss,[OldStackSeg]	;; start the recovery
assume ds:BiosSeg
	pop	word ptr [RealLoc1+2]
	pop	word ptr [RealLoc1]
	pop	es
	pop	ds
	popa
	ret		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
blkmov_386:	    ;_protect:
assume	ds:ramcode,es:nothing,ss:nothing
;
; Compute 32 bit address of start of I/O
;
	add	ax,word ptr [base_addr]
	adc	dx,word ptr [base_addr + 2]
;
	push	cx
;
; Are we in virtual mode
;
	smsw	cx
	test	cx,01B		; is the pe bit set
	je	pr_mode_tran

       jmp     int_15_tran
;
; Dispatch on function
;
pr_mode_tran:
	or	bh,bh
	jz	read_it_1
;
; Write
;
; Update ES descriptor with address of track in cache
;
	mov	si,offset es_des
	mov	[si].bas_0_15,ax
	mov	[si].bas_16_23,dl
	mov	[si].bas_24_31,dh
;
; Update DS descriptor with transfer address
;
	mov	ax,es
	mov	cx,16
	mul	cx
	mov	si,offset ds_des
	mov	[si].bas_0_15,ax
	mov	[si].bas_16_23,dl
	mov	[si].bas_24_31,dh


; Switch SI and DI for write transfer

	mov	si,di
	xor	di,di

	jmp	short set_trans_1

read_it_1:
;
; Update DS descriptor with address of track in cache
;
	mov	si,offset ds_des
	mov	[si].bas_0_15,ax
	mov	[si].bas_16_23,dl
	mov	[si].bas_24_31,dh
;
; Update ES descriptor with transfer address
;
	mov	ax,es
	mov	cx,16
	mul	cx
	mov	si,offset es_des
	mov	[si].bas_0_15,ax
	mov	[si].bas_16_23,dl
	mov	[si].bas_24_31,dh
;
; Keep SI and DI the same for read transfer
;
	xor	si,si

set_trans_1:
;
; Restore Transfer Count
;
	pop	cx

;
	mov	ax,cs:[A20On]
	call	A20
	jc	nr_err_1
;
;	we shall do the transfer 1024 words at a time
;
	db	66h
	push	ax
	mov	bx,cx
assume ds:nothing
pr_io_agn_1:
	mov	cx,1024
	cmp	bx,cx
	ja	pr_strt_1
	mov	cx,bx
pr_strt_1:
	sub	bx,cx
	cli		; Un interruptable
	cld
	lgdt	fword ptr emm_gdt


;
; Switch to protected mode
;
	db	66h,0Fh, 20h, 0 	    ;mov     eax,cr0
	or	ax,1
	db	66h,0Fh,22h, 0		    ;mov     cr0,eax
;
; Clear prefetch queue
;
	db	0eah		; far jump
	dw	offset flush_prefetch
	dw	cs_des - start_gdt	
;
flush_prefetch:
	assume	cs:nothing
;
; Initialize segment registers
;
	mov	ax,ds_des - start_gdt
	mov	ds,ax
	assume	ds:nothing
	mov	ax,es_des - start_gdt
	mov	es,ax
	assume	es:nothing
	shr	cx,1			; convert word count into dword count
	db	0f3h,066h,0a5h		; rep movsd
;	rep	movsw			; Move data
;
;
; Return to Real Mode
;
;
	db	66h,0Fh, 20h, 0 	    ; mov     eax,cr0
	and	ax,0FFFEh
	db	66h,0Fh, 22h, 0 	    ; mov     cr0,eax
;
; Flush Prefetch Queue
;
	db	0EAh			; Far jump
	dw	offset flushcs
cod_seg dw	?			; Fixed up at initialization time
	assume	cs:ramcode
flushcs:
;
	sti
;  see if transfer done else go to do next block
;
	or	bx,bx
	jne	pr_io_agn_1
;
	db	66h
	pop	ax
	mov	ax,cs
	mov	es,ax
	assume	es:nothing
	mov	ds,ax
	assume	ds:ramcode

	mov	cx,800h 		; Retry this many times
offlp_1:
	mov	ax,cs:[A20Off]
	call	A20			; Disable address line 20
	jnc	offlp1_out
	loop	offlp_1
offlp1_out:
	clc
	ret

nr_err_1:

	mov	al,02			; Drive not ready error
	stc
	ret
;
int_15_tran:
assume	ds:ramcode,es:nothing,ss:nothing
	or	bh,bh
	jz	read_it_2
;
; Write
;
; Update tgt descriptor with address of track in cache
;
	mov	si,offset tgt
	mov	[si].bas_0_15,ax
	mov	[si].bas_16_23,dl
	mov	[si].bas_24_31,dh
;
; Update src descriptor with transfer address
;
	mov	ax,es
	mov	cx,16
	mul	cx
	add	ax,di
	adc	dx,0
	mov	si,offset src
	mov	[si].bas_0_15,ax
	mov	[si].bas_16_23,dl
	mov	[si].bas_24_31,dh
;
	jmp	short set_trans_2

read_it_2:
;
; Update src descriptor with address of track in cache
;
	mov	si,offset src
	mov	[si].bas_0_15,ax
	mov	[si].bas_16_23,dl
	mov	[si].bas_24_31,dh
;
; Update tgt descriptor with transfer address
;
	mov	ax,es
	mov	cx,16
	mul	cx
	add	ax,di
	adc	dx,0
	mov	si,offset tgt
	mov	[si].bas_0_15,ax
	mov	[si].bas_16_23,dl
	mov	[si].bas_24_31,dh
;
set_trans_2:
;
; Restore Transfer Count
;
	pop	bx

;
;	we shall do the transfer 1024 words at a time
;
pr_io_agn_2:
	mov	cx,1024
	cmp	bx,cx
	ja	pr_strt_2
	mov	cx,bx
pr_strt_2:
	sub	bx,cx
	push	cs
	pop	es
	mov	si,offset int15_gdt
	mov	ax,emm_blkm shl 8
	int	emm_int
	jc	nr_err_1
;
;
;  see if transfer done else fo to do next block
;
	or	bx,bx
	je	io_exit
;
	add	[src.bas_0_15],2048
	adc	[src.bas_16_23],0
	adc	[src.bas_24_31],0
;
	add	[tgt.bas_0_15],2048
	adc	[tgt.bas_16_23],0
	adc	[tgt.bas_24_31],0
;
	jmp	pr_io_agn_2
io_exit:
	clc
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;**	SEG_SET - Set up a LOADALL segment descriptor as in REAL mode
;
;	This routine sets the BASE value in the segment descriptor
;	pointed to by DS:SI with the segment value in AX as the 80286
;	does in REAL mode. This routine is used to set a descriptor
;	which DOES NOT have an extended 24 bit address.
;
;	SEE ALSO
;	    INTEL special documentation of LOADALL instruction
;
;	ENTRY:
;	      DS:SI -> Seg register descriptor
;	      AX is seg register value
;	EXIT:
;	      NONE
;	USES:
;	      AX
;
;	This routine is specific to TYPE 1 driver
;

SEG_SET:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSH	DX
	PUSH	CX
	MOV	CX,16
	MUL	CX	; Believe or not, this is faster than a 32 bit SHIFT
	MOV	WORD PTR [SI.SEG_BASE],AX
	MOV	BYTE PTR [SI.SEG_BASE + 2],DL
	POP	CX
	POP	DX
	RET

;**	FIX_DESCRIPTOR - Shuffle GTD IDT descriptors
;
;	The segment descriptors for the IDT and GDT are stored
;	by the SIDT instruction in a slightly different format
;	than the LOADALL instruction wants them. This routine
;	performs the transformation by PUSHing the contents
;	of the descriptor, and then POPing them in a different
;	order.
;
;	SEE ALSO
;	    INTEL special documentation of LOADALL instruction
;	    INTEL 80286 processor handbook description of SIDT instruction
;
;	ENTRY:
;	    DS:SI points to IDT or GDT descriptor in SIDT form
;	EXIT:
;	    DS:SI points to IDT or GDT descriptor in LOADALL form
;	USES:
;	    6 words of stack
;
;	NOTE: The transformation is reversable, so this routine
;		will also work to transform a descriptor in LOADALL
;		format to one in SIDT format.
;
;	Specific to TYPE 1 driver
;

FIX_DESCRIPTOR:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSH	WORD PTR [SI + 4]
	PUSH	WORD PTR [SI + 2]
	PUSH	WORD PTR [SI]
	POP	WORD PTR [SI + 4]
	POP	WORD PTR [SI]
	POP	WORD PTR [SI + 2]
	RET

;**	DATA SPECIFIC TO THE LOADALL INSTRUCTION USAGE
;
;	SWAP_80 and LOADALL_TBL are data elements specific to the use
;	of the LOADALL instruction by TYPE 1 drivers.
;

;
; Swap buffer for contents of 80:0
;
	EVEN		; Force word alignment of SWAP_80 and LOADALL_TBL

SWAP_80 DB	102 DUP(?)
ssSave	dw	?

;
; LOADALL data buffer placed at 80:0
;
LOADALL_TBL	LABEL	BYTE
	DB	6 DUP(0)
LDSW	DW	?
	DB	14 DUP (0)
TR	DW	0
FLAGS	DW	0		; High 4 bits 0, Int off, Direction clear
				;   Trace clear. Rest don't care.
LIP	DW	OFFSET AFTER_LOADALL
LDT	DW	0
LDSS	DW	8000h
LSSS	DW	?
LCSS	DW	?
LESS	DW	?
LDI	DW	?
LSI	DW	?
LBP	DW	?
LSP	DW	?
LBX	DW	?
LDX	DW	?
LCX	DW	?
LAX	DW	80H
ESDES	SEGREG_DESCRIPTOR <>
CSDES	SEGREG_DESCRIPTOR <>
SSDES	SEGREG_DESCRIPTOR <>
DSDES	SEGREG_DESCRIPTOR <>
GDTDES	DTR_DESCRIPTOR <>
LDTDES	DTR_DESCRIPTOR <0D000H,0,0FFH,0088H>
IDTDES	DTR_DESCRIPTOR <>
TSSDES	DTR_DESCRIPTOR <0C000H,0,0FFH,0800H>

;**	TRUE LOCATION OF ABOVE_PID
;
;	Define the TRUE (runtime TYPE 2 driver) location of ABOVE_PID.
;	This is the only piece of TYPE 2 specific data that we need
;	in the resident image. We must define it HERE rather than down
;	at ABOVE_BLKMOV so that we have its TRUE location after the
;	TYPE 2 code is swapped in at initialization. If we defined
;	it down at ABOVE_BLKMOV any instruction like:
;
;		MOV	DX,[ABOVE_PID]
;
;	Would have to be "fixed up" when we moved the ABOVE_BLKMOV
;	code into its final location.
;

ABOVE_PID	EQU	WORD PTR $ - 2		; TRUE location of ABOVE_PID

;
; The following label defines the end of the region where BLKMOV code
;   may be swapped in. BLKMOV code to be swapped in MUST fit
;   between DRIVE_CODE and DRIVE_END
;
DRIVE_END	LABEL	WORD


BREAK	<BPB POINTER ARRAY>

;**	BPB pointer array data
;
; BPB pointer array returned by INIT call. Must be part of resident image.
;
;	SEE ALSO
;	  MS-DOS Technical Reference manual section on
;	  Installable Device Drivers
;

INITAB	DW	RDRIVEBPB

;
; The following label defines the end of the RAMDrive resident code
;  for cases where no INT 9/19 code is included.
;
DEVICE_END	LABEL	BYTE

BREAK	<INT 19/9/15 Handlers. Incl if FIRST driver in system or /A or new alloc>

;
; As discussed above in the documentation of the EMM_CTRL sector it
; is necessary to hear about system re-boots so that the EMM_ISDRIVER
; bits in the EMM_REC structures can be manipulated correctly.
;
; On the IBM PC family of machines there are two events which cause a
; "soft" system re-boot which we might expect the EMM_CTRL sector to
; survive through. One is software INT 19H, the other is the Ctrl-Alt-Del
; character sequence which can be detected by "listening" on INT 9 for
; it. The code below consists of a handler for INT 19H, a handler
; for INT 9, and a drive TYPE dependant piece of code.
;
; The drive TYPE dependant piece of code works as follows:
;
;	TYPE 1 uses EMM_CTRL sector so it scans the EMM_CTRL sector
;		looking for all EMM_ALLOC and EMM_MSDOS EMM_REC
;		structures and turns off the EMM_ISDRIVER bit.
;		Since this scan is GLOBAL for all EMM_MSDOS
;		marked structures we need only ONE INT 19/INT 9
;		handler even if we have more than one TYPE 1
;		RAMDrive in the system. The handler is always
;		in the FIRST TYPE 1 RAMDrive installed at boot
;		time.
;
;	TYPE 2 DOES NOT use the EMM_CTRL sector but it still has
;		a handler. What this handler does is issue an
;		ABOVE_DEALLOC call to deallocate the Above Board
;		memory allocated to the RAMDrive. In current versions
;		of the EMM device driver this step is unnecessary
;		as the EMM device driver is thrown away together
;		with all of the allocation information when the system
;		is re-booted. We do it anyway because some future version
;		of the EMM device driver may be smarter and retain
;		allocation information through a warm-boot. Currently,
;		doing this doesn't hurt anything. Since this code cannot
;		do a global ABOVE_DEALLOC for all TYPE 2 drivers in the
;		system, it does an ABOVE_DEALLOC only for its memory
;		and EACH TYPE 2 driver in the system includes the INT 19/9
;		code.
;
;	TYPE 3 uses EMM_CTRL sector so it scans the EMM_CTRL sector
;		looking for all EMM_ALLOC and EMM_MSDOS EMM_REC
;		structures and turns off the EMM_ISDRIVER bit.
;		Since this scan is GLOBAL for all EMM_MSDOS
;		marked structures we need only ONE INT 19/INT 9
;		handler even if we have more than one TYPE 3
;		RAMDrive in the system. The handler is always
;		in the FIRST TYPE 3 RAMDrive installed at boot
;		time.
;
;	TYPE 4 does not use EMM_CTRL or have any other need to hear
;		about re-boots since this type of RAMDrive CANNOT
;		live through a warm boot. So TYPE 4 drivers NEVER
;		include the INT 19/9 code.
;

;
; Storage locations for the "next" INT 19 and INT 9 vectors, the ones
;  that were in the interrupt table when the device driver was loaded.
;  They are initialized to -1 to indicate they contain no useful information.
;
OLD_19	LABEL	DWORD
	DW	-1
	DW	-1

;OLD_9	 LABEL	 DWORD
;	 DW	 -1
;	 DW	 -1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; modification to meet new memory allocation standard
OLD_15	LABEL	DWORD
	DW	-1
	DW	-1
int15_size  dw	0
;
;
INT_15:
ASSUME DS:NOTHING,SS:NOTHING,ES:NOTHING
;
;	This piece of code determines the size of extended memory
;	which was allocated before this driver and then subtracts
;	the amount it has allocated for itself
;
;	inputs: ah = 88h is of interest
;	outputs: ax = size of extended memory allocated by all before and
;		 including us
;	regs used: flags
;
	pushf
	cmp	ah,88h
	je	mem_det
	popf
	jmp	[old_15]
mem_det:
	mov	ax,[int15_size]
	popf
	clc
	sti
	iret

;**	INT 9 Keyboard handler
;
;	All this piece of code does is look for the Ctrl-Alt-Del event.
;	If key is not Ctrl-Alt-Del, it jumps to OLD_9 without doing
;	anything. If the Ctrl-Alt-Del key is detected it calls
;	RESET_SYSTEM to perform driver TYPE specific re-boot code
;	and then jumps to OLD_9 to pass on the event.
;
;	NOTE THAT UNLIKE INT 19 THIS HANDLER DOES NOT NEED TO RESET
;	THE INT 9 AND INT 19 VECTORS. This is because the Ctrl-Alt-Del
;	IBM ROM re-boot code resets these vectors.
;
;	SEE ALSO
;	    INT 9 IBM ROM code in ROM BIOS listing of
;	    IBM PC Technical Reference manual for any PC family member
;
;	ENTRY
;	    NONE
;	EXIT
;	    NONE, via OLD_9
;	USES
;	    FLAGS
;
;	THIS CODE IS USED BY TYPE 1,2 and 3 drivers.
;

;INT_9:
;ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
;	 PUSH	 AX
;	 PUSH	 DS
;	 IN	 AL,60H
;	 CMP	 AL,83			 ; DEL key?
;	 JNZ	 CHAIN			 ; No
;	 XOR	 AX,AX
;	 MOV	 DS,AX
;	 MOV	 AL,BYTE PTR DS:[417H]	 ; Get KB flag
;	 NOT	 AL
;	 TEST	 AL,0CH 		 ; Ctrl Alt?
;	 JNZ	 CHAIN			 ; No
;	 CALL	 RESET_SYSTEM		 ; Ctrl Alt DEL
;CHAIN:
;	 POP	 DS
;	 POP	 AX
;	 JMP	 [OLD_9]

;**	INT 19 Software re-boot handler
;
;	All this piece of code does is sit on INT 19 waiting for
;	a re-boot to be signaled by being called. It calls
;	RESET_SYSTEM to perform driver TYPE specific re-boot code,
;	resets the INT 19 and INT 9 vectors,
;	and then jumps to OLD_19 to pass on the event.
;
;	NOTE THAT UNLIKE INT 9 THIS HANDLER NEEDS TO RESET
;	THE INT 9 AND INT 19 VECTORS. This is because the INT 19
;	IBM ROM re-boot code DOES NOT reset these vectors, and we
;	don't want to leave them pointing to routines that are not
;	protected from getting stomped on by the re-boot.
;
;	SEE ALSO
;	    INT 19 IBM ROM code in ROM BIOS listing of
;	    IBM PC Technical Reference manual for any PC family member
;
;	ENTRY
;	    NONE
;	EXIT
;	    NONE, via OLD_19
;	USES
;	    FLAGS
;
;	THIS CODE IS USED BY TYPE 1,2 and 3 drivers.
;

INT_19:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	CALL	RESET_SYSTEM
	PUSH	AX
	PUSH	DS
	XOR	AX,AX
	MOV	DS,AX
    ;
    ; Since INT 19 DOES NOT reset any vectors (like INT 9 Ctrl Alt DEL does),
    ;	we must replace those vectors we have mucked with.
    ;
    ; NOTE THAT WE RESET VECTORS DIRECTLY!!!!!!!!!!!!!!!!!!
    ;	We are not sure that DOS is reliable enough to call.
    ;
	MOV	AX,WORD PTR [OLD_19]
	CLI
	MOV	WORD PTR DS:[19H * 4],AX
	MOV	AX,WORD PTR [OLD_19 + 2]
	MOV	WORD PTR DS:[(19H * 4) + 2],AX
;	 MOV	 AX,WORD PTR [OLD_9]
;	 MOV	 WORD PTR DS:[9H * 4],AX
;	 MOV	 AX,WORD PTR [OLD_9 + 2]
;	 MOV	 WORD PTR DS:[(9H * 4) + 2],AX
;
	mov	ax,word ptr [old_15]
	cmp	ax,word ptr [old_15+2]
	jne	res_15
	cmp	ax,-1
	je	skip_res
res_15:
	mov	word ptr ds:[15h*4],ax
	mov	ax,word ptr [old_15+2]
	mov	word ptr ds:[(15h*4) +2],ax

skip_res:
	POP	DS
	POP	AX
	JMP	[OLD_19]

;**	RESET_SYSTEM perform TYPE 1 (/E) driver specific reboot code
;
;	This code performs the EMM_ISDRIVER reset function as described
;	in EMM.ASM for all EMM_REC structures which are EMM_ALLOC and
;	EMM_ISDRIVER and of type EMM_MSDOS. We use the same LOADALL
;	method described at BLKMOV to address the EMM_CTRL sector
;	at the start of extended memory and perform our changes in
;	place.
;
;	NOTE: RESET_SYSTEM ALSO defines the start of ANOTHER piece of
;		driver TYPE specific code that TYPE 2, 3 and 4 drivers
;		will have to swap in a different piece of code for.
;
;	note: type 1 drivers allocation schemes have changed. so now
;	      only the olivetti special configuration has an emm
;	      control record. this is a 286 machine and we can stick
;	      to the code given below for that. would have preferred
;	      to give complete support here
;
;	ENTRY
;	    NONE
;	EXIT
;	    NONE
;	USES
;	    NONE
;
; This code is specific to TYPE 1 drivers
;

RESET_SYSTEM:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
;
;   this piece of code is now redundant with the new aallocation scheme.
;   for type 1 drivers we use the emm control record only in /u option
;   and for that driver this piece of code is never executed
;
;   this piece of code cannot be removed because other guys relocate
;   on top of this
;
	jmp	reset_ret
;
	PUSHA
	PUSH	DS
	PUSH	ES
	PUSH	CS
	POP	DS
ASSUME	DS:RAMCODE
    ;
    ; Set up to address EMM_CTRL sector
    ;
	MOV	[LIP],OFFSET AFTER_LDA
	MOV	WORD PTR [DSDES.SEG_BASE],EXTMEM_LOW
	MOV	BYTE PTR [DSDES.SEG_BASE + 2],EXTMEM_HIGH
	MOV	[LSI],0
	MOV	[LDI],EMM_RECORD
	MOV	[LCX],EMM_NUMREC
	MOV	SI,OFFSET ESDES
	MOV	AX,ES
	CALL	SEG_SET 		; Set ES segreg
	MOV	AX,SS
	MOV	[LSSS],AX
	MOV	SI,OFFSET SSDES
	CALL	SEG_SET 		; Set SS segreg
	MOV	[LSP],SP
ON20:
	MOV	AH,0DFH
	CALL	A20			; Enable adress 20
	CLI				; A20 STIs
	JNZ	ON20

	MOV	AX,80H
	MOV	DS,AX
ASSUME	DS:NOTHING
	PUSH	CS
	POP	ES
	XOR	SI,SI
	MOV	DI,OFFSET SWAP_80
	MOV	CX,102/2
	CLD
	CLI
	REP	MOVSW			; Transfer out 80:0
	PUSH	DS
	PUSH	ES
	POP	DS
	POP	ES
	XOR	DI,DI
	MOV	SI,OFFSET LOADALL_TBL
	MOV	CX,102/2
	REP	MOVSW			; Transfer in LOADALL info
	DW	050FH			; LOADALL INSTRUCTION
AFTER_LDA:
    ;
    ; Scan EMM_CTRL for MS-DOS ISDRIVER regions and turn off ISDRIVER
    ;

LOOK_RECY:
	TEST	[DI.EMM_FLAGS],EMM_ALLOC
	JZ	DONEY			; Hit free record, done
	TEST	[DI.EMM_FLAGS],EMM_ISDRIVER
	JZ	NEXTRECY		; No Driver
	CMP	[DI.EMM_SYSTEM],EMM_MSDOS
	JNZ	NEXTRECY		; Wrong system
	AND	[DI.EMM_FLAGS],NOT EMM_ISDRIVER     ; No longer a driver
NEXTRECY:
	ADD	DI,SIZE EMM_REC
	LOOP	LOOK_RECY
DONEY:
	MOV	ES,AX		; LOADALL puts 80H in AX
	XOR	DI,DI
	PUSH	CS
	POP	DS
ASSUME	DS:RAMCODE
	MOV	SI,OFFSET SWAP_80
	MOV	CX,102/2
	REP	MOVSW		; Restore 80:0

OFF20:
	MOV	AH,0DDH 	; Disable adress line 20
	CALL	A20
	CLI			; A20 STIs
	JNZ	OFF20
	POP	ES
	POP	DS
ASSUME	DS:NOTHING
	POPA
reset_ret:
	RET

;
; The following label performs two functions. It defines the end of the
; Driver TYPE specific RESET_SYSTEM code which will have to be replaced
; for different driver TYPEs as the code between RESET_SYSTEM and
; RESET_INCLUDE. Swapped in code MUST FIT between RESET_SYSTEM and
; RESET_INCLUDE. It also defines the end of the resident device driver
; code for a driver which wants to include the INT 19/ INT 9 code.
;
RESET_INCLUDE  LABEL   BYTE

BREAK	<COMMON INIT CODE>

;**	DISPOSABLE INIT DATA
;
; INIT data which need not be part of resident image
;

DRIVER_SEL	DB	2	; 0 if /E (TYPE 1), 1 if /A (TYPE 2),
				;    2 if resmem (TYPE 3 or 4)

DEV_SIZE	DW	64	; Size in K of this device

U_SWITCH	db	0	;; for the oliv's special config

special_mem	dw	0	;; at&t special memory

new_all 	db	0	; to indicate new allocation scheme

EXT_K		DW	?	; Size in K of Exteneded memory.

NUM_ARG 	DB	1	; Counter for order dependent numeric
				;    arguments	bbbb ssss dddd.

INIT_DRIVE	DB	1	; 0 means drive is inited
				; 1 means drive is to be inited
				;    MUST BE DEFAULT SETTING
				; 2 means drive is to be inited
				;   REGARDLESS of the existence of
				;   a valid DOS volume signature.

GOTSWITCH	DB	0	; 0 if no switch, NZ if switch seen

DIRSEC		DW	?	; Number of directory SECTORS

TERM_ADDR	LABEL	DWORD	; Address to return as break address in INIT packet
		DW	OFFSET DEVICE_END   ; INIT to NOT include INT 19/9 code
		DW	?		; RAMDrive CS filled in at INIT

TRUE_CS 	DW	?	; Used to store the "true" location of
				;   the driver when the relocation at
				;   RAMDrive_RELOC is performed.

RESMEM_SPECIAL	DB	0	; 0 means NORMAL TYPE 3 RAMDrive
				; NZ means SPECIAL TYPE 4 RESMEM version
				;   see code at RAMDrive_RELOC

VALID_EMM	db	0	;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sys_det	proc	near
;
; author:  sunilp, august 1, 1987.  thanks to rickha for most of this
; 	   routine.
;
; purpose: to determine whether extended memory cache can be installed
;	   on this system. also to determine and store in the system 
;	   flag the machine identification.
;
; inputs:  none
;
; outputs: CY set if this machine doesn't allow extended memory cache.
;	   CY clear if this machine allows extended memory cache and
;		    the system flag is set according to the machine type.
;
; registers used:  ax,es,flags
;----------------------------------
;	Clear the state of the system flag
;
assume ds:ramcode,es:nothing,ss:nothing
	xor	ax,ax			; 0000 into AX
;	 mov	 [sys_flg],al		 ; clear system flag
;----------------------------------
;	Determine if 8086/8088 system. If so we should abort immediately.
;
	push	ax			; ax has 0
	popf				; try to put that in the flags
	pushf
	pop	ax			; look at what really went into flags
	and	ax,0F000h		; mask off high flag bits
	cmp	ax,0F000h		; Q: was high nibble all ones ?
	je	cpu_err			; Y: it's an 8086 (or 8088)
;----------------------------------
;	Determine if 80286/80386 machine. 
;
	mov	ax,0F000h		;   N: try to set the high bits
	push	ax
	popf				;      ... in the flags
	pushf
	pop	ax			; look at actual flags
	and	ax,0F000h		; Q: any high bits set ?
	je	cpu_286			;   N: it's an 80286
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	It is a 386 cpu. We should next try to determine if the ROM is
;	B0 or earlier. We don't want these guys.
;
cpu_386:
      	pushf				; clear
      	pop	ax			;   NT
      	and	ax,not 0F000h		;     and
	push	ax			;       IOPL
	popf				;         bits
;----------------------------------
;	the next three instructions were removed because we are loaded
;	in real mode. So there is no need to check for virtual mode.
;
;	smsw	ax			;check for Virtual Mode
;	test	ax,0001			; Q: Currently in Virtual Mode ?
;	jnz	cpu_exit		;   Y: quit with error message
;----------------------------------
					;   N: check 386 stepping for B0
	call	is_b0			; Q: B0 ?
	jc	cpu_err 		;   Y: abort
;----------------------------------
;	We have a valid 386 guy. Set the flag to indicate this.
;
	or	[sys_flg],M_386 	; set 386 bit
	jmp	short PS2Test

;----------------------------------
;	This is a 286 guy. Check for AT model byte. We don't want non-ATs.
;	Set 286 bit if AT type. Then check for PS/2
;
cpu_286:
	mov	ax,0ffffh
	mov	es,ax
	cmp	byte ptr es:[0eh],0fch	; AT model byte
	jne	cpu_err			; if not abort
;
	or	[sys_flg],M_286		; set 286 flag bit
;
;
;	Determine if this is a PS/2 system
;
PS2Test:
	call	IsPS2Machine
	or	ax,ax
	jz	NCRTest
	or	[sys_flg],M_PS2

NCRTest:
	call	IsNCRMachine
	or	ax,ax
	jz	cpu_suc

	; We're on an NCR machine, send D7 and D5 to the 8042 in order
	; to toggle A20 instead of the DF and DD we usually send.
	; ChipA 06-16-88
	mov	cs:[A20On],0D790h
	mov	cs:[A20Off],0D500h


;----------------------------------
;	success exit:--
cpu_suc:
	clc
	ret

;----------------------------------
;	error exit:--
cpu_err:
	stc
	ret
;
sys_det endp


;*--------------------------------------------------------------------------*
;*									    *
;*  IsPS2Machine					    HARDWARE DEP.   *
;*									    *
;*	Check for PS/2 machine						    *
;*									    *
;*  ARGS:   None							    *
;*  RETS:   AX = 1 if we're on a valid PS/2 machine, 0 otherwise	    *
;*  REGS:   AX	and Flags clobbered					    *
;*									    *
;*--------------------------------------------------------------------------*

IsPS2Machine proc   near

	    mov     ax,0C300h	    ; Try to disable the Watchdog timer
	    stc
	    int     15h
	    jc	    IPMNoPS2	    ; Error?  Not a PS/2.

IPMFoundIt: mov     ax,1	    ; Return 1
	    ret

IPMNoPS2:   xor     ax,ax
	    ret

IsPS2Machine endp


;*--------------------------------------------------------------------------*
;*									    *
;*  IsNCRMachine					    HARDWARE DEP.   *
;*									    *
;*	Check for NCR machine						    *
;*									    *
;*  ARGS:   None							    *
;*  RETS:   AX = 1 if we're on a valid NCR machine, 0 otherwise 	    *
;*  REGS:   AX	and Flags clobbered					    *
;*									    *
;*--------------------------------------------------------------------------*

; Look for 'NC' at F000:FFEA

IsNCRMachine proc   near

	    mov     ax,0F000h
	    mov     es,ax
	    mov     ax,word ptr es:[0FFEAh]
	    cmp     ax,'CN'
	    je	    INMFoundIt
	    xor     ax,ax
	    ret

INMFoundIt: mov     ax,1
	    ret

IsNCRMachine endp


;******************************************************************************
;   IS_B0 - check for 386-B0
;
;   This routine takes advantage of the fact that the bit INSERT and 
;   EXTRACT instructions that existed in B0 and earlier versions of the
;   386 were removed in the B1 stepping.  When executed on the B1, INSERT 
;   and EXTRACT cause an INT 6 (invalid opcode) exception.  This routine
;   can therefore discriminate between B1/later 386s and B0/earlier 386s.
;   It is intended to be used in sequence with other checks to determine
;   processor stepping by exercising specific bugs found in specific
;   steppings of the 386.
;
;   ENTRY:  REAL MODE on 386 processor (CPU ID already performed)
;   EXIT:   CF = 0 if B1 or later
;	    CF = 1 if B0 or prior
;
;   ENTRY:  
;   EXIT:   
;   USED:   AX, flags
;   STACK:  
;------------------------------------------------------------------------------
is_b0	proc	near
	push	bx
	push	cx
	push	dx
	push	ds

	xor	bx,bx
	mov	ds,bx			; DS = 0000 (real mode IDT)
assume ds:R_Mode_IDT
	push	[bx+(6*4)]
	pop	cs:[int6_save]		; save old INT 6 offset
	push	[bx+(6*4)+2]
	pop	cs:[int6_save+2]	; save old INT 6 segment
					
	mov	word ptr [bx+(6*4)],offset int6
	mov	[bx+(6*4)+2],cs 	; set vector to new INT 6 handler
;
;   Attempt execution of Extract Bit String instruction.  Execution on
;   B0 or earlier with length (CL) = 0 will return 0 into the destination 
;   (CX in this case).  Execution on B1 or later will fail and dummy INT 6
;   handler will return execution to the instruction following the XBTS.
;   CX will remain unchanged in this case.
;
	xor	ax,ax
	mov	dx,ax
	mov	cx,0FF00h		; Extract length (CL)=0, CX=non-zero
	db	0Fh,0A6h,0CAh		; XBTS CX,DX,AX,CL
	
	xor	bx,bx
	mov	ds,bx			; DS = 0000 (real mode IDT)
	push	cs:[int6_save]		; restore original INT 6 offset
	pop	[bx+(6*4)]		;
	push	cs:[int6_save+2]	; restore original INT 6 segment
	pop	[bx+(6*4)+2]

	or	cx,cx			; Q: CX = 0 (meaning <=B0) ?
	jz	ib_exit			;   Y: exit (carry clear)
	stc				;   N: set carry to indicate >=B1
ib_exit:
	cmc				; flip carry tense
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	ret				; *** RETURN ***
is_b0	endp
;
;   Temporary INT 6 handler - assumes the cause of the exception was the 
;   attempted execution of an XTBS instruction.
;
int6	proc 	near
	push	bp
	mov	bp,sp
	add	word ptr [bp+2],3	; bump IP past faulting instruction
	pop	bp
	iret				; *** RETURN ***
int6_save	dw	0000,0000
int6	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;**	PRINT - Print a "$" terminated message on stdout
;
;	This routine prints "$" terminated messages on stdout.
;	It may be called with only the DX part of the DS:DX message
;	pointer set, the routine puts the correct value in DS to point
;	at the RAMDrive messages.
;
;	ENTRY:
;	     DX pointer to "$" terminated message (RAMCODE relative)
;	EXIT:
;	     NONE
;	USES:
;	     AX
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

PRINT:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSH	DS
	PUSH	CS
	POP	DS
	MOV	AH,Std_Con_String_Output
	INT	21H
	POP	DS
	RET

;**	ITOA - Print Decimal Integer on stdout
;
;	Print an unsigned 16 bit value as a decimal integer on stdout
;	with leading zero supression. Prints from 1 to 5 digits. Value
;	0 prints as "0".
;
;	Routine uses divide instruction and a recursive call. Maximum
;	recursion is four (five digit number) plus one word on stack
;	for each level.
;
;	ENTRY	AX has binary value to be printed
;	EXIT	NONE
;	USES	AX,CX,DX,FLAGS
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

ITOA:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

	MOV	CX,10
	XOR	DX,DX
	DIV	CX			; DX is low digit, AX is higher digits
	OR	AX,AX
	JZ	PRINT_THIS_DIGIT	; No more higher digits
	PUSH	DX			; Save this digit
	CALL	ITOA			; Print higher digits first
	POP	DX			; Recover this digit
PRINT_THIS_DIGIT:
	ADD	DL,"0"			; Convert to ASCII
	MOV	AH,Std_CON_Output
	INT	21H
	RET


;**	RAM$INIT - Device Driver Initialization routine
;
;	RAMDRIVE Initialization routine. This is the COMMON initialization
;	code used by ALL driver TYPEs. Its jobs are to:
;
;	    1.	Initialize various global values
;	    2.	Check for correct DOS version and do changes to the device
;			based on the DOS version if needed.
;	    3.	Parse the command line and set values accordingly
;	    4.	Call a TYPE specific INIT routine based on the Parse
;			to set up a specific driver TYPE.
;	    5.	Initialize the DOS volume in the RAMDrive memory if appropriate
;	    6.	Print out report of RAMDrive parameters
;	    7.	Set the return INIT I/O packet values
;
;	The first two lines perform step 1. Step two starts after and
;	goes through VER_OK. Step 3 starts at VER_OK and goes through
;	ARGS_DONE. Step 4 starts at ARGS_DONE and goes through I001.
;	Step 5 starts at I001 and goes through DRIVE_SET. Step 6 starts
;	at DRIVE_SET and goes through SETBPB. Step 7 starts at SETBPB
;	and ends at the JMP DEVEXIT 10 lines later.
;
;	At any time during the above steps an error may be detected. When
;	this happens one of the error messages is printed and RAMDrive
;	"de-installs" itself by returning a unit count of 0 in the INIT
;	device I/O packet. The DOS device installation code is responsible
;	for taking care of the details of re-claiming the memory used by
;	the device driver. All RAMDrive needs to do is make sure any INT
;	vectors it changed (INT 9 and INT 19) get restored to what they
;	were when RAMDrive first started. If an EMM_CTRL sector is being
;	used (TYPE 1 and 3) and one of the EMM_REC structures has been
;	marked EMM_ISDRIVER by this driver, it must turn that bit back off
;	since the driver did not install. A TYPE 2 driver must make sure it
;	ABOVE_DEALLOCs any memory it allocated from the EMM device. The duty
;	of reclaiming EMM_CTRL or Above Board memory and re-setting vectors
;	is done by the DISK_ABORT routine which may be called by either
;	this COMMON INIT code, or the TYPE specific INIT code.
;
;	Step 1 initializes the segment part of TERM_ADDR to the correct
;	value for type 1, 2 and 3 drivers. A TYPE 4 driver will put a
;	different value in TERM_ADDR as it must include the space taken up
;	by the RAMDrive memory itself which is part of the device. TRUE_CS
;	is also initialized. This datum is relevant to the RESMEM_SPECIAL
;	(TYPE 4) driver which relocates the driver code at RAMDrive_RELOC.
;	This datum stores the CS of the REAL driver (the driver location
;	BEFORE the relocation took place).
;
;	Step 2 checks to make sure that we are running on a DOS in the
;	2.X or 3.X series which this driver is restricted to. If running
;	on a 2.X series the device header attribute word and device command
;	table are patched to exclude those device calls that don't exist
;	on DOS 2.X. The HEADERMES message is also patched to not include
;	the DOS drive letter part because 2.X DOS does not provide this
;	information to the device at INIT time.
;
;	Step 3 uses the "DEVICE = xxxxxxxxx" line pointer provided by
;	DOS to look for the various device parameters. NOTE: This pointer
;	IS NOT DOCUMENTED in the DOS 2.X tech ref material, but it does
;	exist in the same way as 3.X. This code is simple even though
;	it looks rather long. First it skips over the device name field
;	to get to the arguments. In then parses the arguments as they are
;	encountered. All parameter errors are detected here. NOTE THAT
;	THIS ROUTINE IS NOT RESPONSIBLE FOR SETTING DEFAULT VALUES OF
;	PARAMETER VARIABLES. This is accomplished by static initialization
;	of the parameter variables.
;
;	Step 4 calls a device TYPE specific initialization routine based
;	on the parse in step 3 (presence or absense of /E and /A switches).
;	NOTE THAT THERE IS ONE ROUTINE FOR TYPE 3 AND 4 DRIVERS. It is up
;	to this routine itself to make the distinction between TYPE 3 and
;	TYPE 4. NOTE that one of the prime jobs of these device TYPE specific
;	routines is to set all of the variables that are needed by Step
;	5 and 7 that haven't been set by the COMMON init code:
;
;			DEV_SIZE   set to TRUE size of device
;			BASE_ADDR  set to TRUE start of device so MEMIO
;					can be called
;			BASE_RESET set so DISK_ABORT can be called
;			TERM_ADDR  set to correct end of device
;			INIT_DRIVE set to indicate if DOS volume needs to
;					be set up
;			RESMEM_SPECIAL set if TYPE 4 driver
;
;	Step 5 looks at the INIT_DRIVE variable to see if the DOS volume
;	needs to be initialized. The only time we do not need to INITialize
;	the DOS volume is when the driver TYPE specific INIT code finds
;	that there is a VALID DOS volume in the RAMDrive memory it just
;	set up. If the DOS volume does not need to be initialized, we
;	go on to step 6. Otherwise the device BPB must be set, the
;	RESERVED (boot) sector, FAT sectors, and root directory sectors
;	must be initialized and written out to the RAMDrive. The first step
;	is to initialize all of the BPB values. The code is a typical piece
;	of MS-DOS code which given BYTES/SECTOR, TOTAL DISK SIZE
;	and NUMBER OF ROOT DIRECTORY ENTRIES inputs figures out reasonable
;	values for SEC/CLUSTER and SECTORS/FAT and TOTAL NUMBER OF CLUSTERS.
;	NOTE THAT THIS CODE IS TUNED AND SPECIFIC TO 12 BIT FATS. Don't
;	expect it to work AT ALL with a 16 bit FAT. The next step is to write
;	out the BOOT record containing the BPB to sector 0, write out
;	a FAT with all of the clusters free, and write out a root directory
;	with ONE entry (the Volume ID at VOLID). Take CAREFUL note of the
;	special code and comments at RAMDrive_RELOC.
;
;	Step 6 makes the status report display of DEVICE SIZE, SECTOR SIZE,
;	CLUSTER SIZE, and DIRECTORY SIZE by simply printing out the values
;	from the BPB.
;
;	Step 7 sets the INIT I/O packet return values for # of units,
;	Break address, and BPB array pointer and returns via DEVEXIT.
;
;	SEE ALSO
;	  MS-DOS Technical Reference manual section on
;	  Installable Device Drivers
;
;	ENTRY from RAM$IN
;	EXIT Through DEVEXIT
;	USES ALL
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

RAM$INIT:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
    ;
    ; 1.  Initialize various global values
    ;
	MOV	WORD PTR [TERM_ADDR + 2],CS
	MOV	[TRUE_CS],CS
	mov	[sys_flg],0
    ;
    ; 2.  Check for correct DOS version and do changes to the device
    ;	     based on the DOS version if needed.
    ;
	CLD
	MOV	AH,GET_VERSION
	INT	21H
	XCHG	AH,AL
	CMP	AX,(2 SHL 8) + 00
	JB	BADVER			; Below 2.00, BAD
	CMP	AX,(3 SHL 8) + 00
	JB	VER2X			; 2.X requires some patches
	CMP	AX,(4 SHL 8) + 00
	je	ldl_buf_present 	; indicate that there is a hole for loadall
	Ja	BADVER			; 3.X ok, 4.0 or above bad
	cmp	al,30			; 3.30
	jb	ver_ok			; if below we cannot take advantage of 80:0
ldl_buf_present:
	or	[sys_flg],DOS_33	; indicate we have dos 3.3 or above
	jmp	ver_ok

BADVER:
	MOV	DX,OFFSET BADVERMES
	JMP	DEVABORT

VER2X:
	AND	[DEVATS],NOT DEVOPCL	    ; No such bit in 2.X
	MOV	BYTE PTR [RAMTBL],11	    ; Fewer functions too
	MOV	WORD PTR [PATCH2X],0A0DH    ; Don't know DOS drive
	MOV	BYTE PTR [PATCH2X + 2],"$"
VER_OK:
;;
;; 2.5 Check here for 6300 PLUS machine.  First look for Olivetti Copy-right
;;     and if found, check id byte at f000:fffd.
;;

	push	es				;; Olivetti Machine?
	mov	ax,0fc00h			;; Look for 'OL' at fc00:50
	mov	es,ax
	cmp	es:[0050h],'LO'
	jnz	notS5				;; not found
	mov	ax,0f000h
	mov	es,ax
	cmp	word ptr es:[0fffdh],0fc00h	;; look for 6300 plus
	jnz	notS5
	mov	[S5_FLAG],S_OLIVETTI		;; yep, set flag
	jmp	notHP
notS5:
;; Check here for an HP Vectra machine.  Look for HP id byte.
;;
	mov	ax,0f000H
	mov	es,ax
	cmp	es:[0f8H],'PH'
	jnz	notHP
	mov	[S5_FLAG],S_VECTRA
notHP:
	pop	es
;
; 3.  Parse the command line and set values accordingly
;
	LDS	SI,[PTRSAV]
ASSUME	DS:NOTHING
	MOV	AL,[SI.INIT_DOSDEV] ; DOS drive letter
	ADD	CS:[DOS_DRV],AL     ; Need explicit over, this is a forward ref
	MOV	DX,OFFSET HEADERMES
	CALL	PRINT
	LDS	SI,[SI.INIT_BPB]    ; DS:SI points to config.sys
SKIPLP1:			    ; Skip leading delims to start of name
	LODSB
	CMP	AL," "
	JZ	SKIPLP1
	CMP	AL,9
	JZ	SKIPLP1
	CMP	AL,","
	JZ	SKIPLP1
	JMP	SHORT SKIPNM

ARGS_DONEJ:
	JMP	ARGS_DONE

SWITCHJ:
	JMP	SWITCH

SKIPLP2:			; Skip over device name
	LODSB
SKIPNM:
	CMP	AL,13
	JZ	ARGS_DONEJ
	CMP	AL,10
	JZ	ARGS_DONEJ
	CMP	AL," "
	JZ	FIRST_ARG
	CMP	AL,9
	JZ	FIRST_ARG
	CMP	AL,","
	JZ	FIRST_ARG
	CMP	AL,0		; Need this for 2.0 2.1
	JNZ	SKIPLP2
SCAN_LOOP:			; PROCESS arguments
	LODSB
FIRST_ARG:
	OR	AL,AL		; Need this for 2.0 2.1
	JZ	ARGS_DONEJ
	CMP	AL,13
	JZ	ARGS_DONEJ
	CMP	AL,10
	JZ	ARGS_DONEJ
	CMP	AL," "
	JZ	SCAN_LOOP
	CMP	AL,9
	JZ	SCAN_LOOP
	CMP	AL,","
	JZ	SCAN_LOOP
	CMP	AL,"/"
	JZ	SWITCHJ
	CMP	AL,"0"
	JB	BAD_PARMJ
	CMP	AL,"9"
	JA	BAD_PARMJ
	DEC	SI
	CALL	GETNUM
	CMP	[NUM_ARG],3
	JA	BAD_PARMJ		 ; Only 3 numeric arguments
	JZ	SET_DIR
	CMP	[NUM_ARG],2
	JZ	SET_SECTOR
SET_SIZE:
	CMP	BX,16
	JB	BAD_PARMJ
	CMP	BX,4096
	JA	BAD_PARMJ
	MOV	[DEV_SIZE],BX
	JMP	SHORT NUM_DONE

BAD_PARMJ:
	JMP	BAD_PARM

SET_SECTOR:
	MOV	AL,6
	CMP	BX,128
	JZ	SET_SEC
	INC	AL
	CMP	BX,256
	JZ	SET_SEC
	INC	AL
	CMP	BX,512
	JZ	SET_SEC
	INC	AL
	CMP	BX,1024
	JNZ	BAD_PARM
SET_SEC:
	MOV	[SSIZE],BX
	MOV	[SEC_SHFT],AL
	JMP	SHORT NUM_DONE

SET_DIR:
	CMP	BX,2
	JB	BAD_PARM
	CMP	BX,1024
	JA	BAD_PARM
    ;
    ; NOTE: Since DIRNUM is the 3rd numeric arg and SSIZE is the first,
    ;	    we know the desired sector size has been given.
    ;
	MOV	DI,[SSIZE]
	MOV	CL,5		; 32 bytes per dir ent
	SHR	DI,CL		; DI is number of dir ents in a sector
	MOV	AX,BX
	XOR	DX,DX
	DIV	DI		; Rem in DX is partial dir sector
	OR	DX,DX
	JZ	SET_DSZ 	; User specified groovy number
	SUB	DI,DX		; Figure how much user goofed by
	ADD	BX,DI		; Round UP by DI entries
SET_DSZ:
	MOV	[DIRNUM],BX
NUM_DONE:
	INC	[NUM_ARG]		; Next numeric argument
SCAN_LOOPJ:
	JMP	SCAN_LOOP

BAD_PARM:
	MOV	DX,OFFSET ERRMSG1
DEVABORT:
	CALL	PRINT
DEVABORT_NOMES:
	XOR	AX,AX			;Indicate no devices
	JMP	SETBPB			;and return

SWITCH:
	MOV	AL,0FFH
	XCHG	AL,[GOTSWITCH]		; Switch already?
	OR	AL,AL
	JNZ	BAD_PARM		; Yes, only one allowed
	LODSB
	CMP	AL,"E"
	JZ	EXT_SET
	CMP	AL,"e"
	JNZ	ABOVE_TEST
EXT_SET:
	MOV	[DRIVER_SEL],0
	JMP	SCAN_LOOP

ABOVE_TEST:
;; Added for /u switch
	cmp	al,'u'			;; Look for U switch for PLUS
	jz	S5_TEST
	cmp	al,'U'			;;
	jnz	A_TEST
S5_TEST:
	cmp	[S5_FLAG],S_OLIVETTI	;; No good unless PLUS
	jne	bad_parm
;	xchg	al,[gotswitch]	       ; switch already
;	or	al,al
;	jnz	bad_parm
;
	cmp	[U_SWITCH],0
	jne	bad_parm
	dec	[U_SWITCH]
	jmp	ext_set
A_TEST:

	CMP	AL,"A"
	JZ	ABOVE_SET
	CMP	AL,"a"
	JNZ	BAD_PARM
ABOVE_SET:
	MOV	[DRIVER_SEL],1
	JMP	SCAN_LOOP

ARGS_DONE:
;
; 4.  Call a TYPE specific INIT routine based on the Parse
;	 to set up a specific driver TYPE.
;
	PUSH	CS
	POP	DS
ASSUME	DS:RAMCODE
	MOV	AL,[DRIVER_SEL] 	; Find out which init to call
	OR	AL,AL
	JNZ	NEXTV
	CALL	AT_EXT_INIT
	JMP	SHORT INI_RET

NEXTV:
	DEC	AL
	JNZ	DORESM
	CALL	ABOVE_INIT
	JMP	SHORT INI_RET

DORESM:
	CALL	RESMEM_INIT
INI_RET:
	JNC	I001
	JMP	DEVABORT_NOMES

I001:
;
; 5.  Initialize the DOS volume in the RAMDrive memory if appropriate
;
	CMP	[INIT_DRIVE],0
	JNZ	INIDRV			; Need to initialize drive
	JMP	DRIVE_SET		; All set to go

INIDRV:
;
; We must figure out what to do.
; All values are set so we can call MEMIO to read and write disk
; SSIZE is user sector size in bytes
; DIRNUM is user directory entries
; DEV_SIZE is size of device in K bytes
;
    ; Figure out total number of sectors in logical image
	MOV	AX,[DEV_SIZE]
	MOV	CX,1024
	MUL	CX		; DX:AX is size in bytes of image
	DIV	[SSIZE] 	; AX is total sectors
				; Any remainder in DX is ignored
	MOV	[SECLIM],AX
    ; Compute # of directory sectors
	MOV	AX,[DIRNUM]
	MOV	CL,5		; Mult by 32 bytes per entry
	SHL	AX,CL		; Don't need to worry about overflow, # ents
				;     is at most 1024
	XOR	DX,DX
	DIV	[SSIZE]
	OR	DX,DX
	JZ	NOINC
	INC	AX
NOINC:				; AX is # sectors for root dir
	MOV	[DIRSEC],AX
	ADD	AX,2		; One reserved, At least one FAT sector
	CMP	AX,[SECLIM]
	JB	OK001		; we're OK
	MOV	[DIRNUM],16	; Smallest reasonable number
	XOR	DX,DX
	MOV	AX,512		; 16*32 = 512 bytes for dir
	DIV	[SSIZE]
	OR	DX,DX
	JZ	NOINC2
	INC	AX
NOINC2: 			; AX is # sectors for root dir
	MOV	[DIRSEC],AX
	ADD	AX,2		; One reserved, At least one FAT sector
	CMP	AX,[SECLIM]
	JB	OK001		; 16 directory sectors got us to OK
	CALL	DISK_ABORT	; Barf
	MOV	DX,OFFSET ERRMSG2
	JMP	DEVABORT

OK001:
	mov	si,64		; set a loop bound for the homing process
				; to avoid oscillation in homing
CLUSHOME:
    ; Figure a reasonable cluster size
	MOV	AX,[SECLIM]	; AX is total sectors on disk
	SUB	AX,[RESSEC]	; Sub off reserved sectors
	MOV	CL,[FATNUM]	; CX is number of FATs
	XOR	CH,CH
FATSUB:
	SUB	AX,[FATSEC]	; Sub off FAT sectors
	LOOP	FATSUB
	SUB	AX,[DIRSEC]	; Sub off directory sectors, AX is # data sectors
	MOV	BX,1		; Start at 1 sec per alloc unit
	CMP	AX,4096-10
	JB	CSET		; 1 sector per cluster is OK
	MOV	BX,2
	CMP	AX,(4096-10) * 2
	JB	CSET		; 2 sector per cluster is OK
	MOV	BX,4
	CMP	AX,(4096-10) * 4
	JB	CSET		; 4 sector per cluster is OK
	MOV	BX,8
	CMP	AX,(4096-10) * 8
	JB	CSET		; 8 sector per cluster is OK
	MOV	BX,16		; 16 sector per cluster is OK
CSET:
    ; Figure FAT size. AX is reasonable approx to number of DATA sectors
    ;  BX is reasonable sec/cluster
	XOR	DX,DX
	DIV	BX		; AX is total clusters, ignore remainder
				;  can't have a "partial" cluster
	MOV	CX,AX
	SHR	CX,1
	JNC	ADDIT
	INC	CX
ADDIT:
	ADD	AX,CX		; AX is Bytes for fat (1.5 * # of clusters)
	ADD	AX,3		; Plus two reserved clusters
	XOR	DX,DX
	DIV	[SSIZE] 	; AX is # sectors for a FAT this size
	OR	DX,DX
	JZ	NOINC4
	INC	AX		; Round up
NOINC4: 			; AX is # sectors for FAT
	XCHG	AX,[FATSEC]	; Set newly computed value
	XCHG	BL,[CSIZE]	; Set newly computed value
	dec	si		; have we looped enough?
	jz	homfin		; yes, time to get out
	CMP	BL,[CSIZE]	; Did we compute a different size?
	JNZ	CLUSHOME	; Keep performing FATSEC and CSIZE computation
				;   until the values don't change.
	CMP	AX,[FATSEC]	; Did we compute a different size?
	JNZ	CLUSHOME	; Keep performing FATSEC and CSIZE computation
				;   until the values don't change.
HOMFIN:
    ;
    ; 6.  Print out report of RAMDrive parameters
    ;
	MOV	DX,OFFSET STATMES1
	CALL	PRINT
	MOV	AX,[DEV_SIZE]
	CALL	ITOA
	MOV	DX,OFFSET STATMES2
	CALL	PRINT
	MOV	AX,[SSIZE]
	CALL	ITOA
	MOV	DX,OFFSET STATMES3
	CALL	PRINT
	MOV	AL,[CSIZE]
	XOR	AH,AH
	CALL	ITOA
	MOV	DX,OFFSET STATMES4
	CALL	PRINT
	MOV	AX,[DIRNUM]
	CALL	ITOA
	MOV	DX,OFFSET STATMES5
	CALL	PRINT
	CMP	[RESMEM_SPECIAL],0
	JZ	NO_RELOC
    ;
    ; We are in a special case. The RAMDrive driver area starts at DEVICE_END.
    ;  If we left this INIT code where it is and executed it the act of
    ;  Initializing the boot sector, FAT, and root directory would overwrite
    ;  this INIT code as we are executing it. So what we do is COPY this
    ;  code into the DATA area of the RAMDrive and execute it from there.
    ;
RAMDrive_RELOC:
	MOV	AX,1			; AX is sec # of start of FAT
	ADD	AX,[FATSEC]		; AX is sec # of start of directory
	ADD	AX,[DIRSEC]		; AX is sec # of start of DATA
	MUL	[SSIZE] 		; DX:AX is byte offset of start of DATA
	ADD	AX,WORD PTR [BASE_ADDR]
	ADC	DX,WORD PTR [BASE_ADDR + 2] ; DX:AX is 32 addr of first byte of DATA
	ADD	AX,15			; PARA round up
	ADC	DX,0
	MOV	CX,16
	DIV	CX			; AX is Seg addr of DATA region
    ;
    ; At this point we need to do a little check. We need to make
    ;	sure the distance between where we are now, and where we
    ;	are relocating to is AT LEAST as much as we are moving
    ;	so that we don't modify ourselves while we're moving
    ;
	MOV	BX,AX
	MOV	DX,CS
	SUB	BX,DX			; BX is para between segs
	CMP	BX,((OFFSET RAMDrive_END - OFFSET RAMDEV) + 15) / 16 ; CMP to para moving
	JAE	OKMOV			; Distance is enough
	MOV	AX,CS			; Move far enough away
	ADD	AX,((OFFSET RAMDrive_END - OFFSET RAMDEV) + 15) / 16
OKMOV:
	MOV	ES,AX
	XOR	SI,SI
	MOV	DI,SI
	MOV	CX,OFFSET RAMDrive_END	   ; Amount to move
	CLD
	REP	MOVSB			; Reloc to data region
	PUSH	ES			; Push FAR return
	MOV	AX,OFFSET NO_RELOC
	PUSH	AX
	PUSH	ES
	POP	DS			; DS is NEW RAMCODE
RELOCR	PROC	FAR
	RET
RELOCR	ENDP

NO_RELOC:
	PUSH	CS
	POP	ES
	XOR	DX,DX		; Sector 0
	MOV	CX,1		; One sector
	MOV	DI,OFFSET BOOT_SECTOR	; Boot sector
	MOV	BH,1		; Write
	CALL	INIMEMIO
	INC	DX		; First FAT sector
	MOV	DI,OFFSET SECTOR_BUFFER
	XOR	AX,AX
	MOV	CX,512
	CLD
	REP	STOSW
	MOV	DI,OFFSET SECTOR_BUFFER
	MOV	CX,1
	MOV	WORD PTR ES:[DI],0FFF8H
	MOV	BYTE PTR ES:[DI + 2],0FFH
	CALL	INIMEMIO
	INC	DX		; Next sector
	MOV	WORD PTR ES:[DI],0
	MOV	BYTE PTR ES:[DI + 2],0
	MOV	CX,[FATSEC]
	DEC	CX
	JCXZ	FATDONE
FATZERO:
	PUSH	CX
	MOV	CX,1
	CALL	INIMEMIO
	INC	DX		; Next sector
	POP	CX
	LOOP	FATZERO
FATDONE:
	MOV	CX,1
	MOV	DI,OFFSET VOLID
	CALL	INIMEMIO	; FIRST directory sector
	INC	DX
	MOV	CX,[DIRSEC]
	DEC	CX
	JCXZ	DRIVE_SET
	MOV	DI,OFFSET SECTOR_BUFFER
DIRZERO:
	PUSH	CX
	MOV	CX,1
	CALL	INIMEMIO
	INC	DX		; Next sector
	POP	CX
	LOOP	DIRZERO
;
DRIVE_SET:
;
;	BPB IS NOW ALL SET
;
	MOV	AL,1			;Number of ramdrives
;
;	NOTE FALL THROUGH!!!!!!!
;

;**	SETBPB - Set INIT packet I/O return values
;
;	This entry is used in ERROR situations to return
;	a unit count of 0 by jumping here with AL = 0.
;	The successful code path falls through to here
;	with AL = 1
;
;	ENTRY
;	    AL = INIT packet unit count
;	EXIT
;	    through DEVEXIT
;	USES
;	    DS, BX, CX
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

SETBPB:
ASSUME	DS:NOTHING
    ;
    ; 7.  Set the return INIT I/O packet values
    ;
	LDS	BX,[PTRSAV]
	MOV	[BX.INIT_NUM],AL
	MOV	CX,WORD PTR [TERM_ADDR]
	MOV	WORD PTR [BX.INIT_BREAK],CX		   ;SET BREAK ADDRESS
	MOV	CX,WORD PTR [TERM_ADDR + 2]
	MOV	WORD PTR [BX.INIT_BREAK + 2],CX
	MOV	WORD PTR [BX.INIT_BPB],OFFSET INITAB	   ;SET POINTER TO BPB ARRAY
	MOV	CX,[TRUE_CS]
	MOV	WORD PTR [BX.INIT_BPB + 2],CX
	JMP	DEVEXIT

;**	INIMEMIO call MEMIO but preserve registers
;
;	MEMIO is very register destructive, all this routine
;	does is provide a less destructive way to call MEMIO.
;
;	ENTRY
;	    Same as MEMIO
;	EXIT
;	    Same as MEMIO
;	USES
;	    AX, SI, BP
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

INIMEMIO:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSH	ES
	PUSH	DI
	PUSH	DS
	PUSH	CX
	PUSH	DX
	PUSH	BX
	CALL	MEMIO
	POP	BX
	POP	DX
	POP	CX
	POP	DS
	POP	DI
	POP	ES
	RET

;**	GETNUM - Read an unsigned integer
;
;	This routine looks at DS:SI for a decimal unsigned integer.
;	It is up to the caller to make sure DS:SI points to the start
;	of a number. If it is called without DS:SI pointing to a valid
;	decimal digit the routine will return 0. Any non decimal digit
;	defines the end of the number and SI is advanced over the
;	digits which composed the number. Leading "0"s are OK.
;
;	THIS ROUTINE DOES NOT CHECK FOR NUMBERS LARGER THAN WILL FIT
;	IN 16 BITS. If it is passed a pointer to a number larger than
;	16 bits it will return the low 16 bits of the number.
;
;	This routine uses the MUL instruction to multiply the running
;	number by 10 (initial value is 0) and add the numeric value
;	of the current digit. Any overflow on the MUL or ADD is ignored.
;
;	ENTRY:
;	     DS:SI -> ASCII text of number
;	EXIT:
;	     BX is binary for number
;	     SI advanced to point to char after number
;	USES:
;	     AX,BX,DX,SI
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

GETNUM:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

	XOR	BX,BX
GETNUM1:
	LODSB
	SUB	AL,"0"
	JB	NUMRET
	CMP	AL,9
	JA	NUMRET
	CBW
	XCHG	AX,BX
	MOV	DX,10
	MUL	DX
	ADD	BX,AX
	JMP	GETNUM1

NUMRET:
	DEC	SI
	RET

BREAK	<INITIAL EMM control sector>

;**	INITIAL EMM_CTRL sector
;
;	This is a datum which represents a correct initial EMM_CTRL
;	sector as discussed in the EMM_CTRL documentation. It is used
;	to check for the presense of a valid EMM_CTRL by comparing
;	the signature strings, and for correctly initializing the
;	EMM_CTRL sector if needed.
;
;	The DWORD at BASE_RESET, which is the EMM_BASE of the NULL
;	0th EMM_REC structure, is used as a storage location of
;	the address of the EMM_CTRL sector (PLUS 1024!!!!!!).
;	This value can be used if it is necessary to re-address the
;	EMM_CTRL sector during initialization. See the DISK_ABORT routine.
;	NOTE THAT BASE_RESET CAN NOT BE USED AT RUNTIME AS THIS DATUM
;	IS NOT PART OF THE RESIDENT IMAGE.
;
;	This data is appropriate to TYPE 1 and TYPE 3 drivers
;

EMM_CONTROL   LABEL   BYTE
		DB	"MICROSOFT EMM CTRL VERSION 1.00 CONTROL BLOCK     "
		DW	0
		DW	0
	; NULL 0th record
		DW	EMM_ALLOC + EMM_ISDRIVER
		DW	EMM_EMM
BASE_RESET	LABEL	DWORD		; RESMEM driver must patch this value
		DW	EXTMEM_LOW + 1024
		DW	EXTMEM_HIGH
		DW	0

		DB	950 DUP(0)
		DB	"ARRARRARRA"


BREAK	<RAMDrive COMMON INIT ROUTINES>

;**	DISK_ABORT - De-install RAMDrive after init
;
;	This routine MUST BE CALLED to de-install a RAMDrive driver
;	if the de-installation takes place:
;
;		AFTER INT 19/INT 9 vectors are replaced
;		AFTER ABOVE_PID is valid for TYPE 2
;		AFTER an EMM_REC structure in the EMM_CTRL sector
;			has been marked EMM_ISDRIVER for TYPE 1 or 3.
;
;	NOTE: Since a TYPE 4 driver does NONE of the above things it is
;		not necessary to call this routine, but the routine is
;		designed so that it is OK to call for a TYPE 4 driver.
;
;	In all cases the INT 9 and INT 19 vectors are replaced if the
;	value of both words of OLD_19 is NOT -1. This is why the initial value
;	of this datum is -1. In the event that the INT 9 and INT 19 vectors
;	are replaced, this datum takes on some value other than -1.
;
;	If this is a TYPE 1 or TYPE 3 driver the EMM_ISDRIVER bit is
;	turned off in the LAST EMM_MSDOS EMM_REC structure.
;	NOTE THAT A TYPE 1 or TYPE 3 DRIVER MUST NOT USE THIS ROUTINE
;	IF IT HAS NOT "TURNED ON" AN EMM_ISDRIVER BIT IN ONE OF THE EMM_REC
;	STRUCTURES. If this is done, this code MAY turn off the WRONG
;	EMM_ISDRIVER bit (probably a bit for a previously installed RAMDrive
;	of the same TYPE).
;
;	If this is a TYPE 2 driver, an ABOVE_DEALLOC call is made on
;	ABOVE_PID.
;
;	ENTRY:
;	    NONE
;
;	    BASE_RESET valid if TYPE 1 or TYPE 3
;	    ABOVE_PID valid if TYPE 2
;
;	EXIT:
;	    NONE
;	USES:
;	    ALL but DS
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

DISK_ABORT:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING

	CMP	[DRIVER_SEL],1
	JNZ	NOT_ABOVE
AGAIN:
    ;
    ; TYPE 2, De-alloc the Above Board memory
    ;
	MOV	DX,[ABOVE_PID]
	MOV	AH,ABOVE_DEALLOC
	INT	67H
	CMP	AH,ABOVE_ERROR_BUSY
	JZ	AGAIN
	JMP	SHORT RET002

NOT_ABOVE:
	CMP	[RESMEM_SPECIAL],0
	JNZ	RET002				; No EMM_CTRL on TYPE 4
;
; sp new int15 allocation for ext memory (except for oli memory) so no
;    emm control for these
;
    ;
	cmp	[new_all],0	    ;new allocation scheme
	jne	ret002		    ; if yes then skip emm updates
    ;
    ; TYPE 1 or 3, turn off last EMM_ISDRIVER
    ;
	MOV	AX,WORD PTR [BASE_RESET]
	MOV	DX,WORD PTR [BASE_RESET + 2]
	SUB	AX,1024 			; Backup to EMM_CTRL
	SBB	DX,0
	MOV	WORD PTR [BASE_ADDR],AX
	MOV	WORD PTR [BASE_ADDR + 2],DX
	XOR	BH,BH				; READ
	CALL	CTRL_IO 			; Get EMM_CTRL
	JC	RET002
	MOV	DI,OFFSET SECTOR_BUFFER
	MOV	SI,DI
	ADD	DI,EMM_RECORD
	MOV	BX,-1			; Init to "no such record"
	MOV	CX,EMM_NUMREC
LOOK_RECX:
    ;
    ; Look for last installed MS-DOS region
    ;
	TEST	[DI.EMM_FLAGS],EMM_ALLOC
	JZ	DONE
	TEST	[DI.EMM_FLAGS],EMM_ISDRIVER
	JZ	NEXTRECX		; No Driver
	CMP	[DI.EMM_SYSTEM],EMM_MSDOS
	JNZ	NEXTRECX
	MOV	BX,DI
NEXTRECX:
	ADD	DI,SIZE EMM_REC
	LOOP	LOOK_RECX
DONE:
	CMP	BX,-1		; DIDn't find it
	JZ	RET002
	AND	[BX.EMM_FLAGS],NOT EMM_ISDRIVER     ; Undo install
	MOV	BH,1		; WRITE
	CALL	CTRL_IO 	; EMM_CTRL back out
RET002:
    ;
    ; Reset INT 9 and/or INT 19 if OLD_19 is not -1
    ;
	PUSH	DS
	LDS	DX,[OLD_19]
ASSUME	DS:NOTHING
	MOV	AX,DS
	CMP	AX,-1
	JNZ	RESET_VECS
	CMP	AX,DX
	JZ	NO_VECS
RESET_VECS:
	MOV	AX,(Set_Interrupt_Vector SHL 8) OR 19H
	INT	21H
;	 LDS	 DX,[OLD_9]
;	 MOV	 AX,(Set_Interrupt_Vector SHL 8) OR 9H
;	 INT	 21H
;
; sp we have to deinstall the int15 handler also if it was installed
;
	lds	dx,[old_15]	; get the old 15h handler addressin ds:dx
	mov	ax,ds
	cmp	ax,-1
	jne	reset_15
	cmp	ax,dx
	je	no_vecs
reset_15:
	mov	ax,(set_interrupt_vector shl 8) or 15h
	int	21h
NO_VECS:
	POP	DS
	RET

;**	CTRL_IO - Read/Write the first 1024 bytes at BASE_ADDR
;
;	This routine is used at INIT time to read the first 1024
;	bytes at BASE_ADDR. If TYPE 1 or TYPE 3 and BASE_ADDR points
;	to the EMM_CTRL address (initial value), the EMM_CTRL sector
;	is read/written. If TYPE 1 or TYPE 3 and BASE_ADDR has been set
;	to the start of a RAMDrive, the first 1024 bytes of the DOS volume
;	are read/written. If TYPE 2 or TYPE 4, the first 1024 bytes of
;	the DOS volume are read/written. All this routine does is
;	set inputs to BLKMOV to transfer 1024 bytes at offset 0 to/from
;	SECTOR_BUFFER.
;
;	ENTRY:
;	     BH = 0 for READ, 1 for WRITE
;	EXIT:
;	     SECTOR_BUFFER filled in with 1024 bytes at BASE_ADDR
;	USES:
;	     ALL but DS
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

CTRL_IO:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	XOR	DX,DX
	MOV	AX,DX		; Offset 0
	MOV	CX,512		; 1024 bytes
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET SECTOR_BUFFER
	PUSH	DS
	CALL	BLKMOV		; Read in EMM_CTRL
	POP	DS
	RET

;**	MM_SETDRIVE - Look for/Init EMM_CTRL and DOS volume
;
;	This routine is used by TYPE 1 and 3 drivers to check for/initialize
;	the EMM_CTRL sector, and check for a valid DOS volume if approriate.
;
;	This routine reads the EMM_CTRL sector in to SECTOR_BUFFER
;	CALLS FIND_VDRIVE to check out and alloc or find an EMM_REC
;	Sets BASE_ADDR to point to the start of the RAMDrive memory
;	Writes the updated EMM_CTRL back out from SECTOR_BUFFER
;	JUMPs to CHECK_DOS_VOL to snoop for a valid DOS volume if
;		the return from FIND_VDRIVE indicates this is worth
;		doing, OTHERWISE return leaving INIT_DRIVE set to the
;		default value of 1 (needs to be INITed).
;
;	ENTRY:
;	     BASE_ADDR initialized to point at START of extended memory
;		     so that the EMM_CTRL sector can be accessed by
;		     doing I/O at offset 0.
;	     EXT_K is set to size of extended memory
;	     DEV_SIZE is set to user requested device size
;	EXIT:
;	     CARRY SET - error, message already printed
;	     CARRY CLEAR
;		     BASE_ADDR set for this drive
;		     INIT_DRIVE set
;		     DEV_SIZE set to TRUE size
;
;	    WARNING! Exit conditions MUST match CHECK_DOS_VOL as it transfers
;		      to that routine.
;
;	USES
;	    ALL but DS
;
;	Used by TYPE 1 and TYPE 3 drivers
;

MM_SETDRIVE:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	XOR	BH,BH		; READ
	CALL	CTRL_IO 	; Get EMM_CTRL
	MOV	DX,OFFSET INIT_IO_ERR
	JC	ERR_RET2
	CALL	FIND_VDRIVE	; Snoop
	JC	RET001
	PUSHF			; Save zero status for DOS VOL snoop
	PUSH	ES		; Save EMM_BASE from EMM_REC
	PUSH	DI
;
;   once again if we installed according to new int15 standard we should
;   not write emm back
;
    ;
    ; test if we installed according to new standard
    ;
	cmp	[new_all],0	 ; did we install according to new standard
	jne	skip_emm_write	; skip writing back emm
;
	MOV	BH,1		; WRITE
	CALL	CTRL_IO 	; Write EMM_CTRL back out
	MOV	DX,OFFSET INIT_IO_ERR
	JC	ERR_RET2P
skip_emm_write:
	POP	WORD PTR [BASE_ADDR]	; Set final correct BASE_ADDR
	POP	WORD PTR [BASE_ADDR + 2]
	POPF
;
; NOTE TRANSFER TO DIFFERENT ROUTINE
;
	JZ	CHECK_DOS_VOL
	CLC			; Leave INIT_DRIVE set
RET001:
	RET

ERR_RET2P:
	ADD	SP,6
ERR_RET2:
	CALL	PRINT
	STC
	RET

;**	CHECK_DOS_VOL  examine RAMDrive region for valid DOS volume.
;
;	This routine is used by TYPE 1, 2 and 3 drivers to check and see
;	if the RAMDrive memory contains a valid DOS volume (one that lived
;	through a re-boot). Its prime job is to set INIT_DRIVE to indicate
;	whether the DOS volume needs to be initialized.
;
;	First the first 1024 bytes of the drive are read in to SECTOR_BUFFER
;	Next we check for a match of the signature areas up at BOOT_SECTOR
;	  to see if this drive contains a VALID RAMDrive boot record.
;	IF the signatures are valid AND INIT_DRIVE != 2 (ignore valid signature)
;		We check to make sure that SSIZE and DIRNUM set by the user
;		match the values in the BPB we just found.
;		IF they match
;		    we set INIT_DRIVE to 0 (don't init)
;		    and transfer the BPB out of the boot sector on the drive
;		    (in SECTOR_BUFFER) into the BPB for this driver at
;		    RDRIVEBPB.
;		ELSE
;		    Leave INIT_DRIVE set to whatever it was on input (1 or 2)
;		    indicating that the drive must be INITed.
;	ELSE
;		Leave INIT_DRIVE set to whatever it was on input (1 or 2)
;		indicating that the drive must be INITed.
;
;	WARNING! This routine DOES NOT check to make sure that the size of
;		the device as indicated in the BPB transfered in if a valid
;		DOS volume is found is consistent with the actual size
;		of the memory allocated to the device (DEV_SIZE). It
;		is up to the caller to check this if so desired.
;
;	ENTRY:
;	    BASE_ADDR set to point at START of DOS device
;	EXIT:
;	    CARRY SET - error, message already printed
;	    CARRY CLEAR
;		INIT_DRIVE set
;		SECTOR_BUFFER contains first 1024 bytes of device
;	USES:
;	    All but DS
;
;	WARNING! Exit conditions MUST match MM_SETDRIVE as it jumps to this
;		  routine.
;
;	Used by TYPE 1, 2 and 3 drivers
;

CHECK_DOS_VOL:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	XOR	BH,BH		; READ
    ;
    ; NOTE: WE CANNOT CALL MEMIO, WE MUST STILL USE CTRL_IO because the BPB
    ;	 is not set up.
    ;
	CALL	CTRL_IO 	; Since BASE_ADDR is set, reads start of DEVICE
	MOV	DX,OFFSET INIT_IO_ERR
	JC	ERR_RET2
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET SECTOR_BUFFER
	MOV	SI,OFFSET BOOT_SECTOR
	MOV	CX,OFFSET RDRIVEBPB - OFFSET BOOT_SECTOR
	CLD
	REPE	CMPSB
	JNZ	OK_RET		; No DOS device
	ADD	DI,OFFSET BOOT_START - OFFSET RDRIVEBPB
	ADD	SI,OFFSET BOOT_START - OFFSET RDRIVEBPB
	MOV	CX,OFFSET BOOT_END - OFFSET BOOT_START
	REPE	CMPSB
	JNZ	OK_RET		; No DOS device
	CMP	[INIT_DRIVE],2
	JZ	NOT_VALID		; Current value 2 means we CANNOT
					; assume this BPB is valid.
    ;
    ; Check to make sure found BPB has same SSIZE and DIRNUM values
    ;
	MOV	SI,OFFSET SECTOR_BUFFER + (OFFSET SSIZE - OFFSET BOOT_SECTOR)
	LODSW
	CMP	AX,[SSIZE]
	JNZ	NOT_VALID		; Sector size different than user request
	MOV	SI,OFFSET SECTOR_BUFFER + (OFFSET DIRNUM - OFFSET BOOT_SECTOR)
	LODSW
	CMP	AX,[DIRNUM]
	JNZ	NOT_VALID		; Sector size different than user request

	MOV	[INIT_DRIVE],0		; Found a DOS drive
	MOV	DI,OFFSET RDRIVEBPB
	MOV	SI,OFFSET SECTOR_BUFFER + (OFFSET RDRIVEBPB - OFFSET BOOT_SECTOR)
	MOV	CX,OFFSET BOOT_START - OFFSET RDRIVEBPB
	REP	MOVSB			; Set correct BPB
NOT_VALID:
OK_RET:
	CLC
	RET

;**	FIND_VDRIVE - Check out EMM_CTRL and alloc
;
;	This code checks for a valid EMM_CTRL and sets up
;	an initial one if there isn't. It then performs the
;	algorithm described in the EMM_CTRL documentation
;	to either allocate a NEW EMM_REC of type EMM_MSDOS,
;	or find an existing EMM_REC which is EMM_MSDOS and has
;	its EMM_ISDRIVER bit clear. In the later case it
;	checks to see if DEV_SIZE is consistent with EMM_KSIZE
;	and tries to make adjustments to EMM_KSIZE or DEV_SIZE
;	if they are not consistent.
;
;	As a side effect of scanning the EMM_CTRL sector for
;	EMM_RECs with EMM_MSDOS and EMM_ISDRIVER we also find
;	out if this is the first TYPE 1 or TYPE 3 driver in the
;	system. If this is the first, then the INT 9/INT 19 code
;	is installed.
;
;	First the EMM_CTRL signature strings are checked.
;	If they are not valid we go to SETCTRL to set up a new
;	empty EMM_CTRL in SECTOR_BUFFER.
;	If the signatures are valid, EMM_TOTALK is checked
;	against EXT_K. If they are the same, the EMM_CTRL sector is
;	valid and we skip to SCAN_DEV. Otherwise we initialize the
;	EMM_CTRL sector at SETCTRL. All we need to do to set up the initial
;	EMM_CTRL sector is transfer the record at EMM_CONTROL into
;	SECTOR_BUFFER and set EMM_TOTALK and EMM_AVAILK to EXT_K - 1.
;
;	In either case, finding a valid EMM_CTRL or setting up a correct
;	initial one, we end up at SCAN_DEV. This code performs the
;	scan of the EMM_REC structures looking for a "free" one
;	or an allocated one which is EMM_MSDOS and has its EMM_ISDRIVER
;	bit clear as described in the EMM_CTRL sector documentation.
;	NOTE THAT THIS SCAN SETS THE BX REGISTER TO INDICATE WHETHER
;	WE FOUND ANY EMM_REC STRUCTURES WHICH WERE EMM_MSDOS AND HAD
;	THEIR EMM_ISDRIVER BIT SET. If we found such an EMM_REC structure
;	then this IS NOT the first driver in the system and the INT 9/INT 19
;	code SHOULD NOT be installed.
;
;	If we find a "free" EMM_REC structure we go to GOT_FREE_REC
;	and try to allocate some memory. This attempt will fail if
;	EMM_AVAILK is less than 16K. We then call SET_RESET to do
;	the INT 9/INT 19 setup if the BX register set by the EMM_REC
;	scan indicates we should. We adjust DEV_SIZE to equal the
;	available memory if DEV_SIZE is > EMM_AVAILK. Then all we do
;	is set EMM_AVAILK and all of the fields in the EMM_REC structure
;	as described in the EMM_CTRL sector documentation. We return
;	with zero reset as there cannot be a valid RAMDrive in this
;	region because we just allocated it.
;
;	If we find an EMM_REC structure with EMM_MSDOS and EMM_ISDRIVER
;	clear then we know this region MIGHT have a valid DOS volume
;	so we will return with zero set (this is set up at OK_SET_DEV).
;	At CHECK_SYS plus 5 lines we:
;
;		Call SET_RESET to do INT 9/INT 19 setup if BX indicates
;		IF the EMM_REC structure we found is the LAST EMM_REC structure
;		    we cannot edit any sizes and whatever the EMM_KSIZE
;		    is we stuff it into DEV_SIZE and set the EMM_ISDRIVER
;		    bit, and we're done.
;		    NOTE: We DO NOT check that EMM_KSIZE is at least
;			16K as we know this EMM_REC was created
;			by some PREVIOUS RAMDrive program who
;			DID make sure it was at least 16K
;		ELSE
;		    IF EMM_KSIZE == DEV_SIZE
;			set EMM_ISDRIVER and we're done
;		    IF EMM_KSIZE < DEV_SIZE
;			either the user has edited his DEVICE = line since
;			the last time the system was re-booted, or at the
;			time we initially allocated this region EMM_AVAILK
;			was less than DEV_SIZE and we had to trim the device
;			size back.
;			This case is handled at INSUFF_MEM.
;			IF the next EMM_REC structure is not allocated
;			    IF EMM_AVAILK == 0
;				We can't do anything, so set DEV_SIZE
;				to EMM_KSIZE and we're done.
;			    ELSE
;				allocate appropriate amount off of EMM_AVAILK
;				and add it to EMM_KSIZE.
;				Set INIT_DRIVE to 2 and we're done.
;				The reason we set INIT_DRIVE to 2 is because
;				we just changed the size of this block from
;				what it was before so there is no way the BPB
;				in the region (if there is one) can be valid.
;				Setting INIT_DRIVE to 2 means "I don't care if
;				there is a valid boot record in this region,
;				re-initialize it based on DEV_SIZE
;			ELSE
;			    We can't do anything, so set DEV_SIZE
;			    to EMM_KSIZE and we're done.
;		    ELSE
;			This is the EMM_KSIZE > DEV_SIZE case, it means the
;			user MUST have edited his DEVICE = line.
;			IF next EMM_REC is NOT free
;				We can't shrink the allocation block,
;				but we'll leave DEV_SIZE set to the user
;				specification and let him waste memory.
;				We set INIT_DRIVE to 2 because we're not
;				sure what to do and this is safe and we're done.
;				NOTE that this drive will get re-initialized
;				on EVERY re-boot. Tough cookies.
;			ELSE
;				SHRINK the allocation block by adding
;				the extra memory back onto EMM_AVAILK
;				and subtracting it from EMM_KSIZE. Set
;				INIT_DRIVE to 2 because we changed the
;				allocation block size, and we're done.
;
;	ENTRY:
;	     SECTOR_BUFFER containes POSSIBLE EMM_CTRL sector
;		  MUST BE CHECKED
;	     EXT_K is set to size of extended memory
;	     DEV_SIZE is set to user requested device size
;	EXIT:
;	    CARRY SET
;		Error, message already printed
;	    CARRY CLEAR
;		ES:DI = BASE_ADDR for this drive from EMM_BASE of EMM_REC
;		EMM_REC is marked EMM_ISDRIVER
;		SECTOR_BUFFER must be written out, it contains an updated
;			 EMM_CTRL sector
;		DEV_SIZE set to TRUE size
;		Zero SET
;		    An existing disk was found, region should be checked
;			for valid MS-DOS volume
;		Zero RESET
;		    A new block was allocated from the EMM_CTRL sector
;		TERM_ADDR may be adjusted to include RESET_SYSTEM code and
;		    INT 19 and 9 vector patched if this is the first
;		    TYPE 1 or TYPE 3 RAMDrive in the system (no other
;		    EMM_MSDOS EMM_REC structures marked EMM_ISDRIVER).
;
;	USES:
;	    ALL but DS
;
;	Specific to TYPE 1 and 3 drivers
;

FIND_VDRIVE:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET SECTOR_BUFFER
	MOV	SI,OFFSET EMM_CONTROL
	MOV	CX,50
	CLD
	REPE	CMPSB
	JNZ	no_emm_rec		; No EMM_CTRL
	ADD	SI,EMM_TAIL_SIG - 50
	ADD	DI,EMM_TAIL_SIG - 50
	MOV	CX,10
	REPE	CMPSB
	jnz	no_emm_rec
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	 JNZ	 SETCTRL		 ; No EMM_CTRL
;	 MOV	 DI,OFFSET SECTOR_BUFFER
;	 MOV	 AX,[EXT_K]
;	 DEC	 AX		 ; Size in EMM_CTRL doesn't include EMM_CTRL
;	 CMP	 AX,[DI.EMM_TOTALK]
;	 JZ	 SCAN_DEV		 ; EMM_CTRL is valid
;SETCTRL:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
	dec	[valid_emm]		; signal prescence of emm record
no_emm_rec:
;
; we have to decide which standard to use for installing the driver, the old or
; the new. driver type 3 - old, driver type 2 not u - new, u driver - old
;
    ;
    ;	check if driver in extended
    ;
	cmp	[driver_sel],0		; if driver not in extended memory
	jne	old_st			; install according to old standard
	cmp	[u_switch],0h		  ; is it a u driver
	jne	old_st			; if not go to install acc to new int15
	jmp	new_st			; standard
;
; for olivetti u memory we still have to install according to ol' microsoft st
;
old_st:
	cmp	[valid_emm],0h		; do we have a valid emm
	jne	scan_dev		; if yes go to scan structures
set_ctrl:				 ; else we have to install a new one
	MOV	DI,OFFSET SECTOR_BUFFER
	PUSH	DI
	MOV	SI,OFFSET EMM_CONTROL
	MOV	CX,1024/2
	REP	MOVSW		; Move in initial EMM_CTRL
	POP	DI
	MOV	AX,[EXT_K]
	DEC	AX		; Size in EMM_CTRL doesn't include EMM_CTRL
	MOV	[DI.EMM_TOTALK],AX
	MOV	[DI.EMM_AVAILK],AX
SCAN_DEV:
	XOR	BX,BX		; Will get tripped if a DOS dev found
	MOV	SI,OFFSET SECTOR_BUFFER ; DS:SI points to EMM_CTRL
	MOV	DI,SI
	ADD	DI,EMM_RECORD	      ; DS:DI points to EMM records
	MOV	CX,EMM_NUMREC
LOOK_REC:
	TEST	[DI.EMM_FLAGS],EMM_ALLOC
	JNZ	CHECK_SYS
	JMP	GOT_FREE_REC		; Must alloc new region

CHECK_SYS:
	CMP	[DI.EMM_SYSTEM],EMM_MSDOS
	JNZ	NEXTREC 		; Not MS-DOS
	TEST	[DI.EMM_FLAGS],EMM_ISDRIVER
	JNZ	NEXTRECI		; Driver already in, I am not first driver
	CALL	SET_RESET		; Set up INT 19,9 as per BX
	MOV	AX,[DI.EMM_KSIZE]
	CMP	CX,1
	JBE	OK_SET_DEV		; If this is last record, must
					;   select this size
	CMP	AX,[DEV_SIZE]
	JZ	OK_SET_DEV		; Exact match, Okay
	JB	INSUFF_MEM		; User asked for more
    ; Size of found block is bigger than requested size.
    ;	User MUST have edited CONFIG.SYS.
	PUSH	DI
	ADD	DI,SIZE EMM_REC
	TEST	[DI.EMM_FLAGS],EMM_ALLOC
	POP	DI
	JZ	SHRINK_BLOCK	; Next block is free, shrink
	MOV	AX,[DEV_SIZE]
	JMP	SHORT SET_2

SHRINK_BLOCK:
	SUB	AX,[DEV_SIZE]	; AX is amount to shrink
	ADD	[SI.EMM_AVAILK],AX
	MOV	AX,[DEV_SIZE]
	MOV	[DI.EMM_KSIZE],AX
	JMP	SHORT SET_2

INSUFF_MEM:			; Size of found block is smaller
				;   than requested size.
	PUSH	DI
	ADD	DI,SIZE EMM_REC
	TEST	[DI.EMM_FLAGS],EMM_ALLOC
	POP	DI
	JNZ	OK_SET_DEV	; Next block is NOT free, can't grow
TRY_TO_GROW_BLOCK:
	CMP	[SI.EMM_AVAILK],0
	JZ	OK_SET_DEV	; Need SPECIAL check for this case so
				;  that INIT_DRIVE doesn't get set to 2
				;  when it shouldn't
	SUB	AX,[DEV_SIZE]
	NEG	AX		; AX is amount we would like to grow
	SUB	[SI.EMM_AVAILK],AX
	JNC	GOT_THE_MEM
	ADD	AX,[SI.EMM_AVAILK]    ; AX is MAX we can grow
	MOV	[SI.EMM_AVAILK],0     ; We take all that's left
GOT_THE_MEM:
	ADD	[DI.EMM_KSIZE],AX
	MOV	AX,[DI.EMM_KSIZE]
SET_2:
	MOV	[INIT_DRIVE],2	; CANNOT TRUST BPB in boot sector
OK_SET_DEV:
	MOV	[DEV_SIZE],AX
	OR	[DI.EMM_FLAGS],EMM_ISDRIVER
	LES	DI,[DI.EMM_BASE]
	XOR	AX,AX			; Set zero, clear carry
	RET

NEXTRECI:
	INC	BX			; Flag that we ARE NOT first DOS device
NEXTREC:
	ADD	DI,SIZE EMM_REC       ; Next record
	LOOP	LOOK_RECJ
VERRR:
	MOV	DX,OFFSET ERRMSG2
	CALL	PRINT
	STC
	RET

LOOK_RECJ:
	JMP	LOOK_REC

GOT_FREE_REC:
	MOV	AX,[SI.EMM_AVAILK]
	CMP	AX,16
	JB	VERRR			; 16K is smallest device
	CALL	SET_RESET		; Set INT 19,9 as per BX
	CMP	AX,[DEV_SIZE]
	JBE	GOTSIZE 		; Not enough for user spec
	MOV	AX,[DEV_SIZE]		; User size is OK
GOTSIZE:
	MOV	[DEV_SIZE],AX
	SUB	[SI.EMM_AVAILK],AX
	MOV	[DI.EMM_KSIZE],AX
	MOV	[DI.EMM_SYSTEM],EMM_MSDOS
	MOV	[DI.EMM_FLAGS],EMM_ALLOC + EMM_ISDRIVER
	PUSH	DI
	SUB	DI,SIZE EMM_REC       ; Look at prev record to compute base
	MOV	AX,[DI.EMM_KSIZE]
	LES	BX,[DI.EMM_BASE]
	MOV	DI,ES			; DI:BX is prev base
	MOV	CX,1024
	MUL	CX			; Mult size by 1024 to get # bytes
	ADD	AX,BX			; Add size onto base to get next base
	ADC	DX,DI
	POP	DI
	MOV	WORD PTR [DI.EMM_BASE],AX
	MOV	WORD PTR [DI.EMM_BASE + 2],DX
	LES	DI,[DI.EMM_BASE]
	XOR	AX,AX			; Set zero, clear carry
	INC	AX			; RESET zero
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; the new int15 standard
;
new_st:
	dec	[new_all]		; indicate new standard allocation
	mov	bx,[ext_k]		; contiguous memory reported by int15
	cmp	[valid_emm],0		; is there a valid emm record
	je	no_adjust		; if not there no need to adjust
					; the memory available
; else we have to find how much memory is already allocated by the microsoft
; emm control block and subtract this from the amount that is available. the
; memory allocated is totalk - availk + 1
;
	sub	bx,1			; subtract the emm ctrl record size
	mov	di,offset sector_buffer  ; set up to address the ctrl record
					; read in
	mov	ax,[di.emm_totalk]	; ax <- totalk
	sub	ax,[di.emm_availk]	; ax <- totalk - availk
	sub	bx,ax			; adjust memory available
	jc	verrr			; if no memory go to abort
;
	cmp	bx,128			; is it the minimum required
	jb	verrr			; if less go to abort
;
; the memory available has been found and is in bx. now compare it with
; requested device size and take the minimum of the two
;
no_adjust:
	cmp	[dev_size],bx		;
	jb	skip_adj_dev_size	; if enough space we don't need to adj
					; dev_size
	mov	[dev_size],bx		; else we have compromise on dev size
skip_adj_dev_size:
;
; now that we have the correct dev size we should proceed with the installation
; of a new int 15 handler which will account for the memory grabbed by this guy
;
	mov	bx,[ext_k]		; get memory which was reported by int15
	add	bx,[special_mem]	; account for olivetti guys
	sub	bx,[dev_size]		;
	mov	[int15_size],bx 	; this is the size thaat will be reported
					; by the int 15 handler
; now install the int15 handler
;
	push	ax
	push	dx
	push	bx
	push	es
	mov	ax,(get_interrupt_vector shl 8) or 15h
	int	21h
	mov	word ptr [old_15],bx
	mov	word ptr [old_15+2],es
	mov	dx,offset int_15
	mov	ax,(set_interrupt_vector shl 8) or 15h
	int	21h
	pop	es
	pop	bx
	pop	dx
	pop	ax
;
;	set up int19 vector
;
	xor	bx,bx		    ; for int19 to be installed
	call	set_reset
;
;	now fill device base address in es:di
;
	mov	ax,[ext_k]
	sub	ax,[dev_size]	    ; this now has memory left
	mov	cx,1024 	    ; we are going to find size in bytes
	mul	cx		    ; dx:ax = ax * 1024
	add	ax,word ptr [base_addr]      ;
	adc	dx,word ptr [base_addr+2]    ;
	mov	es,dx		    ;
	mov	di,ax		    ;
	xor	ax,ax		    ; to say that there
	inc	ax		    ; was no dos volume reset 0
	ret

;**	SET_RESET - Set up INT 19/INT 9 vectors
;
;	This routine will do nothing if BX is non-zero
;	otherwise it will install the INT 9 and INT 19
;	code by saving the current INT 9 and INT 19
;	vectors in OLD_9 and OLD_19 (NOTE: the change in the value of OLD_19
;	to something other than -1 indicates that the vectors have been
;	replaced), setting the vectors to point to INT_9 and INT_19,
;	and adjusting TERM_ADDR to include the code as part of the resident
;	image.
;
;	ENTRY:
;	     BX is 0 if INT 19/9 code to be installed
;	EXIT:
;	     NONE
;	USES:
;	     None
;
;	COMMON TO TYPE 1, 2, 3, 4 drivers
;

SET_RESET:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	OR	BX,BX
	JNZ	RET005
	cmp	[u_switch],0		; for uswitch don't bother
	jne	ret005
	PUSH	AX
	PUSH	DX
	PUSH	BX
	PUSH	ES
	MOV	AX,(Get_Interrupt_Vector SHL 8) OR 19H
	INT	21H
	MOV	WORD PTR [OLD_19],BX
	MOV	WORD PTR [OLD_19 + 2],ES
	MOV	DX,OFFSET INT_19
	MOV	AX,(Set_Interrupt_Vector SHL 8) OR 19H
	INT	21H
;	 MOV	 AX,(Get_Interrupt_Vector SHL 8) OR 9H
;	 INT	 21H
;	 MOV	 WORD PTR [OLD_9],BX
;	 MOV	 WORD PTR [OLD_9 + 2],ES
;	 MOV	 DX,OFFSET INT_9
;	 MOV	 AX,(Set_Interrupt_Vector SHL 8) OR 9H
;	 INT	 21H
	MOV	WORD PTR [TERM_ADDR],OFFSET RESET_INCLUDE
	POP	ES
	POP	BX
	POP	DX
	POP	AX
RET005:
	RET

BREAK	</E INIT Code>

;**	AT_EXT_INIT - Perform /E (TYPE 1) specific initialization
;
;	This code does the drive TYPE specific initialization for TYPE 1
;	drivers.
;
;	Make sure running on 80286 IBM PC-AT compatible system by
;		making sure the model byte at FFFF:000E is FC.
;	Get the size of extended memory by using 8800H call to INT 15.
;		and make sure it is big enough to accomodate a RAMDrive.
;	Limit DEV_SIZE to the available memory found in the previous step
;		by making DEV_SIZE smaller if necessary.
;	Initialize the GLOBAL parts of the LOADALL information which
;		are not set by each call to BLKMOV.
;	CALL MM_SETDRIVE to look for EMM_CTRL and perform all the
;		other initialization tasks.
;
;	ENTRY:
;	    Invokation line parameter values set.
;	EXIT:
;	    CARRY SET
;		Error, message already printed. Driver not installed.
;			EMM_CTRL not marked (but MAY be initialized if
;			a valid one was not found).
;	    CARRY CLEAR
;		BASE_ADDR set for this drive from EMM_BASE of EMM_REC
;		BASE_RESET set from BASE_ADDR
;		EMM_REC is marked EMM_ISDRIVER
;		DEV_SIZE set to TRUE size
;		INIT_DRIVE set appropriatly
;		TERM_ADDR set to correct device end.
;		    RESET_SYSTEM code and INT 9/INT 19 code included,
;		    INT 19 and 9 vector patched if this is the first
;		    TYPE 1 RAMDrive in the system.
;
;	USES:
;	    ALL but DS
;
;	Code is specific to TYPE 1 driver
;

AT_EXT_INIT:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
	push	ds
	call	sys_det 	; new routine to do more comprehensive checking
	pop	ds
	jnc	at001		; sp
;
	MOV	DX,OFFSET BAD_AT
ERR_RET:
	CALL	PRINT
	STC
	RET

AT001:
;; patch the values of base_reset and base_addr to get the addressing right.
;;
	cmp	[U_SWITCH],0		;; patch the code for /U option
	jz	AT001A
	mov	ax,00fah
;	mov	word ptr [emm_ctrl_addr+2],ax	;; in resident part for reset code
	mov	word ptr [base_reset+2],ax	;; patching upper address
	mov	word ptr [base_addr+2],ax	;;   to FA from 10
AT001A:
	MOV	AX,8800H
	INT	15H		; Get extended memory size
	MOV	DX,OFFSET NO_MEM
	OR	AX,AX
	JZ	ERR_RET

;; If running on a 6300 PLUS, it is necessary to subtract any upper extended
;; memory from the value obtained by int 15 to determine the correct memory
;; available for a type /E RAMDrive.  If loading a /U RAMDrive, it is necessary
;; to find out if there IS any upper extended memory.

	cmp	[U_SWITCH],0		;; did we ask for upper extended memory
	jz	olstuff			;; no
	call	UpperMemCheck		;; yes, see if anything there
	jc	ERR_RET			;; no, quit
	mov	ax,384			;; yes, but max allowed is 384K
	jmp short at001b
olstuff:
	cmp	[S5_FLAG],S_OLIVETTI	;; if not 6300 PLUS, go on
	jne	at001b
	call	UpperMemCheck		;; yes, see if 384K is there
	jc	at001b			;; no, so int 15h is right
	sub	ax,384			;; yes, subtract 384K
	mov	[special_mem],384	;; store special memory size
AT001B:

	MOV	DX,OFFSET ERRMSG2
	cmp	ax,16
;	CMP	AX,17		; 1k ident block plus 16k min Ramdrive
	JB	ERR_RET
	MOV	[EXT_K],AX
	MOV	BX,AX
;	DEC	BX		; BX is MAX possible disk size
	CMP	[DEV_SIZE],BX
	JBE	AT002		; DEV_SIZE OK
	MOV	[DEV_SIZE],BX	; Limit DEV_SIZE to available
AT002:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 386 modification
	test	[sys_flg],M_386
	je	loadall_setup
	mov	ax,cs
	mov	word ptr [cod_seg],ax
; set cs descriptor
	mov	cx,16
	mul	cx
	mov	si,offset cs_des
	mov	[si].bas_0_15,ax
	mov	[si].bas_16_23,dl
	mov	[si].bas_24_31,dh
; set gdt base
	mov	si,offset emm_gdt
	add	ax,offset start_gdt
	adc	dx,0
	mov	[si].gdt_base_0,ax
	mov	[si].gdt_base_2,dx
	jmp	common_setup
;
loadall_setup:
    ;
    ; Init various pieces of LOADALL info
    ;
;;;;	    SMSW    [LDSW]
;;;;	    SIDT    QWORD PTR [IDTDES]
;;;;	    SGDT    QWORD PTR [GDTDES]
;;;;	;
;;;;	; NOW The damn SXXX instructions store the desriptors in a
;;;;	;     different order than LOADALL wants
;;;;	;
;;;;	    MOV     SI,OFFSET IDTDES
;;;;	    CALL    FIX_DESCRIPTOR
;;;;	    MOV     SI,OFFSET GDTDES
;;;;	    CALL    FIX_DESCRIPTOR
	MOV	[LCSS],CS
	MOV	SI,OFFSET CSDES
	MOV	AX,CS
	CALL	SEG_SET
common_setup:
	CALL	MM_SETDRIVE
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;* UpperMemCheck - Called by 6300 PLUS to verify existence of
;;		    upper extended memory of 384K at FA0000h
;;
;;	Returns carry set if no upper extended memory.
;;
;;	This routine is called only by a 6300 PLUS, and
;;	it reads the hardware switch DSW2 to do the job.
;;
UpperMemCheck:
	push	ax
	in	al,66h
	and	al,00001111b
	cmp	al,00001011b
	pop	ax
	jnz	nomem
	clc
	ret
nomem:
	stc
	ret



BREAK	</A INIT Code>

;**	EMM device driver name
;
;	The following datum defines the Above Board EMM 8 character
;	device driver name that is looked for as part of TYPE 2
;	specific initialization.
;
;	This datum is specific to TYPE 2 drivers
;

ABOVE_DEV_NAME	DB	"EMMXXXX0"

;**	ABOVE_INIT - Perform /A (TYPE 2) specific initialization
;
;	This code performes the driver specific initialization for
;	type 2 drivers.
;
;	Swap ABOVE_BLKMOV code in for TYPE 1 code at BLKMOV
;	Swap ABOVE_RESET code in for TYPE 1 code at RESET_SYSTEM
;	Check to make sure EMM Above Board device driver is installed
;		by looking for device name relative to INT 67H segment
;		address. This is method 2 described on page 36 and 37
;		of the Expanded Memory Manager Programming Specification.
;
;		WARNING! If run on a version of DOS where all INT vectors
;		are managed by the kernel, or on a system where some
;		foreign program (not EMM.SYS) is also using INT 67H, this
;		method will fail to find the EMM device driver.
;		The reason this method was used rather than the more portable
;		method 1 described on pages 33 and 34 of the EMM Programming
;		Specification is that the DOS Installable Device Driver
;		document makes a statement about which DOS system calls
;		may be made in a device initialization routine, and
;		OPEN, IOCTL, and CLOSE are not included in the allowed
;		set. Adherance to the Installable Device Driver document,
;		therefore, excludes the use of method 1.
;
;	Check the EMM device status
;	Get the EMM map window address and set BASE_ADDR
;	Get the available Above Board memory
;	Adjust DEV_SIZE to be consistent with the available memory if needed,
;		and also round DEV_SIZE up so that it is a multiple of the 16K
;		granularity of the Above Board memory.
;	Allocate DEV_SIZE worth of Above Board memory and set ABOVE_PID.
;		After this point we can use CTRL_IO and/or BLKMOV to
;		read/write the memory we have allocated.
;	Install the INT 9 and INT 19 code by calling SET_RESET with BX = 0.
;	Adjust the TERM_ADDR set by SET_RESET to a more appropriate size.
;	Call CHECK_DOS_VOL to look for a DOS volume and set INIT_DRIVE.
;	IF INIT_DRIVE indicates that a DOS volume was found
;		Check to make sure that the size of the found DOS
;		volume is consistent with DEV_SIZE.
;		IF it is not
;			Set INIT_DRIVE to 2 to indicate that the found volume
;				is invalid and needs to be re-initialized.
;
;	SEE ALSO
;	    INTEL Expanded Memory Manager Programming Specification
;
;	ENTRY:
;	    Invokation line parameter values set.
;	EXIT:
;	    ABOVE_BLKMOV code swapped in at BLKMOV
;	    ABOVE_RESET code swapped in at RESET_SYSTEM
;	    CARRY SET
;		Error, message already printed. Driver not installed.
;			No Above Board memory allocated.
;	    CARRY CLEAR
;		BASE_ADDR set to segment address of Above Board map window
;		ABOVE_PID contains PID of allocated above board memory
;		DEV_SIZE set to TRUE size
;		INIT_DRIVE set appropriatly
;		TERM_ADDR set to correct device end.
;		    RESET_SYSTEM code and INT 9/INT 19 code included.
;
;	USES:
;	    ALL but DS
;
;	Code is specific to TYPE 2 driver
;

ABOVE_INIT:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
    ;
    ; Swap above code into place
    ;
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET ABOVE_CODE
	MOV	DI,OFFSET DRIVE_CODE
	MOV	CX,OFFSET DRIVE_END - OFFSET DRIVE_CODE
	REP	MOVSB
	MOV	SI,OFFSET ABOVE_RESET
	MOV	DI,OFFSET RESET_SYSTEM
	MOV	CX,OFFSET RESET_INCLUDE - OFFSET RESET_SYSTEM
	REP	MOVSB
    ;
    ; Check for presence of Above board memory manager
    ;
	MOV	AX,(Get_Interrupt_Vector SHL 8) OR 67H
	INT	21H
	MOV	DI,SDEVNAME
	MOV	SI,OFFSET ABOVE_DEV_NAME
	MOV	CX,8
	REPE	CMPSB
	JZ	GOT_MANAGER
	MOV	DX,OFFSET NO_ABOVE
ABOVE_ERR:
	CALL	PRINT
	STC
	RET

GOT_MANAGER:
    ;
    ; Check memory status
    ;
	MOV	CX,8000H
STLOOP:
	MOV	AH,ABOVE_STATUS
	INT	67H
	CMP	AH,ABOVE_SUCCESSFUL
	JZ	MEM_OK
	CMP	AH,ABOVE_ERROR_BUSY
	LOOPZ	STLOOP
ST_ERR:
	MOV	DX,OFFSET BAD_ABOVE
	JMP	ABOVE_ERR

MEM_OK:
    ;
    ; Get base address of map region and set BASE_ADDR
    ;
	MOV	AH,ABOVE_GET_SEG
	INT	67H
	CMP	AH,ABOVE_ERROR_BUSY
	JZ	MEM_OK
	CMP	AH,ABOVE_SUCCESSFUL
	JNZ	ST_ERR
	MOV	WORD PTR [BASE_ADDR],0
	MOV	WORD PTR [BASE_ADDR + 2],BX
    ;
    ; Allocate drive memory
    ;
GET_AVAIL:
	MOV	AH,ABOVE_GET_FREE
	INT	67H
	CMP	AH,ABOVE_ERROR_BUSY
	JZ	GET_AVAIL
	CMP	AH,ABOVE_SUCCESSFUL
	JNZ	ST_ERR
	MOV	AX,DX		; AX is total 16K pages
				; BX is un-allocated 16K pages
	MOV	DX,OFFSET NO_MEM
	OR	AX,AX
	JZ	ABOVE_ERR
	MOV	DX,OFFSET ERRMSG2
	OR	BX,BX		; 16k is min Ramdrive
	JZ	ABOVE_ERR
	TEST	BX,0F000H
	JNZ	AB001		; Avialable K is REAL big
	MOV	CX,4
	SHL	BX,CL		; BX is un-allocated K
	CMP	[DEV_SIZE],BX
	JBE	AB001		; DEV_SIZE OK
	MOV	[DEV_SIZE],BX	; Limit DEV_SIZE to available
AB001:
	MOV	BX,[DEV_SIZE]
    ;
    ; BX is K we want to allocate (limited by available K)
    ;  BX is at least 16
    ;
	MOV	AX,BX
	MOV	CX,4		; Convert back to # of 16K pages
	SHR	BX,CL
	TEST	AX,0FH		; Even????
	JZ	OKAYU		; Yes
	INC	BX		; Gotta round up
	PUSH	BX
	MOV	CX,4
	SHL	BX,CL
	MOV	[DEV_SIZE],BX	; Correct dev size too by rounding it up to
				;   next multiple of 16K, no sense wasting
				;   part of a page.
	POP	BX
OKAYU:
	MOV	AH,ABOVE_ALLOC
	INT	67H
	CMP	AH,ABOVE_ERROR_BUSY
	JZ	OKAYU
	CMP	AH,ABOVE_SUCCESSFUL
	JZ	GOT_ID
	CMP	AH,ABOVE_ERROR_MAP_CNTXT
	JZ	ST_ERRJ
	CMP	AH,ABOVE_ERROR_OUT_OF_PIDS
	JB	ST_ERRJ
	MOV	DX,OFFSET ERRMSG2
	JMP	ABOVE_ERR

ST_ERRJ:
	JMP	ST_ERR

GOT_ID:
	MOV	[ABOVE_PID],DX
    ;
    ; INSTALL ABOVE RESET handler
    ;
	XOR	BX,BX
	CALL	SET_RESET
    ;
    ; The above RESET_SYSTEM handler is real small, and since we include it in
    ;	EACH driver, we make sure the size is minimal
    ;
	MOV	WORD PTR [TERM_ADDR],OFFSET RESET_SYSTEM + (OFFSET ABOVE_RESET_END - OFFSET ABOVE_RESET)
    ;
    ; We are now in good shape. Can call BLKMOV to read drive
    ;
	CALL	CHECK_DOS_VOL		; Snoop for DOS volume
	JNC	DOUBLE_CHECK
	CALL	DISK_ABORT
	STC
	RET

DOUBLE_CHECK:
	CMP	[INIT_DRIVE],0
	JNZ	RETAB			; No DOS volume found
    ;
    ; We MUST check to see if the FOUND DOS volume is consistent
    ;	with DEV_SIZE.
    ;
	MOV	AX,[SECLIM]
	MUL	[SSIZE] 		; DX:AX is size of volume in bytes
	MOV	CX,1024
	DIV	CX			; AX is size in K
	CMP	AX,[DEV_SIZE]
	JE	RETAB			; Volume is OK
RE_INIT:
	MOV	[INIT_DRIVE],2		; Force re-compute of volume
RETAB:
	CLC
	RET

BREAK	<Drive code for /A driver. Swapped in at BLKMOV>

;
; This label defines the start of the code swapped in at DRIVE_CODE
;
ABOVE_CODE	LABEL	WORD

;
; WARNING DANGER!!!!!!!
;
; This code is tranfered over the /E driver code at DRIVE_CODE
;
; ALL jmps etc. must be IP relative.
; ALL data references must be to cells at the FINAL, TRUE location
;	(no data cells may be named HERE, must be named up at BLKMOV).
; OFFSET of ABOVE_BLKMOV relative to ABOVE_CODE MUST be the same as
;	the OFFSET of BLKMOV relative to DRIVE_CODE.
; SIZE of stuff between ABOVE_CODE and ABOVE_END MUST be less than
;	or equal to size of stuff between DRIVE_CODE and DRIVE_END.

IF2
  IF((OFFSET ABOVE_BLKMOV - OFFSET ABOVE_CODE) NE (OFFSET BLKMOV - OFFSET DRIVE_CODE))
	  %out ERROR BLKMOV, ABOVE_BLKMOV NOT ALIGNED
  ENDIF
  IF((OFFSET ABOVE_END - OFFSET ABOVE_CODE) GT (OFFSET DRIVE_END - OFFSET DRIVE_CODE))
	  %out ERROR ABOVE CODE TOO BIG
  ENDIF
ENDIF

		DD	?	; 24 bit address of start of this RAMDRV
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;**	ABOVE_BLKMOV - Perform transfer for TYPE 2 driver
;
;	This routine is the transfer routine for moving bytes
;	to and from the Above Board memory containing the cache.
;
;	The Above Board is implemented as 4 16K windows into the Above
;	Board memory, giving a total window of 64K wich starts on some
;	16K boundary of the Above Board memory. Given that a DOS I/O
;	request is up to 64K bytes starting on some sector boundary,
;	the most general I/O picture is:
;
;	|------------|------------|------------|------------|------------|
;	| Above Brd  | Above Brd  | Above Brd  | Above Brd  | Above Brd  |
;	|Log page n  |Log page n+1|Log page n+2|log page n+3|Log page n+4|
;	|------------|------------|------------|------------|------------|
;	|---|---|					    |	    |
;	|   |	|---------------- 64K bytes of sectors -------------|
;	   Byte |					    |	    |
;	  offset|------------------|------------------------|	    |
;	of first|	       Number of words in	    |	    |
;	byte of |	       first part of I/O that	    |---|---|
;	I/O in	|	       can be performed once	      Number
;	first	|	       logical pages n - n+3	      of words
;	Log page|	       are mapped into physical       in tail
;		|	       pages 0 - 3		      part of I/O
;	     Location of				      that have
;	     first byte 				      to be done
;	     of sector M,				      once logical
;	     the start sector				      page n+4 is
;	     of the I/O 				      mapped into
;							      physical page
;							      0
;
; One or both of "Byte offset of first byte of I/O in first page" and
; "Number of words in tail part of I/O" may be zero depending on the
; size of the I/O and its start offset in the first logical page it is
; possible to map.
;
; WARNING: IF A PRE-EMPTIVE MULTITASKING SYSTEM SCHEDULES A TASK WHICH
;	IS USING THE ABOVE BOARD DURING THE TIME THIS DRIVER IS IN THE
;	MIDDLE OF PERFORMING AN I/O, THE SYSTEM HAD BETTER MANAGE THE A
;	BOARD MAPPING CONTEXT CORRECTLY OR ALL SORTS OF STRANGE UNPLEASANT
;	THINGS WILL OCCUR.
;
;	SEE ALSO
;	    INTEL Expanded Memory Manager Programming Specification
;
;	ENTRY:
;	    ES:DI is packet transfer address.
;	    CX is number of words to transfer.
;	    DX:AX is 32 bit start byte offset (0 = start of cache)
;	    BH is 1 for WRITE, 0 for READ
;
;	    BASE_ADDR set to point to Above Board mapping window in main memory
;		This "input" is not the responsibility of the caller. It
;		is up to the initialization code to set it up when the
;		device is installed
;
;	EXIT:
;	    Carry Clear
;		    OK, operation performed successfully
;	    Carry Set
;		    Error during operation, AL is error number
;
;	USES:
;	    ALL
;
;	This routine is specific to TYPE 2 driver
;
;	sunilp - note that this has one limitation. in the case where
;		 one is using the above board for ramdrive and for
;		 the buffer then one is limited to 32k byte transfers
;
;	tonyg	- above limitation removed - now handles 64kb transfers
;		  which can overlap the page frame
;
above_blkmov:
assume ds:ramcode,es:nothing,ss:nothing
;
;	save mapping context and return with error if save fails
;
	save_mapping_context
	jnc	ab_blk$1
	ret
;
;	find logical page number, offset of i/o in first page
;
ab_blk$1:
	push	cx
	mov	cx,1024*16	; 16k bytes / page
	div	cx		; dx:ax / 16k --> log page numb in ax
				; 	      --> offset of i/o in dx
	mov	si,dx		; transfer offset to si
	mov	dx,ax		; store the page number in dx
	pop	cx
;
;	find case and dispatch accordingly
;
;	case 0 : user buffer below page map, can use aaron's code
;	case 1 : user buffer above page map, can use aaron's code
;	case 2 : user buffer partly/totally in page map, use pai's code
;
	push	bx
	push	cx
;
;	if( final_user_off < pm_base_addr ) then case 0
;
	mov	ax,di		; get user buffer initial offset into ax
	add	ax,1		; round up (add to get carry)
	rcr	ax,1		; convert to word offset
	dec	cx		; convert word count to 0 based number
	add	ax,cx		; user buffer final word offset
	shr	ax,1		; convert to segment
	shr	ax,1		;
	shr	ax,1		;
	mov	bx,es		; get segment of buffer
	add	ax,bx		; now we have the last segment of the user buffer
				; with offset < 16
	sub	ax,word ptr [base_addr+2] ; compare against page map
	jc	aar_cd		; if end below page map then execute old code
;
;	if( initial_user_off < pm_base_addr ) then case 2
;	
	mov	cx,4
	mov	bp,di		; get initial segment in bp
	shr	bp,cl		;
	add	bp,bx		;
	sub	bp,word ptr [base_addr +2]
	jc	within_pm	; case 2
;
;	if ( initial_user_off >= pm_end_addr ) then case1
;
	cmp	bp,4*1024	;
	jae	aar_cd		; case 1
;
;	case 2
;
within_pm:	jmp	new_code	; user buffer in page map
					; so we need to execute new code
aar_cd:
	pop	cx
	pop	bx
;	
; Referring back to the diagram given above the following routine is
; to take care of transfer of the most general case.
; What this routine does is break every I/O down into the above parts.
; The first or main part of the I/O is performed by mapping 1 to 4
; sequential logical pages into the 4 physical pages and executing one
; REP MOVSW. If the tail word count is non-zero then the fith sequential
; logical page is mapped into physical page 0 and another REP MOVSW is
; executed.
;
;	METHOD:
;	    Break I/O down as described above into main piece and tail piece
;	    Map the appropriate number of sequential pages (up to 4)
;	      into the page window at BASE_ADDR to set up the main piece
;	      of the I/O.
;	   Set appropriate seg and index registers and CX to perform the
;	      main piece of the I/O into the page window
;	   REP MOVSW
;	   IF there is a tail piece
;		Map the next logical page into physical page 0
;		Reset the appropriate index register to point at phsical page 0
;		Move tail piece word count into CX
;		REP MOVSW
;	   Restore Above Board page mapping context
;
	XOR	BP,BP		; No tail page
	PUSH	BX
    ;
    ; DX is first page #, SI is byte offset of start of I/O in first page
    ;
	MOV	AX,DX
	MOV	BX,SI
	SHR	BX,1		; # Words in first 16k page which are not part
				;	of I/O
	PUSH	CX
	ADD	BX,CX		; # of words we need to map to perform I/O
	MOV	DX,BX
	AND	DX,1FFFH	; DX is number of words to transfer last page
				;    remainder of div by words in 16K bytes
	MOV	CL,13		; Div by # words in 16K
	SHR	BX,CL		; BX is number of pages to map (may need round up)
	OR	DX,DX		; Remainder?
	JZ	NO_REM
	INC	BX		; Need one more page
NO_REM:
	MOV	CX,BX		; CX is total pages we need to map
	MOV	BX,AX		; BX is first logical page
	CMP	CX,4		; We can map up to 4 pages
	JBE	NO_TAIL
	MOV	BP,DX		; Words to move in tail page saved in BP
	DEC	CX		; Need second map for the 5th page
	POP	AX
	SUB	AX,DX		; Words to move in first 4 pages is input
				;   word count minus words in tail page
	PUSH	AX		; Count for first mapping back on stack
NO_TAIL:
    ; Map CX pages
	MOV	DX,[ABOVE_PID]
	MOV	AX,ABOVE_MAP SHL 8 ; Physical page 0
	PUSH	AX
MAP_NEXT:
	POP	AX		; Recover correct AX register
	PUSH	AX
	PUSH	BX
	PUSH	DX
	INT	67H		; Damn call ABOVE_MAP zaps BX,DX,AX
	POP	DX
	POP	BX
	OR	AH,AH
	JNZ	MAP_ERR1	; error
IF2
	IF (ABOVE_SUCCESSFUL)
		%out ASSUMPTION IN CODE THAT ABOVE_SUCCESSFUL = 0 IS INVALID
	ENDIF
ENDIF
NEXT_PAGE:
	INC	BX		; Next logical page
	POP	AX
	INC	AL		; Next physical page
	PUSH	AX
	LOOP	MAP_NEXT
	POP	AX		; Clean stack
	POP	CX		; Word count for first page mapping
	POP	AX		; Operation in AH
    ;
    ; BX has # of next logical page (Tail page if BP is non-zero)
    ; BP has # of words to move in tail page (0 if no tail)
    ; CX has # of words to move in current mapping
    ; SI is offset into current mapping of start of I/O
    ; AH indicates READ or WRITE
    ;
	PUSH	AX		; Save op for possible second I/O
	OR	AH,AH
	JZ	READ_A
    ;
    ; WRITE
    ;
	PUSH	ES
	PUSH	DI
	MOV	DI,SI		; Start page offset to DI
	POP	SI		; DS:SI is transfer addr
	POP	DS
ASSUME	DS:NOTHING
	MOV	ES,WORD PTR [BASE_ADDR + 2] ; ES:DI -> start
	JMP	SHORT FIRST_MOVE

READ_A:
ASSUME	DS:ramcode
	MOV	DS,WORD PTR [BASE_ADDR + 2]	; DS:SI -> start
ASSUME	DS:NOTHING
FIRST_MOVE:
	REP	MOVSW
	OR	BP,BP		; Tail?
	JNZ	TAIL_IO 	; Yup
ALL_DONE:
	POP	AX
	CLC
REST_CONT:
    ; Restore page mapping context
	PUSH	AX		; Save possible error code
	PUSHF			; And carry state
REST_AGN:
	MOV	DX,[ABOVE_PID]
	MOV	AH,ABOVE_RESTORE_MAP_PID
	INT	67H
	OR	AH,AH
	JZ	ROK
IF2
	IF (ABOVE_SUCCESSFUL)
		%out ASSUMPTION IN CODE THAT ABOVE_SUCCESSFUL = 0 IS INVALID
	ENDIF
ENDIF
	CMP	AH,ABOVE_ERROR_BUSY
	JZ	REST_AGN
	CMP	AH,ABOVE_ERROR_NO_CNTXT
	JZ	ROK		; Ignore the invalid PID error
	POP	DX
	POP	DX		; Clean stack
	MOV	AL,0cH	       ; General failure
	STC
	RET

ROK:
	POPF			; Recover carry state
	POP	AX		; and possible error code
	RET

TAIL_IO:
	MOV	DX,[ABOVE_PID]
MAP_AGN:
	MOV	AX,ABOVE_MAP SHL 8 ; map logical page BX to phys page 0
	PUSH	BX
	PUSH	DX
	INT	67H		; Damn call ABOVE_MAP zaps BX,DX,AX
	POP	DX
	POP	BX
	OR	AH,AH
	JNZ	MAP_ERR2	; Error
IF2
	IF (ABOVE_SUCCESSFUL)
		%out ASSUMPTION IN CODE THAT ABOVE_SUCCESSFUL = 0 IS INVALID
	ENDIF
ENDIF
SECOND_MOVE:
	POP	AX		; Recover Op type
	PUSH	AX
	OR	AH,AH
	JZ	READ_SEC
    ;
    ; WRITE
    ;
	XOR	DI,DI		; ES:DI -> start of tail
	JMP	SHORT SMOVE

READ_SEC:
	XOR	SI,SI		; DS:SI -> start of tail
SMOVE:
	MOV	CX,BP
	REP	MOVSW
	JMP	ALL_DONE

MAP_ERR1:
	CMP	AH,ABOVE_ERROR_BUSY ; Busy?
	JZ	MAP_NEXT	; Yes, wait till not busy (INTs are ON)
	ADD	SP,6		; Clean stack
	JMP	SHORT DNR_ERR

MAP_ERR2:
	CMP	AH,ABOVE_ERROR_BUSY
	JZ	MAP_AGN
	ADD	SP,2
DNR_ERR:
	MOV	AL,02H	       ; Drive not ready
	STC
	JMP	REST_CONT
;
;
;   this code has been written to handle te cases of overlapping usage
;   of the above board page frame segment by the cache and user buffer
;   assumption: in dos tracks cannot be more than 64 sectors long so
;   in the worst case we shall have the user buffer occupying three
;   pages is the page frame. we attempt to find the page that is
;   available for the cache and use it repeatedly to access the cache
;
;   above comment was for smartdrv. 128 sector reads are possible here
;   see the kludge in step 2 and step 4 to handle this


;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;   the algorithm is:
;   ******************************************************
;   [STEP1: determine the page we can use for the cache]
;
;   if (initial_para_offset_user in page 1, 2 or 3 ) then  {
;	    physical_cache_page = 0;
;	    cache_segment	= above board segment;
;		}
;						      else  {
;	    physical_cache_page = 3;
;	    cache_segment	= above_board_segment + 3*1024;
;		}
;
;   ******************************************************
;   [STEP2: initial setup]
;
;   count = user_count_requested;
;   number_to_be_transferred = min ( count, (16K - si) >> 2 );
;   exchange source and destination if necessary;
;
;   *******************************************************
;   [STEP3: set up transfer and do it]
;
;   count = count - number_to_be_transferred;
;   map_page cache_handle,physical_cache_page,logical_cache_page
;   mov data
;
;   *******************************************************
;   [STEP4: determine if another transfer needed and setup if so]
;
;   if ( count == 0 ) then exit;
;   if ( operation == read ) then source_offset = 0;
;			     else dest_offset	= 0;
;   number_to_be_transferred = min ( count, 8*1024 );
;   logical_page_number++ ;
;
;   *******************************************************
;   [STEP5: go to do next block]
;
;   goto [STEP3]
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
new_code:
	assume	ds:ramcode,es:nothing,ss:nothing
;
;	input parameters:
;
;	bp : start para offset of user buffer from start of physical page frame
;	ax : end para offset of user buffer in physical page frame
;	di : transfer offset of user buffer
;	es : transfer segment of user buffer
;	dx : logical page number in cache
;	si : offset from start in logical page number
;
;	on stack { cx,bx } where cx = number of words, bx = read / write status
;
;   [STEP1: finding physical cache page and page frame]
;
    ;
    ; assume is physical page 0
    ;
	xor	al, al		; use page 0 for cache
	mov	bx,word ptr [base_addr+2]
    ;
    ; see if this assumption valid
    ;
	cmp	bp, 4*1024	; base is below start of page frame
	jae	ab$300
	cmp	bp,1024 	; is initial in page 1 or above
	jae	ab$30		; if so or assumption is valid
    ;
    ; else we have to correct our assumption
    ;
ab$300:
	mov	al, 3		; use page 3 for cache
	add	bx, 3*1024	; segment of page 3
    ;
    ; initialise page frame segment
    ;
ab$30:
	add	bp, 2*1024	; base of second transfer
	mov	cx, bp
	mov	ds,bx
    ;
assume	ds:nothing
;
;   [STEP2: initialising transfer parameters]
;
    ;
	pop	bp		; bp will have count of words left to be transferred
	pop	bx		; read / write status
;
; kludged to handle 64k byte transfers
;
	push	cx		; base of second transfer
    ;
    ; initialise the number of words needed for a second transfer to 0
    ;
	xor	cx,cx		;
    ;
    ; compare the number to be transferred to 16k words. any more than this
    ; will have to be done in the second transfer
    ;
	cmp	bp,16*1024	; more than 16k word transfers
	jbe	ab$301		; if not cx is fine
	mov	cx,bp		; else cx = number of words - 16*1024
	mov	bp,16*1024	; and bp = 16*1024
	sub	cx,bp		;
ab$301:
    ;
    ; store this on stack
    ;
	push	cx
;
; end of kludge in step 2
;
	push	bx		; save it back again
	push	dx		; save this too
    ;
    ; initially si offset into logical page, so we can only do 16*1024 - si
    ; byte transfer
    ;
	mov	cx,16*1024
	sub	cx,si
	shr	cx,1		; convert to word count
    ;
    ;	number to be transferred is the minimum of this and the user requested
    ;	count
    ;
	cmp	cx,bp
	jb	ab$31
	mov	cx,bp
    ;
ab$31:
    ;
    ;	see if write, then we have to switch source with destination
    ;
	or	bh,bh
	je	ab$32		; if read we don't have to do anything
				; else we have to switch
	src_dest_switch
ab$32:
    ;
    ;	set direction flag so that we don't have to do it repeatedly
    ;
	cld
;
;   [STEP3: set up transfer and do it]
;
ab$33:
    ;
    ;	update count of words still left to be transferred after this
    ;
	sub	bp,cx
    ;
    ;	map the logical page in cache to the physical page  selected
    ;
	mov	bx,dx		; get logical page into bx
				; al already holds the physical page #
	map_page
	jnc	ab$34		; suceeded ?
    ;
    ; else report error
    ;
	add	sp,6
	stc
	jmp	      restore_mp ; and go to restore page map
ab$34:
    ;
    ; succeeded, do the transfer
    ;
rep	movsw
    ;
;
;   [STEP4: check if transfer done, if not set up for next block]
;   [STEP5: go back to STEP3]
    ;
    ; check if done
    ;
	or	bp,bp		; count 0
	je	ab$40		; yes, go to finish up
    ;
    ;	recover original dx and bx, increment dx and then save both again
    ;
	pop	dx
	pop	bx
	inc	dx
	push	bx
	push	dx
    ;
    ; words to be transferred minimum of count and 8*1024 words
    ;
	mov	cx,8*1024	; 8k words in a page
	cmp	cx,bp		;
	jbe	ab$35		; if below or equal this is what we want
    ;
	mov	cx,bp		; else we can transfer the whole count
ab$35:
    ;
    ; see whether cache src or dest and accordingly reset either si or di
    ;
	or	bh,bh		; read?
	jne	ab$36		; if write go to modify
    ;
    ; read, zero si and go back to step3
    ;
	xor	si,si
	jmp	short ab$33	; to step 3
ab$36:
    ;
    ; write, zero di and go back to step3
    ;
	xor	di,di
	jmp	short ab$33	; to step 3
;
; finishing up we have to restore the page map
;
ab$40:
;
; also kludged to handle 64k byte transfers
;
	pop	dx
	pop	bx
	pop	bp		; number of words for second transfer
	pop	ax		; base of second transfer
	or	bp,bp		; are we done?
	jne	ab$407		; no, we have to do another transfer
	jmp	ab$405		; yes we can go to finish up
ab$407: 			; apologies for such abominations
	push	ax		; dummy transfer base
	xor	cx, cx
	push	cx		; zero count for next time
;
; restore the mapping context
;
	clc
	push	dx		; dx is destroyed by restore mapping context
	restore_mapping_context
	pop	dx		;
	jnc	ab$401
;
; error we should quit here
;
	add	sp, 4		; throw base & count
	ret
;
; we need to save the mapping context again
;
ab$401:
	save_mapping_context
	jnc	ab$406		; if we couldn't save it then error
	add	sp, 4
	ret
;
; reset physical page to be mapped to 0 and ds or es to page map base
; and increment logical page if we have si = 0 (read) or di=0 (write)
;
ab$406:
	mov	cx, word ptr [base_addr+2]
	cmp	ax, 1024	; new base in page 0?
	jb	ab$4060
	cmp	ax, 4*1024
	jae	ab$4060
	xor	ax, ax
	jmp	short ab$4061
ab$4060:
	mov	al, 3
	add	cx, 3*1024
ab$4061:
	or	bh,bh		; read or write?
	jne	ab$402		; if write branch
;
    ;
    ; read, reset ds to base address
    ;
	mov	ds,cx
	mov	cx,16*1024	;
	cmp	si, cx		; at end of page?
	jbe	ab$4030
	inc	dx
	xor	si, si
ab$4030:
	sub	cx,si
	shr	cx,1

ab$403:
	push	bx		; save these
	push	dx
;
	cmp	cx,bp		; is the cx appropriate
	jbe	ab$404		; if yes go to do transfer
	mov	cx,bp		; else cx <--- bp
ab$404:
	jmp	ab$33	  ; and go to do transfer
;
ab$402:
    ;
    ; write, reset es to base address
    ;
	mov	es,cx
	mov	cx,16*1024
	cmp	di, cx
	jb	ab$4020
	xor	di, di
	inc	dx
ab$4020:
	sub	cx,di
	shr	cx,1
	jmp	short ab$403
;
;	add	sp,4
ab$405:
	clc
restore_mp:
	restore_mapping_context
	ret

		DW	?		; SPACE for ABOVE_PID

;
; This label defines the end of the code swapped in at DRIVE_CODE
;
ABOVE_END	LABEL	WORD

BREAK	<Drive code for /A driver. Swapped in at RESET_SYSTEM>


;
; WARNING DANGER!!!!!!!
;
; This code is tranfered over the /E driver code at RESET_SYSTEM
;
; ALL jmps etc. must be IP relative.
; ALL data references must be to cells at the FINAL, TRUE location
;	(no data cells may be named HERE, must be named up at RESET_SYSTEM).
; SIZE of stuff between ABOVE_RESET and ABOVE_RESET_END MUST be less than
;	or equal to size of stuff between RESET_SYSTEM and RESET_INCLUDE.
;
; NOTE: EACH ABOVE BOARD driver has an INT 19 and 9 handler. This is
;	different from /E and RESMEM in which only the first
;	driver has an INT 19 and 9 handler.
;

IF2
  IF((OFFSET ABOVE_RESET_END - OFFSET ABOVE_RESET) GT (OFFSET RESET_INCLUDE - OFFSET RESET_SYSTEM))
	  %out ERROR ABOVE_RESET CODE TOO BIG
  ENDIF
ENDIF

;**	ABOVE_RESET perform TYPE 2 (/A) driver specific reboot code
;
;	This code issues an ABOVE_DEALLOC call for the memory
;	associated with this particular TYPE 2 RAMDrive since the
;	system is being re-booted and the driver is "gone".
;
;	ENTRY
;	    NONE
;	EXIT
;	    NONE
;	USES
;	    NONE
;
; This code is specific to TYPE 2 drivers
;

ABOVE_RESET:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSH	AX
	PUSH	DX
AGAIN_RESET:
	MOV	DX,[ABOVE_PID]
	MOV	AH,ABOVE_DEALLOC	; Close PID
	INT	67H
	CMP	AH,ABOVE_ERROR_BUSY
	JZ	AGAIN_RESET
	POP	DX
	POP	AX
	RET

;
; This label defines the end of the code swapped in at RESET_SYSTEM
;
ABOVE_RESET_END    LABEL   BYTE

BREAK	<RESMEM INIT Code>

;**	RESMEM specific data
;
;	The following datums are specific to the RESMEM (TYPE 3
;	or 4) drivers
;
;	Specific to TYPE 3 or TYPE 4 drivers
;

HIGH_SEG DW	?		; Segment addr of "end of memory" from INT 12

RAMSEG	DW	0		; Segment addr of the start of RAMDrive memory.
				;   Basically a segment register version of
				;   BASE_ADDR

CRTSEG	EQU	0A000H		; Memory past this segment value is RESERVED
				;   Memory scan must stop here.


;**	RESMEM_INIT - Perform RESMEM (TYPE 3 or 4) specific initialization
;
;	This code performs the driver TYPE specific initialization for
;	TYPE 3 and TYPE 4 drivers.
;
;	Memory scan
;	    The method used by this code to "find" valid RAM between
;	    the "end of memory" as determined from the INT 12 memory
;	    size and CRTSEG is to look for memory which will correctly
;	    store data. It looks on 1K boundaries. If the first 2 words
;	    of a 1k block are good, it is assumed that the rest of the
;	    1K block is good without explicitly checking it. The scan
;	    is interested only in the FIRST block it finds. If two
;	    separated (by invalid RAM) blocks of RAM exist in the
;	    above range, the second block WILL NOT be found.
;	    NOTE that this can be fooled by a bad memory chip in
;	    a block of RAM. In this case RAMDrive will use the
;	    memory up to the bad spot and ignore the rest.
;	    Also note that since 16K is the minimum RAMDrive
;	    size, and the EMM_CTRL sector takes 1k, a block
;	    of size < 17K results in an insufficient memory error.
;
;	    Since access to invalid RAM (RAM that isn't present)
;	    results in a parity error, the above scan must be done
;	    with parity checking disabled.
;
;	    Since the ROM BIOS memory initialization code and tests
;	    is only run on the memory indicated by INT 12, one of
;	    the things this code must do when it finds memory "above
;	    INT 12" is make sure all of the parity bits are set correctly.
;	    This is accomplished easily by just copying the memory to
;	    itself.
;
;	    The scan is NON-DESTRUCTIVE so that any data contained in
;	    the memory will not be destroyed.
;
;	    The result of this scan also makes the determination between
;	    a TYPE 3 and TYPE 4 RAMDrive. If memory is found, then we're
;	    TYPE 3. If no memory is found, then we're TYPE 4.
;
;
;	RESMEM_BLKMOV code swapped in at BLKMOV
;	RESMEM_RESET code swapped in at RESET_SYSTEM
;	    NOTE: This step is not needed for a TYPE 4 driver
;		    since TYPE 4 NEVER has an INT 9 or INT 19 handler,
;		    but it isn't harmful either, so we do it always.
;	Issue INT 12 to get size of memory
;	Convert INT 12 result to segment address of first byte after system
;	    memory.
;	IF this segment address is equal to or grater than CRTSEG
;	    There cannot be any memory "above INT 12" so we are TYPE 4.
;	    Skip the memory scan since there is no memory to scan and
;	    go to the TYPE 4 init code at CASE1.
;	Disable parity checking so access to non-existent RAM won't crash
;	    the system.
;	Perform the memory scan. This starts at FOO and ends at HAVE_MEM
;	    if we find some valid memory, or at CASE1 if we don't.
;	  A word about the scan.
;	    There are two cases for valid RAM.
;		1.) Valid memory starts at the INT 12 address
;		2.) There is invalid RAM for a while, then valid RAM starts.
;	    The DX register is used to tell us what is going on. It is
;	    non-zero if we are skipping over invalid RAM looking for
;	    some valid RAM (case 2), or 0 is we have found some valid RAM
;	    (case 1, or case 2 after skipping invalid RAM) and are scanning
;	    to set parity and find the end of the valid RAM.
;	    RAMSEG is given the initial value of 0 to indicate we have not
;	    found the start of a valid block.
;	    When the scan is finished ENABLE_PARITY is called to turn parity
;	    checking back on.
;	IF we have valid RAM and end at HAVE_MEM
;	    We are TYPE 3.
;	    RAMSEG contains the segment address of the start of the block
;	    BX is the segment address of the end of the block
;	    Subtract RAMSEG from BX to get size of region in paragraphs
;	    Convert size in Paragraphs to size in K
;	    Check that size is AT LEAST 17k (minimum size)
;	    Jump to GOT_RESMEM if OK else error
;	    Set EXT_K to size of block
;	    Adjust DEV_SIZE if bigger than EXT_K - 1 (-1 for EMM_CTRL)
;	    Convert RAMSEG to 32 bit address and set it into BASE_ADDR
;		This sets BASE_ADDR to point to EMM_CTRL sector.
;	    Set BASE_RESET to BASE_ADDR plus 1024
;	    Call MM_SETDRIVE to complete TYPE 3 specific initialization
;	ELSE we end up at CASE1
;	    We are TYPE 4.
;	    Set RESMEM_SPECIAL to indicate TYPE 4
;	    Set INIT_DRIVE to 2 (DOS volume MUST be initialized)
;	    Set BASE_ADDR to be the first para boundary after the resident
;		code (which DOES NOT include INT 19/INT 9 code).
;	    Compute TERM_ADDR based on DEV_SIZE Kbytes of device starting at
;		BASE_ADDR.
;	    NOTE: We must make sure the specified DEV_SIZE is reasonable:
;		It must not be bigger than 10 bits (1 Meg)
;			as this is the memory limit of the 8086.
;		It must not be so big that there is less than 48k of system
;			memory after the device is installed.
;			This is checked by computing the segment address
;			of the end of the device and comparing it to the
;			INT 12 memory end address minus 48k worth of paragraphs
;
;	ENTRY:
;	    Invokation line parameter values set.
;	EXIT:
;	    RESMEM_BLKMOV code swapped in at BLKMOV
;	    RESMEM_RESET code swapped in at RESET_SYSTEM
;	    Determination of TYPE 3 or TYPE 4 made by setting RESMEM_SPECIAL
;		if TYPE 4.
;	    CARRY SET
;		Error, message already printed. Driver not installed.
;		    If TYPE 3
;			EMM_CTRL not marked (but MAY be initialized if
;			a valid one was not found).
;	    CARRY CLEAR
;		DEV_SIZE set to TRUE size
;		INIT_DRIVE set appropriatly
;		IF TYPE 3
;		    BASE_ADDR set for this drive from EMM_BASE of EMM_REC
;		    BASE_RESET set from BASE_ADDR
;		    EMM_REC is marked EMM_ISDRIVER
;		    TERM_ADDR set to correct device end.
;			RESET_SYSTEM code and INT 9/INT 19 code included,
;			INT 19 and 9 vector patched if this is the first
;			TYPE 3 RAMDrive in the system.
;		IF TYPE 4
;		    BASE_ADDR set for this drive by computing address of
;			start of memory after RAMDrive code.
;		    BASE_RESET set from BASE_ADDR
;		    TERM_ADDR set to correct device end which includes
;			the memory taken up by the RAMDrive itself.
;
;	USES:
;	    ALL but DS
;
;	Code is specific to TYPE 3 and TYPE 4 drivers
;

RESMEM_INIT:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING
    ;
    ; Swap RESMEM code into place
    ;
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET RESMEM_CODE
	MOV	DI,OFFSET DRIVE_CODE
	MOV	CX,OFFSET DRIVE_END - OFFSET DRIVE_CODE
	REP	MOVSB
	MOV	SI,OFFSET RESMEM_RESET
	MOV	DI,OFFSET RESET_SYSTEM
	MOV	CX,OFFSET RESET_INCLUDE - OFFSET RESET_SYSTEM
	REP	MOVSB
    ;
    ; We have THREE cases to contend with:
    ;
    ;  1. There is NO memory above the INT 12H switch setting.
    ;	     In this case we will use the user specified device
    ;	     size (within limits) to allocate some memory as part
    ;	     of the RAMDRIVE.SYS resident image.
    ;	  NOTE: This type of a RAMDrive will not live through a warm boot
    ;
    ;  2. There is memory immediately after the INT 12H memory size.
    ;	     We will check for a EMM_CTRL there etc.
    ;
    ;  3. There is memory after the INT 12H memory size, but not
    ;	     Immediately after.
    ;	     We will check for a EMM_CTRL there etc.
    ;
	INT	12H			; Get size of memory set on switches

IF DEBUG

	JMP	SHORT DEB1

DEB1MES DB	13,10,"INT 12 returned $"

DEB1:
	PUSH	CX
	PUSH	DX
	PUSHF
	PUSH	AX
	MOV	DX,OFFSET DEB1MES
	CALL	PRINT
	POP	AX
	PUSH	AX
	CALL	ITOA
	POP	AX
	POPF
	POP	DX
	POP	CX
ENDIF

	MOV	CL,6
	SHL	AX,CL			; Convert to Segment register value
	MOV	BX,AX			; Save in BX
	MOV	[HIGH_SEG],AX		; And here

;
;*****************************************************************************
; Ramdrives installed between int12 reported memory and crtseg (A000h) are
; no longer allowed because on several machines including the model 50/60
; and the Tandy AT clone this area is used for something else.	The idea to
; install a ramdrive in system memory is bad anyway but we shall still support
; the installation of a ramdrive in low memory as part of the driver. isp
;
; **START OF CODE REMOVED
;
;
;	 CMP	 BX,CRTSEG
;
;IF DEBUG
;	 JB	 DEBX
;	 JMP	 CASE1
;DEBX:
;ELSE
;	 JAE	 CASE1			 ; No memory to scan
;ENDIF
;
;	 IN	 AL,61H
;	 OR	 AL,20H 		 ; Turn off parity interrupt
;	 JMP	 FOO			 ; 286 back to back IN OUT bug fix
;FOO:	 OUT	 61H,AL
;    ;
;    ; SCAN memory
;    ;
;	 XOR	 DI,DI
;	 MOV	 SI,DI
;	 MOV	 ES,BX			 ;Segment to scan for valid memory
;	 MOV	 DS,BX
;ASSUME  DS:NOTHING
;	 CALL	 TEST_RAM
;	 JNZ	 NO_RAM
;    ; We have case 2
;HAVE_START:
;	 XOR	 DX,DX			 ; DX = 0 means skipping memory
;	 MOV	 [RAMSEG],BX		 ; This is the start of our memory
;
;IF DEBUG
;
;	 JMP	 SHORT DEB2
;
;DEB2MES DB	 13,10,"CASE 1 Ramseg $"
;
;DEB2:
;	 PUSH	 CX
;	 PUSH	 DX
;	 PUSHF
;	 PUSH	 AX
;	 MOV	 DX,OFFSET DEB2MES
;	 CALL	 PRINT
;	 MOV	 AX,[RAMSEG]
;	 CALL	 ITOA
;	 POP	 AX
;	 POPF
;	 POP	 DX
;	 POP	 CX
;ENDIF
;
;	 JMP	 SHORT NEXT_K
;
;NO_RAM:
;	 MOV	 DX,1			 ; DX = 1 means skipping hole
;	 CMP	 [RAMSEG],0		 ; If ramseg is NZ we are done,
;	 JZ	 NEXT_K 		 ;   have case 2 or 3
;	 CALL	 ENABLE_PARITY
;HAVE_MEM:
;    ;
;    ; Driver is TYPE 3
;    ;
;	 SUB	 BX,[RAMSEG]		 ; BX is Para of RAMDRV region
;	 MOV	 CX,6
;	 SHR	 BX,CL			 ; BX is K in region
;	 CMP	 BX,17			 ; Ik EMM_CTRL, 16k min ramdrive
;
;IF DEBUG
;
;	 JMP	 SHORT DEB3
;
;DEB3MESA DB	  13,10,"CASE 3 Ramseg $"
;DEB3MESB DB	  " AVAIL K $"
;
;DEB3:
;	 PUSH	 CX
;	 PUSH	 DX
;	 PUSHF
;	 PUSH	 AX
;	 MOV	 DX,OFFSET DEB3MESA
;	 CALL	 PRINT
;	 MOV	 AX,[RAMSEG]
;	 CALL	 ITOA
;	 MOV	 DX,OFFSET DEB3MESB
;	 CALL	 PRINT
;	 MOV	 AX,BX
;	 CALL	 ITOA
;	 POP	 AX
;	 POPF
;	 POP	 DX
;	 POP	 CX
;ENDIF
;
;	 JB	 RES_NOMEMJ
;	 JMP	 GOT_RESMEM
;
;RES_NOMEMJ:
;	 JMP	 RES_NOMEM
;
;CONT_SCAN:
;	 XOR	 DI,DI
;	 MOV	 SI,DI
;	 MOV	 ES,BX			 ;Segment to scan for valid memory
;	 MOV	 DS,BX
;	 CALL	 TEST_RAM
;	 JNZ	 AT_DIS 		 ;No, detected discontinuity
;	 OR	 DX,DX
;	 JZ	 NEXT_K
;	 JMP	 HAVE_START
;
;AT_DIS:
;	 OR	 DX,DX
;	 JZ	 NO_RAM
;NEXT_K:
;	 ADD	 BX,64			 ; Next K
;	 CMP	 BX,CRTSEG
;	 JB	 CONT_SCAN
;	 CALL	 ENABLE_PARITY
;	 CMP	 [RAMSEG],0
;	 JNZ	 HAVE_MEM
;***END OF CODE REMOVED***
;*****************************************************************************
CASE1:
    ;
    ; Have CASE 1.
    ; Driver is TYPE 4
    ;

IF DEBUG

	JMP	SHORT DEB4

DEB4MES DB	13,10,"CASE 1$"

DEB4:
	PUSH	CX
	PUSH	DX
	PUSHF
	PUSH	AX
	MOV	DX,OFFSET DEB4MES
	CALL	PRINT
	POP	AX
	POPF
	POP	DX
	POP	CX
ENDIF

	PUSH	CS
	POP	DS
ASSUME	DS:RAMCODE
	INC	[RESMEM_SPECIAL]	; Flag SPECIAL case for INIDRV
	MOV	[INIT_DRIVE],2		; This type must ALWAYS be inited
    ;
    ; Compute BASE_ADDR to be right after DEVICE_END, NO INT 19/9 handler
    ;
	MOV	AX,OFFSET DEVICE_END
	ADD	AX,15			; Para round up
	MOV	CL,4
	SHR	AX,CL			; # of para in RAMDrive resident code
	MOV	DX,CS
	ADD	AX,DX			; AX is seg addr of start of RAMDrive
	PUSH	AX
	MOV	CX,16
	MUL	CX			; DX:AX is byte offset of that many paras
	MOV	WORD PTR [BASE_ADDR],AX
	MOV	WORD PTR [BASE_ADDR + 2],DX
	POP	AX
    ;
    ; Compute correct ending address and set TERM_ADDR
    ; Check that there is at least 48k of system memory after device end
    ; AX is the segment address of the start of the device
    ;
	MOV	DX,[DEV_SIZE]		; Get size in K
    ;
    ; DEV_SIZE can be at most a 10 bit number as that is 1 Meg, the memory
    ;	 limit on the 8086
    ;
	TEST	DX,0FC00H		; If any of high 6 bits set, too big
	JNZ	RES_NOMEM
	MOV	CL,6
	SHL	DX,CL			; DX is # of PARA in that many k
	ADD	AX,DX			; AX is end seg addr
	JC	RES_NOMEM		; Overflow
    ;
    ; Make sure at least 48K left after device
    ;
	MOV	DX,[HIGH_SEG]
	SUB	DX,0C00H		; 48K worth of PARAs left for system

IF DEBUG

	JMP	SHORT DEB5

DEB5MESA DB	 " Max end is $"
DEB5MESB DB	 " end is $"

DEB5:
	PUSH	CX
	PUSHF
	PUSH	DX
	PUSH	AX
	MOV	DX,OFFSET DEB5MESA
	CALL	PRINT
	POP	DX
	POP	AX
	PUSH	AX
	PUSH	DX
	CALL	ITOA
	MOV	DX,OFFSET DEB5MESB
	CALL	PRINT
	POP	AX
	PUSH	AX
	CALL	ITOA
	POP	AX
	POP	DX
	POPF
	POP	CX
ENDIF

	JC	RES_NOMEM
	CMP	AX,DX
	JA	RES_NOMEM		; Too big
	MOV	WORD PTR [TERM_ADDR],0
	MOV	WORD PTR [TERM_ADDR + 2],AX

IF DEBUG

	JMP	SHORT DEB6

DEB6MES DB	" OK term $"

DEB6:
	PUSH	CX
	PUSHF
	PUSH	DX
	PUSH	AX
	MOV	DX,OFFSET DEB6MES
	CALL	PRINT
	POP	AX
	PUSH	AX
	CALL	ITOA
	POP	AX
	POP	DX
	POPF
	POP	CX
ENDIF
	CLC
	RET

RES_NOMEM:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	MOV	DX,OFFSET ERRMSG2
	CALL	PRINT
	PUSH	CS
	POP	DS
	STC
	RET

GOT_RESMEM:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
;
; Completion of TYPE 3 initialization.
; RAMSEG is start seg addr of ramdrv region, BX is its size in K
;
	PUSH	CS
	POP	DS
ASSUME	DS:RAMCODE
	MOV	[EXT_K],BX
	DEC	BX		; BX is MAX possible disk size
	CMP	[DEV_SIZE],BX
	JBE	RES002		; DEV_SIZE is OK
	MOV	[DEV_SIZE],BX	; Limit DEV_SIZE to available K
RES002:
	MOV	AX,[RAMSEG]
	MOV	CX,16
	MUL	CX
	MOV	WORD PTR [BASE_ADDR],AX
	MOV	WORD PTR [BASE_ADDR + 2],DX
	ADD	AX,1024
	ADC	DX,0
	MOV	WORD PTR [BASE_RESET],AX
	MOV	WORD PTR [BASE_RESET + 2],DX
	CALL	MM_SETDRIVE
	RET


;**	ENABLE_PARITY - Turn on parity checking of IBM PC AT XT
;
;	This routine enables the memory parity checking on an IBM PC
;	family machine
;
;	ENTRY  NONE
;	EXIT   NONE
;	USES   AL
;
;	SEE ALSO
;	    IBM PC Technical Reference manual for any PC family member
;
;	Code is specific to TYPE 3 and TYPE 4 drivers
;

ENABLE_PARITY:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	IN	AL,61H
	AND	AL,NOT 20H		;Re-enable parity checking
	JMP	BAR			; 286 back to back IN OUT bug fix
BAR:	OUT	61H,AL
	RET


;**	TEST_RAM - Check if valid RAM exists and reset parity if it does
;
;	This routine checks for valid RAM is a 1k block by performing
;	various tests on the first two words of the block. If the RAM
;	is valid, the parity of the 1k block is set by copying the block
;	to itself.
;
;	TESTS
;	    See if first word will store its own compliment
;	    See if read first word writes out correctly (also resets first
;		word to its original value)
;	    See if second word will store a fixed value "AR"
;		On this test we wait a while between the store and
;		the test to allow the buss to settle.
;
;	ENTRY
;	    DS:SI = ES:DI -> a 1k region of RAM to be tested
;	    PARITY CHECKING DISABLED
;	EXIT
;	    Zero set if RAM is valid
;	    Zero reset if RAM is invalid
;	USES
;	    AX, SI, DI
;
;	Code is specific to TYPE 3 and TYPE 4 drivers
;

TEST_RAM:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	LODSW				; See what's there
	NOT	AX
	MOV	[DI],AX 		; See if memory can store complement
	CMP	AX,[DI] 		; Memory OK?
	JNZ	RET007			; Not valid RAM
	NOT	AX
	STOSW				; Restore correct value
	CMP	AX,[DI - 2]		; Memory OK?
	JNZ	RET007			; Not valid RAM
	LODSW				; Next word
	MOV	WORD PTR [DI],"AR"	; Store fixed value
	NOP				; Wait
	NOP
	NOP
	NOP
	CMP	WORD PTR [DI],"AR"	; Did it store?
	JNZ	RET007			; Not Valid RAM
	STOSW				; Restore correct value
	MOV	CX,510	; Copy to self to reset parity in this 1k block
	REP	MOVSW
RET007:
	RET

BREAK	<Drive code for resmem driver. Swapped in at BLKMOV>

;
; This label defines the start of the TYPE 3 and 4 code swapped
;  in at BLKMOV
;
RESMEM_CODE	 LABEL	 WORD

;
; WARNING DANGER!!!!!!!
;
; This code is tranfered over the /E driver code at DRIVE_CODE
;
; ALL jmps etc. must be IP relative.
; ALL data references must be to cells at the FINAL, TRUE location
;	(no data cells may be named HERE, must be named up at BLKMOV).
; OFFSET of RESMEM_BLKMOV relative to RESMEM_CODE MUST be the same as
;	the OFFSET of BLKMOV relative to DRIVE_CODE.
; SIZE of stuff between RESMEM_CODE and RESMEM_END MUST be less than
;	or equal to size of stuff between DRIVE_CODE and DRIVE_END.

IF2
  IF((OFFSET RESMEM_BLKMOV - OFFSET RESMEM_CODE) NE (OFFSET BLKMOV - OFFSET DRIVE_CODE))
	  %out ERROR BLKMOV, RESMEM_BLKMOV NOT ALIGNED
  ENDIF
  IF((OFFSET RESMEM_END - OFFSET RESMEM_CODE) GT (OFFSET DRIVE_END - OFFSET DRIVE_CODE))
	  %out ERROR RESMEM CODE TOO BIG
  ENDIF
ENDIF

		DD	?	; 24 bit address of start of this RAMDRV

;**	RESMEM_BLKMOV - Perform transfer for TYPE 3 and 4 driver
;
;	This routine is the transfer routine for moving bytes
;	to and from a RAMDrive located in main memory.
;
;	METHOD:
;	    Convert start address into segreg index reg pair
;	    Mov computed segreg index reg pairs into correct registers
;	    Execute REP MOVSW to perform transfer
;
;	ENTRY:
;	    ES:DI is packet transfer address.
;	    CX is number of words to transfer.
;	    DX:AX is 32 bit start byte offset (0 = sector 0 of RAMDrive drive)
;	    BH is 1 for WRITE, 0 for READ
;
;	    BASE_ADDR set to point to start of RAMDrive memory
;		This "input" is not the responsibility of the caller. It
;		is up to the initialization code to set it up when the
;		device is installed
;
;	EXIT:
;	    Carry Clear
;		    OK, operation performed successfully
;	    Carry Set
;		    Error during operation, AL is error number
;
;	USES:
;	    ALL
;
;	This routine is specific to TYPE 3 and 4 drivers
;

RESMEM_BLKMOV:
ASSUME	DS:RAMCODE,ES:NOTHING,SS:NOTHING

	ADD	AX,WORD PTR [BASE_ADDR]
	ADC	DX,WORD PTR [BASE_ADDR + 2]
	PUSH	CX
	MOV	CX,16
	DIV	CX		; AX is seg reg value, DX is index register
	POP	CX
	OR	BH,BH
	JZ	READ_ITR
    ;
    ; WRITE
    ;
	PUSH	ES
	POP	DS
ASSUME	DS:NOTHING
	MOV	SI,DI
	MOV	ES,AX
	MOV	DI,DX
TRANS:
	REP	MOVSW
	CLC
	RET

READ_ITR:
	MOV	DS,AX
ASSUME	DS:NOTHING
	MOV	SI,DX
	JMP	TRANS

;
; This label defines the end of the RESMEM code swapped in at BLKMOV
;
RESMEM_END	 LABEL	 WORD

BREAK	<Drive code for resmem driver. Swapped in at RESET_SYSTEM>


;
; WARNING DANGER!!!!!!!
;
; This code is tranfered over the /E driver code at RESET_SYSTEM
;
; ALL jmps etc. must be IP relative.
; ALL data references must be to cells at the FINAL, TRUE location
;	(no data cells may be named HERE, must be named up at RESET_SYSTEM).
; SIZE of stuff between RESMEM_RESET and RESMEM_RESET_END MUST be less than
;	or equal to size of stuff between RESET_SYSTEM and RESET_INCLUDE.

IF2
  IF((OFFSET RESMEM_RESET_END - OFFSET RESMEM_RESET) GT (OFFSET RESET_INCLUDE - OFFSET RESET_SYSTEM))
	  %out ERROR RESMEM_RESET CODE TOO BIG
  ENDIF
ENDIF

;**	RESMEM_RESET perform TYPE 3 (RESMEM) driver specific reboot code
;
;	This code performs the EMM_ISDRIVER reset function as described
;	in EMM.ASM for all EMM_REC structures which are EMM_ALLOC and
;	EMM_ISDRIVER and of type EMM_MSDOS.
;
;	ENTRY
;	    NONE
;	EXIT
;	    NONE
;	USES
;	    NONE
;
; This code is specific to TYPE 3 drivers
;

RESMEM_RESET:
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSH	SI
	PUSH	DI
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DS
	PUSH	ES
	PUSH	CS
	POP	DS
ASSUME	DS:RAMCODE
	MOV	AX,WORD PTR [BASE_ADDR]
	MOV	DX,WORD PTR [BASE_ADDR + 2]
	SUB	AX,1024 		; Point back to EMM block
	SBB	DX,0
;
; NOTE: We can address the EMM block by just backing up
;	by 1024 bytes from BASE_ADDR because the RESET_SYSTEM handler
;	is in the FIRST RAMDrive driver
;
	MOV	CX,16
	DIV	CX			; AX is seg reg, DX is index reg
	MOV	DS,AX
ASSUME	DS:NOTHING
	MOV	SI,DX			; DS:SI -> EMM_CTRL
	MOV	DI,SI
	ADD	DI,EMM_RECORD
	MOV	CX,EMM_NUMREC
LOOK_RECRY:
    ;
    ; Scan EMM_CTRL for all ISDRIVER MS-DOS regions and turn off ISDRIVER
    ;
	TEST	[DI.EMM_FLAGS],EMM_ALLOC
	JZ	DONERY
	TEST	[DI.EMM_FLAGS],EMM_ISDRIVER
	JZ	NEXTRECRY		 ; No Driver
	CMP	[DI.EMM_SYSTEM],EMM_MSDOS
	JNZ	NEXTRECRY
	AND	[DI.EMM_FLAGS],NOT EMM_ISDRIVER
NEXTRECRY:
	ADD	DI,SIZE EMM_REC
	LOOP	LOOK_RECRY
DONERY:
	POP	ES
	POP	DS
ASSUME	DS:NOTHING
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	POP	DI
	POP	SI
	RET

;
; This label defines the end of the RESMEM code swapped in at RESET_SYSTEM
;
RESMEM_RESET_END    LABEL   BYTE

BREAK <messages and common data>

;**	Message texts and common data
;
;	Init data. This data is disposed of after initialization.
;	it is mostly texts of all of the messages
;
;	COMMON to TYPE 1,2,3 and 4 drivers
;
;
;	translatable messages moved to message module (SP)

	EXTRN	NO_ABOVE:BYTE,BAD_ABOVE:BYTE,BAD_AT:BYTE,NO_MEM:BYTE
	EXTRN	ERRMSG1:BYTE,ERRMSG2:BYTE,INIT_IO_ERR:BYTE,BADVERMES:BYTE
	EXTRN	HEADERMES:BYTE,PATCH2X:BYTE,DOS_DRV:BYTE
	EXTRN	STATMES1:BYTE,STATMES2:BYTE,STATMES3:BYTE
	EXTRN	STATMES4:BYTE,STATMES5:BYTE
	db	"RAMDrive is a trademark of Microsoft Corporation."
	db	"This program is the property of Microsoft Corporation."

VOLID	DB	'MS-RAMDRIVE',ATTR_VOLUME_ID
	DB	10 DUP (0)
	DW	1100000000000000B		;12:00:00
	DW	0000101011001001B		;JUN 9, 1985
	DW	0,0,0

SECTOR_BUFFER	DB	1024 DUP(0)

RAMDrive_END	   LABEL   BYTE

RAMCODE ENDS
	END
