


data    segment public 'DATA'



;
;***************************************************************************
; Equates
;***************************************************************************
;

;Match Flags

Numeric_Value           equ     8000h           ;                               ;AN000;
Signed_Numeric_Value    equ     4000h           ;                               ;AN000;
Simple_String           equ     2000h           ;                               ;AN000;
Date_String             equ     1000h           ;                               ;AN000;
Time_String             equ     0800h           ;                               ;AN000;
Complex_List            equ     0400h           ;                               ;AN000;
Filespec                equ     0200h           ;                               ;AN000;
Drive_Only              equ     0100h           ;                               ;AN000;
Quoted_String           equ     0080h           ;                               ;AN000;
Ignore_Colon            equ     0010h           ;                               ;AN000;
Repeats_Allowed         equ     0002h           ;                               ;AN000;
Optional                equ     0001h           ;                               ;AN000;

;Function_Flags

File_Table_Capitalize   equ     1               ;                               ;AN000;

;Result buffer type returned
rb_Number               equ     1
rb_List_Index           equ     2
rb_String               equ     3
rb_Complex              equ     4
rb_Filespec             equ     5
rb_Drive                equ     6
rb_Date                 equ     7
rb_Time                 equ     8
rb_Quoted_String        equ     9


;Extra delimeters and EOL

Delimiters_Only         equ     1               ;                               ;AN000;
EOL_Or_Delimiters       equ     2               ;                               ;AN000;

Semi_Colon              equ     ";"             ;                               ;AN000;
Tab                     equ     09h             ;                               ;AN000;
Colon1                  equ     ":"             ;                               ;AN000;
NUL                     equ     "0"

;Parse Errors

No_Error                equ     0               ;                               ;AN000;
Too_Many_Operands       equ     1               ;                               ;AN000;
Operand_Missing         equ     2               ;                               ;AN000;
Not_In_Switch_List      equ     3               ;                               ;AN000;
Not_In_Keyword_List     equ     4               ;                               ;AN000;
Out_Of_Range            equ     6               ;                               ;AN000;
Not_In_Value_List       equ     7               ;                               ;AN000;
Not_In_String_List      equ     8               ;                               ;AN000;
Syntax_Error            equ     9               ;                               ;AN000;
End_Of_Parse            equ     -1              ;                               ;AN000;

;Other

None                    equ     0               ;                               ;AN000;
No_Error                equ     0               ;                               ;AN000;
Switch_Found            equ     0FFFFh          ;                               ;AN000;
Range_Ok                equ     1               ;                               ;AN000;
Command_Line_Parms      equ     81h             ;                               ;AN000;

;
;*****************************************************************************
; Parse Structures
;*****************************************************************************
;

Control          struc

Match_Flags     dw      ?
Function_Flags  dw      ?
Result          dw      ?
Values          dw      ?
Num_Keywords    db      ?
Keyword         db      ?

Control         ends

File_Name_Return        struc                   ;                               ;AN000;

Drive_Type      db      0                       ;                               ;AN000;
Drive_Item_Tag  db      0                       ;                               ;AN000;
Synonym         dw      0                       ;                               ;AN000;
String_Value_ptr db     0                       ;File Name                      ;AN000;

File_Name_Return     ends                       ;                               ;AN000;


;
;**************************************************************************
; Parse tables
;**************************************************************************
;

Command_Line_Table label byte                      ;                               ;AN000;

        dw      Command_Control                 ;Point to next level            ;AN000;
        db      Delimiters_Only                 ;                               ;AN000;
        db      1                               ;                               ;AN000;
        db      Semi_Colon                      ;                               ;AN000;


;
;**************************************************************************
; Define Positionals, Switches and Keywords
;**************************************************************************
;

Command_Control label byte                      ;                               ;AN000;

        db      1,2                             ;File names Positional (1 required) ;AN000;
        dw      Positional_Control1             ;Pointer to control table       ;AN000;
        dw      Positional_Control2             ;Pointer to control table       ;AN000;
        db      None                            ;no switches                    ;AN000;
        db      None                            ;No Keywords (maxk)             ;AN000;

;
;**************************************************************************
;Control Tables
;**************************************************************************
;

Positional_Control1 label byte                  ;                               ;AN000;

        dw      Filespec                        ;Match_Flag                     ;AN000;
        dw      File_Table_Capitalize           ;No function flags              ;AN000;
        dw      File_Name_Buffer1               ;Where it will be returned      ;AN000;
        dw      No_Value                        ;No value ranges defined        ;AN000;
        db      None                            ;No defined switches/keywords   ;AN000;

Positional_Control2 label byte                  ;                               ;AN000;

        dw      Filespec+Optional               ;Match_Flag                     ;AN000;

        dw      File_Table_Capitalize           ;No function flags              ;AN000;
        dw      File_Name_Buffer2               ;Where it will be returned      ;AN000;
        dw      No_Value                        ;No value ranges defined        ;AN000;
        db      None                            ;No defined switches/keywords   ;AN000;

No_Value        label   byte                    ;                               ;AN000;
        db      0                               ;                               ;AN000;

;
;************************************************************************
; PARSE Return Buffers
;************************************************************************
;
File_name_Buffer1   label  byte                 ;                               ;AN000;

rb_type1       db      0                        ;type returned                  ;AN000;
rb_item_tag1   db      0                        ;matched item tag               ;AN000;
rb_synonym1    dw      0                        ;found synonyms                 ;AN000;
rb_string1_off dw      0                        ;Offset of string               ;AN000;
rb_string1_seg dw      0                        ;Offset of string               ;AN000;

File_name_Buffer2   label  byte                 ;                               ;AN000;

rb_type2       db      0                        ;type returned                  ;AN000;
rb_item_tag2   db      0                        ;matched item tag               ;AN000;
rb_synonym2    dw      0                        ;found synonyms                 ;AN000;
rb_string2_off dw      0                        ;Offset of string               ;AN000;
rb_string2_seg dw      0                        ;Offset of string               ;AN000;

data    ends

