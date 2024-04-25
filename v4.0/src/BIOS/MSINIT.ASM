	PAGE	,132			;
	%OUT	...MSINIT.ASM
;=======================================================
;REVISION HISTORY:
;AN000; - NEW Version 4.00. J.K.
;AC000; - Modified Line 4.00. J.K.
;ANxxx; - PTMyyy
;==============================================================================
;AN001; P87 Set the value of MOTOR START TIME Variable		    6/25/87 J.K.
;AN002; P40 Boot from the system with no floppy diskette drives     6/26/87 J.K.
;AN003; D9  Double Word MOV instruction for 386 based machine	    7/1/87  J.K.
;AN004; D64 Extend DOS 3.3 FAT tables to 64 K entries.		    7/8/87  J.K.
;AN005; D113 Disable I/O access to unformatted media		    9/03/87 J.K.
;AN006; p941 D113 does not implemented properly.		    9/11/87 J.K.
;AN007; p969 Should Honor OS2 boot record.			    9/11/87 J.K.
;AN008; p985 Allow I/O access to unformtted media		    9/14/87 J.K.
;AN009; p1535 Disallow I/O access to unformtted media		   10/15/87 J.K.
;AN010; p2349 Cover DOS 3.3 and below FDISK bug 		   11/10/87 J.K.
;AN011; P2431 OS2 boot record version number is at offset 7 (not 8)11/12/87 J.K.
;AN012; P2900 DOS 4.0 does not recognize 3.0 formatted media	   12/18/87 J.K.
;AN013; P3409 Extended keyboard not recognized			   02/05/88 J.K.
;AN014; D486 Share installation for big media			   02/23/88 J.K.
;AN015; P3929 Boot record buffer overlaps MSBIO code		   03/18/88 J.K.
;==============================================================================

	itest = 0
	INCLUDE MSGROUP.INC	;DEFINE CODE SEGMENT
	INCLUDE MSDSKPR.INC
	INCLUDE MSEQU.INC
	INCLUDE MSMACRO.INC
	INCLUDE MSEXTRN.INC
	INCLUDE BIOSTRUC.INC
	INCLUDE CMOSEQU.INC
	include cputype.inc

; THE FOLLOWING LABEL DEFINES THE END OF THE AT ROM PATCH.  THIS IS USED AT
; CONFIGURATION TIME.
;J.K. 10/2/86 Waring!!! This code will be dynamically relocated by MSINIT.

	PUBLIC	ENDATROM		;NOT REFERENCES EXTERNALLY, BUT
					; JUST TO CAUSE ENTRY IN LINK MAP
ENDATROM LABEL	BYTE

;CMOS Clock setting support routines used by MSCLOCK.
;J.K. 10/2/86 Waring!!! This code will be dynamically relocated by MSINIT.

	EXTRN	base_century:byte
	EXTRN	base_year:byte
	EXTRN	month_tab:byte

	public	Daycnt_to_day	;J.K. 4/30/86 for real time clock support
Daycnt_to_day	proc	near	;J.K. 4/30/86 for real time clock support
;Entry: [DAYCNT] = number of days since 1-1-80
;Return: CH - centry in BCD, CL - year in BCD, DH - month in BCD, DL - day in BCD

	push	[daycnt]		;save daycnt
	cmp	daycnt, (365*20+(20/4)) ;# of days from 1-1-1980 to 1-1-2000
	jae	century20
	mov	base_century, 19
	mov	base_year, 80
	jmp	years
century20:				;20th century
	mov	base_century, 20
	mov	base_year, 0
	sub	daycnt, (365*20+(20/4)) ;adjust daycnt
years:
	xor	dx, dx
	mov	ax, daycnt
	mov	bx, (366+365*3) 	;# of days in a Leap year block
	div	bx			;AX = # of leap block, DX = daycnt
	mov	daycnt, dx		;save daycnt left
;	or	ah, ah			;ax should be less than 256
;	jz	OK1
;	 jmp	 Erroroccur
;OK1:
	mov	bl,4
	mul	bl			;AX = # of years. Less than 100 years!
	add	base_year, al		;So, ah = 0. Adjust year accordingly.
	inc	daycnt			;set daycnt to 1 base
	cmp	daycnt, 366		;the daycnt here is the remainder of the leap year block.
	jbe	Leapyear		;So, it should within 366+355+355+355 days.
	inc	base_year		;First if daycnt <= 366, then leap year
	sub	daycnt, 366		;else daycnt--, base_year++;
					;And the next three years are regular years.
	mov	cx, 3
Regularyear:
	cmp	daycnt, 365		;for(i=1; i>3 or daycnt <=365;i++)
	jbe	YearDone		;{if (daycnt > 365)
	inc	base_year		;  { daycnt -= 365
	sub	daycnt, 365		;  }
	loop	regularyear		;}
;	 jmp	 Erroroccur		 ;cannot come to here
Leapyear:
	mov	byte ptr month_tab+1,29 ;leap year. change the month table.
Yeardone:
	xor	bx,bx
	xor	dx,dx
	mov	ax, daycnt
	mov	si, offset month_tab
	mov	cx, 12
Months:
	inc	bl			;
	mov	dl, byte ptr ds:[si]	;compare daycnt for each month until fits
	cmp	ax, dx			;dh=0.
	jbe	Month_done
	inc	si			;next month
	sub	ax, dx			;adjust daycnt
	loop	Months
;	 jmp	 Erroroccur
Month_done:
	mov	byte ptr month_tab+1, 28 ;restore month table value
	mov	dl, bl
	mov	dh, base_year
	mov	cl, base_century	;now, al=day, dl=month,dh=year,cl=century
	call	word ptr BinToBCD	;Oh my!!! To save 15 bytes, Bin_To_BCD proc
					;was relocated seperately from Daycnt_to_Day proc.
;	call Bin_to_bcd 		;convert "day" to bcd
	xchg	dl, al			;dl = bcd day, al = month
	call	word ptr BinToBCD
;	call Bin_to_bcd
	xchg	dh, al			;dh = bcd month, al = year
	call	word ptr BinToBCD
;	call Bin_to_bcd
	xchg	cl, al			;cl = bcd year, al = century
	call	word ptr BinToBCD
;	call Bin_to_bcd
	mov	ch, al			;ch = bcd century
	pop	[daycnt]		;restore original value
	ret
Daycnt_to_day	endp

	public	EndDaycntToDay
EndDaycntToDay label	byte

	public	Bin_to_bcd
Bin_to_bcd	proc	near		;J.K. 4/30/86 for real time clock support
;Convert a binary input in AL (less than 63h or 99 decimal)
;into a bcd value in AL.  AH destroyed.
	push	cx
	xor	ah, ah
	mov	cl, 10
	div	cl		;al - high digit for bcd, ah - low digit for bcd
	mov	cl, 4
	shl	al, cl		;mov the high digit to high nibble
	or	al, ah
	pop	cx
	ret
Bin_to_bcd	endp

	Public	EndCMOSClockset 	;End of supporting routines for CMOS clock setting.
EndCMOSClockset label byte
;

	EXTRN  INT6C_RET_ADDR:DWORD	; RETURN ADDRESS FROM INT 6C
	EXTRN  BIN_DATE_TIME:BYTE
	EXTRN  MONTH_TABLE:WORD
	EXTRN  DAYCNT2:WORD
	EXTRN  FEB29:BYTE
	EXTRN  TimeToTicks:Word 	;indirect intra-segment call address

	EVENB
;
; THE K09 REQUIRES THE ROUTINES FOR READING THE CLOCK BECAUSE OF THE SUSPEND/
; RESUME FACILITY. THE SYSTEM CLOCK NEEDS TO BE RESET AFTER RESUME.
;
	ASSUME	ES:NOTHING

; THE FOLLOWING ROUTINE IS EXECUTED AT RESUME TIME WHEN THE SYSTEM
; POWERED ON AFTER SUSPENSION. IT READS THE REAL TIME CLOCK AND
; RESETS THE SYSTEM TIME AND DATE, AND THEN IRETS.

;J.K. 10/2/86 Waring!!! This code will be dynamically relocated by MSINIT.

INT6C	PROC	FAR
	PUSH	CS
	POP	DS

	ASSUME DS:CODE

	POP	WORD PTR INT6C_RET_ADDR ; POP OFF RETURN ADDRESS
	POP	WORD PTR INT6C_RET_ADDR+2
	POPF
	CALL	READ_REAL_DATE		; GET THE DATE FROM THE CLOCK
	CLI
	MOV	DS:DAYCNT,SI	      ; UPDATE DOS COPY OF DATE
	STI
	CALL	READ_REAL_TIME		; GET THE TIME FROM THE RTC
	CLI
;SB33019***************************************************************
	MOV	AH, 01h 		; COMMAND TO SET THE TIME      ;SB;3.30
	INT	1Ah			; CALL ROM-BIOS TIME ROUTINE   ;SB;3.30
;SB33019***************************************************************
	STI
	JMP	INT6C_RET_ADDR		; LONG JUMP

INT6C	ENDP


	INCLUDE READCLOC.INC
	INCLUDE CLOCKSUB.INC

	PUBLIC	ENDK09			;NOT REFERENCES EXTERNALLY, BUT
					; JUST TO CAUSE ENTRY IN LINK MAP
ENDK09	LABEL	BYTE
	ASSUME	DS:NOTHING,ES:NOTHING

;*********************************************************
;	SYSTEM INITIALIZATION
;
;	THE ENTRY CONDITIONS ARE ESTABLISHED BY THE BOOTSTRAP
;	LOADER AND ARE CONSIDERED UNKNOWN. THE FOLLOWING JOBS
;	WILL BE PERFORMED BY THIS MODULE:
;
;	1.	ALL DEVICE INITIALIZATION IS PERFORMED
;	2.	A LOCAL STACK IS SET UP AND DS:SI ARE SET
;		TO POINT TO AN INITIALIZATION TABLE. THEN
;		AN INTER-SEGMENT CALL IS MADE TO THE FIRST
;		BYTE OF THE DOS
;	3.	ONCE THE DOS RETURNS FROM THIS CALL THE DS
;		REGISTER HAS BEEN SET UP TO POINT TO THE START
;		OF FREE MEMORY. THE INITIALIZATION WILL THEN
;		LOAD THE COMMAND PROGRAM INTO THIS AREA
;		BEGINNING AT 100 HEX AND TRANSFER CONTROL TO
;		THIS PROGRAM.
;
;********************************************************

;SYSIZE=200H		       ;NUMBER OF PARAGRAPHS IN SYSINIT MODULE
sysize=500h    ;AC000;

; DRVFAT MUST BE THE FIRST LOCATION OF FREEABLE SPACE!
	EVENB
DRVFAT	DW	0000			;DRIVE AND FAT ID OF DOS
BIOS$_L DW	0000			;FIRST SECTOR OF DATA (Low word)
bios$_H dw	0000			;First sector of data (High word)
DOSCNT	DW	0000			;HOW MANY SECTORS TO READ
FBIGFAT DB	0			; FLAGS FOR DRIVE
;an004
;FATLEN  DW	 ?			 ; NUMBER OF SECTORS IN FAT.
FATLOC	DW	?			; SEG ADDR OF FAT SECTOR
Init_BootSeg	dw	?		;AN015; seg addr of buffer for reading boot record
ROM_drv_num db	80h			;AN000; rom drv number
;Boot_Sec_Per_Fat dw 0			 ;AN000; Boot media sectors/FAT
Md_SectorSize	dw 512			;AN004; Used by Get_Fat_Sector proc.
Temp_Cluster	dw 0			;AN004; Used by Get_Fat_Sector proc.
Last_Fat_SecNum dw -1			;AN004; Used by Get_Fat_Sector proc.

; THE FOLLOWING TWO BYTES ARE USED TO SAVE THE INFO RETURNED BY INT 13, AH = 8
; CALL TO DETERMINE DRIVE PARAMETERS.
NUM_HEADS DB	2			; NUMBER OF HEADS RETURNED BY ROM
SEC_TRK   DB	9			; SEC/TRK RETURNED BY ROM
NUM_CYLN  DB	40			; NUMBER OF CYLINDERS RETURNED BY ROM

FakeFloppyDrv db      0 		;AN002; If 1, then No diskette drives in the system.

BOOTBIAS =	200H
BOOT_ADDR = 7C00H
EXT_BOOT_SIG_OFF = 11+size BPB_TYPE ;AN000; 3 byte jmp+8 byte OEM +extended bpb


	EVENB
DISKTABLE DW	512,	0100H,	64,	0
	DW	2048,	0201H,	112,	0
	DW	8192,	0402H,	256,	0
	DW	32680,	0803H,	512,	0      ;Warning !!! Old values
;	DW	20740,	0803H,	 512,	0	;PTM P892 J.K. 12/3/86 DOS 3.3 will use this.
						;J.K.3/16/87 P54 Return back to old value for compatibility.!!!
	DW	65535,	1004H,	1024,	0

;DISKTABLE2 DW	 32680,  0803H,  512,	 0	;Warning !!! Old values  ;J.K.3/16/87 P54 Return to old value!!!
;DISKTABLE2 DW	 20740,  0803H,  512,	 0	 ;PTM p892 J.K. 12/3/86 DOS 3.3 will use this.
;	 DW	 65535,  0402H,  512,	 FBIG
;AN000;
;DISKTABLE2 dw	 0, 32680, 0803h, 512, 0	 ;table with the assumption of the
;	    dw	2h, 0000h, 0402h, 512, FBIG	 ;total fat size <= 64KB.
;	    dw	4h, 0000h, 0803h, 512, FBIG	 ;-This will cover upto 134 MB
;	    dw	8h, 0000h, 1004h, 512, FBIG	 ;-This will cover upto 268 MB
;	    dw 10h, 0000h, 2005h, 512, FBIG	 ;-This will cover upto 536 MB

;AN004 Default DiskTable under the assumption of Total FAT size <= 128 KB, and
;	the maxium size of FAT entry = 16 Bit.
DiskTable2  dw	 0, 32680, 0803h, 512, 0	;For compatibility.
	    dw	4h, 0000h, 0402h, 512, FBIG	;Covers upto 134 MB media.
	    dw	8h, 0000h, 0803h, 512, FBIG	;	upto 268 MB
	    dw 10h, 0000h, 1004h, 512, FBIG	;	upto 536 MB
	    dw 20h, 0000h, 2005h, 512, FBIG	;	upto 1072 MB
	    dw 40h, 0000h, 4006h, 512, FBIG	;	upto 2144 MB
	    dw 80h, 0000h, 8007h, 512, FBIG	;	upto 4288 MB...

;******************************************************************************
;Variables for Mini disk initialization - J.K. 4/7/86
;******************************************************************************
End_Of_BDSM	dw	?		;offset value of the ending address
					;of BDSM table. Needed to figure out
					;the Final_DOS_Location.
numh		db	0		;number of hard files
mininum 	db	0		;logical drive number for mini disk(s)
num_mini_dsk	db	0		;# of mini disk installed
Rom_Minidsk_num db	80h		;physical mini disk number
Mini_HDLIM	dw	0
Mini_SECLIM	dw	0
Mini_BPB_ptr	dw	0		;temporary variable used to save the
					;Mini Disk BPB pointer address in DskDrvs.
;J.K. 4/7/86 End of Mini Disk Init Variables **********************************


BIOS_DATE DB	'01/10/84',0     ;This is used for checking AT ROM BIOS date.

; THE FOLLOWING ARE THE RECOMMENDED BPBS FOR THE MEDIA THAT WE KNOW OF SO
; FAR.

; 48 TPI DISKETTES
	EVENB
BPB48T	DW	512
	DB	2
	DW	1
	DB	2
	DW	112
	DW	2*9*40
	DB	0FDH
	DW	2
	DW	9
	DW	2
	DW	0
	dw	0		;AN000;  hidden sector High
	dd	0		;AN000;  extended total sectors

