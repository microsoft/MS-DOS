TITLE   PART4 - COMMAND Transient routines.

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
        EXTRN   RESTDIR:BYTE
DATARES ENDS

TRANDATA        SEGMENT PUBLIC
        EXTRN   BADDRV:BYTE,BADSWT:BYTE
        EXTRN   BADDAT:BYTE,NEWDAT:BYTE,BADTIM:BYTE
        EXTRN   DMES:BYTE,CURDAT_PRE:BYTE,CURDAT_MID:BYTE,CURDAT_POST:BYTE
        EXTRN   RENERR:BYTE,VERMES_PRE:BYTE,VERMES_POST:BYTE
        EXTRN   DIRHEAD_PRE:BYTE,DIRHEAD_POST:BYTE
        EXTRN   ACRLF:BYTE,BADARGS:BYTE,NOTFND:BYTE
        EXTRN   NEWTIM:BYTE,BADCD:BYTE,BADMKD:BYTE,CLSSTRING:BYTE
        EXTRN   CURTIM_PRE:BYTE,CURTIM_POST:BYTE,PauseMes:BYTE
        EXTRN   BADRMD:BYTE
TRANDATA        ENDS

TRANSPACE       SEGMENT PUBLIC
        EXTRN   COMBUF:BYTE,DIRCHAR:BYTE,USERDIR1:BYTE
        EXTRN   BYTCNT:WORD,CURDRV:BYTE,COMSW:WORD,ARGTS:WORD
        EXTRN   LINCNT:BYTE,LINLEN:BYTE,FILECNT:WORD,CHARBUF:BYTE
        EXTRN   DIRBUF:BYTE,BITS:WORD,PATHPOS:WORD
        EXTRN   DESTISDIR:BYTE,DESTTAIL:WORD,DESTINFO:BYTE,FULLSCR:WORD
        EXTRN   INTERNATVARS:BYTE,RESSEG:WORD,TPA:WORD
TRANSPACE       ENDS


TRANCODE        SEGMENT PUBLIC BYTE
ASSUME  CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

        EXTRN   NOTEST2:NEAR,PRINTVOL:NEAR,Print_Date:NEAR
        EXTRN   CERROR:NEAR,SWITCH:NEAR,PWD:NEAR,SETREST:NEAR,MESTRAN:NEAR
        EXTRN   NOTFNDERR:NEAR,CHKCNT:NEAR,GETKEYSTROKE:NEAR
        EXTRN   SETPATH:NEAR,PATHCRUNCH:NEAR,PRINT:NEAR,ZPRINT:NEAR
        EXTRN   DISPSIZE:NEAR,OUT:NEAR,OUT2:NEAR,ERROR_PRINT:NEAR
        EXTRN   SCANOFF:NEAR,OUTBYTE:NEAR,GETNUM:NEAR,ERROR_OUTPUT:NEAR


        PUBLIC  PRINT_TIME,CATALOG
        PUBLIC  BADCDERR,PRINT_VERSION,CLS,SAVUDIR,SAVUDIR1
        PUBLIC  TYPEFIL,CRENAME,$RMDIR
        PUBLIC  CTIME,$CHDIR,ONESPC,DATINIT
        PUBLIC  $MKDIR,VERSION,RESTUDIR1
        PUBLIC  RESTUDIR,CRLF2,ERASE
        PUBLIC  volume,date,P_date,PAUSE
 

CATALOG:
        CALL    OKVOLARG
        MOV     AL,"?"                  ; *.* is default file spec.
        MOV     DI,5DH
        MOV     CX,11
        REP     STOSB
        MOV     SI,81H
        CALL    SWITCH
        MOV     DI,FCB
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 0DH          ; Parse with default name and extension
        INT     int_command

; Begin by processing any switches that may have been specified.
; BITS will contain any information about switches that was
; found when the command line was parsed.

