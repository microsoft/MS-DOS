; TITLE MSINIT.ASM -- MS-DOS INITIALIZATION CODE

        ORG     0                       ; reset to beginning of data segment
; Init code below overlaps with data area

INITBLOCK DB    110H DUP(0)     ; Allow for segment round up

INITSP  DW      ?
INITSS  DW      ?
BUFFSTRT DW     ?

ASSUME  CS:DOSGROUP,DS:DOSGROUP,ES:DOSGROUP,SS:NOTHING

        EXTRN   QUIT:NEAR,IRET:NEAR,ABSDRD:FAR,ABSDWRT:FAR
        EXTRN   COMMAND:NEAR,CALL_ENTRY:NEAR
        IF      NOT IBM
        EXTRN   HEADER:BYTE
        ENDIF

MOVDPB:
; This section of code is safe from being overwritten by block move
        MOV     SP,CS:[INITSP]
        MOV     SS,CS:[INITSS]
        REP     MOVS    BYTE PTR [DI],[SI]
        CLD
        MOV     WORD PTR ES:[DMAADD+2],DX
        MOV     SI,WORD PTR [DPBHEAD]   ; Address of first DPB
        MOV     WORD PTR ES:[DPBHEAD+2],ES
        MOV     WORD PTR ES:[sft_addr+2],ES
        MOV     CL,[NUMIO]      ; Number of DPBs
        XOR     CH,CH
SETFINDPB:
        MOV     WORD PTR ES:[SI.dpb_next_dpb+2],ES
        MOV     ES:[SI.dpb_first_access],-1      ; Never accessed before
        ADD     SI,DPBSIZ       ; Point to next DPB
        LOOP    SETFINDPB
        SUB     SI,DPBSIZ
        MOV     WORD PTR ES:[SI.dpb_next_dpb+2],-1
        MOV     DI,[BUFFSTRT]                   ; Set up one default buffer
        MOV     WORD PTR ES:[BUFFHEAD+2],ES
        MOV     WORD PTR ES:[BUFFHEAD],DI
        MOV     WORD PTR ES:[DI.BUFDRV],00FFH
        MOV     ES:[DI.BUFPRI],FREEPRI
        MOV     WORD PTR ES:[DI.NEXTBUF],-1
        MOV     WORD PTR ES:[DI.NEXTBUF+2],-1
        PUSH    ES
        INC     DX                          ; Leave enough room for the ARENA
        MOV     BYTE PTR [CreatePDB],0FFh   ; create jfns and set CurrentPDB
        invoke  $CREATE_PROCESS_DATA_BLOCK     ; Set up segment
ASSUME  DS:NOTHING,ES:NOTHING
        POP     ES
ASSUME  ES:DOSGROUP

;
; set up memory arena
;SPECIAL NOTE FOR HIGHMEM VERSION
; At this point a process header has been built where the start of the 
; CONSTANTS segment as refed by CS is. From this point until the return 
; below be careful about references off of CS.
;
        PUSH    AX
        MOV     AX,[CurrentPDB]
        MOV     ES:[CurrentPDB],AX         ; Put it in the REAL location
        MOV     BYTE PTR ES:[CreatePDB],0h ; reset flag in REAL location
        DEC     AX
        MOV     ES:[arena_head],AX
        PUSH    DS
        MOV     DS,AX
        MOV     DS:[arena_signature],arena_signature_end
        MOV     DS:[arena_owner],arena_owner_system
        SUB     AX,ES:[ENDMEM]
        NEG     AX
        DEC     AX
        MOV     DS:[arena_size],AX
        POP     DS
        POP     AX

        MOV     DI,OFFSET DOSGROUP:sftabl + sft_table   ; Point to sft 0
        MOV     AL,3
        STOSB           ; Adjust Refcount
        MOV     DI,OFFSET DOSGROUP:SYSINITVAR

XXX     PROC FAR
        RET
XXX     ENDP
DATA    ENDS

; the next segment defines a new class that MUST appear last in the link map.
; This defines several important locations for the initialization process that
; must be the first available locations of free memory.

