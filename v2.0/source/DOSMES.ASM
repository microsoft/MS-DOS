	INCLUDE	STDSW.ASM

KANJI   EQU     FALSE

Rainbow EQU FALSE

        INCLUDE DOSSYM.ASM
;
; segment ordering for MSDOS
;

CONSTANTS       SEGMENT BYTE PUBLIC 'CONST'
CONSTANTS       ENDS

DATA            SEGMENT BYTE PUBLIC 'DATA'
DATA            ENDS

CODE            SEGMENT BYTE PUBLIC 'CODE'
CODE            ENDS

LAST            SEGMENT BYTE PUBLIC 'LAST'
LAST            ENDS

DOSGROUP    GROUP   CODE,CONSTANTS,DATA,LAST

CONSTANTS       SEGMENT BYTE PUBLIC 'CONST'

        PUBLIC  DIVMES
DIVMES  DB      13,10,"Divide overflow",13,10

        PUBLIC  DivMesLen
DivMesLen   DB  $-DivMes        ; Length of the above message in bytes


;
; The next variable points to the country table for the current country
;       ( the table returned by the AL=0 INTERNATIONAL call).
;
        PUBLIC  Current_Country

        IF KANJI
Current_Country DW      OFFSET DOSGROUP:JAPTABLE
        ELSE
Current_Country DW      OFFSET DOSGROUP:USTABLE
        ENDIF

;
; The international tabel(s).
; This is simply a sequence of tables of the following form:
;
;               BYTE  Size of this table excluding this byte and the next
;               BYTE  Country code represented by this table
;	                A sequence of n bytes, where n is the number specified
;                       by the first byte above and is not > internat_block_max,
;                       in the correct order for being returned by the
;                       INTERNATIONAL call as follows:
;		WORD	Date format 0=mdy, 1=dmy, 2=ymd
;		5 BYTE	Currency symbol null terminated
;		2 BYTE	thousands separator null terminated
;		2 BYTE	Decimal point null terminated
;		2 BYTE	Date separator null terminated
;		2 BYTE	Time separator null terminated
;		1 BYTE	Bit field.  Currency format.
;			Bit 0.  =0 $ before #  =1 $ after #
;			Bit 1.	no. of spaces between # and $ (0 or 1)
;		1 BYTE	No. of significant decimal digits in currency
;		1 BYTE	Bit field.  Time format.
;			Bit 0.  =0 12 hour clock  =1 24 hour
;		WORD	Segment offset for address of case conversion routine
;		WORD	RESERVED.  Filled in by DOS.  Segment value for above routine
;		2 BYTE	Data list separator null terminated.
;                  NOTE: The segment part of the DWORD Map_call is set
;                       by the INTERNATIONAL call. Do not try to initialize
;                       it to anything meaningful.
;
; The list of tables is terminated by putting a byte of -1 after the last
;       table (a table with length -1).

        PUBLIC  international_table

international_table LABEL       BYTE

        IF KANJI
                    DB  SIZE internat_block   ; Size in bytes of this table
                    DB  81              ; Country code
JAPTABLE internat_block <2,'\',0,0,0,0,',',0,'.',0,'-',0,':',0,0,0,1,OFFSET DOSGROUP:MAP_DCASE , 0,',',0>
        ENDIF

                    DB  SIZE internat_block   ; Size in bytes of this table
                    DB  1               ; Country code
USTABLE internat_block <0,'$',0,0,0,0,',',0,'.',0,'-',0,':',0,0,2,0,OFFSET DOSGROUP:MAP_DCASE,0,',',0>
;	Tables for the IBM PC character set follow.  The values
;	associated with some of the currency symbols may change with
;	other character sets.  You may wish to add or delete country
;	entries.  NOTE: It is not a mistake that the JAPANESE entry
;	has different currency symbols for the KANJI and
;	non-KANJI versions.

IF	NOT	KANJI
IF	IBM
                    DB  SIZE internat_block   ; Size in bytes of this table
                    DB  44              ; Country code
UKTABLE internat_block <1,9Ch,0,0,0,0,',',0,'.',0,'-',0,':',0,0,2,0,OFFSET DOSGROUP:MAP_DCASE,0,',',0>
                    DB  SIZE internat_block   ; Size in bytes of this table
                    DB  49               ; Country code
GRMTABLE internat_block <1,'D','M',0,0,0,'.',0,',',0,'.',0,'.',0,3,2,1,OFFSET DOSGROUP:MAP_DCASE,0,';',0>
                    DB  SIZE internat_block   ; Size in bytes of this table
                    DB  33               ; Country code
FRNTABLE internat_block <1,'F',0,0,0,0,' ',0,',',0,'/',0,':',0,3,2,1,OFFSET DOSGROUP:MAP_DCASE,0,';',0>
                    DB  SIZE internat_block   ; Size in bytes of this table
                    DB  81              ; Country code
