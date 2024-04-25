

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
;;	     KDFIT142.ASM  - Italian
;;	     KDFIT.ASM	- Italian
;;	     KDFFR189.ASM  - French
;;	     KDFFR.ASM	- French
;;	     KDFSG.ASM	- Swiss German
;;	     KDFSF.ASM	- Swiss French
;;	     KDFDK.ASM	- Danish
;;	     KDFUK168.ASM  - English
;;	     KDFUK.ASM	- English
;;	     KDFBE.ASM	- Belgium
;;	     KDFNL.ASM	- Netherlands
;;	     KDFNO.ASM	- Norway
;;	     KDFLA.ASM	- Latin American
;;	     KDFSV.ASM	- SWEDEN   -----> This moddule is used for both Sweden
;;					  and Finland - exact same template
;;	     KDFSU.ASM	- Finland  -----> Same module as Sweden eliminated
;;	     Dummy US	- US
;; Linkage Instructions:
;;	The following instructions are contained in KDFLINK.BAT:
;;
;;	LINK KDF+KDFSP+KDFGE+KDFFR+KDFIT+KDFPO+KDFUK+KDFSG+KDFDK+KDFEOF;
;;	EXE2BIN KDF.EXE KEYBOARD.SYS
;;
;; DCL, March 8, 1988 - swapped 437/850 to 850/437 for SG & SF
;; DCL, March 8, 1988 - uncommented SU(finland)& swapped 437/850 to 850/437
;;			   as the Finnish want 850/437 vs. 437/850 for Sweden
;;			   did not alter the pointer to kbid 153 to Sweden
;; CNS	   April 14 1988 - swapped 437/850 to 850/437 for SP & LA
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
DW   0				     ;;AC000;reserved
DW   19 			     ;;AC000 number of IDs
DW   17 			     ;;AC000 number of languages
DB   'GR'                            ;; LANGUAGE CODE TABLE
DW   OFFSET GE_LANG_ENT,0	     ;;
DB   'SP'                            ;;
DW   OFFSET SP_LANG_ENT,0	     ;;
DB   'PO'                            ;;
DW   OFFSET PO_LANG_ENT,0	     ;;
DB   'FR'                            ;;
DW   OFFSET FR2_LANG_ENT,0	     ;;
DB   'DK'                            ;;
DW   OFFSET DK_LANG_ENT,0	     ;;
DB   'SG'                            ;;
DW   OFFSET SG_LANG_ENT,0	     ;;
DB   'IT'                            ;;
DW   OFFSET IT2_LANG_ENT,0	     ;;
DB   'UK'                            ;;
DW   OFFSET UK2_LANG_ENT,0	     ;;
DB   'SF'                            ;;
DW   OFFSET SF_LANG_ENT,0	     ;;
DB   'BE'                            ;;
DW   OFFSET BE_LANG_ENT,0	     ;;
DB   'NL'                            ;;
DW   OFFSET NL_LANG_ENT,0	     ;;
DB   'NO'                            ;;
DW   OFFSET NO_LANG_ENT,0	     ;;
DB   'CF'                            ;;
DW   OFFSET CF_LANG_ENT,0	     ;;
DB   'SV'                            ;;
DW   OFFSET SV_LANG_ENT,0	     ;;
DB   'SU'                            ;;
DW   OFFSET Su_LANG_ENT,0	     ;;
DB   'LA'                            ;;
DW   OFFSET LA_LANG_ENT,0	     ;;
DB   'US'                            ;;
DW   OFFSET DUMMY_ENT,0 	     ;;
DW    172			     ;;AN000;ID CODE TABLE ***************************
DW   OFFSET SP_LANG_ENT,0	     ;;AN000;
DW    163			     ;;AN000;
DW   OFFSET PO_LANG_ENT,0	     ;;AN000;
DW    120			     ;;AN000;
DW   OFFSET FR1_LANG_ENT,0	     ;;AN000;
DW    189			     ;;AN000;
DW   OFFSET FR2_LANG_ENT,0	     ;;AN000;
DW    159			     ;;AN000;
DW   OFFSET DK_LANG_ENT,0	     ;;AN000;
DW    000			     ;;AN000;
DW   OFFSET SG_LANG_ENT,0	     ;;AN000;
DW    129			     ;;AN000;
DW   OFFSET GE_LANG_ENT,0	     ;;AN000;
DW    142			     ;;AN000;
DW   OFFSET IT1_LANG_ENT,0	     ;;AN000;
DW    141			     ;;AN000;
DW   OFFSET IT2_LANG_ENT,0	     ;;AN000;
DW    168			     ;;AN000;
DW   OFFSET UK1_LANG_ENT,0	     ;;AN000;
DW    166			     ;;AN000;
DW   OFFSET UK2_LANG_ENT,0	     ;;AN000;
DW    150			     ;;AN000;
DW   OFFSET SF_LANG_ENT,0	     ;;AN000;
DW    120			     ;;AN000;
DW   OFFSET BE_LANG_ENT,0	     ;;AN000;
DW    143			     ;;AN000;
DW   OFFSET NL_LANG_ENT,0	     ;;AN000;
DW    155			     ;;AN000;
DW   OFFSET NO_LANG_ENT,0	     ;;AN000;
DW    058			     ;;AN000;
DW   OFFSET CF_LANG_ENT,0	     ;;AN000;
DW    153			     ;;AN000;
DW   OFFSET SV_LANG_ENT,0	     ;;AN000;
DW    171			     ;;AN000;
DW   OFFSET LA_LANG_ENT,0	     ;;AN000;
DW    103			     ;;AN000;
DW   OFFSET DUMMY_ENT,0 	     ;;AN000;
;				     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
  DW   172			       ;; AN000;ID entry  (ID CODE)
  DW   OFFSET SP_LOGIC,0	       ;; pointer to LANG kb table
  DB   1			       ;; AN000;number of IDs
  DB   2			       ;; number of code pages
  DW   850			       ;; code page
  DW   OFFSET SP_850_XLAT,0	       ;; table pointer
  DW   437			       ;; code page
  DW   OFFSET SP_437_XLAT,0	       ;; table pointer
				       ;;
