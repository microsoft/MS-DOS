;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; *** MACROS **** MACROS **** MACROS ****
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF1                                     ;
        %OUT .               ®MACROS  .INC¯
ENDIF                                   ;
                                        ;
JUMP    MACRO   LBL                     ;
        LOCAL   A                       ;
.XCREF                                  ;
      IFNDEF LBL&_J                     ; IS THIS FIRST INVOKATION
A:       JMP     LBL                    ;
      ELSE                              ;
         IF (LBL&_J GE $) OR ($-LBL&_J GT 126)
A:          JMP     LBL                 ; IS THE JUMP TOO FAR AWAY?
         ELSE                           ;
A:          JMP     LBL&_J              ; PERFORM SHORT JUMP
         ENDIF                          ;
      ENDIF                             ;
LBL&_J=A                                ;
.CREF                                   ;
        ENDM                            ;
.XCREF JUMP                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; *** MACROS **** MACROS **** MACROS ****
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
