TITLE   PART2 - COMMAND Transient routines.

        INCLUDE COMSW.ASM

.xlist
.xcref
        INCLUDE DOSSYM.ASM
        INCLUDE DEVSYM.ASM
        INCLUDE COMSEG.ASM
.list
.cref

        INCLUDE COMEQU.ASM

CODERES SEGMENT PUBLIC
        EXTRN   LODCOM1:NEAR
CODERES ENDS

DATARES SEGMENT PUBLIC
        EXTRN   PARENT:WORD,IO_SAVE:WORD,PERMCOM:BYTE
        EXTRN   PIPEFLAG:BYTE,ENVIRSEG:WORD
        if      ibmver
        EXTRN   SYS_CALL:DWORD
        endif
DATARES ENDS

TRANDATA        SEGMENT PUBLIC

        EXTRN   PATH_TEXT:BYTE,PROMPT_TEXT:BYTE
        EXTRN   BADDEV:BYTE,SYNTMES:BYTE,ENVERR:BYTE
TRANDATA        ENDS

TRANSPACE       SEGMENT PUBLIC

        EXTRN   CURDRV:BYTE,DIRCHAR:BYTE,PWDBUF:BYTE
        EXTRN   INTERNATVARS:BYTE,RESSEG:WORD,TPA:WORD

TRANSPACE       ENDS


TRANCODE        SEGMENT PUBLIC BYTE
ASSUME  CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

        EXTRN   CERROR:NEAR,ZPRINT:NEAR
        EXTRN   CRLF2:NEAR,SCANOFF:NEAR,FREE_TPA:NEAR,ALLOC_TPA:NEAR
        EXTRN   OUT:NEAR,DRVBAD:NEAR,SETPATH:NEAR,PRINT:NEAR
        EXTRN   FCB_TO_ASCZ:NEAR

        PUBLIC  PRINT_DRIVE,$EXIT,MOVE_NAME
        PUBLIC  UPCONV,ADD_PROMPT,CTTY,PRINT_DEFAULT_DIRECTORY
        PUBLIC  ADD_NAME_TO_ENVIRONMENT,PWD,SCAN_DOUBLE_NULL
        PUBLIC  FIND_NAME_IN_ENVIRONMENT,STORE_CHAR
        PUBLIC  FIND_PATH,DELETE_PATH,FIND_PROMPT
        PUBLIC  SCASB2

        IF      KANJI
        PUBLIC  TESTKANJ
        ENDIF

BREAK   <Environment utilities>
ASSUME DS:TRANGROUP

ADD_PROMPT:
        CALL    DELETE_PROMPT                   ; DELETE ANY EXISTING PROMPT
        CALL    SCAN_DOUBLE_NULL
ADD_PROMPT2:
        PUSH    SI
        CALL    GETARG
        POP     SI
        retz                                    ; PRE SCAN FOR ARGUMENTS
        CALL    MOVE_NAME                       ; MOVE IN NAME
        CALL    GETARG
        JMP     SHORT ADD_NAME
;
; Input: DS:SI points to a CR terminated string
; Output: carry flag is set if no room
;         otherwise name is added to environment
;
ADD_NAME_TO_ENVIRONMENT:
        CALL    GETARG
        JZ      DISP_ENV
;
; check if line contains exactly one equals sign
;
        XOR     BX,BX           ;= COUNT IS 0
        PUSH    SI              ;SAVE POINTER TO BEGINNING OF LINE
EQLP:
        LODSB                   ;GET A CHAR
        CMP     AL,13           ;IF CR WE'RE ALL DONE
        JZ      QUEQ
        CMP     AL,"="          ;LOOK FOR = SIGN
        JNZ     EQLP            ;NOT THERE, GET NEXT CHAR
        INC     BL              ;OTHERWISE INCREMENT EQ COUNT
        CMP     BYTE PTR [SI],13        ;LOOK FOR CR FOLLOWING = SIGN
        JNZ     EQLP
        INC     BH              ;SET BH=1 MEANS NO PARAMETERS
        JMP     EQLP            ;AND LOOK FOR MORE
