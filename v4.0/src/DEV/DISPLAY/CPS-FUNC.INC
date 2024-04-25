;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       CODE PAGE DRIVER FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF1                                     ;
        %OUT .               ®CPS-FUNC.INC¯
ENDIF                                   ;
                                        ;
CP_FUNCTION     LABEL   BYTE            ;
        DW   4CH,OFFSET DESIGNATE_BEGIN ;
        DW   4DH,OFFSET DESIGNATE_END   ;
        DW   4AH,OFFSET INVOKE_CP       ;
        DW   6AH,OFFSET QUERY_CP        ;
        DW   6BH,OFFSET QUERY_CP_LIST   ;
NUM_CP_FUNCTION  EQU ($-CP_FUNCTION)/4  ;
                                        ;
DESG_SEMAPHORE  DB      0               ; TEMPORARY
G_IOCTL_SEMA    DB      0               ; SEMAPHORE TO INDICATE IF CPS IS BUSY!
                                        ;
CHAR_HEIGHT     DB      8               ;
                DB     14               ;
                DB     16               ;
                DB     19               ;
                DB      0               ;
                DB      0               ;
                DB      0               ;
                DB      0               ;
NUM_CHAR_HEIGHT EQU ($-CHAR_HEIGHT)     ;
                                        ;
                                        ;
GENERIC_IOCTL PROC                      ; CON OUTPUT
        CLI                           ;S;
        MOV     SI,SP                 ;S;
        MOV     CS:OLD_STACK_O,SI     ;S;
        MOV     SI,SS                 ;S;
        MOV     CS:OLD_STACK_S,SI     ;S;
        MOV     AX,OFFSET STACK_START ;S;
        MOV     SI,CS                 ;S;
        MOV     SS,SI                 ;S;
        MOV     SP,AX                 ;S;
        STI                           ;S;
        PUSH    DS                      ;
                                        ;
        PUSH    CS                      ;
        POP     DS                      ; FROM HERE IN, DS=CS
                                        ;
        LES     DI,DWORD PTR BUF.RH_PTRO; GET RH
                                        ;
GI_1:   MOV     AL,RH.MINOR_F           ; PUT MINOR VERSION IN AL
        XOR     AH,AH                   ; CLEAR OUT HIGH BYTE FOR COMPARES
                                        ;
        PUSH    DI                      ; SAVE POINTER!!!
        PUSH    ES                      ;
        PUSH    CS                      ;
        POP     ES                      ;
        MOV     CX,NUM_CP_FUNCTION      ;
        MOV     DI,OFFSET CP_FUNCTION   ;
GI_1A:  SCASW                           ; SEARCH THROUGH THE LIST OF VALID FN's
        JE      GI_2                    ;
        INC     DI                      ;
        INC     DI                      ;
        LOOP    GI_1A                   ;
        POP     ES                      ;
        POP     DI                      ;
        JUMP    GI_3                    ; NOT FOUND!
GI_2:   POP     ES                      ;
        MOV     SI,DI                   ;
        POP     DI                      ;
                                        ;
        MOV     G_IOCTL_SEMA,ONE        ; SEMAPHORE TO INDICATE CALLS ARE BUSY!
        CALL    [SI]                    ; JMP OFF TO THE APPROPRIATE CALL!
        MOV     G_IOCTL_SEMA,ZERO       ; SEMAPHORE TO INDICATE CALLS ARE DONE!
        STC                             ; SET CY not TO TRY ATTACHED CON!
        JUMP    GI_4                    ;
GI_3:   CLC                             ; CLEAR CY TO TRY ATTACHED CON!
GI_4:   POP     DS                      ;
        CLI                           ;S;
        MOV     AX,CS:OLD_STACK_O     ;S;
        MOV     SI,CS:OLD_STACK_S     ;S;
        MOV     SS,SI                 ;S;
        MOV     SP,AX                 ;S;
        STI                           ;S;
        RET                             ;
GENERIC_IOCTL ENDP                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       DESIGNATE BEGIN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DESIGNATE_BEGIN PROC                    ;
        LES     DI,RH.REQUEST_PACKET    ; AND DI TO POINT TO REQUEST PACKET
        MOV     CX,RH.DESG_N            ; MOVE THE NUMBER OF CODE PAGES DESIG'ed
                                        ;
        OR      CX,CX                   ;
        JZ      DB_0C                   ; CHECK IF ZERO CP's DESIGNATED
                                        ; IF SO, THEN THIS IS THE REFRESH CALL
