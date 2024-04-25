; ACUTE lc y added
; ****** CNS 12/18
; ****** CNS 01/21 NUM PAD
	PAGE	,132
	TITLE	DOS - Keyboard Definition File

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - - NLS Support - Keyboard Defintion File
;; (c) Copyright 1988 Microsoft
;;
;; This file contains the keyboard tables for Belgium.
;;
;; Linkage Instructions:
;;	Refer to KDF.ASM.
;;
;;
;; Modded from French - DTF 11-Sep-86
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
	INCLUDE KEYBSHAR.INC	       ;;
	INCLUDE POSTEQU.INC	       ;;
	INCLUDE KEYBMAC.INC	       ;;
				       ;;
	PUBLIC BE_LOGIC 	       ;;
	PUBLIC BE_437_XLAT	       ;;
	PUBLIC BE_850_XLAT	       ;;
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
;; BE State Logic
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
BE_LOGIC:

   DW  LOGIC_END-$		       ;; length
				       ;;
   DW  TYPEWRITER_CAPS_LK	       ;; special features
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
     IFF CAPS_STATE
	 SET_FLAG DEAD_UPPER
     ELSEF
      IFF EITHER_SHIFT		       ;;
	  SET_FLAG DEAD_UPPER	       ;;
      ELSEF			       ;;
	  SET_FLAG DEAD_LOWER	       ;;
      ENDIFF			       ;;
     ENDIFF
   ELSEF			       ;;
      IFF EITHER_SHIFT,NOT	       ;;
	IFKBD XT_KB+AT_KB
	  IFF EITHER_CTL		;;
	  ANDF ALT_SHIFT		;;
	    SET_FLAG DEAD_THIRD        ;;
	  ENDIFF			;;
	ELSEF
	 IFF R_ALT_SHIFT	       ;;
	 ANDF EITHER_CTL,NOT	       ;;
	 ANDF LC_E0,NOT 	       ;;
	    SET_FLAG DEAD_THIRD        ;;
	 ENDIFF 		       ;;
	ENDIFF
       ENDIFF
   ENDIFF			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ACUTE ACCENT TRANSLATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
ACUTE_PROC:			       ;;
				       ;;
   IFF ACUTE,NOT		       ;;
      GOTO TILDE_PROC		       ;;
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
      PUT_ERROR_CHAR TILDE_LOWER       ;; standalone accent
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
;***************************
NON_DEAD:			       ;;
;ADDED FOR DIVIDE SIGN		       ;;
    IFKBD G_KB+P12_KB			;; Avoid accidentally translating
    ANDF LC_E0				;;  the "/" on the numeric pad of the
      IFF EITHER_CTL,NOT
      ANDF EITHER_ALT,NOT
	XLATT DIVIDE_SIGN	       ;;
      ENDIFF
      EXIT_STATE_LOGIC		     ;;
    ENDIFF			       ;;
;BD END OF ADDITION
;****************************
;NON_DEAD:				;;
;					;;
;  IFKBD G_KB+P12_KB		       ;; Avoid accidentally translating
;  ANDF LC_E0			       ;;  the "/" on the numeric pad of the
;     EXIT_STATE_LOGIC		       ;;   G keyboard
;  ENDIFF			       ;;
				       ;;
   IFF	EITHER_ALT,NOT		       ;;
   ANDF EITHER_CTL,NOT		       ;;
      IFF EITHER_SHIFT		       ;;
;******************************************
;;***BD ADDED FOR NUMERIC PAD
	  IFF NUM_STATE,NOT	       ;;
	      XLATT NUMERIC_PAD        ;;
	  ENDIFF		       ;;
;;***BD END OF ADDITION
;*******************************************
	  IFF CAPS_STATE	       ;;
	      XLATT ALPHA_LOWER        ;;
	      XLATT NON_ALPHA_LOWER    ;;
	  ELSEF 		       ;;
	      XLATT ALPHA_UPPER        ;;
	      XLATT NON_ALPHA_UPPER    ;;
	  ENDIFF		       ;;
      ELSEF			       ;;
;******************************************
;;***BD ADDED FOR NUMERIC PAD
	  IFF NUM_STATE 	       ;;
	      XLATT NUMERIC_PAD        ;;
	  ENDIFF		       ;;
