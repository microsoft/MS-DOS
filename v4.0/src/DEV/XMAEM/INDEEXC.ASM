PAGE    60,132
TITLE   INDEEXC - 386 XMA EMULATOR - System Exception Handler

COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEEXC                                                   *
*                                                                             *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corp.              *
*                                                                             *
* DESCRIPTIVE NAME: 80386 XMA Emulator System Exception Handler               *
*                                                                             *
* STATUS (LEVEL)  : VERSION (0) LEVEL (1.0)                                   *
*                                                                             *
* FUNCTION        : This module gets control whenever an interrupt 00 - 07,   *
*                   09 - 0E or 15 occurs.  This is because this module's      *
*                   entry point was placed in the IDT entries for these       *
*                   interrupts.  It determines what course of action to take  *
*                   on the interrupt/exception.                               *
*                                                                             *
*                   First thing it does is is to check to see who caused the  *
*                   exception.  If the exception came from the virtual 8086   *
*                   (V86) task then it will try to emulate the interrupt if   *
*                   necessary.  If the exception came from the emulator it-   *
*                   self then we may have problems.  If it was a general      *
*                   protection exception (INT 0D) then it just ignores it and *
*                   passes control back to the V86 task.  If it was a page    *
*                   fault (INT 14) then it assumes that whatever is running in*
*                   the V86 task came up with a bad address so it terminates  *
*                   the application since it is obviously bad.  If it is      *
*                   neither of these two errors then something has gone bad   *
*                   in the emulator.  When this happens it signals the error  *
*                   handler to prompt the user to take a dump or reIPL the    *
*                   system.                                                   *
*                                                                             *
*                   The old error routine used to display a panel with the    *
*                   contents of the registers and the stack.  The new error   *
*                   routine just forces the V86 task to run the NMI code.     *
*                   The old routine was left in place for debugging purposes. *
*                                                                             *
* MODULE TYPE     : ASM                                                       *
*                                                                             *
* REGISTER USAGE  : 80386 Standard                                            *
*                                                                             *
* RESTRICTIONS    : None                                                      *
*                                                                             *
* DEPENDENCIES    : None                                                      *
*                                                                             *
* ENTRY POINT     : VEXCPT13                                                  *
*                                                                             *
* LINKAGE         : This entry point is placed in the IDT for each interrupt  *
*                   we want to handle.  Whenever one of those interrupts is   *
*                   execupted, control comes here.                            *
*                                                                             *
* INPUT PARMS     : None                                                      *
*                                                                             *
* RETURN PARMS    : None                                                      *
*                                                                             *
* OTHER EFFECTS   : None                                                      *
*                                                                             *
* EXIT NORMAL     : IRET to the virtual 8086 task                             *
*                                                                             *
* EXIT ERROR      : Force the V86 task to execute an NMI                      *
*                                                                             *
* EXTERNAL                                                                    *
* REFERENCES      : EMULATE - Entry point for INDEEMU                         *
*                   INT15   - Entry point for INDEI15                         *
*                                                                             *
* SUB-ROUTINES    : HEXD - Display the double word in EAX                     *
*                   HEXW - Display the word in AX                             *
*                   HEXB - Display the byte in AL                             *
*                                                                             *
* MACROS          : DATAOV - Create a prefix for the following instruction    *
*                            so that it accesses data 32 bits wide            *
*                   ADDROV - Create a prefix for the following instruction    *
*                            so that it uses addresses that are 32 bits wide  *
*                                                                             *
* CONTROL BLOCKS  : INDEDAT.INC                                               *
*                                                                             *
* CHANGE ACTIVITY :                                                           *
*                                                                             *
* $MOD(INDEEXC) COMP(LOAD) PROD(3270PC) :                                     *
*                                                                             *
* $D0=D0004700 410 870523 D : NEW FOR RELEASE 1.1                             *
* $P1=P0000312 410 870804 D : CLEAN UP WARNING MESSAGES                       *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

        .286P                 ; Enable recognition of 286 privileged instructs.

        .XLIST                ; Turn off the listing
        INCLUDE INDEDAT.INC   ; Include system data

        IF1                   ; Only include macros on the first pass of
        INCLUDE INDEOVP.MAC   ;   of the assembler
        ENDIF
        .LIST                 ; Turn on the listing

