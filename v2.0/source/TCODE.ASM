TITLE   PART1 - COMMAND Transient routines.

        INCLUDE COMSW.ASM

.xlist
.xcref
        INCLUDE DOSSYM.ASM
        INCLUDE DEVSYM.ASM
        INCLUDE COMSEG.ASM
.list
.cref

        INCLUDE COMEQU.ASM


DATARES SEGMENT PUBLIC
        EXTRN   BATCH:WORD,BATLOC:DWORD,PARMBUF:BYTE
        EXTRN   RESTDIR:BYTE,EXTCOM:BYTE,ECHOFLAG:BYTE
        EXTRN   SINGLECOM:WORD,VERVAL:WORD,FORFLAG:BYTE
        EXTRN   RE_INSTR:BYTE,RE_OUT_APP:BYTE,PIPE1:BYTE,PIPE2:BYTE
        EXTRN   RE_OUTSTR:BYTE,PIPEFLAG:BYTE,PIPEFILES:BYTE,PIPEPTR:WORD
        EXTRN   INPIPEPTR:WORD,OUTPIPEPTR:WORD,EXEC_BLOCK:BYTE,ENVIRSEG:WORD
DATARES ENDS

TRANDATA        SEGMENT PUBLIC
        EXTRN   BADBAT:BYTE,NEEDBAT:BYTE,BADNAM:BYTE
        EXTRN   SYNTMES:BYTE,BADDRV:BYTE,BYTMES_POST:BYTE
        EXTRN   DIRMES_PRE:BYTE,DIRMES_POST:BYTE,BYTMES_PRE:BYTE
        EXTRN   NOTFND:BYTE,PIPEEMES:BYTE,BADPMES:BYTE,COMTAB:BYTE
TRANDATA        ENDS

TRANSPACE       SEGMENT PUBLIC
        EXTRN   UCOMBUF:BYTE,COMBUF:BYTE,USERDIR1:BYTE,EXECPATH:BYTE
        EXTRN   DIRCHAR:BYTE,EXEC_ADDR:DWORD,RCH_ADDR:DWORD,CHKDRV:BYTE
        EXTRN   CURDRV:BYTE,PARM1:BYTE,PARM2:BYTE,COMSW:WORD,ARG1S:WORD
        EXTRN   ARG2S:WORD,ARGTS:WORD,SPECDRV:BYTE,BYTCNT:WORD,IDLEN:BYTE
        EXTRN   DIRBUF:BYTE,ID:BYTE,COM:BYTE,LINCNT:BYTE,INTERNATVARS:BYTE
        EXTRN   HEADCALL:DWORD,RESSEG:WORD,TPA:WORD,SWITCHAR:BYTE
        EXTRN   STACK:WORD,FILTYP:BYTE,FILECNT:WORD,LINLEN:BYTE


        IF      KANJI
        EXTRN   KPARSE:BYTE
        ENDIF
TRANSPACE       ENDS

; ********************************************************************
; START OF TRANSIENT PORTION
; This code is loaded at the end of memory and may be overwritten by
; memory-intensive user programs.

TRANCODE        SEGMENT PUBLIC PARA
ASSUME  CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING


        EXTRN   SCANOFF:NEAR,DELIM:NEAR,SAVUDIR:NEAR,SAVUDIR1:NEAR
        EXTRN   PATHCHRCMP:NEAR,PRINT:NEAR,RESTUDIR:NEAR
        EXTRN   CRLF2:NEAR,PRINT_PROMPT:NEAR,GETBATBYT:NEAR,PRESCAN:NEAR
        EXTRN   CRPRINT:NEAR,DISP32BITS:NEAR,FCB_TO_ASCZ:NEAR
        EXTRN   ERROR_PRINT:NEAR,FREE_TPA:NEAR,ALLOC_TPA:NEAR
        EXTRN   $EXIT:NEAR,FORPROC:NEAR,FIND_NAME_IN_ENVIRONMENT:NEAR
        EXTRN   UPCONV:NEAR,BATOPEN:NEAR,BATCLOSE:NEAR,IOSET:NEAR,FIND_PATH:NEAR
        EXTRN   TESTDOREIN:NEAR,TESTDOREOUT:NEAR

        PUBLIC  SWLIST,CERROR,SETREST1,DOCOM,DOCOM1,DRVBAD,NOTFNDERR
        PUBLIC  COMMAND,TCOMMAND,SWITCH,PIPEERRSYN,GETKEYSTROKE,SETREST
        PUBLIC  CHKCNT


        IF      KANJI
        EXTRN   TESTKANJ:NEAR
        ENDIF

        ORG     0
ZERO    =       $

        ORG     100H                    ; Allow for 100H parameter area

SETDRV:
        MOV     AH,SET_DEFAULT_DRIVE
        INT     int_command
TCOMMAND:
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        MOV     AX,-1
        XCHG    AX,[VERVAL]
        CMP     AX,-1
        JZ      NOSETVER2
        MOV     AH,SET_VERIFY_ON_WRITE  ; AL has correct value
        INT     int_command
