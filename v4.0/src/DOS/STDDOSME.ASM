;	SCCSID = @(#)stddosmes.as	1.2 85/10/07
;	SCCSID = @(#)stddosmes.as	1.2 85/10/07
;
; Standard device IO for MSDOS (first 12 function calls)
;

.xlist
.xcref
include stdsw.asm
include dosseg.asm
.cref
.list

debug=0

TITLE   STDDOSMES - DOS OEM dependancies
NAME    STDDOSMES

include dosmes.asm
