        title   EDLIN for MSDOS 2.0

;-----------------------------------------------------------------------;
;               REVISION HISTORY:                                       ;
;                                                                       ;
;       V1.02                                                           ;
;                                                                       ;
;       V2.00   9/13/82  M.A. Ulloa                                     ;
;                  Modified to use Pathnames in command line file       ;
;               specification, modified REPLACE to use an empty         ;
;               string intead of the old replace string when this       ;
;               is missing, and search and replace now start from       ;
;               first line of buffer (like old version of EDLIN)        ;
;               instead than current+1 line. Also added the U and       ;
;               V commands that search (replace) starting from the      ;
;               current+1 line.                                         ;
;                                                                       ;
;               9/15/82  M.A. Ulloa                                     ;
;                  Added the quote character (^V).                      ;
;                                                                       ;
;               9/16/82  M.A. Ulloa                                     ;
;                  Corrected bug about use of quote char when going     ;
;               into default insert mode. Also corrected the problem    ;
;               with ^Z being the end of file marker. End of file is    ;
;               reached when an attempt to read returns less chars      ;
;               than requested.                                         ;
;                                                                       ;
;               9/17/82  M.A. Ulloa                                     ;
;                  Corrected bug about boundaries for Copy              ;
;                                                                       ;
;               10/4/82  Rev. 1         M.A. Ulloa                      ;
;                  The IBM version now does NOT have the U and V        ;
;               commands. The MSDOS version HAS the U and V commands.   ;
;                  Added the B switch, and modified the effect of       ;
;               the quote char.                                         ;
;                                                                       ;
;               10/7/82  Rev. 2         M.A. Ulloa                      ;
;                  Changed the S and R commands to start from the       ;
;               current line+1 (as U and V did). Took away U and V in   ;
;               all versions.                                           ;
;                                                                       ;
;               10/13/82 Rev. 3         M.A. Ulloa                      ;
;                  Now if parameter1 < 1 then parameter1 = 1            ;
;                                                                       ;
;               10/15/82 Rev. 4         M.A. Ulloa                      ;
;                  Param4 if specified must be an absolute number that  ;
;               reprecents the count.                                   ;
;                                                                       ;
;               10/18/82 Rev. 5         M.A. Ulloa                      ;
;                  Fixed problem with trying to edit files with the     ;
;               same name as directories. Also, if the end of file is   ;
;               reached it checks that a LF is the last character,      ;
;               otherwise it inserts a CRLF pair at the end.            ;
;                                                                       ;
;               10/20/82 Rev. 6         M.A.Ulloa                       ;
;                  Changed the text of some error messages for IBM and  ;
;               rewrite PAGE.                                           ;
;                                                                       ;
;               10/25/82 Rev. 7         M.A.Ulloa                       ;
;                  Made all messages as in the IBM vers.                ;
;                                                                       ;
;               10/28/82 Rev. 8         M.A.Ulloa                       ;
;                  Corrected problem with parsing for options.          ;
;                                                                       ;
;                        Rev. 9         Aaron Reynolds                  ;
;                  Made error messages external.                        ;
;                                                                       ;
;               12/08/82 Rev. 10        M.A. Ulloa                      ;
;                  Corrected problem arising with having to restore     ;
;               the old directory in case of a file name error.         ;
;                                                                       ;
;               12/17/82 Rev. 11        M.A. Ulloa                      ;
;                  Added the ROPROT equate for R/O file protection.     ;
;               It causes only certain operations (L,P,S,W,A, and Q)    ;
;               to be allowed on read only files.                       ;
;                                                                       ;
;               12/29/82 Rev. 12        M.A. Ulloa                      :
;                  Added the creation error message.                    ;
;                                                                       ;
;               4/14/83  Rev. 13        N.Panners                       ;
;                  Fixed bug in Merge which lost char if not ^Z.        ;
;                  Fixed bug in Copy to correctly check                 ;
;                  for full buffers.                                    ;
;                                                                       ;
;                                                                       ;
;               7/23/83 Rev. 14         N.Panners                       ;
;                   Split EDLIN into two seperate modules to            ;
;                   allow assembly of sources on an IBM PC              ;
;                   EDLIN and EDLPROC                                   ;
;                                                                       ;
;-----------------------------------------------------------------------;


FALSE   EQU     0
TRUE    EQU     NOT FALSE

KANJI   EQU     FALSE

roprot  equ     true            ;set to TRUE if protection to r/o files
                                ; desired.
FCB     EQU     5CH

Comand_Line_Length equ 128
quote_char equ  16h             ;quote character = ^V


PAGE

        .xlist
        INCLUDE DOSSYM.ASM
        .list


SUBTTL  Contants and Data areas
PAGE

PROMPT  EQU     "*"
STKSIZ  EQU     80H

CODE    SEGMENT PUBLIC
CODE    ENDS

CONST   SEGMENT PUBLIC WORD
CONST   ENDS

DATA    SEGMENT PUBLIC WORD
DATA    ENDS

DG      GROUP   CODE,CONST,DATA

CONST   SEGMENT PUBLIC WORD

        EXTRN   BADDRV:BYTE,NDNAME:BYTE,bad_vers_err:BYTE,opt_err:BYTE
        EXTRN   NOBAK:BYTE,BADCOM:BYTE,NEWFIL:BYTE,DEST:BYTE,MRGERR:BYTE
        EXTRN   NODIR:BYTE,DSKFUL:BYTE,MEMFUL:BYTE,FILENM:BYTE
        EXTRN   NOSUCH:BYTE,TOOLNG:BYTE,EOF:BYTE,ro_err:byte,bcreat:byte

        PUBLIC  TXT1,TXT2,FUDGE,USERDIR,HARDCH

BAK     DB      "BAK"

make    db      "***MAUlloa/Microsoft/V20***"
rev     db      "14"

        if      roprot                  ;***** R/O *****
roflag  db      0                       ; =1 if file is r/o
        endif

fourth  db      0                       ;fourth parameter flag

loadmod db      0                       ;Load mode flag, 0 = ^Z marks the
                                        ; end of a file, 1 = viceversa.
hardch  dd      ?

the_root db     0                       ;root directory flag

fudge   db      0                       ;directory changed flag
user_drive db   0


optchar db      "-"

dirchar db      "/",0

userdir db      "/",0
        db      (dirstrlen) dup(0)

fname_buffer db Comand_Line_Length dup(0)
;-----------------------------------------------------------------------;

TXT1    DB      0,80H DUP (?)
TXT2    DB      0,80H DUP (?)
DELFLG  DB      0

CONST   ENDS

DATA    SEGMENT PUBLIC WORD

        PUBLIC  QFLG,FCB2,OLDLEN,PARAM1,PARAM2,OLDDAT,SRCHFLG
        PUBLIC  COMLINE,NEWLEN,SRCHMOD,CURRENT,LSTFND,NUMPOS
        PUBLIC  LSTNUM,SRCHCNT,POINTER,START,ENDTXT,USER_DRIVE

;-----------------------------------------------------------------------;
;    Be carefull when adding parameters, they have to follow the
; order in which they apperar here. (this is a table, ergo it
; is indexed thru a pointer, and random additions will cause the
; wrong item to be accessed). Also param4 is known to be the
; count parameter, and known to be the fourth entry in the table
; so it receives special treatment. (See GETNUM)

