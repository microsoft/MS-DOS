;       SCCSID = @(#)locate.asm 4.3 85/09/13
Title   LOCATE (EXE2BIN)

;   Loader for EXE files under 86-DOS
;   VER 1.5
;       05/21/82   Added rev number
;   VER 1.6
;       07/01/82   A little less choosy about size matches
;   VER 2.0  M.A.U
;       10/08/82   Modified to use new 2.0 system calls for file i/o
;   Ver 2.1  M.A.U
;       10/27/82   Added the DOS version check
;   Ver 2.2  MZ
;       8/30/83     Fixed command line parsing
;   Ver 2.3  EE
;       10-12-83    More fixes to command line parsing
;   Ver 2.4  NP
;       10/17/83    Use Printf for messages
;   Ver 2.5  MZ     Fix LOCATE sss D: problem
;       04/09/87    Add PARSER and MESSAGE RETRIEVER
;   Ver 4.00  DRM

; The following switch allows use with the "old linker", which put a version
; number where the new linker puts the number of bytes used in the last page.
; If enabled, this will cause a test for 0004 at this location (the old linker
; version number), and if equal, change it to 200H so all of the last page
; will be used.


OLDLINK EQU     0                  ;1 to enable, 0 to disable

        .xlist

;       INCLUDE DOSSYM.INC              ; also versiona.inc
;       INCLUDE E2BMACRO.INC

        .list

        subttl  Main Code Area
        page

DATA    SEGMENT PUBLIC BYTE

rev     db      "2.4"


file1_ext db    ".EXE",00h
file2_ext db    ".BIN",00h

per1    dW      0
per2    db      0

file1   db      (64+13) dup(?)
fnptr   dw      offset file1    ; Ptr to filename in file1
handle1 dw      1 dup(?)

file2   db      (64+13) dup(?)
f2cspot dw      offset file2    ; Ptr to spot in file2, file1 maybe added
handle2 dw      1 dup(?)

dma_buf db      80h dup(0)       ; DMA transfer buffer

INBUF   DB      5,0
        DB      5 DUP(?)

;The following locations must be defined for storing the header:

RUNVAR  LABEL   BYTE            ;Start of RUN variables
RELPT   DW      ?
LASTP   LABEL   WORD
RELSEG  DW      ?
SIZ     LABEL   WORD            ;Share these locations
PAGES   DW      ?
RELCNT  DW      ?
HEADSIZ DW      ?
        DW      ?
LOADLOW DW      ?
INITSS  DW      ?
INITSP  DW      ?
        DW      ?
INITIP  DW      ?
INITCS  DW      ?
RELTAB  DW      ?
RUNVARSIZ       EQU     $-RUNVAR

DATA    ENDS

STACK   SEGMENT WORD STACK
        DB   (362 - 80h) + 80H DUP (?)  ; (362 - 80h) is IBMs ROM requirement
                                        ; (New - Old) == size of growth
STACK   ENDS


ZLOAD   SEGMENT
ZLOAD   ENDS
LOAD    EQU     ZLOAD


CODE    SEGMENT BYTE

        ASSUME  CS:CODE,SS:STACK

LOCATE  PROC    NEAR

LOCSTRT:
        PUSH    DS
        XOR     AX,AX
        PUSH    AX                      ;Push return address to DS:0


        MOV     SI,81H
        MOV     BX,DATA
        MOV     ES,BX
        MOV     BX,WORD PTR DS:[2]      ;Get size of memory

        assume  es:data






;-----------------------------------------------------------------------;

;
; The rules for the arguments are:
;   File 1:
;       If no extention is present, .EXE is used.
;   File 2:
;       If no drive is present in file2, use the one from file1
;       If no path is specified, then use current dir
;       If no filename is specified, use the filename from file1
;       If no extention is present in file2, .BIN is used
;


;----- Get the first file name
        call    kill_bl                 ;   p = skipblanks (p);
        jnc     sj01                    ;   if (p == NULL)
        push    es
        pop     ds
        MESSAGE msgNoFile               ;AC000;
sj01:
        mov     di,offset file1         ;   d = file1;
sj0:
        lodsb                           ;   while (!IsBlank(c=*p++)) {
        CALL    IsBlank
        JZ      SJ2
        mov     DX,per1
        cmp     al,'\'                  ;       if (c == '\\' || c == ':') {
        jz      sj05
        cmp     al,':'
        jnz     checkper1
sj05:
        mov     fnptr,di                ;           fnptr = ptr to slash
        inc     fnptr                   ;   fnptr advanced past slash to fname
        xor     DX,DX                   ;           per1 = NULL;
checkper1:
        cmp     al,'.'                  ;       if (c == '.')
        jne     sj1
        mov     DX,DI                   ;           per1 = p-1;
        DEC     DX                      ;
sj1:
        mov     per1,DX
        stosb                           ;       *d++ = c;
        jmp     short sj0               ;       }
sj2:
        dec     si                      ;   p--;
        mov     byte ptr es:[di],00h    ;   *d = 0;
        call    kill_bl                 ;   if (End(p))
        jnc     get_second
        cmp     byte ptr [file1+1],':'  ; Drive spec on first file?
        jnz     nsja                    ; no
        mov     ax,word ptr file1       ; get drive stuff
        mov     word ptr file2,ax
        inc     f2cspot
        inc     f2cspot
nsja:
        jmp     no_second               ;       goto No_second;


get_second:
;----- Get the second file name
        mov     di,offset file2         ;   d = file2
        cmp     byte ptr [si+1],':'     ; Drive spec on second file?
        jz      sj3                     ; yes
        cmp     byte ptr [file1+1],':'  ; Drive spec on first file?
        jnz     sj3                     ; no
        push    ax                      ; Suck drive spec from file1
        mov     ax,word ptr file1
        stosw
        mov     f2cspot,di
        pop     ax
sj3:
        lodsb                           ;   while (!IsBlank(c=*p++)) {
        CALL    IsBlank
        JZ      SJ5
        mov     ah,per2
        cmp     al,'\'                  ;       if (c == '\\')
        jnz     checkper2
        xor     ah,ah                   ;           per2 = FALSE;
checkper2:
        cmp     al,'.'                  ;       if (c == '.')
        jne     sj4
        mov     ah,-1                   ;           per2 = TRUE;
sj4:
        mov     per2,ah
        stosb                           ;       *d++ = c;
        jmp     short sj3               ;       }
sj5:
        mov     byte ptr es:[di],00h    ;   *d = 0;
        mov     ah,Set_DMA              ; Use find_first to see if file2 is
        mov     dx,offset dma_buf       ; a directory.  If it isn't, go to
        push    es                      ; chex_ext.  If it is, put a back-
        pop     ds                      ; slash on the end of the string,
        int     21h                     ; set f2cspot to point to the spot
        mov     ah,Find_First           ; right after the backslash, and
        mov     dx,offset file2         ; fall through to no_second so that
        mov     cx,-1                   ; file1's name will be added to file2.
        int     21h
        jc      checkDrive
        test    dma_buf+21,00010000b
        jNZ     DoDirectory
        jmp     Check_Ext
CheckDrive:
        CMP     BYTE PTR ES:[DI-1],':'
        JNZ     Check_Ext               ; if char is not a : then skip
        JMP     SetSecond               ; presume drive:
DoDirectory:
        mov     AL,5ch
        stosb
SetSecond:
        mov     per2,FALSE
        mov     f2cspot,di

;----- Copy file1 to file2
no_second:
        PUSH    ES
        POP     DS
        assume  ds:data

        mov     si,fnptr                ;   s = ptr to fname in file1;
        mov     di,f2cspot              ;   d = spot in file2 to cat file1;
        mov     dx,per1                 ;   dx = ptr to ext dot in file1;
        inc     dx

sj6:                                    ;   while (TRUE) {
        cmp     SI,dx                   ;       if (s == per1)
        je      sj7                     ;           break;
        lodsb                           ;       c = *s++;
        cmp     al,00h                  ;       if (!c)
        je      sj7                     ;           break;
        stosb                           ;       *d++ = c;
        jmp     short sj6               ;       }
sj7:
        mov     byte ptr [di],00h       ;   *d = 0;

;----- Check that files have an extension, otherwise set default
check_ext:
        PUSH    ES
        POP     DS
        assume  ds:data

        cmp     per1,0                  ;   if (per1 == NULL) {
        jNZ     file1_ok
        mov     di,offset file1         ;       d = file1;
        mov     si,offset file1_ext     ;       s = ".EXE";
        call    strcat                  ;       strcat (d, s);
file1_ok:                               ;       }
        cmp     per2,-1                 ;   if (per2 != NULL) {
        je      file2_ok
        mov     di,offset file2         ;       d = file2;
        mov     si,offset file2_ext     ;       s = ".BIN";
        call    strcat                  ;       strcap (d, s);
        jmp     short file2_ok          ;       }

;-----------------------------------------------------------------------;
file2_ok:
        mov     dx,offset file1
        mov     ax,(open SHL 8) + 0     ;for reading only
        INT     21H                     ;Open input file
        jc      bad_file
        mov     [handle1],ax
        jmp     exeload

bad_file:
        MESSAGE msgNoFile               ;AC000;
        call    TriageError
BADEXE:
        MESSAGE msgNoConvert            ;AC000;
TOOBIG:
        MESSAGE msgOutOfMemory          ;AC000;

EXELOAD:
        MOV     DX,OFFSET RUNVAR        ;Read header in here
        MOV     CX,RUNVARSIZ            ;Amount of header info we need
        push    bx
        mov     bx,[handle1]
        MOV     AH,read
        INT     21H                      ;Read in header
        pop     bx
        CMP     [RELPT],5A4DH           ;Check signature word
        JNZ     BADEXE
        MOV     AX,[HEADSIZ]            ;size of header in paragraphs
        ADD     AX,31                   ;Round up first
        CMP     AX,1000H                ;Must not be >=64K
        JAE     TOOBIG
        AND     AX,NOT 31
        MOV     CL,4
        SHL     AX,CL                   ;Header size in bytes

        push    dx
        push    cx
        push    ax
        push    bx
        mov     dx,ax
        xor     cx,cx
        mov     al,0
        mov     bx,[handle1]
        mov     ah,lseek
        int     21h
        pop     bx
        pop     ax
        pop     cx
        pop     dx

        XCHG    AL,AH
        SHR     AX,1                    ;Convert to pages
        MOV     DX,[PAGES]              ;Total size of file in 512-byte pages
        SUB     DX,AX                   ;Size of program in pages
        CMP     DX,80H                  ;Fit in 64K?
        JAE     TOOBIG
        XCHG    DH,DL
        SHL     DX,1                    ;Convert pages to bytes
        MOV     AX,[LASTP]              ;Get count of bytes in last page
        OR      AX,AX                   ;If zero, use all of last page
        JZ      WHOLEP

        IF      OLDLINK
        CMP     AX,4                    ;Produced by old linker?
        JZ      WHOLEP                  ;If so, use all of last page too
        ENDIF

        SUB     DX,200H                 ;Subtract last page
        ADD     DX,AX                   ;Add in byte count for last page
WHOLEP:
        MOV     [SIZ],DX
        ADD     DX,15
        SHR     DX,CL                   ;Convert bytes to paragraphs
        MOV     BP,LOAD
        ADD     DX,BP                   ;Size + start = minimum memory (paragr.)
        CMP     DX,BX                   ;Enough memory?
        JA      TOOBIG
        MESSAGE msgNoConvert            ;AC000;
        MOV     AX,[INITSS]
        OR      AX,[INITSP]
        OR      AX,[INITCS]
ERRORNZ:
        jz      xj
        JMP     WRTERR                  ;Must not have SS, SP, or CS to init.
xj:     MOV     AX,[INITIP]
        OR      AX,AX                   ;If IP=0, do binary fix
        JZ      BINFIX
        CMP     AX,100H                 ;COM file must be set up for CS:100
        JNZ     ERRORNZ

        push    dx
        push    cx
        push    ax
        push    bx
        mov     dx,100h                 ;chop off first 100h
        xor     cx,cx
        mov     al,1                    ;seek from current position
        mov     bx,[handle1]
        mov     ah,lseek
        int     21h
        pop     bx
        pop     ax
        pop     cx
        pop     dx

        SUB     [SIZ],AX                ;And count decreased size
        CMP     [RELCNT],0              ;Must have no fixups
        JNZ     ERRORNZ
BINFIX:
        XOR     BX,BX                   ;Initialize fixup segment
;See if segment fixups needed
        CMP     [RELCNT],0
        JZ      LOADEXE
GETSEG:
        MESSAGE msgFixUp                ;AC000;
        MOV     AH,STD_CON_STRING_INPUT
        MOV     DX,OFFSET INBUF
        INT     21H                      ;Get user response
        MOV     SI,OFFSET INBUF+2
        MOV     BYTE PTR [SI-1],0       ;Any digits?
        JZ      GETSEG
DIGLP:
        LODSB
        SUB     AL,"0"
        JC      DIGERR
        CMP     AL,10
        JB      HAVDIG
        AND     AL,5FH                  ;Convert to upper case
        SUB     AL,7
        CMP     AL,10
        JB      DIGERR
        CMP     AL,10H
        JAE     DIGERR
HAVDIG:
        SHL     BX,1
        SHL     BX,1
        SHL     BX,1
        SHL     BX,1
        OR      BL,AL
        JMP     DIGLP

DIGERR:
        CMP     BYTE PTR [SI-1],0DH     ;Is last char. a CR?
        JNZ     GETSEG
LOADEXE:
        XCHG    BX,BP                   ;BX has LOAD, BP has fixup

        MOV     CX,[SIZ]
        MOV     AH,read
        push    di
        mov     di,[handle1]
        PUSH    DS
        MOV     DS,BX
        XOR     DX,DX
        push    bx
        mov     bx,di
        INT     21H                     ;Read in up to 64K
        pop     bx
        POP     DS
        pop     di
        Jnc     HAVEXE                  ;Did we get it all?
        MESSAGE msgReadError            ;AC000;
HAVEXE:
        CMP     [RELCNT],0              ;Any fixups to do?
        JZ      STORE
        MOV     AX,[RELTAB]             ;Get position of table

        push    dx
        push    cx
        push    ax
        push    bx
        mov     dx,ax
        xor     cx,cx
        mov     al,0
        mov     bx,[handle1]
        mov     ah,lseek
        int     21h
        pop     bx
        pop     ax
        pop     cx
        pop     dx

        MOV     DX,OFFSET RELPT         ;4-byte buffer for relocation address
RELOC:
        MOV     DX,OFFSET RELPT         ;4-byte buffer for relocation address
        MOV     CX,4
        MOV     AH,read
        push    bx
        mov     bx,[handle1]
        INT     21H                      ;Read in one relocation pointer
        pop     bx
        Jnc     RDCMP
        JMP     BADEXE
RDCMP:
        MOV     DI,[RELPT]              ;Get offset of relocation pointer
        MOV     AX,[RELSEG]             ;Get segment
        ADD     AX,BX                   ;Bias segment with actual load segment
        MOV     ES,AX
        ADD     ES:[DI],BP              ;Relocate
        DEC     [RELCNT]                ;Count off
        JNZ     RELOC
STORE:
        MOV     AH,CREAT
        MOV     DX,OFFSET file2
        xor     cx,cx
        INT     21H
        Jc      MKERR
        mov     [handle2],ax
        MOV     CX,[SIZ]
        MOV     AH,write
        push    di
        mov     di,[handle2]
        PUSH    DS
        MOV     DS,BX
        XOR     DX,DX                   ;Address 0 in segment
        push    bx
        mov     bx,di
        INT     21H
        pop     bx
        POP     DS
        pop     di
        Jc      WRTERR                  ;Must be zero if more to come
        MOV     AH,CLOSE
        push    bx
        mov     bx,[handle2]
        INT     21H
        pop     bx
        RET

WRTERR:
        MESSAGE msgOutOfMemory          ;AC000;

MKERR:
        MESSAGE msgFileCreateError      ;AC000;
        Call    TriageError


LOCATE  ENDP

;----- concatenate two strings
strcat  proc    near                    ;   while (*d)
        cmp     byte ptr [di],0
        jz      atend
        inc     di                      ;       d++;
        jmp     strcat
atend:                                  ;   while (*d++ = *s++)
        lodsb
        stosb
        or      al,al                   ;       ;
        jnz     atend
        ret
strcat  endp

;----- Find the first non-ignorable char, return carry if CR found
kill_bl proc    near
        cld
sj10:                                   ;   while ( *p != 13 &&
        lodsb
        CMP     AL,13                   ;           IsBlank (*p++))
        JZ      BreakOut
        CALL    IsBlank
        JZ      SJ10                    ;       ;
BreakOut:
        dec     si                      ;   p--;
        cmp     al,0dh                  ;   return *p == 13;
        clc
        jne     sj11
        stc
sj11:
        ret
kill_bl endp

IsBlank proc    near
        cmp     al,13
        retz
        cmp     al,' '                  ; space
        retz
        cmp     al,9                    ; tab
        retz
        cmp     al,','                  ; comma
        retz
        cmp     al,';'                  ; semicolon
        retz
        cmp     al,'+'                  ; plus
        retz
        cmp     al,10                   ; line feed
        retz
        cmp     al,'='                  ; equal sign
        return
IsBlank Endp

;
; Take a default message pointer in DX and convert it to access-denied iff
; the extended error indicates so.  Leave all other registers (except AX)
; alone.
;
Procedure TriageError,near
        retnc                           ; no carry => do nothing...
        PUSHF
        SaveReg <BX,CX,SI,DI,BP,ES,DS,AX,DX>
        MOV     AH,GetExtendedError
        INT     21h
        RestoreReg  <CX,BX>             ; restore original AX
        MESSAGE msgNoAccess             ;AC000;
        CMP     AX,65                   ; network access denied?
        JZ      NoMove                  ; Yes, return it.
        MOV     AX,BX
        MOV     DX,CX
NoMove:
        RestoreReg  <DS,ES,BP,DI,SI,CX,BX>
        popf
        return
TriageError ENDP

CODE    ENDS
        END     LOCATE
