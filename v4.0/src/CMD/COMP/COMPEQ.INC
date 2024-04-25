;*****************************************************************************
;
; MODULE: compeq.inc
;
; Modification History:
;
;   version   author          date     comment
;   -------   ------          ----     -------
;   V4.0      Bill L.	     9/17/87  moved equates from comp2.sal to here!
;
;*****************************************************************************
               if1                                                              ;AN000;
                     %OUT INCLUDING COMPEQ.INC...                               ;AN000;
               endif                                                            ;AN000;

EAISBINARY     equ  02h           ;extended attribute is a binary integer       ;AN001;
EASYSTEM       equ  8000h         ;extended attr. is system defined             ;AN001;

VERSION        EQU  00H           ;DOS VERSION, =00H (NOT USED)                 ;AN000;
NUL            EQU  00H           ;END OF STRING (ASCIIZ) MARKER                ;AN000;
ONE_PARM       EQU  01H           ;ONLY PARSE ONE PARAMETER                     ;AN000;
ZERO_PARM_CT   EQU  00H           ;ORDINAL # BEFORE PARSING FIRST PARM.         ;AN000;
FIRST_PARM_CT  EQU  01H           ;ORDINAL # AFTER PARSING FIRST PARM.          ;AN000;
TRICK_PARM_CT  EQU  02H           ;TRICK PARSER SO THAT FILENAME GOES TO PATH2  ;AN000;
                                  ;INSTEAD OF PATH1                             ;AN000;
YES            EQU  01H           ;A VALID YES RESPONSE EQUALS 1                ;AN000;
KEYB_INP_CLR   EQU  0C1H          ; does an INT 21H fuction 0CH, 01H            ;AN000;
KEYB_INPUT     EQU  0FFH          ;DO A READ ON CLEAR KEYBOARD                  ;AN000;
INPUT_LEN      EQU  127           ;LENGTH OF INPUT BUFFER ON BUFFERED INPUT     ;AN000;
KEYIN          EQU  01H           ;WAIT FOR KEYBOARD INPUT TO AL                ;AN000;
DISP_OUT       EQU  02H           ;DL = CHAR TO BE DISPLAYED TO STD OUT         ;AN000;
DIRECT_IO      EQU  06H           ;DUMBY CALL, USED IN CLEARING KEYBOARD        ;AN000;
BUFFD_KEYBD    EQU  0AH           ;BUFFERED KEYBOARD INPUT TO DX                ;AN000;
IN_STAT        EQU  0BH           ;check keyboard status                        ;AC210;
CLEAR_KEYBD    EQU  0CH           ;CLEAR KEYB, DO KEYB FUNC IN AL               ;AN000;
FCBOpen        equ  0FH           ;fcb open                                     ;AN000;
FCBCLOSE       EQU  10H           ;FCB CLOSE FILE                               ;AN000;
SearchF        equ  11H           ;FCB Search function call                     ;AN000;
SEARCHN        EQU  12H           ;FCB SEARCH NEXT                              ;AN000;
SetDTA         equ  1AH           ;Set DTA                                      ;AN000;
DEFDRV         equ  19H           ;get default drive                            ;AN000;
YESNO_CHECK    EQU  23H           ;CHECK (Y/N) RESPONSE ON INPUT (EXTENDED COUNTRY INFO) ;AN000;
SETVECTOR      equ  25H           ;set interrupt vector in AL to DS:DX          ;AN000;
FCBRndBlkRead  equ  27H           ;Read function call                           ;AN000;
PARSE_FILENAME EQU  29H           ;PARSE FILENAME                               ;AN000;
GETVER         equ  30H           ;get dos version                              ;AN000;
CHDIR          equ  3BH           ;CHDIR function call                          ;AN000;
HandleOpen     equ  3DH           ;Handle open function call                    ;AN000;
HANDLECLOSE    EQU  3EH           ;HANDLE CLOSE FUNCTION CALL                   ;AN000;
Write          equ  40H           ;Write function call                          ;AN000;
CURDIR         equ  47H           ;get current directory for drive in [dl]      ;AN000;
RET_FN         EQU  4CH           ;"RETURN TO DOS" NOT REMAIN RESIDENT          ;AN000;
GET_EXT_CNTRY_INFO EQU 65H        ;EXTENED COUNTRY INFO DOS CALL                ;AN000;

STDOUT          equ  0001H        ;Standard output device                       ;AN000;
STDERR          equ  0002H        ;Standard error device                        ;AN000;

ReadOnlyAccess  equ  00H          ;Access code for Handle Open function call    ;AN000;

