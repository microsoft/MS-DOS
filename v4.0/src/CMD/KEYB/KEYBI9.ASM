
        PAGE    ,132
        TITLE   DOS KEYB Command  -  Interrupt 9 Non-US Support

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBI9.ASM
;; ----------
;;
;; Description:
;; ------------
;;       Converts scan codes to ASCII for non-US keyboards.
;;       This orutine uses the tables loaded into the SHARED_DATA_AREA
;;       from KEYBOARD.SYS by the KEYB_COMMAND module.
;;
;; Documentation Reference:
;; ------------------------
;;       PC DOS 3.3 Detailed Design Document - May  1986
;;
;; Procedures Contained in This File:
;; ----------------------------------
;;       KEYB_STATE_PROCESSOR - Scan to ASCII translator.
;;
;; External Procedure References:
;; ------------------------------
;;       None.
;;
;; Linkage Information:  Refer to file KEYB.ASM
;; --------------------
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
;****
        INCLUDE KEYBEQU.INC            ;;
        INCLUDE DSEG.inc               ;; System data segments
        INCLUDE POSTEQU.inc            ;; System equates
        INCLUDE KEYBSHAR.INC           ;;
        INCLUDE KEYBI2F.INC            ;;
        INCLUDE KEYBI9C.INC            ;;
        INCLUDE KEYBCPSD.INC           ;;
        INCLUDE KEYBCMD.INC            ;;
                                       ;;
        PUBLIC KEYB_STATE_PROCESSOR    ;;
                                       ;;
CODE    SEGMENT PUBLIC 'CODE'          ;;
                                       ;;
        ASSUME  CS:CODE,DS:CODE        ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Procedure: KEYB_STATE_PROCESSOR
;;
;; Description:
;;     Convert scan to ASCII using the tables loaded into the
;;     SHARED_DATA_AREA.  Conversion is directed by the STATE LOGIC
;;     commands contained in the SHARED_DATA_AREA.  This routine
;;     interprets those commands.
;;
;; Input Registers:
;;     N/A
;;
;; Output Registers:
;;     N/A
;;
;; Logic:
;;     Enable interrupts
;;     Save registers
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
BREAK_CODE    EQU  80H                 ;;
                                       ;;
HOT_KEY_ACTIVE  DB   0                 ;; 1 if hot key is active
                                       ;;
                                       ;;
                                       ;; These are copies of the BIOS FLAGS
FLAGS_TO_TEST    LABEL BYTE            ;;  KB_FLAG, KB_FLAG_1,2,3
KB_SHADOW_FLAGS  DB   NUM_BIOS_FLAGS DUP(0) ;;
EXT_KB_FLAG      DB   0                ;; Extended KB Flag for shift states
NLS_FLAG_1       DB   0                ;; NLS Flags for dead key etc
NLS_FLAG_2       DB   0                ;;  .
                                       ;;
SAVED_NLS_FLAGS  DB   0,0              ;; Saved copy of the NLS flags
                                       ;;
OPTION_BYTE     DB    0                ;; Set by OPTION command
                                       ;;
KB_FLAG_PTRS    DW   OFFSET KB_FLAG    ;; These are pointers to the BIOS flags
                DW   OFFSET KB_FLAG_1  ;;  we must test
                DW   OFFSET KB_FLAG_2  ;;
                DW   OFFSET KB_FLAG_3  ;;
                                       ;;
XLAT_TAB_PTR    DW   0                 ;; pointer to xlat tables for cur state
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


NEST_LEVEL      DB   0                 ;;
PROCESS_LEVEL   DB   0                 ;;
TAKE_ELSE       DB   0                 ;;
BUSY_FLAG       DB   0                 ;; Flag to prevent re-entry
                                       ;;
