TITLE   DEBUASM

; Code for the UASSEMble command in the debugger

.xlist
.xcref
        INCLUDE DEBEQU.ASM
        INCLUDE DOSSYM.ASM
.cref
.list


CODE    SEGMENT PUBLIC BYTE 'CODE'
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE

        EXTRN   SYNERR:BYTE
        EXTRN   NSEG:WORD,SISAVE:WORD,BPSAVE:WORD,DISAVE:WORD
        EXTRN   BXSAVE:WORD,DSSAVE:WORD,ESSAVE:WORD,CSSAVE:WORD,IPSAVE:WORD
        EXTRN   SSSAVE:WORD,CXSAVE:WORD,SPSAVE:WORD,FSAVE:WORD
        EXTRN   DISTAB:WORD,SHFTAB:WORD,IMMTAB:WORD,GRP1TAB:WORD,GRP2TAB:WORD
        EXTRN   DBMN:BYTE,ESCMN:BYTE,DISPB:WORD,STACK:BYTE,REG8:BYTE
        EXTRN   REG16:BYTE,SREG:BYTE,SIZ8:BYTE,SEGTAB:WORD,M8087_TAB:BYTE
        EXTRN   FI_TAB:BYTE,SIZE_TAB:BYTE,MD9_TAB:BYTE,MD9_TAB2:BYTE
        EXTRN   MDB_TAB:BYTE,MDB_TAB2:BYTE,MDD_TAB:BYTE,MDD_TAB2:BYTE
        EXTRN   MDF_TAB:BYTE

CONST   ENDS

DATA    SEGMENT PUBLIC BYTE

        EXTRN   DISADD:BYTE,DISCNT:WORD,BYTCNT:BYTE,TEMP:BYTE,AWORD:BYTE
        EXTRN   MIDFLD:BYTE,MODE:BYTE,REGMEM:BYTE,OPCODE:WORD,OPBUF:BYTE
        EXTRN   INDEX:WORD

DATA    ENDS

DG      GROUP   CODE,CONST,DATA


CODE    SEGMENT PUBLIC BYTE 'CODE'
ASSUME  CS:DG,DS:DG,ES:DG,SS:DG


        PUBLIC  UNASSEM
        PUBLIC  DISASLN,MEMIMM,JMPCALL,SIGNIMM,ALUFROMREG,WORDTOALU
        PUBLIC  GRP2,PREFIX,OUTVARW,GRP1,SSPRE,MOVSEGTO,DSPRE,SHIFT
        PUBLIC  ESPRE,IMMED,CSPRE,OUTVARB,CHK10,ACCIMM,INT3,INVARB
        PUBLIC  MOVSEGFROM,LOADACC,OUTFIXB,XCHGAX,REGIMMW,SHORTJMP
        PUBLIC  SAV8,M8087,M8087_DB,M8087_DF,M8087_D9,M8087_DD
        PUBLIC  SAV16,SAVHEX,INFIXW,REGIMMB,OUTFIXW,SHIFTV,LONGJMP
        PUBLIC  INVARW,STOREACC,INFIXB,NOOPERANDS,ALUTOREG
        PUBLIC  SEGOP,REGOP,GETADDR

        EXTRN   CRLF:NEAR,PRINTMES:NEAR,BLANK:NEAR,TAB:NEAR,OUT:NEAR
        EXTRN   HEX:NEAR,DEFAULT:NEAR,OUTSI:NEAR,OUTDI:NEAR

UNASSEM:
        MOV     BP,[CSSAVE]             ; Default code segment
        MOV     DI,OFFSET DG:DISADD     ; Default address
        MOV     CX,DISPB                ; Default length
        SHR     CX,1
        SHR     CX,1
        CALL    DEFAULT
        MOV     WORD PTR [DISADD],DX    ; Displacement of disassembly
        MOV     WORD PTR [DISADD+2],AX  ; Segment
        MOV     WORD PTR [DISCNT],CX    ; No. of bytes (but whole instructions)
