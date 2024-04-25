;; LATEST CHANGE ALT & CTL "Z & Y", "-" symbol  (AT)
;; Eliminated zero scan tag from alpha upper CP section
;; SECTION SYMBOL
;; SCAN CODE OUTPUT CHANGES MADE 12/18/86
;; **************** CNS ************************
	PAGE	,132
	TITLE	DOS - Keyboard Definition File

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - - NLS Support - Keyboard Defintion File
;; (c) Copyright 1988 Microsoft
;;
;; This file contains the keyboard tables for Spanish.
;;
;; Linkage Instructions:
;;	Refer to KDF.ASM.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
	INCLUDE KEYBSHAR.INC	       ;;
	INCLUDE POSTEQU.INC	       ;;
	INCLUDE KEYBMAC.INC	       ;;
				       ;;
	PUBLIC GE_LOGIC 	       ;;
	PUBLIC GE_437_XLAT	       ;;
	PUBLIC GE_850_XLAT	       ;;
				       ;;
CODE	SEGMENT PUBLIC 'CODE'          ;;
	ASSUME CS:CODE,DS:CODE	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Standard translate table options are a liner search table
;; (TYPE_2_TAB) and ASCII entries ONLY (ASCII_ONLY)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
STANDARD_TABLE	    EQU   TYPE_2_TAB+ASCII_ONLY
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; GE State Logic
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
GE_LOGIC:

   DW  LOGIC_END-$		       ;; length
				       ;;
   DW  TYPEWRITER_CAPS_LK	       ;; special features (shift lock state)
				       ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; COMMANDS START HERE
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OPTIONS:  If we find a scan match in
;; an XLATT or SET_FLAG operation then
;; exit from INT 9.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   OPTION EXIT_IF_FOUND 	       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Dead key definitions must come before
;;  dead key translations to handle
;;  dead key + dead key.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   IFF	EITHER_ALT,NOT		       ;;
   ANDF EITHER_CTL,NOT		       ;;
    IFKBD G_KB+P12_KB		       ;; FUNCTIONS AS A SHIFT LOCK
     IFF CAPS_STATE		       ;;
     ANDF EITHER_SHIFT		       ;;
	 SET_FLAG DEAD_LOWER		;;
     ELSEF
	IFF CAPS_STATE			 ;;
	  SET_FLAG DEAD_UPPER	       ;;
	ELSEF
	 IFF EITHER_SHIFT		;;
	  SET_FLAG DEAD_UPPER	       ;;
	 ELSEF
	  SET_FLAG DEAD_LOWER	       ;; NORMAL STATE LC
	 ENDIFF 		      ;; SHIFT OR NORMAL CHECK END
	ENDIFF			      ;; CAPS OR SHIFT CHECK END
     ENDIFF			      ;; BOTH SHIFT LOCK AND CAPS END
    ELSEF			      ;;
     IFF CAPS_STATE			;; THIS MEANS IT IS A at OR xt
     ANDF EITHER_SHIFT
	 SET_FLAG DEAD_UPPER
     ELSEF
	IFF CAPS_STATE			 ;;
	  SET_FLAG DEAD_LOWER	       ;;
	ELSEF
	 IFF EITHER_SHIFT		;;
	  SET_FLAG DEAD_UPPER	       ;;
	 ELSEF
	  SET_FLAG DEAD_LOWER	       ;; NORMAL STATE LC
	 ENDIFF 		       ;; SHIFT OR NORMAL CHECK END
	ENDIFF			       ;; CAPS OR SHIFT CHECK END
      ENDIFF			       ;; BOTH SHIFT LOCK AND CAPS END ;;
    ENDIFF			       ;; IS IT ENHANCED OR NOT END
   ENDIFF			       ;; NO CONTROL OR ALT END
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ACUTE ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
ACUTE_PROC:			       ;;
				       ;;
   IFF ACUTE,NOT		       ;;
      GOTO DIARESIS_PROC	       ;;
      ENDIFF			       ;;
				       ;;
      RESET_NLS 		       ;;
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
      PUT_ERROR_CHAR ACUTE_LOWER       ;; If we get here then either the XLATT
      BEEP			       ;; failed or we are ina bad shift state.
      GOTO NON_DEAD		       ;; Either is invalid so BEEP and fall
				       ;; through to generate the second char.
				       ;; Note that the dead key flag will be
				       ;; reset before we get here.
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DIARESIS ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
DIARESIS_PROC:			       ;;
				       ;;
   IFF DIARESIS,NOT		       ;;
      GOTO GRAVE_PROC		       ;;
      ENDIFF			       ;;
				       ;;
      RESET_NLS 		       ;;
      IFF R_ALT_SHIFT,NOT	       ;;
	 XLATT DIARESIS_SPACE	       ;;  exist for 437 so beep for
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
      PUT_ERROR_CHAR DIARESIS_SPACE    ;; standalone accent
      BEEP			       ;; Invalid dead key combo.
      GOTO NON_DEAD		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GRAVE ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
