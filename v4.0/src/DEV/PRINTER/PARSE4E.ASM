;***************************************************************
;**                                                           **
;**     ********  **   **  *******                            **
;**        **     **   **  **                                 **
;**        **     *******  *****                              **
;**        **     **   **  **                                 **
;**        **     **   **  *******                            **
;**                                                           **
;**   ******      *     ******     ******  *******  ******    **
;**   **   **   ** **   **   **   **       **       **   **   **
;**   ******   *******  ******     *****   ******   ******    **
;**   **       **   **  **  **         **  **       **  **    **
;**   **       **   **  **   **   ******   *******  **   **   **
;**                                                           **
;***************************************************************
;
; File Name:   PARSE.ASM
; ----------
;
; Description: A command parser for DEVICE command in the CONFIG.SYS file.
; ------------
;
; Procedures contained in the file:
; ---------------------------------
;              PARSER:  Main routine for command processing.
;              GET_CHAR:  Gets a character from command line.
;              IS_ALPH:  Checks if character is an alpha character.
;              IS_DIGIT:  Checks if character is a digit.
;              IS_DELIM:  Checks if character is a DOS delimiter.
;              DEVICE_PARSE:  Pulls device name from command line and
;                             inserts in table.
;              ID_PARSE:  Pulls id name from command line and insers in table
;              HWCP_PARMS:  Extract HWCP number, converts it to binary and
;                           inserts it in table.
;              HWCP_PARSE:  Extracts HWCP number if only one number is given.
;              MUL_HWCP:  Extracts multiple HWCP's numbers, if they are given
;                         in a list.
;              DESG_PARMS:  Extracts designate number, converts it to binary
;                           and inserts it in table.
;              DESG_FONT:  Extracts the designate and the font if both were
;                          given in command line.
;              DESG_PARSE:  Pulls designate number if it is the only one given.
;              GET_NUMBER:  Converts a number to binary.
;              OFFSET_TABLE:  Updates the counter in table #1.
;              FIND_RIGHT_BR:  Looks for a right bracket.
;
;
; Change history:
; ---------------
;
;
;LOGIC:
;------
;        Establish addressability to parameters.
;        Skip until end of path and file name -first delimiter
;
;   Loop:
;        Isolate the first non-delimiter or non delimeter characters.
;         If End_of_Line_Delimiter then
;           return an error_code
;         Else
;           If first non-delimiter is ALPHA then
;             (assume a device name)
;             Extracts device name
;         Update offset counter
;
;        Isolate the first non-delimiter characters after id name.
;         If End_of_Line_Delimiter then
;           return an error_code
;         Else
;           If first non-delimiter is ALPHA-NUMARIC or
;            If character is '(' then
;             (assume an id name)
;             Extracts id name
;         Update offset counter
;
;         Pull out HWCP
;           If error flag is set then exit
;           Else if end of line flag is set then exit
;
;         Pull out DESG parms
;           If error_flag is set then exit.
;           Else if end of line flag is set then exit
;           Else if Number of devices is four then Exit
;        Else Loop
;
;
;Subroutines Logic:
;------------------
;
;  GET_CHAR:
;  ---------
;              Load character in AL
;              If character less than 20h then
;                turn Z-flag on
;
;  IS_ALPHA:
;  ---------
;              Save character
;              'Convert character to upper case'
;              If character >=A and <=Z then
;                turn Z-flag on
;                exit
;              Else
;                Restore character
;                exit.
;
;  IS_DIGIT:
;  ---------   If Character >=0 and <=9 then
;                turn Z-flag on
;
;  IS_DELIMITER:
;  -------------
;              If character a dos delimiter (' ','=',',',';',TAB)
;                 then turn Z-flag on
;
;  DEVICE_PARSE:
;  -------------
;              Set device name length counter.
;              Loop
;                If a dos delimiter then
;                  add spaces to name (if require)
;                Else if char is ALPHA-NUM then
;                  save in table
;                  If name >8 character thne
;                    error; exit
;                Else
;                  error; exit
;
;  ID_PARSE:
;  ---------   Set id name length counter.
;              Loop
;                If a dos delimiter then
;                  add spaces to name (if require)
;                Else if char is ALPHA-NUM then
;                  save in table
;                  If name >8 character then
;                    error; exit
;                Else if char is ')' or '(' then
;                  set flags
;                Else
;                  error; exit
;
;  HWCP_PARMS:
;  -----------
;       Loop:   Set flags off
;               If char is a DIGIT then
;                 convert number to binary
;                 update table
;               Else if char is ',' then
;                 no HWCP was given
;                 exit
;               Else if char is '(' then
;                 assume multiple HWCP
;               Else if char is ')' then
;                 end of parms, exit
;               Else if not a delimiter then
;                 error, exit set carry flag set carry flag
;               Loop
;
;  HWCP_PARSE:
;  -----------  Increment counter
;               Get number and convert to binary
;               Update the table
;               Set table_5 pointer
;
;  MUL_HWCP:
;  ---------
;      Loop:    If char is ')' then
;                 end of list, exit
;               If char is a DIGIT
;                 Get number and convert to binary
;                 Update table.
;               If char is not a delimiter then
;                 error, exit set carry flag
;               Loop
;
;  DESG_PARMS:
;  -----------
;        Loop:  If char is a DIGIT then
;                 Get number and convert to binary
;                 Update table.
;               If char is a ')' then
;                 end of parms, exit
;               If char is a '(' then
;                 assume given desg. and font
;               If char is a ',' then
;                 no desg ginven
;                 scane for ')'
;               If char is not a delimiter then
;                 error, exit set carry flag
;               Loop
;
;  DESG_FONT:
;  ----------
;       Loop:   If char is a ',' then
;                 no desg number was given
;                 update table
;               If char is a ')' then
;                 end of desg-font pair, exit
;               If char is a DIGIT then
;                 Get number and convert to binary
;                 Update table
;               If char not a delimiter then
;                 error, exit set carry flag
;               Loop
;
;  DESG_PARSE:
;  -----------  Get number and conver to binary
;               Update table
;
;  GET_NUMBER:
;  -----------  Get ASCII number from parms
;               conver to binary
;               add to total
;
;  OFFSET_TABLE:
;  -------------
;               Increment the number of parms
;
;  FIND_RIGHT_BR:
;  --------------
;         Loop: If char is ')' then
;                 found bracket exit
;               If char is not ' ' then
;                 error, exit set carry flag
;               Loop
; END
;------------------------------------------------------
;
; The following is the table structure of the parser.   All fields are
; two bytes field (accept for the device and id name)
;
; TABLE HEADER :
; ÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Number of devices.     ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³   Device  # 1  offset     ÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄ>ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´               ³                          ³
;    ³   Device  # 2  offset      ³               ³      Table_1  (a)        ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´               ³                          ³
;    ³   Device  # 3  offset      ³               ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³   Device  # 4  offset      ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;
; N = 1,2,3 or 4.  A two bytes number indicating the number of device specified.
; DEVICE # N OFFSET : a two bytes offset address to table_1. (ie. Device #1 offset
; is a pointer to table_1 (a). Device #2 offset is a pointer to table_1
; (b)...etc.).   If an error was detected in the command N is set to zero.
;
;
;
; TABLE_1 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿           ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Number of Offsets.     ³           ³                          ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´    ÚÄÄÄÄÄÄ³      Table_2  (a)        ³
;    ³   Device Name  offset     ÄÅÄÄÄÄÙ      ³                          ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´           ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;    ³   Device  Id   offset     ÄÅÄÄÄÄÄÄ¿
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´      ³    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³   Device  HWCP offset     ÄÅÄÄÄÄ¿ ³    ³                          ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´    ³ ÀÄÄÄÄ³      Table_3  (a)        ³
;    ³   Device  Desg offset     ÄÅÄÄ¿ ³      ³                          ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´  ³ ³      ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;    ³      "Reserved"            ³  ³ ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³ ³      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;                                    ³ ³      ³                          ³
;                                    ³ ÀÄÄÄÄÄÄ³      Table_4  (a)        ³
;                                    ³        ³                          ³
;                                    ³        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;                                    ³        ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;                                    ³        ³                          ³
;                                    ÀÄÄÄÄÄÄÄÄ³      Table_5  (a)        ³
;                                             ³                          ³
;                                             ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;
;  N=Length of table_1, or the number of offsets contained in table_1.
;  The offsets are pointers (two bytes) to the parameters value of the device.
;  "Reserved" : a two byte memory reserved for future use of the "PARMS" option.
;
;
; TABLE_2 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of devices name ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³    Device   name           ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
; N = Length of device name.  Device length is always 8 byte long.
; Device Name : the name of the device (eg. LPT1, CON, PRN).  The name
; is paded with spaces to make up the rest of the 8 characters.
;
;
;
; TABLE_3 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of Id name.     ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³     Id   Name              ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
; N = Length of id name.  Id name length is always 8 byte long.
; Id Name : the name of the id (eg. EGA, VGA, 3812).  The name
; is paded with spaces to make up the rest of the 8 character.
;
;
;
; TABLE_4 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of table.       ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³    HWCP  #  1              ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³    HWCP  #  2              ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³          .                 ³
;    ³          .                 ³
;    ³          .                 ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³    HWCP  #  10             ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;
; N = Length of table in words. Or the number of HWCP's.
; HWCP # N : a hardware code page number converted to binary.  The maximum
; number of pages allowed is 10.
;
;
;
; TABLE_5 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of table.       ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³    Designate               ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³    Font                    ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
; N = Lenght of table.  0 - nothing was specified
;                       1 - Only a designate was specified.
;                       2 - Designate and font were given.  If the Desg field
;                           was left empty in the DEVICE command then the
;                           Designate field is filled with 0FFFFH.
; Designate, Font : Are the Desg. and Font binary numbers.
;
;------------------------------------------------------
;