PARAM1  DW      1 DUP (?)
PARAM2  DW      1 DUP (?)
PARAM3  DW      1 DUP (?)
PARAM4  DW      1 DUP (?)

;-----------------------------------------------------------------------;

PTR_1   DW      1 DUP (?)
PTR_2   DW      1 DUP (?)
PTR_3   DW      1 DUP (?)
COPYSIZ DW      1 DUP (?)
OLDLEN  DW      1 DUP (?)
NEWLEN  DW      1 DUP (?)
LSTFND  DW      1 DUP (?)
LSTNUM  DW      1 DUP (?)
NUMPOS  DW      1 DUP (?)
SRCHCNT DW      1 DUP (?)
CURRENT DW      1 DUP (?)
POINTER DW      1 DUP (?)
ONE4TH  DW      1 DUP (?)
THREE4TH DW     1 DUP (?)
LAST    DW      1 DUP (?)
ENDTXT  DW      1 DUP (?)
COMLINE DW      1 DUP (?)
LASTLIN DW      1 DUP (?)
COMBUF  DB      82H DUP (?)
EDITBUF DB      258 DUP (?)
EOL     DB      1 DUP (?)
FCB2    DB      37 DUP (?)
FCB3    DB      37 DUP (?)
fake_fcb db     37 dup (?)              ;fake for size figuring
QFLG    DB      1 DUP (?)
HAVEOF  DB      1 DUP (?)
ENDING  DB      1 DUP (?)
SRCHFLG DB      1 DUP (?)
amnt_req dw     1 dup (?)               ;ammount of bytes requested to read
olddat  db      1 dup (?)               ;Used in replace and search,
                                        ; replace by old data flag (1=yes)
srchmod db      1 dup (?)               ;Search mode: 1=from current+1 to
                                        ; end of buffer, 0=from beg. of
                                        ; buffer to the end (old way).
MOVFLG  DB      1 DUP (?)
        DB      STKSIZ DUP (?)

STACK   LABEL   BYTE
START   LABEL   WORD

DATA    ENDS

SUBTTL  Main Body
PAGE

CODE SEGMENT PUBLIC

ASSUME  CS:DG,DS:DG,SS:DG,ES:DG

        EXTRN   QUIT:NEAR,QUERY:NEAR,FNDFIRST:NEAR,FNDNEXT:NEAR
        EXTRN   UNQUOTE:NEAR,LF:NEAR,CRLF:NEAR,OUT:NEAR
        EXTRN   REST_DIR:NEAR,KILL_BL:NEAR,INT_24:NEAR
        EXTRN   FINDLIN:NEAR,SHOWNUM:NEAR,SCANLN:NEAR

        if  Kanji
        EXTRN   TESTKANJ:NEAR
        endif

        PUBLIC  CHKRANGE

        ORG     100H

EDLIN:
        JMP     SIMPED

edl_pad db      0e00h dup (?)

HEADER  DB      "Vers 2.14"

NONAME:
        MOV     DX,OFFSET DG:NDNAME
ERRJ:   JMP     xERROR

SIMPED:
        MOV     BYTE PTR [ENDING],0
        MOV     SP,OFFSET DG:STACK

;Code to print header
;       PUSH    AX
;       MOV     DX,OFFSET DG:HEADER
;       MOV     AH,STD_CON_STRING_OUTPUT
;       INT     21H
;       POP     AX

;----- Check Version Number --------------------------------------------;
        push    ax
        mov     ah,Get_Version
        int     21h
        cmp     al,2
        jae     vers_ok                         ; version >= 2, enter editor
        mov     dx,offset dg:bad_vers_err
        jmp     short errj
;-----------------------------------------------------------------------;

vers_ok:

;----- Process Pathnames -----------------------------------------------;

        mov     ax,(char_oper shl 8)    ;get switch character
        int     21h
        cmp     dl,"/"
        jnz     slashok                 ;if not / , then not PC
        mov     [dirchar],"\"           ;in PC, dir separator = \
        mov     [userdir],"\"
        mov     [optchar],"/"           ;in PC, option char = /

slashok:
        mov     si,81h                  ;point to cammand line

        call    kill_bl
        cmp     al,13                   ;A carriage return?
        je      noname                  ;yes, file name missing

        mov     di,offset dg:fname_buffer
        xor     cx,cx                   ;zero pathname length

next_char:
        stosb                           ;put patname in buffer
        inc     cx
        lodsb
        cmp     al,' '
        je      xx1
        cmp     al,13                   ; a CR ?
        je      name_copied
        cmp     al,[optchar]            ; an option character?
        je      an_option
        jmp     short next_char

xx1:
        dec     si
        call    kill_bl
        cmp     al,[optchar]
        jne     name_copied

an_option:
        lodsb                           ;get the option
        cmp     al,'B'
        je      b_opt
        cmp     al,'b'
        je      b_opt
        mov     dx,offset dg:opt_err    ;bad option specified
        jmp     xerror

b_opt:
        mov     [loadmod],1

name_copied:
        mov     byte ptr dg:[di],0      ;nul terminate the pathname

        if      roprot                  ;***** R/O *****
;----- Check that file is not R/O --------------------------------------;
        push    cx                      ;save character count
        mov     dx,offset dg:fname_buffer
        mov     al,0                    ;get attributes
        mov     ah,chmod
        int     21h
        jc      attr_are_ok
        and     cl,00000001b            ;mask all but: r/o
        jz      attr_are_ok             ;if all = 0 then file ok to edit,
        mov     dg:[roflag],01h         ;otherwise: Error (GONG!!!)
attr_are_ok:
        pop     cx                      ;restore character count
        endif

;----- Scan for directory ----------------------------------------------;
        dec     di                      ;adjust to the end of the pathname

        IF      KANJI
        mov     dx,offset dg: fname_buffer
        PUSH    DX
        PUSH    DI
        MOV     BX,DI
        MOV     DI,DX
DELLOOP:
        CMP     DI,BX
        Jae     GOTDELE
        MOV     AL,[DI]
        INC     DI
        CALL    TESTKANJ
        JZ      NOTKANJ11
        INC     DI
        JMP     DELLOOP

NOTKANJ11:
        cmp     al,dg:[dirchar]
        JNZ     DELLOOP
        MOV     DX,DI           ;Point to char after '/'
        DEC     DX
        DEC     DX              ;Point to char before '/'
        JMP     DELLOOP

GOTDELE:
        MOV     DI,DX
        POP     AX              ;Initial DI
        POP     DX
        SUB     AX,DI           ;Distance moved
        SUB     CX,AX           ;Set correct CX
        CMP     DX,DI
        JB      sj1             ;Found a pathsep
        JA      sj2             ;Started with a pathsep, root
        MOV     AX,[DI]
        CALL    TESTKANJ
        JNZ     same_dirj
        XCHG    AH,AL
        cmp     al,dg:[dirchar]
        jz      sj1             ;One character directory
same_dirj:
        ELSE
        mov     al,dg:[dirchar]         ;get directory separator character
        std                             ;scan backwards
        repnz   scasb                   ;(cx has the pathname length)
        cld                             ;reset direction, just in case
        jz      sj1
        ENDIF

        jmp     same_dir                ;no dir separator char. found, the
                                        ; file is in the current directory
                                        ; of the corresponding drive. Ergo,
                                        ; the FCB contains the data already.