GRAVE_PROC:			       ;;
				       ;;
   IFF GRAVE,NOT		       ;;
      GOTO CIRCUMFLEX_PROC	       ;;
      ENDIFF			       ;;
				       ;;
      RESET_NLS 		       ;;
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
	   IFF CAPS_STATE,NOT	       ;;
	      XLATT GRAVE_LOWER        ;;
	   ELSEF		       ;;
	      XLATT GRAVE_UPPER        ;;
	   ENDIFF		       ;;
	ENDIFF			       ;;
      ENDIFF			       ;;
				       ;;
INVALID_GRAVE:			       ;;
      PUT_ERROR_CHAR GRAVE_LOWER       ;; standalone accent
      BEEP			       ;; Invalid dead key combo.
      GOTO NON_DEAD		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CIRCUMFLEX ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
CIRCUMFLEX_PROC:		       ;;
				       ;;
   IFF CIRCUMFLEX,NOT		       ;;
      GOTO NON_DEAD		       ;;
      ENDIFF			       ;;
				       ;;
      RESET_NLS 		       ;;
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
	   IFF CAPS_STATE,NOT	       ;;
	      XLATT CIRCUMFLEX_LOWER   ;;
	   ELSEF		       ;;
	      XLATT CIRCUMFLEX_UPPER   ;;
	   ENDIFF		       ;;
	ENDIFF			       ;;
      ENDIFF			       ;;
				       ;;
INVALID_CIRCUMFLEX:		       ;;
      PUT_ERROR_CHAR CIRCUMFLEX_LOWER  ;; standalone accent
      BEEP			       ;; Invalid dead key combo.
      GOTO NON_DEAD		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Upper, lower and third shifts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
NON_DEAD:			       ;;
				       ;;
   IFKBD G_KB+P12_KB		       ;; Avoid accidentally translating
   ANDF LC_E0			       ;;  the "/" on the numeric pad of the
      EXIT_STATE_LOGIC		       ;;   G keyboard
   ENDIFF			       ;;
;;***BD ADDED FOR ALT, CTRL CASES      ;;
      IFF EITHER_CTL,NOT	       ;;
	 IFF  ALT_SHIFT 	       ;; ALT - case
	 ANDF R_ALT_SHIFT,NOT	       ;;
	    XLATT ALT_CASE	       ;;
	 ENDIFF 		       ;;
      ELSEF			       ;;
	 IFF EITHER_ALT,NOT	       ;; CTRL - case
	    XLATT CTRL_CASE	       ;;
	 ENDIFF 		       ;;
      ENDIFF			       ;;
;;***BD END OF ADDITION
				       ;;
   IFF	EITHER_ALT,NOT		       ;; Lower and upper case.  Alphabetic
   ANDF EITHER_CTL,NOT		       ;; keys are affected by CAPS LOCK.
      IFF EITHER_SHIFT		       ;; Numeric keys are not.
