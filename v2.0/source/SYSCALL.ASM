;
; system call entry points MSDOS
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


        i_need  YEAR,WORD
        i_need  DAY,BYTE
        i_need  WeekDay,BYTE
        i_need  TimeBuf,6
        i_need  BCLOCK,DWORD
        i_need  DskErr,BYTE
        i_need  Attrib,BYTE
        i_need  Name1,BYTE
        i_need  Name2,BYTE
        i_need  Name3,BYTE
        i_need  DelAll,BYTE
        i_need  ThisDPB,DWORD
        i_need  CurBuf,DWORD
        i_need  LastEnt,WORD
        i_need  ThisDrv,BYTE
        i_need  DirStart,WORD
        i_need  DevPt,DWORD
        i_need  Creating,BYTE
        i_need  VolID,BYTE
        i_need  FoundDel,BYTE

SUBTTL DATE AND TIME - SYSTEM CALLS 42,43,44,45; S/G DATE,TIME
PAGE
        procedure   $GET_DATE,NEAR   ;System call 42
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       None
; Function:
;       Return current date
; Returns:
;       Date in CX:DX

        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        invoke  READTIME        ;Check for rollover to next day
        MOV     AX,[YEAR]
        MOV     BX,WORD PTR [DAY]
        invoke  get_user_stack           ;Get pointer to user registers
ASSUME  DS:NOTHING
        MOV     [SI.user_DX],BX  ;DH=month, DL=day
        ADD     AX,1980         ;Put bias back
        MOV     [SI.user_CX],AX  ;CX=year
        MOV     AL,BYTE PTR [WEEKDAY]
        RET
$GET_DATE ENDP

        procedure   $SET_DATE,NEAR   ;System call 43
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       CX:DX valid date
; Function:
;       Set current date
; Returns:
;       AL = -1 date bad, = 0 OK

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
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        invoke  DODATE
RET24:  RET
$SET_DATE ENDP

        procedure   $GET_TIME,NEAR   ;System call 44
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       None
; Function:
;       Get current time
; Returns:
;       Time in CX:DX

        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        invoke  READTIME
        invoke  get_user_stack           ;Get pointer to user registers
        MOV     [SI.user_DX],DX
        MOV     [SI.user_CX],CX
        XOR     AL,AL
RET26:  RET
$GET_TIME ENDP

        procedure   $SET_TIME,NEAR   ;System call 45
;Time is in CX:DX in hours, minutes, seconds, 1/100 sec.
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       CX:DX = Time
; Function:
;       Set time
; Returns:
;       AL = -1 time bad, = 0 OK

        MOV     AL,-1           ;Flag in case of error
        CMP     CH,24           ;Check hours
        JAE     RET26
        CMP     CL,60           ;Check minutes
        JAE     RET26
        CMP     DH,60           ;Check seconds
        JAE     RET26
        CMP     DL,100          ;Check 1/100's
        JAE     RET26
        PUSH    CX
        PUSH    DX
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     BX,OFFSET DOSGROUP:TIMEBUF
        MOV     CX,6
        XOR     DX,DX
        MOV     AX,DX
        PUSH    BX
        invoke  SETREAD
ASSUME  ES:DOSGROUP
        PUSH    DS
        LDS     SI,[BCLOCK]
ASSUME  DS:NOTHING
        invoke  DEVIOCALL2      ;Get correct day count
        POP     DS
ASSUME  DS:DOSGROUP
        POP     BX
        invoke  SETWRITE
        POP     WORD PTR [TIMEBUF+4]
        POP     WORD PTR [TIMEBUF+2]
        LDS     SI,[BCLOCK]
ASSUME  DS:NOTHING
        invoke  DEVIOCALL2      ;Set the time
        XOR     AL,AL
        RET
$SET_TIME ENDP

SUBTTL DISK R/W ROUTINES
PAGE
        procedure   $FCB_SEQ_READ,NEAR   ; System call 20
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX Points to openned FCB
; Function:
;       Read next record from file to disk transfer address
; Returns:
;       AL = 1 EOF record is empty
;       AL = 3 EOF record is partial zero filled
;       AL = 2 No room at disk transfer address
;       AL = 0 All OK

        invoke  GETREC
        invoke  LOAD
        JMP     SHORT FINSEQ

    entry   $FCB_SEQ_WRITE              ; System call 21
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX Points to openned FCB
; Function:
;       Write next record to file from disk transfer address
; Returns:
;       AL = 1 Disk full
;       AL = 2 No room in disk transfer segment
;       AL = 0 All OK

        invoke  GETREC
        invoke  STORE
