	PAGE	,132
	TITLE	DOS - KEYB Command  -  Transient Command Processing

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  COMMSUBS.ASM
;; ----------
;;
;; Description:
;; ------------
;;	 Common subroutines used by NLS support
;;
;; Documentation Reference:
;; ------------------------
;;	 None
;;
;; Procedures Contained in This File:
;; ----------------------------------
;;
;;	 FIND_HW_TYPE - Determine the keyboard and system unit types and
;;	       set the corresponding flags.
;;
;; Include Files Required:
;; -----------------------
;;	 None
;;
;; External Procedure References:
;; ------------------------------
;;	 FROM FILE  ????????.ASM:
;;	      ????????? - ????????????????????????????????????????????
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
	PUBLIC FIND_SYS_TYPE	       ;;
	PUBLIC FIND_KEYB_TYPE	       ;;
	PUBLIC HW_TYPE		       ;;
	PUBLIC SECURE_FL	       ;;

				       ;;
	INCLUDE KEYBEQU.INC	       ;;
	INCLUDE KEYBCPSD.INC	       ;;
	INCLUDE KEYBSHAR.INC	       ;;
	INCLUDE KEYBCMD.INC	       ;;
	INCLUDE DSEG.INC	       ;;
	INCLUDE POSTEQU.INC	       ;;
				       ;;
CODE	SEGMENT PUBLIC 'CODE'          ;;
				       ;;
	ASSUME	CS:CODE,DS:CODE        ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: FIND_SYS_TYPE
;;
;; Description:
;;     Determine the type of system we are running on.
;;     SYSTEM_FLAG (in active SHARED_DATA) are set to
;;     indicate the system type.
;;     This routine is only called the first time KEYB is being installed.
;;
;;
;; Input Registers:
;;     DS - points to our data segment
;;
;; Output Registers:
;;     NONE
;;
;; Logic:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					       ;;
ROM	   SEGMENT AT 0F000H		       ;;
		ORG	0FFFEH		       ;;
ROMID		DB	?		       ;;
					       ;; SEGMENT F000. (F000:FFFE)
					       ;;
ROMPC1		EQU	0FFH		       ;; ID OF PC1 hardware
ROMXT		EQU	0FEH		       ;; ID OF PC-XT/PORTABLE hardware
ROMJR		EQU	0FDH		       ;; ID OF PCjr & Optional ROM
ROMAT		EQU	0FCH		       ;; ID OF PCAT
ROMXT_ENHAN	EQU	0FBH		       ;; ID OF ENHANCED PCXT
ROMPAL		EQU	0FAH		       ;; ID FOR PALACE
ROMLAP		EQU	0F9H		       ;; ID FOR PC LAP (P-14)
ROM_RU_386	EQU	0F8H		       ;; ID FOR ROUNDUP-386
					       ;;
ROM	   ENDS 			       ;;
					       ;;
					       ;; ******** CNS
 ROMEXT     SEGMENT AT 00000H		       ;; ADDRESS SHOULD NOT BE FIXED AT
		 ORG	 0003BH 		;;AT 09FC0H -- This is just a ;;
 KEYBID1	 DB	 ?			;;a dummy value of 000H INT 15H call
					       ;; will load dynamically depending
					       ;; upon system mem size- 9FC0 was only for 640K system
					       ;; *** UNTRUE SEGMENT 9FC0. (9FC0:003B)
 ROMEXT     ENDS				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;***CNS








;;  Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
FIND_SYS_TYPE	       PROC  NEAR      ;;
				       ;;
	MOV	AX,ROM		       ;; Set segmant to look at ROM
	MOV	DS,AX		       ;;    using the data segment
	ASSUME	DS:ROM		       ;;
				       ;;
	MOV	AL,ROMID	       ;; Get hardware ID
	PUSH	AX		       ;; save it
				       ;;
	PUSH	CS		       ;; Set data seg back to code
	POP	DS		       ;;
	ASSUME	DS:CODE 	       ;;
				       ;;
	MOV	AH,92H		       ;; SET INVALID CALL FOR INT16
	INT	16H		       ;; CALL BIOS
	CMP	AH,80H		       ;; IS EXTENDED INTERFACE THERE?
	JA	CHECK_PC_NET	       ;;  NO, SKIP FLAG
	OR	SD.SYSTEM_FLAG,EXT_16  ;; default is extended INT 16 support
				       ;;