NOSETVER2:
        CALL    [HEADCALL]              ; Make sure header fixed
        XOR     BP,BP                   ; Flag transient not read
        CMP     [SINGLECOM],-1
        JNZ     COMMAND
$EXITPREP:
        PUSH    CS
        POP     DS
        JMP     $EXIT                   ; Have finished the single command
ASSUME  DS:NOTHING
COMMAND:
        CLD
        MOV     AX,CS
        MOV     SS,AX
ASSUME  SS:TRANGROUP
        MOV     SP,OFFSET TRANGROUP:STACK
        MOV     ES,AX
ASSUME  ES:TRANGROUP
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        STI

        MOV     [UCOMBUF],COMBUFLEN     ; Init UCOMBUF
        MOV     [COMBUF],COMBUFLEN      ; Init COMBUF (Autoexec doing DATE)
        OR      BP,BP                   ; See if just read
        JZ      TESTRDIR                ; Not read, check user directory
        MOV     WORD PTR [UCOMBUF+1],0D01H  ; Reset buffer
        JMP     SHORT NOSETBUF
TESTRDIR:
        CMP     [RESTDIR],0
        JZ      NOSETBUF                ; User directory OK
        PUSH    DS
        PUSH    CS
        POP     DS
ASSUME  DS:TRANGROUP
        MOV     DX,OFFSET TRANGROUP:USERDIR1
        MOV     AH,CHDIR
        INT     int_command             ; Restore users directory
        POP     DS
ASSUME  DS:RESGROUP
NOSETBUF:
        CMP     [PIPEFILES],0
        JZ      NOPCLOSE                ; Don't bother if they don't exist
        CMP     [PIPEFLAG],0
        JNZ     NOPCLOSE                ; Don't del if still piping
        CALL    PIPEDEL
NOPCLOSE:
        MOV     [EXTCOM],0              ; Flag internal command
        MOV     [RESTDIR],0             ; Flag users dirs OK
        MOV     AX,CS                   ; Get segment we're in
        MOV     DS,AX
ASSUME  DS:TRANGROUP
        PUSH    AX
        MOV     DX,OFFSET TRANGROUP:INTERNATVARS
        MOV     AX,INTERNATIONAL SHL 8
        INT     21H
        POP     AX
        SUB     AX,[TPA]                ; AX=size of TPA in paragraphs
        MOV     DX,16
        MUL     DX                      ; DX:AX=size of TPA in bytes
        OR      DX,DX                   ; See if over 64K
        JZ      SAVSIZ                  ; OK if not
        MOV     AX,-1                   ; If so, limit to 65535 bytes
SAVSIZ:
        MOV     [BYTCNT],AX             ; Max no. of bytes that can be buffered
        MOV     DS,[RESSEG]             ; All batch work must use resident seg.
ASSUME  DS:RESGROUP
        TEST    [ECHOFLAG],-1
        JZ      GETCOM                  ; Don't do the CRLF
        CALL    SINGLETEST
        JB      GETCOM
        CALL    CRLF2
GETCOM:
        MOV     AH,GET_DEFAULT_DRIVE
        INT     int_command
        MOV     [CURDRV],AL
        TEST    [ECHOFLAG],-1
        JZ      NOPDRV                  ; No prompt if echo off
        CALL    SINGLETEST
        JB      NOPDRV
        CALL    PRINT_PROMPT            ; Prompt the user
NOPDRV:
        TEST    [PIPEFLAG],-1           ; Pipe has highest presedence
        JZ      NOPIPE
        JMP     PIPEPROC                ; Continue the pipeline
NOPIPE:
        TEST    [FORFLAG],-1            ; FOR has next highest precedence
        JZ      TESTFORBAT
        JMP     FORPROC                 ; Continue the FOR
TESTFORBAT:
        MOV     [RE_INSTR],0            ; Turn redirection back off
        MOV     [RE_OUTSTR],0
        MOV     [RE_OUT_APP],0
        TEST    [BATCH],-1              ; Batch has lowest precedence
        JZ      ISNOBAT
        JMP     READBAT                 ; Continue BATCH

ISNOBAT:
        CMP     [SINGLECOM],0
        JZ      REGCOM
        MOV     SI,-1
        XCHG    SI,[SINGLECOM]
        MOV     DI,OFFSET TRANGROUP:COMBUF + 2
        XOR     CX,CX
SINGLELOOP:
        LODSB
        STOSB
        INC     CX
        CMP     AL,0DH
        JNZ     SINGLELOOP
        DEC     CX
        PUSH    CS
        POP     DS
ASSUME  DS:TRANGROUP
        MOV     [COMBUF + 1],CL
        JMP     DOCOM

REGCOM:
        PUSH    CS
        POP     DS                      ; Need local segment to point to buffer
        MOV     DX,OFFSET TRANGROUP:UCOMBUF
        MOV     AH,STD_CON_STRING_INPUT
        INT     int_command             ; Get a command
        MOV     CL,[UCOMBUF]
        XOR     CH,CH
        ADD     CX,3
        MOV     SI,OFFSET TRANGROUP:UCOMBUF
        MOV     DI,OFFSET TRANGROUP:COMBUF
        REP     MOVSB                   ; Transfer it to the cooked buffer
        JMP     DOCOM