CMD_JUMP_TABLE  LABEL  WORD            ;;
        DW   OFFSET  IFF_PROC          ;; CODE  0
        DW   OFFSET  ANDF_PROC         ;;       1
        DW   OFFSET  ELSEF_PROC        ;;       2
        DW   OFFSET  ENDIFF_PROC       ;;       3
        DW   OFFSET  XLATT_PROC        ;;       4
        DW   OFFSET  OPTION_PROC       ;;       5
        DW   OFFSET  SET_FLAG_PROC     ;;       6
        DW   OFFSET  PUT_ERROR_PROC    ;;       7
        DW   OFFSET  IFKBD_PROC        ;;       8
        DW   OFFSET  GOTO_PROC         ;;       9
        DW   OFFSET  BEEP_PROC         ;;       A
        DW   OFFSET  RESET_NLS_PROC    ;;       B
        DW   OFFSET  UNKNOWN_COMMAND   ;;       C
        DW   OFFSET  UNKNOWN_COMMAND   ;;       D
        DW   OFFSET  UNKNOWN_COMMAND   ;;       E
        DW   OFFSET  UNKNOWN_COMMAND   ;;       F
                                       ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
KEYB_STATE_PROCESSOR   PROC   NEAR     ;;
                                       ;;
        TEST   CS:SD.TABLE_OK,1        ;;
        JNZ    WE_HAVE_A_TABLE         ;;
        CLC                            ;; BACK TO US INT 9
	RET			       ;;

	EVEN

WE_HAVE_A_TABLE:                       ;;
	
        PUSH   DS                      ;; save DS
        PUSH   ES                      ;; save ES
        PUSH   AX                      ;; save scan code for caller
        PUSH   BX                      ;; save shift states for caller

        PUSH   CS                      ;;
        POP    DS                      ;; DS = our seg
        MOV    BX,DATA                 ;;
        MOV    ES,BX                   ;; addressability to BIOS data
                                       ;;
                                       ;;
        CMP     COUNTRY_FLAG,0FFH      ;; Q..country mode?
        JE      INIT_STATE_PROCESSING  ;; Y..continue
        JMP     GOTO_BIOS              ;; N..exit
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; -------STATE SECTION PROCESSING-------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
INIT_STATE_PROCESSING:                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set NLS shift flags EITHER_SHIFT, EITHER_ALT, EITHER_CTRL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
                                       ;; Q..in shift state?
        TEST   ES:KB_FLAG,RIGHT_SHIFT+LEFT_SHIFT
        JNZ    IN_SHIFT_STATE          ;; Y..go set bit
        AND    EXT_KB_FLAG,NOT EITHER_SHIFT ;; N..clear bit
        JMP    SHORT TEST_CTL          ;;
IN_SHIFT_STATE:                        ;;
        OR     EXT_KB_FLAG,EITHER_SHIFT ;;
TEST_CTL:                              ;;
        TEST   ES:KB_FLAG,CTL_SHIFT    ;; Q..in control state?
        JNZ    IN_CTL_STATE            ;; Y..go set bit
        TEST   ES:KB_FLAG_3,R_CTL_SHIFT ;; Q..how bout the right ctl?
        JNZ    IN_CTL_STATE            ;; Y..go set the bit
        AND    EXT_KB_FLAG,NOT EITHER_CTL ;; N..clear the bit
        JMP    SHORT TEST_ALT          ;;
IN_CTL_STATE:                          ;;
        OR     EXT_KB_FLAG,EITHER_CTL   ;;
TEST_ALT:                              ;;
        TEST   ES:KB_FLAG,ALT_SHIFT    ;; Q..in alt state?
        JNZ    IN_ALT_STATE            ;; Y..go set bit
        TEST   ES:KB_FLAG_3,R_ALT_SHIFT ;; Q..how bout the right alt?
        JNZ    IN_ALT_STATE            ;; Y..go set the bit
        AND    EXT_KB_FLAG,NOT EITHER_ALT ;; N..clear the bit
        JMP    SHORT COPY_FLAGS        ;;
IN_ALT_STATE:                          ;;
        OR     EXT_KB_FLAG,EITHER_ALT   ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copy BIOS KB flags from BIOS data seg into the