;;***BD ADDED FOR NUMERIC PAD
	  IFF NUM_STATE,NOT	       ;;
	      XLATT NUMERIC_PAD        ;;
	  ENDIFF		       ;;
;;***BD END OF ADDITION
;	  XLATT NON_ALPHA_UPPER        ;;  add in keyboard logic
	 IFKBD G_KB+P12_KB		 ;;  SHIFT STATE ONLY FOR P12 & G
	  IFF CAPS_STATE	       ;;  for AT and XT
	      XLATT ALPHA_LOWER        ;;
	      XLATT NON_ALPHA_LOWER    ;;
	  ELSEF 		       ;;
	      XLATT ALPHA_UPPER        ;;THIS MEANS normal SHIFT STATE
	   XLATT NON_ALPHA_UPPER	;;FOR G AND P12
	  ENDIFF		       ;;
	 ELSEF
	  IFF CAPS_STATE	       ;;  for AT and XT
	      XLATT ALPHA_LOWER        ;;  shift state & caps
	  XLATT NON_ALPHA_UPPER        ;;
	  ELSEF 		       ;;
	      XLATT ALPHA_UPPER        ;;  shift state & no caps
	      XLATT NON_ALPHA_UPPER	   ;;
	  ENDIFF		       ;;
	 ENDIFF
      ELSEF			       ;; SHIFT STATE DOES NOT EXIST
;;***BD ADDED FOR NUMERIC PAD
	  IFF NUM_STATE 	       ;;
	      XLATT NUMERIC_PAD        ;;
	  ENDIFF		       ;;
;;***BD END OF ADDITION
;;	  XLATT NON_ALPHA_LOWER        ;;
	 IFKBD G_KB+P12_KB	       ;; G & p12 NO shift state
	  IFF CAPS_STATE	       ;;
	     XLATT ALPHA_UPPER	       ;;
	     XLATT NON_ALPHA_UPPER	  ;;
	  ELSEF 		       ;;
	     XLATT ALPHA_LOWER	       ;;
	     XLATT NON_ALPHA_LOWER	  ;;
	  ENDIFF		       ;;
	 ELSEF			       ;;AT & XT WITH NO SHIFT
	  IFF CAPS_STATE	       ;;
	     XLATT ALPHA_UPPER	       ;;
	     XLATT NON_ALPHA_LOWER	  ;;
	  ELSEF 		       ;;
	     XLATT ALPHA_LOWER	       ;;
	     XLATT NON_ALPHA_LOWER	  ;;
	  ENDIFF		       ;;
	 ENDIFF
      ENDIFF			       ;;
   ELSEF			       ;;
      IFF EITHER_SHIFT,NOT	       ;;
	  IFKBD XT_KB+AT_KB	 ;;
	      IFF  EITHER_CTL	       ;;
	      ANDF ALT_SHIFT	       ;;
		  XLATT THIRD_SHIFT    ;;
	      ENDIFF		       ;;
	  ELSEF 		       ;;
	      IFF EITHER_CTL,NOT       ;;
	      ANDF R_ALT_SHIFT	       ;;
		  XLATT THIRD_SHIFT    ;;
	      ENDIFF		       ;;
	   ENDIFF		       ;;
      ENDIFF			       ;;
   ENDIFF			       ;;
				       ;;
   EXIT_STATE_LOGIC		       ;;
				       ;;
LOGIC_END:			       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; GE Common Translate Section
;; This section contains translations for the lower 128 characters
;; only since these will never change from code page to code page.
;; In addition the dead key "Set Flag" tables are here since the
;; dead keys are on the same keytops for all code pages.
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC GE_COMMON_XLAT		       ;;
GE_COMMON_XLAT: 		       ;;
				       ;;
   DW	 COMMON_XLAT_END-$	       ;; length of section
   DW	 -1			       ;; code page
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Lower Shift Dead Key
;; KEYBOARD TYPES: All
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_LO_END-$	       ;; length of state section
   DB	 DEAD_LOWER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 1			       ;; number of entries
   DB	 13			       ;; scan code
   FLAG  ACUTE			       ;; flag bit to set
				       ;;
				       ;;