SETSWT:
        MOV     AX,[COMSW]              ; Get switches from command
        OR      AX,[ARGTS]              ; OR in switches from all of tail
        MOV     [BITS],AX
        MOV     BYTE PTR[FULLSCR],LINPERPAG
        TEST    AL,1                    ; Look for W switch
        MOV     AL,NORMPERLIN
        JZ      DIR
        MOV     AL,WIDEPERLIN
DIR:
        MOV     [LINLEN],AL             ; Set number of entries per line
        MOV     [LINCNT],AL
        MOV     [FILECNT],0     ; Keep track of how many files found
        MOV     DX,OFFSET TRANGROUP:DIRBUF      ; Set Disk transfer address
        MOV     AH,SET_DMA
        INT     int_command
        CALL    PATHCRUNCH                      ; Get where we're going
        PUSHF
        JNC     NOTEST
        CMP     [DESTISDIR],0           ; No CHDIRs worked
        JZ      NOTEST                  ; see if they should have
        JMP     BADCDERR

NOTEST:
        MOV     SI,FCB
        MOV     DI,OFFSET TRANGROUP:DIRBUF
        MOV     DX,DI
        MOV     CX,12
        REP     MOVSB
        MOV     AH,FCB_OPEN
        INT     int_command
        MOV     DX,OFFSET TRANGROUP:DIRHEAD_PRE ; Print "Directory of"
        PUSH    AX                              ; save return code
        CALL    PRINT
        CALL    PWD                             ; print the path
        MOV     DX,OFFSET TRANGROUP:DIRHEAD_POST
        CALL    PRINT
        POP     AX
        OR      AL,AL
        JNZ     OKDODIR                         ; Go ahead and dir if open fail
        TEST    [DIRBUF+fcb_DEVID],devid_device
        JZ      OKDODIR
        JMP     NOTFNDERR                       ; Can't DIR a device
OKDODIR:
        MOV     AH,DIR_SEARCH_FIRST
        MOV     BYTE PTR DS:[FCB-7],0FFH
        MOV     BYTE PTR DS:[FCB-1],010H
        POPF
        JC      SHOWDIR                         ; Current dir
        JZ      DOFIRST                         ; FCB is *.*
        MOV     AL,"?"
        MOV     DI,5DH
        MOV     CX,11
        REP     STOSB           ; Remake default FCB
        MOV     SI,[DESTTAIL]
        MOV     DI,FCB
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 0EH  ; Parse with default drive, name and extension
        INT     int_command
        MOV     AH,DIR_SEARCH_FIRST
DOFIRST:
        MOV     DX,FCB-7
        INT     int_command
        PUSH    AX
        CALL    RESTUDIR
        POP     AX
        JMP     SHORT DIRSTART

SHOWDIR:
        MOV     DX,FCB-7        ; DX -> Unopened FCB
        INT     int_command             ; Search for a file to match FCB
DIRSTART:
        INC     AL              ; FF = file not found
        JNZ     AGAIN           ; Either an error or we are finished
        JMP     CHKCNT
NEXENTJ:
        JMP    NEXENT
AGAIN:
        INC     [FILECNT]       ; Keep track of how many we find
        MOV     SI,OFFSET TRANGROUP:DIRBUF+8    ; SI -> information returned by sys call
        CALL    SHONAME
        TEST    BYTE PTR[BITS],WSWITCH  ; W switch set?
        JNZ     NEXENTJ         ; If so, no size, date, or time
        MOV     SI,OFFSET TRANGROUP:DIRBUF+8+dir_attr
        TEST    BYTE PTR [SI],attr_directory
        JZ      FILEENT
        MOV     DX,OFFSET TRANGROUP:DMES
        CALL    PRINT
        JMP     SHORT NOFSIZ
FILEENT:
        CALL    DISPSIZE        ; Print size of file
