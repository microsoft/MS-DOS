;
; Disk routines for MSDOS
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

TITLE   DISK - Disk utility routines
NAME    Disk

        i_need  COUTDSAV,BYTE
        i_need  COUTSAV,DWORD
        i_need  CINDSAV,BYTE
        i_need  CINSAV,DWORD
        i_need  CONSWAP,BYTE
        i_need  IDLEINT,BYTE
        i_need  THISFCB,DWORD
        i_need  DMAADD,DWORD
        i_need  DEVCALL,BYTE
        i_need  CALLSCNT,WORD
        i_need  CALLXAD,DWORD
        i_need  CONTPOS,WORD
        i_need  NEXTADD,WORD
        i_need  CONBUF,BYTE
        i_need  User_SS,WORD
        i_need  User_SP,WORD
        i_need  DSKStack,BYTE
        i_need  InDOS,BYTE
        i_need  NumIO,BYTE
        i_need  CurDrv,BYTE
        i_need  ThisDrv,BYTE
        i_need  ClusFac,BYTE
        i_need  SecClusPos,BYTE
        i_need  DirSec,WORD
        i_need  ClusNum,WORD
        i_need  NxtClusNum,WORD
        i_need  ReadOp,BYTE
        i_need  DskErr,BYTE
        i_need  RecCnt,WORD
        i_need  RecPos,4
        i_need  Trans,BYTE
        i_need  BytPos,4
        i_need  SecPos,WORD
        i_need  BytSecPos,WORD
        i_need  BytCnt1,WORD
        i_need  BytCnt2,WORD
        i_need  SecCnt,WORD
        i_need  ThisDPB,DWORD
        i_need  LastPos,WORD
        i_need  ValSec,WORD
        i_need  GrowCnt,DWORD

SUBTTL LOAD -- MAIN READ ROUTINE AND DEVICE IN ROUTINES
PAGE
; * * * * Drivers for file input from devices * * * *

        procedure   SWAPBACK,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING
        PUSH    ES
        PUSH    DI
        PUSH    SI
        PUSH    BX
        MOV     BX,1
        invoke  get_sf_from_jfn
        ADD     DI,sf_fcb
        MOV     BL,BYTE PTR [COUTDSAV]
        LDS     SI,[COUTSAV]
ASSUME  DS:NOTHING
        MOV     WORD PTR ES:[DI.fcb_FIRCLUS],SI
        MOV     WORD PTR ES:[DI.fcb_FIRCLUS+2],DS
        MOV     ES:[DI.fcb_DEVID],BL
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        XOR     BX,BX
        invoke  get_sf_from_jfn
        ADD     DI,sf_fcb
        MOV     BL,BYTE PTR [CINDSAV]
        LDS     SI,[CINSAV]
ASSUME  DS:NOTHING
        MOV     WORD PTR ES:[DI.fcb_FIRCLUS],SI
        MOV     WORD PTR ES:[DI.fcb_FIRCLUS+2],DS
        MOV     ES:[DI.fcb_DEVID],BL
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     BYTE PTR [CONSWAP],0
        MOV     BYTE PTR [IDLEINT],1
SWAPRET:
        POP     BX
        POP     SI
        POP     DI
        POP     ES
        return
SWAPBACK    ENDP

        procedure   SWAPCON,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING
        PUSH    ES
        PUSH    DI
        PUSH    SI
        PUSH    BX
        MOV     BYTE PTR [CONSWAP],1
        MOV     BYTE PTR [IDLEINT],0
        XOR     BX,BX
        invoke  get_sf_from_jfn
        ADD     DI,sf_fcb
        MOV     BL,ES:[DI.fcb_DEVID]
        MOV     BYTE PTR [CINDSAV],BL
        LDS     SI,DWORD PTR ES:[DI.fcb_FIRCLUS]
ASSUME  DS:NOTHING
        MOV     WORD PTR [CINSAV],SI
        MOV     WORD PTR [CINSAV+2],DS
        LDS     SI,[THISFCB]
        MOV     BL,[SI.fcb_DEVID]
        LDS     SI,DWORD PTR [SI.fcb_FIRCLUS]
        MOV     ES:[DI.fcb_DEVID],BL
        MOV     WORD PTR ES:[DI.fcb_FIRCLUS],SI
        MOV     WORD PTR ES:[DI.fcb_FIRCLUS+2],DS
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     BX,1
        invoke  get_sf_from_jfn
        ADD     DI,sf_fcb
        MOV     BL,ES:[DI.fcb_DEVID]
        MOV     BYTE PTR [COUTDSAV],BL
        LDS     SI,DWORD PTR ES:[DI.fcb_FIRCLUS]
ASSUME  DS:NOTHING
        MOV     WORD PTR [COUTSAV],SI
        MOV     WORD PTR [COUTSAV+2],DS
        LDS     SI,[THISFCB]
        MOV     BL,[SI.fcb_DEVID]
        LDS     SI,DWORD PTR [SI.fcb_FIRCLUS]
        MOV     ES:[DI.fcb_DEVID],BL
        MOV     WORD PTR ES:[DI.fcb_FIRCLUS],SI
        MOV     WORD PTR ES:[DI.fcb_FIRCLUS+2],DS
        PUSH    SS
        POP     DS
        JMP     SWAPRET
SWAPCON ENDP

        procedure   LOAD,NEAR
