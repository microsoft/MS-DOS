

	PAGE	,132
	TITLE	DOS - Keyboard Definition File

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - - NLS Support - Keyboard Definition File
;; (c) Copyright 1988 Microsoft
;;
;; This the file header and table pointers ONLY.
;; The actual tables are contained in seperate source files.
;; These are:
;;	     KDFSP.ASM	- Spanish
;;	     KDFPO.ASM	- Portuguese
;;	     KDFGR.ASM	- German
;;	     KDFIT.ASM	- Italian
;;	     KDFFR.ASM	- French
;;	     KDFSG.ASM	- Swiss German
;;	     KDFSF.ASM	- Swiss French
;;	     KDFDK.ASM	- Danish
;;	     KDFUK.ASM	- English
;;	     KDFBE.ASM	- Belgium
;;	     KDFNL.ASM	- Netherlands
;;	     KDFNO.ASM	- Norway
;;	     KDFLA.ASM	- Latin American
;;	     KDFSV.ASM	- SWEDEN
;;	     KDFSU.ASM	- Finland
;;	     Dummy US	- US
;; Linkage Instructions:
;;	The following instructions are contained in KDFLINK.BAT:
;;
;;	LINK KDF+KDFSP+KDFGE+KDFFR+KDFIT+KDFPO+KDFUK+KDFSG+KDFDK+KDFEOF;
;;	EXE2BIN KDF.EXE KEYBOARD.SYS
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
CODE	SEGMENT PUBLIC 'CODE'          ;;
	ASSUME CS:CODE,DS:CODE	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; File Header
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
DB   0FFh,'KEYB   '                  ;; signature
DB   8 DUP(0)			     ;; reserved
DW   650			     ;; maximum size of Common Xlat Sect
DW   350			     ;; max size of Specific Xlat Sect
DW   400			     ;; max size of State Logic
DD   0				     ;; reserved
DW   17 			     ;; number of languages
DB   'SP'
DW   OFFSET SP_LANG_ENT,0
DB   'PO'
DW   OFFSET PO_LANG_ENT,0
DB   'FR'
DW   OFFSET FR_LANG_ENT,0
DB   'DK'
DW   OFFSET DK_LANG_ENT,0
DB   'SG'
DW   OFFSET SG_LANG_ENT,0
DB   'GR'
DW   OFFSET GE_LANG_ENT,0
DB   'IT'
DW   OFFSET IT_LANG_ENT,0
DB   'UK'
DW   OFFSET UK_LANG_ENT,0
DB   'SF'
DW   OFFSET SF_LANG_ENT,0
DB   'BE'
DW   OFFSET BE_LANG_ENT,0
DB   'NL'
DW   OFFSET NL_LANG_ENT,0
DB   'NO'
DW   OFFSET NO_LANG_ENT,0
DB   'CF'
DW   OFFSET CF_LANG_ENT,0
DB   'SV'
DW   OFFSET SV_LANG_ENT,0
DB   'SU'
DW   OFFSET SV_LANG_ENT,0
DB   'LA'
DW   OFFSET LA_LANG_ENT,0
DB   'US'
DW   OFFSET DUMMY_ENT,0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; Language Entries
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
   EXTRN SP_LOGIC:NEAR		       ;;
   EXTRN SP_437_XLAT:NEAR	       ;;
   EXTRN SP_850_XLAT:NEAR	       ;;
				       ;;
SP_LANG_ENT:			       ;; language entry for SPANISH
  DB   'SP'                            ;;
  DW   0			       ;; reserved
  DW   OFFSET SP_LOGIC,0	       ;; pointer to LANG kb table
  DW   2			       ;; number of code pages
  DW   437			       ;; code page
  DW   OFFSET SP_437_XLAT,0	       ;; table pointer
  DW   850			       ;; code page
  DW   OFFSET SP_850_XLAT,0	       ;; table pointer
				       ;;
;****************************************************************************
   EXTRN PO_LOGIC:NEAR		       ;;
   EXTRN PO_860_XLAT:NEAR	       ;;
   EXTRN PO_850_XLAT:NEAR	       ;;
				       ;;
