TITLE   DEBASM

; Code for the ASSEMble command in the debugger

.xlist
.xcref
        INCLUDE DEBEQU.ASM
        INCLUDE DOSSYM.ASM
.cref
.list


CODE    SEGMENT PUBLIC BYTE 'CODE'
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE

        EXTRN   DBMN:BYTE,CSSAVE:WORD,REG8:BYTE,REG16:BYTE,SIZ8:BYTE
        EXTRN   SYNERR:BYTE,OPTAB:BYTE,MAXOP:ABS

CONST   ENDS

DATA    SEGMENT PUBLIC BYTE

        EXTRN   HINUM:WORD,LOWNUM:WORD,ASSEM_CNT:BYTE
        EXTRN   ASSEM1:BYTE,ASSEM2:BYTE,ASSEM3:BYTE,ASSEM4:BYTE,ASSEM5:BYTE
        EXTRN   ASSEM6:BYTE,OPBUF:BYTE,OPCODE:WORD,REGMEM:BYTE,INDEX:WORD
        EXTRN   ASMADD:BYTE,ASMSP:WORD,MOVFLG:BYTE,SEGFLG:BYTE,TSTFLG:BYTE
        EXTRN   NUMFLG:BYTE,DIRFLG:BYTE,BYTEBUF:BYTE,F8087:BYTE,DIFLG:BYTE
        EXTRN   SIFLG:BYTE,BXFLG:BYTE,BPFLG:BYTE,NEGFLG:BYTE,MEMFLG:BYTE
        EXTRN   REGFLG:BYTE,AWORD:BYTE,MIDFLD:BYTE,MODE:BYTE

DATA    ENDS

DG      GROUP   CODE,CONST,DATA


CODE    SEGMENT PUBLIC BYTE 'CODE'
ASSUME  CS:DG,DS:DG,ES:DG,SS:DG

        PUBLIC  ASSEM
        PUBLIC  DB_OPER,DW_OPER,ASSEMLOOP,GROUP2,AA_OPER,DCINC_OPER
        PUBLIC  GROUP1,ESC_OPER,FGROUPP,FGROUPX,FDE_OPER,FGROUPZ
        PUBLIC  FD9_OPER,FGROUP,FDB_OPER,FGROUPB,FGROUP3,FGROUP3W
        PUBLIC  FGROUPDS,INT_OPER,IN_OPER,DISP8_OPER,JMP_OPER,NO_OPER
        PUBLIC  OUT_OPER,L_OPER,MOV_OPER,POP_OPER,PUSH_OPER,ROTOP
        PUBLIC  TST_OPER,EX_OPER,GET_DATA16,CALL_OPER

        EXTRN   INBUF:NEAR,SCANB:NEAR,SCANP:NEAR,GETHX:NEAR,GET_ADDRESS:NEAR
        EXTRN   DEFAULT:NEAR,OUTDI:NEAR,BLANK:NEAR,PRINTMES:NEAR,TAB:NEAR

;
;       Line by line assembler
;

ASSEM:
        MOV     BP,[CSSAVE]             ; Default code segment
        MOV     DI,OFFSET DG:ASMADD     ; Default address
        CALL    DEFAULT
        MOV     WORD PTR [ASMADD],DX    ; Displacement of disassembly
        MOV     WORD PTR [ASMADD+2],AX  ; Segment
        MOV     [ASMSP],SP              ; Save sp in case of error

ASSEMLOOP:
        MOV     SP,[ASMSP]              ; Restore sp in case of error
        LES     DI,DWORD PTR ASMADD     ; GET PC
        CALL    OUTDI                   ; OUTPUT ADDRESS
        CALL    BLANK                   ; SKIP A SPACE
        PUSH    CS
        POP     ES
        CALL    INBUF                   ; GET A BUFFER
        CALL    SCANB
        JNZ     OPLOOK
        RET                             ; IF EMPTY JUST RETURN
;
;  At this point ds:si points to the opcode mnemonic...
;
OPLOOK: XOR     CX,CX                   ; OP-CODE COUNT = 0
        MOV     DI,OFFSET DG:DBMN
OPSCAN: XOR     BX,BX
OPLOOP: MOV     AL,[DI+BX]
        AND     AL,7FH
        CMP     AL,[SI+BX]
        JZ      OPMATCH
        INC     CX                      ; INCREMENT OP-CODE COUNT
        CMP     CX,MAXOP                ; CHECK FOR END OF LIST
        JB      OP1
        JMP     ASMERR
OP1:    INC     DI                      ; SCAN FOR NEXT OP-CODE...
        TEST    BYTE PTR [DI-1],80H
        JZ      OP1
        JMP     OPSCAN

OPMATCH:INC     BX                      ; COMPARE NEXT CHAR
        TEST    BYTE PTR [DI+BX-1],80H  ; ARE WE DONE?
        JZ      OPLOOP                  ; ..IF NOT KEEP COMPARING
        XCHG    BX,CX
        MOV     AX,BX
        SHL     AX,1
        ADD     AX,BX
        ADD     AX,OFFSET DG:OPTAB
        MOV     BX,AX
;
; CX = COUNT OF CHARS IN OPCODE
; BX = POINTER INTO OPCODE TABLE
;
        XOR     AX,AX
        MOV     BYTE PTR [AWORD],AL
        MOV     WORD PTR [MOVFLG],AX    ; MOVFLG + TSTFLG
        MOV     BYTE PTR [SEGFLG],AL    ; ZERO SEGMENT REGISTER FLAG
        MOV     AH,00001010B            ; SET UP FOR AA_OPER
        MOV     AL,BYTE PTR [BX]
        MOV     WORD PTR [ASSEM1],AX
        MOV     BYTE PTR [ASSEM_CNT],1

        ADD     SI,CX                   ; SI POINTS TO OPERAND
        JMP     WORD PTR [BX+1]