;;***BD END OF ADDITION
;******************************************
	  IFF CAPS_STATE	       ;;
	     XLATT ALPHA_UPPER	       ;;
      XLATT NON_ALPHA_UPPER	       ;;
	  ELSEF 		       ;;
	     XLATT ALPHA_LOWER	       ;;
	     XLATT NON_ALPHA_LOWER     ;;
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
      IFKBD AT_KB+XT_KB 	 ;;
	IFF EITHER_CTL		       ;;
	ANDF ALT_SHIFT		       ;;
	  XLATT ALT_CASE	       ;;
	ENDIFF			       ;;
      ENDIFF			       ;;
      IFKBD G_KB+P12_KB 	       ;;
	IFF EITHER_CTL		       ;;
	ANDF ALT_SHIFT		       ;;
	  IFF R_ALT_SHIFT,NOT		  ;;
	    XLATT ALT_CASE		  ;;
	  ENDIFF			  ;;
	ENDIFF				  ;;
      ENDIFF				  ;;
     ENDIFF				  ;;
   ENDIFF				  ;;
;IFF EITHER_SHIFT,NOT			  ;;
   IFKBD AT_KB+XT_KB		    ;;
     IFF EITHER_CTL,NOT 		  ;;
       IFF ALT_SHIFT			  ;; ALT - case
	 XLATT ALT_CASE 		  ;;
       ENDIFF				  ;;
     ELSEF				  ;;
	 XLATT CTRL_CASE		  ;;
     ENDIFF				  ;;
   ENDIFF				  ;;
					  ;;
   IFKBD G_KB+P12_KB			  ;;
     IFF EITHER_CTL,NOT 		  ;;
       IFF ALT_SHIFT			  ;; ALT - case
       ANDF R_ALT_SHIFT,NOT		  ;;
	 XLATT ALT_CASE 		  ;;
       ENDIFF				  ;;
     ELSEF				  ;;
       IFF EITHER_ALT,NOT		  ;;
	 XLATT CTRL_CASE		  ;;
       ENDIFF				  ;;
     ENDIFF				  ;;
     IFF EITHER_CTL			  ;;
     ANDF ALT_SHIFT			  ;;
     ANDF R_ALT_SHIFT,NOT		  ;;
	XLATT ALT_CASE			  ;;
     ENDIFF				  ;;
   ENDIFF				  ;;
					  ;;
   EXIT_STATE_LOGIC			  ;;
					  ;;
LOGIC_END:				  ;;
					  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; BE Common Translate Section
;; This section contains translations for the lower 128 characters
;; only since these will never change from code page to code page.
;; In addition the dead key "Set Flag" tables are here since the
;; dead keys are on the same keytops for all code pages.
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC BE_COMMON_XLAT		       ;;
BE_COMMON_XLAT: 		       ;;
				       ;;
   DW	 COMMON_XLAT_END-$	       ;; length of section
   DW	 -1			       ;; code page
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alt Case
;; KEYBOARD TYPES: G + P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_ALT_K1_END-$	       ;; length of state section
   DB	 ALT_CASE		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 COM_ALT_K1_T1_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;;
   DB	 8			       ;; Number of entries
   DB	 12,-1,-1		       ;;
   DB	 13,0,82H		       ;;
   DB	 16,0,1EH		       ;; A
   DB	 17,0,2CH		       ;; Z
   DB	 30,0,10H		       ;; Q
   DB	 39,0,32H		       ;; M
   DB	 44,0,11H		       ;; W
   DB	 50,-1,-1		       ;; U.S. 'M'
COM_ALT_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;;
				       ;;
COM_ALT_K1_END: 		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Ctrl Case
;; KEYBOARD TYPES: G + P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CTRL_K1_END-$	       ;; length of state section
   DB	 CTRL_CASE		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 COM_CTRL_K1_T1_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;;
   DB	 10			       ;; Number of entries
   DB	 12,-1,-1		       ;;
   DB	 13,31,13		       ;;
   DB	 16,01,16		       ;; A
   DB	 17,26,17		       ;; Z
   DB	 30,17,30		       ;; Q
   DB	 39,13,39		       ;; M
   DB	 43,-1,-1		       ;; \
   DB	 44,23,44		       ;; W
   DB	 50,-1,-1		       ;; U.S. 'M'
   DB	 86,28,86		       ;;
COM_CTRL_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;;
				       ;;
COM_CTRL_K1_END:		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Alt Case
;; KEYBOARD TYPES: AT + XT
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_ALT_K2_END-$	       ;; length of state section
   DB	 ALT_CASE		       ;; State ID
   DW	 AT_KB+XT_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 COM_ALT_K2_T2_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;;
   DB	 6			       ;; Number of entries
