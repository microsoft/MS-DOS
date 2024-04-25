
        PAGE    ,132
        TITLE   DOS - KEYB Command  -  Interrupt 2F Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBI2F.ASM
;; ----------
;;
;; Description:
;; ------------
;;       Contains Interrupt 2F handler.
;;
;; Documentation Reference:
;; ------------------------
;;       PC DOS 3.3 Detailed Design Document - May ?? 1986
;;
;; Procedures Contained in This File:
;; ----------------------------------
;;       KEYB_INT_2F - Interupt 2F handler
;;
;; Include Files Required:
;; -----------------------
;;       INCLUDE KEYBEQU.INC
;;       INCLUDE KEYBSHAR.INC
;;       INCLUDE KEYBMAC.INC
;;       INCLUDE KEYBCMD.INC
;;       INCLUDE KEYBCPSD.INC
;;       INCLUDE KEYBI9C.INC
;;
;; External Procedure References:
;; ------------------------------
;;       FROM FILE  ????????.ASM:
;;            procedure - description????????????????????????????????
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
        INCLUDE KEYBEQU.INC            ;;
        INCLUDE KEYBSHAR.INC           ;;
        INCLUDE KEYBMAC.INC            ;;
        INCLUDE KEYBCMD.INC            ;;
        INCLUDE KEYBCPSD.INC           ;;
        INCLUDE KEYBI9C.INC            ;;
                                       ;;
        PUBLIC KEYB_INT_2F             ;;
                                       ;;
        EXTRN  ERROR_BEEP:NEAR         ;;
                                       ;;
CODE    SEGMENT PUBLIC 'CODE'          ;;
                                       ;;
        ASSUME  CS:CODE,DS:CODE        ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: KEYB_INT_2F
;;
;; Description:
;;
;; Input Registers:
;;     AH = 0ADH
;;     AL = 80,81,82
;;
;; Output Registers:
;;     N/A
;;
;; Logic:
;;    IF AH = 0ADh THEN    (this call is for us)
;;       Set carry flag to 0
;;       IF AL = 80 THEN
;;          Get major and minor
;;          Get SEG:OFFSET of SHARED_DATA_AREA
;;
;;       IF AL = 81 THEN
;;          Get FIRST_XLAT_PTR
;;          FOR each table
;;             IF code page requested = code page value at pointer THEN
;;                Set INVOKED_CODE_PAGE
;;                Set ACTIVE_XLAT_PTR
;;                EXIT
;;             ELSE
;;                Get NEXT_SECT_PTR
;;          NEXT table
;;          IF no corresponding code page found THEN
;;             Set carry flag
;;
;;       IF AL = 82 THEN
;;          IF BL = 00 THEN
;;             Set COUNTRY_FLAG = 00
;;          ELSE IF BL = 0FFH THEN
;;             Set COUNTRY_FLAG = 0FFH
;;          ELSE
;;             Set carry flag
;;    IRET or JMP to another INT 2FH handler (if installed)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
CP_QUERY        EQU   80H              ;;
CP_INVOKE       EQU   81H              ;;
CP_LANGUAGE     EQU   82H              ;;
                                       ;;
VERSION_MAJOR   EQU   01H              ;;
VERSION_MINOR   EQU   00H              ;;
                                       ;;
CARRY_FLAG      EQU   01H              ;;
RESTORE_BP       DW    ?               ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
KEYB_INT_2F   PROC                     ;;
                                       ;;
        PUSH  DS                       ;;
        PUSH  BX                       ;;
        PUSH  CX                       ;;
        PUSH  SI                       ;;
                                       ;;
        PUSH  CS                       ;;
        POP   DS                       ;; Set DATA SEGMENT register
                                       ;;
        CMP   AH,INT_2F_SUB_FUNC       ;; Q..is this call for us?
        JE    CHECK_REQUEST_CODE       ;; Y..check request code
        JMP   INT_2F_DONE              ;; N..get out
                                       ;;
CHECK_REQUEST_CODE:                    ;; Y..check request code
        MOV   RESTORE_BP,BP            ;;;;;;;;;;;
        MOV   BP,SP                             ;;  Clear CARRY flag
        AND   WORD PTR [BP]+12,NOT CARRY_FLAG   ;;
        MOV   BP,RESTORE_BP                     ;;
                                       ;;;;;;;;;;;
                                       ;;