; All batch proccessing has DS set to segment of resident portion
ASSUME  DS:RESGROUP,ES:TRANGROUP

NEEDENV:
        PUSH    DS
        PUSH    SI
        PUSH    DI

        MOV     DI,OFFSET TRANGROUP:ID
        ADD     AL,"0"
        STOSB
GETENV1:
        CALL    GETBATBYT
        STOSB
        CMP     AL,13
        JZ      GETENV2
        CMP     AL,"%"
        JNZ     GETENV1
        MOV     BYTE PTR ES:[DI-1],"="
GETENV2:
        MOV     SI,OFFSET TRANGROUP:ID
        PUSH    CS
        POP     DS                      ; DS:SI POINTS TO NAME
ASSUME DS:TRANGROUP,ES:RESGROUP
        CALL    FIND_NAME_IN_environment
        PUSH    ES
        POP     DS
        PUSH    CS
        POP     ES
ASSUME DS:RESGROUP,ES:TRANGROUP
        MOV     SI,DI
        POP     DI                      ; get back pointer to command line
        JNC     GETENV4

GETENV3:                                ; Parameter not found
        PUSH    CS
        POP     DS
        MOV     SI,OFFSET TRANGROUP:ID

GETENV4:
        LODSB                           ; From resident segment
        OR      AL,AL                   ; Check for end of parameter
        JZ      GETENV6
        CMP     AL,13
        JZ      GETENV6
        CMP     AL,"="
        JZ      GETENVX
        STOSB
        JMP     GETENV4

GETENVX:
        MOV     AL,"%"
        STOSB
GETENV6:
        POP     SI
        POP     DS
        CMP     AL,13
        JZ      SAVBATBYTJ
        JMP     RDBAT

NEEDPARM:
        CALL    GETBATBYT
        CMP     AL,"%"                  ; Check for two consecutive %
        JZ      SAVBATBYTJ
        CMP     AL,13                   ; Check for end-of-line
        JNZ     PAROK
SAVBATBYTJ:
        JMP     SAVBATBYT
PAROK:
        SUB     AL,"0"
        JB      NEEDENV                 ; look for parameter in the environment
        CMP     AL,9
        JA      NEEDENV

        CBW
        MOV     SI,AX
        SHL     SI,1                    ; Two bytes per entry
        PUSH    ES
        PUSH    DI
        MOV     ES,[BATCH]
        XOR     CX,CX
        MOV     AX,CX
        MOV     DI,CX
        DEC     CX
        REPNZ   SCASB
        ADD     DI,SI
        MOV     SI,ES:[DI]
        POP     DI
        POP     ES
        CMP     SI,-1                   ; Check if parameter exists
        JZ      RDBAT                   ; Ignore if it doesn't
RDPARM:
        LODSB                           ; From resident segment
        CMP     AL,0DH                  ; Check for end of parameter
        JZ      RDBAT
        STOSB
        JMP     RDPARM

PROMPTBAT:
        MOV     DX,OFFSET TRANGROUP:NEEDBAT
        CALL    [RCH_ADDR]
        JZ      AskForBat               ; Media is removable
NoAskForBat:
        MOV     ES,[BATCH]              ; Turn off batch
        MOV     AH,DEALLOC
        INT     int_command             ; free up the batch piece
        MOV     [BATCH],0               ; AFTER DEALLOC in case of ^C
        MOV     [FORFLAG],0             ; Turn off for processing
        MOV     [PIPEFLAG],0            ; Turn off any pipe
        PUSH    CS
        POP     DS
        MOV     DX,OFFSET TRANGROUP:BADBAT
        CALL    ERROR_PRINT             ; Tell user no batch file
        JMP     TCOMMAND

ASKFORBAT:
        PUSH    CS
        POP     DS
        CALL    ERROR_PRINT             ; Prompt for batch file
        CALL    GetKeystroke
        JMP     TCOMMAND
;**************************************************************************
; read the next keystroke

GetKeystroke:
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8) OR STD_CON_INPUT_no_echo
        INT     int_command             ; Get character with KB buffer flush
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8) + 0
        INT     int_command
        return

READBAT:
        CALL    BATOPEN
        JC      PROMPTBAT
        MOV     DI,OFFSET TRANGROUP:COMBUF+2
TESTNOP:
        CALL    GETBATBYT
        CMP     AL,':'                  ; Label/Comment?
        JNZ     NOTLABEL
NOPLINE:                                ; Consume the line
        CALL    GETBATBYT
        CMP     AL,0DH
        JNZ     NOPLINE
        CALL    GETBATBYT               ; Eat Linefeed
        TEST    [BATCH],-1
        JNZ     TESTNOP
        JMP     TCOMMAND                ; Hit EOF

