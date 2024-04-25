	PAGE	60,132			;
	TITLE	DEBUG.SAL - DEBUGger for PC DOS

;======================= START OF SPECIFICATIONS =========================
;
; MODULE NAME: DEBUG.SAL
;
; DESCRIPTIVE NAME: DEBUGGING TOOL
;
; FUNCTION: PROVIDES USERS WITH A TOOL FOR DEBUGGING PROGRAMS.
;
; ENTRY POINT: START
;
; INPUT: DOS COMMAND LINE
;	 DEBUG COMMANDS
;
; EXIT NORMAL: NA
;
; EXIT ERROR: NA
;
; INTERNAL REFERENCES:
;
; EXTERNAL REFERENCES:
;
;	ROUTINE: DEBCOM1 - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBCOM2 - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBCOM3 - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBASM  - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBUASM - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBMES  - CONTAINS MESSAGE RETRIEVER ROUTINES
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK DEBUG+DEBCOM1+DEBCOM2+DEBCOM3+DEBASM+DEBUASM+DEBERR+
;	      DEBCONST+DEBDATA+DEBMES
;
; REVISION HISTORY:
;
;	AN000	VERSION 4.00 - REVISIONS MADE RELATE TO THE FOLLOWING:
;
;				- IMPLEMENT DBCS HANDLING	DMS:6/17/87
;				- IMPLEMENT DBCS HANDLING	bgb:5/03/88	;an001;bgb
;				- IMPLEMENT MESSAGE RETRIEVER	DMS:6/17/87
;				- > 32 MB SUPPORT		DMS:6/17/87
;
; COPYRIGHT: "MS DOS DEBUG UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988 Microsoft"
;	     "LICENSED MATERIAL - PROPERTY OF Microsoft  "
;
;	MICROSOFT REVISION HISTORY:
;
; Modified 5/4/82 by AaronR to do all I/O direct to devices
; Runs on MS-DOS 1.28 and above
;
; REV 1.20
;	Tab expansion
;	New device interface (1.29 and above)
; REV 2.0
;	line by line assembler added by C. P.
; REV 2.1
;	Uses EXEC system call
; REV 2.2
;	Ztrace mode by zibo.
;	Fix dump display to indent properly
;	Parity nonsense by zibo
;
; REV 2.3 NP
;	Use Printf for all standard output.
;	Change to EXE file
; REV 2.4 ARR
;	Bug fixes. TEST, XCHG instructions reg order reversed.
;	Single step, break point interrupts saved and restored.
;	Access denied given on W to read only file.
;======================= END OF SPECIFICATIONS ===========================

	IF1
	    %OUT    COMPONENT=DEBUG, MODULE=DEBUG
	ENDIF
.XLIST
.XCREF
	INCLUDE DOSSYM.INC		; ALSO VERSION NUMBER
.CREF
.LIST
	INCLUDE DEBEQU.ASM
	IF	SYSVER
; Structure for system call 72
SYSINITVAR  STRUC
DPBHEAD     DD	    ?			; Pointer to head of DPB-FAT list
SFT_ADDR    DD	    ?			; Pointer to first FCB table
; The following address points to the CLOCK device
BCLOCK	    DD	    ?
; The following address is used by DISKSTATCHK it is always
; points to the console input device header
BCON	    DD	    ?			; Console device entry points
MAXSEC	    DW	    0			; Maximum allowed sector size
BUFFHEAD    DD	    ?
CDS	    DD	    ?
SFTFCB	    DD	    ?
KEEP	    DW	    ?
NUMIO	    DB	    0			; Number of disk tables
NCDS	    DB	    ?
DEVHEAD     DD	    ?
SYSINITVAR  ENDS

	ENDIF


;======================= macro equates ===================================

dbcs_delim equ	81h			;an000;delimits dbcs char
asian_blk equ	40h			;an000;asian blank
amer_blk equ	20h			;an000;american blank
quote_char equ	22h			;an000;quote delim "

;======================= end macro equates ===============================


;This segment must be the first loaded since we are using it to make
;a CREATE_PROCESS_DATA_BLOCK system call a la 1.0 and .COM files.
;For this system call CS must point to the Program Prefix Header, so
;by setting up a seperate segment just after the header we can issue
;an INT 21H via a long call.  So don't move this guy around!

A_CREATE_BLOCK SEGMENT

	PUBLIC	CREATE_CALL

;The other arguements to this system call have been set up
;by the caller.

CREATE_CALL PROC FAR
	MOV	AH,CREATE_PROCESS_DATA_BLOCK
	INT	21H
	RET

CREATE_CALL ENDP

A_CREATE_BLOCK ENDS


CODE	SEGMENT PUBLIC
CODE	ENDS

CONST	SEGMENT PUBLIC
CONST	ENDS

CSTACK	SEGMENT STACK
CSTACK	ENDS

DATA	SEGMENT PUBLIC
DATA	ENDS

DG	GROUP	CODE,CONST,CSTACK,DATA