NOFSIZ:
        MOV     AX,WORD PTR [DIRBUF+8+dir_date]  ; Get date
        OR      AX,AX
        JZ      NEXENT          ; Skip if no date
        MOV     DI,OFFSET TRANGROUP:CHARBUF
        PUSH    AX
        MOV     AX,"  "
        STOSW
        POP     AX
        MOV     BX,AX
        AND     AX,1FH          ; get day
        MOV     DL,AL
        MOV     AX,BX
        MOV     CL,5
        SHR     AX,CL           ; Align month
        AND     AL,0FH          ; Get month
        MOV     DH,AL
        MOV     CL,BH
        SHR     CL,1            ; Align year
        XOR     CH,CH
        ADD     CX,80           ; Relative 1980
        CMP     CL,100
        JB      MILLENIUM
        SUB     CL,100
MILLENIUM:
        CALL    DATE_CXDX
        MOV     CX,WORD PTR[DIRBUF+8+dir_time]  ; Get time
        JCXZ    PRBUF           ; Time field present?
        MOV     AX,"  "
        STOSW
        SHR     CX,1
        SHR     CX,1
        SHR     CX,1
        SHR     CL,1
        SHR     CL,1            ; Hours in CH, minutes in CL
        MOV     BL,[INTERNATVARS.Time_24]
        OR      BL,80H          ; Tell P_TIME called from DIR
        CALL    P_TIME          ; Don't care about DX, never used with DIR
PRBUF:
        XOR     AX,AX
        STOSB
        MOV     DX,OFFSET TRANGROUP:CHARBUF
        CALL    ZPRINT
NEXENT:
        DEC     [LINCNT]
        JNZ     SAMLIN
NEXLIN:
        MOV     AL,[LINLEN]
        MOV     [LINCNT],AL
        CALL    CRLF2
        TEST    BYTE PTR[BITS],PSWITCH  ; P switch present?
        JZ      SCROLL          ; If not, just continue
        DEC     BYTE PTR[FULLSCR]
        JNZ     SCROLL
        MOV     BYTE PTR[FULLSCR],LINPERPAG
        MOV     DX,OFFSET TRANGROUP:PAUSEMES
        CALL    PRINT
        CALL    GetKeystroke
        CALL    CRLF2
SCROLL:
        MOV     AH,DIR_SEARCH_NEXT
        JMP     SHOWDIR

SAMLIN:
        MOV     AL,9            ; Output a tab
        CALL    OUT
        JMP     SHORT SCROLL

SHONAME:
        MOV     DI,OFFSET TRANGROUP:CHARBUF
        MOV     CX,8
        REP     MOVSB
        MOV     AL," "
        STOSB
        MOV     CX,3
        REP     MOVSB
        XOR     AX,AX
        STOSB
        PUSH    DX
        MOV     DX,OFFSET TRANGROUP:CHARBUF
        CALL    ZPRINT
        POP     DX
        return

ONESPC:
        MOV     AL," "
        JMP     OUT

CRLF2:
        PUSH    DX
        MOV     DX,OFFSET TRANGROUP:ACRLF
PR:
        PUSH    DS
        PUSH    CS
        POP     DS
        CALL    PRINT
        POP     DS
        POP     DX
        return

PAUSE:
        MOV     DX,OFFSET TRANGROUP:PAUSEMES
        CALL    ERROR_PRINT
        CALL    GetKeystroke
        CALL    CRLF2
        return

ERASE:
        MOV     DX,OFFSET TRANGROUP:BADARGS
        MOV     SI,80H
        LODSB
        OR      AL,AL
        JZ      ERRJ2
        CALL    SCANOFF
        CMP     AL,13           ; RETURN KEY?
        JZ      ERRJ2           ; IF SO NO PARAMETERS SPECIFIED

ERA1:
        CALL    PATHCRUNCH
        JNC     NOTEST2J
        CMP     [DESTISDIR],0           ; No CHDIRs worked
        JZ      NOTEST2J                ; see if they should have
BADCDERR:
        MOV     DX,OFFSET TRANGROUP:BADCD
ERRJ2:
        JMP     CERROR

NOTEST2J:
        JMP     NOTEST2

CRENAME:
        CALL    PATHCRUNCH
        JNC     NOTEST3
        CMP     [DESTISDIR],0           ; No CHDIRs worked
        JZ      NOTEST3                 ; see if they should have
        JMP     BADCDERR

