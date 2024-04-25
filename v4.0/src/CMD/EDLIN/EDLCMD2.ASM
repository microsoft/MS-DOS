	PAGE 60,132
TITLE Edlcmd2 - PART2 procedures called from EDLIN


;======================= START OF SPECIFICATIONS =========================
;
; MODULE NAME: EDLCMD2.SAL
;
; DESCRIPTIVE NAME: EDLIN ROUTINES
;
; FUNCTION: THIS MODULE PROVIDES ROUTINES NEEDED FOR EDLIN'S EXECUTION.
;
; ENTRY POINT: ANY CALLED ROUTINE
;
; EXIT NORMAL: NA
;
; EXIT ERROR : NA
;
; INTERNAL REFERENCES:
;
; EXTERNAL REFERENCES:
;
;	ROUTINE: EDLCMD1 - ROUTINES MAY BE CALLED FROM EDLCMD1
;		 EDLMES  - ROUTINES MAY BE CALLED FROM EDLMES
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK EDLIN+EDLCMD1+EDLCMD2+EDLMES+EDLPARSE
;
;
; REVISION HISTORY:
;
;	AN000	VERSION DOS 4.00 - REVISIONS MADE RELATE TO THE FOLLOWING:
;
;				    - IMPLEMENT SYSPARSE
;				    - IMPLEMENT MESSAGE RETRIEVER
;				    - IMPLEMENT DBCS ENABLING
;				    - ENHANCED VIDEO SUPPORT
;				    - EXTENDED OPENS
;				    - SCROLLING ERROR
;
; COPYRIGHT: "MS DOS EDLIN UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988 Microsoft"
;
;======================= END OF SPECIFICATIONS ===========================

include edlequ.asm

CODE	SEGMENT PUBLIC
CODE	ENDS

CONST	SEGMENT PUBLIC WORD
CONST	ENDS

cstack	segment stack
cstack	ends

DATA	SEGMENT PUBLIC WORD
DATA	ENDS


DG	GROUP	CODE,CONST,cstack,DATA

CONST	SEGMENT PUBLIC WORD
	extrn	crlf_ptr:byte,lf_ptr:byte,qmes_ptr:byte,ask_ptr:byte
	extrn	bak:byte,$$$file:byte,delflg:byte,loadmod:byte,txt1:byte
	extrn	txt2:byte,memful_ptr:word,YES_BYTE:BYTE

	extrn	Del_Bak_Ptr:byte		;an000;dms;
	extrn	cont_ptr:byte			;an000;dms:6/10/87

CONST	ENDS

DATA	SEGMENT PUBLIC WORD
	extrn	ParamCt:WORD
	extrn	current:word,pointer:word,start:word,endtxt:word
	extrn	wrt_handle:word,editbuf:byte,ext_ptr:word,qflg:byte
	extrn	temp_path:byte,line_num:word,line_flag:byte
	extrn	line_num_buf_ptr:byte,arg_buf:byte,arg_buf_ptr:word
	extrn	olddat:byte,oldlen:word,newlen:word,param1:word,param2:word
	extrn	srchflg:byte,srchmod:byte,comline:word,lstfnd:word,numpos:word
	extrn	lstnum:word,last:word,srchcnt:word,amnt_req:word

	extrn	lc_adj:byte			;an000;dms:6/10/87
	extrn	continue:byte			;an000;dms:6/10/87
	extrn	pg_count:byte			;an000;dms:6/10/87
	extrn	Disp_Len:byte			;an000;dms;
	extrn	Disp_Width:byte 		;an000;dms;
	extrn	lc_flag:byte			;an000;dms:6/10/87

	if	kanji
	extrn	lbtbl:dword
	endif

DATA	ENDS

CODE SEGMENT PUBLIC

ASSUME	CS:DG,DS:DG,SS:CStack,ES:DG

	public	findlin,shownum,loadbuf,crlf,lf,abortcom,unquote
	public	kill_bl,make_caps,display,dispone,make_cntrl
	public	query,quit,scanln,delbak,scaneof,memerr
	public	fndfirst,fndnext,replace
	if	kanji
	public	testkanj
	endif
	extrn	std_printf:near,command:near,chkrange:near,ComErr:NEAR
	extrn	Xerror:near


FINDLIN:

; Inputs
;	BX = Line number to be located in buffer (0 means last line+1)
; Outputs:
;	DX = Actual line found
;	DI = Pointer to start of line DX
;	Zero set if BX = DX (if specified line found)
; AL,CX destroyed. No other registers affected.

	MOV	DX,[CURRENT]
	MOV	DI,[POINTER]
	CMP	BX,DX			; fast find.  Current = requested
	retz
	JA	FINDIT			; start scanning at current?
	OR	BX,BX			; special case of EOF?
	JZ	FINDIT			; yes
	MOV	DX,1			; set up for scan at beginning
	MOV	DI,OFFSET DG:START
	CMP	BX,DX			; at beginning?
	retz
FINDIT:
	MOV	CX,[ENDTXT]		; count of bytes in buffer
	SUB	CX,DI			; for scan
SCANLN:
	MOV	AL,10			; LF is what we look for.
	OR	AL,AL			; Clear zero flag for JCXZ
FINLIN:
	JCXZ	RET4			; at end? Yes, no skip.
	REPNE	SCASB			; find EOL
	INC	DX			; increment count
	CMP	BX,DX			; find correct line?
	JNZ	FINLIN			; no, try again.
RET4:	return

; Inputs:
;	BX = Line number to be displayed
; Function:
;	Displays line number on terminal in 8-character
;	format, suppressing leading zeros.
; AX, CX, DX destroyed. No other registers affected.

SHOWNUM:
	mov	dx,offset dg:line_num_buf_ptr
	mov	line_num,bx
	MOV	line_flag,"*"
	CMP	BX,[CURRENT]
	JZ	STARLIN
	MOV	line_flag," "
STARLIN:
	call	std_printf
ret5:	return


DISPONE:
	MOV	DI,1

DISPLAY:

; Inputs:
;	BX = Line number
;	SI = Pointer to text buffer
;	DI = No. of lines
; Function:
;	Ouputs specified no. of line to terminal, each
;	with leading line number.
; Outputs:
;	BX = Last line output.
; All registers destroyed.

	MOV	CX,[ENDTXT]
	SUB	CX,SI
	retz				; no lines to display
;=========================================================================
; Initialize screen size and line counts for use by display.
;
;	Date	   : 6/10/87
;=========================================================================

	push	ax				;an000;save affected regs

	mov	al,dg:disp_len			;an000;length of video display
	mov	pg_count,al			;an000;init. screen size ctr.

	pop	ax				;an000;restore affected regs

;=========================================================================

	mov	dx,di				;number of lines to print
;
; CX is the number of bytes in the buffer
; dx is the number of lines to be output
;
DISPLN:
	SaveReg <CX,DX>
	CALL	SHOWNUM
	RestoreReg  <DX,CX>
	mov	di,offset dg:arg_buf
;
; Copy chars until CR/LF or end of line hit
;
OUTLN:
	LODSB
	CMP	DI,254+offset dg:arg_buf ; are we at end of buffer?
	JAE	StoreDone		; Yes, do NOT store
	CMP	AL," "
	JAE	SEND
	CMP	AL,10
	JZ	SEND
	CMP	AL,13
	JZ	SEND
	CMP	AL,9
	JZ	SEND
	MOV	AH,"^"
	OR	AL,40h
	XCHG	AL,AH
	STOSW
	JMP	StoreDone
SEND:
	stosb
StoreDone:
	CMP	AL,10			; perform copy until LF is seen
	LOOPNZ	OUTLN
;
; Make sure buffer ends with CRLF
;
	cmp	byte ptr [di-1],10
	jz	Terminate
;
; No LF seen.  See if CR
;
	cmp	byte ptr [di-1],CR
	jz	StoreLF
	mov	al,CR
	stosb
StoreLF:
	mov	al,10
	stosb
Terminate:
	mov	byte ptr [di],0

	call	EDLIN_DISP_COUNT		;an000;determine lines printed
						;      DMS:6/10/87
	push	dx
	mov	dx,offset dg:arg_buf_ptr
	call	std_printf
	pop	dx
	JCXZ	ret7
	INC	BX

	call	EDLIN_PG_COUNT			;an000;adjust screen line count
						;      DMS:6/10/87
	cmp	lc_flag,false			;an000;continue DISPLAY?
						;      DMS:6/10/87
	JNZ	DISPLN
	DEC	BX
ret7:	return

FNDFIRST:
	MOV	DI,1+OFFSET DG:TXT1
	mov	byte ptr[olddat],1     ;replace with old value if none new
	CALL	GETTEXT
	OR	AL,AL		;Reset zero flag in case CX is zero
	JCXZ	RET7
	cmp	al,1ah		;terminated with a ^Z ?
	jne	sj8
	mov	byte ptr[olddat],0     ;do not replace with old value
sj8:
	MOV	[OLDLEN],CX
	XOR	CX,CX
	CMP	AL,0DH
	JZ	SETBUF
	CMP	BYTE PTR [SRCHFLG],0
	JZ	NXTBUF