FINSEQ:
        JCXZ    SETNREX
        ADD     AX,1
        ADC     DX,0
        JMP     SHORT SETNREX

    entry   $FCB_RANDOM_READ                ; System call 33
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX Points to openned FCB
; Function:
;       Read record addressed by random record field from file to
;         disk transfer address
; Returns:
;       AL = 1 EOF record is empty
;       AL = 3 EOF record is partial zero filled
;       AL = 2 No room at disk transfer address
;       AL = 0 All OK

        invoke  GETRRPOS1
        invoke  LOAD
        JMP     SHORT FINRND

    entry   $FCB_RANDOM_WRITE               ; System call 34
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX Points to openned FCB
; Function:
;       Write record addressed by random record field to file from
;         disk transfer address
; Returns:
;       AL = 1 Disk full
;       AL = 2 No room in disk transfer segment
;       AL = 0 All OK

        invoke  GETRRPOS1
        invoke  STORE
        JMP     SHORT FINRND

    entry   $FCB_RANDOM_READ_BLOCK          ; System call 39
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX Points to openned FCB
;       CX = Record count
; Function:
;       Read CX records starting at random record field from file
;         to disk transfer address
; Returns:
;       AL = 1 EOF record is empty
;       AL = 3 EOF record is partial zero filled
;       AL = 2 No room at disk transfer address
;       AL = 0 All OK
;       CX = Actual number of records read

        invoke  GETRRPOS
        invoke  LOAD
        JMP     SHORT FINBLK

    entry   $FCB_RANDOM_WRITE_BLOCK         ; System call 40
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX Points to openned FCB
;       CX = Record count
; Function:
;       Write CX records starting at random record field to file
;         from disk transfer address
;       If CX = 0 File is set to length determined from random record field
; Returns:
;       AL = 1 Disk full
;       AL = 2 No room in disk transfer segment
;       AL = 0 All OK
;       CX = Actual number of records written

        invoke  GETRRPOS
        invoke  STORE
FINBLK:
        invoke  get_user_stack
        MOV     [SI.user_CX],CX
        entry   FINNOSAV
        JCXZ    FINRND
        ADD     AX,1
        ADC     DX,0
FINRND:
        MOV     WORD PTR ES:[DI.fcb_RR],AX
        MOV     ES:[DI.fcb_RR+2],DL
        OR      DH,DH
        JZ      SETNREX
        MOV     ES:[DI.fcb_RR+3],DH ; Save 4 byte of RECPOS only if significant
SETNREX:
        MOV     CX,AX
        AND     AL,7FH
        MOV     ES:[DI.fcb_NR],AL
        AND     CL,80H
        SHL     CX,1
        RCL     DX,1
        MOV     AL,CH
        MOV     AH,DL
        MOV     ES:[DI.fcb_EXTENT],AX
        MOV     AL,BYTE PTR [DSKERR]
RET4:
        RET
$FCB_SEQ_READ   ENDP

SUBTTL $FCB_DELETE -- SYSTEM CALL 19
PAGE
        procedure   $FCB_DELETE,NEAR   ; System call 19
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX point to unopened FCB
; Function:
;       Delete all matching entries
; Returns:
;       AL = -1 if no entries matched, otherwise 0

        invoke  MOVNAME
ASSUME  ES:DOSGROUP
        MOV     AL,-1
        MOV     BYTE PTR [FoundDel],AL
        JC      RET4
        MOV     AL,BYTE PTR [ATTRIB]
        AND     AL,attr_hidden+attr_system+attr_directory+attr_volume_id+attr_read_only
                                        ; Look only at hidden bits
        CMP     AL,attr_hidden+attr_system+attr_directory+attr_volume_id+attr_read_only
                                        ; All must be set
        JNZ     NOTALL
        MOV     CX,11
        MOV     AL,"?"
        MOV     DI,OFFSET DOSGROUP:NAME1
        REPE    SCASB                   ; See if name is *.*
        JNZ     NOTALL
        MOV     BYTE PTR [DELALL],0           ; DEL *.* - flag deleting all
NOTALL:
        invoke  FINDNAME
ASSUME  DS:DOSGROUP
        MOV     AL,-1
        JC      RET4
        OR      AH,AH           ; Check if device name
        JS      RET4            ; Can't delete I/O devices
DELFILE:
        LES     BP,[THISDPB]
        MOV     AH,BYTE PTR [DELALL]
        PUSH    DS
        LDS     DI,[CURBUF]
