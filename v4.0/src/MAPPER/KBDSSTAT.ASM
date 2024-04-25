;
page 80,132
;
title CP/DOS KbdSetStatus

        .sall
        .xlist
        include kbd.inc       ; kbd set status data structure
        .list

kbddata segment word public 'kbddata'

        extrn   KbdBitMask:word
        extrn   KbdTurnAroundCharacter:word
        extrn   KbdInterimCharFlags:word

kbddata ends



kbdxxx  segment byte public 'kbd'
        assume  cs:kbdxxx,ds:nothing,es:nothing,ss:nothing
;
; ************************************************************************* *
; *
; *      MODULE:  kbdsetStatus
; *
; *
; *      CALLING SEQUENCE:
; *
; *                PUSH@ DWORD   data              ;  kbd data structure
; *                PUSH  WORD    handle            ;  kbd handle
; *
; *                CALL  kbdsetstatus
; *
; *      RETURN SEQUENCE:
; *
; *
; *
; *************************************************************************
;
        public kbdsetstatus

str     struc
old_bp  dw      ?
return  dd      ?
handle  dw      ?       ; kbd handle
data    dd      ?       ; kbd data strructure pointer
str     ends

kbdsetstatus    proc    far

        Enter   KbdSetStatus            ; save registers

        les     di,[bp].data            ; set up kbd data structure
        mov     ax,seg kbddata
        mov     ds,ax
        assume  ds:kbddata

        mov     ax,es:[di].Bit_Mask     ; get bit mask

CheckTurnAround:
        test    ax,040h                 ; define turnaround character ??
        jz      CheckInterimFlags       ; jump if not

        mov     bx,es:[di].Turn_Around_Char  ; else, save turnaround character
        mov     KbdTurnAroundCharacter,bx

CheckInterimFlags:
        test    ax,020h                 ; check for interim character flag ??
        jz      CheckShiftState         ; if not jump

        mov     bx,es:[di].Interim_Char_Flags   ; save interim character flag
        mov     KbdInterimCharFlags,bx

CheckShiftState:
        test    ax,010h                 ; check for shift state ??
        jz      CheckCookedOn           ; jump if not

        push    ds                      ; setup for shift state
        mov     bx,040h
        mov     ds,bx
        assume  ds:nothing

        mov     bx,es:[di].Status_Shift_State   ; save shift state data
        mov     ds:018h,bl

        pop     ds
        assume  ds:kbddata

CheckCookedOn:                              ; check for cooked mode ??
        test    ax,008h
        jz      CheckRawOn

        and     KbdBitMask,not RawModeOn    ; setup cooked mode status
        or      KbdBitMask,CookedModeOn

CheckRawOn:
        test    ax,004h                     ; check for raw mdoe ??
        jz      CheckEchoOff

        and     KbdBitMask,not CookedModeOn ; setup for raw mode
        or      KbdBitMask,RawModeOn

CheckEchoOff:
        test    ax,002h                     ; check for echo on
        jz      CheckEchoOn                 ; branch if so

        and     KbdBitMask,not EchoOn       ; else setup echo off
        or      KbdBitMask,EchoOff

CheckEchoOn:
        test    ax,001h
        jz      EverythingSet

        and     KbdBitMask,not EchoOff      ; setup echo on
        or      KbdBitMask,EchoOn

EverythingSet:
        Mexit                               ; pop registers

        ret     size str - 6                ; return

KbdSetStatus    endp

kbdxxx  ends

        end

