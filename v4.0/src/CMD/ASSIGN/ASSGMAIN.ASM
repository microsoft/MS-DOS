

	PAGE	90,132			  ;
	TITLE	ASSGMAIN.SAL - ASSIGN  MAIN PROGRAM
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: ASSGMAIN.SAL
;
; DESCRIPTIVE NAME: Reassigns drive specifications.
;
;FUNCTION: This program reassigns the specified drives to a new drive
;	   identifier.
;
; ENTRY POINT: ENTRY_POINT
;
; INPUT:
;
;   ASSIGN [DRIVE] [DELIMITER] [DRIVE] [SW]
;    where DRIVE = optional colon
;    where DELIMITER = +;=TAB LF SPACE
;    where SW = /STATUS or /STA
;
;    where:
;	 /STATUS - reports back to the user
;		   the currently changed
;		   drive assignments and the
;		   new assignment drive
;
;    Note:
;	  If a drive value has not been
;	  ASSIGN will report back nothing.
;
;    UTILITY FUNCTION:
;    Instructs DOS to route disk I/O
;    for one drive into disk I/O to another
;    drive.	 eg.
;		   a=c sets a: to c:
;
; EXIT-NORMAL:	Assigned drives or reassigned drives
;
; EXIT-ERROR:	Any one of the possible parse errors
;
; INTERNAL REFERENCES:
;    ROUTINES: SYSPARSE:near (INCLUDEd in PARSE.SAL)
;	       SYSLOADMSG
;	       SYSDISPMSG
;
;
; EXTERNAL REFERENCES:
;    ROUTINES: none
;
; NOTES:
;	 This module should be processed with the SALUT preprocessor
;	 with the re-alignment not requested, as:
;
;		SALUT  ASSPARM,NUL;
;
;	 To assemble these modules, the sequential
;	 ordering of segments may be used.
;
;	 For LINK instructions, refer to the PROLOG of the main module,
;	 ASSIGN.SAL
;
; REVISION HISTORY: AN000 - Version 4.00: PARSER, System Message Handler,
;					  Status report
;
; COPYRIGHT: "Microsoft DOS ASSIGN Utility"
;	     "Version 4.00 (C)Copyright 1988 Microsoft"
;	     "Licensed Material - Program Property of Microsoft"
;
;
;	AN000	->		New Code
;
;	AN001	-> PTM P3954	Release the environmental vector and close
;				all handles.
;
;	AN002	-> PTM P3918	Parse error messages must conform to spec.
;				All parse error messages should display
;				the offending parameters.
;
;
;****************** END OF SPECIFICATIONS *****************************

;*********************************************
;*					     *
;*  UTILITY NAME:	ASSIGN.COM	     *
;*					     *
;*  SOURCE FILE NAME:	ASSIGN.SAL	     *
;*					     *
;*  STATUS:		ASSIGN utility	     *
;*			PC-DOS Version 3.40  *
;*					     *
;*  SYNTAX (Command line)		     *
;*					     *
;*  ASSIGN [DRIVE] [DELIMITER] [DRIVE] [SW]  *
;*   where DRIVE = optional colon	     *
;*   where DELIMITER = +;=TAB LF SPACE	     *
;*   where SW = /STATUS or /STA 	     *
;*					     *
;*   where:				     *
;*	 /STATUS - reports back to the user  *
;*		   the currently changed     *
;*		   drive assignments and the *
;*		   new assignment drive      *
;*   Note:				     *
;*	  If a drive value has not been      *
;*	  ASSIGN will report back nothing.   *
;*					     *
;*   UTILITY FUNCTION:			     *
;*   Instructs DOS to route disk I/O	     *
;*   for one drive into disk I/O to another  *
;*   drive.	 eg.			     *
;*		   a=c sets a: to c:	     *
;*********************************************

page
DEBUG	=	0

.xlist
	INCLUDE SYSMSG.INC		;AN000;
	INCLUDE SYSVAR.INC
	INCLUDE CURDIR.INC
	INCLUDE MULT.INC
	INCLUDE PDB.INC

MSG_UTILNAME <ASSIGN>

.list

; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	BREAK	<MACRO DEFINITIONS>
BREAK	MACRO	subtitle
.XLIST
	SUBTTL	subtitle
.LIST
	PAGE
	ENDM
.xcref	break
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
CallOperRange macro low,high,routine	;;NS-macro to call subroutines
?call	=	low			;;NS-in the given call range
					;;NS-starting call value = low #
rept	(high-low)+1			;;NS-calculate the entry point
	CallOper ?call,routine		;;NS-into the table then execute
	?call	= ?call + 1		;;NS-increment call value to next
endm
	endm
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
CallOper macro	call,routine		;;NS-macro that calls a single
					;;NS-subroutine that is used in
					;;NS-the above macro loop CallOperange
	ORG	(SysTab-ASSIGN_BASE)+(call*2) ;;NS-Calculate entry point into
	DW	OFFSET CODE:routine	;;NS-code where SysTab is the
	ENDM				;;NS-entry point to the tables
					;;NS-ASSIGN_BASE is at 0:0000
					;;NS-the (call*2) is calculated
					;;NS-to take into account two bytes
					;;NS-and final OFFSET statement points
					;;NS-code to be executed at the given
					;;NS-label
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
;	$SALUT	(0,36,40,48)
MyINT21 macro				;;NS-macro used to save
	pushf				;;NS-the flags to maintain
	call	system			;;NS-DOS environment
	endm
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
SaveReg MACRO	reglist 		;; push those registers
IRP	reg,<reglist>
	?stackdepth = ?stackdepth + 1
	PUSH	reg
ENDM
ENDM
.xcref	SaveReg
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
RestoreReg MACRO reglist		;; pop those registers
IRP	reg,<reglist>
	?stackdepth = ?stackdepth - 1
	POP	reg
ENDM
ENDM
.xcref	RestoreReg

; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
page
	BREAK	<DOS FUNCTIONS, AND OTHER EQUATES>
;	$SALUT	(0,23,28,41)
;		DOS FUNCTIONS USED
;			  (DEC) 	(HEX)
NO_ERROR equ	0			;return code zero from the parser
					;********** CNS *****************
;Std_Con_String_Output EQU 9		 ;  9
PSP_Env 		equ	2ch	;Environmental vector segment in PSP	;an001; dms;
Get_PSP 		equ	62h	; DOS function call to get PSP address	;an001; dms;
Handle_Close		equ	3eh	;close handle				;an001; dms;

Set_Default_Drive	EQU	14	;  E
Get_Default_Drive	EQU	25	; 19
Set_Interrupt_Vector	EQU	37	; 25
Get_Version		EQU	48	; 30
Keep_Process		EQU	49	; 31
Get_Interrupt_Vector	EQU	53	; 35
Get_Drive_Freespace	EQU	54	; 36
Exit			EQU	76	; 4C
Dealloc 		EQU	73	; 49
Get_In_Vars		EQU	82	; 52
Get_Set_Media_ID	equ	69h	; 69h

IOCTL_READ_BLOCK EQU 4404H		;READ FROM BLOCK DEVICE
IOCTL_WRITE_BLOCK EQU 4405H		;WRITE TO A BLOCK DEVICE
IOCTL_BLOCK_CHANGE EQU 4408H		;BLOCK DEVICE CHANGEABLE
IOCTL_BLOCK_REMOTE EQU 4409H		;BLOCK DEVICE REMOTE

