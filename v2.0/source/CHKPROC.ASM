TITLE   CHKPROC - Procedures called from chkdsk

FALSE   EQU     0
TRUE    EQU     NOT FALSE

DRVCHAR EQU     ":"

        INCLUDE DOSSYM.ASM

SUBTTL  Segments used in load order

CODE    SEGMENT PUBLIC
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE

        EXTRN   CLUSBAD:BYTE,BADATT:BYTE,BADSIZM:BYTE
        EXTRN   DIRECMES:BYTE,CDDDMES:BYTE,NDOTMES:BYTE
        EXTRN   BADTARG1:BYTE,BADTARG2:BYTE,FATALMES:BYTE
        EXTRN   STACKMES:BYTE,BADDPBDIR:BYTE,CREATMES:BYTE
        EXTRN   FREEBYMES_PRE:BYTE,FREEBYMESF_PRE:BYTE
        EXTRN   FREEBYMES_POST:BYTE,FREEBYMESF_POST:BYTE
        EXTRN   NULNZ:BYTE,NULDMES:BYTE,BADCLUS:BYTE
        EXTRN   NORECDDOT:BYTE,NORECDOT:BYTE,DOTMES:BYTE
        EXTRN   BADWRITE_PRE:BYTE,BADCHAIN:BYTE,CROSSMES_PRE:BYTE
        EXTRN   BADWRITE_POST:BYTE,CROSSMES_POST:BYTE,INDENT:BYTE
        EXTRN   PTRANDIR:BYTE,PTRANDIR2:BYTE,FREEMES:BYTE,FIXMES:BYTE

        EXTRN   NOISY:BYTE,DOFIX:BYTE,DIRBUF:WORD,DOTENT:BYTE,FIXMFLG:BYTE
        EXTRN   HAVFIX:BYTE,SECONDPASS:BYTE,LCLUS:WORD,DIRTYFAT:BYTE
        EXTRN   NUL:BYTE,ALLFILE:BYTE,PARSTR:BYTE,ERRSUB:WORD,USERDIR:BYTE
        EXTRN   HIDCNT:WORD,HIDSIZ:WORD,FILCNT:WORD,FILSIZ:WORD,DIRCHAR:BYTE
        EXTRN   DIRCNT:WORD,DIRSIZ:WORD,FRAGMENT:BYTE,HECODE:BYTE
        EXTRN   BADSIZ:WORD,ORPHSIZ:WORD,DDOTENT:BYTE,CROSSCNT:WORD
        EXTRN   ORPHCNT:WORD,ORPHFCB:BYTE,ORPHEXT:BYTE,ALLDRV:BYTE,DIRCHAR:BYTE

CONST   ENDS

DATA    SEGMENT PUBLIC WORD

        EXTRN   THISDPB:DWORD,HARDCH:DWORD,CONTCH:DWORD,USERDEV:BYTE
        EXTRN   CSIZE:BYTE,SSIZE:WORD,DSIZE:WORD,MCLUS:WORD,NAMBUF:BYTE
        EXTRN   DOTSNOGOOD:BYTE,ZEROTRUNC:BYTE,ISCROSS:BYTE,SRFCBPT:WORD
        EXTRN   FATMAP:WORD,SECBUF:WORD,ERRCNT:BYTE,STACKLIM:WORD,FAT:WORD

DATA    ENDS

DG      GROUP   CODE,CONST,DATA

SUBTTL  Initialized Data
PAGE


CODE    SEGMENT PUBLIC
ASSUME  CS:DG,DS:DG,ES:DG,SS:DG

        PUBLIC  INT_23,INT_24,FINDCHAIN,DONE,AMDONE,RDONE
        PUBLIC  FATAL,DIRPROC,CHKMAP,CHKCROSS,UNPACK
        PUBLIC  PRINTTHISEL2,CHECKERR,PRINTCURRDIRERR

        EXTRN   EPRINT:NEAR,DOCRLF:NEAR,PRINT:NEAR
        EXTRN   PROMPTYN:NEAR,DOINT26:NEAR,SUBERRP:NEAR
        EXTRN   DOTCOMBMES:NEAR,DISP16BITS:NEAR
        EXTRN   CHAINREPORT:NEAR,DISPCLUS:NEAR
        EXTRN   PRTCHR:NEAR,WDSKERR:NEAR,CHECKFILES:NEAR
        EXTRN   FCB_TO_ASCZ:NEAR,FIGREC:NEAR,RDSKERR:NEAR

CHKPROC:

SUBTTL  DIRPROC -- Recursive directory processing

; YOU ARE ADVISED NOT TO COPY THE FOLLOWING METHOD!!!

DOTDOTHARDWAY:
        LDS     DI,[THISDPB]
ASSUME  DS:NOTHING
        MOV     [DI.dpb_current_dir],-1       ;Invalidate path
        MOV     SI,DI
        ADD     SI,dpb_dir_text
        MOV     CX,SI
FINDEND:
        LODSB                           ;Scan to end of current path
        OR      AL,AL
        JNZ     FINDEND
        DEC     SI                      ;Point at the NUL
DELLOOP:                                ;Delete last element
        CMP     SI,CX
        JZ      SETROOT
        CMP     BYTE PTR [SI],"/"
        JZ      SETTERM
        CMP     BYTE PTR [SI],"\"
        JZ      SETTERM
        DEC     SI
        JMP     SHORT DELLOOP

SETTERM:
        MOV     BYTE PTR [SI],0
SETCURR:
        PUSH    CS
        POP     DS
ASSUME  DS:DG
        MOV     DX,OFFSET DG:DOTMES
        MOV     AH,CHDIR                ;Chdir to altered path
        INT     21H
        RET

SETROOT:
ASSUME  DS:NOTHING
        MOV     [DI.dpb_current_dir],0        ;Set Path to Root
        JMP     SHORT SETCURR           ;The CHDIR will fail, but who cares


;Structures used by DIRPROC

SRCHFCB STRUC
        DB      44 DUP (?)
SRCHFCB ENDS
SFCBSIZ EQU     SIZE SRCHFCB
THISENT EQU     17H                     ;Relative entry number of current entry

DIRENT  STRUC
        DB      7 DUP (?)               ;Ext FCB junk
        DB      ?                       ;Drive
