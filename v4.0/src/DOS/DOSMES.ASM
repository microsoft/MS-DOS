;	SCCSID = @(#)dosmes.asm 1.7 85/10/23
;	SCCSID = @(#)dosmes.asm 1.7 85/10/23
;
; Message file for Internationalized messages.	There is
; only one message here available for translation.
;
;
;    Revision history
;	  A000	  version 4.00  Jan. 1988
;

IFNDEF	KANJI
KANJI	EQU	FALSE
ENDIF

IFNDEF	Rainbow
Rainbow EQU FALSE
ENDIF

include dossym.inc
include dosmac.inc
include doscntry.inc

CONSTANTS	SEGMENT WORD PUBLIC 'CONST'

    PUBLIC  UserNum, OEMNum
    Public DMES001S,DMES001E
DMES001S Label byte
USERNUM DW	?			; 24 bit user number
	DB	?
IF	IBM
	IF	IBMCOPYRIGHT
	OEMNUM	DB	0			; 8 bit OEM number
	ELSE
	OEMNUM	DB	0FFH			; 8 bit OEM number
	ENDIF
ELSE
OEMNUM	DB	0FFH
ENDIF


DMES001E label byte
CONSTANTS	ENDS

TABLE		SEGMENT BYTE PUBLIC 'TABLE'
Public DMES002S
DMES002S  label byte


; The following table is used for DOS 3.3
;DOS country and code page information is defined here for DOS 3.3.
;The initial value for ccDosCountry is 1 (USA).
;The initial value for ccDosCodepage is 850.
;
;
		   PUBLIC  COUNTRY_CDPG,UCASE_TAB,FILE_UCASE_TAB
		   PUBLIC  FILE_CHAR_TAB
;
; country and code page infomation
;
COUNTRY_CDPG  label  byte

	 db   0,0,0,0,0,0,0,0	      ; reserved words
	 db   '\COUNTRY.SYS',0        ; path name of country.sys
	 db   51 dup (?)
	 dw   437		      ; system code page id
	 dw   6 		      ; number of entries
	 db   SetUcase		      ; Ucase type
	 dw   OFFSET DOSGROUP:UCASE_TAB    ;pointer to upper case table
	 dw   0 			   ; segment of poiter
	 db   SetUcaseFile	      ; Ucase file char type
	 dw   OFFSET DOSGROUP:FILE_UCASE_TAB	;pointer to file upper case table
	 dw   0 			   ; segment of poiter
	 db   SetFileList	      ; valid file chars type
	 dw   OFFSET DOSGROUP:FILE_CHAR_TAB   ;pointer to valid file char tab
	 dw   0 			   ; segment of poiter
	 db   SetCollate	      ; collate type
	 dw   OFFSET DOSGROUP:COLLATE_TAB  ;pointer to collate table
	 dw   0 			   ; segment of poiter
	 db   SetDBCS		      ;AN000; DBCS Ev			  2/12/KK
	 dw   OFFSET DOSGROUP:DBCS_TAB ;AN000;;pointer to DBCS Ev table   2/12/KK
	 dw   0 		       ;AN000; segment of poiter	 2/12/KK
	 db   SetCountryInfo	      ; country info type
	 dw   NEW_COUNTRY_SIZE	      ; extended country info size
	 dw   1 		      ; USA country id
	 dw   437		      ; USA system code page id
	 dw   0 		      ; date format
	 db   '$',0,0,0,0             ; currency symbol
	 db   ',',0                   ; thousand separator
	 db   '.',0                   ; decimal separator
	 db   '-',0                   ; date separator
	 db   ':',0                   ; time separator
	 db   0 		      ; currency format flag
	 db   2 		      ; # of disgit in currency
	 db   0 		      ; time format
	 dw   OFFSET DOSGROUP:MAP_CASE	;mono case routine entry point
	 dw   0 			; segment of entry point
	 db   ',',0                    ; data list separator
	 dw   0,0,0,0,0 	       ; reserved



;
;
;
;
;
; upper case table
;
UCASE_TAB    label   byte
		    dw	128
		    db	128,154,069,065,142,065,143,128
		    db	069,069,069,073,073,073,142,143
		    db	144,146,146,079,153,079,085,085
		    db	089,153,154,155,156,157,158,159
		    db	065,073,079,085,165,165,166,167
		    db	168,169,170,171,172,173,174,175
		    db	176,177,178,179,180,181,182,183
		    db	184,185,186,187,188,189,190,191
		    db	192,193,194,195,196,197,198,199
		    db	200,201,202,203,204,205,206,207
		    db	208,209,210,211,212,213,214,215
		    db	216,217,218,219,220,221,222,223
		    db	224,225,226,227,228,229,230,231
		    db	232,233,234,235,236,237,238,239
		    db	240,241,242,243,244,245,246,247
		    db	248,249,250,251,252,253,254,255

;
; file upper case table
;
FILE_UCASE_TAB	label  byte
		    dw	128
		    db	128,154,069,065,142,065,143,128
		    db	069,069,069,073,073,073,142,143
		    db	144,146,146,079,153,079,085,085
		    db	089,153,154,155,156,157,158,159
		    db	065,073,079,085,165,165,166,167
		    db	168,169,170,171,172,173,174,175
		    db	176,177,178,179,180,181,182,183
		    db	184,185,186,187,188,189,190,191
		    db	192,193,194,195,196,197,198,199
		    db	200,201,202,203,204,205,206,207
		    db	208,209,210,211,212,213,214,215
		    db	216,217,218,219,220,221,222,223
		    db	224,225,226,227,228,229,230,231
		    db	232,233,234,235,236,237,238,239
		    db	240,241,242,243,244,245,246,247
		    db	248,249,250,251,252,253,254,255

;
; file char list
;
FILE_CHAR_TAB  label  byte
		dw	22				; length
		db	1,0,255 			; include all
		db	0,0,20h 			; exclude 0 - 20h
		db	2,14,'."/\[]:|<>+=;,'           ; exclude 14 special
		db	24 dup (?)			; reserved
;
; collate table
;
COLLATE_TAB    label   byte
		dw	256
	db	0,1,2,3,4,5,6,7
	db	8,9,10,11,12,13,14,15
	db	16,17,18,19,20,21,22,23
	db	24,25,26,27,28,29,30,31
	db	" ","!",'"',"#","$","%","&","'"
	db	"(",")","*","+",",","-",".","/"
	db	"0","1","2","3","4","5","6","7"
	db	"8","9",":",";","<","=",">","?"
	db	"@","A","B","C","D","E","F","G"
	db	"H","I","J","K","L","M","N","O"
	db	"P","Q","R","S","T","U","V","W"
	db	"X","Y","Z","[","\","]","^","_"
	db	"`","A","B","C","D","E","F","G"
	db	"H","I","J","K","L","M","N","O"
	db	"P","Q","R","S","T","U","V","W"
	db	"X","Y","Z","{","|","}","~",127
	db	"C","U","E","A","A","A","A","C"
	db	"E","E","E","I","I","I","A","A"
	db	"E","A","A","O","O","O","U","U"
	db	"Y","O","U","$","$","$","$","$"
	db	"A","I","O","U","N","N",166,167
	db	"?",169,170,171,172,"!",'"','"'
	db	176,177,178,179,180,181,182,183
	db	184,185,186,187,188,189,190,191
	db	192,193,194,195,196,197,198,199
	db	200,201,202,203,204,205,206,207
	db	208,209,210,211,212,213,214,215
	db	216,217,218,219,220,221,222,223
	db	224,"S"
	db	226,227,228,229,230,231
	db	232,233,234,235,236,237,238,239
	db	240,241,242,243,244,245,246,247
	db	248,249,250,251,252,253,254,255
;
; dbcs is not supported in DOS 3.3
;		   DBCS_TAB	    CC_DBCS <>
;
; DBCS for DOS 4.00			   2/12/KK
   PUBLIC    DBCS_TAB
DBCS_TAB	label byte		;AN000;  2/12/KK
		dw	0		;AN000;  2/12/KK      max number
		db	16 dup(0)	;AN000;  2/12/KK

;		dw	6		;  2/12/KK
;		db	081h,09fh	;  2/12/KK
;		db	0e0h,0fch	;  2/12/KK
;		db	0,0		;  2/12/KK
;
;
include divmes.asm
include yesno.asm

TABLE		ENDS

CODE		SEGMENT BYTE PUBLIC 'CODE'
ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;CASE MAPPER ROUTINE FOR 80H-FFH character range, DOS 3.3
;     ENTRY: AL = Character to map
;     EXIT:  AL = The converted character
; Alters no registers except AL and flags.
; The routine should do nothing to chars below 80H.
;
; Example:

Procedure   MAP_CASE,FAR
	CMP	AL,80H
	JAE	Map1		;Map no chars below 80H ever
	RET
Map1:
	SUB	AL,80H		;Turn into index value
	PUSH	DS
	PUSH	BX
	MOV	BX,OFFSET DOSGROUP:UCASE_TAB + 2
FINISH:
	PUSH	CS		;Move to DS
	POP	DS
	XLAT	ds:[bx] 	;Get upper case character
	POP	BX
	POP	DS
L_RET:	RET
EndProc MAP_CASE

SUBTTL EDIT FUNCTION ASSIGNMENTS AND HEADERS
PAGE
; The following two tables implement the current buffered input editing
; routines.  The tables are pairwise associated in reverse order for ease
; in indexing.	That is; The first entry in ESCTAB corresponds to the last
; entry in ESCFUNC, and the last entry in ESCTAB to the first entry in ESCFUNC.


TABLE	SEGMENT
	PUBLIC	CANCHAR
CANCHAR DB	CANCEL			;Cancel line character
	PUBLIC	ESCCHAR
ESCCHAR DB	ESCCH			;Lead-in character for escape sequences
	IF	NOT Rainbow
ESCTAB	LABEL BYTE
	IF	NOT IBM
	IF	WANG
	DB	0C0h			; ^Z inserter
	DB	0C1H			; Copy one char
	DB	0C1H			; Copy one char
	DB	0C7H			; Skip one char
	DB	08AH			; Copy to char
	DB	088H			; Skip to char
	DB	09AH			; Copy line
	DB	0CBH			; Kill line (no change in template)
	DB	08BH			; Reedit line (new template)
	DB	0C3H			; Backspace
	DB	0C6H			; Enter insert mode
	DB	0D6H			; Exit insert mode
	DB	0C6H			; Escape character
	DB	0C6H			; End of table
	ELSE
					; VT52 equivalences
	DB	"Z"                     ; ^Z inserter
	DB	"S"                     ; F1 Copy one char
	DB	"S"                     ; F1 Copy one char
	DB	"V"                     ; F4 Skip one char
	DB	"T"                     ; F2 Copy to char
	DB	"W"                     ; F5 Skip to char
	DB	"U"                     ; F3 Copy line
	DB	"E"                     ; SHIFT ERASE Kill line (no change in template)
	DB	"J"                     ; ERASE Reedit line (new template)
	DB	"D"                     ; LEFT Backspace
	DB	"P"                     ; BLUE Enter insert mode
	DB	"Q"                     ; RED Exit insert mode
	DB	"R"                     ; GRAY Escape character
	DB	"R"                     ; End of table
	ENDIF
	ENDIF
	IF	IBM
	DB	64			; Ctrl-Z - F6
	DB	77			; Copy one char - -->
	DB	59			; Copy one char - F1
	DB	83			; Skip one char - DEL
	DB	60			; Copy to char - F2
	DB	62			; Skip to char - F4
	DB	61			; Copy line - F3
	DB	61			; Kill line (no change to template ) - Not used
	DB	63			; Reedit line (new template) - F5
	DB	75			; Backspace - <--
	DB	82			; Enter insert mode - INS (toggle)
	DB	82			; Exit insert mode - INS (toggle)
	DB	65			; Escape character - F7
	DB	65			; End of table
	ENDIF
ESCEND LABEL BYTE
ESCTABLEN EQU	ESCEND-ESCTAB

ESCFUNC LABEL	WORD
	short_addr  GETCH		; Ignore the escape sequence
	short_addr  TWOESC
	short_addr  EXITINS
	short_addr  ENTERINS
	short_addr  BACKSP
	short_addr  REEDIT
	short_addr  KILNEW
	short_addr  COPYLIN
	short_addr  SKIPSTR
	short_addr  COPYSTR
	short_addr  SKIPONE
	short_addr  COPYONE
	short_addr  COPYONE
	short_addr  CTRLZ
	ENDIF
TABLE	ENDS

;
; OEMFunction key is expected to process a single function
;   key input from a device and dispatch to the proper
;   routines leaving all registers UNTOUCHED.
;
; Inputs:   CS, SS are DOSGROUP
; Outputs:  None. This function is expected to JMP to one of
;	    the following labels:
;
;	    GetCh	- ignore the sequence
;	    TwoEsc	- insert an ESCChar in the buffer
;	    ExitIns	- toggle insert mode
;	    EnterIns	- toggle insert mode
;	    BackSp	- move backwards one space
;	    ReEdit	- reedit the line with a new template
;	    KilNew	- discard the current line and start from scratch
;	    CopyLin	- copy the rest of the template into the line
;	    SkipStr	- read the next character and skip to it in the template
;	    CopyStr	- read next char and copy from template to line until char
;	    SkipOne	- advance position in template one character
;	    CopyOne	- copy next character in template into line
;	    CtrlZ	- place a ^Z into the template
; Registers that are allowed to be modified by this function are:
;	    AX, CX, BP

Procedure   OEMFunctionKey,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING,SS:DOSGROUP
 IF  DBCS				;AN000;
extrn	intCNE0:near			;AN000; 2/17/KK
	CALL	intCNE0 		;AN000; 2/17/KK
 ELSE					;AN000;
	invoke	$std_con_input_no_echo	; Get the second byte of the sequence
 ENDIF					;AN000;
	IF NOT Rainbow
	MOV	CL,ESCTABLEN		; length of table for scan
	PUSH	DI			; save DI (cannot change it!)
	MOV	DI,OFFSET DOSGROUP:ESCTAB   ; offset of second byte table
	REPNE	SCASB			; Look it up in the table
	POP	DI			; restore DI
	SHL	CX,1			; convert byte offset to word
	MOV	BP,CX			; move to indexable register
	JMP	[BP+OFFSET DOSGROUP:ESCFUNC]	; Go to the right routine
	ENDIF
	IF Rainbow

TransferIf  MACRO   value,address
	local	a
	CMP	AL,value
	JNZ	a
	transfer    address
a:
ENDM

	CMP	AL,'['                  ; is it second lead char
	JZ	EatParm 		; yes, go walk tree
GoGetCh:
	transfer    GetCh		; no, ignore sequence
EatParm:
	invoke	$std_con_input_no_echo	; get argument
	CMP	AL,'A'                  ; is it alphabetic arg?
	JAE	EatAlpha		; yes, go snarf one up
	XOR	BP,BP			; init digit counter
	JMP	InDigit 		; jump into internal eat digit routine
EatNum:
	invoke	$std_con_input_no_echo	; get next digit
InDigit:
	CMP	AL,'9'                  ; still a digit?
	JA	CheckNumEnd		; no, go check for end char
	SUB	AL,'0'                  ; turn into potential digit
	JL	GoGetCh 		; oops, not a digit, ignore
	MOV	CX,BP			; save BP for 10 multiply
	CBW				; make AL into AX
	SHL	BP,1			; 2*BP
	SHL	BP,1			; 4*BP
	ADD	BP,CX			; 5*BP
	SHL	BP,1			; 10*BP
	ADD	BP,AX			; 10*BP + digit
	JMP	EatNum			; continue with number
CheckNumEnd:
	CMP	AL,7Eh			; is it end char ~
	JNZ	GoGetCh 		; nope, ignore key sequence
	MOV	AX,BP
	transferIf  1,SkipStr		; FIND key
	transferIf  2,EnterIns		; INSERT HERE key
	transferIf  3,SkipOne		; REMOVE
	transferIf  4,CopyStr		; SELECT
	transferIf  17,TwoEsc		; INTERRUPT
	transferIf  18,ReEdit		; RESUME
	transferIf  19,KilNew		; CANCEL
	transferIf  21,CtrlZ		; EXIT
	transferIf  29,CopyLin		; DO
	JMP	GoGetCh
EatAlpha:
	CMP	AL,'O'                  ; is it O?
	JA	GoGetCh 		; no, after assume bogus
	JZ	EatPQRS 		; eat the rest of the bogus key
	transferIf  'C',CopyOne         ; RIGHT
	transferIf  'D',BackSp          ; LEFT
	JMP	GoGetCh
EatPQRS:
	invoke	$std_con_input_no_echo	; eat char after O
	JMP	GoGetCh
	ENDIF

EndProc OEMFunctionKey

CODE		ENDS

	END