CPSW_CHECK      EQU  33H          ;CODE PAGE SWITCHING CONTROL                  ;AN000;
GET_CPSW_STATE  EQU  03H          ;AL=3, GET STATE TO DL                        ;AN000;
SET_CPSW_STATE  EQU  04H          ;AL=4, SET STATE FROM DL                      ;AN000;
CPSW_OFF        EQU  00H          ; DL=0, OFF                                   ;AN000;
CPSW_ON         EQU  01H          ; DL=1, ON                                    ;AN000;
CPSW            EQU  40H          ;IN CPSW_ORIG: ON, CPSW=ON                    ;AN000;
ZERO_CP         EQU  00H          ; A ZERO CODE PAGE                            ;AN000;

;   EXTENDED OPEN EQUATES         ;                                    LOOK     ;AN000;
NO_ATTR_LIST    EQU  00H          ;NO ATTRIBUTE LIST NEEDED            ||       ;AN000;
OPEN_MODE       EQU  82H          ;OPEN MODE FOR EXTENDED OPEN         ||       ;AN000;
FUNC_CNTRL      EQU  0101H        ;FUNCTION CONTROL FOR EXTENDED OPEN  ||       ;AN000;
EXT_OPEN_RD     EQU  00H          ;READ MODE ON EXTENDED OPEN          \/       ;AN000;
EXT_OPEN        EQU  6CH          ;EXTENDED OPEN                                ;AN000;
                                  ;AL=FUNCTION CONTROL, IN FORMAT=CE            ;AN000;
                                  ; C=DOES NOT EXIST ACTION:                    ;AN000;
                                  ;   0=FAIL, 1=CREATE                          ;AN000;
                                  ; E=EXISTS ACTION                             ;AN000;
                                  ;   0=FAIL, 1=OPEN, 2=REPLACE/OPEN            ;AN000;
                                  ;BX=OPEN MODE, FORMAT=0WF00000ISSS0AAA        ;AN000;
                                  ;   AAA=ACCESS CODE: 0=READ, 1=WRITE          ;AN000;
                                  ;    2=READ/WRITE, 4=EXECUTE (UNDOC)          ;AN000;
                                  ;    7=FCB (UNDOC)                            ;AN000;
                                  ;   SSS=SHARING MODE: 0=COMPATIBILITY         ;AN000;
                                  ;    1=DENY READ/WRITE, 2=DENY WRITE          ;AN000;
                                  ;    2=DENY READ, 3=DENY NONE                 ;AN000;
                                  ;   I=0, PASS HANDLE TO CHILD, 1=NO INHERIT   ;AN000;
                                  ;   F=0, INT 24H, 1=RETURN ERROR              ;AN000;
                                  ;ON THIS OPEN AND ANY IO TO THIS HANDLE       ;AN000;
                                  ;   W=0, NO COMMIT, 1=AUTO-COMMIT ON WRITE    ;AN000;
                                  ;CX=SCARCH/CREATE ATTRIBUTE                   ;AN000;
                                  ;DX=FUNCTION CONTROL, 0000000C NNNNEEEE       ;AN000;
                                  ; NNNN=DOES NOT EXIST ACTION:                 ;AN000;
                                  ;  0=FAIL,1=CREATE                            ;AN000;
                                  ; EEEE=DOES EXIST ACTION:                     ;AN000;
                                  ;  0=FAIL,1=OPEN,2=REPLACE/OPEN               ;AN000;
                                  ; C=CODEPAGE ACTION:                          ;AN000;
                                  ;  0=VALIDATE, 1=NO CHECK CODE PAGE           ;AN000;
                                  ;DS:SI=PARM LIST:                             ;AN000;
                                  ;    DD POINT TO NAME TO OPEN                 ;AN000;
                                  ;    DB NUMBER OF ADDITIONAL PARMS            ;AN000;
                                  ;    DB 1  IO MODE                            ;AN000;
                                  ;    DB IOMODE                                ;AN000;
                                  ;       ???0H=UNSPECIFIED (DEFAULT)           ;AN000;
                                  ;       ???1H=MAINLY SEQUENTIAL               ;AN000;
                                  ;       ???2H=MAINLY RANDOM                   ;AN000;
                                  ;       ???3H=RANDOM WITH LOCALITY            ;AN000;
                                  ;       ???=RESERVED (SET TO ZERO)            ;AN000;
                                  ;ES:DI=EXTENTED ATTR LIST                     ;AN000;

                                  ;OUTPUT: CY SET ON ERROR                      ;AN000;
                                  ; AX=HANDLE                                   ;AN000;
                                  ; CX=ACTION TAKEN: 1=FILE OPENED,             ;AN000;
                                  ;  2=FILE CREATED/OPENED,                     ;AN000;
                                  ;  3=FILE REPLACED/OPENED                     ;AN000;

EXT_ATTR_LIST   EQU  57H          ;FUNCTION # : EXTENDED ATTR LIST              ;AN000;
GET_EXT_ATTR_LIST EQU 02H         ;SUB-FUNC. # : GET EXTENDED ATTR TO LIST      ;AN000;
                                  ;BX=HANDLE                                    ;AN000;
                                  ;ES:DI=LIST                                   ;AN000;
                                  ;CY SET IF ERROR                              ;AN000;


