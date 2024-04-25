;       SCCSID = @(#)msdata.asm 1.8 85/09/12
        AsmVars <Kanji, Debug, Redirector, ShareF>
 
Break <Uninitialized data overlayed by initialization code>
 
DATA    SEGMENT WORD PUBLIC 'DATA'
; Init code overlaps with data area below
 
        ORG     0
PUBLIC MSDAT001S,MSDAT001E
MSDAT001S       label byte
 
        I_am    TIMEBUF,6               ; Time read from clock device
        I_am    DEVIOBUF,2              ; Buffer for I/O under file assignment
;
; The following areas are used as temp buffer in EXEC system call
;
        I_am    OPENBUF,128             ; buffer for name operations
        I_am    RenBuf,128              ; buffer for rename destination
; Buffer for search calls
        I_am    SEARCHBUF,53            ; internal search buffer
        I_am    DummyCDS,curdirLen
;
; End of contiguous buffer
;
 
;
; Temporary directory entry for use by many routines.  Device directory
; entries (bogus) are built here.
;
        PUBLIC  DevFCB
DEVFCB  LABEL   BYTE                    ; Uses NAME1, NAME2, combined
; WARNING..  do not alter position of NAME1 relative to DEVFCB
; without first examining BUILD_DEVICE_ENT. Look carefully at DOS_RENAME
; as well as it is the only guy who uses NAME2 and DESTSTART.
        I_am    NAME1,12                ; File name buffer
        I_am    NAME2,13                ;
        I_am    DESTSTART,WORD          ;
        DB      ((SIZE DIR_ENTRY) - ($ - DEVFCB)) DUP (?)
;
; End Temporary directory entry.
;
        I_am    ATTRIB,BYTE             ; storage for file attributes
        I_am    EXTFCB,BYTE             ; TRUE => extended FCB in use
        I_am    SATTRIB,BYTE            ; Storage for search attributes
        I_AM    open_access,BYTE        ; access of open system call
        I_am    FoundDel,BYTE           ; true => file was deleted
        I_am    Found_dev,BYTE          ; true => search found a device
        I_am    fSplice,BYTE            ; true => do a splice in transpath
        I_am    fSharing,BYTE           ; TRUE => no redirection
        I_am    SECCLUSPOS,BYTE         ; Position of first sector within cluster
        I_am    TRANS,BYTE              ;
        I_am    READOP,BYTE             ;
        I_am    THISDRV,BYTE            ;
        I_am    CLUSFAC,BYTE            ;
        I_am    CLUSSPLIT,BYTE          ;
        I_am    INSMODE,BYTE            ; true => insert mode in buffered read
        I_am    cMeta,BYTE              ; count of meta'ed components found
        I_am    VOLID,BYTE              ;
        I_am    exit_type,BYTE          ; type of exit...
 
        EVEN
 
; WARNING - the following two items are accessed as a word
        I_am    CREATING,BYTE           ; true => creating a file
        I_am    DELALL,BYTE             ; true => deleting everything
 
        I_am    EXITHOLD,DWORD          ; Temp location for proc terminate
        I_am    user_SP,WORD            ; User SP for system call
        I_am    user_SS,WORD            ; User SS for system call
        I_am    CONTSTK,WORD            ;
        I_am    THISDPB,DWORD           ;
        I_am    CLUSSAVE,WORD           ;
        I_am    CLUSSEC,DWORD           ;>32mb                                  AC0000
        I_am    PREREAD,WORD            ; 0 means preread; 1 means optional
        I_am    FATBYT,WORD             ; Used by ALLOCATE
        I_am    FATBYTE,WORD            ; Used by $SLEAZEFUNC
        I_am    DEVPT,DWORD             ;
        I_am    THISSFT,DWORD           ; Address of user SFT
        I_am    THISCDS,DWORD           ; Address of current CDS
        I_am    THISFCB,DWORD           ; Address of user FCB
        I_am    SFN,WORD,<-1>           ; SystemFileNumber found for accessfile
        I_am    JFN,WORD                ; JobFileNumber found for accessfile
        I_am    PJFN,DWORD              ; PointerJobFileNumber found for accessfile
        I_am    WFP_START,WORD          ;
        I_am    REN_WFP,WORD            ;
        I_am    CURR_DIR_END,WORD       ;
        I_am    NEXTADD,WORD            ;
        I_am    LASTPOS,WORD            ;
        I_am    CLUSNUM,WORD            ;
        I_am    DIRSEC,DWORD            ;>32mb                                  AC0000
        I_am    DIRSTART,WORD           ;
        I_am    SECPOS,DWORD       ;>32mb Position of first sector accessed
        I_am    VALSEC,DWORD       ;>32mb Number of valid (previously written)
                                        ; sectors
        I_am    BYTSECPOS,WORD          ; Position of first byte within sector
        I_am    BYTPOS,4                ; Byte position in file of access
        I_am    BYTCNT1,WORD            ; No. of bytes in first sector
        I_am    BYTCNT2,WORD            ; No. of bytes in last sector
        I_am    SECCNT,WORD             ; No. of whole sectors
        I_am    ENTFREE,WORD            ;
        I_am    ENTLAST,WORD            ;
        I_am    NXTCLUSNUM,WORD         ;
        I_am    GROWCNT,DWORD           ;
        I_am    CURBUF,DWORD            ;
        I_am    CONSft,DWORD            ; SFT of console swapped guy.
        I_am    SaveBX,WORD             ;
        I_am    SaveDS,WORD             ;
        I_am    restore_tmp,WORD        ; return address for restore world
        I_am    NSS,WORD
        I_am    NSP,WORD
        I_am    EXTOPEN_FLAG,WORD,<0>   ;FT. extended open input flag           ;AN000;
        I_am    EXTOPEN_ON,BYTE,<0>     ;FT. extended open conditional flag     ;AN000;
        I_am    EXTOPEN_IO_MODE,WORD,<0>;FT. extende open io mode               ;AN000;
        I_am    SAVE_DI,WORD            ;FT. extende open saved DI              ;AN000;
        I_am    SAVE_ES,WORD            ;FT. extende open saved ES              ;AN000;
        I_am    SAVE_DX,WORD            ;FT. extende open saved DX              ;AN000;
        I_am    SAVE_CX,WORD            ;FT. extende open saved CX              ;AN000;
        I_am    SAVE_BX,WORD            ;FT. extende open saved BX              ;AN000;
        I_am    SAVE_SI,WORD            ;FT. extende open saved SI              ;AN000;
        I_am    SAVE_DS,WORD            ;FT. extende open saved DS              ;AN000;
        I_am    HIGH_SECTOR,WORD,<0>    ;>32mb higher sector #                  ;AN000;
        I_am    HIGH_SECTOR_TEMP,WORD,<0>;>32mb high sector #                   ;AN000;
        I_am    DISK_FULL,BYTE          ;>32mb indicating disk full when 1      ;AN000;
        I_am    TEMP_VAR,WORD           ; temporary variable for everyone       ;AN000;
        I_am    TEMP_VAR2,WORD          ; temporary variable 2 for everyone     ;AN000;
        I_am    DrvErr,BYTE             ; used to save drive error              ;AN000;
        I_am    DOS34_FLAG,WORD,<0>     ; common flag for DOS 3.4               ;AN000;
        I_am    NO_FILTER_PATH,DWORD    ; pointer to orignal path               ;AN000;
        I_am    NO_FILTER_DPATH,DWORD   ; pointer to orignal path of destination;AN000;
        I_am   Callback_SS,WORD         ;AN000; call back SS for system call
        I_am   Callback_SP,WORD         ;AN000; call back SP for system call
        I_am   Callback_flag,BYTE,<0>   ;AN000; call back flag
 
 
; make those pushes fast!!!
EVEN
StackSize   =   180h                    ; gross but effective
;;;StackSize   =   300h                    ; This is a "trial" change IBM hasn't
;;;                                        ; made up their minds about
 
;
; WARNING!!!! DskStack may grow into AUXSTACK due to interrupt service.
; This is NO problem as long as AUXSTACK comes immediately before DSKSTACK
;
 
        PUBLIC  RENAMEDMA,AuxStack,DskStack,IOStack
RENAMEDMA   LABEL   BYTE                ; See DOS_RENAME
 
        DB      StackSize DUP (?)       ;
AuxStack    LABEL   BYTE
 
        DB      StackSize DUP (?)       ;
DskStack    LABEL   BYTE
 
        DB      StackSize DUP (?)       ;
IOStack LABEL   BYTE
 
 
; patch space for Boca folks.
; Say What????!!! This does NOT go into the swappable area!
; NOTE: We include the decl of ibmpatch in ms-dos even though it is not needed.
;       This allows the REDIRector to work on either IBM or MS-DOS.
 
PUBLIC  IBMPATCH
IBMPATCH    label byte
        I_am    PRINTER_FLAG,BYTE,<0>   ; [SYSTEM] status of PRINT utility
        I_am    VOLCHNG_FLAG,BYTE,<0>   ; [SYSTEM] true if volume label created
        I_am    VIRTUAL_OPEN,BYTE,<0>   ; [SYSTEM] non-zero if we opened a virtual file
 
; Following 4 variables moved to MSDATA.asm from MSTABLE.asm (P4986)
      I_am     FSeek_drive,BYTE         ;AN000; fastseek drive #
      I_am     FSeek_firclus,WORD       ;AN000; fastseek first cluster #
      I_am     FSeek_logclus,WORD       ;AN000; fastseek logical cluster #
      I_am     FSeek_logsave,WORD       ;AN000; fastseek returned log clus #
      I_am     ACT_PAGE,WORD,<-1>       ;;;;;;; ;BL ; active EMS page                       ;AN000;
 
 
SWAP_END    LABEL   BYTE
PUBLIC  SWAP_END
 
; THE FOLLOWING BYTE MUST BE HERE, IMMEDIATELY FOLLOWING SWAP_END. IT CANNOT
;   BE USED. If the size of the swap data area is ODD, it will be rounded up
;   to include this byte.
        DB      ?
 
            DB      (512+80+32-(SWAP_END-ibmpatch)) DUP (?)
 
MSDAT001e       label byte
 
.xall
 
DATA    ENDS
