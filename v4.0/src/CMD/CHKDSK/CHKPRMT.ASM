TITLE	CHKPRMT - Procedures called from chkdsk which prompt			;an000;bgb
page	,132					;				;an000;bgb
										;an000;bgb
	.xlist									;an000;bgb
	include chkseg.inc							;an000;bgb
	INCLUDE CHKCHNG.INC							;an000;bgb
	INCLUDE SYSCALL.INC							;an000;bgb
	INCLUDE CHKEQU.INC							;an000;bgb
	INCLUDE CHKMACRO.INC							;an000;bgb
	include pathmac.inc							;an000;bgb
	.list									;an000;bgb
										;an000;bgb
										;an000;bgb
CONST	SEGMENT PUBLIC PARA 'DATA'						;an000;bgb
	EXTRN	YES_BYTE:BYTE,NO_BYTE:BYTE					;an000;bgb
	EXTRN	YN_ARG:WORD							;an000;bgb
	EXTRN	HECODE:byte,CONBUF:byte 					;an000;bgb
CONST	ENDS									;an000;bgb
										;an000;bgb
										;an000;bgb
CODE	SEGMENT PUBLIC PARA 'CODE'						;an000;bgb
ASSUME	CS:DG,DS:DG,ES:DG,SS:DG 						;an000;bgb
	EXTRN	PRINTF_CRLF:NEAR,DOCRLF:NEAR					;an000;bgb
										;an000;bgb
	pathlabl chkprmt							;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name:PromptYN								;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;description: Validate that input is valid Y/N for the country dependent info	;an000;bgb
;	     Return Z flag if 'Y' entered					;an000;bgb
;Called Procedures: Message (macro)						;an000;bgb
;		    User_String 						;an000;bgb
;										;an000;bgb
;Change History: Created	5/10/87 	MT				;an000;bgb
;										;an000;bgb
;Input: DX = offset to message							;an000;bgb
;										;an000;bgb
;Output: Z flag if 'Y' entered							;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	DO									;an000;bgb
;	   Display prompt and input character					;an000;bgb
;	   IF got character							;an000;bgb
;	      Check for country dependent Y/N (INT 21h, AX=6523h Get Ext Country;an000;bgb)
;	      IF NC (Yes or No) 						;an000;bgb
;		 Set Z if Yes, NZ if No 					;an000;bgb
;	      ENDIF								;an000;bgb
;	   ELSE  (nothing entered)						;an000;bgb
;	      stc								;an000;bgb
;	   ENDIF								;an000;bgb
;	ENDDO NC								;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
Procedure PromptYN				;				;an000;bgb;AN000;
	push	si				;Save reg			;an000;bgb
;	$DO					;				;an000;bgb;AC000;
$$DO1:
	   Call    Display_Interface		;Display the message		;an000;bgb;AC000;
	   MOV	   DX,OFFSET DG:CONBUF		;Point at input buffer		;an000;bgb
	   DOS_Call Std_Con_String_Input	;Get input			;an000;bgb;AC000;
	   CALL    DOCRLF			;				;an000;bgb
	   MOV	   SI,OFFSET DG:CONBUF+2	;Point at contents of buffer	;an000;bgb
	   CMP	   BYTE PTR [SI-1],0		;Was there input?		;an000;bgb
;	   $IF	   NE				;Yep				;an000;bgb;AC000;
	   JE $$IF2
	      mov     al,23h			;See if it is Y/N		;an000;bgb;AN000;
	      mov     dl,[si]			;Get character			;an000;bgb;AN000;
	      DOS_Call GetExtCntry		;Get country info call		;an000;bgb;AN000;
;	      $IF     NC			;Yes or No entered		;an000;bgb;AN000;
	      JC $$IF3
		 cmp	 ax,Yes_Found		;Set Z if Yes, NZ if No 	;an000;bgb;AN000;
		 clc				;CY=0 means Y/N found		;an000;bgb
;	      $ENDIF				;CY set if neither		;an000;bgb;AN000;
$$IF3:
;	   $ELSE				;No characters input		;an000;bgb
	   JMP SHORT $$EN2
$$IF2:
	      stc				;CY means not Y/N		;an000;bgb
;	   $ENDIF				;				;an000;bgb
$$EN2:
;	$ENDDO	NC				;				;an000;bgb;AN000;
	JC $$DO1
	pop	si				;				;an000;bgb
	ret					;				;an000;bgb
PromptYN endp					;				;an000;bgb;AN000;
	pathlabl chkprmt							;an000;bgb
										;an000;bgb
CODE	ENDS									;an000;bgb
	END									;an000;bgb