ASSUME  DS:NOTHING,ES:NOTHING
;
; Inputs:
;       DS:DI point to FCB
;       DX:AX = Position in file to read
;       CX = No. of records to read
; Outputs:
;       DX:AX = Position of last record read
;       CX = No. of bytes read
;       ES:DI point to FCB
;       fcb_LSTCLUS, fcb_CLUSPOS fields in FCB set

        call    SETUP
ASSUME  DS:DOSGROUP
        OR      BL,BL           ; Check for named device I/O
        JS      READDEV
        call    DISKREAD
        return

READDEV:
ASSUME  DS:DOSGROUP,ES:NOTHING
        LES     DI,[DMAADD]
        TEST    BL,40H                  ; End of file?
        JZ      ENDRDDEVJ3
        TEST    BL,ISNULL               ; NUL device?
        JZ      TESTRAW                 ; NO
        XOR     AL,AL                   ; Indicate EOF
ENDRDDEVJ3: JMP ENDRDDEVJ2

DVRDRAW:
ASSUME  DS:DOSGROUP
        PUSH    ES
        POP     DS
ASSUME  DS:NOTHING
DVRDRAWR:
        MOV     BX,DI                   ; DS:BX transfer addr
        XOR     DX,DX                   ; Start at 0
        XOR     AX,AX                   ; Media Byte, unit = 0
        invoke  SETREAD
        LDS     SI,[THISFCB]
        invoke  DEVIOCALL
        MOV     DX,DI                   ; DX is preserved by INT 24
        MOV     AH,86H                  ; Read error
        MOV     DI,[DEVCALL.REQSTAT]
        TEST    DI,STERR
        JZ      CRDROK                  ; No errors
        invoke  CHARHARD
        MOV     DI,DX
        CMP     AL,1
        JZ      DVRDRAWR                ; Retry
CRDROK:
        MOV     DI,DX
        ADD     DI,[CALLSCNT]           ; Amount transferred
        JMP     SHORT ENDRDDEVJ2

TESTRAW:
        TEST    BL,020H                 ; Raw mode?
        JNZ     DVRDRAW
        TEST    BL,ISCIN                ; Is it console device?
        JZ      NOTRDCON
        JMP     READCON
NOTRDCON:
        MOV     AX,ES
        MOV     DS,AX
ASSUME  DS:NOTHING
        MOV     BX,DI
        XOR     DX,DX
        MOV     AX,DX
        PUSH    CX
        MOV     CX,1
        invoke  SETREAD
        POP     CX
        LDS     SI,[THISFCB]
        LDS     SI,DWORD PTR [SI.fcb_FIRCLUS]
DVRDLP:
        invoke  DSKSTATCHK
        invoke  DEVIOCALL2
        PUSH    DI
        MOV     AH,86H
        MOV     DI,[DEVCALL.REQSTAT]
        TEST    DI,STERR
        JZ      CRDOK
        invoke  CHARHARD
        POP     DI
        MOV     [CALLSCNT],1
        CMP     AL,1
        JZ      DVRDLP                  ;Retry
        XOR     AL,AL                   ;Pick some random character
        JMP     SHORT DVRDIGN
CRDOK:
        POP     DI
        CMP     [CALLSCNT],1
        JNZ     ENDRDDEVJ2
        PUSH    DS
        MOV     DS,WORD PTR [CALLXAD+2]
        MOV     AL,BYTE PTR [DI]
        POP     DS
DVRDIGN:
        INC     WORD PTR [CALLXAD]
        MOV     [DEVCALL.REQSTAT],0
        INC     DI
        CMP     AL,1AH                  ; ^Z?
        JZ      ENDRDDEVJ
        CMP     AL,c_CR                 ; CR?
        LOOPNZ  DVRDLP
ENDRDDEVJ:
        DEC     DI
ENDRDDEVJ2:
        JMP     SHORT ENDRDDEV

ASSUME  DS:NOTHING,ES:NOTHING

TRANBUF:
        LODSB
        STOSB
        CMP     AL,c_CR         ; Check for carriage return
        JNZ     NORMCH
        MOV     BYTE PTR [SI],c_LF
NORMCH:
        CMP     AL,c_LF
        LOOPNZ  TRANBUF
        JNZ     ENDRDCON
        XOR     SI,SI           ; Cause a new buffer to be read
        invoke  OUT             ; Transmit linefeed
        OR      AL,1            ; Clear zero flag--not end of file
ENDRDCON:
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        CALL    SWAPBACK
        MOV     [CONTPOS],SI
ENDRDDEV:
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     [NEXTADD],DI
        JNZ     SETFCBC         ; Zero set if Ctrl-Z found in input
        LES     DI,[THISFCB]
        AND     ES:BYTE PTR [DI.fcb_DEVID],0FFH-40H ; Mark as no more data available
SETFCBC:
        call    SETFCB
        return

ASSUME  DS:NOTHING,ES:NOTHING

READCON:
ASSUME  DS:DOSGROUP
        CALL    SWAPCON
        MOV     SI,[CONTPOS]
        OR      SI,SI
        JNZ     TRANBUF
        CMP     BYTE PTR [CONBUF],128
        JZ      GETBUF
        MOV     WORD PTR [CONBUF],0FF80H        ; Set up 128-byte buffer with no template
GETBUF:
        PUSH    CX
        PUSH    ES
        PUSH    DI
        MOV     DX,OFFSET DOSGROUP:CONBUF
        invoke  $STD_CON_STRING_INPUT           ; Get input buffer
        POP     DI
        POP     ES
        POP     CX
        MOV     SI,2 + OFFSET DOSGROUP:CONBUF
        CMP     BYTE PTR [SI],1AH       ; Check for Ctrl-Z in first character
        JNZ     TRANBUF
        MOV     AL,1AH
        STOSB
        DEC     DI
        MOV     AL,10
        invoke  OUT             ; Send linefeed
        XOR     SI,SI
        JMP     SHORT ENDRDCON