LAST    SEGMENT BYTE PUBLIC 'LAST'
        PUBLIC  SYSBUF
        PUBLIC  MEMSTRT

SYSBUF  LABEL   WORD
ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

DOSINIT:
        CLI
        CLD
        MOV     [ENDMEM],DX
        MOV     [INITSP],SP
        MOV     [INITSS],SS
        MOV     SP,OFFSET DOSGROUP:INITSTACK
        MOV     AX,CS
        MOV     SS,AX
ASSUME  SS:DOSGROUP
        MOV     WORD PTR [DEVHEAD+2],DS
        MOV     WORD PTR [DEVHEAD],SI   ; DS:SI Points to CONSOLE Device
        CALL    CHARINIT
        PUSH    SI
        ADD     SI,SDEVNAME             ; Point to name
        PUSH    CS
        POP     ES
ASSUME  ES:DOSGROUP
        MOV     DI,OFFSET DOSGROUP:sftabl + sft_table   ; Point to sft 0
        MOV     AL,3
        STOSB           ; Refcount
        DEC     AL
        STOSB           ; Access rd/wr
        XOR     AL,AL
        STOSB           ; Drive byte
        STOSB           ; attribute
        MOV     CX,4
        REP     MOVSW   ; Name
        MOV     CL,3
        MOV     AL," "
        REP     STOSB   ; Extension
        ADD     DI,12   ; Skip
        MOV     AL,0C0H OR ISCIN OR ISCOUT
        STOSB
        POP     SI
        MOV     AX,SI
        STOSW                   ; Device pointer in FIRCLUS
        MOV     AX,DS
        STOSW
        OR      BYTE PTR [SI.SDEVATT],ISCIN OR ISCOUT
        MOV     WORD PTR [BCON],SI
        MOV     WORD PTR [BCON+2],DS
CHAR_INIT_LOOP:
        LDS     SI,DWORD PTR [SI]               ; AUX device
        CALL    CHARINIT
        TEST    BYTE PTR [SI.SDEVATT],ISCLOCK
        JZ      CHAR_INIT_LOOP
        MOV     WORD PTR [BCLOCK],SI
        MOV     WORD PTR [BCLOCK+2],DS
        MOV     BP,OFFSET DOSGROUP:MEMSTRT      ; ES:BP points to DPB
PERDRV:
        LDS     SI,DWORD PTR [SI]               ; Next device
        CMP     SI,-1
        JZ      CONTINIT
        CALL    CHARINIT
        TEST    [SI.SDEVATT],DEVTYP
        JNZ     PERDRV                          ; Skip any other character devs
        MOV     CL,[CALLUNIT]
        XOR     CH,CH
        MOV     [SI.SDEVNAME],CL                ; Number of units in name field
        MOV     DL,[NUMIO]
        XOR     DH,DH
        ADD     [NUMIO],CL
        PUSH    DS
        PUSH    SI
        LDS     BX,[CALLBPB]
PERUNIT:
        MOV     SI,[BX]                 ; DS:SI Points to BPB
        INC     BX
        INC     BX                      ; On to next BPB
        MOV     ES:[BP.dpb_drive],DL
        MOV     ES:[BP.dpb_UNIT],DH
        PUSH    BX
        PUSH    CX
        PUSH    DX
        invoke  $SETDPB
        MOV     AX,ES:[BP.dpb_sector_size]
        CMP     AX,[MAXSEC]
        JBE     NOTMAX
        MOV     [MAXSEC],AX
NOTMAX:
        POP     DX
        POP     CX
        POP     BX
        MOV     AX,DS                   ; Save DS
        POP     SI
        POP     DS
        MOV     WORD PTR ES:[BP.dpb_driver_addr],SI
        MOV     WORD PTR ES:[BP.dpb_driver_addr+2],DS
        PUSH    DS
        PUSH    SI
        INC     DH
        INC     DL
        MOV     DS,AX
        ADD     BP,DPBSIZ
        LOOP    PERUNIT
        POP     SI
        POP     DS
        JMP     PERDRV

CONTINIT:
        PUSH    CS
        POP     DS