;  DB	 12,-1,-1		       ;; invalid key U.S. alt -
;  DB	 13,0,82H		       ;; alt - (minus sign)
;  DB	 53,0,83H		       ;; alt = (equal sign)
   DB	 16,0,1EH		       ;; A
   DB	 17,0,2CH		       ;; Z
   DB	 30,0,10H		       ;; Q
   DB	 39,0,32H		       ;; M
   DB	 44,0,11H		       ;; W
   DB	 50,-1,-1		       ;; U.S. 'M'
COM_ALT_K2_T2_END:		       ;;
				       ;;
   DW	 0			       ;;
				       ;;
COM_ALT_K2_END: 		       ;;
				       ;;
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
				       ;; Set Flag Table
   DW	 COM_CTRL_K2_T2_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;;
   DB	 11				;; Number of entries
   DB	 12,-1,-1		       ;; invalid U.S. -
   DB	 43,-1,-1		       ;; invalid U.S. \
   DB	 41,28,41		       ;; valid ctl + \
   DB	 07,30,07		       ;; ctl + number six key
   DB	 13,31,13		       ;; ctl - or _
   DB	 16,01,16		       ;; A
   DB	 17,26,17		       ;; Z
   DB	 30,17,30		       ;; Q
   DB	 39,13,39		       ;; M
   DB	 44,23,44		       ;; W
   DB	 50,-1,-1		       ;; U.S. 'M'
COM_CTRL_K2_T2_END:		       ;;
				       ;;
   DW	 0			       ;;
				       ;;
COM_CTRL_K2_END:		       ;;
				       ;;
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
   DW	 AT_KB+XT_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 COM_CTRL_K3_T3_END-$	       ;; Size of xlat table
   DB	 TYPE_2_TAB		       ;;
   DB	 11			       ;; Number of entries
   DB	 12,-1,-1		       ;;
   DB	 43,-1,-1		       ;;
   DB	 43,28,43		       ;; valid ctl + \
   DB	 07,30,07		       ;; ctl + number six key
   DB	 13,31,13		       ;; ctl - or _
   DB	 16,01,16		       ;; A
   DB	 17,26,17		       ;; Z
   DB	 30,17,30		       ;; Q
   DB	 39,13,39		       ;; M
   DB	 44,23,44		       ;; W
   DB	 50,-1,-1		       ;; U.S. 'M'
COM_CTRL_K3_T3_END:		       ;;
				       ;;
   DW	 0			       ;;
				       ;;
COM_CTRL_K3_END:		       ;;
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
   DB	 26			       ;; scan code
   FLAG  CIRCUMFLEX		       ;; flag bit to set
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
   DB	 26			       ;; scan code
   FLAG  DIARESIS		       ;; flag bit to set
				       ;;
COM_DK_UP_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift Dead Key
;; KEYBOARD TYPES: G, P12,AT
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_TH_END-$	       ;; length of state section
   DB	 DEAD_THIRD		       ;; State ID
   DW	 G_KB+P12_KB+AT_KB	       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 3			       ;; number of entries
   DB	40			       ;;
   FLAG ACUTE			       ;;
   DB	43			       ;;
   FLAG GRAVE			       ;;
   DB	53			       ;;
   FLAG TILDE			       ;;
				       ;;
COM_DK_TH_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift Dead Key
;; KEYBOARD TYPES: XT +
;; TABLE TYPE: Flag Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_DK_TH_K1_END-$	       ;; length of state section
   DB	 DEAD_THIRD		       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;; Set Flag Table
   DW	 3			       ;; number of entries
   DB	40			       ;;
   FLAG ACUTE			       ;;
   DB	41			       ;;
   FLAG GRAVE			       ;;
   DB	53			       ;;
   FLAG TILDE			       ;;
				       ;;
