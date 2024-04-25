;; LATEST CHANGE TO CTL [ and ] on XT moved to key 26 & 27
;; XT section enabled
;; ************* CNS 12/18/86


	PAGE	,132
	TITLE	DOS - Keyboard Definition File

;; LATEST CHANGE P12 NUMERIC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - - NLS Support - Keyboard Defintion File
;; (c) Copyright 1988 Microsoft
;;
;; This file contains the keyboard tables for Portugeuse
;;
;; Linkage Instructions:
;;	Refer to KDF.ASM.
;;
;;	       modded : DTF 18-Sep-86
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
	INCLUDE KEYBSHAR.INC	       ;;
	INCLUDE POSTEQU.INC	       ;;
	INCLUDE KEYBMAC.INC	       ;;
				       ;;
	PUBLIC PO_LOGIC 	       ;;
	PUBLIC PO_860_XLAT	       ;;
	PUBLIC PO_850_XLAT	       ;;
				       ;;
CODE	SEGMENT PUBLIC 'CODE'          ;;
	ASSUME CS:CODE,DS:CODE	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Standard translate table options are a linear search table
;; (TYPE_2_TAB) and ASCII entries ONLY (ASCII_ONLY)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
STANDARD_TABLE	    EQU   TYPE_2_TAB+ASCII_ONLY
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PO State Logic
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
PO_LOGIC:

   DW  LOGIC_END-$		       ;; length
				       ;;
   DW  0			       ;; special features
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; COMMANDS START HERE
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
      IFF EITHER_SHIFT		       ;;
	  SET_FLAG DEAD_UPPER	       ;;
      ELSEF			       ;;
	  SET_FLAG DEAD_LOWER	       ;;
      ENDIFF			       ;;
   ENDIFF			       ;;
IFF EITHER_SHIFT,NOT		       ;;
   IFKBD XT_KB+AT_KB		       ;;
      IFF EITHER_CTL		       ;;
      ANDF ALT_SHIFT		       ;;
	  SET_FLAG DEAD_THIRD	       ;;
      ENDIFF			       ;;
   ELSEF			       ;;
      IFF EITHER_CTL,NOT	       ;;
      ANDF R_ALT_SHIFT		       ;;
	  SET_FLAG DEAD_THIRD	       ;;
      ENDIFF			       ;;
   ENDIFF			       ;;
ENDIFF				       ;;
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
      GOTO TILDE_PROC		       ;;
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
;; TILDE ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TILDE_PROC:			       ;;
				       ;;
   IFF TILDE,NOT		       ;;
      GOTO CIRCUMFLEX_PROC	       ;;
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
	   IFF CAPS_STATE	       ;;
	      XLATT TILDE_UPPER        ;;
	   ELSEF		       ;;
	      XLATT TILDE_LOWER        ;;
	   ENDIFF		       ;;
	ENDIFF			       ;;
      ENDIFF			       ;;
				       ;;
INVALID_TILDE:			       ;;
      PUT_ERROR_CHAR TILDE_LOWER       ;; standalone accent
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
	  IFKBD XT_KB+AT_KB	       ;;
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
;**************************************;;
 IFF EITHER_SHIFT,NOT		       ;;
   IFKBD XT_KB+AT_KB		       ;;
     IFF EITHER_CTL		       ;;
     ANDF ALT_SHIFT		       ;;
       XLATT ALT_CASE		       ;;
     ENDIFF			       ;;
   ENDIFF			       ;;
   IFKBD G_KB+P12_KB		       ;;
     IFF EITHER_CTL		       ;;
     ANDF ALT_SHIFT		       ;;
       IFF R_ALT_SHIFT,NOT	       ;;
	 XLATT ALT_CASE 	       ;;
       ENDIFF			       ;;
     ENDIFF			       ;;
   ENDIFF			       ;;
 ENDIFF 			       ;;
