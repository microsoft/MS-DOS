TITLE   COMMAND Initialization

        INCLUDE COMSW.ASM

.xlist
.xcref
        INCLUDE DOSSYM.ASM
        INCLUDE DEVSYM.ASM
        INCLUDE COMSEG.ASM
.list
.cref

        INCLUDE COMEQU.ASM

ENVIRONSIZ EQU  0A0H            ;Must agree with values in EVIRONMENT segment
ENVIRONSIZ2 EQU 092H

CODERES SEGMENT PUBLIC
        EXTRN   RSTACK:WORD,SETVECT:NEAR,LODCOM:NEAR,CONTC:NEAR,INT_2E:NEAR
        EXTRN   LOADCOM:NEAR,CHKSUM:NEAR

        IF      IBMVER
        EXTRN   EXECHK:NEAR,SYSCALL:NEAR
        ENDIF

CODERES ENDS

DATARES SEGMENT PUBLIC
        EXTRN   DATARESEND:BYTE,LTPA:WORD,MYSEG:WORD,MYSEG1:WORD,MYSEG2:WORD
        EXTRN   MEMSIZ:WORD,TRNSEG:WORD,ENVIRSEG:WORD,RSWITCHAR:BYTE
        EXTRN   COMDRV:BYTE,COMLET:BYTE,PERMCOM:BYTE,SINGLECOM:WORD
        EXTRN   PARENT:WORD,IO_SAVE:WORD,COM_PTR:DWORD,COM_FCB1:DWORD
        EXTRN   COM_FCB2:DWORD,SUM:WORD,BATCH:WORD,COMSPEC:BYTE

        IF      IBMVER
        EXTRN   SYS_CALL:DWORD,EXESEG:WORD,EXESUM:WORD
        ENDIF

DATARES ENDS

ENVIRONMENT SEGMENT PUBLIC
        EXTRN   ENVIREND:BYTE,PATHSTRING:BYTE,ECOMSPEC:BYTE
ENVIRONMENT ENDS

TRANCODE        SEGMENT PUBLIC
        EXTRN   DATINIT:FAR
TRANCODE        ENDS

TRANSPACE       SEGMENT PUBLIC
        EXTRN   TRANSPACEEND:BYTE
TRANSPACE       ENDS

ZEXEC_DATA      SEGMENT PUBLIC
        IF      IBM
        EXTRN   ZEXECDATAEND:BYTE
        ENDIF
ZEXEC_DATA      ENDS

; *******************************************************************
; START OF INIT PORTION
; This code is overlayed the first time the TPA is used.

INIT    SEGMENT PUBLIC PARA

        EXTRN   HEADER:BYTE
        EXTRN   BADCOMLKMES:BYTE

        PUBLIC  CONPROC

ASSUME  CS:RESGROUP,DS:RESGROUP,ES:RESGROUP,SS:RESGROUP

        ORG     0
ZERO    =       $

CONPROC:
        MOV     SP,OFFSET RESGROUP:RSTACK

        IF      HIGHMEM
        MOV     BX,WORD PTR DS:[PDB_block_len]
        MOV     AX,OFFSET RESGROUP:ENVIREND + 15
        MOV     CL,4
        SHR     AX,CL
        PUSH    AX                         ; Save size to alloc
        INC     AX                         ; Plus one for arena
        SUB     BX,AX                      ; Subtract size of resident
        MOV     WORD PTR DS:[PDB_block_len],BX
        MOV     AX,CS
        SUB     BX,AX
        MOV     AH,SETBLOCK
        INT     21H
        POP     BX                          ; Get back size to alloc
        MOV     AH,ALLOC
        INT     21H
        MOV     [REALRES],AX
        MOV     ES,AX
        XOR     SI,SI
        MOV     DI,SI
        MOV     CX,OFFSET RESGROUP:ENVIREND
        SHR     CX,1          ; Length of resident and environment in words
                              ; Last byte doesn't matter
        REP     MOVSW                   ; Move to end of memory
        MOV     DS,AX
        MOV     BX,AX
        MOV     AH,SET_CURRENT_PDB
        INT     21H
        MOV     AX,BX
        MOV     BX,OFFSET RESGROUP:DATARESEND + 15
        MOV     CL,4
        SHR     BX,CL           ; BX is size for SETBLOCK
        MOV     WORD PTR DS:[PDB_block_len],BX
        ADD     WORD PTR DS:[PDB_block_len],AX
        MOV     [LTPA],CS
        MOV     AH,SETBLOCK
        INT     21H             ;Shrink to not include environment
        MOV     BX,(ENVIRONSIZ + 15) / 16
        MOV     AH,ALLOC
        INT     21H             ;Allocate the environment
        MOV     [ENVIRSEG],AX
        MOV     CS:[ENVIRSEGSAV],AX
        MOV     ES,AX