RDBAT:
        CALL    GETBATBYT
NOTLABEL:
        CMP     AL,"%"                  ; Check for parameter
        JNZ     SAVBATBYT
        JMP     NEEDPARM
SAVBATBYT:
        STOSB
        CMP     AL,0DH
        JNZ     RDBAT
        SUB     DI,OFFSET TRANGROUP:COMBUF+3
        MOV     AX,DI
        MOV     ES:[COMBUF+1],AL        ; Set length of line
        CALL    GETBATBYT               ; Eat linefeed
        CALL    BATCLOSE
        TEST    [ECHOFLAG],-1
        PUSH    CS
        POP     DS                      ; Go back to local segment
        JZ      NOECHO2
ASSUME DS:TRANGROUP
        MOV     DX,OFFSET TRANGROUP:COMBUF+2
        CALL    CRPRINT
DOCOM:
; All segments are local for command line processing
        CALL    CRLF2
DOCOM1:

NOECHO2:
        CALL    PRESCAN                 ; Cook the input buffer
        JZ      NOPIPEPROC
        JMP     PIPEPROCSTRT            ; Fire up the pipe
NOPIPEPROC:
        MOV     SI,OFFSET TRANGROUP:COMBUF+2
        MOV     DI,OFFSET TRANGROUP:IDLEN
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H ; Make FCB with blank scan-off
        INT     int_command
        CMP     AL,1                    ; Check for ambiguous command name
        JZ      BADCOMJ1                ; Ambiguous commands not allowed
        CMP     AL,-1
        JNZ     DRVGD
        JMP     DRVBAD

BADCOMJ1:
        JMP    BADCOM

DRVGD:
        MOV     AL,[DI]
        MOV     [SPECDRV],AL
        MOV     AL," "
        MOV     CX,9
        INC     DI
        REPNE   SCASB                   ; Count no. of letters in command name
        MOV     AL,9
        SUB     AL,CL
        MOV     [IDLEN],AL
        MOV     DI,81H
        XOR     CX,CX
        PUSH    SI
COMTAIL:
        LODSB
        STOSB                           ; Move command tail to 80H
        CMP     AL,13
        LOOPNZ  COMTAIL
        NOT     CL
        MOV     BYTE PTR DS:[80H],CL
        POP     SI
; If the command has 0 parameters must check here for
; any switches that might be present.
; SI -> first character after the command.
        CALL    SWITCH          ; Is the next character a SWITCHAR
        MOV     [COMSW],AX
        MOV     DI,FCB
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
        INT     int_command
        MOV     [PARM1],AL      ; Save result of parse

PRBEG:
        LODSB
        CMP     AL,[SWITCHAR]
        JZ      PRFIN
        CMP     AL,13
        JZ      PRFIN
        CALL    DELIM
        JNZ     PRBEG
PRFIN:
        DEC     SI
        CALL    SWITCH
        MOV     [ARG1S],AX
        MOV     DI,FCB+10H
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
        INT     int_command             ; Parse file name
        MOV     [PARM2],AL      ; Save result
        CALL    SWITCH
        MOV     [ARG2S],AX
        OR      AX,[ARG1S]
        MOV     [ARGTS],AX
SWTLP:                          ; Find any remaining switches
        CMP     BYTE PTR [SI],0DH
        JZ      GOTALLSW
        INC     SI
        CALL    SWITCH
        OR      [ARGTS],AX
        JMP     SHORT SWTLP

GOTALLSW:
        MOV     AL,[IDLEN]
        MOV     DL,[SPECDRV]
        OR      DL,DL           ; Check if drive was specified
        JZ      OK
        JMP     DRVCHK
OK:
        DEC     AL              ; Check for null command
        JNZ     FNDCOM
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        CMP     [SINGLECOM],-1
        JZ      EXITJ
        JMP     GETCOM

EXITJ:
        JMP     $EXITPREP
ASSUME  DS:TRANGROUP

RETSW:
        XCHG    AX,BX           ; Put switches in AX
        return

SWITCH:
        XOR     BX,BX           ; Initialize - no switches set
SWLOOP:
        CALL    SCANOFF         ; Skip any delimiters
        CMP     AL,[SWITCHAR]   ; Is it a switch specifier?
        JNZ     RETSW           ; No -- we're finished
        OR      BX,GOTSWITCH    ; Indicate there is a switch specified
        INC     SI              ; Skip over the switch character
        CALL    SCANOFF
        CMP     AL,0DH
        JZ      RETSW           ; Oops
        INC     SI
; Convert lower case input to upper case
        CALL    UPCONV
        MOV     DI,OFFSET TRANGROUP:SWLIST
        MOV     CX,SWCOUNT
        REPNE   SCASB                   ; Look for matching switch
        JNZ     BADSW
        MOV     AX,1
        SHL     AX,CL           ; Set a bit for the switch
        OR      BX,AX
        JMP     SHORT SWLOOP

BADSW:
        JMP     SHORT SWLOOP

SWLIST  DB      "VBAPW"
SWCOUNT EQU     $-SWLIST

