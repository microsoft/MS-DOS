 page 80,132
;	SCCSID = @(#)tcmd2b.asm 4.1 85/09/22
;	SCCSID = @(#)tcmd2b.asm 4.1 85/09/22
TITLE	PART5 COMMAND Transient routines.

.xlist
.xcref
	INCLUDE comsw.asm
	INCLUDE DOSSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm
.list
.cref


CODERES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	LODCOM1:NEAR
CODERES ENDS

DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	crit_msg_off:word	;AC000;
	EXTRN	crit_msg_seg:word	;AC000;
	EXTRN	IO_SAVE:WORD
	EXTRN	OldTerm:DWORD
	EXTRN	PARENT:WORD
;AD060; EXTRN	pars_msg_off:word	;AC000;
;AD060; EXTRN	pars_msg_seg:word	;AC000;
	EXTRN	PERMCOM:BYTE		;AN045;
	EXTRN	RetCode:WORD
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	ACRLF_PTR:WORD		;AN007;
	EXTRN	baddev_ptr:word
	EXTRN	CP_active_Ptr:word
	EXTRN	CP_not_all_Ptr:word
	EXTRN	CP_not_set_Ptr:word
	EXTRN	Extend_buf_ptr:word	;AN000;
	EXTRN	Extend_buf_sub:byte	;AN000;
	EXTRN	inv_code_page:word	;AC000;
	EXTRN	msg_disp_class:byte	;AN000;
	EXTRN	NLSFUNC_Ptr:word	;AC000;
	EXTRN	parse_chcp:byte 	;AC000;
	EXTRN	parse_chdir:byte	;AC000;
	EXTRN	parse_ctty:byte 	;AC000;
	EXTRN	string_buf_ptr:word	;AC000;

TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	COMBUF:BYTE
	EXTRN	parse_last:word 	;AN018;
	EXTRN	parse1_addr:dword	;AC000;
	EXTRN	parse1_type:byte	;AC000;
	EXTRN	RESSEG:WORD
	EXTRN	srcbuf:byte
	EXTRN	srcxname:byte		;AC000;
	EXTRN	string_ptr_2:word
	EXTRN	system_cpage:word
	EXTRN	TRAN_TPA:WORD
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;---------------

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg:byte		; the arg structure!
TRANSPACE	ENDS
;---------------

	EXTRN	cerror:near

	PUBLIC	$exit
	PUBLIC	chcp
	PUBLIC	ctty
	PUBLIC	parse_check_eol 	;AN000;
	PUBLIC	parse_with_msg		;AN018;
	PUBLIC	setup_parse_error_msg	;AN018;
	PUBLIC	truename		;AN000;

	break	Ctty
assume	ds:trangroup,es:trangroup

; ****************************************************************
; *
; * ROUTINE:	 CTTY - Change console
; *
; * SYNTAX:	 CTTY device
; *
; * FUNCTION:	 If a valid console device is specified, CTTY will
; *		 duplicate the device handle to STDIN, STDOUT and
; *		 STDERR.  This routine returns to LODCOM1.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

CTTY:
	push	ds				;AN000; Get local ES
	pop	es				;AN000;
	mov	si,81H				;AC000; Get command argument for CTTY

	mov	di,offset trangroup:parse_ctty	;AC000; Get adderss of PARSE_CTTY
	xor	cx,cx				;AC000; clear cx,dx
	xor	dx,dx				;AC000;
	invoke	cmd_parse			;AC000; call parser
	cmp	ax,end_of_line			;AN000; are we at end of line?
	jz	ctty_error			;AN000; yes - error
	cmp	ax,result_no_error		;AN000; did an error occur
	jnz	ctty_error			;AN000; YES -ERROR

	push	si				;AN000; save position in line
	lds	si,parse1_addr			;AN000; get address of filespec
	mov	di,offset trangroup:srcbuf	;AN000; get address of srcbuf

ctty_move_filename:				;AN000; put filespec in srcbuf
	lodsb					;AN000; get a char from buffer
	stosb					;AN000; store in srcbuf
	cmp	al,end_of_line_out		;AN000; it char a terminator?
	jnz	ctty_move_filename		;AN000; no - keep moving
	pop	si				;AN000; get line position back
	mov	di,offset trangroup:parse_ctty	;AC000; Get adderss of PARSE_CTTY
	call	parse_check_eol 		;AN000; are we at end of line?
	jz	nocolon 			;AN000; yes - continue

ctty_error:
	jmp	isbaddev			;AC000; yes - exit

nocolon:
	mov	dx,offset trangroup:srcbuf	;AN000; get address of srcbuf
	MOV	AX,(OPEN SHL 8) OR 2		; Read and write
	INT	int_command			; Open new device
	JC	ISBADDEV
	MOV	BX,AX
	MOV	AX,IOCTL SHL 8
	INT	int_command
	TEST	DL,80H
	JNZ	DEVISOK

CLOSEDEV:					;AN007;
	MOV	AH,CLOSE			; Close initial handle
	INT	int_command

ISBADDEV:
	MOV	DX,OFFSET TRANGROUP:BADDEV_ptr
	invoke	std_printf
	JMP	RESRET

DEVISOK:
	push	dx				;AN007; save device info
	mov	ax,acrlf_ptr			;AN021; get message number for 0d, 0a
	mov	dh,util_msg_class		;AN021; this is a utility message
	push	bx				;AN021; save handle
	invoke	Tsysgetmsg			;AN021; get the address of the message
	mov	dx,si				;AN021; get address into dx
	mov	ax,(write shl 8)		;AN007; write to device
	mov	cx,2				;AN007; write two bytes
	int	int_command			;AN007;
	pop	bx				;AN021; get back handle
	pop	dx				;AN007; get back device info
	jc	closedev			;AN007; if error, quit
	XOR	DH,DH
	OR	DL,3				; Make sure has CON attributes
	MOV	AX,(IOCTL SHL 8) OR 1
	INT	int_command
	PUSH	BX				; Save handle
	MOV	CX,3
	XOR	BX,BX

ICLLOOP:					; Close basic handles
	MOV	AH,CLOSE
	INT	int_command
	INC	BX
	LOOP	ICLLOOP
	POP	BX				; Get handle
	MOV	AH,XDUP
	INT	int_command			; Dup it to 0
	MOV	AH,XDUP
	INT	int_command			; Dup to 1
	MOV	AH,XDUP
	INT	int_command			; Dup to 2
	MOV	AH,CLOSE			; Close initial handle
	INT	int_command

RESRET:
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	PUSH	DS
	MOV	AX,WORD PTR DS:[PDB_JFN_Table]	; Get new 0 and 1
	MOV	[IO_SAVE],AX
	MOV	AX,OFFSET RESGROUP:LODCOM1
	PUSH	AX

ZMMMM	PROC FAR
	RET					; Force header to be checked
ZMMMM	ENDP

	break	Chcp

;****************************************************************
;*
;* ROUTINE:	CHCP - Change code page internal command
;*		(added DOS 3.30 07/21/86)
;*
;* SYNTAX:	CHCP [xxx]
;*		where xxx is a valid code page
;*
;* FUNCTION:	If xxx is specified, CHCP will use INT 21H function
;*		6402H to set the code page to xxxx. If no parameters
;*		are specified, CHCP will use INT 21H function 6401H
;*		to get global code page and display it to the user.
;*
;* INPUT:	command line at offset 81H
;*
;* OUTPUT:	none
;*
;****************************************************************

NLSFUNC_installed	equ    0ffh
set_global_cp		equ    2
get_global_cp		equ    1

assume	ds:trangroup,es:trangroup

CHCP:
	push	ds				;AN000; Get local ES
	pop	es				;AN000;
	mov	si,81H				;AC000; Get command argument for CHCP

	mov	di,offset trangroup:parse_chcp	;AN000; Get adderss of PARSE_CHCP
	xor	cx,cx				;AC000; clear cx,dx
	xor	dx,dx				;AC000;
	call	parse_with_msg			;AC018; call parser
	cmp	ax,end_of_line			;AN000; are we at end of line?

	jnz	setcp				;AC000; no go get number & set code page
	jmp	getcp				;AC000; yes - no parm - get code page

setcp:
	cmp	ax,result_no_error		;AN000; did we have an error?
	jne	cp_error			;AC018; yes - go issue message

	push	cx				;AN000; save positional count
	mov	bx,offset trangroup:parse1_addr ;AN000; get number returned
	mov	cx,word ptr [bx]		;AN000;     into cx
	mov	system_cpage,cx 		;AN000; save user input number
	pop	cx				;AC000; restore positional count
	mov	di,offset trangroup:parse_chcp	;AN000; Get adderss of PARSE_CHCP
	call	parse_check_eol 		;AN000; are we at end of line?
	jnz	cp_error			;AC000; no - exit

okset:
	mov	ah,NLSFUNC			;AN000; see if NLSFUNC installed
	mov	al,0				;AN000;
	int	2fh				;AN000;
	cmp	al,NLSFUNC_installed		;AN000;
	jz	got_NLS 			;AN000; Yes - continue
	mov	dx,offset trangroup:NLSFUNC_ptr ;AN000; no - set up error message
	jmp	short cp_error			;AN000; error exit

got_NLS:
	mov	bx,system_cpage 		;AN000; get user input code page
	mov	ah,getsetcdpg			;get/set global code page function
	mov	al,set_global_cp		;minor - set
	int	int_command
	jnc	chcp_return			;no error - exit
;
;added for p716
;
	cmp	ax,error_file_not_found 	;p716 was the error file not found?
	jnz	chcp_other_error		;no - country.sys was found

	mov	ah,GetExtendedError		;p850 see if error is invalid data
	xor	bx,bx				;  which is file was found but CP
	int	int_command			;  information was not found.
	cmp	ax,error_invalid_data		;AC000; invalid code page
	jnz	no_countrysys			;no - use file not found
	mov	dx,offset trangroup:inv_code_page ;AN000; get message
	jmp	short cp_error			;AC000; error exit

no_countrysys:
	mov	msg_disp_class,ext_msg_class	;AN000; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr  ;AC000; get extended message pointer
	mov	Extend_Buf_ptr,error_file_not_found ;AN000; get message number in control block
	jmp	short cp_error			;AC000; error exit

chcp_other_error:
;
; end of p716
;
	mov	ah,GetExtendedError		;error - see what it is
	xor	bx,bx
	int	int_command
	cmp	ax,65				;was it access denied?
	jnz	none_set			;no - assume all failed
	mov	dx,offset trangroup:cp_not_all_ptr ;set up message
	jmp	short cp_error			;AC000; error exit

none_set:
	mov	dx,offset trangroup:cp_not_set_ptr ;set up message
cp_error:					;AN000;
	jmp	cerror				;exit

getcp:
	mov	ah,getsetcdpg			;get/set global code page function
	mov	al,get_global_cp		;minor - get
	int	int_command
	mov	system_cpage,bx 		;get active cp for output
	mov	dx,offset trangroup:cp_active_ptr
	invoke	std_printf			;print it out

chcp_return:

	RET

	break	TRUENAME			;AN000;


; ****************************************************************
; *
; * ROUTINE:	 TRUENAME
; *
; * FUNCTION:	 Entry point for the internal TRUENAME command.
; *		 Parses the command line. If a path is found, set
; *		 SRCXNAME to path.  If only a drive letter is
; *		 found, set SRCXNAME to the drive letter.  If
; *		 no path is found, set the path of SRCXNAME to
; *		 dot (.) for current directory.  Use the NAME
; *		 TRANSLATE system call to get the real name and
; *		 then display the real name.  If an error occurs
; *		 issue an error message and transfer control to
; *		 CERROR.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

assume	ds:trangroup,es:trangroup		;AN000;

TRUENAME:					;AN000; TRUENAME entry point
	push	ds				;AN000; Get local ES
	pop	es				;AN000;
	mov	si,81H				;AN000; Get command line
	mov	di,offset trangroup:parse_chdir ;AN000; Get adderss of PARSE_CHDIR
	xor	cx,cx				;AN000; clear cx,dx
	xor	dx,dx				;AN000;
	call	parse_with_msg			;AC018; call parser

	mov	di,offset trangroup:srcxname	;AN000; get address of srcxname
	cmp	ax,end_of_line			;AN000; are we at end of line?
	je	tn_eol				;AN000; yes - go process
	cmp	ax,result_no_error		;AN000; did we have an error?
	jne	tn_parse_error			;AN000; yes - go issue message
	cmp	parse1_type,result_drive	;AN000; was a drive entered?
	je	tn_drive			;AN000; yes - go process
	jmp	short tn_filespec		;AN000; nothing else - must be filespec

tn_eol: 					;AN000; no parameters on line
	mov	ah,end_of_line_out		;AN000; set buffer to .
	mov	al,dot_chr			;AN000;     for current dir
	stosw					;AN000; store in srcxname
	jmp	short tn_doit			;AN000; go do command

tn_drive:					;AN000; a drive was entered
	push	si				;AN000; save position in line
	mov	si,offset trangroup:parse1_addr ;AN000; get address of drive
	lodsb					;AN000; get the drive number
	add	al,"A"-1                        ;AN000; convert it to char
	stosb					;AN000; store it in srcxname
	mov	ax,dot_colon			;AN000; get colon and . and
	stosw					;AN000;    store in srcxname
	mov	al,end_of_line_out		;AN000; put a terminator char
	stosb					;AN000;
	pop	si				;AN000; get line position back
	jmp	short tn_check_eol		;AN000; check to make sure eol

tn_filespec:					;AN000; a filespec was entered
	push	si				;AN000; save position in line
	lds	si,parse1_addr			;AN000; get address of filespec

tn_move_filename:				;AN000; put filespec in srcxname
	lodsb					;AN000; get a char from buffer
	stosb					;AN000; store in srcxname
	cmp	al,end_of_line_out		;AN000; it char a terminator?
	jnz	tn_move_filename		;AN000; no - keep moving
	pop	si				;AN000; get line position back

tn_check_eol:					;AN000; make sure no extra parms
	mov	di,offset trangroup:parse_chdir ;AN000; get address of parse_chdir
	call	parse_check_eol 		;AN000; are we at end of line?
	je	tn_doit 			;AN000; Yes - do the command

tn_parse_error: 				;AN000; A parse error occurred
	jmp	cerror				;AN000; Go to error routine

tn_doit:					;AN000;
	mov	si,offset trangroup:srcxname	;AN000; set up srcxname as source
	mov	di,offset trangroup:combuf	;AN000; set up combuf as target (need big target)
	mov	ah,xnametrans			;AN000; do name translate call
	int	int_command			;AN000;
	jnc	tn_print_xname			;AN000; If no error - print result

	invoke	Set_ext_error_msg		;AN000; get extended message
	mov	string_ptr_2,offset trangroup:srcxname ;AN000; get address of failed string
	mov	Extend_buf_sub,one_subst	;AN000; put number of subst in control block
	jmp	cerror				;AN000; Go to error routine

tn_print_xname: 				;AN000;
	mov	string_ptr_2,offset Trangroup:combuf ;AN000; Set up address of combuf
	mov	dx,offset trangroup:string_buf_ptr   ;AN000; Set up address of print control block
	invoke	crlf2				;AN000; print a crlf
	invoke	printf_crlf			;AN000; print it out

	ret					;AN000;

	break	$Exit

assume	ds:trangroup,es:trangroup

$EXIT:
	push	ds				;AN000; save data segment
	mov	ds,[resseg]			;AN000; get resident data segment

assume	ds:resgroup				;AN000;

	cmp	[permcom],0			;AN045; is this a permanent COMMAND?
	jnz	no_reset			;AN045; Yes - don't do anything
;AD060; mov	ah,multdos			;AN000; reset parse message pointers
;AD060; mov	al,message_2f			;AN000; call for message retriever
;AD060; mov	dl,set_parse_msg		;AN000; set up parse message address
;AD060; mov	di,pars_msg_off 		;AN000; old offset of parse messages
;AD060; mov	es,pars_msg_seg 		;AN000; old segment of parse messages
;AD060; int	2fh				;AN000; go set it

;AD060; mov	ah,multdos			;AN000; set up to call DOS through int 2fh
;AD060; mov	al,message_2f			;AN000; call for message retriever
	mov	ax,(multdos shl 8 or message_2f);AN060; reset parse message pointers
	mov	dl,set_critical_msg		;AN000; set up critical error message address
	mov	di,crit_msg_off 		;AN000; old offset of critical messages
	mov	es,crit_msg_seg 		;AN000; old segment of critical messages
	int	2fh				;AN000; go set it
no_reset:					;AN045;
	pop	ds				;AN000; restore local data segment

assume	ds:trangroup				;AN000;

	MOV	ES,[RESSEG]

assume	es:resgroup

	MOV	AX,[PARENT]
	MOV	WORD PTR ES:[PDB_Parent_PID],AX
	MOV	AX,WORD PTR OldTerm
	MOV	WORD PTR ES:[PDB_Exit],AX
	MOV	AX,WORD PTR OldTerm+2
	MOV	WORD PTR ES:[PDB_Exit+2],AX

	PUSH	ES
	MOV	ES,[TRAN_TPA]
	MOV	AH,DEALLOC
	INT	int_command			; Now running in "free" space
	POP	ES

	MOV	AH,Exit
	MOV	AL,BYTE PTR RetCode
	INT	int_command


; ****************************************************************
; *
; * ROUTINE:	 PARSE_CHECK_EOL
; *
; * FUNCTION:	 Calls parser to see if end of line occurred.
; *		 If not end of line, set up to print parse
; *		 error message.  ASSUMES NO MORE PARAMETERS ARE
; *		 EXPECTED!
; *
; * INPUT:	 DS:SI	  last output from parser
; *		 ES:DI	  points to parse block
; *		 CX	  last output from parser
; *
; * OUTPUT:	 AX	  parser return code
; *
; *		 if end of line found
; *		     zero flag set
; *		 else
; *		     MSG_DISPLAY_CLASS set to parse error
; *
; ****************************************************************

ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:NOTHING	;AN000;

parse_check_eol Proc near			;AN000;

	xor	dx,dx				;AN000;
	mov	[parse_last],si 		;AN018; save start of parameter
	invoke	cmd_parse			;AN000; call parser
	cmp	al,end_of_line			;AN000; Are we at end of line?
	jz	parse_good_eol			;AN000; yes - no problem

	cmp	ax,result_no_error		;AN018; was any error found?
	jnz	ok_to_setup_pmsg		;AN018; yes - continue
	inc	ax				;AN018; set AX to 1 and turn off zero flag

ok_to_setup_pmsg:
	call	setup_parse_error_msg		;AN018; go set up error message

parse_good_eol:
	ret					;AN000;

parse_check_eol endp				;AN000;

; ****************************************************************
; *
; * ROUTINE:	 PARSE_WITH_MSG
; *
; * FUNCTION:	 Calls parser.	If an error occurred, the error
; *		 message is set up.
; *
; * INPUT:	 DS:SI	  last output from parser
; *		 ES:DI	  points to parse block
; *		 CX	  last output from parser
; *
; * OUTPUT:	 AX	  parser return code
; *
; *		 if no error
; *		     outputs from parser
; *		 else
; *		     MSG_DISPLAY_CLASS set to parse error
; *		     error message set up for STD_PRINTF
; *
; ****************************************************************

ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:NOTHING	;AN018;

parse_with_msg	Proc near			;AN018;

	mov	[parse_last],si 		;AN018; save start of parameter
	invoke	cmd_parse			;AN018; call parser
	cmp	al,end_of_line			;AN018; Are we at end of line?
	jz	parse_msg_good			;AN018; yes - no problem
	cmp	ax,result_no_error		;AN018; did an error occur
	jz	parse_msg_good			;AN018; yes - no problem

	call	setup_parse_error_msg		;AN018; go set up error message

parse_msg_good:
	ret					;AN018;

parse_with_msg endp				;AN018;

; ****************************************************************
; *
; * ROUTINE:	 SETUP_PARSE_ERROR_MSG
; *
; * FUNCTION:	 Calls parser.	If an error occurred, the error
; *		 message is set up.
; *
; * INPUT:	 AX	     Parse error number
; *		 SI	     Set to past last parameter
; *		 Parse_last  Set to start of last parameter
; *
; * OUTPUT:	 MSG_DISPLAY_CLASS set to parse error
; *		 error message set up for STD_PRINTF
; *
; ****************************************************************

ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:NOTHING	;AN018;

SETUP_PARSE_ERROR_MSG	Proc near		;AN018;

	mov	msg_disp_class,parse_msg_class	;AC018; Set up parse message class
	mov	dx,offset TranGroup:Extend_Buf_ptr  ;AC018; get extended message pointer
	mov	byte ptr [si],end_of_line_out	;AC018; terminate the parameter string
	mov	Extend_Buf_ptr,ax		;AC018; get message number in control block
	cmp	ax,lessargs_ptr 		;AC018; if required parameter missing
	jz	Setup_parse_msg_ret		;AN018;    no subst
	mov	si,[parse_last] 		;AC018; get start of parameter
	mov	string_ptr_2,si 		;AC018; get address of failed string
	mov	Extend_buf_sub,one_subst	;AC018; put number of subst in control block

setup_parse_msg_ret:
	inc	si				;AN018; make sure zero flag not set

	ret					;AC018;

SETUP_PARSE_ERROR_MSG	Endp			;AN018;

trancode    ends
	    end
