	PAGE	,132			;
	title	COMP2.SAL - COMPARES FILES
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: COMP2.ASM
;
; DESCRIPTIVE NAME: Compare two files to show they are identical or not.
;
; FUNCTION:  The paths and names of each pair of files is
;	 displayed as the comparing process proceeds.  An
;	 error message will follow the names if:
;	     (1) a file matching the second filename can't be found,
;	     (2) the files are different sizes,
;	     (3) either path is invalid, or.
;	     (4) CHCP=Yes (CODE PAGE active) and code page of files
;		do not match.
;
;	 During the comparison, an error message will appear for any
;	 location that contains mismatching information in the 2
;	 files.  The message indicates the offset into the files of
;	 the mismatching bytes, and the contents of the 2 bytes
;	 themselves (all in hex).  This will occur for up to 10
;	 mismatching bytes - if more than 10 compare errors are
;	 found, the program assumes that further comparison would be
;	 useless, and ends its compare of the 2 files at that point.
;
;	 If all bytes in the 2 files match, a "Files compare OK"
;	 message will appear.
;
;	 In all cases, after the comparing of 2 files ends, comparing
;	 will proceed with the next pair of files that match the 2
;	 filenames, until no more files can be found that match the
;	 first filename.  You are then asked if you want to compare
;	 any more files.  Replying "N" returns you to the DOS prompt
;	 (such as A>); a reply of "Y" results in prompts for new
;	 primary and secondary filenames.
;
;	 In all compares, COMP looks at the last byte of one of the
;	 files being compared to assure that it contains a valid
;	 end-of-file mark (CTRL-Z, which is the hex character 1A).
;	 If found, no action is taken by COMP.	If the end-of-file
;	 mark is NOT found, COMP produces the message "EOF mark not
;	 found".  This is done because some products produce files
;	 whose sizes are always recorded in the directory as a
;	 multiple of 128 bytes, even though the actual usable data in
;	 the file will usually be a few bytes less than the directory
;	 size.	In this case, COMP may produce "Compare error"
;	 messages when comparing the few bytes beyond the last real
;	 data byte in the last block of 128 bytes (COMP always
;	 compares the number of bytes reflected in the directory).
;	 Thus, the "EOF mark not found" message indicates that the
;	 compare errors may not have occurred in the usable data
;	 portion of the file.
;
;	 Multiple compare operations may be performed with one load
;	 of COMP.  A prompt, "Compare more files (Y/N)?" permits additional
;	 executions.
;
; ENTRY POINT: "INIT", jumped to by COMP1 at the DOS entry point.
;
; INPUT: (DOS command line parameters)
;	[d:][path] COMP [d:][path][filenam1[.ext]] [d:][path][filenam2[.ext]]
;
;	 Where
;	 [d:][path] before COMP to specify the drive and path that
;		    contains the COMP command file.
;
;	 [d:][path][filenam1[.ext]] -  to specify the FIRST (or primary)
;		    file or group of files to be compared
;
;	 [d:][path][filenam2[.ext]]  - to specify the SECOND file or group
;		    of files to be compared with the corresponding file
;		    from the FIRST group
;
;	 Global filename characters are allowed in both filenames,
;	 and will cause all of the files matching the first filename
;	 to be compared with the corresponding files from the second
;	 filename.  Thus, entering COMP A:*.ASM B:*.BAK will cause
;	 each file from drive A:  that has an extension of .ASM to be
;	 compared with a file of the same name (but with an extension
;	 of .BAK) from drive B:.
;
;	 If you enter only a drive specification, COMP will assume
;	 all files in the current directory of the specified drive.
;	 If you enter a path without a filename, COMP assumes all
;	 files in the specified directory.  Thus, COMP A:\LEVEL1
;	 B:\LEVEL2 will compare all files in directory A:\LEVEL1 with
;	 the files of the same names in directory B:\LEVEL2.
;
;	 If no parameters are entered with the COMP command, you will
;	 be prompted for both.	If the second parm is omitted, COMP
;	 will prompt for it.  If you simply press ENTER when prompted
;	 for the second filename, COMP assumes *.* (all files
;	 matching the primary filename), and will use the current
;	 directory of the default drive.
;
;	 If no file matches the primary filename, COMP will prompt
;	 again for both parameters.
;
; EXIT-NORMAL: Errorlevel = 0, Function completed successfully.
;
; EXIT-ERROR: Errorlevel = 1, Abnormal termination due to error, wrong DOS,
;	      invalid parameters, unrecoverable I/O errors on the diskette.
;
; EFFECTS: Files are not altered.  A Message will show result of compare.
;
; INTERNAL REFERENCES:
;    ROUTINES:
;	SENDMSG - passes parms to regs and invokes the system message routine.
;	EXTERR - get extended error and display message.
;	INIT_CP - record chcp switch then turn off. Allows COMP to open first
;		  or second file regardless of the system code page.
;	RESTORE_CP - resets the chcp switch to the initial value.
;	COMP_CODEPAGE - verify matching code pages.
;	GET_CP - do an extended open, get code page, then close.
;
;    DATA AREAS:
;	WORKAREA - Temporary storage
;
; EXTERNAL REFERENCES:
;    ROUTINES:
;	SYSDISPMSG - Uses the MSG parm lists to construct the messages
;		 on STDOUT.
;	SYSLOADMSG - Loads messages, makes them accessable.
;	SYSPARSE - Processes the DOS Command line, finds parms.
;
;    DATA AREAS:
;	 PSP - Contains the DOS command line parameters.
;	 COMPSM.SAL - Defines the control blocks that describe the messages
;	 COMPPAR.SAL - Defines the control blocks that describe the
;		DOS Command line parameters.
;
; NOTES:
;	 This module should be processed with the SALUT preprocessor
;	 with the re-alignment not requested, as:
;
;		SALUT COMP2,NUL
;
;	 To assemble these modules, the alphabetical or sequential
;	 ordering of segments may be used.
;
;	 For LINK information, reference Prolog of COMP1.SAL.
;
; COPYRIGHT: The following notice is found in the OBJ code generated from
;	     the "COMPSM.SAL" module:
;
;	     "The DOS COMP Utility"
;	     "Version 4.0  (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Property of Microsoft"
;
; Modification History:
;
;   Version   Author	       date	 comment
;   -------   ------	       ----	 -------
;   V0.0      Dave L.			 Original author
;
;   V3.3      Russ W.
;
;   V4.0      Edwin M. K.		 ;AN000; Extended attribute support,
;	      Bill L.	     7/10/87	 parser, message retriever support
;
;   V4.0      Bill L.	     9/17/87	 ;AN001; - DCR 201 enhancements to the
;					 extended attribute support
;
;   V4.0      Bill L.			 ;AN002; - PTM 708
;					 ;AN003; - PTM 728
;					 ;AN004; - PTM 1610
;					 ;AN005; - PTM 274
;					 ;AN006; - PTM 2205 (DBCS support)
;					 ;AN007; - PTM 3056 (y/n -> STDERR)
;					 ;AN008; -	    optimizations
;					 ;AN009; - PTM 4076 network hang
;
;****************** END OF SPECIFICATIONS *****************************
	page

	if1
	    %OUT    COMPONENT=COMP, MODULE=COMP2.SAL
	endif

;***********************************
; Macro definitions
;***********************************

fill_name1 macro pfcb			;AN000;
	push	dx			;AN000;
	push	di			;AN000;
	push	si			;AN000;
	mov	dx,offset name1 	;AN000;
	mov	si,offset path1 	;AN000;
	mov	di,offset pfcb		;AN000;
	call	fill_n			;AN000;
	pop	si			;AN000;
	pop	di			;AN000;
	pop	dx			;AN000;
	endm				;AN000;

fill_name2 macro			;AN000;
	push	dx			;AN000;
	push	di			;AN000;
	push	si			;AN000;
	mov	dx,offset name2 	;AN000;
	mov	si,offset path2 	;AN000;
	mov	di,offset outfcb	;AN000;
	call	fill_n			;AN000;
	pop	si			;AN000;
	pop	di			;AN000;
	pop	dx			;AN000;
	endm				;AN000;

print_msg macro msg,handle		;AC003;
	push	ax			;AN000;
	mov	dx,offset msg		;AN000; ;dx: ptr to msg descriptor
	ifnb	<handle>		;AN003; ;check if new handle given
	    push    di			;AN003; ;put new handle in msg structure
	    mov     di,dx		;AN003;
	    mov     [di].msg_handle,handle ;AN003;
	    pop     di			;AN003;
	endif				;AN003;
	call	sendmsg 		;AC000;
	pop	ax			;AN000;
	endm				;AN000;

doscall macro	func,subfunc		;AN000;
	ifnb	<func>			;AN000; ;are there any parms at all ?
	    ifnb    <subfunc>		;AN000; ;is there a sub-function ?
		mov	ax,(func shl 8)+subfunc ;AN000; ;yes, ah=func, al=subfunc
	    else			;AN000; ;no sub-function
		mov	ah,func 	;AN000;
	    endif			;AN000;
	endif				;AN000;
	int	21h			;AN000;
	endm				;AN000;

;***********************************
; Include equates
;***********************************

	include compeq.inc		;AN000; ;include some equates

;***********************************
; Extended attribute structures
;***********************************

ea	struc				;AN001; ;extended attr. structure
ea_type db	EAISBINARY		;AN001;
ea_flags dw	EASYSTEM		;AN001;
ea_rc	db	?			;AN001;
ea_namelen db	2			;AN001;
ea_vallen dw	2			;AN001;
ea_name db	"CP"			;AN001;
ea_value dw	?			;AN001;
ea	ends				;AN001;

qea	struc				;AN001; ;query extended attr. name
qea_type db	EAISBINARY		;AN001;
qea_flags dw	EASYSTEM		;AN001;
qea_namelen db	2			;AN001;
qea_name db	"CP"			;AN001;
qea	ends				;AN001;

;***********************************
; Code Segment
;***********************************