QUEQ:
        POP     SI              ;RESTORE BEGINNING OF LINE
        DEC     BL              ;ZERO FLAG MEANS ONLY ONE EQ
        JZ      ONEQ            ;GOOD LINE
        MOV     DX,OFFSET TRANGROUP:SYNTMES
        JMP     CERROR

ONEQ:
        PUSH    BX
        CALL    DELETE_NAME_IN_ENVIRONMENT
        POP     BX
        DEC     BH
        retz

        CALL    SCAN_DOUBLE_NULL
        CALL    MOVE_NAME
ADD_NAME:
        LODSB
        CMP     AL,13
        retz
        CALL    STORE_CHAR
        JMP     ADD_NAME

DISP_ENV:
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        MOV     DS,[ENVIRSEG]
ASSUME  DS:NOTHING
        XOR     SI,SI
PENVLP:
        CMP     BYTE PTR [SI],0
        retz

        MOV     DX,SI
        CALL    ZPRINT
        CALL    CRLF2
PENVLP2:
        LODSB
        OR      AL,AL
        JNZ     PENVLP2
        JMP     PENVLP

ASSUME  DS:TRANGROUP
DELETE_PATH:
        MOV     SI,OFFSET TRANGROUP:PATH_TEXT
        JMP     SHORT DELETE_NAME_IN_environment

DELETE_PROMPT:
        MOV     SI,OFFSET TRANGROUP:PROMPT_TEXT

DELETE_NAME_IN_environment:
;
; Input: DS:SI points to a "=" terminated string
; Output: carry flag is set if name not found
;         otherwise name is deleted
;
        PUSH    SI
        PUSH    DS
        CALL    FIND            ; ES:DI POINTS TO NAME
        JC      DEL1
        MOV     SI,DI           ; SAVE IT
        CALL    SCASB2          ; SCAN FOR THE NUL
        XCHG    SI,DI
        CALL    GETENVSIZ
        SUB     CX,SI
        PUSH    ES
        POP     DS              ; ES:DI POINTS TO NAME, DS:SI POINTS TO NEXT NAME
        REP     MOVSB           ; DELETE THE NAME
DEL1:
        POP     DS
        POP     SI
        return

FIND_PATH:
        MOV     SI,OFFSET TRANGROUP:PATH_TEXT
        JMP     SHORT FIND_NAME_IN_environment

FIND_PROMPT:
        MOV     SI,OFFSET TRANGROUP:PROMPT_TEXT

FIND_NAME_IN_environment:
;
; Input: DS:SI points to a "=" terminated string
; Output: ES:DI points to the arguments in the environment
;         zero is set if name not found
;         carry flag is set if name not valid format
;
        CALL    FIND                    ; FIND THE NAME
        retc                            ; CARRY MEANS NOT FOUND
        JMP     SCASB1                  ; SCAN FOR = SIGN
;
; On return of FIND1, ES:DI points to beginning of name
;
FIND:
        CLD
        CALL    COUNT0                  ; CX = LENGTH OF NAME
        MOV     ES,[RESSEG]
ASSUME  ES:RESGROUP
        MOV     ES,[ENVIRSEG]
ASSUME  ES:NOTHING
        XOR     DI,DI
FIND1:
        PUSH    CX
        PUSH    SI
        PUSH    DI
FIND11:
        LODSB

        IF      KANJI
        CALL    TESTKANJ
        JZ      NOTKANJ3
        DEC     SI
        LODSW
        INC     DI
        INC     DI
        CMP     AX,ES:[DI-2]
        JNZ     FIND12
        DEC     CX
        LOOP    FIND11
        JMP     SHORT FIND12

NOTKANJ3:
        ENDIF

        CALL    UPCONV
        INC     DI
        CMP     AL,ES:[DI-1]
        JNZ     FIND12
        LOOP    FIND11
FIND12:
        POP     DI
        POP     SI
        POP     CX
        retz
        PUSH    CX
        CALL    SCASB2                  ; SCAN FOR A NUL
        POP     CX
        CMP     BYTE PTR ES:[DI],0
        JNZ     FIND1
        STC                             ; INDICATE NOT FOUND
        return