sj1:
        jcxz    sj2                     ;no more chars left, it refers to root
        cmp     byte ptr [di],':'       ;is the prvious character a disk def?
        jne     not_root
sj2:
        mov     dg:[the_root],01h       ;file is in the root
not_root:
        inc     di                      ;point to dir separator char.
        mov     al,0
        stosb                           ;nul terminate directory name
        pop     ax
        push    di                      ;save pointer to file name
        mov     dg:[fudge],01h          ;remember that the current directory
                                        ; has been changed.

;----- Save current directory for exit ---------------------------------;
        mov     ah,get_default_drive    ;save current drive
        int     21h
        mov     dg:[user_drive],al

        mov     dl,byte ptr ds:[fcb]    ;get specified drive if any
        or      dl,dl                   ;default disk?
        jz      same_drive
        dec     dl                      ;adjust to real drive (a=0,b=1,...)
        mov     ah,set_default_drive    ;change disks
        int     21h
        cmp     al,-1                   ;error?
        jne     same_drive
        mov     dx,offset dg:baddrv
        jmp     xerror

same_drive:
        mov     ah,get_default_dpb
        int     21h

assume  ds:nothing

        cmp     al,-1                   ;bad drive? (should always be ok)
        jne     drvisok
        mov     dx,offset dg:baddrv
        jmp     xerror

drvisok:
        cmp     [bx.dpb_current_dir],0
        je      curr_is_root
        mov     si,bx
        add     si,dpb_dir_text
        mov     di,offset dg:userdir + 1

dir_save_loop:
        lodsb
        stosb
        or      al,al
        jnz     dir_save_loop

curr_is_root:
        push    cs
        pop     ds

assume  ds:dg


;----- Change directories ----------------------------------------------;
        cmp     [the_root],01h
        mov     dx,offset dg:[dirchar]         ;assume the root
        je      sj3
        mov     dx,offset dg:[fname_buffer]
sj3:
        mov     ah,chdir                        ;change directory
        int     21h
        mov     dx,offset dg:baddrv
        jnc     no_errors
        jmp     xerror
no_errors:

;----- Set Up int 24 intercept -----------------------------------------;

        mov     ax,(get_interrupt_vector shl 8) or 24h
        int     21h
        mov     word ptr [hardch],bx
        mov     word ptr [hardch+2],es
        mov     ax,(set_interrupt_vector shl 8) or 24h
        mov     dx,offset dg:int_24
        int     21h
        push    cs
        pop     es

;----- Parse filename to FCB -------------------------------------------;
        pop     si
        mov     di,fcb
        mov     ax,(parse_file_descriptor shl 8) or 1
        int     21h
        push    ax

;-----------------------------------------------------------------------;

same_dir:
        pop     ax
        OR      AL,AL
        MOV     DX,OFFSET DG:BADDRV
        jz      sj4
        jmp     xerror
sj4:
        CMP     BYTE PTR DS:[FCB+1]," "
        jnz     sj5
        jmp     noname
sj5:
        MOV     SI,OFFSET DG:BAK
        MOV     DI,FCB+9
        MOV     CX,3
        ;File must not have .BAK extension
        REPE    CMPSB
        JZ      NOTBAK
        ;Open input file
        MOV     AH,FCB_OPEN
        MOV     DX,FCB
        INT     21H
        MOV     [HAVEOF],AL
        OR      AL,AL
        JZ      HAVFIL

;----- Check that file is not a directory ------------
        mov     ah,fcb_create
        mov     dx,fcb
        int     21h
        or      al,al
        jz      sj50                    ;no error found
        mov     dx,offset dg:bcreat     ;creation error
        jmp     xerror
sj50:
        mov     ah,fcb_close            ;no error, close the file
        mov     dx,fcb
        int     21h
        mov     ah,fcb_delete           ;delete the file
        mov     dx,fcb
        int     21h

;-----------------------------------------------------

        MOV     DX,OFFSET DG:NEWFIL
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
HAVFIL:
        MOV     SI,FCB
        MOV     DI,OFFSET DG:FCB2
        MOV     CX,9
        REP     MOVSB
        MOV     AL,"$"
        STOSB
        STOSB
        STOSB
MAKFIL:
        ;Create .$$$ file to make sure directory has room
        MOV     DX,OFFSET DG:FCB2
        MOV     AH,FCB_CREATE
        INT     21H
        OR      AL,AL
        JZ      SETUP
        CMP     BYTE PTR [DELFLG],0
        JNZ     NOROOM
        CALL    DELBAK
        JMP     MAKFIL
NOROOM:
        MOV     DX,OFFSET DG:NODIR
        JMP     xERROR
NOTBAK:
        MOV     DX,OFFSET DG:NOBAK
        JMP     xERROR
SETUP:
        XOR     AX,AX
        MOV     WORD PTR DS:[FCB+fcb_RR],AX         ;Set RR field to zero
        MOV     WORD PTR DS:[FCB+fcb_RR+2],AX
        MOV     WORD PTR [FCB2+fcb_RR],AX
        MOV     WORD PTR [FCB2+fcb_RR+2],AX
        INC     AX
        MOV     WORD PTR DS:[FCB+fcb_RECSIZ],AX         ;Set record length to 1
        MOV     WORD PTR [FCB2+fcb_RECSIZ],AX
        MOV     DX,OFFSET DG:START
        MOV     DI,DX
        MOV     AH,SET_DMA
        INT     21H
        MOV     CX,DS:[6]
        DEC     CX
        MOV     [LAST],CX
        TEST    BYTE PTR [HAVEOF],-1
        JNZ     SAVEND
        SUB     CX,OFFSET DG:START      ;Available memory
        SHR     CX,1            ;1/2 of available memory
        MOV     AX,CX
        SHR     CX,1            ;1/4 of available memory
        MOV     [ONE4TH],CX     ;Save amount of 1/4 full
        ADD     CX,AX           ;3/4 of available memory
        MOV     DX,CX
        ADD     DX,OFFSET DG:START
        MOV     [THREE4TH],DX   ;Save pointer to 3/4 full
        ;Read in input file
        MOV     DX,FCB
        MOV     AH,FCB_RANDOM_READ_BLOCK
        mov     [amnt_req],cx   ;save ammount of chars requested
        INT     21H
        CALL    SCANEOF
        ADD     DI,CX           ;Point to last byte
SAVEND:
        CLD
        MOV     BYTE PTR [DI],1AH
        MOV     [ENDTXT],DI
        MOV     BYTE PTR [COMBUF],128
        MOV     BYTE PTR [EDITBUF],255
        MOV     BYTE PTR [EOL],10
        MOV     [POINTER],OFFSET DG:START
        MOV     [CURRENT],1
        MOV     [PARAM1],1
        TEST    BYTE PTR [HAVEOF],-1
        JNZ     COMMAND
        CALL    APPEND

COMMAND:
        MOV     SP, OFFSET DG:STACK
        MOV     AX,(SET_INTERRUPT_VECTOR SHL 8) OR 23H
        MOV     DX,OFFSET DG:ABORTCOM
        INT     21H
        MOV     AL,PROMPT
        CALL    OUT
        MOV     DX,OFFSET DG:COMBUF
        MOV     AH,STD_CON_STRING_INPUT
        INT     21H
        MOV     [COMLINE],OFFSET DG:COMBUF + 2
        MOV     AL,10
        CALL    OUT