;		VECTORS REFERENCED
PGM_TERM EQU	20H
DOS_CALL EQU	21H
CTL_BREAK EQU	23H
CRIT_ERR EQU	24H
ABS_DISK_READ EQU 25H
ABS_DISK_WRITE EQU 26H
stay	equ	27h			;NS  stay interrupt value
int_IBM EQU	2AH			;critical section maintenance
MULTIPLEXOR EQU 2FH			;MULTIPLEXOR INTERRUPT VECTOR NUMBER

;		CONSTANTS USED ACROSS THE MULTIPLEXOR INTERFACE
MPLEX_ID EQU	06H			;ID OF ASSIGN IN MPLEX CHAIN
MPLEX_R_U_THERE EQU 0			;MPLEX FUNCTION: ARE YOU THERE?
MPLEX_GET_SEG EQU 1			;MPLEX FUNCTION: GET SEG OF INSTALLED ASSIGN
MPLEX_INSTALLED EQU 0FFH		;"I AM HERE" RETURN VALUE

;		OTHER EQUATES
cr	equ	0dh			;CARRIAGE RETURN
LF	EQU	0AH			;LINE FEED
f_Interrupt EQU 0000001000000000B	;NS - mask used for interrupt
					;NS  value
	BREAK	<ENTRY POINT FOR CODE, EXTRNS>
;	$SALUT	(4,15,21,41)

code	segment para   public		;NS code all in one segment
assume	cs:code
					;   one segment

page

ASSIGN_BASE:				;NS- starting point of loaded file
	org	100h

ENTRY_POINT:
	jmp	INITIALIZATION		;JUMP TO INITIALIZATION
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	BREAK	<TABLES AND LOCAL WORKAREAS>
drives	db	1,2,3,4,5,6,7,8,9	;drive values used in comparison
	db	10,11,12,13,14,15,16,17,18,19 ;against default or found drive
	db	20,21,22,23,24,25,26
default_drive db ?
drive_save db	?			; saved drive byte
drive_address dw ?			; location (from DS) of drive byte
drive_save2 db	?			; second saved drive byte
;******************************************************************************
;******************************************************************************

system	dd	?
int25_vec dd	?			;NS - Hooks for the Int 2f handler preparation
int26_vec dd	?			;NS - Hooks for the Int 2f handler preparation
int2F_vec dd	?			;NS - Area to be hooked in and remain resident
user_ret dd	?			;     ???????????????????????????????????????
saveIntF dw	?			;     ???????????????????????????????????????
I21_Func db	?			; Save area for INT21 function requested -->RW


;	$SALUT	(4,9,23,41)
	EVEN
SysTab	label	word			;NS-Beginning of the call,subroutine table
	CallOper 00h,DoReset
	CallOperRange 01h,0Ch,DoNothing ; done ????????????????????????
	CallOper 0Dh,DoReset		; done ????????????????????????
	CallOper 0Eh,DoSetDefault
	CallOperRange 0Fh,17h,DoFCB	; done ????????????????????????
	CallOper 18h,DoReset		; done ????????????????????????
	CallOper 19h,DoGetDefault	;     ????????????????????????
	CallOperRange 1Ah,1Bh,DoReset	; done ????????????????????????
	CallOper 1Ch,DoDL		; done ????????????????????????
	CallOperRange 1Dh,20h,DoReset	; done ????????????????????????
	CallOperRange 21h,24h,DoFCB	; done ????????????????????????
	CallOperRange 25h,26h,DoReset	; done ????????????????????????
	CallOperRange 27h,28h,DoFCB	; done ????????????????????????
	CallOperRange 29h,31h,DoReset	; done ????????????????????????
	CallOper 32h,DoDL		; done ????????????????????????
	CallOperRange 33h,35h,DoReset	; done ????????????????????????
	CallOper 36h,DoDL		; done ????????????????????????
	CallOperRange 37h,38h,DoReset	; done ????????????????????????
	CallOperRange 39h,3Dh,DoAscii	; done ????????????????????????
	CallOperRange 3Eh,40h,DoReset	; done ????????????????????????
	CallOper 41h,DoAscii		; done ????????????????????????
	CallOper 42h,DoReset		; done ????????????????????????
	CallOper 43h,DoAscii		; done ????????????????????????
	CallOper 44h,DoIOCTL		; done ????????????????????????
	CallOperRange 45h,46h,DoReset	; done ????????????????????????
	CallOper 47h,DoDL		; done ????????????????????????
	CallOperRange 48h,4Ah,DoReset	; done ????????????????????????
	CallOper 4Bh,DoExec		; done ????????????????????????
	CallOperRange 4Ch,4Dh,DoReset	; done ????????????????????????
	CallOper 4Eh,DoAscii		; done ????????????????????????
	CallOperRange 4Fh,55h,DoReset	; done ????????????????????????
	CallOper 56h,DoRename		; done ????????????????????????
	CallOperRange 57h,59h,DoReset	; done ????????????????????????
	CallOperRange 5Ah,5Bh,DoAscii	; done ????????????????????????
	CallOperRange 5Ch,5Fh,DoReset	; done ????????????????????????
	CallOper 60h,DoTranslate	; done ????????????????????????
	CallOperRange 61h,63h,DoReset	; done ????????????????????????
	CallOperRange 64h,69h,DoSetGetMedia ;done ????????????????????????
	CallOperRange 6ah,6bh,DoNothing ;done ????????????????????????
	CallOper 6ch,DoAscii_DS_SI	;done ?????????????????????????
					; ????????????????????????
page
;	$SALUT	(4,5,11,36)
MAXCLL	EQU	6CH			; High bound of table

	org	(systab-ASSIGN_BASE) + (2 * (MAXCLL + 1)) ;NS - Beginning of code starts at
					;NS - Beginning of table + 128 bytes
	BREAK	<ASSIGN INTERRUPT HANDLER>
ASSIGN_HANDLER:
	mov	SaveIntf,f_interrupt	;NS- Move in the mask into a saved area
	SaveReg <AX,BX> 		;NS- ??????????????????????????????????
	cmp	ah,MAXCLL		; Do a high bound check on the call
					;  so we don't index past the end of
	ja	DoNothing		;  the table on a bogus call

	mov	al,ah			;NS-  Call must be in the 0 - 63h range
	cbw				;NS-  zero out the high byte now
					;NS-  AX has 0 & call number
	shl	ax,1			;NS-  Double the value in AX
	mov	bx,ax			;NS-  Move the value into BX to
	jmp	systab[bx]		;NS-  access the call number & subroutine
					;NS-  bx bytes into the tbl
;***********************************************************************************

EnterAssign:				;NS- make sure system intact by doing
	call	LeaveAllAssign		;NS- error recovery check

	push	ax			;NS- before making code
	mov	ax,8000h + critAssign	;NS- non- reentrant if unable
	INT	INT_IBM 		;(2AH) NS- to screen out successfully

	POP	AX			;NS- LeaveAllAssign will be executed
	RET				;return NS- and the critical section will be reset
;************************************************************************************
LeaveAssign:				;NS- restore re-entrancy to
	push	ax			;NS- the code after & only
	mov	ax,8100h + critAssign	;NS- after this call has been
	INT	INT_IBM 		;(2AH) NS- made or the error recovery

	POP	AX			;NS- call has been made
	RET				;return NS-

;************************************************************************************
LeaveAllAssign: 			;NS- Error recovery call
	push	ax			;NS- to restore the Assigns
	mov	ax,8908h		;NS- critical section
	int	INT_IBM 		;(2AH) NS- if ASSIGN has encountered

	pop	ax			;NS- a problem on entrance or departure
	RET				;return NS-
;************************************************************************************
;
; Reset the exclusion flag		;NS- Reset to Assign
;					;NS- critical section state
DoReset:				;NS-
	call	LeaveAllAssign		;NS-
					;NS-
