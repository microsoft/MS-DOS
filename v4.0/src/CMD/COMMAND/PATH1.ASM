 page 80,132
;	SCCSID = @(#)path1.asm	1.1 85/05/14
;	SCCSID = @(#)path1.asm	1.1 85/05/14
.sall
.xlist
.xcref
INCLUDE DOSSYM.INC
    include comsw.asm
    include comseg.asm
    include comequ.asm
.list
.cref

break <Path.Asm>
;----------------------------------------------------------------------------
;    PATH.ASM contains the routines to perform pathname incovation.  Path and
;    Parse share a temporary buffer and argv[] definitions.  <Path_Search>,
;    given a pathname, attempts to find a corresponding executable or batch
;    file on disk.  Directories specified in the user's search path will be
;    searched for a matching file, if a match is not found in the current
;    directory and if the pathname is actually only an MSDOS filename.
;    <Path_Search> assumes that the parsed command name can be found in
;    argv[0] -- in other words, <Parseline> should be executed prior to
;    <Path_Search>.  Alternatively, the command name and appropriate
;    information could be placed in argv[0], or <Path_Search> could be
;    (easily) modified to make no assumptions about where its input is found.
;    Please find enclosed yet another important routine, <Save_Args>, which
;    places the entire arg/argv[]/argbuf structure on a piece of newly
;    allocated memory.	This is handy for for-loop processing, and anything
;    else that wants to save the whole shebang and then process other command
;    lines.
;
; Alan L, OS/MSDOS				    August 15, 1983
;
; ENTRY:
;   <Path_Search>:	    argv[0].
;   <Save_Args>:	    bytes to allocate in addition to arg structure
; EXIT:
;   <Path_Search>:	    success flag, best pathname match in EXECPATH.
;   <Save_Args>:	    success flag, segment address of new memory
; NOTE(S):
;   *	<Argv_calc> handily turns an array index into an absolute pointer.
;	The computation depends on the size of an argv[] element (arg_ele).
;   *	<Parseline> calls <cparse> for chunks of the command line.  <Cparse>
;	does not function as specified; see <Parseline> for more details.
;   *	<Parseline> now knows about the flags the internals of COMMAND.COM
;	need to know about.  This extra information is stored in a switch_flag
;	word with each command-line argument; the switches themselves will not
;	appear in the resulting arg structure.
;   *	With the exception of CARRY, flags are generally preserved across calls.
;---------------
; CONSTANTS:
;---------------
    DEBUGx	equ	    FALSE	; prints out debug info
;---------------
; DATA:
;---------------

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	baddrv_ptr:word
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg:byte
	EXTRN	BADPMES_ptr:word
	EXTRN	curdrv:byte
	EXTRN	EXECPATH:byte
	EXTRN	search_best_buf:byte
	EXTRN	search_error:word
	EXTRN	string_ptr_2:word
	EXTRN	tpbuf:byte
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE	;AC000;

assume cs:trangroup, ds:trangroup, es:trangroup, ss:nothing

break <Path_Search>
;------------------------------------------------------------------------------
;   PATH_SEARCH tries to find the file it's given, somewhere.  An initial value
; of *argv[0].argstartel == 0 implies that there is no command (empty line
; or 'd:'  or 'd:/').  This check is done in strip; otherwise, strip formats
; the filename/pathname into tpbuf.  Search(tpbuf) is executed to see if we
; have a match, either in the current working directory if we were handed
; a filename, or in the specified directory, given a pathname.	If this call
; fails, and we were given a pathname, then Path_Search fails.	Otherwise,
; Path_Crunch is repeatedly invoked on tpbuf[STARTEL] (if there's a drive
; prefix, we want to skip it) for each pathstring in userpath.	Success on
; either the first invocation of search or on one of the succeeding calls
; sets up the appropriate information for copying the successful pathname
; prefix (if any) into the result buffer, followed by the successful filename
; match (from [search_best_buf]).  The result is returned in in EXECPATH.
; ENTRY:
;   argv[0]		--	command name and associated information
; EXIT:
;   AX			--	non-zero indicates type of file found
;   EXECPATH		--	successful pathname (AX non-zero)
; NOTE(S):
;   1)	Uses the temporary buffer, tpbuf, from the parse routines.
;   2)	Some files are more equal than others.	See search: for rankings.
;   3)	Path_Search terminates as soon as a call to search succeeds, even
;	if search returns an .exe or .bat.
;   5)	Clobbers dma address.

pbuflen 	equ	128		; length of EXECPATH
path_sep_char	equ	';'

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	fbuf:byte
	EXTRN	pathinfo:word
	EXTRN	psep_char:byte