DB_0:   CMP     CX,CPD_DESG_N           ; CHECK IF NUMBER > # CONFIGed
        JA      DB_0B                   ;
        JUMP    DB_1B                   ;
                                        ;
DB_0D:  OR      BUF.STATUS,EIGHT        ; Error>> KEYBOARD ERROR!!
        RET                             ;
DB_2D:  POP     CX                      ; RESTORE STACK ELEMENTS
        POP     BX                      ;
        POP     CX                      ; RESTORE STACK ELEMENTS
        POP     BX                      ;
DB_0B:  OR      BUF.STATUS,TEN          ; Error>> DEVICE ERROR!!
        RET                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       REFRESH ACTIVE CODE PAGE TO DISPLAY
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DB_0C:  MOV     DESG_SEMAPHORE,TWO      ; SET REFRESH COMMENCED
        MOV     CPD_REQ_DESG,CX         ; SAVE NUMBER OF REQUESTED CP'S (0)
        MOV     DX,CPD_ACTIVE           ; THIS IS THE REFRESH CALL
        CMP     DX,-1                   ; CHECK IF THE ACTIVE_CP = INVALID
        JE      DB_0B                   ;
        CLC                             ; CLEAR OUT THE CARRY FLAG
        CALL    SIGNAL_KBD_INVK         ;
        JC      DB_0D                   ; IF CY SET, THEN KEYBOARD IS WRONG
        CALL    TEST_CP                 ;
        JC      DB_0B                   ;
        CALL    INVOKE_DATA             ;
        JC      DB_0B                   ;
        RET                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       THIS SECTION FORMS THE NEW DESIGNATE CP LIST IN THE
;       CPD_TEMP_DESG.  AT THE SAME TIME THE TOTAL NUMBER OF
;       REQUESTED CP's ARE FOUND.
;
;       DX will contain the real CP's to load
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DB_1B:  CLD                             ; SET DIRECTION FORWARD
        PUSH    ES                      ;
        PUSH    CX                      ;
        PUSH    DI                      ;
        PUSH    CS                      ;
        POP     ES                      ;
        MOV     CX,CPD_DESG_N           ;
        INC     CX                      ; ACCOUNT FOR NUMBER OF CPS
        LEA     SI,CPD_DESG_N           ; COPY PREPARED CP LIST TO TEMP BUFFER
        LEA     DI,CPD_TEMP_DESG        ;
        REP     MOVSW                   ;
        POP     DI                      ;
        POP     CX                      ;
        POP     ES                      ;
                                        ;
        XOR     DX,DX                   ; SET COUNT OF CP's TO PREPARE = 0
        PUSH    CX                      ;
        PUSH    BX                      ;
        MOV     CPD_REQ_DESG,CX         ; SAVE NUMBER OF REQUESTED CP'S
        MOV     SI,2                    ;
        MOV     BX,SI                   ;
DB_1:   MOV     AX,RH.DESG_N[BX]        ; GET REQUESTED CP
        CMP     AX,-1                   ; TEST IF REQUESTED IS PLACE HOLDER..
        JE      DB_1A                   ;
        INC     DX                      ; ADD ONE TO THE # VALID DESG
        MOV     CPD_TEMP_DESG[SI],AX    ; OVERLAY THE NEWER CP INTO TEMP BUFFER
DB_1A:  MOV     CPD_REQ_DESG[SI],AX     ; COPY TO THE REQ DESG LIST
        INC     SI                      ;
        INC     SI                      ;
        INC     BX                      ;
        INC     BX                      ;
        LOOP    DB_1                    ;
        POP     BX                      ;
        POP     CX                      ;
                                        ;
        OR      DX,DX                   ; ARE THERE NO CP's TO PREPARE?
        JZ      DB_0B                   ; IF NONE TO DESG, THEN ERROR!!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       THIS SECTION CHECKS THE LIST OF DESIGed CP's IN THE
;       TEMP BUFFER AND SETS AN ERROR FOR DUPLICATES.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DB_2:   PUSH    BX                      ; CHECK THE DESIGNATE LIST FOR DUP's
        PUSH    CX                      ; AND FOR INVALIDS
        MOV     CX,CPD_TEMP_DESG        ;
        DEC     CX                      ; NORMALIZE
        JZ      DB_3                    ; IF ZERO, THEN NONE TO COMPARE
        MOV     BX,2                    ; SET BX TO START OF LIST....
        MOV     SI,2                    ; SETUP SI READY TO MOVE DESG LIST IN!