;
; 8087 INSTRUCTIONS WITH NO OPERANDS
;
FDE_OPER:
        MOV     AH,0DEH
        JMP     SHORT FDX_OPER
FDB_OPER:
        MOV     AH,0DBH
        JMP     SHORT FDX_OPER
FD9_OPER:
        MOV     AH,0D9H
FDX_OPER:
        XCHG    AL,AH
        MOV     WORD PTR [ASSEM1],AX
;
;  aad and aam instrucions
;
AA_OPER:INC     BYTE PTR [ASSEM_CNT]
;
;  instructions with no operands
;
NO_OPER:
        CALL    STUFF_BYTES
        CALL    SCANP
        PUSH    CS
        POP     ES
        JNZ     OPLOOK
        JMP     ASSEMLOOP
;
;  push instruction
;
PUSH_OPER:
        MOV     AH,11111111B
        JMP     SHORT POP1
;
;  pop instruction
;
POP_OPER:
        MOV     AH,10001111B
POP1:   MOV     [ASSEM1],AH
        MOV     [MIDFLD],AL
        INC     BYTE PTR [MOVFLG]       ; ALLOW SEGMENT REGISTERS
        MOV     BYTE PTR [AWORD],2      ; MUST BE 16 BITS
        CALL    GETREGMEM
        CALL    BUILDIT
        MOV     AL,[DI+2]
        CMP     AL,11000000B
        JB      DATRET
        MOV     BYTE PTR [DI],1
        CMP     BYTE PTR [MOVFLG],2
        JNZ     POP2
        AND     AL,00011000B
        OR      AL,00000110B
        CMP     BYTE PTR [MIDFLD],0
        JNZ     POP3
        OR      AL,00000001B
        JMP     SHORT POP3

POP2:   AND     AL,111B
        OR      AL,01010000B
        CMP     BYTE PTR [MIDFLD],0
        JNZ     POP3
        OR      AL,01011000B
POP3:   MOV     BYTE PTR [DI+1],AL
        JMP     ASSEM_EXIT
;
; ret and retf instructions
;
GET_DATA16:
        CALL    SCANB
        MOV     CX,4
        CALL    GETHX
        JC      DATRET
        DEC     BYTE PTR [ASSEM1]       ; CHANGE OP-CODE
        ADD     BYTE PTR [ASSEM_CNT],2  ; UPDATE LENGTH
        MOV     WORD PTR [ASSEM2],DX    ; SAVE OFFSET
DATRET: JMP     ASSEM_EXIT
;
;  int instruction
;
INT_OPER:
        CALL    SCANB
        MOV     CX,2
        CALL    GETHX
        JC      ERRV1
        MOV     AL,DL
        CMP     AL,3
        JZ      DATRET
        INC     BYTE PTR [ASSEM1]
        JMP     DISPX
;
;  in instruction
;
IN_OPER:
        CALL    SCANB
        LODSW
        CMP     AX,"A"+4C00H            ; "AL"
        JZ      IN_1
        CMP     AX,"A"+5800H            ; "AX"
        JZ      IN_0
ERRV1:  JMP     ASMERR
IN_0:   INC     BYTE PTR [ASSEM1]
IN_1:   CALL    SCANP
        CMP     WORD PTR [SI],"D"+5800H ; "DX"
        JZ      DATRET
        MOV     CX,2
        CALL    GETHX
        JC      ERRV1
        AND     BYTE PTR [ASSEM1],11110111B
        MOV     AL,DL
        JMP     DISPX
;
;  out instruction
;
OUT_OPER:
        CALL    SCANB
        CMP     WORD PTR [SI],"D"+5800H ; "DX"
        JNZ     OUT_0
        INC     SI
        INC     SI
        JMP     SHORT OUT_1
OUT_0:  AND     BYTE PTR [ASSEM1],11110111B
        MOV     CX,2
        CALL    GETHX
        JC      ERRV1
        INC     BYTE PTR [ASSEM_CNT]
        MOV     BYTE PTR [ASSEM2],DL
OUT_1:  CALL    SCANP
        LODSW
        CMP     AX,"A"+4C00H            ; "AL"
        JZ      DATRET
        CMP     AX,"A"+5800H            ; "AX"
        JNZ     ERRV1
        INC     BYTE PTR [ASSEM1]
        JMP     DATRET

;
;  jump instruction
;
JMP_OPER:
        INC     BYTE PTR [TSTFLG]
;
;  call instruction
;
CALL_OPER:
        MOV     BYTE PTR [ASSEM1],11111111B
        MOV     BYTE PTR [MIDFLD],AL
        CALL    GETREGMEM
        CALL    BUILD3
        CMP     BYTE PTR [MEMFLG],0
        JNZ     CALLJ1
        CMP     BYTE PTR [REGMEM],-1
        JZ      CALLJ2
;
;  INDIRECT JUMPS OR CALLS
;
CALLJ1: CMP     BYTE PTR [AWORD],1
ERRZ4:  JZ      ERRV1
        CMP     BYTE PTR [AWORD],4
        JNZ     ASMEX4
        OR      BYTE PTR [DI+2],1000B
        JMP     SHORT ASMEX4
;
;   DIRECT JUMPS OR CALLS
;
CALLJ2: MOV     AX,[LOWNUM]
        MOV     DX,[HINUM]
        MOV     BL,[AWORD]
        CMP     BYTE PTR [NUMFLG],0
        JZ      ERRZ4

