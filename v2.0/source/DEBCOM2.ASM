TITLE   PART2 DEBUGGER COMMANDS

; Routines to perform debugger commands except ASSEMble and UASSEMble

.xlist
.xcref
        INCLUDE DEBEQU.ASM
        INCLUDE DOSSYM.ASM
.cref
.list

CODE    SEGMENT PUBLIC BYTE 'CODE'
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE

        EXTRN   NOTFND:BYTE,NOROOM:BYTE,DRVLET:BYTE,NOSPACE:BYTE,NAMBAD:BYTE
        EXTRN   TOOBIG:BYTE,ERRMES:BYTE
        EXTRN   EXEBAD:BYTE,HEXERR:BYTE,EXEWRT:BYTE,HEXWRT:BYTE
        EXTRN   EXECEMES:BYTE,WRTMES1:BYTE,WRTMES2:BYTE,ACCMES:BYTE

        EXTRN   FLAGTAB:WORD,EXEC_BLOCK:BYTE,COM_LINE:DWORD,COM_FCB1:DWORD
        EXTRN   COM_FCB2:DWORD,COM_SSSP:DWORD,COM_CSIP:DWORD,RETSAVE:WORD
        EXTRN   NEWEXEC:BYTE,HEADSAVE:WORD
        EXTRN   REGTAB:BYTE,TOTREG:BYTE,NOREGL:BYTE
        EXTRN   USER_PROC_PDB:WORD,STACK:BYTE,RSTACK:WORD,AXSAVE:WORD
        EXTRN   BXSAVE:WORD,DSSAVE:WORD,ESSAVE:WORD,CSSAVE:WORD,IPSAVE:WORD
        EXTRN   SSSAVE:WORD,CXSAVE:WORD,SPSAVE:WORD,FSAVE:WORD
        EXTRN   SREG:BYTE,SEGTAB:WORD,REGDIF:WORD,RDFLG:BYTE

CONST   ENDS

DATA    SEGMENT PUBLIC BYTE

        EXTRN   DEFDUMP:BYTE,TRANSADD:DWORD,INDEX:WORD,BUFFER:BYTE
        EXTRN   ASMADD:BYTE,DISADD:BYTE,NSEG:WORD,BPTAB:BYTE
        EXTRN   BRKCNT:WORD,TCOUNT:WORD,SWITCHAR:BYTE,XNXCMD:BYTE,XNXOPT:BYTE
        EXTRN   AWORD:BYTE,EXTPTR:WORD,HANDLE:WORD,PARSERR:BYTE

DATA    ENDS

DG      GROUP   CODE,CONST,DATA


CODE    SEGMENT PUBLIC BYTE 'CODE'
ASSUME  CS:DG,DS:DG,ES:DG,SS:DG

        PUBLIC  DEFIO,SKIP_FILE,PREPNAME,DEBUG_FOUND
        PUBLIC  REG,COMPARE,GO,INPUT,LOAD
        PUBLIC  NAME,OUTPUT,TRACE,ZTRACE,DWRITE
        if  sysver
        PUBLIC  DISPREG
        endif

        EXTRN   GETHEX:NEAR,GETEOL:NEAR
        EXTRN   CRLF:NEAR,BLANK:NEAR,OUT:NEAR
        EXTRN   OUTSI:NEAR,OUTDI:NEAR,INBUF:NEAR,SCANB:NEAR,SCANP:NEAR
        EXTRN   RPRBUF:NEAR,HEX:NEAR,OUT16:NEAR,DIGIT:NEAR
        EXTRN   COMMAND:NEAR,DISASLN:NEAR,SET_TERMINATE_VECTOR:NEAR
        EXTRN   RESTART:NEAR,DABORT:NEAR,TERMINATE:NEAR,DRVERR:NEAR
        EXTRN   FIND_DEBUG:NEAR,NMIInt:NEAR,NMIIntEnd:NEAR
        EXTRN   HEXCHK:NEAR,GETHEX1:NEAR,PRINT:NEAR,DSRANGE:NEAR
        EXTRN   ADDRESS:NEAR,HEXIN:NEAR,PERROR:NEAR


DEBCOM2:
DISPREG:
        MOV     SI,OFFSET DG:REGTAB
        MOV     BX,OFFSET DG:AXSAVE
        MOV     BYTE PTR TOTREG,13
        MOV     CH,0
        MOV     CL,NOREGL
REPDISP:
        SUB     TOTREG,CL
        CALL    DISPREGLINE
        CALL    CRLF
        MOV     CH,0
        MOV     CL,NOREGL
        CMP     CL,TOTREG
        JL      REPDISP
        MOV     CL,TOTREG
        CALL    DISPREGLINE
        CALL    BLANK
        CALL    DISPFLAGS
        CALL    CRLF
        MOV     AX,[IPSAVE]
        MOV     WORD PTR [DISADD],AX
        PUSH    AX
        MOV     AX,[CSSAVE]
        MOV     WORD PTR [DISADD+2],AX
        PUSH    AX
        MOV     [NSEG],-1
        CALL    DISASLN
        POP     WORD PTR DISADD+2
        POP     WORD PTR DISADD
        MOV     AX,[NSEG]
        CMP     AL,-1
        JZ      CRLFJ
        CMP     AH,-1
        JZ      NOOVER
        XCHG    AL,AH