LOAD    ENDP

SUBTTL STORE -- MAIN WRITE ROUTINE AND DEVICE OUT ROUTINES
PAGE
ASSUME  DS:NOTHING,ES:NOTHING
        procedure   STORE,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DI point to FCB
;       DX:AX = Position in file of disk transfer
;       CX = Record count
; Outputs:
;       DX:AX = Position of last record written
;       CX = No. of records written
;       ES:DI point to FCB
;       fcb_LSTCLUS, fcb_CLUSPOS fields in FCB set

        call    SETUP
ASSUME  DS:DOSGROUP
        OR      BL,BL
        JS      WRTDEV
        invoke  DATE16
        MOV     ES:[DI.fcb_FDATE],AX
        MOV     ES:[DI.fcb_FTIME],DX
        call    DISKWRITE
        return

WRITECON:
        PUSH    DS
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        CALL    SWAPCON
        POP     DS
ASSUME  DS:NOTHING
        MOV     SI,BX
        PUSH    CX
WRCONLP:
        LODSB
        CMP     AL,1AH          ; ^Z?
        JZ      CONEOF
        invoke  OUT
        LOOP    WRCONLP
CONEOF:
        POP     AX                      ; Count
        SUB     AX,CX                   ; Amount actually written
        POP     DS
ASSUME  DS:DOSGROUP
        CALL    SWAPBACK
        JMP     SHORT ENDWRDEV

DVWRTRAW:
ASSUME  DS:NOTHING
        XOR     AX,AX                   ; Media Byte, unit = 0
        invoke  SETWRITE
        LDS     SI,[THISFCB]
        invoke  DEVIOCALL
        MOV     DX,DI
        MOV     AH,87H
        MOV     DI,[DEVCALL.REQSTAT]
        TEST    DI,STERR
        JZ      CWRTROK
        invoke  CHARHARD
        MOV     BX,DX                   ; Recall transfer addr
        CMP     AL,1
        JZ      DVWRTRAW                ; Try again
CWRTROK:
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     AX,[CALLSCNT]           ; Get actual number of bytes transferred
ENDWRDEV:
        LES     DI,[THISFCB]
        XOR     DX,DX
        DIV     ES:[DI.fcb_RECSIZ]
        MOV     CX,AX                   ; Partial record is ignored
        call    ADDREC
        return

ASSUME  DS:DOSGROUP
WRTDEV:
        OR      BL,40H          ; Reset EOF for input
        XOR     AX,AX
        JCXZ    ENDWRDEV        ; problem of creating on a device.
        PUSH    DS
        MOV     AL,BL
        LDS     BX,[DMAADD]
ASSUME  DS:NOTHING
        MOV     DI,BX
        XOR     DX,DX                   ; Set starting point
        TEST    AL,020H                 ; Raw?
        JNZ     DVWRTRAW
        TEST    AL,ISCOUT               ; Console output device?
        JNZ     WRITECON
        TEST    AL,ISNULL
        JNZ     WRTNUL
        MOV     AX,DX
        CMP     BYTE PTR [BX],1AH       ; ^Z?
        JZ      WRTCOOKDONE             ; Yes, transfer nothing
        PUSH    CX
        MOV     CX,1
        invoke  SETWRITE
        POP     CX
        LDS     SI,[THISFCB]
        LDS     SI,DWORD PTR [SI.fcb_FIRCLUS]
DVWRTLP:
        invoke  DSKSTATCHK
        invoke  DEVIOCALL2
        PUSH    DI
        MOV     AH,87H
        MOV     DI,[DEVCALL.REQSTAT]
        TEST    DI,STERR
        JZ      CWROK
        invoke  CHARHARD
        POP     DI
        MOV     [CALLSCNT],1
        CMP     AL,1
        JZ      DVWRTLP
        JMP     SHORT DVWRTIGN
CWROK:
        POP     DI
        CMP     [CALLSCNT],0
        JZ      WRTCOOKDONE
DVWRTIGN:
        INC     DX
        INC     WORD PTR [CALLXAD]
        INC     DI
        PUSH    DS
        MOV     DS,WORD PTR [CALLXAD+2]
        CMP     BYTE PTR [DI],1AH       ; ^Z?
        POP     DS
        JZ      WRTCOOKDONE
        MOV     [DEVCALL.REQSTAT],0
        LOOP    DVWRTLP
WRTCOOKDONE:
        MOV     AX,DX
        POP     DS
        JMP     ENDWRDEV

WRTNUL:
        MOV     DX,CX                   ;Entire transfer done
        JMP     WRTCOOKDONE

STORE   ENDP

        procedure   get_io_fcb,near
ASSUME  DS:NOTHING,ES:NOTHING
; Convert JFN number in BX to FCB in DS:SI
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        PUSH    ES
        PUSH    DI
        invoke  get_sf_from_jfn
        JC      RET44P
        MOV     SI,DI
        ADD     SI,sf_fcb
        PUSH    ES
        POP     DS
ASSUME  DS:NOTHING
RET44P:
        POP     DI
        POP     ES
        return
get_io_fcb  ENDP