SETBUF:
	DEC	SI
NXTBUF:
	MOV	[COMLINE],SI
	MOV	DI,1+OFFSET DG:TXT2
	CALL	GETTEXT
	CMP	BYTE PTR [SRCHFLG],0
	JNZ	NOTREPL
	CMP	AL,0DH
	JNZ	HAVCHR
	DEC	SI
HAVCHR:
	MOV	[COMLINE],SI
NOTREPL:
	MOV	[NEWLEN],CX
	MOV	BX,[PARAM1]
	OR	BX,BX
	JNZ	CALLER
	cmp	byte ptr[srchmod],0
	jne	sj9
	mov	bx,1	 ;start from line number 1
	jmp	short sj9a
sj9:
	MOV	BX,[CURRENT]
	INC	BX	;Default search and replace to current+1
sj9a:
	CALL	CHKRANGE
CALLER:
	CALL	FINDLIN
	MOV	[LSTFND],DI
	MOV	[NUMPOS],DI
	MOV	[LSTNUM],DX
	MOV	BX,[PARAM2]
	CMP	BX,1
	SBB	BX,-1	;Decrement everything except zero
	CALL	FINDLIN
	MOV	CX,DI
	SUB	CX,[LSTFND]
	OR	AL,-1
	JCXZ	aret
	CMP	CX,[OLDLEN]
	jae	sj10
aret:	return
sj10:
	MOV	[SRCHCNT],CX

FNDNEXT:

; Inputs:
;	[TXT1+1] has string to search for
;	[OLDLEN] has length of the string
;	[LSTFND] has starting position of search in text buffer
;	[LSTNUM] has line number which has [LSTFND]
;	[SRCHCNT] has length to be searched
;	[NUMPOS] has beginning of line which has [LSTFND]
; Outputs:
;	Zero flag set if match found
;	[LSTFND],[LSTNUM],[SRCHCNT] updated for continuing the search
;	[NUMPOS] has beginning of line in which match was made

	MOV	AL,[TXT1+1]
	MOV	CX,[SRCHCNT]
	MOV	DI,[LSTFND]
SCAN:
	OR	DI,DI		;Clear zero flag in case CX=0
	REPNE	SCASB		;look for first byte of string

	retnz			;return if you don't find
if	kanji
	call	kanji_check	;see if the found byte is on a character boundary
	jnz	scan
endif
	MOV	DX,CX
	MOV	BX,DI		;Save search position
	MOV	CX,[OLDLEN]
	DEC	CX
	MOV	SI,2 + OFFSET DG:TXT1
	CMP	AL,AL		;Set zero flag in case CX=0
	REPE	CMPSB
	MOV	CX,DX
	MOV	DI,BX
	JNZ	SCAN
	MOV	[SRCHCNT],CX
	MOV	CX,DI
	MOV	[LSTFND],DI
	MOV	DI,[NUMPOS]
	SUB	CX,DI
	MOV	AL,10
	MOV	DX,[LSTNUM]
;Determine line number of match
GETLIN:
	INC	DX
	MOV	BX,DI
	REPNE	SCASB
	JZ	GETLIN
	DEC	DX
	MOV	[LSTNUM],DX
	MOV	[NUMPOS],BX
	XOR	AL,AL
	return

if	kanji

;Kanji_check		idea is to scan backwards to the first
;			character which can't be a kanji or part of one
;			(.lt. 40h) then scan forward to see if the
;			current byte is on character boundary
;
;Output 	ZR <==> we're on a character boundary
;		NZ <==> we're not on character boundary i.e. No Match
kanji_check:
	push	ax			;save search character
	push	di
	dec	di			;point to the character we found
	mov	si,di			;start searching bakwards from there
	std
srch_loop:
	lodsb
	cmp	al,40H
	jae	srch_loop
	inc	si			;point to first non-kanji
	cld				;forward search
kan_loop:
	cmp	si,di			;are we at current byte?
	jae	passed_char		;if we are, or are passed it, exit
	call	next_char		;otherwise advance si to next char
	jmp	short kan_loop		;and loop
passed_char:
	pop	di
	pop	ax
	ret

;Next_char		si points to a character boundary
;			advance si to point to the beginning of the next char
;
;
next_char:
	push	ax
	lodsb
	call	testkanj
	jz	not_kanj
	inc	si
not_kanj:
	pop	ax
	ret