;**************************************;;
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
 IFKBD G_KB+P12_KB		       ;;
      IFF EITHER_CTL,NOT	       ;;
	 IFF ALT_SHIFT		       ;; ALT - case
	 ANDF R_ALT_SHIFT,NOT	       ;;
	    XLATT ALT_CASE	       ;;
	 ENDIFF 		       ;;
      ELSEF			       ;;
	 IFF EITHER_ALT,NOT	       ;; CTRL - case
	    XLATT CTRL_CASE	       ;;
	 ENDIFF 		       ;;
      ENDIFF			       ;;
      IFF EITHER_CTL		       ;;
      ANDF ALT_SHIFT		       ;;
      ANDF R_ALT_SHIFT,NOT	       ;;
	   XLATT ALT_CASE	       ;;
      ENDIFF			       ;;
 ENDIFF 			       ;;
				       ;;
 EXIT_STATE_LOGIC		       ;;
				       ;;
LOGIC_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PO Common Translate Section
;; This section contains translations for the lower 128 characters
;; only since these will never change from code page to code page.
;; In addition the dead key "Set Flag" tables are here since the
;; dead keys are on the same keytops for all code pages.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC PO_COMMON_XLAT		       ;;
PO_COMMON_XLAT: 		       ;;
				       ;;
   DW	 COMMON_XLAT_END-$	       ;; length of section
   DW	 -1			       ;; code page
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Lower Shift Dead Key
;; KEYBOARD TYPES: XT
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_LO_END-$	       ;; length of state section
   DB	 DEAD_LOWER		       ;; State ID
   DW	 XT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 2			       ;; number of entries
   DB	 27			       ;; scan code
   FLAG  ACUTE			       ;; flag bit to set
   DB	 41			       ;;
   FLAG  TILDE			       ;;
				       ;;
				       ;;
COM_DK_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Lower Shift Dead Key
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_LO_K1_END-$		  ;; length of state section
   DB	 DEAD_LOWER		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 2			       ;; number of entries
   DB	 27			       ;; scan code
   FLAG  ACUTE			       ;; flag bit to set
   DB	 43			       ;;
   FLAG  TILDE			       ;;
				       ;;
				       ;;
COM_DK_LO_K1_END:			  ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Upper Shift Dead Key
;; KEYBOARD TYPES: XT
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_UP_END-$	       ;; length of state section
   DB	 DEAD_UPPER		       ;; State ID
   DW	 XT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 2			       ;; number of entries
   DB	 27			       ;; scan code
   FLAG  GRAVE			       ;; flag bit to set
   DB	 41			       ;;
   FLAG  CIRCUMFLEX		       ;;
				       ;;
COM_DK_UP_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Upper Shift Dead Key
;; KEYBOARD TYPES: G, P12,
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_UP_K1_END-$		  ;; length of state section
   DB	 DEAD_UPPER		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 2			       ;; number of entries
   DB	 27			       ;; scan code
   FLAG  GRAVE			       ;; flag bit to set
   DB	 43			       ;;
   FLAG  CIRCUMFLEX		       ;;
				       ;;
COM_DK_UP_K1_END:			  ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift Dead Key
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_TH_END-$	       ;; length of state section
   DB	 DEAD_THIRD		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 1			       ;; number of entries
   DB	 26			       ;; scan code
   FLAG  DIARESIS		       ;; flag bit to set
				       ;;
COM_DK_TH_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alt Case
;; KEYBOARD TYPES: XT, G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_ALT_K1_END-$		;; length of state section
   DB	 ALT_CASE		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_ALT_K1_T1_END-$		;; Size of xlat table
   DB	 TYPE_2_TAB		     ;; xlat options:
   DB	 0			       ;; 2 number of entries