DIRNAM  DB      11 DUP (?)
DIRATT  DB      ?
        DB      10 DUP (?)
DIRTIM  DW      ?
DIRDAT  DW      ?
DIRCLUS DW      ?
DIRESIZ DD      ?
DIRENT  ENDS
ENTSIZ  EQU     SIZE DIRENT

;Attribute bits

RDONLY  EQU     1
HIDDN   EQU     2
SYSTM   EQU     4
VOLIDA  EQU     8
ISDIR   EQU     10H

ASSUME  DS:DG

NODOT:                                  ;No .
        PUSH    AX                      ;Return from SRCH
        CMP     [NOISY],0
        JNZ     DOEXTMES1
        CALL    SUBERRP
        JMP     SHORT MESD1
DOEXTMES1:
        MOV     SI,OFFSET DG:DOTMES
        CALL    PRINTCURRDIRERR
        MOV     DX,OFFSET DG:NDOTMES
        CALL    EPRINT
MESD1:
        XOR     AX,AX
        PUSH    BX
        PUSH    BP
        CALL    GETENT
        POP     BP
        PUSH    BP
        CMP     BYTE PTR [DI],0E5H      ;Have place to put .?
        JNZ     CANTREC                 ;Nope
        MOV     SI,OFFSET DG:DOTENT
        MOV     CX,11
        REP     MOVSB                   ;Name
        PUSH    AX
        MOV     AL,ISDIR
        STOSB                           ;Attribute
        ADD     DI,10
        XOR     AX,AX
        STOSW                           ;Date = 0
        STOSW                           ;Time = 0
        MOV     AX,[BP+6]
        STOSW                           ;Alloc #
        XOR     AX,AX
        STOSW
        STOSW                           ;Size
        POP     AX
        MOV     [HAVFIX],1              ;Have a fix
        CMP     [DOFIX],0
        JZ      DOTGOON                 ;No fix if not F
        MOV     CX,1
        CALL    DOINT26
        JMP     SHORT DOTGOON

CANTREC:
        INC     [DOTSNOGOOD]
        CMP     [NOISY],0
        JZ      DOTGOON
        MOV     DX,OFFSET DG:NORECDOT
        CALL    EPRINT
DOTGOON:
        POP     BP
        POP     BX
        POP     AX
        MOV     SI,OFFSET DG:DIRBUF
        JMP     CHKDOTDOT               ;Go look for ..

NODDOT:                                 ;No ..
        PUSH    AX                      ;Return from SRCH
        CMP     [NOISY],0
        JNZ     DOEXTMES2
        CALL    SUBERRP
        JMP     SHORT MESD2
DOEXTMES2:
        MOV     SI,OFFSET DG:PARSTR
        CALL    PRINTCURRDIRERR
        MOV     DX,OFFSET DG:NDOTMES
        CALL    EPRINT
MESD2:
        MOV     AX,1
        PUSH    BX
        PUSH    BP
        CALL    GETENT
        POP     BP
        PUSH    BP
        CMP     BYTE PTR [DI],0E5H      ;Place to put it?
        JNZ     CANTREC2                ;Nope
        MOV     SI,OFFSET DG:DDOTENT
        MOV     CX,11
        REP     MOVSB                   ;Name
        PUSH    AX
        MOV     AL,ISDIR
        STOSB                           ;Attribute
        ADD     DI,10
        XOR     AX,AX
        STOSW                           ;Date
        STOSW                           ;Time
        MOV     AX,[BP+4]
        STOSW                           ;Alloc #
        XOR     AX,AX
        STOSW
        STOSW                           ;Size
        POP     AX
        MOV     [HAVFIX],1              ;Got a fix
        CMP     [DOFIX],0
        JZ      NFIX                    ;No fix if no F, carry clear
        MOV     CX,1
        CALL    DOINT26
NFIX:
        POP     BP
        POP     BX
        POP     AX
        MOV     SI,OFFSET DG:DIRBUF
        JMP     ROOTDIR                 ;Process files

CANTREC2:
        POP     BP
        POP     BX
        POP     AX
        CMP     [NOISY],0
        JZ      DOTSBAD
        MOV     DX,OFFSET DG:NORECDDOT
        CALL    EPRINT
        JMP     DOTSBAD

NULLDIRERR:
        CMP     [NOISY],0
        JNZ     DOEXTMES3
        CALL    SUBERRP
        JMP     SHORT DOTSBAD
DOEXTMES3:
        MOV     SI,OFFSET DG:NUL
        CALL    PRINTCURRDIRERR
        MOV     DX,OFFSET DG:NULDMES
        CALL    EPRINT
DOTSBAD:                                ;Can't recover
        MOV     DX,OFFSET DG:BADTARG2
        CALL    EPRINT
        CALL    DOTDOTHARDWAY
        INC     [DOTSNOGOOD]
        JMP     DIRDONE                 ;Terminate tree walk at this level

ROOTDIRJ: JMP   ROOTDIR

PAGE
DIRPROC:
;Recursive tree walker
;dirproc(self,parent)
        MOV     [DOTSNOGOOD],0          ;Init to dots OK
        MOV     [ERRSUB],0              ;No subdir errors yet
        PUSH    BP                      ;Save frame pointer
        MOV     BP,SP
        SUB     SP,SFCBSIZ              ;Only local var
        CMP     SP,[STACKLIM]
        JA      STACKISOK
        MOV     BX,OFFSET DG:STACKMES   ;Out of stack
        JMP     FATAL
STACKISOK:
        CMP     [NOISY],0
        JZ      NOPRINT
        CMP     [SECONDPASS],0
        JNZ     NOPRINT                 ;Don't do it again on second pass
        MOV     DX,OFFSET DG:DIRECMES   ;Tell user where we are
        CALL    PRINT
        MOV     SI,OFFSET DG:NUL
        CALL    PRINTCURRDIR
        CALL    DOCRLF