PARSE:
        MOV     [PARAM2],0
        MOV     [PARAM3],0
        MOV     [PARAM4],0
        mov     [fourth],0              ;reset the fourth parameter flag
        MOV     BYTE PTR [QFLG],0
        MOV     SI,[COMLINE]
        MOV     BP,OFFSET DG:PARAM1
        XOR     DI,DI
CHKLP:
        CALL    GETNUM
        MOV     [BP+DI],DX
        INC     DI
        INC     DI
        CALL    SKIP1
        CMP     AL,","
        JNZ     CHKNXT
        INC     SI
CHKNXT:
        DEC     SI
        CMP     DI,8
        JB      CHKLP
        CALL    SKIP
        CMP     AL,"?"
        JNZ     DISPATCH
        MOV     [QFLG],AL
        CALL    SKIP
DISPATCH:
        CMP     AL,5FH
        JBE     UPCASE
        AND     AL,5FH
UPCASE:
        MOV     DI,OFFSET DG:COMTAB
        MOV     CX,NUMCOM
        REPNE   SCASB
        JNZ     COMERR
        MOV     BX,CX
        MOV     AX,[PARAM2]
        OR      AX,AX
        JZ      PARMOK
        CMP     AX,[PARAM1]
        JB      COMERR          ;Param. 2 must be >= param 1
PARMOK:
        MOV     [COMLINE],SI

        if      roprot                          ;***** R/O *****
        cmp     [roflag],01                     ;file r/o?
        jne     paramok2
        cmp     byte ptr [bx+rotable],01        ;operation allowed?
        je      paramok2
        mov     dx,offset dg:ro_err             ;error
        jmp     short comerr1
paramok2:
        endif

        SHL     BX,1
        CALL    [BX+TABLE]
COMOVER:
        MOV     SI,[COMLINE]
        CALL    SKIP
        CMP     AL,0DH
        JZ      COMMANDJ
        CMP     AL,1AH
        JZ      DELIM
        CMP     AL,";"
        JNZ     NODELIM
DELIM:
        INC     SI
NODELIM:
        DEC     SI
        MOV     [COMLINE],SI
        JMP     PARSE

COMMANDJ:
        JMP     COMMAND

SKIP:
        LODSB
SKIP1:
        CMP     AL," "
        JZ      SKIP
RET1:   RET

CHKRANGE:
        CMP     [PARAM2],0
        JZ      RET1
        CMP     BX,[PARAM2]
        JBE     RET1
COMERR:
        MOV     DX,OFFSET DG:BADCOM
COMERR1:
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
        JMP     COMMAND


GETNUM:
        CALL    SKIP
        cmp     di,6            ;Is this the fourth parameter?
        jne     sk1
        mov     [fourth],1      ;yes, set the flag
sk1:
        CMP     AL,"."
        JZ      CURLIN
        CMP     AL,"#"
        JZ      MAXLIN
        CMP     AL,"+"
        JZ      FORLIN
        CMP     AL,"-"
        JZ      BACKLIN
        MOV     DX,0
        MOV     CL,0            ;Flag no parameter seen yet
NUMLP:
        CMP     AL,"0"
        JB      NUMCHK
        CMP     AL,"9"
        JA      NUMCHK
        CMP     DX,6553         ;Max line/10
        JAE     COMERR          ;Ten times this is too big
        MOV     CL,1            ;Parameter digit has been found
        SUB     AL,"0"
        MOV     BX,DX
        SHL     DX,1
        SHL     DX,1
        ADD     DX,BX
        SHL     DX,1
        CBW
        ADD     DX,AX
        LODSB
        JMP     SHORT NUMLP
NUMCHK:
        CMP     CL,0
        JZ      RET1
        OR      DX,DX
        JZ      COMERR          ;Don't allow zero as a parameter
        RET

CURLIN:
        cmp     [fourth],1      ;the fourth parameter?
        je      comerra         ;yes, an error
        MOV     DX,[CURRENT]
        LODSB
        RET
MAXLIN:
        cmp     [fourth],1      ;the fourth parameter?
        je      comerra         ;yes, an error
        MOV     DX,-2
        LODSB
        RET
FORLIN:
        cmp     [fourth],1      ;the fourth parameter?
        je      comerra         ;yes, an error
        CALL    GETNUM
        ADD     DX,[CURRENT]
        RET
BACKLIN:
        cmp     [fourth],1      ;the fourth parameter?
        je      comerra         ;yes, an error
        CALL    GETNUM
        MOV     BX,[CURRENT]
        SUB     BX,DX
        jns     sk2     ;if below beg of buffer then default to the
        mov     bx,1    ; beg of buffer (line1)
sk2:
        MOV     DX,BX
        RET

comerra:
        jmp     comerr


COMTAB  DB      "QTCMWASRDLPIE;",13

NUMCOM  EQU     $-COMTAB

;-----------------------------------------------------------------------;
;       Carefull changing the order of the next two tables. They are
;      linked and chnges should be be to both.

TABLE   DW      NOCOM   ;No command--edit line
        DW      NOCOM
        DW      ENDED
        DW      INSERT
        DW      PAGE
        DW      LIST
        DW      DELETE
        dw      replac_from_curr        ;replace from current+1 line
        dw      search_from_curr        ;search from current+1 line
        DW      APPEND
        DW      EWRITE
        DW      MOVE
        DW      COPY
        DW      MERGE

        if      roprot                  ;***** R/O *****
        DW      QUIT1
        else
        DW      QUIT
        endif

        if      roprot                  ;***** R/O *****
;-----------------------------------------------------------------------;
;       If = 1 then the command can be executed with a file that
;      is r/o. If = 0 the command can not be executed, and error.

ROTABLE db      0               ;NOCOM
        db      0               ;NOCOM
        db      0               ;ENDED
        db      0               ;INSERT
        db      1               ;PAGE
        db      1               ;LIST
        db      0               ;DELETE
        db      0               ;replac_from_curr
        db      1               ;search_from_curr
        db      1               ;APPEND
        db      1               ;EWRITE
        db      0               ;MOVE
        db      0               ;COPY
        db      0               ;MERGE
        db      1               ;QUIT

;-----------------------------------------------------------------------;
        endif

        if      roprot                  ;***** R/O *****
quit1:
        cmp     [roflag],01             ;are we in r/o mode?
        jne     q3                      ;no query....
        MOV     DX,OFFSET DG:FCB2       ;yes, quit without query.
        MOV     AH,FCB_CLOSE
        INT     21H
        MOV     AH,FCB_DELETE
        INT     21H
        call    rest_dir                ;restore directory if needed
        INT     20H
q3:
        call    quit
        endif

SCANEOF:
        cmp     [loadmod],0
        je      sj52

;----- Load till physical end of file
        cmp     cx,word ptr[amnt_req]
        jb      sj51
        xor     al,al
        inc     al              ;reset zero flag
        ret
sj51:
        jcxz    sj51b
        push    di              ;get rid of any ^Z at the end of the file
        add     di,cx
        dec     di              ;points to last char
        cmp     byte ptr [di],1ah
        pop     di
        jne     sj51b
        dec     cx
