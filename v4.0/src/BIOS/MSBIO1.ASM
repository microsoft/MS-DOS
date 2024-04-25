
	PAGE	,132			;
	TITLE	MSBIO1.asm - BIOS
;==============================================================================
;REVISION HISTORY:
;AN000 - New for DOS Version 4.00 - J.K.
;AC000 - Changed for DOS Version 4.00 - J.K.
;AN00x - PTM number for DOS Version 4.00 - J.K.
;==============================================================================
COMMENT *
THE LINK STEP IS PERFORMED BY USING THE FOLLOWING "NEW.ARF" FILE:
msbio1+
msSTACK+
MsCON+
msAUX+
msLPT+
msCLOCK+
msdISK+
msBIO2+
C:\BIO2\OLDOBJ\disk+
C:\BIO2\OLDOBJ\msinit+
C:\BIO2\OLDOBJ\sysinit1+
C:\BIO2\OLDOBJ\sysinit2+
C:\BIO2\OLDOBJ\sysimes,msbio,/M;

THE FOLLOWING IS A BATCH FILE THAT CAN BE USED TO CREATE THE IBMBIO.COM
WHERE "LOCSCR" IS A FILE THAT JUST HAS THE NUMBER, 70:

link @NEW.ARF
exe2bin ibmbio ibmbio.com <C:\BIO2\Locscr
del ibmbio.exe
(END OF COMMENT)*

;***For testing purposes, set the TEST flag to 1. Otherwise reset it.

iTEST=0

PATHGEN =	1

.SALL
	%OUT	...MSBIO1.ASM

; THIS IS A DOSMAC MACRO WHICH IS USED IN DEVSYM WHICH IS INCLUDED LATER
BREAK	MACRO	SUBTITLE
	SUBTTL	SUBTITLE
	PAGE
	ENDM

POPFF	MACRO
	JMP	$+3
	IRET
	PUSH	CS
	CALL	$-2
	ENDM

	INCLUDE MSGROUP.INC	;DEFINE CODE SEGMENT

SYSINITSEG SEGMENT PUBLIC 'SYSTEM_INIT'
SYSINITSEG ENDS


	INCLUDE JUMPMAC.INC
PATHSTART MACRO INDEX,ABBR
	IFDEF	PATHGEN
	    PUBLIC  ABBR&INDEX&S,ABBR&INDEX&E
	    ABBR&INDEX&S LABEL	 BYTE
	ENDIF
	ENDM

PATHEND MACRO	INDEX,ABBR
	IFDEF	PATHGEN
	    ABBR&INDEX&E LABEL	 BYTE
	ENDIF
	ENDM

	INCLUDE PUSHPOP.INC
	INCLUDE DEVSYM.INC		;MJB001