NOPRINT:
        MOV     SI,OFFSET DG:ALLFILE
        MOV     DI,SP
        PUSH    DI
        MOV     CX,SFCBSIZ
        REP     MOVSB           ;Initialize search FCB
        POP     DX
        MOV     BX,DX           ;BX points to SRCH FCB
        MOV     AH,DIR_SEARCH_FIRST
        INT     21H
        CMP     WORD PTR [BP+6],0       ;Am I the root
        JZ      ROOTDIRJ                ;Yes, no . or ..
        OR      AL,AL
        JZ      NONULLDERR
        JMP     NULLDIRERR              ;Dir is empty!
NONULLDERR:
        MOV     SI,OFFSET DG:DIRBUF + DIRNAM
        MOV     DI,OFFSET DG:DOTENT
        MOV     CX,11
        REP     CMPSB
        JZ      DOTOK                   ;Got a . as first entry
        JMP     NODOT                   ;No .
DOTOK:
        MOV     SI,OFFSET DG:DIRBUF
        MOV     AL,[SI.DIRATT]
        TEST    AL,ISDIR
        JNZ     DATTOK
        PUSH    SI                      ;. not a dir?
        MOV     SI,OFFSET DG:DOTMES
        MOV     DX,OFFSET DG:BADATT
        CALL    DOTCOMBMES
        POP     SI
        OR      [SI.DIRATT],ISDIR
        CALL    FIXENT                  ;Fix it
DATTOK:
        MOV     AX,[SI.DIRCLUS]
        CMP     AX,[BP+6]               ;. link = MYSELF?
        JZ      DLINKOK
        PUSH    SI                      ;Link messed up
        MOV     SI,OFFSET DG:DOTMES
        MOV     DX,OFFSET DG:CLUSBAD
        CALL    DOTCOMBMES
        POP     SI
        MOV     AX,[BP+6]
        MOV     [SI.DIRCLUS],AX
        CALL    FIXENT                  ;Fix it
DLINKOK:
        MOV     AX,WORD PTR [SI.DIRESIZ]
        OR      AX,AX
        JNZ     BADDSIZ
        MOV     AX,WORD PTR [SI.DIRESIZ+2]
        OR      AX,AX
        JZ      DSIZOK
BADDSIZ:                                ;Size should be zero
        PUSH    SI
        MOV     SI,OFFSET DG:DOTMES
        MOV     DX,OFFSET DG:BADSIZM
        CALL    DOTCOMBMES
        POP     SI
        XOR     AX,AX
        MOV     WORD PTR [SI.DIRESIZ],AX
        MOV     WORD PTR [SI.DIRESIZ+2],AX
        CALL    FIXENT                  ;Fix it
DSIZOK:                                 ;Get next (should be ..)
        MOV     DX,BX
        MOV     AH,DIR_SEARCH_NEXT
        INT     21H
CHKDOTDOT:                              ;Come here after . failure
        OR      AL,AL
        JZ      DOTDOTOK
NODDOTJ: JMP    NODDOT                  ;No ..
DOTDOTOK:
        MOV     SI,OFFSET DG:DIRBUF + DIRNAM
        MOV     DI,OFFSET DG:DDOTENT
        MOV     CX,11
        REP     CMPSB
        JNZ     NODDOTJ                 ;No ..
        MOV     SI,OFFSET DG:DIRBUF
        MOV     AL,[SI.DIRATT]
        TEST    AL,ISDIR
        JNZ     DDATTOK                 ;.. must be a dir
        PUSH    SI
        MOV     SI,OFFSET DG:PARSTR
        MOV     DX,OFFSET DG:BADATT
        CALL    DOTCOMBMES
        POP     SI
        OR      [SI.DIRATT],ISDIR
        CALL    FIXENT                  ;Fix it
DDATTOK:
        PUSH    SI
        MOV     AX,[SI.DIRCLUS]
        CMP     AX,[BP+4]               ;.. link must be PARENT
        JZ      DDLINKOK
        MOV     SI,OFFSET DG:PARSTR
        MOV     DX,OFFSET DG:CLUSBAD
        CALL    DOTCOMBMES
        POP     SI
        MOV     AX,[BP+4]
        MOV     [SI.DIRCLUS],AX
        CALL    FIXENT                  ;Fix it
DDLINKOK:
        MOV     AX,WORD PTR [SI.DIRESIZ]
        OR      AX,AX
        JNZ     BADDDSIZ
        MOV     AX,WORD PTR [SI.DIRESIZ+2]
        OR      AX,AX
        JZ      DDSIZOK
BADDDSIZ:                               ;.. size should be 0
        PUSH    SI
        MOV     SI,OFFSET DG:PARSTR
        MOV     DX,OFFSET DG:BADSIZM
        CALL    DOTCOMBMES
        POP     SI
        XOR     AX,AX
        MOV     WORD PTR [SI.DIRESIZ],AX
        MOV     WORD PTR [SI.DIRESIZ+2],AX
        CALL    FIXENT                  ;Fix it
DDSIZOK:
        MOV     DX,BX                   ;Next entry
        MOV     AH,DIR_SEARCH_NEXT
        INT     21H

ROOTDIR:                                ;Come here after .. failure also
        OR      AL,AL
        JZ      MOREDIR                 ;More to go
        CMP     WORD PTR [BP+6],0       ;Am I the root?
        JZ      DIRDONE                 ;Yes, no chdir
        MOV     DX,OFFSET DG:PARSTR
        MOV     AH,CHDIR                ;Chdir to parent (..)
        INT     21H
        JNC     DIRDONE                 ;Worked
        CMP     [NOISY],0
        JZ      DODDH
        MOV     SI,OFFSET DG:NUL
        CALL    PRINTCURRDIRERR
        MOV     DX,OFFSET DG:CDDDMES
        CALL    EPRINT
DODDH:
        CALL    DOTDOTHARDWAY           ;Try again
DIRDONE:
        MOV     SP,BP                   ;Pop local vars
        POP     BP                      ;Restore frame
        RET     4                       ;Pop args

MOREDIR:
        MOV     SI,OFFSET DG:DIRBUF
        TEST    [SI.DIRATT],ISDIR
        JNZ     NEWDIR                  ;Is a new directory
        CMP     [SECONDPASS],0
        JZ      FPROC1                  ;First pass
        CALL    CROSSLOOK               ;Check for cross links
        JMP     DDSIZOK                 ;Next
