TITLE   CPARSE

        INCLUDE COMSW.ASM

.xlist
.xcref
        INCLUDE DOSSYM.ASM
        INCLUDE DEVSYM.ASM
        INCLUDE COMSEG.ASM
.list
.cref

        INCLUDE COMEQU.ASM

DATARES SEGMENT PUBLIC
DATARES ENDS

TRANDATA        SEGMENT PUBLIC
        EXTRN   BADCPMES:BYTE
TRANDATA        ENDS

TRANSPACE       SEGMENT PUBLIC
        EXTRN   CURDRV:BYTE,ELPOS:BYTE,STARTEL:WORD
        EXTRN   SKPDEL:BYTE,SWITCHAR:BYTE,ELCNT:BYTE

TRANSPACE       ENDS

TRANCODE        SEGMENT PUBLIC BYTE

ASSUME  CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP

        EXTRN   DELIM:NEAR,UPCONV:NEAR,PATHCHRCMP:NEAR
        EXTRN   SWLIST:BYTE,BADCDERR:NEAR,SCANOFF:NEAR,CERROR:NEAR

        if  KANJI
        EXTRN   TESTKANJ:NEAR
        endif

SWCOUNT EQU 5

        PUBLIC  CPARSE

CPARSE:

;-----------------------------------------------------------------------;
; ENTRY:                                                                ;
;       DS:SI   Points input buffer                                     ;
;       ES:DI   Points to the token buffer                              ;
;       BL      Special delimiter for this call                         ;
;                   Always checked last                                 ;
;                   set it to space if there is no special delimiter    ;
; EXIT:                                                                 ;
;       DS:SI   Points to next char in the input buffer                 ;
;       ES:DI   Points to the token buffer                              ;
;       [STARTEL] Points to start of last element of path in token      ;
;               points to a NUL for no element strings 'd:' 'd:/'       ;
;       CX      Character count                                         ;
;       BH      Condition Code                                          ;
;                       Bit 1H of BH set if switch character            ;
;                               Token buffer contains char after        ;
;                               switch character                        ;
;                               BP has switch bits set (ORing only)     ;
;                       Bit 2H of BH set if ? or * in token             ;
;                               if * found element ? filled             ;
;                       Bit 4H of BH set if path sep in token           ;
;                       Bit 80H of BH set if the special delimiter      ;
;                          was skipped at the start of this token       ;
;               Token buffer always starts d: for non switch tokens     ;
;       CARRY SET                                                       ;
;           if CR on input                                              ;
;               token buffer not altered                                ;
;                                                                       ;
;       DOES NOT RETURN ON BAD PATH ERROR                               ;
; MODIFIES:                                                             ;
;       CX, SI, AX, BH, DX and the Carry Flag                           ;       ;
;                                                                       ;
; -----------------------------------------------------------------------;

        xor     ax,ax
        mov     [STARTEL],DI            ; No path element (Is DI correct?)
        mov     [ELPOS],al              ; Start in 8 char prefix
        mov     [SKPDEL],al             ; No skip delimiter yet
        mov     bh,al                   ; Init nothing
        pushf                           ; save flags
        push    di                      ; save the token buffer addrss
        xor     cx,cx                   ; no chars in token buffer
moredelim:
        LODSB
        CALL    DELIM
        JNZ     SCANCDONE
        CMP     AL,' '
        JZ      moredelim
        CMP     AL,9
        JZ      moredelim
        xchg    al,[SKPDEL]
        or      al,al
        jz      moredelim               ; One non space/tab delimiter allowed
        JMP     x_done                  ; Nul argument

SCANCDONE:

        IF      NOT KANJI
        call    UPCONV
        ENDIF

        cmp     al,bl                   ; Special delimiter?
        jnz     nospec
        or      bh,80H
        jmp     short moredelim

nospec:
        cmp     al,0DH                  ; a CR?
        jne     ncperror
        jmp     cperror
ncperror:
        cmp     al,[SWITCHAR]           ; is the char the switch char?
        jne     na_switch               ; yes, process...
        jmp     a_switch
