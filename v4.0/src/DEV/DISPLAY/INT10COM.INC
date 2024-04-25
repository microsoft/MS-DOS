;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	INT10COM.INC
;
;	THESE FOLLOWING ROUTINES ARE USED TO LOCATE AND LOAD
;	THE FONTS FOR THE SPECIFIED CODE PAGE.	IT IS DESIGNED
;	TO WORK ON THE FOLLOWING DISPLAY ADAPTERS;
;
;	- EGA 1501200	 (minimal configuration) no expansion card needed
;	- PC Convertible (with LCD display adapter)
;	- plus literally a half-dozen code-named unreleased IBM products
;
;	SUPPORT FOR THE 'CGA' (Colour Graphics Adapter) and
;	'MONO' (Monochrome/Printer Adapter) IS LIMITED TO THE
;	HARDWARE CODE PAGE ONLY (ie. not soft-loadable devices).
;
;	PSEUDO CODE:
;	===========
;	INT_10_PROC STARTS
;		GET MODE (AL=?)
;		CALL rom_int_10
;		GET FONT_SIZE
;		if FONT_SIZE <> 0FFH
;		    if FONT_SIZE = available
;			GET LOAD_MECHANISM
;			if LOAD_MECHANISM = BIOS technique
;			    CALL LOAD_BIOS_CHAR
;			endif
;			if LOAD_MECHANISM = VECTOR technique
;			    CALL LOAD_VECTOR_CHAR
;			endif
;		    endif
;		endif
;		IRET
;	INT_10_PROC ENDS
;
;		 (C)Copyright 1988 Microsoft
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF1					;
	%OUT .		     �INT10COM.INC�
ENDIF

;Modification history *********************************************************
;AN001; P1497 Cursor disappearance problem after codepage switch    10/9/87 J.K.
;******************************************************************************
	PUBLIC	MODE_VALUE		;
	PUBLIC	ROM_INT_10		;
	PUBLIC	ROM_INT_1F		;
	PUBLIC	OLD_INT_1F		;
	PUBLIC	ROM_INT_44		;
	PUBLIC	INT_10_COM		;
	PUBLIC	ASK_BIOS_FONT_SIZE	;
	PUBLIC	ASK_BIOS_SCAN_LINES	;
					;
ROM_INT_10	 DW   ? 		; Int 10H vector offset
		 DW   ? 		; Int 10H vector segment
ROM_INT_1F	 DW   ? 		; Int 1FH vector offset
		 DW   ? 		; Int 1FH vector segment
OLD_INT_1F	 DW   ? 		; OLD Int 1FH vector offset
		 DW   ? 		; OLD Int 1FH vector segment
ROM_INT_44	 DW   ? 		; Int 44H vector offset
		 DW   ? 		; Int 44H vector segment
MODE_VALUE	 DB   ? 		; VALUE OF AL DURING INT 10H (AH=0)
BYTES_PER_CHAR	 DB   ? 		; VALUE OF BYTES/CHARACTER IN MODES
LOAD_MECHANISM	 DB   ? 		; SUPPORT SCHEME FOR ACTIVE MODE
CHARACTER_SOURCE DB   ? 		; FLAG TO INDICATE: 0 = HDWR
					;		    1 = DESG
INVALID_MODE	 EQU  0FFH		;
MASK_BIOS_LOAD	 EQU  00000011b 	;
MASK_VECTOR_LOAD EQU  00110000B 	;
MODE_MASK	 EQU  01111111B 	; GHG Emulator Problem
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	CONFIGURATION TABLES FOR CHARACTER LOADING
;
;	TABLE WILL BE FILLED IN BY INIT.ASM
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	LOAD_MECH		;
LOAD_MECH	LABEL	BYTE		; RESERVE 32 MODE SETTINGS
		DB	32 DUP(?)	; REFER TO TABLES.INC FOR DETAILS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	CONFIGURATION TABLES FOR CHARACTER SIZES
;
;	TABLE WILL BE FILLED IN BY INIT.ASM
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	FONT_SIZE		;
FONT_SIZE	LABEL	BYTE		; RESERVE 32 MODE SETTINGS
		DB	32 DUP(?)	; REFER TO TABLES.INC FOR DETAILS
NUM_FONT_SIZES	EQU ($-FONT_SIZE)	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	INTERRUPT 10H SUPPORT CODE
;
;	THE INIT ROUTINE WILL INSTALL THIS CODE INTO THE
;	INTERRUPT 10H VIDEO BIOS CALL.	IT CHAINS TO THE
;	LOWER LEVEL (usually BIOS for Device Drivers).
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INT_10_COM	PROC  FAR		;
	STI				;
	OR	AH,AH			; TEST THE SUBFUNCTION CALL=0
	JE	INT_1			; RESERVED FOR THE COM PATH!
	JMP	DWORD PTR CS:ROM_INT_10 ;
					;
INT_1:					;
	PUSHF				; PREPARE FOR IRET!
	CALL	DWORD PTR CS:ROM_INT_10 ; call routine to handle the command
	PUSH	AX			;
	PUSH	BX			; WGR						 ;AN000;
	MOV	AH,GET_MODE		; WGR get actual mode set			 ;AN000;
	PUSHF				; WGR						 ;AN000;
	CALL	DWORD PTR CS:ROM_INT_10 ; WGR						 ;AN000;
	MOV	CS:MODE_VALUE,AL	; SAVE MODE_VALUE BEFORE CALL
	and	CS:MODE_VALUE,mode_mask ; GHG Emulator Problem.....
	POP	BX			; WGR						 ;AN000;
					;
	CALL	TEST_CP 		; FIND OUT IF CP CAN BE SUPPORTED?
	JNC	INT_2			;
					;
	MOV	CS:CHARACTER_SOURCE,0	; IF AN ERROR OCCURRED IN FINDING THE
	MOV	AL,INTER_1FH		; FONT DATA INFORMATION...THEN THE
	CALL	VECTOR_LOAD		; INTERRUPT 1F hex VECTOR MUST BE
	JUMP	INT_3			; SET TO THE HDWR CP - ELSE WRONG
					; DATA MAY BE DISPLAYED
