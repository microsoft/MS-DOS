 page 80,132
;	SCCSID = @(#)tcmd1a.asm 1.1 85/05/14
;	SCCSID = @(#)tcmd1a.asm 1.1 85/05/14
TITLE	PART4 COMMAND Transient routines.

;	Internal commands DIR,PAUSE,ERASE,TYPE,VOL,VER

	INCLUDE comsw.asm
.xlist
.xcref
	INCLUDE DOSSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm		;AC000;
	include ioctl.inc		;AN000;
.list
.cref

DATARES SEGMENT PUBLIC BYTE		;AN020;
	EXTRN	append_flag:byte	;AN020;
	EXTRN	append_state:word	;AN020;
DATARES ENDS				;AN020;

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BadCD_ptr:word
	EXTRN	bits:word
	EXTRN	Bytmes_ptr:word
	EXTRN	comsw:word
	EXTRN	dir_w_syn:word		;AC000;
	EXTRN	dirdat_mo_day:word	;AC000;
	EXTRN	dirdat_yr:word		;AC000;
	EXTRN	dirdattim_ptr:word
	EXTRN	dirhead_ptr:word
	EXTRN	dirtim_hr_min:word	;AC000;
	EXTRN	Dirmes_ptr:word
	EXTRN	disp_file_size_ptr:word
	EXTRN	Dmes_ptr:word
	EXTRN	Extend_buf_ptr:word	;AN000;
	EXTRN	msg_disp_class:byte	;AN000;
	EXTRN	parse_dir:byte		;AC000;
	EXTRN	slash_p_syn:word	;AC000;
	EXTRN	string_buf_ptr:word
	EXTRN	tab_ptr:word		;AC000;
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	bytes_free:word
	EXTRN	charbuf:byte
	EXTRN	COM:byte
	EXTRN	Destisdir:byte
	EXTRN	Desttail:word
	EXTRN	dir_num:word
	EXTRN	Dirbuf:byte
	EXTRN	dirflag:byte		;AN015;
	EXTRN	display_ioctl:word	;AC000;
	EXTRN	display_mode:byte	;AC000;
	EXTRN	filecnt:word
	EXTRN	file_size_high:word
	EXTRN	file_size_low:word
	EXTRN	fullscr:word
	EXTRN	ID:byte
	EXTRN	lincnt:byte		;AC000;
	EXTRN	linlen:byte
	EXTRN	linperpag:word		;AC000;
	EXTRN	msg_numb:word		;AN022;
	EXTRN	parse1_addr:dword	;AC000;
	EXTRN	parse1_syn:word 	;AC000;
	EXTRN	parse1_type:byte	;AC000;
	EXTRN	pathcnt:word		;AN000;
	EXTRN	pathpos:word		;AN000;
	EXTRN	resseg:word		;AN020;
	EXTRN	srcbuf:byte		;AC000;
	EXTRN	string_ptr_2:word
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;---------------

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg:byte		; the arg structure!
TRANSPACE	ENDS
;---------------

	EXTRN	cerror:near
	EXTRN	std_printf:near


	PUBLIC	catalog


	break	Catalog - Directory command
assume	ds:trangroup,es:trangroup

;
; The DIR command displays the contents of a directory.
;
; ****************************************************************
; *
; * ROUTINE:	 CATALOG - display file(s) in directory
; *
; * FUNCTION:	 PARSE command line for drive, file, or path name.
; *		 DIR allows two switches, /P (pause) and /W (wide).
; *		 If an error occurs issue and error message and
; *		 transfer control to CERROR.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

CATALOG:

;
; Set up DTA for dir search firsts
;
	mov	dx,offset trangroup:Dirbuf	;AC000; Set Disk transfer address
	mov	ah,Set_DMA			;AC000;
	int	int_command			;AC000;
;
; Set up defaults for switches and parse the command line.
;
	mov	msg_numb,0			;AN022; initialize message flag
	mov	di,offset trangroup:srcbuf	;AN000; get address of srcbuf
	mov	[pathpos],di			;AN000; this is start of path
	mov	[pathcnt],1			;AN000; initialize length to 1 char
	mov	al,star 			;AN000; initialize srcbuf to *,0d
	stosb					;AN000;
	mov	al,end_of_line_in		;AN000;
	stosb					;AN000;
	mov	si,81H				;AN000; Get command line
	mov	di,offset trangroup:parse_dir	;AN000; Get adderss of PARSE_DIR
	xor	cx,cx				;AC000; clear counter for positionals
	mov	ComSw,cx			;AC000; initialize flags
	mov	bits,cx 			;AC000; initialize switches
	mov	linperpag,linesperpage		;AC000; Set default for lines per page
	mov	linlen,normperlin		;AC000; Set number of entries per line
	mov	lincnt,normperlin		;AC000;

dirscan:
	xor	dx,dx				;AN000;
	invoke	parse_with_msg			;AC018; call parser
	cmp	ax,end_of_line			;AN000; are we at end of line?
	jne	dirscan_cont			;AN000; No - continue parsing
	jmp	scandone			;AN000; yes - go process

dirscan_cont:
	cmp	ax,result_no_error		;AN000; did we have an error?
	jz	dirscan_cont2			;AN000; No - continue parsing
	jmp	badparm 			;AN000; yes - exit

dirscan_cont2:
	cmp	parse1_syn,offset trangroup:dir_w_syn ;AN000; was /W entered?
	je	set_dir_width			;AN000; yes - go set wide lines
	cmp	parse1_syn,offset trangroup:slash_p_syn ;AN000; was /P entered?
	je	set_dir_pause			;AN000; yes - go set pause at end of screen
;
; Must be filespec since no other matches occurred. move filename to srcbuf
;
	push	si				;AC000; save position in line
	lds	si,parse1_addr			;AC000; get address of filespec
	push	si				;AN000; save address
	invoke	move_to_srcbuf			;AC000; move to srcbuf
	pop	dx				;AC000; get address in DX

;
; The user may have specified a device.  Search for the path and see if the
; attributes indicate a device.
;
	mov	ah,Find_First			;AC000; find the file
	int	int_command			;AC000;
	jnc	Dir_check_device		;AN022; if no error - check device
	invoke	get_ext_error_number		;AN022; get the extended error
	cmp	ax,error_no_more_files		;AN022; was error no file found
	jz	Dir_fspec_end			;AC022; yes -> obviously not a device
	cmp	ax,error_path_not_found 	;AN022; was error no file found
	jz	Dir_fspec_end			;AC022; yes -> obviously not a device
	jmp	dir_err_setup			;AN022; otherwise - go issue error message

dir_check_device:				;AN022;
	test	byte ptr (DirBuf+find_buf_attr),attr_device ;AC000;
	jz	Dir_fspec_end			;AC000; no, go do normal operation
	mov	ComSw,-2			;AC000; signal device

dir_fspec_end:
	pop	si				;AC000; restore position in line
	jmp	short dirscan			;AC000; keep parsing

set_dir_width:
	test	byte ptr[bits],SwitchW		;AN018; /W already set?
	jz	ok_set_width			;AN018; no - okay to set width
	mov	ax,moreargs_ptr 		;AN018; set up too many arguments
	invoke	setup_parse_error_msg		;AN018; set up an error message
	jmp	badparm 			;AN018; exit

ok_set_width:
	or	bits,switchw			;AC000; indicate /w was selected
	mov	linlen,wideperlin		;AC000; Set number of entries per line
	mov	lincnt,wideperlin		;AC000;
	jmp	short dirscan			;AC000; keep parsing

set_dir_pause:
	test	byte ptr[bits],SwitchP		;AN018; /p already set?
	jz	ok_set_pause			;AN018; no - okay to set width
	mov	ax,moreargs_ptr 		;AN018; set up too many arguments
	invoke	setup_parse_error_msg		;AN018; set up an error message
	jmp	badparm 			;AN018; exit

ok_set_pause:
	or	bits,switchp			;AC000; indicate /p was selected
	push	cx				;AN000; save necessary registers
	push	si				;AN000;
	mov	ax,(IOCTL SHL 8) + generic_ioctl_handle ;AN000; get lines per page on display
	mov	bx,stdout			;AN000; lines for stdout
	mov	ch,ioc_sc			;AN000; type is display
	mov	cl,get_generic			;AN000; get information
	mov	dx,offset trangroup:display_ioctl ;AN000;
	int	int_command			;AN000;

lines_set:
	dec	linperpag			;AN000; lines per actual page should
	dec	linperpag			;AN000;     two less than the max
	mov	ax,linperpag			;AN000; get number of lines into
	mov	[fullscr],ax			;AC000;    screen line counter
	pop	si				;AN000; restore registers
	pop	cx				;AN000;
	jmp	dirscan 			;AC000; keep parsing

;
; The syntax is incorrect.  Report only message we can.
;
BadParm:
	jmp	cerror				;AC000; invalid switches get displayed

ScanDone:

;
; Find and display the volume ID on the drive.
;

	invoke	okvolarg			;AC000;
	mov	[filecnt],0			;AC000; Keep track of how many files found
	cmp	comsw,0 			;AC000; did an error occur?
	jnz	doheader			;AC000; yes - don't bother to fix path

	mov	dirflag,-1			;AN015; set pathcrunch called from DIR
	invoke	pathcrunch			;AC000; set up FCB for dir
	mov	dirflag,0			;AN015; reset dirflag
	jc	DirCheckPath			;AC015; no CHDIRs worked.
	jz	doheader			;AC015; chdirs worked - path\*.*
	mov	si,[desttail]			;AN015; get filename back
	jmp	short DoRealParse		;AN015; go parse it

DirCheckPath:
	mov	ax,[msg_numb]			;AN022; get message number
	cmp	ax,0				;AN022; Is there a message?
	jnz	dir_err_setup			;AN022; yes - there's an error
	cmp	[destisdir],0			;AC000; Were pathchars found?
	jz	doparse 			;AC000; no - no problem
	inc	comsw				;AC000; indicate error
	jmp	short doheader			;AC000; go print header

DirNF:
	mov	ax,error_file_not_found 	;AN022; get message number in control block

dir_err_setup:
	mov	msg_disp_class,ext_msg_class	;AN000; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr  ;AC000; get extended message pointer
	mov	extend_buf_ptr,ax		;AN022;

DirError:
	jmp	Cerror

;
; We have changed to something.  We also have a file.  Parse it into a
; reasonable form, leaving drive alone, leaving extention alone and leaving
; filename alone.  We need to special case ...	If we are at the root, the
; parse will fail and it will give us a file not found instead of file not
; found.
;
DoParse:
	mov	si,offset trangroup:srcbuf	;AN000; Get address of source
	cmp	byte ptr [si+1],colon_char	;AN000; Is there a drive?
	jnz	dir_no_drive			;AN000; no - keep going
	lodsw					;AN000; bypass drive

dir_no_drive:
	cmp	[si],".."
	jnz	DoRealParse
	cmp	byte ptr [si+2],0
	jnz	DoRealParse
	inc	ComSw
	jmp	short DoHeader

DoRealParse:
	mov	di,FCB			; where to put the file name
	mov	ax,(Parse_File_Descriptor SHL 8) OR 0EH
	int	int_command

;
; Check to see if APPEND installed.  If it is installed, set all flags
; off.	This will be reset in the HEADFIX routine
;

DoHeader:
	mov	ax,AppendInstall		;AN020; see if append installed
	int	2fh				;AN020;
	cmp	al,0				;AN020; append installed?
	je	DoHeaderCont			;AN020; no - continue
	mov	ax,AppendDOS			;AN020; see if append DOS version right
	int	2fh				;AN020;
	cmp	ax,-1				;AN020; append version correct?
	jne	DoHeaderCont			;AN020; no - continue
	mov	ax,AppendGetState		;AN020; Get the state of Append
	int	2fh				;AN020;
	push	ds				;AN020; save current data segment
	mov	ds,[resseg]			;AN020; get resident segment
	assume	ds:resgroup			;AN020;
	mov	append_state,bx 		;AN020; save append state
	mov	append_flag,-1			;AN020; set append flag
	xor	bx,bx				;AN020; clear out state
	mov	ax,AppendSetState		;AN020; Set the state of Append
	int	2fh				;AN020;     set everything off
	pop	ds				;AN020; save current data segment
	assume	ds:trangroup			;AN020;

;
; Display the header
;

DoHeaderCont:
	mov	al,blank			;AN051; Print out a blank
	invoke	print_char			;AN051;   before DIR header
	invoke	build_dir_string		; get current dir string
	mov	dx,offset trangroup:Dirhead_ptr
	invoke	printf_crlf			; bang!

;
; If there were chars left after parse or device, then invalid file name
;
	cmp	ComSw,0
	jz	DoSearch			; nothing left; good parse
	jl	DirNFFix			; not .. => error file not found
	invoke	RestUDir
	mov	dx,offset TranGroup:BadCD_ptr
	jmp	Cerror				; was .. => error directory not found
DirNFFix:
	invoke	RestUDir
	jmp	DirNF
;
; We are assured that everything is correct.  Let's go and search.  Use
; attributes that will include finding directories.  perform the first search
; and reset our directory afterward.
;
DoSearch:
	mov	byte ptr DS:[FCB-7],0FFH
	mov	byte ptr DS:[FCB-1],010H
;
; Caution!  Since we are using an extended FCB, we will *also* be returning
; the directory information as an extended FCB.  We must bias all fetches into
; DIRBUF by 8 (Extended FCB part + drive)
;
	mov	ah,Dir_Search_First
	mov	dx,FCB-7
	int	int_command

	push	ax				;AN022; save return state
	inc	al				;AN022; did an error occur?
	pop	ax				;AN022; get return state back
	jnz	found_first_file		;AN022; no error - start dir
	invoke	set_ext_error_msg		;AN022; yes - set up error message
	push	dx				;AN022; save message
	invoke	restudir			;AN022; restore user's dir
	pop	dx				;AN022; restore message
	cmp	word ptr Extend_Buf_Ptr,Error_No_More_Files ;AN022; convert no more files to
	jnz	DirCerrorJ			;AN022; 	file not found
	mov	Extend_Buf_Ptr,Error_File_Not_Found  ;AN022;

DirCerrorJ:					;AN022;
	jmp	Cerror				;AN022; exit

;
; Restore the user's directory.  We preserve, though, the return from the
; previous system call for later checking.
;

found_first_file:
	push	ax
	invoke	restudir
	pop	ax
;
; Main scanning loop.  Entry has AL = Search first/next error code.  Test for
; no more.
;
DIRSTART:
	inc	al				; FF = file not found
	jnz	Display
	jmp	DirDone 			; Either an error or we are finished
;
; Note that we've seen a file and display the found file.
;

Display:
	inc	[filecnt]			; Keep track of how many we find
	mov	si,offset trangroup:dirbuf+8	; SI -> information returned by sys call
	call	shoname
;
; If we are displaying in wide mode, do not output the file info
;
	test	byte ptr[bits],SwitchW		; W switch set?
	jz	DirTest
	jmp	nexent				; If so, no size, date, or time

;
; Test for directory.
;
DirTest:
	test	[dirbuf+8].dir_attr,attr_directory
	jz	fileent
;
; We have a directory.	Display the <DIR> field in place of the file size
;
	mov	dx,offset trangroup:Dmes_ptr
	call	std_printf
	jmp	short nofsiz
;
; We have a file.  Display the file size
;
fileent:
	mov	dx,[DirBuf+8].dir_size_l
	mov	file_size_low,dx
	mov	dx,[DirBuf+8].dir_size_h
	mov	file_size_high,dx
	mov	dx,offset trangroup:disp_file_size_ptr
	call	std_printf
;
; Display time and date of last modification
;
nofsiz:
	mov	ax,[DirBuf+8].dir_date		; Get date
;
; If the date is 0, then we have found a 1.x level diskette.  We skip the
; date/time fields as 1.x did not have them.
;
	or	ax,ax
	jz	nexent				; Skip if no date
	mov	bx,ax
	and	ax,1FH				; get day
	mov	dl,al
	mov	ax,bx
	mov	cl,5
	shr	ax,cl				; Align month
	and	al,0FH				; Get month
	mov	dh,al
	mov	cl,bh
	shr	cl,1				; Align year
	xor	ch,ch
	add	cx,80				; Relative 1980
	cmp	cl,100
	jb	millenium
	sub	cl,100

millenium:
	xchg	dh,dl				;AN000; switch month & day
	mov	DirDat_yr,cx			;AC000; put year into message control block
	mov	DirDat_mo_day,dx		;AC000; put month and day into message control block
	mov	cx,[DirBuf+8].dir_time		; Get time
	jcxz	prbuf				; Time field present?
	shr	cx,1
	shr	cx,1
	shr	cx,1
	shr	cl,1
	shr	cl,1				; Hours in CH, minutes in CL
	xchg	ch,cl				;AN000; switch hours & minutes
	mov	DirTim_hr_min,cx		;AC000; put hours and minutes into message subst block

prbuf:
	mov	dx,offset trangroup:DirDatTim_ptr
	call	std_printf
	invoke	crlf2				;AC066;end the line
	dec	byte ptr [fullscr]		;AC066;count the line
	jnz	endif04 			;AN066;IF the last on the screen THEN
	   call    check_for_P			;AN066;   pause if /P requested
	endif04:				;AN066;
	jmp	scroll				; If not, just continue
;AD061; mov	DirDat_yr,0			;AC000; reset year, month and day
;AD061; mov	DirDat_mo_day,0 		;AC000;     in control block
;AD061; mov	DirTim_hr_min,0 		;AC000; reset hour & minute in control block
;
; We are done displaying an entry.  The code between "noexent:" and "scroll:"
; is only for /W case.
;
nexent:
	mov	bl,[lincnt]			;AN066;save for check for first entry on line
	dec	[lincnt]			      ;count this entry on the line
	jnz	else01				;AX066;IF last entry on line THEN
	   mov	   al,[linlen]
	   mov	   [lincnt],al
	   invoke  crlf2
	   cmp	   [fullscr],0			;AC066;IF have filled the screen THEN
	   jnz	   endif02			;AN066;
	      call    check_for_P		;AN066;   reinitialize fullscr,
	   endif02:				;AN066;   IF P requested THEN pause
	   jmp	   short endif01		;AN066;
	else01: 				;AN066;ELSE since screen not full
	   cmp	   bl,[linlen]			;AN066;   IF starting new line THEN
	   jne	   endif03			;	     count the line
	      dec     byte ptr [fullscr]	;AN066;   ENDIF
	   endif03:				;AC066;We are outputting on the same line, between fields, we tab.
	   mov	   dx,offset trangroup:tab_ptr	;Output a tab
	   call    std_printf
	endif01:				;AX066;
;
; All we need to do now is to get the next directory entry.
;
scroll:
	mov	ah,Dir_Search_Next
	mov	dx,FCB-7			; DX -> Unopened FCB
	int	int_command			; Search for a file to match FCB
	jmp	DirStart
;
; If no files have been found, display a not-found message
;
DirDone:
	invoke	get_ext_error_number		;AN022; get the extended error number
	cmp	ax,error_no_more_files		;AN022; was error file not found?
	jnz	dir_err_setup_jmp		;AN022; no - setup error message
	test	[filecnt],-1
	jnz	Trailer
	mov	ax,error_file_not_found 	;AN022;

dir_err_setup_jmp:				;AN022;
	jmp	dir_err_setup			;AN022; go setup error msg & print it
;
; If we have printed the maximum number of files per line, terminate it with
; CRLF.
;
Trailer:
	mov	al,[linlen]
	cmp	al,[lincnt]			; Will be equal if just had CR/LF
	jz	mmessage
	invoke	crlf2
	cmp	[fullscr],0			;AN066;IF on last line of screen THEN
	jnz	endif06 			;AN066;   pause before going on
	   call    check_for_P			;AN066;   to number and freespace
	endif06:				;AN066;   displays

mmessage:
	mov	dx,offset trangroup:Dirmes_ptr
	mov	si,[filecnt]
	mov	dir_num,si
	call	std_printf
	mov	ah,Get_Drive_Freespace
	mov	dl,byte ptr DS:[FCB]
	int	int_command
	cmp	ax,-1
	retz
	mul	cx				; AX is bytes per cluster
	mul	bx
	mov	bytes_free,ax			;AC000;
	mov	bytes_free+2,dx 		;AC000;
	MOV	DX,OFFSET TRANGROUP:BYTMES_ptr
	jmp	std_printf

shoname:
	mov	di,offset trangroup:charbuf
	mov	cx,8
	rep	movsb
	mov	al,' '
	stosb
	mov	cx,3
	rep	movsb
	xor	ax,ax
	stosb
	push	dx
	mov	dx,offset trangroup:charbuf
	mov	string_ptr_2,dx
	mov	dx,offset trangroup:string_buf_ptr
	call	std_printf
	pop	DX
	return

check_for_P    PROC  NEAR			;AN066;

test	byte ptr[bits],SwitchP	     ;P switch present?
jz	endif05 				;AN066;
   mov	   ax,linperpag 		   ;AN000;  transfer lines per page
   mov	   [fullscr],ax 		   ;AC000;	to fullscr
   invoke  Pause
endif05:
ret						;AN066;

check_for_P    ENDP				;AN066;

trancode    ends
	    end
