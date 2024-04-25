;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   INTERRUPT 2F HEX COMMUNICATION ROUTINE
;
;   This routine is used to communicate between the CON driver
;   and the Keyboard routine.  The various calls are as follows:
;
;   1) not yet defined
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF1					       ;
	%OUT .		     ®INT2FCOM.INC¯
ENDIF					       ;
	PUBLIC	ROM_INT_2F		       ;
	PUBLIC	INT_2F_COM		       ;
	PUBLIC	ABORT			       ;
					       ;
CON_REQ LABEL WORD			       ; THESE CALLS START AT '00H'
	DW	OFFSET CON_INSTALL	       ;
	DW	OFFSET CON_INVOKE	       ;
	DW	OFFSET CON_QUERY_CP	       ;
	DW	OFFSET CON_QUERY_PARAMETER     ;
CON_MAX EQU	($-CON_REQ)/2		       ;
					       ;
QPARM_TABLE LABEL WORD			       ;
	DW	OFFSET CPD_DESG_N	       ;
	DW	OFFSET CPD_FONTS_N	       ;
	DW	OFFSET CPD_HDWR_N	       ;
QPARM_ENTRY EQU  ($-QPARM_TABLE)/2	       ;
					       ;
ROM_INT_2F	 DW   ? 		       ; Int 2FH vector offset
		 DW   ? 		       ; Int 2FH vector segment
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	INTERRUPT 2F HEX
;
;	Communication between the KEYBOARD (KEYB.COM) and the
;	CON Device Driver.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INT_2F_COM	PROC  FAR		;
	STI				;
	CMP	AH,0ADH 		; TEST THE SUBFUNCTION CALL
	JNE	I2C_6			; RESERVED FOR THE COM PATH!
					;
	CMP	AL,10H			; WGR				       ;AN000;
	JNE	I2C_0			; WGR				       ;AN000;
	CALL	CHECK_VALID		; WGR				       ;AN000;
	PUSH	SI			; WGR				       ;AN000;
	JMP	I2C_1			; WGR				       ;AN000;
I2C_0:					; WGR
	CMP	AL,CON_MAX		; TEST IF IT IS ABOVE HIGH
	JAE	I2C_6			; CON CALL?
					;
	PUSH	SI			; FORMULATE THE JUMP POINTER
	PUSH	AX			;
	XOR	AH,AH			;
	MOV	SI,AX			;
	POP	AX			;
	ADD	SI,SI			;
	CALL	CS:CON_REQ[SI]		; call routine to handle the command
I2C_1:					;
	PUSH	AX			; SAVE AX REGISTER TO PLAY WITH STACK
	MOV	SI,SP			;
	MOV	AX,SS:[SI+8]		; ACCOUNT FOR SI & AX ON STACK
	JC	I2C_2			;
	AND	AX,NOT_CY		;
	JUMP	I2C_3			;
I2C_2:	OR	AX,CY			;
I2C_3:	MOV	SS:[SI+8],AX		;
	POP	AX			;
	POP	SI			;
ABORT:	IRET				;
I2C_6:	JMP    DWORD PTR CS:ROM_INT_2F	;
INT_2F_COM   ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	CON_INSTALL
;
;	A STRAIGHT FORWARD ROUTINE WHICH INDICATES WHETHER OR NOT
;	ANY PC DOS CPS-CON SUPPORT WAS LOADED DURING BOOTSTRAP.
;	THE INTERFACE IS AS PER 'DOS FUNCTIONAL SPEC'
;	(Program Interfaces).
;
;	INPUT:
;		none
;
;	OUTPUT:
;		AX = (-1) if loaded
;		     no change if not....since this is not even loaded!
;		BX = [upper nibble][lower nibble] = MAJOR - MINOR
;		     release number.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CON_INSTALL	PROC			;
	MOV	AX,-1			; CHANGE AX TO '0FFFFH' AND BX TO
	MOV	BX,0100H		; MAJOR - MINOR VERSION #
	CLC				; NO ERROR TO INDICATE....
	RET				;