FPROC1:
        CMP     [NOISY],0
        JZ      NOPRINT2
        MOV     DX,OFFSET DG:INDENT     ;Tell user where we are
        CALL    PRINT
        PUSH    BX
        MOV     BX,SI
        CALL    PRINTTHISEL
        CALL    DOCRLF
        MOV     SI,BX
        POP     BX
NOPRINT2:
        MOV     AL,81H                  ;Head of file
        CALL    MARKFAT
        TEST    [SI.DIRATT],VOLIDA
        JNZ     HIDENFILE               ;VOL ID counts as hidden
        TEST    [SI.DIRATT],HIDDN
        JZ      NORMFILE
HIDENFILE:
        INC     [HIDCNT]
        ADD     [HIDSIZ],CX
        JMP     DDSIZOK                 ;Next
NORMFILE:
        INC     [FILCNT]
        ADD     [FILSIZ],CX
        JMP     DDSIZOK                 ;Next

NEWDIR:
        CMP     [SECONDPASS],0
        JZ      DPROC1
        CALL    CROSSLOOK               ;Check for cross links
        JMP     SHORT DPROC2
DPROC1:
        MOV     AL,82H                  ;Head of dir
        CALL    MARKFAT
        INC     [DIRCNT]
        ADD     [DIRSIZ],CX
        CMP     [ZEROTRUNC],0
        JZ      DPROC2                  ;Dir not truncated
CONVDIR:
        AND     [SI.DIRATT],NOT ISDIR   ;Turn into file
        CALL    FIXENT
        JMP     DDSIZOK                 ;Next
DPROC2:
        PUSH    [ERRSUB]
        PUSH    BX                      ;Save my srch FCB pointer
        PUSH    [SI.DIRCLUS]            ;MYSELF for next directory
        PUSH    [BP+6]                  ;His PARENT is me
        ADD     SI,DIRNAM
        MOV     DI,OFFSET DG:NAMBUF
        PUSH    DI
        CALL    FCB_TO_ASCZ
        POP     DX
        MOV     AH,CHDIR                ;CHDIR to new dir
        INT     21H
        JC      CANTTARG                ;Barfed
        CALL    DIRPROC
        POP     BX                      ;Get my SRCH FCB pointer back
        POP     [ERRSUB]
        CMP     [DOTSNOGOOD],0
        JNZ     ASKCONV
        JMP     DDSIZOK                 ;Next

CANTTARG:
        POP     AX                      ;Clean stack
        POP     AX
        POP     AX
        POP     AX
        PUSH    DX                      ;Save pointer to bad DIR
        MOV     DX,OFFSET DG:BADTARG1
        CALL    EPRINT
        POP     SI                      ;Pointer to bad DIR
        CALL    PRINTCURRDIRERR
        MOV     DX,OFFSET DG:BADTARG2
        CALL    EPRINT
DDSIZOKJ: JMP   DDSIZOK                 ;Next

ASKCONV:
        CMP     [SECONDPASS],0
        JNZ     DDSIZOKJ                ;Leave on second pass
        MOV     DX,OFFSET DG:PTRANDIR
        CMP     [NOISY],0
        JNZ     PRINTTRMES
        MOV     DX,OFFSET DG:PTRANDIR2
PRINTTRMES:
        CALL    PROMPTYN                ;Ask user what to do
        JNZ     DDSIZOKJ                ;User say leave alone
        PUSH    BP
        PUSH    BX
        MOV     AX,[BX+THISENT]         ;Entry number
        CALL    GETENT                  ;Get the entry
        MOV     SI,DI
        MOV     DI,OFFSET DG:DIRBUF
        PUSH    DI
        ADD     DI,DIRNAM
        MOV     CX,32
        REP     MOVSB                   ;Transfer entry to DIRBUF
        POP     SI
        PUSH    SI
        MOV     SI,[SI.DIRCLUS]         ;First cluster
        CALL    GETFILSIZ
        POP     SI
        POP     BX
        POP     BP
        MOV     WORD PTR [SI.DIRESIZ],AX        ;Fix entry
        MOV     WORD PTR [SI.DIRESIZ+2],DX
        JMP     CONVDIR

SUBTTL  FAT Look routines
PAGE
CROSSLOOK:
;Same as MRKFAT only simpler for pass 2
        MOV     [SRFCBPT],BX
        MOV     BX,SI
        MOV     SI,[BX.DIRCLUS]
        CALL    CROSSCHK
        JNZ     CROSSLINKJ
CHLP:
        PUSH    BX
        CALL    UNPACK
        POP     BX
        XCHG    SI,DI
        CMP     SI,0FF8H
        JAE     CHAINDONEJ
        CALL    CROSSCHK
        JZ      CHLP
CROSSLINKJ: JMP SHORT CROSSLINK

CROSSCHK:
        MOV     DI,[FATMAP]
        ADD     DI,SI
        MOV     AH,[DI]
        TEST    AH,10H
        RET

NOCLUSTERSJ: JMP        NOCLUSTERS

MARKFAT:
; Map the file and perform checks
; SI points to dir entry
; AL is head mark with app type
; On return CX is number of clusters
; BX,SI preserved
; ZEROTRUNC is non zero if the file was trimmed to zero length
; ISCROSS is non zero if the file is cross linked

        MOV     [ZEROTRUNC],0   ;Initialize
        MOV     [ISCROSS],0
        MOV     [SRFCBPT],BX
        MOV     BX,SI
        XOR     CX,CX
        MOV     SI,[BX.DIRCLUS]
        CMP     SI,2
        JB      NOCLUSTERSJ     ;Bad cluster #  or nul file (SI = 0)
        CMP     SI,[MCLUS]
        JA      NOCLUSTERSJ     ;Bad cluster #
        PUSH    BX
        CALL    UNPACK
        POP     BX
        JZ      NOCLUSTERSJ     ;Bad cluster (it is marked free)
        CALL    MARKMAP
        JNZ     CROSSLINK
        AND     AL,7FH                  ;Turn off head bit
CHASELOOP:
        PUSH    BX
        CALL    UNPACK
        POP     BX
        INC     CX
        XCHG    SI,DI
        CMP     SI,0FF8H
        JAE     CHAINDONE
        CMP     SI,2
        JB      MRKBAD
        CMP     SI,[MCLUS]
        JBE     MRKOK
