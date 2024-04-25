 page 80,132
;	SCCSID = @(#)tucode.asm 4.2 85/05/31
;	SCCSID = @(#)tucode.asm 4.2 85/05/31
Title	COMMAND Language midifiable Code Transient


.xlist
.xcref
	INCLUDE dossym.inc
	INCLUDE comsw.asm
	INCLUDE comseg.asm
	INCLUDE comequ.asm
.list
.cref


DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	ECHOFLAG:BYTE
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BAD_ON_OFF_ptr:word
	EXTRN	ctrlcmes_ptr:word
	EXTRN	DEL_Y_N_PTR:WORD
	EXTRN	ECHOMES_ptr:word
	EXTRN	extend_buf_ptr:word	;AC000;
	EXTRN	offmes_ptr:word
	EXTRN	onmes_ptr:word
	EXTRN	PARSE_BREAK:BYTE	;AN000;
	EXTRN	promptdat_moday:word	;AC000;
	EXTRN	promptdat_ptr:word	;AC000;
	EXTRN	promptdat_yr:word	;AC000;
	EXTRN	string_buf_ptr:word
	EXTRN	SUREMES_ptr:word
	EXTRN	VERIMES_ptr:BYTE
	EXTRN	WeekTab:word
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg_buf:byte
	EXTRN	BWDBUF:BYTE
	EXTRN	DEST:BYTE
	EXTRN	destdir:byte
	EXTRN	dirchar:byte
	EXTRN	PARSE1_CODE:BYTE	;AN000;
	EXTRN	RESSEG:WORD
	EXTRN	string_ptr_2:word

TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

	EXTRN	CERROR:NEAR
	EXTRN	CRLF2:NEAR
	EXTRN	extend_setup:near	;AN022;

	PUBLIC	CNTRLC
	PUBLIC	ECHO
	PUBLIC	GetDate
	PUBLIC	NOTEST2
	PUBLIC	PRINT_DATE
	PUBLIC	SLASHP_ERASE		;AN000;
	PUBLIC	VERIFY

ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING

; ****************************************************************
; *
; * ROUTINE:	 NOTEST2 - execution of DEL/ERASE command
; *
; * FUNCTION:	 Delete files based on user parsed input.  Prompt
; *		 user for Y/N if necessary.  If an error occurs,
; *		 set up an error message and go to CERROR.
; *
; * INPUT:	 FCB at 5ch set up with filename(s) entered
; *		 Current directory set to entered directory
; *
; * OUTPUT:	 none
; *
; ****************************************************************
;
; ARE YOU SURE prompt when deleting *.*

NOTEST2:
	MOV	CX,11
	MOV	SI,FCB+1

AMBSPEC:
	LODSB
	CMP	AL,'?'
	JNZ	ALLFIL
	LOOP	AMBSPEC

ALLFIL:
	CMP	CX,0
	JNZ	NOPRMPT

ASKAGN:
	MOV	DX,OFFSET TRANGROUP:SUREMES_ptr ; "Are you sure (Y/N)?"
	invoke	std_printf
	MOV	SI,80H
	MOV	DX,SI
	MOV	WORD PTR [SI],120		; zero length
	MOV	AX,(STD_CON_INPUT_FLUSH SHL 8) OR STD_CON_STRING_INPUT
	INT	21H
	LODSW
	OR	AH,AH
	JZ	ASKAGN
	INVOKE	SCANOFF
	call	char_in_xlat			;G Convert to upper case
	retc					;AN000; return if function not supported
	CMP	AL,CAPITAL_N			;G
	retz
	CMP	AL,CAPITAL_Y			;G
	PUSHF
	CALL	CRLF2
	POPF
	JNZ	ASKAGN

NOPRMPT:
	MOV	AH,FCB_DELETE
	MOV	DX,FCB
	INT	21H
	INC	AL
	jz	eraerr
	invoke	RESTUDIR
	ret					; If no error, return

eraerr:
	invoke	set_ext_error_msg		;AN022; set up the extended error
	push	dx				;AN022; save message
	invoke	RESTUDIR
	pop	dx				;AN022; restore message

	cmp	word ptr extend_buf_ptr,error_no_more_files ;AN022; convert no more files to
	jnz	cerrorj2			;AN022; 	file not found
	mov	Extend_Buf_ptr,error_file_not_found  ;AN000; get message number in control block

cerrorj2:
	jmp	cerror


; ****************************************************************
; *
; * ROUTINE:	 SLASHP_ERASE  - execution of DEL/ERASE /P
; *
; * FUNCTION:	 Delete files based on user parsed input.  Prompt
; *		 user for Y/N where necessary.	If an error occurs
; *		 set up and error message and transfer control
; *		 to CERROR.
; *
; * INPUT:	 FCB at 5ch set up with filename(s) entered
; *		 Current directory set to entered directory
; *
; * OUTPUT:	 none
; *
; ****************************************************************

ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING

SLASHP_ERASE:					;AN000; entry point
	invoke	build_dir_string		;AN000; set up current directory string for output
	mov	ah,Set_DMA			;AN000; issue set dta int 21h
	mov	dx,offset trangroup:destdir	;AN000; use Destdir for target
	int	21H				;AN000;
	mov	ah,Dir_Search_First		;AN000; do dir search first int 21h
	mov	dx,FCB				;AN000; use FCB at 5Ch for target
	int	21H				;AN000;
	inc	al				;AN000; did an error occur
	jz	eraerr				;AN022; go to error exit

delete_prompt_loop:				;AN000;
	mov	si,offset trangroup:destdir+1	;AN000; set up FCB as source
	mov	di,offset trangroup:dest	;AN000; set up dest as target
	mov	al,dirchar			;AN000; store a "\" in the first char
	stosb					;AN000;     of DEST
	invoke	fcb_to_ascz			;AN000; convert filename from FCB to ASCIIZ string

slashp_askagn:					;AN000;
	call	crlf2				;AN000; print out carriage return, line feed
	mov	dx,offset trangroup:bwdbuf	;AN000; print out current directory string
	mov	bx,dx				;AN000; get string pointer in bx
	cmp	byte ptr [bx+3],end_of_line_out ;AN000; see if only D:\,0
	jnz	not_del_root			;AN000; no continue
	mov	byte ptr [bx+2],end_of_line_out ;AN000; yes, get rid of \

Not_del_root:					;AN000;
	mov	string_ptr_2,dx 		;AN000;
	mov	dx,offset trangroup:string_buf_ptr ;AN000;
	invoke	std_printf			;AN000;
	mov	dx,offset trangroup:dest	;AN000; print out file name string
	mov	string_ptr_2,dx 		;AN000;
	mov	dx,offset trangroup:string_buf_ptr ;AN000;
	invoke	std_printf			;AN000;
	mov	dx,offset trangroup:Del_Y_N_Ptr ;AN000; issue ",    Delete (Y/N)?" message
	invoke	std_printf			;AN000;
	mov	si,80H				;AN000; set up buffer for input
	mov	dx,si				;AN000;
	mov	word ptr [si],combuflen 	;AN000;
	mov	ax,(std_con_input_flush shl 8) or std_con_string_input	 ;AN000;
	int	int_command			;AN000; get input from the user
	lodsw					;AN000;
	or	ah,ah				;AN000; was a character entered?
	jz	slashp_askagn			;AN000; no - ask again
	invoke	scanoff 			;AN000; scan off leading delimiters
	call	char_in_xlat			;AN000; yes - upper case it
	retc					;AN000; return if function not supported
	cmp	al,capital_n			;AN000; was it no?
	jz	next_del_file			;AN000; yes - don't delete file
	cmp	al,capital_y			;AN000; was it yes?
	jz	delete_this_file		;AN000; yes - delete the file
	jmp	short slashp_askagn		;AN000; it was neither - ask again

delete_this_file:				;AN000;
	mov	ah,fcb_delete			;AN000; delete the file
	mov	dx,offset trangroup:destdir	;AN000; use Destdir for target
	int	int_command			;AN000;
	inc	al				;AN000; did an error occur?
	jnz	next_del_file			;AN000; no - get next file
	jmp	eraerr				;AN022; go to error exit - need long jmp

next_del_file:					;AN000;
	mov	ah,dir_search_next		;AN000; search for another file
	mov	dx,FCB				;AN000;
	int	int_command			;AN000;
	inc	al				;AN000; was a file found?
	jz	slash_p_exit			;AN000; no - exit
	jmp	delete_prompt_loop		;AN000; yes - continue (need long jump)

slash_p_exit:
	invoke	get_ext_error_number		;AN022; get the extended error number
	cmp	ax,error_no_more_files		;AN022; was error file not found?
	jz	good_erase_exit 		;AN022; yes - clean exit
	jmp	extend_setup			;AN022; go issue error message

good_erase_exit:
	invoke	restudir			;AN000; we're finished - restore user's dir
	call	crlf2				;AN000; print out carriage return, line feed
	ret					;AN000; exit


;************************************************
; ECHO, BREAK, and VERIFY commands. Check for "ON" and "OFF"

	break	Echo

assume	ds:trangroup,es:trangroup

ECHO:
	CALL	ON_OFF
	JC	DOEMES
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	JNZ	ECH_OFF
	OR	[ECHOFLAG],1
	RET
ECH_OFF:
	AND	[ECHOFLAG],NOT 1
	RET


CERRORJ:
	JMP	CERROR

;
; There was no discrenable ON or OFF after the ECHO.  If there is nothing but
; delimiters on the command line, we issue the ECHO is ON/OFF message.
;

ASSUME	DS:TRANGROUP

DOEMES:
	cmp	cl,0				;AC000; was anything on the line?
	jz	PEcho				; just display current state.
	MOV	DX,82H				; Skip one char after "ECHO"
	invoke	CRPRINT
	JMP	CRLF2

PECHO:
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	BL,[ECHOFLAG]
	PUSH	CS
	POP	DS
ASSUME	DS:TRANGROUP
	AND	BL,1
	MOV	DX,OFFSET TRANGROUP:ECHOMES_ptr
	JMP	SHORT PYN

	break	Break
assume	ds:trangroup,es:trangroup

CNTRLC:
	CALL	ON_OFF
	MOV	AX,(SET_CTRL_C_TRAPPING SHL 8) OR 1
	JC	PCNTRLC
	JNZ	CNTRLC_OFF
	MOV	DL,1
	INT	21H				; Set ^C
	RET

CNTRLC_OFF:
	XOR	DL,DL
	INT	21H				; Turn off ^C check
	RET

PCNTRLC:
	CMP	CL,0				;AC000; rest of line blank?
	JNZ	CERRORJ 			; no, oops!

pccont:
	XOR	AL,AL
	INT	21H
	MOV	BL,DL
	MOV	DX,OFFSET TRANGROUP:CTRLCMES_ptr

PYN:
	mov	si,offset trangroup:onmes_ptr	;AC000; get ON pointer
	OR	BL,BL
	JNZ	PRINTVAL
	mov	si,offset trangroup:offmes_ptr	;AC000; get OFF pointer

PRINTVAL:
	push	dx				;AN000; save offset of message block
	mov	bx,dx				;AN000; save offset value
	lodsw					;AN000; get message number of on or off
	mov	dh,util_msg_class		;AN000; this is a utility message
	invoke	Tsysgetmsg			;AN000; get the address of the message
	add	bx,ptr_off_pos			;AN000; point to offset of ON/OFF
	mov	word ptr [bx],si		;AN000; put the offset in the message block
	pop	dx				;AN000; get message back
	invoke	std_printf			;AC000; go print message
	mov	word ptr [bx],0 		;AN000; zero out message pointer

	ret					;AN000; exit

	break	Verify
assume	ds:trangroup,es:trangroup

VERIFY:
	CALL	ON_OFF
	MOV	AX,(SET_VERIFY_ON_WRITE SHL 8) OR 1
	JC	PVERIFY
	JNZ	VER_OFF
	INT	21H				; Set verify
	RET

VER_OFF:
	DEC	AL
	INT	21H				; Turn off verify after write
	RET

PVERIFY:
	CMP	CL,0				;AC000; is rest of line blank?
	JNZ	CERRORJ 			; nope...
	MOV	AH,GET_VERIFY_ON_WRITE
	INT	21H
	MOV	BL,AL
	MOV	DX,OFFSET TRANGROUP:VERIMES_ptr
	JMP	PYN

; ****************************************************************
; *
; * ROUTINE:	 ON_OFF
; *
; * FUNCTION:	 Parse the command line for an optional ON or
; *		 OFF string for the BREAK, VERIFY, and ECHO
; *		 routines.
; *
; * INPUT:	 command line at offset 81H
; *		 PARSE_BREAK control block
; *
; * OUTPUT:	 If carry is clear
; *		    If ON is found
; *		       Zero flag set
; *		    If OFF is found
; *		       Zero flag clear
; *		 If carry set
; *		    If nothing on command line
; *		       CL set to zero
; *		    If error
; *		       CL contains error value from parse
; *
; ****************************************************************

assume	ds:trangroup,es:trangroup

ON_OFF:
	MOV	SI,81h

scan_on_off:					;AN032; scan off leading blanks & equal
	lodsb					;AN032; get a char
	cmp	al,blank			;AN032; if whitespace
	jz	scan_on_off			;AN032;    keep scanning
	cmp	al,tab_chr			;AN032; if tab
	jz	scan_on_off			;AN032;    keep scanning
	cmp	al,equal_chr			;AN032; if equal char
	jz	parse_on_off			;AN032;    start parsing
	dec	si				;AN032; if none of above - back up

parse_on_off:					;AN032;    and start parsing
	mov	di,offset trangroup:parse_break ;AN000; Get adderss of PARSE_BREAK
	xor	cx,cx				;AN000; clear cx,dx
	xor	dx,dx				;AN000;
	invoke	cmd_parse			;AC000; call parser
	cmp	ax,end_of_line			;AC000; are we at end of line?
	jz	BADONF				;AC000; yes, return error
	cmp	ax,result_no_error		;AN000; did an error occur
	jz	on_off_there			;AN000; no - continue
	mov	cx,ax				;AN000; yes - set cl to error code
	jmp	short BADONF			;AN000; return error

on_off_there:
	cmp	parse1_code,-1			;AN014; was a valid positional present?
	jnz	good_on_off			;AN014; yes - continue
	mov	cx,badparm_ptr			;AN014; something other than ON/OFF
	jmp	short BADONF			;AN014; return error

good_on_off:					;AN014;
	xor	ax,ax				;AC000; set up return code for
	or	al,parse1_code			;AC000;    ON or OFF in AX
	pushf					;AN000; save flags
	mov	di,offset trangroup:parse_break ;AN000; Get adderss of PARSE_BREAK
	xor	dx,dx				;AN000;
	invoke	cmd_parse			;AN000; call parser
	cmp	ax,end_of_line			;AN000; are we at end of line?
	jnz	BADONF_flags			;AN000; NO, return error
	popf					;AN000; restore flags
	clc					;AC000; no error
	jmp	short on_off_end		;AN000; return to caller

BADONF_flags:
	mov	cx,ax
	popf

;
; No discernable ON or OFF has been found. Put an error message pointer in DX
; and return the error
;
BADONF:
	MOV	DX,OFFSET TRANGROUP:BAD_ON_OFF_ptr
	STC

ON_OFF_END:

	RET



;*************************************************************************
; print date

PRINT_DATE:
	PUSH	ES
	PUSH	DI
	PUSH	CS
	POP	ES
	CALL	GetDate 			; get date
	xchg	dh,dl				;AN000; switch month & day
	mov	promptDat_yr,cx 		;AC000; put year into message control block
	mov	promptDat_moday,dx		;AC000; put month and day into message control block
	mov	dx,offset trangroup:promptDat_ptr ;AC000; set up message for output
	invoke	std_printf
;AD061; mov	promptDat_yr,0			;AC000; reset year, month and day
;AD061; mov	promptDat_moday,0		;AC000;     pointers in control block
	POP	DI				;AC000; restore di,es
	POP	ES				;AC000;
	return
;
; Do GET DATE system call and set up 3 character day of week in ARG_BUF
; for output.  Date will be returned in CX,DX.
;

GetDate:
	mov	di,offset trangroup:arg_buf	;AC000; target for day of week
	MOV	AH,GET_DATE			;AC000; get current date
	INT	int_command			;AC000; Get date in CX:DX
	CBW					;AC000;

	push	cx				;AN000; save date returned in
	push	dx				;AN000;      CX:DX
	MOV	SI,AX
	SHL	SI,1
	ADD	SI,AX				; SI=AX*3
	mov	cx,si				;AN000; save si
	mov	ax,weektab			;AN000; get message number of weektab
	mov	dh,util_msg_class		;AN000; this is a utility message
	push	di				;AN000; save argument buffer
	invoke	Tsysgetmsg			;AN000; get the address of the message
	pop	di				;AN000; retrieve argument buffer
	add	si,cx				;AC000; get day of week
	MOV	CX,3
	REP	MOVSB
	mov	al,end_of_line_out		;AC000; terminate the string
	stosb
	pop	dx				;AN000; get back date
	pop	cx				;AN000;

	return
;g
;g   This routine determines whether the character in AL is a
;g   Yes or No character.  On return, if AL=0, the character is
;g   No, if AL=1, the character is Yes.
;g

assume	ds:trangroup

char_in_xlat	proc	near

	mov	dl,al				;AC000; get character into DX
	xor	dh,dh				;AC000;
	mov	ax,(getextcntry SHL 8) + 35	;AC000; Yes/No char call
	int	int_command			;AC000;

	ret

char_in_xlat	endp

TRANCODE	ENDS
	END
