; COMMAND version 1.17
;
; This version of COMMAND is divided into three distinct parts. First
; is the resident portion, which includes handlers for interrupts
; 22H (terminate), 23H (Cntrl-C), 24H (fatal error), and 27H (stay
; resident); it also has code to test and, if necessary, reload the
; transient portion. Following the resident is the init code, which is
; overwritten after use. Then comes the transient portion, which
; includes all command processing (whether internal or external).
; The transient portion loads at the end of physical memory, and it may
; be overlayed by programs that need as much memory as possible. When
; the resident portion of command regains control from a user program,
; a checksum is performed on the transient portion to see if it must be
; reloaded. Thus programs which do not need maximum memory will save
; the time required to reload COMMAND when they terminate.

;Use the following booleans to set assembly flags
FALSE   EQU     0
TRUE    EQU     NOT FALSE

IBMVER  EQU     FALSE   ;Switch to build IBM version of Command
MSVER   EQU     TRUE    ;Switch to build MS-DOS version of Command

HIGHMEM EQU     TRUE    ;Run resident part above transient (high memory)

LINPERPAG       EQU     23
NORMPERLIN      EQU     1
WIDEPERLIN      EQU     5

        IF      IBMVER
SYM     EQU     ">"
COMDRV  EQU     1
        ENDIF

        IF      MSVER
SYM     EQU     ":"
COMDRV  EQU     0
        ENDIF

FCB     EQU     5CH
DSKRESET EQU    13
SETBASE EQU     38
SRCHFRST EQU    17
SRCHNXT EQU     18
RENAM   EQU     23
INCHAR  EQU     1
GETFAT  EQU     27
OPEN    EQU     15
CLOSE   EQU     16
MAKE    EQU     22
DELETE  EQU     19
RDBLK   EQU     39
WRBLK   EQU     40
SETDMA  EQU     26
SELDRV  EQU     14
GETDRV  EQU     25
PRINTBUF EQU    9
OUTCH   EQU     2
INBUF   EQU     10
GETDATE EQU     2AH
SETDATE EQU     2BH
GETTIME EQU     2CH
SETTIME EQU     2DH
RR      EQU     33
RECLEN  EQU     14
FILLEN  EQU     16
OFFDATE EQU     20


;The following are all of the segments used in the load order

CODERES SEGMENT
CODERES ENDS

DATARES SEGMENT BYTE
DATARES ENDS

INIT    SEGMENT BYTE
INIT    ENDS

TAIL    SEGMENT PARA
TAIL    ENDS

TRANCODE        SEGMENT PARA
TRANCODE        ENDS

TRANDATA        SEGMENT BYTE
TRANDATA        ENDS

TRANSPACE       SEGMENT BYTE
TRANSPACE       ENDS

RESGROUP        GROUP   CODERES,DATARES,INIT,TAIL
TRANGROUP       GROUP   TRANCODE,TRANDATA,TRANSPACE

;Data for resident portion

DATARES SEGMENT BYTE
        ORG     0
ZERO    =       $
MESBAS  DW      OFFSET RESGROUP:ERR0
        DW      OFFSET RESGROUP:ERR2
        DW      OFFSET RESGROUP:ERR4
        DW      OFFSET RESGROUP:ERR6
        DW      OFFSET RESGROUP:ERR8
        DW      OFFSET RESGROUP:ERR10
        DW      OFFSET RESGROUP:ERR12
ERR0    DB      "Write protect$"
ERR2    DB      "Not ready$"
ERR4    DB      "Data$"
ERR6    DB      "Seek$"
ERR8    DB      "Sector not found$"
ERR10   DB      "Write fault$"
ERR12   DB      "Disk$"
READ    DB      "read$"
WRITE   DB      "writ$"
ERRMES  DB      " error "
IOTYP   DB      "writing"
DRVNUM  DB      " drive "
DRVLET  DB      "A"
NEWLIN  DB      13,10,"$"
REQUEST DB      "Abort, Retry, Ignore? $"
BADFAT  DB      13,10,"File allocation table bad,$"
COMBAD  DB      13,10,"Invalid COMMAND.COM"
NEEDCOM DB      13,10,"Insert DOS disk in "
        IF      IBMVER
        DB      "drive A"
        ELSE
        DB      "default drive"
        ENDIF
PROMPT  DB      13,10,"and strike any key when ready",13,10,"$"
NEEDBAT DB      13,10,"Insert disk with batch file$"
ENDBATMES DB    13,10,"Terminate batch job (Y/N)? $"
LOADING DB      0
BATFCB  DB      1,"AUTOEXECBAT"
        DB      21 DUP(?)
        DW      0
        DW      0               ;Initialize RR field to zero
PARMTAB DW      10 DUP(-1)      ;No parameters initially
BATCH   DB      1               ;Assume batch mode initially
COMFCB  DB      COMDRV,"COMMAND COM"
        DB      25 DUP(?)
TRANS   DW      OFFSET TRANGROUP:COMMAND
TRNSEG  DW      ?
BATBYT  DB      ?
MEMSIZ  DW      ?
SUM     DW      ?
INITADD DB      4 DUP(?)
RESDATASIZE     EQU     $-ZERO
DATARES ENDS

;Data for transient portion

TRANDATA        SEGMENT BYTE
        ORG     0
ZERO    EQU     $
BADNAM  DB      "Bad command or file name",13,10,"$"
MISNAM  DB      "Missing file name$"
RENERR  DB      "Duplicate file name or "
NOTFND  DB      "File not found$"
EXEBAD  DB      "Error in EXE file$"
NOSPACE DB      "Insufficient disk space",13,10,"$"
FULDIR  DB      "File creation error",13,10,"$"
OVERWR  DB      "File cannot be copied onto itself",13,10,"$"
LOSTERR DB      "Content of destination lost before copy",13,10,"$"
COPIED  DB      " File(s) copied$"
DIRMES  DB      " File(s)$"
TOOBIG  DB      "Program too big to fit in memory$"
BADDRV  DB      "Invalid drive specification$"
PAUSMES DB      "Strike a key when ready . . . $"
BADSWT  DB      "Illegal switch",13,10,"$"
WEEKTAB DB      "SunMonTueWedThuFriSat"
BADDAT  DB      13,10,"Invalid date$"
CURDAT  DB      "Current date is $"
NEWDAT  DB      13,10,"Enter new date: $"
BADTIM  DB      13,10,"Invalid time$"
CURTIM  DB      "Current time is $"
NEWTIM  DB      13,10,"Enter new time: $"
SUREMES DB      "Are you sure (Y/N)? $"

COMTAB  DB      4,"DIR",1
        DW      OFFSET TRANGROUP:CATALOG
        DB      7,"RENAME",1
        DW      OFFSET TRANGROUP:RENAME
        DB      4,"REN",1
        DW      OFFSET TRANGROUP:RENAME
        DB      6,"ERASE",1
        DW      OFFSET TRANGROUP:ERASE
        DB      4,"DEL",1
        DW      OFFSET TRANGROUP:ERASE
        DB      5,"TYPE",1
        DW      OFFSET TRANGROUP:TYPEFIL
        DB      4,"REM",1
        DW      OFFSET TRANGROUP:COMMAND
        DB      5,"COPY",1
        DW      OFFSET TRANGROUP:COPY
        DB      6,"PAUSE",1
        DW      OFFSET TRANGROUP:PAUSE
        DB      5,"DATE",0
        DW      OFFSET TRANGROUP:DATE
        DB      5,"TIME",0
        DW      OFFSET TRANGROUP:TIME
        DB      0               ;Terminate command table

COMBUF  DB      128,1,13

TRANDATASIZE    EQU     $-ZERO
TRANDATA        ENDS

;Uninitialized transient data
TRANSPACE       SEGMENT BYTE
        ORG     0
ZERO    =       $
        DB      128 DUP(?)
TPA     DW      1 DUP(?)
RESSEG  DW      1 DUP(?)
CHKDRV  DB      1 DUP(?)
FILTYP  DB      1 DUP(?)
CURDRV  DB      1 DUP(?)
PARM1   DB      1 DUP(?)
PARM2   DB      1 DUP(?)
COMSW   DW      1 DUP(?)
ARG1S   DW      1 DUP(?)
ARG2S   DW      1 DUP(?)
FLAGER  DB      1 DUP(?)
CFLAG   DB      1 DUP(?)
SPECDRV DB      1 DUP(?)
BYTCNT  DW      1 DUP(?)
NXTADD  DW      1 DUP(?)
LINCNT  DB      1 DUP(?)
LINLEN  DB      1 DUP(?)
FILECNT DW      1 DUP(?)
EXEFCB  LABEL WORD
IDLEN   DB      1 DUP(?)
ID      DB      8 DUP(?)
COM     DB      3 DUP(?)
DEST    DB      37 DUP(?)
DESTNAME DB     11 DUP(?)
DIRBUF  DB      37 DUP(?)
BITS    DW      1 DUP(?)
FULLSCR DW      1 DUP(?)
EXEEND  DW      1 DUP(?)
;Header variables for EXE file load
;These are overlapped with COPY variables, below
RUNVAR  LABEL WORD
RELPT   DW      1 DUP(?)
RELSEG  DW      1 DUP(?)
PSIZE   LABEL   WORD
PAGES   DW      1 DUP(?)
RELCNT  DW      1 DUP(?)
HEADSIZ DW      1 DUP(?)
        DW      1 DUP(?)
LOADLOW DW      1 DUP(?)
INITSS  DW      1 DUP(?)
INITSP  DW      1 DUP(?)
        DW      1 DUP(?)
