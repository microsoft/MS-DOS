CODE    SEGMENT BYTE PUBLIC 'CODE'
        ASSUME CS:CODE,DS:CODE

IF1
        %OUT    EGA.CPI creation file
        %OUT    .
        %OUT    CP SRC files:
        %OUT    .
        %OUT    .       CODE PAGE:  863
ENDIF

EGA863: DW     LEN_863                  ; SIZE OF ENTRY HEADER
        DW     POST_EGA863,0            ; POINTER TO NEXT HEADER
        DW     1                        ; DEVICE TYPE
        DB     "EGA     "               ; DEVICE SUBTYPE ID
        DW     863                      ; CODE PAGE ID
        DW     3 DUP(0)                 ; RESERVED
        DW     OFFSET DATA863,0         ; POINTER TO FONTS
LEN_863 EQU    ($-EGA863)               ;
                                        ;
DATA863:DW     1                        ; CART/NON-CART
        DW     3                        ; # OF FONTS
        DW     LEN_D863                 ; LENGTH OF DATA
D863:                                   ;
        DB     16,8                     ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 863-8X16.ASM            ;
                                        ;
        DB     14,8                     ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 863-8X14.ASM            ;
                                        ;
        DB     8,8                      ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        INCLUDE 863-8X8.ASM             ;
                                        ;
LEN_D863        EQU ($-D863)            ;
                                        ;
POST_EGA863     EQU     $               ;
                                        ;
CODE    ENDS                            ;
        END                             ;