SUBTTL GETTHISDRV -- FIND CURRENT DRIVE
PAGE
; Input:    AL has drive identifier (1=A, 0=default)
; Output:   AL has physical drive (0=A)
; Carry set if invalid drive (and AL is garbage anyway)
        procedure   GetThisDrv,NEAR
ASSUME  DS:NOTHING,ES:NOTHING
        CMP     BYTE PTR [NUMIO],AL
        retc
        DEC     AL
        JNS     PHYDRV
        MOV     AL,[CURDRV]
PHYDRV:
        MOV     BYTE PTR [THISDRV],AL
        return
GetThisDrv  ENDP

SUBTTL DIRREAD -- READ A DIRECTORY SECTOR
PAGE
        procedure   DirRead,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       AX = Directory block number (relative to first block of directory)
;       ES:BP = Base of drive parameters
;       [DIRSEC] = First sector of first cluster of directory
;       [CLUSNUM] = Next cluster
;       [CLUSFAC] = Sectors/Cluster
; Function:
;       Read the directory block into [CURBUF].
; Outputs:
;       [NXTCLUSNUM] = Next cluster (after the one skipped to)
;       [SECCLUSPOS] Set
;       ES:BP unchanged [CURBUF] Points to Buffer with dir sector
; All other registers destroyed.

        MOV     CL,[CLUSFAC]
        DIV     CL              ; AL # clusters to skip, AH position in cluster
        MOV     [SECCLUSPOS],AH
        MOV     CL,AL
        XOR     CH,CH
        MOV     DX,[DIRSEC]
        ADD     DL,AH
        ADC     DH,0
        MOV     BX,[CLUSNUM]
        MOV     [NXTCLUSNUM],BX
        JCXZ    FIRSTCLUSTER
SKPCLLP:
        invoke  UNPACK
        XCHG    BX,DI
        CMP     BX,0FF8H
        JAE     HAVESKIPPED
        LOOP    SKPCLLP
HAVESKIPPED:
        MOV     [NXTCLUSNUM],BX
        MOV     DX,DI
        MOV     BL,AH
        invoke  FIGREC
        entry   FIRSTCLUSTER
        XOR     AL,AL           ; Indicate pre-read
        MOV     AH,DIRPRI
        invoke  GETBUFFR
        ret
DirRead ENDP

SUBTTL FATSECRD -- READ A FAT SECTOR
PAGE
        procedure   FATSecRd,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       Same as DREAD
;       DS:BX = Transfer address
;       CX = Number of sectors
;       DX = Absolute record number
;       ES:BP = Base of drive parameters
; Function:
;       Calls BIOS to perform FAT read.
; Outputs:
;       Same as DREAD

        MOV     DI,CX
        MOV     CL,ES:[BP.dpb_FAT_count]
        MOV     AL,ES:[BP.dpb_FAT_size]
        XOR     AH,AH
        MOV     CH,AH
        PUSH    DX
NXTFAT:
        PUSH    CX
        PUSH    AX
        MOV     CX,DI
        CALL    DSKREAD
        POP     AX
        POP     CX
        JZ      RET41P
        ADD     DX,AX
        LOOP    NXTFAT
        POP     DX
        MOV     CX,DI

; NOTE FALL THROUGH

SUBTTL DREAD -- DO A DISK READ
PAGE
        entry   DREAD
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:BX = Transfer address
;       CX = Number of sectors
;       DX = Absolute record number
;       ES:BP = Base of drive parameters
; Function:
;       Calls BIOS to perform disk read. If BIOS reports
;       errors, will call HARDERR for further action.
; DS,ES:BP preserved. All other registers destroyed.

        CALL    DSKREAD
        retz
        MOV     BYTE PTR [READOP],0
        invoke  HARDERR
        CMP     AL,1            ; Check for retry
        JZ      DREAD
        return                  ; Ignore otherwise
RET41P: POP     DX
        return
FATSecRd    ENDP

SUBTTL DSKREAD -- PHYSICAL DISK READ
PAGE
        procedure   DskRead,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:BX = Transfer addr
;       CX = Number of sectors
;       DX = Absolute record number
;       ES:BP = Base of drive parameters
; Function:
;       Call BIOS to perform disk read
; Outputs:
;       DI = CX on entry
;       CX = Number of sectors unsuccessfully transfered
;       AX = Status word as returned by BIOS (error code in AL if error)
;       Zero set if OK (from BIOS)
;       Zero clear if error
; SI Destroyed, others preserved

        PUSH    CX
        MOV     AH,ES:[BP.dpb_media]
        MOV     AL,ES:[BP.dpb_UNIT]
        PUSH    BX
        PUSH    ES
        invoke  SETREAD
        JMP     DODSKOP

SUBTTL DWRITE -- SEE ABOUT WRITING
PAGE
        entry   DWRITE
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:BX = Transfer address
;       CX = Number of sectors
;       DX = Absolute record number
;       ES:BP = Base of drive parameters
; Function:
;       Calls BIOS to perform disk write. If BIOS reports
;       errors, will call HARDERR for further action.
; BP preserved. All other registers destroyed.

        CALL    DSKWRITE
        retz
        MOV     BYTE PTR [READOP],1
        invoke  HARDERR
        CMP     AL,1            ; Check for retry
        JZ      DWRITE
        return

