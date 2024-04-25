;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   WRITE ROUTINE FOR DESIGNATE WRITE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF1                                            ;
        %OUT .               ®WRITE   .INC¯
ENDIF                                          ;
        PUBLIC  REDUCED_SUPPORT                ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       WRITE DESIGNATE SUPPORT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DESG_WRITE      PROC                    ;
        CMP     CS:DESG_SEMAPHORE,ZERO  ; TEST IF DESIGNATE IS ON...
        JNE     DW_2                    ; PASS ONTO DOS
        CLC                             ;
        RET                             ;
DW_2:   CMP     CS:DESG_SEMAPHORE,ONE   ; CHECK IF PROPER DESIGNATE
        JE      DW_4                    ;
        OR      BUF.STATUS,TEN          ; IF NOT, THEN DEVICE ERROR
        STC                             ;
        RET                             ;
DW_4:   CALL    WRITE                   ;
        RET                             ;
DESG_WRITE   ENDP                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
REDUCED_SUPPORT EQU     $               ; THIS IS A MARKER FOR REDUCED CPS
                                        ; SUPPORT WITH 0 DESGINATES (CGA,MONO)
WRITE   PROC                            ;
        PUSH    DS                      ;
                                        ;
        PUSH    CS                      ;
        POP     DS                      ;
                                        ;
        PUSH    SI                    ;S;
        CLI                           ;S;
        MOV     SI,SP                 ;S;
        MOV     OLD_STACK_O,SI        ;S;
        MOV     SI,SS                 ;S;
        MOV     OLD_STACK_S,SI        ;S;
        MOV     AX,OFFSET STACK_START ;S;
        MOV     SI,CS                 ;S;
        MOV     SS,SI                 ;S;
        MOV     SP,AX                 ;S;
        STI                           ;S;
                                        ;
        LES     DI,DWORD PTR BUF.RH_PTRO; RESTORE ES:DI AS REQUEST HEADER PTR
        LEA     SI,FTABLE               ; GET BASE ADDRESS OF PARSER TABLE
                                        ;
        MOV     DS:[SI].FLAG,0          ; NO RESTART
        MOV     AX,RH.RH3_CNT           ;
        MOV     DS:[SI].BUFFER_LEN,AX   ; LENGTH OF REQUEST PACKET
                                        ;
        PUSH    SI                      ;
        LEA     SI,[SI].BUFFER_ADDR     ; PACKET ADDRESS
        MOV     AX,RH.RH3_DTAO          ;
        MOV     DS:[SI],AX              ;
        INC     SI                      ;
        INC     SI                      ;
        MOV     AX,RH.RH3_DTAS          ;
        MOV     DS:[SI],AX              ;
        POP     SI                      ;
                                        ;
        CALL    FONT_PARSER             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       FONT PARSER HAS BEEN CALLED, NOW CHECK ALL OF THE
;       APPROPRIATE TABLES FOR DATA INFORMATION, ERROR
;       CONDITIONS, etc....
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        LEA     SI,FTABLE               ; GET BASE ADDRESS OF PARSER TABLE
        MOV     CX,[SI].NUM_FTBLK       ; CX = NUMBER OF PARSING TABLES
        LEA     SI,FTB1                 ; THEN SET SI = FIRST PARSING TABLE
                                        ;
W_1:    MOV     AX,DS:[SI].FTB_STATUS   ;
        CMP     AX,0FFF0H               ; CHECK THE PARSER STATUS
        JNB     W_3                     ;
                                        ;
        OR      BUF.STATUS,FAIL         ; IF THE PARSER FAILED ON THE DATA
        MOV     RH.RHC_STA,AX           ; FILE, THEN SET FLAG AND...
        CALL    HANDLE_WRITE_ERROR      ;
        JUMP    W_7                     ; ERROR HAS BEEN FOUND..DON'T CONTINUE
                                        ;
W_3:    CMP     AX,FSTAT_FONT           ;
        JNE     W_6                     ;
                                        ;
        MOV     AX,DS:[SI].FTB_DLEN     ;
        CALL    HANDLE_DATA_WRITE       ;
                                        ;
W_6:    ADD     SI,TYPE FTBLK           ; ADVANCE SI POINTER TO NEXT TABLE
        LOOP    W_1                     ; CHECK OUT ALL PARSING TABLES
                                        ;
