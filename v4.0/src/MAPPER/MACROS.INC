;
        if1
                %out    macros.inc
        endif


pushal  macro
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    ds
        push    es
        push    ss
        push    bp
        endm
;
popal   macro
        pop     bp
        pop     ss
        pop     es
        pop     ds
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        endm
;
Enter   macro   Routine

        push    bp
        mov     bp,sp
        pushal

        endm
;
Mexit   macro

        popal
        mov     sp,bp
        pop     bp

        endm
