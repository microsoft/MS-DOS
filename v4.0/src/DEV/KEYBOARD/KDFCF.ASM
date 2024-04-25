
	PAGE	,132
	TITLE	DOS - KEYBOARD.SYS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - - NLS Support - KEYBOARD.SYS
;; (c) Copyright 1988 Microsoft
;;
;; This file contains the keyboard table for Canadian French
;;
;; Linkage Instructions:
;;    Refer to KDF.ASM
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
	INCLUDE KEYBSHAR.INC	       ;;
	INCLUDE POSTEQU.INC	       ;;
	INCLUDE KEYBMAC.INC	       ;;
				       ;;
	PUBLIC CF_LOGIC 	       ;;
	PUBLIC CF_863_XLAT	       ;;
	PUBLIC CF_850_XLAT	       ;;
				       ;;
CODE	SEGMENT PUBLIC 'CODE'          ;;
	ASSUME CS:CODE,DS:CODE	       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Standard translate table options are a liner search table
;; (TYPE_2_TAB) and ASCII entries ONLY (ASCII_ONLY)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
STANDARD_TABLE	    EQU   TYPE_2_TAB+ASCII_ONLY
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; CF State Logic
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
CF_LOGIC:			       ;;
				       ;;
   DW  LOGIC_END-$		       ;; length
				       ;;
   DW  JR_HOT_KEY_1_2		     ;; special features
				       ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; COMMANDS START HERE
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OPTIONS:  If we find a scan match in
;; an XLATT or SET_FLAG operation then
;; exit from INT 9.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   OPTION EXIT_IF_FOUND 	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Dead key definitions must come before
;;  dead key translations to handle
;;  dead key + dead key.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   IFF	EITHER_ALT,NOT		       ;;
   ANDF EITHER_CTL,NOT		       ;;
      IFF CIRCUMFLEX		       ;;
	  RESET_NLS		       ;;
	  XLATT CIRCUMFLEX_CIRCUMFLEX  ;;
	  GOTO CIRCUMFLEX_ON	       ;;
      ENDIFF			       ;;
      IFF GRAVE 		       ;;
	  RESET_NLS		       ;;
	  XLATT GRAVE_GRAVE	       ;;
	  GOTO GRAVE_ON 	       ;;
      ENDIFF			       ;;
      IFF EITHER_SHIFT		       ;;
	  IFF DIARESIS		       ;;
	      RESET_NLS 	       ;;
	      XLATT DIARESIS_DIARESIS  ;;
	      GOTO DIARESIS_ON	       ;;
	  ENDIFF		       ;;
	  SET_FLAG DEAD_UPPER	       ;;
      ELSEF			       ;;
	  IFF CEDILLA		       ;;
	      RESET_NLS 	       ;;
	      XLATT CEDILLA_CEDILLA    ;;
	      GOTO CEDILLA_ON	       ;;
	  ENDIFF		       ;;
	  SET_FLAG DEAD_LOWER	       ;;
      ENDIFF			       ;;
   ELSEF			       ;;
      IFF  R_ALT_SHIFT,NOT	       ;;
      ANDF ALT_SHIFT		       ;;
	 IFF  EITHER_SHIFT	       ;; Third shift is activated by ALT_GR
				       ;; OR ALT + SHIFT.
	     IFF ACUTE		       ;;
		RESET_NLS	       ;;
		XLATT ACUTE_ACUTE      ;;
		GOTO ACUTE_ON	       ;;
	     ENDIFF		       ;;
	     SET_FLAG DEAD_THIRD       ;;
	 ENDIFF 		       ;;
      ELSEF			       ;;
	 IFF R_ALT_SHIFT	       ;;
;;;**************************************
;;;	       BIOS sets ALT_SHIFT when R_ALT_SHIFT is pressed.
;;;	       We must suppress this to detect both ALT keys simultaneously.
;;;	     ANDF ALT_SHIFT,NOT        ;;
;;;**************************************
	 ANDF EITHER_SHIFT,NOT	       ;;
	     IFF ACUTE		       ;;
		 RESET_NLS	       ;;
		 XLATT ACUTE_ACUTE     ;;
		 GOTO ACUTE_ON	       ;;
	     ENDIFF		       ;;
	     SET_FLAG DEAD_THIRD       ;;
	 ENDIFF 		       ;;
      ENDIFF			       ;;
   ENDIFF			       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ACUTE ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
ACUTE_PROC:			       ;;
				       ;;
   IFF ACUTE,NOT		       ;;
      GOTO GRAVE_PROC		       ;;
      ENDIFF			       ;;
				       ;;
      RESET_NLS 		       ;;
ACUTE_ON:			       ;;
      IFF R_ALT_SHIFT,NOT	       ;;
	 XLATT ACUTE_SPACE	       ;;
      ENDIFF			       ;;
      IFF EITHER_CTL,NOT	       ;;
      ANDF EITHER_ALT,NOT	       ;;
	 IFF EITHER_SHIFT	       ;;
	    IFF CAPS_STATE	       ;;
	       XLATT ACUTE_LOWER       ;;
	    ELSEF		       ;;
	       XLATT ACUTE_UPPER       ;;
	    ENDIFF		       ;;
	 ELSEF			       ;;
	    IFF CAPS_STATE	       ;;
	       XLATT ACUTE_UPPER       ;;
	    ELSEF		       ;;
	       XLATT ACUTE_LOWER       ;;
	    ENDIFF		       ;;
	 ENDIFF 		       ;;
      ENDIFF			       ;;
				       ;;