NOOVER:
        CBW
        MOV     BX,AX
        SHL     BX,1
        MOV     AX,WORD PTR [BX+SREG]
        CALL    OUT
        XCHG    AL,AH
        CALL    OUT
        MOV     AL,":"
        CALL    OUT
        MOV     DX,[INDEX]
        CALL    OUT16
        MOV     AL,"="
        CALL    OUT
        MOV     BX,[BX+SEGTAB]
        PUSH    DS
        MOV     DS,[BX]
        MOV     BX,DX
        MOV     DX,[BX]
        POP     DS
        TEST    BYTE PTR [AWORD],-1
        JZ      OUT8
        CALL    OUT16
CRLFJ:
        JMP     CRLF
OUT8:
        MOV     AL,DL
        CALL    HEX
        JMP     CRLF

DISPREGJ:JMP    DISPREG

; Perform register dump if no parameters or set register if a
; register designation is a parameter.

REG:
        CALL    SCANP
        JZ      DISPREGJ
        MOV     DL,[SI]
        INC     SI
        MOV     DH,[SI]
        CMP     DH,13
        JZ      FLAG
        INC     SI
        CALL    GETEOL
        CMP     DH," "
        JZ      FLAG
        MOV     DI,OFFSET DG:REGTAB
        XCHG    AX,DX
        PUSH    CS
        POP     ES
        MOV     CX,REGTABLEN
        REPNZ   SCASW
        JNZ     BADREG
        OR      CX,CX
        JNZ     NOTPC
        DEC     DI
        DEC     DI
        MOV     AX,CS:[DI-2]
NOTPC:
        CALL    OUT
        MOV     AL,AH
        CALL    OUT
        CALL    BLANK
        PUSH    DS
        POP     ES
        LEA     BX,[DI+REGDIF-2]
        MOV     DX,[BX]
        CALL    OUT16
        CALL    CRLF
        MOV     AL,":"
        CALL    OUT
        CALL    INBUF
        CALL    SCANB
        JZ      RET4
        MOV     CX,4
        CALL    GETHEX1
        CALL    GETEOL
        MOV     [BX],DX
RET4:   RET
BADREG:
        MOV     AX,5200H+"B"            ; BR ERROR
        JMP     ERR
FLAG:
        CMP     DL,"F"
        JNZ     BADREG
        CALL    DISPFLAGS
        MOV     AL,"-"
        CALL    OUT
        CALL    INBUF
        CALL    SCANB
        XOR     BX,BX
        MOV     DX,[FSAVE]
GETFLG:
        LODSW
        CMP     AL,13
        JZ      SAVCHG
        CMP     AH,13
        JZ      FLGERR
        MOV     DI,OFFSET DG:FLAGTAB
        MOV     CX,32
        PUSH    CS
        POP     ES
        REPNE   SCASW
        JNZ     FLGERR
        MOV     CH,CL
        AND     CL,0FH
        MOV     AX,1
        ROL     AX,CL
        TEST    AX,BX
        JNZ     REPFLG
        OR      BX,AX
        OR      DX,AX
        TEST    CH,16
        JNZ     NEXFLG
        XOR     DX,AX
NEXFLG:
        CALL    SCANP
        JMP     SHORT GETFLG
DISPREGLINE:
        LODS    CS:WORD PTR [SI]
        CALL    OUT
        MOV     AL,AH
        CALL    OUT
        MOV     AL,"="
        CALL    OUT
        MOV     DX,[BX]
        INC     BX
        INC     BX
        CALL    OUT16
        CALL    BLANK
        CALL    BLANK
        LOOP    DISPREGLINE
        RET
REPFLG:
        MOV     AX,4600H+"D"            ; DF ERROR
FERR:
        CALL    SAVCHG
ERR:
        CALL    OUT
        MOV     AL,AH
        CALL    OUT
        MOV     SI,OFFSET DG:ERRMES
        JMP     PRINT
SAVCHG:
        MOV     [FSAVE],DX
        RET
FLGERR:
        MOV     AX,4600H+"B"            ; BF ERROR
        JMP     SHORT FERR
DISPFLAGS:
        MOV     SI,OFFSET DG:FLAGTAB
        MOV     CX,16
        MOV     DX,[FSAVE]
DFLAGS:
        LODS    CS:WORD PTR [SI]
        SHL     DX,1
        JC      FLAGSET
        MOV     AX,CS:[SI+30]
FLAGSET:
        OR      AX,AX
        JZ      NEXTFLG
        CALL    OUT
        MOV     AL,AH
        CALL    OUT
        CALL    BLANK
NEXTFLG:
        LOOP    DFLAGS
        RET

; Input from the specified port and display result

INPUT:
        MOV     CX,4                    ; Port may have 4 digits
        CALL    GETHEX                  ; Get port number in DX
        CALL    GETEOL
        IN      AL,DX                   ; Variable port input
        CALL    HEX                     ; And display
        JMP     CRLF

; Output a value to specified port.

OUTPUT:
        MOV     CX,4                    ; Port may have 4 digits
        CALL    GETHEX                  ; Get port number
        PUSH    DX                      ; Save while we get data
        MOV     CX,2                    ; Byte output only
        CALL    GETHEX                  ; Get data to output
        CALL    GETEOL
        XCHG    AX,DX                   ; Output data in AL
        POP     DX                      ; Port in DX
        OUT     DX,AL                   ; Variable port output
RET5:   RET
COMPARE:
        CALL    DSRANGE
        PUSH    CX
        PUSH    AX
        PUSH    DX
        CALL    ADDRESS                 ; Same segment
        CALL    GETEOL
        POP     SI
        MOV     DI,DX
        MOV     ES,AX
        POP     DS
        POP     CX                      ; Length
        DEC     CX
        CALL    COMP                    ; Do one less than total
        INC     CX                      ; CX=1 (do last one)