SEX_ATTR        EQU     04B00H
STACK_ATTR      EQU     00700H
BLANK           EQU     00020H
BP_START EQU    0

        PUBLIC  INDEEXC

PROG    SEGMENT PARA PUBLIC 'PROG'

        ASSUME  CS:PROG
        ASSUME  DS:NOTHING
        ASSUME  ES:NOTHING
        ASSUME  SS:NOTHING

INDEEXC LABEL   NEAR

        ; External entry points

        EXTRN   EMULATE:NEAR       ; Entry point to INDEEMU
        EXTRN   INT15:NEAR         ; Entry point to INDEI15

        ; External variables

        EXTRN   CRT_SELECTOR:WORD  ; Selector for the display buffer (INDEI15)
        EXTRN   XMATID:BYTE        ; Current bank ID                 (INDEXMA)

PAGE

VEXCPT13        LABEL NEAR

        PUBLIC  SEX
        PUBLIC  POPREGS       ;                                              P1C
        PUBLIC  HEXD
        PUBLIC  HEXW
        PUBLIC  HEXB
        PUBLIC  VEXCPT13
        PUBLIC  DISPLAY

SEX     PROC    NEAR

        CLD                   ; All moves go forward

; Save the registers on the stack.  These are the registers of the task that
; got interrupted.

SAVE_REGS:
        PUSH    DS            ; Save DS

        DATAOV                ; Save all the registers (32 bits wide).  They are
        PUSHA                 ;   pushed in the order: AX, CX, DX, BX, original
                              ;   SP (before the PUSHA), BP, SI, DI.

        PUSH    ES            ; Save ES
        MOV     BP,SP         ; Point BP to the start of the register save area

PAGE
; First let's check to see who caused the exception, the V86 task or us.  This
; is done by checking the flags of the routine that was interrupted.  The VM
; flag is set for every routine that is running in V86 mode.  There are really
; only two entities in the system, the emulator and the V86 task.  The V86 task
; has the VM bit set when it is running, the emulator does not.  So we can read
; this bit to determine who was interrupted.

        MOV     AX,SS:WORD PTR [BP+BP_FL2]    ; Get hi-order word of the flags
        TEST    AL,02H                        ; Check the VM bit
        JZ      DISPLAY                       ; Uh oh!  It's us.
        JMP     LONGWAY                       ; It's the V86 task

PAGE
; The following entry point, DISPLAY, is know to other modules.  They jump here
; when they encounter a severe error and want to call the error handler.

DISPLAY:
;       JMP     DODISP                        ; Just display the registers.
                                              ; Comment out for final product.

; Check if it was a general protection exception.  If so, then we'll just pass
; control back to the V86 task and let it worry about it.

        MOV     BP,SP                         ; Point BP to the saved registers
        CMP     SS:WORD PTR [BP+BP_EX],0DH    ; Was it a general protection
                                              ;   exception
        JNE     DISPCONT                      ; If not, the continue
        JMP     POPREGS                       ; Else just return to the V86 @P1C
                                              ;   task

; Check if it was a page fault.  Page faults only occur when the page that is
; addressed is marked not present.  When the emulator sets up memory it marks
; all pages as present.  And this is true because the emulator does no page
; swapping.  It messes with the page tables but it doesn't remove pages from
; memory.  Therefore, if the page is not present then whatever is running in
; the V86 task came up with some wierd non-existant address.  This guy obviously
; has gone west or doesn't know what he's doing.  So we forcr the application
; to be terminated.

DISPCONT:
        CMP     SS:WORD PTR [BP+BP_EX],0EH    ; Was it a page fault?
        JNE     CHKVM                         ; Nope.  Continue checking.
        JMP     PAGE_FAULT                    ; Yup.  Assume application had bad
                                              ;   addresses.  Therefore, termin-
                                              ;   ate the application.