INVALID_ACUTE:			       ;;
				       ;; If we get here then either the XLATT
      BEEP			       ;; failed or we are ina bad shift state.
      EXIT_INT_9		       ;; Either is invalid so BEEP.
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GRAVE ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
GRAVE_PROC:			       ;;
				       ;;
   IFF GRAVE,NOT		       ;;
      GOTO DIARESIS_PROC	       ;;
      ENDIFF			       ;;
				       ;;
      RESET_NLS 		       ;;
GRAVE_ON:			       ;;
      IFF R_ALT_SHIFT,NOT	       ;;
	 XLATT GRAVE_SPACE	       ;;
      ENDIFF			       ;;
      IFF EITHER_CTL,NOT	       ;;
      ANDF EITHER_ALT,NOT	       ;;
	IFF EITHER_SHIFT	       ;;
	   IFF CAPS_STATE	       ;;
	      XLATT GRAVE_LOWER        ;;
	   ELSEF		       ;;
	      XLATT GRAVE_UPPER        ;;
	   ENDIFF		       ;;
	ELSEF			       ;;
	   IFF CAPS_STATE	       ;;
	      XLATT GRAVE_UPPER        ;;
	   ELSEF		       ;;
	      XLATT GRAVE_LOWER        ;;
	   ENDIFF		       ;;
	ENDIFF			       ;;
      ENDIFF			       ;;
				       ;;
INVALID_GRAVE:			       ;;
				       ;; If we get here then either the XLATT
      BEEP			       ;; failed or we are ina bad shift state.
      EXIT_INT_9		       ;; Either is invalid so BEEP.
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DIARESIS ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
DIARESIS_PROC:			       ;;
				       ;;
   IFF DIARESIS,NOT		       ;;
      GOTO CIRCUMFLEX_PROC	       ;;
      ENDIFF			       ;;
				       ;;
      RESET_NLS 		       ;;
DIARESIS_ON:			       ;;
      IFF R_ALT_SHIFT,NOT	       ;;
	 XLATT DIARESIS_SPACE	       ;;
      ENDIFF			       ;;
      IFF EITHER_CTL,NOT	       ;;
      ANDF EITHER_ALT,NOT	       ;;
	 IFF EITHER_SHIFT	       ;;
	    IFF CAPS_STATE	       ;;
	       XLATT DIARESIS_LOWER    ;;
	    ELSEF		       ;;
	       XLATT DIARESIS_UPPER    ;;
	    ENDIFF		       ;;
	 ELSEF			       ;;
	    IFF CAPS_STATE	       ;;
	       XLATT DIARESIS_UPPER    ;;
	    ELSEF		       ;;
	       XLATT DIARESIS_LOWER    ;;
	    ENDIFF		       ;;
	 ENDIFF 		       ;;
      ENDIFF			       ;;
				       ;;
INVALID_DIARESIS:		       ;;
				       ;; If we get here then either the XLATT
      BEEP			       ;; failed or we are ina bad shift state.
      EXIT_INT_9		       ;; Either is invalid so BEEP.
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CIRCUMFLEX ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
CIRCUMFLEX_PROC:		       ;;
				       ;;
   IFF CIRCUMFLEX,NOT		       ;;
      GOTO CEDILLA_PROC 	       ;;
      ENDIFF			       ;;
				       ;;
      RESET_NLS 		       ;;
CIRCUMFLEX_ON:			       ;;
      IFF R_ALT_SHIFT,NOT	       ;;
	 XLATT CIRCUMFLEX_SPACE        ;;
      ENDIFF			       ;;
      IFF EITHER_CTL,NOT	       ;;
      ANDF EITHER_ALT,NOT	       ;;
	IFF EITHER_SHIFT	       ;;
	   IFF CAPS_STATE	       ;;
	      XLATT CIRCUMFLEX_LOWER   ;;
	   ELSEF		       ;;
	      XLATT CIRCUMFLEX_UPPER   ;;
	   ENDIFF		       ;;
	ELSEF			       ;;
	   IFF CAPS_STATE	       ;;
	      XLATT CIRCUMFLEX_UPPER   ;;
	   ELSEF		       ;;
	      XLATT CIRCUMFLEX_LOWER   ;;
	   ENDIFF		       ;;
	ENDIFF			       ;;
      ENDIFF			       ;;
				       ;;
INVALID_CIRCUMFLEX:		       ;;
				       ;; If we get here then either the XLATT
      BEEP			       ;; failed or we are ina bad shift state.
      EXIT_INT_9		       ;; Either is invalid so BEEP.
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CEDILLA ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
CEDILLA_PROC:			       ;;
				       ;;
   IFF CEDILLA,NOT		       ;;
      GOTO NON_DEAD		       ;;
      ENDIFF			       ;;
				       ;;
      RESET_NLS 		       ;;
