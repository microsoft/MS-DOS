                                                                                ;an000;bgb
;                                                                               ;an000;bgb
;*****************************************************************************  ;an000;bgb
; Macro's                                                                       ;an000;bgb
;*****************************************************************************  ;an000;bgb
;                                                                               ;an000;bgb
                                                                                ;an000;bgb
                                                                                ;an000;bgb
Define_Msg macro Message_Name                   ;                               ;AN000;
                                                ;                               ;an000;bgb
Create_Msg Message_Name,Message_Number,Handle,Sublist,Count,Class,Function,Input;AN000;
                                                ;                               ;an000;bgb
        endm                                    ;                               ;AN000;
                                                                                ;an000;bgb
;-----------------------------------------------------------------------------  ;an000;bgb
                                                                                ;an000;bgb
Create_Msg macro Parm1,Parm2,Parm3,Parm4,Parm5,Parm6,Parm7,Parm8;               ;AN000;
                                                                                ;an000;bgb
Public  Parm1                                                                   ;an000;bgb
Parm1   label   word                            ;                               ;AN000;
        dw      Parm2                           ;                               ;AN000;
        dw      Parm3                           ;                               ;AN000;
        dw      Parm4                           ;                               ;AN000;
        dw      Parm5                           ;                               ;AN000;
        db      Parm6                           ;                               ;AN000;
        db      Parm7                           ;                               ;AN000;
        dw      Parm8                           ;                               ;AN000;
        endm                                    ;                               ;AN000;
                                                                                ;an000;bgb
                                                                                ;an000;bgb
;                                                                               ;an000;bgb
;*****************************************************************************  ;an000;bgb
; External data declarations                                                    ;an000;bgb
;*****************************************************************************  ;an000;bgb
;                                                                               ;an000;bgb
                                                                                ;an000;bgb
        Extrn   Arg_Buf:Byte                                                    ;an000;bgb
ifdef fsexec                                                                    ;an038;bgb
        Extrn   Drive_Letter_Msg:Byte                                           ;an038;bgb;an000;bgb
endif                                                                           ;an038;bgb
        Extrn   TChar:Byte                                                      ;an000;bgb
        Extrn   Cross_Clus:Byte                                                 ;an000;bgb
        extrn   sernum:word                                                     ;an024;bgb
;                                                                               ;an000;bgb
;*****************************************************************************  ;an000;bgb
; Public Data                                                                   ;an000;bgb
;*****************************************************************************  ;an000;bgb
;                                                                               ;an000;bgb
                                                                                ;an000;bgb
        Public  Sublist_msg_Idmes                                               ;an000;bgb
        Public  BadDrvm                                                         ;an000;bgb
        Public  YES_BYTE                                                        ;an000;bgb
        Public  NO_BYTE                                                         ;an000;bgb
        Public  yn_arg                                                          ;an000;bgb
        Public  orphcnt                                                         ;an000;bgb
        Public  report_arg                                                      ;an000;bgb
        Public  rarg1                                                           ;an000;bgb
        Public  rarg3                                                           ;an000;bgb
        Public  badrw_str                                                       ;an000;bgb
        Public  badrw_num                                                       ;an000;bgb
        Public  block_num                                                       ;an000;bgb
        Public  fatal_arg1                                                      ;an000;bgb
        Public  fatal_arg2                                                      ;an000;bgb
        Public  file_arg1                                                       ;an000;bgb
        Public  file_arg2                                                       ;an000;bgb
        Public  free_arg1                                                       ;an000;bgb
        Public  free_arg2                                                       ;an000;bgb
        Public  free_arg3                                                       ;an000;bgb
        Public  Fatal_End                                                       ;an000;bgb
        Public  MonTab                                                          ;an000;bgb
        public  fatmsg1                 ;an024;bgb                              ;an000;bgb
        public  fatmsg2                 ;an024;bgb                              ;an000;bgb
        extrn   orphsiz:word                                                    ;an049;bgb
                                                                                ;an000;bgb
;                                                                               ;an000;bgb
;*****************************************************************************  ;an000;bgb
; Message Retriever equates                                                     ;an000;bgb
;*****************************************************************************  ;an000;bgb
;                                                                               ;an000;bgb
                                                                                ;an000;bgb
                                                                                ;an000;bgb
Format_Msg              equ     'C'                                             ;an000;bgb
                                                                                ;an000;bgb
N_A                     equ     0                                               ;an000;bgb
None                    equ     0                                               ;an000;bgb
                                                                                ;an000;bgb
Blank                   equ     " "                                             ;an000;bgb
No_Function             equ     0                                               ;an000;bgb
                                                                                ;an000;bgb
                                                                                ;an000;bgb
                                                                                ;an000;bgb
                                                                                ;an000;bgb
data    segment public para 'data'              ; AN000;                        ;an000;bgb
                                                                                ;an000;bgb
;                                                                               ;an000;bgb
;*****************************************************************************  ;an000;bgb
; Message Sublist Tables                                                        ;an000;bgb
;*****************************************************************************  ;an000;bgb
;                                                                               ;an000;bgb
;The  following  control  blocks  are   used   for   messages  with             ;an000;bgb
;replaceable  paramters.  These  control  blocks  are  used by  the             ;an000;bgb
;SysDispMsg routine.                                                            ;an000;bgb
;                                                                               ;an000;bgb
                                                                                ;an000;bgb