W_7:    CLI                           ;S;
        MOV     SI,OLD_STACK_S        ;S;
        MOV     AX,OLD_STACK_O        ;S;
        MOV     SS,SI                 ;S;
        MOV     SP,AX                 ;S;
        STI                           ;S;
        POP     SI                    ;S;
        POP     DS                      ;
        STC                             ; INDICATE NOT TO PASS ON DATA
        RET                             ;
WRITE   ENDP                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       THIS IS USED TO SET THE CPS DRIVER IN THE CASE OF A
;       DESIGNATE ERROR.  IT WILL RESET THE DESIGNATED CP's
;       TO INVALID, AND IF THE ACTIVE_CP WAS A DESIGNATED CP,
;       THEN IT TOO BECOMES INVALID.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HANDLE_WRITE_ERROR      PROC            ;
        PUSH    DS                      ;
        PUSH    AX                      ;
        PUSH    CX                      ;
        PUSH    SI                      ;
                                        ;
        MOV     AX,-1                   ; ...SET DESGINATE LIST TO (-1)'S
        MOV     CX,CPD_REQ_DESG         ; GET NUMBER AND
        MOV     SI,2                    ; +2
HWE_3:  CMP     CPD_REQ_DESG[SI],AX     ; CHECK IF REQUESTED PREP WAS VALID
        JE      HWE_4                   ; IF REQUESTED WAS VALID, THEN THE ERROR
        MOV     CPD_DESG_N[SI],AX       ; SETS ACTUAL PREP LIST ENTRY TO INVALID
HWE_4:  INC     SI                      ;
        INC     SI                      ;
        LOOP    HWE_3                   ; REPEAT FOR #DESIGNATES
                                        ;
        MOV     CX,CPD_ACTIVE           ;
        CALL    FIND_CP                 ; CHECK IF ACTIVE_CP=STILL VALID
        JNC     HWE_2                   ;
        MOV     CX,-1                   ;
        MOV     CPD_ACTIVE,CX           ;
                                        ;
HWE_2:  POP     SI                      ;
        POP     CX                      ;
        POP     AX                      ;
        POP     DS                      ;
        RET                             ;
HANDLE_WRITE_ERROR      ENDP            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       THIS SUBROUTINE TAKES THE DATA INFORMATION ISOLATED
;       BY THE FONT PARSER AND MOVES INTO THE INTERNAL FONT
;       FONT BUFFERS.  IT COPIES THE DATA BASED ON THE SIZE
;       OF THE INTERNAL FONTS & THE REQUIRED FONT SIZES.
;
;
;       INPUT:
;               AX = LENGTH OF DATA
;               CX = TABLE # TO PARSE
;               DS:SI = POINTER TO 'FTBLK'
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NUM_DATA_FONTS  DW      ?               ;
TABLE_INDEX     DW      ?               ;
LEN_DATA        DW      ?               ;
INDEX_WRITE_PNTER DW    ?               ;
                                        ;
HANDLE_DATA_WRITE       PROC            ;
        PUSH    AX                      ;
        PUSH    BX                      ;
        PUSH    CX                      ;
        PUSH    SI                      ;
        PUSH    DI                      ;
        PUSH    DS                      ;
        PUSH    ES                      ;
                                        ;
        PUSH    CX                      ;
        MOV     CX,DS:[SI].FTB_FONTS    ; READ IN #FONTS FROM DATA FILE
        MOV     CS:NUM_DATA_FONTS,CX    ;
        POP     CX                      ;
                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       ROUTINE TO FIND TABLE_INDEX FOR DATA WRITE'S
;       THIS WAS ADDED TO ACCOUNT FOR A REPLACEMENT
;       TECHNIQUE APPROACH.....(Sept 3/86)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        PUSH    AX                      ;
        PUSH    CX                      ;
        PUSH    ES                      ;
                                        ;
        PUSH    CS                      ;
        POP     ES                      ;
        MOV     AX,DS:[SI].FTB_CP       ; GET THE CODE PAGE OF THIS FONT BLOCK
        MOV     CX,CPD_DESG_N           ; GET THE NUMBER OF CP's TO CHECK
        MOV     DI,TWO                  ;
BBB_0:  CMP     AX,CPD_DESG_N[DI]       ; LOOKING FOR A MATCHED CODE PAGE
        JE      BBB_1                   ;
        INC     DI                      ;
        INC     DI                      ;
        LOOP    BBB_0                   ;
                                        ;
