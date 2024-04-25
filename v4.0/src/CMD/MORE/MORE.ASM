;******************************************************************************
;
; MODULE:   more.asm
;
; Modification History:
;
;  Version    Author	       date	   comment
;  -------    ------	       ----	   -------
;  V4.0       RussW			   ;AN000; initial extended attr. support
;
;  V4.0       Bill L	      9/17/87	   ;AN001; DCR 201 - extended attr. enhancement
;					   ;AN002; DCR 191
;					   ;AN003; PTM 3860 - add CR-LF to make DOS3.3 compat.
;******************************************************************************

FALSE	EQU	0
TRUE	EQU	NOT FALSE

IBMVER	EQU	TRUE
IBMJAPVER   EQU FALSE
MSVER	EQU	FALSE

STDOUT	EQU	1			 ;AN003;
;------------------------------
; EXTENDED ATTRIBUTE Equates
;------------------------------
GetExtAttr	      equ     05702h	 ;AN000; ;Int 021h function call
SetExtAttr	      equ     05704h	 ;AN000; ;Int 021h function call
GetCPSW 	      equ     03303h	 ;AN001;

EAISBINARY	      equ     02h	 ;AN001; ;ea_type
EASYSTEM	      equ     8000h	 ;AN001; ;ea_flags

BREAK	MACRO	subtitle
	SUBTTL	subtitle
	PAGE
ENDM

	INCLUDE SYSCALL.INC

	INCLUDE MORE.INC		 ;AN000; ;MORE strucs and equates
	.XLIST				 ;AN000;
	INCLUDE STRUC.INC		 ;AN000; ;Structured macros
	INCLUDE SYSMSG.INC		 ;AN000; ;Message retriever code
	.LIST				 ;AN000;

MSG_UTILNAME <MORE>			 ;AN000;

CODE	SEGMENT PUBLIC
	ORG	100H
ASSUME	CS:CODE,DS:CODE,ES:CODE,SS:CODE


START:	JMP	START1				 ;AC000;
;;;	DB	" The DOS 4.0 MORE Filter"       ;AC003;


;----------------------------------------
;- STRUCTURE TO QUERY EXTENDED ATTRIBUTES
;----------------------------------------
querylist   struc			 ;AN001; ;query general list
qea_num     dw	    1			 ;AN001;
qea_type    db	    EAISBINARY		 ;AN001;
qea_flags   dw	    EASYSTEM		 ;AN001;
qea_namelen db	    ?			 ;AN001;
qea_name    db	    "        "           ;AN001;
querylist   ends			 ;AN001;

cp_qlist    querylist <1,EAISBINARY,EASYSTEM,2,"CP"> ;AN001; ;query code page attr.

cp_list     label   word		 ;AN001; ;code page attr. get/set list
	    dw	    1			 ;AN001; ; # of list entries
	    db	    EAISBINARY		 ;AN001; ; ea type
	    dw	    EASYSTEM		 ;AN001; ; ea flags
	    db	    ?			 ;AN001; ; ea return code
	    db	    2			 ;AN001; ; ea name length
	    dw	    2			 ;AN001; ; ea value length
	    db	    "CP"                 ;AN001; ; ea name
cp	    dw	    ?			 ;AN001; ; ea value (code page)
cp_len	    equ     ($ - cp_list)	 ;AN001;


START1:
	CALL	SYSLOADMSG		 ;AN000;
	.IF C				 ;AN000;
	  CALL	  SYSDISPMSG		 ;AN000;
	  MOV	  AH,EXIT		 ;AN000;
	  INT	  21H			 ;AN000;
	.ENDIF				 ;AN000;

	MOV	AX,ANSI_GET		 ;AN000; ;prepare for device characteristics..
	MOV	BX,STDERR		 ;AN000; ;request.
	MOV	CX,GET_SUBFUNC		 ;AN000; ;get subfucntion..
	LEA	DX,ANSI_BUF		 ;AN000; ;point to buffer.
	INT	21H			 ;AN000;
	.IF NC				 ;AN000; ;if ANSI returns a no carry then..
	  LEA	DI,ANSI_BUF		 ;AN000;
	  .IF <[DI].D_MODE EQ TEXT_MODE> ;AN000; ;if we are in a text mode then..
	    MOV    AX,[DI].SCR_ROWS	 ;AN000; ;store the screen length...else..
	    MOV    MAXROW,AL		 ;AN000; ;default (25) is assumed.
	  .ENDIF			 ;AN000;
	.ENDIF				 ;AN000;
	MOV	AH,0FH
	INT	10H
	MOV	MAXCOL,AH

	XOR	BX,BX			; DUP FILE HANDLE 0
	MOV	AH,XDUP
	INT	21H
	MOV	BP,AX			; Place new handle in BP

	MOV	AH,CLOSE		; CLOSE STANDARD IN
	INT	21H

	MOV	BX,2			; DUP STD ERR TO STANDARD IN
	MOV	AH,XDUP
	INT	21H
cp_check:				;AN001;
	mov	ax,GetCPSW		;AN001;
	int	21h			;AN001; ;DL =0 (Not supported)
	jc	sloop			;AN001; ;no CPSW, skip cp setting
	cmp	dl,0			;AN001; ;Is CPSW active ?
	je	sloop			;AN001; ;no, skip cp setting
