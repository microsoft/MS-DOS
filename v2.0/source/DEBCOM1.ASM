TITLE   PART1 DEBUGGER COMMANDS

; Routines to perform debugger commands except ASSEMble and UASSEMble

.xlist
.xcref
        INCLUDE DEBEQU.ASM
        INCLUDE DOSSYM.ASM
.cref
.list

CODE    SEGMENT PUBLIC BYTE 'CODE'
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE

        EXTRN   SYNERR:BYTE

        EXTRN   DISPB:WORD,DSIZ:BYTE,DSSAVE:WORD
        if  sysver
        EXTRN   CIN:DWORD,PFLAG:BYTE
        endif

CONST   ENDS

DATA    SEGMENT PUBLIC BYTE

        EXTRN   DEFLEN:WORD,BYTEBUF:BYTE,DEFDUMP:BYTE

DATA    ENDS

DG      GROUP   CODE,CONST,DATA


CODE    SEGMENT PUBLIC BYTE 'CODE'
ASSUME  CS:DG,DS:DG,ES:DG,SS:DG


        PUBLIC  HEXCHK,GETHEX1,PRINT,DSRANGE,ADDRESS,HEXIN,PERROR
        PUBLIC  GETHEX,GET_ADDRESS,GETEOL,GETHX,PERR
        PUBLIC  PERR,MOVE,DUMP,ENTER,FILL,SEARCH,DEFAULT
        if  sysver
        PUBLIC  IN
        EXTRN   DISPREG:NEAR,DEVIOCALL:NEAR
        endif

        EXTRN   OUT:NEAR,CRLF:NEAR,OUTDI:NEAR,OUTSI:NEAR,SCANP:NEAR
        EXTRN   SCANB:NEAR,BLANK:NEAR,TAB:NEAR,PRINTMES:NEAR,COMMAND:NEAR
        EXTRN   HEX:NEAR,BACKUP:NEAR


DEBCOM1:

; RANGE - Looks for parameters defining an address range.
; The first parameter is the starting address. The second parameter
; may specify the ending address, or it may be preceded by
; "L" and specify a length (4 digits max), or it may be
; omitted and a length of 128 bytes is assumed. Returns with
; segment in AX, displacement in DX, and length in CX.

DSRANGE:
        MOV     BP,[DSSAVE]             ; Set default segment to DS
        MOV     [DEFLEN],128            ; And default length to 128 bytes
RANGE:
        CALL    ADDRESS
        PUSH    AX                      ; Save segment
        PUSH    DX                      ; Save offset
        CALL    SCANP                   ; Get to next parameter
        MOV     AL,[SI]
        CMP     AL,"L"                  ; Length indicator?
        JE      GETLEN
        MOV     DX,[DEFLEN]             ; Default length
        CALL    HEXIN                   ; Second parameter present?
        JC      GetDef                  ; If not, use default
        MOV     CX,4
        CALL    GETHEX                  ; Get ending address (same segment)
        MOV     CX,DX                   ; Low 16 bits of ending addr.
        POP     DX                      ; Low 16 bits of starting addr.
        SUB     CX,DX                   ; Compute range
        JAE     DSRNG2
DSRNG1: JMP     PERROR                  ; Negative range
DSRNG2: INC     CX                      ; Include last location
        JCXZ    DSRNG1                  ; Wrap around error
        POP     AX                      ; Restore segment
        RET
GetDef:
        POP     CX                      ; get original offset
        PUSH    CX                      ; save it
        NEG     CX                      ; rest of segment
        JZ      RngRet                  ; use default
        CMP     CX,DX                   ; more room in segment?
        JAE     RngRet                  ; yes, use default
        JMP     RngRet1                 ; no, length is in CX

GETLEN:
        INC     SI                      ; Skip over "L" to length
        MOV     CX,4                    ; Length may have 4 digits
        CALL    GETHEX                  ; Get the range
RNGRET:
        MOV     CX,DX                   ; Length
RngRet1:
        POP     DX                      ; Offset
        MOV     AX,CX
        ADD     AX,DX
        JNC     OKRET
        CMP     AX,1
        JAE     DSRNG1                  ; Look for wrap error
OKRET:
        POP     AX                      ; Segment
        RET

