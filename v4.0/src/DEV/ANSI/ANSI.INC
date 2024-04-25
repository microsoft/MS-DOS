;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Equates and Strucs.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------------------------------------------------------------------------
;AN001; D425 For OS2 compatibiltiy box, /L option status query     01/14/88 J.K.
;AN002; D493 New INIT request structure for error message          02/25/88 J.K.
;AN003; P4934 Change ANSI 2F function number t0 1Ah                05/20/88 F.G.
;------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      DEVICE  Header     DS:[SI]      -- to locate the next CON header
;      NEXT device header ES:[DI]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HP      EQU     DS:[SI]                 ;                                      ;AN000;
NHD     EQU     ES:[DI]                 ;                                      ;AN000;
                                        ;
NAME_LEN EQU    8                       ;                                      ;AN000;
                                        ;
DHS     STRUC                           ;                                      ;AN000;
DH_NEXTO DW     ?                       ; offset of pointer to next header     ;AN000;
DH_NEXTS DW     ?                       ; segment of pointer to next header    ;AN000;
        DW      ?                       ; attribute                            ;AN000;
DH_STRAO DW     ?                       ; offset to strategy routine           ;AN000;
DH_INTRO DW     ?                       ; offset to interrupt routine          ;AN000;
DH_NAME DB      NAME_LEN DUP(0)         ; device name in this header           ;AN000;
DHS     ENDS                            ; end of common portion                ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CON data structure  CS:[BX]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CONPTR  EQU     CS:[BX]                 ;                                      ;AN000;
                                        ; STATES                               ;AN000;
BUF_DATA STRUC                          ;                                      ;AN000;
DEV_HDRO DW     -1                      ; device driver header offset          ;AN000;
DEV_HDRS DW     -1                      ;                                      ;AN000;
CON_STRAO DW    -1                      ; dos CON strategy offset              ;AN000;
CON_STRAS DW    -1                      ;                                      ;AN000;
CON_INTRO DW    -1                      ; dos CON strategy offset              ;AN000;
CON_INTRS DW    -1                      ;                                      ;AN000;
BUF_DATA ENDS                           ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                                      ;AN000;
;
;  INIT Structures and equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ROM_BIOS        EQU     40h             ; Segment of ROM_BIOS data area        ;AN000;
EQUIP_FLAG      EQU     10h             ; equipment flag. (for LCD)            ;AN000;
KBD_FLAG_3      EQU     96h             ; offset of KBD_FLAG_3 in data area    ;AN000;
NUM_ROWS        EQU     84h             ; offset of number of rows in data area;AN000;
EXT16_FLAG      EQU     00010000b       ; mask for Extended INT16 bit          ;AN000;
INIT_VID_MASK   EQU     0FFCFh          ; mask for equipment list              ;AN000;
LCD_COLOR_MODE  EQU     20h             ; LCD as color                         ;AN000;
LCD_MONO_MODE   EQU     30h             ; LCD as MONOchrome                    ;AN000;
UNKNOWN_CMD     EQU     8103H           ; unknown command status byte          ;AN000;
RC_EOL          EQU     -1              ; parser return code for EOL           ;AN000;
RC_NO_ERROR     EQU     0               ; parser return code for not in switch list  ;AN000;
INVALID_PARM    EQU     10              ; PARSE Invalid parameter message number     ;AN000;
SSTRING         EQU     3               ; PARSE Too many parameters message    ;AN000;
FUNC_CALL       EQU     1BH             ; VGA functionality call               ;AN000;
ALT_SELECT      EQU     12H             ; EGA alternate select call            ;AN000;
EGA_INFO        EQU     10H             ; EGA return information subcall       ;AN000;
ALT_PRT_SC      EQU     20H             ; select alternate print screen subcall;AN000;
MONOCHROME      EQU     1               ; monochrome attached to EGA           ;AN000;
COLOR           EQU     0               ; some color attached to EGA           ;AN000;
PS2_MONO        EQU     7               ; display adapter types...             ;AN000;
PS2_COLOR       EQU     8               ;                                      ;AN000;
MOD30_MONO      EQU     0BH             ;                                      ;AN000;
MOD30_COLOR     EQU     0CH             ;                                      ;AN000;
LCD_MODEL       EQU     0F9H            ; Convertible model byte value         ;AN000;
GET_SYS_ID      EQU     0C0H            ; INT15H call for system identification;AN000;
GET_STATUS      EQU     43H             ; read system status (Convertible)     ;AN000;
MONO_ADDRESS    EQU     0B000H          ; base address for monochrome          ;AN000;
COLOR_ADDRESS   EQU     0B800H          ; base address for CGA                 ;AN000;
UNOCCUPIED      EQU     -1              ; value in VIDEO_MODE_TABLE if space unused  ;AN000;
LCD_ACTIVE      EQU     00000001B       ; LCD adapter is present               ;AN000;
MONO_ACTIVE     EQU     00000010B       ; monochrome adapter is present        ;AN000;
CGA_ACTIVE      EQU     00000100B       ; CGA adapter is present               ;AN000;
MCGA_ACTIVE     EQU     00001000B       ; MCGA is present                      ;AN000;
E5151_ACTIVE    EQU     00010000B       ; EGA with monochrome is present       ;AN000;
E5153_ACTIVE    EQU     00100000B       ; EGA with color display is present    ;AN000;
E5154_ACTIVE    EQU     01000000B       ; EGA with enhanced color display is present ;AN000;
VGA_ACTIVE      EQU     10000000B       ; VGA is present                       ;AN000;
INT10_LOW       EQU     (4*10H)         ; interrupt 10 vector location         ;AN000;
INT10_HI        EQU     (4*10H)+2       ;                                      ;AN000;
INT2F_LOW       EQU     (4*2FH)         ; interrupt 2F vector location         ;AN000;
INT2F_HI        EQU     (4*2FH)+2       ;                                      ;AN000;
ONE             EQU     1               ;                                      ;AN000;
THREE           EQU     3               ;                                      ;AN000;
EIGHT           EQU     8               ;                                      ;AN000;
NINE            EQU     9               ;                                      ;AN000;
FOURTEEN        EQU     14              ;                                      ;AN000;
REQ_CRSR_POS    EQU     3               ; function call to return cursor position    ;AN000;
MODE7           EQU     7               ;                                      ;AN000;
MODE13          EQU     13              ;                                      ;AN000;
MODE15          EQU     15              ;                                      ;AN000;
MODE19          EQU     19              ;                                      ;AN000;
                                        ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                                      ;AN000;
