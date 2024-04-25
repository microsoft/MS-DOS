PAGE 55,132				;AN000;
NAME	SELECT				;AN000;
TITLE	SELECT - GET_HELP_ID		;AN000;
SUBTTL	Get_Help.asm			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	GET_HELP_ID
;
; Entry:
;
;
;
; Exit:
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	SEGMENT PARA PUBLIC 'SELECT'    ;AN000;segment for far routine
	ASSUME	CS:SELECT		;AN000;
					;
					;
INP_HELP_ID	DW     12,10,10 	;AN000; help_id  1, row', col'   STR_DOS_LOC
		DW     19,12,15 	;AN000; help_id  2, row', col'   STR_EXT_PARMS
		DW     31,11,20 	;AN000; help_id  3, row', col'   STR_DOS_PATH
		DW     32,11,20 	;AN000; help_id  4, row', col'   STR_DOS_APPEND
		DW     33,11,20 	;AN000; help_id  5, row', col'   STR_DOS_PROMPT
		DW     34,12,20 	;AN000; help_id  6, row', col'   STR_SHELL
		DW     35,12,20 	;AN000; help_id  7, row', col'   STR_KSAM
		DW     35,12,20 	;AN000; help_id  8, row', col'   STR_FASTOPEN
		DW     36,12,20 	;AN000; help_id  9, row', col'   STR_SHARE
		DW     37,12,20 	;AN000; help_id 10, row', col'   STR_GRAPHICS
		DW     38,12,20 	;AN000; help_id 11, row', col'   STR_XMAEM
		DW     39,12,20 	;AN000; help_id 12, row', col'   STR_XMA2EMS
		DW     40,13,20 	;AN000; help_id 13, row', col'   STR_VDISK
		DW     41,12,20 	;AN000; help_id 14, row', col'   STR_BREAK
		DW     42,12,20 	;AN000; help_id 15, row', col'   STR_BUFFERS
		DW     43,11,20 	;AC000; help_id 16, row', col'   STR_DOS_APPEND_P JW
		DW     44, 2,20 	;AN000; help_id 17, row', col'   STR_FCBS
		DW     45, 2,20 	;AN000; help_id 18, row', col'   STR_FILES
		DW     46, 2,20 	;AN000; help_id 19, row', col'   STR_LASTDRIVE
		DW     47, 2,20 	;AN000; help_id 20, row', col'   STR_STACKS
		DW     48, 2,20 	;AN000; help_id 21, row', col'   STR_VERIFY
		DW     13,10,10 	;AN000; help_id 22, row', col'   NUM_PRINTER
		DW     18,10,20 	;AN000; help_id 23, row', col'   NUM_EXT_DISK
		DW     53,12,20 	;AN000; help_id 24, row', col'   NUM_YEAR
		DW     53,12,20 	;AN000; help_id 25, row', col'   NUM_MONTH
		DW     53,12,20 	;AN000; help_id 26, row', col'   NUM_DAY
		DW     53,12,20 	;AN000; help_id 27, row', col'   NUM_HOUR
		DW     53,12,20 	;AN000; help_id 28, row', col'   NUM_MINUTE
		DW     53,11,20 	;AN000; help_id 29, row', col'   NUM_SECOND
INP_HELP_ID_LEN EQU ($-INP_HELP_ID)/6	;AN000;
INP_HELP_ID_ELE EQU 3			;AN000;
					;
SCR_HELP_ID	DW     3		;AN000; scr_id1
		DW     3,12,20		;AN000; help_id1,row1',col1'
		DW     4, 1,20		;AN000;
		DW     5, 3,20		;AN000;
		DW     2		;AN000; scr_id2
		DW     6, 1,20		;AN000;
		DW     7, 3,20		;AN000;
		DW     1		;AN000;
		DW     8, 3,20		;AN000;  SCR_CTY_1
		DW     1		;AN000;
		DW     8, 3,20		;AN000;  SCR_CTY_2
		DW     1		;AN000;
		DW     9,10,20		;AN000;  SCR_KYB_1
		DW     1		;AN000;
		DW     9,10,20		;AN000;  SCR_KYB_2
		DW     1		;AN000;
		DW    10,10,23		;AN000;  SCR_FR_KYB
		DW     1		;AN000;
		DW    10,10,23		;AN000;  SCR_IT_KYB
		DW     1		;AN000;
		DW    10,10,23		;AN000;  SCR_UK_KYB
		DW     1		;AN000;
		DW    11,10,20		;AN111;  SCR_DEST_B_C JW
		DW     1		;AN000;
		DW    14, 1,25		;AN000;  SCR_PRT_TYPE
		DW     1		;AN000;
		DW    15, 9,20		;AN000;  SCR_PARALLEL
		DW     1		;AN000;
		DW    16,10,20		;AN000;  SCR_SERIAL
		DW     1		;AN000;
		DW    17, 8,20		;AN000;  SCR_PRT_REDIR
		DW     2		;AN000;
		DW    20, 6,20		;AN000;  SCR_REVIEW
		DW    21, 6,20		;AN000;  SCR_REVIEW
		DW     9		;AN000;
		DW    22,10,11		;AN000;
		DW    23,11,11		;AN000;
		DW    24,12,11		;AN000;
		DW    25, 1,11		;AN000;
		DW    26, 2,11		;AN000;
		DW    27, 3,11		;AN000;
		DW    28, 4,11		;AN000;
		DW    29, 5,11		;AN000;
		DW    30, 6,11		;AN000;
		DW     6		;AN000;
		DW    22,10,11		;AN000;
		DW    24,11,11		;AN000;
		DW    26,12,11		;AN000;
		DW    27, 1,11		;AN000;
		DW    29, 2,11		;AN000;
		DW    30, 3,11		;AN000;  SCR_FUNC_DISKET
		DW     2		;AN000;
		DW    49, 1,11		;AN000;
		DW    50, 1,11		;AN000;  SCR_FIXED_FIRST
		DW     2		;AN000;
		DW    51, 1,11		;AN000;
		DW    52, 1,11		;AN000;  SCR_FIXED_BOTH
		DW     2		;AN000;
		DW    54, 1,11		;AN000;
		DW    55, 1,11		;AN000;  SCR_FORMAT
		DW     0		;AN000;  SCR_CONTEXT_HLP
		DW     0		;AN000;  SCR_INDEX_HLP
		DW     0		;AN000;  SCR_TITLE_HLP
		DW     0		;AN000;
		DW     0		;AN000;
		DW     2		;AN000;  SCR_COPY_DEST		 JW
		DW    18,10,10		;AC035;  SEH new help text
		DW    19,10,10		;AC035;  SEH new help text
		DW     1		;AN000;
		DW    11,10,20		;AN111;  SCR_DEST_A_C JW
		DW     2		;AN000;
		DW    56, 6,20		;AN000;  SCR_choose_screen
		DW    57, 6,20		;AN000;  SCR_choose_screen