PO_LANG_ENT:			       ;; language entry for POTUGAL
  DB   'PO'                            ;;
  DW   0			       ;; reserved
  DW   OFFSET PO_LOGIC,0	       ;; pointer to LANG kb table
  DW   2			       ;; number of code pages
  DW   860			       ;; code page
  DW   OFFSET PO_860_XLAT,0	       ;; table pointer
  DW   850			       ;; code page
  DW   OFFSET PO_850_XLAT,0	       ;; table pointer
				       ;;
;*****************************************************************************
    EXTRN FR_LOGIC:NEAR 		;;
    EXTRN FR_437_XLAT:NEAR		;;
    EXTRN FR_850_XLAT:NEAR		;;
					;;
 FR_LANG_ENT:				;; language entry for POTUGAL
   DB	'FR'                            ;;
   DW	0				;; reserved
   DW	OFFSET FR_LOGIC,0		;; pointer to LANG kb table
   DW	2				;; number of code pages
   DW	437				;; code page
   DW	OFFSET FR_437_XLAT,0		;; table pointer
   DW	850				;; code page
   DW	OFFSET FR_850_XLAT,0		;; table pointer
					;;
;*****************************************************************************
   EXTRN DK_LOGIC:NEAR		       ;;
   EXTRN DK_865_XLAT:NEAR	       ;;
   EXTRN DK_850_XLAT:NEAR	       ;;
					;;
 DK_LANG_ENT:				;; language entry for POTUGAL
   DB	'DK'                            ;;
   DW	0				;; reserved
   DW	OFFSET DK_LOGIC,0		;; pointer to LANG kb table
   DW	2				;; number of code pages
   DW	865				;; code page
   DW	OFFSET DK_865_XLAT,0		;; table pointer
   DW	850				;; code page
   DW	OFFSET DK_850_XLAT,0		;; table pointer
					;;
;*****************************************************************************
   EXTRN SG_LOGIC:NEAR		       ;;
   EXTRN SG_437_XLAT:NEAR	       ;;
   EXTRN SG_850_XLAT:NEAR	       ;;
				       ;;
SG_LANG_ENT:			       ;; language entry for POTUGAL
  DB   'SG'                            ;;
  DW   0			       ;; reserved
  DW   OFFSET SG_LOGIC,0	       ;; pointer to LANG kb table
  DW   2			       ;; number of code pages
  DW   437			       ;; code page
  DW   OFFSET SG_437_XLAT,0	       ;; table pointer
  DW   850			       ;; code page
  DW   OFFSET SG_850_XLAT,0	       ;; table pointer
				       ;;
;*****************************************************************************
   EXTRN SF_LOGIC:NEAR		       ;;
   EXTRN SF_437_XLAT:NEAR	       ;;
   EXTRN SF_850_XLAT:NEAR	       ;;
				       ;;
SF_LANG_ENT:			       ;; language entry for SWISS FRENCH
  DB   'SF'                            ;;
  DW   0			       ;; reserved
  DW   OFFSET SF_LOGIC,0	       ;; pointer to LANG kb table
  DW   2			       ;; number of code pages
  DW   437			       ;; code page
  DW   OFFSET SF_437_XLAT,0	       ;; table pointer
  DW   850			       ;; code page
  DW   OFFSET SF_850_XLAT,0	       ;; table pointer
				       ;;
;*****************************************************************************
   EXTRN GE_LOGIC:NEAR		       ;;
   EXTRN GE_437_XLAT:NEAR	       ;;
   EXTRN GE_850_XLAT:NEAR	       ;;
				       ;;
GE_LANG_ENT:			       ;; language entry for POTUGAL
  DB   'GR'                            ;;
  DW   0			       ;; reserved
  DW   OFFSET GE_LOGIC,0	       ;; pointer to LANG kb table
  DW   2			       ;; number of code pages
  DW   437			       ;; code page
  DW   OFFSET GE_437_XLAT,0	       ;; table pointer
  DW   850			       ;; code page
  DW   OFFSET GE_850_XLAT,0	       ;; table pointer
				       ;;
;*****************************************************************************
    EXTRN IT_LOGIC:NEAR 		;;
    EXTRN IT_437_XLAT:NEAR		;;
    EXTRN IT_850_XLAT:NEAR		;;
					;;
 IT_LANG_ENT:				;; language entry for POTUGAL
   DB	'IT'                            ;;
   DW	0				;; reserved
   DW	OFFSET IT_LOGIC,0		;; pointer to LANG kb table
   DW	2				;; number of code pages
   DW	437				;; code page
   DW	OFFSET IT_437_XLAT,0		;; table pointer
   DW	850				;; code page
   DW	OFFSET IT_850_XLAT,0		;; table pointer
					;;
