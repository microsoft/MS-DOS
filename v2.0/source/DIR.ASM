;
; Directory routines for MSDOS
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

TITLE   DIR - Directory and path cracking
NAME    Dir

        i_need  NoSetDir,BYTE
        i_need  EntFree,WORD
        i_need  DirStart,WORD
        i_need  LastEnt,WORD
        i_need  ClusNum,WORD
        i_need  CurBuf,DWORD
        i_need  ThisFCB,DWORD
        i_need  Attrib,BYTE
        i_need  DelAll,BYTE
        i_need  VolID,BYTE
        i_need  Name1,BYTE
        i_need  ThisDPB,DWORD
        i_need  EntLast,WORD
        i_need  Creating,BYTE
        i_need  SecClusPos,BYTE
        i_need  ClusFac,BYTE
        i_need  NxtClusNum,WORD
        i_need  DirSec,WORD
        i_need  DriveSpec,BYTE
        i_need  Device_availability,BYTE
        i_need  RootStart,BYTE
        i_need  DevString,BYTE
        i_need  DevStrLen,BYTE

SUBTTL BUILDDIR,NEWDIR -- ALLOCATE DIRECTORIES
PAGE
    procedure   BUILDDIR,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       ES:BP Points to DPB
;       [THISFCB] Set if using NEWDIR entry point
;       [LASTENT] current last valid entry number in directory if no free
;               entries
; Function:
;       Grow directory if no free entries and not root
; Outputs:
;       CARRY SET IF FAILURE
;       ELSE
;          AX entry number of new entry
;          If a new dir [DIRSTART],[CLUSFAC],[CLUSNUM],[DIRSEC] set
;               AX = first entry of new dir
;       GETENT should be called to set [LASTENT]

        MOV     AX,[ENTFREE]
        CMP     AX,-1
        JNZ     GOTRET
        CMP     [DIRSTART],0
        JNZ     NEWDIR
        STC
        return                  ; Can't grow root

        entry   NEWDIR
        MOV     BX,[DIRSTART]
        OR      BX,BX
        JZ      NULLDIR
        invoke  GETEOF
NULLDIR:
        MOV     CX,1
        invoke  ALLOCATE
        retc
        MOV     DX,[DIRSTART]
        OR      DX,DX
        JNZ     ADDINGDIR
        call    SETDIRSRCH
        MOV     [LASTENT],-1
        JMP     SHORT GOTDIRREC
ADDINGDIR:
        CMP     [CLUSNUM],0FF8H
        JB      NOTFIRSTGROW
        MOV     [CLUSNUM],BX
NOTFIRSTGROW:
        MOV     DX,BX
        XOR     BL,BL
        invoke  FIGREC
GOTDIRREC:
        MOV     CL,ES:[BP.dpb_cluster_mask]
        INC     CL
        XOR     CH,CH
ZERODIR:
        PUSH    CX
        MOV     AL,0FFH
        invoke  GETBUFFR
        MOV     CX,ES:[BP.dpb_sector_size]
        PUSH    ES
        LES     DI,[CURBUF]
        PUSH    DI
        ADD     DI,BUFINSIZ
        XOR     AX,AX
        SHR     CX,1
        REP     STOSW
        JNC     EVENZ
        STOSB
EVENZ:
        POP     DI
        INC     AL
        MOV     ES:[DI.BUFDIRTY],AL
        POP     ES
        POP     CX
        INC     DX
        LOOP    ZERODIR
        MOV     AX,[LASTENT]
        INC     AX
GOTRET:
        CLC
        return

BUILDDIR    ENDP

;
; set up a . and .. directory entry for a directory
;
        procedure   SETDOTENT,NEAR
ASSUME  DS:DOSGROUP
        MOV     CX,4
        MOV     AX,2020H
        REP     STOSW
        STOSB
        MOV     SI,WORD PTR [THISFCB]
        MOV     AL,attr_directory
        STOSB
        ADD     DI,10
        MOV     AX,[SI.fcb_FTIME]
        STOSW
        MOV     AX,[SI.fcb_FDATE]
        STOSW
        MOV     AX,DX
        STOSW
        XOR     AX,AX
        STOSW
        STOSW
        return