;*****************************************************************************
    EXTRN FR1_LOGIC:NEAR		 ;;AN000;
    EXTRN FR1_437_XLAT:NEAR		 ;;AN000;
    EXTRN FR1_850_XLAT:NEAR		 ;;AN000;
					 ;;
 FR1_LANG_ENT:				 ;;AN000; language entry for FRANCE
   DB	'FR'                             ;;AN000; SECONDARY KEYBOARD ID VALUE
   DW	120				 ;;AN000; ID entry
   DW	OFFSET FR1_LOGIC,0		 ;;AN000; pointer to LANG kb table
   DB	2				 ;;AN000; number of code pages
   DB	2				 ;;AN000; number of ids
   DW	437				 ;;AN000; code page
   DW	OFFSET FR1_437_XLAT,0		 ;;AN000; table pointer
   DW	850				 ;;AN000; code page
   DW	OFFSET FR1_850_XLAT,0		 ;;AN000; table pointer
					 ;;AN000;
;*****************************************************************************
    EXTRN FR2_LOGIC:NEAR		 ;;AC000;
    EXTRN FR2_437_XLAT:NEAR		 ;;AC000;
    EXTRN FR2_850_XLAT:NEAR		 ;;AC000;
					 ;;
 FR2_LANG_ENT:				 ;; language entry for FRANCE
   DB	'FR'                             ;; PRIMARY  KEYBOARD ID VALUE
   DW	189				 ;;AC000; ID entry
   DW	OFFSET FR2_LOGIC,0		 ;;AC000; pointer to LANG kb table
   DB	1				 ;;AC000; number of ids
   DB	2				 ;;AC000; number of code pages
   DW	437				 ;;AC000; code page
   DW	OFFSET FR2_437_XLAT,0		 ;;AC000; table pointer
   DW	850				 ;;AC000; code page
   DW	OFFSET FR2_850_XLAT,0		 ;;AC000; table pointer
					 ;;
;****************************************************************************
   EXTRN PO_LOGIC:NEAR			 ;;AC000;
   EXTRN PO_850_XLAT:NEAR		 ;;AC000;
   EXTRN PO_860_XLAT:NEAR		 ;;AC000;
					 ;;
PO_LANG_ENT:				 ;; language entry for PORTUGAL
  DB   'PO'                              ;;
  DW   163				 ;;AN000; ID entry
  DW   OFFSET PO_LOGIC,0		 ;; pointer to LANG kb table
  DB   1				 ;;AC000; number of ids
  DB   2				 ;;AC000; number of code pages
  DW   850				 ;;AC000; code page
  DW   OFFSET PO_850_XLAT,0		 ;;AC000; table pointer
  DW   860				 ;;AC000; code page
  DW   OFFSET PO_860_XLAT,0		 ;;AC000; table pointer
					 ;;