TRANSPACE	ENDS

Procedure   Path_Search,NEAR

	push	BX
	push	CX
	push	DX				; could use a "stack 'em" instruction
	push	SI
	push	DI
	push	BP
	pushf
	test	DS:arg.argv[0].argflags, (MASK wildcard) + (MASK sw_flag)
	jz	path_search_ok

path_failure_jmp:
	jmp	path_failure			; ambiguous commands not allowed

path_search_ok:
	call	store_pchar			; figure out the pathname separator
	mov	DX, OFFSET TRANGROUP:fbuf	; clobber old dma value with
	trap	set_dma 			; a pointer to our dma buffer
	push	ES
	invoke	find_path			; get a handle (ES:DI) on user path
	mov	DS:pathinfo[0], ES		; and squirrel it away
	mov	DS:pathinfo[2], DI		; "old" pathstring pointer
	mov	DS:pathinfo[4], DI		; "new" pathstring pointer
	pop	ES

	mov	BX, pbuflen			; copy/format argv[0] into temp buffer
	mov	SI, OFFSET TRANGROUP:EXECPATH
	invoke	strip
	jc	path_failure_jmp		; if possible, of course

	mov	DX, SI				; search(EXECPATH, error_message)
	mov	[search_error], OFFSET TRANGROUP:BADDRV_ptr
	invoke	search				; must do at least one search
	or	AX, AX				; find anything?
	jz	path_noinit			; failure ... search farther

	mov	BP, AX				; success... save filetype code
	mov	DI, OFFSET TRANGROUP:EXECPATH
	mov	SI, DS:arg.argv[0].argpointer
	mov	CX, DS:arg.argv[0].argstartel
	sub	CX, SI				; compute prefix bytes to copy
;
; We have the number of bytes in the prefix (up to the final component).
; We need to form the complete pathname including leading drive and current
; directory.
;
; Is there a drive letter present?
;

	mov	ah,':'
	cmp	cx,2				; room for drive letter?
	jb	AddDrive			; no, stick it in
	cmp	[si+1],ah			; colon present?
	jz	MoveDrive			; yes, just move it

AddDrive:
	mov	al,curdrv			; get current drive
	add	al,"A"                          ; convert to uppercase letter
	stosw					; store d:
	jmp	short CheckPath

MoveDrive:
	lodsw					; move d:
	stosw
	sub	cx,2				; 2 bytes less to move

CheckPath:
	or	al,20h
	mov	dl,al
	sub	dl,"a"-1                        ; convert to 1-based for current dir
;
; Stick in beginning path char
;
	mov	al,psep_char
	stosb
;
; Is there a leading /?  If so, then no current dir copy is necessary.
; Otherwise, get current dir for DL.
;
	cmp	cx,1				; is there room for path char?
	jb	AddPath 			; no, go add path
	lodsb
	dec	cx
	cmp	al,psep_char			; is there a path separator?
	jz	MovePath			; yes, go move remainder of path
	inc	cx
	dec	si				; undo the lodsb

AddPath:
	SaveReg <SI>
	mov	si,di				; remainder of buffer
	trap	Current_dir
;
; The previous current dir will succeed a previous find_first already worked.
;
; Find end of string.
;
	mov	di,si
	RestoreReg  <SI>
	mov	al,psep_char
	cmp	byte ptr [di],0 		; root (empty dir string)?
	jz	MovePath			; yes, no need for path char

ScanEnd:
	cmp	byte ptr [dI],0 		; end of string?
	jz	FoundEnd
	inc	di
	jmp	ScanEnd
;
; Stick in a trailing path char
;
FoundEnd:
	stosb
;
; Move remaining part of path.	Skip leading path char if present.
;
MovePath:
	cmp	[si],al 			; first char a path char?
	jnz	CopyPath
	inc	si				; move past leading char
	dec	cx				; drop from count

CopyPath:
	jcxz	CopyDone			; no chars to move!
	rep	movsb

CopyDone:
	jmp	path_success			; run off and form complete pathname

path_noinit:
	test	DS:arg.argv[0].argflags, MASK path_sep
	jnz	path_failure			; complete pathname specified ==> fail

	mov	BH, path_sep_char		; semicolon terminates pathstring
	mov	DX, DS:arg.argv[0].argstartel	; this is where the last element starts
	sub	DX, DS:arg.argv[0].argpointer	; form pointer into EXECPATH,
	add	DX, OFFSET TRANGROUP:EXECPATH	; skipping over drive spec, if any

