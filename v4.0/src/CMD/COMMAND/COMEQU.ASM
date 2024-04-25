;	SCCSID = @(#)comequ.asm 1.1 85/05/14
;	SCCSID = @(#)comequ.asm 1.1 85/05/14
;*************************************
; COMMAND EQUs which are not switch dependant

EMGDEBUG = FALSE

SYM		EQU	">"

LINESPERPAGE	EQU	25		;AC000; default lines per page
NORMPERLIN	EQU	1
WIDEPERLIN	EQU	5
COMBUFLEN	EQU	128		; Length of commmand buffer
BatLen		EQU	32		; buffer for batch files
YES_ECHO	EQU	1		; echo line
NO_ECHO 	EQU	0		; don't echo line
No_Echo_Char	EQU	"@"             ; don't echo line if this is first char
call_in_progress EQU	1		; indicate we're in the CALL command
length_call	EQU	4		; length of CALL
max_nest	EQU    10		; max # levels of batch nesting allowed
fail_allowed	EQU    00001000b	; critical error
retry_allowed	EQU    00010000b	; critical error
Ignore_allowed	EQU    00100000b	; critical error
nullcommand	EQU    1		; no command on command line
end_of_line	EQU    -1		;AN000; end of line return from parser
end_of_line_out EQU	0		;AN000; end of line for output
end_of_line_in	EQU	0dh		;AN000; end of line for input
result_number	EQU	1		;AN000; number returned from parser
result_string	EQU	3		;AN000; string returned from parser
result_filespec EQU	5		;AN000; filespec returned from parser
result_drive	EQU	6		;AN000; drive returned from parser
result_date	EQU	7		;AN000; date returned from parser
result_time	EQU	8		;AN000; time returned from parser
result_no_error EQU	0		;AN000; no error returned from parser
no_cont_flag	EQU	0		;AN000; no control flags for message
util_msg_class	EQU	-1		;AN000; message class for utility
ext_msg_class	EQU	1		;AN000; message class for extended error
parse_msg_class EQU	2		;AN000; message class for parse error
crit_msg_class	EQU	3		;AN000; message class for critical error
ext_crlf_class	EQU	081h		;AN054; message class for extended error with no CRLF
colon_char	EQU	":"             ;AN000; colon character
crt_ioctl_ln	EQU	14		;AN000; default length of data for display ioctl
text_mode	EQU	1		;AN000; text mode return from ioctl
get_generic	EQU	07Fh		;AN000; generic ioctl - get device info
set_crit_dev	EQU	0100H		;AN000; device attribute for critical error on I/0
mult_ansi	EQU	01Ah		;AC064; multiplex for ansi.sys
mult_shell_get	EQU	01902h		;AC065; multiplex for Shell - get next command
mult_shell_brk	EQU	01903h		;AN000; multiplex for Shell - ^C batch check
shell_action	equ	0ffh		;AN000; SHELL - return for taking SHELL specific action
bat_not_open	EQU	-1		;AN000; batch handle will be set to this if not open
bat_open_handle EQU	19		;AN000; handle will be in this position in JFN table
Ptr_seg_pos	equ	7		;AN000; Offset from start of message block for subst segment
Ptr_off_pos	equ	5		;AN000; Offset from start of message block for subst offset
Parm_off_pos	equ	word ptr 2	;AN000; Offset from start of subst list for subst offset
parm_block_size equ	11		;AN000; size of message subst block
blank		equ	" "             ;AN000; blank character
no_subst	equ	0		;AN000; no substitutions for messages
one_subst	equ	1		;AN000; one substitution for messages
no_handle_out	equ	-1		;AN000; use function 1 thru 12 for message retriever
res_subst	equ	2		;AN000; offset from start of message definition to number of subst
read_open_mode	equ   0000000000000000b ;AN024; extended open mode for read
read_open_flag	equ   0000000100000001b ;AN000; extended open flags for read
write_open_mode equ   0000000000000001b ;AN024; extended open mode for read
write_open_flag equ   0000000100000001b ;AN000; extended open flags for read
creat_open_flag equ   0000000100010010b ;AN000; extended open flags for read
get_CPSW	equ	3		;AN000; minor function for get CPSW status
CPSW_off	equ	0		;AN000; CPSW return from function - OFF
Get_XA		equ	2		;AN030; minor function for get extended attributes
Set_XA		equ	4		;AN000; minor function for set extended attributes
file_no_cpage	equ	0		;AN000; file has no code page tag
file_inv_cpage	equ	-1		;AN000; file has invalid code page tag
do_xa		equ	-1		;AN000; flag to get extended attributes
inv_cp_tag	equ	0		;AC039; tag for invalid code page
no_xa_seg	equ	-1		;AN000; no segment for extended attributes - COPY
capital_A	equ	'A'             ;AC000;
vbar		equ	'|'             ;AC000;
labracket	equ	'<'             ;AC000;
rabracket	equ	'>'             ;AC000;
dollar		equ	'$'             ;AC000;
lparen		equ	'('             ;AC000;
rparen		equ	')'             ;AC000;
nullrparen	equ	29h		;AC000;
in_word 	equ	4e49h		;AC000; 'NI'  ('IN' backwards)
do_word 	equ	4f44h		;AC000; 'OD'  ('DO' backwards)
star		equ	'*'             ;AC000;
plus_chr	equ	'+'             ;AC000;
small_a 	equ	'a'             ;AC000;
small_z 	equ	'z'             ;AC000;
dot_chr 	equ	'.'             ;AC000;
tab_chr 	equ	9		;AN032;
equal_chr	equ	'='             ;AN032;
semicolon	equ	';'             ;AN049;
dot_qmark	equ	2e3fh		;AC000; '.?'
dot_colon	equ	2e3ah		;AC000; '.:'
capital_n	equ	0		;AC000; result from Y/N call if N entered
capital_y	equ	1		;AC000; result from Y/N call if Y entered
AppendInstall	equ	0B700H		;AN020; append install check
AppendDOS	equ	0B702H		;AN020; append DOS version check
AppendGetState	equ	0B706H		;AN020; append get current state
AppendSetState	equ	0B707H		;AN020; append set current state
AppendTruename	equ	0B711H		;AN042; Get file's real location for Batch
search_attr	equ	attr_read_only+attr_hidden+attr_directory  ;AC042;

;*************************************
;* PARSE ERROR MESSAGES
;*************************************

MoreArgs_Ptr	equ	1		;AN000;"Too many parameters" message number
LessArgs_Ptr	equ	2		;AN000;"Required parameter missing" message number
BadSwt_Ptr	equ	3		;AN000;"Invalid switch" message number
BadParm_Ptr	equ	10		;AN000;"Invalid parameter" message number

;*************************************
;* EQUATES FOR MESSAGE RETRIEVER
;*************************************

GET_EXTENDED_MSG	EQU	0	;AN000;  get extended message address
SET_EXTENDED_MSG	EQU	1	;AN000;  set extended message address
GET_PARSE_MSG		EQU	2	;AN000;  get parse message address
SET_PARSE_MSG		EQU	3	;AN000;  set parse message address
GET_CRITICAL_MSG	EQU	4	;AN000;  get critical message address
SET_CRITICAL_MSG	EQU	5	;AN000;  set critical message address
MESSAGE_2F		EQU	46	;AN000;  minor code for message retriever

;*********************************
;* EQUATES FOR INT 10H
;*********************************

VIDEO_IO_INT		EQU	10H	;AN000;  equate for int 10h
SET_VIDEO_MODE		EQU	0	;AN000;  set video mode
SET_CURSOR_POSITION	EQU	2	;AN000;  set new cursor position
SCROLL_VIDEO_PAGE	EQU	6	;AN000;  scroll active page up
VIDEO_ATTRIBUTE 	EQU	7	;AN000;  attribute to be used on blank line
SET_COLOR_PALETTE	EQU	11	;AN000;  set color for video
GET_VIDEO_STATE 	EQU	15	;AN000;  get current video state
VIDEO_ALPHA		EQU	3	;AN000;  alpha video is 3 or below
VIDEO_BW		EQU	7	;AN000;  mode for 80X25 black & white

AltPipeChr	equ	"|"             ; alternate pipe character

FCB		EQU	5CH

VARSTRUC	STRUC
ISDIR		DB	?
SIZ		DB	?
TTAIL		DW	?
INFO		DB	?
BUF		DB	DIRSTRLEN + 20 DUP (?)
VARSTRUC	ENDS

fCheckDrive	equ	00000001b
fSwitchAllowed	equ	00000010b

;
; Test switches
;
fParse		EQU	0001h		; display results of parseline

;
; Batch segment structure
;
;   BYTE    type of segment
;   BYTE    echo state of parent on entry to batch file
;   WORD    segment of last batch file
;   WORD    segment for FOR command
;   BYTE    FOR flag state on entry to batch file
;   DWORD   offset for next line
;   10 WORD pointers to parameters.  -1 is empty parameter
;   ASCIZ   file name (with . and ..)
;   BYTES   CR-terminated parameters
;   BYTE    0 flag to indicate end of parameters
;

BatchType   equ 0

BatchSegment	struc
BatType 	DB	BatchType	; signature
Batechoflag	DB	0		; G state of echo
Batlast 	DW	0		; G segment of last batch file
Batforptr	DW	0		; G segment for FOR command
Batforflag	DB	0		; G state of FOR
BatSeek 	DD	?		; lseek position of next char
BatParm 	DW	10 dup (?)	; pointers to parameters
BatFile 	DB	?		; beginning of batch file name
BatchSegment	ends

ANULL		equ	0		; terminates an argv string
ARGMAX		equ	64		; max args on a command line
ARGBLEN 	equ	2*128		; 1char each plus term NUL
tplen		equ	64		; max size of one argument
arg_cnt_error	equ	1		; number of args > MAXARG
arg_buf_ovflow	equ	2		; overflowed argbuffer

argv_ele   STRUC			; elements in the argv array
    argpointer	DW	(?)		; pointer to the argstring
    argflags	DB	(?)		; cparse flags for this argstring
    argstartel	DW	(?)		; the result of cparse's [STARTEL]
    arglen	DW	(?)		; cparse's char count + one (for null)
    argsw_word	DW	(?)		; any switches after this?  what kinds?
    arg_ocomptr DW	(?)		; pointer into original command string
argv_ele   ENDS

arg_unit    STRUC
    argv	DB	(ARGMAX * SIZE argv_ele) DUP (?)
    argvcnt	DW	(?)		; number of arguments
    argswinfo	DW	(?)		; Switch information for entire line
    argbuf	DW	ARGBLEN DUP (?) ; storage for argv strings
    argforcombuf db	COMBUFLEN DUP (?) ; Original for loop command string
arg_unit    ENDS

parseflags RECORD special_delim:1, unused:4, path_sep:1, wildcard:1, sw_flag:1

SwitchV 	EQU	10h
SwitchB 	EQU	08h
SwitchA 	EQU	04h
SwitchP 	EQU	02h
SwitchW 	EQU	01h
fSwitch 	EQU	8000h
fBadSwitch	EQU	4000h

SwitchDir	EQU	SwitchP + SwitchW + fSwitch
SwitchCopy	EQU	SwitchV + SwitchA + SwitchB + fSwitch

break <Trap:  Get the attention of MSDOS>
;   TRAP snares the operating system for a service call
; AX, as well as any other registers MS-DOS takes a fancy to, will be crunched.
trap	MACRO	dos_function,dos_info
    ifnb    <dos_info>
	mov	AX, (dos_function SHL 8) + dos_info
    else
	mov	AX, (dos_function SHL 8)
    endif
	int	int_command
ENDM

;
; Equates for initialization
;
initInit	equ	01h		; initialization in progress
initSpecial	equ	02h		; in initialization time/date routine
initCtrlC	equ	04h		; already in ^C handler
