;
; Disk utilities of MSDOS
;

INCLUDE DOSSEG.ASM

CODE    SEGMENT BYTE PUBLIC  'CODE'
        ASSUME  SS:DOSGROUP,CS:DOSGROUP

.XLIST
.xcref
INCLUDE DOSSYM.ASM
INCLUDE DEVSYM.ASM
.cref
.list

TITLE   ROM - miscellaneous routines
NAME    ROM

        i_need  CLUSNUM,WORD
        i_need  NEXTADD,WORD
        i_need  LASTPOS,WORD
        i_need  SECCLUSPOS,BYTE
        i_need  FATBYT,WORD
        i_need  RECPOS,4
        i_need  THISFCB,DWORD
        i_need  TRANS,BYTE
        i_need  BYTCNT1,WORD
        i_need  CURBUF,DWORD
        i_need  BYTSECPOS,WORD
        i_need  DMAADD,WORD
        i_need  SECPOS,WORD
        i_need  VALSEC,WORD

        procedure   GET_random_record,NEAR
        entry   GETRRPOS1
        MOV     CX,1
        entry   GetRRPos
        MOV     DI,DX
        CMP     BYTE PTR [DI],-1
        JNZ     NORMFCB1
        ADD     DI,7
NORMFCB1:
        MOV     AX,WORD PTR [DI.fcb_RR]
        MOV     DX,WORD PTR [DI.fcb_RR+2]
        return
GET_random_record   ENDP

SUBTTL FNDCLUS -- Skip over allocation units
PAGE
        procedure   FNDCLUS,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       CX = No. of clusters to skip
;       ES:BP = Base of drive parameters
;       [THISFCB] point to FCB
; Outputs:
;       BX = Last cluster skipped to
;       CX = No. of clusters remaining (0 unless EOF)
;       DX = Position of last cluster
; DI destroyed. No other registers affected.

        PUSH    ES
        LES     DI,[THISFCB]
        MOV     BX,ES:[DI.fcb_LSTCLUS]  ; fcb_lstclus is packed with dir clus
        AND     BX,0FFFh                ; get rid of dir nibble
        MOV     DX,ES:[DI.fcb_CLUSPOS]
        OR      BX,BX
        JZ      NOCLUS
        SUB     CX,DX
        JNB     FINDIT
        ADD     CX,DX
        XOR     DX,DX
        MOV     BX,ES:[DI.fcb_FIRCLUS]
FINDIT:
        POP     ES
        JCXZ    RET10
entry   SKPCLP
        invoke  UNPACK
        CMP     DI,0FF8H
        JAE     RET10
        XCHG    BX,DI
        INC     DX
        LOOP    SKPCLP
RET10:  return

NOCLUS:
        POP     ES
        INC     CX
        DEC     DX
        return
FNDCLUS ENDP

SUBTTL BUFSEC -- BUFFER A SECTOR AND SET UP A TRANSFER
PAGE
        procedure   BUFSEC,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       AH = priority of buffer
;       AL = 0 if buffer must be read, 1 if no pre-read needed
;       ES:BP = Base of drive parameters
;       [CLUSNUM] = Physical cluster number
;       [SECCLUSPOS] = Sector position of transfer within cluster
;       [BYTCNT1] = Size of transfer
; Function:
;       Insure specified sector is in buffer, flushing buffer before
;       read if necessary.
; Outputs:
;       ES:DI = Pointer to buffer
;       SI = Pointer to transfer address
;       CX = Number of bytes
;       [NEXTADD] updated
;       [TRANS] set to indicate a transfer will occur

        MOV     DX,[CLUSNUM]
        MOV     BL,[SECCLUSPOS]
        CALL    FIGREC
        invoke  GETBUFFR
        MOV     BYTE PTR [TRANS],1      ; A transfer is taking place
        MOV     SI,[NEXTADD]
        MOV     DI,SI
        MOV     CX,[BYTCNT1]
        ADD     DI,CX
        MOV     [NEXTADD],DI
        LES     DI,[CURBUF]
        ADD     DI,BUFINSIZ             ; Point to buffer
        ADD     DI,[BYTSECPOS]
        return