INITIP  DW      1 DUP(?)
INITCS  DW      1 DUP(?)
RELTAB  DW      1 DUP(?)
RUNVARSIZ       EQU     $-RUNVAR

        DB      80H DUP(?)
STACK   LABEL   WORD

PRETRLEN        EQU     $-ZERO          ;Used later to compute TRNLEN

        ORG     RUNVAR-ZERO                     ;Overlaps EXE variables

SRCPT   DW      1 DUP(?)
INEXACT DB      1 DUP(?)
APPEND  DB      1 DUP(?)
NOWRITE DB      1 DUP(?)
ASCII   DB      1 DUP(?)
PLUS    DB      1 DUP(?)
SOURCE  DB      11 DUP(?)
TRANSPACESIZE   EQU     $-ZERO
TRANSPACE       ENDS


;START OF RESIDENT PORTION

CODERES SEGMENT
ASSUME  CS:RESGROUP,DS:RESGROUP,ES:RESGROUP,SS:RESGROUP
        ORG     0
ZERO    =       $
PARMBUF LABEL   WORD

        ORG     100H

RSTACK  LABEL   WORD

PROGSTART:
        JMP     CONPROC

LTPA    DW      0               ;WILL STORE TPA SEGMENT HERE
MYSEG   DW      0               ;Put our own segment here

CONTC:
        MOV     AX,CS
        MOV     DS,AX
        MOV     SS,AX
        MOV     SP,OFFSET RESGROUP:RSTACK
        STI
        CALL    SETVECT
        MOV     AH,DSKRESET
        INT     33              ;Reset disks in case files were open
        TEST    [BATCH],-1
        JZ      LODCOM
ASKEND:
        MOV     DX,OFFSET RESGROUP:ENDBATMES
        MOV     AH,PRINTBUF
        INT     33
        MOV     AX,0C00H+INCHAR
        INT     33
        AND     AL,5FH
        CMP     AL,"N"
        JZ      LODCOM
        CMP     AL,"Y"
        JNZ     ASKEND
        MOV     [BATCH],0
LODCOM:
        MOV     AX,CS
        MOV     SS,AX
        MOV     SP,OFFSET RESGROUP:RSTACK
        MOV     DS,AX
        CALL    SETVECT
        CALL    CHKSUM
        CMP     DX,[SUM]
        JZ      HAVCOM
        MOV     [LOADING],1
        CALL    LOADCOM
CHKSAME:
        CALL    CHKSUM
        CMP     DX,[SUM]
        JZ      HAVCOM
        CALL    WRONGCOM
        JMP     SHORT CHKSAME
HAVCOM:
        MOV     [LOADING],0
        MOV     SI,OFFSET RESGROUP:LTPA
        MOV     DI,OFFSET TRANGROUP:TPA
        MOV     ES,[TRNSEG]
        CLD
        MOVSW           ;Move TPA segment to transient storage
        MOVSW           ;Move resident segment too
        MOV     AX,[MEMSIZ]
        MOV     WORD PTR ES:[2],AX
        JMP     DWORD PTR [TRANS]

RESIDENT:
        ADD     DX,15
        MOV     CL,4
        SHR     DX,CL           ;Number of paragraphs of new addition
        ADD     CS:[LTPA],DX
        XOR     AX,AX
        MOV     DS,AX
        JMP     DWORD PTR DS:[80H]              ;Pretend user executed INT 20H

DSKERR:
        ;******************************************************
        ;       THIS IS THE DEFAULT DISK ERROR HANDLING CODE 
        ;       AVAILABLE TO ALL USERS IF THEY DO NOT TRY TO 
        ;       INTERCEPT INTERRUPT 24H.
        ;******************************************************
        STI
        PUSH    DS
        PUSH    CS
        POP     DS              ;Set up local data segment
        PUSH    DX
        CALL    CRLF
        POP     DX
        ADD     AL,"A"          ;Compute drive letter
        MOV     [DRVLET],AL
        TEST    AH,80H          ;Check if hard disk error
        JNZ     FATERR
        MOV     SI,OFFSET RESGROUP:READ
        TEST    AH,1
        JZ      SAVMES
        MOV     SI,OFFSET RESGROUP:WRITE
SAVMES:
        LODSW
        MOV     WORD PTR [IOTYP],AX
        LODSW
        MOV     WORD PTR [IOTYP+2],AX
        AND     DI,0FFH
        CMP     DI,12
        JBE     HAVCOD
        MOV     DI,12
HAVCOD:
        MOV     DI,WORD PTR [DI+MESBAS] ;Get pointer to error message
        XCHG    DI,DX           ;May need DX later
        MOV     AH,PRINTBUF
        INT     33              ;Print error type
        MOV     DX,OFFSET RESGROUP:ERRMES
        INT     33
        CMP     [LOADING],0
        JNZ     GETCOMDSK
ASK:
        MOV     DX,OFFSET RESGROUP:REQUEST
        MOV     AH,PRINTBUF
        INT     33
        MOV     AX,0C00H+INCHAR
        INT     33              ;Get response
        CALL    CRLF
        OR      AL,20H          ;Convert to lower case
        MOV     AH,0            ;Return code for ignore
        CMP     AL,"i"          ;Ignore?
        JZ      EXIT
        INC     AH
        CMP     AL,"r"          ;Retry?
        JZ      EXIT
        INC     AH
        CMP     AL,"a"          ;Abort?
        JNZ     ASK
EXIT:
        MOV     AL,AH
        MOV     DX,DI
        POP     DS
        IRET

FATERR:
        MOV     DX,OFFSET RESGROUP:BADFAT
        MOV     AH,PRINTBUF
        INT     33
        MOV     DX,OFFSET RESGROUP:DRVNUM
        INT     33
        MOV     AL,2            ;Abort
        POP     DS
        IRET

GETCOMDSK:
        MOV     DX,OFFSET RESGROUP:NEEDCOM
        MOV     AH,PRINTBUF
        INT     33
        MOV     AX,0C07H        ;Get char without testing or echo
        INT     33
        JMP     LODCOM

CRLF:
        MOV     DX,OFFSET RESGROUP:NEWLIN
        PUSH    AX
        MOV     AH,PRINTBUF
        INT     33
        POP     AX
RET10:  RET

LOADCOM:
        PUSH    DS
        MOV     DS,[TRNSEG]
        MOV     DX,100H
        MOV     AH,SETDMA
        INT     33
        POP     DS
        MOV     DX,OFFSET RESGROUP:COMFCB
        MOV     AH,OPEN
        INT     33              ;Open COMMAND.COM
        OR      AL,AL
        JZ      READCOM
        MOV     DX,OFFSET RESGROUP:NEEDCOM
PROMPTCOM:
        MOV     AH,PRINTBUF
        INT     33
        MOV     AX,0C07H        ;Get char without testing or echo
        INT     33
        JMP     SHORT LOADCOM
READCOM:
        MOV     WORD PTR[COMFCB+RR],OFFSET RESGROUP:TRANSTART
        XOR     AX,AX
        MOV     WORD PTR[COMFCB+RR+2],AX
        MOV     [COMFCB],AL             ;Use default drive
        INC     AX
        MOV     WORD PTR[COMFCB+RECLEN],AX
        MOV     CX,COMLEN
        MOV     DX,OFFSET RESGROUP:COMFCB
        MOV     AH,RDBLK
        INT     33
        OR      AL,AL
        JZ      RET10
WRONGCOM:
        MOV     DX,OFFSET RESGROUP:COMBAD
        JMP     SHORT PROMPTCOM

CHKSUM:
        CLD
        PUSH    DS
        MOV     DS,[TRNSEG]
        MOV     SI,100H
        MOV     CX,COMLEN
        SHR     CX,1
        XOR     DX,DX
CHK:
        LODSW
        ADD     DX,AX
        LOOP    CHK
        POP     DS
        RET

SETVECT:
        MOV     DX,OFFSET RESGROUP:LODCOM
        MOV     AX,2522H        ;Set Terminate address
        INT     21H
        MOV     DX,OFFSET RESGROUP:CONTC
        MOV     AX,2523H        ;Set Ctrl-C address
        INT     21H
        MOV     DX,OFFSET RESGROUP:DSKERR
        MOV     AX,2524H        ;Set Hard Disk Error address
        INT     33
        MOV     DX,OFFSET RESGROUP:RESIDENT
        MOV     AX,2527H        ;Set Terminate and Stay Resident address
        INT     33
        RET
RESCODESIZE     EQU     $-ZERO
CODERES ENDS

;*******************************************************************
;START OF INIT PORTION
;This code is overlayed the first time the TPA is used.

INIT    SEGMENT BYTE

        ORG     0
