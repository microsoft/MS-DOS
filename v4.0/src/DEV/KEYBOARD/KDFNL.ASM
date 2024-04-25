;; LATEST CHANGE ALT & CTL
	PAGE	,132
	TITLE	DOS - Keyboard Definition File

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - - NLS Support - Keyboard Defintion File
;; (c) Copyright 1988 Microsoft
;;
;; This file contains the keyboard tables for Netherlands
;;
;; Linkage Instructions:
;;	Refer to KDF.ASM.
;;
;; Modded from Belgian - DTF 20-Aug-86; 08-Sep-86
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
	INCLUDE KEYBSHAR.INC	       ;;
	INCLUDE POSTEQU.INC	       ;;
	INCLUDE KEYBMAC.INC	       ;;
				       ;;
	PUBLIC NL_LOGIC 	       ;;
	PUBLIC NL_437_XLAT	       ;;
	PUBLIC NL_850_XLAT	       ;;
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
;; NL State Logic
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
NL_LOGIC:

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
 IFF EITHER_CTL,NOT		       ;;
    IFF EITHER_ALT,NOT		       ;;
      IFF EITHER_SHIFT		       ;;
	  SET_FLAG DEAD_UPPER	       ;;
      ELSEF			       ;;
	  SET_FLAG DEAD_LOWER	       ;;
      ENDIFF			       ;;
    ELSEF			       ;;
      IFKBD G_KB+P12_KB 	       ;; For ENHANCED keyboard some
      ANDF R_ALT_SHIFT		       ;;  dead keys are on third shift
      ANDF EITHER_SHIFT,NOT	       ;;   which is accessed via the altgr key
	 SET_FLAG DEAD_THIRD	       ;;
      ENDIFF			       ;;
    ENDIFF			       ;;
 ENDIFF 			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ACUTE ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
ACUTE_PROC:			       ;;
				       ;;
   IFF ACUTE,NOT		       ;;
      GOTO CEDILLA_PROC 	       ;;
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
      PUT_ERROR_CHAR ACUTE_SPACE       ;; If we get here then either the XLATT
      BEEP			       ;; failed or we are ina bad shift state.
      GOTO NON_DEAD		       ;; Either is invalid so BEEP and fall
				       ;; through to generate the second char.
				       ;; Note that the dead key flag will be
				       ;; reset before we get here.
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CEDILLA ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
CEDILLA_PROC:			       ;;
				       ;;
   IFF CEDILLA,NOT		       ;;
      GOTO TILDE_PROC		       ;;
      ENDIFF			       ;;
				       ;;
      RESET_NLS 		       ;;
      IFF R_ALT_SHIFT,NOT	       ;;
	 XLATT CEDILLA_SPACE	       ;;
      ENDIFF			       ;;
      IFF EITHER_CTL,NOT	       ;;
      ANDF EITHER_ALT,NOT	       ;;
	 IFF EITHER_SHIFT	       ;;
	    IFF CAPS_STATE	       ;;
	       XLATT CEDILLA_LOWER     ;;
	    ELSEF		       ;;
	       XLATT CEDILLA_UPPER     ;;
	    ENDIFF		       ;;
	 ELSEF			       ;;
	    IFF CAPS_STATE	       ;;
	       XLATT CEDILLA_UPPER     ;;
	    ELSEF		       ;;
	       XLATT CEDILLA_LOWER     ;;
	    ENDIFF		       ;;
	 ENDIFF 		       ;;
      ENDIFF			       ;;
				       ;;
INVALID_CEDILLA:		       ;;
      PUT_ERROR_CHAR CEDILLA_SPACE     ;; If we get here then either the XLATT
      BEEP			       ;; failed or we are ina bad shift state.
      GOTO NON_DEAD		       ;; Either is invalid so BEEP and fall
				       ;; through to generate the second char.
				       ;; Note that the dead key flag will be
				       ;; reset before we get here.
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; TILDE ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
TILDE_PROC:			       ;;
				       ;;
   IFF TILDE,NOT		       ;;
      GOTO DIARESIS_PROC	       ;;
      ENDIFF			       ;;
				       ;;
      RESET_NLS 		       ;;
      IFF R_ALT_SHIFT,NOT	       ;;
	 XLATT TILDE_SPACE	       ;;
      ENDIFF			       ;;
      IFF EITHER_CTL,NOT	       ;;
      ANDF EITHER_ALT,NOT	       ;;
	IFF EITHER_SHIFT	       ;;
	   IFF CAPS_STATE	       ;;
	      XLATT TILDE_LOWER        ;;
	   ELSEF		       ;;
	      XLATT TILDE_UPPER        ;;
	   ENDIFF		       ;;
	ELSEF			       ;;
	   IFF CAPS_STATE,NOT	       ;;
	      XLATT TILDE_LOWER        ;;
	   ELSEF		       ;;
	      XLATT TILDE_UPPER        ;;
	   ENDIFF		       ;;
	ENDIFF			       ;;
      ENDIFF			       ;;
				       ;;
