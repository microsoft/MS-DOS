.XLIST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBSHAR.INC
;; ----------
;;
;; Description:
;; ------------
;;       Include file containing structure definitions Shared Data Area
;;       for the Shared Data Area.
;;       The Shared Data Area contains data which is required by
;;       both the resident and transient KEYB code.  The Shared
;;       Data Area is allocated in the KEYBI2F file and will be
;;       resident following initial installation.
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SHARED_DATA_STR defines the initial fixed length portion of the
;; Shared Data Area.
;; Tables are loaded beginning at TABLE_AREA in the following order:
;;  State Logic
;;  Common Translate Section
;;  Specific Translate Sections for
;;   each code page
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;; SPECIAL_FEATURES equates:
TYPEWRITER_CAPS_LK  EQU    8000H       ;; typewriter style caps lock
JR_HOT_KEY_1_2      EQU    4000H       ;; on PCjr use 1/2 as the hot keys
                                       ;;  instead of F1/F2
                                       ;;
                                       ;; Some useful scan codes:
F1_SCAN     EQU   59                   ;; F1
F2_SCAN     EQU   60                   ;; F2
ONE_SCAN    EQU   2                    ;; "1"
TWO_SCAN    EQU   3                    ;; "2"
                                       ;;
                                       ;; SYSTEM_FLAG equates:
EXT_16          EQU    8000H           ;; extended int16 support is there
PC_AT           EQU    4000H           ;; code for pcat
PC_LAP          EQU    2000H           ;; code for pc lap computer (p-12)
PC_XT           EQU    1000H           ;; code for PC, PC/XT, PORTABLE
PC_JR           EQU    0800H           ;; code for PCjr
PC_PAL          EQU    0400H           ;; code for ???
PC_386          EQU    0200H           ;; code for ???
PC_NET          EQU    0100H           ;; PC Net is installed
                                       ;;
                                       ;; HOT_KEY_FLAG EQUATES:
US_MODE     EQU   0                    ;;  hot key is active => US
LANG_MODE   EQU   0FFH                 ;;  hot key is inactive
                                       ;;
                                       ;; -----------------------------------
SHARED_DATA_STR     STRUC              ;; SHARED DATA AREA
                                       ;;
OLD_INT_9           DD    0            ;; saved int 9 vector
OLD_INT_2F          DD    0            ;; saved int 2F vector
OLD_INT_48          DD    0            ;; saved int 48 vector (if PCjr)
KEYB_TYPE           DW    0            ;; type of keyboard
SYSTEM_FLAG         DW    0            ;; system configuration flags
TABLE_OK            DB    0            ;; flag to INT 9 that table is built
JR_KB_FLAG          DB    0            ;; flag for special PCjr processing
                    DB    4 DUP(0)     ;; reserved
                                       ;;
                                       ;; Table copy begins here:
ACTIVE_LANGUAGE     DB    'US'         ;; language code
INVOKED_CP_TABLE    DW    437          ;; ptr to table for invoked code page
ACTIVE_XLAT_PTR     DW    -1           ;; ptr to active Specific Translate Sect
FIRST_XLAT_PTR      DW    -1           ;; ptr to first Specific Translate Sect
RESIDENT_END        DW    0ffffh       ;; offset of last byte in resident mem
LOGIC_PTR           DW    -1           ;; ptr to State Logic
COMMON_XLAT_PTR     DW    -1           ;; ptr to Common Translate Section
SPECIAL_FEATURES    DW    ?            ;; special Features
TABLE_OVERFLOW      DB    0            ;; overflow flag for table rebuild
HOT_KEY_ON_SCAN     DB    ?            ;; scan codes to use with ALT+CTRL
HOT_KEY_OFF_SCAN    DB    ?            ;;  to turn hot key on and off
                    DB    4 DUP(0)     ;; reserved
TABLE_AREA          DB    ?            ;; tables loaded here:
                                       ;;  State Logic
                                       ;;  Common Translate Section
                                       ;;  Specific Translate Sections for
                                       ;;   each code page
SHARED_DATA_STR     ENDS               ;;
                                       ;;
                                       ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; State Logic equates.
;; Contains equates for our NLS Flags and for the State Logic
;; commands.
;; State Logic command macros are defined in KEYBMAC.INC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
STATE_LOGIC_STR STRUC                  ;;
                                       ;;
SL_LOGIC_LEN    DW   ?                 ;; length of state logic
SL_SPECIAL_FEATURES   DW   ?           ;;
SL_LOGIC_CMDS   DB   0                 ;; state logic commands begin here
                                       ;;
