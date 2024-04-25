;-----------------------------------------------------------------------;
;       DATA THAT IS UNIQUE TO THE DIAGNOSTICS PORTION OF               ;
;       THE DEVICE DRIVER. THIS AREA WILL NOT REMAIN PRESENT            ;
;       AFTER INITIALIZATION.                                           ;
;-----------------------------------------------------------------------;
INCLUDE    EMS_US.MSG

MEM_INST        DB      '1'
ADDR_MODEL_BYTE DD      0F000FFFEH      ;ADDRESS IN BIOS OF MODEL BYTE
MODEL           DB      ?               ;SAVE AREA FOR MODEL
TEST_ID         DB      ?               ;SAVE AREA FOR CURRENT TEST ID
CTRLPARM        DW      ?               ;SAVE AREA FOR CONTROL PARM
PAGE_UNDER_TEST DW      0               ;SAVE AREA FOR PAGE UNDER TEST
CUR_SAVE        DW      ?               ;SAVE AREA FOR NEXT AVAILABLE LINE
                                        ;FOR MESSAGES
ACTIVE_PAGE     DB      ?               ;ACTIVE DISPLAY PAGE
TESTABLE_SEGMENTS DW    ?


PAGE
;-----------------------------------------------------------------------;
;       EQUATES THAT ARE UNIQUE TO THE DIAGNOSTICS PORTION OF           ;
;       THE DEVICE DRIVER.                                              ;
;-----------------------------------------------------------------------;
BASE_REG        EQU     31A0H
DMACAPT         EQU     31A8H           ;I/O ADDRESS OF DMA CAPTURE REG
BLK_ON          EQU     11110111B       ;MASK FOR ENABLING A BLOCK
BLK_OFF         EQU     00001000B       ;MASK FOR INHIBITING A BLOCK
VIRT_MODE       EQU     00000010B       ;MASK FOR VIRTUAL MODE
REAL_MODE       EQU     11111101B       ;MASK FOR REAL MODE
MAX_TASK_ID     EQU     15              ;MAXIMIM TASK ID
ENABLE          EQU     01H             ;INDICATES THAT BLOCK SHOULD BE ENABLED
TABLEN          EQU     1000H           ;NUMBER OF ENTRIES IN XLAT TABLE
DMAREQ1         EQU     0009H           ;I/O ADDRESS OF DMA CTRL 1 REQ REG
DMAREQ2         EQU     00D2H           ;I/O ADDRESS OF DMA CTRL 2 REQ REG
DMAMODE1        EQU     000BH           ;I/O ADDRESS OF DMA CTRL 1 MODE REG
DMAMODE2        EQU     00D6H           ;I/O ADDRESS OF DMA CTRL 2 MODE REG
PC1             EQU     0FFH            ;RESERVED BYTE FOR PC1
PC_XT           EQU     0FEH            ;RESERVED BYTE FOR XT
XT_AQUARIUS     EQU     0FBH            ;RESERVED BYTE FOR XT-AQUARIUS
AT_NMI_REG      EQU     70H             ;AT NMI REG
AT_NMI_OFF      EQU     80H             ;AT NMI OFF MASK
AT_NMI_ON       EQU     00H             ;AT NMI ON MASK
AT_CHCHK_EN_REG EQU     61H             ;AT CH CHK ENABLE REG
AT_CHCHK_REG    EQU     61H             ;AT CH CHK REG
AT_CHCHK_EN     EQU     0F7H            ;AT CH CHK ENABLE MASK
AT_CHCHK_DIS    EQU     08H             ;AT CH CHK DISABLE MASK
AT_CHCHK        EQU     40H             ;AT CH CHK MASK
XT_NMI_REG      EQU     0A0H            ;XT NMI REG
XT_NMI_OFF      EQU     00H             ;XT NMI OFF MASK
XT_NMI_ON       EQU     80H             ;XT NMI ON MASK
XT_CHCHK_EN_REG EQU     61H             ;XT CH CHK ENABLE REG
XT_CHCHK_REG    EQU     62H             ;XT CH CHK REG
XT_CHCHK_EN     EQU     0DFH            ;XT CH CHK ENABLE MASK
XT_CHCHK_DIS    EQU     20H             ;XT CH CHK DISABLE MASK
XT_CHCHK        EQU     40H             ;XT CH CHK MASK
ONE_MEG         EQU     16              ;CONSTANT FOR ONE MEG MEMORY CARD
TWO_MEG         EQU     32              ;CONSTANT FOR TWO MEG MEMORY CARD
CR              EQU     0DH             ;CARRIAGE RETURN
LF              EQU     0AH             ;LINE FEED
PRES_TEST       EQU     01              ;PRESENCE TEST ID
REG_TEST        EQU     02              ;REG TEST ID
AUTO_INC        EQU     03              ;AUTO INC TEST ID
XLAT_TABLE_TEST EQU     04              ;TT TEST ID
LOMEM_TEST      EQU     05              ;ABOVE 640K TEST ID
DMA_CAPTURE     EQU     06              ;DMA CAPTURE TEST ID
PAGE_TEST       EQU     07              ;PAGE TEST ID
MEM_TEST        EQU     10              ;MEMORY TEST ID


;------------------------------------------------------------------------;
;          Diagnostics...on exit if ZF=0 then error                      ;
;------------------------------------------------------------------------;
DIAGS           PROC

                MOV     CS:TEST_ID,00H                  ;CLEAR TEST ID BYTE
                MOV     CS:CTRLPARM,0100H               ;SAVE CONTROL PARM
                CALL    GETMOD                          ;FIND OUT WHICH PC THIS IS
                CALL    CUR_POS                         ;GET CURSOR READY FOR MESSAGES
                CALL    REGTST                          ;TEST XMA REGISTERS
                JNE     FOUND_ERROR                     ;JUMP IF ERROR
                CALL    INCTST
                JNE     FOUND_ERROR
                CALL    XLATST
                JNE     FOUND_ERROR
                CALL    LOMEMTST                        ;TEST FOR BELOW 640K
                JNE     FOUND_ERROR                     ;JUMP IF ERROR
                CALL    MEMARRAY                        ;TEST MEMORY ABOVE 640K
                JNE     FOUND_ERROR                     ;JUMP IF ERROR
                CALL    PAGETST
                JNE     FOUND_ERROR
                CALL    CAPTST                          ;TEST DMA CAPTURE
                JNE     FOUND_ERROR                     ;JUMP IF ERROR
FOUND_ERROR:
                RET
DIAGS           ENDP




PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       PRESENCE TEST
;
; DESCRIPTION   :  This routine will determine if the XMA is in the system.
;                  It will also determine the amount of memory installed
;                  on the card in 1Meg increments (up to 4Meg).
;
; FUNCTION/     :  See description
; PURPOSE
;
; ENTRY POINT   :  PRESTST
;
; ENTRY         :  The assumption is that at least 1MB of memory is installed.
; CONDITIONS       If the 2nd, 3rd or 4th MB of memory is installed then the
;                  TOTAL_XMA_PAGES, TOTAL_PAGES, FREE_PAGES and
;                  MEM_INST words are Revised accordingly.
;
;
;
; EXIT          :  (zero flag) = 0 indicates that the XMA is not installed.
;                  if (zero flag) <> 0 then
;                  TOTAL_XMA_PAGES, TOTAL_PAGES, FREE_PAGES and
;                  MEM_INST words are Revised accordingly.
;
;                  AX,BX,CX,DX ARE DESTROYED
;-------------------------------------------------------------------------
;
PRESTST         PROC
;
                MOV     AL,PRES_TEST
                MOV     CS:TEST_ID,AL

;SAVE CONTENTS OF MODE REG
                MOV     DX,MODE_REG
                IN      AL,DX
                PUSH    AX

; TRANSLATE TABLE ADDRESS AND DATA REGISTERS
;
                MOV     AX,0AA55H               ;DATA PATTERN (IN REAL MODE)
                                                ;BE CERTAIN MODE REG GETS
                                                ;REAL MODE
                MOV     DX,MODE_REG             ;I/O TO MODE REG
                OUT     DX,AL                   ;WRITE PATTERN
                MOV     DX,TTPOINTER + 1        ;I/O TO TT POINTER (ODD ADDR)
                XCHG    AL,AH                   ;CHRG BUS WITH INVERSE PATTERN
                OUT     DX,AL                   ;WRITE IT
                MOV     DX,MODE_REG
                IN      AL,DX                   ;READ BACK MODE REG
                XOR     AL,AH
                AND     AL,0FH                  ;MASK OFF UNUSED BITS
                                                ;ZERO FLAG = 0 IF ERROR
END_PRES:
                POP     AX
                PUSHF                           ;SAVE FLAGS
                MOV     DX,MODE_REG
                OUT     DX,AL                   ;RESTORE MODE REG TO INITIAL STATE
                POPF                            ;RESTORE FLAGS
                RET                             ;BACK TO CALLER
;
PRESTST         ENDP




PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       SAVES CURSOR POSITION
;
; DESCRIPTION   :  This routine simply saves the cursor location
;                  in CS:CUR_SAVE.  This cursor position
;                  should be used by the KB_OK routine to insure proper
;                  format of the screen.
;
; FUNCTION/     :  See description
; PURPOSE
;
;
; ENTRY POINT   :  CUR_POS
;
; ENTRY         :
; CONDITIONS
;
;
; EXIT          :  new cursor position is saved in CS:CUR_SAVE
;
;                  All registers are preserved
;
;-------------------------------------------------------------------------
;
CUR_POS         PROC
;
                PUSH    AX
                PUSH    BX
                PUSH    CX
                PUSH    DX
                PUSH    SI
                PUSH    DI
                PUSH    DS                      ;SAVE REGISTERS
;
                PUSH    CS
                POP     DS                      ;GET DS TO THIS CODE SEGMENT
        ;MOVE CURSOR TO NEXT AVAILABLE LINE
