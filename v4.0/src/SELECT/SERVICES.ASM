

PAGE	60,132				;AN000;
NAME	SERVICES			;AN000;
TITLE	SERVICES - DOS - SELECT.EXE	;AN000;
SUBTTL	services.asm			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	SERVICES.ASM:  Copyright 1988 Microsoft
;
;
;	CHANGE HISTORY:
;
;		AN000
;		AN003	- DCR 225
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	EXTRN	INC_KS:WORD		;AN000;
	EXTRN	IN_ICBID:WORD		;AN000;
	EXTRN	CRD_CCBVECOFF:WORD	;AN000;
	EXTRN	CRD_CCBVECSEG:WORD	;AN000;
	EXTRN	IN_CCBVECSEG:WORD	;AN000;
	EXTRN	IN_CCBVECOFF:WORD	;AN000;
	EXTRN	WR_HLPOPT:WORD		;AN000;
	EXTRN	WR_HLPROW:WORD		;AN000;
	EXTRN	WR_HCBCONT:WORD 	;AN000;
	EXTRN	WR_SCBID:WORD		;AN000;
	EXTRN	WR_DRETLEN:WORD 	;AN000;
	EXTRN	WR_DRETOFF:WORD 	;AN000;
	EXTRN	WR_DRETSEG:WORD 	;AN000;
	EXTRN	QM_ID:WORD		;AN000;
	EXTRN	QM_OPT1:WORD		;AN000;
	EXTRN	QM_ACTIVEPAN:WORD	;AN000;
	EXTRN	S_USER_STRING:WORD	;AN000;
	EXTRN	P_USER_STRING:BYTE	;AN000;
	EXTRN	I_USER_INDEX:WORD	;AN000;
	EXTRN	N_USER_FUNC:WORD	;AN000;
	EXTRN	WR_REFBUF:WORD		;AN000;
	EXTRN	WR_REFIELDCNT:WORD	;AN000;
	EXTRN	WR_REFID:WORD		;AN000;
	EXTRN	QM_OPT2:WORD		;AN000;
	EXTRN	WR_MAXREFID:ABS 	;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	SEGMENT PARA PUBLIC 'SELECT'    ;AN000;segment for far routine
	ASSUME	CS:SELECT		;AN000;
					;
	INCLUDE MACROS.INC		;AN000;
	INCLUDE PCEQUATE.INC		;AN000;
	INCLUDE CASTRUC.INC		;AN000;
	INCLUDE CASVAR.INC		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	INIT_PQUEUE_CALL
;
; Entry:
;	AX = panel id
;
;
; Exit:
;	none
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	EXTRN	PCDISPQ_CALL:NEAR	;AN000;
					;
	PUBLIC	INIT_PQUEUE_CALL	;AN000;
INIT_PQUEUE_CALL   PROC 		;AN000;
	MOV	QM_OPT1,QM_CLSPAN	;AN000;clear parent panel queue
	OR	QM_OPT1,QM_CLSCHD	;AN000;clear parent panel queue
	CALL	PCDISPQ_CALL		;AN000;update display queue
	MOV	QM_ACTIVEPAN,AX 	;AN000;current active parent panel
	MOV	QM_OPT1,QM_PUSHPAN	;AN000;push parent panels
	OR	QM_OPT2,QM_BREAKON	;AN000;break on
	CALL	PREPARE_PANEL_CALL	;AN000;add panel to display queue
	MOV	WR_REFBUF,AX		;AN000;update the field refresh buffer!
	XOR	AX,AX			;AN000;
	MOV	WR_REFIELDCNT,AX	;AN000;
	MOV	QM_OPT2,AX		;AN000;set options back off...
	RET				;AN000;
INIT_PQUEUE_CALL   ENDP 		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	AX=panel
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	PUBLIC	PREPARE_PANEL_CALL	;AN000;
PREPARE_PANEL_CALL  PROC		;AN000;
	PUSH	AX			;AN000;
	PUSH	BX			;AN000;
	MOV	BX,AX			;AN000;
	MOV	QM_ID,AX		;AN000;parent PCB number
	MOV	AX, 0ADC0H		;AN000; SELECT PANEL INTERFACE
	INT	2FH			;AN000;
	CALL	PCDISPQ_CALL		;AN000;update display queue
	POP	BX			;AN000;
	POP	AX			;AN000;
	RET				;AN000;
