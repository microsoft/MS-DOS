CODE    SEGMENT BYTE PUBLIC 'CODE'
        ASSUME CS:CODE,DS:CODE

IF1
        %OUT    EGA.CPI creation file
        %OUT    .
        %OUT    CP SRC files:
        %OUT    .
        %OUT    .       CODE PAGE:  850
ENDIF

EGA850: DW     LEN_850                  ; SIZE OF ENTRY HEADER
        DW     POST_EGA850,0            ; POINTER TO NEXT HEADER
        DW     1                        ; DEVICE TYPE
        DB     "EGA     "               ; DEVICE SUBTYPE ID
        DW     850                      ; CODE PAGE ID
        DW     3 DUP(0)                 ; RESERVED
        DW     OFFSET DATA850,0         ; POINTER TO FONTS
LEN_850 EQU    ($-EGA850)               ;
                                        ;
DATA850:DW     1                        ; CART/NON-CART
        DW     3                        ; # OF FONTS
        DW     LEN_D850                 ; LENGTH OF DATA
D850:                                   ;
        DB     16,8                     ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 850-8X16.ASM            ;
                                        ;
        DB     14,8                     ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 850-8X14.ASM            ;
                                        ;
        DB     8,8                      ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 850-8X8.ASM             ;
                                        ;
LEN_D850        EQU ($-D850)            ;
                                        ;
POST_EGA850     EQU     $               ;
                                        ;
CODE    ENDS                            ;
        END                             ;
