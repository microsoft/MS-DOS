TITLE   COMMAND Transient Initialized DATA

        INCLUDE COMSW.ASM
.xlist
.xcref
        INCLUDE COMSEG.ASM
.list
.cref

        INCLUDE IFEQU.ASM

TRANCODE        SEGMENT PUBLIC
        EXTRN   PRINT_DATE:NEAR,PRINT_TIME:NEAR,PRINT_DEFAULT_DIRECTORY:NEAR
        EXTRN   PRINT_DRIVE:NEAR,PRINT_VERSION:NEAR,PRINT_G:NEAR
        EXTRN   PRINT_L:NEAR,PRINT_B:NEAR,CRLF2:NEAR,OUT:NEAR,PRINT_ESC:NEAR
        EXTRN   PRINT_BACK:NEAR,PRINT_EQ:NEAR

        EXTRN   IFNOT:NEAR,IFERLEV:NEAR,IFEXISTS:NEAR

        EXTRN   CATALOG:NEAR,CRENAME:NEAR,ERASE:NEAR,TYPEFIL:NEAR
        EXTRN   TCOMMAND:NEAR,COPY:NEAR,PAUSE:NEAR,DATE:NEAR,CTIME:NEAR
        EXTRN   VERSION:NEAR,VOLUME:NEAR,$CHDIR:NEAR,$MKDIR:NEAR,$RMDIR:NEAR
        EXTRN   CNTRLC:NEAR,VERIFY:NEAR,ADD_NAME_TO_ENVIRONMENT:NEAR
        EXTRN   ADD_PROMPT:NEAR,PATH:NEAR,$EXIT:NEAR,CTTY:NEAR,ECHO:NEAR
        EXTRN   GOTO:NEAR,SHIFT:NEAR,$IF:NEAR,$FOR:NEAR,CLS:NEAR
TRANCODE        ENDS

; Data for transient portion

TRANDATA        SEGMENT PUBLIC BYTE

        PUBLIC  BADBAT,NEEDBAT,BADNAM,RENERR,NOTFND,NOSPACE,ENVERR,FULDIR
        PUBLIC  OVERWR,LOSTERR,DIRMES_PRE,DIRMES_POST,BADDRV,PAUSEMES,BADSWT
        PUBLIC  COPIED_PRE,COPIED_POST,BYTMES_PRE,BYTMES_POST
        PUBLIC  WEEKTAB,BADDAT,NEWDAT,BADTIM,NEWTIM,SUREMES,CURDAT_MID
        PUBLIC  CURDAT_PRE,CURDAT_POST,CURTIM_PRE,CURTIM_POST,VERMES_POST
        PUBLIC  DMES,VERMES_PRE,VOLMES,GOTVOL,NOVOL,BADCD,BADMKD,BADRMD
        PUBLIC  BAD_ON_OFF,NULPATH,PATH_TEXT,PROMPT_TEXT,BADPMES
        PUBLIC  BADDEV,BADLAB,SYNTMES,FORNESTMES,PIPEEMES,INBDEV,OFFMES
        PUBLIC  ONMES,CTRLCMES,VERIMES,ECHOMES,BADCPMES,BADARGS,DEVWMES
        PUBLIC  ACRLF,DBACK,CLSSTRING,PROMPT_TABLE,IFTAB,COMTAB
        PUBLIC  TRANDATAEND,DIRHEAD_PRE,DIRHEAD_POST

        ORG     0
ZERO    =       $
BADBAT  DB      13,10,"Batch file missing",13,10,"$"
NEEDBAT DB      13,10,"Insert disk with batch file"
        DB      13,10,"and press any key when ready",13,10,"$"
BADNAM  DB      "Bad command or file name",13,10,"$"
RENERR  DB      "Duplicate file name or "
NOTFND  DB      "File not found",13,10,"$"
NOSPACE DB      "Insufficient disk space",13,10,"$"
ENVERR  DB      "Out of environment space",13,10,"$"
FULDIR  DB      "File creation error",13,10,"$"
OVERWR  DB      "File cannot be copied onto itself",13,10,"$"
LOSTERR DB      "Content of destination lost before copy",13,10,"$"

;"COPIED_PRE<# files copied>COPIED_POST"
COPIED_POST  DB      " File(s) copied",13,10ŠCOPIED_PRE   DB      "$"

