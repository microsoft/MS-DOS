PAGE	60,132
TITLE	INDEINI - 386 XMA EMULATOR - Initialization

COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*									      *
* MODULE NAME	  : INDEINI						      *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corp.              *
*                                                                             *
* DESCRIPTIVE NAME: 80386 XMA EMULATOR INITIALIZATION			      *
*									      *
* STATUS (LEVEL)  : VERSION (0) LEVEL (2.0)				      *
*									      *
* FUNCTION	  : Do all the initialization needed for the 386 XMA emulator.*
*									      *
*		    The 386 XMA emulator is installed by putting the follow-  *
*		    ing command in the CONFIG.SYS file: 		      *
*									      *
*			      DEVICE=\386XMAEM.SYS bbb			      *
*									      *
*		    where "bbb" is the number of K reserved for the MOVEBLOCK *
*		    function.  If EMS is used, this command must appear       *
*		    before the command to load EMS.			      *
*									      *
*		    This module first of all does all the stuff to set up     *
*		    the device driver linkage to DOS.  The driver is a	      *
*		    character device.  The only command it recognizes is   P3C*
*		    "initialize".  When it receives the initialize command    *
*		    it does all the set up for the emulator.  For information *
*		    on device drivers see the DOS Technical Reference.	      *
*									      *
*		    Then it checks to see if we're on a model_80 and the      *
*		    emulator has not been previously installed.  If this is   *
*		    the case, then it procedes to do the following:	      *
*			Get the MOVEBLOCK buffer size from the parameter list *
*			Save the maximum XMA block number in the header       *
*			Relocate to high memory 			      *
*			Initialize the page directory and page tables	      *
*			Call INDEIDT to initialize the IDT		      *
*			Call INDEGDT to initialize the GDT		      *
*			Switch to virtual mode				      *
*			Initialize the TSS for the virtual 8086 task	      *
*			Initialize the XMA page tables			      *
*			Enable paging					      *
*									      *
*		    This module also contains code to handle the Generic   D2A*
*		    IOCTL call which is used to query the highest valid    D2A*
*		    XMA block number.  This code is left resident.	   D2A*
*									      *
* MODULE TYPE	  : ASM 						      *
*									      *
* REGISTER USAGE  : 80386 STANDARD					      *
*									      *
* RESTRICTIONS	  : None						      *
*									      *
* DEPENDENCIES	  : None						      *
*									      *
* LINKAGE	  : Invoked as a DOS device driver			      *
*									      *
* INPUT PARMS	  : The number of 1K blocks reserved for the MOVE BLOCK       *
*		    service can be specified after the DEVICE command in the  *
*		    CONFIG.SYS file.  0K is the default.		      *
*									      *
* RETURN PARMS	  : A return code is returned to DOS in the device header     *
*		    at offset 3.					      *
*									      *
* OTHER EFFECTS   : None						      *
*									      *
* EXIT NORMAL	  : Return to DOS after device driver is loaded 	      *
*									      *
* EXIT ERROR	  : Return to DOS after putting up error messages	      *
*									      *
* EXTERNAL								      *
* REFERENCES	  : SIDT_BLD - Entry point for INDEIDT to build the IDT       *
*		    GDT_BLD  - Entry point for INDEGDT to build the GDT       *
*		    WELCOME  - The welcome message			      *
*		    GOODLOAD - Message saying we loaded OK		      *
*		    NO_80386 - Error message for not running on a model_80    *
*		    WAS_INST - Error message for protect mode in use	      *
*		    SP_INIT  - Initial protect mode SP			      *
*		    REAL_CS  - Place to save our real mode CS		      *
*		    REAL_SS  - Place to save our real mode SS		      *
*		    REAL_SP  - Place to save our real mode SP		      *
*		    PGTBLOFF - Offset of the page tables		      *
*		    SGTBLOFF - Offest of the page directory		      *
*		    NORMPAGE - Normal page directory entry		      *
*		    XMAPAGE  - Page directory entry for the first XMA page D1A*
*		    BUFF_SIZE- Size of the MOVEBLOCK buffer		      *
*		    MAXMEM   - Maximum amount of memory on the box	      *
*		    CRT_SELECTOR - Selector for the display buffer	      *
*									      *
* SUB-ROUTINES	  : GATE_A20  - Gate on or off address bit 20		      *
*		    GET_PARMS - Get the MOVEBLOCK buffer size specified on    *
*				the command in CONFIG.SYS and convert to      *
*				binary. 				      *
*									      *
* MACROS	  : DATAOV  - Add prefix for the next instruction so that it  *
*			      accesses data as 32 bits wide		      *
*		    ADDROV  - Add prefix for the next instruction so that it  *
*			      uses addresses that are 32 bits wide	      *
*		    CMOV    - Move to and from control registers	      *
*		    JUMPFAR - Build an instruction that will jump to the      *
*			      offset and segment specified		      *
*									      *
* CONTROL BLOCKS  : INDEDAT.INC 					      *
*									      *
* CHANGE ACTIVITY :							      *
*									      *
* $MOD(INDEINI) COMP(LOAD) PROD(3270PC) :				      *
*									      *
* $D0=D0004700 410 870521 D : NEW FOR RELEASE 1.1.  CHANGES TO THE ORIGINAL   *
*			      CODE ARE MARKED WITH D0A. 		      *
* $P1=P0000281 410 870730 D : SAVE 32 BIT REGISTERS ON model_80 	      *
* $P2=P0000312 410 870804 D : CHANGE COMPONENT FROM MISC TO LOAD	      *
* $P3=P0000335 410 870811 D : HEADER INFORMATION ALL SCREWED UP 	      *
* $D1=D0007100 410 870810 D : CHANGE TO EMULATE XMA 2			      *
*			      CHANGE ID STRING TO "386XMAEMULATOR10"          *
* $P4=P0000649 411 880125 D : A20 NOT ENABLED WHEN PASSWORD SET 	      *
* $P5=P0000650 411 880128 D : COPROCESSOR APPLICATIONS FAIL		      *
* $P6=P0000740 411 880129 D : IDSS CAPTURED DCR 87 CODE.  REMOVE IT.	      *
* $D2=D0008700 120 880206 D : SUPPORT DOS 3.4 IOCTL CALL		      *
* $P7=P0000xxx 120 880331 D : FIX INT 15.  LOAD AS V86 MODE HANDLER.	      *
*									      *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

	.286P		      ; Enable recognition of 286 privileged instructs.

	.XLIST		      ; Turn off the listing
	INCLUDE INDEDAT.INC

	IF1		      ; Only include the macros in the first pass
	INCLUDE INDEOVP.MAC   ;   of the assembler
	INCLUDE INDEINS.MAC
	ENDIF
	.LIST		      ; Turn on the listing

	; Let these variables be known to external procedures

	PUBLIC	POST
	PUBLIC	INDEINI

PROG	SEGMENT PARA PUBLIC  'PROG'

	ASSUME	CS:PROG
	ASSUME	SS:NOTHING
	ASSUME	DS:PROG
	ASSUME	ES:NOTHING

INDEINI LABEL	NEAR

	; These variables are located in INDEI15

	EXTRN	SP_INIT:WORD	  ; Initial protect mode SP
	EXTRN	REAL_CS:WORD	  ; Place to save our real mode CS
	EXTRN	REAL_SS:WORD	  ; Place to save our real mode SS
	EXTRN	REAL_SP:WORD	  ; Place to save our real mode SP
	EXTRN	PGTBLOFF:WORD	  ; Offset of the page tables
	EXTRN	SGTBLOFF:WORD	  ; Offest of the page directory
	EXTRN	NORMPAGE:WORD	  ; Normal page directory entry.  Points to the
				  ;   page table that maps the real 0 to 4M.
	EXTRN	XMAPAGE:WORD	  ; Page directory entry for the first XMA
				  ;   page table (page table for bank 0)    @D1A
	EXTRN	BUFF_SIZE:WORD	  ; Size of the MOVEBLOCK buffer
	EXTRN	MAXMEM:WORD	  ; Maximum amount of memory on the box
	EXTRN	CRT_SELECTOR:WORD ; Selector for the display buffer

	; These are the messages

	EXTRN	WELCOME:BYTE	  ; The welcome message
	EXTRN	GOODLOAD:BYTE	  ; Message saying we loaded OK
	EXTRN	NO_80386:BYTE	  ; Error message for not running on a model_80
	EXTRN	WAS_INST:BYTE	  ; Error message for protect mode in use
	Extrn	Small_Parm:Byte   ; Parm value < 64 and > 0			;an000; dms;
	Extrn	No_Mem:Byte	  ; Parm value > memory available		;an000; dms;

	; These entries are located in external procedures

	EXTRN	SIDT_BLD:NEAR	  ; Build the interrupt descriptor table (IDT)
	EXTRN	GDT_BLD:NEAR	  ; Build the global descriptor table (GDT)

