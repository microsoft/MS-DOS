;; LATEST CHANGE ALT & CTL	(November)
;LATEST CHANGE XT "\" third shift (December)
;;;;********************************************
;;;;********************************************
;;;;CONTAINS UPDATES FOR
;;;; 1) ALT, CTRL CASES
;;;; 2) DECIMAL SEPERATOR ON NUMERIC PAD
;;;; 3) STANDALONE DIARESIS VALID ONLY FOR 850
;;;;CHANGES ARE MARKED ***BD
;;;;********************************************
;;;;********************************************

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
	PUBLIC SP_LOGIC 	       ;;
	PUBLIC SP_437_XLAT	       ;;
	PUBLIC SP_850_XLAT	       ;;
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
;; SP State Logic
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
SP_LOGIC:

   DW  LOGIC_END-$		       ;; length
				       ;;
   DW  0			       ;; special features
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
      IFF EITHER_SHIFT		       ;;
	  SET_FLAG DEAD_UPPER	       ;;
      ELSEF			       ;;
	  SET_FLAG DEAD_LOWER	       ;;
      ENDIFF			       ;;
   ENDIFF			       ;;
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
      PUT_ERROR_CHAR DIARESIS_LOWER    ;; standalone accent
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
	  XLATT NON_ALPHA_UPPER        ;;
	  IFF CAPS_STATE	       ;;
	      XLATT ALPHA_LOWER        ;;
	  ELSEF 		       ;;
	      XLATT ALPHA_UPPER        ;;
	  ENDIFF		       ;;
      ELSEF			       ;;
;;***BD ADDED FOR NUMERIC PAD
	  IFF NUM_STATE 	       ;;
	      XLATT NUMERIC_PAD        ;;
	  ENDIFF		       ;;
;;***BD END OF ADDITION
	  XLATT NON_ALPHA_LOWER        ;;
	  IFF CAPS_STATE	       ;;
	     XLATT ALPHA_UPPER	       ;;
	  ELSEF 		       ;;
	     XLATT ALPHA_LOWER	       ;;
	  ENDIFF		       ;;
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
;; SP Common Translate Section
;; This section contains translations for the lower 128 characters
;; only since these will never change from code page to code page.
;; In addition the dead key "Set Flag" tables are here since the
;; dead keys are on the same keytops for all code pages.
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC SP_COMMON_XLAT		       ;;
SP_COMMON_XLAT: 		       ;;
				       ;;
   DW	 COMMON_XLAT_END-$	       ;; length of section
   DW	 -1			       ;; code page
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Lower Shift Dead Key
;; KEYBOARD TYPES: G + P12
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_LO_K1_END-$	       ;; length of state section
   DB	 DEAD_LOWER		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 2			       ;; number of entries
   DB	 26			       ;; scan code
   FLAG  GRAVE			       ;; flag bit to set
   DB	 40			       ;;
   FLAG  ACUTE			       ;;
				       ;;
				       ;;
COM_DK_LO_K1_END:		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Lower Shift Dead Key
;; KEYBOARD TYPES: AT + XT +
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_LO_K2_END-$	       ;; length of state section
   DB	 DEAD_LOWER		       ;; State ID
   DW	 AT_KB+XT_KB		 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 2			       ;; number of entries
   DB	 26			       ;; scan code
   FLAG  ACUTE			       ;; flag bit to set
   DB	 27			       ;;
   FLAG  GRAVE			       ;;
				       ;;
				       ;;
COM_DK_LO_K2_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Upper Shift Dead Key
;; KEYBOARD TYPES: G + P12
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_UP_K1_END-$	       ;; length of state section
   DB	 DEAD_UPPER		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 2			       ;; number of entries
   DB	 26			       ;; scan code
   FLAG  CIRCUMFLEX		       ;; flag bit to set
   DB	 40			       ;;
   FLAG  DIARESIS		       ;;
				       ;;
COM_DK_UP_K1_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Upper Shift Dead Key
;; KEYBOARD TYPES: AT + XT +
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_UP_END-$	       ;; length of state section
   DB	 DEAD_UPPER		       ;; State ID
   DW	 AT_KB+XT_KB		 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 2			       ;; number of entries
   DB	 26			       ;; scan code
   FLAG  DIARESIS		       ;; flag bit to set
   DB	 27			       ;;
   FLAG  CIRCUMFLEX		       ;;
				       ;;