COMP:
        REPE    CMPSB
        JZ      RET5
; Compare error. Print address, value; value, address.
        DEC     SI
        CALL    OUTSI
        CALL    BLANK
        CALL    BLANK
        LODSB
        CALL    HEX
        CALL    BLANK
        CALL    BLANK
        DEC     DI
        MOV     AL,ES:[DI]
        CALL    HEX
        CALL    BLANK
        CALL    BLANK
        CALL    OUTDI
        INC     DI
        CALL    CRLF
        XOR     AL,AL
        JMP     SHORT COMP

ZTRACE:
IF ZIBO
; just like trace except skips OVER next INT or CALL.
        CALL    SETADD                  ; get potential starting point
        CALL    GETEOL                  ; check for end of line
        MOV     [TCOUNT],1              ; only a single go at it
        MOV     ES,[CSSAVE]             ; point to instruction to execute
        MOV     DI,[IPSAVE]             ; include offset in segment
        XOR     DX,DX                   ; where to place breakpoint
        MOV     AL,ES:[DI]              ; get the opcode
        CMP     AL,11101000B            ; direct intra call
        JZ      ZTrace3                 ; yes, 3 bytes
        CMP     AL,10011010B            ; direct inter call
        JZ      ZTrace5                 ; yes, 5 bytes
        CMP     AL,11111111B            ; indirect?
        JZ      ZTraceModRM             ; yes, go figure length
        CMP     AL,11001100B            ; short interrupt?
        JZ      ZTrace1                 ; yes, 1 byte
        CMP     AL,11001101B            ; long interrupt?
        JZ      ZTrace2                 ; yes, 2 bytes
        CMP     AL,11100010B            ; loop
        JZ      ZTrace2                 ; 2 byter
        CMP     AL,11100001B            ; loopz/loope
        JZ      ZTrace2                 ; 2 byter
        CMP     AL,11100000B            ; loopnz/loopne
        JZ      ZTrace2                 ; 2 byter
        AND     AL,11111110B            ; check for rep
        CMP     AL,11110010B            ; perhaps?
        JNZ     Step                    ; can't do anything special, step
        MOV     AL,ES:[DI+1]            ; next instruction
        AND     AL,11111110B            ; ignore w bit
        CMP     AL,10100100B            ; MOVS
        JZ      ZTrace2                 ; two byte
        CMP     AL,10100110B            ; CMPS
        JZ      ZTrace2                 ; two byte
        CMP     AL,10101110B            ; SCAS
        JZ      ZTrace2                 ; two byte
        CMP     AL,10101100B            ; LODS
        JZ      ZTrace2                 ; two byte
        CMP     AL,10101010B            ; STOS
        JZ      ZTrace2                 ; two byte
        JMP     Step                    ; bogus, do single step

ZTraceModRM:
        MOV     AL,ES:[DI+1]            ; get next byte
        AND     AL,11111000B            ; get mod and type
        CMP     AL,01010000B            ; indirect intra 8 bit offset?
        JZ      ZTrace3                 ; yes, three byte whammy
        CMP     AL,01011000B            ; indirect inter 8 bit offset
        JZ      ZTrace3                 ; yes, three byte guy
        CMP     AL,10010000B            ; indirect intra 16 bit offset?
        JZ      ZTrace4                 ; four byte offset
        CMP     AL,10011000B            ; indirect inter 16 bit offset?
        JZ      ZTrace4                 ; four bytes
        JMP     Step                    ; can't figger out what this is!
ZTrace5:INC     DX
ZTrace4:INC     DX
ZTrace3:INC     DX
ZTrace2:INC     DX
ZTrace1:INC     DX
        ADD     DI,DX                   ; offset to breakpoint instruction
        MOV     WORD PTR [BPTab],DI     ; save offset
        MOV     WORD PTR [BPTab+2],ES   ; save segment
        MOV     AL,ES:[DI]              ; get next opcode byte
        MOV     BYTE PTR [BPTab+4],AL   ; save it
        MOV     BYTE PTR ES:[DI],0CCh   ; break point it
        MOV     [BrkCnt],1              ; only this breakpoint
        JMP     DExit                   ; start the operation!
        ENDIF

; Trace 1 instruction or the number of instruction specified
; by the parameter using 8086 trace mode. Registers are all
; set according to values in save area

TRACE:
        CALL    SETADD
        CALL    SCANP
        CALL    HEXIN
        MOV     DX,1
        JC      STOCNT
        MOV     CX,4
        CALL    GETHEX
STOCNT:
        MOV     [TCOUNT],DX
        CALL    GETEOL
STEP:
        MOV     [BRKCNT],0
        OR      BYTE PTR [FSAVE+1],1
DEXIT:
IF  NOT SYSVER
        MOV     BX,[USER_PROC_PDB]
        MOV     AH,SET_CURRENT_PDB
        INT     21H
ENDIF
        PUSH    DS
        XOR     AX,AX
        MOV     DS,AX
        MOV     WORD PTR DS:[12],OFFSET DG:BREAKFIX ; Set vector 3--breakpoint instruction
        MOV     WORD PTR DS:[14],CS
        MOV     WORD PTR DS:[4],OFFSET DG:REENTER   ; Set vector 1--Single step
        MOV     WORD PTR DS:[6],CS
        CLI

        IF      SETCNTC
        MOV     WORD PTR DS:[8CH],OFFSET DG:CONTC   ; Set vector 23H (CTRL-C)
        MOV     WORD PTR DS:[8EH],CS
        ENDIF

        POP     DS
        MOV     SP,OFFSET DG:STACK
        POP     AX
        POP     BX
        POP     CX
        POP     DX
        POP     BP
        POP     BP
        POP     SI
        POP     DI
        POP     ES
        POP     ES
        POP     SS
        MOV     SP,[SPSAVE]
        PUSH    [FSAVE]
        PUSH    [CSSAVE]
        PUSH    [IPSAVE]
        MOV     DS,[DSSAVE]
        IRET