; Lastly we'll check who had the error, them or us.  We need to check again
; because anybody can jump to the DISPLAY label above.  If the V86 task had
; the exception then we will just terminate whatever was running in the V86
; task.  If the emulator had the exception, then obviously WE don't know
; what WE'RE doing.  Oops!  In this case we will force an NMI and bring down
; the whole system.  If the emulator isn't healthy then nothing else should
; run either.  It may sould selfish, but if the emulator is damaged then the
; rest of the system will die soon anyway.

CHKVM:
        MOV     AX,SS:WORD PTR [BP+BP_FL2]    ; Check the VM bit in the flags
        TEST    AL,02H                        ;   to see who was running
        JZ      ERROR                         ; It was us.  Better Force an NMI.
        JMP     TERM_APP                      ; It was them.  Terminate whatever
                                              ;   is running.

PAGE
ERROR:

;----------------------------------------------------------------------------D1A
; We're in big trouble now.  Something has gone west and there's no way to   D1A
; get back home.  At this point we give up and send up a flare.  We signal   D1A
; the error handler by forcing the V86 task to execute the NMI interrupt.    D1A
; We put a marker of 0DEADH at the fixed location 0:4F2.  This is in the     D1A
; BIOS communication area.  The error handler will look here for our marker  D1A
; to determine if the NMI came from the emulator.  If it finds it, it will   D1A
; put up a severe error with our return code and ask the user to take a dump D1A
; or reIPL.  The code following this new code is old code to display a debug D1A
; panel with the contents of the registers and stack.  It is left here for   D1A
; debugging but will not be executed when the new code is in place.          D1A
;----------------------------------------------------------------------------D1A
                                        ;                                    D1A
        MOV     AX,HUGE_PTR             ; Load ES with a selector that      @D1A
        MOV     ES,AX                   ;   accesses all of memory as data  @D1A
                                        ;                                    D1A
        MOV     DI,4F2H                 ; Put our 0DEADH marker at the      @D1A
        MOV     WORD PTR ES:[DI],0DEADH ;   fixed location 0:4F2.            D1A
        MOV     WORD PTR SS:[BP+BP_EX],2; Put a 2, the NMI interrupt number,@D1A
                                        ;   in the exception field.  The     D1A
                                        ;   code after LONGWAY4 will use     D1A
                                        ;   this number to get the interrupt D1A
                                        ;   vector.                          D1A
        JMP     LONGWAY4                ; Go do the NMI                     @D1A

PAGE
; The following code will not be executed.  It is left as a debugging tool.

DODISP:
; Blank the display screen
        MOV     DI,CRT_SELECTOR         ; Load ES with the selector for the
        MOV     ES,DI                   ;   display buffer
        XOR     DI,DI                   ; DI points to the start of the buffer
        MOV     CX,80*15                ; Only clear 15 lines
        MOV     AX,STACK_ATTR+BLANK     ; AH = white on black attribute
                                        ; AL = ASCII for a blank
        REP     STOSW                   ; Write 15 rows of while blanks on black

; Highlite the display area

        XOR     DI,DI                   ; DI points to the start of the buffer
        MOV     CX,80*6                 ; Highlite 6 lines
        MOV     AX,SEX_ATTR+BLANK       ; AH = white on red attribute
                                        ; AL = ASCII for a blank
        REP     STOSW                   ; Highlight the 6 lines

; Display the registers one at at time

        MOV     CX,21             ; 18 regs + excpt id + task id + error code
        MOV     SI,SYS_PATCH_DS   ; Load DS with the selector for our data
        MOV     DS,SI             ;   area
        MOV     SI,OFFSET REG_TABLE ; DS:SI now points to the reg table
        SUB     AX,AX             ; Clear AH
        MOV     AL,XMATID         ; Load AL with the current XMA bank ID
        MOV     WORD PTR SS:[BP+BP_PSP2],AX  ; The bank ID gets displayed as
                                             ;   the task ID

; Display one register

DO_REG:

; Calculate the offset into the display buffer

        LODSB                           ; Get the row coordinate
        MOV     AH,160                  ; Multiply by 160 byte to a row
        MUL     AH                      ;   (80 bytes of character, attribute)
        ADD     AL,DS:BYTE PTR [SI]     ; Add on the number of columns
        ADC     AH,0                    ; Don't forget the carry
        ADD     AL,DS:BYTE PTR [SI]     ; Add the columns again (remember -
        ADC     AH,0                    ;   character, attribute)
        INC     SI                      ; Point to next entry in the reg table
        MOV     DI,AX                   ; Load DI with the offset into the
                                        ;   display buffer

DO_ID:

; Put the register name on the screen.

        MOV     BX,SEX_ATTR             ; Load the attribute byte into AH
        MOV     AH,BH
        LODSB                           ; Get the character to display
        CMP     AL,0                    ; Are we at the end of the string yet?
        JZ      DID_ID                  ; Yup.  Then go display the register
                                        ;   value.
        STOSW                           ; Else put the next character of the
                                        ;   register name on the screen
        JMP     DO_ID                   ; Go get the next character

DID_ID:

; Put the register value on the screen.

        MOV     BP,SP                   ; BP points the start of the register
                                        ;   save area
        LODSW                           ; Get the offset of this register's
                                        ;   save area
        ADD     BP,AX                   ; Add to BP.  BP ponts to the register
                                        ;   value.
        LODSW                           ; Get the length of this register's
        MOV     DX,AX                   ;   save area
        CMP     DX,2                    ; If the length is not two words
        JNE     MORE                    ; Then go to the one word code

        DATAOV                          ; Grab all 32 bits of the register
        MOV     AX,SS:WORD PTR [BP]
        ADD     BP,4                    ; Point BP past the register value
        CALL    HEXD                    ; Display the 32 bit value
        JMP     LOOPREG                 ; Jump over the one word code

MORE:
        MOV     AX,SS:WORD PTR [BP]     ; Get the word value into AX
        ADD     BP,2                    ; Step BP past the register value
        CALL    HEXW                    ; Display the 16 bit value

LOOPREG:
        LOOP    DO_REG                  ; Go do another register

PAGE
;
;       Let's go put up the stack for everyone to see !!!
;
        MOV     BP,SP                   ; Reset BP to point to the beginning
                                        ;   of the register save area

; If the V86 task faulted, display its stack.  Else display our stack.

        MOV     AX,SS:WORD PTR [BP+BP_FL2] ; Alright, whose fault was it?
        TEST    AL,02H                     ; Check the VM flag
        JZ      NOTVM86                    ; Gulp!  It's us.

; It was the V86 task that faulted.  Set DS:SI to point to their stack.

        MOV     AX,HUGE_PTR             ; Load DS with a slector that accesses
        MOV     DS,AX                   ;   all of memory as data
        DATAOV
        SUB     SI,SI                   ; Clear all 32 bits of ESI
        MOV     SI,SS:[BP+BP_SP]        ; Load SI wiht the V86 task's SP
        DATAOV
        SUB     AX,AX                   ; Clear all 32 bits of EAX
        MOV     AX,SS:[BP+BP_SS]        ; Get the V86 task's SS
        DATAOV                          ; Shift it left 4 bits to convert it
        SHL     AX,4                    ;   to an offset
        DATAOV                          ; Add it on to SP.  Now SI contains
        ADD     SI,AX                   ;   the offest of the stack from 0

        MOV     BP,0FFFFH               ; I don't know what this code does but
        DATAOV                          ;   I left it anyway.  The following
                                        ;   comment is the only clue.
        SHL     BP,16                   ; Make stack seg limit very large
        JMP     COMSTACK

; It was us that faulted.  Set DS:SI to point to our stack.

NOTVM86:
        MOV     AX,SS                   ; Load DS with our own SS
        MOV     DS,AX
        DATAOV
        SUB     SI,SI                   ; Clear all 32 bits of ESI
        MOV     SI,SP                   ; Now DS:SI points to our stack

; DS:SI points to the beginning of a stack.  Now display it.

COMSTACK:
        MOV     DI,1120                 ; Load DI with the offset into the
                                        ;   display buffer of where we want
                                        ;   to display the stack
        MOV     CX,70H                  ; Display 70H words of the stack
        MOV     BX,STACK_ATTR           ; Load BH with the attribute byte

