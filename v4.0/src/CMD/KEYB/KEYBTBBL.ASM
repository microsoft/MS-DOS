
        PAGE    ,132
        TITLE   DOS KEYB Command  -  Transient Command Processing

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBTBBL.ASM
;; ----------
;;
;; Description:
;; ------------
;;       Build SHARED_DATA_AREA with parameters specified
;;       in KEYBCMD.ASM
;;
;; Documentation Reference:
;; ------------------------
;;       None
;;
;; Procedures Contained in This File:
;; ----------------------------------
;;     TABLE_BUILD: Build the header sections of the SHARED_DATA_AREA
;;     STATE_BUILD: Build the state sections in the table area
;;     FIND_CP_TABLE: Given the language and code page parm, determine the
;;            offset of the code page table in KEYBOARD.SYS
;;
;; Include Files Required:
;; -----------------------
;;       KEYBSHAR.INC
;;       KEYBSYS.INC
;;       KEYBDCL.INC
;;       KEYBI2F.INC
;;
;; External Procedure References:
;; ------------------------------
;;       None
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
        PUBLIC TABLE_BUILD             ;;
        PUBLIC FIND_CP_TABLE           ;;
        PUBLIC CPN_INVALID             ;;
        PUBLIC SD_LENGTH               ;;
                                       ;;
CODE    SEGMENT PUBLIC 'CODE'          ;;
                                       ;;
        INCLUDE KEYBEQU.INC            ;;
        INCLUDE KEYBSHAR.INC           ;;
        INCLUDE KEYBSYS.INC            ;;
        INCLUDE KEYBCMD.INC            ;;
        INCLUDE KEYBDCL.INC            ;;
        INCLUDE COMMSUBS.INC           ;;
        INCLUDE KEYBCPSD.INC           ;;
                                       ;;
        ASSUME  CS:CODE,DS:CODE        ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: TABLE_BUILD
;;
;; Description:
;;     Create the table area within the shared data structure. Each
;;     table is made up of a descriptor plus the state sections.
;;     Translate tables are found in the Keyboard definition file and are
;;     copied into the shared data area by means of the STATE_BUILD
;;     routine.
;;
;; Input Registers:
;;     DS - points to our data segment
;;     ES - points to our data segment
;;     BP - points at beginning of CMD_PARM_LIST
;;
;;     SHARED_DATA_STR must be allocated in memory
;;
;;     The following variables must also be passed from KEYB_COMMAND
;;         KEYBSYS_FILE_HANDLE is set to file handle after opening file
;;         CP_TAB_OFFSET is the offset of the CP table in the SHARED_DATA_AREA
;;         STATE_LOGIC_OFFSET is the offset of the state section in the SHARED_DATA_AREA
;;         SYS_CODE_PAGE is the binary representation of the system CP
;;         KEYBCMD_LANG_ENTRY_PTR is a pointer to the lang entry in KEY DEF file
;;         DESIG_CP_BUFFER is the buffer which holds a list of designated CPs
;;         DESIG_CP_OFFSET:WORD is the offset of that list
;;         NUM_DESIG_CP is the number of CPs designated
;;         FILE_BUFFER is the buffer to read in the KEY DEF file
;**********CNS ***************************************
;;         ID_PTR_SIZE is the size of the ID ptr structure
;**********CNS ***************************************
;;         LANG_PTR_SIZE is the size of the lang ptr structure
;;         CP_PTR_SIZE is the size of the CP ptr structure
;;         NUM_CP is the number of CPs in the KEYB DEF file for that lang
;;         SHARED_AREA_PTR segment and offset of the SHARED_DATA_AREA
;;
;;
;; Output Registers:
;;     CX - RETURN_CODE :=  0  - Table build successful
;;                          1  - Table build unsuccessful - ERROR 1
;;                                     (Invalid language parm)
;;                          2  - Table build unsuccessful - ERROR 2
;;                                     (Invalid Code Page parm)
;;                          3  - Table build unsuccessful - ERROR 3
;;                                     (Machine type unavaliable)
;;                          4  - Table build unsuccessful - ERROR 4
;;                                     (Bad or missing keyboard def file)
;;                          5  - Table build unsuccessful - ERROR 5
;;                                     (Memory overflow occurred)
;; Logic:
;;     Calculate Offset difference between TEMP and SHARED_DATA_AREAs
;;     Get LANGUAGE_PARM and CODE_PAGE_PARM from parm list
;;     Call FIND_CP_TABLE := Determine whether CP is valid for given language
;;     IF CP is valid THEN
;;        Store them in the SHARED_DATA_AREA
;;        Prepare to read Keyboard definition file by LSEEKing to the top
;;        READ the header
;;        Store maximum table values for calculation of RES_END
;;        Set DI to point at TABLE_AREA within SHARED_DATA_AREA
;;        FOR the state logic section of the specified language:
;;           IF STATE_LOGIC_PTR is not -1 THEN
;;               LSEEK to state logic section in keyboard definition file
;;               READ the state logic section into the TABLE_AREA
;;               Set the hot keyb scan codes
;;               Set the LOGIC_PTR in the header
;;        FOR the common translate section:
;;           IF Length parameter is not 0 THEN
;;               Build state
;;               Set the COMMON_XLAT_PTR in the header
;;        FOR the specific translate sections:
;;        Establish addressibility to list of designated code pages
;;        FOR each code page
;;           IF CP_ENTRY_PTR is not -1 THEN
;;               Determine offset of CP table in Keyb Def file
;;               IF CP table not avaliable THEN
;;                   Set CPN_INVALID flag
;;               ELSE
;;                   LSEEK to CPn state section in keyboard definition file
;;                   IF this is the invoked code page THEN
;;                       Set ACTIVE_XLAT_PTR in SHARED_DATA_AREA
;;                   Update RESIDENT_END ptr
;;                   Build state
;;        Update RESIDENT_END ptr
;;        End
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                               ;;
FB                   EQU   FILE_BUFFER         ;;
KB_MASK              EQU   02H                 ;;
                                               ;;