CONST	SEGMENT PUBLIC BYTE
	EXTRN	BADVER:BYTE,ENDMES_PTR:BYTE,CRLF_PTR:BYTE
	IF	IBMJAPAN
	    EXTRN   PARITYMES_PTR:BYTE
	ENDIF
	EXTRN	PROMPT_PTR:BYTE,ADD_PTR:BYTE,HEX_PTR:BYTE
	EXTRN	USER_PROC_PDB:WORD,CSSAVE:WORD,DSSAVE:WORD
	EXTRN	SPSAVE:WORD,IPSAVE:WORD,LINEBUF:BYTE,QFLAG:BYTE
	EXTRN	NEWEXEC:BYTE,HEADSAVE:WORD,LBUFSIZ:BYTE,BACMES_PTR:WORD

	IF	IBMVER
	    EXTRN   DSIZ:BYTE,NOREGL:BYTE,DISPB:WORD
	ENDIF

	IF	SYSVER
	    EXTRN   CONFCB:BYTE,POUT:DWORD,COUT:DWORD,CIN:DWORD,IOBUFF:BYTE
	    EXTRN   IOADDR:DWORD,IOCALL:BYTE,IOCOM:BYTE,IOSTAT:WORD,IOCNT:WORD
	    EXTRN   IOSEG:WORD,COLPOS:BYTE,BADDEV_PTR:BYTE,BADLSTMES_PTR:BYTE
	    EXTRN   LBUFFCNT:BYTE,PFLAG:BYTE
	ENDIF

	EXTRN	NAMESPEC:BYTE

CONST	ENDS

CSTACK	SEGMENT STACK
	DB	(362 - 80H) + 80H DUP(?) ; (362 - 80H) == IBM'S ROM REQUIREMENTS
					; (NEW - OLD) == SIZE TO GROW STACK
CSTACK	ENDS

DATA	SEGMENT PUBLIC BYTE
	EXTRN	ARG_BUF:BYTE,ADD_ARG:WORD,SUB_ARG:WORD,HEX_ARG1:WORD
	EXTRN	HEX_ARG2:WORD,STACK:BYTE, PREV24:DWORD, FIN24:BYTE
	EXTRN	PARSERR:BYTE,DATAEND:WORD,PARITYFLAG:BYTE,DISADD:BYTE
	EXTRN	ASMADD:BYTE,DEFDUMP:BYTE,BYTEBUF:BYTE,BEGSEG:WORD
	EXTRN	BPINTSAV:DWORD,SSINTSAV:DWORD ;ARR 2.4
	EXTRN	CREATE_LONG:DWORD

	extrn	lbtbl:dword		;an000;lead byte table pointer

DATA	ENDS

	EXTRN	PRINTF:NEAR		;ac000;changed to NEAR call

CODE	SEGMENT PUBLIC
	ASSUME	CS:DG,DS:NOTHING,ES:NOTHING,SS:CSTACK

	PUBLIC	RESTART
	PUBLIC	STD_PRINTF,PRINTF_CRLF
	PUBLIC	HEX_ADDRESS_ONLY,HEX_ADDRESS_STR
	PUBLIC	RESTART,SET_TERMINATE_VECTOR,DABORT,TERMINATE,COMMAND
	PUBLIC	FIND_DEBUG,CRLF,BLANK,TAB,INBUF,SCANB,SCANP
	PUBLIC	HEX,OUTSI,OUTDI,DIGIT,BACKUP,RBUFIN
	public	test_lead							;an001;bgb
	public	test1								;an001;bgb

	IF	SYSVER
;	    PUBLIC  SETUDEV,DEVIOCALL				; kwc 12/10/86
	    PUBLIC  SETUDEV		; kwc 12/10/86
	    EXTRN   DISPREG:NEAR,INPT:NEAR
	ENDIF

	EXTRN	PERR:NEAR,COMPARE:NEAR,DUMP:NEAR,ENTERDATA:NEAR,FILL:NEAR
	EXTRN	GO:NEAR,INPUT:NEAR,LOAD:NEAR,MOVE:NEAR,NAMED:NEAR
	EXTRN	REG:NEAR,SEARCH:NEAR,DWRITE:NEAR,UNASSEM:NEAR,ASSEM:NEAR
	EXTRN	OUTPUT:NEAR,ZTRACE:NEAR,TRACE:NEAR,GETHEX:NEAR,GETEOL:NEAR
	EXTRN	PREPNAME:NEAR,DEFIO:NEAR,SKIP_FILE:NEAR,DEBUG_FOUND:NEAR
	EXTRN	TRAPPARITY:NEAR,RELEASEPARITY:NEAR
	extrn	pre_load_message:near	;an000;load messages
	extrn	debems:near		;an000;ems support


	DB	100H DUP (?)

START:
	JMP	SHORT DSTRT

HEADER	DB	"Vers 2.40"

DSTRT:
;=========================================================================
; invoke PRE_LOAD_MESSAGE here.  If the messages were not loaded we will
; exit with an appropriate error message.
;
;	Date	   : 6/14/87
;=========================================================================

	push	ds			;an000;save regs
	push	es			;an000;save resg

	push	cs			;an000;transfer cs
	pop	ds			;an000;    to ds

	push	cs			;an000;transfer cs
	pop	es			;an000;    to es
	assume	ds:dg,es:dg		;an000;assume them
	call	PRE_LOAD_MESSAGE	;an000;invoke SYSLOADMSG
;	$if	c			;an000;if the load was unsuccessful
	JNC $$IF1
	    mov     ax,(exit shl 8)	;an000;exit EDLIN.  PRE_LOAD_MESSAGE
					;      has already said why
	    int     21h 		;an000;exit