;---------------------------                    ;                               ;an000;bgb
Sublist_msg_Orphmes2    label dword             ;                               ;an000;bgb
Sublist_msg_Orphmes3    label dword             ;                               ;an000;bgb
Sublist_msg_HidMes      label dword             ;                               ;an000;bgb
Sublist_msg_DirMes      label dword             ;                               ;an000;bgb
Sublist_msg_FileMes     label dword             ;                               ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;0bh                            ;an000;bgb;an049;bgb
        db              Reserved                ;00h                            ;an000;bgb;an049;bgb
        dw              rarg1                   ;offset of value                ;an000;bgb;an049;bgb
        dw              dg                      ;segment of value               ;an000;bgb;an049;bgb
        db              1                       ;the first parm                 ;an000;bgb;an049;bgb
        db              Right_Align+Unsgn_Bin_DWord ;type of data               ;an000;bgb;an049;bgb
        db              10                      ;max length of data             ;an000;bgb;an049;bgb
        db              10                      ;min length of data             ;an000;bgb;an049;bgb
        db              Blank                   ;pad character                  ;an000;bgb;an049;bgb
        db              Sublist_Length          ;0bh                            ;an000;bgb;an049;bgb
        db              Reserved                ;00h                            ;an000;bgb;an049;bgb
        dw              rarg3                   ;offset of value                ;an000;bgb;an049;bgb
        dw              dg                      ;segment of value               ;an000;bgb;an049;bgb
        db              2                       ;the second parm                ;an000;bgb;an049;bgb
        db              Left_Align+Unsgn_Bin_DWord;type of data                 ;an000;bgb;an049;bgb
        db              10                      ;max length of data             ;an000;bgb;an049;bgb
        db              1                       ;min length of data             ;an000;bgb;an049;bgb
        db              Blank                   ;pad character                  ;an000;bgb;an049;bgb
;---------------------------                    ;                               ;an000;bgb;an049;bgb
Sublist_msg_dskspc      label dword             ;                               ;an000;bgb;an049;bgb
Sublist_msg_badspc      label dword             ;                               ;an000;bgb;an049;bgb
Sublist_msg_frespc      label dword             ;                               ;an000;bgb;an049;bgb
Sublist_msg_totmem      label dword             ;                               ;an000;bgb;an049;bgb
Sublist_msg_fremem      label dword             ;                               ;an000;bgb;an049;bgb
Sublist_msg_Freebymes   label dword             ;                               ;an000;bgb;an049;bgb
Sublist_msg_alloc       label dword             ;                               ;an000;bgb;an049;bgb
                                                                                ;an000;bgb;an049;bgb
        db              Sublist_Length          ;0bh                            ;an000;bgb;an049;bgb
        db              Reserved                ;00h                            ;an000;bgb;an049;bgb
        dw              dg:rarg1                ;offset  of data                ;an000;bgb;an049;bgb
        dw              dg                      ;segment of data                ;an000;bgb;an049;bgb
        db              1                       ;1st parm                       ;an000;bgb;an049;bgb
        db              Right_Align+Unsgn_Bin_DWord ;type of data               ;an000;bgb;an049;bgb
        db              10                      ;max length of data             ;an000;bgb;an049;bgb
        db              10                      ;min length of data             ;an000;bgb;an049;bgb
        db              Blank                   ;pad character                  ;an000;bgb;an049;bgb
;---------------------------                    ;                               ;an000;bgb;an049;bgb
Sublist_msg_Extents     label   dword           ;                               ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;                               ;an000;bgb
        db              Reserved                ;                               ;an000;bgb
        dw              dg:arg_buf              ;                               ;an000;bgb
        dw              dg                      ;                               ;an000;bgb
        db              1                       ;                               ;an000;bgb
        db              Left_Align+Char_Field_ASCIIZ ;                          ;an000;bgb
        db              64                      ;                               ;an000;bgb
        db              1                       ;                               ;an000;bgb
        db              Blank                   ;                               ;an000;bgb
        db              Sublist_Length          ;                               ;an000;bgb
        db              Reserved                ;                               ;an000;bgb
        dw              dg:rarg1                ;                               ;an000;bgb
        dw              dg                      ;                               ;an000;bgb
        db              2                       ;                               ;an000;bgb
        db              Left_Align+Unsgn_Bin_Word ;                            ;;an000;bgb
        db              5                       ;                               ;an000;bgb
        db              1                       ;                               ;an000;bgb
        db              Blank                   ;                               ;an000;bgb
                                                                                ;an000;bgb
;---------------------------                    ;                               ;an000;bgb
Sublist_msg_Badr_arg    label   dword           ;                               ;an000;bgb
Sublist_msg_Badw_arg    label   dword           ;                               ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;                               ;an000;bgb
        db              Reserved                ;                               ;an000;bgb
        dw              dg:Badrw_Num            ;                               ;an000;bgb
        dw              dg                      ;                               ;an000;bgb
        db              1                       ;                               ;an000;bgb
        db              Left_Align+Unsgn_Bin_Word ;                            ;;an000;bgb
        db              5                       ;                               ;an000;bgb
        db              1                       ;                               ;an000;bgb
        db              Blank                   ;                               ;an000;bgb
;---------------------------                    ;                               ;an000;bgb
Sublist_msg_Badrdmes    label   dword           ;                               ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;                               ;an000;bgb;AN000;
        db              Reserved                ;                               ;an000;bgb;AN000;
        dw              dg:Fatal_End            ;                               ;an000;bgb;AN000;
        dw              dg                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Left_Align+Char_Field_ASCIIZ ;                          ;an000;bgb  ;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Blank                   ;                               ;an000;bgb;AN000;
;---------------------------                    ;                               ;an000;bgb
Sublist_msg_Crossmes    label   dword           ;                               ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;                               ;an000;bgb
        db              Reserved                ;                               ;an000;bgb
        dw              dg:Cross_Clus           ;                               ;an000;bgb
        dw              dg                      ;                               ;an000;bgb
        db              1                       ;                               ;an000;bgb
        db              Left_Align+Unsgn_Bin_Word  ;                            ;an000;bgb
        db              5                       ;                               ;an000;bgb
        db              1                       ;                               ;an000;bgb
        db              Blank                   ;                               ;an000;bgb
