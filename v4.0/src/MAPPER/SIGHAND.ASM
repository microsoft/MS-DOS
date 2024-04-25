page 80,132

title CP/DOS DosSetSigHandler  mapper

        include msc.inc

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;**********************************************************************
;*
;*   MODULE:   dossetsighandler
;*
;*   FILE NAME: dos007.asm
;*
;*   CALLING SEQUENCE:
;*
;*       push      word    file handle
;*       push      dword   distance
;*       push      word    move type
;*       push@     dword   new pointer
;*       call      doschgfileptr
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=42h
;*
;*********************************************************************

            public   dossetsighandler
            .sall
            .xlist
            include  macros.inc
            .list

str         struc
old_bp      dw       ?
return      dd       ?
Signumber   dw       ?          ; signal number
Action      dw       ?          ; action code
Prevaction  dd       ?          ; previous action code
Prevadrs    dd       ?          ; previous vector address
Routineadrs dd       ?          ; interrupt handler address
str         ends

; While we hate to do this, we have to.  The following data areas are
; expected to be in the CODE segment.

NextControlBreakHandler         label   dword
NextControlBreakHandlerOffset   dw      DummyControlBreakHandler
NextControlBreakHandlerSegment  dw      dosxxx

NextCriticalErrorHandler        label   dword
NextCriticalErrorHandlerOffset  dw      DummyCriticalErrorHandler
NextCriticalErrorHandlerSegment dw      dosxxx

dossetsighandler  proc  far

        Enter    dossetsighandler       ; push registers

        mov      ax,[bp].action         ; get action code
        cmp      ax,2                   ; action code 2 ??
        je       continue1              ; branch if true
        mov      ax,1                   ; else, set error code
        jmp      exit                   ; return

continue1:
        mov      ax,[bp].signumber      ; get signel number
        cmp      ax,1                   ; signal 1 (cntrl chara) ??
        je       cntrlc                 ; jump if true
        cmp      ax,4                   ; signal 4 (cntrl chara) ??
        je       cntrlc                 ; jump if true
        mov      ax,2                   ; else, set error code
        jmp      exit                   ; return

cntrlc: mov      ax,03523h
        int      21h                    ; get old vector address

        lds      si,[bp].prevadrs       ; previous handler pointer
        mov      word ptr [si],bx       ; save it in prevsdrs
        mov      word ptr [si]+2,es

        lds      dx,[bp].routineadrs    ; get address of signal  handler

        mov     NextControlBreakHandlerOffset,dx   ; save it
        mov     NextControlBreakHandlerSegment,ds

        mov     dx,cs
        mov     ds,dx
        mov     dx,offset RealControlBreakHandler

        mov      ax,02523H
        int      21h                   ; set signal handler addrs in vector

        sub      ax,ax                 ; set good return code

exit:   mexit                          ; pop registers
        ret      size str - 6          ; return

dossetsighandler  endp

        page

;------------------------------------------------------------------------------

; This routine will get control on  control break, and it will make
;  sure that the environment is acceptable prior to calling the new
;  handler.  NOTE: we expect the new handler to be written in MicroSoft 'C'

RealControlBreakHandler         proc    far

        push    ds
        push    es
        push    di
        push    si
        push    bp
        push    dx
        push    cx
        push    bx
        push    ax

; reestablish the es and ds segment registers before going to 'C'

        mov     ax,seg DGroup
        mov     ds,ax
        mov     es,ax

        call    NextControlBreakHandler

        pop     ax
        pop     bx
        pop     cx
        pop     dx
        pop     bp
        pop     si
        pop     di
        pop     es
        pop     ds

        iret

RealControlBreakHandler         endp

        page

;------------------------------------------------------------------------------

; This routine will get control on the control break, and it will make
;  sure that the environment is acceptable prior to calling the new
;  handler.  NOTE: we expect the new handler to be written in MicroSoft 'C'

RealCriticalErrorHandler        proc    far

        push    ds
        push    es
        push    di
        push    si
        push    bp
        push    dx
        push    cx
        push    bx
        push    ax

; reestablish the es and ds segment registers before going to 'C'

        mov     ax,seg DGroup
        mov     ds,ax
        mov     es,ax

        call    NextControlBreakHandler

        pop     ax
        pop     bx
        pop     cx
        pop     dx
        pop     bp
        pop     si
        pop     di
        pop     es
        pop     ds

        iret

RealCriticalErrorHandler        endp

        page

;------------------------------------------------------------------------------

DummyControlBreakHandler        proc    far

                iret

DummyControlBreakHandler        endp

DummyCriticalErrorHandler       proc    far

                iret

DummyCriticalErrorHandler       endp



dosxxx      ends

            end