PREPARE_PANEL_CALL  ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	AX=input
;	BX=index
;	CX=f_keys&_LEN
;	DX=offset f_keys
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	EXTRN	GET_SCB:NEAR		;AN000;
	EXTRN	ADJUST_UP:NEAR		;AN000;
	EXTRN	ADJUST_DOWN:NEAR	;AN000;
	EXTRN	GET_SCROLL_CALL:NEAR	;AN000;
	EXTRN	HANDLE_F3:NEAR		;AN000;
					;
	PUBLIC	EXEC_SCROLL_CALL	;AN000;
EXEC_SCROLL_CALL  PROC			;AN000;
	PUSH	ES			;AN000;
	MOV	WR_SCBID,AX		;AN000;get current scrolling field ID
					;
	MOV	WR_DRETLEN,CX		;AN000;get dynamic return string length
	MOV	WR_DRETOFF,DX		;AN000;
	MOV	CX,DS	      ;AN000;*********;get dynamic return string segment
	MOV	WR_DRETSEG,CX		;AN000;
					;
	PUSH	BX			;AN000;
	MOV	BX,WR_SCBID		;AN000;
	CALL	GET_SCB 		;AN000;
	POP	BX			;AN000;
					;
	MOV	AX,BX			;AN000;initialize at list top
	PUSH	BX			;AN000;
	MOV	BX,WR_SCBID		;AN000;
	CALL	ADJUST_UP		;AN000;
	POP	BX			;AN000;
					;
ESC_0:	PUSH	ES:[DI]+SCB_OPT1	;AN000;
	PUSH	ES:[DI]+SCB_OPT2	;AN000;
	PUSH	ES:[DI]+SCB_OPT3	;AN000;
	PUSH	ES:[DI]+SCB_NUMLINE	;AN000;
					;
	CALL	GET_SCROLL_CALL 	;AN000;display and process scroll field
					;
	POP	ES:[DI]+SCB_NUMLINE	;AN000;GHG CAS BUG.............
	POP	ES:[DI]+SCB_OPT3	;AN000;
	POP	ES:[DI]+SCB_OPT2	;AN000;
	POP	ES:[DI]+SCB_OPT1	;AN000;
	MOV	AX,ES:[DI]+SCB_CURELE	;AN000;
					;
	CMP	ES:[DI]+SCB_KS,F3*256	;AN000;get last keystroke
	JNE	ESC_1			;AN000;
					;
	CALL	HANDLE_F3		;AN000;
	JNC	ESC_0			;AN000;
					;
ESC_1:	PUSH	BX			;AN000;
	MOV	BX,WR_SCBID		;AN000;
	CALL	ADJUST_DOWN		;AN000;
	POP	BX			;AN000;
	MOV	I_USER_INDEX,AX 	;AN000;
					;
	MOV	AX,ES:[DI]+SCB_KS	;AN000;get last keystroke
	MOV	N_USER_FUNC,AX		;AN000;
	POP	ES			;AN000;
	RET				;AN000;
EXEC_SCROLL_CALL  ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	AX=input
;	BX=index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	EXTRN	PCSLCTP_CALL:NEAR	;AN000;
	EXTRN	GET_PCB:NEAR		;AN000;
					;
	PUBLIC	INIT_SCROLL_CALL	;AN000;
INIT_SCROLL_CALL  PROC			;AN000;
	PUSH ES 			;AN000;
	MOV  WR_SCBID,AX		;AN000;get current scrolling field ID
					;
	PUSH BX 			;AN000;
	MOV  BX,AX			;AN000;
	CALL GET_SCB			;AN000;
	POP  BX 			;AN000;
					;
	MOV  AX,BX			;AN000;
	OR   AX,AX			;AN000;
	JNZ  ISC_0			;AN000;
	OR   ES:[DI]+SCB_OPT2,SCB_ROTN	;AN000;
					;
ISC_0:	PUSH	BX			;AN000;
	MOV	BX,WR_SCBID		;AN000;
	CALL ADJUST_UP			;AN000;
	POP	BX			;AN000;
	MOV	ES:[DI]+SCB_TOPELE,1	;AN000;intialize parameters
	MOV	ES:[DI]+SCB_CURELE,AX	;AN000;
	MOV	BX,QM_ACTIVEPAN 	;AN000;get the active panel number
	CALL	GET_PCB 		;AN000;ES:DI address of panel PCB
					;
	PUSH	ES:[DI]+PCB_UROW	;AN000;    ;get active panel row
	PUSH	ES:[DI]+PCB_UCOL	;AN000;    ;get active panel column
	PUSH	ES:[DI]+PCB_CCBID	;AN000;get active panel color index
					;
	MOV	BX,WR_SCBID		;AN000;get PCSLCTP field
	CALL	GET_SCB 		;AN000;ES:DI points to SCB
					;
	POP	ES:[DI]+SCB_CCBID	;AN000;get the panel's current color ind
	POP	ES:[DI]+SCB_RELCOL	;AN000;set the panel's relative column
	POP	ES:[DI]+SCB_RELROW	;AN000;set the panel's relative row
					;
	MOV	AX,SCROLLOBJID		;AN000; scroll_object type
	MOV	BX,WR_SCBID		;AN000; scroll_id
	CALL	ADD_REFRESH		;AN000;
	POP	ES			;AN000;
	RET				;AN000;
