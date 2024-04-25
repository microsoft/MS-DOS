LF	EQU	0AH			;ASCII line feed
CR	EQU	0DH			;ASCII carriage return

CRLF		DB	CR,LF		; gga used to skip a blank line
		db	'$'

WELCOME_MSG	DB	'XMA2EMS: Expanded Memory Manager'
		DB	CR,LF
		DB	'(c)Copyright 1988 Microsoft Corporation                     All rights reserved'
		DB	CR,LF
		DB	'$'

DGS_START_MSG	DB	CR,LF
		DB	'Performing XMA diagnostics:   '
		DB	'$'

DGS_END_MSG	DB	CR,LF
		DB	'Diagnostics completed '
		DB	CR,LF,LF
		DB	'$'

PAGE_FRAME_MSG	DB	'Page Frame starts at........................ '
PF_START	DB	'XXXX'
		DB	':0'
		DB	CR,LF
		DB	'Pages mapped to conventional memory......... '
CONV_PAGES	DB	'0   '
		DB	CR,LF
		DB	'$'
RESERVE_MSG	DB	'Pages reserved for 3270 PC Control Program.. '
RES_PAGES	DB	'0   '
		DB	CR,LF
		DB	'$'
AVAIL_MSG	DB	'Pages available for expanded memory......... '
EMS_PAGES	DB	'0   '
		DB	CR,LF
		DB	'$'

XMA1_ERR_MSG	DB	CR,LF
		DB	'Adapter error '
		DB	CR,LF
		DB	'$'

NOT_FOUND_MSG	DB	CR,LF
		DB	'Cannot find adapter '
		DB	CR,LF
		DB	'$'

PARM_ERR_MSG	DB	CR,LF
		DB	'Parameter syntax or value error '
		DB	CR,LF
		DB	'$'

NO_EMUL_MSG	DB	CR,LF
		DB	'Cannot find XMA Emulator device driver '
		DB	CR,LF
		DB	'$'

WRONG_EMUL_MSG	DB	CR,LF
		DB	'Incorrect version of XMAEM.SYS '
		DB	CR,LF
		DB	'$'

WRONG_XMAA_MSG	DB	CR,LF
		DB	'Incorrect version of INDXMAA.SYS '
		DB	CR,LF
		DB	'$'

REQ_EMS_ERR_MSG DB	CR,LF
		DB	'Too many EMS pages requested in /X parameter '
		DB	CR,LF
		DB	'$'

NOT_INSTL_MSG	DB	'Expanded Memory Manager has NOT been installed'
		DB	CR,LF
		DB	'$'

CONFLICT_MSG	DB	'Specified page address conflicts with installed adapter at address '
CONFL_ADDRESS	DB	'0   '
		DB	CR,LF
		DB	'$'

HOLE_MSG	DB	'Possible 16KB page available at address  '
HOLE_ADDRESS	DB	'0   '
		DB	CR,LF
		DB	'$'

FRAME_MSG	DB	CR,LF
		DB	'Possible 64KB frame available at address '
FRAME_ADDRESS	DB	'0   '
		DB	CR,LF
		DB	'$'

NO_PAGES_MSG	DB	'No page addresses specified'
		DB	CR,LF
		DB	'$'


SIZE_MSG1	DB	SIZE1_END - 2 -$
MEM_OK		DB	4 DUP (?)
		DB	' KB OK$'
SIZE1_END	EQU	$

NEXT_LINE	DB	NXT_LN_END - 2 -$
		DB	' ',CR,LF,'$'
NXT_LN_END	EQU	$

Prompt_Msg	db	'Press any key to continue . . .',CR,LF
		db	'$'

