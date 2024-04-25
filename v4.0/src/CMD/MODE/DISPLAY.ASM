;m
PRINTF_CODE SEGMENT PUBLIC

ASSUME CS:PRINTF_CODE, DS:PRINTF_CODE, ES:PRINTF_CODE, SS:PRINTF_CODE


;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  P U B L I C S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º											  º

PUBLIC	 initialize_sublists

;º											  º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  P U B L I C S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

;*****************************************************************************
; External Declarations
;*****************************************************************************
;

EXTRN	 first_sublist:BYTE
EXTRN	 number_of_sublists:ABS
EXTRN	 SysDispMsg:Near






;
;***************************************************************************
; Message Structures
;***************************************************************************
;


Message_Table struc				;				;AN000;
						;
Entry1	dw	0				;				;AN000;
Entry2	dw	0				;				;AN000;
Entry3	dw	0				;				;AN000;
Entry4	dw	0				;				;AN000;
Entry5	db	0				;				;AN000;
Entry6	db	0				;				;AN000;
Entry7	dw	0				;				;AN000;
						;
Message_Table ends				;				;AN000;

include common.stc	      ;contains the following structure

;sublist_def  STRUC

;	      db  ?  ;Sublist Length, fixed
;	      db  ?  ;Reserved, not used yet		       ;AN000;
;	      dw  ?  ;offset
;sublist_seg  dw  ?  ;segment part of pointer to piece of message
;	      db  ?  ;ID, special end of message format ;AN000;
;	      db  ?  ;flags
;	      db  ?
;	      db  ?
;	      db  ?

;sublist_def  ENDS

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³
;³ INITIALIZE_SUBLISTS
;³ -------------------
;³ A .COM file cannot have references to segments in it at EXE2BIN time so
;³ the segment part of pointers to pieces of messages in sublist blocks must
;³ be done at execution time.  This routine does that for all sublists.
;³
;³
;³ INPUT:
;³
;³
;³
;³
;³
;³
;³
;³ RETURN:
;³
;³
;³  MESSAGES:	 none
;³
;³
;³
;³  REGISTER
;³  USAGE AND
;³  COMVENTIONS:
;³
;³
;³
;³  ASSUMPTIONS:
;³
;³
;³  SIDE EFFECT:
;³
;³
;³   ùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùù
;³
;³ BEGIN
;³										³
;³ END										³
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

initialize_sublists  PROC  NEAR 										 ;AN000;

MOV   CX,number_of_sublists											 ;AN000;
MOV   SI,OFFSET first_sublist	       ;address first sublist							 ;AN000;
REPEAT: 													 ;AN000;
   MOV	 [SI].sublist_seg,DS	       ;set up the segment part of the pointer field in the sublist block	 ;AN000;
   ADD	 SI,TYPE sublist_def	       ;point to next sublist block						 ;AN000;
LOOPNZ	repeat													 ;AN000;
														 ;AN000;
RET
														 ;AN000;
initialize_sublists  ENDP

;*****************************************************************************
;PRINTF
;*****************************************************************************
;
;Description: Save all registers, set up registers required for SysDispMsg
;	      routine. This information is contained in a message description
;	      table pointed to by the DX register. Call SysDispMsg, then
;	      restore registers. This routine assumes that the only time an
;	      error will be returned is if an extended error message was
;	      requested, so it will ignore error returns
;
;Called Procedures: sysdispmsg
;
;Change History:    Created	   4/22/87	   MT
;
;Input:    ES:DX = pointer to message description
;
;Output:   None
;
;Psuedocode
;----------
;
;	Save all registers
;	Setup registers for SysDispMsg from Message Description Tables
;	CALL SysDispMsg
;	Restore registers
;	ret
;*****************************************************************************

Public	PRINTF
PRINTF	 PROC  NEAR		     ;				     ;AN000;

;	push	ax
						;Save registers 		;AN000;
	push	bx				; "  "    "  "                  ;AN000;
	push	cx				; "  "    "  "                  ;AN000;
	push	dx				; "  "    "  "                  ;AN000;
	push	si				; "  "    "  "                  ;AN000;
	push	di				; "  "    "  "                  ;AN000;
	mov	di,dx				;Change pointer to table	;AN000;
	mov	ax,[di].Entry1			  ;Message number		  ;AN000;
	mov	bx,[di].Entry2			  ;Handle			  ;AN000;
	mov	si,[di].Entry3			  ;Sublist			  ;AN000;
	mov	cx,[di].Entry4			  ;Count			  ;AN000;
	mov	dh,[di].Entry5			  ;Class			  ;AN000;
	mov	dl,[di].Entry6			  ;Function			  ;AN000;
	mov	di,[di].Entry7			  ;Input			  ;AN000;
	call	SysDispMsg			;Display the message		;AN000;
	pop	di				;Restore registers		;AN000;
	pop	si				; "  "    "  "                  ;AN000;
	pop	dx				; "  "    "  "                  ;AN000;
	pop	cx				; "  "    "  "                  ;AN000;
	pop	bx				; "  "    "  "                  ;AN000;
;	pop	ax				; "  "    "  "                  ;AN000;
	ret					;All done			;AN000;

PRINTF	ENDP			 ;				 ;AN000;

PRINTF_CODE ENDS

	end