; 96TPI DISKETTES
	EVENB
BPB96T	DW	512
	DB	1
	DW	1
	DB	2
	DW	224
	DW	2*15*80
	DB	0F9H
	DW	7
	DW	15
	DW	2
	DW	0
	dw	0		;AN000;  hidden sector High
	dd	0		;AN000;  extended total sectors

BPBSIZ	=	$-BPB96T

; 3 1/2 INCH DISKETTE BPB

	EVENB
BPB35	DW	512
	DB	2
	DW	1			; DOUBLE SIDED WITH 9 SEC/TRK
	DB	2
	DW	70h
	DW	2*9*80
	DB	0F9H
	DW	3
	DW	9
	DW	2
	DW	0
	dw	0		;AN000;  hidden sector High
	dd	0		;AN000;  extended total sectors

	EVENB
BPBTABLE DW	BPB48T			; 48TPI DRIVES
	DW	BPB96T			; 96TPI DRIVES
	DW	BPB35			; 3.5" DRIVES
					;DW	 BPB48T 	     ; NOT USED - 8" DRIVES
					;DW	 BPB48T 	     ; NOT USED - 8" DRIVES
					;DW	 BPB48T 	     ; NOT USED - HARD FILES
					;DW	 BPB48T 	     ; NOT USED - TAPE DRIVES
					;DW	 BPB48T 	     ; NOT USED - OTHER

PATCHTABLE LABEL BYTE
	DW	10,MEDIA_PATCH
	DW	3,GETBP1_PATCH
	DW	3,SET_PATCH
	DW	3,DISKIO_PATCH
	DW	3,DSKERR
	DW	10,CHANGED_PATCH
	DW	3,INIT_PATCH
	DW	0

	ASSUME	DS:NOTHING,ES:NOTHING

;
; ENTRY FROM BOOT SECTOR.  THE REGISTER CONTENTS ARE:
;   DL = INT 13 DRIVE NUMBER WE BOOTED FROM
;   CH = MEDIA BYTE
;   BX = FIRST DATA SECTOR ON DISK.
;J.K.
;   AX = first data sector (High)
;   DI = Sectors/FAT for the boot media.
;
	PUBLIC	INIT
INIT	PROC	NEAR
	MESSAGE FTESTINIT,<"IBMBIO",CR,LF>
	CLI
	push	ax
	XOR	AX,AX
	MOV	DS,AX
	pop	ax
;J.K. MSLOAD will check the extended boot record and set AX, BX accordingly.

;SB34INIT000*************************************************************
;SB	MSLOAD passes a 32 bit sector number hi word in ax and low in bx
;SB	Save this in cs:BIOS$_H and cs:BIOS$_L. This is for the start of
;SB	data sector of the BIOS.

	mov	cs:BIOS$_H,ax
	mov	cs:BIOS$_L,bx

;SB34INIT000*************************************************************

;J.K. With the following information from MSLOAD, we don't need the
;     Boot sector any more.-> This will solve the problem of 29 KB size
;     limitation of MSBIO.COM file.
;J.K. AN004 - Don't need this information any more, since we are not going to
;	      read the whole FAT into memory.
;	 mov	 cs:Boot_Sec_Per_FAT, di ;sectors/FAT for boot media. ;AN000;

;
; PRESERVE ORIGINAL INT 13 VECTOR
;   WE NEED TO SAVE INT13 IN TWO PLACES IN CASE WE ARE RUNNING ON AN AT.
; ON ATS WE INSTALL THE IBM SUPPLIED ROM_BIOS PATCH DISK.OBJ WHICH HOOKS
; INT13 AHEAD OF ORIG13.  SINCE INT19 MUST UNHOOK INT13 TO POINT TO THE
; ROM INT13 ROUTINE, WE MUST HAVE THAT ROM ADDRESS ALSO STORED AWAY.
;
	MOV	AX,DS:[13H*4]
	MOV	WORD PTR OLD13,AX
	MOV	WORD PTR ORIG13,AX
	MOV	AX,DS:[13H*4+2]
	MOV	WORD PTR OLD13+2,AX
	MOV	WORD PTR ORIG13+2,AX
;
; SET UP INT 13 FOR NEW ACTION
;
	MOV	WORD PTR DS:[13H*4],OFFSET BLOCK13
	MOV	DS:[13H*4+2],CS
;
; PRESERVE ORIGINAL INT 19 VECTOR
;
	MOV	AX,DS:[19H*4]
	MOV	WORD PTR ORIG19,AX
	MOV	AX,DS:[19H*4+2]
	MOV	WORD PTR ORIG19+2,AX
;
; SET UP INT 19 FOR NEW ACTION
;
	MOV	WORD PTR DS:[19H*4],OFFSET INT19
	MOV	DS:[19H*4+2],CS
	STI
	INT	11H			;GET EQUIPMENT STATUS
;J.K.6/24/87 We have to support a system that does not have any diskette
;drives but only hardfiles.  This system will IPL from the hardfile.
;If the equipment flag bit 0 is 1, then the system has diskette drive(s).
;Otherwise, the system only have hardfiles.
;Important thing is that still, for compatibility reason, the drive letter
;for the hardfile start from "C".  So, we still need to allocate dummy BDS
;drive A and driver B.	In SYSINIT time, we are going to set CDS table entry
;of DPB pointer for these drives to 0, so any user attempt to access this
;drives will get "Invalid drive letter ..." message.  We are going to
;establish "FAKEFLOPPYDRV" flag.  ***SYSINIT module should call INT 11h to check
;if there are any diskette drivers in the system or not.!!!***

;SB34INIT001**************************************************************
;SB	check the register returned by the equipment determination interrupt
;SB	we have to handle the case of no diskettes in the system by faking
;SB	two dummy drives.
;SB	if the register indicates that we do have floppy drives we don't need
;SB	to do anything special.
;SB	if the register indicates that we don't have any floppy drives then
;SB	what we need to do is set the FakeFloppyDrv variable, change the 
;SB	register to say that we do have floppy drives and then go to execute
;SB	the code which starts at NOTSINGLE.  This is because we can skip the
;SB	code given below which tries to find if there are one or two drives
;SB	since we already know about this.  6 LOCS

	test	ax,1
	jnz	DO_FLOPPY
	mov	cs:FakeFloppyDrv,1	; fake floppy
	mov	ax,1			; set to indicate 2 floppies 
	jmp	short NOTSINGLE

DO_FLOPPY:

;SB34INIT001**************************************************************
   ;
   ; Determine if there are one or two diskette drives in system
   ;
	ROL	AL,1			;PUT BITS 6 & 7 INTO BITS 0 & 1
	ROL	AL,1
	AND	AX,3			;ONLY LOOK AT BITS 0 & 1
	JNZ	NOTSINGLE		;ZERO MEANS SINGLE DRIVE SYSTEM
	INC	AX			;PRETEND IT'S A TWO DRIVE SYSTEM
	INC	CS:SINGLE		;REMEMBER THIS
NOTSINGLE:
	INC	AX			;AX HAS NUMBER OF DRIVES, 2-4
					;IS ALSO 0 INDEXED BOOT DRIVE IF WE
					;  BOOTED OFF HARD FILE
	MOV	CL,AL			;CH IS FAT ID, CL # FLOPPIES
	TEST	DL,80H			;BOOT FROM FLOPPY ?
	JNZ	GOTHRD			;NO.
	XOR	AX,AX			;INDICATE BOOT FROM DRIVE A
GOTHRD:
;
;   AX = 0-BASED DRIVE WE BOOTED FROM
;   BIOS$_L, BIOS$_H set.
;   CL = NUMBER OF FLOPPIES INCLUDING FAKE ONE
;   CH = MEDIA BYTE
;
	MESSAGE FTESTINIT,<"INIT",CR,LF>
	XOR	DX,DX
	CLI
	MOV	SS,DX
	MOV	SP,700H 		;LOCAL STACK
	STI
	ASSUME	SS:NOTHING

	PUSH	CX			;SAVE NUMBER OF FLOPPIES AND MEDIA BYTE
	MOV	AH,CH			;SAVE FAT ID TO AH
	PUSH	AX			;SAVE BOOT DRIVE NUMBER, AND MEDIA BYTE
;J.K. Let Model_byte, Secondary_Model_Byte be set here!!!
;SB33020******************************************************************
	mov	ah,0c0h 		; return system environment    ;SB;3.30
	int	15h			; call ROM-Bios routine        ;SB;3.30
;SB33020******************************************************************
	jc	No_Rom_System_Conf	; just use Model_Byte
	cmp	ah, 0			; double check
	jne	No_Rom_System_Conf
	mov	al, ES:[BX.bios_SD_modelbyte] ;get the model byte
	mov	[Model_Byte], al
	mov	al, ES:[BX.bios_SD_scnd_modelbyte] ;secondary model byte
	mov	[Secondary_Model_Byte], al
	jmp	short Turn_Timer_On
No_Rom_System_Conf:
	MOV	SI,0FFFFH		;MJB001
	MOV	ES,SI			;MJB001
	MOV	AL,ES:[0EH]		; GET MODEL BYTE ARR 2.41
	MOV	MODEL_BYTE,AL	      ; SAVE MODEL BYTE ARR 2.41
Turn_Timer_On:
	MOV	AL,EOI
	OUT	AKPORT,AL		;TURN ON THE TIMER

;     NOP out the double word MOV instruction in MSDISK, if
;     this is not a 386 machine...
	Get_CPU_Type			; macro to determine cpu type
	cmp	ax, 2			; is it a 386?
	je	Skip_Patch_DoubleWordMov; yes: skip the patch

Patch_DoubleWordMov:
	push	es			 ;AN003;
	push	cs			 ;AN003;
	pop	es			 ;AN003;ES -> CS
	mov	di, offset DoubleWordMov ;AN003;
	mov	cx, 3			;AN003; 3 bytes to NOP
	mov	al, 90h 		;AN003;
	rep	stosb			;AN003;
	pop	es			;AN003;
Skip_Patch_DoubleWordMov:		;AN003;
	MESSAGE FTESTINIT,<"COM DEVICES",CR,LF>
;SB33IN1*********************************************************

	mov	si,offset COM4DEV 
	call	AUX_INIT
	mov	si,offset COM3DEV
	call	AUX_INIT
;SB33IN1*********************************************************
	MOV	SI,OFFSET COM2DEV
	CALL	AUX_INIT		;INIT COM2
	MOV	SI,OFFSET COM1DEV
	CALL	AUX_INIT		;INIT COM1

	MESSAGE FTESTINIT,<"LPT DEVICES",CR,LF>
	MOV	SI,OFFSET LPT3DEV
	CALL	PRINT_INIT		;INIT LPT3
	MOV	SI,OFFSET LPT2DEV
	CALL	PRINT_INIT		;INIT LPT2
	MOV	SI,OFFSET LPT1DEV
	CALL	PRINT_INIT		;INIT LPT1

	XOR	DX,DX
	MOV	DS,DX			;TO INITIALIZE PRINT SCREEN VECTOR
	MOV	ES,DX

	XOR	AX,AX
	MOV	DI,INITSPOT
	STOSW				;INIT FOUR BYTES TO 0
	STOSW

	MOV	AX,CS			;FETCH SEGMENT

	MOV	DS:WORD PTR BRKADR,OFFSET CBREAK ;BREAK ENTRY POINT
	MOV	DS:BRKADR+2,AX		;VECTOR FOR BREAK

;*********************************************** ARR 2.15
; SINCE WE'RE FIRST IN SYSTEM, NO NEED TO CHAIN THIS.
;	CLI				; ARR 2.15 DON'T GET BLOWN
;	MOV	DS:WORD PTR TIMADR,OFFSET TIMER ; ARR 2.15 TIMER ENTRY POINT
;	MOV	DS:TIMADR+2,AX		; ARR 2.15 VECTOR FOR TIMER
;	STI
;*********************************************** ARR 2.15

; BAS DEBUG
	MOV	DS:WORD PTR CHROUT*4,OFFSET WORD PTR OUTCHR
	MOV	DS:WORD PTR CHROUT*4+2,AX

	MESSAGE FTESTINIT,<"INTERRUPT VECTORS",CR,LF>
	MOV	DI,4
	MOV	BX,OFFSET INTRET	;WILL INITIALIZE REST OF INTERRUPTS
	XCHG	AX,BX
	STOSW				;LOCATION 4
	XCHG	AX,BX
	STOSW				;INT 1		;LOCATION 6
	ADD	DI,4
	XCHG	AX,BX
	STOSW				;LOCATION 12
	XCHG	AX,BX
	STOSW				;INT 3		;LOCATION 14
	XCHG	AX,BX
	STOSW				;LOCATION 16
	XCHG	AX,BX
	STOSW				;INT 4		;LOCATION 18

	MOV	DS:WORD PTR 500H,DX	;SET PRINT SCREEN & BREAK =0
	MOV	DS:WORD PTR LSTDRV,DX	;CLEAN OUT LAST DRIVE SPEC

	MESSAGE FTESTINIT,<"DISK PARAMETER TABLE",CR,LF>

;;**	MOV	SI,WORD PTR DS:DSKADR	;			  ARR 2.41
;;**	MOV	DS,WORD PTR DS:DSKADR+2 ; DS:SI -> CURRENT TABLE  ARR 2.41
;;**
;;**	MOV	DI,SEC9 		; ES:DI -> NEW TABLE	  ARR 2.41
;;**	MOV	CX,SIZE DISK_PARMS	;			  ARR 2.41
;;**	REP	MOVSB			; COPY TABLE		  ARR 2.41
;;**	PUSH	ES			;			  ARR 2.41
;;**	POP	DS			; DS = 0		  ARR 2.41

;;**	MOV	WORD PTR DS:DSKADR,SEC9 ;			  ARR 2.41
;;**	MOV	WORD PTR DS:DSKADR+2,DS ; POINT DISK PARM VECTOR TO NEW TABLE
					;			  ARR 2.41
;SB34INIT002******************************************************************
;SB	We need to initalise the cs:MotorStartup variable from the disk 
;SB	parameter table at SEC9.  The offsets in this table are defined in
;SB	the DISK_PARMS struc in MSDSKPRM.INC.  2 LOCS

	mov	al,ds:SEC9 + DISK_MOTOR_STRT
	mov	cs:MotorStartup,al
;SB34INIT002******************************************************************
	CMP	MODEL_BYTE,0FDH       ; IS THIS AN OLD ROM?	ARR 2.41
	JB	NO_DIDDLE		; NO			  ARR 2.41
	MOV	WORD PTR DS:(SEC9 + DISK_HEAD_STTL),0200H+NORMSETTLE
					; SET HEAD SETTLE AND MOTOR START
					; ON PC-1 PC-2 PC-XT HAL0 ARR 2.41
	MOV	DS:(SEC9 + DISK_SPECIFY_1),0DFH
					; SET 1ST SPECIFY BYTE
					; ON PC-1 PC-2 PC-XT HAL0 ARR 2.41
NO_DIDDLE:				;			  ARR 2.41
	INT	12H			;GET MEMORY SIZE--1K BLOCKS IN AX
	MOV	CL,6
	SHL	AX,CL			;CONVERT TO 16-BYTE BLOCKS(SEGMENT NO.)
	POP	CX			; RETREIVE BOOT DRIVE NUMBER, AND FAT ID
	MOV	DRVFAT,CX	      ;SAVE DRIVE TO LOAD DOS, AND FAT ID

	PUSH	AX
;J.K. Don't have to look at the boot addr.
;	 MOV	 DX,DS:(7C00H + 16H)	 ; NUMBER OF SECTORS/FAT FROM BOOT SEC
;an004
;	 mov	 dx, cs:Boot_Sec_Per_FAT  ;AC000;Do not use the bpb info from Boot record any more.
;	 XOR	 DH,DH
;	 MOV	 FATLEN,DX
;
; CONVERT SECTOR COUNT TO PARAGRAPH COUNT:512 BYTES / SEC / 16 BYTES / PARA
; = 32 PARA /SECTOR
;

