;
; FAT operations for MSDOS
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

TITLE   FAT - FAT maintenance routines
NAME    FAT

        i_need  CURBUF,DWORD
        i_need  CLUSSPLIT,BYTE
        i_need  CLUSSAVE,WORD
        i_need  CLUSSEC,WORD
        i_need  THISDRV,BYTE
        i_need  DEVCALL,BYTE
        i_need  CALLMED,BYTE
        i_need  CALLRBYT,BYTE
        i_need  BUFFHEAD,DWORD
        i_need  CALLXAD,DWORD
        i_need  CALLBPB,DWORD

SUBTTL UNPACK -- UNPACK FAT ENTRIES
PAGE

ASSUME  SS:DOSGROUP
        procedure   UNPACK,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       BX = Cluster number
;       ES:BP = Base of drive parameters
; Outputs:
;       DI = Contents of FAT for given cluster
;       Zero set means DI=0 (free cluster)
; SI Destroyed, No other registers affected. Fatal error if cluster too big.

        CMP     BX,ES:[BP.dpb_max_cluster]
        JA      HURTFAT
        CALL    MAPCLUSTER
ASSUME  DS:NOTHING
        MOV     DI,[DI]
        JNC     HAVCLUS
        PUSH    CX
        MOV     CL,4
        SHR     DI,CL
        POP     CX
        STC
HAVCLUS:
        AND     DI,0FFFH
        PUSH    SS
        POP     DS
        return