CON_INSTALL	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	CHECK_VALID
;
;	THIS ROUTINE CHECKS TO SEE IF THE CURRENT CODE PAGE HAS BEEN
;	PREPARED FOR AN 8X8 RAM FONT.  THIS IS AN INTERFACE TO ANSI.SYS
;	TO ENSURE THAT A REQUEST FOR > 25 LINES IS VALID.
;
;	INPUT:
;		none
;
;	OUTPUT:
;		CF = 1 IF NOT FONT NOT AVAILABLE
;		   = 0 IF FONT IS AVAILABLE.
;
;	AUTHOR: WGR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHECK_VALID	PROC			;				       ;AN000;
	CMP	CS:CPD_ACTIVE,-1	; see if a code page has been..        ;AN000;
	JNE	CV_1			; selected?			       ;AN000;
	CLC				; no..therefore hardware code page..   ;AN000;
	JMP	CV_4			; okay...exit with carry clear.        ;AN000;
CV_1:					;				       ;AN000;
	PUSH	BX			; s				       ;AN000;
	PUSH	CX			;  a				       ;AN000;
	PUSH	DX			;   v				       ;AN000;
	PUSH	DI			;    e				       ;AN000;
	PUSH	SI			;	r			       ;AN000;
	PUSH	DS			;	 e			       ;AN000;
	PUSH	ES			;	  g			       ;AN000;
	PUSH	CS			;	   s.			       ;AN000;
	POP	DS			; establish addressibility to data     ;AN000;
	MOV	CX,CPD_ACTIVE		; use active code page...	       ;AN000;
	CALL	FIND_CP 		; is the code page prepared?	       ;AN000;
	JC	CV_3			; no....problem..exit with carry set.  ;AN000;
	CMP	CX,0			; okay...check if hardware code page?  ;AN000;
	JNE	CV_2			;				       ;AN000;
	CLC				; yes...so okay...exit with carry clear;AN000;
	JMP	CV_3			;				       ;AN000;
CV_2:					;				       ;AN000;
	MOV	DL,CS:BYTES_PER_CHAR	; save current box size..	       ;AN000;
	PUSH	DX			;				       ;AN000;
	MOV	CS:BYTES_PER_CHAR,8	; check for 8x8 box (>25 line support) ;AN000;
	CALL	FIND_FONT		; is font size there??		       ;AN000;
	POP	DX			;				       ;AN000;
	MOV	CS:BYTES_PER_CHAR,DL	; restore old box size...FIND_FONT...  ;AN000;
CV_3:					; will have returned..		       ;AN000;
	POP	ES			; with carry set appropriately	       ;AN000;
	POP	DS			;				       ;AN000;
	POP	SI			; restore			       ;AN000;
	POP	DI			;				       ;AN000;
	POP	DX			;      registers.		       ;AN000;
	POP	CX			;				       ;AN000;
	POP	BX			;				       ;AN000;
CV_4:					;				       ;AN000;
	RET				; return.			       ;AN000;
CHECK_VALID	ENDP			;				       ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	CON_INVOKE
;
;	THIS ROUTINE IS A SECOND INTERFACE TO THE CPS CON DEVICE
;	TO ACTIVATE A PARTICULAR CODE PAGE.  THIS MAKE USE OF THE
;	SAME ROUTINES AS THE GENERIC IOCTL CALLS (via INT 21H).
;	A SEMAPHORE IS PROVIDED BY THE IOCTL CALLS TO PREVENT
;	RE-ENTRANCY....WHICH MAY CAUSE INTERESTING RESULTS!!
;
;	INPUT:
;		BX = code page to activate
;
;	OUTPUT:
;		CY = 0 if CP was activated
;		     1 if an error occurred during activation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CON_INVOKE	PROC			;
	PUSH	DS			;
	PUSH	ES			;
	CMP	CS:G_IOCTL_SEMA,ONE	; ARE GENERIC IOCTL ROUTINES ACTIVE???
	JE	CI_3			; IF SO, THEN EXIT WITH ERROR...
					;
	PUSH	CS			;
	POP	DS			;
	PUSH	CS			;
	POP	ES			;
	PUSH	CPD_ACTIVE		;
	MOV	CPD_ACTIVE,BX		; SET THE ACTIVE CP = REQUESTED
	CALL	TEST_CP 		; FIND OUT IF CP IS THERE....
	POP	CPD_ACTIVE		;
	JC	CI_3			; IF CY=1, THEN LEAVE OLD CP ALONE!
	CALL	INVOKE_DATA		; LOAD THE DATA....
	JC	CI_3			; IF ERROR, THEN FONT NOT AVAILABLE
	MOV	CPD_ACTIVE,BX		;
	PUSH	DX			;
	MOV	DX,BX			;
	CALL	SIGNAL_KBD_INVK 	;
	POP	DX			;
	JC	CI_3			; SET CARRY IF KEYBOARD ERROR OCCURRED.
	CLC				; NO ERROR TO INDICATE....
	POP	ES			;
	POP	DS			;
	RET				;