;	 SHL	 DX,1
;	 SHL	 DX,1
;	 SHL	 DX,1
;	 SHL	 DX,1
;	 SHL	 DX,1
;	 SUB	 AX,DX			 ; ROOM FOR FAT
	sub	ax, 64			;AN004; Room for FATLOC segment. (1 KB buffer)
	MOV	FATLOC,AX		; LOCATION TO READ FAT
	sub	ax, 64			;Room for Boot Record buffer segment (1 KB)
	mov	Init_BootSeg, ax	;AN015;
	POP	AX

	MOV	DX,SYSINITSEG
	MOV	DS,DX

	ASSUME	DS:SYSINITSEG

	MOV	WORD PTR DEVICE_LIST,OFFSET CONHEADER
	MOV	WORD PTR DEVICE_LIST+2,CS

	MOV	MEMORY_SIZE,AX
	INC	CL
	MOV	DEFAULT_DRIVE,CL	;SAVE DEFAULT DRIVE SPEC

;DOSSEG  = (((END$ - START$)+15)/16)+BIOSEG+SYSIZE

; BAS DEBUG
;MOV	 CURRENT_DOS_LOCATION,(((END$ - START$)+15)/16)+SYSIZE
	MOV	AX, OFFSET END$
	SUB	AX, OFFSET START$
	ADD	AX, 15
	RCR	AX, 1			; DIVIDE BY 16
	SHR	AX, 1
	SHR	AX, 1
	SHR	AX, 1
	ADD	AX, SYSIZE
	ADD	AX, CODE
	MOV	CURRENT_DOS_LOCATION, AX
; BAS DEBUG
;	ADD	CURRENT_DOS_LOCATION,CODE

; IMPORTANT: SOME OLD IBM HARDWARE GENERATES SPURIOUS INT F'S DUE TO BOGUS
; PRINTER CARDS.  WE INITIALIZE THIS VALUE TO POINT TO AN IRET ONLY IF

; 1) THE ORIGINAL SEGMENT POINTS TO STORAGE INSIDE VALID RAM.

; 2) THE ORIGINAL SEGMENT IS 0F000:XXXX

; THESES ARE CAPRICIOUS REQUESTS FROM OUR OEM FOR REASONS BEHIND THEM, READ
; THE DCR'S FOR THE IBM DOS 3.2 PROJECT.

	PUSH	AX

	ASSUME	ES:SYSINITSEG, DS:NOTHING

	MOV	AX,SYSINITSEG
	MOV	ES,AX

	XOR	AX,AX			; AX := SEGMENT FOR INT 15
	MOV	DS,AX
	MOV	AX,WORD PTR DS:(0FH*4+2)

	CMP	AX,ES:MEMORY_SIZE     ; CONDITION 1
	JNA	RESETINTF

	CMP	AX,0F000H		; CONDITION 2
	JNE	KEEPINTF

RESETINTF:
	MOV	WORD PTR DS:[0FH*4],OFFSET INTRET
	MOV	WORD PTR DS:[0FH*4+2],CS
KEEPINTF:
	POP	AX

; END IMPORTANT

;SB34INIT003****************************************************************
;SB We will check if the system has IBM extended key board by
;SB looking at a byte at 40:96.  If bit 4 is set, then extended key board
;SB is installed, and we are going to set KEYRD_Func to 10h, KEYSTS_Func to 11h
;SB for the extended keyboard function. Use cx as the temporary register. 8 LOCS

	xor	cx,cx
	mov	ds,cx
	assume	ds:nothing
	mov	cl,ds:0496h			; get keyboard flag
	test	cl,00010000b
	jz	ORG_KEY				; orginal keyboard
	mov	byte ptr KEYRD_func,10h		; extended keyboard
	mov	byte ptr KEYSTS_func,11h	; change for extended keyboard functions
ORG_KEY:

;SB34INIT003****************************************************************

;**************************************************************
;	WILL INITIALIZE THE NUMBER OF DRIVES
;	AFTER THE EQUIPMENT CALL (INT 11H) BITS 6&7 WILL TELL
;	THE INDICATIONS ARE AS FOLLOWS:
;
;	BITS	7	6	DRIVES
;		0	0	1
;		0	1	2
;		1	0	3
;		1	1	4
;**************************************************************
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES

	ASSUME	DS:CODE,ES:CODE

	call	CMOS_Clock_Read     ;Before doing anythig else if CMOS clock exists,
				    ;then set the system time according to that.
				    ;Also, reset the cmos clock rate.

	MESSAGE FTESTINIT,<"DISK DEVICES",CR,LF>

	XOR	SI,SI
	MOV	WORD PTR [SI],OFFSET HARDDRV ;SET UP POINTER TO HDRIVE

	POP	AX			;NUMBER OF FLOPPIES AND FAT ID
	XOR	AH,AH			; CHUCK FAT ID BYTE
	MOV	HARDNUM,AL	      ;REMEMBER WHICH DRIVE IS HARD DISK
	MOV	DRVMAX,AL	      ;AND SET INITIAL NUMBER OF DRIVES
	SHL	AX,1			;TWO BYTES PER ADDRESS
	MOV	DI,OFFSET DSKDRVS
	ADD	DI,AX			;POINT TO HARDFILE LOCATION
	MOV	SI,OFFSET HDSKTAB
	MOVSW				;TWO ADDRESSES TO MOVE
	MOVSW
	MESSAGE FTESTINIT,<"BEFORE INT 13",CR,LF>
;SB33021********************************************************************
	mov	DL, 80h     ;SB 	; tell rom bios to look at hard drives
	mov	AH, 8h	    ;SB 	; set command to get drive parameter
	int	13h	    ;SB 	; call ROM-BIOS to get number of drives
;SB33021********************************************************************
	JC	ENDDRV			;CARRY INDICATES OLD ROM, SO NO HARDFILE
	MOV	HNUM,DL
ENDDRV:
	MESSAGE FTESTINIT,<"SETTING UP BDSS",CR,LF>