;--------------------------------------------------------------------;
; TESTKANJ ~ FIND OUT IS THE BYTE IS A KANJI PREFIX		     ;
;								     ;
; entry:  AL	byte to test					     ;
;								     ;
; exit:   NZ if lead byte ortherwise  ZR			     ;
;								     ;
; modifies:	AX						     ;
;								     ;
;--------------------------------------------------------------------;

testkanj:
	push	ax
	xchg	ah,al		    ;put byte in ah
	push	ds
	push	si
	lds	si,cs:[lbtbl]	       ;get pointer to lead byte table
ktlop:
	lodsb			    ;direction flag should be OK
	or	al,al		    ;are we at the end of table?
	jz	notlead 	    ;brif so
	cmp	al,ah		    ;is START RANGE > CHARACTER?
	ja	notlead 	    ;brif so, not a lead character (carry clear)
	lodsb			    ;get second range byte
	cmp	ah,al		    ;is CHARACTER > END RANGE
	ja	ktlop		    ;brif so, not a lead character (check next range)
	or	al,al		    ;make NZ
notl_exit:
	pop	si
	pop	ds
	pop	ax
	ret
notlead:
	cmp	al,al
	jmp	notl_exit

endif

GETTEXT:

; Inputs:
;	SI points into command line buffer
;	DI points to result buffer
; Function:
;	Moves [SI] to [DI] until ctrl-Z (1AH) or
;	RETURN (0DH) is found. Termination char not moved.
; Outputs:
;	AL = Termination character
;	CX = No of characters moved.
;	SI points one past termination character
;	DI points to next free location

	XOR	CX,CX

GETIT:
	LODSB
;-----------------------------------------------------------------------
	cmp	al,quote_char	;a quote character?
	jne	sj101		;no, skip....
	lodsb			;yes, get quoted character
	call	make_cntrl
	jmp	short sj102
;-----------------------------------------------------------------------
sj101:
	CMP	AL,1AH
	JZ	DEFCHK
sj102:
	CMP	AL,0DH
	JZ	DEFCHK
	STOSB
	INC	CX
	JMP	SHORT GETIT

DEFCHK:
	OR	CX,CX
	JZ	OLDTXT
	PUSH	DI
	SUB	DI,CX
	MOV	BYTE PTR [DI-1],cl
	POP	DI
	return

OLDTXT:
	cmp	byte ptr[olddat],1	;replace with old text?
	je	sj11			;yes...
	mov	byte ptr[di-1],cl	;zero text buffer char count
	return

sj11:
	MOV	CL,BYTE PTR [DI-1]
	ADD	DI,CX
	return

REPLACE:

; Inputs:
;	CX = Length of new text
;	DX = Length of original text
;	SI = Pointer to new text
;	DI = Pointer to old text in buffer
; Function:
;	New text replaces old text in buffer and buffer
;	size is adjusted. CX or DX may be zero.
; CX, SI, DI all destroyed. No other registers affected.

	CMP	CX,DX
	JZ	COPYIN
	PUSH	SI
	PUSH	DI
	PUSH	CX
	MOV	SI,DI
	ADD	SI,DX
	ADD	DI,CX
	MOV	AX,[ENDTXT]
	SUB	AX,DX
	ADD	AX,CX
	CMP	AX,[LAST]
	JAE	MEMERR
	XCHG	AX,[ENDTXT]
	MOV	CX,AX
	SUB	CX,SI
	CMP	SI,DI
	JA	DOMOV
	ADD	SI,CX
	ADD	DI,CX
	STD
DOMOV:
	INC	CX

	REP	MOVSB
	CLD
	POP	CX
	POP	DI
	POP	SI
COPYIN:
	REP	MOVSB
	return

MEMERR:
	MOV	DX,OFFSET DG:MEMFUL_ptr
	call	std_printf
	JMP	COMMAND


LOADBUF:
	MOV	DI,2 + OFFSET DG:EDITBUF
	MOV	CX,255
	MOV	DX,-1
LOADLP:
	LODSB
	STOSB
	INC	DX
	CMP	AL,13
	LOOPNZ	LOADLP
	MOV	[EDITBUF+1],DL
	retz
TRUNCLP:
	LODSB
	INC	DX
	CMP	AL,13
	JNZ	TRUNCLP
	DEC	DI
	STOSB
	return

SCANEOF:
	cmp	[loadmod],0
	je	sj52

;----- Load till physical end of file

	cmp	cx,word ptr[amnt_req]
	jb	sj51
	xor	al,al
	inc	al		;reset zero flag
	return
sj51:
	jcxz	sj51b
	push	di		;get rid of any ^Z at the end of the file
	add	di,cx
	dec	di		;points to last char
	cmp	byte ptr [di],1ah
	pop	di
	jne	sj51b
	dec	cx
