TITLE   CHKDSK Messages

FALSE   EQU     0
TRUE    EQU     NOT FALSE

.xlist
.xcref
        INCLUDE DOSSYM.ASM
;The DOST: prefix is a DEC TOPS/20 directory prefix. Remove it for
;   assembly in MS-DOS assembly environments using MASM. The DOSSYM.ASM
;   file must exist though, it is included with OEM distribution.
.cref
.list
CODE    SEGMENT PUBLIC BYTE
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE
        EXTRN   HIDSIZ:WORD,HIDCNT:WORD,DIRCNT:WORD,DIRSIZ:WORD,FILCNT:WORD
        EXTRN   FILSIZ:WORD,ORPHCNT:WORD,ORPHSIZ:WORD,BADSIZ:WORD,LCLUS:WORD
        EXTRN   DOFIX:BYTE
CONST   ENDS

DATA    SEGMENT PUBLIC BYTE
        EXTRN   DSIZE:WORD
DATA    ENDS

DG      GROUP   CODE,CONST,DATA


CODE    SEGMENT PUBLIC BYTE
ASSUME  CS:DG,DS:DG,ES:DG,SS:DG

        PUBLIC  RDSKERR,WDSKERR,SETSWITCH,PROMPTYN,DOINT26,CHAINREPORT,REPORT
        EXTRN   RDONE:NEAR,PRTCHR:NEAR,PRINT:NEAR,DOCRLF:NEAR
        EXTRN   DISP16BITS:NEAR,FINDCHAIN:NEAR
        EXTRN   DISP32BITS:NEAR,DISPCLUS:NEAR

DOINT26:
        PUSH    CX
        PUSH    AX
        PUSH    DX
        PUSH    BX
        INT     26H
        MOV     [HECODE],AL
        POP     AX                      ;FLAGS
        POP     BX
        POP     DX
        POP     AX
        POP     CX
        JNC     RET23
        MOV     SI,OFFSET DG:WRITING
        CALL    DSKERR
        JZ      DOINT26
RET23:  RET

RDSKERR:
        MOV     SI,OFFSET DG:READING
        JMP     SHORT DSKERR

WDSKERR:
        MOV     SI,OFFSET DG:WRITING
DSKERR:
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        PUSH    ES
        MOV     AL,[HECODE]
        CMP     AL,12
        JBE     HAVCOD
        MOV     AL,12
HAVCOD:
        XOR     AH,AH
        MOV     DI,AX
        SHL     DI,1
        MOV     DX,WORD PTR [DI+MESBAS] ; Get pointer to error message
        CALL    PRINT          ; Print error type
        MOV     DX,OFFSET DG:ERRMES
        CALL    PRINT
        MOV     DX,SI
        CALL    PRINT
        MOV     DX,OFFSET DG:DRVMES
        CALL    PRINT
ASK:
        MOV     DX,OFFSET DG:REQUEST
        CALL    PRINT
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8)+STD_CON_INPUT
        INT     21H             ; Get response
        PUSH    AX
        CALL    DOCRLF
        POP     AX
        OR      AL,20H          ; Convert to lower case
        CMP     AL,"i"          ; Ignore?
        JZ      EEXITNZ
        CMP     AL,"r"          ; Retry?
        JZ      EEXIT
        CMP     AL,"a"          ; Abort?
        JNZ     ASK
        JMP     RDONE

EEXITNZ:
        OR      AL,AL           ; Resets zero flag
EEXIT:
        POP     ES
        POP     DI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET

PROMPTYN:
;Prompt message in DX
;Prompt user for Y or N answer. Zero set if Y
        PUSH    SI
        CALL    PRINT
PAGAIN:
        MOV     DX,OFFSET DG:YES_NO
        CALL    PRINT
        MOV     DX,OFFSET DG:CONBUF
        MOV     AH,STD_CON_STRING_INPUT
        INT     21H
        CALL    DOCRLF
        MOV     SI,OFFSET DG:CONBUF+2
        CMP     BYTE PTR [SI-1],0
        JZ      PAGAIN
        LODSB
        OR      AL,20H          ;Convert to lower case
        CMP     AL,'y'
        JZ      GOTANS
        CMP     AL,'n'
        JZ      GOTNANS
        JMP     PAGAIN
GOTNANS:
        OR      AL,AL           ;Reset zero
GOTANS:
        POP     SI
        RET