ZERO    =       $
CONPROC:
        MOV     SP,OFFSET RESGROUP:RSTACK

        IF      HIGHMEM
        MOV     AX,WORD PTR DS:[2]
        SUB     AX,((RESCODESIZE+RESDATASIZE)+15)/16            ;Subtract size of resident
        MOV     WORD PTR DS:[2],AX
        MOV     ES,AX
        MOV     SI,100H
        MOV     DI,SI
        MOV     CX,((RESCODESIZE+RESDATASIZE)-100H+1)/2 ;Length of resident in words
        REP     MOVSW                   ;Move to end of memory
        MOV     DS,AX
        MOV     [LTPA],CS
        ENDIF

        IF      NOT HIGHMEM
        MOV     AX,CS
        ADD     AX,((RESCODESIZE+RESDATASIZE)+15)/16            ;Compute segment of TPA
        MOV     [LTPA],AX
        MOV     AX,WORD PTR DS:[2]
        ENDIF

        MOV     [MYSEG],DS
        MOV     [MEMSIZ],AX
        SUB     AX,TRNLEN               ;Subtract size of transient
        MOV     [TRNSEG],AX
        CALL    SETVECT
        CALL    LOADCOM
        CALL    CHKSUM
        MOV     [SUM],DX

        IF MSVER
        IF      HIGHMEM
        PUSH    DS
        PUSH    CS
        POP     DS
        ENDIF
        MOV     DX,OFFSET RESGROUP:HEADER
        MOV     AH,PRINTBUF
        INT     33
        IF      HIGHMEM
        POP     DS
        ENDIF
        ENDIF

        MOV     DX,OFFSET RESGROUP:BATFCB
        MOV     AH,OPEN
        INT     33                      ;See if AUTOEXEC.BAT exists
        MOV     WORD PTR[BATFCB+RECLEN],1       ;Set record length to 1
        OR      AL,AL                   ;Zero means file found
        JZ      DRV0
        MOV     [BATCH],0               ;Not found--turn off batch job
        MOV     AX,OFFSET TRANGROUP:DATINIT
        MOV     WORD PTR[INITADD],AX
        MOV     AX,[TRNSEG]
        MOV     WORD PTR[INITADD+2],AX
        CALL    DWORD PTR DS:[INITADD]

        IF IBMVER
        MOV     DX,OFFSET RESGROUP:HEADER
        MOV     AH,PRINTBUF
        INT     33
        ENDIF

DRV0:
        JMP     HAVCOM


        IF MSVER
HEADER  DB      13,10,"Command v. 1.17"
        IF      HIGHMEM
        DB      "H"
        ENDIF
        DB      13,10,"$"
        ENDIF

        IF IBMVER
HEADER  DB      13,10,13,10,"The IBM Personal Computer DOS",13,10
        DB      "Version 1.10 (C)Copyright IBM Corp 1981, 1982",13,10,"$"
        DB      "Licensed Material - Program Property of IBM"
        ENDIF

INITSIZE        EQU     $-ZERO
INIT    ENDS

;This TAIL segment is used to produce a PARA aligned label in the resident
; group which is the location where the transient segments will be loaded
; initialy.

TAIL    SEGMENT PARA
        ORG     0
TRANSTART       LABEL   WORD
TAIL    ENDS

;********************************************************************
;START OF TRANSIENT PORTION
;This code is loaded at the end of memory and may be overwritten by
;memory-intensive user programs.

TRANCODE        SEGMENT PARA
ASSUME  CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:TRANGROUP

WSWITCH EQU     1               ;Wide display during DIR
PSWITCH EQU     2               ;Pause (or Page) mode during DIR
VSWITCH EQU     4               ;Verify during COPY
ASWITCH EQU     8               ;ASCII mode during COPY
BSWITCH EQU     10H             ;Binary mode during COPY

        ORG     0
ZERO    =       $

        ORG     100H            ;Allow for 100H parameter area

SETDRV:
        MOV     AH,SELDRV
        INT     21H
COMMAND:
        CLD
        MOV     AX,CS
        MOV     SS,AX
        MOV     SP,OFFSET TRANGROUP:STACK
        MOV     ES,AX
        MOV     DS,AX
        STI
        MOV     AX,46*100H
        MOV     DL,0
        INT     33              ;Turn off verify after write
        MOV     AX,CS           ;Get segment we're in
        SUB     AX,[TPA]        ;AX=size ot TPA in paragraphs
        MOV     DX,16
        MUL     DX              ;DX:AX=size of TPA in bytes
        OR      DX,DX           ;See if over 64K
        JZ      SAVSIZ          ;OK if not
        MOV     AX,-1           ;If so, limit to 65535 bytes
SAVSIZ:
        MOV     [BYTCNT],AX     ;Max no. of bytes that can be buffered
        CALL    CRLF2
GETCOM:
        MOV     AH,GETDRV
        INT     21H
        MOV     [CURDRV],AL
        ADD     AL,"A"
        CALL    OUT             ;Print letter for default drive
        MOV     AL,SYM
        CALL    OUT
        MOV     DS,[RESSEG]     ;All batch work must use resident seg.
ASSUME  DS:RESGROUP
        TEST    [BATCH],-1
        JNZ     READBAT
        PUSH    CS
        POP     DS              ;Need local segment to point to buffer
ASSUME  DS:TRANGROUP
        MOV     DX,OFFSET TRANGROUP:COMBUF
        MOV     AH,INBUF
        INT     21H             ;Get a command
        JMP     DOCOM

;All batch proccessing has DS set to segment of resident portion
ASSUME  DS:RESGROUP
NEEDPARM:
        CALL    GETBATBYT
        CMP     AL,"%"          ;Check for two consecutive %
        JZ      SAVBATBYT
        CMP     AL,13           ;Check for end-of-line
        JZ      SAVBATBYT
        SUB     AL,"0"
        JB      RDBAT           ;Ignore parameter reference if invalid
        CMP     AL,9
        JA      RDBAT
        CBW
        MOV     SI,AX
        SHL     SI,1            ;Two bytes per entry
        MOV     SI,[SI+OFFSET RESGROUP:PARMTAB] ;Get pointer to corresponding parameter
        CMP     SI,-1           ;Check if parameter exists
        JZ      RDBAT           ;Ignore if it doesn't
        MOV     AH,OUTCH
RDPARM:
        LODSB           ;From resident segment
        CMP     AL,0DH          ;Check for end of parameter
        JZ      RDBAT
        STOSB           ;To transient segment
        MOV     DL,AL
        INT     33              ;Display paramters too
        JMP     SHORT RDPARM

PROMPTBAT:
        MOV     AH,PRINTBUF
        MOV     DX,OFFSET RESGROUP:NEEDBAT
        INT     33              ;Prompt for batch file
        MOV     AH,PRINTBUF
        MOV     DX,OFFSET RESGROUP:PROMPT
        INT     33
        MOV     AX,0C00H+INCHAR
        INT     33
        JMP     COMMAND

BADCOMJ1:JMP    BADCOM

READBAT:
        MOV     DX,OFFSET RESGROUP:BATFCB
        MOV     AH,OPEN
        INT     33              ;Make sure batch file still exists
        OR      AL,AL
        JNZ     PROMPTBAT       ;If OPEN fails, prompt for disk
        MOV     WORD PTR [BATFCB+RECLEN],1
        MOV     DX,OFFSET RESGROUP:BATBYT
        MOV     AH,SETDMA
        INT     33
        MOV     DI,OFFSET TRANGROUP:COMBUF+2
RDBAT:
        CALL    GETBATBYT
        CMP     AL,"%"          ;Check for parameter
        JZ      NEEDPARM
SAVBATBYT:
        STOSB
        CALL    OUT             ;Display batched command line
        CMP     AL,0DH
        JNZ     RDBAT
        SUB     DI,OFFSET TRANGROUP:COMBUF+3
        MOV     AX,DI
        MOV     ES:[COMBUF+1],AL        ;Set length of line
        CALL    GETBATBYT       ;Eat linefeed
        PUSH    CS
        POP     DS              ;Go back to local segment
ASSUME DS:TRANGROUP
DOCOM:
;All segments are local for command line processing
        MOV     AL,10
        CALL    OUT
        MOV     SI,OFFSET TRANGROUP:COMBUF+2
        MOV     DI,OFFSET TRANGROUP:IDLEN
        MOV     AX,2901H        ;Make FCB with blank scan-off
        INT     21H
        CMP     AL,1            ;Check for ambiguous command name
        JZ      BADCOMJ1        ;Ambiguous commands not allowed
        CMP     AL,-1
        JNZ     DRVGD
        JMP     DRVBAD
DRVGD:
        MOV     AL,[DI]
        MOV     [SPECDRV],AL
        MOV     AL," "
        MOV     CX,9
        INC     DI
        REPNE   SCASB           ;Count no. of letters in command name
        MOV     AL,9
        SUB     AL,CL
        MOV     [IDLEN],AL
        MOV     DI,81H
        MOV     CX,0
        PUSH    SI
COMTAIL:
        LODSB
        STOSB           ;Move command tail to 80H
        CMP     AL,13
        LOOPNZ  COMTAIL
        NOT     CL
        MOV     BYTE PTR DS:[80H],CL
        POP     SI
;If the command has 0 parameters must check here for
;any switches that might be present.
;SI -> first character after the command.
        MOV     [FLAGER],0      ;Set error flag before any calls to switch 
        CALL    SWITCH          ;Is the next character a "/"
        MOV     [COMSW],AX
        MOV     DI,FCB
        MOV     AX,2901H
        INT     21H
        MOV     [PARM1],AL      ;Save result of parse
        CALL    SWITCH
        MOV     [ARG1S],AX
        MOV     DI,FCB+10H
        MOV     AX,2901H
        INT     21H             ;Parse file name
        MOV     [PARM2],AL      ;Save result
        CALL    SWITCH
        MOV     [ARG2S],AX
        MOV     AL,[IDLEN]
        MOV     DL,[SPECDRV]
        OR      DL,DL           ;Check if drive was specified
        JZ      OK
        JMP     DRVCHK
OK:     DEC     AL              ;Check for null command
        JNZ     FNDCOM
        JMP     GETCOM

RETSW:
        XCHG    AX,BX           ;Put switches in AX
        RET

SWITCH:
        XOR     BX,BX           ;Initialize - no switches set
SWLOOP:
        CALL    SCANOFF         ;Skip any delimiters
        CMP     AL,"/"          ;Is it a switch specifier?
        JNZ     RETSW           ;No -- we're finished
        INC     SI              ;Skip over "/"
        CALL    SCANOFF
        INC     SI