sj51b:
	xor	al,al		;set zero flag
	call	check_end	;check that we have a CRLF pair at the end
	return

;----- Load till first ^Z is found

sj52:
	PUSH	DI
	PUSH	CX
	MOV	AL,1AH
	or	cx,cx
	jz	not_found	;skip with zero flag set
	REPNE	SCASB		;Scan for end of file mark
	jnz	not_found
	LAHF				;Save flags momentarily
	inc	cx			;include the ^Z
	SAHF				;Restore flags
not_found:
	mov	di,cx			;not found at the end
	POP	CX
	LAHF				;Save flags momentarily
	SUB	CX,DI			;Reduce byte count if EOF found
	SAHF				;Restore flags
	POP	DI
	call	check_end		;check that we have a CRLF pair at the end

	return


;-----------------------------------------------------------------------
;	If the end of file was found, then check that the last character
; in the file is a LF. If not put a CRLF pair in.

check_end:
	jnz	not_end 		;end was not reached
	pushf				;save return flag
	push	di			;save pointer to buffer
	add	di,cx			;points to one past end on text
	dec	di			;points to last character
	cmp	di,offset dg:start
	je	check_no
	cmp	byte ptr[di],0ah	;is a LF the last character?
	je	check_done		;yes, exit
check_no:
	mov	byte ptr[di+1],0dh	;no, put a CR
	inc	cx			;one more char in text
	mov	byte ptr[di+2],0ah	;put a LF
	inc	cx			;another character at the end
check_done:
	pop	di
	popf
not_end:
	return

CRLF:
	push	dx
	mov	dx,offset dg:crlf_ptr
	call	std_printf
	pop	dx
	return
LF:
	MOV	dx,offset dg:lf_ptr
	call	std_printf
	return

ABORTCOM:
	MOV	AX,CS
	MOV	DS,AX
	MOV	ES,AX
	MOV	AX,cstack
	MOV	SS,AX
	MOV	SP,STACK
	STI
	CALL	CRLF
	JMP	COMMAND

DELBAK:
	;Delete old backup file (.BAK)

	MOV	BYTE PTR [DELFLG],1
	MOV	DI,[EXT_PTR]
	MOV	SI,OFFSET DG:BAK
	MOVSW
	MOVSW
	MOVSB
	MOV	AH,UNLINK
	MOV	DX,OFFSET DG:TEMP_PATH
	INT	21H
;	$if	c					;error ?		;an000; dms;
	JNC $$IF1
		cmp	ax,Access_Denied		;file read only?	;an000; dms;
;		$if	e				;yes			;an000; dms;
		JNE $$IF2
			mov	bx,[Wrt_Handle] 	;close .$$$ file	;an000; dms;
			mov	ah,Close		;close function 	;an000; dms;
			int	21h			;close it		;an000; dms;

			mov	di,[Ext_Ptr]		;point to extension	;an000; dms;
			mov	si,offset dg:$$$File	;point to .$$$ extension;an000; dms;
			movsw				;get .$$$ extension	;an000; dms;
			movsw				;			;an000; dms;
			movsb				;			;an000; dms;
			mov	dx,offset dg:Temp_Path	;point to .$$$ file	;an000; dms;
			mov	ah,Unlink		;delete it		;an000; dms;
			int	21h			;			;an000; dms;

			mov	di,[Ext_Ptr]		;point to extension	;an000; dms;
			mov	si,offset dg:BAK	;point to .BAK extension;an000; dms;
			movsw				;get .BAK extension	;an000; dms;
			movsw				;			;an000; dms;
			movsb				;			;an000; dms;
			mov	dx,offset dg:Del_Bak_Ptr;point to error message ;an000; dms;
			jmp	Xerror			;display message & exit ;an000; dms;
;		$endif
$$IF2:
;	$endif
$$IF1:

	MOV	DI,[EXT_PTR]
	MOV	SI,OFFSET DG:$$$FILE
	MOVSW
	MOVSW
	MOVSB
	return


;-----------------------------------------------------------------------;
; Will scan buffer given pointed to by SI and get rid of quote
;characters, compressing the line and adjusting the length at the
;begining of the line.
; Preserves al registers except flags and AX .

unquote:
	push	cx
	push	di
	push	si
	mov	di,si
	mov	cl,[si-1]	;length of buffer
	xor	ch,ch
	mov	al,quote_char
	cld