STEP1:
        CALL    CRLF
        CALL    DISPREG
        JMP     SHORT STEP

; Re-entry point from CTRL-C. Top of stack has address in 86-DOS for
; continuing, so we must pop that off.

CONTC:
        ADD     SP,6
        JMP     SHORT ReEnterReal

; Re-entry point from breakpoint. Need to decrement instruction
; pointer so it points to location where breakpoint actually
; occured.

BREAKFIX:
        PUSH    BP
        MOV     BP,SP
        DEC     WORD PTR [BP].OldIP
        POP     BP
        JMP     ReenterReal

; Re-entry point from trace mode or interrupt during
; execution. All registers are saved so they can be
; displayed or modified.

Interrupt_Frame STRUC
OldBP   DW  ?
OldIP   DW  ?
OldCS   DW  ?
OldF    DW  ?
OlderIP DW  ?
OlderCS DW  ?
OlderF  DW  ?
Interrupt_Frame ENDS

REENTER:
        PUSH    BP
        MOV     BP,SP                   ; get a frame to address from
        PUSH    AX
        MOV     AX,CS
        CMP     AX,[BP].OldCS           ; Did we interrupt ourselves?
        JNZ     GoReEnter               ; no, go reenter
        MOV     AX,[BP].OldIP
        CMP     AX,OFFSET DG:NMIInt     ; interrupt below NMI interrupt?
        JB      GoReEnter               ; yes, go reenter
        CMP     [BP].OLDIP,OFFSET DG:NMIIntEnd
        JAE     GoReEnter               ; interrupt above NMI interrupt?
        POP     AX                      ; restore state
        POP     BP
        SUB     SP,6                    ; switch TRACE and NMI stack frames
        PUSH    BP
        MOV     BP,SP                   ; set up frame
        PUSH    AX                      ; get temp variable
        MOV     AX,[BP].OlderIP         ; get NMI Vector
        MOV     [BP].OldIP,AX           ; stuff in new NMI vector
        MOV     AX,[BP].OlderCS         ; get NMI Vector
        MOV     [BP].OldCS,AX           ; stuff in new NMI vector
        MOV     AX,[BP].OlderF          ; get NMI Vector
        AND     AH,0FEh                 ; turn off Trace if present
        MOV     [BP].OldF,AX            ; stuff in new NMI vector
        MOV     [BP].OlderF,AX
        MOV     [BP].OlderIP,OFFSET DG:ReEnter  ; offset of routine
        MOV     [BP].OlderCS,CS         ; and CS
        POP     AX
        POP     BP
        IRET                            ; go try again
GoReEnter:
        POP     AX
        POP     BP
ReEnterReal:
        MOV     CS:[SPSAVE+SEGDIF],SP
        MOV     CS:[SSSAVE+SEGDIF],SS
        MOV     CS:[FSAVE],CS
        MOV     SS,CS:[FSAVE]
        MOV     SP,OFFSET DG:RSTACK
        PUSH    ES
        PUSH    DS
        PUSH    DI
        PUSH    SI
        PUSH    BP
        DEC     SP
        DEC     SP
        PUSH    DX
        PUSH    CX
        PUSH    BX
        PUSH    AX
        PUSH    SS
        POP     DS
        MOV     SS,[SSSAVE]
        MOV     SP,[SPSAVE]
        POP     [IPSAVE]
        POP     [CSSAVE]
        POP     AX
        AND     AH,0FEH                 ; turn off trace mode bit
        MOV     [FSAVE],AX
        MOV     [SPSAVE],SP
        PUSH    DS
        POP     ES
        PUSH    DS
        POP     SS
        MOV     SP,OFFSET DG:STACK
        PUSH    DS
        XOR     AX,AX
        MOV     DS,AX

        IF      SETCNTC
        MOV     WORD PTR DS:[8CH],OFFSET DG:DABORT  ; Set Ctrl-C vector
        MOV     WORD PTR DS:[8EH],CS
        ENDIF

        POP     DS
        STI
        CLD
IF  NOT SYSVER
        MOV     AH,GET_CURRENT_PDB
        INT     21H
        MOV     [USER_PROC_PDB],BX
        MOV     BX,DS
        MOV     AH,SET_CURRENT_PDB
        INT     21H
ENDIF
        DEC     [TCOUNT]
        JZ      CheckDisp
        JMP     Step1
CheckDisp:
        MOV     SI,OFFSET DG:BPTAB
        MOV     CX,[BRKCNT]
        JCXZ    SHOREG
        PUSH    ES
CLEARBP:
        LES     DI,DWORD PTR [SI]
        ADD     SI,4
        MOVSB
        LOOP    CLEARBP
        POP     ES
SHOREG:
        CALL    CRLF
        CALL    DISPREG
        JMP     COMMAND

SETADD:
        MOV     BP,[CSSAVE]
        CALL    SCANP
        CMP     BYTE PTR [SI],"="
        JNZ     RET$5
        INC     SI
        CALL    ADDRESS
        MOV     [CSSAVE],AX
        MOV     [IPSAVE],DX
RET$5:  RET