;---------------------------                    ;                               ;an000;bgb
Sublist_msg_BadTarg     label   dword           ;                               ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;                               ;an000;bgb
        db              Reserved                ;                               ;an000;bgb
        dw              dg:arg_buf              ;                               ;an000;bgb
        dw              dg                      ;                               ;an000;bgb
        db              1                       ;                               ;an000;bgb
        db              Left_Align+Char_Field_ASCIIZ ;                          ;an000;bgb
        db              64                      ;                               ;an000;bgb
        db              1                       ;                               ;an000;bgb
        db              Blank                   ;                               ;an000;bgb;AN000;
;---------------------------                    ;                               ;an000;bgb
Sublist_msg_IDmes       label   dword           ;                               ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;                               ;an000;bgb;AN000;
        db              Reserved                ;                               ;an000;bgb;AN000;
        dw              dg:arg_buf              ;                               ;an000;bgb;AN000;
        dw              dg                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Left_Align+Char_Field_ASCIIZ ;                          ;an000;bgb  ;AN000;
        db              11                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Blank                   ;                               ;an000;bgb;AN000;
        db              Sublist_Length          ;                               ;an000;bgb;AN000;
        db              Reserved                ;                               ;an000;bgb;AN000;
        dw              0                       ;Date will be entered           ;an000;bgb;AN000;
        dw              0                       ; by PrintID routine            ;an000;bgb;AN000;
        db              2                       ;                               ;an000;bgb;AN000;
        db              Left_Align+Date_MDY_4   ;                               ;an000;bgb;AN000;
        db              10                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Blank                   ;                               ;an000;bgb;AN000;
        db              Sublist_Length          ;                               ;an000;bgb;AN000;
        db              Reserved                ;                               ;an000;bgb;AN000;
        dw              0                       ;Time will be entered           ;an000;bgb;AN000;
        dw              0                       ; by PrintID routine            ;an000;bgb;AN000;
        db              3                       ;                               ;an000;bgb;AN000;
        db              Left_Align+Time_HHMM_Cty;                               ;an000;bgb;AN000;
        db              6                       ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Blank                   ;                               ;an000;bgb;AN000;
                                                                                ;an000;bgb
;---------------------------                    ;                               ;an000;bgb
Sublist_Msg_File_Arg    label   dword           ;an000;dms                      ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;                               ;an000;bgb;AN000;
        db              Reserved                ;                               ;an000;bgb;AN000;
        dw              dg:arg_buf              ;                               ;an000;bgb;AN000;
        dw              dg                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Left_Align+Char_Field_ASCIIZ ;                          ;an000;bgb  ;AN000;
        db              64                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Blank                   ;                               ;an000;bgb;AN000;
                                                                                ;an000;bgb
;---------------------------                    ;                               ;an000;bgb
Sublist_Msg_Noisy       label   dword           ;an000;dms                      ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;                               ;an000;bgb;AN000;
        db              Reserved                ;                               ;an000;bgb;AN000;
        dw              dg:arg_buf              ;                               ;an000;bgb;AN000;
        dw              dg                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Left_Align+Char_Field_ASCIIZ ;                          ;an000;bgb  ;AN000;
        db              64                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Blank                   ;                               ;an000;bgb;AN000;
                                                                                ;an000;bgb
;---------------------------                    ;                               ;an000;bgb
Sublist_Msg_Orphmes     label   dword           ;an000;dms                      ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;0bh                            ;an000;bgb;AN000;
        db              Reserved                ;00h                            ;an000;bgb;AN000;
        dw              dg:orphsiz              ;offset of data                 ;an000;bgb;AN000;;an049;bgb
        dw              dg                      ;segment                        ;an000;bgb;AN000;
        db              1                       ;1st of 2 replaceable parms     ;an000;bgb;AN000;
        db              Left_Align+Unsgn_Bin_Word ;only 64k clusters            ;an000;bgb  ;AN000;
        db              05                      ;max length                     ;an000;bgb;AN000;;an049;bgb
        db              1                       ;min length                     ;an000;bgb;AN000;
        db              Blank                   ;pad                            ;an000;bgb;AN000;
                                                                                ;an000;bgb
        db              Sublist_Length          ;0b                             ;an000;bgb;AN000;
        db              Reserved                ;00                             ;an000;bgb;AN000;
        dw              dg:orphcnt              ;offset                         ;an000;bgb;AN000;
        dw              dg                      ;seg                            ;an000;bgb;AN000;
        db              2                       ;2nd replaceable parm           ;an000;bgb;AN000;
        db              Left_Align+Unsgn_Bin_dword ;double word                 ;an000;bgb;AN000;;an049;bgb
        db              10                      ;max len                        ;an000;bgb;AN000;;an049;bgb
        db              1                       ;min len                        ;an000;bgb;AN000;
        db              Blank                   ;pad char                       ;an000;bgb;AN000;
;---------------------------                    ;                               ;an000;bgb
Sublist_Msg_Direcmes    label   dword           ;an000;dms                      ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;                               ;an000;bgb;AN000;
        db              Reserved                ;                               ;an000;bgb;AN000;
        dw              dg:arg_buf              ;                               ;an000;bgb;AN000;
        dw              dg                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Left_Align+Char_Field_ASCIIZ ;                          ;an000;bgb;AN000;
        db              64                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Blank                   ;                               ;an000;bgb;AN000;
                                                                                ;an000;bgb
