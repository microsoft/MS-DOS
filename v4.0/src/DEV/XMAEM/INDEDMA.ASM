PAGE    60,132
TITLE   INDEDMA - 386 XMA Emulator - DMA Emulation

COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEDMA                                                   *
*                                                                             *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corporation        *
*                                                                             *
* DESCRIPTIVE NAME: DMA handler for the 80386 XMA emulator                    *
*                                                                             *
* STATUS (LEVEL)  : Version (0) Level (1.0)                                   *
*                                                                             *
* FUNCTION        : This module intercepts any I/O going to the DMA address   *
*                   ports.  We can't let the DMA requests go to the virtual   *
*                   addresses.  On the real XMA card the addresses on the     *
*                   bus lines are translated by the card so that it accesses  *
*                   the correct memory.  But with our emulation the addresses *
*                   are translated before they hit the bus lines.  The DMA    *
*                   addresses go straight to the bus lines without being      *
*                   translated.  This would result in DMA reading and writing *
*                   data to the wrong memory location.  Not good.  Therefore  *
*                   we intercept the I/O that is going to the DMA address     *
*                   ports.  We run these addresses through our paging mech-   *
*                   anism and then write the real addresses to the DMA        *
*                   address ports.                                            *
*                                                                             *
* MODULE TYPE     : ASM                                                       *
*                                                                             *
* REGISTER USAGE  : 80386 Standard                                            *
*                                                                             *
* RESTRICTIONS    : None                                                      *
*                                                                             *
* DEPENDENCIES    : None                                                      *
*                                                                             *
* ENTRY POINTS    : DMAIN   - Entry point for "IN" instructions               *
*                   DMAOUT  - Entry point for "OUT" instructions              *
*                   MANPORT - Entry point to issue an OUT to the manufacturing*
*                             port to re-IPL the system                       *
*                                                                             *
* LINKAGE         : Jumped to by INDEXMA                                      *
*                                                                             *
* INPUT PARMS     : None                                                      *
*                                                                             *
* RETURN PARMS    : None                                                      *
*                                                                             *
* OTHER EFFECTS   : None                                                      *
*                                                                             *
* EXIT NORMAL     : Jump to POPIO to return to the V86 task                   *
*                                                                             *
* EXIT ERROR      : None                                                      *
*                                                                             *
* EXTERNAL                                                                    *
* REFERENCES      : DISPLAY   - Entry point in INDEEXC to signal an error     *
*                   POPIO     - Entry point in INDEEMU to return to the V86   *
*                               task                                          *
*                   PGTBLOFF  - Word in INDEI15 that contains the offset of   *
*                               the page tables                               *
*                   SGTBLOFF  - Word in INDEI15 that contains the offset of   *
*                               the page directory                            *
*                   NORMPAGE  - Double Word in INDEI15 that contains the      *
*                               entry that goes into the first page directory *
*                               entry so that it points to the normal page    *
*                               tables                                        *
*                   BUFF_SIZE - Word in INDEI15 that contains the size of the *
*                               MOVEBLOCK buffer                              *
*                   MAXMEM    - Word in INDEI15 that contains the total       *
*                               number of K in the box                        *
*                   WORD_FLAG - Byte in INDEXMA that indicates whether the    *
*                               I/O instruction was for a word or a byte      *
*                                                                             *
* SUB-ROUTINES    : XLATE  - Translate the virtual DMA address to a real DMA  *
*                            address                                          *
*                                                                             *
* MACROS          : DATAOV - Add prefix for the next instruction so that it   *
*                            accesses data as 32 bits wide                    *
*                   ADDROV - Add prefix for the next instruction so that it   *
*                            uses addresses that are 32 bits wide             *
*                   LJB    - Long jump if below                               *
*                   LJA    - Long jump if above                               *
*                   LJAE   - Long jump if above or equal                      *
*                   LJNE   - Long jump if not equal                           *
*                                                                             *
* CONTROL BLOCKS  : INDEDAT.INC - System data structures                      *
*                                                                             *
* CHANGE ACTIVITY :                                                           *
*                                                                             *
* $MOD(INDEDMA) COMP(LOAD) PROD(3270PC) :                                     *
*                                                                             *
* $D0=D0004700 410 870101 D : NEW FOR RELEASE 1.1                             *
* $P1=P0000312 410 870804 D : CLEAN UP WARNING MESSAGES                       *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

        .286P                 ; Enable recognition of 286 privileged instructs.

        .XLIST                ; Turn off the listing
        INCLUDE INDEDAT.INC   ; Include system data structures and equates

        IF1                   ; Only include macros on the first pass
        INCLUDE INDEOVP.MAC   ; Override prefix macros
        INCLUDE INDEINS.MAC   ; 386 instruction macros
        ENDIF
        .LIST                 ; Turn the listing back on