;
; SCAN THE LIST OF DRIVES TO DETERMINE THEIR TYPE.  WE HAVE THREE FLAVORS OF
; DISKETTE DRIVES:
;
;   48TPI DRIVES    WE DO NOTHING SPECIAL FOR THEM
;   96TPI DRIVES    MARK THE FACT THAT THEY HAVE CHANGELINE SUPPORT.
;   3 1/4 DRIVES    MARK CHANGELINE SUPPORT AND SMALL.
;
; THE FOLLOWING CODE USES REGISTERS FOR CERTAIN VALUES:
;   DL - PHYSICAL DRIVE
;   DS:DI - POINTS TO CURRENT BDS
;   CX - FLAG BITS FOR BDS
;   DH - FORM FACTOR FOR THE DRIVE (1 - 48TPI, 2 - 96TPI, 3 - 3.5" MEDIUM)
;
	XOR	DL,DL			; START OUT WITH DRIVE 0.
	PUSH	CS
	POP	DS
	ASSUME	DS:CODE

	MOV	EOT,9
	MOV	DI,OFFSET START_BDS
;J.K.6/24/87 Check if the system has no physical diskette drives.
;J.K. If it is, then we don't have to set BDS tables.  But since we
;J.K. pretend that we have 2 floppies, we are going to reserve two
;J.K. BDS tables for the fake drive A, and B. and set the end of link
;J.K. pointer.

;SB34INIT004*********************************************************
;SB	Check to see if we are faking floppy drives.  If not we don't 
;SB	do anything special.  If we are faking floppy drives we need
;SB	to set aside two BDSs for the two fake floppy drives.  We 
;SB	don't need to initalise any fields though. So starting at START_BDS
;SB	use the link field in the BDS structure to go to the second BDS
;SB	in the list and initalise it's link field to -1 to set the end of
;SB	the list.  Then jump to the routine at DoHard to allocate/initialise
;SB     the BDS for HardDrives.

	cmp	cs:FakeFloppyDrv,1
	jnz	LOOP_DRIVE		; system has floppy
	mov	di,word ptr [di].link	; di <- first BDS link
	mov	di,word ptr [di].link	; di <- second BDS link
	mov	word ptr [di].link,-1	; set end of link
	jmp	DoHard			; allocate/initialise BDS for HardDrives
;SB34INIT004*********************************************************

LOOP_DRIVE:
	CMP	DL,DRVMAX
	JB	GOT_MORE
	JMP	DONE_DRIVES
GOT_MORE:
	XOR	CX,CX			; ZERO ALL FLAGS
	MOV	DI,WORD PTR [DI].LINK	; GET NEXT BDS
	MOV	DH,FF48TPI		; SET FORM FACTOR TO 48 TPI
	MOV	NUM_CYLN,40	      ; 40 TRACKS PER SIDE

	PUSH	DS
	PUSH	DI
	PUSH	DX
	PUSH	CX
	PUSH	ES

;SB33022********************************************************************
	MOV	AH, 8h			;GET DRIVE PARAMETERS	       ;SB;3.30
	INT	13h			;CALL ROM-BIOS		       ;SB;3.30
;SB33022********************************************************************
	JNC	PARMSFROMROM
	JMP	NOPARMSFROMROM		; GOT AN OLD ROM
PARMSFROMROM:
;J.K. 10/9/86 If CMOS is bad, it gives ES,AX,BX,CX,DH,DI=0. CY=0.
;In this case, we are going to put bogus informations to BDS table.
;We are going to set CH=39,CL=9,DH=1 to avoid divide overflow when
;they are calculated at the later time.  This is just for the Diagnostic
;Diskette which need MSBIO,MSDOS to boot up before it sets CMOS.
;This should only happen with drive B.

	CMP	CH,0			; if ch=0, then cl,dh=0 too.
	JNE	PFR_OK
	MOV	CH,39			; ROM gave wrong info.
	MOV	CL,9			; Let's default to 360K.
	MOV	DH,1
PFR_OK:
	INC	DH			; MAKE NUMBER OF HEADS 1-BASED
	INC	CH			; MAKE NUMBER OF CYLINDERS 1-BASED
	MOV	NUM_HEADS,DH	      ; SAVE PARMS RETURNED BY ROM
	AND	CL,00111111B		; EXTRACT SECTORS/TRACK
	MOV	SEC_TRK,CL
	MOV	NUM_CYLN,CH	      ; ASSUME LESS THAN 256 CYLINDERS!!
; MAKE SURE THAT EOT CONTAINS THE MAX NUMBER OF SEC/TRK IN SYSTEM OF FLOPPIES
	CMP	CL,EOT			; MAY SET CARRY
	JBE	EOT_OK
	MOV	EOT,CL
EOT_OK:
	POP	ES
	POP	CX
	POP	DX
	POP	DI
	POP	DS

; CHECK FOR CHANGELINE SUPPORT ON DRIVE
;SB33023********************************************************************
	mov	AH, 15h      ;SB	; set command to get DASD type
	int	13h	     ;SB	; call ROM-BIOS
;SB33023********************************************************************
	JC	CHANGELINE_DONE
	CMP	AH,02			; CHECK FOR PRESENCE OF CHANGELINE
	JNE	CHANGELINE_DONE
;
; WE HAVE A DRIVE WITH CHANGE LINE SUPPORT.
;
	MESSAGE FTESTINIT,<"96TPI DEVICES",CR,LF>

	OR	CL,FCHANGELINE		; SIGNAL TYPE
	MOV	FHAVE96,1		; REMEMBER THAT WE HAVE 96TPI DISKS
;
; WE NOW TRY TO SET UP THE FORM FACTOR FOR THE TYPES OF MEDIA THAT WE KNOW
; AND CAN RECOGNISE. FOR THE REST, WE SET THE FORM FACTOR AS "OTHER".
;
CHANGELINE_DONE:
; 40 CYLINDERS AND 9 OR LESS SEC/TRK, TREAT AS 48 TPI MEDIUM.
	CMP	NUM_CYLN,40
	JNZ	TRY_80
	CMP	SEC_TRK,9
	JBE	GOT_FF
GOTOTHER:
	MOV	DH,FFOTHER		; WE HAVE A "STRANGE" MEDIUM
	JMP	SHORT GOT_FF

;
; 80 CYLINDERS AND 9 SECTORS/TRACK => 720 KB DEVICE
; 80 CYLINDERS AND 15 SEC/TRK => 96 TPI MEDIUM
;
TRY_80:
	CMP	NUM_CYLN,80
	JNZ	GOTOTHER
	CMP	SEC_TRK,15
	JZ	GOT96
	CMP	SEC_TRK,9
	JNZ	GOTOTHER
	MOV	DH,FFSMALL
	JMP	SHORT GOT_FF

GOT96:
	MOV	DH,FF96TPI

GOT_FF:
	JMP	SHORT NEXTDRIVE

; WE HAVE AN OLD ROM, SO WE EITHER HAVE A 48TPI OR 96TPI DRIVE. IF THE DRIVE
; HAS CHANGELINE, WE ASSUEM IT IS A 96TPI, OTHERWISE WE TREAT IT AS A 48TPI.

NOPARMSFROMROM:
	POP	ES
	POP	CX
	POP	DX
	POP	DI
	POP	DS

;SB33024****************************************************************
	MOV	AH, 15h 		; SET COMMAND TO GET DASD TYPE ;SB;3.30
	INT	13h			; CALL ROM-BIOS 	       ;SB;3.30
;SB33024****************************************************************
	JC	NEXTDRIVE
	CMP	AH,2			; IS THERE CHANGELINE?
	JNZ	NEXTDRIVE
	OR	CL,FCHANGELINE
	MOV	FHAVE96,1		; REMEMBER THAT WE HAVE 96TPI DRIVES
	MOV	NUM_CYLN,80
	MOV	DH,FF96TPI
	MOV	AL,15			; SET EOT IF NECESSARY
	CMP	AL, EOT
	JBE	EOT_OK2
	MOV	EOT,AL
EOT_OK2:

NEXTDRIVE:
	OR	CL,FI_OWN_PHYSICAL	; SET THIS TRUE FOR ALL DRIVES
	MOV	BH,DL			;SAVE INT13 DRIVE NUMBER

; WE NEED TO DO SPECIAL THINGS IF WE HAVE A SINGLE DRIVE SYSTEM AND ARE SETTING
; UP A LOGICAL DRIVE. IT NEEDS TO HAVE THE SAME INT13 DRIVE NUMBER AS ITS
; COUNTERPART, BUT THE NEXT DRIVE LETTER. ALSO RESET OWNERSHIP FLAG.
; WE DETECT THE PRESENCE OF THIS SITUATION BY EXAMINING THE FLAG SINGLE FOR THE
; VALUE 2.

	CMP	SINGLE,2
	JNZ	NOT_SPECIAL
	DEC	BH			; INT13 DRIVE NUMBER SAME FOR LOGICAL DRIVE
	XOR	CL,FI_OWN_PHYSICAL	; RESET OWNERSHIP FLAG FOR LOGICAL DRIVE
NOT_SPECIAL:
; THE VALUES THAT WE PUT IN FOR RHDLIM AND RSECLIM WILL ONLY REMAIN IF THE
; FORM FACTOR IS OF TYPE "FFOTHER".
	XOR	AX,AX
	MOV	AL,NUM_HEADS
	MOV	WORD PTR [DI].RHDLIM,AX
	MOV	AL,SEC_TRK
	MOV	WORD PTR [DI].RSECLIM,AX
	MOV	WORD PTR [DI].FLAGS,CX
	MOV	BYTE PTR [DI].FORMFACTOR,DH
	MOV	BYTE PTR [DI].DRIVELET,DL
	MOV	BYTE PTR [DI].DRIVENUM,BH
	MOV	BL,BYTE PTR NUM_CYLN
	MOV	BYTE PTR [DI].CCYLN,BL	; ONLY THE L.S. BYTE IS SET HERE
	CMP	SINGLE,1		; SPECIAL CASE FOR SINGLE DRIVE SYSTEM
	JNZ	NO_SINGLE
	MESSAGE FTESTINIT,<"SINGLE DRIVE SYSTEM",CR,LF>
	MOV	SINGLE,2		; DON'T LOSE INFO THAT WE HAVE SINGLE SYSTEM
	OR	CX,FI_AM_MULT
	OR	WORD PTR [DI].FLAGS,CX
	MOV	DI,WORD PTR [DI].LINK	; MOVE TO NEXT BDS IN LIST
	INC	DL
	JMP	SHORT NEXTDRIVE 	; USE SAME INFO FOR BDS A PREVIOUS
NO_SINGLE:
	INC	DL
	JMP	LOOP_DRIVE

DONE_DRIVES:
	MOV	AX,-1			; SET LINK TO NULL
	MOV	WORD PTR [DI].LINK,AX

; SET UP ALL THE HARD DRIVES IN THE SYSTEM

DOHARD:
	MNUM	FTESTINIT+FTESTHARD,AX
	MESSAGE FTESTINIT+FTESTHARD,<" HARD DISK(S) TO INITIALIZE",CR,LF>
	MESSAGE FTESTINIT+FTESTHARD,<"HARD DISK 1",CR,LF>

	CMP	HNUM,0		      ; IF (NO_HARD_FILES)
	JLE	STATIC_CONFIGURE      ;   THEN EXIT TO CONFIGURE

	MOV	DL,80H
	MOV	DI,OFFSET BDSH		; SET UP FIRST HARD FILE.
	MOV	BL,HARDNUM
	CALL	SETHARD
	assume	es:nothing
	JNC	HARDFILE1_OK

	DEC	HNUM		      ; FIRST HARD FILE IS BAD.
	CMP	HNUM,0		      ; IF (SECOND_HARD_FILE)
	JG	SECOND_HARD		;   THEN SET UP SECOND HARD FILE
	JMP	SHORT STATIC_CONFIGURE

HARDFILE1_OK:
	CALL	INSTALL_BDS		; INSTALL BDS INTO LINKED LIST
	CMP	HNUM,2		      ; IF (ONLY_ONE_HARDFILE)
	JB	SETIT			;   THEN SETIT "IN PLACE"

	MOV	BL,HARDNUM
	INC	BL			; NEXT DRIVE LETTER
	MOV	DI,OFFSET BDSX

SECOND_HARD:				; SETUP SECOND HARD FILE

	MESSAGE FTESTINIT+FTESTHARD,<"HARD DISK 2",CR,LF>
	MOV	DL,81H			; NEXT HARD FILE
	CALL	SETHARD
	assume	es:nothing
	JNC	HARDFILE2_OK
	DEC	HNUM
	JMP	SHORT SETIT

HARDFILE2_OK:
	CALL	INSTALL_BDS

SETIT:
	MOV	AL,HNUM
	OR	AL,AL
	JZ	STATIC_CONFIGURE
	ADD	AL,HARDNUM
	MOV	DRVMAX,AL

; End of physical drive initialization.
; *** Do not change the position of the following statement.-J.K.4/7/86
; *** DoMini routine will use [DRVMAX] value for the start of the logical
; *** drive number of Mini disk(s).

       call    DoMini			       ;For setting up mini disks, if found -J.K.

	assume	es:nothing
; END OF DRIVE INITIALIZATION.

;J.K. 9/24/86 We now decide, based on the configurations available so far, what
;code or data we need to keep as a stay resident code.	The following table
;shows the configurations under consideration.	They are listed in the order
;of their current position memory.
;Configuration will be done in two ways:
;First, we are going to set "Static configuration".  Static configuration will
;consider from basic configuration to ENDOF96TPI configuration.  The result
;of static configuration will be the address the Dynamic configuration will
;use to start with.
;Secondly, "Dynamic cofiguration" will be performed.  Dynamic configuration
;involves possible relocation of CODE or DATA.	Dynamic configuration routine
;will take care of BDSM tables and AT ROM Fix module thru K09 suspend/resume
;code individually.  After these operation, FINAL_DOS_LOCATION will be set.
;This will be the place SYSINIT routine will relocate MSDOS module for good.
;
;   1.	 BASIC CONFIGURATION FOR IBMBIO (EndFloppy, EndSwap)
;   2.	 ENDONEHARD
;   3.	 ENDTWOHARD
;   4.	 END96TPI	;a system that supports "Change Line Error"
;   5.	 End of BDSM	;BDSM tables for mini disks.
;   6.	 ENDATROM	;Some of AT ROM fix module.
;   7.	 ENDCMOSCLOCKSET;Supporting program for CMOS clock write.
;   8.	 ENDK09 	;K09 CMOS Clock module to handle SUSPEND/RESUME operation.
;
;J.K. 9/24/86.

; *** For mini disk configuration. -J.K. 4/7/86
; *** END_OF_BDSM will contains the ending address(offset) of BDSM table for
; *** mini disks which is located right after the label END96TPI.
; *** The variable NUM_MINI_DSK will indicate the existance of the mini disk.-J.K. 4/7/86


STATIC_CONFIGURE:


	PUSH	AX
	mov	ax, offset END96TPI	;let's start with the biggest one.
	cmp	fHave96, 0		;Is change line support there?
	jnz	Config96		;Yes.

	mov	ax, offset ENDTWOHARD
	cmp	HNUM, 1 		;1 hard file?
	jbe	No_Two_HRD
	jmp	ConfigTwoHard
No_Two_HRD:
	mov	ax, offset ENDONEHARD
	jnz	Basic_Floppy
	jmp	ConfigOneHard
Basic_Floppy:
	mov	ax, offset ENDFLOPPY
	jmp	Dynamic_Configure	;static configuration is done!

;
; KEEP THE 96TPI CODE
;
CONFIG96:
;
; SAVE OLD INT 13 VECTOR
;
	PUSH	AX
	PUSH	DS
	XOR	AX,AX
	MOV	DS,AX
	ASSUME	DS:NOTHING

	MOV	AX,DS:[4 * 13H]
	MOV	WORD PTR CS:REAL13,AX
	MOV	AX,DS:[4 * 13H+2]
	MOV	WORD PTR CS:REAL13+2,AX
;
; INSERT NEW VECTOR
;
	MOV	WORD PTR DS:[4 * 13H],OFFSET INT13
	MOV	DS:[4 * 13H + 2],CS

	POP	DS
	ASSUME DS:CODE

	POP	AX

; KEEP TWO HARD DISK BPBS

CONFIGTWOHARD:

; KEEP ONE HARD DISK BPB

CONFIGONEHARD:

; ADJUST THE NUMBER OF DRIVES TO INCLUDE THE HARD DISKS.

	PUSH	AX

	MOV	AL,HARDNUM
	ADD	AL,HNUM
	add	al, num_mini_dsk		;J.K. 4/7/86 for mini disks installed
						;if not installed, then num_mini_dsk = 0.
	MOV	DRVMAX,AL
	POP	AX				;now, static config is done.


DYNAMIC_CONFIGURE:
	call	Get_Para_Offset 		;For dynamic allocation, we are
						;going to use offset address that
						;is in paragraph boundary.
	push	cs
	pop	es				;es -> code
	assume	es:code
	cld					;clear direction

	cmp	[num_mini_dsk], 0		;Mini disk(s) installed ?
	jz	CheckATROM			;No.
	mov	ax, End_Of_BDSM 		;set the new ending address
	call	Get_Para_Offset
CheckATROM:
	cmp	Model_Byte, 0FCh		;AT ?
	jnz	CheckCMOSClock
	cmp	HNUM, 0 			;No hard file?
	jz	CheckCMOSClock

	mov	si, 0F000h
	mov	es, si			       ;ES -> BIOS segment
	assume	es:nothing		       ;
	mov	si, offset BIOS_DATE	       ;
	mov	di, 0FFF5H		       ;ROM BIOS string is at F000:FFF5
Cmpbyte:				       ;Only patch ROM for bios dated 01/10/84
	cmpsb				       ;
	jnz	CheckCMOSClock		       ;
	cmp	byte ptr [si-1],0	       ;
	jnz	Cmpbyte 		       ;
SetRomCode:				       ;Now we have to install ROM fix
					       ;AX is the address to move.
	push	cs			       ;
	pop	es			       ;set ES to CODE seg
	assume	es:code

	mov	word ptr ORIG13, ax
	mov	word ptr ORIG13+2, cs		;set new ROM bios int 13 vector
	mov	cx, offset ENDATROM
	mov	si, offset IBM_DISK_IO
	sub	cx, si				;size of AT ROM FIX module
	mov	di, ax				;destination
	rep	movsb				;relocate it
	mov	ax, di				;new ending address
	call	Get_Para_Offset 		;in AX

CheckCMOSClock:
	push	cs
	pop	es				;set ES to CODE seg
	assume	es:code
	cmp	HaveCMOSClock, 1		;CMOS Clock exists?
	jne	CheckK09
	mov	DaycntToDay, ax 		;set the address for MSCLOCK
	mov	cx, offset EndDaycntToDay
	mov	si, offset Daycnt_To_Day
	sub	cx, si				;size of CMOS clock supporting routine
	mov	di, ax
	rep	movsb
	mov	ax, di
	call	Get_Para_Offset
	mov	BinToBCD, ax			;set the address for MSCLOCK
	mov	cx, offset EndCMOSClockSet
	mov	si, offset Bin_To_BCD
	sub	cx, si
	mov	di, ax
	rep	movsb
	mov	ax, di
	call	Get_Para_Offset

CheckK09:
;SB33025****************************************************************
	push	ax			;save ax		     ;SB  ;3.30*
	mov	ax,4100h		;Q: is it a K09 	     ;SB  ;3.30*
	mov	bl,0			;			     ;SB  ;3.30*
	int	15h			;			     ;SB  ;3.30*
;SB33025****************************************************************
	pop	ax
	jc	CONFIGDONE

	mov	si, offset INT6C
	mov	cx, offset ENDK09
	sub	cx, si				;size of K09 routine
	mov	di, ax
	push	di				;save destination
	rep	movsb
	mov	ax, di				;
	call	Get_Para_Offset 		;AX = new ending address
	pop	di

	push	ax
	push	ds
	mov	fHaveK09, 1			;remember we have a K09 type
	xor	ax,ax
	mov	ds, ax
	assume	ds:nothing

	mov	word ptr ds:[4 * 6Ch], di	;new INT 6Ch handler
	mov	ds:[4 * 6Ch +2], cs

	pop	ds
	assume	ds:code
	pop	ax				;restore the ending address

; SET UP CONFIG STUFF FOR SYSINIT

CONFIGDONE:			;AX is final ending address of MSBIO.
	MOV	DX,SYSINITSEG
	MOV	DS,DX
	ASSUME	DS:SYSINITSEG

	SUB	AX,OFFSET START$
	ADD	AX,15
	RCR	AX,1
	SHR	AX, 1
	SHR	AX, 1
	SHR	AX, 1
	MOV	FINAL_DOS_LOCATION, AX
	POP	AX

GOINIT:
	ADD	FINAL_DOS_LOCATION,CODE
	MESSAGE FTESTINIT,<"FINAL DOS LOCATION IS ">
	MNUM	FTESTINIT,FINAL_DOS_LOCATION
	MESSAGE FTESTINIT,<CR,LF>
	PUSH	CS
	POP	DS

	ASSUME	DS:CODE,ES:NOTHING

	CMP	BYTE PTR FHAVE96,0
	JNZ	READDOS
	CALL	PURGE_96TPI		;MJB001 ELIMINATE CALLS TO 96TPI HOOHAH

READDOS:
	MESSAGE FTESTINIT,<"LOAD FAT",CR,LF>
	MOV	AX,DRVFAT		; GET DRIVE AND FAT ID
	CALL	SETDRIVE		; GET BDS FOR DRIVE

	CALL	GETBP			; ENSURE VALID BPB IS PRESENT

;AN004; J.K. Don't need this. We are not read the whole FAT at once.
;	 CALL	 GETFAT 		 ;READ IN THE FAT SECTOR

	XOR	DI,DI
	MOV	AL,ES:[DI]		;GET FAT ID BYTE
	MOV	BYTE PTR DRVFAT+1,AL	;SAVE FAT BYTE
	MOV	AX,DRVFAT
	MESSAGE FTESTINIT,<"FATID READ ">
	MNUM	FTESTINIT,AX
	MESSAGE FTESTINIT,<CR,LF>
	CALL	SETDRIVE		;GET CORRECT BDS FOR THIS DRIVE

	mov	bx, [di].BYTEPERSEC
	mov	cs:Md_SectorSize, bx	;AN004;Used by Get_Fat_Sector proc.
	MOV	BL,[DI].FATSIZ		; GET SIZE OF FAT ON MEDIA
	MOV	FBIGFAT,BL
	MOV	CL,[DI].SECPERCLUS	;GET SECTORS/CLUSTER
;J.K.32 bit calculation
	MOV	AX,[DI].HIDSEC_L	;GET NUMBER OF HIDDEN SECTORS (low)
	SUB	BIOS$_L,AX		;SUBTRACT HIDDEN SECTORS since we
					;need a logical sector number that will
					;be used by GETCLUS(diskrd procedure)
;SB34INIT005******************************************************************
;SB	We have 32 bit sector number now though. SO the high word also needs
;SB	to be adjusted.  Update BIOS$_H too.  2 LOCS

	mov	ax,[di].HIDSEC_H	;subtract upper 16 bits of sector num
	sbb	BIOS$_H,ax
;SB34INIT005******************************************************************
	XOR	CH,CH			;CX = SECTORS/CLUSTER

;	THE BOOT PROGRAM HAS LEFT THE DIRECTORY AT 0:500

	PUSH	DS
	XOR	DI,DI
	MOV	DS,DI			; ES:DI POINTS TO LOAD LOCATION
	MOV	BX,DS:WORD PTR [53AH]	;   CLUS=*53A;
	POP	DS			;
	MESSAGE FTESTINIT,<"LOAD DOS",CR,LF>
; BAS DEBUG
;LOADIT: MOV	 AX,(((END$ - START$)+15)/16)+SYSIZE

LOADIT:
	MOV	AX, OFFSET END$
	SUB	AX, OFFSET START$
	ADD	AX, 15
	RCR	AX, 1			; DIVIDE BY 16
	SHR	AX, 1
	SHR	AX, 1
	SHR	AX, 1
	ADD	AX, SYSIZE

	ADD	AX,CODE

	MOV	ES,AX			;
	CALL	GETCLUS 		;	CLUS = GETCLUS (CLUS);

ISEOF:
	TEST	FBIGFAT,FBIG		;   IF (FBIGFAT)
	JNZ	EOFBIG
	  MESSAGE FTESTINIT,<CR,LF,"SMALL FAT EOF CHECK",CR,LF>
	CMP	BX,0FF7H		;	RETURN (CLUS > 0FF7H);
	JMP SHORT ISEOFX
EOFBIG:
	  MESSAGE FTESTINIT,<CR,LF,"BIG FAT EOF CHECK",CR,LF>
	CMP	BX,0FFF7H		;   ELSE
ISEOFX:
	JB	LOADIT			;   } WHILE (!ISEOF (CLUS));

	CALL	SETDRVPARMS

	MESSAGE FTESTINIT,<"SYSINIT",CR,LF>
	ZWAIT
	MESSAGE FTESTINIT,<"ON TO SYSINIT...",CR,LF>
	JMP	SYSINIT

INIT	ENDP

;****************************

Get_Para_Offset proc	near
;in:  AX - offset value
;out: AX - offset value adjusted for the next paragraph boundary.
	add	ax, 15		;make a paragraph
	rcr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shl	ax, 1		;now, make it back to offset value
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	ret
Get_Para_Offset endp

