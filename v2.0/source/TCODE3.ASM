TITLE   PART3 - COMMAND Transient routines.

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
        EXTRN   BATCH:WORD,BATLOC:DWORD
        EXTRN   RETCODE:WORD,ECHOFLAG:BYTE
        EXTRN   SINGLECOM:WORD,FORFLAG:BYTE,UFORDRV:BYTE
        EXTRN   FORSET:BYTE,FORCOM:BYTE,FORVAR:BYTE,FORPTR:WORD
        EXTRN   FORUFCB:BYTE,FORFCB:BYTE,RE_INSTR:BYTE,RE_OUT_APP:BYTE
        EXTRN   RE_OUTSTR:BYTE,PIPEFLAG:BYTE

DATARES ENDS

TRANDATA        SEGMENT PUBLIC

        EXTRN   BADLAB:BYTE,SYNTMES:BYTE,FORNESTMES:BYTE
        EXTRN   NOTFND:BYTE,FULDIR:BYTE,IFTAB:BYTE
TRANDATA        ENDS

TRANSPACE       SEGMENT PUBLIC

        EXTRN   BATHAND:WORD,RESSEG:WORD,DIRBUF:BYTE,COMBUF:BYTE
        EXTRN   GOTOLEN:WORD,IFNOTFLAG:BYTE

TRANSPACE       ENDS


TRANCODE        SEGMENT PUBLIC BYTE
ASSUME  CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

        EXTRN   SCANOFF:NEAR,DOCOM:NEAR,DOCOM1:NEAR,CERROR:NEAR
        EXTRN   PRINT:NEAR,TCOMMAND:NEAR,DELIM:NEAR,GETBATBYT:NEAR
        EXTRN   FCB_TO_ASCZ:NEAR

        PUBLIC  GOTO,$IF,IFERLEV,SHIFT,IFEXISTS
        PUBLIC  STRCOMP,MesTran,$FOR,IFNOT
        PUBLIC  FORPROC,BATOPEN,BATCLOSE
        PUBLIC  IOSET,TESTDOREIN,TESTDOREOUT

        ASSUME  DS:RESGROUP
FORTERM:
        MOV     [FORFLAG],0
        CMP     [SINGLECOM],0FF00H
        JNZ     NOFORP2
        MOV     [SINGLECOM],-1          ; Cause a terminate
NOFORP2:
        JMP     TCOMMAND

FORPROC:
ASSUME  DS:RESGROUP
        CMP     [FORUFCB],-1
        JZ      NORMFOR
        MOV     DX,OFFSET TRANGROUP:DIRBUF
        PUSH    DS
        PUSH    CS
        POP     DS
ASSUME  DS:TRANGROUP
        MOV     AH,SET_DMA
        INT     int_command
        POP     DS
ASSUME  DS:RESGROUP
        MOV     DX,OFFSET RESGROUP:FORFCB
        MOV     AH,DIR_SEARCH_NEXT
        CMP     [FORUFCB],0
        JZ      DOFORSRCH
        MOV     AH,DIR_SEARCH_FIRST
        MOV     [FORUFCB],0
DOFORSRCH:
        INT     int_command
        OR      AL,AL
        JNZ     FORTERM
        PUSH    DS
        POP     ES
ASSUME  ES:RESGROUP
        PUSH    CS
        POP     DS
ASSUME  DS:TRANGROUP
        MOV     SI,OFFSET TRANGROUP:DIRBUF
        MOV     DI,OFFSET RESGROUP:FORSET
        MOV     [FORPTR],DI
        LODSB                   ;Get drive spec
        ADD     AL,'@'
        CMP     AL,'@'
        JZ      NDRV8
        CMP     [UFORDRV],0
        JZ      NDRV8
        MOV     AH,':'
        STOSW
NDRV8:
        CALL    FCB_TO_ASCZ
        MOV     BYTE PTR ES:[DI-1],0DH
        PUSH    ES
        POP     DS
ASSUME  DS:RESGROUP
NORMFOR:
        PUSH    CS
        POP     ES
ASSUME  ES:TRANGROUP
        MOV     BX,[FORPTR]
        CMP     BYTE PTR [BX],0
        JZ      FORTERM
        MOV     SI,BX
