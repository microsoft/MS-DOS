        TITLE   PROFIL - MS-DOS Profile program

;Profiler for MS-DOS 1.25 2.00
;
; Lots of stuff stolen from debug.
; User provides # of paragraphs per bucket, program is cut up accordingly.
; User also specifies clock interval


;System calls
PRINTBUF        EQU     9
SETDMA          EQU     26
CREATE          EQU     22
OPEN            EQU     15
CLOSE           EQU     16
GETBUF          EQU     10
BLKWRT          EQU     40
BLKRD           EQU     39
OUTCH           EQU     2
SETBASE         EQU     38

FCB             EQU     5CH
BUFLEN          EQU     80

; FCB offsets
RR              EQU     33
RECLEN          EQU     14
FILELEN         EQU     16


;Segments in load order

CODE    SEGMENT PUBLIC
CODE    ENDS

DATA    SEGMENT BYTE
DATA    ENDS

INIT    SEGMENT BYTE
INIT    ENDS

DG      GROUP   CODE,DATA,INIT

;The data segment

DATA    SEGMENT BYTE
        ORG     0
ENDMES          DB      13,10,"Program terminated normally",13,10,"$"
ABORTMES        DB      13,10,"Program aborted",13,10,"$"
TOOBIG          DB      "Program too big",13,10,"$"
EXEBAD          DB      "EXE file bad",13,10,"$"

OUT_FCB         LABEL   WORD
                DB      0
OUTNAME         DB      "        PRF"
                DB      30 DUP(0)

                DB      80H DUP(?)
STACK           LABEL   WORD

BYTEBUF         DB      BUFLEN DUP(?)           ;Processed input queue
AXSAVE          DW      ?                       ;See interrupt routine
BXSAVE          DW      ?                       ; "     "        "
PROG_AREA       DW      ?                       ;Segment of program start

;EXE file header
RUNVAR          LABEL   WORD
RELPT           DW      ?
LASTP           LABEL   WORD
RELSEG          DW      ?
PSIZE           LABEL   WORD
PAGES           DW      ?
RELCNT          DW      ?
HEADSIZ         DW      ?
                DW      ?
LOADLOW         DW      ?
PROG_SS         LABEL   WORD                    ;Program stack seg
INITSS          DW      ?
PROG_SP         LABEL   WORD                    ;Program SP
INITSP          DW      ?
                DW      ?
PROG_ENTRY      EQU     THIS DWORD
PROG_RA         LABEL   WORD                    ;Program start offset
INITIP          DW      ?
PROG_SA         LABEL   WORD                    ;Program start segment (may be different from PROG_AREA)
INITCS          DW      ?
RELTAB          DW      ?
RUNVARSIZ       EQU     $-RUNVAR