PROGRAM         SEGMENT

                ASSUME  CS:PROGRAM
                ASSUME  DS:PROGRAM
                ASSUME  ES:PROGRAM

                ORG     100H

START:
                JMP     NOW

;RESERVED MEMORY:
TABLE_1         DW      ?                       ; Pointer at offsets.
TABLE_2         DW      ?                       ; Pointer at device name.
TABLE_3         DW      ?                       ; Pointer at id name.
TABLE_4         DW      ?                       ; Pointer at hwcp.
TABLE_5         DW      ?                       ; Pointer at desg and font.
TABLE           DB      290 DUP (?)             ; Table of parsed parms. Max 4 devices.
DEVNUM          DW      ?                       ; Counter to number of devices.
RIGHT_FLAG      DB      ?                       ; Flag to indicate a left bracket.
DEV_ERR_FLG     DB      ?                       ; Device name error flag.
ID_ERR_FLG      DB      ?                       ; Id name error flag.
ERROR_FLAG      DB      ?                       ; Error flag_terminate program if set to 1.
COMMA_FLAG      DB      ?                       ; Indicate the number of commas incounterd.
HWCP_FLAG       DB      ?                       ; Flag for multiple hwcps.
DESG_FLAG       DB      ?                       ; Flag indicates desg. and font.

