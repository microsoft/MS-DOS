
;***********************************************************************
; NAME: pathlabl
; DESC: creates a public label at the spot it is placed, using the name
;       given.
; INPUT: either module name or procedure name
; OUTPUT: public label
; LOGIC: if masm is in pass1 (pass2 will gen dup labels)
;           if this label has not been gen before
;              then create the label
;                   - $$A to place at begin of map
;                   - start means first occurence
;                   - use module/proc name last
;                   define this label for creation of 'stop' label
;              else create stop label
;                   - same as start except name
;***********************************************************************
.LALL
pathlabl MACRO pnam
IF1                                     ;if pass 1
    IFNDEF LBL_&pnam                    ;switch not defined if first creation
        $$A_START_&pnam:                ;create label
        PUBLIC $$A_START_&pnam          ;make it public
        LBL_&pnam = 1                   ;set switch
    ELSE                                ;start label already created
        $$A_STOP_&pnam:                 ;create stop label
        PUBLIC $$A_STOP_&pnam           ;make it public
    ENDIF
ENDIF
ENDM