COM_DK_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Upper Shift Dead Key
;; KEYBOARD TYPES: All
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_UP_END-$	       ;; length of state section
   DB	 DEAD_UPPER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 1			       ;; number of entries
   DB	 13			       ;; scan code
   FLAG  GRAVE			       ;; flag bit to set
COM_DK_UP_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alt Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_ALT_K1_END-$	       ;; length of state section
   DB	 ALT_CASE		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_ALT_K1_T1_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;; xlat options:
   DB	 2			       ;; 5 number of entries
;;***BD THIS ENTRY IS A TEST ENTRY
;; DB	 53,225,0		       ;; TEST ENTRY - switch  two keys
;  DB	 12,-1,-1		       ;; invalid key U.S. -
;  DB	 13,-1,-1		       ;; invalid key U.S. =
   DB	 21,0,44		       ;; alt z function
   DB	 44,0,21		       ;; alt y function
;  DB	 53,0,82H		       ;; alt - (minus sign)
COM_ALT_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_ALT_K1_END: 		       ;;
				       ;;
;;******************************
;;***BD - ADDED FOR CTRL CASE
;;******************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Ctrl Case
;; KEYBOARD TYPES: G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CTRL_K1_END-$	       ;; length of state section
   DB	 CTRL_CASE		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_CTRL_K1_T1_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;; xlat options:
   DB	 5			       ;; number of entries
;;***BD THIS ENTRY IS A TEST ENTRY
;; DB	 53,226,0		       ;; TEST ENTRY
   DB	 43,-1,-1		       ;; no backslash
   DB	 53,31,53		       ;; ctl + - or _
   DB	 21,1AH,21		       ;; ctl z function
   DB	 44,19h,44		       ;; ctl y function
   DB	 12,28,12		       ;;  \ position
COM_CTRL_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CTRL_K1_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Ctrl Case
;; KEYBOARD TYPES: AT
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CTRL_K2_END-$	       ;; length of state section
   DB	 CTRL_CASE		       ;; State ID
   DW	 AT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_CTRL_K2_T2_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;; xlat options:
   DB	 6			       ;; number of entries
;;***BD THIS ENTRY IS A TEST ENTRY
;; DB	 53,226,0		       ;; TEST ENTRY
   DB	 12,-1,-1		       ;; invalid key U.S. -
   DB	 43,-1,-1		       ;; no backslash
   DB	 53,31,53		       ;; ctl + - or _
   DB	 21,1AH,21		       ;; ctl z function
   DB	 44,19h,44		       ;; ctl y function
   DB	 41,28,41		       ;;  \ position
COM_CTRL_K2_T2_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CTRL_K2_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Ctrl Case
;; KEYBOARD TYPES: XT
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CTRL_K3_END-$	       ;; length of state section
   DB	 CTRL_CASE		       ;; State ID
   DW	 XT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_CTRL_K3_T3_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;; xlat options:
   DB	 6			       ;; number of entries
;;***BD THIS ENTRY IS A TEST ENTRY
;; DB	 53,226,0		       ;; TEST ENTRY
   DB	 43,-1,-1		       ;; no backslash
   DB	 12,-1,-1		       ;; invalid key U.S. -
   DB	 53,31,53		       ;; ctl + - or _
   DB	 21,1AH,21		       ;; ctl z function
   DB	 44,19h,44		       ;; ctl y function
   DB	 43,28,43		       ;;  \ position
COM_CTRL_K3_T3_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CTRL_K3_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AL_LO_END-$	       ;; length of state section
   DB	 ALPHA_LOWER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_AL_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 5			       ;; number of entries
   DB	 26,081h		       ;; diaresis - Å
   DB	 39,094h		       ;; diaresis - î
   DB	 40,084h		       ;; diaresis - Ñ
   DB	 44,'y'                        ;;
   DB	 21,'z'                        ;;                          ;;