;   REV 2.1	5/1/83 ARR ADDED TIMER INT HANDLER AND CHANGED ORDER OF AUX
;		    PRN INIT FOR HAL0
;
;   REV 2.15	7/13/83 ARR BECAUSE IBM IS FUNDAMENTALY BRAIN DAMAGED, AND
;		    BASCOM IS RUDE ABOUT THE 1CH TIMER INTERRUPT, THE TIMER
;		    HANDLER HAS TO GO BACK OUT!!!!!  IBM SEEMS UNWILLING TO
;		    BELIEVE THE PROBLEM IS WITH THE BASCOM RUNTIME, NOT THE
;		    DOS.  THEY HAVE EVEN BEEN GIVEN A PATCH FOR BASCOM!!!!!
;		    THE CORRECT CODE IS COMMENTED OUT AND HAS AN ARR 2.15
;		    ANNOTATION.  THIS MEANS THE BIOS WILL GO BACK TO THE
;		    MULTIPLE ROLL OVER BUG.
;   REV 2.20	8/5/83 ARR IBM MAKES HARDWARE CHANGE.  NOW WANTS TO USE HALF
;		    HIGHT DRIVES FOR HAL0, AND BACK FIT FOR PC/PC XT.  PROBLEM
;		    WITH HEAD SETTLE TIME.  PREVIOUS DRIVES GOT BY ON A 0
;		    SETTLE TIME, 1/2 HIGHT DRIVES NEED 15 HEAD SETTLE WHEN
;		    DOING WRITES (0 OK ON READ) IF THE HEAD IS BEING STEPPED.
;		    THIS REQUIRES A LAST TRACK VALUE TO BE KEPT SO THAT BIOS
;		    KNOWS WHEN HEAD IS BEING MOVED.  TO HELP OUT STUPID
;		    PROGRAMS THAT ISSUE INT 13H DIRECTLY, THE HEAD SETTLE WILL
;		    NORMALLY BE SET TO 15.  IT WILL BE CHANGED TO 0 ON READS,
;		    OR ON WRITES WHICH DO NOT REQUIRE HEAD STEP.
;   REV 2.21	8/11/83 MZ IBM WANTS WRITE WITH VERIFY TO USE HEAD SETTLE 0.
;		    USE SAME TRICK AS ABOVE.
;   REV 2.25	6/20/83 MJB001 ADDED SUPPORT FOR 96TPI AND SALMON
;   REV 2.30	6/27/83 MJB002 ADDED REAL-TIME CLOCK
;   REV 2.40	7/8/83 MJB003 ADDED VOLUME-ID CHECKING AND INT 2F MACRO
;		    DEFINITIONS PUSH* AND POP*
;   REV 2.41	7/12/83 ARR MORE 2.X ENHANCEMENTS.  OPEN/CLOSE MEDIA CHANGE
;   REV 2.42	11/3/83 ARR MORE 2.X ENHANCEMENTS.  DISK OPEN/CLOSE, FORMAT
;		    CODE AND OTHER MISC HOOKED OUT TO SHRINK BIOS.  CODE FOR
;		    DISK OPEN/CLOSE, FORMAT INCLUDED ONLY WITH 96TPI DISKS.
;   REV   2.43	12/6/83 MZ EXAMINE BOOT SECTORS ON HARD DISKS FOR 16-BIT FAT
;		    CHECK.  EXAMINE LARGE FAT BIT IN BPB FOR WALK OF MEDIA FOR
;		    DOS
;   REV   2.44	12/9/83 ARR CHANGE TO ERROR REPORTING ON INT 17H
;   REV   2.45	12/22/83 MZ MAKE HEAD SETTLE CHANGE ONLY WHEN DISK PARM IS 0.

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;
;	IBM ADDRESSES FOR I/O
;
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	INCLUDE MSDSKPR.INC

LF	=	10			;LINE FEED
CR	=	13			;CARRIAGE RETURN
BACKSP	=	8			;BACKSPACE
BRKADR	=	1BH * 4 		;006C  1BH BREAK VECTOR ADDRESS
TIMADR	=	1CH * 4 		;0070  1CH TIMER INTERRUPT
DSKADR	=	1EH * 4 		;ADDRESS OF PTR TO DISK PARAMETERS
SEC9	=	522H			;ADDRESS OF DISK PARAMETERS
HEADSETTLE =	SEC9+9			; ARR 2.20 ADDRESS OF HEAD SETTLE TIME
NORMSETTLE =	15			; ARR 2.20 NORMAL HEAD SETTLE
SPEEDSETTLE =	0			; ARR 2.20 SPEED UP SETTLE TIME
INITSPOT =	534H			; ARR IBM WANTS 4 ZEROS HERE
AKPORT	=	20H
EOI	=	20H

	ASSUME	CS:CODE,DS:NOTHING,ES:NOTHING

	EXTRN	MEDIA$CHK:NEAR
	EXTRN	GET$BPB:NEAR
	EXTRN	DSK$INIT:NEAR
	EXTRN	DSK$READ:NEAR
	EXTRN	DSK$WRIT:NEAR
	EXTRN	DSK$WRITV:NEAR
	EXTRN	DSK$OPEN:NEAR
	EXTRN	DSK$CLOSE:NEAR
	EXTRN	DSK$REM:NEAR
	EXTRN	GENERIC$IOCTL:NEAR
	EXTRN	IOCTL$GETOWN:NEAR
	EXTRN	IOCTL$SETOWN:NEAR
	EXTRN	CON$READ:NEAR
	EXTRN	CON$RDND:NEAR
	EXTRN	CON$FLSH:NEAR
	EXTRN	CON$WRIT:NEAR