INT_2:	MOV	CS:SETMODE_FLAG,OFF	; WGR						 ;AN000;
	CALL	INVOKE_DATA		; IF SO, THEN LOAD THE DATA
INT_3:	POP	AX			;
					;
	IRET				;
INT_10_COM   ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SET BLOCK SPECIFIER = 0
;
;	THIS IS USED TO ACTIVATE BLOCK = 0 FONT.  THIS PERFORMS
;	DIFFERENT OPERATIONS ON VARIOUS DISPLAY ADAPTERS.  THE
;	RESULTS OF WHICH ARE TO ACTIVATE THE DESIGNATED FONT.
;
;	INPUT:
;		none
;	OUTPUT:
;		none
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_BLOCK_SP0	PROC			;
	PUSH	AX			;
	PUSH	BX			;
	MOV	AX,1103H		; SET BLOCK SPECIFIER
	MOV	BL,ZERO 		; CHAR GEN BLOCK SPECIFIER
	INT	10H			; PERFORM CALL...
	POP	BX			;
	POP	AX			;
	RET				;
SET_BLOCK_SP0	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	FIND_FONT
;
;	THE ROUTINE STARTS WITH THE FONT DATA POINTER, AND
;	TRIES TO FIND THE FONT RESOLUTION THAT IS NEEDED.
;	THIS FONT RESOLUTION IS BASED ON THE PRESENT SCREEN
;	MODE WHICH IS ACTIVE.
;
;	INPUT:
;		ES : DI points to beginning
;			of font data
;	OUTPUT:
;		ES : DI points to font data
;			for needed resolution
;		CY = 0	if found
;		   = 1	if not found
;
;		DS = CS assumed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FIND_FONT	PROC			;
	PUSH	AX			;
	PUSH	CX			;
	PUSH	DX			;
					;
	MOV	CX,CPD_FONTS_N		; GET NUMBER OF FONT STYLES
FF_0:	MOV	AH,BYTES_PER_CHAR	; GET BYTES_PER_CHAR FOR COMPARISON
					;
	MOV	AL,ES:[DI]		; GET #ROWS OF POINTED DATA
	CMP	AL,AH			; COMPARE BYTES_PER_CHAR AGAINST #ROWS
	JE	FF_3			; IF MATCHED...THEN ADJUST ES:DI (CY=0)
					;
	PUSH	CX			; ELSE, MOVE ES:DI TO NEXT FONT START
	MOV	CX,ES:[DI+4]		; GET count OF CHARACTERS IN LIST
	XOR	AH,AH			; PREPARE AX FOR MULT
	MUL	CX			; CALCULATE DELTA TO NEXT FONT START
	POP	CX			;
					;
	ADD	AX,SIX			; ADD FONT STYLE HEADER OF SIX BYTES
	ADD	DI,AX			; ADJUST THE DI POINTER
					; THERE CAN BE NO CARRY DUE TO STRUCTURE
	LOOP	FF_0			; OF FONT DATA (ie. no straddling)
	STC				;
	JUMP	FF_4			;
FF_3:	ADD	DI,SIX			; POINT TO VERY START OF DATA
	CLC				; SET FLAG TO OK!
FF_4:	POP	DX			;
	POP	CX			;
	POP	AX			;
	RET				;
FIND_FONT	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	BIOS_LOAD
;
;	THIS CALL IS USED TO LOAD THE ACTIVE CP.  IT LOADS
;	THE ACTIVE CP WHETHER IT IS DESIGNATED OR HDWR.  THE
;	ACTUAL LOADING OF THE FONT IS PERFORMED BY THE 'EGA CLASS'
;	BIOS ROUTINES (different for some adapters).
;
;	INPUT:
;		AL = ?	load mechanism
;
;		     7 6 5 4 3 2 1 0
;		     0 0 0 0 0 0 x x
;				 � ��� 1 - AX=1100H
;				 ����� 1 = AX=1400H
;
;		ES : DI points to start of font data
;		CX = ?	count of characters to load
;		BH = bytes per character
;		DS = CS assumed...
;
;	OUTPUT:
;		none
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
AX_1100H	EQU	00000001b	;
AX_1400H	EQU	00000010b	;
EGA_INFO	EQU	0487H		; ADDRESS OF INFO BYTE
EGA_ACTIVE	EQU	00001000b	; MASK FOR EGA_ACTIVE/NON-ACTIVE
					;
BIOS_LOAD	PROC			;
	CALL	GET_CURSOR_POS		; ONE MUST RECORD THE CURSOR POS DURING
					; A FONT LOAD...ELSE CURSOR TO (1,1)
	PUSH	BX			;
	PUSH	DX			;
					;
	MOV	DX,ZERO 		; CHARACTER OFFSET INTO TABLE
	MOV	BL,ZERO 		; BLOCK TO LOAD (Block=0)
					;
	TEST	AL,AX_1100H		; DETERMINE IF EGA_TYPE LOAD?
	JNZ	BL_00			; IF NOT, THEN TRY FOR LCD_TYPE...
	JMP	BL_3			;
					;
