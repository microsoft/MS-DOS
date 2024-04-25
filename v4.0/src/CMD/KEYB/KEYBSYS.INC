.XLIST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBSYS.INC
;; ----------
;;
;; Root File Name:  KEYB.ASM
;; ---------------
;;
;; Description:
;; ------------
;;	 Include file containing structure definitions and equates
;;	 for the KEYBOARD.SYS file.
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; File header - contains pointers to keyboard tables for each language
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
KEYBSYS_HEADER	STRUC		       ;;
				       ;;
KH_SIGNATURE	DB   0FFh,'KEYB   '    ;; signature
KH_RESV_1	DB   8 DUP(0)	       ;; reserved
KH_MAX_COM_SZ	DW   0	      ;AN000;**chg  ;; maximum size of Common Xlat Sect
KH_MAX_SPEC_SZ	DW   0	      ;AN000;;**chg   ;; max size of Specific Xlat Sect
KH_MAX_LOGIC_SZ DW   0	      ;AN000;;**chg   ;; max size of State Logic
KH_RESV_2	Dw   0	      ;AN000;;**chg   ;; reserved CNS
KH_NUM_ID	Dw   0		       ;AN000;;; ************* CNS
KH_NUM_LANG	DW   0		       ;; number of languages
KH_LANG_PTRS	DB   0		       ;; language pointers start here
;********************* CNS **********************
;KH_NUM_ID	  DW   0		 ;; number of languages
;KH_ID_PTRS	  DB   0		 ;; id pointers start here
;********************* CNS **********************
KEYBSYS_HEADER	ENDS		       ;;
;******************CNS*******************
KEYBSYS_ID_PTRS STRUC

KP_ID_CODE	DW   0		       ;AN000;
KP_LANG_PTR	DD   0		       ;AN000;

KEYBSYS_ID_PTRS ENDS
				       ;;
;*****************CNS********************
KEYBSYS_LANG_PTRS STRUC 	       ;;
				       ;; Next two entries repeat:
KP_LANG_CODE	DW   0		       ;;   language code
KP_ENTRY_PTR	DD   0		       ;;   language entry pointer
				       ;;
KEYBSYS_LANG_PTRS ENDS		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Language Entry - pointed to by KH_ENTRY_PTR in KEYBSYS_HEADER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
KEYBSYS_LANG_ENTRY  STRUC	       ;;
				       ;;
KL_LANG_CODE	DW   'XX'              ;; language code
KL_ID_CODE	DW   0		       ;; reserved (ID CODE)
KL_LOGIC_PTR	DD   0	       ;AC000;;**chg  ;; State Logic pointer
KL_NUM_ID	DB   0	       ;AN000;;CNS    ;; number of valid IDs for this lang
KL_NUM_CP	DB   0		       ;; number of valid CPs for this lang
KL_CP_PTRS	DB   0		       ;; CP table pointers start here
				       ;;
KEYBSYS_LANG_ENTRY  ENDS	       ;;
				       ;;
KEYBSYS_CP_PTRS     STRUC	       ;;
				       ;; Next two entries repeat:
KC_CODE_PAGE	DW   0		       ;;  code page
KC_ENTRY_PTR	DD   0		       ;; ptr to Specific Translate Section
				       ;;
KEYBSYS_CP_PTRS     ENDS	       ;;
				       ;;
				       ;;
;; Everything from here down is new
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; State Logic - pointed to by KL_LOGIC_PTR in KEYBSYS_LANG_ENTRY
;; Common Translate Section follows immediately after the State Logic.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
KEYBSYS_STATE_LOGIC STRUC	       ;;
				       ;;
KT_LOGIC_LEN	DW   ?		       ;; length of state logic
KT_SPECIAL_FEATURES  DW  ?	       ;; Special Features (see KEYBSHAR.INC)
KT_LOGIC_CMDS	DB   0		       ;; state logic commands begin here
				       ;;
KEYBSYS_STATE_LOGIC ENDS	       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Translate Section - Common and Specific Translate Sections
;; are both in this form.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
KEYBSYS_XLAT_SECT   STRUC	       ;;
				       ;;
KX_SECTION_LEN	 DW    ?	       ;; Length of this section
KX_CP_ID	 DW    ?	       ;; code page id
KX_FIRST_STATE	 DB    ?	       ;;
				       ;;
KEYBSYS_XLAT_SECT   ENDS	       ;;
				       ;;
				       ;;
KEYBSYS_STATE	    STRUC	       ;;
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     ;; Translate Sections contains multiple States.
	     ;; A State contains the translate tables for a single
	     ;; shift state (IE lower case, upper case ....)
	     ;; The last State is a null State containing only the
	     ;; KX_STATE_LEN field with a value of 0.
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
KX_STATE_LEN	 DW    ?	       ;; length of state section
KX_STATE_ID	 DB    ?	       ;; State ID
KX_KBD_TYPE	 DW    ?	       ;; Keyboard Type
KX_ERROR_CHAR	 DW    ?	       ;; Buffer entry for error character
KX_FIRST_XLAT	 DB    ?	       ;; XLAT tables begin here
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     ;; Each State consists of multiple translate tables.
	     ;; The last translate table within a state is a null
	     ;; table containing only the
	     ;; KX_XLAT_LEN field with a value of 0.
	     ;; Refer to KEYBSHAR.INC for translate table format.
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
KEYBSYS_STATE	    ENDS	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.LIST