STATE_LOGIC_STR ENDS                   ;;
                                       ;;
                                       ;;
NUM_BIOS_FLAGS      EQU   4            ;;
NUM_NLS_FLAGS       EQU   2            ;; '+1' below is the EXT_KB_FLAG
NUM_FLAGS           EQU   NUM_BIOS_FLAGS+NUM_NLS_FLAGS+1
                                       ;;
                                       ;;
EITHER_SHIFT        EQU   80H          ;; EXT_KB_FLAG : our own shift state
EITHER_CTL          EQU   40H          ;;  flags
EITHER_ALT          EQU   20H          ;;
SCAN_MATCH          EQU   08H          ;; set if scan code found in XLATT
                                       ;; or SET_FLAG searches
                                       ;;
                                       ;;
KB_FLAG_ID          EQU   0            ;; Flag ID's as coded in IFF and ANDF
KB_FLAG_1_ID        EQU   1            ;;  commands
KB_FLAG_2_ID        EQU   2            ;;
KB_FLAG_3_ID        EQU   3            ;;
EXT_KB_FLAG_ID      EQU   4            ;;
NLS_FLAG_1_ID       EQU   5            ;;
NLS_FLAG_2_ID       EQU   6            ;;
                                       ;;
COMMAND_BITS        EQU   0F0H         ;; Mask to isolate command code
SUB_CMD_BITS        EQU   0FH          ;; mask to isolate sub command code
NOT_TEST            EQU   08H          ;; NOT bit in IFF, ANDF
COMMAND_SHIFT       EQU   4            ;; shift amount for command code
FLAG_ID_BITS        EQU   07H          ;; mask to isolate flag id in IFF, ANDF
NUM_COMMANDS        EQU   0CH          ;; number of commands
                                       ;;
IFF_COMMAND         EQU   00H          ;;
ANDF_COMMAND        EQU   10H          ;;
ELSEF_COMMAND       EQU   20H          ;;
ENDIFF_COMMAND      EQU   30H          ;;
XLATT_COMMAND       EQU   40H          ;;
OPTION_COMMAND      EQU   50H          ;;
SET_FLAG_COMMAND    EQU   60H          ;;
PUT_ERROR_COMMAND   EQU   70H          ;;
IFKBD_COMMAND       EQU   80H          ;;
GOTO_COMMAND        EQU   90H          ;;
BEEP_COMMAND        EQU   0A0H         ;;
RESET_NLS_COMMAND   EQU   0B0H         ;;
CHECK_CORE_COMMAND  EQU   0C0H         ;;
                                       ;;
                                       ;;
EXIT_INT_9_FLAG         EQU  01H       ;; Special forms of GOTO.  These
EXIT_STATE_LOGIC_FLAG   EQU  02H       ;;  values are in the right nibble
                                       ;;   of the GOTO command.
                                       ;;
                                       ;; PROCESSING OPTIONS:
EXIT_IF_FOUND       EQU   80H          ;; exit INT 9 if a translation
                                       ;;  match is found
                                       ;;
ANY_KB               EQU   0FFFFH      ;;
JR_KB                EQU   8000H       ;; Keyboard types
XT_KB                EQU   4000H       ;;
AT_KB                EQU   2000H       ;;
G_KB                 EQU   1000H       ;;
P_KB                 EQU   0800H       ;;
P12_KB               EQU   0400H       ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Translate Table Sections.  Both the Specific and Common
;; Translate Sections are formatted as follows.
;;
;; The Specific Translate Sections are chained together using the
;; XS_NEXT_SECT_PTR field (-1 if last section).
;; Translate Sections contains multiple States.
;; A State contains the translate tables for a single
;; shift state (IE lower case, upper case ....)
;; Each State may contain multiple translate tables.
;;
;; The Translate Section layout is defined using several STRUCs.
;; These STRUCs are allocated in the Shared Data Area as follows:
;;
;;       XLAT_SECT_STR            ; header info for the section
;;          STATE_STR             ; header for state #1
;;            XLAT_STR            ;   first translate tab for state #1
;;            XLAT_TYPE_1_STR or XLAT_TYPE_2_STR
;;            XLAT_STR            ;   second translate tab
;;            XLAT_TYPE_1_STR or XLAT_TYPE_2_STR
;;            ...
;;          STATE_STR             ; header for state #2
;;            XLAT_STR
;;            XLAT_TYPE_1_STR or XLAT_TYPE_2_STR
;;            ...
;;         ...
;;
;; A State may contain a "Set_Flag" table instead of translate tables.
;; These tables are used to set the NLS flags instead of generating
;; ASCII codes (for example: to remember dead key states).
;; There can be only on Set_Flag table per state.
;; The Set_Flag table layout is defined in the SET_FLAG_STR STRUC.
;;
;; So some states will contain translate tables (to generate ASCII codes)
;; and some states will contain a Set_Flag table (to record dead key
;; status).
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
XLAT_SECT_STR       STRUC              ;;
                                       ;;
