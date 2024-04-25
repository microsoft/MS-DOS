

CODE    SEGMENT PARA PUBLIC 'CODE'
CODE    ENDS
DATA    SEGMENT PARA PUBLIC 'DATA'
DATA    ENDS
STACK   SEGMENT PARA STACK  'STACK'
STACK   ENDS
ZLOAD   SEGMENT PARA PUBLIC 'ZLOAD'
ZLOAD   ENDS

CODE    SEGMENT PARA PUBLIC 'CODE'
        assume  cs:code,ds:data
;
;*****************************************************************************
; External Declarations
;*****************************************************************************
;

        extrn   SysDispMsg:near

;
;***************************************************************************
; Message Structures
;***************************************************************************
;


Message_Table struc                             ;                               ;AN000;
                                                ;
Entry1  dw      0                               ;                               ;AN000;
Entry2  dw      0                               ;                               ;AN000;
Entry3  dw      0                               ;                               ;AN000;
Entry4  dw      0                               ;                               ;AN000;
Entry5  db      0                               ;                               ;AN000;
Entry6  db      0                               ;                               ;AN000;
Entry7  dw      0                               ;                               ;AN000;
                                                ;
Message_Table ends                              ;                               ;AN000;



;*****************************************************************************
;Routine name&gml Display_Interface
;*****************************************************************************
;
;DescriptioN&gml Save all registers, set up registers required for SysDispMsg
;             routine. This information is contained in a message description
;             table pointed to by the DX register. Call SysDispMsg, then
;             restore registers. This routine assumes that the only time an
;             error will be returned is if an extended error message was
;             requested, so it will ignore error returns
;
;Called Procedures: Message (macro)
;
;Change History&gml Created        4/22/87         MT
;
;Input&gml ES&gmlDX = pointer to message description
;
;Output&gml None
;
;Psuedocode
;----------
;
;       Save all registers
;       Setup registers for SysDispMsg from Message Description Tables
;       CALL SysDispMsg
;       Restore registers
;       ret
;*****************************************************************************

Public  Display_Interface
Display_Interface   proc                        ;                               ;AN000;

        push    ds                              ;                               ;AN000;
        push    es                              ;                               ;AN000;
        push    ax                              ;Save registers                 ;AN000;
        push    bx                              ; "  "    "  "                  ;AN000;
        push    cx                              ; "  "    "  "                  ;AN000;
        push    dx                              ; "  "    "  "                  ;AN000;
        push    si                              ; "  "    "  "                  ;AN000;
        push    di                              ; "  "    "  "                  ;AN000;
        mov     di,dx                           ;Change pointer to table        ;AN000;
        mov     dx,SEG data                     ;Point to data segment
        mov     ds,dx                           ;
        mov     es,dx
        mov     ax,[di].Entry1                  ;Message number                 ;AN000;
        mov     bx,[di].Entry2                  ;Handle                         ;AN000;
        mov     si,[di].Entry3                  ;Sublist                        ;AN000;
        mov     cx,[di].Entry4                  ;Count                          ;AN000;
        mov     dh,[di].Entry5                  ;Class                          ;AN000;
        mov     dl,[di].Entry6                  ;Function                       ;AN000;
        mov     di,[di].Entry7                  ;Input                          ;AN000;
        call    SysDispMsg                      ;Display the message            ;AN000;
        pop     di                              ;Restore registers              ;AN000;
        pop     si                              ; "  "    "  "                  ;AN000;
        pop     dx                              ; "  "    "  "                  ;AN000;
        pop     cx                              ; "  "    "  "                  ;AN000;
        pop     bx                              ; "  "    "  "                  ;AN000;
        pop     ax                              ; "  "    "  "                  ;AN000;
        pop     es                              ;                               ;AN000;
        pop     ds                              ;                               ;AN000;
        ret                                     ;All done                       ;AN000;

Display_Interface      endp                     ;                               ;AN000;
code    ends


        end