COM_DK_TH_K1_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;**************************************************** CODE eliminated**********
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	      NUM PAD altered  ********
;; CODE PAGE: 850				      CNS engraved "," out
;; STATE: Numeric Pad - Divide Sign
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;					;;
;; DW	 CP850_DIVID_END-$	       ;; length of state section
;; DB	 DIVIDE_SIGN		       ;; State ID
;; DW	 G_KB+P12_KB		       ;; Keyboard Type
;; DB	 -1,-1			       ;; error character = standalone accent
;;				       ;;
;; DW	 CP850_DIVID_T1_END-$	       ;; Size of xlat table
;; DB	 TYPE_2_TAB		       ;; xlat options:
;; DB	 2			       ;; number of scans
;; DB	 0E0H,',',0E0H                ;; DIVIDE SIGN
;; DB	 51,',',0E0H                  ;;
;; CP850_DIVID_T1_END:			  ;;
;;					  ;;
;;    DW    0				  ;; Size of xlat table - null table
;;					  ;;
;; CP850_DIVID_END:			  ;;
;;					  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Numeric Key Pad - Multiplication
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;				       ;;
;; DW	 CP850_PAD_K1_END-$	       ;; length of state section
;; DB	 NUMERIC_PAD		       ;; State ID
;; DW	 P12_KB 		       ;; Keyboard Type
;; DB	 -1,-1			       ;; Buffer entry for error character
;;				       ;;
;; DW	 CP850_PAD_K1_T1_END-$	       ;; Size of xlat table
;; DB	 STANDARD_TABLE 	       ;; xlat options:
;; DB	 1			       ;; number of entries
;; DB	 51,',' ; (removed *** CNS ****)  ;; MULTIPLICATION SIGN
;;  CP850_PAD_K1_T1_END:		   ;;
;;					   ;;
;;     DW    0				   ;; Size of xlat table - null table
;;					   ;;
;;  CP850_PAD_K1_END:			   ;;
;;					   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*********************************************************
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
   DB	 16,'a'                        ;; small a
   DB	 17,'z'                        ;; small z
   DB	 30,'q'                        ;; small q
   DB	 39,'m'                        ;; small m
   DB	 44,'w'                        ;; small w
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
   DB	 16,'A'                        ;; caps  A
   DB	 17,'Z'                        ;; caps  Z
   DB	 30,'Q'                        ;; caps  Q
   DB	 39,'M'                        ;; caps  M
   DB	 44,'W'                        ;; caps  W
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
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 20			       ;; number of entries
   DB	 41,"˝"                        ;; superscript 2
   DB	  2,"&"                        ;;
   DB	  3,"Ç"                        ;; acute - e
   DB	  4,'"'                        ;;
   DB	  5,"'"                        ;;
   DB	  6,"("                        ;;
   DB	  8,"ä"                        ;; grave - e
   DB	  9,"!"                        ;;
   DB	 10,"á"                        ;; c - cedilla small
   DB	 11,"Ö"                        ;;
   DB	 12,")"                        ;;
   DB	 13,"-"                        ;;
   DB	 27,"$"                        ;;
   DB	 40,"ó"                        ;; grave - u
   DB	 43,0E6H		       ;; mu
   DB	 86,'<'                        ;;
   DB	 50,','                        ;;
   DB	 51,';'                        ;;
   DB	 52,':'                        ;;
   DB	 53,'='                        ;;
COM_NA_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_END:			       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES:AT
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_K2_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 AT_KB			       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_T1_K2_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 19			       ;; number of entries
   DB	 41,"<"                        ;;
   DB	  2,"&"                        ;;
   DB	  3,"Ç"                        ;; acute - e
   DB	  4,'"'                        ;;
   DB	  5,"'"                        ;;
   DB	  6,"("                        ;;
   DB	  8,"ä"                        ;; grave - e
   DB	  9,"!"                        ;;
   DB	 10,"á"                        ;; c - cedilla small
   DB	 11,"Ö"                        ;;
   DB	 12,")"                        ;;
   DB	 13,"-"                        ;;
   DB	 27,"$"                        ;;
   DB	 40,"ó"                        ;; grave - u
   DB	 43,0E6H		       ;; mu
   DB	 50,','                        ;;
   DB	 51,';'                        ;;
   DB	 52,':'                        ;;
   DB	 53,'='                        ;;
COM_NA_LO_T1_K2_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_K2_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: XT,
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_LO_K1_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_LO_K1_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 19			       ;; number of entries
   DB	  2,"&"                        ;;
   DB	  3,"Ç"                        ;; acute - e
   DB	  4,'"'                        ;;
   DB	  5,"'"                        ;;
   DB	  6,"("                        ;;
   DB	  8,"ä"                        ;;
   DB	  9,"!"                        ;;
   DB	 10,"á"                        ;; c - cedilla small
   DB	 11,"Ö"                        ;;
   DB	 12,")"                        ;;
   DB	 13,"-"                        ;;
   DB	 27,"$"                        ;;
   DB	 40,"ó"                        ;; grave - u
   DB	 41,0E6H		       ;; mu
   DB	 43,'<'                        ;;
   DB	 50,','                        ;;
   DB	 51,';'                        ;;
   DB	 52,':'                        ;;
   DB	 53,'='                        ;;
