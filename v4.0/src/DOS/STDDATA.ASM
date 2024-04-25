;	SCCSID = @(#)stddata.asm	1.1 85/04/10
;
; DATA Segment for MS-DOS
;

.xlist
.xcref
include stdsw.asm
include dosseg.asm
debug = FALSE                           ; No dossym (too big)
INCLUDE DOSMAC.INC
INCLUDE SF.INC
INCLUDE DIRENT.INC
INCLUDE CURDIR.INC
INCLUDE DPB.INC
INCLUDE BUFFER.INC
INCLUDE ARENA.INC
INCLUDE VECTOR.INC
INCLUDE DEVSYM.INC
INCLUDE PDB.INC
INCLUDE FIND.INC
INCLUDE MI.INC
.cref
.list

TITLE   STDDATA - DATA segment for MS-DOS
NAME    STDDATA

installed = TRUE

include msdata.asm
include msinit.asm
	END
