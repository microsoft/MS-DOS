PAGE    60,132
TITLE   INDEI15 - 386 XMA Emulator - Interrupt 15 handler

COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEI15                                                   *
*                                                                             *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corp.              *
*                                                                             *
* DESCRIPTIVE NAME: Interrupt 15H handler for the 80386 XMA emulator          *
*                                                                             *
* STATUS (LEVEL)  : Version (0) Level (2.0)                                   *
*                                                                             *
* FUNCTION        : This module emulates the MOVEBLOCK functions of interrupt *
*                   15H.  The MOVEBLOCK functions are specified by an AH value*
*                   of 87H to 89H.  The user can use the MOVEBLOCK functions  *
*                   to copy a block of memory to another block of memory.     *
*                   This includes copying to and from memory above 1M.  This  *
*                   is really where this function comes in handy.  The user   *
*                   can reserve memory above 1M for use by the MOVEBLOCK      *
*                   functions by specifying the number of K to be reserved as *
*                   a parameter on the line to load the emulator in the       *
*                   CONFIG.SYS file.                                          *
*                                                                             *
*                        DEVICE=INDXMAEM.SYS bbb                              *
*                                                                             *
*                        "bbb" is the number of K to reserve for MOVEBLOCK    *
*                        functions                                            *
*                                                                             *
*                   We allocate a buffer for the MOVEBLOCK functions at the   *
*                   top of available memory.  Any functions dealing with this *
*                   buffer area must be handles by us.                        *
*                                                                             *
*                   Function 87H is the actual MOVEBLOCK function.  The user  *
*                   passes a 32 bit source address and a 32 bit destination   *
*                   address in a parameter list pointed to by ES:SI.  CX      *
*                   contains the number of words to copy.  We need to         *
*                   intercept this call and check the source and destination  *
*                   addresses.  If either or both of these addresses is above *
*                   1M then we need to adjust the addresses so that they      *
*                   access the MOVEBLOCK buffer up at the top of memory.  You *
*                   see, the user thinks the extended memory starts right     *
*                   after the 1M boundary.  We want to make it look like the  *
*                   MOVEBLOCK buffer sits right after the 1M boundary.  So we *
*                   monkey with the user's addresses so that they access the  *
*                   MOVEBLOCK buffer instead of real memory after 1M, because *
*                   that memory is us.                                        *
*                                                                             *
*                   Function 88H queries how many K are above the 1M          *
*                   boundary.  We can't tell him how much is really there     *
*                   because some of it is us and our XMA pages.  So for this  *
*                   function we will just return the size of the MOVEBLOCK    *
*                   buffer.  This function was moved to a real mode        P3C*
*                   interrupt handler in module INDE15H.                   P3C*
*                                                                             *
*                   Function 89H is reserved for the MOVEBLOCK functions but  *
*                   is not in use right now.  So for this function we just    *
*                   return a bad return code in AH and set the carry flag.    *
*                                                                             *
* MODULE TYPE     : ASM                                                       *
*                                                                             *
* REGISTER USAGE  : 80386 Standard                                            *
*                                                                             *
* RESTRICTIONS    : None                                                      *
*                                                                             *
* DEPENDENCIES    : None                                                      *
*                                                                             *
* ENTRY POINT     : INT15                                                     *
*                                                                             *
* LINKAGE         : Jumped to from INDEEXC                                    *
*                                                                             *
* INPUT PARMS     : None                                                      *
*                                                                             *
* RETURN PARMS    : None                                                      *
*                                                                             *
* OTHER EFFECTS   : None                                                      *
*                                                                             *
* EXIT NORMAL     : Go to POPIO in INDEEMU to IRET to the V86 task            *
*                                                                             *
* EXIT ERROR      : None                                                      *
*                                                                             *
* EXTERNAL                                                                    *
* REFERENCES      : EMULATE - Entry point for INDEEMU                         *
*                   POPIO   - Entry in INDEEMU to check for single step       *
*                             interrupts, pop the registers and IRET to the   *
*                             V86 task                                        *
*                   POPREGS - Entry point in INDEEXC to pop the registers     *
*                             off the stack and IRET to the V86 task       P2C*
*                                                                             *
* SUB-ROUTINES    : None                                                      *
*                                                                             *
* MACROS          : DATAOV  - Add prefix for the next instruction so that it  *
*                             accesses data as 32 bits wide                   *
*                   ADDROV  - Add prefix for the next instruction so that it  *
*                             uses addresses that are 32 bits wide            *
*                                                                             *
* CONTROL BLOCKS  : INDEDAT.INC                                               *
*                                                                             *
* CHANGE ACTIVITY :                                                           *
*                                                                             *
* $MOD(INDEI15) COMP(LOAD) PROD(3270PC) :                                     *
*                                                                             *
* $D0=D0004700 410 870603 D : NEW FOR RELEASE 1.1                             *
* $P1=P0000293 410 870731 D : LIMIT LINES TO 80 CHARACTERS                    *
* $P2=P0000312 410 870804 D : CLEAN UP WARNING MESSAGES                       *
* $D1=D0007100 410 870817 D : CHANGE TO EMULATE XMA 2                         *
* $P3=P0000xxx 120 880331 D : MOVE FUNCTION 88H HANDLING TO INDE15H           *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

        .286P                 ; Enable recognition of 286 privileged instructs.

        .XLIST                ; Turn off the listing
        INCLUDE INDEDAT.INC   ; Include the system data structures

        IF1                   ; Only include the macros on the first pass
        INCLUDE INDEOVP.MAC
        ENDIF
        .LIST                 ; Turn on the listing