DEFAULT:
; DI points to default address and CX has default length
        CALL    SCANP
        JZ      USEDEF                  ; Use default if no parameters
        MOV     [DEFLEN],CX
        CALL    RANGE
        JMP     GETEOL
USEDEF:
        MOV     SI,DI
        LODSW                           ; Get default displacement
        MOV     DX,AX
        LODSW                           ; Get default segment
        RET

; Dump an area of memory in both hex and ASCII

DUMP:
        MOV     BP,[DSSAVE]
        MOV     CX,DISPB
        MOV     DI,OFFSET DG:DEFDUMP
        CALL    DEFAULT                 ; Get range if specified
        MOV     DS,AX                   ; Set segment
        MOV     SI,DX                   ; SI has displacement in segment

        IF  ZIBO
        PUSH    SI                      ; save SI away
        AND     SI,0FFF0h               ; convert to para number
        CALL    OutSI                   ; display location
        POP     SI                      ; get SI back
        MOV     AX,SI                   ; move offset
        MOV     AH,3                    ; spaces per byte
        AND     AL,0Fh                  ; convert to real offset
        MUL     AH                      ; compute (AL+1)*3-1
        OR      AL,AL                   ; set flag
        JZ      InRow                   ; if xero go on
        PUSH    CX                      ; save count
        MOV     CX,AX                   ; move to convenient spot
        CALL    Tab                     ; move over
        POP     CX                      ; get back count
        JMP     InRow                   ; display line
        ENDIF

ROW:
        CALL    OUTSI                   ; Print address at start of line
InRow:
        PUSH    SI                      ; Save address for ASCII dump
        CALL    BLANK
BYTE0:
        CALL    BLANK                   ; Space between bytes
BYTE1:
        LODSB                           ; Get byte to dump
        CALL    HEX                     ; and display it
        POP     DX                      ; DX has start addr. for ASCII dump
        DEC     CX                      ; Drop loop count
        JZ      ToAscii                 ; If through do ASCII dump
        MOV     AX,SI
        TEST    AL,CS:(BYTE PTR DSIZ)   ; On 16-byte boundary?
        JZ      ENDROW
        PUSH    DX                      ; Didn't need ASCII addr. yet
        TEST    AL,7                    ; On 8-byte boundary?
        JNZ     BYTE0
        MOV     AL,"-"                  ; Mark every 8 bytes
        CALL    OUT
        JMP     SHORT BYTE1
ENDROW:
        CALL    ASCII                   ; Show it in ASCII
        JMP     SHORT ROW               ; Loop until count is zero
ToAscii:
        MOV     AX,SI                   ; get offset
        AND     AL,0Fh                  ; real offset
        JZ      ASCII                   ; no loop if already there
        SUB     AL,10h                  ; remainder
        NEG     AL
        MOV     CL,3
        MUL     CL
        MOV     CX,AX                   ; number of chars to move
        CALL    Tab
ASCII:
        PUSH    CX                      ; Save byte count
        MOV     AX,SI                   ; Current dump address
        MOV     SI,DX                   ; ASCII dump address
        SUB     AX,DX                   ; AX=length of ASCII dump
        IF NOT ZIBO
; Compute tab length. ASCII dump always appears on right side
; screen regardless of how many bytes were dumped. Figure 3
; characters for each byte dumped and subtract from 51, which
; allows a minimum of 3 blanks after the last byte dumped.
        MOV     BX,AX
        SHL     AX,1                    ; Length times 2
        ADD     AX,BX                   ; Length times 3
        MOV     CX,51
        SUB     CX,AX                   ; Amount to tab in CX
        CALL    TAB
        MOV     CX,BX                   ; ASCII dump length back in CX
        ELSE
        MOV     CX,SI                   ; get starting point
        DEC     CX
        AND     CX,0Fh
        INC     CX
        AND     CX,0Fh
        ADD     CX,3                    ; we have the correct number to tab
        PUSH    AX                      ; save count
        CALL    TAB
        POP     CX                      ; get count back
        ENDIF
ASCDMP:
        LODSB                           ; Get ASCII byte to dump
        AND     AL,7FH                  ; ASCII uses 7 bits
        CMP     AL,7FH                  ; Don't try to print RUBOUT
        JZ      NOPRT
        CMP     AL," "                  ; Check for control characters
        JNC     PRIN