INIT_SCROLL_CALL  ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	AX=input
;	BX=index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	INIT_SCROLL_W_LIST_CALL ;AN000;
INIT_SCROLL_W_LIST_CALL  PROC		;AN000;
	PUSH	ES			;AN000;
	PUSH	BX			;AN000;
	PUSH	CX			;AN000;
	PUSH	DX			;AN000;
	PUSH	SI			;AN000;
	PUSH	DI			;AN000;
					;
	MOV  WR_SCBID,AX		;AN000;get current scrolling field ID
	MOV  BX,AX			;AN000;
	CALL GET_SCB			;AN000;
					;
	POP  ES:[DI]+SCB_OAPOFF 	;AN000;
	POP  ES:[DI]+SCB_OAPSEG 	;AN000;
	POP  ES:[DI]+SCB_OASLEN 	;AN000;
	POP  ES:[DI]+SCB_NUMELE 	;AN000;
	POP  ES:[DI]+SCB_WIDTH		;AN000;
					;
	PUSH ES:[DI]+SCB_OAPSEG 	;AN000;
	POP  ES:[DI]+SCB_OASSEG 	;AN000;
	POP  ES 			;AN000;
	RET				;AN000;
INIT_SCROLL_W_LIST_CALL  ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	AX=input
;	CX=num_ele
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	INIT_SCROLL_W_NUM_CALL	;AN000;
INIT_SCROLL_W_NUM_CALL	PROC		;AN000;
	PUSH	ES			;AN000;
	PUSH	AX			;AN000;save current scroll field ID
	MOV	BX,AX			;AN000;
	MOV	AX,CX			;AN000;initialize at list top
	CALL	ADJUST_UP		;AN000;
					;
	POP	BX			;AN000;restore scroll field ID
	PUSH	AX			;AN000;
	CALL	GET_SCB 		;AN000;
	POP	ES:[DI]+SCB_NUMELE	;AN000;
	POP	ES			;AN000;
	RET				;AN000;
INIT_SCROLL_W_NUM_CALL	ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	AX=input
;	BX=index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	SET_SCROLL_COLOUR	;AN000;
SET_SCROLL_COLOUR  PROC 		;AN000;
	PUSH	ES			;AN000;
	CALL	GET_SCB 		;AN000;ES:DI points to SCB
	MOV	ES:[DI]+SCB_CCBID,AX	;AN000;set the panel's current color ind
	POP	ES			;AN000;
	RET				;AN000;
SET_SCROLL_COLOUR  ENDP 		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	AX=input
;	BX=index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	PUBLIC	SET_SCROLL_CALL 	;AN000;
SET_SCROLL_CALL  PROC			;AN000;
	PUSH	ES			;AN000;
	MOV  WR_SCBID,AX		;AN000;get current scrolling field ID
					;
	PUSH BX 			;AN000;
	MOV  BX,AX			;AN000;
	CALL GET_SCB			;AN000;
	POP  BX 			;AN000;
					;
	PUSH ES:[DI]+SCB_OPT1		;AN000;
	PUSH ES:[DI]+SCB_OPT2		;AN000;
					;
	OR   ES:[DI]+SCB_OPT1,SCB_RD	;AN000;
	MOV  AX,BX			;AN000;
	OR   AX,AX			;AN000;
	JNZ  SSC_0			;AN000;
	OR   ES:[DI]+SCB_OPT2,SCB_ROTN	;AN000;
					;