COM_AL_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AL_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Upper Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AL_UP_END-$	       ;; length of state section
   DB	 ALPHA_UPPER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_AL_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 5			       ;; number of entries
   DB	 26,09AH		       ;; Diaresis - ö
   DB	 39,099H		       ;; Diaresis - ô
   DB	 40,08EH		       ;; Diaresis - é
   DB	 44,'Y'                        ;;
   DB	 21,'Z'                        ;;
COM_AL_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AL_UP_END:			       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;******************************
;;***BD - ADDED FOR NUMERIC PAD (DECIMAL SEPERATOR)
;;******************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Numeric Key Pad	       ;;**********CNS******************
;; KEYBOARD TYPES: G_KB 	       ;;change does not apply to P12
;; TABLE TYPE: Translate	       ;;P12 Key #54 has a comma available
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_PAD_K1_END-$	       ;; length of state section
   DB	 NUMERIC_PAD		       ;; State ID
   DW	 G_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_PAD_K1_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 1			       ;; number of entries
   DB	 83,44			       ;; decimal seperator = ,
COM_PAD_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_PAD_K1_END: 		       ;;
				       ;;
;;******************************
;; CODE PAGE: Common
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: G_KB + P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_K1_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_K1_T1_END-$	      ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 18				;; number of entries
   DB	 41,'^'                        ;;
   DB	 2,'1'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 3,'2'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 4,'3'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 5,'4'                        ;;
   DB	 6,'5'                        ;;
   DB	 7,'6'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 8,'7'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 9,'8'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 10,'9'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 11,'0'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 12,0E1H		       ;; ·
   DB	 27,'+'                        ;;
   DB	 43,'#'                        ;; pound sign
   DB	 86,'<'                        ;;
   DB	 51,','                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 52,'.'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 53,'-'                        ;;
COM_NA_LO_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_K1_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: AT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_K2_END-$		  ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 AT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_K2_T1_END-$		  ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 17			       ;; number of entries
   DB	 41,'<'                        ;; different than enhanced
   DB	 2,'1'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 3,'2'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 4,'3'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 5,'4'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 6,'5'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 7,'6'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 8,'7'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 9,'8'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 10,'9'                        ;;
   DB	 11,'0'                        ;;
   DB	 12,0E1H		       ;; ·
   DB	 27,'+'                        ;;
   DB	 43,'#'                        ;; pound sign
   DB	 51,','                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 52,'.'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 53,'-'                        ;;
COM_NA_LO_K2_T1_END:			  ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_K2_END:			  ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: XT_KB+
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_K3_END-$		  ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_K3_T1_END-$		  ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 17			       ;; number of entries
   DB	 2,'1'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 3,'2'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 4,'3'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 5,'4'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 6,'5'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 7,'6'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 8,'7'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 9,'8'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 10,'9'                        ;;
   DB	 11,'0'                        ;;
   DB	 12,0E1H		       ;; ·
   DB	 27,'+'                        ;;
   DB	 41,'#'                        ;; pound sign
   DB	 43,'<'                        ;;
   DB	 51,','                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 52,'.'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 53,'-'                        ;;
COM_NA_LO_K3_T1_END:			  ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_K3_END:			  ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: G_KB+P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_K1_END-$		  ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_UP_K1_T1_END-$		  ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 17			       ;; number of entries
   DB	 41,0F8H		       ;;
   DB	 3,'"'                        ;;
   DB	 2,'!'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 5,'$'                        ;;
   DB	 6,'%'                        ;;
   DB	 7,'&'                        ;;
   DB	 8,'/'                        ;;
   DB	 9,'('                        ;;
   DB	 10,')'                        ;;
   DB	 11,'='                        ;;
   DB	 12,'?'                        ;;
   DB	 27,'*'                        ;;
   DB	 43,"'"                        ;;
   DB	 86,'>'                        ;;
   DB	 51,';'                        ;;
   DB	 52,':'                        ;;
   DB	 53,'_'                        ;;