;	$endif				;an000;
$$IF1:

	pop	es			;an000;restore regs.
	pop	ds			;an000;
	assume	ds:nothing,es:nothing	;an000;back to original

	MOV	AX,(GET_INTERRUPT_VECTOR SHL 8) OR VEC_BREAKPOINT ;get original contents
	INT	21H			;  of the BREAKPOINT vector

	MOV	WORD PTR [BPINTSAV],BX	;  and save that vector for later
	MOV	WORD PTR [BPINTSAV+WORD],ES ; restoration

	MOV	AX,(GET_INTERRUPT_VECTOR SHL 8) OR VEC_SING_STEP ;get original contents
	INT	21H			;  of the SINGLE STEP vector

	MOV	WORD PTR [SSINTSAV],BX	;  and save that vector for later
	MOV	WORD PTR [SSINTSAV+WORD],ES ; restoration

	MOV	BEGSEG,DS		; save beginning DS
	PUSH	CS			; repair damaged ES to be
	POP	ES			;  back to just like CS
	XOR	SI,SI			; set source and destination
	XOR	DI,DI			;  indices both to zero
	MOV	CX,256			; set count to size of PSP
	REP	MOVSB			; move to es:[di] from ds:[si]
	PUSH	CS			; set up DS to be just like CS
	POP	DS			;  to match .COM rules of addressability
	ASSUME	DS:DG,ES:DG		; like CS, also have DS and DS as bases

	CALL	TRAPPARITY		; scarf up those parity guys
	MOV	AH,GET_CURRENT_PDB	;(undocumented function call - 51h)
	INT	21H

	MOV	[USER_PROC_PDB],BX	; Initially set to DEBUG

	IF	SYSVER
	    MOV     [IOSEG],CS
	ENDIF

	MOV	[PARSERR],AL


	IF	SYSVER
	    MOV     AH,GET_IN_VARS	;(undocumented function call - 52h)
	    INT     21H

	    LDS     SI,ES:[BX.BCON]	; get system console device
	    ASSUME  DS:NOTHING

	    MOV     WORD PTR CS:[CIN+WORD],DS ;save vector to console input device
	    MOV     WORD PTR CS:[CIN],SI
	    MOV     WORD PTR CS:[COUT+WORD],DS ;save vector to console output device
	    MOV     WORD PTR CS:[COUT],SI
	    PUSH    CS			; restore DS to be
	    POP     DS			;  just like CS, as before
	    ASSUME  DS:DG

	    MOV     DX,OFFSET DG:CONFCB ; get system printer device
	    MOV     AH,FCB_OPEN 	; open system printer "PRN"
	    INT     21H

	    OR	    AL,AL		; open ok?
	    JZ	    GOTLIST		; yes, it was there

	    MOV     DX,OFFSET DG:BADLSTMES_ptr ; no list file found...
	    CALL    STD_PRINTF		; tell user

	    CALL    RBUFIN		; ask for a new one

	    CALL    CRLF

	    MOV     CL,[LBUFFCNT]
	    OR	    CL,CL
	    JZ	    NOLIST1		; User didn't specify one

	    XOR     CH,CH
	    MOV     DI,OFFSET DG:(CONFCB + BYTE)
	    MOV     SI,OFFSET DG:LINEBUF ; get one from input line
	    REP     MOVSB
	    MOV     DX,OFFSET DG:CONFCB
	    MOV     AH,FCB_OPEN 	; try to open it
	    INT     21H

	    OR	    AL,AL
	    JZ	    GOTLIST		; yep, use it...

	    MOV     DX,OFFSET DG:BADDEV_Ptr ; complain again
	    CALL    STD_PRINTF
NOLIST1:				; kwc 12/10/86
	    MOV     WORD PTR [POUT+WORD],CS ; use null device for printer
	    MOV     WORD PTR [POUT],OFFSET DG:LONGRET
	    JMP     NOLIST

XXX	    PROC    FAR
LONGRET:
	    RET
XXX	    ENDP
	ENDIF

GOTLIST:
;DX = OFFSET OF 'CONFCB', WHICH HAS JUST BEEN OPENED OK
	IF	SYSVER
	    MOV     SI,DX
;	    LDS     SI,DWORD PTR DS:[SI.FCB_FIRCLUS]		; KWC 12/10/86
	    LDS     SI,DWORD PTR DS:[SI.FCB_NSLD_DRVPTR] ; KWC 12/10/86
	    ASSUME  DS:NOTHING

	    MOV     WORD PTR CS:[POUT+WORD],DS
	    MOV     WORD PTR CS:[POUT],SI
	ENDIF
NOLIST:
	MOV	AX,CS			;restore the DS and ES segregs
	MOV	DS,AX			; to become once again just like CS
	MOV	ES,AX
	ASSUME	DS:DG,ES:DG

; Code to print header
;	MOV	DX,OFFSET DG:HEADER_PTR
;	CALL	STD_PRINTF

	CALL	SET_TERMINATE_VECTOR