FIRST_XLAT_TAB       DW    0                   ;;
NEXT_SECT_PTR        DW    -1                  ;;
                                               ;;
MAX_COM_SIZE         DW    ?                   ;;
MAX_SPEC_SIZE        DW    ?                   ;;
MAX_LOGIC_SIZE       DW    ?                   ;;
                                               ;;
RESIDENT_END_ACC     DW    0                   ;;
SA_HEADER_SIZE       DW    SIZE SHARED_DATA_STR;;
PARM_LIST_OFFSET     DW    ?                   ;;
;********************CNS*************************
TB_ID_PARM           DW    0
;********************CNS*************************
TB_LANGUAGE_PARM     DW    0                   ;;
TB_CODE_PAGE_PARM    DW    0                   ;;
                                               ;;
CPN_INVALID          DW    0                   ;;
                                               ;;
KEYB_INSTALLED       DW    0                   ;;
SD_AREA_DIFFERENCE   DW    0                   ;;
SD_LENGTH            DW    2000                ;;
                                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                          ;;
TABLE_BUILD          PROC NEAR            ;;
                                          ;;
        MOV   AX,OFFSET SD_SOURCE_PTR     ;;    Setup the difference
        SUB   AX,OFFSET SD_DEST_PTR       ;;     value used to calculate
        MOV   SD_AREA_DIFFERENCE,AX       ;;      new ptr values for
                                          ;;        SHARED_DATA_AREA
        MOV   AX,[BP].ID_PARM             ;; WGR Get id parameter              ;AN000
        MOV   TB_ID_PARM,AX               ;; WGR                               ;AN000
        MOV   AX,[BP].LANGUAGE_PARM       ;;    Get language parameter
        MOV   TB_LANGUAGE_PARM,AX         ;;
        MOV   BX,[BP].CODE_PAGE_PARM      ;;    Get code page parameter
        MOV   TB_CODE_PAGE_PARM,BX        ;;
                                          ;;  Make sure code page is
        CALL  FIND_CP_TABLE               ;;   valid for the language
        CMP   CX,0                        ;; Test return codes
        JE    TB_CHECK_CONTINUE1          ;; IF code page is found
        JMP   TB_ERROR6                   ;;               for language THEN
                                          ;;
TB_CHECK_CONTINUE1:                       ;;;;;;;;
        MOV   BP,OFFSET SD_SOURCE_PTR           ;;    Put language parm and    ;AN000
        MOV   AX,TB_ID_PARM                     ;; WGR id parm and..           ;AN000
        MOV   ES:[BP].INVOKED_KBD_ID,AX         ;; WGR
        MOV   BX,TB_CODE_PAGE_PARM              ;;
        MOV   ES:[BP].INVOKED_CP_TABLE,BX       ;;;;;; code page parm into the
        MOV   AX,TB_LANGUAGE_PARM                   ;;  SHARED_DATA_AREA
        MOV   WORD PTR ES:[BP].ACTIVE_LANGUAGE,AX   ;;
                                                    ;;
        MOV   BX,KEYBSYS_FILE_HANDLE   ;;;;;;;;;;;;;;; Get handle
        XOR   DX,DX                    ;; LSEEK file pointer
        XOR   CX,CX                    ;;    back to top of file
        MOV   AH,42H                   ;;
        MOV   AL,0                     ;; If no problem with
        INT   21H                      ;;     Keyboard Def file THEN
        JNC   TB_START                 ;;
        JMP   TB_ERROR4                ;;
                                       ;;
TB_START:                              ;; Else
        XOR   DI,DI                    ;; Set number
        LEA   CX,[DI].KH_MAX_LOGIC_SZ+2;;        bytes to read header
        MOV   DX,OFFSET FILE_BUFFER    ;; Move contents into file buffer
        MOV   AH,3FH                   ;;     READ
        PUSH  CS                       ;;
        POP   DS                       ;;
        INT   21H                      ;;        File
        JNC   TB_CONTINUE1             ;;
        JMP   TB_ERROR4                ;;
                                       ;;
