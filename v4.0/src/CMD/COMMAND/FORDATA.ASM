;	SCCSID = @(#)fordata.asm	1.1 85/05/14
;	SCCSID = @(#)fordata.asm	1.1 85/05/14
; Data structure definitions included by tfor.asm

for_info        STRUC
    for_args        DB          (SIZE arg_unit) DUP (?) ; argv[] structure
    FOR_COM_START   DB          (?)                     ; beginning of <command>
    FOR_EXPAND      DW          (?)                     ; * or ? item in <list>?
    FOR_MINARG      DW          (?)                     ; beginning of <list>
    FOR_MAXARG      DW          (?)                     ; end of <list>
    forbuf          DW          64 DUP (?)              ; temporary buffer
    fordma          DW          64 DUP (?)              ; FindFirst/Next buffer
    FOR_VAR         DB          (?)                     ; loop control variable
for_info        ENDS

; empty segment done for bogus addressing
for_segment     segment
f       LABEL   BYTE
for_segment     ends