SCR_HELP_ID_LEN EQU    28		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	GET_HELP_ID
;
; Entry:
;	AX = 1	for input field help_id's
;	   BX = field_id
;	AX = 2	for scroll help_id's
;	   BX = scroll_id
;	   CX = index
;
; Exit:
;	AX = help_id
;	DH = row'
;	DL = col'
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
THREE	DW	3			;AN000;
					;
	PUBLIC	GET_HELP_ID		;AN000;
GET_HELP_ID	PROC			;AN000;
	CMP	AX,1			;AN000;
	JNE	GH_8			;AN000;
					;
	CMP	AX,INP_HELP_ID_LEN	;AN000;
	JA	GH_8			;AN000;
					;
	PUSH	BX			;AN000;
	PUSH	CX			;AN000;
	MOV	AX,BX			;AN000;
	DEC	AX			;AN000;
	MOV	BX,INP_HELP_ID_ELE*2	;AN000;
	MUL	BX			;AN000;
	MOV	BX,AX			;AN000;
	MOV	AX,CS:[BX].INP_HELP_ID	;AN000;
	MOV	CX,CS:[BX+2].INP_HELP_ID;AN000;
	MOV	DX,CS:[BX+4].INP_HELP_ID;AN000;
	XCHG	CH,CL			;AN000;
	MOV	DH,CH			;AN000;
	POP	CX			;AN000;
	POP	BX			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	AX = 2	for scroll help_id's
;	   BX = scroll_id
;	   CX = index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GH_8:	CMP	AX,2			;AN000;
	JNE	GH_20			;AN000;
					;
	CMP	BX,SCR_HELP_ID_LEN	;AN000;
	JA	GH_20			;AN000;
					;
	OR	CX,CX			;AN000;
	JE	GH_20			;AN000;
					;
	PUSH	CX			;AN000; search for matching scroll_id
	PUSH	SI			;AN000;
	MOV	DX,1			;AN000;
	XOR	SI,SI			;AN000;
					;
GH_9:	CMP	DX,BX			;AN000;
	JE	GH_10			;AN000;
	MOV	AX,CS:[SI]+SCR_HELP_ID	;AN000; get number of help screens
	PUSH	DX			;AN000;
	MUL	THREE			;AN000;
	POP	DX			;AN000;
	ADD	AX,1			;AN000; +additional entries (row',col',count)
	SHL	AX,1			;AN000; account for WORD entries
	ADD	SI,AX			;AN000;
	INC	DX			;AN000;
	CMP	DX,SCR_HELP_ID_LEN	;AN000;
	JBE	GH_9			;AC000; JW Changed to JBE
	JMP	GH_15			;AN000;
					;
GH_10:	CMP	CX,CS:[SI]+SCR_HELP_ID	;AN000; check for index out of range?
	JBE	GH_11			;AN000;  then
	MOV	CX,1			;AN000;  set to first help_id....
					;
GH_11:	MOV	AX,CX			;AN000; scroll_id found!!!!
	DEC	AX			;AN000;
	MUL	THREE			;AN000;
	INC	AX			;AN000;
	SHL	AX,1			;AN000;
	ADD	SI,AX			;AN000;
	MOV	AX,CS:[SI]+SCR_HELP_ID	;AN000;
	MOV	CX,CS:[SI+2].SCR_HELP_ID;AN000;
	MOV	DX,CS:[SI+4].SCR_HELP_ID;AN000;
	XCHG	CH,CL			;AN000;
	MOV	DH,CH			;AN000;
GH_15:	POP	SI			;AN000;
	POP	CX			;AN000;
GH_20:					;AN000;
	RET				;AN000;
GET_HELP_ID	ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	ENDS				;AN000;
	END	GET_HELP_ID		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