TB_CONTINUE1:                          ;;
        CMP   CX,AX                    ;;
        JE    TB_ERROR_CHECK1          ;;
        MOV   CX,4                     ;;
        JMP   TB_CPN_INVALID           ;;
                                       ;;
TB_ERROR_CHECK1:                       ;;
        MOV   CX,FB.KH_MAX_COM_SZ      ;;  Save values for RESIDENT_END
        MOV   MAX_COM_SIZE,CX          ;;           calculation
        MOV   CX,FB.KH_MAX_SPEC_SZ     ;;
        MOV   MAX_SPEC_SIZE,CX         ;;
        MOV   CX,FB.KH_MAX_LOGIC_SZ    ;;
        MOV   MAX_LOGIC_SIZE,CX        ;;
                                       ;;
        LEA   DI,[BP].TABLE_AREA       ;; Point at beginning of table area
                                       ;;           DI ---> TABLE_AREA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   ** FOR STATE LOGIC SECTION FOR LANG **
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                               ;;
TB_STATE_BEGIN:                                ;;
        MOV   BX,KEYBSYS_FILE_HANDLE           ;; Get handle
        MOV   CX,WORD PTR STATE_LOGIC_OFFSET+2 ;;
        MOV   DX,WORD PTR STATE_LOGIC_OFFSET   ;; Get LSEEK file pointer
                                               ;;
        CMP   DX,-1                    ;;;;;;;;;; If no language table then
        JNE   TB_STATE_CONTINUE1       ;;           jump to code page begin
        JMP   TB_CP_BEGIN              ;;
                                       ;;
TB_STATE_CONTINUE1:                    ;; Else
        MOV   AH,42H                   ;; LSEEK to beginning of state logic sect
        MOV   AL,0                     ;; If no problem with
        INT   21H                      ;;     Keyboard Def file THEN
        JNC   TB_STATE_CONTINUE2       ;;
        JMP   TB_ERROR4                ;;
                                       ;;;;;;;;;;
TB_STATE_CONTINUE2:                            ;;
        MOV   DX,AX                            ;;
        MOV   WORD PTR SB_STATE_OFFSET+2,CX    ;;  Save the offset of the
        MOV   WORD PTR SB_STATE_OFFSET,DX      ;;     states in Keyb Def file
                                               ;;
        SUB   DI,SD_AREA_DIFFERENCE            ;;  Adjust for relocation
        MOV   ES:[BP].LOGIC_PTR,DI     ;;;;;;;;;;  Set because this is state
        ADD   DI,SD_AREA_DIFFERENCE    ;;  Adjust for relocation
                                       ;;
        MOV   CX,4                     ;; Set number bytes to read length and
                                       ;;    special features
        MOV   DX,OFFSET FILE_BUFFER    ;; Set the buffer address
        MOV   AH,3FH                   ;; Read from the Keyb Def file
        INT   21H                      ;;
        JNC   TB_STATE_CONTINUE3       ;;
        JMP   TB_ERROR4                ;;
                                       ;;
TB_STATE_CONTINUE3:                    ;;
        CMP   CX,AX                    ;;
        JE    TB_ERROR_CHECK2          ;;
        MOV   CX,4                     ;;
        JMP   TB_CPN_INVALID           ;;
                                       ;;;;;
TB_ERROR_CHECK2:                          ;;
        MOV   AX,FB.KT_SPECIAL_FEATURES   ;; Save the special features in the
        MOV   ES:[BP].SPECIAL_FEATURES,AX ;;  SHARED_DATA_AREA
                                          ;;
        CMP   HW_TYPE,JR_KB               ;;;;;;;;
        JNE   USE_F1_F2                         ;;
        TEST  AX,JR_HOT_KEY_1_2                 ;;
        JZ    USE_F1_F2                         ;;
        MOV   ES:[BP].HOT_KEY_ON_SCAN,ONE_SCAN  ;;
        MOV   ES:[BP].HOT_KEY_OFF_SCAN,TWO_SCAN ;;
        JMP   HOT_KEY_SET                       ;;
                                                ;;
USE_F1_F2:                                      ;;
        MOV   ES:[BP].HOT_KEY_ON_SCAN,F1_SCAN   ;;
        MOV   ES:[BP].HOT_KEY_OFF_SCAN,F2_SCAN  ;;
                                                ;;
HOT_KEY_SET:                              ;;;;;;;;
        MOV   CX,FB.KT_LOGIC_LEN          ;; Set length of section to read
        CMP   CX,0                        ;;
        JNE   TB_STATE_CONTINUE4          ;;
        MOV   CX,-1                    ;;;;;
        MOV   ES:[BP].LOGIC_PTR,CX     ;;
        JMP   SB_COMM_BEGIN            ;;
                                       ;;