;Main part of program-links different sumbroutines together
NOW:
                CALL    PARSER
                INT     20H                     ;Exit DOS.

PARSER          PROC

                PUSH    AX                      ; ;;;;;;;;;;;;;;;;;;
                PUSH    BX                      ; ;
                PUSH    CX                      ; ; SAVE
                PUSH    DX                      ; ; ALL
                PUSH    DS                      ; ; REGISTERS.
                PUSH    ES                      ; ;
                PUSH    DI                      ; ;
                PUSH    SI                      ; ;;;;;;;;;;;;;;;;;;

                ;LES     SI,RH.RH0_BPBA         ; Point at all after DEVICE=
                                                ; in the CONFIG.SYS file.

                mov     di,81h                  ; ;;;;;;;;;;;;;;;;;;;;;;;;;
                mov     cl,cs:byte ptr [di-1]   ; ;                      ;;
                xor     ch,ch                   ; ;        ERASE THIS    ;;
                add     di,cx                   ; ;;;;;;;; CODE IN       ;;
                mov     ds:word ptr[di],0a0dh   ; ; CPS                  ;;
                                                ; ;;;;;;;;               ;;
                MOV     SI,0081h                ; ;Set SI at parameters. ;;
                                                ; ;;;;;;;;;;;;;;;;;;;;;;;;;

;Skip to end of file name, to the first DOS delimiter.

                MOV     DEVNUM,02H              ; Number of devices counter.

GET_PARMS_A:    CALL    GET_CHAR                ; Get command character in AL .
                JZ      EXIT_B                  ; No parms found.
                CALL    IS_DELIM                ; If not a delimiter then.
                JNE     GET_PARMS_A             ; Check next character.

                MOV     DI,OFFSET TABLE         ; Get the table address.
                ADD     DI,02H                  ; Point at devices offsets.
                MOV     BX,DI                   ;
                ADD     BX,08H                  ; Point BX at parms offsets.
TAB2:           CALL    UPDATE_TABLE            ; Update table pointers value.

CLR_DELIM:      CALL    GET_CHAR                ; Get character into AL.
                JZ      EXIT_B                  ; No parms found.
                CALL    IS_ALPHA                ; If alpha then assume.
                JZ      DEVICE                  ; A device name.
                CALL    IS_DELIM                ; Is it a delimiter
                JNE     EXIT_A                  ; If not then error.
                JMP     CLR_DELIM               ; Get next character.

DEVICE:         MOV     DEV_ERR_FLG,00H         ; Set device error flag off;
                CALL    DEVICE_PARSE            ; Call routine to parse device name.
                CMP     DEV_ERR_FLG,01H         ; If error flag is
                JZ      EXIT_A                  ; set then exit.
                CALL    OFFSET_TABLE            ; Update table.

ID_PARMS:       CALL    GET_CHAR                ; Load a character in AL.
                JZ      EXIT_A                  ; Exit if end of line (error).
                CMP     AL,'('                  ; If AL is a '(' then
                JE      ID                      ; Parse ID name.
                CALL    IS_ALPHA                ; If an Alpha
                JE      ID                      ; Then parse ID name.
                CALL    IS_DIGIT                ; If a digit
                JE      ID                      ; Then parse ID name.
                CALL    IS_DELIM                ; If not a delimiter
                JNE     EXIT_A                  ; Then error, exit
                JMP     ID_PARMS                ; Get another number

EXIT_B:         CMP     DEVNUM,02H              ; If device number above 2 then
                JA      EXIT_C                  ; Exit parse.
                JMP     EXIT_A                  ; Else error, exit

ID:             MOV     ID_ERR_FLG,00H          ; Set id error flag off.
                CALL    ID_PARSE                ; Parse ID name.
                CMP     ID_ERR_FLG,01H          ; Was error flag set, then
                JE      EXIT_A                  ; Print error message.
                CALL    OFFSET_TABLE            ; Update table of offsets.

                CALL    HWCP_PARMS              ; Get code page number
                CMP     ERROR_FLAG,01H          ; If error, then
                JE      EXIT_A                  ; Print error message and exit
                CMP     ERROR_FLAG,02H          ; If end of string
                JE      EXIT_H                  ; Then exit.

                CALL    DESG_PARMS              ; Get designate number
                CMP     ERROR_FLAG,01H          ; If error, then
                JE      EXIT_A                  ; Print error message and exit
                JMP     EXIT_H                  ; Then exit.

