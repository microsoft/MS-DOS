;       SCCSID = @(#)rom.asm    1.1 85/04/10
TITLE   ROM - Miscellaneous routines
NAME    ROM
; Misc Low level routines for doing simple FCB computations, Cache
;       reads and writes, I/O optimization, and FAT allocation/deallocation
;
;   SKPCLP
;   FNDCLUS
;   BUFSEC
;   BUFRD
;   BUFWRT
;   NEXTSEC
;   OPTIMIZE
;   FIGREC
;   ALLOCATE
;   RESTFATBYT
;   RELEASE
;   RELBLKS
;   GETEOF
;
;   Modification history:
;
;       Created: ARR 30 March 1983
;

;
; get the appropriate segment definitions
;
.xlist
include dosseg.asm
include fastseek.inc			       ; DOS 4.00
include fastxxxx.inc			       ; DOS 4.00
include version.inc

CODE    SEGMENT BYTE PUBLIC  'CODE'
        ASSUME  SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
include EA.inc
.cref
.list

        i_need  CLUSNUM,WORD
        i_need  NEXTADD,WORD
        i_need  LASTPOS,WORD
        i_need  SECCLUSPOS,BYTE
        i_need  FATBYT,WORD
        i_need  THISSFT,DWORD
        i_need  TRANS,BYTE
        i_need  BYTCNT1,WORD
        i_need  CURBUF,DWORD
        i_need  BYTSECPOS,WORD
        i_need  DMAADD,WORD
        i_need  SECPOS,DWORD                         ;F.C. >32mb
        i_need  VALSEC,DWORD                         ;F.C. >32mb
        i_need  ALLOWED,BYTE
        i_need  FSeek_drive,BYTE                     ; DOS 3.4
        i_need  FSeek_firclus,WORD                   ; DOS 3.4
        i_need  FSeek_logclus,WORD                   ; DOS 3.4
        i_need  FSeek_logsave,WORD                   ; DOS 3.4
        i_need  FastSeekFlg,BYTE                     ; DOS 3.4
        i_need  XA_condition,BYTE                    ; DOS 3.4
        i_need  HIGH_SECTOR,WORD                     ; DOS 3.4
        i_need  DISK_FULL,BYTE                       ; DOS 3.4
        i_need  Temp_VAR2,WORD                       ; DOS 3.4



Break   <FNDCLUS -- Skip over allocation units>

; Inputs:
;       CX = No. of clusters to skip
;       ES:BP = Base of drive parameters
;       [THISSFT] point to SFT
; Outputs:
;       BX = Last cluster skipped to
;       CX = No. of clusters remaining (0 unless EOF)
;       DX = Position of last cluster
;       Carry set if error (currently user FAILed to I 24)
; DI destroyed. No other registers affected.

        procedure   FNDCLUS,NEAR
        DOSAssume   CS,<DS>,"FndClus"
        ASSUME  ES:NOTHING

        Assert      ISDPB,<ES,BP>,"FndCLus"
;; 10/31/86 FastSeek
        PUSH    ES
        LES     DI,[THISSFT]
        Assert      ISSFT,<ES,DI>,"FndClus"
        MOV     [FSeek_logclus],CX                ; presume CX is the position  ;AN000;
        MOV     BX,ES:[DI.sf_lstclus]
        MOV     DX,ES:[DI.sf_cluspos]
;; 10/31/86 FastSeek
        OR      BX,BX
        JNZ     YCLUS
        JMP     NOCLUS
YCLUS:
        SUB     CX,DX
        JNB     FINDIT
        ADD     CX,DX
        XOR     DX,DX
        MOV     BX,ES:[DI.sf_firclus]
FINDIT:
;; 10/31/86 FastSeek


        POP     ES
        OR      CX,CX
        JNZ     skpclp
        JMP     RET10

entry   SKPCLP
        TEST    [FastSeekflg],Fast_yes            ; fastseek installed?         ;AN000;
        JZ      do_norm                           ; no                          ;AN000;
        TEST    [FastSeekflg],FS_begin            ; do fastseek                 ;AN000;
        JZ      do_norm                           ; no                          ;AN000;
        TEST    [FastSeekflg],FS_insert           ; is in insert mode ?         ;AN000;
        JNZ     do_norm                           ; yes                         ;AN000;
        MOV     [Temp_Var2],BX                    ; save physical cluster       ;AN000;
                                                  ; PTR P005079
SKPCLP2:
        invoke  FastSeek_Lookup                   ; ask for next cluster #      ;AN000;
        JNC     clusfound                         ; yes, we got it              ;AN000;
        CMP     DI,1                              ; valid drive ,e.g. C,D...    ;AN000;
        JNZ     par_found                         ; yes,                        ;AN000;
        AND     [FastSeekflg],Fast_yes            ; no more, fastseek           ;AN000;
        JMP     SHORT do_norm                                                   ;AN000;
                                                                                ;AN000;
par_found:
        CALL    FS_Trunc_EOF                      ; check EOF and truncate      ;AN000;
        JNC     SKPCLP2                           ; redo lookup                 ;AN000;
noteof:
        OR      [FastSeekflg],FS_insert           ; no, start to insert         ;AN000;
        CMP     DX,[FSeek_logsave]                ; is current better than new? ;AN000;
        JBE     OnCache                           ; no, let's use new           ;AN000;
        MOV     [FSeek_logclus],DX                ; use current                 ;AN000;
        MOV     BX,[Temp_Var2]                    ; retore pysical cluster      ;AN000;
        MOV     DI,BX                             ; insert cureent cluster      ;AN000;
        invoke  FastSeek_Insert                   ; insert cluster # to         ;AN000;
        INC     [FSeek_logclus]                   ; get next inserted position  ;AN000;
        JMP     SHORT do_norm
OnCache:
        MOV     CX,[FSeek_logclus]                ; get the number of clusters  ;AN000;
        SUB     CX,[FSeek_logsave]                ; we need to skip             ;AN000;
        MOV     DX,[FSeek_logsave]                ; cluster position            ;AN000;
dodo:
        INC     [FSeek_logsave]                   ; get next inserted position  ;AN000;
        PUSH    [FSeek_logsave]                   ; logclus=logsave             ;AN000;
        POP     [FSeek_logclus]                                                 ;AN000;

do_norm:

        invoke  UNPACK
        retc

        invoke  FastSeek_Insert                   ; insert cluster # to         ;AN000;
cluss:                                                                          ;AN000;
        PUSH    BX                                ; FastSeek                    ;AN000;
        MOV     BX,DI
        Invoke  IsEOF
        POP     BX
        JAE     RET10
        XCHG    BX,DI
        INC     DX
        INC     [FSeek_logclus]                  ; increment for next inserted  ;AN000;
        LOOP    SKPCLPX
        JMP     short  RET10
SKPCLPX:
        JMP     SKPCLP
RET10:                                                                          ;AN000;
        AND     [FastSeekflg],FS_no_insert       ; clear insert mode
        CLC
        return
NOCLUS:
        POP     ES
        INC     CX
        DEC     DX
        CLC
        return
clusfound:
        MOV     DX,[FSeek_logclus]                ; get cluster position        ;AN000;
        MOV     BX,[FSeek_logsave]                ; bx=previous cluster # PTM   ;AN000;
        DEC     DX                                                              ;AN000;
        MOV     CX,1                              ; we found it                 ;AN000;
        JMP     cluss                                                           ;AN000;

EndProc FNDCLUS

Break  <BUFSEC -- BUFFER A SECTOR AND SET UP A TRANSFER>

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
;       Carry set if error (user FAILed to I 24)

        procedure   BUFSEC,NEAR
        DOSAssume   CS,<DS>,"BufSec"
        ASSUME  ES:NOTHING

        Assert      ISDPB,<ES,BP>,"BufSec"
        MOV     DX,[CLUSNUM]
        MOV     BL,[SECCLUSPOS]
        MOV     [ALLOWED],allowed_FAIL + allowed_RETRY + allowed_IGNORE
        CALL    FIGREC
        invoke  GETBUFFR
        retc
        MOV     BYTE PTR [TRANS],1      ; A transfer is taking place
        MOV     SI,[NEXTADD]
        MOV     DI,SI
        MOV     CX,[BYTCNT1]
        ADD     DI,CX
        MOV     [NEXTADD],DI
        LES     DI,[CURBUF]
        Assert  ISBUF,<ES,DI>,"BufSec"
        OR      ES:[DI.buf_flags],buf_isDATA
        LEA     DI,[DI].BUFINSIZ        ; Point to buffer
        ADD     DI,[BYTSECPOS]
        CLC
        return
EndProc BUFSEC

Break   <BUFRD, BUFWRT -- PERFORM BUFFERED READ AND WRITE>

; Do a partial sector read via one of the system buffers
; ES:BP Points to DPB
; Carry set if error (currently user FAILed to I 24)

        procedure   BUFRD,NEAR
        DOSAssume   CS,<DS>,"BufRd"
        ASSUME  ES:NOTHING

        Assert      ISDPB,<ES,BP>,"BufRd"
        PUSH    ES
        MOV     AX,0
        CALL    BUFSEC
        JNC     BUF_OK
BUF_IO_FAIL:
        POP     ES
        JMP     SHORT RBUFPLACED

BUF_OK:
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
        Assert  ISBUF,<DS,DI>,"BufRD/EvenRD"
        LEA     BX,[DI.BufInSiz]
        SUB     SI,BX                   ; Position in buffer
        invoke  PLACEBUF
        Assert  ISDPB,<ES,BP>,"BufRD/EvenRD"
        CMP     SI,ES:[BP.dpb_sector_size] ; Read Last byte?
        JB      RBUFPLACEDC             ; No, leave buf where it is
        invoke  PLACEHEAD               ; Make it prime candidate for chucking
                                        ;  even though it is MRU.
RBUFPLACEDC:
        CLC
RBUFPLACED:
        PUSH    SS
        POP     DS
        return
EndProc BUFRD

; Do a partial sector write via one of the system buffers
; ES:BP Points to DPB
; Carry set if error (currently user FAILed to I 24)

        procedure   BUFWRT,NEAR
        DOSAssume   CS,<DS>,"BufWrt"
        ASSUME  ES:NOTHING

        Assert      ISDPB,<ES,BP>,"BufWrt"
        MOV     AX,WORD PTR [SECPOS]
        ADD     AX,1            ; Set for next sector
        MOV     WORD PTR [SECPOS],AX      ;F.C. >32mb                           ;AN000;
        ADC     WORD PTR [SECPOS+2],0     ;F.C. >32mb                           ;AN000;
        MOV     AX,WORD PTR [SECPOS+2]    ;F.C. >32mb                           ;AN000;
        CMP     AX,WORD PTR [VALSEC+2]    ;F.C. >32mb                           ;AN000;
        MOV     AL,1                      ;F.C. >32mb                           ;AN000;
        JA      NOREAD                    ;F.C. >32mb                           ;AN000;
        JB      doread                    ;F.C. >32mb                           ;AN000;
        MOV     AX,WORD PTR [SECPOS]      ;F.C. >32mb                           ;AN000;
        CMP     AX,WORD PTR [VALSEC]     ; Has sector been written before?
        MOV     AL,1
        JA      NOREAD          ; Skip preread if SECPOS>VALSEC
doread:
        XOR     AL,AL
NOREAD:
        PUSH    ES
        CALL    BUFSEC
        JC      BUF_IO_FAIL
        MOV     DS,[DMAADD+2]
ASSUME  DS:NOTHING
        SHR     CX,1
        JNC     EVENWRT
        MOVSB
EVENWRT:
        REP     MOVSW
        POP     ES
        LDS     BX,[CURBUF]
        Assert  ISBUF,<DS,BX>,"BufWrt/EvenWrt"

        TEST    [BX.buf_flags],buf_dirty  ;LB. if already dirty                 ;AN000;
        JNZ     yesdirty                  ;LB.    don't increment dirty count   ;AN000;
        invoke  INC_DIRTY_COUNT           ;LB.                                  ;AN000;
        OR      [BX.buf_flags],buf_dirty
yesdirty:
        LEA     SI,[BX.BufInSiz]
        SUB     DI,SI                   ; Position in buffer
        MOV     SI,DI
        MOV     DI,BX
        invoke  PLACEBUF
        Assert  ISDPB,<ES,BP>,"BufWrt/EvenWrt"
        CMP     SI,ES:[BP.dpb_sector_size]  ; Written last byte?
        JB      WBUFPLACED              ; No, leave buf where it is
        invoke  PLACEHEAD               ; Make it prime candidate for chucking
                                        ;  even though it is MRU.
WBUFPLACED:
        CLC
        PUSH    SS
        POP     DS
        return
EndProc BUFWRT

Break   <NEXTSEC -- Compute next sector to read or write>

; Compute the next sector to read or write
; ES:BP Points to DPB

        procedure   NEXTSEC,NEAR
        DOSAssume   CS,<DS>,"NextSec"
        ASSUME  ES:NOTHING

        Assert      ISDPB,<ES,BP>,"NextSec"
        TEST    BYTE PTR [TRANS],-1
        JZ      CLRET
        MOV     AL,[SECCLUSPOS]
        INC     AL
        CMP     AL,ES:[BP.dpb_cluster_mask]
        JBE     SAVPOS
        MOV     BX,[CLUSNUM]
        Invoke  IsEOF
        JAE     NONEXT
;; 11/5/86 FastSeek
        TEST    [FastSeekflg],Fast_yes            ; fastseek installed?         ;AN000;
        JZ      do_norm2                          ; no                          ;AN000;
        PUSH    [LASTPOS]               ; save logical cluster #                ;AN000;
        POP     [FSeek_logclus]                                                 ;AN000;
        INC     [FSeek_logclus]         ; get next cluster                      ;AN000;
                                                                                ;AN000;
        TEST    [FastSeekflg],FS_begin  ; from R/W                              ;AN000;
        JZ      do_norm2                ; no                                    ;AN000;
look2:                                                                          ;AN000;
        invoke  FastSeek_Lookup         ; call lookup                           ;AN000;
        JNC     clusgot                 ; found one                             ;AN000;

        CMP     DI,1                              ; valid drive ,e.g. C,D...    ;AN000;
        JNZ     parfound2                         ; yes,                        ;AN000;
        AND     [FastSeekflg],Fast_yes            ; no more, fastseek           ;AN000;
        JMP     SHORT do_norm2                                                  ;AN000;
parfound2:
        CALL    FS_TRUNC_EOF            ; check EOF                             ;AN000;
        MOV     BX,[CLUSNUM]            ; don't need partially found cluster
        OR      [FastSeekflg],FS_insert ; prepared for cluster insertion        ;AN000;
                                        ; use the old bx                        ;AN000;
                                                                                ;AN000;
do_norm2:
        invoke  UNPACK
        JC      NONEXT
        invoke  FastSeek_Insert         ; call insert                           ;AN000;
        AND     [FastSeekflg],FS_no_insert  ; clear insert flag                 ;AN000;
                                                                                ;AN000;
clusgot:
;; 11/5/86 FastSeek
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
EndProc NEXTSEC

Break   <OPTIMIZE -- DO A USER DISK REQUEST WELL>

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
;       DX = Physical sector address            (LOW)
;       [HIGH_SECTOR] = Physical sector address (HIGH)
;       DI = Next cluster
;       [CLUSNUM] = Last cluster accessed
;       [NEXTADD] updated
;       Carry set if error (currently user FAILed to I 24)
; ES:BP unchanged. Note that segment of transfer not set.

        procedure   OPTIMIZE,NEAR
        DOSAssume   CS,<DS>,"Optimize"
        ASSUME  ES:NOTHING

        Assert      ISDPB,<ES,BP>,"Optimize"
        PUSH    DX
        PUSH    BX
        MOV     AL,ES:[BP.dpb_cluster_mask]
        INC     AL              ; Number of sectors per cluster
        MOV     AH,AL
        SUB     AL,DL           ; AL = Number of sectors left in first cluster
        MOV     DX,CX
        MOV     CX,0
;;; 11/5/86 FastSeek
        PUSH    [LASTPOS]               ; save logical cluster #                ;AN000;
        POP     [FSeek_logclus]                                                 ;AN000;
        INC     [FSeek_logclus]         ; get next cluster                      ;AN000;
                                                                                ;AN000;
OPTCLUS:
; AL has number of sectors available in current cluster
; AH has number of sectors available in next cluster
; BX has current physical cluster
; CX has number of sequential sectors found so far
; DX has number of sectors left to transfer
; ES:BP Points to DPB
; ES:SI has FAT pointer

        TEST    [FastSeekflg],Fast_yes            ; fastseek installed?         ;AN000;
        JZ      do_norm3                          ; no                          ;AN000;
        TEST    [FastSeekflg],FS_begin            ; from R/W                    ;AN000;
        JZ      do_norm3                          ; no                          ;AN000;
        TEST    [FastSeekflg],FS_insert           ; is in insert mode ?         ;AN000;
        JNZ     do_norm3                          ; yes                         ;AN000;
        invoke  FastSeek_Lookup                   ; call lookup                 ;AN000;
        JNC     clusgot2                          ; found one                   ;AN000;

        CMP     DI,1                              ; valid drive ,e.g. C,D...    ;AN000;
        JNZ     par_found3                        ; yes,                        ;AN000;
        AND     [FastSeekflg],Fast_yes            ; no more, fastseek           ;AN000;
        JMP     SHORT do_norm3                                                  ;AN000;
par_found3:
        PUSH    BX
        CALL    FS_TRUNC_EOF                      ; file entry not existing     ;AN000;
        POP     BX                                                              ;AN000;
        OR      [FastSeekflg],FS_insert           ; prepare for insertion       ;AN000;
                                                  ; use old bx                  ;AN000;
do_norm3:
        invoke  UNPACK
        JC      OP_ERR
clusgot2:
        invoke  FastSeek_Insert         ; call insert                           ;AN000;
        INC     [FSeek_logclus]         ; insert to next position               ;AN000;
;;; 11/5/86 FastSeek                                                            ;AN000;
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
        AND     [FastSeekflg],FS_no_insert  ; clear insert flag
        CLC
        return

OP_ERR:
        ADD     SP,4
        AND     [FastSeekflg],FS_no_insert  ; clear insert flag
        STC
        return

BLKDON:
        SUB     CX,DX           ; Number of sectors in cluster we don't want
        SUB     AH,CL           ; Number of sectors in cluster we accepted
        DEC     AH              ; Adjust to mean position within cluster
        MOV     [SECCLUSPOS],AH
        MOV     CX,DX           ; Anyway, make the total equal to the request
        JMP     SHORT FINCLUS
EndProc OPTIMIZE

Break   <FIGREC -- Figure sector in allocation unit>

; Inputs:
;       DX = Physical cluster number
;       BL = Sector postion within cluster
;       ES:BP = Base of drive parameters
; Outputs:
;       DX = physical sector number           (LOW)
;       [HIGH_SECTOR] Physical sector address (HIGH)
; No other registers affected.

        procedure   FIGREC,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

        Assert      ISDPB,<ES,BP>,"FigRec"
        PUSH    CX
        MOV     CL,ES:[BP.dpb_cluster_shift]
        DEC     DX
        DEC     DX
        MOV     [HIGH_SECTOR],0              ;F.C. >32mb
        OR      CL,CL                        ;F.C. >32mb
        JZ      noshift                      ;F.C. >32mb
        XOR     CH,CH                        ;F.C. >32mb
rotleft:                                     ;F.C. >32mb
        CLC                                  ;F.C. >32mb
        RCL     DX,1                         ;F.C. >32mb
        RCL     [HIGH_SECTOR],1              ;F.C. >32mb
        LOOP    rotleft                      ;F.C. >32mb
noshift:

;       SHL     DX,CL
        OR      DL,BL
        ADD     DX,ES:[BP.dpb_first_sector]
        ADC     [HIGH_SECTOR],0              ;F.C. >32mb
        POP     CX
        return
EndProc FIGREC

Break   <ALLOCATE -- Assign disk space>

;***    ALLOCATE - Allocate Disk Space
;
;   ALLOCATE is called to allocate disk clusters.  The new clusters are
;   FAT-chained onto the end of the existing file.
;
;   The DPB contains the cluster # of the last free cluster allocated
;   (dpb_next_free).  We start at this cluster and scan towards higher
;   numbered clusters, looking for the necessary free blocks.
;
;   Once again, fancy terminology gets in the way of corrct coding.  When
;   using next_free, start scanning AT THAT POINT and not the one following it.
;   This fixes the boundary condition bug when only free = next_free = 2.
;
;       If we get to the end of the disk without satisfaction:
;
;           if (dpb_next_free == 2) then we've scanned the whole disk.
;               return (insufficient_disk_space)
;           ELSE
;               dpb_next_free = 2; start scan over from the beginning.
;
;   Note that there is no multitasking interlock.  There is no race when
;   examining the entrys in an in-core FAT block since there will be no
;   context switch.  When UNPACK context switches while waiting for a FAT read
;   we are done with any in-core FAT blocks, so again there is no race.  The
;   only special concern is that V2 and V3 MSDOS left the last allocated
;   cluster as "00"; marking it EOF only when the entire alloc request was
;   satisfied.  We can't allow another activation to think this cluster is
;   free, so we give it a special temporary mark to show that it is, indeed,
;   allocated.
;
;   Note that when we run out of space this algorithem will scan from
;   dpb_next_free to the end, then scan from cluster 2 through the end,
;   redundantly scanning the later part of the disk.  This only happens when
;   we run out of space, so sue me.
;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  A  T  T  E  R  S  O  N                ;
;                                                                          ;
;   The use of FATBYT and RESTFATBYT is somewhat mysterious.  Here is the
;   explanation:
;
;   In the NUL file case (sf_firclus currently 0) ALLOCATE is called with
;   entry BX = 0.  What needs to be done in this case is to stuff the cluster
;   number of the first cluster allocated in sf_firclus when the ALLOCATE is
;   complete.  THIS VALUE IS SAVED TEMPORARILY IN CLUSTER 0, HENCE THE CURRENT
;   VALUE IN CLUSTER 0 MUST BE SAVED AND RESTORED.  This is a side effect of
;   the fact that PACK and UNPACK don't treat requests for clusters 0 and 1 as
;   errors.  This "stuff" is done by the call to PACK which is right before
;   the
;           LOOP    findfre         ; alloc more if needed
;   instruction when the first cluster is allocated to the nul file.  The
;   value is recalled from cluster 0 and stored at sf_firclus at ads4:
;
;   This method is obviously useless (because it is non-reentrant) for
;   multitasking, and will have to be changed.  Storing the required value on
;   the stack is recommended.  Setting sf_firclus at the PACK of cluster 0
;   (instead of actually doing the PACK) is BAD because it doesn't handle
;   problems with INT 24 well.
;
;            C  A  V  E  A  T     P  A  T  T  E  R  S  O  N                ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;                                                                          ;
;       ENTRY   BX = Last cluster of file (0 if null file)
;               CX = No. of clusters to allocate
;               ES:BP = Base of drive parameters
;               [THISSFT] = Points to SFT
;
;       EXIT    'C' set if insufficient space
;                 [FAILERR] can be tested to see the reason for failure
;                 CX = max. no. of clusters that could be added to file
;               'C' clear if space allocated
;                 BX = First cluster allocated
;                 FAT is fully updated
;                 sf_FIRCLUS field of SFT set if file was null
;
;       USES    ALL but SI, BP

        PROCEDURE   ALLOCATE,NEAR

        DOSAssume   CS,<DS>,"Allocate"
        ASSUME  ES:NOTHING

        Assert      ISDPB,<ES,BP>,"Allocate"
        PUSH    BX                      ; save (bx)
        XOR     BX,BX
        invoke  UNPACK
        MOV     [FATBYT],DI             ; save correct cluster 0 value
        POP     BX
        retc                            ; abort if error   [INTERR?]

        PUSH    CX
        PUSH    BX

        MOV     DX,BX
        Assert      ISDPB,<ES,BP>,"Allocate/Unpack"
        mov     bx,es:[bp.dpb_next_free]
        cmp     bx,2
        ja      findfre

;   couldn't find enough free space beyond dpb_next_free, or dpb_next_free is
;   <2 or >dpb_max_clus.  Reset it and restart the scan

ads1:
        Assert      ISDPB,<ES,BP>,"Alloc/ads1"
        mov     es:[bp.dpb_next_free],2
        mov     bx,1                    ; Counter next instruction so first
                                        ;       cluster examined is 2

;   Scanning both forwards and backwards for a free cluster
;
;       (BX) = forwards scan pointer
;       (CX) = clusters remaining to be allocated
;       (DX) = current last cluster in file
;       (TOS) = last cluster of file

FINDFRE:
        INC     BX
        Assert      ISDPB,<ES,BP>,"Alloc/findfre"
        CMP     BX,ES:[BP.dpb_max_cluster]
        JBE     aupk
        jmp     ads7            ; at end of disk
aupk:
        invoke  UNPACK          ; check out this cluster
        jc      ads4            ; FAT error             [INTERR?]
        jnz     findfre         ; not free, keep on truckin

;   Have found a free cluster.  Chain it to the file
;
;       (BX) = found free cluster #
;       (DX) = current last cluster in file

        mov     es:[bp.dpb_next_free],bx        ; next time start search here
        xchg    ax,dx           ; save (dx) in ax
        mov     dx,1            ; mark this free guy as "1"
        invoke  PACK            ; set special "temporary" mark
        jc      ads4            ; FAT error             [INTERR?]
        CMP     ES:[BP.dpb_free_cnt],-1 ; Free count valid?
        JZ      NO_ALLOC                ; No
        DEC     ES:[BP.dpb_free_cnt]    ; Reduce free count by 1
NO_ALLOC:
        xchg    ax,dx           ; (dx) = current last cluster in file
        XCHG    BX,DX
        MOV     AX,DX
        invoke  PACK            ; link free cluster onto file
                                ;  CAVEAT.. On Nul file, first pass stuffs
                                ;    cluster 0 with FIRCLUS value.
        jc      ads4            ; FAT error             [INTERR?]
        xchg    BX,AX           ; (BX) = last one we looked at
        mov     dx,bx           ; (dx) = current end of file
        LOOP    findfre         ; alloc more if needed

;   We've successfully extended the file.  Clean up and exit
;
;       (BX) = last cluster in file

        MOV     DX,0FFFFH
        invoke  PACK            ; mark last cluster EOF

;   Note that FAT errors jump here to clean the stack and exit.  this saves us
;   2 whole bytes.  Hope its worth it...
;
;       'C' set iff error
;       calling (BX) and (CX) pushed on stack

ads4:   POP     BX
        POP     CX              ; Don't need this stuff since we're successful
        retc
        invoke  UNPACK          ; Get first cluster allocated for return
                                ; CAVEAT... In nul file case, UNPACKs cluster 0.
        retc
        invoke  RESTFATBYT      ; Restore correct cluster 0 value
        retc
        XCHG    BX,DI           ; (DI) = last cluster in file upon our entry
        OR      DI,DI           ; clear 'C'
        retnz                   ; we were extending an existing file

;   We were doing the first allocation for a new file.  Update the SFT cluster
;   info
;; Extended Attributes
;       TEST    [XA_condition],XA_No_SFT      ;FT. don't update SFT when from   ;AN000;
;       JZ      dofastk                       ;FT. GetSet_XA                    ;AN000;
;       AND     [XA_condition],not XA_No_SFT  ;FT. clear the bit                ;AN000;
;       CLC                                   ;FT.                              ;AN000;
;       ret                                   ;FT.                              ;AN000;
;; 11/6/86 FastSeek
dofastk:
        PUSH    DX
        MOV     DL,ES:[BP.dpb_drive]              ; get drive #

        PUSH    ES
        LES     DI,[THISSFT]
        Assert  ISSFT,<ES,DI>,"Allocate/ads4"
        MOV     ES:[DI.sf_firclus],BX
        MOV     ES:[DI.sf_lstclus],BX

        TEST    [FastSeekflg],Fast_yes           ; fastseek installed
        JZ      do_norm5                         ; no
        TEST    [FastSeekflg],FS_begin           ; do fastseek
        JZ      do_norm5                          ; no
        PUSH    CX
        MOV     CX,BX                             ; set up firclus #
        MOV     [FSeek_firclus],BX                ; update firclus varible
        invoke  FastSeek_Open                     ; create this file entry
        POP     CX
do_norm5:
        POP     ES
;; 11/6/86 FastSeek
        POP     DX
        return


;** we're at the end of the disk, and not satisfied.  See if we've scanned ALL
;   of the disk...

ads7:   cmp     es:[bp.dpb_next_free],2
if not debug
        jz      tmplab2         ;
        jmp     ads1            ; start scan from front of disk
tmplab2:
else
        jz      tmplab
        jmp     ads1
tmplab:
endif

;   Sorry, we've gone over the whole disk, with insufficient luck.  Lets give
;   the space back to the free list and tell the caller how much he could have
;   had.  We have to make sure we remove the "special mark" we put on the last
;   cluster we were able to allocate, so it doesn't become orphaned.
;
;       (CX) = clusters remaining to be allocated
;       (TOS) = last cluster of file (before call to ALLOCATE)
;       (TOS+1) = # of clusters wanted to allocate


        POP     BX              ; (BX) = last cluster of file
        MOV     DX,0FFFFH
        invoke  RELBLKS         ; give back any clusters just alloced
        POP     AX              ; No. of clusters requested
                                ; Don't "retc". We are setting Carry anyway,
                                ;   Alloc failed, so proceed with return CX
                                ;   setup.
        SUB     AX,CX           ; AX=No. of clusters allocated
        invoke  RESTFATBYT      ; Don't "retc". We are setting Carry anyway,
                                ;   Alloc failed.
;       fmt     <>,<>,<"$p: disk full in allocate\n">
        MOV     [DISK_FULL],1   ;MS. indicating disk full
        STC
        return

EndProc ALLOCATE

; SEE ALLOCATE CAVEAT
;       Carry set if error (currently user FAILed to I 24)

        procedure   RESTFATBYT,NEAR
        DOSAssume   CS,<DS>,"RestFATByt"
        ASSUME  ES:NOTHING

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
EndProc RESTFATBYT

Break   <RELEASE -- DEASSIGN DISK SPACE>

; Inputs:
;       BX = Cluster in file
;       ES:BP = Base of drive parameters
; Function:
;       Frees cluster chain starting with [BX]
;       Carry set if error (currently user FAILed to I 24)
; AX,BX,DX,DI all destroyed. Other registers unchanged.

        procedure   RELEASE,NEAR
        DOSAssume   CS,<DS>,"Release"
        ASSUME  ES:NOTHING

        XOR     DX,DX
entry   RELBLKS
        DOSAssume   CS,<DS>,"RelBlks"
        Assert      ISDPB,<ES,BP>,"RelBlks"

;   Enter here with DX=0FFFFH to put an end-of-file mark in the first cluster
;   and free the rest in the chain.

        invoke  UNPACK
        retc
        retz
        MOV     AX,DI
        PUSH    DX
        invoke  PACK
        POP     DX
        retc
        OR      DX,DX
        JNZ     NO_DEALLOC              ; Was putting EOF mark
        CMP     ES:[BP.dpb_free_cnt],-1 ; Free count valid?
        JZ      NO_DEALLOC              ; No
        INC     ES:[BP.dpb_free_cnt]    ; Increase free count by 1
NO_DEALLOC:
        MOV     BX,AX
        dec     ax              ; check for "1"
        retz                    ; is last cluster of incomplete chain
        Invoke  IsEOF
        JB      RELEASE         ; Carry clear if JMP not taken
ret12:  return
EndProc RELEASE

Break   <GETEOF -- Find the end of a file>

; Inputs:
;       ES:BP Points to DPB
;       BX = Cluster in a file
;       DS = CS
; Outputs:
;       BX = Last cluster in the file
;       Carry set if error (currently user FAILed to I 24)
; DI destroyed. No other registers affected.

        procedure   GETEOF,NEAR
        DOSAssume   CS,<DS>,"GetEOF"
        ASSUME  ES:NOTHING

        Assert      ISDPB,<ES,BP>,"GetEof"
        invoke  UNPACK
        retc
        PUSH    BX
        MOV     BX,DI
        Invoke  IsEOF
        POP     BX
        JAE     RET12           ; Carry clear if jmp
        MOV     BX,DI
        JMP     GETEOF
EndProc GETEOF

Break   <FS_TRUNC_EOF - truncate EOF for Fastseek>

; Inputs:
;       ES:BP Points to DPB
;       BX = Cluster in a file
; Functions: if BX=EOF then truncate it from Fastseek Cache
; Outputs:
;       carry set: not EOF
;       carry clear: EOF and do truncate

        procedure   FS_TRUNC_EOF,NEAR
        ASSUME  ES:NOTHING,DS:NOTHING

        MOV     BX,DI                             ; get beginning physical#     ;AN000;
        invoke  IsEOF                             ; is EOF                      ;AN000;
        JB      noteof2                           ; no                          ;AN000;
        PUSH    [FSeek_logclus]                   ;                             ;AN000;
        PUSH    [FSeek_logsave]                   ; logclus=logsave             ;AN000;
        POP     [FSeek_logclus]                   ; delete EOF                  ;AN000;
        invoke  FastSeek_Truncate                 ;                             ;AN000;
        POP     [FSeek_logclus]                   ; redo the look up            ;AN000;
        CLC                                                                     ;AN000;
noteof2:                                                                        ;AN000;
        return                                                                  ;AN000;
EndProc FS_TRUNC_EOF                                                            ;AN000;

CODE    ENDS
    END