COUNT0:
        PUSH    DS
        POP     ES
        MOV     DI,SI

COUNT1:
        PUSH    DI                      ; COUNT NUMBER OF CHARS UNTIL "="
        CALL    SCASB1
        JMP     SHORT COUNTX
COUNT2:
        PUSH    DI                      ; COUNT NUMBER OF CHARS UNTIL NUL
        CALL    SCASB2
COUNTX:
        POP     CX
        SUB     DI,CX
        XCHG    DI,CX
        return

MOVE_NAME:
        CMP     BYTE PTR DS:[SI],13
        retz
        LODSB

        IF      KANJI
        CALL    TESTKANJ
        JZ      NOTKANJ1
        CALL    STORE_CHAR
        LODSB
        CALL    STORE_CHAR
        JMP     SHORT MOVE_NAME

NOTKANJ1:
        ENDIF

        CALL    UPCONV
        CALL    STORE_CHAR
        CMP     AL,"="
        JNZ     MOVE_NAME
        return

GETARG:
        MOV     SI,80H
        LODSB
        OR      AL,AL
        retz
        CALL    SCANOFF
        CMP     AL,13
        return

SCAN_DOUBLE_NULL:
        MOV     ES,[RESSEG]
ASSUME  ES:RESGROUP
        MOV     ES,[ENVIRSEG]
ASSUME  ES:NOTHING
        XOR     DI,DI
SDN1:
        CALL    SCASB2
        CMP     BYTE PTR ES:[DI],0
        JNZ     SDN1
        return

SCASB1:
        MOV     AL,"="                  ; SCAN FOR AN =
        JMP     SHORT SCASBX
SCASB2:
        XOR     AL,AL                   ; SCAN FOR A NUL
SCASBX:
        MOV     CX,100H
        REPNZ   SCASB
        return

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
        return

ISLEAD:
        PUSH    AX
        XOR     AX,AX           ;Set zero
        INC     AX              ;Reset zero
        POP     AX
        return
        ENDIF

UPCONV:
        CMP     AL,"a"
        JB      RET22C
        CMP     AL,"z"
        JA      RET22C
        SUB     AL,20H          ; Lower-case changed to upper-case
RET22C:
        CALL    DWORD PTR CS:[INTERNATVARS.Map_call]
        return
;
; STORE A CHAR IN environment, GROWING IT IF NECESSARY
;
STORE_CHAR:
        PUSH    CX
        PUSH    BX
        CALL    GETENVSIZ
        MOV     BX,CX
        SUB     BX,2            ; SAVE ROOM FOR DOUBLE NULL
        CMP     DI,BX
        JB      STORE1

        PUSH    AX
        PUSH    CX
        PUSH    BX              ; Save Size of environment
        CALL    FREE_TPA
        POP     BX
        ADD     BX,2            ; Recover true environment size
        MOV     CL,4
        SHR     BX,CL           ; Convert back to paragraphs
        INC     BX              ; Try to grow environment by one para
        MOV     AH,SETBLOCK
        INT     int_command
        PUSHF
        PUSH    ES
        MOV     ES,[RESSEG]
        CALL    ALLOC_TPA
        POP     ES
        POPF
        POP     CX
        POP     AX
        JNC     STORE1
        MOV     DX,OFFSET TRANGROUP:ENVERR
        JMP     CERROR
STORE1:
        STOSB
        MOV     WORD PTR ES:[DI],0            ; NULL IS AT END
        POP     BX
        POP     CX
        return

GETENVSIZ:
;Get size of environment in bytes, rounded up to paragraph boundry
;ES has environment segment
;Size returned in CX, all other registers preserved

        PUSH    ES
        PUSH    AX
        MOV     AX,ES
        DEC     AX              ;Point at arena
        MOV     ES,AX
        MOV     AX,ES:[arena_size]
        MOV     CL,4
        SHL     AX,CL           ;Convert to bytes
        MOV     CX,AX
        POP     AX
        POP     ES
        return

