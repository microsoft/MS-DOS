

FALSE   EQU     0
TRUE    EQU     NOT FALSE

KANJI   EQU     FALSE

roprot  equ     FALSE           ;set to TRUE if protection to r/o files
                                ; desired.
FCB     EQU     5CH

Comand_Line_Length equ 128
quote_char equ  16h             ;quote character = ^V


PAGE

        .xlist
        INCLUDE DOSSYM.ASM
        .list


SUBTTL  Contants and Data areas
PAGE

PROMPT  EQU     "*"
STKSIZ  EQU     80H

CODE    SEGMENT PUBLIC
CODE    ENDS

CONST   SEGMENT PUBLIC WORD

        EXTRN   TXT1:BYTE,TXT2:BYTE,FUDGE:BYTE,HARDCH:DWORD,USERDIR:BYTE

CONST   ENDS

DATA    SEGMENT PUBLIC WORD

        EXTRN   OLDLEN:WORD,OLDDAT:BYTE,SRCHFLG:BYTE,COMLINE:WORD
        EXTRN   PARAM1:WORD,PARAM2:WORD,NEWLEN:WORD,SRCHMOD:BYTE
        EXTRN   CURRENT:WORD,POINTER:WORD,START:BYTE,ENDTXT:WORD
        EXTRN   USER_DRIVE:BYTE,LSTNUM:WORD,NUMPOS:WORD,LSTFND:WORD
        EXTRN   SRCHCNT:WORD

DATA    ENDS

DG      GROUP   CODE,CONST,DATA

CODE SEGMENT PUBLIC

ASSUME  CS:DG,DS:DG,SS:DG,ES:DG

        PUBLIC  REST_DIR,KILL_BL,INT_24,SCANLN,FINDLIN,SHOWNUM
        PUBLIC  FNDFIRST,FNDNEXT,CRLF,LF,OUT,UNQUOTE

        if  kanji
        PUBLIC  TESTKANJ
        endif

        EXTRN   CHKRANGE:NEAR

EDLPROC:

RET1:   RET

FNDFIRST:
        MOV     DI,1+OFFSET DG:TXT1
        mov     byte ptr[olddat],1     ;replace with old value if none new
        CALL    GETTEXT
        OR      AL,AL           ;Reset zero flag in case CX is zero
        JCXZ    RET1
        cmp     al,1ah          ;terminated with a ^Z ?
        jne     sj8
        mov     byte ptr[olddat],0     ;do not replace with old value
sj8:
        MOV     [OLDLEN],CX
        XOR     CX,CX
        CMP     AL,0DH
        JZ      SETBUF
        CMP     BYTE PTR [SRCHFLG],0
        JZ      NXTBUF
SETBUF:
        DEC     SI
NXTBUF:
        MOV     [COMLINE],SI
        MOV     DI,1+OFFSET DG:TXT2
        CALL    GETTEXT
        CMP     BYTE PTR [SRCHFLG],0
        JNZ     NOTREPL
        CMP     AL,0DH
        JNZ     HAVCHR
        DEC     SI
HAVCHR:
        MOV     [COMLINE],SI
NOTREPL:
        MOV     [NEWLEN],CX
        MOV     BX,[PARAM1]
        OR      BX,BX
        JNZ     CALLER
        cmp     byte ptr[srchmod],0
        jne     sj9
        mov     bx,1     ;start from line number 1
        jmp     short sj9a
sj9:
        MOV     BX,[CURRENT]
        INC     BX      ;Default search and replace to current+1
sj9a:
        CALL    CHKRANGE
CALLER:
        CALL    FINDLIN
        MOV     [LSTFND],DI
        MOV     [NUMPOS],DI
        MOV     [LSTNUM],DX
        MOV     BX,[PARAM2]
        CMP     BX,1
        SBB     BX,-1   ;Decrement everything except zero
        CALL    FINDLIN
        MOV     CX,DI
        SUB     CX,[LSTFND]
        OR      AL,-1
        JCXZ    aret
        CMP     CX,[OLDLEN]
        jae     sj10
aret:   ret
sj10:
        MOV     [SRCHCNT],CX

FNDNEXT:

; Inputs:
;       [TXT1+1] has string to search for
;       [OLDLEN] has length of the string
;       [LSTFND] has starting position of search in text buffer
;       [LSTNUM] has line number which has [LSTFND]
;       [SRCHCNT] has length to be searched
;       [NUMPOS] has beginning of line which has [LSTFND]
; Outputs:
;       Zero flag set if match found
;       [LSTFND],[LSTNUM],[SRCHCNT] updated for continuing the search
;       [NUMPOS] has beginning of line in which match was made

        MOV     AL,[TXT1+1]
        MOV     CX,[SRCHCNT]
        MOV     DI,[LSTFND]