;*****************************************************************************
    EXTRN UK_LOGIC:FAR			;;
    EXTRN UK_437_XLAT:FAR		;;
    EXTRN UK_850_XLAT:FAR		;;
					;;
 UK_LANG_ENT:				;; language entry for POTUGAL
   DB	'UK'                            ;;
   DW	0				;; reserved
   DW	OFFSET UK_LOGIC,0		;; pointer to LANG kb table
   DW	2				;; number of code pages
   DW	437				;; code page
   DW	OFFSET UK_437_XLAT,0		;; table pointer
   DW	850				;; code page
   DW	OFFSET UK_850_XLAT,0		;; table pointer
					;;
;*****************************************************************************
   EXTRN BE_LOGIC:NEAR		       ;;
   EXTRN BE_437_XLAT:NEAR	       ;;
   EXTRN BE_850_XLAT:NEAR	       ;;
				       ;;
BE_LANG_ENT:			       ;; language entry for POTUGAL
  DB   'BE'                            ;;
  DW   0			       ;; reserved
  DW   OFFSET BE_LOGIC,0	       ;; pointer to LANG kb table
  DW   2			       ;; number of code pages
  DW   437			       ;; code page
  DW   OFFSET BE_437_XLAT,0	       ;; table pointer
  DW   850			       ;; code page
  DW   OFFSET BE_850_XLAT,0	       ;; table pointer
					;;
;*****************************************************************************
;*****************************************************************************
     EXTRN NL_LOGIC:NEAR		 ;;
     EXTRN NL_437_XLAT:NEAR		 ;;
     EXTRN NL_850_XLAT:NEAR		 ;;
					 ;;
  NL_LANG_ENT:				 ;; language entry for NETHERLANDS
    DB	 'NL'                            ;;
    DW	 0				 ;; reserved
    DW	 OFFSET NL_LOGIC,0		 ;; pointer to LANG kb table
    DW	 2				 ;; number of code pages
    DW	 437				 ;; code page
    DW	 OFFSET NL_437_XLAT,0		 ;; table pointer
    DW	 850				 ;; code page
    DW	 OFFSET NL_850_XLAT,0		 ;; table pointer
				     ;;
;*****************************************************************************
;*****************************************************************************
     EXTRN NO_LOGIC:NEAR		 ;;
     EXTRN NO_865_XLAT:NEAR		 ;;
     EXTRN NO_850_XLAT:NEAR		 ;;
					 ;;
  NO_LANG_ENT:				 ;; language entry for NORWAY
    DB	 'NO'                            ;;
    DW	 0				 ;; reserved
    DW	 OFFSET NO_LOGIC,0		 ;; pointer to LANG kb table
    DW	 2				 ;; number of code pages
    DW	 865				 ;; code page
    DW	 OFFSET NO_865_XLAT,0		 ;; table pointer
    DW	 850				 ;; code page
    DW	 OFFSET NO_850_XLAT,0		 ;; table pointer
				     ;;
;*****************************************************************************
;*****************************************************************************
     EXTRN SV_LOGIC:NEAR		 ;;
     EXTRN SV_437_XLAT:NEAR		 ;;
     EXTRN SV_850_XLAT:NEAR		 ;;
					 ;;
  SV_LANG_ENT:				 ;; language entry for SWEDEN
    DB	 'SV'                            ;;
    DW	 0				 ;; reserved
    DW	 OFFSET SV_LOGIC,0		 ;; pointer to LANG kb table
    DW	 2				 ;; number of code pages
    DW	 437				 ;; code page
    DW	 OFFSET SV_437_XLAT,0		 ;; table pointer
    DW	 850				 ;; code page
    DW	 OFFSET SV_850_XLAT,0		 ;; table pointer
				     ;;