;Convert lower case input to upper case
        CMP     AL,"a"
        JB      SAVCHR
        CMP     AL,"z"
        JA      SAVCHR
        SUB     AL,20H          ;Lower-case changed to upper-case
SAVCHR:
        MOV     DI,OFFSET TRANGROUP:SWLIST
        MOV     CX,SWCOUNT
        REPNE   SCASB                   ;Look for matching switch
        JNZ     BADSW
        MOV     AX,1
        SHL     AX,CL           ;Set a bit for the switch
        OR      BX,AX
        JMP     SHORT SWLOOP

BADSW:
        MOV     [FLAGER],1      ;Record error in switch
        JMP     SHORT SWLOOP

SWLIST  DB      "BAVPW"
SWCOUNT EQU     $-SWLIST

DRVBAD:
        MOV     DX,OFFSET TRANGROUP:BADDRV
        JMP     ERROR

FNDCOM:
        MOV     SI,OFFSET TRANGROUP:COMTAB      ;Prepare to search command table
        MOV     CH,0
FINDCOM:
        MOV     DI,OFFSET TRANGROUP:IDLEN
        MOV     CL,[SI]
        JCXZ    EXTERNAL
        REPE    CMPSB
        LAHF
        ADD     SI,CX           ;Bump to next position without affecting flags
        SAHF
        LODSB           ;Get flag for drive check
        MOV     [CHKDRV],AL
        LODSW           ;Get address of command
        JNZ     FINDCOM
        MOV     DX,AX
        CMP     [CHKDRV],0
        JZ      NOCHECK
        MOV     AL,[PARM1]
        OR      AL,[PARM2]      ;Check if either parm. had invalid drive
        CMP     AL,-1
        JZ      DRVBAD
NOCHECK:CALL    DX
COMJMP: JMP     COMMAND

BADCOMJ:JMP     BADCOM

SETDRV1:
        JMP     SETDRV

DRVCHK:
        DEC     DL              ;Adjust for correct drive number
        DEC     AL              ;Check if anything else is on line
        JZ      SETDRV1
EXTERNAL:
        MOV     AL,[SPECDRV]
        MOV     [IDLEN],AL
        MOV     WORD PTR[COM],4F00H+"C" ;"CO"
        MOV     BYTE PTR[COM+2],"M"
        MOV     DX,OFFSET TRANGROUP:IDLEN
        MOV     AH,OPEN
        INT     33              ;Check if command to be executed
        MOV     [FILTYP],AL     ;0 for COM files, -1 for EXE files
        OR      AL,AL
        JZ      EXECUTE
        MOV     WORD PTR[COM],5800H+"E" ;"EX"
        MOV     BYTE PTR[COM+2],"E"
        INT     33              ;Check for EXE file
        OR      AL,AL
        JZ      EXECUTE
        MOV     WORD PTR[COM],4100H+"B" ;"BA"
        MOV     BYTE PTR[COM+2],"T"
        INT     33              ;Check if batch file to be executed
        OR      AL,AL
        JNZ     BADCOMJ
BATCOM:
;Batch parameters are read with ES set to segment of resident part
        MOV     ES,[RESSEG]
ASSUME  ES:RESGROUP
        MOV     DI,OFFSET RESGROUP:PARMTAB
        MOV     AX,-1
        MOV     CX,10
        REP     STOSW           ;Zero parameter pointer table
        MOV     SI,OFFSET TRANGROUP:COMBUF+2
        MOV     DI,OFFSET RESGROUP:PARMBUF
        MOV     BX,OFFSET RESGROUP:PARMTAB
EACHPARM:
        CALL    SCANOFF
        CMP     AL,0DH
        JZ      HAVPARM
        MOV     ES:[BX],DI              ;Set pointer table to point to actual parameter
        INC     BX
        INC     BX
MOVPARM:
        LODSB
        CALL    DELIM
        JZ      ENDPARM         ;Check for end of parameter
        STOSB
        CMP     AL,0DH
        JZ      HAVPARM
        JMP     SHORT MOVPARM
ENDPARM:
        MOV     AL,0DH
        STOSB           ;End-of-parameter marker
        CMP     BX,OFFSET RESGROUP:PARMTAB+20   ;Maximum number of parameters?
        JB      EACHPARM
HAVPARM:
        MOV     SI,OFFSET TRANGROUP:IDLEN
        MOV     DI,OFFSET RESGROUP:BATFCB
        MOV     CX,16
        REP     MOVSW           ;Move into private batch FCB
        XOR     AX,AX
        PUSH    ES
        POP     DS                      ;Simply batch FCB setup
ASSUME  DS:RESGROUP
        MOV     WORD PTR[BATFCB+RR],AX
        MOV     WORD PTR[BATFCB+RR+2],AX        ;Zero RR field
        INC     AX
        MOV     WORD PTR[BATFCB+RECLEN],AX      ;Set record length to 1 byte
        MOV     [BATCH],AL              ;Flag batch job in progress
        JMP     COMMAND
ASSUME  DS:TRANGROUP,ES:TRANGROUP

EXECUTE:
        MOV     AX,WORD PTR[IDLEN+16]
        OR      AX,WORD PTR[IDLEN+18]           ;See if zero length
        JZ      BADCOM                  ;If so, error
        XOR     AX,AX
        MOV     WORD PTR[IDLEN+RR],AX
        MOV     WORD PTR[IDLEN+RR+2],AX         ;Set RR field to zero
        INC     AX
        MOV     WORD PTR[IDLEN+RECLEN],AX       ;Set record length field to 1
        MOV     DX,[TPA]
        MOV     BX,DX
        MOV     AH,SETBASE
        INT     21H
        TEST    [FILTYP],-1             ;Check if file is COM or EXE
        JZ      COMLOAD
        JMP     EXELOAD
COMLOAD:PUSH    DS
        MOV     DS,DX
        MOV     DX,100H
        MOV     AH,SETDMA
        INT     21H
        POP     DS
        MOV     CX,[BYTCNT]
        SUB     CX,100H
        MOV     DX,OFFSET TRANGROUP:IDLEN
        MOV     AH,RDBLK
        INT     21H
        DEC     AL
        MOV     DX,OFFSET TRANGROUP:TOOBIG
        JNZ     ERROR
;Set up exit conditions
        MOV     CX,[BYTCNT]
        MOV     DS,BX
        MOV     ES,BX
        CLI
        MOV     SS,BX
        MOV     SP,CX
        STI
        SUB     CX,100H         ;Allow some stack space
        XOR     AX,AX
        PUSH    AX
        MOV     AX,100H
        PUSH    BX
        PUSH    AX
        CALL    SETUP
XXX     PROC    FAR
        RET
XXX     ENDP
BADCOM:
        MOV     DX,OFFSET TRANGROUP:BADNAM
ERROR:
        MOV     AH,PRINTBUF
        INT     21H
        JMP     COMMAND

CHKCNT:
        TEST    [FILECNT],-1
        JNZ     ENDDIR
        MOV     DX,OFFSET TRANGROUP:NOTFND
        JMP     ERROR

ENDDIR:
;Make sure last line ends with CR/LF
        MOV     AL,[LINLEN]
        CMP     AL,[LINCNT]     ;Will be equal if just had CR/LF
        JZ      MESSAGE
        CALL    CRLF2
MESSAGE:                
        MOV     SI,[FILECNT]
        XOR     DI,DI
        CALL    DISP32BITS
        MOV     DX,OFFSET TRANGROUP:DIRMES
        MOV     AH,PRINTBUF
        INT     21H
        RET

CATALOG:
        MOV     AL,"?"                  ;*.* is default file spec.
        MOV     DI,5DH
        MOV     CX,11
        REP     STOSB
        MOV     SI,81H
        CALL    SWITCH
        MOV     DI,5CH
        MOV     AX,41*100H+0DH          ;Parse with default name and extension
        INT     33

;Begin by processing any switches that may have been specified.
;BITS will contain any information about switches that was
;found when the command line was parsed.

SETSWT:
        MOV     AX,[COMSW]              ;Get switches from command
        OR      AX,[ARG1S]              ;OR in switches from first parameter
        MOV     [BITS],AX
        MOV     BYTE PTR[FULLSCR],LINPERPAG
        TEST    AL,1                    ;Look for /W
        MOV     AL,NORMPERLIN
        JZ      DIR
        MOV     AL,WIDEPERLIN
DIR:
        MOV     [LINLEN],AL             ;Set number of entries per line
        MOV     [LINCNT],AL
        MOV     [FILECNT],0     ;Keep track of how many files found
        MOV     DX,OFFSET TRANGROUP:DIRBUF      ;Set Disk transfer address
        MOV     AH,SETDMA
        INT     21H             
        MOV     AH,SRCHFRST
SHOWDIR:
        MOV     DX,5CH          ;DX -> Unopened FCB
        INT     21H             ;Search for a file to match FCB
        INC     AL              ;FF = file not found
        JNZ     AGAIN           ;Either an error or we are finished
        JMP     CHKCNT
AGAIN:
        INC     [FILECNT]       ;Keep track of how many we find
        MOV     SI,OFFSET TRANGROUP:DIRBUF+1    ;SI -> information returned by sys call
        CALL    SHONAME
        TEST    BYTE PTR[BITS],1        ;/W set?
        JNZ     NEXENT          ;If so, no size, date, or time
        CALL    DISPSIZE        ;Print size of file
        CALL    TWOSPC
        MOV     AX,WORD PTR[DIRBUF+25]  ;Get date
        OR      AX,AX
        JZ      NEXENT          ;Skip if no date
        MOV     DX,AX
        MOV     CL,5
        SHR     AX,CL           ;Align month
        AND     AL,0FH
        MOV     BH,"0"-" "      ;Enable zero suppression
        CALL    OUT2
        MOV     AL,"-"
        CALL    OUT
        MOV     AL,DL
        AND     AL,1FH          ;Mask to day
        CALL    OUT2
        MOV     AL,"-"
        CALL    OUT
        MOV     AL,DH
        SHR     AL,1            ;Align year
        ADD     AX,80           ;Relative 1980
        CMP     AL,100
        JB      MILLENIUM
        SUB     AL,100