ASSUME  ES:ENVIRONMENT
        XOR     DI,DI
        MOV     SI,OFFSET RESGROUP:PATHSTRING
        MOV     CX,ENVIRONSIZ
        REP     MOVSB
        MOV     AX,WORD PTR CS:[PDB_block_len]
        ENDIF

        IF      NOT HIGHMEM
        MOV     AX,OFFSET RESGROUP:ENVIREND + 15
        MOV     CL,4
        SHR     AX,CL
        MOV     CX,CS
        ADD     AX,CX                         ; Compute segment of TPA
        MOV     [LTPA],AX                     ; Good enough for the moment
        MOV     AX,WORD PTR DS:[PDB_block_len]
        ENDIF

        MOV     [MYSEG1],DS
        MOV     [MYSEG2],DS
        MOV     [MYSEG],DS
        MOV     [MEMSIZ],AX

        MOV     DX,OFFSET TRANGROUP:TRANSPACEEND + 15
        MOV     CL,4
        SHR     DX,CL

        IF      IBM
        PUSH    DX
        MOV     DX,OFFSET EGROUP:ZEXECDATAEND + 15
        MOV     CL,4
        SHR     DX,CL
        POP     CX
        ADD     DX,CX
        ENDIF

        SUB     AX,DX
        MOV     [TRNSEG],AX                     ; Read it in here
        MOV     AX,DS:[PDB_environ]
        OR      AX,AX
        JZ      BUILDENV                        ; Need to make an environment

        IF      HIGHMEM
        INC     BYTE PTR CS:[CHUCKENV]          ; Flag no ENVIRONSEG
        ELSE
        INC     BYTE PTR [CHUCKENV]             ; Flag no ENVIRONSEG
        ENDIF

        JMP     SHORT ENVIRONPASSED

BUILDENV:

        IF      NOT HIGHMEM
        MOV     AX,OFFSET RESGROUP:PATHSTRING   ; Figure environment pointer
        MOV     CL,4
        SHR     AX,CL
        MOV     DX,DS
        ADD     AX,DX
        ELSE
        JMP     SHORT GOTTHEENVIR
        ENDIF

ENVIRONPASSED:
        MOV     [ENVIRSEG],AX

        IF      HIGHMEM
        DEC     AX
        MOV     ES,AX
        INC     AX
        MOV     ES:[arena_owner],DS             ; Adjust owner of passed envir
        ENDIF

        MOV     ES,AX
ASSUME  ES:ENVIRONMENT

GOTTHEENVIR:
        MOV     AX,CHAR_OPER SHL 8
        INT     int_command
        MOV     [RSWITCHAR],DL

        CMP     DL,'/'
        JNZ     IUSESLASH

        IF      HIGHMEM
        MOV     CS:[COMSPECT],'\'
        ELSE
        MOV     [COMSPECT],'\'
        ENDIF

        IF      HIGHMEM
        CMP     BYTE PTR CS:[CHUCKENV],0
        ELSE
        CMP     BYTE PTR [CHUCKENV],0
        ENDIF

        JNZ     IUSESLASH

        MOV     ES:[ECOMSPEC-10H],'\'
IUSESLASH:

IF IBMVER
        PUSH    ES
        MOV     AX,(Get_interrupt_vector SHL 8) + int_command
        INT     int_command
        MOV     WORD PTR [SYS_CALL],BX
        MOV     WORD PTR [SYS_CALL+2],ES
        MOV     DX,OFFSET RESGROUP:SYSCALL
        MOV     AX,(Set_interrupt_vector SHL 8) + int_command
        INT     int_command
        POP     ES