INVALID_TILDE:			       ;;
      PUT_ERROR_CHAR TILDE_SPACE       ;; standalone accent
      BEEP			       ;; Invalid dead key combo.
      GOTO NON_DEAD		       ;;
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
      PUT_ERROR_CHAR GRAVE_SPACE       ;; standalone accent
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
      PUT_ERROR_CHAR CIRCUMFLEX_SPACE  ;; standalone accent
      BEEP			       ;; Invalid dead key combo.
      GOTO NON_DEAD		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Upper, lower and third shifts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NON_DEAD:			       ;;
				       ;;
   IFKBD G_KB+P12_KB		       ;; Avoid accidentally translating
   ANDF LC_E0			       ;;  the "/" on the numeric pad of the
      EXIT_STATE_LOGIC		       ;;   G keyboard
   ENDIFF			       ;;
				       ;;
;;***BD ADDED FOR ALT, CTRL CASES      ;;
;;***MJS Added because of diferences   ;;
;;between KYB Types		       ;;
				       ;;
 IFKBD AT_KB+XT_KB		 ;;
      IFF EITHER_CTL,NOT	       ;;
	 IFF ALT_SHIFT		       ;; ALT - case
	    XLATT ALT_CASE	       ;;
	 ENDIFF 		       ;;
      ELSEF			       ;;
	 IFF EITHER_ALT,NOT	       ;; CTRL - case
	    XLATT CTRL_CASE	       ;;
	 ENDIFF 		       ;;
      ENDIFF			       ;;
 ENDIFF 			       ;;
				       ;;
;;***MJS repeated for G, P12	       ;;
 IFKBD G_KB+P12_KB		       ;;
      IFF EITHER_CTL,NOT	       ;;
	ANDF ALT_SHIFT		       ;;
	ANDF R_ALT_SHIFT,NOT	       ;;
	    XLATT ALT_CASE	       ;;
      ENDIFF			       ;;
      IFF EITHER_CTL		       ;;
	ANDF ALT_SHIFT		       ;; ALT - case
	ANDF R_ALT_SHIFT,NOT	       ;;
	    XLATT ALT_CASE	       ;;
      ENDIFF			       ;;
      IFF EITHER_CTL		       ;;
	ANDF EITHER_ALT,NOT	       ;; CTRL - case
	    XLATT CTRL_CASE	       ;;
      ENDIFF			       ;;
 ENDIFF 			       ;;
;;***BD END OF ADDITION
 IFF  EITHER_CTL,NOT		       ;; Lower and upper case.  Alphabetic
    IFF EITHER_ALT,NOT		       ;; keys are affected by CAPS LOCK.
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
      ENDIFF			       ;; Third and Fourth shifts
    ELSEF			       ;; ctl off, alt on at this point
      IFKBD XT_KB+AT_KB 	 ;; XT, AT,  keyboards. Nordics
	 IFF EITHER_SHIFT	       ;; only.
	    XLATT FOURTH_SHIFT	       ;; ALT + shift
	 ELSEF			       ;;
	    XLATT THIRD_SHIFT	       ;; ALT
	 ENDIFF 		       ;;
      ELSEF			       ;; ENHANCED keyboard
	 IFF R_ALT_SHIFT	       ;; ALTGr
	 ANDF EITHER_SHIFT,NOT	       ;;
	    XLATT THIRD_SHIFT	       ;;
	 ENDIFF 		       ;;
      ENDIFF			       ;;
    ENDIFF			       ;;
 ENDIFF 			       ;;
				       ;;
 EXIT_STATE_LOGIC		       ;;
				       ;;
