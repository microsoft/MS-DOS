;
; ^C status routines for MSDOS
;

INCLUDE DOSSEG.ASM

CODE    SEGMENT BYTE PUBLIC  'CODE'
        ASSUME  SS:DOSGROUP,CS:DOSGROUP

.xlist
.xcref
INCLUDE DOSSYM.ASM
INCLUDE DEVSYM.ASM
.cref
.list

        i_need  DevIOBuf,BYTE
        i_need  DidCTRLC,BYTE
        i_need  INDOS,BYTE
        i_need  DSKSTCOM,BYTE
        i_need  DSKSTCALL,BYTE
        i_need  DSKSTST,WORD
        i_need  BCON,DWORD
        i_need  DSKCHRET,BYTE
        i_need  DSKSTCNT,WORD
        i_need  IDLEINT,BYTE
        i_need  CONSWAP,BYTE
        i_need  user_SS,WORD
        i_need  user_SP,WORD
        i_need  ERRORMODE,BYTE
        i_need  ConC_spSave,WORD
        i_need  Exit_type,BYTE
        i_need  PFLAG,BYTE
        i_need  ExitHold,DWORD
        i_need  WPErr,BYTE
        i_need  ReadOp,BYTE
        i_need  CONTSTK,WORD
        i_need  Exit_Code,WORD
        i_need  CurrentPDB,WORD
        i_need  DIVMES,BYTE
        i_need  DivMesLen,BYTE

SUBTTL Checks for ^C in CON I/O
PAGE
ASSUME  DS:NOTHING,ES:NOTHING

        procedure   DSKSTATCHK,NEAR ; Check for ^C if only one level in
        CMP     BYTE PTR [INDOS],1
        retnz                   ; Do NOTHING
        PUSH    CX
        PUSH    ES
        PUSH    BX
        PUSH    DS
        PUSH    SI
        PUSH    CS
        POP     ES
        PUSH    CS
        POP     DS
ASSUME  DS:DOSGROUP
        XOR     CX,CX
        MOV     BYTE PTR [DSKSTCOM],DEVRDND
        MOV     BYTE PTR [DSKSTCALL],DRDNDHL
        MOV     [DSKSTST],CX
        MOV     BX,OFFSET DOSGROUP:DSKSTCALL
        LDS     SI,[BCON]
ASSUME  DS:NOTHING
        invoke  DEVIOCALL2
        TEST    [DSKSTST],STBUI
        JNZ     ZRET                    ; No characters available
        MOV     AL,BYTE PTR [DSKCHRET]
DSK1:
        CMP     AL,"C"-"@"
        JNZ     RET36
        MOV     BYTE PTR [DSKSTCOM],DEVRD
        MOV     BYTE PTR [DSKSTCALL],DRDWRHL
        MOV     BYTE PTR [DSKCHRET],CL
        MOV     [DSKSTST],CX
        INC     CX
        MOV     [DSKSTCNT],CX
        invoke  DEVIOCALL2              ; Eat the ^C
        POP     SI
        POP     DS
        POP     BX                      ; Clean stack
        POP     ES
        POP     CX
        JMP     SHORT CNTCHAND

ZRET:
        XOR     AL,AL                   ; Set zero
RET36:
        POP     SI
        POP     DS
        POP     BX
        POP     ES
        POP     CX
        return

NOSTOP:
        CMP     AL,"P"-"@"
        JZ      INCHK

        IF      NOT TOGLPRN
        CMP     AL,"N"-"@"
        JZ      INCHK
        ENDIF

        CMP     AL,"C"-"@"
        JZ      INCHK
        return
DSKSTATCHK  ENDP

        procedure   SPOOLINT,NEAR
        PUSHF
        CMP     BYTE PTR [IDLEINT],0
        JZ      POPFRET
        CMP     BYTE PTR [ERRORMODE],0
        JNZ     POPFRET                 ;No spool ints in error mode
        INT     int_spooler
POPFRET:
        POPF