EXIT_A:         MOV     DI,OFFSET TABLE         ; Load table offset
                MOV     DS:WORD PTR [DI],00H    ; Set error to on.
                STC                             ; Set carry flag
                JMP     EXIT_P                  ; Exit parse.

EXIT_H:         MOV     DI,OFFSET TABLE         ; Load table offset.
                ADD     DS:WORD PTR [DI],01H    ; Increment number of devices.
                CMP     DEVNUM,08H              ; If 4 devices loaded
                JE      EXIT_C                  ; Then exit parse.
                ADD     DEVNUM,02H              ; Increment the number of devices
                ADD     DI,DEVNUM               ; Point at next devices offset.
                MOV     BX,TABLE_5              ; BX point at
                ADD     BX,06H                  ; end of previous table.
                JMP     TAB2                    ; Get next device.

EXIT_C:         CLC

EXIT_P:         POP     SI                      ; ;;;;;;;;;;;;;;;;;;
                POP     DI                      ; ;
                POP     ES                      ; ;  RESTORE
                POP     DS                      ; ;  ALL
                POP     DX                      ; ;  REGISTERS.
                POP     CX                      ; ;
                POP     BX                      ; ;
                POP     AX                      ; ;;;;;;;;;;;;;;;;;;
                RET

PARSER          ENDP


;********************************************************
;** GET_CHAR : a routine to get next character pointed **
;** to by ES:SI into AL.                               **
;********************************************************

GET_CHAR        PROC

                MOV     AL,ES:BYTE PTR [SI]     ; Load character pointed to
                CMP     AL,09H                  ; by ES:[SI] in AL.
                JE      ZOFF                    ; If tab then O.K
                CMP     AL,20H                  ; Turn Z-flag on
                JL      TURN_Z_ON               ; if character
ZOFF:           INC     SI                      ; is below
                JMP     GET_CHAR_X              ; 20h.
                                                ; ( End of line
TURN_Z_ON:      CMP     AL,AL                   ;   delimiters ).
GET_CHAR_X:     RET

GET_CHAR        ENDP


;********************************************************
;** IS_ALPHA : a routine to check the character in     **
;** AL if it is an alpha character (a...z,A...Z).      **
;** If character is lower case, convert to upper case. **
;********************************************************

IS_ALPHA        PROC

                PUSH    AX                      ; Save value of AL
                AND     AL,0DFH                 ; Convert to upper case
                CMP     AL,'A'                  ; If <'A', then
                JB      IS_ALPHA_X              ; NZ-flag is set, exit
                CMP     AL,'Z'                  ; If >'Z', then
                JA      IS_ALPHA_X              ; NZ-flag is set, exit
                CMP     AL,AL                   ; Force Z-flag
                POP     DX                      ; Discard lower case.
                JMP     IA_X                    ; Exit.
IS_ALPHA_X:     POP     AX                      ; Restore value of AL
IA_X:           RET

IS_ALPHA        ENDP


;********************************************************
;** IS_DIGIT : a routine to check if the character in  **
;** AL register is a digit (i.e. 1..9).                **
;********************************************************

IS_DIGIT        PROC

                CMP     AL,'0'                  ; If < '0' then
                JB      IS_NUM_X                ; NZ-flag is set, exit
                CMP     AL,'9'                  ; If > '9' then
                JA      IS_NUM_X                ; NZ-flag is set, exit
                CMP     AL,AL                   ; Set Z-flag to indecate digit
IS_NUM_X:       RET

IS_DIGIT        ENDP


;********************************************************
;** IS_DELIM : This routine check if the character in  **
;** AL is a delimiter. ('+',' ',';',',','=',tab)       **
;********************************************************

IS_DELIM        PROC

                CMP     AL,' '                  ; Test for space.
                JE      IS_DELIM_X              ; Z-flag is set, exit
                CMP     AL,','                  ; Test for comma.
                JE      IS_DELIM_X              ; Z-flag is set, exit
                CMP     AL,';'                  ; Test for semicolon.
                JE      IS_DELIM_X              ; Z-flag is set, exit
                CMP     AL,'='                  ; Test for equal sign.
                JE      IS_DELIM_X              ; Z-flag is set, exit
                CMP     AL,09h                  ; Test for TAB.

IS_DELIM_X:     RET                             ; Exit

IS_DELIM        ENDP


;********************************************************
;** DEVICE_PARSE : Parse the device driver name and    **
;** store in table.  Update offset.                    **
;********************************************************

DEVICE_PARSE    PROC

                MOV     DI,TABLE_2
                MOV     DS:WORD PTR [DI],0008H  ; Save dev name size.
                ADD     DI,02H                  ; Increment DI.
                MOV     CX,9                    ; Set counter.
NEXT_C:         CALL    IS_ALPHA                ; if Check then.
                JZ      SAVE_C                  ; Save it.
                CALL    IS_DIGIT                ; if Digit then.
                JZ      SAVE_C                  ; Save it.
                CMP     AL,'-'                  ; If '-' then.
                JZ      SAVE_C                  ; Save it.
                CALL    IS_DELIM                ; If a delimiter then.
                JZ      ADD_SPACE1              ; Pad with spaces.
                CMP     AL,':'                  ; If a colon
                JE      ADD_SPACE1              ; then end device parse
                JMP     ERR_DEV_PAR             ; Else an error.

