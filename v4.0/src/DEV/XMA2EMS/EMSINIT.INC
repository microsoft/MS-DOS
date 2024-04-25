
;------------------------------------------------------------------------;
;	   Initialization...						 ;
;------------------------------------------------------------------------;

RESR_EXT_PGS   DW    0			;Ext mem reserved here after EMS taken	;an002; dms;

MACH_MODEL_PTR	DD   0F000FFFEh 	;Byte in upper BIOS that indicates @RH1
MODEL_BYTE	DB   (?)		; which system you are on.	   @RH1
PC1		EQU  0FFh		;Values returned for:  PC 1	   @RH1
PC_XT		EQU  0FEh		;   PC XT			   @RH1
XT_AQUARIUS	EQU  0FBH		;   PC Aquarius 		   @RH1
PC_AT		EQU  0FCh		;   PC AT type - AT, PS/2 models   @RH1
					;     50 and 60, etc.
PS2MODEL80	EQU  0F8h		;   386 processor - PS/2 model 80  @RH1

INT15_SEC_MOD	EQU  ES:BYTE PTR [BX+3] ;Secondary model byte		   @RH2
SEC_MOD_TB	EQU  4			; PS/2 Model 50 		   @RH2
SEC_MOD_RR	EQU  5			; PS/2 Model 60 		   @RH2

START_BACMEM_SEG DW  0			;Starting and ending segment addrs
END_BACMEM_SEG	 DW  0			; of memory backed by the XMA card

INIT_ERR	DW   ?			;Initialization error flag	   @RH4
NO_ERROR	EQU  0			;				   @RH4
ERROR		EQU  1			;				   @RH4
			     ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			     ;³ Device driver IOCTL call declares	       ³
			     ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
EMULATOR_DD_NAME   DB	'386XMAEM',0    ;Device driver names for the Emulator
XMAAVIRT_DD_NAME   DB	'INDXMAII',0    ; and WSP's XMA/A init code
DD_FILE_HANDLE	   DW	?		;File handle from opening either DD

REQ_PACKET_STRUC   STRUC		;Generic IOCTL parameter packet
PACKET_LEN	   DW	4		;Packet length (in bytes)
PACKET_FCN	   DW	0		;DD defined function number
PACKET_WORD	   DW	0		;Data area
REQ_PACKET_STRUC   ENDS

REQ_PACKET	   REQ_PACKET_STRUC <>	;


INIT	PROC

	PUSH	CS
	POP	DS			;Get this segment into CS

	MOV	DX,SS			;save stack segment
	MOV	CX,SP			;save stack pointer
	CLI				;ints off during swap
	MOV	AX,CS			;move cs to ss
	MOV	SS,AX			;through ax
	MOV	SP,OFFSET TOP_OF_STACK	;sp to end of code
	STI				;ints back on
	PUSH	DX			;save old ss on new stack
	PUSH	CX			;save old sp on new stack


	MOV	DX,OFFSET WELCOME_MSG	;Print title and copy-right
	MOV	AH,9			;
	INT	21H

	push	ax			;save affected regs			;an000; dms;
	push	bx			;					;an000; dms;
	push	cx			;					;an000; dms;
	push	dx			;					;an000; dms;
	push	si			;					;an000; dms;
	push	di			;					;an000; dms;
	push	ds			;					;an000; dms;

	CALL	GET_PARMS		;Get the user parameters

	pop	ds			;restore affected regs			;an000; dms;
	pop	di			;					;an000; dms;
	pop	si			;					;an000; dms;
	pop	dx			;					;an000; dms;
	pop	cx			;					;an000; dms;
	pop	bx			;					;an000; dms;
	pop	ax			;					;an000; dms;

	JE	PARMS_OK
	    PUSH    CS
	    POP     DS
	    MOV     DX,OFFSET PARM_ERR_MSG  ;Print message indicating
	    MOV     AH,9		    ; parameter error using
	    INT     21H 		    ; DOS function call
	    MOV     DX,OFFSET NOT_INSTL_MSG ;Print that the EMS driver
	    MOV     AH,9		    ; has not been installed
	    INT     21H 		    ;
	    JMP     GENERAL_FAILURE	;indicate general failure
PARMS_OK:

			;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			;³ Does the system use the XMA Emulator?	       ³
			;³  (PS/2 model 80 with 80386 processor)	       ³
			;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PUSH	DS			;				   @RH1
	LDS	SI,MACH_MODEL_PTR	; DS:SI points to model descriptor @RH1
	MOV	AL,DS:BYTE PTR [SI]	;  byte (F000:FEEE)		   @RH1
	MOV	MODEL_BYTE,AL		;				   @RH1
	POP	DS			;				   @RH1

	CMP	MODEL_BYTE,PS2MODEL80	;If the model byte is for a	   @RH7
	JE	FIND_EMULATOR		; PS/2 model 80			   @RH7
	JMP	NOT_PS2MODEL80		; then attempt to open the 80386   @RH7