ENDIF

        MOV     AL,BYTE PTR DS:[FCB]         ; get drive spec for default
        MOV     AH,DRVCHAR
        MOV     [COMDRV],AL
        ADD     AL,40H                  ; Convert to letter
        CMP     AL,40H
        JZ      NOCOMDRV
        STD
        IF      HIGHMEM
        CMP     BYTE PTR CS:[CHUCKENV],0
        ELSE
        CMP     BYTE PTR [CHUCKENV],0
        ENDIF

        JNZ     NOTWIDENV

        PUSH    DS
        PUSH    ES
        POP     DS
        MOV     DI,OFFSET ENVIRONMENT:ECOMSPEC + ENVIRONSIZ2 - 1 - 10H
        MOV     SI,OFFSET ENVIRONMENT:ECOMSPEC + ENVIRONSIZ2 - 3 - 10H
        MOV     CX,ENVIRONSIZ2 - 2
        REP     MOVSB

        POP     DS
        MOV     WORD PTR ES:[ECOMSPEC-10H],AX

NOTWIDENV:
        CLD
        IF      HIGHMEM
        MOV     WORD PTR CS:[AUTOBAT],AX
        ELSE
        MOV     WORD PTR [AUTOBAT],AX
        ENDIF

        MOV     [COMLET],AL
NOCOMDRV:
        CALL    SETVECT         ; Set the vectors

        MOV     SI,80H
        LODSB
        MOV     CL,AL
        XOR     CH,CH
        JCXZ    COMRETURNSJ     ; No parameters
        MOV     SI,81H          ; Start of parms
CHKARG:
        LODSB
        CMP     AL,' '
        JZ      NEXTCH
        CMP     AL,9            ; Tab only other delimiter
        JZ      NEXTCH
        CMP     AL,[RSWITCHAR]   ; Switch?
        JNZ     CHKOTHERARGS    ; No
        DEC     CX
        JCXZ    ARGSDONEJ       ; oops
        LODSB
        OR      AL,20H          ; Lower case
        CMP     AL,'p'          ; PERMCOM switch
        JNZ     NEXTCH
        JMP     SETPERM

NEXTCH:
        CMP     AL,'d'
        JNZ     NEXTCH3

        IF      HIGHMEM
        MOV     BYTE PTR CS:[PRDATTM],1  ; User explicitly says no date time
        ELSE
        MOV     BYTE PTR [PRDATTM],1     ; User explicitly says no date time
        ENDIF

        LOOP    CHKARG
        JMP     SHORT ARGSDONEJ
NEXTCH3:
        CMP     AL,'c'
        JNZ     NEXTCH2         ; SINGLECOM switch 2
        MOV     [SINGLECOM],SI  ; Point to the rest of the command line
        MOV     [PERMCOM],0     ; A SINGLECOM must not be a PERMCOM

        IF      HIGHMEM
        MOV     BYTE PTR CS:[PRDATTM],1  ; No date or time either, explicit
        ELSE
        MOV     BYTE PTR [PRDATTM],1     ; No date or time either, explicit
        ENDIF

ARGSDONEJ:
        JMP  ARGSDONE

NEXTCH2:
        LOOP    CHKARG

COMRETURNSJ:
        JMP COMRETURNS

CHKOTHERARGS:
        DEC     SI
        MOV     DX,SI
        PUSH    CX
        PUSH    SI
CONTRLOOP:
        LODSB
        DEC     CX
        CMP     AL,' '
        JZ      SETCDEV
        CMP     AL,9
        JZ      SETCDEV
        JCXZ    SETCDEVA
        JMP     SHORT CONTRLOOP

SETCDEVA:
        INC     SI
SETCDEV:
        MOV     BYTE PTR [SI-1],0
        MOV     AX,(OPEN SHL 8) OR 2    ; Read and write
        INT     int_command
        JC      CHKSRCHSPEC             ; Wasn't a file
        MOV     BX,AX
        MOV     AX,IOCTL SHL 8
        INT     int_command
        TEST    DL,80H
        JNZ     ISADEVICE
        MOV     AH,CLOSE       ; Close initial handle, wasn't a device
        INT     int_command
        JMP     CHKSRCHSPEC