SAVE_C:         DEC     CX                      ; Decrement counter.
                CMP     CX,0                    ; If counter zero then.
                JE      ERR_DEV_PAR             ; Error.
                MOV     DS:BYTE PTR [DI],AL     ; Save char in table.
                INC     DI                      ; Increment pointer.
                CALL    GET_CHAR                ; Get another char.
                JZ      ERR_DEV_PAR
                JMP     NEXT_C                  ; Check char.

ERR_DEV_PAR:    MOV     DEV_ERR_FLG,01H         ; Set error flag.
                JMP     DEV_PAR_X               ; Exit.

ADD_SPACE1:     DEC     CX                      ; Check counter.
                CMP     CX,1
                JL      DEV_PAR_X               ; Exit if already 8.
LL1:            MOV     DS:BYTE PTR [DI],' '    ; Pad name with spaces.
                INC     DI                      ; Increment pointer.
                LOOP    LL1                     ; Loop again.
DEV_PAR_X:      RET

DEVICE_PARSE    ENDP


;********************************************************
;** ID_PARSE : Parse the id driver name and            **
;** store in table.  Update offset.                    **
;********************************************************

ID_PARSE        PROC

                MOV     DI,TABLE_3
                MOV     DS:WORD PTR [DI],0008H  ; Save dev name size.
                ADD     DI,02H                  ; Increment DI.
                MOV     RIGHT_FLAG,00H          ; Clear flag.
                MOV     CX,9                    ; Set counter.

NEXT_I:         CALL    IS_ALPHA                ; If Check then.
                JZ      SAVE_I                  ; Save it.
                CALL    IS_DIGIT                ; if Digit then.
                JZ      SAVE_I                  ; Save it.
                CMP     AL,'-'                  ; If '-' then.
                JZ      SAVE_I                  ; Save it.
                CMP     AL,'('                  ; If '(' then.
                JE      RIG_BR_FLG              ; Set flag.
                CMP     AL,')'                  ; If ')' then
                JE      BR_FLG_LEF              ; Pad with spaces.
                CALL    IS_DELIM                ; If a delimiter then.
                JZ      ADD_SPACE2              ; Pad with spaces.
                JMP     ERR_ID_PAR              ; Else an error.

SAVE_I:         DEC     CX                      ; Decrement counter.
                CMP     CX,0                    ; If counter zero then.
                JLE     ERR_ID_PAR              ; Error.
                MOV     DS:BYTE PTR [DI],AL     ; Save char in table.
                INC     DI                      ; Increment pointer.
                CALL    GET_CHAR                ; Get another char.
                JZ      ADD_SPACE2              ; Exit routine.
                JMP     NEXT_I                  ; Check char.

ERR_ID_PAR:     MOV     ID_ERR_FLG,01H          ; Set error falg on.
                JMP     ID_PAR_X                ; Exit.

BR_FLG_LEF:     CMP     RIGHT_FLAG,01H          ; If left bracket was
                JNE     ERR_ID_PAR              ; found and no previous
                JMP     ADD_SPACE2              ; Bracket found, then error

RIG_BR_FLG:     CMP     RIGHT_FLAG,01H          ; If more than one bracket
                JE      ERR_ID_PAR              ; then error.
                CMP     CX,09                   ; If '(' and already id
                JB      ERR_ID_PAR              ; then error.
                MOV     RIGHT_FLAG,01H          ; Set flag for.
                CALL    GET_CHAR                ; Left brackets.
                JZ      ERR_ID_PAR              ; If end of line,exit.
                JMP     NEXT_I                  ; Check character.

ADD_SPACE2:     DEC     CX                      ; Check counter.
                CMP     CX,1
                JL      ID_PAR_X                ; Exit if already 8.

LL2:            MOV     DS:BYTE PTR [DI],' '    ; Pad name with spaces.
                INC     DI                      ; Increment pointer.
                LOOP    LL2                     ; Loop again.

ID_PAR_X:       RET

ID_PARSE        ENDP

;********************************************************
;** HWCP_PARMS : Scane for the hardware code page, and **
;** parse it if found.  Flag  codes set to:            **
;** ERROR_FLAG = 0 - parsing completed. No error.      **
;** ERROR_FLAG = 1 - error found exit parse.           **
;** ERROR_FLAG = 2 - end of line found, exit parse.    **
;********************************************************


HWCP_PARMS      PROC

                MOV     COMMA_FLAG,00H          ; Set the comma flag off.
                MOV     ERROR_FLAG,00H          ; Set the error flag off.
                DEC     SI                      ; Point at current char in Al.
                CMP     RIGHT_FLAG,01H          ; If no left brackets then
                JNE     LEFT_BR                 ; Exit parse.