SSC_0:	PUSH	BX			;AN000;
	MOV	BX,WR_SCBID		;AN000;
	CALL ADJUST_UP			;AN000;
	POP	BX			;AN000;
	MOV	ES:[DI]+SCB_TOPELE,1	;AN000;intialize parameters
	MOV	ES:[DI]+SCB_CURELE,AX	;AN000;
	MOV	BX,QM_ACTIVEPAN 	;AN000;get the active panel number
	CALL	GET_PCB 		;AN000;ES:DI address of panel PCB
					;
	PUSH	ES:[DI]+PCB_UROW	;AN000;    ;get active panel row
	PUSH	ES:[DI]+PCB_UCOL	;AN000;    ;get active panel column
	PUSH	ES:[DI]+PCB_CCBID	;AN000;get active panel color index
					;
	MOV	BX,WR_SCBID		;AN000;get PCSLCTP field
	CALL	GET_SCB 		;AN000;ES:DI points to SCB
					;
	POP	ES:[DI]+SCB_CCBID	;AN000;get the panel's current color ind
	POP	ES:[DI]+SCB_RELCOL	;AN000;set the panel's relative column
	POP	ES:[DI]+SCB_RELROW	;AN000;set the panel's relative row
	INC	ES:[DI]+SCB_CCBID	;AN000;INCREMENT COLOUR INDEX TO MAKE IT DIFFERENT **************
					;
	AND	ES:[DI]+SCB_OPT1,NOT SCB_UKS;AN000;
	CALL	PCSLCTP_CALL		;AN000;display scroll field
					;
	POP	ES:[DI]+SCB_OPT2	;AN000;
	POP	ES:[DI]+SCB_OPT1	;AN000;
	POP	ES			;AN000;
	RET				;AN000;
SET_SCROLL_CALL ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	EXTRN	PCPANEL_CALL:NEAR	;AN000;
					;
	PUBLIC	DISPLAY_PANEL_CALL	;AN000;
DISPLAY_PANEL_CALL  PROC		;AN000;
	MOV	BX,0			;AN000;
	MOV	AX,0ADC0H		;AN000;
	INT	2FH			;AN000;
	XOR	AX,AX			;AN000;turn break option OFF
	CMP	WR_REFIELDCNT,0 	;AN000;
	JE	DP_10			;AN000;
	INC	AX			;AN000;turn break option ON
DP_10:	CALL	PCPANEL_CALL		;AN000;display panel
	RET				;AN000;
DISPLAY_PANEL_CALL  ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	EXTRN	GET_KEY:NEAR		;AN000;
					;
	PUBLIC	GET_FUNCTION_CALL	;AN000;
GET_FUNCTION_CALL  PROC 		;AN000;
	MOV	WR_DRETLEN,CX		;AN000;get return string length
	MOV	AX,DX			;AN000;get return string offset
	MOV	WR_DRETOFF,AX		;AN000;
	MOV	AX,DS			;AN000;get return string segment
	MOV	WR_DRETSEG,AX		;AN000;
GFC_0:	CALL	GET_KEY 		;AN000;
					;
	MOV	AX,INC_KS		;AN003;GHG
	MOV	N_USER_FUNC,AX		;AN003;GHG
					;GHG					 ;AN003;
	CMP	AX,F3*256		;AN003;GHG
	JNE	GFC_1			;AN003;GHG
					;GHG					 ;AN003;
	CALL	HANDLE_F3		;AN003;GHG
	JNC	GFC_0			;AN003;GHG
	MOV	N_USER_FUNC,F3*256	;AN003;GHG set last keystroke to exit!
					;
GFC_1:	RET				;AN000;
GET_FUNCTION_CALL  ENDP 		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	 AX,input
;	 BX,string
;	 CX,fkeys&_LEN
;	 DX,fkeys
;	 SI,field_length
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	EXTRN	CURSOROFF:NEAR		;AN000;
	EXTRN	GET_ICB:NEAR		;AN000;
	EXTRN	GET_INPUT_CALL:NEAR	;AN000;
					;
	PUBLIC	GET_STRING_CALL 	;AN000;
GET_STRING_CALL PROC			;AN000;
	PUSH	ES			;AN000;
	CALL	CLEAR_USER_STRING	;AN000;
					;
	MOV	IN_ICBID,AX		;AN000; process input field x
					;
	PUSH	BX			;AN000;
	MOV	BX,AX			;AN000;
	CALL	GET_ICB 		;AN000;
	POP	BX			;AN000;
					;
	MOV	WR_DRETLEN,CX		;AN000; SET RETURN KEYS
	MOV	WR_DRETOFF,DX		;AN000;
	MOV	AX,DS			;AN000;
	MOV	WR_DRETSEG,AX		;AN000;
					;
	MOV	ES:[DI]+ICB_WIDTH,SI	;AN000;GHG
	MOV	AX,SI			;AN000;GHG
	ADD	AX,ES:[DI]+ICB_COL	;AN000;GHG
	CMP	AX,75			;AN000;GHG
	JB	GSC_10			;AN000;GHG
	MOV	AX,70			;AN000;GHG
	SUB	AX,ES:[DI]+ICB_COL	;AN000;GHG
	MOV	ES:[DI]+ICB_WIDTH,AX	;AN000;GHG