JAPTABLE internat_block <2,9DH,0,0,0,0,',',0,'.',0,'-',0,':',0,0,0,1,OFFSET DOSGROUP:MAP_DCASE , 0,',',0>
ENDIF
ENDIF
                    DB  -1              ; End of tables

CONSTANTS       ENDS


CODE            SEGMENT BYTE PUBLIC 'CODE'
ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;CASE MAPPER ROUTINE FOR 80H-FFH character range
;     ENTRY: AL = Character to map
;     EXIT:  AL = The converted character
; Alters no registers except AL and flags.
; The routine should do nothing to chars below 80H.
;
; Example:
       MAP_DCASE       PROC FAR
IF	NOT	KANJI
IF	IBM
               CMP     AL,80H
               JB      L_RET           ;Map no chars below 80H ever
               CMP     AL,0A7H
               JA     L_RET             ;This routine maps chars between 80H and A7H
		SUB	AL,80H		;Turn into index value
		PUSH	DS
		PUSH	BX
		PUSH	CS		;Move to DS
		POP	DS
		MOV	BX,OFFSET DOSGROUP:TABLE
		XLAT			;Get upper case character
		POP	BX
		POP	DS
ENDIF
ENDIF
       L_RET:  RET
       MAP_DCASE ENDP
IF	NOT KANJI
IF	IBM
TABLE:	DB	80H,9AH,"E","A",8EH,"A",8FH,80H
	DB	"E","E","E","I","I","I",8EH,8FH
	DB	90H,92H,92H,"O",99H,"O","U","U"
	DB	"Y",99H,9AH,9BH,9CH,9DH,9EH,9FH
	DB	"A","I","O","U",0A5H,0A5H,0A6H,0A7H
ENDIF
ENDIF

SUBTTL EDIT FUNCTION ASSIGNMENTS AND HEADERS
PAGE
; The following two tables implement the current buffered input editing
; routines.  The tables are pairwise associated in reverse order for ease
; in indexing.  That is; The first entry in ESCTAB corresponds to the last
; entry in ESCFUNC, and the last entry in ESCTAB to the first entry in ESCFUNC.


        PUBLIC  ESCCHAR
ESCCHAR DB      ESCCH                   ;Lead-in character for escape sequences
        IF      NOT Rainbow
ESCTAB:
        IF      NOT IBM
        IF      WANG
        DB      0C0h                    ; ^Z inserter
        DB      0C1H                    ; Copy one char
        DB      0C7H                    ; Skip one char
        DB      08AH                    ; Copy to char
        DB      088H                    ; Skip to char
        DB      09AH                    ; Copy line
        DB      0CBH                    ; Kill line (no change in template)
        DB      08BH                    ; Reedit line (new template)
        DB      0C3H                    ; Backspace
        DB      0C6H                    ; Enter insert mode
        IF      NOT TOGLINS
        DB      0D6H                    ; Exit insert mode
        ENDIF
        DB      0C6H                    ; Escape character
        DB      0C6H                    ; End of table
        ELSE
                                        ; VT52 equivalences
        DB      "Z"                     ; ^Z inserter
        DB      "S"                     ; F1 Copy one char
        DB      "V"                     ; F4 Skip one char
        DB      "T"                     ; F2 Copy to char
        DB      "W"                     ; F5 Skip to char
        DB      "U"                     ; F3 Copy line
        DB      "E"                     ; SHIFT ERASE Kill line (no change in template)
        DB      "J"                     ; ERASE Reedit line (new template)
        DB      "D"                     ; LEFT Backspace
        DB      "P"                     ; BLUE Enter insert mode
        DB      "Q"                     ; RED Exit insert mode
        DB      "R"                     ; GRAY Escape character
        DB      "R"                     ; End of table
        ENDIF
        ENDIF
        IF      IBM
        DB      64                      ; Ctrl-Z - F6
        DB      77                      ; Copy one char - -->
        DB      59                      ; Copy one char - F1
        DB      83                      ; Skip one char - DEL
        DB      60                      ; Copy to char - F2
        DB      62                      ; Skip to char - F4
        DB      61                      ; Copy line - F3
        DB      61                      ; Kill line (no change to template ) - Not used
        DB      63                      ; Reedit line (new template) - F5
        DB      75                      ; Backspace - <--
        DB      82                      ; Enter insert mode - INS (toggle)
        DB      65                      ; Escape character - F7
        DB      65                      ; End of table
        ENDIF
ESCEND:
ESCTABLEN EQU   ESCEND-ESCTAB

