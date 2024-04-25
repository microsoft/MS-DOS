 page 80,132
;	SCCSID = @(#)rdata.asm	4.2 85/09/22
;	SCCSID = @(#)rdata.asm	4.2 85/09/22
TITLE	COMMAND Resident DATA

include comsw.asm
.xlist
.xcref
include comseg.asm
.list
.cref

;
; Equates for initialization (from COMEQU)
;
initInit    equ     01h 		; initialization in progress
initSpecial equ     02h 		; in initialization time/date routine
initCtrlC   equ     04h 		; already in ^C handler

Tokenized = FALSE

CODERES 	SEGMENT PUBLIC BYTE	;AC000;
	PUBLIC	RSTACK
	EXTRN	EXT_EXEC:NEAR
	EXTRN	THEADFIX:NEAR
	EXTRN	TREMCHECK:NEAR

	DB	(80H - 3) DUP (?)

RSTACK	LABEL	WORD

CODERES ENDS

TRANCODE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	COMMAND:NEAR
TRANCODE	ENDS

; Data for resident portion

DATARES SEGMENT PUBLIC BYTE

	IF	Tokenized
	PUBLIC	IOTYP
	PUBLIC	MESADD
	ENDIF

	PUBLIC	abort_char
	PUBLIC	append_flag		;AN020;
	PUBLIC	append_state		;AN020;
	PUBLIC	BADFAT_BLOCK		;AC000;
	PUBLIC	BADFAT_OP_SEG		;AC000;
	PUBLIC	BADFAT_SUBST		;AC000;
	PUBLIC	BATCH
	PUBLIC	Batch_Abort
	PUBLIC	call_batch_flag
	PUBLIC	call_flag
	PUBLIC	CDEVAT			;AC000;
	PUBLIC	COM_FCB1
	PUBLIC	COM_FCB2
	PUBLIC	COM_PTR
	PUBLIC	COM_XLAT_ADDR
	PUBLIC	COMDRV
	PUBLIC	COMPRMT1_BLOCK		;AC000;
	PUBLIC	COMPRMT1_SEG		;AC000;
	PUBLIC	COMPRMT1_SEG2		;AC000;
	PUBLIC	COMPRMT1_SUBST		;AC000;
	PUBLIC	COMSPEC
	PUBLIC	crit_msg_off		;AC000;
	PUBLIC	crit_msg_seg		;AC000;
	PUBLIC	critical_msg_start	;AC000;
	PUBLIC	comspec_print
	PUBLIC	comspec_end
	PUBLIC	cpdrv
	PUBLIC	crit_err_INFO
	PUBLIC	DATARESEND
	PUBLIC	dbcs_vector_addr	;AN000;
	PUBLIC	DEVE_OP_OFF		;AC000;
	PUBLIC	DEVE_OP_SEG		;AC000;
	PUBLIC	DEVE_OP_SEG2		;AC000;
	PUBLIC	DEVEMES_BLOCK		;AC000;
	PUBLIC	DEVEMES_SUBST		;AC000;
	PUBLIC	DEVENAM 		;AC000;
	PUBLIC	DISP_CLASS		;AN000;
	PUBLIC	DRVLET
	PUBLIC	DRVNUM_BLOCK		;AC000;
	PUBLIC	DRVNUM_OP_OFF		;AC000;
	PUBLIC	DRVNUM_OP_SEG		;AC000;
	PUBLIC	DRVNUM_OP_SEG2		;AC000;
	PUBLIC	DRVNUM_SUBST		;AC000;
	PUBLIC	ECHOFLAG
	PUBLIC	ENVIRSEG
	PUBLIC	ERR15_OP_SEG		;AC000;
	PUBLIC	ERR15_OP_SEG2		;AC000;
	PUBLIC	ERR15_OP_SEG3		;AC000;
	PUBLIC	ERR15MES_BLOCK		;AC000;
	PUBLIC	ERR15MES_SUBST		;AC000;
	PUBLIC	ERRCD_24
	PUBLIC	ErrType
	PUBLIC	EXEC_BLOCK
	PUBLIC	EXECEMES_BLOCK		;AC000;
	PUBLIC	EXECEMES_SUBST		;AC000;
	PUBLIC	EXECEMES_OFF		;AC000;
	PUBLIC	EXECEMES_SEG		;AC000;
	PUBLIC	EXTCOM
	PUBLIC	extended_msg_start	;AN000;
	PUBLIC	extmsgend		;AN000;
	PUBLIC	fail_char		;AC000;
	PUBLIC	fFail
	PUBLIC	FORFLAG
	PUBLIC	forptr
	PUBLIC	fucase_addr		;AN000;
	PUBLIC	HANDLE01
	PUBLIC	IFFlag
	PUBLIC	ignore_char
	PUBLIC	In_Batch
	PUBLIC	InitFlag
	PUBLIC	INPIPEPTR
	PUBLIC	INT_2E_RET
	PUBLIC	IO_SAVE
	PUBLIC	LOADING
	PUBLIC	LTPA
	PUBLIC	MEMSIZ
;AD054; PUBLIC	MESBAS			;AC000;
	PUBLIC	MYSEG
	PUBLIC	MYSEG1
	PUBLIC	MYSEG2
	PUBLIC	nest
	PUBLIC	next_batch
	PUBLIC	no_char
	PUBLIC	NULLFLAG
	PUBLIC	NUMBER_SUBST		;AN000;
	PUBLIC	olderrno
	PUBLIC	OldTerm
	PUBLIC	OUTPIPEPTR
	PUBLIC	PARENT
;AD060; PUBLIC	pars_msg_off		;AN000;
;AD060; PUBLIC	pars_msg_seg		;AN000;
	PUBLIC	parse_msg_start 	;AN000;
	PUBLIC	PERMCOM
	PUBLIC	PIPE1
	PUBLIC	pipe1t
	PUBLIC	PIPE2
	PUBLIC	pipe2t
	PUBLIC	PIPEFILES
	PUBLIC	PIPEFLAG
	PUBLIC	PIPEPTR
	PUBLIC	PIPESTR
	PUBLIC	RDIRCHAR
	PUBLIC	RE_OUT_APP
	PUBLIC	RE_OUTSTR
	PUBLIC	RemMsg
	PUBLIC	resmsgend		;AN000;
	PUBLIC	RES_TPA
	PUBLIC	RESTDIR
	PUBLIC	ResTest
	PUBLIC	RETCODE
	PUBLIC	retry_char
	PUBLIC	rsrc_xa_seg		;AN030;
	PUBLIC	RSWITCHAR
	PUBLIC	SAVE_PDB
	PUBLIC	SINGLECOM
	PUBLIC	SUM
	PUBLIC	SUPPRESS
	PUBLIC	TRANS
	PUBLIC	TranVarEnd
	PUBLIC	TRANVARS
	PUBLIC	TRNSEG
	PUBLIC	TrnMvFlg
	PUBLIC	VERVAL
	PUBLIC	VolName
	PUBLIC	VOLSER			;AN000;
	PUBLIC	yes_char

;AD054;MESBAS  DW      19		       ;AC000;	 error_write_protect
;AD054;        DW      20		       ;AC000;	 error_bad_unit
;AD054;        DW      21		       ;AC000;	 error_not_ready
;AD054;        DW      22		       ;AC000;	 error_bad_command
;AD054;        DW      23		       ;AC000;	 error_CRC
;AD054;        DW      24		       ;AC000;	 error_bad_length
;AD054;        DW      25		       ;AC000;	 error_Seek
;AD054;        DW      26		       ;AC000;	 error_not_DOS_disk
;AD054;        DW      27		       ;AC000;	 error_sector_not_found
;AD054;        DW      28		       ;AC000;	 error_out_of_paper
;AD054;        DW      29		       ;AC000;	 error_write_fault
;AD054;        DW      30		       ;AC000;	 error_read_fault
;AD054;        DW      31		       ;AC000;	 error_gen_failure
;AD054;        DW      32		       ;AC000;	 error_sharing_violation
;AD054;        DW      33		       ;AC000;	 error_lock_violation
;AD054;        DW      34		       ;AC000;	 error_wrong_disk
;AD054;        DW      35		       ;AC000;	 error_FCB_unavailable
;AD054;        DW      36		       ;AC000;	 error_sharing_buffer_exceeded
;AD054;        DW      37		       ;AC000;	 error_code_page_mismatch
;AD054;        DW      38		       ;AC026;	 error_out_of_input
;AD054;        DW      39		       ;AN026;	 error_insufficient_disk_space



IF Tokenized
MESADD	LABEL WORD
	DW	OFFSET ResGroup:NEWLIN		;"0"
	DW	OFFSET ResGroup:COM$1		;"1"
	DW	OFFSET ResGroup:ERR3		;"2"
	DW	OFFSET ResGroup:ALLOC$3 	;"3"
	DW	OFFSET ResGroup:FILE$4		;"4"
	DW	OFFSET ResGroup:RROR$5		;"5"
	DW	OFFSET ResGroup:CAN$6		;"6"
	DW	OFFSET ResGroup:EMORY$7 	;"7"
	DW	OFFSET ResGroup:BAT$8		;"8"
	DW	OFFSET ResGroup:INS$9		;"9"

ERR0	DB	"Write protec","t"+80h
ERR1	DB	"Bad uni","t"+80h
ERR2	DB	"Not read","y"+80h
ERR3	DB	"Bad command"," "+80h
ERR4	DB	"Dat","a"+80h
ERR5	DB	"Bad call forma","t"+80h
ERR6	DB	"See","k"+80h
ERR7	DB	"Non-DOS dis","k"+80h
ERR8	DB	"Sector not foun","d"+80h
ERR9	DB	"No pape","r"+80h
ERR10	DB	"Write faul","t"+80h
ERR11	DB	"Read faul","t"+80h
ERR12	DB	"General Failur","e"+80h
ERR13	DB	"Sharing Violatio","n"+80h
ERR14	DB	"Lock Violatio","n"+80h
ERR15	DB	"Invalid Disk Chang","e"+80h
ERR16	DB	"FCB unavailabl","e"+80h
ERR17	DB	"Sharing buffer exceede","d"+80h

;--- Extra message for error 15
Err15Mes	db     "Please Insert disk "
VolName 	db	11 dup(?)
		db	13,10,"$"

MREAD		DB	"read"
MWRITE		DB	"writ"
ERRMES		DB	" e5"
IOTYP		DB	"writin","g"+80h
DRVNUM		DB	" drive "
DRVLET		DB	"A"
NEWLIN		DB	13,10+80h
DEVEMES 	DB	" device "
DEVENAM 	DB	8 DUP (?)
		DB	13,10,"$"               ;Must be $ terminated
COM$1		DB	" COMMAN","D"+80h
ALLOC$3 	DB	" allocation"," "+80h
FILE$4		DB	" file"," "+80h
RROR$5		DB	"rror"," "+80h
CAN$6		DB	"Cannot"," "+80h
EMORY$7 	DB	"emor","y"+80h
BAT$8		DB	" batc","h"+80h
INS$9		DB	"Inser","t"+80h


CDEVAT		DB	?
BADFAT		DB	"0File 3table bad",","+80h
COMBAD		DB	"0Invalid1.COM","0"+80h
comprmt1	DB	"9 disk with"," "+80h
comprmt2	DB	" in drive "
cpdrv		DB	" "
PROMPT		DB	"0and strike any key when ready","0"+80h
ENDBATMES	DB	"0Terminate8 job (Y/N)?"," "+80h
EXECEMES	DB	"EXEC failure","0"+80h
EXEBAD		DB	"E5in EXE4","0"+80h
TOOBIG		DB	"Program too big to fit in m7","0"+80h
NOHANDMES	DB	"0No free4handle","s"+80h
BMEMMES 	DB	"0M73e","5"+80h
HALTMES 	DB	"06load1, system halte","d"+80h
FRETMES 	DB	"06start1, exiting","0"+80h
RBADNAM 	DB	"2or4name","0"+80h
AccDen		DB	"Access Denied","0"+80h
Patricide	DB	13,10,"Top level process aborted, cannot continue."," "+80h
COMSPEC_PRINT	DW	?

ELSE


parm_block_size EQU	11			;AN000; size of message subst block
blank		EQU	" "                     ;AN000; blank character

DISP_CLASS	DB	-1			;AN000; utility message class
NUMBER_SUBST	DB	0			;AN000; number of message substitutions - def 0


DRVNUM_SUBST	db	2			;AN000; number of subst
DRVNUM_BLOCK	db	parm_block_size 	;AN000;size of sublist
		db	0			;AN000;reserved
DRVNUM_OP_OFF	dw	0			;AN000;offset of arg
DRVNUM_OP_SEG	dw	0			;AN000;segment of arg
		db	1			;AN000;first subst
		db	Char_field_ASCIIZ	;AN000;character string
		db	128			;AN000;maximum width
		db	0			;AN000;minimum width
		db	blank			;AN000;pad character
		db	parm_block_size 	;AN000;size of sublist
		db	0			;AN000;reserved
		dw	OFFSET RESGROUP:DRVLET	;AN000;offset of arg
DRVNUM_OP_SEG2	dw	0			;AN000;segment of arg
		db	2			;AN000;second subst
		db	Char_field_Char 	;AN000;one character
		db	1			;AN000;maximum width
		db	1			;AN000;minimum width
		db	blank			;AN000;pad character

DRVLET		DB	"A"

DEVEMES_SUBST	db	2			;AN000; number of subst
DEVEMES_BLOCK	db	parm_block_size 	;AN000;size of sublist
		db	0			;AN000;reserved
DEVE_OP_OFF	dw	0			;AN000;offset of arg
DEVE_OP_SEG	dw	0			;AN000;segment of arg
		db	1			;AN000;first subst
		db	Char_field_ASCIIZ	;AN000;character string
		db	128			;AN000;maximum width
		db	0			;AN000;minimum width
		db	blank			;AN000;pad character
		db	parm_block_size 	;AN000;size of sublist
		db	0			;AN000;reserved
		dw	OFFSET RESGROUP:DEVENAM ;AN000;offset of arg
DEVE_OP_SEG2	dw	0			;AN000;segment of arg
		db	2			;AN000;second subst
		db	Char_field_ASCIIZ	;AN000;character string
		db	8			;AN019;maximum width
		db	8			;AN019;minimum width
		db	blank			;AN000;pad character

DEVENAM 	DB	8 DUP (?)

;--- Extra message for error 15
ERR15MES_SUBST	db	3			;AN000; number of subst
ERR15MES_BLOCK	db	parm_block_size 	;AN000;size of sublist
		db	0			;AN000;reserved
		dw	OFFSET RESGROUP:VOLNAME ;AN000;offset of arg
ERR15_OP_SEG	dw	0			;AN000;segment of arg
		db	1			;AN000;first subst
		db	Char_field_ASCIIZ	;AN000;character string
		db	12			;AN000;maximum width
		db	12			;AN000;minimum width
		db	blank			;AN000;pad character
		db	parm_block_size 	;AN000;size of sublist
		db	0			;AN000;reserved
		dw	OFFSET RESGROUP:VOLSER+2;AN000;offset of arg
ERR15_OP_SEG2	dw	0			;AN000;segment of arg
		db	2			;AN000;second subst
		db	right_align+Bin_Hex_Word ;AN000;long binary to decimal
		db	4			;AN000;maximum width
		db	4			;AN000;minimum width
		db	"0"                     ;AN000;pad character
		db	parm_block_size 	;AN000;size of sublist
		db	0			;AN000;reserved
		dw	OFFSET RESGROUP:VOLSER	;AN000;offset of arg
ERR15_OP_SEG3	dw	0			;AN000;segment of arg
		db	3			;AN000;third subst
		db	right_align+Bin_Hex_Word ;AN000;long binary to decimal
		db	4			;AN000;maximum width
		db	4			;AN000;minimum width
		db	"0"                     ;AN000;pad character

;************************************
;* DO NOT SEPARATE VOLNAME & VOLSER *
;************************************
				   ;*
VolName 	DB	11 dup(?)  ;*
		DB	0	   ;*
VolSer		DD	0	   ;*
				   ;*
;************************************


CDEVAT		DB	?

BADFAT_SUBST	db	1			;AN000; number of subst
BADFAT_BLOCK	db	parm_block_size 	;AN000;size of sublist
		db	0			;AN000;reserved
		dw	OFFSET RESGROUP:DRVLET	;AN000;offset of arg
BADFAT_OP_SEG	dw	0			;AN000;segment of arg
		db	1			;AN000;first subst
		db	Char_field_Char 	;AN000;one character
		db	1			;AN000;maximum width
		db	1			;AN000;minimum width
		db	blank			;AN000;pad character


COMPRMT1_SUBST	db	2			;AN000; number of subst
COMPRMT1_BLOCK	db	parm_block_size 	;AN000;size of sublist
		db	0			;AN000;reserved
COMSPEC_PRINT	dw	?			;AN000;offset of arg
COMPRMT1_SEG	dw	0			;AN000;segment of arg
		db	1			;AN000;first subst
		db	Char_field_ASCIIZ	;AN000;character string
		db	64			;AN000;maximum width
		db	0			;AN000;minimum width
		db	blank			;AN000;pad character
		db	parm_block_size 	;AN000;size of sublist
		db	0			;AN000;reserved
		dw	OFFSET RESGROUP:CPDRV	;AN000;offset of arg
COMPRMT1_SEG2	dw	0			;AN000;segment of arg
		db	2			;AN000;second subst
		db	Char_field_Char 	;AN000;one character
		db	1			;AN000;maximum width
		db	1			;AN000;minimum width
		db	blank			;AN000;pad character

cpdrv		DB	" "
;
; Exec error messages
;
EXECEMES_SUBST	db	1			;AN000; number of subst
EXECEMES_BLOCK	db	parm_block_size 	;AN000;size of sublist
		db	0			;AN000;reserved
EXECEMES_OFF	dw	0			;AN000;offset of arg
EXECEMES_SEG	dw	0			;AN000;segment of arg
		db	1			;AN000;first subst
		db	Char_field_ASCIIZ	;AN000;character string
		db	64			;AN000;maximum width
		db	0			;AN000;minimum width
		db	blank			;AN000;pad character

;
; These characters MUST remain in order
;
abort_char	db	"A"
retry_char	db	"R"
ignore_char	db	"I"
fail_char	db	"F"
yes_char	db	"Y"
no_char 	db	"N"
;
; End of characters that MUST remain in order
;
ENDIF

RemMsg		DD	?			;Pointer to message in error 15
ErrType 	DB	?			; Error message style, 0=old, 1=new

INT_2E_RET	DD	?			; Magic command executer return address
SAVE_PDB	DW	?
PARENT		DW	?
OldTerm 	DD	?
ERRCD_24	DW	?
HANDLE01	DW	?
LOADING 	DB	0
BATCH		DW	0			; Assume no batch mode initially
COMSPEC 	DB	64 DUP(0)
comspec_end	dw	?
TRANS		DW	OFFSET TRANGROUP:COMMAND
TRNSEG		DW	?
; BAS DEBUG
TrnMvFlg	DB	0			; Indicate if transient portion has been moved

In_Batch	DB	0			; Indicate if we are in Batch processing mode.
Batch_Abort	DB	0			; Indicate if user wants to abort from batch mode.

COMDRV		DB	?			; DRIVE SPEC TO LOAD AUTOEXEC AND COMMAND
MEMSIZ		DW	?
SUM		DW	?
EXTCOM		DB	1			; For init, pretend just did an external
RETCODE 	DW	?
CRIT_ERR_INFO	DB	?			;G hold critical error flags for R,I,F
rsrc_xa_seg	DW	-1			;AN030; holds segment of xa copy buffer

;
; The echo flag needs to be pushed and popped around pipes and batch files.
; We implement this as a bit queue that is shr/shl for push and pop.
;
ECHOFLAG	DB	00000001B		; low bit TRUE => echo commands
SUPPRESS	DB	1			; used for echo, 1=echo line
IO_SAVE 	DW	?
RESTDIR 	DB	0
PERMCOM 	DB	0			; TRUE => permanent command
SINGLECOM	DW	0			; TRUE => single command version
VERVAL		DW	-1
fFail		DB	0			; TRUE => FAIL all INT 24s
IFFLAG		DB	0			; TRUE => If statement in progress

FORFLAG 	DB	0			; TRUE => FOR statement in progress
FORPTR		DW	0

NEST		DW	0			; NESTED BATCH FILE COUNTER
CALL_FLAG	DB	0			; NO CALL (BATCH COMMAND) IN PROGRESS
CALL_BATCH_FLAG DB	0
NEXT_BATCH	DW	0			; ADDRESS OF NEXT BATCH SEGMENT
NULLFLAG	DB	0			; FLAG IF NO COMMAND ON COMMAND LINE
COM_XLAT_ADDR	DB	5 DUP (0)		;G BUFFER FOR TRANSLATE TABLE ADDRESS
FUCASE_ADDR	DB	5 DUP (0)		;AN000;  BUFFER FOR FILE UCASE ADDRESS
CRIT_MSG_OFF	DW	0			;AN000;  SAVED CRITICAL ERROR MESSAGE OFFSET
CRIT_MSG_SEG	DW	0			;AN000;  SAVED CRITICAL ERROR MESSAGE SEGMENT
;AD060; PARS_MSG_OFF	DW	0			;AN000;  SAVED PARSE ERROR MESSAGE OFFSET
;AD060; PARS_MSG_SEG	DW	0			;AN000;  SAVED PARSE ERROR MESSAGE SEGMENT
Dbcs_vector_addr DW	0			;AN000; DBCS vector offset
		DW	0			;AN000; DBCS vector segment
APPEND_STATE	DW	0			;AN020; current state of append (if flag = -1)
APPEND_FLAG	DB	0			;AN020; set if APPEND state valid

RE_OUT_APP	DB	0
RE_OUTSTR	DB	64+3+13 DUP (?)

;
; We flag the state of COMMAND in order to correctly handle the ^Cs at
; various times.  Here is the breakdown:
;
;   initINIT	We are in the init code.
;   initSpecial We are in the date/time prompt
;   initCtrlC	We are handling a ^C already.
;
; If we get a ^C in the initialization but not in the date/time prompt, we
; ignore the ^C.  This is so the system calls work on nested commands.
;
; If we are in the date/time prompt at initialization, we stuff the user's
; input buffer with a CR to pretend an empty response.
;
; If we are already handling a ^C, we set the carry bit and return to the user
; (ourselves).	We can then detect the carry set and properly retry the
; operation.
;

InitFlag	DB	initINIT

;These two bytes refed as a word
PIPEFLAG	DB	0
PIPEFILES	DB	0

;--- 2.x data for piping
;
;  All the "_" are substituted later, the one before the : is substituted
; by the current drive, and the others by the CreateTemp call with the
; unique file name. Note that the first 0 is the first char of the pipe
; name. -MU
;
;--- Order dependant, do not change

Pipe1		db	"_:/"
Pipe1T		db	0
		db	"_______.___",0
Pipe2		db	"_:/"
Pipe2T		db	0
		db	"_______.___",0

PIPEPTR 	DW	?
PIPESTR 	DB	129 DUP(?)
INPIPEPTR	DW	OFFSET ResGroup:PIPE1
OUTPIPEPTR	DW	OFFSET ResGroup:PIPE2

EXEC_BLOCK	LABEL	BYTE			; The data block for EXEC calls
ENVIRSEG	DW	?
COM_PTR 	LABEL	DWORD
		DW	80H			; Point at unformatted parameters
		DW	?
COM_FCB1	LABEL	DWORD
		DW	5CH
		DW	?
COM_FCB2	LABEL	DWORD
		DW	6CH
		DW	?

TRANVARS	LABEL	BYTE			; Variables passed to transient
		DW	OFFSET ResGroup:THEADFIX
MYSEG		DW	0			; Put our own segment here
LTPA		DW	0			; WILL STORE TPA SEGMENT HERE
RSWITCHAR	DB	"-"
RDIRCHAR	DB	"/"
		DW	OFFSET ResGroup:EXT_EXEC
MYSEG1		DW	?
		DW	OFFSET ResGroup:TREMCHECK
MYSEG2		DW	0
ResTest 	DW	0
RES_TPA 	DW	0			; Original TPA (not rounded to 64K)
TranVarEnd	LABEL	BYTE

olderrno	dw	?

RESMSGEND	DW	0			;AN000;; holds offset of msg end (end of resident)

.xlist
.xcref

INCLUDE SYSMSG.INC				;AN000; include message services

.list
.cref

ASSUME DS:RESGROUP,ES:RESGROUP,CS:RESGROUP

MSG_UTILNAME <COMMAND>				;AN000; define utility name

;AD054; MSG_SERVICES <COMR,MSGDATA,COMMAND.CLA,COMMAND.CL3,COMMAND.CL4>  ;AN000; get message services data and resident messages
MSG_SERVICES <COMR,MSGDATA,COMMAND.CLA>  ;AN054; get message services data and resident messages


CRITICAL_MSG_START	LABEL	BYTE		;AN000; start of critical error messages

MSG_SERVICES <COMR,COMMAND.CLD> 		;AN000; get critical error messages

DATARESEND		LABEL	BYTE		;AC060; end of resident portion if /msg not used

PARSE_MSG_START 	LABEL	BYTE		;AN000; start of parse error messages

MSG_SERVICES <COMR,COMMAND.CLC> 		;AN000; get parse error messages

;AD060; DATARESEND		LABEL	BYTE		; end of resident portion if /msg not used

EXTENDED_MSG_START	LABEL	BYTE		;AN000; start of extended error messages

MSG_SERVICES <COMR,COMMAND.CLE> 		;AN000; get extended error messages

EXTMSGEND		LABEL	BYTE		;AN000; end of extended error messages

include msgdcl.inc

DATARES ENDS
	END