Sublist_Msg_Fatalmes    label   dword           ;an000;dms                      ;an000;bgb
                                                                                ;an000;bgb
        db              Sublist_Length          ;                               ;an000;bgb;AN000;
        db              Reserved                ;                               ;an000;bgb;AN000;
fatmsg1 dw              dg:fatal_arg1           ;                               ;an000;bgb;AN024;bgb
        dw              dg                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Left_Align+Char_Field_ASCIIZ ;                          ;an000;bgb  ;AN000;
        db              64                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Blank                   ;                               ;an000;bgb;AN000;
        db              Sublist_Length          ;                               ;an000;bgb;AN000;
        db              Reserved                ;                               ;an000;bgb;AN000;
fatmsg2 dw              dg:fatal_arg2           ;                               ;an000;bgb;AN000;
        dw              dg                      ;                               ;an000;bgb;AN000;
        db              2                       ;number 2 of 2 subs             ;an000;bgb;AN022;bgb
        db              Left_Align+Char_Field_ASCIIZ ;                          ;an000;bgb  ;AN000;
        db              64                      ;                               ;an000;bgb;AN000;
        db              1                       ;                               ;an000;bgb;AN000;
        db              Blank                   ;                               ;an000;bgb;AN000;
;---------------------------                    ;                               ;an000;bgb
ifdef   fsexec                                                                  ;an038;bgb
Sublist_msg_EXECFailure label   dword           ;                               ;an038;bgb;an000;bgb
        db              Sublist_Length          ;                               ;an038;bgb;an000;bgb;AN000;
        db              Reserved                ;                               ;an038;bgb;an000;bgb;AN000;
        dw              dg:Drive_Letter_Msg     ;                               ;an038;bgb;an000;bgb;AN000;
        dw              dg                      ;                               ;an038;bgb;an000;bgb;AN000;
        db              1                       ;                               ;an038;bgb;an000;bgb;AN000;
        db              Left_Align+Char_Field_ASCIIZ ;                          ;an038;bgb;an000;bgb  ;AN000;
        db              2                       ;                               ;an038;bgb;an000;bgb;AN000;
        db              2                       ;                               ;an038;bgb;an000;bgb;AN000;
        db              Blank                   ;                               ;an038;bgb;an000;bgb;AN000;
endif                                                                           ;an000;bgb
                                                                                ;an000;bgb
;---------------------------                    ;                               ;an000;bgb
Sublist_msgSerialNumber label dword             ;                               ;an000;bgb;an024;bgb
        db              Sublist_Length          ;0b                             ;an000;bgb;an024;bgb
        db              Reserved                ;00                             ;an000;bgb;an024;bgb
        dw              offset word ptr sernum+2 ;data field                    ;an000;bgb;an024;bgb
        dw              data                    ;                               ;an000;bgb;an024;bgb
        db              1                       ;#1 of 2                        ;an000;bgb;an024;bgb
        db              Right_Align+Bin_Hex_Word ;format                        ;an000;bgb;an024;bgb
        db              4                       ;min len                        ;an000;bgb;an024;bgb
        db              4                       ;max len                        ;an000;bgb;an024;bgb
        db              '0'                     ;Display leading 0's            ;an000;bgb;an024;bgb
                                                                                ;an000;bgb;an024;bgb
        db              Sublist_Length          ;0b                             ;an000;bgb;an024;bgb
        db              Reserved                ;00                             ;an000;bgb;an024;bgb
        dw              offset sernum           ;data field                     ;an000;bgb;an024;bgb
        dw              data                    ;                               ;an000;bgb;an024;bgb
        db              2                       ;#2 of 2                        ;an000;bgb;an024;bgb
        db              Right_Align+Bin_hex_Word ;format                        ;an000;bgb;an024;bgb
        db              4                       ;min len                        ;an000;bgb;an024;bgb
        db              4                       ;max len                        ;an000;bgb;an024;bgb
        db              '0'                     ;pad char                       ;an000;bgb;an024;bgb
                                                                                ;an000;bgb
;---------------------------                    ;                               ;an046;bgb
Sublist_msg_parserr     label   dword           ;                               ;an046;bgb
                                                                                ;an046;bgb
        db              Sublist_Length          ;11                             ;an046;bgb
        db              Reserved                ;0                              ;an046;bgb
public movsi
movsi   dw              dg:command_line_buffer  ;off                            ;an046;bgb
        dw              dg                      ;seg                            ;an046;bgb
        db              0                       ;USE PERCENT ZERO               ;an046;bgb
        db              Left_Align+Char_Field_ASCIIZ ;type of data              ;an046;bgb
        db              128                     ;max width                      ;an046;bgb
        db              1                       ;min width                      ;an046;bgb
        db              Blank                   ;pad char                       ;an046;bgb
;---------------------------                    ;                               ;an046;bgb
;                                                                               ;an000;bgb
;*****************************************************************************  ;an000;bgb
; Message Description Tables                                                    ;an000;bgb
;*****************************************************************************  ;an000;bgb
;                                                                               ;an000;bgb
                                                                                ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 1                             ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = EXT_ERR_CLASS                 ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   badver                     ; AN000;SM Incorrect DOS version;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 19                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = N_A                           ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   badidbyt                   ; AN000;SM Probable non_DOS disk;an000;bgb (CRLF) Continue (Y/N)?