;   DB	  12,-1,-1			;; BLOT OUT HYPHEN
;   DB	  53,0,82H			;; MOVE HYPHEN
COM_ALT_K1_T1_END:			;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_ALT_K1_END: 			;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Ctrl Case
;; KEYBOARD TYPES: G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CTRL_K1_END-$		 ;; length of state section
   DB	 CTRL_CASE			;; State ID   **** CNS 12/18
   DW	 G_KB+P12_KB			;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_CTRL_K1_T1_END-$		 ;; Size of xlat table
   DB	 TYPE_2_TAB		     ;; xlat options:
   DB	 7			       ;; number of entries
   DB	 09,1BH,09		       ;; [
   DB	 10,1DH,10		       ;; ]
   DB	 12,-1,-1		       ;; BLOT OUT HYPHEN
   DB	 1AH,-1,-1		       ;;   "   "   [
   DB	 1BH,-1,-1		       ;;   "   "   ]
   DB	 29H,1CH,29H		       ;; backslash
   DB	 53,01FH,35H		       ;; MOVE HYPHEN
COM_CTRL_K1_T1_END:			 ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CTRL_K1_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Ctrl Case
;; KEYBOARD TYPES: XT
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; *** CNS 12/18/86
				       ;;
   DW	 COM_CTRL_K2_END-$		 ;; length of state section
   DB	 CTRL_CASE			;; State ID
   DW	 XT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_CTRL_K2_T1_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;; xlat options:
   DB	 5			       ;; number of entries
   DB	 12,-1,-1		       ;; BLOT OUT HYPHEN
   DB	 1AH,1BH,1AH		       ;;   "   "   [
   DB	 1BH,1DH,1BH		       ;;   "   "   ]
   DB	 43,1CH,43		       ;; backslash
   DB	 53,01FH,35H		       ;; MOVE HYPHEN
COM_CTRL_K2_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_CTRL_K2_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Lower Case
;; KEYBOARD TYPES: XT, G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AL_LO_END-$	       ;; length of state section
   DB	 ALPHA_LOWER		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_AL_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 1			       ;; number of entries
   DB	 39,087H		       ;; c-cedilla
COM_AL_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AL_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alpha Upper Case
;; KEYBOARD TYPES: XT, G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_AL_UP_END-$	       ;; length of state section
   DB	 ALPHA_UPPER		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_AL_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 1			       ;; number of entries
   DB	 39,080H		       ;; c-cedilla
COM_AL_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_AL_UP_END:			       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: XT,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 6			       ;; number of entries
   DB	 12,"'"                        ;;
   DB	 13,0AEH		       ;;
   DB	 26,"+"                        ;;
   DB	 40,0A7H		       ;;
   DB	 43,"<"                        ;;
   DB	 53,"-"                        ;;
COM_NA_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_K1_END-$		  ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_K1_T1_END-$		  ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 7			       ;; number of entries
   DB	 12,"'"                        ;;
   DB	 13,0AEH		       ;;
   DB	 26,"+"                        ;;
   DB	 40,0A7H		       ;;
   DB	 41,"\"                        ;;
   DB	 53,"-"                        ;;
   DB	 86,"<"                        ;;
COM_NA_LO_K1_T1_END:			  ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_K1_END:			  ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: XT,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 14			       ;;
   DB	  3,'"'                        ;;
   DB	  7,'&'                        ;;
   DB	  8,'/'                        ;;
   DB	  9,'('                        ;;
   DB	 10,')'                        ;;
   DB	 11,'='                        ;;
   DB	 12,'?'                        ;;
   DB	 13,0AFH		       ;; right double arrow Ø
   DB	 26,'*'                        ;;
   DB	 40,0A6H		       ;;¶ a underscore
   DB	 43,'>'                        ;;
   DB	 51,';'                        ;;
   DB	 52,':'                        ;;
   DB	 53,'_'                        ;;
				       ;;