;  BL = NUMBER OF BYTES IN JUMP
;  DX = OFFSET
;  AX = SEGMENT

CALLJ3:
        MOV     BYTE PTR [DI],5
        MOV     [DI+2],AX
        MOV     [DI+4],DX

        MOV     AL,10011010B            ; SET UP INTER SEGMENT CALL
        CMP     BYTE PTR [TSTFLG],0
        JZ      CALLJ5
        MOV     AL,11101010B            ; FIX UP FOR JUMP
CALLJ5: MOV     BYTE PTR [DI+1],AL
        CMP     BL,4                    ; FAR SPECIFIED?
        JZ      ASMEX4
        OR      BL,BL
        JNZ     CALLJ6
        CMP     DX,WORD PTR [ASMADD+2]  ; DIFFERENT SEGMENT?
        JNZ     ASMEX4

CALLJ6: MOV     BYTE PTR [DI],3
        MOV     AL,11101000B            ; SET UP FOR INTRASEGMENT
        OR      AL,[TSTFLG]
        MOV     BYTE PTR [DI+1],AL

        MOV     AX,[LOWNUM]
        SUB     AX,WORD PTR [ASMADD]
        SUB     AX,3
        MOV     [DI+2],AX
        CMP     BYTE PTR [TSTFLG],0
        JZ      ASMEX4
        CMP     BL,2
        JZ      ASMEX4

        INC     AX
        MOV     CX,AX
        CBW
        CMP     AX,CX
        JNZ     ASMEX3
        MOV     BYTE PTR [DI+1],11101011B
        MOV     [DI+2],AX
        DEC     BYTE PTR [DI]
ASMEX4: JMP     ASSEM_EXIT
;
;  conditional jumps and loop instructions
;
DISP8_OPER:
        MOV     BP,WORD PTR [ASMADD+2]  ; GET DEFAULT DISPLACEMENT
        CALL    GET_ADDRESS
        SUB     DX,WORD PTR [ASMADD]
        DEC     DX
        DEC     DX
        CALL    CHKSIZ
        CMP     CL,1
        JNZ     ERRV2
DISPX:  INC     [ASSEM_CNT]
        MOV     BYTE PTR [ASSEM2],AL
ASMEX3: JMP     ASSEM_EXIT
;
;  lds, les, and lea instructions
;
L_OPER:
        CALL    SCANB
        LODSW
        MOV     CX,8
        MOV     DI,OFFSET DG:REG16
        CALL    CHKREG
        JZ      ERRV2                   ; CX = 0 MEANS NO REGISTER
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
        MOV     BYTE PTR [MIDFLD],AL
        CALL    SCANP
        CALL    GETREGMEM
        CMP     BYTE PTR [AWORD],0
        JNZ     ERRV2
        CALL    BUILD2
        JMP     SHORT ASEXV
;
;  dec and inc instructions
;
DCINC_OPER:
        MOV     BYTE PTR [ASSEM1],11111110B
        MOV     BYTE PTR [MIDFLD],AL
        CALL    GETREGMEM
        CALL    BUILDIT
        TEST    BYTE PTR [DI+1],1
        JZ      ASEXV
        MOV     AL,[DI+2]
        CMP     AL,11000000B
        JB      ASEXV
        AND     AL,1111B
        OR      AL,01000000B
        MOV     [DI+1],AL
        DEC     BYTE PTR [DI]
ASEXV:  JMP     ASSEM_EXIT

ERRV2:  JMP     ASMERR
;
; esc instruction
;
ESC_OPER:
        INC     BYTE PTR [AWORD]
        CALL    SCANB
        MOV     CX,2
        CALL    GETHX
        CMP     DX,64
        JAE     ERRV2
        CALL    SCANP
        MOV     AX,DX
        MOV     CL,3
        SHR     DX,CL
        OR      [ASSEM1],DL
        AND     AL,111B
        SHL     AL,CL
        JMP     GROUPE
;
; 8087 arithmetic instuctions
;

;
;  OPERANDS THAT ALLOW THE REVERSE BIT
;
FGROUPDS:
        CALL    SETMID
        CALL    GETREGMEM2
        CALL    BUILD3
        CMP     BYTE PTR [MODE],11000000B
        JNZ     FGROUP1
        MOV     AL,[DIRFLG]
        OR      AL,AL
        JZ      FEXIT
        OR      [DI+1],AL               ; IF D=1...
        XOR     BYTE PTR [DI+2],00001000B   ; ...REVERSE THE SENSE OF R
        JMP     SHORT FEXIT

;
;  Here when instruction could have memory or register operand
;
FGROUPX:
        CALL    SETMID                  ; THIS ENTRY POINT FOR 1 MEM OPER
        MOV     BYTE PTR [DIRFLG],0
        JMP     SHORT FGRP2
FGROUP:
        CALL    SETMID
FGRP2:
        CALL    GETREGMEM2
        CALL    BUILD3
        CMP     BYTE PTR [MODE],11000000B
        JNZ     FGROUP1
        MOV     AL,[DIRFLG]
        OR      [DI+1],AL
        JMP     SHORT FEXIT
FGROUP1:CALL    SETMF
FEXIT:  JMP     ASSEM_EXIT
;
; These 8087 instructions require a memory operand
;
FGROUPB:
        MOV     AH,5                    ; MUST BE TBYTE
        JMP     SHORT FGROUP3E
FGROUP3W:
        MOV     AH,2                    ; MUST BE WORD
        JMP     SHORT FGROUP3E
FGROUP3:
        MOV     AH,-1                   ; SIZE CANNOT BE SPECIFIED
FGROUP3E:
        MOV     [AWORD],AH
        CALL    SETMID
        CALL    GETREGMEM
        CMP     BYTE PTR [MODE],11000000B
        JZ      FGRPERR
