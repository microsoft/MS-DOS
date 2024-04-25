.XLIST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBCMD.INC
;; ----------
;;
;; Root File Name:  KEYB.ASM
;; ---------------
;;
;; Description:
;; ------------
;;       External declarations for procedures in file KEYCMD.ASM.
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                              ;;
        EXTRN    KEYB_COMMAND        :NEAR    ;;
                                              ;;
        EXTRN    KEYBSYS_FILE_HANDLE:WORD     ;;
        EXTRN    CP_TAB_OFFSET:DWORD          ;;
        EXTRN    STATE_LOGIC_OFFSET:DWORD     ;;
        EXTRN    SYS_CODE_PAGE:WORD           ;;
        EXTRN    KEYBCMD_LANG_ENTRY_PTR:DWORD ;;
        EXTRN    DESIG_CP_BUFFER:WORD         ;;
        EXTRN    DESIG_CP_OFFSET:WORD         ;;
        EXTRN    NUM_DESIG_CP:WORD            ;;
        EXTRN    TB_RETURN_CODE:WORD          ;;
	EXTRN	 FILE_BUFFER_SIZE:ABS
        EXTRN    FILE_BUFFER:WORD             ;;
;****************CNS****************************
        EXTRN    ID_PTR_SIZE:WORD             ;;
;****************CNS****************************
        EXTRN    LANG_PTR_SIZE:WORD           ;;
        EXTRN    CP_PTR_SIZE:WORD             ;;
;****************CNS****************************
        EXTRN    NUM_ID:WORD                  ;;
;****************CNS****************************
        EXTRN    NUM_LANG:WORD                ;;
        EXTRN    NUM_CP:WORD                  ;;
        EXTRN    SHARED_AREA_PTR:DWORD        ;;
        EXTRN    SD_SOURCE_PTR:BYTE           ;;
        EXTRN    TEMP_SHARED_DATA:BYTE        ;;
                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.LIST

