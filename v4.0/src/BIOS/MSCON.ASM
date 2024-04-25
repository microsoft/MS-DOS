	PAGE ,132 ;
	TITLE MSCON - BIOS
	%OUT	...MSCON.ASM
;==============================================================================
;REVISION HISTORY:
;AN000 - New for DOS Version 4.00 - J.K.
;AC000 - Changed for DOS Version 4.00 - J.K.
;AN00x - PTM number for DOS Version 4.00 - J.K.
;==============================================================================

	itest=0
	INCLUDE MSGROUP.INC	;DEFINE CODE SEGMENT
	INCLUDE JUMPMAC.INC
	INCLUDE MSEQU.INC
	INCLUDE MSMACRO.INC

;*** DOS 3.3 will not support more than 25 rows
;	INCLUDE DEVSYM.INC	;J.K. 4/29/86 for CON$GENIOCTL support
;	INCLUDE IOCTL.INC	;J.K. 4/29/86 for CON$GENIOCTL support

	EXTRN EXIT:NEAR 	;MSBIO1
	EXTRN BUS$EXIT:NEAR	;MSBIO1

;	EXTRN CMDERR:NEAR	;MSBIO1	J.K. 4/29/86

;DATA
	EXTRN PTRSAV:DWORD	;MSBIO1
	EXTRN FHAVEK09:BYTE	;MSDISK
	EXTRN ALTAH:BYTE	;MSBDATA
	EXTRN KEYRD_Func:Byte	;MSBDATA
	EXTRN KEYSTS_Func:Byte	;MSBDATA

;	EXTRN SAV_SC_INFO:BYTE	;MSBDATA J.K. 4/29/86
;	EXTRN SAV_SC_MODE:BYTE	;MSBDATA J.K. 4/29/86
;------------------------------------------------------
;
;	CONSOLE READ ROUTINE
;
	ASSUME DS:CODE		     ; THIS WAS SET BY THE CON DD ENTRY POINT
	PUBLIC	CON$READ
CON$READ PROC	NEAR
	JCXZ	CON$EXIT
CON$LOOP:
	CALL	CHRIN			;GET CHAR IN AL
	STOSB				;STORE CHAR AT ES:DI
	LOOP	CON$LOOP
CON$EXIT:
	JUMP	EXIT
CON$READ ENDP
;---------------------------------------------------------
;
;	INPUT SINGLE CHAR INTO AL
;
;J.K.5/12/87 We are going to issue extended keyboard function, if supported.
;The returning value of the extended key stroke of the extended key board
;function uses 0E0h in AL instead of 00 as in the conventional key board
;function.  This creates a conflict when the user entered real Greek Alpha
;charater (= 0E0h) to  distinguish the extended key stroke and the Greek Alpha.
;This case will be handled in the following manner;
;	AH = 16h
;	INT 16h
;	If AL == 0, then extended code (in AH)
;  else If AL == 0E0h, then
;	     IF AH <> 0, then extended code (in AH)
;	else Greek_Alpha character.
;Also, for compatibility reason, if an extended code is detected, then we
;are going to change the value in AL from 0E0h to 00h.


CHRIN	PROC	NEAR
;AN000;
;	 XOR	 AX,AX
	mov	ah,KEYRD_Func		;AN000; Set by MSINIT. 0 or 10h
	xor	al,al			;AN000;
	XCHG	AL,ALTAH		;GET CHARACTER & ZERO ALTAH

	OR	AL,AL
	JNZ	KEYRET
;SB34CON000**************************************************************
;SB  Keyboard I/O interrupt
;SB	AH already contains the keyboard read function number
;SB		1 LOC

	int	16h
;SB34CON000**************************************************************
ALT10:
	OR	AX,AX			;CHECK FOR NON-KEY AFTER BREAK
	JZ	CHRIN
	CMP	AX,7200H		;CHECK FOR CTRL-PRTSC
	JNZ	ALT_Ext_Chk		;AN000;
	MOV	AL,16
	jmp	KeyRet			;AN000;
ALT_Ext_Chk:
;SB34CON001**************************************************************
;SB  IF operation was extended function (i.e. KEYRD_Func != 0) THEN
;SB    IF character read was 0E0h THEN
;SB      IF extended byte was zero (i.e. AH == 0) THEN
;SB        goto keyret
;SB      ELSE
;SB        set AL to zero
;SB        goto ALT_SAVE
;SB      ENDIF
;SB    ENDIF
;SB  ENDIF
;SB		9 LOCS

	cmp	BYTE PTR KEYRD_Func,0
	jz	NOT_EXT
	cmp	al,0E0h
	jnz	NOT_EXT
	or	ah,ah
	jz	KEYRET
	xor	al,al
	jmp	short ALT_SAVE
