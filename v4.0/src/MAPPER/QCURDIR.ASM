;
page 80,132
;
title CP/DOS DosQCurDir mapper

buffer  segment word public 'buffer'
CurrentDirectoryBuffer db      128 dup(?)
buffer  ends

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;**********************************************************************
;*
;*   MODULE:   dosqcurdir
;*
;*   FILE NAME: dos036.asm
;*
;*   CALLING SEQUENCE:
;*
;*       push      word    drive number (0=default, 1=a, etc.)
;*       push@     other   dirpath
;*       push@     other   dirpathlen
;*
;*       call      doqcurdir
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=47h, get current directory
;*
;*********************************************************************

            public   dosqcurdir
            .sall
            include  macros.inc

str         struc
old_bp      dw       ?
return      dd       ?
BufferLengthPtr dd      ?    ; directory path buffer length pointer
BufferPtr       dd      ?    ; directory path buffer pointer
Drive           dw      ?    ; driver number
str         ends


dosqcurdir  proc     far

        Enter   Dosqcurdir               ; push registers

        mov     ax,seg buffer            ; set temporary buffer  to receive
        mov     ds,ax                    ; dircetory path information
        assume  ds:buffer
        mov     si,offset buffer:CurrentDirectoryBuffer
        mov     dx,[bp].drive            ; set driver number

        mov     ah,47h
        int     21h                      ; get directory path information
        jc      ErrorExit                ; check for error

        mov     di,ds
        mov     es,di
        assume  es:buffer

; next calculate the size of the path name just received

        mov     di,offset buffer:CurrentDirectoryBuffer
        mov     cx,128
        mov     al,0                     ; look for the non-ascii chara
        cld                              ; in the buffer indciates the
        repne   scasb                    ; end of the path.

        mov     dx,128
        sub     dx,cx                    ; calculate actual path length

        les     di,[bp].BufferLengthPtr  ; set path buffer lenght pointer
        assume  es:nothing
        mov     cx,es:[di]               ; check for directory path
                                         ; buffe size
        cmp     cx,dx                    ; compare with needed length
        jnc     HaveThePathLength        ; branch if length is ok

        mov     ax,8                     ; else, set error code
        jmp     ErrorExit                ; return

HaveThePathLength:
        mov     cx,dx
        mov     es:[di],dx               ; return path length

        les     di,[bp].BufferPtr        ; prepare to move directory path name
                                         ; into return buffer
        mov     si,offset buffer:CurrentDirectoryBuffer

        rep     movsb                    ; copy dir path to return buffer

        sub     ax,ax                    ; set good return

ErrorExit:
        mexit                            ; pop registers
        ret      size str - 6            ; return

dosqcurdir  endp

dosxxx      ends

            end