DRVBAD:
        MOV     DX,OFFSET TRANGROUP:BADDRV
        JMP     CERROR

FNDCOM:
        MOV     SI,OFFSET TRANGROUP:COMTAB      ; Prepare to search command table
        MOV     CH,0
FINDCOM:
        MOV     DI,OFFSET TRANGROUP:IDLEN
        MOV     CL,[SI]
        JCXZ    EXTERNAL
        REPE    CMPSB
        LAHF
        ADD     SI,CX           ; Bump to next position without affecting flags
        SAHF
        LODSB           ; Get flag for drive check
        MOV     [CHKDRV],AL
        LODSW           ; Get address of command
        JNZ     FINDCOM
        MOV     DX,AX
        CMP     [CHKDRV],0
        JZ      NOCHECK
        MOV     AL,[PARM1]
        OR      AL,[PARM2]      ; Check if either parm. had invalid drive
        CMP     AL,-1
        JZ      DRVBAD
NOCHECK:
        CALL    IOSET
        CALL    DX              ; Call the internal
COMJMP:
        JMP     TCOMMAND

SETDRV1:
        JMP     SETDRV

DRVCHK:
        DEC     DL              ; Adjust for correct drive number
        DEC     AL              ; Check if anything else is on line
        JZ      SETDRV1
EXTERNAL:
        MOV     [FILTYP],0
        MOV     DL,[SPECDRV]
        MOV     [IDLEN],DL
        CALL    SAVUDIR                 ; Drive letter already checked
        MOV     AL,'?'
        MOV     DI,OFFSET TRANGROUP:COM
        STOSB                           ; Look for any extension
        STOSB
        STOSB
        MOV     DX,OFFSET TRANGROUP:DIRBUF      ; Command will end up here
        MOV     AH,SET_DMA
        INT     int_command
        PUSH    ES
        CALL    FIND_PATH
        MOV     SI,DI
        POP     ES

        MOV     DI,OFFSET TRANGROUP:EXECPATH
        MOV     BYTE PTR [DI],0         ; Initialize to current directory
RESEARCH:
        MOV     AH,DIR_SEARCH_FIRST
COMSRCH:
        PUSH    CS
        POP     DS
        MOV     DX,OFFSET TRANGROUP:IDLEN
        INT     int_command
        OR      AL,AL
        MOV     AH,DIR_SEARCH_NEXT      ; Do search-next next
        JNZ     PATHCHK
        CMP     WORD PTR [DIRBUF+9],4F00H + "C"
        JNZ     CHKEXE
        CMP     [DIRBUF+11],"M"
        JNZ     CHKEXE
        OR      [FILTYP],4
        JMP     EXECUTE                 ; If we find a COM were done

CHKEXE:
        CMP     WORD PTR [DIRBUF+9],5800H + "E"
        JNZ     CHKBAT
        CMP     [DIRBUF+11],"E"
        JNZ     CHKBAT
        OR      [FILTYP],1              ; Flag an EXE found
        JMP     COMSRCH                 ; Continue search

CHKBAT:
        CMP     WORD PTR [DIRBUF+9],4100H + "B"
        JNZ     COMSRCH
        CMP     [DIRBUF+11],"T"
        JNZ     COMSRCH
        OR      [FILTYP],2              ; Flag BAT found
        JMP     COMSRCH                 ; Continue search

PATHCHK:
        TEST    [FILTYP],1
        JZ      TESTBAT
        MOV     WORD PTR [DIRBUF+9],5800H+"E"
        MOV     [DIRBUF+11],"E"
        JMP     EXECUTE                 ; Found EXE

TESTBAT:
        TEST    [FILTYP],2
        JZ      NEXTPATH                ; Found nothing, try next path
        MOV     WORD PTR [DIRBUF+9],4100H+"B"
        MOV     [DIRBUF+11],"T"
        MOV     DX,OFFSET TRANGROUP:DIRBUF      ; Found BAT
        MOV     AH,FCB_OPEN
        INT     int_command
        OR      AL,AL
        JZ      BATCOMJ         ; Bat exists
        CALL    RESTUDIR
        JMP     BADCOM

BATCOMJ:
        JMP    BATCOM

NEXTPATH:
        MOV     DX,OFFSET TRANGROUP:USERDIR1    ; Restore users dir
        MOV     AH,CHDIR
        INT     int_command
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        MOV     [RESTDIR],0
BADPATHEL:
        MOV     DI,OFFSET TRANGROUP:EXECPATH    ; Build a full path here
        MOV     DX,SI
        MOV     DS,[ENVIRSEG]   ; Point into environment
ASSUME  DS:NOTHING
        LODSB

        IF      KANJI
        MOV     [KPARSE],0
        ENDIF

        OR      AL,AL
        JZ      BADCOMJ                 ; NUL, command not found
        XOR     BL,BL                   ; Make BL a NUL
