;
page 80,132
;
title CP/DOS  DosChDir  mapper
;
dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
; ************************************************************************* *
; *
; *      MODULE: DosChDir
; *
; *      FUNCTION: change directory name
; *
; *      FUNCTION: This module will change the current directory for the
; *                requesting process.
; *
; *
; *      CALLING SEQUENCE:
; *
; *                PUSH@ ASCIIZ Dirname ; Directory path name
; *                PUSH  DWORD  0       ; Reserved (must be zero)  took out @
; *                                     ; 5/28 to match 3/25 spec
; *                CALL DosChDir
; *
; *
; *      RETURN SEQUENCE:
; *
; *                IF ERROR (AX NOT = 0)
; *
; *                   AX = Error Code:
; *
; *                   o   Invalid directory path
; *
; *      MODULES CALLED:
; *                     DOS int 21h   function 3Bh ; Change current directory
; *
; *************************************************************************

        public  DosChDir
        .sall
        .xlist
        include macros.inc
        .list

str     struc
old_bp  dw      ?
return  dd      ?
dtrm006 dd      0h           ;reserved  (must be zero)
dnam006 dd      ?            ;address of directory path name
str     ends

DosChDir  proc   far
        Enter   DosChDir                 ; push registers

        mov     dx, word ptr [bp].dnam006    ;load directory name offset
        mov     ax, word ptr [bp].dnam006+2  ;load directory name segment

        push    ax                       ; set segment in DS
        pop     ds

        mov     ax,03b00h                ; load chdir op code
        int     21h                      ; call dos to change the directory
        jc      exit                     ; jump if error

        xor     ax,ax                    ; else, good return code
exit:   mexit                            ; pop registers
        ret     size str - 6             ; return

DosChDir  endp

dosxxx  ends

        end