DB_2A:  PUSH    BX                      ;
        PUSH    CX                      ;
        MOV     AX,CPD_TEMP_DESG[BX]    ; GET CP DESGINATED
        CMP     AX,-1                   ; TEST IF ENTRY = -1
        JE      DB_2E                   ; IF SO, THEN SKIP
DB_2B:  CMP     CX,1                    ; TEST IF IT IS THE ONLY ONE TO COMPARE
        JE      DB_2E                   ; AGAINST!
        INC     BX                      ; ADVANCE POINTER TO NEXT CP DESIGNATED
        INC     BX                      ;
        CMP     AX,CPD_TEMP_DESG[BX]    ; CHECK IF NEXT CP's = ONE TESTED
        JNE     DB_2C                   ; IF error, THEN GET OUT
        JUMP    DB_2D                   ;
                                        ;
DB_2C:  LOOP    DB_2B                   ;
DB_2E:  POP     CX                      ;
        POP     BX                      ;
        INC     BX                      ;
        INC     BX                      ;
        OR      CX,CX                   ;
        JE      DB_3                    ; TEST IF ONLY ONE CP SPECIFIED
        LOOP    DB_2A                   ;
                                        ;
DB_3:   POP     CX                      ;
        POP     BX                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NOW, THE TEMPORARY BUFFER CONTAINS THE NEW LIST
;       OF DESGINATED CODE PAGES.  COPY THIS TO THE
;       PREPARED CP LIST.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        PUSH    ES                      ; NOW ALL TESTS ARE SUCCESSFUL,
        PUSH    CX                      ;
        PUSH    DI                      ;
        PUSH    CS                      ;
        POP     ES                      ;
        MOV     CX,CPD_DESG_N           ;
        INC     CX                      ; ACCOUNT FOR NUMBER OF CPS
        LEA     SI,CPD_TEMP_DESG        ; COPY TEMP BUFFER INTO NEW CP LIST
        LEA     DI,CPD_DESG_N           ;
        REP     MOVSW                   ;
        POP     DI                      ;
        POP     CX                      ;
        POP     ES                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NOW THAT THE LIST IS VALID, THE FONT PARSER & PARSING TABLES
;       ARE PREPARED FOR INITIALIZATION OF DESIGNATION.
;
;       DX is the number of valid CP's
;       CX is the number of CP's desginated
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        PUSH    BX                      ;
        PUSH    ES                      ;
        PUSH    DI                      ;
                                        ; CX=#DESGed, BX=pnter DESG LIST
        MOV     BX,2                    ; SET BX TO POINT TO FIRST CP DESGed
        LEA     DI,FTABLE               ; SET DI TO POINT TO MAIN PARSER TABLE
        PUSH    CS                      ;
        POP     ES                      ; INITIALIZE ES=CS
        MOV     [DI].FLAG,FLAG_RESTART  ; SETUP UP MAIN TABLE FOR F-PARSER.SRC
        MOV     [DI].BUFFER_LEN,0       ; PREPARING FOR START OF DESIGNATION
        MOV     [DI].NUM_FTBLK,DX       ; DX=#DESG TO PARSE OUT
                                        ;
        LEA     SI,CPD_CLASS            ; SET DI TO POINT TO (EGA,LCD) CLASSES
        LEA     DI,FTB1                 ; SET DI TO POINT TO FIRST PARSING TABLE
                                        ;
DB_4:   MOV     AX,CPD_REQ_DESG[BX]     ;
        CMP     AX,-1                   ; CHECK FOR PLACE HOLDER
        JE      DB_5                    ;
        MOV     [DI].FTB_CP,AX          ; COPY THE DESG CP VALUE INTO THE TABLE
        PUSH    CX                      ; AND ALSO THE CPD_CLASS
        PUSH    SI                      ;
        PUSH    DI                      ;
        LEA     DI,[DI].FTB_TID         ;
        MOV     CX,8                    ;
        REP     MOVSB                   ;
        POP     DI                      ;
        POP     SI                      ;
        POP     CX                      ;
                                        ;
        ADD     DI,TYPE FTBLK           ; MOVE POINTERS TO NEXT PARSING TABLE