DISLP:
        CALL    DISASLN                 ; Disassemble one line
        CALL    CRLF
        TEST    [DISCNT],-1             ; See if we've used up the range
        JNZ     DISLP
        RET

GOTDIS: PUSH    DS                      ; RE-GET LAST BYTE
        PUSH    SI
        LDS     SI,DWORD PTR [DISADD]
        MOV     AL,[SI-1]
        POP     SI
        POP     DS
        RET

GETDIS:
        PUSH    DS
        LDS     SI,DWORD PTR [DISADD]
        LODSB                           ; Get the next byte of code
        POP     DS
        MOV     WORD PTR [DISADD],SI    ; Update pointer
        PUSH    AX
        CALL    HEX                     ; Display each code byte
        MOV     SI,[DISCNT]
        OR      SI,SI                   ; Check if range exhausted
        JZ      ENDRNG                  ; If so, don't wrap around
        DEC     SI                      ; Count off the bytes
        MOV     [DISCNT],SI
ENDRNG:
        INC     BYTE PTR[BYTCNT]        ; Keep track of no. of bytes per line
        POP     AX
        RET

DSPRE:  INC     BYTE PTR [NSEG+1]
SSPRE:  INC     BYTE PTR [NSEG+1]
CSPRE:  INC     BYTE PTR [NSEG+1]
ESPRE:  INC     BYTE PTR [NSEG+1]

PREFIX:
        POP     BX                      ; Dump off return address
        CALL    FINLN
        CALL    CRLF
DISASLN:
        PUSH    DS
        LDS     SI,DWORD PTR [DISADD]
        CALL    OUTSI                   ; Show disassembly address
        POP     DS
        CALL    BLANK
DISASLN1:
        MOV     BYTE PTR [BYTCNT],0     ; Count of code bytes per line
        MOV     DI,OFFSET DG:OPBUF      ; Point to operand buffer
        MOV     AL," "
        MOV     CX,OPBUFLEN-1           ; Don't do last byte which has end marker
        REP     STOSB                   ; Initialize operand buffer to blanks
        MOV     BYTE PTR [DI]," "+80H
        CALL    GETDIS                  ; Get opcode
        MOV     AH,0
        MOV     BX,AX
        AND     AL,1                    ; Mask to "W" bit
        MOV     [AWORD],AL
        MOV     AL,BL                   ; Restore opcode
        SHL     BX,1
        SHL     BX,1                    ; Multiply opcode by 4
        ADD     BX,OFFSET DG:DISTAB
        MOV     DX,[BX]                 ; Get pointer to mnemonic from table
        MOV     [OPCODE],DX             ; Save it until line is complete
        MOV     DI,OFFSET DG:OPBUF      ; Initialize for opcode routines
        CALL    WORD PTR [BX+2]         ; Dispatch to opcode routine
FINLN:
        MOV     SI,OFFSET DG:DISADD
        MOV     AH,[BYTCNT]             ; See how many bytes in this instruction
        ADD     AH,AH                   ; Each uses two characters
        MOV     AL,14                   ; Amount of space we want to use
        SUB     AL,AH                   ; See how many fill characters needed
        CBW
        XCHG    CX,AX                   ; Parameter for TAB needed in CX
        CALL    TAB
        MOV     SI,[OPCODE]
        OR      SI,SI                   ; MAKE SURE THERE IS SOMETHING TO PRINT
        JZ      NOOPC
        CALL    PRINTMES                ; Print opcode mnemonic
        MOV     AL,9
        CALL    OUT                     ; and a tab
NOOPC:  MOV     SI,OFFSET DG:OPBUF
        JMP     PRINTMES                ; and the operand buffer

GETMODE:
        CALL    GETDIS                  ; Get the address mode byte
        MOV     AH,AL
        AND     AL,7                    ; Mask to "r/m" field
        MOV     [REGMEM],AL
        SHR     AH,1
        SHR     AH,1
        SHR     AH,1
        MOV     AL,AH
        AND     AL,7                    ; Mask to center 3-bit field
        MOV     [MIDFLD],AL
        SHR     AH,1
        SHR     AH,1
        SHR     AH,1
        MOV     [MODE],AH               ; Leaving 2-bit "MOD" field
        RET