FIND_EMULATOR:				; XMA Emulator device driver	   @RH7
	MOV	AX,3D00h		; (INDXMAEM.SYS)		   @RH7
	LEA	DX,EMULATOR_DD_NAME	;				   @RH7
	INT	21h			;No carry means open successful    @RH7
	JNC	EMUL_INSTALLED		; and the DD is present 	   @RH7
	    PUSH    CS			    ;Else open failed		   @RH7
	    POP     DS			    ;Print message indicating	   @RH7
	    MOV     DX,OFFSET NO_EMUL_MSG   ; emulator not present	   @RH7
	    MOV     AH,9		    ;dos prt string		   @RH7
	    INT     21H 		    ;write message		   @RH7
	    MOV     DX,OFFSET NOT_INSTL_MSG ;Print that the EMS driver	   @RH7
	    MOV     AH,9		    ; has not been installed	   @RH7
	    INT     21H 		    ;				   @RH7
	    JMP     GENERAL_FAILURE	    ;indicate general failure	   @RH7
EMUL_INSTALLED: 			;Emulator is present		   @RH7
	MOV	DD_FILE_HANDLE,AX	;Do IOCTL to find # of XMA blocks  @RH7
	MOV	BX,AX			;Emulator DD handle in BX	   @RH7
	MOV	AX,440Ch		;Handle generic IOCTL fcn code	   @RH7
	XOR	CH,CH			;CH = 0 means "unknown"            @RH7
	MOV	CL,60h			;CL = 40h means set device info    @RH7
	PUSH	CS			;   = 60h means get device info    @RH7
	POP	DS			;				   @RH7
	LEA	DX,REQ_PACKET		;DS:DX -> generic IOCTL packet	   @RH7
	INT	21h			;Issue the generic IOCTL	   @RH7
	JNC	EMUL_VER_GOOD		    ;No carry means the right	   @RH7
	    PUSH   CS			    ; version of the Emulator was  @RH7
	    POP    DS			    ; installed (can handle IOCTL) @RH7
	    MOV    DX,OFFSET WRONG_EMUL_MSG ;Otherwise print message	   @RH7
	    MOV    AH,9 		    ; indicating incorrect version @RH7
	    INT    21H			    ; of the Emulator detected	   @RH7
	    MOV    DX,OFFSET NOT_INSTL_MSG  ;Print that the EMS driver	   @RH7
	    MOV    AH,9 		    ; has not been installed	   @RH7
	    INT    21H			    ;				   @RH7
	    JMP    GENERAL_FAILURE	    ;indicate general failure	   @RH7
EMUL_VER_GOOD:
	MOV	AX,REQ_PACKET.PACKET_WORD ;Get the last available XMA block@RH7
	INC	AX			; number from the emulator...add 1 @RH7
	XOR	DX,DX			; to calc total XMA blocks and	   @RH7
	DIV	BLOCKS_PER_PAGE 	; convert it to EMS pages	   @RH7
	MOV	TOTAL_SYS_PAGES,AX	;Set the number of total 16K pages @RH7
	MOV	TOTAL_EMS_PAGES,AX	; (before and after mem backing)   @RH7
	MOV	FREE_PAGES,AX		; and the pages free for useage    @RH7
	MOV	START_BACMEM_SEG,0	;Mark from 0-640K as taken to	   @RH7
	MOV	END_BACMEM_SEG,0A000h	; back conventional memory and	   @RH7
	CALL	BACK_CONV_MEM		; adjust TOTAL_EMS_PAGES	   @RH7
	MOV	AX,3E00h		;Close the XMA Emulator device	   @RH7
	MOV	BX,DD_FILE_HANDLE	; driver			   @RH7
	MOV	MEMCARD_MODE,EMUL_VIRT	;Set flag for hardware used	   @RH7
	INT	21h			;				   @RH7
	JMP	INT_67_INSTALL		;Install int 67 vector, end init   @RH7
			;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
NOT_PS2MODEL80:		;³ Does the system use the XMA\A or XMO card?	       ³
			;³  (PS/2 models 50 and 60)			       ³
			;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	CMP	MODEL_BYTE,PC_AT	;If the model byte is for an 'AT'  @RH2
	JE	MODEL_AT		; type (80286 processor), check    @RH2
	JMP	FAMILY_1_MACH		; the secondary model byte to	   @RH2
MODEL_AT:				; see if it's a model that uses    @RH2
	MOV	AH,0C0h 		; the XMA/A or XMO card		   @RH2
	INT	15h			;				   @RH2
	CMP	INT15_SEC_MOD,SEC_MOD_TB;				   @RH2
	JNE	NOT_PS2MODEL50		;				   @RH2
	MOV	NUM_OF_SLOTS,4		; PS2/50 has 4 adapter slots	   @RH2
	JMP	PS2_5060		; Init for XMA/A and XMO	   @RH2
NOT_PS2MODEL50:				;				   @RH2
	CMP	INT15_SEC_MOD,SEC_MOD_RR;If 'AT' but not PS/2 50 or 60,    @RH2
	JE	IS_PS2MODEL60		; then family 1 (uses XMA 1 card)  @RH2
	JMP	FAMILY_1_MACH		;				   @RH2