; General equates

DDSIZE		EQU	GDT_LOC 	; Size of the device driver
HIGH_SEG	EQU	0FFF0H		; The segment we relocate to
MEG_SUPPORTED	EQU	24		; Must be a multiple of 4
XMA_PAGES_SEL	EQU	RSDA_PTR	; Selector for XMA pages
DISPSTRG	EQU	09H		; DOS display string function number D0A
GET_VECT	EQU	35H		; DOS get vector function number     P7A
SET_VECT	EQU	25H		; DOS set vector function number     P7A
model_80	EQU	0F8H		; Model byte for the Wangler	     D0A
XMA640KSTRT	EQU	580H		; Start address of XMA block for     D0A
					;   640K (16000:0 / 1K) 	D0A  P3C

; ASCII character equates

TAB	   EQU	09H		; ASCII tab
LF	   EQU	0AH		; ASCII line feed
CR	   EQU	0DH		; ASCII carriage return

SUBTTL	Structure Definitions
PAGE
;------------------------------------------------------------------------------;
;	Request Header (Common portion) 				       ;
;------------------------------------------------------------------------------;

RH	EQU	DS:[BX] 	; The Request Header structure is based off
				;   of DS:[BX]

RHC	STRUC			; Fields common to all request types
	   DB	?		; Length of Request Header (including data)
	   DB	?		; Unit code (subunit)
RHC_CMD    DB	?		; Command code
RHC_STA    DW	?		; Status
	   DQ	?		; Reserved for DOS
RHC	ENDS			; End of common portion

; Status values for RHC_STA

STAT_DONE   EQU 0100H		; Function complete status (high order byte)@P3C
STAT_CMDERR EQU 8003H		; Invalid command code error
STAT_GEN    EQU 800CH		; General error code			     D0A

;------------------------------------------------------------------------------;
;	Request Header for INIT command 				       ;
;------------------------------------------------------------------------------;

RH0	STRUC
	   DB	(TYPE RHC) DUP (?)	; Reserve space for the header

RH0_NUN    DB	?		; Number of units
				; Set to 1 if installation succeeds,
				; Set to 0 to cause installation failure
RH0_ENDO   DW	?		; Offset  of ending address
RH0_ENDS   DW	?		; Segment of ending address
RH0_BPBO   DW	?		; Offset  of BPB array address
RH0_BPBS   DW	?		; Segment of BPB array address
RH0_DRIV   DB	?		; Drive code (DOS 3 only)
RH0	ENDS

RH0_BPBA   EQU	DWORD PTR RH0_BPBO  ; Offset & segment of BPB array address.
				    ; On the INIT command the BPB points to
				    ; the characters following the "DEVICE="
				    ; in the CONFIG.SYS file.

;---------------------------------------------------------------------------D2A;
;	Request Header for Generic IOCTL Request			    D2A;
;---------------------------------------------------------------------------D2A;

RH19	STRUC
	    DB	 (TYPE RHC) DUP (?)	; Reserve space for the header	   @D2A

RH19_MAJF   DB	 ?		; Major function			   @D2A
RH19_MINF   DB	 ?		; Minor function			   @D2A
RH19_SI     DW	 ?		; Contents of SI			   @D2A
RH19_DI     DW	 ?		; Contents of DI			   @D2A
RH19_RQPK   DD	 ?		; Pointer to Generic IOCTL request packet  @D2A
RH19	ENDS

SUBTTL	Device Driver Header
PAGE
POST	PROC	NEAR

	; Declare the device driver header

	ORG  0		      ; Device header must the very first thing in the
			      ;   device driver
	DD   -1 	      ; Becomes pointer to next device header
	DW   0C040H	      ; Character device, does IOCTL	       @P3C @D2C
	DW   OFFSET STRATEGY  ; Pointer to device "strategy" routine
	DW   OFFSET IRPT      ; Pointer to device "interrupt handler"
	DB   "386XMAEM"       ; Device name                                 @D0C

	; End of device driver header

;------------------------------------------------------------------------------;
;	Request Header (RH) address, saved here by "strategy" routine          ;
;------------------------------------------------------------------------------;

RH_PTRA    LABEL DWORD
RH_PTRO    DW	?	      ; Offset of the request header
RH_PTRS    DW	?	      ; Segment of the request header
			      ; Character ID "386XMAEMULATOR10" deleted   2@D2D
HI_XMA_BLK DW	?	      ; The highest XMA block number		   @D0A
EXT_MEM    DW	?	      ; Number of K of extended memory		   @P7A
			      ; 					    D0A
RBX	   DW	?	      ; Temporary save area for register BX	   @P1A
ISmodel_80 DB	-1	      ; model_80 flag.	Set to 1 if on a model_80  @P1A
			      ;   Set to 0 if not on a model_80 	   @D1C

SUBTTL	Device Strategy
PAGE
;------------------------------------------------------------------------------;
;	Device "strategy" entry point                                          ;
;									       ;
;	Retain the Request Header address for use by Interrupt routine	       ;
;------------------------------------------------------------------------------;

STRATEGY PROC	FAR

	MOV	CS:RH_PTRO,BX ; Save the offset of the request header
	MOV	CS:RH_PTRS,ES ; Save the segment of the request header
	RET

STRATEGY ENDP

SUBTTL	Device Interrupt Intry Point
PAGE

;------------------------------------------------------------------------------;
;	Table of command processing routine entry points		       ;
;------------------------------------------------------------------------------;
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
	   DW	OFFSET REMOVABLE_MEDIA	;15 - Removable media
	   DW	OFFSET INVALID_FCN	;16 - Invalid IOCTL function	    @D2A
	   DW	OFFSET INVALID_FCN	;17 - Invalid IOCTL function	    @D2A
	   DW	OFFSET INVALID_FCN	;18 - Invalid IOCTL function	    @D2A
	   DW	OFFSET GENERIC_IOCTL	;19 - Generic IOCTL function	    @D2A
	   DW	OFFSET INVALID_FCN	;20 - Invalid IOCTL function	    @D2A
	   DW	OFFSET INVALID_FCN	;21 - Invalid IOCTL function	    @D2A
	   DW	OFFSET INVALID_FCN	;22 - Invalid IOCTL function	    @D2A
	   DW	OFFSET GET_LOG_DEVICE	;23 - Get Logical Device	    @D2A
MAX_CMD    EQU	($-CMD_TABLE)/2 	; Highest valid command follows
	   DW	OFFSET SET_LOG_DEVICE	;24 - Set Logical Device	    @D2A

;------------------------------------------------------------------------------;
;	Device "interrupt" entry point                                         ;
;------------------------------------------------------------------------------;
IRPT	PROC	FAR		; Device interrupt entry point

; First we must save all the registers that we use so that when we return to
; DOS the registers are not changed.

	PUSH	DS		; Save the segment registers modified
	PUSH	ES

	CMP	CS:ISmodel_80,-1; Did we already check what machine we are  @D2A
	JNE	DID_CHECK	;   running on? 			    @D2A

	MOV	CS:RBX,BX	; Save BX				    @P1A
	MOV	BX,0FFFFH	; Check the model byte at FFFF:000E    @D0A @P1M
	MOV	ES,BX		;   to see if we're running on a       @D0A @P1M
	MOV	BX,0EH		;   model_80 (PS/2 model 80).	       @D0A @P1M
	CMP	BYTE PTR ES:[BX],model_80 ;				    @P1A
	MOV	BX,CS:RBX	; Restore BX			       @P1A @D2M
	JNE	NO_model_80

	MOV	CS:ISmodel_80,1 ; Set the flag saying we're on a       @P1A @D2M
	JMP	DID_CHECK	;   model_80				    @D2A

