






;
;******************************************************************************
; Message Macro Definitions
;******************************************************************************
;

      EXTRN Display_Interface:near


;-----------------------------------------------------------------------------

MESSAGE macro   Message_Name                    ;                               ;AN000;
                                                ;
        mov     dx,offset Message_Name          ;                               ;AN000;
        call    Display_Interface               ;                               ;AN000;
                                                ;
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

Parse_Message macro                                                             ;AN000;


        push    ds                                                              ;AN000;
        mov     dx,SEG parse_ptr                                                ;AN000;
        mov     ds,dx                                                           ;AN000;
        ASSUME  DS:DATA                                                         ;AN000;
        ASSUME  ES:DATA                                                         ;AN000;
        mov     word ptr Parse_Error_Msg,ax                                     ;AN000;
        mov     dx,offset Parse_Error_Msg       ;                               ;AN000;
        call    Display_Interface               ;                               ;AN000;
        pop     ds
        endm                                    ;                               ;AN000;

;-----------------------------------------------------------------------------

Extend_Message macro                            ;                               ;AN001;

                                                ;
        push    ds                                                              ;AN001;
        mov     dx,SEG parse_ptr                                                ;AN001;
        mov     ds,dx                                                           ;AN001;
        ASSUME  DS:DATA                                                         ;AN001;
        ASSUME  ES:DATA                                                         ;AN001;
        mov     word ptr Extend_Error_Msg,ax     ;                              ;AN001;
        mov     dx,offset Extend_Error_Msg       ;                              ;AN001;
        call    Display_Interface               ;                               ;AN001;
        pop     ds                                                              ;AN001;
        endm                                    ;                               ;AN001;

;-----------------------------------------------------------------------------