SETSWITCH:
;Look for F or V switch in command line
        MOV     SI,80H
        LODSB
        MOV     DI,SI
        MOV     CL,AL
        XOR     CH,CH
        JCXZ    RET10           ;No parameters
        MOV     AL,[SWITCHAR]
MORESCAN:
        REPNZ   SCASB
        JNZ     RET10
        JCXZ    BADSWITCHA
        MOV     AH,[DI]
        INC     DI
        OR      AH,20H          ;Convert to lower case
        CMP     AH,'f'
        JNZ     CHECKV
        INC     [DOFIX]
        JMP     SHORT CHEKMORE
CHECKV:
        CMP     AH,'v'
        JZ      SETNOISY
        CALL    BADSWITCH
        JMP     SHORT CHEKMORE
SETNOISY:
        INC     [NOISY]
CHEKMORE:
        LOOP    MORESCAN
        RET

BADSWITCHA:
        MOV     AH,' '                  ;Print a non switch
BADSWITCH:
        PUSH    AX
        MOV     DL,[SWITCHAR]
        CALL    PRTCHR
        POP     AX
        PUSH    AX
        MOV     DL,AH
        CALL    PRTCHR
        MOV     DX,OFFSET DG:BADSWMES
        CALL    PRINT
        POP     AX
RET10:  RET


;**************************************
; Prints XXX lost clusters found in YYY chains message
; On entry SI is the XXX value and the YYY value is
; in ORPHCNT.
; NOTE:
;       The DISP16BITS routine prints the number in DI:SI followed
;          by the message pointed to by BX. If it is desired to
;          print a message before the first number, point at the
;          message with DX and call PRINT.

CHAINREPORT:
        XOR     DI,DI
        MOV     BX,OFFSET DG:ORPHMES2
        CALL    DISP16BITS
        CALL    FINDCHAIN
        MOV     BX,OFFSET DG:CHNUMMES
        MOV     SI,[ORPHCNT]
        XOR     DI,DI
        CALL    DISP16BITS              ;Tell user how many chains found
        RET

;*****************************************
;Prints all of the reporting data
;NOTE:
;       The DISPCLUS, DISP16BITS and DISP32BITS routines
;          print the number in DI:SI followed
;          by the message pointed to by BX. If it is desired to
;          print a message before the first number, point at the
;          message with DX and call PRINT.

REPORT:
        MOV     AX,[DSIZE]
        MOV     BX,OFFSET DG:DSKSPC
        CALL    DISPCLUS                ;Total size
        CMP     [HIDCNT],0
        JZ      USERLIN
        MOV     AX,[HIDSIZ]             ;Hidden files
        MOV     BX,OFFSET DG:INMES
        CALL    DISPCLUS
        MOV     SI,[HIDCNT]
        XOR     DI,DI
        MOV     BX,OFFSET DG:HIDMES
        CALL    DISP16BITS
USERLIN:
        CMP     [DIRCNT],0
        JZ      DIRLIN
        MOV     AX,[DIRSIZ]
        MOV     BX,OFFSET DG:INMES
        CALL    DISPCLUS
        MOV     SI,[DIRCNT]
        XOR     DI,DI
        MOV     BX,OFFSET DG:DIRMES
        CALL    DISP16BITS
DIRLIN:
        CMP     [FILCNT],0
        JZ      ORPHLIN
        MOV     AX,[FILSIZ]             ;Regular files
        MOV     BX,OFFSET DG:INMES
        CALL    DISPCLUS
        MOV     SI,[FILCNT]
        XOR     DI,DI
        MOV     BX,OFFSET DG:FILEMES
        CALL    DISP16BITS
ORPHLIN:
        MOV     AX,[ORPHSIZ]
        OR      AX,AX
        JZ      BADLIN
        MOV     BX,OFFSET DG:INMES      ;Orphans
        CMP     [DOFIX],0
        JNZ     ALLSET1
        MOV     BX,OFFSET DG:INMES2     ;Orphans
ALLSET1:
        CALL    DISPCLUS
        MOV     SI,[ORPHCNT]
        XOR     DI,DI
        MOV     BX,OFFSET DG:ORPHMES
        CALL    DISP16BITS
BADLIN:
        MOV     AX,[BADSIZ]
        OR      AX,AX
        JZ      AVAILIN
        MOV     BX,OFFSET DG:BADSPC     ;Bad sectors
        CALL    DISPCLUS