CEDILLA_ON:			       ;;
      IFF R_ALT_SHIFT,NOT	       ;;
	 XLATT CEDILLA_SPACE	       ;;
      ENDIFF			       ;;
      IFF EITHER_CTL,NOT	       ;;
      ANDF EITHER_ALT,NOT	       ;;
	IFF EITHER_SHIFT	       ;;
	   IFF CAPS_STATE	       ;;
	      XLATT CEDILLA_LOWER      ;;
	   ELSEF		       ;;
	      XLATT CEDILLA_UPPER      ;;
	   ENDIFF		       ;;
	ELSEF			       ;;
	   IFF CAPS_STATE	       ;;
	      XLATT CEDILLA_UPPER      ;;
	   ELSEF		       ;;
	      XLATT CEDILLA_LOWER      ;;
	   ENDIFF		       ;;
	ENDIFF			       ;;
      ENDIFF			       ;;
				       ;;
INVALID_CEDILLA:		       ;;
				       ;; If we get here then either the XLATT
      BEEP			       ;; failed or we are ina bad shift state.
      EXIT_INT_9		       ;; Either is invalid so BEEP.
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Upper, lower and third shifts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
NON_DEAD:			       ;;
   IFKBD G_KB+P12_KB		       ;;
   ANDF LC_E0			       ;;
      EXIT_STATE_LOGIC		       ;;
   ENDIFF			       ;;
				       ;;
   IFF	EITHER_ALT,NOT		       ;; Lower and upper case.  Alphabetic
   ANDF EITHER_CTL,NOT		       ;; keys are affected by CAPS LOCK.
      GOTO NO_THIRD		       ;;
      ENDIFF			       ;;
				       ;;
      IFF  R_ALT_SHIFT,NOT	       ;; Third shift is activated by ALT_GR
      ANDF ALT_SHIFT		       ;; OR ALT + SHIFT.
	 IFF EITHER_SHIFT	       ;;
	     XLATT THIRD_SHIFT	       ;;
	     IFF SCAN_MATCH,NOT        ;;
		EXIT_INT_9	       ;;
	     ENDIFF		       ;;
	 ENDIFF 		       ;;
      ELSEF			       ;;
	 IFF R_ALT_SHIFT	       ;;
;;;**************************************
;;;	      BIOS sets ALT_SHIFT when R_ALT_SHIFT is pressed.
;;;	      We must suppress this to detect both ALT keys simultaneously.
;;;	 ANDF ALT_SHIFT,NOT	       ;;
;;;**************************************
	 ANDF EITHER_SHIFT,NOT	       ;;
	     XLATT THIRD_SHIFT	       ;;
	     IFF SCAN_MATCH,NOT        ;;
		EXIT_INT_9	       ;;
	     ENDIFF		       ;;
	 ENDIFF 		       ;;
      ENDIFF			       ;;
				       ;;
      EXIT_STATE_LOGIC		       ;;
				       ;;
				       ;;
NO_THIRD:			       ;; Lower and upper case.  Alphabetic
				       ;; keys are affected by CAPS LOCK.
      IFF EITHER_SHIFT		       ;; Numeric keys are not.
	  XLATT NON_ALPHA_UPPER        ;;
	  IFF CAPS_STATE	       ;;
	      XLATT ALPHA_LOWER        ;;
	  ELSEF 		       ;;
	      XLATT ALPHA_UPPER        ;;
	  ENDIFF		       ;;
      ELSEF			       ;;
	  XLATT NON_ALPHA_LOWER        ;;
	  IFF CAPS_STATE	       ;;
	     XLATT ALPHA_UPPER	       ;;
	  ELSEF 		       ;;
	     XLATT ALPHA_LOWER	       ;;
	  ENDIFF		       ;;
      ENDIFF			       ;;
				       ;;
      EXIT_STATE_LOGIC		       ;;
				       ;;
LOGIC_END:			       ;;
				       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; CF Common Translate Section