DISP_STACK:

        ADDROV                          ; Get a word off of the stack
        LODSW
        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119
        CALL    HEXW                    ; Display the word
        MOV     AX,STACK_ATTR+BLANK     ; Put a blank after each word
        STOSW                           ; Put that on the screen
        LOOP    DISP_STACK              ; Do the rest of the stack

; Wait for the operator to press the system request key to go to
;  the monitor, or the escape key to perform the reset operation

WAIT_HERE:

        IN      AL,064H                 ; Poll the keystroke port
        TEST    AL,000000001B           ; Did the user hit a key?
        JZ      WAIT_HERE               ; Nope.  Go check again.

        IN      AL,060H                 ; Get the keystroke
        CMP     AL,054H                 ; System request key?
        JNE     CHK_ESC                 ; No.  Check for Esc key.

        CMP     SS:WORD PTR [BP+BP_EX],0EH ; It was system request key.  Now
                                           ;   check for a page fault.
        JE      PAGE_FAULT              ; If so, go remove the extra return code
                                        ;   from the stack and terminate the
                                        ;   application running in the V86 task.
        JMP     POPREGS                 ; Else just return to the V86 task  @P1C

CHK_ESC:
        CMP     AL,001H                 ; Was the Esc key hit?
        JNE     CHKPRT                  ; Nope.  Go check for Print Screen and
                                        ;   Ctrl-Alt-Del.
        MOV     BP,SP                   ; Point BP to the register save area
        CMP     SS:WORD PTR [BP+BP_EX],0EH ; Check for a page fault
        JE      PAGE_FAULT                 ; If so, go remove the extra return
                                           ;   code from the stack and terminate
                                           ;   the application running in the
                                           ;   V86 task.
        MOV     AX,SS:WORD PTR [BP+BP_FL2] ; Else, Esc key hit and no page fault
        TEST    AL,02H                     ; Check who faulted, them or us
        JZ      DO_RESET                   ; If it's us, then reIPL.

TERM_APP:
        MOV     SS:WORD PTR [BP+BP_EX],21H   ; If it's them, termintate whatever
        MOV     SS:WORD PTR [BP+BP_AX],4CFFH ;   is running by forcing a DOS
                                             ;   termintate.  Return code is FF.
        JMP     DO_MONITOR                   ; Go pass the interrupt to the V86
                                             ;   task

PAGE_FAULT:
;
; On a page fault the 80386 processor puts an extra error code on our stack.
; (How handy!)  We now need to remove the extra error code so that when we pop
; the registers off our stack at the end we end up with our stack possitioned
; correctly for the IRET.  To do this, we move everything on the stack that is
; below the extra error code up four bytes.  The error code takes up four bytes.
;

        STD                             ; Shift into reverse, 'cause stacks
                                        ;   grow down
        MOV     CX,(BP_EC-BP_START)/2   ; Load CX with the number of words
        MOV     DI,(BP_EC+2-BP_START)   ; Point DI to the last word of the
        ADD     DI,BP                   ;   extra error code
        MOV     SI,(BP_EC-2-BP_START)   ; Point SI to the last word of the
        ADD     SI,BP                   ;   exception code
        MOV     AX,SS                   ; Set up the selectors
        MOV     ES,AX
        MOV     DS,AX
STACK_LOOP:
        LODSW                           ; Get a word off the stack
        STOSW                           ; And move it up four bytes
        LOOP    STACK_LOOP              ; Do that trick again

        CLD                             ; Shift back into forward
        ADD     BP,4                    ; Scoot BP up four bytes to point to
                                        ;   pur new register save area
        MOV     SP,BP                   ; Adjust SP, too
        JMP     TERM_APP                ; Go kill whatever is running in the V86
                                        ;   task