SETDOTENT   ENDP

SUBTTL GETFILE, GETNAME, FINDNAME -- LOOK FOR A FILE
PAGE
        procedure   SEARCH,near

        entry   GETFILE
ASSUME  DS:NOTHING,ES:NOTHING
; Same as GETNAME except ES:DI points to FCB on successful return
        invoke  MOVNAME
        retc
        PUSH    DX
        PUSH    DS
        CALL    FINDNAME
        POP     ES
        POP     DI
        return

        entry   GETNAME
ASSUME  DS:NOTHING,ES:NOTHING

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
;       AH = Device ID (bit 7 set if not disk)
;       [THISDPB] = Base of drive parameters
;       DS = DOSGROUP
;       ES = DOSGROUP
;       [CURBUF+2]:BX = Pointer into directory buffer
;       [CURBUF+2]:SI = Pointer to First Cluster field in directory entry
;       [CURBUF] has directory record with match
;       [NAME1] has file name
; All other registers destroyed.

        invoke  MOVNAME
ASSUME  ES:DOSGROUP
        retc                    ; Bad file name?

        entry   FINDNAME
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        invoke  DEVNAME
        JC      FindEntry
        invoke  BUILDFCB
        return
ASSUME  ES:NOTHING

; NOTE THE FALL THROUGH

SUBTTL FINDENTRY -- LOOK FOR AN ENTRY
PAGE
        entry   FindEntry
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       [THISDPB] set
;       [SECCLUSPOS] = 0
;       [DIRSEC] = Starting directory sector number
;       [CLUSNUM] = Next cluster of directory
;       [CLUSFAC] = Sectors/Cluster
;       [NAME1] = Name to look for
; Function:
;       Find file name in disk directory.
;       "?" matches any character.
; Outputs:
;       Carry set if name not found
;       ELSE
;       Zero set if attributes match (always except when creating)
;       AH = Device ID (bit 7 set if not disk)
;       [THISDPB] = Base of drive parameters
;       DS = DOSGROUP
;       ES = DOSGROUP
;       [CURBUF+2]:BX = Pointer into directory buffer
;       [CURBUF+2]:SI = Pointer to First Cluster field in directory entry
;       [CURBUF] has directory record with match
;       [NAME1] has file name
;       [LASTENT] is entry number of the entry
; All other registers destroyed.

        CALL    STARTSRCH
        CMP     BYTE PTR [ATTRIB],attr_volume_id
                                ; Looking for vol ID only ?
        JNZ     NOTVOLSRCH      ; No
        CALL    SETROOTSRCH     ; Yes force search of root
NOTVOLSRCH:
        CALL    GETENTRY
        entry   Srch
        PUSH    DS
        MOV     DS,WORD PTR [CURBUF+2]
ASSUME  DS:NOTHING
        MOV     AH,BYTE PTR [BX]
        OR      AH,AH                   ; End of directory?
        JZ      FREE
        CMP     AH,BYTE PTR [DELALL]             ; Free entry?
        JZ      FREE
        TEST    BYTE PTR [BX+11],attr_volume_id
                                        ; Volume ID file?
        JZ      CHKFNAM                 ; NO
        INC     BYTE PTR [VOLID]
CHKFNAM:
        MOV     SI,BX
        PUSH    SS
        POP     ES
ASSUME  ES:DOSGROUP
        MOV     DI,OFFSET DOSGROUP:NAME1
        MOV     CX,11
WILDCRD:
        REPE    CMPSB
        JZ      FOUND
        CMP     BYTE PTR ES:[DI-1],"?"
        JZ      WILDCRD
        POP     DS
ASSUME  DS:DOSGROUP
        entry   NEXTENT
        LES     BP,[THISDPB]