PROG    SEGMENT PARA PUBLIC 'PROG'

        ASSUME  CS:PROG
        ASSUME  DS:PROG
        ASSUME  ES:NOTHING
        ASSUME  SS:NOTHING

INDEI15 LABEL   NEAR

        EXTRN   EMULATE:NEAR            ; Entry point for INDEEMU
        EXTRN   POPIO:NEAR              ; Entry in INDEEMU to check for single
                                        ;   step interrupts and return to the
                                        ;   V86 task
        EXTRN   POPREGS:NEAR            ; Entry in INDEEXC to return to the  P2C
                                        ;   V86 task

        PUBLIC  INDEI15
        PUBLIC  INT15
        PUBLIC  TTTABLE

PAGE

INT15   PROC    NEAR

        CLD                             ; All string operations go forward

; We handle the INT 15H functions for MOVEBLOCK interface.  These functions
; are specified by an AH value of 87H to 89H.  Function 87H is the MOVEBLOCK
; function.  Function 88H queries the size of memory above 1M.  Function 89H
; is reserved but not supported so we return a return code of 86H.

        CMP     SS:BYTE PTR [BP+BP_AX+1],87H ; Is AH asking for function 87H?
        JB      NOTMINE                 ; No.  It's too low.  It's out of our
                                        ;   range so we'll pass it on to the
                                        ;   real vector.
        JE      MOVEBLK                 ; It is 87H!  Let's go do the MOVEBLOCK.

        CMP     SS:BYTE PTR [BP+BP_AX+1],89H ; Is AH asking for function 89H?
        JNE     NOTMINE                 ; No.  It's not our function so     @P3C
                                        ;   so we'll pass it on to the real
                                        ;   vector.
                                        ;                                   @P3D
        MOV     SS:BYTE PTR [BP+BP_AX+1],86H ; It's 89H.  Sorry we don't support
                                        ;   that function.  Put an 86H return
                                        ;   code in AH.
        OR      WORD PTR SS:[BP+BP_FL],1 ; Set the carry flag
        JMP     POPIO                   ; And return to the V86 task

; Hey, it's not MY interrupt.

NOTMINE:
        JMP     DOINT                   ; Go pass the interrupt back to the
                                        ;   real INT 15H vector


; Function 88H code to query the size of memory above 1M was moved to      3@P3D
; INDE15H.

PAGE
; The user wants to move a block of memory.  Now the source and target of the
; MOVEBLOCK can each be below 1M or above 1M.  For addresses above 1M we must
; make adjustments so that the MOVEBLOCK is done to and/or from the MOVEBLOCK
; buffer in high memory.  The user passes a parameter list which is pointed
; at by ES:SI.  At offset 0EH is a 32 bit pointer to the source block.  At
; offset 1AH is a 32 bit pointer to the destination block.  CX contains the
; number of words to move.  Here we go!

MOVEBLK:
        MOV     AX,HUGE_PTR             ; Load DS and ES with a selector that
        MOV     DS,AX                   ;   accesses all of memory as data
        MOV     ES,AX

