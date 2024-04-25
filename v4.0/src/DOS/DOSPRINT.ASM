;	SCCSID = @(#)dosprint.asm	1.1 85/04/10
;	SCCSID = @(#)dosprint.asm	1.1 85/04/10
TITLE	DOSPRINT - PRINTF at DOS level
NAME	DOSPRINT
;
;
;   Modification history:
;
;	Created: MZ 16 June 1984
;

.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGroup,CS:DOSGroup

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
.cref
.list
.sall

	I_Need	Proc_ID,WORD
	I_Need	User_ID,WORD

BREAK	<debugging output>

include print.asm

CODE ENDS
END