cseg	segment para public 'CODE'	;AC000;
	assume	cs:cseg,ds:cseg,es:cseg,ss:cseg ;as set by DOS loader

	extrn	parser:near		;AN000;
	extrn	sysloadmsg:near 	;AN000;
	extrn	sysdispmsg:near 	;AN000;
	extrn	memory_size:word
	extrn	fcb:byte
	extrn	parms:word		;AN000;
	extrn	parm_area:byte
	extrn	parm_count:word 	;AN000;
	extrn	current_parm:word	;AN000;
	extrn	ordinal:word		;AN000;
	extrn	msgnum_mem:word 	;AN000;
	extrn	msgnum_para:word	;AN000;
	extrn	msgnum_tenmsg:word	;AN000;
	extrn	msgnum_baddrv:word	;AN000;
	extrn	msgnum_bad:word 	;AN000;
	extrn	msgnum_adr:word 	;AN000;
	extrn	msgnum_bdr:word 	;AN000;
	extrn	msgnum_eor:word 	;AN000;
	extrn	msgnum_done:word	;AN000;
	extrn	msgnum_fnf:word 	;AN000;
	extrn	msgnum_bad_path:word	;AN000;
	extrn	msgnum_share:word	;AN000;
	extrn	msgnum_too_many:word	;AN000;
	extrn	msgnum_prinam:word	;AN000;
	extrn	msgnum_secnam:word	;AN000;
	extrn	msgnum_badsiz:word	;AN000;
	extrn	msgnum_nother:word	;AN000;
	extrn	msgnum_and_msg:word	;AN000;
	extrn	msgnum_crlf:word	;AN000;
	extrn	msgnum_accessdenied:word ;AN000;
	extrn	msgnum_cp_mismatch:word ;AN000;
	extrn	msgnum_ok:word		;AN000;
	extrn	msgnum_exterr:word	;AN000;
	extrn	msgnum_pparse:word	 ;AN000;
	extrn	sublist_6:word		;AN000;
	extrn	sublist_7:word		;AN000;
	extrn	sublist_8:word		;AN000;
	extrn	sublist_11:word 	;AN000;
	extrn	sublist_12:word 	;AN000;
	extrn	sublist_13:word 	;AN000;
	extrn	sublist_19a:word	;AN000;
	extrn	sublist_19b:word	;AN000;
	extrn	sublist_21:word 	;AN000;
	extrn	sublist_exterr:word	;AN000;
	extrn	sublist_24:word 	;AN000;

;***********************************
; Data area in code segment
;***********************************

	public	path1			;AN000;
	public	path2			;AN000;
	public	name1			;AN000;
	public	name2			;AN000;
	public	cur_name		;AN000;
	public	exitfl			;AN000;

	even				;AN000; ;align stack on word boundary

stack_area db	512 dup ("S")		;Added in DOS 3.20 to support hardware requiring
End_Stack_Area db 00h			;large stacks. DO NOT PUT DATA ABOVE THIS !

clear	db	00h			;AN000; ;clear path2
cur_name dw	00h			;AN000; ;ptr to current filename
input_buf db	130 dup (0)		;AN000; ;input buffer for keyb input
name1	db	130 dup (0)		;AN000; ;source file name
name2	db	130 dup (0)		;AN000; ;target file name
byte1	db	00h			;AN000; ;on compare: bad byte for source
byte2	db	00h			;AN000; ;on compare: bad byte for target
fcb2	db	16 dup (0)		;entered target filespec
;--------KEEP NEXT VARIABLes IN ORIGINAL ORDER-------------
oldp1	db	67 dup (0)		;original path for the first drive    1 KEEP IN ORDER
path1	db	130 dup (0)		;path we'll use for the first drive   2
infcb	db	37 dup (0)		;source fcb			      3
oldp2	db	67 dup (0)		;original path for second drive       4
path2	db	130 dup (0)		;path we'll use for second drive      5
outfcb	db	37 dup (0)		;target fcb			      6
;--------KEEP ABOVE VARIABLes IN ORIGINAL ORDER------------
sav	db	2 dup (0)
mem	db	2 dup (0)		;size of large buffer in bytes
curfcb	db	4 dup (0)		;first 2 bytes = addr of fcb for large buffer,
					;last 2 bytes = addr of fcb for small buffer
curpos	dw	00h			;current byte offset in large buffer
buf2	dw	00h			;seg address of large buffer
siz	dw	512			;# bytes of data left to compare in large buffer
swt	db	00h			;Bit switch:
					; 1   = read file to eof
					; 4   = had compare error
					; 8   = eof mark not found
					; 16  = secondary dir path has been found
					; 32  = primary file opened
					; 64  = secondary file opened
					; 128 = zero suppress switch
swt2	db	00h			;Bit switch:
					; 1 = oldp1 setup
					; 2 = oldp2 setup
offs	db	00h,00h,00h,00h 	;count of bytes compared
cnt	db	00h			;# of bad compares
offp	db	8 dup(0)		;AC000; ;offset of mis-compare between bytes
off_byte db	8 dup (0)		;AN000; ;same as offp, but the words are reversed
curdrv	db	00h			;actual number of default drive
cdrv	db	" :"			;ascii letter of default drive
pathchar db	"\",00h
tbl	db	"0123456789ABCDEF"
openpath db	15 dup (0)		;An fcb will be parsed into this path.
cpsw_orig db	00h			;AN000; ;save original cpsw value
exitfl	db	EXOK			;AN000; ;errorlevel return code
handle	dw	00h			;AN000;

dbcs_off dw	0			;AN006;
dbcs_seg dw	0			;AN006;
dbcs_len dw	0			;AN006;
string_off dw	0			;AN006;
string_seg dw	0			;AN006;
dstring db	128 dup(0)		;AN006;

parm_list label word			;AN001;
	dd	-1			;AN001;
	dw	1			;AN001;
	db	6			;AN001;
	dw	2			;AN001;

querylist label byte			;AN001; ;query general list
	dw	1			;AN001; ;# of entries
querylist_qea qea <EAISBINARY,EASYSTEM,2,"CP"> ;AN001;

qlist	label	byte			;AN001; ;general get/set list
	dw	1			;AN001; ;count of attr entries
qlist_ea ea	<EAISBINARY,EASYSTEM,?,2,2,"CP",?> ;AN001; ;return code page in this structure

;***********************************
; Code area in code segment
;***********************************


;-----------------------------------------------------------------------------
; INIT - Fill in fill_seg, fill_off in all msg sublists with current seg_id
;	 and offset. Also calls the system load massage function so it can
;	 establish addressability to the system messages, and for it to verify
;	 the DOS version
;-----------------------------------------------------------------------------
init	proc	near			;AC000;
	public	init			;AN000;

	mov	sp,offset End_Stack_Area ;Big Stack
	push	ax			;AN000; ;on entry--ax (should) = valid drive parm
	call	setfill 		;AN000; ;init fill_seg, fill_off in sublists
	call	sysloadmsg		;AN000; ;init sysmsg handler

;	$if	c			;AN000; ;if there was a problem
	JNC $$IF1
	    call    sysdispmsg		;AN000; ;let him say why we had a problem
	    mov     exitfl,EXVER	;AN000; ;tell errorlevel bad DOS version
;	$else				;AN000; ;since sysdispmsg is happy
	JMP SHORT $$EN1
$$IF1:
	    call    get_dbcs_vector	;AN006; ;get DOS DBCS table vector
;;(deleted for AN009)		 call	 init_cp	     ;AN000; ;get current setting of CHCP
	    pop     ax			;AN000; ;restore valid drive parm
	    call    more_init		;AN000; ;do more init
	    call    main		;AN000; ;do rest of utility as normal
;;(deleted for AN009)		 call	 restore_cp	     ;AN000; ;set CHCP back to normal
;	$endif				;AN000; ;ok with sysdispmsg?
$$EN1:
	mov	al,exitfl		;AN000; ;pass back errorlevel ret code
	doscall RET_FN			;AN000; ;return to DOS with ret code
	int	20h			;AN000; ;if above not work,
					;AN000; ;take stick and kill it
init	endp				;AN000;


;------------------------------------------------------------------------------
; MAIN - Does the compare for two sets of files
;------------------------------------------------------------------------------
;
main	proc	near			;AN000;
	public	main			;AN000;

	mov	clear,0 		;clear it
;	$do				;AN000;
$$DO4:
	    cmp     byte ptr path1,0	;was first parm given?
;	$leave	ne			;AN000; ;Yes, LEAVE INPUT loop
	JNE $$EN4
	    mov     byte ptr path2,0	;AN000; ;make sure that we get the second file name
rpt:
	    mov     dx,offset msgnum_prinam ;AC000; ;to ask user for first parm
	    mov     parm_count,FIRST_PARM_CT ;AN000; ;THIS IS FIRST PARM (ONLY ONE ACTUALLY)
	    call    getnam		;get first parm from user in  path1  and  fcb
	    mov     di,offset fcb	;AN000; ;es:di=ptr TO UNOPENED fcb
	    mov     si,offset path1	;AN000; ;ds:si=ptr TO COMMAND LINE TO PARSE
					;AN000; ;AL-BIT VALUE CONTROLS PARsiNG
	    doscall PARSE_FILENAME,01H	;AN000; ;AND GO MAKE AN fcb, SCAN OFF LEAdiNG SEPARATORS
	    cmp     AL,255		;AN000; ;INVALID DRIVE?
;	    $if     e			;AN000; ;Yes
	    JNE $$IF6
		print_msg msgnum_baddrv,STDERR ;AN000; ;"Invalid drive spec."
		mov	byte ptr path1,00 ;AN000; ;BLANK FIRST CHAR. SO TO loop AGAIN
;	    $endif			;AN000;
$$IF6:
;	$enddo				;AC000; ;REPEAT UNTIL FIRST PARM OK
	JMP SHORT $$DO4
$$EN4:

;chek2: 				;GET/SET SECOND FILENAME
	cmp	clear,1
;	$if	e
	JNE $$IF9
	    mov     byte ptr path2,0
	    mov     clear,0
;	$endif
$$IF9:
;	$do				;AN000;
$$DO11:
	    cmp     byte ptr path2,0	;was second parm given?
;	$leave	ne			;AN000; ;Yes, LEAVE INPUT loop
	JNE $$EN11
	    mov     dx,offset msgnum_secnam ;AC000; ;to ask for second parm
	    mov     parm_count,TRICK_PARM_CT ;AN000; ;THIS IS FIRST PARM (ONLY ONE ACTUALLY)
					;AN000; ;BUT PUT FILENAME IN path2 INSTEAD OF path1
	    call    getnam		;get second parm in path2 and fcb2
	    mov     di,offset fcb2	;AN000; ;es:di=ptr TO UNOPENED fcb
	    mov     si,offset path2	;AN000; ;ds:si=ptr TO COMMAND LINE TO PARSE
					;AN000; ;AL-BIT VALUE CONTROLS PARsiNG
	    doscall PARSE_FILENAME,01H	;AN000; ;AND GO MAKE AN fcb, SCAN OFF LEAdiNG SEPARATORS
	    cmp     AL,255		;AN000; ;INVALID DRIVE?
;	    $if     e			;AN000; ;Yes
	    JNE $$IF13
		print_msg msgnum_baddrv,STDERR ;AN000; ;"Invalid drive spec."
		mov	byte ptr path2, 00 ;AN000; ;BLANK FIRST CHAR. SO TO loop AGAIN
;	    $endif			;AN000;
$$IF13:
;	$enddo				;AC000; ;SECOND PARM?
	JMP SHORT $$DO11
$$EN11:
	mov	si,offset path1 	;AN000; ;si = ptr TO PATH NAME TO FIND "\" IN
	call	findfs			;AN000; ;FIND LAST "\" AND SAVE ADDR
	mov	si,offset path2 	;AN000; ;si = ptr TO PATH NAME TO FIND "\" IN
	call	findfs			;AN000; ;FIND LAST "\" AND SAVE ADDR
	mov	al,curdrv		;get default drive
	cmp	byte ptr fcb,0		;source on default?