COM_NA_UP_K1_T1_END:			  ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_K1_END:			  ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: AT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_K2_END-$		  ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 AT_KB			      ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_UP_K2_T1_END-$		  ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 16			      ;; number of entries
   DB	 41,'>'                        ;;
   DB	  3,'"'                        ;;
   DB	 2,'!'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 5,'$'                        ;;
   DB	 6,'%'                        ;;
   DB	  7,'&'                        ;;
   DB	  8,'/'                        ;;
   DB	  9,'('                        ;;
   DB	 10,')'                        ;;
   DB	 11,'='                        ;;
   DB	 12,'?'                        ;;
   DB	 27,'*'                        ;;
   DB	 43,"^"                        ;;
   DB	 51,';'                        ;;
   DB	 52,':'                        ;;
   DB	 53,'_'                        ;;

COM_NA_UP_K2_T1_END:			  ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_K2_END:			  ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: XT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_K3_END-$		  ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 XT_KB			;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_UP_K3_T1_END-$		  ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 16			      ;; number of entries
   DB	  3,'"'                        ;;
   DB	 2,'!'                        ;;IMPLEMENTED FOR SHIFT STATE STATUS
   DB	 5,'$'                        ;;
   DB	 6,'%'                        ;;
   DB	  7,'&'                        ;;
   DB	  8,'/'                        ;;
   DB	  9,'('                        ;;
   DB	 10,')'                        ;;
   DB	 11,'='                        ;;
   DB	 12,'?'                        ;;
   DB	 27,'*'                        ;;
   DB	 41,"^"                        ;;
   DB	 43,'>'                        ;;
   DB	 51,';'                        ;;
   DB	 52,':'                        ;;
   DB	 53,'_'                        ;;

COM_NA_UP_K3_T1_END:			  ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_K3_END:			  ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift
;; KEYBOARD TYPES: G_KB+P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_THIRD_K1_END-$		  ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 G_KB+P12_KB			      ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_THIRD_K1_T1_END-$		  ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 11			       ;; number of entries
   DB	  3,0FDH		       ;; ˝
   DB	  4,0FCH		       ;; ¸ - converted to script 3 in Germany
   DB	  8,'{'                        ;;
   DB	  9,'['                        ;;
   DB	 10,']'                        ;;
   DB	 11,'}'                        ;;
   DB	 12,'\'                        ;;
   DB	 16,'@'                        ;;
   DB	 27,07EH		       ;; Tilde - ~
   DB	 86,07CH		       ;; Solid vertical bar
   DB	 50,0E6H		       ;; Ê - mu symbol
COM_THIRD_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Last xlat table
COM_THIRD_K1_END:			  ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift
;; KEYBOARD TYPES: AT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_THIRD_K2_END-$		  ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 AT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_THIRD_K2_T1_END-$		  ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 4			      ;; number of entries
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 41,'\'                        ;;
   DB	 3,'@'                        ;;
COM_THIRD_K2_T1_END:			  ;;
				       ;;
   DW	 0			       ;; Last xlat table
COM_THIRD_K2_END:			  ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift
;; KEYBOARD TYPES: XT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_THIRD_K3_END-$	       ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_THIRD_K3_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 4			       ;; number of entries
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 43,'\'                        ;;
   DB	 3,'@'                         ;;