;; FLAGS_TO_TEST structure.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
COPY_FLAGS:                            ;;
        MOV    CX,NUM_BIOS_FLAGS       ;;
        MOV    SI,0                    ;; pointers to the BIOS flags
        MOV    DI,0                    ;; create shadow copies
MOVE_NEXT_FLAG:                        ;;
        MOV    BX,KB_FLAG_PTRS[SI]     ;; pointer to next flag
        MOV    AL,ES:[BX]              ;; flag in AL
        MOV    KB_SHADOW_FLAGS[DI],AL  ;; save it in the shadow table
        INC    DI                      ;;
        INC    SI                      ;;
        INC    SI                      ;;
        LOOP   MOVE_NEXT_FLAG          ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Interpret State Logic Commands
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
PROCESS_STATES:                        ;;
        MOV    OPTION_BYTE,0           ;; clear options
        MOV    SI,SD.LOGIC_PTR         ;;
        LEA    SI,[SI].SL_LOGIC_CMDS   ;;
NEXT_COMMAND:                          ;;
        MOV    BL,[SI]                 ;; command byte in BL
        SHR    BL,1                    ;;
        SHR    BL,1                    ;;
        SHR    BL,1                    ;;
        SHR    BL,1                    ;; ISOLATE COMMAND CODE
        SHL    BL,1                    ;; command code * 2
        JMP    CMD_JUMP_TABLE[BX]      ;; go process command
UNKNOWN_COMMAND:                       ;;
        JMP    FATAL_ERROR             ;; bad news
                                       ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IFKBD_PROC:                            ;;
        MOV    AL,NEST_LEVEL           ;;
        CMP    AL,PROCESS_LEVEL        ;; Q..nest level = process level?
        JNE    IFKBD_DONE              ;; N..don't process

        MOV    AX,[SI+1]               ;; Keyboard Type Flag
                                       ;;
        TEST   SD.KEYB_TYPE,AX         ;; Q..are we the right system?
        JNZ    IFKBD_TEST_OK           ;; Y..
IFKBD_TEST_FAILED:                     ;;
        MOV    TAKE_ELSE,YES           ;; test failed - take ELSE
        JMP    SHORT IFKBD_DONE        ;;
IFKBD_TEST_OK:                         ;;
        INC    PROCESS_LEVEL           ;; process commands within IF
        MOV    TAKE_ELSE,NO            ;;
IFKBD_DONE:                            ;;
        INC    NEST_LEVEL              ;; IFKBD increments nest level
        INC    SI                      ;; bump past IFKBD
        INC    SI                      ;;
        INC    SI                      ;;
        JMP    NEXT_COMMAND            ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
PUT_ERROR_PROC:                        ;;
        MOV    AL,NEST_LEVEL           ;;
        CMP    AL,PROCESS_LEVEL        ;; Q..nest level = process level?
        JNE    PUT_ERROR_DONE          ;; N..don't process
        MOV    DI,SD.ACTIVE_XLAT_PTR   ;; pointer to active Xlat Section
        MOV    AL,[SI+1]               ;; state id in AL
        CALL   PUT_ERROR               ;; check active section
        JC     PUT_ERROR_DONE          ;; carry set if translation found
        MOV    DI,SD.COMMON_XLAT_PTR   ;; check common Xlat Section
        MOV    AL,[SI+1]               ;; state id for XLATT in AL
        CALL   PUT_ERROR               ;;
                                       ;;
PUT_ERROR_DONE:                        ;;
        INC    SI                      ;;
        INC    SI                      ;;
        JMP    NEXT_COMMAND            ;;
                                       ;;
PUT_ERROR      PROC                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Search for a state whose ID matches the ID
;; on the PUT_ERROR command
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
        CLC                            ;;
        LEA    DI,[DI].XS_FIRST_STATE  ;; point to first state in section
PE_NEXT_STATE:                         ;;
        CMP    [DI].XS_STATE_LEN,0     ;; Q..out of states?
        JE     PE_EXIT                 ;; Y..exit
        CMP    AL,[DI].XS_STATE_ID     ;; Q..is this the requested state?
        JE     PE_STATE_MATCH          ;;
        ADD    DI,[DI].XS_STATE_LEN    ;; N..check next state
        JMP    SHORT PE_NEXT_STATE     ;;
                                       ;;