;IF DOS
;                MOV     AH,9                    ;DOS PRINT STRING
;                MOV     DX,OFFSET NEXT_LINE + 1 ;OFFSET OF NEXT LINE MSG
;                INT     21H                     ;DISPLAY MESSAGE
;ELSE
;                MOV     BX,OFFSET NEXT_LINE     ;GET OFFSET OF NEXT LINE MSG
;                MOV     AH,0                    ;TELL DCP TO DISPLAY
;                INT     82H                     ;DISPLAY MESSAGE
;ENDIF
                                                ; rsh001 fix scroll problem
                                                ;  and remove IF DOS crap
        ;READ CURRENT VIDEO PAGE                ; rsh001
                MOV     AH,15                   ;READ CURRENT Video Page
                INT     10H                     ;VIDEO CALL
                MOV     ACTIVE_PAGE,BH          ;SAVE ACTIVE PAGE

        ;READ CURRENT CURSOR POSITION
                MOV     AH,3                    ;READ CURRENT CURSOR POS
                INT     10H                     ;VIDEO CALL
                MOV     CUR_SAVE,DX             ;SAVE CURSOR POSITION

        ;RESTORE ALL REGISTERS
                POP     DS
                POP     DI
                POP     SI
                POP     DX
                POP     CX
                POP     BX
                POP     AX                      ;RESTORE ALL REGISTERS

                RET                             ;RETURN TO CALLER

CUR_POS         ENDP





PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                  TEST FOR PRESENCE OF MORE THAN 1 MEGABYTE OF MEMORY
;
; DESCRIPTION   :  This routine will determine if the 2nd, 3rd or 4th MB is
;                  installed. Since there are no switches or other indicators
;                  to be tested, this test will make a "best guess" as to
;                  the presence of this memory. This test will roll a 0
;                  and a 1 through the 1st word of the next Meg and if
;                  at least 1 bit is consistently good then it is assumed
;                  that the optional memory is installed. If successful
;                  then try next Meg.
;
; FUNCTION/     :  See description
; PURPOSE
;
; ENTRY POINT   :  TRY4MEG
;
; ENTRY         :  none
; CONDITIONS
;
; EXIT          :
;
;                  AX,BX,CX,DX ARE DESTROYED
;-------------------------------------------------------------------------
;
TRY4MEG         PROC

;MEMORY TEST MUST RUN IN PAGE MODE
;BEFORE CARD IS PUT INTO PAGE MODE...MUST SET UP XLAT TABLE TO  PASSOVER
;RESERVED MEMORY SPACES (IE.,BIOS, DISPLAY, DISTRIBUTED ROS, ETC)
;
                CALL    VIRT2REAL

                MOV     DX,IDREG                ;I/O TO ID REGISTER
                MOV     AL,0                    ;ID = 0
                OUT     DX,AL                   ;SWITCH TO ID = 0
;
        ;DISABLE NMI AND ENABLE I/O CHANNEL CHECK
                MOV     AL,CS:MODEL             ;GET SAVED MODEL BYTE
                CMP     AL,PC1                  ;IS IT A PC1?
                JE      TR2M1                   ;IF NO THEN TRY FOR PC_XT
                CMP     AL,PC_XT                ;IS IT AN XT?
                JE      TR2M1                   ;IF NO THEN TRY FOR AQUARIUS
                CMP     AL,XT_AQUARIUS          ;IS IT AN AQUARIUS?
                JE      TR2M1                   ;IF NO THEN USE AT NMI REGS
        ;USE PC-AT NMI REGISTER
                MOV     DX,AT_NMI_REG           ;AT's NMI REGISTER
                MOV     AL,AT_NMI_OFF           ;MASK OFF NMI
                OUT     DX,AL                   ;OUTPUT IT
                MOV     DX,AT_CHCHK_EN_REG      ;AT's I/O CH CHK REG
                IN      AL,DX                   ;READ IT
                OR      AL,AT_CHCHK_DIS         ;MASK OFF I/O CH CHK ENABLE
                OUT     DX,AL                   ;WRITE IT
                AND     AL,AT_CHCHK_EN          ;MASK ON I/O CH CHK ENABLE
                OUT     DX,AL                   ;TOGGLE CH CHK LTCH AND LEAVE
                                                ;ENABLED
        ;USE PC1, XT, AQUARIUS REGISTERS
TR2M1:
                MOV     DX,XT_NMI_REG           ;XT's NMI REGISTER
                MOV     AL,XT_NMI_OFF           ;MASK OFF NMI
                OUT     DX,AL                   ;OUTPUT IT
                MOV     DX,XT_CHCHK_EN_REG      ;XT's I/O CH CHK REG
                IN      AL,DX                   ;READ IT
                OR      AL,XT_CHCHK_DIS         ;MASK OFF I/O CH CHK ENABLE
                OUT     DX,AL                   ;WRITE IT
                AND     AL,XT_CHCHK_EN          ;MASK ON I/O CH CHK ENABLE
                OUT     DX,AL                   ;TOGGLE CH CHK LTCH AND LEAVE
                                                ;ENABLED
;
        ;MAP FIRST 64K OF 2ND MEG INTO PC SPACE BEGINNING AT 512K
;***jnw         MOV     CX,3                    ;LOOK FOR PRESENCE OF NEXT 3 MB IN 1MB STEPS
                MOV     CX,99*1024/16   ;***jnw ;LOOK FOR PRESENCE OF NEXT n MB IN 1MB STEPS
                MOV     AX,CS:PAGE_FRAME_STA    ;SEGMENT AT PAGE FRAME
;***jnw         MOV     DX,256                  ;BEGINNING AT 2ND MEG OF XMA
                MOV     DX,256+3    ;***jnw     ;AT end of 16k
                MOV     BH,0                    ;ASSIGNED TO TASK ID 0
                MOV     BL,01H                  ;ENABLE THIS MEMORY
TR2M1A:
                PUSH    AX
                PUSH    BX
                PUSH    CX
                PUSH    DX
;***jnw         MOV     CX,16                   ;16 * 4K = 64K BLOCK
                MOV     CX,1     ;***jnw        ;1 * 4K = 4K BLOCK
                CALL    SETXLAT                 ;SET TRANSLATE TABLE
;
                MOV     AX,CS:PAGE_FRAME_STA
                MOV     DS,AX                   ;SET SEGMENT AND
                MOV     SI,0                    ;OFFSET TO TEST
                MOV     BX,0000000000000001B    ;ROLL 1 THROUGH WORD
                MOV     DX,1111111111111110B    ;ROLL 0 THROUGH WORD
                MOV     CX,16                   ;16 BITS TO TEST
TR2M2:
                MOV     [SI],BX                 ;WRITE ROLLING 1 PATTERN
        LOCK    MOV     [SI+2],DX               ;CHARGE BUS INVERSE PATTERN
        LOCK    MOV     AX,[SI]                 ;READ BACK INITIAL PATTERN
                AND     AX,BX                   ;ISOLATE BIT UNDER TEST
;***jnw         JZ      TR2M3                   ;IF ZERO TRY ANOTHER BIT
                JZ      quit                    ;IF ZERO quit ***jnw
                MOV     [SI],DX                 ;WRITE ROLLING 0 PATTERN
        LOCK    MOV     [SI+2],BX               ;CHARGE BUS INVERSE PATTERN
        LOCK    MOV     AX,[SI]                 ;READ BACK INITIAL PATTERN
                AND     AX,BX                   ;ISOLATE BIT UNDER TEST
                AND     AX,BX                   ;ISOLATE BIT UNDER TEST
;***jnw         JZ      TR2M4                   ;IF ZERO THEN FOUND GOOD BIT
                Jnz     quit                    ;IF nonzero then quit ***jnw
TR2M3:
                ROL     BX,1                    ;ROLL 1 TO NEXT POSITION
                ROL     DX,1                    ;ROLL 0 TO NEXT POSITION
                LOOP    TR2M2                   ;REPEAT FOR 16 BITS
                jmp     tr2m4   ;all 16 bits passed test ***jnw
quit:   ;***jnw
;AT THIS POINT THERE ARE NO GOOD BITS SO END SEARCH FOR NEXT MB
                POP     DX                      ;RECOVER THESES REGISTERS
                POP     CX
                POP     BX
                POP     AX
                JMP     TR2M5                   ;EXIT
;AT THIS POINT WE KNOW THERE IS MEMORY IN THIS MEG THAT WAS JUST TESTED
TR2M4:
;***jnw         ADD     CS:MEM_INST,1                   ;ADD 1 MB TO THIS FLAG
;***jnw         ADD     CS:TOTAL_XMA_PAGES,1024/16      ;ADD 1 MB TO THIS FLAG
;***jnw         ADD     CS:TOTAL_PAGES,1024/16          ;ADD 1 MB TO THIS FLAG
;***jnw         ADD     CS:FREE_PAGES,1024/16           ;ADD 1 MB TO THIS FLAG
                ADD     CS:TOTAL_XMA_PAGES,1            ;Add 16k ***jnw
                ADD     CS:TOTAL_PAGES,1                ;Add 16k ***jnw
                ADD     CS:FREE_PAGES,1                 ;Add 16k ***jnw
                POP     DX                              ;RECOVER THESE REGISTERS
                POP     CX
                POP     BX
                POP     AX
;***jnw         ADD     DX,256                  ;TRY NEXT MB
                ADD     DX,4                   ;TRY NEXT 16k ***jnw
                LOOP    TR2M1A                  ;REPEAT LOOP
TR2M5:
;BEFORE NMI IS ENABLED, CLEAR PARITY CHECK LATCH ON XMA
                MOV     SI,0
                MOV     AX,[SI]                 ;READ 1ST WORD OF THIS SEG
                MOV     [SI],AX                 ;WRITE BACK SAME WORD
                                                ;THE WRITE WILL CLEAR PCHK LTCH
;PUT THE XMA CARD BACK INTO REAL MODE
                MOV     DX,MODE_REG             ;READY FOR I/O TO MODE REG
                IN      AL,DX                   ;READ IT
                AND     AL,REAL_MODE            ;TURN OFF VIRTUAL BIT
                OUT     DX,AL                   ;WRITE IT TO MODE REG
;CLEAR I/O CHANNEL CHECK LATCHES AND ENABLE NMI
                MOV     AL,CS:MODEL             ;GET SAVED MODEL BYTE
                CMP     AL,PC1                  ;IS IT A PC1?
                JE      TR2M6                   ;USE XT REGISTERS
                CMP     AL,PC_XT                ;IS IT AN XT?
                JE      TR2M6                   ;USE XT REGISTERS
                CMP     AL,XT_AQUARIUS          ;IS IT AN AQUARIUS?
                JE      TR2M6                   ;USE XT REGISTERS
