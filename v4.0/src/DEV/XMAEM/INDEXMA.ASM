PAGE    60,132
TITLE   INDEXMA - 386 XMA Emulator - XMA Emulation

COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEXMA                                                   *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corp.              *
*                                                                             *
* DESCRIPTIVE NAME: Do the XMA emulation for the 80386 XMA Emulator           *
*                                                                             *
* STATUS (LEVEL)  : Version (0) Level (1.0)                                   *
*                                                                             *
* FUNCTION        : This module does the actual manipulation of the page      *
*                   tables to emulate the XMA card.  Using the 80386          *
*                   paging mechanism we let the 4K page frames represent      *
*                   the 4K XMA blocks on the XMA card.  We let the page       *
*                   tables represent the translate table.                     *
*                                                                             *
*                   The XMA "blocks" start at address 12000:0.  The        D1C*
*                   Emulator emulates the XMA 2 card with the INDXMAA      D1C*
*                   device driver.  On initial power up, the XMA 2 card is D1C*
*                   disabled.  The INDXMAA device driver then disables the D1C*
*                   memory from 0K to 640K and backs it with memory from   D1C*
*                   0K to 640K on the XMA 2 card.  The Emulator looks like D1C*
*                   it does the same thing.  The XMA blocks for 0K to 640K D1C*
*                   are taken from the system board memory from 0K to      D1C*
*                   640K.  This memory on the motherboard is treated as    D1C*
*                   XMA memory.  This emulates the INDXMAA device driver's D1C*
*                   mapping of 0K to 640K on the XMA card to real memory.  D1C*
*                   The XMA "blocks" for 640K and up are located in high   D1C*
*                   memory starting at 12000:0.  These "blocks" run up to  D1C*
*                   the start of the MOVEBLOCK buffer.  The MOVEBLOCK      D1C*
*                   buffer is a chunk of storage (in 16K multiples) at the D1C*
*                   end of available memory that is reserved for the       D1C*
*                   MOVEBLOCK functions.                                   D1C*
*                                                                             *
*                   The page tables are used to emulate the translate         *
*                   table.  By setting the address of the XMA "block" into    *
*                   the page table entry for a specific page frame we can     *
*                   make that address access that particular XMA page         *
*                   frame.  To the user this looks just like the translate    *
*                   table is active.                                          *
*                                                                             *
*                   The tricky part comes in disabling pages (blocks).  On D1C*
*                   the XMA 2 card, when a translate table entry is        D1C*
*                   disabled the addresses for that address range go to    D1C*
*                   real memory.  If the address is between 0K and 640K    D1C*
*                   then any access of that storage gets nothing because   D1C*
*                   there is no memory backed from 0K to 640K on the real  D1C*
*                   system.  All other addresses go to real memory.  So    D1C*
*                   when the user disables translation of a translate      D1C*
*                   table entry we need to check what range that entry     D1C*
*                   covers.  If the entry points to somewhere between 0K   D1C*
*                   and 640K then we will set the page table entry that    D1C*
*                   corresponds to the translate table entry to point to   D1C*
*                   non-existent memory.  For all other addresses we will  D1C*
*                   just point the page table entry back to the real       D1C*
*                   memory at that address.                                D1C*
*                                                                             *
*                   This module receives control on all "IN"s and "OUT"s      *
*                   done by the user.  If the "IN" or "OUT" is not to an      *
*                   XMA port then it passes the I/O on to INDEDMA.  If it     *
*                   is for an XMA port then the request is handled here.      *
*                                                                             *
*                   This module keeps its own copies of the XMA registers     *
*                   and the translate table.  When any I/O comes for the      *
*                   XMA card it updates its copies of the registers and       *
*                   the translate table.  Then it does any needed             *
*                   modifications on the page tables to emulate the XMA       *
*                   request.                                                  *
*                                                                             *
* MODULE TYPE     : ASM                                                       *
*                                                                             *
* REGISTER USAGE  : 80386 Standard                                            *
*                                                                             *
* RESTRICTIONS    : None                                                      *
*                                                                             *
* DEPENDENCIES    : None                                                      *
*                                                                             *
* ENTRY POINTS    : INW         - Emulate "IN" for a word with port number    *
*                                 in DX                                       *
*                   INWIMMED    - Emulate "IN" for a word with an immediate   *
*                                 port number                                 *
*                   INIMMED     - Emulate "IN" for a byte with an immediate   *
*                                 port number                                 *
*                   XMAIN       - Emulate "OUT" for a byte with port number   *
*                                 in DX                                       *
*                   OUTW        - Emulate "OUT" for a word with port number   *
*                                 in DX                                       *
*                   OUTWIMMED   - Emulate "OUT" for a word with an immediate  *
*                                 port number                                 *
*                   XMAOUTIMMED - Emulate "OUT" for a byte with an immediate  *
*                                 port number                                 *
*                   XMAOUT      - Emulate "OUT" for a byte with port number   *
*                                 in DX                                       *
*                                                                             *
* LINKAGE         : Jumped to by INDEEXC                                      *
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
* REFERENCES      : POPIO:NEAR     - Entry in INDEEMU to return to V86 task   *
*                   HEXW:NEAR      - Entry in INDEEXC to display word in AX   *
*                   DMAIN:NEAR     - Entry in INDEDMA to "IN" from DMA port   *
*                   DMAOUT:NEAR    - Entry in INDEDMA to "OUT" to DMA port    *
*                   PGTBLOFF:WORD  - Offset of the normal page tables         *
*                   SGTBLOFF:WORD  - Offset of the page directory             *
*                   NORMPAGE:WORD  - Entry for the 1st page directory entry   *
*                                    so that it points to the normal          *
*                                    page tables                              *
*                   XMAPAGE:WORD   - Entry for the 1st page directory entry   *
*                                    that points to the XMA page tables       *
*                   TTTABLE:WORD   - The translate table                      *
*                   BUFF_SIZE:WORD - Size of the MOVEBLOCK buffer             *
*                   MAXMEM:WORD    - Number of kilobytes on this machine      *
*                                                                             *
* SUB-ROUTINES    : TTARCHANGED - Put the block number at the translate table *
*                                 entry in 31A0H into "ports" 31A2H and 31A4H *
*                   UPDATETT    - Update the translate table and page tables  *
*                                 to reflect the new block number written to  *
*                                 either 31A2H or 31A4H                       *
*                                                                             *
* MACROS          : DATAOV - Add prefix for the next instruction so that it   *
*                            accesses data as 32 bits wide                    *
*                   ADDROV - Add prefix for the next instruction so that it   *
*                            uses addresses that are 32 bits wide             *
*                   CMOV   - Move to and from control registers               *
*                                                                             *
* CONTROL BLOCKS  : INDEDAT.INC - system data structures                      *
*                                                                             *
* CHANGE ACTIVITY :                                                           *
*                                                                             *
* $MOD(INDEXMA) COMP(LOAD) PROD(3270PC) :                                     *
*                                                                             *
* $D0=D0004700 410 870530 D : NEW FOR RELEASE 1.1                             *
* $P1=P0000293 410 870731 D : LIMIT LINES TO 80 CHARACTERS                    *
* $P2=P0000312 410 870804 D : CHANGE COMPONENT FROM MISC TO LOAD              *
* $D1=D0007100 410 870810 D : CHANGE TO EMULATE XMA 2                         *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

        .286P                 ; Enable recognition of 286 privileged instructs.

        .XLIST                ; Turn off the listing
        INCLUDE INDEDAT.INC   ; Include system data structures

        IF1                   ; Only include macros on the first pass
        INCLUDE INDEOVP.MAC
        INCLUDE INDEINS.MAC
        ENDIF
        .LIST                 ; Turn on the listing