sj51b:
        xor     al,al           ;set zero flag
        call    check_end       ;check that we have a CRLF pair at the end
        ret

;----- Load till first ^Z is found
sj52:
        PUSH    DI
        PUSH    CX
        MOV     AL,1AH
        or      cx,cx
        jz      not_found       ;skip with zero flag set
        REPNE   SCASB           ;Scan for end of file mark
        jnz     not_found
        LAHF                    ;Save flags momentarily
        inc     cx              ;include the ^Z
        SAHF                    ;Restore flags
not_found:
        mov     di,cx           ;not found at the end
        POP     CX
        LAHF                    ;Save flags momentarily
        SUB     CX,DI           ;Reduce byte count if EOF found
        SAHF                    ;Restore flags
        POP     DI
        call    check_end       ;check that we have a CRLF pair at the end

RET2:   RET


;-----------------------------------------------------------------------
;       If the end of file was found, then check that the last character
; in the file is a LF. If not put a CRLF pair in.

check_end:
        jnz     not_end                 ;end was not reached
        pushf                           ;save return flag
        push    di                      ;save pointer to buffer
        add     di,cx                   ;points to one past end on text
        dec     di                      ;points to last character
        cmp     di,offset dg:start
        je      check_no
        cmp     byte ptr[di],0ah        ;is a LF the last character?
        je      check_done              ;yes, exit
check_no:
        mov     byte ptr[di+1],0dh      ;no, put a CR
        inc     cx                      ;one more char in text
        mov     byte ptr[di+2],0ah      ;put a LF
        inc     cx                      ;another character at the end
check_done:
        pop     di
        popf
not_end:
        ret



NOMOREJ:JMP     NOMORE

APPEND:
        TEST    BYTE PTR [HAVEOF],-1
        JNZ     NOMOREJ
        MOV     DX,[ENDTXT]
        CMP     [PARAM1],0      ;See if parameter is missing
        JNZ     PARMAPP
        CMP     DX,[THREE4TH]   ;See if already 3/4ths full
        JAE     RET2            ;If so, then done already
PARMAPP:
        MOV     DI,DX
        MOV     AH,SET_DMA
        INT     21H
        MOV     CX,[LAST]
        SUB     CX,DX           ;Amount of memory available
        jnz     sj53
        jmp     memerr
sj53:
        MOV     DX,FCB
        mov     [amnt_req],cx   ;save ammount of chars requested
        MOV     AH,FCB_RANDOM_READ_BLOCK
        INT     21H              ;Fill memory with file data
        MOV     [HAVEOF],AL
        PUSH    CX              ;Save actual byte count
        CALL    SCANEOF
        JNZ     NOTEND
        MOV     BYTE PTR [HAVEOF],1     ;Set flag if 1AH found in file
NOTEND:
        XOR     DX,DX
        MOV     BX,[PARAM1]
        OR      BX,BX
        JNZ     COUNTLN
        MOV     AX,DI
        ADD     AX,CX           ;First byte after loaded text
        CMP     AX,[THREE4TH]   ;See if we made 3/4 full
        JBE     COUNTLN
        MOV     DI,[THREE4TH]
        MOV     CX,AX
        SUB     CX,DI           ;Length remaining over 3/4
        MOV     BX,1            ;Look for one more line
COUNTLN:
        CALL    SCANLN          ;Look for BX lines
        CMP     [DI-1],AL       ;Check for full line
        JZ      FULLN
        STD
        DEC     DI
        MOV     CX,[LAST]
        REPNE   SCASB                   ;Scan backwards for last line
        INC     DI
        INC     DI
        DEC     DX
        CLD
FULLN:
        POP     CX                              ;Actual amount read
        MOV     WORD PTR [DI],1AH               ;Place EOF after last line
        SUB     CX,DI
        XCHG    DI,[ENDTXT]
        ADD     DI,CX                           ;Amount of file read but not used
        SUB     WORD PTR DS:[FCB+fcb_RR],DI         ;Adjust RR field in case end of file
        SBB     WORD PTR DS:[FCB+fcb_RR+2],0           ;   was not reached
        CMP     BX,DX
        JNZ     EOFCHK
        MOV     BYTE PTR [HAVEOF],0
        RET
NOMORE:
        MOV     DX,OFFSET DG:EOF
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
RET3:   RET
EOFCHK:
        TEST    BYTE PTR [HAVEOF],-1
        JNZ     NOMORE
        TEST    BYTE PTR [ENDING],-1
        JNZ     RET3            ;Suppress memory error during End
        JMP     MEMERR

EWRITE:
        MOV     BX,[PARAM1]
        OR      BX,BX
        JNZ     WRT
        MOV     CX,[ONE4TH]
        MOV     DI,[ENDTXT]
        SUB     DI,CX           ;Write everything in front of here
        JBE     RET3
        CMP     DI,OFFSET DG:START      ;See if there's anything to write
        JBE     RET3
        XOR     DX,DX
        MOV     BX,1            ;Look for one more line
        CALL    SCANLN
        JMP     SHORT WRTADD
WRT:
        INC     BX
        CALL    FINDLIN
WRTADD:
        CMP     BYTE PTR [DELFLG],0
        JNZ     WRTADD1
        PUSH    DI
        CALL    DELBAK                  ;Want to delete the .BAK file
                                        ;as soon as the first write occurs
        POP     DI
WRTADD1:
        MOV     CX,DI
        MOV     DX,OFFSET DG:START
        SUB     CX,DX                   ;Amount to write
        JZ      RET3
        MOV     AH,SET_DMA
        INT     21H
        MOV     DX,OFFSET DG:FCB2
        MOV     AH,FCB_RANDOM_WRITE_BLOCK
        INT     21H
        OR      AL,AL
        JNZ     WRTERR
        MOV     SI,DI
        MOV     DI,OFFSET DG:START
        MOV     [POINTER],DI
        MOV     CX,[ENDTXT]
        SUB     CX,SI
        INC     CX              ;Amount of text remaining
        REP     MOVSB
        DEC     DI              ;Point to EOF
        MOV     [ENDTXT],DI
        MOV     [CURRENT],1
        RET

WRTERR:
        MOV     AH,FCB_CLOSE
        INT     21H
        MOV     DX,OFFSET DG:DSKFUL
xERROR:
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
;-----------------------------------------------------------------------
        call    rest_dir                ;restore to the proper directory
;-----------------------------------------------------------------------
        INT     32

RET$5:  RET

PAGE:
        xor     bx,bx           ;get last line in the buffer
        call    findlin
        mov     [lastlin],dx

        mov     bx,[param1]
        or      bx,bx           ;was it specified?
        jnz     frstok          ;yes, use it
        mov     bx,[current]
        cmp     bx,1            ;if current line =1 start from there
        je      frstok
        inc     bx              ;start from current+1 line
frstok:
        cmp     bx,[lastlin]    ;check that we are in the buffer
        ja      ret$5           ;if not just quit
infile:
        mov     dx,[param2]
        or      dx,dx           ;was param2 specified?
        jnz     scndok          ;yes,....
        mov     dx,bx           ;no, take the end line to be the
        add     dx,22           ;  start line + 23
scndok:
        inc     dx
        cmp     dx,[lastlin]    ;check that we are in the buffer
        jbe     infile2
        mov     dx,[lastlin]    ;we are not, take the last line as end