IMMED:
        MOV     BX,OFFSET DG:IMMTAB
        CALL    GETMNE
FINIMM:
        CALL    TESTREG
        JMP     SHORT IMM

MEMIMM:
        CALL    GETMODE
        JMP     SHORT FINIMM

ACCIMM:
        XOR     AL,AL
IMM1:
        CALL    SAVREG
IMM:
        MOV     AL,","
        STOSB
        TEST    BYTE PTR [AWORD],-1
        JNZ     SAV16
SAV8:
        CALL    GETDIS
        JMP     SHORT SAVHEX

LONGJMP:
        PUSH    DI
        MOV     DI,OFFSET DG:TEMP
        CALL    SAV16
        POP     DI
        CALL    SAV16
        MOV     AL,":"
        STOSB
        MOV     SI,OFFSET DG:TEMP
        MOV     CX,4
MOVDIG:
        LODSB
        STOSB
        LOOP    MOVDIG
        RET
SAV16:
        CALL    GETDIS                  ; Get low byte
        MOV     DL,AL
        CALL    GETDIS                  ; Get high byte
        MOV     DH,AL
        CALL    SAVHEX                  ; Convert and store high byte
        MOV     AL,DL
SAVHEX:
        MOV     AH,AL
        SHR     AL,1
        SHR     AL,1
        SHR     AL,1
        SHR     AL,1
        CALL    SAVDIG
        MOV     AL,AH
SAVDIG:
        AND     AL,0FH
        ADD     AL,90H
        DAA
        ADC     AL,40H
        DAA
        STOSB
        RET

CHK10:
        CALL    GETDIS
        CMP     AL,10
        JNZ     SAVHEX
        RET

SIGNIMM:
        MOV     BX,OFFSET DG:IMMTAB
        CALL    GETMNE
        CALL    TESTREG
        MOV     AL,","
        STOSB
SAVD8:
        CALL    GETDIS                  ; Get signed 8-bit number
        CBW
        MOV     DX,AX                   ; Save true 16-bit value in DX
        MOV     AH,AL
        MOV     AL,"+"
        OR      AH,AH
;       JZ      nosign
        JNS     POSITIV                 ; OK if positive
        MOV     AL,"-"
        NEG     AH                      ; Get magnitude if negative
POSITIV:
        STOSB
; nosign:
        MOV     AL,AH
        JMP     SHORT SAVHEX

ALUFROMREG:
        CALL    GETADDR
        MOV     AL,","
        STOSB
REGFLD:
        MOV     AL,[MIDFLD]
SAVREG:
        MOV     SI,OFFSET DG:REG8
        CMP     BYTE PTR [AWORD],1
        JNE     FNDREG
SAVREG16:
        MOV     SI,OFFSET DG:REG16
FNDREG:
        CBW
        ADD     SI,AX
        ADD     SI,AX
        MOVSW
        RET

SEGOP:
        SHR     AL,1
        SHR     AL,1
        SHR     AL,1
SAVSEG:
        AND     AL,3
        MOV     SI,OFFSET DG:SREG
        JMP     SHORT FNDREG

REGOP:
        AND     AL,7
        JMP     SHORT SAVREG16

MOVSEGTO:
        MOV     BYTE PTR [AWORD],1
        CALL    GETADDR
        MOV     AL,","
        STOSB
        MOV     AL,[MIDFLD]
        JMP     SHORT SAVSEG

MOVSEGFROM:
        CALL    GETMODE
        CALL    SAVSEG
        MOV     BYTE PTR [AWORD],1
        JMP     SHORT MEMOP2

GETADDR:
        CALL    GETMODE
        JMP     SHORT ADDRMOD

WORDTOALU:
        MOV     BYTE PTR [AWORD],1
ALUTOREG:
        CALL    GETMODE
        CALL    REGFLD