SCAN:
        OR      DI,DI           ;Clear zero flag in case CX=0
        REPNE   SCASB
        JNZ     RET11
        MOV     DX,CX
        MOV     BX,DI           ;Save search position
        MOV     CX,[OLDLEN]
        DEC     CX
        MOV     SI,2 + OFFSET DG:TXT1
        CMP     AL,AL           ;Set zero flag in case CX=0
if kanji
        dec     si              ;Want to look at the first character again
        dec     di
kanjchar:
        lodsb
        call    testkanj
        jz      nxt_kj_char
        xchg    ah,al
        lodsb
        mov     bx,[di]
        add     di,2
        cmp     ax,bx
        jnz     not_kj_match
        dec     cx
        loop    kanjchar
nxt_kj_char:
        cmp     al,byte ptr[di]
        jnz     not_kj_match
        inc     di
        loop    kanjchar

not_kj_match:
else
        REPE    CMPSB
endif
        MOV     CX,DX
        MOV     DI,BX
        JNZ     SCAN
        MOV     [SRCHCNT],CX
        MOV     CX,DI
        MOV     [LSTFND],DI
        MOV     DI,[NUMPOS]
        SUB     CX,DI
        MOV     AL,10
        MOV     DX,[LSTNUM]
;Determine line number of match
GETLIN:
        INC     DX
        MOV     BX,DI
        REPNE   SCASB
        JZ      GETLIN
        DEC     DX
        MOV     [LSTNUM],DX
        MOV     [NUMPOS],BX
        XOR     AL,AL
RET11:  RET


GETTEXT:

; Inputs:
;       SI points into command line buffer
;       DI points to result buffer
; Function:
;       Moves [SI] to [DI] until ctrl-Z (1AH) or
;       RETURN (0DH) is found. Termination char not moved.
; Outputs:
;       AL = Termination character
;       CX = No of characters moved.
;       SI points one past termination character
;       DI points to next free location

        XOR     CX,CX

GETIT:
        LODSB
;-----------------------------------------------------------------------
        cmp     al,quote_char   ;a quote character?
        jne     sj101           ;no, skip....
        lodsb                   ;yes, get quoted character
        call    make_cntrl
        jmp     short sj102
;-----------------------------------------------------------------------
sj101:
        CMP     AL,1AH
        JZ      DEFCHK
sj102:
        CMP     AL,0DH
        JZ      DEFCHK
        STOSB
        INC     CX
        JMP     SHORT GETIT

DEFCHK:
        OR      CX,CX
        JZ      OLDTXT
        PUSH    DI
        SUB     DI,CX
        MOV     BYTE PTR [DI-1],cl
        POP     DI
        RET

OLDTXT:
        cmp     byte ptr[olddat],1      ;replace with old text?
        je      sj11                    ;yes...
        mov     byte ptr[di-1],cl       ;zero text buffer char count
        ret

sj11:
        MOV     CL,BYTE PTR [DI-1]
        ADD     DI,CX
        RET


FINDLIN:

; Inputs
;       BX = Line number to be located in buffer (0 means last line)
; Outputs:
;       DX = Actual line found
;       DI = Pointer to start of line DX
;       Zero set if BX = DX
; AL,CX destroyed. No other registers affected.

        MOV     DX,[CURRENT]
        MOV     DI,[POINTER]
        CMP     BX,DX
        JZ      RET4
        JA      FINDIT
        OR      BX,BX
        JZ      FINDIT
        MOV     DX,1
        MOV     DI,OFFSET DG:START
        CMP     BX,DX
        JZ      RET4
FINDIT:
        MOV     CX,[ENDTXT]
        SUB     CX,DI
SCANLN:
        MOV     AL,10
        OR      AL,AL           ;Clear zero flag
FINLIN:
        JCXZ    RET4
        REPNE   SCASB
        INC     DX
        CMP     BX,DX
        JNZ     FINLIN
RET4:   RET


SHOWNUM:

; Inputs:
;       BX = Line number to be displayed
; Function:
;       Displays line number on terminal in 8-character
;       format, suppressing leading zeros.
; AX, CX, DX destroyed. No other registers affected.

        PUSH    BX
        MOV     AL," "
        CALL    OUT
        CALL    CONV10
        MOV     AL,":"
        CALL    OUT
        MOV     AL,"*"
        POP     BX
        CMP     BX,[CURRENT]
        JZ      STARLIN
        MOV     AL," "
STARLIN:
        JMP     OUT


CONV10:

;Inputs:
;       BX = Binary number to be displayed
; Function:
;       Ouputs binary number. Five digits with leading
;       zero suppression. Zero prints 5 blanks.

        XOR     AX,AX
        MOV     DL,AL
        MOV     CX,16