NOTEST3:
        MOV     SI,[PATHPOS]
        MOV     DI,FCB+10H
        CALL    SCANOFF
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
        INT     int_command
        CMP     BYTE PTR DS:[FCB+10H+1]," "  ; Check if parameter exists
        MOV     DX,OFFSET TRANGROUP:BADARGS
        JZ      ERRJ            ; Error if missing parameter
        MOV     AH,FCB_RENAME
        MOV     DX,FCB
        INT     int_command
        PUSH    AX
        CALL    RESTUDIR
        POP     AX
        MOV     DX,OFFSET TRANGROUP:RENERR
        INC     AL
        retnz
ERRJ:
        JMP     CERROR

ASSUME  DS:TRANGROUP,ES:TRANGROUP
TYPEFIL:
        mov     si,81H
        call    SCANOFF         ; Skip to first non-delim
        cmp     al,0DH
        jnz     GOTTARG
        jmp     NOARGERR        ; No args
GOTTARG:
        CALL    SETPATH
        MOV     AX,OPEN SHL 8
        INT     int_command
        MOV     DX,OFFSET TRANGROUP:NOTFND
        JC      ERRJ
        MOV     BX,AX           ; Handle
        MOV     DS,[TPA]
        XOR     DX,DX
ASSUME  DS:NOTHING
TYPELP:
        MOV     CX,[BYTCNT]
        MOV     AH,READ
        INT     int_command
        MOV     CX,AX
        JCXZ    RET56
        PUSH    BX
        MOV     BX,1
        MOV     AH,WRITE
        INT     int_command
        POP     BX
        JC      ERROR_OUTPUTJ
        CMP     AX,CX
        JZ      TYPELP
        DEC     CX
        CMP     AX,CX
        retz                            ; One less byte OK (^Z)
ERROR_OUTPUTJ:
        MOV     BX,1
        MOV     AX,IOCTL SHL 8
        INT     int_command
        TEST    DL,devid_ISDEV
        retnz                           ; If device, no error message
        JMP     ERROR_OUTPUT

RESTUDIR1:
        PUSH    DS
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        CMP     [RESTDIR],0
        POP     DS
ASSUME  DS:TRANGROUP
        retz
RESTUDIR:
        MOV     DX,OFFSET TRANGROUP:USERDIR1
        MOV     AH,CHDIR
        INT     int_command             ; Restore users DIR
        XOR     AL,AL
        CALL    SETREST
RET56:
        return


VOLUME:
        mov     si,81H
        call    SCANOFF         ; Skip to first non-delim
        CMP     BYTE PTR DS:[FCB],0     ;Default drive?
        JZ      CHECKNOARG              ;Yes
        INC     SI
        INC     SI      ;Skip over d:
        MOV     BX,SI
        CALL    SCANOFF
        CMP     BX,SI
        JNZ     OKVOLARG        ; If we skipped some delims at this point, OK
CHECKNOARG:
        cmp     al,0DH
        JZ      OKVOLARG
BADVOLARG:
        MOV     DX,OFFSET TRANGROUP:BADDRV
        JMP     CERROR

OKVOLARG:
        CALL    CRLF2
        PUSH    DS
        POP     ES
        MOV     DI,FCB-7        ; Set up extended FCB
        MOV     AX,-1
        STOSB
        XOR     AX,AX
        STOSW
        STOSW
        STOSB
        MOV     AL,8            ; Look for volume label
        STOSB
        INC     DI              ; Skip drive byte
        MOV     CX,11
        MOV     AL,'?'
        REP     STOSB
        MOV     DX,OFFSET TRANGROUP:DIRBUF
        MOV     AH,SET_DMA
        INT     int_command
        MOV     DX,FCB-7
        MOV     AH,DIR_SEARCH_FIRST
        INT     int_command
        JMP     PRINTVOL

VERSION:
        CALL    CRLF2
        CALL    PRINT_VERSION
        JMP     CRLF2