;*****************************************************************************
   EXTRN DK_LOGIC:NEAR			 ;;
   EXTRN DK_850_XLAT:NEAR		 ;;AC000;
   EXTRN DK_865_XLAT:NEAR		 ;;AC000;
					 ;;
 DK_LANG_ENT:				 ;; language entry for DENMARK
   DB	'DK'                             ;;
   DW	159				 ;;AN000; ID entry
   DW	OFFSET DK_LOGIC,0		 ;; pointer to LANG kb table
   DB	1				 ;;AN000;number of ids
   DB	2				 ;;AC000; number of code pages
   DW	850				 ;;AC000; code page
   DW	OFFSET DK_850_XLAT,0		 ;;AC000; table pointer
   DW	865				 ;;AC000; code page
   DW	OFFSET DK_865_XLAT,0		 ;;AC000; table pointer
					 ;;
;*****************************************************************************
   EXTRN SG_LOGIC:NEAR			 ;;
   EXTRN SG_850_XLAT:NEAR		 ;;
   EXTRN SG_437_XLAT:NEAR		 ;;
					 ;;
SG_LANG_ENT:				 ;; language entry for SWISS GERMAN
  DB   'SG'                              ;;
  DW   000				 ;;AN001; ID entry
  DW   OFFSET SG_LOGIC,0		 ;; pointer to LANG kb table
  DB   1				 ;;AN000; number of ids
  DB   2				 ;;AC000; number of code pages
  DW   850				 ;; code page ;;;dcl 850 now default March 8, 1988
  DW   OFFSET SG_850_XLAT,0		 ;; table pointer
  DW   437				 ;; code page
  DW   OFFSET SG_437_XLAT,0		 ;; table pointer
					 ;;
;*****************************************************************************
   EXTRN SF_LOGIC:NEAR			 ;;
   EXTRN SF_850_XLAT:NEAR		 ;;
   EXTRN SF_437_XLAT:NEAR		 ;;
					 ;;
SF_LANG_ENT:				 ;; language entry for SWISS FRENCH
  DB   'SF'                              ;;
  DW   150				 ;;AN000; ID entry
  DW   OFFSET SF_LOGIC,0		 ;; pointer to LANG kb table
  DB   1			       ;;AN000; number of ids
  DB   2				 ;;AC000; number of code pages
  DW   850				 ;; code page ;;;dcl 850 now default March 8, 1988
  DW   OFFSET SF_850_XLAT,0		 ;; table pointer
  DW   437				 ;; code page
  DW   OFFSET SF_437_XLAT,0		 ;; table pointer
					 ;;
;*****************************************************************************
   EXTRN GE_LOGIC:NEAR			 ;;
   EXTRN GE_437_XLAT:NEAR		 ;;
   EXTRN GE_850_XLAT:NEAR		 ;;
					 ;;
GE_LANG_ENT:				 ;; language entry for GERMANY
  DB   'GR'                              ;;
  DW   129				 ;;AN000; ID entry
  DW   OFFSET GE_LOGIC,0		 ;; pointer to LANG kb table
  DB   1			       ;;AN000; number of ids
  DB   2				 ;;AC000; number of code pages
  DW   437				 ;; code page
  DW   OFFSET GE_437_XLAT,0		 ;; table pointer
  DW   850				 ;; code page
  DW   OFFSET GE_850_XLAT,0		 ;; table pointer
					 ;;
;*****************************************************************************
    EXTRN IT1_LOGIC:NEAR		 ;;AN000;
    EXTRN IT1_437_XLAT:NEAR		 ;;AN000;
    EXTRN IT1_850_XLAT:NEAR		 ;;AN000;
					 ;;
 IT1_LANG_ENT:				 ;;AN000; language entry for ITALY
   DB	'IT'                             ;;AN000; SECONDARY KEYBOARD ID VALUE
   DW	142				 ;;AN000; ID entry
   DW	OFFSET IT1_LOGIC,0		 ;;AN000; pointer to LANG kb table
   DB	2				 ;;AN000;number of ids
   DB	2				 ;;AN000; number of code pages
   DW	437				 ;;AN000; code page
   DW	OFFSET IT1_437_XLAT,0		 ;;AN000; table pointer
   DW	850				 ;;AN000; code page
   DW	OFFSET IT1_850_XLAT,0		 ;;AN000; table pointer
					 ;;