COM_NA_LO_K1_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_LO_K1_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 20			       ;; number of entries
   DB	  2,'1'                        ;;
   DB	  3,'2'                        ;;
   DB	  4,'3'                        ;;
   DB	  5,'4'                        ;;
   DB	  6,'5'                        ;;
   DB	  7,'6'                        ;;
   DB	  8,'7'                        ;;
   DB	  9,'8'                        ;;
   DB	 10,'9'                        ;;
   DB	 11,'0'                        ;;
   DB	 12,0F8H		       ;; degree symbol
   DB	 13,"_"                        ;;
   DB	 27,"*"                        ;;
   DB	 40,'%'                        ;;
   DB	 43,'ú'                        ;;
   DB	 86,'>'                        ;;
   DB	 50,'?'                        ;;
   DB	 51,'.'                        ;;
   DB	 52,'/'                        ;;
   DB	 53,'+'                        ;;
COM_NA_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_END:			       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: XT +
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_NA_UP_K1_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_NA_UP_T1_K1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 20			       ;; number of entries
   DB	 41,'ú'                        ;;
   DB	  2,'1'                        ;;
   DB	  3,'2'                        ;;
   DB	  4,'3'                        ;;
   DB	  5,'4'                        ;;
   DB	  6,'5'                        ;;
   DB	  7,'6'                        ;;
   DB	  8,'7'                        ;;
   DB	  9,'8'                        ;;
   DB	 10,'9'                        ;;
   DB	 11,'0'                        ;;
   DB	 12,0F8H		       ;; degree symbol
   DB	 13,"_"                        ;;
   DB	 27,"*"                        ;;
   DB	 40,'%'                        ;;
   DB	 43,'>'                        ;;
   DB	 50,'?'                        ;;
   DB	 51,'.'                        ;;
   DB	 52,'/'                        ;;
   DB	 53,'+'                        ;;
COM_NA_UP_T1_K1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_K1_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
   DW	 COM_NA_UP_T1_K2_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 20			       ;; number of entries
   DB	 41,'>'                        ;;
   DB	  2,'1'                        ;;
   DB	  3,'2'                        ;;
   DB	  4,'3'                        ;;
   DB	  5,'4'                        ;;
   DB	  6,'5'                        ;;
   DB	  7,'6'                        ;;
   DB	  8,'7'                        ;;
   DB	  9,'8'                        ;;
   DB	 10,'9'                        ;;
   DB	 11,'0'                        ;;
   DB	 12,0F8H		       ;; degree symbol
   DB	 13,"_"                        ;;
   DB	 27,"*"                        ;;
   DB	 40,'%'                        ;;
   DB	 43,'ú'                        ;;
   DB	 50,'?'                        ;;
   DB	 51,'.'                        ;;
   DB	 52,'/'                        ;;
   DB	 53,'+'                        ;;
COM_NA_UP_T1_K2_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
COM_NA_UP_K2_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_THIRD_END-$	       ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_THIRD_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	  9			       ;; number of entries
   DB	  2,"|"                        ;;
   DB	  3,'@'                        ;;
   DB	  4,'#'                        ;;
   DB	  7,'^'                        ;;
   DB	 10,'{'                        ;;
   DB	 11,'}'                        ;;
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 86,'\'                        ;;
COM_THIRD_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Last xlat table
COM_THIRD_END:			       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Third Shift
;; KEYBOARD TYPES: XT
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_THIRD_K1_END-$	       ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 XT_KB			 ;; Keyboard Type
   DB	 -1,-1			       ;; Buffer entry for error character
				       ;;
   DW	 COM_THIRD_T1_K1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	  9			       ;; number of entries
   DB	  2,"|"                        ;;
   DB	  3,'@'                        ;;
   DB	  4,'#'                        ;;
   DB	  7,'^'                        ;;
   DB	 10,'{'                        ;;
   DB	 11,'}'                        ;;
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 43,'\'                        ;;
COM_THIRD_T1_K1_END:		       ;;
				       ;;
   DW	 0			       ;; Last xlat table