GSC_10: 				;AN000;
	MOV	ES:[DI]+ICB_FIELDLEN,SI ;AN000; size specified by si
	MOV	AX,[BX] 		;AN000;
	MOV	ES:[DI]+ICB_DEFLEN,AX	;AN000;
	INC	AX			;AN000;
	MOV	ES:[DI]+ICB_CURCHAR,AX	;AN000;
	MOV	AX,BX			;AN000;
	INC	AX			;AN000;
	INC	AX			;AN000;
	MOV	ES:[DI]+ICB_DEFOFF,AX	;AN000;
	MOV	AX,DS			;AN000;
	MOV	ES:[DI]+ICB_DEFSEG,AX	;AN000;
					;
	LEA	AX,P_USER_STRING	;AN000;
	MOV	ES:[DI]+ICB_FIELDOFF,AX ;AN000;
	MOV	AX,DS			;AN000;
	MOV	ES:[DI]+ICB_FIELDSEG,AX ;AN000;
					;
	PUSH	CRD_CCBVECOFF		;AN000;
	PUSH	CRD_CCBVECSEG		;AN000;
	POP	IN_CCBVECSEG		;AN000;
	POP	IN_CCBVECOFF		;AN000;
					;
GSC_0:	CALL	GET_INPUT_CALL		;AN000;
	MOV	AX,ES:[DI]+ICB_KEYRET	;AN000;
	MOV	N_USER_FUNC,AX		;AN000;
					;
	CMP	AX,F3*256		;AN000;get last keystroke
	JNE	GSC_1			;AN000;
					;
	CALL	HANDLE_F3		;AN000;
	JNC	GSC_0			;AN000;
	MOV	N_USER_FUNC,F3*256	;AN000;set last keystroke to exit!
					;
GSC_1:;;AN000;MOV     AX,ES:[DI]+ICB_ENDBYTE  ;
					;
	MOV	ax,ES:[DI]+ICB_FIELDLEN ;AN000; size specified by si
	MOV	S_USER_STRING,AX	;AN000;
	call	unpad_user_string	;AN000;
					;
	CALL	CURSOROFF		;AN000;
	POP	ES			;AN000;
	RET				;AN000;
GET_STRING_CALL ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	 AX,input
;	 BX,string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	INIT_STRING_CALL	;AN000;
INIT_STRING_CALL  PROC			;AN000;
	PUSH	ES			;AN000;
	CALL	CLEAR_USER_STRING	;AN000;
					;
	MOV	IN_ICBID,AX		;AN000; process input field x
					;
	PUSH	BX			;AN000;
	MOV	BX,AX			;AN000;
	CALL	GET_ICB 		;AN000;
	POP	BX			;AN000;
					;
	MOV	ES:[DI]+ICB_WIDTH,SI	;AN000;GHG
	MOV	AX,SI			;AN000;GHG
	ADD	AX,ES:[DI]+ICB_COL	;AN000;GHG
	CMP	AX,75			;AN000;GHG
	JB	ISC_10			;AN000;GHG
	MOV	AX,70			;AN000;GHG
	SUB	AX,ES:[DI]+ICB_COL	;AN000;GHG
	MOV	ES:[DI]+ICB_WIDTH,AX	;AN000;GHG
					;
ISC_10: MOV	ES:[DI]+ICB_FIELDLEN,SI ;AN000; size specified by si
	MOV	AX,[BX] 		;AN000; SETUP TO DISPLAY DEFAULT STRING
	MOV	ES:[DI]+ICB_DEFLEN,AX	;AN000;
	INC	AX			;AN000;
	MOV	ES:[DI]+ICB_CURCHAR,AX	;AN000;
	MOV	AX,BX			;AN000;
	INC	AX			;AN000;
	INC	AX			;AN000;
	MOV	ES:[DI]+ICB_DEFOFF,AX	;AN000;
	MOV	AX,DS			;AN000;
	MOV	ES:[DI]+ICB_DEFSEG,AX	;AN000;
					;
	LEA	AX,P_USER_STRING	;AN000; SETUP RETURN STRING ADDRESS
	MOV	ES:[DI]+ICB_FIELDOFF,AX ;AN000;
	MOV	AX,DS			;AN000;
	MOV	ES:[DI]+ICB_FIELDSEG,AX ;AN000;
					;
	PUSH	CRD_CCBVECOFF		;AN000;
	PUSH	CRD_CCBVECSEG		;AN000;
	POP	IN_CCBVECSEG		;AN000;
	POP	IN_CCBVECOFF		;AN000;
					;
	MOV	AX,INPUTOBJID		;AN000; input_object type
	MOV	BX,IN_ICBID		;AN000; scroll_id
	CALL	ADD_REFRESH		;AN000;
	POP	ES			;AN000;
	RET				;AN000;