;AN004; Don't need this procedure. Get_FAT_Sector replace this.
;	READ A FAT SECTOR INTO FAT LOCATION
;GETFAT  PROC	 NEAR
;	 XOR	 DI,DI			 ; OFFSET
;	 MOV	 DX,1			 ; RELATIVE SECTOR (1ST SECTOR OF FAT)
;	 MOV	 CX,FATLEN		 ; READ ENTIRE FAT.
;	 MOV	 AX,FATLOC		 ;
;	 MOV	 ES,AX			 ; LOCATION TO READ
;	 MOV	 AX,DRVFAT	       ; AH FAT ID BYTE, AL DRIVE
;	 JMP	 DISKRD
;GETFAT  ENDP

;	READ A BOOT RECORD INTO 7C0:BOOTBIAS
;AN015; Read a boot record into Init_BootSeg:BOOTBIAS

GETBOOT PROC	NEAR
;SB33026****************************************************************
	mov	AX, cs:Init_BootSeg	; prepare to load ES
	mov	ES, AX	      ;SB	; load ES segment register
	assume	es:nothing
	mov	BX, BootBias  ;SB	; load BX,  ES:BX is where sector goes
	mov	AX, 0201h     ;SB	; command to read & num sec. to 1
	xor	DH, DH	      ;SB	; head number zero
	mov	CX, 0001h     ;SB	; cylinder zero and sector one
	int	13h	      ;SB	; call rom bios
;SB33026****************************************************************
	JC	ERRET

	CMP	WORD PTR ES:[BOOTBIAS+1FEH],0AA55H ; DAVE L**** MAGIC BYTE?
	JZ	NORM_RET
	  MESSAGE FTESTHARD,<"SIGNATURE AA55 NOT FOUND",CR,LF>
ERRET:
	  MESSAGE FTESTHARD,<"ERROR IN GETBOOT",CR,LF>
	STC
NORM_RET:
	RET
GETBOOT ENDP

;   SETHARD - GENERATE BPB FOR A VARIABLE SIZED HARD FILE.  IBM HAS A
;   PARTITIONED HARD FILE; WE MUST READ PHYSICAL SECTOR 0 TO DETERMINE WHERE
;   OUR OWN LOGICAL SECTORS START.  WE ALSO READ IN OUR BOOT SECTOR TO
;   DETERMINE VERSION NUMBER

;   INPUTS:	DL IS ROM DRIVE NUMBER (80 OR 81)
;		DS:DI POINTS TO BDS
;   OUTPUTS:	CARRY CLEAR -> BPB IS FILLED IN
;		CARRY SET   -> BPB IS LEFT UNINITIALIZED DUE TO ERROR

SETHARD PROC	NEAR
	assume	ds:code,es:nothing
	PUSH	DI
	PUSH	BX
	PUSH	DS
	MOV	BYTE PTR [DI].DRIVELET,BL
	MOV	BYTE PTR [DI].DRIVENUM,DL
	XOR	AX,AX
	OR	AL,FNON_REMOVABLE
	OR	WORD PTR [DI].FLAGS,AX
	MOV	BYTE PTR [DI].FORMFACTOR,FFHARDFILE
	MOV	FBIGFAT,0		; ASSUME 12 BIT FAT
	PUSH	DX
;SB33027***************************************************************
	mov	AH, 8		 ;SB	; set command to get drive parameters
	int	13h		 ;SB	; call rom-bios disk routine
;SB33027***************************************************************
; DH IS NUMBER OF HEADS-1
; DL IS NUMBER OF HARD DISKS ATTACHED
; LOW 6 BITS OF CL IS SECTORS/TRACK
; HIGH 2 BITS OF CL WITH CH ARE MAX # OF CYLINDERS
	INC	DH			; GET NUMBER OF HEADS
	MOV	BYTE PTR [DI].HDLIM,DH
	POP	DX
	JC	SETRET			; CARRY HERE MEANS NO HARD DISK
	AND	CL,3FH			; EXTRACT NUMBER OF SECTORS/TRACK
	MOV	BYTE PTR [DI].SECLIM,CL
	CALL	GETBOOT 		;   IF (GETBOOT ())
	assume	es:nothing
	JC	SETRET			;	RETURN -1;
	MOV	BX,1C2H+BOOTBIAS	;   P = &BOOT[0X1C2];
SET1:
	CMP	BYTE PTR ES:[BX],1	;   WHILE (P->PARTITIONTYPE != 1 &&
	JZ	SET2

	CMP	BYTE PTR ES:[BX],4	;	P->PARTITIONTYPE != 4 &&
	JZ	SET2

;SB34INIT006******************************************************************
;SB	we have a new partition type 6 now. add code to support this too.

	cmp	byte ptr es:[bx],6	;	P->PARTITIONTYPE !=6
	jz	set2
;SB34INIT006******************************************************************

	ADD	BX,16			;	P += SIZEOF PARTITION;
	CMP	BX,202H+BOOTBIAS	;	IF (P == &BOOT[0X202H])
	JNZ	SET1			;	    RETURN -1;}

SETRET:
	STC				;AN000;  Note: Partitiontype 6 means either
	JMP	RET_HARD		;1).the partition has not been formatted yet, or
					;2).(# of sectors before the partition +
					;    # of sectors in this partition) > word boundary
					;	i.e., needs 32 bit sector calculation, or
					;3).the partition is not a FAT file system.

;J.K.  Until we get the real logical boot record and get the bpb,
;DRVLIM_H,DRVLIM_L will be used instead of DRVLIM for the convenience of
;the computation.
;At the end of this procedure, if a BPB information is gotten from
;the valid boot record, then we are going to use those BPB information
;without change.
;Otherwise, if (hidden sectors + total sectors) <= a word, then
;we will move DRVLIM_L to DRVLIM and zero out DRVLIM_L entry to make
;it a conventional BPB format.

SET2:
;	 PUSH	 DX	;AN000;
	mov	cs:ROM_drv_num, dl	;AN000; save the ROM BIOS drive number we are handling now.

	MOV	AX,WORD PTR ES:[BX+4]	;Hidden sectors
	MOV	DX,WORD PTR ES:[BX+6]


	;Decrement the sector count by 1 to make it zero based. Exactly 64k
	;sectors should be allowed
	;
	SUB	AX,1			; PTM 901    12/12/86 MT
	SBB	DX,0			; PTM 901    12/12/86 MT

	ADD	AX,WORD PTR ES:[BX+8]	;Sectors in Partition
	ADC	DX,WORD PTR ES:[BX+10]
;	 JZ	 OKDRIVE
	jnc	Okdrive 		;AC000;
	  MESSAGE FTESTHARD,<"PARTITION INVALID",CR,LF>
	OR	FBIGFAT,FTOOBIG
OKDRIVE:
;	 POP	 DX
	MOV	AX,WORD PTR ES:[BX+4]

	MOV	[DI].HIDSEC_L,AX	;   BPB->HIDSECCT = P->PARTITIONBEGIN;
	mov	ax,word ptr es:[bx+6]	;AN000;
	mov	[di].HIDSEC_H,ax	;AN000;

	mov	dx,word ptr es:[bx+10]	;AN000; # of sectors (High)
	MOV	AX,WORD PTR ES:[BX+8]	;# of sectors (Low)
	mov	word ptr [di].DRVLIM_H,dx ;AN000;
	MOV	WORD PTR [DI].DRVLIM_L,AX ;   BPB->MAXSEC = P->PARTITIONLENGTH;
	cmp	dx,0			;AN000;
	ja	OKDrive_Cont		;AN000;
	CMP	AX,64			;   IF (P->PARTITIONLENGTH < 64)
	JB	SETRET			;	RETURN -1;

OKDrive_Cont:				;AN000;
 ;	 PUSH	 DX			;AC000;
	mov	dx,[di].HIDSEC_H	;AN000;
	MOV	AX,[DI].HIDSEC_L	; BOOT SECTOR NUMBER - For mini disk,;J.K.
;	 XOR	 DX,DX			 ; this will be logical and equal to  ;AC000;
	xor	bx,bx			;usUally equal to the # of sec/trk.  ;J.K.
;	 MOV	 BH,DH			;AC000;
	MOV	BL,BYTE PTR [DI].SECLIM
	push	ax			;AN000;
	mov	ax,dx			;AN000;
	xor	dx,dx			;AN000;
	div	bx			;AN000;
	mov	cs:[Temp_H],ax		;AN000;
	pop	ax			;AN000;
	DIV	BX			;(Sectors)DX;AX / (Seclim)BX =(Track) Temp_H;AX + (Sector)DX
	MOV	CL,DL			; CL IS SECTOR NUMBER;J.K.Assume sector number < 255.
	INC	CL			; SECTORS ARE 1 BASED
;	 CWD				;AC000;

	xor	bx,bx			;AN000;
	MOV	BL,BYTE PTR [DI].HDLIM
	push	ax			;AN000;
	xor	dx,dx			;AN000;
	mov	ax, cs:[Temp_H] 	;AN000;
	div	bx			;AN000;
	mov	cs:[Temp_H],ax		;AN000;
	pop	ax			;AN000;
	DIV	BX			; DL IS HEAD, AX IS CYLINDER
	cmp	cs:[Temp_H],0		;AN000;
	ja	SetRet_brdg		;AN000; Exceeds the limit of Int 13h
	cmp	ax, 1024		;AN000;
	ja	SetRet_brdg		;AN000; Exceeds the limit of Int 13h

; DL IS HEAD.
; AX IS CYLINDER
; CL IS SECTOR NUMBER (assume less than 2**6 = 64 for INT 13h)

;*** For Mini Disks *** J.K. 4/7/86
	cmp	word ptr [di].ISMINI, 1 ;check for mini disk -J.K. 4/7/86
	jnz	OKnotMini		;not mini disk. -J.K. 4/7/86
	add	ax, [di].HIDDEN_TRKS	;set the physical track number -J.K. 4/7/86
OKnotMini:				;J.K. 4/7/86
;*** End of added logic for mini disk
	ROR	AH,1			; MOVE HIGH TWO BITS OF CYL TO HIGH
	ROR	AH,1			; TWO BITS OF UPPER BYTE
	AND	AH,0C0H 		; TURN OFF REMAINDER OF BITS
	OR	CL,AH			; MOVE TWO BITS TO CORRECT SPOT
	MOV	CH,AL			; CH IS CYLINDER

; CL IS SECTOR + 2 HIGH BITS OF CYLINDER
; CH IS LOW 8 BITS OF CYLINDER
; DL IS HEAD
; ROM_drv_num IS DRIVE

;	 POP	 AX			 ;AC000; AL IS DRIVE
	MOV	DH,DL			; DH IS HEAD
;	 MOV	 DL,AL			 ;AC000; DL IS DRIVE
	mov	dl, cs:ROM_drv_num	;AN000; Set the drive number

; CL IS SECTOR + 2 HIGH BITS OF CYLINDER
; CH IS LOW 8 BITS OF CYLINDER
; DH IS HEAD
; DL IS DRIVE
;J.K. For convenience, we are going to read the logical boot sector
;into cs:DiskSector area.

;SB34INIT009*************************************************************
;SB  Read in boot sector using BIOS disk interrupt.  The buffer where it
;SB  is to be read in is cs:Disksector.
;SB	5 LOCS

	push	cs
	pop	es
	mov	bx,offset DiskSector
	mov	ax,0201h	; read, one sector
	int	13h

;SB34INIT009*************************************************************

; cs:Disksec contains THE BOOT SECTOR.	IN THEORY, (HA HA) THE BPB IN THIS THING
; IS CORRECT.  WE CAN, THEREFORE, SUCK OUT ALL THE RELEVANT STATISTICS ON THE
; MEDIA IF WE RECOGNIZE THE VERSION NUMBER.
	mov	bx, offset DiskSector	;AN000;
; look for a signature for msdos...
	cmp	word ptr cs:[bx+3], "S" shl 8 + "M"
	jnz	notmssig
	cmp	word ptr cs:[bx+5], "O" shl 8 + "D"
	jnz	notmssig
	cmp	byte ptr cs:[bx+7], "S"
	je	sigfound
; ...or perhaps pcdos...
notmssig:
	CMP	WORD PTR cs:[bx+3], "B" SHL 8 + "I"
	jnz	notibmsig
	CMP	WORD PTR cs:[bx+5], " " SHL 8 + "M"
 	je	sigfound
;----------------------------------------------------------------------
;	check for Microsoft OS/2 signature also. 7/29/88. HKN
notibmsig:
	CMP	WORD PTR cs:[bx+3], "S" SHL 8 + "O"
	JNZ	UNKNOWNJ
	CMP	WORD PTR cs:[bx+5], " " SHL 8 + "2"
	JNZ	UNKNOWNJ
;-----------------------------------------------------------------------
	
sigfound:			; signature was found, now check version
	CMP	WORD PTR cs:[bx+8], "." SHL 8 + "2"
	JNZ	TRY5
	CMP	BYTE PTR cs:[bx+10], "0"
	JNZ	TRY5
	MESSAGE FTESTHARD,<"VERSION 2.0 MEDIA",CR,LF>
	JMP	SHORT COPYBPB

SetRet_Brdg:
	jmp	SETRET

UNKNOWNJ:
	JMP	UNKNOWN 			;Unformatted or illegal media.
UNKNOWN3_0_J:					;AN012;Legally formatted media,
	jmp	Unknown3_0			;AN012; although, content might be bad.

TRY5:
	call	Cover_Fdisk_Bug 		;AN010;
	CMP	WORD PTR cs:[bx+8],"." SHL 8 + "3"
	jb	Unknown3_0_J			;AN012; Must be 2.1 boot record. Do not trust it, but still legal.
	JNZ	COPYBPB 			;AN007; Honor OS2 boot record, or DOS 4.0 version
	cmp	byte ptr cs:[bx+10],"1"         ;do not trust 3.0 boot record. But still legal J.K. 4/15/86
	jb	UnKnown3_0_J			;AN012; if version >= 3.1, then O.K.
	Message ftestHard,<"VERSION 3.1 OR ABOVE MEDIA",CR,LF>

COPYBPB:
; WE HAVE A VALID BOOT SECTOR. USE THE BPB IN IT TO BUILD THE
; BPB IN BIOS. IT IS ASSUMED THAT ONLY SECPERCLUS, CDIR, AND
; CSECFAT NEED TO BE SET (ALL OTHER VALUES IN ALREADY). FBIGFAT
; IS ALSO SET.