ISADEVICE:
        XOR     DH,DH
        OR      DL,3            ; Make sure has CON attributes
        MOV     AX,(IOCTL SHL 8) OR 1
        INT     int_command
        MOV     DX,BX           ; Save new handle
        POP     BX              ; Throw away saved SI
        POP     BX              ; Throw away saved CX
        PUSH    CX
        MOV     CX,3
        XOR     BX,BX
RCCLLOOP:                                ; Close 0,1 and 2
        MOV     AH,CLOSE
        INT     int_command
        INC     BX
        LOOP    RCCLLOOP
        MOV     BX,DX           ; New device handle
        MOV     AH,XDUP
        INT     int_command             ; Dup to 0
        MOV     AH,XDUP
        INT     int_command             ; Dup to 1
        MOV     AH,XDUP
        INT     int_command             ; Dup to 2
        MOV     AH,CLOSE
        INT     int_command             ; Close initial handle
        POP     CX
        JCXZ    ARGSDONEJ2
        JMP     CHKARG

CHKSRCHSPEC:                    ; Not a device, so must be directory spec

        IF      HIGHMEM
        MOV     BYTE PTR CS:[CHUCKENV],0    ; If search specified -- no inheritance
        MOV     AX,CS:[ENVIRSEGSAV]
        MOV     [ENVIRSEG],AX
        ELSE
        MOV     BYTE PTR [CHUCKENV],0    ; If search specified -- no inheritance
        MOV     AX,OFFSET RESGROUP:PATHSTRING   ; Figure environment pointer
        MOV     CL,4
        SHR     AX,CL
        MOV     DX,DS
        ADD     AX,DX
        MOV     [ENVIRSEG],AX
        ENDIF

        MOV     ES,AX
        MOV     BYTE PTR [SI-1],' '
        POP     SI                      ; Remember location
        POP     CX                      ; and count

        IF      HIGHMEM
        MOV     DI,CS:[ECOMLOC]
        ELSE
        MOV     DI,[ECOMLOC]
        ENDIF

COMTRLOOP:
        LODSB
        DEC     CX
        CMP     AL,' '
        JZ      SETCOMSR
        CMP     AL,9
        JZ      SETCOMSR
        STOSB

        IF      KANJI
        XOR     AH,AH
        ENDIF

        JCXZ    SETCOMSR

        IF      KANJI
        CALL    ITESTKANJ
        JZ      COMTRLOOP
        DEC     CX
        MOVSB
        INC     AH
        JCXZ    SETCOMSR
        ENDIF

        JMP     SHORT COMTRLOOP

SETCOMSR:
        PUSH    SI
        PUSH    CX

        PUSH    DS

        IF      HIGHMEM
        PUSH    CS
        POP     DS
        ENDIF

        MOV     SI,OFFSET RESGROUP:COMSPECT
        MOV     CX,14

        MOV     AL,ES:[DI-1]

        IF      KANJI
        OR      AH,AH
        JNZ     INOTROOT        ; Last char was KANJI second byte, might be '\'
        ENDIF

        CALL    PATHCHRCMPR
        JNZ     INOTROOT
        INC     SI              ; Don't make a double /
        DEC     CX
INOTROOT:
        REP     MOVSB

        MOV     DX,[ECOMLOC]    ; Now lets make sure its good!
        PUSH    ES
        POP     DS

        MOV     AX,OPEN SHL 8
        INT     int_command             ; Open COMMAND.COM
        POP     DS
        JC      SETCOMSRBAD     ; No COMMAND.COM here
        MOV     BX,AX           ; Handle
        MOV     AH,CLOSE
        INT     int_command             ; Close COMMAND.COM
SETCOMSRRET:
        POP     CX
        POP     SI
ARGSDONEJ2:
        JCXZ    ARGSDONE
        JMP     CHKARG

SETCOMSRBAD:

        IF      HIGHMEM
        PUSH    DS
        PUSH    CS
        POP     DS
        ENDIF

        MOV     DX,OFFSET RESGROUP:BADCOMLKMES
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     int_command
        MOV     SI,OFFSET RESGROUP:COMSPECT
        MOV     DI,[ECOMLOC]
        MOV     CX,14
        REP     MOVSB           ; Get my default back

        IF      HIGHMEM
        POP     DS
        ENDIF

        JMP     SHORT SETCOMSRRET

CHKARGJ:
        JMP    CHKARG

