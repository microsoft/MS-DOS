;*************************************
; COMMAND EQUs which are not switch dependant

IFDEF   IBM
        INCLUDE IFEQU.ASM
ENDIF


SYM     EQU     ">"

LINPERPAG       EQU     23
NORMPERLIN      EQU     1
WIDEPERLIN      EQU     5
COMBUFLEN       EQU     128     ; Length of commmand buffer

DRVCHAR         EQU     ":"

FCB     EQU     5CH

VARSTRUC        STRUC
ISDIR   DB      ?
SIZ     DB      ?
TTAIL   DW      ?
INFO    DB      ?
BUF     DB      DIRSTRLEN + 20 DUP (?)
VARSTRUC        ENDS

WSWITCH EQU     1               ; Wide display during DIR
PSWITCH EQU     2               ; Pause (or Page) mode during DIR
ASWITCH EQU     4               ; ASCII mode during COPY
BSWITCH EQU     8               ; Binary mode during COPY
VSWITCH EQU     10H             ; Verify switch
GOTSWITCH EQU   8000H           ; Meta switch set if switch character encountered
