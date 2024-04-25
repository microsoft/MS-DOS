CODE    SEGMENT BYTE PUBLIC 'CODE'
        ASSUME CS:CODE,DS:CODE

BEGIN:  ORG    0

FNTHEAD:DB     0FFH,"FONT   "           ;FILE TAG
        DB     8 DUP(0)                 ;RESERVED
        DW     1                        ;CNT OF POINTERS IN HEADER
        DB     1                        ;TYPE FOR INFO POINTER
        DW     OFFSET INFO,0            ;POINTER TO INFO IN FILE
INFO:   DW     5                        ;COUNT OF ENTRIES

CODE    ENDS
        END
