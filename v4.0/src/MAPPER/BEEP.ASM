page 80,132

title CP/DOS DosBeep mapper

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;**********************************************************************
;*
;*   MODULE:   dosbeep
;*
;*   FUNCTION:  generate a tone with desired frequency and duration
;*
;*   CALLING SEQUENCE:
;*
;*       push      word   frequency
;*       push      word   duration      (in milliseconds)
;*       call      dosbeep
;*
;*   MODULES CALLED:  none
;*
;*********************************************************************

        public  dosbeep
        .sall
        include macros.inc

inv_parm equ    0002h         ;invalid parameter return code

str     struc
old_bp  dw      ?
return  dd      ?
duratn  dw      ?       ; duration
frqncy  dw      ?       ; frequency
str     ends

dosbeep proc    far
        Enter   DosBeep

        mov     al,10110110b      ; Set 8253 chip channel 2
        out     43h,al            ; to proper mode for tone

; Channel 2 is now set up as a frequency divider.  The sixteen bit
; value sent to that port (in low-high format) is divided into
; 1.19 MHz, the clock speed.  In order to send the proper value
; to the register, then, the frequency requested must be divided
; into 1,190,000.

        mov     dx,012h           ; MSB of 1.19M
        mov     ax,2970h          ; LSB of 1.19M
        mov     cx,[bp].frqncy    ; divisor
        mov     bx,025h           ; check frequency range
        cmp     cx,bx             ; frequency ok ??
        jl      error             ; branch if error

        mov     bx,7fffh
        cmp     cx,bx
        jg      error
        div     cx                ; then divide

        out     42h,al            ; and output
        mov     al,ah             ; directly to
        out     42h,al            ; the 8253 port.

; Turn on speaker

        in      al,61h            ; Save original value
        mov     ah,al             ; in ah
        or      al,3              ; Turn on control bit
        out     61h,al            ; in 8255 chip

; Now loop for DURATN milliseconds

        mov     cx,[bp].duratn    ; load value
delay:  mov     bx,196            ; inner loop count
del2:   dec     bx                ; a millisecond
        jne     del2              ; for each
        loop    delay             ; iteration

; Turn speaker off

        mov     al,ah             ; replace
        out     61h,al            ; original value

        sub     ax,ax             ; set no error code
        jmp     exit              ; return

error:  mov     ax,inv_parm

exit:   MExit                     ; pop registers
        ret     size str - 6      ; return

dosbeep endp

dosxxx  ends

        end