BUFSEC  ENDP

SUBTTL BUFRD, BUFWRT -- PERFORM BUFFERED READ AND WRITE
PAGE
        procedure   BUFRD,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Do a partial sector read via one of the system buffers
; ES:BP Points to DPB

        PUSH    ES
        MOV     AX,LBRPRI SHL 8         ; Assume last byte read
        CALL    BUFSEC
        MOV     BX,ES
        MOV     ES,[DMAADD+2]
        MOV     DS,BX
ASSUME  DS:NOTHING
        XCHG    DI,SI
        SHR     CX,1
        JNC     EVENRD
        MOVSB
EVENRD:
        REP     MOVSW
        POP     ES
        LDS     DI,[CURBUF]
        LEA     BX,[DI.BufInSiz]
        SUB     SI,BX                   ; Position in buffer
        invoke  PLACEBUF
        CMP     SI,ES:[BP.dpb_sector_size]
        JB      RBUFPLACED
        invoke  PLACEHEAD
RBUFPLACED:
        PUSH    SS
        POP     DS
        return
BUFRD   ENDP

        procedure   BUFWRT,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Do a partial sector write via one of the system buffers
; ES:BP Points to DPB

        MOV     AX,[SECPOS]
        INC     AX              ; Set for next sector
        MOV     [SECPOS],AX
        CMP     AX,[VALSEC]     ; Has sector been written before?
        MOV     AL,1
        JA      NOREAD          ; Skip preread if SECPOS>VALSEC
        XOR     AL,AL
NOREAD:
        PUSH    ES
        CALL    BUFSEC
        MOV     DS,[DMAADD+2]
ASSUME  DS:NOTHING
        SHR     CX,1
        JNC     EVENWRT
        MOVSB
EVENWRT:
        REP     MOVSW
        POP     ES
        LDS     BX,[CURBUF]
        MOV     BYTE PTR [BX.BUFDIRTY],1
        LEA     SI,[BX.BufInSiz]
        SUB     DI,SI                   ; Position in buffer
        MOV     SI,DI
        MOV     DI,BX
        invoke  PLACEBUF
        CMP     SI,ES:[BP.dpb_sector_size]
        JB      WBUFPLACED
        invoke  PLACEHEAD
WBUFPLACED:
        PUSH    SS
        POP     DS
        return
BUFWRT  ENDP

SUBTTL NEXTSEC -- Compute next sector to read or write
PAGE
        procedure   NEXTSEC,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Compute the next sector to read or write
; ES:BP Points to DPB

        TEST    BYTE PTR [TRANS],-1
        JZ      CLRET
        MOV     AL,[SECCLUSPOS]
        INC     AL
        CMP     AL,ES:[BP.dpb_cluster_mask]
        JBE     SAVPOS
        MOV     BX,[CLUSNUM]
        CMP     BX,0FF8H
        JAE     NONEXT
        invoke  UNPACK
        MOV     [CLUSNUM],DI
        INC     [LASTPOS]
        MOV     AL,0
SAVPOS:
        MOV     [SECCLUSPOS],AL
CLRET:
        CLC
        return
NONEXT:
        STC
        return
NEXTSEC ENDP

SUBTTL OPTIMIZE -- DO A USER DISK REQUEST WELL
PAGE
        procedure   OPTIMIZE,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       BX = Physical cluster