;; This section contains translations for the lower 128 characters
;; only since these will never change from code page to code page.
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC CF_COMMON_XLAT		       ;;
CF_COMMON_XLAT: 		       ;;
				       ;;
   DW	   COMMON_XLAT_END-$	       ;; length of Common Tranlate Section
   DW	   -1			       ;; code page
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Lower Shift Dead Key
;; KEYBOARD: All
;; TABLE TYPE: Set Dead Key Flag
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 COM_DE_LO_END-$	       ;;
				       ;;  label format:
				       ;;    codepage_state_n_END
				       ;;	codepage = COMmon
				       ;;		   codepage1,
				       ;;		   codepage2.
				       ;;	state refers to
				       ;;	alpha, case, and dead:
				       ;;	 DE_LO:  DEAD_LOWER
				       ;;	 DE_UP:  DEAD_UPPER
				       ;;	 DE_TH:  DEAD_THIRD
				       ;;	 AL_LO:  ALPHA_LOWER
				       ;;	 AL_UP:  ALPHA_UPPER
				       ;;	 NA_LO:  NON_ALPHA_LOWER
				       ;;	 NA_UP:  NON_ALPHA_UPPER
				       ;;	 NA_TH:  THIRD_SHIFT
				       ;;	 AC_LO:  ACUTE_LOWER
				       ;;	 AC_UP:  ACUTE_UPPER
				       ;;	 AC_SP:  ACUTE_SPACE
				       ;;	 AC_AC:  ACUTE_ACUTE
				       ;;	 GR_LO:  GRAVE_LOWER
				       ;;	 GR_UP:  GRAVE_UPPER
				       ;;	 GR_SP:  GRAVE_SPACE
				       ;;	 GR_GR:  GRAVE_GRAVE
				       ;;	 DI_LO:  DIARESIS_LOWER
				       ;;	 DI_UP:  DIARESIS_UPPER
				       ;;	 DI_SP:  DIARESIS_SPACE
				       ;;	 DI_DI:  DIARESIS_DIARESIS
				       ;;	 CI_LO:  CIRCUMFLEX_LOWER
				       ;;	 CI_UP:  CIRCUMFLEX_UPPER
				       ;;	 CI_SP:  CIRCUMFLEX_SPACE
				       ;;	 CI_CI:  CIRCUMFLEX_CIRCUMFLEX
				       ;;	 CE_LO:  CEDILLA_LOWER
				       ;;	 CE_UP:  CEDILLA_UPPER
				       ;;	 CE_SP:  CEDILLA_SPACE
				       ;;	 CE_CE:  CEDILLA_CEDILLA
				       ;;
				       ;;	 n = 1,2,... to distinguish
				       ;;	     for different KB
   DB	 DEAD_LOWER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 3			       ;; number of dead keys
   DB	 40			       ;; scan code
   FLAG  GRAVE			       ;; flag bit assignment
   DB	 26			       ;;
   FLAG  CIRCUMFLEX		       ;;
   DB	 27			       ;;
   FLAG  CEDILLA		       ;;
COM_DE_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Upper Shift Dead Key
;; KEYBOARD: ALL
;; TABLE TYPE: Set Dead Key Flag
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 COM_DE_UP_END-$	       ;;
   DB	 DEAD_UPPER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 3			       ;; number of dead keys
   DB	 40			       ;; scan code
   FLAG  GRAVE			       ;; flag bit assignment
   DB	 26			       ;;
   FLAG  CIRCUMFLEX		       ;;
   DB	 27			       ;;
   FLAG  DIARESIS		       ;;
COM_DE_UP_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift Dead Key
;; KEYBOARD: All
;; TABLE TYPE: Set Dead Key Flag
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 COM_DE_TH_END-$	       ;;
   DB	 DEAD_THIRD		       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 1			       ;; number of dead keys
   DB	 53			       ;; scan code
   FLAG  ACUTE			       ;; flag bit assignment
COM_DE_TH_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Lower Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AL_LO_END-$	       ;; Length of state section
   DB	 ALPHA_LOWER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_000400-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 53,'Ç'                        ;;
CF_000400:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AL_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Upper Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AL_UP_END-$	       ;;
   DB	 ALPHA_UPPER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_002400-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 53,'ê'                        ;;
CF_002400:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AL_UP_END:			       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-alpha lower Case
;; KEYBOARD: G_KB, P_KB, P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_1_END-$	       ;; Length of state section
   DB	 NON_ALPHA_LOWER	       ;;
   DW	 G_KB+P_KB+P12_KB	       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_004300-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 41,'#'                        ;;
   DB	 43,'<'                        ;;
   DB	 86,'Æ'                        ;;
CF_004300:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_1_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-alpha lower Case
;; KEYBOARD: XT_KB, AT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_2_END-$	       ;; Length of state section
   DB	 NON_ALPHA_LOWER	       ;;
   DW	 XT_KB+AT_KB		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_004400-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 2			       ;; number of scans
   DB	 41,'<'                        ;;
   DB	 43,'\'                        ;;
CF_004400:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table : null
				       ;;
COM_NA_LO_2_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-alpha lower Case
;; KEYBOARD: JR_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_3_END-$	       ;; Length of state section
   DB	 NON_ALPHA_LOWER	       ;;
   DW	 JR_KB			       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_004401-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 51,','                        ;;
CF_004401:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table : null
				       ;;
COM_NA_LO_3_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-alpha Upper Case
;; KEYBOARD: G_KB, P_KB, P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_1_END-$	       ;; Length of state section
   DB	 NON_ALPHA_UPPER	       ;;
   DW	 G_KB+P_KB+P12_KB	       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_005300-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 8			       ;; number of scans
   DB	 3,'"'                         ;;
   DB	 4,'/'                         ;;
   DB	 7,'?'                         ;;
   DB	 41,'|'                        ;;
   DB	 43,'>'                        ;;
   DB	 51,27H 		       ;;    single quote
   DB	 52,'.'                        ;;
   DB	 86,'Ø'                        ;;