;	EXTRN	CON$GENIOCTL:NEAR		;J.K. 4/29/86
	EXTRN	AUX$READ:NEAR
	EXTRN	AUX$WRIT:NEAR
	EXTRN	AUX$FLSH:NEAR
	EXTRN	AUX$RDND:NEAR
	EXTRN	AUX$WRST:NEAR
	EXTRN	TIM$READ:NEAR
	EXTRN	TIM$WRIT:NEAR
	EXTRN	PRN$WRIT:NEAR
	EXTRN	PRN$STAT:NEAR
	EXTRN	PRN$TILBUSY:NEAR
	EXTRN	PRN$GENIOCTL:NEAR
	EXTRN	WRMSG:NEAR

;DATA AREAS
	extrn	Start_Sec_H:word	;AN000; Starting sector high word for
					;disk I/O request. IBMDISK.ASM

	INCLUDE MSBDATA.INC

	IF	iTEST
	    PUBLIC  MSGNUM
MSGNUM:
	    PUSHF
	    TEST    FTESTBITS,AX
	    JZ	    MRET
	    PUSH    SI
	    PUSH    BX
	    PUSH    CX
	    PUSH    ES
	    PUSH    DI
	    MOV     DI,OFFSET NUMBUF
	    PUSH    CS
	    POP     ES
	    MOV     CX,4
NUMLOOP:
	    PUSH    CX
	    MOV     CL,4
	    ROL     BX,CL
	    POP     CX
	    PUSH    BX
	    AND     BX,0FH
	    MOV     AL,DIGITS[BX]
	    STOSB
	    POP     BX
	    LOOP    NUMLOOP
	    POP     DI
	    POP     ES
	    POP     CX
	    POP     BX
	    MOV     SI,OFFSET NUMBUF
	    CALL    MSGOUT
	    POP     SI
	    POPF
	    RET

	    PUBLIC  MSGOUT
MSGOUT:
	    PUSHF
	    TEST    FTESTBITS,AX
	    JZ	    MRET
	    PUSH    DS
	    PUSH    AX
	    PUSH    BX
	    PUSH    CS
	    POP     DS
	    CALL    WRMSG
	    POP     BX
	    POP     AX
	    POP     DS
MRET:
	    POPF
	    RET

	    PUBLIC DUMPBYTES		;J.K. 4/9/86
;Dumpbytes will dump the bytes in memory in hex.  Space will be put in between
;the bytes and CR, LF will be put at the end. - J.K.
;Input: DS:SI -> buffer to dump in Hex.
;	CX -> # of bytes (Length of the buffer)
;
DUMPBYTES proc near
	pushf
	push	ax
dumploops:
	lodsb
	mov	ah, al
	shr	ah, 1
	shr	ah, 1
	shr	ah, 1
	shr	ah, 1
	call	hex_to_ascii
	push	ax
	mov	al, ah
	call	outchar
	pop	ax
	call	outchar
	mov	al, ' '
	call	outchar
	loop	dumploops

	mov	al, 0dh
	call	outchar
	mov	al, 0ah
	call	outchar

	pop	ax
	popf
	ret
DUMPBYTES	endp

	PUBLIC	Hex_to_ascii
Hex_to_ascii	proc	near		;J.K. - 4/9/86
	and	ax, 0f0fh
	add	ah, 30h
	cmp	ah, 3ah
	jb	hta_$1
	add	ah, 7
