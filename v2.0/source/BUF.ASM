;
; buffer management for MSDOS
;

INCLUDE DOSSEG.ASM

CODE    SEGMENT BYTE PUBLIC  'CODE'
        ASSUME  SS:DOSGROUP,CS:DOSGROUP

.xlist
.xcref
INCLUDE DOSSYM.ASM
INCLUDE DEVSYM.ASM
.cref
.list

        i_need  BuffHead,DWORD
        i_need  PreRead,WORD
        i_need  LastBuffer,DWORD
        i_need  CurBuf,DWORD
        i_need  WPErr,BYTE

SUBTTL SETVISIT,SKIPVISIT -- MANAGE BUFFER SCANS
PAGE
        procedure   SETVISIT,near
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       None
; Function:
;       Set up a scan of I/O buffers
; Outputs:
;       All visit flags = 0
;               NOTE: This pre-scan is needed because a hard disk error
;                     may cause a scan to stop in the middle leaving some
;                     visit flags set, and some not set.
;       DS:DI Points to [BUFFHEAD]
; No other registers altered

        LDS     DI,[BUFFHEAD]
        PUSH    AX
        XOR     AX,AX
SETLOOP:
        MOV     [DI.VISIT],AL
        LDS     DI,[DI.NEXTBUF]
        CMP     DI,-1
        JNZ     SETLOOP
        LDS     DI,[BUFFHEAD]
        POP     AX
        return

        entry   SKIPVISIT
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DI Points to a buffer
; Function:
;       Skip visited buffers
; Outputs:
;       DS:DI Points to next unvisited buffer
;       Zero is set if skip to LAST buffer
; No other registers altered

        CMP     DI,-1
        retz
        CMP     [DI.VISIT],1
        retnz
        LDS     DI,[DI.NEXTBUF]
        JMP     SHORT SKIPVISIT
        return
SetVisit    ENDP


SUBTTL SCANPLACE, PLACEBUF -- PUT A BUFFER BACK IN THE POOL
PAGE
        procedure   ScanPlace,near
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       Same as PLACEBUF
; Function:
;       Save scan location and call PLACEBUF
; Outputs:
;       DS:DI Points to saved scan location
; SI destroyed, other registers unchanged

        PUSH    ES
        LES     SI,[DI.NEXTBUF]         ; Save scan location
        CALL    PLACEBUF
        PUSH    ES
        POP     DS                      ; Restore scan location
        MOV     DI,SI
        POP     ES
        return
ScanPlace   ENDP

NRETJ:  JMP     SHORT NRET

        procedure   PLACEBUF,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Input:
;       DS:DI points to buffer
; Function:
;       Remove buffer from queue and re-insert it in proper place.
;       If buffer doesn't go at end, and isn't free, decrement
;       priorities.
; NO registers altered
;
; DS:SI -- Curbuf, current buffer in list
; ES:DI -- Buf, buffer passed as argument
; BP:CX -- Pointsave, saved Buf.nextbuf
; DX:BX -- Lastbuf, previous buffer in list
; AL    -- Inserted, Buf has been inserted
; AH    -- Removed, Buf has been removed

        IF      IBM
        IF      NOT IBM
        invoke  save_world
        XOR     AX,AX           ; Inserted = Removed = FALSE
        LES     CX,[DI.NEXTBUF]
        MOV     BP,ES           ; Pointsave = Buf.nextbuf
        MOV     SI,DS
        MOV     ES,SI           ; Buf is ES:DI
        LDS     SI,[BUFFHEAD]   ; Curbuf = HEAD
        CALL    POINTCOMP       ; Buf == HEAD?
        JNZ     TNEWHEAD
        CMP     CX,-1           ; Buf is LAST?
        JZ      NRETJ           ; Only one buffer, nothing to do
        MOV     WORD PTR [BUFFHEAD],CX
        MOV     WORD PTR [BUFFHEAD+2],BP        ; HEAD = Pointsave
        INC     AH              ; Removed = TRUE
        MOV     DS,BP
        MOV     SI,CX           ; Curbuf = HEAD
TNEWHEAD:
        MOV     BL,ES:[DI.BUFPRI]
        CMP     BL,[SI.BUFPRI]
        JGE     BUFLOOP