CF_005300:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_1_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-alpha Upper Case
;; KEYBOARD: XT_KB+AT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_2_END-$	       ;; Length of state section
   DB	 NON_ALPHA_UPPER	       ;;
   DW	 XT_KB+AT_KB		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_005400-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 7			       ;; number of scans
   DB	 3,'"'                         ;;
   DB	 4,'/'                         ;;
   DB	 7,'?'                         ;;
   DB	 41,'>'                        ;;
   DB	 43,'|'                        ;;
   DB	 51,27H 		       ;;    single quote
   DB	 52,'.'                        ;;    period
CF_005400:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table : null
				       ;;
COM_NA_UP_2_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-alpha Upper Case
;; KEYBOARD: JR_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_3_END-$	       ;; Length of state section
   DB	 NON_ALPHA_UPPER	       ;;
   DW	 JR_KB			       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_005100-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 5			       ;;
   DB	 3,'"'                         ;;
   DB	 4,'/'                         ;;
   DB	 7,'?'                         ;;
   DB	 51,27H 		       ;;    single quote
   DB	 52,02EH		       ;;    period
CF_005100:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table : null
				       ;;
				       ;;
COM_NA_UP_3_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-alpha Third Case
;; KEYBOARD: G_KB, P_KB, P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_TH_1_END-$	       ;; Length of state section
   DB	 THIRD_SHIFT		       ;;
   DW	 G_KB+P_KB+P12_KB	       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_007760-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 18			       ;; number of scans
   DB	 2,'Ò'                         ;;
   DB	 3,'@'                         ;;
   DB	 4,'ú'                         ;;
   DB	 7,'™'                         ;;
   DB	 9,'˝'                         ;;
   DB	 11,'¨'                        ;;
   DB	 12,'´'                        ;;
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 39,'~'                        ;;
   DB	 40,'{'                        ;;
   DB	 41,'\'                        ;;
   DB	 43,'}'                        ;;
   DB	 47,'Æ'                        ;;
   DB	 48,'Ø'                        ;;
   DB	 49,'¯'                        ;;
   DB	 50,'Ê'                        ;;
   DB	 86,'¯'                        ;;
CF_007760:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_TH_1_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-alpha Third Case
;; KEYBOARD: XT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_TH_2_END-$	       ;; Length of state section
   DB	 THIRD_SHIFT		       ;;
   DW	 XT_KB			       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_006500-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 17			       ;; number of scans
   DB	 2,'Ò'                         ;;
   DB	 3,'@'                         ;;
   DB	 4,'ú'                         ;;
   DB	 7,'™'                         ;;
   DB	 9,'˝'                         ;;
   DB	 11,'¨'                        ;;
   DB	 12,'´'                        ;;
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 39,'~'                        ;;
   DB	 40,'{'                        ;;
   DB	 41,'}'                        ;;
   DB	 43,'#'                        ;;
   DB	 47,'Æ'                        ;;
   DB	 48,'Ø'                        ;;
   DB	 49,'¯'                        ;;
   DB	 50,'Ê'                        ;;
CF_006500:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_TH_2_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-alpha Third Case
;; KEYBOARD: AT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_TH_3_END-$	       ;; Length of state section
   DB	 THIRD_SHIFT		       ;;
   DW	 AT_KB			       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_006300-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 17			       ;; number of scans
   DB	 2,'Ò'                         ;;
   DB	 3,'@'                         ;;
   DB	 4,'ú'                         ;;
   DB	 7,'™'                         ;;
   DB	 9,'˝'                         ;;
   DB	 11,'¨'                        ;;
   DB	 12,'´'                        ;;
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 38,'~'                        ;;
   DB	 39,'{'                        ;;
   DB	 40,'}'                        ;;
   DB	 43,'#'                        ;;
   DB	 47,'Æ'                        ;;
   DB	 48,'Ø'                        ;;
   DB	 49,'¯'                        ;;
   DB	 50,'Ê'                        ;;
CF_006300:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_TH_3_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-alpha Third Case
;; KEYBOARD: PCJR
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CF_COM_NA_TH_4_END-$	       ;; Length of state section
   DB	 THIRD_SHIFT		       ;;
   DW	 JR_KB			       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_007100-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 21			       ;;
   DB	 2,'Ò'                         ;;
   DB	 3,'@'                         ;;
   DB	 4,'ú'                         ;;
   DB	 7,'™'                         ;;
   DB	 9,'Ê'                         ;;
   DB	 11,'˝'                        ;;
   DB	 16,'¨'                        ;;
   DB	 17,'´'                        ;;
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 30,'<'                        ;;
   DB	 31,'>'                        ;;
   DB	 38,'~'                        ;;
   DB	 39,'{'                        ;;
   DB	 40,'}'                        ;;
   DB	 44,'\'                        ;;
   DB	 45,'#'                        ;;
   DB	 46,'|'                        ;;
   DB	 47,'Æ'                        ;;
   DB	 48,'Ø'                        ;;
   DB	 49,'¯'                        ;;
CF_007100:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CF_COM_NA_TH_4_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Acute Lower Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AC_LO_END-$	       ;; Length of state section
   DB	 ACUTE_LOWER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_001100-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 18,'Ç'                        ;;
   DB	 24,'¢'                        ;;
   DB	 22,'£'                        ;;