CONV:
        SHL     BX,1
        ADC     AL,AL
        DAA
        XCHG    AL,AH
        ADC     AL,AL
        DAA
        XCHG    AL,AH
        ADC     DL,DL
        LOOP    CONV
        MOV     BL,"0"-" "
        XCHG    AX,DX
        CALL    LDIG
        MOV     AL,DH
        CALL    DIGITS
        MOV     AL,DL
DIGITS:
        MOV     DH,AL
        SHR     AL,1
        SHR     AL,1
        SHR     AL,1
        SHR     AL,1
        CALL    LDIG
        MOV     AL,DH
LDIG:
        AND     AL,0FH
        JZ      ZERDIG
        MOV     BL,0
ZERDIG:
        ADD     AL,"0"
        SUB     AL,BL
        JMP     OUT

RET5:   RET


CRLF:
        MOV     AL,13
        CALL    OUT
LF:
        MOV     AL,10
OUT:
        PUSH    DX
        XCHG    AX,DX
        MOV     AH,STD_CON_OUTPUT
        INT     21H
        XCHG    AX,DX
        POP     DX
        RET


;-----------------------------------------------------------------------;
; Will scan buffer given pointed to by SI and get rid of quote
;characters, compressing the line and adjusting the length at the
;begining of the line.
; Preserves al registers except flags and AX .

unquote:
        push    cx
        push    di
        push    si
        mov     di,si
        mov     cl,[si-1]       ;length of buffer
        xor     ch,ch
        mov     al,quote_char
        cld
unq_loop:
        jcxz    unq_done        ;no more chars in the buffer, exit
        repnz   scasb           ;search for quote character
        jnz     unq_done        ;none found, exit
        push    cx              ;save chars left in buffer
        push    di              ;save pointer to quoted character
        push    ax              ;save quote character
        mov     al,byte ptr[di] ;get quoted character
        call    make_cntrl
        mov     byte ptr[di],al
        pop     ax              ;restore quote character
        mov     si,di
        dec     di              ;points to the quote character
        inc     cx              ;include the carriage return also
        rep     movsb           ;compact line
        pop     di              ;now points to after quoted character
        pop     cx
        jcxz    sj13            ;if quote char was last of line do not adjust
        dec     cx              ;one less char left in the buffer
sj13:   pop     si
        dec     byte ptr[si-1]  ;one less character in total buffer count also
        push    si
        jmp     short unq_loop

unq_done:
        pop     si
        pop     di
        pop     cx
        ret


;-----------------------------------------------------------------------;
;       Convert the character in AL to the corresponding control
; character. AL has to be between @ and _ to be converted. That is,
; it has to be a capital letter. All other letters are left unchanged.

make_cntrl:
        push    ax
        and     ax,11100000b
        cmp     ax,01000000b
        pop     ax
        jne     sj14
        and     ax,00011111b
sj14:
        ret


;---- Kill spaces in buffer --------------------------------------------;
kill_bl:
        lodsb                           ;get rid of blanks
        cmp     al,' '
        je      kill_bl
        ret


;----- Restore INT 24 vector and old current directory -----------------;
rest_dir:
        cmp     [fudge],0
        je      no_fudge

        mov     ax,(set_interrupt_vector shl 8) or 24h
        lds     dx,[hardch]
        int     21h
        push    cs
        pop     ds

        mov     dx,offset dg:userdir            ;restore directory
        mov     ah,chdir
        int     21h
        mov     dl,[user_drive]                 ;restore old current drive
        mov     ah,set_default_drive
        int     21h

no_fudge:
        ret

;----- INT 24 Processing -----------------------------------------------;

int_24_retaddr dw       offset dg:int_24_back

int_24  proc    far
assume  ds:nothing,es:nothing,ss:nothing

        pushf
        push    cs
        push    [int_24_retaddr]
        push    word ptr [hardch+2]
        push    word ptr [hardch]
        ret
int_24  endp

int_24_back:
        cmp     al,2            ;abort?
        jnz     ireti
        push    cs
        pop     ds

assume  ds:dg

        call    rest_dir
        int     20h
ireti:
        iret

        IF      KANJI
TESTKANJ:
        CMP     AL,81H
        JB      NOTLEAD
        CMP     AL,9FH
        JBE     ISLEAD
        CMP     AL,0E0H
        JB      NOTLEAD
        CMP     AL,0FCH
        JBE     ISLEAD
NOTLEAD:
        PUSH    AX
        XOR     AX,AX           ;Set zero
        POP     AX
        RET

ISLEAD:
        PUSH    AX
        XOR     AX,AX           ;Set zero
        INC     AX              ;Reset zero
        POP     AX
        RET
        ENDIF

;-----------------------------------------------------------------------;

CODE    ENDS
        END     EDLPROC
                                               