PROG    SEGMENT PARA PUBLIC 'PROG'

        ASSUME  CS:PROG
        ASSUME  DS:PROG
        ASSUME  ES:NOTHING
        ASSUME  SS:NOTHING

INDEDMA LABEL   NEAR

        EXTRN   DISPLAY:NEAR    ; Entry point in INDEEXC to signal an error
        EXTRN   POPIO:NEAR      ; Entry point in INDEEMU to return to the V86
                                ;   task
        EXTRN   PGTBLOFF:WORD   ; Word in INDEI15 that contains the offset of
                                ;   the page tables
        EXTRN   SGTBLOFF:WORD   ; Word in INDEI15 that contains the offset of
                                ;   the page directory
        EXTRN   NORMPAGE:WORD   ; Double Word in INDEI15 that contains the
                                ;   entry that goes into the first page direct-
                                ;   ory entry so that it points to the normal
                                ;   page tables
        EXTRN   BUFF_SIZE:WORD  ; Word in INDEI15 that contains the size of the
                                ;   MOVEBLOCK buffer
        EXTRN   MAXMEM:WORD     ; Word in INDEI15 that contains the total
                                ;   number of K in the box
        EXTRN   WORD_FLAG:BYTE  ; Byte in INDEXMA that indicates whether the
                                ;   I/O instruction was for a word or a byte

; Let these entry points be known to other modules

        PUBLIC  INDEDMA
        PUBLIC  DMAIN
        PUBLIC  DMAOUT
        PUBLIC  MANPORT

PAGE

; Define control blocks for each of the DMA channels 0 to 7.  The control
; blocks have information on where the user wanted to do DMA, where we will
; actually do the DMA, the channel number and the page port.  The following
; is an overlay for the control blocks.  After that the actual control
; blocks are defined.

DMACB   STRUC                   ; DMA control block

DMACHN  DB      0               ; Channel number
DMALSB  DB      0               ; Least significant address byte
DMAMSB  DB      0               ; Most significant address byte (16 bits)
DMAPAGE DB      0               ; Page - Hi-order of 24-bit address
DMALR   DB      0               ; Real Least significant address byte
DMAMR   DB      0               ; Real Most significant address byte (16 bits)
DMAPR   DB      0               ; Real Page - Hi-order of 24-bit address
DMAPP   DB      0               ; Compatability mode page port

DMACB   ENDS

DMASTART EQU    0
DMAENTRYLEN  EQU     DMAPP+1-DMASTART

; Now, the channel control blocks

DMATABLE DB     0                       ; Channel number
         DB     DMAENTRYLEN-2 DUP (0)   ; The other stuff
         DB     87H                     ; Page port

         DB     1                       ; Channel number
         DB     DMAENTRYLEN-2 DUP (0)   ; The other stuff
         DB     83H                     ; Page port

         DB     2                       ; Channel number
         DB     DMAENTRYLEN-2 DUP (0)   ; The other stuff
         DB     81H                     ; Page port

         DB     3                       ; Channel number
         DB     DMAENTRYLEN-2 DUP (0)   ; The other stuff
         DB     82H                     ; Page port

         DB     4                       ; Channel number
         DB     DMAENTRYLEN-2 DUP (0)   ; The other stuff
         DB     8FH                     ; Page port

         DB     5                       ; Channel number
         DB     DMAENTRYLEN-2 DUP (0)   ; The other stuff
         DB     8BH                     ; Page port

         DB     6                       ; Channel number
         DB     DMAENTRYLEN-2 DUP (0)   ; The other stuff
         DB     89H                     ; Page port

         DB     7                       ; Channel number
         DB     DMAENTRYLEN-2 DUP (0)   ; The other stuff
         DB     8AH                     ; Page port