; Get the user's ES:SI and convert it to a 32 bit offset in ESI.

        DATAOV                          ; Purge ESI
        SUB     SI,SI
        MOV     SI,SS:[BP+BP_SI]        ; Load SI with the user's SI

        DATAOV                          ; Purge EBX
        SUB     BX,BX
        MOV     BX,10H                  ; Set EBX to 1M by loading it with 10H
        DATAOV                          ;   and shifting it left 16 bits to
        SHL     BX,16                   ;   multiply by 64K

        DATAOV                          ; Sterilize EAX
        SUB     AX,AX
        MOV     AX,SS:[BP+BP_VMES]      ; Load AX with the user's ES
        DATAOV                          ; Shift it left four bits to convert it
        SHL     AX,4                    ;   to an offset

        DATAOV                          ; Add the ES offset on to SI.  Now ESI
        ADD     SI,AX                   ;   is the offset from 0 of the user's
                                        ;   parameter list.
        DATAOV                          ; Add 1AH to SI.  Now it points to the
        ADD     SI,1AH                  ;   32 bit destination address.

        DATAOV
        ADDROV                          ; Get the 32 bit destination address
        LODSW                           ;   into EAX

        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        DATAOV                          ; Clear the top eight bits of any
        SHL     AX,8                    ;   residual gunk.  Only 24 bit     ;P1C
        DATAOV                          ;   addresses (16M) are allowed anyway.
        SHR     AX,8                    ;   Shift the bits off the left end and
                                        ;   shift zeroes back in.
        DATAOV                          ; Move this clean value into EDI
        MOV     DI,AX                   ; EDI now has the destination address

        DATAOV                          ; Check if this address is over 1M.  If
        CMP     DI,BX                   ;   so then it's going to our MOVEBLOCK
                                        ;   buffer.
        JB      OK1                     ; It's below 1M?  OK.  Leave it alone.

; The destination is above 1M so we have to modify the destination address so
; that it points to our MOVEBLOCK buffer.

        PUSH    DS                      ; Save DS
        MOV     AX,SYS_PATCH_DS         ; Load DS with the selector for our data
        MOV     DS,AX                   ;   segment

        DATAOV                          ; Clean up EAX
        SUB     AX,AX
        MOV     AX,MAXMEM               ; Load the total number of K on the box
        SUB     AX,BUFF_SIZE            ; Subtract the MOVEBLOCK buffer size
        SUB     AX,1024                 ; Subtract 1M (/1K) for 0 to 1M.  This
                                        ;   leaves AX with the number of K from
                                        ;   1M to the MOVEBLOCK buffer.
        POP     DS                      ; Restore DS
        DATAOV                          ; Multiply EAX by 1K (shift left 10) to
        SHL     AX,10                   ;   convert it to an offset from 1M of
                                        ;   the MOVEBLOCK buffer
        DATAOV                          ; Add this to EDI.  EDI now points to
        ADD     DI,AX                   ;   a location within (hopefully) the
                                        ;   MOVEBLOCK buffer as if the buffer
                                        ;   were located at the 1M boundary.

; Now let's get the source address

OK1:
        DATAOV                          ; Subtract 0C from ESI to point ESI to
        SUB     SI,0CH                  ;   offset 0E in the parameter list

        DATAOV
        ADDROV                          ; Get the 32 bit source address into
        LODSW                           ;   EAX

        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        DATAOV                          ; Clear the top eight bits of any
        SHL     AX,8                    ;   residual gunk.  Only 24 bit address
        DATAOV                          ;   (16M) are allowed.  Shift the gunky
        SHR     AX,8                    ;   bits off the left end and shift
                                        ;   zeroes back in.
        DATAOV                          ; Move this clean value into ESI
        MOV     SI,AX                   ; ESI now has the source address

        DATAOV                          ; Check if this address is over 1M.  If
        CMP     SI,BX                   ;   so then it's goin' to our MOVEBLOCK
                                        ;   buffer.
        JB      OK2                     ; It's below 1M?  OK.  Let it be.

