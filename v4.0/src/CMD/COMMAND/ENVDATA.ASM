;	SCCSID = @(#)envdata.asm	1.1 85/05/14
;	SCCSID = @(#)envdata.asm	1.1 85/05/14
; This file is included by command.asm and is used as the default command
; environment.

ENVARENA  SEGMENT PUBLIC PARA
	ORG 0
	DB  10h  DUP (?)		 ;Pad for memory allocation addr mark
ENVARENA   ENDS

ENVIRONMENT SEGMENT PUBLIC PARA        ; Default COMMAND environment

	PUBLIC	ECOMSPEC,ENVIREND,PATHSTRING

	ORG	0
PATHSTRING DB	"PATH="
USERPATH LABEL	BYTE

	DB	0		; Null path
	DB	"COMSPEC="
ECOMSPEC DB	"\COMMAND.COM"      ;AC062
	DB	134 DUP (0)

ENVIREND	LABEL	BYTE

ENVIRONSIZ EQU	$-PATHSTRING
ENVIRONSIZ2 EQU $-ECOMSPEC
ENVIRONMENT ENDS