COM_THIRD_K1_END:		       ;;
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
   DW	 COM_THIRD_T1_K2_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	  9			       ;; number of entries
   DB	  2,"|"                        ;;
   DB	  3,'@'                        ;;
   DB	  4,'#'                        ;;
   DB	  7,'^'                        ;;
   DB	 10,'{'                        ;;
   DB	 11,'}'                        ;;
   DB	 26,'['                        ;;
   DB	 27,']'                        ;;
   DB	 41,'\'                        ;;
COM_THIRD_T1_K2_END:		       ;;
				       ;;
   DW	 0			       ;; Last xlat table
COM_THIRD_K2_END:		       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Grave Lower
;; KEYBOARD TYPES: ALL
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 COM_GR_LO_END-$		 ;; length of state section
   DB	 GRAVE_LOWER			 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
   DB	 96,0				 ;; error character = standalone accent
					 ;;
   DW	 COM_GR_LO_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 5				 ;; number of scans
   DB	 18,'ä'                          ;; scan code,ASCII - e
   DB	 16,'Ö'                          ;; scan code,ASCII - a
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
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_GR_UP_END-$	       ;; length of state section
   DB	 GRAVE_UPPER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 96,0			       ;; error character = standalone accent
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
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 COM_GR_SP_END-$		 ;; length of state section
   DB	 GRAVE_SPACE			 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
   DB	 96,0				 ;; error character = standalone accent
					 ;;
   DW	 COM_GR_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 57,96				 ;; STANDALONE GRAVE
COM_GR_SP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
COM_GR_SP_END:				 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
   DB	 16,'É'                        ;; scan code,ASCII - a
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
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 COM_CI_UP_END-$	       ;; length of state section
   DB	 CIRCUMFLEX_UPPER	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 94,0			       ;; error character = standalone accent
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
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: Common
;; STATE: Tilde Space Bar
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 COM_TI_SP_END-$		 ;; length of state section
   DB	 TILDE_SPACE			 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
   DB	 126,0				 ;; error character = standalone accent
					 ;;
   DW	 COM_TI_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 57,126 			 ;; STANDALONE TIDLE
COM_TI_SP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
COM_TI_SP_END:				 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	 0			       ;; Last State
COMMON_XLAT_END:		       ;;
				       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; BE Specific Translate Section for 437
;;
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC BE_437_XLAT		       ;;
BE_437_XLAT:			       ;;
				       ;;
   DW	  CP437_XLAT_END-$	       ;; length of section
   DW	  437			       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 437
;; STATE: Non-Alpha Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_NA_LO_END-$	       ;; length of state section
   DB	 NON_ALPHA_LOWER	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; default ignore error state
				       ;;
   DW	 CP437_NA_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 1			       ;; number of scans
   DB	7,15H			       ;; Section Symbol
CP437_NA_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_NA_LO_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 437
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_NA_UP_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; default ignore error state
				       ;;
   DW	 CP437_NA_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 1			       ;; number of scans
   DB	41,00H			       ;; 3 Superscript
CP437_NA_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_NA_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP437
;; STATE: Acute Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_AC_LO_END-$	       ;; length of state section
   DB	 ACUTE_LOWER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 39,0			       ;; error character = standalone accent
				       ;;
   DW	 CP437_AC_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 5			       ;; number of scans
   DB	 16,'†'                        ;; a acute
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
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP437_AC_UP_END-$		 ;; length of state section
   DB	 ACUTE_UPPER			 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
   DB	 39,0				 ;; error character = standalone accent
					 ;;
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
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP437_AC_SP_END-$		 ;; length of state section
   DB	 ACUTE_SPACE			 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
   DB	 39,0				 ;; error character = standalone accent
					 ;;
   DW	 CP437_AC_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 57,39				 ;; scan code,ASCII - SPACE
CP437_AC_SP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP437_AC_SP_END:			 ;;
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP437
;; STATE: Tilde Lower
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP437_TI_LO_END-$		 ;; length of state section
   DB	 TILDE_LOWER			 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
   DB	 126,0				 ;; error character = standalone accent
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
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_TI_UP_END-$	       ;; length of state section
   DB	 TILDE_UPPER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 126,0			       ;; error character = standalone accent
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP437
;; STATE: Diaresis Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_DI_LO_END-$	       ;; length of state section
   DB	 DIARESIS_LOWER 	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 0FEH,0 		       ;; error character = standalone accent
				       ;;
   DW	 CP437_DI_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 6			       ;; number of scans
   DB	 18,'â'                        ;; scan code,ASCII - e
   DB	 16,'Ñ'                        ;; scan code,ASCII - a
   DB	 24,'î'                        ;; scan code,ASCII - o
   DB	 22,'Å'                        ;; scan code,ASCII - u
   DB	 23,'ã'                        ;; scan code,ASCII - i
   DB	 21,'ò'                        ;; scan code,ASCII - y