DB_5:   INC     BX                      ;
        INC     BX                      ; ADVANCE BX TO NEXT DESG CP
        LOOP    DB_4                    ;
                                        ;
        POP     DI                      ;
        POP     ES                      ;
        POP     BX                      ;
                                        ;
        CALL    FONT_PARSER             ; CALL FONT PARSER TO INITIALIZE WRITES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       THIS WILL COPY THE START LOCATION OF THE FONTS (set by INIT)
;       INTO THE START LOCATION FOR THE DESIGNATE WRITE, WHICH FOLLOWS!
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        PUSH    SI                      ;
        PUSH    DI                      ;
        PUSH    ES                      ;
        PUSH    CS                      ;
        POP     ES                      ; SET EXTRA SEG ES = CS
        LEA     SI,CPD_FONT_PNTER       ;
        LEA     DI,CPD_FONT_WRITE       ;
        MOV     CX,CPD_DESG_N           ; GET NUMBER OF DESIGNATES
        ADD     CX,CX                   ; DOUBLE FOR SEG:OFFSET
        REP     MOVSW                   ; COPY FONT START LOC's TO START WRITE
        XOR     DI,DI                   ;
        LEA     SI,CPD_FONT_DATA        ; SET THE FONT_DATA COUNTERS BACK TO 0
        MOV     CX,CPD_DESG_N           ;
DB_6:   MOV     [SI],DI                 ;
        INC     SI                      ;
        INC     SI                      ;
        LOOP    DB_6                    ;
        POP     ES                      ;
        POP     DI                      ;
        POP     SI                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       CREATE THE FONT_PRIORITY TABLE
;
;       THIS IS USED TO PLACE PRIORITY ON THE FONTS BEING DESIGNATED
;       ESPECIALLY WHEN THE NUMBER OF DESIGNATED FONTS < FONTS IN THE
;       xxx.CPI FILE.  THIS IS USED TO SELECT THE NEEDED FONTS FOR
;       CP SUPPORT.
;
;       RULE:  PRIORITY 1 = ACTIVE MODE's FONT RESOLUTION
;              PRIORITY 2 = FONT RESOLUTION (non-repeats) OF ALL DISPLAY
;                           MODES - STARTING FROM MODE (0) - MODE (?)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        PUSH    AX                      ;
        PUSH    BX                      ;
        PUSH    CX                      ;
        PUSH    SI                      ;
        PUSH    DI                      ;
                                        ;
        LEA     DI,FONT_PRIORITY        ;
        MOV     CX,CPD_FONTS_N          ; GET THE NUMBER OF SPECIFIED FONTS
                                        ;
        PUSH    ES                      ;
        PUSH    DI                      ;
        PUSH    CX                      ; OVER-WRITE THE TABLE WITH 0FFH's
        PUSH    CS                      ;
        POP     ES                      ;
        MOV     AL,-1                   ;
        REP     STOSB                   ;
        POP     CX                      ;
        POP     DI                      ;
        POP     ES                      ;
                                        ;
        XOR     AH,AH                   ; AH=0 FOR MODE SET, AL=MODE_TYPE
        MOV     AL,MODE_VALUE           ;
        MOV     SI,AX                   ; ESTABLISH INDEX INTO LOAD_MECH table
        MOV     AL,[SI].FONT_SIZE       ; GET FONT_SIZE FOR THIS MODE_VALUE
        OR      AL,AL                   ; TEST FOR FONT_VALUE=0
        JNZ     DB_8                    ;
        CALL    ASK_BIOS_FONT_SIZE      ; GET BIOS TO INDICATE FONT_SIZE
DB_8:   MOV     CS:[DI],AL              ; PUT ACTIVE FONT RESOLUTION INTO 1ST!
        INC     DI                      ; ADVANCE POINTER TO NEXT POSITION
        DEC     CX                      ; SUBTRACT ONE FONT RESOLUTION...
        JZ      DB_A                    ; IF THERE WAS ONLY 1 FONT...THEN DONE
                                        ;
        XOR     SI,SI                   ; START WITH MODE = 0
