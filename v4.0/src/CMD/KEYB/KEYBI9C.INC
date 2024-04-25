.XLIST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBI9C.INC
;; ----------
;;
;; Root File Name:  KEYB.ASM
;; ---------------
;;
;; Description:
;; ------------
;;	 External declarations and equates for procedures in file
;;	 KEYBI9C.ASM
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
	EXTRN	 KEYB_INT_9:NEAR       ;;
	EXTRN	 BUFFER_FILL:NEAR      ;;
	EXTRN	 ERROR_BEEP :NEAR      ;;
	EXTRN	 COUNTRY_FLAG:BYTE     ;;
	EXTRN	 BEEP_PENDING:BYTE     ;;
	EXTRN	 SCAN_CODE:BYTE        ;;
	EXTRN	 K8:BYTE	       ;;
	EXTRN	 TEMP_HEAD:WORD        ;;
	EXTRN	 TEMP_TAIL:WORD        ;;
	EXTRN	 BUSY_TFLAG:BYTE       ;;
	EXTRN	 MYBUFF:BYTE	       ;;
	EXTRN	 ENABLE_FL:BYTE        ;;
	EXTRN	 NEW_BUFF_CTR :BYTE    ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.LIST