MRKBAD:                         ;Bad cluster # in chain
        PUSH    CX
        PUSH    DI
        CALL    PRINTTHISELERR
        MOV     DX,OFFSET DG:BADCHAIN
        CALL    EPRINT
        POP     SI
        MOV     DX,0FFFH        ;Insert EOF
        PUSH    BX
        CALL    PACK
        POP     BX
        POP     CX
CHAINDONEJ: JMP SHORT CHAINDONE

MRKOK:
        CALL    MARKMAP
        JZ      CHASELOOP
CROSSLINK:                      ;File is cross linked
        INC     [ISCROSS]
        CMP     [SECONDPASS],0
        JZ      CHAINDONE               ;Crosslinks only on second pass
        PUSH    SI                      ;Cluster number
        CALL    PRINTTHISEL
        CALL    DOCRLF
        MOV     DX,OFFSET DG:CROSSMES_PRE
        CALL    PRINT
        POP     SI
        PUSH    BX
        PUSH    CX
        MOV     BX,OFFSET DG:CROSSMES_POST
        XOR     DI,DI
        CALL    DISP16BITS
        POP     CX
        POP     BX
CHAINDONE:
        TEST    [BX.DIRATT],ISDIR
        JNZ     NOSIZE                  ;Don't size dirs
        CMP     [ISCROSS],0
        JNZ     NOSIZE                  ;Don't size cross linked files
        CMP     [SECONDPASS],0
        JNZ     NOSIZE                  ;Don't size on pass 2  (CX garbage)
        MOV     AL,[CSIZE]
        XOR     AH,AH
        MUL     [SSIZE]
        PUSH    AX              ;Size in bytes of one alloc unit
        MUL     CX
        MOV     DI,DX           ;Save allocation size
        MOV     SI,AX
        SUB     AX,WORD PTR [BX.DIRESIZ]
        SBB     DX,WORD PTR [BX.DIRESIZ+2]
        JC      BADFSIZ         ;Size to big
        OR      DX,DX
        JNZ     BADFSIZ         ;Size to small
        POP     DX
        CMP     AX,DX
        JB      NOSIZE          ;Size within one Alloc unit
        PUSH    DX              ;Size to small
BADFSIZ:
        POP     DX
        PUSH    CX              ;Save size of file
        MOV     WORD PTR [BX.DIRESIZ],SI
        MOV     WORD PTR [BX.DIRESIZ+2],DI
        CALL    FIXENT2                 ;Fix it
        CALL    PRINTTHISELERR
        MOV     DX,OFFSET DG:BADCLUS
        CALL    EPRINT
        POP     CX              ;Restore size of file
NOSIZE:
        MOV     SI,BX
        MOV     BX,[SRFCBPT]
        RET

NOCLUSTERS:
;File is zero length
        OR      SI,SI
        JZ      CHKSIZ          ;Firclus is OK, Check size
        MOV     DX,OFFSET DG:NULNZ
ADJUST:
        PUSH    DX
        CALL    PRINTTHISELERR
        POP     DX
        CALL    EPRINT
        XOR     SI,SI
        MOV     [BX.DIRCLUS],SI                 ;Set it to 0
        MOV     WORD PTR [BX.DIRESIZ],SI        ;Set size too
        MOV     WORD PTR [BX.DIRESIZ+2],SI
        CALL    FIXENT2                         ;Fix it
        INC     [ZEROTRUNC]                     ;Indicate truncation
        JMP     CHAINDONE

CHKSIZ:
        MOV     DX,OFFSET DG:BADCLUS
        CMP     WORD PTR [BX.DIRESIZ],0
        JNZ     ADJUST                          ;Size wrong
        CMP     WORD PTR [BX.DIRESIZ+2],0
        JNZ     ADJUST                          ;Size wrong
        JMP     CHAINDONE                       ;Size OK

UNPACK:
;Cluster number in SI, Return contents in DI, BX destroyed
;ZERO SET IF CLUSTER IS FREE
        MOV     BX,OFFSET DG:FAT
        MOV     DI,SI
        SHR     DI,1
        ADD     DI,SI
        MOV     DI,WORD PTR [DI+BX]
        TEST    SI,1
        JZ      HAVCLUS
        SHR     DI,1
        SHR     DI,1
        SHR     DI,1
        SHR     DI,1
HAVCLUS:
        AND     DI,0FFFH
        RET

PACK:
; SI      CLUSTER NUMBER TO BE PACKED
; DX      DATA TO BE PLACED IN CLUSTER (SI)
; BX,DX   DESTROYED
        MOV     [DIRTYFAT],1            ;Set FAT dirty byte
        MOV     [HAVFIX],1              ;Indicate a fix
        MOV     BX,OFFSET DG:FAT
        PUSH    SI
        MOV     DI,SI
        SHR     SI,1
        ADD     SI,BX
        ADD     SI,DI
        SHR     DI,1
        MOV     DI,[SI]
        JNC     ALIGNED
        SHL     DX,1
        SHL     DX,1
        SHL     DX,1
        SHL     DX,1
        AND     DI,0FH
        JMP     SHORT PACKIN
ALIGNED:
        AND     DI,0F000H
PACKIN:
        OR      DI,DX
        MOV     [SI],DI
        POP     SI
        RET



MARKMAP:
; Mark in AL
; Cluster in SI
; AL,SI,CX preserved
; ZERO RESET IF CROSSLINK, AH IS THE MARK THAT WAS THERE
        MOV     DI,[FATMAP]
        ADD     DI,SI
        MOV     AH,[DI]
        OR      AH,AH
        PUSH    AX
        JZ      SETMARK
        MOV     AL,AH
        INC     [CROSSCNT]      ;Count the crosslink
        OR      AL,10H          ;Resets zero
SETMARK:
        MOV     [DI],AL
        POP     AX
        RET


CHKMAP:
;Compare FAT and FATMAP looking for badsectors orphans
        MOV     SI,[FATMAP]
        INC     SI
        INC     SI
        MOV     DX,2
        MOV     CX,[DSIZE]