infile2:
        cmp     dx,bx           ;is param1 < param2 ?
        jbe     ret$5           ;yes, no backwards listing, quit
        push    dx              ;save the end line
        push    bx              ;save start line
        mov     bx,dx           ;set the current line
        dec     bx
        call    findlin
        mov     [pointer],di
        mov     [current],dx
        pop     bx              ;restore start line
        call    findlin         ;get pointer to start line
        mov     si,di           ;save pointer
        pop     di              ;get end line
        sub     di,bx           ;number of lines
        jmp     short display


LIST:
        MOV     BX,[PARAM1]
        OR      BX,BX
        JNZ     CHKP2
        MOV     BX,[CURRENT]
        SUB     BX,11
        JA      CHKP2
        MOV     BX,1
CHKP2:
        CALL    FINDLIN
        JNZ     RET7
        MOV     SI,DI
        MOV     DI,[PARAM2]
        INC     DI
        SUB     DI,BX
        JA      DISPLAY
        MOV     DI,23
        JMP     SHORT DISPLAY


DISPONE:
        MOV     DI,1

DISPLAY:

; Inputs:
;       BX = Line number
;       SI = Pointer to text buffer
;       DI = No. of lines
; Function:
;       Ouputs specified no. of line to terminal, each
;       with leading line number.
; Outputs:
;       BX = Last line output.
; All registers destroyed.

        MOV     CX,[ENDTXT]
        SUB     CX,SI
        JZ      RET7
        MOV     BP,[CURRENT]
DISPLN:
        PUSH    CX
        CALL    SHOWNUM
        POP     CX
OUTLN:
        LODSB
        CMP     AL," "
        JAE     SEND
        CMP     AL,10
        JZ      SEND
        CMP     AL,13
        JZ      SEND
        CMP     AL,9
        JZ      SEND
        PUSH    AX
        MOV     AL,"^"
        CALL    OUT
        POP     AX
        OR      AL,40H
SEND:
        CALL    OUT
        CMP     AL,10
        LOOPNZ  OUTLN
        JCXZ    RET7
        INC     BX
        DEC     DI
        JNZ     DISPLN
        DEC     BX
RET7:   RET

LOADBUF:
        MOV     DI,2 + OFFSET DG:EDITBUF
        MOV     CX,255
        MOV     DX,-1
LOADLP:
        LODSB
        STOSB
        INC     DX
        CMP     AL,13
        LOOPNZ  LOADLP
        MOV     [EDITBUF+1],DL
        JZ      RET7
TRUNCLP:
        LODSB
        INC     DX
        CMP     AL,13
        JNZ     TRUNCLP
        DEC     DI
        STOSB
        RET

NOTFNDJ:JMP     NOTFND

replac_from_curr:
        mov     byte ptr [srchmod],1   ;search from curr+1 line
        jmp     short sj6

REPLAC:
        mov     byte ptr [srchmod],0   ;search from beg of buffer
sj6:
        MOV     BYTE PTR [SRCHFLG],0
        CALL    FNDFIRST
        JNZ     NOTFNDJ
REPLP:
        MOV     SI,[NUMPOS]
        CALL    LOADBUF         ;Count length of line
        SUB     DX,[OLDLEN]
        MOV     CX,[NEWLEN]
        ADD     DX,CX           ;Length of new line
        CMP     DX,254
        JA      TOOLONG
        MOV     BX,[LSTNUM]
        PUSH    DX
        CALL    SHOWNUM
        POP     DX
        MOV     CX,[LSTFND]
        MOV     SI,[NUMPOS]
        SUB     CX,SI           ;Get no. of char on line before change
        DEC     CX
        CALL    OUTCNT          ;Output first part of line
        PUSH    SI
        MOV     SI,1+ OFFSET DG:TXT2
        MOV     CX,[NEWLEN]
        CALL    OUTCNT          ;Output change
        POP     SI
        ADD     SI,[OLDLEN]     ;Skip over old stuff in line
        MOV     CX,DX           ;DX=no. of char left in line
        ADD     CX,2            ;Include CR/LF
        CALL    OUTCNT          ;Output last part of line
        CALL    QUERY           ;Check if change OK
        JNZ     REPNXT
        CALL    PUTCURS
        MOV     DI,[LSTFND]
        DEC     DI
        MOV     SI,1+ OFFSET DG:TXT2
        MOV     DX,[OLDLEN]
        MOV     CX,[NEWLEN]
        DEC     CX
        ADD     [LSTFND],CX     ;Bump pointer beyond new text
        INC     CX
        DEC     DX
        SUB     [SRCHCNT],DX    ;Old text will not be searched
        JAE     SOMELEFT
        MOV     [SRCHCNT],0
SOMELEFT:
        INC     DX
        CALL    REPLACE
REPNXT:
        CALL    FNDNEXT
        JNZ     RET8
        JMP     REPLP

OUTCNT:
        JCXZ    RET8
OUTLP:
        LODSB
        CALL    OUT
        DEC     DX
        LOOP    OUTLP
RET8:   RET

TOOLONG:
        MOV     DX,OFFSET DG:TOOLNG
        JMP     SHORT PERR

search_from_curr:
        mov     byte ptr [srchmod],1   ;search from curr+1 line
        jmp     short sj7

SEARCH:
        mov     byte ptr [srchmod],0   ;search from beg of buffer
sj7:
        MOV     BYTE PTR [SRCHFLG],1
        CALL    FNDFIRST
        JNZ     NOTFND
SRCH:
        MOV     BX,[LSTNUM]
        MOV     SI,[NUMPOS]
        CALL    DISPONE
        MOV     DI,[LSTFND]
        MOV     CX,[SRCHCNT]
        MOV     AL,10
        REPNE   SCASB
        JNZ     NOTFND
        MOV     [LSTFND],DI
        MOV     [NUMPOS],DI
        MOV     [SRCHCNT],CX
        INC     [LSTNUM]
        CALL    QUERY
        JZ      PUTCURS
        CALL    FNDNEXT
        JZ      SRCH
NOTFND:
        MOV     DX,OFFSET DG:NOSUCH
PERR:
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
        RET

PUTCURS:
        MOV     BX,[LSTNUM]
        DEC     BX                      ;Current <= Last matched line
        CALL    FINDLIN
        MOV     [CURRENT],DX
        MOV     [POINTER],DI
RET9:   RET

DELETE:
        MOV     BX,[PARAM1]
        OR      BX,BX
        JNZ     DELFIN1
        MOV     BX,[CURRENT]
        CALL    CHKRANGE
DELFIN1:
        CALL    FINDLIN
        JNZ     RET9
        PUSH    BX
        PUSH    DI
        MOV     BX,[PARAM2]
        OR      BX,BX
        JNZ     DELFIN2
        MOV     BX,DX
DELFIN2:
        INC     BX
        CALL    FINDLIN
        MOV     DX,DI
        POP     DI
        SUB     DX,DI
        JBE     COMERRJ
        POP     [CURRENT]
        MOV     [POINTER],DI
        XOR     CX,CX
        JMP     SHORT REPLACE

COMERRJ:JMP     COMERR


NOCOM:
        DEC     [COMLINE]
        MOV     BX,[PARAM1]
        OR      BX,BX
        JNZ     HAVLIN
        MOV     BX,[CURRENT]
        INC     BX      ;Default is current line plus one
        CALL    CHKRANGE
