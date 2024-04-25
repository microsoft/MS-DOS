PAGE    60,132
TITLE   INDEEMU - 386 XMA EMULATOR - Sensitive Instruction Emulator

COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEEMU                                                   *
*                                                                             *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corporation	      *
*                                                                             *
* DESCRIPTIVE NAME: 386 XMA emulator - emulate sensitive instructions         *
*                                                                             *
* STATUS (LEVEL)  : VERSION (0) LEVEL (1.0)                                   *
*                                                                             *
* FUNCTION        : When the I/O privilege level (IOPL) is less than 3 then   *
*                   the processor flags an exception and gives control to     *
*                   the emulator whenever the virtual 8086 (V86) task tries   *
*                   to execute a sensitive instruction.  The set of sensitive *
*                   instructions includes: STI, CLI, INT3, INTO, IRET, INT,   *
*                   PUSHF, POPF, LOCK, IN and OUT.  This moudle will emulate  *
*                   these intructions for the V86 task.  It will also set the *
*                   IOPL to 3.  This will keep the processor from raising     *
*                   further exceptions for these instructions.  This in turn  *
*                   improves performance because the emulator will not be     *
*                   given control each time one of these instructions is      *
*                   executed by the V86 task.                                 *
*                                                                             *
*                   This module also has a small piece of code to handle      *
*                   exception 7, coprocessor not available.  This exception   *
*                   is raised when the EM (EMulation), MP (Monitor Processor),*
*                   and TS (Task Switch) bits in CR0 are on.  When this       *
*                   happens it turns off these bits and retries the instruc-  *
*                   tion that faulted.                                        *
*                                                                             *
* MODULE TYPE     : ASM                                                       *
*                                                                             *
* REGISTER USAGE  : 80386 Standard                                            *
*                                                                             *
* RESTRICTIONS    : None                                                      *
*                                                                             *
* DEPENDENCIES    : None                                                      *
*                                                                             *
* ENTRY POINT     : EMULATE                                                   *
*                                                                             *
* LINKAGE         : Jumped to by INDEEXC                                      *
*                                                                             *
* INPUT PARMS     : None                                                      *
*                                                                             *
* RETURN PARMS    : None                                                      *
*                                                                             *
* OTHER EFFECTS   : None                                                      *
*                                                                             *
* EXIT NORMAL     : IRET to the V86 task                                      *
*                                                                             *
* EXIT ERROR      : Jump to error routine in INDEEXC                          *
*                                                                             *
* EXTERNAL                                                                    *
* REFERENCES      : POPREGS - Entry point in INDEEXC to pop the registers  P1C*
*                             off the stack and IRET to the V86 task.         *
*                   DISPLAY - Entry point in INDEEXC for the error routine    *
*                             that does the NMI to the error handler.         *
*                   INT15   - Entry point to INDEI15, the INT 15 handler.     *
*                   XMAIN   - Entry point in INDEXMA to handle IN for a byte  *
*                             at the port address in DX                       *
*                   INW     - Entry point in INDEXMA to handle IN for a word  *
*                             at the port address in DX                       *
*                   INIMMED - Entry point in INDEXMA to handle IN for a byte  *
*                             at the immediate port address given             *
*                   INWIMMED- Entry point in INDEXMA to handle IN for a word  *
*                             at the immediate port address given             *
*                   XMAOUT  - Entry point in INDEXMA to handle OUT for a byte *
*                             at the port address in DX                       *
*                   OUTW    - Entry point in INDEXMA to handle OUT for a word *
*                             at the port address in DX                       *
*                   XMAOUTIMMED  - Entry point in INDEXMA to handle OUT for a *
*                             byte at the immediate port address given        *
*                   XMAOUTWIMMED - Entry point in INDEXMA to handle OUT for a *
*                             word at the immediate port address given        *
*                   MANPORT - Entry point in INDEDMA to issue an out to the   *
*                             port that will reIPL the system                 *
*                                                                             *
* SUB-ROUTINES    : None                                                      *
*                                                                             *
* MACROS          : DATAOV - Create a prefix for the following instruction    *
*                            so that it accesses data 32 bits wide            *
*                   ADDROV - Create a prefix for the following instruction    *
*                            so that it uses addresses that are 32 bits wide  *
*                   CMOV   - Move to or from a control register               *
*                                                                             *
* CONTROL BLOCKS  : INDEDAT.INC                                               *
*                                                                             *
* CHANGE ACTIVITY :                                                           *
*                                                                             *
* $MOD(INDEEMU) COMP(LOAD) PROD(3270PC) :                                     *
*                                                                             *
* $D0=D0004700 410 870523 D : NEW FOR RELEASE 1.1                             *
* $P1=P0000312 410 870804 D : CLEAN UP WARNING MESSAGES                       *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

        .286P                 ; Enable recognition of 286 privileged instructs.

        .XLIST                ; Turn off the listing
        INCLUDE INDEDAT.INC

        IF1                   ; Only include macros on the first pass
        INCLUDE INDEOVP.MAC
        INCLUDE INDEINS.MAC
        ENDIF
        .LIST                 ; Turn on the listing

        PUBLIC  INDEEMU