hta_$1:
	add	al, 30h
	cmp	al, 3ah
	jb	hta_$2
	add	al, 7
hta_$2:
	ret
Hex_to_ascii	endp

	PUBLIC	outchar
Outchar proc	near
	PUSH	AX
	PUSH	SI
	PUSH	DI
	PUSH	BP
	PUSH	BX
;SB33002*******************************************************
	MOV	AH, 0Eh 		;SET COMMAND TO WRITE A CHAR   ;SB;3.30*
	MOV	BX, 7			;SET FOREGROUND COLOR	       ;SB;3.30*
	INT	10h			;CALL ROM-BIOS		       ;SB;3.30*
;SB33002*******************************************************
	POP	BX
	POP	BP
	POP	DI
	POP	SI
	POP	AX
	RET
Outchar endp

	ENDIF
	INCLUDE MSMACRO.INC

;---------------------------------------------------
;
;	DEVICE ENTRY POINT
;
CMDLEN	=	0			;LENGTH OF THIS COMMAND
UNIT	=	1			;SUB UNIT SPECIFIER
CMD	=	2			;COMMAND CODE
STATUS	=	3			;STATUS
MEDIA	=	13			;MEDIA DESCRIPTOR
TRANS	=	14			;TRANSFER ADDRESS
COUNT	=	18			;COUNT OF BLOCKS OR CHARACTERS
START	=	20			;FIRST BLOCK TO TRANSFER
EXTRA	=	22			;USUALLY A POINTER TO VOL ID FOR ERROR 15
START_L =	26			;AN000; Extended start sector (Low)
START_H =	28			;AN000; Extended start sector (High)

	PUBLIC	STRATEGY
STRATEGY PROC	FAR
	MOV	WORD PTR CS:[PTRSAV],BX
	MOV	WORD PTR CS:[PTRSAV+2],ES
	RET
STRATEGY ENDP

	PUBLIC CON$IN
CON$IN	PROC	FAR
	PUSH	SI
	MOV	SI,OFFSET CONTBL
	JMP	SHORT ENTRY
CON$IN	ENDP

	PUBLIC	AUX0$IN
AUX0$IN PROC	FAR
	PUSH	SI
	PUSH	AX
	XOR	AL,AL
	JMP	SHORT AUXENT
AUX0$IN ENDP

	PUBLIC AUX1$IN
AUX1$IN PROC	FAR
	PUSH	SI
	PUSH	AX
	MOV	AL,1
	JMP	short AUXENT		;J.K. 4/15/86
AUX1$IN ENDP

;SB33102****************************************************************
;SB  Add code to handle two more COM Ports
;boban

	PUBLIC  AUX2$IN
AUX2$IN proc far
	push	si
	push	ax
	mov	al,2
	jmp	short AUXENT
AUX2$IN endp

	PUBLIC  AUX3$IN
AUX3$IN proc far
	push	si
	push	ax
	mov	al,3
	jmp	short AUXENT

;SB33102****************************************************************

AUXENT:
	MOV	SI,OFFSET AUXTBL
	JMP	SHORT ENTRY1
AUX3$IN ENDP

PRN0$IN PROC	FAR
	PUBLIC	PRN0$IN

	PUSH	SI
	PUSH	AX
	XOR	AX,AX
	JMP	SHORT PRNENT
PRN0$IN ENDP

	PUBLIC	PRN1$IN
PRN1$IN PROC	FAR
	PUSH	SI
	PUSH	AX
	XOR	AL,AL
	MOV	AH,1
	JMP	SHORT PRNENT
PRN1$IN ENDP

	PUBLIC PRN2$IN
PRN2$IN PROC	FAR
	PUSH	SI
	PUSH	AX
	MOV	AL,1
	MOV	AH,2
	JMP	SHORT PRNENT
PRN2$IN ENDP

	PUBLIC PRN3$IN
PRN3$IN PROC	FAR
	PUSH	SI
	PUSH	AX
	MOV	AL,2
	MOV	AH,3