COM_NA_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_END:			       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: G, P12,
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
   DB	 15			       ;;
   DB	  3,'"'                        ;;
   DB	  7,'&'                        ;;
   DB	  8,'/'                        ;;
   DB	  9,'('                        ;;
   DB	 10,')'                        ;;
   DB	 11,'='                        ;;
   DB	 12,'?'                        ;;
   DB	 13,0AFH		       ;; right double arrow Ø
   DB	 26,'*'                        ;;
   DB	 40,0A6H		       ;;¶ a underscore
   DB	 41,07CH		       ;;|
   DB	 51,';'                        ;;
   DB	 52,':'                        ;;
   DB	 53,'_'                        ;;
   DB	 86,'>'                        ;;
				       ;;
COM_NA_UP_K1_T1_END:			  ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_K1_END:			  ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift
;; KEYBOARD TYPES: XT,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_THIRD_END-$	       ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_THIRD_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 8			       ;; number of entries
   DB	  2,'|'                        ;;
   DB	  3,'@'                        ;;
   DB	  5,09CH		       ;; ú
   DB	  9,'{'                        ;;
   DB	 10,'}'                        ;;
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 43,'\'                        ;;
COM_THIRD_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Last xlat table
COM_THIRD_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift
;; KEYBOARD TYPES: G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_THIRD_K1_END-$		  ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_THIRD_K1_T1_END-$		  ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 6			       ;; number of entries
   DB	  3,'@'                        ;;
   DB	  4,09CH		       ;; ú
   DB	  8,'{'                        ;;
   DB	  9,'['                        ;;
   DB	 10,']'                        ;;
   DB	 11,'}'                        ;;
COM_THIRD_K1_T1_END:			  ;;
				       ;;
   DW	 0			       ;; Last xlat table
COM_THIRD_K1_END:			  ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Grave Lower
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_GR_LO_END-$	       ;; length of state section
   DB	 GRAVE_LOWER		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 96,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_GR_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 18,'ä'                        ;; scan code,ASCII - e
   DB	 22,'ó'                        ;; scan code,ASCII - u
   DB	 23,'ç'                        ;; scan code,ASCII - i
   DB	 24,'ï'                        ;; scan code,ASCII - o
   DB	 30,'Ö'                        ;; scan code,ASCII - a
COM_GR_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_GR_LO_END:			       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Grave Space Bar
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_GR_SP_END-$	       ;; length of state section
   DB	 GRAVE_SPACE		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
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
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CI_LO_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_LOWER	       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 94,0			       ;; error character = standalone accent
				       ;;
   DW	 COM_CI_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 18,'à'                        ;; scan code,ASCII - e
   DB	 24,'ì'                        ;; scan code,ASCII - o
   DB	 30,'É'                        ;; scan code,ASCII - a
COM_CI_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;;
				       ;;
COM_CI_LO_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Circumflex Space Bar
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CI_SP_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_SPACE	       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
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
;; CODE PAGE: Common
;; STATE: Tilde Lower
;; KEYBOARD TYPES: XT,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
    DW	  COM_TI_LO_END-$		;; length of state section
    DB	  TILDE_LOWER			;; State ID
    DW	  XT_KB 		  ;; Keyboard Type
    DB	  07EH,0			;; error character = standalone accent
					;;
    DW	  COM_TI_LO_T1_END-$		;; Size of xlat table
    DB	  STANDARD_TABLE+ZERO_SCAN	;; xlat options:
    DB	  4				;; number of scans
    DB	  30,0C6H			;; scan code,ASCII - tilde a
    DB	  24,0E4H			;; scan code,ASCII - tilde o
    DB	  49,0A4H			;; scan code,ASCII - §
    DB	  22,081h			;; scan code,ASCII - u diaresis
 COM_TI_LO_T1_END:			;; because the diaresis is not
					;; available on the XT
    DW	  0				;;
					;;
 COM_TI_LO_END: 			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CODE PAGE: Common
