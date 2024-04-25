.XLIST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBEQU.INC
;; ----------
;;
;; Root File Name:  KEYB.ASM
;; ---------------
;;
;; Description:
;; ------------
;;       Include file containing equates used by all KEYB modules.
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
YES         EQU      1                 ;;
NO          EQU      0                 ;;
                                       ;;
INT_2F_SUB_FUNC  EQU  0ADH             ;; our subfunction code for int 2f
SD               EQU  SHARED_DATA      ;;
TSD              EQU  TEMP_SHARED_DATA ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.LIST