ASSUME  ES:NOTHING
        CALL    NEXTENTRY
        JNC     SRCH
        JMP     SHORT SETESRET

FREE:
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     CX,[LASTENT]
        CMP     CX,[ENTFREE]
        JAE     TSTALL
        MOV     [ENTFREE],CX
TSTALL:
        CMP     AH,BYTE PTR [DELALL]             ; At end of directory?
        JZ      NEXTENT                 ; No - continue search
        MOV     [ENTLAST],CX
        STC
        JMP     SHORT SETESRET

FOUND:
;
; We have a file with a matching name.  We must now consider
; the attributes:
; ATTRIB        Action
; ------        ------
; Volume_ID     Is Volume_ID in test?
; Otherwise     If no create then Is ATTRIB+extra superset of test?
;               If create then Is ATTRIB equal to test?
;
        MOV     CH,[SI]                 ; Attributes of file
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     AH,BYTE PTR [ATTRIB]    ; Attributes of search
        TEST    CH,attr_volume_id       ; Volume ID file?
        JZ      check_one_volume_id     ; Nope check other attributes
        TEST    AH,attr_volume_id       ; Can we find Volume ID?
        JZ      NEXTENT                 ; Nope, (not even $FCB_CREATE)
        XOR     AH,AH                   ; Set zero flag for $FCB_CREATE
        JMP     SHORT RETF              ; Found Volume ID
check_one_volume_id:
        CMP     AH,attr_volume_id       ; Looking only for Volume ID?
        JZ      NEXTENT                 ; Yes, continue search
        ADD     SI,15
        CALL    MatchAttributes
        JZ      RETF
        TEST    BYTE PTR [CREATING],-1  ; Pass back mismatch if creating
        JZ      NEXTENT                 ; Otherwise continue searching
RETF:
        LES     BP,[THISDPB]
        MOV     AH,ES:[BP.dpb_drive]
SETESRET:
        PUSH    SS
        POP     ES
        return

SUBTTL GETENTRY, NEXTENTRY, GETENT -- STEP THROUGH DIRECTORY
PAGE
        entry   GETENTRY
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       [LASTENT] has directory entry
;       ES:BP points to drive parameters
; Function:
;       Locates directory entry in preparation for search
;       GETENT provides entry for passing desired entry in AX
;       A valid search environment MUST exist
;               ENDENT,ENTLAST,ENTFREE
; Outputs:
;       [CURBUF+2]:BX = Pointer to next directory entry in CURBUF
;       [CURBUF+2]:DX = Pointer to first byte after end of CURBUF
;       [LASTENT] = New directory entry number

        MOV     AX,[LASTENT]
        entry   GETENT
        MOV     [LASTENT],AX
        MOV     CL,4
        SHL     AX,CL
        XOR     DX,DX
        SHL     AX,1
        RCL     DX,1                    ; Account for overflow in last shift
        MOV     BX,ES:[BP.dpb_sector_size]
        AND     BL,255-31               ; Must be multiple of 32
        DIV     BX
        MOV     BX,DX                   ; Position within sector
        PUSH    BX
        invoke  DIRREAD
        POP     BX
SETENTRY:
        MOV     DX,WORD PTR [CURBUF]
        ADD     DX,BUFINSIZ
        ADD     BX,DX
        ADD     DX,ES:[BP.dpb_sector_size]       ; Always clears carry
        return

        entry   NEXTENTRY
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       Same as outputs of GETENTRY, above
; Function:
;       Update BX, and [LASTENT] for next directory entry.
;       Carry set if no more.

        MOV     AX,[LASTENT]
        CMP     AX,[ENTLAST]
        JZ      NONE
        INC     AX
        ADD     BX,32
        CMP     BX,DX
        JB      HAVIT
        MOV     BL,BYTE PTR [SECCLUSPOS]
        INC     BL
        CMP     BL,BYTE PTR [CLUSFAC]
        JB      SAMECLUS
        MOV     BX,[NXTCLUSNUM]
        CMP     BX,0FF8H
        JAE     NONE
        CMP     BX,2
        JB      NONE
        JMP     GETENT