TB_STATE_CONTINUE4:                    ;;
        MOV   ES:[DI],CX               ;; Store length parameter in
        ADD   DI,2                     ;;                  SHARED_DATA_AREA
        MOV   CX,FB.KT_SPECIAL_FEATURES;; Save the special features
        MOV   ES:[DI],CX               ;;
        ADD   DI,2                     ;;
        MOV   CX,FB.KT_LOGIC_LEN       ;; Set length of section to read
        SUB   CX,4                     ;; Adjust for what we have already read
        MOV   DX,DI                    ;; Set the address of SHARED_DATA_AREA
        PUSH  ES                       ;;
        POP   DS                       ;;
        MOV   AH,3FH                   ;; Read logic section from the
        INT   21H                      ;;      Keyb Def file
        PUSH  CS                       ;;
        POP   DS                       ;;
        JNC   TB_STATE_CONTINUE5       ;;
        JMP   TB_ERROR4                ;;
                                       ;;
TB_STATE_CONTINUE5:                    ;;
        CMP   CX,AX                    ;;
        JE    TB_ERROR_CHECK3          ;;
        MOV   CX,4                     ;;
        JMP   TB_CPN_INVALID           ;;
                                       ;;
TB_ERROR_CHECK3:                       ;;
        ADD   DI,CX                    ;; Set DI at new beginning of area
                                       ;;              TABLE_AREA
                                       ;;              STATE_LOGIC
        MOV   CX,RESIDENT_END_ACC      ;;      DI --->
        ADD   CX,SA_HEADER_SIZE        ;;
        ADD   CX,MAX_LOGIC_SIZE        ;;
        MOV   RESIDENT_END_ACC,CX      ;;  Refresh resident end size
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   ** FOR COMMON TRANSLATE SECTION FOR LANG **
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
SB_COMM_BEGIN:                         ;;
        MOV   CX,SIZE KEYBSYS_XLAT_SECT-1 ;; Set number bytes to read header
        MOV   DX,DI                    ;; Set the SHARED_DATA_AREA address
        PUSH  ES                       ;;
        POP   DS                       ;;
        MOV   AH,3FH                   ;; Read from the Keyb Def file
        INT   21H                      ;;
        PUSH  CS                       ;;
        POP   DS                       ;;
        JNC   TB_STATE_CONTINUE6       ;;
        JMP   TB_ERROR4                ;;
                                       ;;
TB_STATE_CONTINUE6:                    ;;
        MOV   CX,ES:[DI].KX_SECTION_LEN;; Set length of section to read
        CMP   CX,0                     ;;
        JNE   TB_STATE_CONTINUE7       ;;
        JMP   TB_CP_BEGIN              ;;
                                       ;;;;;;;
TB_STATE_CONTINUE7:                         ;;
        MOV   CX,WORD PTR SB_STATE_OFFSET   ;;  Save the offset of the
        ADD   CX,FB.KT_LOGIC_LEN            ;;
        MOV   WORD PTR SB_STATE_OFFSET,CX   ;;  Save the offset of the
        SUB   DI,SD_AREA_DIFFERENCE         ;;  Adjust for relocation
        MOV   ES:[BP].COMMON_XLAT_PTR,DI    ;;
        ADD   DI,SD_AREA_DIFFERENCE         ;;  Adjust for relocation
                                       ;;;;;;;
        CALL  STATE_BUILD              ;;
                                       ;; DI set at new beginning of area
                                       ;;              TABLE_AREA
                                       ;;              STATE_LOGIC
                                       ;;              COMMON_XLAT_SECTION
        MOV   CX,RESIDENT_END_ACC      ;;
        ADD   CX,MAX_COM_SIZE          ;;
        MOV   RESIDENT_END_ACC,CX      ;;  Refresh resident end size
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    FOR ALL DESIGNATED OR INVOKED CODE PAGES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                       ;;
TB_CP_BEGIN:                                           ;; Get the offset to
        MOV   CX,OFFSET DESIG_CP_BUFFER.DESIG_CP_ENTRY ;; the beginning of the
        MOV   DESIG_CP_OFFSET,CX                       ;; table of designated
                                                   ;;;;;; code pages
TB_CPN_BEGIN:                                      ;;
        MOV   AX,WORD PTR ES:[BP].ACTIVE_LANGUAGE  ;; Get the active language
        MOV   CX,NUM_DESIG_CP          ;;;;;;;;;;;;;; Get the number of CPs
        CMP   CX,0                     ;; IF we have done all requested CPs
        JNE   TB_CPN_VALID1            ;;
        JMP   TB_DONE                  ;;   Then done
                                       ;;
TB_CPN_VALID1:                         ;;
        MOV   SI,[DESIG_CP_OFFSET]     ;;
        MOV   BX,[SI]                  ;; Get the CP
        CMP   BX,-1                    ;;
        JNE   TB_CPN_CONTINUE1         ;;
        JMP   TB_CPN_REPEAT            ;;
                                       ;;
TB_CPN_CONTINUE1:                      ;; ELSE
        PUSH  DI                       ;;
        CALL  FIND_CP_TABLE            ;;   Find offset of code page table
        POP   DI                       ;;
                                       ;;
        CMP   CX,0                     ;; Test return codes
        JE    TB_CPN_VALID             ;; IF code page is not found for language
        MOV   CPN_INVALID,CX           ;;       Set flag and go to next CP
        JMP   TB_CPN_REPEAT            ;; Else
                                       ;;
