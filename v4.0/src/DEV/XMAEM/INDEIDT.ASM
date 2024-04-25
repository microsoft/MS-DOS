PAGE    60,132
TITLE   INDEIDT - 386 XMA Emulator - Build Interrupt Descriptor Table

COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEIDT                                                   *
*                                                                             *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corp.              *
*	                                                                      *
* DESCRIPTIVE NAME: Build the Interrupt Descriptor Table (IDT)                *
*                                                                             *
* STATUS (LEVEL)  : Version (0) Level (2.0)                                   *
*                                                                             *
* FUNCTION        : Build the Interrupt Descriptor Table for the 80386 XMA    *
*                   emulator.                                                 *
*                                                                             *
* MODULE TYPE     : ASM                                                       *
*                                                                             *
* REGISTER USAGE  : 80386 Standard                                            *
*                                                                             *
* RESTRICTIONS    : None                                                      *
*                                                                             *
* DEPENDENCIES    : None                                                      *
*                                                                             *
* ENTRY POINT     : SIDT_BLD (not to be confused with SIDTBLD)                *
*                                                                             *
* LINKAGE         : Called by INDEINI                                         *
*                                                                             *
* INPUT PARMS     : None                                                      *
*                                                                             *
* RETURN PARMS    : None                                                      *
*                                                                             *
* OTHER EFFECTS   : None                                                      *
*                                                                             *
* EXIT NORMAL     : Return to INDEINI                                         *
*                                                                             *
* EXIT ERROR      : None                                                      *
*                                                                             *
* EXTERNAL                                                                    *
* REFERENCES      : VEXCP13 - Entry point for INDEEXC                         *
*                                                                             *
* SUB-ROUTINES    : BLD_IDT - Put the entries into the IDT                    *
*                                                                             *
* MACROS          : DATAOV - Create a prefix for the following instruction    *
*                            so that it accesses data 32 bits wide            *
*                   ADDROV - Create a prefix for the following instruction    *
*                            so that it uses addresses that are 32 bits wide  *
*                                                                             *
* CONTROL BLOCKS  : INDEDAT                                                   *
*                                                                             *
* CHANGE ACTIVITY :                                                           *
*                                                                             *
* $MOD(INDEIDT) COMP(LOAD) PROD(3270PC) :                                     *
*                                                                             *
* $D0=D0004700 410 870530 D : NEW FOR RELEASE 1.1                             *
* $P1=P0000312 410 870803 D : CHANGE COMPONENT FROM MISC TO LOAD              *
* $P2=P0000xxx 120 880517 D : HANDLE INT 0D FROM V86 TASK, I.E., OPTICAL DISK *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

        .286P                 ; Enable recognition of 286 privileged instructs.

        .XLIST                ; Turn off the listing
        INCLUDE INDEDAT.INC   ; System data structures and equates

        IF1                   ; Only include macros on the first pass
        INCLUDE INDEOVP.MAC
        ENDIF
        .LIST                 ; Turn on the listing
PAGE

PROG    SEGMENT PARA    PUBLIC  'PROG'

        ASSUME  CS:PROG
        ASSUME  SS:NOTHING
        ASSUME  DS:NOTHING
        ASSUME  ES:NOTHING

INDEIDT LABEL   NEAR

; Let these entry points be known to other modules.

        PUBLIC  INDEIDT
        PUBLIC  SIDT_BLD

; This is the entry point to INDEEXC.

        EXTRN   VEXCPT13:NEAR

PAGE
; Define the stack structure for our fast path.  For all the interrupts that we
; don't want to handle we just pass the interrupt back to the real interrupt
; vector.  The entry points for these vectors push the interrupt vector offset
; (interrupt number * 4) onto the stack and then call FASTPATH to pass the
; interrupt to the real vector.  FASTPATH pushes BP, AX, DI and SI on to the
; stack.  The following structure is a map of the stack after these registers
; are pushed.  This structure allows us to access info on the stack.

SPSTACK STRUC

SP_SI   DW      0             ; Saved ESI (32 bit SI)
        DW      0
SP_DI   DW      0             ; Saved EDI (32 bit DI)
        DW      0
SP_AX   DW      0             ; Saved EAX
        DW      0
SP_BP   DW      0             ; Saved BP (only 16 bits)
SP_EX   DW      0             ; Interrupt vector offset (interrupt number * 4)

; The following information is saved by the 80386

SP_IP   DW      0             ; Interruptee's EIP (32 bit IP)
SP_IP2  DW      0
SP_CS   DW      0             ; Interruptee's CS (16 bit CS and 16 bit junk)
SP_CS2  DW      0
SP_FL   DW      0             ; Interruptee's Eflags (32 bit flags)
SP_FL2  DW      0
SP_SP   DW      0             ; Interruptee's ESP
SP_SP2  DW      0
SP_SS   DW      0             ; Interruptee's SS
SP_SS2  DW      0
SP_VMES DW      0             ; Interruptee's ES
        DW      0