; And now some more variables

DMACURRENT DB   0                       ; Channel we're working on
DMABYTE DB      0                       ; This flag is toggled between 0 and 1
                                        ;   to indicated whether the least
                                        ;   significant or most significant byte
                                        ;   of the DMA address is being written
DMA_ADV_CHN DB  0                       ; Advanced mode channel number

PAGE

; Define the jump table.  There are 32 entries in the table that correspond to
; the first 32 ports, 0 to 20H.  The code uses the port number as an index into
; this table which then gives control to the appropriate routine for that port.
; The table is initialized so that all entries jump to the code that will pass
; the I/O back to the real port.  Then the entries for the ports we want to
; handle are set to the corresponding routines for those ports.

OUT_TABLE:
        .XLIST
        REPT    32
        JMP     DOOUT
        ENDM
        .LIST
OUT_TABLE_END:

; Set the entries for the ports we want to handle.

        ORG     OUT_TABLE+(00H*3)
        JMP     CHN_0
        ORG     OUT_TABLE+(02H*3)
        JMP     CHN_1
        ORG     OUT_TABLE+(04H*3)
        JMP     CHN_2
        ORG     OUT_TABLE+(06H*3)
        JMP     CHN_3
        ORG     OUT_TABLE+(0CH*3)
        JMP     RESET_BYTE_PTR
        ORG     OUT_TABLE+(18H*3)
        JMP     CHK_FUNCTION
        ORG     OUT_TABLE+(1AH*3)
        JMP     CHK_BASE_REG

        ORG     OUT_TABLE_END

PAGE

; Control comes here from INDEXMA when it determines that the "IN" instruction
; is not for one of the XMA ports.  On entry, WORD_FLAG is already set for word
; or byte operation.  IP points to next instruction minus 1.  DX has the port
; value in it.

DMAIN   PROC    NEAR
        CMP     WORD_FLAG,0             ; Is this "IN" for a word?
        JNE     GETWORDREAL             ; Yes.  Then go get a word.

        IN      AL,DX                   ; Else we'll just get a byte
        MOV     BYTE PTR SS:[BP+BP_AX],AL ; And put it into the user's AL reg.
        JMP     INEXIT                  ; Go return to the user

GETWORDREAL:
        IN      AX,DX                   ; Get a word from the port
        MOV     WORD PTR SS:[BP+BP_AX],AX ; Put it into the user's AX register
        MOV     WORD_FLAG,0             ; Reset the word flag

INEXIT:
        ADD     WORD PTR SS:[BP+BP_IP],1 ; Step IP past the instruction, or past
                                        ;   the port value in the case of I/O
                                        ;   with an immediate port value
        JMP     POPIO                   ; Return to the V86 task

PAGE

; Control comes here from INDEXMA when it determines that the "OUT" instruction
; is not for one of the XMA ports.  On entry, WORD_FLAG is already set for word
; or byte operation.  IP points to next instruction minus 1.  DX has the port
; value in it.

DMAOUT:

; Check for DMA page registers in compatibility mode

        MOV     AX,SYS_PATCH_DS         ; Load DS with the selector for our data
        MOV     DS,AX                   ;   segment
        CMP     WORD_FLAG,0             ; Is this a word operation?
       LJNE     DISPLAY                 ; No?  Sorry.  We don't support word DMA
                                        ;   yet.  We'll just have to signal an
                                        ;   error.
        LEA     BX,DMATABLE             ; Point BX to the base of our channel
                                        ;   control blocks
        CMP     DX,0081H                ; Is this out to the channel 2 page port
       LJB      NOT_DMA_PAGE            ; If the port number is less than 81H
                                        ;   then the "OUT" is not to a DMA page
        JA      CHK_CHN_0               ; If the port number is above 81H, then
                                        ;   go check if it's below 87H, the page
                                        ;   port for channel 0
        ADD     BX,DMAENTRYLEN*2        ; If it's not below or above, then it
                                        ;   must be port 81H!  Point BX to the
                                        ;   control block for channel 2
        JMP     CHNCOM                  ; Continue