;----------------------                         ;                               ;an000;bgb
Message_Number  = 3                             ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = N_A                           ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   freemes                    ; AN000;SM Convert lost chains t;an000;bgbo files (Y/N)?
;----------------------                         ;                               ;an000;bgb
Message_Number  = 4                             ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = N_A                           ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   ptrandir                   ; AN000;SM Unrecoverable error i;an000;bgbn directory
;----------------------                         ;                               ;an000;bgb
Message_Number  = 5                             ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = N_A                           ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   ptrandir2                  ; AN000;SM Convert directory to ;an000;bgbfile (Y/N)?
;----------------------                         ;                               ;an000;bgb
Message_Number  = 7                             ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_dskspc         ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   dskspc                     ; AN000;SM %1 bytes total disk s;an000;bgbpace
;----------------------                         ;                               ;an000;bgb
Message_Number  = 8                             ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_badspc         ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   badspc                     ; AN000;SM %1 bytes in bad secto;an000;bgbrs
;----------------------                         ;                               ;an000;bgb
Message_Number  =  9                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_hidmes         ; AN000;SM                      ;an000;bgb
Count           = 2                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   hidmes                     ; AN000;SM %1 bytes in %2 hidden;an000;bgb files
;----------------------                         ;                               ;an000;bgb
Message_Number  = 10                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_dirmes         ; AN000;SM                      ;an000;bgb
Count           = 2                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   dirmes                     ; AN000;SM %1 bytes in %2 direct;an000;bgbories
;----------------------                         ;                               ;an000;bgb
Message_Number  = 11                            ; message number 11             ;an000;bgb
Handle          = STDOUT                        ; crt                           ;an000;bgb
Sublist         = dg:Sublist_msg_filemes        ; location of sublist           ;an000;bgb
Count           = 2                             ; caontains 2 parameters        ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; type of msg                   ;an000;bgb
Function        = NO_INPUT                      ; no input from user            ;an000;bgb
Input           = N_A                           ; not applicable              ;an000;bgb
        Define_Msg   filemes                    ; AN000;SM %1 bytes in %2 user f;an000;bgbiles
;----------------------                         ;                               ;an000;bgb
Message_Number  = 12                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_orphmes2       ; AN000;SM                      ;an000;bgb
Count           = 2                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   orphmes2                   ; AN000;SM %1 bytes in %2 recove;an000;bgbred files
;----------------------                         ;                               ;an000;bgb
Message_Number  = 13                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_orphmes3       ; AN000;SM                      ;an000;bgb
Count           = 2                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   orphmes3                   ; AN000;SM %1 bytes would be in ;an000;bgb%2 recovered files
;----------------------                         ;                               ;an000;bgb
Message_Number  = 14                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_frespc         ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   frespc                     ; AN000;SM %1 bytes available on;an000;bgb disk
;----------------------                         ;                               ;an000;bgb
Message_Number  = 15                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_totmem         ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   totmem                     ; AN000;SM %1 bytes total memory;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 16                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_fremem         ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   fremem                     ; AN000;SM %1 bytes free        ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 17                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   no_net_arg                 ; AN000;SM Cannot CHKDSK a netwo;an000;bgbrk drive
;----------------------                         ;                               ;an000;bgb
Message_Number  = 18                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   SubstErr                   ; AN000;SM Cannot CHKDSK a SUBST;an000;bgbed or ASSIGNed drive
;----------------------                         ;                               ;an000;bgb
Message_Number  = 20                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_badr_arg       ; AN000;SM                      ;an000;bgb
Count           = 2                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   badr_arg                   ; AN000;SM Disk error reading FA;an000;bgbT %2
;----------------------                         ;                               ;an000;bgb
Message_Number  = 21                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_direcmes       ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   direc_arg                  ; AN000;SM Directory %1         ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 22                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_extents        ; AN000;SM                      ;an000;bgb
Count           = 2                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   extent_arg                 ; AN000;SM %1 Contains %2 non-co;an000;bgbntiguous blocks
;----------------------                         ;                               ;an000;bgb
Message_Number  = 23                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   noext_arg                  ; AN000;SM All specified file(s);an000;bgb are contiguous
;----------------------                         ;                               ;an000;bgb
Message_Number  = 24                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   fixmes_arg                 ; AN000;SM Errors found, F param;an000;bgbeter not specified (CRLF)
;----------------------                         ;          Corrections will not ;an000;bgbbe written to disk
Message_Number  = 25                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_fatalmes       ; AN000;SM                      ;an000;bgb
Count           = 2                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   fatal_arg                  ; AN000;SM Processing cannot con;an000;bgbtinue %1%2
;----------------------                         ;                               ;an000;bgb
Message_Number  = 26                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_badrdmes       ; AN000;SM                      ;an000;bgb
Count           = 2                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   badrdmes                   ; AN000;SM File allocation table;an000;bgb bad, drive %1
;----------------------                         ;                               ;an000;bgb
Message_Number  = 2                             ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   stackmes                   ; AN000;SM Insufficient memory  ;an000;bgb
        Define_Msg   stackmes1                  ; AN000;SM Cannot make directory;an000;bgb entry %1 (CRLF)