CHECK_PC_NET:			       ;;
	MOV	AH,30H		       ;; GET DOS VERSION NUMBER
	INT	21H		       ;; MAJOR # IN AL, MINOR # IN AH
	CMP	AX,0A03H	       ;; SENSITIVE TO 3.10 OR >
	JB	CHECK_SYSTEM	       ;; EARLIER VERSION OF DOS NOTHING
				       ;; WAS ESTABLISHED FOR THIS SITUATION
	PUSH	ES		       ;; Save ES just in case
	MOV	AX,3509H	       ;; GET INT VECTOR 9 CONTENTS
	INT	21H		       ;; ES:BX WILL = CURRENT INT9 VECTOR
				       ;; WE WANT TO SEE IF WE ARE THE 1ST ONES LOADED
	MOV	CX,ES		       ;; INTO THE INT VECTOR 9. WITH DOS 3.1 WE CAN
	POP	ES		       ;;
	CMP	CX,0F000H	       ;; HANDSHAKE WITH THE PC NETWORK BUT NO ONE ELSE
	JE	CHECK_SYSTEM	       ;; INT VECTOR 9 POINTS TO ROM, OK
	MOV	AX,0B800H	       ;; ASK IF PC NETWORK IS INSTALLED
	INT	2FH		       ;;
	CMP	AL,0		       ;; NOT INSTALLED IF AL=0
	JE	CHECK_SYSTEM	       ;; SOMEBODY ELSE HAS LINKED INTO THE INT VECTOR
				       ;; 9 & I'M GOING TO DROP RIGHT IN AS USUAL
	OR	SD.SYSTEM_FLAG,PC_NET  ;; INDICATE PC NET IS RUNNING
				       ;;
CHECK_SYSTEM:			       ;;
	POP	AX		       ;; get code back
				       ;; Is the hardware a PCjr
	CMP   AL,ROMJR		       ;;
	JNE   TEST_PC_XT	       ;; IF not then check for next type
	OR    SD.SYSTEM_FLAG,PC_JR     ;; system type
	JMP   FIND_SYS_END	       ;; Done
				       ;;
TEST_PC_XT:			       ;;
				       ;; Is the hardware a PC1 or XT ?
	CMP   AL,ROMXT		       ;;
	JAE   ITS_AN_XT 	       ;; IF FE OR FF THEN ITS AN XT
	CMP   AL,ROMXT_ENHAN	       ;; IF FB IT IS ALSO AN XT
	JNE   TEST_PC_AT	       ;; IF not then check for next type
ITS_AN_XT:			       ;;
	OR    SD.SYSTEM_FLAG,PC_XT     ;; system type
	JMP   FIND_SYS_END	       ;;
				       ;;
TEST_PC_AT:			       ;;
				       ;; Is the hardware an AT ?
	CMP   AL,ROMAT		       ;;
	JNE   TEST_P12		       ;; IF not then check for next type
				       ;;
	OR    SD.SYSTEM_FLAG,PC_AT     ;; system type
				       ;;
	JMP   FIND_SYS_END	       ;;
				       ;;
TEST_P12:			       ;;
	CMP   AL,ROMLAP 	       ;; IS this a P12?
	JNE   TEST_PAL		       ;; IF not then check for next type
	OR    SD.SYSTEM_FLAG,PC_LAP    ;; system type
	JMP   FIND_SYS_END	       ;;
				       ;;
TEST_PAL:			       ;;
	CMP   AL,ROMPAL 	       ;; IS this a PALACE?
	JNE   TEST_RU_386	       ;; IF not then check for next type
	OR    SD.SYSTEM_FLAG,PC_PAL    ;; system type
	JMP   FIND_SYS_END	       ;;
				       ;;
TEST_RU_386:			       ;;
	CMP   AL,ROM_RU_386	       ;; IS this a ROUNDUP with a 386?
	JNE   FIND_SYS_END	       ;; IF not then check for next type
	OR    SD.SYSTEM_FLAG,PC_386    ;; system type
	MOV   SD.TIMING_FACTOR,2       ;; Bump scale factor to account for 386
				       ;;