CHK_CHN_0:
        CMP     DX,0087H                ; Is it the page port for channel 0?
        JA      CHK680                  ; Nope. It's above that.  Go check for
                                        ;   the Roundup IPL port
        JE      CHNCOM                  ; It IS the page port for channel 0.
                                        ;   BX already points to the control
                                        ;   block for channel 0.
        CMP     DX,0083H                ; Is it the page port for channel 1?
        JB      SET_CHN_3               ; No.  It's below that.  Then it must
                                        ;   be the page port for channel 3!
       LJA      DISPLAY                 ; No.  It's above it.  We don't know any
                                        ;   ports between 83H and 87H.  Go
                                        ;   signal an error.
        ADD     BX,DMAENTRYLEN*1        ; Yes.  It's the page port for channel 1
                                        ;   Point BX to the control block for
                                        ;   channel 1.
        JMP     CHNCOM                  ; And continue

; The port is greater than 87H

CHK680:
        CMP     DX,680H                 ; Is it the manufacturing port (for IPL)
                                        ;   on the Roundup?
        JE      MANPORT                 ; Yes.  Go IPL the system.
        JMP     DOOUT                   ; No.  Pass the "OUT" on to the real
                                        ;   port.

; The "OUT" is to the page port for channel 3

SET_CHN_3:
        ADD     BX,DMAENTRYLEN*3        ; Point BX to the control block for
                                        ;   channel 3

; Check to see if the value written to the page port is greater than 0FH.
; Why?  Let me tell you.  Addresses are 20 bits, right?  The user puts the
; lower 16 bits into the channel port in two eight bit writes.  The value
; written to the page port is the upper eight bits of the address.  But to
; address 1M you only need 20 bits.  Therefore, only the lower four bits are
; valid if the address is to remain within the 1M address limit.  So if the
; value to be written to the page port is 10H or greater it is invalid, so
; we will signal an error.

CHNCOM:
        MOV     AL,BYTE PTR SS:[BP+BP_AX] ; Get the value that is to be written
                                        ;   to the page port
        CMP     AL,10H                  ; Is it 10H or greater?
        JB      CHNCONT                 ; Nope.  We're still OK.

; Oops.  It's an invalid page port value.  Time to signal an error.  But wait.
; If we just jump to DISPLAY as usual the code will just return to the V86
; task.  This is not good since we haven't Revised the DMA and it will end
; up going to the wrong address.  What we really want to do is kill the system.
; To do this we will issue an interrupt 6, invalid instruction.  The exception
; handler checks to see from whence the interrupt came.  If it came from the
; emulator then it assumes something is terribly wrong and issues an NMI.
; This is what we want.  So we'll issue an INT 6 instead of a JMP DISPLAY.

INVALID_PAGE:
        INT     6                       ; Signal and error
        JMP     INVALID_PAGE            ; Do it again in case control comes
                                        ;   back here

; At this point were still OK.  BX points to the control block for the channel.
; Let's translate the address we currently have to its real address and send
; it out to the DMA channel.

CHNCONT:
        MOV     BYTE PTR [BX+DMAPAGE],AL ; Put the page port value into the
                                        ;   control block
        CALL    XLATE                   ; Create the real address entries in
                                        ;   the control block
        MOV     DL,BYTE PTR [BX+DMACHN] ; Get the channel number from the c.b.
        SHL     DX,1                    ; Convert it to a port address
        MOV     AL,BYTE PTR [BX+DMALR]  ; Get the LSB of the real address
        OUT     DX,AL                   ; "OUT" it to the address port
        JMP     $+2                     ; Wait a bit
        MOV     AL,BYTE PTR [BX+DMAMR]  ; Get the MSB of the real address
        OUT     DX,AL                   ; "OUT" it to the address port
        JMP     $+2                     ; Wait a bit
        MOV     DL,BYTE PTR [BX+DMAPP]  ; Get the page port
        MOV     AL,BYTE PTR [BX+DMAPR]  ; Get the real page number
        OUT     DX,AL                   ; Do the "OUT" to the DMA page port
        JMP     OUTEXITDMA              ; That's it

PAGE

