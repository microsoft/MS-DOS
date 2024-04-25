;
page 60,132
;
title CP/DOS  DosReallocSeg  mapper
;
dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
; ************************************************************************* *
; *
; *      MODULE: DosReallocSeg
; *
; *      FILE NAME: dos043.asm
; *
; *      FUNCTION: This module changes the size of a segment already
; *             allocated
; *
; *      CALLING SEQUENCE:
; *
; *             push    size            ; new segment size requested in bytes
; *             push    selector        ; selector
; *             call    dosreallocseg
; *
; *      RETURN SEQUENCE:
; *
; *
; *
; *      MODULES CALLED:  DOS Int 21, AH=4A
; *
; *
; *
; *************************************************************************
;
        public  dosreallocseg
        .sall
        .xlist
        include macros.inc
        .list

str     struc
old_bp  dw      ?
return  dd      ?
Selector        dw      ?       ; segment selector
SegmentSize     dw      ?       ; new segment size in bytes
str     ends

dosreallocseg proc   far
        Enter   dosreallocseg           ; save registers

        mov     bx,[bp].SegmentSize     ; Get new segment size
        cmp     bx,0                    ; check for 0
        je      AllocateMax             ; jmp to full seg

        shr     bx,1                    ; else convert segment in bytes
        shr     bx,1                    ; paragraph
        shr     bx,1
        shr     bx,1
        jmp     HaveSize

AllocateMax:
        mov     bx,4096                 ; default segment size in paragraph

HaveSize:
        mov     es,[bp].Selector        ; set up segment for new size

        mov     ah,4ah                  ; set up for DOS realloc call
        int     21h                     ; realloc segment
        jc      ErrorExit               ; jump if error

        sub     ax,ax                   ; else set good return code

ErrorExit:
        Mexit                           ; restore registers

        ret     size str - 6            ; return

dosreallocseg  endp

dosxxx  ends

        end