TB_CPN_VALID:                          ;;;;;;
        MOV   BX,KEYBSYS_FILE_HANDLE       ;; Get handle
        MOV   CX,WORD PTR CP_TAB_OFFSET+2  ;; Get offset of the code page
        MOV   DX,WORD PTR CP_TAB_OFFSET    ;;    in the Keyb Def file
                                           ;;
        CMP   DX,-1                    ;;;;;; Test if code page is blank
        JNE   TB_CPN_CONTINUE2         ;;
        JMP   TB_CPN_REPEAT            ;; If it is then go get next CP
                                       ;;
TB_CPN_CONTINUE2:                      ;;
        MOV   AH,42H                   ;; LSEEK to table in Keyb Def file
        MOV   AL,0                     ;; If no problem with
        INT   21H                      ;;     Keyb Def file Then
        JNC   TB_CPN_CONTINUE3         ;;
        JMP   TB_ERROR4                ;;
                                       ;;;;;;;;;;
TB_CPN_CONTINUE3:                              ;;
        MOV   DX,AX                            ;;
        MOV   WORD PTR SB_STATE_OFFSET+2,CX    ;;  Save the offset of the
        MOV   WORD PTR SB_STATE_OFFSET,DX      ;;      states in Keyb Def file
                                               ;;
        MOV   CX,TB_CODE_PAGE_PARM          ;;;;;  If this code page is the
        MOV   SI,[DESIG_CP_OFFSET]          ;;        invoked code page
        CMP   CX,[SI]                       ;;
        JNE   TB_CPN_CONTINUE4              ;;  Then
                                            ;;
        SUB   DI,SD_AREA_DIFFERENCE         ;;  Adjust for relocation
        MOV   ES:[BP].ACTIVE_XLAT_PTR,DI    ;;  Set active xlat section
        ADD   DI,SD_AREA_DIFFERENCE         ;;  Adjust for relocation
                                       ;;;;;;;
TB_CPN_CONTINUE4:                      ;;
        SUB   DI,SD_AREA_DIFFERENCE    ;;  Adjust for relocation
        MOV   ES:[BP].FIRST_XLAT_PTR,DI;;          Set flag
        ADD   DI,SD_AREA_DIFFERENCE    ;;  Adjust for relocation
                                       ;;
TB_CPN_CONTINUE5:                      ;;
        CALL  STATE_BUILD              ;;  Build state
                                       ;;             TABLE_AREA
        CMP   CX,0                     ;;             COMMON_XLAT_SECTION
        JE    TB_CPN_REPEAT            ;;             SPECIFIC_XLAT_SECTION(S)
        JMP   TB_ERROR4                ;;    DI --->
                                       ;;
TB_CPN_REPEAT:                         ;;
        MOV   CX,RESIDENT_END_ACC      ;;
        ADD   CX,MAX_SPEC_SIZE         ;;  Refresh resident end size
        MOV   RESIDENT_END_ACC,CX      ;;
                                       ;;
        MOV   CX,DESIG_CP_OFFSET       ;;
        ADD   CX,2                     ;; Adjust offset to find next code page
        MOV   DESIG_CP_OFFSET,CX       ;;
                                       ;;
        MOV   CX,NUM_DESIG_CP          ;; Adjust the number of code pages left
        DEC   CX                       ;;
        MOV   NUM_DESIG_CP,CX          ;;
                                       ;;
        JMP   TB_CPN_BEGIN             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
TB_DONE:                               ;;
        MOV   CX,RESIDENT_END_ACC      ;;  Set final calculated value
        ADD   CX,BP                    ;;;;;;;;;;;
        SUB   CX,SD_AREA_DIFFERENCE             ;;  Adjust for relocation
        MOV   ES,WORD PTR SHARED_AREA_PTR       ;;    Set segment
        MOV   BP,WORD PTR SHARED_AREA_PTR+2     ;;
        CMP   CX,ES:[BP].RESIDENT_END           ;;
        JNA   TB_DONE_CONTINUE1        ;;;;;;;;;;;
        JMP   TB_ERROR5                ;;
                                       ;;
TB_DONE_CONTINUE1:                     ;;
        CMP   ES:[BP].RESIDENT_END,-1  ;;
        JNE   DONT_REPLACE             ;;
        PUSH  CS                       ;;
        POP   ES                       ;;
        MOV   BP,OFFSET SD_SOURCE_PTR  ;;
        MOV   ES:[BP].RESIDENT_END,CX  ;;  Save resident end
        JMP   CONTINUE_2_END           ;;
                                       ;;
DONT_REPLACE:                          ;;
        PUSH  CS                       ;;
        POP   ES                       ;;
        MOV   BP,OFFSET SD_SOURCE_PTR  ;;
                                       ;;
CONTINUE_2_END:                        ;;
        SUB   CX,OFFSET SD_DEST_PTR    ;;  Calculate # of bytes to copy
        MOV   SD_LENGTH,CX             ;;
                                       ;;
        XOR   CX,CX                    ;;  Set valid completion return code
        MOV   TB_RETURN_CODE,CX        ;;
        RET                            ;;
                                       ;;