CP437_DI_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP437_DI_LO_END:			       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP437
;; STATE: Diaresis Upper Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP437_DI_UP_END-$	       ;; length of state section
   DB	 DIARESIS_UPPER 	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 0FEH,0 		       ;; error character = standalone accent
				       ;;
   DW	 CP437_DI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 16,'é'                        ;; scan code,ASCII - a
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
;; CODE PAGE: CP437
;; STATE: Diaresis Space Bar
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				       ;;
;  DW	 CP437_DI_SP_END-$	       ;; length of state section
;  DB	 DIARESIS_SPACE 	       ;; State ID
;  DW	 ANY_KB 		       ;; Keyboard Type
;  DB	 0FEH,0 		       ;; error character = standalone accent
;				       ;;
;  DW	 CP437_DI_SP_T1_END-$	       ;; Size of xlat table
;  DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
;  DB	 1			       ;; number of scans
;  DB	 57,0FEH		       ;; error character = standalone accent
;CP437_DI_SP_T1_END:		       ;;
;				       ;;
;  DW	 0			       ;; Size of xlat table - null table
;CP437_DI_SP_END:		       ;; length of state section
;				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   DW	  0			       ;; LAST STATE
				       ;;
CP437_XLAT_END: 		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; BE Specific Translate Section for 850
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 PUBLIC BE_850_XLAT		       ;;
BE_850_XLAT:			       ;;
				       ;;
   DW	  CP850_XLAT_END-$	       ;; length of section
   DW	  850			       ;;
				       ;;
				       ;;
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
   DB	 -1,-1			       ;; default ignore error state
				       ;;
   DW	 CP850_NA_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 1			       ;; number of scans
   DB	 7,0F5H 		       ;; Section symbol - 
CP850_NA_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_NA_LO_END:		       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Non-Alpha Upper Case
;; KEYBOARD TYPES: G, P12
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_NA_UP_END-$	       ;; length of state section
   DB	 NON_ALPHA_UPPER	       ;; State ID
   DW	 G_KB+P12_KB		       ;; Keyboard Type
   DB	 -1,-1			       ;; default ignore error state
				       ;;
   DW	 CP850_NA_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE 	       ;; xlat options:
   DB	 1			       ;; number of scans
   DB	41,0FCH 		       ;; 3 Superscript
CP850_NA_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_NA_UP_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Third Shift
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_THIRD_END-$	       ;; length of state section
   DB	 THIRD_SHIFT		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 -1,-1			       ;; default ignore error state
				       ;;
   DW	 CP850_THIRD_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 0			       ;; number of scans
CP850_THIRD_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_THIRD_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850
;; STATE: Tilde Lower
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_TI_LO_END-$		 ;; length of state section
   DB	 TILDE_LOWER			 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
   DB	 126,0				 ;; error character = standalone accent
					 ;;
   DW	 CP850_TI_LO_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 3				 ;; number of scans
   DB	 49,164 			 ;; scan code,ASCII - n
   DB	 16,0C6H			 ;;		      a
   DB  24,0E4H			 ;;		      o
CP850_TI_LO_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP850_TI_LO_END:			 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850
;; STATE: Tilde Upper Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_TI_UP_END-$	       ;; length of state section
   DB	 TILDE_UPPER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 126,0			       ;; error character = standalone accent
				       ;;
   DW	 CP850_TI_UP_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 3			       ;; number of scans
   DB	 49,165 		       ;; scan code,ASCII - N
   DB	 16,0C7H		       ;;		    A
   DB	 24,0E5H		       ;;		    O
CP850_TI_UP_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_TI_UP_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850
;; STATE: Acute Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_AC_LO_END-$	       ;; length of state section
   DB	 ACUTE_LOWER		       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 0EFH,0 		       ;; error character = standalone accent
   DW	 CP850_AC_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 6			       ;; number of scans
   DB	 16,'†'                        ;; a acute
   DB	 18,'Ç'                        ;; e acute
   DB	 23,'°'                        ;; i acute
   DB	 24,'¢'                        ;; o acute
   DB	 22,'£'                        ;; u acute
   DB	 21,0ECH		       ;; y acute  ADDED 12/16 CNS **********