PE_STATE_MATCH:                        ;;
        MOV    AX,[DI].XS_ERROR_CHAR   ;; get error char in AX
        CALL   BUFFER_FILL             ;;
        STC                            ;; indicate that we found the state
PE_EXIT:                               ;;
        RET                            ;;
                                       ;;
PUT_ERROR   ENDP                       ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
GOTO_BIOS:                             ;;
        CLC                            ;; clear carry flag indicating
        POP   BX                       ;;  we should continue INT 9
        POP   AX                       ;;   processing
        POP   ES                       ;;
        POP   DS                       ;;
        RET                            ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
IFF_PROC:                              ;;
        MOV    AL,NEST_LEVEL           ;;
        CMP    AL,PROCESS_LEVEL        ;; Q..nest level = process level?
        JNE    IFF_DONE                ;; N..don't process IFF
        MOV    BL,[SI]                 ;; command byte
        AND    BL,FLAG_ID_BITS         ;; isolate flag id
        XOR    BH,BH                   ;;
        MOV    AL,FLAGS_TO_TEST[BX]    ;; flag in AL
        TEST   BYTE PTR[SI],NOT_TEST   ;; Q..is this a NOT test?
        JNZ    ITS_A_NOT               ;;
        TEST   AL,[SI]+1               ;; Y..check for bit set
        JNZ    IFF_MATCH               ;;
        JZ     IFF_NO_MATCH            ;;
ITS_A_NOT:                             ;;
        TEST   AL,[SI]+1               ;; Y..check for bit clear
        JZ     IFF_MATCH               ;;
IFF_NO_MATCH:                          ;;
        MOV    TAKE_ELSE,YES           ;; flag test failed - take ELSE
        JMP    SHORT IFF_DONE          ;;
IFF_MATCH:                             ;;
        INC    PROCESS_LEVEL           ;; process commands within IF
        MOV    TAKE_ELSE,NO            ;;
                                       ;;
IFF_DONE:                              ;;
        INC    NEST_LEVEL              ;; IFF increments nest level
        INC    SI                      ;; bump past IFF
        INC    SI                      ;;
        JMP    NEXT_COMMAND            ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
ELSEF_PROC:                            ;;
        MOV    AL,PROCESS_LEVEL        ;;
        CMP    AL,NEST_LEVEL           ;; Q..nest level = process level?
        JNE    CHECK_TAKE_ELSEF        ;; N..check for take_else
        DEC    PROCESS_LEVEL           ;; Y..we just finished the "IF" block
        JMP    ELSEF_DONE              ;;    so we are finished with IFF/ELSEF
CHECK_TAKE_ELSEF:                      ;;
        CMP    TAKE_ELSE,YES           ;; Q..are we scanning for ELSE?
        JNE    ELSEF_DONE              ;; N..done
        DEC    NEST_LEVEL              ;; ELSEF itself is back a level
        CMP    AL,NEST_LEVEL           ;; Q..nest level = process level?
        JNE    NOT_THIS_ELSEF          ;; N..this else is not the one
        INC    PROCESS_LEVEL           ;; Y..process ELSEF block
        MOV    TAKE_ELSE,NO            ;; reset
NOT_THIS_ELSEF:                        ;;
        INC    NEST_LEVEL              ;; stuff within the ELSEF is up a level
                                       ;;
ELSEF_DONE:                            ;;
        INC    SI                      ;; bump past ELSEF
        JMP    NEXT_COMMAND            ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ENDIFF_PROC:                           ;;
        MOV    AL,PROCESS_LEVEL        ;;
        CMP    AL,NEST_LEVEL           ;; Q..nest level = process level?
        JNE    ENDIFF_DONE             ;; N..don't adjust process level
        DEC    PROCESS_LEVEL           ;; Y..we just finished the IF/ELSE