SUBTTL DSKWRITE -- PHYSICAL DISK WRITE
PAGE
        entry   DSKWRITE
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:BX = Transfer addr
;       CX = Number of sectors
;       DX = Absolute record number
;       ES:BP = Base of drive parameters
; Function:
;       Call BIOS to perform disk read
; Outputs:
;       DI = CX on entry
;       CX = Number of sectors unsuccessfully transfered
;       AX = Status word as returned by BIOS (error code in AL if error)
;       Zero set if OK (from BIOS)
;       Zero clear if error
; SI Destroyed, others preserved

        PUSH    CX
        MOV     AH,ES:[BP.dpb_media]
        MOV     AL,ES:[BP.dpb_UNIT]
        PUSH    BX
        PUSH    ES
        invoke  SETWRITE
DODSKOP:
        MOV     CX,DS           ; Save DS
        POP     DS              ; DS:BP points to DPB
        PUSH    DS
        LDS     SI,DS:[BP.dpb_driver_addr]
        invoke  DEVIOCALL2
        MOV     DS,CX           ; Restore DS
        POP     ES              ; Restore ES
        POP     BX
        MOV     CX,[CALLSCNT]   ; Number of sectors transferred
        POP     DI
        SUB     CX,DI
        NEG     CX              ; Number of sectors not transferred
        MOV     AX,[DEVCALL.REQSTAT]
        TEST    AX,STERR
        return
DskRead ENDP

SUBTTL SETUP -- SETUP A DISK READ OR WRITE FROM USER
PAGE
ASSUME  DS:DOSGROUP,ES:NOTHING

        procedure   SETUP,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DI point to FCB
;       DX:AX = Record position in file of disk transfer
;       CX = Record count
; Outputs:
;       DS = DOSGROUP
;       BL = fcb_DEVID from FCB
;       CX = No. of bytes to transfer  (0 = 64K)
;       [THISDPB] = Base of drive parameters
;       [RECCNT] = Record count
;       [RECPOS] = Record position in file
;       ES:DI Points to FCB
;       [THISFCB] = ES:DI
;       [NEXTADD] = Displacement of disk transfer within segment
;       [SECPOS] = Position of first sector
;       [BYTPOS] = Byte position in file
;       [BYTSECPOS] = Byte position in first sector
;       [CLUSNUM] = First cluster
;       [SECCLUSPOS] = Sector within first cluster
;       [DSKERR] = 0 (no errors yet)
;       [TRANS] = 0 (No transfers yet)
;       [THISDRV] = Physical drive unit number

        PUSH    AX
        MOV     AL,[DI]
        DEC     AL
        MOV     BYTE PTR [THISDRV],AL
        MOV     AL,[DI.fcb_DEVID]
        MOV     SI,[DI.fcb_RECSIZ]
        OR      SI,SI
        JNZ     HAVRECSIZ
        MOV     SI,128
        MOV     [DI.fcb_RECSIZ],SI
HAVRECSIZ:
        MOV     WORD PTR [THISFCB+2],DS
        PUSH    SS
        POP     DS              ; Set DS to DOSGROUP
ASSUME  DS:DOSGROUP
        MOV     WORD PTR [THISFCB],DI
        OR      AL,AL           ; Is it a device?
        JNS     NOTDEVICE
        XOR     AL,AL           ; Fake in drive 0 so we can get BP
NOTDEVICE:
        invoke  GETBP
        POP     AX
        JNC     CheckRecLen
        XOR     CX,CX
        MOV     BYTE PTR [DSKERR],4
        POP     BX
        return

CheckRecLen:
        CMP     SI,64           ; Check if highest byte of RECPOS is significant
        JB      SMALREC
        XOR     DH,DH           ; Ignore MSB if record >= 64 bytes
SMALREC:
        MOV     [RECCNT],CX
        MOV     WORD PTR [RECPOS],AX
        MOV     WORD PTR [RECPOS+2],DX
        MOV     BX,WORD PTR [DMAADD]
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
        ADC     DX,0            ; Ripple carry
        JNZ     EOFERR
        MOV     WORD PTR [BYTPOS+2],AX
        MOV     DX,AX
        MOV     AX,WORD PTR [BYTPOS]
        MOV     BX,ES:[BP.dpb_sector_size]
        CMP     DX,BX           ; See if divide will overflow
        JNC     EOFERR
        DIV     BX
        MOV     [SECPOS],AX
        MOV     [BYTSECPOS],DX
        MOV     DX,AX
        AND     AL,ES:[BP.dpb_cluster_mask]
        MOV     [SECCLUSPOS],AL
        MOV     AX,CX           ; Record count
        MOV     CL,ES:[BP.dpb_cluster_shift]
        SHR     DX,CL
        MOV     [CLUSNUM],DX
        MUL     SI              ; Multiply by bytes per record
        MOV     CX,AX
        ADD     AX,WORD PTR [DMAADD]     ; See if it will fit in one segment
        ADC     DX,0
        JZ      OK              ; Must be less than 64K
        MOV     AX,WORD PTR [DMAADD]
        NEG     AX              ; Amount of room left in segment
        JNZ     PARTSEG
        DEC     AX
PARTSEG:
        XOR     DX,DX
        DIV     SI              ; How many records will fit?
        MOV     [RECCNT],AX
        MUL     SI              ; Translate that back into bytes
        MOV     BYTE PTR [DSKERR],2      ; Flag that trimming took place
        MOV     CX,AX
        JCXZ    NOROOM
OK:
        LES     DI,[THISFCB]
        MOV     BL,ES:[DI.fcb_DEVID]
        return

EOFERR:
        MOV     BYTE PTR [DSKERR],1
        XOR     CX,CX
NOROOM:
        LES     DI,[THISFCB]
        POP     BX              ; Kill return address
        return