SETPERM:
        INC     [PERMCOM]

        IF      HIGHMEM
        CMP     BYTE PTR CS:[PRDATTM],-1
        ELSE
        CMP     BYTE PTR [PRDATTM],-1
        ENDIF

        JNZ     LOOPIT

        IF      HIGHMEM
        MOV     BYTE PTR CS:[PRDATTM],0          ; If not set explicit, set to prompt
        ELSE
        MOV     BYTE PTR [PRDATTM],0             ; If not set explicit, set to prompt
        ENDIF

LOOPIT:
        LOOP    CHKARGJ
ARGSDONE:
        CMP     [PERMCOM],0
        JZ      COMRETURNS
        PUSH    ES                      ; Save environment pointer
        MOV     AH,SET_CURRENT_PDB
        MOV     BX,DS
        MOV     ES,BX
        INT     int_command                     ; Current process is me
        MOV     DI,PDB_Exit             ; Diddle the addresses in my header
        MOV     AX,OFFSET RESGROUP:LODCOM
        STOSW
        MOV     AX,DS
        STOSW
        MOV     AX,OFFSET RESGROUP:CONTC
        STOSW
        MOV     AX,DS
        STOSW
        MOV     WORD PTR DS:[PDB_Parent_PID],DS ; Parent is me forever
        MOV     DX,OFFSET RESGROUP:INT_2E
        MOV     AX,(SET_INTERRUPT_VECTOR SHL 8) OR 02EH
        INT     int_command                     ;Set magic interrupt
        POP     ES                              ;Remember environment
COMRETURNS:
        MOV     AX,WORD PTR DS:[PDB_Parent_PID]
        MOV     [PARENT],AX                     ; Save parent
        MOV     WORD PTR DS:[PDB_Parent_PID],DS ; Parent is me
        MOV     AX,WORD PTR DS:[PDB_JFN_Table]
        MOV     [IO_SAVE],AX                    ; Get the default stdin and out
        MOV     WORD PTR [COM_PTR+2],DS         ; Set all these to resident
        MOV     WORD PTR [COM_FCB1+2],DS
        MOV     WORD PTR [COM_FCB2+2],DS
        MOV     DI,OFFSET RESGROUP:COMSPEC

        IF      HIGHMEM
        MOV     SI,CS:[ECOMLOC]
        CMP     BYTE PTR CS:[CHUCKENV],0
        ELSE
        MOV     SI,[ECOMLOC]
        CMP     BYTE PTR [CHUCKENV],0
        ENDIF

        MOV     AX,DS                   ; XCHG ES,DS
        PUSH    ES
        POP     DS
        MOV     ES,AX

        JZ      COPYCOMSP               ; All set up for copy

        PUSH    CS
        POP     DS

        MOV     SI,OFFSET RESGROUP:COMSPSTRING
        PUSH    ES
        PUSH    DI
        CALL    IFINDE
        MOV     SI,DI
        PUSH    ES
        POP     DS
        POP     DI
        POP     ES
        JNC     COPYCOMSP
COMSPECNOFND:

        IF      HIGHMEM
        MOV     DS,CS:[ENVIRSEG]
        MOV     SI,CS:[ECOMLOC]
        ELSE
        MOV     SI,[ECOMLOC]
        ADD     SI,OFFSET RESGROUP:PATHSTRING
        PUSH    CS
        POP     DS
        ENDIF

COPYCOMSP:
        LODSB
        STOSB
        OR      AL,AL
        JNZ     COPYCOMSP

        IF      HIGHMEM
        MOV     DS,CS:[REALRES]
        PUSH    CS
        POP     ES
        MOV     AH,DEALLOC
        INT     21H
        CMP     BYTE PTR CS:[CHUCKENV],0
        JZ      GOTENVIR                ; Environment is ok
        MOV     ES,CS:[ENVIRSEGSAV]
        MOV     AH,DEALLOC
        INT     21H
        ELSE
        PUSH    CS
        POP     DS
        MOV     BX,OFFSET RESGROUP:DATARESEND + 15
        MOV     CL,4
        SHR     BX,CL
        MOV     AH,SETBLOCK
        INT     int_command                     ; Shrink me to the resident only
        CMP     BYTE PTR [CHUCKENV],0
        JNZ     GOTENVIR                ; Environment was passed
        MOV     BX,(ENVIRONSIZ + 15) /16
        MOV     AH,ALLOC
        INT     int_command                     ; "ALLOCATE" the environment
        MOV     DS,[ENVIRSEG]
        MOV     [ENVIRSEG],AX
        MOV     ES,AX
        XOR     SI,SI
        MOV     DI,SI
        MOV     CX,ENVIRONSIZ
        REP     MOVSB
        PUSH    CS
        POP     DS
        ENDIF

