
	PAGE	,132

IF1
	%OUT .		     ®F-PARSER.SRC¯
ENDIF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  FILENAME:	  CPS Device Driver -- Font Parser
;;  MODULE NAME:  CPSFONT
;;  TYPE:	  Font Parser Module
;;  LINK PROCEDURE:	Link CPSPMnn+CPSFONTn+PTRMSGn+CPSPInn into .EXE format.
;;			CPSPM must be first.  CPSPInn must be last.  Everything
;;			before CPSPInn will be resident.
;;  INCLUDE FILES:
;;			CPSPEQU.INC
;;  Remarks :
;;
;;	changes are made in stages : PTRSELLO, PTRSELHI, PTRLENLO, PTRLENHI
;;	as for Display-type of DEVICE_ID, there will be no printer-type of
;;	of DEVICE_TYPE. And these four stages are for the DEVICE_TYPE with
;;	the value of printer-type.
;;
;;	(most codes in the four stages are masked out as comments than real
;;	 codes to save spaces. Also mask out lines that contain the
;;	 following varaibles :
;;		--	PTR_SEL_WORD
;;		--	PTR_SELOB
;;		--	PTR_SEHIB
;;		--	PTR_LEN_WORD
;;		--	PTR_LNLOB
;;		--	PTR_LNHIB
;;		--	PRE_FONT_P0
;;		--	PRE_FONT_P
;;		--	FTB_SELECT
;;		--	FTB_SELLEN
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
;INCLUDE CPSPEQU.INC			 ;;
					;;
STAT_DELETE EQU 08000H			; previous degignate deleted (DST)
					; STAT_DELETE : only for FIFO
STAT_NOFIND EQU 08008H			; codepage,device not found  (DST)
STAT_DEVERR EQU 0800AH			; Device error (DST, IVK, QIV, QLS)
STAT_BADATA EQU 0800CH			; bad font file (DST)
STAT_BADDEN EQU 0800CH			; no DST (DEN)
STAT_TOMANY EQU 0800CH			; too manay codepages (DST)
STAT_DUPLCP EQU 0800CH			; too manay codepages (DST)
STAT_NOCPIV EQU 08007H			; no codepage designated/invoked
STAT_NOCP EQU	08007H			; no codepage designated/invoked
					; (IVK, QIV, QLS)
TYPE_DISPLAY EQU 01H			;; display type device
FLAG_RESTART EQU 000001H		;; bit 1 = restart the parsing

FPKT	EQU	DS:[SI] 		;
FTP	EQU	ES:[BX] 		;
					; ( I=Input  O=Output )
FTBLK	STRUC				;
FTB_LENGTH DW	TYPE FTBLK		; (NOT TO BE CHANGED)
FTB_STATUS DW	0FFFFH			; (O) parsing compelte
FTB_TYPE DW	0			; (O)
FTB_TID DB	'........'              ; (I)
FTB_CP	DW	0FFFFH			; (I)
FTB_MOD DW	0			; (O)
FTB_FONTS DW	0			; (O)
FTB_ROWS  DB	0			;; (O) DISPLAY TYPE DEVICE
FTB_COLS  DB	0			;; (O) DISPLAY TYPE DEVICE
FTB_X	  DB	0			;; (O) DISPLAY TYPE DEVICE
FTB_Y	  DB	0			;; (O) DISPLAY TYPE DEVICE
FTB_COUNT DW	0			;; (O) DISPLAY TYPE DEVICE
FTB_DLEFT DW	0			; (O)  =0, none to come
FTB_DLEN DW	0			; (O)  =0, not in this packet
FTB_DALO DW	0			; (O)  in the DOS "packet" buffer
FTB_DAHI DW	0			; (O)  "  "   "    "       "
TARGET_LO DW	0			;  internal registers
TARGET_HI DW	0			;  internal registers
FTBLK	ENDS				;
					;
FBUFS	STRUC				;
FLAG	DW	0			;
BUFFER_LEN DW	0			;
BUFFER_ADDR DD	0			;
NUM_FTBLK DW	0			; no. of FTBKL entries
FBUFS	ENDS				;
					; STATUS : (in FTB_STATUS)
FSTAT_COMPLETE EQU 0FFFFH		; parsing compeleted. (good status)
FSTAT_FONT  EQU 0FFFEH			; font data is defined and returned
FSTAT_FOUND EQU 0FFFDH			; informations including font-length
FSTAT_MATCH EQU 0FFFCH			; font header matches  FTBLK
FSTAT_SEARCH EQU 0FFFBH 		; seraching for header & font
FSTAT_BOTTOM EQU 0FFF0H 		; below this are the DOS_STATUS.
					;
;; the FSTAT with value lower than 0FFF0H is to be returned to the DOS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
PUBLIC	FTABLE,FONT_PARSER		;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  ************************************
;;  **				      **
;;  **	     Resident Code	      **
;;  **				      **
;;  ************************************
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	FONT_PARSER data
;;
;;	-- Interface table : FTABLE
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FTABLE: FBUFS	<0FFFFH,,,>		;; for temporary testing
FTB1	FTBLK	<,,,,,,,,,,,,>		;; -- at most 12 entries
FTB2	FTBLK	<,,,,,,,,,,,,>		;;
FTB3	FTBLK	<,,,,,,,,,,,,>		;;
FTB4	FTBLK	<,,,,,,,,,,,,>		;;
FTB5	FTBLK	<,,,,,,,,,,,,>		;;
FTB6	FTBLK	<,,,,,,,,,,,,>		;;
FTB7	FTBLK	<,,,,,,,,,,,,>		;;
FTB8	FTBLK	<,,,,,,,,,,,,>		;;
FTB9	FTBLK	<,,,,,,,,,,,,>		;;
FTBa	FTBLK	<,,,,,,,,,,,,>		;;
FTBb	FTBLK	<,,,,,,,,,,,,>		;;
FTBc	FTBLK	<,,,,,,,,,,,,>		;;
					;;
FP_ERROR	DW   0000H		;; internal error register
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; the followings are bytes accumulated
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FTAG_LEN	EQU	8		;; FILE TAGE in the font file header
FTAG_COUNT	DW	0000H		;;
					;;
FTAG_PATTERN	LABEL	BYTE		;;
	DB	0FFH			;;
	DB	'FONT   '               ;;
					;;
					;;
					;; POINTER in the font file header
fptr_LOW LABEL	WORD			;;
fptr_LOL DB	00H			;; NEXT
fptr_LOH DB	00H			;;
fptr_HIGH LABEL WORD			;;
fptr_HIL DB	00H			;;
fptr_HIH DB	00H			;;
					;;
					;;
					;;
ENTRY_WORD LABEL WORD			;;
ENTRY_LOB DB	00H			;; ENTRY COUNT
ENTRY_HIB DB	00H			;;
NEXT_LOW LABEL	WORD			;;
NEXT_LOL DB	00H			;; NEXT
NEXT_LOH DB	00H			;;
NEXT_HIGH LABEL WORD			;;
NEXT_HIL DB	00H			;;
NEXT_HIH DB	00H			;;
TYPE_WORD LABEL WORD			;;
TYPE_LOB DB	00H			;; TYPE
TYPE_HIB DB	00H			;;
TID_CNT DW	00000H			;; TYPEID COUNT(0 to 8)
TYPE_ID :	DB '        '           ;; TYPEID
CPG_WORD LABEL	WORD			;;
CPG_LOB DB	00H			;; CODE PAGE
CPG_HIB DB	00H			;;
FONT_LOW LABEL	WORD			;;
FONT_LOL DB	00H			;; FONT ADDRESS
FONT_LOH DB	00H			;;
FONT_HIGH LABEL WORD			;;
FONT_HIL DB	00H			;;
FONT_HIH DB	00H			;;
;; the followings are contained in the font-block in the exact order & length
MOD_WORD LABEL	WORD			;;
MOD_LOB DB	00H			;; MODIFIER
MOD_HIB DB	00H			;;
FONTS_WORD LABEL WORD			;;
FONTS_LOB DB	00H			;; FONTS
FONTS_HIB DB	00H			;;
FDLEN_WORD LABEL WORD			;;
FDLEN_LOB DB	00H			;; FONT DATA LENGTH
FDLEN_HIB DB	00H			;;
PRE_FONT_ND	EQU ($-MOD_WORD)	;; used to update target for font data
					;; to follow. -- for NON-DISPLAY
;DISP_ROWS DB	 00H			 ;; DISPLAY's parameters :
;DISP_COLS DB	 00H			 ;; BOX SIZE
;DISP_X    DB	 00H			 ;; ASPECT RATIO
;DISP_Y    DB	 00H			 ;;
;COUNT_WORD    LABEL WORD		 ;; NO. OF DISPLAY CHARACTERS
;COUNT_LOB DB	 00H			 ;;
;COUNT_HIB DB	 00H			 ;;
;PRE_FONT_D	 EQU ($-MOD_WORD)	 ;; used to update target for font data
					;; to follow. -- for DISPLAY
					;;
;PTR_SEL_WORD	 LABEL WORD		 ;;
;PTR_SELOB DB	 00H			 ;;
;PTR_SEHIB DB	 00H			 ;;
;PRE_FONT_P0	 EQU ($-PTR_SELOB+PRE_FONT_ND) ;; to update target for font data
					;; to follow -- for PRINTER with
					;; selection type = 0.
					;;
;PTR_LEN_WORD	 LABEL WORD		 ;;
;PTR_LNLOB DB	 00H			 ;;
;PTR_LNHIB DB	 00H			 ;;
;PRE_FONT_P	 EQU ($-PTR_SELOB+PRE_FONT_ND) ;; to update target for font data
					;; to follow -- for PRINTER with
					;; selection type <> 0.
					;;
					;;
;; also update STAGE_CASES and indexing constants
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; the stage the parsing is in :  ;;;;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
STAGE_CASES LABEL WORD			;; the stage the parsing is in :
					;;
					;; *** INDEXED BY  STAGE-INDEX
					;;
	DW	OFFSET ENTRYLO		;; 0
	DW	OFFSET ENTRYHI		;; 1
	DW	OFFSET NEXTLOL		;; 2
	DW	OFFSET NEXTLOH		;; 3
	DW	OFFSET NEXTHIL		;; 4
	DW	OFFSET NEXTHIH		;; 5
	DW	OFFSET TYPELO		;; 6
	DW	OFFSET TYPEHI		;; 7
	DW	OFFSET TYPEIDS		;; 8
	DW	OFFSET CPGLO		;; 9
	DW	OFFSET CPGHI		;; A
	DW	OFFSET FONTLOL		;; B
	DW	OFFSET FONTLOH		;; C
	DW	OFFSET FONTHIL		;; D
	DW	OFFSET FONTHIH		;; E
	DW	00H			;; MATCH case -- end of SEARCH stages
	DW	00H			;; SCAN  case -- before PRE-FOUND stage
	DW	OFFSET MODLO		;; 11
	DW	OFFSET MODHI		;; 12
	DW	OFFSET FONTSLO		;; 13
	DW	OFFSET FONTSHI		;; 14
	DW	OFFSET FDLENLO		;; 15
	DW	OFFSET FDLENHI		;; 16 -- lead to FONT case,NON- DISPLAY
	DW	OFFSET DSPROWS		;; 17 -- DISPLAY only
	DW	OFFSET DSPCOLS		;; 18
	DW	OFFSET DSPX		;; 19
	DW	OFFSET DSPY		;; 1A
	DW	OFFSET DSPCOUNTLO	;; 1B
	DW	OFFSET DSPCOUNTHI	;; 1C -- lead to FONT case, DISPLAY
	DW	OFFSET PTRSELLO        ;;  1D -- PRINTER only
	DW	OFFSET PTRSELHI        ;;  1E
	DW	OFFSET PTRLENLO        ;;  1F
	DW	OFFSET PTRLENHI        ;;  20 -- lead to FONT case, PRINTER
	DW	00H			;; FOUND    case
	DW	00H			;; GET_FONT case
	DW	00H			;; PASS special stage
	DW	OFFSET FILETAG		;; 24
	DW	OFFSET fptrLOL		;; 25
	DW	OFFSET fptrLOH		;; 26
	DW	OFFSET fptrHIL		;; 27
	DW	OFFSET fptrHIH		;; 28
	DW	00H			;; FPTR_SKIP_CASE
					;;
					;; The followings are individual stage
STAGE_MAX EQU	($-STAGE_CASES)/2	;;  number of stages
					;;
					;; STAGE-INDEX
					;;
					;; **** INDEX TO STAGE_CASES  ****
ENTRY_LOX EQU	00H			;;
ENTRY_HIX EQU	01H			;;
NEXT_LOLX EQU	02H			;; NEXT
NEXT_LOHX EQU	03H			;;
NEXT_HILX EQU	04H			;;
NEXT_HIHX EQU	05H			;;
TYPE_LOBX EQU	06H			;; TYPE
TYPE_HIBX EQU	07H			;;
TYPE_IDX EQU	08H			;; TYPEID
CPG_LOBX EQU	09H			;; CODE PAGE
CPG_HIBX EQU	0AH			;;
FONT_LOLX EQU	0BH			;; FONT ADDRESS
FONT_LOHX EQU	0CH			;;
FONT_HILX EQU	0DH			;;
FONT_HIHX EQU	0EH			;;
					;; ------------------------------
MATCHX	EQU	0FH			;; MATCH is the end of SEARCH's stages
SCANX	EQU	10H			;; SCANX is before the PRE-FOUND stages
					;; ------------------------------
MOD_LOBX EQU	11H			;; MODIFIER
MOD_HIBX EQU	12H			;;
FONTS_LOBX EQU	13H			;; FONTS
FONTS_HIBX EQU	14H			;;
FDLEN_LOBX EQU	15H			;; FONT DATA LENGTH
FDLEN_HIBX EQU	16H			;;
DISP_ROWSX EQU	17H			;; DISPLAY -- CHAR. SIZE
DISP_COLSX EQU	18H			;;
DISP_XX    EQU	19H			;; DISPLAY -- ASPECT RATIO
DISP_YX    EQU	1AH			;;
COUNT_LOBX EQU	1BH			;; DISPLAY -- COUNT
COUNT_HIBX EQU	1CH			;;
PTRSELLOX  EQU	1DH			;;
PTRSELHIX  EQU	1EH			;;
PTRLENLOX  EQU	1FH			;;
PTRLENHIX  EQU	20H			;;
					;;
					;; ------------------------------
FOUNDX	EQU	21H			;; GET_FX is the end of PRE-FOUND stage
GET_FX	EQU	22H			;;
					;; ------------------------------
PASSX	EQU	23H			;; see pass_brk table
					;; ------------------------------
FTAGX	EQU	24H			;; RESTART ==> FILE TAG
					;;
fptr_LOLX EQU	25H			;; POINTER in font file header
fptr_LOHX EQU	26H			;;
fptr_HILX EQU	27H			;;
fptr_HIHX EQU	28H			;; ---------------------------------
					;;
fptr_SKIPX EQU	29H			;; ==> ENTRY_LOX
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; PASS -- to skip some bytes ;;;;;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; the PASS mechanism is used to skip
					;; a number of bytes between two fields
					;; The numbers are tabulated in
					;; PASS_BRK table in the accumulative
					;; sum. The PASS_POSTX(and PASS_POSTXX)
					;; are used to tell what is the stage
					;; after all the bytes have skipped.
					;;
PASS_POSTX  DW	 STAGE_MAX		;; the stage after pass-stage
					;;
FILE_OFFSET    EQU     0BH	       ;; spaces to be skipped in font file :
					;; ( after TAG, before POINTER)
					;;
PASS_CNT DW	0			;;
PASS_BRK LABEL	WORD			;;
	DW	FILE_OFFSET		;; skip in the font file header
	DW	FILE_OFFSET+2		;; pass header-length, needs to reset
					;; PASS_CNT for each of the font_header
	DW	FILE_OFFSET+8		;; pass header-reserved bytes
PASS_INDX EQU	($-PASS_BRK)/2		;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; the control variables :  ;;;;;;;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STAGE	DW	STAGE_MAX		;; of the STAGE-INDEX
					;;
Pre_font_len	DW	00000H		;; no. of bytes before the FONT DATA
					;;
					;;
COUNT_LO DW	00000H			;; no. of bytes parsed so far
COUNT_hI DW	00000H			;;
					;;
HIT_LO	DW	00000H			;; the next byte that is addressed by :
HIT_HI	DW	00000H			;; either NEXT or TARGET in FTBLK.
					;;
HIT_FLAG DW	00000H			;; IF ZERO, the NEXT is approaching
HIT_BX	DW	00000H			;; where FTB is found for nearest hit
					;;
NUM_FTB DW	00000H			;; as defined in the FP_BUFFER
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	FONT_PARSER routine
;;
;;	-- to be called at every packet received to extract informations
;;	   from Font File on byte basis.
;;
;;	-- Interface though FTABLE
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
FONT_PARSER PROC			;;
	PUSH	DS			;; save all registers Revised
	PUSH	ES			;;
	PUSH	AX			;;
	PUSH	BX			;;
	PUSH	CX			;;
	PUSH	DX			;;
	PUSH	DI			;;
	PUSH	SI			;;
					;; BP isn't used, so it isn't saved
	LEA	BX,FTABLE		;;
	PUSH	CS			;;
	POP	ES			;; ES:[BX]
	LDS	SI,FTP.BUFFER_ADDR	;; DS:[SI]
	MOV	CX,FTP.BUFFER_LEN	;; CX = length of packet
	MOV	DX,FTP.NUM_FTBLK	;; DX = number of FTB
	MOV	cs:num_ftb,DX		   ;;
	AND	DX,DX			;;
	JNZ	VALID_BUFFER		;;
	MOV	cs:fp_error,0020H	   ;; ERROR 0020H
	JMP	FP_RET			;;
VALID_BUFFER :				;;
	MOV	AX,FTP.FLAG		;;
	AND	AX,FLAG_RESTART 	;;
	Jnz	has_RESTART		;;
	JMP	NO_RESTART		;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
has_restart :				;;
	PUSH	BX			;; reset all the output fields
	ADD	BX,TYPE FBUFS		;; FTP = FONT BLOCK
	XOR	AX,AX			;;
					;;
	MOV	cs:ftag_count,AX	   ;;
	MOV	cs:fptr_low,AX		   ;;
	MOV	cs:fptr_high,AX 	   ;;
	MOV	cs:pre_font_len,AX	  ;;
	MOV	cs:count_lo,AX		   ;;
	MOV	cs:count_hi,AX		   ;;
	MOV	cs:next_low,AX		   ;;
	MOV	cs:next_high,AX 	   ;;
	MOV	cs:hit_lo,AX		   ;;
	MOV	cs:hit_hi,AX		   ;;
	MOV	cs:hit_flag,AX		   ;;
	MOV	cs:pass_cnt,AX		   ;;
	MOV	cs:pass_postx,STAGE_MAX    ;;
					;;
	MOV	cs:stage,STAGE_MAX	   ;;
					;;
RESET_FTB :				;;
	MOV	FTP.FTB_STATUS,FSTAT_SEARCH
	MOV	FTP.FTB_TYPE,AX 	;;
	MOV	FTP.FTB_MOD,AX		;;
	MOV	FTP.FTB_FONTS,AX	;;
	MOV	FTP.FTB_ROWS,AL 	;;
	MOV	FTP.FTB_COLS,AL 	;;
	MOV	FTP.FTB_X,AL		;;
	MOV	FTP.FTB_Y,AL		;;
	MOV	FTP.FTB_COUNT,AX	;;
	MOV	FTP.FTB_DLEFT,AX	;;
	MOV	FTP.FTB_DLEN,AX 	;;
	MOV	FTP.FTB_DALO,AX 	;;
	MOV	FTP.FTB_DAHI,AX 	;;
	MOV	FTP.TARGET_LO,AX	;;
	MOV	FTP.TARGET_HI,AX	;;
					;;
	ADD	BX, TYPE FTBLK		;;
					;;
	DEC	DX			;;
	AND	DX,DX			;;
	JNZ	RESET_FTB		;;
					;;
	POP	BX			;;
NO_RESTART :				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; any FTBLKs have their data all
					;; returned ? if so set their status
					;; from FOUND to COMPLETE
	PUSH	BX			;;
	ADD	BX,TYPE FBUFS		;; FTP = FONT BLOCK
					;;
	MOV	DX,cs:num_ftb		   ;;
					;;
SET_COMPLETE :				;;
	MOV	AX,FTP.FTB_STATUS	;;
	CMP	AX,FSTAT_FONT		;;
	JNE	SET_NEXT		;;
					;;
	MOV	AX,FTP.FTB_DLEFT	;;
	AND	AX,AX			;;
	JNZ	SET_NEXT		;;
					;;
	MOV	FTP.FTB_STATUS,FSTAT_COMPLETE
					;;
SET_NEXT :				;;
					;;
	ADD	BX,TYPE FTBLK		;;
					;;
	DEC	DX			;;
	AND	DX,DX			;;
	JNZ	SET_COMPLETE		;;
					;;
	POP	BX			;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ADD	BX,TYPE FBUFS		;; FTP = FONT BLOCK
					;;
	PUSH	CX			;; STACK 1 = CX
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; DO WHILE CX is not zero :
;;
;; -- on each loop, the CX, COUNTs are updated
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
FTB_LOOP :				;;
	POP	AX			;; STACK -1
	SUB	AX,CX			;;
	ADD	cs:count_lo,AX		   ;;
	JNC	NO_CARRY		;;
	ADD	cs:count_hi,1000H	   ;;
NO_CARRY :				;;
	PUSH	CX			;; STACK 1 = CX
	AND	CX,CX			;;
	JNZ	FTB_CONT		;;
	JMP	FTB_LPEND		;;
					;; DO CASES :
FTB_CONT :				;; ==========
					;;
	MOV	AX,cs:stage		   ;;
					;;
	CMP	AX,STAGE_MAX		;;
	JNE	FTB_010 		;;
	JMP	START_CASE		;; ** RESTART **
					;;
FTB_010 :				;;
	CMP	AX,MATCHX		;;
	JAE	FTB_020 		;;
	JMP	SEARCH_CASE		;; ** SEARCH **
					;;
FTB_020 :				;;
	CMP	AX,MATCHX		;;
	JNE	FTB_030 		;;
	JMP	MATCH_CASE		;; ** MATCH **
					;;
FTB_030 :				;;
	CMP	AX,SCANX		;;
	JNE	FTB_040 		;;
	JMP	SCAN_CASE		;; ** SCAN **
					;;
FTB_040 :				;;
	CMP	AX,FOUNDX		;;
	JAE	FTB_050 		;;
	JMP	PRE_FOUND_CASE		;; ** PRE-FOUND **
					;;
FTB_050 :				;;
	CMP	AX,FOUNDX		;;
	JNE	FTB_060 		;;
	JMP	FOUND_CASE		;; ** FOUND  **
					;;
FTB_060 :				;;
	CMP	AX,GET_FX		;;
	JNE	FTB_070 		;;
	JMP	GETFONT_CASE		;; ** GET_FONT **
					;;
FTB_070 :				;;
	CMP	AX,PASSX		;;
	JNE	FTB_080 		;;
	JMP	PASS			;; ** PASS **
					;;
FTB_080 :				;;
	CMP	AX,FPTR_SKIPX		;;
	JAE	FTB_090 		;;
	JMP	SEARCH_CASE		;; ** SEARCH **
					;;
FTB_090 :				;;
	CMP	AX,FPTR_SKIPX		;;
	JNE	FTB_FFF 		;;
	JMP	FPTR_SKIP_CASE		;; ** SEARCH **
					;;
FTB_FFF :				;;
	MOV	FTP.FTB_STATUS,STAT_DEVERR
	JMP	FTB_LPEND		;; ** DEVICE ERROR **
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; at the entry of each STAGES /CASES
;;
;; --	DS:[SI]  (FPKT) points to PACKET, of DOS's buffer
;; --	CX	 remaining packet length
;; --	ES:[BX]  points to the first FTBLK
;; --	COUNT_LO, COUNT_HI, upto but and including the address pointed by FPKT
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
;============================================================================
START_CASE :				;; pass the FILE leading bytes
					;;
	MOV	cs:ftag_count,0 	   ;;
	MOV	cs:stage,ftagx		   ;;
	JMP	FTB_LOOP		;;
					;;
;=============================================================================
FPTR_SKIP_CASE :			;; skip until the ENTRY pointed by
					;; POINTER (in FPTR) is reached.
					;;
					;; **************
	MOV	AX,cs:fptr_low		   ;; * HIT = FPTR *
	MOV	cs:hit_lo,AX		   ;; **************
	MOV	DX,cs:fptr_high 	   ;;
	MOV	cs:hit_hi,DX		   ;;
					;;
	CMP	AX,0FFFFH		;;
	JNE	FPTR_SKIP_VALID 	;;
	CMP	DX,0FFFFH		;;
	JNE	FPTR_SKIP_VALID 	;;
					;;
	MOV	FTP.FTB_STATUS,STAT_BADATA ;; returned at the first FTBLK
	JMP	FPTR_SKIP_MORE		;;
					;;
FPTR_SKIP_VALID :			;;
					;; normalised HIT_HI, HIT_LO
	MOV	AX,DX			;;
	AND	AX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	AX,CL			;;
	POP	CX			;;
	AND	DX,0F000H		;;
	ADD	AX,cs:hit_lo		   ;;
	JNC	NO_CARRY10		;;
	ADD	DX,01000H		;;
NO_CARRY10:				;;
	MOV	cs:hit_lo,AX		   ;;
	MOV	cs:hit_hi,DX		   ;;
					;; **************************
					;; * compare FPTR and COUNT *
					;; **************************
					;; DX:AX = HIT_HI:HIT_LO (normalised)
					;;
	SUB	AX,cs:count_lo		   ;;
	Jnc	more_fptrlo		;;
	sub	dx,01000h		;;
	jc	fptr_bad		;;
					;;
more_fptrlo :				;;
	SUB	DX,cs:count_hi		   ;;
	JC	fptr_BAD		;;
					;;
	INC	AX			;; COUNT can be at the HIT, then AX=0
	JNC	NO_CARRY11		;; INC AX to make AX comparable to CX
	ADD	DX,01000H		;; i.e. AX = offset + 1
					;;
NO_CARRY11:				;;
	CMP	AX,CX			;;
	JA	fptr_skip_more		;; AX > CX, whole CX to be skipped
					;;
	PUSH	DX			;;  normalise dx:ax
	AND	DX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	DX,CL			;;
	POP	CX			;;
	ADD	AX,DX			;;
	POP	DX			;;
	JNC	NO_CARRY13		;;
	ADD	DX,01000H		;;
NO_CARRY13:				;;
	AND	DX,0F000H		;;
					;;
	PUSH	AX			;;
	PUSH	DX			;; STACK +1 : normalosed DX:AX
	SUB	AX,CX			;;
	JNC	NO_BORROW11		;;
	SUB	DX,1000H		;;
	JC	fptr_MORE_CXp		;; dx:ax < cx
NO_BORROW11:				;;
					;; dx:ax >= cx
	AND	AX,AX			;;
	JNE	fptr_skip_MOREP 	;;
	AND	DX,DX			;;
	JNE	fptr_skip_MOREP 	;;
					;; dx:ax = cx, or
					;; offset + 1 = CX
					;;
					;; ************************************
					;; * POINTER is within the current CX *
					;; ************************************
fptr_MORE_CXP : 			;;
	POP	DX			;;
	POP	AX			;; STACK -1
					;;
fptr_MORE_CX :				;; DX = 0,to have more CX than offset+1
	DEC	AX			;; = offset : 0 and above
	SUB	CX,AX			;;
	ADD	SI,AX			;; where the first byte is
					;;
	MOV	cs:stage,entry_lox	   ;; ENTRIES in the font file
					;;
	JMP	FTB_LOOP		;;  ******  RETURN  *******
					;;
					;; ***********************************
					;; * more to skip ==> FPTR_SKIP_CASE *
					;; ***********************************
fptr_skip_morep:			;;
	POP	DX			;;
	POP	AX			;; STACK -1
					;;
fptr_skip_more :			;;
	ADD	SI,CX			;;
	SUB	CX,CX			;;
	JMP	FTB_LOOP		;; ******  RETURN  *****
					;;
					;; ***********************************
					;; * bad POINTER in font file header *
					;; ***********************************
					;;
fptr_bad :				;;
	MOV	cs:fptr_low,0FFFFH	   ;;
	MOV	cs:fptr_high,0FFFFH	   ;;
					;;
	MOV	FTP.FTB_STATUS,STAT_BADATA ;; returned at the first FTBLK
					;;
	JMP	FPTR_SKIP_MORE		;;
					;;
;=============================================================================
SEARCH_CASE :				;;
					;; still looking for header to match
					;; the input : codepage and typeid
					;;
	MOV	DI,cs:stage		   ;;
					;;
	ADD	DI,DI			;; double to index to WORD-offset
					;;
	JMP	CS:STAGE_CASES[DI]	;; call routine to process the stage
					;;
					;;
;===========================================================================
MATCH_CASE :				;;
					;;
	PUSH	BX			;;
	MOV	DX,cs:num_ftb		   ;;
					;;
					;;
MATCH_LOOP :				;;
	MOV	AX,FTP.FTB_STATUS	;;
	CMP	AX,FSTAT_SEARCH 	;;
	JE	MATCH_SEARCH		;;
	JMP	MATCH_NEXT		;;
					;;
MATCH_SEARCH :				;;
	MOV	AX,FTP.FTB_CP		;; check the FTB with SEARCH status
	CMP	AX,cs:cpg_word		   ;;
	JNE	MATCH_MORE		;;
	PUSH	DS			;; code page matched
	PUSH	SI			;;
	PUSH	CX			;;
					;;
	PUSH	CS			;;
	POP	DS			;;
	MOV	SI,OFFSET TYPE_ID	;;
	LEA	DI,[BX].FTB_TID 	;;
	MOV	CX,8			;;
	REPE	CMPSB			;;
					;;
	POP	CX			;;
	POP	SI			;;
	POP	DS			;;
					;;
	JNE	MATCH_MORE		;;
					;; MATCH !!!!!	(type_id matched)
	MOV	FTP.FTB_STATUS,FSTAT_MATCH
	MOV	AX,cs:type_word 	   ;;
	MOV	FTP.FTB_TYPE,AX 	;;
	MOV	AX,cs:font_low		   ;;
	MOV	FTP.TARGET_LO,AX	;;
	MOV	AX,cs:font_high 	   ;;
	MOV	FTP.TARGET_HI,AX	;;
					;;
	JMP	MATCH_NEXT		;;
					;;
MATCH_MORE :				;; if this is the last rounf ?
					;;
	MOV	AX,cs:next_low		   ;; NEXT = FFFF:FFFF means no more
	CMP	AX,-1			;;	  header to come.
	JNE	MATCH_NEXT		;;
					;;
	MOV	AX,cs:next_high 	   ;;
	CMP	AX,-1			;;
	JNE	MATCH_NEXT		;;
					;;
	MOV	FTP.FTB_STATUS,STAT_NOFIND ;; ERROR : no match
					;;
MATCH_NEXT :				;;
	ADD	BX,FTP.FTB_LENGTH	;;
	DEC	DX			;;
	AND	DX,DX			;;
	JZ	MATCH_ALL		;;
	JMP	MATCH_LOOP		;;
					;;
MATCH_ALL :				;;
	MOV	cs:stage,SCANX		   ;;
					;;
MATCH_DONE :				;;
	POP	BX			;;
	JMP	FTB_LOOP		;;
					;;
;===========================================================================
SCAN_CASE :				;;
					;; **********************************
					;; * determine whether it the font  *
					;; * data(TARGET),or the next font  *
					;; * header(NEXT) that is approaching
					;; **********************************
					;;
	MOV	AX,cs:next_low		   ;;
	MOV	cs:hit_lo,AX		   ;;
	MOV	AX,cs:next_high 	   ;;
	MOV	cs:hit_hi,AX		   ;;
	XOR	AX,AX			;;
	MOV	cs:hit_flag,AX		   ;;
					;;
	MOV	DI,cs:hit_hi		   ;; normalised HIT_HI, HIT_LO
	MOV	AX,DI			;;
	AND	AX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	AX,CL			;;
	POP	CX			;;
	AND	DI,0F000H		;;
	ADD	AX,cs:hit_lo		   ;;
	JNC	NO_CARRY2		;;
	ADD	DI,01000H		;;
NO_CARRY2 :				;;
	MOV	cs:hit_lo,AX		   ;;
	MOV	cs:hit_hi,DI		   ;;
					;;
	MOV	DX,cs:num_ftb		   ;;
					;;
	PUSH	BX			;;
SCAN_LOOP :				;;
	MOV	AX,FTP.FTB_STATUS	;;
	CMP	AX,FSTAT_MATCH		;;
	JNE	SCAN_NEXT		;;
					;;
					;;
	MOV	DI,FTP.TARGET_HI	;; NORMALISED TARGET
	MOV	AX,DI			;;
	AND	AX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	AX,CL			;;
	POP	CX			;;
	AND	DI,0F000H		;;
	ADD	AX,FTP.TARGET_LO	;;
	JNC	NO_CARRY1		;;
	ADD	DI,01000H		;;
NO_CARRY1 :				;; DI:AX = NORMALISED TARGET
					;;
					;; ** compare the TARGET and the NEXT
					;;
	CMP	DI,cs:hit_hi		   ;;
	JA	SCAN_NEXT		;;
					;;
	JE	SCAN_EQU		;;
	JMP	NEAR_FONT		;;
					;;
SCAN_EQU :				;;
	CMP	AX,cs:hit_lo		   ;;
	JA	SCAN_NEXT		;;
	JE	SCAN_ERROR_CHK		;;
					;; **********************************
					;; * the font data is approaching   *
					;; **********************************
NEAR_FONT :				;;
	MOV	cs:hit_flag,-1		   ;;
	MOV	cs:hit_lo,AX		   ;;
	MOV	cs:hit_hi,DI		   ;;
	MOV	cs:hit_bx,BX		   ;; used for BAD_BX and in FOUND_CASE
	JMP	SCAN_NEXT		;;
					;;
					;; **********************************
					;; * the NEXT header is approaching *
					;; **********************************
SCAN_ERROR_CHK :			;;
	MOV	AX,cs:hit_flag		   ;;
	AND	AX,AX			;;
	JNZ	SCAN_NEXT		;;
	MOV	FTP.FTB_STATUS,STAT_BADATA ;; next header and font cannot be the
					;; same
					;;
SCAN_NEXT :				;;
	DEC	DX			;;
	AND	DX,DX			;;
	JZ	SCAN_DONE		;;
					;;
	ADD	BX,FTP.FTB_LENGTH	;;
	JMP	SCAN_LOOP		;; ** is there any closer font data ?
					;;
					;; ************************************
					;; * the HIT is either font data(TARGET
					;; * or the font block (NEXT).	      *
					;; ************************************
SCAN_DONE :				;;
	POP	BX			;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	DX,cs:hit_hi		   ;; HIT_FLAG, HIT_LO, HIT_HI defined
	MOV	AX,cs:hit_lo		   ;;
					;;
	CMP	AX,0FFFFH		;;
	JNE	NOT_FFFF_HIT		;;
	CMP	DX,0FFFFH		;;
	JNE	NOT_FFFF_HIT		;;
	JMP	SCAN_MORE		;; stage remained as SCAN, discard data
					;;
NOT_FFFF_HIT :				;;
					;; DX:AX = HIT_HI:HIT_LO (normalised)
	SUB	AX,cs:count_lo		   ;;
	JNC	NO_BORROW		;;
	SUB	DX,01000H		;;
	JC	SCAN_BAD		;;
NO_BORROW:				;;
	SUB	DX,cs:count_hi		   ;;
	JC	SCAN_BAD		;;
					;;
	INC	AX			;; COUNT can be at the HIT, then AX=0
	JNC	NO_CARRYX		;; INC AX to make AX comparable to CX
	ADD	DX,01000H		;; i.e. AX = offset + 1
					;;
NO_CARRYX :				;;
	CMP	AX,CX			;;
	JA	SCAN_MORE		;;
					;;
	PUSH	DX			;;
	AND	DX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	DX,CL			;;
	POP	CX			;;
	ADD	AX,DX			;;
	POP	DX			;;
	JNC	NO_CARRY3		;;
	ADD	DX,01000H		;;
NO_CARRY3 :				;;
	AND	DX,0F000H		;;
					;;
					;;
	PUSH	AX			;;
	PUSH	DX			;;
	SUB	AX,CX			;;
	JNC	NO_BORROW1		;;
	SUB	DX,1000H		;;
	JC	MORE_CXp		;;
NO_BORROW1 :				;;
					;; dx:ax >= cx
	AND	AX,AX			;;
	JNE	SCAN_MOREP		;;
	AND	DX,DX			;;
	JNE	SCAN_MOREP		;;
					;;
					;; offset + 1 = CX
					;;
MORE_CXP :				;;
	POP	DX			;;
	POP	AX			;;
					;;
MORE_CX :				;; DX = 0,to have more CX than offset+1
	DEC	AX			;; = offset : 0 and above
	SUB	CX,AX			;;
	ADD	SI,AX			;; where the first byte is
	MOV	AX,cs:hit_flag		   ;;
	AND	AX,AX			;;
	JE	NEXT_REACHED		;;
					;;
	MOV	cs:stage,MOD_LOBX	   ;; font-data reached,
					;;
	JMP	FTB_LOOP		;;  ****** RETURN   *******
					;;
NEXT_REACHED :				;;
	MOV	cs:stage,PASSX		   ;;
	MOV	cs:pass_postx,next_lolX    ;;
	MOV	cs:pass_cnt,FILE_OFFSET    ;;
					;;
					;;
	JMP	FTB_LOOP		;; ******  RETURN   *******
					;;
					;; ***********************************
SCAN_MOREP :				;; * scan more FTBLK for the nearest *
					;; * font data			     *
					;; ***********************************
	POP	DX			;;
	POP	AX			;;
					;;
SCAN_MORE :				;;
	ADD	SI,CX			;;
	SUB	CX,CX			;;
	JMP	FTB_LOOP		;; more SCAN stage
					;;
SCAN_BAD:				;; *************************
	MOV	AX,cs:hit_flag		   ;; * scan is bad	      *
	AND	AX,AX			;; *************************
	JNZ	BAD_BX			;;
	MOV	AX,-1			;; NEXT is pointing backwards
	MOV	cs:next_low,AX		   ;;
	MOV	cs:next_high,AX 	   ;; no more NEXT
	MOV	FTP.FTB_STATUS,STAT_BADATA ;; returned at the first FTBLK
	JMP	FTB_LOOP		;;
					;;
BAD_BX	:				;;
	PUSH	BX			;; FONT is pointing backwards
	MOV	BX,cs:hit_bx		   ;;
	MOV	FTP.FTB_STATUS,STAT_BADATA
	POP	BX			;;
	JMP	FTB_LOOP		;;
					;;
;===========================================================================
PRE_FOUND_CASE :			;;
					;; extract informations from the font
					;; block until font_length is defined
					;;
	MOV	DI,cs:stage		   ;;
					;;
	ADD	DI,DI			;; double to index to WORD-offset
					;;
	JMP	CS:STAGE_CASES[DI]	;; call routine to process the stage
					;;
;===========================================================================
FOUND_CASE :				;;
	MOV	DI,OFFSET FTB_LOOP	;; as FOUND has two places to return to
	PUSH	DI			;;
;===========================================================================
FOUND_DO :				;;
					;; define informations into FTBLK of
					;; HIT_BX defined in the SCAN case
	PUSH	BX			;;
	MOV	BX,cs:hit_bx		   ;;
					;; FTBLK :
	MOV	AX,cs:mod_word		   ;;
	MOV	FTP.FTB_MOD,AX		;;
	MOV	AX,cs:fonts_word	   ;;
	MOV	FTP.FTB_FONTS,AX	;;
					;;
	MOV	AX,cs:fdlen_word	   ;;
	MOV	FTP.FTB_DLEFT,AX	;;
	MOV	FTP.FTB_DLEN,0		;;
	MOV	FTP.FTB_DALO,0		;;
	MOV	FTP.FTB_DAHI,0		;;
					;;
	MOV	FTP.FTB_STATUS,FSTAT_FOUND
					;;
;	CMP	FTP.FTB_TYPE,TYPE_DISPLAY;
;	JNE	CHECK_PTR_TYPE		;;
;	CMP	cs:pre_font_len,PRE_FONT_D ;;
;	JNE	DISPLAY_BAD		;;
;	JMP	DISPLAY_DONE		;;
;					;;
;CHECK_PTR_TYPE :			 ;;
;	CMP	FTP.FTB_TYPE,TYPE_PRINTER;
;	JNE	SET_STAGE		;;
;	CMP	cs:ptr_sel_word,0	   ;;
;	JNE	PRINTER_HAS_SEL 	;;
;	CMP	cs:pre_font_len,PRE_FONT_P0;;
;	JNE	PRINTER_BAD		;;
;	JMP	PRINTER_DONE		;;
;					;;
;PRINTER_HAS_SEL :			 ;;
;	 CMP	 cs:pre_font_len,PRE_FONT_P ;;
;	 JNE	 PRINTER_BAD		 ;;
;	 JMP	 PRINTER_DONE		 ;;
;					 ;;
;DISPLAY_BAD :				 ;;
;					;;
;	MOV	FTP.FTB_STATUS,STAT_BADATA ;the FDLEN_WORD should be 0.
;					;;
;DISPLAY_DONE : 			 ;;
;	MOV	AL,cs:disp_rows 	   ;;
;	MOV	FTP.FTB_ROWS,AL 	;;
;	MOV	AL,cs:disp_cols 	   ;;
;	MOV	FTP.FTB_COLS,AL 	;;
;	MOV	AL,cs:disp_x		   ;;
;	MOV	FTP.FTB_X,AL		;;
;	MOV	AL,cs:disp_y		   ;;
;	MOV	FTP.FTB_Y,AL		;;
;	MOV	AX,cs:count_word	   ;;
;	MOV	FTP.FTB_COUNT,AX	;;
;	JMP	SET_STAGE		;;
					;;
;PRINTER_BAD :				 ;;
;					 ;;
;	 MOV	 FTP.FTB_STATUS,STAT_BADATA ;the FDLEN_WORD should be 0.
;					 ;;
;PRINTER_DONE : 			 ;;
;	 MOV	 AX,cs:ptr_sel_word	    ;;
;	 MOV	 FTP.FTB_SELECT,AX	 ;;
;	 MOV	 AX,cs:ptr_len_word	    ;;
;	 MOV	 FTP.FTB_SELLEN,AX	 ;;
;					 ;;
;SET_STAGE :				 ;; STAGE :
	MOV	AX,cs:fdlen_word	   ;; if no font data to follow
	AND	AX,AX			;;
	JNZ	GET_FDATA		;;
	MOV	cs:stage,SCANX		   ;; then scan for next header or font
	JMP	FONT_RET		;;
					;;
GET_FDATA :				;; update the moving target
	MOV	cs:stage,GET_FX 	   ;;
	MOV	AX,cs:pre_font_len	   ;;
	ADD	FTP.TARGET_LO,AX	;;
	JNC	FONT_RET		;;
	ADD	FTP.TARGET_HI,01000H	;;
					;;
FONT_RET :				;;
	POP	BX			;;
	RET				;;
					;;
;===========================================================================
GETFONT_CASE :				;; as ES:[SI], at COUNT, there is font
					;; data
	MOV	DX,cs:num_ftb		   ;;
	PUSH	BX			;;
					;;
	MOV	cs:hit_hi,0		   ;; temp. register
	MOV	cs:hit_flag,0		   ;; assumed can be changed to SCAN stage
					;;
	MOV	DI,cs:count_hi		   ;; normalised COUNT_HI,COUNT_LO
	MOV	AX,DI			;;
	AND	AX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	AX,CL			;;
	POP	CX			;;
	AND	DI,0F000H		;;
	ADD	AX,cs:count_lo		   ;;
	JNC	NO_CARRY4		;;
	ADD	DI,01000H		;;
NO_CARRY4 :				;;
	MOV	cs:count_lo,AX		   ;;
	MOV	cs:count_hi,DI		   ;;
					;;
					;;
GETFONT_LOOP :				;;
	MOV	AX,FTP.FTB_STATUS	;;
	CMP	AX,FSTAT_FONT		;;
	JE	GETFONT_CONT		;;
					;;
	CMP	AX,FSTAT_FOUND		;;
	JE	GETFONT_FOUND		;;
					;;
	JMP	NEXT_GETFONT		;;
					;;
GETFONT_FOUND : 			;;
	MOV	AX,FTP.FTB_DLEFT	;;
	AND	AX,AX			;;
	JZ	NEXT_GF 		;;
	MOV	FTP.FTB_STATUS,FSTAT_FONT;
	JMP	GETFONT_CONT1		;;
					;;
					;;
GETFONT_CONT :				;;
	MOV	AX,FTP.FTB_DLEFT	;;
	AND	AX,AX			;;
	JNZ	GETFONT_CONT1		;;
NEXT_GF :				;;
	JMP	NEXT_GETFONT		;;
					;; only on FOUND and DLEFT <> 0
GETFONT_CONT1:				;;
	MOV	DI,FTP.TARGET_HI	;; normalised TARGET
	MOV	AX,DI			;;
	AND	AX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	AX,CL			;;
	POP	CX			;;
	AND	DI,0F000H		;;
	ADD	AX,FTP.TARGET_LO	;;
	JNC	NO_CARRY5		;;
	ADD	DI,01000H		;;
NO_CARRY5 :				;; DI:AX = TARGET (normalised)
					;;
	CMP	DI,cs:count_hi		   ;;
	JB	GETFONT_BAD		;;
	JNE	NEXT_GETFONT		;;
	CMP	AX,cs:count_lo		   ;;
	JB	GETFONT_BAD		;;
	JNE	NEXT_GETFONT		;;
					;;
	MOV	FTP.FTB_DALO,SI 	;; where the font data is in the packet
	MOV	FTP.FTB_DAHI,DS 	;;
					;;
	MOV	AX,FTP.FTB_DLEFT	;;
	CMP	AX,CX			;;
	JAE	UPTO_CX 		;;
					;; upto FDLEFT
	MOV	FTP.FTB_DLEFT,0 	;;
	MOV	FTP.FTB_DLEN,AX 	;;
	CMP	cs:hit_hi,AX		   ;;
	JNB	NOT_HIGHER0		;;
	MOV	cs:hit_hi,AX		   ;;
NOT_HIGHER0 :				;;
	ADD	FTP.TARGET_LO,AX	;;
	JNC	NEXT_GETFONT		;;
	ADD	FTP.TARGET_HI,01000H	;;
	JMP	NEXT_GETFONT		;;
					;;
GETFONT_BAD :				;;
	MOV	FTP.FTB_STATUS,STAT_BADATA ;; pointing backwards
	JMP	NEXT_GETFONT		;;
					;;
UPTO_CX :				;;
	SUB	AX,CX			;;
	MOV	FTP.FTB_DLEFT,AX	;;
	MOV	FTP.FTB_DLEN,CX 	;;
	MOV	cs:hit_hi,CX		   ;;
	ADD	FTP.TARGET_LO,CX	;;
	JNC	NO_CARRYOVER		;;
	ADD	FTP.TARGET_HI,01000H	;;
NO_CARRYOVER :				;;
	AND	AX,AX			;; all data have been returned ?
	JZ	NEXT_GETFONT		;;
					;;
	MOV	cs:hit_flag,-1		   ;; no ! stay in the GET_FONT stage
					;;
NEXT_GETFONT :				;;
	ADD	BX,FTP.FTB_LENGTH	;;
	DEC	DX			;;
	AND	DX,DX			;;
	JZ	GETFONT_END		;;
	JMP	GETFONT_LOOP		;;
					;;
GETFONT_END :				;;
	MOV	AX,cs:hit_hi		   ;;
	ADD	SI,AX			;;
	SUB	CX,AX			;;
					;;
	CMP	cs:hit_flag,0		   ;;
	Jne	GETFONT_DONE		;;
	MOV	cs:stage,SCANX		   ;; no more in the GET_FONT stage
					;;
					;;
GETFONT_DONE :				;;
	POP	BX			;;
	JMP	FTB_LOOP		;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; STAGES --  "called by" SERACH_CASE
;;
;; --	DS:[SI]  (FPKT) points to PACKET, of DOS's buffer
;; --	CX	 remaining packet length
;; --	ES:[BX]  points to the first FTBLK
;; --	COUNT_LO, COUNT_HI, upto but not including the address pointed by FPKT
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;+++++++++++++++++++++++++++++++++
filetag :				;;
					;;
;	mov	ax,ftag_len		;;
	cmp	cs:ftag_count,ftag_len	   ;;
	jB	valid_ftag		;;
	JE	FTAG_FAILED		;;
					;;
	mov	ftp.ftb_status,stat_deverr
	mov	cs:fp_error,00022H	   ;; ERROR 0022H
					;;
FTAG_FAILED :				;; discard all the bytes, while
	ADD	SI,CX			;; stage stays as FTAGX
	SUB	CX,CX			;;
	JMP	FTB_LOOP		;; **** RETURN (bytes discarded) ****
					;;
VALID_FTAG :				;;
	MOV	AX,FPKT 		;;
	INC	SI			;;
	DEC	CX			;;
					;;
	MOV	DI,cs:ftag_count	   ;;
	CMP	AL,cs:ftag_pattern[DI]	   ;;
	JE	FTAG_NEXTB		;;
					;;
	mov	ftp.ftb_status,stat_badata
	MOV	ax,ftag_len		;; stays in FTAGX to consume all bytes
	MOV	cs:ftag_count,ax	   ;; stays in FTAGX to consume all bytes
	JMP	FTB_LOOP		;; **** RETURN (FAILED !)  ****
					;;
FTAG_NEXTB :				;;
	INC	DI			;;
	MOV	cs:ftag_count,DI	   ;;
					;;
	CMP	DI,ftag_len		;;
	JE	FTAG_DONE		;;
					;;
	JMP	FTB_LOOP		;; **** RETURN ( MORE TO COME) ****
					;;
FTAG_DONE :				;;
	MOV	cs:pass_cnt,0		   ;;
	MOV	cs:stage,PASSX		   ;;
	MOV	cs:pass_postx,fptr_lolx    ;;
					;;
	JMP	FTB_LOOP		;; **** NEXT STAGE ****
					;;
					;;+++++++++++++++++++++++++++++++++
fptrLOL :				;; STAGE the low byte of the low fptr
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_fptrLO		;;
	MOV	cs:fptr_lol,AL		   ;;
	MOV	cs:stage,fptr_lohX	   ;;
	JMP	FTB_LOOP		;;
WORD_fptrLO :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:fptr_low,AX		   ;;
	MOV	cs:stage,fptr_HILX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
fptrLOH :				;; STAGE the high byte of the low fptr
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:fptr_loh,AL		   ;;
	MOV	cs:stage,fptr_HILX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
fptrHIL :				;; STAGE the low byte of the high fptr
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_fptrHI		;;
	MOV	cs:fptr_hil,AL		   ;;
	MOV	cs:stage,fptr_hihX	   ;;
	JMP	FTB_LOOP		;;
WORD_fptrHI :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:fptr_high,AX 	   ;;
	MOV	cs:stage,FPTR_SKIPX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
fptrHIH :				;; STAGE the high byte of the high fptr
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:fptr_hih,AL		   ;;
	MOV	cs:stage,FPTR_SKIPX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
ENTRYLO :				;; STAGE - ENTRY LOW BYTE
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_ENTRY		;;
	MOV	cs:entry_lob,AL 	   ;;
	MOV	cs:stage,ENTRY_HIX	   ;;
	JMP	FTB_LOOP		;;
WORD_ENTRY :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:entry_word,AX	   ;;
	MOV	cs:stage,PASSX		   ;; 2 bytes to be passed
	MOV	cs:pass_postx,NEXT_LOLX    ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
ENTRYHI :				;; stage - ENTRY HIGN BYTE
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:entry_hib,AL 	   ;;
	MOV	cs:stage,PASSX		   ;; 2 bytes to be passed
	MOV	cs:pass_postx,NEXT_LOLX    ;;
	AND	CX,CX			;;
	JNZ	ENTHI_PASS1		;;
	JMP	FTB_LOOP		;;
ENTHI_PASS1 :				;;
	INC	SI			;;
	INC	cs:pass_cnt		   ;;
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	ENTHI_PASS2		;;
	JMP	FTB_LOOP		;;
ENTHI_PASS2 :				;;
	INC	SI			;;
	INC	cs:pass_cnt		   ;;
	DEC	CX			;;
	MOV	cs:stage,NEXT_LOLX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
NEXTLOL :				;; STAGE the low byte of the low NEXT
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_NEXTLO		;;
	MOV	cs:next_lol,AL		   ;;
	MOV	cs:stage,NEXT_LOHX	   ;;
	JMP	FTB_LOOP		;;
WORD_NEXTLO :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:next_low,AX		   ;;
	MOV	cs:stage,next_hilX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
NEXTLOH :				;; STAGE the high byte of the low NEXT
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:next_loh,AL		   ;;
	MOV	cs:stage,next_hilX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
NEXTHIL :				;; STAGE the low byte of the high NEXT
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_NEXTHI		;;
	MOV	cs:next_hil,AL		   ;;
	MOV	cs:stage,NEXT_HIHX	   ;;
	JMP	FTB_LOOP		;;
WORD_NEXTHI :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:next_high,AX 	   ;;
	MOV	cs:stage,type_lobX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
NEXTHIH :				;; STAGE the high byte of the high NEXT
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:next_hih,AL		   ;;
	MOV	cs:stage,type_lobX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
TYPELO	:				;; STAGE the low byte of the TYPE
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_TYPE		;;
	MOV	cs:type_lob,AL		   ;;
	MOV	cs:stage,type_hibX	   ;;
	JMP	FTB_LOOP		;;
WORD_TYPE :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:type_word,AX 	   ;;
	MOV	cs:stage,type_idX	   ;;
	MOV	cs:tid_cnt,0		   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
TYPEHI	:				;; STAGE the high byte of the TYPE
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:type_hib,AL		   ;;
	MOV	cs:stage,TYPE_IDX	   ;;
	MOV	cs:tid_cnt,0		   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
TYPEIDS :				;; STAGE the type id
	CMP	cs:tid_cnt,8		   ;;
	JNA	VALID_TID		;;
	MOV	FTP.FTB_STATUS,STAT_DEVERR
	MOV	cs:fp_error,00021H	   ;; ERROR 0021H
	ADD	SI,CX			;;
	SUB	CX,CX			;;
	JMP	FTB_LOOP		;;
					;;
VALID_TID :				;;
	MOV	AX,8			;;
	SUB	AX,cs:tid_cnt		   ;;
	CMP	CX,AX			;;
	JNB	TID_ALL 		;;
					;; all data in FPKT are stored
	PUSH	ES			;;
	PUSH	CS			;;
	POP	ES			;;
					;;
	MOV	DI,OFFSET TYPE_ID	;;
	ADD	DI,cs:tid_cnt		   ;;
	ADD	cs:tid_cnt,CX		   ;;
	REP	MOVSB			;; SI is incremented accordingly
	POP	ES			;;
					;;
	MOV	CX,0			;; STAGE remained
	JMP	FTB_LOOP		;;
TID_ALL :				;;
	PUSH	CX			;;
					;;
	PUSH	ES			;;
	PUSH	CS			;;
	POP	ES			;;
					;;
	MOV	DI,OFFSET TYPE_ID	;;
	ADD	DI,cs:tid_cnt		   ;;
	MOV	CX,AX			;;
	REP	MOVSB			;; SI is incremented accordingly
	POP	ES			;;
					;;
	ADD	cs:tid_cnt,AX		   ;;
	POP	CX			;;
	SUB	CX,AX			;;
					;;
	MOV	cs:stage,CPG_LOBX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
CPGLO	:				;; STAGE the low byte of the CODE PAGE
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_CPG		;;
	MOV	cs:cpg_lob,AL		   ;;
	MOV	cs:stage,CPG_HIBX	   ;;
	JMP	FTB_LOOP		;;
WORD_CPG :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:cpg_word,AX		   ;;
	MOV	cs:stage,PASSX		   ;;
	MOV	cs:pass_postx,font_lolX    ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
CPGHI	:				;; STAGE the high byte of the CODE PAGE
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:cpg_hib,AL		   ;;
	MOV	cs:stage,PASSX		   ;;
	MOV	cs:pass_postx,font_lolX    ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTLOL :				;; STAGE the low byte of the low FONT
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_FONTLO		;;
	MOV	cs:font_lol,AL		   ;;
	MOV	cs:stage,FONT_LOHX	   ;;
	JMP	FTB_LOOP		;;
WORD_FONTLO :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:font_low,AX		   ;;
	MOV	cs:stage,FONT_HILX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTLOH :				;; STAGE the high byte of the low FONT
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:font_loh,AL		   ;;
	MOV	cs:stage,FONT_HILX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTHIL :				;; STAGE the low byte of the high FONT
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_FONTHI		;;
	MOV	cs:font_hil,AL		   ;;
	MOV	cs:stage,FONT_HIHX	   ;;
	JMP	FTB_LOOP		;;
WORD_FONTHI :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:font_high,AX 	   ;;
;;;;;;	MOV	cs:stage,MOD_LOBX	   ;; end of SCAN
					;; anymore headers to be processed ?
	MOV	cs:stage,MATCHX 	   ;;
	MOV	AX,cs:entry_word	   ;;
	DEC	AX			;;
	MOV	cs:entry_word,AX	   ;;
	AND	AX,AX			;;
	JNZ	CHECK_NEXT		;;
					;; no more header to be processed !
	MOV	AX,-1			;;
	MOV	cs:next_low,AX		   ;;
	MOV	cs:next_high,AX 	   ;; as ENTRY has been consumed
	JMP	FTB_LOOP		;;
					;;
CHECK_NEXT :				;;
	MOV	AX,cs:next_low		   ;;
	AND	AX,AX			;;
	JNZ	MORE_HEADER		;;
	MOV	AX,cs:next_high 	   ;;
	AND	AX,AX			;;
	JNZ	MORE_HEADER		;;
					;; no more header to be processed !
	MOV	AX,-1			;;
	MOV	cs:next_low,AX		   ;; as NEXT is nil
	MOV	cs:next_high,AX 	   ;;
					;;
MORE_HEADER :				;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTHIH :				;; STAGE the high byte of the high FONT
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:font_hih,AL		   ;;
;;;;;	MOV	cs:stage,MOD_LOBX	   ;; end of SCAN
					;;
	MOV	cs:stage,MATCHX 	   ;;
					;; anymore headers to be processed ?
	MOV	AX,cs:entry_word	   ;;
	DEC	AX			;;
	MOV	cs:entry_word,AX	   ;;
	AND	AX,AX			;;
	JNZ	CHECK_NEXT0		;;
					;; no more header to be processed !
	MOV	AX,-1			;;
	MOV	cs:next_low,AX		   ;;
	MOV	cs:next_high,AX 	   ;; as ENTRY has been consumed
	JMP	FTB_LOOP		;;
					;;
CHECK_NEXT0 :				;;
	MOV	AX,cs:next_low		   ;;
	AND	AX,AX			;;
	JNZ	MORE_HEADER0		;;
	MOV	AX,cs:next_high 	   ;;
	AND	AX,AX			;;
	JNZ	MORE_HEADER0		;;
					;; no more header to be processed !
	MOV	AX,-1			;;
	MOV	cs:next_low,AX		   ;; as NEXT is nil
	MOV	cs:next_high,AX 	   ;;
					;;
MORE_HEADER0 :				;;
	JMP	FTB_LOOP		;;
					;;
					;;+++++++++++++++++++++++++++++++++
MODLO	:				;; STAGE the low byte of the MODIFIER
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_MOD		;;
	MOV	MOD_LOB,AL		;;
	MOV	cs:stage,MOD_HIBX	   ;;
	JMP	FTB_LOOP		;;
WORD_MOD :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:mod_word,AX		   ;;
	MOV	cs:stage,fonts_lobX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
MODHI	:				;; STAGE the high byte of the MODIFIER
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:mod_hib,AL		   ;;
	MOV	cs:stage,FONTS_LOBX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTSLO :				;; STAGE the low byte of the FONTS
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_FONTS		;;
	MOV	cs:fonts_lob,AL 	   ;;
	MOV	cs:stage,FONTS_HIBX	   ;;
	JMP	FTB_LOOP		;;
WORD_FONTS :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:fonts_word,AX	   ;;
	MOV	cs:stage,FDLEN_LOBX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTSHI :				;; STAGE the high byte of the FONTS
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:fonts_hib,AL 	   ;;
	MOV	cs:stage,FDLEN_LOBX	   ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FDLENLO :				;; the low byte of the FONT-LENGTH
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_FDLEN		;;
	MOV	cs:fdlen_lob,AL 	   ;;
	MOV	cs:stage,FDLEN_HIBX	   ;;
	JMP	FTB_LOOP		;;
WORD_FDLEN :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	cs:pre_font_len,PRE_FONT_ND;;
	MOV	cs:fdlen_word,AX	   ;;
;	AND	AX,AX			;;
;	JZ	NO_DISP_PTR		;;
;	CMP	cs:type_word,TYPE_DISPLAY  ;;
;	JE	DISPLAY_TYPE1		;;
;	CMP	cs:type_word,TYPE_PRINTER  ;;
;	JE	PRINTER_TYPE1		;;
					;;
;NO_DISP_PTR :				 ;;
	MOV	cs:stage,FOUNDX 	   ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
;DISPLAY_TYPE1 :			 ;;
;	MOV	cs:stage,DISP_ROWSX	   ;;
;	JMP	FTB_LOOP		;;
;PRINTER_TYPE1 :			 ;;
;	 MOV	 cs:stage,PTRSELLOX	    ;;
;	 JMP	 FTB_LOOP		 ;;
					;;
					;;+++++++++++++++++++++++++++++++++
FDLENHI :				;; STAGE the high byte of the F-LENGTH
	MOV	cs:pre_font_len,PRE_FONT_ND
	MOV	AX,FPKT 		;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	cs:fdlen_hib,AL 	   ;;
	MOV	AX,cs:fdlen_word	   ;;
;	AND	AX,AX			;;
;	JZ	NO_DISP_PTR2		;;
;	CMP	cs:type_word,TYPE_DISPLAY  ;;
;	JE	DISPLAY_TYPE2		;;
;	 CMP	 cs:type_word,TYPE_PRINTER  ;;
;	 JE	 PRINTER_TYPE2		 ;;
;NO_DISP_PTR2:				 ;;
	MOV	cs:stage,FOUNDX 	   ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
;DISPLAY_TYPE2 :			 ;;
;	MOV	cs:stage,DISP_ROWSX	   ;;
;	JMP	FTB_LOOP		;;
;PRINTER_TYPE2 :			 ;;
;	 MOV	 cs:stage,PTRSELLOX	    ;;
;	 JMP	 FTB_LOOP		 ;;
					;;
					;;+++++++++++++++++++++++++++++++++
DSPROWS :				;; STAGE : get the rows
;	XOR	AX,AX			;;
;	MOV	cs:disp_rows,AL 	   ;;
;	MOV	cs:disp_cols,AL 	   ;;
;	MOV	cs:DISP_X,AL		   ;;
;	MOV	cs:disp_y,AL		   ;;
;	MOV	cs:count_word,AX	   ;;
;					;;
;	INC	cs:pre_font_len 	  ;;
;	MOV	AX,FPKT 		;;
;	INC	SI			;;
;	DEC	CX			;;
;	MOV	cs:disp_rows,AL 	   ;;
;	MOV	AX,cs:fdlen_word	   ;;
;	DEC	AX			;;
;	MOV	cs:fdlen_word,AX	   ;;
;	JZ	NO_DISP_FONT3		;;
;	MOV	cs:stage,disp_colsX	   ;;
;	JMP	FTB_LOOP		;;
;NO_DISP_FONT3 :			 ;;
;	MOV	cs:stage,FOUNDX 	   ;; FSTAT is to be changed
;	JMP	FTB_LOOP		;;
;					;;+++++++++++++++++++++++++++++++++
DSPCOLS :				;; STAGE : get the COLS
;	INC	cs:pre_font_len 	  ;;
;	MOV	AX,FPKT 		;;
;	INC	SI			;;
;	DEC	CX			;;
;	MOV	cs:disp_cols,AL 	   ;;
;	MOV	AX,cs:fdlen_word	   ;;
;	DEC	AX			;;
;	MOV	cs:fdlen_word,AX	   ;;
;	JZ	NO_DISP_FONT3		;;
;	MOV	cs:stage,DISP_XX	   ;;
;	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
 DSPX : 				 ;; STAGE : get the aspect X
;	INC	cs:pre_font_len 	  ;;
;	MOV	AX,FPKT 		;;
;	INC	SI			;;
;	DEC	CX			;;
;	MOV	DISP_X,AL		;;
;	MOV	AX,cs:fdlen_word	   ;;
;	DEC	AX			;;
;	MOV	cs:fdlen_word,AX	   ;;
;	JZ	NO_DISP_FONT3		;;
;	MOV	cs:stage,DISP_YX	   ;;
;	JMP	FTB_LOOP		;;
;					;;+++++++++++++++++++++++++++++++++
 DSPY : 				 ;; STAGE : get the aspect Y
;	INC	cs:pre_font_len 	  ;;
;	MOV	AX,FPKT 		;;
;	INC	SI			;;
;	DEC	CX			;;
;	MOV	cs:disp_y,AL		   ;;
;	MOV	AX,cs:fdlen_word	   ;;
;	DEC	AX			;;
;	MOV	cs:fdlen_word,AX	   ;;
;	JZ	NO_DISP_FONT3		;;
;	MOV	cs:stage,COUNT_LOBX	   ;;
;	JMP	FTB_LOOP		;;
;					;;
					;;+++++++++++++++++++++++++++++++++
 DSPCOUNTLO :				 ;; the low byte of the FONT-LENGTH
;	INC	cs:pre_font_len 	  ;;
;	MOV	AX,FPKT 		;;
;	INC	SI			;; byte by byte
;	DEC	CX			;;
;	PUSH	AX			;; check if length is enough
;	MOV	AX,cs:fdlen_word	   ;;
;	DEC	AX			;;
;	MOV	cs:fdlen_word,AX	   ;;
;	POP	AX			;;
;	JNZ	A_WORD_COUNT		;;
;	JMP	NO_DISP_FONT3		;;
;A_WORD_COUNT : 			 ;;
;	AND	CX,CX			;;
;	JNZ	WORD_COUNT		;;
;	MOV	cs:count_lob,AL 	   ;;
;	MOV	cs:stage,COUNT_HIBX	   ;;
;	JMP	FTB_LOOP		;;
;WORD_COUNT :				 ;;
;	INC	cs:pre_font_len 	  ;;
;	INC	SI			;;
;	DEC	CX			;;
;	MOV	cs:count_word,AX	   ;;
;	MOV	cs:pre_font_len,PRE_FONT_D;
					;;
;	MOV	AX,cs:fdlen_word	   ;;
;	DEC	AX			;;
;	MOV	cs:fdlen_word,AX	   ;;
;	MOV	cs:stage,FOUNDX 	   ;; FSTAT is to be changed
;	JMP	FTB_LOOP		;;
;					;;
;					;;+++++++++++++++++++++++++++++++++
 DSPCOUNTHI :				 ;; STAGE the high byte of the F-LENGTH
;	INC	cs:pre_font_len 	  ;;
;	MOV	AX,FPKT 		;;
;	INC	SI			;; byte by byte
;	DEC	CX			;;
;	MOV	cs:count_hib,AL 	   ;;
;	MOV	cs:pre_font_len,PRE_FONT_D;
					;;
;	MOV	AX,cs:fdlen_word	   ;;
;	DEC	AX			;;
;	MOV	cs:fdlen_word,AX	   ;;
;	MOV	cs:stage,FOUNDX 	   ;; FSTAT is to be changed
;	JMP	FTB_LOOP		;;
;					;;
					;;
					;;+++++++++++++++++++++++++++++++++
PTRSELLO :				;; the low byte of the SELECTION_TYPE
					;;
;	 INC	 cs:pre_font_len	   ;;
;	 MOV	 AX,FPKT		 ;;
;	 INC	 SI			 ;; byte by byte
;	 DEC	 CX			 ;;
;	 PUSH	 AX			 ;; check if length is enough
;	 MOV	 AX,cs:fdlen_word	    ;;
;	 DEC	 AX			 ;;
;	 MOV	 cs:fdlen_word,AX	    ;;
;	 POP	 AX			 ;;
;	 JNZ	 A_WORD_SEL		 ;;
;	 JMP	 NO_PTR_FONT3		 ;;
;A_WORD_SEL :				 ;;
;	 AND	 CX,CX			 ;;
;	 JNZ	 WORD_SEL		 ;;
;	 MOV	 cs:ptr_selob,AL	    ;;
;	 MOV	 cs:stage,PTRSELHIX	    ;;
;	 JMP	 FTB_LOOP		 ;;
;WORD_SEL :				 ;;
;	 INC	 cs:pre_font_len	    ;;
;	 INC	 SI			 ;;
;	 DEC	 CX			 ;;
;	 MOV	 cs:ptr_sel_word,AX	    ;;
;					 ;;
;	 MOV	 AX,cs:fdlen_word	    ;;
;	 DEC	 AX			 ;;
;	 MOV	 cs:fdlen_word,AX	    ;;
;					 ;;
;	 CMP	 cs:ptr_sel_word,0	    ;;
;	 JNE	 PTR_SEL_NOT0		 ;;
;					 ;;
;					 ;;
;	 MOV	 cs:stage,FOUNDX	    ;; FSTAT is to be changed
;	 JMP	 FTB_LOOP		 ;;
;					 ;;
;PTR_SEL_NOT0 : 			 ;;
;	 MOV	 cs:stage,PTRLENLOX	    ;;
;	 JMP	 FTB_LOOP		 ;;
;					 ;;
					;;+++++++++++++++++++++++++++++++++
PTRSELHI:				;; STAGE the high byte of SELECT_TYPE
					;;
;	 INC	 cs:pre_font_len	   ;;
;	 MOV	 AX,FPKT		 ;;
;	 INC	 SI			 ;; byte by byte
;	 DEC	 CX			 ;;
;	 MOV	 cs:ptr_sehib,AL	    ;;
;					 ;;
;	 MOV	 AX,cs:fdlen_word	    ;;
;	 DEC	 AX			 ;;
;	 MOV	 cs:fdlen_word,AX	    ;;
;					 ;;
;	 CMP	 cs:ptr_sel_word,0	    ;;
;	 JNE	 PTR_SEL_NOT0		 ;;
;					 ;;
;					 ;;
;	 MOV	 cs:stage,FOUNDX	    ;; FSTAT is to be changed
;	 JMP	 FTB_LOOP		 ;;
;					 ;;
;					 ;;
					;;+++++++++++++++++++++++++++++++++
PTRLENLO :				;; the low byte of SELECTION_LENGTH
					;;
;	 INC	 cs:pre_font_len	   ;;
;	 MOV	 AX,FPKT		 ;;
;	 INC	 SI			 ;; byte by byte
;	 DEC	 CX			 ;;
;	 PUSH	 AX			 ;; check if length is enough
;	 MOV	 AX,cs:fdlen_word	    ;;
;	 DEC	 AX			 ;;
;	 MOV	 cs:fdlen_word,AX	    ;;
;	 POP	 AX			 ;;
;	 JNZ	 A_WORD_SELEN		 ;;
;	 JMP	 NO_PTR_FONT3		 ;;
;A_WORD_SELEN : 			 ;;
;	 AND	 CX,CX			 ;;
;	 JNZ	 WORD_SELEN		 ;;
;	 MOV	 cs:ptr_lnlob,AL	    ;;
;	 MOV	 cs:stage,PTRLENHIX	    ;;
;	 JMP	 FTB_LOOP		 ;;
;WORD_SELEN :				 ;;
;	 INC	 cs:pre_font_len	    ;;
;	 INC	 SI			 ;;
;	 DEC	 CX			 ;;
;	 MOV	 cs:ptr_len_word,AX	    ;;
;					 ;;
;	 MOV	 AX,cs:fdlen_word	    ;;
;	 DEC	 AX			 ;;
;	 MOV	 cs:fdlen_word,AX	    ;;
;	 MOV	 cs:stage,FOUNDX	    ;; FSTAT is to be changed
;	 JMP	 FTB_LOOP		 ;;
;					 ;;
					 ;;+++++++++++++++++++++++++++++++++
 PTRLENHI :				 ;; STAGE the high byte of SELECT_LENGTH
					 ;;
	SUB	CX,CX			 ;D; added for DISPLAY.SYS version
	MOV	CS:STAGE,STAGE_MAX+1	 ;D; added for DISPLAY.SYS version
	JMP	FTB_LOOP		 ;D; added for DISPLAY.SYS version
					 ;;
					 ;;
;	 INC	 cs:pre_font_len	   ;;
;	 MOV	 AX,FPKT		 ;;
;	 INC	 SI			 ;; byte by byte
;	 DEC	 CX			 ;;
;	 MOV	 cs:ptr_lnhib,AL	    ;;
;					 ;;
;	 MOV	 AX,cs:fdlen_word	    ;;
;	 DEC	 AX			 ;;
;	 MOV	 cs:fdlen_word,AX	    ;;
;	 MOV	 cs:stage,FOUNDX	    ;; FSTAT is to be changed
;	 JMP	 FTB_LOOP		 ;;
;					 ;;
;NO_PTR_FONT3 : 			 ;;
;	 MOV	 cs:stage,FOUNDX	    ;; FSTAT is to be changed
;	 JMP	 FTB_LOOP		 ;;
					;;+++++++++++++++++++++++++++++++++
PASS	:				;; STAGE - PASS DUMMY BYTES
					;;
	PUSH	DX			;;
	PUSH	ES			;;
	PUSH	DI			;;
					;;
	PUSH	CS			;;
	POP	ES			;;
	MOV	DI,OFFSET PASS_BRK	;;
	MOV	DX,PASS_INDX		;;
	MOV	AX,cs:pass_cnt		   ;;
					;;
NEXT_BRK:				;; find the next pass-break
	CMP	AX,ES:[DI]		;;
					;;
	JB	UPTO_BRK		;;
					;;
	DEC	DX			;;
	JZ	PASS_ERR		;;
	INC	DI			;;
	INC	DI			;;
	JMP	NEXT_BRK		;;
					;;
UPTO_BRK :				;; next break point found
	MOV	DX,ES:[DI]		;;
	SUB	DX,AX			;; bytes to be skipped
	CMP	CX,DX			;; all to be skipped ?
	JAE	PASS_ALL		;;
					;;
	ADD	cs:pass_cnt,CX		   ;;
	ADD	SI,CX			;;
	SUB	CX,CX			;;
	JMP	PASS_END		;;
					;;
PASS_ALL :				;;
	ADD	cs:pass_cnt,DX		   ;;
	ADD	SI,DX			;;
	SUB	CX,DX			;;
					;;
	MOV	AX,cs:pass_postx	   ;;
	MOV	cs:stage,AX		   ;;
					;;
;	cmp	ax,passx		;; is the next stage a pass-stage ?
;	jne	not_passx		;;
;	mov	ax,pass_postxx		;;
;	mov	pass_postx,ax		;;
;	mov	pass_postxx,stage_max	;; can support only 2 consecutive pass
					;;
;not_passx :				 ;;
					;;
	JMP	PASS_END		;;
					;;
PASS_ERR :				;; DEVICE ERROR, wrong stage
	POP	DI			;;
	POP	ES			;;
	POP	DX			;;
	MOV	FTP.FTB_STATUS,STAT_DEVERR
	SUB	CX,CX			;; ignore all the input string
	JMP	PASS_DONE		;;
					;;
PASS_END :				;;
	POP	DI			;;
	POP	ES			;;
	POP	DX			;;
PASS_DONE :				;;
	JMP	FTB_LOOP		;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
FTB_LPEND :				;;
					;;
	CMP	cs:stage,FOUNDX 	   ;;
	JNE	NOT_FOUNDX		;;
					;;
	CALL	FOUND_DO		;;
					;;
NOT_FOUNDX :				;;
					;;
	POP	CX			;; STACK -1
					;;
FP_RET	:				;;
	POP	SI			;; restore registers
	POP	DI			;;
	POP	DX			;;
	POP	CX			;;
	POP	BX			;;
	POP	AX			;;
	POP	ES			;;
	POP	DS			;;
					;;
	RET				;;
FONT_PARSER ENDP			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
