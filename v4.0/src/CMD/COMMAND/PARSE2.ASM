 page 80,132
;	SCCSID = @(#)parse.asm	1.1 85/05/14
;	SCCSID = @(#)parse.asm	1.1 85/05/14
.sall
.xlist
.xcref
    INCLUDE DOSSYM.INC
    INCLUDE DEVSYM.INC
    include comsw.asm
    include comseg.asm
    include comequ.asm
.list
.cref


break <Parse.Asm>
;----------------------------------------------------------------------------
;    PARSE.ASM contains the routines to perform command line parsing.
;    Parse and Path share a buffer and argv[] definitions.
;   Invoking <Parseline> maps the unparsed command line in COMBUF into an
;   array of pointers to the parsed tokens.  The resulting array, argv[],
;   also contains extra information provided by cparse about each token
;   <Parseline> should be executed prior to <Path_Search>
;
; Alan L, OS/MSDOS				    August 15, 1983
;
;
; ENTRY:
;   <Parseline>:	    command line in COMTAB.
; EXIT:
;   <Parseline>:	    success flag, argcnt (number of args), argv[].
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

DATARES 	SEGMENT PUBLIC BYTE
	EXTRN	FORFLAG:BYTE
DATARES     ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	combuf:byte
	EXTRN	cpyflag:byte
	EXTRN	expand_star:byte
	EXTRN	RESSEG:word
	EXTRN	STARTEL:word
TRANSPACE   ENDS

TRANCODE	SEGMENT PUBLIC BYTE	;AC000;
	PUBLIC	argv_calc		; convert array index into address
	PUBLIC	parseline


assume cs:trangroup, ds:trangroup, es:trangroup, ss:nothing


break <Parseline:  Munch on the command line>
;----------------------------------------------------------------------------
;    PARSELINE takes an MSDOS command line and maps it into a UNIX-style
; argv[argvcnt] array.	The most important difference between this array and
; the tradition UNIX format is the extra cparse information included with
; each argument element.
;---------------
; ENTRY:
;	(BL	     special delimiter for cparse -- not implemented)
;---------------
; EXIT:
;	CF	    set if error
;	AL	    error code (carry set).  Note AH clobbered in any event.
;	argv[]	    array of cparse flags and pointers to arguments
;	argvcnt     argument count
;---------------
; NOTE(S):
;	*   BL (special delimiter) is ignored, for now (set to space).
;	*   Parseflags record contains cparse flags, as follows:
;		sw_flag 	--	was this arg a switch?
;		wildcard	--	whether or not it contained a * or ?
;		path_sep	--	maybe it was a pathname
;		unused		--	for future expansion
;		special_delim	--	was there an initial special delimiter?
;	*   argv[] and argvcnt are undefined if CF/AL indicates an error.
;	*   Relationship between input, cparse output, and comtail can be
;	    found in the following chart.  Despite the claim of the cparse
;	    documentation that, "Token buffer always starts d:  for non switch
;	    tokens", such is not the case (see column two, row two).
;	    Similarly, [STARTEL] is not null when the command line is one of
;	    the forms, "d:", "d:\", or "d:/".  In fact, *STARTEL (i.e., what
;	    STARTEL addresses) will be null.  This is clearly just a
;	    documentation error.
;	*   cparse also returns a switch code in BP for each switch it
;	    recognizes on the command line.
;	*   arglen for each token does NOT include the terminating null.
;	*   Finally, note that interesting constructions like 'foodir/*.exe'
;	    parse as three separate tokens, and the asterisk is NOT a wildcard.
;	    For example, 'for %i in (foodir/*.exe) do echo %i' will first
;	    echo 'foodir', then '*', then '.exe'.  Using cparse for command-
;	    line parsing may result in slightly different behavior than
;	    previously observed with the old COMMAND.COM command-line parser.
;
;	    Input		    Cparse		Command Line (80H)
;	\alan\foo.bat		c:\alan\foo.bat 	\alan\foo.bat
;	alan\foo.bat		alan\foo.bat		alan\foo.bat
;	foo.bat 		foo.bat 		foo.bat
;	c:\alan\foo.bat 	c:\alan\foo.bat 	c:\alan\foo.bat
;	c:alan\foo.bat		c:alan\foo.bat		c:alan\foo.bat
;	c:foo.bat		c:foo.bat		c:foo.bat
;---------------
; CONSTANTS:
;---------------
;---------------
; DATA:
;---------------

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg:byte
	EXTRN	argbufptr:word
	EXTRN	comptr:word
	EXTRN	last_arg:word
	EXTRN	tpbuf:byte
TRANSPACE	ENDS

;---------------
parseline:
;---------------

	push	AX				; most of these are clobbered
	push	BX				; by cparse...
	push	CX
	push	DX
	push	DI
	push	SI
	pushf
	mov	cpyflag,0			; Turn "CPARSE called from COPY flag" off

	mov	[LAST_ARG], -1			; last argument at which to accumulate
	xor	ax,ax
	mov	cx,SIZE arg_unit
	mov	di,offset trangroup:arg
	rep	stosb
	mov	argbufptr,offset trangroup:arg.argbuf
	mov	arg.argswinfo, 0		; switch information, and info to date
	mov	arg.argvcnt, 0			; initialize argvcnt/argv[]
	mov	SI, OFFSET TRANGROUP:combuf+2	; prescan leaves cooked input in combuf

; This next section of code (up to pcont:)  makes sure that si is set up for
; parsing.  It should point at COMBUF if FORFLAG is set and arg.argforcombuf
; otherwise.  This is done so that commands can get arg pointers into their
; original command line (or an exact copy of it) in arg_ocomptr.
; Arg.argforcombuf is used so that the for loop processor will always be able
; to get a hold of its original command line; even after COMBUF is blasted by
; the command to be repeated or the transient part of command has been
; reloaded.

	push	ds
	mov	ds,[RESSEG]
	assume	ds:resgroup
	cmp	FORFLAG,0
	pop	ds
	assume	ds:trangroup
	jnz	pcont
	mov	di,OFFSET TRANGROUP:arg.argforcombuf
	xor	ch,ch
	mov	cl,[COMBUF+1]
	inc	cl
	rep	movsb
	mov	si,OFFSET TRANGROUP:arg.argforcombuf

pcont:
	mov	DI, OFFSET TRANGROUP:tpbuf	; destination is temporary token buffer
	mov	BL, ' '                         ; no special delimiter, for now

parseloop:
	mov	comptr,si			; save ptr into original command buffer
	xor	BP, BP				; switch information put here by cparse
	mov	byte ptr [expand_star],0	; don't expand *'s to ?'s
	invoke	scanoff 			; skip leading blanks...
	invoke	cparse				; byte off a token (args in SI, DI, BL)
	jnc	More_prse
	or	BP,BP				; Check for trailing switch character
	jz	parsedone
	call	newarg				; We hit CR but BP is non-zero. The
						;   typical cause of this is that a
						;   switch char IMMEDIATELY preceeds
						;   the CR. We have an argument, but it
						;   is sort of an error.
	jmp	short parsedone 		; We're done (found the CR).

More_prse:
	mov	cpyflag,2			; tell CPARSE that 1st token is done
	call	newarg				; add to argv array (CX has char count)
	jnc	parseloop			; was everything OK?
	jmp	short parse_error		; NO, it wasn't -- bug out (CF set)

parsedone:					; successful completion of parseline
	popf
	clc
	jmp	short parse_exit

parse_error:					; error entry (er, exit) point
	popf
	stc
parse_exit:					; depend on not changing CF
	pop	SI
	pop	DI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret

;---------------
; parseline ends
;----------------------------------------------------------------------------


break <NewArg>
;----------------------------------------------------------------------------
;   NEWARG adds the supplied argstring and cparse data to arg.argv[].
; ENTRY:
;   BH			argflags
;   CX			character count in argstring
;   DI			pointer to argstring
;   comptr		ptr to starting loc of current token in original command
;   [STARTEL]		cparse's answer to where the last element starts
; EXIT:
;   argbufptr		points to next free section of argbuffer
;   arg.argbuf		contains null-terminated argument strings
;   arg.argvcnt 	argument count
;   arg.argv[]		array of flags and pointers
;   arg.arg_ocomptr	ptr to starting loc of current token in original command
;   CF			set if error
;   AL			carry set:  error code; otherwise, zero
;---------------
newarg:
;---------------

	push	BX
	push	CX
	push	DX				; one never knows, do one?
	push	DI
	push	SI
	pushf
	call	arg_switch			; if it's a switch, record switch info
						; LEAVE SWITCH ON COMMAND LINE!!
;;;	jc	newarg_done			; previous arg's switches -- and leave

	cmp	arg.argvcnt, ARGMAX		; check to ensure we've not
	jge	too_many_args			; exceeded array limits
	mov	DH, BH				; save argflags
	mov	BX, arg.argvcnt 		; argv[argvcnt++] = arg data
	inc	arg.argvcnt
	mov	AX, OFFSET TRANGROUP:arg.argv
	call	argv_calc			; convert offset to pointer
	mov	[BX].argsw_word, 0		; no switch information, yet...
	mov	[BX].arglen, CX 		; argv[argvcnt].arglen = arg length
	mov	[BX].argflags, DH		; argv[argvcnt].argflags = cparse flags
	mov	SI, argbufptr
	mov	[BX].argpointer, SI		; argv[argvcnt].argpointer = [argbufptr]
	add	SI, [STARTEL]			; save startel from new location
	sub	SI, DI				; form pointer into argbuf
	mov	[BX].argstartel, SI		; argv[argvcnt].argstartel = new [STARTEL]
	mov	si,[comptr]
	mov	[BX].arg_ocomptr,si		; arg_ocomptr=ptr into original com line

	mov	SI, DI				; now save argstring in argbuffer
	mov	DI, argbufptr			; load the argbuf pointer and make
	add	DI, CX				; sure we're not about to run off
	cmp	DI, OFFSET TRANGROUP:arg.argbuf+ARGBLEN-1
	jge	buf_ovflow			; the end of the buffer (plus null byte)
	sub	DI, CX				; adjust the pointer
	cld
	rep	movsb				; and save the string in argbuffer
	mov	AL, ANULL			; tack a null byte on the end
	stosb
	mov	argbufptr, DI			; update argbufptr after copy

newarg_done:
	popf
	clc
	jmp	short newarg_exit

too_many_args:
	mov	AX, arg_cnt_error
	jmp	short newarg_error

buf_ovflow:
	mov	AX, arg_buf_ovflow

newarg_error:
	popf
	stc

newarg_exit:
	pop	SI
	pop	DI
	pop	DX
	pop	CX
	pop	BX
	ret

;---------------
; NewArg ends
;----------------------------------------------------------------------------


break <Arg_Switch>
;----------------------------------------------------------------------------
;   ARG_SWITCH decides if an argument might really be a switch.  In the
; event that it is, and we can recognize
; ENTRY:
;   As in <newarg>.
; EXIT:
;   CF	    --	    clear (wasn't a switch); set (was a switch)
; NOTE(S):
;   *	The mechanism mapping a switch into a bit-value depends entirely
;	on the order of definition in the <switch_list> variable and the
;	values chosen to define the bits in CMDT:COMEQU.ASM.  Change either
;	<switch_list> or the definitions in CMDT:COMEQU.ASM -- and rewrite
;	this mechanism.  This code taken from CMDT:TCODE.ASM.
;   *	The <switch_list> declared below is redundant to one declared in
;	TDATA.ASM, and used in TCODE.ASM.
;   *	An ugly routine.
;---------------
; CONSTANTS:
;---------------
;   Constants come from the definitions in CMDT:COMEQU.ASM.
;---------------
; DATA:
;---------------

TRANSPACE	SEGMENT PUBLIC BYTE		;AC000;
    extrn   switch_list:byte
    switch_count    EQU     $-switch_list
transpace   ends

;---------------
Arg_Switch:
;---------------

	push	AX
	push	BX
	push	CX
	push	DI
	pushf
	test	BH, MASK sw_flag		; is it a switch? (preserve flag word)
	jz	arg_no_switch0
	cmp	[LAST_ARG], -1			; have we encountered any REAL args yet?
	je	arg_no_switch1			; no, so leading switches don't matter
	mov	BX, [LAST_ARG]			; yes, add switch info to last REAL arg
	mov	AX, OFFSET TRANGROUP:arg.argv
	call	argv_calc
	or	[BX].argsw_word, BP
	or	arg.argswinfo, BP

arg_yes_switch: 				; ah, sweet success...
	popf
	stc
	jmp	short arg_switch_exit

arg_no_switch0:
	mov	AX, arg.argvcnt 		; future switches should then affect
	mov	[LAST_ARG], AX			; this argument

arg_no_switch1: 				; wasn't a switch, or we're pretending
	popf
	clc

arg_switch_exit:
	pop	DI
	pop	CX
	pop	BX
	pop	AX
	ret

;---------------
; Arg_Switch ends
;----------------------------------------------------------------------------


break <Argv_calc>
;----------------------------------------------------------------------------
;   ARGV_CALC maps an array index into a byte-offset from the base of
; the supplied array.  Method used for computing the address is:
;	Array Index * Array Elt Size + Base Addr = Elt Addr
; ENTRY:
;   AX	    --	    base of array
;   BX	    --	    array index
; EXIT:
;   BX	    --	    byte offset
;---------------

argv_calc:
	push	ax				; Save base
	mov	al,bl				; al = array index
	mov	bl,SIZE argv_ele		; bl = size of an argv element
	mul	bl				; ax = base offset
	pop	bx				; Get base
	add	ax,bx				; Add in base offset
	xchg	ax,bx				; Restore ax and put byte offset in bx
	ret

;---------------
; argv_calc ends
;----------------------------------------------------------------------------



trancode    ends
	    end