PRINT_VERSION:
        MOV     DI,OFFSET TRANGROUP:CHARBUF
        MOV     SI,OFFSET TRANGROUP:VERMES_PRE
        CALL    MESTRAN
        MOV     AH,GET_VERSION
        INT     int_command
        PUSH    AX
        XOR     AH,AH
        MOV     CL,10
        DIV     CL
        MOV     CL,4
        SHL     AL,CL
        OR      AL,AH
        MOV     CX,1110H
        MOV     DL,AL
        CALL    OUTBYTE
        MOV     AL,'.'
        STOSB
        POP     AX
        MOV     AL,AH
        XOR     AH,AH
        MOV     CL,10
        DIV     CL
        MOV     CL,4
        SHL     AL,CL
        OR      AL,AH
        MOV     CX,1010H
        MOV     DL,AL
        CALL    OUTBYTE
        MOV     SI,OFFSET TRANGROUP:VERMES_POST
        CALL    MESTRAN
        XOR     AX,AX
        STOSB
        MOV     DX,OFFSET TRANGROUP:CHARBUF
        JMP     ZPRINT

ASSUME  DS:TRANGROUP

CLS:
        IF      IBMVER
        MOV     BX,1
        MOV     AX,IOCTL SHL 8
        INT     int_command
        TEST    DL,devid_ISDEV
        JZ      ANSICLS         ; If a file put out ANSI
        TEST    DL,devid_SPECIAL
        JZ      ANSICLS         ; If not special CON, do ANSI
        MOV     AX,(GET_INTERRUPT_VECTOR SHL 8) OR 29H
        INT     int_command
        MOV     DX,ES
        MOV     AX,(GET_INTERRUPT_VECTOR SHL 8) OR 20H
        INT     int_command
        MOV     AX,ES
        CMP     DX,AX
        JA      ANSICLS         ; If not default driver, do ANSI
        MOV     AH,11           ; Set overscan to black
        XOR     BX,BX
        INT     16
        MOV     AH,15
        INT     16
        MOV     DL,AH
        DEC     DL

        IF      KANJI
        MOV     DH,23
        ELSE
        MOV     DH,25
        ENDIF

        XOR     AX,AX
        MOV     CX,AX

        IF      KANJI
        MOV     BH,0
        ELSE
        MOV     BH,7
        ENDIF

        MOV     AH,6
        INT     16
        XOR     DX,DX
        MOV     BH,0
        MOV     AH,2
        INT     16
        return

ANSICLS:
        ENDIF

        MOV     SI,OFFSET TRANGROUP:CLSSTRING
        LODSB
        MOV     CL,AL
        XOR     CH,CH
        MOV     AH,RAW_CON_IO
CLRLOOP:
        LODSB
        MOV     DL,AL
        INT     int_command
        LOOP    CLRLOOP
        return

$CHDIR:
        MOV     AX,[COMSW]
        OR      AX,[ARGTS]
        MOV     DX,OFFSET TRANGROUP:BADSWT
        JNZ     CERRORJ3
        mov     si,81H
        call    SCANOFF         ; Skip to first non-delim
        cmp     al,0DH
        jz      PWDJ            ; No args
        inc     si              ; Skip first char
        lodsw
        cmp     ax,(0DH SHL 8) OR ':'   ; d:<CR> ?
        jnz     REALCD          ; no
PWDJ:
        jmp     PWD             ; Drive only specified
REALCD:
        CALL    SETPATH
        TEST    [DESTINFO],2
        JNZ     BADCDERRJ
        MOV     AH,CHDIR
        INT     int_command
        retnc
BADCDERRJ:
        JMP  BADCDERR

$MKDIR:
        CALL    SETRMMK
        JNZ     BADMDERR
        MOV     AH,MKDIR
        INT     int_command
        retnc
BADMDERR:
        MOV     DX,OFFSET TRANGROUP:BADMKD
CERRORJ3:
        JMP    CERROR

NOARGERR:
        MOV     DX,OFFSET TRANGROUP:BADARGS
        JMP     SHORT CERRORJ3

