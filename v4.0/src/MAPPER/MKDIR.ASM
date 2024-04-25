page 80,132

title CP/DOS DosMkDir mapper

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
;**********************************************************************
;*
;*   MODULE:   dosmkdir
;*
;*   FUNCTION:  Create  a new directory
;*
;*   CALLING SEQUENCE:
;*
;*       push@     asciiz  directory name
;*       push      dword   reserved (must be zero)
;*       call      dosmkdir
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=39h
;*
;*********************************************************************

            public   dosmkdir
            .sall
            include  macros.inc

str         struc
old_bp      dw       ?
return      dd       ?
rsrvd       dd       ?
Asciiz      dd       ?       ; new directory name pointer
str         ends

dosmkdir    proc     far

            Enter    DosMkdir            ; push registers
            lds      dx,[bp].asciiz      ; set pointer to directory name

            mov      ah,39h              ; load opcode
            int      21h                 ; create new directory
            jc       exit                ; jump if error

            sub      ax,ax               ; else, set good return code

exit:       mexit                        ; pop registers
            ret      size str - 6        ; return

dosmkdir    endp

dosxxx      ends

            end