COM_THIRD_K3_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Last xlat table
COM_THIRD_K3_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Acute Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				       ;;
;  DW	 COM_AC_LO_END-$	       ;; length of state section
;  DB	 ACUTE_LOWER		       ;; State ID
;  DW	 ANY_KB 		       ;; Keyboard Type
;  DB	 39,0			       ;; error character = standalone accent
;				       ;;
;  DW	 COM_AC_LO_T1_END-$	       ;; Size of xlat table
;  DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
;  DB	 5			       ;; number of scans
;  DB	 18,'Ç'                        ;; scan code,ASCII - e
;  DB	 30,'†'                        ;; scan code,ASCII - a
;  DB	 24,'¢'                        ;; scan code,ASCII - o
;  DB	 22,'£'                        ;; scan code,ASCII - u
;  DB	 23,'°'                        ;; scan code,ASCII - i
;COM_AC_LO_T1_END:			;;
;					;;
;   DW	  0				;; Size of xlat table - null table
;					;;
;COM_AC_LO_END: 			;;
;					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CODE PAGE: Common
;;; STATE: Acute Upper Case
;;; KEYBOARD TYPES: All
;;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					;;
;   DW	  COM_AC_UP_END-$		;; length of state section
;   DB	  ACUTE_UPPER			;; State ID
;   DW	  ANY_KB			;; Keyboard Type
;   DB	  39,0				;; error character = standalone accent
;					;;
;   DW	  COM_AC_UP_T1_END-$		;; Size of xlat table
;   DB	  STANDARD_TABLE+ZERO_SCAN	;; xlat options:
;   DB	  1				;; number of scans
;   DB	  18,'ê'                        ;; scan code,ASCII - e
;COM_AC_UP_T1_END:			;;
;					;;
;   DW	  0				;; Size of xlat table - null table
;					;;
;COM_AC_UP_END: 			;;
;					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CODE PAGE: Common
;;; STATE: Acute Space Bar
;;; KEYBOARD TYPES: All
;;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					;;
;   DW	  COM_AC_SP_END-$		;; length of state section
;   DB	  ACUTE_SPACE			;; State ID
;   DW	  ANY_KB			;; Keyboard Type
;   DB	  39,0				;; error character = standalone accent
;					;;
;   DW	  COM_AC_SP_T1_END-$		;; Size of xlat table
;   DB	  STANDARD_TABLE+ZERO_SCAN	;; xlat options:
;   DB	  1				;; number of scans
;   DB	  57,39 			;; scan code,ASCII - SPACE
;COM_AC_SP_T1_END:			;;
;					;;
;   DW	  0				;; Size of xlat table - null table
;					;;
;COM_AC_SP_END: 			;;
;;					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Grave Lower
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_GR_LO_END-$	       ;; length of state section
   DB	 GRAVE_LOWER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 96,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_GR_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 18,'ä'                        ;; scan code,ASCII - e
   DB	 30,'Ö'                        ;; scan code,ASCII - a
   DB	 24,'ï'                        ;; scan code,ASCII - o
   DB	 22,'ó'                        ;; scan code,ASCII - u
   DB	 23,'ç'                        ;; scan code,ASCII - i
COM_GR_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_GR_LO_END:			       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Grave Space Bar
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_GR_SP_END-$	       ;; length of state section
   DB	 GRAVE_SPACE		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 96,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_GR_SP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,96			       ;; STANDALONE GRAVE
COM_GR_SP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_GR_SP_END:			       ;; length of state section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 0			       ;; Last State
COMMON_XLAT_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; GE Specific Translate Section for 437
;; 437 IS COMPLETELY COVERED BY THE COMMON TABLE.
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC GE_437_XLAT		       ;;
GE_437_XLAT:			       ;;
				       ;;
   DW	  CP437_XLAT_END-$	       ;; length of section
   DW	  437			       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 437
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;; eliminated !!!!
   DW	 CP437_NA_LO_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; error character = standalone accent
				       ;;
   DW	 CP437_NA_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 0			       ;; number of scans
CP437_NA_LO_T1_END:		       ;;
				       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_NA_LO_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 437
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_NA_UP_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; error character = standalone accent
				       ;;
   DW	 CP437_NA_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 		;; xlat options:  ***** CNS 12/18
   DB	 1			       ;; number of scans
   DB	 4,015H 		       ;;   - Section symbol
CP437_NA_UP_T1_END:		       ;;
				       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_NA_UP_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 437