unq_loop:
	jcxz	unq_done	;no more chars in the buffer, exit
	repnz	scasb		;search for quote character
	jnz	unq_done	;none found, exit
	push	cx		;save chars left in buffer
	push	di		;save pointer to quoted character
	push	ax		;save quote character
	mov	al,byte ptr[di] ;get quoted character
	call	make_cntrl
	mov	byte ptr[di],al
	pop	ax		;restore quote character
	mov	si,di
	dec	di		;points to the quote character
	inc	cx		;include the carriage return also
	rep	movsb		;compact line
	pop	di		;now points to after quoted character
	pop	cx
	jcxz	sj13		;if quote char was last of line do not adjust
	dec	cx		;one less char left in the buffer
sj13:	pop	si
	dec	byte ptr[si-1]	;one less character in total buffer count also
	push	si
	jmp	short unq_loop

unq_done:
	pop	si
	pop	di
	pop	cx
	return


;-----------------------------------------------------------------------;
;	Convert the character in AL to the corresponding control
; character. AL has to be between @ and _ to be converted. That is,
; it has to be a capital letter. All other letters are left unchanged.

make_cntrl:
	push	ax
	and	ax,11100000b
	cmp	ax,01000000b
	pop	ax
	jne	sj14
	and	ax,00011111b
sj14:
	return


;---- Kill spaces in buffer --------------------------------------------;
;=========================================================================
; kill_bl : Parses over spaces in a buffer.
;
;	Date	   : 6/10/86
;=========================================================================
kill_bl:

	push	bx			;an000;save affected reg.
kill_bl_cont:

	lodsb				;get rid of blanks
	    cmp al,9
	    je	kill_bl_cont		;an000;it is a tab

	    cmp al,10
	    je	kill_bl_cont		;an000;if LF

	    cmp al,' '
	    je	kill_bl_cont		;an000;we have a space

	if kanji			;an000;is this a kanji assembly
	     call testkanj		;an000;do we have a dbcs lead byte
;	     $if  nz			;an000;yes, we have a lead byte
	     JZ $$IF5
		  cmp  al,dbcs_lead_byte;an000;is it 81h
;		  $if  z		;an000;it is 81h
		  JNZ $$IF6
		       mov  bl,ds:[si]	;an000;set up for compare
		       cmp  bl,asian_blk;an000;is it 40h
;		       $if  z		;an000;we have an asian blank
		       JNZ $$IF7
			    lodsb	;an000;skip byte containing 81h
			    jmp kill_bl_cont
;		       $endif		;an000;
$$IF7:
;		  $endif		;an000;fall through no delim
$$IF6:
					;      found
;	     $endif			;an000;end test for dbcs lead byte
$$IF5:
	endif				;an000;end conditional assembly

	pop	bx			;an000;restore affected reg.
	return

;----- Capitalize the character in AL ----------------------------------;
;									;
;   Input:								;
;									;
;	    AL	    contains a character to capitalize			;
;									;
;   Output:								;
;									;
;	    AL	    contains a capitalized character			;
;									;
;-----------------------------------------------------------------------;

MAKE_CAPS:
	CMP	AL,"a"
	JB	CAPS1
	CMP	AL,"z"
if KANJI
	JA	CAPS1		; M003 MSKK TAR 476, kana chars
else
	JG	CAPS1
endif
	AND	AL,0DFH
CAPS1:
	return

QUIT:
	CMP	ParamCt,1
	JZ	Quit1
CERR:	JMP	ComErr
Quit1:	CMP	Param1,0
	JNZ	CERR
	MOV	DX,OFFSET DG:QMES_ptr
	call	std_printf

IF	KANJI
	CALL	TESTKANJ
	JZ	ASCII
	MOV	AX, (STD_CON_INPUT_FLUSH SHL 8) + 0
	INT	21H		; Eat the trailing byte.
	JMP	CRLF
ASCII:
ENDIF
;=========================================================================
; We are invoking the VAL_YN proc here.  This will replace the
; method of Y/N validation used prior to DOS 4.00.
;
;	Date	   : 6/10/87
;=========================================================================

	call	val_yn		;an000;pass Y/N byte in AL to macro
	cmp	ax,yes		;an000;did we return a Y
	jz	NoCRLF		;an000; dms; close the file
	cmp	ax,no		;an000; dms; return N?
;	$if	ne		;an000; dms; neither N or Y - reprompt
	JE $$IF11
		push	dx			;an000; dms; must be N
		mov	dx,offset dg:crlf_ptr	;an000; dms; spit out CRLF
		call	std_printf		;an000; dms;   and return
		pop	dx			;an000; dms;   to caller
		jmp	Quit1			;an000; dms; reprompt