path_loop:
	call	path_crunch			; pcrunch(EXECPATH, pathinfo)
	mov	BP, AX				; save filetype code

	lahf					; save flags, just in case
	or	BP, BP				; did path_crunch find anything?
	jne	path_found
	sahf					; see?	needed those flags, after all!
	jnc	path_loop			; is there anything left to the path?

path_failure:
	xor	AX, AX
;;	jmp	short path_exit 		; 3/3/KK
	jmp	path_exit			;AC000;  3/3/KK

path_found:					; pathinfo[] points to winner
	mov	DI, OFFSET TRANGROUP:EXECPATH
	mov	CX, pathinfo[4] 		; "new" pointer -- end of string
	mov	SI, pathinfo[2] 		; "old" pointer -- beginning of string

;
;	BAS Nov 20/84
;   Look at the pathname and expand . and .. if they are the first element
;   in the pathname (after the drive letter)
;
	push	ES
	push	pathinfo[0]
	pop	ES
	cmp	Byte Ptr ES:[SI+2],'.'          ; Look for Current dir at start of path
	jnz	path_cpy

	push	CX				; Save pointer to end of string
	mov	AL, ES:[SI]
	mov	[DI],AL 			; Copy drive letter, :, and root char
	mov	AL, ES:[SI+1]			; to EXECPATH
	mov	[DI+1],AL
	mov	AL,psep_char
	mov	[DI+2],AL
	push	SI				; Save pointer to begining of string
	mov	DL,ES:[SI]			; Convert device letter for cur dir
	or	DL,20h
	sub	DL,"a"-1
	mov	SI,DI				; pointer to EXECPATH
	add	SI, 3				; Don't wipe out drive and root info
	trap	Current_dir
	invoke	DStrlen 			; Determine length of present info
	add	SI,CX				; Don't copy over drive and root info
	dec	SI
	mov	DI,SI				; Point to end of target string
	pop	SI				; Restore pointer to begining of string
	add	SI, 3				; Point past drive letter, :, .
	pop	CX				; Restore pointer to end of string

path_cpy:
	pop	ES
	sub	CX, SI				; yields character count
	push	DS				; time to switch segments
	push	pathinfo[0]			; string lives in this segment
	pop	DS
	cld
;;	rep	movsb	    3/3/KK		; copy the prefix path into EXECPATH

Kloop:						;AN000;  3/3/KK
	lodsb					;AN000;  3/3/KK
	stosb					;AN000;  3/3/KK
	invoke	testkanj			;AN000;  3/3/KK
	jz	NotKanj1			;AN000;  3/3/KK
	dec	cx				;AN000;  3/3/KK
	JCXZ	PopDone 			;AN000;  Ignore boundary error	 3/3/KK
	movsb					;AN000;  3/3/KK
	dec	cx				;AN000;  3/3/KK
	cmp	cx,1				;AN000;  One char (the terminator) left ? 3/3/KK
	ja	Kloop				;AN000;  no.			 3/3/KK

PopDone:					;AN000;  3/3/KK
	POP	DS				;AN000;  Yes ES:DI->terminator, last char is 3/3/KK
	mov	AL, psep_char			;AN000;       KANJI		  3/3/KK
	jmp	Short path_store		;AN000;  3/3/KK

NotKanj1:
	loop	Kloop
	pop	DS				; return to our segment
	dec	DI				; overwrite terminator
	mov	AL, psep_char			; with a pathname separator
	cmp	al,byte ptr [di-1]
	jz	path_success

path_store:					;AN000;  3/3/KK
	stosb

path_success:
	mov	SI, OFFSET TRANGROUP:search_best_buf
	xor	CX, CX

path_succ_loop:
	lodsb					; append winning filename to path
	stosb					; (including terminating null)
	or	al,al
	jnz	path_succ_loop
	mov	AX, BP				; retrieve filetype code

path_exit:
	popf
	pop	BP
	pop	DI
	pop	SI				; chill out...
	pop	DX
	pop	CX
	pop	BX
	ret
EndProc Path_Search

break <Store_Pchar>
;----------------------------------------------------------------------------
;   STORE_PCHAR determines the pathname-element separator and squirrels
; it away.  In other words, must we say '/bin/ls' or '\bin\ls'?
; ENTRY:
; EXIT:
; NOTE(S):
;   *	Uses <psep_char>, defined in <path_search>.
;---------------
;---------------
Procedure   Store_PChar,NEAR
;---------------

	push	AX
	mov	AL, '/'                         ; is the pathname-element separator
	invoke	pathchrcmp			; a regular slash?
	jz	store_slash			; if yes, remember slash
	mov	al,'\'
	mov	[psep_char], al 		; otherwise, remember back-slash
	pop	ax
	ret