BL_00:	PUSH	BP			; SAVE REGISTERS TO BE USED
	PUSH	AX			;
	CMP	CHARACTER_SOURCE,ZERO	; TEST IF CP = HDWR
	JE	BL_0			;
					;
	MOV	BP,DI			; POINTER TO USER TABLE (ES:BP)
	MOV	AX,1100H		; USER ALPHA LOAD
	JUMP	BL_2			;
					;
BL_0:	MOV	AX,1102H		; ROM 8X8 DOUBLE DOT
	CMP	BYTES_PER_CHAR,8	;
	JE	BL_2			;
BL_1:	MOV	AL,01H			; ROM MONOCHROME SET
	CMP	BYTES_PER_CHAR,14	;
	JE	BL_2			;
	MOV	AL,04H			; ROM 8X16 SET
	CMP	BYTES_PER_CHAR,16	;
	JE	BL_2			;
	JUMP	BL_2A			; PERFORM BIOS CALL...
					;
BL_2:	PUSH	DS			; THIS TEST VERIFIES THAT THE EGA
	PUSH	AX			; ADAPTER IS PRESENTLY ACTIVE.
	XOR	AX,AX			; IF IT IS NOT, THEN THE EGA WILL
	MOV	DS,AX			; REPROGRAM THE ACTIVE CRT TO THE EGA
	MOV	AL,DS:EGA_INFO		; SPECIFICATION....HAZARDOUS RESULTS!
	AND	AL,EGA_ACTIVE		; MASK FOR EGA ACTIVE/NON-ACTIVE
	POP	AX			;
	POP	DS			;
					;
	JZ	BL_2AA			; IF ZERO, THE EGA IS ACTIVE...AND OK!
	STC				;   ELSE, EGA IS NOT ACTIVE
	POP	AX			;
	POP	BP			; AND WE MUST
	JUMP	BL_7			; LEAVE WITH AN ERROR....
					;
BL_2AA:
	CMP	CS:SETMODE_FLAG,OFF	; WGR MODE SET REQUIRED?..			 ;AN000;
	JE	BL_2B			; WGR NO...JUMP TO CHARACTER LOAD.		 ;AN000;
	PUSH	AX			; WGR						 ;AN000;
	PUSH	DS			; WGR						 ;AN000;
	XOR	AX,AX			; WGR						 ;AN000;
	MOV	DS,AX			; WGR						 ;AN000;
	PUSH	DS:[VIDEO_CTRL] 	; WGR						 ;AN000;
	MOV	AL,CS:MODE_VALUE	; WGR GET CURRENT MODE				 ;AN000;
	OR	AL,NOT MODE_MASK	; WGR MODE SET WITHOUT BUFFER CLEARED		 ;AN000;

	call	Info_Ansi_ModeSet	;J.K.Tell ANSI that DISPLAY.SYS is going to call INT 10h, SET MODE function.

	XOR	AH,AH			; WGR MODE SET CALL..				 ;AN000;
	PUSHF				; WGR						 ;AN000;
	CALL	DWORD PTR CS:ROM_INT_10 ; WGR						 ;AN000;

	call	Info_Ansi_ModeDone	;J.K.Tell ANSI that it is through.

	POP	DS:[VIDEO_CTRL] 	; WGR						 ;AN000;
	POP	DS			; WGR						 ;AN000;
	POP	AX			; WGR						 ;AN000;
BL_2B:					; WGR WAS ISSUED (BY ME)			 ;AN000;
	OR	AX,CS:RE_CALC		; WGR INCASE RECALC IS NEEDED.			 ;AN000;
	INT	10H			;
;AN001; EGA ROM BIOS has a bug when AX=1110h, INT 10h is issued.
;	Cursor type is changed to 0C0Dh which causes the cursor to
;	disappear!!!
;	We are going to set Cursor type back to 0607h for EGA.

	cmp	ax, 1110h		;AN001;
	jne	Skip_Cursor_Problem	;AN001;
	push	cx			;AN001;
	mov	ah, 1			;AN001;
	mov	cx, 0607h		;AN001;
	int	10h			;AN001;
	pop	cx			;AN001;

Skip_Cursor_Problem:
	MOV	CS:RE_CALC,OFF		; WGR RESET RE_CALC VALUE			 ;AN000;
	CALL	SET_BLOCK_SP0		; AND THEN SET_BLOCK_SPECIFIER (0)
BL_2A:	POP	AX			;
	POP	BP			;
					;
BL_3:	TEST	AL,AX_1400H		;
	JZ	BL_6			;
					;
	PUSH	AX			; SAVE INDICATOR
					;
	CMP	CHARACTER_SOURCE,ZERO	; TEST IF CP = HDWR
	JE	BL_4			;
					;
	MOV	AX,1400H		; LOAD USER SPECIFIED FONT
	JUMP	BL_5			;
					;
BL_4:	MOV	AX,1401H		; ASK FOR ROM LOAD FONT
	MOV	BL,ZERO 		;
BL_5:	INT	10H			; PERFORM THE LOAD!
	CALL	SET_BLOCK_SP0		; AND ALSO DO THE SET BLOCK SPECIFIER
	POP	AX			;
					;
BL_6:	CLC				;
BL_7:	POP	DX			;
	POP	BX			;
					;
	CALL	SET_CURSOR_POS		; RESTORE THE CURSOR POSITION
	RET				;