SETRMMK:
        mov     si,81H
        call    SCANOFF         ; Skip to first non-delim
        cmp     al,0DH
        jz      NOARGERR        ; No args
        MOV     AX,[COMSW]
        OR      AX,[ARGTS]
        MOV     DX,OFFSET TRANGROUP:BADSWT
        JNZ     CERRORJ3
        CALL    SETPATH
        TEST    [DESTINFO],2
        return

$RMDIR:
        CALL    SETRMMK
        JNZ     BADRDERR
        MOV     AH,RMDIR
        INT     int_command
        retnc
BADRDERR:
        MOV     DX,OFFSET TRANGROUP:BADRMD
        JMP     CERROR

SAVUDIR:
; DL is drive number A=1
        MOV     DI,OFFSET TRANGROUP:USERDIR1
SAVUDIR1:
        MOV     AL,DL
        ADD     AL,'@'
        CMP     AL,'@'
        JNZ     GOTUDRV
        ADD     AL,[CURDRV]
        INC     AL                 ; A = 1
GOTUDRV:
        STOSB
        MOV     AH,[DIRCHAR]
        MOV     AL,DRVCHAR
        STOSW
        PUSH    ES
        POP     DS
ASSUME  DS:NOTHING
        MOV     SI,DI
        MOV     AH,CURRENT_DIR      ; Get the Directory Text
        INT     int_command
        retc
        PUSH    CS
        POP     DS
ASSUME  DS:TRANGROUP
        return

ASSUME  DS:TRANGROUP,ES:TRANGROUP

; Date and time are set during initialization and use
; this routines since they need to do a long return

DATINIT PROC    FAR
        PUSH    ES
        PUSH    DS              ; Going to use the previous stack
        MOV     AX,CS           ; Set up the appropriate segment registers
        MOV     ES,AX
        MOV     DS,AX
        MOV     DX,OFFSET TRANGROUP:INTERNATVARS        ;Set up internat vars
        MOV     AX,INTERNATIONAL SHL 8
        INT     21H
        MOV     WORD PTR DS:[81H],13    ; Want to prompt for date during initialization
        MOV     [COMBUF],COMBUFLEN      ; Init COMBUF
        MOV     WORD PTR [COMBUF+1],0D01H
        CALL    DATE
        CALL    CTIME
        POP     DS
        POP     ES
        RET
DATINIT ENDP

; DATE - Gets and sets the time

DATE_CXDX:
        MOV     BX,CX
P_DATE:
        MOV     AX,BX
        MOV     CX,DX
        MOV     DL,100
        DIV     DL
        XCHG    AL,AH
        XCHG    AX,DX
        MOV     BH,"0"-" "      ; Enable leading zero suppression
        MOV     AX,WORD PTR [INTERNATVARS.Date_tim_format]
        OR      AX,AX
        JZ      USPDAT
        DEC     AX
        JZ      EUPDAT
        MOV     BH,0            ; Disable leading zero suppression
        CALL    P_YR
        CALL    P_DSEP
        CALL    P_MON
        CALL    P_DSEP
        CALL    P_DAY
        return

USPDAT:
        CALL    P_MON
        CALL    P_DSEP
        CALL    P_DAY
PLST:
        CALL    P_DSEP
        CALL    P_YR
        return

EUPDAT:
        CALL    P_DAY
        CALL    P_DSEP
        CALL    P_MON
        JMP     PLST

P_MON:
        MOV     AL,CH
        CALL    OUT2
        return

P_DSEP:
        MOV     AL,BYTE PTR [INTERNATVARS.Date_sep]
        STOSB
        return

P_DAY:
        MOV     AL,CL
        CALL    OUT2
        return

P_YR:
        MOV     AL,DH
        OR      AL,AL
        JZ      TWODIGYR        ; Two instead of 4 digit year
        CALL    OUT2
TWODIGYR:
        MOV     AL,DL
        CALL    OUT2
        return

DATE:
        MOV     SI,81H          ; Accepting argument for date inline
        CALL    SCANOFF
        CMP     AL,13
        JZ      PRMTDAT
        JMP     COMDAT