; Save the current INT 24 vector.  We will need this to link to the previous
; handler for handling of int 24 output.
	PUSH	ES			; save it, about to clobber it...
	MOV	AX,(GET_INTERRUPT_VECTOR SHL 8) + VEC_CRIT_ERR ; get original contents
	INT	21H			; of the int 24h vector

	MOV	WORD PTR PREV24,BX	; remember what int 24h used to
	MOV	WORD PTR PREV24+WORD,ES ;  point to
	POP	ES			; restore ES to be like CS and DS

	MOV	AX,(SET_INTERRUPT_VECTOR SHL 8) + VEC_CRIT_ERR ; change int 24h to
	MOV	DX,OFFSET DG:MY24	; point to my own int 24h handler
	INT	21H

	IF	SETCNTC
	    MOV     AL,VEC_CTRL_BREAK	; Set vector 23H
	    MOV     DX,OFFSET DG:DABORT
	    INT     21H
	ENDIF

	MOV	DX,CS			;get para of where this pgm starts
	MOV	AX,OFFSET DG:DATAEND+15 ;get offset of end of this program
	MOV	CL,4			; (plus 15 padding for rounding)
	SHR	AX,CL			; adjusted to number of paragraphs
	ADD	DX,AX			;get para of where this pgm ends
	MOV	AX,CS
	SUB	AX,BEGSEG		; add in size of printf
	ADD	DX,AX			; create program segment here
	CALL	[CREATE_LONG]		; and call special routine

	MOV	AX,DX
; Initialize the segments
	MOV	DI,OFFSET DG:DSSAVE
	CLD
	STOSW
	STOSW
	STOSW
	STOSW
	MOV	WORD PTR [DISADD+WORD],AX
	MOV	WORD PTR [ASMADD+WORD],AX
	MOV	WORD PTR [DEFDUMP+WORD],AX

	MOV	AX,100H
	MOV	WORD PTR[DISADD],AX
	MOV	WORD PTR[ASMADD],AX
	MOV	WORD PTR [DEFDUMP],AX

	MOV	DS,DX
	MOV	ES,DX
	ASSUME	DS:NOTHING,ES:NOTHING

	MOV	DX,80H
	MOV	AH,SET_DMA
	INT	21H			; Set default DMA address to 80H
; Set up initial stack.  We already have a 'good' stack set up already.  DS:6
; has the number of bytes remaining in the segment.  We should take this
; value, add 100h and use it as the Stack pointer.
	MOV	AX,WORD PTR DS:[6]	; get bytes remaining
	MOV	BX,AX
	ADD	AX,100h

;	MOV	BX,AX
;	CMP	AX,0FFF0H
;	PUSH	CS
;	POP	DS
;	JAE	SAVSTK
;	MOV	AX,WORD PTR DS:[6]
;	PUSH	BX
;	MOV	BX,OFFSET DG:DATAEND + 15
;	AND	BX,0FFF0H		; Size of DEBUG in bytes (rounded up to PARA)
;	SUB	AX,BX
;	POP	BX
;SAVSTK:
	PUSH	CS
	POP	DS
	ASSUME	DS:DG
	PUSH	BX			; bx is no. bytes remaining from PSP+6
	DEC	AX			; ax was no. bytes remaining +100h
	DEC	AX			; back up one word from end of new stack
	MOV	BX,AX			; set base to point to last word in new stack
	MOV	WORD PTR ES:[BX],0	; set final word in new stack to zero
	POP	BX			; back to beginning of new stack area
	MOV	SPSAVE,AX		; remember where new stack is
	DEC	AH
	MOV	ES:WORD PTR [6],AX	; change PSP to show usage of
	SUB	BX,AX			; new stack area
	MOV	CL,4
	SHR	BX,CL
	ADD	ES:WORD PTR [8],BX

	IF	IBMVER
; Get screen size and initialize display related variables
	    MOV     AH,15		;function = "request current video state"
	    INT     10H 		;set al=screen mode
					;    ah=no. char cols on screen
					;    bh=current active display page
	    CMP     AH,40		;is screen in 40 col mode?
	    JNZ     PARSCHK		; no, skip
					; yes, 40 col, continue
					;next fields defined in 'debconst.asm'
	    MOV     BYTE PTR DSIZ,7	; originally assembled as 0fh
	    MOV     BYTE PTR NOREGL,4	; originally assembled as 8
	    MOV     DISPB,64		; originally assembled as 128
	ENDIF

PARSCHK:


	call	DEBUG_LEAD_BYTE 	;an000;build the dbcs env. table
					;      of valid dbcs lead bytes

;=========================================================================
; prep_command_line requires the use of ds:si.	ds is left intact for
; the call.  si is initialized to point to the command line input buffer.
; ds and si are saved since we stomp all over them in prep_command_line.
;=========================================================================

	push	si			;an000;save si

	mov	si,81h			;an000;point to command line
	call	prep_command_line	;an000;invoke command line conversion

	pop	si			;an000;restore si

;=========================================================================
; we have prepped the command line for dbcs.  we can now enter the old
; routines.
;=========================================================================

; Copy rest of command line to test program's parameter area
	MOV	DI,FCB			;es[di]=to be filled with unopened FCB
	MOV	SI,81H			;ds[si]=command line to parse
	MOV	AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR SET_DRIVEID_OPTION
					;func=29H, option al=1, which
					; says, drive id byte in fcb is set
					; only if drive specified in command
					; line being parsed.
	INT	21H			;parse filename from command to fcb
					; ds:si=points to first char AFTER parsed filename
					; es:di=points to first byte of formatted FCB

	CALL	SKIP_FILE		; Make sure si points to delimiter
test1:					;for testing only - u can remove this
	CALL	PREPNAME

	PUSH	CS			;restore ES to point to the
	POP	ES			;  common group
FILECHK:
	MOV	DI,80H			;point to byte in PSP defining parm length
	CMP	BYTE PTR ES:[DI],0	; ANY STUFF FOUND?
	JZ	COMMAND 		; no parms, skip
					; yes parms, continue