CHKMAPLP:
        LODSB
        OR      AL,AL
        JNZ     CONTLP          ;Already seen this one
        XCHG    SI,DX
        CALL    UNPACK
        XCHG    SI,DX
        JZ      CONTLP          ;Free cluster
        CMP     DI,0FF7H        ;Bad sector?
        JNZ     ORPHAN          ;No, found an orphan
        INC     [BADSIZ]
        MOV     BYTE PTR [SI-1],4       ;Flag it
        JMP     CONTLP
ORPHAN:
        INC     [ORPHSIZ]
        MOV     BYTE PTR [SI-1],8       ;Flag it
CONTLP:
        INC     DX              ;Next cluster
        LOOP    CHKMAPLP
        MOV     SI,[ORPHSIZ]
        OR      SI,SI
        JZ      RET18           ;No orphans
        CALL    RECOVER
RET18:  RET

RECOVER:
;free orphans or do chain recovery
        CALL    CHECKNOFMES
        CALL    DOCRLF
        CALL    CHAINREPORT
        MOV     DX,OFFSET DG:FREEMES
        CALL    PROMPTYN                ;Ask user
        JNZ     NOCHAINREC
        JMP     CHAINREC
NOCHAINREC:
        MOV     SI,[FATMAP]             ;Free all orphans
        INC     SI
        INC     SI
        MOV     DX,2
        MOV     CX,[DSIZE]
CHKMAPLP2:
        LODSB
        TEST    AL,8
        JZ      NEXTCLUS
        XCHG    SI,DX
        PUSH    DX
        XOR     DX,DX
        CALL    PACK            ;Mark as free
        POP     DX
        XCHG    SI,DX
NEXTCLUS:
        INC     DX
        LOOP    CHKMAPLP2
        XOR     AX,AX
        XCHG    AX,[ORPHSIZ]
        PUSH    AX
        MOV     DX,OFFSET DG:FREEBYMESF_PRE
        CMP     [DOFIX],0
        JNZ     PRINTFMES
        MOV     DX,OFFSET DG:FREEBYMES_PRE
PRINTFMES:
        CALL    PRINT
        POP     AX
        MOV     BX,OFFSET DG:FREEBYMESF_POST
        CMP     [DOFIX],0
        JNZ     DISPFRB
        MOV     BX,OFFSET DG:FREEBYMES_POST
        MOV     [LCLUS],AX
DISPFRB:
        CALL    DISPCLUS        ;Tell how much freed
        RET

FINDCHAIN:
;Do chain recovery on orphans
        MOV     SI,[FATMAP]
        INC     SI
        INC     SI
        MOV     DX,2
        MOV     CX,[DSIZE]
CHKMAPLP3:
        LODSB
        TEST    AL,8            ;Orphan?
        JZ      NEXTCLUS2       ;Nope
        TEST    AL,1            ;Seen before ?
        JNZ     NEXTCLUS2       ;Yup
        PUSH    SI              ;Save search environment
        PUSH    CX
        PUSH    DX
        DEC     SI
        OR      BYTE PTR [SI],81H       ;Mark as seen and head
        INC     [ORPHCNT]      ;Found a chain
        MOV     SI,DX
CHAINLP:
        CALL    UNPACK
        XCHG    SI,DI
        CMP     SI,0FF8H
        JAE     CHGOON          ;EOF
        PUSH    DI
        CMP     SI,2
        JB      INSERTEOF       ;Bad cluster number
        CMP     SI,[MCLUS]
        JA      INSERTEOF       ;Bad cluster number
        CMP     SI,DI
        JZ      INSERTEOF       ;Tight loop
        CALL    CROSSCHK
        TEST    AH,8            ;Points to a non-orphan?
        JNZ     CHKCHHEAD       ;Nope
INSERTEOF:
        POP     SI              ;Need to stick EOF here
        MOV     DX,0FFFH
        CALL    PACK
        JMP     SHORT CHGOON
CHKCHHEAD:
        TEST    AH,80H          ;Previosly marked head?
        JZ      ADDCHAIN        ;Nope
        AND     BYTE PTR [DI],NOT 80H   ;Turn off head bit
        DEC     [ORPHCNT]              ;Wasn't really a head
        POP     DI              ;Clean stack
        JMP     SHORT CHGOON
ADDCHAIN:
        TEST    AH,1            ;Previosly seen?
        JNZ     INSERTEOF       ;Yup, don't make a cross link
        OR      BYTE PTR [DI],1 ;Mark as seen
        POP     DI              ;Clean stack
        JMP     CHAINLP         ;Follow chain

CHGOON:
        POP     DX              ;Restore search
        POP     CX
        POP     SI
NEXTCLUS2:
        INC     DX
        LOOP    CHKMAPLP3
        RET

CHAINREC:
        LDS     DI,[THISDPB]
ASSUME  DS:NOTHING
        MOV     CX,[DI.dpb_root_entries]
        PUSH    CS
        POP     DS
ASSUME  DS:DG
        MOV     SI,[FATMAP]
        INC     SI
        INC     SI
        MOV     DI,1
        CALL    NEXTORPH
        PUSH    SI
        PUSH    DI
        MOV     SI,DI
        XOR     AX,AX
        MOV     DX,[ORPHCNT]
MAKFILLP:
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        CALL    GETENT
        POP     SI
        CMP     BYTE PTR [DI],0E5H
        JZ      GOTENT
        CMP     BYTE PTR [DI],0
        JNZ     NEXTENT
GOTENT:
        MOV     [HAVFIX],1      ;Making a fix
        CMP     [DOFIX],0
        JZ      ENTMADE         ;Not supposed to, carry clear
        MOV     [DI+26],SI      ;FIRCLUS Pointer
        PUSH    AX              ;Save INT 26 data
        PUSH    DX
        PUSH    BX
        MOV     AH,DISK_RESET        ;Force current state
        INT     21H
        MOV     DX,OFFSET DG:ORPHFCB
        MOV     AH,FCB_OPEN
OPAGAIN:
        INT     21H
        OR      AL,AL
        JNZ     GOTORPHNAM
        CALL    MAKORPHNAM                 ;Try next name
        JMP     SHORT OPAGAIN