;****************************************************************************************
;
; The system call needed no special processing.  Go do it directly.
;
DoNothing:				;NS-System registers and flags still
	RestoreReg <bx,ax>		;NS-intact it has not been clobbered
	jmp	system			;NS-by ASSIGN code

page
;************************************************************************************
;
; Munge the drive byte in an FCB pointed to by DS:DX.
; "MUNGE" ? (Webster will turn over in his gravy...)
;
DoFCB:
	mov	bx,dx			; indexable pointer
	mov	al,[bx] 		; get drive
	cmp	al,0ffh 		; extended fcb?
	jnz	DoMapDrive		; no

	add	bx,7			; yes, advance past it
	mov	al,[bx] 		; get read drive byte
DoMapDrive:
	or	al,al			; default drive?
;	$IF	Z			;YES
	JNZ $$IF1
	    mov     al,default_drive	; get default drive
;
; DS:BX points to the drive byte being munged.	AL is the old value.  Save
; it away.
;
;	$ENDIF				;AC000;
$$IF1:
					;SaveFCB:
	call	EnterAssign		; NS-Enter Assign's critical section

	mov	drive_save,al		; NS-save the drive assignment
	call	mapdrv1 		; NS-now let's map it to the

	mov	[bx],al 		; NS-numeric drive associated in
					; NS-in drive range 1 to 26
;******************************************************************************
; The FCB has been converted.  Now let's POP off the user's info and do the
; system call. Note that we are no longer reentrant!
;
	mov	drive_address,bx	; NS- location of drive value
	RestoreReg <BX,AX>		; get back original registers
	pop	word ptr user_ret	; restore his IP
	pop	word ptr user_ret+2	; restore his CS
	call	GotoCLI 		; NS- Clear out old interrupts
					; NS- before an IRET is issued
					; NS- update the current
	call	system			; flags saved => this is a system call

	pushf				; NS- re-adjust the stack
	call	RestInt 		; NS- and setup the environment

	SaveReg <ax,bx> 		; NS- with drive and the drive address
	mov	bx,drive_address	; NS- before leaving the Assign critical
	mov	al,drive_save		; NS- section
	mov	[bx],al
	RestoreReg <bx,ax>
	push	word ptr user_ret+2	; push back user's cs
	push	word ptr user_ret	; push back user's ip
	Call	LeaveAssign

	iret				; back to user

page
;************************************************************************************
;
; Munge the user's ASCIZ string at DS:DX.
;
DoAscii:
	mov	bx,dx			; point to area
	cmp	byte ptr [bx+1],':'	; drive letter present?
	jnz	DoNothing		; nope, ignore this
;
; There is a drive leter present.  Grab it and convert it
;
	mov	al,[bx] 		; get drive letter
	call	EnterAssign		; NS- Re-enter ASSIGN crit section

	mov	drive_save,al		; remember previous contents
	call	maplet			; convert to real drive letter

	mov	[bx],al 		; place in new drive letter
	mov	drive_address,bx
	RestoreReg <BX,AX>		; get back original registers
	pop	word ptr user_ret	; restore his IP
	pop	word ptr user_ret+2	; restore his CS
	call	GotoCLI 		; clean up stack

	call	system			; flags saved => this is a system call

	pushf				; save all drive info
	call	RestInt 		; NS- clean up environment before

	SaveReg <ax,bx> 		; NS- returning to the user's environment
	mov	bx,drive_address	; NS- to ask on the next ASSIGN entrance
	mov	al,drive_save
	mov	[bx],al
	RestoreReg <bx,ax>
	push	word ptr user_ret+2	; push back user's cs
	push	word ptr user_ret	; push back user's ip
	Call	LeaveAssign		; NS-  exit ASSIGN crit. section

	iret				; back to user


;************************************************************************************
;
; Munge the user's ASCIZ string at DS:SI.
;
DoAscii_DS_SI:
	mov	bx,si			; point to area
	cmp	byte ptr [bx+1],':'	; drive letter present?
;	$if	ne			; drive letter not present
	JE $$IF3
		jmp	DoNothing	; nope, ignore this
;	$endif				;
$$IF3:
;
; There is a drive leter present.  Grab it and convert it
;
	mov	al,[bx] 		; get drive letter
	call	EnterAssign		; NS- Re-enter ASSIGN crit section

	mov	drive_save,al		; remember previous contents
	call	maplet			; convert to real drive letter

	mov	[bx],al 		; place in new drive letter
	mov	drive_address,bx
	RestoreReg <BX,AX>		; get back original registers
	pop	word ptr user_ret	; restore his IP
	pop	word ptr user_ret+2	; restore his CS
	call	GotoCLI 		; clean up stack

	call	system			; flags saved => this is a system call

	pushf				; save all drive info
	call	RestInt 		; NS- clean up environment before

	SaveReg <ax,bx> 		; NS- returning to the user's environment
	mov	bx,drive_address	; NS- to ask on the next ASSIGN entrance
	mov	al,drive_save
	mov	[bx],al
	RestoreReg <bx,ax>
	push	word ptr user_ret+2	; push back user's cs
	push	word ptr user_ret	; push back user's ip
	Call	LeaveAssign		; NS-  exit ASSIGN crit. section

	iret				; back to user

page
;************************************************************************************

;
; DoDL - the drive to map is in DL.
;
DoDL:
	or	dl,dl			; NS- check for drive mapping
;	$IF	Z			;AC000;;USE DEFAULT DRIVE
	JNZ $$IF5

DNJ1:
	    jmp     DoNothing		; NS- default drive was requested
					; NS- thus no mapping needed
;	$ENDIF				;AC000;
$$IF5:
	mov	al,dl			; NS- not default case so no need doctor
	call	EnterAssign		; NS- so enter ASSIGN crit. section again

	mov	drive_save,al		; preserve old drive
	call	mapdrv1

	mov	dl,al			; drive is mapped
	RestoreReg <BX,AX>		; get back registers
	mov	I21_Func,ah		; Save requested function call -->RW
	pop	word ptr user_ret	; restore his IP
	pop	word ptr user_ret+2	; restore his CS
	call	GotoCLI

	call	system			; flags saved => this is a system call

	pushf				;
	call	RestInt

	cmp	I21_Func,GET_DRIVE_FREESPACE ;(36h) If call returns info in DX, -->RW
					; NS- DL in both cases Func 36
					; NS- Func 1Ch are both used for
					; NS- drive input  we don't want to
					; NS- the old drives so they should not
					; restored as the old value - use ASSIGN's
	je	Dont_Restore_DL 	;AC000;;THEN DO CHANGE IT

	cmp	I21_Func,1ch		; If call returns info in DX, -->RW
					;(NOTE 1CH IS NOT DEFINED IN SYSCALL.INC. EK)
	je	Dont_Restore_DL 	;AC000;;THEN DO CHANGE IT

	mov	dl,drive_save		; restore his dl
					;DONT_RESTORE_DL:
Dont_Restore_DL:

	push	word ptr user_ret+2	; push back user's cs
	push	word ptr user_ret	; push back user's ip
	Call	LeaveAssign

	iret				; back to user
;************************************************************************************

; Map the IOCTL drives in BX		; NS- this section handles
					; NS- INT21 calls to get drive info