EXEFILE         DB      0                       ;Flag to indicate EXE file
DRV_VALID       DW      ?                       ;Init for AX register
OUTPUT_DATA     LABEL   WORD                    ;Start of the profile data
CLOCK_GRAIN     DW      ?                       ;Clock interval micro-seconds
BUCKET_NUM      DW      ?                       ;Number of buckets
BUCKET_SIZE     DW      ?                       ;Paragraphs per bucket
PROG_LOW_PA     DW      ?                       ;Start of program (PARA #)
PROG_HIGH_PA    DW      ?                       ;End of program (PARA #)
DOS_PA          DW      ?                       ;IO-DOS PARA boundry
HIT_IO          DW      0                       ;IO bucket
HIT_DOS         DW      0                       ;DOS bucket
HIT_HIGH        DW      0                       ;Above Program bucket
NUM_DATA_WORDS  EQU     ($-OUTPUT_DATA)/2       ;Number of word items
BUCKET          LABEL   WORD                    ;Bucket count area

;The following data will be overwritten when the buckets are initialized
LINEBUF         DB      BUFLEN,1,0DH            ;Raw input buffer
                DB      BUFLEN DUP(?)

NOFILE          DB      "File not found",13,10,"$"
OUTERR          DB      "Cannot open output file",13,10,"$"
GRAIN_PROMPT    DB      "Sample time (micro-sec) >= 60 ? ","$"
SIZE_PROMPT     DB      "Number of paragraphs (16 bytes) per bucket? ","$"
PARAM_PROMPT    DB      "Parameters to program? ","$"
DATA    ENDS

;The resident code portion
CODE    SEGMENT PUBLIC
ASSUME  CS:DG,DS:DG,ES:DG,SS:DG

;The clock interrupt routine
        PUBLIC  CLK_INTER

;Stuff provided by external clock handler routine
        EXTRN   CLOCKON:NEAR,CLOCKOFF:NEAR,LEAVE_INT:NEAR

        ORG     100H
START:
        CLD
        MOV     SP,OFFSET DG:STACK      ;Use internal stack
        CALL    SETUP
;The following setup stuff cannot be done in SETUP because we're probably
; overwritting the INIT area
        MOV     DX,[PROG_AREA]
        MOV     AH,SETBASE
        INT     21H                     ;Set base for program
        MOV     ES,[PROG_AREA]
        PUSH    SI                      ;Points to BYTEBUF
        MOV     DI,81H                  ;Set unformatted params
COMTAIL:
        LODSB
        STOSB
        CMP     AL,13
        JNZ     COMTAIL
        SUB     DI,82H                  ;Figure length
        XCHG    AX,DI
        MOV     BYTE PTR ES:[80H],AL
        POP     SI
        MOV     DI,FCB                  ;First param
        MOV     AX,2901H
        INT     21H
        MOV     BYTE PTR [DRV_VALID],AL
        MOV     AX,2901H                
        MOV     DI,6CH                  ;Second param
        INT     21H
        MOV     BYTE PTR [DRV_VALID+1],AL

        MOV     AX,ES                   ;Prog segment to AX
        MOV     DX,[PROG_RA]            ;Offset
        CMP     [EXEFILE],1
        JZ      EXELOAD                 ;EXE file
        JMP     BINFIL                  ;Regular file (.COM)

EXELOAD:
        MOV     AX,[HEADSIZ]            ;Size of header in paragraphs
        ADD     AX,31
        MOV     CL,4
        ROL     AX,CL                   ;Size in bytes
        MOV     BX,AX
        AND     AX,0FE00H
        AND     BX,0FH
        MOV     WORD PTR DS:[FCB+RR],AX         ;Position in file of program
        MOV     WORD PTR DS:[FCB+RR+2],BX       ;Record size
        MOV     DX,[PAGES]                      ;Size in 512 byte blocks
        DEC     DX
        XCHG    DH,DL
        ROL     DX,1
        MOV     DI,DX
        MOV     SI,DX
        AND     DI,0FE00H
        AND     SI,1FFH
        SUB     DI,AX
        SBB     SI,BX
        MOV     AX,[LASTP]
        OR      AX,AX
        JNZ     PARTP
        MOV     AX,200H
PARTP:
        ADD     DI,AX
        ADC     SI,0
        MOV     AX,DI
        ADD     AX,15
        AND     AL,0F0H
        OR      AX,SI
        MOV     CL,4
        ROR     AX,CL
        XCHG    AX,CX
        MOV     BX,[PROG_AREA]
        ADD     BX,10H
        MOV     AX,WORD PTR DS:[2]
        SUB     AX,CX
        MOV     DX,OFFSET DG:TOOBIG
        JB      ERROR
        CMP     BX,AX
        JA      ERROR
        CMP     [LOADLOW],-1
        JNZ     LOADEXE
        XCHG    AX,BX
LOADEXE:
        MOV     BP,AX
        XOR     DX,DX
        CALL    READ
        JC      HAVEXE
BADEXE:
        MOV     DX,OFFSET DG:EXEBAD

ERROR:
        MOV     AH,PRINTBUF             ;Print the message in DX
        INT     21H
        INT     20H                     ;Exit

HAVEXE:
        MOV     AX,[RELTAB]             ;Get position of relocation table
        MOV     WORD PTR DS:[FCB+RR],AX
        MOV     WORD PTR DS:[FCB+RR+2],0
        MOV     DX,OFFSET DG:RELPT      ;Four byte buffer
        MOV     AH,SETDMA
        INT     21H
        CMP     [RELCNT],0
        JZ      NOREL
RELOC:
        MOV     AH,BLKRD
        MOV     DX,FCB
        MOV     CX,4
        INT     21H             ;Read in one relocation pointer
        OR      AL,AL
        JNZ     BADEXE
        MOV     DI,[RELPT]      ;Pointer offset
        MOV     AX,[RELSEG]     ;pointer segment
        ADD     AX,BP           ;Bias with actual load segment
        MOV     ES,AX
        ADD     ES:[DI],BP      ;Relocate
        DEC     [RELCNT]
        JNZ     RELOC

NOREL:
        ADD     [INITSS],BP
        ADD     [INITCS],BP
        JMP     SHORT PROGGO

BINFIL:
        MOV     WORD PTR DS:[FCB+RECLEN],1
        MOV     SI,-1
        MOV     DI,SI
        CALL    READ
        MOV     ES,[PROG_SA]            ;Prog segment to ES
        MOV     AX,WORD PTR ES:[6]
        MOV     [PROG_SP],AX            ;Default SP for non EXE files
        DEC     AH
        MOV     WORD PTR ES:[6],AX      ;Fix size
        
PROGGO:
        PUSH    DS
        MOV     AX,[PROG_AREA]
        MOV     DS,AX
        MOV     DX,80H
        MOV     AH,SETDMA
        INT     21H                     ;Set default disk transfer address
        POP     DS
        MOV     BX,[BUCKET_NUM]
        SHL     BX,1                    ;Mult by 2 to get #bytes in bucket area
CLEAR:
        MOV     BUCKET[BX],0            ;Zero counts
        SUB     BX,2
        JGE     CLEAR
        MOV     DX,[CLOCK_GRAIN]
        PUSH    DS
        POP     ES
        CLI                             ;Don't collect data yet
        CALL    CLOCKON                 ;Set the interrupt
        MOV     SI,[PROG_RA]
        MOV     DI,[PROG_AREA]
        MOV     BX,[PROG_SS]
        MOV     CX,[PROG_SP]
        MOV     AX,[DRV_VALID]
        MOV     DX,[PROG_SA]
        MOV     SS,BX
        MOV     SP,CX
        XOR     CX,CX
        PUSH    CX                      ;0 on prog stack
        PUSH    DX
        PUSH    SI
        MOV     DS,DI                   ;Set up segments
        MOV     ES,DI
        STI                             ;Start collecting data
XXX     PROC    FAR
        RET                             ;Hop to program
XXX     ENDP
        
READ:
; AX:DX is disk transfer address (segment:offset)
; SI:DI is 32 bit length

RDLOOP:
        MOV     BX,DX
        AND     DX,000FH
        MOV     CL,4
        SHR     BX,CL
        ADD     AX,BX
        PUSH    AX
        PUSH    DX
        PUSH    DS
        MOV     DS,AX
        MOV     AH,SETDMA
        INT     21H
        POP     DS
        MOV     DX,FCB
        MOV     CX,0FFF0H               ;Keep request in segment
        OR      SI,SI                   ;Need > 64K?
        JNZ     BIGRD
        MOV     CX,DI                   ;Limit to amount requested
BIGRD:
        MOV     AH,BLKRD
        INT     21H
        SUB     DI,CX                   ;Subtract off amount done
        SBB     SI,0                    ;Ripple carry
        CMP     AL,1                    ;EOF?
        POP     DX
        POP     AX                      ;Restore transfer address
        JZ      RET10
        ADD     DX,CX                   ;Bump transfer address by last read
        MOV     BX,SI
        OR      BX,DI                   ;Finished with request
        JNZ     RDLOOP
RET10:  STC
        RET


;Return here on termination or abort

TERMINATE:
        CLI                             ;Stop collecting data
        MOV     DX,OFFSET DG:ENDMES
        JMP     SHORT WRITEOUT
ABORT:
        CLI                             ;Stop collecting data
        MOV     DX,OFFSET DG:ABORTMES
WRITEOUT:
        MOV     AX,CS
        MOV     DS,AX
        MOV     SS,AX
        MOV     SP,OFFSET DG:STACK      ;Use internal stack
        PUSH    DX
        CALL    CLOCKOFF                ;Restore original clock routine
        STI                             ;Back to normal clock
        POP     DX
        MOV     AH,PRINTBUF
        INT     21H                     ;Apropriate termination message
        MOV     [OUT_FCB+14],2          ;Word size records
        MOV     DX,OFFSET DG:OUTPUT_DATA
        MOV     AH,SETDMA
        INT     21H                     ;Set the transfer address
        MOV     CX,NUM_DATA_WORDS
        ADD     CX,[BUCKET_NUM]
        MOV     DX,OFFSET DG:OUT_FCB
        MOV     AH,BLKWRT
        INT     21H                     ;Write out data
        MOV     DX,OFFSET DG:OUT_FCB
        MOV     AH,CLOSE
        INT     21H
        INT     20H                     ;Exit


;The clock interrupt routine
CLK_INTER       PROC    NEAR
        CLI
        PUSH    DS
        PUSH    CS
        POP     DS                      ;Get profile segment
        MOV     [AXSAVE],AX
        MOV     [BXSAVE],BX
        POP     AX                      ;old DS
        MOV     BX,OFFSET DG:LEAVE_INT
        PUSH    BX
        PUSH    AX
        PUSH    ES
        PUSH    [AXSAVE]
        PUSH    [BXSAVE]
        PUSH    CX
        PUSH    DX


;Stack looks like this
;
; +18   OLDFLAGS
; +16   OLDCS
; +14   OLDIP
; +12   RETURN TO LEAVE_INT
; +10   OLDDS
; +8    OLDES
; +6    OLDAX
; +4    OLDBX
; +2    OLDCX
;SP->   OLDDX

        MOV     BX,SP
        LES     BX,DWORD PTR SS:[BX+14]         ;Get CS:IP
        MOV     AX,BX
        MOV     CL,4
        SHR     AX,CL
        MOV     CX,ES
        ADD     AX,CX                   ;Paragraph of CS:IP
        CMP     AX,[DOS_PA]             ;Below DOS?
        JB      IOHIT
        CMP     AX,[PROG_LOW_PA]        ;Below program?
        JB      DOSHIT
        CMP     AX,[PROG_HIGH_PA]       ;Above program?
        JAE     MISSH

        SUB     AX,[PROG_LOW_PA]        ;Paragraph offset
        XOR     DX,DX
        
        DIV     [BUCKET_SIZE]
        MOV     BX,AX
        SHL     BX,1                    ;Mult by 2 to get byte offset
        INC     BUCKET[BX]
        JMP     SHORT DONE

IOHIT:
        INC     [HIT_IO]
        JMP     SHORT DONE

DOSHIT:
        INC     [HIT_DOS]
        JMP     SHORT DONE

MISSH:
        INC     [HIT_HIGH]

DONE:
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        POP     ES
        POP     DS
        STI
        RET             ;To LEAVE_INT

CLK_INTER       ENDP

CODE    ENDS

;The init segment contains code to process input parameters
; It will be blasted as soon as the program to be run is read in
; And/or the bucket area is initialized
 
INIT    SEGMENT BYTE
        ORG     0

SETUP:
        MOV     DX,FCB
        MOV     AH,OPEN
        INT     21H                     ;Open program file
        AND     AL,AL
        JZ      OPENOK
        MOV     DX,OFFSET DG:NOFILE
        JMP     ERROR

OPENOK:
        XOR     BX,BX
        MOV     WORD PTR DS:[FCB+RR],BX
        MOV     WORD PTR DS:[FCB+RR+2],BX       ;RR to 0
        MOV     SI,FCB
        MOV     DI,OFFSET DG:OUT_FCB
        MOV     CX,4
        REP     MOVSW
        MOVSB                           ;Transfer drive spec and file to output
        MOV     DX,OFFSET DG:OUT_FCB
        MOV     AH,CREATE
        INT     21H                     ;Try to create the output file
        AND     AL,AL
        JZ      GETSIZE
        MOV     DX,OFFSET DG:OUTERR
        JMP     ERROR

GETSIZE:                                ;Get bucket size
        MOV     DX,OFFSET DG:SIZE_PROMPT
        MOV     AH,PRINTBUF
        INT     21H
        CALL    INBUF
        CALL    SCANB
        JZ      GETSIZE         ;SCANB went to CR
        XOR     BX,BX
        INC     BX              ;Size >=1
        CALL    GETNUM
        JC      GETSIZE         ;Bad number
        MOV     [BUCKET_SIZE],DX

        CMP     WORD PTR DS:[FCB+9],5800H+"E"           ;"EX"
        JNZ     NOTEXE
        CMP     BYTE PTR DS:[FCB+11],"E"
        JNZ     NOTEXE

LOADEXEHEAD:                            ;Load the EXE header
        MOV     [EXEFILE],1
        MOV     DX,OFFSET DG:RUNVAR     ;Read header in here
        MOV     AH,SETDMA
        INT     21H
        MOV     CX,RUNVARSIZ
        MOV     DX,FCB
        MOV     WORD PTR DS:[FCB+RECLEN],1
        OR      AL,AL
        MOV     AH,BLKRD
        INT     21H
        CMP     [RELPT],5A4DH           ;Magic number
        JZ      EXEOK
        JMP     BADEXE
EXEOK:
        MOV     AX,[PAGES]              ;Size of file in 512 byte blocks
        MOV     CL,5
        SHL     AX,CL                   ;Size in paragraphs     
        JMP     SHORT SETBUCKET

NOTEXE:
        MOV     AX,WORD PTR DS:[FCB+FILELEN]
        MOV     DX,WORD PTR DS:[FCB+FILELEN+2]  ;Size of file in bytes DX:AX
        ADD     AX,15
        ADC     DX,0                            ;Round to PARA
        MOV     CL,4
        SHR     AX,CL
        AND     AX,0FFFH
        MOV     CL,12
        SHL     DX,CL
        AND     DX,0F000H
        OR      AX,DX                           ;Size in paragraphs to AX
        MOV     [PROG_RA],100H                  ;Default offset

SETBUCKET:
        PUSH    AX                      ;Save size
        XOR     DX,DX
        DIV     [BUCKET_SIZE]
        INC     AX                      ;Round up
        MOV     [BUCKET_NUM],AX
        MOV     BX,OFFSET DG:BUCKET
        SHL     AX,1                    ;Number of bytes in bucket area
        ADD     AX,BX                   ;Size of profil in bytes
        ADD     AX,15                   ;Round up to PARA boundry
        MOV     CL,4
        SHR     AX,CL                   ;Number of paragraphs in profil
        INC     AX                      ;Insurance
        MOV     BX,CS
        ADD     AX,BX
        MOV     [PROG_AREA],AX

        CMP     [EXEFILE],1
        JZ      SETBOUNDS
        MOV     AX,[PROG_AREA]          ;Set up .COM segments
        MOV     [PROG_SS],AX
        MOV     [PROG_SA],AX

SETBOUNDS:                              ;Set the sample window
        MOV     BX,10H                  ;Get start offset
        ADD     BX,[PROG_AREA]          ;PARA # of start
        MOV     [PROG_LOW_PA],BX
        POP     AX                      ;Recall size of PROG in paragraphs
        ADD     BX,AX
        MOV     [PROG_HIGH_PA],BX

SETDOS:
        XOR     DX,DX
        MOV     ES,DX                   ;look in interrupt area
        MOV     DX,WORD PTR ES:[82H]    ;From int #20
        MOV     [DOS_PA],DX
        PUSH    DS
        POP     ES

GETGRAIN:                               ;Get sample interval
        MOV     DX,OFFSET DG:GRAIN_PROMPT
        MOV     AH,PRINTBUF
        INT     21H
        CALL    INBUF
        CALL    SCANB
        JZ      GETGRAIN                ;SCANB went to CR
        MOV     BX,60                   ;Grain >=60
        CALL    GETNUM
        JC      GETGRAIN                ;Bad number
        MOV     [CLOCK_GRAIN],DX

        MOV     DX,OFFSET DG:PARAM_PROMPT
        MOV     AH,PRINTBUF
        INT     21H
        CALL    INBUF                   ;Get program parameters

        MOV     AX,2522H                ;Set vector 22H
        MOV     DX,OFFSET DG:TERMINATE
        INT     21H
        MOV     AL,23H                  ;Set vector 23H
        MOV     DX,OFFSET DG:ABORT
        INT     21H
        RET                             ;Back to resident code

GETNUM:                         ;Get a number, DS:SI points to buffer, carry set if bad
        XOR     DX,DX
        MOV     CL,0
        LODSB
NUMLP:
        SUB     AL,"0"
        JB      NUMCHK
        CMP     AL,9
        JA      NUMCHK
        CMP     DX,6553
        JAE     BADNUM
        MOV     CL,1
        PUSH    BX
        MOV     BX,DX
        SHL     DX,1
        SHL     DX,1
        ADD     DX,BX
        SHL     DX,1
        CBW
        POP     BX
        ADD     DX,AX
        LODSB
        JMP     NUMLP
NUMCHK:
        CMP     CL,0
        JZ      BADNUM
        CMP     BX,DX
        JA      BADNUM
        CLC
        RET
BADNUM:
        STC
        RET     

INBUF:                                  ;Read in from console, SI points to start on exit
        MOV     AH,GETBUF
        MOV     DX,OFFSET DG:LINEBUF
        INT     21H
        MOV     SI,2 + OFFSET DG:LINEBUF
        MOV     DI,OFFSET DG:BYTEBUF
CASECHK:
        LODSB
        CMP     AL,'a'
        JB      NOCONV
        CMP     AL,'z'
        JA      NOCONV
        ADD     AL,"A"-"a"              ;Convert to upper case
NOCONV:
        STOSB
        CMP     AL,13
        JZ      INDONE
        CMP     AL,'"'
        JNZ     QUOTSCAN
        CMP     AL,"'"
        JNZ     CASECHK
QUOTSCAN:
        MOV     AH,AL
KILLSTR:
        LODSB
        STOSB
        CMP     AL,13
        JZ      INDONE
        CMP     AL,AH
        JNZ     KILLSTR
        JMP     SHORT CASECHK

INDONE:
        MOV     SI,OFFSET DG:BYTEBUF

;Output CR/LF

CRLF:
        MOV     AL,13
        CALL    OUT
        MOV     AL,10

OUT:
        PUSH    AX
        PUSH    DX
        AND     AL,7FH
        XCHG    AX,DX
        MOV     AH,OUTCH
        INT     21H
        POP     DX
        POP     AX
        RET

SCANB:                          ;Scan to first non-blank
        PUSH    AX
SCANNEXT:
        LODSB
        CMP     AL," "
        JZ      SCANNEXT
        CMP     AL,9
        JZ      SCANNEXT
        DEC     SI
        POP     AX
EOLCHK:
        CMP     BYTE PTR[SI],13
        RET

INIT    ENDS
        END     START
                                                                                                                        