; Jump to program, setting up registers according to the
; save area. up to 10 breakpoint addresses may be specified.

GO:
        CALL    SETADD
        XOR     BX,BX
        MOV     DI,OFFSET DG:BPTAB
GO1:
        CALL    SCANP
        JZ      DEXEC
        MOV     BP,[CSSAVE]
        CALL    ADDRESS
        MOV     [DI],DX                 ; Save offset
        MOV     [DI+2],AX               ; Save segment
        ADD     DI,5                    ; Leave a little room
        INC     BX
        CMP     BX,1+BPMAX
        JNZ     GO1
        MOV     AX,5000H+"B"            ; BP ERROR
        JMP     ERR
DEXEC:
        MOV     [BRKCNT],BX
        MOV     CX,BX
        JCXZ    NOBP
        MOV     DI,OFFSET DG:BPTAB
        PUSH    DS
SETBP:
        LDS     SI,ES:DWORD PTR [DI]
        ADD     DI,4
        MOVSB
        MOV     BYTE PTR [SI-1],0CCH
        LOOP    SETBP
        POP     DS
NOBP:
        MOV     [TCOUNT],1
        JMP     DEXIT

SKIP_FILE:
        MOV     AH,CHAR_OPER
        INT     21H
        MOV     [SWITCHAR],DL           ; GET THE CURRENT SWITCH CHARACTER
FIND_DELIM:
        LODSB
        CALL    DELIM1
        JZ      GOTDELIM
        CALL    DELIM2
        JNZ     FIND_DELIM
GOTDELIM:
        DEC     SI
        RET

PREPNAME:
        MOV     ES,DSSAVE
        PUSH    SI
        MOV     DI,81H
COMTAIL:
        LODSB
        STOSB
        CMP     AL,13
        JNZ     COMTAIL
        SUB     DI,82H
        XCHG    AX,DI
        MOV     ES:(BYTE PTR [80H]),AL
        POP     SI
        MOV     DI,FCB
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
        INT     21H
        MOV     BYTE PTR [AXSAVE],AL    ; Indicate analysis of first parm
        CALL    SKIP_FILE
        MOV     DI,6CH
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
        INT     21H
        MOV     BYTE PTR [AXSAVE+1],AL  ; Indicate analysis of second parm
RET23:  RET


;  OPENS A XENIX PATHNAME SPECIFIED IN THE UNFORMATTED PARAMETERS
;  VARIABLE [XNXCMD] SPECIFIES WHICH COMMAND TO OPEN IT WITH
;
;  VARIABLE [HANDLE] CONTAINS THE HANDLE
;  VARIABLE [EXTPTR] POINTS TO THE FILES EXTENSION

DELETE_A_FILE:
        MOV     BYTE PTR [XNXCMD],UNLINK
        JMP     SHORT OC_FILE

PARSE_A_FILE:
        MOV     BYTE PTR [XNXCMD],0
        JMP     SHORT OC_FILE

EXEC_A_FILE:
        MOV     BYTE PTR [XNXCMD],EXEC
        MOV     BYTE PTR [XNXOPT],1
        JMP     SHORT OC_FILE

OPEN_A_FILE:
        MOV     BYTE PTR [XNXCMD],OPEN
        MOV     BYTE PTR [XNXOPT],2     ; Try read write
        CALL    OC_FILE
        JNC     RET23
        MOV     BYTE PTR [XNXCMD],OPEN
        MOV     BYTE PTR [XNXOPT],0     ; Try read only
        JMP     SHORT OC_FILE

CREATE_A_FILE:
        MOV     BYTE PTR [XNXCMD],CREAT

OC_FILE:
        PUSH    DS
        PUSH    ES
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        XOR     AX,AX
        MOV     [EXTPTR],AX             ; INITIALIZE POINTER TO EXTENSIONS
        MOV     AH,CHAR_OPER
        INT     21H
        MOV     [SWITCHAR],DL           ; GET THE CURRENT SWITCH CHARACTER

        MOV     SI,81H

OPEN1:  CALL    GETCHRUP
        CALL    DELIM2                  ; END OF LINE?
        JZ      OPEN4
        CALL    DELIM1                  ; SKIP LEADING DELIMITERS
        JZ      OPEN1

        MOV     DX,SI                   ; SAVE POINTER TO BEGINNING
        DEC     DX
OPEN2:  CMP     AL,"."                  ; LAST CHAR A "."?
        JNZ     OPEN3
        MOV     [EXTPTR],SI             ; SAVE POINTER TO THE EXTENSION
OPEN3:  CALL    GETCHRUP
        CALL    DELIM1                  ; LOOK FOR END OF PATHNAME
        JZ      OPEN4
        CALL    DELIM2
        JNZ     OPEN2

OPEN4:  DEC     SI                      ; POINT BACK TO LAST CHAR
        PUSH    [SI]                    ; SAVE TERMINATION CHAR
        MOV     BYTE PTR [SI],0         ; NULL TERMINATE THE STRING

        MOV     AL,[XNXOPT]
        MOV     AH,[XNXCMD]             ; OPEN OR CREATE FILE
        OR      AH,AH
        JZ      OPNRET
        MOV     BX,OFFSET DG:EXEC_BLOCK
        XOR     CX,CX
        INT     21H
        MOV     CS:[HANDLE],AX          ; SAVE ERROR CODE OR HANDLE

OPNRET: POP     [SI]

        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        POP     ES
        POP     DS
        RET

GETCHRUP:
        LODSB
        CMP     AL,"a"
        JB      GCUR
        CMP     AL,"z"
        JA      GCUR
        SUB     AL,32
        MOV     [SI-1],AL