PSKIPLP:                                ; Get the path
        STOSB
        OR      AL,AL
        JZ      LASTPATH
        CMP     AL,';'
        JZ      GOTNEXTPATH
        CMP     DI,15+DirStrLen+(OFFSET TRANGROUP:EXECPATH)
        JB      OKPath
SKIPPathElem:
        LODSB                           ; scan to end of path element
        OR      AL,AL
        JZ      BadPathEl
        CMP     AL,';'
        JZ      BadPathEl
        JMP     SkipPathElem

OKPath:
        IF      KANJI
        MOV     [KPARSE],0
        CALL    TESTKANJ
        JZ      NXTPTCHR
        INC     [KPARSE]
        MOVSB
NXTPTCHR:
        ENDIF

        LODSB
        JMP     SHORT PSKIPLP

BADCOMJ:
        JMP     BADCOM

LASTPATH:
        MOV     BYTE PTR ES:[DI-1],';'  ; Fix up the NUL in EXECPATH
        DEC     SI                      ; Point to the NUL in PATHSTRING
        MOV     BL,[SI-1]               ; Change substi char to char before NUL

GOTNEXTPATH:
        DEC     DI              ; Point to the end of the dir
        PUSH    BX
        PUSH    SI
        PUSH    DX
        MOV     SI,DX
        XOR     DL,DL
        CMP     BYTE PTR [SI+1],DRVCHAR
        JNZ     DEFDRVPATH      ; No drive spec
        MOV     DL,[SI]
        SUB     DL,'@'
DEFDRVPATH:
        PUSH    DS
        PUSH    CS
        POP     DS
ASSUME  DS:TRANGROUP
        MOV     [IDLEN],DL      ; New drive
        PUSH    DI
        CALL    SAVUDIR         ; Save the users dir
        POP     DI
        JNC     PATHTRY
        MOV     DX,OFFSET TRANGROUP:BADPMES ; Tell the user bad stuff in path
        CALL    PRINT
PATHTRY:
        POP     DS
ASSUME  DS:NOTHING
        POP     DX
        POP     SI
        POP     BX
        XCHG    BL,[SI-1]       ; Stick in NUL, or same thing if LASTPATH
CDPATH:
        MOV     AH,CHDIR
        INT     int_command
        MOV     [SI-1],BL       ; Fix the path string back up
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        INC     [RESTDIR]       ; Say users dir needs restoring
        JNC     ResearchJ
        JMP     BADPATHEL       ; Ignore a directory which doesn't exist
ResearchJ:
        JMP     RESEARCH        ; Try looking in this one

BATCOM:
ASSUME  DS:TRANGROUP
; Batch parameters are read with ES set to segment of resident part
        CALL    IOSET           ; Set up any redirection
        MOV     ES,[RESSEG]
ASSUME  ES:RESGROUP
;Since BATCH has lower precedence than PIPE or FOR. If a new BATCH file
;is being started it MUST be true that no FOR or PIPE is currently in
;progress.
        MOV     [FORFLAG],0     ; Turn off for processing
        MOV     [PIPEFLAG],0    ; Turn off any pipe
        TEST    [BATCH],-1
        JNZ     CHAINBAT        ; Don't need allocation if chaining
        CALL    FREE_TPA
ASSUME  ES:RESGROUP
        MOV     BX,6            ; 64 + 32 bytes
        MOV     AH,ALLOC
        INT     int_command             ; Suck up a little piece for batch processing
        MOV     [BATCH],AX
        CALL    ALLOC_TPA
CHAINBAT:
        PUSH    ES
        MOV     ES,[BATCH]
ASSUME  ES:NOTHING
        MOV     DL,[DIRBUF]
        XOR     DI,DI
        CALL    SAVUDIR1        ; ES:DI set up, get dir containing Batch file
        XOR     AX,AX
        MOV     CX,AX
        DEC     CX
        REPNZ   SCASB           ; Find the NUL
        DEC     DI              ; Point at the NUL
        MOV     AL,[DIRCHAR]
        CMP     AL,ES:[DI-1]
        JZ      NOPUTSLASH
        STOSB
NOPUTSLASH:
        MOV     SI,OFFSET TRANGROUP:DIRBUF+1
        CALL    FCB_TO_ASCZ     ; Tack on batch file name
        MOV     AX,-1
        MOV     BX,DI
        MOV     CX,10
        REP     STOSW           ; Init Parmtab to no parms
        POP     ES
ASSUME  ES:RESGROUP
        CALL    RESTUDIR
        MOV     SI,OFFSET TRANGROUP:COMBUF+2
        MOV     DI,OFFSET RESGROUP:PARMBUF
        MOV     CX,10
EACHPARM:
        CALL    SCANOFF
        CMP     AL,0DH
        JZ      HAVPARM
        JCXZ    MOVPARM                 ; Only first 10 parms get pointers
        PUSH    ES
        MOV     ES,[BATCH]
        MOV     ES:[BX],DI              ; Set pointer table to point to actual parameter
        POP     ES
        INC     BX
        INC     BX
MOVPARM:
        LODSB
        CALL    DELIM
        JZ      ENDPARM         ; Check for end of parameter
        STOSB
        CMP     AL,0DH
        JZ      HAVPARM
        JMP     SHORT MOVPARM