RET18:  return
SPOOLINT    ENDP

        procedure   STATCHK,NEAR

        invoke  DSKSTATCHK              ; Allows ^C to be detected under
                                        ; input redirection
        PUSH    BX
        XOR     BX,BX
        invoke  GET_IO_FCB
        POP     BX
        JC      RET18
        MOV     AH,1
        invoke  IOFUNC
        JZ      SPOOLINT
        CMP     AL,'S'-'@'
        JNZ     NOSTOP
        XOR     AH,AH
        invoke  IOFUNC                  ; Eat Cntrl-S
        JMP     SHORT PAUSOSTRT
PRINTOFF:
PRINTON:
        NOT     BYTE PTR [PFLAG]
        return

PAUSOLP:
        CALL    SPOOLINT
PAUSOSTRT:
        MOV     AH,1
        invoke  IOFUNC
        JZ      PAUSOLP
INCHK:
        PUSH    BX
        XOR     BX,BX
        invoke  GET_IO_FCB
        POP     BX
        JC      RET18
        XOR     AH,AH
        invoke  IOFUNC
        CMP     AL,'P'-'@'
        JZ      PRINTON
        IF      NOT TOGLPRN
        CMP     AL,'N'-'@'
        JZ      PRINTOFF
        ENDIF
        CMP     AL,'C'-'@'
        retnz
STATCHK ENDP

        procedure   CNTCHAND,NEAR
; Ctrl-C handler.
; "^C" and CR/LF is printed.  Then the user registers are restored and
; the user CTRL-C handler is executed.  At this point the top of the stack
; has 1) the interrupt return address should the user CTRL-C handler wish
; to allow processing to continue; 2) the original interrupt return address
; to the code that performed the function call in the first place.  If
; the user CTRL-C handler wishes to continue, it must leave all registers
; unchanged and RET (not IRET) with carry CLEAR.  If carry is SET then
; an terminate system call is simulated.
        MOV     AL,3                ; Display "^C"
        invoke  BUFOUT
        invoke  CRLF
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        CMP     BYTE PTR [CONSWAP],0
        JZ      NOSWAP
        invoke  SWAPBACK
NOSWAP:
        CLI                         ; Prepare to play with stack
        MOV     SP,[user_SP]
        MOV     SS,[user_SS]        ; User stack now restored
ASSUME  SS:NOTHING
        invoke  restore_world       ; User registers now restored
ASSUME  DS:NOTHING
        MOV     BYTE PTR [INDOS],0  ; Go to known state
        MOV     BYTE PTR [ERRORMODE],0
        MOV     [ConC_spsave],SP    ; save his SP
        INT     int_ctrl_c          ; Execute user Ctrl-C handler
        MOV     [user_SS],AX        ; save the AX
        PUSHF                       ; and the flags (maybe new call)
        POP     AX
        CMP     SP,[ConC_spsave]
        JNZ     ctrlc_try_new       ; new syscall maybe?
ctrlc_repeat:
        MOV     AX,[user_SS]        ; no...
        transfer    COMMAND         ; Repeat command otherwise

ctrlc_try_new:
        SUB     [ConC_spsave],2     ; Are there flags on the stack?
        CMP     SP,[ConC_spsave]
        JZ      ctrlc_new           ; yes, new system call

ctrlc_abort:
        MOV     AX,(EXIT SHL 8) + 0
        MOV     BYTE PTR [DidCTRLC],0FFh

        transfer    COMMAND         ; give up by faking $EXIT

ctrlc_new:
        PUSH    AX
        POPF
        POP     [user_SS]
        JNC     ctrlc_repeat        ; repeat operation
        JMP     ctrlc_abort         ; indicate ^ced

CNTCHAND ENDP

SUBTTL DIVISION OVERFLOW INTERRUPT
PAGE
; Default handler for division overflow trap
        procedure   DIVOV,NEAR
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        MOV     SI,OFFSET DOSGROUP:DIVMES
        CALL    RealDivOv
        JMP     ctrlc_abort     ; Use Ctrl-C abort on divide overflow
DIVOV   ENDP

;
; RealDivOv: perform actual divide overflow stuff.
; Inputs:   none
; Outputs:  message to BCON
;
        procedure   RealDivOv,NEAR  ; Do divide overflow and clock process

        PUSH    CS                  ; get ES addressability
        POP     ES

        PUSH    CS                  ; get DS addressability
        POP     DS