; This is where we come when we want to simply send the "OUT" to the real port.

DOOUT:
        CMP     WORD_FLAG,0             ; Is this an "OUT" for a word?
        JNE     PUTWORDREAL             ; Aye.  Go put out a word.

        MOV     AL,BYTE PTR SS:[BP+BP_AX] ; Nay.  It is for a byte.  Get the
                                        ;   byte from the user's AL register
        OUT     DX,AL                   ; And send it out to the port
        JMP     OUTEXITDMA              ; Time to leave

PUTWORDREAL:
        MOV     AX,WORD PTR SS:[BP+BP_AX] ; Get the word form the user's AX
        OUT     DX,AX                   ; And thrust it out to the port
        MOV     WORD_FLAG,0             ; Reset the word flag

OUTEXITDMA:

        ADD     WORD PTR SS:[BP+BP_IP],1 ; Step IP past the instruction, or past
                                        ;   the port value in the case of I/O
                                        ;   with an immediate port value
        JMP     POPIO                   ; Return to the V86 task

PAGE

; It's not an "OUT" to one of the DMA page ports.

NOT_DMA_PAGE:
        CMP     DX,(OUT_TABLE_END-OUT_TABLE)/3 ; Is the port within the range
                                        ;   covered by our jump table, i.e.,
                                        ;   0 to 20H
        JAE     NOTCOWBOY               ; Nope.  Let's go check if it's the IPL
                                        ;   port on the AT
        MOV     AL,DL                   ; Yes, it's handled by our jump table
        MOV     AH,3                    ; Convert the port number to an index
        MUL     AH                      ;   into the jump table by multiplying
                                        ;   by 3.  Jump table entry are 3 bytes.
        LEA     CX,OUT_TABLE            ; Get the offset of the jump table
        ADD     AX,CX                   ; And add it on to the index
        JMP     AX                      ; Jump to the jump table entry for this
                                        ;   port

NOTCOWBOY:
        CMP     DX,80H                  ; Is it the manufacturing (IPL) port for
                                        ;   the AT?
        JNE     DOOUT                   ; Negative.  Then let's just do a plain
                                        ;   vanilla "OUT" to the real port.
MANPORT:
        MOV     AL,0FEH                 ; It's the IPL port!  Send out a FEH to
        OUT     064H,AL                 ;   reset the system.

HALT:   HLT                             ; In case that trick didn't work    @P1C
        JMP     HALT                    ;   we'll just wait here until      @P1C
                                        ;   somebody hits the big red switch.

PAGE

; This is the entry for an "OUT" to port 0CH.  An "OUT" to this port will
; reset the controller so that the next out will be to the least significant
; byte of the address register.  The way you set the lower 16 bits of the
; address is by sending the two bytes to the same port, first the least
; significant byte (LSB) and then the most significant byte (MSB).  The port
; knows that successive bytes to the port mean successively higher bytes of
; the address.  We emulate this with our DMABYTE flag.  Since the user will
; only be sending two bytes to an address port this flag will be toggled
; between 0 and 1 indicating that the "OUT" was to the LSB if 0 and to the
; MSB if 1.  A write to port 0CH tells the controller that the next write
; will be for the LSB.  We emulate this by setting our DMABYTE flag to 0.

RESET_BYTE_PTR:
        MOV     DMABYTE,0               ; Reset the byte flag
        JMP     DOOUT                   ; Send the "OUT" to the real port

PAGE

; The following entries handle the "OUT"s to the address ports for channels
; 0 to 3.  These are ports 00, 02, 04 and 06 respectively.  As mentioned
; above the address written to these ports is done in two steps.  First the
; least significant byte (LSB) is written, the the most significant byte (MSB)
; is written.  This results in a 16 bit value in the address port.  Combine
; this with the byte in the page port and you have a 24 bit DMA address.  The
; code below emulates this by putting the byte that is "OUT"ed to the LSB if
; DMA BYTE is 0 and to the MSB if DMABYTE is 1.  DMABYTE is toggled between 0
; and 1 each time there is a write to the port.  So the bytes go alternately
; to the LSB and the MSB.

; "OUT" is to port 00, the address port for channel 0.