INT_2F_CP_QUERY:                       ;;
        CMP   AL,CP_QUERY              ;; Q..query CP?
        JNE   INT_2F_CP_INVOKE         ;; N..next
        MOV   AX,-1                    ;; Y..process query
        MOV   BH,VERSION_MAJOR         ;;
        MOV   BL,VERSION_MINOR         ;;
        MOV   DI,OFFSET SD             ;;
        PUSH  CS                       ;;
        POP   ES                       ;;
        JMP   INT_2F_DONE              ;;
                                       ;;
INT_2F_CP_INVOKE:                      ;;
        CMP   AL,CP_INVOKE             ;; Q..invoke CP?
        JNE   INT_2F_CP_LANGUAGE       ;; N..next
                                       ;;
        MOV   SI,SD.FIRST_XLAT_PTR     ;; Get FIRST_XLAT_PTR
                                       ;;
INT_2F_NEXT_SECTION:                   ;;
        CMP   SI,-1                    ;;
        JE    INT_2F_ERROR_FLAG        ;;
        MOV   CX,[SI].XS_CP_ID         ;; Read in the code page value
        CMP   CX,BX                    ;; Is this the table to make active?
        JNE   INT_2F_CP_INVOKE_CONT1   ;;
        MOV   SD.ACTIVE_XLAT_PTR,SI    ;; IF Yes, Set the ACTIVE_XLAT_PTR
        MOV   SD.INVOKED_CP_TABLE,BX   ;;   record new code page
        JMP   INT_2F_DONE              ;;
                                       ;;
INT_2F_CP_INVOKE_CONT1:                ;; Else
        MOV   DI,[SI].XS_NEXT_SECT_PTR ;; IF No,
        MOV   SI,DI                    ;;    Get NEXT_SECT_PTR
        JMP   INT_2F_NEXT_SECTION      ;;    NEXT_SECTION
                                       ;;
INT_2F_ERROR_FLAG:                     ;;
        MOV   AX,1                     ;;
        MOV   RESTORE_BP,BP            ;;;;;;
        MOV   BP,SP                        ;;
        OR    WORD PTR [BP]+12,CARRY_FLAG  ;; Set carry flag
        MOV   BP,RESTORE_BP                ;;
                                       ;;;;;;
        JMP   INT_2F_DONE              ;;
                                       ;;
INT_2F_CP_LANGUAGE:                    ;;
        CMP   AL,CP_LANGUAGE           ;; Q..Set default language??
        JNE   INT_2F_DONE              ;; N..next
                                       ;;
        CMP   BL,0                     ;; Y..Check if Language is to be US437
        JNE   INT_2F_CONTINUE1         ;; IF yes THEN,
        MOV   COUNTRY_FLAG,BL          ;;   Set COUNTRY_FLAG to 0
        JMP   INT_2F_DONE              ;;
                                       ;;
INT_2F_CONTINUE1:                      ;; ELSE
        CMP   BL,-1                    ;;   Check if language is to be national
        JNE   INT_2F_LANG_ERROR_FLAG   ;;   IF yes THEN,
        MOV   COUNTRY_FLAG,BL          ;;     Set COUNTRY_FLAG to -1 (0FFH)
        JMP   INT_2F_DONE              ;;
                                       ;;
INT_2F_LANG_ERROR_FLAG:                ;;   ELSE
        MOV   RESTORE_BP,BP            ;;;;;;     Set CARRY flag
        MOV   BP,SP                        ;;
        OR    WORD PTR [BP]+12,CARRY_FLAG  ;;
        MOV   BP,RESTORE_BP                ;;
                                       ;;;;;;
        JMP   INT_2F_DONE              ;;
                                       ;;
INT_2F_DONE:                           ;;
        POP   SI                       ;;
        POP   CX                       ;;
        POP   BX                       ;;;;;;;
        POP   DS                            ;;
        CMP   WORD PTR CS:SD.OLD_INT_2F,0   ;; Q..are we the last in the chain?
        JNE   INT_2F_JMP                    ;; N..call next in chain
        CMP   WORD PTR CS:SD.OLD_INT_2F+2,0 ;; Q..are we the last in the chain?
        JNE   INT_2F_JMP                    ;; N..call next in chain
                                       ;;;;;;;
        IRET                           ;; Y..return to caller
                                       ;;
INT_2F_JMP:                            ;;
                                       ;;
        JMP   CS:SD.OLD_INT_2F         ;;
                                       ;;
KEYB_INT_2F   ENDP                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE   ENDS
       END