;	$if	e			;AC000; ;Yes
	JNE $$IF16
	    mov     fcb,al		;yes, set to actual drive
;	$endif				;AC000;
$$IF16:
	cmp	byte ptr fcb2,0 	;target on default?
;	$if	e			;AC000; ;Yes
	JNE $$IF18
	    mov     fcb2,al		;yes, set to actual drive
;	$endif				;AC000; ;***** FIND PRI FILE
$$IF18:
	mov	si,offset path1
	mov	di,offset fcb
	call	findpath		;locate primary's specified dir
;	$if	ne			;AC000;
	JE $$IF20
	    fill_name1 fcb		;AN000; ;get full path name
	    mov     sublist_12.sub_value,offset name1 ;AN000; ;SET UP %1 IN sublist OF "Invalid path - %0:
	    mov     dx,offset msgnum_bad_path ;AC000; ;dx = ptr TO MSG DesCRIPTOR TO dispLAY
					;AN000; ;VALUE IN di,si,dx PAssED TO BADFIL CODE
	    jmp     badfil		;dir not found - tell user
;	$endif				;AC000;
$$IF20:
	mov	dx,offset infcb
	doscall SETDTA			;AC000; ;diR FOUND, SET DTA TO SOURCE fcb
	mov	dx,di			;fcb
	doscall SEARCHF 		;AC000; SEARCH FIRST SOURCE FILE
	or	al,al			;find one?
;	$if	nz			;AC000; ;Yes
	JZ $$IF22
	    fill_name1 fcb		;AN000; ;get full path name
	    mov     sublist_11.sub_value,offset name1 ;AN000; ;SET UP %1 IN sublist OF "File not found - %0"
	    mov     dx,offset msgnum_fnf ;AC000; ;dx = ptr TO MSG DesCRIPTOR TO dispLAY
					;AN000; ;VALUE IN di,si,dx PAssED TO BADFIL CODE
	    jmp     badfil
;	$endif				;AC000;
$$IF22:
f1ok:					;OPEN, PRIME PRIMARY FILE
	and	swt,09Fh		;clear file open flags
	mov	dx,offset infcb
	doscall FCBOPEN 		;AC000; OPEN SOURCE FILE
	or	al,al			;Error ?

					;Try to open the same file using a handle open with read access
;	$if	nz			;AC000; ;IF fcb OPEN FAILED, THEN SHARING ERROR
	JZ $$IF24
	    jmp     shrerr
;	$endif				;AC000;
$$IF24:
	mov	si,offset infcb 	;Take this fcb...
	mov	di,offset OpenPath	; and in this area...
	call	MakePathFromfcb 	; make an ASCIIZ path.
	mov	dx,offset OpenPath
	doscall HANDLEOPEN,READONLYACCESS ;AC000; TRY TO OPEN IT WITH READONLY ACCEss
;	$if	c			;AC000;
	JNC $$IF26
	    jmp     accessdenied1	;ERROR OPENING FILE. AssUME ACCEss DENIED.
;	$endif				;AC000;
$$IF26:
	mov	bx,ax			;Put the handle in bx...
	doscall HANDLECLOSE		;AC000; AND CLOSE IT
	cmp	byte ptr path1,0	;using current dir?
;	$if	ne			;AC000; ;NO
	JE $$IF28
	    mov     dx,offset oldp1
	    doscall CHDIR		;AN000; change directory
;	$endif				;AC000;
$$IF28:
;p1ok:
	mov	word ptr infcb+14,1	;set record size
	xor	ax,ax
	mov	di,offset infcb+33
	stosw				;set rr fields
	stosw
	Mov	dx,offset infcb
	call	get			;and prime big buffer from first file
	print_msg msgnum_crlf,STDOUT	;AN000; ;dispLAY CRLF
	print_msg msgnum_crlf,STDOUT	;AN000; ;dispLAY CRLF
	fill_name1 infcb		;AN000; ;get full path name
	mov	sublist_19a.sub_value,offset name1 ;AN000; ;SET UP %1 IN sublist FOR "%1 AND %2" MSG
	mov	al,fcb2 		;target drive
	mov	outfcb,al		;to target fcb

					;****** FIND SECONDARY diR
	mov	si,offset path2
	test	byte ptr swt,16 	;has secondary path already been found?
;	$if	z			;AC000; ;NO
	JNZ $$IF30
	    mov     di,offset fcb2
	    call    findpath		;no, find its path now
;	$else				;AC000; ;siNCE SECONDARY PATH ALREADY BEEN FOUND
	JMP SHORT $$EN30
$$IF30:
	    cmp     byte ptr [si],0	;is there a path?
;	    $if     ne			;AC000; ;Yes
	    JE $$IF32
					; BUT IF NOT, WILL USE CURRENT DIR
		mov	dx,si
		doscall CHDIR		;AC000; ;yes, set the secondary dir to proper node

		cmp	al,al		;force eq
;	    $endif			;AC000;
$$IF32:
;	$endif				;AC000;
$$EN30:
	pushf				;save status of secondary dir search
	mov	cx,11
	mov	di,offset outfcb+1	;target filename field
	mov	si,offset fcb2+1	;current target filename
	mov	bx,offset infcb+1	;current source filename
;	$do				;AC000;
$$DO35:
	    lodsb			;get target name char
	    cmp     al,"?"		;is it ambiguous?
;	    $if     E			;AC000; ;Yes
	    JNE $$IF36
		mov	al,[bx] 	;yes, copy char from source
;	    $endif			;AC000;
$$IF36:
	    stosb			;build target name
	    inc     bx			;next source char
;	$enddo	loop			;AC000;
	LOOP $$DO35
	fill_name2			;AN000; ;get full path name
	mov	sublist_19b.sub_value,offset name2 ;AN000; ;SET UP %2 IN sublist FOR "%1 AND %2" MSG
	print_msg msgnum_and_msg,STDOUT ;AN000; ;dispLAY " AND "
	print_msg msgnum_crlf,STDOUT	;AN000; ;dispLAY CRLF
	popf				;return from getting secondary dir
;	$if	ne			;AC000; ;diD NOT GET IT
	JE $$IF39
	    fill_name2			;AN000; ;get full path name
	    mov     sublist_12.sub_value,offset name2 ;AN000; ;SET UP %1 IN sublist FOR "%1 - INVALID PATH" ;AN000;
	    print_msg msgnum_bad_path,STDERR ;AN000; ;"Invalid path - %0"
	    mov     dx,offset oldp2	;Get back to current dir on sec drive
	    doscall CHDIR		;AC000;
	    jmp     quit5

;	$endif				;AC000;
$$IF39:
	mov	dx,offset outfcb
	doscall SETDTA			;AC000; diR FOUND, SET DTA TO TARGET fcb
	mov	dx,offset outfcb
	doscall SEARCHF 		;AC000; FIND FIRST TARGET FILE
	or	al,al			;Find one?
;	$if	NZ			;AC000; ;Yes
	JZ $$IF41
	    print_msg msgnum_crlf,STDERR ;AN000; ;dispLAY CRLF
	    fill_name2			;AN000; ;get full path name
	    mov     sublist_11.sub_value,offset name2 ;AN000; ;SET UP %1 IN sublist OF MSG
	    print_msg msgnum_fnf,STDERR ;AN000; ;"File not found - %0"
	    mov     dx,offset oldp2	;Get back to current dir on sec drive
	    doscall CHDIR		;AC000;
	    jmp     quit3		;and get the next source file

;	$endif				;AC000;
$$IF41:
	mov	dx,offset outfcb
	doscall FCBOPEN 		;AC000; OPEN TARGET FILE
	or	al,al			;Was the fcb open ok?

	jnz	ShrViolation		;If fcb open failed, then SHARING ERROR
	mov	si,offset outfcb	;Take this fcb...
	mov	di,offset OpenPath	; and in this area...
	call	MakePathFromfcb 	; make an ASCIIZ path.
	mov	dx,offset OpenPath
	doscall HANDLEOPEN,READONLYACCESS ;AC000; TRY TO OPEN IT WITH READONLY ACCEss
	jc	accessdenied2
	mov	bx,ax			;Put the handle in bx...
	doscall HANDLECLOSE		;AC000; AND CLOSE IT.
	call	RestoreDir
	jmp	filopn			;If successful then continue
accessdenied2:				;Oops, there was an error. AssUME it was Access Denied
	call	RestoreDir
	print_msg msgnum_crlf,STDERR	;AN000; ;dispLAY CRLF
	fill_name2			;AN000; ;get full path name
	mov	sublist_21.sub_value,offset name2 ;AN000; ;SET UP %1 IN sublist OF "Access Denied - %0"
	mov	dx,offset oldp2 	;Get back to current dir on sec drive
	doscall CHDIR			;AC000;
	print_msg msgnum_accessdenied,STDERR ;AN000; ;"Access Denied - %0"
	jmp	quit3			;and get the next source file

ShrViolation:
	call	RestoreDir
	print_msg msgnum_crlf,STDERR	;AN000; ;dispLAY CRLF
	fill_name2			;AN000; ;get full path name
	mov	sublist_13.sub_value,offset name2 ;AN000; ;SET UP %1 IN sublist OF "Sharing violation - %0"
	mov	dx,offset oldp2 	;Get back to current dir on sec drive
	doscall CHDIR			;AC000;
	print_msg msgnum_share,STDERR	;AN000; ;"Sharing violation - %0"
	jmp	quit3			;and get the next source file
filopn:
	mov	word ptr outfcb+14,1	;record size
	xor	ax,ax
	mov	di,offset outfcb+33
	stosw
	stosw
	mov	ax,word ptr infcb+16	;low part of file size
	mov	dx,word ptr infcb+18	;high part
	cmp	ax,word ptr outfcb+16	;are files the same size?
	jne	invsiz			;no, error
	cmp	dx,word ptr outfcb+18
	je	sizok			;yes, ok
invsiz:
	print_msg msgnum_badsiz,STDOUT	;AN000; ;"Files are different sizes"
	jmp	quit3			;tell user sizes are different and process next source file
sizok:
;;(deleted for AN009)	     call    comp_codepage	     ;AN000; ;VERIFY BOTH FILes HAVE THE SAME CODEPAGE
;;(deleted for AN009)	     $if     c			     ;AN000; ;ERROR WITH CODEPAGE
;;(deleted for AN009)		 jmp	 quit3		     ;AN000; ;go on to other files if any
;;(deleted for AN009)	     $endif			     ;AN000;
	mov	dx,offset infcb
	mov	word ptr curfcb,dx	;get fcb's in proper order
	mov	dx,offset outfcb
	mov	word ptr curfcb+2,dx
	mov	word ptr offs,0 	;set constants
	mov	word ptr offs+2,0
	mov	byte ptr cnt,0		;and fall through to process
