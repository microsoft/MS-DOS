
major_version	    equ     4	    ;Major DOS version
minor_version	    equ     00	    ;Minor DOS Version

expected_version    equ     (MINOR_VERSION SHL 8)+MAJOR_VERSION

       if1
       %OUT  ... for DOS Version 4.00 ...
       endif

       ;******************************
       ;Each assembler program should:
       ;  mov ah,030h			;DOS Get Version function
       ;  int 021h			;Version ret. in AX,minor version first
       ;  cmp ax,expected_version	;ALL utilities should check for an
       ;  jne error_handler		; EXACT version match.
       ;******************************

