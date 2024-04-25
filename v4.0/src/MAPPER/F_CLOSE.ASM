page 80,132

title CP/DOS  DosFindClose  mapper

        include find.inc


FindSegment     segment word public 'find'

; We will use the offset into the segment 'FindSegment' as the handle that we
;  return and use in subsequent FindNext and FindClose calls.  The data that is
;  in the word is the offset into the 'FindSegment' to the DTA that we should
;  use.
                extrn   FindDTAs:word
                extrn   FindHandles:word

FindSegment     ends


; ************************************************************************* *
; *
; *      MODULE: DosFindClose
; *
; *      FUNCTION:  Close Find Handle
; *
; *      FUNCTION: This module closes the directory handle used by CP/DOS
; *                in a find first/find next search.  Since PC/DOS does not
; *                use directory handles it will simply return to the caller
; *                removing the parameters passed on the stack.
; *
; *      CALLING SEQUENCE:
; *
; *                PUSH  WORD  DirHandle   ; Directory search handle
; *                CALL DosFindClose
; *
; *
; *      RETURN SEQUENCE:
; *
; *                IF ERROR (AX not = 0)
; *
; *                   AX = Error Code:
; *
; *
; *      MODULES CALLED:  None
; *
; *************************************************************************

        public  DosFindClose
        .sall
        .xlist
        include macros.inc
        .list

str     struc
old_bp    dw      ?
return    dd      ?
DirHandle dw      ?           ; dirctory search handle
str     ends


dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

DosFindClose  proc   far
        Enter   DosFindClose               ; push registers

        mov     ax,seg FindSegment         ; get address to our data
        mov     ds,ax
        assume  ds:FindSegment

; Close the handle

; The 'DirHandle' that the mapper returns from FindFirst, is the offset into
; 'FindSegment' of the pointer to the DTA for that Handle.  The 08000h bit
; of the pointer is used to indicate that the handle is open.  Reset the bit.

; Special Logic to handle DirHandle = 1

        mov     si,[bp].DirHandle          ; get directory hanlde
        cmp     si,1                       ; handle = 1??
        jne     CheckForClose              ; branch if not

        mov     si,offset FindSegment:FindHandles

CheckForClose:
        test    ds:[si],OpenedHandle       ; handle is open ??
        jnz     OkToClose                  ; go and close if it is open

        mov     ax,6                       ; else load error code
        jmp     ErrorExit                  ; return

OkToClose:
        and     ds:[si],not OpenedHandle   ; set close flag
        xor     ax,ax                      ; set good return code

ErrorExit:
        mexit                              ; pop registers
        ret     size str - 6               ; return

DosFindClose endp

dosxxx  ends

        end