SETUP   ENDP

SUBTTL BREAKDOWN -- CUT A USER READ OR WRITE INTO PIECES
PAGE
        procedure   BREAKDOWN,near
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       CX = Length of disk transfer in bytes
;       ES:BP = Base of drive parameters
;       [BYTSECPOS] = Byte position witin first sector
; Outputs:
;       [BYTCNT1] = Bytes to transfer in first sector
;       [SECCNT] = No. of whole sectors to transfer
;       [BYTCNT2] = Bytes to transfer in last sector
; AX, BX, DX destroyed. No other registers affected.

        MOV     AX,[BYTSECPOS]
        MOV     BX,CX
        OR      AX,AX
        JZ      SAVFIR          ; Partial first sector?
        SUB     AX,ES:[BP.dpb_sector_size]
        NEG     AX              ; Max number of bytes left in first sector
        SUB     BX,AX           ; Subtract from total length
        JAE     SAVFIR
        ADD     AX,BX           ; Don't use all of the rest of the sector
        XOR     BX,BX           ; And no bytes are left
SAVFIR:
        MOV     [BYTCNT1],AX
        MOV     AX,BX
        XOR     DX,DX
        DIV     ES:[BP.dpb_sector_size]  ; How many whole sectors?
        MOV     [SECCNT],AX
        MOV     [BYTCNT2],DX    ; Bytes remaining for last sector
        OR      DX,[BYTCNT1]
        retnz                   ; NOT (BYTCNT1 = BYTCNT2 = 0)
        CMP     AX,1
        retnz
        MOV     AX,ES:[BP.dpb_sector_size]       ; Buffer EXACT one sector I/O
        MOV     [BYTCNT2],AX
        MOV     [SECCNT],DX             ; DX = 0
        return
BreakDown   ENDP

SUBTTL DISKREAD -- PERFORM USER DISK READ
PAGE
        procedure   DISKREAD,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       Outputs of SETUP
; Function:
;       Perform disk read
; Outputs:
;       DX:AX = Position of last record read
;       CX = No. of records read
;       ES:DI point to FCB
;       fcb_LSTCLUS, fcb_CLUSPOS fields in FCB set

        MOV     AX,ES:WORD PTR [DI.fcb_FILSIZ]
        MOV     BX,ES:WORD PTR [DI.fcb_FILSIZ+2]
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
        LES     BP,[THISDPB]
        CALL    BREAKDOWN
        MOV     CX,[CLUSNUM]
        invoke  FNDCLUS
        OR      CX,CX
        JZ      SHORT SKIPERR
RDERR:
        JMP     WRTERR
RDLASTJ:JMP     RDLAST
SETFCBJ2: JMP   SETFCB

SKIPERR:

        MOV     [LASTPOS],DX
        MOV     [CLUSNUM],BX
        CMP     [BYTCNT1],0
        JZ      RDMID
        invoke  BUFRD
RDMID:
        CMP     [SECCNT],0
        JZ      RDLASTJ
        invoke  NEXTSEC
        JC      SETFCBJ2
        MOV     BYTE PTR [TRANS],1      ; A transfer is taking place
ONSEC:
        MOV     DL,[SECCLUSPOS]
        MOV     CX,[SECCNT]
        MOV     BX,[CLUSNUM]
RDLP:
        invoke  OPTIMIZE
        PUSH    DI
        PUSH    AX
        PUSH    BX
        MOV     DS,WORD PTR [DMAADD+2]
ASSUME  DS:NOTHING
        PUSH    DX
        PUSH    CX
        CALL    DREAD
        POP     BX
        POP     DX
        ADD     BX,DX           ; Upper bound of read
        MOV     AL,ES:[BP.dpb_drive]
        invoke  SETVISIT
NXTBUF:                         ; Must see if one of these sectors is buffered
        MOV     [DI.VISIT],1    ; Mark as visited
        CMP     AL,[DI.BUFDRV]
        JNZ     DONXTBUF        ; Not for this drive
        CMP     [DI.BUFSECNO],DX
        JC      DONXTBUF        ; Below first sector
        CMP     [DI.BUFSECNO],BX
        JNC     DONXTBUF        ; Above last sector
        CMP     BYTE PTR [DI.BUFDIRTY],0
        JZ      CLBUFF                  ; Buffer is clean, so OK
; A sector has been read in when a dirty copy of it is in a buffer
; The buffered sector must now be read into the right place
        POP     AX              ; Recall transfer address
        PUSH    AX
        PUSH    DI              ; Save search environment
        PUSH    DX
        SUB     DX,[DI.BUFSECNO]   ; How far into transfer?
        NEG     DX
        MOV     SI,DI
        MOV     DI,AX
        MOV     AX,DX
        MOV     CX,ES:[BP.dpb_sector_size]
        MUL     CX
        ADD     DI,AX           ; Put the buffer here
        ADD     SI,BUFINSIZ
        SHR     CX,1
        PUSH    ES
        MOV     ES,WORD PTR [DMAADD+2]
        REP     MOVSW
        JNC     EVENMOV
        MOVSB
EVENMOV:
        POP     ES
        POP     DX
        POP     DI
        MOV     AL,ES:[BP.dpb_drive]
CLBUFF:
        invoke  SCANPLACE
DONXTBUF:
        invoke  SKIPVISIT
        JNZ     NXTBUF
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        POP     CX
        POP     CX
        POP     BX
        JCXZ    RDLAST
        CMP     BX,0FF8H
        JAE     SETFCB
        MOV     DL,0
        INC     [LASTPOS]       ; We'll be using next cluster
        JMP     RDLP