GOTORPHNAM:
        MOV     SI,OFFSET DG:ORPHFCB + 1   ;ORPHFCB Now has good name
        MOV     CX,11
        REP     MOVSB
        CALL    MAKORPHNAM                 ;Make next name
        XOR     AX,AX
        MOV     CX,15
        REP     STOSB
        MOV     SI,[DI]
        INC     DI              ;Skip FIRCLUS
        INC     DI
        PUSH    DI
        CALL    GETFILSIZ
        POP     DI
        STOSW
        MOV     AX,DX
        STOSW
        POP     BX
        POP     DX
        POP     AX
        MOV     CX,1
        CALL    DOINT26
ENTMADE:
        POP     DX
        POP     CX
        POP     AX
        POP     DI
        POP     SI
        DEC     DX
        OR      DX,DX
        JZ      RET100
        CALL    NEXTORPH
        PUSH    SI
        PUSH    DI
        MOV     SI,DI
        JMP     SHORT NXTORP

NEXTENT:
        POP     DX
        POP     CX
        POP     AX
NXTORP:
        INC     AX
        LOOP    MAKFILLPJ
        POP     AX                      ;Clean Stack
        POP     AX
        SUB     [ORPHCNT],DX            ;Couldn't make them all
        MOV     DX,OFFSET DG:CREATMES
        CALL    EPRINT
RET100: RET

MAKFILLPJ: JMP  MAKFILLP

NEXTORPH:
        PUSH    AX
        LODSB
        INC     DI
        CMP     AL,89H
        POP     AX
        JZ      RET100
        JMP     SHORT NEXTORPH

MAKORPHNAM:
        PUSH    SI
        MOV     SI,OFFSET DG:ORPHEXT - 1
NAM0:
        INC     BYTE PTR [SI]
        CMP     BYTE PTR [SI],'9'
        JLE     NAMMADE
        MOV     BYTE PTR [SI],'0'
        DEC     SI
        JMP     NAM0

NAMMADE:
        POP     SI
        RET

GETFILSIZ:
;SI is start cluster, returns filesize as DX:AX
        XOR     AX,AX
NCLUS:
        CALL    UNPACK
        XCHG    SI,DI
        INC     AX
        CMP     SI,0FF8H
        JAE     GOTEOF
        CMP     SI,2
        JAE     NCLUS
GOTEOF:
        MOV     BL,[CSIZE]
        XOR     BH,BH
        MUL     BX
        MUL     [SSIZE]
        RET



CHKCROSS:
;Check for Crosslinks, do second pass if any to find pairs
        MOV     SI,[CROSSCNT]
        OR      SI,SI
        JZ      RET8            ;None
        CALL    DOCRLF
        INC     [SECONDPASS]
        XOR     AX,AX
        PUSH    AX
        PUSH    AX
        CALL    DIRPROC         ;Do it again
RET8:   RET

SUBTTL  AMDONE - Finish up routine
PAGE
AMDONE:
ASSUME  DS:NOTHING
        CMP     [DIRTYFAT],0
        JZ      NOWRITE         ;FAT not dirty
        CMP     [DOFIX],0
        JZ      NOWRITE         ;Not supposed to fix
REWRITE:
        LDS     BX,[THISDPB]
ASSUME  DS:NOTHING
        MOV     CL,[BX.dpb_FAT_size]          ;Sectors for one fat
        XOR     CH,CH
        MOV     DI,CX
        MOV     CL,[BX.dpb_FAT_count]          ;Number of FATs
        MOV     DX,[BX.dpb_first_FAT]          ;First sector of FAT
        PUSH    CS
        POP     DS
ASSUME  DS:DG
        MOV     [ERRCNT],CH
        MOV     BX,OFFSET DG:FAT
        MOV     AL,[ALLDRV]
        DEC     AL
        MOV     AH,'1'
        PUSH    CX
WRTLOOP:
        XCHG    CX,DI
        PUSH    DX
        PUSH    CX
        PUSH    DI
        PUSH    AX
        INT     26H                     ;Write out the FAT
        MOV     [HECODE],AL
        POP     AX                      ;Flags
        JNC     WRTOK
        INC     [ERRCNT]
        MOV     DX,OFFSET DG:BADWRITE_PRE
        CALL    PRINT
        POP     AX
        PUSH    AX
        MOV     DL,AH
        CALL    PRTCHR
        MOV     DX,OFFSET DG:BADWRITE_POST
        CALL    PRINT
WRTOK:
        POP     AX
        POP     CX
        POP     DI
        POP     DX
        INC     AH
        ADD     DX,DI
        LOOP    WRTLOOP         ;Next FAT
        POP     CX              ;Number of FATs
        CMP     CL,[ERRCNT]     ;Error on all?
        JNZ     NOWRITE         ;no
        CALL    WDSKERR
        JZ      REWRITE
NOWRITE:
        MOV     AH,DISK_RESET        ;Invalidate any buffers in system
        INT     21H
        MOV     DX,OFFSET DG:USERDIR    ;Recover users directory
        MOV     AH,CHDIR
        INT     21H
        CMP     BYTE PTR [FRAGMENT],1   ;Check for any fragmented files?
        JNZ     DONE                    ;No -- we're finished
        CALL    CHECKFILES              ;Yes -- report any fragments
DONE:
ASSUME  DS:NOTHING
        MOV     DL,[USERDEV]    ;Recover users drive
        MOV     AH,SET_DEFAULT_DRIVE
        INT     21H
        RET

SUBTTL  Routines for manipulating dir entries
PAGE
FIXENT2:
;Same as FIXENT only [SRFCBPT] points to the search FCB, BX points to the entry
        PUSH    SI
        PUSH    BX
        PUSH    CX
        MOV     SI,BX
        MOV     BX,[SRFCBPT]
        CALL    FIXENT
        POP     CX
        POP     BX
        POP     SI
RET20:  RET

FIXENT:
;BX Points to search FCB
;SI Points to Entry to fix
        MOV     [HAVFIX],1      ;Indicate a fix
        CMP     [DOFIX],0
        JZ      RET20           ;But don't do it!
        PUSH    BP
        PUSH    BX
        PUSH    SI
        PUSH    SI              ;Entry pointer
        MOV     AX,[BX+THISENT]         ;Entry number
        CALL    GETENT
        POP     SI              ;Entry pointer
        ADD     SI,DIRNAM       ;Point to start of entry
        MOV     CX,32
        REP     MOVSB
        INC     CL
        CALL    DOINT26
        POP     SI
        POP     BX
        POP     BP
        RET