BIOS_LOAD	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	ASK_BIOS_INFO
;
;	THIS ROUTINE IS DESIGNED TO MAKE USE OF THE NEW BIOS
;	CALL IN THE '???????' AND FOLLOW-ONS.  REFER TO THE
;	'Personal Systems Architecture' DCR #405 (written
;	by DD).  IF THIS SUPPORT IS NOT FOUND ON THE
;	DISPLAY ADAPTER, THEN THE CARRY FLAG IS SET!
;
;	INPUT:
;		none
;	OUTPUT:
;		CY = 0 if found
;		     1 if not supported
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RETURN_INFO	LABEL BYTE		;
	DW	?			; OFFSET  TO STATIC FUNCTIONALITY INFO
	DW	?			; SEGMENT TO STATIC FUNCTIONALITY INFO
	DB	?			; VIDEO MODE
	DW	?			; COLUMNS ON SCREEN
	DW	?			; LEN OF REGEN BUFFER
	DW	?			; START ADDRESS IN REGEN BUFFER
	DW	?			; CURSOR POSITION OF PAGE #0
	DW	?			; CURSOR POSITION OF PAGE #1
	DW	?			; CURSOR POSITION OF PAGE #2
	DW	?			; CURSOR POSITION OF PAGE #3
	DW	?			; CURSOR POSITION OF PAGE #4
	DW	?			; CURSOR POSITION OF PAGE #5
	DW	?			; CURSOR POSITION OF PAGE #6
	DW	?			; CURSOR POSITION OF PAGE #7
	DW	?			; CURSOR MODE SETTING
	DB	?			; ACTIVE DISPLAY PAGE
	DW	?			; CRT CONTROLLER ADDRESS
	DB	?			; CRT_MODE_SET
	DB	?			; CRT_PALETTE
	DB	?			; ROWS ON SCREEN
CHAR_H	LABEL	WORD			;
	DW	?			; CHARACTER HEIGHT
	DB	?			; DISPLAY COMBINATION (ACTIVE)
	DB	?			; DISPLAY COMBINATION (ALTERNATE)
L_RET_INFO	EQU ($-RETURN_INFO)	;
	DB     (40h-L_RET_INFO) DUP (?) ; REMAINING DATA....
					;
STATIC_INFO	STRUC			;
	DB	?			; VIDEO MODES (part 1)
	DB	?			; VIDEO MODES (part 2)
	DB	?			; VIDEO MODES (part 3)
	DB	?			; RESERVED
	DB	?			; RESERVED
	DB	?			; RESERVED
	DB	?			; RESERVED
SI_LINE DB	?			; SCAN LINES AVAILABLE IN TEXT MODES
STATIC_INFO	ENDS			;
					;
ASK_BIOS_INFO	PROC			;
	PUSH	ES			;
	PUSH	DI			;
	PUSH	BX			;
	PUSH	AX			;
					;
	MOV	AX,1B00H		; BIOS CALL FOR 'EGA +' INFORMATION
	MOV	BX,0			;
	MOV	DI,OFFSET RETURN_INFO	; SETUP THE RETURN ADDRESS (above)
	PUSH	CS			;
	POP	ES			;
	INT	10H			;
					;
	CMP	AL,1BH			; IF AL <> 1BH, THEN ADAPTER DOES
	JNZ	ABI_3			; NOT SUPPORT THIS CALL...EXIT w/ERROR
	CLC				;
	JUMP	ABI_4			; ELSE, LEAVE w/o ERROR
					; WITH THE TABLE ALL FILLED IN....
ABI_3:	STC				;
ABI_4:	POP	AX			;
	POP	BX			;
	POP	DI			;
	POP	ES			;
	RET				;
ASK_BIOS_INFO	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	ASK_BIOS_FONT_SIZE
;
;	THIS ROUTINE RETURNS THE PRESENT FONT RESOLUTION.
;	IT IS SUPPORTED VIA THE ENHANCED INT 10H BIOS CALL.
;	REFER TO THE 'ASK_BIOS_INFO' FOR DETAILS.
;
;	INPUT:
;		none
;	OUTPUT:
;		AL = bytes/character
;		CY = 0 if found
;		     1 if not supported (and AL = unchanged)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ASK_BIOS_FONT_SIZE PROC 		;
	PUSH	BX			;
	CALL	ASK_BIOS_INFO		;
	JC	ABFS_1			;
	MOV	BX,CHAR_H		;
	MOV	AL,BL			;
	CMP	AL,ZERO 		; PERFORM CHECK FOR BIOS ERROR!
	JNZ	ABFS_0			;
	STC				;
	JUMP	ABFS_1			;
ABFS_0: CLC				;
ABFS_1: POP	BX			;
	RET				;
ASK_BIOS_FONT_SIZE ENDP 		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	ASK_BIOS_SCAN_LINES
;
;	THIS IS SIMILAR TO THE ASK_BIOS_FONT_SIZE, EXCEPT IT
;	WILL RETURN THE AVAILABLE VERTICAL SCAN LINES FOR ALL
;	TEXT MODES.  REFER TO REFERENCED DCR #405.
;
;	INPUT:
;		none
;	OUTPUT:
;		AL = encoded SCAN LINES (in text modes)
;		CY = 0 if found
;		     1 if not supported
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ASK_BIOS_SCAN_LINES PROC		;
	CALL	ASK_BIOS_INFO		; ASK BIOS FOR DETAILED INFO...
	JC	ABSL_0			; IF CY = 1, THEN BIOS NOT SMART ENOUGH!
	PUSH	BX			;
	PUSH	SI			;
	PUSH	ES			;
	LEA	SI,RETURN_INFO		; GET POINTERS TO STATIC TABLE....
	MOV	BX,CS:[SI+2]		; GET STATIC INFO SEGMENT
	MOV	ES,BX			;	    &
	MOV	SI,CS:[SI]		; GET STATIC INFO OFFSET
	MOV	AL,ES:[SI].SI_LINE	; THEN, FINALLY THE ENCODED SCAN_LINES
	POP	ES			;
	POP	SI			;
	POP	BX			;