ESCFUNC LABEL   WORD
        short_addr  GETCH               ; Ignore the escape sequence
        short_addr  TWOESC
        IF      NOT TOGLINS
        short_addr  EXITINS
        ENDIF
        short_addr  ENTERINS
        short_addr  BACKSP
        short_addr  REEDIT
        short_addr  KILNEW
        short_addr  COPYLIN
        short_addr  SKIPSTR
        short_addr  COPYSTR
        short_addr  SKIPONE
        short_addr  COPYONE

        IF      IBM
        short_addr  COPYONE
        ENDIF
        short_addr  CTRLZ
        ENDIF

;
; OEMFunction key is expected to process a single function
;   key input from a device and dispatch to the proper
;   routines leaving all registers UNTOUCHED.
;
; Inputs:   CS, SS are DOSGROUP
; Outputs:  None. This function is expected to JMP to onw of
;           the following labels:
;
;           GetCh       - ignore the sequence
;           TwoEsc      - insert an ESCChar in the buffer
;           ExitIns     - toggle insert mode
;           EnterIns    - toggle insert mode
;           BackSp      - move backwards one space
;           ReEdit      - reedit the line with a new template
;           KilNew      - discard the current line and start from scratch
;           CopyLin     - copy the rest of the template into the line
;           SkipStr     - read the next character and skip to it in the template
;           CopyStr     - read next char and copy from template to line until char
;           SkipOne     - advance position in template one character
;           CopyOne     - copy next character in template into line
;           CtrlZ       - place a ^Z into the template
; Registers that are allowed to be modified by this function are:
;           AX, CX, BP

        PUBLIC OEMFunctionKey
OEMFunctionKey  PROC    NEAR
        ASSUME  DS:NOTHING,ES:NOTHING,SS:DOSGROUP
        invoke  $STD_CON_INPUT_NO_ECHO  ; Get the second byte of the sequence

        IF NOT Rainbow
        MOV     CL,ESCTABLEN            ; length of table for scan
        PUSH    DI                      ; save DI (cannot change it!)
        MOV     DI,OFFSET DOSGROUP:ESCTAB   ; offset of second byte table
        REPNE   SCASB                   ; Look it up in the table
        POP     DI                      ; restore DI
        SHL     CX,1                    ; convert byte offset to word
        MOV     BP,CX                   ; move to indexable register
        JMP     [BP+OFFSET DOSGROUP:ESCFUNC]    ; Go to the right routine
        ENDIF
        IF Rainbow

TransferIf  MACRO   value,address
        local   a
        CMP     AL,value
        JNZ     a
        transfer    address
a:
ENDM

        CMP     AL,'['                  ; is it second lead char
        JZ      EatParm                 ; yes, go walk tree
GoGetCh:
        transfer    GetCh               ; no, ignore sequence
EatParm:
        invoke  $STD_CON_INPUT_NO_ECHO  ; get argument
        CMP     AL,'A'                  ; is it alphabetic arg?
        JAE     EatAlpha                ; yes, go snarf one up
        XOR     BP,BP                   ; init digit counter
        JMP     InDigit                 ; jump into internal eat digit routine
EatNum:
        invoke  $STD_CON_INPUT_NO_ECHO  ; get next digit
InDigit:
        CMP     AL,'9'                  ; still a digit?
        JA      CheckNumEnd             ; no, go check for end char
        SUB     AL,'0'                  ; turn into potential digit
        JB      GoGetCh                 ; oops, not a digit, ignore
        MOV     CX,BP                   ; save BP for 10 multiply
        CBW                             ; make AL into AX
        SHL     BP,1                    ; 2*BP
        SHL     BP,1                    ; 4*BP
        ADD     BP,CX                   ; 5*BP
        SHL     BP,1                    ; 10*BP
        ADD     BP,AX                   ; 10*BP + digit
        JMP     EatNum                  ; continue with number
CheckNumEnd:
        CMP     AL,7Eh                  ; is it end char ~
        JNZ     GoGetCh                 ; nope, ignore key sequence
        MOV     AX,BP
        transferIf  1,SkipStr           ; FIND key
        transferIf  2,EnterIns          ; INSERT HERE key
        transferIf  3,SkipOne           ; REMOVE
        transferIf  4,CopyStr           ; SELECT
        transferIf  17,TwoEsc           ; INTERRUPT
        transferIf  18,ReEdit           ; RESUME
        transferIf  19,KilNew           ; CANCEL
        transferIf  21,CtrlZ            ; EXIT
        transferIf  29,CopyLin          ; DO
        JMP     GoGetCh
EatAlpha:
        CMP     AL,'O'                  ; is it O?
        JA      GoGetCh                 ; no, after assume bogus
        JZ      EatPQRS                 ; eat the rest of the bogus key
        transferIf  'C',CopyOne         ; RIGHT
        transferIf  'D',BackSp          ; LEFT
        JMP     GoGetCh
EatPQRS:
        invoke  $STD_CON_INPUT_NO_ECHO  ; eat char after O
        JMP     GoGetCh
        ENDIF

OEMFunctionKey  ENDP

CODE            ENDS

        do_ext
        END
                                         

