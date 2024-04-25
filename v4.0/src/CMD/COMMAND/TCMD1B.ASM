 page 80,132
;	SCCSID = @(#)tcmd1b.asm 1.1 85/05/14
;	SCCSID = @(#)tcmd1b.asm 1.1 85/05/14
TITLE	PART4 COMMAND Transient routines.

;	Internal commands DIR,PAUSE,ERASE,TYPE,VOL,VER

.xlist
.xcref
	INCLUDE DOSSYM.INC
	INCLUDE comseg.asm
	INCLUDE comsw.asm		;AC000;
	INCLUDE comequ.asm
	INCLUDE ioctl.inc		;AN000;
	INCLUDE ea.inc			;AN030;
.list
.cref


TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	badcpmes_ptr:word	;AC022;
	EXTRN	Extend_buf_ptr:word	;AC000;
	EXTRN	Extend_buf_sub:byte	;AN000;
	EXTRN	inornot_ptr:word
	EXTRN	msg_disp_class:byte	;AC000;
	EXTRN	parse_erase:byte	;AC000;
	EXTRN	parse_mrdir:byte	;AC000;
	EXTRN	parse_rename:byte	;AC000;
	EXTRN	parse_vol:byte		;AC000;
	EXTRN	PauseMes_ptr:word
	EXTRN	renerr_ptr:word
	EXTRN	slash_p_syn:word	;AC000;
	EXTRN	volmes_ptr:word 	;AC000;
	EXTRN	volmes_ptr_2:word	;AC000;
	EXTRN	volsermes_ptr:word	;AC000;
	EXTRN	xa_cp:byte		;AN030;
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	bytcnt:word
	EXTRN	charbuf:byte
	EXTRN	comsw:word
	EXTRN	cpyflag:byte		;AC000;
	EXTRN	curdrv:byte
	EXTRN	destinfo:byte
	EXTRN	destisdir:byte
	EXTRN	dirbuf:byte
	EXTRN	msg_numb:word		;AN022;
	EXTRN	one_char_val:byte
	EXTRN	parse1_addr:dword	;AN000;
	EXTRN	parse1_syn:word 	;AN000;
	EXTRN	srcbuf:byte		;AN000;
	EXTRN	string_ptr_2:word	;AN000;
	EXTRN	TPA:word
	EXTRN	vol_drv:byte
	EXTRN	vol_ioctl_buf:byte	;AC000;
	EXTRN	vol_label:byte		;AC000;
	EXTRN	vol_serial:dword	;AC000;
	EXTRN	xa_cp_out:byte		;AN030;
	EXTRN	xa_cp_length:word	;AN030;
	EXTRN	xa_list_attr:word	;AC030;
	EXTRN	zflag:byte
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;---------------

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg:byte		; the arg structure!
transpace   ends
;---------------

	EXTRN	cerror:near
	EXTRN	error_output:near
	EXTRN	notest2:near
	EXTRN	slashp_erase:near	;AN000;
	EXTRN	std_printf:near
	EXTRN	tcommand:near

	PUBLIC	badpath_err		;AN022;
	PUBLIC	crename
	PUBLIC	erase
	PUBLIC	extend_setup		;AN022;
	PUBLIC	Get_ext_error_number	;AN022;
	PUBLIC	Get_file_code_page_tag	;AN000;
	PUBLIC	pause
	PUBLIC	Set_ext_error_msg	;AN000;
	PUBLIC	set_file_code_page	;AN000;
	PUBLIC	typefil
	PUBLIC	volume


assume	ds:trangroup,es:trangroup

	break	Pause
assume	ds:trangroup,es:trangroup

PAUSE:
	mov	dx,offset trangroup:pausemes_ptr
	call	std_printf
	invoke	GetKeystroke
	invoke	crlf2
	return

	break	Erase

;****************************************************************
;*
;* ROUTINE:	DEL/ERASE - erase file(s)
;*
;* FUNCTION:	PARSE command line for file or path name and /P
;*		and invoke PATHCRUNCH.	If an error occurs, set
;*		up an error message and transfer control to CERROR.
;*		Otherwise, transfer control to NOTEST2 if /P not
;*		entered or SLASHP_ERASE if /P entered.
;*
;* INPUT:	command line at offset 81H
;*
;* OUTPUT:	if no error:
;*		FCB at 5ch set up with filename(s) entered
;*		Current directory set to entered directory
;*
;****************************************************************

assume	ds:trangroup,es:trangroup

ERASE:
	mov	si,81H				;AC000; get command line
	mov	comsw,0 			;AN000; clear switch indicator
	mov	di,offset trangroup:parse_erase ;AN000; Get adderss of PARSE_erase
	xor	cx,cx				;AN000; clear cx,dx

erase_scan:
	xor	dx,dx				;AN000;
	invoke	parse_with_msg			;AC018; call parser
	cmp	ax,end_of_line			;AN000; are we at end of line?
	jz	good_line			;AN000; yes - done parsing
	cmp	ax,result_no_error		;AC000; did we have an error?
	jnz	errj2				;AC000; yes exit

	cmp	parse1_syn,offset trangroup:slash_p_syn ;AN000; was /P entered?
	je	set_erase_prompt		;AN000; yes - go set prompt

;
; Must be filespec since no other matches occurred. move filename to srcbuf
;
	push	si				;AC000; save position in line
	lds	si,parse1_addr			;AC000; get address of filespec
	cmp	byte ptr[si+1],colon_char	;AC000; drive specified?
	jnz	Erase_drive_ok			;AC000; no - continue
	cmp	byte ptr[si+2],end_of_line_out	;AC000; was only drive entered?
	jnz	erase_drive_ok			;AC000; no - continue
	mov	ax,error_file_not_found 	;AN022; get message number in control block
	jmp	short extend_setup		;AC000; exit

erase_drive_ok:
	invoke	move_to_srcbuf			;AC000; move to srcbuf
	pop	si				;AC000; get position back
	jmp	short erase_scan		;AN000; continue parsing

set_erase_prompt:
	cmp	comsw,0 			;AN018; was /P already entered?
	jz	ok_to_set_erase_prompt		;AN018; no go set switch
	mov	ax,moreargs_ptr 		;AN018; set up too many arguments
	invoke	setup_parse_error_msg		;AN018; set up an error message
	jmp	short errj2			;AN018; exit

ok_to_set_erase_prompt: 			;AN018;
	inc	comsw				;AN000; indicate /p specified
	jmp	short erase_scan		;AN000; continue parsing

good_line:					;G  We know line is good
	invoke	pathcrunch
	jnc	checkdr
	mov	ax,[msg_numb]			;AN022; get message number
	cmp	ax,0				;AN022; was message flag set?
	jnz	extend_setup			;AN022; yes - print out message
	cmp	[destisdir],0			; No CHDIRs worked
	jnz	badpath_err			;AC022; see if they should have

checkdr:
	cmp	comsw,0 			;AN000; was /p specified
	jz	notest2j			;AN000; no - go to notest2
	jmp	slashp_erase			;AN000; yes - go to slashp_erase

notest2j:
	jmp	notest2

badpath_err:					;AN022; "Path not found" message
	mov	ax,error_path_not_found 	;AN022; set up error number

extend_setup:					;AN022;
	mov	msg_disp_class,ext_msg_class	;AN022; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr ;AC022; get extended message pointer
	mov	Extend_Buf_ptr,ax		;AN022; get message number in control block
errj2:						;AC022; exit jump
	jmp	Cerror				;AN022;

	break	Rename

; ****************************************************************
; *
; * ROUTINE:	 CRENAME - rename file(s)
; *
; * FUNCTION:	 PARSE command line for one full filespec and one
; *		 filename.  Invoke PATHCRUNCH on the full filespec.
; *		 Make sure the second filespec only contains a
; *		 filename.  If both openands are valid, attempt
; *		 to rename the file.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

assume	ds:trangroup,es:trangroup

CRENAME:

	mov	si,81H				;AC000; Point to command line
	mov	di,offset trangroup:parse_rename;AN000; Get adderss of PARSE_RENAME
	xor	cx,cx				;AN000; clear cx,dx
	xor	dx,dx				;AN000;
	invoke	parse_with_msg			;AC018; call parser
	cmp	ax,result_no_error		;AC000; did we have an error?
	jz	crename_no_parse_error		;AC000; no - continue
	JMP	crename_parse_error		;AC000; Yes, fail. (need long jump)

;
;  Get first file name returned from parse into our buffer
;
crename_no_parse_error:
	push	si				;AN000; save position in line
	lds	si,parse1_addr			;AN000; get address of filespec
	invoke	move_to_srcbuf			;AN000; move to srcbuf
	pop	si				;AN000; restore position in line

	xor	dx,dx				;AN000; clear dx
	invoke	parse_with_msg			;AC018; call parser
	cmp	ax,result_no_error		;AN000; did we have an error?
	JNZ	crename_parse_error		;AN000; Yes, fail.

;
;  Check the second file name for drive letter colon
;
	push	si				;AN000; save position in line
	lds	si,parse1_addr			;AC000; get address of path

	mov	al,':'                          ;AC000;
	cmp	[si+1],al			;AC000; Does the 2nd parm have a drive spec?
	jnz	ren_no_drive			;AN000; Yes, error
	mov	msg_disp_class,parse_msg_class	;AN000; set up parse error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr  ;AC000; get extended message pointer
	mov	Extend_Buf_ptr,BadParm_ptr	;AN000; get "Invalid parameter" message number

	pop	si				;AN000;
crename_parse_error:				;AC022;
	jmp	short errj			;AC000;

;
;  Get second file name returned from parse into the fCB.  Save
;  character after file name so we can later check to make sure it
;  isn't a path character.
;

ren_no_drive:
	mov	di,FCB+10H			;AC000; set up to parse second file name
	mov	ax,(Parse_File_Descriptor SHL 8) OR 01H ;AC000;
	int	int_command			;AC000; do the function
	lodsb					;AC000; Load char after filename
	mov	one_char_val,al 		;AN000; save char after filename
	pop	si				;AN000; get line position back

;
; We have source and target.  See if any args beyond.
;

	mov	di,offset trangroup:parse_rename;AC000; get address of parse_rename
	invoke	parse_check_eol 		;AC000; are we at end of line?
	jnz	crename_parse_error		;AN000; no, fail.

	invoke	pathcrunch
	mov	dx,offset trangroup:badcpmes_ptr
	jz	errj2				; If 1st parm a dir, print error msg
	jnc	notest3
	mov	ax,[msg_numb]			;AN022; get message number
	cmp	ax,0				;AN022; was message flag set?
	jnz	extend_setup			;AN022; yes - print out message
	cmp	[destisdir],0			; No CHDIRs worked
	jz	notest3 			; see if they should have
	Jmp	badpath_err			;AC022; set up error

notest3:
	mov	al,one_char_val 		;AN000; move char into AX
	mov	dx,offset trangroup:inornot_ptr ; Load invalid fname error ptr
	invoke	pathchrcmp			; Is the char in al a path sep?
	jz	errj				; Yes, error - 2nd arg must be
						;  filename only.

	mov	ah,FCB_Rename
	mov	dx,FCB
	int	int_command
	cmp	al, 0FFH			; Did an error occur??
	jnz	renameok

	invoke	get_ext_error_number		;AN022; get extended error
	SaveReg <AX>				;AC022; Save results
	mov	al, 0FFH			; Restore original error state

renameok:
	push	ax
	invoke	restudir
	pop	ax
	inc	al
	retnz

	RestoreReg  <AX>			;AC022; get the error number back
	cmp	ax,error_file_not_found 	;AN022; error file not found?
	jz	use_renerr			;AN022; yes - use generic error message
	cmp	ax,error_access_denied		;AN022; error file not found?
	jz	use_renerr			;AN022; yes - use generic error message
	jmp	extend_setup			;AN022; need long jump - use extended error

use_renerr:
	mov	dx,offset trangroup:RenErr_ptr	;AC022;

ERRJ:
	jmp	Cerror

ret56:	ret

	break	Type

;****************************************************************
;*
;* ROUTINE:	TYPEFIL - Display the contents of a file to the
;*		standard output device
;*
;* SYNTAX:	TYPE filespec
;*
;* FUNCTION:	If a valid filespec is found, read the file until
;*		1Ah and display the contents to STDOUT.
;*
;* INPUT:	command line at offset 81H
;*
;* OUTPUT:	none
;*
;****************************************************************

assume	ds:trangroup,es:trangroup

TYPEFIL:
	mov	si,81H
	mov	di,offset trangroup:parse_mrdir ;AN000; Get adderss of PARSE_MRDIR
	xor	cx,cx				;AN000; clear cx,dx
	xor	dx,dx				;AN000;
	invoke	parse_with_msg			;AC018; call parser
	cmp	ax,result_no_error		;AC000; did we have an error?
	jnz	typefil_parse_error		;AN000; yes - issue error message

	push	si				;AC000; save position in line
	lds	si,parse1_addr			;AC000; get address of filespec
	invoke	move_to_srcbuf			;AC000; move to srcbuf
	pop	si				;AC000; get position back
	mov	di,offset trangroup:parse_mrdir ;AC000; get address of parse_mrdir
	invoke	parse_check_eol 		;AC000; are we at end of line?
	jz	gottarg 			;AC000; yes - continue

typefil_parse_error:				;AN000; no - set up error message and exit
	jmp	Cerror

gottarg:
	invoke	setpath
	test	[destinfo],00000010b		; Does the filespec contain wildcards
	jz	nowilds 			; No, continue processing
	mov	dx,offset trangroup:inornot_ptr ; Yes, report error
	jmp	Cerror
nowilds:
	mov	ax,ExtOpen SHL 8		;AC000; open the file
	mov	bx,read_open_mode		;AN000; get open mode for TYPE
	xor	cx,cx				;AN000; no special files
	mov	dx,read_open_flag		;AN000; set up open flags
	mov	di,-1				;AN030; no parm list
	mov	si,offset trangroup:srcbuf	;AN030; get file name
	int	int_command
	jnc	typecont			; If open worked, continue. Otherwise load

Typerr: 					;AN022;
	push	cs				;AN022; make sure we have local segment
	pop	ds				;AN022;
	invoke	set_ext_error_msg		;AN022;

Typerr2:					;AN022;
	mov	string_ptr_2,offset trangroup:srcbuf ;AC022; get address of failed string
	mov	Extend_buf_sub,one_subst	;AC022; put number of subst in control block
	jmp	cerror				;AC022; exit

typecont:
	mov	bx,ax				;AC000; get  Handle
	mov	cx,stdout			;AN000; set output to STDOUT
	call	set_file_code_page		;AN000; Set code page on output device
	jc	typerr2 			;AN022; exit if error

	mov	zflag,0 			; Reset ^Z flag
	mov	ds,[TPA]
	xor	dx,dx
ASSUME	DS:NOTHING

typelp:
	cmp	cs:[zflag],0			;AC050; Is the ^Z flag set?
	retnz					; Yes, return
	mov	cx,cs:[bytcnt]			;AC056; No, continue
	mov	ah,read
	int	int_command
	jc	typerr				;AN022; Exit if error
	mov	cx,ax
	jcxz	typelp_ret			;AC000; exit if nothing read
	push	ds
	pop	es				; Check to see if a ^Z was read.
assume es:nothing
	xor	di,di
	push	ax
	mov	al,1ah
	repnz	scasb
	pop	ax
	xchg	ax,cx
	cmp	ax,0
	jnz	foundz				; Yes, handle it
	cmp	byte ptr [di-1],1ah		; No, double check
	jnz	typecont2			; No ^Z, continue

foundz:
	sub	cx,ax				; Otherwise change cx so that only those
	dec	cx				;  bytes up to but NOT including the ^Z
	push	cs				;  will be typed.
	pop	es
assume es:trangroup
	not	zflag				; Turn on ^Z flag so that the routine

typecont2:					;  will quit after this write.
	push	bx
	mov	bx,1
	mov	ah,write
	int	int_command
	pop	bx
	jc	Error_outputj
	cmp	ax,cx
	jz	typelp
	dec	cx
	cmp	ax,cx
	retz					; One less byte OK (^Z)

Error_outputj:
	mov	bx,1
	mov	ax,IOCTL SHL 8
	int	int_command
	test	dl,devid_ISDEV
	retnz					; If device, no error message
	jmp	error_output

typelp_ret:
	ret

	break	Volume
assume	ds:trangroup,es:trangroup

;
; VOLUME command displays the volume ID on the specified drive
;
VOLUME:

	mov	si,81H
	mov	di,offset trangroup:parse_vol	;AN000; Get adderss of PARSE_VOL
	xor	cx,cx				;AN000; clear cx,dx
	xor	dx,dx				;AN000;
	invoke	parse_with_msg			;AC018; call parser
	cmp	ax,end_of_line			;AC000; are we at end of line?
	jz	OkVolArg			;AC000; Yes, display default volume ID
	cmp	ax,result_no_error		;AC000; did we have an error?
	jnz	BadVolArg			;AC000; Yes, fail.
;
; We have parsed off the drive.  See if there are any more chars left
;

	mov	di,offset trangroup:parse_vol	;AC000; get address of parse_vol
	xor	dx,dx				;AC000;
	invoke	parse_check_eol 		;AC000; call parser
	jz	OkVolArg			;AC000; yes, end of road
;
; The line was not interpretable.  Report an error.
;
badvolarg:
	jmp	Cerror
;
; Find the Volume ID on the disk.
;
PUBLIC	OkVolArg
OKVOLARG:
	invoke	crlf2
	mov	al,blank			;AN051; Print out a blank
	invoke	print_char			;AN051;   before volume message
	push	ds
	pop	es
;
; Volume IDs are only findable via extended FCBs or find_first with attributes
; of volume_id ONLY.
;

	mov	di,FCB-7			; Point to extended FCB beginning
	mov	al,-1				; Tag to indicate Extention
	stosb
	xor	ax,ax				; Zero padding to volume label
	stosw
	stosw
	stosb
	mov	al,attr_volume_ID		; Look for volume label
	stosb
	inc	di				; Skip drive byte; it is already set
	mov	cx,11				; fill in remainder of file
	mov	al,'?'
	rep	stosb
;
; Set up transfer address (destination of search first information)
;
	mov	dx,offset trangroup:dirbuf
	mov	ah,set_DMA
	int	int_command
;
; Do the search
;
	mov	dx,FCB-7
	mov	ah,Dir_Search_First
	int	int_command

;********************************
; Print volume ID info

	push	ax				;AC000; AX return from SEARCH_FIRST for VOL ID
	mov	al,DS:[FCB]			;AC000; get drive letter
	add	al,'@'
	cmp	al,'@'
	jnz	drvok
	mov	al,[curdrv]
	add	al,capital_A
drvok:
	mov	vol_drv,al			;AC000; get drive letter into argument
	pop	ax				;AC000; get return code back
	or	al,al				;AC000; volume label found?
	jz	Get_vol_name			;AC000; volume label exists - go get it
	mov	dx,offset trangroup:VolMes_ptr_2 ;AC000; set up no volume message
	jmp	short print_serial		;AC000; go print it

Get_vol_name:
	mov	di,offset trangroup:charbuf
	mov	dx,di
	mov	si,offset trangroup:dirbuf + 8	;AN000;  3/3/KK
	mov	cx,11				;AN000;  3/3/KK
	rep	movsb				;AN000;  3/3/KK

	xor	al,al				;AC000; store a zero to terminate the string
	stosb
	mov	dx,offset trangroup:VolMes_ptr	;AC000; set up message

PRINT_SERIAL:

;
; Attempt to get the volume serial number from the disk.  If an error
; occurs, do not print volume serial number.
;

	push	dx				;AN000; save message offset
	mov	ax,(GetSetMediaID SHL 8)	;AC036; Get the volume serial info
	mov	bl,DS:[FCB]			;AN000; get drive number from FCB
	mov	dx,offset trangroup:vol_ioctl_buf ;AN000;target buffer
	int	int_command			;AN000; do the call
	pop	dx				;AN000; get message offset back
	jc	printvol_end			;AN000; if error, just go print label
	call	std_printf			;AC000; go print volume message
	mov	al,blank			;AN051; Print out a blank
	invoke	print_char			;AN051;   before volume message
	mov	dx,offset trangroup:VolSerMes_ptr ;AN000; get serial number message

printvol_end:
	jmp	std_printf			;AC000; go print and exit

;****************************************************************
;*
;* ROUTINE:	Set file Code page
;*
;* FUNCTION:	Check CPSW status, if CPSW is on, get the file's
;*		code page and attempt to invoke it on the
;*		output device.
;*
;* INPUT:	file handle in BX - unless copyflg is set
;*		handle of output device in CX
;*
;* OUTPUT:	if carry set  (code page invoke failed)
;*		   ax = extended error
;*		otherwise
;*		   ax modified
;*
;*
;****************************************************************

Set_file_code_page proc near			;AN000;

	push	bx				;AN000; save registers
	push	di				;AN000;
	push	dx				;AN000;

	cmp	cpyflag,1			;AN000; were we called from COPY?
	jz	Already_have_cp 		;AN000; yes - already have code page
	call	get_file_code_page_tag		;AN000; get the file's code page
	jc	cp_set_error			;AN000; if error - just continue

already_have_cp:				;AN000; See what was returned.
	mov	ax,(file_times SHL 8)+set_XA	;AC030; set code page
	mov	di,offset trangroup:xa_cp_out	;AC030; offset of attr list
	mov	bx,cx				;AN000; get handle of output device
	int	int_command			;AN000;
	jnc	set_file_cp_end 		;AN000; all okay - return
cp_set_error:
	pop	dx				;AC030; we don't restore DX for error -
	call	Set_Ext_Error_msg		;AN000;    we return error message
	jmp	short set_file_cp_exit		;AC030; exit

set_file_cp_end:				;AN000; finished
	pop	dx				;AN000; restore registers

set_file_cp_exit:
	pop	di				;AN000;
	pop	bx				;AN000;

	ret					;AN000; return

Set_file_code_page endp 			;AN000;


;****************************************************************
;*
;* ROUTINE:	Get file Code page tag
;*
;* FUNCTION:	Get code page file attribute.
;*
;* INPUT:	file handle in BX
;*
;* OUTPUT:	if error - carry set
;*		otherwise - xa_list_attr set to file's code page
;*
;*		AX and DI modified
;*
;****************************************************************


Get_file_code_page_tag proc near		;AN000;

	push	cx				;AN030;
	push	si				;AN030;
	push	di				;AN030;
	mov	xa_list_attr,0			;AN030; initialize code page
	mov	ax,(file_times SHL 8)+get_XA	;AC030; get extended attributes
	mov	si,offset trangroup:xa_cp	;AN030; get xa request buffer
	mov	di,offset trangroup:xa_cp_out	;AC030; get xa output buffer
	mov	cx,xa_cp_length 		;AN030; length of buffer
	int	int_command			;AN000;
	pop	di				;AN030;
	pop	si				;AN030;
	pop	cx				;AN030;

	ret					;AN000; return

Get_file_code_page_tag endp			;AN000;


;****************************************************************
;*
;* ROUTINE:	Set_ext_error_msg
;*
;* FUNCTION:	Sets up extended error message for printing
;*
;* INPUT:	return from INT 21
;*
;* OUTPUT:	extended error message set up in extended error
;*		buffer.
;*
;****************************************************************

Set_ext_error_msg proc near			;AN000;

	call	get_ext_error_number		;AC022; get the extended error
	mov	msg_disp_class,ext_msg_class	;AN000; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr ;AC000; get extended message pointer
	mov	Extend_Buf_ptr,ax		;AN000; get message number in control block
	stc					;AN000; make sure carry is set

	ret					;AN000; return

Set_ext_error_msg endp				;AN000;

;****************************************************************
;*
;* ROUTINE:	Get_ext_error_number
;*
;* FUNCTION:	Does get extended error function call
;*
;* INPUT:	return from INT 21
;*
;* OUTPUT:	AX - extended error number
;*
;****************************************************************

Get_ext_error_number proc near			;AN022;

	SaveReg <BX,CX,DX,SI,DI,BP,ES,DS>	;AN022; save registers
	mov	ah,GetExtendedError		;AN022; get extended error
	xor	bx,bx				;AN022; clear BX
	int	int_command			;AN022;
	RestoreReg  <DS,ES,BP,DI,SI,DX,CX,BX>	;AN022; restore registers

	ret					;AN022; return

Get_ext_error_number endp			;AN022;

trancode    ends
	    end