CP850_AC_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_AC_LO_END:		       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850
;; STATE: Acute Upper Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_AC_UP_END-$		 ;; length of state section
   DB	 ACUTE_UPPER			 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
   DB	 0EFH,0 			 ;; error character = standalone accent
   DW	 CP850_AC_UP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 6				 ;; number of scans
   DB	 16,0B5H			 ;;    A acute
   DB	 18,090H			 ;;    E acute
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
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_AC_SP_END-$		 ;; length of state section
   DB	 ACUTE_SPACE			 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
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
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850
;; STATE: Diaresis Lower Case
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   DW	 CP850_DI_LO_END-$	       ;; length of state section
   DB	 DIARESIS_LOWER 	       ;; State ID
   DW	 ANY_KB 		       ;; Keyboard Type
   DB	 249,0			       ;; error character = standalone accent
				       ;;
   DW	 CP850_DI_LO_T1_END-$	       ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN      ;; xlat options:
   DB	 6			       ;; number of scans
   DB	 18,'â'                        ;; scan code,ASCII - e
   DB	 16,'Ñ'                        ;; scan code,ASCII - a
   DB	 24,'î'                        ;; scan code,ASCII - o
   DB	 22,'Å'                        ;; scan code,ASCII - u
   DB	 23,'ã'                        ;; scan code,ASCII - i
   DB	 21,'ò'                        ;; scan code,ASCII - y
CP850_DI_LO_T1_END:		       ;;
				       ;;
   DW	 0			       ;; Size of xlat table - null table
				       ;;
CP850_DI_LO_END:		       ;; length of state section
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;					 ;;
;; CODE PAGE: 850
;; STATE: Diaresis Upper
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_DI_UP_END-$		 ;; length of state section
   DB	 DIARESIS_UPPER 		 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
   DB	 249,0				 ;; error character = standalone accent
					 ;;
   DW	 CP850_DI_UP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 5				 ;; number of scans
   DB	 16,8EH 			 ;;    A di
   DB	 18,0D3H			 ;;    E diaeresis
   DB	 23,0D8H			 ;;    I diaeresis
   DB	 24,99H 			 ;;    O di
   DB	 22,9AH 			 ;;    U di
CP850_DI_UP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP850_DI_UP_END:			 ;; length of state section
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: CP850
;; STATE: Diaeresis Space Bar
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_DI_SP_END-$		 ;; length of state section
   DB	 DIARESIS_SPACE 		 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
   DB	 0FEH,0 			 ;; error character = standalone accent
					 ;;
   DW	 CP850_DI_SP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 1				 ;; number of scans
   DB	 57,0F9H			 ;; scan code,ASCII - SPACE
CP850_DI_SP_T1_END:			 ;;
					 ;;
   DW	 0				 ;; Size of xlat table - null table
					 ;;
CP850_DI_SP_END:			 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CODE PAGE: 850
;; STATE: Grave Upper
;; KEYBOARD TYPES: ALL
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_GR_UP_END-$		 ;; length of state section
   DB	 GRAVE_UPPER			 ;; State ID
   DW	 ANY_KB 			 ;; Keyboard Type
   DB	 96,0				 ;; error character = standalone accent
					 ;;
   DW	 CP850_GR_UP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 5				 ;; number of scans
   DB	 16,0B7H			 ;;    A grave
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
;; KEYBOARD TYPES: All
;; TABLE TYPE: Translate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
   DW	 CP850_CI_UP_END-$		 ;; length of state section
   DB	 CIRCUMFLEX_UPPER		 ;; State ID
   DW	 ANY_KB 			 ;;
   DB	 94,0				 ;; error character = standalone accent
					 ;;
   DW	 CP850_CI_UP_T1_END-$		 ;; Size of xlat table
   DB	 STANDARD_TABLE+ZERO_SCAN	 ;; xlat options:
   DB	 5				 ;; number of scans
   DB	 16,0B6H			 ;;    A circumflex
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
;;					 ;;
     DW    0				 ;; LAST STATE
					 ;;
CP850_XLAT_END: 			 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					 ;;
CODE	 ENDS				 ;;
	 END				 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
