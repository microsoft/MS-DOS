






;
;******************************************************************************
; Message Macro Definitions
;******************************************************************************
;

      EXTRN Display_Interface:near


;-----------------------------------------------------------------------------

Message macro   Message_Name                    ;                               ;AN000;
                                                ;
        mov     dx,offset data:Message_Name     ;                               ;AN000;
        call    Display_Interface               ;                               ;AN000;
        endm                                    ;                               ;AN000;

;-----------------------------------------------------------------------------

Parse_Message macro                             ;                               ;AN000;

                                                ;
        push    ds
        mov     dx,data
        mov     ds,dx
        mov     word ptr Parse_Error_Msg,ax     ;                               ;AN000;
        mov     dx,offset Parse_Error_Msg       ;                               ;AN000;
        call    Display_Interface               ;                               ;AN000;
        pop     ds                              ;
        endm                                    ;                               ;AN000;

;-----------------------------------------------------------------------------

Extended_Message macro                          ;                               ;AN000;
                                                ;

        push    ds
        mov     dx,data
        mov     ds,dx
        mov     word ptr Extended_Error_Msg,ax       ;                               ;AN000;
        mov     dx,offset data:Extended_Error_Msg    ;                               ;AN000;
        call    Display_Interface               ;                               ;AN000;
        pop     ds
        endm                                    ;                               ;AN000;

;
;*****************************************************************************
; General Macro's
;*****************************************************************************
;

Procedure       macro   Proc_Name

Public  Proc_Name
Proc_Name    proc

        endm
;-----------------------------------------------------------------------------

DOS_Call        macro   Function

        mov     ah,Function
        int     21h

        endm
;-----------------------------------------------------------------------------

Popff   macro

        jmp     $+3
        iret
        push    cs
        call    $-2

        endm


;-----------------------------------------------------------------------------

Set_Data_Segment     macro

        push    ax
        mov     ax,data                         ;Point to data segment
        mov     ds,ax                           ;
        push    ds
        pop     es
        pop     ax

assume  ds:data,es:data

        endm