DoIOCTL:
	RestoreReg <BX,AX>
	SaveReg <AX,BX>
	cmp	ax,IOCTL_READ_BLOCK	;(4404h) IOCTL read string from block dev
	jz	DoMapBX 		;AC000;
					;    jz    DoMapBX
	cmp	ax,IOCTL_WRITE_BLOCK	;(4405h) IOCTL write string from block dev
	jz	DoMapBX 		;AC000;
					;    jz    DoMapBX
	cmp	ax,IOCTL_BLOCK_CHANGE	;(4408h) IOCTL is removable
	jz	DoMapBX 		;AC000;
					;    jz    DoMapBX
	cmp	ax,IOCTL_BLOCK_REMOTE	;(4409h) IOCTL block dev redir (network)
	jnz	DNJ2			;AC000;;NORMAL CALL
					;DoMapBX:
DoMapBX:

	or	bx,bx			; NS- drive letter associated in BL
	jz	DNJ2

	mov	al,bl			; not the default case
	call	EnterAssign

	mov	drive_save,al		; remember drive
	call	mapdrv1 		; NS- time to map drive to new assoc.

	mov	bl,al			; drive is mapped
	RestoreReg <AX,AX>		; get back registers (throw away BX)
	pop	word ptr user_ret	; restore his IP
	pop	word ptr user_ret+2	; restore his CS
	call	GotoCLI

	call	system			; flags saved => this is a system call

	pushf
	call	RestInt

	mov	bl,drive_save		; restore his dl
	push	word ptr user_ret+2	; push back user's cs
	push	word ptr user_ret	; push back user's ip
	Call	LeaveAssign

	iret				; back to user

DNJ2:

	jmp	DoNothing

DoSetGetMedia:
	RestoreReg <BX,AX>				;an000; dms;restore regs
	SaveReg <AX,BX> 				;an000; dms;save regs
	cmp	ah,Get_Set_Media_ID			;an000; dms;trap on get/set media id
;	$if	z					;an000; dms;found
	JNZ $$IF7
		or	bl,bl				;an000; dms;drive letter entered
;		$if	nz				;an000; dms;yes
		JZ $$IF8
			mov	al,bl			; not the default case
			call	EnterAssign

			mov	drive_save,al		; remember drive
			call	mapdrv1 		; NS- time to map drive to new assoc.

			mov	bl,al			; drive is mapped
			RestoreReg <AX,AX>		; get back registers (throw away BX)
			pop	word ptr user_ret	; restore his IP
			pop	word ptr user_ret+2	; restore his CS
			call	GotoCLI

			call	system			; flags saved => this is a system call

			pushf
			call	RestInt

			mov	bl,drive_save		; restore his dl
			push	word ptr user_ret+2	; push back user's cs
			push	word ptr user_ret	; push back user's ip
			Call	LeaveAssign
;		$else					;an000; dms;not valid function 69h
		JMP SHORT $$EN8
$$IF8:
			jmp	DoNothing		;an000; dms;pass to interrupt
;		$endif					;an000; dms;
$$EN8:
;	$else						;an000; dms;
	JMP SHORT $$EN7
$$IF7:
		jmp	DoNothing			;an000; dms;pass to interrupt
;	$endif						;an000; dms;
$$EN7:

	iret				; back to user
page
;************************************************************************************
;
; Map the drive letter and forget about it.  EXEC never returns.
;
DoExec:
	RestoreReg <BX,AX>
	SaveReg <AX,BX>
	or	al,al
;	$IF	Z			;AC000;;IS LOAD GO, NOT USE NORMAL STUFF
	JNZ $$IF13

	    mov     bx,dx		; point to area
DoOnce:
	    cmp     byte ptr [bx+1],':' ; drive letter present?
;	    $IF     Z			;AC000;;YES
	    JNZ $$IF14
;
; There is a drive leter present.  Grab it and convert it
;
		mov	al,[bx] 	; get drive letter
		call	maplet		; convert to real drive letter

		mov	[bx],al 	; place in new drive letter
;	    $ENDIF			;AC000;
$$IF14:
DNJ3:
	    jmp     DoNothing		; restore and go on!

;	$ENDIF
$$IF13:
					;DAJ:
	jmp	DoAscii

;************************************************************************************
;
; Map the drive letter at DS:SI.  We need to un-map it at the end.
;
DoTranslate:
	mov	bx,SI			; point to area
	cmp	byte ptr [bx+1],':'	; drive letter present?
	jnz	DNJ3			; nope, ignore this
;
; There is a drive leter present.  Grab it and convert it
;
	mov	al,[bx] 		; get drive letter
	call	EnterAssign

	mov	drive_save,al		; remember previous contents
	call	maplet			; convert to real drive letter

	mov	[bx],al 		; place in new drive letter
	mov	drive_address,bx
	RestoreReg <BX,AX>		; get back original registers
	pop	word ptr user_ret	; restore his IP
	pop	word ptr user_ret+2	; restore his CS
	call	GotoCLI

	call	system			; flags saved => this is a system call

	pushf
	call	RestInt

	SaveReg <ax,bx>
	mov	bx,drive_address
	mov	al,drive_save
	mov	[bx],al
	RestoreReg <bx,ax>
	push	word ptr user_ret+2	; push back user's cs
	push	word ptr user_ret	; push back user's ip
	Call	LeaveAssign

	iret				; back to user

page
;************************************************************************************
;
; Munge the user's ASCIZ string at DS:DX and es:di
;
DoRename:
	mov	bx,dx			; point to area
	mov	ax,[bx]
	call	EnterAssign

	mov	drive_save,al
	mov	drive_address,bx
	cmp	ah,':'			; drive letter present?
;	$IF	Z			;AC000;
	JNZ $$IF17

	    call    maplet		; convert to real drive letter

	    mov     [bx],al		; place in new drive letter
;	$ENDIF				;AC000;
$$IF17:
					;DoES:
	mov	ax,es:[di]		;NS- Get the 2nd drive from the command linepSOP
	mov	drive_save2,al		;NS- Save possible drive
	cmp	ah,':'			;NS- exclude if no colon present
;	$IF	Z			;AC000;
	JNZ $$IF19

	    call    maplet		;NS- go convert letter to actual drive #

	    mov     es:[di],al		;NS- new drive value
;	$ENDIF				;AC000;
$$IF19:
					;DoIt:
	RestoreReg <BX,AX>		; get back original registers
	pop	word ptr user_ret	; restore his IP
	pop	word ptr user_ret+2	; restore his CS
	call	GotoCLI

	call	system			; flags saved => this is a system call

	pushf
	call	RestInt

	SaveReg <ax,bx>
	mov	al,drive_save2		; NS- get the second drive update
	mov	es:[di],al		; NS- on the command line
	mov	bx,drive_address	;
	mov	al,drive_save		;
	mov	[bx],al 		;
	RestoreReg <bx,ax>		;
	push	word ptr user_ret+2	; push back user's cs
	push	word ptr user_ret	; push back user's ip
	Call	LeaveAssign

	iret				; back to user

;************************************************************************************
;
; DoGetDefault - return our idea of the current drive...
;
DoGetDefault:
	call	Assign_Check

;	$IF	Z			;AC000;
	JNZ $$IF21
					;DNJ4:
	    jmp     DoNothing

;	$ENDIF				;AC000;
$$IF21:
	RestoreReg <BX,AX>
	mov	al,default_drive
	dec	al
	iret

page
;************************************************************************************
;
; DoSetDefault - try to set to the mapped current drive.  If we can do it,
; then OK, else oops!
;
DoSetDefault:
	RestoreReg <BX,AX>
	mov	al,dl			; get new drive
	inc	al			; convert it to 1-based
	call	EnterAssign

	mov	drive_save,al		; remember what we're doing
	call	mapdrv1 		; convert drive

	dec	al			; convert back to 0-based
	mov	dl,al			; stick back in correct register
	mov	drive_save2,al		; remember more of what we're doing
	MyInt21 			; try the set

	push	ax			; save return info from set
	mov	ah,Get_Default_Drive	;(29h)
	MyInt21

	mov	dl,drive_save
	dec	dl			; Restore users original value
	cmp	al,drive_save2		; Did the set work?