PARMSUB0:
        LODSB
        CMP     AL,0DH
        JNZ     PARMSUB0
        MOV     DX,SI           ; DX points to next parm
        MOV     SI,OFFSET RESGROUP:FORCOM
        MOV     DI,OFFSET TRANGROUP:COMBUF+2
        XOR     CX,CX
TFORCOM:
        LODSB
        CMP     AL,'%'
        JNZ     NOFORPARM
        MOV     AH,[FORVAR]
        CMP     AH,[SI]
        JNZ     NOFORPARM
        INC     SI
        PUSH    SI
        MOV     SI,BX
PARMSUB:
        LODSB
        CMP     AL,0DH
        JZ      PARMSUBDONE
        INC     CX
        STOSB
        JMP     SHORT PARMSUB
PARMSUBDONE:
        POP     SI              ; Get back command line pointer
        JMP     TFORCOM
NOFORPARM:
        STOSB
        INC     CX
        CMP     AL,0DH
        JNZ     TFORCOM
        DEC     CX
        MOV     [COMBUF+1],CL
        MOV     [FORPTR],DX     ; Point to next set element
        TEST    [ECHOFLAG],-1
        PUSH    CS
        POP     DS
ASSUME  DS:TRANGROUP
        JZ      NOECHO3
        MOV     BYTE PTR ES:[DI-1],'$'
        MOV     DX,OFFSET TRANGROUP:COMBUF+2
        CALL    PRINT
        MOV     BYTE PTR ES:[DI-1],0DH
        JMP     DOCOM
NOECHO3:
        JMP     DOCOM1

ASSUME  DS:TRANGROUP,ES:TRANGROUP

FORNESTERR:
        PUSH    DS
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        MOV     DX,OFFSET TRANGROUP:FORNESTMES
        CMP     [SINGLECOM],0FF00H
        JNZ     NOFORP3
        MOV     [SINGLECOM],-1          ; Cause termination
NOFORP3:
        POP     DS
ASSUME  DS:TRANGROUP
        JMP     CERROR

$FOR:
        MOV     SI,81H
        XOR     CX,CX
        MOV     ES,[RESSEG]
ASSUME  ES:RESGROUP
        MOV     DI,OFFSET RESGROUP:FORSET
        XOR     AL,AL
        MOV     [UFORDRV],AL
        XCHG    AL,[FORFLAG]
        OR      AL,AL
        JNZ     FORNESTERR
        MOV     [FORPTR],DI
        MOV     [FORUFCB],-1
        CALL    SCANOFF
        LODSW
        CMP     AL,'%'
        JNZ     FORERRORJ
        MOV     [FORVAR],AH
        CALL    SCANOFF
        CMP     AL,0DH
        JZ      FORERRORJ2
        LODSW
        CMP     AX,('N' SHL 8) OR 'I'
        JZ      FOROK1
        CMP     AX,('n' SHL 8) OR 'i'
        JNZ     FORERRORJ
FOROK1:
        CALL    SCANOFF
        LODSB
        CMP     AL,'('
        JNZ     FORERRORJ
        CALL    SCANOFF
        CMP     AL,')'          ; Special check for null set
        JNZ     FORSETLP
        MOV     DS,[RESSEG]
        JMP     FORTERM
FORSETLP:
        LODSB
        CMP     AL,0DH
FORERRORJ2:
        JZ  FORERRORJ3
        CMP     AL,')'
        JZ      FORSETEND
        STOSB
        CMP     AL,'*'
        JZ      SETFORSCAN
        CMP     AL,'?'
        JNZ     NOFORSCAN
SETFORSCAN:
        MOV     [FORUFCB],1
NOFORSCAN:
        CALL    DELIM
        JNZ     FORSETLP
        MOV     BYTE PTR ES:[DI-1],0DH
        CALL    SCANOFF
        JMP     FORSETLP

FORSETEND:
        MOV     AX,000DH
        CMP     BYTE PTR ES:[DI-1],0DH
        JNZ     FORSETTERM
        XOR     AX,AX
FORSETTERM:
        STOSW
        CALL    SCANOFF
        LODSW
        CMP     AX,('O' SHL 8) OR 'D'
        JZ      FOROK2
        CMP     AX,('o' SHL 8) OR 'd'