process:				;**** PREPARE TO COMPARE DATA
	mov	dx,word ptr curfcb+2	;small buffer's file
	cmp	word ptr siz,0		;any data left in large buffer?
	jne	getsec			;yes, use it
	test	byte ptr swt,1		;no, have we reached eof yet?
	jz	large			;no - fill large buffer from other file
	doscall FCBCLOSE		;AC000; CLOSE THE FILE FILLING SMALL BUFFER
	test	byte ptr swt,8		;yes, files are done - did we find eof mark?
;	$if	z			;AC000; ;NO
	JNZ $$IF43
	    print_msg msgnum_eor,STDOUT ;AN000; ;"Eof mark not found"
;	$endif				;AC000;
$$IF43:
	test	byte ptr swt,4		;any compare errors?
;	$if	Z			;AC000;
	JNZ $$IF45
	    print_msg msgnum_ok,STDOUT	;AN000; ;"FILes COMPARE OK"
;	$endif				;AC000;
$$IF45:
	jmp	quit3			;had compare errors - no "ok" msg

large:					;Fill large buffer
	xchg	dx,word ptr curfcb	;AC000; ;switch fcbs' association with buffers
	xchg	dx,word ptr curfcb+2
	call	get			;fill large buffer from currently mounted file
	jmp	process 		;and now fill small buffer from other file
getsec:
	call	getf2			;fill small buffer with 1024 bytes
	sub	siz,cx			;# bytes left in big buffer after this compare
	mov	bp,cx			;save # bytes of compare
	les	di,dword ptr curpos	;current byte in large buffer
	mov	si,offset buf		;current byte in small buffer
comp:
	jcxz	compok			;all done and equal
	repe	cmpsb
	jne	cmp1			;bytes don't match
compok:
	push	ds
	pop	es			;get es back
	mov	curpos,di		;next byte to compare in large buffer
	mov	ax,word ptr offs+2	;low part of bytes compared so far
	add	ax,bp			;increment count of bytes compared
	adc	word ptr offs,0 	;adjust high part
	mov	word ptr offs+2,ax	;save low part
	jmp	process 		;and keep going
cmp1:					;***** FOUND UNEQUAL BYTes
	or	byte ptr swt,4		;indicate had compare error
	dec	si			;point to the bad bytes
	dec	di
	mov	al,[si] 		;bad byte from small buffer
	mov	ah,es:[di]		;bad byte from large buffer
	mov	dx,offset infcb 	;AC000; ;FIND OUT WHICH byte CAME FROM WHICH FILE
					;AN000; ;SO THAT "File 1 = %1" AND "File 2 = %1"
					;AN000; ;MEssAGes WILL BE CORRECT.
	cmp	word ptr curfcb+2,dx	;is first file in small buffer?
;	$if	ne			;AC000; ;NO
	JE $$IF47
	    xchg    ah,al		;no, reverse the bad bytes
;	$endif				;AC000;
$$IF47:
	mov	byte1,al		;AN000; ;SAVE FIRST FILE BAD byte
	mov	byte2,ah		;AN000; ;SAVE SECOND FILE BAD byte
					;AN000; ;COMPUTE offset IN FILE OF BAD BYTes
	mov	bx,word ptr offs	;high part of byte count
	mov	ax,si			;addr of the bad byte in small buffer
	sub	ax,offset buf		;bad byte's offset in this buffer
	add	ax,word ptr offs+2	;offset into file
	adc	bx,0			;adjust high part if needed
	mov	word ptr offp,bx	;AC000; ;SAVE HIGH PART OF offset
	mov	word ptr off_byte+2,bx	;AN000; ;SAVE HIGH PART OF offset
	mov	word ptr offp+2,ax	;AN000; ;SAVE LOW PART OF offset
	mov	word ptr  off_byte,ax	;AN000; ;SAVE LOW PART OF offset
	inc	si			;back to correct position
	inc	di
	push	cx			;save remaining byte count
	push	si			;save next data byte addr

mdone:
	mov	sublist_6.sub_value,offset OFF_byte ;AN000; ;sublist OF MSG DesC
	print_msg msgnum_bad,STDOUT	;AN000; ;"Compare error at offset %1"
	mov	sublist_7.sub_value,offset byte1 ;AN000; ;sublist OF MSG DesC. (ptr TO BAD byte IN FIRST FILE)
	print_msg msgnum_adr,STDOUT	;AN000; ;"File 1 = %1"
	mov	sublist_8.sub_value,offset byte2 ;AN000; ;sublist OF MSG DesC. (ptr TO BAD byte IN SECOND FILE)
	print_msg msgnum_bdr,STDOUT	;AN000; ;"File 2 = %1"
	pop	si			;get regs back
	pop	cx
	inc	byte ptr cnt		;count errors
	cmp	byte ptr cnt,10 	;10 errors yet?
	je	gotten			;yes, further compare is useless
	jmp	comp			;no, go on with following byte
gotten:
	push	ds
	pop	es			;get es back
	print_msg msgnum_tenmsg,STDOUT	;AN000; ;"10 Mismatches - ending compare"

quit3:					;terminate
	mov	byte ptr swt,16 	;say we've found the secondary dir
	cmp	byte ptr path1,0	;is primary file in the drive's current dir?
;	$if	ne			;AN000; NO
	JE $$IF49
	    mov     dx,offset path1	;no,
	    doscall CHDIR		;AC000;
;	$endif				;AC000;
$$IF49:
	mov	dx,offset infcb
	doscall SETDTA			;AC000; ;DTA = SOURCE fcb
	mov	dx,offset fcb
	doscall SEARCHN 		;AC000; ;12H FIND NEXT SOURCE FILE
	or	al,al			;find one?
	jnz	quit4			;no
	jmp	f1ok			;yes, go process it
AccessDenied1:				;Oops, there was an error. AssUME it was Access Denied
	fill_name1 INfcb		;AN000; ;get full path name
	mov	sublist_21.sub_value,offset name1 ;AN000; ;SET UP %1 IN sublist OF "Access Denied - %0"
	mov	dx,offset msgnum_accessdenied ;AC000; ;dx = ptr TO MSG DesCRIPTOR TO dispLAY
					;AN000; ;VALUES IN dx,si,di PAssED TO BADFIL CODE
	jmp	short badfil

ShrErr:
	fill_name1 INfcb		;AN000; ;get full path name
	mov	sublist_13.sub_value,offset name1 ;AN000; ;SET UP %1 IN sublist OF "Sharing violation - %0"
	mov	dx,offset msgnum_SHARE	;AC000; ;dx = ptr TO MSG DesCRIPTOR TO dispLAY
					;AN000; ;VALUes IN dx,si,di PAssED TO BADFIL CODE
badfil: 				;assume si = path, di = fcb , dx = MSG DesCRIPTOR
	push	dx
	push	cx
	print_msg msgnum_crlf,STDERR	;AN000; ;dispLAY CRLF
	print_msg msgnum_crlf,STDERR	;AN000; ;dispLAY CRLF
	pop	cx
	pop	dx
;	DISPLAY MSG THAT WAS POINTED TO BY DX
	push	ax
	push	di			;AN003;
	mov	di,dx			;AN003;
	mov	[di].msg_handle,STDERR	;AN003;
	pop	di			;AN003;
	call	sendmsg 		;AC000; ;dispLAY IT
	pop	ax			;AN000;
quit4:					;no more primary files
;;;;;;	 cmp byte ptr path1,0 ;current dir on pri drive?
;;;;;;	 je quit5	 ;yes
	mov	dx,offset oldp1
	doscall CHDIR			;AC000; ;no, restore it now
quit5:
	mov	byte ptr path2,0	;force get of second name - leave this here
	mov	byte ptr swt,0
;	$do				;AC000; ;REPEAT UNTIL A VALID Y/N REspONSE
$$DO51:
	    mov     dx,offset msgnum_nother ;AN000; ;dispLAY (Y/N) MEssAGE
	    push    di			;AN007;  save DI
	    mov     di,dx		;AN007;  DI -> message struct
	    mov     [di].msg_handle,STDERR ;AN007; display to STDERR
	    pop     di			;AN007; restore DI
	    call    sendmsg		;AC000; ;dispLAY IT
	    push    ax			;SAVE REspONSE
	    print_msg msgnum_crlf,STDERR ;AC003; ;dispLAY CRLF
	    print_msg msgnum_crlf,STDOUT ;AC009; ;dispLAY CRLF
	    pop     dx			;AN000; ;GET REspONSE BACK
	    doscall GET_EXT_CNTRY_INFO,YESNO_CHECK ;AC000; ;CHECK REspONSE, dx=REspONSE
	    cmp     al,YES		;AN000; ;Yes REspONSE
;	$leave	e			;AN000; ;LEAVE loop
	JE $$EN51
	    cmp     al,0		;AN000; ;NO REspONSE
;	$leave	e
	JE $$EN51
;	$enddo				;AN000; ;REPEAT UNTIL A VALID Y/N REspONSE
	JMP SHORT $$DO51
$$EN51:
	cmp	al,YES			;AC000; ;ax=0=NO, ax=1=Yes   (CHECK REspONSE)
;	$if	e			;AC000; ;GOT A Yes REspONSE, REPEAT COMP
	JNE $$IF55
	    xor     ax,ax		;AN008; ;AN000; ;CHAR TO USE TO CLEAR BUFFER
	    mov     di,offset path1	;AN000; ;CLEAR OLD PATH, FILE NAMes TO START AGAIN
	    mov     cx,129		;AN000; ;LENGTH OF BUFFER
;	    $do 			;AN000;
$$DO56:
		stosb			;AN000;
;	    $enddo  loop		;AN000;
	    LOOP $$DO56
	    mov     di,offset path2	;AN000; ;CLEAR OLD PATH, FILE NAMes TO START AGAIN
	    mov     cx,129		;AN000; ;LENGTH OF BUFFER
;	    $do 			;AN000;
$$DO58:
		stosb			;AN000;
;	    $enddo  loop		;AN000;
	    LOOP $$DO58
	    mov     clear,1		;set clear
	    jmp     rpt 		;AC000; ;REPEAT COMP
;	$endif				;AC000;
$$IF55:
	ret				;AN000; ;QUIT


;--------------------------------------------
; CONTROL BREAK EXIT CODE (INTERRUPT HANDLER)
;--------------------------------------------
CBExit:
	test	swt2,2			;oldp2 set?
;	$if	nz			;AC000; ;no, restore it now
	JZ $$IF61
	    mov     dx,offset oldp2
	    doscall CHDIR		;AC000; ;no, restore it now
;	$endif				;AC000;
$$IF61:

	test	swt2,1			;oldp1 set?
;	$if	nz			;AC000; ;if it was
	JZ $$IF63
	    mov     dx,offset oldp1
	    doscall CHDIR		;AC000; ;no, restore it now
;	$endif				;AC000;
$$IF63:

