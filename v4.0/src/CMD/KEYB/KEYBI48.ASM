

        PAGE    ,132
        TITLE   DOS - KEYB Command  -  Interrupt 48H Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBI48.ASM
;; ----------
;;
;; Description:
;; ------------
;;       Contains Interrupt 48H handler.
;;
;; Documentation Reference:
;; ------------------------
;;       PC DOS 3.3 Detailed Design Document - May ?? 1986
;;
;; Procedures Contained in This File:
;; ----------------------------------
;;
;; Include Files Required:
;; -----------------------
;;       INCLUDE KEYBEQU.INC
;;       INCLUDE KEYBSHAR.INC
;;       INCLUDE KEYBMAC.INC
;;       INCLUDE KEYBCMD.INC
;;       INCLUDE KEYBCPSD.INC
;;       INCLUDE POSTEQU.inc
;;       INCLUDE DSEG.inc
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
        INCLUDE POSTEQU.inc            ;;
        INCLUDE DSEG.inc               ;;
                                       ;;
        PUBLIC KEYB_INT_48             ;;
                                       ;;
        EXTRN  ERROR_BEEP:NEAR         ;;
                                       ;;
CODE    SEGMENT PUBLIC 'CODE'          ;;
                                       ;;
        ASSUME  CS:CODE,DS:CODE,ES:DATA;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: KEYB_INT_48
;;
;; Description:
;;
;; Input Registers:
;;     AL := Scan Code
;;
;; Output Registers:
;;     N/A
;;
;; Logic:
;;    IF scan code is not a break code THEN
;;       IF CNTL was not entered THEN
;;          IF ALT+SHIFT was pressed THEN
;;             Set JB_KB_FLAG in SHARED_DATA_AREA
;;             Clear ALT and SHIFT states in KB_FLAG
;;    IRET or JMP to a chained INT48 routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   Program Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
KEYB_INT_48   PROC                     ;;
                                       ;;
        STI                            ;; allow NON-KB interrupts
        PUSH   BX                      ;;
        PUSH   BP                      ;;
        PUSH   CX                      ;;
        PUSH   DX                      ;;
        PUSH   DI                      ;;
        PUSH   SI                      ;;
        PUSH   DS                      ;;
        PUSH   ES                      ;;
        PUSH   AX                      ;;
                                       ;;
        MOV     SD.JR_KB_FLAG,0        ;; Clear the flag
                                       ;;
        CMP     AL,80H                 ;; Test for break code
        JA      INT48_EXIT             ;; IF not a break code THEN
                                       ;;
        PUSH    DS                     ;; Save segment registers
        PUSH    ES                     ;;
                                       ;;
        PUSH    CS                     ;; Set up addressing
        POP     DS                     ;;  for DATA SEGMENT (=CODE SEGMENT)
        MOV     BX,DATA                ;; Set up addressing
        MOV     ES,BX                  ;;  for EXTRA SEGMENT (=BIOS RAM AREA)
                                       ;;
        MOV     AH,KB_FLAG             ;; Get the flag status
        AND     AH,0FH                 ;; Clear all shift states
                                       ;;
        TEST    AH,CTL_SHIFT           ;; Test if CNTL was entered?
        JNE     INT48_PASS             ;;;;;;;;;;;;;;;; IF yes THEN
                                                     ;;     pass to ROM INT48
        AND     AH,ALT_SHIFT+RIGHT_SHIFT+LEFT_SHIFT  ;; Test if both ALT and
        CMP     AH,ALT_SHIFT                         ;;     SHIFT were pressed
        JBE     INT48_PASS                           ;; IF no THEN
                                                     ;;     pass to ROM INT48
        MOV     BH,KB_FLAG                           ;;;;;;;;;;;; IF yes then
        MOV     SD.JR_KB_FLAG,BH                               ;;  Setup JR flag
        AND     SD.JR_KB_FLAG,ALT_SHIFT+RIGHT_SHIFT+LEFT_SHIFT ;; Pass flags
                                                               ;;   (ALT and
                                       ;;;;;;;;;;;;;;;;;;;;;;;;;; EITHER/BOTH SHIFT)
        XOR     KB_FLAG,AH             ;; Clear the ALT state and SHIFT state
                                       ;; Reset the KB_FLAG to permit
                                       ;;    third shifts to go through
INT48_PASS:                            ;;
        POP     ES                     ;;
        POP     DS                     ;;
                                       ;;;;;;;
INT48_EXIT:                                 ;;
        CMP   WORD PTR CS:SD.OLD_INT_48,0   ;; Q..are we the last in the chain?
        JNE   INT_48_JMP                    ;; N..call next in chain
        CMP   WORD PTR CS:SD.OLD_INT_48+2,0 ;; Q..are we the last in the chain?
        JNE   INT_48_JMP                    ;; N..call next in chain
                                       ;;;;;;;
        POP    AX                      ;; restore regs
        POP    ES                      ;;
        POP    DS                      ;;
        POP    SI                      ;;
        POP    DI                      ;;
        POP    DX                      ;;
        POP    CX                      ;;
        POP    BP                      ;;
        POP    BX                      ;;
                                       ;;
        IRET                           ;; Y..return to caller
                                       ;;
INT_48_JMP:                            ;;
                                       ;;
        POP    AX                      ;; restore regs
        POP    ES                      ;;
        POP    DS                      ;;
        POP    SI                      ;;
        POP    DI                      ;;
        POP    DX                      ;;
        POP    CX                      ;;
        POP    BP                      ;;
        POP    BX                      ;;
                                       ;;
        JMP   CS:SD.OLD_INT_48         ;;
                                       ;;
KEYB_INT_48   ENDP                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE   ENDS
       END