NEWHEAD:                        ; If Buf.pri < HEAD.pri
        MOV     WORD PTR ES:[DI.NEXTBUF],SI
        MOV     WORD PTR ES:[DI.NEXTBUF+2],DS   ; Buf.nextbuf = HEAD
        MOV     WORD PTR [BUFFHEAD],DI
        MOV     WORD PTR [BUFFHEAD+2],ES        ; HEAD = Buf
        INC     AL                              ; Inserted = TRUE
        OR      AH,AH
        JNZ     NRET            ; If Removed == TRUE
BUFLOOP:
        PUSH    DS
        PUSH    SI
        LDS     SI,[SI.NEXTBUF]
        CALL    POINTCOMP
        POP     SI
        POP     DS
        JNZ     TESTINS
        MOV     WORD PTR [SI.NEXTBUF],CX        ; If Curbuf.nextbuf == buf
        MOV     WORD PTR [SI.NEXTBUF+2],BP      ; Curbuf.nextbuf = Pointsave
        INC     AH              ; Removed = TRUE
        OR      AL,AL
        JNZ     SHUFFLE         ; If Inserted == TRUE
TESTINS:
        OR      AL,AL
        JNZ     LOOKBUF
        PUSH    CX              ; If NOT Inserted
        MOV     CL,ES:[DI.BUFPRI]
        CMP     CL,[SI.BUFPRI]
        POP     CX
        JGE     LOOKBUF
        PUSH    DS              ; If Buf.pri < Curbuf.pri
        MOV     DS,DX
        MOV     WORD PTR [BX.NEXTBUF],DI
        MOV     WORD PTR [BX.NEXTBUF+2],ES      ; Lastbuf.nextbuf = Buf
        POP     DS
        MOV     WORD PTR ES:[DI.NEXTBUF],SI
        MOV     WORD PTR ES:[DI.NEXTBUF+2],DS   ; Buf.nextbuf = Curbuf
        INC     AL              ; Inserted = TRUE
        OR      AH,AH
        JNZ     SHUFFLE         ; If Removed == TRUE
LOOKBUF:
        MOV     BX,SI
        MOV     DX,DS           ; Lastbuf = Curbuf
        CMP     WORD PTR [SI.NEXTBUF],-1
        JZ      ISLAST
        LDS     SI,[SI.NEXTBUF] ; Curbuf = Curbuf.nextbuf
        JMP     SHORT BUFLOOP
ISLAST:                 ; If Curbuf is LAST
        MOV     WORD PTR [SI.NEXTBUF],DI
        MOV     WORD PTR [SI.NEXTBUF+2],ES      ; Curbuf.nextbuf = Buf
        MOV     WORD PTR ES:[DI.NEXTBUF],-1
        MOV     WORD PTR ES:[DI.NEXTBUF+2],-1      ; Buf is LAST
NRET:
        invoke  restore_world
        return

SHUFFLE:
        LDS     DI,[BUFFHEAD]
DECLOOP:
        CMP     [DI.BUFPRI],FREEPRI
        JZ      NODEC
        DEC     [DI.BUFPRI]
NODEC:
        LDS     DI,[DI.NEXTBUF]
        CMP     DI,-1
        JNZ     DECLOOP
        JMP     SHORT NRET
        ENDIF
        ENDIF

        invoke  save_world
        LES     CX,[DI.NEXTBUF]
        CMP     CX,-1           ; Buf is LAST?
        JZ      NRET            ; Buffer already last
        MOV     BP,ES           ; Pointsave = Buf.nextbuf
        PUSH    DS
        POP     ES              ; Buf is ES:DI
        LDS     SI,[BUFFHEAD]   ; Curbuf = HEAD
        CALL    POINTCOMP       ; Buf == HEAD?
        JNZ     BUFLOOP
        MOV     WORD PTR [BUFFHEAD],CX
        MOV     WORD PTR [BUFFHEAD+2],BP        ; HEAD = Pointsave
        JMP     SHORT LOOKEND

BUFLOOP:
        PUSH    DS
        PUSH    SI
        LDS     SI,[SI.NEXTBUF]
        CALL    POINTCOMP
        JZ      GOTTHEBUF
        POP     AX
        POP     AX
        JMP     SHORT BUFLOOP

GOTTHEBUF:
        POP     SI
        POP     DS
        MOV     WORD PTR [SI.NEXTBUF],CX        ; If Curbuf.nextbuf == buf
        MOV     WORD PTR [SI.NEXTBUF+2],BP      ; Curbuf.nextbuf = Pointsave