;----------------------                         ;          Move files from root ;an000;bgbdirectory and repeat CHKDSK
Message_Number  = 29                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   cdddmes                    ; AN000;SM CHDIR .. failed, tryi;an000;bgbng alternate method
;----------------------                         ;                               ;an000;bgb
Message_Number  = 30                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   badchain                   ; AN000;SM Has invalid cluster, ;an000;bgbfile truncated
;----------------------                         ;                               ;an000;bgb
Message_Number  = 31                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   badsubdir                  ; AN000;SM Invalid sub-directory;an000;bgb entry
;----------------------                         ;                               ;an000;bgb
Message_Number  = 32                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   ndotmes                    ; AN000;SM Does not exist       ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 33                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   nulnz                      ; AN000;SM First cluster number ;an000;bgbis invalid, entry truncated
;----------------------                         ;                               ;an000;bgb
Message_Number  = 34                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   badclus                    ; AN000;SM Allocation error, siz;an000;bgbe adjusted
;----------------------                         ;                               ;an000;bgb
Message_Number  = 35                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   norecdot                   ; AN000;SM Cannot recover .. ent;an000;bgbry, processing continued
;----------------------                         ;                               ;an000;bgb
Message_Number  = 36                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   nuldmes                    ; AN000;SM Directory is totally ;an000;bgbempty, no .. or ..
;----------------------                         ;                               ;an000;bgb
Message_Number  = 37                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   joinmes                    ; AN000;SM Directory is joined  ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 38                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   norecddot                  ; AN000;SM Cannot recover .. ent;an000;bgbry
;----------------------                         ;                               ;an000;bgb
Message_Number  = 39                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   norecddot1                 ; AN000;SM Entry has a bad link ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 40                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   norecddot2                 ; AN000;SM Entry has a bad attri;an000;bgbbute
;----------------------                         ;                               ;an000;bgb
Message_Number  = 41                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   norecddot3                 ; AN000;SM Entry has a bad size ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 42                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_crossmes       ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   cross_arg                  ; AN000;SM Is cross linked on cl;an000;bgbuster %2
;----------------------                         ;                               ;an000;bgb
Message_Number  = 43                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_badtarg        ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   badtarg_ptr                ; AN000;SM Cannot CHDIR to %1, (;an000;bgbCRLF)
;----------------------                         ;          tree past this point ;an000;bgbnot processed
Message_Number  = 44                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   badtarg2                   ; AN000;SM tree past this point ;an000;bgbnot processed
;----------------------                         ;                               ;an000;bgb
Message_Number  = 45                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_freebymes      ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   freeBymes1                 ; AN000;SM %1 bytes disk space f;an000;bgbreed
;----------------------                         ;                               ;an000;bgb
Message_Number  = 46                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_freebymes      ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   freebymes2                 ; AN000;SM %1 bytes disk space w;an000;bgbould be freed
;----------------------                         ;                               ;an000;bgb
Message_Number  = 47                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_idmes          ; AN000;SM                      ;an000;bgb
Count           = 3                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   idmes_arg                  ; AN000;SM Volume %1 created %2 ;an000;bgb%3
;----------------------                         ;                               ;an000;bgb
Message_Number  = 48                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_alloc          ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   idmes1                     ; AN017;bgb %1 total allocation ;an000;bgbunits on disk
;----------------------                         ;                               ;an000;bgb
Message_Number  = 49                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:Sublist_msg_alloc          ; AN000;SM                      ;an000;bgb
Count           = 1                             ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   idmes2                     ; AN000;SM %1 bytes in each allo;an000;bgbcation unit
;----------------------                         ;                               ;an000;bgb
ifdef   fsexec                                                                  ;an038;bgb
Message_Number  = 50                            ; AN000;SM                      ;an038;bgb;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an038;bgb;an000;bgb
Sublist         = dg:Sublist_msg_ExecFailure    ; AN000;SM                      ;an038;bgb;an000;bgb
Count           = 1                             ; AN000;SM                      ;an038;bgb;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an038;bgb;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an038;bgb;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an038;bgb;an000;bgb
        Define_Msg   msgExecFailure             ; AN000;SM CHKDSK not available ;an038;bgb;an000;bgbon drive %1
        endif                                                                   ;an038;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 51                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   Inv_XA_Msg                 ; AN000;SM Extended Attributes h;an000;bgbas invalid clusters,
;----------------------                         ;          attributes truncated ;an000;bgb
Message_Number  = 52                            ; AN000;SM                      ;an000;bgb
Handle          = STDOUT                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   Alloc_XA_Msg               ; AN000;SM Extended Attributes l;an000;bgbocation .. ,
;----------------------                         ;          attributes truncated ;an000;bgb
Message_Number  = 53                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = dg:sublist_msg_parserr        ; AN000;SM                      ;an046;bgb;an000;bgb
Count           = 1                             ; AN000;SM                      ;an046;bgb;an000;bgb
Class           = PARSE_ERR_CLASS               ; AN000;SM                      ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   badsw_arg                  ; AN000;SM Invalid parameter    ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 54                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = utility_msg_class             ; AN000;bgb                     ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   baddrv_arg                 ; AN000;SM Invalid drive specifi;an000;bgbcation
;----------------------                         ;                               ;an000;bgb
Message_Number  = 55                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = utility_msg_class             ; AN017;bgb                     ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   invpath_arg                ; AN000;SM Path not found       ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 56                            ; AN000;SM                      ;an000;bgb
Handle          = STDERR                        ; AN000;SM                      ;an000;bgb
Sublist         = None                          ; AN000;SM                      ;an000;bgb
Count           = None                          ; AN000;SM                      ;an000;bgb
Class           = utility_msg_class             ; AN017;bgb                     ;an000;bgb
Function        = NO_INPUT                      ; AN000;SM                      ;an000;bgb
Input           = N_A                           ; AN000;SM                      ;an000;bgb
        Define_Msg   opnerr_arg                 ; AN000;SM File not found       ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 0                             ;                               ;an000;bgb;AN000;
Handle          = STDERR                        ;                               ;an000;bgb;AN000;
Sublist         = No_Replace                    ;                               ;AN;an000;bgb000;
Count           = N_A                           ;                               ;an000;bgb;AN000;
Class           = Ext_Err_Class                 ;                               ;an000;bgb;AN000;
Function        = No_Function                   ;                               ;an000;bgb;AN000;
Input           = N_A                           ;                               ;an000;bgb;AN000;
        Define_Msg      Extended_Error_Msg      ;                               ;an000;bgb;AN000;