LOGIC_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; NL Common Translate Section
;; This section contains translations for the lower 128 characters
;; only since these will never change from code page to code page.
;; In addition the dead key "Set Flag" tables are here since the
;; dead keys are on the same keytops for all code pages.
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC NL_COMMON_XLAT		       ;;
NL_COMMON_XLAT: 		       ;;
				       ;;
   DW	 COMMON_XLAT_END-$	       ;; length of section
   DW	 -1			       ;; code page
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Lower Shift Dead Key
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_LO_END-$	       ;; length of state section
   DB	 DEAD_LOWER		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 2			       ;; number of entries
   DB	 26			       ;; scan code
   FLAG  DIARESIS		       ;; flag bit to set
   DB	 40			       ;;
   FLAG  ACUTE			       ;;
				       ;;
				       ;;
COM_DK_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Upper Shift Dead Key
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_UP_END-$	       ;; length of state section
   DB	 DEAD_UPPER		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 3			       ;; number of entries
   DB	 26			       ;; scan code
   FLAG  CIRCUMFLEX		       ;; flag bit to set
   DB	 40			       ;;
   FLAG  GRAVE			       ;;
   DB	 13			       ;;
   FLAG  TILDE			       ;;
				       ;;
COM_DK_UP_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift Dead Key
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_TH_END-$	       ;; length of state section
   DB	 DEAD_THIRD		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 1			       ;; number of entries
   DB	13			       ;;
   FLAG CEDILLA 		       ;;
				       ;;
COM_DK_TH_END:			       ;;
				       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Lower Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
;  DW	 COM_AL_LO_END-$	       ;; length of state section
;  DB	 ALPHA_LOWER		       ;; State ID
;  DW	 G_KB + P12_KB		       ;; Keyboard Type
;  DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
;  DW	 COM_AL_LO_T1_END-$	       ;; Size of xlat table
;  DB	 STANDARD_TABLE 	       ;; xlat options:
;  DB	 0			       ;; number of entries
;COM_AL_LO_T1_END:		       ;;
				       ;;
;  DW	 0			       ;; Size of xlat table - null table
				       ;;
;COM_AL_LO_END: 		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				       ;;
;  DW	 COM_AL_UP_END-$	       ;; length of state section
;  DB	 ALPHA_UPPER		       ;; State ID
;  DW	 G_KB + P12_KB		       ;; Keyboard Type
;  DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
;  DW	 COM_AL_UP_T1_END-$	       ;; Size of xlat table
;  DB	 STANDARD_TABLE 	       ;; xlat options:
;  DB	 0			       ;; number of entries
;COM_AL_UP_T1_END:		       ;;
;				       ;;
;  DW	 0			       ;; Size of xlat table - null table
				       ;;
;COM_AL_UP_END: 		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 10			       ;; number of entries
   DB	 41,"@"                        ;; at sign
   DB	 12,"/"                        ;;
   DB	 13,0F8H		       ;;
   DB	 27,"*"                        ;;
   DB	 39,'+'                        ;;
   DB	 43,'<'                        ;;
   DB	 51,','                        ;;
   DB	 52,'.'                        ;;
   DB	 53,'-'                        ;;
   DB	 86,']'
COM_NA_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 17			       ;; number of entries
   DB	  2,'!'                        ;;
   DB	  3,'"'                        ;;
   DB	  4,'#'                        ;;
   DB	  5,'$'                        ;;
   DB	  6,'%'                        ;;
   DB	  7,'&'                        ;;
   DB	  8,'_'                        ;;
   DB	  9,'('                        ;;
   DB	 10,')'                        ;;
   DB	 11,"'"                        ;;
   DB	 12,'?'                        ;;
   DB	 39,0F1H		       ;;
   DB	 43,'>'                        ;;
   DB	 51,';'                        ;;
   DB	 52,':'                        ;;
   DB	 53,'='                        ;;
   DB	 86,'['
