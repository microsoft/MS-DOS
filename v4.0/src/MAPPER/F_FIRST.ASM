page 80,132

title CP/DOS  DosFindFirst  mapper


        include find.inc

FindSegment     segment word public 'find'

                        public  SearchCount
SearchCount             dw      0
                        public  ReturnBufferSave
ReturnBufferSave        dd      0
                        public  CurrentDTA
CurrentDTA              dw      0
                        public  ReturnLengthToGo
ReturnLengthToGo        dw      0

                        public  SaveDTA
SaveDTA                 Label   dword
                        public  SaveDTAOffset
SaveDTAOffset           dw      0
                        public  SaveDTASegment
SaveDTASegment          dw      0
                        public  SaveDTAFlag
SaveDTAFlag             db      0               ; 0 -> not saved
                                                ; 1 -> is saved

; We will use the offset into the segment 'FindSegment' as the handle that we
;  return and use in subsequent FindNext and FindClose calls.  The data that is
;  in the word is the offset into the 'FindSegment' to the DTA that we should
;  use.

                public  FindDTAs
FindDTAs        label   word
                rept    MaxFinds
                dtastr  <>
                endm

                public  FindHandles
FindHandles     label   word
FindDTAIndex    =       0
                rept    MaxFinds
                dw      FindDTAs + FindDTAIndex
FindDTAIndex    =       FindDTAIndex + size dtastr
                endm


FindSegment     ends

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

; ************************************************************************* *
; *
; *      MODULE: DosFindFirst
; *
; *      FILE NAME: DOS021.ASM
; *
; *      FUNCTION: This module Finds the first filename that matches the
; *                specified file specification.  The directory handle
; *                parameter passed will be ignored since PC/DOS does not
; *                support directory handles.  The last access, last write
; *                and the creation date and time are all set to the same,
; *                because PC/DOS does not have seperate last access and
; *                last write fields in the directory.  The allocation
; *                fields are set equal to the eod because of the same
; *                reason.
; *
; *      CALLING SEQUENCE:
; *
; *                PUSH@ ASCIIZ  FileName      ; File path name
; *                PUSH@ WORD    DirHandle     ; Directory search handle
; *                PUSH  WORD    Attribute     ; Search attribute
; *                PUSH@ OTHER   ResultBuf     ; Result buffer
; *                PUSH  DWORD   ResultBufLen  ; Result buffer length
; *                PUSH@ WORD    SearchCount   ; # of entries to find
; *                PUSH  DWORD   0             ; Reserved (must be zero)
; *                CALL  DosFindFirst
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
; *                       DOS int 21H function 4EH
; *                       DOS int 21H function 4FH
; *
; *************************************************************************
;
        public  DosFindFirst
        .sall
        .xlist
        include macros.inc
        .list


str     struc
old_bp          dw      ?
return          dd      ?
ReservedZero    dd      0       ; reserved
FindCountPtr    dd      ?       ; number of entries to find
FindBufferLen   dw      ?       ; result buffer lenght
FindBufferPtr   dd      ?       ; result buffer pointer
FileAttribute   dw      ?       ; search attribute
DirHandlePtr    dd      ?       ; directory search handle
PathNamePtr     dd      ?       ; file path name pointer
str     ends


DosFindFirst  proc   far

        Enter   DosFindFirst

        mov     ax,seg FindSegment      ; get address to our data
        mov     ds,ax
        assume  ds:FindSegment

; Search for an available Find Handle

; The Dir handle that we will return is the offset into the 'FindSegment' that
;  the pointer to the DTA for that handle is at.  Two special things:
;
;       1) when we see file handle one, will use the first pointer and DTA
;       2) the high order bit of the DTA pointer is used to indicate that
;           the handle is allocated

        mov     si,offset FindSegment:FindHandles
        mov     cx,MaxFinds

; DS:[SI] -> Find DTA Pointer Table
; CX = number of Find DTAs

; Incoming DirHandle = -1 ==> allocate a new dir handle

        les     di,[bp].DirHandlePtr
        mov     ax,es:[di]
        cmp     ax,-1
        je      AllocateHandle

; Incoming DirHandle = 1, we will use the first DTA

        cmp     ax,1
        je      HandleFound