NONE:
        STC
        return

HAVIT:
        MOV     [LASTENT],AX
        CLC
        return

SAMECLUS:
        MOV     BYTE PTR [SECCLUSPOS],BL
        MOV     [LASTENT],AX
        PUSH    DS
        LDS     DI,[CURBUF]
ASSUME  DS:NOTHING
        MOV     DX,[DI.BUFSECNO]
        INC     DX
        POP     DS
ASSUME  DS:DOSGROUP
        invoke  FIRSTCLUSTER
        XOR     BX,BX
        JMP     SETENTRY
Search  ENDP

SUBTTL GETCURRDIR -- GET CURRENT DIRECTORY
PAGE
        procedure   Dir_search,NEAR
        entry   GETCURRDIR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       ES:BP Points to DPB
;       FATREAD should be called before this routine
; Function:
;       Find current directory for drive
;       If path is bad set current directory to the root
; Outputs:
;       DS = DOSGROUP
;       [SECCLUSPOS] = 0
;       [DIRSTART] = Cluster # of first cluster of directory ( 0 if root)
;       [DIRSEC] Set to phys sec # of first sector first cluster of directory
;       [CLUSNUM] Set to next cluster
;       [CLUSFAC] Sectors/cluster
; Destroys all registers

        MOV     BX,ES:[BP.dpb_current_dir]
        OR      BX,BX
        JZ      SETROOTSRCH
        CMP     BX,0FF8H
        JB      SETDIRSRCH
        PUSH    ES
        POP     DS
        LEA     SI,[BP.dpb_dir_text]
        CALL    ROOTPATH
ASSUME  DS:DOSGROUP
        JNC     SETCURR
        MOV     ES:[BP.dpb_current_dir],0

SETROOTSRCH:
ASSUME  DS:NOTHING,ES:NOTHING
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        XOR     AX,AX
        MOV     [DIRSTART],AX
        MOV     BYTE PTR [SECCLUSPOS],AL
        DEC     AX
        MOV     [CLUSNUM],AX
        MOV     AX,ES:[BP.dpb_first_sector]
        MOV     DX,ES:[BP.dpb_dir_sector]
        SUB     AX,DX
        MOV     BYTE PTR [CLUSFAC],AL
        MOV     [DIRSEC],DX
        return

SETCURR:
ASSUME  DS:DOSGROUP
        MOV     AX,[DIRSTART]
        MOV     ES:[BP.dpb_current_dir],AX
        return

        entry   SETDIRSRCH
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       BX cluster number of start of directory
;       ES:BP Points to DPB
; Function:
;       Set up a directory search
; Outputs:
;       DS = DOSGROUP
;       [DIRSTART] = BX
;       [CLUSFAC],[CLUSNUM],[SECCLUSPOS],[DIRSEC] set
; destroys AX,DX

        OR      BX,BX
        JZ      SETROOTSRCH
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     [DIRSTART],BX
        MOV     AL,ES:[BP.dpb_cluster_mask]
        INC     AL
        MOV     BYTE PTR [CLUSFAC],AL
        invoke  UNPACK
        MOV     [CLUSNUM],DI
        MOV     DX,BX
        XOR     BL,BL
        MOV     BYTE PTR [SECCLUSPOS],BL
        invoke  FIGREC
        MOV     [DIRSEC],DX
        return
Dir_search  ENDP

SUBTTL MAKENODE -- CREATE A NEW NODE
PAGE
        procedure   MakeNode,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       AL - attribute to create