FIND_SYS_END:			       ;;
				       ;;
	RET			       ;;
				       ;;
FIND_SYS_TYPE	    ENDP	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: FIND_KEYB_TYPE
;;
;; Description:
;;     Determine the type of keyboard we are running on.
;;     KEYB_TYPE (in SHARED_DATA) is set to
;;     indicate the keyboard type.
;;     This routine is only called the first time KEYB is being installed.
;;
;;
;; Input Registers:
;;     DS - points to our data segment
;;
;; Output Registers:
;;     NONE
;;
;; Logic:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					       ;;
HW_TYPE 	DW	0		       ;;
;***CNS 				       ;;

SECURE_FL	DB	0
;RESERVED ADDRESS 013h BITS 1 & 2

	PASS_MODE	equ		00000001B   ;AN000;
	SERVER_MODE	equ		00000010B   ;AN000;
	SECRET_ADD	equ		13h    ;AN000;
	PORT_70 	equ		70h    ;AN000;
	PORT_71 	equ		71h    ;AN000;

;***CNS
G_KEYBOARD	EQU	0AB41h	     ;;?????   ;; Keyboard ID for FERRARI_G
P_KEYBOARD	EQU	0AB54h	     ;;?????   ;; Keyboard ID for FERRARI_P
					       ;;
P_KB_ID 	DB	08		       ;;
					       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
FIND_KEYB_TYPE	      PROC  NEAR       ;;
				       ;;
	PUSH	ES		       ;;
	PUSH	DS		       ;;
				       ;;
	MOV	AX,ROM		       ;; Set segmant to look at ROM
	MOV	DS,AX		       ;;    using the data segment
	ASSUME	DS:ROM		       ;;
				       ;;
	MOV	AX,DATA 	       ;;
	MOV	ES,AX		       ;; ES points to BIOS data
				       ;;
	MOV	AL,ROMID	       ;; Get hardware ID
				       ;;
	PUSH	CS		       ;; Set data seg back to code
	POP	DS		       ;;
	ASSUME	DS:CODE 	       ;;
				       ;;
				       ;;
	MOV   HW_TYPE,G_KB	       ;; Default keyboard is G_KB
				       ;;
				       ;; Is the hardware a PCjr
	CMP   AL,ROMJR		       ;;
	JNE   TEST_PC_XT_2	       ;; IF not then check for next type
	MOV   HW_TYPE,JR_KB	       ;; keyboard type
	JMP   FIND_KEYB_END	       ;; Done
				       ;;
TEST_PC_XT_2:			       ;;
				       ;; Is the hardware a PC1 or XT ?
	CMP   AL,ROMXT		       ;;
	JAE   ITS_AN_XT_2	       ;; IF FE OR FF THEN ITS AN XT
	CMP   AL,ROMXT_ENHAN	       ;; IF FB IT IS ALSO AN XT
	JNE   TEST_PC_AT_2	       ;; IF not then check for next type
ITS_AN_XT_2:			       ;;
	TEST  ES:KB_FLAG_3,KBX	       ;; IS THE ENHANCED KEYBOARD INSTALLED?
	JZ    ITS_AN_XT_3	       ;;
	JMP   FIND_KEYB_END	       ;; Yes, exit
				       ;;
ITS_AN_XT_3:			       ;;
	MOV   HW_TYPE,XT_KB	       ;; NO, normal XT keyboard
	JMP   FIND_KEYB_END	       ;;
				       ;;
TEST_PC_AT_2:			       ;;
				       ;; Is the hardware an AT ?
	CMP   AL,ROMAT		       ;;
	JNE   TEST_P12_2	       ;; IF not then check for next type
				       ;;
				       ;; CHECK FOR ENHANCED KEYBOARD...
	OR    ES:KB_FLAG_2,08H	       ;; FROM COMNBODY.ASM - DON'T KNOW WHY
				       ;;
				       ;; READ ID COMMAND TO TEST FOR A KBX
				       ;;
	MOV   ES:KB_FLAG_3,RD_ID       ;; INDICATE THAT A READ ID IS BEING
				       ;; DONE
	MOV   AL,0F2H		       ;; SEND THE READ ID COMMAND
	CALL  SND_DATA_AT	       ;;
				       ;;
	MOV	CX,03F00H	       ;; LOAD COUNT FOR ABOUT 37MS