ENDIFF_DONE:                            ;;
        DEC    NEST_LEVEL              ;; ENDIF decrements nest level
        INC    SI                      ;; bump past ENDIF
        JMP    NEXT_COMMAND            ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Translations may be in the Common or Specific
;; Sections.  Search the Specific section first
;; then the common section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
XLATT_PROC:                            ;;
        MOV    AL,PROCESS_LEVEL        ;;
        CMP    AL,NEST_LEVEL           ;; Q..nest level = process level?
        JNE    XLATT_DONE              ;; N..next command
        MOV    DI,SD.ACTIVE_XLAT_PTR   ;; pointer to active Xlat Section
        MOV    AL,[SI+1]               ;; state id for XLATT in AL
        CALL   TRANSLATE               ;; check active section
        JC     XLATT_FOUND             ;; carry set if translation found
        MOV    DI,SD.COMMON_XLAT_PTR   ;; check common Xlat Section
        MOV    AL,[SI+1]               ;; state id for XLATT in AL
        CALL   TRANSLATE               ;;
        JNC    XLATT_DONE              ;;
XLATT_FOUND:                           ;;
        OR     EXT_KB_FLAG,SCAN_MATCH  ;; set flag indicating scan matched
        TEST   OPTION_BYTE,EXIT_IF_FOUND ;; Q..exit
        JZ     XLATT_DONE              ;;
        JMP    EXIT                    ;; Y..BYE
                                       ;;
XLATT_DONE:                            ;;
        INC    SI                      ;;
        INC    SI                      ;;
        JMP    NEXT_COMMAND            ;;
                                       ;;
TRANSLATE PROC                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Search for a state whose ID matches the ID
;; on the XLATT command
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
        CLC                            ;;
        LEA    DI,[DI].XS_FIRST_STATE  ;; point to first state in section
TP_NEXT_STATE:                         ;;
        CMP    [DI].XS_STATE_LEN,0     ;; Q..out of states?
        JE     TP_EXIT                 ;; Y..exit
        CMP    AL,[DI].XS_STATE_ID     ;; Q..is this the requested state?
        JE     TP_STATE_MATCH          ;;
        ADD    DI,[DI].XS_STATE_LEN    ;; N..check next state
        JMP    SHORT TP_NEXT_STATE     ;;
                                       ;;
TP_STATE_MATCH:                        ;;
        AND    EXT_KB_FLAG,NOT SCAN_MATCH  ;; reset flag before search
        PUSH   SI                      ;; save pointer to next command
        LEA    SI,[DI].XS_FIRST_TAB    ;; point to first xlat table
        MOV    XLAT_TAB_PTR,SI         ;; start of XLAT tables
        MOV    AL,SCAN_CODE            ;; restore incoming scan code
        JMP    SHORT NEXT_XLAT_TAB     ;;
TP_DONE:                               ;; return here from XLAT
        POP    SI                      ;;
TP_EXIT:                               ;;
        RET                            ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Check xlate tables for matching scan code
;; The xlate table can be in one of two forms:
;;    Type 1 = Table contains buffer entries only.
;;             Scan code is used as an index into xlat table
;;    Type 2 = Table contains pairs of SCAN/BUFFER_ENTRY.
;;             Table must be searched for matching scan.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
NEXT_XLAT_TAB:                         ;;
        MOV    SI,XLAT_TAB_PTR         ;; pointer to xlat tables
        CMP    [SI].XLAT_TAB_SIZE,0    ;; Q..any more xlat tables?
        JNE    PROCESS_XLAT_TAB        ;; Y..check um
        JMP    TP_DONE                 ;; N..done
PROCESS_XLAT_TAB:                      ;;
        MOV    DL,[SI].XLAT_OPTIONS    ;; save translate options IN DL
        MOV    BX,[SI].XLAT_TAB_SIZE   ;; Y..calc pointer to next xlat tab
        ADD    BX,SI                   ;;
        MOV    XLAT_TAB_PTR,BX         ;; pointer to next xlat tab
        TEST   DL,TYPE_2_TAB           ;; Q..is this a type 2 table?
        JZ     TYPE_1_LOOKUP           ;; N..go do table lookup
