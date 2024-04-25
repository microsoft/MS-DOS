
INCSW	EQU	0			;INCLUDE PSDATA.INC			;AN000;
FARSW	EQU	1			;CALL THE PARSER BY NEAR CALL
DATESW	EQU	0			;SUPPRESS DATE CHECKING 		;AN000;
TIMESW	EQU	0			;SUPPRESS TIME CHECKING 		;AN000;
FILESW	EQU	0			;SUPPRESS CHECKING FILE SPECIFICATION	;AN000;
CAPSW	EQU	0			;SUPPRESS FILE TABLE CAPS		;AN000;
CMPXSW	EQU	1			;SUPPRESS CHECKING COMPLEX LIST
DRVSW	EQU	1			;SUPPRESS SUPPORT OF DRIVE ONLY FORMAT
QUSSW	EQU	0			;SUPPRESS SUPPORT OF QUOTED STRING FORMAT ;AN000;
NUMSW	EQU	1			;SUPPRESS CHECKING NUMERIC VALUE
KEYSW	EQU	0			;SUPPRESS KEYWORD SUPPORT		;AN000;
SWSW	EQU	1			;DO SUPPORT SWITCHES			;AN000;
VAL1SW	EQU	0			;SUPPRESS SUPPORT OF VALUE DEFINITION 1 ;AN000;
VAL2SW	EQU	0			;SUPPRESS SUPPORT OF VALUE DEFINITION 2 ;AN000;
VAL3SW	EQU	1			;DO SUPPORT VALUE DEFINITION 3

include psdata.inc
;***********************************************************************

;-------------------------------------------------------------------
;
;	parser stuff for APPEND
;
;-------------------------------------------------------------------



p_block1  $P_PARMS_Blk <offset px_block1, 0, 0>    ; parm block
p_block2  $P_PARMS_Blk <offset px_block2, 0, 0>    ; parm block

;------------------------
;	extended parameter block for APPEND first load

px_block1:
	db	0		; min number positional operands
	db	0		; max number positional operands
;	dw	0		; offset into control block for positionals

	db	3		; APPEND has two switches /E, /X, /PATH
	dw	offset e_switch 	; control block for /E switch
	dw	offset x_switch 	; control block for /X switch
	dw	offset path_switch	; control block for /PATH switch

	db	0		; max number of keywords
	dw	0		; offset of keyword control block

;------------------------
;	extended parameter block for 2nd, 3rd, ... APPEND invocations

px_block2:
	db	0		; min number positional operands
	db	1		; max number positional operands
	dw	offset dirs_control	; pointer to dirs control block

;	db	2		; APPEND after first load has two switches /X, /PATH
	db	3		; APPEND has two switches /E, /X, /PATH
	dw	offset e_switch 	; control block for /E switch
	dw	offset x_switch 	; control block for /X switch
	dw	offset path_switch	; control block for /PATH switch

	db	0		; max number of keywords

;------------------------
dirs_control:
	dw	$P_Simple_S+$P_Optional   ; complex, optional string
	dw	$P_CAP_File		; cap by file table
	dw	offset dirs_result	; dirs result buffer
	dw	offset dirs_values	; pointer to null value list
	db	0			; no synonyms

dirs_values:
	db	0			; null value list for dirs



;------------------------
x_switch:
	dw	$P_Simple_s+$P_Optional       ; /X, /X:ON, /X:OFF simple, optional string
	dw	$P_CAP_Char		; cap by char table
	dw	offset x_result 	; pointer to result block
	dw	offset x_values 	; pointer to values block
	db	1			; number of switches and synonyms
	db	"/X",0                  ; only /X is valid

x_values:
	db	3			; string values
	db	0			; zeroes here for ranges and
	db	0			; values
	db	2			; 2 possible string values
	db	0			; /X:OFF = 0
	dw	offset off_string	; pointer to "OFF"
	db	1			; /X:ON  = 1
	dw	offset on_string
;------------------------

e_switch:
	dw	0			; /E
	dw	$P_CAP_Char		; cap by char table
	dw	offset e_result 	; pointer to result block
	dw	offset e_values 	; pointer to values block, none
	db	1			; number of switches and synonyms
	db	"/E",0                   ; only /E is valid

e_values:
	db	0			; null value list for /E


;------------------------
path_switch:
	dw	$P_Simple_s		; /PATH:ON, /PATH:OFF simple string
	dw	$P_CAP_Char		; cap by char table
	dw	offset path_result	; pointer to result block
	dw	offset path_values	; pointer to values block
	db	1			; number of switches and synonyms
	db	"/PATH",0                ; only /PATH is valid


path_values:
	db	3			; string values
	db	0			; zeroes here for ranges and
	db	0			; values
	db	2			; 2 possible string values
	db	0			; /PATH:OFF = 0
	dw	offset off_string	; pointer to "OFF"
	db	1			; /PATH:ON  = 1
	dw	offset on_string


;------------------------

off_string:
	db	"OFF",0                 ; off string

on_string:
	db	"ON",0                  ; on string


;------------------------

x_result	$P_Result_Blk <>	; /X result block
e_result	$P_Result_Blk <>	; /E result block
path_result	$P_Result_Blk <>	; /PATH result block
dirs_result	$P_Result_Blk <>	; dirs result block