NO_model_80:
	MOV	CS:ISmodel_80,0 ; Set the flag saying we're not on a        @D2M
				;   model_80

DID_CHECK:			;					     D2A
	CMP	ISmodel_80,1	; Are we on a model_80? 		    @D2A
	JE	PUSH32		; If so, go save the 32 bit registers	    @P1A

; Push 16 bit registers onto the stack.

	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	SI
	PUSH	BP

	JMP	PUSHED		;					    @P1A

; Push 32 bit registers onto the stack					     P1A
				;					    @D2D
PUSH32: DATAOV			; Save all the 32 bit registers.  The	    @P1A
	PUSHA			;   model_80's BIOS uses 32 bit registers,  @P1A
				;   so we must not trash the high order      P1A
				;   words as well as the low order words.    P1A

PUSHED: CLD			; All moves go forward

	LDS	BX,CS:RH_PTRA	; Get the request header address passed to the
				;   "strategy" routine into DS:BX

	MOV	AL,RH.RHC_CMD	; Get the command code from the Request Header
	CBW			; Zero AH (if AL > 7FH, next compare will
				;   catch that error)

	CMP	AL,MAX_CMD	; If command code is too high
	JA	IRPT_CMD_HIGH	; Then jump to error routine

	ADD	AX,AX		; Double command code for table offset since
				;   table entries are words
	MOV	DI,AX		; Put into index register for CALL
				;					    @D2D
;
; At entry to command processing routine:
;
;	DS:BX	= Request Header address
;	CS	= 386XMAEM code segment address
;	AX	= 0
;
	CALL	CS:CMD_TABLE[DI]	; Call routine to handle the command
	JMP	IRPT_CMD_EXIT


IRPT_CMD_HIGH:			; JMPed to if RHC_CMD > MAX_CMD
	MOV	AX,STAT_CMDERR	; Return "Invalid Command" error code
	OR	AX,STAT_DONE	; Add "done" bit to status word             @P3C
	MOV	RH.RHC_STA,AX	; Store status into request header

IRPT_CMD_EXIT:			; Return from command routine

; Restore the registers before returning to DOS.

	CMP	CS:ISmodel_80,1 ; Are we on a model_80? 		    @P1A
	JE	POP32		; Yes.	Then pop the 32 bit registers.	    @P1A

; Pop 16 bit registers off of the stack.

	POP	BP
	POP	SI
	POP	DI
	POP	DX
	POP	CX
	POP	BX
	POP	AX

	JMP	POPPED		;					    @P1A

; Pop 32 bit registers off of the stack.				     P1A
				;					     P1A
POP32:	DATAOV			;					    @P1A
	POPA			;					    @P1A

; Pop the segment registers off of the stack.

POPPED: POP	ES
	POP	DS

	RET
IRPT	ENDP

SUBTTL	Command Routines
PAGE

MEDIA_CHECK:			;
BLD_BPB:			;
INPUT_IOCTL:			; IOCTL input
INPUT:				;
INPUT_NOWAIT:			; Non-destructive input no wait
INPUT_STATUS:			; Input status
INPUT_FLUSH:			; Input flush
OUTPUT: 			;
OUTPUT_VERIFY:			;
OUTPUT_IOCTL:			; IOCTL output
OUTPUT_STATUS:			; Output status
OUTPUT_FLUSH:			; Output flush
DEVICE_OPEN:			;
DEVICE_CLOSE:			;
REMOVABLE_MEDIA:		;
INVALID_FCN:			;					    @D2A
GET_LOG_DEVICE: 		;					    @D2A
SET_LOG_DEVICE: 		;					    @D2A

	MOV	AX,STAT_GEN	; Return general error code		    @D2A
	OR	AX,STAT_DONE	; Add "done" bit to status word             @D2A
	MOV	RH.RHC_STA,AX	; Store status into request header	    @D2A

	RET

SUBTTL	Generic IOCTL Service Routine
PAGE

;------------------------------------------------------------------------------;
; This routine handles the Generic IOCTL call.	The Emulator provides an    D2A;
; interface through the Generic IOCTL call to query the number of XMA	    D2A;
; blocks available.  When the function code in the parameter list is 0 the  D2A;
; Emulator will return the number of XMA blocks available.  There are no    D2A;
; other functions uspported at this time.				    D2A;
;------------------------------------------------------------------------------;

GIP	EQU	ES:[DI] 	      ; 				    @D2A

GEN_IOCTL_PARM	STRUC		      ; 				    @D2A

GIOPLEN DW	?		      ; Length of the parameter list	    @D2A
GIOPFCN DW	?		      ; Function code			    @D2A
GIOPBLK DW	?		      ; Number of XMA blocks available	    @D2A

GEN_IOCTL_PARM	ENDS		      ; 				    @D2A

MAXFCN	EQU	0		      ; Highest function number allowed     @D2A

; Return codes								     D2A

GOODRET EQU	0		      ; Good return code		    @D2A
BADLEN	EQU	1		      ; Bad parameter list length	    @D2A
BADFCN	EQU	2		      ; Bad function number		    @D2A

GENERIC_IOCTL:			      ; 				     D2A

	LES	DI,RH.RH19_RQPK       ; Point ES:DI to the Generic IOCTL    @D2A
				      ;   request packet		     D2A

; First check to make sure the parameter list is long enough to return the   D2A
; number of XMA blocks. 						     D2A

	CMP	GIP.GIOPLEN,4	      ; Do we have at least four bytes?     @D2A
	JAE	GIP_CHKFCN	      ; Yup.  Go to check function number.  @D2A

	MOV	GIP.GIOPFCN,BADLEN    ; Nope.  Sorry.  Return the error     @D2A
	JMP	GIP_DONE	      ;   code and go to the end.	    @D2A

; Check if the function number in the parameter list is a valid function.    D2A

GIP_CHKFCN:			      ; 				     D2A
	CMP	GIP.GIOPFCN,MAXFCN    ; Is the function code less than or   @D2A
				      ;   equal to the maximum supported?    D2A
	JLE	GIP_CONT	      ; Yes. Good boy. You get to continue. @D2A

	MOV	GIP.GIOPFCN,BADFCN    ; No.  Shamey, shamey.  Set the bad   @D2A
	JMP	GIP_DONE	      ;   return code and go to the end.    @D2A

; Parameter list is OK.  Let's return the number of XMA blocks.              D2A

GIP_CONT:			      ; 				     D2A
	MOV	GIP.GIOPFCN,GOODRET   ; Set a good return code		    @D2A
	MOV	AX,CS:HI_XMA_BLK      ; Get the number of XMA blox	    @D2A
	MOV	GIP.GIOPBLK,AX	      ; Put it in the paramter list	    @D2A


GIP_DONE:			      ; 				     D2A
	MOV	RH.RHC_STA,STAT_DONE  ; Store done status and good return   @D2A
				      ;   code into request header	     D2A
	RET			      ; 				    @D2A

INT15F88   PROC    FAR		      ; 				     P7A

; The following is the interrupt chaining structure specified in the PC AT   P7A
; Technical Reference.							     P7A

	   JMP	   SHORT BEGIN	      ; 				     P7A

CHAINOFF   DW	   0		      ; Offest of the previous INT 15 vect. @P7A
CHAINSEG   DW	   0		      ; Segment of the previous INT 15 vect.@P7A
SIGNATURE  DW	   424BH	      ; Says we're doing chaining           @P7A
FLAGS	   DB	   0		      ; 				    @P7A
FIRST	   EQU	   80H		      ; 				    @P7A
	   JMP	   SHORT RESET	      ; 				    @P7A
RESERVED   DB	   7 DUP (0)	      ; 				    @P7A

; OK.  Let's see if the user asked for function 88H, query memory size.      P7A
; The function number is specified in the AL register.	If it's              P7A
; function88h, then put the memory size in AX and IRET to the caller.	     P7A
; Else, just pass the interrupt on to the guy who was installed in the INT   P7A
; 15 vector before us.							     P7A

BEGIN:	   CMP	   AH,88H	       ; Is it function 88H?		    @P7A
	   JNE	   NOT_MINE	       ; It's not ours to handle            @P7A

	   MOV	   AX,CS:EXT_MEM       ; Put the number of K into AX	    @P7A
	   IRET 		       ; Return to the caller		    @P7A