FORERRORJ:
        JNZ  FORERROR
FOROK2:
        CALL    SCANOFF
        CMP     AL,0DH
FORERRORJ3:
        JZ      FORERROR
        MOV     DI,OFFSET RESGROUP:FORCOM
FORCOMLP:
        LODSB
        STOSB
        CMP     AL,0DH
        JNZ     FORCOMLP
        INC     [FORFLAG]
        CMP     [SINGLECOM],-1
        JNZ     NOFORP
        MOV     [SINGLECOM],0FF00H      ; Flag single command for
NOFORP:
        CMP     [FORUFCB],1
        retnz
        PUSH    ES
        POP     DS
ASSUME  DS:RESGROUP
        MOV     DI,OFFSET RESGROUP:FORFCB
        MOV     SI,OFFSET RESGROUP:FORSET
        CMP     BYTE PTR [SI+1],':'
        JNZ     NOSETUDRV
        INC     [UFORDRV]
NOSETUDRV:
        MOV     AX,PARSE_FILE_DESCRIPTOR SHL 8
        INT     int_command
        return


ASSUME  DS:TRANGROUP,ES:TRANGROUP

IFERRORP:
        POP     AX
IFERROR:
FORERROR:
        MOV     DX,OFFSET TRANGROUP:SYNTMES
        JMP     CERROR

$IF:
        MOV     [IFNOTFLAG],0
        MOV     SI,81H
IFREENT:
        CALL    SCANOFF
        CMP     AL,0DH
        JZ      IFERROR
        MOV     BP,SI
        MOV     DI,OFFSET TRANGROUP:IFTAB     ; Prepare to search if table
        MOV     CH,0
IFINDCOM:
        MOV     SI,BP
        MOV     CL,[DI]
        INC     DI
        JCXZ    IFSTRING
        JMP     SHORT FIRSTCOMP
IFCOMP:
        JNZ     IFDIF
FIRSTCOMP:
        LODSB
        MOV     AH,ES:[DI]
        INC     DI
        CMP     AL,AH
        JZ      IFLP
        OR      AH,20H          ; Try lower case
        CMP     AL,AH
IFLP:
        LOOP    IFCOMP
IFDIF:
        LAHF
        ADD     DI,CX           ; Bump to next position without affecting flags
        MOV     BX,[DI]         ; Get handler address
        INC     DI
        INC     DI
        SAHF
        JNZ     IFINDCOM
        LODSB
        CMP     AL,0DH
IFERRORJ:
        JZ    IFERROR
        CALL    DELIM
        JNZ     IFINDCOM
        CALL    SCANOFF
        JMP     BX

IFNOT:
        NOT     [IFNOTFLAG]
        JMP     IFREENT


IFSTRING:
        PUSH    SI
        XOR     CX,CX
FIRST_STRING:
        LODSB
        CMP     AL,0DH
        JZ      IFERRORP
        CALL    DELIM
        JZ      EQUAL_CHECK
        INC     CX
        JMP     SHORT FIRST_STRING
EQUAL_CHECK:
        CMP     AL,'='
        JZ      EQUAL_CHECK2
        CMP     AL,0DH
        JZ      IFERRORP
        LODSB
        JMP     SHORT EQUAL_CHECK
EQUAL_CHECK2:
        LODSB
        CMP     AL,'='
        JNZ     IFERRORP
        CALL    SCANOFF
        CMP     AL,0DH
        JZ      IFERRORP
        POP     DI
        REPE    CMPSB
        JZ      MATCH
        CMP     BYTE PTR [SI-1],0DH
        JZ      IFERRORJ
SKIPSTRINGEND:
        LODSB
NOTMATCH:
        CMP     AL,0DH
IFERRORJ2:
        JZ   IFERRORJ
        CALL    DELIM
        JNZ     SKIPSTRINGEND
        MOV     AL,-1
        JMP     SHORT IFRET
MATCH:
        LODSB
        CALL    DELIM
        JNZ     NOTMATCH
        XOR     AL,AL
        JMP     SHORT IFRET

IFEXISTS:
        MOV     DI,OFFSET TRANGROUP:DIRBUF
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
        INT     int_command
        MOV     AH,FCB_OPEN
        MOV     DX,DI
        INT     int_command