TYPE_2_SEARCH:                         ;; Y..search table
        XOR    CH,CH                   ;;
        MOV    CL,[SI].XLAT_NUM        ;; number of xlat entries
        MOV    BX,DEFAULT_TAB_2_ENT_SZ ;; default entry size
        TEST   DL,ASCII_ONLY+ZERO_SCAN ;; Q..are buffer entries ASCII only?
        JZ     NEXT_TAB_2_ENTRY        ;; N..continue
        MOV    BX,ASC_ONLY_TAB_2_ENT_SZ ;; Y..set size in BX
NEXT_TAB_2_ENTRY:                      ;; entry size is in BX
        CMP    CX,0                    ;; Q..last entry?
        JE     NEXT_XLAT_TAB           ;; y..go to next table
        CMP    AL,[SI].XLAT_SCAN       ;; Q..scan match?
        JE     FOUND_TAB_2_ENTRY       ;; Y..go create buffer entry
        ADD    SI,BX                   ;; point to next entry
        LOOP   NEXT_TAB_2_ENTRY        ;;
        JMP    SHORT NEXT_XLAT_TAB     ;;
FOUND_TAB_2_ENTRY:                     ;; Q..set scan code to 0?
        MOV    AH,AL                   ;; default scan code in AH
        MOV    AL,[SI].XLAT_2_BUF_ENTRY ;; ASCII code from table in AL
        TEST   DL,ASCII_ONLY+ZERO_SCAN ;; Q..are buffer entries ASCII only?
        JNZ    BUFFER_ENTRY_READY      ;; Y..buffer entry is ready
        MOV    AH,[SI].XLAT_2_BUF_ENTRY+1 ;; N..scan code from table as well
        JMP    SHORT BUFFER_ENTRY_READY ;; go put entry in buffer
                                       ;;
TYPE_1_LOOKUP:                         ;;
        CMP    AL,[SI].XLAT_SCAN_LO    ;; Q..is scan in range of this table?
        JB     NEXT_XLAT_TAB           ;; N..next table
        CMP    AL,[SI].XLAT_SCAN_HI    ;; Q..is scan in range of this table?
        JA     NEXT_XLAT_TAB           ;; N..next table
        SUB    AL,[SI].XLAT_SCAN_LO    ;; convert scan code to xlat index
        TEST   DL,ASCII_ONLY+ZERO_SCAN ;; Q..ASCII only in xlat ?
        JZ     TWO_BYTE_LOOKUP         ;; N..go do 2-byte lookup
        LEA    BX,[SI].XLAT_1_BUF_ENTRY ;; Y..do 1-byte lookup
        XLAT   [SI].XLAT_1_BUF_ENTRY   ;; ASCII code in AL
        MOV    AH,SCAN_CODE            ;; SCAN in AH
        JMP    SHORT BUFFER_ENTRY_READY ;; go put entry in buffer
TWO_BYTE_LOOKUP:                       ;;
        MOV    BL,2                    ;; multiply scan index
        MUL    BL                      ;;  by two
        MOV    BX,AX                   ;; real index in BX
        MOV    AX,WORD PTR [SI].XLAT_1_BUF_ENTRY[BX] ;; get 2-byte buffer entry
                                       ;;  AL=ASCII  AH=SCAN
BUFFER_ENTRY_READY:                    ;;
        TEST   DL,ZERO_SCAN            ;; Q..set scan part to zero?
        JZ     NO_ZERO_SCAN            ;; N..
        XOR    AH,AH                   ;; scan = 0
NO_ZERO_SCAN:                          ;;
        CALL   BUFFER_FILL             ;; go put entry in buffer
        STC                            ;; indicate translation found
        JMP    TP_DONE                 ;;
                                       ;;