AVAILIN:
        MOV     AX,[DSIZE]
        SUB     AX,[DIRSIZ]
        SUB     AX,[FILSIZ]
        SUB     AX,[HIDSIZ]
        SUB     AX,[BADSIZ]
        SUB     AX,[ORPHSIZ]
        SUB     AX,[LCLUS]
        MOV     BX,OFFSET DG:FRESPC
        CALL    DISPCLUS                ;Free space is whats left
        MOV     AX,DS:WORD PTR [2]      ;Find out about memory
        MOV     DX,16
        MUL     DX
        MOV     SI,AX
        MOV     DI,DX
        MOV     BX,OFFSET DG:TOTMEM
        CALL    DISP32BITS
        MOV     AX,DS:WORD PTR [2]
        MOV     DX,CS
        SUB     AX,DX
        MOV     DX,16
        MUL     DX
        MOV     SI,AX
        MOV     DI,DX
        MOV     BX,OFFSET DG:FREMEM
        CALL    DISP32BITS
        RET

CODE    ENDS


CONST   SEGMENT PUBLIC BYTE

        EXTRN   HECODE:BYTE,SWITCHAR:BYTE,NOISY:BYTE,DOFIX:BYTE,CONBUF:BYTE

        PUBLIC  CRLF2,CRLF,BADVER,BADDRV
        PUBLIC  BADSUBDIR,CENTRY,CLUSBAD,BADATT,BADSIZM
        PUBLIC  FIXMES,DIRECMES,CDDDMES
        PUBLIC  FREEBYMESF_PRE,FREEBYMES_PRE,FREEBYMESF_POST,FREEBYMES_POST
        PUBLIC  CREATMES,NDOTMES
        PUBLIC  BADTARG1,BADTARG2,BADCD,FATALMES,BADRDMES
        PUBLIC  BADDRVM,STACKMES,BADDPBDIR
        PUBLIC  BADDRVM2
        PUBLIC  NULNZ,NULDMES,BADCLUS,NORECDOT
        PUBLIC  NORECDDOT,IDMES1,IDPOST,VNAME,TCHAR
        PUBLIC  MONTAB,BADREAD_PRE,BADREAD_POST,BADWRITE_PRE
        PUBLIC  BADWRITE_POST,BADCHAIN,CROSSMES_PRE,CROSSMES_POST
        PUBLIC  FREEMES
        PUBLIC  OPNERR
        PUBLIC  CONTAINS,EXTENTS,NOEXTENTS,INDENT
        PUBLIC  BADIDBYT,PTRANDIR,PTRANDIR2


MESBAS  DW      OFFSET DG:ERR0
        DW      OFFSET DG:ERR1
        DW      OFFSET DG:ERR2
        DW      OFFSET DG:ERR3
        DW      OFFSET DG:ERR4
        DW      OFFSET DG:ERR5
        DW      OFFSET DG:ERR6
        DW      OFFSET DG:ERR7
        DW      OFFSET DG:ERR8
        DW      OFFSET DG:ERR9
        DW      OFFSET DG:ERR10
        DW      OFFSET DG:ERR11
        DW      OFFSET DG:ERR12

CRLF2   DB      13,10
CRLF    DB      13,10,"$"

;Messages

BADVER  DB      "Incorrect DOS version",13,10,"$"
BADDRV  DB      "Invalid drive specification$"

BADSWMES  DB     " Invalid parameter",13,10,"$"

BADSUBDIR DB    "   Invalid sub-directory entry.",13,10,"$"
CENTRY  DB      "   Entry has a bad $"
CLUSBAD DB      " link$"
BADATT  DB      " attribute$"
BADSIZM DB      " size$"

;"BADTARG1<name of dir followed by CR LF>BADTARG2"
BADTARG1 DB     "Cannot CHDIR to $"
BADTARG2 DB     "   tree past this point not processed.",13,10,"$"

BADCD   DB      "Cannot CHDIR to root",13,10,"$"

FATALMES DB     "Processing cannot continue.",13,10,"$"
BADRDMES DB     "File allocation table bad drive "
BADDRVM  DB     "A.",13,10,"$"
STACKMES DB     "Insufficient memory.",13,10,"$"
BADDPBDIR DB    "Invalid current directory.",13,10,"$"

;INT 24 MESSAGE SHOULD AGREE WITH COMMAND