HURTFAT:
        PUSH    AX
        MOV     AH,80H          ; Signal Bad FAT to INT int_fatal_abort handler
        MOV     DI,0FFFH        ; In case INT int_fatal_abort returns (it shouldn't)
        invoke  FATAL
        POP     AX              ; Try to ignore bad FAT
        return
UNPACK  ENDP

SUBTTL PACK -- PACK FAT ENTRIES
PAGE
        procedure   PACK,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       BX = Cluster number
;       DX = Data
;       ES:BP = Pointer to drive DPB
; Outputs:
;       The data is stored in the FAT at the given cluster.
;       SI,DX,DI all destroyed
;       No other registers affected

        CALL    MAPCLUSTER
ASSUME  DS:NOTHING
        MOV     SI,[DI]
        JNC     ALIGNED
        PUSH    CX
        MOV     CL,4
        SHL     DX,CL
        POP     CX
        AND     SI,0FH
        JMP     SHORT PACKIN
ALIGNED:
        AND     SI,0F000H
PACKIN:
        OR      SI,DX
        MOV     [DI],SI
        LDS     SI,[CURBUF]
        MOV     [SI.BUFDIRTY],1
        CMP     BYTE PTR [CLUSSPLIT],0
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        retz
        PUSH    AX
        PUSH    BX
        PUSH    CX
        MOV     AX,[CLUSSAVE]
        MOV     DS,WORD PTR [CURBUF+2]
ASSUME  DS:NOTHING
        ADD     SI,BUFINSIZ
        MOV     [SI],AH
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        PUSH    AX
        MOV     DX,[CLUSSEC]
        MOV     SI,1
        XOR     AL,AL
        invoke  GETBUFFRB
        LDS     DI,[CURBUF]
ASSUME  DS:NOTHING
        MOV     [DI.BUFDIRTY],1
        ADD     DI,BUFINSIZ
        DEC     DI
        ADD     DI,ES:[BP.dpb_sector_size]
        POP     AX
        MOV     [DI],AL
        PUSH    SS
        POP     DS
        POP     CX
        POP     BX
        POP     AX
        return
PACK    ENDP

SUBTTL MAPCLUSTER - BUFFER A FAT SECTOR
PAGE
        procedure   MAPCLUSTER,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       ES:BP Points to DPB
;       BX Is cluster number
; Function:
;       Get a pointer to the cluster
; Outputs:
;       DS:DI Points to contents of FAT for given cluster
;       DS:SI Points to start of buffer
;       Carry set if cluster data is in high 12 bits of word
; No other registers effected

        MOV     BYTE PTR [CLUSSPLIT],0
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     AX,BX
        SHR     AX,1
        ADD     AX,BX
        XOR     DX,DX
        MOV     CX,ES:[BP.dpb_sector_size]
        DIV     CX              ; AX is FAT sector # DX is sector index
        ADD     AX,ES:[BP.dpb_first_FAT]
        DEC     CX
        PUSH    AX
        PUSH    DX
        PUSH    CX
        MOV     DX,AX
        XOR     AL,AL
        MOV     SI,1
        invoke  GETBUFFRB
        LDS     SI,[CURBUF]
ASSUME  DS:NOTHING
        LEA     DI,[SI.BufInSiz]
        POP     CX
        POP     AX
        POP     DX
        ADD     DI,AX
        CMP     AX,CX
        JNZ     MAPRET
        MOV     AL,[DI]
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        INC     BYTE PTR [CLUSSPLIT]
        MOV     BYTE PTR [CLUSSAVE],AL
        MOV     [CLUSSEC],DX
        INC     DX
        XOR     AL,AL
        MOV     SI,1
        invoke  GETBUFFRB
        LDS     SI,[CURBUF]
ASSUME  DS:NOTHING
        LEA     DI,[SI.BufInSiz]
        MOV     AL,[DI]
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     BYTE PTR [CLUSSAVE+1],AL
        MOV     DI,OFFSET DOSGROUP:CLUSSAVE
MAPRET:
        POP     DX
        POP     CX
        POP     BX
        MOV     AX,BX
        SHR     AX,1
        POP     AX
        return
MAPCLUSTER  ENDP

SUBTTL FATREAD -- CHECK DRIVE GET FAT
PAGE
ASSUME  DS:DOSGROUP,ES:NOTHING

        procedure   FAT_operation,NEAR
FATERR:
        AND     DI,STECODE      ; Put error code in DI
        MOV     AH,2            ; While trying to read FAT
        MOV     AL,BYTE PTR [THISDRV]    ; Tell which drive
        invoke  FATAL1

        entry   FATREAD
ASSUME  DS:DOSGROUP,ES:NOTHING

; Function:
;       If disk may have been changed, FAT is read in and buffers are
;       flagged invalid. If not, no action is taken.
; Outputs:
;       ES:BP = Base of drive parameters
; All other registers destroyed

        MOV     AL,BYTE PTR [THISDRV]
        invoke  GETBP
        MOV     AL,DMEDHL
        MOV     AH,ES:[BP.dpb_UNIT]
        MOV     WORD PTR [DEVCALL],AX
        MOV     BYTE PTR [DEVCALL.REQFUNC],DEVMDCH
        MOV     [DEVCALL.REQSTAT],0
        MOV     AL,ES:[BP.dpb_media]
        MOV     BYTE PTR [CALLMED],AL
        PUSH    ES
        PUSH    DS
        MOV     BX,OFFSET DOSGROUP:DEVCALL
        LDS     SI,ES:[BP.dpb_driver_addr]       ; DS:SI Points to device header
ASSUME  DS:NOTHING
        POP     ES                      ; ES:BX Points to call header
        invoke  DEVIOCALL2
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        POP     ES                      ; Restore ES:BP
        MOV     DI,[DEVCALL.REQSTAT]
        TEST    DI,STERR
        JNZ     FATERR
        XOR     AH,AH
        XCHG    AH,ES:[BP.dpb_first_access]      ; Reset dpb_first_access
        MOV     AL,BYTE PTR [THISDRV]    ; Use physical unit number
        OR      AH,BYTE PTR [CALLRBYT]
        JS      NEWDSK          ; new disk or first access?
        JZ      CHKBUFFDIRT
        return                  ; If Media not changed
CHKBUFFDIRT:
        INC     AH              ; Here if ?Media..Check buffers
        LDS     DI,[BUFFHEAD]
ASSUME  DS:NOTHING
NBUFFER:                        ; Look for dirty buffers
        CMP     AX,WORD PTR [DI.BUFDRV]
        retz                    ; There is a dirty buffer, assume Media OK
        LDS     DI,[DI.NEXTBUF]
        CMP     DI,-1
        JNZ     NBUFFER
; If no dirty buffers, assume Media changed
NEWDSK:
        invoke  SETVISIT
NXBUFFER:
        MOV     [DI.VISIT],1
        CMP     AL,[DI.BUFDRV]       ; For this drive?
        JNZ     SKPBUFF
        MOV     WORD PTR [DI.BUFDRV],00FFH  ; Free up buffer
        invoke  SCANPLACE
SKPBUFF:
        invoke  SKIPVISIT
        JNZ     NXBUFFER
        LDS     DI,ES:[BP.dpb_driver_addr]
        TEST    [DI.SDEVATT],ISFATBYDEV
        JNZ     GETFREEBUF
        context DS
        MOV     BX,2
        CALL    UNPACK                  ; Read the first FAT sector into  CURBUF
        LDS     DI,[CURBUF]
        JMP     SHORT GOTGETBUF
GETFREEBUF:
ASSUME  DS:NOTHING
        PUSH    ES                      ; Get a free buffer for BIOS to use
        PUSH    BP
        LDS     DI,[BUFFHEAD]
        invoke  BUFWRITE
        POP     BP
        POP     ES
GOTGETBUF:
        ADD     DI,BUFINSIZ
        MOV     WORD PTR [CALLXAD+2],DS
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     WORD PTR [CALLXAD],DI
        MOV     AL,DBPBHL
        MOV     AH,BYTE PTR ES:[BP.dpb_UNIT]
        MOV     WORD PTR [DEVCALL],AX
        MOV     BYTE PTR [DEVCALL.REQFUNC],DEVBPB
        MOV     [DEVCALL.REQSTAT],0
        MOV     AL,BYTE PTR ES:[BP.dpb_media]
        MOV     [CALLMED],AL
        PUSH    ES
        PUSH    DS
        PUSH    WORD PTR ES:[BP.dpb_driver_addr+2]
        PUSH    WORD PTR ES:[BP.dpb_driver_addr]
        MOV     BX,OFFSET DOSGROUP:DEVCALL
        POP     SI
        POP     DS                      ; DS:SI Points to device header
ASSUME  DS:NOTHING
        POP     ES                      ; ES:BX Points to call header
        invoke  DEVIOCALL2
        POP     ES                      ; Restore ES:BP
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     DI,[DEVCALL.REQSTAT]
        TEST    DI,STERR
        JNZ     FATERRJ
        MOV     AL,BYTE PTR ES:[BP.dpb_media]
        LDS     SI,[CALLBPB]
ASSUME  DS:NOTHING
        CMP     AL,BYTE PTR [SI.BPMEDIA]
        JZ      DPBOK
        invoke  $SETDPB
        LDS     DI,[CALLXAD]            ; Get back buffer pointer
        MOV     AL,BYTE PTR ES:[BP.dpb_FAT_count]
        MOV     AH,BYTE PTR ES:[BP.dpb_FAT_size]
        MOV     WORD PTR [DI.BUFWRTCNT-BUFINSIZ],AX   ;Correct buffer info
DPBOK:
        context ds
        MOV     AX,-1
        TEST    ES:[BP.dpb_current_dir],AX
        retz                            ; If root, leave as root
        MOV     ES:[BP.dpb_current_dir],AX    ; Path may be bad, mark invalid
        return

FATERRJ: JMP    FATERR

FAT_operation   ENDP

do_ext

CODE    ENDS
    END
                                     