;*****************************************************************************
;*****************************************************************************
;    EXTRN SU_LOGIC:NEAR		 ;;
;    EXTRN SU_437_XLAT:NEAR		 ;;
;    EXTRN SU_850_XLAT:NEAR		 ;;
;					 ;;
; SU_LANG_ENT:				 ;; language entry for FINLAND
;   DB	 'SU'                            ;;
;   DW	 0				 ;; reserved
;   DW	 OFFSET SU_LOGIC,0		 ;; pointer to LANG kb table
;   DW	 2				 ;; number of code pages
;   DW	 437				 ;; code page
;   DW	 OFFSET SU_437_XLAT,0		 ;; table pointer
;   DW	 850				 ;; code page
;   DW	 OFFSET SU_850_XLAT,0		 ;; table pointer
;				     ;;
;*****************************************************************************
;*****************************************************************************
     EXTRN CF_LOGIC:NEAR		 ;;
     EXTRN CF_863_XLAT:NEAR		 ;;
     EXTRN CF_850_XLAT:NEAR		 ;;
					 ;;
  CF_LANG_ENT:				 ;; language entry for Canadian-French
    DB	 'CF'                            ;;
    DW	 0				 ;; reserved
    DW	 OFFSET CF_LOGIC,0		 ;; pointer to LANG kb table
    DW	 2				 ;; number of code pages
    DW	 863				 ;; code page
    DW	 OFFSET CF_863_XLAT,0		 ;; table pointer
    DW	 850				 ;; code page
    DW	 OFFSET CF_850_XLAT,0		 ;; table pointer
				     ;;
;*****************************************************************************
     EXTRN LA_LOGIC:NEAR		 ;;
     EXTRN LA_850_XLAT:NEAR		 ;;
     EXTRN LA_437_XLAT:NEAR		 ;;
					 ;;
  LA_LANG_ENT:				 ;; language entry for Canadian-French
    DB	 'LA'                            ;;
    DW	 0				 ;; reserved
    DW	 OFFSET LA_LOGIC,0		 ;; pointer to LANG kb table
    DW	 2				 ;; number of code pages
    DW	 850				 ;; code page
    DW	 OFFSET LA_850_XLAT,0		 ;; table pointer
    DW	 437				 ;; code page
    DW	 OFFSET LA_437_XLAT,0		 ;; table pointer
				     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
DUMMY_ENT:			       ;; language entry
  DB   'XX'                            ;;
  DW   0			       ;; reserved
  DW   OFFSET DUMMY_LOGIC,0	       ;; pointer to LANG kb table
  DW   5			       ;; number of code pages
  DW   437			       ;; code page
  DW   OFFSET DUMMY_XLAT_437,0	       ;; table pointer
  DW   850			       ;; code page
  DW   OFFSET DUMMY_XLAT_850,0	       ;; table pointer
  DW   860			       ;; code page
  DW   OFFSET DUMMY_XLAT_860,0	       ;; table pointer
  DW   863			       ;; code page
  DW   OFFSET DUMMY_XLAT_863,0	       ;; table pointer
  DW   865			       ;; code page
  DW   OFFSET DUMMY_XLAT_865,0	       ;; table pointer
				       ;;
DUMMY_LOGIC:			       ;;
   DW  LOGIC_END-$		       ;; length
   DW  0			       ;; special features
   DB  92H,0,0			       ;; EXIT_STATE_LOGIC_COMMAND
LOGIC_END:			       ;;
				       ;;
DUMMY_XLAT_437: 		       ;;
   DW	  6			       ;; length of section
   DW	  437			       ;; code page
   DW	  0			       ;; LAST STATE
				       ;;
DUMMY_XLAT_850: 		       ;;
   DW	  6			       ;; length of section
   DW	  850			       ;; code page
   DW	  0			       ;; LAST STATE
				       ;;
DUMMY_XLAT_860: 		       ;;
   DW	  6			       ;; length of section
   DW	  860			       ;; code page
   DW	  0			       ;; LAST STATE
				       ;;
DUMMY_XLAT_865: 		       ;;
   DW	  6			       ;; length of section
   DW	  865			       ;; code page
   DW	  0			       ;; LAST STATE
				       ;;
DUMMY_XLAT_863: 		       ;;
   DW	  6			       ;; length of section
   DW	  863			       ;; code page
   DW	  0			       ;; LAST STATE
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*****************************************************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
CODE	 ENDS			       ;;
	 END			       ;;