PROG    SEGMENT PARA PUBLIC 'PROG'

        ASSUME  CS:PROG
        ASSUME  DS:NOTHING
        ASSUME  ES:NOTHING
        ASSUME  SS:NOTHING

INDEEMU LABEL   NEAR

        ; The following entries are in other modules

        EXTRN   XMAIN:NEAR        ; Byte IN from port # in DX
IN_INST EQU     XMAIN             ;                                         @P1C
        EXTRN   INW:NEAR          ; Word IN from port # in DX
        EXTRN   INIMMED:NEAR      ; Byte IN from immediate port #
        EXTRN   INWIMMED:NEAR     ; Word IN from immediate port #
        EXTRN   XMAOUT:NEAR       ; Byte OUT to port # in DX
OUT_INST EQU     XMAOUT           ;                                         @P1C
        EXTRN   OUTW:NEAR         ; Word OUT to port # in DX
        EXTRN   XMAOUTIMMED:NEAR  ; Byte OUT to immediate port #
OUTIMMED EQU    XMAOUTIMMED       ;
        EXTRN   OUTWIMMED:NEAR    ; Word OUT to immediate port #
        EXTRN   DISPLAY:NEAR      ; Signal the error handler
        EXTRN   MANPORT:NEAR      ; ReIPL the system
        EXTRN   INT15:NEAR        ; Handle INT 15
        EXTRN   POPREGS:NEAR      ; Pop the registers and IRET to V86 task  @P1C

PAGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The following is a jump table for each of the instructions.  There are 256 ;;
;; entries, each three bytes long, one for each possible op-code.  The op-    ;;
;; code is used as an index into the table.  Each entry is a jump instruction ;;
;; instruction telling where to jump for each particular op-code.  The table  ;;
;; is initialized such that all in- structions jump to the routin for         ;;
;; unexpected op-codes.  Then the entries for the instructions we want to     ;;
;; emulate are set to jump to the appropriate routine.                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TABLE:
        .XLIST
        REPT    256             ; Initialize the table so that all instructions
        JMP     UNEXPECTED      ;   jump to UNEXPECTED
        ENDM
        .LIST

; Now set up the entries for the instructions we want to emulate

TABLE_END:
        ORG     TABLE+(0FBH*3)  ; 0FBH is the op-code for STI.
        JMP     STI_INST        ;                                           @P1C
        ORG     TABLE+(0FAH*3)  ; 0FAH is the op-code for CLI.
        JMP     CLI_INST        ;                                           @P1C
        ORG     TABLE+(0F0H*3)  ; 0F0H is the op-code for LOCK.
        JMP     LOCK_INST       ;                                           @P1C
        ORG     TABLE+(0EFH*3)  ; 0EFH is the op-code for OUT for a word.
        JMP     OUTW            ;
        ORG     TABLE+(0EEH*3)  ; 0EEH is the op-code for OUT for a byte.
        JMP     OUT_INST        ;                                           @P1C
        ORG     TABLE+(0EDH*3)  ; 0EDH is the op-code for IN for a word.
        JMP     INW
        ORG     TABLE+(0ECH*3)  ; 0ECH is the op-code for IN for a byte.
        JMP     IN_INST         ;                                           @P1C
        ORG     TABLE+(0E7H*3)  ; 0E7H is the op-code for OUT for a word to
        JMP     OUTWIMMED       ;   an immediate port value.
        ORG     TABLE+(0E6H*3)  ; 0E6H is the op-code for OUT for a byte to
        JMP     OUTIMMED        ;   an immediate port value.
        ORG     TABLE+(0E5H*3)  ; 0E5H is the op-code for IN for a word to
        JMP     INWIMMED        ;   an immediate port value.
        ORG     TABLE+(0E4H*3)  ; 0E4H is the op-code for IN for a byte to
        JMP     INIMMED         ;   an immediate port value.
        ORG     TABLE+(0CFH*3)  ; 0CFH is the op-code for IRET.
        JMP     IRET_INST       ;                                           @P1C
        ORG     TABLE+(0CEH*3)  ; 0CEH is the op-code for INTO.
        JMP     INTO_INST       ;                                           @P1C
        ORG     TABLE+(0CDH*3)  ; 0CDH is the op-code for INT.
        JMP     INT_INST        ;                                           @P1C
        ORG     TABLE+(0CCH*3)  ; 0CCH is the op-code for INT3.
        JMP     INT3            ;
        ORG     TABLE+(09DH*3)  ; 09DH is the op-code for POPF.
        JMP     POPF_INST       ;                                           @P1C
        ORG     TABLE+(09CH*3)  ; 09CH is the op-code for PUSHF.
        JMP     PUSHF_INST      ;                                           @P1C
        ORG     TABLE+(00FH*3)  ; 00FH is the op-code for POP CS.
        JMP     MANPORT         ; Expedient until 0F opcode properly emulated

        ORG     TABLE_END