MEMOP2:
        MOV     AL,","
        STOSB
ADDRMOD:
        CMP     BYTE PTR [MODE],3
        MOV     AL,[REGMEM]
        JE      SAVREG
        XOR     BX,BX
        MOV     BYTE PTR [NSEG],3
        MOV     BYTE PTR [DI],"["
        INC     DI
        CMP     AL,6
        JNE     NODRCT
        CMP     BYTE PTR [MODE],0
        JE      DIRECT                  ; Mode=0 and R/M=6 means direct addr.
NODRCT:
        MOV     DL,AL
        CMP     AL,1
        JBE     USEBX
        CMP     AL,7
        JE      USEBX
        CMP     AL,3
        JBE     USEBP
        CMP     AL,6
        JNE     CHKPLS
USEBP:
        MOV     BX,[BPSAVE]
        MOV     BYTE PTR [NSEG],2       ; Change default to Stack Segment
        MOV     AX,BPREG
SAVBASE:
        STOSW
CHKPLS:
        CMP     DL,4
        JAE     NOPLUS
        MOV     AL,"+"
        STOSB
NOPLUS:
        CMP     DL,6
        JAE     DOMODE                  ; No index register
        AND     DL,1                    ; Even for SI, odd for DI
        JZ      USESI
        ADD     BX,[DISAVE]
        MOV     AX,DIREG
SAVINDX:
        STOSW
DOMODE:
        MOV     AL,[MODE]
        OR      AL,AL
        JZ      CLOSADD                 ; If no displacement, then done
        CMP     AL,2
        JZ      ADDDIR
        CALL    SAVD8                   ; Signed 8-bit displacement
ADDCLOS:
        ADD     BX,DX
CLOSADD:
        MOV     AL,"]"
        STOSB
        MOV     [INDEX],BX
NOOPERANDS:
        RET

ADDDIR:
        MOV     AL,"+"
        STOSB
DIRECT:
        CALL    SAV16
        JMP     SHORT ADDCLOS

USEBX:
        MOV     BX,[BXSAVE]
        MOV     AX,BXREG
        JMP     SHORT SAVBASE

USESI:
        ADD     BX,[SISAVE]
        MOV     AX,SIREG
        JMP     SHORT SAVINDX

SHORTJMP:
        CALL    GETDIS
        CBW
        ADD     AX,WORD PTR [DISADD]
        XCHG    DX,AX
SAVJMP:
        MOV     AL,DH
        CALL    SAVHEX
        MOV     AL,DL
        JMP     SAVHEX

JMPCALL:
        CALL    GETDIS
        MOV     DL,AL
        CALL    GETDIS
        MOV     DH,AL
        ADD     DX,WORD PTR [DISADD]
        JMP     SHORT SAVJMP

XCHGAX:
        AND     AL,7
        CALL    SAVREG16
        MOV     AL,","
        STOSB
        XOR     AL,AL
        JMP     SAVREG16

LOADACC:
        XOR     AL,AL
        CALL    SAVREG
        MOV     AL,","
        STOSB
MEMDIR:
        MOV     AL,"["
        STOSB
        XOR     BX,BX
        MOV     BYTE PTR [NSEG],3
        JMP     DIRECT

STOREACC:
        CALL    MEMDIR
        MOV     AL,","
        STOSB
        XOR     AL,AL
        JMP     SAVREG

REGIMMB:
        MOV     BYTE PTR [AWORD],0
        JMP     SHORT REGIMM
REGIMMW:
        MOV     BYTE PTR [AWORD],1
REGIMM:
        AND     AL,7
        JMP     IMM1

INT3:
        MOV     BYTE PTR [DI],"3"
        RET
;
;  8087 instructions whose first byte is 0dfh
;
M8087_DF:
        CALL    GET64F
        JZ      ISDD3
        MOV     SI,OFFSET DG:MDF_TAB
        JMP     NODB3