NOPRT:
        MOV     AL,"."                  ; If unprintable character
PRIN:
        CALL    OUT                     ; Print ASCII character
        LOOP    ASCDMP                  ; CX times
        POP     CX                          ; Restore overall dump length
        MOV     ES:WORD PTR [DEFDUMP],SI
        MOV     ES:WORD PTR [DEFDUMP+2],DS  ; Save last address as default
        CALL    CRLF                        ; Print CR/LF and return
        RET


; Block move one area of memory to another. Overlapping moves
; are performed correctly, i.e., so that a source byte is not
; overwritten until after it has been moved.

MOVE:
        CALL    DSRANGE                 ; Get range of source area
        PUSH    CX                      ; Save length
        PUSH    AX                      ; Save segment
        PUSH    DX                      ; Save source displacement
        CALL    ADDRESS                 ; Get destination address (same segment)
        CALL    GETEOL                  ; Check for errors
        POP     SI
        MOV     DI,DX                   ; Set dest. displacement
        POP     BX                      ; Source segment
        MOV     DS,BX
        MOV     ES,AX                   ; Destination segment
        POP     CX                      ; Length
        CMP     DI,SI                   ; Check direction of move
        SBB     AX,BX                   ; Extend the CMP to 32 bits
        JB      COPYLIST                ; Move forward into lower mem.
; Otherwise, move backward. Figure end of source and destination
; areas and flip direction flag.
        DEC     CX
        ADD     SI,CX                   ; End of source area
        ADD     DI,CX                   ; End of destination area
        STD                             ; Reverse direction
        INC     CX
COPYLIST:
        MOVSB                           ; Do at least 1 - Range is 1-10000H not 0-FFFFH
        DEC     CX
        REP     MOVSB                   ; Block move
RET1:   RET

; Fill an area of memory with a list values. If the list
; is bigger than the area, don't use the whole list. If the
; list is smaller, repeat it as many times as necessary.

FILL:
        CALL    DSRANGE                 ; Get range to fill
        PUSH    CX                      ; Save length
        PUSH    AX                      ; Save segment number
        PUSH    DX                      ; Save displacement
        CALL    LIST                    ; Get list of values to fill with
        POP     DI                      ; Displacement in segment
        POP     ES                      ; Segment
        POP     CX                      ; Length
        CMP     BX,CX                   ; BX is length of fill list
        MOV     SI,OFFSET DG:BYTEBUF    ; List is in byte buffer
        JCXZ    BIGRNG
        JAE     COPYLIST                ; If list is big, copy part of it
BIGRNG:
        SUB     CX,BX                   ; How much bigger is area than list?
        XCHG    CX,BX                   ; CX=length of list
        PUSH    DI                      ; Save starting addr. of area
        REP     MOVSB                   ; Move list into area
        POP     SI
; The list has been copied into the beginning of the
; specified area of memory. SI is the first address
; of that area, DI is the end of the copy of the list
; plus one, which is where the list will begin to repeat.
; All we need to do now is copy [SI] to [DI] until the
; end of the memory area is reached. This will cause the
; list to repeat as many times as necessary.
        MOV     CX,BX                   ; Length of area minus list
        PUSH    ES                      ; Different index register
        POP     DS                      ; requires different segment reg.
        JMP     SHORT COPYLIST          ; Do the block move

; Search a specified area of memory for given list of bytes.
; Print address of first byte of each match.

SEARCH:
        CALL    DSRANGE                 ; Get area to be searched
        PUSH    CX                      ; Save count
        PUSH    AX                      ; Save segment number
        PUSH    DX                      ; Save displacement
        CALL    LIST                    ; Get search list
        DEC     BX                      ; No. of bytes in list-1
        POP     DI                      ; Displacement within segment
        POP     ES                      ; Segment
        POP     CX                      ; Length to be searched
        SUB     CX,BX                   ;  minus length of list
SCAN:
        MOV     SI,OFFSET DG:BYTEBUF    ; List kept in byte buffer
        LODSB                           ; Bring first byte into AL