ASSUME  DS:NOTHING
        TEST    [Attrib],attr_read_only ; are we deleting RO files too?
        JNZ     DoDelete            ; yes
        TEST    DS:[BX.dir_attr],attr_read_only
        JZ      DoDelete            ; not read only
        POP     DS
        JMP     SHORT DelNxt
DoDelete:
        MOV     BYTE PTR [FoundDel],0
        MOV     [DI.BUFDIRTY],1
        MOV     BYTE PTR [BX],AH
        MOV     BX,[SI]
        POP     DS
ASSUME  DS:DOSGROUP
        OR      BX,BX
        JZ      DELNXT
        CMP     BX,ES:[BP.dpb_max_cluster]
        JA      DELNXT
        invoke  RELEASE
DELNXT:
        invoke  GETENTRY                        ; Registers need to be reset
        invoke  NEXTENT
        JNC     DELFILE
        CALL    FLUSHRET1
        MOV     AL,BYTE PTR [FoundDel]
        RET

$FCB_DELETE  ENDP

SUBTTL $FCB_RENAME -- SYSTEM CALL 23; RENAME FILES
PAGE
ERRETJ: JMP     ERRET

        procedure   $FCB_RENAME,NEAR   ; System call 23
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX point to a modified FCB (DS:DX+11H points to destination
;        name)
; Function:
;       Rename all matching entries to indicated name
; Returns:
;       AL = -1 if no entries matched, otherwise 0

        invoke  MOVNAME
ASSUME  ES:DOSGROUP
        JC      ERRETJ
        ADD     SI,5
        MOV     DI,OFFSET DOSGROUP:NAME2
        invoke  LODNAME
        JC      ERRETJ          ; Report error if second name invalid
        invoke  FINDNAME
ASSUME  DS:DOSGROUP
        JC      ERRETJ
        OR      AH,AH           ; Check if I/O device name
        JS      ERRETJ          ; If so, can't rename it
        MOV     SI,OFFSET DOSGROUP:NAME1
        MOV     DI,OFFSET DOSGROUP:NAME3
        MOV     CX,13
        REP     MOVSB           ; Copy name to search for --include attribute byte
RENFIL:
        MOV     DI,OFFSET DOSGROUP:NAME1
        MOV     SI,OFFSET DOSGROUP:NAME2
        MOV     CX,11
NEWNAM:
        LODSB
        CMP     AL,"?"
        JNZ     NOCHG
        PUSH    DS
        MOV     DS,WORD PTR [CURBUF+2]
        MOV     AL,[BX]
        POP     DS
NOCHG:
        STOSB
        INC     BX
        LOOP    NEWNAM
        INC     DI
        MOV     BYTE PTR [DI],attr_all  ;Sets ATTRIB
                                ; Stop duplicates with any attributes
        invoke  DEVNAME         ; Check if giving it a device name
        JNC     RENERR
        XOR     AX,AX
        PUSH    [LASTENT]
        invoke  FINDENTRY       ; See if new name already exists
        POP     AX
        JNC     RENERR                  ; Error if found
        LES     BP,[THISDPB]
        invoke  GETENT                  ; Re-read matching entry
        MOV     DI,BX           ; Leave BX,DX until call to NEXTENT
        MOV     ES,WORD PTR [CURBUF+2]
        MOV     SI,OFFSET DOSGROUP:NAME1
        MOV     CX,11
        REP     MOVSB                   ; Replace old name with new one
        MOV     DI,WORD PTR [CURBUF]
        MOV     ES:[DI.BUFDIRTY],1      ; Directory changed
        PUSH    SS
        POP     ES
        MOV     SI,OFFSET DOSGROUP:NAME3
        MOV     DI,OFFSET DOSGROUP:NAME1
        MOV     CX,13                   ; Include attribute byte
        REP     MOVSB                   ; Copy name back into search buffer
        invoke  NEXTENT
        JNC     RENFIL
        JMP     FLUSHRET1

RENERR:
        CALL    FLUSHRET1
ERRET:
        MOV     AL,-1
        RET
$FCB_RENAME  ENDP

SUBTTL $FCB_OPEN -- SYSTEM CALL 15; OPEN A FILE
PAGE
        procedure   $FCB_OPEN,NEAR   ; System call 15
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX point to an unopened FCB
; Function:
;       Open indicated file and fill in FCB
; Returns:
;       AL = -1 if no entries matched, otherwise 0
; FOR INTERNAL USE
;       [CURBUF+2]:SI and [CURBUF+2]:BX Preserved

        invoke  GETFILE