NOT_MINE:  JMP	   CS:DWORD PTR CHAINOFF
				       ; Pass the interrupt on to the	    @P7A
				       ;   previously installed vector	    @P7A

RESET:	   RET			       ; This, too, is part of the interrupt@P7A
				       ;   chaining structure.	We will just@P7A
				       ;   return on a call to reset.  Note @P7A
				       ;   that this is a far return.	    @P7A
INT15F88   ENDP 		       ;				    @P7A

LEAVE_RES  LABEL NEAR		      ; Leave code up to here resident.@D0A @D2M

SUBTTL	Initialize Routine
PAGE
INIT_P1:

	PUSH	ES			; Save our code segment at the	    @D0A
	MOV	DI,0			;   fixed location 0:4F4.  This     @P3C
	MOV	ES,DI			;   gives us a quick way to find CS @P3C
	MOV	DI,4F4H 		;   and also enables us to break on @P3C
	MOV	ES:[DI],CS		;   a write to 0:4F4 which helps us @P3C
	POP	ES			;   find the code on the ICE386.    @D0A
	MOV	AH,DISPSTRG		; Display the welcome message.	    @D0A
	MOV	DX,OFFSET WELCOME	;				    @D0A
	PUSH	DS			; Save DS since DS:BX points to the @D0A
	PUSH	CS			;   request header		    @D0A
	POP	DS			; DS:DX points to the message	    @D0A
	INT	21H			; Display the message		    @D0A
	POP	DS			; Restore DS			    @D0A
					;				    @P3D
	MOV	RH.RH0_ENDS,CS		; Set the segment and offset of the end
	MOV	RH.RH0_ENDO,OFFSET LEAVE_RES ; of code to leave resident
	MOV	RH.RHC_STA,STAT_DONE	; Store "done" status into request
					;   header
	CMP	CS:ISmodel_80,1 	; Check if we're on a model_80 @D0A @P1C
	JE	CONT			; If so, then continue		    @D0A
					;				     D0A
	MOV	RH.RH0_ENDO,0		; Leave nothing resident	    @D0A
	MOV	AX,STAT_GEN		; Return general error code	    @D0A
	OR	AX,STAT_DONE		; Add "done" bit to status word@D0A @P3C
	MOV	RH.RHC_STA,AX		; Store status into request header  @D0A
					;				     D0A
	MOV	AH,DISPSTRG		; Display the message that we are   @D0A
	MOV	DX,OFFSET NO_80386	;   not on a model_80		    @D0A
	PUSH	CS			;				    @D0A
	POP	DS			;				    @D0A
	INT	21H			;				    @D0A
					;				     D0A
	RET				;				     D0A
					;				     D0A
CONT:					;				    @D0M
	SMSW	AX			; Get machine status register
	TEST	AL,1			; Check if the processor is already in
					;   protect mode.  If so, then someone
					;   else (maybe us) has already taken
					;   over protect mode.
	JZ	STILLOK 		; If not, keep going		    @D0C

	MOV	RH.RH0_ENDO,0		; Leave nothing resident	    @D0A
	MOV	AX,STAT_GEN		; Return general error code	    @D0A
	OR	AX,STAT_DONE		; Add "done" bit to status word@D0A @P3C
	MOV	RH.RHC_STA,AX		; Store status into request header  @D0A
					;				     D0A
	MOV	AH,DISPSTRG		; Display the message that protect  @D0A
	MOV	DX,OFFSET WAS_INST	;   mode is taken.		    @D0A
	PUSH	CS			; DS:DX points to the message	    @D0A
	POP	DS			;				    @D0A
	INT	21H			;				    @D0A

	RET				;
STILLOK:			       ;				     D0A
	PUSH	0DEADH		      ; Push stack delimiter
				      ; Don't have to set character ID      @D2D
	CALL	GET_PARMS	      ; Get the MOVEBLOCK buffer size if
	jnc	StillOK1
		MOV	RH.RH0_ENDO,0		; Leave nothing resident	    @D0A
		MOV	AX,STAT_GEN		; Return general error code	    @D0A
		OR	AX,STAT_DONE		; Add "done" bit to status word@D0A @P3C
		MOV	RH.RHC_STA,AX		; Store status into request header  @D0A
					;				     D0A
		pop	ax
		ret		      ; exit program

StillOK1:
				      ;   one was specified
	CLI			      ; Disable interrupts

	PUSH	CS		      ; Now we can point DS to our own	    @P3A
	POP	DS		      ;   code segment			    @P3A
				      ; 				   2@D2D
	MOV	AX,CS
	MOV	REAL_CS,AX	      ; Save real CS for when we	    @P3C
	MOV	AX,SS		      ;   switch to protect mode
	MOV	REAL_SS,AX	      ; Save real SS			    @P3C
	MOV	AX,SP
	MOV	REAL_SP,AX	      ; Save real SP			    @P3C

;------------------------------------------------------------------------------;
;	Enable address line A20 					       ;
;------------------------------------------------------------------------------;

				      ; 				   3@P4D
	CALL	GATE_A20

	INT	11H		      ; Get the BIOS equipment flags
	AND	AL,30H		      ; Bits 5 and 6 on means it's a mono
	CMP	AL,30H
	JE	LEAVEBW
	MOV	CRT_SELECTOR,C_CCRT_PTR ; Set the CRT selector to color display
LEAVEBW:
	MOV	AH,88H		      ; Get number of 1k blocks above 1M
	INT	15H
	ADD	AX,1024 	      ; Add 640K for the memory below 640K  @P7C
	MOV	MAXMEM,AX	      ; Save for later

; Get the maximum XMA block number and save it in the header up front	     D0A
; All memory is treated as XMA memory.					     D1C
				      ; 				     D0A
	SUB	AX,BUFF_SIZE	      ; Can't use the MOVEBLOCK buffer for  @D0A
				      ;   XMA memory.  AX = number of K      D0A
				      ;   available.			     D0A
	SUB	AX,(1024-640) +128    ; Subtract 128k for the Emulator code	;an000; dms;
	SHR	AX,2		      ; Divide by four to get the number of @D0A
				      ;   4K blocks			     D0A
	DEC	AX		      ; Subtract 1.  This converts the	    @P3A
				      ;   number of blocks available to the  P3A
				      ;   highest block number available.    P3A
				      ;   Block numbers are zero based.      P3A
	MOV	HI_XMA_BLK,AX	      ; Save it in the header		     D0A

;------------------------------------------------------------------------------;
;     Now lets relocate ourselves to high memory.			       ;
;------------------------------------------------------------------------------;

	MOV	AX,HIGH_SEG	      ; Set ES to the highest segment value
	MOV	ES,AX
	MOV	DI,0		      ; ES:DI points to the place to relocate to
	MOV	AX,CS
	MOV	DS,AX
	MOV	SI,0		      ; DS:SI points to our code to be moved
	MOV	CX,DDSIZE/2	      ; Length of code / 2 since moving words
	CLD
	REP	MOVSW		      ; Copy myself to high memory

	JUMPFAR NEXT,HIGH_SEG	      ; Jump to my relocated code
NEXT:

	MOV	AX,HIGH_SEG	      ; Set DS to be the same as CS
	MOV	DS,AX
;------------------------------------------------------------------------------;
;     The machine is still in real mode.  Zero out GDT and IDT ram.	       ;
;------------------------------------------------------------------------------;

	MOV	DI,GDT_LOC	      ; DI points to GDT location

	MOV	CX,(GDT_LEN+SIDT_LEN)/2 ; Set GDT and IDT to zero
	MOV	AX,0		      ; Store zeroes for now
	REP	STOSW