DOSCAN:
        SCASB                           ; Search for first byte
        LOOPNE  DOSCAN                  ; Do at least once by using LOOP
        JNZ     RET1                    ; Exit if not found
        PUSH    BX                      ; Length of list minus 1
        XCHG    BX,CX
        PUSH    DI                      ; Will resume search here
        REPE    CMPSB                   ; Compare rest of string
        MOV     CX,BX                   ; Area length back in CX
        POP     DI                      ; Next search location
        POP     BX                      ; Restore list length
        JNZ     TEST                    ; Continue search if no match
        DEC     DI                      ; Match address
        CALL    OUTDI                   ; Print it
        INC     DI                      ; Restore search address
        CALL    CRLF
TEST:
        JCXZ    RET1
        JMP     SHORT SCAN              ; Look for next occurrence

; Get the next parameter, which must be a hex number.
; CX is maximum number of digits the number may have.

GETHX:
        CALL    SCANP
GETHX1:
        XOR     DX,DX                   ; Initialize the number
        CALL    HEXIN                   ; Get a hex digit
        JC      HXERR                   ; Must be one valid digit
        MOV     DL,AL                   ; First 4 bits in position
GETLP:
        INC     SI                      ; Next char in buffer
        DEC     CX                      ; Digit count
        CALL    HEXIN                   ; Get another hex digit?
        JC      RETHX                   ; All done if no more digits
        STC
        JCXZ    HXERR                   ; Too many digits?
        SHL     DX,1                    ; Multiply by 16
        SHL     DX,1
        SHL     DX,1
        SHL     DX,1
        OR      DL,AL                   ; and combine new digit
        JMP     SHORT GETLP             ; Get more digits

GETHEX:
        CALL    GETHX                   ; Scan to next parameter
        JMP     SHORT GETHX2
GETHEX1:
        CALL    GETHX1
GETHX2: JC      PERROR
RETHX:  CLC
HXERR:  RET


; Check if next character in the input buffer is a hex digit
; and convert it to binary if it is. Carry set if not.

HEXIN:
        MOV     AL,[SI]

; Check if AL has a hex digit and convert it to binary if it
; is. Carry set if not.

HEXCHK:
        SUB     AL,"0"                  ; Kill ASCII numeric bias
        JC      RET2
        CMP     AL,10
        CMC
        JNC     RET2                    ; OK if 0-9
        AND     AL,5FH
        SUB     AL,7                    ; Kill A-F bias
        CMP     AL,10
        JC      RET2
        CMP     AL,16
        CMC
RET2:   RET

; Process one parameter when a list of bytes is
; required. Carry set if parameter bad. Called by LIST.

LISTITEM:
        CALL    SCANP                   ; Scan to parameter
        CALL    HEXIN                   ; Is it in hex?
        JC      STRINGCHK               ; If not, could be a string
        MOV     CX,2                    ; Only 2 hex digits for bytes
        CALL    GETHEX                  ; Get the byte value
        MOV     [BX],DL                 ; Add to list
        INC     BX
GRET:   CLC                             ; Parameter was OK
        RET
STRINGCHK:
        MOV     AL,[SI]                 ; Get first character of param
        CMP     AL,"'"                  ; String?
        JZ      STRING
        CMP     AL,'"'                  ; Either quote is all right
        JZ      STRING
        STC                             ; Not string, not hex - bad
        RET
STRING:
        MOV     AH,AL                   ; Save for closing quote
        INC     SI
STRNGLP:
        LODSB                           ; Next char of string
        CMP     AL,13                   ; Check for end of line
        JZ      PERR                    ; Must find a close quote
        CMP     AL,AH                   ; Check for close quote
        JNZ     STOSTRG                 ; Add new character to list
        CMP     AH,[SI]                 ; Two quotes in a row?
        JNZ     GRET                    ; If not, we're done
        INC     SI                      ; Yes - skip second one
STOSTRG:
        MOV     [BX],AL                 ; Put new char in list
        INC     BX
        JMP     SHORT STRNGLP           ; Get more characters