FGRP:
        CALL    BUILD3
        JMP     FEXIT
;
; These 8087 instructions require a register operand
;
FGROUPP:                                ; 8087 POP OPERANDS
        MOV     BYTE PTR [AWORD],-1
        CALL    SETMID
        CALL    GETREGMEM2
        CMP     BYTE PTR [DIRFLG],0
        JNZ     FGRP
FGRPERR:JMP     ASMERR

FGROUPZ:                                ; ENTRY POINT WHERE ARG MUST BE MEM
        CALL    SETMID
        MOV     BYTE PTR [DIRFLG],0
        CALL    GETREGMEM
        CMP     BYTE PTR [MODE],11000000B
        JZ      FGRPERR
        CALL    BUILD3
        CALL    SETMF
        JMP     FEXIT
;
; not, neg, mul, imul, div, and idiv instructions
;
GROUP1:
        MOV     [ASSEM1],11110110B
GROUPE:
        MOV     BYTE PTR [MIDFLD],AL
        CALL    GETREGMEM
        CALL    BUILDIT
        JMP     FEXIT
;
;  shift and rotate instructions
;
ROTOP:
        MOV     [ASSEM1],11010000B
        MOV     BYTE PTR [MIDFLD],AL
        CALL    GETREGMEM
        CALL    BUILDIT
        CALL    SCANP
        CMP     BYTE PTR [SI],"1"
        JZ      ASMEXV1
        CMP     WORD PTR [SI],"LC"      ; CL
        JZ      ROTOP1
ROTERR: JMP     ASMERR
ROTOP1: OR      BYTE PTR [ASSEM1],10B
ASMEXV1:JMP     ASSEM_EXIT
;
;  xchg instruction
;
EX_OPER:
        INC     BYTE PTR [TSTFLG]
;
;   test instruction
;
TST_OPER:
        INC     BYTE PTR [TSTFLG]
        JMP     SHORT MOVOP
;
;    mov instruction
;
MOV_OPER:
        INC     BYTE PTR [MOVFLG]
MOVOP:  XOR     AX,AX
        JMP     SHORT GROUPM
;
;   add, adc, sub, sbb, cmp, and, or, xor instructions
;
GROUP2:
        MOV     BYTE PTR [ASSEM1],10000000B
GROUPM:
        MOV     BYTE PTR [MIDFLD],AL

        PUSH    AX
        CALL    GETREGMEM
        CALL    BUILD2
        CALL    SCANP                   ; POINT TO NEXT OPERAND
        MOV     AL,BYTE PTR [ASSEM_CNT]
        PUSH    AX
        CALL    GETREGMEM
        POP     AX
        MOV     BYTE PTR [DI],AL
        POP     AX
        MOV     BL,BYTE PTR [AWORD]
        OR      BL,BL
        JZ      ERRV5
        DEC     BL
        AND     BL,1
        OR      BYTE PTR [DI+1],BL

        CMP     BYTE PTR [MEMFLG],0
        JNZ     G21V
        CMP     BYTE PTR [NUMFLG],0     ; TEST FOR IMMEDIATE DATA
        JZ      G21V
        CMP     BYTE PTR [SEGFLG],0
        JNZ     ERRV5
        CMP     BYTE PTR [TSTFLG],2     ; XCHG?
        JNZ     IMMED1
ERRV5:  JMP     ASMERR
G21V:   JMP     GRP21
;
;  SECOND OPERAND WAS IMMEDIATE
;
IMMED1: MOV     AL,BYTE PTR [DI+2]
        CMP     BYTE PTR [MOVFLG],0
        JZ      NOTMOV1
        AND     AL,11000000B
        CMP     AL,11000000B
        JNZ     GRP23                   ; not to a register
                                        ; MOVE IMMEDIATE TO REGISTER
        MOV     AL,BYTE PTR [DI+1]
        AND     AL,1                    ; SET SIZE
        PUSHF
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
        OR      AL,BYTE PTR [DI+2]      ; SET REGISTER
        AND     AL,00001111B
        OR      AL,10110000B
        MOV     BYTE PTR [DI+1],AL
        MOV     AX,WORD PTR [LOWNUM]
        MOV     WORD PTR [DI+2],AX
        POPF
        JZ      EXVEC
        INC     BYTE PTR [DI]
EXVEC:  JMP     GRPEX

NOTMOV1:AND     AL,11000111B
        CMP     AL,11000000B
        JZ      IMMACC                  ; IMMEDIATE TO ACC

        CMP     BYTE PTR [TSTFLG],0
        JNZ     GRP23
        CMP     BYTE PTR [MIDFLD],1*8   ; OR?
        JZ      GRP23
        CMP     BYTE PTR [MIDFLD],4*8   ; AND?
        JZ      GRP23
        CMP     BYTE PTR [MIDFLD],6*8   ; XOR?
        JZ      GRP23
        TEST    BYTE PTR [DI+1],1       ; TEST IF BYTE OPCODE
        JZ      GRP23

        MOV     AX,[LOWNUM]
        MOV     BX,AX
        CBW
        CMP     AX,BX
        JNZ     GRP23                   ; SMALL ENOUGH?

        MOV     BL,[DI]
        DEC     BYTE PTR [DI]
        OR      BYTE PTR [DI+1],10B
        JMP     SHORT GRP23X

IMMACC: MOV     AL,BYTE PTR [DI+1]
        AND     AL,1
        CMP     BYTE PTR [TSTFLG],0
        JZ      NOTTST
        OR      AL,10101000B
        JMP     SHORT TEST1