ABSL_0: RET				;
ASK_BIOS_SCAN_LINES ENDP		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	VECTOR_LOAD
;
;	THIS ROUTINE WORKS SIMILARLY TO THE BIOS_LOAD, EXCEPT THAT
;	THE FONT SUPPORT IS LOADED VIA A VECTOR MECHANISM...RATHER
;	THAN USING BIOS.  THE BIOS_LOAD METHOD IS USED EXCLUSIVELY
;	FOR TEXT MODES ONLY....WHILE THE VECTOR_LOAD IS FOR APA
;	(all points addressable).
;
;	THE VECTOR SUPPORT IS BASED ON THE INTERRUPT VECTORS 1F hex
;	AND 43 hex.  THE INTERRUPT 1F hex HAS SPECIAL CONSIDERATIONS
;	DUE TO THE 'GRAFTABL.COM' PROGRAM PROVIDED ON DOS.  REFER
;	TO THE 'CPS DESIGN DOCUMENT' (written by IBM Canada Lab) FOR
;	DETAILS.
;
;	INPUT:
;		AL = ?	load mechanism
;
;		7 6 5 4 3 2 1 0
;		x x x x 0 0 0 0
;		    � ����������� 1 = INT 1FH
;		    ������������� 1 = INT 43H
;				  1 = int 1FH special handling
;
;
;		ES : DI points to start of font data
;		CX = ?	count of characters to load
;		BH = bytes per character
;
;		DS = CS assumed
;
;    ***********************************************************
;    ************** SCHEDULED FOR OPTIMIZATION *****************
;    ***********************************************************
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VECTOR_MODE	DB	?		;
INTER_43H	EQU	00100000b	;
INTER_1FH	EQU	00010000b	;
LCD_1FH 	EQU	01000000b	;
INTER_44H	EQU	10000000b	;
					;
VECTOR_LOAD	PROC			;
	TEST	AL,INTER_1FH		; CHECK IF ANY INTERRUPT 1FH PROCESSING
	JNZ	VL_00			; IS NEEDED.
	JUMP	VL_3			; IS NEEDED.
					;
VL_00:	MOV	CS:VECTOR_MODE,AL	;
	PUSH	AX			; SAVE AX REGISTER....
	MOV	AX,0B000H		; INTERFACE CALL TO GRAFTABL TO SEE
	INT	2FH			; IF SUPPORT IS LOADED.
	CMP	AL,0FFH 		; IF SO, THEN EXIT!
	POP	AX			; RESTORE AX REGISTER..
	JNE	VL_2AA			; IF NOT 0FFH=AL, THEN NOT LOADED!
	JUMP	VL_3			; EXIT, GRAFTABL HAS CONTROL
					;
VL_2AA: CMP	CHARACTER_SOURCE,0	; TEST IF CP = HDWR
	JE	VL_1			;
					;
	PUSH	DS			;
	PUSH	AX			;
	XOR	AX,AX			;
	MOV	DS,AX			;
	MOV	AX,DI			; PUT DI INTO AX FOR ADJUSTMENT
	ADD	AX,8*128		;
					;
	CLI				;
	MOV	DS:WORD PTR INT_1F_LOW,AX; SET THE HIGH 128 CHARACTERS
	MOV	DS:WORD PTR INT_1F_HI,ES;
	STI				;
	MOV	CS:OLD_INT_1F,AX	; SAVE VALUE TO INTERNAL STORAGE
	MOV	CS:OLD_INT_1F+2,ES	;
	POP	AX			;
	POP	DS			;
	JUMP	VL_3			;
					;
VL_1:	TEST	CS:VECTOR_MODE,LCD_1FH	; CHECK IF LCD ACTIVE
	JZ	VL_11A			;
					;
	PUSH	DS			; SET INT 44 hex WITH HDWR CP
	PUSH	DI			;
	PUSH	AX			;
	XOR	AX,AX			;
	MOV	DS,AX			;
	CLI				;
	MOV	DI,CS:ROM_INT_1F	;
	MOV	DS:WORD PTR INT_1F_LOW,DI; SET NEW VECTOR
	MOV	CS:OLD_INT_1F,DI	; SAVE VALUE TO INTERNAL STORAGE
	MOV	DI,CS:ROM_INT_1F+2	;
	MOV	DS:WORD PTR INT_1F_HI,DI;
	MOV	CS:OLD_INT_1F+2,DI	;
	STI				;
	POP	AX			;
	POP	DI			;
	POP	DS			;
	JUMP	VL_3			;
					;
VL_11A: PUSH	ES			; SET INT 1F hex WITH HDWR CP
	PUSH	DS			;
	PUSH	BP			;
	PUSH	AX			;
	PUSH	BX			;
	PUSH	CX			;
	PUSH	DX			;
	MOV	AX,1130H		; GET EGA INFORMATION
	MOV	BH,4			; GET ROM DOUBLE DOT PTR (TOP)
	INT	10H			;
	XOR	AX,AX			;
	MOV	DS,AX			;
	CLI				;
	MOV	DS:WORD PTR INT_1F_LOW,BP; SET THE HIGH 128 CHARACTERS
	MOV	DS:WORD PTR INT_1F_HI,ES;
	STI				;
	MOV	CS:OLD_INT_1F,BP	; SAVE VALUE TO INTERNAL STORAGE
	MOV	CS:OLD_INT_1F+2,ES	;
	POP	DX			;
	POP	CX			;
	POP	BX			;
	POP	AX			;
	POP	BP			;
	POP	DS			;
	POP	ES			;
					;