INIT_STRING_CALL  ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	 AX,input
;	 BX,string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ENTER_KEY	  DB	  13		;AN000;
ENTER_KEY_LEN	  EQU ($-ENTER_KEY)	;AN000;
					;
	PUBLIC	SET_STRING_CALL 	;AN000;
SET_STRING_CALL PROC			;AN000;
	PUSH	ES			;AN000;
	CALL	CLEAR_USER_STRING	;AN000;
					;
	MOV	IN_ICBID,AX		;AN000; process input field x
					;
	PUSH	BX			;AN000;
	MOV	BX,AX			;AN000;
	CALL	GET_ICB 		;AN000;
	POP	BX			;AN000;
					;
	MOV	ES:[DI]+ICB_WIDTH,SI	;AN000;GHG
	MOV	AX,SI			;AN000;GHG
	ADD	AX,ES:[DI]+ICB_COL	;AN000;GHG
	CMP	AX,75			;AN000;GHG
	JB	SSC_10			;AN000;GHG
	MOV	AX,70			;AN000;GHG
	SUB	AX,ES:[DI]+ICB_COL	;AN000;GHG
	MOV	ES:[DI]+ICB_WIDTH,AX	;AN000;GHG
					;
SSC_10: MOV	ES:[DI]+ICB_FIELDLEN,SI ;AN000; size specified by si
	MOV	AX,[BX] 		;AN000; SETUP TO DISPLAY DEFAULT STRING
	MOV	ES:[DI]+ICB_DEFLEN,AX	;AN000;
	INC	AX			;AN000;
	MOV	ES:[DI]+ICB_CURCHAR,AX	;AN000;
	MOV	AX,BX			;AN000;
	INC	AX			;AN000;
	INC	AX			;AN000;
	MOV	ES:[DI]+ICB_DEFOFF,AX	;AN000;
	MOV	AX,DS			;AN000;
	MOV	ES:[DI]+ICB_DEFSEG,AX	;AN000;
					;
	LEA	AX,P_USER_STRING	;AN000; SETUP RETURN STRING ADDRESS
	MOV	ES:[DI]+ICB_FIELDOFF,AX ;AN000;
	MOV	AX,DS			;AN000;
	MOV	ES:[DI]+ICB_FIELDSEG,AX ;AN000;
					;
	MOV	WR_DRETLEN,ENTER_KEY_LEN;AN000;  SET AUTO RETURN KEYS
	LEA	AX,ENTER_KEY		;AN000;
	MOV	WR_DRETOFF,AX		;AN000;
	MOV	AX,CS			;AN000;
	MOV	WR_DRETSEG,AX		;AN000;
					;
	PUSH	CRD_CCBVECOFF		;AN000;
	PUSH	CRD_CCBVECSEG		;AN000;
	POP	IN_CCBVECSEG		;AN000;
	POP	IN_CCBVECOFF		;AN000;
					;
	PUSH	ES:[DI]+ICB_OPT2	;AN000;
	OR	ES:[DI]+ICB_OPT2,ICB_UFK;AN000;
	MOV	ES:[DI]+ICB_KEYRET,ENTER;AN000;
					;
	CALL	GET_INPUT_CALL		;AN000;
					;
	POP	ES:[DI]+ICB_OPT2	;AN000;
					;
	CALL	CURSOROFF		;AN000;
	POP	ES			;AN000;
	RET				;AN000;
SET_STRING_CALL  ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	 AX,input
;	 SI,status_id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	INIT_SCROLL_STATUS_CALL ;AN000;
INIT_SCROLL_STATUS_cALL   PROC		;AN000;
	PUSH	ES			;AN000;
	MOV	BX,AX			;AN000;
	CALL	GET_SCB 		;AN000;
					;
	MOV	ES:[DI]+SCB_SELOFF,SI	;AN000;
	MOV	AX,DS			;AN000;
	MOV	ES:[DI]+SCB_SELSEG,AX	;AN000;
	POP	ES			;AN000;
	RET				;AN000;
INIT_SCROLL_STATUS_CALL   ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	BX,index
;	DX,table
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	EXTRN	PCMBEEP_CALL:NEAR	;AN000;
					;
	PUBLIC	TOGGLE_SUPPORT_CALL	;AN000;
