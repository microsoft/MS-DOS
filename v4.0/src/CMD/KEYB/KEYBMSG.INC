.XLIST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBMSG.INC
;; ----------
;;
;; Root File Name:  KEYBCMD.ASM (KEYB.ASM)
;; ---------------
;;
;; Description:
;; ------------
;;	 External declarations for procedures in file KEYBCMD.ASM.
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
	EXTRN	 ACT_KEYB_CP :BYTE     ;;
	EXTRN	 ACT_CON_CP  :BYTE     ;;
	EXTRN	 ACT_KEYB    :BYTE     ;;
	EXTRN	 INV_L	     :BYTE     ;;
	EXTRN	 INV_I	     :BYTE     ;;
	EXTRN	 INV_CP      :BYTE     ;;
	EXTRN	 INV_S	     :BYTE     ;;
	EXTRN	 INV_FN      :BYTE     ;;
	EXTRN	 INV_KEYB_Q  :BYTE     ;;
	EXTRN	 INV_CON_Q   :BYTE     ;;
	EXTRN	 NOT_DESIG   :BYTE     ;;
	EXTRN	 NOT_SUPP    :BYTE     ;;
	EXTRN	 NOT_VALID1  :BYTE     ;;
	EXTRN	 NOT_VALID2  :BYTE     ;;
	EXTRN	 WARNING_1   :BYTE     ;;
	EXTRN	 INV_COMBO   :BYTE     ;;
	EXTRN	 CR_LF	     :BYTE     ;;
	EXTRN	 MEMORY_OVERF :BYTE    ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.LIST