;IF NONE OF THE ABOVE THEN...
;USE AT NMI REGISTER
                MOV     DX,AT_CHCHK_EN_REG      ;AT's I/O CH CHK REG
                IN      AL,DX                   ;READ IT
                OR      AL,AT_CHCHK_DIS         ;MASK OFF I/O CH CHK ENABLE
                OUT     DX,AL                   ;WRITE IT
                AND     AL,AT_CHCHK_EN          ;MASK ON I/O CH CHK ENABLE
                OUT     DX,AL                   ;TOGGLE CH CHK LTCH AND LEAVE
                                                ;ENABLED
                MOV     DX,AT_NMI_REG           ;AT's NMI REGISTER
                MOV     AL,AT_NMI_ON            ;MASK ON NMI
                OUT     DX,AL                   ;OUTPUT IT
;USE XT/AQUARIUS NMI REGISTER
TR2M6:
                MOV     DX,XT_CHCHK_EN_REG      ;XT's I/O CH CHK REG
                IN      AL,DX                   ;READ IT
                OR      AL,XT_CHCHK_DIS         ;MASK OFF I/O CH CHK ENABLE
                OUT     DX,AL                   ;WRITE IT
                AND     AL,XT_CHCHK_EN          ;MASK ON I/O CH CHK ENABLE
                OUT     DX,AL                   ;TOGGLE CH CHK LTCH AND LEAVE
                                                ;ENABLED
                MOV     DX,XT_NMI_REG           ;XT's NMI REGISTER
                MOV     AL,XT_NMI_ON            ;MASK ON NMI
                OUT     DX,AL                   ;OUTPUT IT
;
                RET                             ;RETURN TO CALLER

TRY4MEG         ENDP


PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       REGISTER TESTS
;
; DESCRIPTION   :  This routine will test the following subset
;                  of XMA registers:
;                           31A0...8 bits
;                           31A1...4 bits
;                           31A6...4 bits
;                           31A7...4 bits (BIT 1 IS HELD LOW TO DISABLE
;                                          THE VIRTUAL MODE)
;
;                  The test is performed by writing and reading
;                  AA, 55, FF, 00 from each of the above locations.
;
;                  NOTE: Regs 31A6 and 31A7 should always return 0 in
;                        the high nibble.
;
;                  The remainding registers will be tested in
;                  subsequent routines.
;
;
; FUNCTION/     :  To ensure integrity of XMA registers that will be used
; PURPOSE          in subsequent routines.
;
; ENTRY POINT   :  REGTST
;
; ENTRY         :  none
; CONDITIONS
;
; EXIT          :  XMA registers are set to zero
;
;                  (zero flag) = 0 indicates an error
;                  (DX) failing register
;                  (AL) expected data XOR'ed with actual data
;
;-------------------------------------------------------------------------
;
REGTST PROC
;
                MOV     AL,REG_TEST
                MOV     CS:TEST_ID,AL

;SAVE CONTENTS OF MODE REG
                MOV     DX,MODE_REG
                IN      AL,DX
                PUSH    AX

; TRANSLATE TABLE ADDRESS AND DATA REGISTERS
;
                MOV     BX,0AA55H               ;SET UP INITIAL DATA PATTERN
                MOV     AX,BX
                MOV     CX,BX

R1:
                MOV     DX,BASE_REG             ;FIRST REGISTER PAIR TO WRITE

                OUT     DX,AX                   ;WRITE PATTERN TO REGS
                ADD     DX,6                    ;POINT TO NEXT REG PAIR
                XCHG    AL,AH                   ;SETUP INVERSE PATTERN
                AND     AH,11111101B            ;MASK OFF BIT 1
                OUT     DX,AX                   ;BECAUSE AH -> 21B7
R2:
                SUB     DX,6                    ;POINT TO FIRST REGISTER PAIR
                IN      AX,DX                   ;READ REGISTER (21B1 -> AH)
                XOR     AX,BX                   ;DATA READ AS EXPECTED ?
                AND     AX,0FFFH                ;MASK OFF UPPER NIBBLE OF 21B1
                JNE     R_ERROR                 ;MISMATCH - GO TO ERROR ROUTINE
                XCHG    BH,BL                   ;NEXT PATTERN TO TEST
                AND     BX,0F0FH                ;REGS RETURN 0 IN HI NIBBLE
                ADD     DX,6                    ;POINT TO NEXT REGISTER PAIR
                IN      AX,DX                   ;READ IT (21B7 -> AH)
                XOR     AX,BX                   ;DATA READ AS EXPECTED ?
                AND     AX,0DFFH                ;MASK OFF BIT 1 IN REG 21B7
                JNE     R_ERROR                 ;MISMATCH - GO TO ERROR ROUTINE
;
                CMP     CH,CL                   ;LAST PASS ?
                JE      R_EXIT                  ;YES - THEN EXIT REG TEST
;
                CMP     CX,055AAH               ;END OF AA55,55AA PATTERNS?
                JNE     R3                      ;
                MOV     CX,000FFH               ;SET UP NEXT VALUE TO WRITE
                JMP     R4
R3:
                CMP     CX,00FFH                ;END OF FF00,00FF PATTERNS?
                JNE     R4                      ;
                MOV     CX,0                    ;YES, THEN SET UP FOR LAST PASS
R4:
                XCHG    CL,CH                   ;SET UP INVERSE PATTERN
                MOV     AX,CX                   ;SAVE IT
                MOV     BX,CX                   ;SAVE IT
R5:
                JMP     R1                      ;CONTINUE TILL ZERO PATTERN

R_ERROR:
R_EXIT:
                POP     AX
                MOV     DX,MODE_REG
                OUT     DX,AL                   ;restore mode reg
                RET
;
REGTST          ENDP




PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       MEMORY ARRAY TEST
;
; DESCRIPTION   :  This routine test all 1Meg (or 2Meg) of XMA memory
;                  through a 64K window in PC space beginning at PF:0
;                  (where PF is the Page Frame Segment)
;                  This module looks at TOTAL_XMA_PAGES
;                  to determine the memory size to be tested.
;
;                  (i) write the Translate Table for the 1st 64K block
;                      of XMA memory to be mapped into PF:0 in PC space
;                 (ii) test PF:0 to PF:FFFF
;                (iii) if good...write Translate Table to map next 64K block
;                      into PF:0
;                 (iv) repeat 'till all XMA memory is tested
;
; FUNCTION/     :  See description
; PURPOSE
;
;
; ENTRY POINT   :  MEMARRAY
;
; ENTRY         :
; CONDITIONS
;
; EXIT          :  All SMAS memory is set to zero.
;
;                  (zero flag) = 0 if storage error
;                  (AX) expected data XOR'ed with actual data
;                           if AX = 0 and ZF = 0 then parity error
;                  DS:SI point to failing location
;                  CS:PAGE_UNDER_TEST point failing 64k block
;
;                  AX,BX,CX,DX,DS,ES,SI,DI ARE DESTROYED
;
;-------------------------------------------------------------------------

MEMARRAY        PROC

                MOV     AL,MEM_TEST
                MOV     CS:TEST_ID,AL

;MEMORY TEST MUST RUN IN PAGE MODE

                CALL    VIRT2REAL

;INDICATE 0 KB OK
                MOV     DX,(640-64)/4           ;CODE FOR 640 KB OK
                CALL    KB_OK
;SETUP FOR TEST OF SMAS MEMORY ARRAY
                MOV     AX,CS:PAGE_FRAME_STA    ;PAGE MEMORY FROM THIS SEGMENT
                MOV     ES,AX                   ;SET UP DEST SEG
                MOV     DS,AX                   ;SET UP SOURCE SEG
                MOV     BL,01H                  ;ENABLE THIS BLOCK OF MEMORY
                MOV     BH,0                    ;USING ID 0
                MOV     DX,(640)/4              ;STARTING BLK IN SMAS ARRAY
        ;DETERMINE HOW MUCH MEMORY TO TEST
                MOV     CX,CS:TOTAL_XMA_PAGES   ;GET NUMBER OF 16K PAGES
                SHR     CX,1                    ;CONVERT TO NUMBER
                SHR     CX,1                    ;    OF 64K SEGMENTS
                SUB     CX,640/64               ;SUBTRACT OFF 1ST 640K MEMORY
;BEGIN TEST
MA1:
                MOV     CS:PAGE_UNDER_TEST,DX   ;INDICATE WHICH 64K BLOCK
                PUSH    AX                      ;IS UNDER TEST
                PUSH    BX
                PUSH    CX
                PUSH    DX                      ;SAVE ALL REGISTERS
;
                MOV     CX,16                   ;TEST 64K AT ONE TIME
                                                ;16 x 4K = 64K
                CALL    SETXLAT                 ;SET UP XLAT TABLE
                CALL    STGTST                  ;TEST 64K OF STORAGE
                JNZ     MA2                     ;WAS THERE AN ERROR
                POP     DX
                POP     CX
                POP     BX
                POP     AX                      ;RESTORE REGISTERS
;
                PUSHF                           ;SAVE FLAGS FOR ADDITION

                CALL    KB_OK                   ;INDICATE HOW MUCH
                                                ;MEMORY HAS BEEN TESTED


                ADD     DX,16                   ;POINT TO NEXT 64K BLOCK
                POPF                            ;RESTORE FLAGS
                LOOP    MA1                     ;LOOP FOR NEXT 64K
                JMP     MA3                     ;EXIT WHEN COMPLETE
MA2:
                POP     DX
                POP     CX
                POP     BX                      ;BX IS POPPED TWICE
                POP     BX                      ;TO RESTORE STACK WHILE
                                                ;MAINTAINING AX
MA3:
                PUSH    AX
                PUSH    DX
                PUSHF                           ;SAVE THESE REGS...THEY CONTAIN
                                                ;USEFULL ERROR INFO
;PUT THE SMAS CARD INTO REAL MODE
                MOV     DX,MODE_REG             ;READY FOR I/O TO MODE REG
                IN      AL,DX                   ;READ IT
                AND     AL,REAL_MODE            ;TURN OFF VIRTUAL BIT
                OUT     DX,AL                   ;WRITE IT TO MODE REG
                POPF
                POP     DX
                POP     AX                      ;RESTORE THESE REGS
                RET
;
MEMARRAY        ENDP