VL_3:	TEST	AL,INTER_43H		;
	JZ	VL_8			;
					;
	CMP	CHARACTER_SOURCE,0	; TEST IF CP = HDWR
	JE	VL_5			;
					;
	PUSH	DS			; SET INT 43 hex WITH USER TABLE
	PUSH	AX			;
	XOR	AX,AX			;
	MOV	DS,AX			;
	CLI				;
	MOV	DS:WORD PTR INT_43_LOW,DI;
	MOV	DS:WORD PTR INT_43_HI,ES;
	STI				;
	POP	AX			;
	POP	DS			;
	JUMP	VL_9			;
					;
VL_5:	PUSH	BX			; SET INT 43 hex WITH HDWR CP
	MOV	BH,3			; RETURN ROM DOUBLE DOT PTR
	CMP	BYTES_PER_CHAR,8	; WORK FOR HARDWARE CP's
	JE	VL_6			;
					;
	MOV	BH,2			; RETURN ROM 8X14 PTR
	CMP	BYTES_PER_CHAR,14	;
	JE	VL_6			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	THIS IS BH=6 (??????? WAS IN ERROR).  THE ?????? HAS
;	THE LATEST FIX SUPPORT.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	BH,6			; SET FOR ROM 8X16 PTR
	CMP	BYTES_PER_CHAR,16	;
	JNE	VL_7			;
					;
VL_6:	PUSH	AX			; YES, ONCE AGAIN, SAVE THOSE REG'ies
	PUSH	CX			;
	PUSH	DX			;
	PUSH	DS			;
	PUSH	ES			;
	PUSH	BP			;
	MOV	AX,1130H		; GET EGA INFORMATION (PTR=ES:DI)
	INT	10H			;
	XOR	AX,AX			;
	MOV	DS,AX			;
	CLI				;
	MOV	DS:WORD PTR INT_43_LOW,BP; SET THE FULL CHARACTER SET
	MOV	DS:WORD PTR INT_43_HI,ES;
	STI				;
	POP	BP			;
	POP	ES			;
	POP	DS			;
	POP	DX			;
	POP	CX			;
	POP	AX			;
VL_7:	POP	BX			;
					;
VL_8:	TEST	AL,INTER_44H		; Test for INTERRUPT 44 Hex
	JZ	VL_9			;
					;
	CMP	CHARACTER_SOURCE,0	; TEST IF CP = HDWR
	JE	VL_8A			;
					;
	PUSH	DS			; SET INT 43 hex WITH USER TABLE
	PUSH	AX			;
	XOR	AX,AX			;
	MOV	DS,AX			;
	CLI				;
	MOV	DS:WORD PTR INT_44_LOW,DI;
	MOV	DS:WORD PTR INT_44_HI,ES;
	STI				;
	POP	AX			;
	POP	DS			;
	JUMP	VL_9			;
					;
VL_8A:	PUSH	DS			; SET INT 44 hex WITH HDWR CP
	PUSH	DI			;
	PUSH	AX			;
	XOR	AX,AX			;
	MOV	DS,AX			;
	CLI				;
	MOV	DI,CS:ROM_INT_44	;
	MOV	DS:WORD PTR INT_44_LOW,DI;
	MOV	DI,CS:ROM_INT_44+2	;
	MOV	DS:WORD PTR INT_44_HI,DI;
	STI				;
	POP	AX			;
	POP	DI			;
	POP	DS			;
					;
VL_9:	RET				;
VECTOR_LOAD	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	LOAD CODE PAGE
;
;	This routine is called by INVOKE_DATA and
;	by the INT_10H code.
;
;	EXIT:
;		CP_ES	 points to the final CP data segment
;		CP_DI	 points to the final CP data offset
;
;		CY = 0 if no error detected
;		     1 if error occurred
;			AX = 0000 if hardware code page matched
;			AX = 0001 if routine is presently busy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CP_ES	DW	?			;
CP_DI	DW	?			;
LOAD_CP_SEMA	DB	0		; SEMAPHORE TO TELL IF ROUTINE IS
					; ALREADY ACTIVE....
					;
ANSI_BUFFER  LABEL BYTE 		; WGR BUFFER FOR ANSI				 ;AN000;
	     DB    ZERO 		; WGR INFO LEVEL				 ;AN000;
	     DB    ZERO 		; WGR						 ;AN000;
	     DW    ANSI_BUF_SIZE	; WGR LENGTH OF DATA				 ;AN000;
	     DW    ?			; WGR CONTROL FLAGS				 ;AN000;
D_MODE	     LABEL BYTE 		; WGR DISPLAY MODE				 ;AN000;
	     DB    ?			; WGR						 ;AN000;
	     DB    ?			; WGR RESERVED					 ;AN000;
	     DW    ?			; WGR COLORS					 ;AN000;
	     DW    ?			; WGR WIDTH					 ;AN000;
	     DW    ?			; WGR LENGTH					 ;AN000;
	     DW    ?			; WGR COLUMNS					 ;AN000;