;;; STATE: Tilde Upper Case
;;; KEYBOARD TYPES: XT,
;;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
    DW	  COM_TI_UP_END-$		;; length of state section
    DB	  TILDE_UPPER		       ;; State ID
    DW	  XT_KB 		  ;; Keyboard Type
    DB	  07eH,0			 ;; error character = standalone accent
					;;
    DW	  COM_TI_UP_T1_END-$		;; Size of xlat table
    DB	  STANDARD_TABLE+ZERO_SCAN	;; xlat options:
    DB	  4				;; number of scans
    DB	  30,0C7H			;; scan code,ASCII - tilde A
    DB	  24,0E5H			;; scan code,ASCII - tilde O
    DB	  49,0A5H			;; scan code,ASCII - •
    DB	  22,09AH			;; scan code,ASCII - U diaresis
 COM_TI_UP_T1_END:			;; because the diaresis is not
					;; available on the XT
    DW	  0				;; Size of xlat table - null table
					;;
 COM_TI_UP_END: 			;; length of state section
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Tilde Lower
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
    DW	  COM_TI_LO_K1_END-$		   ;; length of state section
    DB	  TILDE_LOWER			;; State ID
    DW	  G_KB+P12_KB			;; Keyboard Type
    DB	  07EH,0			;; error character = standalone accent
					;;
    DW	  COM_TI_LO_K1_T1_END-$ 	   ;; Size of xlat table
    DB	  STANDARD_TABLE+ZERO_SCAN	;; xlat options:
    DB	  3				;; number of scans
    DB	  30,0C6H			;; scan code,ASCII - tilde a
    DB	  24,0E4H			;; scan code,ASCII - tilde o
    DB	  49,0A4H			;; scan code,ASCII - §
 COM_TI_LO_K1_T1_END:			   ;;
					;;
    DW	  0				;;
					;;
 COM_TI_LO_K1_END:			   ;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CODE PAGE: Common
;;; STATE: Tilde Upper Case
;;; KEYBOARD TYPES: G, P12
;;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
    DW	  COM_TI_UP_K1_END-$		   ;; length of state section
    DB	  TILDE_UPPER		       ;; State ID
    DW	  G_KB+P12_KB			;; Keyboard Type
    DB	  07EH,0			 ;; error character = standalone accent
					;;
    DW	  COM_TI_UP_K1_T1_END-$ 	   ;; Size of xlat table
    DB	  STANDARD_TABLE+ZERO_SCAN	;; xlat options:
    DB	  3				;; number of scans
    DB	  30,0C7H			;; scan code,ASCII - tilde A
    DB	  24,0E5H			;; scan code,ASCII - tilde O
    DB	  49,0A5H			;; scan code,ASCII - •
 COM_TI_UP_K1_T1_END:			   ;;
					;;
    DW	  0				;; Size of xlat table - null table
					;;
 COM_TI_UP_K1_END:			   ;; length of state section
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Tilde Space Bar
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_TI_SP_END-$	       ;; length of state section
   DB	 TILDE_SPACE		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 07EH,0 			 ;; error character = standalone accent
				       ;;
   DW	 COM_TI_SP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,07EH		      ;; STANDALONE TILDE
COM_TI_SP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_TI_SP_END:			       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 0			       ;; Last State
COMMON_XLAT_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; PO Specific Translate Section for 860
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC PO_860_XLAT		       ;;
PO_860_XLAT:			       ;;
				       ;;
   DW	  CP860_XLAT_END-$	       ;; length of section
   DW	  860			       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 860
;; STATE: Third Shift
;; KEYBOARD TYPES: G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP860_THIRD_K1_END-$		    ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 CP860_THIRD_K1_T1_END-$	    ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 1			       ;; number of entries
   DB	 5,015H 		      ;; section symbol
CP860_THIRD_K1_T1_END:			    ;;
				       ;;
   DW	 0			       ;; Last xlat table