GOTENVIR:
        CALL    LOADCOM                 ; Load the transient in the right place
        CALL    CHKSUM                  ; Compute the checksum
        MOV     [SUM],DX                ; Save it
IF IBM
        MOV     AX,[MEMSIZ]
        MOV     DX,OFFSET EGROUP:ZEXECDATAEND + 15
        MOV     CL,4
        SHR     DX,CL
        SUB     AX,DX
        MOV     [EXESEG],AX
        CALL    EXECHK
        MOV     [EXESUM],DX
ENDIF
        IF MSVER
        CMP     [SINGLECOM],0
        JNZ     NOPHEAD                 ; Don't print header if SINGLECOM
        IF      HIGHMEM
        PUSH    DS
        PUSH    CS
        POP     DS
        ENDIF
        MOV     DX,OFFSET RESGROUP:HEADER
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     int_command
        IF      HIGHMEM
        POP     DS
        ENDIF
NOPHEAD:
        ENDIF

        IF      HIGHMEM
        CMP     BYTE PTR CS:[PRDATTM],0
        ELSE
        CMP     BYTE PTR [PRDATTM],0
        ENDIF

        JNZ     NODTTM                  ; Don't do AUTOEXEC or date time
        MOV     BX,3                    ; 48 BYTES ENOUGH
        MOV     AH,ALLOC
        INT     int_command
        JC      DODTTM                  ; PRETEND NO BATCH
        MOV     [BATCH],AX
        MOV     ES,AX
        XOR     DI,DI

        IF      HIGHMEM
        CMP     BYTE PTR CS:[AUTOBAT],0
        ELSE
        CMP     BYTE PTR [AUTOBAT],0
        ENDIF

        JNZ     NOAUTSET
        MOV     AH,GET_DEFAULT_DRIVE
        INT     int_command
        ADD     AL,'A'

        IF      HIGHMEM
        MOV     CS:[AUTOBAT],AL
        ELSE
        MOV     [AUTOBAT],AL
        ENDIF

NOAUTSET:

        IF      HIGHMEM
        PUSH    DS
        PUSH    CS
        POP     DS
        ENDIF

        MOV     SI,OFFSET RESGROUP:AUTOBAT
        MOV     CX,8
        REP     MOVSW   ; NAME
        MOV     AX,-1
        MOV     CL,10
        REP     STOSW   ; PARMS
        MOV     DX,OFFSET RESGROUP:AUTOBAT
        MOV     AX,OPEN SHL 8
        INT     int_command                      ; See if AUTOEXEC.BAT exists
        JC      NOABAT
        MOV     BX,AX
        MOV     AH,CLOSE
        INT     int_command

        IF      HIGHMEM
        POP     DS
        ENDIF

        JMP     SHORT DRV0

NOABAT:

        IF      HIGHMEM
        POP     DS
        ENDIF

        MOV     ES,[BATCH]      ; Not found--turn off batch job
        MOV     AH,DEALLOC
        INT     int_command
        MOV     [BATCH],0       ; AFTER DEALLOC in case of ^C
DODTTM:

        IF      HIGHMEM
        MOV     AX,OFFSET TRANGROUP:DATINIT
        MOV     WORD PTR CS:[INITADD],AX
        MOV     AX,[TRNSEG]
        MOV     WORD PTR CS:[INITADD+2],AX
        CALL    DWORD PTR CS:[INITADD]
        ELSE
        MOV     AX,OFFSET TRANGROUP:DATINIT
        MOV     WORD PTR[INITADD],AX
        MOV     AX,[TRNSEG]
        MOV     WORD PTR[INITADD+2],AX
        CALL    DWORD PTR [INITADD]
        ENDIF