CRT_SELECTOR    EQU     00030H          ; Selector for mono display buffer
SEX_ATTR        EQU     04B00H          ; Attribute for turquoise on red
STACK_ATTR      EQU     00700H          ; Attribute for white o black
BLANK           EQU     00020H          ; ASCII for a blank
XMA_PAGES_SEL   EQU     RSDA_PTR        ; Selector for the XMA pages
HIMEM           EQU     120H            ; Adjustment for XMA pages >= 640K. @D1C
                                        ;   They start at address 12000:0.
                                        ;   It's the block number corresponding
                                        ;   to address 12000:0.
                                        ;                                   @D1D

PROG    SEGMENT PARA PUBLIC 'PROG'

        ASSUME  CS:PROG
        ASSUME  DS:PROG
        ASSUME  ES:NOTHING
        ASSUME  SS:NOTHING

INDEXMA LABEL   NEAR

; The following entry points are in other modules

        EXTRN   POPIO:NEAR              ; Return to V86 task - in INDEEMU
        EXTRN   HEXW:NEAR               ; Display word in AX - in INDEEXC
        EXTRN   DMAIN:NEAR              ; "IN" from DMA port - in INDEDMA
        EXTRN   DMAOUT:NEAR             ; "OUT" to DMA port  - in INDEDMA