IS_PS2MODEL60:
	MOV	NUM_OF_SLOTS,8		;PS2/60 has 8 adapter slots  	   @RH2
			     ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
PS2_5060:		     ;³ Machine is a PS/2 Model 50 (TB) or 60 (RR).    ³
			     ;³  Check for the Workstation Program's XMA/A     ³
			     ;³  virtual mode device driver (INDXMAA.SYS).  If ³
			     ;³  present, use only that card in virtual mode.  ³
			     ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MOV	AX,3D00h		;Attempt to open WSP's XMA/A       @RH6
	LEA	DX,XMAAVIRT_DD_NAME	; virtual mode device driver	   @RH6
	INT	21h			;Carry means open failed and the   @RH6
	JC	PS2_5060_REAL		; DD is not present.  Use XMA/A    @RH6
					; in real mode and XMO card.	   @RH6
INDXMAA_INSTALLED:			;Else driver found.  XMA/A virtual @RH6
	MOV	DD_FILE_HANDLE,AX	;Do IOCTL to find # of XMA/A blks  @RH6
	MOV	BX,AX			;INDXMAA.SYS DD handle in BX	   @RH6
	MOV	AX,440Ch		;Handle generic IOCTL fcn code	   @RH6
	XOR	CH,CH			;CH = 0 means "unknown"            @RH6
	MOV	CL,60h			;CL = 40h means set device info    @RH6
	PUSH	CS			;   = 60h means get device info    @RH6
	POP	DS			;				   @RH6
	LEA	DX,REQ_PACKET		;DS:DX -> generic IOCTL packet	   @RH6
	INT	21h			;Issue the generic IOCTL	   @RH6
	JNC	XMAA_VER_GOOD		    ;No carry means the right	   @RH6
	    PUSH   CS			    ; version of the XMAA DD was   @RH6
	    POP    DS			    ; installed (can handle IOCTL) @RH6
	    MOV    DX,OFFSET WRONG_XMAA_MSG ;Otherwise print message	   @RH6
	    MOV    AH,9 		    ; indicating incorrect version @RH6
	    INT    21H			    ; of the XMAA DD detected	   @RH6
	    MOV    DX,OFFSET NOT_INSTL_MSG  ;Print that the EMS driver	   @RH6
	    MOV    AH,9 		    ; has not been installed	   @RH6
	    INT    21H			    ;				   @RH6
	    JMP    GENERAL_FAILURE	    ;indicate general failure	   @RH6
XMAA_VER_GOOD:
	MOV	AX,REQ_PACKET.PACKET_WORD ;Get the last available XMA/A blk@RH6
	INC	AX			; number from the XMA/A DD...add 1 @RH6
	XOR	DX,DX			; to calc total XMA/A blocks and   @RH6
	DIV	BLOCKS_PER_PAGE 	; convert it to EMS pages	   @RH6
	MOV	TOTAL_SYS_PAGES,AX	;Set the number of total 16K pages @RH6
	MOV	TOTAL_EMS_PAGES,AX	; (before and after mem backing)   @RH6
	MOV	FREE_PAGES,AX		; and the pages free for useage    @RH6
	MOV	START_BACMEM_SEG,0	;Mark from 0-640K as taken to	   @RH6
	MOV	END_BACMEM_SEG,0A000h	; back conventional memory and	   @RH6
	CALL	BACK_CONV_MEM		; adjust TOTAL_EMS_PAGES	   @RH6
	MOV	AX,3E00h		;Close the XMA/A virtual mode	   @RH6
	MOV	BX,DD_FILE_HANDLE	; device driver 		   @RH6
	INT	21h			;				   @RH6
	MOV	MEMCARD_MODE,XMAA_VIRT	;Set hardware flag to XMAA virtual @RH6
	JMP	INT_67_INSTALL		;Install int 67 vector,end init    @RH6

			     ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
PS2_5060_REAL:		     ;³ PS/2 Model 50 or 60 without XMA/A virtual DD.  ³
			     ;³  Use XMA/A card in real mode (Bank ID reg      ³
			     ;³  not used) or XMO card.			       ³
			     ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	CALL	INIT_MOD_50_60		;Init for XMA/A and XMO		   @RH2
	CMP	INIT_ERR,ERROR		;If no error then install the	   @RH2
	JE	PS2_5060_ERROR		; int 67 vector, print msgs	   @RH2
	JMP	INT_67_INSTALL		;				   @RH2
PS2_5060_ERROR:
					      ;Else error in intialization @RH2
	    PUSH    CS			      ;
	    POP     DS			      ;
	    MOV     AH,9		      ; Barf out 1st part of msg   @RH2
	    INT     21H 		      ; set by subproc (DX = ptr)  @RH2
	    MOV     DX,OFFSET NOT_INSTL_MSG   ;Print that the EMS driver   @RH2
	    MOV     AH,9		      ; has not been installed	   @RH2
	    INT     21H 		      ; 			   @RH2
	    JMP     GENERAL_FAILURE	      ;indicate general failure    @RH2