TB_CPN_INVALID:                        ;;
        CMP   CX,1                     ;;  Set error 1 return code
        JNE   TB_ERROR2                ;;
        MOV   TB_RETURN_CODE,CX        ;;
        RET                            ;;
                                       ;;
TB_ERROR2:                             ;;
        CMP   CX,2                     ;;  Set error 2 return code
        JNE   TB_ERROR3                ;;
        MOV   TB_RETURN_CODE,CX        ;;
        RET                            ;;
                                       ;;
TB_ERROR3:                             ;;
        CMP   CX,3                     ;;  Set error 3 return code
        JNE   TB_ERROR4                ;;
        MOV   TB_RETURN_CODE,CX        ;;
        RET                            ;;
                                       ;;
TB_ERROR4:                             ;;
        CMP   CX,4                     ;;  Set error 4 return code
        JNE   TB_ERROR5                ;;
        MOV   TB_RETURN_CODE,CX        ;;
        RET                            ;;
                                       ;;
TB_ERROR5:                             ;;
        MOV   CX,5                     ;;  Set error 5 return code
        MOV   TB_RETURN_CODE,CX        ;;
        RET                            ;;
                                       ;;
TB_ERROR6:                             ;;
        MOV   BX,TB_CODE_PAGE_PARM     ;;
        MOV   CX,6                     ;;
        MOV   TB_RETURN_CODE,CX        ;;  Set error 6 return code
        RET                            ;;
                                       ;;
TABLE_BUILD          ENDP              ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: STATE_BUILD
;;
;; Description:
;;     Create the state/xlat section within the specific translate section.
;;
;; Input Registers:
;;     DS - points to our data segment
;;     ES - points to our data segment
;;     SB_STATE_OFFSET - offset to the beginning of the info in Keyb Def SYS
;;     DI - offset of the beginning of the area used to build states
;;
;;     KEYBSYS_FILE_HANDLE - handle of the KEYBOARD.SYS file
;;
;; Output Registers:
;;     DI  - offset of the end of the area used by STATE_BUILD
;;
;;     CX - Return Code := 0  -  State build successful
;;                         4  -  State build unsuccessful
;;                              (Bad or missing Keyboard Def file)
;;
;; Logic:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                               ;;
END_OF_AREA_PTR      DW    0                   ;;
SB_FIRST_STATE       DW    0                   ;;
SB_STATE_LENGTH      DW    0                   ;;
SB_STATE_OFFSET      DD    0                   ;;
STATE_LENGTH         DW    0                   ;;
RESTORE_BP           DW    ?                   ;;
                                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
STATE_BUILD          PROC NEAR         ;;
                                       ;;
        MOV   SI,DI                    ;;  Get the tally pointer
        MOV   END_OF_AREA_PTR,DI       ;;  Save pointer
                                       ;;
        MOV   RESTORE_BP,BP            ;;  Save the base pointer
                                       ;;;;;;;;;
        MOV   BX,KEYBSYS_FILE_HANDLE          ;; Get handle
        MOV   DX,WORD PTR SB_STATE_OFFSET     ;; LSEEK file pointer
        MOV   CX,WORD PTR SB_STATE_OFFSET+2   ;;    back to top of XLAT table
        MOV   AH,42H                          ;;
        MOV   AL,0                     ;;;;;;;;; If no problem with
        INT   21H                      ;;     Keyboard Def file THEN
        JNC   SB_FIRST_HEADER          ;;
        JMP   SB_ERROR4                ;;
                                       ;;
SB_FIRST_HEADER:                       ;;
        XOR   BP,BP                    ;;
        LEA   CX,[BP].KX_FIRST_STATE   ;; Set number of bytes to read header
        MOV   DX,DI                    ;;
        PUSH  ES                       ;;
        POP   DS                       ;;
        MOV   AH,3FH                   ;; read in the header
        INT   21H                      ;;
        PUSH  CS                       ;;
        POP   DS                       ;;
        JNC   SB_HEAD_CONTINUE1        ;;
        JMP   SB_ERROR4                ;;
                                       ;;
SB_HEAD_CONTINUE1:                     ;;
        MOV   DX,NEXT_SECT_PTR         ;;
        CMP   DX,-1                    ;;
        JE    SB_HEAD_CONTINUE2        ;;
        SUB   DX,SD_AREA_DIFFERENCE    ;;  Adjust for relocation
                                       ;;;;;
SB_HEAD_CONTINUE2:                        ;;
        MOV   ES:[DI].XS_NEXT_SECT_PTR,DX ;;
        CMP   DX,-1                       ;;
        JE    SB_HEAD_CONTINUE3        ;;;;;
        ADD   DX,SD_AREA_DIFFERENCE    ;;  Adjust for relocation
                                       ;;
SB_HEAD_CONTINUE3:                     ;;
        ADD   DI,CX                    ;; Update the DI pointer
                                       ;;