SCR_ROWS     LABEL WORD 		; WGR ROWS					 ;AN000;
	     DW    ?			; WGR						 ;AN000;
					;
RE_CALC      DW    OFF			; WGR VALUE TO OR IN CHARACTER LOAD		 ;AN000;
SETMODE_FLAG DB    OFF			; WGR FLAG INDICATING A MODE SET IS REQUIRED	 ;AN000;
					;
TEST_CP 	PROC			;
	CMP	CS:LOAD_CP_SEMA,ZERO	; TEST IF ALREADY ACTIVE!
	JE	I10_0			;
	STC				; IF ALREADY ACTIVE, THEN SET ERROR
	MOV	AX,ONE			; TO INDICATE THAT ACTIVE....
	RET				;
					;
I10_0:	MOV	CS:LOAD_CP_SEMA,ONE	; SET ROUTINE NOW ACTIVE...
	PUSH	BX			;
	PUSH	CX			;
	PUSH	DX			; WGR						 ;AN000;
	PUSH	SI			;
	PUSH	DI			;
	PUSH	DS			;
	PUSH	ES			;
					;
	PUSH	CS			;
	POP	DS			; SETUP DS SEGMENT TO CS
	PUSH	CS			;
	POP	ES			; SETUP ES SEGMENT TO CS
					;
	XOR	AH,AH			; AH=0 FOR MODE SET, AL=MODE_TYPE
	MOV	AL,MODE_VALUE		;
	MOV	SI,AX			; ESTABLISH INDEX INTO LOAD_MECH table
	MOV	AL,[SI].FONT_SIZE	; GET FONT_SIZE FOR THIS MODE_VALUE
	OR	AL,AL			; TEST FOR MODE_VALUE=0
	JNZ	I10_2			;
					;
	CALL	ASK_BIOS_FONT_SIZE	; GET BIOS TO INDICATE FONT_SIZE
	JC	I10_A			; IF CY=1 THEN ERROR OCCURRED
					;
I10_2:	PUSH	AX			; WGR SAVE FONT SIZE				 ;AN000;
	MOV	Ah,ANSI_2F		; WGR REQUEST TO ANSI FOR SCREEN SIZE		 ;AN000;
	mov	al,IOCTL_2F		; IOCTL request
	MOV	CL,GET_SUBFUNC		; WGR GET CHARACTERISTICS FUNCTION		 ;AN000;
	LEA	DX,ANSI_BUFFER		; WGR BUFFER FOR REQUEST STORAGE		 ;AN000;
	INT	2FH			; WGR						 ;AN000;
	JC	I10_3			; WGR IF CARRY THEN ERROR..CONT AS BEFORE	 ;AN000;
	CMP	AL,16H			; WGR ENSURE THAT ANSI WAS THERE..		 ;AN000;
	JNE	I10_3			; WGR NO....CONT AS BEFORE			 ;AN000;
	CMP	D_MODE,ON		; WGR ARE WE IN A TEXT MODE?			 ;AN000;
	JNE	I10_3			; WGR NO...CONT AS BEFORE..			 ;AN000;
	CMP	SCR_ROWS,DEFAULT_LEN	; WGR IS IT JUST 25 LINES?..			 ;AN000;
	JE	I10_3			; WGR THEN...CONT AS BEFORE..			 ;AN000;
	POP	AX			; WGR GREATER THAN 25 LINES SO...POP OFF..	 ;AN000;
	MOV	CS:RE_CALC,RECALC_ON	; WGR RECALCULATION REQUIRED			 ;AN000;
	MOV	CS:SETMODE_FLAG,ON	; WGR A MODE SET IS REQUIRED			 ;AN000;
	MOV	AL,EIGHT		; WGR OLD FONT SIZE AND USE AN 8 HIGH BOX.	 ;AN000;
	JMP	I10_4			; WGR						 ;AN000;
					;
I10_3:	POP	AX			; WGR RESTORE OLD VALUE 			 ;AN000;
	MOV	CS:SETMODE_FLAG,OFF	; WGR NO MODE SET IS REQUIRED.			 ;AN000;
					;
I10_4:	MOV	BYTES_PER_CHAR,AL	; SAVE VALUE DETERMINED
					;
	MOV	CX,CPD_ACTIVE		;
	CMP	CX,-1			; CHECK IF ACTIVE CP=PLACE_HOLDER
	JE	I10_A			; IF SO, THEN STAY SLEEPING
					;
	PUSH	CX			;
	CALL	FIND_CP 		; DETERMINE IF THE CODE PAGE=HDWR
	MOV	BL,CL			;
	POP	CX			; RESTORE CP VALUE FOR FUTURE REF
	JC	I10_A			;
	MOV	CHARACTER_SOURCE,BL	;
	OR	BL,BL			; TEST TYPE OF CP?
	JE	I10_B			; IF CODE PAGE=HDWR THEN RESOLUTION OK!
					;
	CALL	FIND_FONT		; CHECK IF THE FONT RESOLUTION IS HERE
	JC	I10_A			; IF CY=0 THEN ES:DI POINT TO FONT
	MOV	CS:CP_DI,DI		;
	MOV	DI,ES			;
	MOV	CS:CP_ES,DI		;
	JUMP	I10_B			;
					;
I10_A:	XOR	AX,AX			;
	STC				;
I10_B:	POP	ES			;
	POP	DS			;
	POP	DI			;
	POP	SI			;
	POP	DX			; WGR						 ;AN000;
	POP	CX			;
	POP	BX			;
	MOV	CS:LOAD_CP_SEMA,ZERO	; SET ROUTINE NOW COMPLETED....
	RET				;