WT_ID:	TEST	ES:KB_FLAG_3,KBX       ;; TEST FOR KBX SET
	LOOPZ	WT_ID		       ;; WAIT OTHERWISE
				       ;; BE SURE FLAGS GOT RESET
;***CNS
				       ;; SAVE ALL REGISTERS BEFORE ENTRY
				       ;; INTO CHECKING KEYBOARD SECURITY
	PUSH	AX			       ;AN000; ;SAVE THE CURRENT ENVIRONMENT
	PUSH	BX			       ;AN000;
	PUSH	CX			       ;AN000;
	PUSH	DX			       ;AN000;
	PUSH	DS			       ;AN000;
	PUSH	ES			       ;AN000;
	PUSH	SI			       ;AN000;
	PUSH	DI			       ;AN000;



	CALL	KEYB_SECURE		       ;SEE IF THE KEYBOARD SECURITY IS
					       ;ACTIVATED AT THIS POINT


	POP	DI			       ;AN000;
	POP	SI			       ;AN000;
	POP	ES			       ;AN000;
	POP	DS			       ;AN000;
	POP	DX			       ;AN000;
	POP	CX			       ;AN000;
	POP	BX			       ;AN000;
	POP	AX			       ;AN000;SAVE THE CURRENT ENVIRONMENT

	JNC	ASSUME_AT		       ;AN000;SECURITY UNAVAILABLE OR AN AT KB


	MOV	SECURE_FL,1		       ;AN000;SECURITY IS ACTIVE
	JMP	FIND_KEYB_END		       ;AN000;ASSUME IT IS A G_KB  WITH
					       ;AN000;NUM LOCK OFF
ASSUME_AT:
;***CNS
	AND	ES:KB_FLAG_3,NOT RD_ID+LC_AB
				       ;;
	TEST	ES:KB_FLAG_3,KBX       ;; WAS IT A KBX?
	JNZ	DONE_AT_2	       ;; YES, WE ARE DONE
				       ;;
	MOV   HW_TYPE,AT_KB	       ;; NO, AT KBD
DONE_AT_2:			       ;;
	JMP   FIND_KEYB_END	       ;;
				       ;;
TEST_P12_2:			       ;;
	CMP   AL,ROMLAP 	       ;; IS this a P12?
	JNE   TEST_XT_ENH_OR_NEWER     ;; IF not then check for next type
	MOV   HW_TYPE,P12_KB	       ;; IF yes then set flag
				       ;;
TEST_XT_ENH_OR_NEWER:		       ;;
	CMP   AL,ROMXT_ENHAN	       ;;
	JNA   GET_KEYB_ID	       ;; ** assume all new systems will have ext
	JMP   FIND_KEYB_END	       ;; **   ROM or else test previous to this
				       ;;
GET_KEYB_ID:			       ;;
;***************************** CNS ****************************************
;* This area has been Revised to allow the extended ROM support added
;* flexibility for the PALACE or FLASHLIGHT with less than 640k; AN extended
;* BIOS DATA  call is to be made returning the segment of the extended
;* BIOS area which should be in maximum memory - 1k area.
;***************************************************************************

	MOV	AH,0C1H 	       ;; Make the extended bios data area
	INT	15H		       ;; call to get the segment address for
	JNC	NEW_SYSTEM	       ;; accessing the keyboard byte area
	JMP	FIND_KEYB_END	       ;; JNC	  SOMEWHERE&REPORT
				       ;; otherwise EXTENDED BIOS DATA RETURNED
				       ;; in the ES
				       ;; save the starting seg address value
				       ;; needs to start at locale 0003BH
;****************************************************************************
NEW_SYSTEM:
;**CNS
  ;; Set segment to look at extended ROM
  ;;	using the data segment
	PUSH	ES		       ;; SEG value returned from INT15h -- C1 call
	POP	DS
	ASSUME	DS:ROMEXT	       ;;
				       ;;
	MOV	AX,DATA 	       ;;
	MOV	ES,AX		       ;; BP points to BIOS data

				       ;;
	MOV	AL,KEYBID1	       ;; Get keyboard ID  ********** CNS