LOOKEND:
        PUSH    DS
        PUSH    SI
        LDS     SI,[SI.NEXTBUF]
        CMP     SI,-1
        JZ      GOTHEEND
        POP     AX
        POP     AX
        JMP     SHORT LOOKEND

GOTHEEND:
        POP     SI
        POP     DS
        MOV     WORD PTR [SI.NEXTBUF],DI
        MOV     WORD PTR [SI.NEXTBUF+2],ES      ; Curbuf.nextbuf = Buf
        MOV     WORD PTR ES:[DI.NEXTBUF],-1
        MOV     WORD PTR ES:[DI.NEXTBUF+2],-1      ; Buf is LAST
NRET:
        invoke  restore_world
        return

PLACEBUF    ENDP

        procedure   PLACEHEAD,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; SAME AS PLACEBUF except places buffer at head

        invoke  save_world
        PUSH    DS
        POP     ES
        LDS     SI,[BUFFHEAD]
        MOV     WORD PTR [BUFFHEAD],DI
        MOV     WORD PTR [BUFFHEAD+2],ES
        MOV     WORD PTR ES:[DI.NEXTBUF],SI
        MOV     WORD PTR ES:[DI.NEXTBUF+2],DS
LOOKEND2:
        PUSH    DS
        PUSH    SI
        LDS     SI,[SI.NEXTBUF]
        CALL    POINTCOMP
        JZ      GOTHEEND2
        POP     AX
        POP     AX
        JMP     SHORT LOOKEND2

GOTHEEND2:
        POP     SI
        POP     DS
        MOV     WORD PTR [SI.NEXTBUF],-1
        MOV     WORD PTR [SI.NEXTBUF+2],-1      ; Buf is LAST
        JMP     SHORT NRET

PLACEHEAD   ENDP

SUBTTL POINTCOMP -- 20 BIT POINTER COMPARE
PAGE
        procedure   PointComp,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Compare DS:SI to ES:DI (or DS:DI to ES:SI) for equality
; DO NOT USE FOR < or >
; No Registers altered

        CMP     SI,DI
        retnz
        PUSH    CX
        PUSH    DX
        MOV     CX,DS
        MOV     DX,ES
        CMP     CX,DX
        POP     DX
        POP     CX
        return
PointComp   ENDP

SUBTTL GETBUFFR -- GET A SECTOR INTO A BUFFER
PAGE
        procedure   GETBUFFR,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Input:
;       AH = Priority buffer is to have
;       AL = 0 means sector must be pre-read
;          ELSE no pre-read
;       DX = Desired physical sector number
;       ES:BP = Pointer to drive parameters
; Function:
;       Get the specified sector into one of the I/O buffers
;       And shuffle the queue
; Output:
;       [CURBUF] Points to the Buffer for the sector
; DX,ES:BP unchanged, all other registers destroyed

        XOR     SI,SI
        entry   GETBUFFRB
        MOV     [PREREAD],AX
        MOV     AL,ES:[BP.dpb_drive]
        LDS     DI,[LASTBUFFER]
ASSUME  DS:NOTHING
        CMP     DI,-1                           ; Recency pointer valid?
        JZ      SKBUF                           ; No
        CMP     DX,[DI.BUFSECNO]
        JNZ     SKBUF                           ; Wrong sector
        CMP     AL,[DI.BUFDRV]
        JNZ     SKBUF                           ; Wrong Drive
        JMP     SHORT JUSTBUF                   ; Just asked for same buffer
SKBUF:
        LDS     DI,[BUFFHEAD]
NXTBFF:
        CMP     DX,[DI.BUFSECNO]
        JNZ     BUMP
        CMP     AL,[DI.BUFDRV]
        JNZ     BUMP
        JMP     SHORT SETINF
BUMP:
        LDS     DI,[DI.NEXTBUF]
        CMP     DI,-1
        JNZ     NXTBFF
        LDS     DI,[BUFFHEAD]
        PUSH    SI
        PUSH    DX
        PUSH    BP
        PUSH    ES
        CALL    BUFWRITE        ; Write out the dirty buffer
        POP     ES
        POP     BP
        POP     DX
        POP     SI
RDSEC:                          ; Read in the new sector
        TEST    BYTE PTR [PREREAD],-1
        JNZ     SETBUF
        LEA     BX,[DI.BufInSiz]        ; Point at buffer
        MOV     CX,1
        PUSH    SI
        PUSH    DI
        PUSH    DX
        OR      SI,SI
        JZ      NORMSEC
        invoke  FATSECRD
        JMP     SHORT GOTTHESEC         ; Buffer is marked free if read barfs