DB_8A:  PUSH    CX                      ;
        PUSH    DI                      ;
        MOV     CX,NUM_FONT_PRIORITY    ;
        LEA     DI,FONT_PRIORITY        ; SET DI TO START OF TABLE
        MOV     AL,[SI].FONT_SIZE       ; GET FONT SIZE FOR THIS MODE
        CMP     AL,-1                   ; TEST FOR INVALID FONT SIZE
        JE      DB_9                    ; IF SO, THEN TRY NEXT VALUE
        OR      AL,AL                   ; TEST FOR FONT_VALUE=0
        JNZ     DB_8C                   ;
                                        ; OTHERWISE, ONLY EGA BIOS WOULD KNOW!!!
        CMP     SI,EIGHT                ; ONLY EIGHT DIFFERENT FONTS PERMITTED!!
        JAE     DB_9                    ;
                                        ;
        PUSH    CX                      ;
        CALL    ASK_BIOS_SCAN_LINES     ; GET ENCODED SCAN LINES VALUE!!!
        JC      DB_9                    ;
        MOV     CX,SI                   ; PUT INDEX INTO CX
        INC     CL                      ; NORMALIZE INDEX VALUE (1-8)
        SAR     AL,CL                   ;
        POP     CX                      ;
        JNC     DB_9                    ;
        MOV     AL,CS:CHAR_HEIGHT[SI]   ;
                                        ;
DB_8C:  CMP     AL,CS:[DI]              ;
        JE      DB_9                    ; IF EQUAL, THEN ALREADY IN TABLE
        INC     DI                      ; OTHERWISE, TAKE THIS MODES FONT RES
        LOOP    DB_8C                   ; AND COMPARE AGAINST NEXT PRIOR.VALUE
                                        ;
        POP     DI                      ; NEW RESOLUTION FOUND...ADD TO LIST
        POP     CX                      ;
        MOV     CS:[DI],AL              ; PUT NEW VALUE IN THE TABLE
        INC     DI                      ; AND ADVANCE FOR NEXT FONT RESOLUTION
        JUMP    DB_9A                   ; LOOP WILL DECREMENT #FONTS TO FIND
DB_9:   POP     DI                      ;
        POP     CX                      ;
        INC     CX                      ; MATCH FOUND..SO LEAVE #FONT TO PRIOR.
DB_9A:  INC     SI                      ; POINT TO NEXT DISPLAY MODE
        CMP     SI,NUM_FONT_SIZES       ;
        JAE     DB_A                    ;
        LOOP    DB_8A                   ; CONTINUE UNTIL THE #FONTS DESIGNATED
                                        ; HAVE BEEN PRIORITIZED OR ALL MODES
DB_A:   POP     DI                      ; ARE CHECKED OUT!
        POP     SI                      ;
        POP     CX                      ;
        POP     BX                      ;
        POP     AX                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        MOV     DESG_SEMAPHORE,ONE      ; SET DESIGNATION TO COMMENCE...
        RET                             ;
DESIGNATE_BEGIN ENDP                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       DESIGNATE END
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DESIGNATE_END   PROC                    ;
        CMP     DESG_SEMAPHORE,ZERO     ; TEST IF DESG_SEMAPHORE = DATA WRITTEN
        JE      DE_1                    ;
                                        ;
        CMP     CPD_REQ_DESG,ZERO       ; TEST IF ZERO CP's REQUESTED (REFRESH)
        JE      DE_0                    ;
                                        ;
        CALL    VERIFY_FPARSER          ; CALL ROUTINE TO VERIFY THAT THE
        JC      DE_2                    ; FONT PARSER FINISHED OK...
                                        ;
        PUSH    ES                      ; NOW THE DESIGNATE IS OVER...
        PUSH    DI                      ;
        MOV     CX,CPD_ACTIVE           ; CHECK IF ACTIVE_CP IS STILL VALID!
        CALL    FIND_CP                 ; TRY AND FIND CPD_ACTIVE?
        POP     DI                      ;
        POP     ES                      ;
        JNC     DE_0                    ;
        MOV     CX,-1                   ;
        MOV     CPD_ACTIVE,CX           ;
DE_0:   MOV     DESG_SEMAPHORE,ZERO     ;
        RET                             ;
                                        ;
DE_1:   OR      BUF.STATUS,TWELVE       ; Error>> NO DESGINATE START
        JUMP    DE_0                    ;
DE_2:   CALL    HANDLE_WRITE_ERROR      ; RESET ALL DESIGNATED INFORMATION
        OR      BUF.STATUS,FAIL         ; Error>> FONT DATA IS BAD
        JUMP    DE_0                    ;