; The following data are in INDEI15.ASM

        EXTRN   PGTBLOFF:WORD           ; Offset of the normal page tables
        EXTRN   SGTBLOFF:WORD           ; Offset of the page directory
        EXTRN   NORMPAGE:WORD           ; Entry for the 1st page directory entry
                                        ;   so that it points to the normal
                                        ;   page tables
        EXTRN   XMAPAGE:WORD            ; Entry for the 1st page directory entry
                                        ;  that points to the XMA page tables
        EXTRN   TTTABLE:WORD            ; The translate table
        EXTRN   BUFF_SIZE:WORD          ; Size of the MOVEBLOCK buffer
        EXTRN   MAXMEM:WORD             ; Number of kilobytes on this machine

; Let the following entries be known to other modules

        PUBLIC  INDEXMA
        PUBLIC  INW
        PUBLIC  INWIMMED
        PUBLIC  INIMMED
        PUBLIC  XMAIN
        PUBLIC  OUTW
        PUBLIC  OUTWIMMED
        PUBLIC  XMAOUTIMMED
        PUBLIC  XMAOUT
        PUBLIC  NOTXMAOUT

; Let the following data be known to other modules

        PUBLIC  WORD_FLAG
        PUBLIC  XMATTAR
        PUBLIC  XMATTIO
        PUBLIC  XMATTII
        PUBLIC  XMATID
        PUBLIC  XMACTL

; The following XMA labels represent the XMA ports starting at 31A0H.
; THEY MUST BE KEPT IN THE FOLLOWING ORDER.

XMATTAR DW      0             ; Port 31A0H - Translate table index
XMATTIO DW      0             ; Port 31A2H - XMA block number
XMATTII DW      0             ; Port 31A4H - Block number with auto-increment
XMATID  DB      0             ; Port 31A6H - Bank ID
XMACTL  DB      02H           ; Port 31A7H - Control flags.  Virtual        @D1C
                              ;              enable bit is initially on.

; How about some flags?

WORD_FLAG DB    0             ; If set to 1 then I/O is for a word.
                              ;   Else, it's for a byte

PAGE

; Control comes here for an "IN" for a word with the port value in DX

INW:
        MOV     AX,SYS_PATCH_DS         ; Load DS with the selector for our
        MOV     DS,AX                   ;   data segment so we can set WORD_FLAG
        MOV     WORD_FLAG,1             ; Flag this as a word operation
        JMP     XMAIN                   ; Go do the "IN"

; Control comes here for an "IN" for a word with an immediate port value

INWIMMED:
        MOV     AX,SYS_PATCH_DS         ; Load DS with the selector for our
        MOV     DS,AX                   ;   data segment so we can set WORD_FLAG
        MOV     WORD_FLAG,1             ; Flag this as a word operation

; Control comes here for an "IN" for a byte with an immediate port value

INIMMED:

        ADD     WORD PTR SS:[BP+BP_IP],1 ; Step IP past the "IN" instruction

; Get the port address from the instruction.  The port address is in the byte
; immediately following the "IN" op-code.  We will load the port address into
; DX.  This way when we join the code below it will look like the port address
; was in DX all along.

        MOV     AX,HUGE_PTR             ; Load DS with a selector that accesses
        MOV     DS,AX                   ;   all of memory as data

        MOV     SS:WORD PTR [BP+BP_IP2],0 ; Clear the high words of the V86
        MOV     SS:WORD PTR [BP+BP_CS2],0 ;   task's CS and IP

        DATAOV                          ; Load ESI (32 bit SI) with the V86
        MOV     SI,SS:[BP+BP_IP]        ;   task's IP
        DATAOV
        MOV     AX,SS:[BP+BP_CS]        ; Load EAX with the V86 task's CS
        DATAOV                          ;   and then shift left four bits to
        SHL     AX,4                    ;   convert it to an offset
        DATAOV                          ; Add the CS offset to "IP" in SI
        ADD     SI,AX                   ; SI now contains CS:IP as a 32 bit
                                        ;   offset from 0
        ADDROV                          ; Get the byte after the "IN" instruc-
        LODSB                           ;   tion.  This is the port address.

        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        SUB     DX,DX                   ; Clear DX to prepare for one byte move
        MOV     DL,AL                   ; DX now has the port address

