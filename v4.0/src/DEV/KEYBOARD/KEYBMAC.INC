.XLIST
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - - NLS Support - Keyboard Definition File
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBMAC.INC
;; ----------
;;
;; Description:
;; ------------
;;	 Include file containing macros for the Keyboard Definition File.
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Dead key flags
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
ACUTE		    EQU   80H	       ;; NLS_FLAG_1
GRAVE		    EQU   40H	       ;;
DIARESIS	    EQU   20H	       ;;
CIRCUMFLEX	    EQU   10H	       ;;
CEDILLA 	    EQU   08H	       ;;
TILDE		    EQU   04H	       ;;
				       ;; NLS_FLAG_2 : nothing defined yet
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; State IDs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
DEAD_LOWER	    EQU    1	       ;; dead keys on lower shift
DEAD_UPPER	    EQU    2	       ;;
ALPHA_LOWER	    EQU    3	       ;;
ALPHA_UPPER	    EQU    4	       ;;
NON_ALPHA_LOWER     EQU    5	       ;;
NON_ALPHA_UPPER     EQU    6	       ;;
THIRD_SHIFT	    EQU    7	       ;;
ACUTE_LOWER	    EQU    8	       ;;
ACUTE_UPPER	    EQU    9	       ;;
ACUTE_SPACE	    EQU   10	       ;;
GRAVE_LOWER	    EQU   11	       ;;
GRAVE_UPPER	    EQU   12	       ;;
GRAVE_SPACE	    EQU   13	       ;;
DIARESIS_LOWER	    EQU   14	       ;;
DIARESIS_UPPER	    EQU   15	       ;;
DIARESIS_SPACE	    EQU   16	       ;;
CIRCUMFLEX_LOWER    EQU   17	       ;;
CIRCUMFLEX_UPPER    EQU   18	       ;;
CIRCUMFLEX_SPACE    EQU   19	       ;;
CEDILLA_LOWER	    EQU   20	       ;;
CEDILLA_UPPER	    EQU   21	       ;;
CEDILLA_SPACE	    EQU   22	       ;;
CEDILLA_CEDILLA     EQU   23	       ;;
DEAD_THIRD	    EQU   24	       ;;
ACUTE_ACUTE	    EQU   25	       ;;
GRAVE_GRAVE	    EQU   26	       ;;
DIARESIS_DIARESIS   EQU   27	       ;;
CIRCUMFLEX_CIRCUMFLEX EQU 28	       ;;
FOURTH_SHIFT	    EQU   29	       ;;
DEAD_FOURTH	    EQU   30	       ;;
TILDE_LOWER	    EQU   31	       ;;
TILDE_UPPER	    EQU   32	       ;;
TILDE_SPACE	    EQU   33	       ;;
ALT_CASE	    EQU   34	       ;;
CTRL_CASE	    EQU   35	       ;;
NUMERIC_PAD	    EQU   36	       ;;
DIVIDE_SIGN	    EQU   37	       ;;
BOTLH_CAPS	    EQU   38	       ;;
BOTRH_CAPS	    EQU   39	       ;;
BOTLH_F_CAPS	    EQU   40	       ;;
BOTRH_F_CAPS	    EQU   41	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Logic Macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;

UNKNOWN = 255

