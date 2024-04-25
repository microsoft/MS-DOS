;
page 80,132
;
title CP/DOS  DosFindNext   mapper
;

        include find.inc

FindSegment     segment word public 'find'

                        extrn   SearchCount:word
                        extrn   ReturnBufferSave:dword
                        extrn   CurrentDTA:word
                        extrn   ReturnLengthToGo:word

                        extrn   SaveDTA:dword
                        extrn   SaveDTAOffset:word
                        extrn   SaveDTASegment:word
                        extrn   SaveDTAFlag:byte

; We will use the offset into the segment 'FindSegment' as the handle that we
;  return and use in subsequent FindNext and FindClose calls.  The data that is
;  in the word is the offset into the 'FindSegment' to the DTA that we should
;  use.

                extrn   FindDTAs:word

                extrn   FindHandles:word

FindSegment     ends

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
; ************************************************************************* *
; *
; *      MODULE: DosFindNext
; *
; *      FILE NAME: DOS022.ASM
; *
; *      FUNCTION: This module finds the next file in a sequence initiated
; *                by the find first the command.
; *
; *
; *
; *
; *      CALLING SEQUENCE:
; *
; *                PUSH  WORD    DirHandle     ; Directory search handle
; *                PUSH@ OTHER   ResultBuf     ; Result buffer
; *                PUSH  DWORD   ResultBufLen  ; Result buffer length
; *                PUSH@ WORD    SearchCount   ; # of entries to find
; *                CALL  DosFindNext
; *
; *
; *      RETURN SEQUENCE:
; *
; *                IF ERROR (AX not = 0)
; *
; *                   AX = Error Code:
; *
; *                   o   Invalid file path name
; *
; *                   o   Invalid search attribute
; *
; *      MODULES CALLED:  DOS int 21H function 2FH
; *                       DOS int 21H function 4FH
; *
; *************************************************************************
;
        public  DosFindNext
        .sall
        .xlist
        include macros.inc
        .list
;

str     struc
old_bp          dw      ?
return          dd      ?
FindCountPtr    dd      ?
FindBufferLen   dw      ?
FindBufferPtr   dd      ?       ;Changed to DW to match the DOSCALL.h  PyL 6/1 Rsltbuf21       dd    ?
DirHandle       dw      ?
str     ends

;
DosFindNext  proc   far


        Enter   DosFindNext

        mov     ax,seg FindSegment      ; get address to our data
        mov     ds,ax
        assume  ds:FindSegment

; check for a valid dir handle

; Special Logic to handle DirHandle = 1

        mov     si,[bp].DirHandle
        cmp     si,1
        jne     CheckForNext

        mov     si,offset FindSegment:FindHandles

CheckForNext:
        test    ds:[si],OpenedHandle
        jnz     OkToFindNext

        mov     ax,6
        jmp     ErrorExit

OkToFindNext:

; We have a handle, let's look for the file(s)

HandleFound:
        mov     si,ds:[si]              ; get the DTA pointer
        and     si,not OpenedHandle     ;  and get rid of the allocated flag
        mov     CurrentDTA,si           ;   and save the current DTA value

; save the callers dta so we can restore it later

        mov     ah,02fh
        int     21h
        mov     SaveDTAOffset,bx
        mov     SaveDTASegment,es
        mov     SaveDTAFlag,1

; Set the dta to our area

        mov     dx,CurrentDTA
        mov     ah,1ah
        int     21h

; Get the count of files to search for

        les     di,[bp].FindCountPtr  ; load result buffer pointer
        mov     ax,es:[di]            ; save the search
        mov     SearchCount,ax        ;                count
        mov     es:word ptr [di],0    ; set found count to zero

        cmp     ax,0                    ; just in case they try to trick us!
        jne     DoSearch

        jmp     SearchDone

;  Find first file

DoSearch:
        mov     ax,[bp].FindBufferLen ; load the buffer length
        mov     ReturnLengthToGo,ax   ; save low order buffer length

        les     di,[bp].FindBufferPtr ; load result buffer pointer
        mov     word ptr ReturnBufferSave+0,di
        mov     word ptr ReturnBufferSave+2,es

DoFindNext:
        mov     ax,4f00h
        int     21h
        jnc     MoveFindData

        jmp     ErrorExit

; Move find data into the return areas

MoveFindData:
        sub     ReturnLengthToGo,size FileFindBuf ; check if result buffer is larg enough
        jnc     BufferLengthOk        ; it is ok

        mov     ax,8               ; report 'Insufficient memory'
        jmp     ErrorExit          ; error return - buffer not large enough

BufferLengthOk:
        mov     si,CurrentDTA           ; DS:SI -> our dta area
        les     di,ReturnBufferSave

; At this point, the following MUST be true:
;       es:di -> where we are to put the resultant data
;       ds:si -> DTA from find (either first or next)

        mov     ax,ds:[si].DTAFileDate
        mov     es:[di].Create_Date,ax
        mov     es:[di].Access_Date,ax
        mov     es:[di].Write_Date,ax

        mov     ax,ds:[si].DTAFileTime
        mov     es:[di].Create_Time,ax
        mov     es:[di].Access_Time,ax
        mov     es:[di].Write_Time,ax

        mov     ax,ds:word ptr [si].DTAFileSize+0
        mov     es:word ptr [di].File_Size+0,ax
        mov     es:word ptr [di].FAlloc_Size+0,ax
        mov     ax,ds:word ptr [si].DTAFileSize+2
        mov     es:word ptr [di].File_Size+2,ax
        mov     es:word ptr [di].FAlloc_Size+2,ax

        test    es:word ptr [di].FAlloc_Size,001ffh
        jz      AllocateSizeSet

        and     es:word ptr [di].FAlloc_Size,not 001ffh
        add     es:word ptr [di].FAlloc_Size,00200h

AllocateSizeSet:
        xor     ax,ax
        mov     al,ds:[si].DTAFileAttrib
        mov     es:[di].Attributes,ax

        mov     cx,12
        mov     bx,0

MoveNameLoop:
        mov     al,ds:[si+bx].DTAFileName
        cmp     al,0
        je      EndOfName

        mov     es:[di+bx].File_Name,al
        inc     bx
        loop    MoveNameLoop

EndOfName:
        mov     es:[di+bx].File_Name,0
        mov     ax,bx
        mov     es:[di].String_len,al

        add     di,bx
        mov     word ptr ReturnBufferSave+0,di
        mov     word ptr ReturnBufferSave+2,es

        les     di,[bp].FindCountPtr
        inc     word ptr es:[di]

;
;  Check if the request was for more than one
;
        dec     SearchCount
        jz      SearchDone

        jmp     DoFindNext

SearchDone:
        sub     ax,ax              ; set good return code

ErrorExit:
        push    ax
        mov     ax,seg FindSegment
        mov     ds,ax
        assume  ds:FindSegment
        cmp     SaveDTAFlag,0
        je      DoNotRestore

        mov     SaveDTAFlag,0

        lds     dx,SaveDTA
        mov     ah,1ah
        int     21h

DoNotRestore:
        pop     ax

        mexit

        ret     size str - 6

DosFindNext endp

dosxxx  ends

        end