FILOOP:
	INC	DI			;set index to first/next char in parm text
	CMP	BYTE PTR ES:[DI],CR	; carriage return? (at end of parms)
	JZ	COMMAND 		; yes, at end of parms
					; no, not at end of parms yet, continue
	CMP	BYTE PTR ES:[DI],CHAR_BLANK ; is this parm text char a blank?
	JZ	FILOOP			; yes, a blank, skip
					; no, not a blank, continue
	CMP	BYTE PTR ES:[DI],CHAR_TAB ; is this parm text char a tab?
	JZ	FILOOP			; yes, a tab, skip
					; no, not a tab, continue
	OR	[NAMESPEC],1		; set flag to indicate
					;  we have a specified file
					; (this could be set by "N" command also)
	CALL	DEFIO			; READ in the specified file

	PUSH	CS			;restore DS to point to the
	POP	DS			; common group

					;perform self-relocation on some internal vectors:
	MOV	AX,CSSAVE		; pick up the seg id to go to vectors
	MOV	WORD PTR DISADD+WORD,AX ;  shove it into the segid portion
	MOV	WORD PTR ASMADD+WORD,AX ;  of these two vectors
	MOV	AX,IPSAVE		; pick up the offset to go to vectors
	MOV	WORD PTR DISADD,AX	;  shove it into the offset portion
	MOV	WORD PTR ASMADD,AX	;  of these two vectors
COMMAND:
	CLD
	MOV	AX,CS
	MOV	DS,AX
	MOV	ES,AX
	cli				;disable before setting up the stack - EMK
	MOV	SS,AX			;now everything points to the same group
	ASSUME	SS:DG

	MOV	SP,OFFSET DG:STACK
	STI				;re-enable
	CMP	[PARITYFLAG],0		; did we detect a parity error?
	JZ	GOPROMPT		; no, go prompt
					; yes, parity error, continue
	MOV	[PARITYFLAG],0		; reset flag
	IF	IBMJAPAN
	    MOV     DX,OFFSET DG:PARITYMES_PTR
	    CALL    STD_PRINTF		;display msg about parity error
	ENDIF
GOPROMPT:
	MOV	DX,OFFSET DG:PROMPT_PTR ;display the user prompt request
	CALL	STD_PRINTF

	CALL	INBUF			; Get command line
; From now and throughout command line processing, DI points
; to next character in command line to be processed.
	CALL	SCANB			; Scan off leading blanks

	JZ	COMMAND 		; if zero, Null command, go get another
					; nonzero, got something in response
	LODSB				; AL=first non-blank character
; Prepare command letter for table lookup
; converts the first non-blank (assumed to be the command letter)
; to in index in the "comtab" array.
	SUB	AL,UPPER_A		; Low end range check
	JB	ERR1

	CMP	AL,UPPER_Z - UPPER_A	; Upper end range check
	JA	ERR1

	SHL	AL,1			; Times two
	CBW				; Now a 16-bit quantity
	XCHG	BX,AX			; In BX we can address with it
	CALL	CS:[BX+COMTAB]		; Execute command

	JMP	SHORT COMMAND		; Get next command
ERR1:
	JMP	PERR

SET_TERMINATE_VECTOR:
	PUSH	DS
	PUSH	CS
	POP	DS
	MOV	AX,(SET_INTERRUPT_VECTOR SHL 8) OR VEC_TERM_ADDR ; Set vector 22H
	MOV	DX,OFFSET DG:TERMINATE
	INT	21H

	POP	DS
	RET

RESTORE_DEB_VECT:
	PUSH	DS
	PUSH	DX
	PUSH	AX
	LDS	DX,CS:[BPINTSAV]
	MOV	AX,(SET_INTERRUPT_VECTOR SHL 8) OR VEC_BREAKPOINT ;Vector 3
	INT	21H

	LDS	DX,CS:[SSINTSAV]
	MOV	AX,(SET_INTERRUPT_VECTOR SHL 8) OR VEC_SING_STEP ;Vector 1
	INT	21H

	POP	AX
	POP	DX
	POP	DS
	RET

; Internal INT 24 handler.  We allow our parent's handler to decide what to do
; and how to prompt.  When our parent returns, we note the return in AL.  If
; he said ABORT, we need to see if we are aborting ourselves.  If so, we
; cannot turn it into fail; we may get a cascade of errors due to the original
; cause.  Instead, we do the ol' disk-reset hack to clean up.  This involves
; issuing a disk-reset, ignoring all errors, and then returning to the caller.
MY24:
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

; If we are already inside an INT 24, just ignore this error
	TEST	FIN24,-1
	JZ	DO24

	MOV	AL,0			; signal ignore
	IRET

; Let the user decide what to do
DO24:
	PUSHF
	CALL	PREV24			; simulate INT 24 to him

	CMP	AL,2			; was it ABORT?
	JNZ	DOIRET			; no, let it happen

	PUSH	AX
	PUSH	BX
	MOV	AH,GET_CURRENT_PDB	; find out who's terminating
	INT	21H

	CMP	BX,BEGSEG		; is it us?
	POP	BX
	POP	AX
	JZ	DORESET 		; no, let it happen

DOIRET:
	IRET

; We have been instructed to abort ourselves.  Since we can't do this, we will
; perform a disk reset to flush out all buffers and then ignore the errors we
; get.
DORESET:
	MOV	FIN24,-1		; signal that we ignore errors
	MOV	AH,DISK_RESET
	INT	21H			; clean out cache

	MOV	FIN24,0 		; reset flag
	JMP	COMMAND