MILLENIUM:
        CALL    OUT2
        MOV     BX,WORD PTR[DIRBUF+23]  ;Get time
        OR      BX,BX           ;Time field present?
        JZ      NEXENT
        CALL    TWOSPC  
        SHR     BX,1
        SHR     BX,1
        SHR     BX,1
        SHR     BL,1
        SHR     BL,1            ;Hours in BH, minutes in BL
        MOV     AL,BH
        MOV     DH,"a"          ;Assume A.M.
        CMP     AL,12           ;In the afternoon?
        JB      MORN
        MOV     DH,"p"
        JE      MORN
        SUB     AL,12           ;Keep it to 12 hours or less
MORN:
        OR      AL,AL           ;Before 1 am?
        JNZ     SHOHOURS
        MOV     AL,12
SHOHOURS:
        MOV     BH,"0"-" "      ;Enable zero suppression
        CALL    OUT2
        MOV     AL,":"
        CALL    OUT
        MOV     AL,BL           ;Output minutes
        CALL    OUT2
        MOV     AL,DH           ;Get "a" or "p"
        CALL    OUT
NEXENT:
        DEC     [LINCNT]
        JNZ     SAMLIN
NEXLIN:
        MOV     AL,[LINLEN]
        MOV     [LINCNT],AL
        CALL    CRLF2
        TEST    BYTE PTR[BITS],2        ;/P switch present?
        JZ      SCROLL          ;If not, just continue
        DEC     BYTE PTR[FULLSCR]
        JNZ     SCROLL
        MOV     BYTE PTR[FULLSCR],LINPERPAG
        MOV     AH,PRINTBUF
        MOV     DX,OFFSET TRANGROUP:PAUSMES
        INT     33
        MOV     AX,0C08H        ;Wait for any character to be typed
        INT     21H
        CALL    CRLF2
SCROLL:
        MOV     AH,SRCHNXT
        JMP     SHOWDIR

SAMLIN:
        MOV     AL,9            ;Output a tab
        CALL    OUT
        JMP     SHORT SCROLL

SHONAME:
        MOV     CX,8
        CALL    OUTCNT
        CALL    ONESPC
        MOV     CX,3
OUTCNT:
        LODSB
        CALL    OUT
        LOOP    OUTCNT
        RET

TWOSPC:
        CALL    ONESPC
ONESPC:
        MOV     AL," "
        JMP     OUT

CRLF2:
        MOV     AL,13
        CALL    OUT
        MOV     AL,10
        JMP     OUT

DISPSIZE:
        MOV     SI,WORD PTR[DIRBUF+29]
        MOV     DI,WORD PTR[DIRBUF+31]
DISP32BITS:
;Prints the 32-bit number DI:SI on the console in decimal. Uses a total
;of 9 digit positions with leading blanks.
        XOR     AX,AX
        MOV     BX,AX
        MOV     BP,AX
        MOV     CX,32
CONVLP:
        SHL     SI,1
        RCL     DI,1
        XCHG    AX,BP
        CALL    CONVWRD
        XCHG    AX,BP
        XCHG    AX,BX
        CALL    CONVWRD
        XCHG    AX,BX
        ADC     AL,0
        LOOP    CONVLP
; Conversion complete. Print 9-digit number.
        MOV     CX,1810H        ;Allow leading zero blanking for 8 digits
        XCHG    DX,AX
        CALL    DIGIT
        XCHG    AX,BX
        CALL    OUTWORD
        XCHG    AX,BP
OUTWORD:
        PUSH    AX
        MOV     DL,AH
        CALL    OUTBYTE
        POP     DX
OUTBYTE:
        MOV     DH,DL
        SHR     DL,1
        SHR     DL,1
        SHR     DL,1
        SHR     DL,1
        CALL    DIGIT
        MOV     DL,DH
DIGIT:
        AND     DL,0FH
        JZ      BLANKZER
        MOV     CL,0
BLANKZER:
        DEC     CH
        AND     CL,CH
        OR      DL,30H
        SUB     DL,CL
        MOV     AH,OUTCH
        INT     21H
        RET

CONVWRD:
        ADC     AL,AL
        DAA
        XCHG    AL,AH
        ADC     AL,AL
        DAA
        XCHG    AL,AH
RET20:  RET

ERASE:
        MOV     CX,11
        MOV     SI,FCB+1
AMBSPEC:        
        LODSB
        CMP     AL,"?"
        JNZ     ALLFIL
        LOOP    AMBSPEC
ALLFIL: 
        CMP     CX,0
        JNZ     NOPRMPT
ASKAGN:         
        MOV     DX,OFFSET TRANGROUP:SUREMES     ;"Are you sure (Y/N)?"
        MOV     AH,PRINTBUF
        INT     21H
        MOV     AX,0C00H+INCHAR
        INT     21H
        AND     AL,5FH
        CMP     AL,"N"
        JZ      RET20
        CMP     AL,"Y"
        CALL    CRLF2
        JZ      NOPRMPT
        JMP     SHORT ASKAGN
NOPRMPT:
        MOV     AH,DELETE
        MOV     BX,OFFSET TRANGROUP:NOTFND
        CMP     BYTE PTR DS:[FCB+1]," " ;Check if parameter exists
        JMP     SHORT OPFILE
RENAME:
        MOV     AH,RENAM
        MOV     BX,OFFSET TRANGROUP:RENERR
        CMP     BYTE PTR DS:[FCB+16+1]," "  ;Check if parameter exists
OPFILE:
        MOV     DX,OFFSET TRANGROUP:MISNAM
        JZ      ERRJ            ;Error if missing parameter
        MOV     DX,FCB
        INT     21H
        INC     AL
        JNZ     RET20
        MOV     DX,BX
ERRJ:   JMP     ERROR

TYPEFIL:
        MOV     DS,[TPA]
        XOR     DX,DX
        MOV     AH,SETDMA
        INT     21H
        PUSH    CS
        POP     DS
        MOV     DX,FCB
        MOV     AH,OPEN
        INT     21H
        OR      AL,AL
        MOV     DX,OFFSET TRANGROUP:NOTFND
        JNZ     ERRJ
        XOR     AX,AX
        MOV     WORD PTR DS:[FCB+RR],AX ;Set RR field
        MOV     WORD PTR DS:[FCB+RR+2],AX
        INC     AX
        MOV     WORD PTR DS:[FCB+RECLEN],AX     ;Set record length
        MOV     ES,[TPA]
TYPELP:
        MOV     DX,FCB
        MOV     CX,[BYTCNT]
        MOV     AH,RDBLK
        INT     21H
        JCXZ    RET30
        XOR     SI,SI           ;Start at 0 in TPA
OUTLP:
        LODS    BYTE PTR ES:[SI]                ;In TPA segment
        CMP     AL,1AH
        JZ      RET30
        MOV     AH,OUTCH
        MOV     DL,AL
        INT     21H
        LOOP    OUTLP
        JMP     SHORT TYPELP

RET30:  RET                             ;Need a nearby RET

COPY:
        XOR     AX,AX
        MOV     [PLUS],AL               ;Will keep track of "+"s
        MOV     [FILECNT],AX
        MOV     SI,81H                  ;Point to input line
        CALL    SWITCH                  ;Skip over switches on command
        MOV     BP,AX
        MOV     DI,FCB
        CALL    PARSNAM                 ;Scan first source
        MOV     [PARM1],DL              ;Save ambiguous flag
        MOV     [SRCPT],SI              ;Save pointer to command line
;Parse each name to find destination and check for /V switch
SCANNAM:
        CALL    PARSE
        JNZ     SCANNAM
GETDEST:
        MOV     DI,OFFSET TRANGROUP:DEST
        MOV     BX,BP                   ;Remeber switches so far
        XOR     BP,BP                   ;Must have dest. swtiches alone
        CALL    PARSNAM
        MOV     [ARG2S],BP              ;Remember switches on destination
        JNZ     HAVDESTNAM              ;File name present?
        INC     DI                      ;Point to file name spot
        MOV     AL,"?"                  ;Substitute *.*
        MOV     CX,11
        REP     STOSB
HAVDESTNAM:
        OR      BX,BP                   ;BX = all switches combined
        AND     BL,VSWITCH              ;Verify requested?
        JZ      NOVER
        MOV     AX,46*100H+1            ;Set verify
        MOV     DL,0
        INT     33
NOVER:
        MOV     DI,OFFSET TRANGROUP:DESTNAME
        MOV     SI,OFFSET TRANGROUP:DEST+1
        MOV     BX,FCB+1
        CALL    BUILDNAME               ;See if we can make it unambiguous
        MOV     DI,OFFSET TRANGROUP:DESTNAME
        MOV     AL,"?"
        MOV     CX,11
        REPNE   SCASB                   ;Scan for "?" to see if ambiguous
        MOV     AL,1                    ;Flag if ambig.
        JZ      AMBIG
        DEC     AX                      ;AL=0 if unambig.