PRMTDAT:
        MOV     DX,OFFSET TRANGROUP:CURDAT_PRE
        CALL    PRINT           ; Print "Current date is "
        CALL    PRINT_DATE
        MOV     DX,OFFSET TRANGROUP:CURDAT_POST
        CALL    PRINT
GETDAT:
        MOV     DX,OFFSET TRANGROUP:NEWDAT
        CALL    ERROR_PRINT     ; Print "Enter new date: "
        MOV     AH,STD_CON_STRING_INPUT
        MOV     DX,OFFSET TRANGROUP:COMBUF
        INT     int_command             ; Get input line
        CALL    CRLF2
        MOV     SI,OFFSET TRANGROUP:COMBUF+2
        CMP     BYTE PTR[SI],13 ; Check if new date entered
        retz
COMDAT:
        MOV     AX,WORD PTR [INTERNATVARS.Date_tim_format]
        OR      AX,AX
        JZ      USSDAT
        DEC     AX
        JZ      EUSDAT
        CALL    GET_YR
        JC      DATERRJ
        CALL    GET_DSEP
        JC      DATERRJ
        CALL    GET_MON
        JC      DATERRJ
        CALL    GET_DSEP
        JC      DATERRJ
        CALL    GET_DAY
DAT_SET:
        JC      DATERR
        LODSB
        CMP     AL,13
        JNZ     DATERR
        MOV     AH,SET_DATE
        INT     int_command
        OR      AL,AL
        JNZ     DATERR
        return

USSDAT:
        CALL    GET_MON
        JC      DATERR
        CALL    GET_DSEP
DATERRJ:
        JC      DATERR
        CALL    GET_DAY
TGET:
        JC      DATERR
        CALL    GET_DSEP
        JC      DATERR
        CALL    GET_YR
        JMP     DAT_SET

EUSDAT:
        CALL    GET_DAY
        JC      DATERR
        CALL    GET_DSEP
        JC      DATERR
        CALL    GET_MON
        JMP     TGET

GET_MON:
        CALL    GETNUM          ; Get one or two digit number
        retc
        MOV     DH,AH           ; Put in position
        return

GET_DAY:
        CALL    GETNUM
        MOV     DL,AH           ; Put in position
        return

GET_YR:
        CALL    GETNUM
        retc
        MOV     CX,1900
        CALL    GET_DSEP
        PUSHF
        DEC     SI
        POPF
        JZ      BIAS
        CMP     BYTE PTR[SI],13
        JZ      BIAS
        MOV     AL,100
        MUL     AH
        MOV     CX,AX
        CALL    GETNUM
        retc
BIAS:
        MOV     AL,AH
        MOV     AH,0
        ADD     CX,AX

        IF IBM AND KANJI
;
; Gross hack for PC-J machine: CMOS clock cannot handle years after 2079
;
        CMP     CX,2080
        JB      YearOk
        STC
        return
YearOk: CLC
        ENDIF
        return

DATERR:
        MOV     DX,OFFSET TRANGROUP:BADDAT
        CALL    PRINT
        JMP     GETDAT

GET_DSEP:
        LODSB
        CMP     AL,'/'
        retz
        CMP     AL,'.'
        retz
        CMP     AL,'-'
        retz
        STC
        return

; TIME gets and sets the time

CTIME:
        MOV     SI,81H                  ; Accepting argument for time inline
        CALL    SCANOFF
        CMP     AL,13
        JZ      PRMTTIM
        MOV     BX,".:"
        CALL    INLINE
        JMP     COMTIM

PRINT_TIME:
        MOV     AH,GET_TIME
        INT     int_command              ; Get time in CX:DX
        PUSH    DI
        PUSH    ES
        PUSH    CS
        POP     ES
        MOV     DI,OFFSET TRANGROUP:CHARBUF
        MOV     BL,1            ; Always 24 hour time
        CALL    P_TIME
        XOR     AX,AX
        STOSB
        MOV     DX,OFFSET TRANGROUP:CHARBUF
        CALL    ZPRINT
        POP     ES
        POP     DI
        return