PAGE
;---------------------------------------------------------------------
;---------------------------------------------------------------------
;                       LO MEMORY TEST
;
;   DESCRIPTION     :   This routine tests the first 256K or 512K
;                       of XMA memory depending on the starting
;                       position of the starting address jumper on
;                       the card.  The memory that is used to
;                       fill conventional memory space is not tested
;                       it is tested during POST and may now contain
;                       parts of COMMAND.COM.
;
;   FUNCTION/       :   See description
;   PURPOSE
;
;   ENTRY POINT     :   LOMEMTST
;
;   ENTRY           :
;   CONDITIONS
;
;   EXIT            :   All tested memory is set to zero
;
;                       (zero flag) = 0 if storage error
;                       (AX) = expected data XOR'ed with actual data
;                               if (AX)=0 and ZF=0 then parity error
;                       DS:SI point to failing location
;                       CS:PAGE_UNDER_TEST point to failing 64K block
;
;                       AX,BX,CX,DX,DI,SI,ES,DS ARE DESTROYED
;
;-----------------------------------------------------------------------
LOMEMTST        PROC

                MOV     AL,LOMEM_TEST
                MOV     CS:TEST_ID,AL

;MEMORY TEST MUST RUN IN PAGE MODE
                CALL    VIRT2REAL

;INDICATE 0 KB OK AT START OF TEST
                MOV     DX,0FFF0H                       ;code for initial 0 kb
                CALL    KB_OK

;DETERMINE HOW MUCH MEMORY TO TEST
                MOV     AX,CS:START_FILL                ;get starting fill segment
                XCHG    AH,AL
                MOV     CL,4
                SHR     AX,CL                           ;convert to 64k block number
                MOV     CS:TESTABLE_SEGMENTS,AX         ;save...this is number of 64k blocks
                                                        ;that can be tested without
                                                        ;destroying DOS
;SET UP FOR TEST OF XMA MEMORY
                MOV     AX,CS:PAGE_FRAME_STA            ;test through page frame
                MOV     DS,AX                           ;set up ds
                MOV     ES,AX                           ;and es
                MOV     BL,01H                          ;enable this block of memory
                MOV     BH,0                            ;using id=0
                XOR     DX,DX                           ;start at block 0 in xma
                MOV     CX,640/64                       ;loop counter is # 64k blocks in
                                                        ;conventional memory
LM1:
                MOV     CS:PAGE_UNDER_TEST,DX           ;save page under test
                PUSH    AX
                PUSH    BX
                PUSH    CX
                PUSH    DX                              ;save these registers

                MOV     CX,16                           ;test 64k at one time
                                                        ;16 * 4k = 64k
                CALL    SETXLAT                         ;set translate table
                CMP     CS:TESTABLE_SEGMENTS,0          ;if this segment under test is used for
                                                        ;fill then read only
                JG      LM2                             ;else do storage test
                CALL    READ_ONLY
                JMP     LM3
LM2:
                CALL    STGTST
LM3:
                JNZ     LM4                             ;jump if there was an error
                POP     DX
                POP     CX
                POP     BX
                POP     AX                              ;recover registers

                PUSHF                                   ;save flags for addition
                CALL    KB_OK
                                                        ;indicate kb ok
                ADD     DX,16                           ;next 64k block
                DEC     CS:TESTABLE_SEGMENTS            ;dec testable pages
                POPF                                    ;recover flags
                LOOP    LM1                             ;repeat for next 64k block
                JMP     LM5                             ;exit when complete
LM4:
                POP     DX                              ;recover these registers
                POP     CX
                POP     BX                              ;bx is popped twice to restore
                POP     BX                              ;satck while maintaining ax
LM5:
                PUSH    AX                              ;save these ... they contain
                PUSH    DX                              ;useful error information
                PUSHF
;PUT CARD BACK TO REAL MODE
                MOV     DX,MODE_REG                     ;read mode reg
                IN      AL,DX
                AND     AL,REAL_MODE                    ;turn off virtual bit
                OUT     DX,AL                           ;write it to mode reg
                POPF
                POP     DX
                POP     AX                              ;restore these registers
                RET


READ_ONLY       PROC            ;INTERNAL PROC TO READ MEMORY WITHOUT DESTROYING CONTENTS
                XOR     SI,SI                           ;start of segment
                XOR     CX,CX                           ;test 64k

                LODSW                                   ;just read each byte
                XOR     AX,AX                           ;and set zf=1 for return
                RET                                     ;back to caller
READ_ONLY       ENDP

LOMEMTST        ENDP



PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       PAGE TEST
;
; DESCRIPTION   :  This routine tests that the TASK ID register is
;                  actually paging in unique segments of memory.
;                  The test is performed through the page frame segment.
;                  The test assumes that the memory test has already
;                  completed successfully. The page test procedes as
;                  follows:
;                     (i) 6-64K blocks of XMA memory are mapped into a
;                         64K segment of PC space (the page frame)
;                         These XMA blocks are from 640k to 1024k of XMA memory.
;                    (ii) Each of these blocks is assigned to a unique
;                         task ID ranging from 0 to 5.
;                   (iii) For each task ID, the page frame is filled with
;                         a pattern that is the same as the task ID.
;                    (iv) The page frame is then read for each task ID
;                         and compared with the expected data.
;
; FUNCTION/     :
; PURPOSE
;
; ENTRY POINT   :  PAGETST
;
; ENTRY         :  NONE
; CONDITIONS
;
; EXIT          :  (zero flag) = 0 indicates an error
;                  (AL) expected data XOR'ed with actual data
;
;                  AX,BX,CX,DX,ES,DS,SI,DI ARE DESTROYED
;-------------------------------------------------------------------------
;
PAGETST         PROC
;
                MOV     AL,PAGE_TEST
                MOV     CS:TEST_ID,AL
;MEMORY TEST MUST RUN IN PAGE MODE
                CALL    VIRT2REAL
;INITIALIZE TRANSLATE TABLE FOR THIS TEST
                MOV     AX,CS:PAGE_FRAME_STA    ;SEMENT OF PAGE FRAME
                MOV     BL,01H                  ;ENABLE CODE
                MOV     BH,0                    ;START WITH TASK ID = 0
                MOV     DX,640/4                ;START WITH XMA BLOCK 160
                MOV     CX,6                    ;LOOP COUNT...6 TASK ID's
                                                ;EACH TASK ID IS ASSIGNED 64K
                                                ;FROM 640K TO 1024K
PT1:
                PUSH    AX
                PUSH    BX
                PUSH    CX
                PUSH    DX                      ;SAVE ALL REGISTERS
;
                MOV     CX,16                   ;16-4K BLOCKS IN 64K
                CALL    SETXLAT                 ;SET TRANSLATE TABLE
                POP     DX
                POP     CX
                POP     BX
                POP     AX                      ;RECOVER ALL
                INC     BH                      ;POINT TO NEXT TASK ID
                ADD     DX,16                   ;NEXT 64K IN XMA MEMORY
                LOOP    PT1                     ;REPEAT FOR ALL TASK ID's
;FILL MEMORY WITH A UNIQUE PATTERN FOR EACH TASK ID
                MOV     CX,6                    ;6 TASK ID's
                MOV     DX,IDREG                ;READY FOR I/O TO TASK ID REG
                MOV     AL,0                    ;START WITH ID = 0
PT2:
                PUSH    AX                      ;SAVE ID NUMBER
                PUSH    CX                      ;SAVE ID COUNT
                OUT     DX,AL                   ;SWITCH TASK ID
                MOV     BX,CS:PAGE_FRAME_STA
                MOV     ES,BX                   ;SEGMENT TO 1ST 64K 0F ID
                SUB     DI,DI                   ;POINT TO 1ST LOCATION
                XOR     CX,CX                   ;WRITE ALL 64K LOCATIONS
PT2X:
                STOSB
                LOOP    PT2X
                POP     CX                      ;RECOVER ID COUNT
                POP     AX                      ;RECOVER CURRENT ID
                INC     AL
                LOOP    PT2                     ;REPEAT FOR ALL TASK ID's
;NOW CHECK THAT THERE ARE 16 UNIQUE PATTERNS IN MEMORY
                MOV     CX,6                    ;USE 6 TASK ID's
                MOV     AH,0                    ;START WITH ID = 0
PT3:
                MOV     AL,AH                   ;GET TASK ID IN AL
                PUSH    AX
                PUSH    CX                      ;SAVE ID COUNT
                OUT     DX,AL                   ;SWITCH TASK ID
                MOV     BX,CS:PAGE_FRAME_STA
                MOV     DS,BX
                MOV     ES,BX                   ;SEGMENT AT 1ST 64K
                SUB     DI,DI                   ;POINT TO 1ST LOCATION
                SUB     SI,SI                   ;POINT TO 1ST LOCATION
                XOR     CX,CX                   ;READ ALL 64K LOCATIONS
PT3X:
                LODSB
                XOR     AL,AH                   ;DATA AS EXPECTED ?
                JNE     PT4X                    ;NO - THEN EXIT
                STOSB                           ;AL SHOULD CONTAIN 0...WRITE IT
                LOOP    PT3X

                POP     CX                      ;RECOVER ID COUNT
                POP     AX
                INC     AH                      ;NEXT TASK ID
                LOOP    PT3                     ;REPEAT FOR ALL TASK ID's
                XOR     AL,AL                   ;IF WE GOT THIS FAR THEN
                                                ;NO ERRORS...SET ZF TO
                                                ;INDICATE SUCCESS
PT4:
                PUSH    AX
                PUSH    DX
                PUSHF                           ;SAVE THESE REGS...THEY CONTAIN
                                                ;USEFULL ERROR INFO
;PUT THE SMAS CARD INTO REAL MODE
                MOV     DX,MODE_REG             ;READY FOR I/O TO MODE REG
                IN      AL,DX                   ;READ IT
                AND     AL,REAL_MODE            ;TURN OFF VIRTUAL BIT
                OUT     DX,AL                   ;WRITE IT TO MODE REG
;MAKE SURE WE EXIT WHILE IN TASK ID=0
                MOV     DX,IDREG
                XOR     AL,AL
                OUT     DX,AL

                POPF
                POP     DX
                POP     AX                      ;RESTORE THESE REGS
                RET                             ;RETURN TO CALLER
PT4X:
                POP     CX                      ;ALTERNATE RETURN PATH
                POP     AX
                JMP     PT4                     ;TO ADJUST STACK
;
PAGETST         ENDP


PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       DMA CAPTURE TEST
;
; DESCRIPTION   :  This routine is a test of the DMA capture logic.
;                  The test is as follows:
;                     (i) A bit is rolled through the second entry in the
;                         DMA cature register file. (The first entry is used
;                         for refresh on a PC-XT).
;                    (ii) A bit and address test is performed on the
;                         remainder of the register file(s).
;                   (iii) A test is made for the capture of both REQUEST and
;                         MODE registers of the DMA controller.
;                    (iv) DMA channel 0 is tested only on the PC-AT
;
;
; FUNCTION/     :  To verify the functionality of the DMA capture logic.
; PURPOSE
;
; ENTRY POINT   :  CAPTST
;
; ENTRY         :  NONE
; CONDITIONS
;
; EXIT          :  Each entry in the DMA capture register file is set to 0.
;
;                  (zero flag) = 0 indicates an error
;                  '31A8'X points to failing DMA capture reg
;                  (AL) expected data XOR'ed with actual data
;
;                  AX,BX,CX,DX,SI,DI ARE DESTROYED
;-------------------------------------------------------------------------
;
;
CAPTST          PROC
;
                MOV     AL,DMA_CAPTURE
                MOV     CS:TEST_ID,AL
;
;ROLL A BIT THROUGH THE SECOND ENTRY IN THE DMA CAPTURE REGISTER FILE
;
                MOV     BL,01H          ;SET UP INITIAL PATTERN
                MOV     BH,01H          ;SET UP DMA CHANNEL 1
                MOV     DI,DMACAPT      ;SAVE FOR I/O TO DMA CAPTURE REG
                MOV     SI,DMAREQ1      ;SAVE FOR I/O TO DMA CTRL 1 REQ REG
                MOV     CX,4            ;ROLL 4 BIT POSITIONS
C1:
                MOV     DX,IDREG        ;I/O TO ID REG
                MOV     AL,BL           ;PATTERN TO WRITE
                OUT     DX,AX           ;SETUP ID REG WITH DATA PATTERN
                MOV     DX,SI           ;DMA CTRL 1
                MOV     AL,BH           ;CHANNEL 1
                OUT     DX,AL           ;SETUP DMA CH 1...CAPT ID IN 2nd ENTRY
                MOV     DX,DI           ;DMA CAPTURE REG
                OUT     DX,AL           ;POINT TO 2nd ENTRY
                IN      AL,DX           ;READ IT
                XOR     AL,BL           ;DATA READ AS EXPECTED ?
                JNE     CAPT_ERROR      ;NO - THEN ERROR
                SHL     BL,1            ;SHIFT BIT TO NEXT POSITION
                LOOP    C1              ;REPEAT
;
                MOV     DI,DMAREQ2      ;SETUP FOR I/O TO DMA CTRL 2 REQ REG
                MOV     AL,05H          ;DATA PATTERN TO CAPTURE
                CALL    CAPT_FILL       ;FILL CAPTURE REGS WITH VALUE
;
                MOV     AH,05H          ;SETUP INITIAL PATTERN
                MOV     BX,0F0AH        ;OTHER PATTERNS TO USE
C2:
                CALL    CAPT_RMW
                JNZ     CAPT_ERROR      ;ERROR - THEN EXIT
                CMP     AH,BL           ;ZERO PATTERN ?
                JE      CAPT_EXIT       ;EXIT IF YES
                MOV     AH,BL           ;SET UP
                MOV     BL,BH           ;   NEXT
                MOV     BH,0            ;     PATTERN
                JMP     C2              ;REPEAT

;NOW REPEAT TEST FOR CATPURE OF DMA MODE REGISTERS
                MOV     SI,DMAMODE1     ;SETUP FOR I/O TO DMA CTRL 1 MODE REG
                MOV     DI,DMAMODE2     ;SETUP FOR I/O TO DMA CTRL 2 MODE REG
                MOV     AL,05H          ;DATA PATTERN TO CAPTURE
                CALL    CAPT_FILL       ;FILL CAPTURE REGS WITH VALUE
;
                MOV     AH,05H          ;SETUP INITIAL PATTERN
                MOV     BX,0F0AH        ;OTHER PATTERNS TO USE
C3:
                CALL    CAPT_RMW
                JNZ     CAPT_ERROR      ;ERROR - THEN EXIT
                CMP     AH,BL           ;ZERO PATTERN ?
                JE      CAPT_EXIT       ;EXIT IF YES
                MOV     AH,BL           ;SET UP
                MOV     BL,BH           ;   NEXT
                MOV     BH,0            ;     PATTERN
                JMP     C3              ;REPEAT
CAPT_ERROR:
CAPT_EXIT:
                RET

CAPTST          ENDP



PAGE

;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       FILL DMA CAPTURE REG
;
; DESCRIPTION   :  This routine will fill the entire DMA capture register
;                  file with the pattern that is passed in AL
;
; FUNCTION/     :  See Description.
; PURPOSE
;
; ENTRY POINT   :  CAPT_FILL
;
; ENTRY         :  AL contains the value to be captured into
; CONDITIONS          the register file.
;                  SI contains the address of DMA controller 1
;                  DI contains the address of DMA controller 2
;
; EXIT          :  Each entry in the DMA capture register file is set to
;                  the value specified in AL.
;-------------------------------------------------------------------------
;
CAPT_FILL       PROC    NEAR
;
                MOV     DX,IDREG
                OUT     DX,AL           ;LOAD ID REG WITH PAT TO BE CAPTURED
                MOV     DX,DI           ;GET ADDRESS OF CTRL 2
                MOV     CX,3            ;REP FOR CHANNELS 7,6,5
CF1:
                MOV     AL,CL           ;CL CONTAINS WHICH DMA CHANNEL
                OUT     DX,AL           ;SETUP & CAPTURE DMA CHANNEL
                LOOP    CF1             ;REPEAT
;
                MOV     DX,SI           ;GET ADDRESS OF CTRL 1
                MOV     CX,3            ;REP FOR CHANNELS 3,2,1
CF2:
                MOV     AL,CL           ;CL CONTAINS WHICH DMA CHANNEL
                OUT     DX,AL           ;SETUP & CAPTURE DMA CHANNEL
                LOOP    CF2             ;REPEAT
        ;DO CHANNEL 0 IF NOT MODEL PC1, XT, AQUARIUS
                CMP     CS:MODEL,PC1    ;IS THIS A PC1 ?
                JE      CF3             ;YES - THEN EXIT ELSE TRY PC_XT
                CMP     CS:MODEL,PC_XT  ;IS THIS AN XT ?
                JE      CF3             ;YES - THEN EXIT ELSE TRY AQUARIUS
                CMP     CS:MODEL,XT_AQUARIUS    ;IS THIS AN AQUARIUS?
                JE      CF3             ;YES - THEN EXIT ELSE FILL CH 0 CAPT
                MOV     AL,0            ;INDICATE CHANNEL 0
                OUT     DX,AL           ;SETUP & CAPTURE DMA CHANNEL
CF3:
                RET                     ;RETURN TO CALLER
;
CAPT_FILL       ENDP




PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       READ-MODIFY-WRITE DMA CAPTURE REG
;
; DESCRIPTION   :  This routine will read the a DMA capture register
;                  and if the correct value is found will cause a capture
;                  of a new value. The next DMA capture reg is read and
;                  the process repeated.
;
; FUNCTION/     :  See Description.
; PURPOSE
;
; ENTRY POINT   :  CAPT_RMW
;
; ENTRY         :  AH contains the value to be compared
; CONDITIONS       BL contains the new value to be written
;                  SI contains the address of DMA controller 1
;                  DI contains the address of DMA controller 2
;
; EXIT          :  Each entry in the DMA capture register file is set to
;                  the value specified in BL.
;
;                  AL,CX,DX,ARE DESTROYED
;-------------------------------------------------------------------------
;
CAPT_RMW        PROC    NEAR
;
                MOV     CX,3            ;REP FOR CHANNELS 7,6,5
RMW1:
                MOV     DX,DMACAPT      ;I/O ADDRESS OF DMA CAPTURE REG
                MOV     AL,CL           ;GET LOW BYTE OF COUNT
                ADD     AL,4            ;ADD 4 TO POINT TO DMA CAPTURE
                CALL    RMW
                JNZ     RMW4            ;EXIT IF ERROR
                LOOP    RMW1            ;REPEAT FOR CHANNEL 6,5
;
                MOV     CX,3            ;REP FOR CHANNELS 3,2,1
                PUSH    DI              ;SAVE DMA CTRL 2
                MOV     DI,SI           ;GET DMA CTRL 1 INTO DI FOR PROC RMW
RMW2:
                MOV     DX,DMACAPT      ;I/O ADDRESS OF DMA CAPTURE REG
                MOV     AL,CL           ;GET LOW BYTE OF COUNT
                CALL    RMW
                JNZ     RMW3            ;EXIT IF ERROR
                LOOP    RMW2            ;REPEAT FOR DMA CHANNELS 2,1
        ;DO CHANNEL 0 IF NOT MODEL PC1, XT, AQUARIUS
                CMP     CS:MODEL,PC1    ;IS THIS A PC1 ?
                JE      RMW3            ;YES - THEN EXIT ELSE TEST FOR PC_XT
                CMP     CS:MODEL,PC_XT  ;IS THIS AN XT ?
                JE      RMW3            ;YES - THEN EXIT ELSE TEST FOR AQUARIUS
                CMP     CS:MODEL,XT_AQUARIUS    ;IS THIS AN AQUARIUS?
                JE      RMW3            ;YES - THEN EXIT ELSE TEST CH 0
                MOV     DX,DMACAPT      ;I/O ADDRESS OF DMA CAPTURE REG
                MOV     CL,0            ;INDICATE CHANNEL 0
                MOV     AL,CL           ;ALSO INTO AL
                CALL    RMW
RMW3:
                POP     DI              ;RESTORE DI (ADDR OF DMA CTRL 2)
RMW4:
                RET                     ;RETURN TO CALLER
;
CAPT_RMW        ENDP
;
RMW             PROC
;
                OUT     DX,AL           ;SETUP TO READ FROM DMA CAPTURE REG
                IN      AL,DX           ;READ IT
                XOR     AL,AH           ;DATA AS EXPECTED ?
                JNE     RMW5            ;NO THEN EXIT
     ;DATA WAS GOOD---NOW GET NEXT PATTERN INTO THIS CAPTURE REG
                MOV     DX,IDREG        ;ADDRESS OF ID REG
                MOV     AL,BL           ;NEW PATTERN TO WRITE
                OUT     DX,AL           ;WRITE IT TO ID REG
                MOV     DX,DI           ;ADDRESS OF DMA CTRL 2
                MOV     AL,CL           ;DMA CHANNEL TO SET UP
                OUT     DX,AL           ;SET UP DMA---THIS CAUSES CAPTURE OF ID
RMW5:
                RET                     ;RETURN TO CALLER
;
RMW             ENDP




PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       INHIBIT A BLOCK OF MEMORY
;
; DESCRIPTION   :  This routine will set a block of SMAS memory with
;                  the code to enable or inhibit it. The user simply
;                  specifies the starting segment and length of the block in
;                  PC 'real' address space that is to be enabled/inhibited.
;                  The appropriate entries in the Translate Table are
;                  written so that this specified block in 'real' address
;                  is enabled or protected in all 16 possible TASK ID's.
;
;
; FUNCTION/     :  To enable or inhibit SMAS memory in specified areas of
; PURPOSE          PC 'real'address space (ie.,diplay buffer, BIOS,
;                  distributed ROS...)
;
; ENTRY POINT   :  INHIBLK
;
; ENTRY         :  (AX) starting segment in PC address space to be
; CONDITIONS            protected/enabled. Must be on 4K boundary else
;                       this routine will round UP to next 4K block.
;
;                  (CX) number of 4K blocks to be protected
;
;                  (BL) 01 = ENABLE
;                       00 = INHIBIT
;
; EXIT          :  specified entries in Translate Table are enabled or
;                  inhibited for all posible task ID's.
;
;                  AX,BH,CX,DX ARE DESTROYED
;-------------------------------------------------------------------------
;
INHIBLK         PROC
;
        ;ADJUST SI FOR TRANSLATE TABLE ENTRY
                XCHG    AL,AH           ;ROTATE RIGHT BY 8
                XOR     AH,AH           ;CLEAR AH
                                        ;AX IS NOW ADJUSTED FOR ENTRY INTO
                                        ;XLAT TABLE FOR TASK ID=0
                PUSH    AX              ;SAVE IT
                PUSH    CX              ;SAVE COUNT OF 4K BLOCKS
;
                MOV     SI,TTDATA       ;ADDRESS OF TT DATA REG
                MOV     DI,AIDATA       ;ADDRESS OF TT DATA WITH AUTO INC
                XOR     BH,BH           ;BH IS TASK ID
INH1:
                MOV     DX,TTPOINTER    ;ADDRESS OF TT POINTER
                POP     CX              ;RESTORE COUNT
                POP     AX              ;RESTORE TT ENTRY
                PUSH    AX              ;SAVE BOTH
                PUSH    CX              ;   OF THEM
                MOV     AH,BH           ;APPEND TASK ID TO TT POINTER
                OUT     DX,AX           ;SET TT POINTER TO STARTING ENTRY
INH2:
                MOV     DX,SI           ;TT DATA REG
                IN      AX,DX           ;READ CURRENT ENTRY
                MOV     DX,DI           ;ADDRESS OF TT DATA WITH AUTO INC
        ;DETERMINE IF ENABLE OR INHIBIT BLOCK
                CMP     BL,ENABLE       ;WANT TO ENABLE THIS BLOCK ?
                JNE     INH3            ;NO - THEN DISABLE IT
                AND     AH,BLK_ON       ;MASK OFF INHIBIT BIT
                JMP     INH4
INH3:
                OR      AH,BLK_OFF      ;MASK ON INHIBIT BIT
INH4:
                OUT     DX,AX           ;WRITE IT THEN INC TO NEXT TT ENTRY
                LOOP    INH2            ;REPEAT FOR EACH BLOCK OF 4K
                INC     BH              ;NEXT TASK ID
                CMP     BH,MAX_TASK_ID  ;COMPLETED FOR ALL TASK ID's ?
                JBE     INH1            ;NO - THEN LOOP TILL DONE
INHIBLK_EXIT:
                POP     CX
                POP     AX
                RET
;
INHIBLK         ENDP




PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       STORAGE TEST
;
; DESCRIPTION   :  This routine performs a bit and address test on a
;                  64K block of storage.
;
;                  (i) 55AA is written to each location.
;                 (ii) 55AA is read back
;                (iii) if good, write AA55 and point to next location
;                 (iv) repeat step (iii) for all 64K locations
;                  (v) repeat steps (ii) to (iv) for AA55, FF00, 0101, 0000
;                 (vi) check parity bits
;
;
; FUNCTION/     :  See description
; PURPOSE
;
; ENTRY POINT   :  STGTST
;
; ENTRY         :  (ES) storage segment to be tested
; CONDITIONS       (DS) storage segment to be tested
;
; EXIT          :  (zero flag) = 0 if storage error
;                  (AX) expected data XOR'ed with actual data
;                       if ax = 0 and zf = 0 then parity error
;                  DS:SI point to failing location
;
;                  AX,BX,CX,DX,DI,SI ARE DESTROYED
;
;-------------------------------------------------------------------------
;
STGTST          PROC
;
                CMP     CS:WARM_START,'Y'               ;is this a warm start?
                JNE     STG1A                           ;if no then do mem test
                CALL    CLEAR_MEM                       ;if yes then just clear memory
                XOR     AX,AX                           ;set zero flag
                JMP     STG6                            ;exit


        ;DISABLE NMI AND ENABLE I/O CHANNEL CHECK
STG1A:
                MOV     AL,CS:MODEL             ;GET SAVED MODEL BYTE
                CMP     AL,PC1                  ;IS IT A PC1?
                JE      STG1                    ;IF NO THEN TRY FOR PC_XT
                CMP     AL,PC_XT                ;IS IT AN XT?
                JE      STG1                    ;IF NO THEN TRY FOR AQUARIUS
                CMP     AL,XT_AQUARIUS          ;IS IT AN AQUARIUS?
                JE      STG1                    ;IF NO THEN USE AT NMI REGS
        ;USE PC-AT NMI REGISTER
                MOV     DX,AT_NMI_REG           ;AT's NMI REGISTER
                MOV     AL,AT_NMI_OFF           ;MASK OFF NMI
                OUT     DX,AL                   ;OUTPUT IT
                MOV     DX,AT_CHCHK_EN_REG      ;AT's I/O CH CHK REG
                IN      AL,DX                   ;READ IT
                OR      AL,AT_CHCHK_DIS         ;MASK OFF I/O CH CHK ENABLE
                OUT     DX,AL                   ;WRITE IT
                AND     AL,AT_CHCHK_EN          ;MASK ON I/O CH CHK ENABLE
                OUT     DX,AL                   ;TOGGLE CH CHK LTCH AND LEAVE
                                                ;ENABLED
        ;USE PC1, XT, AQUARIUS REGISTERS
STG1:
                MOV     DX,XT_NMI_REG           ;XT's NMI REGISTER
                MOV     AL,XT_NMI_OFF           ;MASK OFF NMI
                OUT     DX,AL                   ;OUTPUT IT
                MOV     DX,XT_CHCHK_EN_REG      ;XT's I/O CH CHK REG
                IN      AL,DX                   ;READ IT
                OR      AL,XT_CHCHK_DIS         ;MASK OFF I/O CH CHK ENABLE
                OUT     DX,AL                   ;WRITE IT
                AND     AL,XT_CHCHK_EN          ;MASK ON I/O CH CHK ENABLE
                OUT     DX,AL                   ;TOGGLE CH CHK LTCH AND LEAVE
                                                ;ENABLED



        ;ROLL A BIT THROUGH THE FIRST WORD
                SUB     DI,DI                   ;FIRST LOCATION
                MOV     CX,16                   ;ROLL 16 BITS
                MOV     AX,0001H                ;FIRST PATTERN TO WRITE
                MOV     BX,AX                   ;SAVE IT
STG2:
                MOV     [DI],AX                 ;WRITE PATTERN
                MOV     [DI+2],0FFFFH           ;CHARGE BUS
                MOV     AX,[DI]                 ;READ PATTERN
                XOR     AX,BX                   ;IS IT CORRECT ?
                JNE     STG_EXIT                ;IF NO - THEN EXIT
                SHL     BX,1                    ;SHIFT BIT
                MOV     AX,BX                   ;GET IT INTO AX
                LOOP    STG2                    ;REPEAT
;
                CLD                             ;FILL FORWARD
                SUB     DI,DI                   ;POINT TO FIRST LOCATION
                MOV     CX,8000H                ;32K WORDS
                MOV     AX,55AAH                ;INITIAL PATTERN TO WRITE
                REP     STOSW                   ;FILL ENTIRE SEGMENT
;
                MOV     BX,55AAH                ;PATTERN TO LOOK FOR
                MOV     DX,0AA55H               ;NEXT PATTERN TO WRITE
                CALL    STG_CNT
                JNZ     STG_EXIT                ;EXIT IF ERROR
;
                MOV     BX,0AA55H               ;PATTERN TO LOOK FOR
                MOV     DX,0101H                ;NEXT PATTERN TO WRITE
                CALL    STG_CNT
                JNZ     STG_EXIT                ;EXIT IF ERROR
;
                MOV     BX,0101H                ;PATTERN TO LOOK FOR
                MOV     DX,0000H                ;NEXT PATTERN TO WRITE
                CALL    STG_CNT
                JNZ     STG_EXIT                ;EXIT IF ERROR
;
;               MOV     BX,0000H                ;PATTERN TO LOOK FOR
;               MOV     DX,0000H                ;NEXT PATTERN TO WRITE
;               CALL    STG_CNT
;               JNZ     STG_EXIT                ;EXIT IF ERROR
;
        ;IF TEST REACHES THIS POINT THEN MEMORY IS GOOD
        ;NEED TO CHECK PARITY BITS...IF PARITY ERROR EXISTS THEN
        ;CAN ASSUME BAD PARITY BIT OR BAD PARITY GENERATOR
;
                MOV     AL,CS:MODEL             ;GET SAVED MODEL BYTE
                CMP     AL,PC1                  ;IS IT A PC1?
                JE      STG3                    ;USE XT REGISTERS
                CMP     AL,PC_XT                ;IS IT AN XT?
                JE      STG3                    ;USE XT REGISTERS
                CMP     AL,XT_AQUARIUS          ;IS IT AN AQUARIUS?
                JE      STG3                    ;USE XT REGISTERS
        ;IF NONE OF THE ABOVE THEN...
        ;USE AT NMI REGISTER
                MOV     DX,AT_CHCHK_REG         ;AT's I/O CH CHK REG
                IN      AL,DX                   ;READ IT
                AND     AL,AT_CHCHK             ;IS CH CHK BIT ON ?
                JZ      STG4                    ;IF NO - THEN EXIT
                MOV     AX,0                    ;ELSE - CLEAR AX TO INDICATE
                                                ;PARITY ERROR
                JMP     STG4                    ;EXIT
        ;USE XT/AQUARIUS NMI REGISTER