;	$IF	Z			;AC000;;YES!
	JNZ $$IF23

	    mov     al,drive_save
	    mov     default_drive,al	; Set ours too, it's valid!
;	$ENDIF				;AC000;
$$IF23:
					;BadDrive:
	pop	ax			; Set return info
	call	LeaveAssign

	iret

;************************************************************************************
;
; Maintain the CLI state upon the next IRET.  Flags for the IRET are on the
; stack just under the return address.	This means saving the current state
; of the int flag and then turning off the saved version.
;
GotoCLI:
	push	ax
	push	bp
	mov	bp,sp
;	      bp  ax  ret  f
	mov	ax,[bp + 2 + 2 + 2]
	and	SaveIntf,ax		; save those interrupts
	and	word ptr [bp + 2 + 2 + 2],not f_interrupt
	pop	bp
	pop	ax
	ret
;
;************************************************************************************
; Restore he saved interrupt flag for the user.  His flags are on the stack
; just above the RET.
;
RestInt:
	push	ax
	push	bp
	mov	bp,sp
	mov	ax,SaveIntf
;	   bp  ax  ret	f
	or	[bp + 2 + 2 + 2],ax
	pop	bp
	pop	ax
	ret

;************************************************************************************
mapdrv0:				;a = 0 , b = 1
	inc	al
;	$IF	NZ			;AC000;
	JZ $$IF25

	    call    mapdrv1

;	$ENDIF				;AC000;
$$IF25:
					;Wrap0:
	dec	al
	ret

;************************************************************************************
mapdrv1:
	cmp	al,26
;	$IF	NA			;AC000;
	JA $$IF27

	    cmp     al,0		; check for default
;	    $IF     Z			;AC000;
	    JNZ $$IF28

		mov	al,default_drive
		mov	drive_save,al
;	    $ENDIF			;AC000;
$$IF28:

	    push    bx			;a = 1, b = 2
	    push    cx
	    mov     ch,ah
	    cbw
	    mov     bx,offset drives-1
	    add     bx,ax
	    mov     al,cs:[bx]
	    mov     ah,ch
	    pop     cx
	    pop     bx
;	$ENDIF				;AC000;
$$IF27:
	ret

;************************************************************************************
maplet:
	cmp	al,'A'
	jb	LetDone

	cmp	al,'Z'
	jbe	DoMapLet

	cmp	al,'a'
	jb	LetDone

	cmp	al,'z'
	ja	LetDone

DoMapLet:
	or	al,20h
	sub	al,"a"-1
	call	mapdrv1

	add	al,40h
LetDone:
	ret

page
;************************************************************************************
int25:
	call	mapdrv0

	jmp	int25_vec

int26:
	call	mapdrv0

	jmp	int26_vec

int2F:
	CMP	AH,mplex_id		;(06h) is this our multiplex?
;	$IF	NE			;AC000;;NO
	JE $$IF31

	    jmp     int2F_vec		; No, Chain to next guy

;	$ENDIF				;AC000;
$$IF31:
					;MINE:
	CMP	AL,mplex_get_seg	;(01h)
					;0 AND 1 ARE THE ONLY ALLOWED FUNCTIONS
;	$IF	NA			;AC000;;IF NOT SOME OTHER NUMBER,
	JA $$IF33
;	    $IF     E			;AC000;;IF FUNCTION REQUEST IS 01
	    JNE $$IF34
					;RETURN THE SEGID IN ES
		PUSH	CS
		POP	ES		; Call 1 gets our segment in ES
;	    $ENDIF			;AC000;
$$IF34:
					;QUER:
	    MOV     AL,MPLEX_INSTALLED	;(0FFh)  I AM here
;	$ENDIF
$$IF33:
					;RESERVED_RET:
	IRET

;************************************************************************************
assign_check:
	push	si
	push	ax
	push	cx
	xor	ax,ax
	mov	si,ax
	mov	cx,26
;	$SEARCH 			;AC000;
$$DO37:
					;scn:
	    mov     al,drives[si]
	    INC     SI
	    cmp     ax,si
;	$EXITIF NZ,NUL			;AC000;
	JNZ $$SR37

;	$ENDLOOP LOOP			;AC000;
	LOOP $$DO37

	    xor     ax,ax		; reset z flag
;	$ENDSRCH			;AC000;
$$SR37:
					;scndone:
	pop	cx
	pop	ax
	pop	si
	ret

prog_size =	($-ASSIGN_BASE+15)/16

page
;************************************************************************************
;			TRANSIENT CODE
;************************************************************************************
;*********************************************
;*					     *
;* Subroutine name: Initialization	     *
;*					     *
;* Purpose: Process the command line.	     *
;*	 If there are no errors update	     *
;*	 the drive table according to	     *
;*	 the drive assignments, terminate    *
;*	 and stay resident. If status switch *
;*	 set and the drive values have been  *
;*	 altered display drive is set to     *
;*	 2nd drive.			     *
;*					     *
;* Input: Command line (described in header) *
;*					     *
;* Output: Table will be updated and resident*
;*	   code will be hooked in.	     *
;*					     *
;* Normal Exit: Valid drives, sufficient     *
;*		memory. 		     *
;* Error Conditions:			     *
;*		Incorrect DOS Version	     *
;*		Invalid Parameter	     *
;*		Invalid switch		     *
;*Externals:				     *
;*	    PROCESS_PATH		     *
;*	    REPORT_STATUS		     *
;*	    EXIT_PROG			     *
;*					     *
;*********************************************
;    *****************************************
;    *		 INITIALIZATION 	     *
;    *****************************************
;    *					     *
;    *	CALL SYSLOADMSG 		     *
;    *	Do DOS Versinon Check		     *
;    *	CALL SYSDISPMSG 		     *
;    *	IF <> X.X then			     *
;    *	   Display message		     *
;    *	   Message number 1		     *
;    *	   (001 - Incorrect DOS Version)     *
;    *	   exit 			     *
;    *	.ENDIF				     *
;    *	   Continue			     *
;    *					     *
;    *	   Establish address of the	     *
;    *	   PDB environment		     *
;    *	   (Process Data Block )	     *
;    *	   .IF NO SPACE free de-allocate (49)*
;    *	       memory  at the environment    *
;    *	       address			     *
;    *	   .ENDIF			     *
;    *****************************************
;*******************************************************************************


	BREAK	<INITIALIZATION - NOT STAY RESIDENT>

	EXTRN	SYSPARSE:NEAR			;AN000;

ODDX			equ	01H		;AN000;
EVENX			equ	00H		;AN000;
PAD_CHAR		equ	' '		;AN000;
SEMICOLON		equ	';'		;AN000;
SPACE			equ	' '		;AN000;
EQUAL			equ	'='		;AN000;
PLUS			equ	'+'		;AN000;
good_parse_finish	equ	0ffffh		;an000;
;******************************************************************************
STATUS_ONLY	db	0			;AN000;
STRING_CTR	db	0			;AN000;
STATUS_FLAG	db	0			;AN000;
ERR_CODE	db	0			;AN000;
POS_FLAG	db	'n'			;AN000;
PARMS_AVAIL	db	'n'			;AN000;
PAR_RETC	dw	0			;AN000; used for the return code
DRV_X		db	0			;AN000; from the parser
save_dr_tbl_ptr dw	?			;an000;drive table pointer
curr_es_seg	dw	?
Parm_Ptr1	dw	?			;an002;ptr to parse parm
Parm_Ptr2	dw	?			;an002;ptr to parse parm