NOT_EXT:

;SB34CON001**************************************************************
	OR	AL,AL			;SPECIAL CASE?
	JNZ	KEYRET
ALT_SAVE:
	MOV	ALTAH,AH		;STORE SPECIAL KEY
KEYRET:
	RET
CHRIN	ENDP

;--------------------------------------------------------------
;
;	KEYBOARD NON DESTRUCTIVE READ, NO WAIT
;
; PC-CONVERTIBLE-TYPE MACHINE: IF BIT 10 IS SET BY THE DOS IN THE STATUS WORD 
; OF THE REQUEST PACKET, AND THERE IS NO CHARACTER IN THE INPUT BUFFER, THE 
; DRIVER ISSUES A SYSTEM WAIT REQUEST TO THE ROM. ON RETURN FROM THE ROM, IT
; RETURNS A 'CHAR-NOT-FOUND' TO THE DOS.
;
CONBUSJ:
	ASSUME	DS:NOTHING
	JMP	CONBUS

	ASSUME DS:CODE		     ; THIS WAS SET BY THE CON DD ENTRY POINT
	PUBLIC	CON$RDND
CON$RDND:
	MOV	AL,[ALTAH]
	OR	AL,AL
	JZ	RD1
	JMP	RDEXIT

RD1:
;SB34CON002**************************************************************
;SB  Keyboard I/O interrupt
;SB	Get keystroke status (KEYSTS_Func)
;SB	 2 LOCS

	mov	ah,KEYSTS_Func
	int	16h
;SB34CON002**************************************************************
	JZ	NOCHR
	JMP	GOTCHR
NOCHR:
	CMP	FHAVEK09,0
	JZ	CONBUSJ
	LDS	BX,[PTRSAV]
	ASSUME	DS:NOTHING
	TEST	[BX].STATUS,0400H	; SYSTEM WAIT ENABLED?
	JZ	CONBUSJ

;********************************
; NEED TO WAIT FOR IBM RESPONSE TO REQUEST FOR CODE ON HOW TO USE THE SYSTEM
; WAIT CALL.
;********************************
	MESSAGE FTESTCON,<"SYSTEM WAIT STAGE",CR,LF>
	MOV	AX,4100H		; WAIT ON AN EXTERNAL EVENT
;	MOV	BX,0300H		; NO TIMEOUT
;	MOV	DX,60H			; LOOK AT I/O PORT 60H
	INT	15H			; CALL ROM FOR SYSTEM WAIT
	MESSAGE FTESTCON,<"OUT OF WAIT. AX IS ">
	MNUM	FTESTCON,AX
	MESSAGE FTESTCON,<CR,LF>
	JMP	CONBUS

	ASSUME	DS:CODE
GOTCHR:
	OR	AX,AX
	JNZ	NOTBRK			;CHECK FOR NULL AFTER BREAK
;SB34CON004**************************************************************
;SB  Keyboard I/O interrupt
;SB	Keyboard read function (KEYRD_Func)
;SB		2 LOCS

	mov	ah,KEYRD_Func
	int	16h
;SB34CON004**************************************************************
	JUMP	CON$RDND		;AND GET A REAL STATUS
NOTBRK:
	CMP	AX,7200H		;CHECK FOR CTRL-PRTSC
	JNZ	RD_Ext_Chk		;AN000;
	MOV	AL,16
	jmp	RDEXIT			;AN000;
RD_Ext_Chk:				;AN000;
	cmp	KEYRD_Func, 0		;AN000; Extended Keyboard function?
	jz	RDEXIT			;AN000; No. Normal exit.
	cmp	al,0E0h 		;AN000; Extended key value or Greek Alpha?
	jne	RDEXIT			;AN000;
	cmp	ah, 0			;AN000; Scan code exist?
	jz	RDEXIT			;AN000; Yes. Greek Alpha char.
	mov	al, 0			;AN000; No. Extended key stroke. Change it for compatibility
	PUBLIC	RDEXIT
RDEXIT:
	LDS	BX,[PTRSAV]
	ASSUME	DS:NOTHING
	MOV	[BX].MEDIA,AL
EXVEC:
	JUMP	EXIT

CONBUS:
	ASSUME	DS:NOTHING
	JUMP	BUS$EXIT
;--------------------------------------------------------------
;
;	KEYBOARD FLUSH ROUTINE
;
	ASSUME DS:CODE		     ; THIS WAS SET BY THE CON DD ENTRY POINT
	PUBLIC	CON$FLSH