;       CX = No. of records
;       DL = sector within cluster
;       ES:BP = Base of drives parameters
;       [NEXTADD] = transfer address
; Outputs:
;       AX = No. of records remaining
;       BX = Transfer address
;       CX = No. or records to be transferred
;       DX = Physical sector address
;       DI = Next cluster
;       [CLUSNUM] = Last cluster accessed
;       [NEXTADD] updated
; ES:BP unchanged. Note that segment of transfer not set.

        PUSH    DX
        PUSH    BX
        MOV     AL,ES:[BP.dpb_cluster_mask]
        INC     AL              ; Number of sectors per cluster
        MOV     AH,AL
        SUB     AL,DL           ; AL = Number of sectors left in first cluster
        MOV     DX,CX
        MOV     CX,0
OPTCLUS:
; AL has number of sectors available in current cluster
; AH has number of sectors available in next cluster
; BX has current physical cluster
; CX has number of sequential sectors found so far
; DX has number of sectors left to transfer
; ES:BP Points to DPB
; ES:SI has FAT pointer
        invoke  UNPACK
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
        MOV     [CLUSNUM],BX    ; Last cluster accessed
        SUB     DX,CX           ; Number of sectors still needed
        PUSH    DX
        MOV     AX,CX
        MUL     ES:[BP.dpb_sector_size]  ; Number of sectors times sector size
        MOV     SI,[NEXTADD]
        ADD     AX,SI           ; Adjust by size of transfer
        MOV     [NEXTADD],AX
        POP     AX              ; Number of sectors still needed
        POP     DX              ; Starting cluster
        SUB     BX,DX           ; Number of new clusters accessed
        ADD     [LASTPOS],BX
        POP     BX              ; BL = sector postion within cluster
        invoke  FIGREC
        MOV     BX,SI
        return
BLKDON:
        SUB     CX,DX           ; Number of sectors in cluster we don't want
        SUB     AH,CL           ; Number of sectors in cluster we accepted
        DEC     AH              ; Adjust to mean position within cluster
        MOV     [SECCLUSPOS],AH
        MOV     CX,DX           ; Anyway, make the total equal to the request
        JMP     SHORT FINCLUS
OPTIMIZE        ENDP

SUBTTL FIGREC -- Figure sector in allocation unit
PAGE
        procedure   FIGREC,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DX = Physical cluster number
;       BL = Sector postion within cluster
;       ES:BP = Base of drive parameters
; Outputs:
;       DX = physical sector number
; No other registers affected.

        PUSH    CX
        MOV     CL,ES:[BP.dpb_cluster_shift]
        DEC     DX
        DEC     DX
        SHL     DX,CL
        OR      DL,BL
        ADD     DX,ES:[BP.dpb_first_sector]
        POP     CX
        return
FIGREC  ENDP

SUBTTL GETREC -- Figure record in file from fcb
PAGE
        procedure   GETREC,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX point to FCB
; Outputs:
;       CX = 1
;       DX:AX = Record number determined by fcb_EXTENT and fcb_NR fields
;       DS:DI point to FCB
; No other registers affected.

        MOV     DI,DX
        CMP     BYTE PTR [DI],-1        ; Check for extended FCB
        JNZ     NORMFCB2
        ADD     DI,7
NORMFCB2:
        MOV     CX,1
        MOV     AL,[DI.fcb_NR]
        MOV     DX,[DI.fcb_EXTENT]
        SHL     AL,1
        SHR     DX,1
        RCR     AL,1
        MOV     AH,DL
        MOV     DL,DH
        MOV     DH,0
        return
GETREC  ENDP

SUBTTL ALLOCATE -- Assign disk space
PAGE
        procedure   ALLOCATE,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       BX = Last cluster of file (0 if null file)
;       CX = No. of clusters to allocate
;       DX = Position of cluster BX
;       ES:BP = Base of drive parameters
;       [THISFCB] = Points to FCB
; Outputs:
;       IF insufficient space
;         THEN
;       Carry set
;       CX = max. no. of records that could be added to file
;         ELSE
;       Carry clear
;       BX = First cluster allocated
;       FAT is fully updated including dirty bit
;       fcb_FIRCLUS field of FCB set if file was null
; SI,BP unchanged. All other registers destroyed.

        PUSH    BX                      ; save the fat byte
        XOR     BX,BX
        invoke  UNPACK
        MOV     [FATBYT],DI
        POP     BX

        PUSH    DX
        PUSH    CX
        PUSH    BX
        MOV     AX,BX