NOTTST: OR      AL,BYTE PTR [MIDFLD]
        OR      AL,100B
TEST1:  MOV     BYTE PTR [DI+1],AL
        DEC     BYTE PTR [DI]

GRP23:  MOV     BL,BYTE PTR [DI]
GRP23X: XOR     BH,BH
        ADD     BX,DI
        INC     BX
        MOV     AX,WORD PTR [LOWNUM]
        MOV     WORD PTR [BX],AX
        INC     BYTE PTR [DI]
        TEST    BYTE PTR [DI+1],1
        JZ      GRPEX1
        INC     BYTE PTR [DI]
GRPEX1: JMP     GRPEX
;
;       SECOND OPERAND WAS MEMORY OR REGISTER
;
GRP21:
        CMP     BYTE PTR [SEGFLG],0
        JZ      GRP28                   ; FIRST OPERAND WAS A SEGMENT REG
        MOV     AL,BYTE PTR [REGMEM]
        TEST    AL,10000B
        JZ      NOTSEG1
ERRV3:  JMP     ASMERR
NOTSEG1:AND     AL,111B
        OR      BYTE PTR [DI+2],AL
        AND     BYTE PTR [DI+1],11111110B
        CMP     BYTE PTR [MEMFLG],0
        JNZ     G22V
        JMP     GRPEX

GRP28:  AND     BYTE PTR [DI+2],11000111B
        MOV     AL,BYTE PTR [DI+1]      ; GET FIRST OPCODE
        AND     AL,1B
        CMP     BYTE PTR [MOVFLG],0
        JZ      NOTMOV2
        OR      AL,10001000B
        JMP     SHORT MOV1
NOTMOV2:CMP     BYTE PTR [TSTFLG],0
        JZ      NOTTST2
        OR      AL,10000100B
        CMP     BYTE PTR [TSTFLG],2
        JNZ     NOTTST2
        OR      AL,10B
NOTTST2:OR      AL,BYTE PTR [MIDFLD]    ; MIDFLD IS ZERO FOR TST
MOV1:   MOV     BYTE PTR [DI+1],AL
        CMP     BYTE PTR [MEMFLG],0
G22V:   JNZ     GRP22
;
;       SECOND OPERAND WAS A REGISTER
;
        MOV     AL,BYTE PTR [REGMEM]
        TEST    AL,10000B               ; SEGMENT REGISTER?
        JZ      NOTSEG
        CMP     BYTE PTR [MOVFLG],0
        JZ      ERRV3
        MOV     BYTE PTR [DI+1],10001100B

NOTSEG: AND     AL,111B
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
        OR      BYTE PTR [DI+2],AL
;
; SPECIAL FORM OF THE EXCHANGE COMMAND
;
        CMP     BYTE PTR [TSTFLG],2
        JNZ     GRPEX
        TEST    BYTE PTR [DI+1],1
        JZ      GRPEX
        PUSH    AX
        MOV     AL,BYTE PTR [DI+2]
        AND     AL,11000000B
        CMP     AL,11000000B            ; MUST BE REGISTER TO REGISTER
        POP     AX
        JB      GRPEX
        OR      AL,AL
        JZ      SPECX
        MOV     AL,[DI+2]
        AND     AL,00000111B
        JNZ     GRPEX
        MOV     CL,3
        SHR     BYTE PTR [DI+2],CL
SPECX:  MOV     AL,[DI+2]
        AND     AL,00000111B
        OR      AL,10010000B
        MOV     BYTE PTR [DI+1],AL
        DEC     BYTE PTR [DI]
        JMP     SHORT GRPEX
;
;  SECOND OPERAND WAS A MEMORY REFERENCE
;
GRP22:  CMP     BYTE PTR [TSTFLG],0
        JNZ     TST2
        OR      BYTE PTR [DI+1],10B
TST2:   MOV     AL,BYTE PTR [DI+2]
        CMP     AL,11000000B            ; MUST BE A REGISTER
        JB      ASMERR
        CMP     BYTE PTR [SEGFLG],0
        JZ      GRP223
        AND     AL,00011000B
        JMP     SHORT GRP222
GRP223: AND     AL,111B
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
GRP222: OR      AL,BYTE PTR [MODE]
        OR      AL,BYTE PTR [REGMEM]
        MOV     BYTE PTR [DI+2],AL
        MOV     AX,WORD PTR [LOWNUM]
        MOV     WORD PTR [DI+3],AX
GRPSIZ: MOV     BYTE PTR [DI],2
        MOV     AL,BYTE PTR [DI+2]
        AND     AL,11000111B
        CMP     AL,00000110B
        JZ      GRP24
        AND     AL,11000000B
        CMP     AL,01000000B
        JZ      GRP25
        CMP     AL,10000000B
        JNZ     GRPEX
GRP24:  INC     BYTE PTR [DI]
GRP25:  INC     BYTE PTR [DI]

GRPEX:  CMP     BYTE PTR [MOVFLG],0
        JZ      ASSEM_EXIT
;
;       TEST FOR SPECIAL FORM OF MOV AX,[MEM] OR MOV [MEM],AX
;
        MOV     AL,[DI+1]               ; GET OP-CODE
        AND     AL,11111100B
        CMP     AL,10001000B
        JNZ     ASSEM_EXIT
        CMP     BYTE PTR [DI+2],00000110B   ; MEM TO AX OR AX TO MEM
        JNZ     ASSEM_EXIT
        MOV     AL,BYTE PTR [DI+1]
        AND     AL,11B
        XOR     AL,10B
        OR      AL,10100000B
        MOV     BYTE PTR [DI+1],AL
        DEC     BYTE PTR [DI]
        MOV     AX,[DI+3]
        MOV     WORD PTR [DI+2],AX