COM_DK_UP_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Lower Case
;; KEYBOARD TYPES: G + AT + P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AL_LO_K1_END-$	       ;; length of state section
   DB	 ALPHA_LOWER		       ;; State ID
   DW	 G_KB+AT_KB+P12_KB	       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_AL_LO_K1_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 2			       ;; number of entries
   DB	 39,164 		       ;; n-tilde
   DB	 43,135 		       ;; c-cedilla
COM_AL_LO_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AL_LO_K1_END:		       ;;

;;******************************
;;***BD - ADDED FOR NUMERIC PAD (DECIMAL SEPERATOR)
;;******************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Numeric Key Pad
;; KEYBOARD TYPES: p12 + G
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_PAD_K1_END-$	       ;; length of state section
   DB	 NUMERIC_PAD		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_PAD_K1_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 0			       ;; number of entries
; THIS IS A TEST ENTRY TO SHOW AN EXAMPLE
;  DB	 83,44			       ;; decimal seperator = ,
COM_PAD_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_PAD_K1_END: 		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Numeric Key Pad
;; KEYBOARD TYPES: AT+ XT
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;				       ;;
;;   DW    COM_PAD_K2_END-$		 ;; length of state section
;;   DB    NUMERIC_PAD			 ;; State ID
;;   DW    AT_KB+XT_KB			 ;; Keyboard Type
;;   DB    -1,-1			 ;; Buffer entry for error character
;;					 ;;
;;   DW    COM_PAD_K2_T2_END-$		 ;; Size of xlat table
;;   DB    STANDARD_TABLE		 ;; xlat options:
;;   DB    1				 ;; number of entries
;;   DB    74,05eh			 ;; circumflex carat under the Prtscr key
;;COM_PAD_K2_T2_END:			 ;;
;;					 ;;
;;   DW    0				 ;; Size of xlat table - null table
;;					 ;;
;;COM_PAD_K2_END:			 ;;
;;					 ;;
;;;;******************************
;;***BD - ADDED FOR ALT CASE
;;******************************
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
   DB	 0			       ;; number of entries
;;***BD THIS ENTRY IS A TEST ENTRY
;; DB	 53,225,0		       ;; TEST ENTRY
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
;; KEYBOARD TYPES: G_KB+P12_KB+AT
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CTRL_K1_END-$	       ;; length of state section
   DB	 CTRL_CASE		       ;; State ID
   DW	 G_KB+P12_KB+AT_KB	       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_CTRL_K1_T1_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;; xlat options:
   DB	 2			       ;; number of entries
;;***BD THIS ENTRY IS A TEST ENTRY
;; DB	 53,226,0		       ;; TEST ENTRY
   DB	 43,-1,-1		       ;; invalid slash
   DB	 41,28,41		       ;; valid slash
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
;; KEYBOARD TYPES: XT_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CTRL_K2_END-$	       ;; length of state section
   DB	 CTRL_CASE		       ;; State ID
   DW	 XT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_CTRL_K2_T2_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;; xlat options:
   DB	 1			       ;; number of entries
;;***BD THIS ENTRY IS A TEST ENTRY
;; DB	 53,226,0		       ;; TEST ENTRY
   DB	 43,-1,-1		       ;; invalid slash
COM_CTRL_K2_T2_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CTRL_K2_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Lower Case
;; KEYBOARD TYPES: XT +
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AL_LO_K2_END-$	       ;; length of state section
   DB	 ALPHA_LOWER		       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_AL_LO_K2_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 2			       ;; number of entries
   DB	 39,164 		       ;; n-tilde
   DB	 41,135 		       ;; c-cedilla
COM_AL_LO_K2_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AL_LO_K2_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Upper Case
;; KEYBOARD TYPES: G + AT + P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AL_UP_K1_END-$	       ;; length of state section
   DB	 ALPHA_UPPER		       ;; State ID
   DW	 G_KB+AT_KB+P12_KB	       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_AL_UP_K1_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 2			       ;; number of entries
   DB	 39,165 		       ;; N-tilde
   DB	 43,128 		       ;; C-cedilla
