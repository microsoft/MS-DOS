page 80,132

title CP/DOS DosWrite mapper

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;**********************************************************************
;*
;*   MODULE:   doswrite
;*
;*   FUNCTION:  Write a specified number of bytes to a file
;*
;*   CALLING SEQUENCE:
;*
;*       push      word     file handle
;*       push@     other    buffer area
;*       push      word     buffer length
;*       push@     word     bytes written
;*       call      doswrite
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=40h, write
;*
;*********************************************************************

            public   doswrite
            .sall
            .xlist
            include  macros.inc
            .list

str         struc
old_bp      dw       ?
return      dd       ?
Written     dd       ?       ; number of bytes actually written
Bufflng     dw       ?       ; number of bytes to be written
Buffer      dd       ?       ; write buffer address
Handle      dw       ?       ; file handle
str         ends

doswrite    proc     far

            Enter    doswrite            ; push registers

            mov      bx,[bp].handle      ; get handle
            lds      dx,[bp].buffer      ; set write buffer
            mov      cx,[bp].bufflng     ; number of bytes to be written

            mov      ah,40h              ; load opcode
            int      21h                 ; write bytes to the file
            jc       exit                ; jump if error

            lds      si,[bp].written     ; pointer to return data
            mov      word ptr [si],ax    ; save actual number of bytes written
            sub      ax,ax               ; set good return code

exit:       mexit                        ; pop registers
            ret      size str - 6        ; return

doswrite    endp

dosxxx      ends

            end
