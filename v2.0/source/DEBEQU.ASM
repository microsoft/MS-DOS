FALSE   EQU     0
TRUE    EQU     NOT FALSE

IBMVER  EQU     true                   ; Set conditional switches
MSVER   EQU     false

SYSVER  EQU     FALSE                   ; if true, i/o direct to bios
                                        ; so DOS can be debugged
IBMJAPAN EQU    FALSE

SETCNTC EQU     TRUE                    ; If this is FALSE, DEBUG will not set
                                        ; the Control C int vector

ZIBO    EQU     TRUE                    ; true if P traces over interrupts
                                        ; and calls and dump looks pretty
PROMPT  EQU     "-"
FCB     EQU     5CH
EXEFCB  EQU     FCB
BUFLEN  EQU     80                      ; Maximum length of line input buffer
BPMAX   EQU     10                      ; Maximum number of breakpoints
BPLEN   EQU     5*BPMAX                 ; Length of breakpoint table
REGTABLEN EQU   14                      ; Number of registers
SEGDIF  EQU     0
BUFSIZ  EQU     512

BXREG   EQU     "B"+5800H               ; "BX"
BPREG   EQU     "B"+5000H               ; "BP"
SIREG   EQU     "S"+4900H               ; "SI"
DIREG   EQU     "D"+4900H               ; "DI"
COMMA   EQU     2C00H
OPBUFLEN        EQU     35