COM_AL_UP_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AL_UP_K1_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Upper Case
;; KEYBOARD TYPES: XT +
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AL_UP_K2_END-$	       ;; length of state section
   DB	 ALPHA_UPPER		       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_AL_UP_K2_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 2			       ;; number of entries
   DB	 39,165 		       ;; N-tilde
   DB	 41,128 		       ;; C-cedilla
COM_AL_UP_K2_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AL_UP_K2_END:		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: G + P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_K1_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_K1_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 6			       ;; number of entries
   DB	 12,"'"                        ;; '
   DB	 27,'+'                        ;; +
   DB	 86,'<'                        ;; <
   DB	 53,'-'                        ;; -
   DB	 41,167 		       ;; o-underline
   DB	 13,173 		       ;; upside-dowm !
COM_NA_LO_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_K1_END:		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: AT
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_K2_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 AT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_K2_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 4			       ;; number of entries
   DB	 40,';'                        ;; ;
   DB	 41,'<'                        ;; <
   DB	 53,"'"                        ;; quote
   DB	 55,05eh		       ;; circumflex carat under the Prtscr key
COM_NA_LO_K2_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_K2_END:		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: XT +
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_K3_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_K3_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 4			       ;; number of entries
   DB	 40,';'                        ;; ;
   DB	 43,'<'                        ;; <
   DB	 53,"'"                        ;; quote
   DB	 55,05eh		       ;; circumflex carat under the Prtscr key
COM_NA_LO_K3_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_K3_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: G + P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_K1_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_UP_K1_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 16			       ;; number of entries
   DB	  3,'"'                        ;;
   DB	  4,250 		       ;; diacritic
   DB	  7,'&'                        ;;
   DB	  8,'/'                        ;;
   DB	  9,'('                        ;;
   DB	 10,')'                        ;;
   DB	 11,'='                        ;;
   DB	 12,'?'                        ;;
   DB	 13,168 		       ;; upside-dowm ?
   DB	 27,'*'                        ;;
   DB	 41,166 		       ;; a-underline
   DB	 86,'>'                        ;;
   DB	 51,';'                        ;;
   DB	 52,':'                        ;;
   DB	 53,'_'                        ;;
COM_NA_UP_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_K1_END:		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: AT
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_K2_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 AT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_UP_K2_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 8			       ;; number of entries
   DB	 41,'>'                        ;;
   DB	  2,0ADH		       ;; UPSIDE DOWN ≠
   DB	  3,168 		       ;; UPSIDE DOWN ?
   DB	  7,'/'                        ;;
   DB	 40,':'                        ;;
   DB	 51,'?'                        ;;
   DB	 52,'!'                        ;;
   DB	 53,'"'                        ;;
COM_NA_UP_K2_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_K2_END:		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: XT +
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_K3_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_UP_K3_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 8			       ;; number of entries
   DB	 43,'>'                        ;;
   DB	  2,0ADH		       ;; UPSIDE DOWN ≠
   DB	  3,168 		       ;; UPSIDE DOWN ?
   DB	  7,'/'                        ;;
   DB	 40,':'                        ;;
   DB	 51,'?'                        ;;
   DB	 52,'!'                        ;;
   DB	 53,'"'                        ;;
COM_NA_UP_K3_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_K3_END:		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift
;; KEYBOARD TYPES: G + P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_THIRD_K1_END-$	       ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_THIRD_K1_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 9			       ;; number of entries
   DB	 41,'\'                        ;;
   DB	  2,'|'                        ;;
   DB	  3,'@'                        ;;
   DB	  4,'#'                        ;;
   DB	  7,170 		       ;;
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 40,'{'                        ;;
   DB	 43,'}'                        ;;