NODTTM:

        IF IBMVER
        CMP     [SINGLECOM],0
        JNZ     DRV0                    ; Don't print header if SINGLECOM
        MOV     DX,OFFSET RESGROUP:HEADER
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     int_command
        ENDIF

DRV0:
        IF      HIGHMEM
        PUSH    DS
        MOV     AX,OFFSET RESGROUP:LODCOM
        PUSH    AX
MQQ     PROC    FAR
        RET
MQQ     ENDP
        ELSE
        JMP     LODCOM                  ; Allocate the transient
        ENDIF

PATHCHRCMPR:
        CMP     [RSWITCHAR],'/'
        JZ      RNOSLASHT
        CMP     AL,'/'
        JZ      RET41
RNOSLASHT:
        CMP     AL,'\'
RET41:
        RET


IFINDE:
        CALL    IFIND                    ; FIND THE NAME
        JC      IFIND2                   ; CARRY MEANS NOT FOUND
        JMP     ISCASB1                  ; SCAN FOR = SIGN
;
; On return of FIND1, ES:DI points to beginning of name
;
IFIND:
        CLD

        CALL    ICOUNT0                  ; CX = LENGTH OF NAME

        IF      HIGHMEM
        MOV     ES,CS:[REALRES]
ASSUME  ES:RESGROUP
        MOV     ES,ES:[ENVIRSEG]
ASSUME  ES:NOTHING
        ELSE
        MOV     ES,[ENVIRSEG]
        ENDIF

        XOR     DI,DI
IFIND1:
        PUSH    CX
        PUSH    SI
        PUSH    DI
IFIND11:
        LODSB

        IF      KANJI
        CALL    ITESTKANJ
        JZ      NOTKANJ4
        DEC     SI
        LODSW
        INC     DI
        INC     DI
        CMP     AX,ES:[DI-2]
        JNZ     IFIND12
        DEC     CX
        LOOP    IFIND11
        JMP     SHORT IFIND12

NOTKANJ4:
        ENDIF

        CALL    IUPCONV
        INC     DI
        CMP     AL,ES:[DI-1]
        JNZ     IFIND12
        LOOP    IFIND11
IFIND12:
        POP     DI
        POP     SI
        POP     CX
        JZ      IFIND2
        PUSH    CX
        CALL    ISCASB2                  ; SCAN FOR A NUL
        POP     CX
        CMP     BYTE PTR ES:[DI],0
        JNZ     IFIND1
        STC                             ; INDICATE NOT FOUND
IFIND2:
        RET

ICOUNT0:
        PUSH    DS
        POP     ES
        MOV     DI,SI

        PUSH    DI                      ; COUNT NUMBER OF CHARS UNTIL "="
        CALL    ISCASB1
        JMP     SHORT ICOUNTX
        PUSH    DI                      ; COUNT NUMBER OF CHARS UNTIL NUL
        CALL    ISCASB2
ICOUNTX:
        POP     CX
        SUB     DI,CX
        XCHG    DI,CX
        RET

ISCASB1:
        MOV     AL,"="                  ; SCAN FOR AN =
        JMP     SHORT ISCASBX
ISCASB2:
        XOR     AL,AL                   ; SCAN FOR A NUL
ISCASBX:
        MOV     CX,100H
        REPNZ   SCASB
        RET

        IF      KANJI
ITESTKANJ:
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

IUPCONV:
        CMP     AL,"a"
        JB      IRET22
        CMP     AL,"z"
        JA      IRET22
        SUB     AL,20H          ; Lower-case changed to upper-case
IRET22:
        RET

ICONDEV LABEL BYTE
        DB      "/DEV/"
        DB      "CON",0,0,0,0,0,0          ; Room for 8 char device
BADCSPFL DB     0
COMSPECT DB     "/COMMAND.COM",0,0
AUTOBAT DB      0,":\AUTOEXEC.BAT",0

PRDATTM DB      -1                      ;Init not to prompt for date time
INITADD DD      ?
CHUCKENV DB     0
ECOMLOC DW      OFFSET ENVIRONMENT:ECOMSPEC-10H

        IF      HIGHMEM
REALRES DW      ?
ENVIRSEGSAV DW  ?
        ENDIF

COMSPSTRING DB  "COMSPEC="


INIT    ENDS

        END
                                                              