CLUSALLOC:
        MOV     DX,BX
FINDFRE:
        INC     BX
        CMP     BX,ES:[BP.dpb_max_cluster]
        JLE     TRYOUT
        CMP     AX,1
        JG      TRYIN
        POP     BX
        MOV     DX,0FFFH
        invoke  RELBLKS
        POP     AX              ; No. of clusters requested
        SUB     AX,CX           ; AX=No. of clusters allocated
        POP     DX
        invoke  RESTFATBYT
        INC     DX              ; Position of first cluster allocated
        ADD     AX,DX           ; AX=max no. of cluster in file
        MOV     DL,ES:[BP.dpb_cluster_mask]
        MOV     DH,0
        INC     DX              ; DX=records/cluster
        MUL     DX              ; AX=max no. of records in file
        MOV     CX,AX
        SUB     CX,WORD PTR [RECPOS]    ; CX=max no. of records that could be written
        JA      MAXREC
        XOR     CX,CX           ; If CX was negative, zero it
MAXREC:
        STC
        return

TRYOUT:
        invoke  UNPACK
        JZ      HAVFRE
TRYIN:
        DEC     AX
        JLE     FINDFRE
        XCHG    AX,BX
        invoke  UNPACK
        JZ      HAVFRE
        XCHG    AX,BX
        JMP     SHORT FINDFRE
HAVFRE:
        XCHG    BX,DX
        MOV     AX,DX
        invoke  PACK
        MOV     BX,AX
        LOOP    CLUSALLOC
        MOV     DX,0FFFH
        invoke  PACK
        POP     BX
        POP     CX              ; Don't need this stuff since we're successful
        POP     DX
        invoke  UNPACK
        invoke  RESTFATBYT
        XCHG    BX,DI
        OR      DI,DI
        retnz
        PUSH    ES
        LES     DI,[THISFCB]
        AND     BX,0FFFh
        MOV     ES:[DI.fcb_FIRCLUS],BX
        AND     ES:[DI.fcb_LSTCLUS],0F000h  ; clear out old lstclus
        OR      ES:[DI.fcb_LSTCLUS],BX      ; or the new guy in...
        POP     ES
        return
ALLOCATE    ENDP

        procedure   RESTFATBYT,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

        PUSH    BX
        PUSH    DX
        PUSH    DI
        XOR     BX,BX
        MOV     DX,[FATBYT]
        invoke  PACK
        POP     DI
        POP     DX
        POP     BX
        return
RESTFATBYT  ENDP

SUBTTL RELEASE -- DEASSIGN DISK SPACE
PAGE
        procedure   RELEASE,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       BX = Cluster in file
;       ES:BP = Base of drive parameters
; Function:
;       Frees cluster chain starting with [BX]
; AX,BX,DX,DI all destroyed. Other registers unchanged.

        XOR     DX,DX
entry   RELBLKS
; Enter here with DX=0FFFH to put an end-of-file mark
; in the first cluster and free the rest in the chain.
        invoke  UNPACK
        retz
        MOV     AX,DI
        invoke  PACK
        CMP     AX,0FF8H
        MOV     BX,AX
        JB      RELEASE
RET12:  return
RELEASE ENDP

SUBTTL GETEOF -- Find the end of a file
PAGE
        procedure   GETEOF,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       ES:BP Points to DPB
;       BX = Cluster in a file
;       DS = CS
; Outputs:
;       BX = Last cluster in the file
; DI destroyed. No other registers affected.

        invoke  UNPACK
        CMP     DI,0FF8H
        JAE     RET12
        MOV     BX,DI
        JMP     SHORT GETEOF
GETEOF  ENDP

do_ext

CODE    ENDS
    END
          