;------------------------------------------------------------------------------;
;    Use good-old real-mode selectors to set up the page tables.  The	       ;
;    page directory is a 4K block that is placed just before the	       ;
;    beginning of the GDT and on a 4K boundary.  Note that the DATAOV	       ;
;    macro creates a prefix for the following instruction so that its	       ;
;    data references are 32 bits wide.					       ;
;------------------------------------------------------------------------------;

	DATAOV
	SUB	AX,AX		      ; Clear EAX (32 bit AX reg.)
	MOV	AX,HIGH_SEG	      ; Get the current code segment
	DATAOV
	SUB	BX,BX		      ; Clear EBX (32 bit BX reg.)
	MOV	BX,GDT_LOC/16	      ; Load the offset of the GDT, converted
				      ;   to paragraphs
	DATAOV			      ; Add it on to the current code segment
	ADD	AX,BX		      ;   to get the segment address of the GDT.
				      ;   This will be over 1M, so use 32 bits.
	AND	AX,0FF00H	      ; Round down to nice 4k boundary
	DATAOV
	SUB	BX,BX		      ; Clear EBX
	MOV	BX,4096/16	      ; Load with the size of the page directory
				      ;   converted to paragraphs
	DATAOV			      ; Subtract the number of paragraphs needed
	SUB	AX,BX		      ;   for the page directory
	DATAOV
	SHL	AX,4		      ; Convert from paragraphs to bytes
	CMOV	CR3,EAX 	      ; Load the address of the page directory
				      ;   into CR3
	DATAOV
	SUB	BX,BX		      ; Clear EBX
	MOV	BX,HIGH_SEG	      ; Load our current code segment
	DATAOV
	SHL	BX,4		      ; Convert from paragraphs to bytes
	DATAOV
	SUB	AX,BX		      ; Subtract from the address of the page
				      ;   directory to get the offset of the
				      ;   directory in our code segment
	MOV	SGTBLOFF,AX	      ; Save for later

; Now let's clear the page directory

	MOV	CX,2048 	      ; Length is 4K/2 since storing words
	DATAOV
	MOV	DI,AX		      ; ES:EDI points to beginning of directory
	MOV	AX,0
	REP	STOSW		      ; Clear the page directory!

;------------------------------------------------------------------------------;
;   Initialize the first directory entries to our page tables		       ;
;------------------------------------------------------------------------------;

	CMOV	EAX,CR3 	; Get back CR3 - the address of the page dir.
	DATAOV
	MOV	DI,SGTBLOFF	; Point ES:EDI to first entry in directory
	DATAOV
	SUB	BX,BX		; Clear EBX
	MOV	BX,MEG_SUPPORTED/4*4096 ; Load the size of the page tables.
				; Each page table maps 4M of memory, so divide
				;   the number of Meg supported by 4 to get the
				;   number of page tables.  Each page table is
				;   4K in size, so multiply by 4K.
	DATAOV
	SUB	AX,BX		; Subtract the size needed for the page tables
				;   from the address of the page directory to
				;   get the address of the first page table.
	ADD	AX,7		; Set the present bit and access rights.
				;   This converts the address to a valid entry
				;   for the page directory.
	DATAOV
	MOV	NORMPAGE,AX	; Save for later
	MOV	CX,MEG_SUPPORTED/4 ; Load the number of page tables into CX
	DATAOV
	SUB	BX,BX		; Clear EBX
	MOV	BX,1000H	; Set up 4k increment
;
; Now we load the page directory.  EAX contains the address of the first
; page table, EBX contains 4K, CX contains the number of page tables, and
; ES:EDI (32 bit DI reg.) points to the first page directory entry.  Now what
; we do is stuff EAX into the 32bits pointed to by EDI.  EDI is then auto-
; incremented by four bytes, because of the 32 bit stuff, and points to the
; next page directory entry.  (Page directory and page table entries are four
; bytes long.)	Then we add the 4K in EBX to the address in EAX making EAX
; the address of the next page table.  This is done for the number of page
; table entries in CX.	Pretty slick, huh?
;
LPT:
	DATAOV			; Stuff the page table address into the
	STOSW			;   page directory
	DATAOV			; Add 4K to the page table address in EAX
	ADD	AX,BX		;   so that it contains the address of the
				;   next page table
	LOOP	LPT		; Do it again

; Now calcuate the offset from our code segment of the page tables

	DATAOV
	SUB	BX,BX		; Clear EBX
	MOV	BX,HIGH_SEG	; Load our current code segment
	DATAOV
	SHL	BX,4		; Convert paragraphs to bytes
	DATAOV			; Load EAX with the address of the first
	MOV	AX,NORMPAGE	;   page table
	DATAOV
	SUB	AX,BX		; Convert EAX to an offset
	AND	AL,0F8H 	; AND off the access rights
	MOV	PGTBLOFF,AX	; Save for later

;------------------------------------------------------------------------------;
;   Initialize the page tables						       ;
;------------------------------------------------------------------------------;

	MOV	DI,PGTBLOFF	      ; ES:DI points to the first page table
	DATAOV
	SUB	AX,AX		      ; Zero EAX
	ADD	AX,7		      ; Set the present and access rights
	MOV	CX,MEG_SUPPORTED/4*1024 ; Load CX with the number of page table
				      ;   entries to initialize.  As mentioned
				      ;   above, the number of page tables =
				      ;   number of Meg / 4.  There are 1K
				      ;   entries per table so multiply by 1K
	DATAOV
	SUB	BX,BX		      ; Clear EBX
	MOV	BX,1000H	      ; Set up 4k increment
;
; As with the page directory, we use a tight loop to initialize the page tables.
; EAX contains the address of the first page frame, which is 0000, plus the
; access rights.  EBX contains a 4K increment.	ES:DI points to the first entry
; in the first page table.  CX contains the number of page table entries to
; initialize.  The stuff and increment works the same as for the page directory
; with an added touch.	Note that this does all the page tables in one fell
; swoop.  When we finish stuffing the last address into the first page table
; the next place we stuff is into the first entry in the second page table.
; Since our page tables are back to back we can just zoom up the page tables
; incrementing by 4K as we go and thus initialize all the page tables in one
; fell swoop.
;
BPT:
	DATAOV			      ; Stuff the page frame address into the
	STOSW			      ;   page table
	DATAOV
	ADD	AX,BX		      ; Next 4k page frame
	LOOP	BPT

;------------------------------------------------------------------------------;
;   Now set up the first 64K over 1M to point to point to the first 64K        ;
;   in low memory to simulate the segment wrap over 1M. 		       ;
;   For now will set it up to point to itself and try to get DOS to load       ;
;   the device driver up there.  Will find out if anyone tries to alter        ;
;   it because it will be marked for system use only.			       ;
;------------------------------------------------------------------------------;

	MOV	DI,1024 	      ; 1M offset into page table
	ADD	DI,PGTBLOFF	      ; Page table offset
	MOV	AX,10H		      ; Set EAX to contain 1M address by loading
	DATAOV			      ;   it with 10H and shifting it 16 bits to
	SHL	AX,16		      ;   get 00100000.  (Same as 10000:0)
	ADD	AX,5		      ; Present, system use, read only
	MOV	CX,16		      ; 16 entries = 64k
BPT2:
	DATAOV
	STOSW			      ; Stuff the address in the page table
	DATAOV
	ADD	AX,BX		      ; Next 4k page frame
	LOOP	BPT2

PAGE
;------------------------------------------------------------------------------;
;	Build the Global Descriptor Table and load the GDT register.	       ;
;------------------------------------------------------------------------------;
	CALL	GDT_BLD

	MOV	DI,GDT_PTR	      ; Get the offset of the GDT descriptor
	ADD	DI,GDT_LOC	      ;   located in the GDT
	MOV	BP,DI		      ; Transfer the offset to BP
	LGDT	ES:FWORD PTR[BP]      ; Put the descriptor for the GDT into
				      ;   the GDT register

PAGE
;------------------------------------------------------------------------------;
;	Build and initialize the system Interrupt Descriptor Table,	       ;
;	then load the IDT register.					       ;
;------------------------------------------------------------------------------;
	CALL	SIDT_BLD

	MOV	DI,MON_IDT_PTR	      ; Get the offset of the IDT descriptor
	ADD	DI,GDT_LOC	      ;   located in the GDT
	MOV	BP,DI		      ; Transfer the offset to BP

	LIDT	ES:FWORD PTR[BP]      ; Put the descriptor for the IDT into
				      ;   the IDT register

PAGE
;------------------------------------------------------------------------------;
;	At this point we prepare to switch to virtual mode.  The first	       ;
;	instruction after the LMSW that causes the switch must be a	       ;
;	jump far to set a protected mode segment selector into CS.	       ;
;------------------------------------------------------------------------------;

	MOV	AX,VIRTUAL_ENABLE     ; Machine status word needed to
	LMSW	AX		      ;  switch to virtual mode

	JUMPFAR DONE,SYS_PATCH_CS     ; Must purge pre-fetch queue
				      ;   and set selector into CS