GCUR:   RET

DELIM0: CMP     AL,"["
        JZ      LIMRET
DELIM1: CMP     AL," "                  ; SKIP THESE GUYS
        JZ      LIMRET
        CMP     AL,";"
        JZ      LIMRET
        CMP     AL,"="
        JZ      LIMRET
        CMP     AL,9
        JZ      LIMRET
        CMP     AL,","
        JMP     SHORT LIMRET

DELIM2: CMP     AL,[SWITCHAR]           ; STOP ON THESE GUYS
        JZ      LIMRET
        CMP     AL,13
LIMRET: RET

NAME:
        CALL    PREPNAME
        MOV     AL,BYTE PTR AXSAVE
        MOV     PARSERR,AL
        PUSH    ES
        POP     DS
        PUSH    CS
        POP     ES
        MOV     SI,FCB                  ; DS:SI points to user FCB
        MOV     DI,SI                   ; ES:DI points to DEBUG FCB
        MOV     CX,82
        REP     MOVSW
RET6:   RET

BADNAM:
        MOV     DX,OFFSET DG:NAMBAD
        JMP     RESTART

IFHEX:
        CMP     BYTE PTR [PARSERR],-1   ; Invalid drive specification?
        JZ      BADNAM
        CALL    PARSE_A_FILE
        MOV     BX,[EXTPTR]
        CMP     WORD PTR DS:[BX],"EH"   ; "HE"
        JNZ     RET6
        CMP     BYTE PTR DS:[BX+2],"X"
        RET

IFEXE:
        PUSH    BX
        MOV     BX,[EXTPTR]
        CMP     WORD PTR DS:[BX],"XE"   ; "EX"
        JNZ     RETIF
        CMP     BYTE PTR DS:[BX+2],"E"
RETIF:  POP     BX
        RET

LOAD:
        MOV     BYTE PTR [RDFLG],READ
        JMP     SHORT DSKIO

DWRITE:
        MOV     BYTE PTR [RDFLG],WRITE
DSKIO:
        MOV     BP,[CSSAVE]
        CALL    SCANB
        JNZ     PRIMIO
        JMP     DEFIO
PRIMIO: CALL    ADDRESS
        CALL    SCANB
        JNZ     PRMIO
        JMP     FILEIO
PRMIO:  PUSH    AX                      ; Save segment
        MOV     BX,DX                   ; Put displacement in proper register
        MOV     CX,1
        CALL    GETHEX                  ; Drive number must be 1 digit
        PUSH    DX
        MOV     CX,4
        CALL    GETHEX                  ; Logical record number
        PUSH    DX
        MOV     CX,3
        CALL    GETHEX                  ; Number of records
        CALL    GETEOL
        MOV     CX,DX
        POP     DX                      ; Logical record number
        POP     AX                      ; Drive number
        CBW                             ; Turn off verify after write
        MOV     BYTE PTR DRVLET,AL      ; Save drive in case of error
        PUSH    AX
        PUSH    BX
        PUSH    DX
        MOV     DL,AL
        INC     DL
        MOV     AH,GET_DPB
        INT     21H
        POP     DX
        POP     BX
        OR      AL,AL
        POP     AX
        POP     DS                      ; Segment of transfer
        JNZ     DRVERRJ
        CMP     CS:BYTE PTR [RDFLG],WRITE
        JZ      ABSWRT
        INT     25H                     ; Primitive disk read
        JMP     SHORT ENDABS

ABSWRT:
        INT     26H                     ; Primitive disk write
ENDABS:
        JNC     RET0
DRVERRJ: JMP    DRVERR

RET0:
        POPF
        RET

DEFIO:
        MOV     AX,[CSSAVE]             ; Default segment
        MOV     DX,100H                 ; Default file I/O offset
        CALL    IFHEX
        JNZ     EXECHK
        XOR     DX,DX                   ; If HEX file, default OFFSET is zero
HEX2BINJ:JMP    HEX2BIN

FILEIO:
; AX and DX have segment and offset of transfer, respectively
        CALL    IFHEX
        JZ      HEX2BINJ
EXECHK:
        CALL    IFEXE
        JNZ     BINFIL
        CMP     BYTE PTR [RDFLG],READ
        JZ      EXELJ
        MOV     DX,OFFSET DG:EXEWRT
        JMP     RESTART                 ; Can't write .EXE files

BINFIL:
        CMP     BYTE PTR [RDFLG],WRITE
        JZ      BINLOAD
        CMP     WORD PTR DS:[BX],4F00H + "C"    ; "CO"
        JNZ     BINLOAD
        CMP     BYTE PTR DS:[BX+2],"M"
        JNZ     BINLOAD
EXELJ:
        DEC     SI
        CMP     DX,100H
        JNZ     PRER
        CMP     AX,[CSSAVE]
        JZ      OAF
PRER:   JMP     PERROR
OAF:    CALL    OPEN_A_FILE
        JNC     GDOPEN
        MOV     AX,exec_file_not_found
        JMP     EXECERR

GDOPEN: XOR     DX,DX
        XOR     CX,CX
        MOV     BX,[HANDLE]
        MOV     AL,2
        MOV     AH,LSEEK
        INT     21H
        CALL    IFEXE                   ; SUBTRACT 512 BYTES FOR EXE
        JNZ     BIN2                    ; FILE LENGTH BECAUSE OF
        SUB     AX,512                  ; THE HEADER