inv		dd	?
STring		dd	?			;AN000;string holder


INCLUDE ASSGPARM.INC				;AN000;
INCLUDE ASSGMSG.INC				;AN000;


assume	cs:code, ds:code, ss:code, es:code

INITIALIZATION:

	push	ax				;an000; save ax
	mov	ax,ds				;an000; get the current ds
	mov	SEG_1,ax			;an000; set sublist table
	mov	SEG_2,ax			;an000; set sublist table
	pop	ax				;an000; restore ax

	call	SYSLOADMSG			;AN000; ;does DOS version check
;	$IF	C				;AN000;
	JNC $$IF41
						;remainder of info given
	    call    SYSDISPMSG			;AN000; ;by the msg retriever
							;message and exit

	    call    EXIT_PROG			;AC000; ;(4CH) Terminate function

;	$ENDIF
$$IF41:


page
;************************************* CNS ************************************
;    *****************************************
;    *		 INITIALIZATION 	     *
;    *****************************************
;    *					     *
;    *	Make internal DOS function call (52h)*
;    *	to process the data block	     *
;    *	information after mem is available   *
;    ******************************************
;************************************* CNS ************************************
					;OKDOS:
	mov	ax,ds:[pdb_environ]	;get your Process Data Block Address
	or	ax,ax			;check to see if space available
;	$IF	NZ			;AC000;
	JZ $$IF43
					;    jz    nofree
	    push    es			; save code segment value
	    mov     es,ax		; de-allocate memory
	    mov     ah,dealloc		;(49H)
	    int     DOS_CALL

	    pop     es			;restore code segment value

;	$ENDIF				;ACx00;
$$IF43:
					;nofree:

	push	es			;an000; save es
	mov	ah,Get_In_Vars		;(52H)
	int	DOS_CALL

	mov	Word ptr inv,bx
	mov	Word ptr inv+2,es
	pop	es			;an000; restore es

;******************************************************************************
;
;    *****************************************
;    *	    Establish addressability	     *
;    *	    to command line parms (DS:SI)    *
;    *	    Establish addressability to PARM *
;    *	    control block	  (ES:DI)    *
;    *					     *
;    *****************************************
;*******************************************************************************
					;parser es & ds now points at the command line
	cld				;clear the directional flag
					;decrement mode - maintanis pointer without
					;advancement

	mov	di,offset ASS_PARMS	;AC000; ;set index to the location of your PARAMETER
					;PARSER control block
	mov	si,81h			;AC000; ;set index to the beginning of the commandline
					;at 81h to the first 128 bytes
page
;******************************************************************************
;*	     PROCESS PATH
;******************************************************************************
;*********************************************
;*					     *
;*  Subroutine : Process_path		     *
;*  Function   : Process command line.	     *
;*		 Repeat searching for drive  *
;*		 spec. If valid update	     *
;*		 drive table.		     *
;*					     *
;*   Normal exit: End of line		     *
;*		  Parse error		     *
;*					     *
;*   Abort exit:  Invalid drive 	     *
;*					     *
;*********************************************
;    *****************************************
;    *					     *
;    *	WHILE PAR_RETC	eq NO_ERROR (0)      *
;    *	   CALL SYSPARSE		     *
;    *	   Case:			     *
;    *	    .IF (POSITIONAL)		     *
;    *	     Result is positional & Ctr even *
;    *	     INC CTR			     *
;    *	     CHECK_STRING		     *
;    *	      .IF the string is valid	     *
;    *		 valid drive		     *
;    *		 calculate table drv posit.  *
;    *		 based on the ascii value    *
;    *	       .ELSE			     *
;    *					     *
;    *		 PARSE ERROR		     *
;    *	       .ENDIF			     *
;    *	      Result is positional & CTR odd *
;    *	      save the ascii_value	     *
;    *	      Check the String		     *
;    *	      .IF the string is valid	     *
;    *		 valid drive		     *
;    *		 update the drive table      *
;    *	       .ELSE			     *
;    *					     *
;    *		 PARSE ERROR		     *
;    *	       .ENDIF			     *
;    *	     .ENDIF			     *
;    *	     INC CTR			     *
;    *****************************************

;******************************************************************************
	xor	cx,cx			;an000;  set cx to 0 for parse
	xor	dx,dx			;an000; set dx to 0 for parse

	mov	Parm_Ptr1,si		;an002; dms;ptr to 1st. parm
	mov	Parm_Ptr2,si		;an002; dms;ptr to 1st. parm
	call	SYSPARSE		;AN000; dms;priming parse
	mov	par_retc,ax		;AN000; dms;set flag

;	$DO
$$DO45:
	    CMP     ax,no_error 	;AN000;Is compare the return
;	$LEAVE	NE			;AN000;code 0 no error keep
	JNE $$EN45
					;AN000;parsing
	    call    CHK_PARSER		;AN000;

	    mov     Parm_Ptr2,si	;an002; dms;ptr to 1st. parm
	    call    SYSPARSE		;AN000;go parse the command line
	    mov     par_retc,ax 	;AN000; dms;set flag
					;AN000;restore the parm return code

;	$ENDDO				;AN000;
	JMP SHORT $$DO45
$$EN45:

	cmp	ax,good_parse_finish	;an000; dms;see if a parse error
;	$if	ne			;an000; dms;if a parse error
	JE $$IF48
		push	ax		;an002; dms save ax
		mov	ax,Parm_Ptr2	;an002; dms;get original parm ptr
		mov	Parm_Ptr1,ax	;an002; dms;place in variable
		pop	ax		;an002; dms;restore ax
		call	PARSE_ERR	;an000; dms;display error & exit
;	$endif				;an000; dms;
$$IF48:

	cmp	PARMS_AVAIL,'y' 	;AN000;
;	$IF	E			;AN000; If there are parms available
	JNE $$IF50
	    cmp     ax,0		;AN000; see if the return code was no error
;	    $IF     G			;AN000; if greater than 0
	    JNG $$IF51
		mov	ax,parse10
		call	PARSE_ERR	;AN000; you got a parser error
					;AN000; so report & exit
;	    $ENDIF			;AN000; you also get an error
$$IF51:

	    xor     ax,ax		;AN000;
	    mov     al,String_ctr	;AN000;
	    mov     bx,0002h
	    div     bl			;AN000;

	    cmp     ah,EVENX
;	    $IF     NE			;AN000; if the drives did not pair off
	    JE $$IF53
		mov	ax,parse10
		call	PARSE_ERR
;	    $ENDIF			;AN000;
$$IF53:

	    cmp     POS_FLAG,'n'	;AN000;has a drive been specified
;	    $IF     E,AND		;AN000;and has a switch also been
	    JNE $$IF55
	    cmp     STATUS_FLAG,1	;AN000;specified if so hook in code
;	    $IF     E			;AN000;and then report status
	    JNE $$IF55
		mov	STATUS_ONLY,1	;AN000;set flag specifing user input full
;	    $ENDIF			;AN000;command line
$$IF55:
					;AN000; hook in the code
;	$ENDIF				;AN000;
$$IF50:

page

	cmp	STATUS_ONLY,0		;AN000;
;	$IF	E			;AN000;
	JNE $$IF58

		call	Get_Vectors	;get current vectors			;an001; dms;
		call	Set_Vectors	;set new vectors			;an001; dms;

;	$ELSE				;AN000;END of HOOK-IN
	JMP SHORT $$EN58
$$IF58:

	    call    REPORT_STATUS	;AN000;
	    call    EXIT_PROG		;AN000;