;"DIRMES_PRE<# files in dir>DIRMES_POST"
DIRMES_POST  DB      " File(s) "
DIRMES_PRE   DB      "$"

;"BYTMES_PRE<# free bytes>BYTMES_POST"
BYTMES_POST  DB      " bytes free",13,10
BYTMES_PRE   DB      "$"

BADDRV  DB      "Invalid drive specification",13,10,"$"
PAUSEMES DB      "Strike a key when ready . . . $"
BADSWT  DB      "Invalid parameter",13,10,"$"
WEEKTAB DB      "SunMonTueWedThuFriSat"
BADDAT  DB      13,10,"Invalid date$"

;"CURDAT_PRE<day of week>CURDAT_MID<MO,DAY,YR>CURDAT_POST"
;Note: CURDAT_MID also appears in the date printed via PROMPT command
CURDAT_PRE   DB      "Current date is "
CURDAT_MID   LABEL   BYTE
CURDAT_POST  DB      "$"

NEWDAT  DB      13,10,"Enter new date: $"
BADTIM  DB      13,10,"Invalid time$"

;"CURTIM_PRE<HR,MIN,SEC,HSEC>CURTIM_POST"
CURTIM_PRE   DB      "Current time is "
CURTIM_POST  DB      "$"

NEWTIM  DB      13,10,"Enter new time: $"
SUREMES DB      "Are you sure (Y/N)? $"
DMES    DB      " <DIR>   $"

;"VERMES_PRE<version #>VERMES_POST"
        IF      IBMVER
VERMES_PRE  DB      "TeleVideo Personal Computer DOS Version "
        ENDIF
        IF      MSVER
VERMES_PRE  DB      "MS-DOS Version "
        ENDIF
VERMES_POST DB      "$"

VOLMES  DB      " Volume in drive $"
GOTVOL  DB      " is $"
NOVOL   DB      " has no label$"

BADCD   DB      "Invalid directory",13,10,"$"
BADMKD  DB      "Unable to create directory",13,10,"$"
BADRMD  DB      "Invalid path, not directory,",13,10
        DB      "or directory not empty",13,10,"$"
BAD_ON_OFF DB   "Must specify ON or OFF"        ;Note Run over to next message

;"DIRHEAD_PRE<path of dir>DIRHEAD_POST"
DIRHEAD_POST DB      13,10,"$"
DIRHEAD_PRE  DB      " Directory of  $"Š
NULPATH DB      "No Path $"
PATH_TEXT    DB "PATH="
PROMPT_TEXT  DB "PROMPT="
BADPMES DB      "Invalid drive in search path",13,10,"$"
BADDEV  DB      "Invalid device",13,10,"$"
BADLAB  DB      "Label not found",13,10,"$"
SYNTMES DB      "Syntax error",13,10,"$"
FORNESTMES DB   13,"FOR cannot be nested",13,10,"$"
PIPEEMES DB     "Intermediate file error during pipe",13,10,"$"
INBDEV  DB      "Cannot do binary reads from a device",13,10,"$"
OFFMES  DB      "off",13,10,"$"
ONMES   DB      "on",13,10,"$"
CTRLCMES DB     "BREAK is $"
VERIMES DB      "VERIFY is $"
ECHOMES DB      "ECHO is $"
BADCPMES DB     "Invalid path or file name",13,10,"$"
BADARGS DB      "Invalid number of parameters",13,10,"$"
DEVWMES DB      "Error writing to device"
ACRLF   DB      13,10,"$"
DBACK   DB      8," ",8,0               ; DESTRUCTIVE BACK SPACE

CLSSTRING DB    4,01BH,"[2J"            ; ANSI Clear screen