CHKPRT:
        CMP     AL,053H                 ; Was the Del (as in Ctrl-Alt-Del) key
                                        ;   pressed?
        JE      DO_RESET                ; If so, then reIPL

        CMP     AL,037H                 ; Was the print screen key pressed?
        JNE     WAIT_HERE               ; Nope.  Must be an invalid key.  Go get
                                        ;   another keystroke.

        MOV     BP,SP                   ; It was a print screen.  Reset BP to
                                        ;   point to our register save area.
        MOV     AX,SS:WORD PTR [BP+BP_FL2] ; If is was us that had the problem
        TEST    AL,02H                     ;   then we don't allow print screen
                                           ;   because the system is not healthy
        JZ      WAIT_HERE                  ; Go get another key

        MOV     SS:WORD PTR [BP+BP_EX],05H ; If it was them then we can do a
        JMP     DO_MONITOR                 ;   print screen.  Force the V86
                                           ;   task to do an INT 5 (Prt Sc).

;
; Reset the system, i.e. reIPL.  Put a 1234 in the BIOS reset flag at 472H.
; This will keep BIOS from running through the whole POST upon reIPL.
;

DO_RESET:
        MOV     AX,HUGE_PTR     ; Load ES with a selector that accesses all
        MOV     ES,AX           ;   of memory as data
        DATAOV
        SUB     DI,DI           ; Clear EDI (32 bit DI)
        MOV     DI,472H         ; Load the offset of the BIOS reset flag
        MOV     AX,1234H
        ADDROV
        STOSW                   ; Put 1234 in the BIOS reset flag

        ADDROV                  ; Intel bug # A0-119
        NOP                     ; Intel bug # A0-119

        MOV     AL,0FEH         ; Now OUT a FE to port 64H.  This will cause
        OUT     064H,AL         ;   the machine to reIPL.

HALT:   HLT                     ; Just in case we don't reIPL, this halt    @P1C
        JMP     HALT            ;   loop will keep the processor from doing @P1C
                                ;   anything else

DO_MONITOR:

; If the exception camefrom the V86 task then pass the interrupt to the
; real mode interrupt vector.

         MOV     BP,SP          ; Reset BP to point to our register save area
                                ;   on the stack
         MOV     AX,SS:WORD PTR [BP+BP_FL2] ; Check if it was the V86 task that
         TEST    AL,02H                     ;   faulted
         JNZ     LONGWAY        ; If so, pass the interrupt on
         JMP     POPREGS        ; Otherwise just return                     @P1C

PAGE

; We come here if the check up front said it was the V86 task that faulted.

LONGWAY:
        MOV     SS:WORD PTR [BP+BP_SP2],0 ;Purify high-order words of SP, SS
        MOV     SS:WORD PTR [BP+BP_SS2],0 ;   and IP
        MOV     SS:WORD PTR [BP+BP_IP2],0

; Test for interrupt versus exception.

        CMP     SS:WORD PTR [BP+BP_EX],13     ; Check if it was a general
                                              ;   protection exception
        JNE     LONGWAY2                      ; If not, continue checking
        JMP     EMULATE                       ; If so, then go to INDEEMU to
                                              ;   emulate the instruction
LONGWAY2:
        CMP     SS:WORD PTR [BP+BP_EX],6      ; Was it an invalid op-code
                                              ;   exception?
        JB      LONGWAY4                      ; If lower, then pass the
                                              ;   interrupt back to the V86 task
        CMP     SS:WORD PTR [BP+BP_EX],7      ; Was it a coprocessor not avail-
                                              ;   able exception?
        JA      LONGWAY3                      ; If greater then do more checking
        JMP     EMULATE                       ; Emulation needed for interrupts
                                              ;   6 and 7
LONGWAY3:
        CMP     SS:WORD PTR [BP+BP_EX],15H    ; Check if it was INT 15
        JNE     LONGWAY4                      ; Nope, pass interrupt back to
                                              ;   the V86 task
        JMP     INT15                         ; Emulation needed for INT 15

LONGWAY4:

; Pass the interrupt back to the V86 task.

        MOV     AX,HUGE_PTR             ; Load ES with a selector that accesses
        MOV     ES,AX                   ;   all of memory as data
        DATAOV
        SUB     DI,DI                   ; Clear all 32 bits of EDI
        MOV     DI,SS:[BP+BP_SP]        ; Load DI with the V86 task's SP
        SUB     DI,6                    ; Decrement "SP" to make room for the
                                        ;   push of IP, CS and the flags.
                                        ; Note that this assumes there are at
                                        ;   least 6 bytes keft on the stack.
        MOV     SS:WORD PTR [BP+BP_SP],DI ; Put the new SP into the V86 register
                                          ;   save area
        DATAOV
        SUB     AX,AX                   ; Clear all 32 bits of EAX
        MOV     AX,SS:[BP+BP_SS]        ; Load AX with the V86 task's SS
        DATAOV                          ; Shift it left four bits to convert
        SHL     AX,4                    ;   it to an offset
        DATAOV                          ; Add it on to SP.  Now DI contains
        ADD     DI,AX                   ;   the offest of the stack from 0

; Now put the V86 task's IP, CS and flags on the stack.  They are put on in
; reverse order because the stack grows down, but we are going up as we put
; the stuff on the stack.

        MOV     AX,SS:[BP+BP_IP]        ; Get the V86 task's IP
        ADDROV
        STOSW                           ; Put it on his stack
        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        MOV     AX,SS:[BP+BP_CS]        ; Get the V86 task's CS
        ADDROV
        STOSW                           ; Put it on his stack
        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        MOV     AX,SS:[BP+BP_FL]        ; Get the V86 task's flags
        ADDROV
        STOSW                           ; Put them on his stack
        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119
        AND     AX,3CFFH                ; Clean up the flags for our IRET
        MOV     WORD PTR SS:[BP+BP_FL],AX

        MOV     SI,SS:[BP+BP_EX]        ; Get the interrupt vector
        SHL     SI,2                    ; Multiply by four because interrupt
                                        ;   vectorsare four bytes long
        MOV     AX,HUGE_PTR             ; Load DS with a selector that accesses
        MOV     DS,AX                   ;   all of memory as data
        LODSW                           ; Get the IP for the interrupt
        MOV     WORD PTR SS:[BP+BP_IP],AX ; Store it in the V86 task's IP
        LODSW                           ; Get the CS for the interrupt
        MOV     WORD PTR SS:[BP+BP_CS],AX ; Store it in the V86 task's CS

PAGE
POPREGS:                                ;                                   @P1C

; Pop the saved registers off of our stack and IRET to the V86 task.

        POP     ES                      ; Restore ES
        DATAOV                          ; Restore all the registers
        POPA                            ;   (32 bit registers)
        POP     DS                      ; Restore DS
        ADD     SP,(BP_IP-BP_EX)        ; Step SP past the error code placed
                                        ;   on our stack by the 80386
        DATAOV
        IRET                            ; IRET to the V86 task

SEX     ENDP

SUBTTL  HEXD - Convert DWORD in EAX to ASCII string at ES:DI
PAGE
;
;       INPUT:   EAX   = hex double word to display
;                BH    = attribute byte
;                ES:DI = location in the display buffer where the characters are
;                        to be placed
;
;       OUTPUT:  DI is incremented past last character displayed
;                Characters are placed on the screen
;

HEXD    PROC    NEAR
        DATAOV
        PUSH    AX            ; Save EAX on the stack
        DATAOV
        SHR     AX,24         ; Shift the high order byte into AL
        CALL    HEXB          ; Convert the byte in AL to ASCII at ES:DI
        DATAOV
        POP     AX            ; Restore the original EAX
        PUSH    AX            ; Save the low word of EAX (i.e. AX)
        DATAOV
        SHR     AX,16         ; Shift the second highest byte into AL
        CALL    HEXB          ; Convert the byte in AL to ASCII at ES:DI
        POP     AX            ; Restore the low word of EAX (i.e. AX)
        PUSH    AX            ; And save it again
        XCHG    AH,AL         ; Move the thrid highest byte into AL
        CALL    HEXB          ; Convert the byte in AL to an ASCII string
        POP     AX            ; Restore AX
        CALL    HEXB          ; And conver the last byte to ASCII at ES:DI
        RET

HEXD    ENDP

SUBTTL  HEXW - Convert WORD in AX to ASCII string at ES:DI
PAGE
;
;       INPUT:   AX    = hex word to display
;                BH    = attribute byte
;                ES:DI = location in the display buffer where the characters are
;                        to be placed
;
;       OUTPUT:  DI is incremented past last character
;                Characters are placed on the screen
;