;
	mov	ax,GetExtAttr		;AN000; ;Get Codepage of source
	mov	bx,bp			;AN000; ;Standard Input
	mov	si,offset cp_qlist	;AN001; ;code page query list
	mov	cx,cp_len		;AN001; ;length of code page list
	mov	di,offset cp_list	;AC001; ;Input buffer address
	int	021h			;AN000; ;Pow !
	jc	SLOOP			;AN000; ;Do nothing if error
				;Ok, we got CP of source. Set tgt to match...
	mov	ax,SetExtAttr		;AN000; ;Set target codepage to that of source
	mov	bx,1			;AN000; ;Standard Output
	mov	di,offset cp_list	;AC001; ;Input buffer address
	int	021h			;AN000; ;Blam !
;-------------------------------
SLOOP:
	MOV	CX,CRLF_LEN		;AN003; ;display a newline
	MOV	DX,OFFSET CRLF		;AN003;
	MOV	BX,STDOUT		;AN003;
	MOV	AH,WRITE		;AN003;
	INT	21H			;AN003;
ALOOP:
	CLD
	MOV	DX,OFFSET BUFFER
	MOV	CX,4096
	MOV	BX,BP
	MOV	AH,READ
	INT	21H
	OR	AX,AX
	JNZ	SETCX
DONE:	INT	20H
SETCX:	MOV	CX,AX
	MOV	SI,DX

TLOOP:
	LODSB
	CMP	AL,1AH
	JZ	DONE
	CMP	AL,13
	JNZ	NOTCR
	MOV	BYTE PTR CURCOL,1
	JMP	SHORT ISCNTRL

NOTCR:	CMP	AL,10
	JNZ	NOTLF
	INC	BYTE PTR CURROW
	JMP	SHORT ISCNTRL

NOTLF:	CMP	AL,8
	JNZ	NOTBP
	CMP	BYTE PTR CURCOL,1
	JZ	ISCNTRL
	DEC	BYTE PTR CURCOL
	JMP	SHORT ISCNTRL

NOTBP:	CMP	AL,9
	JNZ	NOTTB
	MOV	AH,CURCOL
	ADD	AH,7
	AND	AH,11111000B
	INC	AH
	MOV	CURCOL,AH
	JMP	SHORT ISCNTRL

NOTTB:
	IF	MSVER			; IBM CONTROL CHARACTER PRINT
	CMP	AL,' '
	JB	ISCNTRL
	ENDIF

	IF	IBMVER
	CMP	AL,7			; ALL CHARACTERS PRINT BUT BELL
	JZ	ISCNTRL
	ENDIF

	INC	BYTE PTR CURCOL
	MOV	AH,CURCOL
	CMP	AH,MAXCOL
	JBE	ISCNTRL
	INC	BYTE PTR CURROW
	MOV	BYTE PTR CURCOL,1

ISCNTRL:
	MOV	DL,AL
	MOV	AH,STD_CON_OUTPUT
	INT	21H
	MOV	AH,CURROW
	CMP	AH,MAXROW
	JB	CHARLOOP

ASKMORE:
	PUSH	BP			;AN000; ;save file handle
	PUSH	SI			;AN000; ;save pointer
	PUSH	CX			;AN000; ;save count
	MOV	AX,MORE_MSG		;AN000; ;use message retriever..
	MOV	BX,STDERR		;AN000; ;to issue..
	XOR	CX,CX			;AN000; ;-- More --
	MOV	DL,NO_INPUT		;AN000;
	MOV	DH,UTILITY_MSG_CLASS	;AN000;
	CALL	SYSDISPMSG		;AN000;

	MOV	AH,STD_CON_INPUT_FLUSH	 ;WAIT FOR A KEY, NO ECHO
	MOV	AL,STD_CON_INPUT_NO_ECHO ;AC000; ;no echo
	INT	21H

	CMP	AL,EXTENDED		;AN000; ;Check for extended key?
	JNE	NOT_EXTENDED		;AN000; ;continue
	MOV	AH,STD_CON_INPUT_NO_ECHO ;AN000; ;clear extended key
	INT	21H			;AN000; ;

NOT_EXTENDED:
	MOV	CX,CRLF2_LEN		;AC003; ;place cursor..
	MOV	DX,OFFSET CRLF2 	;AC003; ;..on new line.
	MOV	BX,STDERR		;AN000;
	MOV	AH,WRITE		;AN000;
	INT	21H			;AN000;
	POP	CX			;AN000; ;restore count
	POP	SI			;AN000; ;restore pointer
	POP	BP			;AN000; ;restore file handle

	MOV	BYTE PTR CURCOL,1
	MOV	BYTE PTR CURROW,1

CHARLOOP:
	DEC	CX
	JZ	GOBIG
	JMP	TLOOP
GOBIG:	JMP	ALOOP

MAXROW	DB	25
MAXCOL	DB	80
CURROW	DB	1
CURCOL	DB	1

ANSI_BUF ANSI_STR <>			;AN000; ;buffer for IOCTL call

.XLIST					;AN000;
MSG_SERVICES <MSGDATA>			;AN000; ;message retriever code
MSG_SERVICES <LOADmsg,DISPLAYmsg,NOCHECKSTDIN>	;AN002;
MSG_SERVICES <MORE.CL1> 		;AN000;
MSG_SERVICES <MORE.CL2> 		;AN000;
MSG_SERVICES <MORE.CLA> 		;AN000;
.LIST					;AN000;

CRLF	    DB	   13,10		   ;AC000;
CRLF_LEN    DW	   $ - CRLF		   ;AC000;
CRLF2	    DB	   13,10,13,10		   ;AN003;
CRLF2_LEN   DW	   $ - CRLF2		   ;AN003;

BUFFER	LABEL BYTE

CODE	ENDS
	END	START