AMBIG:
        MOV     DL,AL
        MOV     AH,[PLUS]               ;1=found "+"
        XOR     AL,1                    ;0=ambig, 1=unambig destination
        AND     AL,[PARM1]              ;Source ambig. AND dest unambig.
        OR      AL,AH                   ;OR found "+" means concatenation
        MOV     [ASCII],AL              ;Concatenation implies ASCII mode
        MOV     [INEXACT],AL            ;ASCII implies inexact copy
        SHL     AL,1
        OR      AL,DL                   ;Combine multiple and concat flags
        MOV     [PARM2],AL
        MOV     AL,BYTE PTR[COMSW]
        CALL    SETASC                  ;Check /A,/B on command
        MOV     AL,BYTE PTR[ARG1S]
        CALL    SETASC                  ;Check for ASCII on first filename
        MOV     BYTE PTR[COMSW],AL              ;Save starting switch values
        MOV     AH,SRCHFRST
        CALL    SEARCH                  ;Search for first source name
MULTDEST:
        JZ      FIRSTSRC                ;Find a first source name?
        TEST    [PARM2],1               ;If multiple, we're done
        JNZ     ENDCOPY
        XOR     AX,AX
        MOV     [NXTADD],AX
        MOV     [CFLAG],AL              ;Flag nothing read yet
NEXTSNG:
        MOV     DI,FCB
        MOV     SI,[SRCPT]
        CALL    PARSESRC                ;Parse next file name into FCB
        MOV     [PARM1],DL              ;Remember if it's ambiguous
        MOV     [SRCPT],SI
        JZ      SNGCLOS
        MOV     AH,SRCHFRST
        CALL    SEARCH                  ;Search for new file name
        JNZ     NEXTSNG                 ;If none, skip it and move to next name
READSNG:
        CALL    CHECKREAD
SNGLOOP:
        CALL    SEARCHNEXT              ;See if any more of this name
        JZ      READSNG
        JMP     SHORT NEXTSNG

SNGCLOS:
        CALL    CLOSEFIL
ENDCOPY:
        MOV     SI,[FILECNT]
        XOR     DI,DI
        CALL    DISP32BITS
        MOV     DX,OFFSET TRANGROUP:COPIED
        MOV     AH,PRINTBUF
        INT     21H
        JMP     COMMAND                 ;Stack could be messed up

FIRSTSRC:
        MOV     SI,OFFSET TRANGROUP:DIRBUF+1
        MOV     DI,OFFSET TRANGROUP:SOURCE
        MOV     CX,11
        REP     MOVSB                   ;Copy first source name to SOURCE
        MOV     SI,OFFSET TRANGROUP:DESTNAME
        MOV     DI,OFFSET TRANGROUP:DEST+1
        MOV     BX,OFFSET TRANGROUP:SOURCE
        CALL    BUILDNAME               ;Build destination name
        XOR     AX,AX
        MOV     [NXTADD],AX
        MOV     [CFLAG],AL
        MOV     [APPEND],AL
        MOV     [NOWRITE],AL
        TEST    [PARM2],1               ;Multiple destinations?
        JZ      NOPRT
        MOV     SI,OFFSET TRANGROUP:DIRBUF+1
        CALL    SHONAME                 ;If so, show first source
        CALL    CRLF2
NOPRT:
        CALL    COMPNAME                ;Source and dest. the same?
        JNZ     DOREAD                  ;If not, read source in
        TEST    [PARM2],2               ;Concatenation?
        MOV     DX,OFFSET TRANGROUP:OVERWR
        JZ      COPERRJ                 ;If not, overwrite error
        MOV     [APPEND],1              ;Set physical append
        MOV     AH,OPEN
        MOV     DX,OFFSET TRANGROUP:DEST
        INT     33                      ;Open (existing) destination
        CMP     [ASCII],0               ;ASCII flag set?
        JZ      BINARYAPP
;ASCII append. Must find logical EOF, then seek there with dest. FCB
        MOV     [NOWRITE],1
        CALL    READIN                  ;Find EOF
        CALL    FLSHFIL                 ;Seek there
        MOV     [NOWRITE],0
        CALL    FLSHFIL                 ;Truncate file
        JMP     SHORT SNGLCHK

SNGLOOPJ:JMP    SNGLOOP

COPERRJ:JMP     COPERR

BINARYAPP:
        MOV     WORD PTR[DEST+RECLEN],1         ;Set record length to 1
        MOV     SI,OFFSET TRANGROUP:DEST+16             ;Point to file size
        MOV     DI,OFFSET TRANGROUP:DEST+RR
        MOVSW
        MOVSW                           ;Seek to end of file
        MOV     [CFLAG],1
        JMP     SHORT SNGLCHK
DOREAD:
        CALL    READIN
SNGLCHK:
        TEST    [PARM2],1               ;Single or multiple destinations?
        JZ      SNGLOOPJ
        MOV     SI,[SRCPT]
MULTAPP:
        CALL    PARSE
        JZ      MULTCLOS
        PUSH    SI
        MOV     SI,OFFSET TRANGROUP:DIRBUF+1
        MOV     DI,SI
        MOV     BX,OFFSET TRANGROUP:SOURCE
        CALL    BUILDNAME
        CALL    CHECKREAD
        POP     SI
        JMP     SHORT MULTAPP
MULTCLOS:
        CALL    CLOSEFIL
        MOV     AL,BYTE PTR[COMSW]
        MOV     [ASCII],AL              ;Restore ASCII flag
        CALL    SEARCHNEXT
        JMP     MULTDEST

PARSE:
        MOV     DI,OFFSET TRANGROUP:DIRBUF
PARSESRC:
        CALL    SCANOFF
        CMP     AL,"+"
        JNZ     RETZF
        MOV     [PLUS],1                ;Keep track of "+" signs
        INC     SI                      ;Skip over it
PARSNAM:
        MOV     AX,2901H
        INT     33                      ;Parse file name
        CMP     AL,-1                   ;Illegal?
        MOV     DX,OFFSET TRANGROUP:BADDRV
        JZ      COPERRJ
        XCHG    AX,DX                   ;Save parse flag in DL
        MOV     AL,BYTE PTR[DI]         ;Get drive number
        OR      AL,AL                   ;Is it default?
        JNZ     PARSW
        MOV     AL,[CURDRV]             ;Substitute actual drive
        INC     AX
        MOV     BYTE PTR[DI],AL
PARSW:
        PUSH    BX
        PUSH    DI
        CALL    SWITCH                  ;Process switches
        OR      BP,AX                   ;Combine all switches
        CALL    SETASC                  ;Check for /A or /B
        POP     DI
        POP     BX
        CMP     BYTE PTR[DI+1]," "              ;Did we even get a file name?
        RET

RETZF:
        XOR     AX,AX
RET35:  RET

SEARCHNEXT:
        MOV     AL,[PARM1]              ;Is name ambiguous?
        DEC     AL
        JNZ     RET35                   ;Don't perform search if not
        MOV     AH,SRCHNXT
SEARCH:
        PUSH    AX
        MOV     AH,SETDMA
        MOV     DX,OFFSET TRANGROUP:DIRBUF
        INT     33                      ;Put result of search in DIRBUF
        POP     AX                      ;Restore search first/next command
        MOV     DX,FCB
        INT     33                      ;Do the search
        OR      AL,AL
        RET

SETASC:
;Given switch vector in AX, 
;       Set ASCII switch if /A is set
;       Clear ASCII switch if /B is set
;       Leave ASCII unchanged if neither or both are set
; Also sets INEXACT if ASCII is ever set. AL = ASCII on exit, flags set
        AND     AL,ASWITCH+BSWITCH
        JPE     LOADSW                  ;PE means both or neither are set
        AND     AL,ASWITCH
        MOV     [ASCII],AL
        OR      [INEXACT],AL
LOADSW:
        MOV     AL,[ASCII]
        OR      AL,AL
        RET

BUILDNAME:
; [SI] = Ambiguous input file name
; [BX] = Source of replacement characters
; [DI] = Destination
; File name is copied from [SI] to [DI]. If "?"s are encountered,
; they are replaced with the character in the same position at [BX].
        MOV     CX,11
BUILDNAM:
        LODSB
        CMP     AL,"?"
        JNZ     NOTAMBIG
        MOV     AL,BYTE PTR[BX]
NOTAMBIG:
        STOSB
        INC     BX
        LOOP    BUILDNAM
        RET

COMPNAME:
        MOV     SI,OFFSET TRANGROUP:DEST
        MOV     DI,OFFSET TRANGROUP:DIRBUF
        MOV     CX,6
        REPE    CMPSW
        RET

CHECKREAD:
;Read file in (with READIN) if not identical to destination
        CALL    COMPNAME                ;See if source and destination the same
        JNZ     READIN
        CMP     [APPEND],0              ;If physical append, it's OK
        JNZ     RET40
        MOV     DX,OFFSET TRANGROUP:LOSTERR             ;Tell him he's not going to get it
        MOV     AH,PRINTBUF
        INT     33
RET40:  RET

READIN:
;Open source file and read it in. If memory fills up, flush it out to
;destination and keep reading. If /A switch set, chop file at first ^Z.
; Inputs/Outputs:
;       [NXTADD] has current pointer in buffer
;       [CFLAG] <>0 if destination has been created

        MOV     DX,OFFSET TRANGROUP:DIRBUF
        MOV     AH,OPEN
        INT     21H
        OR      AL,AL                   ;Successful open?
        JNZ     RET40                   ;If not, just ignore it
        XOR     AX,AX
        MOV     WORD PTR[DIRBUF+RR],AX
        MOV     WORD PTR[DIRBUF+RR+2],AX
        INC     AX
        MOV     WORD PTR[DIRBUF+RECLEN],AX