PRINT_DRIVE:
        MOV     AH,GET_DEFAULT_DRIVE
        INT     int_command
        ADD     AL,"A"
        JMP     OUT

ASSUME  DS:TRANGROUP,ES:TRANGROUP
PWD:
        CALL    PRINT_DIRECTORY
        CALL    CRLF2
        return

PRINT_DEFAULT_DIRECTORY:
        MOV     BYTE PTR DS:[FCB],0
PRINT_DIRECTORY:
        MOV     DL,DS:[FCB]
        MOV     AL,DL
        ADD     AL,'@'
        CMP     AL,'@'
        JNZ     GOTDRIVE
        ADD     AL,[CURDRV]
        INC     AL
GOTDRIVE:
        PUSH    AX
        MOV     SI,OFFSET TRANGROUP:PWDBUF+3
        MOV     AH,CURRENT_DIR
        INT     int_command
        JNC     DPBISOK
        PUSH    CS
        POP     DS
        JMP     DRVBAD
DPBISOK:
        MOV     DI,OFFSET TRANGROUP:PWDBUF
        MOV     DX,DI
        POP     AX
        MOV     AH,DRVCHAR
        STOSW
        MOV     AL,[DIRCHAR]
        STOSB
        JMP     ZPRINT

$EXIT:
        PUSH    ES
        MOV     ES,[RESSEG]
ASSUME  ES:RESGROUP
        MOV     AX,[PARENT]
        MOV     WORD PTR ES:[PDB_Parent_PID],AX

IF IBM
        CMP     [PERMCOM],0
        JNZ     NORESETVEC      ;Don't reset the vector if a PERMCOM
        LDS     DX,DWORD PTR ES:[SYS_CALL]
ASSUME  DS:NOTHING
        MOV     AX,(SET_INTERRUPT_VECTOR SHL 8) + INT_COMMAND
        INT     int_command
NORESETVEC:
ENDIF

        POP     ES
ASSUME  ES:TRANGROUP
        MOV     ES,[TPA]
        MOV     AH,DEALLOC
        INT     int_command                             ; Now running in "free" space
        MOV     AX,(EXIT SHL 8)
        INT     int_command

CTTY:
        CALL    SETPATH         ; Get spec
        MOV     AX,(OPEN SHL 8) OR 2    ; Read and write
        INT     int_command             ; Open new device
        JC      ISBADDEV
        MOV     BX,AX
        MOV     AX,IOCTL SHL 8
        INT     int_command
        TEST    DL,80H
        JNZ     DEVISOK
        MOV     AH,CLOSE       ; Close initial handle
        INT     int_command
ISBADDEV:
        MOV     DX,OFFSET TRANGROUP:BADDEV
        CALL    PRINT
        JMP     RESRET

DEVISOK:
        XOR     DH,DH
        OR      DL,3            ; Make sure has CON attributes
        MOV     AX,(IOCTL SHL 8) OR 1
        INT     int_command
        PUSH    BX                      ; Save handle
        MOV     CX,3
        XOR     BX,BX
ICLLOOP:                                ; Close basic handles
        MOV     AH,CLOSE
        INT     int_command
        INC     BX
        LOOP    ICLLOOP
        POP     BX              ; Get handle
        MOV     AH,XDUP
        INT     int_command             ; Dup it to 0
        MOV     AH,XDUP
        INT     int_command             ; Dup to 1
        MOV     AH,XDUP
        INT     int_command             ; Dup to 2
        MOV     AH,CLOSE        ; Close initial handle
        INT     int_command
RESRET:
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        PUSH    DS
        MOV     AX,WORD PTR DS:[PDB_JFN_Table]           ; Get new 0 and 1
        MOV     [IO_SAVE],AX
        MOV     AX,OFFSET RESGROUP:LODCOM1
        PUSH    AX
ZMMMM   PROC FAR
        RET                     ; Force header to be checked
ZMMMM   ENDP

TRANCODE        ENDS
        END
                                                                                 