BIN2:   MOV     [BXSAVE],DX             ; SET UP FILE SIZE IN DX:AX
        MOV     [CXSAVE],AX
        MOV     AH,CLOSE
        INT     21H
        JMP     EXELOAD

NO_MEM_ERR:
        MOV     DX,OFFSET DG:TOOBIG
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
        JMP     COMMAND

WRTFILEJ: JMP   WRTFILE
NOFILEJ: JMP    NOFILE

BINLOAD:
        PUSH    AX
        PUSH    DX
        CMP     BYTE PTR [RDFLG],WRITE
        JZ      WRTFILEJ
        CALL    OPEN_A_FILE
        JC      NOFILEJ
        MOV     BX,[HANDLE]
        MOV     AX,(LSEEK SHL 8) OR 2
        XOR     DX,DX
        MOV     CX,DX
        INT     21H                     ; GET SIZE OF FILE
        MOV     SI,DX
        MOV     DI,AX                   ; SIZE TO SI:DI
        MOV     AX,(LSEEK SHL 8) OR 0
        XOR     DX,DX
        MOV     CX,DX
        INT     21H                     ; RESET POINTER BACK TO BEGINNING
        POP     AX
        POP     BX
        PUSH    BX
        PUSH    AX                      ; TRANS ADDR TO BX:AX
        ADD     AX,15
        MOV     CL,4
        SHR     AX,CL
        ADD     BX,AX                   ; Start of transfer rounded up to seg
        MOV     DX,SI
        MOV     AX,DI                   ; DX:AX is size
        MOV     CX,16
        DIV     CX
        OR      DX,DX
        JZ      NOREM
        INC     AX
NOREM:                                  ; AX is number of paras in transfer
        ADD     AX,BX                   ; AX is first seg that need not exist
        CMP     AX,CS:[PDB_block_len]
        JA      NO_MEM_ERR
        MOV     CXSAVE,DI
        MOV     BXSAVE,SI
        POP     DX
        POP     AX

RDWR:
; AX:DX is disk transfer address (segment:offset)
; SI:DI is length (32-bit number)

RDWRLOOP:
        MOV     BX,DX                   ; Make a copy of the offset
        AND     DX,000FH                ; Establish the offset in 0H-FH range
        MOV     CL,4
        SHR     BX,CL                   ; Shift offset and
        ADD     AX,BX                   ; Add to segment register to get new Seg:offset
        PUSH    AX
        PUSH    DX                      ; Save AX,DX register pair
        MOV     WORD PTR [TRANSADD],DX
        MOV     WORD PTR [TRANSADD+2],AX
        MOV     CX,0FFF0H               ; Keep request in segment
        OR      SI,SI                   ; Need > 64K?
        JNZ     BIGRDWR
        MOV     CX,DI                   ; Limit to amount requested
BIGRDWR:
        PUSH    DS
        PUSH    BX
        MOV     BX,[HANDLE]
        MOV     AH,[RDFLG]
        LDS     DX,[TRANSADD]
        INT     21H                     ; Perform read or write
        POP     BX
        POP     DS
        JC      BADWR
        CMP     BYTE PTR [RDFLG],WRITE
        JNZ     GOODR
        CMP     CX,AX
        JZ      GOODR
BADWR:  MOV     CX,AX
        STC
        POP     DX                      ; READ OR WRITE BOMBED OUT
        POP     AX
        RET

GOODR:
        MOV     CX,AX
        SUB     DI,CX                   ; Request minus amount transferred
        SBB     SI,0                    ; Ripple carry
        OR      CX,CX                   ; End-of-file?
        POP     DX                      ; Restore DMA address
        POP     AX
        JZ      RET8
        ADD     DX,CX                   ; Bump DMA address by transfer length
        MOV     BX,SI
        OR      BX,DI                   ; Finished with request
        JNZ     RDWRLOOP
RET8:   CLC                             ; End-of-file not reached
        RET

NOFILE:
        MOV     DX,OFFSET DG:NOTFND
RESTARTJMP:
        JMP     RESTART

WRTFILE:
        CALL    CREATE_A_FILE           ; Create file we want to write to
        MOV     DX,OFFSET DG:NOROOM     ; Creation error - report error
        JC      RESTARTJMP
        MOV     SI,BXSAVE               ; Get high order number of bytes to transfer
        CMP     SI,000FH
        JLE     WRTSIZE                 ; Is bx less than or equal to FH
        XOR     SI,SI                   ; Ignore BX if greater than FH - set to zero
WRTSIZE:
        MOV     DX,OFFSET DG:WRTMES1    ; Print number bytes we are writing
        CALL    RPRBUF
        OR      SI,SI
        JZ      NXTBYT
        MOV     AX,SI
        CALL    DIGIT
NXTBYT:
        MOV     DX,CXSAVE
        MOV     DI,DX
        CALL    OUT16                   ; Amount to write is SI:DI
        MOV     DX,OFFSET DG:WRTMES2
        CALL    RPRBUF
        POP     DX
        POP     AX
        CALL    RDWR
        JNC     CLSFLE
        CALL    CLSFLE
        CALL    DELETE_A_FILE
        MOV     DX,OFFSET DG:NOSPACE
        JMP     RESTARTJMP
        CALL    CLSFLE
        JMP     COMMAND

CLSFLE:
        MOV     AH,CLOSE
        MOV     BX,[HANDLE]
        INT     21H
        RET

EXELOAD:
        POP     [RETSAVE]               ; Suck up return addr
        INC     BYTE PTR [NEWEXEC]
        MOV     BX,[USER_PROC_PDB]
        MOV     AX,DS
        CMP     AX,BX
        JZ      DEBUG_CURRENT
        JMP     FIND_DEBUG