COM_NA_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_END:			       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_THIRD_END-$	       ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_THIRD_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 16			       ;; number of entries
   DB	 41,0AAH		       ;;
   DB	  2,0FBH		       ;;
   DB	  3,0FDH		       ;;
   DB	  4,0FCH		       ;;
   DB	  5,0ACH		       ;;
   DB	  6,0ABH		       ;;
   DB	  7,0F3H		       ;;
   DB	  8,9CH 		       ;;
   DB	  9,'{'                        ;;
   DB	 10,'}'                        ;;
   DB	 12,5CH 		       ;;
   DB	 31,0E1H		       ;;
   DB	 44,0AEH		       ;;
   DB	 45,0AFH		       ;;
;  DB	 46,9BH 		       ;; special case
   DB	 50,0E6H		       ;; mu character
   DB	 52,0FAH		       ;;
COM_THIRD_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Last xlat table
COM_THIRD_END:			       ;;
				       ;;
;;******************************
;;***BD - ADDED FOR NUMERIC PAD (DECIMAL SEPERATOR)
;;******************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Numeric Key Pad
;; KEYBOARD TYPES : G_KB (P12 change does not apply)
;; TABLE TYPE: Translate
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
   DB	 83,','                        ;; decimal seperator = ,
COM_PAD_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_PAD_K1_END: 		       ;;
				       ;;
;;******************************
;;***BD - ADDED FOR ALT CASE
;;******************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alt Case
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_ALT_K1_END-$	       ;; length of state section
   DB	 ALT_CASE		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_ALT_K1_T1_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;; xlat options:
   DB	 0			       ;; 2 number of entries
;   DB	  12,-1,-1		;;
;   DB	  53,0,82H			;;
COM_ALT_K1_T1_END:		       ;;
					;;
    DW	  0				;; Size of xlat table - null table
				       ;;
COM_ALT_K1_END: 		       ;;
					;;
;;******************************
;;***BD - ADDED FOR CTRL CASE
;;******************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Ctrl Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CTRL_K1_END-$	       ;; length of state section
   DB	 CTRL_CASE		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_CTRL_K1_T1_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;; xlat options:
   DB	 5			       ;; number of entries
   DB	 12,-1,-1		       ;;
   DB	 26,-1,-1		       ;;
   DB	 27,-1,-1		       ;;
   DB	 43,-1,-1		       ;;
   DB	 53,01FH,35h		       ;;
COM_CTRL_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CTRL_K1_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Grave Lower
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 COM_GR_LO_END-$		 ;; length of state section
   DB	 GRAVE_LOWER			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 60H,0				 ;; error character = standalone accent
					 ;;
   DW	 COM_GR_LO_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 5				 ;; number of scans
   DB	 18,'ä'                          ;; scan code,ASCII - e
   DB	 30,'Ö'                          ;; scan code,ASCII - a
   DB	 24,'ï'                          ;; scan code,ASCII - o
   DB	 22,'ó'                          ;; scan code,ASCII - u
   DB	 23,'ç'                          ;; scan code,ASCII - i
COM_GR_LO_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
COM_GR_LO_END:				 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Grave Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_GR_UP_END-$	       ;; length of state section
   DB	 GRAVE_UPPER		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 60H,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_GR_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 0			       ;; number of scans
COM_GR_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_GR_UP_END:			       ;; length of state section
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Grave Space Bar
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 COM_GR_SP_END-$		 ;; length of state section
   DB	 GRAVE_SPACE			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 60H,0				 ;; error character = standalone accent
					 ;;
   DW	 COM_GR_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 57,60H 			 ;; STANDALONE GRAVE
COM_GR_SP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
COM_GR_SP_END:				 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Circumflex Lower
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CI_LO_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_LOWER	       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 5EH,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_CI_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,'É'                        ;; scan code,ASCII - a
   DB	 18,'à'                        ;; scan code,ASCII - e
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
;; STATE: Circumflex Upper
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CI_UP_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_UPPER	       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 5EH,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_CI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 0			       ;; number of scans
COM_CI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;;
				       ;;
COM_CI_UP_END:			       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Circumflex Space Bar
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CI_SP_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_SPACE	       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 5EH,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_CI_SP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,5EH 		       ;; STANDALONE CIRCUMFLEX
COM_CI_SP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CI_SP_END:			       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Tilde Space Bar
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 COM_TI_SP_END-$		 ;; length of state section
   DB	 TILDE_SPACE			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 7EH,0				 ;; error character = standalone accent
					 ;;
   DW	 COM_TI_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 57,7EH 			 ;; STANDALONE TIDLE
