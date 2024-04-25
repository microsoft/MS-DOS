page 80,132

title CP/DOS DosSetVerify mapper

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;**********************************************************************
;*
;*   MODULE:   dossetverify       Set new verify switch value
;*
;*   FILE NAME: dos054.asm
;*
;*   CALLING SEQUENCE:
;*
;*       push      word     verify setting
;*       call      dossetverify
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=2eh, get verify setting
;*
;*********************************************************************

            public   dossetverify
            .sall
            .xlist
            include  macros.inc
            .list

error_code  equ      0002h

str         struc
old_bp      dw       ?
return      dd       ?
verify      dw       ?      ; new verify settings value
str         ends

dossetverify proc    far
            Enter    dossetverify          ; push registers

            mov      ax,[bp].verify        ; check request
            cmp      al,1                  ; for validity
            jg       error

            mov      ah,2eh                ; setup new verify value
            int      21h

            sub      ax,ax                 ; set good return code
            jmp      short exit            ; return

error:      mov      ax,error_code         ; set error return code

exit:       Mexit                          ; pop registers
            ret      size str - 6          ; return

dossetverify endp

dosxxx      ends

            end