CP860_THIRD_K1_END:			    ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 860
;; STATE: Acute Lower Case
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP860_AC_LO_END-$		 ;; length of state section
   DB	 ACUTE_LOWER		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 39,0			       ;; error character = standalone accent
				       ;;
   DW	 CP860_AC_LO_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 18,'Ç'                        ;; scan code,ASCII - e
   DB	 22,'£'                        ;; scan code,ASCII - u
   DB	 23,'°'                        ;; scan code,ASCII - i
   DB	 24,'¢'                        ;; scan code,ASCII - o
   DB	 30,'†'                        ;; scan code,ASCII - a
CP860_AC_LO_T1_END:			 ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP860_AC_LO_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 860
;; STATE: Acute Upper Case
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP860_AC_UP_END-$	       ;; length of state section
   DB	 ACUTE_UPPER		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 39,0			       ;; error character = standalone accent
				       ;;
   DW	 CP860_AC_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 18,090H		       ;; E acute
   DB	 22,096H		       ;; U acute
   DB	 23,08BH		       ;; I acute
   DB	 24,09FH		       ;; O acute
   DB	 30,086H		       ;; A acute
CP860_AC_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP860_AC_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 860
;; STATE: Acute Space Bar
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP860_AC_SP_END-$		 ;; length of state section
   DB	 ACUTE_SPACE		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 39,0			       ;; error character = standalone accent
				       ;;
   DW	 CP860_AC_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,39			       ;; scan code,ASCII - SPACE
CP860_AC_SP_T1_END:			 ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP860_AC_SP_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 860
;; STATE: Grave Upper
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP860_GR_UP_END-$	       ;; length of state section
   DB	 GRAVE_UPPER		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 96,0			       ;; error character = standalone accent
				       ;;
   DW	 CP860_GR_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 18,092H		       ;;    E grave
   DB	 22,09DH		       ;;    U grave
   DB	 23,098H		       ;;    I grave
   DB	 24,0A9H		       ;;    O grave
   DB	 30,091H		       ;;    A grave
CP860_GR_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP860_GR_UP_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 860
;; STATE: Circumflex Upper
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP860_CI_UP_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_UPPER	       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 94,0			       ;; error character = standalone accent
				       ;;
   DW	 CP860_CI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 30,08FH		       ;;    A circumflex
   DB	 18,089H		       ;;    E circumflex
   DB	 24,08CH		       ;;    O circumflex
CP860_CI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP860_CI_UP_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 860
;; STATE: Tilde Lower
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
    DW	  CP860_TI_LO_END-$		  ;; length of state section
    DB	  TILDE_LOWER			;; State ID
    DW	  XT_KB+G_KB+P12_KB	  ;; Keyboard Type
    DB	  07eH,0			;; error character = standalone accent
					;;
    DW	  CP860_TI_LO_T1_END-$		  ;; Size of xlat table
    DB	  STANDARD_TABLE+ZERO_SCAN	;; xlat options:
    DB	  2				;; number of scans
    DB	  24,094H			;; scan code,ASCII - o tilde
    DB	  30,084H			;; scan code,ASCII - a tilde
 CP860_TI_LO_T1_END:			  ;;
					;;
    DW	  0				;;
					;;
 CP860_TI_LO_END:			  ;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CODE PAGE: 860
;;; STATE: Tilde Upper Case
;;; KEYBOARD TYPES: XT, , G, P12,
;;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
    DW	  CP860_TI_UP_END-$		  ;; length of state section
    DB	  TILDE_UPPER		       ;; State ID
    DW	  XT_KB+G_KB+P12_KB	  ;; Keyboard Type
    DB	  07eH,0			 ;; error character = standalone accent
					;;
    DW	  CP860_TI_UP_T1_END-$		  ;; Size of xlat table
    DB	  STANDARD_TABLE+ZERO_SCAN	;; xlat options:
    DB	  2				;; number of scans
    DB	  24,099H			;; scan code,ASCII - O tilde
    DB	  30,08EH			;; scan code,ASCII - A tilde
 CP860_TI_UP_T1_END:			;;
					;;
    DW	  0				;; Size of xlat table - null table
					;;
 CP860_TI_UP_END:			;; length of state section
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 860
;; STATE: Diaresis Lower
;; KEYBOARD TYPES: G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP860_DI_LO_END-$	       ;; length of state section
   DB	 DIARESIS_LOWER 	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 0FEH,0 		       ;; error character = standalone accent
				       ;;
   DW	 CP860_DI_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 22,081H		       ;;    u diaeresis