CF_001100:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AC_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Acute Upper Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AC_UP_END-$	       ;; Length of state section
   DB	 ACUTE_UPPER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_003100-$			;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 18,'ê'                        ;;
CF_003100:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AC_UP_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Grave Lower Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_GR_LO_END-$	       ;; Length of state section
   DB	 GRAVE_LOWER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 '`',0                        ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_001200-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 30,'Ö'                        ;;
   DB	 18,'ä'                        ;;
   DB	 22,'ó'                        ;;
CF_001200:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_GR_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Grave + Space Bar
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_GR_SP_END-$	       ;; Length of state section
   DB	 GRAVE_SPACE		       ;;
   DW	 ANY_KB 		       ;;
   DB	 '`',0                         ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_004500-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,'`'                        ;;
CF_004500:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_GR_SP_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Grave + Grave
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_GR_GR_END-$	       ;; Length of state section
   DB	 GRAVE_GRAVE		       ;;
   DW	 ANY_KB 		       ;;
   DB	 '`',0                         ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_004501-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 40,'`'                        ;;
CF_004501:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_GR_GR_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Diaresis Lower Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DI_LO_END-$	       ;; Length of state section
   DB	 DIARESIS_LOWER 	       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_001400-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 18,'â'                        ;;
   DB	 23,'ã'                        ;;
   DB	 22,'Å'                        ;;
CF_001400:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_DI_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Circumflex Lower Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CI_LO_END-$	       ;; Length of state section
   DB	 CIRCUMFLEX_LOWER	       ;;
   DW	 ANY_KB 		       ;;
   DB	 '^',0                         ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_001300-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,'É'                        ;;
   DB	 18,'à'                        ;;
   DB	 23,'å'                        ;;
   DB	 24,'ì'                        ;;
   DB	 22,'ñ'                        ;;
CF_001300:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CI_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Circumflex + Space Bar
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CI_SP_END-$	       ;; Length of state section
   DB	 CIRCUMFLEX_SPACE	       ;;
   DW	 ANY_KB 		       ;;
   DB	 '^',0                         ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_004555-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,'^'                        ;;
CF_004555:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CI_SP_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Circumflex + Circumflex
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CI_CI_END-$	       ;; Length of state section
   DB	 CIRCUMFLEX_CIRCUMFLEX	       ;;
   DW	 ANY_KB 		       ;;
   DB	 '^',0                         ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_004551-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 26,'^'                        ;;
CF_004551:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CI_CI_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Diaresis Upper Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DI_UP_END-$	       ;; Length of state section
   DB	 DIARESIS_UPPER 	       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_003300-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 22,'ö'                        ;;
CF_003300:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_DI_UP_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Cedilla Lower Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CE_LO_END-$	       ;; Length of state section
   DB	 CEDILLA_LOWER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_001500-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 46,'á'                        ;;
CF_001500:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CE_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Cedilla Upper Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CE_UP_END-$	       ;; Length of state section
   DB	 CEDILLA_UPPER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_003400-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 46,'Ä'                        ;;
CF_003400:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CE_UP_END:			       ;;
				       ;;
   DW	 0			       ;; Last State
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COMMON_XLAT_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; CF 863 Translate Section
;; This section contains translations for the UPPER 128 characters
;; of Code Page 863.
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC CF_863_XLAT		       ;;
CF_863_XLAT:			       ;;
				       ;;
   DW	   CP863_XLAT_END-$	       ;; length of 863 Tranlate Section
   DW	   863			       ;; code page id
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 863
;; STATE: Non-alpha Third Case
;; KEYBOARD: G_B, P_KB, P12_KB
;;	     XT_KB, AT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP863_NA_TH_1_END-$	       ;; Length of state section
   DB	 THIRD_SHIFT		       ;;
   DW	 G_KB+P_KB+P12_KB+XT_KB+AT_KB  ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_106300-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 8			       ;; number of scan
   DB	 5,'õ'                         ;;
   DB	 6,98H			       ;;    international currency symbol
   DB	 8,0A0H 		       ;;    vertical line broken
   DB	 10,0A6H		       ;;    superscript 3
   DB	 13,0ADH		       ;;    3 quarters
   DB	 24,08FH		       ;;    section
   DB	 25,086H		       ;;    paragraph
   DB	 51,0A7H		       ;;    overscore
CF_106300:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP863_NA_TH_1_END:		       ;; Length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 863
;; STATE: Non-alpha Third Case
;; KEYBOARD: JR_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP863_NA_TH_2_END-$	       ;; Length of state section
   DB	 THIRD_SHIFT		       ;;
   DW	 JR_KB			       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_106600-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 8			       ;; number of scan
   DB	 5,'õ'                         ;;
   DB	 6,98H			       ;;    international currency symbol
   DB	 8,0A0H 		       ;;    vertical line broken
   DB	 12,0A6H		       ;;    superscript 3
   DB	 18,0ADH		       ;;    3 quarters
   DB	 24,08FH		       ;;    section
   DB	 25,086H		       ;;    paragraph
   DB	 51,0A7H		       ;;    overscore