DONE:
PAGE
;------------------------------------------------------------------------------;
; Initialize all the segment registers					       ;
;------------------------------------------------------------------------------;

	MOV	AX,SYS_PATCH_DS       ; Load DS, ES, and SS with the selector
	MOV	DS,AX		      ;   for our data area.  This is the same
	MOV	ES,AX		      ;   as our code area but has read/write
				      ;   access.
	MOV	SS,AX
	MOV	SP,OFFSET SP_INIT

	PUSH	0002H		      ; Clean up our flags.  Turn off all bits
	POPF			      ;   except the one that is always on.

;------------------------------------------------------------------------------;
; Load the LDTR to avoid faults 					       ;
;------------------------------------------------------------------------------;

	MOV	AX,SCRUBBER.TSS_PTR   ; Load DS with the data descriptor for
	MOV	DS,AX		      ;   the virtual machine's TSS
	MOV	AX,SCRUBBER.VM_LDTR   ; Get the LDTR for virtual machine
	MOV	DS:VM_LDT,AX	      ; Set LDTR in TSS
	LLDT	AX		      ; Set the LDTR.  Temporary for now.

; Have to always have space allocated for the dispatch task TSS

	MOV AX,SCRUBBER.VM_TR	      ; Low mem gets clobbered without this @P5C
	LTR AX			      ; Set current Task Register
				      ; This TSS is located right after the IDT

PAGE
;------------------------------------------------------------------------------;
;	Now we initialize the TSS (Task State Segment) for the one and only    ;
;	virtual 8086 task.  This task encompasses everything that runs in real ;
;	mode.  First we clear the TSS and its I/O bit map.  Then we initialize ;
;	the bit map for all the I/O ports we want to trap.  Then we set up the ;
;	registers for the V86 task.  These registers are given the same values ;
;	as we got on entry.  IP is set to point to TEST_EXIT.		       ;
;------------------------------------------------------------------------------;

	MOV	AX,SCRUBBER.TSS_PTR   ; Load ES and DS with the descriptor
	MOV	DS,AX		      ;   for the VM's TSS with read/write
	MOV	ES,AX		      ;   access rights
	CLD
	MOV	DI,0		      ; Point ES:DI to the beginning of the TSS
	MOV	AX,0		      ; Clear AX
	MOV	BX,0		      ; Clear BX
	MOV	CX,TSS_386_LEN	      ; Load CX with the length of the TSS
	REP	STOSB		      ; Clear the TSS
	MOV	CX,TSS_BM_LEN	      ; Load CX with the length of the I/O bit
				      ;   map.	The bit map immediately follows
				      ;   the TSS and is in the TSS segment.
	REP	STOSB		      ; Clear the bit map
	MOV	AL,0FFH 	      ; Intel requires this byte
	STOSB

;
; Now set up the bit map.  Turn on bits for I/O ports that we want to trap.
;

	MOV	DI,0+TSS_386_LEN      ; Set bits 0,2,4,6 to 1 - DMA ports
	MOV	AL,055H
	STOSB
	MOV	DI,1+TSS_386_LEN      ; Set C to 1 - DMA port
	MOV	AL,010H
	STOSB
	MOV	DI,3+TSS_386_LEN      ; Set 18,1A to 1 - DMA ports
	MOV	AL,005H
	STOSB
	MOV	DI,16+TSS_386_LEN     ; Set 80-8f to 1s - DMA page ports
	MOV	AL,0FFH 	      ;  + manufacturing port for ctl-alt-del
	STOSB
	STOSB
	MOV	DI,0680H/8+TSS_386_LEN ; Set Roundup manuf. port to 1
	MOV	AL,001H
	STOSB
	MOV	DI,31A0H/8+TSS_386_LEN ; Set 31a0-31a7 to 1s (XMA)
	MOV	AL,0FFH
	STOSB

	MOV	WORD PTR [BX].ETSS_BM_OFFSET,TSS_386_LEN
				      ; Put the bit map offset in the TSS
	MOV	WORD PTR [BX].ETSS_SP0,OFFSET SP_INIT
				      ; Put our SP as the SP for privilege
				      ;   level 0
	MOV	WORD PTR [BX].ETSS_SS0,SYS_PATCH_DS
				      ; Put our SS as the SS for privilege
				      ;   level 0

; Next we set up the segment registers

	MOV  WORD PTR [BX].ETSS_GS,SEG PROG	    ; GS - our code segment
	MOV  WORD PTR [BX].ETSS_FS,SEG PROG	    ; FS - our code segment
	MOV  WORD PTR [BX].ETSS_DS,SEG PROG	    ; DS - our code segment
	MOV  WORD PTR [BX].ETSS_ES,SEG PROG	    ; ES - our code segment

; Next the SS,SP

	MOV  AX,CS:REAL_SS	; Set the real mode SS as the SS for the task
	MOV  WORD PTR [BX].ETSS_SS,AX
	MOV  AX,CS:REAL_SP	; Set the real mode SP as the SP for the task
	MOV  WORD PTR [BX].ETSS_SP,AX

; The flags register

	MOV  WORD PTR [BX].ETSS_FL2,2	 ; Set the VM flag.  Task is a V86 task.
	MOV  WORD PTR [BX].ETSS_FL,0202H ; Set interrupts enabled

; Set up CS and IP

	MOV  AX,CS:REAL_CS	; Set the real mode CS as the CS for the task
	MOV  WORD PTR [BX].ETSS_CS,AX ; This is the CS we got when we loaded
				;   in low memory, before relocating
	MOV  AX,OFFSET PROG:TEST_EXIT ; Set IP to the label TEST_EXIT below.
	MOV  WORD PTR [BX].ETSS_IP,AX

; The LDTR

	MOV  WORD PTR [BX].ETSS_LDT,SCRUBBER.VM_LDTR

; And finally, CR3, the page directory base register

	CMOV	EAX,CR3 	; Get CR3
	DATAOV
	MOV  WORD PTR [BX].ETSS_CR3,AX ; Save it in the TSS

PAGE
;------------------------------------------------------------------------------;
;	Now initialize our wonderful XMA page tables.  Each table maps 4M.     ;
;	There is one table for each XMA bank since 4M is enough to map the     ;
;	1M address space.  All the XMA tables are initialized to point to      ;
;	the real memory at 0 to 4M.  This is done by just copying the page     ;
;	table entry for 0 to 4M that was initialized above.		       ;
;------------------------------------------------------------------------------;

	MOV	AX,SYS_PATCH_DS    ; Load DS with the selector for our data
	MOV	DS,AX
	MOV	SI,PGTBLOFF	   ; DS:SI point to the real page table for 0-4M
	MOV	AX,XMA_PAGES_SEL   ; Load ES with the selector for the XMA pages
	MOV	ES,AX
	SUB	DI,DI		   ; ES:DI point to the first XMA page table
	MOV	CX,2048 	   ; Copy 4K / 2 since we're copying words
	REP	MOVSW		   ; Copy the first XMA page table
;
; Now ES:DI points to the second XMA page table.  Set DS:SI to point to the
; first XMA page table as the source for the copy.  Now we can put a count
; of 15 page tables in CX.  After each page is copied it is used as the source
; for the next page.  This method lets us zip up the page tables initializing
; them all to be the same as the original page table for 0 - 4M.
;
	MOV	AX,XMA_PAGES_SEL   ; Load DS with the selector for the XMA page
	MOV	DS,AX		   ;   tables
	SUB	SI,SI		   ; DS:SI points to the first XMA page table
	MOV	CX,2048*15	   ; Copy 15 more page tables
	REP	MOVSW		   ; Copy to the other 15 XMA ID'S page tables

