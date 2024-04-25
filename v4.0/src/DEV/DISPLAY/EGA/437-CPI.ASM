CODE    SEGMENT BYTE PUBLIC 'CODE'
        ASSUME CS:CODE,DS:CODE

IF1
        %OUT    EGA.CPI creation file
        %OUT    .
        %OUT    CP SRC files:
        %OUT    .
        %OUT    .       CODE PAGE:  437
ENDIF

EGA437: DW     LEN_437                  ; SIZE OF ENTRY HEADER
        DW     POST_EGA437,0            ; POINTER TO NEXT HEADER
        DW     1                        ; DEVICE TYPE
        DB     "EGA     "               ; DEVICE SUBTYPE ID
        DW     437                      ; CODE PAGE ID
        DW     3 DUP(0)                 ; RESERVED
        DW     OFFSET DATA437,0         ; POINTER TO FONTS
LEN_437 EQU    ($-EGA437)               ;
                                        ;
DATA437:DW     1                        ; CART/NON-CART
        DW     3                        ; # OF FONTS
        DW     LEN_D437                 ; LENGTH OF DATA
D437:                                   ;
        DB     16,8                     ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 437-8X16.ASM            ;
                                        ;
        DB     14,8                     ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 437-8X14.ASM            ;
                                        ;
        DB     8,8                      ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 437-8X8.ASM             ;
                                        ;
LEN_D437        EQU ($-D437)            ;
                                        ;
POST_EGA437     EQU     $               ;
                                        ;
CODE    ENDS                            ;
        END                             ;