RDLAST:
        MOV     AX,[BYTCNT2]
        OR      AX,AX
        JZ      SETFCB
        MOV     [BYTCNT1],AX
        invoke  NEXTSEC
        JC      SETFCB
        MOV     [BYTSECPOS],0
        invoke  BUFRD

        entry   SETFCB
        LES     SI,[THISFCB]
        MOV     AX,[NEXTADD]
        MOV     DI,AX
        SUB     AX,WORD PTR [DMAADD]     ; Number of bytes transfered
        XOR     DX,DX
        MOV     CX,ES:[SI.fcb_RECSIZ]
        DIV     CX              ; Number of records
        CMP     AX,[RECCNT]     ; Check if all records transferred
        JZ      FULLREC
        MOV     BYTE PTR [DSKERR],1
        OR      DX,DX
        JZ      FULLREC         ; If remainder 0, then full record transfered
        MOV     BYTE PTR [DSKERR],3      ; Flag partial last record
        SUB     CX,DX           ; Bytes left in last record
        PUSH    ES
        MOV     ES,WORD PTR [DMAADD+2]
        XCHG    AX,BX           ; Save the record count temporarily
        XOR     AX,AX           ; Fill with zeros
        SHR     CX,1
        JNC     EVENFIL
        STOSB
EVENFIL:
        REP     STOSW
        XCHG    AX,BX           ; Restore record count to AX
        POP     ES
        INC     AX              ; Add last (partial) record to total
FULLREC:
        MOV     CX,AX
        MOV     DI,SI           ; ES:DI point to FCB
SETCLUS:
        TEST    ES:[DI].fcb_DEVID,-1
        JS      ADDREC                  ; don't set clisters if device
        MOV     AX,[CLUSNUM]
        AND     ES:[DI.fcb_LSTCLUS],0F000h  ; fcb_lstclus is packed with dir clus
        OR      ES:[DI.fcb_LSTCLUS],AX      ; drop in the correct part of fcb_lstclus
        MOV     AX,[LASTPOS]
        MOV     ES:[DI.fcb_CLUSPOS],AX
        entry   AddRec
        MOV     AX,WORD PTR [RECPOS]
        MOV     DX,WORD PTR [RECPOS+2]
        JCXZ    RET28           ; If no records read, don't change position
        DEC     CX
        ADD     AX,CX           ; Update current record position
        ADC     DX,0
        INC     CX
RET28:  return
DISKREAD    ENDP

SUBTTL DISKWRITE -- PERFORM USER DISK WRITE
PAGE
        procedure   DISKWRITE,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       Outputs of SETUP
; Function:
;       Perform disk write
; Outputs:
;       DX:AX = Position of last record written
;       CX = No. of records written
;       ES:DI point to FCB
;       fcb_LSTCLUS, fcb_CLUSPOS fields in FCB set

        AND     BL,3FH          ; Mark file as dirty
        MOV     ES:[DI.fcb_DEVID],BL
        LES     BP,[THISDPB]
        CALL    BREAKDOWN
        MOV     AX,WORD PTR [BYTPOS]
        MOV     DX,WORD PTR [BYTPOS+2]
        JCXZ    WRTEOFJ
        ADD     AX,CX
        ADC     DX,0            ; AX:DX=last byte accessed
        DIV     ES:[BP.dpb_sector_size]  ; AX=last sector accessed
        MOV     BX,AX           ; Save last full sector
        OR      DX,DX
        JNZ     CALCLUS
        DEC     AX              ; AX must be zero base indexed
CALCLUS:
        MOV     CL,ES:[BP.dpb_cluster_shift]
        SHR     AX,CL           ; Last cluster to be accessed
        PUSH    AX
        PUSH    DX              ; Save the size of the "tail"
        PUSH    ES
        LES     DI,[THISFCB]
        MOV     AX,ES:WORD PTR [DI.fcb_FILSIZ]
        MOV     DX,ES:WORD PTR [DI.fcb_FILSIZ+2]
        POP     ES
        DIV     ES:[BP.dpb_sector_size]
        MOV     CX,AX           ; Save last full sector of current file
        OR      DX,DX
        JZ      NORNDUP
        INC     AX              ; Round up if any remainder
NORNDUP:
        MOV     [VALSEC],AX     ; Number of sectors that have been written
        XOR     AX,AX
        MOV     WORD PTR [GROWCNT],AX
        MOV     WORD PTR [GROWCNT+2],AX
        POP     AX
        SUB     BX,CX           ; Number of full sectors
        JB      NOGROW
        JZ      TESTTAIL
        MOV     CX,DX
        XCHG    AX,BX
        MUL     ES:[BP.dpb_sector_size]  ; Bytes of full sector growth
        SUB     AX,CX           ; Take off current "tail"
        SBB     DX,0            ; 32-bit extension
        ADD     AX,BX           ; Add on new "tail"
        ADC     DX,0            ; ripple tim's head off
        JMP     SHORT SETGRW

HAVSTART:
        MOV     CX,AX
        invoke  SKPCLP
        JCXZ    DOWRTJ
        invoke  ALLOCATE
        JNC     DOWRTJ
WRTERR:
        XOR     CX,CX
        MOV     BYTE PTR [DSKERR],1
        MOV     AX,WORD PTR [RECPOS]
        MOV     DX,WORD PTR [RECPOS+2]
        LES     DI,[THISFCB]
        return