DESIGNATE_END   ENDP                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       INVOKE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INVOKE_CP       PROC                    ;
        LES     DI,RH.REQUEST_PACKET    ; AND DI TO POINT TO REQUEST PACKET
        MOV     CX,RH.INVK_LENGTH       ; GET LENGTH OF REMAINING HEADER
                                        ;
        CMP     CX,TWO                  ; TEST IF LENGTH OF TABLE IS GREATER
        JNE     ICP_2                   ; THAN ONE CP!
                                        ;
        MOV     CX,RH.INVK_CP           ; GET THE CODE PAGE TO INVOKE
        MOV     DX,CX                   ; SAVE CP VALUE
        CMP     CX,-1                   ; TEST FOR INVALID CODE PAGE!
        JE      ICP_1A                  ;
                                        ;
        PUSH    CPD_ACTIVE              ; SAVE ACTIVE_CP, FOR POSSIBLE USE...
        MOV     CPD_ACTIVE,CX           ;
        CALL    TEST_CP                 ; TRY AND LOAD THE REQUESTED CP
        POP     CX                      ;
        JC      ICP_1AA                 ; IF ERROR, THEN RESTORE OLD CP
                                        ;
        CMP     CX,CPD_ACTIVE           ; TEST IF OLD CP=ACTIVE!!!
        JE      ICP_0A                  ;
                                        ;
        CALL    INVOKE_DATA             ; IF EVERYTHING OK, THEN LOAD DATA
        JC      ICP_2A                  ;
                                        ;
ICP_0A: CALL    SIGNAL_KBD_INVK         ; DX CONTAINS CODEPAGE
        JC      ICP_1                   ; IF CY THEN ERROR
        RET                             ;
                                        ;
ICP_1:  OR      BUF.STATUS,EIGHT        ; Error>> KEYB ERROR
        RET                             ;
ICP_1AA:MOV     CPD_ACTIVE,CX           ; PUT OLD CP BACK ACTIVE
ICP_1A: OR      BUF.STATUS,SEVEN        ; Error>> CODE PAGE NOT FOUND
        RET                             ;
ICP_2A: MOV     CPD_ACTIVE,CX           ;
ICP_2:  OR      BUF.STATUS,TEN          ; Error>> DEVICE ERROR
        RET                             ;
INVOKE_CP       ENDP                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       QUERY
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
QUERY_CP        PROC                    ;
        LES     DI,RH.REQUEST_PACKET    ; SETUP ADDRESSING TO HEADER
                                        ;
        MOV     CX,TWO                  ;
        MOV     RH.INVK_LENGTH,CX       ; CREATE RETURN 'N' VALUE
                                        ;
        CALL    TEST_CP                 ; FIND OUT IF CP DATA IS OK!
        MOV     CX,CPD_ACTIVE           ;
        JNC     QCP_A                   ;
        MOV     CX,-1                   ; MAKE THE ACTIVE REPONSE AS INVALID
                                        ;
QCP_A:  MOV     RH.INVK_CP,CX           ; SET THE CODE PAGE IN HEADER
        CMP     CX,-1                   ; TEST IF NO CP SPECIFIED?
        JE      QCP_0                   ;
        RET                             ;
                                        ;
QCP_0:  OR      BUF.STATUS,SEVEN        ; Error>> NOT CODE PAGE SPECIFIED
        RET                             ;
QUERY_CP        ENDP                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       QUERY LIST
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
QUERY_CP_LIST   PROC                    ;
        LES     DI,RH.REQUEST_PACKET    ; AND DI TO POINT TO REQUEST PACKET
                                        ;
        MOV     CX,CPD_HDWR_N           ;
        MOV     RH.QLST_N_HDWR,CX       ;
        ADD     CX,CPD_DESG_N           ;
        ADD     CX,TWO                  ; ACCOUNT FOR LENGTH OF 'N's
        ADD     CX,CX                   ;
        MOV     RH.QLST_LENGTH,CX       ; CREATE RETURN TABLE LENGTH
                                        ;
        PUSH    AX                      ;
        PUSH    BX                      ;
        PUSH    SI                      ;
        MOV     CX,CPD_HDWR_N           ;
        MOV     BX,2                    ;
        OR      CX,CX                   ;
        JE      QCP_3                   ;