;; STATE: Acute Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_AC_LO_END-$		 ;; length of state section
   DB	 ACUTE_LOWER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 39,0			       ;; error character = standalone accent
				       ;;
   DW	 CP437_AC_LO_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 18,'Ç'                        ;; scan code,ASCII - e
   DB	 30,'†'                        ;; scan code,ASCII - a
   DB	 24,'¢'                        ;; scan code,ASCII - o
   DB	 22,'£'                        ;; scan code,ASCII - u
   DB	 23,'°'                        ;; scan code,ASCII - i
 CP437_AC_LO_T1_END:			  ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_AC_LO_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Acute Upper Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_AC_UP_END-$		 ;; length of state section
   DB	 ACUTE_UPPER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 39,0			       ;; error character = standalone accent
				       ;;
   DW	 CP437_AC_UP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 18,'ê'                        ;; scan code,ASCII - e
CP437_AC_UP_T1_END:			 ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_AC_UP_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Acute Space Bar
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_AC_SP_END-$		 ;; length of state section
   DB	 ACUTE_SPACE		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 39,0			       ;; error character = standalone accent
				       ;;
   DW	 CP437_AC_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,39			       ;; scan code,ASCII - SPACE
CP437_AC_SP_T1_END:			 ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_AC_SP_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	  0			       ;; LAST STATE
				       ;;
CP437_XLAT_END: 		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; GE Specific Translate Section for 850
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC GE_850_XLAT		       ;;
GE_850_XLAT:			       ;;
				       ;;
   DW	  CP850_XLAT_END-$	       ;; length of section
   DW	  850			       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_NA_LO_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; error character = standalone accent
				       ;;
   DW	 CP850_NA_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 0			       ;; number of scans
CP850_NA_LO_T1_END:		       ;;
				       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_NA_LO_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_NA_UP_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; error character = standalone accent
				       ;;
   DW	 CP850_NA_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 		;; xlat options: **** CNS 12/18
   DB	 1			       ;; number of scans
   DB	 4,0F5H 		       ;;   - Section symbol
				       ;;
CP850_NA_UP_T1_END:		       ;;
				       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_NA_UP_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Acute Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_LO_END-$		 ;; length of state section
   DB	 ACUTE_LOWER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 0eFh,0 			 ;; error character = standalone accent
				       ;;
   DW	 CP850_AC_LO_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 18,'Ç'                        ;; scan code,ASCII - e
   DB	 30,'†'                        ;; scan code,ASCII - a
   DB	 24,'¢'                        ;; scan code,ASCII - o
   DB	 22,'£'                        ;; scan code,ASCII - u
   DB	 23,'°'                        ;; scan code,ASCII - i
 CP850_AC_LO_T1_END:			  ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_LO_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Acute Upper Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_UP_END-$		 ;; length of state section
   DB	 ACUTE_UPPER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 0efh,0 		       ;; error character = standalone accent
				       ;;
   DW	 CP850_AC_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,0B5H			;; Caps acute A
   DB	 23,0D6H			;; Caps acute I
   DB	 24,0E0H			;; Caps acute O
   DB	 22,0E9H			;; Caps acute U
   DB	 18,'ê'                        ;; scan code,ASCII - e
CP850_AC_UP_T1_END:			 ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_UP_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Acute Space Bar
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_SP_END-$		 ;; length of state section
   DB	 ACUTE_SPACE		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 0efh,0 			 ;; error character = standalone accent
				       ;;
   DW	 CP850_AC_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,0efh			 ;; scan code,ASCII - SPACE
CP850_AC_SP_T1_END:			 ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_SP_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Grave Upper Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_GR_UP_END-$	       ;; length of state section
   DB	 GRAVE_UPPER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; error character = standalone accent
				       ;;
   DW	 CP850_GR_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,0B7H			;; Caps grave A
   DB	 18,0D4H			;; Caps grave E
   DB	 23,0DEH			;; Caps grave I
   DB	 24,0E3H			;; Caps grave O
   DB	 22,0EBH			;; Caps grave U
				       ;;
CP850_GR_UP_T1_END:		       ;;
				       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_GR_UP_END:		       ;;
				       ;;
   DW	  0			       ;; LAST STATE
				       ;;
CP850_XLAT_END: 		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
CODE	 ENDS			       ;;
	 END			       ;;