;*****************************************************************************
    EXTRN IT2_LOGIC:NEAR		 ;;
    EXTRN IT2_437_XLAT:NEAR		 ;;
    EXTRN IT2_850_XLAT:NEAR		 ;;
					 ;;
 IT2_LANG_ENT:				 ;;AC000; language entry for ITALY
   DB	'IT'                             ;;AC000;  PRIMARY KEYBOARD ID VALUE
   DW	141				 ;;AN000; ID entry
   DW	OFFSET IT2_LOGIC,0		 ;;AN000; pointer to LANG kb table
   DB	1				;;AC000; number of ids
   DB	2				 ;;AC000; number of code pages
   DW	437				 ;;AC000; code page
   DW	OFFSET IT2_437_XLAT,0		 ;;AC000; table pointer
   DW	850				 ;;AC000; code page
   DW	OFFSET IT2_850_XLAT,0		 ;;AC000; table pointer
					 ;;
;*****************************************************************************
    EXTRN UK1_LOGIC:FAR 		 ;;AN000;
    EXTRN UK1_437_XLAT:FAR		 ;;AN000;
    EXTRN UK1_850_XLAT:FAR		 ;;AN000;
					 ;;
 UK1_LANG_ENT:				 ;;AN000; language entry for UNITED KINGDOM
   DB	'UK'                             ;;AN000; SECONDARY KEYBOARD ID VALUE
   DW	168				 ;;AN000; ID entry
   DW	OFFSET UK1_LOGIC,0		 ;;AN000; pointer to LANG kb table
   DB	2				;;AN000; number of ids
   DB	2				 ;;AN000; number of code pages
   DW	437				 ;;AN000; code page
   DW	OFFSET UK1_437_XLAT,0		 ;;AN000; table pointer
   DW	850				 ;;AN000; code page
   DW	OFFSET UK1_850_XLAT,0		 ;;AN000; table pointer
					 ;;
;*****************************************************************************
    EXTRN UK2_LOGIC:FAR 		 ;;AC000;
    EXTRN UK2_437_XLAT:FAR		 ;;AC000;
    EXTRN UK2_850_XLAT:FAR		 ;;AC000;
					 ;;
 UK2_LANG_ENT:				 ;;AN000; language entry for UNITED KINGDOM
   DB	'UK'                             ;;AC000; PRIMARY KEYBOARD ID VALUE
   DW	166				 ;;AC000; ID entry
   DW	OFFSET UK2_LOGIC,0		 ;;AC000; pointer to LANG kb table
   DB	1				;; AN000;number of ids
   DB	2				 ;;AN000; number of code pages
   DW	437				 ;;AC000; code page
   DW	OFFSET UK2_437_XLAT,0		 ;;AC000; table pointer
   DW	850				 ;;AC000; code page
   DW	OFFSET UK2_850_XLAT,0		 ;;AC000; table pointer
					 ;;
;*****************************************************************************
   EXTRN BE_LOGIC:NEAR			 ;;
   EXTRN BE_437_XLAT:NEAR		 ;;
   EXTRN BE_850_XLAT:NEAR		 ;;
					 ;;
BE_LANG_ENT:				 ;; language entry for BELGIUM
  DB   'BE'                              ;;
  DW   120				 ;;AN000; ID entry
  DW   OFFSET BE_LOGIC,0		 ;; pointer to LANG kb table
  DB   1				 ;;AN000; number of ids
  DB   2				 ;;AN000; number of code pages
  DW   850				 ;; code page ;; default to 850 - same as country.sys
  DW   OFFSET BE_850_XLAT,0		 ;; table pointer
  DW   437				 ;; code page
  DW   OFFSET BE_437_XLAT,0		 ;; table pointer
					 ;;
;*****************************************************************************
;*****************************************************************************
     EXTRN NL_LOGIC:NEAR		 ;;
     EXTRN NL_437_XLAT:NEAR		 ;;
     EXTRN NL_850_XLAT:NEAR		 ;;
					 ;;
  NL_LANG_ENT:				 ;; language entry for NETHERLANDS
    DB	 'NL'                            ;;
    DW	 143				 ;;AN000; ID entry
    DW	 OFFSET NL_LOGIC,0		 ;; pointer to LANG kb table
    DB	 1				 ;;AN000; number of ids
    DB	 2				 ;;AN000; number of code pages
    DW	 437				 ;; code page
    DW	 OFFSET NL_437_XLAT,0		 ;; table pointer
    DW	 850				 ;; code page
    DW	 OFFSET NL_850_XLAT,0		 ;; table pointer
					 ;;