SP_VMDS DW      0             ; Interruptee's DS
        DW      0
SP_VMFS DW      0             ; Interruptee's FS
        DW      0
SP_VMGS DW      0             ; Interruptee's GS
        DW      0
SP_STK  DW      0             ; The rest of the stack

SPSTACK ENDS

SP_START EQU    0             ; Offset from BP of the start of the save area
                              ; BP is set ot point to the start of the save area

PAGE

SIDTBLD         PROC    NEAR

; Generate the entry points for all (yes, ALL) 256 interrupt vectors.  For
; interrupt 0D (general Protection exception) we will check if it was the V86
; task that faulted.  If so, then we will just pass the interrupt back to the
; V86 task.  Else, we will go to our exception handler since the interrupt
; happened because of the emulator.
;
; For interrupts 00, 01, 02, 03, 04, 05, 06, 07, 09, 0A, 0B, 0C, 0E and 15 we
; will go to our exception handler.
;
; For all other interrupts we will go to the FASTPATH routine which will pass
; the interrupt back to the V86 interrupt vector.
;
; Note: For interrupts that go to our exception handler we push a 32 bit error
;       code and then push the interrupt number.  For the FASTPATH interrupts
;       we push the interrupt vector offset (interrupt number *4).  This results
;       in different stack structures depending on how the interrupt is handled.
;       So be careful when you're trying to figure out what's on the stack.
;

; Interrupt 0D

                IRP     V,<0D>
VEC&V:
                PUSH    0&V&H           ; Push the interrupt number (0D)
                PUSH    BP              ; Save BP
                DATAOV                  ;                                   @P2A
                PUSH    AX              ; Save EAX, all 32bits of it.       @P2A
                DATAOV                  ;                                   @P2A
                PUSH    DI              ; Save EDI                          @P2A
                DATAOV                  ;                                   @P2A
                PUSH    SI              ; Save ESI                          @P2A
                MOV     BP,SP           ; Point BP to the save area         @P2A

                ; Now we must check if the INT 0D came from the V86 task     P2A
                ; or if it was a General Protection exception.  In the       P2A
                ; case of a General Protection exception the 80386 puts      P2A
                ; an error code on the stack after pushing the EFLAGS, CS    P2A
                ; and EIP.  The error code is 32 bits wide.  If the V86      P2A
                ; task issues an INT 0D, an error code is NOT placed on      P2A
                ; the stack.  In this case we want to pass the interrupt     P2A
                ; back to the V86 task instead of going to our exception     P2A
                ; handler.  The way we check for an error code is by         P2A
                ; checking how much ESP has been decremented since the       P2A
                ; start of the interrupt.  The original ESP is saved in      P2A
                ; the TSS.  Our stack definition above does not include      P2A
                ; an error code.  So if ESP has been decremented more than   P2A
                ; the size of our structure, we can know that an error       P2A
                ; code is on the stack and then go to our exception          P2A
                ; handler.                                                   P2A

                MOV     AX,SCRUBBER.TSS_PTR ; Load DS with the selector     @P2A
                MOV     DS,AX           ;   that accesses the TSS as data   @P2A
                MOV     SI,0            ; Base for reading the TSS          @P2A
                DATAOV                  ;                                   @P2A
                MOV     AX,[SI].ETSS_SP0 ; Get the original SP before the   @P2A
                DATAOV                  ;   interrupt                       @P2A
                SUB     AX,SP           ; Subtract the current stack        @P2A
                                        ;   pointer                         @P2A
                CMP     AX,SP_STK       ; Check for an error code           @P2A
                                        ;                                   @P2D
                JG      SKIP&V          ; If there's an error code, go      @P2C
                                        ; handle the exception               P2C
                MOV     WORD PTR [BP+SP_EX],0&V&H*4 ; If there is no error  @P2A
                                        ; code then multiply the vector      P2A
                                        ; number by four for the FASTPATH    P2A
                                        ; code.                              P2A
                JMP     PASS_ON         ; Give the interrupt back to the    @P2C
                                        ;   V86 task.
SKIP&V:         DATAOV                  ;                                   @P2A
                POP     SI              ; Restore ESI from off our stack    @P2A
                DATAOV                  ;                                   @P2A
                POP     DI              ; Restore EDI                       @P2A
                DATAOV                  ;                                   @P2A
                POP     AX              ; Restore EAX                       @P2A
                POP     BP              ; Take BP off the stack.  This leaves
                                        ;   the interrupt number that we pushed
                                        ;   above and the error code that was
                                        ;   pushed by the 386 on the INT 0D.
                JMP     VEXCPT13        ; Go to the exception handler.

                ENDM