CP860_DI_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP860_DI_LO_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 860
;; STATE: Diaresis Upper
;; KEYBOARD TYPES: G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP860_DI_UP_END-$	       ;; length of state section
   DB	 DIARESIS_UPPER 	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 0FEH,0 		       ;; error character = standalone accent
				       ;;
   DW	 CP860_DI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 22,09AH		       ;;    U diaeresis
CP860_DI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP860_DI_UP_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 860
;; STATE: Diaresis Space Bar
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP860_DI_SP_END-$	       ;; length of state section
   DB	 DIARESIS_SPACE 	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 0FEH,0 		       ;; error character = standalone accent
				       ;;
   DW	 CP860_DI_SP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,0FEH		       ;; scan code,ASCII - SPACE
CP860_DI_SP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP860_DI_SP_END:		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	  0			       ;; LAST STATE
				       ;;
CP860_XLAT_END: 		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PO Specific Translate Section for 850
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC PO_850_XLAT		       ;;
PO_850_XLAT:			       ;;
				       ;;
   DW	  CP850_XLAT_END-$	       ;; length of section
   DW	  850			       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Third Shift
;; KEYBOARD TYPES: G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_THIRD_K1_END-$		    ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 CP850_THIRD_K1_T1_END-$	    ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 1			       ;; number of entries
   DB	 5,0F5H 		      ;; section symbol
CP850_THIRD_K1_T1_END:			    ;;
				       ;;
   DW	 0			       ;; Last xlat table
CP850_THIRD_K1_END:			    ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Acute Lower Case
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_LO_END-$	       ;; length of state section
   DB	 ACUTE_LOWER		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 239,0				;; error character = standalone accent
				       ;;
   DW	 CP850_AC_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 6			       ;; number of scans
   DB	 18,'Ç'                        ;; scan code,ASCII - e
   DB	 21,0ECH		       ;; y acute
   DB	 22,'£'                        ;; scan code,ASCII - u
   DB	 23,'°'                        ;; scan code,ASCII - i
   DB	 24,'¢'                        ;; scan code,ASCII - o
   DB	 30,'†'                        ;; scan code,ASCII - a
CP850_AC_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_LO_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Acute Upper Case
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_UP_END-$	       ;; length of state section
   DB	 ACUTE_UPPER		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 239,0				;; error character = standalone accent
				       ;;
   DW	 CP850_AC_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 6			       ;; number of scans
   DB	 18,090H		       ;; E acute
   DB	 21,0EDH		       ;;    Y acute
   DB	 22,0E9H		       ;;    U acute
   DB	 23,0D6H		       ;;    I acute
   DB	 24,0E0H		       ;;    O acute
   DB	 30,0B5H		       ;;    A acute
CP850_AC_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Acute Space Bar
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_SP_END-$		 ;; length of state section
   DB	 ACUTE_SPACE		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 239,0				;; error character = standalone accent
				       ;;
   DW	 CP850_AC_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,239 			;; scan code,ASCII - SPACE
CP850_AC_SP_T1_END:			 ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_SP_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Diaresis Lower
;; KEYBOARD TYPES: G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_DI_LO_END-$	       ;; length of state section
   DB	 DIARESIS_LOWER 	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 249,0			       ;; error character = standalone accent
				       ;;
   DW	 CP850_DI_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 6			       ;; number of scans
   DB	 18,089H		       ;;    e diaeresis
   DB	 21,098H		       ;;    y diaeresis
   DB	 22,081H		       ;;    u diaeresis
   DB	 23,08BH		       ;;    i diaeresis
   DB	 24,094H		       ;;    o diaeresis
   DB	 30,084H		       ;;    a diaeresis