;
;  8087 instructions whose first byte is 0ddh
;
M8087_DD:
        CALL    GET64F
        JZ      ISDD3
        MOV     SI,OFFSET DG:MDD_TAB
        JMP     NOD93

ISDD3:
        MOV     AL,DL
        TEST    AL,100B
        JZ      ISSTI
        JMP     ESC0
ISSTI:  AND     AL,11B
        MOV     SI,OFFSET DG:MDD_TAB2
        MOV     CL,AL
        CALL    MOVBYT
        JMP     PUTRST
;
;  8087 instructions whose first byte is 0dbh
;
M8087_DB:
        CALL    GET64F
        JZ      ISDB3
        MOV     SI,OFFSET DG:MDB_TAB
NODB3:  CALL    PUTOP
        CALL    PUTSIZE
        JMP     ADDRMOD

ISDB3:
        MOV     AL,DL
        TEST    AL,100B
        JNZ     ISDBIG
ESC0V:  JMP     ESC0
ISDBIG: CALL    GOTDIS
        AND     AL,11111B
        CMP     AL,4
        JAE     ESC0V
        MOV     SI,OFFSET DG:MDB_TAB2
        JMP     DOBIG
;
;  8087 instructions whose first byte is 0d9h
;
M8087_D9:
        CALL    GET64F
        JZ      ISD93

        MOV     SI,OFFSET DG:MD9_TAB
NOD93:  CALL    PUTOP
        AND     AL,111B
        CMP     AL,3
        JA      NOSHO
        MOV     AL,DL
        CALL    PUTSIZE
NOSHO:  JMP     ADDRMOD

ISD93:  MOV     AL,DL
        TEST    AL,100B
        JNZ     ISD9BIG
        AND     AL,111B
        OR      AL,AL
        JNZ     NOTFLD
        MOV     AX,"DL"
        STOSW
        JMP     SHORT PUTRST
NOTFLD: CMP     AL,1
        JNZ     NOTFXCH
        MOV     AX,"CX"
        STOSW
        MOV     AL,"H"
        JMP     SHORT PUTRST1
NOTFXCH:CMP     AL,3
        JNZ     NOTFSTP
        MOV     AX,"TS"
        STOSW
        MOV     AL,"P"
PUTRST1:STOSB
PUTRST: MOV     AL,9
        STOSB
        JMP     PUTST0

NOTFSTP:CALL    GOTDIS
        CMP     AL,11010000B            ; CHECK FOR FNOP
        JZ      GOTFNOP
        JMP     ESC0
GOTFNOP:MOV     AX,"ON"
        STOSW
        MOV     AL,"P"
        STOSB
        RET

ISD9BIG:
        CALL    GOTDIS                  ; GET THE MODE BYTE
        MOV     SI,OFFSET DG:MD9_TAB2
DOBIG:  AND     AL,11111B
        MOV     CL,AL
        JMP     MOVBYT
;
; entry point for the remaining 8087 instructions
;
M8087:
        CALL    GET64
        CALL    PUTFI                   ; PUT FIRST PART OF OPCODE
        MOV     AL,DL
        CMP     BYTE PTR [MODE],11B     ; CHECK FOR REGISTER MODE
        JZ      MODEIS3
        CALL    PUTMN                   ; PUT MIDDLE PART OF OPCODE
NO3:    MOV     AL,9                    ; OUTPUT A TAB
        STOSB
        MOV     AL,DL
        CALL    PUTSIZE                 ; OUTPUT THE OPERAND SIZE
        JMP     ADDRMOD

MODEIS3:
        TEST    AL,100000B              ; D BIT SET?
        JZ      MPUT                    ; NOPE...
        TEST    AL,000100B              ; FDIV OR FSUB?
        JZ      MPUT                    ; NOPE...
        XOR     AL,1                    ; REVERSE SENSE OF R
        MOV     DL,AL                   ; SAVE CHANGE
MPUT:   CALL    PUTMN                   ; PUT MIDDLE PART OF OPCODE
        MOV     AL,DL
        TEST    AL,010000B
        JZ      NOPSH
        MOV     AL,"P"
        STOSB