FIND_FLAG MACRO  FLAG_MASK
       IFIDN <FLAG_MASK>,<SCAN_MATCH>
	  FLAG_ID = EXT_KB_FLAG_ID
       ELSE
       IFIDN <FLAG_MASK>,<EITHER_SHIFT>
	  FLAG_ID = EXT_KB_FLAG_ID
       ELSE
       IFIDN <FLAG_MASK>,<CAPS_STATE>
	  FLAG_ID = KB_FLAG_ID
       ELSE
       IFIDN <FLAG_MASK>,<NUM_STATE>
	  FLAG_ID = KB_FLAG_ID
       ELSE
       IFIDN <FLAG_MASK>,<EITHER_CTL>
	  FLAG_ID = EXT_KB_FLAG_ID
       ELSE
       IFIDN <FLAG_MASK>,<EITHER_ALT>
	  FLAG_ID = EXT_KB_FLAG_ID
       ELSE
       IFIDN <FLAG_MASK>,<LEFT_SHIFT>
	  FLAG_ID = KB_FLAG_ID
       ELSE
       IFIDN <FLAG_MASK>,<RIGHT_SHIFT>
	  FLAG_ID = KB_FLAG_ID
       ELSE
       IFIDN <FLAG_MASK>,<ALT_SHIFT>
	  FLAG_ID = KB_FLAG_ID
       ELSE
       IFIDN <FLAG_MASK>,<CTL_SHIFT>
	  FLAG_ID = KB_FLAG_ID
       ELSE
       IFIDN <FLAG_MASK>,<R_ALT_SHIFT>
	  FLAG_ID = KB_FLAG_3_ID
       ELSE
       IFIDN <FLAG_MASK>,<R_CTL_SHIFT>
	  FLAG_ID = KB_FLAG_3_ID
       ELSE
       IFIDN <FLAG_MASK>,<TILDE>
	  FLAG_ID = NLS_FLAG_1_ID
       ELSE
       IFIDN <FLAG_MASK>,<ACUTE>
	  FLAG_ID = NLS_FLAG_1_ID
       ELSE
       IFIDN <FLAG_MASK>,<GRAVE>
	  FLAG_ID = NLS_FLAG_1_ID
       ELSE
       IFIDN <FLAG_MASK>,<DIARESIS>
	  FLAG_ID = NLS_FLAG_1_ID
       ELSE
       IFIDN <FLAG_MASK>,<CEDILLA>
	  FLAG_ID = NLS_FLAG_1_ID
       ELSE
       IFIDN <FLAG_MASK>,<CIRCUMFLEX>
	  FLAG_ID = NLS_FLAG_1_ID
       ELSE
       IFIDN <FLAG_MASK>,<LC_E0>
	  FLAG_ID = KB_FLAG_3_ID
       ELSE
	  FLAG_ID = UNKNOWN
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
       ENDIF
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FLAG MACRO  FLAG_MASK
       FIND_FLAG FLAG_MASK
       IF (FLAG_ID EQ UNKNOWN)
	  IF2
	      %OUT Unknown parameter FLAG_MASK on FLAG MACRO
	  ENDIF
       ELSE
	  DB FLAG_ID
	  DB FLAG_MASK
       ENDIF
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IFF MACRO  FLAG_MASK,MASK_TYPE
    MAC_OK = 1
    IFB  <MASK_TYPE>
	 NOT_BIT = 00000000B
    ELSE
	 IFIDN <MASK_TYPE>,<NOT>
	     NOT_BIT = 00001000B
	 ELSE
	     MAC_OK = 0
	     IF2
		 %OUT Unknown parameter MASK_TYPE on IFF MACRO
	     ENDIF
	 ENDIF
    ENDIF
    IF MAC_OK
       FIND_FLAG FLAG_MASK
       IF (FLAG_ID EQ UNKNOWN)
	  IF2
	      %OUT Unknown parameter FLAG_MASK on IFF MACRO
	  ENDIF
       ELSE
	  DB IFF_COMMAND+NOT_BIT+FLAG_ID
	  DB FLAG_MASK
       ENDIF
    ENDIF
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IFKBD MACRO  SYS
       DB IFKBD_COMMAND
       DW SYS
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ANDF MACRO  FLAG_MASK,MASK_TYPE
    MAC_OK = 1
    IFB  <MASK_TYPE>
	 NOT_BIT = 00000000B
    ELSE
	 IFIDN <MASK_TYPE>,<NOT>
	     NOT_BIT = 00001000B
	 ELSE
	     MAC_OK = 0
	     IF2
		 %OUT Unknown parameter MASK_TYPE on ANDF MACRO
	     ENDIF
	 ENDIF
    ENDIF
    IF MAC_OK
       FIND_FLAG FLAG_MASK
       IF (FLAG_ID EQ UNKNOWN)
	  IF2
	      %OUT Unknown parameter FLAG_MASK on ANDF MACRO
	  ENDIF
       ELSE
	  DB ANDF_COMMAND+NOT_BIT+FLAG_ID
	  DB FLAG_MASK
       ENDIF
    ENDIF
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ELSEF  MACRO
       DB  ELSEF_COMMAND
       ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ENDIFF MACRO
       DB  ENDIFF_COMMAND
       ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
XLATT  MACRO STATE
       DB  XLATT_COMMAND
       DB  STATE
       ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PUT_ERROR_CHAR	MACRO STATE
       DB  PUT_ERROR_COMMAND
       DB  STATE
       ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPTION MACRO MASK,MASK_TYPE
    MAC_OK = 1
    IFB  <MASK_TYPE>
	 NOT_BIT = 00000000B
    ELSE
	 IFIDN <MASK_TYPE>,<NOT>
	     NOT_BIT = 00001000B
	 ELSE
	     MAC_OK = 0
	     IF2
		 %OUT Unknown parameter MASK_TYPE on OPTION MACRO
	     ENDIF
	 ENDIF
    ENDIF
    IF MAC_OK
       DB  OPTION_COMMAND+NOT_BIT
       DB  MASK
    ENDIF
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_FLAG  MACRO STATE
       DB  SET_FLAG_COMMAND
       DB  STATE
       ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESET_NLS  MACRO
       DB  RESET_NLS_COMMAND
       ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BEEP   MACRO
       DB  BEEP_COMMAND
       ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GOTO	MACRO GOTO_OFFSET
       DB  GOTO_COMMAND
       DW  GOTO_OFFSET-$-2
       ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EXIT_INT_9  MACRO
       DB  GOTO_COMMAND+EXIT_INT_9_FLAG
       DW  0
       ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EXIT_STATE_LOGIC  MACRO
       DB  GOTO_COMMAND+EXIT_STATE_LOGIC_FLAG
       DW  0
       ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHECK_FOR_CORE_KEY MACRO
       DB  CHECK_CORE_COMMAND
       ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.LIST