ENDPARM:
        MOV     AL,0DH
        STOSB           ; End-of-parameter marker
        JCXZ    EACHPARM
        DEC     CX
        JMP     SHORT EACHPARM
HAVPARM:
        XOR     AL,AL
        STOSB                   ; Nul terminate the parms
        XOR     AX,AX
        PUSH    ES
        POP     DS                      ; Simply batch FCB setup
ASSUME  DS:RESGROUP
        MOV     WORD PTR [BATLOC],AX    ; Start at beginning of file
        MOV     WORD PTR [BATLOC+2],AX
        CMP     [SINGLECOM],-1
        JNZ     NOBATSING
        MOV     [SINGLECOM],0FFF0H      ; Flag single command BATCH job
NOBATSING:
        JMP     TCOMMAND
ASSUME  DS:TRANGROUP,ES:TRANGROUP

EXECUTE:
        CALL    RESTUDIR
NeoExecute:
        CMP     BYTE PTR [DI],0         ; Command in current directory
        JZ      NNSLSH
        MOV     AL,[DI-1]

        IF      KANJI
        CMP     [KPARSE],0
        JNZ     StuffPath               ; Last char is second KANJI byte, might be '\'
        ENDIF

        CALL    PATHCHRCMP
        JZ      HAVEXP                  ; Don't double slash
StuffPath:
        MOV     AL,[DIRCHAR]
        STOSB
        JMP     SHORT HAVEXP

NNSLSH:
        MOV     AL,[DIRBUF]             ; Specify a drive
        ADD     AL,'@'
        STOSB
        MOV     AL,DRVCHAR
        STOSB
HAVEXP:
        MOV     SI,OFFSET TRANGROUP:DIRBUF+1
        CALL    FCB_TO_ASCZ             ; Tack on the filename
        CALL    IOSET
        MOV     ES,[TPA]
        MOV     AH,DEALLOC
        INT     int_command                             ; Now running in "free" space
        MOV     ES,[RESSEG]
ASSUME  ES:RESGROUP
        INC     [EXTCOM]        ; Indicate external command
        MOV     [RESTDIR],0     ; Since USERDIR1 is in transient, insure
                                ;  this flag value for re-entry to COMMAND
        MOV     DI,FCB
        MOV     SI,DI
        MOV     CX,052H
        REP     MOVSW           ; Transfer parameters to resident header
        MOV     DX,OFFSET TRANGROUP:EXECPATH
        MOV     BX,OFFSET RESGROUP:EXEC_BLOCK
        MOV     AX,EXEC SHL 8
        JMP     [EXEC_ADDR]     ; Jmp to the EXEC in the resident

BADCOM:
        PUSH    CS
        POP     DS
        MOV     DX,OFFSET TRANGROUP:BADNAM
CERROR:
        CALL    ERROR_PRINT
        JMP     TCOMMAND

SINGLETEST:
ASSUME  DS:RESGROUP
        CMP     [SINGLECOM],0
        JZ      RET5
        CMP     [SINGLECOM],0EFFFH
        return


ASSUME  DS:TRANGROUP
SETREST1:
        MOV     AL,1
SETREST:
        PUSH    DS
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        MOV     [RESTDIR],AL
        POP     DS
ASSUME  DS:TRANGROUP
RET5:
        return

CHKCNT:
        TEST    [FILECNT],-1
        JNZ     ENDDIR
NOTFNDERR:
        MOV     DX,OFFSET TRANGROUP:NOTFND
        JMP     CERROR

ENDDIR:
; Make sure last line ends with CR/LF
        MOV     AL,[LINLEN]
        CMP     AL,[LINCNT]     ; Will be equal if just had CR/LF
        JZ      MESSAGE
        CALL    CRLF2
MESSAGE:
        MOV     DX,OFFSET TRANGROUP:DIRMES_PRE
        CALL    PRINT
        MOV     SI,[FILECNT]
        XOR     DI,DI
        CALL    DISP32BITS
        MOV     DX,OFFSET TRANGROUP:DIRMES_POST
        CALL    PRINT
        MOV     AH,GET_DRIVE_FREESPACE
        MOV     DL,BYTE PTR DS:[FCB]
        INT     int_command
        CMP     AX,-1
        retz
        MOV     DX,OFFSET TRANGROUP:BYTMES_PRE
        CALL    PRINT
        MUL     CX              ; AX is bytes per cluster
        MUL     BX
        MOV     DI,DX
        MOV     SI,AX
        CALL    DISP32BITS
        MOV     DX,OFFSET TRANGROUP:BYTMES_POST
        JMP     PRINT

ASSUME  DS:RESGROUP