COM_TI_SP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
COM_TI_SP_END:				 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Cedilla lower
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 COM_CE_LO_END-$		 ;; length of state section
   DB	 CEDILLA_LOWER			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 0F7H,0 			 ;; error character = standalone accent
					 ;; CHNAGED MJS 31/10/86
   DW	 COM_CE_LO_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 46,135 			 ;; scan code,ASCII - c
COM_CE_LO_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
COM_CE_LO_END:			 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: CedilIa Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CE_UP_END-$	       ;; length of state section
   DB	 CEDILLA_UPPER		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 0F7H,0 		       ;; error character = standalone accent
				       ;; CHANGED MJS 31/10/86
   DW	 COM_CE_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 46,128 		       ;; scan code,ASCII - C
COM_CE_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CE_UP_END:		       ;; length of state section
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Cedilla Space Bar
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 COM_CE_SP_END-$		 ;; length of state section
   DB	 CEDILLA_SPACE			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 0F7H,0 			 ;; error character = standalone accent
					 ;; CHANGED MJS 31/10/86
   DW	 COM_CE_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 57,0F7H			 ;; STANDALONE CEDILLA
COM_CE_SP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
COM_CE_SP_END:			 ;; length of state section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Diaresis Lower Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DI_LO_END-$	       ;; length of state section
   DB	 DIARESIS_LOWER 	       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 0F9H,0 		       ;; error character = standalone accent
				       ;; CHANGED MJS 31/10/86
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
COM_DI_LO_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Diaresis Space Bar
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DI_SP_END-$	       ;; length of state section
   DB	 DIARESIS_SPACE 	       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 0F9H,0 		       ;; error character = standalone accent
				       ;; CHANGED MJS 31/10/86
   DW	 COM_DI_SP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,0F9H		       ;; error character = standalone accent
COM_DI_SP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
COM_DI_SP_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 0			       ;; Last State
COMMON_XLAT_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; NL Specific Translate Section for 437
;;
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC NL_437_XLAT		       ;;
NL_437_XLAT:			       ;;
				       ;;
   DW	  CP437_XLAT_END-$	       ;; length of section
   DW	  437			       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 437
;; STATE: Third Shift
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_THIRD_END-$	       ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; default ignore error state
				       ;;
   DW	 CP437_THIRD_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 3			       ;; number of scans
;; DB	 2,7			       ;; NO CHAR - JUST BELL  should be super 1
;;				       ;; NOW COMM. MJS 31/10/86
;; DB	 7,0FCH 		       ;; NOW COMM. MJS 31/10/86
   DB	19,14H			       ;; NO CHAR - JUST BELL
;;				       ;; SHOULD O/P MJS 31/10/86
   DB	 46,9BH 		       ;; cent sign - õ
   DB	 86,7CH 		       ;; vertical bar
				       ;;
CP437_THIRD_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_THIRD_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 437
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
;  DW	 CP437_NA_LO_END-$	       ;; length of state section
;  DB	 NON_ALPHA_LOWER	       ;; State ID
;  DW	 G_KB + P12_KB		       ;; Keyboard Type
;  DB	 -1,-1			       ;; default ignore error state
				       ;;
;  DW	 CP437_NA_LO_T1_END-$	       ;; Size of xlat table
;  DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
;  DB	 0			       ;; number of scans
;CP437_NA_LO_T1_END:		       ;;
				       ;;
;  DW	 0			       ;; Size of xlat table - null table
				       ;;
;CP437_NA_LO_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 437
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_NA_UP_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; default ignore error state
				       ;;
   DW	 CP437_NA_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 2			       ;; number of scans
   DB	27,0B3H 		       ;; vert. line graphics
   DB	41,15H			       ;; Section symbol
CP437_NA_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_NA_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP437
;; STATE: Tilde Lower
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP437_TI_LO_END-$		 ;; length of state section
   DB	 TILDE_LOWER			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 7EH,0				 ;; error character = standalone accent
					 ;;
   DW	 CP437_TI_LO_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 49,164 			 ;; scan code,ASCII - n
CP437_TI_LO_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP437_TI_LO_END:			 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP437
;; STATE: Tilde Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_TI_UP_END-$	       ;; length of state section
   DB	 TILDE_UPPER		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 7EH,0			       ;; error character = standalone accent
				       ;;
   DW	 CP437_TI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 49,165 		       ;; scan code,ASCII - N
