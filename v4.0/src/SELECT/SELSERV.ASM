

PAGE 55,132				;AN000;
NAME	SELSERV 			;AN000;
TITLE	SELSERV - SELECT Services	;AN000;
SUBTTL	selserv.asm			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	ADJUST_CURELE
;
;
; Entry:
;	AX = index on entry
;
; Exit:
;	AX = adjusted index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	SEGMENT PARA PUBLIC 'SELECT'    ;AN000;segment for far routine
	ASSUME	CS:SELECT		;AN000;
					;
	EXTRN	WR_SCBID:WORD		;AN000;
					;
SCROLL_ADJUST	LABEL	BYTE		;AN000;
	DB	1		 ;AN000;SCR_DOS_SUPPORT
	DB	1		 ;AN000;SCR_CTY_KYB
	DB	0		 ;AN000;SCR_CTY_1
	DB	0		 ;AN000;SCR_CTY_2
	DB	0		 ;AN000;SCR_KYB_1
	DB	0		 ;AN000;SCR_KYB_2
	DB	1		 ;AN000;SCR_FR_KYB
	DB	1		 ;AN000;SCR_IT_KYB
	DB	1		 ;AN000;SCR_UK_KYB
	DB	1		 ;AN000;SCR_DEST_DRIVE
	DB	0		 ;AN000;SCR_PRT_TYPE
	DB	1		 ;AN000;SCR_PARALLEL
	DB	0		 ;AN000;SCR_SERIAL
	DB	0		 ;AN000;SCR_PRT_REDIR
	DB	1		 ;AN000;SCR_REVIEW
	DB	0		 ;AN000;SCR_FUNC_DISK
	DB	0		 ;AN000;SCR_FUNC_DISKET
	DB	1		 ;AN000;SCR_FIXED_FIRST
	DB	1		 ;AN000;SCR_FIXED_BOTH
	DB	1		 ;AN000;SCR_FORMAT
	DB	0		 ;AC000;SCR_CONTEXT_HLP / SCR_INDEX_HLP JW
	DB	0		 ;AN000;SCR_TITLE_HLP
	DB	0		 ;AN000;SCR_ACC_CTY   JW
	DB	0		 ;AN000;SCR_ACC_KYB   JW
	DB	0		 ;AN000;SCR_ACC_PRT   JW
	DB	1		 ;AC035;SCR_COPY_DEST SEH
	DB	0		 ;AN035;SCR_DEST_A_C; SEH
	DB	1		 ;mrw  ;scr_choose_shell
SCROLL_ADJUST_LEN  EQU	($-SCROLL_ADJUST);AN000;
ADJUST_ON	EQU	1	 ;AN000;
ADJUST_OFF	EQU	0	 ;AN000;
					;
	PUBLIC	ADJUST_UP,ADJUST_DOWN	;AN000;
					;
ADJUST_UP	PROC			;AN000;
	PUSH	BX			;AN000;
	PUSH	CX			;AN000;
	OR	AX,AX			;AN000;
	JZ	AC_1			;AN000;
					;
	MOV	CL,ADJUST_ON		;AN000;
	CMP	CS:[BX-1]+SCROLL_ADJUST,CL;AN000;
	JNE	AC_1			;AN000;
					;
	SHL	AX,1			;AN000;
	DEC	AX			;AN000;
AC_1:	POP	CX			;AN000;
	POP	BX			;AN000;
	RET				;AN000;
ADJUST_UP	ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	ADJUST_INDEX
;
;	AX = index on entry
;
;	AX = adjusted index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ADJUST_DOWN	PROC			;AN000;
	PUSH	BX			;AN000;
	PUSH	CX			;AN000;
	OR	AX,AX			;AN000;
	JZ	AI_1			;AN000;
					;
	MOV	CL,ADJUST_ON		;AN000;
	CMP	CS:[BX-1]+SCROLL_ADJUST,CL;AN000;
	JNE	AC_1			;AN000;
					;
	SHR	AX,1			;AN000;
	INC	AX			;AN000;
AI_1:	POP	CX			;AN000;
	POP	BX			;AN000;
	RET				;AN000;
ADJUST_DOWN	ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT	ENDS				;AN000;
	END				;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
