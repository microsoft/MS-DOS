TITLE	CHKPROC2 - PART2 Procedures called from chkdsk
page	,132					;

	.xlist
	include chkseg.inc							;an005;bgb
	INCLUDE CHKCHNG.INC
	INCLUDE DOSSYM.INC
	INCLUDE CHKEQU.INC
	INCLUDE CHKMACRO.INC
	include pathmac.inc

CONST	SEGMENT PUBLIC PARA  'DATA'
	EXTRN	FIXMES_ARG:word 						;an049;bgb
	EXTRN	FATAL_ARG:word
	EXTRN	BADW_ARG:word,FATAL_END:word
	EXTRN	badrw_num:word,BADRW_STR:WORD,HAVFIX:byte
	EXTRN	DIRTYFAT:byte,CROSSCNT:dword,DOFIX:byte,SECONDPASS:byte
	EXTRN	BADSIZ:word,ORPHSIZ:word,ORPHFCB:byte
	EXTRN	HECODE:byte,USERDIR:byte,FRAGMENT:byte
	EXTRN	ORPHEXT:byte,ALLDRV:byte,FIXMFLG:byte,DIRCHAR:byte
	EXTRN	EOFVAL:word,BADVAL:word
	extrn	fTrunc:BYTE
CONST	ENDS

DATA	SEGMENT PUBLIC PARA 'DATA'
	extrn	fatcnt:byte, orph_arg:word			  ;an005;bgb;an049;bgb
	EXTRN	THISDPB:dword,NUL_ARG:byte
	EXTRN	NAMBUF:byte,SRFCBPT:word,FATMAP:word
	EXTRN	MCLUS:word,CSIZE:byte,SSIZE:word
	EXTRN	DSIZE:word,ARG_BUF:byte,ERRCNT:byte
	EXTRN	USERDEV:byte,HARDCH:dword,CONTCH:dword
	EXTRN	ExitStatus:Byte,Read_Write_Relative:Byte
	extrn	bytes_per_sector:word						;an005;bgb
	extrn	fattbl_seg:word, fatsiz:word,  paras_per_fat:word		;an005;bgb
	extrn	fatmsg1:word							;an024;bgb
	extrn	fatmsg2:word							;an024;bgb
	EXTRN	dbcs_vector:byte						;an055;bgb
	EXTRN	dbcs_vector_off:word						;an055;bgb
	EXTRN	dbcs_vector_seg:word						;an055;bgb
DATA	ENDS

CODE	SEGMENT PUBLIC PARA 'CODE'
ASSUME	CS:DG,DS:DG,ES:DG,SS:DG
	EXTRN	PRINTF_CRLF:NEAR,FCB_TO_ASCZ:NEAR
	EXTRN	PROMPTYN:NEAR,DIRPROC:NEAR
	EXTRN	DOCRLF:NEAR,UNPACK:NEAR,PACK:NEAR
	EXTRN	CHECKNOFMES:NEAR
	EXTRN	multiply_32_bits:near					     ;an047;bgb
	extrn	nowrite:near, done:near, pack:near, unpack:near
	extrn	promptrecover:near, findchain:near
public RECOVER, DoAsk
public MAKORPHNAM, NAM0, NAMMADE
public GETFILSIZ, NCLUS, GOTEOF, CHKCROSS, RET8
public FATAL, hav_fatal_arg,  INT_23, RDONE
public Systime									;an005;bgb
public int_24									;an005;bgb
public CHECK_DBCS_CHARACTER							;an055;bgb
	.list



	pathlabl chkproc2
;*****************************************************************************
; RECOVER -
; free orphans or do chain recovery.  Note that if we have NOT been able to
; process the entire tree (due to inability to CHDIR), we temporarily set
; DoFix to FALSE, do the operation, and then reset it.
;
; inputs:   si - total number of clusters
;	    es - points to fatmap
;
; outputs:  orphaned clusters are converted to files
; LOGIC
;	- display dont fix msg if appropriate
;	- display number of lost clusters
;	- ask the user if he wants the chains converted to files
;***************************************************************************
RECOVER:
    mov     al,1
    xchg    al,[fixmflg]
    or	    al,al
;   $IF     Z				; where there any errors found?
    JNZ $$IF1
	cmp	[dofix],0		; yes - is the /f flag off?
;	$IF	Z			; yes - display the dont fix msg
	JNZ $$IF2
	    mov     dx,offset dg:FIXMES_arg
	    CALL    PRINTf_crlf
	    call    DoCRLF			    ;				    ;AN000;
;	$ENDIF
$$IF2:
;   $ENDIF
$$IF1:
    CALL    DOCRLF