PROMPT_TABLE LABEL BYTE
        DB      "D"
        DW      OFFSET TRANGROUP:PRINT_DATE
        DB      "T"
        DW      OFFSET TRANGROUP:PRINT_TIME
        DB      "P"
        DW      OFFSET TRANGROUP:PRINT_DEFAULT_DIRECTORY
        DB      "N"
        DW      OFFSET TRANGROUP:PRINT_DRIVE
        DB      "V"
        DW      OFFSET TRANGROUP:PRINT_VERSION
        DB      "G"
        DW      OFFSET TRANGROUP:PRINT_G
        DB      "L"
        DW      OFFSET TRANGROUP:PRINT_L
        DB      "B"
        DW      OFFSET TRANGROUP:PRINT_B
        DB      "_"
        DW      OFFSET TRANGROUP:CRLF2
        DB      "$"
        DW      OFFSET TRANGROUP:OUT
        DB      "E"
        DW      OFFSET TRANGROUP:PRINT_ESC
        DB      "H"
        DW      OFFSET TRANGROUP:PRINT_BACK
        DB      "Q"
        DW      OFFSET TRANGROUP:PRINT_EQ
        DB      0                       ; NUL TERMINATED

IFTAB   LABEL   BYTE                    ; Table of IF conditionals
        DB      3,"NOT"                 ; First byte is countŠ        DW      OFFSET TRANGROUP:IFNOT
        DB      10,"ERRORLEVEL"
        DW      OFFSET TRANGROUP:IFERLEV
        DB      5,"EXIST"
        DW      OFFSET TRANGROUP:IFEXISTS
        DB      0

COMTAB  DB      4,"DIR",1               ; Table for internal command names
        DW      OFFSET TRANGROUP:CATALOG
        DB      7,"RENAME",1
        DW      OFFSET TRANGROUP:CRENAME
        DB      4,"REN",1
        DW      OFFSET TRANGROUP:CRENAME
        DB      6,"ERASE",1
        DW      OFFSET TRANGROUP:ERASE
        DB      4,"DEL",1
        DW      OFFSET TRANGROUP:ERASE
        DB      5,"TYPE",1
        DW      OFFSET TRANGROUP:TYPEFIL
        DB      4,"REM",0
        DW      OFFSET TRANGROUP:TCOMMAND
        DB      5,"COPY",1
        DW      OFFSET TRANGROUP:COPY
        DB      6,"PAUSE",0
        DW      OFFSET TRANGROUP:PAUSE
        DB      5,"DATE",0
        DW      OFFSET TRANGROUP:DATE
        DB      5,"TIME",0
        DW      OFFSET TRANGROUP:CTIME
        DB      4,"VER",0
        DW      OFFSET TRANGROUP:VERSION
        DB      4,"VOL",1
        DW      OFFSET TRANGROUP:VOLUME
        DB      3,"CD",1
        DW      OFFSET TRANGROUP:$CHDIR
        DB      6,"CHDIR",1
        DW      OFFSET TRANGROUP:$CHDIR
        DB      3,"MD",1
        DW      OFFSET TRANGROUP:$MKDIR
        DB      6,"MKDIR",1
        DW      OFFSET TRANGROUP:$MKDIR
        DB      3,"RD",1
        DW      OFFSET TRANGROUP:$RMDIR
        DB      6,"RMDIR",1
        DW      OFFSET TRANGROUP:$RMDIR
        DB      6,"BREAK",0
        DW      OFFSET TRANGROUP:CNTRLC
        DB      7,"VERIFY",0
        DW      OFFSET TRANGROUP:VERIFY
        DB      4,"SET",0
        DW      OFFSET TRANGROUP:ADD_NAME_TO_ENVIRONMENT
        DB      7,"PROMPT",0
        DW      OFFSET TRANGROUP:ADD_PROMPT
        DB      5,"PATH",0
        DW      OFFSET TRANGROUP:PATHŠ        DB      5,"EXIT",0
        DW      OFFSET TRANGROUP:$EXIT
        DB      5,"CTTY",1
        DW      OFFSET TRANGROUP:CTTY
        DB      5,"ECHO",0
        DW      OFFSET TRANGROUP:ECHO
        DB      5,"GOTO",0
        DW      OFFSET TRANGROUP:GOTO
        DB      6,"SHIFT",0
        DW      OFFSET TRANGROUP:SHIFT
        DB      3,"IF",0
        DW      OFFSET TRANGROUP:$IF
        DB      4,"FOR",0
        DW      OFFSET TRANGROUP:$FOR
        DB      4,"CLS",0
        DW      OFFSET TRANGROUP:CLS
        DB      0               ; Terminate command table

TRANDATAEND     LABEL   BYTE

TRANDATA        ENDS
        END
                                                                            