CI_3:	STC				;
	POP	ES			;
	POP	DS			;
	RET				;
CON_INVOKE	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	CON_QUERY_CP
;
;	RETURNS THE ACTIVE CODE PAGE VALUE....CPD_ACTIVE VALUE
;	CHECKED FOR INVALID.
;
;	INPUT:
;		none
;	OUTPUT:
;		BX = CODE PAGE ACTIVATED  <-1 IF NONE ACTIVE>
;		CY = 1 IF CP INVALID (BX = -1)
;		     0 IF CP VALID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CON_QUERY_CP	PROC			;
	MOV	BX,CS:CPD_ACTIVE	;
	CMP	BX,-1			;
	JNE	CQCP_0			;
	MOV	AX,ONE			; SET ERROR CONDITION TO (non-active)
	STC				;
	RET				;
CQCP_0: CLC				;
	RET				;
CON_QUERY_CP	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	QUERY PARAMETER INFORMATION
;
;	ENTRY:	ES:DI points to data table
;		CX = max size of table to fill (in bytes)
;	EXIT:	ES:DI filled with formatted data;  DW #DESG,#FONTS,#HDWR,CPx's
;		CY = 1 if problem with table creation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CON_QUERY_PARAMETER PROC		;
	PUSH	DS			;
	PUSH	AX			;
	PUSH	BX			;
	PUSH	CX			;
	PUSH	DI			;
					;
	PUSH	CS			;
	POP	DS			;
					; PERFORM CHECK ON LGTH OF BUFFER
	MOV	BX,THREE		; MANDATORY THREE WORD-STARTER
	ADD	BX,CPD_HDWR_N		; ADD # CP's IN HARDWARE
	ADD	BX,CPD_DESG_N		; ADD # CP's IN DESIGNATION
	SHL	BX,1			; CONVERT TO BYTES
	CMP	BX,CX			; VERIFY THAT TABLE WILL FIT...
	JG	CQP_3			; SET ERROR CONDITION!
					;
	LEA	BX,QPARM_TABLE		;
	MOV	CX,QPARM_ENTRY		;
CQP_0:	MOV	SI,[BX] 		;
	MOV	AX,[SI] 		;
	MOV	ES:[DI],AX		;
	INC	BX			;
	INC	BX			;
	INC	DI			;
	INC	DI			;
	LOOP	CQP_0			;
					;
	CALL	GET_HDWR_CP		;
	MOV	CX,[SI] 		;
	OR	CX,CX			;
	JZ	CQP_1			;
	INC	SI			;
	INC	SI			;
	REP	MOVSW			;
					;
CQP_1:	CALL	GET_DESG_CP		;
	MOV	CX,[SI] 		;
	OR	CX,CX			;
	JE	CQP_2			;
	INC	SI			;
	INC	SI			;
	REP	MOVSW			;
					;
CQP_2:	POP	DI			;
	POP	CX			;
	POP	BX			;
	POP	AX			;
	POP	DS			;
	CLC				; CLEAR ERROR CONDITION!
	RET				;
					;
CQP_3:	POP	DI			;
	POP	CX			;
	POP	BX			;
	POP	AX			;
	POP	DS			;
	STC				; TELL CALLER THAT ERROR OCCURRED!
	RET				;
CON_QUERY_PARAMETER ENDP		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SIGNAL KEYBOARD THAT INVOKE JUST OCCURRED!
;
;	INPUT:
;		DX = code page just invoked!
;	OUTPUT:
;		none
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SIGNAL_KBD_INVK PROC			;
	PUSH	AX			;
	PUSH	BX			;
	MOV	AX,0AD81H		;
	MOV	BX,DX			;
	CLC				; CLEAR THE CARRY IN CASE NOT THERE
	INT	2FH			;
	POP	BX			;
	POP	AX			;
	RET				;
SIGNAL_KBD_INVK ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