;;;;;;INVALID???;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;
BBB_1:  MOV     DI,CPD_DESG_N           ;
        SUB     DI,CX                   ;
        MOV     CS:TABLE_INDEX,DI       ;
BBB_2:  POP     ES                      ;
        POP     CX                      ;
        POP     AX                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        PUSH    SI                      ;
        LEA     SI,FTABLE               ; GET BASE ADDRESS OF PARSER TABLE
        SHL     DI,1                    ;
        SHL     DI,1                    ; MULTIPLY INDEX BY FOUR..SEG:OFFSET
        CALL    GET_WRITE_PNTR          ; GET LOCATION OF 1ST FONT_WRITE PNTER
        ADD     DI,SI                   ; DI NOW IS THE POINTER TO WRITE_START
        POP     SI                      ;
                                        ;
        MOV     CS:INDEX_WRITE_PNTER,DI ; SAVE ADDRESS OF INDEX WRITE PNTER
                                        ;
        MOV     ES,CS:[DI+2]            ; SET ES : DI WITH WRITE POINTER!
        MOV     DI,CS:[DI]              ;
                                        ;
        MOV     CX,DS:[SI].FTB_DAHI     ; GET SEGMENT OF DATA
        MOV     SI,DS:[SI].FTB_DALO     ; GET OFFSET OF DATA
        MOV     DS,CX                   ;
                                        ; <<SETUP DESTINATION INFO>>
        MOV     CX,AX                   ; SAVE LENGTH OF DATA TO COPY
        MOV     CS:LEN_DATA,CX          ; SAVE THIS VALUE
        AND     CX,CX                   ; TEST LENGTH OF DATA
        JNZ     TEMP_0                  ;
        JUMP    HDW_8                   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NOW  DS : SI  POINTS TO SOURCE DATA INFORMATION,
;            ES : DI  POINTS TO THE DESTINATION BUFFER!
;            CX = NUMBER OF INFORMATION BYTES AVAILABLE
;       THE DATA MUST BE CHECKED FOR THE FONT RESOLUTIONS
;       AS THEY ARE TO FIT INTO THE INTERNAL BUFFERS.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TEMP_0: PUSH    AX                      ;
        PUSH    BX                      ;
        PUSH    CX                      ;
        PUSH    SI                      ;
        PUSH    DI                      ;
                                        ;
        LEA     BX,CPD_FONT_DATA        ; TEST IF THERE IS OUTSTANDING DATA
        ADD     BX,CS:TABLE_INDEX       ; FOR INFORMATION TO COPY or SKIP OVER.
        ADD     BX,CS:TABLE_INDEX       ; (ACCOUNT FOR WORD VALUE)
        MOV     AX,CS:[BX]              ;
        OR      AX,AX                   ;
        JE      HDW_00                  ; IF NOTHING TO CONSIDER, THEN MOVE ON
        TEST    AX,8000H ;;;;SKIP/COPY;;;;; TEST IF OUTSTANDING DATA TO COPY/SKIP
        JNZ     HDW_P0                  ;
        MOV     CX,AX                   ; SET VALUE IN CX....
        MOV     AX,CS:NUM_DATA_FONTS    ;
        PUSH    AX                      ;
        JUMP    HDW_3AA                 ;
HDW_P0: AND     AX,7FFFH                ; STRIP OFF FIRST BIT...
        MOV     CX,AX                   ;
        MOV     AX,CS:NUM_DATA_FONTS    ;
        PUSH    AX                      ;
        JUMP    HDW_5AA                 ;
                                        ;
HDW_00: MOV     CX,CS:NUM_DATA_FONTS    ;
HDW_0:  CMP     CS:LEN_DATA,0           ; TEST IF THERE IS ANY DATA LEFT?
        JNE     HDW_0A                  ;
        JUMP    HDW_6                   ; IF 0 LEFT...THEN END...
                                        ;
HDW_0A: MOV     AL,[SI]                 ; GET #ROWS FROM DATA
        PUSH    CX                      ; SAVE COUNT
        MOV     CX,NUM_FONT_PRIORITY    ;
        LEA     BX,FONT_PRIORITY        ; SET DI TO START OF TABLE