QCP_2:  MOV     AX,CPD_HDWR_N[BX]       ;
        MOV     RH.QLST_N_HDWR[BX],AX   ;
        INC     BX                      ;
        INC     BX                      ;
        LOOP    QCP_2                   ;
                                        ;
QCP_3:  MOV     CX,CPD_DESG_N           ; SET TABLE ENTRY FOR DESIGNATE
        MOV     RH.QLST_N_HDWR[BX],CX   ;
        INC     BX                      ;
        INC     BX                      ;
                                        ;
        OR      CX,CX                   ;
        JE      QCP_4A                  ;
        MOV     SI,2                    ;
QCP_4:  MOV     AX,CPD_DESG_N[SI]       ;
        MOV     RH.QLST_N_HDWR[BX],AX   ;
        INC     BX                      ;
        INC     BX                      ;
        INC     SI                      ;
        INC     SI                      ;
        LOOP    QCP_4                   ;
QCP_4A: POP     SI                      ;
        POP     BX                      ;
        POP     AX                      ;
        RET                             ;
QCP_5:  OR      BUF.STATUS,SEVEN        ; Error>> NO CODE PAGE INVOKED
        RET                             ;
QCP_6:  OR      BUF.STATUS,TEN          ; Error>> DEVICE ERROR
        RET                             ;
QUERY_CP_LIST   ENDP                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       GET HARDWARE CODE PAGE TABLE
;
;       INPUT:
;               none
;       OUTPUT:
;               SI = pointer to HARDWARE table (n,h_cp1,h_cp2,...)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GET_HDWR_CP     PROC                    ;
        LEA     SI,CP_PNTER_TABLE       ;
        MOV     SI,[SI].HDWR_CP_STRUC   ;
        RET                             ;
GET_HDWR_CP     ENDP                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       GET DESIGNATE CODE PAGE TABLE
;
;       INPUT:  none
;       OUTPUT: SI = pointer to DESIGNATE table (n,d_cp1,d_cp2,...)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GET_DESG_CP     PROC                    ;
        LEA     SI,CP_PNTER_TABLE       ;
        MOV     SI,[SI].DESG_CP_STRUC   ;
        RET                             ;
GET_DESG_CP     ENDP                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       GET FONT POINTER TABLE
;
;       INPUT:
;               none
;       OUTPUT:
;               SI = pointer to FONTS table (pnter_cp1,pnter_cp2,...)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GET_FONT_CP     PROC                    ;
        LEA     SI,CP_PNTER_TABLE       ;
        MOV     SI,[SI].FONT_CP_STRUC   ;
        RET                             ;
GET_FONT_CP     ENDP                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       GET WRITE POINTER
;
;       INPUT:
;               none
;       OUTPUT:
;               SI = pointer to WRITE pointers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GET_WRITE_PNTR  PROC                    ;
        LEA     SI,CP_PNTER_TABLE       ;
        MOV     SI,[SI].WRITE_DATA_STRUC;
        RET                             ;
GET_WRITE_PNTR  ENDP                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       FIND ACTIVE CODE PAGE
;
;       INPUT:
;               CX      = code page to find
;       OUTPUT:
;              'CY'     = 0 if found, 1 if NOT
;               CX      = 0 for hdwr, 1 for designated
;               ES : DI = pointer to FONT data table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FIND_CP         PROC                    ;
        PUSH    AX                      ;
        PUSH    BX                      ;
        PUSH    SI                      ;
        MOV     AX,CX                   ;
        CALL    GET_DESG_CP             ; SET BX TO DESG TABLE INFO
        MOV     CX,[SI]                 ; GET THE NUMBER OF DESG CP's
        OR      CX,CX                   ;
        JZ      FCP_1                   ; MOVE ONTO DESG TEST WITH 0 CP's
        MOV     BX,TWO                  ; ELSE, USE SI TO POINT TO 1ST CP
FCP_0:  CMP     AX,[SI+BX]              ; SEARCH FOR CP MATCH
        JE      FCP_4                   ; CP MATCHED!!  SET DESG INFO & EXIT
        INC     BX                      ; ADVANCE SI POINTER TO NEXT CP
        INC     BX                      ;
        LOOP    FCP_0                   ; CHECK ACROSS ALL CP's IN TABLE