GETENT:
;AX is desired entry number (in current directory)
;
;DI points to entry in SECBUF
;AX DX BX set to do an INT 26 to write it back out (CX must be reset to 1)
;ALL registers destroyed (via int 25)
        LDS     DI,[THISDPB]
ASSUME  DS:NOTHING
        MOV     BX,[DI.dpb_current_dir]
        PUSH    CS
        POP     DS
ASSUME  DS:DG
        CMP     BX,0FF8H
        JB      CLUSISOK
        MOV     BX,OFFSET DG:BADDPBDIR          ;This should never happen
        JMP     FATAL
CLUSISOK:
        MOV     CL,4
        SHL     AX,CL
        XOR     DX,DX
        SHL     AX,1
        RCL     DX,1                    ;Account for overflow
        MOV     CX,[SSIZE]
        AND     CL,255-31               ;Must be a multiple of 32
        DIV     CX              ;DX is position in sector, AX is dir sector #
        OR      BX,BX
        JZ      WANTROOT
        DIV     [CSIZE]         ;AL # clusters to skip, AH position in cluster
        MOV     CL,AL
        XOR     CH,CH
        JCXZ    GOTCLUS
        MOV     SI,BX
SKIPLP:
        CALL    UNPACK
        XCHG    SI,DI
        LOOP    SKIPLP
        MOV     BX,SI
GOTCLUS:
        PUSH    DX              ;Position in sector
        CALL    FIGREC          ;Convert to sector #
DOROOTDIR:
        MOV     BX,[SECBUF]
        MOV     AL,[ALLDRV]
        DEC     AL
RDRETRY:
        PUSH    AX
        PUSH    DX
        PUSH    BX
        MOV     CX,1
        INT     25H             ;Read it
        MOV     [HECODE],AL
        POP     AX              ;FLAGS
        POP     BX
        POP     DX
        POP     AX
        JNC     RDOK2
        CALL    RDSKERR
        JZ      RDRETRY
RDOK2:
        POP     DI              ;Offset into sector
        ADD     DI,BX           ;Add sector base offset
        RET

WANTROOT:
        PUSH    DX
        LDS     DI,[THISDPB]
ASSUME  DS:NOTHING
        MOV     DX,AX
        ADD     DX,[DI.dpb_dir_sector]
        PUSH    CS
        POP     DS
ASSUME  DS:DG
        JMP     DOROOTDIR

CHECKNOFMES:
        MOV     AL,1
        XCHG    AL,[FIXMFLG]
        OR      AL,AL
        JNZ     RET14           ;Don't print it more than once
        CMP     [DOFIX],0
        JNZ     RET14           ;Don't print it if F switch specified
        PUSH    DX
        MOV     DX,OFFSET DG:FIXMES
        CALL    PRINT
        POP     DX
        RET

CHECKERR:
        CALL    CHECKNOFMES
        CMP     [SECONDPASS],0
RET14:  RET

PRINTCURRDIRERR:
        CALL    CHECKERR
        JNZ     RET14
        CALL    PRINTCURRDIR
        JMP     SHORT ERREX

PRINTTHISELERR:
        CALL    CHECKERR
        JNZ     RET14
        CALL    PRINTTHISEL
ERREX:
        CALL    DOCRLF
        RET

PRINTTHISEL:
        MOV     SI,BX
        ADD     SI,DIRNAM
PRINTTHISEL2:
        MOV     DI,OFFSET DG:NAMBUF
        PUSH    DI
        CALL    FCB_TO_ASCZ
        POP     SI
PRINTCURRDIR:
        PUSH    SI
        MOV     DL,[ALLDRV]
        ADD     DL,'@'
        CALL    PRTCHR
        MOV     DL,DRVCHAR
        CALL    PRTCHR
        LDS     SI,[THISDPB]
ASSUME  DS:NOTHING
        CMP     [SI.dpb_current_dir],0
        JZ      CURISROOT
        MOV     DL,[DIRCHAR]
        CALL    PRTCHR
        ADD     SI,dpb_dir_text
PCURRLP:
        LODSB
        OR      AL,AL
        JZ      CURISROOT
        MOV     DL,AL
        CALL    PRTCHR
        JMP     PCURRLP

CURISROOT:
        PUSH    CS
        POP     DS
ASSUME  DS:DG
        POP     SI
        CMP     BYTE PTR [SI],0
        JZ      LPDONE          ;If tail string NUL, no '/'
        MOV     DL,[DIRCHAR]
        CALL    PRTCHR
ERRLOOP:
        LODSB
        OR      AL,AL
        JZ      LPDONE
        MOV     DL,AL
        CALL    PRTCHR
        JMP     ERRLOOP
LPDONE:
        RET

FATAL:
;Unrecoverable error
        MOV     DX,OFFSET DG:FATALMES
        CALL    PRINT
        MOV     DX,BX
        CALL    PRINT
        MOV     DL,[USERDEV]            ;At least leave on same drive
        MOV     AH,SET_DEFAULT_DRIVE
        INT     21H
        INT     20H


INT_24_RETADDR  DW      OFFSET DG:INT_24_BACK

INT_24  PROC    FAR
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        PUSHF
        PUSH    CS
        PUSH    [INT_24_RETADDR]
        PUSH    WORD PTR [HARDCH+2]
        PUSH    WORD PTR [HARDCH]
        RET
INT_24  ENDP

INT_24_BACK:
        CMP     AL,2            ;Abort?
        JNZ     IRETI
        CALL    DONE            ;Forget about directory, restore users drive
        INT     20H
IRETI:
        IRET

INT_23:
        LDS     DX,[HARDCH]
        MOV     AX,(SET_INTERRUPT_VECTOR SHL 8) OR 24H
        INT     21H
        LDS     DX,[CONTCH]
        MOV     AX,(SET_INTERRUPT_VECTOR SHL 8) OR 23H
        INT     21H
        PUSH    CS
        POP     DS
ASSUME  DS:DG
        MOV     [FRAGMENT],0
RDONE:
        CALL    NOWRITE         ;Restore users drive and directory
        INT     20H

CODE    ENDS
        END     CHKPROC
                                                                                       