; Control comes here for an "IN" for a byte with the port value in DX

XMAIN   PROC    NEAR

        MOV     AX,SYS_PATCH_DS         ; Load DS with the selector for our
        MOV     DS,AX                   ;    data segment

        CMP     DX,31A0H                ; Is the port address below 31A0H?
        JB      NOTXMAIN                ; Yup.  Then it's not XMA.

        CMP     DX,31A7H                ; Is the port address above 31A7H?
        JA      NOTXMAIN                ; Yup.  Then it's not XMA.

; It's an XMA port so lets do the "IN" for the guy.

        AND     XMATTAR,0FFFH           ; First lets clear the high nibbles of
        AND     XMATID,0FH              ;   our ports.  This insures that we
        AND     XMACTL,0FH              ;   have valid values in our ports.

        LEA     SI,XMATTAR              ; Point SI to the port requested by
        ADD     SI,DX                   ;   first pointing it to port 31A0H
        SUB     SI,31A0H                ;   and then adding on the difference
                                        ;   between 31A0H and the requested port
        CMP     WORD_FLAG,0             ; Is this a word operation?
        JNE     GETWORD                 ; Yes.  Then go get a word.

        LODSB                           ; Else get a byte from the "port"
        MOV     BYTE PTR SS:[BP+BP_AX],AL ; Put it in the V86 task's AL register
        JMP     INEXIT                  ; Th-th-that's all folks!

; For non-XMA ports we just pass the "IN" on to INDEDMA

NOTXMAIN:
        JMP     DMAIN

; The "IN" is for a word

GETWORD:
        LODSW                           ; Get a word from the "port"
        MOV     WORD PTR SS:[BP+BP_AX],AX ; Put it in the V86 task's AX register

        MOV     WORD_FLAG,0             ; Reset the word flag

        CMP     DX,31A4H                ; Is this an "IN" from the auto-
                                        ;   increment port?
        JNE     INEXIT                  ; Nope.  Then just leave.

        INC     XMATTAR                 ; The "IN" is from the auto-increment
                                        ;   port so increment the translate
        CALL    TTARCHANGED             ;   table index and call TTARCHANGED
                                        ;   to update the status of the "card"
INEXIT:
        ADD     WORD PTR SS:[BP+BP_IP],1 ; Step IP past the instruction (past
                                        ;   the port value for immediate insts.)
        JMP     POPIO                   ; Go return to the V86 task

PAGE

; Control comes here for an "OUT" for a word with the port value in DX

OUTW:
        MOV     AX,SYS_PATCH_DS         ; Load DS with the selector for our
        MOV     DS,AX                   ;   data segment so we can set WORD_FLAG
        MOV     WORD_FLAG,1             ; Flag this as a word operation
        JMP     XMAOUT                  ; Go do the "OUT"

; Control comes here for an "OUT" for a word with an immediate port value

OUTWIMMED:
        MOV     AX,SYS_PATCH_DS         ; Load DS with the selector for our
        MOV     DS,AX                   ;   data segment so we can set WORD_FLAG
        MOV     WORD_FLAG,1             ; Flag this as a word operation

; Control comes here for an "OUT" for a byte with an immediate port value

XMAOUTIMMED:

        ADD     WORD PTR SS:[BP+BP_IP],1 ; Step IP past the "OUT" instruction

; Get the port address from the instruction.  The port address is in the byte
; immediately following the "OUT" op-code.  We will load the port address into
; DX.  This way when we join the code below it will look like the port address
; was in DX all along.

        MOV     AX,HUGE_PTR             ; Load DS with a selector that accesses
        MOV     DS,AX                   ;   all of memory as data

        MOV     SS:WORD PTR [BP+BP_IP2],0 ; Clear the high words of the V86
        MOV     SS:WORD PTR [BP+BP_CS2],0 ;   task's CS and IP

        DATAOV                          ; Load ESI (32 bit SI) with the V86
        MOV     SI,SS:[BP+BP_IP]        ;   task's IP
        DATAOV
        MOV     AX,SS:[BP+BP_CS]        ; Load EAX with the V86 task's CS
        DATAOV                          ;   and then shift left four bits to
        SHL     AX,4                    ;   convert it to an offset
        DATAOV                          ; Add the CS offset to "IP" in SI
        ADD     SI,AX                   ; SI now contains CS:IP as a 32 bit
                                        ;   offset from 0
        ADDROV                          ; Get the byte after the "OUT" instruc-
        LODSB                           ;   tion.  This is the port address.

        ADDROV                          ; Intel bug # A0-119
        NOP                             ; Intel bug # A0-119

        SUB     DX,DX                   ; Clear DX to prepare for one byte move
        MOV     DL,AL                   ; DX now has the port address

