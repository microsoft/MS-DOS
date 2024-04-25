
.XLIST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBDCL.INC
;; ----------
;;
;; Root File Name:  KEYB.ASM
;; ---------------
;;
;; Description:
;; ------------
;;	 Common declarations for structures in procedures for KEYB.COM
;;
;; Change History:
;; ---------------
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
PARM_LIST	 STRUC		       ;;
;*******************CNS******************
;*******************CNS******************
    RET_CODE_1	    DB	 0	       ;;  \
    RET_CODE_2	    DB	 0	       ;;  |
    RET_CODE_3	    DB	 0	       ;;  |
;*******************CNS******************
    RET_CODE_4	    DB	 0	       ;;  |;AN000;
;*******************CNS******************
    LANGUAGE_PARM   DW	 ?	       ;;   }  PARAMETER
    CODE_PAGE_PARM  DW	 ?	       ;;  |	    LIST
    PATH_OFFSET     DW	 ?	       ;;  |
    PATH_LENGTH     DW	 0	       ;;  /
;*******************CNS******************
    ID_PARM	    DW	 ?	       ;AN000;
;*******************CNS******************
PARM_LIST	 ENDS		       ;;
				       ;;
DESIG_CP_STRUC	 STRUC		       ;;
    NUM_DESIGNATES  DW	 ?	       ;;
    NUM_FONTS	    DW	 ?	       ;;
    NUM_HW_CPS	    DW	 ?	       ;;
    DESIG_CP_ENTRY  DW	 ?	       ;;
DESIG_CP_STRUC	  ENDS		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.LIST