COM_THIRD_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Last xlat table
COM_THIRD_K1_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift
;; KEYBOARD TYPES: AT
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_THIRD_K2_END-$	       ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 AT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_THIRD_K2_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 4			       ;; number of entries
   DB	 41,'\'                        ;;
   DB	  3,'@'                        ;;
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
COM_THIRD_K2_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Last xlat table
COM_THIRD_K2_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift
;; KEYBOARD TYPES: XT
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
   DB	  3,'@'                        ;;
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 43,'\'                        ;;
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
;					;;
;   DW	  COM_AC_LO_END-$		;; length of state section
;   DB	  ACUTE_LOWER			;; State ID
;   DW	  ANY_KB			;; Keyboard Type
;   DB	  39,0				;; error character = standalone accent
;					;;
;   DW	  COM_AC_LO_T1_END-$		;; Size of xlat table
;   DB	  STANDARD_TABLE+ZERO_SCAN	;; xlat options:
;   DB	  5				;; number of scans
;   DB	  18,'Ç'                        ;; scan code,ASCII - e
;   DB	  30,'†'                        ;; scan code,ASCII - a
;   DB	  24,'¢'                        ;; scan code,ASCII - o
;   DB	  22,'£'                        ;; scan code,ASCII - u
;   DB	  23,'°'                        ;; scan code,ASCII - i
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
;   DB	  2				;; number of scans
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
;					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Diaresis Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DI_LO_END-$	       ;; length of state section
   DB	 DIARESIS_LOWER 	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 249,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_DI_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 6			       ;; number of scans
   DB	 18,'â'                        ;; scan code,ASCII - e
   DB	 30,'Ñ'                        ;; scan code,ASCII - a
   DB	 24,'î'                        ;; scan code,ASCII - o
   DB	 22,'Å'                        ;; scan code,ASCII - u
   DB	 23,'ã'                        ;; scan code,ASCII - i
   DB	 21,'ò'                        ;; scan code,ASCII - y
COM_DI_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_DI_LO_END:			       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Diaresis Upper Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DI_UP_END-$	       ;; length of state section
   DB	 DIARESIS_UPPER 	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 249,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_DI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 30,'é'                        ;; scan code,ASCII - a
   DB	 24,'ô'                        ;; scan code,ASCII - o
   DB	 22,'ö'                        ;; scan code,ASCII - u
COM_DI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_DI_UP_END:			       ;; length of state section
				       ;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Circumflex Lower
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CI_LO_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_LOWER	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 94,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_CI_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 18,'à'                        ;; scan code,ASCII - e
   DB	 30,'É'                        ;; scan code,ASCII - a
   DB	 24,'ì'                        ;; scan code,ASCII - o
   DB	 22,'ñ'                        ;; scan code,ASCII - u
   DB	 23,'å'                        ;; scan code,ASCII - i
COM_CI_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;;
				       ;;
COM_CI_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Circumflex Space Bar
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CI_SP_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_SPACE	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 94,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_CI_SP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,94			       ;; STANDALONE CIRCUMFLEX
COM_CI_SP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CI_SP_END:			       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 0			       ;; Last State
COMMON_XLAT_END:		       ;;
				       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; SP Specific Translate Section for 437
;; 437 IS COMPLETELY COVERED BY THE COMMON TABLE.
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC SP_437_XLAT		       ;;
SP_437_XLAT:			       ;;
				       ;;
   DW	  CP437_XLAT_END-$	       ;; length of section
   DW	  437			       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  CODE PAGE: Specific 437
;  STATE: Acute Lower Case
;  KEYBOARD TYPES: All
;  TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 CP437_AC_LO_END-$		  ; length of state section
   DB	 ACUTE_LOWER			; State ID
   DW	 ANY_KB 			; Keyboard Type
   DB	 39,0				; error character = standalone accent
					;
   DW	 CP437_AC_LO_T1_END-$		  ; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	; xlat options:
   DB	 5				; number of scans
   DB	 18,'Ç'                         ; scan code,ASCII - e
   DB	 30,'†'                         ; scan code,ASCII - a
   DB	 24,'¢'                         ; scan code,ASCII - o
   DB	 22,'£'                         ; scan code,ASCII - u
   DB	 23,'°'                         ; scan code,ASCII - i
CP437_AC_LO_T1_END:			  ;
					;
   DW	 0				; Size of xlat table - null table
					;
CP437_AC_LO_END:			  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  CODE PAGE: 437
;  STATE: Acute Upper Case
;  KEYBOARD TYPES: All
;  TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 CP437_AC_UP_END-$		  ; length of state section
   DB	 ACUTE_UPPER			; State ID
   DW	 ANY_KB 			; Keyboard Type
   DB	 39,0				; error character = standalone accent
					;
   DW	 CP437_AC_UP_T1_END-$		  ; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	; xlat options:
   DB	 1				; number of scans
   DB	 18,'ê'                         ; scan code,ASCII - e
CP437_AC_UP_T1_END:			  ;
					;
   DW	 0				; Size of xlat table - null table
					;
