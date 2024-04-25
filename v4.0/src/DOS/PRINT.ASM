;	SCCSID = @(#)print.asm	1.1 85/04/10
;
; PFMT - formatted output.  Calling sequence:
;   PUSH    BP
;   PUSH    fmtstr
;   MOV     BP,SP
;   PUSH    args
;   CALL    PFMT
;   ADD     SP,n
;   POP     BP
;
; The format string contains format directives and normal output characters
; much like the PRINTF for C.  We utilize NO format widths.  Special chars
; and strings are:
;
;       $x      output a hex number
;       $s      output an offset string
;       $c      output a character
;       $S      output a segmented string
;       $p      output userid/processid
;       \t      output a tab
;       \n      output a CRLF
;
; The format string must be addressable via CS
;

Procedure PFMT,NEAR
	SaveReg <AX,BX,DS,SI>
	MOV     AX,8007h
	INT     2Ah
	PUSH    CS
	POP     DS
	SUB     BP,2
	Call    FMTGetArg
	MOV     SI,AX
FmtLoop:
	LODSB
	OR      AL,AL
	JZ      FmtDone
	CMP     AL,'$'
	JZ      FmtOpt
	CMP     AL,'\'
	JZ      FmtChr
FmtOut:
	CALL    Out
	JMP     FmtLoop
Out:
	SaveReg <SI,DI,BP>
	INT     29h
	RestoreReg  <BP,DI,SI>
	return
FmtDone:
	MOV     AX,8107h
	INT     2Ah
	RestoreReg  <SI,DS,BX,AX>
	RET
;
; \ leads in a special character. See what the next char is.
;
FmtChr: LODSB
	OR      AL,AL                   ; end of string
	JZ      fmtDone
	CMP     AL,'n'                  ; newline
	JZ      FmtCRLF
	CMP     AL,'t'                  ; tab
	JNZ     FmtOut
	MOV     AL,9
	JMP     FmtOut
FmtCRLF:MOV     AL,13
	CALL    Out
	MOV     AL,10
	JMP     FmtOut
;
; $ leads in a format specifier.
;
FmtOpt: LODSB
	CMP     AL,'x'                  ; hex number
	JZ      FmtX
	CMP     AL,'c'                  ; single character
	JZ      FmtC
	CMP     AL,'s'                  ; offset string
	JZ      FmtSoff
	CMP     AL,'S'                  ; segmented string
	JZ      FmtSseg
	CMP     AL,'p'
	JZ      FmtUPID
	JMP     FmtOut
FmtX:
	Call    FMTGetArg
	MOV     BX,AX
	CALL    MNUM
	JMP     FmtLoop
FmtC:
	Call    FmtGetArg
	CALL    Out
	JMP     FmtLoop
FmtSoff:
	SaveReg <SI>
	Call    FmtGetArg
	MOV     SI,AX
	CALL    fmtsout
	RestoreReg  <SI>
	JMP     FmtLoop
FmtSSeg:
	SaveReg <DS,SI>
	CALL    FMTGetArg
	MOV     DS,AX
	CALL    FMTGetArg
	MOV     SI,AX
	CALL    fmtsout
	RestoreReg  <SI,DS>
	JMP     FmtLoop
FmtUPID:
	SaveReg <DS>
	MOV     BX,0
	MOV     DS,BX
	MOV     DS,DS:[82h]
	ASSUME  DS:DOSGroup
	MOV     BX,User_ID
	CALL    MNUM
	MOV     AL,':'
	CALL    OUT
	MOV     BX,Proc_ID
	CALL    MNUM
	RestoreReg  <DS>
	Assume  DS:NOTHING
	JMP     FmtLoop
EndProc PFMT

Procedure   FMTGetArg,NEAR
	MOV     AX,[BP]
	SUB     BP,2
	return
EndProc FMTGetArg

Procedure   FmtSOut,NEAR
	LODSB
	OR      AL,AL
	retz
	CALL    OUT
	JMP     FmtSOut
EndProc FMTSout

;
;   MOut - output a message via INT 29h
;   Inputs:     BX points to bytes to output relative to CS
;   Outputs:    message
;   Registers modified: BX
Procedure   MOut,Near
	ASSUME  DS:NOTHING,SS:NOTHING,ES:NOTHING
	PUSHF
	SaveReg <DS,SI,AX>
	PUSH    CS
	POP     DS
	MOV     SI,BX
	Call    FMTSout
	RestoreReg  <AX,SI,DS>
	POPF
	return
EndProc MOut

;   MNum - output a number in BX
;   Inputs:     BX contains a number
;   Outputs:    number in hex appears on screen
;   Registers modified: BX

Procedure   MNum,NEAR
	ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSHF
	SaveReg <ES,DI,AX,BX,CX,SI,DS>
	PUSH    SS
	POP     ES
	SUB     SP,6
	MOV     DI,SP                   ;   p = MNumBuf;
	SaveReg <DI>
	MOV     CX,4                    ;   for (i=0; i < 4; i++)
DLoop:  SaveReg <CX>
	MOV     CX,4                    ;       rotate(n, 4);
	ROL     BX,CL
	RestoreReg  <CX>
	MOV     AL,BL
	AND     AL,0Fh
	ADD     AL,'0'
	CMP     AL,'9'
	JBE     Nok
	ADD     AL,'A'-'0'-10
Nok:    STOSB                           ;       *p++ = "0123456789ABCDEF"[n];
	LOOP    DLoop
	XOR     AL,AL
	STOSB                           ;   *p++ = 0;
	RestoreReg  <SI>
	PUSH    ES
	POP     DS
	CALL    FMTSOUT                 ;   mout (mNumBuf);
	ADD     SP,6
	RestoreReg  <DS,SI,CX,BX,AX,DI,ES>
	POPF
	return
EndProc MNum