CF_106600:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP863_NA_TH_2_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 863
;; STATE: Acute  INPUT: Space Bar
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP863_AC_SP_END-$	       ;; Length of state section
   DB	 ACUTE_SPACE		       ;;
   DW	 ANY_KB 		       ;;
   DB	 0A1H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_104500-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,0A1H		       ;;   acute
CF_104500:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP863_AC_SP_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 863
;; STATE: Acute  INPUT: Acute
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP863_AC_AC_END-$	       ;; Length of state section
   DB	 ACUTE_ACUTE		       ;;
   DW	 ANY_KB 		       ;;
   DB	 0A1H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_104505-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 53,0A1H		       ;;   acute
CF_104505:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP863_AC_AC_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 863
;; STATE: Grave Upper Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP863_GR_UP_END-$	       ;; Length of state section
   DB	 GRAVE_UPPER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_104700-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 30,8EH 		       ;;    A grave
   DB	 18,91H 		       ;;    E grave
   DB	 22,9DH 		       ;;    U grave
CF_104700:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP863_GR_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 863
;; STATE: Diaresis Upper Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP863_DI_UP_END-$	       ;; Length of state section
   DB	 DIARESIS_UPPER 	       ;;
   DW	 ANY_KB 		       ;;
   DB	 0A4H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_104800-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 2			       ;; number of scans
   DB	 18,94H 		       ;;    E diaeresis
   DB	 23,95H 		       ;;    I diaeresis
CF_104800:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP863_DI_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 863
;; STATE: Diaresis  INPUT: Space Bar
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP863_DI_SP_END-$	       ;; Length of state section
   DB	 DIARESIS_SPACE 	       ;;
   DW	 ANY_KB 		       ;;
   DB	 0A4H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_104550-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,0A4H		       ;;   diaeresis
CF_104550:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP863_DI_SP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 863
;; STATE: Diaresis  INPUT: Diaresis
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP863_DI_DI_END-$	       ;; Length of state section
   DB	 DIARESIS_DIARESIS	       ;;
   DW	 ANY_KB 		       ;;
   DB	 0A4H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_104551-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 27,0A4H		       ;;   diaeresis
CF_104551:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP863_DI_DI_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 863
;; STATE: Circumflex Upper Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP863_CI_UP_END-$	       ;; Length of state section
   DB	 CIRCUMFLEX_UPPER	       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_104750-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,84H 		       ;;    A circumflex
   DB	 18,92H 		       ;;    E circumflex
   DB	 23,0A8H		       ;;    I circumflex
   DB	 24,99H 		       ;;    O circumflex
   DB	 22,9EH 		       ;;    U circumflex
CF_104750:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP863_CI_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 863
;; STATE: Cedilla  INPUT: Space Bar
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP863_CE_SP_END-$	       ;; Length of state section
   DB	 CEDILLA_SPACE		       ;;
   DW	 ANY_KB 		       ;;
   DB	 0A5H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_104600-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,0A5H		       ;;   cedilla
CF_104600:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP863_CE_SP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 863
;; STATE: Cedilla  INPUT: Cedilla
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP863_CE_CE_END-$	       ;; Length of state section
   DB	 CEDILLA_CEDILLA	       ;;
   DW	 ANY_KB 		       ;;
   DB	 0A5H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_104601-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 27,0A5H		       ;;   cedilla
CF_104601:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP863_CE_CE_END:		       ;;
				       ;;
				       ;;
   DW	 0			       ;; Last State
CP863_XLAT_END: 		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; CF 850 Translate Section
;; This section contains translations for the UPPER 128 characters
;; of Code Page 850.
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC CF_850_XLAT		       ;;
CF_850_XLAT:			       ;;
				       ;;
   DW	   CP850_XLAT_END-$	       ;; length of 850 Tranlate Section
   DW	   850			       ;; code page id
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Non-alpha Third Case
;; KEYBOARD: G_KB, P_KB, P12_KB
;;	     XT_KB, AT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_NA_TH_1_END-$	       ;; Length of state section
   DB	 THIRD_SHIFT		       ;;
   DW	 G_KB+P_KB+P12_KB+XT_KB+AT_KB  ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_206300-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 8			       ;; number of scan
   DB	 5,0BDH 		       ;;    cent
   DB	 6,0CFH 		       ;;    international currency symbol
   DB	 8,0DDH 		       ;;    vertical line broken
   DB	 10,0FCH		       ;;    superscript 3
   DB	 13,0F3H		       ;;    3 quarters
   DB	 24,0F5H		       ;;    section
   DB	 25,0F4H		       ;;    paragraph
   DB	 51,0EEH		       ;;    overscore
CF_206300:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_NA_TH_1_END:		       ;; Length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Non-alpha Third Case
;; KEYBOARD: JR_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_NA_TH_2_END-$	       ;; Length of state section
   DB	 THIRD_SHIFT		       ;;
   DW	 JR_KB			       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_206600-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 8			       ;; number of scan
   DB	 5,0BDH 		       ;;    cent
   DB	 6,0CFH 		       ;;    international currency symbol
   DB	 8,0DDH 		       ;;    vertical line broken
   DB	 12,0FCH		       ;;    superscript 3
   DB	 18,0F3H		       ;;    3 quarters
   DB	 24,0F5H		       ;;    section
   DB	 25,0F4H		       ;;    paragraph
   DB	 51,0EEH		       ;;    overscore