; Control comes here for an "OUT" for a byte with the port value in DX

XMAOUT:
        MOV     AX,SYS_PATCH_DS         ; Load DS and ES with the selector for
        MOV     DS,AX                   ;   our data area
        MOV     ES,AX

        CMP     DX,31A0H                ; Is the port address below 31A0H?
        JB      NOTXMAOUT               ; Yes.  Then it's not XMA.

        CMP     DX,31A7H                ; Is the port address above 31A7H?
        JA      NOTXMAOUT               ; Yes.  Then it's not XMA.

        LEA     DI,XMATTAR              ; Point SI to the port requested by
        ADD     DI,DX                   ;   first pointing it to port 31A0H
        SUB     DI,31A0H                ;   and then adding on the difference
                                        ;   between 31A0H and the requested port
        CMP     WORD_FLAG,0             ; Is this a word operation?
        JNE     PUTWORD                 ; Yes.  Then go put a word.

        MOV     AL,BYTE PTR SS:[BP+BP_AX] ; Put the value in the V86 task's AL
        STOSB                           ;   register into the "port"

        CMP     DX,31A6H                ; Is this "OUT" to the bank ID port?
        JE      CHKCNTRL                ; If so, go set the new bank

        CMP     DX,31A7H                ; Is the "OUT" to the control port?
        JE      CHKCNTRL                ; Affirmative.  Go handle control bits.

        CMP     DX,31A1H                ; Is this "OUT" to the TT index?
                                        ;   (high byte)
        JBE     TTAROUT                 ; Yup.  Go update dependent fields.

        JMP     OUTEXIT                 ; Any other ports just exit.

; The "OUT" is for a word

PUTWORD:
        MOV     AX,WORD PTR SS:[BP+BP_AX] ; Put the value in the V86 task's AX
        STOSW                           ;   register into the "port"

        MOV     WORD_FLAG,0             ; Reset the word flag

        CMP     DX,31A0H                ; Is the "OUT" to the TT index port?
        JE      TTAROUT                 ; Si.  Go update the dependent fields.

        CMP     DX,31A2H                ; Is the "OUT" to set a block number?
        JNE     CHKA4                   ; No.  Go do some more checks.

        MOV     XMATTII,AX              ; The "OUT" is to 31A2H.  Set the auto-
                                        ;   increment port to the same value.
                                        ;   The two ports should always be in
                                        ;   sync.
        CALL    UPDATETT                ; Update the "translate table" with the
                                        ;   new block number
        JMP     OUTEXIT                 ; That's it.  Let's leave.

CHKA4:
        CMP     DX,31A4H                ; Is "OUT" to the auto-increment port
        JNE     CHKCNTRL                ; No.  Then it must be to the bank ID/
                                        ;   control byte port (31A6H).
        MOV     XMATTIO,AX              ; The "OUT is to the auto-increment port
        CALL    UPDATETT                ; Update the "translate table"
        INC     XMATTAR                 ; Increment the translate table index
        CALL    TTARCHANGED             ; Update fields that depend on the
                                        ;   translate table index
        JMP     OUTEXIT                 ; And return to the V86 task

; The translate table index was changed

TTAROUT:
        CALL    TTARCHANGED             ; Update fields that depend on the
                                        ;   setting of the translate table index
        JMP     OUTEXITDMA              ; Skip flushing the page-translation
                                        ;   cache since the page tables have
                                        ;   not changed.

; It's not an XMA "OUT" so pass it on to INDEDMA

NOTXMAOUT:
        JMP     DMAOUT

; The "OUT" is to the bank ID port (31A6H), the control port (31A7H) or both

CHKCNTRL:

        TEST    XMACTL,02H              ; Is the virtual enable bit on?
        JNZ     SETXMA                  ; Aye.  Go make the specified XMA bank
                                        ;   active.
        DATAOV                          ; Nay.  We simulate disabling the XMA
        MOV     AX,NORMPAGE             ;   card by making the normal page
                                        ;   tables active.
        MOV     DI,SGTBLOFF             ; This is done by setting the first
        DATAOV                          ;   entry in the page directory to
        STOSW                           ;   point to the page table for normal
                                        ;   memory.
        JMP     OUTEXIT                 ; Return to the V86 task

