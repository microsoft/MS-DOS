;
page 60,132
;
title CP/DOS DosExit mapper
;
dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
;**********************************************************************
;*
;*   MODULE:   dosexit
;*
;*   FUNCTION:  Exit a process
;*
;*   CALLING SEQUENCE:
;*
;*       push      word   action code
;*       push      word   result code
;*       call      dosexit
;*
;*   MODULES CALLED:  DOS Int 21h, Function 4ch, terminate process
;*
;*********************************************************************

            public   dosexit
            .sall
            include  macros.inc

str         struc
old_bp      dw       ?
return      dd       ?
Result      dw       ?       ; result code
Action      dw       ?       ; action code
str         ends

dosexit     proc     far

            Enter    DosExit             ; push registers

            mov      ax,[bp].action      ; set resule code area
            cmp      ax,1                ; check for valid action code
            jg       exit                ; jump if invalid action code

            mov      ax,[bp].result      ; else, set result code

            mov      ah,4ch              ; load opcode
            int      21h                 ; do exit

            xor      ax,ax               ; set good return code

exit:       mexit                        ; pop registers
            ret      size str - 6        ; return

dosexit     endp

dosxxx      ends

            end