CHN_0:
        LEA     BX,DMATABLE             ; Point BX to the control block for
                                        ;   channel 0
        JMP     MOVBYTE                 ; Go get the byte

; "OUT" is to port 02, the address port for channel 1.

CHN_1:
        LEA     BX,DMATABLE+(1*DMAENTRYLEN) ; Point BX to the control block for
                                        ;   channel 1
        JMP     MOVBYTE                 ; Go get the byte

; "OUT" is to port 04, the address port for channel 2.

CHN_2:
        LEA     BX,DMATABLE+(2*DMAENTRYLEN) ; Point BX to the control block for
                                        ;   channel 2
        JMP     MOVBYTE                 ; Go get the byte

; "OUT" is to port 06, the address port for channel 3.

CHN_3:
        LEA     BX,DMATABLE+(3*DMAENTRYLEN) ; Point BX to the control block for
                                        ;   channel 3

MOVBYTE:
        MOV     AL,BYTE PTR SS:[BP+BP_AX] ; Get the byte from the user's AL
        XOR     DMABYTE,1               ; Toggle the DMABYTE flag
        JZ      MOVMSB                  ; Was the flag set to 1?  If so, go
                                        ;   put the byte to the MSB
        MOV     BYTE PTR [BX+DMALSB],AL ; Else it was 0 so put the byte in the
                                        ;   LSB for this channel
        JMP     OUTEXITDMA              ; And exit

MOVMSB:
        MOV     BYTE PTR [BX+DMAMSB],AL ; Put the byte in the MSB for this
                                        ;   channel
        JMP     OUTEXITDMA              ; And exit

PAGE

; This is the entry point for an "OUT" to port 18H.  It has something to do
; with the advanced DMA channels 4 thru 7.  If the function number in the high
; nibble of AL is 2, set the base register, then we'll save the advanced channel
; number given in the low nibble of AL.  If the function is not 2 then we will
; inhibit the setting of the base register.

CHK_FUNCTION:
        MOV     AL,BYTE PTR SS:[BP+BP_AX] ; Get the value to be "OUT"ed to 18H
        SHR     AL,4                    ; Shift the function number into AL
        CMP     AL,2                    ; Is this the function to set the base
                                        ;   register?
        JE      SAVE_CHN                ; Yup.  Go save the channel number.
        MOV     DMABYTE,3               ; Nope.  Inhibit setting the base reg.
        JMP     DOOUT                   ; Send the "OUT" to the real port

SAVE_CHN:
        MOV     AL,BYTE PTR SS:[BP+BP_AX] ; Get the value in AL again
        AND     AL,07H                  ; Mask off the function number leaving
                                        ;   the channel number
        MOV     DMA_ADV_CHN,AL          ; And save it
        JMP     RESET_BYTE_PTR          ; Go reset the byte flag

PAGE

; This is the entry for an "OUT" to port 1AH.

CHK_BASE_REG:
        CMP     DMABYTE,3               ; Are we inhibiting setting the base
                                        ;   register?
       LJAE     DOOUT                   ; Yes.  Then just sent the "OUT" to the
                                        ;   real port
        LEA     BX,DMATABLE             ; Point BX to the channel control blocks
        MOV     AL,DMA_ADV_CHN          ; Get the current advanced channel
        MOV     AH,DMAENTRYLEN          ;   and multiply by the size of a
        MUL     AH                      ;   control block.  Now AX is the index
                                        ;   for the current control block
        ADD     BX,AX                   ; Add this on to the base and BX points
                                        ;   to the control block
        SUB     AX,AX                   ; Purge AX
        MOV     AL,DMABYTE              ; Get the byte flag
        ADD     BX,AX                   ; And add it on to BX
        MOV     CL,BYTE PTR SS:[BP+BP_AX] ; Get the out value into CL