SB_NEXT_STATE:                         ;;
        XOR   BP,BP                    ;;  Set number
        LEA   CX,[BP].KX_STATE_ID      ;;     bytes to read state length
        MOV   DX,DI                    ;;  Read the header into the
        MOV   BX,KEYBSYS_FILE_HANDLE   ;;     SHARED_DATA_AREA
        PUSH  ES                       ;;
        POP   DS                       ;;
        MOV   AH,3FH                   ;;
        INT   21H                      ;;
                                       ;;
SB_CONTINUE1:                          ;;
        PUSH  CS                       ;; Reset the data segment
        POP   DS                       ;;
        MOV   CX,ES:[DI].KX_STATE_LEN  ;; If the length of the state section
        MOV   STATE_LENGTH,CX          ;;
        ADD   DI,2                     ;;  is zero then done
        CMP   CX,0                     ;;
        JE    SB_DONE                  ;;
        XOR   BP,BP                    ;;  Set number
        LEA   CX,[BP].KX_FIRST_XLAT-2  ;;     bytes to read state length
        MOV   DX,DI                    ;;  Read the header into the
        MOV   BX,KEYBSYS_FILE_HANDLE   ;;     SHARED_DATA_AREA
        PUSH  ES                       ;;
        POP   DS                       ;;
        MOV   AH,3FH                   ;;
        INT   21H                      ;;
                                       ;;
SB_CONTINUE1A:                         ;;
        PUSH  CS                       ;; Reset the data segment
        POP   DS                       ;;
        SUB   DI,2                     ;;
        MOV   AX,ES:[DI].XS_KBD_TYPE   ;;   Get the keyboard type def
        TEST  AX,HW_TYPE               ;;   Does it match our hardware?
        JNZ   SB_CONTINUE2             ;;
        MOV   DX,ES:[DI].XS_STATE_LEN  ;;     No, then
        LEA   CX,[BP].KX_FIRST_XLAT    ;;
        SUB   DX,CX                    ;;
        XOR   CX,CX                    ;;
        MOV   AH,42H                   ;;          LSEEK past this state
        MOV   AL,01H                   ;;
        INT   21H                      ;;
        JMP   SB_NEXT_STATE            ;;
                                       ;;
SB_CONTINUE2:                          ;;     Yes, then
        MOV   AX,SIZE STATE_STR-1      ;;
        ADD   DI,AX                    ;;  Set PTR and end of header
                                       ;;
SB_XLAT_TAB_BEGIN:                     ;;  Begin getting xlat tables
        MOV   BX,KEYBSYS_FILE_HANDLE   ;;
        LEA   DX,[BP].KX_FIRST_XLAT    ;;  Adjust for what we have already read
        MOV   CX,STATE_LENGTH          ;;
        SUB   CX,DX                    ;;
        MOV   DX,DI                    ;;
        PUSH  ES                       ;;
        POP   DS                       ;;
        MOV   AH,3FH                   ;;  Read in the xlat tables
        INT   21H                      ;;
        PUSH  CS                       ;;
        POP   DS                       ;;
        JNC   SB_CONTINUE4             ;;
        JMP   SB_ERROR4                ;;
                                       ;;
SB_CONTINUE4:                          ;;
        CMP   CX,AX                    ;;
        JE    SB_ERROR_CHECK1          ;;
        JMP   SB_ERROR4                ;;
                                       ;;
SB_ERROR_CHECK1:                       ;;
        ADD   DI,CX                    ;;  Update the end of area ptr
                                       ;;
        MOV   SI,DI                    ;;
        JMP   SB_NEXT_STATE            ;;
                                       ;;
SB_DONE:                               ;;
        MOV   AX,-1                    ;;
        MOV   SI,END_OF_AREA_PTR       ;;
        MOV   NEXT_SECT_PTR,SI         ;;
                                       ;;
        MOV   BP,RESTORE_BP            ;;
        RET                            ;;
                                       ;;
SB_ERROR1:                             ;;
        MOV   CX,1                     ;;
        RET                            ;;
                                       ;;
SB_ERROR2:                             ;;
        MOV   CX,2                     ;;
        RET                            ;;
                                       ;;
SB_ERROR3:                             ;;
        MOV   CX,3                     ;;
        RET                            ;;
                                       ;;
SB_ERROR4:                             ;;
        MOV   CX,4                     ;;
        RET                            ;;
                                       ;;
                                       ;;