ASSUME  DS:DOSGROUP,ES:NOTHING

    entry   DOOPEN

; Enter here to perform $FCB_OPEN on file already found
; in directory. AH=device ID number, DS=CS, BX points to directory
; entry in [CURBUF], SI points to First Cluster field, and
; ES:DI point to the FCB to be opened. This entry point
; is used by $FCB_CREATE.
        JC      ERRET
        PUSH    SI
        PUSH    AX              ; Save I/O driver number
        XOR     AL,AL
        OR      AH,AH
        JS      OPENDEV
        MOV     AL,[THISDRV]
        MOV     DS,WORD PTR [CURBUF+2]
ASSUME  DS:NOTHING
        INC     AX
OPENDEV:
        STOSB
        XOR     AX,AX
IF ZEROEXT
        ADD     DI,11
        STOSW                   ; Zero low byte of extent field if ZERPEXT only
ELSE
        ADD     DI,12           ; Point to high half of CURRENT BLOCK field
        STOSB                   ; Set it to zero (CP/M programs set low byte)
ENDIF
        MOV     AL,128          ; Default record size
        STOSW                   ; Set record size
        LODSW                   ; Get starting cluster
        MOV     DX,AX           ; Save it for the moment
        MOVSW                   ; Transfer size to FCB
        MOVSW
        MOV     AX,[SI-8]       ; Get date
        STOSW                   ; Save date in FCB
        MOV     AX,[SI-10]      ; Get time
        STOSW                   ; Save it in FCB
        POP     AX              ; Restore I/O driver number
        POP     SI
        MOV     AL,AH
        OR      AL,40H          ; Not dirty
        STOSB
        JS      SAVDEVPT        ; If device, go save pointer to it
        MOV     AX,DX           ; Restore starting cluster
        STOSW                   ; first cluster
        PUSH    AX                      ; save cluster
        XOR     AX,AX
        STOSW                           ; clus pos
        POP     AX                      ; last cluster
        STOSB
        MOV     AL,AH
        MOV     AH,BYTE PTR [DIRSTART]
        PUSH    CX
        MOV     CL,4
        SHL     AH,CL
        OR      AL,AH
        STOSB
        MOV     AX,[DIRSTART]
        MOV     CL,4
        SHL     AX,CL
        POP     CX
        MOV     AL,AH
        STOSB
OPEN_RET:
        XOR     AX,AX
        RET

SAVDEVPT:
ASSUME  DS:DOSGROUP
        LDS     AX,[DEVPT]
ASSUME  DS:NOTHING
        STOSW
        MOV     ES:[DI],DS
        JMP     SHORT OPEN_RET
$FCB_OPEN    ENDP

SUBTTL $FCB_CLOSE -- SYSTEM CALL 16; CLOSE FILE
PAGE
        procedure   $FCB_CLOSE,NEAR   ; System call 16
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX point to an opened FCB
; Function:
;       Close the indicated file
; Returns:
;       AL = -1 if disk has been changed, otherwise 0

        MOV     DI,DX
        CMP     BYTE PTR [DI],-1        ; Check for extended FCB
        JNZ     NORMFCB3
        ADD     DI,7
NORMFCB3:
        TEST    [DI.fcb_DEVID],devid_file_clean+devid_device
                                        ; Allow only dirty files
        JNZ     OKRET1                  ; can't close I/O device or not written
        invoke  MOVNAMENOSET
        JC      BADCLOSE                ; Bad file name
        entry   FCB_CLOSE_INNER
        PUSH    DX
        PUSH    DS
        MOV     SI,DX
        MOV     BX,[SI.fcb_LSTCLUS+1]
        MOV     CL,4
        SHR     BX,CL
        PUSH    BX
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        invoke  FATREAD
        POP     BX
        invoke  SETDIRSRCH
        invoke  FINDENTRY
        POP     ES
        POP     DI
        JC      BADCLOSE
        LDS     BX,[CURBUF]
ASSUME  DS:NOTHING

        ; note that SI points to dir_first...

        OR      BYTE PTR [SI-dir_first+dir_attr],attr_archive
        MOV     CX,ES:[DI.fcb_FIRCLUS]
        MOV     [SI-dir_first+dir_first],CX
        MOV     DX,ES:WORD PTR [DI.fcb_FILSIZ]
        MOV     [SI-dir_first+dir_size_l],DX
        MOV     DX,ES:WORD PTR [DI.fcb_FILSIZ+2]
        MOV     [SI-dir_first+dir_size_h],DX
        MOV     DX,ES:[DI.fcb_FDATE]
        MOV     [SI-dir_first+dir_date],DX
        MOV     DX,ES:[DI.fcb_FTIME]
        MOV     [SI-dir_first+dir_time],DX
        MOV     [BX.BUFDIRTY],1
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
FLUSHRET1:
        LES     BP,[THISDPB]
        MOV     AL,ES:[BP.dpb_drive]
        invoke  FLUSHBUF