FAMILY_1_MACH:				;Family 1 machine (pre-PS/2)
	mov	rom_scan_type,family1	; set flag for rom scan code - gga
	MOV	START_BACMEM_SEG,04000h ;Memory is backed from 256K to
	MOV	END_BACMEM_SEG,0A000h	; 640K on XMA 1 card
	CALL	PRESTST 		;Insure XMA 1 card is present
	JE	XMA1_FOUND		;Zero flag = 1 means XMA 1 found
	    PUSH    CS			;Else error..get this segment
	    POP     DS			;into ds
	    MOV     DX,OFFSET NOT_FOUND_MSG ;Print message for cannot
	    MOV     AH,9		    ; find adapter
	    INT     21H 		    ;write message
	    MOV     DX,OFFSET NOT_INSTL_MSG ;Print that the EMS driver
	    MOV     AH,9		    ; has not been installed
	    INT     21H 		    ;
	    JMP     GENERAL_FAILURE	;indicate general failure
XMA1_FOUND:
	MOV	MEMCARD_MODE,XMA1_VIRT	;Indicate an XMA 1 card present    @RH2
	CALL	TRY4MEG 		;determine the size of the XMA memory card

	PUSH	CS
	POP	DS
	MOV	DX,OFFSET DGS_START_MSG ;start of diagnostics message
	MOV	AH,9			;dos prt string
	INT	21H			;starting diagnostics message
	CALL	CUR_POS 		;save cursor position for KB OK msg

	MOV	DX,MODE_REG		;determine if this is a warm start
	IN	AL,DX			;read mode reg
	AND	AL,WARM_MASK		;isolate warm start bit
	JZ	DO_XMA1DIAG		;If off perform full XMA 1 diags
	MOV	CS:WARM_START,'Y'       ;Else warm start..limited diags
DO_XMA1DIAG:
	CALL	XMA1DIAGS		;Perform XMA 1 diagnostics
	JE	XMA1_OK 		;Zero flag set means all OK
	    PUSH    CS			;Else error..get this segment
	    POP     DS			;into ds
	    MOV     DX,OFFSET XMA1_ERR_MSG  ;'XMA001 Adapter error'
	    MOV     AH,9		    ;dos prt string
	    INT     21H 		    ;write message
	    MOV     DX,OFFSET NOT_INSTL_MSG ;Print that the EMS driver
	    MOV     AH,9		    ; has not been installed
	    INT     21H 		    ;
	    JMP     GENERAL_FAILURE	;indicate general failure
XMA1_OK:
	PUSH	CS			;get this segment
	POP	DS			;into ds
	MOV	DX,OFFSET DGS_END_MSG	;start of message
	MOV	AH,9			;dos prt string
	INT	21H			;write message

;Set XMA in virtual mode to look like it was in real mode
	CALL	VIRT2REAL
;Mark pages used on XMA card to back conventional memory
	CALL	BACK_CONV_MEM


;Set up interrupt 67 vector
INT_67_INSTALL:
;------------------------
; added by GGA
;------------------------
;-------------------------------------------------------------------
	call	romscan 		; just for grins
	jc	ROM_Scan_Fail		; error - prompt user to hit any key	;an000; dms;
	jmp	Skip_Pars		; continue load of XMA2EMS		;an000; dms;

ROM_Scan_Fail:

	PUSH	CS			;set up addressibility			;an000; dms;
	POP	DS			;					;an000; dms;
	MOV	DX,OFFSET Prompt_Msg	;Press any key to continue...		;an000; dms;
	MOV	AH,9			;dos prt string 			;an000; dms;
	INT	21H			;

	mov	ah,07h			;keyboard input without ECHO		;an000; dms;
	int	21h			;wait until input			;an000; dms;
	jmp	General_Failure 	;
;-------------------------------------------------------------------
skip_pars:
;------------------------
; end of adds by GGA
;------------------------

	CALL	INIT_PAL		;Initialize the Page Allocation    @RH8
					; linked List			    RH8
	CALL	STEAL_INT67		;




			;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			;³ Initialize the entries in the Page Allocation List  ³
			;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MOV	CX,TOTAL_SYS_PAGES


;write variables into message string
	PUSH	CS			;get this segment
	POP	ES			;into es
	MOV	DI,OFFSET CONV_PAGES	;ascii string for numb fill pgs
	MOV	AX,END_BACMEM_SEG	;upper limit of fill
	SUB	AX,START_BACMEM_SEG	;minus lower start of fill
	MOV	CL,10
	SHR	AX,CL			;convert to number 16k blocks
	CALL	CNVDECAT

	MOV	DI,OFFSET RES_PAGES	;ascii string for pinta reserved pages
	MOV	AX,STARTING_BLOCK	;number of 4k pages res for pinta
	SHR	AX,1
	SHR	AX,1			;convert to 16k pages
	CALL	CNVDECAT

	MOV	DI,OFFSET EMS_PAGES	;ascii string available ems pages
	MOV	AX,FREE_PAGES		;free pages
	CALL	CNVDECAT

	MOV	DI,OFFSET PF_START	;ascii string page frame
	MOV	AX,PAGE_FRAME_STA	;page frame
	CALL	CNVHEXAT