XS_NEXT_SECT_PTR       DW    ?         ;; Pointer to next Specific Translate
                                       ;;  Section
XS_CP_ID               DW    ?         ;; code page id
XS_FIRST_STATE         DB    ?         ;;
                                       ;;
XLAT_SECT_STR       ENDS               ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; State structure.
;; The last State is a null State containing only the
;; XS_STATE_LEN field with a value of 0.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
STATE_STR           STRUC              ;;
                                       ;;
XS_STATE_LEN     DW    ?               ;; length of state section
XS_STATE_ID      DB    ?               ;; State ID
XS_KBD_TYPE      DW    ?               ;; Keyboard Type
XS_ERROR_CHAR    DW    ?               ;; Buffer entry for error character
XS_FIRST_TAB     DB    ?               ;;
                                       ;;
STATE_STR           ENDS               ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Translate Table structures.
;; There may be many translate tables in a State.  The last
;; table is a null table containing only the XLAT_TAB_SIZE field with
;; a value of 0.
;; The xlate table can be in one of two forms:
;;    Type 1 = Table contains buffer entries only.
;;             Scan code is used as an index into xlat table
;;    Type 2 = Table contains pairs of SCAN/BUFFER_ENTRY.
;;             Table must be searched for matching scan.
;; Type 1 is the default.  Type 2 tables should be identified by setting
;; the TYPE_2_TAB bit in XLAT_OPTIONS.
;; Buffer entries default to 2-bytes per entry.
;; Optionally the table may contain ASCII codes only
;; (1-byte entries).  This is specified by setting the ASCII_ONLY bit
;; in XLAT_OPTIONS.  2-byte buffer entries are coded ASCII,SCAN.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
                                       ;; Translate options:
ASCII_ONLY          EQU   80H          ;; Only ASCII codes listed - use
                                       ;;  incoming scan for buffer entry
TYPE_2_TAB          EQU   40H          ;; search xlat table for matching scan
ZERO_SCAN           EQU   20H          ;; set the scan half of the buffer
                                       ;;  entry to 0
                                       ;;
NULL_ASCII_CODE     EQU   -1           ;;
                                       ;;
DEFAULT_TAB_2_ENT_SZ   EQU   3         ;;
ASC_ONLY_TAB_2_ENT_SZ  EQU   2         ;;
                                       ;;
                                       ;;
XLAT_STR            STRUC              ;;
                                       ;;
XLAT_TAB_SIZE       DW    ?            ;; Size in bytes of this table -
                                       ;;  includes this field, options etc.
XLAT_OPTIONS        DB    ?            ;; xlat options
                                       ;; XLAT TABLE IS HERE
XLAT_STR            ENDS               ;;
                                       ;;
XLAT_TYPE_1_STR     STRUC              ;; use scan code as index into table
                    DB TYPE XLAT_STR DUP(?)   ;; filler
XLAT_SCAN_LO        DB    ?            ;; Scan code
XLAT_SCAN_HI        DB    ?            ;;  range
XLAT_1_BUF_ENTRY    DB    ?            ;; The table itself
XLAT_TYPE_1_STR     ENDS               ;;
                                       ;;
XLAT_TYPE_2_STR     STRUC              ;; search table for scan
                    DB TYPE XLAT_STR DUP(?)   ;; filler
XLAT_NUM            DB    ?            ;; number of scans
XLAT_SCAN           DB    ?            ;; Scan code
XLAT_2_BUF_ENTRY    DB    ?            ;; The table itself
XLAT_TYPE_2_STR     ENDS               ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set_Flag Tables.
;; State Sections immediately following the LAST_ENTRYs.
;; Dead key definitions.  If the scan matches then
;; set the bit in NLS_FLAGs indicated in DK_MASK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
SF_ENT_SZ     EQU   3                  ;; size of entry
                                       ;;
SET_FLAG_STR        STRUC              ;;
                                       ;;
SF_NUM              DB    0            ;; Number of entries
SF_SCAN_CODE        DB    0            ;; scan code
SF_FLAG_ID          DB    0            ;; flag id
SF_FLAG_MASK        DB    0            ;; flag mask
                                       ;;
SET_FLAG_STR        ENDS               ;;
                                       ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.LIST