;If it is non FAT based system, then just copy the BPB from the BOOT sector
;into the BPB in BDS table, and also set the Boot serial number, Volume id,
;and System ID according to the Boot record.
;For the non_FAT system, don't need to set the other value. So just
;do GOODRET.- J.K.

	cmp	cs:[Ext_Boot_Sig], EXT_BOOT_SIGNATURE ;AN000;
	jne	COPYBPB_FAT		;AN000; Conventional Fat system
	cmp	cs:[NumberOfFats], 0	;AN000; If (# of FAT <> 0) then
	jne	COPYBPB_FAT		;AN000;   a Fat system.
;J.K. Non Fat based media.
	push	di			;AN000; Sav Reg.
	push	ds			;AN000;

	push	ds			;AN000;
	pop	es			;AN000; now es:di -> bds
	push	cs			;AN000;
	pop	ds			;AN000; ds = cs

	mov	si, offset Bpb_In_Sector ;AN000; ds:si -> BPB in Boot
	add	di, BYTEPERSEC		;AN000; es:di -> BPB in BDS
	mov	cx, size BPB_TYPE	;AN000;
	rep	movsb			;AN000;

	pop	ds			;AN000; Restore Reg.
	pop	di			;AN000;
	call	Mov_Media_IDs		;AN000; Set Volume id, SystemId, Serial.
	jmp	GoodRet

COPYBPB_FAT:				;AN000;  Fat system
	xor	dx,dx			;AN000;
	mov	si, offset Bpb_In_Sector ;AN000;  cs:bx -> bpb in boot
	mov	ax, cs:[si.SECNUM]	;AN000;  total sectors
	cmp	ax,0			;AN000; double word sector number?
	jnz	Fat_Big_Small		;AN000;  No. Conventional BPB.
	mov	ax, word ptr cs:[si.SECNUM_L] ;AN000; Use double word
	mov	dx, word ptr es:[si.SECNUM_H] ;AN000;

Fat_Big_Small:				 ;AN000; Determine Fat entry size.
;At this moment DX;AX = Total sector number
;	 DEC	 AX			 ; SUBTRACT # RESERVED (ALWAYS 1)
	sub	ax,1			;AN000; Subtrack # reserved (always 1)
	sbb	dx,0			;AN000;
	mov	bx, cs:[si.FATSIZE]	;AN000;  BX = Sectors/Fat
	mov	[di.CSECFAT],bx 	;AN000;  Set in BDS BPB
	shl	bx,1			;AN000; Always 2 FATS
	sub	ax,bx			;AN000; Sub # fat sectors
	sbb	dx,0			;AN000;
	mov	bx, cs:[si.DIRNUM]	;AN000;  # root entries
	mov	[di.cDIR],bx		;AN000;  Set in BDS BPB

	MOV	CL,4
	shr	bx,cl			;AN000;  Div by 16 ents/sector
	sub	ax,bx			;AN000;  sub # dir sectors
	sbb	dx,0			;AN000;
					;AN000; DX;AX now contains the # of data sectors
	xor	cx,cx			;AN000;
	MOV	CL, cs:[si.SECALL]	; SECTORS PER CLUSTER
	MOV	[DI.SECPERCLUS],CL	; SET IN BIOS BPB
;	 XOR	 DX,DX
;	 MOV	 CH,DH
	MNUM	FTESTHARD,CX
	MESSAGE FTESTHARD,<" SECPERCLUS",CR,LF>
;J.K. 3/16/87 P54 Returning back to old logic for compatibility reason.
;So, use the old logic again that once had been commented out!!!!!!!!!!!!
;Old logic to determine FAT Entry Size J.K. 12/3/86
	push	ax			;AN000;
	mov	ax,dx			;AN000;
	xor	dx,dx			;AN000;
	div	cx			;AN000; cx = sectors per cluster
	mov	cs:[Temp_H],ax		;AN000;
	pop	ax			;AN000;
	DIV	CX			;AN000;  [Temp_H];AX NOW CONTAINS THE # CLUSTERS.
	cmp	cs:[Temp_H],0		;AN000;
	ja	TooBig_Ret		;AN000;  Too big cluster number
	CMP	AX,4096-10		; IS THIS 16-BIT FAT?
	JB	CopyMediaID		; NO, small FAT
	OR	FBIGFAT,FBIG		; 16 BIT FAT
;End of Old logic
CopyMediaID:
	call	Mov_Media_IDs		;AN000; Copy Filesys_ID, Volume label,
					;and Volume serial to BDS table, if extended
					;boot record.
	JMP	Massage_bpb		;AN000; Now final check for BPB info. and return.

TooBig_Ret:				;AN000;
	OR	cs:FBIGFAT,FTOOBIG
	JMP	GOODRET 		;AN000; Still drive letter is assigned
					;AN000; But useless. To big for
					;AN000; current PC DOS FAT file system
UNKNOWN:
;	or	[di].FLAGS, UNFORMATTED_MEDIA	;AN005; Set unformatted media flag.
	; preceeding line commented out 10/88 by MRW--  The boot signature
	;   may not be recognizable, but we should TRY and read it anyway.
						;AN006;
						;AN008; For the time being, allow it.
						;AN009; Now implemented again
Unknown3_0:				;AN012;Skip setting UNFORMATTED_MEDIA bit
	MESSAGE FTESTHARD,<"UNKNOWN HARD MEDIA. ASSUMING 3.0.",CR,LF>
	mov	dx, [di.DRVLIM_H]	;AN000;
	mov	ax, [di.DRVLIM_L]	;AN000;
	MOV	SI,OFFSET DISKTABLE2
SCAN:
;	 CMP	 AX,[SI]
;	 JBE	 GOTPARM
;	 ADD	 SI,4 * 2

	cmp	dx, word ptr cs:[si]	;AN000;
	jb	GotParm 		;AN000;
	ja	Scan_Next		;AN000;
	cmp	ax, word ptr cs:[si+2]	;AN000;
	jbe	GotParm 		;AN000;
Scan_Next:				;AN000;
	add	si, 5 * 2		;AN000;
	JMP	SCAN			;AN000;  Covers upto 512 MB media
GOTPARM:
;	 MOV	 CL,BYTE PTR [SI+6]
	mov	cl,byte ptr [si+8]	;AN000;  Fat size for FBIGFAT flag
	OR	FBIGFAT,CL
;	 MOV	 CX,[SI+2]
;	 MOV	 DX,[SI+4]
	mov	cx, word ptr cs:[SI+4]	;AN000;
	mov	dx, word ptr cs:[SI+6]	;AN000;

;	DX = NUMBER OF DIR ENTRIES,
;	CH = NUMBER OF SECTORS PER CLUSTER
;	CL = LOG BASE 2 OF CH

;	NOW CALCULATE SIZE OF FAT TABLE

	MNUM	FTESTHARD,AX
	MESSAGE FTESTHARD,<" SECTORS ">
	MNUM	FTESTHARD,DX
	MESSAGE FTESTHARD,<" DIRECTORY ENTRIES ">
	MNUM	FTESTHARD,CX
	MESSAGE FTESTHARD,<" SECPERCLUS|CLUSSHIFT">

	MOV	WORD PTR CDIR[DI],DX	;SAVE NUMBER OF DIR ENTRIES

;Now, CX = SecPerClus|Clusshift
;     [DI.CDIR] = number of directory entries.

	mov	dx, [di.DRVLIM_H]	;AN000;
	mov	ax, [di.DRVLIM_L]	;AN000;
	MOV	BYTE PTR SECPERCLUS[DI],CH ;SAVE SECTORS PER CLUSTER
	TEST	FBIGFAT,FBIG		;   IF (FBIGFAT)
	JNZ	DOBIG			;	GOTO DOBIG;
	 MESSAGE FTESTHARD,<" SMALL FAT",CR,LF>
;J.K. We don't need to change "small fat" logic since it is gauranteed
;that double word total sector will not use 12 bit fat (unless
;it's sectors/cluster >= 16 which will never be in this case.)
;So in this case we assume DX = 0 !!!.

	XOR	BX,BX
	MOV	BL,CH
	DEC	BX
	ADD	BX,AX			;AN000;  DX=0
	SHR	BX,CL			;   BX = 1+(BPB->MAXSEC+SECPERCLUS-1)/
	INC	BX			;	    SECPERCLUS
	AND	BL,11111110B		;   BX &= ~1; (=NUMBER OF CLUSTERS)
	MOV	SI,BX
	SHR	BX,1
	ADD	BX,SI
	ADD	BX,511			;   BX += 511 + BX/2
	SHR	BH,1			;   BH >>= 1; (=BX/512)
	MOV	BYTE PTR [DI].CSECFAT,BH ;SAVE NUMBER OF FAT SECTORS
	JMP	SHORT Massage_BPB
DOBIG:
;J.K. For BIGFAT we do need to extend this logic to 32 bit sector calculation.
	  MESSAGE FTESTHARD,<" BIG FAT",CR,LF>
	MOV	CL,4			; 16 (2^4) DIRECTORY ENTRIES PER SECTOR
	push	dx			;AN000; Save total sectors (high)
	mov	dx, CDIR[DI]		;AN000;
	SHR	DX,CL			; CSECDIR = CDIR / 16;
	SUB	AX,DX			; DX;AX -= CSECDIR; DX;AX -= CSECRESERVED;
	pop	dx			;AN000;
	SBB	dx,0			;AN000;
;	 DEC	 AX			 ; AX = T - R - D
	SUB	ax,1			;AN000; DX;AX = T - R - D
	SBB	dx,0			;AN000;
	MOV	BL,2
	MOV	BH,SECPERCLUS[DI]	; BX = 256 * SECPERCLUS + 2
;	 XOR	 DX,DX
;J.K. I don't understand why to add BX here!!!
	ADD	AX,BX			; AX = T-R-D+256*SPC+2
	ADC	DX,0
	SUB	AX,1			; AX = T-R-D+256*SPC+1
	SBB	DX,0
;J.K. Assuming DX in the table will never be bigger than BX.
	DIV	BX			; CSECFAT = CEIL((TOTAL-DIR-RES)/
					;		 (256*SECPERCLUS+2));
	MOV	WORD PTR [DI].CSECFAT,AX ; NUMBER OF FAT SECTORS
;J.K. Now, set the default FileSys_ID, Volume label, Serial number
	MOV	BL,FBIGFAT
	MOV	[DI].FATSIZ,BL		; SET SIZE OF FAT ON MEDIA
	call	Clear_IDs		;AN000;

;J.K. At this point, in BPB of BDS table, DRVLIM_H,DRVLIM_L which were
;set according to the partition information. We are going to
;see if (hidden sectors + total sectors) > a word.  If it is true,
;then no change.  Otherwise, DRVLIM_L will be moved to DRVLIM
;and DRVLIM_L will be set to 0.
;We don't do this for the bpb information from the boot record. We
;are not going to change the BPB information from the boot record.
Massage_bpb:				;AN000;
	mov	dx, [di.DRVLIM_H]	;AN000;
	mov	ax, [di.DRVLIM_L]	;AN000;
	cmp	dx,0			;AN000; Double word total sector?
	ja	GOODRET 		;AN000; don't have to change it.
	cmp	[di.HIDSEC_H], 0	;AN000;
	ja	GOODRET 		;AN000; don't have to change it.
	add	ax, [di.HIDSEC_L]	;AN000;
	jc	GOODRET 		;AN000; bigger than a word boundary
	mov	ax, [di.DRVLIM_L]	;AN000;
	mov	[di.DRVLIM], ax 	;AN000;
	mov	[di.DRVLIM_L], 0	;AN000;
GOODRET:
	cmp	[di].DRVLIM_H, 0	;AN014; Big media?
	jbe	Not_BigMedia		;AN014; No.
	push	es			;AN014;
	push	ax			;AN014;
	mov	ax, SYSINITSEG		;AN014;
	mov	es, ax			;AN014;
	mov	es:Big_Media_Flag, 1	;AN014; Set the flag in SYSINITSEG.
	pop	ax			;AN014;
	pop	es			;AN014;
Not_BigMedia:				;AN014;
	MOV	BL,FBIGFAT
	MOV	[DI].FATSIZ,BL		; SET SIZE OF FAT ON MEDIA
	CLC
RET_HARD:
	POP	DS
	POP	BX
	POP	DI
	RET

SETHARD ENDP

Cover_FDISK_Bug 	proc			      ;AN010;
;FDISK of PC DOS 3.3 and below, OS2 1.0 has a bug.  The maximum number of
;sector that can be handled by PC DOS 3.3 ibmbio should be 0FFFFh.
;Instead, sometimes FDISK use 10000h to calculate the maximum number.
;So, we are going to check that if SECNUM + Hidden sector = 10000h
;then subtrack 1 from SECNUM.
	push	ax				      ;AN010;
	push	dx				      ;AN010;
	push	si				      ;AN010;
	cmp	cs:[Ext_Boot_Sig], EXT_BOOT_SIGNATURE ;AN010;
	je	CFB_Retit			      ;AN010;if extended BPB, then >= PC DOS 4.00
	cmp	word ptr cs:[bx+7], "0" shl 8 + "1"   ;AN011; OS2 1.0 ? = IBM 10.0
	jne	CFB_Chk_SECNUM			      ;AN010;
	cmp	byte ptr cs:[bx+10], "0"              ;AN010;
	jne	CFB_Retit			      ;AN010;
CFB_Chk_SECNUM: 				      ;AN010;
	mov	si, offset BPB_In_Sector	      ;AN010;
	cmp	cs:[si.SECNUM], 0		      ;AN010;Just to make sure.
	je	CFB_Retit			      ;AN010;
	mov	ax, cs:[si.SECNUM]		      ;AN010;
	add	ax, cs:[si.HIDDEN_L]		      ;AN010;
	jnc	CFB_Retit			      ;AN010;
	xor	ax, ax				      ;AN010;if carry set and AX=0?
	jnz	CFB_Retit			      ;AN010;
	dec	cs:[si.SECNUM]			      ;AN010;  then decrease SECNUM by 1.
	dec	[di].DRVLIM_L			      ;AN010;
CFB_Retit:					      ;AN010;
	pop	si				      ;AN010;
	pop	dx				      ;AN010;
	pop	ax				      ;AN010;
	ret					      ;AN010;
Cover_FDISK_Bug 	endp			      ;AN010;


; SETDRVPARMS SETS UP THE RECOMMENDED BPB IN EACH BDS IN THE SYSTEM BASED ON
; THE FORM FACTOR. IT IS ASSUMED THAT THE BPBS FOR THE VARIOUS FORM FACTORS
; ARE PRESENT IN THE BPBTABLE. FOR HARD FILES, THE RECOMMENDED BPB IS THE SAME
; AS THE BPB ON THE DRIVE.

; NO ATTEMPT IS MADE TO PRESERVE REGISTERS SINCE WE ARE GOING TO JUMP TO
; SYSINIT STRAIGHT AFTER THIS ROUTINE.

SETDRVPARMS PROC NEAR
	MESSAGE FTESTINIT,<"SETTING DRIVE PARAMETERS",CR,LF>
	XOR	BX,BX
	LES	DI,DWORD PTR CS:[START_BDS] ; GET FIRST BDS IN LIST
NEXT_BDS:
	CMP	DI,-1
	JNZ	DO_SETP
DONE_SETPARMS:
	RET

DO_SETP:
	PUSH	ES
	PUSH	DI			; PRESERVE POINTER TO BDS
	MOV	BL,ES:[DI].FORMFACTOR
	CMP	BL,FFHARDFILE
	JNZ	NOTHARDFF

	xor	dx,dx			;AN000;
	MOV	AX,ES:[DI].DRVLIM
	cmp	ax,0			;AN000;
	jne	GET_cCYL		;AN000;
	mov	dx,es:[di].DRVLIM_H	;AN000; Use Double word sector number
	MOV	AX,ES:[DI].DRVLIM_L	;AN000;
GET_cCYL:
	push	dx			;AN000;
	PUSH	AX
	MOV	AX,WORD PTR ES:[DI].HDLIM
	MUL	WORD PTR ES:[DI].SECLIM ;Assume Sectorsp per cyl. < 64K.
	MOV	CX,AX			; CX HAS # SECTORS PER CYLINDER
	POP	AX			;
	pop	dx			;AN000; Restore drvlim.
	push	ax			;AN000;
	mov	ax,dx			;AN000;
	xor	dx,dx			;AN000;
	div	cx			;AN000;
	mov	cs:[Temp_H],ax		;AN000; AX be 0 here.
	pop	ax			;AN000;
	DIV	CX			; DIV #SEC BY SEC/CYL TO GET # CYL.
	OR	DX,DX
	JZ	NO_CYL_RND		; CAME OUT EVEN
	INC	AX			; ROUND UP
NO_CYL_RND:
	MOV	ES:[DI].CCYLN,AX
	MESSAGE FTESTINIT,<"CCYLN ">
	MNUM	FTESTINIT,AX
	MESSAGE FTESTINIT,<CR,LF>
	PUSH	ES
	POP	DS
	LEA	SI,[DI].BYTEPERSEC	; DS:SI -> BPB FOR HARD FILE
	JMP	SHORT SET_RECBPB

NOTHARDFF:
;J.K. We don't use the extended BPB for a floppy.
	PUSH	CS
	POP	DS
	assume	ds:code
;J.K.6/24/87

;SB34INIT007******************************************************************
;SB	If Fake floppy drive variable is set then we don't have to handle this
;SB	BDS.  We can just go and deal with the next BDS at label Go_To_Next_BDS.

	cmp	cs:FakeFloppyDrv,1
	jz	Go_To_Next_BDS
;SB34INIT007******************************************************************

	CMP	BL,FFOTHER		; SPECIAL CASE "OTHER" TYPE OF MEDIUM
	JNZ	NOT_PROCESS_OTHER
PROCESS_OTHER:
	XOR	DX,DX
	MOV	AX,[DI].CCYLN
	MOV	BX,[DI].RHDLIM
	MUL	BX
	MOV	BX,[DI].RSECLIM
	MUL	BX
	MOV	[DI].RDRVLIM,AX 	; HAVE THE TOTAL NUMBER OF SECTORS
	DEC	AX

;J.K. Old logic was...
;	 MOV	 BX,515
;	 DIV	 BX
;	 OR	 DX,DX
;	 JZ	 NO_ROUND_UP
;	 INC	 AX			 ; ROUND UP NUMBER OF FAT SECTORS

;J.K. New logic to get the sectors/fat area.
					;Fat entry is assumed to be 1.5 bytes!!!
	mov	bx, 3
	mul	bx
	mov	bx,2
	div	bx
	xor	dx, dx
	mov	bx, 512
	div	bx
	inc	ax

NO_ROUND_UP:
	MOV	[DI].RCSECFAT,AX
	JMP	SHORT GO_TO_NEXT_BDS
NOT_PROCESS_OTHER:
	SHL	BX,1			; BX IS WORD INDEX INTO TABLE OF BPBS
	MOV	SI,OFFSET BPBTABLE
	MOV	SI,WORD PTR [SI+BX]	; GET ADDRESS OF BPB
SET_RECBPB:
	LEA	DI,[DI].RBYTEPERSEC	; ES:DI -> RECBPB
	MOV	CX,BPBSIZ
	REP	MOVSB			; MOVE BPBSIZ BYTES
GO_TO_NEXT_BDS:
	POP	DI
	POP	ES			; RESTORE POINTER TO BDS
	MOV	BX,WORD PTR ES:[DI].LINK+2
	MOV	DI,WORD PTR ES:[DI].LINK
	MOV	ES,BX
	JMP	NEXT_BDS

SETDRVPARMS ENDP

;  READ CLUSTER SPECIFIED IN BX
;  CX = SECTORS PER CLUSTER
;  DI = LOAD LOCATION
;
GETCLUS PROC	NEAR
	PUSH	CX
	PUSH	DI
	MOV	DOSCNT,CX	      ;SAVE NUMBER OF SECTORS TO READ
	MOV	AX,BX
	DEC	AX
	DEC	AX
	MUL	CX			;CONVERT TO LOGICAL SECTOR
;J.K. Now DX;AX = matching logical sector number starting from the data sector.
;SB34INIT008*************************************************************
;SB	Add the BIOS start sector to the sector number in DX:AX.  The BIOS
;SB	start sector number is in BIOS$_H:BIOS$_L

	add	ax,cs:BIOS$_L
	adc	dx,cs:BIOS$_H
;SB34INIT008*************************************************************
;J.K. Now DX;AX = first logical sector to read
;	 MOV	 DX,AX			 ;DX = FIRST SECTOR TO READ
GETCL1:
	MNUM	FTESTINIT
	MESSAGE FTESTINIT,<" => ">
;				     ;SI = BX, BX = NEXT ALLOCATION UNIT

;	GET THE FAT ENTRY AT BX

UNPACK:
	PUSH	DS
	push	ax			;AN004;Save First logical sector (Low)
	PUSH	BX
	MOV	SI,FATLOC
	MOV	DS,SI			;DS -> FATLOC segment
	mov	si, bx			;AN004;
	TEST	cs:FBIGFAT,FBIG 	;16 bit fat?
	JNZ	UNPACK16
;	 MOV	 SI,BX
	SHR	SI,1			;12 bit fat. si=si/2
	add	si, bx			;AN004; si = clus + clus/2
	call	Get_Fat_Sector		;AN004; offset of FAT entry in BX
	mov	ax, [bx]		;AN004;Save it into AX
	jne	Even_Odd		;AN004;IF not a splitted FAT, check even-odd.
	mov	al, byte ptr [bx]	;AN004;Splitted FAT.
	mov	byte ptr cs:Temp_Cluster, al	;AN004;
	inc	si				;AN004;
	call	Get_Fat_Sector			;AN004;
	mov	al, byte ptr ds:[0]		 ;AN004;
	mov	byte ptr cs:Temp_Cluster+1, al	;AN004;
	mov	ax, cs:Temp_Cluster	;AN004;
Even_Odd:				;AN004;
	pop	bx			;AN004;Restore old Fat entry value
	push	bx			;AN004;Save it right away.
	shr	bx, 1			;AN004;Was it even or odd?
	jnc	HAVCLUS 		;It was even.
	SHR	ax,1			;Odd. Massage FAT value and keep
	SHR	ax,1			;the highest 12 bits.
	SHR	ax,1
	SHR	ax,1
HAVCLUS:
	mov	bx, ax			;AN004; Now BX = New FAT entry.
	AND	BX,0FFFH		;AN004; keep low 12 bits.
	JMP	SHORT UNPACKX
UNPACK16:				;16 bit fat.
	shl	si, 1			;Get the offset value.
	call	Get_Fat_Sector		;AN004;
	mov	bx, [bx]		;AN004; Now BX = New FAT entry.
UNPACKX:
	POP	SI			;Retore Old BX value into SI
	pop	ax			;AN004;Restore logical sector (low)
	POP	DS

	MNUM	FTESTINIT
	MESSAGE FTESTINIT,<"    ">
	SUB	SI,BX
	CMP	SI,-1			;ONE APART?
	JNZ	GETCL2
	ADD	DOSCNT,CX
	JMP	GETCL1

GETCL2:
	PUSH	BX
	push	dx			;AN000; Sector to read (High)
	push	ax			;AN000; Sector to read (low)
	MOV	AX,DRVFAT	      ;GET DRIVE AND FAT SPEC
	MOV	CX,DOSCNT
	pop	dx			;AN000; Sector to read for DISKRD (Low)
	pop	cs:[Start_Sec_H]	;AN000; Sector to read for DISKRD (High)
	CALL	DISKRD			;READ THE CLUSTERS

	POP	BX
	POP	DI
	MOV	AX,DOSCNT	      ;GET NUMBER OF SECTORS READ
	XCHG	AH,AL			;MULTIPLY BY 256
	SHL	AX,1			;TIMES 2 EQUAL 512
	ADD	DI,AX			;UPDATE LOAD LOCATION
	POP	CX			;RESTORE SECTORS/CLUSTER
	RET

GETCLUS ENDP				;   RETURN;

Get_FAT_Sector	proc	near		;AN004;
;Function: FInd and read the corresponding FAT sector into DS:0
;In). SI - offset value (starting from FAT entry 0) of FAT entry to find.
;     DS - FATLOC segment
;     cs:DRVFAT - Logical drive number, FAT id
;     cs:Md_SectorSize
;     cs:Last_Fat_SecNum - Last FAT sector number read in.
;Out). Corresponding FAT sector read in.
;      BX = offset value from FATLOG segment.
;      Other registera saved.
;      Zero flag set if the FAT entry is splitted, i.e., wehn 12 bit FAT entry
;      starts at the last byte of the FAT sector. In this case, the caller
;      should save this byte, and read the next FAT sector to get the rest
;      of the FAT entry value. (This will only happen with the 12 bit fat.)

	push	ax				;AN004;
	push	cx				;AN004;
	push	dx				;AN004;
	push	di				;AN004;
	push	si				;AN004;
	push	es				;AN004;
	push	ds				;AN004;
	xor	dx, dx				;AN004;
	mov	ax, si				;AN004;
	mov	cx, cs:Md_SectorSize		;AN004; =512 bytes
	div	cx				;AN004; AX=sector number, dx = offset
	inc	ax				;AN004; Make AX to relative logical sector number
	cmp	ax, cs:Last_Fat_SecNum		;AN004;  by adding Reserved sector number.
	je	GFS_Split_Chk			;AN004; Don't need to read it again.
	mov	cs:Last_Fat_SecNum, ax		;AN004; Update Last_Fat_SecNum
	push	dx				;AN004; save offset value.
	mov	cs:[Start_Sec_H],0		;AN004; Prepare to read the FAT sector
	mov	dx, ax				;AN004; Start_Sec_H is always 0 for FAT sector.
	mov	cx, 1				;AN004; 1 sector to read
	mov	ax, cs:DrvFAT			;AN004;
	push	ds				;AN004;
	pop	es				;AN004;
	xor	di, di				;AN004; es:di -> FatLoc segment:0
	call	DiskRD				;AN004; cross your finger.
	pop	dx				;AN004; restore offset value.
	mov	cx, cs:Md_SectorSize		;AN004;