STG3:
                MOV     DX,XT_CHCHK_REG         ;XT's I/O CH CHK REG
                IN      AL,DX                   ;READ IT
                AND     AL,XT_CHCHK             ;IS CH CHK BIT ON ?
                JZ      STG4                    ;IF NO - THEN EXIT
                MOV     AX,0                    ;ELSE - CLEAR AX TO INDICATE
                                                ;PARITY ERROR
STG4:
STG_EXIT:
                PUSH    AX                      ;SAVE THESE REGS
                PUSH    DX                      ;THEY CONTAIN
                PUSH    SI
                PUSHF                           ;USEFUL ERROR INFORMATION
        ;BEFORE NMI IS ENABLED, CLEAR PARITY CHECK LATCH ON XMA
                MOV     SI,0
                MOV     AX,[SI]                 ;READ 1ST WORD OF THIS SEG
                MOV     [SI],AX                 ;WRITE BACK SAME WORD
                                                ;THE WRITE WILL CLEAR PCHK LTCH
        ;CLEAR I/O CHANNEL CHECK LATCHES AND ENABLE NMI
                MOV     AL,CS:MODEL             ;GET SAVED MODEL BYTE
                CMP     AL,PC1                  ;IS IT A PC1?
                JE      STG5                    ;USE XT REGISTERS
                CMP     AL,PC_XT                ;IS IT AN XT?
                JE      STG5                    ;USE XT REGISTERS
                CMP     AL,XT_AQUARIUS          ;IS IT AN AQUARIUS?
                JE      STG5                    ;USE XT REGISTERS
        ;IF NONE OF THE ABOVE THEN...
        ;USE AT NMI REGISTER
                MOV     DX,AT_CHCHK_EN_REG      ;AT's I/O CH CHK REG
                IN      AL,DX                   ;READ IT
                OR      AL,AT_CHCHK_DIS         ;MASK OFF I/O CH CHK ENABLE
                OUT     DX,AL                   ;WRITE IT
                AND     AL,AT_CHCHK_EN          ;MASK ON I/O CH CHK ENABLE
                OUT     DX,AL                   ;TOGGLE CH CHK LTCH AND LEAVE
                                                ;ENABLED
                MOV     DX,AT_NMI_REG           ;AT's NMI REGISTER
                MOV     AL,AT_NMI_ON            ;MASK ON NMI
                OUT     DX,AL                   ;OUTPUT IT
        ;USE XT/AQUARIUS NMI REGISTER
STG5:
                MOV     DX,XT_CHCHK_EN_REG      ;XT's I/O CH CHK REG
                IN      AL,DX                   ;READ IT
                OR      AL,XT_CHCHK_DIS         ;MASK OFF I/O CH CHK ENABLE
                OUT     DX,AL                   ;WRITE IT
                AND     AL,XT_CHCHK_EN          ;MASK ON I/O CH CHK ENABLE
                OUT     DX,AL                   ;TOGGLE CH CHK LTCH AND LEAVE
                                                ;ENABLED
                MOV     DX,XT_NMI_REG           ;XT's NMI REGISTER
                MOV     AL,XT_NMI_ON            ;MASK ON NMI
                OUT     DX,AL                   ;OUTPUT IT
;
                POPF
                POP     SI
                POP     DX
                POP     AX                      ;RESTORE REGS
STG6:
                RET                             ;RETURN TO CALLER



CLEAR_MEM       PROC            ;INTERNAL PROC TO CLEAR MEMORY
                XOR     DI,DI                           ;start of segment
                XOR     CX,CX                           ;clear entire segment
                XOR     AX,AX                           ;write zeroes

                STOSB                                   ;just write
                RET                                     ;back to caller
CLEAR_MEM       ENDP


STGTST          ENDP


PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       STORAGE TEST SUBROUTINE
;
; DESCRIPTION   :  This routine performs a bit and address test on a
;                  64K block of storage.
;
;                  (i) a word is read and compared against the value in (BX)
;                 (ii) if good the value in (DX) is written into that location
;                (iii) point to next location and repeat steps (i) to (ii)
;
;
; FUNCTION/     :  See description
; PURPOSE
;
; ENTRY POINT   :  STG_CNT
;
; ENTRY         :  (ES) storage segment to be tested
; CONDITIONS       (DS) storage segment to be tested
;                  (BX) value to be compared
;                  (DX) new value to be written
;
; EXIT          :  (zero flag) = 0 if storage error
;                  (AX) expected data XOR'ed with actual data
;                       if ax = 0 and zf = 0 then parity error
;                  DS:SI point to failing location
;-------------------------------------------------------------------------
;
STG_CNT         PROC
;
                MOV     CX,8000H                ;32K WORDS
                SUB     DI,DI                   ;FIRST LOCATION
                MOV     SI,DI                   ;FIRST LOCATION
SC1:
                LODSW                           ;READ OLD WORD FROM STORAGE
                XOR     AX,BX                   ;DATA AS EXPECTED ?
                JNE     SC2                     ;IF NO - THEN EXIT
                MOV     AX,DX                   ;GET NEW PATTERN
                STOSW                           ;WRITE IT
                LOOP    SC1                     ;REPEAT
SC2:
                RET

STG_CNT         ENDP




PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       PRINT MEMORY GOOD
;
; DESCRIPTION   :  This routine will print to the screen how much memory
;                  has been tested.
;
;                  The format will be: xxxx KB TESTED
;
; FUNCTION/     :  See description
; PURPOSE
;
;
; ENTRY POINT   :  KB_OK
;
; ENTRY         :  (DX) = 1/4 OF GOOD MEMORY + 64K IN KB
; CONDITIONS              ex:  if (DX) = 16 then
;                              (16 * 4) + 64 = 128KB is OK
;
;                   NOTE: if (DX) = FFF0 then 0 KB is OK
;
;
; EXIT          :  Message is displayed
;
;                  All registers are preserved
;
;-------------------------------------------------------------------------
;
KB_OK           PROC
;
                PUSH    AX
                PUSH    BX
                PUSH    CX
                PUSH    DX
                PUSH    SI
                PUSH    DI
                PUSH    DS                      ;SAVE REGISTERS
;
                PUSH    CS
                POP     DS                      ;GET DS TO THIS CODE SEGMENT
        ;CONVERT DX TO KILO BYTES
                SHL     DX,1
                SHL     DX,1            ;MULTIPLY BY 4
                ADD     DX,64           ;ADJUST BY 64
;
                MOV     AX,DX           ;GET NUMBER INTO AX
                MOV     BX,10           ;READY FOR DECIMAL CONVERT
                MOV     CX,4            ;OF 4 DIGITS
K1:
                XOR     DX,DX           ;CLEAR HI WORD OF DIVIDEND
                                        ;AX IS LOW WORD OF DIVIDEND
                DIV     BX              ;DIVIDE BY 10
                OR      DL,30H          ;MAKE MODULO INTO ASCII
                PUSH    DX              ;SAVE IT
                LOOP    K1              ;REPEAT FOR ALL DIGITS
;
                XOR     SI,SI           ;CLEAR SI
                MOV     CX,4
K2:
                POP     AX              ;ASCII DIGIT GOES INTO AL
                MOV     BX,OFFSET MEM_OK
                MOV     CS:[BX+SI],AL   ;BUILD ASCII MESSAGE
                INC     SI
                LOOP    K2
        ;MOVE THE CURSOR AND PRINT MESSAGE
                MOV     DX,CUR_SAVE
                MOV     BH,ACTIVE_PAGE
                MOV     AH,2                    ;SET CURSOR
IF DOS
                INT     10H                     ;BIOS VIDEO CALL SET CURSOR
                MOV     AH,9                    ;DOS PRINT STRING
                MOV     DX,OFFSET SIZE_MSG1 + 1 ;OFFSET OF MEM_OK MSG
                INT     21H                     ;DISPLAY MESSAGE
ELSE
                INT     85H                     ;SET CURSOR POSITION

                MOV     BX,OFFSET SIZE_MSG1     ;GET OFFSET OF MEM_OK MSG
                MOV     AX,0905H                ;MAGENTA MESSAGE
                INT     82H                     ;DISPLAY MESSAGE
ENDIF

                POP     DS
                POP     DI
                POP     SI
                POP     DX
                POP     CX
                POP     BX
                POP     AX                      ;RESTORE ALL REGISTERS

                RET                             ;RETURN TO CALLER

KB_OK           ENDP


PAGE
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;                 GET MODEL BYTE
;
GETMOD          PROC
;GET COPY OF MODEL BYTE INTO THIS SEGMENT
;
                PUSH    DS              ;SAVE DS
                LDS     SI,ADDR_MODEL_BYTE
                MOV     AL,[SI]         ;GET IT INTO AL
                MOV     CS:MODEL,AL     ;SAVE IT IN THIS SEGMENT
                POP     DS              ;RESTORE DS
                RET
;
GETMOD          ENDP




PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       SET TRANSLATE TABLE
;
; DESCRIPTION   :  This routine will write the Translate Table so that
;                  a specified block of PC 'real' address will be mapped
;                  to a specified block of SMAS physycal memory.  Note that
;                  this routine will map only into CONTIGUOUS blocks of
;                  SMAS memory. PC memory is referenced by segments
;                  (must be on 4K boundaries) while SMAS memory is referenced
;                  by block number (each block is 4K).
;
;                       EXAMPLE: segment 4000 can be mapped to block 5
;                                segment 4100 can be mapped to block 6
;
; FUNCTION/     :  To map PC 'real' addresses into SMAS physical memory.
; PURPOSE
;
;
; ENTRY POINT   :  SETXLAT
;
; ENTRY         :  (AX) starting segment in PC address space to be
; CONDITIONS            mapped. Must be on 4K boundary else
;                       this routine will round UP to next 4K block.
;
;                  (CX) number of 4K blocks translated.
;
;                  (BH) task ID for this memory allocation
;
;                  (BL) 01 = ENABLE
;                       00 = INHIBIT
;
;                  (DX) starting block number in SMAS memory
;
;
; EXIT          :  specified entries in Translate Table are enabled or
;                  inhibited for all posible task ID's.
;
;
;                  AX,CX,DX ARE DESTROYED
;
;-------------------------------------------------------------------------
;
SETXLAT         PROC
;
        ;ADJUST AX FOR TRANSLATE TABLE ENTRY
                XCHG    AL,AH           ;ROTATE RIGHT BY 8
                MOV     AH,BH           ;TASK ID INTO BH
                                        ;AX IS NOW ADJUSTED FOR ENTRY INTO
                                        ;XLAT TABLE FOR TASK ID=(BH)
                PUSH    DX              ;SAVE STARTING SMAS BLOCK NUMBER