EXTERROR        EQU  59H          ;EXTENDED ERROR                               ;AN000;
                                  ;BX = 40 VERSION NUMBER (FOR 3.40)            ;AN000;
                                  ;OUTPUT:                                      ;AN000;
                                  ;AX=EXTENDED ERROR                            ;AN000;
                                  ;BH=ERROR CLASS                               ;AN000;
                                  ;BL=SUGGESTED ACTION                          ;AN000;
                                  ;CH=LOCUS                                     ;AN000;

;               ERRORLEVEL RETURN CODES, PASSED IN "EXITFL"                     ;AN000;
EXOK            EQU  0            ;NORMAL RETURN CODE, NO PROBLEM               ;AN000;
EXCB            EQU  1            ;CONTROL BREAK EXIT                           ;AN000;
EXVER           EQU  1            ;BAD DOS VERSION OR OTHER                     ;AN000;
                                  ; SYSLOADMSG DIFFICULTY                       ;AN000;

;               VALUES FOR THE MSG_DESC CONTROL BLOCK                           ;AN000;
NO_SUBS        EQU   0            ;NO VARIABLE FIELDS IN MESSAGE                ;AN000;
ONE_SUBS       EQU   1            ;ONE VARIABLE FIELD IN MESSAGE                ;AN000;
TWO_SUBS       EQU   2            ;TWO VARIABLE FIELDS IN MESSAGE               ;AN000;
THREE_SUBS     EQU   3            ;THREE VARIABLE FIELDS IN MESSAGE             ;AN000;
CLASS_1        EQU   1            ;CLASS 1 (DOS EXTENDED ERRORS)                ;AN000;
CLASS_2        EQU   2            ;CLASS 2 (PARSE ERRORS)                       ;AN000;
CLASS_A        EQU   -1           ;CLASS A TYPE MESSAGE                         ;AN000;

;*****************************                                                  ;AN000;
; Message Retriever structures                                                  ;AN000;
;*****************************                                                  ;AN000;

msg_desc          struc                                                         ;AN000;
msg_num           dw    0         ;MESSAGE NUMBER (TO AX)                       ;AN000;
msg_handle        dw    STDOUT    ;HANDLE OF OUTPUT DEVICE (TO BX)              ;AN000;
msg_sublist       dw    0         ;POINTER TO SUBLIST (TO SI)                   ;AN000;
msg_count         dw    0         ;SUBSTITUTION COUNT (TO CX)                   ;AN000;
msg_class         dw    CLASS_A shl 8 ;MESSAGE CLASS (IN HIGH BYTE, TO DH)      ;AN000;
                                  ;LOW BYTE HAS 0 (FUNCTION "NO INPUT", TO DL)  ;AN000;
msg_input         dw    ?         ;######EXTRA WORD - ONLY FOR MESSAGES WITH BUFFERED INPUT        ;AN000;
                                  ;######OTHERWISE THIS WORD IS NOT VALID AS PART OF THE STRUCT    ;AN000;
                                  ;POINTER TO INPUT BUFFER                      ;AN000;
msg_desc          ends                                                          ;AN000;

MAX_0             equ   0         ;MAXIMUM WIDTH OF STRING FIELD (0=NO LIMIT)   ;AN000;
PAD_BLK           equ   " "       ;CHAR FOR PAD FIELD                           ;AN000;


sublist           struc                                                         ;AN000;
sub_size          db    11        ;SUBLIST SIZE (POINTER TO NEXT SUBLIST)       ;AN000;
sub_res           db    0         ;RESERVED                                     ;AN000;
                                  ;NEXT FIELD IS TO BE USED AS A DOUBLE WORD    ;AN000;
sub_value         dw    0         ;TIME, DATE, OR PTR TO DATA ITEM              ;AN000;
sub_value_seg     dw    0         ;SEG ID OF PTR                                ;AN000;
                                  ;(ABOVE FIELD MUST BE FILLED AT EXECUTION TIME ;AN000;
                                  ; IF THIS IS A .COM FILE)                     ;AN000;
sub_id            db    0         ;N OF %N                                      ;AN000;
sub_flags         db    0         ;DATA TYPE FLAGS                              ;AN000;
sub_max_width     db    MAX_0     ;MAXIMUM FIELD WIDTH (0=UNLIMITED)            ;AN000;
sub_min_width     db    0         ;MINIMUM FIELD WIDTH                          ;AN000;
sub_pad_char      db    PAD_BLK   ;CHARACTER FOR PAD FIELD                      ;AN000;
                                  ; CAN BE " ", "0" OR ",".                     ;AN000;
                                  ; "," CAUSES INSERTION OF THE ACTIVE          ;AN000;
                                  ; THOUSANDS SEPARATOR BETWEEN EVERY 3 DIGITS. ;AN000;
sublist           ends                                                          ;AN000;

;end of COMPEQ.INC                                                              ;AN000;
