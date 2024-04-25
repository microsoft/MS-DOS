;
page 60,132
;
title CP/DOS VioScrollUp mapper
;
vioxxx  segment byte public 'vio'
        assume  cs:vioxxx,ds:nothing,es:nothing,ss:nothing
;
; ************************************************************************* *
; *
; *      MODULE: VioScrollUp
; *
; *      FILE NAME: scrollup.asm
; *
; *      CALLING SEQUENCE:
; *
; *
; *             push    word    toprow
; *             push    word    leftcol
; *             push    word    botrow
; *             push    word    rightcol
; *             push    word    lines
; *             push@   dword   cell
; *             push    word    vio handle
; *             call    vioscrollup
; *
; *      MODULES CALLED:  BIOS Int 10h
; *
; *
; *
; *************************************************************************

        public vioscrollup
        .sall
        .xlist
        include macros.inc
        .list

error_bvs_parameter equ 0002h

str     struc
old_bp   dw      ?
return   dd      ?
handle   dw      ?        ; vio handle
cell     dd      ?        ; cell to be written
lines    dw      ?        ; number of blank lines
rightcol dw      ?        ; right column
botrow   dw      ?        ; bottom row
leftcol  dw      ?        ; left column
toprow   dw      ?        ; top row
str     ends

vioscrollup proc   far
        Enter   VioScrollUp             ; save registers

        mov     bx,[bp].lines           ; get number of blank lines
        cmp     bl,25                   ; check for validity
        jg      error                   ; jump if invalid

        mov     al,bl
        jmp     ar02

ar01:   mov     al,00h
ar02:   mov     ah,06h                  ; set scroll up function code

        mov     bx,[bp].rightcol        ; get right col number
        cmp     bl,80                   ; check the validity
        jg      error                   ; branch if error
        mov     dl,bl                   ; right column number in DL

        mov     bx,[bp].botrow          ; get bottom row
        cmp     bl,25                   ; check for validity
        jg      error                   ; branch if error
        mov     dh,bl                   ; bottom row in DH

        mov     bx,[bp].leftcol         ; get left column number
        mov     cl,bl                   ; left column in CL

        mov     bx,[bp].toprow          ; get top row number
        mov     ch,bl                   ; top row in CH

        lds     si,[bp].cell            ; Set up cell in BX
        mov     bx,ds:[si]              ;                    *****************
;       cmp     bl,15                   ; check validity     ** assume good **
;       jg      error                   ; branch if error    ** attribute!  **
                                        ;                    *****************
        mov     bh,bl                   ; filler attribute in BH
        pushal                          ; Save registers in case int 10h
                                        ;   messes them up
        int     10h                     ; scrollup the display

        popal
        sub     ax,ax                   ; set no error code
        jmp     exit                    ; return

error:  mov     ax,error_bvs_parameter  ; set error code

exit:   Mexit                           ; pop registers
        ret     size str - 6            ; return

vioscrollup endp
vioxxx  ends
        end