;*****************************************************************************
;*****************************************************************************
     EXTRN NO_LOGIC:NEAR		 ;;
     EXTRN NO_850_XLAT:NEAR		 ;;AC000;
     EXTRN NO_865_XLAT:NEAR		 ;;AC000;
					 ;;
  NO_LANG_ENT:				 ;; language entry for NORWAY
    DB	 'NO'                            ;;
    DW	 155				 ;;AN000; ID entry
    DW	 OFFSET NO_LOGIC,0		 ;; pointer to LANG kb table
    DB	 1				 ;;AN000; number of ids
    DB	 2				 ;;AN000; number of code pages
    DW	 850				 ;;AC000; code page
    DW	 OFFSET NO_850_XLAT,0		 ;;AC000; table pointer
    DW	 865				 ;;AC000; code page
    DW	 OFFSET NO_865_XLAT,0		 ;;AC000; table pointer
					 ;;
;*****************************************************************************
;*****************************************************************************
     EXTRN SV_LOGIC:NEAR		 ;;
     EXTRN SV_437_XLAT:NEAR		 ;;
     EXTRN SV_850_XLAT:NEAR		 ;;
					 ;;
  SV_LANG_ENT:				 ;; language entry for SWEDEN
    DB	 'SV'                            ;;
    DW	 153				 ;;AN000; ID entry
    DW	 OFFSET SV_LOGIC,0		 ;; pointer to LANG kb table
    DB	 1				 ;;AN000; number of ids
    DB	 2				 ;;AN000; number of code pages
    DW	 437				 ;; code page
    DW	 OFFSET SV_437_XLAT,0		 ;; table pointer
    DW	 850				 ;; code page
    DW	 OFFSET SV_850_XLAT,0		 ;; table pointer
					 ;;
;*****************************************************************************
;*****************************************************************************
;;  Already declared external above
;;  EXTRN Sv_LOGIC:NEAR 		;; Finland & Sweden have same layout,
;;  EXTRN Sv_437_XLAT:NEAR		;; but different code page defaults,
;;  EXTRN Sv_850_XLAT:NEAR		;; use Sweden data for Finland
					;;
 SU_LANG_ENT:				;; language entry for FINLAND
   DB	'SU'                            ;;
   DW	153				;; ID entry
   DW	OFFSET Sv_LOGIC,0		;; pointer to LANG kb table
   DB	1				;; number of ids
   DB	2				;; number of code pages
   DW	850				;; code page  ;;;dcl 850 now default, March 8, 1988
   DW	OFFSET Sv_850_XLAT,0		;; table pointer
   DW	437				;; code page
   DW	OFFSET Sv_437_XLAT,0		;; table pointer
					;;
;*****************************************************************************
;*****************************************************************************
     EXTRN CF_LOGIC:NEAR		 ;;
     EXTRN CF_863_XLAT:NEAR		 ;;
     EXTRN CF_850_XLAT:NEAR		 ;;
					 ;;
  CF_LANG_ENT:				 ;; language entry for Canadian-French
    DB	 'CF'                            ;;
    DW	 058				 ;; ID entry
    DW	 OFFSET CF_LOGIC,0		 ;; pointer to LANG kb table
    DB	 1				 ;; number of ids
    DB	 2				 ;; number of code pages
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
  LA_LANG_ENT:				 ;; language entry for LATIN AMERICAN
    DB	 'LA'                            ;;
    DW	 171				 ;;AN000; ID entry
    DW	 OFFSET LA_LOGIC,0		 ;; pointer to LANG kb table
    DB	 1				 ;;AN000; number of ids
    DB	 2				 ;;AN000; number of code pages
    DW	 850				 ;; code page
    DW	 OFFSET LA_850_XLAT,0		 ;; table pointer
    DW	 437				 ;; code page  ; default to 437 -same as country.sys
    DW	 OFFSET LA_437_XLAT,0		 ;; table pointer
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
DUMMY_ENT:			       ;; language entry
  DB   'XX'                            ;;
  DW   103			       ;;AC000; ID entry
  DW   OFFSET DUMMY_LOGIC,0	       ;; pointer to LANG kb table
  DB   1			       ;;AC000; number of ids
  DB   5			       ;;AC000; number of code pages
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