VALUE3  DB      3

        PUBLIC  EMULATE
        PUBLIC  POPIO
        PUBLIC  INTCOM

EMULATE PROC    NEAR

        CLD

PAGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Get the op-code that faulted from real memory.  Use it as an index into    ;;
;; the jump table to go to the appropriate routine.                           ;;
;;                                                                            ;;
;; Note: The DATAOV macro creates a prefix that makes the instruction that    ;;
;;       immediately follows access all data as 32 bits wide.  Similarly,     ;;
;;       the ADDROV macro creates a prefix that makes the instruction that    ;;
;;       immediately follows use addresses that are 32 bits wide.             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        MOV     AX,HUGE_PTR            ; Load DS with a selector that will
        MOV     DS,AX                  ;   access all of memory as data

        MOV     SS:WORD PTR [BP+BP_IP2],0 ; Clear the high words of the V86
        MOV     SS:WORD PTR [BP+BP_CS2],0 ;   task's CS and IP

        DATAOV
        MOV     SI,SS:[BP+BP_IP]       ; Get the V86 IP into our SI.  The high
        DATAOV                         ;   order word is zeroes.
        MOV     AX,SS:[BP+BP_CS]       ; Get the V86 CS into AX.  Again, the
        DATAOV                         ;   high order word is zeroes.
        SHL     AX,4                   ; Multiply CS by 16 to convert it to an
        DATAOV                         ;   offset.
        ADD     SI,AX                  ; Add on IP.  Now SI contains the offset
                                       ;   from 0 of the instruction that
                                       ;   faulted.
        ADDROV
        LODSB                          ; Get the op-code into AL

        ADDROV                         ; Intel bug # A0-119
        NOP                            ; Intel bug # A0-119

        MUL     VALUE3                 ; Multiply the op-code by 3 to get an
        LEA     BX,TABLE               ;   index into the jump table
        ADD     AX,BX                  ; Add on the offset of the base of the
                                       ;   table
        JMP     AX                     ; Jump to the entry in the table.  This
                                       ;   entry will then jump us to the
                                       ;   routine that handles this op-code.

PAGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Woops!  We got an op-code that we did not expect to fault.  First let's    ;;
;; check if this instruction faulted because the coprocessor was not avail-   ;;
;; able.  This will be signalled by an exception code of 07.  If this is the  ;;
;; case then reset the the following bits in CR0:  EM (EMulation) says that   ;;
;; coprocessor functions are emulated by software when set to 0; MP (monitor  ;;
;; Processor), when set to 1 raises an exception 7 when TS (Task Switched)    ;;
;; is set to 1 and a WAIT instruction is executed.  TS is set every time      ;;
;; there is a task switch.                                                    ;;
;;                                                                            ;;
;; If it was not an execption 7 then we'll check the I/O privilege level      ;;
;; (IOPL).  An IOPL other less than 3 will cause all I/O and some sensitive   ;;
;; instructions to fault.  We really don't want to be bothered by all these   ;;
;; faulting instructions so we'll set the IOPL to 3 which will allow anyone   ;;
;; to do I/O and the sensitive instructions.  This will improve performance   ;;
;; since the V86 task will be interrupted less often.  But first we'll check  ;;
;; to see if the IOPL is already 3.  If so then we got trouble.  Most likely  ;;
;; it's an invalid op-code.  In this case we'll signal the error handler in   ;;
;; INDEEXC.                                                                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UNEXPECTED:
        CMP     SS:WORD PTR [BP+BP_EX],0007H
                                       ; Check if it's an 07 exception -- co-
                                       ;   processor not available
        JNE     TRYIOPL3               ; If no then try setting the IOPL to 3

        MOV     AX,8000H               ; Set the paging enabled bit
        DATAOV
        SHL     AX,16                  ; It's the one all the way on the left
        MOV     AX,0001H               ; Set protect mode on.  Leave all other
                                       ;   bits off.
        CMOV    CR0,EAX                ; Reset CR0
        JMP     POPREGS                ; Return to the V86 task             @P1C

; Try setting the IOPL to 3

TRYIOPL3:
        MOV     BX,AX                  ; Save the faulty op-code in BX
        MOV     AX,SS:WORD PTR [BP+BP_FL] ; Get the V86 flags and check if
        AND     AX,3000H               ;   IOPL is already set to 3
        CMP     AX,3000H
        JE      WHOOPS                 ; If we're already at IOPL 3 the some-
                                       ;   things fishy.  Time to signal an
                                       ;   error.
        OR      SS:WORD PTR [BP+BP_FL],3000H
                                       ; Otherwise set IOPL to 3 and return to
        JMP     POPREGS                ;   the V86 task and let it try to   @P1C
                                       ;   execute the instruction again.

;  We got trouble.

WHOOPS:

; Convert jump address back to opcode in al

        MOV     AX,BX                  ; Put the jump table index back into AX
        LEA     BX,TABLE               ; Subtract the offset of the base of the
        SUB     AX,BX                  ;   jump table
        DIV     VALUE3                 ; Divide AX by 3 to get the opcode back.
        JMP     DISPLAY                ; Go to the error routine in INDEEXC

PAGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emulate the LOCK instruction.  This is an instruction we really don't want ;;
;; to emulate so we will set the IOPL to 3 so that further LOCKs won't bother ;;
;; us.  If the exception code is for "invalid op-code" then we will just jump ;;
;; to the routine above to set the IOPL to 3.  Otherwise we will just step IP ;;
;; past the LOCK instruction thus treating it as a NOP.                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LOCK_INST:                                    ;                             @P1C
        CMP     SS:WORD PTR [BP+BP_EX],0006H  ; Check if it's an invalid op code
        JNE     TRYIOPL3                      ; Try setting the IOPL to 3
        ADD     WORD PTR SS:[BP+BP_IP],1      ; Step IP past the instruction
        JMP     POPIO                         ;   thus treating it as a NOP

PAGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emulate the STI, enable interupts, instruction.  This is pretty simple to  ;;
;; do.  Just get the V86 task's flags and flip on the enable interrupts bit.  ;;
;; And while we're at it we'll set the IOPL to 3.                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

STI_INST:                                     ;                             @P1C
        OR      WORD PTR SS:[BP+BP_FL],3200H  ; Set the enable interrupts bit
                                              ;   and set IOPL to 3
        ADD     WORD PTR SS:[BP+BP_IP],1      ; Step IP past STI instruction
        JMP     POPIO

PAGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emulate the CLI, disable interrupts, instruction.  Just as in STI above,   ;;
;; all that is needed is to turn of the enable interrups bit.  And again, set ;;
;; the IOPL to 3 so that we won't get control again.                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CLI_INST:                                     ;                             @P1C
        AND     WORD PTR SS:[BP+BP_FL],3DFFH  ; Set interrupts disabled
        OR      WORD PTR SS:[BP+BP_FL],3000H  ; Insure IOPL = 3 for speed
        ADD     WORD PTR SS:[BP+BP_IP],1      ; Step IP past instruction
        JMP     POPIO

PAGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emulate the INT3 instruction.  To do this we put a 3 in the exception code ;;
;; and jump to the portion of the code that emulates the INT instruction.     ;;
;; That code uses the exception code to get the interrupt vector from real    ;;
;; memory and gives control to the V86 task at the interrupt address.         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INT3:
        MOV     WORD PTR SS:[BP+BP_EX],3      ; Put a 3 in the exception field
                                              ;   This will cause the INTCOM
                                              ;   section to go to interrupt 3
        ADD     WORD PTR SS:[BP+BP_IP],1      ; Step IP past INT3 inscruction
        JMP     INTCOM                        ; Go get the vector from real
                                              ;   memory

PAGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emulate the INTO instruction.  This is done just like the INT3 above.  It  ;;
;; puts a 4 in the exception code and jumps to the code in the INT emulator   ;;
;; that will get the real address of the interrupt.                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INTO_INST:                                    ;                             @P1C
        MOV     WORD PTR SS:[BP+BP_EX],4      ; Put a 4 in the exception field
                                              ;   This will cause the INTCOM
                                              ;   section to go to interrupt 4
        ADD     WORD PTR SS:[BP+BP_IP],1      ; Step IP past INTO inscruction
        JMP     INTCOM                        ; Go get the vector from real
                                              ;   memory

PAGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emulate the IRET instruction.  Get CS, IP and the flags off of the V86     ;;
;; task's stack and place them in the register values on our stack.  When we  ;;
;; return control to the V86 task these values will be taken off of our stack ;;
;; and placed in the V86 task's registers.                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IRET_INST:                                    ;                             @P1C
        DATAOV                                ; Get the user's ESP (32 bit SP)
        MOV     AX,SS:[BP+BP_SP]              ;   and save it in ESI.
        DATAOV
        MOV     SI,AX
        ADD     AX,6                          ; Add 6 to the user's SP.  This
        MOV     SS:WORD PTR [BP+BP_SP],AX     ;   skips over the IP, CS and
                                              ;   flags on the user's stack.
                                              ;   This puts SP where it would be
                                              ;   after the IRET.  It assumes
                                              ;   there are at least six bytes
                                              ;   on the stack.
        DATAOV
        MOV     AX,SS:[BP+BP_SS]              ; Get the user's SS and multiply
        DATAOV                                ;   by 16.  This converts the
        SHL     AX,4                          ;   segment value to an offset.
        DATAOV                                ; Add this on to the ESP value in
        ADD     SI,AX                         ;   ESI and now ESI is the offset
                                              ;   from 0 of the user's stack.
        ADDROV
        LODSW                                 ; Get the user's EIP into EAX

        ADDROV                                ; Intel bug # A0-119
        NOP                                   ; Intel bug # A0-119

        MOV     WORD PTR SS:[BP+BP_IP],AX     ; Put IP into the register values
                                              ;   on our stack
        ADDROV
        LODSW                                 ; Get the user's CS into EAX

        ADDROV                                ; Intel bug # A0-119
        NOP                                   ; Intel bug # A0-119

        MOV     WORD PTR SS:[BP+BP_CS],AX     ; Put CS into the register values
                                              ;   on our stack
        ADDROV
        LODSW                                 ; Get the user's flags (32 bits)

        ADDROV                                ; Intel bug # A0-119
        NOP                                   ; Intel bug # A0-119

        AND     AX,3FFFH                      ; Clean up the flags
        OR      AX,3000H                      ; Set IOPL to 3
        MOV     WORD PTR SS:[BP+BP_FL],AX     ; Put the flags into the register
                                              ;   values on our stack
        JMP     POPREGS                       ; Go return to the V86 task   @P1C

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emulate the INT instruction.  Step the V86 task's CS and IP past the INT   ;;
;; instruction.  Push the flags, CS and IP in the task's stack.  Get the      ;;
;; interrupt number and use it to find the appropriate interrupt vector in    ;;
;; low memory.  Set the task's CS and IP to the interrupt vector and return   ;;
;; control to the task.                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INT_INST:                                     ;                             @P1C

; Get the interrupt number from the instruction.  It is the second byte of the
; instruction.  DS:SI was used to get the op-code.  Now DS:SI points to the next
; byte of the instruction.  All we have to do is get it.

        ADDROV
        LODSB                                 ; Get the interrupt number

        ADDROV                                ; Intel bug # A0-119
        NOP                                   ; Intel bug # A0-119

        MOV     AH,0                          ; Clear the high byte
        MOV     WORD PTR SS:[BP+BP_EX],AX     ; Save the interrupt number in
                                              ;   the exception code field