CP437_TI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_TI_UP_END:		       ;; length of state section
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP437
;; STATE: Acute Lower Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_AC_LO_END-$	       ;; length of state section
   DB	 ACUTE_LOWER		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 027H,0 		       ;; error character = standalone accent
				       ;; CHANGED MJS 31/10/86
   DW	 CP437_AC_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,'†'                        ;; a acute
   DB	 18,'Ç'                        ;; e acute
   DB	 23,'°'                        ;; i acute
   DB	 24,'¢'                        ;; o acute
   DB	 22,'£'                        ;; u acute
CP437_AC_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_AC_LO_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP437
;; STATE: Acute Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP437_AC_UP_END-$		 ;; length of state section
   DB	 ACUTE_UPPER			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 027H,0 			 ;; error character = standalone accent
					 ;; CHANGED MJS 31/10/86
   DW	 CP437_AC_UP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 18,'ê'                          ;; scan code,ASCII - e
CP437_AC_UP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP437_AC_UP_END:			 ;;
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP437
;; STATE: Acute Space Bar
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP437_AC_SP_END-$		 ;; length of state section
   DB	 ACUTE_SPACE			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 027H,0 			 ;; error character = standalone accent
					 ;; CHANGED MJS 34/10/86
   DW	 CP437_AC_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 57,027H			 ;; scan code,ASCII - SPACE
CP437_AC_SP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP437_AC_SP_END:			 ;;
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP437
;; STATE: Diaresis Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_DI_UP_END-$	       ;; length of state section
   DB	 DIARESIS_UPPER 	       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 0F9H,0 		       ;; error character = standalone accent
				       ;;
   DW	 CP437_DI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 30,'é'                        ;; scan code,ASCII - a
   DB	 24,'ô'                        ;; scan code,ASCII - o
   DB	 22,'ö'                        ;; scan code,ASCII - u
CP437_DI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_DI_UP_END:		       ;; length of state section
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	  0			       ;; LAST STATE
				       ;;
CP437_XLAT_END: 		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; NL Specific Translate Section for 850
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC NL_850_XLAT		       ;;
NL_850_XLAT:			       ;;
				       ;;
   DW	  CP850_XLAT_END-$	       ;; length of section
   DW	  850			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_NA_UP_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; default ignore error state
				       ;;
   DW	 CP850_NA_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 2			       ;; number of scans
   DB	27,07CH 		       ;; vert line
   DB	41,0F5H 		       ;; section symbol
CP850_NA_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_NA_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Third Shift
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_THIRD_END-$	       ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; default ignore error state
				       ;;
   DW	 CP850_THIRD_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 3			       ;; number of scans
;; DB	 2,0FBH 		       ;; NOW COMM. MJS 31/10/86
;; DB	 7,0F3H 		       ;; NOW COMM. MJS 31/10/86
   DB	19,0F4H 		       ;;
   DB	46,0BDH 		       ;; cent sign - õ
   DB	86,0DDH 		       ;; true broken vertical
CP850_THIRD_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_THIRD_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850
;; STATE: Tilde Lower
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_TI_LO_END-$		 ;; length of state section
   DB	 TILDE_LOWER			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 7EH,0				 ;; error character = standalone accent
					 ;;
   DW	 CP850_TI_LO_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 3				 ;; number of scans
   DB	 30,0C6H			 ;; scan code,ASCII - a
   DB	 24,0E4H			 ;; scan code,ASCII - o
   DB	 49,164 			 ;; scan code,ASCII - n
CP850_TI_LO_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP850_TI_LO_END:			 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850
;; STATE: Tilde Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_TI_UP_END-$	       ;; length of state section
   DB	 TILDE_UPPER		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 7EH,0			       ;; error character = standalone accent
				       ;;
   DW	 CP850_TI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 30,0C7H		       ;; scan code,ASCII - A
   DB	 24,0E5H		       ;; scan code,ASCII - O
   DB	 49,165 		       ;; scan code,ASCII - N