ASSEM_EXIT:
        CALL    STUFF_BYTES
        JMP     ASSEMLOOP

; Assem error. SI points to character in the input buffer
; which caused error. By subtracting from start of buffer,
; we will know how far to tab over to appear directly below
; it on the terminal. Then print "^ Error".

ASMERR:
        SUB     SI,OFFSET DG:(BYTEBUF-10)   ; How many char processed so far?
        MOV     CX,SI                   ; Parameter for TAB in CX
        CALL    TAB                     ; Directly below bad char
        MOV     SI,OFFSET DG:SYNERR     ; Error message
        CALL    PRINTMES
        JMP     ASSEMLOOP
;
;  assemble the different parts into an instruction
;
BUILDIT:
        MOV     AL,BYTE PTR [AWORD]
        OR      AL,AL
        JNZ     BUILD1
BLDERR: JMP     ASMERR

BUILD1: DEC     AL
        OR      BYTE PTR [DI+1],AL      ; SET THE SIZE

BUILD2: CMP     BYTE PTR [NUMFLG],0     ; TEST FOR IMMEDIATE DATA
        JZ      BUILD3
        CMP     BYTE PTR [MEMFLG],0
        JZ      BLDERR

BUILD3: MOV     AL,BYTE PTR [REGMEM]
        CMP     AL,-1
        JZ      BLD1
        TEST    AL,10000B               ; TEST IF SEGMENT REGISTER
        JZ      BLD1
        CMP     BYTE PTR [MOVFLG],0
        JZ      BLDERR
        MOV     WORD PTR [DI+1],10001110B
        INC     BYTE PTR [MOVFLG]
        INC     BYTE PTR [SEGFLG]
        AND     AL,00000011B
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
        OR      AL,BYTE PTR 11000000B
        MOV     BYTE PTR [DI+2],AL
        RET

BLD1:   AND     AL,00000111B
BLD4:   OR      AL,BYTE PTR [MODE]
        OR      AL,BYTE PTR [MIDFLD]
        MOV     BYTE PTR [DI+2],AL
        MOV     AX,WORD PTR [LOWNUM]
        MOV     WORD PTR [DI+3],AX
        RET

GETREGMEM:
        MOV     BYTE PTR [F8087],0
GETREGMEM2:
        CALL    SCANP
        XOR     AX,AX
        MOV     WORD PTR [LOWNUM],AX    ; OFFSET
        MOV     WORD PTR [DIFLG],AX     ; DIFLG+SIFLG
        MOV     WORD PTR [BXFLG],AX     ; BXFLG+BPFLG
        MOV     WORD PTR [NEGFLG],AX    ; NEGFLG+NUMFLG
        MOV     WORD PTR [MEMFLG],AX    ; MEMFLG+REGFLG
        DEC     AL
        CMP     BYTE PTR [F8087],0
        JZ      PUTREG
        MOV     AL,1                    ; DEFAULT 8087 REG IS 1
PUTREG: MOV     BYTE PTR [REGMEM],AL

GETLOOP:MOV     BYTE PTR [NEGFLG],0
GETLOOP1:
        MOV     AX,WORD PTR [SI]
        CMP     AL,','
        JZ      GOMODE
        CMP     AL,13
        JZ      GOMODE
        CMP     AL,';'
        JZ      GOMODE
        CMP     AL,9
        JZ      GETTB
        CMP     AL,' '
        JNZ     GOGET
GETTB:  INC     SI
        JMP     GETLOOP1
GOGET:  JMP     GETINFO
;
;  DETERMINE THE MODE BITS
;
GOMODE: MOV     DI,OFFSET DG:ASSEM_CNT
        MOV     BYTE PTR [MODE],11000000B
        MOV     BYTE PTR [ASSEM_CNT],2
        CMP     BYTE PTR [MEMFLG],0
        JNZ     GOMODE1
        MOV     AL,[NUMFLG]
        OR      AL,[REGFLG]
        JNZ     MORET
        OR      AL,[F8087]
        JZ      ERRET
        MOV     AL,[DI+1]
        OR      AL,[DIRFLG]
        CMP     AL,0DCH                 ; ARITHMETIC?
        JNZ     MORET
        MOV     BYTE PTR [DI+1],0DEH    ; ADD POP TO NULL ARG 8087
MORET:  RET
ERRET:  JMP     ASMERR

GOMODE1:MOV     BYTE PTR [MODE],0
        CMP     BYTE PTR [NUMFLG],0
        JZ      GOREGMEM

        MOV     BYTE PTR [DI],4
        MOV     AX,WORD PTR [DIFLG]
        OR      AX,WORD PTR [BXFLG]
        JNZ     GOMODE2
        MOV     BYTE PTR [REGMEM],00000110B
        RET

GOMODE2:MOV     BYTE PTR [MODE],10000000B
        CALL    CHKSIZ1
        CMP     CL,2
        JZ      GOREGMEM
        DEC     BYTE PTR [DI]
        MOV     BYTE PTR [MODE],01000000B
;
;  DETERMINE THE REG-MEM BITS
;
GOREGMEM:
        MOV     BX,WORD PTR [BXFLG]
        MOV     CX,WORD PTR [DIFLG]
        XOR     DX,DX