CP850_DI_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_DI_LO_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Diaresis Upper
;; KEYBOARD TYPES: G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_DI_UP_END-$	       ;; length of state section
   DB	 DIARESIS_UPPER 	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 249,0			       ;; error character = standalone accent
				       ;;
   DW	 CP850_DI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 18,0D3H		       ;;    E diaeresis
   DB	 22,09AH		       ;;    U diaeresis
   DB	 23,0D8H		       ;;    I diaeresis
   DB	 24,099H		       ;;    O diaeresis
   DB	 30,08EH		       ;;    A diaeresis
CP850_DI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_DI_UP_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Diaresis Space Bar
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_DI_SP_END-$		 ;; length of state section
   DB	 DIARESIS_SPACE 		  ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 249,0				;; error character = standalone accent
				       ;;
   DW	 CP850_DI_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 57,249 			;; scan code,ASCII - SPACE
CP850_DI_SP_T1_END:			 ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_DI_SP_END:			 ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Grave Upper
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_GR_UP_END-$	       ;; length of state section
   DB	 GRAVE_UPPER		       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
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
;; STATE: Tilde Lower
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
    DW	  CP850_TI_LO_END-$		  ;; length of state section
    DB	  TILDE_LOWER			;; State ID
    DW	  XT_KB+G_KB+P12_KB	  ;; Keyboard Type
    DB	  07EH,0			;; error character = standalone accent
					;;
    DW	  CP850_TI_LO_T1_END-$		  ;; Size of xlat table
    DB	  STANDARD_TABLE+ZERO_SCAN	;; xlat options:
    DB	  2				;; number of scans
    DB	  30,0C6H			;; scan code,ASCII - a tilde
    DB	  24,0E4H			;; scan code,ASCII - o tilde
 CP850_TI_LO_T1_END:			  ;;
					;;
    DW	  0				;;
					;;
 CP850_TI_LO_END:			  ;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CODE PAGE: 850
;;; STATE: Tilde Upper Case
;;; KEYBOARD TYPES: XT, , G, P12,
;;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
    DW	  CP850_TI_UP_END-$		  ;; length of state section
    DB	  TILDE_UPPER		       ;; State ID
    DW	  XT_KB+G_KB+P12_KB	  ;; Keyboard Type
    DB	  07eH,0			 ;; error character = standalone accent
					;;
    DW	  CP850_TI_UP_T1_END-$		  ;; Size of xlat table
    DB	  STANDARD_TABLE+ZERO_SCAN	;; xlat options:
    DB	  2				;; number of scans
    DB	  30,0C7H			;; scan code,ASCII - A tilde
    DB	  24,0E5H			;; scan code,ASCII - O tilde
 CP850_TI_UP_T1_END:			  ;;
					;;
    DW	  0				;; Size of xlat table - null table
					;;
 CP850_TI_UP_END:			  ;; length of state section
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Circumflex Lower
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_CI_LO_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_LOWER	       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
   DB	 94,0			       ;; error character = standalone accent
				       ;;
   DW	 CP850_CI_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 2			       ;; number of scans
   DB	 23,08CH		       ;;    i circumflex
   DB	 22,096H		       ;;    u circumflex
CP850_CI_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_CI_LO_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Circumflex Upper
;; KEYBOARD TYPES: XT, , G, P12,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_CI_UP_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_UPPER	       ;; State ID
   DW	 XT_KB+G_KB+P12_KB	 ;; Keyboard Type
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 0			       ;; LAST STATE
				       ;;
CP850_XLAT_END: 		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
CODE	 ENDS			       ;;
	 END			       ;;

