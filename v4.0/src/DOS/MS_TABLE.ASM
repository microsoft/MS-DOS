;       SCCSID = @(#)mstable.asm        1.3 85/07/25
;       Revision history:
;         A000   version 4.0  Jan. 1988
;         A001   DCR 486 - Share installation for >32mb drives
;         A006   DCR 503 - fake version for IBMCACHE
;         A008   PTM 4070 - fake version for MS WINDOWS
.xlist
.xcref
include dosseg.asm
include EA.inc                           ;AN000;; for Extended Attributes
include fastopen.inc                     ;AN000;; for Extended Attributes
include dossym.inc
.cref
.list

        AsmVars <Kanji, Debug, Redirector, ShareF>

TABLE           SEGMENT BYTE PUBLIC 'TABLE'
TableZero   LABEL   BYTE

        PUBLIC  MSVERS
PUBLIC MSTAB001s,MSTAB001e
MSTAB001S       label byte

MSVERS  EQU     THIS WORD               ; MS-DOS version in hex for $GET_VERSION
MSMAJOR DB      MAJOR_VERSION
MSMINOR DB      MINOR_VERSION

        I_am    YRTAB,8,<200,166,200,165,200,165,200,165>   ; [SYSTEM]
        I_am    MONTAB,12,<31,28,31,30,31,30,31,31,30,31,30,31> ; [SYSTEM]

;
; This is the error code mapping table for INT 21 errors.  This table defines
; those error codes which are "allowed" for each system call.  If the error
; code ABOUT to be returned is not "allowed" for the call, the correct action
; is to return the "real" error via Extended error, and one of the allowed
; errors on the actual call.
;
; The table is organized as follows:
;
;    Each entry in the table is of variable size, but the first
;       two bytes are always:
;
;       Call#,Cnt of bytes following this byte
;
; EXAMPLE:
;       Call 61 (OPEN)
;
;       DB      61,5,12,3,2,4,5
;
;       61 is the AH INT 21 call value for OPEN.
;        5 indicates that there are 5 bytes after this byte (12,3,2,4,5).
;       Next five bytes are those error codes which are "allowed" on OPEN.
;       The order of these values is not important EXCEPT FOR THE LAST ONE (in
;       this case 5).  The last value will be the one returned on the call if
;       the "real" error is not one of the allowed ones.
;
; There are a number of calls (for instance all of the FCB calls) for which
;   there is NO entry.  This means that NO error codes are returned on this
;   call, so set up an Extended error and leave the current error code alone.
;
; The table is terminated by a call value of 0FFh

PUBLIC  I21_MAP_E_TAB
I21_MAP_E_TAB   LABEL   BYTE
    DB  International,2,error_invalid_function,error_file_not_found
    DB  MKDir,3,error_path_not_found,error_file_not_found,error_access_denied
    DB  RMDir,4,error_current_directory,error_path_not_found
    DB          error_file_not_found,error_access_denied
    DB  CHDir,2,error_file_not_found,error_path_not_found
    DB  Creat,4,error_path_not_found,error_file_not_found
    DB          error_too_many_open_files
    DB          error_access_denied
    DB  Open,6,error_path_not_found,error_file_not_found,error_invalid_access
    DB          error_too_many_open_files
    DB          error_not_dos_disk,error_access_denied
    DB  Close,1,error_invalid_handle
    DB  Read,2,error_invalid_handle,error_access_denied
    DB  Write,2,error_invalid_handle,error_access_denied
    DB  Unlink,3,error_path_not_found,error_file_not_found,error_access_denied
    DB  LSeek,2,error_invalid_handle,error_invalid_function
    DB  CHMod,4,error_path_not_found,error_file_not_found,error_invalid_function
    DB          error_access_denied
    DB  IOCtl,5,error_invalid_drive,error_invalid_data,error_invalid_function
    DB          error_invalid_handle,error_access_denied
    DB  XDup,2,error_invalid_handle,error_too_many_open_files
    DB  XDup2,2,error_invalid_handle,error_too_many_open_files
    DB  Current_Dir,2,error_not_DOS_disk,error_invalid_drive
    DB  Alloc,2,error_arena_trashed,error_not_enough_memory
    DB  Dealloc,2,error_arena_trashed,error_invalid_block
    DB  Setblock,3,error_arena_trashed,error_invalid_block,error_not_enough_memory
    DB  Exec,8,error_path_not_found,error_invalid_function,error_file_not_found
    DB          error_too_many_open_files,error_bad_format,error_bad_environment
    DB          error_not_enough_memory,error_access_denied
    DB  Find_First,3,error_path_not_found,error_file_not_found,error_no_more_files
    DB  Find_Next,1,error_no_more_files
    DB  Rename,5,error_not_same_device,error_path_not_found,error_file_not_found
    DB          error_current_directory,error_access_denied
    DB  File_Times,4,error_invalid_handle,error_not_enough_memory
    DB               error_invalid_data,error_invalid_function
    DB  AllocOper,1,error_invalid_function
    DB  CreateTempFile,4,error_path_not_found,error_file_not_found
    DB          error_too_many_open_files,error_access_denied
    DB  CreateNewFile,5,error_file_exists,error_path_not_found
    DB          error_file_not_found,error_too_many_open_files,error_access_denied
    DB  LockOper,4,error_invalid_handle,error_invalid_function
    DB          error_sharing_buffer_exceeded,error_lock_violation
    DB  GetExtCntry,2,error_invalid_function,error_file_not_found       ;DOS 3.3
    DB  GetSetCdPg,2,error_invalid_function,error_file_not_found        ;DOS 3.3
    DB  Commit,1,error_invalid_handle                                   ;DOS 3.3
    DB  ExtHandle,3,error_too_many_open_files,error_not_enough_memory
    DB              error_invalid_function
    DB  ExtOpen,10
    DB    error_path_not_found,error_file_not_found,error_invalid_access
    DB          error_too_many_open_files,error_file_exists,error_not_enough_memory
    DB          error_not_dos_disk,error_invalid_data
    DB              error_invalid_function,error_access_denied
    DB  GetSetMediaID,4,error_invalid_drive,error_invalid_data
    DB          error_invalid_function,error_access_denied
    DB  0FFh

;
; The following table defines CLASS ACTION and LOCUS info for the INT 21H
; errors.  Each entry is 4 bytes long:
;
;       Err#,Class,Action,Locus
;
; A value of 0FFh indicates a call specific value (ie.  should already
; be set).  AN ERROR CODE NOT IN THE TABLE FALLS THROUGH TO THE CATCH ALL AT
; THE END, IT IS ASSUMES THAT CLASS, ACTION, LOCUS IS ALREADY SET.
ErrTab  Macro   err,class,action,locus
ifidn <locus>,<0FFh>
    DB  error_&err,errCLASS_&class,errACT_&action,0FFh
ELSE
    DB  error_&err,errCLASS_&class,errACT_&action,errLOC_&locus
ENDIF
ENDM

PUBLIC  ERR_TABLE_21
ERR_TABLE_21    LABEL   BYTE
    ErrTab  invalid_function,       Apperr,     Abort,      0FFh
    ErrTab  file_not_found,         NotFnd,     User,       Disk
    ErrTab  path_not_found,         NotFnd,     User,       Disk
    ErrTab  too_many_open_files,    OutRes,     Abort,      Unk
    ErrTab  access_denied,          Auth,       User,       0FFh
    ErrTab  invalid_handle,         Apperr,     Abort,      Unk
    ErrTab  arena_trashed,          Apperr,     Panic,      Mem
    ErrTab  not_enough_memory,      OutRes,     Abort,      Mem
    ErrTab  invalid_block,          Apperr,     Abort,      Mem
    ErrTab  bad_environment,        Apperr,     Abort,      Mem
    ErrTab  bad_format,             BadFmt,     User,       Unk
    ErrTab  invalid_access,         Apperr,     Abort,      Unk
    ErrTab  invalid_data,           BadFmt,     Abort,      Unk
    ErrTab  invalid_drive,          NotFnd,     User,       Disk
    ErrTab  current_directory,      Auth,       User,       Disk
    ErrTab  not_same_device,        Unk,        User,       Disk
    ErrTab  no_more_files,          NotFnd,     User,       Disk
    ErrTab  file_exists,            Already,    User,       Disk
    ErrTab  sharing_violation,      Locked,     DlyRet,     Disk
    ErrTab  lock_violation,         Locked,     DlyRet,     Disk
    ErrTab  out_of_structures,      OutRes,     Abort,      0FFh
    ErrTab  invalid_password,       Auth,       User,       Unk
    ErrTab  cannot_make,            OutRes,     Abort,      Disk
    ErrTab  Not_supported,          BadFmt,     User,       Net
    ErrTab  Already_assigned,       Already,    User,       Net
    ErrTab  Invalid_Parameter,      BadFmt,     User,       Unk
    ErrTab  FAIL_I24,               Unk,        Abort,      Unk
    ErrTab  Sharing_buffer_exceeded,OutRes,     Abort,      Mem
    ErrTab  Handle_EOF,             OutRes,     Abort,      Unk     ;AN000;
    ErrTab  Handle_DISK_FULL,       OutRes,     Abort,      Unk     ;AN000;
    ErrTab  sys_comp_not_loaded,    Unk,        Abort,      Disk    ;AN001;
    DB      0FFh,                   0FFH,       0FFH,       0FFh

;
; The following table defines CLASS ACTION and LOCUS info for the INT 24H
; errors.  Each entry is 4 bytes long:
;
;       Err#,Class,Action,Locus
;
; A Locus value of 0FFh indicates a call specific value (ie.  should already
; be set).  AN ERROR CODE NOT IN THE TABLE FALLS THROUGH TO THE CATCH ALL AT
; THE END.

PUBLIC  ERR_TABLE_24
ERR_TABLE_24    LABEL   BYTE
    ErrTab  write_protect,          Media,      IntRet,     Disk
    ErrTab  bad_unit,               Intrn,      Panic,      Unk
    ErrTab  not_ready,              HrdFail,    IntRet,     0FFh
    ErrTab  bad_command,            Intrn,      Panic,      Unk
    ErrTab  CRC,                    Media,      Abort,      Disk
    ErrTab  bad_length,             Intrn,      Panic,      Unk
    ErrTab  Seek,                   HrdFail,    Retry,      Disk
    ErrTab  not_DOS_disk,           Media,      IntRet,     Disk
    ErrTab  sector_not_found,       Media,      Abort,      Disk
    ErrTab  out_of_paper,           TempSit,    IntRet,     SerDev
    ErrTab  write_fault,            HrdFail,    Abort,      0FFh
    ErrTab  read_fault,             HrdFail,    Abort,      0FFh
    ErrTab  gen_failure,            Unk,        Abort,      0FFh
    ErrTab  sharing_violation,      Locked,     DlyRet,     Disk
    ErrTab  lock_violation,         Locked,     DlyRet,     Disk
    ErrTab  wrong_disk,             Media,      IntRet,     Disk
    ErrTab  not_supported,          BadFmt,     User,       Net
    ErrTab  FCB_unavailable,        Apperr,     Abort,      Unk
    ErrTab  Sharing_buffer_exceeded,OutRes,     Abort,      Mem
    DB      0FFh,                   errCLASS_Unk, errACT_Panic, 0FFh

;
; We need to map old int 24 errors and device driver errors into the new set
; of errors.  The following table is indexed by the new errors
;
Public  ErrMap24
ErrMap24    Label   BYTE
    DB  error_write_protect             ;   0
    DB  error_bad_unit                  ;   1
    DB  error_not_ready                 ;   2
    DB  error_bad_command               ;   3
    DB  error_CRC                       ;   4
    DB  error_bad_length                ;   5
    DB  error_Seek                      ;   6
    DB  error_not_DOS_disk              ;   7
    DB  error_sector_not_found          ;   8
    DB  error_out_of_paper              ;   9
    DB  error_write_fault               ;   A
    DB  error_read_fault                ;   B
    DB  error_gen_failure               ;   C
    DB  error_gen_failure               ;   D   RESERVED
    DB  error_gen_failure               ;   E   RESERVED
    DB  error_wrong_disk                ;   F

Public  ErrMap24End
ErrMap24End LABEL   BYTE


        PUBLIC  DISPATCH,MAXCALL,MAXCOM

MAXCALL DB      VAL1
MAXCOM  DB      VAL2

; Standard Functions
DISPATCH    LABEL WORD
        short_addr  $ABORT                          ;  0      0
        short_addr  $STD_CON_INPUT                  ;  1      1
        short_addr  $STD_CON_OUTPUT                 ;  2      2
        short_addr  $STD_AUX_INPUT                  ;  3      3
        short_addr  $STD_AUX_OUTPUT                 ;  4      4
        short_addr  $STD_PRINTER_OUTPUT             ;  5      5
        short_addr  $RAW_CON_IO                     ;  6      6
        short_addr  $RAW_CON_INPUT                  ;  7      7
        short_addr  $STD_CON_INPUT_NO_ECHO          ;  8      8
        short_addr  $STD_CON_STRING_OUTPUT          ;  9      9
        short_addr  $STD_CON_STRING_INPUT           ; 10      A
        short_addr  $STD_CON_INPUT_STATUS           ; 11      B
        short_addr  $STD_CON_INPUT_FLUSH            ; 12      C
        short_addr  $DISK_RESET                     ; 13      D
        short_addr  $SET_DEFAULT_DRIVE              ; 14      E
        short_addr  $FCB_OPEN                       ; 15      F
        short_addr  $FCB_CLOSE                      ; 16     10
        short_addr  $DIR_SEARCH_FIRST               ; 17     11
        short_addr  $DIR_SEARCH_NEXT                ; 18     12
        short_addr  $FCB_DELETE                     ; 19     13
        short_addr  $FCB_SEQ_READ                   ; 20     14
        short_addr  $FCB_SEQ_WRITE                  ; 21     15
        short_addr  $FCB_CREATE                     ; 22     16
        short_addr  $FCB_RENAME                     ; 23     17
        short_addr  CPMFUNC                         ; 24     18
        short_addr  $GET_DEFAULT_DRIVE              ; 25     19
        short_addr  $SET_DMA                        ; 26     1A

;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  $SLEAZEFUNC                     ; 27     1B
        short_addr  $SLEAZEFUNCDL                   ; 28     1C
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

        short_addr  CPMFUNC                         ; 29     1D
        short_addr  CPMFUNC                         ; 30     1E
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  $GET_DEFAULT_DPB                ; 31     1F
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        short_addr  CPMFUNC                         ; 32     20
        short_addr  $FCB_RANDOM_READ                ; 33     21
        short_addr  $FCB_RANDOM_WRITE               ; 34     22
        short_addr  $GET_FCB_FILE_LENGTH            ; 35     23
        short_addr  $GET_FCB_POSITION               ; 36     24
VAL1    =       ($-DISPATCH)/2 - 1

; Extended Functions
        short_addr  $SET_INTERRUPT_VECTOR           ; 37     25
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  $CREATE_PROCESS_DATA_BLOCK      ; 38     26
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        short_addr  $FCB_RANDOM_READ_BLOCK          ; 39     27
        short_addr  $FCB_RANDOM_WRITE_BLOCK         ; 40     28
        short_addr  $PARSE_FILE_DESCRIPTOR          ; 41     29
        short_addr  $GET_DATE                       ; 42     2A
        short_addr  $SET_DATE                       ; 43     2B
        short_addr  $GET_TIME                       ; 44     2C
        short_addr  $SET_TIME                       ; 45     2D
        short_addr  $SET_VERIFY_ON_WRITE            ; 46     2E

; Extended functionality group
        short_addr  $GET_DMA                        ; 47     2F
        short_addr  $GET_VERSION                    ; 48     30
        short_addr  $Keep_Process                   ; 49     31
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  $GET_DPB                        ; 50     32
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        short_addr  $SET_CTRL_C_TRAPPING            ; 51     33
        short_addr  $GET_INDOS_FLAG                 ; 52     34
        short_addr  $GET_INTERRUPT_VECTOR           ; 53     35
        short_addr  $GET_DRIVE_FREESPACE            ; 54     36
        short_addr  $CHAR_OPER                      ; 55     37
        short_addr  $INTERNATIONAL                  ; 56     38
; XENIX CALLS
;   Directory Group
        short_addr  $MKDIR                          ; 57     39
        short_addr  $RMDIR                          ; 58     3A
        short_addr  $CHDIR                          ; 59     3B
;   File Group
        short_addr  $CREAT                          ; 60     3C
        short_addr  $OPEN                           ; 61     3D
        short_addr  $CLOSE                          ; 62     3E
        short_addr  $READ                           ; 63     3F
        short_addr  $WRITE                          ; 64     40
        short_addr  $UNLINK                         ; 65     41
        short_addr  $LSEEK                          ; 66     42
        short_addr  $CHMOD                          ; 67     43
        short_addr  $IOCTL                          ; 68     44
        short_addr  $DUP                            ; 69     45
        short_addr  $DUP2                           ; 70     46
        short_addr  $CURRENT_DIR                    ; 71     47
;    Memory Group
        short_addr  $ALLOC                          ; 72     48
        short_addr  $DEALLOC                        ; 73     49
        short_addr  $SETBLOCK                       ; 74     4A
;    Process Group
        short_addr  $EXEC                           ; 75     4B
        short_addr  $EXIT                           ; 76     4C
        short_addr  $WAIT                           ; 77     4D
        short_addr  $FIND_FIRST                     ; 78     4E
;   Special Group
        short_addr  $FIND_NEXT                      ; 79     4F
; SPECIAL SYSTEM GROUP
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  $SET_CURRENT_PDB                ; 80     50
        short_addr  $GET_CURRENT_PDB                ; 81     51
        short_addr  $GET_IN_VARS                    ; 82     52
        short_addr  $SETDPB                         ; 83     53
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        short_addr  $GET_VERIFY_ON_WRITE            ; 84     54
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  $DUP_PDB                        ; 85     55
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        short_addr  $RENAME                         ; 86     56
        short_addr  $FILE_TIMES                     ; 87     57
        short_addr  $AllocOper                      ; 88     58
; Network extention system calls
        short_addr  $GetExtendedError               ; 89     59
        short_addr  $CreateTempFile                 ; 90     5A
        short_addr  $CreateNewFile                  ; 91     5B
        short_addr  $LockOper                       ; 92     5C
        short_addr  $ServerCall                     ; 93     5D
        short_addr  $UserOper                       ; 94     5E
        short_addr  $AssignOper                     ; 95     5F
        short_addr  $NameTrans                      ; 96     60
        short_addr  CPMFunc                         ; 97     61
        short_addr  $Get_Current_PDB                ; 98     62
; the next call is reserved for hangool sys call
        short_addr  $ECS_Call                       ; 99     63
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  $Set_Printer_Flag               ; 100    64
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        short_addr  $GetExtCntry                    ; 101    65
        short_addr  $GetSetCdPg                     ; 102    66
        short_addr  $ExtHandle                      ; 103    67
        short_addr  $Commit                         ; 104    68
        short_addr  $GSetMediaID                    ; 105    69   ;AN000;
        short_addr  $Commit                         ; 106    6A   ;AN000;
        short_addr  $IFS_IOCTL                      ; 107    6B   ;AN000;
        short_addr  $Extended_Open                  ; 108    6C   ;AN000;
;
VAL2    =       ($-DISPATCH)/2 - 1


        If      Installed

PUBLIC FOO
FOO     LABEL WORD
        Short_addr  Leave2F
DTab    DW  OFFSET  DOSGroup:DOSTable
        PUBLIC FOO,DTAB

DOSTable    LABEL   WORD
        DB      (DOSTableEnd-DOSTable-1)/2
        Short_addr  DOSInstall          ;   0 install check
        Short_addr  DOS_CLOSE           ;   1   DOS_CLOSE
        Short_addr  RECSET              ;   2   RECSET
        Short_addr  DOSGetGroup         ;   3   Get DOSGROUP
        Short_addr  PATHCHRCMP          ;   4   PATHCHRCMP
        Short_addr  OUTT                ;   5   OUT
        Short_addr  NET_I24_ENTRY       ;   6   NET_I24_ENTRY
        Short_addr  PLACEBUF            ;   7   PLACEBUF
        Short_addr  FREE_SFT            ;   8   FREE_SFT
        Short_addr  BUFWRITE            ;   9   BUFWRITE
        Short_addr  SHARE_VIOLATION     ;   10  SHARE_VIOLATION
        Short_addr  SHARE_ERROR         ;   11  SHARE_ERROR
        Short_addr  SET_SFT_MODE        ;   12  SET_SFT_MODE
        Short_addr  DATE16              ;   13  DATE16
        Short_addr  idle                ;   14      empty slot
        Short_addr  SCANPLACE           ;   15  SCANPLACE
        Short_addr  idle                ;   16      empty slot
        Short_addr  StrCpy              ;   17  StrCpy
        Short_addr  StrLen              ;   18  StrLen
        Short_addr  Ucase               ;   19  Ucase
        Short_addr  POINTCOMP           ;   20  POINTCOMP
        Short_addr  CHECKFLUSH          ;   21  CHECKFLUSH
        Short_addr  SFFromSFN           ;   22  SFFromSFN
        Short_addr  GetCDSFromDrv       ;   23  GetCDSFromDrv
        Short_addr  Get_User_Stack      ;   24  Get_User_Stack
        Short_addr  GetThisDrv          ;   25  GetThisDrv
        Short_addr  DriveFromText       ;   26  DriveFromText
        Short_addr  SETYEAR             ;   27  SETYEAR
        Short_addr  DSUM                ;   28  DSUM
        Short_addr  DSLIDE              ;   29  DSLIDE
        Short_addr  StrCmp              ;   30  StrCmp
        Short_addr  InitCDS             ;   31  initcds
        Short_addr  pJFNFromHandle      ;   32  pJfnFromHandle
        Short_addr  $NameTrans          ;   33  $NameTrans
        Short_addr  CAL_LK              ;   34  CAL_LK
        Short_addr  DEVNAME             ;   35  DEVNAME
        Short_addr  Idle                ;   36  Idle
        Short_addr  DStrLen             ;   37  DStrLen
        Short_addr  NLS_OPEN            ;   38  NLS_OPEN      DOS 3.3
        Short_addr  $CLOSE              ;   39  $CLOSE        DOS 3.3
        Short_addr  NLS_LSEEK           ;   40  NLS_LSEEK     DOS 3.3
        Short_addr  $READ               ;   41  $READ         DOS 3.3
        Short_addr  FastInit            ;   42  FastInit      DOS 3.4  ;AN000;
        Short_addr  NLS_IOCTL           ;   43  NLS_IOCTL     DOS 3.3
        Short_addr  GetDevList          ;   44  GetDevList    DOS 3.3
        Short_addr  NLS_GETEXT          ;   45  NLS_GETEXT    DOS 3.3
        Short_addr  MSG_RETRIEVAL       ;   46  MSG_RETRIEVAL DOS 4.0  ;AN000;
        Short_addr  Fake_Version        ;   47  Fake_Version  DOS 4.0  ;AN006;

DOSTableEnd LABEL   BYTE

        ENDIF

; NOTE WARNING: This declaration of HEADER must be THE LAST thing in this
;       module. The reason is so that the data alignments are the same in
;       IBM-DOS and MS-DOS up through header.
;---------------------------------------Start of Korean support  2/11/KK
;
; The varialbes for ECS version are moved here for the same data alignments
; as IBM-DOS and MS-DOS.
;

        I_AM    InterChar, byte         ; Interim character flag ( 1= interim)  ;AN000;
                                                                                ;AN000;
;------- NOTE: NEXT TWO BYTES SOMETIMES USED AS A WORD !! ---------------------
DUMMY   LABEL   WORD                                                            ;AN000;
        PUBLIC  InterCon                ; Console in Interim mode ( 1= interim) ;AN000;
InterCon        db      0                                                       ;AN000;
        PUBLIC  SaveCurFlg              ; Print, do not advance cursor flag     ;AN000;
SaveCurFlg      db      0                                                       ;AN000;
;-----------------------------------------End of Korean support  2/11/KK


        PUBLIC  HEADER
Header  LABEL   BYTE
        IF      DEBUG
        DB      13,10,"Debugging DOS version "
        DB      MAJOR_VERSION + "0"
        DB      "."
        DB      (MINOR_VERSION / 10) + "0"
        DB      (MINOR_VERSION MOD 10) + "0"
        ENDIF

        IF      NOT IBM
        DB      13,10,"MS-DOS version "
        DB      MAJOR_VERSION + "0"
        DB      "."
        DB      (MINOR_VERSION / 10) + "0"
        DB      (MINOR_VERSION MOD 10) + "0"

        IF      HIGHMEM
        DB      "H"
        ENDIF

	DB	13,10, "Copyright 1981,82,83,84,88 Microsoft Corp.",13,10,"$"
	ENDIF

IF DEBUG
        DB      13,10,"$"
ENDIF

MSTAB001E       label byte

include copyrigh.inc                                                            ;AN000;

; SYS init extended table,   DOS 3.3   F.C. 5/29/86
;
       PUBLIC   SysInitTable
       I_need   COUNTRY_CDPG,BYTE
       I_need   SYSINITVAR,BYTE

SysInitTable  label  byte
               dw      OFFSET DOSGROUP:SYSINITVAR    ; pointer to sysinit var
               dw      0                             ; segment
               dw      OFFSET DOSGROUP:COUNTRY_CDPG  ; pointer to country table
               dw      0                             ; segment of pointer
; DOS 3.3 F.C. 6/12/86

; FASTOPEN communications area DOS 3.3   F.C. 5/29/86
;
       PUBLIC   FastOpenTable
       PUBLIC   FastTable                            ; a better name
       EXTRN    FastRet:FAR                          ; defined in misc2.asm

FastTable      label  byte                           ; a better name
FastOpenTable  label  byte
               dw      2                             ; number of entries
               dw      OFFSET DOSGROUP:FastRet       ; pointer to ret instr.
               dw      0                             ; and will be modified by
               dw      OFFSET DOSGROUP:FastRet       ; FASTxxx when loaded in
               dw      0                             ;
; DOS 3.3 F.C. 6/12/86
      PUBLIC   FastFlg                  ;AN000; flags
FastFlg        label  byte              ;AN000; don't change the following order
        I_am   FastOpenFlg,BYTE,<0>     ;AN000;
        I_am   FastSeekFlg,BYTE,<0>     ;AN000;

       PUBLIC   FastOpen_Ext_Info

; FastOpen_Ext_Info is used as a temporary storage for saving dirpos,dirsec
; and clusnum  which are filled by DOS 3.3 when calling FastOpen Insert
; or filled by FastOPen when calling FastOpen Lookup

FastOpen_Ext_Info  label  byte
               db   SIZE FASTOPEN_EXTENDED_INFO dup(0) ;dirpos

; Dir_Info_Buff is a dir entry buffer which is filled by FastOPen
; when calling FastOpen Lookup

       PUBLIC  Dir_Info_Buff

Dir_Info_Buff  label  byte
               db   SIZE dir_entry dup (0)


      I_am     Next_Element_Start,WORD  ; save next element start offset

; Following 4 variables moved to MSDATA.asm  (P4986)
;     I_am     FSeek_drive,BYTE         ;AN000; fastseek drive #
;     I_am     FSeek_firclus,WORD       ;AN000; fastseek first cluster #
;     I_am     FSeek_logclus,WORD       ;AN000; fastseek logical cluster #
;     I_am     FSeek_logsave,WORD       ;AN000; fastseek returned log clus #

; The following is a stack and its pointer for interrupt 2F which is uesd
; by NLSFUNC.  There is no significant use of this stack, we are just trying
; not to destroy the INT 21 stack saved for the user.


       PUBLIC   User_SP_2F

USER_SP_2F       LABEL  WORD
                dw    OFFSET DOSGROUP:FAKE_STACK_2F

       PUBLIC   Packet_Temp
Packet_Temp      label  word             ; temporary packet used by readtime
       PUBLIC   DOS_TEMP                 ; temporary word
DOS_TEMP         label  word
FAKE_STACK_2F   dw   14 dup (0)          ; 12 register temporary storage

       PUBLIC   Hash_Temp                ;AN000; temporary word
Hash_Temp        label  word             ;AN000;
                dw    4 dup (0)          ;AN000; temporary hash table during config.sys

      PUBLIC   SCAN_FLAG                 ; flag to indicate key ALT_Q
SCAN_FLAG      label  byte
               db     0
;;; The following  2 words must be adjacent for IBMDOS reasons

      PUBLIC   DATE_FLAG
DATE_FLAG      label  word               ; flag to
               dw     0                  ; to update the date
;;;; special tag for IBMDOS
      PUBLIC   FETCHI_TAG
FETCHI_TAG     label  word               ; TAG to make DOS 3.3 work
               dw     0                  ; must be 22642
;;; The above  2 words must be adjacent for IBMDOS reasons
; DOS 3.3 F.C. 6/12/86
      I_am     Del_ExtCluster,WORD       ; for dos_delete                       ;AN000;

      PUBLIC   MSG_EXTERROR              ; for system message addr              ;AN000;
MSG_EXTERROR   label  DWORD                                                     ;AN000;
               dd     0                  ; for extended error                   ;AN000;
               dd     0                  ; for parser                           ;AN000;
               dd     0                  ; for critical errror                  ;AN000;
               dd     0                  ; for IFS                              ;AN000;
               dd     0                  ; for code reduction                   ;AN000;

      PUBLIC   SEQ_SECTOR                ; last sector read                     ;AN000;
SEQ_SECTOR     label  DWORD                                                     ;AN000;
               dd     -1                                                        ;AN000;

      I_am     XA_CONDITION,BYTE,<0>     ; for Extended Attributes              ;AN000;
;     I_am     XA_ES,WORD                ; for extended find                    ;AN000;
;     I_am     XA_BP,WORD                ; for extended find                    ;AN000;
;     I_am     XA_handle,WORD            ; for get/set EA                       ;AN000;
      I_am     XA_type,BYTE              ; for get/set EA                       ;AN000;
;     I_am     XA_device,BYTE            ; for get/set EA                       ;AN000;
      I_am     XA_from,BYTE              ; for get/set EA                       ;AN000;
;     I_am     XA_VAR,WORD               ; for get/set EA                       ;AN000;
;     I_am     XA_TEMP,WORD              ; for get/set EA                       ;AN000;
;     I_am     XA_TEMP2,WORD             ; for get/set EA                       ;AN000;
;

;     I_am     MAX_EA_SIZE,WORD,<29>     ; max EA list size                     ;AN000;
;     I_am     MAX_EANAME_SIZE,WORD,<20> ; max EA name list size                ;AN000;
;     I_am     XA_COUNT,WORD,<2>         ; number of EA entries                 ;AN000;


;     PUBLIC   XA_TABLE                       ; for get/set EA                  ;AN000;
;
;XA_TABLE       label  byte                                                      ;AN000;
;              db EAISBINARY                                       ;Code Page   ;AN000;
;              dw EASYSTEM                                                      ;AN000;
;              db 0,2                                                           ;AN000;
;              dw 2                                                             ;AN000;
;              db 'CP'                                                          ;AN000;
;
;              db EAISBINARY                                       ;File Type   ;AN000;
;              dw EASYSTEM                                                      ;AN000;
;              db 0,8                                                           ;AN000;
;              dw 1                                                             ;AN000;
;              db 'FILETYPE'                                                    ;AN000;
;

;         PUBLIC XA_PACKET                                                            ;AN000;
;XA_PACKET        label byte                                                           ;AN000;
;IF  DBCS                                                                             ;AN000;
;                dw   18                                                              ;AN000;
;                db   18 dup(0)                                                       ;AN000;
;         PUBLIC DBCS_PACKET                                                          ;AN000;
;DBCS_PACKET      label byte                                                           ;AN000;
;                db   5 dup(0)
;ELSE
;                dw   2, 0                       ; get/set device code page           ;AN000;
;ENDIF
        I_am    CurHashEntry,DWORD               ; current hash buffer entry          ;AN000;
;;      I_am    ACT_PAGE,WORD,<-1>               ;BL ; active EMS page                       ;AN000;
        I_am    SC_SECTOR_SIZE,WORD              ; sector size for SC                 ;AN000;
        I_am    SC_DRIVE,BYTE                    ; drive # for secondary cache        ;AN000;
        I_am    CurSC_DRIVE,BYTE,<-1>            ; current SC drive                   ;AN000;
        I_am    CurSC_SECTOR,DWORD               ; current SC starting sector         ;AN000;
        I_am    SC_STATUS,WORD,<0>               ; SC status word                     ;AN000;
        I_am    SC_FLAG,BYTE,<0>                 ; SC flag                            ;AN000;
        I_am    IFS_DRIVER_ERR,WORD,<0>          ; driver error for IFS               ;AN000;

          PUBLIC NO_NAME_ID                                                           ;AN000;
NO_NAME_ID       label byte                                                           ;AN000;
                 db   'NO NAME    '              ; null media id                      ;AN000;

          PUBLIC SWAP_AREA_TABLE                                                      ;AN000;
SWAP_AREA_TABLE  label byte                                                           ;AN000;
        I_am    NUM_SWAP_AREA,WORD,<2>           ; number of swap areas               ;AN000;
        I_am    SWAP_IN_DOS,DWORD                ; swap in dos area                   ;AN000;
        I_am    SWAP_IN_DOS_LEN,WORD             ; swap in dos area length            ;AN000;
        I_am    SWAP_ALWAYS_AREA,DWORD           ; swap always area                   ;AN000;
        I_am    SWAP_ALWAYS_AREA_LEN,WORD        ; swap always area length            ;AN000;
        I_am    IFSFUNC_SWAP_IN_DOS,DWORD        ; ifsfunc swap in dos area           ;AN000;
        I_am    IFSFUNC_SWAP_IN_DOS_LEN,WORD     ; ifsfunc swap in dos area length    ;AN000;

        I_am    SWAP_AREA_LEN,WORD               ; swap area length                   ;AN000;
        I_am    FIRST_BUFF_ADDR,WORD             ; first buffer address               ;AN000;
        I_am    SPECIAL_VERSION,WORD,<0>         ;AN006; used by INT 2F 47H
        I_am    FAKE_COUNT,<255>                 ;AN008; fake version count
        I_am    OLD_FIRSTCLUS,WORD               ;AN011; save old first cluster for fastopen

TABLE   ENDS