;
                MOV     DX,TTPOINTER    ;ADDRESS OF TT POINTER
                OUT     DX,AX           ;SET TT POINTER TO STARTING ENTRY
                POP     AX              ;GET STARTING BLOCK NUMBER INTO AX
;
                MOV     DX,AIDATA       ;TT DATA REG WITH AUTO INC
        ;DETERMINE IF ENABLE OR INHIBIT BLOCK
                CMP     BL,ENABLE       ;WANT TO ENABLE THIS BLOCK ?
                JE      SETX1           ;YES - THEN SKIP THE DISABLE STEP
                OR      AH,BLK_OFF      ;MASK ON INHIBIT BIT
SETX1:
                OUT     DX,AX           ;WRITE IT THEN INC TO NEXT TT ENTRY
                INC     AX              ;NEXT BLOCK OF SMAS MEMORY
                LOOP    SETX1           ;REPEAT FOR EACH BLOCK OF 4K
SETXLAT_EXIT:
                RET
;
SETXLAT         ENDP

 PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       AUTO-INCREMENT TEST
;
; DESCRIPTION   :  This routine will test the auto-increment of
;                  the Translate Table pointer. The test will procede
;                  in the following manner:
;                     (i) A basic check of the TT pointer reg is performed
;                    (ii) The TT pointer is initialized to '00'H
;                   (iii) The auto increment data reg is written
;                    (iv) The TT pointer is read and checked for increment
;                     (v) Repeat until TT pointer wraps from 'FFF'H to '000'H
;                    (vi) Repeat test for auto-increment for read of data reg
;
; FUNCTION/     :  To ensure that the Translate Table pointer can auto
; PURPOSE          increment when 31A5 is written or read.
;
; ENTRY POINT   :  INCTST
;
; ENTRY         :  NONE
; CONDITIONS
;
; EXIT          :
;                  (zero flag) = 0 indicates an error
;                  (DX) failing register (ie.,TT pointer reg)
;                  (AX) expected data XOR'ed with actual data
;-------------------------------------------------------------------------
;
;
INCTST          PROC
;
                MOV     AL,AUTO_INC
                MOV     CS:TEST_ID,AL
;
;PERFORM SIMPLE TEST OF TTPOINTER REG
;
                MOV     BX,0AA55H       ;SET UP PATTERN TO WRITE
                MOV     AX,BX
                MOV     DX,TTPOINTER    ;I/O TO TTPOINTER REG
                MOV     SI,TTDATA       ;SAVE FOR I/O TO TTDATA
                OUT     DX,AX           ;WRITE THE REGISTER
                XCHG    DX,SI           ;I/O TO TTDATA REG
                XCHG    AH,AL           ;INVERSE PATTERN
                OUT     DX,AX           ;CHARGE BUS WITH OPPOSITE PATTERN
                XCHG    DX,SI           ;I/O TO TTPOINTER REG
                IN      AX,DX           ;READ TTPOINTER REG
                XOR     AX,BX           ;READ AS EXPECTED
                AND     AX,0FFFH        ;MASK OFF HI NIBBLE (INVALID)
                JNE     INC_ERROR       ;NO - THEN EXIT
;
;CONTINUE WITH AUTO-INC TEST
;
                MOV     DI,2            ;2 PASSES...1 WRITE , 1 READ
AI1:
                MOV     SI,AIDATA       ;SAVE FOR I/O TO TTDATA WITH AUTO-INC
AI2:
                MOV     CX,1000H        ;TTPOINTER RANGE 0 -> FFF
                MOV     BX,0001H        ;INITIAL COMPARE VALUE
                MOV     AX,0            ;SET TTPONTER TO ZERO
                OUT     DX,AX           ;TTPOINTER IS INITIALIZED TO ZERO
AI2X:
                XCHG    DX,SI           ;I/O TO TTDATA WITH AUTO-INC
;
;DETERMINE IF WRITE OR READ TEST
;
                CMP     DI,2            ;DOING A AUTO-INC WRITE TEST ?
                JNE     AI3             ;NO - THEN MUST BE AUTO-INC READ TEST
                OUT     DX,AX           ;WRITE TO AUTO-INC DATA REG
                JMP     AI4             ;CONTINUE WITH TEST
AI3:
                IN      AX,DX           ;READ FROM AUTO-INC DATA REG
AI4:
                XCHG    DX,SI           ;I/O TO TTPOINTER REG
                IN      AX,DX           ;READ TTPOINTER (31A1 -> AH)
                XOR     AX,BX           ;DATA AS EXPECTED ?
                AND     AX,0FFFH        ;MASK OFF UPPER NIBBLE (INVALID)
                JNE     INC_ERROR       ;NO - GO TO ERROR
                INC     BX              ;NEXT VALUE TO LOOK FOR
                LOOP    AI2X            ;CONTINUE TIL ALL VALUES ARE TESTED
;
                DEC     DI
                CMP     DI,0            ;COMPLETE WITH WRITE AND READ TEST ?
                JE      INC_EXIT        ;YES - THEN EXIT
                JMP     AI1             ;NO - THEN CONTINUE WITH READ TEST
;
INC_ERROR:
INC_EXIT:       RET
;
INCTST          ENDP

PAGE
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;
;                       TRANSLATE TABLE TEST
;
; DESCRIPTION   :  This routine performs a write/read storage test
;                  on the Translate Table. The test is as follows:
;                     (i) A bit is rolled through the first word of the TT
;                    (ii) A bit and address test is performed on the
;                         remainder of the TT.
;
; FUNCTION/     :  To verify the integrity of the Translate Table.
; PURPOSE
;
; ENTRY POINT   :  XLATST
;
; ENTRY         :  NONE
; CONDITIONS
;
; EXIT          :  Entire Translate Table is left with FFF (passover code)
;
;                  (zero flag) = 0 indicates an error
;                  (DX) failing register (TT data register)
;                  (AX) expected data XOR'ed with actual data
;                  (31A0) address in TT of failure
;-------------------------------------------------------------------------
;
XLATST          PROC
;
                MOV     AL,XLAT_TABLE_TEST
                MOV     CS:TEST_ID,AL
;
;ROLL A BIT THROUGH THE FIRST BYTE
;
                MOV     BX,0001H        ;SET UP INITIAL PATTERN
                MOV     SI,TTDATA       ;SAVE FOR I/O TO DATA REG
                MOV     DX,TTPOINTER    ;I/O TO TTPOINTER REG
                MOV     CX,12           ;ROLL 12 BIT POSITIONS
                XOR     AX,AX           ;CLEAR AX (WRITE TO 1st TT LOCATION)
                OUT     DX,AX           ;SET TT POINTER
                XCHG    DX,SI           ;READY FOR I/O TO TTDATA REG
X1:
                MOV     AX,BX           ;GET BIT PATTERN
                OUT     DX,AX           ;WRITE BIT PATTERN TO TT
                XCHG    DX,SI           ;READY FOR I/O TO TTPOINTER REG
                XOR     AX,AX           ;CLEAR AX
                OUT     DX,AX           ;CHARGE BUS WITH 0000 PATTERN
                XCHG    DX,SI           ;READY FOR I/O TO TTDATA REG
                IN      AX,DX           ;READ TT (31A1 -> AH)
                XOR     AX,BX           ;DATA READ AS EXPECTED ?
                AND     AX,0FFFH        ;MASK OFF UPPER NIBBLE (INVALID)
                JNE     XLA_ERROR       ;NO - THEN EXIT
                SHL     BX,1            ;SHIFT BIT TO NEXT POSITION
                LOOP    X1
;
;CONTINUE REMAINDER OF TRANSLATE TABLE
;
                MOV     DX,AIDATA
;
                XCHG    DX,SI           ;READY FOR I/O TO TTPOINTER
                XOR     AX,AX           ;CLEAR AX
                OUT     DX,AX           ;TTPOINTER AT 1st LOCATION
;
                XCHG    DX,SI           ;READY FOR I/O TO TT DATA W/AUTO-INC
                MOV     AX,0AA55H       ;INITIAL DATA PATTERN
                MOV     CX,TABLEN       ;NUMBER OF TT ENTRIES
X2:
                OUT     DX,AX           ;SETUP INVERSE PATTERN
                LOOP    X2              ;FILL ENTIRE XLATE TABLE
;
                MOV     SI,TTDATA       ;ADDRESS OF TTDATA WITHOUT INC.
                MOV     BX,AX           ;SAVE VALUE FOR COMPARE
                MOV     DI,055AAH       ;NEXT PATTERN TO WRITE
X3:
                MOV     CX,TABLEN       ;NUMBER OF TT ENTRIES
X4:
                XCHG    DX,SI           ;GET IT INTO DX...SI GETS AUTO-INC
                IN      AX,DX           ;READ TABLE ENTRY (HI BYTE -> AH)
                XOR     AX,BX           ;DATA READ AS EXPECTED ?
                AND     AX,0FFFH        ;MASK OFF HI NIBBLE (INVALID)
                JNE     XLA_ERROR       ;NO - THE EXIT
                XCHG    DX,SI           ;GET TTDATA WITH AUTO-INC
                MOV     AX,DI           ;RECOVER NEXT PATTERN TO WRITE
                OUT     DX,AX           ;WRITE IT THEN INCREMENT
                LOOP    X4              ;REPEAT TILL TABLE FILLED


;
                CMP     DI,0FFFFH       ;LAST PASS ?
                JE      XLA_EXIT        ;YES - THEN EXIT REG TEST
;
                XCHG    BX,DI           ;BX GETS NEXT PATTERN TO TEST
;
                CMP     BX,055AAH       ;LAST PASS FOR AA55,55AA PATTERN?
                JNE     X5              ;NO
                MOV     DI,0FF00H       ;YES- PREPARE TO WRITE NEW PATTERN
                JMP     X3              ;DO IT
X5:
                CMP     BX,0FF00H       ;READY TO READ 0FF00 PATTERN
                JNE     X6              ;NO
                MOV     DI,00FFH        ;YES- PREPARE TO WRITE NEW PATTERN
                JMP     X3              ;DO IT
X6:
                MOV     DI,0FFFFH       ;PREPARE TO SET ALL OF TT INACTIVE
                JMP     X3              ;DO IT
;
XLA_ERROR:
XLA_EXIT:       RET
;
XLATST          ENDP
