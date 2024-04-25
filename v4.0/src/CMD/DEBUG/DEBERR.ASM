	PAGE	80,132 ;
	TITLE	DEBERR.ASM - DEBUGGER DISK ERROR HANDLER

;******************* START OF SPECIFICATIONS *****************************
;
; MODULE NAME:DEBERR.SAL
;
; DESCRIPTIVE NAME: DISK ERROR HANDLER
;
; FUNCTION: THIS ROUTINE IS A CATCHALL ERROR HANDLER.  IT PRIMARILY
;	    HANDLES DISK ERROR.
;
; ENTRY POINT: ANY CALLED ROUTINE
;
; INPUT: NA
;
; EXIT-NORMAL: NA
;
; EXIT-ERROR: NA
;
; INTERNAL REFERENCES:
;
;
; EXTERNAL REFERENCES:
;
; NOTES: THIS MODULE SHOULD BE PROCESSED WITH THE SALUT PRE-PROCESSOR
;	 WITH OPTIONS "PR".
;	 LINK DEBUG+DEBCOM1+DEBCOM2+DEBCOM3+DEBASM+DEBUASM+DEBERR+DEBCONST+
;	      DEBDATA+DEBMES
;
; REVISION HISTORY:
;
;	AN000	VERSION DOS 4.0 - MESSAGE RETRIEVER IMPLEMENTED.  DMS:6/17/87
;
;
; COPYRIGHT: "MS DOS DEBUG Utility"
;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Property of Microsoft  "
;
;******************** END OF SPECIFICATIONS ******************************


	IF1
	    %OUT COMPONENT=DEBUG, MODULE=DEBERR
	ENDIF
.XLIST
.XCREF
	INCLUDE DOSSYM.INC
.CREF
.LIST

	INCLUDE DEBEQU.ASM

FIRSTDRV EQU	"A"

CODE	SEGMENT PUBLIC BYTE
CODE	ENDS

CONST	SEGMENT PUBLIC BYTE
	EXTRN	RDFLG:BYTE
	EXTRN	DRVLET:BYTE
	EXTRN	dr1_ptr:word,dr2_ptr:word,dr3_ptr:word,dr4_ptr:word ;ac000
CONST	ENDS

CSTACK	SEGMENT STACK
CSTACK	ENDS

DATA	SEGMENT PUBLIC BYTE
	EXTRN	PARITYFLAG:BYTE
DATA	ENDS

DG	GROUP	CODE,CONST,CSTACK,DATA

CODE	SEGMENT PUBLIC BYTE
	ASSUME	CS:DG,DS:DG,ES:DG,SS:DG

	EXTRN	RESTART:NEAR
	PUBLIC	DRVERR, TRAPPARITY, RELEASEPARITY, NMIINT, NMIINTEND

TRAPPARITY:
	IF	IBMJAPAN
	    PUSH    BX
	    PUSH    ES
	    PUSH    DX			; save location of new offset
	    MOV     DX,OFFSET DG:NMIINT ; DS:DX has new interrupt vector
	    CALL    SWAPINT		; diddle interrupts
	    ASSUME  ES:NOTHING

	    MOV     WORD PTR [NMIPTR],BX ; save old offset
	    MOV     WORD PTR [NMIPTR+2],ES ; save old segment
	    POP     DX			; get old regs back
	    POP     ES			; restore old values
	    ASSUME  ES:DG

	    POP     BX
	    MOV     BYTE PTR [PARITYFLAG],0 ; no interrupts detected yet!
	    RET

SWAPINT:
	    PUSH    AX
	    MOV     AX,(GET_INTERRUPT_VECTOR SHL 8) + 2
	    INT     21H 		; Get old NMI Vector
	    MOV     AX,(SET_INTERRUPT_VECTOR SHL 8) + 2
	    INT     21h 		; let OS set new vector
	    POP     AX
	ENDIF
	RET

RELEASEPARITY:
	IF	IBMJAPAN
	    PUSH    DX
	    PUSH    DS
	    PUSH    BX
	    PUSH    ES
	    LDS     DX,DWORD PTR [NMIPtr] ; get old vector
	    CALL    SwapInt		; diddle back to original
	    POP     ES
	    POP     BX
	    POP     DS
	    POP     DX
	    MOV     [PARITYFLAG],0	; no interrupts possible!
	ENDIF
	RET

NMIInt:
	IF	IBMJAPAN
	    PUSH    AX			; save AX
	    IN	    AL,0A0H		; get status register
	    OR	    AL,1		; was there parity check?
	    POP     AX			; get old AX back
	    JZ	    NMICHAIN		; no, go chain interrupt
	    OUT     0A2H,AL		; reset NMI detector
	    MOV     CS:[PARITYFLAG],1	; signal detection
	    IRET
NMICHAIN:
	    JMP     DWORD PTR CS:[NMIPTR] ; chain the vectors
NMIPTR	    DD	    ?			; where old NMI gets stashed
	ENDIF
NMIINTEND:

DRVERR:

	or	al,al				;ac000;see if drive specified
;	$if	nz				;an000;drive specified
	JZ $$IF1
		add	byte ptr drvlet,firstdrv;ac000;determine drive letter
		cmp	byte ptr rdflg,write	;ac000;see if it is read/write
;		$if	z			;an000;it is write
		JNZ $$IF2
			mov	dx,offset dg:dr2_ptr	;an000;message
;		$else				;an000;it is read
		JMP SHORT $$EN2
$$IF2:
			mov	dx,offset dg:dr1_ptr	;an000;message
;		$endif				;an000;
$$EN2:
;	$else					;an000;write protect error
	JMP SHORT $$EN1
$$IF1:
		add	byte ptr drvlet,firstdrv;ac000;determine drive letter
		cmp	byte ptr rdflg,write	;ac000;see if it is read/write
;		$if	z			;an000;it is write
		JNZ $$IF6
			mov	dx,offset dg:dr4_ptr	;an000;message
;		$else				;an000;it is read
		JMP SHORT $$EN6
$$IF6:
			mov	dx,offset dg:dr3_ptr	;an000;message
;		$endif				;an000;
$$EN6:
;	$endif					;an000;
$$EN1:

; CLEAN OUT THE DISK...
	MOV	AH,DISK_RESET
	INT	21H

	JMP	RESTART
CODEEND:

CODE	ENDS
	END