ASSUME  DS:DOSGROUP
; Calculate true address of buffers, FATs, free space
        MOV     DI,BP           ; First byte after current DPBs
        MOV     BP,[MAXSEC]
        MOV     AX,OFFSET DOSGROUP:SYSBUF
        MOV     [BUFFSTRT],AX
        ADD     AX,BP           ; One I/O buffer
        ADD     AX,BUFINSIZ
        MOV     WORD PTR [DPBHEAD],AX      ; True start of DPBs
        MOV     DX,AX
        SUB     DX,OFFSET DOSGROUP:SYSBUF
        MOV     BP,DX
        ADD     BP,DI           ; Allocate buffer space
        SUB     BP,ADJFAC       ; True address of free memory
        PUSH    BP
        MOV     DI,OFFSET DOSGROUP:MEMSTRT    ; Current start of DPBs
        ADD     DI,dpb_next_dpb      ; Point at dpb_next_dpb field
        MOV     CL,[NUMIO]
        XOR     CH,CH
TRUEDPBAD:
        ADD     AX,DPBSIZ       ; Compute address of next DPB
        STOSW                   ; Set the link to next DPB
        ADD     DI,DPBSIZ-2     ; Point at next address
        LOOP    TRUEDPBAD
        SUB     DI,DPBSIZ       ; Point at last dpb_next_dpb field
        MOV     AX,-1
        STOSW                   ; End of list
        ADD     BP,15           ;True start of free space (round up to segment)
        MOV     CL,4
        SHR     BP,CL           ; Number of segments for DOS resources
        MOV     DX,CS
        ADD     DX,BP           ; First free segment
        MOV     BX,0FH
        MOV     CX,[ENDMEM]

        IF      HIGHMEM
        SUB     CX,BP
        MOV     BP,CX           ; Segment of DOS
        MOV     DX,CS           ; Program segment
        ENDIF

        IF      NOT HIGHMEM
        MOV     BP,CS
        ENDIF

; BP has segment of DOS (whether to load high or run in place)
; DX has program segment (whether after DOS or overlaying DOS)
; CX has size of memory in paragraphs (reduced by DOS size if HIGHMEM)
        MOV     [ENDMEM],CX
        MOV     ES,BP
ASSUME  ES:DOSGROUP

        IF      HIGHMEM
        XOR     SI,SI
        MOV     DI,SI
        MOV     CX,OFFSET DOSGROUP:SYSBUF  ;# bytes to move
        SHR     CX,1            ;# words to move (carry set if odd)
        REP MOVSW               ; Move DOS to high memory
        JNC     NOTODD
        MOVSB
NOTODD:
        ENDIF

        MOV     WORD PTR ES:[DSKCHRET+3],ES
        XOR     AX,AX
        MOV     DS,AX
        MOV     ES,AX
ASSUME  DS:NOTHING,ES:NOTHING
        MOV     DI,INTBASE+2
        MOV     AX,BP
        MOV     BYTE PTR DS:[ENTRYPOINT],mi_Long_JMP
        MOV     WORD PTR DS:[ENTRYPOINT+1],OFFSET DOSGROUP:CALL_ENTRY
        MOV     WORD PTR DS:[ENTRYPOINT+3],AX
        EXTRN   DIVOV:near
        MOV     WORD PTR DS:[0],OFFSET DOSGROUP:DIVOV   ; Set default divide 
							; trap address
        MOV     DS:[2],AX
        MOV     CX,17
        REP STOSW               ; Set 9 segments (skip 2 between each)

        IF      ALTVECT
        MOV     DI,ALTBASE+2
        MOV     CX,15
        REP     STOSW           ; Set 8 segments (skip 2 between each)
        ENDIF

        MOV     WORD PTR DS:[addr_int_abort],OFFSET DOSGROUP:QUIT
        MOV     WORD PTR DS:[addr_int_command],OFFSET DOSGROUP:COMMAND
        MOV     WORD PTR DS:[addr_int_terminate],100H
        MOV     WORD PTR DS:[addr_int_terminate+2],DX
        MOV     WORD PTR DS:[addr_int_ctrl_c],OFFSET DOSGROUP:IRET   
							; Ctrl-C exit
        MOV     WORD PTR DS:[addr_int_fatal_abort],OFFSET DOSGROUP:IRET
							; Fatal error exit
        MOV     WORD PTR DS:[addr_int_disk_read],OFFSET DOSGROUP:ABSDRD
							; INT 25
        MOV     WORD PTR DS:[addr_int_disk_write],OFFSET DOSGROUP:ABSDWRT
							; INT 26
        EXTRN   Stay_resident:NEAR
        MOV     WORD PTR DS:[addr_int_keep_process],OFFSET DOSGROUP:Stay_resident
        MOV     WORD PTR DS:[addr_int_spooler],OFFSET DOSGROUP:IRET  ; Spooler

        IF      NOT ALTVECT
        MOV     CX,12
        XOR     AX,AX
        MOV     DI,2AH*4
        REP     STOSW           ;Zero interrupt locs for ints 2AH-2FH
        ENDIF

        PUSH    CS
        POP     DS
        PUSH    CS
        POP     ES