P_TIME:
        MOV     AL,CH
        TEST    BL,07FH         ; Ignore high bit
        JNZ     T24             ; 24 hr time?
        MOV     BH,"a"          ; Assume A.M.
        CMP     AL,12           ; In the afternoon?
        JB      MORN
        MOV     BH,"p"
        JE      MORN
        SUB     AL,12           ; Keep it to 12 hours or less
MORN:
        OR      AL,AL           ; Before 1 am?
        JNZ     T24
        MOV     AL,12
T24:
        PUSH    BX
        MOV     BH,"0"-" "      ; Enable leading zero suppression
        CALL    OUT2
        CALL    P_TSEP
        MOV     AL,CL
        CALL    OUT2
        POP     BX
        PUSH    BX
        TEST    BL,80H
        JNZ     PAP             ; If from DIR, go directly to am pm
        MOV     BH,0            ; Disable leading zero suppression
        CALL    P_TSEP
        MOV     AL,DH
        CALL    OUT2
        IF NOT IBMJAPAN
        MOV     AL,"."
        STOSB
        MOV     AL,DL
        CALL    OUT2
        ENDIF
PAP:
        POP     BX
        TEST    BL,07FH         ; Ignore high bit
        retnz                   ; 24 hour time, no am pm
        MOV     AL,BH
        STOSB                   ; Store 'a' or 'p'
        return

P_TSEP:
        MOV     AL,[INTERNATVARS.Time_sep]
        STOSB
        return


PRMTTIM:
        MOV     DX,OFFSET TRANGROUP:CURTIM_PRE
        CALL    PRINT           ; Print "Current time is "
        CALL    PRINT_TIME
        MOV     DX,OFFSET TRANGROUP:CURTIM_POST
        CALL    PRINT
GETTIM:
        XOR     CX,CX           ; Initialize hours and minutes to zero
        MOV     DX,OFFSET TRANGROUP:NEWTIM
        MOV     BX,".:"
        CALL    GETBUF
COMTIM:
        retz                    ; If no time present, don't change it
        JC      TIMERR
        MOV     CX,DX
        XOR     DX,DX
        LODSB
        CMP     AL,13
        JZ      SAVTIM
        CMP     AL,BL
        JZ      GOTSEC
        CMP     AL,BH
        JNZ     TIMERR
GOTSEC:
        CALL    GETNUM
        JC      TIMERR
        MOV     DH,AH           ; Position seconds
        LODSB
        CMP     AL,13
        JZ      SAVTIM
        CMP     AL,"."
        JNZ     TIMERR
        CALL    GETNUM
        JC      TIMERR
        MOV     DL,AH
        LODSB
        CMP     AL,13
        JNZ     TIMERR
SAVTIM:
        MOV     AH,SET_TIME
        INT     int_command
        OR      AL,AL
        retz                    ; Error in time?
TIMERR:
        MOV     DX,OFFSET TRANGROUP:BADTIM
        CALL    PRINT           ; Print error message
        JMP     GETTIM          ; Try again

GETBUF:
        CALL    ERROR_PRINT     ; Print "Enter new time: "
        MOV     AH,STD_CON_STRING_INPUT
        MOV     DX,OFFSET TRANGROUP:COMBUF
        INT     int_command             ; Get input line
        CALL    CRLF2
        MOV     SI,OFFSET TRANGROUP:COMBUF+2
        CMP     BYTE PTR[SI],13 ; Check if new time entered
        retz
INLINE:
        CALL    GETNUM          ; Get one or two digit number
        retc
        MOV     DH,AH           ; Put in position
        LODSB
        CMP     AL,BL
        JZ      NEXT
        CMP     AL,BH
        JZ      NEXT
        DEC     SI              ; Clears zero flag
        CLC
        MOV     DL,0
        return                  ; Time may have only an hour specified

NEXT:
        CALL    GETNUM
        MOV     DL,AH           ; Put in position
        return


TRANCODE        ENDS
                END
                                                                                                                   