store_slash:
	mov	[psep_char], al
	pop	ax
	return
;---------------
EndProc Store_Pchar
;----------------------------------------------------------------------------

break <Path_Crunch>
;----------------------------------------------------------------------------
; PATH_CRUNCH takes a prefix from a prefix string, and a suffix from
; EXECPATH, and smooshes them into tpbuf.  The caller may supply an
; additional separator to use for breaking up the path-string.	Null is the
; default.  Once the user-string has been formed, search is invoked to see
; what's out there.
; ENTRY:
;   BH			--	additional terminator character
;   SI			--	pointer into pathstring to be dissected
;   DX			--	pointer to stripped filename
; EXIT:
;   AX			--	non-zero (file type), zero (nothing found)
;   SI			--	moves along pathstring from call to call
;   [search_best_buf]	--	name of best file (AX non-zero)
;   [tpbuf]		--	clobbered
; NOTE(S):
;   *	Implicit in this code is the ability to specify when to search
;	the current directory (if at all) through the PATH defined by
;	the user, a la UNIX (e.g., PATH=;c:\bin;c:\etc searches the
;	current directory before the bin and etc directories of drive c).
;---------------
Procedure   Path_Crunch,NEAR
;---------------
	push	BX
	push	CX
	push	DX
	push	DI
	push	SI
	pushf
	call	store_pchar			; figure out pathname separator
	mov	DI, OFFSET TRANGROUP:tpbuf	; destination of concatenated string
	mov	SI, pathinfo[4] 		; "new" pointer to start with
	mov	pathinfo[2], SI 		; becomes "old" pointer
	push	DS				; save old segment pointer
	push	pathinfo[0]			; replace with pointer to userpath's
	pop	DS				; segment
	xor	cl,cl				;AN000;  clear flag for later use 3/3/KK

path_cr_copy:
	lodsb					; get a pathname byte
	or	al,al				; check for terminator(s)
	jz	path_seg			; null terminates segment & pathstring
	cmp	AL, BH
	jz	path_seg			; BH terminates a pathstring segment
	invoke	testkanj			;AN000;  3/3/KK
	jz	NotKanj2			;AN000;  3/3/KK
	stosb					;AN000;  3/3/KK
	movsb					;AN000;  3/3/KK
	MOV	CL,1				;AN000;  CL=1 means latest stored char is DBCS 3/3/KK
	jmp	path_cr_copy			;AN000;  3/3/KK

NotKanj2:					;AN000;  3/3/KK
	xor	cl,cl				;AN000;  CL=0 means latest stored char is SBCS 3/3/KK
	stosb					; save byte in concat buffer
	jmp	path_cr_copy			; loop until we see a terminator

path_seg:
	pop	DS				; restore old data segment
	mov	pathinfo[4], SI 		; save "new" pointer for next time
	mov	BL, AL				; remember if we saw null or not...
						;;; REMOVE NEXT 3 LINES FOR CURDIR SPEC
	xor	AX, AX				; in case nothing in pathstr...
	cmp	DI, OFFSET TRANGROUP:tpbuf	; was there really anything in pathstr?
	je	path_cr_leave			; if nothing was copied, pathstr empty

path_cr_look:					; form complete pathname
	mov	al, psep_char			; add pathname separator for suffix
	or	cl,cl				;AN000;  3/3/KK
	jnz	path_cr_store			;AN000;  this is a trailing byte of ECS code 3/3/KK
	cmp	al,byte ptr [di-1]
	jz	path_cr_l1

path_cr_store:					;AN000;  3/3/KK
	stosb

path_cr_l1:
	mov	SI, DX

path_cr_l2:
	lodsb					; tack the stripped filename onto
	stosb					; the end of the path, up to and
	or	AL, AL				; including the terminating null
	jnz	path_cr_l2
	mov	DX, OFFSET TRANGROUP:tpbuf	; and look for an appropriate file...
	mov	[search_error], OFFSET TRANGROUP:BADPMES_ptr
	invoke	search				; results are in AX & search_best_buf

path_cr_leave:
	or	BL, BL				; did we finish off the pathstring?
	jz	path_cr_empty			; null in BL means all gone...
	popf					; otherwise, plenty left
	clc
	jmp	short path_cr_exit

path_cr_empty:
	popf
	stc

path_cr_exit:
	pop	SI
	pop	DI
	pop	DX
	pop	CX
	pop	BX
	ret
;---------------
EndProc Path_Crunch
;----------------------------------------------------------------------------


trancode    ends
END