CHAINREPORT:
;;;;mov     si,orphsiz		   ;get number of bad clusters found (recover)	;an005;bgb;an049;bgb
;;;;mov     [orph_num],si	   ; Prints "XXX lost clusters found in YYY chains.";an049;bgb
    call    findchain		   ;   On entry SI is the XXX value and the YYY value is
    mov     dx,offset dg:orph_arg  ;   in orphan-count.
    call    printf_crlf
    TEST    fTrunc,-1
;   $IF     NZ
    JZ $$IF5
	XOR	AX,AX	     ; We have truncated the scan.  Set DoFix to FALSE,
	XCHG	AL,DoFix     ; do the operation and then restore things.
	PUSH	AX
	CALL	PromptRecover
	POP	AX
	MOV	DoFix,AL
DoAsk:
;   $ELSE
    JMP SHORT $$EN5
$$IF5:
	CALL	PromptRecover
;   $ENDIF
$$EN5:
    return








;*****************************************************************************
;*****************************************************************************
MAKORPHNAM:
	PUSH	SI
	MOV	SI,OFFSET DG:ORPHEXT - 1
NAM0:
	INC	BYTE PTR [SI]
	CMP	BYTE PTR [SI],'9'
	JLE	NAMMADE
	MOV	BYTE PTR [SI],'0'
	DEC	SI
	JMP	NAM0

NAMMADE:
	POP	SI
	RET




;*****************************************************************************
; GETFILSIZ - calculate the file size based on the number of clusters.
;
; WARNING!! NOTE!! -->
;
; called by - PROCEDURE NAME
;
; inputs: AX -
;	  BX -
;	  CX -
;	  DX -
;	  SP -
;	  BP -
;	  SI - conatins the starting cluster number
;	  DI -
;	  DS -
;	  ES -
;
; output: AX - low word of the file size
;	  BX -
;	  CX -
;	  DX - hi  word of the file size
;	  SP -
;	  BP -
;	  SI -
;	  DI -
;	  DS -
;	  ES -
;
; Regs abused - none
;
;logic: 1. save bx & cx for 32 bit mul
;
;	2. zero out file size results
;
;	3. do for all clusters:
;
;	   4. get the next one and inc cluster counter
;
;	5. multiply clusters times sectors per cluster to give
;	   number of sectors in file.  This can be a 2 word value - DX:AX.
;
;	6. multiply the sectors times the number of bytes per sector.  This
;	   yields the number of bytes in the file.
;*****************************************************************************
;SI is start cluster, returns filesize as DX:AX
Procedure getfilsiz,near
    savereg <bx,cx>
	XOR	AX,AX			;zero out low word
	XOR	DX,DX			;zero out high word
	OR	SI,SI			;did we get a zero cluster?
;	$if	NZ
	JZ $$IF8
;	    $DO 			;do for all clusters
$$DO9:
NCLUS:		CALL	UNPACK		;find the next cluster
		XCHG	SI,DI		;put output into input for unpack
		INC	AX		;found another cluster
		CMP	SI,[EOFVAL]	;did we find last cluster?
;	    $leave    ae		;yes, so exit loop
	    JAE $$EN9
					;;;;;;;CMP     SI,2
					;;;;;;;JAE     NCLUS
;	    $enddo
	    JMP SHORT $$DO9
$$EN9:
GOTEOF:
	    MOV     BL,[CSIZE]		;get sectors per cluster
	    XOR     BH,BH
	    MUL     BX			;clusters * secs/cluster = sectors
	    mov     bx,dx		;get high num for 32bit mult
	    mov     cx,ssize		;cx = word to mult with
	    call    multiply_32_bits	;mul bx:ax * cx
	    mov     dx,bx		;save high word
;	$endif
$$IF8:
    restorereg <bx,cx>
  return
EndProc getfilsiz



;*****************************************************************************
;*****************************************************************************
Public Chkcross
CHKCROSS:
;Check for Crosslinks, do second pass if any to find pairs
	MOV	SI,word ptr CROSSCNT
	cmp	word ptr crosscnt,0	;if there is at least one crossed
;	$if	nz,or
	JNZ $$LL13
	cmp	word ptr crosscnt+2,0
;	$if	nz
	JZ $$IF13
$$LL13:
	    CALL    DOCRLF		;display another line
	    MOV     SecondPass,True	;	     ;				     ;AC000;
	    XOR     AX,AX		;
	    PUSH    AX
	    PUSH    AX
	    CALL    DIRPROC			    ;Do it again
;	$endif
$$IF13:
RET8:	RET



;*****************************************************************************
;*****************************************************************************
FATAL:
;Unrecoverable error
	mov	dx,offset dg:FATAL_arg
	mov	[fatmsg1],bx							;an024;bgb
	cmp	byte ptr [nul_arg],0
	jnz	hav_fatal_arg
	mov	[fatmsg2],offset dg:fatal_end