CP437_AC_UP_END:			  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  CODE PAGE: 437
;  STATE: Acute Space Bar
;  KEYBOARD TYPES: All
;  TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 CP437_AC_SP_END-$		  ; length of state section
   DB	 ACUTE_SPACE			; State ID
   DW	 ANY_KB 			; Keyboard Type
   DB	 39,0				; error character = standalone accent
					;
   DW	 CP437_AC_SP_T1_END-$		  ; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	; xlat options:
   DB	 1				; number of scans
   DB	 57,39				; scan code,ASCII - SPACE
CP437_AC_SP_T1_END:			  ;
					;
   DW	 0				; Size of xlat table - null table
					;
CP437_AC_SP_END:			  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	  0			       ;; LAST STATE
				       ;;
CP437_XLAT_END: 		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; SP Specific Translate Section for 850
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC SP_850_XLAT		       ;;
SP_850_XLAT:			       ;;
				       ;;
   DW	  CP850_XLAT_END-$	       ;; length of section
   DW	  850			       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Acute Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_LO_END-$	       ;; length of state section
   DB	 ACUTE_LOWER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 0EFH,0 			 ;; error character = standalone accent
				       ;;
   DW	 CP850_AC_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5				; number of scans
   DB	 18,'Ç'                         ; scan code,ASCII - e
   DB	 30,'†'                         ; scan code,ASCII - a
   DB	 24,'¢'                         ; scan code,ASCII - o
   DB	 22,'£'                         ; scan code,ASCII - u
   DB	 23,'°'                         ; scan code,ASCII - i
;  DB	 21,0ECH    Delete until 4.00   ;; y acute
CP850_AC_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_LO_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Acute Upper Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_UP_END-$	       ;; length of state section
   DB	 ACUTE_UPPER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 0EFH,0 			 ;; error character = standalone accent
				       ;;
   DW	 CP850_AC_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 18,'ê'                         ; scan code,ASCII - e
   DB	 30,0B5H		       ;;    A acute
   DB	 23,0D6H		       ;;    I acute
   DB	 24,0E0H		       ;;    O acute
   DB	 22,0E9H		       ;;    U acute
;  DB	 21,0EDH  Delete until 4.00     ;;    Y acute
CP850_AC_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_UP_END:		       ;;
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
   DB	 0EFH,0 			 ;; error character = standalone accent
				       ;;
   DW	 CP850_AC_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,0EFH			 ;; scan code,ASCII - SPACE
CP850_AC_SP_T1_END:			 ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_SP_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Diaresis Upper
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_DI_UP_END-$	       ;; length of state section
   DB	 DIARESIS_UPPER 	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 249,0			       ;; error character = standalone accent
				       ;;
   DW	 CP850_DI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 2			       ;; number of scans
   DB	 18,0D3H		       ;;    E diaeresis
   DB	 23,0D8H		       ;;    I diaeresis
CP850_DI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_DI_UP_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Diaresis Space Bar
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW  CP850_DI_SP_END-$	       ;; length of state section
   DB	 DIARESIS_SPACE 	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 249,0			       ;; error character = standalone accent
				       ;;
   DW  CP850_DI_SP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,249 		       ;; error character = standalone accent
CP850_DI_SP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
CP850_DI_SP_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Grave Upper
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_GR_UP_END-$	       ;; length of state section
   DB	 GRAVE_UPPER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 96,0			       ;; error character = standalone accent
				       ;;
   DW	 CP850_GR_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,0B7H		       ;;    A grave
   DB	 18,0D4H		       ;;    E grave
   DB	 23,0DEH		       ;;    I grave
   DB	 24,0E3H		       ;;    O grave
   DB	 22,0EBH		       ;;    U grave
CP850_GR_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_GR_UP_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Circumflex Upper
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_CI_UP_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_UPPER	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 94,0			       ;; error character = standalone accent
				       ;;
   DW	 CP850_CI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,0B6H		       ;;    A circumflex
   DB	 18,0D2H		       ;;    E circumflex
   DB	 23,0D7H		       ;;    I circumflex
   DB	 24,0E2H		       ;;    O circumflex
   DB	 22,0EAH		       ;;    U circumflex
CP850_CI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_CI_UP_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 0			       ;; LAST STATE
				       ;;
CP850_XLAT_END: 		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
CODE	 ENDS			       ;;
	 END			       ;;