NOPSH:  MOV     AL,9
        STOSB
        MOV     AL,DL
        AND     AL,00000111B
        CMP     AL,2                    ; FCOM
        JZ      PUTST0
        CMP     AL,3                    ; FCOMP
        JZ      PUTST0
        MOV     AL,DL
        TEST    AL,100000B
        JZ      PUTSTST0
;
; output 8087 registers in the form st(n),st
;
PUTST0ST:
        CALL    PUTST0
        MOV     AL,','
ISCOMP: STOSB

PUTST:  MOV     AX,"TS"
        STOSW
        RET
;
; output 8087 registers in the form st,st(n)
;
PUTSTST0:
        CALL    PUTST
        MOV     AL,','
        STOSB

PUTST0: CALL    PUTST
        MOV     AL,"("
        STOSB
        MOV     AL,[REGMEM]
        ADD     AL,"0"
        STOSB
        MOV     AL,")"
        STOSB
        RET
;
; output an 8087 mnemonic
;
PUTMN:  MOV     SI,OFFSET DG:M8087_TAB
        MOV     CL,AL
        AND     CL,00000111B
        JMP     SHORT MOVBYT
;
; output either 'FI' or 'F' for first byte of opcode
;
PUTFI:  MOV     SI,OFFSET DG:FI_TAB
        JMP     SHORT PUTFI2
;
; output size (dword, tbyte, etc.)
;
PUTSIZE:MOV     SI,OFFSET DG:SIZE_TAB
PUTFI2: CMP     BYTE PTR [MODE],11B     ; check if 8087 register
        JNZ     PUTFI3
        AND     AL,111000B              ; LOOK FOR INVALID FORM OF 0DAH OPERANDS
        CMP     AL,010000B
        JZ      ESC0PJ
        MOV     AL,DL
        CMP     AL,110011B              ; FCOMPP
        JNZ     GOFI
        CMP     BYTE PTR [REGMEM],1
        JZ      GOFI
ESC0PJ: JMP     ESC0P
GOFI:   XOR     CL,CL
        JMP     SHORT MOVBYT
;
;  Look for qword
;
PUTFI3: CMP     AL,111101B
        JZ      GOTQU
        CMP     AL,111111B
        JNZ     NOTQU
GOTQU:  MOV     CL,2
        JMP     SHORT MOVBYT
;
;  look for tbyte
;
NOTQU:  CMP     AL,011101B
        JZ      GOTTB
        CMP     AL,111100B
        JZ      GOTTB
        CMP     AL,111110B
        JZ      GOTTB
        CMP     AL,011111B
        JNZ     NOTTB
GOTTB:  MOV     CL,5
        JMP     SHORT MOVBYT

NOTTB:  MOV     CL,4
        SHR     AL,CL
        MOV     CL,AL
;
; SI POINTS TO A TABLE OF TEXT SEPARATED BY "$"
; CL = WHICH ELEMENT IN THE TABLE YOU WISH TO COPY TO [DI]
;
MOVBYT: PUSH    AX
        INC     CL
MOVBYT1:DEC     CL
        JZ      MOVBYT3
MOVBYT2:LODSB
        CMP     AL,'$'
        JZ      MOVBYT1
        JMP     MOVBYT2
MOVBYT3:LODSB
        CMP     AL,'$'
        JZ      MOVBYT5
        CMP     AL,'@'                  ; THIS MEANS RESVERED OP-CODE
        JNZ     MOVBYT4
        POP     AX
        JMP     SHORT ESC0P             ; GO DO AN ESCAPE COMMAND
MOVBYT4:STOSB
        JMP     MOVBYT3
MOVBYT5:POP     AX
        RET

PUTOP:  AND     AL,111B
        MOV     CL,AL
        CALL    MOVBYT
        MOV     AL,9
        STOSB
        MOV     AL,DL
        RET

GET64F: CALL    GET64
        MOV     AL,"F"
        STOSB
        CMP     BYTE PTR [MODE],3
        MOV     AL,DL
        RET