;**CNS
;*****************************************************************************
;old	 MOV	 AX,ROMEXT		;; Set segment to look at extended ROM
;code	 MOV	 DS,AX			;;    using the data segment
;	 ASSUME  DS:ROMEXT		;;
;					;;
;	 MOV	 AX,DATA		;;
;old	 MOV	 ES,AX			;; ES points to BIOS data
;code					;;
;	 MOV	 AL,KEYBID1		;; Get keyboard ID
;******************************************************************************
	PUSH	CS		       ;; Set data seg back to code
	POP	DS		       ;;
	ASSUME	DS:CODE 	       ;;
				       ;;
	AND	AL,0FH		       ;; Remove high nibble
	CMP	AL,P_KB_ID	       ;; IF keyboard is a FERRARI P THEN
	JNE	FIND_KEYB_END	       ;;
	OR	HW_TYPE,P_KB	       ;;    Set the HW_TYPE flag
				       ;;
FIND_KEYB_END:			       ;; ELSE
	MOV   AX,HW_TYPE	       ;;    Leave default alone
	MOV   SD.KEYB_TYPE,AX	       ;;
				       ;;
	POP   DS		       ;;
	POP   ES		       ;;
	RET			       ;;
				       ;;
FIND_KEYB_TYPE		ENDP	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: SND_DATA_AT
;;
;; Description:
;;	THIS ROUTINE HANDLES TRANSMISSION OF PC/AT COMMAND AND DATA BYTES
;;	TO THE KEYBOARD AND RECEIPT OF ACKNOWLEDGEMENTS.  IT ALSO
;;	HANDLES ANY RETRIES IF REQUIRED
;;
;;
;; Input Registers:
;;     DS - points to our data segment
;;     ES - points to the BIOS data segment
;;
;; Output Registers:
;;
;; Logic:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SND_DATA_AT PROC   NEAR
	PUSH	AX			; SAVE REGISTERS
	PUSH	BX			; *
	PUSH	CX
	MOV	BH,AL			; SAVE TRANSMITTED BY FOR RETRIES
	MOV	BL,3			; LOAD RETRY COUNT
SD0:	CLI				; DISABLE INTERRUPTS
	AND	ES:KB_FLAG_2,NOT (KB_FE+KB_FA) ; CLEAR ACK AND RESEND FLAGS

;------- WAIT FOR COMMAND TO BE ACCEPTED

	SUB	CX,CX
SD5:
	IN	AL,STATUS_PORT
	TEST	AL,INPT_BUF_FULL
	LOOPNZ	SD5			; WAIT FOR COMMAND TO BE ACCEPTED
;
	MOV	AL,BH			; REESTABLISH BYTE TO TRANSMIT
	OUT	PORT_A,AL		; SEND BYTE
	STI				; ENABLE INTERRUPTS
	MOV	CX,01A00H		; LOAD COUNT FOR 10mS+
SD1:	TEST	ES:KB_FLAG_2,KB_FE+KB_FA   ; SEE IF EITHER BIT SET
	JNZ	SD3			; IF SET, SOMETHING RECEIVED GO PROCESS
;
	LOOP	SD1			; OTHERWISE WAIT
;
SD2:	DEC	BL			; DECREMENT RETRY COUNT
	JNZ	SD0			; RETRY TRANSMISSION
;
	OR	ES:KB_FLAG_2,KB_ERR	   ; TURN ON TRANSMIT ERROR FLAG
	JMP	SHORT SD4		; RETRIES EXHAUSTED FORGET TRANSMISSION
;
SD3:	TEST	ES:KB_FLAG_2,KB_FA	   ; SEE IF THIS IS AN ACKNOWLEDGE
	JZ	SD2			; IF NOT, GO RESEND
;
				       ;; If this was an acknowledge, determine*RPS
				       ;;     if keyboard is FERRARI G or P    *RPS
	MOV	CX,1000 	       ;;
IO_DELAY1:			       ;;
	LOOP	IO_DELAY1	       ;;
	JMP	SHORT $+2	       ;; Allow for recovery time
	IN	AL,PORT_A	       ;; READ IN THE CHARACTER 	       *RPS
	MOV	CX,1000 	       ;;