TRANSLATE ENDP                         ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPTION_PROC:                           ;;
        MOV    AL,PROCESS_LEVEL        ;;
        CMP    AL,NEST_LEVEL           ;; Q..nest level = process level?
        JNE    DONE_OPTION             ;; N..done
        MOV    AL,[SI]+1               ;; mask in AL
        TEST   BYTE PTR[SI],NOT_TEST   ;; Q..is this a NOT?
        JNZ    AND_MASK                ;;
        OR     OPTION_BYTE,AL          ;; N..OR in the mask bits
        JMP    DONE_OPTION             ;;
AND_MASK:                              ;;
        NOT    AL                      ;;
        AND    OPTION_BYTE,AL          ;; Y..AND out the mask bits
DONE_OPTION:                           ;;
        INC    SI                      ;;
        INC    SI                      ;;
        JMP    NEXT_COMMAND            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESET_NLS_PROC:                        ;;
        MOV    AL,NEST_LEVEL           ;;
        CMP    AL,PROCESS_LEVEL        ;; Q..nest level = process level?
        JNE    RN_DONE                 ;; N..don't process
        MOV    NLS_FLAG_1,0            ;;
        MOV    NLS_FLAG_2,0            ;;
RN_DONE:                               ;;
        INC    SI                      ;;
        JMP    NEXT_COMMAND            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BEEP_PROC:                             ;;
        MOV    AL,NEST_LEVEL           ;;
        CMP    AL,PROCESS_LEVEL        ;; Q..nest level = process level?
        JNE    BP_DONE                 ;; N..don't process
        MOV    BEEP_PENDING,YES        ;; set beep pending flag. the beep
                                       ;;  will be done just before iret
BP_DONE:                               ;;
        INC    SI                      ;;
        JMP    NEXT_COMMAND            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GOTO_PROC:                             ;;
        MOV    AL,NEST_LEVEL           ;;
        CMP    AL,PROCESS_LEVEL        ;; Q..nest level = process level?
        JNE    GOTO_DONE               ;; N..don't process
        MOV    BL,[SI]                 ;; command byte in BL
        AND    BL,NOT COMMAND_BITS     ;; remove command code
        OR     BL,BL                   ;; Q..goto label?
        JZ     GOTO_LABEL              ;; Y..go jump
        CMP    BL,EXIT_INT_9_FLAG      ;; Q..SPECIAL - Exit Int 9?
        JNE    NOT_EXIT_INT_9          ;; N..
        JMP    EXIT                    ;; Y..bye bye
NOT_EXIT_INT_9:                        ;;
        CMP    BL,EXIT_STATE_LOGIC_FLAG ;; Q..SPECIAL - Exit State Logic?
        JNE    NOT_EXIT_S_L            ;; N..
        JMP    GOTO_BIOS               ;; Y..goto bios
NOT_EXIT_S_L:                          ;;
        JMP    FATAL_ERROR             ;; garbage in that command
GOTO_LABEL:                            ;;
        ADD    SI,[SI]+1               ;; bump by relative offset
        MOV    PROCESS_LEVEL,0         ;; reset process and nest level
        MOV    NEST_LEVEL,0            ;;
GOTO_DONE:                             ;;
        ADD    SI,3                    ;; bump to next command
        JMP    NEXT_COMMAND            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
ANDF_PROC:                             ;;
        MOV    AL,NEST_LEVEL           ;;
        CMP    AL,PROCESS_LEVEL        ;; Q..nest level = process level?
        JNE    ANDF_DONE               ;; N..don't process ANDF
        MOV    BL,[SI]                 ;; command byte
        AND    BL,FLAG_ID_BITS         ;; isolate flag id
        XOR    BH,BH                   ;;
        MOV    AL,FLAGS_TO_TEST[BX]    ;; flag in AL
        TEST   BYTE PTR[SI],NOT_TEST   ;; Q..is this a NOT test?
        JNZ    ANDF_NOT                ;;
        TEST   AL,[SI]+1               ;; Y..check for bit set
        JNZ    ANDF_DONE               ;; if set then remain in IFF
        JZ     ANDF_NO_MATCH           ;;
ANDF_NOT:                              ;;
        TEST   AL,[SI]+1               ;; Y..check for bit clear
        JZ     ANDF_DONE               ;; if clear then remain in IFF