;-----------------------                                                        ;an000;bgb
Message_Number  = 0                             ;                               ;an000;bgb
Handle          = STDERR                        ;                               ;an000;bgb;AN000;
Sublist         = dg:sublist_msg_parserr        ;                               ;an046;bgbbgb000;
Count           = 1                             ;                               ;an046;bgb;AN000;
Class           = Parse_Err_Class               ;                               ;an000;bgb;AN000;
Function        = No_Function                   ;                               ;an000;bgb;AN000;
Input           = N_A                           ;                               ;an000;bgb;AN000;
        Define_Msg      Parse_Error_Msg         ;                               ;an000;bgb;AN000;
;-----------------------                                                        ;an000;bgb
Message_Number  = 58                            ; AN000;dms                     ;an000;bgb
Handle          = STDERR                        ; AN000;dms                     ;an000;bgb
Sublist         = dg:Sublist_msg_orphmes           ; AN000;dms                  ;an000;bgb
Count           = 2                             ; AN000;dms                     ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;dms                     ;an000;bgb
Function        = NO_INPUT                      ; AN000;dms                     ;an000;bgb
Input           = N_A                           ; AN000;dms                     ;an000;bgb
        Define_Msg   orph_arg                   ; AN000;dms "%1 lost clusters fo;an000;bgbund in %2 chains.",0
;----------------------                         ;                               ;an000;bgb
Message_Number  = 59                            ; AN000;dms                     ;an000;bgb
Handle          = STDout                        ; AN000;bgb                     ;an000;bgb
Sublist         = none                          ; AN000;dms                     ;an000;bgb
Count           = none                          ; AN000;dms                     ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;dms                     ;an000;bgb
Function        = NO_INPUT                      ; AN000;dms                     ;an000;bgb
Input           = N_A                           ; AN000;dms                     ;an000;bgb
        Define_Msg   crlf_arg                   ; AN000;dms CR,LF               ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 60                            ; AN000;dms                     ;an000;bgb
Handle          = STDERR                        ; AN000;dms                     ;an000;bgb
Sublist         = none                          ; AN000;dms                     ;an000;bgb
Count           = none                          ; AN000;dms                     ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;dms                     ;an000;bgb
Function        = NO_INPUT                      ; AN000;dms                     ;an000;bgb
Input           = N_A                           ; AN000;dms                     ;an000;bgb
        Define_Msg   badcd_arg                  ; AN000;dms "Cannot CHDIR to roo;an000;bgbt",cr,lf
;----------------------                         ;                               ;an000;bgb
Message_Number  = 61                            ; AN000;dms                     ;an000;bgb
Handle          = STDERR                        ; AN000;dms                     ;an000;bgb
Sublist         = dg:Sublist_Msg_Badw_arg          ; AN000;dms                  ;an000;bgb
Count           = 1                             ; AN000;dms                     ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;dms                     ;an000;bgb
Function        = NO_INPUT                      ; AN000;dms                     ;an000;bgb
Input           = N_A                           ; AN000;dms                     ;an000;bgb
        Define_Msg   badw_arg                   ; AN000;dms "Disk error writing ;an000;bgbFAT %1"
;----------------------                         ;                               ;an000;bgb
Message_Number  = 62                            ; AN000;dms                     ;an000;bgb
Handle          = STDOUT                        ; AN000;dms                     ;an042;bgb;an000;bgb
Sublist         = dg:Sublist_Msg_Noisy             ; AN000;dms                  ;an000;bgb
Count           = 1                             ; AN000;dms                     ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;dms                     ;an000;bgb
Function        = NO_INPUT                      ; AN000;dms                     ;an000;bgb
Input           = N_A                           ; AN000;dms                     ;an000;bgb
        Define_Msg   noisy_arg                  ; AN000;dms "       %1"         ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 63                            ; AN000;dms                     ;an000;bgb
Handle          = STDERR                        ; AN000;dms                     ;an000;bgb
Sublist         = none                          ; AN000;dms                     ;an000;bgb
Count           = none                          ; AN000;dms                     ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;dms                     ;an000;bgb
Function        = NO_INPUT                      ; AN000;dms                     ;an000;bgb
Input           = N_A                           ; AN000;dms                     ;an000;bgb
        Define_Msg   baddpbdir                  ; AN000;dms "Invalid current dir;an000;bgbectory"
;----------------------                         ;                               ;an000;bgb
Message_Number  = 64                            ; AN000;dms                     ;an000;bgb
Handle          = STDERR                        ; AN000;dms                     ;an000;bgb
Sublist         = dg:Sublist_Msg_File_Arg          ; AN000;dms                  ;an000;bgb
Count           = 1                             ; AN000;dms                     ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;dms                     ;an000;bgb
Function        = NO_INPUT                      ; AN000;dms                     ;an000;bgb
Input           = N_A                           ; AN000;dms                     ;an000;bgb
        Define_Msg   file_arg                   ; AN000;dms "%1",cr,lf          ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 65                            ; AN000;dms                     ;an000;bgb
Handle          = STDERR                        ; AN000;dms                     ;an000;bgb
Sublist         = none                          ; AN000;dms                     ;an000;bgb
Count           = none                          ; AN000;dms                     ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN000;dms                     ;an000;bgb
Function        = NO_INPUT                      ; AN000;dms                     ;an000;bgb
Input           = N_A                           ; AN000;dms                     ;an000;bgb
        Define_Msg   creatmes                   ; AN000;dms "Insufficient room i;an000;bgbn root directory"
;----------------------                         ;                               ;an000;bgb
Message_Number  = 70                            ; AN017;bgb                     ;an000;bgb
Handle          = STDOUT                        ; AN017;bgb                     ;an000;bgb
Sublist         = dg:Sublist_msg_alloc          ; AN017;bgb                     ;an000;bgb
Count           = 1                             ; AN017;bgb                     ;an000;bgb
Class           = UTILITY_MSG_CLASS             ; AN017;bgb                     ;an000;bgb
Function        = NO_INPUT                      ; AN017;bgb                     ;an000;bgb
Input           = N_A                           ; AN017;bgb                     ;an000;bgb
        Define_Msg   idmes3                     ; AN017;bgb %1 allocation units ;an000;bgbavailable on disk