hav_fatal_arg:
	CALL	PRINTf_crlf
	MOV	DL,[USERDEV]			;At least leave on same drive
	DOS_Call Set_Default_Drive		;				;AC000;
						;MOV	 AH,EXIT
	mov	ExitStatus,Bad_Exit		;Get return code			;AC000;
						;INT	 21H
	ret					;Ret Main_Init for common exit




;*****************************************************************************
;*****************************************************************************
iNT_24	PROC	FAR
aSSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSHF
	push	ax				;Save AX register		;AN000;
	test	al,Disk_Error			;Is it a disk critical err?
;	$IF	Z				;Yes
	JNZ $$IF15
	   mov	   ax,di			;Get error (DI low)		;AN000;
	   cmp	   al,Write_Protect		;Special case errors		;AN000;
;	   $IF	   E,OR 			;If write protect or		;AN000;
	   JE $$LL16
	   cmp	   al,Drive_Not_Ready		; if drive not ready		;AN000;
	   pop	   ax				;Balance stack again		;AN000;
;	   $IF	   E				;				;AN000;
	   JNE $$IF16
$$LL16:
	      CALL    dword ptr HardCh		; let parent's handler decide what to do
;	   $ELSE				;Other error			;AN000;
	   JMP SHORT $$EN16
$$IF16:
	      pop     ax			;balance stack			;AN000;
	      mov     al,Critical_Error_Fail	;Fail the operation		;AN000;
;	   $ENDIF				;				;AN000;
$$EN16:
;	$ELSE					;Not disk error
	JMP SHORT $$EN15
$$IF15:
	   CALL    dword ptr HardCh		; let parent's handler decide what to do
;	$ENDIF
$$EN15:
	CMP	AL,2				;Abort? 			;AC000;
;	$IF	E				;Yes				;AC000;
	JNE $$IF21
	   STI					;Turn off Interrupts
	   CALL    DONE 			;Forget about directory, restore users drive
	   mov	   ExitStatus,Bad_Exit		;Get return code			;AN000;
;	$ENDIF					;AN000;
$$IF21:
	IRET
iNT_24	ENDP




;*****************************************************************************
;*****************************************************************************
INT_23	proc	far
	STI
	LDS	DX,[HARDCH]
	mov	al,24h				;				;AC000;
	DOS_Call Set_Interrupt_Vector		;				;AC000;
	LDS	DX,cs:[CONTCH]							;ac039;bgb
	mov	al,23h				;				;AC000;
	DOS_Call Set_Interrupt_Vector		;				;AC000;
	PUSH	CS
	POP	DS
ASSUME	DS:DG
	MOV	[FRAGMENT],0
RDONE:
	CALL	NOWRITE 			;Restore users drive and directory
						;MOV	 AH,EXIT
						;MOV	 AL,0FFH
						;INT	 21H
	mov	ExitStatus,Bad_Exit		;Get return code			;AC000;
	stc
	ret					;Ret for common exit			;AN000;
int_23	endp





;*****************************************************************************
;*****************************************************************************
;
; Systime returns the current date in AX, current time in DX
;   AX - HHHHHMMMMMMSSSSS  hours minutes seconds/2
;   DX - YYYYYYYMMMMDDDDD  years months days
;
public	Systime
Systime:
	DOS_Call Get_Time			;				;AC000;
	SHL	CL,1				;Minutes to left part of byte
	SHL	CL,1
	SHL	CX,1				;Push hours and minutes to left end
	SHL	CX,1
	SHL	CX,1
	SHR	DH,1				;Count every two seconds
	OR	CL,DH				;Combine seconds with hours and minutes
	MOV	DX,CX
	PUSH	DX				; Save time
;
; WARNING!  MONTH and YEAR must be adjacently allocated
;
	DOS_Call Get_Date			;				;AC000;
	SUB	CX, 1980
	MOV	AX, CX
	MOV	CL, 4
	SHL	AL, CL				; Push year to left for month
	OR	AL, DH				; move in month
	MOV	CL,4
	SHL	AX,CL				;Push month to left to make room for day
	SHL	AX,1
	OR	AL, DL
	POP	DX				; Restore time
	XCHG	AX, DX				; Switch time and day
	return