ANDF_NO_MATCH:                         ;;
        MOV    TAKE_ELSE,YES           ;; flag test failed - take ELSE
        DEC    PROCESS_LEVEL           ;; IFF would have inc'd - so dec
ANDF_DONE:                             ;;
        INC    SI                      ;; bump past ANDF
        INC    SI                      ;;
        JMP    NEXT_COMMAND            ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SET_FLAG Command.
;; Flag Table must be in the Common Section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
SET_FLAG_PROC:                         ;;
        MOV    AL,NEST_LEVEL           ;;
        CMP    AL,PROCESS_LEVEL        ;; Q..nest level = process level?
        JNE    SF_DONE                 ;; N..don't process
                                       ;;
        MOV    DI,SD.COMMON_XLAT_PTR   ;; check common Xlat Section
        MOV    AL,[SI+1]               ;; state id in AL
        LEA    DI,[DI].XS_FIRST_STATE  ;; point to first state in section
SF_NEXT_STATE:                         ;;
        CMP    [DI].XS_STATE_LEN,0     ;; Q..out of states?
        JE     SF_DONE                 ;; Y..exit
        CMP    AL,[DI].XS_STATE_ID     ;; Q..is this the requested state?
        JE     SF_STATE_MATCH             ;;
        ADD    DI,[DI].XS_STATE_LEN    ;; N..check next state
        JMP    SHORT SF_NEXT_STATE     ;;
                                       ;;
SF_STATE_MATCH:                        ;;
        AND    EXT_KB_FLAG,NOT SCAN_MATCH  ;; reset flag before search
        PUSH   SI                      ;; save pointer to next command
        LEA    SI,[DI].XS_FIRST_TAB    ;; point to table
        MOV    AL,SCAN_CODE            ;; restore incoming scan code
        MOV    CX,[SI]                 ;; number of entries
        CMP    CX,0                    ;; Q..any entries?
        JE     SF_RESTORE              ;; N..done
        INC    SI                      ;; Y..Bump to first entry
        INC    SI                      ;;
NEXT_SF_ENTRY:                         ;;
        CMP    AL,[SI]                 ;; Q..scan match?
        JE     FOUND_SF_ENTRY          ;; Y..go set flag
        ADD    SI,3                    ;; point to next entry
        LOOP   NEXT_SF_ENTRY           ;;
        JMP    SHORT SF_RESTORE        ;; no match found
FOUND_SF_ENTRY:                        ;;
        MOV    NLS_FLAG_1,0            ;; clear all NLS bits
        MOV    NLS_FLAG_2,0            ;;
        MOV    BL,[SI]+1               ;; flag id in BX
        XOR    BH,BH                   ;;
        MOV    AL,[SI]+2               ;; mask in AL
        OR     FLAGS_TO_TEST[BX],AL    ;; set the bit
        OR     EXT_KB_FLAG,SCAN_MATCH  ;; set flag indicating scan matched
        TEST   OPTION_BYTE,EXIT_IF_FOUND ;; Q..exit
        JZ     SF_RESTORE              ;;
        POP    SI                      ;;
        JMP    EXIT                    ;;
SF_RESTORE:                            ;;
        POP    SI                      ;;
SF_DONE:                               ;;
        INC    SI                      ;; bump past command
        INC    SI                      ;;
        JMP    NEXT_COMMAND            ;;
                                       ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fatal Error routine.  Come here when
;; we have a critical error such as an
;; invalid State Logic Command.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
FATAL_ERROR:                           ;;
        JMP   SHORT EXIT               ;; end the int 9 processing
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exit point.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
EXIT:                                  ;;
        MOV   BUSY_FLAG,NO             ;;
        STC                            ;; indicate we should end INT 9
        POP   BX                       ;;  processing
        POP   AX                       ;;
        POP   ES                       ;;
        POP   DS                       ;;
        RET                            ;;
                                       ;;
KEYB_STATE_PROCESSOR   ENDP            ;;
                                       ;;
                                       ;;

CODE   ENDS
	END