SETXMA:
        AND     XMATID,0FH              ; Wipe out the high nibble of the bank
        MOV     AL,XMATID               ;   ID.  XMA only has 16 banks.
        DATAOV                          ; Now multiply by 4K (shift left 12 ;P1C
        SHL     AX,28                   ;   bits) to get the offset from the
        DATAOV                          ;   base of the XMA page tables of the
        SHR     AX,28-12                ;   page table for the requested bank.
                                        ;   Page tables are 4K in length.  In
                                        ;   the process of shifting we shift the
                                        ;   high order 16 bits off the left end
                                        ;   of EAX so that they are 0 when we
                                        ;   shift back.
        DATAOV                          ; Add on the offset of the base of the
        ADD     AX,XMAPAGE              ;   page tables.  EAX now has the offset
                                        ;   of the page table for the XMA bank.
        MOV     DI,SGTBLOFF             ; Point to the first entry in the page
                                        ;   directory.
        DATAOV                          ; Set the first entry in the page
        STOSW                           ;   directory to point to the XMA page
                                        ;   table

; Since the page tables have changed we need to purge the page-translation
; cache.  "For greatest efficiency in address translation, the processor
; stores the most recently used page-table data in an on-chip cache...  The
; existence of the page-translation cache is invisible to applications
; programmers but not to systems programmers; operating-system programmers
; must flush the cache whenever the page tables are changed."
;   -- 80386 Programmer's Reference Manual (C) Intel 1986

OUTEXIT:
        CMOV    EAX,CR3                 ; Get the page directory base register
        NOP                             ; 386 errata B0-110
        CMOV    CR3,EAX                 ; Write it back to reset the cache
        NOP                             ; 386 errata B0-110

OUTEXITDMA:
        ADD     WORD PTR SS:[BP+BP_IP],1 ; Step IP past the "OUT" instruction
        JMP     POPIO                   ; Return to the V86 task

PAGE

; TTARCHANGED updates all the fields that depend on the translate table index
; in port 31A0H.  This is mainly getting the translate table entries for the
; specified index and putting them in the block number ports 31A2H and 31A4H.

TTARCHANGED     PROC

        MOV     AX,XMATTAR              ; Get the new translate table index
        AND     AX,0FFFH                ; The high nibble is not used
        SHL     AX,1                    ; Change it to a word index.  The
                                        ;   translate table entries are words.
        LEA     SI,TTTABLE              ; Point SI to the translate table base
        ADD     SI,AX                   ; Add on the offset into the table
        LODSW                           ; Get the XMA block number for the
                                        ;  specified translate table entry
        MOV     XMATTIO,AX              ; Put it into "port" 31A2H
        MOV     XMATTII,AX              ; Put it into "port" 31A4H

        RET

TTARCHANGED     ENDP

PAGE

; UPDATETT will update the "translate table" and the corresponding page
; tables when an XMA block number is written to either port 31A2H or the
; auto-increment port 31A4H.  A write to either of these ports means to set
; the XMA block specified at the translate table entry indicated in port
; 31A0H.
;
; The Emulator is set up to look like an XMA 2 card with the INDXMAA device  D1C
; driver.  When the system comes up the XMA card is initially disabled.      D1C
; INDXMAA then backs memory from 0K to 640K on the system board with memory  D1C
; from 0K to 640K on the XMA card.  To emulate this, the Emulator treats     D1C
; real memory from 0K to 640K as XMA blocks from 0K to 640K on the XMA card. D1C
; This both saves memory and requires no code to back the real memory from   D1C
; 0K to 640K with XMA memory on initialization.  The Emulator therefore only D1C
; needs to allocate XMA memory for the XMA blocks over 640K.  The XMA memory D1C
; for over 640K starts at 12000:0.  The XMA blocks 00H to 9FH will be mapped D1C
; to the motherboard memory at 0K to 640K.  The XMA blocks A0H and up will   D1C
; be mapped to the memory at 12000:0 and up.                                 D1C
;
; Bits 15 (IBM bit 0) and 11 (IBM bit 4) of the XMA block number have
; special meanings.  When bit 15 is on it means that the block number is a
; 15 bit number.  This is in anticipation of larger block numbers in the
; future.  Current block numbers are 11 bits.  When bit 11 is on it means
; that the XMA translation for this translation table entry should be
; disabled.  The memory for this 4K block should be mapped back to real
; memory.
;
; We also check to make sure that the XMA block is not above the XMA memory
; limit.  XMA memory ends where the MOVEBLOCK buffer starts.  If the XMA
; block is above the end of XMA memory then the page table entry for that
; address is set to point to non-existent memory.
;
; When address translation is disabled for addresses above 640K then the     D1C
; page table entry for that address is set to point back to real memory.     D1C
; For disabled pages in the range 0K to 640K the page table entry is set to  D1C
; point to non-existent memory.                                              D1C