; Step IP past the INT instruction.

        ADD     WORD PTR SS:[BP+BP_IP],2      ; STEP IP PAST INT INSTRUCTION

; Check for INT 15.  This is handled by INDEI15.

INTCONT:
        CMP     AL,15H                        ; Is it interrupt 15?
        JNE     INTCOM                        ; If not, continue
        JMP     INT15                         ; Else go to INDEI15

; Now use the interrupt number to get the appropriate interrupt vector from
; low core.

INTCOM:
        MOV     AX,HUGE_PTR                   ; Load ES with the selector that
        MOV     ES,AX                         ;   accesses all of memory as data
        DATAOV
        MOV     DI,SS:[BP+BP_SP]              ; Load EDI with the user's ESP
                                              ; Now ES:EDI points to the user's
                                              ;   stack
        SUB     DI,6                          ; Decrement "SP" to make space for
                                              ;   the flags, CS snd IP
        MOV     SS:WORD PTR [BP+BP_SP],DI     ; Set the user's new SP

        DATAOV
        MOV     AX,SS:[BP+BP_SS]              ; Get the user's SS and shift it
        DATAOV                                ;   left four bits to convert it
        SHL     AX,4                          ;   to an offset
        DATAOV                                ; Add it to EDI so that EDI now
        ADD     DI,AX                         ;   contains the physical offset
                                              ;   of the user's stack

; Now put the flags, CS and IP on the V86 task's stack.  They are put on in the
; order IP, CS, flags.  This is backwards from the INT push order of flags, CS
; and then IP.  This is because we are moving forward through memory (CLD)
; whereas the stack grows backwards through memory as things apushed on to it.

        MOV     AX,SS:[BP+BP_IP]
        ADDROV
        STOSW                                 ; Put IP on the V86 task's stack
        ADDROV                                ; Intel bug # A0-119
        NOP                                   ; Intel bug # A0-119

        MOV     AX,SS:[BP+BP_CS]
        ADDROV
        STOSW                                 ; Put CS on the V86 task's stack
        ADDROV                                ; Intel bug # A0-119
        NOP                                   ; Intel bug # A0-119

        MOV     AX,SS:[BP+BP_FL]              ; Get the v86 task's flags
        OR      AX,3000H                      ; Set IPOL to 3 while we're here
        ADDROV
        STOSW                                 ; Put the flags on the v86 task's
                                              ;   stack

        ADDROV                                ; INTEL BUG # A0-119
        NOP                                   ; INTEL BUG # A0-119
        AND     AX,3CFFH                      ; Clean up flags for our IRET
        MOV     WORD PTR SS:[BP+BP_FL],AX

; Use the interrupt number to get the CS and IP of the interrupt routine

        MOV     SI,SS:[BP+BP_EX]              ; Get the interrupt number
        SHL     SI,2                          ; Multiply by 4 since interrupt
                                              ;   vectors are 4 bytes long
        LODSW                                 ; Get the IP for the vector
        MOV     WORD PTR SS:[BP+BP_IP],AX     ; Put it in the V86 task's IP
        LODSW                                 ; Get the CS for the vector
        MOV     WORD PTR SS:[BP+BP_CS],AX     ; Put it in the V86 task's CS

        JMP     POPREGS                       ; Go return to the V86 task   @P1C

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emulate the PUSHF instruction.  Get the V86 task's flags and put them on   ;;
;; its stack.                                                                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PUSHF_INST:                                   ;                             @P1C
        MOV     AX,HUGE_PTR                   ; Load ES with the selector that
        MOV     ES,AX                         ;   accesses all of memory as data

        DATAOV
        MOV     DI,SS:[BP+BP_SP]              ; Load EDI with the V86 task's SP
        SUB     DI,2                          ; Decrement "SP" by one word to
                                              ;   make room for the flags
        MOV     SS:WORD PTR [BP+BP_SP],DI     ; Store the new V86 task's SP
        DATAOV
        MOV     AX,SS:[BP+BP_SS]              ; Get the user's SS and shift it
        DATAOV                                ;   left four bits to convert it
        SHL     AX,4                          ;   to an offset
        DATAOV                                ; Add it to EDI so that EDI now
        ADD     DI,AX                         ;   contains the physical offset
                                              ;   of the user's stack
        MOV     AX,SS:[BP+BP_FL]              ; Get the v86 task's flags
        OR      AX,3000H                      ; Set IPOL to 3 so that we won't
        ADDROV                                ;   be bothered anymore
        STOSW                                 ; Put the flags on the stack
        ADDROV                                ; Intel bug # A0-119
        NOP                                   ; Intel bug # A0-119

        ADD     WORD PTR SS:[BP+BP_IP],1      ; Step IP past PUSHF instruction

        JMP     POPIO                         ; Go return to the V86 task

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emulate the POPF instruction.  Get the next word off of the V86 task's     ;;
;; stack, set IOPL to 3 and put it in the V86 task's flags.                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