FCP_1:  CALL    GET_HDWR_CP             ; NOW, REPEAT SAME OPERATION
        MOV     CX,[SI]                 ; WITH THE HARDWARE CP's
        OR      CX,CX                   ;
        JZ      FCP_3                   ; IF THIS FAR, THEN SET ERROR FOR
        INC     SI                      ;
        INC     SI                      ; ADVANCE POINTER BY TWO...SINCE
        MOV     BX,ZERO                 ; PNTER'S DON'T HAVE 'n'...
FCP_2:  CMP     AX,[SI+BX]              ; SEARCH AGAIN FOR CP MATCH
        JE      FCP_5                   ; CP MATCHED!! SET HDWR INFO & EXIT
        INC     BX                      ; ADVANCE SI POINTER TO NEXT CP
        INC     BX                      ;
        LOOP    FCP_2                   ; REPEAT FOR ALL CP ENTRIES
FCP_3:  XOR     CX,CX                   ; SET RETURN VALUES TO ZERO
        XOR     DI,DI                   ;
        POP     SI                      ;
        POP     BX                      ;
        POP     AX                      ;
        STC                             ; CY=1 FOR ERROR
        RET                             ; EXIT
FCP_4:  MOV     CX,ONE                  ; ®®DESIGNATED CODE PAGE FOUND¯¯
        CALL    GET_FONT_CP             ; SET THE BX VALUE TO THE FONT DATA
        SUB     BX,2                    ; NORMALIZE BX VALUE;;;;;;;;;;;;;;;
        ADD     SI,BX                   ; FORMULATE THE SI INDEX BY ADDING
        ADD     SI,BX                   ; BX INDEX x 2 (dword FONT_PNTER)
        MOV     DI,[SI]                 ; TAKE OFFSET DATA FROM font_table
        MOV     ES,[SI+2]               ; AND SEGMENT ALSO!
        POP     SI                      ;
        POP     BX                      ;
        POP     AX                      ;
        CLC                             ; CY=0 FOR OK!
        RET                             ; EXIT
FCP_5:  XOR     CX,CX                   ; ®®HARDWARE CODE PAGE FOUND¯¯
        XOR     DI,DI                   ;
        POP     SI                      ;
        POP     BX                      ;
        POP     AX                      ;
        CLC                             ;
        RET                             ; EXIT
FIND_CP         ENDP                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       VERIFY_FPARSER A ROUTINE THAT CHECKS THE
;       FONT_BLOCKS FOR INCOMPLETE DESIGNATES?
;       IF SO, THEN AN ERROR OCCURRED...
;
;       INPUT:
;               FONT_PARSER should be completed parsing
;
;       OUTPUT:
;               CY = 0 if all is correct
;                    1 if one or more designates are incomplete
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VERIFY_FPARSER  PROC                    ;
        PUSH    AX                      ;
        PUSH    CX                      ;
        PUSH    ES                      ;
        PUSH    DI                      ;
                                        ;
        PUSH    CS                      ;
        POP     ES                      ;
                                        ;
        MOV     CX,CPD_REQ_DESG         ; CX = REQUESTED DESG CP's
        LEA     DI,FTB1                 ; SET DI TO POINT TO FIRST PARSING TABLE
                                        ;
VFP_4:  MOV     AX,[DI].FTB_STATUS      ; GET STATUS OF PARSING TABLE #n
        CMP     AX,FSTAT_COMPLETE       ; FIND OUT IF THIS CP COMPLETED?
        JE      VFP_6                   ;
                                        ;
        CMP     AX,FSTAT_FONT           ; CHECK IF AT LEAST THE FONT DATA FOUND
        JNE     VFP_8                   ; IF NOT, THEN AN ERROR OCCURRED....
        CMP     [DI].FTB_DLEFT,ZERO     ; IF SO, THEN NO DATA CAN BE LEFT....
        JNE     VFP_8                   ; OTHERWISE ANOTHER ERROR ?
VFP_6:  ADD     DI,TYPE FTBLK           ; MOVE POINTERS TO NEXT PARSING TABLE
        LOOP    VFP_4                   ;
        CLC                             ;
        JUMP    VFP_9                   ;
                                        ;
VFP_8:  STC                             ;
VFP_9:  POP     DI                      ;
        POP     ES                      ;
        POP     CX                      ;
        POP     AX                      ;
        RET                             ;
VERIFY_FPARSER  ENDP                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