HAVLIN:
        CALL    FINDLIN
        MOV     SI,DI
        MOV     [CURRENT],DX
        MOV     [POINTER],SI
        jz      sj12
        ret
sj12:
        CMP     SI,[ENDTXT]
        JZ      RET12
        CALL    LOADBUF
        MOV     [OLDLEN],DX
        MOV     SI,[POINTER]
        CALL    DISPONE
        CALL    SHOWNUM
        MOV     AH,STD_CON_STRING_INPUT           ;Get input buffer
        MOV     DX,OFFSET DG:EDITBUF
        INT     21H
        MOV     AL,10
        CALL    OUT
        MOV     CL,[EDITBUF+1]
        MOV     CH,0
        JCXZ    RET12
        MOV     DX,[OLDLEN]
        MOV     SI,2 + OFFSET DG:EDITBUF
;-----------------------------------------------------------------------
        call    unquote                 ;scan for quote chars if any
;-----------------------------------------------------------------------
        MOV     DI,[POINTER]

REPLACE:

; Inputs:
;       CX = Length of new text
;       DX = Length of original text
;       SI = Pointer to new text
;       DI = Pointer to old text in buffer
; Function:
;       New text replaces old text in buffer and buffer
;       size is adjusted. CX or DX may be zero.
; CX, SI, DI all destroyed. No other registers affected.

        CMP     CX,DX
        JZ      COPYIN
        PUSH    SI
        PUSH    DI
        PUSH    CX
        MOV     SI,DI
        ADD     SI,DX
        ADD     DI,CX
        MOV     AX,[ENDTXT]
        SUB     AX,DX
        ADD     AX,CX
        CMP     AX,[LAST]
        JAE     MEMERR
        XCHG    AX,[ENDTXT]
        MOV     CX,AX
        SUB     CX,SI
        CMP     SI,DI
        JA      DOMOV
        ADD     SI,CX
        ADD     DI,CX
        STD
DOMOV:
        INC     CX

        REP     MOVSB
        CLD
        POP     CX
        POP     DI
        POP     SI
COPYIN:
        REP     MOVSB
RET12:  RET

MEMERR:
        MOV     DX,OFFSET DG:MEMFUL
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
        JMP     COMMAND

MOVERR:
        MOV     DX,OFFSET DG:BADCOM
ERRORJ:
        JMP     COMERR

MOVE:
        MOV     BYTE PTR [MOVFLG],1
        JMP     SHORT BLKMOVE
COPY:
        MOV     BYTE PTR [MOVFLG],0

BLKMOVE:
        MOV     BX,[PARAM3]             ;Third parameter must be specified
        OR      BX,BX
        MOV     DX,OFFSET DG:DEST
        JZ      ERRORJ
        MOV     BX,[PARAM1]             ;Get the first parameter
        OR      BX,BX                   ;Not specified?
        JNZ     NXTARG
        MOV     BX,[CURRENT]            ;Defaults to the current line
        CALL    CHKRANGE
        MOV     [PARAM1],BX             ;Save it since current line may change
 NXTARG:
        CALL    FINDLIN                 ;Get a pointer to the line
        MOV     [PTR_1],DI              ;Save it
        MOV     BX,[PARAM2]             ;Get the second parameter
        OR      BX,BX                   ;Not specified?
        JNZ     HAVARGS
        MOV     BX,[CURRENT]            ;Defaults to the current line
        MOV     [PARAM2],BX             ;Save it since current line may change
HAVARGS:
        ;Parameters must not overlap
        MOV     DX,[PARAM3]
        CMP     DX,[PARAM1]
        JBE     NOERROR
        CMP     DX,[PARAM2]
        JBE     MOVERR
NOERROR:
        INC     BX                      ;Get pointer to line Param2+1
        CALL    FINDLIN
        MOV     SI,DI
        MOV     [PTR_2],SI              ;Save it
        MOV     CX,DI
        MOV     DI,[PTR_1]              ;Restore pointer to line Param1
        SUB     CX,DI                   ;Calculate number of bytes to copy
        MOV     [COPYSIZ],CX            ;Save in COPYSIZ
        PUSH    CX                      ;And on the stack
        MOV     AX,[PARAM4]             ;Is count specified?
        OR      AX,AX
        JZ      MEM_CHECK
        MUL     [COPYSIZ]
        OR      DX,DX
        JZ      COPYSIZ_OK
        JMP     MEMERR
COPYSIZ_OK:
        MOV     CX,AX
        MOV     [COPYSIZ],CX
MEM_CHECK:
        MOV     AX,[ENDTXT]
        MOV     DI,[LAST]
        SUB     DI,AX
        CMP     DI,CX
        JAE     HAV_ROOM
        JMP     MEMERR
HAV_ROOM:
        MOV     BX,[PARAM3]
        PUSH    BX
        CALL    FINDLIN
        MOV     [PTR_3],DI
        MOV     CX,[ENDTXT]
        SUB     CX,DI
        INC     CX
        MOV     SI,[ENDTXT]
        MOV     DI,SI
        ADD     DI,[COPYSIZ]
        MOV     [ENDTXT],DI
        STD
        REP     MOVSB
        CLD
        POP     BX
        CMP     BX,[PARAM1]
        JB      GET_PTR_2
        MOV     SI,[PTR_1]
        JMP     SHORT COPY_TEXT
GET_PTR_2:
        MOV     SI,[PTR_2]
COPY_TEXT:
        MOV     BX,[PARAM4]
        MOV     DI,[PTR_3]
        POP     CX
        MOV     [COPYSIZ],CX
COPY_TEXT_1:
        REP     MOVSB
        DEC     BX
        CMP     BX,0
        JLE     MOV_CHK
        MOV     [PARAM4],BX
        SUB     SI,[COPYSIZ]
        MOV     CX,[COPYSIZ]
        JMP     SHORT COPY_TEXT_1
MOV_CHK:
        CMP     BYTE PTR[MOVFLG],0
        JZ      COPY_DONE
        MOV     DI,[PTR_1]
        MOV     SI,[PTR_2]
        MOV     BX,[PARAM3]
        CMP     BX,[PARAM1]
        JAE     DEL_TEXT
        ADD     DI,[COPYSIZ]
        ADD     SI,[COPYSIZ]
DEL_TEXT:
        MOV     CX,[ENDTXT]
        SUB     CX,SI
        REP     MOVSB
        MOV     [ENDTXT],DI
        MOV     CX,[PARAM2]
        SUB     CX,[PARAM1]
        MOV     BX,[PARAM3]
        SUB     BX,CX
        JNC     MOVE_DONE
COPY_DONE:
        MOV     BX,[PARAM3]
MOVE_DONE:
        CALL    FINDLIN
        MOV     [POINTER],DI
        MOV     [CURRENT],BX
        RET


MOVEFILE:
        MOV     CX,[ENDTXT]             ;Get End-of-text marker
        MOV     SI,CX
        SUB     CX,DI                   ;Calculate number of bytes to copy
        INC     CX
        MOV     DI,DX
        STD
        REP     MOVSB                   ;Copy CX bytes
        XCHG    SI,DI
        CLD
        INC     DI
        MOV     BP,SI