COPYLP:
        MOV     DX,[NXTADD]
        MOV     AH,SETDMA
        PUSH    DS
        MOV     DS,[TPA]
        INT     33
        POP     DS
        MOV     CX,[BYTCNT]
        SUB     CX,DX                   ;Compute available space
        MOV     DX,OFFSET TRANGROUP:DIRBUF
        MOV     AH,RDBLK                ;Read in source file
        INT     21H
        JCXZ    RET40
        CMP     [ASCII],0
        JZ      BINREAD
        MOV     DX,CX
        MOV     DI,[NXTADD]
        MOV     AL,1AH
        PUSH    ES
        MOV     ES,[TPA]
        REPNE   SCASB                   ;Scan for EOF
        POP     ES
        JNZ     USEALL
        INC     CX
USEALL:
        SUB     DX,CX
        MOV     CX,DX
BINREAD:
        ADD     CX,[NXTADD]
        MOV     [NXTADD],CX
        CMP     CX,[BYTCNT]             ;Is buffer full?
        JB      RET40                   ;If not, we must have found EOF
        CALL    FLSHFIL
        JMP     SHORT COPYLP

CLOSEFIL:
        MOV     AX,[NXTADD]
        MOV     BX,AX
        OR      AL,AH                   ;See if any data is loaded
        OR      AL,[CFLAG]              ;   or file was created
        JZ      RET50                   ;Don't close or count if not created
        MOV     AL,BYTE PTR[ARG2S]
        CALL    SETASC                  ;Check for /B or /A on destination
        JZ      BINCLOS
        CMP     BX,[BYTCNT]             ;Is memory full?
        JNZ     PUTZ
        CALL    FLSHFIL                 ;Empty it to make room for 1 lousy byte
        XOR     BX,BX
PUTZ:
        PUSH    DS
        MOV     DS,[TPA]
        MOV     WORD PTR[BX],1AH                ;Add End-of-file mark (Ctrl-Z)
        POP     DS
        INC     [NXTADD]
BINCLOS:
        CALL    FLSHFIL
        CMP     [INEXACT],0             ;Copy not exact?
        JNZ     NODATE                  ;If so, don't copy date & time
        MOV     SI,OFFSET TRANGROUP:DIRBUF+OFFDATE
        MOV     DI,OFFSET TRANGROUP:DEST+OFFDATE        ;Make date & time same as original
        MOVSW                           ;Copy date
        MOVSW                           ;Copy time
NODATE:
        MOV     DX,OFFSET TRANGROUP:DEST
        MOV     AH,CLOSE
        INT     21H
        INC     [FILECNT]
RET50:  RET

FLSHFIL:
;Write out any data remaining in memory.
; Inputs:
;       [NXTADD] = No. of bytes to write
;       [CFLAG] <>0 if file has been created
; Outputs:
;       [NXTADD] = 0

        MOV     AL,1
        XCHG    [CFLAG],AL
        OR      AL,AL
        JNZ     EXISTS
        CMP     [NOWRITE],0
        JNZ     SKPMAK                  ;Don't actually create if NOWRITE set
        MOV     DX,OFFSET TRANGROUP:DEST
        MOV     AH,MAKE
        INT     21H
        MOV     DX,OFFSET TRANGROUP:FULDIR
        OR      AL,AL
        JNZ     COPERR
SKPMAK:
        XOR     AX,AX
        MOV     WORD PTR[DEST+RR],AX
        MOV     WORD PTR[DEST+RR+2],AX
        INC     AX
        MOV     WORD PTR[DEST+RECLEN],AX
EXISTS:
        XOR     CX,CX
        XCHG    CX,[NXTADD]
        CMP     [NOWRITE],0             ;If NOWRITE set, just seek CX bytes
        JNZ     SEEKEND
        XOR     DX,DX
        PUSH    DS
        MOV     DS,[TPA]
        MOV     AH,SETDMA
        INT     33
        POP     DS
        MOV     DX,OFFSET TRANGROUP:DEST
        MOV     AH,WRBLK
        INT     21H
        OR      AL,AL
        JZ      RET60
        MOV     DX,OFFSET TRANGROUP:DEST
        MOV     AH,CLOSE
        INT     21H
        MOV     AH,DELETE
        INT     33
        MOV     DX,OFFSET TRANGROUP:NOSPACE
COPERR:
        MOV     AH,9
        INT     21H
        JMP     ENDCOPY

SEEKEND:
        ADD     WORD PTR[DEST+RR],CX
        ADC     WORD PTR[DEST+RR+2],0           ;Propagate carry
RET60:  RET

GETBATBYT:
;Get one byte from the batch file and return it in AL. End-of-file
;returns <CR> and ends batch mode. DS must be set to resident segment.
;AH, CX, DX destroyed.
ASSUME  DS:RESGROUP
        MOV     DX,OFFSET RESGROUP:BATFCB
        MOV     AH,RDBLK
        MOV     CX,1
        INT     33              ;Get one more byte from batch file
        JCXZ    BATEOF
        MOV     AL,[BATBYT]
        CMP     AL,1AH
        JNZ     RET70
BATEOF:
        MOV     AL,0DH          ;If end-of-file, then end of line
        MOV     [BATCH],0       ;And turn off batch mode
RET70:  RET
ASSUME  DS:TRANGROUP

SCANOFF:
        LODSB
        CALL    DELIM
        JZ      SCANOFF
        DEC     SI              ;Point to first non-delimiter
        RET

DELIM:
        CMP     AL," "
        JZ      RET80
        CMP     AL,"="
        JZ      RET80
        CMP     AL,","
        JZ      RET80
        CMP     AL,9            ;Check for TAB character
RET80:  RET

PAUSE:
        MOV     DX,OFFSET TRANGROUP:PAUSMES
        MOV     AH,PRINTBUF
        INT     33
        MOV     AX,0C00H+INCHAR ;Get character with KB buffer flush
        INT     33
RET90:  RET

;Date and time are set during initialization and use
;this routines since they need to do a long return

DATINIT:
        PUSH    ES
        PUSH    DS              ;Going to use the previous stack
        MOV     AX,CS           ;Set up the appropriate segment registers
        MOV     ES,AX
        MOV     DS,AX
        MOV     WORD PTR DS:[81H],13    ;Want to prompt for date during initialization
        CALL    DATE
        CALL    TIME
        POP     DS
        POP     ES
YYY     PROC    FAR
        RET
YYY     ENDP

; DATE - Gets and sets the time

DATE:
        MOV     SI,81H          ;Accepting argument for date inline
        CALL    SCANOFF
        CMP     AL,13
        JZ      PRMTDAT
        MOV     BX,2F00H+"-"    ;"/-"
        CALL    INLINE
        JMP     COMDAT

PRMTDAT:
        MOV     DX,OFFSET TRANGROUP:CURDAT
        MOV     AH,PRINTBUF
        INT     33              ;Print "Current date is "
        MOV     AH,GETDATE
        INT     33              ;Get date in CX:DX
        CBW
        MOV     SI,AX
        SHL     SI,1
        ADD     SI,AX           ;SI=AX*3
        ADD     SI,OFFSET TRANGROUP:WEEKTAB
        MOV     BX,CX
        MOV     CX,3
        CALL    OUTCNT
        MOV     AL," "
        CALL    OUT
        MOV     AX,BX
        MOV     CX,DX
        MOV     DL,100
        DIV     DL
        XCHG    AL,AH
        XCHG    AX,DX
        MOV     BL,"-"
        CALL    SHOW
GETDAT:
        MOV     DX,OFFSET TRANGROUP:NEWDAT
        MOV     BX,2F00H+"-"    ;"/-" in BX
        CALL    GETBUF
COMDAT: JZ      RET90
        JC      DATERR
        LODSB   
        CMP     AL,BL
        JZ      SEPGD
        CMP     AL,BH
        JNZ     DATERR
SEPGD:  CALL    GETNUM
        JC      DATERR
        MOV     CX,1900
        CMP     BYTE PTR[SI],13
        JZ      BIAS
        MOV     AL,100
        MUL     AH
        MOV     CX,AX
        CALL    GETNUM
        JC      DATERR
BIAS:
        MOV     AL,AH
        MOV     AH,0
        ADD     CX,AX
        LODSB
        CMP     AL,13
        JNZ     DATERR
        MOV     AH,SETDATE
        INT     33
        OR      AL,AL
        JNZ     DATERR
        JMP     RET90
DATERR:
        MOV     DX,OFFSET TRANGROUP:BADDAT
        MOV     AH,PRINTBUF
        INT     33
        JMP     GETDAT

; TIME gets and sets the time

TIME:
        MOV     SI,81H                  ;Accepting argument for time inline
        CALL    SCANOFF
        CMP     AL,13
        JZ      PRMTTIM
        MOV     BX,3A00H+":"
        CALL    INLINE
        JMP     COMTIM

PRMTTIM:
        MOV     DX,OFFSET TRANGROUP:CURTIM
        MOV     AH,PRINTBUF
        INT     33              ;Print "Current time is "
        MOV     AH,GETTIME
        INT     33              ;Get time in CX:DX
        MOV     BL,":"
        CALL    SHOW
GETTIM:
        XOR     CX,CX           ;Initialize hours and minutes to zero
        MOV     DX,OFFSET TRANGROUP:NEWTIM
        MOV     BX,3A00H+":"
        CALL    GETBUF
COMTIM: JZ      RET100          ;If no time present, don't change it
        JC      TIMERR
        MOV     CX,DX
        XOR     DX,DX
        LODSB
        CMP     AL,13
        JZ      SAVTIM
        CMP     AL,BL
        JNZ     TIMERR
        MOV     BL,"."
        CALL    GETNUM
        JC      TIMERR
        MOV     DH,AH           ;Position seconds
        LODSB
        CMP     AL,13
        JZ      SAVTIM
        CMP     AL,BL
        JNZ     TIMERR  
        CALL    GETNUM
        JC      TIMERR
        MOV     DL,AH
        LODSB
        CMP     AL,13
        JNZ     TIMERR