;*****************************************************************************	;an055;bgb
;Routine name: Check_DBCS_CharACter						;an055;bgb
;*****************************************************************************	;an055;bgb
;										;an055;bgb
;Description: Check if specified byte is in rANges of DBCS vectors		;an055;bgb
;										;an055;bgb
;Called Procedures: None							;an055;bgb
;										;an055;bgb
;ChANge History: Created	6/12/87 	MT				;an055;bgb
;										;an055;bgb
;Input: AL = CharACter to check for DBCS lead charACter 			;an055;bgb
;	DBCS_Vector = YES/NO							;an055;bgb
;										;an055;bgb
;Output: CY set if DBCS charACter						;an055;bgb
;	 DBCS_VECTOR = YES							;an055;bgb
;										;an055;bgb
;										;an055;bgb
;Psuedocode									;an055;bgb
;----------									;an055;bgb
;	Save registers								;an055;bgb
;	IF DBCS vector not found						;an055;bgb
;	   Get DBCS environmental vector (INT 21h				;an055;bgb
;	   Point at first set of vectors					;an055;bgb
;	ENDIF									;an055;bgb
;	SEARCH									;an055;bgb
;	LEAVE End of DBCS vectors						;an055;bgb
;	EXITIF CharACter > X1,AND  (X1,Y1) are environment vectors		;an055;bgb
;	EXITIF CharACter < Y1							;an055;bgb
;	  STC (DBCS charACter)							;an055;bgb
;	ORELSE									;an055;bgb
;	   Inc pointer to next set of vectors					;an055;bgb
;	ENDLOOP 								;an055;bgb
;	   CLC (Not DBCS charACter)						;an055;bgb
;	ENDSRCH 								;an055;bgb
;	Restore registers							;an055;bgb
;	ret									;an055;bgb
;*****************************************************************************	;an055;bgb
DBCS_Vector_Size	equ 2							;an055;bgb
end_of_vector		equ 0							;an055;bgb
Procedure	Check_DBCS_Character		      ; 			;an055;bgb
	push	ds				;Save registers 		;an055;bgb
	push	si				; "  "	  "  "			;an055;bgb
	push	ax				; "  "	  "  "			;an055;bgb
;;;;;;;;push	ds				; "  "	  "  "			;an055;bgb
;;;;;;;;pop	es				;Establish addressability	;an055;bgb
	cmp	byte ptr es:DBCS_VECTOR,Yes	;Have we set this yet?		;an055;bgb
;	$IF	NE				;Nope				;an055;bgb
	JE $$IF23
	   push    ax				   ;Save input charACter	   ;an055;bgb
	   mov	   al,0 			;Get DBCS environment vectors	;an055;bgb
	   DOS_Call Hongeul			;  "  "    "  " 		;an055;bgb
	   mov	   byte ptr es:DBCS_VECTOR,YES	;Indicate we've got vector      ;an055;bgb
	   mov	   es:DBCS_Vector_Off,si	;Save the vector		;an055;bgb
	   mov	   ax,ds			;				;an055;bgb
	   mov	   es:DBCS_Vector_Seg,ax	;				;an055;bgb
	   pop	   ax				   ;Restore input charACter	   ;an055;bgb
;	$ENDIF					; for next time in		;an055;bgb
$$IF23:
	mov	si,es:DBCS_Vector_Seg		;Get saved vector pointer	;an055;bgb
	mov	ds,si				;				;an055;bgb
	mov	si,es:DBCS_Vector_Off		;				;an055;bgb
;	$SEARCH 				;Check all the vectors		;an055;bgb
$$DO25:
	   cmp	   word ptr ds:[si],End_Of_Vector ;End of vector table? 	;an055;bgb
;	$LEAVE	E				;Yes, done			;an055;bgb
	JE $$EN25
	   cmp	   al,ds:[si]			;See if char is in vector	;an055;bgb
;	$EXITIF AE,AND				;If >= to lower, ANd		;an055;bgb
	JNAE $$IF25
	   cmp	   al,ds:[si+1] 		; =< thAN higher rANge		;an055;bgb
;	$EXITIF BE				; then DBCS charACter		;an055;bgb
	JNBE $$IF25
	   stc					;Set CY to indicate DBCS	;an055;bgb
;	$ORELSE 				;Not in rANge, check next	;an055;bgb
	JMP SHORT $$SR25
$$IF25:
	   add	   si,DBCS_Vector_Size		;Get next DBCS vector		;an055;bgb
;	$ENDLOOP				;We didn't find DBCS char       ;an055;bgb
	JMP SHORT $$DO25
$$EN25:
	   clc					;Clear CY for exit		;an055;bgb
;	$ENDSRCH				;				;an055;bgb
$$SR25:
	pop	ax				;Restore registers		;an055;bgb
	pop	si				; "  "	  "  "			;an055;bgb
	pop	ds				;Restore data segment		;an055;bgb
	ret					;				;an055;bgb
Check_DBCS_CharACter endp			;				;an055;bgb



	pathlabl chkproc2
CODE	ENDS
	END