;       DS:SI Points to asciz path
;       [THISFCB] Points to an empty FCB
; Function:
;       Make a new node
; Outputs:
;       DS=DOSGROUP
;       ES:BP Points to DPB
;       AX = 0 Success
;       AX = 1 A node by this name exists and is a directory
;       AX = 2 A new node could not be created                error
;       AX = 3 A node by this name exists and is a file       error
;       AX = 4 Bad Path                                       error
;       AX = 5 Attribute mismatch                             error
;       CARRY SET IF ERROR
;       ELSE
;          [DIRSTART],[DIRSEC],[CLUSFAC],[CLUSNUM] set to directory
;               containing new node.
;          [CURBUF+2]:BX Points to entry
;          [CURBUF+2]:SI Points to entry.fcb_firclus
;          [ThisFCB] is filled in
;          If this is a new entry zero is set and
;               Attribute byte in entry is directory
;          else a file existed by this name and:
;               [NAME1] has name
;               entry is not changed in any way
; Destroys all registers

        PUSH    AX
        CALL    GetPath
        MOV     DL,CL           ; Save CL info
        POP     CX
        MOV     BYTE PTR [ATTRIB],CL
        MOV     CX,AX
        JNC     make_exists     ; File existed
        JNZ     make_err_4      ; Path bad
        OR      DL,DL           ; Check "CL" return from GETPATH
        JNZ     make_type       ; Name simply not found
make_err_4:
        MOV     AL,4            ; case 1 bad path
make_err_ret:
        STC
        return

make_type:
        XOR     AL,AL           ; nothing exists... assume 0
        STC
        JMP     SHORT make_save
make_exists:
        JZ      make_exists_dir
        MOV     AL,3            ; file exists type 3
        TEST    BYTE PTR [ATTRIB],(attr_volume_id+attr_directory)
        JNZ     make_err_ret_5  ; but we wanted a volid or dir
        OR      CH,CH
        JS      make_dev        ; No furthur checks if device
        PUSH    CX
        MOV     DS,WORD PTR [CURBUF+2]
        MOV     CH,[BX+dir_attr] ; Get file attributes
        TEST    CH,attr_read_only
        JNZ     make_err_ret_5P ; Cannot create on read only files
        CALL    MatchAttributes
make_err_ret_5P:
        POP     CX
        JZ      make_dev        ; Attributes ok
make_err_ret_5:
        MOV     AL,5            ; Attribute mismatch
        JMP     SHORT make_err_ret

make_dev:
        XOR     AL,AL           ; Make sure zero set(atts match), carry clear(exists)
        MOV     AL,3            ; Restore correct value
        JMP     SHORT make_save
make_exists_dir:
        MOV     AL,1            ; directory exists
        TEST    BYTE PTR [ATTRIB],attr_directory
        JZ      make_err_ret    ; we didn't want a directory
        CLC
        return                  ; just return
make_save:
        PUSH    AX
;
; set up for call to NewEntry - it is in the middle of FCB_CREATE
; so we must also pre-push two registers.  They will be popped off
; by FCB_CREATE
;
        PUSH    SS
        POP     DS
        ASSUME  DS:DOSGROUP
        PUSHF                           ;Save state of flags
        CMP     BYTE PTR [NAME1],'.'    ;Detect attempt to make '.' or '..'
        JNZ     NOTLDOT                 ; Needed because no '.' or '..' in root
        POPF
        MOV     AL,1                    ;Force type 2 error
        JMP     SHORT SET2ERR

NOTLDOT:
        POPF
        PUSH    ES
        LES     DI,[ThisFCB]
        PUSH    DS
        PUSH    DI
        PUSH    ES
        MOV     AX,CX
        invoke  NewEntry
        POP     DS
        POP     ES
SET2ERR:
        OR      AL,AL
        POP     AX
        JZ      make_set_fcb
        MOV     AL,2                ; create failed case 2
        STC
        return
make_set_fcb:
ASSUME  DS:DOSGROUP
        PUSH    ES
        LES     DI,[THISFCB]
        INC     DI
        PUSH    DS
        PUSH    SI
        MOV     DS,WORD PTR [CURBUF+2]
ASSUME  DS:NOTHING
        MOV     SI,BX
        MOV     CX,11
        REP     MOVSB
        POP     SI
        POP     DS