;	$endif			;an000; dms;
$$IF11:
	push	dx		;an000; dms; must be N
	mov	dx,offset dg:crlf_ptr	;an000; dms; spit out CRLF
	call	std_printf		;an000; dms;   and return
	pop	dx			;an000; dms;   to caller
	return				;an000; dms;

;=========================================================================
; End of Y/N validation check for qmes_ptr
;=========================================================================

NOCRLF:
	MOV	BX,[WRT_HANDLE]
	MOV	AH,CLOSE
	INT	21H
	MOV	DX,OFFSET DG:TEMP_PATH
	MOV	AH,UNLINK
	INT	21H
	mov	ah,exit
	xor	al,al
	INT	21H

QUERY:
	TEST	BYTE PTR [QFLG],-1
	retz
	MOV	DX,OFFSET DG:ASK_ptr
	call	std_printf
	PUSH	AX
	CALL	CRLF
	POP	AX
IF	KANJI
	CALL	TESTKANJ
	JZ	ASCII1
	PUSH	AX
	MOV	AX,(STD_CON_INPUT_FLUSH SHL 8) + 0
	INT	21H		;Eat the trailing byte
	XOR	AX,AX
	INC	AX		; non zero flag
	POP	AX
	return
ASCII1:
ENDIF
	CMP	AL,13		;Carriage return means yes
	retz
;=========================================================================
; We are invoking the VAL_YN proc here.  This will replace the
; method of Y/N validation used prior to DOS 4.00.
; This invocation of val_yn will return ZR if Y is found, otherwise
; it will return NZ.
;
;	Date	   : 6/10/87
;=========================================================================

	call	val_yn		;an000;pass Y/N byte in AL to macro
	cmp	ax,yes		;an000;did we return a Y
	je	Query_Exit	;an000; dms; exit Y/N validation
	cmp	ax,no		;an000; dms; N response?
	jne	Query		;an000; dms; no - reprompt user
	cmp	ax,yes		;an000; dms; must have N response - force
				;	     NZ flag
Query_Exit:


;=========================================================================
; End of Y/N validation check for ask_ptr
;=========================================================================

	return

;=========================================================================
; EDLIN_DISP_COUNT: This routine will determine the number of lines
;		    actually displayed to the screen.  Lines displayed to
;		    the screen for one EDLIN line printed will be calculated
;		    by the following formula:
;
;		LINES_PRINTED = (LINE_LEN + 10) / SCREEN_WIDTH
;
;		LINES_PRINTED - Actual number of lines printed on screen
;				for one EDLIN line.  If LINES_PRINTED has
;				a remainder, it will be rounded up.
;
;		LINE_LEN      - The length, in bytes, of the EDLIN line
;				printed.
;
;		SCREEN_WIDTH  - The width in bytes of the current display.
;
;	Inputs : DI - offset into buffer containing line printed
;		 DISP_WIDTH  - width of current video output
;
;	Outputs: LC_ADJ - factor to adjust line counter by
;
;	Date	   : 6/10/87
;=========================================================================

EDLIN_DISP_COUNT	proc	near		;an000;lines printed

	push	dx				;an000;save affected regs
	push	di				;an000;
	push	ax				;an000;
	push	bx				;an000;
	push	cx				;an000;

	mov	bx,offset dg:arg_buf		;an000;arg_buf holds line
						;      printed
	mov	ax,di				;an000;where print line ends
	sub	ax,bx				;an000;diff = line's length
	add	ax,10				;an000;adjust for leading blks
	mov	cl,dg:disp_width		;an000;set up for division
	div	cl				;an000;divide AX by the
						;      width of the console
	cmp	ah,0				;an000;see if a remainder
;	$if	nz				;an000;if a remainder
	JZ $$IF13
		add al,1			;an000;increment AL 1
						;      to round upward
;	$endif					;an000;
$$IF13:

	mov	lc_adj,al			;an000;number of lines printed
						;      on console
	pop	cx				;an000;restore affected regs
	pop	bx				;an000;
	pop	ax				;an000;
	pop	di				;an000;
	pop	dx				;an000;

	ret					;an000;return to caller

EDLIN_DISP_COUNT	endp			;an000;end proc

;=========================================================================
; EDLIN_PG_COUNT : This routine determines whether or not we will continue
;		   displaying text lines based on the count of lines that
;		   can be output to the current video screen.
;
;	Inputs : LC_ADJ    - adjustment factor for number of lines printed
;		 PG_COUNT  - number of lines remaining on current video
;			     display
;		 DX	   - holds the total number of lines to print
;		 CONTINUE  - signals if the user wants to continue
;			     printing lines.
;
;	Outputs: LC_FLAG   - used to signal completion of print
;
;	Date	   : 6/10/87
;=========================================================================