PIPEDEL:
        PUSH    DX
        MOV     DX,OFFSET RESGROUP:PIPE1        ; Clean up in case ^C
        MOV     AH,UNLINK
        INT     int_command
        MOV     DX,OFFSET RESGROUP:PIPE2
        MOV     AH,UNLINK
        INT     int_command
        XOR     AX,AX
        MOV     WORD PTR [PIPEFLAG],AX    ; Pipe files and pipe gone
        MOV     [ECHOFLAG],1    ; Make sure ^C to pipe doesn't leave ECHO OFF
        POP     DX
        return

PIPEERRSYN:
        MOV     DX,OFFSET TRANGROUP:SYNTMES
        JMP     SHORT PIPPERR
PIPEERR:
        MOV     DX,OFFSET TRANGROUP:PIPEEMES
PIPPERR:
        CALL    PIPEDEL
        PUSH    CS
        POP     DS
        JMP     CERROR

PIPEPROCSTRT:
ASSUME  DS:TRANGROUP,ES:TRANGROUP
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        INC     [PIPEFILES]             ; Flag that the pipe files exist
        MOV     AH,19H                  ; Get current drive
        INT     int_command
        ADD     AL,'A'
        MOV     [PIPE2],AL              ; Make pipe files in root of def drv
        MOV     BX,OFFSET RESGROUP:PIPE1
        MOV     [BX],AL
        MOV     DX,BX
        XOR     CX,CX
        MOV     AH,CREAT
        INT     int_command
        JC      PIPEERR                 ; Couldn't create
        MOV     BX,AX
        MOV     AH,CLOSE                ; Don't proliferate handles
        INT     int_command
        MOV     DX,OFFSET RESGROUP:PIPE2
        MOV     AH,CREAT
        INT     int_command
        JC      PIPEERR
        MOV     BX,AX
        MOV     AH,CLOSE
        INT     int_command
        CALL    TESTDOREIN      ; Set up a redirection if specified
        MOV     [ECHOFLAG],0    ; No echo on pipes
        MOV     SI,[PIPEPTR]
        CMP     [SINGLECOM],-1
        JNZ     NOSINGP
        MOV     [SINGLECOM],0F000H      ; Flag single command pipe
NOSINGP:
        JMP     SHORT FIRSTPIPE

PIPEPROC:
ASSUME  DS:RESGROUP
        MOV     [ECHOFLAG],0    ; No echo on pipes
        MOV     SI,[PIPEPTR]
        LODSB
        CMP     AL,'|'
        JNZ     PIPEEND         ; Pipe done
        MOV     DX,[INPIPEPTR]  ; Get the input file name
        MOV     AX,(OPEN SHL 8)
        INT     int_command
PIPEERRJ:
        JC    PIPEERR         ; Lost the pipe file
        MOV     BX,AX
        MOV     AL,0FFH
        XCHG    AL,[BX.PDB_JFN_Table]
        MOV     DS:[PDB_JFN_Table],AL   ; Redirect
FIRSTPIPE:
        MOV     DI,OFFSET TRANGROUP:COMBUF + 2
        XOR     CX,CX
        CMP     BYTE PTR [SI],0DH       ; '|<CR>'
        JNZ     PIPEOK1
PIPEERRSYNJ:
        JMP     PIPEERRSYN
PIPEOK1:
        CMP     BYTE PTR [SI],'|'       ; '||'
        JZ      PIPEERRSYNJ
PIPECOMLP:
        LODSB
        STOSB

        IF      KANJI
        CALL    TESTKANJ
        JZ      NOTKANJ5
        MOVSB
        JMP     PIPECOMLP

NOTKANJ5:
        ENDIF

        CMP     AL,0DH
        JZ      LASTPIPE
        INC     CX
        CMP     AL,'|'
        JNZ     PIPECOMLP
        MOV     BYTE PTR ES:[DI-1],0DH
        DEC     CX
        MOV     [COMBUF+1],CL
        DEC     SI
        MOV     [PIPEPTR],SI            ; On to next pipe element
        MOV     DX,[OUTPIPEPTR]
        PUSH    CX
        XOR     CX,CX
        MOV     AX,(CREAT SHL 8)
        INT     int_command
        POP     CX
        JC      PIPEERRJ                ; Lost the file
        MOV     BX,AX
        MOV     AL,0FFH
        XCHG    AL,[BX.PDB_JFN_Table]
        MOV     DS:[PDB_JFN_Table+1],AL
        XCHG    DX,[INPIPEPTR]          ; Swap for next element of pipe
        MOV     [OUTPIPEPTR],DX
        JMP     SHORT PIPECOM

LASTPIPE:
        MOV     [COMBUF+1],CL
        DEC     SI
        MOV     [PIPEPTR],SI    ; Point at the CR (anything not '|' will do)
        CALL    TESTDOREOUT     ; Set up the redirection if specified
PIPECOM:
        PUSH    CS
        POP     DS
        JMP     NOPIPEPROC      ; Process the pipe element

PIPEEND:
        CALL    PIPEDEL
        CMP     [SINGLECOM],0F000H
        JNZ     NOSINGP2
        MOV     [SINGLECOM],-1          ; Make it return
NOSINGP2:
        JMP     TCOMMAND

TRANCODE    ENDS
            END
                                                                                        