ASSUME  DS:DOSGROUP
        POP     ES
        CMP     AL,1
        JA      make_errors
        OR      AL,AL
        CLC
        return
make_errors:
        STC
        return

MakeNode    ENDP

SUBTTL GETPATH -- PARSE AN asciz PATH
PAGE

        procedure   GETPATH,near
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:SI Points to asciz path
; Function:
;       Crack the path
; Outputs:
;       [DRIVESPEC] is non zero if a drive was specified
;       [ROOTSTART] is non zero if a / started the path
;       [ATTRIB] set to attr_directory+attr_hidden+attr_system
;       Same as FINDPATH except if path specifies a device in which case
;       bit 7 of AH will be set and SI and BX will point DOSGROUP relative
; Destroys all registers

        XOR     AX,AX
        MOV     WORD PTR [DRIVESPEC],AX
        MOV     BYTE PTR [ATTRIB],attr_directory+attr_system+attr_hidden
        LODSB
        invoke  PATHCHRCMP
        JZ      DEFAULTROOT
        MOV     AH,AL
        LODSB
        CMP     AL,':'
        JZ      DRVSPEC
        DEC     SI
        DEC     SI
        PUSH    DS
        PUSH    SI
        PUSH    SS
        POP     ES
        CMP     BYTE PTR [device_availability],0
        JZ      NOWDEV
        CALL    GOTPRESTRING2
        JNC     BUILDFCBJ               ; If no carry then we have a device
NOWDEV:
        CALL    DEFPATH
GOFIND:
        MOV     AL,[NoSetDir]
        PUSH    AX
        MOV     [NoSetDir],0
        CALL    GETCURRDIR
        POP     AX
        MOV     [NoSetDir],AL
        POP     SI
        POP     DS
        JMP     FINDPATH

DEFPATH:
        XOR     AL,AL
DRVPATH:
        invoke  GETTHISDRV
        retc                    ; Bad drive
        PUSH    SS
        POP     DS
        invoke  FATREAD
        CLC
        return

DEFAULTROOT:
        PUSH    DS
        PUSH    SI
        CALL    DEFPATH
        POP     SI
        POP     DS
ROOTSRCH:
        INC     BYTE PTR [ROOTSTART]
        CMP     BYTE PTR [SI],0
        JZ      PATHISNULL
        PUSH    DS
        PUSH    SI
        PUSH    ES              ; Save pointer to DPB
        CALL    CHKDEV
        POP     ES
        JNC     BUILDFCBJ
        POP     SI
        POP     DS
        JMP     ROOTPATH

BUILDFCBJ:
        POP     AX
        POP     AX
        context es
        invoke  BUILDFCB        ; Clears carry sets zero
        INC     AL              ; reset zero
        return

DRVSPEC:
        INC     [DRIVESPEC]
        MOV     AL,AH
        OR      AL,20H          ; Convert to lower case
        SUB     AL,60H          ; Make A=1
        PUSH    DS
        PUSH    SI
        PUSH    AX
        context es
        CALL    GotPreString2
        ASSUME  ES:NOTHING
        POP     AX
        JNC     BuildFCBJ
        CALL    DRVPATH
        POP     SI
        POP     DS
        retc                    ; Bad drive
        LODSB
        invoke  PATHCHRCMP
        JZ      ROOTSRCH
        DEC     SI
        PUSH    DS
        PUSH    SI
        JMP     GOFIND

PATHISNULL:
        CALL    SETROOTSRCH
ASSUME  DS:DOSGROUP
        XOR     AL,AL           ; Set zero (directory) clear carry
        return

CHKDEV:
ASSUME  DS:NOTHING
        PUSH    SS
        POP     ES
        MOV     DI,OFFSET DOSGROUP:DEVSTRING
        XOR     CX,CX
        MOV     CL,DEVSTRLEN
CHKPRESTRING:
        REPE    CMPSB
        JZ      GOTPRESTRING
        DEC     SI
        invoke  GETLET          ; Try convert to upper case
        CMP     AL,ES:[DI-1]
        JZ      CHKPRESTRING
