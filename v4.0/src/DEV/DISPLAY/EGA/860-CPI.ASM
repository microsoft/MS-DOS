CODE    SEGMENT BYTE PUBLIC 'CODE'
        ASSUME CS:CODE,DS:CODE

IF1
        %OUT    EGA.CPI creation file
        %OUT    .
        %OUT    CP SRC files:
        %OUT    .
        %OUT    .       CODE PAGE:  860
ENDIF

EGA860: DW     LEN_860                  ; SIZE OF ENTRY HEADER
        DW     POST_EGA860,0            ; POINTER TO NEXT HEADER
        DW     1                        ; DEVICE TYPE
        DB     "EGA     "               ; DEVICE SUBTYPE ID
        DW     860                      ; CODE PAGE ID
        DW     3 DUP(0)                 ; RESERVED
        DW     OFFSET DATA860,0         ; POINTER TO FONTS
LEN_860 EQU    ($-EGA860)               ;
                                        ;
DATA860:DW     1                        ; CART/NON-CART
        DW     3                        ; # OF FONTS
        DW     LEN_D860                 ; LENGTH OF DATA
D860:                                   ;
        DB     16,8                     ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 860-8X16.ASM            ;
                                        ;
        DB     14,8                     ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 860-8X14.ASM            ;
                                        ;
        DB     8,8                      ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 860-8X8.ASM             ;
                                        ;
LEN_D860        EQU ($-D860)            ;
                                        ;
POST_EGA860     EQU     $               ;
                                        ;
CODE    ENDS                            ;
        END                             ;