READING DB      "read$"
WRITING DB      "writ$"
ERRMES  DB      " error $"
DRVMES  DB      "ing drive "
BADDRVM2  DB    "A",13,10,"$"
REQUEST DB      "Abort, Retry, Ignore? $"
ERR0    DB      "Write protect$"
ERR1    DB      "Bad unit$"
ERR2    DB      "Not ready$"
ERR3    DB      "Bad command$"
ERR4    DB      "Data$"
ERR5    DB      "Bad call format$"
ERR6    DB      "Seek$"
ERR7    DB      "Non-DOS disk$"
ERR8    DB      "Sector not found$"
ERR9    DB      "No paper$"
ERR10   DB      "Write fault$"
ERR11   DB      "Read fault$"
ERR12   DB      "Disk$"


NDOTMES DB      "   Does not exist.",13,10,"$"
NULNZ   DB      "   First cluster number is invalid,",13,10
        DB      "    entry truncated.",13,10,"$"
NULDMES DB      "   Directory is totally empty, no . or ..",13,10,"$"
BADCLUS DB      "   Allocation error, size adjusted.",13,10,"$"
NORECDOT DB     "   Cannot recover . entry, processing continued.",13,10,"$"
NORECDDOT DB    "   Cannot recover .. entry,"

;VOLUME ID

;"IDMES1/name at VNAME<date and time>IDPOST"
IDPOST  DB      13,10,"$"               ;WARNING this is currently the tail of
                                        ; the previos message!!!
IDMES1  DB      "Volume "
VNAME   DB      12 DUP(' ')
        DB      "created $"
TCHAR   DB      'a'
MONTAB  DB      "JanFebMarAprMayJunJulAugSepOctNovDec"



;"BADREAD_PRE<# of FAT>BADREAD_POST"
BADREAD_PRE DB      "Disk error reading FAT $"

;"BADWRITE_PRE<# of FAT>BADWRITE_POST"
BADWRITE_PRE DB     "Disk error writing FAT $"

BADCHAIN DB     "   Has invalid cluster, file truncated."

BADREAD_POST    LABEL   BYTE
BADWRITE_POST   LABEL   BYTE

;"<name of file followed by CR LF>CROSSMES_PRE<# of cluster>CROSSMES_POST"
CROSSMES_POST   DB  13,10,"$"           ;WARNING Is tail of previos messages
CROSSMES_PRE    DB  "   Is cross linked on cluster $"

;CHAINREPORT messages
ORPHMES2 DB     " lost clusters found in $"
CHNUMMES DB     " chains.",13,10,"$"

FREEMES DB      "Convert lost chains to files $"

;REPORT messages
ORPHMES DB      " recovered files",13,10,"$"
DSKSPC  DB      " bytes total disk space",13,10,"$"
INMES   DB      " bytes in $"
INMES2  DB      " bytes would be in",13,10
        DB      "          $"
FILEMES DB      " user files",13,10,"$"
BADSPC  DB      " bytes in bad sectors",13,10,"$"
HIDMES  DB      " hidden files",13,10,"$"
DIRMES  DB      " directories",13,10,"$"
FRESPC  DB      " bytes available on disk",13,10,13,10,"$"
TOTMEM  DB      " bytes total memory",13,10,"$"
FREMEM  DB      " bytes free",13,10,13,10,"$"

;"<filename followed by CR LF>CONTAINS<# non-contig blocks>EXTENTS"
CONTAINS DB     "   Contains $"
EXTENTS DB      " non-contiguous blocks.",13,10,"$"

NOEXTENTS DB    "All specified file(s) are contiguous.",13,10,"$"
INDENT  DB      "      $"

BADIDBYT DB     "Probable non-DOS disk."
        DB      13,10,"Continue $"
YES_NO  DB      "(Y/N)? $"
PTRANDIR DB     "   Unrecoverable error in directory.",13,10
PTRANDIR2 DB    "   Convert directory to file $"
FIXMES  DB      13,10,"Errors found, F parameter not specified."
        DB      13,10,"Corrections will not be written to disk.",13,10,13,10,"$"
DIRECMES DB     "Directory $"
CDDDMES DB      "   CHDIR .. failed, trying alternate method.",13,10,"$"


FREEBYMESF_POST DB   " bytes disk space freed.",13,10
FREEBYMESF_PRE  DB   "$"
FREEBYMES_POST  DB   " bytes disk space",13,10
                DB   "          would be freed.",13,10
FREEBYMES_PRE   DB   "$"


CREATMES DB     "Insufficient room in root directory."
        DB      13,10,"Erase files in root and repeat CHKDSK.",13,10,"$"
OPNERR  DB      "   File not found.",13,10,"$"


CONST   ENDS
        END
                    