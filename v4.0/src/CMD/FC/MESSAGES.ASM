;
; message file for FC command
;

CONST   SEGMENT WORD PUBLIC 'DATA'
CONST   ENDS

_BSS    SEGMENT WORD PUBLIC 'DATA'
_BSS    ENDS

_DATA   SEGMENT WORD PUBLIC 'DATA'
_DATA   ENDS

DGROUP  GROUP   CONST, _BSS, _DATA

        ASSUME  DS:DGROUP

_DATA   SEGMENT
PUBLIC	_BadSw, _UseMes, _BadOpn, _LngFil, _NoDif, _NoMem, _Bad_ver, _ReSyncMes, _UnKnown

_BadSw          DB      "Incompatible switches",0
_Bad_ver        DB      "Incorrect DOS version",0
_UseMes         DB      "usage: fc [/a] [/b] [/c] [/l] [/lbNN] [/w] [/t] [/n] [/NNNN] file1 file2",0ah,0
_BadOpn         DB      "cannot open %s - %s",0
_LngFil         DB      "%s longer than %s",0
_NoDif          DB      "no differences encountered",0
_NoMem          DB      "out of memory",0ah,0
_ReSyncMes	DB	"Resync failed.  Files are too different\n",0
_UnKnown	DB	"Unknown error",0
_DATA   ENDS
END
