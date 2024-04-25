page 80,132

title CP/DOS DosRead mapper   * * *

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;**********************************************************************
;*
;*   MODULE:   dosreade
;*
;*   FUNCTION: Read a specified number of bytes from the file
;*
;*   CALLING SEQUENCE:
;*
;*       push      word     file handle
;*       push@     other    buffer area
;*       push      word     buffer length
;*       push@     word     bytes read
;*       call      dosread
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=3fh,
;*
;*********************************************************************

            public   dosread
            .sall
            .xlist
            include  macros.inc
            .list

str         struc
old_bp      dw       ?
return      dd       ?
Written     dd       ?       ; number of bytes actually read
Bufflng     dw       ?       ; number of bytes to be read
Buffer      dd       ?       ; read buffer
Handle      dw       ?       ; handle
str         ends

dosread     proc     far
            Enter    Dosread           ; save registers

            mov      bx,[bp].handle    ; fill registers for
            lds      dx,[bp].buffer    ; function call
            mov      cx,[bp].bufflng   ; number of bytes to read

            mov      ah,3fh            ; load opcode
            int      21h               ; read from file
            jc       exit              ; jump if error

            lds      si,[bp].written   ; else, set return data area
            mov      word ptr [si],ax  ; save number of bytes read
            sub      ax,ax             ; set good return code

exit:       mexit                      ; pop registers
            ret      size str - 6      ; rturn

dosread     endp

dosxxx      ends

            end