DEBUG_CURRENT:
        MOV     AX,[DSSAVE]
DEBUG_FOUND:
        MOV     BYTE PTR [NEWEXEC],0
        MOV     [HEADSAVE],AX
        PUSH    [RETSAVE]               ; Get the return address back
        PUSH    AX
        MOV     BX,CS
        SUB     AX,BX
        PUSH    CS
        POP     ES
        MOV     BX,AX
        ADD     BX,10H                  ; RESERVE HEADER
        MOV     AH,SETBLOCK
        INT     21H
        POP     AX
        MOV     WORD PTR [COM_LINE+2],AX
        MOV     WORD PTR [COM_FCB1+2],AX
        MOV     WORD PTR [COM_FCB2+2],AX

        CALL    EXEC_A_FILE
        JC      EXECERR
        CALL    SET_TERMINATE_VECTOR    ; Reset int 22
        MOV     AH,GET_CURRENT_PDB
        INT     21H
        MOV     [USER_PROC_PDB],BX
        MOV     [DSSAVE],BX
        MOV     [ESSAVE],BX
        MOV     ES,BX
        MOV     WORD PTR ES:[PDB_exit],OFFSET DG:TERMINATE
        MOV     WORD PTR ES:[PDB_exit+2],DS
        LES     DI,[COM_CSIP]
        MOV     [CSSAVE],ES
        MOV     [IPSAVE],DI
        MOV     WORD PTR [DISADD+2],ES
        MOV     WORD PTR [DISADD],DI
        MOV     WORD PTR [ASMADD+2],ES
        MOV     WORD PTR [ASMADD],DI
        MOV     WORD PTR [DEFDUMP+2],ES
        MOV     WORD PTR [DEFDUMP],DI
        MOV     BX,DS
        MOV     AH,SET_CURRENT_PDB
        INT     21H
        LES     DI,[COM_SSSP]
        MOV     AX,ES:[DI]
        INC     DI
        INC     DI
        MOV     [AXSAVE],AX
        MOV     [SSSAVE],ES
        MOV     [SPSAVE],DI
        RET

EXECERR:
        MOV     DX,OFFSET DG:NOTFND
        CMP     AX,exec_file_not_found
        JZ      GOTEXECEMES
        MOV     DX,OFFSET DG:ACCMES
        CMP     AX,error_access_denied
        JZ      GOTEXECEMES
        MOV     DX,OFFSET DG:TOOBIG
        CMP     AX,exec_not_enough_memory
        JZ      GOTEXECEMES
        MOV     DX,OFFSET DG:EXEBAD
        CMP     AX,exec_bad_format
        JZ      GOTEXECEMES
        MOV     DX,OFFSET DG:EXECEMES
GOTEXECEMES:
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
        JMP     COMMAND

HEX2BIN:
        MOV     [INDEX],DX
        MOV     DX,OFFSET DG:HEXWRT
        CMP     BYTE PTR [RDFLG],WRITE
        JNZ     RDHEX
        JMP     RESTARTJ2
RDHEX:
        MOV     ES,AX
        CALL    OPEN_A_FILE
        MOV     DX,OFFSET DG:NOTFND
        JNC     HEXFND
        JMP     RESTART
HEXFND:
        XOR     BP,BP
        MOV     SI,OFFSET DG:(BUFFER+BUFSIZ)    ; Flag input buffer as empty
READHEX:
        CALL    GETCH
        CMP     AL,":"                  ; Search for : to start line
        JNZ     READHEX
        CALL    GETBYT                  ; Get byte count
        MOV     CL,AL
        MOV     CH,0
        JCXZ    HEXDONE
        CALL    GETBYT                  ; Get high byte of load address
        MOV     BH,AL
        CALL    GETBYT                  ; Get low byte of load address
        MOV     BL,AL
        ADD     BX,[INDEX]              ; Add in offset
        MOV     DI,BX
        CALL    GETBYT                  ; Throw away type byte
READLN:
        CALL    GETBYT                  ; Get data byte
        STOSB
        CMP     DI,BP                   ; Check if this is the largest address so far
        JBE     HAVBIG
        MOV     BP,DI                   ; Save new largest
HAVBIG:
        LOOP    READLN
        JMP     SHORT READHEX

GETCH:
        CMP     SI,OFFSET DG:(BUFFER+BUFSIZ)
        JNZ     NOREAD
        MOV     DX,OFFSET DG:BUFFER
        MOV     SI,DX
        MOV     AH,READ
        PUSH    BX
        PUSH    CX
        MOV     CX,BUFSIZ
        MOV     BX,[HANDLE]
        INT     21H
        POP     CX
        POP     BX
        OR      AX,AX
        JZ      HEXDONE
NOREAD:
        LODSB
        CMP     AL,1AH
        JZ      HEXDONE
        OR      AL,AL
        JNZ     RET7
HEXDONE:
        MOV     [CXSAVE],BP
        MOV     BXSAVE,0
        RET

HEXDIG:
        CALL    GETCH
        CALL    HEXCHK
        JNC     RET7
        MOV     DX,OFFSET DG:HEXERR
RESTARTJ2:
        JMP     RESTART

GETBYT:
        CALL    HEXDIG
        MOV     BL,AL
        CALL    HEXDIG
        SHL     BL,1
        SHL     BL,1
        SHL     BL,1
        SHL     BL,1
        OR      AL,BL
RET7:   RET


CODE    ENDS
        END     DEBCOM2