NOPRESTRING:
        STC
        return

GOTPRESTRING:
        LODSB
        invoke  PATHCHRCMP
        JNZ     NOPRESTRING
GOTPRESTRING2:
        MOV     DI,OFFSET DOSGROUP:NAME1
        MOV     CX,9
TESTLOOP:
        invoke  GETLET
        CMP     AL,'.'
        JZ      TESTDEVICE
        invoke  PATHCHRCMP
        JZ      NOTDEV
        OR      AL,AL
        JZ      TESTDEVICE
        STOSB
        LOOP    TESTLOOP
NOTDEV:
        STC
        return

TESTDEVICE:
        ADD     CX,2
        MOV     AL,' '
        REP     STOSB
        PUSH    SS
        POP     DS
        invoke  DEVNAME
        return
GETPATH ENDP

SUBTTL ROOTPATH, FINDPATH -- PARSE A PATH
PAGE
        procedure   ROOTPATH,near

ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       ES:BP Points to DPB
;       FATREAD should be called before this routine
;       DS:SI Points to asciz string of path which is assumed to start at
;               the root (no leading '/').
; Function:
;       Search from root for path
; Outputs:
;       Same as FINDPATH
; Destroys all registers

        PUSH    DS
        CALL    SETROOTSRCH
        POP     DS

; NOTE FALL THROUGH

    entry   FINDPATH
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       ES:BP Points to DPB
;       DS:SI Points to asciz string of path (no leading '/').
;       [SECCLUSPOS] = 0
;       [DIRSEC] = Phys sec # of first sector of directory
;       [CLUSNUM] = Cluster # of next cluster
;       [CLUSFAC] = Sectors per cluster
;   Validate_path should be called before this routine is used,
;       unless it is KNOWN the path is good.
; Function:
;       Parse path name
; Outputs:
;       ES:BP Points to DPB
;       Carry set if bad path
;          DS:SI Points to path element causing failure
;          Zero set
;             [DIRSTART],[DIRSEC],[CLUSNUM], and [CLUSFAC] are set up to
;             start a search on the last directory
;             CL is zero if there is a bad name in the path
;             CL is non-zero if the name was simply not found
;                [ENTFREE] may have free spot in directory
;                [NAME1] is the name.
;                CL = 81H if '*'s or '?' in name 1, 80H otherwise
;          Zero reset
;             File in middle of path or bad name in path
;               or path too long or malformed path
;       ELSE
;          DS = DOSGROUP
;          AH = device ID
;          [CURBUF] contains directory record with match
;          [CURBUF+2]:BX Points into [CURBUF] to start of entry
;          [CURBUF+2]:SI Points to fcb_FIRCLUS field for entry
;          [NAME1] Has entry name
;          If last element is a directory zero is set and:
;             [DIRSTART],[SECCLUSPOS],[DIRSEC],[CLUSNUM], and [CLUSFAC]
;             are set up to start a search on it.
;          If last element is a file zero is reset
; Destroys all registers

        PUSH    ES
        PUSH    SI
        invoke  NAMETRANS
        MOV     CL,AL
        OR      CL,80H
        POP     DI
        POP     ES
        CMP     SI,DI
        JNZ     check_device
        JMP     BADPATH
check_device:
        PUSH    DS
        PUSH    SI
        MOV     AL,BYTE PTR [SI]

;
; can we see all devices
;
        context DS
        CMP     BYTE PTR [device_availability],0
        JZ      FindFile

;
; check name1 to see if we have a device...
;
        PUSH    ES
        context ES
        invoke  DevName         ; blast BX
        POP     ES
        ASSUME  ES:NOTHING
        JC      FindFile
        OR      AL,AL
        JNZ     FileInPath
        POP     SI
        POP     SI
        context ES
        invoke  BuildFCB
        INC     AL
        return