NORMSEC:
        invoke  DREAD                   ; Buffer is marked free if read barfs
GOTTHESEC:
        POP     DX
        POP     DI
        POP     SI
SETBUF:
        MOV     [DI.BUFSECNO],DX
        MOV     WORD PTR [DI.BUFDRVDP],BP
        MOV     WORD PTR [DI.BUFDRVDP+2],ES
        XOR     AH,AH
        MOV     AL,ES:[BP.dpb_drive]
        MOV     WORD PTR [DI.BUFDRV],AX
SETINF:
        MOV     AX,1                            ; Default to not a FAT sector
        OR      SI,SI
        JZ      SETSTUFFOK
        MOV     AL,ES:[BP.dpb_FAT_count]
        MOV     AH,ES:[BP.dpb_FAT_size]
SETSTUFFOK:
        MOV     WORD PTR [DI.BUFWRTCNT],AX
        CALL    PLACEBUF
JUSTBUF:
        MOV     WORD PTR [CURBUF+2],DS
        MOV     WORD PTR [LASTBUFFER+2],DS
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     WORD PTR [CURBUF],DI
        MOV     WORD PTR [LASTBUFFER],DI
        return
GETBUFFR    ENDP


SUBTTL FLUSHBUF -- WRITE OUT DIRTY BUFFERS
PAGE
        procedure   FlushBuf,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Input:
;       DS = DOSGROUP
;       AL = Physical unit number
;          = -1 for all units
; Function:
;       Write out all dirty buffers for unit, and flag them as clean
; DS Preserved, all others destroyed (ES too)

        LDS     DI,[BUFFHEAD]
ASSUME  DS:NOTHING
        MOV     AH,-1
NXTBUFF:
        CMP     [DI.BUFDRV],AH
        JZ      SKIPBFF                 ; Skip free buffers
        CMP     AH,AL
        JZ      DOBUFFER                ; Do all dirty buffers
        CMP     AL,[DI.BUFDRV]
        JNZ     SKIPBFF                 ; Buffer not for this unit
DOBUFFER:
        CMP     BYTE PTR [DI.BUFDIRTY],0
        JZ      SKIPBFF                 ; Buffer not dirty
        PUSH    AX
        PUSH    WORD PTR [DI.BUFDRV]
        CALL    BUFWRITE
        POP     AX
        XOR     AH,AH                   ; Buffer is clean
        CMP     AL,BYTE PTR [WPERR]
        JNZ     NOZAP
        MOV     AL,0FFH                 ; Invalidate buffer, it is inconsistent
NOZAP:
        MOV     WORD PTR [DI.BUFDRV],AX
        POP     AX                      ; Search info
SKIPBFF:
        LDS     DI,[DI.NEXTBUF]
        CMP     DI,-1
        JNZ     NXTBUFF
        PUSH    SS
        POP     DS
        return
FlushBuf    ENDP


SUBTTL BUFWRITE -- WRITE OUT A BUFFER IF DIRTY
PAGE
        procedure   BufWrite,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Input:
;       DS:DI Points to the buffer
; Function:
;       Write out all the buffer if dirty.
; Output:
;       Buffer marked free
; DS:DI Preserved, ALL others destroyed (ES too)

        MOV     AX,00FFH
        XCHG    AX,WORD PTR [DI.BUFDRV] ; Free, in case write barfs
        CMP     AL,0FFH
        retz                            ; Buffer is free.
        OR      AH,AH
        retz                            ; Buffer is clean.
        CMP     AL,BYTE PTR [WPERR]
        retz                            ; If in WP error zap buffer
        LES     BP,[DI.BUFDRVDP]
        LEA     BX,[DI.BufInSiz]        ; Point at buffer
        MOV     DX,[DI.BUFSECNO]
        MOV     CX,WORD PTR [DI.BUFWRTCNT]
        MOV     AL,CH                   ; [DI.BUFWRTINC]
        XOR     CH,CH
        MOV     AH,CH
        PUSH    DI
WRTAGAIN:
        PUSH    CX
        PUSH    AX
        MOV     CX,1
        PUSH    BX
        PUSH    DX
        invoke  DWRITE          ; Write out the dirty buffer
        POP     DX
        POP     BX
        POP     AX
        POP     CX
        ADD     DX,AX
        LOOP    WRTAGAIN
        POP     DI
        return
BufWrite    ENDP

do_ext

CODE    ENDS
    END