EDLIN_PG_COUNT		proc	near		;an000;track remaining lines

	push	ax				;an000;save affected regs

	mov	lc_flag,true			;an000;init. flag to signal
						;      continue printing

	mov	al,pg_count			;an000;set up for page adj.
	cmp	al,lc_adj			;an000;see if we are at end
;	$if	be				;an000
	JNBE $$IF15
		mov	pg_count,0		;an000;set pg_count to 0
;	$else
	JMP SHORT $$EN15
$$IF15:
		sub	al,lc_adj		;an000;adjust number of lines
		mov	pg_count,al		;an000;save remaining line ct.
;	$endif					;an000;
$$EN15:

	dec	dx				;an000;decrease total number
						;      of lines to print by 1
;	$if	nz				;an000;more lines to print
	JZ $$IF18
	    cmp    pg_count,0			;an000;have we printed screen
;	    $if    be				;an000;we have printed screen
	    JNBE $$IF19
		   call    EDLIN_PG_PROMPT	;an000;prompt the user to
						;      "Continue(Y/N)?"
		   cmp	  continue,true 	;an000;did user say continue
;		   $if	  z			;an000;continue
		   JNZ $$IF20
			  mov	al,dg:disp_len	;an000;begin init of screen
;			  dec	al		;an000;    length
			  mov	pg_count,al	;an000;
;		   $else			;an000;do not continue
		   JMP SHORT $$EN20
$$IF20:
			  mov	lc_flag,false	;an000;signal no more to print
;		   $endif			;an000;
$$EN20:
;	    $endif				;an000;
$$IF19:
;	$else					;an000;total lines printed
	JMP SHORT $$EN18
$$IF18:
	    mov    lc_flag,false		;an000;signal no more to print
;	$endif					;an000;
$$EN18:

	pop	ax				;an000;restore affected regs

	ret					;an000;return to caller

EDLIN_PG_COUNT		endp			;an000;end procedure

;=========================================================================
; EDLIN_PG_PROMPT : This routine prompts the user as to whether or not to
;		    continue printing lines to the video display, if lines
;		    are still present for printing.
;
;	Inputs : none
;
;	Outputs: CONTINUE - flag that signals other routines whether or
;			    not to continue printing.
;
;	Date	   : 6/10/87
;=========================================================================

EDLIN_PG_PROMPT 	proc	near		;an000;ask user to continue?

	push	dx				;an000;save affected regs.
	push	ax				;an000;

EPP_Reprompt:

	mov	dx,offset dg:cont_ptr		;an000;point to Continue msg.
	call	std_printf			;an000;invoke message ret.

	push	ax				;an000;save affected regs.
	call	crlf				;an000;send crlf
	pop	ax				;an000;restore affected regs.

	call	val_yn				;an000;Y/N validation

	cmp	ax,yes				;an000;did we have a Y
	jz	EPP_True_Exit			;an000;we had a Y
	cmp	ax,no				;an000;did we have a N
	jz	EPP_False_Exit			;an000;yes
	jmp	EPP_Reprompt			;an000;neither Y or N - reprompt

EPP_True_Exit:

	mov	Continue,True			;an000;flag Y found
	jmp	EPP_Exit			;an000;exit routine

EPP_False_Exit:

	mov	Continue,False			;an000;flag N found

EPP_Exit:

	pop	ax				;an000;restore affected regs.
	pop	dx				;an000;

	ret					;an000;return to caller

EDLIN_PG_PROMPT 	endp			;an000;end procedure

;=========================================================================
; val_yn: This proc validates a Y/N response entered by the user.  The
;	  routine uses the new functionality of "GET EXTENDED COUNTRY
;	  INFORMATION" being implemented in DOS 4.00.
;
; Inputs : AL - character to be validated for Y/N response
;
; Outputs: AX - 00h = "N"o
;	      - 01h = "Y"es
;=========================================================================

val_yn	proc	near		;an000;validate Y/N response

	push	dx		;an000;save affected registers
	push	cx		;an000;
	push	bx		;an000;

	mov	dl,al		;an000;character to be checked for Y/N
	mov	ah,GetExtCntry	;an000;get extended country information
	mov	al,yn_chk	;an000;perform Y/N checking
	mov	cx,max_len	;an000;max. len. of Y/N char.
	int	21h		;an000;invoke function

	pop	bx		;an000;restore affected registers
	pop	cx		;an000;
	pop	dx		;an000;

	ret			;an000;return to caller

val_yn	endp			;an000;end proc



code	ends
	end