GOREG0:
        MOV     AL,BL                   ; BX
        ADD     AL,CH                   ; SI
        CMP     AL,2
        JZ      GOGO
        INC     DL
        MOV     AL,BL
        ADD     AL,CL
        CMP     AL,2
        JZ      GOGO
        INC     DL
        MOV     AL,BH
        ADD     AL,CH
        CMP     AL,2
        JZ      GOGO
        INC     DL
        MOV     AL,BH
        ADD     AL,CL
        CMP     AL,2
        JZ      GOGO
        INC     DL
        OR      CH,CH
        JNZ     GOGO
        INC     DL
        OR      CL,CL
        JNZ     GOGO
        INC     DL                      ; BP+DISP
        OR      BH,BH
        JZ      GOREG1
        CMP     BYTE PTR [MODE],0
        JNZ     GOGO
        MOV     BYTE PTR [MODE],01000000B
        INC     BYTE PTR [DI]
        DEC     DL
GOREG1: INC     DL                      ; BX+DISP
GOGO:   MOV     BYTE PTR [REGMEM],DL
        RET

GETINFO:CMP     AX,'EN'                 ; NEAR
        JNZ     GETREG3
GETREG0:MOV     DL,2
GETRG01:CALL    SETSIZ1
GETREG1:CALL    SCANS
        MOV     AX,WORD PTR [SI]
        CMP     AX,"TP"                 ; PTR
        JZ      GETREG1
        JMP     GETLOOP

GETREG3:MOV     CX,5
        MOV     DI,OFFSET DG:SIZ8
        CALL    CHKREG                  ; LOOK FOR BYTE, WORD, DWORD, ETC.
        JZ      GETREG41
        INC     AL
        MOV     DL,AL
        JMP     GETRG01

GETREG41:
        MOV     AX,[SI]
        CMP     BYTE PTR [F8087],0
        JZ      GETREG5
        CMP     AX,"TS"                 ; 8087 STACK OPERAND
        JNZ     GETREG5
        CMP     BYTE PTR [SI+2],","
        JNZ     GETREG5
        MOV     BYTE PTR [DIRFLG],0
        ADD     SI,3
        JMP     GETLOOP

GETREG5:CMP     AX,"HS"                 ; SHORT
        JZ      GETREG1

        CMP     AX,"AF"                 ; FAR
        JNZ     GETRG51
        CMP     BYTE PTR [SI+2],"R"
        JNZ     GETRG51
        ADD     SI,3
        MOV     DL,4
        JMP     GETRG01

GETRG51:CMP     AL,'['
        JNZ     GETREG7
GETREG6:INC     BYTE PTR [MEMFLG]
        INC     SI
        JMP     GETLOOP

GETREG7:CMP     AL,']'
        JZ      GETREG6
        CMP     AL,'.'
        JZ      GETREG6
        CMP     AL,'+'
        JZ      GETREG6
        CMP     AL,'-'
        JNZ     GETREG8
        INC     BYTE PTR [NEGFLG]
        INC     SI
        JMP     GETLOOP1

GETREG8:                                ; LOOK FOR A REGISTER
        CMP     BYTE PTR [F8087],0
        JZ      GETREGREG
        CMP     AX,"TS"
        JNZ     GETREGREG
        CMP     BYTE PTR [SI+2],"("
        JNZ     GETREGREG
        CMP     BYTE PTR [SI+4],")"
        JNZ     ASMPOP
        MOV     AL,[SI+3]
        SUB     AL,"0"
        JB      ASMPOP
        CMP     AL,7
        JA      ASMPOP
        MOV     [REGMEM],AL
        INC     BYTE PTR [REGFLG]
        ADD     SI,5
        CMP     WORD PTR [SI],"S,"
        JNZ     ZLOOP
        CMP     BYTE PTR [SI+2],"T"
        JNZ     ZLOOP
        ADD     SI,3
ZLOOP:  JMP     GETLOOP

GETREGREG:
        MOV     CX,20
        MOV     DI,OFFSET DG:REG8
        CALL    CHKREG
        JZ      GETREG12                ; CX = 0 MEANS NO REGISTER
        MOV     BYTE PTR [REGMEM],AL
        INC     BYTE PTR [REGFLG]       ; TELL EVERYONE WE FOUND A REG
        CMP     BYTE PTR [MEMFLG],0
        JNZ     NOSIZE
        CALL    SETSIZ
INCSI2: ADD     SI,2
        JMP     GETLOOP

NOSIZE: CMP     AL,11                   ; BX REGISTER?
        JNZ     GETREG9
        CMP     WORD PTR [BXFLG],0
        JZ      GETOK
ASMPOP: JMP     ASMERR

GETOK:  INC     BYTE PTR [BXFLG]
        JMP     INCSI2
GETREG9:
        CMP     AL,13                   ; BP REGISTER?
        JNZ     GETREG10
        CMP     WORD PTR [BXFLG],0
        JNZ     ASMPOP
        INC     BYTE PTR [BPFLG]
        JMP     INCSI2
GETREG10:
        CMP     AL,14                   ; SI REGISTER?
        JNZ     GETREG11
        CMP     WORD PTR [DIFLG],0
        JNZ     ASMPOP
        INC     BYTE PTR [SIFLG]
        JMP     INCSI2
GETREG11:
        CMP     AL,15                   ; DI REGISTER?
        JNZ     ASMPOP                  ; *** error
        CMP     WORD PTR [DIFLG],0
        JNZ     ASMPOP
        INC     BYTE PTR [DIFLG]
        JMP     INCSI2

GETREG12:                               ; BETTER BE A NUMBER!
        MOV     BP,WORD PTR [ASMADD+2]
        CMP     BYTE PTR [MEMFLG],0
        JZ      GTRG121
GTRG119:MOV     CX,4
GTRG120:CALL    GETHX
        JMP     SHORT GTRG122
GTRG121:MOV     CX,2
        CMP     BYTE PTR [AWORD],1
        JZ      GTRG120
        CMP     BYTE PTR [AWORD],CL
        JZ      GTRG119
        CALL    GET_ADDRESS