DOWRTJ: JMP     DOWRT

WRTEOFJ:
        JMP     WRTEOF

TESTTAIL:
        SUB     AX,DX
        JBE     NOGROW
        XOR     DX,DX
SETGRW:
        MOV     WORD PTR [GROWCNT],AX
        MOV     WORD PTR [GROWCNT+2],DX
NOGROW:
        POP     AX
        MOV     CX,[CLUSNUM]    ; First cluster accessed
        invoke  FNDCLUS
        MOV     [CLUSNUM],BX
        MOV     [LASTPOS],DX
        SUB     AX,DX           ; Last cluster minus current cluster
        JZ      DOWRT           ; If we have last clus, we must have first
        JCXZ    HAVSTART        ; See if no more data
        PUSH    CX              ; No. of clusters short of first
        MOV     CX,AX
        invoke  ALLOCATE
        POP     AX
        JC      WRTERR
        MOV     CX,AX
        MOV     DX,[LASTPOS]
        INC     DX
        DEC     CX
        JZ      NOSKIP
        invoke  SKPCLP
NOSKIP:
        MOV     [CLUSNUM],BX
        MOV     [LASTPOS],DX
DOWRT:
        CMP     [BYTCNT1],0
        JZ      WRTMID
        MOV     BX,[CLUSNUM]
        invoke  BUFWRT
WRTMID:
        MOV     AX,[SECCNT]
        OR      AX,AX
        JZ      WRTLAST
        ADD     [SECPOS],AX
        invoke  NEXTSEC
        MOV     BYTE PTR [TRANS],1       ; A transfer is taking place
        MOV     DL,[SECCLUSPOS]
        MOV     BX,[CLUSNUM]
        MOV     CX,[SECCNT]
WRTLP:
        invoke  OPTIMIZE
        PUSH    DI
        PUSH    AX
        PUSH    DX
        PUSH    BX
        MOV     AL,ES:[BP.dpb_drive]
        MOV     BX,CX
        ADD     BX,DX           ; Upper bound of write
        invoke  SETVISIT
ASSUME  DS:NOTHING
NEXTBUFF:                       ; Search for buffers
        MOV     [DI.VISIT],1    ; Mark as visited
        CMP     AL,[DI.BUFDRV]
        JNZ     DONEXTBUFF      ; Not for this drive
        CMP     [DI.BUFSECNO],DX
        JC      DONEXTBUFF      ; Buffer is not in range of write
        CMP     [DI.BUFSECNO],BX
        JNC     DONEXTBUFF      ; Buffer is not in range of write
        MOV     WORD PTR [DI.BUFDRV],00FFH    ; Free the buffer, it is being over written
        invoke  SCANPLACE
DONEXTBUFF:
        invoke  SKIPVISIT
        JNZ     NEXTBUFF
        POP     BX
        POP     DX
        MOV     DS,WORD PTR [DMAADD+2]
        CALL    DWRITE
        POP     CX
        POP     BX
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        JCXZ    WRTLAST
        MOV     DL,0
        INC     [LASTPOS]       ; We'll be using next cluster
        JMP     SHORT WRTLP

WRTERRJ: JMP     WRTERR

WRTLAST:
        MOV     AX,[BYTCNT2]
        OR      AX,AX
        JZ      FINWRT
        MOV     [BYTCNT1],AX
        invoke  NEXTSEC
        MOV     [BYTSECPOS],0
        invoke  BUFWRT
FINWRT:
        LES     DI,[THISFCB]
        MOV     AX,WORD PTR [GROWCNT]
        MOV     CX,WORD PTR [GROWCNT+2]
        OR      AX,AX
        JNZ     UPDATE_size
        OR      CX,CX
        JZ      SAMSIZ
Update_size:
        ADD     WORD PTR ES:[DI.fcb_FILSIZ],AX
        ADC     WORD PTR ES:[DI.fcb_FILSIZ+2],CX
SAMSIZ:
        MOV     CX,[RECCNT]
        JMP     SETCLUS

WRTEOF:
        MOV     CX,AX
        OR      CX,DX
        JZ      KILLFIL
        SUB     AX,1
        SBB     DX,0
        DIV     ES:[BP.dpb_sector_size]
        MOV     CL,ES:[BP.dpb_cluster_shift]
        SHR     AX,CL
        MOV     CX,AX
        invoke  FNDCLUS
        JCXZ    RELFILE
        invoke  ALLOCATE
        JC      WRTERRJ
UPDATE:
        LES     DI,[THISFCB]
        MOV     AX,WORD PTR [BYTPOS]
        MOV     ES:WORD PTR [DI.fcb_FILSIZ],AX
        MOV     AX,WORD PTR [BYTPOS+2]
        MOV     ES:WORD PTR [DI.fcb_FILSIZ+2],AX
        XOR     CX,CX
        JMP     ADDREC

RELFILE:
        MOV     DX,0FFFH
        invoke  RELBLKS
        JMP     SHORT UPDATE

KILLFIL:
        XOR     BX,BX
        PUSH    ES
        LES     DI,[THISFCB]
        MOV     ES:[DI.fcb_CLUSPOS],BX
        XCHG    BX,ES:[DI.fcb_FIRCLUS]
        AND     ES:[DI.fcb_LSTCLUS],0F000H
        POP     ES
        OR      BX,BX
        JZ      UPDATE
        invoke  RELEASE
        JMP     SHORT UPDATE
DISKWRITE   ENDP
do_ext

CODE    ENDS
    END
                                                                                                                             