IO_DELAY2:			       ;;
	LOOP	IO_DELAY2	       ;;
	JMP	SHORT $+2	       ;; Allow for recovery time
	MOV	BH,AL		       ;;				       *RPS
				       ;;
	IN	AL,PORT_A	       ;; READ IN THE CHARACTER 	       *RPS
	MOV	BL,AL		       ;;				       *RPS
				       ;;				       *RPS
	CMP	BX,P_KEYBOARD	       ;; Set HW_TYPE appropriately	       *RPS
	JNE	SD4		       ;;				       *RPS
	OR	HW_TYPE,P_KB	       ;;				       *RPS
				       ;;
SD4:	POP	CX			; RESTORE REGISTERS
	POP	BX
	POP	AX			; *
	RET				; RETURN, GOOD TRANSMISSION
SND_DATA_AT ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;************************************************************************
; KEYBOARD SECURITY LOGIC
; CHECK THE CMOS RAM @ ADDRESS HEX 013H
; CHECK TO SEE IF EITHER BITS 1 (PASSWORD) OR 2 (SERVER MODE) ARE SET ON
; IF EITHER BIT IS SET ON THE SYSTEM IS A MOD 50 on up
;  REPORT MESSAGE KEYBOARD LOCKED UNABLE TO LOAD KEYBOARD TABLES
; OTHERWISE AN INVALID RESPONSE OR ZERO SHOULD BE RETURNED
;  PROCEED AS WITH LOADING OF THE CORRECT TABLES

; PROPOSED KEYBOARD SYNTAX

; KEYB [lang],[cp],[[d:][path]KEYBOARD.SYS][/ID:id]



;************************************************************************

KEYB_SECURE	PROC	NEAR



;RESERVED ADDRESS 013h BITS 1 & 2

;	PASS_MODE	equ		00000001B   ;AN000;
;	SERVER_MODE	equ		00000010B   ;AN000;



;	SECRET_ADD	equ		13h    ;AN000;
;	PORT_70 	equ		70h    ;AN000;
;	PORT_71 	equ		71h    ;AN000;

;	 PUSH	 AX				;AN000; ;SAVE THE CURRENT ENVIRONMENT
;	 PUSH	 BX				;AN000;
;	 PUSH	 CX				;AN000;
;	 PUSH	 DX				;AN000;
;	 PUSH	 CS				;AN000;
;	 PUSH	 DS				;AN000;
;	 PUSH	 ES				;AN000;
;	 PUSH	 SI				;AN000;
;	 PUSH	 DI				;AN000;
	CLI					;AN000;;DISABLE THE INTERRUPT TO AVOID
						;AN000;;THE CMOS REGISTER BEFORE
						;AN000;;THE READ & WRITE IS DONE

	XOR	AX,AX
	MOV	AL,SECRET_ADD
	OUT	PORT_70,AL			;AN000;;SEND THE ADDRESS CONTAINING THE
						;BITS FOR THE PASSWORD AND SERVER
						;MODE STATE TO PORT 70H





	IN	AL,PORT_71			;AN000;;READ THE DATA IN TO GET THE
						;RESULTS OF THE CHECK FOR THE
						;EXISTENCE OF SECURITY.

	MOV	DX,AX

	TEST	DL,PASS_MODE+SERVER_MODE	;AN000;;CHECK & SEE IF THE BITS ARE ON
	JNZ	KEYB_LOCKED			;AN000;;YES THEY ARE ON SO EXIT AND REPORT
	CLC    ;XOR	AX,AX				;ASSUME THIS IS AN AT KEYBOARD
	JMP	SECURE_RET

KEYB_LOCKED:

	STC   ; MOV	AX,1				;AN000;SET THE SECURITY FLAG
						;ON;
						;PROCEED - EITHER SYSTEM IS AN
						;AT OR THE SYSTEM IS UNLOCKED
SECURE_RET:

	STI					;AN000;;ENABLE THE INTERRUPT


;	POP	DI			       ;AN000;
;	POP	SI			       ;AN000;
;	POP	ES			       ;AN000;
;	POP	DS			       ;AN000;
;	POP	CS			       ;AN000;
;	POP	DX			       ;AN000;
;	POP	CX			       ;AN000;
;	POP	BX			       ;AN000;
;	POP	AX			       ;AN000; ;SAVE THE CURRENT ENVIRONMENT


	RET


KEYB_SECURE	ENDP




CODE   ENDS
       END