STATE_BUILD          ENDP              ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: FIND_CP_TABLE
;;
;; Description:
;;     Determine the offset of the specified code page table in KEYBOARD.SYS
;;
;; Input Registers:
;;     DS - points to our data segment
;;     ES - points to our data segment
;;     AX - ASCII representation of the language parm
;;     BX - binary representation of the code page
;;
;;     KEYBSYS_FILE_HANDLE - handle of the KEYBOARD.SYS file
;;
;; Output Registers:
;;     CP_TAB_OFFSET - offset of the CP table in KEYBOARD.SYS
;;
;;     CX - Return Code := 0  -  State build successful
;;                         2  -  Invalid Code page for language
;;                         4  -  Bad or missing Keyboard Def file
;; Logic:
;;
;;     READ language table
;;     IF error in reading file THEN
;;         Display ERROR message and EXIT
;;     ELSE
;;         Use table to verify language parm
;;         Set pointer values
;;         IF code page was specified
;;             READ language entry
;;             IF error in reading file THEN
;;                  Display ERROR message and EXIT
;;             ELSE
;;                  READ Code page table
;;                  IF error in reading file THEN
;;                      Display ERROR message and EXIT
;;                  ELSE
;;                      Use table to get the offset of the code page parm
;;    RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                               ;;
FIND_CP_PARM          DW    ?                  ;;
                                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
FIND_CP_TABLE          PROC  NEAR      ;;
                                       ;;
                                       ;;
        MOV   FIND_CP_PARM,BX          ;; Save Code page
                                       ;;;;;;;;;;;;;;
        MOV   BX,KEYBSYS_FILE_HANDLE               ;; Get handle
        MOV   DX,WORD PTR KEYBCMD_LANG_ENTRY_PTR   ;; LSEEK file pointer
        MOV   CX,WORD PTR KEYBCMD_LANG_ENTRY_PTR+2 ;;  to top of language entry
        MOV   AH,42H                               ;;
        MOV   AL,0                     ;;;;;;;;;;;;;; If no problem with
        INT   21H                      ;;     Keyb Def file Then
        JNC   FIND_BEGIN               ;;
        JMP   FIND_CP_ERROR4           ;;
                                       ;;;;;;;;;
FIND_BEGIN:                                   ;;
        MOV   DI,AX                           ;;
        MOV   CX,SIZE KEYBSYS_LANG_ENTRY-1    ;; Set number
                                              ;;        bytes to read header
        MOV   DX,OFFSET FILE_BUFFER    ;;;;;;;;;
        MOV   AH,3FH                   ;; Read language entry in
        INT   21H                      ;;        KEYBOARD.SYS file
        JNC   FIND_VALID4              ;; If no error in opening file then
        JMP   FIND_CP_ERROR4           ;;
                                       ;;
FIND_VALID4:                           ;;
;****************************** CNS *******************************************
        xor   ah,ah
        mov   al,FB.KL_NUM_CP
;****************************** CNS *******************************************
        MOV   NUM_CP,AX                ;; Save the number of code pages
        MUL   CP_PTR_SIZE              ;; Determine # of bytes to read
        MOV   DX,OFFSET FILE_BUFFER    ;; Establish beginning of buffer
        MOV   CX,AX                    ;;
        CMP   CX,FILE_BUFFER_SIZE      ;; Make sure buffer is not to small
        JBE   FIND_VALID5              ;;
        JMP   FIND_CP_ERROR4           ;;
                                       ;;
FIND_VALID5:                           ;;
        MOV   AH,3FH                   ;; Read code page table from
        INT   21H                      ;;              KEYBOARD.SYS file
        JNC   FIND_VALID6              ;; If no error in opening file then
        JMP   FIND_CP_ERROR4           ;;
                                       ;;
FIND_VALID6:                           ;;
        MOV   CX,NUM_CP                ;;    Number of valid codes
        MOV   DI,OFFSET FILE_BUFFER    ;;    Point to correct word in table
                                       ;;
F_SCAN_CP_TABLE:                       ;; FOR code page parm
        MOV   AX,FIND_CP_PARM          ;;    Get parameter
        CMP   [DI].KC_CODE_PAGE,AX     ;;    Valid Code ??
        JE    F_CODE_PAGE_FOUND        ;; If not found AND more entries THEN
        ADD   DI,LANG_PTR_SIZE         ;;    Check next entry
        DEC   CX                       ;;    Decrement count of entries
        JNE   F_SCAN_CP_TABLE          ;; Else
        JMP   FIND_CP_ERROR2           ;;    Display error message
                                       ;;;;;;;;;;
F_CODE_PAGE_FOUND:                             ;;
        MOV   AX,WORD PTR [DI].KC_ENTRY_PTR    ;;
        MOV   WORD PTR CP_TAB_OFFSET,AX        ;;
        MOV   AX,WORD PTR [DI].KC_ENTRY_PTR+2  ;;
        MOV   WORD PTR CP_TAB_OFFSET+2,AX      ;;
                                               ;;
        XOR   CX,CX                    ;;;;;;;;;;
        RET                            ;;
                                       ;;
FIND_CP_ERROR1:                        ;;
        MOV   CX,1                     ;;
        RET                            ;;
                                       ;;
FIND_CP_ERROR2:                        ;;
        MOV   CX,2                     ;;
        RET                            ;;
                                       ;;
FIND_CP_ERROR3:                        ;;
        MOV   CX,3                     ;;
        RET                            ;;
                                       ;;
FIND_CP_ERROR4:                        ;;
        MOV   CX,4                     ;;
        RET                            ;;
                                       ;;
FIND_CP_TABLE         ENDP             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CODE   ENDS
       END    TABLE_BUILD