;;(deleted for AN009)	     call    restore_cp 	     ;AN000; ;restore the codepage
	mov	al,EXCB 		;AN000; ;errorlevel: control break exit
	doscall RET_FN			;AN000; ;return to DOS with ret code

	int	20h			;AC000; ;if exit didn't work, kill it
main	endp				;AN000;

;------------------------------------------------------------------------------
;  -----------------------------SUBROUTINES----------------------------------
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; FINDFS - Finds the last "\" in the path name given. This is done so that the
;	   path and not the filename can be derived from the path name.
;
;   INPUT  - SI = ptr to path name to work on
;   OUTPUT - saves address of last "\" at end of buffer that SI points to.
;	     (this is tricky)
;------------------------------------------------------------------------------
findfs	proc	near			;AN000;
	mov	string_off,si		;AN006;  save addr of string for Check_DBCS_slash
	mov	string_seg,cs		;AN006;
	push	dx			;AN000;
	push	si			;AN000;
	xor	dx,dx			;AN008; ;AN000; ;CLEAR dx IN THE CASE THAT NO "\" IS FOUND
;	$do				;AN000;
$$DO65:
	    lodsb			;AN000; ;GET A CHARACTER
	    cmp     al,0		;AN000; ;AT END OF STRING YET ?
;	$leave	z			;AN000; ;Yes, LEAVE
	JZ $$EN65
	    push    si			;AN006; Check the character in AL == '\'
	    dec     si			;AN006;  and the character in front of
	    call    Check_DBCS_slash	;AN006;  the '\' is not DBCS.
	    pop     si			;AN006;

;	    $if     z			;AN000; ;Yes, SAVE ADDR OF IT IN dx
	    JNZ $$IF67
		mov	dx,si		;AN000;
		dec	dx		;AN000;
;	    $endif			;AN000;
$$IF67:
;	$enddo				;AN000;
	JMP SHORT $$DO65
$$EN65:
	pop	si			;AN000;
	mov	[si+128],dx		;AN000; ;SAVE ADDR OF LAST "\" IN THE LAST TWO BYTes OF PATH
	pop	dx			;AN000;
	ret				;AN000;
findfs	endp				;AN000;


;------------------------------------------------------------------------------
; GETNAM - Inputs a filename from STDIN to be used as either the first or second
;	   parameter for COMP.
;
;   INPUT  - PARM_COUNT = ordinal number for parser
;	     DX = ptr to msg descriptor of message to display
;	     BX = ptr to FCB of file
;	     SI = ptr to FCB structure
;------------------------------------------------------------------------------
getnam	proc	near
	mov	input_buf,INPUT_LEN	;AN000; ;PUT LENGTH OF BUFFER AS FIRST byte OF BUFFER
	mov	di,dx			;AN000; ;FILL IN offset OF INPUT BUFFER IN MSG DesC.
	mov	[di].msg_input, offset input_buf ;AN000; ;ptr TO INPUT BUFFER
	mov	[di].msg_handle, STDERR
	push	ax			;AN000;
	call	sendmsg 		;AC000; ;dispLAY MEssAGE, GET BUFFERED INPUT
	pop	ax			;AN000;
	xor	ch,ch			;AN000; ;CLEAR HIGH byte OF cx
	mov	cl,input_len		;AN000; ;CL = LENGTH OF INPUT BUFFER
					;get offset into input buffer (to skip length word)
	mov	current_parm,offset INPUT_BUF+2 ;AN000; ;CURRENT_PARM = offset OF INPUT BUFFER
	mov	ordinal,ZERO_PARM_CT	;AN000; ;TELL PARSER THAT THIS IS FIRST PARAMETER (ONLY ONE)
	call	parser			;PUT NEW STRING AT WHERE di POINTS TO
	ret				;then go back
getnam	endp				;AC000;


;------------------------------------------------------------------------------
; FINDPATH - Check if path is a directory. If yes, then CHDIR to it and set the
;	     FCB to ????????.???. If no, check for "\". If no "\", then assume
;	     we are in the correct directory and set FCB to ????????.??? if blank.
;	     If "\" is found, then strip last name off path into FCBYTE (?'s if
;	     nothing follows "\") and try to find the directory again.
;
;   INPUT  - SI = ptr to path string
;	     DI = ptr to FCB (drive byte is valid)
;   OUTPUT - if path found then set ZERO flag and CHDIR to directory and FCB set.
;	     else FCB set and reset ZERO flag.
;------------------------------------------------------------------------------
findpath proc	near
	mov	dl,[di] 		;drive number from fcb
	push	di
	push	si
	mov	di,si
	sub	di,67			;where to put current dir for the drive
	mov	al,dl			;AN005; ;get drive number
	add	al,64			;AN005; ;convert to ascii letter
	stosb				;AN005;
	mov	al,':'			;AN005;
	stosb				;AN005;
	mov	al,pathchar		;get path separator
	stosb				;and put in beginning of path
	mov	si,di
	doscall CURDIR			;AC000; ;GET DRIVE'S CURRENT diR
	cmp	di,offset oldp1+3	;See if pri cur dir is set up
;	$if	e			;AC000;
	JNE $$IF70
	    or	    swt2,1
;	$endif				;AC000;
$$IF70:
	cmp	di,offset oldp2+3	;See if sec cur dir is set up
;	$if	e			;AC000;
	JNE $$IF72
	    or	    swt2,2
;	$endif				;AC000;
$$IF72:
	pop	si			;path string
	pop	di			;fcb
	cmp	byte ptr [si],0 	;is there a path?
	jne	fp3			;yes
fp0:
	cmp	byte ptr [di+1]," "	;no, is there a name in the fcb?
	jne	fp2			;yes, use current dir
fp1:
	call	setq			;no, set it to ????????.???
fp2:
	cmp	al,al			;force eq on return
	ret
fp3:					;there's a path
	mov	dx,si			;path
	doscall CHDIR			;AC000; ;see if it's a dir
	jnc	fp1			;yes, set fcb to ?'s - path found and set
	mov	bx,[si+128]		;no - get last \ in string
	or	bx,bx			;is there a \?
	jnz	fp4			;yes, go strip off last name
	mov	byte ptr [si],0 	;no, there's only 1 name in path - must be filename
	jmp	short fp0		;go use current dir
fp4:
	call	backoff 		;strip last name off line into fcb
	mov	dx,si
	doscall CHDIR			;AC000; ;noword ptr  is result line a valid path?
	jnc	fp2			;yes, fcb and path are set
fp5:
	cmp	ax,1234h		;no, pass back error - path has first part of name,
	ret				;remainder is in fcb
findpath endp				;AN000;


;------------------------------------------------------------------------------
; BACKOFF - Removes the last name of a path and puts it into an FCB. Assumes at
;	    least one "\" in path. If no name is found then set the FCB to
;	    ????????.??? and
;
;   INPUT  - SI = ptr to path string.
;	     DI = ptr to FCB to format.
;   OUTPUT -
;------------------------------------------------------------------------------
backoff proc	near
	push	si
	mov	bx,[si+128]		;address of last \ in path
	cmp	byte ptr [si+1],":"	;AN002;
;	$if	e			;AN002;
	JNE $$IF74
	    add     si,2		;char following d: in path name
;	$endif				;AN002;
$$IF74:
	cmp	si,bx			;is it the only \ and is it at beg of line?
	mov	si,bx
;	$if	e			;AC000; ;Yes
	JNE $$IF76
	    inc     bx			;yes, going to root - leave \ alone
;	$endif				;AC000;
$$IF76:
	inc	si			;char following \
	cmp	byte ptr [si],0 	;are there any?
	jne	bo4			;yes
	call	setq			;no, use ????????.??? in root
	jmp	short bo3		;AC008;
bo4:
	push	di
					;AC000; ;ds:si=POINTER TO COMMAND LINE TO PARSE
					;AC000; ;es:di=POINTER TO UNOPENED fcb
					;AC000; ;AL-BIT VALUE CONTROLS PARsiNG
	doscall PARSE_FILENAME,02h	;AC000; ;PARSE LAST NAME ON LINE INTO fcb, LEAVE DRIVE byte ALONE
	pop	di
	cmp	byte ptr [di+1]," "	;is there a file name?
;	$if	ne			;AC000; ;Yes, TRUNCATE PATH AND LEAVE
	JE $$IF78
bo3:
	    mov     byte ptr [bx],0	;truncate the path name
	    pop     si
;	$else				;AC000; ;siNCE NO FILE NAME,
	JMP SHORT $$EN78
$$IF78:
	    pop     si			;no, restore si
	    pop     ax			;strip return to findpath
	    call    setq		;fill fcb with ?'s
	    cmp     ax,1234h		;AN000; ;SET ERROR retURN
;	$endif				;AC000;
$$EN78:
	ret
backoff endp				;AN000;


;------------------------------------------------------------------------------
; SETQ - Set an FCB filename field to ????????.???
;
;   INPUT  - DI = ptr to FCB
;   OUTPUT - FCB is changed.
;------------------------------------------------------------------------------
setq	proc	near
					;di = ^ fcb
	push	di
	mov	al,"?"
	mov	cx,11
	inc	di			;point to filename
;	$do				;AC000;
$$DO81:
	    stosb
;	$enddo	loop			;AC000;
	LOOP $$DO81
	pop	di
	ret
setq	endp				;AC000;


;------------------------------------------------------------------------------
; GET - Fill large buffer
;
;   INPUT  -
;   OUTPUT -
;------------------------------------------------------------------------------
get	proc	near
	push	dx			;save fcb address
	mov	ds,buf2 		;point to large buffer
	xor	dx,dx
	doscall SETDTA			;AC000; ;SET DTA TO LARGE BUFFER
	push	cs
	pop	ds			;get ds back
	pop	dx			;and get fcb addr back
	mov	cx,word ptr mem 	;# bytes of avail mem in large buffer
	doscall FCBRNDBLKREAD		;AC000; ;FILL LARGE BUFFER
	mov	siz,cx			;# bytes we read
	mov	word ptr curpos,0	;current byte position offset in large buffer
	or	al,al			;get eof?
;	$if	nz			;AC000; ;Yes, AT EOF
	JZ $$IF83
	    call    fileend		;AC000;
;	$endif				;AC000;
$$IF83:
	ret				;No, keep on going
get	endp				;AC000;


;------------------------------------------------------------------------------
; FILEEND - Check for EOF char on last read into large buffer (?)
;
;   INPUT  -
;   OUTPUT -
;------------------------------------------------------------------------------
fileend proc	near
	or	byte ptr swt,1		;yes, flag it
	mov	bx,cx			;# bytes just read
	mov	ds,buf2
	cmp	byte ptr [bx-1],26	;is the last char of file an eof?
	push	cs
	pop	ds
;	$if	e			;AC000; ;Yes
	JNE $$IF85
	    or	    byte ptr swt,8	;yes, say we found the eof