GFS_Split_Chk:					;AN004;
	dec	cx				;AN004;if offset points to the
	cmp	dx, cx				;AN004;last byte of this sector, then splitted entry.
	mov	bx, dx				;AN004;Set BX to DX
	pop	ds				;AN004;
	pop	es				;AN004;
	pop	si				;AN004;
	pop	di				;AN004;
	pop	dx				;AN004;
	pop	cx				;AN004;
	pop	ax				;AN004;
	ret					;AN004;
Get_FAT_Sector	endp				;AN004;

;
; SI POINTS TO DEVICE HEADER
; J.K. 4/22/86 - print_init, aux_init is modified to eliminate the self-modifying
; J.K. code.

PRINT_INIT:
	call	Get_device_number
;SB33028*****************************************************************
	mov	ah,1			;initalize printer port        ;SB;3.30
	int	17h			;call ROM-Bios routine	       ;SB;3.30
;SB33028*****************************************************************
	ret

AUX_INIT:
	call	Get_device_number
;SB33028*****************************************************************
	mov	al,RSINIT		;2400,N,1,8 (MSEQU.INC)       ;SB ;3.30*
	mov	ah,0			;initalize AUX port	      ;SB ;3.30*
	int	14h			;call ROM-Bios routine	      ;SB ;3.30*
;SB33028*****************************************************************
	ret

GET_DEVICE_NUMBER:
;SI -> device header
	MOV	AL,CS:[SI+13]		;GET DEVICE NUMBER FROM THE NAME
	SUB	AL,"1"
	CBW
	MOV	DX,AX
	RET

;
;   PURGE_96TPI NOP'S CALLS TO 96TPI SUPPORT.
;
PURGE_96TPI PROC NEAR			;MJB001
	PUSH	DS
	PUSH	ES

	PUSH	CS			;MJB001
	POP	ES			;MJB001
	PUSH	CS			;MJB001
	POP	DS			;MJB001
	ASSUME	DS:CODE,ES:CODE

	MOV	SI,OFFSET PATCHTABLE
PATCHLOOP:
	LODSW
	MOV	CX,AX
	JCXZ	PATCHDONE
	LODSW
	MOV	DI,AX
	MOV	AL,90H
	REP	STOSB
	JMP	PATCHLOOP

PATCHDONE:
;**************NOT NEEDED ANY MORE***********************
;	MOV	DI,OFFSET FORMAT_PATCH	     ; ARR 2.42
;	MOV	AL,CS:INST_FAR_RET
;	STOSB
;********************************************************
	MOV	DI,OFFSET TABLE_PATCH	; ARR 2.42
	MOV	AX,OFFSET EXIT
	STOSW
	STOSW

	POP	ES
	POP	DS
	RET				;MJB001
PURGE_96TPI ENDP

;Mini disk initialization routine. Called right after DoHard - J.K. 4/7/86
; DoMini **********************************************************************
; **CS=DS=ES=code
; **DoMini will search for every extended partition in the system, and
;   initialize it.
; **BDSM stands for BDS table for Mini disk and located right after the label
;   End96Tpi.  End_Of_BDSM will have the offset value of the ending
;   address of BDSM table.
; **BDSM is the same as usual BDS structure except that TIM_LO, TIM_HI entries
;   are overlapped and used to identify mini disk and the number of Hidden_trks.
;   Right now, they are called as IsMini, Hidden_Trks respectively.
; **DoMini will use the same routine in SETHARD routine after label SET1 to
;   save coding.
; **DRVMAX determined in DoHard routine will be used for the next
;   available logical mini disk drive number.
;
; Input: DRVMAX, DSKDRVS
;
; Output: MiniDisk installed. BDSM table established and installed to BDS.
;	  num_mini_dsk -  the number of mini disks installed in the system.
;	  End_Of_BDSM - ending offset address of BDSM.
;
;
; Called modules:
;		  GetBoot, WRMSG, int 13h (AH=8, Rom)
;		  FIND_MINI_PARTITION (new), Install_BDSM (new),
;		  SetMini (new, it will use SET1 routine)
; Variables used: End_Of_BDSM, numh, mininum, num_mini_dsk,
;		  Rom_Minidsk_num, Mini_HDLIM, Mini_SECLIM
;		  BDSMs, BDSM_type (struc), Start_BDS
;******************************************************************************
;

DoMini:
	push	cs
	pop	es
	push	cs
	pop	ds
	assume	ds:code,es:code
	Message fTestHard,<"Start of DoMini...",cr,lf>

	push	ax			;Do I need to do this?

	mov	di, offset BDSMs	;from now on, DI points to BDSM
;SB33028********************************************************************
	mov	dl, 80h 		;look at first hard drive     ;SB ;3.30*
	mov	ah, 8h			;get drive parameters	      ;SB ;3.30*
	int	13h			;call ROM-Bios		      ;SB ;3.30*
;SB33028********************************************************************
	cmp	dl, 0
	jz	DoMiniRet		;no hard file? Then exit.
	mov	numh, dl		;save the number of hard files.
	xor	ax,ax
	mov	al, drvmax
	mov	mininum, al		;this will be the logical drive letter
					;for mini disk to start with.

	shl	ax, 1			;ax=number of devices. make it to word boundary
	push	bx
	mov	bx, offset DSKDRVS
	add	bx, ax
	mov	Mini_BPB_ptr, BX	;Mini_BPB_ptr points to the first available
					;spot in DskDrvs for Mini disk which
					;points to BPB area of BDSM.
	pop	bx

	mov	Rom_Minidsk_num, 80h
DoMiniBegin:
	inc	dh			;Get # of heads (convert it to 1 based)
	xor	ax, ax
	mov	al, dh
	mov	Mini_HDLIM, ax		;save it.
	xor	ax, ax
	and	cl, 3fh 		;Get # of sectors/track
	mov	al, cl
	mov	Mini_SECLIM, ax 	;and save it.

	mov	dl, Rom_Minidsk_num	;drive number <DL>
	call	GETBOOT 		;read master boot record into 7c0:BootBias
	assume	es:nothing
	jc	DoMiniNext
	call	FIND_MINI_PARTITION
DoMiniNext:
	dec	numh
	jz	DoMiniRet
	inc	Rom_MiniDsk_Num 	;Next hard file
;SB33028********************************************************************
	mov	dl, Rom_MiniDsk_Num	;look at next hard drive      ;SB ;3.30*
	mov	ah, 8h			;get drive parameters	      ;SB ;3.30*
	int	13h			;call ROM-Bios		      ;SB ;3.30*
;SB33028********************************************************************
	jmp	DoMiniBegin

DoMiniRet:
	pop	ax
	ret


;Find_Mini_Partition tries to find every Extended partition on a disk.
;At entry:	DI -> BDSM entry
;		ES:BX -> 07c0:BootBias - Master Boot Record
;		Rom_MiniDsk_Num  - ROM drive number
;		MiniNum - Logical drive number
;		Mini_HDLIM, Mini_SECLIM
;
;Called routine: SETMINI which uses SET1 (in SETHARD routine)
;Variables & equates used from original BIOS - flags, fNon_Removable, fBigfat
;
;
FIND_MINI_PARTITION:

	add	bx, 1C2h		;BX -> system id.