TERMINATE:
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

	CMP	QFLAG,0
	JNZ	QUITING

	MOV	AX,BEGSEG
	MOV	USER_PROC_PDB,AX
	CMP	NEWEXEC,0
	JZ	NORMTERM

	MOV	AX,CS
	MOV	DS,AX
	ASSUME	DS:DG
					;is CLI/STI needed here ? - emk
	CLI
	MOV	SS,AX
	ASSUME	SS:DG

	MOV	SP,OFFSET DG:STACK
	STI
	MOV	AX,HEADSAVE
	JMP	DEBUG_FOUND

NORMTERM:
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

	PUSH	CS
	POP	DS
	ASSUME	DS:DG

	MOV	DX,OFFSET DG:ENDMES_PTR
	JMP	SHORT RESTART

QUITING:
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

	CALL	RESTORE_DEB_VECT

	MOV	AX,(EXIT SHL 8)
	INT	21H

RESTART:
	CALL	STD_PRINTF
DABORT:
	MOV	AX,CS
	MOV	DS,AX
	ASSUME	DS:DG

					;is CLI\STI needed here? - emk
	CLI
	MOV	SS,AX
	ASSUME	SS:DG

	MOV	SP,OFFSET DG:STACK
	STI
;;;;;;	CALL	CRLF

	JMP	COMMAND

	IF	SYSVER
SETUDEV:
	    MOV     DI,OFFSET DG:CONFCB
	    MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR SET_DRIVEID_OPTION
	    INT     21H

	    CALL    USERDEV

	    JMP     DISPREG

USERDEV:
	    MOV     DX,OFFSET DG:CONFCB
	    MOV     AH,FCB_OPEN
	    INT     21H

	    OR	    AL,AL
	    JNZ     OPENERR

	    MOV     SI,DX
;	    TEST    BYTE PTR [SI.FCB_DEVID],080H ; Device?	; KWC 12/10/86
;	    JZ	    OPENERR		; NO			; KWC 12/10/86
	    MOV     AL,BYTE PTR [SI.FCB_NSL_DRIVE] ; KWC 12/10/86
	    AND     AL,NOT FCBMASK	; KWC 12/10/86
	    CMP     AL,0C0H		; KWC 12/10/86
	    JNE     OPENERR		; KWC 12/10/86
	    XOR     AL,AL		; KWC 12/10/86

;	    LDS     SI,DWORD PTR [CONFCB.FCB_FIRCLUS]		; KWC 12/10/86
	    LDS     SI,DWORD PTR [CONFCB.FCB_NSLD_DRVPTR] ; KWC 12/10/86
	    MOV     WORD PTR CS:[CIN],SI
	    MOV     WORD PTR CS:[CIN+WORD],DS

	    MOV     WORD PTR CS:[COUT],SI
	    MOV     WORD PTR CS:[COUT+WORD],DS
	    PUSH    CS
	    POP     DS
	    RET

OPENERR:
	    MOV     DX,OFFSET DG:BADDEV_PTR
	    CALL    STD_PRINTF

	    RET
	ENDIF
; Get input line. Convert all characters NOT in quotes to upper case.
INBUF:
	CALL	RBUFIN

;=========================================================================
; prep_command_line requires the use of ds:si.	ds is left intact for
; the call.  si is initialized to point to the command line input buffer.
; ds and si are saved since we stomp all over them in prep_command_line.
;=========================================================================

	push	si			;an000;save si

	mov	si,offset dg:linebuf	;an000;point to command line
	call	prep_command_line	;an000;invoke command line conversion

	pop	si			;an000;restore si

;=========================================================================
; we have prepped the command line for dbcs.  we can now enter the old
; routines.
;=========================================================================

	MOV	SI,OFFSET DG:LINEBUF
	MOV	DI,OFFSET DG:BYTEBUF

CASECHK:

	LODSB

	call	Test_Lead			;DBCS lead byte 		;an000; dms;
;	$if	c				;yes - ignore 2nd. byte 	;an000; dms;
	JNC $$IF3
		stosb				;save the byte			;an000; dms;
		lodsb				;pick up the 2nd. character	;an000; dms;
		stosb				;save it also			;an000; dms;
		jmp	CaseChk 		;read next character		;an000; dms;
;	$endif					;				;an000; dms;
$$IF3:

	CMP	AL,LOWER_A
	JB	NOCONV

	CMP	AL,LOWER_Z
	JA	NOCONV

	ADD	AL,UPPER_A - LOWER_A	; Convert to upper case
NOCONV:
	STOSB
	CMP	AL,CR
	JZ	INDONE

	CMP	AL,DOUBLE_QUOTE
	JZ	QUOTSCAN

	CMP	AL,SINGLE_QUOTE
	JNZ	CASECHK

QUOTSCAN:
	MOV	AH,AL
KILLSTR:
	LODSB
	STOSB
	CMP	AL,CR			;CARRIAGE RETURN?
	JZ	INDONE

	CMP	AL,AH
	JNZ	KILLSTR

	JMP	SHORT CASECHK

INDONE:
	MOV	SI,OFFSET DG:BYTEBUF
	CALL	CRLF

	RET