HWCP_1:         CALL    GET_CHAR                ; Load character in AL.
                JZ      LEFT_BR                 ; Exit, if end of line.
                CALL    IS_DIGIT                ; Check if digit, then
                JE      HP1                     ; Parse hwcp parms.
                CMP     AL,','                  ; If a comma
                JE      COMMA_1                 ; Jump to comma_1
                CMP     AL,')'                  ; If a ')' then
                JE      RIGHT_BR                ; end of current dev parms.
                CMP     AL,'('                  ; If a '(' then
                JE      HWCP_2                  ; There are multible hwcp.
                CALL    IS_DELIM                ; Else, if not a delimiter
                JNE     EXIT_2                  ; Then error, exit
                JMP     HWCP_1                  ; Get another character.

LEFT_BR:        CMP     RIGHT_FLAG,01H          ; If no left bracket
                JE      EXIT_2                  ; Then error, exit
                JMP     RB1                     ; Jump to rb1

COMMA_1:        CMP     COMMA_FLAG,01H          ; If comma flag set
                JE      COM_2_HC                ; Then exit hwcp parse.
                MOV     COMMA_FLAG,01H          ; Else set comma flag.
JMP HWCP_1 ; Get another character.

HWCP_2:         CMP     RIGHT_FLAG,01H          ; If left bracket not set
                JNE     EXIT_2                  ; then error.
                CALL    MUL_HWCP                ; else call multiple hwcp
                ADD     DI,02H                  ; routine.  Increment DI
                MOV     TABLE_5,DI              ; Desg. Table starts at end
                CALL    OFFSET_TABLE            ; Update table of offsets.
                JMP     HP_X                    ; Exit.

HP1:            JMP     HWCP                    ; Jump too long.

COM_2_HC:       MOV     DI,TABLE_4              ; DI points at hwcp table
                MOV     DS:WORD PTR [DI],0000H  ; Set number of pages to
                MOV     COMMA_FLAG,00H          ; Zero and reset comma flag.
                ADD     DI,02H                  ; Increment DI.
                MOV     TABLE_5,DI              ; Desg. Table starts at end
                CALL    OFFSET_TABLE            ; Update table of offsets.
                JMP     HP_X                    ; of hwcp table.  Exit.

RIGHT_BR:       CMP     RIGHT_FLAG,01H          ; If left brackets not
                JNE     EXIT_2                  ; Found then error.
RB1:            MOV     ERROR_FLAG,02H          ; Set end of line flag.
                MOV     BX,TABLE_4              ; Point at hwcp table
                ADD     BX,02H                  ; Adjust pointer to  desg
                MOV     TABLE_5,BX              ; table, and save in table_5
                MOV     DI,TABLE_1              ; Point at table of offsets
                ADD     DI,08H                  ; Set at DESG offset
                MOV     DS:WORD PTR [DI],BX     ; Update table.
                JMP     HP_X                    ; Exit



EXIT_2:         MOV     ERROR_FLAG,01H          ; Set error flag.
                JMP     HP_X                    ; and exit.

HWCP:           CMP     RIGHT_FLAG,01H          ; If left brackets not
                JNE     EXIT_2                  ; Found then error.
                CALL    HWCP_PARSE              ; Call parse one hwcp.
                CMP     ERROR_FLAG,01H          ; If error flag set
                JE      HP_X                    ; Then exit,  else
                CALL    OFFSET_TABLE            ; Update table of offsets.

HP_X:           RET

HWCP_PARMS      ENDP


;********************************************************
;** HWCP_PARSE : Parse the hardware code page page     **
;** number and change it from hex to binary.           **
;********************************************************

HWCP_PARSE      PROC

                MOV     DI,TABLE_4              ; Load address of hwcpages.
                ADD     DS:WORD PTR [DI],0001H  ; Set count to 1

                CALL    GET_NUMBER              ; Convert number to binary.
                CMP     ERROR_FLAG,01H          ; If error then
                JE      HWCP_X                  ; Exit.
                MOV     DS:WORD PTR [DI+2],BX   ; Else, save binary page number
                ADD     DI,04H                  ; Increment counter
                MOV     TABLE_5,DI              ; Set pointer of designate num

HWCP_X:         RET

HWCP_PARSE      ENDP


;********************************************************
;** MUL_HWCP : Parse multiple hardware code pages      **
;** and convert them from hex to binary numbers.       **
;********************************************************

MUL_HWCP        PROC

                MOV     DI,TABLE_4              ; Load offset of table_4
                MOV     BX,DI                   ; in DI and Bx.
                MOV     HWCP_FLAG,00H           ; Set hwcp flag off.

MH1:            CALL    GET_CHAR                ; Load character in AL.
                JZ      MH3                     ; Exit if end of line.
                CMP     AL,')'                  ; If ')' then exit
                JE      MH2                     ; end of parms.
                CALL    IS_DIGIT                ; If a digit, then
                JE      MH4                     ; Convert number to binary.
                CALL    IS_DELIM                ; If not a delimiter
                JNE     MH3                     ; then error, exit
                JMP     MH1                     ; get another character.

MH2:            CALL    GET_CHAR                ; Get next character
                JMP     MH_X                    ; and exit.

MH3:            MOV     ERROR_FLAG,01H          ; Set error flag on.
                JMP     MH_X                    ; Exit.