GET64:
        AND     AL,7
        MOV     DL,AL
        CALL    GETMODE
        SHL     DL,1
        SHL     DL,1
        SHL     DL,1
        OR      AL,DL
        MOV     DL,AL                   ; SAVE RESULT
        RET

ESC0P:  POP     DI                      ; CLEAN UP STACK
ESC0:   MOV     WORD PTR [OPCODE],OFFSET DG:ESCMN
        MOV     AL,DL
        MOV     DI,OFFSET DG:OPBUF
        JMP     SHORT ESC1

ESC:    CALL    GET64
ESC1:   CALL    SAVHEX
        CMP     BYTE PTR [MODE],3
        JZ      SHRTESC
        MOV     BYTE PTR  [AWORD],1
        JMP     MEMOP2

SHRTESC:
        MOV     AL,","
        STOSB
        MOV     AL,[REGMEM]
        AND     AL,7
        JMP     SAVREG

INVARW:
        CALL    PUTAX
        JMP     SHORT INVAR
INVARB:
        CALL    PUTAL
INVAR:  MOV     AL,','
        STOSB
        JMP     PUTDX

INFIXW:
        CALL    PUTAX
        JMP     SHORT INFIX
INFIXB:
        CALL    PUTAL
INFIX:  MOV     AL,','
        STOSB
        JMP     SAV8
        STOSW
        RET

OUTVARB:
        MOV     BX,"LA"
        JMP     SHORT OUTVAR
OUTVARW:
        MOV     BX,"XA"
OUTVAR: CALL    PUTDX
OUTFV:  MOV     AL,','
        STOSB
        MOV     AX,BX
        STOSW
        RET

OUTFIXB:
        MOV     BX,"LA"
        JMP     SHORT OUTFIX
OUTFIXW:
        MOV     BX,"XA"
OUTFIX: CALL    SAV8
        JMP     OUTFV

PUTAL:  MOV     AX,"A"+4C00H            ; "AL"
        JMP     SHORT PUTX
PUTAX:  MOV     AX,"A"+5800H            ; "AX"
        JMP     SHORT PUTX
PUTDX:  MOV     AX,"D"+5800H            ; "DX"
PUTX:   STOSW
        RET

SHFT:
        MOV     BX,OFFSET DG:SHFTAB
        CALL    GETMNE
TESTREG:
        CMP     BYTE PTR [MODE],3
        JZ      NOFLG
        MOV     SI,OFFSET DG:SIZE_TAB
        MOV     CL,3
        TEST    BYTE PTR [AWORD],-1
        JNZ     TEST_1
        INC     CL
TEST_1: CALL    MOVBYT
NOFLG:
        JMP     ADDRMOD

SHIFTV:
        CALL    SHFT
        MOV     AL,","
        STOSB
        MOV     WORD PTR [DI],"C"+4C00H ; "CL"
        RET

SHIFT:
        CALL    SHFT
        MOV     AX,"1,"
        STOSW
        RET

GETMNE:
        CALL    GETMODE
        MOV     DL,AL
        CBW
        SHL     AX,1
        ADD     BX,AX
        MOV     AX,[BX]
        MOV     [OPCODE],AX
        MOV     AL,DL
        RET

GRP1:
        MOV     BX,OFFSET DG:GRP1TAB
        CALL    GETMNE
        OR      AL,AL
        JZ      FINIMMJ
        JMP     TESTREG
FINIMMJ:
        JMP     FINIMM

GRP2:
        MOV     BX,OFFSET DG:GRP2TAB
        CALL    GETMNE
        CMP     AL,2
        JB      TESTREG
        CMP     AL,6
        JAE     INDIRECT
        TEST    AL,1
        JZ      INDIRECT
        MOV     AX,"AF"                 ; "FAR"
        STOSW
        MOV     AX," R"
        STOSW
INDIRECT:
        JMP     ADDRMOD

CODE    ENDS
        END     UNASSEM
                                                                                                                    