;	$ENDIF
$$EN58:
page
;*********************************** CNS ***************************************
	RELOAD_CURDIR PROC    NEAR

;*****************************************************************************
;
; We have an interesting problem here.	What if the user is assigning away
; his current drive?  Here's the solution:
;
;   o	We get the current drive here.
;   o	We reload the mapping table.
;   o	We set the current drive.
;
	MOV	AH,Get_Default_Drive	;(19H)
	INT	DOS_CALL

	PUSH	AX			; save away the table

	MOV	AX,(MPLEX_ID SHL 8)+MPLEX_GET_SEG ;(0601H) Get the SEG of the installed ASSIGN
	INT	MULTIPLEXOR		;(2FH)	in ES

	mov	si,offset drives	;move in the new drive table
	mov	di,si
	mov	cx,26			; move a-z
	CLI
	rep	movsb			;
	STI

	POP	DX			; restore the old current drive
	MOV	AH,Set_Default_Drive	;(0EH)
	INT	DOS_CALL

	call	EXIT_PROG		;go_home:

	INT	PGM_TERM		;(20H) Exit SHOULD not return, but be safe

	ret

	RELOAD_CURDIR ENDP
;*********************************** CNS ***************************************
;Input: Parser control block
;Output: Result Parser control block
;Register usage: AX,BX,CX,DX,ES,DS,SI,DI
;
;
;*********************************** CNS ***************************************

	CHK_PARSER PROC    NEAR

	xor	cx,cx				;an000; clear out cx
	xor	ax,ax				;AN000; clear out ax
	mov	al,String_ctr			;AN000; grab current assign ctr
	mov	bx,0002h			;an000; set bx to 2
	div	bl				;AN000; divide so we get rem.
	cmp	RES_TYPE,2			;an000; check for 1st drive
;	$IF	E,AND				;AN000; drive letter?
	JNE $$IF61
	cmp	ah,EVENX			;AN000; and no remainder?
;	$IF	E				;AN000;
	JNE $$IF61
	    inc     STRING_CTR			;AN000; increment counter
	    mov     PARMS_AVAIL,'y'		;AN000; signal parms entered
	    push    ax				;AN000; save ax
	    mov     al,res_itag 		;AN000; grab parm entered
	    mov     drv_x,al			;AN000; save it for later use
	    call    drvchk			;AC000; check for valid drive
	    cbw 				;AC000; convert drive byte found to a word
	    mov     bx,offset drives-1		;AC000; get the drive table
	    add     bx,ax			;AC000; get the drive address
	    mov     save_dr_tbl_ptr,bx		;an000; save the drive table pointer
	    pop     ax				;an000; restore ax
;	$ENDIF					;AN000;
$$IF61:

	cmp	RES_TYPE,2			;AN000; check for 2nd drive
;	$IF	E,AND				;AN000; drive entered?
	JNE $$IF63
	cmp	ah,EVENX			;AN000; and not first?
;	$IF	NE				;AN000;
	JE $$IF63
	    inc     STRING_CTR			;AN000; increment counter
	    mov     PARMS_AVAIL,'y'		;AN000; signal parms entered
	    push    ax				;AN000; save ax
	    mov     al,res_itag 		;AN000; grab parm entered
	    mov     drv_x,al			;AN000; save it for later use
	    call    drvchk			;AC000; if so see if it was valid
	    mov     bx,save_dr_tbl_ptr		;an000; set bx to drive table
	    mov     [bx],al			;AC000; if valid update the table
	    mov     POS_FLAG,'y'		;AN000; yes you have valid positionals
	    pop     ax				;an000; restore ax
	    mov     Parm_Ptr1,si		;an002; dms;ptr to 1st. parm
;	$ENDIF					;AN000;
$$IF63:

	cmp	RES_SYN,0			;AN000; See if a switch was specified
;	$IF	NE				;AN000; If so,
	JE $$IF65
	    mov     STATUS_flag,1		;AN000; set the status flag on
	    mov     PARMS_AVAIL,'y'		;AN000; and report that a valid parameter
	    mov     byte ptr SW_Syn1,20h	;an000; remove switch from list
	    mov     byte ptr SW_Syn2,20h	;an000; remove switch from list
	    mov     Parm_Ptr1,si		;an002; dms;ptr to 1st. parm
;	$ENDIF					;AN000; was on the command line
$$IF65:

	ret					;AN000;


	CHK_PARSER ENDP

page
;*********************************** CNS ***************************************
;
; check drive validity
;
drvchk:

	sub	al,"A"			; NS- error checking
;	$IF	NB			;AN000; ;if alphabetic,
	JB $$IF67

	    push    es
	    push    bx
	    push    ax

	    les     bx,inv
	    cmp     al,es:[bx].sysi_ncds	;AN000; ;NS- check in case current directory
;	    $IF     NAE 			;AN000; ;NS- has been altered
	    JAE $$IF68


		les	bx,es:[bx].sysi_cds
		push	bx
		mov	bl,size curdir_list
		mul	bl
		pop	bx
		add	bx,ax
		test	es:[bx].curdir_flags,curdir_inuse
;		$IF	NZ			;AC000;
		JZ $$IF69

		    pop     ax
		    pop     bx
		    pop     es
		    inc     al

		    ret

;		$ENDIF				;AC000; curdir in use?
$$IF69:
;	    $ENDIF				;AC000; curdir been altered?
$$IF68:
;	$ENDIF					;AC000; alphabetic?
$$IF67:

	mov	ax,parse10			;AN000; Invalid parameter
	call	PARSE_ERR			;an000; display the error & end

;*******************************  CNS *******************************************
;Purpose: Print the mapping status of the drive table.
;Input	: Drive table
;Registers affected: BX,CX,DX,AX
;
;Output : Display of all drive values stored not equal to their sequential
;	  storage address
;
;*******************************  CNS *******************************************
REPORT_STATUS PROC NEAR

	push	es				;an000; save es
	push	es				;an000; swap es with
	pop	ax				;an000;     ax
	mov	curr_es_seg,ax			;an000; save es in curr_es_seg

	mov	ax,0601h			;an000; our int 2fh
	int	2fh				;an000; returns segment of drive vector
	assume	es:nothing			;an000; tell the linker

	mov	cl,01				;AN000; ;initialize the counter
						;AN000; advance to next drive
	mov	bx,offset drives		;AN000; load drive table
;	$DO
$$DO73:
	    cmp     cl,26			;AN000; see if we scanned all drives

;	$LEAVE	A				;AN000; exit loop if we have
	JA $$EN73

	    cmp     cl,es:[bx]			;AN000; ;compare the table value
							;to the table contents
;	    $IF     NE				;AN000;
	    JE $$IF75
		push	bx			;an000; save bx - we stomp it
		push	cx			;an000; save cx - we stomp it
		mov	al,es:[bx]		;AN000; get the table contents to convert
		push	es			;an000; save es for print
		mov	bx,curr_es_seg		;an000; get the current segment
		mov	es,bx			;an000; get the segment into es
		assume	es:code 		;an000; tell linker it is code

		add	cl,40H			;AN000; convert to ascii representation
		add	al,40h			;an000; convert to ascii
		mov	OLD_DRV,cl		;AN000; place in parms for printing
		mov	NEW_DRV,al		;AN000;     by message retriever

		mov	ax,0002h		;an000; message #2
		mov	bx,stdout		;an000; print to standard out
		mov	cx,0002h		;an000; two replaceable parms
		mov	si,offset sublist1	;an000; offset of sublist
		mov	di,0000h		;an000; no buffer for user input
		mov	dl,no_input		;AN000; no user input to mes. ret.
		mov	dh,utility_msg_class	;an000; utility messages only

		call	SYSDISPMSG		;AN000; ;go to message retriever
		pop	es			;an000; restore es
		assume	es:nothing		;an000; tell the linker
		pop	cx			;an000; restore cx
		pop	bx			;an000; restore bx