TOGGLE_SUPPORT_CALL PROC		;AN000;
	PUSH	SI			;AN000;
	DEC	BX			;AN000;
	SHL	BX,1			;AN000;
	MOV	SI,DX			;AN000;
	MOV	AX,[SI+BX]		;AN000;
	CMP	AX,SCB_ACTIVEON 	;AN000;
	JNE	TS_1			;AN000;
	MOV	AX,SCB_SELECTON 	;AN000;
	MOV	[SI+BX],AX		;AN000;
	JMP	TS_4			;AN000;
					;
TS_1:	CMP	AX,SCB_SELECTON 	;AN000;
	JNE	TS_3			;AN000;
	MOV	AX,SCB_ACTIVEON 	;AN000;
	MOV	[SI+BX],AX		;AN000;
	JMP	TS_4			;AN000;
					;
TS_3:	CALL	PCMBEEP_CALL		;AN000;
TS_4:	POP	SI			;AN000;
	RET				;AN000;
TOGGLE_SUPPORT_CALL ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	UNPAD_USER_STRING	;AN000;
UNPAD_USER_STRING	PROC		;AN000;
	PUSH	SI			;AN000;
	PUSH	CX			;AN000;
	LEA	SI,P_USER_STRING	;AN000;
	MOV	CX,S_USER_STRING	;AN000;
	ADD	SI,CX			;AN000;
	DEC	SI			;AN000;
	MOV	AL,20H			;AN000;
					;
UUS_1:	CMP	[SI],AL 		;AN000;
	JA	UUS_3			;AN000;
	DEC	SI			;AN000;
	LOOP	UUS_1			;AN000;
					;
UUS_3:	MOV	S_USER_STRING,CX	;AN000;
	POP	CX			;AN000;
	POP	SI			;AN000;
	RET				;AN000;
UNPAD_USER_STRING	ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	CLEAR_USER_STRING	;AN000;
CLEAR_USER_STRING	PROC		;AN000;
	PUSH	SI			;AN000;
	PUSH	CX			;AN000;
	PUSH	AX			;AN000;
	LEA	SI,P_USER_STRING	;AN000;
	MOV	CX,110			;AN000;
	MOV	AL,20H			;AN000;
					;
CUS_1:	MOV	[SI],AL 		;AN000;
	INC	SI			;AN000;
	LOOP	CUS_1			;AN000;
					;
	POP	AX			;AN000;
	POP	CX			;AN000;
	POP	SI			;AN000;
	RET				;AN000;
CLEAR_USER_STRING	ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	BX,minimum
;	CX,maximum
;	AX=input
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	CHECK_MIN_MAX		;AN000;
CHECK_MIN_MAX	PROC			;AN000;
	CMP	AX,BX			;AN000;
	JB	CMM_3			;AN000;
	CMP	AX,CX			;AN000;
	JA	CMM_3			;AN000;
	CLC				;AN000;
	JMP	CMM_5			;AN000;
CMM_3:	CALL	PCMBEEP_CALL		;AN000;
	STC				;AN000;
CMM_5:	RET				;AN000;
CHECK_MIN_MAX	ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	MOV	AX,value
;	LEA	BX,P_USER_STRING
;	CALL	CONVERT_ASCII
;	MOV	S_USER_STRING,AX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TEN	DW	10			;AN000;
					;
	PUBLIC	CONVERT_ASCII		;AN000;
CONVERT_ASCII	PROC			;AN000;
	PUSH	BX			;AN000;
	PUSH	CX			;AN000;
	XOR	CX,CX			;AN000;
					;
	OR	AX,AX			;AN000;test if input value is 0
	JNE	CA_1			;AN000;
					;
	MOV	CX,1			;AN000;
	MOV	AX,1			;AN000;
	MOV	DX,'0'                  ;AN000;if input=0, then put '0' on stack
	PUSH	DX			;AN000;
	JMP	CA_6			;AN000;
					;
CA_1:	OR	AX,AX			;AN000;
	JE	CA_5			;AN000;
					;
	XOR	DX,DX			;AN000;
	DIV	TEN			;AN000;
	ADD	DX,'0'                  ;AN000;
	PUSH	DX			;AN000;
	INC	CX			;AN000;
	JMP	CA_1			;AN000;
					;
CA_5:	MOV	AX,CX			;AN000;
	OR	AX,AX			;AN000;
	JZ	CA_8			;AN000;
					;
CA_6:	POP	[BX]			;AN000;
	INC	BX			;AN000;
	LOOP	CA_6			;AN000;
					;
CA_8:	POP	CX			;AN000;
	POP	BX			;AN000;
	RET				;AN000;