MH4:            ADD     HWCP_FLAG,01H           ; Set hwcp flag on (0 off)
                ADD     DI,02H                  ; Increment table pointer
                PUSH    BX                      ; Save Bx
                CALL    GET_NUMBER              ; Convert number to binary.
                MOV     DS:WORD PTR [DI],BX     ; Add number to table
                POP     BX                      ; Restore BX.
                CMP     ERROR_FLAG,01H          ; If error then
                JE      MH_X                    ; Exit.
                ADD     DS:WORD PTR [BX],01H    ; Increment hwcp count.
                DEC     SI                      ; Point at character in AL
                JMP     MH1                     ;   (delimeter or ')').
MH_X:           RET

MUL_HWCP        ENDP



;********************************************************
;** DESG_PARMS : Scane for the designate numbers, and  **
;** parse it if found.  Flag  codes set to:            **
;** ERROR_FLAG = 0 - parsing completed. No error.      **
;** ERROR_FLAG = 1 - error found exit parse.           **
;** ERROR_FLAG = 2 - end of line found, exit parse.    **
;********************************************************


DESG_PARMS      PROC

                MOV     DI,TABLE_1              ; Get offset of dev in DI
                MOV     BX,TABLE_5              ; & offset of desg. in BX.
                ADD     DI,08                   ; Location of desg offset in table.
                MOV     DS:WORD PTR [DI],BX     ; Update table.
                MOV     COMMA_FLAG,00H          ; Set comma flag off.

                cmp     al,'('
                je      df
                cmp     al,')'
                je      right_br2

                cmp     al,','
                jne     desg_parm1
                mov     comma_flag,01h

DESG_PARM1:     CALL    GET_CHAR                ; Get character in AL.
                JZ      EXIT_3                  ; Error, if end of line
                CALL    IS_DIGIT                ; If character is a digit
                JE      DESG                    ; Then convert to binary.
                CMP     AL,')'                  ; If a ')', then
                JE      RIGHT_BR2               ; end of parameters.
                CMP     AL,'('                  ; If a '(' then
                JE      DF                      ; parse desg and font.
                CMP     AL,','                  ; If a comma then
                JE      DP3                     ; set flag.
                CALL    IS_DELIM                ; If not a delimiter
                JNE     EXIT_3                  ; then error.
                JMP     DESG_PARM1              ; Get another character.

RIGHT_BR2:      CMP     RIGHT_FLAG,01H          ; IF no '(' encountered,
                JNE     EXIT_3                  ; then error, exit
                JMP     DP_x                    ; Jump to DP1.

EXIT_3:         MOV     ERROR_FLAG,01H          ; Set error flag on
                JMP     DP_X                    ; Exit.

DF:             CMP     RIGHT_FLAG,01H          ; If no '(' encountered
                JB      EXIT_3                  ; then error, exit
                CALL    DESG_FONT               ; Parse desg and font.
                JMP     DP1                     ; Jump to DP1.

DP2:            CALL    FIND_RIGHT_BR           ; Check for ')'
                JMP     DP_X                    ; Exit.

DP3:            CMP     COMMA_FLAG,01H          ; If comma flag set
                JE      DP2                     ; then error
                MOV     COMMA_FLAG,01H          ; Else set comma flag on.
                JMP     DESG_PARM1              ; Get another character.

DESG:           MOV     ERROR_FLAG,00H          ; Set error flag off.
                CALL    DESG_PARSE              ; Parse desg.
DP1:            CMP     ERROR_FLAG,01H          ; If error flag on then
                JE      DP_X                    ; Exit,
                CALL    FIND_RIGHT_BR           ; Else check for ')'
                CALL    OFFSET_TABLE            ; Update table

DP_X:           RET

DESG_PARMS      ENDP



;********************************************************
;** DESG_FONT : Parse the designate and font numbers & **
;** change them from decimal to binary.                **
;********************************************************


DESG_FONT       PROC


                MOV     DI,TABLE_5              ; Get desg font table.
                MOV     COMMA_FLAG,00H          ; Set comma flag off.
DF1:            CALL    GET_CHAR                ; Load a character in AL.
                JZ      DF3                     ; Error if end of line.
                CMP     AL,','                  ; Check if a comma.
                JE      DF2                     ; Set flag.
                CALL    IS_DIGIT                ; If a digit, then
                JE      DF5                     ; Convert number to binary.
                CMP     AL,')'                  ; If a ')' then
                JE      DF4                     ; Exit.
                CALL    IS_DELIM                ; If not a delimiter
                JNE     DF3                     ; then error, exit
                JMP     DF1                     ; Get another character.

DF2:            CMP     COMMA_FLAG,01H          ; If comma flag on
                JE      DF3                     ; then error, exit
                MOV     COMMA_FLAG,01H          ; Set comma flag on
                ADD     DS:WORD PTR [DI],01H      ; Increment desg counter.
                MOV     DS:WORD PTR [DI+2],0FFFFH ; Load ffffh for desg empty
                JMP     DF1                       ; field.

DF3:            MOV     ERROR_FLAG,01H          ; Set error flag on.
                JMP     DF_X                    ; Exit.

DF4:            CMP     DESG_FLAG,00H           ; If desg flag off
                JE      DF3                     ; then error, exit
                JMP     DF_X                    ; Else exit.

