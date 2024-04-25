.XLIST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBCPSD.INC
;; ----------
;;
;; Description:
;; ------------
;;       External declarations and equates for procedures in file
;;       KEYBCPSD.ASM
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
        EXTRN    COPY_SD_AREA:NEAR     ;;
                                       ;;
        EXTRN    SD_DEST_PTR :BYTE     ;;
        EXTRN    SHARED_DATA :BYTE     ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.LIST