CON$FLSH:
	CALL	FLUSH
	JUMP	EXIT

	PUBLIC	FLUSH
FLUSH:
	MOV	[ALTAH],0		;CLEAR OUT HOLDING BUFFER

FLLOOP:
;SB33012****************************************************************
			 ;SB	; Is there a char there?
	mov	AH, 1	 ;SB	; command code for check status
	int	16h	 ;SB	; call rom-bios keyboard routine
;SB33012****************************************************************
	JZ	FLDONE
;SB33013****************************************************************
	xor	AH, AH	 ;SB	; if zf is nof set, get character
	int	16h	 ;SB	; call rom-bios to get character
;SB33013****************************************************************
	JMP	FLLOOP
FLDONE:

	RET
;----------------------------------------------------------
;
;	CONSOLE WRITE ROUTINE
;
	ASSUME DS:CODE		     ; THIS WAS SET BY THE CON DD ENTRY POINT
	PUBLIC	CON$WRIT
CON$WRIT:
	JCXZ	EXVEC
CON$LP:
	MOV	AL,ES:[DI]		;GET CHAR
	INC	DI
	INT	CHROUT			;OUTPUT CHAR
	LOOP	CON$LP			;REPEAT UNTIL ALL THROUGH
	JUMP	EXIT
;-----------------------------------------------
;
;	BREAK KEY HANDLING
;
	PUBLIC CBREAK
CBREAK:
	MOV	CS:ALTAH,3		;INDICATE BREAK KEY SET

	PUBLIC INTRET
INTRET:
	IRET

;------------------------------------------------------------------------------
;J.K. 4/29/86 - CONSOLE GENERIC IOCTL SUPPORT FOR DOS 3.3.
;CON$GENIOCTL supports Get mode information, Set mode information functions.
;It will only save the value from "Set mode information" and will return
;the value through "Get mode information".  It is supposed to be set by
;the MODE.COM and other application program can retrieve information
;through "Get mode information" call.
;Initially, there is no valuable informaton until set by MODE command, so
;any attemp to "Get mode information" at that points will fail. (unknown
;command with carry set.)
;At entry:  CS = DS = code
;	    CS:[PTRSAV] has seg, address of the Request Header saved in
;	    in Strategy routine.
;
;	PUBLIC	CON$GENIOCTL
;	ASSUME	DS:CODE
;CON$GENIOCTL:
;	 les	 di, CS:[PTRSAV]		 ;get the request header
;	 cmp	 es:[di].MajorFunction, IOC_SC
;	 je	 Major_SC_OK
;SC_CMDERR:
;	 stc
;	 jmp	 cmderr 			 ;carry is set, exit to cmderr
;Major_SC_OK:
;	 mov	 al, es:[di].MinorFunction	 ;save minor function
;	 les	 di, es:[di].GenericIOCTL_Packet ;pointer of SC_MODE_INFO structure
;	 mov	 cx, es:[di].SC_INFO_LENGTH	 ;save length
;	 inc	 di
;	 inc	 di				 ;ES:DI -> SC_MODE in Info. Packet
;	 cmp	 cx, SC_INFO_PACKET_LENGTH	 ;currently 9.
;	 jne	 SC_CMDERR			 ;cannot accept the different packet
;	 cmp	 al, GET_SC_MODE		 ;minor function = 60h ?
;	 jne	 SC_SET_MODE_FUNC		 ;no, check if it is "Set mode function"
;	 cmp	 SAV_SC_MODE, 0 		 ;information set before?
;	 je	 SC_CMDERR			 ;no, cannot get the info.
;;SC_GET_MODE_FUNC:				 ;es:di -> SC_MODE in info. packet
;						 ;cx - length
;	 mov	 si, offset SAV_SC_INFO
;	 rep	 movsb		 ;ds:si -> sav_sc_info, es:di -> sc_mode
;	 jmp	 exit
;
;SC_SET_MODE_FUNC:				 ;es:di -> SC_MODE
;	 cmp	 al, SET_SC_MODE		 ;minor function = 40h ?
;	 jne	 SC_CMDERR
;	 mov	 si, offset SAV_SC_INFO
;	 xchg	 di, si
;	 push	 es
;	 push	 ds
;	 pop	 es
;	 pop	 ds
;	 rep	 movsb		 ;ds:si -> sc_mode, es:di -> sav_sc_info
;	 jmp	 exit
;
;J.K. 4/29/86 - End of CONSOLE GENERIC IOCTL SUPPORT FOR DOS 3.3.

CODE	ENDS
	END