;
;  Request Header Structure (INIT)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_REQ_HDR    STRUC                   ; INIT Request header structure        ;AN000;
                DB   13 DUP(?)          ; standard request header              ;AN000;
NUM_UNITS       DB   ?                  ; number of units (N/A)                ;AN000;
END_ADDRESS_O   DW   ?                  ; ending address of resident code      ;AN000;
END_ADDRESS_S   DW   ?                  ;                                      ;AN000;
ARG_PTR         DD   ?                  ; ptr. to remaining arguments          ;AN000;
DRIVE_NUM       DB   ?                  ; drive number (N/A)                   ;AN000;
CONFIG_ERRMSG   dw   0                  ;Flag to control "Error in CONFIG.SYS.." msg.;AN002;
INIT_REQ_HDR    ENDS                    ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Information Block Structure
;    (for functionality call)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INFO_BLOCK      STRUC                   ; information block for functionality call   ;AN000;
STATIC_ADDRESS  DD   ?                  ; address of static functionality table      ;AN000;
                DB   33 DUP(?)          ; don't care                           ;AN000;
ACTIVE_DISPLAY  DB   ?                  ; active display code                  ;AN000;
ALT_DISPLAY     DB   ?                  ; alternate display code               ;AN000;
                DB   3  DUP(?)          ; don't care                           ;AN000;
CURRENT_SCANS   DB   ?                  ; current number of scan lines         ;AN000;
                DB   2  DUP(?)          ; don't care                           ;AN000;
MISC_INFO       DB   ?                  ; miscellaneous state information      ;AN000;
                DB   18 DUP(?)          ; don't care                           ;AN000;