HEXW    PROC    NEAR

        PUSH    AX            ; Save the value in AX on the stack
        XCHG    AH,AL         ; Move the high byte into AL
        CALL    HEXB          ; Convert the byte in AL to a string at ES:DI
        POP     AX            ; Restore AX
        CALL    HEXB          ; Convert the low byte to ASCII at ES:DI
        RET

HEXW    ENDP

SUBTTL  HEXD - Convert BYTE in AL to ASCII string at ES:DI
PAGE
;
;       INPUT:   AL    = hex byte to display
;                BH    = attribute byte
;                ES:DI = location in the display buffer where the characters are
;                        to be placed
;
;       OUTPUT:  DI is incremented past last character
;                Characters are placed on the screen
;

HEXB    PROC    NEAR

        PUSH    AX            ; Save the value in AX
        AND     AL,0F0H       ; Clear the low nibble of AL
        SHR     AL,1          ; Shift the high nibble into the low nibble
        SHR     AL,1
        SHR     AL,1
        SHR     AL,1
        ADD     AL,030H       ; Add '0' to convert to ASCII
        CMP     AL,03AH       ; Was this hex digit greater than 9?
        JC      OK1           ; Nope.  It's OK, so go display it.
        ADD     AL,7          ; Yup.  Then convert to 'A' to 'F'.
OK1:    MOV     AH,BH         ; Move the attribute into AH
        STOSW                 ; Put the character & attribute into the display
                              ;   buffer at ES:DI
        POP     AX            ; Restore AX
        AND     AL,00FH       ; Clear the high nibble of AL
        ADD     AL,030H       ; Convert the low nibble to ASCII as before
        CMP     AL,03AH       ; Hex digit greater than 9?
        JC      OK2           ; Nope.  It's OK, so go display it.
        ADD     AL,7          ; Yup.  Then convert to 'A' to 'F'.
OK2:    MOV     AH,BH
        STOSW
        RET

HEXB    ENDP

        PAGE

REG     MACRO   NAME,ROW,COL,L
        DB      &ROW                    ; Display of register &NAME starts in
        DB      &COL                    ;   row &ROW and column &COL
        DB      '&NAME:'                ; Name to display for register &NAME
        DB      0                       ; End of string marker
        DW      BP_&NAME                ; Offset of value of register &NAME
                                        ;   that we saved on our stack
        DW      &L                      ; Number of words in the register
        ENDM

SUBTTL  Register table
PAGE
REG_TABLE LABEL NEAR
;
; Declare data used for displaying the registers on the screen.  For each
; register there is a structure that contains the row and column of where the
; display of the register starts, the text or register name ended with a 0, the
; offset into the stack where the value in the register was saved, and the
; number of words in the register.
;

; First, lets fake a register to put the exception message on the screen.

        DB      1                       ; Row 1
        DB      10                      ; Column 10
        DB      'System Exception - '   ; Text
        DB      0                       ; End of text
        DW      BP_EX                   ; Offset to hex value on the stack
        DW      1                       ; Number of words of data

; Now, fake one to put the task id (bank ID) on the screen.

        DB      1                       ; Row 1
        DB      50                      ; Column 50
        DB      'Task ID - '            ; Text
        DB      0                       ; End of text
        DW      BP_PSP2                 ; Offset to hex value on the stack
        DW      1                       ; Number of words of data

; Now, lets do the registers

        REG     CS,3,1,1
        REG     IP,3,9,2
        REG     SS,3,21,1
        REG     SP,3,29,2
        REG     DS,3,41,1
        REG     SI,3,49,2
        REG     ES,3,61,1
        REG     DI,3,69,2

        REG     AX,4,1,2
        REG     BX,4,13,2
        REG     CX,4,25,2
        REG     DX,4,37,2
        REG     BP,4,49,2
        REG     EC,4,61,2

        REG     FL,5,1,2
        REG     VMDS,5,18,1
        REG     VMES,5,33,1
        REG     VMFS,5,48,1
        REG     VMGS,5,63,1

PROG    ENDS

        END