IFRET:
        TEST    [IFNOTFLAG],-1
        JZ      REALTEST
        NOT     AL
REALTEST:
        OR      AL,AL
        JZ      IFTRUE
        JMP     TCOMMAND
IFTRUE:
        CALL    SCANOFF
        MOV     CX,SI
        SUB     CX,81H
        SUB     DS:[80H],CL
        MOV     CL,DS:[80H]
        MOV     [COMBUF+1],CL
        MOV     DI,OFFSET TRANGROUP:COMBUF+2
        REP     MOVSB
        MOV     AL,0DH
        STOSB
        JMP     DOCOM1

IFERLEV:
        MOV     BH,10
        XOR     BL,BL
GETNUMLP:
        LODSB
        CMP     AL,0DH
        JZ      IFERRORJ2
        CALL    DELIM
        JZ      GOTNUM
        SUB     AL,'0'
        XCHG    AL,BL
        MUL     BH
        ADD     AL,BL
        XCHG    AL,BL
        JMP     SHORT GETNUMLP
GOTNUM:
        PUSH    DS
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        MOV     AH,BYTE PTR [RETCODE]
        POP     DS
ASSUME  DS:TRANGROUP
        XOR     AL,AL
        CMP     AH,BL
        JAE     IFRET
        DEC     AL
        JMP     SHORT IFRET

ASSUME  DS:TRANGROUP

SHIFT:
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        MOV     AX,[BATCH]
        TEST    AX,-1
        retz
        MOV     ES,AX
        MOV     DS,AX
ASSUME  DS:NOTHING,ES:NOTHING
        XOR     CX,CX
        MOV     AX,CX
        MOV     DI,CX
        DEC     CX
        REPNZ   SCASB
        MOV     SI,DI
        INC     SI
        INC     SI
        MOV     CX,9
        REP     MOVSW                   ; Perform shift of existing parms
        CMP     WORD PTR [DI],-1
        retz                            ; No new parm
        MOV     SI,[DI]
        MOV     WORD PTR [DI],-1        ; Assume no parm
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
SKIPCRLP:
        LODSB
        CMP     AL,0DH
        JNZ     SKIPCRLP
        CMP     BYTE PTR [SI],0
        retz                            ; End of parms
        MOV     ES:[DI],SI              ; Pointer to next parm as %9
        return


ASSUME  DS:TRANGROUP,ES:TRANGROUP
GOTO:
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        TEST    [BATCH],-1
        retz                    ; If not in batch mode, a nop
        XOR     DX,DX
        MOV     WORD PTR [BATLOC],DX    ; Back to start
        MOV     WORD PTR [BATLOC+2],DX
        CALL    BATOPEN                 ; Find the batch file
        MOV     DI,FCB+1        ; Get the label
        MOV     CX,11
        MOV     AL,' '
        REPNE   SCASB
        JNZ     NOINC
        INC     CX
NOINC:
        SUB     CX,11
        NEG     CX
        MOV     [GOTOLEN],CX
        CALL    GETBATBYT
        CMP     AL,':'
        JZ      CHKLABEL
LABLKLP:                        ; Look for the label
        CALL    GETBATBYT
        CMP     AL,0AH
        JNZ     LABLKTST
        CALL    GETBATBYT
        CMP     AL,':'
        JZ      CHKLABEL
LABLKTST:
        TEST    [BATCH],-1
        JNZ     LABLKLP
        CALL    BATCLOSE
        PUSH    CS
        POP     DS
        MOV     DX,OFFSET TRANGROUP:BADLAB
        JMP     CERROR

CHKLABEL:
        MOV     DI,FCB+1
        MOV     CX,[GOTOLEN]
NEXTCHRLP:
        PUSH    CX
        CALL    GETBATBYT
        POP     CX
        OR      AL,20H
        CMP     AL,ES:[DI]
        JNZ     TRYUPPER
        JMP     SHORT NEXTLABCHR
TRYUPPER:
        SUB     AL,20H
        CMP     AL,ES:[DI]
        JNZ     LABLKTST
NEXTLABCHR:
        INC     DI
        LOOP    NEXTCHRLP
        CALL    GETBATBYT
        CMP     AL,' '
        JA      LABLKTST
        CMP     AL,0DH
        JZ      SKIPLFEED