PAGE
; For interrupts 00, 01, 02, 03, 04, 05, 06, 07, 09, 0A, 0B, 0C, 0E and 15
; push a dummy error code of 0 and then the interrupt number.  Then go to the
; exception handler.

                IRP     V,<00,01,02,03,04,05,06,07,09,0A,0B,0C,0E,15>
VEC&V:
                PUSH    0               ; Push a dummy error code of 0
                PUSH    0               ; 32 bits wide
SKIP&V:
                PUSH    0&V&H           ; Push the interrupt number
                JMP     VEXCPT13        ; Go to the exception handler
                ENDM

PAGE
; For the rest of the interrupts push the interrupt vector offset (interrupt
; number * 4) and go to the fast path routine.
;
; INT 08H is given the FASTPATH.  It's the double fault interrupt so we are
; dead any way.  This interrupt is normally used for the timer interrupt.
;
; INT 10H, BIOS video calls, is given the fastest code path by putting it just
; before the FASTPATH routine.

                IRP     V,<08,0F,11,12,13,14,16,17,18,19,1A,1B,1C,1D,1E,1F>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<20,21,22,23,24,25,26,27,28,29,2A,2B,2C,2D,2E,2F>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<30,31,32,33,34,35,36,37,38,39,3A,3B,3C,3D,3E,3F>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<40,41,42,43,44,45,46,47,48,49,4A,4B,4C,4D,4E,4F>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<50,51,52,53,54,55,56,57,58,59,5A,5B,5C,5D,5E,5F>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<60,61,62,63,64,65,66,67,68,69,6A,6B,6C,6D,6E,6F>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<70,71,72,73,74,75,76,77,78,79,7A,7B,7C,7D,7E,7F>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<80,81,82,83,84,85,86,87,88,89,8A,8B,8C,8D,8E,8F>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<90,91,92,93,94,95,96,97,98,99,9A,9B,9C,9D,9E,9F>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,AA,AB,AC,AD,AE,AF>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,BA,BB,BC,BD,BE,BF>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<C0,C1,C2,C3,C4,C5,C6,C7,C8,C9,CA,CB,CC,CD,CE,CF>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<D0,D1,D2,D3,D4,D5,D6,D7,D8,D9,DA,DB,DC,DD,DE,DF>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<E0,E1,E2,E3,E4,E5,E6,E7,E8,E9,EA,EB,EC,ED,EE,EF>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM
                IRP     V,<F0,F1,F2,F3,F4,F5,F6,F7,F8,F9,FA,FB,FC,FD,FE,FF>
VEC&V:
                PUSH    0&V&H*4         ; Push the interrupt vector offset
                JMP     FASTPATH        ; Go to the fastpath routine
                ENDM

VEC10:
                PUSH    010H*4          ; Push the interrupt vector offset

PAGE
FASTPATH:
        PUSH    BP                      ; Save BP
        DATAOV
        PUSH    AX                      ; Save EAX, all 32bits of it.
        DATAOV
        PUSH    DI                      ; Save EDI
        DATAOV
        PUSH    SI                      ; Save ESI
        MOV     BP,SP                   ; Point BP to the save area

PASS_ON:                                ;                                  @P2C
        CLD                             ; All string operations go forward

        MOV     AX,HUGE_PTR             ; Load DS and ES with a selector that
        MOV     DS,AX                   ;   accesses all of memory as data
        MOV     ES,AX
        DATAOV
        SUB     DI,DI                   ; Clear EDI
        MOV     DI,SS:[BP+SP_SP]        ; Load DI with the interruptee's SP
        SUB     DI,6                    ; Decrement "SP" to simulate the pushing
                                        ;   of the flags, CS and IP on an INT.
        MOV     SS:WORD PTR [BP+SP_SP],DI ; Replace the user's SP

        DATAOV
        SUB     AX,AX                   ; Clear EAX
        MOV     AX,SS:[BP+SP_SS]        ; Load AX with the user's SS register
        DATAOV                          ; Shift "SS" left four bits to convert
        SHL     AX,4                    ;   it to an offset
        DATAOV                          ; Add on "SP" to get a 32 bit offset
        ADD     DI,AX                   ;   from 0 of the user's stack.

; Put the user's IP, CS and flags onto his stack.  This is done in reverse
; order because we are moving forward in memory whereas stacks grow backward.

        MOV     AX,SS:[BP+SP_IP]        ; Get the user's IP
        ADDROV
        STOSW                           ; And put it on the stack
        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        MOV     AX,SS:[BP+SP_CS]        ; Get the user's CS
        ADDROV
        STOSW                           ; And put it on the stack
        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        MOV     AX,SS:[BP+SP_FL]        ; Get the user's flags
        ADDROV
        STOSW                           ; And put them on the stack
        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        AND     AX,3CFFH                ; Clean up the flags for our IRET by
        MOV     WORD PTR SS:[BP+SP_FL],AX  ; setting IOPL to 3