SETPTS:
        MOV     [POINTER],DI            ;Current line is first free loc
        MOV     [CURRENT],BX            ;   in the file
        MOV     [ENDTXT],BP             ;End-of-text is last free loc before
        RET

NAMERR:
        JMP     COMERR1


MERGE:
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 1
        MOV     DI,OFFSET DG:FCB3
        INT     21H
        OR      AL,AL
        MOV     DX,OFFSET DG:BADDRV
        JNZ     NAMERR
        MOV     [COMLINE],SI
        MOV     DX,OFFSET DG:FCB3
        MOV     AH,FCB_OPEN
        INT     21H
        OR      AL,AL
        MOV     DX,OFFSET DG:FILENM
        JNZ     NAMERR
        MOV     AX,(SET_INTERRUPT_VECTOR SHL 8) OR 23H
        MOV     DX,OFFSET DG:ABORTMERGE
        INT     21H
        MOV     BX,[PARAM1]
        OR      BX,BX
        JNZ     MRG
        MOV     BX,[CURRENT]
        CALL    CHKRANGE
MRG:
        CALL    FINDLIN
        MOV     BX,DX
        MOV     DX,[LAST]
        CALL    MOVEFILE
        ;Set DMA address for reading in new file
        MOV     DX,[POINTER]
        MOV     AH,SET_DMA
        INT     21H
        XOR     AX,AX
        MOV     WORD PTR DS:[FCB3+fcb_RR],AX
        MOV     WORD PTR DS:[FCB3+fcb_RR+2],AX
        INC     AX
        MOV     WORD PTR DS:[FCB3+fcb_RECSIZ],AX
        MOV     DX,OFFSET DG:FCB3
        MOV     CX,[ENDTXT]
        SUB     CX,[POINTER]
        MOV     AH,FCB_RANDOM_READ_BLOCK
        INT     21H
        CMP     AL,1
        JZ      FILEMRG
        MOV     DX,OFFSET DG:MRGERR
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
        MOV     CX,[POINTER]
        JMP     SHORT RESTORE
FILEMRG:
        ADD     CX,[POINTER]
        MOV     SI,CX
        DEC     SI
        LODSB
        CMP     AL,1AH
        JNZ     RESTORE
        DEC     CX
RESTORE:
        MOV     DI,CX
        MOV     SI,[ENDTXT]
        INC     SI
        MOV     CX,[LAST]
        SUB     CX,SI
        REP     MOVSB
        MOV     [ENDTXT],DI
        MOV     BYTE PTR [DI],1AH
        MOV     DX,OFFSET DG:FCB3
        MOV     AH,FCB_CLOSE
        INT     21H
        MOV     DX,OFFSET DG:START
        MOV     AH,SET_DMA
        INT     21H
        RET


INSERT:
        MOV     AX,(SET_INTERRUPT_VECTOR SHL 8) OR 23H        ;Set vector 23H
        MOV     DX,OFFSET DG:ABORTINS
        INT     21H
        MOV     BX,[PARAM1]
        OR      BX,BX
        JNZ     INS
        MOV     BX,[CURRENT]
        CALL    CHKRANGE
INS:
        CALL    FINDLIN
        MOV     BX,DX
        MOV     DX,[LAST]
        CALL    MOVEFILE
INLP:
        CALL    SETPTS                  ;Update the pointers into file
        CALL    SHOWNUM
        MOV     DX,OFFSET DG:EDITBUF
        MOV     AH,STD_CON_STRING_INPUT
        INT     21H
        CALL    LF
        MOV     SI,2 + OFFSET DG:EDITBUF
        CMP     BYTE PTR [SI],1AH
        JZ      ENDINS
;-----------------------------------------------------------------------
        call    unquote                 ;scan for quote chars if any
;-----------------------------------------------------------------------
        MOV     CL,[SI-1]
        MOV     CH,0
        MOV     DX,DI
        INC     CX
        ADD     DX,CX
        JC      MEMERRJ1
        JZ      MEMERRJ1
        CMP     DX,BP
        JB      MEMOK
MEMERRJ1:
        CALL    END_INS
        JMP     MEMERR
MEMOK:
        REP     MOVSB
        MOV     AL,10
        STOSB
        INC     BX
        JMP     SHORT INLP

ABORTMERGE:
        MOV     DX,OFFSET DG:START
        MOV     AH,SET_DMA
        INT     21H

ABORTINS:
        MOV     AX,CS           ;Restore segment registers
        MOV     DS,AX
        MOV     ES,AX
        MOV     SS,AX
        MOV     SP,OFFSET DG:STACK
        STI
        CALL    CRLF
        CALL    ENDINS
        JMP     COMOVER

ENDINS:
        CALL    END_INS
        RET

END_INS:
        MOV     BP,[ENDTXT]
        MOV     DI,[POINTER]
        MOV     SI,BP
        INC     SI
        MOV     CX,[LAST]
        SUB     CX,BP
        REP     MOVSB
        DEC     DI
        MOV     [ENDTXT],DI
        MOV     AX,(SET_INTERRUPT_VECTOR SHL 8) OR 23H
        MOV     DX,OFFSET DG:ABORTCOM
        INT     21H
        RET

FILLBUF:
        MOV     [PARAM1],-1     ;Read in max. no of lines
        CALL    APPEND
ENDED:
;Write text out to .$$$ file
        MOV     BYTE PTR [ENDING],1     ;Suppress memory errors
        MOV     BX,-1           ;Write max. no of lines
        CALL    WRT
        TEST    BYTE PTR [HAVEOF],-1
        JZ      FILLBUF
        MOV     DX,[ENDTXT]
        MOV     AH,SET_DMA
        INT     21H
        MOV     CX,1
        MOV     DX,OFFSET DG:FCB2
        MOV     AH,FCB_RANDOM_WRITE_BLOCK
        INT     21H              ;Write end-of-file byte
;Close .$$$ file
        MOV     AH,FCB_CLOSE
        INT     21H
        MOV     SI,FCB
        LEA     DI,[SI+fcb_FILSIZ]
        MOV     DX,SI
        MOV     CX,9
        REP     MOVSB
        MOV     SI,OFFSET DG:BAK
        MOVSW
        MOVSB
;Rename original file .BAK
        MOV     AH,FCB_RENAME
        INT     21H
        MOV     SI,FCB
        MOV     DI,OFFSET DG:FCB2 + fcb_FILSIZ
        MOV     CX,6
        REP     MOVSW
;Rename .$$$ file to original name
        MOV     DX,OFFSET DG:FCB2
        INT     21H
        call    rest_dir                ;restore directory if needed
        INT     20H

ABORTCOM:
        MOV     AX,CS
        MOV     DS,AX
        MOV     ES,AX
        MOV     SS,AX
        MOV     SP,OFFSET DG:STACK
        STI
        CALL    CRLF
        JMP     COMMAND

DELBAK:
        MOV     BYTE PTR [DELFLG],1
        MOV     DI,9+OFFSET DG:FCB2
        MOV     SI,OFFSET DG:BAK
        MOVSW
        MOVSB
        ;Delete old backup file (.BAK)
        MOV     AH,FCB_DELETE
        MOV     DX,OFFSET DG:FCB2
        INT     21H
        MOV     DI,9+OFFSET DG:FCB2
        MOV     AL,"$"
        STOSB
        STOSB
        STOSB
        RET

CODE    ENDS
        END     EDLIN