; We have not been requested to allocate a new handle, and we are not using
; DirHandle 1.  At this time, we need to reuse the incoming handle, but only
; if it is a valid (ie - previously allocated by us) DirHandle

        mov     si,ax                     ; verify it is an active handle
        test    ds:[si],OpenedHandle
        jnz     HandleFound               ; jump if true

        mov     ax,6                      ; else set error code
        jmp     ErrorExit                 ; return

; Allocate a new handle from the DTA pointer list

AllocateHandle:
        add     si,2
        dec     cx

FindHandleLoop:
        test    ds:[si],OpenedHandle
        jz      HandleFound

        add     si,2
        loop    FindHandleLoop

; No Handles available, return error

        mov     ax,4               ; report 'no handles available'
        jmp     ErrorExit          ; error return - buffer not large enough


; We have a handle, let's look for the file(s)

HandleFound:
        mov     ax,ds:[si]              ; get the dta pointer
        or      ds:[si],OpenedHandle    ; allocate the handle
        and     ax,not OpenedHandle
        mov     CurrentDTA,ax

        les     di,[bp].DirHandlePtr    ; the handle number we return is the
        mov     es:[di],si              ;  offset to the entry in FindSegment

; save the callers dta so we can restore it later

        mov     ah,02fh                 ; get callers DTA
        int     21h

        mov     SaveDTAOffset,bx        ; save it
        mov     SaveDTASegment,es
        mov     SaveDTAFlag,1

; Set the dta to our area

        mov     dx,CurrentDTA           ; set DTA address
        mov     ah,1ah
        int     21h

; Get the count of files to search for

        les     di,[bp].FindCountPtr    ; load result buffer pointer
        mov     ax,es:[di]              ; save the search
        mov     SearchCount,ax          ;                count
        mov     es:word ptr [di],0      ; set found count to zero

        cmp     ax,0                    ; just in case they try to trick us!
        jne     DoSearch

        jmp     SearchDone

;  Find first file

DoSearch:
        lds     dx,[bp].PathNamePtr    ; load address of asciiz string
        assume  ds:nothing
        mov     cx,[bp].FileAttribute  ; load the attribute
        mov     ax,04E00h
        int     21h                    ; find the first occurance of file
        jnc     FindFirstOK            ; continue

        jmp     ErrorExit

FindFirstOK:
        mov     ax,seg FindSegment
        mov     ds,ax
        assume  ds:FindSegment

        mov     ax,[bp].FindBufferLen  ; load the buffer length
        mov     ReturnLengthToGo,ax    ; save low order buffer length

        les     di,[bp].FindBufferPtr  ; load result buffer pointer

        mov     word ptr ReturnBufferSave+0,di
        mov     word ptr ReturnBufferSave+2,es

; Move find data into the return areas

MoveFindData:
        sub     ReturnLengthToGo,size FileFindBuf ; check if result buffer is larg enough
        jnc     BufferLengthOk         ; it is ok

        mov     ax,8                   ; report 'Insufficient memory'
        jmp     ErrorExit              ; error return - buffer not large enough

BufferLengthOk:
        mov     si,CurrentDTA          ; DS:SI -> our dta area
        les     di,ReturnBufferSave

; At this point, the following MUST be true:
;       es:di -> where we are to put the resultant data
;       ds:si -> DTA from find (either first or next)

        mov     ax,ds:[si].DTAFileDate    ; save date
        mov     es:[di].Create_Date,ax
        mov     es:[di].Access_Date,ax
        mov     es:[di].Write_Date,ax

        mov     ax,ds:[si].DTAFileTime    ; save time
        mov     es:[di].Create_Time,ax
        mov     es:[di].Access_Time,ax
        mov     es:[di].Write_Time,ax

        mov     ax,ds:word ptr [si].DTAFileSize+0    ; save file size
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

        mov     ax,04f00h          ; set opcode
        int     21h                ; find next matching file
        jc      ErrorExit          ; jump if error

        les     di,ReturnBufferSave     ;
        jmp     MoveFindData

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
        mov     ah,1ah                     ; load opcode
        int     21h                        ; setup DTA

DoNotRestore:
        pop     ax

        mexit                              ; pop registers
        ret     size str - 6               ; return

DosFindFirst endp

dosxxx  ends

        end