; The source is above 1M so we have to modify the source address so that it
; points to our MOVEBLOCK buffer.

        PUSH    DS                      ; Save DS
        MOV     AX,SYS_PATCH_DS         ; Load DS with the selector for our data
        MOV     DS,AX                   ;   segment

        DATAOV                          ; Sanitize up EAX
        SUB     AX,AX
        MOV     AX,MAXMEM               ; Load the total number of K on the box
        SUB     AX,BUFF_SIZE            ; Subtract the MOVEBLOCK buffer size
        SUB     AX,1024                 ; Subtract 1M (/1K) for 0 to 1M.  This
                                        ;   leaves AX with the number of K from
                                        ;   1M to the MOVEBLOCK buffer.
        POP     DS                      ; Restore DS
        DATAOV                          ; Multiply EAX by 1K (shift left 10) to
        SHL     AX,10                   ;   convert it to an offset from 1M of
                                        ;   the MOVEBLOCK buffer
        DATAOV                          ; Add this to ESI.  ESI now points to
        ADD     SI,AX                   ;   a location within (hopefully) the
                                        ;   MOVEBLOCK buffer as if the buffer
                                        ;   were located at the 1M boundary.

; Our pointers are all set.  Let's get CX and do the copy for the guy.

OK2:
        MOV     CX,SS:[BP+BP_CX]        ; Get the user's CX
        TEST    CL,01H                  ; Is this an even number?
        JZ      MOV4                    ; If so, we can make the copy faster
                                        ;   by moving double words
        ADDROV                          ; Nope. It's odd.  We'll just do the
        REP     MOVSW                   ;   copy with words.

        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        JMP     MOVCOM                  ; Skip over the double word copy

MOV4:
        SHR     CX,1                    ; Divide the count by two since we'll
                                        ;   be copying double words
        DATAOV                          ; Do it 32 bits wide
        ADDROV                          ; Use the 32 bit ESI and EDI
        REP     MOVSW                   ; Ready?  ZOOOOM!

        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

; Now let's set the flags and return code in AH to show that every thing went
; A-OK.

MOVCOM:
        MOV     SS:BYTE PTR [BP+BP_AX+1],0    ; Set a zero return code in AH
        AND     WORD PTR SS:[BP+BP_FL],0FFFEH ; Reset the carry flag
        OR      WORD PTR SS:[BP+BP_FL],40H    ; Set the zero flag

        JMP     POPIO                   ; Return to the V86 task

PAGE

; It's not a MOVEBLOCK function so we'll just pass the interrupt on to the real
; interrupt handler.

DOINT:
        MOV     AX,HUGE_PTR             ; Load ES with a selector that accesses
        MOV     ES,AX                   ;   all of memory as data
        DATAOV                          ; Load EDI with the user's ESP
        MOV     DI,SS:[BP+BP_SP]

        SUB     DI,6                    ; Decrement "SP" by six to make room
                                        ;   for our simulated interrupt that
                                        ;   will put the flags, CS and IP on
                                        ;   the stack.   This assumes that there
                                        ;   are indeed six bytes left on the
                                        ;   stack.
        MOV     SS:WORD PTR [BP+BP_SP],DI ; Set the user's new SP

        DATAOV                          ; Get the user's SS into our AX
        MOV     AX,SS:[BP+BP_SS]
        DATAOV                          ; Shift "SS" left four bits to convert
        SHL     AX,4                    ;   it to an offset
        DATAOV                          ; Add this to "SP" in DI to make EDI
        ADD     DI,AX                   ;   a 32 bit offset from 0 of the user's
                                        ;   stack

; Now put the flags, CS and IP on the V86 task's stack.  They are put on in the
; order IP, CS, flags.  This is backwards from the INT push order of flags, CS
; and then IP.  This is because we are moving forward through memory (CLD)
; whereas the stack grows backwards through memory as things pushed on to it.

        MOV     AX,SS:[BP+BP_IP]        ; Get the user's IP
        ADDROV                          ; And put it on his stack
        STOSW

        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        MOV     AX,SS:[BP+BP_CS]        ; Get the user's CS
        ADDROV                          ; And put it on his stack
        STOSW

        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        MOV     AX,SS:[BP+BP_FL]        ; Get the user's flags
        OR      AX,3000H                ; Set the IOPL to 3 so we get fewer
                                        ;   faults
        ADDROV                          ; And put them on his stack
        STOSW

        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        AND     AX,3CFFH                ; Clean up the flags for our IRET
        MOV     WORD PTR SS:[BP+BP_FL],AX ; Put them on our stack

        MOV     SI,SS:[BP+BP_EX]        ; Get the interrupt number
        SHL     SI,2                    ; Multiply by four 'cause interrupt
                                        ;   vectors are four bytes long
        MOV     AX,HUGE_PTR             ; Load DS with a selector that accesses
        MOV     DS,AX                   ;   all of memory as data
        LODSW                           ; Get the IP of the interrupt vector
                                        ;   from the interrupt vector table
        MOV     WORD PTR SS:[BP+BP_IP],AX ; Put it in the IP saved on our stack
        LODSW                           ; Get the CS of the interrupt vector
                                        ;   from the interrupt vector table
        MOV     WORD PTR SS:[BP+BP_CS],AX ; Put it in the CS saved on our stack

        JMP     POPREGS                 ; Now when we do an IRET we will    @P2C
                                        ;   actually be giving control to the
                                        ;   real INT 15H vector.
