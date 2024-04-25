;	SCCSID = @(#)locmes.asm	1.1 85/06/13
	title   LOCATE (EXE2BIN) Messages

FALSE   EQU     0
TRUE    EQU     NOT FALSE

addr macro sym,name
    public name
    ifidn <name>,<>
	dw offset sym
    else
    public name
name    dw  offset sym
    endif
endm


DATA    SEGMENT PUBLIC BYTE

	PUBLIC  bad_vers

bad_vers    db    "Incorrect DOS version$"

AccDen      db      "Access denied",0
	    addr    AccDen,AccDen_ptr

notfnd      db      "File not found",0
	    addr    notfnd,notfnd_ptr

NOROOM      db      "Insufficient memory",0
	    addr    noroom,noroom_ptr

DIRFULL     db      "File creation error",0
	    addr    dirfull,dirfull_ptr

FULL        db      "Insufficient disk space",0
	    addr    full,full_ptr

CANTFIX     db      "File cannot be converted",0
	    addr    cantfix,cantfix_ptr

PROMPT      db      "Fix-ups needed - base segment (hex): ",0
	    addr    prompt,prompt_ptr


crlf        db      13,10,0
	    addr    crlf,crlf_ptr

rdbad       db      "WARNING - Read error on EXE file.",13,10
	    db      "          Amount read less than size in header.",0
	    addr    rdbad,rdbad_ptr


DATA    ENDS
	END