FindFile:
        ASSUME  ES:NOTHING
        PUSH    DI              ; Start of this element
        PUSH    ES
        PUSH    CX
        CALL    FINDENTRY
        POP     CX
        POP     ES
        POP     DI
        JC      BADPATHPOP
        LDS     DI,[CURBUF]
ASSUME  DS:NOTHING
        TEST    BYTE PTR [BX+dir_attr],attr_directory
        JZ      FileInPath

;
; if we are not setting the directory, then
; check for end of string
;
        CMP     BYTE PTR [NoSetDir],0
        JZ      SetDir
        MOV     DX,DI
        MOV     AX,DS
        POP     DI
        POP     DS
        CMP     BYTE PTR [DI],0
        JZ      SetRet
        PUSH    DS
        PUSH    DI
        MOV     DI,DX
        MOV     DS,AX

SetDir:
        MOV     DX,[SI]
        SUB     BX,DI
        SUB     SI,DI
        PUSH    BX
        PUSH    AX
        PUSH    SI
        PUSH    CX
        PUSH    [DI.BUFSECNO]
        MOV     BX,DX
        CALL    SETDIRSRCH
ASSUME  DS:DOSGROUP
        POP     DX
        XOR     AL,AL
        invoke  GETBUFFR
        POP     CX
        POP     SI
        POP     AX
        POP     BX
        MOV     DI,WORD PTR [CURBUF]
        ADD     SI,DI
        ADD     BX,DI
        POP     DI
        POP     DS
ASSUME  DS:NOTHING
        MOV     AL,[DI]
        OR      AL,AL
        JZ      SETRET
        INC     DI
        MOV     SI,DI
        invoke  PATHCHRCMP
        JNZ     find_bad_name
        JMP     FINDPATH

find_bad_name:
        DEC     SI
BADPATH:
        XOR     CL,CL   ; Set zero
        STC
        return

FILEINPATH:
        POP     DI
        POP     DS
        MOV     AL,[DI]
        OR      AL,AL
        JZ      INCRET
        MOV     SI,DI   ; Path too long
        STC
        return

INCRET:
        INC     AL      ; Reset zero
SETRET:
        PUSH    SS
        POP     DS
        return

BADPATHPOP:
        POP     SI
        POP     DS
        MOV     AL,[SI]
        MOV     SI,DI   ; Start of bad element
        OR      AL,AL   ; zero if bad element is last, non-zero if path too long
        STC
        return
ROOTPATH    ENDP

SUBTTL STARTSRCH -- INITIATE DIRECTORY SEARCH
PAGE
        procedure   StartSrch,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       [THISDPB] Set
; Function:
;       Set up a search for GETENTRY and NEXTENTRY
; Outputs:
;       ES:BP = Drive parameters
;       Sets up LASTENT, ENDENT, ENTFREE=ENTLAST=-1, VOLID=0
; Destroys all registers (via FATREAD)

        LES     BP,[THISDPB]
        XOR     AX,AX
        MOV     [LASTENT],AX
        MOV     BYTE PTR [VOLID],AL      ; No volume ID found
        DEC     AX
        MOV     [ENTFREE],AX
        MOV     [ENTLAST],AX
        return
StartSrch   ENDP

BREAK <MatchAttributes - the final check for attribute matching>

;
; Input:    [Attrib] = attribute to search for
;           CH = found attribute
; Output:   JZ <match>
;           JNZ <nomatch>
;
        procedure MatchAttributes,near
        ASSUME  DS:NOTHING,ES:NOTHING
        PUSH    AX
        MOV     AL,[Attrib]         ; AL <- SearchSet
        NOT     AL                  ; AL <- SearchSet'
        AND     AL,CH               ; AL <- SearchSet' and FoundSet
        AND     AL,attr_all         ; AL <- SearchSet' and FoundSet and Important
;
; the result is non-zero if an attribute is not in the search set
; and in the found set and in the important set. This means that we do not
; have a match.  Do a JNZ <nomatch> or JZ <match>
;
        POP     AX
        return
MatchAttributes ENDP

do_ext

CODE    ENDS
    END
                                                                                            