;	    $ENDIF				;AN000;
$$IF75:

	    inc     bx				;an000; next drive in vector
	    inc     cl				;AN000; next letter to address

;	$ENDDO					;AN000;
	JMP SHORT $$DO73
$$EN73:
	pop	es				;an000; restore es
	assume	es:code 			;an000; tell the linker

	ret					;AN000;

REPORT_STATUS ENDP
page
;*******************************  CNS *******************************************
; Purpose: Exit program
; Input  : Error code AL
; Output : Error code AL
;
;*******************************  CNS *******************************************
EXIT_PROG PROC	NEAR



	mov	ah,EXIT 		;AC000;(4ch) RETURN TO DOS WITH ERRORLEVEL
	int	DOS_CALL		;AC000;


	ret				;AC000;

EXIT_PROG ENDP
;*******************************  CNS *******************************************

;=========================================================================
; PARSE_ERR		: This routine prints out the applicable parse
;			  error that is returned in AX by SYSPARSE.
;
;	Inputs		: AX - Parse error number to be printed
;	Outputs 	: Applicable parse error
;=========================================================================


PARSE_ERR	proc	near		;an000; dms;report an error

	push	ax			;an000;save ax
	mov	byte ptr ds:[si],0	;an002;null terminate string
	mov	dx,Parm_Ptr1		;an002;move ptr to sublist
	mov	Parse_Sub_Off,dx	;an002;
	mov	Parse_Sub_Seg,ds	;an002;

	mov	bx,STDERR		;an000;print to standard out
	mov	cx,1			;an002;1 replaceable parm
	mov	si,offset Parse_Sublist ;an002;sublist for replaceable parm
	mov	dl,NO_INPUT		;AN000;no input to message retriever
	mov	dh,PARSE_ERR_CLASS	;AN000;display parse errors
	call	SYSDISPMSG		;AN000;display error

	pop	ax			;AN000;restore errcode
	call	EXIT_PROG		;AN000;exit ASSIGN due to error


PARSE_ERR	endp			;an000; dms;

Release_Environment	proc	near						;an001; dms;

	push	ax			;save regs				;an001; dms;
	push	bx			;					;an001; dms;
	push	es			;					;an001; dms;
	mov	ah,Get_PSP		; get the PSP segment			;an001; dms;
	int	21h			; invoke INT 21h			;an001; dms;
	mov	es,bx			; BX contains PSP segment - put in ES	;an001; dms;
	mov	bx,word ptr es:[PSP_Env]; get segment of environmental vector	;an001; dms;
	mov	es,bx			; place segment in ES for Free Memory	;an001; dms;
	mov	ah,Dealloc		; Free Allocated Memory 		;an001; dms;
	int	21h			; invoke INT 21h			;an001; dms;
	pop	es			; restore regs				;an001; dms;
	pop	bx			;					;an001; dms;
	pop	ax			;					;an001; dms;

	ret				; return to caller			;an001; dms;

Release_Environment	endp

Close_Handles		proc	near	;close handles 0-4			;an001; dms;

	push	bx			;save regs				;an001; dms;
	mov	bx,4			;close all standard files		;an001; dms;

Close_Handle_Loop:

	mov	ah,Handle_Close 	;close file handle			;an001; dms;
	int	21h			;					;an001; dms;
	dec	bx			;next handle				;an001; dms;
	jns	Close_Handle_Loop	;continue				;an001; dms;

	pop	bx			;restore regs				;an001; dms;
	ret				;					;an001; dms;

Close_Handles		endp		;					;an001; dms;

Get_Vectors		proc	near	;get original vectors			;an001; dms;

	    mov     ax,(GET_INTERRUPT_VECTOR SHL 8)+ABS_DISK_READ ;(3525h) get the int 25 vector
	    int     DOS_CALL

	    mov     word ptr [int25_vec],bx
	    mov     word ptr [int25_vec+2],es

	    mov     ax,(GET_INTERRUPT_VECTOR SHL 8)+ABS_DISK_WRITE ;(3526H) get the int 26 vector
	    int     DOS_CALL

	    mov     word ptr [int26_vec],bx
	    mov     word ptr [int26_vec+2],es

	    mov     ax,(GET_INTERRUPT_VECTOR SHL 8)+MULTIPLEXOR ;(352FH) get the int 2F vector
	    int     DOS_CALL

	    mov     word ptr [int2F_vec],bx
	    mov     word ptr [int2F_vec+2],es

	    mov     ax,(Get_Interrupt_Vector SHL 8)+DOS_CALL ;(3521H)
	    int     DOS_CALL

	    mov     word ptr cs:[system],bx
	    mov     word ptr cs:[system+2],es

	    MOV     AX,(MPLEX_ID SHL 8)+MPLEX_R_U_THERE ;(0600H) See if we are in system already
	    INT     MULTIPLEXOR 	;(2FH)

	    OR	    AL,AL
;	    $IF     NZ			;AC000; NOT INSTALLED
	    JZ $$IF78

		call	RELOAD_CURDIR	;AC000;

;	    $ENDIF
$$IF78:

	ret				;					;an001; dms;

Get_Vectors		endp		;					;an001; dms;


Set_Vectors		proc	near	;set to new vectors			;an001; dms;

	    mov     ah,Get_Default_Drive ;(19H)
	    int     DOS_CALL

	    inc     al
	    mov     [default_drive],al	;NS- add one to the value to get the
	    call    mapdrv1		;NS- actual drive value before mapping

	    dec     al			;NS- dec one to setup for select function
	    mov     dl,al		;select its replacement
	    mov     ah,Set_Default_Drive ;(0EH)
	    int     DOS_CALL
					;NS- Set up hooks
	    mov     dx,offset int25	;set int 25 vector
	    mov     ax,(SET_INTERRUPT_VECTOR SHL 8) + ABS_DISK_READ ;(2525H)
	    int     DOS_CALL
					;NS- setup new seg
	    mov     dx,offset int26	;set int 26 vector
	    mov     ax,(SET_INTERRUPT_VECTOR SHL 8) + ABS_DISK_WRITE ;(2526H)
	    int     DOS_CALL
					;NS- Hook in resident portion
	    mov     dx,offset int2F	;set int 2F vector
	    mov     ax,(SET_INTERRUPT_VECTOR SHL 8) + MULTIPLEXOR ;(252FH)
	    int     DOS_CALL

	    mov     dx,offset ASSIGN_HANDLER ;set the system int vector
	    mov     ax,(SET_INTERRUPT_VECTOR SHL 8) + DOS_CALL ;(2521H)
	    int     DOS_CALL

	    call    Close_Handles	;close handles 0-4			;an001; dms;
	    call    Release_Environment ;release the environmental vector	;an001; dms;

	    mov     dx,prog_size	;end but stay resident
	    mov     ah,KEEP_PROCESS	;(31h) NS- ASSIGN loaded in mem
	    int     DOS_CALL

	ret				;					;an001; dms;

Set_Vectors		endp		;					;an001; dms;



.xlist
MSG_SERVICES <MSGDATA>
msg_services <NEARmsg>
msg_services <LOADmsg>
msg_services <DISPLAYmsg,CHARmsg>
msg_services <assign.cla,assign.cl1>
msg_services <assign.cl2>
.list

include msgdcl.inc

code	ends
	end	ENTRY_POINT