CONVERT_ASCII	ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	LEA	BX,P_USER_STRING
;	MOV	CX,S_USER_STRING
;	CALL	CONVERT_NUMERIC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	CONVERT_NUMERIC 	;AN000;
CONVERT_NUMERIC PROC			;AN000;
	PUSH	SI			;AN000;
	PUSH	CX			;AN000;
	PUSH	DX			;AN000;
	XOR	DX,DX			;AN000;
	XOR	AX,AX			;AN000;
					;
	OR	CX,CX			;AN000;
	JZ	CN_8			;AN000;
					;
CN_3:	MUL	TEN			;AN000;
	PUSH	CX			;AN000;
	MOV	CL,[BX] 		;AN000;
	CMP	CL,'0'                  ;AN000;
	JB	CN_4			;AN000;
	CMP	CL,'9'                  ;AN000;
	JA	CN_4			;AN000;
	JMP	CN_5			;AN000;
CN_4:	MOV	CL,'0'                  ;AN000;
CN_5:	SUB	CL,'0'                  ;AN000;
	XOR	CH,CH			;AN000;
	ADD	AX,CX			;AN000;
	POP	CX			;AN000;
	INC	BX			;AN000;
	LOOP	CN_3			;AN000;
					;
CN_8:	POP	DX			;AN000;
	POP	CX			;AN000;
	POP	SI			;AN000;
	RET				;AN000;
CONVERT_NUMERIC ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	AX = OBJECT ID
;	BX = FIELD ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	ADD_REFRESH		;AN000;
ADD_REFRESH	PROC			;AN000;
	PUSH	SI			;AN000;
	LEA	SI,WR_REFID		;AN000;
	ADD	SI,WR_REFIELDCNT	;AN000;
	ADD	SI,WR_REFIELDCNT	;AN000;
	ADD	SI,WR_REFIELDCNT	;AN000;
	ADD	SI,WR_REFIELDCNT	;AN000;
	MOV	[SI],AX 		;AN000;
	MOV	[SI+2],BX		;AN000;
	CMP	WR_REFIELDCNT,WR_MAXREFID;AN000;
	JAE	AD_10			 ;AN000;
	INC	WR_REFIELDCNT		;AN000;
AD_10:	POP	SI			;AN000;
	RET				;AN000;
ADD_REFRESH	ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	 AX,input
;	 DX,maximum DESTINATION buffer size
;	 SI,field_length
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	RETURN_STRING_CALL	;AN000;
RETURN_STRING_CALL PROC 		;AN000;
	PUSHH  <ES,DI,DS,SI,BX,CX>	;AN000;
					;
	MOV	BX,AX			;AN000;
	CALL	GET_ICB 		;AN000;
					;
	PUSH	ES:[DI]+ICB_DEFSEG	;AN000;
	MOV	CX,ES:[DI]+ICB_DEFLEN	;AN000;
	CMP	DX,CX			;AN000;check if DEFAULT string > buffer
	JAE	RS_10			;AN000;
	MOV	CX,DX			;AN000;only copy as much as possible
RS_10:	MOV	DI,ES:[DI]+ICB_DEFOFF	;AN000;
	POP	ES			;AN000;
					;
	PUSH	DS			;AN000;
	PUSH	SI			;AN000;
	PUSH	ES			;AN000;
	PUSH	DI			;AN000;
	POP	SI			;AN000;
	POP	DS			;AN000;
	POP	DI			;AN000;
	POP	ES			;AN000;
	CLD				;AN000;
	REP	MOVSB			;AN000;
					;
	POPP   <CX,BX,SI,DS,DI,ES>	;AN000;
	RET				;AN000;
RETURN_STRING_CALL ENDP 		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	AX,row
;	BX,panid
;	CX,col
;	DL,character
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PUBLIC	INIT_CHAR_CALL			;AN000;JW
INIT_CHAR_CALL	PROC			;AN000;JW
;					;AN000;JW
	PUSH DX 			;AN000;JW
	CALL GET_PCB			;AN000;JW
	MUL  ES:[DI]+PCB_WIDTH		;AN000;JW
	ADD  AX,CX			;AN000;JW
	MOV  SI,ES:[DI]+PCB_EXPANDOFF	;AN000;JW
	ADD  SI,AX			;AN000;JW
	PUSH ES:[DI]+PCB_EXPANDSEG	;AN000;JW
	POP  ES 			;AN000;JW
	POP  DX 			;AN000;JW
	MOV  ES: BYTE PTR [SI],DL	;AN000;JW
;					;AN000;JW
	RET				;AN000;JW
INIT_CHAR_CALL	ENDP			;AN000;JW
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	ENDS				;AN000;
	END				;AN000;