; Physical backspace - blank, backspace, blank
BACKUP:
	PUSH	DX
	MOV	DX,OFFSET DG:BACMES_PTR
	CALL	STD_PRINTF

	POP	DX
	RET

; Scan for parameters of a command
SCANP:
	CALL	SCANB			; Get first non-blank

	CMP	BYTE PTR [SI],CHAR_COMMA ; One comma between params OK
	JNE	EOLCHK			; If not comma, we found param

	INC	SI			; Skip over comma
; Scan command line for next non-blank character
SCANB:
	PUSH	AX
SCANNEXT:
	LODSB
	CMP	AL,CHAR_BLANK		;is this char a "blank"?
	JZ	SCANNEXT

	CMP	AL,CHAR_TAB		;is this char a "tab"?
	JZ	SCANNEXT

	DEC	SI			; Back to first non-blank
	POP	AX
EOLCHK:
	CMP	BYTE PTR [SI],CR	;CARRIAGE RETURN
	RET

; Hex addition and subtraction
HEXADD:
	MOV	CX,4
	CALL	GETHEX

	MOV	DI,DX
	MOV	CX,4
	CALL	GETHEX

	CALL	GETEOL

	PUSH	DX
	ADD	DX,DI
	MOV	[ADD_ARG],DX
	POP	DX
	SUB	DI,DX
	MOV	[SUB_ARG],DI
	MOV	DX,OFFSET DG:ADD_PTR
	CALL	PRINTF_CRLF

	RET

; Put the hex address in DS:SI in the argument list for a call to printf
OUTSI:
	MOV	CS:[HEX_ARG1],DS
	MOV	CS:[HEX_ARG2],SI
	RET

;Put the hex address in ES:DI in the argument list for a call to printf
OUTDI:
	MOV	[HEX_ARG1],ES
	MOV	[HEX_ARG2],DI
	RET

HEX_ADDRESS_ONLY:
	MOV	BYTE PTR [ARG_BUF],0
HEX_ADDRESS_STR:
	MOV	DX,OFFSET DG:HEX_PTR
STD_PRINTF:
	PUSH	DX
	CALL	PRINTF
	POP	DX			;ac000;restore dx

	RET

PRINTF_CRLF:
	PUSH	DX
	CALL	PRINTF
	POP	DX			;ac000;restore dx
CRLF:
	MOV	DX,OFFSET DG:CRLF_PTR
	PUSH	DX
	CALL	PRINTF
	POP	DX			;ac000;restore dx

	RET

HEX:
	MOV	AH,AL			; Save for second digit
	PUSH	CX
	MOV	CL,4
	SHR	AL,CL
	POP	CX

	CALL	DIGIT			; First digit

	MOV	AL,AH			; Now do digit saved in AH
DIGIT:
	AND	AL,0FH			; Mask to 4 bits
	ADD	AL,90H
	DAA
	ADC	AL,40H
	DAA
	AND	AL,7FH
	STOSB
	RET

RBUFIN:
	PUSH	AX
	PUSH	DX
	MOV	AH,STD_CON_STRING_INPUT
	MOV	DX,OFFSET DG:LBUFSIZ
	INT	21H

	POP	DX
	POP	AX
	RET

; Put one space in the printf output uffer
BLANK:
	MOV	AL,CHAR_BLANK
	STOSB
	RET

; Put CX spaces in the printf output buffer
TAB:
	JCXZ	TAB_RET

	CALL	BLANK

	LOOP	TAB
TAB_RET:
	RET

; Command Table. Command letter indexes into table to get
; address of command. PERR prints error for no such command.

COMTAB	DW	ASSEM			; A
	DW	PERR			; B
	DW	COMPARE 		; C
	DW	DUMP			; D
	DW	ENTERDATA		; E
	DW	FILL			; F
	DW	GO			; G
	DW	HEXADD			; H
	DW	INPUT			; I
	DW	PERR			; J
	DW	PERR			; K
	DW	LOAD			; L
	DW	MOVE			; M
	DW	NAMED			; N
	DW	OUTPUT			; O
	DW	ZTRACE			; P
	DW	QUIT			; Q (QUIT)
	DW	REG			; R
	DW	SEARCH			; S
	DW	TRACE			; T
	DW	UNASSEM 		; U
	DW	PERR			; V
	DW	DWRITE			; W
	IF	SYSVER
	    DW	    SETUDEV		; X
	ELSE
	    DW	    DEBEMS
	ENDIF
	DW	PERR			; Y
	DW	PERR			; Z

QUIT:
	INC	BYTE PTR [QFLAG]
	MOV	BX,[USER_PROC_PDB]
FIND_DEBUG:
	IF	NOT SYSVER
	    MOV     AH,SET_CURRENT_PDB
	    INT     21H
	ENDIF
	CALL	RELEASEPARITY		; let system do normal parity stuff

	CALL	RESTORE_DEB_VECT

	MOV	AX,(EXIT SHL 8)
	INT	21H