na_switch:
        cmp     byte ptr [si],':'
        jne     anum_chard              ; Drive not specified

        IF      KANJI
        call    UPCONV
        ENDIF

        call    move_char
        lodsb                           ; Get the ':'
        call    move_char
        mov     [STARTEL],di
        mov     [ELCNT],0
        jmp     anum_test

anum_chard:
        mov     [STARTEL],di
        mov     [ELCNT],0               ; Store of this char sets it to one
        call    PATHCHRCMP              ; Starts with a pathchar?
        jnz     anum_char               ; no
        push    ax
        mov     al,[CURDRV]             ; Insert drive spec
        add     al,'A'
        call    move_char
        mov     al,':'
        call    move_char
        pop     ax
        mov     [STARTEL],di
        mov     [ELCNT],0

anum_char:

        IF      KANJI
        call    TESTKANJ
        jz      TESTDOT
        call    move_char
        lodsb
        jmp     short notspecial

TESTDOT:
        ENDIF

        cmp     al,'.'
        jnz     testquest
        inc     [ELPOS]                 ; flag in extension
        mov     [ELCNT],0FFH            ; Store of the '.' resets it to 0
testquest:
        cmp     al,'?'
        jnz     testsplat
        or      bh,2
testsplat:
        cmp     al,'*'
        jnz     testpath
        or      bh,2
        mov     ah,7
        cmp     [ELPOS],0
        jz      gotelcnt
        mov     ah,2
gotelcnt:
        mov     al,'?'
        sub     ah,[ELCNT]
        jc      badperr2
        xchg    ah,cl
        jcxz    testpathx
qmove:
        xchg    ah,cl
        call    move_char
        xchg    ah,cl
        loop    qmove
testpathx:
        xchg    ah,cl
testpath:
        call    PATHCHRCMP
        jnz     notspecial
        or      bh,4
        test    bh,2                    ; If just hit a '/', cannot have ? or * yet
        jnz     badperr
        mov     [STARTEL],di            ; New element
        INC     [STARTEL]               ; Point to char after /
        mov     [ELCNT],0FFH            ; Store of '/' sets it to 0
        mov     [ELPOS],0
notspecial:
        call    move_char               ; just an alphanum string
anum_test:
        lodsb

        IF      NOT KANJI
        call    UPCONV
        ENDIF

        call    DELIM
        je      x_done
        cmp     al,0DH
        je      x_done
        cmp     al,[SWITCHAR]
        je      x_done
        cmp     al,bl
        je      x_done
        cmp     al,':'                  ; ':' allowed as trailer because
                                        ; of devices
        IF      KANJI
        je      FOO15
        jmp     anum_char
FOO15:
        ELSE
        jne     anum_char
        ENDIF

        mov     byte ptr [si-1],' '     ; Change the trailing ':' to a space
        jmp     short x_done

badperr2:
        mov     dx,offset trangroup:BADCPMES
        jmp     CERROR

badperr:
        jmp     BADCDERR

cperror:
        dec     si                      ; adjust the pointer
        pop     di                      ; retrive token buffer address
        popf                            ; restore flags
        stc                             ; set the carry bit
        return

x_done:
        dec     si                      ; adjust for next round
        jmp     short out_token

a_switch:
        OR      BH,1                    ; Indicate switch
        OR      BP,GOTSWITCH
        CALL    SCANOFF
        INC     SI
        cmp     al,0DH
        je      cperror
        call    move_char               ; store the character
        CALL    UPCONV
        PUSH    ES
        PUSH    DI
        PUSH    CX
        PUSH    CS
        POP     ES
ASSUME  ES:TRANGROUP
        MOV     DI,OFFSET TRANGROUP:SWLIST
        MOV     CX,SWCOUNT
        REPNE   SCASB
        JNZ     out_tokenp
        MOV     AX,1
        SHL     AX,CL
        OR      BP,AX
out_tokenp:
        POP     CX
        POP     DI
        POP     ES
ASSUME  ES:NOTHING
out_token:
        mov     al,0
        stosb                           ; null at the end
        pop     di                      ; restore token buffer pointer
        popf
        clc                             ; clear carry flag
        return

move_char:
        stosb                           ; store char in token buffer
        inc     cx                      ; increment char count
        inc     [ELCNT]                 ; increment element count for * substi
        return

TRANCODE        ENDS
        END
                                                                                                                             