CP850_TI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_TI_UP_END:		       ;; length of state section
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850 - NOW IN COMMON MJS 31/10/86
;; STATE: Cedilla lower
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850 - NOW IN COMMON MJS 31/10/86
;; STATE: CedilIa Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850 - NOW IN COMMON MJS 31/10/86
;; STATE: Cedilla Space Bar
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850
;; STATE: Acute Lower Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_LO_END-$	       ;; length of state section
   DB	 ACUTE_LOWER		       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 0EFH,0 		       ;; error character = standalone accent
   DW	 CP850_AC_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 6			       ;; number of scans
   DB	 30,'†'                        ;; a acute
   DB	 18,'Ç'                        ;; e acute
   DB	 23,'°'                        ;; i acute
   DB	 24,'¢'                        ;; o acute
   DB	 22,'£'                        ;; u acute
   DB	 21,0ECH	       ;; y acute
CP850_AC_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_LO_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850
;; STATE: Acute Upper Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_AC_UP_END-$		 ;; length of state section
   DB	 ACUTE_UPPER			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 0EFH,0 			 ;; error character = standalone accent
   DW	 CP850_AC_UP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 6				 ;; number of scans
   DB	 18,090H			 ;;    E acute
   DB	 30,0B5H			 ;;    A acute
   DB	 23,0D6H			 ;;    I acute
   DB	 24,0E0H			 ;;    O acute
   DB	 22,0E9H			 ;;    U acute
   DB	 21,0EDH			 ;;    Y acute
CP850_AC_UP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP850_AC_UP_END:			 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850
;; STATE: Acute Space Bar
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_AC_SP_END-$		 ;; length of state section
   DB	 ACUTE_SPACE			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 0EFH,0 			 ;; error character = standalone accent
					 ;;
   DW	 CP850_AC_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 57,0EFH			 ;; scan code,ASCII - SPACE
CP850_AC_SP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP850_AC_SP_END:			 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850 - NOW IN COMMON MJS 31/10/86
;; STATE: Diaresis Lower Case
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;					 ;;
;; CODE PAGE: 850
;; STATE: Diaresis Upper
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_DI_UP_END-$	       ;; length of state section
   DB	 DIARESIS_UPPER 	       ;; State ID
   DW	 G_KB + P12_KB		       ;; Keyboard Type
   DB	 0F9H,0 		       ;; error character = standalone accent
				       ;;
   DW	 CP850_DI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 30,'é'                        ;; scan code,ASCII - A
   DB	 18,0D3H		       ;; scan code,ASCII - E
   DB	 23,0D8H		       ;; scan code,ASCII - I
   DB	 24,'ô'                        ;; scan code,ASCII - O
   DB	 22,'ö'                        ;; scan code,ASCII - U
CP850_DI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_DI_UP_END:		       ;; length of state section
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850 - NOW IN COMMON MJS 31/10/86
;; STATE: Diaeresis Space Bar
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Grave Upper
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_GR_UP_END-$		 ;; length of state section
   DB	 GRAVE_UPPER			 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 60H,0				 ;; error character = standalone accent
					 ;;
   DW	 CP850_GR_UP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 5				 ;; number of scans
   DB	 30,0B7H			 ;;    A grave
   DB	 18,0D4H			 ;;    E grave
   DB	 23,0DEH			 ;;    I grave
   DB	 24,0E3H			 ;;    O grave
   DB	 22,0EBH			 ;;    U grave
CP850_GR_UP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP850_GR_UP_END:			 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Circumflex Upper
;; KEYBOARD TYPES : G_KB + P12_KB
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_CI_UP_END-$		 ;; length of state section
   DB	 CIRCUMFLEX_UPPER		 ;; State ID
   DW	 G_KB + P12_KB			 ;; Keyboard Type
   DB	 5EH,0				 ;; error character = standalone accent
					 ;;
   DW	 CP850_CI_UP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 5				 ;; number of scans
   DB	 30,0B6H			 ;;    A circumflex
   DB	 18,0D2H			 ;;    E circumflex
   DB	 23,0D7H			 ;;    I circumflex
   DB	 24,0E2H			 ;;    O circumflex
   DB	 22,0EAH			 ;;    U circumflex
CP850_CI_UP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP850_CI_UP_END:			 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
     DW    0				 ;; LAST STATE
					 ;;
CP850_XLAT_END: 			 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
CODE	 ENDS				 ;;
	 END				 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