PRNENT:
	MOV	SI,OFFSET PRNTBL
	MOV	CS:[PRINTDEV],AH	;SAVE INDEX INTO ARRAY OF RETRY COUNTS
	JMP	SHORT ENTRY1
PRN3$IN ENDP

	PUBLIC	TIM$IN
TIM$IN	PROC	FAR
	PUSH	SI
	MOV	SI,OFFSET TIMTBL
	JMP	SHORT ENTRY
TIM$IN	ENDP

	PUBLIC	DSK$IN
DSK$IN	PROC	FAR
	PUSH	SI
	MOV	SI,OFFSET DSKTBL

ENTRY:
	PUSH	AX
ENTRY1:
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	BP
	PUSH	DS
	PUSH	ES
	PUSH	BX

	MOV	CS:[AUXNUM],AL		;SAVE CHOICE OF AUX/PRN DEVICE

	LDS	BX,CS:[PTRSAV]		;GET POINTER TO I/O PACKET
	ASSUME	DS:NOTHING

	MOV	AL,BYTE PTR DS:[BX].UNIT ;AL = UNIT CODE
	MOV	AH,BYTE PTR DS:[BX].MEDIA ;AH = MEDIA DESCRIP
	MOV	CX,WORD PTR DS:[BX].COUNT ;CX = COUNT
	MOV	DX,WORD PTR DS:[BX].START ;DX = START SECTOR

;SB34MSB100*********************************************************************
;SB
;SB	The disk device driver can now handle 32 bit start sector number.
;SB	So we should check to see if a 32 bit sector number has been specified
;SB	and if so get it. Whether a 32 bit sector has been specified or not
;SB	the disk driver expects a 32 bit sector number with the high word
;SB	in cs:Start_Sec_H and the low word in dx.
;SB
;SB	Algorithm:
;SB		1. Check to see if the request is for the disk driver by 
;SB		   checking to see if SI points to DSKTBL.
;SB
;SB		2. If request not for the disk nothing special needs to be done.
;SB	
;SB		3. If request for the disk then check to see if a 32 bit 
;SB		   sector number has been specified by seeing whether the
;SB		   the conventional sector number specified is -1.  If so
;SB		   we need to pick the 32 bit sector number from the new
;SB		   fields in the request packet.  See the request header
;SB		   struc for the fields you need.  If the conventional
;SB		   sector field is not -1 then a 16 bit sector number
;SB		   has been specified and we just need to initalise the
;SB		   high word in cs:Start_Sec_H to 0
;SB	
;SB NOTE: START_L and START_H are the offsets withing the IO_REQUEST packet
;SB	  which contain the low and hi words of the 32 bit start sector if
;SB	  it has been used.
;SB	
;SB NOTE:Remember not to destroy the registers which have been set up before

	CMP	SI,OFFSET DSKTBL
	JNZ	DSK_REQ_CONT		; Not Disk Req
	CMP	DX,-1
	JNZ	DSK_REQ_16
	MOV	DX,DS:[BX].START_H	; 32 bits DSK REQ
	MOV	CS:START_SEC_H,DX	; CS:Start_sec_H = Packet.Start_H
	MOV	DX,DS:[BX].START_L	; DX             = Packet.Start_L
	JMP	SHORT DSK_REQ_CONT
DSK_REQ_16:
	MOV	CS:START_SEC_H,0
DSK_REQ_CONT:

;SB34MSB100*********************************************************************

	XCHG	DI,AX
	MOV	AL,BYTE PTR DS:[BX].CMD
	CMP	AL,CS:[SI]		;ARR 2.41
	JA	CMDERR

	CBW				; NOTE THAT AL <= 15 MEANS OK
	SHL	AX,1

	ADD	SI,AX
	XCHG	AX,DI

	LES	DI,DWORD PTR DS:[BX].TRANS

	PUSH	CS
	POP	DS

	ASSUME	DS:CODE

	CLD
	JMP	WORD PTR [SI+1] 	;GO DO COMMAND