DF5:            ADD     DS:WORD PTR [DI],01H    ; Increment desg font count.
                CMP     DESG_FLAG,01H           ; If desg flag is on
                JE      DF6                     ; then get font.
                CMP     COMMA_FLAG,01H          ; if comma flag is on
                JE      DF6                     ; then get font.
                MOV     DESG_FLAG,01H           ; Set desg flag on
                JMP     DF7                     ; Get desg number.

DF6:            ADD     DI,02H                  ; adjust pointer to font.
                MOV     DESG_FLAG,02H           ; Set desg and font flag.
DF7:            CALL    GET_NUMBER              ; Get a number & convert to
                CMP     ERROR_FLAG,01H          ; binary.
                JE      DF_X                    ; If error flag set, Exit.
                MOV     DS:WORD PTR [DI+2],BX   ; Store number in table.
                CMP     DESG_FLAG,02H           ; If desg and font flag
                JNE     DF1                     ; not set, then get char.
                CALL    FIND_RIGHT_BR           ; Check for right bracket.

DF_X:           RET

DESG_FONT       ENDP


;********************************************************
;** DESG_PARSE : Parse the designate number and        **
;** change it from decimal to binary.                  **
;********************************************************

DESG_PARSE      PROC

                MOV     DI,TABLE_5              ; Load designate location
                ADD     DS:WORD PTR [DI],0001H  ; Update table count.

                CALL    GET_NUMBER              ; Get the ascii number and
                CMP     ERROR_FLAG,01H          ; conver it to binary
                JE      DESG_X                  ; If error then exit

                MOV     DS:WORD PTR [DI+2],BX   ; Else, save desg number


DESG_X:         RET

DESG_PARSE      ENDP


;********************************************************
;** GET_NUMBER : Convert the number pointed to by  SI  **
;** to a binary number and store it in BX              **
;********************************************************

GET_NUMBER      PROC

                MOV     CX,0AH                  ; Set multiplying factor
                XOR     BX,BX                   ; Clear DX

NEXT_NUM:       SUB     AL,30H                  ; Conver number to binary
                CBW                             ; Clear AH
                XCHG    AX,BX                   ; Switch ax and bx to mul
                MUL     CX                      ; already converted number by 10.
                JO      ERR_NUM                 ; On over flow jump to error.
                ADD     BX,AX                   ; Add number to total.
                JC      ERR_NUM                 ; On over flow jump to error.
                XOR     AX,AX                   ; Clear AX (clear if al=0a).
                CALL    GET_CHAR                ; Get next character
                JZ      GET_NUM_X               ; Exit, if end of line.
                CALL    IS_DIGIT                ; Call is digit.
                JNZ     GET_NUM_X               ; Exit if not a number.
                JMP     NEXT_NUM                ; Loop.

ERR_NUM:        MOV     ERROR_FLAG,01H          ; Set error code to 1.

GET_NUM_X:      RET

GET_NUMBER      ENDP


;********************************************************
;** UPDATE_TABLE : This routine set up pointers to the **
;** different offsets of the different tables          **
;********************************************************

UPDATE_TABLE    PROC

                MOV     DS:WORD PTR [DI],BX     ; Offset of offsets
                MOV     TABLE_1,BX              ; Table_1 points at offsets

                MOV     DI,BX                   ;
                ADD     BX,0CH                  ;
                MOV     DS:WORD PTR [DI+2],BX   ; Offset of DEVICE name.
                MOV     TABLE_2,BX              ; Table_2 point at device name.

                ADD     BX,0AH                  ;
                MOV     DS:WORD PTR [DI+4],BX   ; Offset of ID name.
                MOV     TABLE_3,BX              ; Table_3 point at ID name.

                ADD     BX,0AH                  ;
                MOV     DS:WORD PTR [DI+6],BX   ; Offset of HWCP pages.
                MOV     TABLE_4,BX              ; Table_4 point at HWCP pages.

                RET

UPDATE_TABLE    ENDP


;********************************************************
;** OFFSET_TABLE : This routine set up pointers of     **
;** tables number one and two.                         **
;********************************************************

OFFSET_TABLE    PROC

                MOV     DI,TABLE_1              ; Increment the number
                ADD     DS:WORD PTR [DI],01H    ; of parms foun. (ie. id,hwcp
                RET                             ; and desg)

OFFSET_TABLE    ENDP


;********************************************************
;** FIND_RIGHT_BR :This routine scane the line for a   **
;** ')' if cannot find it turns error flag on          **
;********************************************************

FIND_RIGHT_BR   PROC

FBR1:           CMP     AL,')'                  ; If a right bracket
                JE      FBR_X                   ; then exit.
                CMP     AL,' '                  ; If not a space
                JNE     FBR2                    ; Then error.
                CALL    GET_CHAR                ; Get a character
                JZ      FBR2                    ; If end of line then exit.
                JMP     FBR1                    ; Else get another character.

FBR2:           MOV     ERROR_FLAG,01H          ; Set error flag on
FBR_X:          MOV     AL,20H                  ; Erase character from AL.
                RET

FIND_RIGHT_BR   ENDP


PROGRAM         ENDS
                END     START