ASSUME  DS:DOSGROUP

        MOV     BYTE PTR [DskStCom],DevWrt
        MOV     BYTE PTR [DskStCall],DRdWrHL
        MOV     [DskSTST],0
        MOV     BL,[DivMesLen]
        XOR     BH,BH
        MOV     [DskStCnt],BX
        MOV     BX,OFFSET DOSGROUP:DskStCall
        MOV     WORD PTR [DskChRet+1],SI    ; transfer address (need an EQU)
        LDS     SI,[BCON]
ASSUME  DS:NOTHING
        invoke  DEVIOCALL2
        MOV     WORD PTR [DskChRet+1],OFFSET DOSGROUP:DevIOBuf
        MOV     [DskStCnt],1
        return
RealDivOv   ENDP

SUBTTL CHARHRD,HARDERR,ERROR -- HANDLE DISK ERRORS AND RETURN TO USER
PAGE
        procedure   CHARHARD,NEAR
ASSUME  DS:NOTHING,ES:NOTHING,SS:DOSGROUP

; Character device error handler
; Same function as HARDERR

        MOV     WORD PTR [EXITHOLD+2],ES
        MOV     WORD PTR [EXITHOLD],BP
        PUSH    SI
        AND     DI,STECODE
        MOV     BP,DS                   ;Device pointer is BP:SI
        CALL    FATALC
        POP     SI
        return
CHARHARD    ENDP

        procedure   HardErr,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Hard disk error handler. Entry conditions:
;       DS:BX = Original disk transfer address
;       DX = Original logical sector number
;       CX = Number of sectors to go (first one gave the error)
;       AX = Hardware error code
;       DI = Original sector transfer count
;       ES:BP = Base of drive parameters
;       [READOP] = 0 for read, 1 for write
                                        ;
        XCHG    AX,DI                   ; Error code in DI, count in AX
        AND     DI,STECODE              ; And off status bits
        CMP     DI,WRECODE              ; Write Protect Error?
        JNZ     NOSETWRPERR
        PUSH    AX
        MOV     AL,ES:[BP.dpb_drive]
        MOV     BYTE PTR [WPERR],AL              ; Flag drive with WP error
        POP     AX
NOSETWRPERR:
        SUB     AX,CX                   ; Number of sectors successfully transferred
        ADD     DX,AX                   ; First sector number to retry
        PUSH    DX
        MUL     ES:[BP.dpb_sector_size]          ; Number of bytes transferred
        POP     DX
        ADD     BX,AX                   ; First address for retry
        XOR     AH,AH                   ; Flag disk section in error
        CMP     DX,ES:[BP.dpb_first_FAT]    ; In reserved area?
        JB      ERRINT
        INC     AH                      ; Flag for FAT
        CMP     DX,ES:[BP.dpb_dir_sector]   ; In FAT?
        JB      ERRINT
        INC     AH
        CMP     DX,ES:[BP.dpb_first_sector]       ; In directory?
        JB      ERRINT
        INC     AH                      ; Must be in data area
ERRINT:
        SHL     AH,1                    ; Make room for read/write bit
        OR      AH,BYTE PTR [READOP]
        entry   FATAL
        MOV     AL,ES:[BP.dpb_drive]      ; Get drive number
        entry   FATAL1
        MOV     WORD PTR [EXITHOLD+2],ES
        MOV     WORD PTR [EXITHOLD],BP  ; The only things we preserve
        LES     SI,ES:[BP.dpb_driver_addr]
        MOV     BP,ES                   ; BP:SI points to the device involved
FATALC:
        CMP     BYTE PTR [ERRORMODE],0
        JNZ     SETIGN                  ; No INT 24s if already INT 24
        MOV     [CONTSTK],SP
        PUSH    SS
        POP     ES
ASSUME  ES:DOSGROUP
        CLI                             ; Prepare to play with stack
        INC     BYTE PTR [ERRORMODE]    ; Flag INT 24 in progress
        DEC     BYTE PTR [INDOS]        ; INT 24 handler might not return
        MOV     SS,[user_SS]