;									     D1A
; Set the first page directory entry to point to the page table for bank 0.  D1A
; This is another way of saying, "Let's make bank 0 the active bank."  We    D1A
; are now emulating the  XMA 2 card along with its initialization device     D1A
; driver, INDXMAA.SYS.	When the device driver exits, it leaves the XMA 2    D1A
; card enabled and set to bank 0.  Therefore, we must do the same.	     D1A
;									     D1A
				   ;					     D1A
	MOV	AX,SYS_PATCH_DS    ; Load DS and ES with our data segment   @D1A
	MOV	DS,AX		   ;   selector 			    @D1A
	MOV	ES,AX		   ;					    @D1A
	MOV	DI,SGTBLOFF	   ; Point ES:DI to the first page	    @D1A
				   ;   directory entry			     D1A
	DATAOV			   ; Load AX with the page directory entry  @D1A
	MOV	AX,XMAPAGE	   ;   for the first XMA page table	    @D1A
	DATAOV			   ; Stuff the address of the page table    @D1A
	STOSW			   ;   for bank 0 into the page directory   @D1A

PAGE
;------------------------------------------------------------------------------;
;	And now, the moment you've all been waiting for -- TURN ON THE PAGING  ;
;	MECHANISM!!!							       ;
;------------------------------------------------------------------------------;

	CMOV	EAX,CR0 	; Get CR0				    @P5A
	MOV	BX,8000H	; Set up BX to OR on the Paging Enable bit  @P5C
	DATAOV
	SHL	BX,16		; It's the one all the way on the left      @P5C
	DATAOV			;					    @P5A
	OR	AX,BX		; Set the paging enabled bit		    @P5A
	OR	AL,02H		; Set co-processor bit on		    @P5A
	AND	AL,0F7H 	; Turn off Task Switch bit		    @P5C
	CMOV	CR0,EAX 	; Here we go...

; Make sure high order bits of ESP are zero - a1 errata

	MOV	AX,SP		; Save SP in AX 'cause it changes when we do...
	PUSH	0		;   this PUSH.	Push 0 for high 16 bits of ESP
	PUSH	AX		; Push low 16 bits of SP
	DATAOV
	POP	SP		; Pop 32 bit ESP!

PAGE
;------------------------------------------------------------------------------;
;	Now we give control back to the V86 task by setting up the stack    P5C;
;	for an IRET back to the V86 task.  This requires putting the V86    P5C;
;	task's segment registers, SS and ESP, and the EFLAGS, CS and IP on  P5C;
;	the stack.  The 80386 puts all these values on the stack when it    P5C;
;	interrupts out of V86 mode, so it expects them there on an IRET     P5C;
;	back to V86 mode.  But really we are giving control back to	       ;
;	ourself.  The CS:IP on the stack point to the label TEST_EXIT	       ;
;	below, but it is in the copy of the emulator that was originally       ;
;	loaded, not the copy that was relocated to high memory and is now      ;
;	running in protect mode.  This clever trick will result in the	       ;
;	original copy of the emulator returning to DOS which will continue     ;
;	to load the rest of the system.  The system will come up completely    ;
;	unaware that it is running in a small universe of a V86 task which     ;
;	is being monitored by the XMA emulator. 			       ;
;------------------------------------------------------------------------------;


	MOV	AX,SCRUBBER.TSS_PTR   ; Load DS with the descriptor for the @P5A
	MOV	DS,AX		      ;   VM's TSS with read/write access   @P5A
	MOV	BX,0		      ;   VM's TSS with read/write access   @P5A
;									     P5A
; Set up our stack for an IRET to the V86 task.  This is an inter-level      P5A
; IRET to a V86 task so we need the V86 task's SS, ESP, ES, DS, FS and GS    P5A
; as well as his EFLAGS, EIP and CS.					     P5A
;									     P5A
	DATAOV			      ; 				    @P5A
	PUSH	WORD PTR [BX].ETSS_GS ; Put V86 task's GS on the stack      @P5A
	DATAOV			      ; 				    @P5A
	PUSH	WORD PTR [BX].ETSS_FS ; Put V86 task's FS on the stack      @P5A
	DATAOV			      ; 				    @P5A
	PUSH	WORD PTR [BX].ETSS_DS ; Put V86 task's DS on the stack      @P5A
	DATAOV			      ; 				    @P5A
	PUSH	WORD PTR [BX].ETSS_ES ; Put V86 task's ES on the stack      @P5A
	DATAOV			      ; 				    @P5A
	PUSH	WORD PTR [BX].ETSS_SS ; Put V86 task's SS on the stack      @P5A
	DATAOV			      ; 				    @P5A
	PUSH	WORD PTR [BX].ETSS_SP ; Put V86 task's ESP on the stack     @P5A
	DATAOV			      ; 				    @P5A
	PUSH	WORD PTR [BX].ETSS_FL ; Put V86 task's EFLAGS on the stack  @P5A
	DATAOV			      ; 				    @P5A
	PUSH	WORD PTR [BX].ETSS_CS ; Put V86 task's CS on the stack      @P5A
	DATAOV			      ; 				    @P5A
	PUSH	WORD PTR [BX].ETSS_IP ; Put V86 task's EIP on the stack     @P5A
	DATAOV			      ; 				    @P5A
	IRET			      ; 				    @P5A
				      ; 				    @P5D

TEST_EXIT:			; We are now running in V86 mode
	POP	AX		; Pop the stack until our DEAD delimiter is
	CMP	AX,0DEADH	;   found
	JNE	TEST_EXIT

; Replace the interrupt 15 vector with our handler (INT15F88).		     P7A

	MOV	AH,GET_VECT	; Get the current vector at interrupt 15H   @P7A
	MOV	AL,15H		;					    @P7A
	INT	21H		;					    @P7A

	MOV	CS:CHAINSEG,ES	; Save it in the chaining header in	    @P7A
	MOV	CS:CHAINOFF,BX	;   INT15F88				    @P7A

	MOV	AH,SET_VECT	; Set the entry point of INT15F88 as the    @P7A
	MOV	AL,15H		;   new interrupt 15 vector		    @P7A
	PUSH	CS		;					    @P7A
	POP	DS		;					    @P7A
	MOV	DX,OFFSET INT15F88 ;					    @P7A
	INT	21H		;					    @P7A

; Copy the number of K for extended memory from BUFF_SIZE to EXT_MEM.  This  P7A
; is needed because BUFF_SIZE does not stay resident, EXT_MEM does.	     P7A

	MOV	AX,BUFF_SIZE	;					    @P7A
	MOV	EXT_MEM,AX	;					    @P7A

; Issue the message that says we installed successfully

	MOV	AH,DISPSTRG	; Set AH to DOS display string function     @D0A
	MOV	DX,OFFSET GOODLOAD ;					    @D0A
	PUSH	CS		;					    @D0A
	POP	DS		; DS:DX points to the message		    @D0A
	INT	21H		; Display the message			    @D0A

	RET			; Return to IRPT which called INIT_P1

SUBTTL	Gate A20
PAGE
;------------------------------------------------------------------------------;
; GATE_A20								       ;
;	This routine controls a signal which gates address bit 20.	       ;
;	Bit 2 of port 92H controls the enabling of A20.  If bit 2 is on,    P4C;
;	then A20 is enabled.  Conversely, if bit 2 is off, A20 is disabled. P4C;
;									       ;
;------------------------------------------------------------------------------;

; Equates for the Gate A20 enable

ENABLE_A20	EQU	02H	; Bit 2 of port 92H turns on A20	    @P4C

GATE_A20    PROC

	IN	AL,92H		; Get the current value of port 92	    @P4A
	OR	AL,ENABLE_A20	; Turn on the bit to enable A20 	    @P4A
	OUT	92H,AL		; Send it back out to port 92		    @P4A
	RET
				;					  15@P4D
GATE_A20	ENDP

SUBTTL	GET_PARMS parameter line scan
PAGE
;------------------------------------------------------------------------------;
; GET_PARMS								       ;
; This procedure converts the numeric parameter following the DEVICE statement ;
; in the CONFIG.SYS file to a binary number and saves it in BUFF_SIZE.	The    ;
; number is rounded up to the nearest 16K boundary.			       ;
;									       ;
; Register usage:							       ;
;	DS:SI indexes parameter string					       ;
;	AL contains character from parameter string			       ;
;	CX value from GET_NUMBER					       ;
;									       ;
;------------------------------------------------------------------------------;

	ASSUME	DS:NOTHING	; DS:BX point to Request Header

GET_PARMS PROC

	PUSH	DS		; Save DS
	push	bx		; save bx					;an000; dms;

	LDS	SI,RH.RH0_BPBA	; DS:SI point to all text after "DEVICE="
				;   in CONFIG.SYS
	XOR	AL,AL		; Start with a null character in AL.