;gga	MOV	DX,OFFSET PAGE_FRAME_MSG ;start of message
;gga	MOV	AH,9			;dos prt string
;gga	INT	21H			;status msg1

	CMP	STARTING_BLOCK,0
;	$IF	A
	JNA $$IF117
	    MOV     DX,OFFSET RESERVE_MSG ;start of message
	    MOV     AH,9		;dos prt string
	    INT     21H 		;status msg2
;	$ENDIF
$$IF117:

;gga	MOV	DX,OFFSET AVAIL_MSG	;start of message
;gga	MOV	AH,9			;dos prt string
;gga	INT	21H			;status msg3

;indicate that the card has been tested
	MOV	DX,MODE_REG
	IN	AL,DX			;read mode reg
	OR	AL,WARM_MASK		;turn on warm start bit
	OUT	DX,AL			;write it back

	call	Calc_INT15_Space	;calculate remaining INT 15h space	;an000; dms;
	call	Steal_INT15		;hook INT 15h				;an000; dms;
	call	Steal_Int13		;hook INT 13h				;an004; dms;

	JMP	COMMON_EXIT_PATH


GENERAL_FAILURE:

	LDS	BX,CS:RH_PTRA		;ELSE ...
	MOV	AX,STAT_GENFAIL 	;INDICATE A GENERAL FAILURE
	MOV	RH.RHC_STA,AX		;WRITE IT TO RH STATUS
;------------------------
;	adds by GGA
;------------------------
	xor	ax,ax			; zero segment and offset
	mov	rh.rh0_endo,ax		; offset of ending addr
	push	cs
	pop	ax
	mov	rh.rh0_ends,ax		; segment of ending addr

	mov	rh.rh0_err,0ffh 	; error flag for DOS

	mov	rh.rh0_nun,al		; = 0 causes installation failure

	jmp	skip_size
;------------------------
COMMON_EXIT_PATH:
;move cursor to next line so other messages are clear
	PUSH	CS			;get cs
	POP	DS			;into ds
	MOV	DX,OFFSET NEXT_LINE + 1 ;get offset of string
	MOV	AH,9			;dos print string
	INT	21H

	LDS	BX,CS:RH_PTRA		;ADDRESSABILITY INTO RH
	MOV	AX,OFFSET RESIDENT + STACK_SIZE + 100H
	MOV	RH.RH0_ENDO,AX		;OFFSET OF ENDING ADDR
	PUSH	CS
	POP	AX
	MOV	RH.RH0_ENDS,AX		;OFFSET OF ENDING ADDR

skip_size:				; gga

	POP	CX			;recover old ss
	POP	DX			;recover old sp
	CLI				;ints off during swap
	MOV	SP,CX			;restore old sp
	MOV	SS,DX			;restore old ss
	STI				;ints back on


	RET
INIT	ENDP

;-----------------------------------------------------------------------;
;	STEAL_INT67 changes the INT 67H vector to point to this 	;
;	Memory Manager to field subsequent calls.			;
;-----------------------------------------------------------------------;
STEAL_INT67 PROC
	PUSH	DS
	XOR	AX,AX
	MOV	DS,AX			;set DS = 0
	ASSUME	DS:INT_VEC
	CLI				;disable interrupts
	LES	DI,DS:EMS_VEC		;get addressing into vector
	MOV	DS:EMS_VECO,OFFSET EMS_INT67 ;offset of new INT routine
	MOV	DS:EMS_VECS,CS		;segment of new INT routine
	STI				;enable interrupts again
	POP	DS			;restore DS
	RET
STEAL_INT67 ENDP