POPF_INST:                                    ;                             @P1C
        MOV     AX,HUGE_PTR                   ; Big segment selector
        MOV     DS,AX                         ; Stack seg
        DATAOV          ; Create 32-bit operand prefix for next instruction
        MOV     AX,SS:[BP+BP_SP]              ; stack ptr
        DATAOV          ; Create 32-bit operand prefix for next instruction
        MOV     SI,AX                         ; SI = stack ptr
        ADD     AX,2
        MOV     SS:WORD PTR [BP+BP_SP],AX     ; NEW STACK POINTER
        DATAOV          ; Create 32-bit operand prefix for next instruction
        MOV     AX,SS:[BP+BP_SS]              ; Convert ss to 20 bit address
        DATAOV          ; Create 32-bit operand prefix for next instruction
        SHL     AX,4
        DATAOV          ; Create 32-bit operand prefix for next instruction
        ADD     SI,AX                         ; Now have 32-bit offset from 0
        ADDROV                                ; Use 32-bit offset
        LODSW                                 ; GET REAL MODE FLAGS
        ADDROV                                ; INTEL BUG # A0-119
        NOP                                   ; INTEL BUG # A0-119
        AND     AX,0FFFH                      ; CLEAN UP FLAGS FOR OUR IRET
; A POPF at level 3 will not change IOPL - WE WANT TO KEEP IT AT IOPL = 3
        OR      AX,3000H                      ; SET IOPL = 3
        MOV     WORD PTR SS:[BP+BP_FL],AX
        ADD     WORD PTR SS:[BP+BP_IP],1      ; STEP IP PAST INSTRUCTION
        JMP     POPIO                         ; CHECK FOR SINGLE STEP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The following entry point, POPIO, is the exit routine for situations when  ;;
;; a single step condition would be lost by a normal IRET to the V86 task.    ;;
;; You see, in real mode the single step interrupt gets control whenever the  ;;
;; single step flag is on.  However, we just got control and emulated the     ;;
;; instruction.  If we just return to the V86 task at CS:IP then the step     ;;
;; between the instruction we just emulated and the next instruction will be  ;;
;; missed by the single step routine.  Therefore we check the V86 task's flags;;
;; to see if the single step flag is on.  If so, then we give control to the  ;;
;; singel step interrupt.  Otherwise we just IRET to the V86 task's CS:IP.    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

POPIO:
        CMP     SS:WORD PTR [BP+BP_EX],1      ; First check if the reason we got
                                              ;   control was because of a
                                              ;   single step
        JE      POPCONT                       ; If so, then we don't have to
                                              ;   give control to the single
                                              ;   step routine 'cause we already
                                              ;   did it.
        TEST    WORD PTR SS:[BP+BP_FL],0100H  ; Was the single step flag on?
        JZ      POPCONT                       ; If not then just IRET
        MOV     SS:WORD PTR [BP+BP_EX],1      ; Otherwise put a 1 (single step
        JMP     INTCOM                        ;   interrupt number) in the
                                              ;   exception code and go to
                                              ;   INTCOM to give control to the
                                              ;   interrupt
POPCONT:

; Restore the registers.  On entry, in INDEEXC, the registers were pushed as:
; DS, all registers, ES.

        POP     ES              ; Restore ES
        DATAOV
        POPA                    ; Restore all the registers (32 bits wide)
        POP     DS              ; Restore DS
        ADD     SP,(BP_IP-BP_EX); Move SP past the exception ID an error code
                                ;   that were put on our stack when the 386
                                ;   gave us control for the exception.
                                ;   SS:SP now points to the V86's IP, CS, flags
                                ;   for the IRET
        DATAOV                  ; IP, CS, and flags are saved 32 bits wide
        IRET                    ; Give control back to the V86 task

EMULATE ENDP

PROG    ENDS

        END