; Get a byte list for ENTER, FILL or SEARCH. Accepts any number
; of 2-digit hex values or character strings in either single
; (') or double (") quotes.

LIST:
        MOV     BX,OFFSET DG:BYTEBUF    ; Put byte list in the byte buffer
LISTLP:
        CALL    LISTITEM                ; Process a parameter
        JNC     LISTLP                  ; If OK, try for more
        SUB     BX,OFFSET DG:BYTEBUF    ; BX now has no. of bytes in list
        JZ      PERROR                  ; List must not be empty

; Make sure there is nothing more on the line except for
; blanks and carriage return. If there is, it is an
; unrecognized parameter and an error.

GETEOL:
        CALL    SCANB                   ; Skip blanks
        JNZ     PERROR                  ; Better be a RETURN
RET3:   RET

; Command error. SI has been incremented beyond the
; command letter so it must decremented for the
; error pointer to work.

PERR:
        DEC     SI

; Syntax error. SI points to character in the input buffer
; which caused error. By subtracting from start of buffer,
; we will know how far to tab over to appear directly below
; it on the terminal. Then print "^ Error".

PERROR:
        SUB     SI,OFFSET DG:(BYTEBUF-1); How many char processed so far?
        MOV     CX,SI                   ; Parameter for TAB in CX
        CALL    TAB                     ; Directly below bad char
        MOV     SI,OFFSET DG:SYNERR     ; Error message

; Print error message and abort to command level

PRINT:
        CALL    PRINTMES
        JMP     COMMAND

; Gets an address in Segment:Displacement format. Segment may be omitted
; and a default (kept in BP) will be used, or it may be a segment
; register (DS, ES, SS, CS). Returns with segment in AX, OFFSET in DX.

ADDRESS:
        CALL    GET_ADDRESS
        JC      PERROR
ADRERR: STC
        RET

GET_ADDRESS:
        CALL    SCANP
        MOV     AL,[SI+1]
        CMP     AL,"S"
        JZ      SEGREG
        MOV     CX,4
        CALL    GETHX
        JC      ADRERR
        MOV     AX,BP                   ; Get default segment
        CMP     BYTE PTR [SI],":"
        JNZ     GETRET
        PUSH    DX
GETDISP:
        INC     SI                      ; Skip over ":"
        MOV     CX,4
        CALL    GETHX
        POP     AX
        JC      ADRERR
GETRET: CLC
        RET
SEGREG:
        MOV     AL,[SI]
        MOV     DI,OFFSET DG:SEGLET
        MOV     CX,4
        REPNE   SCASB
        JNZ     ADRERR
        INC     SI
        INC     SI
        SHL     CX,1
        MOV     BX,CX
        CMP     BYTE PTR [SI],":"
        JNZ     ADRERR
        PUSH    [BX+DSSAVE]
        JMP     SHORT GETDISP

SEGLET  DB      "CSED"

; Short form of ENTER command. A list of values from the
; command line are put into memory without using normal
; ENTER mode.

GETLIST:
        CALL    LIST                    ; Get the bytes to enter
        POP     DI                      ; Displacement within segment
        POP     ES                      ; Segment to enter into
        MOV     SI,OFFSET DG:BYTEBUF    ; List of bytes is in byte 2uffer
        MOV     CX,BX                   ; Count of bytes
        REP     MOVSB                   ; Enter that byte list
        RET

; Enter values into memory at a specified address. If the
; line contains nothing but the address we go into "enter
; mode", where the address and its current value are printed
; and the user may change it if desired. To change, type in
; new value in hex. Backspace works to correct errors. If
; an illegal hex digit or too many digits are typed, the
; bell is sounded but it is otherwise ignored. To go to the
; next byte (with or without change), hit space bar. To
; back   CLDto a previous address, type "-". On
; every 8-byte boundary a new line is started and the address
; is printed. To terminate command, type carriage return.
;   Alternatively, the list of bytes to be entered may be
; included on the original command line immediately following
; the address. This is in regular LIST format so any number
; of hex values or strings in quotes may be entered.

ENTER:
        MOV     BP,[DSSAVE]             ; Set default segment to DS
        CALL    ADDRESS
        PUSH    AX                      ; Save for later
        PUSH    DX
        CALL    SCANB                   ; Any more parameters?
        JNZ     GETLIST                 ; If not end-of-line get list
        POP     DI                      ; Displacement of ENTER
        POP     ES                      ; Segment
GETROW:
        CALL    OUTDI                   ; Print address of entry
        CALL    BLANK                   ; Leave a space
        CALL    BLANK
GETBYTE:
        MOV     AL,ES:[DI]              ; Get current value
        CALL    HEX                     ; And display it
PUTDOT:
        MOV     AL,"."
        CALL    OUT                     ; Prompt for new value
        MOV     CX,2                    ; Max of 2 digits in new value
        MOV     DX,0                    ; Intial new value
GETDIG:
        CALL    IN                      ; Get digit from user
        MOV     AH,AL                   ; Save
        CALL    HEXCHK                  ; Hex digit?
        XCHG    AH,AL                   ; Need original for echo
        JC      NOHEX                   ; If not, try special command
        MOV     DH,DL                   ; Rotate new value
        MOV     DL,AH                   ; And include new digit
        LOOP    GETDIG                  ; At most 2 digits
; We have two digits, so all we will accept now is a command.
DWAIT:
        CALL    IN                      ; Get command character
NOHEX:
        CMP     AL,8                    ; Backspace
        JZ      BS
        CMP     AL,7FH                  ; RUBOUT
        JZ      RUB
        CMP     AL,"-"                  ; Back   CLDto previous address
        JZ      PREV
        CMP     AL,13                   ; All done with command?
        JZ      EOL
        CMP     AL," "                  ; Go to next address
        JZ      NEXT
        MOV     AL,8
        CALL    OUT                     ; Back   CLDover illegal character
        CALL    BACKUP
        JCXZ    DWAIT
        JMP     SHORT GETDIG

RUB:
        MOV     AL,8
        CALL    OUT
BS:
        CMP     CL,2                    ; CX=2 means nothing typed yet
        JZ      PUTDOT                  ; Put back the dot we backed     CLDover
        INC     CL                      ; Accept one more character
        MOV     DL,DH                   ; Rotate out last digit
        MOV     DH,CH                   ; Zero this digit
        CALL    BACKUP                  ; Physical backspace
        JMP     SHORT GETDIG            ; Get more digits

; If new value has been entered, convert it to binary and
; put into memory. Always bump pointer to next location

STORE:
        CMP     CL,2                    ; CX=2 means nothing typed yet
        JZ      NOSTO                   ; So no new value to store
; Rotate DH left 4 bits to combine with DL and make a byte value
        PUSH    CX
        MOV     CL,4
        SHL     DH,CL
        POP     CX
        OR      DL,DH                   ; Hex is now converted to binary
        MOV     ES:[DI],DL              ; Store new value
NOSTO:
        INC     DI                      ; Prepare for next location
        RET
NEXT:
        CALL    STORE                   ; Enter new value
        INC     CX                      ; Leave a space plus two for
        INC     CX                      ;  each digit not entered
        CALL    TAB
        MOV     AX,DI                   ; Next memory address
        AND     AL,7                    ; Check for 8-byte boundary
        JNZ     GETBYTE                 ; Take 8 per line
NEWROW:
        CALL    CRLF                    ; Terminate line
        JMP     GETROW                  ; Print address on new line
PREV:
        CALL    STORE                   ; Enter the new value
; DI has been bumped to next byte. Drop it 2 to go to previous addr
        DEC     DI
        DEC     DI
        JMP     SHORT NEWROW            ; Terminate line after backing   CLD

EOL:
        CALL    STORE                   ; Enter the new value
        JMP     CRLF                    ; CR/LF and terminate

; Console input of single character

        IF      SYSVER
IN:
        PUSH    DS
        PUSH    SI
        LDS     SI,CS:[CIN]
        MOV     AH,4
        CALL    DEVIOCALL
        POP     SI
        POP     DS
        CMP     AL,3
        JNZ     NOTCNTC
        INT     23H
NOTCNTC:
        CMP     AL,'P'-'@'
        JZ      PRINTON
        CMP     AL,'N'-'@'
        JZ      PRINTOFF
        CALL    OUT
        RET

PRINTOFF:
PRINTON:
        NOT     [PFLAG]
        JMP     SHORT IN

        ELSE

IN:
        MOV     AH,1
        INT     21H
        RET
        ENDIF

CODE    ENDS
        END     DEBCOM1
                                                                                            