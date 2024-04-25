;	SCCSID = @(#)ibmcpmio.asm	1.1 85/04/10
;
; Standard device IO for MSDOS (first 12 function calls)
;

.xlist
.xcref
include mssw.asm
include dosseg.asm
.cref
.list

TITLE	IBMCPMIO - device IO for MSDOS
NAME	IBMCPMIO

include cpmio.asm
