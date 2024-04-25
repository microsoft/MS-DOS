page 80,132

title CP/DOS DosRmDir mapper

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;**********************************************************************
;*
;*   MODULE:   dosrmdir
;*
;*   FUNCTION:  remove directory
;*
;*   CALLING SEQUENCE:
;*
;*       push@     asciiz  directory name
;*       push      dword   reserved (must be zero)
;*       call      dosrmdir
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=3ah, remove subdirectory
;*
;*********************************************************************

            public   dosrmdir
            .sall
            include  macros.inc

str         struc
old_bp      dw       ?
return      dd       ?
rsrvd       dd       ?       ; reserved
asciiz      dd       ?       ; directory name pointer
str         ends

dosrmdir    proc     far

            Enter    dosrmdir            ; push registers

            lds      dx,[bp].asciiz      ; set pointer to directory name

            mov      ah,3ah              ; load opcode
            int      21h                 ; remove directory
            jc       exit                ; check for error

            sub      ax,ax               ; set good return code
exit:       Mexit                        ; pop registers
            ret      size str - 6        ; return

dosrmdir    endp

dosxxx      ends

            end