; Now put it in the control block.  Notice that BX is the base of the control
; block plus the byte flag.  Now we add on the offset for the LSB entry.  A
; little pondering of this code will reveal that for DMABYTE = 0 the byte in
; CL goes to the LSB entry, for DMABYTE = 1 it goes to the MSB entry and for
; DMABYTE = 2 it goes to the page entry.

        MOV     BYTE PTR [BX+DMALSB],CL ; Save the byte in the control block
        INC     DMABYTE                 ; Increment our byte counter
        CMP     DMABYTE,3               ; Was the page entry written?
       LJNE     OUTEXITDMA              ; Nope.  Let's just exit.

        SUB     BX,AX                   ; The page was written.  Point BX back
                                        ;   to the start of the control block.
        CMP     CL,10H                  ; Does the page point to over 1M?
       LJAE     INVALID_PAGE            ; Yes.  Better signal an error.

        CALL    XLATE                   ; The page is OK.  Translate the virtual
                                        ;   address to the real address
        MOV     AL,BYTE PTR [BX+DMALR]  ; Get the LSB of the real address
        OUT     1AH,AL                  ; "OUT" it to the port 1AH
        JMP     $+2                     ; Wait a bit
        MOV     AL,BYTE PTR [BX+DMAMR]  ; Get the MSB of the real address
        OUT     1AH,AL                  ; "OUT" it to the port 1AH
        JMP     $+2                     ; Wait a bit
        MOV     AL,BYTE PTR [BX+DMAPR]  ; Get the real page number
        OUT     1AH,AL                  ; Do the "OUT" to port 1AH
        JMP     OUTEXITDMA              ; That's all

PAGE

; XLATE is a procedure to translate the virtual DMA address to the real DMA
; address.  It takes the virtual address that was "OUT"ed to the DMA ports
; and follows it through the page tables to get the real address.  It puts
; the real address into the current channel control block.

XLATE   PROC

; Calcuate the page fram offset of the real address,  the lower 12 bits.

        MOV     AX,WORD PTR [BX+DMALSB] ; Get the virtual LSB and MSB
        AND     AH,0FH                  ; Wipe out the top nibble.  This leaves
                                        ;   us with only the offset into the 4K
                                        ;   page frame.  This real address will
                                        ;   have the same offset into the page
                                        ;   frame
        MOV     WORD PTR [BX+DMALR],AX  ; So save this in the real LSB

; Pick up page table address.

        MOV     SI,SGTBLOFF             ; Point ST to the first page directory
                                        ;  entry
        DATAOV                          ; Get the address of the current page
        LODSW                           ;   table
        SUB     AL,AL                   ; Clear the access rights byte.  This
                                        ;   makes it a real offset.
        DATAOV                          ; Point SI to the page table
        MOV     SI,AX
        MOV     AX,WORD PTR [BX+DMAMSB] ; Get the MSB and page
        SHR     AX,4                    ; Shift the top four bits off the end
                                        ;   of the register these four bits are
                                        ;   not used.  We are dealing with a 24
                                        ;   bit address where only 20 bits are
                                        ;   used.
        SHL     AX,4-2                  ; Shift back 2 bits.  This puts zeroes
                                        ;   in the high bits while converting
                                        ;   the address to a page table index.
                                        ;   Page table entries are 4 bytes long,
                                        ;   hence, shift left 2 bits.
        ADD     SI,AX                   ; Add the page table index on to the
                                        ;   offset of the page table.  SI now
                                        ;   points to the correct page table
                                        ;   entry.
        ADD     SI,1                    ; Step over the access rights byte

        MOV     AX,HUGE_PTR             ; Load DS with a selector that accesses
        MOV     DS,AX                   ;   all of memory as data
        ADDROV                          ; Load the address of the page frame
        LODSW                           ;   into EAX
        MOV     CX,SYS_PATCH_DS         ; Point DS back to our data segment
        MOV     DS,CX

; Now AX contains the address of the page frame shifted right 8 bits.  Remember
; that we incremented SI to skip the access rights?  This gave us the page
; frame offset with out the lower byte.  The lSB real address was already set
; above, as well as the low nibble of the real MSB.  AX now contains the page
; and MSB of the real address.  The low nibble of the MSB was already set so
; we just OR on the high nibble of the MSB.  Then we set the real page.  Then
; we're all done.

        OR      BYTE PTR [BX+DMAMR],AL  ; Turn on high 4 bits of the real MSB
        MOV     BYTE PTR [BX+DMAPR],AH  ; Set the real page

        RET

XLATE   ENDP

DMAIN   ENDP

PROG    ENDS

        END