DSK$IN	ENDP
	PAGE
;=====================================================
;=
;=	SUBROUTINES SHARED BY MULTIPLE DEVICES
;=
;=====================================================
;----------------------------------------------------------
;
;	EXIT - ALL ROUTINES RETURN THROUGH THIS PATH
;
	PUBLIC	BUS$EXIT
BUS$EXIT PROC	FAR
	ASSUME	DS:NOTHING
	MOV	AH,00000011B
	JMP	SHORT ERR1

	PUBLIC	CMDERR
CMDERR:
	MOV	AL,3			;UNKNOWN COMMAND ERROR

	PUBLIC	ERR$CNT
ERR$CNT:
	LDS	BX,CS:[PTRSAV]
	ASSUME	DS:NOTHING
	SUB	WORD PTR [BX].COUNT,CX	;# OF SUCCESSFUL I/O'S

	PUBLIC	ERR$EXIT
ERR$EXIT:
	MOV	AH,10000001B		;MARK ERROR RETURN
	JMP	SHORT ERR1
BUS$EXIT ENDP

EXITP	PROC	FAR
	ASSUME	DS:CODE      ; WE ARE NOT SURE THIS IS CORRECT 3/18/86
EXIT$ZER:
	LDS	BX,[PTRSAV]
	ASSUME	DS:NOTHING
	XOR	AX,AX
	MOV	WORD PTR [BX].COUNT,AX	;INDICATE NO CHARS READ

	PUBLIC	EXIT
EXIT:
	ASSUME	DS:NOTHING
	MOV	AH,00000001B
ERR1:
	ASSUME	DS:NOTHING
	LDS	BX,CS:[PTRSAV]
	MOV	WORD PTR [BX].STATUS,AX ;MARK OPERATION COMPLETE

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

;-------------------------------------------------------------
;
;	CHROUT - WRITE OUT CHAR IN AL USING CURRENT ATTRIBUTE
;
;	CALLED VIA INT 29H
;
	PUBLIC	CHROUT
CHROUT	=	29H

	PUBLIC	OUTCHR
OUTCHR	PROC	FAR
	PUSH	AX
	PUSH	SI
	PUSH	DI
	PUSH	BP
;SB33002a*******************************************************
	push	bx			;			      ;SB ;3.30
	mov	AH, 0Eh 		; set command to write a character;SB;3.30
	mov	BX, 7			; set foreground color	      ;SB ;3.30
	int	10h			; call rom-bios 	      ;SB ;3.30
	pop	bx			;			      ;SB ;3.30
;SB33002a*******************************************************
	POP	BP
	POP	DI
	POP	SI
	POP	AX
	IRET
OUTCHR	ENDP
;----------------------------------------------
;
;	SET DX TO AUXNUM
;
	PUBLIC GETDX
GETDX	PROC	NEAR
	MOV	DX,WORD PTR CS:[AUXNUM]
	RET
GETDX	ENDP
	PAGE
;************************************************** ARR 2.15

;-----------------------------------------------
;
;	TIMER INTERRUPT HANDLER
;
;TIMER_LOW	 DW	 0
;TIMER_HIGH	 DW	 0
;
;TIMER:
;	 STI
;	 PUSH	 AX
;	 PUSH	 CX
;	 PUSH	 DX
;	 PUSH	 DS
;	 PUSH	 CS
;	 POP	 DS
;	 XOR	 AX,AX
;	 INT	 1AH			 ; GET ROM TIME AND ZAP ROLL OVER
;	 MOV	 [TIMER_HIGH],CX
;	 MOV	 [TIMER_LOW],DX
;	 OR	 AL,AL
;	 JZ	 T5
;	 INC	 WORD PTR [DAYCNT]		  ; ONE DAY GONE BY
;T5:
;	 POP	 DS
;	 POP	 DX
;	 POP	 CX
;	 POP	 AX
;	 IRET
;************************************************** ARR 2.15
CODE	ENDS
	END
