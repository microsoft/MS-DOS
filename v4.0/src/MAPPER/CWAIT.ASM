;
page 60,132
;
title CP/DOS  DOSCWait  mapper

; ************************************************************************* *
; *
; *      MODULE: DosCWait
; *
; *      ACTION:    Wait for a child termination
; *
; *      CALLING SEQUENCE:
; *
; *             push    actioncode      ; execution options
; *             push    waitoption      ; wait options
; *             push@   resultcode      ; address to put result code
; *             push@   processidword   ; address to put process id
; *             push    processid       ; process id of process to wait for
; *             call    doscwait
; *
; *      RETURN SEQUENCE:
; *
; *
; *
; *      MODULES CALLED:   None
; *
; *
; *
; *************************************************************************

buffer  segment word public 'buffer'

        extrn   DosExecPgmCalled:word
        extrn   DosExecPgmReturnCode:word

buffer  ends

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

        public  doscwait
        .sall
        .xlist
        include macros.inc
        .list
;
str     struc
old_bp      dw    ?
return      dd    ?
Qprocessid  dw    ?           ; Child process ID
Aprocessid  dd    ?           ; process id pointer
resultcode  dd    ?           ; result code pointer
waitoption  dw    ?           ; wait option
actioncode  dw    ?           ; action code
str     ends

doscwait proc   far
        Enter   doscwait                 ; push registers

        mov     ax,seg buffer
        mov     ds,ax                    ; set temporary buffer
        assume  ds:buffer

        cmp     DosExecPgmCalled,0       ; ??????
        jz      WeHaveExeced

        mov     ax,31
        jmp     ErrorExit                ; error exit

WeHaveExeced:
        mov     ax,DosExecPgmReturnCode
        lds     si,[bp].ResultCode
        assume  ds:nothing
        mov     ds:[si],ax               ; return termination code

        mov     ax,[bp].Qprocessid       ; return child process id
        lds     si,[bp].Aprocessid
        mov     ds:[si],ax

        xor     ax,ax                    ; set good return code

ErrorExit:
        Mexit                            ; pop registers
        ret     size str - 6             ; return

doscwait endp

dosxxx  ends

        end