UPDATETT        PROC

        MOV     AX,XMATTAR              ; Get the index of the TT entry that
                                        ;   is to be changed
        AND     AX,0FFFH                ; Clear the high four bits.  They are
                                        ;   not used.
        SHL     AX,1                    ; Change to a word offset since the TT
                                        ;   entries are words.
        LEA     DI,TTTABLE              ; Point DI to the translate table base
        ADD     DI,AX                   ; Add on the offset of the entry that
                                        ;   is to be changed
        MOV     AX,XMATTIO              ; Get the block number to be written
        STOSW                           ; Store the block number in the TT

; Convert bank number to a page address.
; The following code works only with paging enabled at 256k boundary.
; It is intended to support up to 128M at 4k granularity.
; It interprets the high order bits as a superset of XMA.
; Following is a truth table for bits 11 (XMA inhibit bit) and 15 ("enable-hi").
;   15   11
;    0    0   =   enabled 11 bit address
;    0    1   =   disabled address
;    1    x   =   enabled 15 bit address

        TEST    AH,80H                  ; Is this a 15 bit block number?
        JZ      SMALL                   ; Far from it.  Go do stuff for 11 bit
                                        ;   block numbers.

; We have a 15 bit address

        CMP     AX,0FFFFH               ; If it's FFFFH then we treat it the
                                        ;   the same as 0FFFH which means
        JE      DISABLEPAGE             ;   disable the page

        AND     AX,7FFFH                ; Turn off the 15 bit address bit
        JMP     BOTH                    ;   leaving a valid block number for
                                        ;   our calculations later

SMALL:
        TEST    AH,08H                  ; Is the disable bit on?
        JNZ     DISABLEPAGE             ; Yes.  Go disable the page.

        AND     AX,07FFH                ; No.  Turn off the high nibble and the
                                        ;   disable bit leaving a valid block
                                        ;   number for our upcoming calculations
BOTH:
        CMP     AX,640/4                ; Is this block number for 640K or over?
        JB      NOADJUST                ; Yup.  There's no adjustment       @D1C
                                        ;   needed for blocks between 0K and
                                        ;   640K since we use real memory for
                                        ;   these blocks.
                                        ; XMA 1 emulation code deleted     3@D1D
        ADD     AX,HIMEM-(640/4)        ; Add on the adjustment needed for  @D1C
                                        ;   blocks above 640K to point to
                                        ;   the XMA blocks starting at 12000:0.
                                        ;   But don't forget to subtract the
                                        ;   block number for 640K.  This makes
                                        ;   the block number 0 based before we
                                        ;   add on the block number for 12000:0.
NOADJUST:
        DATAOV                          ; Shift the high order 16 bits of EAX
        SHL     AX,16                   ;   off the left end of the register.
        DATAOV                          ; Now shift the block number back four
        SHR     AX,16-12                ;   bits.  This results in a net shift
                                        ;   left of 12 bits which converts the
                                        ;   block number to an offset, and it
                                        ;   clears the high four bits.
        OR      AL,7                    ; Set the access and present bits.  This
                                        ;   converts our offset to a valid page
                                        ;   table entry.
        DATAOV                          ; Save the page table entry in EBX for
        MOV     BX,AX                   ;   now

; Now we must make sure the offset of our XMA page frame is within the address
; space of the XMA pages, that is, it is below the start of the MOVEBLOCK
; buffer.

        DATAOV                          ; Clear all 32 bits of EAX
        SUB     AX,AX
        MOV     AX,MAXMEM               ; Load up the number of K on the box
        SUB     AX,BUFF_SIZE            ; Subtract the number of K reserved
                                        ;   for the MOVEBLOCK buffer
        DATAOV                          ; Multiply by 1K (shift left 10) to
        SHL     AX,10                   ;   convert it to an offset
        DATAOV                          ; Is the XMA page address below the
        CMP     BX,AX                   ;   MOVEBLOCK buffer address?
        JB      ENABLED                 ; Yup.  Whew!  Let's go set up the page
                                        ;   table entry for this XMA block.
        JMP     EMPTY                   ; Nope.  Rats!  Well, we'll just have
                                        ;   to point this TT entry to unbacked
                                        ;   memory.