;	$endif				;AC000;
$$IF85:
	doscall FCBCLOSE		;AC000; ;Close the file filling large buffer
	ret
fileend endp				;AN000;


;------------------------------------------------------------------------------
; GETF2 -  Read 8 sectors from file that FCB points to.
;
;   INPUT  - DX = ptr to FCB
;   OUTPUT - fills small buffer
;------------------------------------------------------------------------------
getf2	proc	near
					;fill small buffer from fcb at [dx]
	push	dx
	mov	dx,offset buf		;small buffer addr
	doscall SETDTA			;AC000; ;SET THE DTA
	pop	dx
	mov	cx,4096 		;ask for 8 sectors
	doscall FCBRNDBLKREAD		;AC000; ;GET THE DATA
	ret
getf2	endp				;AN000;


;------------------------------------------------------------------------------
; FILL_N - This routine fills the buffer NAME1 or NAME2 with the full path name
;	   of the corresponding file.
;
;   INPUT  - DX = ptr to buffer to put full path name in
;	     DI = ptr to FCB to get drive letter,filename,extension from
;	     SI = ptr to PATH1 or PATH2 depending on whether first or second file
;   OUTPUT -
;------------------------------------------------------------------------------
fill_n	proc	near
	push	ax			;AN000;
	push	cx			;AN000;
	mov	string_off,dx		;AN006; pass whole string to Check_DBCS_slash
	mov	string_seg,cs		;AN006;
;get drive letter & colon		;AN000;
	xchg	dx,si			;AN000; ;make dx=fcb ptr, si=buffer ptr
	mov	al,[di] 		;AN000; ;drive byte from fcb
	inc	di			;AN000; ;point to filename
	add	al,64			;AN000; ;drive to ascii
	mov	[si],al 		;AN000; ;save letter in string
	inc	si			;AN000; ;increment ptr
	mov	byte ptr [si],":"	;AN000; ;add colon to drive letter
	inc	si			;AN000;
	xchg	dx,si			;AN000;
;get full path				;AN000;
	xchg	dx,di			;AN000;
	cmp	byte ptr [si],0 	;AN000; ;is there a path?
;	$if	ne			;AN000; ;Yes
	JE $$IF87
	    cmp     byte ptr [si+1],':' ;is thera a drive letter ?
;	    $if     e
	    JNE $$IF88
		add	si,2		;AN000; ;yes, skip drive id in path
;	    $endif
$$IF88:
;	    $do 			;AC000;
$$DO90:
		lodsb			;AN000; ;get a path char
		or	al,al		;AN000; ;end of path?
;	    $leave  Z			;AN000; ;Yes
	    JZ $$EN90
		stosb			;AN000; ;copy character
;	    $enddo			;AC000;
	    JMP SHORT $$DO90
$$EN90:
	    push    si			;AN006; Check the character in AL == '\'
	    mov     si,di		;AN006;  and the character in front of
	    dec     si			;AN006;  the '\' is not DBCS.
	    call    Check_DBCS_slash	;AN006;
	    pop     si			;AN006;

;	    $if     NE			;AC000; ;NO
	    JE $$IF93
		mov	al,"\"		;AC000; ;no, display separator ahead of filename
		stosb			;AN000;
;	    $endif			;AC000;
$$IF93:
;	$endif				;AC000;
$$IF87:
;get filename				;AN000;
	xchg	dx,si			;AC000; ;dx=path1 or path2, si=ptr buffer, di=ptr fcb
	mov	cx,8			;AN000;
;	$do				;AC000;
$$DO96:
	    lodsb			;AC000; ;display filename
	    cmp     al," "		;AC000; ;Is it end of filename
;	$leave	e			;AC000; ;Yes, GET EXTENsiON
	JE $$EN96
	    stosb			;AN000;
;	$enddo	loop			;AC000; ;GET MORE CHARS, IF ANY
	LOOP $$DO96
$$EN96:
	and	cx,cx			;AC008;
;	$if	ne
	JE $$IF99
	    dec     cx			;AC000; ;# of spaces left to skip in filename
;	    $do 			;AC000; ;step thru spaces to get to file extension
$$DO100:
		inc	si		;AN000;
;	    $enddo  loop		;AC000; ;until cx=0
	    LOOP $$DO100
;	$endif
$$IF99:
;get filename extension 		;AN000;
	cmp	byte ptr [si]," "	;AC000; ;is there an extension?
;	$if	ne			;AC000; ;Yes, DO PERIOD
	JE $$IF103
	    mov     al,"."		;AN000;
	    stosb			;AN000;
	    mov     cx,3		;AN000;
;	    $do 			;AC000;
$$DO104:
		lodsb			;AC000; ;display extension
		cmp	al," "		;AC000; ;is it end of extension?
;	    $leave  e			;AC000; ;Yes
	    JE $$EN104
		stosb			;AN000;
;	    $enddo  loop		;AC000;
	    LOOP $$DO104
$$EN104:
;	$endif				;AC000; ;EXTENsiON?
$$IF103:
	mov	al,0			;AN000;
	stosb				;AC000; ;end of string marker
	xchg	dx,si			;AN000;
	xchg	dx,di			;AN000;
	pop	cx			;AN000;
	pop	ax			;AN000;
	ret
fill_n	endp				;AN000;


;------------------------------------------------------------------------------
; MAKEPATHFROMFCB - Creates an ASCIIZ path at DI from the FCB pointed to by SI.
;
;   INPUT  - SI = ptr to FCB
;	     DI = buffer for path name to be stored.
;   OUTPUT -
;------------------------------------------------------------------------------
MakePathFromFcb proc near
	push	si			;Save fcb address
	mov	al,byte ptr [si]	;Get drive letter from fcb (0=A,1=B,...)
	add	al,64			;Convert it to ASCII
	stosb				;Store it in the PATH
	mov	al,":"			;Put a drive separator
	stosb				; in the PATH.
	inc	si
	mov	cx,8			;Copy [1..8] bytes
					; GET FILENAME
;	$do				;AC000;
$$DO108:
	    movsb			;Move the char from the fcb
	    cmp     byte ptr [si]," "	;Is the next char a blank ?
;	$leave	e			;AC000; ;Yes, NO MORE CHARS IN FILENAME
	JE $$EN108
;	$enddo	loop			;AC000; ;NO, GET NEXT CHAR, IF ANY
	LOOP $$DO108
$$EN108:
					; InsertPeriod
	mov	byte ptr [di],"."	;Stick a period in there...
	inc	di			; and increment the pointer
	mov	cx,3			;Copy [0..3] bytes...
	pop	si			; from the fcb's
	add	si,9			; extension area
;	$do				;AC000;
$$DO111:
	    cmp     byte ptr [si]," "	;Is the next char a blank?
;	$leave	e			;AC000; ;Yes, THEN WE ARE DONE
	JE $$EN111
	    movsb			; No, move it
;	$enddo	loop			;AC000; ;AND GET THE NEXT ONE, IF ANY
	LOOP $$DO111
$$EN111:
	mov	al,00
	stosb				;Copy in a byte of Hex 0
	ret
MakePathFromFcb endp


;------------------------------------------------------------------------------
; RESTOREDIR - Do a CHDIR to the original directory this program started in.
;
;   INPUT  - OLDP2 = path string of original directory (for target filespec)
;	     PATH2 = path string of target filespec.
;   OUTPUT - changes the current directory
;------------------------------------------------------------------------------
RestoreDir proc near
	cmp	byte ptr path2,0	;working with current dir on secondary file?
;	$if	ne			;AC000; ;NO,
	JE $$IF114
	    push    ax			;restore old current directory
	    mov     dx,offset oldp2
	    doscall CHDIR		;AC000;
	    pop     ax
;	$endif				;AC000;
$$IF114:
	ret
RestoreDir endp 			;AN000;


;------------------------------------------------------------------------------
; INIT_CP - To permit "COMP" to open the first and second files regardless of
;	    the system codepage, and to avoid any codepage mismatch critical
;	    error from occurring from the open, we temporarily suspend codepage
;	    support. It will be restored at the end of COMP.
;
;   INPUT  -
;   OUTPUT - CPSW_ORIG byte will have the CPSW bit set on if cpsw = on
;------------------------------------------------------------------------------
init_cp proc	near			;AN000;
	public	init_cp 		;AN000;

	doscall CPSW_CHECK,GET_CPSW_STATE ;AN000; ;IS CODEPAGE SUPPORT LOADED
	and	dl,dl			;AC008; ;AN000;
;	$if	ne			;AN000; ;IF CPSW IS LOADED
	JE $$IF116
	    or	    cpsw_orig,CPSW	;AN000; ;SET FLAG TO INdiCATE CPSW=ON
	    mov     dl,CPSW_OFF 	;AN000; ; TO CPSW=OFF
	    doscall CPSW_CHECK,SET_CPSW_STATE ;AN000; ;SET CPSW=OFF
;	$endif				;AN000; ;CPSW LOADED?
$$IF116:
	ret				;AN000; ;retURN TO callER
init_cp endp				;AN000;


;------------------------------------------------------------------------------
; RESTORE_CP - Restore chcp status (codepage support to original values)
;
;   INPUT  -
;   OUTPUT -
;------------------------------------------------------------------------------
restore_cp proc near			;AN000;
	public	restore_cp		;AN000;

	test	cpsw_orig,CPSW		;AN000; ;WAS CPSW ON WHEN WE STARTED?
;	$if	nz			;AN000; ;IF CPSW WAS ON
	JZ $$IF118
	    mov     dl,CPSW_ON		;AN000; ; TO CPSW=ON
	    doscall CPSW_CHECK,SET_CPSW_STATE ;AN000; ;SET CPSW=ON
;	$endif				;AN000; ;CPSW WAS ON?
$$IF118:
	ret				;AN000; ;retURN TO callER
restore_cp endp 			;AN000;


;------------------------------------------------------------------------------
; COMP_CODEPAGE - If chcp=on, verify that the codepage of the two files agree.
;
;   INPUT  - PATH1 has the asciiz of the first path\filename
;	     PATH2 has the asciiz of the second path\filename
;   OUTPUT -
;------------------------------------------------------------------------------
comp_codepage proc near 		;AN000;
	public	comp_codepage		;AN000;

	test	cpsw_orig,CPSW		;AN000; ;WAS CPSW=ON WHEN WE STARTED?
;	$if	nz			;AN000; ;IF CPSW IS LOADED
	JZ $$IF120
	    fill_name1 infcb		;AN000; ;get full path name
	    mov     cur_name,offset name1 ;AN000; ;PAss INPUTED FILENAME OF FIRST FILE
	    call    getcp		;AN000; ;GET CODEPAGE OF FIRST FILE
	    mov     ax,qlist_ea.ea_value ;AC001; ;SAVE	ITS CODEPAGE
	    push    ax			;AN000; ;ON THE STACK
	    fill_name2			;AN000; ;get full path name
	    mov     cur_name,offset name2 ;AN000; ;PAss INPUTED FILENAME OF SECOND FILE
	    call    getcp		;AN000; ;GET CODEPAGE OF SECOND FILE
	    pop     ax			;AN000; ;GET FIRST FILE CODEPAGE
	    mov     bx,qlist_ea.ea_value ;AC001; ;GET SECOND FILE CODEPAGE
	    and     ax,ax		;AC008; ;AN000; ;COMPARE TO ZERO CP