INFO_BLOCK      ENDS                    ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Video table entry structure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MODE_TABLE      STRUC                   ;                                      ;AN000;
V_MODE          DB    -1                ; video mode                           ;AN000;
D_MODE          DB    -1                ; display mode                         ;AN000;
RESERVED_BYTE   DB    0                 ; reserved                             ;AN000;
COLORS          DW    -1                ; colors                               ;AN000;
SCR_WIDTH       DW    -1                ; screen width (pels)                  ;AN000;
SCR_LENGTH      DW    -1                ; screen length (pels)                 ;AN000;
SCR_COLS        DW    -1                ; number columns                       ;AN000;
SCR_ROWS        DW    -1                ; number rows                          ;AN000;
MODE_TABLE      ENDS                    ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Structure of Static Block
;  (for functionality call
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STATIC_BLOCK    STRUC                   ; format of static functionality table ;AN000;
                DB   7  DUP(?)          ; don't care                           ;AN000;
SCAN_TEXT       DB   ?                  ; available scan lines in text modes   ;AN000;
STATIC_BLOCK    ENDS                    ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Structure of System ID call return block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SYS_ID          STRUC                   ; format of return system config data  ;AN000;
                DW   ?                  ; don't care                           ;AN000;
MODEL_BYTE      DB   ?                  ; model byte                           ;AN000;
SYS_ID          ENDS                    ;                                      ;AN000;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; INT2f Strucs and Equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MULT_ANSI       EQU     1Ah             ; ANSI multiplex number                ;AC003;
;Catagory code
INSTALL_CHECK   EQU     0               ; install check for ANSI               ;AN000;
IOCTL_2F        EQU     1               ; 2F interface to IOCTL                ;AN000;
DA_INFO_2F      EQU     2h              ;J.K. Information passing to ANSI.
;Subfunction code for IOCTL_2F
GET_SUBFUNC   EQU    7FH                ; WGR Same structure as GET_IOCTL(ANSI);AN000;

;Info Struture for DA_INFO_2F. (DS:DX point to this packet)
;J.K. Note: For DOS 4.00, DA_INFO_PACKET is used by DISPLAY.SYS to signal ANSI.SYS that
;DISPLAY.SYS is calling/finishing INT 10h SET MODE call.  ANSI.SYS needs this
;infomration since it also hooks INT 10h vector.
;For this DA_SETMODE_FLAG purpose, DA_INFO_LEVEL and DA_INFO_DIRECTION should always be
;set to 0.  This can be extended for another information passing scheme between
;DISPLAY.SYS and ANSI.SYS in the future version.
;For DA_SETMODE_FLAG, DISPLAY.SYS should be extremely careful that when it calls
;with DA_SETMODE_FLAG =1, then it should calls with DA_SETMODE_FLAG=0
;when it finished INT 10h function call. Otherwise, the system goes .....
;
;D425. At the request of OS2 compatibility box, when the user ask to ANSI
; with DA_INFO_LEVEL=1, then ANSI sets DA_OPTION_L_STATE based on /L option
; status.

DA_INFO_PACKET   struc
DA_INFO_LEVEL       db      0           ; 0=used for SET_MODE_FLAG 1=for OPTION_L_STATE
DA_SETMODE_FLAG     db      0           ; 1: DISPLAY.SYS is calling INT 10h call, SET MODE. 0=finished.
DA_OPTION_L_STATE   db      0           ; 1 = /L active, 0 = /L inactive
DA_INFO_PACKET   ends

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GENERIC IOCTL Strucs and Equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;                                      ;AN000;
DISPLAY_TYPE    EQU     3               ; MAJ_FUNC type for display            ;AN000;
GET_FUNC        EQU     7FH             ; MIN_FUNC for get subfunction         ;AN000;
SET_FUNC        EQU     5FH             ; MIN_FUNC for set subfunction         ;AN000;
REQ_VID_MODE    EQU     0FH             ; request video mode INT10h function call    ;AN000;
DONE            EQU     0100H           ; set done bit for IOCTL status        ;AN000;
CMD_ERROR       EQU     8000H           ; set error bit for IOCTL status       ;AN000;
INVALID_FUNC    EQU     1               ; invalid function                     ;AN000;
NOT_SUPPORTED   EQU     10              ; return code non-supported ioctl function   ;AN000;
NOT_AVAILABLE   EQU     12              ; return code for font not available   ;AN000;
TEXT_MODE       EQU     1               ; text mode = 1 in request packet      ;AN000;
GRAPHICS_MODE   EQU     2               ; graphics mode = 2                    ;AN000;
DEFAULT_LENGTH  EQU     25              ; normal screen length                 ;AN000;
OFF             EQU     0000H           ;                                      ;AN000;
ON              EQU     0001H           ;                                      ;AN000;
INT_BIT         EQU     00100000b       ; mask for int. bit from functionality call  ;AN000;
FOUND           EQU     1               ; flag value for FOUND                 ;AN000;
NOT_FOUND       EQU     0               ; flag value for not FOUND             ;AN000;
SET_MODE        EQU     0               ; set mode INT10H function number      ;AN000;
DISPLAY_CHECK   EQU     0AD00H          ; install check for DISPLAY.SYS        ;AN000;
CHECK_ACTIVE    EQU     0AD02H          ; active code page check for DISPLAY.SY;AN000;
INSTALLED       EQU     0FFH            ; present in AL if installed           ;AN000;
LOAD_8X8        EQU     1112H           ; register value for 8x8 ROM load      ;AN000;
SET_BLOCK_0     EQU     1103H           ; activate block = 0.                  ;AN000;
CHECK_FOR_FONT  EQU     0AD10H          ; check for 8x8 RAM font - DISPLAY.SYS ;AN000;
SELECT_SCAN     EQU     30H             ; subfunction to set scan lines (VGA)  ;AN000;
SET_INTENSIFY   EQU     0               ; value to enable intensify.           ;AN000;
SET_BLINK       EQU     1               ; value to enable blink.               ;AN000;
BLINK_TOGGLE    EQU     1003H           ; INT10 call to toggle int/blink bit.  ;AN000;
CURSOR_FLAG     EQU     87H             ; cursor flag byte in ROM_BIOS         ;AN000;
SET_CURSOR_CALL EQU     1               ; INT10 function call to set cursor typ;AN000;
VIDEO_MASK      EQU     7FH             ; turn of clear buffer bit of mode value     ;AN000;
MULT_ANSI       EQU     1Ah             ; ANSI multiplex number                ;AC003;
INSTALL_CHECK   EQU     0               ; install check for ANSI               ;AN000;
IOCTL_2F        EQU     1               ; 2F interface to IOCTL                ;AN000;
NOT_CY          EQU     0FFFEH          ; turn carry bit off                   ;AN000;
CY              EQU     1               ; turn carry bit off                   ;AN000;
INVALID_FLAGS   EQU     0FFFEH          ; test for invalid flags in control word     ;AN000;
TURN_OFF        EQU     0FEH            ; values to turn off and on cursor..   ;AN000;
TURN_ON         EQU     NOT TURN_OFF    ; emulation                            ;AN000;
SUB_SIZE        EQU     11              ; sublist size                         ;AN000;
LEFT_ASCIIZ     EQU     00010000B       ; left-aligned asciiz string           ;AN000;
UNLIMITED       EQU     0               ; unlimited message size.              ;AN000;
                                        ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Request Header Structure (Generic IOCTL)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_REQ_HDR    STRUC                   ;                                      ;AN000;
                DB   13 DUP(?)          ; standard request header              ;AN000;
MAJ_FUNC        DB   ?                  ; major function                       ;AN000;
MIN_FUNC        DB   ?                  ; minor function                       ;AN000;
IOCTL_SI        DW   ?                  ; contents of SI                       ;AN000;
IOCTL_DI        DW   ?                  ; contents of DI                       ;AN000;
REQ_PCKT_PTR    DD   ?                  ; pointer to request packet            ;AN000;
INIT_REQ_HDR    ENDS                    ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; REQUEST PACKET STRUCTURE (Generic IOCTL)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
REQ_PCKT        STRUC                   ;                                      ;AN000;
INFO_LEVEL      DB   ?                  ; information level (should be 0)      ;AN000;
                DB   ?                  ; reserved                             ;AN000;
DATA_LENGTH     DW   ?                  ; length of remaining data             ;AN000;
RP_FLAGS        DW   ?                  ; control flags                        ;AN000;
RP_MODE         DB   ?                  ; display mode                         ;AN000;
RESERVED2       DB   ?                  ; reserved                             ;AN000;
RP_COLORS       DW   ?                  ; # of colors                          ;AN000;
RP_WIDTH        DW   ?                  ; screen width                         ;AN000;
RP_LENGTH       DW   ?                  ; screen length                        ;AN000;
RP_COLS         DW   ?                  ; columns                              ;AN000;
RP_ROWS         DW   ?                  ; rows                                 ;AN000;
REQ_PCKT        ENDS                    ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Scan Lines available structure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCAN_LINE_STR   STRUC                   ;                                      ;AN000;
NUM_LINES       DW   ?                  ; number of scan lines                 ;AN000;
REP_1BH         DB   ?                  ; representation in 1Bh call           ;AN000;
REP_12H         DB   ?                  ; representation in 12h call           ;AN000;
SCAN_LINE_STR   ENDS                    ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SUBLIST struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SUB_STRUC       STRUC                   ;                                      ;AN000;
                DB  2 DUP(?)            ;                                      ;AN000;
SUB_PTR_O       DW  ?                   ;                                      ;AN000;
SUB_PTR_S       DW  ?                   ;                                      ;AN000;
SUB_STRUC       ENDS                    ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; RESULT BUFFER struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESULT_STRUC    STRUC                   ;                                      ;AN000;
RESULT_TYPE     DB  ?                   ;                                      ;AN000;
                DB  ?                   ;                                      ;AN000;
RES_SYN_PTR     DW  ?                   ;                                      ;AN000;
RES_PTR         DD  ?                   ;                                      ;AN000;
RESULT_STRUC    ENDS                    ;                                      ;AN000;