; We come here when we want to disable translation for this translate table
; entry.  For TT entries for 640K and over we just point the translate table
; entry back to real memory.  For TT entries between 0K and 640K we point
; the translate table to unbacked memory.  This memory on the motherboard
; was disabled under real XMA so we emulate it by pointing to unbacked
; memory.

DISABLEPAGE:
                                        ; XMA 1 emulation code deleted     2@D1D
        CMP     BYTE PTR XMATTAR,640/4  ; Is the address at 640K or above?
        JNB     SPECIAL                 ; Aye.  Go point back to real memory.

; The address is between 256K and 640K.  Let's set the page table entry to
; point to non-exiatent memory.

EMPTY:
        DATAOV                          ; Clear EAX
        SUB     AX,AX
        MOV     AX,MAXMEM               ; Get the total number of K on the box
        DATAOV                          ; Multiply by 1024 to convert to an
        SHL     AX,10                   ;   offset.  AX now points to the 4K
                                        ;   page frame after the end of memory.
        OR      AL,7                    ; Turn on the accessed and present bits
                                        ;    to avoid page faults
        DATAOV                          ; Save the page table entry in EBX
        MOV     BX,AX
        JMP     ENABLED                 ; Go set up the page table

; If the address is above 640K then the translate table (page table) entry   D1C
; is set to point back to real memory.
SPECIAL:
        MOV     AX,XMATTAR              ; Get the index of the TT entry that is
                                        ;   to be disabled
        DATAOV                          ; Dump the high 24 bits off the left end
        SHL     AX,24                   ;   of the register
        DATAOV                          ; Now shift it back 12 bits.  This
        SHR     AX,24-12                ;   results in a net shift left of 12
                                        ;   bits which multiplies the TT index
                                        ;   by 4K while at the same time clear-
                                        ;   ing the high order bits.  EAX is now
                                        ;   the offset of the memory pointed to
                                        ;   by the TT entry.
        OR      AL,7                    ; Turn on the accessed and present bits
                                        ;   to make this a page table entry
        DATAOV                          ; Save the page table entry in EBX
        MOV     BX,AX

; Now let's put the new page table entry in EBX, which represents the XMA block,
; into the page table.
ENABLED:
        MOV     AX,XMATTAR              ; Get the index of the TT entry

; Now we want ot convert the index of the TT entry to an offset into our XMA
; page tables.  The bank number is now in AH and the 4K block number of the
; bank is in AL.  To point to the right page table we need to multiply the bank
; number by 4K (shift left 12 bits) since page tables are 4K in length.  The
; bank number is already shifted left 8 bits by virtue of it being in AH.  It
; needs to be shifted left four more bits.  In order to access the right entry
; in the page table, the block number in AL must be multiplied by 4 (shifted
; left two bits) because the page table entries are 4 bytes in length.  So,
; first we shift AH left two bits and then shift AX left two bits.  In the end
; this shifts AH, the bank ID, left four bits and shifts AL, the block number,
; two bits, which is what we wanted.  A long explanation for two instructions,
; but they're pretty efficient, don't you think?

        SHL     AH,2                    ; Shift the bank ID left two bits
        SHL     AX,2                    ; Shift the bank ID and the block number
                                        ;   left two bits
        MOV     DI,AX                   ; Load DI with the offset of the page
                                        ;   table entry that is to be changed
        PUSH    ES                      ; Save ES
        MOV     AX,XMA_PAGES_SEL        ; Load ES with the selector for our
        MOV     ES,AX                   ;   XMA page tables.  Now ES:DI points
                                        ;   to the page table entry to be
                                        ;   changed
        DATAOV                          ; Get the new value for the page table
        MOV     AX,BX                   ;   entry which was saved in EBX.
        DATAOV                          ; Stuff it into the page table - all
        STOSW                           ;   32 bits of it.

        POP     ES                      ; Restore ES

        RET                             ; And return

UPDATETT        ENDP

XMAIN   ENDP

PROG    ENDS

        END