GTRG122:JC      ASMPOP
        MOV     [HINUM],AX
        CMP     BYTE PTR [NEGFLG],0
        JZ      GETREG13
        NEG     DX
GETREG13:
        ADD     WORD PTR [LOWNUM],DX
        INC     BYTE PTR [NUMFLG]
GETLOOPV:
        JMP     GETLOOP

CHKREG: PUSH    CX
        INC     CX
        REPNZ   SCASW
        POP     AX
        SUB     AX,CX
        OR      CX,CX
        RET

STUFF_BYTES:
        PUSH    SI
        LES     DI,DWORD PTR ASMADD
        MOV     SI,OFFSET DG:ASSEM_CNT
        XOR     AX,AX
        LODSB
        MOV     CX,AX
        JCXZ    STUFFRET
        REP     MOVSB
        MOV     WORD PTR [ASMADD],DI
STUFFRET:
        POP     SI
        RET

SETSIZ:
        MOV     DL,1
        TEST    AL,11000B               ; 16 BIT OR SEGMENT REGISTER?
        JZ      SETSIZ1
        INC     DL
SETSIZ1:
        CMP     BYTE PTR [AWORD],0
        JZ      SETSIZ2
        CMP     BYTE PTR [AWORD],DL
        JZ      SETSIZ2
SETERR: POP     DX
        JMP     ASMPOP
SETSIZ2:MOV     BYTE PTR [AWORD],DL
        RET
;
;  DETERMINE IF NUMBER IN AX:DX IS 8 BITS, 16 BITS, OR 32 BITS
;
CHKSIZ: MOV     CL,4
        CMP     AX,BP
        JNZ     RETCHK
CHKSIZ1:MOV     CL,2
        MOV     AX,DX
        CBW
        CMP     AX,DX
        JNZ     RETCHK
        DEC     CL
RETCHK: RET
;
;  get first character after first space
;
SCANS:  CMP     BYTE PTR [SI],13
        JZ      RETCHK
        CMP     BYTE PTR [SI],"["
        JZ      RETCHK
        LODSB
        CMP     AL," "
        JZ      SCANBV
        CMP     AL,9
        JNZ     SCANS
SCANBV: JMP     SCANB
;
; Set up for 8087 op-codes
;
SETMID:
        MOV     BYTE PTR [ASSEM1],0D8H
        MOV     AH,AL
        AND     AL,111B                 ; SET MIDDLE BITS OF SECOND BYTE
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
        MOV     [MIDFLD],AL
        MOV     AL,AH                   ; SET LOWER BITS OF FIRST BYTE
        SHR     AL,1
        SHR     AL,1
        SHR     AL,1
        OR      [ASSEM1],AL
        MOV     BYTE PTR [F8087],1      ; INDICATE 8087 OPERAND
        MOV     BYTE PTR [DIRFLG],100B
        RET
;
; Set MF bits for 8087 op-codes
;
SETMF:  MOV     AL,[AWORD]
        TEST    BYTE PTR [DI+1],10B
        JNZ     SETMFI
        AND     BYTE PTR [DI+1],11111001B   ; CLEAR MF BITS
        CMP     AL,3                    ; DWORD?
        JZ      SETMFRET
        CMP     AL,4                    ; QWORD?
        JZ      SETMFRET2
        TEST    BYTE PTR [DI+1],1
        JZ      SETMFERR
        CMP     AL,5                    ; TBYTE?
        JZ      SETMFRET3
        JMP     SHORT SETMFERR

SETMFI: CMP     AL,3                    ; DWORD?
        JZ      SETMFRET
        CMP     AL,2                    ; WORD?
        JZ      SETMFRET2
        TEST    BYTE PTR [DI+1],1
        JZ      SETMFERR
        CMP     AL,4                    ; QWORD?
        JNZ     SETMFERR
        OR      BYTE PTR [DI+1],111B
SETMFRET3:
        OR      BYTE PTR [DI+1],011B
        OR      BYTE PTR [DI+2],101000B
        JMP     SHORT SETMFRET
SETMFRET2:
        OR      BYTE PTR [DI+1],100B
SETMFRET:
        RET

SETMFERR:
        JMP     ASMPOP


DW_OPER:
        MOV     BP,1
        JMP     SHORT DBEN

DB_OPER:
        XOR     BP,BP
DBEN:   MOV     DI,OFFSET DG:ASSEM_CNT
        DEC     BYTE PTR [DI]
        INC     DI
DB0:    XOR     BL,BL
        CALL    SCANP
        JNZ     DB1
DBEX:   JMP     ASSEM_EXIT
DB1:    OR      BL,BL
        JNZ     DB3
        MOV     BH,BYTE PTR [SI]
        CMP     BH,"'"
        JZ      DB2
        CMP     BH,'"'
        JNZ     DB4
DB2:    INC     SI
        INC     BL
DB3:    LODSB
        CMP     AL,13
        JZ      DBEX
        CMP     AL,BH
        JZ      DB0
        STOSB
        INC     BYTE PTR [ASSEM_CNT]
        JMP     DB3
DB4:    MOV     CX,2
        CMP     BP,0
        JZ      DB41
        MOV     CL,4
DB41:   PUSH    BX
        CALL    GETHX
        POP     BX
        JNC     DB5
        JMP     ASMERR
DB5:    MOV     AX,DX
        CMP     BP,0
        JZ      DB6
        STOSW
        INC     BYTE PTR [ASSEM_CNT]
        JMP     SHORT DB7
DB6:    STOSB
DB7:    INC     BYTE PTR [ASSEM_CNT]
        JMP     DB0

CODE    ENDS
        END ASSEM
                     