;======================= proc  prep_command_line =========================
; prep_command_line: This proc converts a Asian DBCS space delimiter (8140h)
;		     into 2 20h values.  In this way we can pass command
;		     lines throughout DEBUG without major modification
;		     to the source code.  This proc is invoked anywhere
;		     a command line is initially accessed.  In the case
;		     of DEBUG it is used in PARSCHK and INBUF.
;		     Any quoted string, a string delimited by ("), will
;		     be ignored.
;
;	input: ds - segment of command line
;	       si - offset of command line
;
;	output: command line with Asian blanks (8140h) converted to
;		2020h.
;
;=========================================================================

prep_command_line proc near		;command line conversion
    push    ax				;save affected regs.
    push    bx				;
    push    si				;

    mov     bl,00h			;initialize flag
					;bl is used to signal
					;  a quote delimiter
;   $DO 				;do while not CR
$$DO5:
	mov	al,[si] 		;move char from cmd line for compare
	cmp	al,CR			;is it a CR ?
;   $LEAVE  E				;if CR exit
    JE $$EN5

	cmp	al,quote_char		;is it a quote ?
;	$IF	Z			;if it is a quote
	JNZ $$IF7
	    xor     bl,01h		;set or reset the flag
;	$ENDIF
$$IF7:

	cmp	bl,01h			;is 1st quote set ?
;	$IF	NZ			;if not continue
	JZ $$IF9
	    call    TEST_LEAD		;test for dbcs lead byte
;	    $IF     C			;we have a lead byte
	    JNC $$IF10
		cmp	al,dbcs_delim	;is it a dbcs char? 81h
;		$IF	Z		;if a dbcs char
		JNZ $$IF11
		    mov     al,[si+1]	    ;move next char al
		    cmp     al,asian_blk    ;is it an Asian blank? 40h
;		    $IF     Z		    ;if an Asian blank
		    JNZ $$IF12
			mov	al,amer_blk ;set up moves
			mov	[si],al     ;  to replace
			mov	[si+1],al   ;  Asian blank w/20h
			inc	si	    ;point to si+1
;		    $ELSE		;if not an asian blank
		    JMP SHORT $$EN12
$$IF12:
			inc	si	;point to dbcs char
;		    $ENDIF		;
$$EN12:
;		$ENDIF			;
$$IF11:
;	    $ENDIF			;end lead byte test
$$IF10:
;	$ENDIF				;
$$IF9:
	inc	si			;point to si+1
;   $ENDDO				;end do while
    JMP SHORT $$DO5
$$EN5:
    pop     si				;restore affected regs.
    pop     bx				;
    pop     ax				;
    ret 				;return to caller
prep_command_line endp			;end proc


;=========================================================================
; DEBUG_LEAD_BYTE - This routine sets the lead-byte-pointers to point
;		    to the dbcs environmental vector table of lead bytes.
;		    This table will be used to determine if we have a
;		    dbcs lead byte.
;
;	Inputs - none
;
;	Outputs- pointer to dbcs environmental vector table of lead bytes
;		 LBTBL DD ?
;
;	Date	  : 6/16/87
;=========================================================================

DEBUG_LEAD_BYTE proc near		;an000;get lead byte vector

	push	ds			;an000;save affected regs
	push	es			;an000;
	push	si			;an000;

	mov	ax,(ECS_call shl 8) or 00h ;an000;get dbcs env. vector
	int	21h			;an000;invoke function

	assume	ds:nothing

	mov	word ptr cs:lbtbl[0],si ;an000;move offset of table
	mov	word ptr cs:lbtbl[2],ds ;an000;move segment of table

	pop	si			;an000;restore affected regs
	pop	es			;an000;
	pop	ds			;an000;

	ret				;an000;return to caller

DEBUG_LEAD_BYTE endp			;an000;end proc

;=========================================================================
; TEST_LEAD - This routine will determine whether or not we have a valid
;	      lead byte for a DBCS character.
;
;	Inputs : AL - Holds the byte to compare.  Passed by POP.		;an001;bgb
;
;	Outputs: Carry set if lead byte
;		 No carry if not lead byte
;
;	Date	  : 6/16/87
;=========================================================================

TEST_LEAD proc	near			;an000;check for dbcs lead byte

	push	ds			;an000;save affected regs
	push	si			;an000;
	push	ax			;an000;

	xchg	ah,al			;an000;ah used for compare
	mov	si,word ptr cs:lbtbl[2] ;an000;get segment of table
	mov	ds,si			;an000;
	mov	si,word ptr cs:lbtbl[0] ;an000;get offset of table

ck_next:

	lodsb				;an000;load al with byte table
	or	al,al			;an000;end of table?
;	$IF	z			;an000;yes, end of table
	JNZ $$IF19
	    jmp     lead_exit		;an000;exit with clear carry
;	$ELSE				;an000;
	JMP SHORT $$EN19
$$IF19:
	    cmp     al,ah		;an000;start > character?
;	    $IF     a			;an000;it is above
	    JNA $$IF21
		clc			;an000;clear carry flag
		jmp	lead_exit	;an000;exit with clear carry
;	    $ELSE			;an000;
	    JMP SHORT $$EN21
$$IF21:
		lodsb			;an000;load al with byte table
		cmp	ah,al		;an000;character > end range
;		$IF	a		;an000;not a lead
		JNA $$IF23
		    jmp     ck_next	;an000;check next range
;		$ELSE			;an000;lead byte found
		JMP SHORT $$EN23
$$IF23:
		    stc 		;an000;set carry flag
;		$ENDIF			;an000;
$$EN23:
;	    $ENDIF			;an000;
$$EN21:
;	$ENDIF				;an000;
$$EN19:

lead_exit:				;an000;exit from check

	pop	ax			;an000;
	pop	si			;an000;restore affected regs.
	pop	ds			;an000;

	ret				;an000;return to caller

TEST_LEAD endp				;an000;end proc



CODE	ENDS
	END	START