SAVTIM:
        MOV     AH,SETTIME
        INT     33
        OR      AL,AL
        JZ      RET100          ;Error in time?
TIMERR:
        MOV     DX,OFFSET TRANGROUP:BADTIM
        MOV     AH,PRINTBUF
        INT     33              ;Print error message
        JMP     GETTIM          ;Try again

GETBUF:
        MOV     AH,PRINTBUF
        INT     33              ;Print "Enter new date: "
        MOV     AH,INBUF
        MOV     DX,OFFSET TRANGROUP:COMBUF
        INT     33              ;Get input line
        CALL    CRLF2
        MOV     SI,OFFSET TRANGROUP:COMBUF+2
        CMP     BYTE PTR[SI],13 ;Check if new date entered
        JZ      RET100
INLINE:
        CALL    GETNUM          ;Get one or two digit number
        JC      RET100
        MOV     DH,AH           ;Put in position
        LODSB
        CMP     AL,BL
        JZ      NEXT
        CMP     BL,":"          ;Is it a date seperator?
        JNZ     DATESEP
        DEC     SI
        MOV     DL,0
RET100: RET                     ;Time may have only an hour specified
DATESEP:
        CMP     AL,BH
        STC
        JNZ     RET100
NEXT:   CALL    GETNUM
        MOV     DL,AH           ;Put in position
        RET

GETNUM:
        CALL    INDIG
        JC      RET100
        MOV     AH,AL           ;Save first digit
        CALL    INDIG           ;Another digit?
        JC      OKRET
        AAD                     ;Convert unpacked BCD to decimal
        MOV     AH,AL
OKRET:
        OR      AL,1
RET110: RET

INDIG:
        MOV     AL,BYTE PTR[SI]
        SUB     AL,"0"
        JC      RET110
        CMP     AL,10
        CMC
        JC      RET110
        INC     SI
        RET

SHOW:
        MOV     AL,CH
        MOV     BH,"0"-" "      ;Enable leading zero suppression
        CALL    OUT2
        MOV     AL,BL
        CALL    OUT
        MOV     AL,CL
        CALL    OUT2
        MOV     AL,BL
        CALL    OUT
        MOV     AL,DH
        CALL    OUT2
        CMP     BL,":"          ;Are we outputting time?
        JNZ     SKIPIT
        MOV     AL,"."
        CALL    OUT
SKIPIT: MOV     AL,DL
OUT2:   ;Output binary number as two ASCII digits
        AAM                     ;Convert binary to unpacked BCD
        XCHG    AL,AH
        OR      AX,3030H        ;Add "0" bias to both digits
        CMP     AL,"0"          ;Is MSD zero?
        JNZ     NOSUP
        SUB     AL,BH           ;Suppress leading zero if enabled
NOSUP:
        MOV     BH,0            ;Disable zero suppression
        CALL    OUT
        MOV     AL,AH
OUT:
;Print char in AL without affecting registers
        XCHG    AX,DX
        PUSH    AX
        MOV     AH,OUTCH
        INT     33
        POP     AX
        XCHG    AX,DX
        RET

EXELOAD:
        MOV     AX,CS
        ADD     AX,LOADSEG
        MOV     [EXEEND],AX     ;Store in EXEEND
        MOV     DX,OFFSET TRANGROUP:RUNVAR      ;Read header in here
        MOV     AH,SETDMA
        INT     33
        MOV     CX,RUNVARSIZ    ;Amount of header info we need
        MOV     DX,OFFSET TRANGROUP:EXEFCB
        MOV     AH,RDBLK
        INT     33              ;Read in header
        OR      AL,AL
        JNZ     BADEXE          ;Must not reach EOF
        MOV     AX,[HEADSIZ]    ;Size of header in paragraphs
;Convert header size to 512-byte pages by multiplying by 32 & rounding up
        ADD     AX,31           ;Round up first
        MOV     CL,5
        SHR     AX,CL           ;Multiply by 32
        MOV     [EXEFCB+RR],AX  ;Position in file of program
        MOV     WORD PTR[EXEFCB+RECLEN],512 ;Set record size
        ADD     BX,10H          ;First paragraph above parameter area
        MOV     DX,[PAGES]      ;Total size of file in 512-byte pages
        SUB     DX,AX           ;Size of program in pages
        MOV     [PSIZE],DX
        SHL     DX,CL           ;Convert pages back to paragraphs
        MOV     AX,DX
        ADD     DX,BX           ;Size + start = minimum memory (paragr.)
        MOV     CX,[EXEEND]     ;Get memory size in paragraphs
        CMP     DX,CX           ;Enough memory?
        JA      SHRTERR
        MOV     DX,[INITSP]
        ADD     DX,15
        SHR     DX,1
        SHR     DX,1
        SHR     DX,1
        SHR     DX,1
        ADD     DX,[INITSS]
        ADD     DX,BX           ;Adjusted value of SP
        CMP     DX,CX           ;Is it valid?
        JA      SHRTERR
        CMP     [LOADLOW],-1    ;Load low or high?
        JZ      LOAD            ;If low, load at segment BX
        SUB     CX,AX           ;Memory size - program size = load addr.
        MOV     BX,CX
LOAD:
        MOV     BP,BX           ;Save load segment
LOAD1:
LOADSEG EQU     (LOAD1-ZERO)/16
        PUSH    DS
        MOV     DS,BX
        XOR     DX,DX           ;Address 0 in segment
        MOV     AH,SETDMA
        INT     33              ;Set load address
        POP     DS
        MOV     CX,[PSIZE]      ;Number of records to read
        MOV     DX,OFFSET TRANGROUP:EXEFCB
        MOV     AH,RDBLK
        INT     33              ;Read in up to 64K
        SUB     [PSIZE],CX      ;Decrement count by amount read
        JZ      HAVEXE          ;Did we get it all?
        TEST    AL,1            ;Check return code if not
        JNZ     BADEXE          ;Must be zero if more to come
        ADD     BX,1000H-20H    ;Bump data segment 64K minus one record
        JMP     SHORT LOAD1             ;Get next 64K block

BADEXE:
        MOV     DX,OFFSET TRANGROUP:EXEBAD
        JMP     ERROR

SHRTERR:
        MOV     DX,OFFSET TRANGROUP:TOOBIG
        JMP     ERROR

HAVEXE:
        MOV     AX,[RELTAB]     ;Get position of table
        MOV     [EXEFCB+RR],AX  ;Set in random record field
        MOV     WORD PTR[EXEFCB+RECLEN],1  ;Set one-byte record
        MOV     DX,OFFSET TRANGROUP:RELPT       ;4-byte buffer for relocation address
        MOV     AH,SETDMA
        INT     33
        CMP     [RELCNT],0
        JZ      NOREL
RELOC:
        MOV     AH,RDBLK
        MOV     DX,OFFSET TRANGROUP:EXEFCB
        MOV     CX,4
        INT     33              ;Read in one relocation pointer
        OR      AL,AL           ;Check return code
        JNZ     BADEXE
        MOV     DI,[RELPT]      ;Get offset of relocation pointer
        MOV     AX,[RELSEG]     ;Get segment
        ADD     AX,BP           ;Bias segment with actual load segment
        MOV     ES,AX
        ADD     WORD PTR ES:[DI],BP             ;Relocate
        DEC     [RELCNT]        ;Count off
        JNZ     RELOC
;Set up exit conditions
NOREL:
        MOV     AX,[INITSS]
        ADD     AX,BP
        CLI
        MOV     SS,AX           ;Initialize SS
        MOV     SP,[INITSP]
        STI
        ADD     [INITCS],BP
        MOV     AX,[TPA]        ;Get pointer to parameter area
        MOV     CX,[BYTCNT]     ;Size of TPA segment
        MOV     ES,AX
        MOV     DS,AX           ;Set segment registers to point to it
        CALL    SETUP
        JMP     DWORD PTR CS:[INITIP]   ;Long jump to program

SETUP:
        AND     CL,0F0H         ;Adjust to even paragraph boundary
        MOV     AX,WORD PTR DS:[6]              ;Get current memory size
        SUB     AX,CX           ;Find out how much we're changing it
        MOV     WORD PTR DS:[6],CX
        MOV     CL,4
        SAR     AX,CL           ;Convert to a segment address
        ADD     WORD PTR DS:[8],AX              ;Adjust long jump to go to same place
        MOV     DX,80H
        MOV     AH,SETDMA
        INT     33              ;Set default disk transfer address
        MOV     AX,WORD PTR CS:[PARM1]  ;Pass on info about FCBs
        XOR     CX,CX
        MOV     DX,CX           ;Assume no batch file
ASSUME  CS:RESGROUP
        TEST    CS:[BATCH],-1   ;Batch file in progress?
ASSUME  CS:TRANGROUP
        JZ      RET120          ;If not, all set up
        MOV     CX,CS:[RESSEG]
        MOV     DX,OFFSET RESGROUP:BATFCB       ;CX:DX points to batch FCB
RET120: RET
TRANCODESIZE    EQU     $-ZERO
TRANCODE        ENDS
COMLEN  EQU     TRANDATASIZE+TRANCODESIZE-102H          ;End of COMMAND load. ZERO Needed to make COMLEN absolute
TRNLEN  EQU     (PRETRLEN+TRANCODESIZE+TRANDATASIZE+15)/16              ;Length of transient in paragraphs
        END     PROGSTART