INT15   ENDP

PAGE
;   Macros used to define data areas

; DDL - Define a label and make it public

DDL     MACRO   NAME,SIZE
        PUBLIC  &NAME
&NAME   LABEL   &SIZE
        ENDM


; DDW - Define a word and make it public

DDW     MACRO   NAME,VALUE
        IFNB    <&NAME>       ;; If a name was given then make it public
        PUBLIC  &NAME
        ENDIF
        IFNB    <&VALUE>      ;; If a value was given then initialize the
&NAME   DW      &VALUE        ;;    variable to that value
        ELSE                  ;; Else initialize it to 0
&NAME   DW      0
        ENDIF
        ENDM


; Now lets define some data.  Remember, these are all PUBLIC even though they
; are not listed at the top of the program as being such.  It's easy to lose
; these guys.

        DDW     REAL_SP,0     ; Our initial SP when we come up in real mode

        DDW     REAL_SS,0     ; Our initial SS when we come up in real mode

        DDW     REAL_CS,0     ; Our initial CS when we come up in real mode

        DDW     PGTBLOFF,0    ; The offset of the normal page tables

        DDW     SGTBLOFF,0    ; The offset of the page directory

        DDW     NORMPAGE,0    ; The entry for the first page directory entry
        DDW     ,0            ;   which points to the first normal page table.
                              ;   A 32 bit value
        DDW     XMAPAGE,7     ; Page directory entry that points to the first
        DDW     ,0011H        ;   XMA page table at 11000:0.  Access and present
                              ;   bits set.  It, too, is a 32 bit value.
        DDW     BUFF_SIZE,0   ; Size of the MOVEBLOCK buffer.  Initialized to 0.

        DDW     MAXMEM,1000H  ; Total amount of K in the box. Initialized to 4M.

        DDW     CRT_SELECTOR,C_BWCRT_PTR  ; Selector for the display buffer

; And now, the world famous Translate Table!!   YEAAAA!!
;
; The first 160 entries (0 to 640K) are initialized to blocks 0 to '9F'X.    D1A
; This is to emulate the XMA 2 device driver which uses these blocks to back D1A
; the memory on the mother board from 0 to 640K which it disabled.  It sets  D1A
; up the translate table for bank 0 such that it maps the XMA memory from 0  D1A
; to 640K to conventional memory at 0 to 640K.  So we emulate that here by   D1A
; initializing the firs 160 entries in the translate table.                  D1A

TTTABLE:
        BLOCK = 0             ; Start with block number 0                   @D1A
        REPT    20            ; Do 20 times (20 x 8 = 160)                  @D1A
        DW      BLOCK,BLOCK+1,BLOCK+2,BLOCK+3,BLOCK+4,BLOCK+5,BLOCK+6,BLOCK+7
                              ; Define eight translate table entries        @D1A
                              ;   initialized to the block number            D1A
        BLOCK = BLOCK + 8     ; Increment the block number to the next set  @D1A
        ENDM                  ;   of eight translate table entries          @D1A

        DW      96 + 256*15 DUP(0FFFH) ; The rest of the translate table    @D1C

TTTABLE_END:                  ; Label to mark the end of the translate table


; Define our stack for when we're in protect mode

        DDW     MON_STACK_BASE,<500 DUP(0)>
        DDL     SP_INIT,WORD  ; Top of the stack.  The initial SP points here.

PROG    ENDS

        END