;	    $if     ne			;AN000; ;FIRST FILE HAS NON-ZERO CODE PAGE
	    JE $$IF121
		and	bx,bx		;AC008; ;AN000; ;COMPARE TO ZERO CP
;		$if	ne		;AN000; ;SECOND FILE HAS NON-ZERO CODE PAGE
		JE $$IF122
		    cmp     ax,bx	;AN000; ;COMPARE CP OF 1ST WITH CP OF 2ND
;		    $if     e		;AN000; ;CP ARE ALIKE
		    JNE $$IF123
			clc		;AN000; ;INdiCATE MATCHING CP
;		    $else		;AN000; ;siNCE CP ARE NOT ALIKE
		    JMP SHORT $$EN123
$$IF123:
			stc		;AN000; ;INdiCATE NON-MATCHING CP
;		    $endif		;AN000; ;CP ARE ALIKE
$$EN123:
;		$else			;AN000; ;siNCE 2ND HAS NO CODE PAGE
		JMP SHORT $$EN122
$$IF122:
		    stc 		;AN000; ;INdiCATE NON-MATCHING CP
;		$endif			;AN000; ;2ND FILE HAS CODE PAGE?
$$EN122:
;	    $else			;AN000; ;siNCE 1ST FILE HAS NO CODE PAGE
	    JMP SHORT $$EN121
$$IF121:
		and	bx,bx		;AC008; ;AN000; ;COMPARE TO ZERO CP
;		$if	ne		;AN000; ;2ND FILE HAS NO CODE PAGE
		JE $$IF129
		    stc 		;AN000; ;INdiCATE NON-MATCHING CP
;		$else			;AN000; ;siNCE 2ND FILE HAS NO CODE PAGE EITHER
		JMP SHORT $$EN129
$$IF129:
		    clc 		;AN000; ;INdiCATE OK, NO CP TO COMPARE
;		$endif			;AN000; ;2ND FILE HAS CP?
$$EN129:
;	    $endif			;AN000; ;1ST FILE HAS CODE PAGE?
$$EN121:
;	    $if     c			;AN000; ;IF CARRY
	    JNC $$IF133
		print_msg msgnum_cp_mismatch,STDERR ;AN000; ;"CODE PAGE MISMATCH"
		stc			;AN000; ;PAss INdiCATOR OF NON-MATCH CP
;	    $endif			;AN000;
$$IF133:
;	$else				;AN000; ;siNCE CODE PAGE NOT ACTIVE
	JMP SHORT $$EN120
$$IF120:
	    clc 			;AN000; ;PAss INdiCTOR OF OK CP
;	$endif				;AN000; ;CODEPAGE LOADED?
$$EN120:
	ret				;AN000; ;retURN TO callER
comp_codepage endp			;AN000;


;------------------------------------------------------------------------------
; GETCP - Does an extended open, gets codepage #, closes file.
;
;  INPUT  - AX = ptr to real filename to open
;	    CUR_NAME = ptr to inputed filename to open (display this if error)
;  OUTPUT -
;------------------------------------------------------------------------------
getcp	proc	near			;AN000;
	public	getcp			;AN000;

;	SET   UP INPUTS TO EXTENDED OPEN:
;	REQUesT FUNCTIONS: READ,COMPATABILITY,NO INHERIT,INT 24H ret ERR,
;	NO    COMMIT, NO ATTR, FAIL IF NOT EXIST, OPEN IF EXIST
;	NO    CODE PAGE CHECK

	mov	bx,OPEN_MODE		;AN000; ;SET READ MODE TO CORRECT VALUE FOR EXTENDED OPEN
	xor	cx,cx			;AC008; ;AN000; ;NO ATTRIBUTE TO WORRY ABOUT (00H = NO_ATTR)
	mov	dx,FUNC_CNTRL		;AN000; ;SET FUNCTION CONTROL FOR EXTENDED OPEN
	mov	di,offset parm_list	;AN000; ;PAss offset TO PARM_LIST
	mov	si,cur_name		;AN000; ;ptr to name of file to open
	doscall EXT_OPEN,EXT_OPEN_RD	;AN000;
	mov	handle,ax		;AN000; ;SAVE HANDLE
;	$if	c			;AN000; ;IF ERROR
	JNC $$IF137
	    call    exterr		;AN000; ;GET EXTENDED ERROR, SHOW MSG
;	$else				;AN000; ;siNCE NO ERROR ON OPEN
	JMP SHORT $$EN137
$$IF137:
					;AN000; ;GET_EXT_ATTR_LIST (5702), GET
					;AN000; ;EXTENDED ATTR. TO LIST
	    mov     bx,handle		;AN000; ;bx=HANDLE
	    mov     di,offset qlist	;AC001; ;es:di=QLIST
	    mov     cx,13		;AN001; ;size of QLIST returned
	    mov     si,offset querylist ;AN001; ;get code page attr. only
	    doscall EXT_ATTR_LIST,GET_EXT_ATTR_LIST ;AN000;
					;AN000; ;CY SET IF ERROR
;	    $if     c			;AN000; ;IF ERROR
	    JNC $$IF139
		call	exterr		;AN000; ;GET EXTENDED ERROR, SHOW MSG
;	    $endif			;AN000;
$$IF139:
	    mov     bx,handle		;AN000; ;PAss HANDLE TO CLOSE FILE
	    doscall HANDLECLOSE 	;AN000; ;CLOSE THIS EXTENDED OPEN OF THE FILE
;	$endif				;AN000;
$$EN137:
	ret				;AN000; ;retURN TO callER
getcp	endp				;AN000;


;------------------------------------------------------------------------------
; EXTERR - Displays the extended error message and filename.
;
;   INPUT  -
;   OUTPUT -
;------------------------------------------------------------------------------
exterr	proc	near			;AN000;
	public	exterr			;AN000;

	xor	bx,bx			;AC008; ;AN000; ;bx = MINOR VERsiON # OF DOS
	doscall EXTERROR		;AN000; ;GET EXTENDED ERROR
	mov	msgnum_exterr.msg_num,ax ;AN000; ;PUT EXT. ERROR # IN MSG DesCRIPTOR STRUCT.
	mov	msgnum_exterr.msg_sublist,offset sublist_EXTERR ;AN000; ;ptr TO sublist
	mov	msgnum_exterr.msg_count,NO_SUBS ;AN000; ;ONE sublist WILL BE USED.
	mov	ax,cur_name		;AN000; ;GET CURRENT FILENAME
	mov	sublist_exterr.sub_value,ax ;AN000; ;FILL IN offset OF FILENAME TEXT
	print_msg msgnum_exterr,STDERR	;AN000; ;dispLAY EXTENDED ERROR MEssAGE

	mov	exitfl,EXVER		;AN000; ;INdiCATE AN ERROR
	ret				;AN000;
exterr	endp				;AN000;


;------------------------------------------------------------------------------
; GET_DBCS_VECTOR - Get the DOS double byte character table segment and offset
;
;   INPUT  -
;   OUTPUT -
;------------------------------------------------------------------------------
bufferDB db	6 dup(0)

get_dbcs_vector proc near		;AN006;
	push	es			;AN006;
	push	di			;AN006;
	push	ax			;AN006;
	push	bx			;AN006;
	push	cx			;AN006;
	push	dx			;AN006;
;
	mov	ax,cs			;AN006; ;segment of return buffer
	mov	es,ax			;AN006;
	mov	di,offset bufferDB	;AN006; ;offset of return buffer
	mov	ah,65h			;AN006; ;get extended country info
	mov	al,07h			;AN006; ;get DBCS environment table
	mov	bx,0ffffh		;AN006; ;use active code page
	mov	cx,5			;AN006; ;number of bytes returned
	mov	dx,0ffffh		;AN006; ;default country ID
	int	21h			;AN006; ;DOS function call,vector returned
					;AN006; ; in ES:DI
	inc	di			;AN006; ;skip over id byte returned
	mov	ax,word ptr es:[di]	;AN006; ;get offset of DBCS table
	mov	cs:dbcs_off,ax		;AN006; ;save it
;
	add	di,2			;AN006; ;skip over offset to get segment
	mov	bx,word ptr es:[di]	;AN006; ;get segment of DBCS table
	mov	cs:dbcs_seg,bx		;AN006; ;save it
;
	mov	di,ax			;AN006; ;Point to DBCS table to get length
	mov	es,bx			;AN006;
	mov	ax,word ptr es:[di]	;AN006;
	mov	cs:dbcs_len,ax		;AN006;
	add	cs:dbcs_off,2		;AN006; ;change offset to point to table
;
	pop	dx			;AN006;
	pop	cx			;AN006;
	pop	bx			;AN006;
	pop	ax			;AN006;
	pop	di			;AN006;
	pop	es			;AN006;
;
	ret				;AN006;
get_dbcs_vector endp			;AN006;


;------------------------------------------------------------------------------
;  Check_DBCS_slash - given SI pointing to string, check if the character SI
;		      points to is a slash and that the preceeding character
;		      is not DBCS.
;
;   INPUT  - SI = ptr to possible slash character
;	     STRING_SEG:STRING_OFF points to the beginning of string
;   OUTPUT - set ZERO flag if [SI-1] != DBCS character AND [SI] == '\',
;	     else resets ZERO flag.
;------------------------------------------------------------------------------
Check_DBCS_slash proc near		;AN006;
	push	es			;AN006;
	push	di			;AN006;
	push	si			;AN006;
	push	ax			;AN006;
	push	bx			;AN006;
	push	cx			;AN006;
;
	cmp	byte ptr [si],'\'	;AN006; ;Is character a slash ?
	jne	reset_zero		;AN006; ;no, quit.
;
	cld				;AN006;
	mov	cx,128			;AN006; ;clear darray to zeroes
	mov	di,offset dstring	;AN006; ;dstring will correspond to the string pointed to by
	mov	al,00			;AN006; ;string_seg:string_off and for each character in the string
	rep	stosb			;AN006; ;that is DBCS a corresponding "D" will be stored in dstring.
					;AN006; ;example:    string : [c:\\\ ]
					;	     dstring: [   D D  ] (there are two DBCS characters)
;
	sub	si,string_off		;AN006; ;si will equal length of string from beginning to character that may be a slash.
	and	si,si			;AC008; ;AN006; ;is character in first position ?
	jbe	set_zero		;AN006; ;yes, quit.
	mov	cx,si			;AN006; ;cx will contain the count of characters to check DBCS status of.
	push	cx			;AN006; ;save for later
	mov	si,string_off		;AN006; ;si points to beginning of string.