CF_206600:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_NA_TH_2_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Acute Lower Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_LO_END-$	       ;; Length of state section
   DB	 ACUTE_LOWER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 0EFH,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_201100-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 30,'†'                        ;;
   DB	 23,'°'                        ;;
   DB	 21,0ECH		       ;; y acute
CF_201100:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_LO_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Acute Upper Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_UP_END-$	       ;; Length of state section
   DB	 ACUTE_UPPER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 0EFH,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_203100-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,0B5H		       ;;    A acute
   DB	 23,0D6H		       ;;    I acute
   DB	 24,0E0H		       ;;    O acute
   DB	 22,0E9H		       ;;    U acute
   DB	 21,0EDH		       ;;    Y acute
CF_203100:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Acute  INPUT: Space Bar
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_SP_END-$	       ;; Length of state section
   DB	 ACUTE_SPACE		       ;;
   DW	 ANY_KB 		       ;;
   DB	 0EFH,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_204500-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,0EFH		       ;;   acute
CF_204500:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_SP_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Acute  INPUT: Acute
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_AC_END-$	       ;; Length of state section
   DB	 ACUTE_ACUTE		       ;;
   DW	 ANY_KB 		       ;;
   DB	 0EFH,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_204501-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 53,0EFH		       ;;   acute
CF_204501:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_AC_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Grave Lower Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_GR_LO_END-$	       ;; Length of state section
   DB	 GRAVE_LOWER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_201200-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 2			       ;; number of scans
   DB	 23,'ç'                        ;;
   DB	 24,'ï'                        ;;
CF_201200:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_GR_LO_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Grave Upper Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_GR_UP_END-$	       ;; Length of state section
   DB	 GRAVE_UPPER		       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_203200-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,0B7H		       ;;    A grave
   DB	 18,0D4H		       ;;    E grave
   DB	 23,0DEH		       ;;    I grave
   DB	 24,0E3H		       ;;    O grave
   DB	 22,0EBH		       ;;    U grave
CF_203200:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_GR_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Diaresis Lower Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_DI_LO_END-$	       ;; Length of state section
   DB	 DIARESIS_LOWER 	       ;;
   DW	 ANY_KB 		       ;;
   DB	 0F9H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_201400-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 30,'Ñ'                        ;;
   DB	 24,'î'                        ;;
   DB	 21,'ò'                        ;;
CF_201400:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_DI_LO_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Diaresis Upper Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_DI_UP_END-$	       ;; Length of state section
   DB	 DIARESIS_UPPER 	       ;;
   DW	 ANY_KB 		       ;;
   DB	 0F9H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_203400-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 4			       ;; number of scans
   DB	 30,'é'                        ;;
   DB	 18,0D3H		       ;;    E diaeresis
   DB	 23,0D8H		       ;;    I diaeresis
   DB	 24,'ô'                        ;;
CF_203400:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_DI_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Diaresis  INPUT: Space Bar
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_DI_SP_END-$	       ;; Length of state section
   DB	 DIARESIS_SPACE 	       ;;
   DW	 ANY_KB 		       ;;
   DB	 0F9H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_204550-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,0F9H		       ;;   diaeresis
CF_204550:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_DI_SP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Diaresis  INPUT: Diaresis
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_DI_DI_END-$	       ;; Length of state section
   DB	 DIARESIS_DIARESIS	       ;;
   DW	 ANY_KB 		       ;;
   DB	 0F9H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_204551-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 27,0F9H		       ;;   diaeresis
CF_204551:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_DI_DI_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Circumflex Upper Case
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_CI_UP_END-$	       ;; Length of state section
   DB	 CIRCUMFLEX_UPPER	       ;;
   DW	 ANY_KB 		       ;;
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_003305-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,0B6H		       ;;    A circumflex
   DB	 18,0D2H		       ;;    E circumflex
   DB	 23,0D7H		       ;;    I circumflex
   DB	 24,0E2H		       ;;    O circumflex
   DB	 22,0EAH		       ;;    U circumflex
CF_003305:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_CI_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Cedilla  INPUT: Space Bar
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_CE_SP_END-$	       ;; Length of state section
   DB	 CEDILLA_SPACE		       ;;
   DW	 ANY_KB 		       ;;
   DB	 0F7H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_204600-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,0F7H		       ;;   cedilla
CF_204600:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_CE_SP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Cedilla  INPUT: Cedilla
;; KEYBOARD: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_CE_CE_END-$	       ;; Length of state section
   DB	 CEDILLA_CEDILLA	       ;;
   DW	 ANY_KB 		       ;;
   DB	 0F7H,0 		       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 CF_204601-$		       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 27,0F7H		       ;;   cedilla
CF_204601:			       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_CE_CE_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 0			       ;; no more states
				       ;;
CP850_XLAT_END: 		       ;;

CODE   ENDS
       END