FmpNext:
	cmp	byte ptr ES:[BX], 5	; 5 = extended partition ID.
	jz	FmpGot
	add	bx, 16			; for next entry
	cmp	bx, 202h+BootBias
	jnz	FmpNext
	jmp	FmpRet			;not found extended partition

FmpGot: 				;found my partition.
	Message ftestHard,<"Found my partition...",cr,lf>
	xor	ax,ax
	or	al, fNon_Removable
	or	word ptr [DI].Flags, ax
	mov	byte ptr [DI].FormFactor, ffHardFile
	mov	fBigFat, 0		;assume 12 bit Fat.
	mov	ax, Mini_HDLIM
	mov	[DI].HDLIM, ax
	mov	ax, Mini_SECLIM
	mov	[DI].SECLIM, ax
	mov	al, Rom_MiniDsk_Num
	mov	[DI].DRIVENUM, al	;set physical number
	mov	al, Mininum
	mov	[DI].DRIVELET, al	;set logical number

	cmp	word ptr es:[bx+10], 0	;AN000;
	ja	FmpGot_Cont		;AN000;
	cmp	word ptr ES:[BX+8], 64	;**With current BPB, only lower word
					; is meaningful.
	jb	FmpRet			;should be bigger than 64 sectors at least
FmpGot_Cont:				;AN000;
	sub	bx, 4			;let BX point to the start of the entry
	mov	dh, byte ptr ES:[BX+2]
	and	dh, 11000000b		;get higher bits of cyl
	rol	dh, 1
	rol	dh, 1
	mov	dl, byte ptr ES:[BX+3]	;cyl byte
	mov	[DI].HIDDEN_TRKS, dx	;set hidden trks
;** Now, read the volume boot record into BootBias.
;SB33029******************************************************************
	mov	cx,ES:[BX+2]		;cylinder,cylinder/sector     ;SB ;3.30*
	mov	dh,ES:[BX+1]		;head			      ;SB ;3.30*
	mov	dl,Rom_MiniDsk_Num	;drive			      ;SB ;3.30*
	mov	bx,BOOTBIAS		;buffer offset		      ;SB ;3.30*
	mov	ax,0201h		;read,1 sector		      ;SB ;3.30*
	int	13h			;call ROM-Bios routine	      ;SB ;3.30*
;SB33029******************************************************************
	jc	FmpRet			;cannot continue.
	mov	bx, 1c2h+BOOTBIAS

	push	es			;;DCL/KWC 8/2/87 addressability to
					;; next minidisk

	call	SetMini 		;install a mini disk. BX value saved.

	pop	es			;;DCL/KWC 8/2/87

	jc	FmpnextChain

	call	Install_BDSM		;install the BDSM into the BDS table
;	 call	 Show_Installed_Mini	 ;show the installed message. 3/35/86 - Don't show messages. J.K.
	inc	mininum 		;increase the logical drive number for next
	inc	num_mini_dsk		;increase the number of mini disk installed.

	push	bx			;now, set the DskDrvs pointer to BPB info.
	mov	bx, Mini_BPB_ptr
	lea	si, [di].BYTEPERSEC	;points to BPB of BDSM
	mov	[bx], si
	inc	Mini_BPB_ptr		;advance to the next address
	inc	Mini_BPB_ptr
	pop	bx

	add	DI, type BDSM_type	;adjust to the next BDSM table entry.
	mov	End_OF_BDSM, DI 	;set the ending address of BDSM table to this.
;	 Message fTestHard,<"Mini disk installed.",cr,lf>
FmpnextChain: jmp FmpNext		;let's find out if we have any chained partition
FmpRet:
	ret

SetMini:
	push	di
	push	bx
	push	ds
	jmp	SET1			;will be returned to Find mini partition routine.
					;Some logic has been added to SET1 to
					;deal with Mini disks.

;
;Install BDSM installs a BDSM (pointed by DS:DI) into the end of the current
;linked list of BDS.
;Also, set the current BDSM pointer segment to DS.
;At entry: DS:DI -> BDSM
;
Install_BDSM:
assume	ds:code,es:nothing
	push	ax
	push	si
	push	es

	les	si, dword ptr cs:Start_BDS	;start of the beginning of list
I_BDSM_Next:
	cmp	word ptr es:[si], -1		;end of the list?
	jz	I_BDSM_New
	mov	si, word ptr es:[si].LINK
	mov	ax, word ptr es:[si].LINK+2	;next pointer
	mov	es, ax
	jmp	short I_BDSM_Next
I_BDSM_New:
	mov	ax, ds
	mov	word ptr ds:[di].LINK+2, ax	;BDSM segment had not been initialized.
	mov	word ptr es:[si].LINK+2, ax
	mov	word ptr es:[si].LINK, di
	mov	word ptr ds:[di].LINK, -1	;make sure it is a null ptr.

I_BDSM_ret:
	pop	es
	pop	si
	pop	ax
	ret

;***The following code is not needed any more.	Don't show any
;***messages to be compatible with the behavior of IBMBIO.COM.
;;Show the message "Mini disk installed ..."
;;This routine uses WRMSG procedure which will call OUTCHR.
;Show_Installed_Mini:
;	 push	 ax
;	 push	 bx
;	 push	 ds
;
;	 mov	 al, Mininum		 ;logical drive number
;	 add	 al, Drv_Letter_Base	 ;='A'
;	 mov	 Mini_Drv_Let, al
;	 mov	 si, offset Installed_Mini
;	 call	 WRMSG
;
;	 pop	 ds
;	 pop	 bx
;	 pop	 ax
;	 ret
;**End of mini disk initialization**	;J.K. 4/7/86


CMOS_Clock_Read proc	near

	assume	ds:code,es:code
; IN ORDER TO DETERMINE IF THERE IS A CLOCK PRESENT IN THE SYSTEM, THE FOLLOWING
; NEEDS TO BE DONE.
	PUSH	AX
	PUSH	CX
	PUSH	DX
	PUSH	BP

	XOR	BP,BP
LOOP_CLOCK:
	XOR	CX,CX
	XOR	DX,DX
;SB33030********************************************************************
	MOV	AH,2			;READ REAL TIME CLOCK	      ;SB ;3.30
	INT	1Ah			;CALL ROM-BIOS ROUTINE	      ;SB ;3.30
;SB33030********************************************************************
	CMP	CX,0
	JNZ	CLOCK_PRESENT

	CMP	DX,0
	JNZ	CLOCK_PRESENT

	CMP	BP,1			; READ AGAIN AFTER A SLIGHT DELAY, IN CASE CLOCK
	JZ	NO_READDATE		; WAS AT ZERO SETTING.

	INC	BP			; ONLY PERFORM DELAY ONCE.
	MOV	CX,4000H
DELAY:
	LOOP	DELAY
	JMP	LOOP_CLOCK

CLOCK_PRESENT:
	mov	cs:HaveCMOSClock, 1	;J.K. Set the flag for cmos clock

	call	CMOSCK			;J.K. Reset CMOS clock rate that may be
					;possibly destroyed by CP DOS and POST routine did not
					;restore that.

	PUSH	SI
	MESSAGE FTESTINIT,<"CLOCK DEVICE",CR,LF>
	CALL	READ_REAL_DATE		;MJB002 READ REAL-TIME CLOCK FOR DATE

	CLI				;MJB002
	MOV	DAYCNT,SI	      ;MJB002 SET SYSTEM DATE
	STI				;MJB002
	POP	SI			;MJB002
NO_READDATE:
	POP	BP
	POP	DX
	POP	CX
	POP	AX
	RET

CMOS_Clock_Read endp
;
;J.K. 10/28/86
;J.K. THE FOLLOWING CODE IS WRITTEN BY JACK GULLEY IN ENGINEERING GROUP.
;J.K. CP DOS IS CHANGING CMOS CLOCK RATE FOR ITS OWN PURPOSES AND IF THE
;J.K. USE COLD BOOT THE SYSTEM TO USE PC DOS WHILE RUNNING CP DOS, THE CMOS
;J.K. CLOCK RATE ARE STILL SLOW WHICH SLOW DOWN DISK OPERATIONS OF PC DOS
;J.K. WHICH USES CMOS CLOCK.  PC DOS IS PUT THIS CODE IN MSINIT TO FIX THIS
;J.K. PROBLEM AT THE REQUEST OF CP DOS.
;J.K. THE PROGRAM IS MODIFIED TO BE RUN ON MSINIT. Equates are defined in CMOSEQU.INC.
;J.K. This program will be called by CMOS_Clock_Read procedure.
;
;  The following code CMOSCK is used to insure that the CMOS has not
;	had its rate controls left in an invalid state on older AT's.
;
;	It checks for an AT model byte "FC" with a submodel type of
;	00, 01, 02, 03 or 06 and resets the periodic interrupt rate
;	bits incase POST has not done it.  This initilization routine
;	is only needed once when DOS loads.  It should be ran as soon
;	as possible to prevent slow diskette access.
;
;	This code exposes one to DOS clearing CMOS setup done by a
;	resident program that hides and re-boots the system.
;
CMOSCK	PROC	NEAR			;	CHECK AND RESET RTC RATE BITS
	assume	ds:nothing,es:nothing

;Model byte and Submodel byte were already determined in MSINIT.
	push	ax
	cmp	cs:Model_byte, 0FCh	;check for PC-AT model byte
					 ;	 EXIT IF NOT "FC" FOR A PC-AT
	JNE	CMOSCK9 		; Exit if not an AT model

	CMP	cs:Secondary_Model_Byte,06H  ; Is it 06 for the industral AT
	JE	CMOSCK4 		; Go reset CMOS periodic rate if 06
	CMP	cs:Secondary_Model_Byte,04H  ; Is it 00, 01, 02, or 03
	JNB	CMOSCK9 		; EXIT if problem fixed by POST
					;J.K. Also,Secondary_model_byte = 0 when AH=0c0h, int 15h failed.
CMOSCK4:				;	RESET THE CMOS PERIODIC RATE
					;  Model=FC submodel=00,01,02,03 or 06
;SB33IN2***********************************************************************

	mov	al,CMOS_REG_A or NMI	;NMI disabled on return
	mov	ah,00100110b		;Set divider & rate selection
	call	CMOS_WRITE

;SB33IN2***********************************************************************

					;	CLEAR SET,PIE,AIE,UIE AND SQWE
	mov	al,CMOS_REG_B or NMI	;NMI disabled on return
	call	CMOS_READ
	and	al,00000111b		;clear SET,PIE,AIE,UIE,SQWE
	mov	ah,al
	mov	al,CMOS_REG_B		;NMI enabled on return
	call	CMOS_WRITE

;SB33IN3***********************************************************************

CMOSCK9:				;	EXIT ROUTINE
	pop	ax
	RET				; RETurn to caller
					;  Flags modifyied
CMOSCK	ENDP
PAGE
;--- CMOS_READ -----------------------------------------------------------------
;		READ BYTE FROM CMOS SYSTEM CLOCK CONFIGURATION TABLE	       :
;									       :
; INPUT: (AL)=	CMOS TABLE ADDRESS TO BE READ				       :
;		BIT    7 = 0 FOR NMI ENABLED AND 1 FOR NMI DISABLED ON EXIT    :
;		BITS 6-0 = ADDRESS OF TABLE LOCATION TO READ		       :
;									       :
; OUTPUT: (AL)	VALUE AT LOCATION (AL) MOVED INTO (AL).  IF BIT 7 OF (AL) WAS  :
;		ON THEN NMI LEFT DISABLED.  DURING THE CMOS READ BOTH NMI AND  :
;		NORMAL INTERRUPTS ARE DISABLED TO PROTECT CMOS DATA INTEGRITY. :
;		THE CMOS ADDRESS REGISTER IS POINTED TO A DEFAULT VALUE AND    :
;		THE INTERRUPT FLAG RESTORED TO THE ENTRY STATE ON RETURN.      :
;		ONLY THE (AL) REGISTER AND THE NMI STATE IS CHANGED.	       :
;-------------------------------------------------------------------------------

CMOS_READ	PROC	NEAR		;	READ LOCATION (AL) INTO (AL)
	assume	es:nothing,ds:nothing
	PUSHF				; SAVE INTERRUPT ENABLE STATUS AND FLAGS
;SB33IN4********************************************************************

	cli
	push	bx
	push	ax			;save user NMI state
	or	al,NMI			;disable NMI for us
	out	CMOS_PORT,al
	nop				;undocumented delay needed
	in	al,CMOS_DATA		;get data value

	 ;set NMI state to user specified 
	mov	bx,ax			;save data value
	pop	ax			;get user NMI
	and	al,NMI
	or	al,CMOS_SHUT_DOWN
	out	CMOS_PORT,al
	nop
	in	al,CMOS_DATA

	mov	ax,bx			;data value
	pop	bx

;SB33IN4********************************************************************
	PUSH	CS			; *PLACE CODE SEGMENT IN STACK AND
	CALL	CMOS_POPF		; *HANDLE POPF FOR B- LEVEL 80286
	RET				; RETURN WITH FLAGS RESTORED

CMOS_READ	ENDP

CMOS_POPF	PROC	NEAR		;	POPF FOR LEVEL B- PARTS
	IRET				; RETURN FAR AND RESTORE FLAGS

CMOS_POPF	ENDP

;--- CMOS_WRITE ----------------------------------------------------------------
;		WRITE BYTE TO CMOS SYSTEM CLOCK CONFIGURATION TABLE	       :
;									       :
; INPUT: (AL)=	CMOS TABLE ADDRESS TO BE WRITTEN TO			       :
;		BIT    7 = 0 FOR NMI ENABLED AND 1 FOR NMI DISABLED ON EXIT    :
;		BITS 6-0 = ADDRESS OF TABLE LOCATION TO WRITE		       :
;	 (AH)=	NEW VALUE TO BE PLACED IN THE ADDRESSED TABLE LOCATION	       :
;									       :
; OUTPUT:	VALUE IN (AH) PLACED IN LOCATION (AL) WITH NMI LEFT DISABLED   :
;		IF BIT 7 OF (AL) IS ON.  DURING THE CMOS UPDATE BOTH NMI AND   :
;		NORMAL INTERRUPTS ARE DISABLED TO PROTECT CMOS DATA INTEGRITY. :
;		THE CMOS ADDRESS REGISTER IS POINTED TO A DEFAULT VALUE AND    :
;		THE INTERRUPT FLAG RESTORED TO THE ENTRY STATE ON RETURN.      :
;		ONLY THE CMOS LOCATION AND THE NMI STATE IS CHANGED.	       :
;-------------------------------------------------------------------------------

CMOS_WRITE	PROC	NEAR		;	WRITE (AH) TO LOCATION (AL)
	assume	es:nothing,ds:nothing
	PUSHF				; SAVE INTERRUPT ENABLE STATUS AND FLAGS
	PUSH	AX			; SAVE WORK REGISTER VALUES

	cli
	push	ax			;save user NMI state
	or	al,NMI			;disable NMI for us
	out	CMOS_PORT,al
	nop
	mov	al,ah
	out	CMOS_DATA,al		;write data

	 ;set NMI state to user specified 
	pop	ax 			;get user NMI
	and	al,NMI
	or	al,CMOS_SHUT_DOWN
	out	CMOS_PORT,al
	nop
	in	al,CMOS_DATA

;SB33IN5********************************************************************
	POP	AX			; RESTORE WORK REGISTERS
	PUSH	CS			; *PLACE CODE SEGMENT IN STACK AND
	CALL	CMOS_POPF		; *HANDLE POPF FOR B- LEVEL 80286
	RET

CMOS_WRITE	ENDP
;


END$:
CODE	ENDS
	END
