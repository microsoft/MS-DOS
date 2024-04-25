 page 80,132
;	SCCSID = @(#)copy.asm	1.1 85/05/14
;	SCCSID = @(#)copy.asm	1.1 85/05/14
TITLE	COMMAND COPY routines.

; MODIFICATION HISTORY
;
;   11/01/83 EE  Added a few lines at the end of SCANSRC2 to get multiple
;		 file concatenations (eg copy a.*+b.*+c.*) to work properly.
;   11/02/83 EE  Commented out the code in CPARSE which added drive designators
;		 to tokens which begin with path characters so that PARSELINE
;		 will work correctly.
;   11/04/83 EE  Commented out the code in CPARSE that considered paren's to be
;		 individual tokens.  That distinction is no longer needed for
;		 FOR loop processing.
;   11/17/83 EE  CPARSE upper case conversion is now flag dependent.  Flag is
;		 1 when Cparse is called from COPY.
;   11/17/83 EE  Took out the comment chars around code described in 11/04/83
;		 mod.  It now is conditional on flag like previous mod.
;   11/21/83 NP  Added printf
;   12/09/83 EE  CPARSE changed to use CPYFLAG to determine when a colon should
;		 be added to a token.
;   05/30/84 MZ  Initialize all copy variables.  Fix confusion with destclosed
;		 NOTE: DestHand is the destination handle.  There are two
;		 special values:  -1 meaning destination was never opened and
;		 0 which means that the destination has been openned and
;		 closed.
;   06/01/84 MZ  Above reasoning totally specious.  Returned things to normal
;   06/06/86 EG  Change to fix problem of source switches /a and /b getting
;		 lost on large and multiple file (wildcard) copies.
;   06/09/86 EG  Change to use xnametrans call to verify that source and
;		 destination are not equal.


.xlist
.xcref
	INCLUDE comsw.asm
	INCLUDE DOSSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm
.list
.cref


DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	VERVAL:WORD
	EXTRN	RSRC_XA_SEG:WORD	;AN030;
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BADCD_ptr:word
	EXTRN	COPIED_ptr:word
	EXTRN	Extend_buf_ptr:word	;AN000;
	EXTRN	Extend_buf_sub:byte	;AN000;
	EXTRN	file_name_ptr:word
	EXTRN	INBDEV_ptr:word 	;AC000;
	EXTRN	msg_disp_class:byte	;AN000;
	EXTRN	overwr_ptr:word
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	ALLSWITCH:WORD
	EXTRN	ARGC:BYTE
	EXTRN	ASCII:BYTE
	EXTRN	BINARY:BYTE
	EXTRN	BYTCNT:WORD
	EXTRN	CFLAG:BYTE
	EXTRN	comma:byte
	EXTRN	CONCAT:BYTE
	EXTRN	concat_xa:byte		;AN000;
	EXTRN	copy_num:word		;AC000;
	EXTRN	CPDATE:WORD
	EXTRN	CPTIME:WORD
	EXTRN	cpyflag:byte		;AC000;
	EXTRN	CURDRV:BYTE
	EXTRN	DESTBUF:BYTE
	EXTRN	DestClosed:BYTE
	EXTRN	DESTFCB:BYTE
	EXTRN	DESTFCB2:BYTE
	EXTRN	DESTHAND:WORD
	EXTRN	DESTINFO:BYTE
	EXTRN	DESTISDIR:BYTE
	EXTRN	DESTSIZ:BYTE
	EXTRN	DESTSWITCH:WORD
	EXTRN	DESTTAIL:WORD
	EXTRN	DESTVARS:BYTE
	EXTRN	DIRBUF:BYTE
	EXTRN	expand_star:byte
	EXTRN	FILECNT:WORD
	EXTRN	FIRSTDEST:BYTE
	EXTRN	FRSTSRCH:BYTE
	EXTRN	INEXACT:BYTE
	EXTRN	MELCOPY:BYTE
	EXTRN	MELSTART:WORD
	EXTRN	msg_flag:byte		;AN022;
	EXTRN	NOWRITE:BYTE
	EXTRN	NXTADD:WORD
	EXTRN	objcnt:byte
	EXTRN	one_char_val:byte	;AN000;
	EXTRN	parse_last:word 	;AN018;
	EXTRN	PLUS:BYTE
	EXTRN	plus_comma:byte
	EXTRN	RDEOF:BYTE
	EXTRN	RESSEG:WORD
	EXTRN	SCANBUF:BYTE
	EXTRN	SDIRBUF:BYTE
	EXTRN	src_xa_size:word	;AN000;
	EXTRN	src_xa_seg:word 	;AN000;
	EXTRN	SRCBUF:BYTE
	EXTRN	SRCHAND:WORD
	EXTRN	SRCINFO:BYTE
	EXTRN	SRCISDEV:BYTE
	EXTRN	SRCPT:WORD
	EXTRN	SRCSIZ:BYTE
	EXTRN	SRCTAIL:WORD
	EXTRN	SRCVARS:BYTE
	EXTRN	srcxname:byte
	EXTRN	STARTEL:WORD
	EXTRN	string_ptr_2:word
	EXTRN	TERMREAD:BYTE
	EXTRN	TPA:WORD
	EXTRN	USERDIR1:BYTE
	EXTRN	WRITTEN:WORD
	EXTRN	xa_cp_out:byte		;AN030;
	EXTRN	xa_list_attr:word	;AC030;
TRANSPACE	ENDS


; ******************************************
; COPY CODE
;

TRANCODE	SEGMENT PUBLIC BYTE

	EXTRN	CERROR:NEAR
	EXTRN	COPERR:NEAR
	EXTRN	TCOMMAND:NEAR

	PUBLIC	COPY

ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING
	break	Copy
assume	ds:trangroup,es:trangroup

COPY:
; First order of buisness is to find out about the destination
;
; initialize all internal variables
;
	xor	ax,ax
	mov	copy_num,ax
	mov	SrcPt,AX
	mov	SrcTail,AX
	mov	CFlag,AL
	mov	NxtAdd,AX
	mov	DestSwitch,AX
	mov	StartEl,AX
	mov	DestTail,AX
	mov	DestClosed,AL
	mov	DestSiz,AL
	mov	SrcSiz,AL
	mov	DestInfo,AL
	mov	SrcInfo,AL
	mov	InExact,AL
	mov	DestVars,AL
	mov	SrcVars,AL
	mov	UserDir1,AL
	mov	NoWrite,AL
	mov	RdEOF,AL
	mov	SrcHand,AX
	mov	CpDate,AX
	mov	CpTime,AX
	mov	xa_list_attr,ax 		;AN030; initialize code page to none
	mov	SrcIsDev,AL
	mov	TermRead,AL
	mov	comma,al			;g
	mov	plus_comma,al			;g
	mov	msg_flag,al			;AN022;
	mov	[ALLSWITCH],AX			; no switches
	mov	[ARGC],al			; no arguments
	mov	[PLUS],al			; no concatenation
	mov	[BINARY],al			; Binary not specifically specified
	mov	[ASCII],al			; ASCII not specifically specified
	mov	[FILECNT],ax			; No files yet
	mov	[WRITTEN],ax			; Nothing written yet
	mov	[CONCAT],al			; No concatenation
	mov	[MELCOPY],al			; Not a Mel Hallerman copy
	mov	[concat_xa],al			;AN000; initialize flag for concatenation XA
	mov	MelStart,ax			; Not a Mel Hallerman copy
	mov	word ptr [SCANBUF],ax		; Init buffer
	mov	word ptr [DESTBUF],ax		; Init buffer
	mov	word ptr [SRCBUF],ax		; Init buffer
	mov	word ptr [SDIRBUF],ax		; Init buffer
	mov	word ptr [DIRBUF],ax		; Init buffer
	mov	word ptr [DESTFCB],ax		; Init buffer
	mov	objcnt,al			; Init command line object count
	dec	ax
	mov	DestHand,AX			; destination has never been opened
	mov	[FRSTSRCH],al			; First search call
	mov	[FIRSTDEST],al			; First time
	mov	[DESTISDIR],al			; Don't know about dest
	mov	src_xa_seg,ax			;AN000; initialize attribute segment to -1
	mov	si,81H
	mov	bl,plus_chr			; include '+' as a delimiter
	inc	byte ptr [expand_star]		; want to include * expansion in cparse
	mov	cpyflag,1			; Turn "CPARSE called from COPY flag" on

DESTSCAN:
	xor	bp,bp				; no switches
	mov	di,offset trangroup:SCANBUF
	mov	parse_last,si			;AN018; save start of parsed string
	invoke	CPARSE
	PUSHF					; save flags
	inc	objcnt
	test	bh,80H				; A '+' argument?
	jz	NOPLUS				; no
	mov	[PLUS],1			; yes
NOPLUS:
	test	bh,1				; Switch?
	jz	TESTP2				; no

	test	bp,SwitchV			;AN038; Verify requested?
	jz	not_slashv			;AN038; No - set the switch
	test	[allswitch],SwitchV		;AN038; Verify already entered?
	jz	not_slashv			;AN038; No - set the switch
;AD018; or	[allswitch],FBadSwitch		;AN038; Set up bad switch
	or	BP,FBadSwitch			;AN018; Set up bad switch

not_slashv:					;AN038;
	or	[DESTSWITCH],BP 		; Yes, assume destination
	or	[ALLSWITCH],BP			; keep tabs on all switches

	test	BP,NOT SwitchCopy		;AN018; Bad switch?
	jz	NOT_BAD_SWITCH			;AN018; Switches are okay
	popf					;AN018; fix up stack
	mov	ax,BadSwt_ptr			;AN018; get "Invalid switch" message number
	invoke	Setup_parse_error_msg		;AN018; setup to print the message
	jmp	CERROR				;AC018; exit

NOT_BAD_SWITCH: 				;AN018; switch okay
	POPF					; get flags back
	jc	CHECKDONE			; Hit CR?
	jmp short DESTSCAN

TESTP2:
	POPF					; get flags back
	jc	CHECKDONE			; Hit CR?
	test	bh,80H				; Plus?
	jnz	GOTPLUS 			; Yes, not a separate arg
	inc	[ARGC]				; found a real arg
GOTPLUS:
	push	SI
	mov	ax,[STARTEL]
	mov	SI,offset trangroup:SCANBUF	; Adjust to copy
	sub	ax,SI
	mov	DI,offset trangroup:DESTBUF
	add	ax,DI
	mov	[DESTTAIL],AX
	mov	[DESTSIZ],cl			; Save its size
	inc	cx				; Include the nul
	rep	movsb				; Save potential destination
	mov	[DESTINFO],bh			; Save info about it
	mov	[DESTSWITCH],0			; reset switches
	pop	SI
	jmp	DESTSCAN			;AC018; keep going

CHECKDONE:
	cmp	plus,1				; If a statement like "copy file+" is
	jnz	cdcont				;  entered, complain about it.
	cmp	argc,1
	jnz	cdcont
	cmp	objcnt,2
	jnz	cdcont
	mov	dx,offset trangroup:overwr_ptr
	jmp	coperr
cdcont:
	mov	al,[PLUS]
	mov	[CONCAT],al			; PLUS -> Concatination
	shl	al,1
	shl	al,1
	mov	[INEXACT],al			; CONCAT -> inexact copy
	mov	al,[ARGC]
	or	al,al				; Good number of args?
	jnz	TRY_TOO_MANY			;AC000; there are args, see if too many
	MOV	DX,OFFSET TranGroup:Extend_Buf_ptr  ;AC000; get extended message pointer
	mov	Extend_Buf_ptr,LessArgs_ptr	;AN000; get "Required parameters missing" message number
	jmp	short cerror_parsej		;AN000; exit

TRY_TOO_MANY:
	cmp	al,2
	jbe	ACOUNTOK
	MOV	DX,OFFSET TranGroup:Extend_Buf_ptr  ;AC000; get extended message pointer
	mov	Extend_Buf_ptr,MoreArgs_ptr	;AN000; get "Too many parameters" message number

CERROR_PARSEJ:
	mov	msg_disp_class,parse_msg_class	;AN000; set up parse error msg class
CERROR4J:
	jmp	CERROR				; no, too many

ACOUNTOK:
	mov	bp,offset trangroup:DESTVARS
	cmp	al,1
	jnz	GOT2ARGS
	mov	al,[CURDRV]			; Dest is default drive:*.*
	add	al,capital_A
	mov	ah,':'
	mov	[bp.SIZ],2
	mov	di,offset trangroup:DESTBUF
	stosw
	mov	[DESTSWITCH],0			; no switches on dest
	mov	[bp.INFO],2			; Flag dest is ambig
	mov	[bp.ISDIR],0			; Know destination specs file
	invoke	SETSTARS
GOT2ARGS:
	cmp	[bp.SIZ],2
	jnz	NOTSHORTDEST
	mov	al,':'
	cmp	[DESTBUF+1],al
	jnz	NOTSHORTDEST			; Two char file name
	or	[bp.INFO],2			; Know dest is d:
	mov	di,offset trangroup:DESTBUF + 2
	mov	[bp.ISDIR],0			; Know destination specs file
	invoke	SETSTARS
NOTSHORTDEST:
	mov	di,[bp.TTAIL]
	cmp	byte ptr [DI],0
	jnz	CHKSWTCHES
	mov	dx,offset trangroup:BADCD_ptr
	mov	al,':'
	cmp	byte ptr [DI-2],al
	jnz	CERROR4J			; Trailing '/' error
	mov	[bp.ISDIR],2			; Know destination is d:/
	or	[bp.INFO],6
	invoke	SETSTARS
CHKSWTCHES:
;AD018; mov	ax,[ALLSWITCH]
;AD018; test	ax,NOT SwitchCopy
;AD018; jz	NOT_BAD_SWITCH			;AN000; Switches are okay
;AD018; MOV	DX,OFFSET TranGroup:Extend_Buf_ptr  ;AC000; get extended message pointer
;AD018; mov	Extend_Buf_ptr,BadSwt_ptr	;AN000; get "Invalid switch" message number
;AD018; jmp	short CERROR_PARSEJ		;AC000; Switch specified which is not known

; Now know most of the information needed about the destination

;AD018; NOT_BAD_SWITCH:
if not ibmcopyright
	mov	ax, [allswitch]			; Which switches were requested?  Hmmm?
endif
	TEST	AX,SwitchV			; Verify requested?
	JZ	NOVERIF 			; No
	MOV	AH,GET_VERIFY_ON_WRITE
	INT	int_command			; Get current setting
	PUSH	DS
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	XOR	AH,AH
	MOV	[VERVAL],AX			; Save current setting
	POP	DS
ASSUME	DS:TRANGROUP
	MOV	AX,(SET_VERIFY_ON_WRITE SHL 8) OR 1 ; Set verify
	INT	int_command
NOVERIF:
	xor	bp,bp				; no switches
	mov	si,81H
	mov	bl,plus_chr			; include '+' as a delimiter
SCANFSRC:
	mov	di,offset trangroup:SCANBUF
	invoke	CPARSE				; Parse first source name
	test	bh,1				; Switch?
	jnz	SCANFSRC			; Yes, try again
	or	[DESTSWITCH],bp 		; Include copy wide switches on dest
	test	bp,SwitchB
	jnz	NOSETCASC			; Binary explicit
	cmp	[CONCAT],0
	JZ	NOSETCASC			; Not Concat
	mov	[ASCII],SwitchA 		; Concat -> ASCII copy if no B switch
	mov	[concat_xa],do_xa		;AN000; set up to do XA only on first file
NOSETCASC:
	call	source_set
	call	FRSTSRC
	jmp	FIRSTENT

PUBLIC	EndCopy
ENDCOPY:
	CALL	CLOSEDEST
ENDCOPY2:
	call	deallocate_src_xa		;AN030; deallocate xa segment
	invoke	free_tpa			;AN000; Make sure work area
	invoke	alloc_tpa			;AN000;   is reset properly
	MOV	DX,OFFSET TRANGROUP:COPIED_ptr
	MOV	SI,[FILECNT]
	mov	copy_num,si
	invoke	std_printf
	JMP	TCOMMAND			; Stack could be messed up

SRCNONEXIST:
	cmp	[CONCAT],0
	jnz	NEXTSRC 			; If in concat mode, ignore error
	mov	msg_disp_class,ext_msg_class	     ;AN000; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr   ;AC000; get extended message pointer
	mov	Extend_Buf_ptr,error_file_not_found  ;AN000; get message number in control block
	mov	string_ptr_2,offset trangroup:srcbuf ;AC046; get address of failed string
	mov	Extend_buf_sub,one_subst	     ;AC046; put number of subst in control block
	jmp	COPERR

SOURCEPROC:
	call	source_set
	cmp	[CONCAT],0
	jnz	LEAVECFLAG			; Leave CFLAG if concatination
FRSTSRC:
	xor	ax,ax
	mov	[CFLAG],al			; Flag destination not created
	mov	[NXTADD],ax			; Zero out buffer
	mov	DestClosed,AL
LEAVECFLAG:
	mov	[SRCPT],SI			; remember where we are
	mov	di,offset trangroup:USERDIR1
	mov	bp,offset trangroup:SRCVARS
	invoke	BUILDPATH			; Figure out everything about the source
	mov	si,[SRCTAIL]			; Create the search FCB
	return

NEXTSRC:
	cmp	[PLUS],0
	jnz	MORECP
ENDCOPYJ2:
	jmp	ENDCOPY 			; Done
MORECP:
	xor	bp,bp				; no switches
	mov	si,[SRCPT]
	mov	bl,plus_chr			; include '+' as a delimiter
SCANSRC:
	mov	di,offset trangroup:SCANBUF
	invoke	CPARSE				; Parse first source name
	JC	EndCopyJ2			; if error, then end (trailing + case)
	test	bh,80H
	jz	ENDCOPYJ2			; If no '+' we're done
	test	bh,1				; Switch?
	jnz	SCANSRC 			; Yes, try again
	call	SOURCEPROC
	cmp	comma,1 			;g  was +,, found last time?
	jnz	nostamp 			;g  no - try for a file
	mov	plus_comma,1			;g  yes - set flag
	jmp	srcnonexist			;g  we know we won't find it
nostamp:					;g
	mov	plus_comma,0			;g  reset +,, flag
FIRSTENT:
	mov	di,FCB
	mov	ax,PARSE_FILE_DESCRIPTOR SHL 8
	INT	int_command
	CMP	BYTE PTR [SI],0 		; parse everything?
	JNZ	SrchDone			; no, error, simulate no more search
	mov	ax,word ptr [SRCBUF]		; Get drive
	cmp	ah,':'
	jz	DRVSPEC1
	mov	al,'@'
DRVSPEC1:
	or	al,20h
	sub	al,60h
	mov	ds:[FCB],al
	mov	ah,DIR_SEARCH_FIRST
	call	SEARCH
SrchDone:
	pushf					; Save result of search
	invoke	RESTUDIR1			; Restore users dir
	popf
	jz	NEXTAMBIG0
	jmp	SRCNONEXIST			; Failed
NEXTAMBIG0:
	xor	al,al
	xchg	al,[FRSTSRCH]
	or	al,al
	jz	NEXTAMBIG
SETNMEL:
	mov	cx,12
	mov	di,OFFSET TRANGROUP:SDIRBUF
	mov	si,OFFSET TRANGROUP:DIRBUF
	rep	movsb				; Save very first source name
NEXTAMBIG:
	xor	al,al
	mov	[NOWRITE],al			; Turn off NOWRITE
	mov	di,[SRCTAIL]
	mov	si,offset trangroup:DIRBUF + 1
	invoke	FCB_TO_ASCZ			; SRCBUF has complete name
MELDO:
	cmp	[CONCAT],0
	jnz	SHOWCPNAM			; Show name if concat
	test	[SRCINFO],2			; Show name if multi
	jz	DOREAD
SHOWCPNAM:
	mov	dx,offset trangroup:file_name_ptr
	invoke	std_printf
	invoke	CRLF2
DOREAD:
	call	DOCOPY
	cmp	[CONCAT],0
	jnz	NODCLOSE			; If concat, do not close
	call	CLOSEDEST			; else close current destination
	jc	NODCLOSE			; Concat flag got set, close didn't really happen
	mov	[CFLAG],0			; Flag destination not created
NODCLOSE:
	cmp	[CONCAT],0			; Check CONCAT again
	jz	NOFLUSH
	invoke	FLSHFIL 			; Flush output between source files on
						; CONCAT so LOSTERR stuff works
						; correctly
	TEST	[MELCOPY],0FFH
	jz	NOFLUSH
	jmp	SHORT DOMELCOPY

NOFLUSH:
	call	SEARCHNEXT			; Try next match
	jnz	NEXTSRCJ			; Finished with this source spec
	mov	[DESTCLOSED],0			; Not created or concat ->...
	jmp	NEXTAMBIG			; Do next ambig

DOMELCOPY:
	cmp	[MELCOPY],0FFH
	jz	CONTMEL
	mov	SI,[SRCPT]
	mov	[MELSTART],si
	mov	[MELCOPY],0FFH
CONTMEL:
	xor	BP,BP
	mov	si,[SRCPT]
	mov	bl,plus_chr
SCANSRC2:
	mov	di,OFFSET TRANGROUP:SCANBUF
	invoke	CPARSE
	test	bh,80H
	jz	NEXTMEL 			; Go back to start
	test	bh,1				; Switch ?
	jnz	SCANSRC2			; Yes
	call	SOURCEPROC
	invoke	RESTUDIR1
	mov	di,OFFSET TRANGROUP:DESTFCB2
	mov	ax,PARSE_FILE_DESCRIPTOR SHL 8
	INT	int_command
	mov	bx,OFFSET TRANGROUP:SDIRBUF + 1
	mov	si,OFFSET TRANGROUP:DESTFCB2 + 1
	mov	di,[SRCTAIL]
	invoke	BUILDNAME
	cmp	[CONCAT],0			; Are we concatenating?
	jz	meldoj				; No, continue.
;
; Yes, turn off nowrite because this part of the code is only reached after
; the first file has been dealt with.
;
	mov	[NOWRITE],0
meldoj:
	jmp	MELDO

NEXTSRCJ:
	jmp   NEXTSRC

NEXTMEL:
	call	CLOSEDEST
	xor	ax,ax
	mov	[CFLAG],al
	mov	[NXTADD],ax
	mov	[DESTCLOSED],al
	mov	si,[MELSTART]
	mov	[SRCPT],si
	call	SEARCHNEXT
	jz	SETNMELJ
	jmp	ENDCOPY2
SETNMELJ:
	jmp	SETNMEL

SEARCHNEXT:
	MOV	AH,DIR_SEARCH_NEXT
	TEST	[SRCINFO],2
	JNZ	SEARCH				; Do search-next if ambig
	OR	AH,AH				; Reset zero flag
	return
SEARCH:
	PUSH	AX
	MOV	AH,SET_DMA
	MOV	DX,OFFSET TRANGROUP:DIRBUF
	INT	int_command			; Put result of search in DIRBUF
	POP	AX				; Restore search first/next command
	MOV	DX,FCB
	INT	int_command			; Do the search
	OR	AL,AL
	return

DOCOPY:
	mov	si,offset trangroup:SRCBUF	;g do name translate of source
	mov	di,offset trangroup:SRCXNAME	;g save for name comparison
	mov	ah,xnametrans			;g
	int	int_command			;g

	mov	[RDEOF],0			; No EOF yet

	MOV	AX,EXTOPEN SHL 8		;AC000; open the file
	mov	bx,read_open_mode		;AN000; get open mode for COPY
	xor	cx,cx				;AN000; no special files
	mov	dx,read_open_flag		;AN000; set up open flags
	mov	di,-1				;AN030; no parameter list
	INT	int_command

	jnc	OpenOK
;
; Bogosity:  IBM wants us to issue Access denied in this case.	THey asked
; for it...
;
	jmp	error_on_source 		;AC022; clean up and exit

OpenOK:
	mov	bx,ax				; Save handle
	mov	[SRCHAND],bx			; Save handle
	mov	ax,(FILE_TIMES SHL 8)
	INT	int_command
	jc	src_cp_error			;AN022; If error, exit
	mov	[CPDATE],dx			; Save DATE
	mov	[CPTIME],cx			; Save TIME

	mov	cx,xa_list_attr 		;AN000; get old code page in cx
	push	cx				;AN000; save old attribute
	mov	xa_list_attr,0			;AN000; initialize code page

	mov	ax,(file_times SHL 8)+get_XA	;AC030; get extended attribute size
	mov	si,-1				;AN030; no querylist
	xor	cx,cx				;AN030; indicate we want size
	int	int_command			;AC000;
	jc	src_cp_error			;AN022; If error, exit
	mov	src_xa_size,cx			;AN000; save size
	cmp	cx,0				;AN000; are there any?
	pop	cx				;AN000; get old attribute
	jz	no_cp_get			;AN030; no - don't get attributes

	push	cx				;AN030; save old code page
	invoke	get_file_code_page_tag		;AN000; get file's code page
	pop	cx				;AN030	retrieve old code page
	jnc	no_cp_get			;AN000; no error - continue
src_cp_error:					;AN022;
	jmp	error_on_source 		;AC022; and exit

no_cp_get:
	cmp	[concat],0			;AN000; are we doing concatenation
	jz	get_src_xa			;AN000; no get source extended attrib
	cmp	[concat_xa],do_xa		;AN000; is this the first file?
	jz	get_src_xa			;AN000; yes - get extended attributes
	cmp	cx,xa_list_attr 		;AN000; no - see if code pages match
	jz	no_copy_xa_jmp			;AN000; code pages match - continue
	mov	xa_list_attr,inv_cp_tag 	;AN000; set invalid code page tag
no_copy_xa_jmp: 				;AC022;
	jmp	no_copy_xa			;AN000; don't get extended attributes

get_src_xa:
	call	deallocate_src_xa		;AN030; deallocate any existing XA segment
	cmp	src_xa_size,0			;AN000; are there any extended attributes?
	jz	no_copy_xa_jmp			;AC022; nothing there - don't allocate memory
	push	bx				;AN000; save handle
	invoke	free_tpa			;AN000; need to make free memory, first
	mov	bx,src_xa_size			;AN000; get bytes (size of XA) into bx
	mov	cl,4				;AN000; divide bytes by 16 to convert
	shr	bx,cl				;AN000;    to paragraphs
	inc	bx				;AN000; round up
	mov	ax,(alloc SHL 8)		;AN000; allocate memory for XA
	int	int_command			;AN000;
	pushf					;AN000; save flags
	mov	[src_xa_seg], AX		;AN000; save new segment
	push	ds				;AN030; get resident segment
	mov	ds,[resseg]			;AN030;   and save copy of xa
	assume	ds:resgroup			;AN030;   segment in resident
	mov	[rsrc_xa_seg],ax		;AN030;   in case user breaks
	pop	ds				;AN030;   out or has critical
	assume	ds:trangroup			;AN030;   error
	invoke	alloc_tpa			;AN000; reallocate the work area
	popf					;AN000; restore flags
	pop	bx				;AN000; restore handle
	jnc	Alloc_for_xa_okay		;AN000; no carry - everything okay
	call	closesrc			;AN000; close the source file
	mov	msg_disp_class,ext_msg_class	       ;AN000; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr     ;AC000; get extended message pointer
	mov	Extend_Buf_ptr,error_not_enough_memory ;AN000; get message number in control block
	jmp	cerror				;AN000; exit

Alloc_for_xa_okay:

	mov	ax,(file_times SHL 8)+get_XA	;AN000; get extended attributes
	push	es				;AN000; save es
	mov	es,[src_xa_seg] 		;AN000; get segment for XA list
	xor	di,di				;AN000; offset of return list
	mov	si,-1				;AN030; get all attributes
	mov	cx,[src_xa_size]		;AN000; get size of list
	int	int_command			;AN000; get all the attributes
	pop	es				;AN000; restore es
	jnc	no_copy_xa			;AC022; no error - continue

error_on_source:				;AN022; we have a BAD error
	invoke	set_ext_error_msg		;AN022; set up the error message
	mov	string_ptr_2,offset trangroup:srcbuf ;AN022; get address of failed string
	mov	Extend_buf_sub,one_subst	;AN022; put number of subst in control block
	invoke	std_Eprintf			;AN022; print it
	cmp	[srchand],0			;AN022; did we open the file?
	jz	no_close_src			;AN022; no - don't close
	call	closesrc			;AN022; clean up
no_close_src:					;AN022;
	cmp	[cflag],0			;AN022; was destination created?
	jz	endcopyj3			;AN022; no - just cleanup and exit
	jmp	endcopy 			;AN022; clean up concatenation and exit
endcopyj3:					;AN022;
	jmp	endcopy2			;AN022;
no_copy_xa:
	mov	bx,[srchand]			;AN022; get handle back
	mov	ax,(IOCTL SHL 8)
	INT	int_command			; Get device stuff
	and	dl,devid_ISDEV
	mov	[SRCISDEV],dl			; Set source info
	jz	COPYLP				; Source not a device
	cmp	[BINARY],0
	jz	COPYLP				; ASCII device OK
	mov	dx,offset trangroup:INBDEV_ptr	; Cannot do binary input
	jmp	COPERR

COPYLP:
	mov	bx,[SRCHAND]
	mov	cx,[BYTCNT]
	mov	dx,[NXTADD]
	sub	cx,dx				; Compute available space
	jnz	GOTROOM
	invoke	FLSHFIL
	CMP	[TERMREAD],0
	JNZ	CLOSESRC			; Give up
	mov	cx,[BYTCNT]
GOTROOM:
	push	ds
	mov	ds,[TPA]
ASSUME	DS:NOTHING
	mov	ah,READ
	INT	int_command
	pop	ds
ASSUME	DS:TRANGROUP
	jc	error_on_source 		;AC022; Give up if error
	mov	cx,ax				; Get count
	jcxz	CLOSESRC			; No more to read
	cmp	[SRCISDEV],0
	jnz	NOTESTA 			; Is a device, ASCII mode
	cmp	[ASCII],0
	jz	BINREAD
NOTESTA:
	MOV	DX,CX
	MOV	DI,[NXTADD]
	MOV	AL,1AH
	PUSH	ES
	MOV	ES,[TPA]
	REPNE	SCASB				; Scan for EOF
	POP	ES
	JNZ	USEALL
	INC	[RDEOF]
	INC	CX
USEALL:
	SUB	DX,CX
	MOV	CX,DX
BINREAD:
	ADD	CX,[NXTADD]
	MOV	[NXTADD],CX
	CMP	CX,[BYTCNT]			; Is buffer full?
	JB	TESTDEV 			; If not, we may have found EOF
	invoke	FLSHFIL
	CMP	[TERMREAD],0
	JNZ	CLOSESRC			; Give up
	JMP	SHORT COPYLP

TESTDEV:
	cmp	[SRCISDEV],0
	JZ	CLOSESRC			; If file then EOF
	CMP	[RDEOF],0
	JZ	COPYLP				; On device, go till ^Z
CLOSESRC:
	mov	bx,[SRCHAND]
	mov	ah,CLOSE
	INT	int_command
	return

;
; We are called to close the destination.  We need to note whether or not
; there is any internal data left to be flushed out.
;
CLOSEDEST:
	cmp	[DESTCLOSED],0
	retnz					; Don't double close
	MOV	AL,BYTE PTR [DESTSWITCH]
	invoke	SETASC				; Check for B or A switch on destination
	JZ	BINCLOS
	MOV	BX,[NXTADD]
	CMP	BX,[BYTCNT]			; Is memory full?
	JNZ	PUTZ
	invoke	TRYFLUSH			; Make room for one lousy byte
	jz	NOCONC
CONCHNG:					; Concat flag changed on us
	stc
	return
NOCONC:
	XOR	BX,BX
PUTZ:
	PUSH	DS
	MOV	DS,[TPA]
	MOV	WORD PTR [BX],1AH		; Add End-of-file mark (Ctrl-Z)
	POP	DS
	INC	[NXTADD]
	MOV	[NOWRITE],0			; Make sure our ^Z gets written
	MOV	AX,[WRITTEN]
	ADD	AX,[NXTADD]
	JC	BINCLOS 			; > 1
	CMP	AX,1
	JZ	FORGETITJ			; WRITTEN = 0 NXTADD = 1 (the ^Z)
BINCLOS:
	invoke	TRYFLUSH
	jnz	CONCHNG
	cmp	[WRITTEN],0
ForgetItJ:
	jnz	no_forget			;AC000; Wrote something
	jmp	FORGETIT			;AC000; Never wrote nothing
no_forget:
	MOV	BX,[DESTHAND]
	MOV	CX,[CPTIME]
	MOV	DX,[CPDATE]
	CMP	[INEXACT],0			; Copy not exact?
	JZ	DODCLOSE			; If no, copy date & time
	MOV	AH,GET_TIME
	INT	int_command
	SHL	CL,1
	SHL	CL,1				; Left justify min in CL
	SHL	CX,1
	SHL	CX,1
	SHL	CX,1				; hours to high 5 bits, min to 5-10
	SHR	DH,1				; Divide seconds by 2 (now 5 bits)
	OR	CL,DH				; And stick into low 5 bits of CX
	PUSH	CX				; Save packed time
	MOV	AH,GET_DATE
	INT	int_command
	SUB	CX,1980
	XCHG	CH,CL
	SHL	CX,1				; Year to high 7 bits
	SHL	DH,1				; Month to high 3 bits
	SHL	DH,1
	SHL	DH,1
	SHL	DH,1
	SHL	DH,1				; Most sig bit of month in carry
	ADC	CH,0				; Put that bit next to year
	OR	DL,DH				; Or low three of month into day
	MOV	DH,CH				; Get year and high bit of month
	POP	CX				; Get time back
DODCLOSE:
	CMP	BX,0
	JLE	CloseDone
	MOV	AX,(FILE_TIMES SHL 8) OR 1
	INT	int_command			; Set date and time
	jc	xa_cleanup_err			;AN022; handle error

	mov	ax,(file_times SHL 8)+set_XA	;AN000; set code page
	mov	di,offset trangroup:xa_cp_out	;AC030; offset of attr list
	int	int_command			;AN000;
	jc	xa_cleanup_err			;AN030; exit if error

;
; See if the destination has *anything* in it.	If not, just close and delete
; it.
;
no_xa_cleanup_err:
	mov	ax,(lseek shl 8) + 2		; seek to EOF
	xor	dx,dx
	mov	cx,dx
	int	21h
;
; DX:AX is file size
;
	or	dx,ax
	pushf
	mov	ax,(IOCTL SHL 8) + 0		; get the destination attributes
	int	21h
	push	dx				; save them away
	MOV	AH,CLOSE
	INT	int_command
	pop	dx
	jnc	close_cont			;AN022; handle error on close
	popf					;AN022; get the flags back
xa_cleanup_err: 				;AN022;
	call	cleanuperr			;AN022; attempt to delete the target
	call	DestDelete			;AN022; attempt to delete the target
	jmp	short fileclosed		;AN022; close the file
close_cont:					;AN022; no error - continue
	popf
	jnz	CloseDone
	test	dx,80h				; is the destination a device?
	jnz	CloseDone			; yes, copy succeeded
	call	DestDelete
	jmp	short FileClosed
CloseDone:
	INC	[FILECNT]
FileClosed:
	INC	[DESTCLOSED]
RET50:
	CLC
	return


FORGETIT:
	MOV	BX,[DESTHAND]
	CALL	DODCLOSE			; Close the dest
	call	DestDelete
	MOV	[FILECNT],0			; No files transferred
	JMP	RET50

DestDelete:
	MOV	DX,OFFSET TRANGROUP:DESTBUF
	MOV	AH,UNLINK
	INT	int_command			; And delete it
	return

source_set	proc near

	push	SI
	mov	ax,[STARTEL]
	mov	SI,offset trangroup:SCANBUF	; Adjust to copy
	sub	ax,SI
	mov	DI,offset trangroup:SRCBUF
	add	ax,DI
	mov	[SRCTAIL],AX
	mov	[SRCSIZ],cl			; Save its size
	inc	cx				; Include the nul
	rep	movsb				; Save this source
	mov	[SRCINFO],bh			; Save info about it
	pop	SI
	mov	ax,bp				; Switches so far
	invoke	SETASC				; Set A,B switches accordingly
	invoke	SWITCH				; Get any more switches on this arg
	invoke	SETASC				; Set
	return

source_set	endp


;****************************************************************
;*
;* ROUTINE:	Cleanuperr
;*
;* FUNCTION:	Issues extended error message for destination
;*		if not alreay issued
;*
;* INPUT:	return from INT 21
;*
;* OUTPUT:	none
;*
;****************************************************************

cleanuperr	proc	near			;AN022;

	cmp	msg_flag,0			;AN022; have we already issued a message?
	jnz	cleanuperr_cont 		;AN022; yes - don't issue duplicate error
	invoke	set_ext_error_msg		;AN022; set up error message
	mov	string_ptr_2,offset trangroup:destbuf ;AN022; get address of failed string
	mov	Extend_buf_sub,one_subst	;AN022; put number of subst in control block
	invoke	std_eprintf			;AN022; issue the error message
cleanuperr_cont:				;AN022;

	ret					;AN022; return to caller
cleanuperr	endp				;AN022;

;****************************************************************
;*
;* ROUTINE:	Deallocate_Src_XA
;*
;* FUNCTION:	Deallocates source extended attribute segment
;*		and resets both resident and transient variables.
;*
;*
;* INPUT:	none
;*
;* OUTPUT:	none
;*
;****************************************************************

Deallocate_Src_XA  proc    near 		;AN030;

	cmp	[src_xa_seg],no_xa_seg		;AN030; has any XA segment been allocated
	jz	no_src_xa			;AN030; no - continue
	push	es				;AN030;
	mov	es,src_xa_seg			;AN030; yes - free it
	mov	ax,(Dealloc SHL 8)		;AN030; Deallocate memory call
	int	int_command			;AN030;
	pop	es				;AN030;
	mov	[src_xa_seg],no_xa_seg		;AN030; reset to no segment
	push	ds				;AN030; reinitialize resident
	mov	ds,[resseg]			;AN030;   copy of xa segment
	assume	ds:resgroup			;AN030;
	mov	[rsrc_xa_seg],no_xa_seg 	;AN030; reset to no segment
	pop	ds				;AN030;
	assume	ds:trangroup			;AN030;
no_src_xa:					;AN030;

	ret					;AN030; return to caller
Deallocate_Src_XA  endp 			;AN030;


TRANCODE	ENDS
	END