;
	mov	bx,cs:dbcs_seg		;AN006; ;ES:SI -> DOS dbcs table (segment)
	mov	es,bx			;AN006;
;
	mov	bx,offset dstring	;AN006; ;bx points to dstring
DB_loop:				;AN006;
	mov	di,cs:dbcs_off		;AN006; ;ES:SI -> DOS dbcs table (offset)
	lodsb				;AN006; ;get character into al
;
; Two consecutive 00 bytes signifies end of table
;

is_loop:				;AN006;
	cmp	word ptr es:[di],00h	;AN006; ;Check for two consecutive 00 bytes
	jne	is_next1		;AN006; ;no, continue
	jmp	short DB_inc		;AC008; ;AN006; ;yes, found them, quit
;
; Check if byte is within range values of DOS dbcs table
;
is_next1:				;AN006;
	cmp	al,byte ptr es:[di]	;AN006; ;is byte >= first byte in range?
	jae	is_next2		;AN006; ;yes, continue
	jmp	short is_again		;AC008; ;AN006; ;no, loop again
is_next2:				;AN006;
	cmp	al,byte ptr es:[di+1]	;AN006; ;is byte <= last byte in range?
	jbe	is_found		;AN006; ;yes, found a lead byte of db char
is_again:				;AN006;
	add	di,2			;AN006; ;no, increment ptr to next range
	jmp	is_loop 		;AN006;
is_found:				;AN006;
	mov	byte ptr ds:[bx],'D'	;AN006; ;byte is lead byte of db char, set [BX] = 'D'
	inc	bx			;AN006; ;skip over second part of double byte char.
	inc	si			;AN006; ; "     "    "     "   "    "	  "     "
DB_inc: 				;AN006;
	inc	bx			;AN006;
	dec	cx			;AN006;
	and	cx,cx			;AC008; ;AN006; ;are we done check characters for DBCS
	jne	DB_loop 		;AN006; ;no, check next character
;
; end of loop
;
	pop	cx			;AN006; ;restore offset into string
	dec	cx			;AN006; ;check character preceeding slah to see if it is DBCS
	mov	si,offset dstring	;AN006; ;get beginning of string
	add	si,cx			;AN006; ;si now point to char preceeding slash
	cmp	byte ptr [si],'D'	;AN006; ;Is it DBCS ?
	je	reset_zero		;AN006; ;yes
set_zero:				;AN006;
	cmp	al,al			;AN006; ;set ZERO flag
	jmp	short is_bye		;AC008; ;AN006;
reset_zero:				;AN006;
	mov	bx,01h			;AN006;
	cmp	bx,0ffh 		;AN006; ;reset ZERO flag
is_bye: 				;AN006;
	pop	cx			;AN006;
	pop	bx			;AN006;
	pop	ax			;AN006;
	pop	si			;AN006;
	pop	di			;AN006;
	pop	es			;AN006;
;					;AN006;
	ret				;AN006;
Check_DBCS_slash endp			;AN006;


;------------------------------------------------------------------------------
; SENDMSG - Transfer msg descriptor info to registers and call the msg retriever
;
;   INPUT  - DX = ptr to msg descriptor for this message
;   OUTPUT - DX, AX altered, others ok.
;------------------------------------------------------------------------------
sendmsg proc	near			;AN000;
	public	sendmsg 		;AN000;

	push	bx			;AN000; ;SAVE callER'S REGS
	push	cx			;AN000;
	push	si			;AN000;
	push	di			;AN000;
	mov	di,dx			;AN000; ;PUT ptr TO MSG DesC. IN di
	mov	dx,[di].msg_input	;AN000; ;GET ptr TO INPUT BUFFER AND PUT IN dx
	push	dx			;AN000; ;SAVE IT ON THE STACK FOR LATER

;		 PAss PARMS TO MEssAGE HANDLER IN
;		 THE APPROPRIATE REGISTERS IT NEEds.
	mov	ax,[di].msg_num 	;AN000; ;MEssAGE NUMBER
	mov	bx,[di].msg_handle	;AN000; ;HANDLE TO dispLAY TO
	mov	si,[di].msg_sublist	;AN000; ;offset IN es: OF sublist, OR 0 IF NONE
	mov	cx,[di].msg_count	;AN000; ;NUMBER OF %PARMS, 0 IF NONE
	mov	dx,[di].msg_class	;AN000; ;CLAss IN HIGH byte, INPUT FUNCTION IN LOW
	pop	di			;AN000; ;GET OLD dx VALUE (ptr TO INPUT BUFFER)
	call	sysdispmsg		;AN000; ;dispLAY THE MEssAGE
;	$if	c			;AN000; ;IF THERE IS A PROBLEM
	JNC $$IF142
					;AN000; ;ax=EXTENDED ERROR NUMBER
	    mov     bx,STDERR		;AN000; ;HANDLE TO dispLAY TO
	    xor     si,si		;AC008; ;AN000; ;offset IN es: OF sublist, OR 0 IF NONE
	    xor     cx,cx		;AC008; ;AN000; ;NUMBER OF %PARMS, 0 IF NONE
	    mov     dh,CLASS_1		;AN000; ;CLAss IN HIGH byte, INPUT FUNCTION IN LOW
	    call    sysdispmsg		;AN000; ;TRY TO SAY WHAT HAPPENED
	    stc 			;AN000; ;REPORT PROBLEM
;	$endif				;AN000; ;PROBLEM WITH dispLAY?
$$IF142:

	pop	di			;AN000; ;ResTORE callER'S REGISTERS
	pop	si			;AN000;
	pop	cx			;AN000;
	pop	bx			;AN000;

	ret				;AN000;
sendmsg endp				;AN000;



;------FIND BOUNDARY--------------
	if	($-cseg) mod 16 	;AN000; ;IF NOT ALREADY ON 16 byte BOUNDARY
	    org     ($-cseg)+16-(($-cseg) mod 16) ;AN000; ;ADJUST TO 16 byte BOUNDARY
	endif				;AN000;
;---------------------------------

buf	label	byte
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;ALL CODE BELOW THIS POINT WILL BE OVERLAID WITH DATA BEING COMPARED;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;------------------------------------------------------------------------------
; SETFILL - sets the fill_seg, fill_off with the current seg_id, offset in
;	    sublists of msg.
;
;   INPUT  -
;   OUTPUT -
;------------------------------------------------------------------------------
setfill proc	near			;AN000;
	public	setfill 		;AN000;
	push	ax			;AN000; ;save registers
	mov	ax,cs			;AN000; ;get the code segment
	mov	sublist_6.sub_value_seg,ax ;AN000; ;save seg_id in sublist
	mov	sublist_7.sub_value_seg,ax ;AN000; ;save seg_id in sublist
	mov	sublist_8.sub_value_seg,ax ;AN000; ;save seg_id in sublist
	mov	sublist_11.sub_value_seg,ax ;AN000; ;save seg_id in sublist
	mov	sublist_12.sub_value_seg,ax ;AN000; ;save seg_id in sublist
	mov	sublist_13.sub_value_seg,ax ;AN000; ;save seg_id in sublist
	mov	sublist_19a.sub_value_seg,ax ;AN000; ;save seg_id in sublist
	mov	sublist_19b.sub_value_seg,ax ;AN000; ;save seg_id in sublist
	mov	sublist_24.sub_value_seg,ax ;AN000; ;FILL IN CODE SEGMENT
	mov	sublist_exterr.sub_value_seg,ax ;AN000; ;FILL IN CODE SEGMENT
	pop	ax			;AN000; ; GET OLD VALUE IN ax BACK
	ret				;AN000;
setfill endp				;AN000;


;------------------------------------------------------------------------------
; MORE_INIT - finishes the initialization. this code will be overlaid with data
;	      after it executes.
;
;   INPUT  -
;   OUTPUT -
;------------------------------------------------------------------------------
more_init proc	near			;AC000;
	public	more_init		;AN000;

	cld
	or	ah,al
	cmp	ah,-1			;was either drive specified invalid?
;	$if	e			;AC000; ;one or both of drives are invalid
	JNE $$IF144
	    print_msg msgnum_baddrv,STDERR ;AN000; ;"INVALID DRIVE SPEC."
	    int     20h 		;and quit
;	$endif				;AC000;
$$IF144:
	mov	ax, offset buf+4096	;end of pgm
	add	ax,16
	mov	cl,4
	shr	ax,cl			;in seg form
	push	cs
	pop	dx
	add	ax,dx			;seg addr of buf2
	mov	buf2,ax
	mov	dx,Memory_Size		;# paragraphs in machine
	cmp	ax,dx			;does start of buf2 exceed mem?
	jnb	badmem			;yes, can't do nothin' without mem
	sub	dx,ax			;# avail paragraphs
	cmp	dx,256			;have at least 4k?
	jnb	havmem			;yes
badmem:
	print_msg msgnum_mem,STDERR	;AN000; ;"INSUFFICIENT MEMORY"
	int	20h			;and quit
havmem:
	cmp	dx,3840 		;over 61440 bytes avail?
	jbe	cmem			;no
	mov	dx,3840 		;yes, set to max of 61440 bytes
cmem:
	mov	cl,4
	shl	dx,cl			;# bytes avail
	and	dx,0f000h		;round down to a 4096-byte boundary
	mov	word ptr mem,dx 	;and save buf2 size in bytes
	mov	byte ptr swt,0		;initialize master switch
	doscall DEFDRV			;AC000; ;get default drive
	inc	al
	mov	curdrv,al		;and save
	or	al,64			;drive to ascii
	mov	cdrv,al 		;save
	xor	ch,ch
	mov	cl,Parm_Area		;length of input parms
	mov	si,129			;where parms are

	mov	current_parm,si 	;AN000; ;pass to parser ptr to input parm buffer
	mov	ordinal,ZERO_PARM_CT	;AN000; ;pass ordinal #, this is begin of parse
	mov	parm_count,FIRST_PARM_CT ;AN000; ;parse the first parm and second parm
	call	parser			;AC000; ;returns first filename in path1, and the
					;AN000; ;second filename in path2.
					;fcb is already formatted with correct drive
	mov	si,offset path2
	mov	di,offset fcb2
	doscall PARSE_FILENAME,01H	;AC000; ;build 2nd fcb from 2nd parm,
					;AC000; ;scan off leading separators
	cmp	al,-1			;invalid drive?
;	$if	e			;AC000; ;Yes, invalid drive
	JNE $$IF146
	    print_msg msgnum_baddrv,STDERR ;AN000; ;"Invalid drive spec."
	    int     20h 		;and quit
;	$else				;AC000;
	JMP SHORT $$EN146
$$IF146:
	    mov     dx,offset CBExit
	    doscall SETVECTOR,23H	;AC000; ;change control break vector, #23h
;	$endif				;AC000;
$$EN146:

	ret				;AN000; ;return to main
more_init endp				;AN000;

cseg	ends
	end