;------------------------------------------------------------------------------;
; Skip until first delimiter is found.	There may be digits in the path string.;
;									       ;
; DS:SI points to  \pathstring\386XMAEM.SYS nn nn nn			       ;
; The character following 386XMAEM.SYS may have been changed to a null (00H).  ;
; All letters have been changed to uppercase.				       ;
;------------------------------------------------------------------------------;

GET_PARMS_A:
	CALL	GET_PCHAR	; Get a character from the parameter string
	JZ	Get_Parms_Null	; The zero flag is set if the end of the line
				;   is found.  If so, then exit.

; Check for various delimeters

	OR	AL,AL		; Null
	JZ	GET_PARMS_B
	CMP	AL,' '          ; Blank
	JE	GET_PARMS_B
	CMP	AL,','          ; Comma
	JE	GET_PARMS_B
	CMP	AL,';'          ; Semi-colon
	JE	GET_PARMS_B
	CMP	AL,'+'          ; Plus sign
	JE	GET_PARMS_B
	CMP	AL,'='          ; Equals
	JE	GET_PARMS_B
	CMP	AL,TAB		; Tab
	JNE	GET_PARMS_A	; Skip until delimiter or CR is found

GET_PARMS_B:			; Now pointing to first delimiter
	CALL	SKIP_TO_DIGIT	; Skip to first digit
	JZ	Get_Parms_C	; Found EOL, no digits remain

	CALL	GET_NUMBER	; Extract the digits and convert to binary
	jmp	Get_Parms_Found ; Parm found

Get_Parms_Null:

	xor	cx,cx		; set cx to 0					;an000; dms;

Get_Parms_Found:

	mov	bx,cx		; put cx value in bx				;an000; dms;

	cmp	cx,0		; 0 pages requested?				;an000; dms;
	jne	Get_Parm_Max	; allocate maximum number			;an000; dms;
		MOV	CS:BUFF_SIZE,0; Store buffer size
		jmp	Get_Parms_C

Get_Parm_Max:

	cmp	bx,64		; >= 64 pages requested?			;an000; dms;
	jnb	Get_Parms_64_Pg ; yes - continue				;an000; dms;
		mov	dx,offset Small_Parm	; Parm < 64 and > 0		;an000; dms;
		mov	ah,Dispstrg		; Display the welcome message.	;an000; dms;
		push	ds			; Save DS			;an000; dms;
		push	cs			;				;an000; dms;
		pop	ds			; DS:DX points to the message	;an000; dms;
		int	21h			; Display the message		;an000; dms;
		pop	ds			; Restore DS			;an000; dms;
		stc				; flag an error occurred	;an000; dms;
		jmp	Get_Parms_C		; exit routine			;an000; dms;

Get_Parms_64_Pg:

	mov	ax,bx		; prepare to adjust to Kb value 		;an000; dms;
	mov	cx,10h		; 16Kb per page 				;an000; dms;
	xor	dx,dx		; clear high word				;an000; dms;
	mul	cx		; get Kb value					;an000; dms;

	mov	bx,ax		; store page Kb value in bx			;an000; dms;
	add	bx,128		; adjust for emulator code

	mov	ah,88h		; get number of 1k blocks above 1Mb		;an000; dms;
	int	15h		;

	sub	ax,bx		; get number of blocks to allocate for extended ;an000; dms;
	jnc	Get_Parms_Ext	; set extended memory value in buff size	;an000; dms;
		mov	dx,offset No_Mem	; not enough memory for parm
		mov	ah,Dispstrg		; Display the welcome message.	;an000; dms;
		push	ds			; Save DS			;an000; dms;
		push	cs			;				;an000; dms;
		pop	ds			; DS:DX points to the message	;an000; dms;
		int	21h			; Display the message		;an000; dms;
		pop	ds			; Restore DS			;an000; dms;
		stc				; flag an error 		;an000; dms;
		jmp	Get_Parms_C		; exit routine			;an000; dms;

Get_Parms_Ext:

	MOV	CS:BUFF_SIZE,ax ; Store buffer size
	clc

GET_PARMS_C:
	pop	bx		; restore bx					;an000; dms;
	POP	DS		; Restore DS

	RET

;------------------------------------------------------------------------------;
; GET_PCHAR -- Get a character from the parameter string into AL	       ;
;------------------------------------------------------------------------------;

GET_PCHAR PROC
	CMP	AL,CR		; Carriage return already encountered?
	JE	GET_PCHAR_X	; Don't read past end of line
	LODSB			; Get character from DS:SI, increment SI
	CMP	AL,CR		; Is the character a carriage return?
	JE	GET_PCHAR_X	; Yes, leave the zero flag set to signal end
				;   of line
	CMP	AL,LF		; No, is it a line feed?  This will leave the
				;   zero flag set if a line feed was found.
GET_PCHAR_X:
	RET

GET_PCHAR ENDP

;------------------------------------------------------------------------------;
; CHECK_NUM -- Check if the character in AL is a numeric digit, ASCII for      ;
;	       0 - 9.  The zero flag is set if the character is a digit,       ;
;	       otherwise it is reset.					       ;
;------------------------------------------------------------------------------;

CHECK_NUM PROC
	CMP	AL,'0'          ; If character is less than a "0" then it is not
	JB	CHECK_NUM_X	;   a number, so exit

	CMP	AL,'9'          ; If character is greater than a "9" then it is
	JA	CHECK_NUM_X	;   not a number, so exit

	CMP	AL,AL		; Set the zero flag to show it is a number
CHECK_NUM_X:
	RET			; Zero flag is left reset if character is not
CHECK_NUM ENDP			;   a number

;------------------------------------------------------------------------------;
; SKIP_TO_DIGIT -- Scan the parameter string until a numeric character is      ;
;		   found or the end of the line is encountered.  If a numeric  ;
;		   character is not found then the zero flag is set.  Else if  ;
;		   a character was found then the zero flag is reset.	       ;
;------------------------------------------------------------------------------;

SKIP_TO_DIGIT PROC
	CALL	CHECK_NUM	; Is the current character a digit?
	JZ	SKIP_TO_DIGIT_X ; If zero flag is set then it is a number

	CALL	GET_PCHAR	; Get the next character from the line
	JNZ	SKIP_TO_DIGIT	; Loop until first digit or CR or LF is found
	RET			; Fall through to here if digit not found

SKIP_TO_DIGIT_X:
	CMP	AL,0		; Digit found, reset the zero flag to show digit
	RET			;   was found
SKIP_TO_DIGIT ENDP

;------------------------------------------------------------------------------;
; GET_NUMBER -- Convert the character digits in the parameter string to a      ;
;		binary value.  The value is returned in CX, unless the	       ;
;		calculation overflows, in which case return a 0.  The next     ;
;		character after the digits is left in AL.		       ;
;------------------------------------------------------------------------------;

C10	   DW	10
GN_ERR	   DB	?		; Zero if no overflow in accumulation

GET_NUMBER PROC 		; Convert string of digits to binary value
	XOR	CX,CX		; Clear CX, the resulting number
	MOV	CS:GN_ERR,CL	; No overflow yet

GET_NUMBER_A:
	SUB	AL,'0'          ; Convert the ASCII character in AL to binary
	CBW			; Clear AH
	XCHG	AX,CX		; Previous accumulation in AX, new digit in CL
	MUL	CS:C10		; DX:AX = AX*10
	OR	CS:GN_ERR,DL	; Any overflow from AX goes into DX.  Any non-
				;   zero value in DL will signal an error
	ADD	AX,CX		; Add the new digit to ten times the previous
				;   digits
	XCHG	AX,CX		; New number now in CX
	CALL	GET_PCHAR	; Get the next character
	CALL	CHECK_NUM	; Check if it is numeric
	JZ	GET_NUMBER_A	; If so, then go back and add this digit to the
				;   result
	CMP	CS:GN_ERR,0	; Did we overflow?
	JE	GET_NUMBER_B	; If not, we're done
	XOR	CX,CX		; Return a zero result if overflow
GET_NUMBER_B:
	RET
GET_NUMBER ENDP

GET_PARMS ENDP

POST	ENDP

PROG	ENDS
	END