;-----------------------------------------------------------------------;
;	VIRT2REAL puts the XMA into 'virtual' mode with the translate   ;
;	table written such that memory is mapped just as it was 	;
;	in 'real' mode. (Either 256-640k or 512-640k reamains fixed     ;
;	for all ID's)                                                   ;
;									;
;		     all registers are preserved			;
;									;
;-----------------------------------------------------------------------;
VIRT2REAL PROC
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DS			;save these registers

	PUSH	CS			;get this segment
	POP	DS			;into ds
;inhibit all of XMA memory before going into virtual mode
	XOR	AX,AX			;start at segment 0
	XOR	BL,BL			;inhibit
	MOV	CX,1024/4		;all 4k blocks in pc space
	CALL	INHIBLK
;now map virtual mode to look like real mode
	MOV	AX,START_BACMEM_SEG	;starting 'fill' segment
	MOV	DX,AX			;get it into dx
	XCHG	DH,DL			;and shr 8 to convert it to 4k block #
	XOR	BH,BH			;start at task ID=0
	MOV	BL,1			;enable
	MOV	CX,16			;do for all 16 task ID's
;	$DO
$$DO119:
	    PUSH    AX			;save these
	    PUSH    CX			;because they are
	    PUSH    DX			;destroyed by call
	    MOV     CX,160		;640K = 160*4K blocks
	    SUB     CX,DX		;minus starting 4K block
					;is # 4K blocks to map for this ID
	    CALL    SETXLAT		;write trans table accordingly
	    POP     DX			;recover these registers
	    POP     CX
	    POP     AX
	    INC     BH			;next ID
;	$ENDDO	LOOP
	LOOP $$DO119

	MOV	DX,MODE_REG
	IN	AL,DX			;read mode reg
	OR	AL,VIRT_MODE		;turn on virtual bit
	OUT	DX,AL			;write it back

	POP	DS			;restore these registers
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET
VIRT2REAL ENDP


include romscan.inc			; code to do romscan for hole location/verification
INCLUDE PARMPARS.INC			;Routines to parse the parameters
					; on the CONFIG.SYS line

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Subprocedure:  BACK_CONV_MEM					³
;³									³
;³  Purpose:  Called when a portion of the XMA card is used to back	³
;³	       conventional memory.  This is the case on an XMA 1	³
;³	       card (256K - 640K disabled on planar) and on the 	³
;³	       XMA/A card when WSP's XMA/A initialization device        ³
;³	       driver has disabled the planar.				³
;³	      This procedure will mark the Page Allocation List for	³
;³	       these entries with an ASCII value (for debugging) that	³
;³	       is above the range of eligible pointer values.		³
;³	       At the time this proc is called the PAL has not been	³
;³		initialized.  Initialization will skip these entries.	³
;³									³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
BACK_CONV_MEM	PROC
	MOV	AX,END_BACMEM_SEG	;upper segment of backed memory
	SUB	AX,START_BACMEM_SEG	;subtract seg of backed memory start
	MOV	CL,10			;conver # of segments to # of 16 K
	SHR	AX,CL			; pages used for fill (div by 1024)
	SUB	TOTAL_EMS_PAGES,AX	;subtract from total EMS pages
					; (but not from TOTAL_SYStem_PAGES)
	SUB	FREE_PAGES,AX		;subtract from free EMS pages
	MOV	CX,AX			;Put # of backing pages into CX
	PUSH	CX			; and save it on stack

	MOV	AX,START_BACMEM_SEG	;Convert the segment value for the
	MOV	CL,10			; start of backed memory to its
	SHR	AX,CL			; corresponding page number
	MOV	DX,TYPE PAGE_ALLOC_LIST ; then convert to the correct	   @RH8
	MUL	DX			; entry in the page alloc list	   @RH8
	MOV	SI,AX			; store PAL offset into SI
	POP	CX			;recover loop counter for # backed
;mark these pages used in page list but do not assign a handle
BACK_MEM_PAL:
	MOV	PAGE_LIST_ENTRY,BACMEM_ALLOC	 ;Mark the PAL with ascii  @RH8
	ADD	SI,TYPE PAGE_ALLOC_LIST 	 ;Next entry in PAL	   @RH8
	LOOP	BACK_MEM_PAL
			;Remove code here that used to reserve pages for
			; WSP by reading a value on the CONFIG.SYS line.
			; Instead, WSP will make an IOCTL call for the
			; number of pages it needs.
BACK_CONV_MEM	ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Subprocedure:  INIT_PAL						³
;³									³
;³  Purpose:  This subprocedure will link the Page Allocation List.	³
;³	       The head pointer to the list of available pages		³
;³	       (PAL_FREE_PTR) is initialized to the top EMS page,	³
;³	       and all available pages are linked from top to bottom.	³
;³	      All free pages will initially be contiguous, except on	³
;³	       an XMA 1 system.  With XMA 1, 256-640K on the card is	³
;³	       used to back conventional memory.  The free list will	³
;³	       skip around these pages (pages 16 to 40).		³
;³									³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
INIT_PAL   PROC
	push	cs					;set up addressibility	;an000; dms;
	pop	ds					;			;an000; dms;

	cmp	Total_EMS_Pages,0			;any pages?		;an000; dms;
	je	Init_Pal_End				;no - exit		;an000; dms;

	mov	ax,Total_Sys_Pages			;top of EMS pages =	;an000; dms;
	add	ax,Resr_Ext_Pgs 			;  total EMS pages +	;an000; dms;
	dec	ax					;  rsv ext. pages - 1	;an000; dms;


	mov	si,ax					;ptr to free page	;an000; dms;
	shl	si,1					;make an index		;an000; dms;
	mov	Page_List_Entry,Pal_Null		;set last entry to null ;ac007; dms;
	shr	si,1					;convert to ptr value	;an007; dms;
	mov	di,si					;place in di		;an007; dms;

	dec	ax					;next page		;an000; dms;
	mov	cx,Total_EMS_Pages			;loop for all entries	;an000; dms;
	dec	cx					;  but the last 	;an000; dms;

INIT_PAL_LP:

	cmp	cx,0					;at end?		;an000; dms;
	je	Init_Pal_Loop_Exit			;yes - exit		;an000; dms;

	mov	si,ax					;ptr to next page	;ac007; dms;
	shl	si,1					;make an index		;ac007; dms;
	cmp	Page_Alloc_List[si],BacMem_Alloc	;backfilled memory?	;ac007; dms;
	jne	Init_Pal_Entry				;no - set up ptr's      ;an000; dms;
	dec	ax					;yes - next ptr value	;an000; dms;
	jmp	Init_Pal_LP				;keep on looping	;an000; dms;
INIT_PAL_ENTRY:
	mov	Page_List_Entry,di			;set up ptr value	;ac007; dms;
	mov	di,si					;next ptr value 	;ac007; dms;
	shr	di,1					;make a ptr value	;an007; dms;
INIT_PAL_BOT:
	dec	ax					;get next ptr value	;an000; dms;
	dec	cx					;dec loop counter	;an000; dms;
	jmp	INIT_PAL_LP				;continue looping	;an000; dms;

Init_Pal_Loop_Exit:
	mov	Pal_Free_Ptr,di 			;init free ptr		;an007; dms;

INIT_PAL_END:
	ret						;return to caller	;an000; dms;
INIT_PAL  ENDP

;-----------------------------------------------------------------------;
;	This routine will convert a number in (AX) to a 		;
;	4 byte ascii string equivalent to a 4 digit decimal		;
;	number and write it at the address pointed to			;
;	by ES:DI. Leading zeroes are suppressed.			;
;									;
;	On entry:   (AX) = number to be converted			;
;		    ES:DI= address where string is to be written	;
;									;
;	On exit:    all registers are preserved 			;
;									;
;-----------------------------------------------------------------------;

CNVDECAT PROC

	PUSH	AX
	PUSH	CX
	PUSH	DX
	PUSH	DI			;save these registers

	MOV	CX,4			;loop counter 4 digits
;	$DO
$$DO152:
	    XOR     DX,DX		;clear hi word of dividend
					;ax is low word of dividend
	    DIV     CS:TEN		;divide by 10
	    OR	    DL,30H		;make modulo into ascii digit
	    PUSH    DX			;put it on stack
;	$ENDDO	LOOP			;repeat for all 4 digits
	LOOP $$DO152

	MOV	CX,4			;recover 4 digits from stack
;	$DO
$$DO154:
	    POP     AX			;recover next most sign digit
	    CMP     AL,'0'              ;is it a '0'
;	    $IF     NE
	    JE $$IF155
		PUSH	AX		;back on stack for next loop
		JMP	LEAD_DIGIT	;if not then we found leading non zero
;	    $ENDIF
$$IF155:
;	$ENDDO	LOOP			;else continiue til non zero found
	LOOP $$DO154
LEAD_DIGIT:
;	$IF	NCXZ			;only if cx is non zero
	JCXZ $$IF158
;	    $DO
$$DO159:
		POP	AX		;recover next digit
		MOV	ES:BYTE PTR [DI],AL ;write it to string
		INC	DI		;point to next byte
;	    $ENDDO  LOOP		;repeat for all digits
	    LOOP $$DO159
;	$ENDIF
$$IF158:

	POP	DI			;recover these registers
	POP	DX
	POP	CX
	POP	AX

	RET				;return to caller
CNVDECAT ENDP



;-----------------------------------------------------------------------;
;	This routine will convert a number in (AX) to a 		;
;	4 byte ascii string equivalent to a 4 digit hexadecimal 	;
;	number and write it at the address pointed to			;
;	by ES:DI. Leading zeroes are suppressed.			;
;									;
;	On entry:   (AX) = number to be converted			;
;		    ES:DI= address where string is to be written	;
;									;
;	On exit:    all registers are preserved 			;
;									;
;-----------------------------------------------------------------------;

DEC2ASCII DB	'0123456789ABCDEF'


CNVHEXAT PROC

	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DI			;save these registers
	PUSH	DS

	PUSH	CS
	POP	DS

	MOV	BX,OFFSET DEC2ASCII
	MOV	CX,4			;loop counter 4 digits
;	$DO
$$DO162:
	    XOR     DX,DX		;clear hi word of dividend
					;ax is low word of dividend
	    DIV     SIXTEEN		;divide by 10

	    PUSH    AX			;save quotient
	    MOV     AX,DX		;get modulo into ax
	    XLAT    DEC2ASCII		;convert al to ascii
	    MOV     DX,AX		;get it into dx
	    POP     AX			;recover quotient
	    PUSH    DX			;put ascii modulo on stack
;	$ENDDO	LOOP			;repeat for all 4 digits
	LOOP $$DO162

	MOV	CX,4			;recover 4 digits from stack
;	$DO
$$DO164:
;gga	    POP     AX			;recover next most sign digit
;gga	    CMP     AL,'0'              ;is it a '0'
;	    $IF     NE
;gga	    JE $$IF165
;gga		PUSH	AX		;back on stack for next loop
;gga		JMP	CNVH1		;if not then we found leading non zero
;	    $ENDIF
$$IF165:
;	$ENDDO	LOOP			;else continiue til non zero found
;gga	LOOP $$DO164
CNVH1:
;	$IF	NCXZ			;only if cx is non zero
	JCXZ $$IF168
;	    $DO
$$DO169:
		POP	AX		;recover next digit
		MOV	ES:BYTE PTR [DI],AL ;write it to string
		INC	DI		;point to next byte
;	    $ENDDO  LOOP		;repeat for all digits
	    LOOP $$DO169
;	$ENDIF
$$IF168:

	POP	DS
	POP	DI			;recover these registers
	POP	DX
	POP	CX
	POP	BX
	POP	AX

	RET				;return to caller
CNVHEXAT ENDP

;-----------------------------------------------------------------------;
;	STEAL_INT15 changes the INT 15H vector to point to this EMS'    ;
;	so that subsequent calls to INT15H may determine the actual	;
;	size of EM after EMS' allocation of it                          ;
;-----------------------------------------------------------------------;
STEAL_INT15 PROC
	PUSH	DS
	push	ax

	CMP	MODEL_BYTE,PS2MODEL80	;If a PS2/80 treat as XMA memory	;an000; dms;
	je	Steal_INT15_Exit	;do not hook INT15h			;an000; dms;

	CMP	MODEL_BYTE,PC_AT	;If the model byte is for an 'AT'  @RH2
	jne	Steal_INT15_Hook	; type (80286 processor), check    @RH2

	MOV	AH,0C0h 		; the XMA/A or XMO card		   @RH2
	INT	15h			;				   @RH2
	CMP	INT15_SEC_MOD,SEC_MOD_TB;				   @RH2
	JE	Steal_INT15_Hook	;				   @RH2

	CMP	INT15_SEC_MOD,SEC_MOD_RR;If 'AT' but not PS/2 50 or 60,    @RH2
	JE	Steal_INT15_Hook	; then family 1 (uses XMA 1 card)  @RH2
	JMP	Steal_INT15_Exit	;				   @RH2

Steal_INT15_Hook:

	XOR	AX,AX
	MOV	DS,AX			;set DS = 0
	ASSUME	DS:INT_VEC15
	CLI				;disable interrupts
	LES	DI,DS:EM_VEC		;get original vector's content
	MOV	CS:INTV15O,DI		;save original vector
	MOV	CS:INTV15S,ES
	MOV	DS:EM_VECO,OFFSET XMA_INT15 ;offset of new INT routine
	MOV	DS:EM_VECS,CS		;segment of new INT routine
	STI				;enable interrupts again

Steal_INT15_Exit:

	pop	ax
	POP	DS			;restore DS
	RET
STEAL_INT15 ENDP


;-----------------------------------------------------------------------;
;	Calc_INT15_Space calculates the remaining extended memory for	;
;	the system.  This value will be used by all subsequent calls	;
;	to function 88h, INT 15h.					;
;-----------------------------------------------------------------------;
Calc_INT15_Space	proc	near						;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	bx					;			;an000; dms;
	push	cx					;			;an002; dms;
	push	dx					;			;an000; dms;

	mov	ah,EM_Size_Get				;get extended mem	;an000; dms;
	int	15h					;			;an000; dms;

	mov	cl,4					;divide by 16		;an002; dms;
	shr	ax,cl					;  to get page count	;an002; dms;

	sub	ax,cs:Total_Sys_Pages			;new extended mem size	;an002; dms;
	xor	dx,dx					;get K count		;an002; dms;
	mov	bx,cs:Sixteen				;			;an002; dms;
	mul	bx					;			;an002; dms;
	mov	word ptr cs:EM_Ksize,ax 		;save new size		;an000; dms;

	pop	dx					;restore regs		;an000; dms;
	pop	cx					;			;an002; dms;
	pop	bx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret

Calc_INT15_Space	endp							;an000; dms;


;-----------------------------------------------------------------------;
;	STEAL_INT13 changes the INT 13H vector to point to this EMS'    ;
;	so that subsequent calls to INT13H may properly handle DMA	;
;	to EMS pages.							;
;-----------------------------------------------------------------------;
Steal_Int13 PROC								;an004; dms;
	PUSH	DS								;an004; dms;
	push	ax								;an004; dms;

	CMP	MODEL_BYTE,PS2MODEL80	;If not a PS2/80 don't hook INT 13h   ;an004; dms;
	jne	Steal_INT15_Exit	;					;an004; dms;

	XOR	AX,AX
	MOV	DS,AX			;set DS = 0
	ASSUME	DS:INT_VEC13
	CLI				;disable interrupts
	LES	DI,DS:DK_VEC		;get original vector's content
	MOV	CS:INTV13O,DI		;save original vector
	MOV	CS:INTV13S,ES
	MOV	DS:DK_VECO,OFFSET I13_Handler ;offset of new INT routine
	MOV	DS:DK_VECS,CS		;segment of new INT routine
	STI				;enable interrupts again

Steal_INT13_Exit:

	pop	ax
	POP	DS			;restore DS
	RET
STEAL_INT13 ENDP