ASSUME  DS:DOSGROUP,ES:DOSGROUP
        MOV     AX,OFFSET DOSGROUP:INITBLOCK
        ADD     AX,0Fh                  ; round to a paragraph
        MOV     CL,4
        SHR     AX,CL
        MOV     DI,DS
        ADD     DI,AX
        INC     DI
        MOV     [CurrentPDB],DI
        PUSH    BP
        PUSH    DX              ; Save COMMAND address
        MOV     AX,[ENDMEM]
        MOV     DX,DI

        invoke    SETMEM          ; Basic Header
ASSUME  DS:NOTHING,ES:NOTHING
        PUSH    CS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     DI,PDB_JFN_Table
        XOR     AX,AX
        STOSW
        STOSB                   ; 0,1 and 2 are CON device
        MOV     AL,0FFH
        MOV     CX,FilPerProc - 3
        REP     STOSB           ; Rest are unused
        PUSH    CS
        POP     ES
ASSUME  ES:DOSGROUP
        MOV     WORD PTR [sft_addr+2],DS     ; Must be set to print messages

; After this points the char device functions for CON will work for
; printing messages

        IF      NOT IBM
        IF      NOT ALTVECT
        MOV     SI,OFFSET DOSGROUP:HEADER
        invoke  OUTMES
        PUSH    CS                      ; Outmes stomps on segments
        POP     DS
        PUSH    CS
        POP     ES
        ENDIF
        ENDIF

; Move the FATs into position
        POP     DX                      ; Restore COMMAND address
        POP     BP
        POP     CX                      ; True address of free memory
        MOV     SI,OFFSET DOSGROUP:MEMSTRT      ; Place to move DPBs from
        MOV     DI,WORD PTR [DPBHEAD]   ; Place to move DPBs to
        SUB     CX,DI                   ; Total length of DPBs
        CMP     DI,SI
        JBE     MOVJMP                  ; Are we moving to higher or 
					; lower memory?
        DEC     CX                      ; Move backwards to higher memory
        ADD     DI,CX
        ADD     SI,CX
        INC     CX
        STD
MOVJMP:
        MOV     ES,BP
ASSUME  ES:DOSGROUP
        JMP     MOVDPB

CHARINIT:
ASSUME  DS:NOTHING,ES:NOTHING
; DS:SI Points to device header
        MOV     [DEVCALL.REQLEN],DINITHL
        MOV     [DEVCALL.REQUNIT],0
        MOV     [DEVCALL.REQFUNC],DEVINIT
        MOV     [DEVCALL.REQSTAT],0
        PUSH    ES
        PUSH    BX
        PUSH    AX
        MOV     BX,OFFSET DOSGROUP:DEVCALL
        PUSH    CS
        POP     ES
        invoke  DEVIOCALL2
        POP     AX
        POP     BX
        POP     ES
        RET

        DB      80H DUP(?)
INITSTACK LABEL BYTE
        DW      ?

MEMSTRT LABEL   WORD
ADJFAC  EQU     MEMSTRT-SYSBUF

        do_ext
LAST    ENDS