;----------------------                         ;                               ;an000;bgb
Message_Number  = 71                            ;                               ;an000;bgb;an024;bgb
Handle          = STDOUT                        ;                               ;an000;bgb;an024;bgb
Sublist         = Sublist_msgSerialNumber       ;                               ;an000;bgb;an024;bgb
Count           = 2                             ;                               ;an000;bgb;an024;bgb
Class           = Utility_Msg_Class             ;                               ;an000;bgb;an024;bgb
Function        = No_Function                   ;                               ;an000;bgb;an024;bgb
Input           = N_A                           ;                               ;an000;bgb;an024;bgb
        Define_Msg      msgSerialNumber         ;                               ;an000;bgb;an024;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 72                            ; AN030;bgb                     ;an000;bgb
Handle          = STDERR                        ; AN030;bgb                     ;an000;bgb
Sublist         = None                          ; AN030;bgb                     ;an000;bgb
Count           = None                          ; AN030;bgb                     ;an000;bgb
Class           = utility_msg_class             ; AN030;bgb                     ;an000;bgb
Function        = NO_INPUT                      ; AN030;bgb                     ;an000;bgb
Input           = N_A                           ; AN030;bgb                     ;an000;bgb
        Define_Msg   no_mem_arg                 ; AN030;bgb insufficient memory ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 73                            ; AN033;bgb                     ;an000;bgb
Handle          = STDERR                        ; AN033;bgb                     ;an000;bgb
Sublist         = None                          ; AN033;bgb                     ;an000;bgb
Count           = None                          ; AN033;bgb                     ;an000;bgb
Class           = utility_msg_class             ; AN033;bgb                     ;an000;bgb
Function        = NO_INPUT                      ; AN033;bgb                     ;an000;bgb
Input           = N_A                           ; AN033;bgb                     ;an000;bgb
        Define_Msg   inval_media                ; AN033;bgb invalid media type  ;an000;bgb
;----------------------                         ;                               ;an000;bgb
Message_Number  = 74                            ; AN045;bgb                     ;an000;bgb
Handle          = STDERR                        ; AN045;bgb                     ;an000;bgb
Sublist         = None                          ; AN045;bgb                     ;an000;bgb
Count           = None                          ; AN045;bgb                     ;an000;bgb
Class           = utility_msg_class             ; AN045;bgb                     ;an000;bgb
Function        = NO_INPUT                      ; AN045;bgb                     ;an000;bgb
Input           = N_A                           ; AN045;bgb                     ;an000;bgb
        Define_Msg   write_fault                ; AN045;bgb write fault error   ;an000;bgb
                                                                                ;an000;bgb
                                                                                ;an000;bgb
;                                                                               ;an000;bgb
;*****************************************************************************  ;an000;bgb
; Message Data Area                                                             ;an000;bgb
;*****************************************************************************  ;an000;bgb
;                                                                               ;an000;bgb
                                                                                ;an000;bgb
                                                                                ;an000;bgb
; THE FOLLOWING ONE BYTE CHARACTERS ARE THE PROMPT ANSWERS.                     ;an000;bgb
; THEY MUST BE LOWER CASE, AND THE UPPER TO LOWER, OR LOWER                     ;an000;bgb
; TO LOWER CONVERSION MUST BE DOABLE BY "OR  AL,20h".                           ;an000;bgb
; Yes/No Answers                                                                ;an000;bgb
YES_BYTE        DB      "y"                                                     ;an000;bgb
NO_BYTE         DB      "n"                                                     ;an000;bgb
                                                                                ;an000;bgb
;The following table is the list of abbreviated month names used to print       ;an000;bgb
;  out the volume ID.                                                           ;an000;bgb
; MUST BE THREE BYTES PER MONTH                                                 ;an000;bgb
MONTAB          DB      "JanFebMarAprMayJunJulAugSepOctNovDec"                  ;an000;bgb
                                                                                ;an000;bgb
                                                                                ;an000;bgb
yn_arg      dw      ?                                                           ;an000;bgb
                                                                                ;an000;bgb
;orph_num    dw      ?  ;from orphsiz; = number of lost clusters                 ;an000;bgb;an049;bgb
orphcnt     dd      ?  ;number of chains of lost clusters                       ;an000;bgb
                                                                                ;an000;bgb
report_arg  dw      ?                                                           ;an000;bgb
rarg1       dd      ? ;changed to dword                                         ;an000;bgb;an049;bgb
rarg3       dd      ? ;changed to dword                                         ;an000;bgb;an049;bgb
                                                                                ;an000;bgb
baddrvm     DB      " A.",0                                                     ;an000;bgb
badrw_str   dw      ?                                                           ;an000;bgb
badrw_num   dw      ?                                                           ;an000;bgb
block_num   dw      ?                                                           ;an000;bgb
fatal_arg1  dw      ?                                                           ;an000;bgb
fatal_arg2  dw      ?                                                           ;an000;bgb
file_arg1   dw      ?                                                           ;an000;bgb
file_arg2   dw      ?                                                           ;an000;bgb
free_arg1   dw      ?                                                           ;an000;bgb
free_arg2   dw      ?                                                           ;an000;bgb
free_arg3   dw      ?                                                           ;an000;bgb
fatal_end   db     ".",0                                                        ;an000;bgb
                                                                                ;an000;bgb
                                                                                ;an000;bgb
data ends                                       ; AN000;                        ;an000;bgb
