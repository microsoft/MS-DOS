; 86-DOS  High-performance operating system for the 8086  version 1.25
;       by Tim Paterson


; ****************** Revision History *************************
;          >> EVERY change must noted below!! <<
;
; 0.34 12/29/80 General release, updating all past customers
; 0.42 02/25/81 32-byte directory entries added
; 0.56 03/23/81 Variable record and sector sizes
; 0.60 03/27/81 Ctrl-C exit changes, including register save on user stack
; 0.74 04/15/81 Recognize I/O devices with file names
; 0.75 04/17/81 Improve and correct buffer handling
; 0.76 04/23/81 Correct directory size when not 2^N entries
; 0.80 04/27/81 Add console input without echo, Functions 7 & 8
; 1.00 04/28/81 Renumber for general release
; 1.01 05/12/81 Fix bug in `STORE'
; 1.10 07/21/81 Fatal error trapping, NUL device, hidden files, date & time,
;               RENAME fix, general cleanup
; 1.11 09/03/81 Don't set CURRENT BLOCK to 0 on open; fix SET FILE SIZE
; 1.12 10/09/81 Zero high half of CURRENT BLOCK after all (CP/M programs don't)
; 1.13 10/29/81 Fix classic "no write-through" error in buffer handling
; 1.20 12/31/81 Add time to FCB; separate FAT from DPT; Kill SMALLDIR;
;               Add FLUSH and MAPDEV calls; allow disk mapping in DSKCHG;
;               Lots of smaller improvements
; 1.21 01/06/82 HIGHMEM switch to run DOS in high memory
; 1.22 01/12/82 Add VERIFY system call to enable/disable verify after write
; 1.23 02/11/82 Add defaulting to parser; use variable escape character
;               Don't zero extent field in IBM version (back to 1.01!)
; 1.24 03/01/82 Restore fcn. 27 to 1.0 level; add fcn. 28
; 1.25 03/03/82 Put marker (00) at end of directory to speed searches
;
; *************************************************************


; Interrupt Entry Points:

; INTBASE:      ABORT
; INTBASE+4:    COMMAND
; INTBASE+8:    BASE EXIT ADDRESS
; INTBASE+C:    CONTROL-C ABORT
; INTBASE+10H:  FATAL ERROR ABORT
; INTBASE+14H:  BIOS DISK READ
; INTBASE+18H:  BIOS DISK WRITE
; INTBASE+40H:  Long jump to CALL entry point

        IF      IBM
ESCCH   EQU     0
CANCEL  EQU     1BH             ;Cancel with ESC
TOGLINS EQU     TRUE            ;One key toggles insert mode
TOGLPRN EQU     TRUE            ;One key toggles printer echo
NUMDEV  EQU     6               ;Include "COM1" as I/O device name
ZEROEXT EQU     TRUE
        ELSE
ESCCH   EQU     1BH
CANCEL  EQU     "X"-"@"         ;Cancel with Ctrl-X
TOGLINS EQU     FALSE           ;Separate keys for insert mode on and off
TOGLPRN EQU     FALSE           ;Separate keys for printer echo on and off
NUMDEV  EQU     5               ;Number of I/O device names
ZEROEXT EQU     FALSE
        ENDIF

MAXCALL EQU     36
MAXCOM  EQU     46
INTBASE EQU     80H
INTTAB  EQU     20H
ENTRYPOINTSEG   EQU     0CH
ENTRYPOINT      EQU     INTBASE+40H
CONTC   EQU     INTTAB+3
EXIT    EQU     INTBASE+8
LONGJUMP EQU    0EAH
LONGCALL EQU    9AH
MAXDIF  EQU     0FFFH
SAVEXIT EQU     10

; Field definition for FCBs

FCBLOCK STRUC
        DB      12 DUP (?)              ;Drive code and name
EXTENT  DW      ?
RECSIZ  DW      ?       ;Size of record (user settable)
FILSIZ  DW      ?       ;Size of file in bytes
DRVBP   DW      ?       ;BP for SEARCH FIRST and SEARCH NEXT
FDATE   DW      ?       ;Date of last writing
FTIME   DW      ?       ;Time of last writing
DEVID   DB      ?       ;Device ID number, bits 0-5
                        ;bit 7=0 for file, bit 7=1 for I/O device
                        ;If file, bit 6=0 if dirty
                        ;If I/O device, bit 6=0 if EOF (input)
FIRCLUS DW      ?       ;First cluster of file
LSTCLUS DW      ?       ;Last cluster accessed
CLUSPOS DW      ?       ;Position of last cluster accessed
        DB      ?       ;Forces NR to offset 32
NR      DB      ?       ;Next record
RR      DB      3 DUP (?)               ;Random record
FCBLOCK ENDS
FILDIRENT       = FILSIZ                ;Used only by SEARCH FIRST and SEARCH NEXT

; Description of 32-byte directory entry (same as returned by SEARCH FIRST
; and SEARCH NEXT, functions 17 and 18).
;
; Location      bytes   Description
;
;    0          11      File name and extension ( 0E5H if empty)
;   11           1      Attributes. Bits 1 or 2 make file hidden
;   12          10      Zero field (for expansion)
;   22           2      Time. Bits 0-4=seconds/2, bits 5-10=minute, 11-15=hour
;   24           2      Date. Bits 0-4=day, bits 5-8=month, bits 9-15=year-1980
;   26           2      First allocation unit ( < 4080 )
;   28           4      File size, in bytes (LSB first, 30 bits max.)
;
; The File Allocation Table uses a 12-bit entry for each allocation unit on
; the disk. These entries are packed, two for every three bytes. The contents
; of entry number N is found by 1) multiplying N by 1.5; 2) adding the result
; to the base address of the Allocation Table; 3) fetching the 16-bit word at
; this address; 4) If N was odd (so that N*1.5 was not an integer), shift the
; word right four bits; 5) mask to 12 bits (AND with 0FFF hex). Entry number
; zero is used as an end-of-file trap in the OS and as a flag for directory
; entry size (if SMALLDIR selected). Entry 1 is reserved for future use. The
; first available allocation unit is assigned entry number two, and even
; though it is the first, is called cluster 2. Entries greater than 0FF8H are
; end of file marks; entries of zero are unallocated. Otherwise, the contents
; of a FAT entry is the number of the next cluster in the file.


; Field definition for Drive Parameter Block

DPBLOCK STRUC
DEVNUM  DB      ?       ;I/O driver number
DRVNUM  DB      ?       ;Physical Unit number
SECSIZ  DW      ?       ;Size of physical sector in bytes
CLUSMSK DB      ?       ;Sectors/cluster - 1
CLUSSHFT DB     ?       ;Log2 of sectors/cluster
FIRFAT  DW      ?       ;Starting record of FATs
FATCNT  DB      ?       ;Number of FATs for this drive
MAXENT  DW      ?       ;Number of directory entries
FIRREC  DW      ?       ;First sector of first cluster
MAXCLUS DW      ?       ;Number of clusters on drive + 1
FATSIZ  DB      ?       ;Number of records occupied by FAT
FIRDIR  DW      ?       ;Starting record of directory
FAT     DW      ?       ;Pointer to start of FAT
DPBLOCK ENDS

DPBSIZ  EQU     20      ;Size of the structure in bytes
DIRSEC  =       FIRREC  ;Number of dir. sectors (init temporary)
DSKSIZ  =       MAXCLUS ;Size of disk (temp used during init only)

;The following are all of the segments used
;They are declared in the order that they should be placed in the executable

CODE    SEGMENT
CODE    ENDS

CONSTANTS       SEGMENT BYTE
CONSTANTS       ENDS

DATA    SEGMENT WORD
DATA    ENDS

DOSGROUP        GROUP   CODE,CONSTANTS,DATA

SEGBIOS SEGMENT
SEGBIOS ENDS


; BOIS entry point definitions

        IF      IBM
BIOSSEG EQU     60H
        ENDIF
        IF      NOT IBM
BIOSSEG EQU     40H
        ENDIF

SEGBIOS         SEGMENT AT BIOSSEG
                ORG     0
                DB      3 DUP (?)       ;Reserve room for jump to init code
BIOSSTAT        DB      3 DUP (?)       ;Console input status check
BIOSIN          DB      3 DUP (?)       ;Get console character
BIOSOUT         DB      3 DUP (?)       ;Output console character
BIOSPRINT       DB      3 DUP (?)       ;Output to printer
BIOSAUXIN       DB      3 DUP (?)       ;Get byte from auxilliary
BIOSAUXOUT      DB      3 DUP (?)       ;Output byte to auxilliary
BIOSREAD        DB      3 DUP (?)       ;Disk read
BIOSWRITE       DB      3 DUP (?)       ;Disk write
BIOSDSKCHG      DB      3 DUP (?)       ;Dsik-change status
BIOSSETDATE     DB      3 DUP (?)       ;Set date
BIOSSETTIME     DB      3 DUP (?)       ;Set time
BIOSGETTIME     DB      3 DUP (?)       ;Get time and date
BIOSFLUSH       DB      3 DUP (?)       ;Clear console input buffer
BIOSMAPDEV      DB      3 DUP (?)       ;Dynamic disk table mapper

SEGBIOS ENDS
; Location of user registers relative user stack pointer

STKPTRS STRUC
AXSAVE  DW      ?
BXSAVE  DW      ?
CXSAVE  DW      ?
DXSAVE  DW      ?
SISAVE  DW      ?
DISAVE  DW      ?
BPSAVE  DW      ?
DSSAVE  DW      ?
ESSAVE  DW      ?
IPSAVE  DW      ?
CSSAVE  DW      ?
FSAVE   DW      ?
STKPTRS ENDS

; Start of code

CODE    SEGMENT
ASSUME  CS:DOSGROUP,DS:DOSGROUP,ES:DOSGROUP,SS:DOSGROUP

        ORG     0
CODSTRT EQU     $
        JMP     DOSINIT

ESCCHAR DB      ESCCH   ;Lead-in character for escape sequences
ESCTAB: 
        IF      NOT IBM
        DB      "S"     ;Copy one char
        DB      "V"     ;Skip one char
        DB      "T"     ;Copy to char
        DB      "W"     ;Skip to char
        DB      "U"     ;Copy line
        DB      "E"     ;Kill line (no change in template)
        DB      "J"     ;Reedit line (new template)
        DB      "D"     ;Backspace
        DB      "P"     ;Enter insert mode
        DB      "Q"     ;Exit insert mode
        DB      "R"     ;Escape character
        DB      "R"     ;End of table
        ENDIF
        IF      IBM
        DB      64      ;Crtl-Z - F6
        DB      77      ;Copy one char - -->
        DB      59      ;Copy one char - F1
        DB      83      ;Skip one char - DEL
        DB      60      ;Copy to char - F2
        DB      62      ;Skip to char - F4
        DB      61      ;Copy line - F3
        DB      61      ;Kill line (no change to template ) - Not used
        DB      63      ;Reedit line (new template) - F5
        DB      75      ;Backspace - <--
        DB      82      ;Enter insert mode - INS (toggle)
        DB      65      ;Escape character - F7
        DB      65      ;End of table
        ENDIF

ESCTABLEN EQU   $-ESCTAB
        IF      NOT IBM
HEADER  DB      13,10,"MS-DOS version 1.25"
        IF      HIGHMEM
        DB      "H"
        ENDIF
        IF      DSKTEST
        DB      "D"
        ENDIF

        DB      13,10
        DB      "Copyright 1981,82 Microsoft, Inc.",13,10,"$"
        ENDIF

QUIT:
        MOV     AH,0
        JMP     SHORT SAVREGS

COMMAND: ;Interrupt call entry point
        CMP     AH,MAXCOM
        JBE     SAVREGS
BADCALL:
        MOV     AL,0
IRET:   IRET

ENTRY:  ;System call entry point and dispatcher
        POP     AX              ;IP from the long call at 5
        POP     AX              ;Segment from the long call at 5
        POP     CS:[TEMP]       ;IP from the CALL 5
        PUSHF                   ;Start re-ordering the stack
        CLI
        PUSH    AX              ;Save segment
        PUSH    CS:[TEMP]       ;Stack now ordered as if INT had been used
        CMP     CL,MAXCALL      ;This entry point doesn't get as many calls
        JA      BADCALL
        MOV     AH,CL
SAVREGS:
        PUSH    ES
        PUSH    DS
        PUSH    BP
        PUSH    DI
        PUSH    SI
        PUSH    DX
        PUSH    CX
        PUSH    BX
        PUSH    AX

        IF      DSKTEST
        MOV     AX,CS:[SPSAVE]
        MOV     CS:[NSP],AX
        MOV     AX,CS:[SSSAVE]
        MOV     CS:[NSS],AX
        POP     AX
        PUSH    AX
        ENDIF

        MOV     CS:[SPSAVE],SP
        MOV     CS:[SSSAVE],SS
        MOV     SP,CS
        MOV     SS,SP
REDISP:
        MOV     SP,OFFSET DOSGROUP:IOSTACK
        STI                     ;Stack OK now
        MOV     BL,AH
        MOV     BH,0
        SHL     BX,1
        CLD
        CMP     AH,12
        JLE     SAMSTK
        MOV     SP,OFFSET DOSGROUP:DSKSTACK
SAMSTK:
        CALL    CS:[BX+DISPATCH]
LEAVE:
        CLI
        MOV     SP,CS:[SPSAVE]
        MOV     SS,CS:[SSSAVE]
        MOV     BP,SP
        MOV     BYTE PTR [BP.AXSAVE],AL

        IF      DSKTEST
        MOV     AX,CS:[NSP]
        MOV     CS:[SPSAVE],AX
        MOV     AX,CS:[NSS]
        MOV     CS:[SSSAVE],AX
        ENDIF

        POP     AX
        POP     BX
        POP     CX
        POP     DX
        POP     SI
        POP     DI
        POP     BP
        POP     DS
        POP     ES
        IRET
; Standard Functions
DISPATCH DW     ABORT           ;0
        DW      CONIN
        DW      CONOUT
        DW      READER
        DW      PUNCH
        DW      LIST            ;5
        DW      RAWIO
        DW      RAWINP
        DW      IN
        DW      PRTBUF
        DW      BUFIN           ;10
        DW      CONSTAT
        DW      FLUSHKB
        DW      DSKRESET
        DW      SELDSK
        DW      OPEN            ;15
        DW      CLOSE
        DW      SRCHFRST
        DW      SRCHNXT
        DW      DELETE
        DW      SEQRD           ;20
        DW      SEQWRT
        DW      CREATE
        DW      RENAME
        DW      INUSE
        DW      GETDRV          ;25
        DW      SETDMA
        DW      GETFATPT
        DW      GETFATPTDL
        DW      GETRDONLY
        DW      SETATTRIB       ;30
        DW      GETDSKPT
        DW      USERCODE
        DW      RNDRD
        DW      RNDWRT
        DW      FILESIZE        ;35
        DW      SETRNDREC
; Extended Functions
        DW      SETVECT
        DW      NEWBASE
        DW      BLKRD
        DW      BLKWRT          ;40
        DW      MAKEFCB
        DW      GETDATE
        DW      SETDATE
        DW      GETTIME
        DW      SETTIME         ;45
        DW      VERIFY

INUSE:
GETIO:
SETIO:
GETRDONLY:
SETATTRIB:
USERCODE:
        MOV     AL,0
        RET

VERIFY:
        AND     AL,1
        MOV     CS:VERFLG,AL
        RET

FLUSHKB:
        PUSH    AX
        CALL    FAR PTR BIOSFLUSH
        POP     AX
        MOV     AH,AL
        CMP     AL,1
        JZ      REDISPJ
        CMP     AL,6
        JZ      REDISPJ
        CMP     AL,7
        JZ      REDISPJ
        CMP     AL,8
        JZ      REDISPJ
        CMP     AL,10
        JZ      REDISPJ
        MOV     AL,0
        RET

REDISPJ:JMP     REDISP

READER:
AUXIN:
        CALL    STATCHK
        CALL    FAR PTR BIOSAUXIN 
        RET

PUNCH:
        MOV     AL,DL
AUXOUT:
        PUSH    AX
        CALL    STATCHK
        POP     AX
        CALL    FAR PTR BIOSAUXOUT 
        RET


UNPACK:

; Inputs:
;       DS = CS
;       BX = Cluster number
;       BP = Base of drive parameters
;       SI = Pointer to drive FAT
; Outputs:
;       DI = Contents of FAT for given cluster
;       Zero set means DI=0 (free cluster)
; No other registers affected. Fatal error if cluster too big.

        CMP     BX,[BP.MAXCLUS]
        JA      HURTFAT
        LEA     DI,[SI+BX]
        SHR     BX,1
        MOV     DI,[DI+BX]
        JNC     HAVCLUS
        SHR     DI,1
        SHR     DI,1
        SHR     DI,1
        SHR     DI,1
        STC
HAVCLUS:
        RCL     BX,1
        AND     DI,0FFFH
        RET
HURTFAT:
        PUSH    AX
        MOV     AH,80H          ;Signal Bad FAT to INT 24H handler
        MOV     DI,0FFFH        ;In case INT 24H returns (it shouldn't)
        CALL    FATAL
        POP     AX              ;Try to ignore bad FAT
        RET


PACK:

; Inputs:
;       DS = CS
;       BX = Cluster number
;       DX = Data
;       SI = Pointer to drive FAT
; Outputs:
;       The data is stored in the FAT at the given cluster.
;       BX,DX,DI all destroyed
;       No other registers affected

        MOV     DI,BX
        SHR     BX,1
        ADD     BX,SI
        ADD     BX,DI
        SHR     DI,1
        MOV     DI,[BX]
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
        MOV     [BX],DI
        RET

DEVNAME:
        MOV     SI,OFFSET DOSGROUP:IONAME       ;List of I/O devices with file names
        MOV     BH,NUMDEV               ;BH = number of device names
LOOKIO:
        MOV     DI,OFFSET DOSGROUP:NAME1
        MOV     CX,4                    ;All devices are 4 letters
        REPE    CMPSB                   ;Check for name in list
        JZ      IOCHK                   ;If first 3 letters OK, check for the rest
        ADD     SI,CX                   ;Point to next device name
        DEC     BH
        JNZ     LOOKIO
CRET:
        STC                             ;Not found
        RET

IOCHK:
        IF      IBM
        CMP     BH,NUMDEV       ;Is it the first device?
        JNZ     NOTCOM1
        MOV     BH,2            ;Make it the same as AUX
NOTCOM1:
        ENDIF
        NEG     BH
        MOV     CX,2            ;Check rest of name but not extension
        MOV     AX,2020H
        REPE    SCASW           ;Make sure rest of name is blanks
        JNZ     CRET
RET1:   RET                     ;Zero set so CREATE works

GETFILE:
; Same as GETNAME except ES:DI points to FCB on successful return
        CALL    MOVNAME
        JC      RET1
        PUSH    DX
        PUSH    DS
        CALL    FINDNAME
        POP     ES
        POP     DI
RET2:   RET


GETNAME:

; Inputs:
;       DS,DX point to FCB
; Function:
;       Find file name in disk directory. First byte is
;       drive number (0=current disk). "?" matches any
;       character.
; Outputs:
;       Carry set if file not found
;       ELSE
;       Zero set if attributes match (always except when creating)
;       BP = Base of drive parameters
;       DS = CS
;       ES = CS
;       BX = Pointer into directory buffer
;       SI = Pointer to First Cluster field in directory entry
;       [DIRBUF] has directory record with match
;       [NAME1] has file name
; All other registers destroyed.

        CALL    MOVNAME
        JC      RET2            ;Bad file name?
FINDNAME:
        MOV     AX,CS
        MOV     DS,AX
        CALL    DEVNAME
        JNC     RET2
        CALL    STARTSRCH
CONTSRCH:
        CALL    GETENTRY
        JC      RET2
SRCH:
        MOV     AH,BYTE PTR [BX]
        OR      AH,AH                   ;End of directory?
        JZ      FREE
        CMP     AH,[DELALL]             ;Free entry?
        JZ      FREE
        MOV     SI,BX
        MOV     DI,OFFSET DOSGROUP:NAME1
        MOV     CX,11
WILDCRD:
        REPE    CMPSB
        JZ      FOUND
        CMP     BYTE PTR [DI-1],"?"
        JZ      WILDCRD
NEXTENT:
        CALL    NEXTENTRY
        JNC     SRCH
RET3:   RET

FREE:
        CMP     [ENTFREE],-1            ;Found a free entry before?
        JNZ     TSTALL                  ;If so, ignore this one
        MOV     CX,[LASTENT]
        MOV     [ENTFREE],CX
TSTALL:
        CMP     AH,[DELALL]             ;At end of directory?
        JZ      NEXTENT                 ;No - continue search
        STC                             ;Report not found
        RET
 
FOUND:
;Check if attributes allow finding it
        MOV     AH,[ATTRIB]             ;Attributes of search
        NOT     AH
        AND     AH,[SI]                 ;Compare with attributes of file
        ADD     SI,15   
        AND     AH,6                    ;Only look at bits 1 and 2
        JZ      RET3
        TEST    BYTE PTR [CREATING],-1  ;Pass back mismatch if creating
        JZ      NEXTENT                 ;Otherwise continue searching
        RET


GETENTRY:

; Inputs:
;       [LASTENT] has previously searched directory entry
; Function:
;       Locates next sequential directory entry in preparation for search
; Outputs:
;       Carry set if none
;       ELSE
;       AL = Current directory block
;       BX = Pointer to next directory entry in [DIRBUF]
;       DX = Pointer to first byte after end of DIRBUF
;       [LASTENT] = New directory entry number

        MOV     AX,[LASTENT]
        INC     AX                      ;Start with next entry
        CMP     AX,[BP.MAXENT]
        JAE     NONE
GETENT:
        MOV     [LASTENT],AX
        MOV     CL,4
        SHL     AX,CL
        XOR     DX,DX
        SHL     AX,1
        RCL     DX,1                    ;Account for overflow in last shift
        MOV     BX,[BP.SECSIZ]
        AND     BL,255-31               ;Must be multiple of 32
        DIV     BX
        MOV     BX,DX                   ;Position within sector
        MOV     AH,[BP.DEVNUM]          ;AL=Directory sector no.
        CMP     AX,[DIRBUFID]
        JZ      HAVDIRBUF
        PUSH    BX
        CALL    DIRREAD
        POP     BX
HAVDIRBUF:
        MOV     DX,OFFSET DOSGROUP:DIRBUF
        ADD     BX,DX
        ADD     DX,[BP.SECSIZ]
        RET

NEXTENTRY:

; Inputs:
;       Same as outputs of GETENTRY, above
; Function:
;       Update AL, BX, and [LASTENT] for next directory entry.
;       Carry set if no more.

        MOV     DI,[LASTENT]
        INC     DI
        CMP     DI,[BP.MAXENT]
        JAE     NONE
        MOV     [LASTENT],DI
        ADD     BX,32
        CMP     BX,DX
        JB      HAVIT
        INC     AL                      ;Next directory sector
        PUSH    DX                      ;Save limit
        CALL    DIRREAD
        POP     DX
        MOV     BX,OFFSET DOSGROUP:DIRBUF
HAVIT:
        CLC
        RET

NONE:
        CALL    CHKDIRWRITE
        STC
RET4:   RET


DELETE: ; System call 19
        CALL    MOVNAME
        MOV     AL,-1
        JC      RET4
        MOV     AL,CS:[ATTRIB]
        AND     AL,6                    ;Look only at hidden bits
        CMP     AL,6                    ;Both must be set
        JNZ     NOTALL
        MOV     CX,11
        MOV     AL,"?"
        MOV     DI,OFFSET DOSGROUP:NAME1
        REPE    SCASB                   ;See if name is *.*
        JNZ     NOTALL
        MOV     BYTE PTR CS:[DELALL],0  ;DEL *.* - flag deleting all
NOTALL:
        CALL    FINDNAME
        MOV     AL,-1
        JC      RET4
        OR      BH,BH           ;Check if device name
        JS      RET4            ;Can't delete I/O devices
DELFILE:
        MOV     BYTE PTR [DIRTYDIR],-1
        MOV     AH,[DELALL]
        MOV     BYTE PTR [BX],AH
        MOV     BX,[SI]
        MOV     SI,[BP.FAT]
        OR      BX,BX
        JZ      DELNXT
        CMP     BX,[BP.MAXCLUS]
        JA      DELNXT
        CALL    RELEASE
DELNXT:
        CALL    CONTSRCH
        JNC     DELFILE
        CALL    FATWRT
        CALL    CHKDIRWRITE
        XOR     AL,AL
        RET


RENAME: ;System call 23
        CALL    MOVNAME
        JC      ERRET
        ADD     SI,5
        MOV     DI,OFFSET DOSGROUP:NAME2
        CALL    LODNAME
        JC      ERRET           ;Report error if second name invalid
        CALL    FINDNAME
        JC      ERRET
        OR      BH,BH           ;Check if I/O device name
        JS      ERRET           ;If so, can't rename it
        MOV     SI,OFFSET DOSGROUP:NAME1
        MOV     DI,OFFSET DOSGROUP:NAME3
        MOV     CX,6            ;6 words (12 bytes)--include attribute byte
        REP     MOVSW           ;Copy name to search for
RENFIL:
        MOV     DI,OFFSET DOSGROUP:NAME1
        MOV     SI,OFFSET DOSGROUP:NAME2
        MOV     CX,11
NEWNAM:
        LODSB
        CMP     AL,"?"
        JNZ     NOCHG
        MOV     AL,[BX]
NOCHG:
        STOSB
        INC     BX
        LOOP    NEWNAM
        MOV     BYTE PTR [DI],6 ;Stop duplicates with any attributes
        CALL    DEVNAME         ;Check if giving it a device name
        JNC     RENERR
        PUSH    [LASTENT]       ;Save position of match
        MOV     [LASTENT],-1    ;Search entire directory for duplicate
        CALL    CONTSRCH        ;See if new name already exists
        POP     AX
        JNC     RENERR                  ;Error if found
        CALL    GETENT                  ;Re-read matching entry
        MOV     DI,BX
        MOV     SI,OFFSET DOSGROUP:NAME1
        MOV     CX,5
        MOVSB
        REP     MOVSW                   ;Replace old name with new one
        MOV     BYTE PTR [DIRTYDIR],-1  ;Flag change in directory
        MOV     SI,OFFSET DOSGROUP:NAME3
        MOV     DI,OFFSET DOSGROUP:NAME1
        MOV     CX,6                    ;Include attribute byte
        REP     MOVSW                   ;Copy name back into search buffer
        CALL    CONTSRCH
        JNC     RENFIL
        CALL    CHKDIRWRITE
        XOR     AL,AL
        RET

RENERR:
        CALL    CHKDIRWRITE
ERRET:
        MOV     AL,-1
RET5:   RET


MOVNAME:

; Inputs:
;       DS, DX point to FCB or extended FCB
; Outputs:
;       DS:DX point to normal FCB
;       ES = CS
;       If file name OK:
;       BP has base of driver parameters
;       [NAME1] has name in upper case
; All registers except DX destroyed
; Carry set if bad file name or drive

        MOV     CS:WORD PTR [CREATING],0E500H   ;Not creating, not DEL *.*
        MOV     AX,CS
        MOV     ES,AX
        MOV     DI,OFFSET DOSGROUP:NAME1
        MOV     SI,DX
        LODSB
        MOV     CS:[EXTFCB],AL  ;Set flag if extended FCB in use
        MOV     AH,0            ;Set default attributes
        CMP     AL,-1           ;Is it an extended FCB?
        JNZ     HAVATTRB
        ADD     DX,7            ;Adjust to point to normal FCB
        ADD     SI,6            ;Point to drive select byte
        MOV     AH,[SI-1]       ;Get attribute byte
        LODSB           ;Get drive select byte
HAVATTRB:
        MOV     CS:[ATTRIB],AH  ;Save attributes
        CALL    GETTHISDRV
LODNAME:
; This entry point copies a file name from DS,SI
; to ES,DI converting to upper case.
        CMP     BYTE PTR [SI]," "       ;Don't allow blank as first letter
        STC                     ;In case of error
        JZ      RET5
        MOV     CX,11
MOVCHK:
        CALL    GETLET
        JB      RET5
        JNZ     STOLET          ;Is it a delimiter?
        CMP     AL," "          ;This is the only delimiter allowed
        STC                     ;In case of error
        JNZ     RET5
STOLET:
        STOSB
        LOOP    MOVCHK
        CLC                     ;Got through whole name - no error
RET6:   RET

GETTHISDRV:
        CMP     CS:[NUMDRV],AL
        JC      RET6
        DEC     AL
        JNS     PHYDRV
        MOV     AL,CS:[CURDRV]
PHYDRV:
        MOV     CS:[THISDRV],AL
        RET
        

OPEN:   ;System call 15
        CALL    GETFILE
DOOPEN:
; Enter here to perform OPEN on file already found
; in directory. DS=CS, BX points to directory
; entry in DIRBUF, SI points to First Cluster field, and
; ES:DI point to the FCB to be opened. This entry point
; is used by CREATE.
        JC      ERRET
        OR      BH,BH           ;Check if file is I/O device
        JS      OPENDEV         ;Special handler if so
        MOV     AL,[THISDRV]
        INC     AX
        STOSB
        XOR     AX,AX
        IF      ZEROEXT
        ADD     DI,11
        STOSW                   ;Zero low byte of extent field if IBM only
        ENDIF
        IF      NOT ZEROEXT
        ADD     DI,12           ;Point to high half of CURRENT BLOCK field
        STOSB                   ;Set it to zero (CP/M programs set low byte)
        ENDIF
        MOV     AL,128          ;Default record size
        STOSW                   ;Set record size
        LODSW                   ;Get starting cluster
        MOV     DX,AX           ;Save it for the moment
        MOVSW                   ;Transfer size to FCB
        MOVSW
        MOV     AX,[SI-8]       ;Get date
        STOSW                   ;Save date in FCB
        MOV     AX,[SI-10]      ;Get time
        STOSW                   ;Save it in FCB
        MOV     AL,[BP.DEVNUM]
        OR      AL,40H
        STOSB
        MOV     AX,DX           ;Restore starting cluster
        STOSW                   ; first cluster
        STOSW                   ; last cluster accessed
        XOR     AX,AX
        STOSW                   ; position of last cluster
        RET


OPENDEV:
        ADD     DI,13           ;point to 2nd half of extent field
        XOR     AX,AX
        STOSB                   ;Set it to zero
        MOV     AL,128
        STOSW                   ;Set record size to 128
        XOR     AX,AX
        STOSW
        STOSW                   ;Set current size to zero
        CALL    DATE16
        STOSW                   ;Date is todays
        XCHG    AX,DX
        STOSW                   ;Use current time
        MOV     AL,BH           ;Get device number
        STOSB
        XOR     AL,AL           ;No error
        RET
FATERR:
        XCHG    AX,DI           ;Put error code in DI
        MOV     AH,2            ;While trying to read FAT
        MOV     AL,[THISDRV]    ;Tell which drive
        CALL    FATAL1
        JMP     SHORT FATREAD
STARTSRCH:
        MOV     AX,-1
        MOV     [LASTENT],AX
        MOV     [ENTFREE],AX
FATREAD:

; Inputs:
;       DS = CS
; Function:
;       If disk may have been changed, FAT is read in and buffers are
;       flagged invalid. If not, no action is taken.
; Outputs:
;       BP = Base of drive parameters
;       Carry set if invalid drive returned by MAPDEV
; All other registers destroyed

        MOV     AL,[THISDRV]
        XOR     AH,AH           ;Set default response to zero & clear carry
        CALL    FAR PTR BIOSDSKCHG      ;See what BIOS has to say
        JC      FATERR
        CALL    GETBP
        MOV     AL,[THISDRV]    ;Use physical unit number
        MOV     SI,[BP.FAT]
        OR      AH,[SI-1]       ;Dirty byte for FAT
        JS      NEWDSK          ;If either say new disk, then it's so
        JNZ     MAPDRV
        MOV     AH,1
        CMP     AX,WORD PTR [BUFDRVNO]  ;Does buffer have dirty sector of this drive?
        JZ      MAPDRV
NEWDSK:
        CMP     AL,[BUFDRVNO]   ;See if buffer is for this drive
        JNZ     BUFOK           ;If not, don't touch it
        MOV     [BUFSECNO],0    ;Flag buffers invalid
        MOV     WORD PTR [BUFDRVNO],00FFH
BUFOK:
        MOV     [DIRBUFID],-1
        CALL    FIGFAT
NEXTFAT:
        PUSH    AX
        CALL    DSKREAD
        POP     AX
        JC      BADFAT
        SUB     AL,[BP.FATCNT]
        JZ      NEWFAT
        CALL    FATWRT
NEWFAT:
        MOV     SI,[BP.FAT]
        MOV     AL,[BP.DEVNUM]
        MOV     AH,[SI]         ;Get first byte of FAT
        OR      AH,0F8H         ;Put in range
        CALL    FAR PTR BIOSMAPDEV
        MOV     AH,0
        MOV     [SI-2],AX       ;Set device no. and reset dirty bit
MAPDRV:
        MOV     AL,[SI-2]       ;Get device number
GETBP:
        MOV     BP,[DRVTAB]     ;Just in case drive isn't valid
        AND     AL,3FH          ;Mask out dirty bit
        CMP     AL,[NUMIO]
        CMC
        JC      RET7
        PUSH    AX
        MOV     AH,DPBSIZ
        MUL     AH
        ADD     BP,AX
        POP     AX
RET7:   RET

BADFAT:
        MOV     CX,DI
        ADD     DX,CX
        DEC     AL
        JNZ     NEXTFAT
        CALL    FIGFAT                          ;Reset registers
        CALL    DREAD                           ;Try first FAT once more
        JMP     SHORT NEWFAT

OKRET1:
        MOV     AL,0
        RET

CLOSE:  ;System call 16
        MOV     DI,DX
        CMP     BYTE PTR [DI],-1                ;Check for extended FCB
        JNZ     NORMFCB3
        ADD     DI,7
NORMFCB3:
        TEST    BYTE PTR [DI.DEVID],0C0H        ;Allow only dirty files
        JNZ     OKRET1                          ;can't close if I/O device, or not writen
        MOV     AL,[DI]                         ;Get physical unit number
        DEC     AL                              ;Make zero = drive A
        MOV     AH,1                            ;Look for dirty buffer
        CMP     AX,CS:WORD PTR [BUFDRVNO]
        JNZ     FNDDIR
;Write back dirty buffer if on same drive
        PUSH    DX
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     BYTE PTR [DIRTYBUF],0
        MOV     BX,[BUFFER]
        MOV     CX,1
        MOV     DX,[BUFSECNO]
        MOV     BP,[BUFDRVBP]
        CALL    DWRITE
        POP     DS
        POP     DX
FNDDIR:
        CALL    GETFILE
BADCLOSEJ:
        JC      BADCLOSE
        MOV     CX,ES:[DI.FIRCLUS]
        MOV     [SI],CX
        MOV     DX,ES:WORD PTR [DI.FILSIZ]
        MOV     [SI+2],DX
        MOV     DX,ES:WORD PTR [DI.FILSIZ+2]
        MOV     [SI+4],DX
        MOV     DX,ES:[DI.FDATE]
        MOV     [SI-2],DX
        MOV     DX,ES:[DI.FTIME]
        MOV     [SI-4],DX
        CALL    DIRWRITE

CHKFATWRT:
; Do FATWRT only if FAT is dirty and uses same I/O driver
        MOV     SI,[BP.FAT]
        MOV     AL,[BP.DEVNUM]
        MOV     AH,1
        CMP     [SI-2],AX       ;See if FAT dirty and uses same driver
        JNZ     OKRET

FATWRT:

; Inputs:
;       DS = CS
;       BP = Base of drive parameter table
; Function:
;       Write the FAT back to disk and reset FAT
;       dirty bit.
; Outputs:
;       AL = 0
;       BP unchanged
; All other registers destroyed

        CALL    FIGFAT
        MOV     BYTE PTR [BX-1],0
EACHFAT:
        PUSH    DX
        PUSH    CX
        PUSH    BX
        PUSH    AX
        CALL    DWRITE
        POP     AX
        POP     BX
        POP     CX
        POP     DX
        ADD     DX,CX
        DEC     AL
        JNZ     EACHFAT
OKRET:
        MOV     AL,0
        RET

BADCLOSE:
        MOV     SI,[BP.FAT]
        MOV     BYTE PTR [SI-1],0
        MOV     AL,-1
        RET


FIGFAT:
; Loads registers with values needed to read or
; write a FAT.
        MOV     AL,[BP.FATCNT]
        MOV     BX,[BP.FAT]
        MOV     CL,[BP.FATSIZ]  ;No. of records occupied by FAT
        MOV     CH,0
        MOV     DX,[BP.FIRFAT]  ;Record number of start of FATs
        RET


DIRCOMP:
; Prepare registers for directory read or write
        CBW
        ADD     AX,[BP.FIRDIR]
        MOV     DX,AX
        MOV     BX,OFFSET DOSGROUP:DIRBUF
        MOV     CX,1
        RET


CREATE: ;System call 22
        CALL    MOVNAME
        JC      ERRET3
        MOV     DI,OFFSET DOSGROUP:NAME1
        MOV     CX,11
        MOV     AL,"?"
        REPNE   SCASB
        JZ      ERRET3
        MOV     CS:BYTE PTR [CREATING],-1
        PUSH    DX
        PUSH    DS
        CALL    FINDNAME
        JNC     EXISTENT
        MOV     AX,[ENTFREE]    ;First free entry found in FINDNAME
        CMP     AX,-1
        JZ      ERRPOP
        CALL    GETENT          ;Point at that free entry
        JMP     SHORT FREESPOT
ERRPOP:
        POP     DS
        POP     DX
ERRET3:
        MOV     AL,-1
        RET

EXISTENT:
        JNZ     ERRPOP          ;Error if attributes don't match
        OR      BH,BH           ;Check if file is I/O device
        JS      OPENJMP         ;If so, no action
        MOV     CX,[SI]         ;Get pointer to clusters
        JCXZ    FREESPOT
        CMP     CX,[BP.MAXCLUS]
        JA      FREESPOT
        PUSH    BX
        MOV     BX,CX
        MOV     SI,[BP.FAT]
        CALL    RELEASE         ;Free any data already allocated
        CALL    FATWRT
        POP     BX
FREESPOT:
        MOV     DI,BX
        MOV     SI,OFFSET DOSGROUP:NAME1
        MOV     CX,5
        MOVSB
        REP     MOVSW
        MOV     AL,[ATTRIB]
        STOSB
        XOR     AX,AX
        MOV     CL,5
        REP     STOSW
        CALL    DATE16
        XCHG    AX,DX
        STOSW
        XCHG    AX,DX
        STOSW
        XOR     AX,AX
        PUSH    DI
        MOV     CL,6
SMALLENT:
        REP     STOSB
        PUSH    BX
        CALL    DIRWRITE
        POP     BX
        POP     SI
OPENJMP:
        CLC                     ;Clear carry so OPEN won't fail
        POP     ES
        POP     DI
        JMP     DOOPEN


DIRREAD:

; Inputs:
;       DS = CS
;       AL = Directory block number
;       BP = Base of drive parameters
; Function:
;       Read the directory block into DIRBUF.
; Outputs:
;       AX,BP unchanged
; All other registers destroyed.

        PUSH    AX
        CALL    CHKDIRWRITE
        POP     AX
        PUSH    AX
        MOV     AH,[BP.DEVNUM]
        MOV     [DIRBUFID],AX
        CALL    DIRCOMP
        CALL    DREAD
        POP     AX
RET8:   RET


DREAD:

; Inputs:
;       BX,DS = Transfer address
;       CX = Number of sectors
;       DX = Absolute record number
;       BP = Base of drive parameters
; Function:
;       Calls BIOS to perform disk read. If BIOS reports
;       errors, will call HARDERR for further action.
; BP preserved. All other registers destroyed.

        CALL    DSKREAD
        JNC     RET8
        MOV     CS:BYTE PTR [READOP],0
        CALL    HARDERR
        CMP     AL,1            ;Check for retry
        JZ      DREAD
        RET                     ;Ignore otherwise


HARDERR:

;Hard disk error handler. Entry conditions:
;       DS:BX = Original disk transfer address
;       DX = Original logical sector number
;       CX = Number of sectors to go (first one gave the error)
;       AX = Hardware error code
;       DI = Original sector transfer count
;       BP = Base of drive parameters
;       [READOP] = 0 for read, 1 for write

        XCHG    AX,DI           ;Error code in DI, count in AX
        SUB     AX,CX           ;Number of sectors successfully transferred
        ADD     DX,AX           ;First sector number to retry
        PUSH    DX
        MUL     [BP.SECSIZ]     ;Number of bytes transferred
        POP     DX
        ADD     BX,AX           ;First address for retry
        MOV     AH,0            ;Flag disk section in error
        CMP     DX,[BP.FIRFAT]  ;In reserved area?
        JB      ERRINT
        INC     AH              ;Flag for FAT
        CMP     DX,[BP.FIRDIR]  ;In FAT?
        JB      ERRINT
        INC     AH
        CMP     DX,[BP.FIRREC]  ;In directory?
        JB      ERRINT
        INC     AH              ;Must be in data area
ERRINT:
        SHL     AH,1            ;Make room for read/write bit
        OR      AH,CS:[READOP]
FATAL:
        MOV     AL,[BP.DRVNUM]  ;Get drive number
FATAL1:
        PUSH    BP              ;The only thing we preserve
        MOV     CS:[CONTSTK],SP
        CLI                     ;Prepare to play with stack
        MOV     SS,CS:[SSSAVE]
        MOV     SP,CS:[SPSAVE]  ;User stack pointer restored
        INT     24H             ;Fatal error interrupt vector
        MOV     CS:[SPSAVE],SP
        MOV     CS:[SSSAVE],SS
        MOV     SP,CS
        MOV     SS,SP
        MOV     SP,CS:[CONTSTK]
        STI
        POP     BP
        CMP     AL,2
        JZ      ERROR
        RET

DSKREAD:
        MOV     AL,[BP.DEVNUM]
        PUSH    BP
        PUSH    BX
        PUSH    CX
        PUSH    DX
        CALL    FAR PTR BIOSREAD 
        POP     DX
        POP     DI
        POP     BX
        POP     BP
RET9:   RET


CHKDIRWRITE:
        TEST    BYTE PTR [DIRTYDIR],-1
        JZ      RET9

DIRWRITE:

; Inputs:
;       DS = CS
;       AL = Directory block number
;       BP = Base of drive parameters
; Function:
;       Write the directory block into DIRBUF.
; Outputs:
;       BP unchanged
; All other registers destroyed.

        MOV     BYTE PTR [DIRTYDIR],0
        MOV     AL,BYTE PTR [DIRBUFID]
        CALL    DIRCOMP


DWRITE:

; Inputs:
;       BX,DS = Transfer address
;       CX = Number of sectors
;       DX = Absolute record number
;       BP = Base of drive parameters
; Function:
;       Calls BIOS to perform disk write. If BIOS reports
;       errors, will call HARDERR for further action.
; BP preserved. All other registers destroyed.

        MOV     AL,[BP.DEVNUM]
        MOV     AH,CS:VERFLG
        PUSH    BP
        PUSH    BX
        PUSH    CX
        PUSH    DX
        CALL    FAR PTR BIOSWRITE 
        POP     DX
        POP     DI
        POP     BX
        POP     BP
        JNC     RET9
        MOV     CS:BYTE PTR [READOP],1
        CALL    HARDERR
        CMP     AL,1            ;Check for retry
        JZ      DWRITE
        RET


ABORT:
        LDS     SI,CS:DWORD PTR [SPSAVE]
        MOV     DS,[SI.CSSAVE]
        XOR     AX,AX
        MOV     ES,AX
        MOV     SI,SAVEXIT
        MOV     DI,EXIT
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        MOVSW
ERROR:
        MOV     AX,CS
        MOV     DS,AX
        MOV     ES,AX
        CALL    WRTFATS
        XOR     AX,AX
        CLI
        MOV     SS,[SSSAVE]
        MOV     SP,[SPSAVE]
        MOV     DS,AX
        MOV     SI,EXIT
        MOV     DI,OFFSET DOSGROUP:EXITHOLD
        MOVSW
        MOVSW
        POP     AX
        POP     BX
        POP     CX
        POP     DX
        POP     SI
        POP     DI
        POP     BP
        POP     DS
        POP     ES
        STI             ;Stack OK now
        JMP     CS:DWORD PTR [EXITHOLD]


SEQRD:  ;System call 20
        CALL    GETREC
        CALL    LOAD
        JMP     SHORT FINSEQ

SEQWRT: ;System call 21
        CALL    GETREC
        CALL    STORE
FINSEQ:
        JCXZ    SETNREX
        ADD     AX,1
        ADC     DX,0
        JMP     SHORT SETNREX

RNDRD:  ;System call 33
        CALL    GETRRPOS1
        CALL    LOAD
        JMP     SHORT FINRND

RNDWRT: ;System call 34
        CALL    GETRRPOS1
        CALL    STORE
        JMP     SHORT FINRND

BLKRD:  ;System call 39
        CALL    GETRRPOS
        CALL    LOAD
        JMP     SHORT FINBLK

BLKWRT: ;System call 40
        CALL    GETRRPOS
        CALL    STORE
FINBLK:
        LDS     SI,DWORD PTR [SPSAVE]
        MOV     [SI.CXSAVE],CX
        JCXZ    FINRND
        ADD     AX,1
        ADC     DX,0
FINRND:
        MOV     ES:WORD PTR [DI.RR],AX
        MOV     ES:[DI.RR+2],DL
        OR      DH,DH
        JZ      SETNREX
        MOV     ES:[DI.RR+3],DH ;Save 4 byte of RECPOS only if significant
SETNREX:
        MOV     CX,AX
        AND     AL,7FH
        MOV     ES:[DI.NR],AL
        AND     CL,80H
        SHL     CX,1
        RCL     DX,1
        MOV     AL,CH
        MOV     AH,DL
        MOV     ES:[DI.EXTENT],AX
        MOV     AL,CS:[DSKERR]
        RET

GETRRPOS1:
        MOV     CX,1
GETRRPOS:
        MOV     DI,DX
        CMP     BYTE PTR [DI],-1
        JNZ     NORMFCB1
        ADD     DI,7
NORMFCB1:
        MOV     AX,WORD PTR [DI.RR]
        MOV     DX,WORD PTR [DI.RR+2]
        RET

NOFILERR:
        XOR     CX,CX
        MOV     BYTE PTR [DSKERR],4
        POP     BX
        RET

SETUP:

; Inputs:
;       DS:DI point to FCB
;       DX:AX = Record position in file of disk transfer
;       CX = Record count
; Outputs:
;       DS = CS
;       ES:DI point to FCB
;       BL = DEVID from FCB
;       CX = No. of bytes to transfer
;       BP = Base of drive parameters
;       SI = FAT pointer
;       [RECCNT] = Record count
;       [RECPOS] = Record position in file
;       [FCB] = DI
;       [NEXTADD] = Displacement of disk transfer within segment
;       [SECPOS] = Position of first sector
;       [BYTPOS] = Byte position in file
;       [BYTSECPOS] = Byte position in first sector
;       [CLUSNUM] = First cluster
;       [SECCLUSPOS] = Sector within first cluster
;       [DSKERR] = 0 (no errors yet)
;       [TRANS] = 0 (No transfers yet)
;       [THISDRV] = Physical drive unit number
; If SETUP detects no records will be transfered, it returns 1 level up 
; with CX = 0.

        PUSH    AX
        MOV     AL,[DI]
        DEC     AL
        MOV     CS:[THISDRV],AL
        MOV     AL,[DI.DEVID]
        MOV     SI,[DI.RECSIZ]
        OR      SI,SI
        JNZ     HAVRECSIZ
        MOV     SI,128
        MOV     [DI.RECSIZ],SI
HAVRECSIZ:
        PUSH    DS
        POP     ES              ;Set ES to DS
        PUSH    CS
        POP     DS              ;Set DS to CS
        OR      AL,AL           ;Is it a device?
        JNS     NOTDEVICE
        MOV     AL,0            ;Fake in drive 0 so we can get SP
NOTDEVICE:
        CALL    GETBP
        POP     AX
        JC      NOFILERR
        CMP     SI,64           ;Check if highest byte of RECPOS is significant
        JB      SMALREC
        MOV     DH,0            ;Ignore MSB if record >= 64 bytes
SMALREC:
        MOV     [RECCNT],CX
        MOV     WORD PTR [RECPOS],AX
        MOV     WORD PTR [RECPOS+2],DX
        MOV     [FCB],DI
        MOV     BX,[DMAADD]
        MOV     [NEXTADD],BX
        MOV     BYTE PTR [DSKERR],0
        MOV     BYTE PTR [TRANS],0
        MOV     BX,DX
        MUL     SI
        MOV     WORD PTR [BYTPOS],AX
        PUSH    DX
        MOV     AX,BX
        MUL     SI
        POP     BX
        ADD     AX,BX
        ADC     DX,0            ;Ripple carry
        JNZ     EOFERR
        MOV     WORD PTR [BYTPOS+2],AX
        MOV     DX,AX
        MOV     AX,WORD PTR [BYTPOS]
        MOV     BX,[BP.SECSIZ]
        CMP     DX,BX           ;See if divide will overflow
        JNC     EOFERR
        DIV     BX
        MOV     [SECPOS],AX
        MOV     [BYTSECPOS],DX
        MOV     DX,AX
        AND     AL,[BP.CLUSMSK]
        MOV     [SECCLUSPOS],AL
        MOV     AX,CX           ;Record count
        MOV     CL,[BP.CLUSSHFT]
        SHR     DX,CL
        MOV     [CLUSNUM],DX
        MUL     SI              ;Multiply by bytes per record
        MOV     CX,AX
        ADD     AX,[DMAADD]     ;See if it will fit in one segment
        ADC     DX,0
        JZ      OK              ;Must be less than 64K
        MOV     AX,[DMAADD]
        NEG     AX              ;Amount of room left in segment
        JNZ     PARTSEG         ;All 64K available?
        DEC     AX              ;If so, reduce by one
PARTSEG:
        XOR     DX,DX
        DIV     SI              ;How many records will fit?
        MOV     [RECCNT],AX
        MUL     SI              ;Translate that back into bytes
        MOV     BYTE PTR [DSKERR],2     ;Flag that trimming took place
        MOV     CX,AX
        JCXZ    NOROOM
OK:
        MOV     BL,ES:[DI.DEVID]
        MOV     SI,[BP.FAT]
        RET

EOFERR:
        MOV     BYTE PTR [DSKERR],1
        XOR     CX,CX
NOROOM:
        POP     BX              ;Kill return address
        RET

BREAKDOWN:

;Inputs:
;       DS = CS
;       CX = Length of disk transfer in bytes
;       BP = Base of drive parameters
;       [BYTSECPOS] = Byte position witin first sector
;Outputs:
;       [BYTCNT1] = Bytes to transfer in first sector
;       [SECCNT] = No. of whole sectors to transfer
;       [BYTCNT2] = Bytes to transfer in last sector
;AX, BX, DX destroyed. No other registers affected.

        MOV     AX,[BYTSECPOS]
        MOV     BX,CX
        OR      AX,AX
        JZ      SAVFIR          ;Partial first sector?
        SUB     AX,[BP.SECSIZ]
        NEG     AX              ;Max number of bytes left in first sector
        SUB     BX,AX           ;Subtract from total length
        JAE     SAVFIR
        ADD     AX,BX           ;Don't use all of the rest of the sector
        XOR     BX,BX           ;And no bytes are left
SAVFIR:
        MOV     [BYTCNT1],AX
        MOV     AX,BX
        XOR     DX,DX
        DIV     [BP.SECSIZ]     ;How many whole sectors?
        MOV     [SECCNT],AX
        MOV     [BYTCNT2],DX    ;Bytes remaining for last sector
RET10:  RET


FNDCLUS:

; Inputs:
;       DS = CS
;       CX = No. of clusters to skip
;       BP = Base of drive parameters
;       SI = FAT pointer
;       ES:DI point to FCB
; Outputs:
;       BX = Last cluster skipped to
;       CX = No. of clusters remaining (0 unless EOF)
;       DX = Position of last cluster
; DI destroyed. No other registers affected.

        MOV     BX,ES:[DI.LSTCLUS]
        MOV     DX,ES:[DI.CLUSPOS]
        OR      BX,BX
        JZ      NOCLUS
        SUB     CX,DX
        JNB     FINDIT
        ADD     CX,DX
        XOR     DX,DX
        MOV     BX,ES:[DI.FIRCLUS]
FINDIT:
        JCXZ    RET10
SKPCLP:
        CALL    UNPACK
        CMP     DI,0FF8H
        JAE     RET10
        XCHG    BX,DI
        INC     DX
        LOOP    SKPCLP
        RET
NOCLUS:
        INC     CX
        DEC     DX
        RET


BUFSEC:
; Inputs:
;       AL = 0 if buffer must be read, 1 if no pre-read needed
;       BP = Base of drive parameters
;       [CLUSNUM] = Physical cluster number
;       [SECCLUSPOS] = Sector position of transfer within cluster
;       [BYTCNT1] = Size of transfer
; Function:
;       Insure specified sector is in buffer, flushing buffer before
;       read if necessary.
; Outputs:
;       SI = Pointer to buffer
;       DI = Pointer to transfer address
;       CX = Number of bytes
;       [NEXTADD] updated
;       [TRANS] set to indicate a transfer will occur

        MOV     DX,[CLUSNUM]
        MOV     BL,[SECCLUSPOS]
        CALL    FIGREC
        MOV     [PREREAD],AL
        CMP     DX,[BUFSECNO]
        JNZ     GETSEC
        MOV     AL,[BUFDRVNO]
        CMP     AL,[THISDRV]
        JZ      FINBUF          ;Already have it?
GETSEC:
        XOR     AL,AL
        XCHG    [DIRTYBUF],AL   ;Read dirty flag and reset it
        OR      AL,AL
        JZ      RDSEC
        PUSH    DX
        PUSH    BP
        MOV     BP,[BUFDRVBP]
        MOV     BX,[BUFFER]
        MOV     CX,1
        MOV     DX,[BUFSECNO]
        CALL    DWRITE
        POP     BP
        POP     DX
RDSEC:
        TEST    BYTE PTR [PREREAD],-1
        JNZ     SETBUF
        XOR     AX,AX
        MOV     [BUFSECNO],AX           ;Set buffer valid in case of disk error
        DEC     AX
        MOV     [BUFDRVNO],AL
        MOV     BX,[BUFFER]
        MOV     CX,1
        PUSH    DX
        CALL    DREAD
        POP     DX
SETBUF:
        MOV     [BUFSECNO],DX
        MOV     AL,[THISDRV]
        MOV     [BUFDRVNO],AL
        MOV     [BUFDRVBP],BP
FINBUF:
        MOV     BYTE PTR [TRANS],1      ;A transfer is taking place
        MOV     DI,[NEXTADD]
        MOV     SI,DI
        MOV     CX,[BYTCNT1]
        ADD     SI,CX
        MOV     [NEXTADD],SI
        MOV     SI,[BUFFER]
        ADD     SI,[BYTSECPOS]
        RET

BUFRD:
        XOR     AL,AL           ;Pre-read necessary
        CALL    BUFSEC
        PUSH    ES
        MOV     ES,[DMAADD+2]
        SHR     CX,1
        JNC     EVENRD
        MOVSB
EVENRD:
        REP     MOVSW
        POP     ES
        RET

BUFWRT:
        MOV     AX,[SECPOS]
        INC     AX              ;Set for next sector
        MOV     [SECPOS],AX
        CMP     AX,[VALSEC]     ;Has sector been written before?
        MOV     AL,1
        JA      NOREAD          ;Skip preread if SECPOS>VALSEC
        MOV     AL,0
NOREAD:
        CALL    BUFSEC
        XCHG    DI,SI
        PUSH    DS
        PUSH    ES
        PUSH    CS
        POP     ES
        MOV     DS,[DMAADD+2]
        SHR     CX,1
        JNC     EVENWRT
        MOVSB
EVENWRT:
        REP     MOVSW
        POP     ES
        POP     DS
        MOV     BYTE PTR [DIRTYBUF],1
        RET

NEXTSEC:
        TEST    BYTE PTR [TRANS],-1
        JZ      CLRET
        MOV     AL,[SECCLUSPOS]
        INC     AL
        CMP     AL,[BP.CLUSMSK]
        JBE     SAVPOS
        MOV     BX,[CLUSNUM]
        CMP     BX,0FF8H
        JAE     NONEXT
        MOV     SI,[BP.FAT]
        CALL    UNPACK
        MOV     [CLUSNUM],DI
        INC     [LASTPOS]
        MOV     AL,0
SAVPOS:
        MOV     [SECCLUSPOS],AL
CLRET:
        CLC
        RET
NONEXT:
        STC
        RET

TRANBUF:
        LODSB
        STOSB
        CMP     AL,13           ;Check for carriage return
        JNZ     NORMCH
        MOV     BYTE PTR [SI],10
NORMCH:
        CMP     AL,10
        LOOPNZ  TRANBUF
        JNZ     ENDRDCON
        CALL    OUT             ;Transmit linefeed
        XOR     SI,SI
        OR      CX,CX
        JNZ     GETBUF
        OR      AL,1            ;Clear zero flag--not end of file
ENDRDCON:
        MOV     [CONTPOS],SI
ENDRDDEV:
        MOV     [NEXTADD],DI
        POP     ES
        JNZ     SETFCBJ         ;Zero set if Ctrl-Z found in input
        MOV     DI,[FCB]
        AND     ES:BYTE PTR [DI.DEVID],0FFH-40H ;Mark as no more data available
SETFCBJ:
        JMP     SETFCB

READDEV:
        PUSH    ES
        LES     DI,DWORD PTR [DMAADD]
        INC     BL
        JZ      READCON
        INC     BL
        JNZ     ENDRDDEV
READAUX:
        CALL    AUXIN
        STOSB
        CMP     AL,1AH
        LOOPNZ  READAUX
        JMP     SHORT ENDRDDEV

READCON:
        PUSH    CS
        POP     DS
        MOV     SI,[CONTPOS]
        OR      SI,SI
        JNZ     TRANBUF
        CMP     BYTE PTR [CONBUF],128
        JZ      GETBUF
        MOV     WORD PTR [CONBUF],0FF80H        ;Set up 128-byte buffer with no template
GETBUF:
        PUSH    CX
        PUSH    ES
        PUSH    DI
        MOV     DX,OFFSET DOSGROUP:CONBUF
        CALL    BUFIN           ;Get input buffer
        POP     DI
        POP     ES
        POP     CX
        MOV     SI,2 + OFFSET DOSGROUP:CONBUF
        CMP     BYTE PTR [SI],1AH       ;Check for Ctrl-Z in first character
        JNZ     TRANBUF
        MOV     AL,1AH
        STOSB
        MOV     AL,10
        CALL    OUT             ;Send linefeed
        XOR     SI,SI
        JMP     SHORT ENDRDCON

RDERR:
        XOR     CX,CX
        JMP     WRTERR

RDLASTJ:JMP     RDLAST

LOAD:

; Inputs:
;       DS:DI point to FCB
;       DX:AX = Position in file to read
;       CX = No. of records to read
; Outputs:
;       DX:AX = Position of last record read
;       CX = No. of bytes read
;       ES:DI point to FCB
;       LSTCLUS, CLUSPOS fields in FCB set

        CALL    SETUP
        OR      BL,BL           ;Check for named device I/O
        JS      READDEV
        MOV     AX,ES:WORD PTR [DI.FILSIZ]
        MOV     BX,ES:WORD PTR [DI.FILSIZ+2]
        SUB     AX,WORD PTR [BYTPOS]
        SBB     BX,WORD PTR [BYTPOS+2]
        JB      RDERR
        JNZ     ENUF
        OR      AX,AX
        JZ      RDERR
        CMP     AX,CX
        JAE     ENUF
        MOV     CX,AX
ENUF:
        CALL    BREAKDOWN
        MOV     CX,[CLUSNUM]
        CALL    FNDCLUS
        OR      CX,CX
        JNZ     RDERR
        MOV     [LASTPOS],DX
        MOV     [CLUSNUM],BX
        CMP     [BYTCNT1],0
        JZ      RDMID
        CALL    BUFRD
RDMID:
        CMP     [SECCNT],0
        JZ      RDLASTJ
        CALL    NEXTSEC
        JC      SETFCB
        MOV     BYTE PTR [TRANS],1      ;A transfer is taking place
ONSEC:
        MOV     DL,[SECCLUSPOS]
        MOV     CX,[SECCNT]
        MOV     BX,[CLUSNUM]
RDLP:
        CALL    OPTIMIZE
        PUSH    DI
        PUSH    AX
        PUSH    DS
        MOV     DS,[DMAADD+2]
        PUSH    DX
        PUSH    BX
        PUSHF                   ;Save carry flag
        CALL DREAD
        POPF                    ;Restore carry flag
        POP     DI              ;Initial transfer address
        POP     AX              ;First sector transfered
        POP     DS
        JC      NOTBUFFED       ;Was one of those sectors in the buffer?
        CMP     BYTE PTR [DIRTYBUF],0   ;Is buffer dirty?
        JZ      NOTBUFFED       ;If not no problem
;We have transfered in a sector from disk when a dirty copy of it is in the buffer.
;We must transfer the sector from the buffer to correct memory address
        SUB     AX,[BUFSECNO]   ;How many sectors into the transfer?
        NEG     AX
        MOV     CX,[BP.SECSIZ]
        MUL     CX              ;How many bytes into the transfer?
        ADD     DI,AX
        MOV     SI,[BUFFER]
        PUSH    ES
        MOV     ES,[DMAADD+2]   ;Get disk transfer segment
        SHR     CX,1
        REP     MOVSW
        JNC     EVENMOV
        MOVSB
EVENMOV:
        POP     ES
NOTBUFFED:
        POP     CX
        POP     BX
        JCXZ    RDLAST
        CMP     BX,0FF8H
        JAE     SETFCB
        MOV     DL,0
        INC     [LASTPOS]       ;We'll be using next cluster
        JMP     SHORT RDLP

SETFCB:
        MOV     SI,[FCB]
        MOV     AX,[NEXTADD]
        MOV     DI,AX
        SUB     AX,[DMAADD]     ;Number of bytes transfered
        XOR     DX,DX
        MOV     CX,ES:[SI.RECSIZ]
        DIV     CX              ;Number of records
        CMP     AX,[RECCNT]     ;Check if all records transferred
        JZ      FULLREC
        MOV     BYTE PTR [DSKERR],1
        OR      DX,DX
        JZ      FULLREC         ;If remainder 0, then full record transfered
        MOV     BYTE PTR [DSKERR],3     ;Flag partial last record
        SUB     CX,DX           ;Bytes left in last record
        PUSH    ES
        MOV     ES,[DMAADD+2]
        XCHG    AX,BX           ;Save the record count temporarily
        XOR     AX,AX           ;Fill with zeros
        SHR     CX,1
        JNC     EVENFIL
        STOSB
EVENFIL:
        REP     STOSW
        XCHG    AX,BX           ;Restore record count to AX
        POP     ES
        INC     AX              ;Add last (partial) record to total
FULLREC:
        MOV     CX,AX
        MOV     DI,SI           ;ES:DI point to FCB
SETCLUS:
        MOV     AX,[CLUSNUM]
        MOV     ES:[DI.LSTCLUS],AX
        MOV     AX,[LASTPOS]
        MOV     ES:[DI.CLUSPOS],AX
ADDREC:
        MOV     AX,WORD PTR [RECPOS]
        MOV     DX,WORD PTR [RECPOS+2]
        JCXZ    RET28           ;If no records read, don't change position
        DEC     CX
        ADD     AX,CX           ;Update current record position
        ADC     DX,0
        INC     CX      
RET28:  RET

RDLAST:
        MOV     AX,[BYTCNT2]
        OR      AX,AX
        JZ      SETFCB
        MOV     [BYTCNT1],AX
        CALL    NEXTSEC
        JC      SETFCB
        MOV     [BYTSECPOS],0
        CALL    BUFRD
        JMP     SHORT SETFCB

WRTDEV:
        PUSH    DS
        LDS     SI,DWORD PTR [DMAADD]
        OR      BL,40H
        INC     BL
        JZ      WRTCON
        INC     BL
        JZ      WRTAUX
        INC     BL
        JZ      ENDWRDEV        ;Done if device is NUL
WRTLST:
        LODSB
        CMP     AL,1AH
        JZ      ENDWRDEV
        CALL    LISTOUT
        LOOP    WRTLST
        JMP     SHORT ENDWRDEV

WRTAUX:
        LODSB
        CALL    AUXOUT
        CMP     AL,1AH
        LOOPNZ  WRTAUX
        JMP     SHORT ENDWRDEV

WRTCON:
        LODSB
        CMP     AL,1AH
        JZ      ENDWRDEV
        CALL    OUT
        LOOP    WRTCON
ENDWRDEV:
        POP     DS
        MOV     CX,[RECCNT]
        MOV     DI,[FCB]
        JMP     SHORT ADDREC

HAVSTART:
        MOV     CX,AX
        CALL    SKPCLP
        JCXZ    DOWRTJ
        CALL    ALLOCATE
        JNC     DOWRTJ
WRTERR:
        MOV     BYTE PTR [DSKERR],1
LVDSK:
        MOV     AX,WORD PTR [RECPOS]
        MOV     DX,WORD PTR [RECPOS+2]
        MOV     DI,[FCB]
        RET

DOWRTJ: JMP     DOWRT

WRTEOFJ:
        JMP     WRTEOF

STORE:

; Inputs:
;       DS:DI point to FCB
;       DX:AX = Position in file of disk transfer
;       CX = Record count
; Outputs:
;       DX:AX = Position of last record written
;       CX = No. of records written
;       ES:DI point to FCB
;       LSTCLUS, CLUSPOS fields in FCB set

        CALL    SETUP
        CALL    DATE16
        MOV     ES:[DI.FDATE],AX
        MOV     ES:[DI.FTIME],DX
        OR      BL,BL
        JS      WRTDEV
        AND     BL,3FH          ;Mark file as dirty
        MOV     ES:[DI.DEVID],BL
        CALL    BREAKDOWN
        MOV     AX,WORD PTR [BYTPOS]
        MOV     DX,WORD PTR [BYTPOS+2]
        JCXZ    WRTEOFJ
        DEC     CX
        ADD     AX,CX
        ADC     DX,0            ;AX:DX=last byte accessed
        DIV     [BP.SECSIZ]     ;AX=last sector accessed
        MOV     CL,[BP.CLUSSHFT]
        SHR     AX,CL           ;Last cluster to be accessed
        PUSH    AX
        MOV     AX,ES:WORD PTR [DI.FILSIZ]
        MOV     DX,ES:WORD PTR [DI.FILSIZ+2]
        DIV     [BP.SECSIZ]
        OR      DX,DX
        JZ      NORNDUP
        INC     AX              ;Round up if any remainder
NORNDUP:
        MOV     [VALSEC],AX     ;Number of sectors that have been written
        POP     AX
        MOV     CX,[CLUSNUM]    ;First cluster accessed
        CALL    FNDCLUS
        MOV     [CLUSNUM],BX
        MOV     [LASTPOS],DX
        SUB     AX,DX           ;Last cluster minus current cluster
        JZ      DOWRT           ;If we have last clus, we must have first
        JCXZ    HAVSTART        ;See if no more data
        PUSH    CX              ;No. of clusters short of first
        MOV     CX,AX
        CALL    ALLOCATE
        POP     AX
        JC      WRTERR
        MOV     CX,AX
        MOV     DX,[LASTPOS]
        INC     DX
        DEC     CX
        JZ      NOSKIP
        CALL    SKPCLP
NOSKIP:
        MOV     [CLUSNUM],BX
        MOV     [LASTPOS],DX
DOWRT:
        CMP     [BYTCNT1],0
        JZ      WRTMID
        MOV     BX,[CLUSNUM]
        CALL    BUFWRT  
WRTMID:
        MOV     AX,[SECCNT]
        OR      AX,AX
        JZ      WRTLAST
        ADD     [SECPOS],AX
        CALL    NEXTSEC
        MOV     BYTE PTR [TRANS],1      ;A transfer is taking place
        MOV     DL,[SECCLUSPOS]
        MOV     BX,[CLUSNUM]
        MOV     CX,[SECCNT]
WRTLP:
        CALL    OPTIMIZE
        JC      NOTINBUF        ;Is one of the sectors buffered?
        MOV     [BUFSECNO],0    ;If so, invalidate the buffer since we're
        MOV     WORD PTR [BUFDRVNO],0FFH        ;       completely rewritting it
NOTINBUF:
        PUSH    DI
        PUSH    AX
        PUSH    DS
        MOV     DS,[DMAADD+2]
        CALL    DWRITE
        POP     DS
        POP     CX
        POP     BX
        JCXZ    WRTLAST
        MOV     DL,0
        INC     [LASTPOS]       ;We'll be using next cluster
        JMP     SHORT WRTLP
WRTLAST:
        MOV     AX,[BYTCNT2]
        OR      AX,AX
        JZ      FINWRT
        MOV     [BYTCNT1],AX
        CALL    NEXTSEC
        MOV     [BYTSECPOS],0
        CALL    BUFWRT
FINWRT:
        MOV     AX,[NEXTADD]
        SUB     AX,[DMAADD]
        ADD     AX,WORD PTR [BYTPOS]
        MOV     DX,WORD PTR [BYTPOS+2]
        ADC     DX,0
        MOV     CX,DX
        MOV     DI,[FCB]
        CMP     AX,ES:WORD PTR [DI.FILSIZ]
        SBB     CX,ES:WORD PTR [DI.FILSIZ+2]
        JB      SAMSIZ
        MOV     ES:WORD PTR [DI.FILSIZ],AX
        MOV     ES:WORD PTR [DI.FILSIZ+2],DX
SAMSIZ:
        MOV     CX,[RECCNT]
        JMP     SETCLUS


WRTERRJ:JMP     WRTERR

WRTEOF:
        MOV     CX,AX
        OR      CX,DX
        JZ      KILLFIL
        SUB     AX,1
        SBB     DX,0
        DIV     [BP.SECSIZ]
        MOV     CL,[BP.CLUSSHFT]
        SHR     AX,CL
        MOV     CX,AX
        CALL    FNDCLUS
        JCXZ    RELFILE
        CALL    ALLOCATE
        JC      WRTERRJ
UPDATE:
        MOV     DI,[FCB]
        MOV     AX,WORD PTR [BYTPOS]
        MOV     ES:WORD PTR [DI.FILSIZ],AX
        MOV     AX,WORD PTR [BYTPOS+2]
        MOV     ES:WORD PTR [DI.FILSIZ+2],AX
        XOR     CX,CX
        JMP     ADDREC

RELFILE:
        MOV     DX,0FFFH
        CALL    RELBLKS
SETDIRT:
        MOV     BYTE PTR [SI-1],1
        JMP     SHORT UPDATE

KILLFIL:
        XOR     BX,BX
        XCHG    BX,ES:[DI.FIRCLUS]
        OR      BX,BX
        JZ      UPDATE
        CALL    RELEASE
        JMP     SHORT SETDIRT


OPTIMIZE:

; Inputs:
;       DS = CS
;       BX = Physical cluster
;       CX = No. of records
;       DL = sector within cluster
;       BP = Base of drives parameters
;       [NEXTADD] = transfer address
; Outputs:
;       AX = No. of records remaining
;       BX = Transfer address
;       CX = No. or records to be transferred
;       DX = Physical sector address
;       DI = Next cluster
;       Carry clear if a sector to transfer is in the buffer
;       Carry set otherwise
;       [CLUSNUM] = Last cluster accessed
;       [NEXTADD] updated
; BP unchanged. Note that segment of transfer not set.

        PUSH    DX
        PUSH    BX
        MOV     AL,[BP.CLUSMSK]
        INC     AL              ;Number of sectors per cluster
        MOV     AH,AL
        SUB     AL,DL           ;AL = Number of sectors left in first cluster
        MOV     DX,CX
        MOV     SI,[BP.FAT]
        MOV     CX,0
OPTCLUS:
;AL has number of sectors available in current cluster
;AH has number of sectors available in next cluster
;BX has current physical cluster
;CX has number of sequential sectors found so far
;DX has number of sectors left to transfer
;SI has FAT pointer
        CALL    UNPACK
        ADD     CL,AL
        ADC     CH,0
        CMP     CX,DX
        JAE     BLKDON
        MOV     AL,AH
        INC     BX
        CMP     DI,BX
        JZ      OPTCLUS
        DEC     BX
FINCLUS:
        MOV     [CLUSNUM],BX    ;Last cluster accessed
        SUB     DX,CX           ;Number of sectors still needed
        PUSH    DX
        MOV     AX,CX
        MUL     [BP.SECSIZ]     ;Number of sectors times sector size
        MOV     SI,[NEXTADD]
        ADD     AX,SI           ;Adjust by size of transfer
        MOV     [NEXTADD],AX
        POP     AX              ;Number of sectors still needed
        POP     DX              ;Starting cluster
        SUB     BX,DX           ;Number of new clusters accessed
        ADD     [LASTPOS],BX
        POP     BX              ;BL = sector postion within cluster
        CALL    FIGREC
        MOV     BX,SI
;Now let's see if any of these sectors are already in the buffer
        CMP     [BUFSECNO],DX
        JC      RET100          ;If DX > [BUFSECNO] then not in buffer
        MOV     SI,DX
        ADD     SI,CX           ;Last sector + 1
        CMP     [BUFSECNO],SI
        CMC
        JC      RET100          ;If SI <= [BUFSECNO] then not in buffer
        PUSH    AX
        MOV     AL,[BP.DEVNUM]
        CMP     AL,[BUFDRVNO]   ;Is buffer for this drive?
        POP     AX
        JZ      RET100          ;If so, then we match 
        STC                     ;No match
RET100: RET
BLKDON:
        SUB     CX,DX           ;Number of sectors in cluster we don't want
        SUB     AH,CL           ;Number of sectors in cluster we accepted
        DEC     AH              ;Adjust to mean position within cluster
        MOV     [SECCLUSPOS],AH
        MOV     CX,DX           ;Anyway, make the total equal to the request
        JMP     SHORT FINCLUS


FIGREC:

;Inputs:
;       DX = Physical cluster number
;       BL = Sector postion within cluster
;       BP = Base of drive parameters
;Outputs:
;       DX = physical sector number
;No other registers affected.

        PUSH    CX
        MOV     CL,[BP.CLUSSHFT]
        DEC     DX
        DEC     DX
        SHL     DX,CL
        OR      DL,BL
        ADD     DX,[BP.FIRREC]
        POP     CX
        RET

GETREC:

; Inputs:
;       DS:DX point to FCB
; Outputs:
;       CX = 1
;       DX:AX = Record number determined by EXTENT and NR fields
;       DS:DI point to FCB
; No other registers affected.

        MOV     DI,DX
        CMP     BYTE PTR [DI],-1        ;Check for extended FCB
        JNZ     NORMFCB2
        ADD     DI,7
NORMFCB2:
        MOV     CX,1
        MOV     AL,[DI.NR]
        MOV     DX,[DI.EXTENT]
        SHL     AL,1
        SHR     DX,1
        RCR     AL,1
        MOV     AH,DL
        MOV     DL,DH
        MOV     DH,0
        RET


ALLOCATE:

; Inputs:
;       DS = CS
;       ES = Segment of FCB
;       BX = Last cluster of file (0 if null file)
;       CX = No. of clusters to allocate
;       DX = Position of cluster BX
;       BP = Base of drive parameters
;       SI = FAT pointer
;       [FCB] = Displacement of FCB within segment
; Outputs:
;       IF insufficient space
;         THEN
;       Carry set
;       CX = max. no. of records that could be added to file
;         ELSE
;       Carry clear
;       BX = First cluster allocated
;       FAT is fully updated including dirty bit
;       FIRCLUS field of FCB set if file was null
; SI,BP unchanged. All other registers destroyed.

        PUSH    [SI]
        PUSH    DX
        PUSH    CX
        PUSH    BX
        MOV     AX,BX
ALLOC:
        MOV     DX,BX
FINDFRE:
        INC     BX
        CMP     BX,[BP.MAXCLUS]
        JLE     TRYOUT
        CMP     AX,1
        JG      TRYIN
        POP     BX
        MOV     DX,0FFFH
        CALL    RELBLKS
        POP     AX              ;No. of clusters requested
        SUB     AX,CX           ;AX=No. of clusters allocated
        POP     DX
        POP     [SI]
        INC     DX              ;Position of first cluster allocated
        ADD     AX,DX           ;AX=max no. of cluster in file
        MOV     DL,[BP.CLUSMSK]
        MOV     DH,0
        INC     DX              ;DX=records/cluster
        MUL     DX              ;AX=max no. of records in file
        MOV     CX,AX
        SUB     CX,WORD PTR [RECPOS]    ;CX=max no. of records that could be written
        JA      MAXREC
        XOR     CX,CX           ;If CX was negative, zero it
MAXREC:
        STC
RET11:  RET

TRYOUT:
        CALL    UNPACK
        JZ      HAVFRE
TRYIN:
        DEC     AX
        JLE     FINDFRE
        XCHG    AX,BX
        CALL    UNPACK
        JZ      HAVFRE
        XCHG    AX,BX
        JMP     SHORT FINDFRE
HAVFRE:
        XCHG    BX,DX
        MOV     AX,DX
        CALL    PACK
        MOV     BX,AX
        LOOP    ALLOC
        MOV     DX,0FFFH
        CALL    PACK
        MOV     BYTE PTR [SI-1],1
        POP     BX
        POP     CX              ;Don't need this stuff since we're successful
        POP     DX
        CALL    UNPACK
        POP     [SI]
        XCHG    BX,DI
        OR      DI,DI
        JNZ     RET11
        MOV     DI,[FCB]
        MOV     ES:[DI.FIRCLUS],BX
RET12:  RET


RELEASE:

; Inputs:
;       DS = CS
;       BX = Cluster in file
;       SI = FAT pointer
;       BP = Base of drive parameters
; Function:
;       Frees cluster chain starting with [BX]
; AX,BX,DX,DI all destroyed. Other registers unchanged.

        XOR     DX,DX
RELBLKS:
; Enter here with DX=0FFFH to put an end-of-file mark
; in the first cluster and free the rest in the chain.
        CALL    UNPACK
        JZ      RET12
        MOV     AX,DI
        CALL    PACK
        CMP     AX,0FF8H
        MOV     BX,AX
        JB      RELEASE
RET13:  RET


GETEOF:

; Inputs:
;       BX = Cluster in a file
;       SI = Base of drive FAT
;       DS = CS
; Outputs:
;       BX = Last cluster in the file
; DI destroyed. No other registers affected.

        CALL    UNPACK
        CMP     DI,0FF8H
        JAE     RET13
        MOV     BX,DI
        JMP     SHORT GETEOF


SRCHFRST: ;System call 17
        CALL    GETFILE
SAVPLCE:
; Search-for-next enters here to save place and report
; findings.
        JC      KILLSRCH
        OR      BH,BH
        JS      SRCHDEV
        MOV     AX,[LASTENT]
        MOV     ES:[DI.FILDIRENT],AX
        MOV     ES:[DI.DRVBP],BP
;Information in directory entry must be copied into the first
; 33 bytes starting at the disk transfer address.
        MOV     SI,BX
        LES     DI,DWORD PTR [DMAADD]
        MOV     AX,00FFH
        CMP     AL,[EXTFCB]
        JNZ     NORMFCB
        STOSW
        INC     AL
        STOSW
        STOSW
        MOV     AL,[ATTRIB]
        STOSB
NORMFCB:
        MOV     AL,[THISDRV]
        INC     AL
        STOSB   ;Set drive number
        MOV     CX,16
        REP     MOVSW   ;Copy remaining 10 characters of name
        XOR     AL,AL
        RET

KILLSRCH:
KILLSRCH1       EQU     KILLSRCH+1
;The purpose of the KILLSRCH1 label is to provide a jump label to the following
;   instruction which leaves out the segment override.
        MOV     WORD PTR ES:[DI.FILDIRENT],-1
        MOV     AL,-1
        RET

SRCHDEV:
        MOV     ES:[DI.FILDIRENT],BX
        LES     DI,DWORD PTR [DMAADD]
        XOR     AX,AX
        STOSB           ;Zero drive byte
        SUB     SI,4            ;Point to device name
        MOVSW
        MOVSW
        MOV     AX,2020H
        STOSB
        STOSW
        STOSW
        STOSW                   ;Fill with 8 blanks
        XOR     AX,AX
        MOV     CX,10
        REP     STOSW
        STOSB
RET14:  RET

SRCHNXT: ;System call 18
        CALL    MOVNAME
        MOV     DI,DX
        JC      NEAR PTR KILLSRCH1
        MOV     BP,[DI.DRVBP]
        MOV     AX,[DI.FILDIRENT]
        OR      AX,AX
        JS      NEAR PTR KILLSRCH1
        PUSH    DX
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     [LASTENT],AX
        CALL    CONTSRCH
        POP     ES
        POP     DI
        JMP     SAVPLCE


FILESIZE: ;System call 35
        CALL    GETFILE
        MOV     AL,-1
        JC      RET14
        ADD     DI,33           ;Write size in RR field
        MOV     CX,ES:[DI.RECSIZ-33]
        OR      CX,CX
        JNZ     RECOK
        MOV     CX,128
RECOK:
        XOR     AX,AX
        XOR     DX,DX           ;Intialize size to zero
        OR      BH,BH           ;Check for named I/O device
        JS      DEVSIZ
        INC     SI
        INC     SI              ;Point to length field
        MOV     AX,[SI+2]       ;Get high word of size
        DIV     CX
        PUSH    AX              ;Save high part of result
        LODSW           ;Get low word of size
        DIV     CX
        OR      DX,DX           ;Check for zero remainder
        POP     DX
        JZ      DEVSIZ
        INC     AX              ;Round up for partial record
        JNZ     DEVSIZ          ;Propagate carry?
        INC     DX
DEVSIZ:
        STOSW
        MOV     AX,DX
        STOSB
        MOV     AL,0
        CMP     CX,64
        JAE     RET14           ;Only 3-byte field if RECSIZ >= 64
        MOV     ES:[DI],AH
        RET


SETDMA: ;System call 26
        MOV     CS:[DMAADD],DX
        MOV     CS:[DMAADD+2],DS
        RET

NOSUCHDRV:
        MOV     AL,-1
        RET

GETFATPT: ;System call 27
        MOV     DL,0                    ;Use default drive

GETFATPTDL:     ;System call 28
        PUSH    CS
        POP     DS
        MOV     AL,DL
        CALL    GETTHISDRV
        JC      NOSUCHDRV
        CALL    FATREAD
        MOV     BX,[BP.FAT]
        MOV     AL,[BP.CLUSMSK]
        INC     AL
        MOV     DX,[BP.MAXCLUS]
        DEC     DX
        MOV     CX,[BP.SECSIZ]
        LDS     SI,DWORD PTR [SPSAVE]
        MOV     [SI.BXSAVE],BX
        MOV     [SI.DXSAVE],DX
        MOV     [SI.CXSAVE],CX
        MOV     [SI.DSSAVE],CS
        RET


GETDSKPT: ;System call 31
        PUSH    CS
        POP     DS
        MOV     AL,[CURDRV]
        MOV     [THISDRV],AL
        CALL    FATREAD
        LDS     SI,DWORD PTR [SPSAVE]
        MOV     [SI.BXSAVE],BP
        MOV     [SI.DSSAVE],CS
        RET


DSKRESET: ;System call 13
        PUSH    CS
        POP     DS
WRTFATS:
; DS=CS. Writes back all dirty FATs. All registers destroyed.
        XOR     AL,AL
        XCHG    AL,[DIRTYBUF]
        OR      AL,AL
        JZ      NOBUF
        MOV     BP,[BUFDRVBP]
        MOV     DX,[BUFSECNO]
        MOV     BX,[BUFFER]
        MOV     CX,1
        CALL    DWRITE
NOBUF:
        MOV     CL,[NUMIO]
        MOV     CH,0
        MOV     BP,[DRVTAB]
WRTFAT:
        PUSH    CX
        CALL    CHKFATWRT
        POP     CX
        ADD     BP,DPBSIZ
        LOOP    WRTFAT
        RET


GETDRV: ;System call 25
        MOV     AL,CS:[CURDRV]
RET15:  RET


SETRNDREC: ;System call 36
        CALL    GETREC
        MOV     [DI+33],AX
        MOV     [DI+35],DL
        CMP     [DI.RECSIZ],64
        JAE     RET15
        MOV     [DI+36],DH      ;Set 4th byte only if record size < 64
RET16:  RET


SELDSK: ;System call 14
        MOV     AL,CS:[NUMDRV]
        CMP     DL,AL
        JNB     RET17
        MOV     CS:[CURDRV],DL
RET17:  RET

BUFIN:  ;System call 10
        MOV     AX,CS
        MOV     ES,AX
        MOV     SI,DX
        MOV     CH,0
        LODSW
        OR      AL,AL
        JZ      RET17
        MOV     BL,AH
        MOV     BH,CH
        CMP     AL,BL
        JBE     NOEDIT
        CMP     BYTE PTR [BX+SI],0DH
        JZ      EDITON
NOEDIT:
        MOV     BL,CH
EDITON:
        MOV     DL,AL
        DEC     DX
NEWLIN:
        MOV     AL,CS:[CARPOS]
        MOV     CS:[STARTPOS],AL
        PUSH    SI
        MOV     DI,OFFSET DOSGROUP:INBUF
        MOV     AH,CH
        MOV     BH,CH
        MOV     DH,CH
GETCH:
        CALL    IN
        CMP     AL,"F"-"@"      ;Ignore ^F
        JZ      GETCH
        CMP     AL,CS:ESCCHAR
        JZ      ESC
        CMP     AL,7FH
        JZ      BACKSP
        CMP     AL,8
        JZ      BACKSP
        CMP     AL,13
        JZ      ENDLIN
        CMP     AL,10
        JZ      PHYCRLF
        CMP     AL,CANCEL
        JZ      KILNEW
SAVCH:
        CMP     DH,DL
        JAE     BUFFUL
        STOSB
        INC     DH
        CALL    BUFOUT
        OR      AH,AH
        JNZ     GETCH
        CMP     BH,BL
        JAE     GETCH
        INC     SI
        INC     BH
        JMP     SHORT GETCH

BUFFUL:
        MOV     AL,7
        CALL    OUT
        JMP     SHORT GETCH

ESC:
        CALL    IN
        MOV     CL,ESCTABLEN
        PUSH    DI
        MOV     DI,OFFSET DOSGROUP:ESCTAB
        REPNE   SCASB
        POP     DI
        SHL     CX,1
        MOV     BP,CX
        JMP     [BP+OFFSET DOSGROUP:ESCFUNC]

ENDLIN:
        STOSB
        CALL    OUT
        POP     DI
        MOV     [DI-1],DH
        INC     DH
COPYNEW:
        MOV     BP,ES
        MOV     BX,DS
        MOV     ES,BX
        MOV     DS,BP
        MOV     SI,OFFSET DOSGROUP:INBUF
        MOV     CL,DH
        REP     MOVSB
        RET
CRLF:
        MOV     AL,13
        CALL    OUT
        MOV     AL,10
        JMP     OUT

PHYCRLF:
        CALL    CRLF
        JMP     SHORT GETCH

KILNEW:
        MOV     AL,"\"
        CALL    OUT
        POP     SI
PUTNEW:
        CALL    CRLF
        MOV     AL,CS:[STARTPOS]
        CALL    TAB
        JMP     NEWLIN

BACKSP:
        OR      DH,DH
        JZ      OLDBAK
        CALL    BACKUP
        MOV     AL,ES:[DI]
        CMP     AL," "
        JAE     OLDBAK
        CMP     AL,9
        JZ      BAKTAB
        CALL    BACKMES
OLDBAK:
        OR      AH,AH
        JNZ     GETCH1
        OR      BH,BH
        JZ      GETCH1
        DEC     BH
        DEC     SI
GETCH1:
        JMP     GETCH
BAKTAB:
        PUSH    DI
        DEC     DI
        STD
        MOV     CL,DH
        MOV     AL," "
        PUSH    BX
        MOV     BL,7
        JCXZ    FIGTAB
FNDPOS:
        SCASB
        JNA     CHKCNT
        CMP     ES:BYTE PTR [DI+1],9
        JZ      HAVTAB
        DEC     BL
CHKCNT:
        LOOP    FNDPOS
FIGTAB:
        SUB     BL,CS:[STARTPOS]
HAVTAB:
        SUB     BL,DH
        ADD     CL,BL
        AND     CL,7
        CLD
        POP     BX
        POP     DI
        JZ      OLDBAK
TABBAK:
        CALL    BACKMES
        LOOP    TABBAK
        JMP     SHORT OLDBAK
BACKUP:
        DEC     DH
        DEC     DI
BACKMES:
        MOV     AL,8
        CALL    OUT
        MOV     AL," "
        CALL    OUT
        MOV     AL,8
        JMP     OUT

TWOESC:
        MOV     AL,ESCCH
        JMP     SAVCH

COPYLIN:
        MOV     CL,BL
        SUB     CL,BH
        JMP     SHORT COPYEACH

COPYSTR:
        CALL    FINDOLD
        JMP     SHORT COPYEACH

COPYONE:
        MOV     CL,1
COPYEACH:
        MOV     AH,0
        CMP     DH,DL
        JZ      GETCH2
        CMP     BH,BL
        JZ      GETCH2
        LODSB
        STOSB
        CALL    BUFOUT
        INC     BH
        INC     DH
        LOOP    COPYEACH
GETCH2:
        JMP     GETCH

SKIPONE:
        CMP     BH,BL
        JZ      GETCH2
        INC     BH
        INC     SI
        JMP     GETCH

SKIPSTR:
        CALL    FINDOLD
        ADD     SI,CX
        ADD     BH,CL
        JMP     GETCH

FINDOLD:
        CALL    IN
        MOV     CL,BL
        SUB     CL,BH
        JZ      NOTFND
        DEC     CX
        JZ      NOTFND
        PUSH    ES
        PUSH    DS
        POP     ES
        PUSH    DI
        MOV     DI,SI
        INC     DI
        REPNE   SCASB
        POP     DI
        POP     ES
        JNZ     NOTFND
        NOT     CL
        ADD     CL,BL
        SUB     CL,BH
RET30:  RET
NOTFND:
        POP     BP
        JMP     GETCH

REEDIT:
        MOV     AL,"@"
        CALL    OUT
        POP     DI
        PUSH    DI
        PUSH    ES
        PUSH    DS
        CALL    COPYNEW
        POP     DS
        POP     ES
        POP     SI
        MOV     BL,DH
        JMP     PUTNEW

ENTERINS:
        IF      TOGLINS
        NOT     AH
        JMP     GETCH
        ENDIF
        IF      NOT TOGLINS
        MOV     AH,-1
        JMP     GETCH

EXITINS:
        MOV     AH,0
        JMP     GETCH
        ENDIF

ESCFUNC DW      GETCH
        DW      TWOESC
        IF      NOT TOGLINS
        DW      EXITINS
        ENDIF
        DW      ENTERINS
        DW      BACKSP
        DW      REEDIT
        DW      KILNEW
        DW      COPYLIN
        DW      SKIPSTR
        DW      COPYSTR
        DW      SKIPONE
        DW      COPYONE

        IF      IBM
        DW      COPYONE
        DW      CTRLZ
CTRLZ:
        MOV     AL,"Z"-"@"
        JMP     SAVCH
        ENDIF
BUFOUT:
        CMP     AL," "
        JAE     OUT
        CMP     AL,9
        JZ      OUT
        PUSH    AX
        MOV     AL,"^"
        CALL    OUT
        POP     AX
        OR      AL,40H
        JMP     SHORT OUT

NOSTOP:
        CMP     AL,"P"-"@"
        JZ      INCHK
        IF      NOT TOGLPRN
        CMP     AL,"N"-"@"
        JZ      INCHK
        ENDIF
        CMP     AL,"C"-"@"
        JZ      INCHK
        RET

CONOUT: ;System call 2
        MOV     AL,DL
OUT:
        CMP     AL,20H
        JB      CTRLOUT
        CMP     AL,7FH
        JZ      OUTCH
        INC     CS:BYTE PTR [CARPOS]
OUTCH:
        PUSH    AX
        CALL    STATCHK
        POP     AX
        CALL    FAR PTR BIOSOUT 
        TEST    CS:BYTE PTR [PFLAG],-1
        JZ      RET18
        CALL    FAR PTR BIOSPRINT 
RET18:  RET

STATCHK:
        CALL    FAR PTR BIOSSTAT 
        JZ      RET18
        CMP     AL,'S'-'@'
        JNZ     NOSTOP
        CALL    FAR PTR BIOSIN          ;Eat Cntrl-S
INCHK:
        CALL    FAR PTR BIOSIN 
        CMP     AL,'P'-'@'
        JZ      PRINTON
        IF      NOT TOGLPRN
        CMP     AL,'N'-'@'
        JZ      PRINTOFF
        ENDIF
        CMP     AL,'C'-'@'
        JNZ     RET18
; Ctrl-C handler.
; "^C" and CR/LF is printed. Then the user registers are restored and the
; user CTRL-C handler is executed. At this point the top of the stack has
; 1) the interrupt return address should the user CTRL-C handler wish to
; allow processing to continue; 2) the original interrupt return address
; to the code that performed the function call in the first place. If the
; user CTRL-C handler wishes to continue, it must leave all registers
; unchanged and IRET. The function that was interrupted will simply be
; repeated.
        MOV     AL,3            ;Display "^C"
        CALL    BUFOUT
        CALL    CRLF
        CLI                     ;Prepare to play with stack
        MOV     SS,CS:[SSSAVE]
        MOV     SP,CS:[SPSAVE]  ;User stack now restored
        POP     AX
        POP     BX
        POP     CX
        POP     DX
        POP     SI
        POP     DI
        POP     BP
        POP     DS
        POP     ES              ;User registers now restored
        INT     CONTC           ;Execute user Ctrl-C handler
        JMP     COMMAND         ;Repeat command otherwise

PRINTON:
        IF      TOGLPRN
        NOT     CS:BYTE PTR [PFLAG]
        RET
        ENDIF
        IF      NOT TOGLPRN
        MOV     CS:BYTE PTR [PFLAG],1
        RET

PRINTOFF:
        MOV     CS:BYTE PTR [PFLAG],0
        RET
        ENDIF

CTRLOUT:
        CMP     AL,13
        JZ      ZERPOS
        CMP     AL,8
        JZ      BACKPOS
        CMP     AL,9
        JNZ     OUTCHJ
        MOV     AL,CS:[CARPOS]
        OR      AL,0F8H
        NEG     AL
TAB:
        PUSH    CX
        MOV     CL,AL
        MOV     CH,0
        JCXZ    POPTAB
TABLP:
        MOV     AL," "
        CALL    OUT
        LOOP    TABLP
POPTAB:
        POP     CX
RET19:  RET

ZERPOS:
        MOV     CS:BYTE PTR [CARPOS],0
OUTCHJ: JMP     OUTCH

BACKPOS:
        DEC     CS:BYTE PTR [CARPOS]
        JMP     OUTCH


CONSTAT: ;System call 11
        CALL    STATCHK
        MOV     AL,0 
        JZ      RET19
        OR      AL,-1
        RET


CONIN:  ;System call 1
        CALL    IN
        PUSH    AX
        CALL    OUT
        POP     AX
        RET


IN:     ;System call 8
        CALL    INCHK
        JZ      IN
RET29:  RET

RAWIO:  ;System call 6
        MOV     AL,DL
        CMP     AL,-1
        JNZ     RAWOUT
        LDS     SI,DWORD PTR CS:[SPSAVE]                ;Get pointer to register save area
        CALL    FAR PTR BIOSSTAT
        JNZ     RESFLG
        OR      BYTE PTR [SI.FSAVE],40H ;Set user's zero flag
        XOR     AL,AL
        RET

RESFLG:
        AND     BYTE PTR [SI.FSAVE],0FFH-40H    ;Reset user's zero flag
RAWINP: ;System call 7
        CALL    FAR PTR BIOSIN 
        RET
RAWOUT:
        CALL    FAR PTR BIOSOUT 
        RET

LIST:   ;System call 5
        MOV     AL,DL
LISTOUT:
        PUSH    AX
        CALL    STATCHK
        POP     AX
        CALL    FAR PTR BIOSPRINT 
RET20:  RET

PRTBUF: ;System call 9
        MOV     SI,DX
OUTSTR:
        LODSB
        CMP     AL,"$"
        JZ      RET20
        CALL    OUT
        JMP     SHORT OUTSTR

OUTMES: ;String output for internal messages
        LODS    CS:BYTE PTR [SI]
        CMP     AL,"$"
        JZ      RET20
        CALL    OUT
        JMP     SHORT OUTMES


MAKEFCB: ;Interrupt call 41
DRVBIT  EQU     2
NAMBIT  EQU     4
EXTBIT  EQU     8
        MOV     DL,0            ;Flag--not ambiguous file name
        TEST    AL,DRVBIT       ;Use current drive field if default?
        JNZ     DEFDRV
        MOV     BYTE PTR ES:[DI],0      ;No - use default drive
DEFDRV:
        INC     DI
        MOV     CX,8
        TEST    AL,NAMBIT       ;Use current name fiels as defualt?
        XCHG    AX,BX           ;Save bits in BX
        MOV     AL," "
        JZ      FILLB           ;If not, go fill with blanks
        ADD     DI,CX
        XOR     CX,CX           ;Don't fill any
FILLB:
        REP     STOSB
        MOV     CL,3
        TEST    BL,EXTBIT       ;Use current extension as default
        JZ      FILLB2
        ADD     DI,CX
        XOR     CX,CX
FILLB2:
        REP     STOSB
        XCHG    AX,CX           ;Put zero in AX
        STOSW
        STOSW                   ;Initialize two words after to zero
        SUB     DI,16           ;Point back at start
        TEST    BL,1            ;Scan off separators if not zero
        JZ      SKPSPC
        CALL    SCANB           ;Peel off blanks and tabs
        CALL    DELIM           ;Is it a one-time-only delimiter?
        JNZ     NOSCAN
        INC     SI              ;Skip over the delimiter
SKPSPC:
        CALL    SCANB           ;Always kill preceding blanks and tabs
NOSCAN:
        CALL    GETLET
        JBE     NODRV           ;Quit if termination character
        CMP     BYTE PTR[SI],":"        ;Check for potential drive specifier
        JNZ     NODRV
        INC     SI              ;Skip over colon
        SUB     AL,"@"          ;Convert drive letter to binary drive number
        JBE     BADDRV          ;Valid drive numbers are 1-15
        CMP     AL,CS:[NUMDRV]
        JBE     HAVDRV
BADDRV:
        MOV     DL,-1
HAVDRV:
        STOSB           ;Put drive specifier in first byte
        INC     SI
        DEC     DI      ;Counteract next two instructions
NODRV:
        DEC     SI      ;Back up
        INC     DI      ;Skip drive byte
        MOV     CX,8
        CALL    GETWORD         ;Get 8-letter file name
        CMP     BYTE PTR [SI],"."
        JNZ     NODOT
        INC     SI              ;Skip over dot if present
        MOV     CX,3            ;Get 3-letter extension
        CALL    MUSTGETWORD
NODOT:
        LDS     BX,CS:DWORD PTR [SPSAVE]
        MOV     [BX.SISAVE],SI
        MOV     AL,DL
        RET

NONAM:
        ADD     DI,CX
        DEC     SI
        RET

GETWORD:
        CALL    GETLET
        JBE     NONAM           ;Exit if invalid character
        DEC     SI
MUSTGETWORD:
        CALL    GETLET
        JBE     FILLNAM
        JCXZ    MUSTGETWORD
        DEC     CX
        CMP     AL,"*"          ;Check for ambiguous file specifier
        JNZ     NOSTAR
        MOV     AL,"?"
        REP     STOSB
NOSTAR:
        STOSB
        CMP     AL,"?"
        JNZ     MUSTGETWORD
        OR      DL,1            ;Flag ambiguous file name
        JMP     MUSTGETWORD
FILLNAM:
        MOV     AL," "
        REP     STOSB
        DEC     SI
RET21:  RET

SCANB:
        LODSB
        CALL    SPCHK
        JZ      SCANB
        DEC     SI
        RET

GETLET:
;Get a byte from [SI], convert it to upper case, and compare for delimiter.
;ZF set if a delimiter, CY set if a control character (other than TAB).
        LODSB
        AND     AL,7FH
        CMP     AL,"a"
        JB      CHK
        CMP     AL,"z"
        JA      CHK
        SUB     AL,20H          ;Convert to upper case
CHK:
        CMP     AL,"."
        JZ      RET21
        CMP     AL,'"'
        JZ      RET21
        CMP     AL,"/"
        JZ      RET21
        CMP     AL,"["
        JZ      RET21
        CMP     AL,"]"
        JZ      RET21

        IF      IBM
DELIM:
        ENDIF
        CMP     AL,":"          ;Allow ":" as separator in IBM version
        JZ      RET21
        IF      NOT IBM
DELIM:
        ENDIF

        CMP     AL,"+"
        JZ      RET101
        CMP     AL,"="
        JZ      RET101
        CMP     AL,";"
        JZ      RET101
        CMP     AL,","
        JZ      RET101
SPCHK:
        CMP     AL,9            ;Filter out tabs too
        JZ      RET101
;WARNING! " " MUST be the last compare
        CMP     AL," "
RET101: RET

SETVECT: ; Interrupt call 37
        XOR     BX,BX
        MOV     ES,BX
        MOV     BL,AL
        SHL     BX,1
        SHL     BX,1
        MOV     ES:[BX],DX
        MOV     ES:[BX+2],DS
        RET


NEWBASE: ; Interrupt call 38
        MOV     ES,DX
        LDS     SI,CS:DWORD PTR [SPSAVE]
        MOV     DS,[SI.CSSAVE]
        XOR     SI,SI
        MOV     DI,SI
        MOV     AX,DS:[2]
        MOV     CX,80H
        REP     MOVSW

SETMEM:

; Inputs:
;       AX = Size of memory in paragraphs
;       DX = Segment
; Function:
;       Completely prepares a program base at the 
;       specified segment.
; Outputs:
;       DS = DX
;       ES = DX
;       [0] has INT 20H
;       [2] = First unavailable segment ([ENDMEM])
;       [5] to [9] form a long call to the entry point
;       [10] to [13] have exit address (from INT 22H)
;       [14] to [17] have ctrl-C exit address (from INT 23H)
;       [18] to [21] have fatal error address (from INT 24H)
; DX,BP unchanged. All other registers destroyed.

        XOR     CX,CX
        MOV     DS,CX
        MOV     ES,DX
        MOV     SI,EXIT
        MOV     DI,SAVEXIT
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        MOV     ES:[2],AX
        SUB     AX,DX
        CMP     AX,MAXDIF
        JBE     HAVDIF
        MOV     AX,MAXDIF
HAVDIF:
        MOV     BX,ENTRYPOINTSEG
        SUB     BX,AX
        SHL     AX,1
        SHL     AX,1
        SHL     AX,1
        SHL     AX,1
        MOV     DS,DX
        MOV     DS:[6],AX
        MOV     DS:[8],BX
        MOV     DS:[0],20CDH    ;"INT INTTAB"
        MOV     DS:(BYTE PTR [5]),LONGCALL
        RET

DATE16:
        PUSH    CX
        CALL    READTIME
        SHL     CL,1            ;Minutes to left part of byte
        SHL     CL,1
        SHL     CX,1            ;Push hours and minutes to left end
        SHL     CX,1
        SHL     CX,1
        SHR     DH,1            ;Count every two seconds
        OR      CL,DH           ;Combine seconds with hours and minutes
        MOV     DX,CX
        POP     CX
        MOV     AX,WORD PTR [MONTH]     ;Fetch month and year
        SHL     AL,1                    ;Push month to left to make room for day
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
        SHL     AX,1
        OR      AL,[DAY]
RET22:  RET

FOURYEARS       EQU     3*365+366

READTIME:
;Gets time in CX:DX. Figures new date if it has changed.
;Uses AX, CX, DX.
        CALL    FAR PTR BIOSGETTIME 
        CMP     AX,[DAYCNT]     ;See if day count is the same
        JZ      RET22
        CMP     AX,FOURYEARS*30 ;Number of days in 120 years
        JAE     RET22           ;Ignore if too large
        MOV     [DAYCNT],AX
        PUSH    SI
        PUSH    CX
        PUSH    DX              ;Save time
        XOR     DX,DX
        MOV     CX,FOURYEARS    ;Number of days in 4 years
        DIV     CX              ;Compute number of 4-year units
        SHL     AX,1
        SHL     AX,1
        SHL     AX,1            ;Multiply by 8 (no. of half-years)
        MOV     CX,AX           ;<240 implies AH=0
        MOV     SI,OFFSET DOSGROUP:YRTAB        ;Table of days in each year
        CALL    DSLIDE          ;Find out which of four years we're in
        SHR     CX,1            ;Convert half-years to whole years
        JNC     SK              ;Extra half-year?
        ADD     DX,200
SK:
        CALL    SETYEAR
        MOV     CL,1            ;At least at first month in year
        MOV     SI,OFFSET DOSGROUP:MONTAB       ;Table of days in each month
        CALL    DSLIDE          ;Find out which month we're in
        MOV     [MONTH],CL
        INC     DX              ;Remainder is day of month (start with one)
        MOV     [DAY],DL
        CALL    WKDAY           ;Set day of week
        POP     DX
        POP     CX
        POP     SI
RET23:  RET

DSLIDE:
        MOV     AH,0
DSLIDE1:
        LODSB           ;Get count of days
        CMP     DX,AX           ;See if it will fit
        JB      RET23           ;If not, done
        SUB     DX,AX
        INC     CX              ;Count one more month/year
        JMP     SHORT DSLIDE1

SETYEAR:
;Set year with value in CX. Adjust length of February for this year.
        MOV     BYTE PTR [YEAR],CL
CHKYR:
        TEST    CL,3            ;Check for leap year
        MOV     AL,28
        JNZ     SAVFEB          ;28 days if no leap year
        INC     AL              ;Add leap day
SAVFEB:
        MOV     [MONTAB+1],AL   ;Store for February
        RET

;Days in year
YRTAB   DB      200,166         ;Leap year
        DB      200,165
        DB      200,165
        DB      200,165

;Days of each month
MONTAB  DB      31              ;January
        DB      28              ;February--reset each time year changes
        DB      31              ;March
        DB      30              ;April
        DB      31              ;May
        DB      30              ;June
        DB      31              ;July
        DB      31              ;August
        DB      30              ;September
        DB      31              ;October
        DB      30              ;November
        DB      31              ;December

GETDATE: ;Function call 42
        PUSH    CS
        POP     DS
        CALL    READTIME        ;Check for rollover to next day
        MOV     AX,[YEAR]
        MOV     BX,WORD PTR [DAY]
        LDS     SI,DWORD PTR [SPSAVE]   ;Get pointer to user registers
        MOV     [SI.DXSAVE],BX  ;DH=month, DL=day
        ADD     AX,1980         ;Put bias back
        MOV     [SI.CXSAVE],AX  ;CX=year
        MOV     AL,CS:[WEEKDAY]
RET24:  RET

SETDATE: ;Function call 43
        MOV     AL,-1           ;Be ready to flag error
        SUB     CX,1980         ;Fix bias in year
        JC      RET24           ;Error if not big enough
        CMP     CX,119          ;Year must be less than 2100
        JA      RET24
        OR      DH,DH
        JZ      RET24
        OR      DL,DL
        JZ      RET24           ;Error if either month or day is 0
        CMP     DH,12           ;Check against max. month
        JA      RET24
        PUSH    CS
        POP     DS
        CALL    CHKYR           ;Set Feb. up for new year
        MOV     AL,DH
        MOV     BX,OFFSET DOSGROUP:MONTAB-1
        XLAT                    ;Look up days in month
        CMP     AL,DL
        MOV     AL,-1           ;Restore error flag, just in case
        JB      RET24           ;Error if too many days
        CALL    SETYEAR
        MOV     WORD PTR [DAY],DX       ;Set both day and month
        SHR     CX,1
        SHR     CX,1
        MOV     AX,FOURYEARS
        MOV     BX,DX
        MUL     CX
        MOV     CL,BYTE PTR [YEAR]
        AND     CL,3
        MOV     SI,OFFSET DOSGROUP:YRTAB
        MOV     DX,AX
        SHL     CX,1            ;Two entries per year, so double count
        CALL    DSUM            ;Add up the days in each year
        MOV     CL,BH           ;Month of year
        MOV     SI,OFFSET DOSGROUP:MONTAB
        DEC     CX              ;Account for months starting with one
        CALL    DSUM            ;Add up days in each month
        MOV     CL,BL           ;Day of month
        DEC     CX              ;Account for days starting with one
        ADD     DX,CX           ;Add in to day total
        XCHG    AX,DX           ;Get day count in AX
        MOV     [DAYCNT],AX
        CALL    FAR PTR BIOSSETDATE 
WKDAY:
        MOV     AX,[DAYCNT]
        XOR     DX,DX
        MOV     CX,7
        INC     AX
        INC     AX              ;First day was Tuesday
        DIV     CX              ;Compute day of week
        MOV     [WEEKDAY],DL
        XOR     AL,AL           ;Flag OK
RET25:  RET

DSUM:
        MOV     AH,0
        JCXZ    RET25
DSUM1:
        LODSB
        ADD     DX,AX
        LOOP    DSUM1
        RET

GETTIME: ;Function call 44
        PUSH    CS
        POP     DS
        CALL    READTIME
        LDS     SI,DWORD PTR [SPSAVE]   ;Get pointer to user registers
        MOV     [SI.DXSAVE],DX
        MOV     [SI.CXSAVE],CX
        XOR     AL,AL
RET26:  RET

SETTIME: ;Function call 45
;Time is in CX:DX in hours, minutes, seconds, 1/100 sec.
        MOV     AL,-1           ;Flag in case of error
        CMP     CH,24           ;Check hours
        JAE     RET26
        CMP     CL,60           ;Check minutes
        JAE     RET26
        CMP     DH,60           ;Check seconds
        JAE     RET26
        CMP     DL,100          ;Check 1/100's
        JAE     RET26
        CALL    FAR PTR BIOSSETTIME 
        XOR     AL,AL
        RET


; Default handler for division overflow trap
DIVOV:
        PUSH    SI
        PUSH    AX
        MOV     SI,OFFSET DOSGROUP:DIVMES
        CALL    OUTMES
        POP     AX
        POP     SI
        INT     23H             ;Use Ctrl-C abort on divide overflow
        IRET

CODSIZ  EQU     $-CODSTRT       ;Size of code segment
CODE    ENDS


;***** DATA AREA *****
CONSTANTS       SEGMENT BYTE
        ORG     0
CONSTRT EQU     $               ;Start of constants segment

IONAME:
        IF      NOT IBM
        DB      "PRN ","LST ","NUL ","AUX ","CON "
        ENDIF
        IF      IBM
        DB      "COM1","PRN ","LPT1","NUL ","AUX ","CON "
        ENDIF
DIVMES  DB      13,10,"Divide overflow",13,10,"$"
CARPOS  DB      0
STARTPOS DB     0
PFLAG   DB      0
DIRTYDIR DB     0               ;Dirty buffer flag
NUMDRV  DB      0       ;Number of drives
NUMIO   DB      ?       ;Number of disk tables
VERFLG  DB      0       ;Initialize with verify off
CONTPOS DW      0
DMAADD  DW      80H             ;User's disk transfer address (disp/seg)
        DW      ?
ENDMEM  DW      ?
MAXSEC  DW      0
BUFFER  DW      ?
BUFSECNO DW     0
BUFDRVNO DB     -1
DIRTYBUF DB     0
BUFDRVBP DW     ?
DIRBUFID DW     -1
DAY     DB      0
MONTH   DB      0
YEAR    DW      0
DAYCNT  DW      -1
WEEKDAY DB      0
CURDRV  DB      0               ;Default to drive A
DRVTAB  DW      0               ;Address of start of DPBs
DOSLEN  EQU     CODSIZ+($-CONSTRT)      ;Size of CODE + CONSTANTS segments
CONSTANTS       ENDS

DATA    SEGMENT WORD
; Init code overlaps with data area below

        ORG     0
INBUF   DB      128 DUP (?)
CONBUF  DB      131 DUP (?)             ;The rest of INBUF and console buffer
LASTENT DW      ?
EXITHOLD DB     4 DUP (?)
FATBASE DW      ?
NAME1   DB      11 DUP (?)              ;File name buffer
ATTRIB  DB      ?
NAME2   DB      11 DUP (?)
NAME3   DB      12 DUP (?)
EXTFCB  DB      ?
;WARNING - the following two items are accessed as a word
CREATING DB     ?
DELALL  DB      ?
TEMP    LABEL   WORD
SPSAVE  DW      ?
SSSAVE  DW      ?
CONTSTK DW      ?
SECCLUSPOS DB   ?       ;Position of first sector within cluster
DSKERR  DB      ?
TRANS   DB      ?
PREREAD DB      ?       ;0 means preread; 1 means optional
READOP  DB      ?
THISDRV DB      ?

        EVEN
FCB     DW      ?       ;Address of user FCB
NEXTADD DW      ?
RECPOS  DB      4 DUP (?)
RECCNT  DW      ?
LASTPOS DW      ?
CLUSNUM DW      ?
SECPOS  DW      ?       ;Position of first sector accessed
VALSEC  DW      ?       ;Number of valid (previously written) sectors
BYTSECPOS DW    ?       ;Position of first byte within sector
BYTPOS  DB      4 DUP (?)               ;Byte position in file of access
BYTCNT1 DW      ?       ;No. of bytes in first sector
BYTCNT2 DW      ?       ;No. of bytes in last sector
SECCNT  DW      ?       ;No. of whole sectors
ENTFREE DW      ?

        DB      80H DUP (?)     ;Stack space
IOSTACK LABEL   BYTE
        DB      80H DUP (?)
DSKSTACK LABEL  BYTE 

        IF      DSKTEST
NSS     DW      ?
NSP     DW      ?
        ENDIF

DIRBUF LABEL    WORD

;Init code below overlaps with data area above

        ORG     0

MOVFAT:
;This section of code is safe from being overwritten by block move
        REP     MOVS    BYTE PTR [DI],[SI]
        CLD
        MOV     ES:[DMAADD+2],DX
        MOV     SI,[DRVTAB]     ;Address of first DPB
        MOV     AL,-1
        MOV     CL,[NUMIO]      ;Number of DPBs
FLGFAT:
        MOV     DI,ES:[SI.FAT]  ;get pointer to FAT
        DEC     DI              ;Point to dirty byte
        STOSB                   ;Flag as unused
        ADD     SI,DPBSIZ       ;Point to next DPB
        LOOP    FLGFAT
        MOV     AX,[ENDMEM]
        CALL    SETMEM          ;Set up segment

XXX     PROC FAR
        RET
XXX     ENDP

DOSINIT:
        CLI
        CLD
        PUSH    CS
        POP     ES
        MOV     ES:[ENDMEM],DX
        LODSB                   ;Get no. of drives & no. of I/O drivers
        MOV     ES:[NUMIO],AL
        MOV     DI,OFFSET DOSGROUP:MEMSTRT
PERDRV:
        MOV     BP,DI
        MOV     AL,ES:[DRVCNT]
        STOSB           ;DEVNUM
        LODSB           ;Physical unit no.
        STOSB           ;DRVNUM
        CMP     AL,15
        JA      BADINIT
        CBW             ;Index into FAT size table
        SHL     AX,1
        ADD     AX,OFFSET DOSGROUP:FATSIZTAB
        XCHG    BX,AX
        LODSW           ;Pointer to DPT
        PUSH    SI
        MOV     SI,AX
        LODSW
        STOSW           ;SECSIZ
        MOV     DX,AX
        CMP     AX,ES:[MAXSEC]
        JBE     NOTMAX
        MOV     ES:[MAXSEC],AX
NOTMAX:
        LODSB
        DEC     AL
        STOSB           ;CLUSMSK
        JZ      HAVSHFT
        CBW
FIGSHFT:
        INC     AH
        SAR     AL,1
        JNZ     FIGSHFT
        MOV     AL,AH
HAVSHFT:
        STOSB           ;CLUSSHFT
        MOVSW           ;FIRFAT (= number of reserved sectors)
        MOVSB           ;FATCNT
        MOVSW           ;MAXENT
        MOV     AX,DX           ;SECSIZ again
        MOV     CL,5
        SHR     AX,CL
        MOV     CX,AX           ;Directory entries per sector
        DEC     AX
        ADD     AX,ES:[BP.MAXENT]
        XOR     DX,DX
        DIV     CX
        STOSW           ;DIRSEC (temporarily)
        MOVSW                   ;DSKSIZ (temporarily)
FNDFATSIZ:
        MOV     AL,1
        MOV     DX,1
GETFATSIZ:
        PUSH    DX
        CALL    FIGFATSIZ
        POP     DX
        CMP     AL,DL           ;Compare newly computed FAT size with trial
        JZ      HAVFATSIZ       ;Has sequence converged?
        CMP     AL,DH           ;Compare with previous trial
        MOV     DH,DL
        MOV     DL,AL           ;Shuffle trials
        JNZ     GETFATSIZ       ;Continue iterations if not oscillating
        DEC     WORD PTR ES:[BP.DSKSIZ] ;Damp those oscillations
        JMP     SHORT FNDFATSIZ ;Try again

BADINIT:
        MOV     SI,OFFSET DOSGROUP:BADMES
        CALL    OUTMES
        STI
        HLT

HAVFATSIZ:
        STOSB                   ;FATSIZ
        MUL     ES:BYTE PTR[BP.FATCNT]  ;Space occupied by all FATs
        ADD     AX,ES:[BP.FIRFAT]
        STOSW                   ;FIRDIR
        ADD     AX,ES:[BP.DIRSEC]
        MOV     ES:[BP.FIRREC],AX       ;Destroys DIRSEC
        CALL    FIGMAX
        MOV     ES:[BP.MAXCLUS],CX
        MOV     AX,BX           ;Pointer into FAT size table
        STOSW                   ;Allocate space for FAT pointer
        MOV     AL,ES:[BP.FATSIZ]
        XOR     AH,AH
        MUL     ES:[BP.SECSIZ]
        CMP     AX,ES:[BX]      ;Bigger than already allocated
        JBE     SMFAT
        MOV     ES:[BX],AX
SMFAT:
        POP     SI              ;Restore pointer to init. table
        MOV     AL,ES:[DRVCNT]
        INC     AL
        MOV     ES:[DRVCNT],AL
        CMP     AL,ES:[NUMIO]
        JAE     CONTINIT
        JMP     PERDRV  

BADINITJ:
        JMP     BADINIT

CONTINIT:
        PUSH    CS
        POP     DS
;Calculate true address of buffers, FATs, free space
        MOV     BP,[MAXSEC]
        MOV     AX,OFFSET DOSGROUP:DIRBUF
        ADD     AX,BP
        MOV     [BUFFER],AX     ;Start of buffer
        ADD     AX,BP
        MOV     [DRVTAB],AX     ;Start of DPBs
        SHL     BP,1            ;Two sectors - directory and buffer
        ADD     BP,DI           ;Allocate buffer space
        ADD     BP,ADJFAC       ;True address of FATs
        PUSH    BP
        MOV     SI,OFFSET DOSGROUP:FATSIZTAB
        MOV     DI,SI
        MOV     CX,16
TOTFATSIZ:
        INC     BP              ;Add one for Dirty byte
        INC     BP              ;Add one for I/O device number
        LODSW                   ;Get size of this FAT
        XCHG    AX,BP
        STOSW                   ;Save address of this FAT
        ADD     BP,AX           ;Compute size of next FAT
        CMP     AX,BP           ;If size was zero done
        LOOPNZ  TOTFATSIZ
        MOV     AL,15
        SUB     AL,CL           ;Compute number of FATs used
        MOV     [NUMDRV],AL
        XOR     AX,AX           ;Set zero flag
        REPZ    SCASW           ;Make sure all other entries are zero
        JNZ     BADINITJ
        ADD     BP,15           ;True start of free space
        MOV     CL,4
        SHR     BP,CL           ;First free segment
        MOV     DX,CS
        ADD     DX,BP
        MOV     BX,0FH
        MOV     CX,[ENDMEM]
        CMP     CX,1            ;Use memory scan?
        JNZ     SETEND
        MOV     CX,DX           ;Start scanning just after DOS
MEMSCAN:
        INC     CX
        JZ      SETEND
        MOV     DS,CX
        MOV     AL,[BX]
        NOT     AL
        MOV     [BX],AL
        CMP     AL,[BX]
        NOT     AL
        MOV     [BX],AL
        JZ      MEMSCAN
SETEND:
        IF      HIGHMEM
        SUB     CX,BP
        MOV     BP,CX           ;Segment of DOS
        MOV     DX,CS           ;Program segment
        ENDIF
        IF      NOT HIGHMEM
        MOV     BP,CS
        ENDIF
; BP has segment of DOS (whether to load high or run in place)
; DX has program segment (whether after DOS or overlaying DOS)
; CX has size of memory in paragraphs (reduced by DOS size if HIGHMEM)
        MOV     CS:[ENDMEM],CX
        IF      HIGHMEM
        MOV     ES,BP
        XOR     SI,SI
        MOV     DI,SI
        MOV     CX,(DOSLEN+1)/2
        PUSH    CS
        POP     DS
        REP MOVSW               ;Move DOS to high memory
        ENDIF
        XOR     AX,AX
        MOV     DS,AX
        MOV     ES,AX
        MOV     DI,INTBASE
        MOV     AX,OFFSET DOSGROUP:QUIT
        STOSW                   ;Set abort address--displacement
        MOV     AX,BP
        MOV     BYTE PTR DS:[ENTRYPOINT],LONGJUMP
        MOV     WORD PTR DS:[ENTRYPOINT+1],OFFSET DOSGROUP:ENTRY
        MOV     WORD PTR DS:[ENTRYPOINT+3],AX
        MOV     WORD PTR DS:[0],OFFSET DOSGROUP:DIVOV   ;Set default divide trap address
        MOV     DS:[2],AX
        MOV     CX,9
        REP STOSW               ;Set 5 segments (skip 2 between each)
        MOV     WORD PTR DS:[INTBASE+4],OFFSET DOSGROUP:COMMAND
        MOV     WORD PTR DS:[INTBASE+12],OFFSET DOSGROUP:IRET   ;Ctrl-C exit
        MOV     WORD PTR DS:[INTBASE+16],OFFSET DOSGROUP:IRET   ;Fatal error exit
        MOV     AX,OFFSET BIOSREAD
        STOSW
        MOV     AX,BIOSSEG
        STOSW
        STOSW                   ;Add 2 to DI
        STOSW
        MOV     WORD PTR DS:[INTBASE+18H],OFFSET BIOSWRITE
        MOV     WORD PTR DS:[EXIT],100H
        MOV     WORD PTR DS:[EXIT+2],DX
        IF      NOT IBM
        MOV     SI,OFFSET DOSGROUP:HEADER
        CALL    OUTMES
        ENDIF
        PUSH    CS
        POP     DS
        PUSH    CS
        POP     ES
;Move the FATs into position
        MOV     AL,[NUMIO]
        CBW
        XCHG    AX,CX
        MOV     DI,OFFSET DOSGROUP:MEMSTRT.FAT
FATPOINT:
        MOV     SI,WORD PTR [DI]        ;Get address within FAT address table
        MOVSW                           ;Set address of this FAT
        ADD     DI,DPBSIZ-2             ;Point to next DPB
        LOOP    FATPOINT
        POP     CX                      ;True address of first FAT
        MOV     SI,OFFSET DOSGROUP:MEMSTRT      ;Place to move DPBs from
        MOV     DI,[DRVTAB]             ;Place to move DPBs to
        SUB     CX,DI                   ;Total length of DPBs
        CMP     DI,SI
        JBE     MOVJMP                  ;Are we moving to higher or lower memory?
        DEC     CX                      ;Move backwards to higher memory
        ADD     DI,CX
        ADD     SI,CX
        INC     CX
        STD
MOVJMP:
        MOV     ES,BP
        JMP     MOVFAT

FIGFATSIZ:
        MUL     ES:BYTE PTR[BP.FATCNT]
        ADD     AX,ES:[BP.FIRFAT]
        ADD     AX,ES:[BP.DIRSEC]
FIGMAX:
;AX has equivalent of FIRREC
        SUB     AX,ES:[BP.DSKSIZ]
        NEG     AX
        MOV     CL,ES:[BP.CLUSSHFT]
        SHR     AX,CL
        INC     AX
        MOV     CX,AX           ;MAXCLUS
        INC     AX
        MOV     DX,AX
        SHR     DX,1
        ADC     AX,DX           ;Size of FAT in bytes
        MOV     SI,ES:[BP.SECSIZ]
        ADD     AX,SI
        DEC     AX
        XOR     DX,DX
        DIV     SI
        RET

BADMES:
        DB      13,10,"INIT TABLE BAD",13,10,"$"

FATSIZTAB:
        DW      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

DRVCNT  DB      0

MEMSTRT LABEL   WORD
ADJFAC  EQU     DIRBUF-MEMSTRT
DATA    ENDS
        END