TEST_CP 	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	INVOKE DATA
;
;	THIS ROUTINE PERFORMS THE LOADING OF THE CODE PAGE
;	INFORMATION.  IT USES THE POINTERS FROM THE TEST_CP
;	ROUTINE.
;
;	ENTRY:
;		CP_ES	points to the actual data of CP segment
;		CP_DI	points to the actual data of CP offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INVOKE_DATA	PROC			;
	PUSH	BX			;
	PUSH	CX			;
	PUSH	SI			;
	PUSH	DI			;
	PUSH	DS			;
	PUSH	ES			;
					;
	MOV	DI,CS:CP_ES		; GET THE ES:DI COMBO FROM TEST_CP
	MOV	ES,DI			;
	MOV	DI,CS:CP_DI		;
					;
	XOR	AH,AH			;
	MOV	AL,MODE_VALUE		; CREATE INDEX TO GET LOAD_MECH
	MOV	SI,AX			;
	MOV	AL,[SI].LOAD_MECH	;
	MOV	LOAD_MECHANISM,AL	; SAVE THIS VALUE FOR OTHER ROUTINES
	TEST	AL,MASK_BIOS_LOAD	; FIND OUT IF INT 10H SUPPORTS
	JZ	INV_7			;
					;
	MOV	CX,256			; **** HARD CODED COUNT ****
	MOV	BH,BYTES_PER_CHAR	;
	CALL	BIOS_LOAD		; GET BIOS CODE TO GIVE THE CP SUPPORT
	JC	INV_A			;
					;
INV_7:	TEST	AL,MASK_VECTOR_LOAD	;
	JZ	INV_8			;
					;
	CALL	VECTOR_LOAD		; ESTABLISH THE VECTORS FOR CP SUPPORT
	JC	INV_A			;
					;
INV_8:	CLC				;
	JUMP	INV_B			;
INV_A:	XOR	AX,AX			;
	STC				;
INV_B:	POP	ES			;
	POP	DS			;
	POP	DI			;
	POP	SI			;
	POP	CX			;
	POP	BX			;
	RET				;
INVOKE_DATA	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	GET_CURSOR_POSITION
;
;	This routine is called by BIOS_LOAD.  It is used
;	to ask for the cursor position before a character
;	download...since BIOS puts the cursor to (1,1).
;
;
;	INPUT:
;		none
;	OUTPUT:
;		BX = page number
;		DX = cursor position
;
;		DS = CS assumed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ACTIVE_PAGE	DW	?		;
CURSOR_POS	DW	?		;
					;
GET_CURSOR_POS	PROC			;
	PUSHF				;
	PUSH	DX			;
	PUSH	CX			;
	PUSH	BX			;
	PUSH	AX			;
	MOV	AH,15			; CALL TO GET CURRENT_VIDEO_STATE
	PUSHF				;
	CALL	DWORD PTR CS:ROM_INT_10 ; call routine to handle the command
	MOV	ACTIVE_PAGE,BX		;
					;
	MOV	AH,3			;
	PUSHF				;
	CALL	DWORD PTR CS:ROM_INT_10 ; call routine to handle the command
	MOV	CURSOR_POS,DX		;
	POP	AX			;
	POP	BX			;
	POP	CX			;
	POP	DX			;
	POPF				;
	RET				;
GET_CURSOR_POS	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SET_CURSOR_POSITION
;
;	This routine is called by BIOS_LOAD.  It is used
;	to tell BIOS where to put the cursor.
;
;	INPUT:
;		BX = page number
;		DX = cursor position
;	OUTPUT:
;		none
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_CURSOR_POS	PROC			;
	PUSHF				;
	PUSH	DX			;
	PUSH	BX			;
	PUSH	AX			;
	MOV	AH,2			;
	MOV	BX,ACTIVE_PAGE		;
	MOV	DX,CURSOR_POS		;
	PUSHF				;
	CALL	DWORD PTR CS:ROM_INT_10 ; call routine to handle the command
	POP	AX			;
	POP	BX			;
	POP	DX			;
	POPF				;
	RET				;
SET_CURSOR_POS	ENDP			;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Info_Ansi_ModeSet
;
;	INPUT:None
;	OUTPUT:None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Info_Ansi_ModeSet	proc	near
	push	ax
	push	dx
	push	ds
	push	si
	pushf
	push	cs
	pop	ds
	lea	si, ANSI_DA_INFO
	mov	[si].DA_SETMODE_FLAG, 1 ;Tell ANSI we are calling int10h, Set Mode funciton
	mov	dx, si
	mov	ah, ANSI_2F
	mov	al, DA_INFO_2F
	int	2fh			;We don't worry about whether ANSI installed or not.
	popf
	pop	si
	pop	ds
	pop	dx
	pop	ax
	ret
Info_Ansi_ModeSet	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Info_Ansi_ModeDone
;
;	INPUT:None
;	OUTPUT:None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Info_Ansi_ModeDone	proc	near
	push	ax
	push	dx
	push	ds
	push	si
	pushf
	push	cs
	pop	ds
	lea	si, ANSI_DA_INFO
	mov	[si].DA_SETMODE_FLAG, 0 ;Tell ANSI we are done with int10h, Set Mode funciton
	mov	dx, si
	mov	ah, ANSI_2F
	mov	al, DA_INFO_2F
	int	2fh			;We don't worry about whether ANSI installed or not.
	popf
	pop	si
	pop	ds
	pop	dx
	pop	ax
	ret
Info_Ansi_ModeDone	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