OKRET1:
        XOR     AL,AL
        RET

BADCLOSE:
        MOV     AL,-1
        RET
$FCB_CLOSE   ENDP

SUBTTL $FCB_CREATE -- SYSTEM CALL 22; MAKE AND OPEN A NEW FILE
PAGE
        procedure   $FCB_CREATE,NEAR   ; System call 22
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX point to an unopened FCB
; Function:
;       If file does not exist, create it and open it
;       If file exists, free up its contents and open the file
; Returns:
;       AL = -1 if file cannot be created, otherwise 0

        invoke  MOVNAME
ASSUME  ES:DOSGROUP
        JC      ERRET3
        MOV     DI,OFFSET DOSGROUP:NAME1
        MOV     CX,11
        MOV     AL,"?"
        REPNE   SCASB
        JZ      ERRET3
        MOV     BYTE PTR [CREATING],-1
        PUSH    DX
        PUSH    DS
        invoke  FINDNAME
ASSUME  DS:DOSGROUP
NWENTY:
        LES     BP,[THISDPB]
ASSUME  ES:NOTHING
        JNC     EXISTENT
        invoke  BUILDDIR
        JC      ERRPOP
        invoke  GETENT          ; Point at that free entry
        JMP     SHORT FREESPOT
ERRPOP:
        POP     DS
        POP     DX
ASSUME  DS:NOTHING
ERRET3:
        JMP     SHORT BADCLOSE

        entry   NEWENTRY
        POP     DX      ; Return address
        POP     ES      ; ES
        POP     CX      ; DI
        PUSH    DX
        PUSH    CX
        PUSH    ES
        JMP     NWENTY

EXISTENT:
ASSUME  DS:DOSGROUP
        JNZ     ERRPOP          ; Error if attributes don't match
        OR      AH,AH           ; Check if file is I/O device
        JS      OPENJMP         ; If so, no action
        PUSH    DS
        LDS     DI,[CURBUF]
ASSUME  DS:NOTHING
        MOV     CX,[SI]         ; Get pointer to clusters
        MOV     SI,[DI.BUFSECNO]
        POP     DS
ASSUME  DS:DOSGROUP
        JCXZ    FREESPOT
        CMP     CX,ES:[BP.dpb_max_cluster]
        JA      FREESPOT
        SUB     BX,DI
        PUSH    BX
        PUSH    SI              ; Save sector number
        MOV     BX,CX
        invoke  RELEASE         ; Free any data already allocated
        POP     DX
        XOR     AL,AL
        invoke  GETBUFFR
        POP     BX
        ADD     BX,WORD PTR [CURBUF]
FREESPOT:
        TEST    BYTE PTR [ATTRIB],attr_volume_id
        JZ      NOTVOLID
        CMP     BYTE PTR [VOLID],0
        JNZ     ERRPOP          ; Can't create a second volume ID
NOTVOLID:
        MOV     ES,WORD PTR [CURBUF+2]
        MOV     DI,BX
        MOV     SI,OFFSET DOSGROUP:NAME1
        MOV     CX,5
        MOVSB
        REP     MOVSW
        MOV     AL,[ATTRIB]
        STOSB
        MOV     CL,5
        XOR     AX,AX
        REP     STOSW
        invoke  DATE16
        XCHG    AX,DX
        STOSW
        XCHG    AX,DX
        STOSW
        XOR     AX,AX
        PUSH    DI
        STOSW
        STOSW
        STOSW
        MOV     SI,WORD PTR [CURBUF]
        MOV     ES:[SI.BUFDIRTY],1
        LES     BP,[THISDPB]
        MOV     AL,ES:[BP.dpb_drive]
        PUSH    AX
        PUSH    BX
        invoke  FLUSHBUF
        POP     BX
        POP     AX
        POP     SI
        MOV     AH,AL             ; Get I/O driver number back
OPENJMP:
        CLC                     ; Clear carry so OPEN won't fail
        POP     ES
        POP     DI
ASSUME  ES:NOTHING
        JMP     DOOPEN
$FCB_CREATE  ENDP

do_ext

CODE    ENDS
    END