ASSUME  SS:NOTHING
        MOV     SP,ES:[user_SP]         ; User stack pointer restored
        INT     int_fatal_abort         ; Fatal error interrupt vector, must preserve ES
        MOV     ES:[user_SP],SP         ; restore our stack
        MOV     ES:[user_SS],SS
        MOV     SP,ES
        MOV     SS,SP
ASSUME  SS:DOSGROUP
        MOV     SP,[CONTSTK]
        INC     BYTE PTR [INDOS]        ; Back in the DOS
        MOV     BYTE PTR [ERRORMODE],0  ; Back from INT 24
        STI
IGNRET:
        LES     BP,[EXITHOLD]
ASSUME  ES:NOTHING
        CMP     AL,2
        JZ      error_abort
        MOV     BYTE PTR [WPERR],-1              ;Forget about WP error
        return

SETIGN:
        XOR     AL,AL                   ;Flag ignore
        JMP     SHORT IGNRET

error_abort:
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        CMP     BYTE PTR [CONSWAP],0
        JZ      NOSWAP2
        invoke  SWAPBACK
NOSWAP2:
        MOV     BYTE PTR [exit_Type],Exit_hard_error
        MOV     DS,[CurrentPDB]
ASSUME  DS:NOTHING

;
; reset_environment checks the DS value against the CurrentPDB.  If they
; are different, then an old-style return is performed.  If they are
; the same, then we release jfns and restore to parent.  We still use
; the PDB at DS:0 as the source of the terminate addresses.
;
; output:   none.
;
        entry   reset_environment
        ASSUME  DS:NOTHING,ES:NOTHING
        PUSH    DS                      ; save PDB of process

        MOV     AL,int_Terminate
        invoke  $Get_interrupt_vector   ; and who to go to
        MOV     WORD PTR [EXITHOLD+2],ES ; save return address
        MOV     WORD PTR [EXITHOLD],BX

        MOV     BX,[CurrentPDB]         ; get current process
        MOV     DS,BX                   ;
        MOV     AX,DS:[PDB_Parent_PID]  ; get parent to return to
        POP     CX
;
; AX = parentPDB, BX = CurrentPDB, CX = ThisPDB
; Only free handles if AX <> BX and BX = CX and [exit_code].upper is not
; Exit_keep_process
;
        CMP     AX,BX
        JZ      reset_return            ; parentPDB = CurrentPDB
        CMP     BX,CX
        JNZ     reset_return            ; CurrentPDB <> ThisPDB
        PUSH    AX                      ; save parent
        CMP     BYTE PTR [exit_type],Exit_keep_process
        JZ      reset_to_parent         ; keeping this process

        invoke  arena_free_process

        ; reset environment at [CurrentPDB]; close those handles
        MOV     CX,FilPerProc

reset_free_jfn:
        MOV     BX,CX
        PUSH    CX
        DEC     BX                      ; get jfn
        invoke  $CLOSE                  ; close it, ignore return
        POP     CX
        LOOP    reset_free_jfn          ; and do 'em all

reset_to_parent:
        POP     [CurrentPDB]            ; set up process as parent

reset_return:                           ; come here for normal return
        PUSH    CS
        POP     DS
        ASSUME  DS:DOSGROUP
        MOV     AL,-1
        invoke  FLUSHBUF                ; make sure that everything is clean

        CLI
        MOV     BYTE PTR [INDOS],0               ;Go to known state
        MOV     BYTE PTR [WPERR],-1              ;Forget about WP error
;
; Snake into multitasking... Get stack from CurrentPDB person
;
        MOV     DS,[CurrentPDB]
        ASSUME  DS:NOTHING
        MOV     SS,WORD PTR DS:[PDB_user_stack+2]
        MOV     SP,WORD PTR DS:[PDB_user_stack]

        ASSUME  SS:NOTHING
        invoke  restore_world
        ASSUME  ES:NOTHING
        POP     AX                      ; suck off CS:IP of interrupt...
        POP     AX
        POP     AX
        MOV     AX,0F202h               ; STI
        PUSH    AX
        PUSH    WORD PTR [EXITHOLD+2]
        PUSH    WORD PTR [EXITHOLD]
        STI
        IRET            ; Long return back to user terminate address
HardErr ENDP

        ASSUME  SS:DOSGROUP

do_ext

CODE    ENDS
    END
