;       SCCSID = @(#)strin.asm  1.2 85/04/18
Break

; Inputs:
;       DS:DX Point to an input buffer
; Function:
;       Fill buffer from console input until CR
; Returns:
;       None

        procedure   $STD_CON_STRING_INPUT,NEAR   ;System call 10
ASSUME  DS:NOTHING,ES:NOTHING

        MOV     AX,SS
        MOV     ES,AX
        MOV     SI,DX
        XOR     CH,CH
        LODSW
;
; AL is the buffer length
; AH is the template length
;
        OR      AL,AL
        retz                    ;Buffer is 0 length!!?
        MOV     BL,AH           ;Init template counter
        MOV     BH,CH           ;Init template counter
 ;
 ; BL is the number of bytes in the template
 ;
        CMP     AL,BL
        JBE     NOEDIT          ;If length of buffer inconsistent with contents
        CMP     BYTE PTR [BX+SI],c_CR
        JZ      EDITON          ;If CR correctly placed EDIT is OK
;
; The number of chars in the template is >= the number of chars in buffer or
; there is no CR at the end of the template.  This is an inconsistant state
; of affairs.  Pretend that the template was empty:
;
NOEDIT:
        MOV     BL,CH           ;Reset buffer
EDITON:
        MOV     DL,AL
        DEC     DX              ;DL is # of bytes we can put in the buffer
;
; Top level.  We begin to read a line in.
;
NEWLIN:
        MOV     AL,[CARPOS]
        MOV     [STARTPOS],AL   ;Remember position in raw buffer
        PUSH    SI
        MOV     DI,OFFSET DOSGROUP:INBUF        ;Build the new line here
        MOV     [INSMODE],CH    ;Insert mode off
        MOV     BH,CH           ;No chars from template yet
        MOV     DH,CH           ;No chars to new line yet
        invoke  $STD_CON_INPUT_NO_ECHO          ;Get first char
        CMP     AL,c_LF         ;Linefeed
        JNZ     GOTCH           ;Filter out LF so < works
;
; This is the main loop of reading in a character and processing it.
;
;   BH is the index of the next byte in the template
;   BL is the length of the template
;   DH is the number of bytes in the buffer
;   DL is the length of the buffer
;
entry   GETCH
        invoke  $STD_CON_INPUT_NO_ECHO
GOTCH:
;
; Brain-damaged TP ignored ^F in case his BIOS did not flush the
; input queue.
;
        CMP     AL,"F"-"@"
        JZ      GETCH
;
; If the leading char is the function-key lead byte
;
        CMP     AL,[ESCCHAR]
        JZ      ESCape          ;change reserved keyword DBM 5-7-87
;
; Rubout and ^H are both destructive backspaces.
;
        CMP     AL,c_DEL
        JZ      BACKSPJ
        CMP     AL,c_BS
        JZ      BACKSPJ
;
; ^W deletes backward once and then backs up until a letter is before the
; cursor
;
        CMP     AL,"W" - "@"
; The removal of the comment characters before the jump statement will
; cause ^W to backup a word.
;***    JZ      WordDel
        NOP
        NOP
        CMP     AL,"U" - "@"
; The removal of the comment characters before the jump statement will
; cause ^U to clear a line.
;***    JZ      LineDel
        NOP
        NOP

;
; CR terminates the line.
;
        CMP     AL,c_CR
        JZ      ENDLIN
;
; LF goes to a new line and keeps on reading.
;
        CMP     AL,c_LF
        JZ      PHYCRLF
;
; ^X (or ESC) deletes the line and starts over
;
        CMP     AL,[CANCHAR]
        JZ      KILNEW
;
; Otherwise, we save the input character.
;
SAVCH:
        CMP     DH,DL
        JAE     BUFFUL                  ; buffer is full.
        STOSB
        INC     DH                      ; increment count in buffer.
        invoke  BUFOUT                  ;Print control chars nicely
        CMP     BYTE PTR [INSMODE],0
        JNZ     GETCH                   ; insertmode => don't advance template
        CMP     BH,BL
        JAE     GETCH                   ; no more characters in template
        INC     SI                      ; Skip to next char in template
        INC     BH                      ; remember position in template
        JMP     SHORT GETCH

BACKSPJ: JMP    SHORT BACKSP

BUFFUL:
        MOV     AL,7                    ; Bell to signal full buffer
        invoke  OUTT
        JMP     SHORT GETCH

ESCape:                         ;change reserved keyword DBM 5-7-87
        transfer    OEMFunctionKey      ; let the OEM's handle the key dispatch

ENDLIN:
        STOSB                           ; Put the CR in the buffer
        invoke  OUTT                    ; Echo it
        POP     DI                      ; Get start of user buffer
        MOV     [DI-1],DH               ; Tell user how many bytes
        INC     DH                      ; DH is length including CR
COPYNEW:
        SaveReg <DS,ES>
        RestoreReg <DS,ES>              ; XCHG ES,DS
        MOV     SI,OFFSET DOSGROUP:INBUF
        MOV     CL,DH                   ; set up count
        REP     MOVSB                   ; Copy final line to user buffer
        return
;
; Output a CRLF to the user screen and do NOT store it into the buffer
;
PHYCRLF:
        invoke  CRLF
        JMP     GETCH

;
; Delete the previous line
;
LineDel:
        OR      DH,DH
        JZ      GetCh
        Call    BackSpace
        JMP     LineDel

;
; delete the previous word.
;
WordDel:
WordLoop:
        Call    BackSpace               ; backspace the one spot
        OR      DH,DH
        JZ      GetChJ
        MOV     AL,ES:[DI-1]
        cmp     al,'0'
        jb      GetChj
        cmp     al,'9'
        jbe     WordLoop
        OR      AL,20h
        CMP     AL,'a'
        JB      GetChJ
        CMP     AL,'z'
        JBE     WordLoop
GetChJ:
        JMP     GetCh
;
; The user wants to throw away what he's typed in and wants to start over.  We
; print the backslash and then go to the next line and tab to the correct spot
; to begin the buffered input.
;
        entry   KILNEW
        MOV     AL,"\"
        invoke  OUTT            ;Print the CANCEL indicator
        POP     SI              ;Remember start of edit buffer
PUTNEW:
        invoke  CRLF            ;Go to next line on screen
        MOV     AL,[STARTPOS]
        invoke  TAB             ;Tab over
        JMP     NEWLIN          ;Start over again


;
; Destructively back up one character position
;
entry   BackSp
        Call    BackSpace
        JMP     GetCh

BackSpace:
        OR      DH,DH
        JZ      OLDBAK          ;No chars in line, do nothing to line
        CALL    BACKUP          ;Do the backup
        MOV     AL,ES:[DI]      ;Get the deleted char
        CMP     AL," "
        JAE     OLDBAK          ;Was a normal char
        CMP     AL,c_HT
        JZ      BAKTAB          ;Was a tab, fix up users display
;; 9/27/86 fix for ctrl-U backspace
        CMP     AL,"U"-"@"      ; ctrl-U is a section symbol not ^U
        JZ      OLDBAK
        CMP     AL,"T"-"@"      ; ctrl-T is a paragraphs symbol not ^T
        JZ      OLDBAK
;; 9/27/86 fix for ctrl-U backspace
        CALL    BACKMES         ;Was a control char, zap the '^'
OLDBAK:
        CMP     BYTE PTR [INSMODE],0
        retnz                   ;In insert mode, done
        OR      BH,BH
        retz                    ;Not advanced in template, stay where we are
        DEC     BH              ;Go back in template
        DEC     SI
        return

BAKTAB:
        PUSH    DI
        DEC     DI              ;Back up one char
        STD                     ;Go backward
        MOV     CL,DH           ;Number of chars currently in line
        MOV     AL," "
        PUSH    BX
        MOV     BL,7            ;Max
        JCXZ    FIGTAB          ;At start, do nothing
FNDPOS:
        SCASB                   ;Look back
        JNA     CHKCNT
        CMP     BYTE PTR ES:[DI+1],9
        JZ      HAVTAB          ;Found a tab
        DEC     BL              ;Back one char if non tab control char
CHKCNT:
        LOOP    FNDPOS
FIGTAB:
        SUB     BL,[STARTPOS]
HAVTAB:
        SUB     BL,DH
        ADD     CL,BL
        AND     CL,7            ;CX has correct number to erase
        CLD                     ;Back to normal
        POP     BX
        POP     DI
        JZ      OLDBAK          ;Nothing to erase
TABBAK:
        invoke  BACKMES
        LOOP    TABBAK          ;Erase correct number of chars
        JMP     SHORT OLDBAK

BACKUP:
        DEC     DH              ;Back up in line
        DEC     DI
BACKMES:
        MOV     AL,c_BS         ;Backspace
        invoke  OUTT
        MOV     AL," "          ;Erase
        invoke  OUTT
        MOV     AL,c_BS         ;Backspace
        JMP     OUTT            ;Done

;User really wants an ESC character in his line
        entry   TwoEsc
        MOV     AL,[ESCCHAR]
        JMP     SAVCH

;Copy the rest of the template
        entry   COPYLIN
        MOV     CL,BL           ;Total size of template
        SUB     CL,BH           ;Minus position in template, is number to move
        JMP     SHORT COPYEACH

        entry   CopyStr
        invoke  FINDOLD         ;Find the char
        JMP     SHORT COPYEACH  ;Copy up to it

;Copy one char from template to line
        entry   COPYONE
        MOV     CL,1
;Copy CX chars from template to line
COPYEACH:
        MOV     BYTE PTR [INSMODE],0    ;All copies turn off insert mode
        CMP     DH,DL
        JZ      GETCH2                  ;At end of line, can't do anything
        CMP     BH,BL
        JZ      GETCH2                  ;At end of template, can't do anything
        LODSB
        STOSB
        invoke  BUFOUT
        INC     BH                      ;Ahead in template
        INC     DH                      ;Ahead in line
        LOOP    COPYEACH
GETCH2:
        JMP     GETCH

;Skip one char in template
        entry   SKIPONE
        CMP     BH,BL
        JZ      GETCH2                  ;At end of template
        INC     BH                      ;Ahead in template
        INC     SI
        JMP     GETCH

        entry   SKIPSTR
        invoke  FINDOLD                 ;Find out how far to go
        ADD     SI,CX                   ;Go there
        ADD     BH,CL
        JMP     GETCH

;Get the next user char, and look ahead in template for a match
;CX indicates how many chars to skip to get there on output
;NOTE: WARNING: If the operation cannot be done, the return
;       address is popped off and a jump to GETCH is taken.
;       Make sure nothing extra on stack when this routine
;       is called!!! (no PUSHes before calling it).
FINDOLD:
        invoke  $STD_CON_INPUT_NO_ECHO
        CMP     AL,[ESCCHAR]            ; did he type a function key?
        JNZ     FindSetup               ; no, set up for scan
        invoke  $STD_CON_INPUT_NO_ECHO  ; eat next char
        JMP     NotFnd                  ; go try again
FindSetup:
        MOV     CL,BL
        SUB     CL,BH           ;CX is number of chars to end of template
        JZ      NOTFND          ;At end of template
        DEC     CX              ;Cannot point past end, limit search
        JZ      NOTFND          ;If only one char in template, forget it
        PUSH    ES
        PUSH    DS
        POP     ES
        PUSH    DI
        MOV     DI,SI           ;Template to ES:DI
        INC     DI
        REPNE   SCASB           ;Look
        POP     DI
        POP     ES
        JNZ     NOTFND          ;Didn't find the char
        NOT     CL              ;Turn how far to go into how far we went
        ADD     CL,BL           ;Add size of template
        SUB     CL,BH           ;Subtract current pos, result distance to skip
        return

NOTFND:
        POP     BP              ;Chuck return address
        JMP     GETCH

entry   REEDIT
        MOV     AL,"@"          ;Output re-edit character
        invoke  OUTT
        POP     DI
        PUSH    DI
        PUSH    ES
        PUSH    DS
        invoke  COPYNEW         ;Copy current line into template
        POP     DS
        POP     ES
        POP     SI
        MOV     BL,DH           ;Size of line is new size template
        JMP     PUTNEW          ;Start over again

        entry   EXITINS
        entry   ENTERINS
        NOT     BYTE PTR [INSMODE]
        JMP     GETCH

;Put a real live ^Z in the buffer (embedded)
        entry   CTRLZ
        MOV     AL,"Z"-"@"
        JMP     SAVCH

;Output a CRLF
        entry   CRLF
        MOV     AL,c_CR
        invoke  OUTT
        MOV     AL,c_LF
        JMP     OUTT

EndProc $STD_CON_STRING_INPUT
