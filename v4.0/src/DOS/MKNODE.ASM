;       SCCSID = @(#)mknode.asm 1.5 85/08/29
TITLE   MKNODE - Node maker
NAME    MKNODE
; Low level routines for making a new local file system node
;   and filling in an SFT from a directory entry
;
;   BUILDDIR
;   SETDOTENT
;   MakeNode
;   NEWENTRY
;   FREEENT
;   NEWDIR
;   DOOPEN
;   RENAME_MAKE
;   CHECK_VIRT_OPEN
;
;   Revision history:
;
;    AN000  version 4.0  Jan. 1988
;    A004   PTM 3680  --- Make SFT NAME field offset same as 3.30

;
; get the appropriate segment definitions
;
.xlist
include dosseg.asm
include fastopen.inc

CODE    SEGMENT BYTE PUBLIC  'CODE'
        ASSUME  SS:DOSGROUP,CS:DOSGROUP

.xcref
include dossym.inc
include devsym.inc
.cref
.list

        i_need  EntFree,WORD
        i_need  DirStart,WORD
        i_need  LastEnt,WORD
        i_need  ClusNum,WORD
        i_need  CurBuf,DWORD
        i_need  Attrib,BYTE
        i_need  VolID,BYTE
        i_need  Name1,BYTE
        i_need  ThisDPB,DWORD
        i_need  EntLast,WORD
        i_need  Creating,BYTE
        i_need  SecClusPos,BYTE
        i_need  ClusFac,BYTE
        i_need  NxtClusNum,WORD
        i_need  DirSec,WORD
        i_need  NoSetDir,BYTE
        i_need  THISSFT,DWORD
        i_need  SATTRIB,BYTE
        i_need  ALLOWED,BYTE
        i_need  FAILERR,BYTE
        i_need  VIRTUAL_OPEN
        I_need  FastOpen_Ext_info,BYTE        ; DOS 3.3
        I_need  FastOpenFlg,BYTE              ; DOS 3.3
        I_need  CPSWFLAG,BYTE                 ;FT. DOS 3.4                      ;AN000;
        I_need  EXTOPEN_ON,BYTE               ;FT. DOS 3.4                      ;AN000;
        I_need  EXTOPEN_FLAG,WORD             ;FT. DOS 3.4                      ;AN000;
        I_need  EXTOPEN_IO_MODE,WORD          ;FT. DOS 3.4                      ;AN000;
        I_need  HIGH_SECTOR,WORD              ;>32mb                            ;AN000;
        I_need  ACT_PAGE,WORD                 ;>32mb                            ;AN000;

Break   <BUILDDIR,NEWDIR -- ALLOCATE DIRECTORIES>

; Inputs:
;       ES:BP Points to DPB
;       [THISSFT] Set if using NEWDIR entry point
;               (used by ALLOCATE)
;       [LASTENT] current last valid entry number in directory if no free
;               entries
;       [DIRSTART] Points to first cluster of dir (0 means root)
; Function:
;       Grow directory if no free entries and not root
; Outputs:
;       CARRY SET IF FAILURE
;       ELSE
;          AX entry number of new entry
;          If a new dir [DIRSTART],[CLUSFAC],[CLUSNUM],[DIRSEC] set
;               AX = first entry of new dir
;       GETENT should be called to set [LASTENT]

        procedure   BUILDDIR,NEAR
        DOSAssume   CS,<DS>,"BuildDir"
        ASSUME  ES:NOTHING

        MOV     AX,[ENTFREE]
        CMP     AX,-1
        JZ      CHECK_IF_ROOT
        CLC
        return

CHECK_IF_ROOT:
        CMP     [DIRSTART],0
        JNZ     NEWDIR
        STC
        return                  ; Can't grow root

        entry   NEWDIR
        MOV     BX,[DIRSTART]
        OR      BX,BX
        JZ      NULLDIR
        invoke  GETEOF
        retc                    ; Screw up
NULLDIR:
        MOV     CX,1
        invoke  ALLOCATE
        retc
        MOV     DX,[DIRSTART]
        OR      DX,DX
        JNZ     ADDINGDIR
        invoke  SETDIRSRCH
        retc
        MOV     [LASTENT],-1
        JMP     SHORT GOTDIRREC
ADDINGDIR:
        PUSH    BX
        MOV     BX,[ClusNum]
        Invoke  IsEof
        POP     BX
        JB      NOTFIRSTGROW
;;;; 10/17/86 update CLUSNUM in the fastopen cache
        MOV     [CLUSNUM],BX
        PUSH    CX
        PUSH    AX
        PUSH    BP
        MOV     AH,1                       ; CLUSNUM update
        MOV     DL,ES:[BP.dpb_drive]       ; drive #
        MOV     CX,[DIRSTART]              ; first cluster #
        MOV     BP,BX                      ; CLUSNUM
        invoke  FastOpen_Update
        POP     BP
        POP     AX
        POP     CX

;;;; 10/17/86 update CLUSNUM in the fastopen cache
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
        MOV     [ALLOWED],allowed_FAIL + allowed_RETRY
        MOV     AL,0FFH
        invoke  GETBUFFR
        JNC     GET_SSIZE
        POP     CX
        return

GET_SSIZE:
        MOV     CX,ES:[BP.dpb_sector_size]
        PUSH    ES
        LES     DI,[CURBUF]
        OR      ES:[DI.buf_flags],buf_isDIR
        PUSH    DI
        ADD     DI,BUFINSIZ
        XOR     AX,AX
        SHR     CX,1
        REP     STOSW
        JNC     EVENZ
        STOSB
EVENZ:
        POP     DI

        TEST    ES:[DI.buf_flags],buf_dirty  ;LB. if already dirty              ;AN000;
        JNZ     yesdirty                  ;LB.    don't increment dirty count   ;AN000;
        invoke  INC_DIRTY_COUNT           ;LB.                                  ;AN000;
        OR      ES:[DI.buf_flags],buf_dirty
yesdirty:
        POP     ES
        POP     CX
        INC     DX
        LOOP    ZERODIR
        MOV     AX,[LASTENT]
        INC     AX
        CLC
        return

EndProc BUILDDIR

;
; set up a . or .. directory entry for a directory.
;
;   Inputs:     ES:DI point to the beginning of a directory entry.
;               AX contains ". " or ".."
;               DX contains first cluster of entry
;
        procedure   SETDOTENT,NEAR
        DOSAssume   CS,<DS>,"SetDotEnt"
;
; Fill in name field
;
        STOSW
        MOV     CX,4
        MOV     AX,"  "
        REP     STOSW
        STOSB
;
; Set up attribute
;
        MOV     AL,attr_directory
        errnz   dir_attr-(dir_name+11)
        STOSB
;
; Initialize time and date of creation
;
        ADD     DI,10
        MOV     SI,WORD PTR [THISSFT]
        MOV     AX,[SI.sf_time]
        errnz   dir_time-(dir_attr+1+10)
        STOSW
        MOV     AX,[SI.sf_date]
        errnz   dir_date-(dir_time+2)
        STOSW
;
; Set up first cluster field
;
        MOV     AX,DX
        errnz   dir_first-(dir_date+2)
        STOSW
;
; 0 file size
;
        XOR     AX,AX
        errnz   dir_size_l-(dir_first+2)
        STOSW
        STOSW
        errnz   <(size dir_entry)-(dir_size_l+4)>
        return
EndProc SETDOTENT

Break   <MAKENODE -- CREATE A NEW NODE>

; Inputs:
;       AL - attribute to create
;       AH = 0 if it is ok to truncate a file already by this name
;       AH = Non 0 if this is an error
;               (AH ignored on dirs and devices)
;        NOTE: When making a DIR or volume ID, AH need not be set since
;               a name already existant is ALWAYS an error in these cases.
;       [WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL
;               terminated)
;       [CURR_DIR_END] Points to end of Current dir part of string
;               ( = -1 if current dir not involved, else
;                Points to first char after last "/" of current dir part)
;       [THISCDS] Points to CDS being used
;       [THISSFT] Points to an empty SFT. EXCEPT sf_mode filled in.
; Function:
;       Make a new node
; Outputs:
;       Sets EXTERR_LOCUS = errLOC_Disk or errLOC_Unk via GetPathNoset
;       CARRY SET IF ERROR
;          AX = 1 A node by this name exists and is a directory
;          AX = 2 A new node could not be created
;          AX = 3 A node by this name exists and is a disk file
;               (AH was NZ on input)
;          AX = 4 Bad Path
;               SI return from GetPath maintained
;          AX = 5 Attribute mismatch
;          AX = 6 Sharing Violation
;               (INT 24 generated ALWAYS since create is always compat mode
;          AX = 7 file not found for Extended Open (not exists and fails)
;       ELSE
;          AX = 0       Disk Node
;          AX = 3       Device Node (error in some cases)
;          [DIRSTART],[DIRSEC],[CLUSFAC],[CLUSNUM] set to directory
;               containing new node.
;          [CURBUF+2]:BX Points to entry
;          [CURBUF+2]:SI Points to entry.dir_first
;          [THISSFT] is filled in
;               sf_mode = unchanged.
;          Attribute byte in entry is input AL
; DS preserved, others destroyed

        procedure   MakeNode,NEAR
        DOSAssume   CS,<DS>,"MakeNode"
        ASSUME  ES:NOTHING

        MOV     WORD PTR [CREATING],0E5FFH      ; Creating, not DEL *.*
        PUSH    AX              ; Save AH value
        MOV     [NoSetDir],0
        MOV     [SATTRIB],AL
        invoke  GetPathNoSet
        MOV     DL,CL           ; Save CL info
        MOV     CX,AX           ; Device ID to CH
        POP     AX              ; Get back AH
        JNC     make_exists     ; File existed
        JNZ     make_err_4      ; Path bad
        CMP     DL,80H          ; Check "CL" return from GETPATH
        JZ      make_type       ; Name simply not found, and no metas
make_err_4:
        MOV     AL,4            ; case 1 bad path
make_err_ret:
        XOR     AH,AH
        STC
        return

        entry   RENAME_MAKE     ; Used by DOS_RENAME to "copy" a node

make_type:
;Extended Open hooks
        TEST   [EXTOPEN_ON],ext_open_on  ;FT. from extended open                ;AN000;
        JZ     make_type2                ;FT. no                                ;AN000;
        OR     [EXTOPEN_ON],ext_file_not_exists ;FT. set for extended open      ;AN000;
        TEST   [EXTOPEN_FLAG],0F0H       ;FT. not exists and fails              ;AN000;
        JNZ    make_type2                ;FT. no                                ;AN000;
        STC                              ;FT. set carry                         ;AN000;
        MOV    AX,7                      ;FT. file not found                    ;AN000;
        return                           ;FT.                                   ;AN000;
make_type2:
;Extended Open hooks
        LES     DI,[THISSFT]
;       MOV     ES:[DI.sf_mode],sharing_compat + open_for_both
        XOR     AX,AX           ; nothing exists Disk Node
        STC                     ; Not found
        JMP     make_new

;
; The node exists.  It may be either a device, directory or file:
;   Zero set => directory
;   High bit of CH on => device
;   else => file
make_exists:
        JZ      make_exists_dir
        MOV     AL,3            ; file exists type 3  (error or device node)
        TEST    BYTE PTR [ATTRIB],(attr_volume_id+attr_directory)
        JNZ     make_err_ret_5  ; Cannot already exist as Disk or Device Node
                                ;       if making DIR or Volume ID
        OR      CH,CH
        JS      make_share      ; No further checks on attributes if device
        OR      AH,AH
        JNZ     make_err_ret    ; truncating NOT OK (AL = 3)
        PUSH    CX              ; Save device ID
        MOV     ES,WORD PTR [CURBUF+2]
        MOV     CH,ES:[BX+dir_attr] ; Get file attributes
        TEST    CH,attr_read_only
        JNZ     make_err_ret_5P ; Cannot create on read only files
        invoke  MatchAttributes
        POP     CX              ; Devid back in CH
        JNZ     make_err_ret_5  ; Attributes not ok
        XOR     AL,AL           ; AL = 0, Disk Node
make_share:
        XOR     AH,AH
        PUSH    AX              ; Save Disk or Device node
        PUSH    CX              ; Save Device ID
        MOV     AH,CH           ; Device ID to AH
        CALL    DOOPEN          ; Fill in SFT for share check
        LES     DI,[THISSFT]
;       MOV     ES:[DI.sf_mode],sharing_compat + open_for_both
        SaveReg <SI,BX>         ; Save CURBUF pointers
        invoke  ShareEnter
        jnc     MakeEndShare
;
; User failed request.
;
        RestoreReg  <BX,SI,CX,AX>
Make_Share_ret:
        MOV     AL,6
        JMP     make_err_ret

make_err_ret_5P:
        POP     CX              ; Get back device ID
make_err_ret_5:
        MOV     AL,5            ; Attribute mismatch
        JMP     make_err_ret

make_exists_dir:
        MOV     AL,1            ; exists as directory, always an error
        JMP     make_err_ret

make_save:
        PUSH    AX              ; Save whether Disk or File
        MOV     AX,CX           ; Device ID to AH
        CALL    NewEntry
        POP     AX              ; 0 if Disk, 3 if File
        retnc
        MOV     AL,2            ; create failed case 2
        return

make_new:
        call    make_save
        retc                    ; case 2 fail
        TEST    BYTE PTR [ATTRIB],attr_directory
        retnz                   ; Don't "open" directories, so don't
                                ;   tell the sharer about them
        SaveReg <AX,BX,SI>      ; Save AL code
        invoke  ShareEnter
        RestoreReg  <SI,BX,AX>
        retnc
;
; We get here by having the user FAIL a share problem.  Typically a failure of
; this nature is an out-of-space or an internal error.  We clean up as best as
; possible:  delete the newly created directory entry and return share_error.
;
        PUSH    AX
        LES     DI,CurBuf
        MOV     BYTE PTR ES:[BX],0E5H   ; nuke newly created entry.

        TEST    ES:[DI.buf_flags],buf_dirty  ;LB. if already dirty              ;AN000;
        JNZ     yesdirty2                 ;LB.    don't increment dirty count   ;AN000;
        invoke  INC_DIRTY_COUNT           ;LB.                                  ;AN000;
        OR      ES:[DI].buf_flags,buf_dirty ; flag buffer as dirty
yesdirty2:
        LES     BP,ThisDPB
        MOV     AL,ES:[BP].DPB_Drive    ; get drive for flush
        Invoke  FlushBuf                ; write out buffer.
        POP     AX
        jmp     make_Share_ret
;
; We have found an existing file.  We have also entered it into the share set.
; At this point we need to call newentry to correctly address the problem of
; getting rid of old data (create an existing file) or creating a new
; directory entry (create a new file).  Unfortunately, this operation may
; result in an INT 24 that the user doesn't return from, thus locking the file
; irretrievably into the share set.  The correct solution is for us to LEAVE
; the share set now, do the operation and then reassert the share access.
;
; We are allowed to do this!  There is no window!  After all, we are in
; critDisk here and for someone else to get in, they must enter critDisk also.
;
MakeEndShare:
        LES     DI,ThisSFT              ; grab SFT
        XOR     AX,AX
        EnterCrit   critSFT
        XCHG    AX,ES:[DI].sf_ref_count
        SaveReg <AX,DI,ES>
        PUSHF
        invoke  ShareEnd                ; remove sharing
        POPF
        RestoreReg  <ES,DI,ES:[DI].sf_ref_count>
        LeaveCrit   critSFT
        RestoreReg  <BX,SI,CX,AX>
        CALL    make_save
;
; If the user failed, we do not reenter into the sharing set.
;
        retc                            ; bye if error
        SaveReg <AX,BX,SI>
        PUSHF
        invoke  ShareEnter
        POPF
        RestoreReg  <SI,BX,AX>
;
; If Share_check fails, then we have an internal ERROR!!!!!
;
        return
EndProc MakeNode

; Inputs:
;       [THISSFT] set
;       [THISDPB] set
;       [LASTENT] current last valid entry number in directory if no free
;               entries
;       [VOLID] set if a volume ID was found during search
;       [ATTRIB] Contains attributes for new file
;       [DIRSTART] Points to first cluster of dir (0 means root)
;       CARRY FLAG INDICATES STATUS OF SEARCH FOR FILE
;               NC means file existed (device)
;               C  means file did not exist
;       AH = Device ID byte
;       If FILE
;           [CURBUF+2]:BX points to start of directory entry
;           [CURBUF+2]:SI points to dir_first of directory entry
;       If device
;           DS:BX points to start of "fake" directory entry
;           DS:SI points to dir_first of "fake" directory entry
;               (has DWORD pointer to device header)
; Function:
;       Make a new directory entry
;       If an old one existed it is truncated first
; Outputs:
;       Carry set if error
;               Can't grow dir, atts didn't match, attempt to make 2nd
;               vol ID, user FAILed to I 24
;       else
;               outputs of DOOPEN
; DS, BX, SI preserved (meaning on SI BX, not value), others destroyed

        procedure NEWENTRY,NEAR
        DOSAssume   CS,<DS>,"NewEntry"
        ASSUME  ES:NOTHING

        LES     BP,[THISDPB]
ASSUME  ES:NOTHING
        JNC     EXISTENT
        CMP     [FAILERR],0
        STC
        retnz                   ; User FAILed, node might exist
        CALL    BUILDDIR        ; Try to build dir
        retc                    ; Failed
        invoke  GETENT          ; Point at that free entry
        retc                    ; Failed
        JMP     SHORT FREESPOT

ERRRET3:
        STC
        return

EXISTENT:
        DOSAssume   CS,<DS>,"MKNODE/ExistEnt"
        OR      AH,AH           ; Check if file is I/O device
        JNS     NOT_DEV1
        JMP     DOOPEN          ; If so, proceed with open

NOT_DEV1:
        invoke  FREEENT         ; Free cluster chain
        retc                    ; Failed
FREESPOT:
        TEST    BYTE PTR [ATTRIB],attr_volume_id
        JZ      NOTVOLID
        CMP     BYTE PTR [VOLID],0
        JNZ     ERRRET3         ; Can't create a second volume ID
NOTVOLID:
        MOV     ES,WORD PTR [CURBUF+2]
        MOV     DI,BX
        MOV     SI,OFFSET DOSGROUP:NAME1
        MOV     CX,5
        REP     MOVSW
        MOVSB                   ; Move name into dir entry
        MOV     AL,[ATTRIB]
        errnz   dir_attr-(dir_name+11)
        STOSB                   ; Attributes
;; File Tagging for Create DOS 4.00
        MOV     CL,5            ;FT. assume normal                              ;AN000;
;       CMP     [CPSWFLAG],0    ;FT. code page matching on                      ;AN000;
;       JZ      NORMFT          ;FT. no, make null code page                    ;AN000;
;       invoke  Get_Global_CdPg ;FT. get global code page                       ;AN000;
;       STOSW                   ;FT. tag this file with global code page        ;AN000;
;       DEC     CL              ;FT. only 4                                     ;AN000;
;NORMFT:                        ;FT.                                            ;AN000;

;; File Tagging for Create DOS 4.00
        XOR     AX,AX
        REP     STOSW           ; Zero pad
        invoke  DATE16
        XCHG    AX,DX
        errnz   dir_time-(dir_attr+1+2*5)
        STOSW                   ; dir_time
        XCHG    AX,DX
        errnz   dir_date-(dir_time+2)
        STOSW                   ; dir_date
        XOR     AX,AX
        PUSH    DI              ; Correct SI input value (recomputed for new buffer)

        errnz   dir_first-(dir_date+2)
        STOSW                   ; Zero dir_first and size
        errnz   dir_size_l-(dir_first+2)
        STOSW
        STOSW
updnxt:
        errnz   <(size dir_entry)-(dir_size_l+4)>
        MOV     SI,WORD PTR [CURBUF]

        TEST    ES:[SI.buf_flags],buf_dirty  ;LB. if already dirty              ;AN000;
        JNZ     yesdirty3                 ;LB.    don't increment dirty count   ;AN000;
        invoke  INC_DIRTY_COUNT           ;LB.                                  ;AN000;
        OR      ES:[SI.buf_flags],buf_dirty
yesdirty3:
        LES     BP,[THISDPB]
        MOV     AL,ES:[BP.dpb_drive]    ; Sets AH value again (in AL)
        PUSH    AX
        PUSH    BX
; If we have a file, we need to increment the open ref. count so that
; we have some protection against invalid media changes if an Int 24
; error occurs.
; Do nothing for a device.
        SaveReg <ES,DI>
        LES     DI,[THISSFT]
        test    es:[di.sf_flags],devid_device
        jnz     GotADevice
        SaveReg <DS,BX>
        LDS     BX,[THISDPB]
        MOV     word ptr ES:[DI.sf_devptr],BX
        MOV     BX,DS
        MOV     word ptr ES:[DI.sf_devptr+2],BX
        RestoreReg <BX,DS>      ; need to use DS for segment later on
        invoke  Dev_Open_SFT    ; increment ref. count
        mov     [VIRTUAL_OPEN],1; set flag
GotADevice:
        RestoreReg <DI,ES>

        PUSH    [ACT_PAGE]      ;LB. save EMS page for curbuf                   ;AN000;
        invoke  FLUSHBUF
        POP     BX              ;LB. restore EMS page for curbuf                ;AN000;
        PUSHF                   ;LB. save flushbuf falg                         ;AN000;
        CMP     BX,-1           ;BL-NETWORK PTM #-?
        JE      Page_ok         ;BL-NETWORK PTM #-?
        invoke  SET_MAP_PAGE    ;LB. remap curbuf                               ;AN000;
Page_ok:                        ;BL-NETWORK PTM #-?
        POPF                    ;LB. restore flush flag                         ;AN000;
        Call    CHECK_VIRT_OPEN ; decrement ref. count                          ;AN000;
        POP     BX
        POP     AX
        POP     SI              ; Get SI input back
        MOV     AH,AL           ; Get I/O driver number back
        retc                    ; Failed


;NOTE FALL THROUGH

; Inputs:
;       [THISDPB] points to DPB if file
;       [THISSFT] points to SFT being used
;       AH = Device ID byte
;       If FILE
;           [CURBUF+2]:BX points to start of directory entry
;           [CURBUF+2]:SI points to dir_first of directory entry
;       If device
;           DS:BX points to start of "fake" directory entry
;           DS:SI points to dir_first of "fake" directory entry
;               (has DWORD pointer to device header)
; Function:
;       Fill in SFT from dir entry
; Outputs:
;       CARRY CLEAR
;       sf_ref_count and sf_mode fields not altered
;       sf_flags high byte = 0
;       sf_flags low byte = AH except
;       sf_flags Bit 6 set (not dirty or not EOF)
;       sf_attr sf_date sf_time sf_name set from entry
;       sf_position = 0
;       If device
;           sf_devptr = dword at dir_first (pointer to device header)
;           sf_size = 0
;       If file
;           sf_firclus sf_size set from entry
;           sf_devptr = [THISDPB]
;           sf_cluspos = 0
;           sf_lstclus = sf_firclus
;           sf_dirsec sf_dirpos set
; DS,SI,BX preserved, others destroyed

    entry   DOOPEN
        DOSAssume   CS,<DS>,"DoOpen"
        ASSUME  ES:NOTHING

;
; Generate and store attribute
;
        MOV     DH,AH           ; AH to different place
        LES     DI,[THISSFT]
        ADD     DI,sf_attr      ; Skip ref_count and mode fields
        XOR     AL,AL           ; Assume it's a device, devices have an
                                ;   attribute of 0 (for R/O testing etc).
        OR      DH,DH           ; See if our assumption good.
        JS      DEV_SFT1        ; If device DS=DOSGROUP
        MOV     DS,WORD PTR [CURBUF+2]
ASSUME  DS:NOTHING
        MOV     AL,[BX.dir_attr] ; If file, get attrib from dir entry
DEV_SFT1:
        STOSB                   ; sf_attr, ES:DI -> sf_flags
;
; Generate and store flags word
;
        XOR     AX,AX
        MOV     AL,DH
        OR      AL,devid_file_clean
        STOSW                   ; sf_flags, ES:DI -> sf_devptr
;
; Generate and store device pointer
;
        PUSH    DS
        LDS     AX,DWORD PTR [BX.dir_first]       ; Assume device
        OR      DH,DH
        JS      DEV_SFT2
        LDS     AX,[THISDPB]            ; Was file
DEV_SFT2:
        STOSW                           ; store offset
        MOV     AX,DS
        POP     DS
        STOSW                           ; store segment
                                        ; ES:DI -> sf_firclus
;
; Generate pointer to, generate and store first cluster (irrelevant  for
; devices)
;
        PUSH    SI              ; Save pointer to dir_first
        MOVSW                   ; dir_first -> sf_firclus
                                ; DS:SI -> dir_size_l, ES:DI -> sf_time
;
; Copy time/date of last modification
;
        SUB     SI,dir_size_l - dir_time        ; DS:SI->dir_time
        MOVSW                   ; dir_time -> sf_time
                                ; DS:SI -> dir_date, ES:DI -> sf_date
        MOVSW                   ; dir_date -> sf_date
                                ; DS:SI -> dir_first, ES:DI -> sf_size
;
; Generate and store file size (0 for devices)
;
        LODSW                   ; skip dir_first, DS:SI -> dir_size_l
        LODSW                   ; dir_size_l in AX , DS:SI -> dir_size_h
        MOV     CX,AX           ; dir_size_l in CX
        LODSW                   ; dir_size_h (size AX:CX), DS:SI -> ????
        OR      DH,DH
        JNS     FILE_SFT1
        XOR     AX,AX
        MOV     CX,AX           ; Devices are open ended
FILE_SFT1:
        XCHG    AX,CX
        STOSW                   ; Low word of sf_size
        XCHG    AX,CX
        STOSW                   ; High word of sf_size
                                ; ES:DI -> sf_position
;
; Initialize position to 0
;
        XOR     AX,AX
        STOSW
        STOSW                   ; sf_position
                                ; ES:DI -> sf_cluspos
;
; Generate cluster optimizations for files
;
        OR      DH,DH
        JS      DEV_SFT3
        STOSW                   ; sf_cluspos
        MOV     AX,[BX.dir_first]
;;;;    STOSW                   ; sf_lstclus
        PUSH    DI              ;AN004; save dirsec offset
        SUB     DI,sf_dirsec    ;AN004; es:di -> SFT
        MOV     ES:[DI.sf_lstclus],AX  ;AN004; save it
        POP     DI              ;AN004; restore dirsec offset



; DOS 3.3  FastOpen  6/13/86

        PUSH   DS
        context DS
        TEST   [FastOpenFlg],Special_Fill_Set
        JZ     Not_FastOpen
        MOV     SI,OFFSET DOSGROUP:FastOpen_Ext_Info
        MOV     AX,WORD PTR [SI.FEI_dirsec]
        STOSW                   ; sf_dirsec
        MOV     AX,WORD PTR [SI.FEI_dirsec+2]  ;;; changed for >32mb
        STOSW                   ; sf_dirsec
        MOV     AL,[SI.FEI_dirpos]
        STOSB                   ; sf_dirpos
        POP     DS
        JMP     Next_Name

; DOS 3.3  FastOpen  6/13/86

Not_FastOpen:
        POP     DS                      ; normal path
ASSUME  DS:NOTHING
        MOV     SI,WORD PTR [CURBUF]    ; DS:SI->buffer header
        MOV     AX,WORD PTR [SI.buf_sector]     ;F.C. >32mb                        ;AN000;
        STOSW                   ; sf_dirsec     ;F.C. >32mb                        ;AN000;
        MOV     AX,WORD PTR [SI.buf_sector+2]   ;F.C. >32mb                        ;AN000;
        STOSW                   ; sf_dirsec     ;F.C. >32mb                        ;AN000;
        MOV     AX,BX
        ADD     SI,BUFINSIZ     ; DS:SI-> start of data in buffer
        SUB     AX,SI           ; AX = BX relative to start of sector
        MOV     CL,SIZE dir_entry
        DIV     CL
        STOSB                   ; sf_dirpos

Next_Name:
        errnz   sf_name-(sf_dirpos+1)
        JMP     SHORT FILE_SFT2

DEV_SFT3:
        ADD     DI,sf_name - sf_cluspos
FILE_SFT2:
;
; Copy in the object's name
;
        MOV     SI,BX           ; DS:SI points to dir_name
        MOV     CX,11
        REP     MOVSB           ; sf_name
        POP     SI              ; recover DS:SI -> dir_first
;; File tagging , code page and XA cluster must be after name
;       MOV     AX,[BX.dir_CODEPG]       ;FT. set file's code page                 ;AN000;
;       STOSW                            ;FT.                                      ;AN000;
;       MOV     AX,[BX.dir_EXTCLUSTER]   ;FT. set XA cluster                       ;AN000;
;       STOSW                            ;FT.                                      ;AN000;
;       MOV     AX,[EXTOPEN_IO_MODE]     ;FT. extended open                        ;AN000;
;       STOSW                            ;FT.                                      ;AN000;
;       MOV     AL,[BX.dir_attr2]        ;FT. high attribute                       ;AN000;
;       STOSB                            ;FT.                                      ;AN000;

;; File tagging , code page and XA cluster must be after name

        context DS
        CLC
        return

EndProc NEWENTRY

; Inputs:
;       ES:BP -> DPB
;       [CURBUF] Set
;       [CURBUF+2]:BX points to directory entry
;       [CURBUF+2]:SI points to above dir_first
; Function:
;       Free the cluster chain for the entry if present
; Outputs:
;       Carry set if error (currently user FAILed to I 24)
;       (NOTE dir_firclus and dir_size_l/h are wrong)
; DS BX SI ES BP preserved (BX,SI in meaning, not value) others destroyed

        procedure FREEENT,NEAR
        DOSAssume   CS,<DS>,"FreeEnt"
        ASSUME  ES:NOTHING

        PUSH    DS
        LDS     DI,[CURBUF]
ASSUME  DS:NOTHING
        MOV     CX,[SI]         ; Get pointer to clusters
        MOV     DX,WORD PTR [DI.buf_sector+2]  ;F.C. >32mb                      ;AN000;
        MOV     [HIGH_SECTOR],DX               ;F.C. >32mb                      ;AN000;
        MOV     DX,WORD PTR [DI.buf_sector]
        POP     DS
        DOSAssume   CS,<DS>,"MKNODE/FreeEnt"
        CMP     CX,2
        JB      RET1            ; Was 0 length file (or mucked Firclus if CX=1)
        CMP     CX,ES:[BP.dpb_max_cluster]
        JA      RET1            ; Treat like zero length file (firclus mucked)
        SUB     BX,DI
        PUSH    BX              ; Save offset
        PUSH    [HIGH_SECTOR]                  ;F.C. >32mb                      ;AN000;
        PUSH    DX              ; Save sector number

        MOV     BX,CX
        invoke  Delete_FSeek    ; FS. delete Fastseek Clusters                  ;AN000;
        invoke  RELEASE         ; Free any data allocated
        POP     DX
        POP     [HIGH_SECTOR]                  ;F.C. >32mb                      ;AN000;
        JNC     GET_BUF_BACK
        POP     BX
        return                  ; Screw up

GET_BUF_BACK:

        MOV     [ALLOWED],allowed_RETRY + allowed_FAIL
        XOR     AL,AL
        invoke  GETBUFFR        ; Get sector back
        POP     BX              ; Get offset back
        retc
        invoke  SET_BUF_AS_DIR
        ADD     BX,WORD PTR [CURBUF]    ; Correct it for new buffer
        MOV     SI,BX
        ADD     SI,dir_first    ; Get corrected SI
RET1:
        CLC
        return
EndProc FREEENT

;
; CHECK_VIRT_OPEN checks to see if we had performed a "virtual open" (by
; examining the flag [VIRTUAL_OPEN] to see if it is 1). If we did, then
; it calls Dev_Close_SFT to decrement the ref. count. It also resets the
; flag [VIRTUAL_OPEN].
; No registers affected (including flags).
; On input, [THISSFT] points to current SFT.
;
        Procedure CHECK_VIRT_OPEN,NEAR
        DOSAssume   CS,<DS>,"Check_Virt_Open"

        PUSH    AX
        lahf                    ; preserve flags
        CMP     [VIRTUAL_OPEN],0
        JZ      ALL_CLOSED
        mov     [VIRTUAL_OPEN],0        ; reset flag
        SaveReg <ES,DI>
        LES     DI,[THISSFT]
        INVOKE  DEV_CLOSE_SFT
        RestoreReg <DI,ES>

ALL_CLOSED:
        sahf                    ; restore flags
        POP     AX
        return

EndProc CHECK_VIRT_OPEN


CODE    ENDS
    END