HDW_1:  CMP     AL,CS:[BX]              ;
        JE      HDW_3                   ; IF EQUAL, THEN ALREADY IN TABLE
        INC     BX                      ; OTHERWISE, TAKE THIS MODES FONT RES
        LOOP    HDW_1                   ; AND COMPARE AGAINST NEXT PRIOR.VALUE
        JUMP    HDW_5                   ; IF NO MATCH, THEN IGNORE THIS FONT!!!
                                        ;
HDW_3:  XOR     AH,AH                   ; FONT SIZE NEEDED...GET IT!
        MOV     CX,[SI+4]               ; GET THE #CHARACTERS IN TABLE
        PUSH    DX                      ;
        MUL     CX                      ;
        POP     DX                      ;
        ADD     AX,SIX                  ; ACCOUNT FOR DATA HEADER
        MOV     CX,AX                   ; SET COUNT INTO CX....
                                        ;
HDW_3AA:CMP     CX,CS:LEN_DATA          ; TEST IF SUPPLIED DATA>=NEEDED
        JBE     HDW_3A                  ;
        SUB     CX,CS:LEN_DATA          ; IF NOT ENOUGH DATA HERE, THEN FORWARD
        MOV     AX,CX                   ; VALUE TO NEXT DATA CALL.
        CALL    SET_CPD_FONT_DATA       ;
        MOV     CX,CS:LEN_DATA          ;
        JUMP    HDW_3B                  ;
                                        ;
HDW_3A: XOR     AX,AX                   ;
        CALL    SET_CPD_FONT_DATA       ;
HDW_3B: SUB     CS:LEN_DATA,CX          ;
        CLD                             ;
        REP     MOVSB                   ; MOVE THAT RESOLUTION IN...
                                        ;
HDW_4:  POP     CX                      ; RESTORE #FONTS IN DATA
        LOOP    HDW_0                   ;
        JUMP    HDW_6                   ;
                                        ;
HDW_5:  XOR     AH,AH                   ; FONT SIZE NEEDED...GET IT!
        MOV     CX,[SI+4]               ; GET THE #CHARACTERS IN TABLE
        PUSH    DX                      ;
        MUL     CX                      ;
        POP     DX                      ;
        ADD     AX,SIX                  ; ACCOUNT FOR DATA HEADER
        MOV     CX,AX                   ; PUT IN CX FOR NOW
                                        ;
HDW_5AA:CMP     CX,CS:LEN_DATA          ; TEST IF SUPPLIED DATA>=NEEDED
        JBE     HDW_5A                  ;
        SUB     CX,CS:LEN_DATA          ; IF NOT ENOUGH DATA HERE, THEN FORWARD
        MOV     AX,CX                   ; VALUE TO NEXT DATA CALL.
        OR      AX,8000H                ; SET TO SKIP NEXT DATA....
        CALL    SET_CPD_FONT_DATA       ;
        MOV     CX,CS:LEN_DATA          ;
        JUMP    HDW_5B                  ;
                                        ;
HDW_5A: XOR     AX,AX                   ;
        CALL    SET_CPD_FONT_DATA       ;
HDW_5B: SUB     CS:LEN_DATA,CX          ;
        ADD     SI,CX                   ; ADVANCE SOURCE POINTER OVER THIS FONT
        JUMP    HDW_4                   ;
                                        ;
HDW_6:  MOV     SI,CS:INDEX_WRITE_PNTER ;
        MOV     CS:[SI],DI              ;
        MOV     CS:[SI+2],ES            ;
                                        ;
        POP     DI                      ;
        POP     SI                      ;
        POP     CX                      ;
        POP     BX                      ;
        POP     AX                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HDW_8:  POP     ES                      ;
        POP     DS                      ;
        POP     DI                      ;
        POP     SI                      ;
        POP     CX                      ;
        POP     BX                      ;
        POP     AX                      ;
        RET                             ;
HANDLE_DATA_WRITE       ENDP            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       SET_CPD_FONT_DATA
;
;       THIS ROUTINE IS USED TO SET THE COPY/SKIP VALUE
;       CONTAINED IN 'AX'.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_CPD_FONT_DATA       PROC            ;
        PUSH    SI                      ;
        MOV     SI,CS:TABLE_INDEX       ;
        ADD     SI,SI                   ;
        MOV     CS:CPD_FONT_DATA.[SI],AX;
        POP     SI                      ;
        RET                             ;
SET_CPD_FONT_DATA       ENDP            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