TONEXTBATLIN:
        CALL    GETBATBYT
        CMP     AL,0DH
        JNZ     TONEXTBATLIN
SKIPLFEED:
        CALL    GETBATBYT
BATCLOSE:
        MOV     BX,CS:[BATHAND]
        MOV     AH,CLOSE
        INT     int_command
        return

BATOPEN:
;Open the BATCH file, If open fails, AL is drive of batch file (A=1)
ASSUME  DS:RESGROUP,ES:TRANGROUP
        PUSH    DS
        MOV     DS,[BATCH]
ASSUME  DS:NOTHING
        XOR     DX,DX
        MOV     AX,OPEN SHL 8
        INT     int_command             ; Open the batch file
        JC      SETERRDL
        POP     DS
ASSUME  DS:RESGROUP
        MOV     [BATHAND],AX
        MOV     BX,AX
        MOV     DX,WORD PTR [BATLOC]
        MOV     CX,WORD PTR [BATLOC+2]
        MOV     AX,LSEEK SHL 8          ; Go to the right spot
        INT     int_command
        return

SETERRDL:
        MOV     BX,DX
        MOV     AL,[BX]                 ; Get drive spec
        SUB     AL,'@'                  ; A = 1
        POP     DS
        STC                             ; SUB mucked over carry
        return

MESTRAN:
ASSUME  DS:NOTHING,ES:NOTHING
        LODSB
        CMP     AL,"$"
        retz
        STOSB
        JMP     MESTRAN
IOSET:
; ALL REGISTERS PRESERVED
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        PUSH    DS
        PUSH    DX
        PUSH    AX
        PUSH    BX
        PUSH    CX
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        CMP     [PIPEFLAG],0
        JNZ     NOREDIR                 ; Don't muck up the pipe
        CALL    TESTDOREIN
        CALL    TESTDOREOUT
NOREDIR:
        POP     CX
        POP     BX
        POP     AX
        POP     DX
        POP     DS
ASSUME  DS:NOTHING
        return

TESTDOREIN:
ASSUME  DS:RESGROUP
        CMP     [RE_INSTR],0
        retz
        MOV     DX,OFFSET RESGROUP:RE_INSTR
        MOV     AX,(OPEN SHL 8)
        INT     int_command
        MOV     DX,OFFSET TRANGROUP:NOTFND
        JC      REDIRERR
        MOV     BX,AX
        MOV     AL,0FFH
        XCHG    AL,[BX.PDB_JFN_Table]
        MOV     DS:[PDB_JFN_Table],AL
        return

REDIRERR:
        PUSH    CS
        POP     DS
        JMP     CERROR

TESTDOREOUT:
ASSUME  DS:RESGROUP
        CMP     [RE_OUTSTR],0
        JZ      NOREOUT
        CMP     [RE_OUT_APP],0
        JZ      REOUTCRT
        MOV     DX,OFFSET RESGROUP:RE_OUTSTR
        MOV     AX,(OPEN SHL 8) OR 1
        INT     int_command
        JC      REOUTCRT
        XOR     DX,DX
        XOR     CX,CX
        MOV     BX,AX
        MOV     AX,(LSEEK SHL 8) OR 2
        INT     int_command
        JMP     SHORT SET_REOUT
REOUTCRT:
        MOV     DX,OFFSET RESGROUP:RE_OUTSTR
        XOR     CX,CX
        MOV     AH,CREAT
        INT     int_command
        MOV     DX,OFFSET TRANGROUP:FULDIR
        JC      REDIRERR
        MOV     BX,AX
SET_REOUT:
        MOV     AL,0FFH
        XCHG    AL,[BX.PDB_JFN_Table]
        MOV     DS:[PDB_JFN_Table+1],AL
NOREOUT:
        return

STRCOMP:
; Compare ASCIZ DS:SI with ES:DI.
; SI,DI destroyed.
        CMPSB
        retnz                           ; Strings not equal
        cmp     byte ptr [SI-1],0       ; Hit NUL terminator?
        retz                            ; Yes, strings equal
        jmp     short STRCOMP           ; Equal so far, keep going



TRANCODE        ENDS
        END
                                                                                                                    