; Replace the interruptee's CS:IP with the CS:IP of the interrupt vector.  When
; we IRET back to the V86 task control will go to the interrupt routine.

        MOV     SI,SS:[BP+SP_EX]        ; Get the interrupt vector offset
        LODSW                           ; Get the IP of the interrupt vector
        MOV     WORD PTR SS:[BP+SP_IP],AX ; Replace the user's IP
        LODSW                           ; Get the CS of the interrupt vector
        MOV     WORD PTR SS:[BP+SP_CS],AX ; Replace the user's CS

        DATAOV
        POP     SI                      ; Restore ESI from off our stack
        DATAOV
        POP     DI                      ; Restore EDI
        DATAOV
        POP     AX                      ; Restore EAX
        POP     BP                      ; Restore BP
        ADD     SP,(SP_IP-SP_EX)        ; Step SP past the interrupt vector
                                        ;   offset
        DATAOV
        IRET                            ; Give control back to the interruptee

PAGE

; Build a talbe of the offsets of all the interrupt entry points.  This table
; is used as input to the procedure that builds the IDT.

SIDT_OFFSETS            LABEL   WORD

                IRP     V,<00,01,02,03,04,05,06,07,08,09,0A,0B,0C,0D,0E,0F>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<10,11,12,13,14,15,16,17,18,19,1A,1B,1C,1D,1E,1F>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<20,21,22,23,24,25,26,27,28,29,2A,2B,2C,2D,2E,2F>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<30,31,32,33,34,35,36,37,38,39,3A,3B,3C,3D,3E,3F>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<40,41,42,43,44,45,46,47,48,49,4A,4B,4C,4D,4E,4F>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<50,51,52,53,54,55,56,57,58,59,5A,5B,5C,5D,5E,5F>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<60,61,62,63,64,65,66,67,68,69,6A,6B,6C,6D,6E,6F>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<70,71,72,73,74,75,76,77,78,79,7A,7B,7C,7D,7E,7F>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<80,81,82,83,84,85,86,87,88,89,8A,8B,8C,8D,8E,8F>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<90,91,92,93,94,95,96,97,98,99,9A,9B,9C,9D,9E,9F>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,AA,AB,AC,AD,AE,AF>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,BA,BB,BC,BD,BE,BF>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<C0,C1,C2,C3,C4,C5,C6,C7,C8,C9,CA,CB,CC,CD,CE,CF>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<D0,D1,D2,D3,D4,D5,D6,D7,D8,D9,DA,DB,DC,DD,DE,DF>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<E0,E1,E2,E3,E4,E5,E6,E7,E8,E9,EA,EB,EC,ED,EE,EF>
                DW      OFFSET VEC&V
                ENDM
                IRP     V,<F0,F1,F2,F3,F4,F5,F6,F7,F8,F9,FA,FB,FC,FD,FE,FF>
                DW      OFFSET VEC&V
                ENDM
PAGE
SIDT_BLD:

; Build the system IDT.  The system IDT will contain 256 interrupt gates.

        MOV     AX,CS                   ; Set DS:SI to point to the table of
        MOV     DS,AX                   ;   interrupt entry points
        MOV     SI,OFFSET SIDT_OFFSETS

        MOV     DI,SIDT_LOC             ; Set ES:DI to point to the beginning
                                        ;   of the IDT
        MOV     BX,SYS_PATCH_CS         ; Load BX with the selector for the
                                        ;   segment of the interrupt routines.
                                        ;   It's our code segment.

;       DX contains the second highest word of the interrupt descriptor.

        MOV     DH,0EEH                 ; Set DPL to 3 to reduce the number of
                                        ;   exceptions
        MOV     DL,0                    ; The word count field is unused

        MOV     CX,256                  ; 256 interrupt gates

        CALL    BLD_IDT                 ; Go build the IDT

        RET                             ; Return to INDEINI

PAGE

; This loop builds descriptors in the IDT.  DS:SI points to a table of 16 bit
; offsets for the interrupt entry points.  ES:DI points to the start of the IDT.
; BX contains the segment selector of the interrupt entry points.  DX contains
; the DPL of the interrupt gates.

BLD_IDT:
        MOVSW                         ; Get an interrupt routine entry point
                                      ;   and put it in the offset field
        MOV     AX,BX                 ; Get the segment selector
        STOSW                         ;   and put it in the selector field
        MOV     AX,DX                 ; Get the interrupt gate DPL
        STOSW                         ;   and put it in the access rights field
        MOV     AX,0                  ; Zero out the reserved portions
        STOSW
        LOOP    BLD_IDT               ; Repeat for all interrupt vectors

        RET

SIDTBLD ENDP

PROG    ENDS

        END
