        page    80,132
;******************* START OF SPECIFICATIONS ***********************************
;
; MODULE NAME:          SYS1.SAL + SYS2.SAL + SYSSR.SAL
;
; DESCRIPTIVE NAME:     SYS
;
; FUNCTION:             Copies system programs IBMBIO.COM and
;                       IBMDOS.COM onto a specified media.
;
; ENTRY POINT:
;
; INPUT:
;
; EXIT NORMAL:
;
; EXIT ERROR:
;
; INTERNAL REFERENCES:
;
;       ROUTINES:
;
;       DATA AREAS:
;
; EXTERNAL REFERENCES:
;
;       ROUTINES:
;
;       DATA AREAS:
;
; NOTES:  Version 4.0 is a MAJOR diversion from all previous versions of DOS.
;
;         In all older versions of SYS the target diskette, HAD to meet the
;         following criteria in order to be SYSed:
;                       - there must be enough physical room for IBMBIO and
;                         IBMDOS.
;                       - the first data cluster (#2) had to be either not
;                         used - or owned by IBMBIO allready on the disk
;                       - The first 2 root DIR entries had to be unused, deleted
;                          or owned by IBMBIO and IBMDOS.
;
;         4.0 SYS is far less restrictive.
;                       - there must still be enough physical room for IBMBIO
;                         and IBMDOS.
;                       - SYS will free up all required data clusters required
;                         by IBMBIO.
;                       - The 2 root DIR entries for IBMDOS and IBMBIO may
;                         be anywhere in the root.  SYS will move entrys
;                         in order for IBMBIO and IBMDOS to be in their proper
;                         positions.
;        *** NOTE ****  - Sys will operate on DOS 3.2, 3.3 and 4.0.
;                         This has reqired a HARD CODED lower bound - DOS_low
;                         that is set in this file to 3.20
;
; REVISION HISTORY: Ax000  Version 4.0  05/01/87 - first release             FG
;                   Ax001          4.0  PTR P324                         D Love
;                   Ax002          4.0  PTR P583                             FG
;                   Ax003          4.0  DCR D4    - sys anything,anywhere    FG
;                   Ax004          4.0  DCR D201  - extended arbib change    FG
;                   Ax005          4.0  PTR P1334 - 1.2 MB + system  hang    FG
;                   Ax006          4.0  PTR P1403 - BIO & DOS wrong spots    FG
;                   Ax007          4.0  PTR P1404,5 - DIR search error       FG
;                   Ax008          4.0  PTR P1406 - IOCTL to INT 21-69       FG
;                   Ax009          4.0  PTR P1637 - full 720KB error         FG
;                   Ax010          4.0  PTR P1764 - single file error        FG
;                   Ax011          4.0  PTR P1772 - IBMBIO cluster chain     FG
;                   Ax012          4.0  PTR P1710 - ASSIGN or SUBST invalid  FG
;                   Ax013          4.0  PTR P1872 - ROOT restoration problem FG
;                   Ax014          4.0  PTR P1884 - more ROOT problems       FG
;                   Ax015          4.0  PTR P2165 - ROOT DIR above #100h sec.FG
;                   Ax016          4.0  DCR D304  - change in BOOT.INC       FG
;                   Ax017          4.0  PTR P2356 - HILDA error message      FG
;                   Ax018          4.0  PTR P2769 - no system on default drv FG
;                   Ax019          4.0  DCR D380  - run on current VER -1    FG
;                   Ax020          4.0  PTR P3028 - run using PATHGEN        FG
;                   Ax021          4.0  DCR D494  - add "source" & DOS 3.2   FG
;                   Ax022          4.0  PTR P3728 - wrong network message    FG
;                   Ax023          4.0  DCR D503  - Version is now 4.0       FG
;                   Ax024          4.0  PTM P3905 - fix parse error format   FG
;                   Ax025          4.0  PTM P4118 - fix message error        FG
;
; PRE-VERSION 4.0 HISTORY:
;
;   1.6     05/21/82    Added rev number message
;   1.61    06/04/82    Allow SYS to blank disk TimP at SCP
;   1.70    06/30/82    NON contiguous DOS allowed on 2.00 IBM.  Allows SYS to
;                       1.0 1.1 disks.
;   1.71    07/02/82    Put in CHDIRs to make sure everything done in root dir.
;   1.80    04/26/83    MZ make sys work in small machines; use full 2.0
;                       system calls
;   1.81    07/22/83    ARR Added check in IBM version for valid FAT ID on
;                       destination because of IBM problem with SYSing to
;                       unformatted disks which are really formatted.  Prints
;                       NoDest message for ridic IBM reasons, should have a
;                       better message.
;   1.82    08/12/83    ARR ZIBOed again.  Mark fails to check for errors on
;                       his file I/O.  Results in SYS saying system
;                       transferred when it hasn't been.
;   1.83    09/08/83    EKE Added code to quit if sys called on a drive across
;                       a net.
;   1.84    09/09/83    CHRISP grabbed against his will to make this stupid
;                       program write out a boot sector
;   1.85    10/18/83    NP Printf to print messages and it's now an .EXE file
;   1.86    11/8/83     MZ fix hard file output of boot sector
;   1.87    5/1/84      MZ make sys prompt for system disk in default drive.
;   3.20    11/9/84     RS make sys write out a correct boot sector for the
;                       version of DOS. It grabs the boot sector off the system
;                       disk and inserts the correct BPB.
;                       Uses IOCTL Get Device Parms to get BPB for a Hard drive.
;   3.20    08/5/85     RS Allow FAT ID byte of 0F0H for 'strange' media
;                       layouts. These come about because of /T /N switches in
;                       FORMAT.
;   3.20    09/16/85    Incorporate tables of filenames to allow system files
;                       used by other OEMs to be SYSed onto disks formatted on
;                       other MSDOS systems. Allows the flexibility to replace
;                       system files for one OEM by system files for another.
;
;
;   3.30    06/04/86    MT removes initial check for IBMBIO and DOS - not needed
;                       because of later search of dirs
;   3.30    06/16/86    MT only force part of IBMBIO contig - do this by assuming
;                       contig part smaller than 1.10 BIOS
;   3.30    06/16/86    MT Check diks space for enough room to install BIO and DOS
;
;     Label: "The DOS SHARE Utility"
;            "Version 4.00 (C) Copyright 1988 Microsoft
;            "Licenced Material - Program Property of Microsoft"
;
;******************* END OF SPECIFICATIONS *************************************
        BREAK   <SYS1 - Program Organization>
;******************+ START OF PSEUDOCODE +**************************************
;
;ÚÄÄÄÄÄÄ¿   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿     ÚÄÄÄÄÄÄÄÄÄÄ¿
;³ Main ÃÄÄÂ´Init_Input_OutputÃÄÄÄÄÂ´SysLoadMsg³ (DOS version check)
;ÀÄÄÄÄÄÄÙ  ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³ÀÄÄÄÄÄÄÄÄÄÄÙ
;          ³                       ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;          ³                       À´Parse_Command_Line³
;          ³                        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;          Ã´Validate_Target_DriveÃÂ´Check_Default_Drive³
;          ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³                       ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;          ³                       Ã´Check_Target_Drive³
;          ³                       ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³                       ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;          ³                       À´Check_For_Network³
;          ³                        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;          Ã´Get_System_FilesÃÄÄÄÄÄÂ´Prompt_For_Media³
;          ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ     ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³                       ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;          ³                       Ã´Check_Removable³
;          ³                       ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³                       ³ÚÄÄÄÄÄÄÄÄÄ¿
;          ³                       Ã´Open_File³
;          ³                       ³ÀÄÄÄÄÄÄÄÄÄÙ
;          ³                       ³ÚÄÄÄÄÄÄÄÄÄÄÄ¿
;          ³                       À´Fill_Memory³
;          ³                        ÀÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿  ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;          Ã´Check_SYS_ConditionsÃÄÂ´Verify_File_System³
;          ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³                       ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿         ÚÄ Ä Ä Ä Ä Ä Ä Ä ¿
;          ³                       Ã´Read_DirectoryÃÄÄÄÄÄÄÄÄÄ´Prompt_For_Media³
;          ³                       ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ         ÀÄ Ä Ä Ä Ä Ä Ä Ä Ù
;          ³                       ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;          ³                       Ã´Verify_File_Location³
;          ³                       ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³                       ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿   ÚÄÄÄÄÄÄÄÄÄÄÄ¿
;          ³                       À´Determine_Free_SpaceÃÄÄÄ´Get_Cluster³
;          ³                        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ   ÀÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³ÚÄÄÄÄÄÄ¿                ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿          ÚÄÄÄÄÄÄÄÄÄÄÄ¿
;          Ã´Do_SYSÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂ´Create_SystemÃÄÄÄÄÄÄÄÄÄÄ´Create_File³
;          ³ÀÄÄÄÄÄÄÙ               ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ          ÀÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³                       ³ÚÄ Ä Ä Ä Ä Ä¿
;          ³                       Ã´Fill_Memory³
;          ³                       ³ÀÄ Ä Ä Ä Ä ÄÙ
;          ³                       ³ÚÄÄÄÄÄÄÄÄÄÄÄ¿
;          ³                       À´Dump_Memory³
;          ³                        ÀÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³ÚÄÄÄÄÄÄ¿                ÚÄÄÄÄÄÄÄÄÄÄÄ¿
;          Ã´Do_EndÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂ´Close_Files³
;          ³ÀÄÄÄÄÄÄÙ               ³ÀÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³                       ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;          ³                       À´Write_Boot_RecordÃÄÄÄÄÄÂ´Create_Serial_ID³
;          ³                        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ     ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;          ³                                                ³ÚÄÄÄÄÄÄÄÄ¿
;          ³                                                À´FAT_Size³
;          ³                                                 ÀÄÄÄÄÄÄÄÄÙ
;          ³ÚÄÄÄÄÄÄÄÄÄÄ¿            ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;          À´Message   ÃÄÄÄÄÄÄÄÄÄÄÄÄ´Get_DOS_Error³
;           ÀÄÄÄÄÄÄÄÄÄÄÙ            ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;******************-  END  OF PSEUDOCODE -**************************************
        BREAK   <SYS - Segment Definition>
                                        ;---------------------------------------
                                        ;  NOTE: Structures used by SYS include:
                                        ;
                                        ;   find_buf           - DTA mapper
                                        ;   a_bpb              - EBPB struc
                                        ;   dir_entry          - Directory struc
                                        ;   A_DeviceParameters - IOCtl struc
                                        ;   BootForm           - Boot Rec struc
                                        ;---------------------------------------


;       INCLUDE DOSSYM.INC              ;also defines version of dos
.xlist
.xcref
        INCLUDE DOSSYM.INC
.cref
.list


;       INCLUDE IOCTL.INC               ; Get / Set Device Parameters IOCTL
.xlist
.xcref
        INCLUDE IOCTL.INC
.cref
.list


;       INCLUDE BOOTFORM.INC            ; Boot Record Structure
.xlist
.xcref
        INCLUDE BOOTFORM.INC
.cref


;       INCLUDE PATHMAC.INC            ; PATH macro for PATHGEN
.xlist
.xcref
        INCLUDE PATHMAC.INC
.cref
.list

IBMJAPVER EQU   FALSE                   ; this and the following are mutually
IBMVER  EQU     TRUE                    ; exclusive

CODE    SEGMENT PARA PUBLIC
CODE    ENDS

DATA    SEGMENT PARA PUBLIC
DATA    ENDS

;                       $SALUT (4,25,30,41)
                                        ;--------------------------------------
                                        ; constants
                                        ;--------------------------------------

DOS_low                 equ  0300h + 20 ; 3 in high reg, 20 in low reg.        ;AN023;
not_used                equ  0          ; filler for INT 21's
num_2_letter            equ  040h       ; turn dirve number to letter
dev_local               equ  9          ; IOCtl - get device parameters
removable               equ  01h        ; for testing removeability
net_drive               equ  01000h     ; for testing net drive
DOS_system_atrib        equ  7          ; DOS system file atributes
DOS_volume_atrib        equ  8          ; DOS volume label atribute
error_RC                equ  1          ; error return code
any_error               equ  255        ; mask for detecting errors
success                 equ  0          ; successful completion of SYS
LSeek_EOF               equ  2          ; seek relative to eof
LSeek_Start             equ  0          ; seek relative to beginning
old_type_media          equ  26         ; DOS extended error - old type media
file_not_found          equ  2          ; DOS extended error - file not found
file_spec_length        equ  11         ; length of file name
empty                   equ  0          ; empty directory entry
deleted                 equ  0E5h       ; entry is deleted
SetAtrib                equ  01h        ; set file attributes
set                     equ  1          ; set file date and time
BIG_FAT_THRESHOLD       equ  4086       ; size break for FAT12 - FAT16
PRELOAD                 equ  1          ; normal preload
return_error            equ  1          ; SYS return error code
FQ_DOS_DIR_CON_INP      equ  07h        ; Flush Queue / Direct CON in no echo
hard_drive              equ  0F8H       ; Media Descriptor for Hard drive
first_drive             equ  80H        ; first physical hard drive number
noerror                 equ  0          ; no errors
FAT_sect_size           equ  12         ; FAT sector count
dot                     equ  02Eh       ; Sub DIR DOT
bad_sector              equ  0F7h       ; FAT bad sector mark
end_cluster             equ  0FFh       ; FAT last cluster mark
not_found               equ  0FFh       ; current cluster not yet found
cluster_ent_per_sect    equ  512/2      ; (bytes/sector) / (bytes/cluster entry)
                                        ;    = cluster entries / sector
clusters_loaded         equ  cluster_ent_per_sect * FAT_sect_size ; = # of cluster
                                        ;    entries loaded in 12 sectors.

FAT_BUF                 equ  512 * 13   ; This space is used to do a number
                                        ;  of tasks. It existes at the START
                                        ;  of BUF. It is used as a 1 sector
                                        ;  buffer for processing DIR sector
                                        ;  manipulation. It is also used to
                                        ;  process the FAT. NOTE: a 12 bit fat
                                        ;  has a max. of FFFh (4K) entries - or
                                        ;  6K of space - or 12 sectors (512 bytes)
                                        ;  an extra 512 bytes is added for safety

                                        ;----------------------------------------
                                        ;  definition of the MODE bits
                                        ;     for an extended open
                                        ;----------------------------------------

;                 BITS DEFINED FOR THE MODE WORD
;                       FORMAT = 0WF0000CISSS0AAA
;              Write   ÄÄÄÄÄÄÄÄÄÄÄÙ³    ³³³   ÀÄÄÄ Access code
;                0 = no commit     ³    ³³³             0 = read
;                1 = auto commit   ³    ³³³             1 = write
;                                  ³    ³³³             2 = read/write
;          Fail action ÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³³³             3 = execute
;            0 = INT 24h                ³³³             4 = FCB
;            1 = return error           ³³³
;                                       ³³ÀÄÄÄ  Sharing mode
;             Code Page support ÄÄÄÄÄÄÄÄÙ³         0 = compatability
;               0 = validate code page   ³         1 = deny read/write
;               1 = no code page check   ³         2 = deny write
;                                        ³         3 = deny read
;                                        ³         4 = deny none
;                                      Inherit
;                                        0 = pass handle to child
;                                        1 = no inherit
;
MODE_COM                equ  0100000000000000b ; Auto Commit
MODE_NO24               equ  0010000000000000b ; No 24 - return error
MODE_NOCP               equ  0000000100000000b ; No 24 - return error
MODE_NOINH              equ  0000000010000000b ; No child procees access
;                                            Sharing mode
;MODE_SH_COMP   equ       0000000000000000b        0 = compatability
MODE_SH_D_RW            equ  0000000000010000b ;    1 = deny read/write
MODE_SH_D_W             equ  0000000000100000b ;    2 = deny write
MODE_SH_D_R             equ  0000000000110000b ;    3 = deny read
MODE_SH_D_NONE          equ  0000000001000000b ;    4 = deny none
;                                            Access code
;MODE_AC_R      equ       0000000000000000b        0 = read
MODE_AC_W               equ  0000000000000001b ;    1 = write
MODE_AC_RW              equ  0000000000000010b ;    2 = read/write
MODE_AC_EXE             equ  0000000000000011b ;    3 = execute
MODE_AC_FCB             equ  0000000000000100b ;    4 = FCB

open_mode               equ  MODE_NO24+MODE_NOCP+MODE_NOINH+MODE_SH_D_RW+ MODE_AC_RW

;-------------------------------------------------
; Message Skeleton File
;-------------------------------------------------

;util   SYS

;class  1

;use EXTEND15                           ; INVALID DRIVE

;class  2

;use PARSE1                              ;1 - Too many operands
;use PARSE2                              ;2 - Required operand missing
                                        ;3 - Not in switch list provided
                                        ;4 - Not in keyword list provided
                                        ;6 - Out of range specified
                                        ;7 - Not in value list provided
                                        ;8 - Not in string list provided
;use PARSE9                              ;9 - Invalid Parameter

;class  A

;use 1  COMMON1

;class  B

;def 7  "No room for system on destination disk",CR,LF         ; Old
;def 8  "Ivalid path or System files not found",CR,LF          ; New
;use 9  COMMON30                 ; System transferred                  - Old
;def 10 "No system on default drive",CR,LF                     ; Old
;def 11 "Can not specify default drive",CR,LF                  ; New
;def 12 "Write failure, diskette unusable",CR,LF               ; New
;use 19 COMMON25                 ; Invalid path                ; New

;class  C

;use 13 COMMON12                 ; Cannot %1 to a Network drive        - Old
;def 14 "Insert system disk in drive %1",CR,LF                 ; Old
;use 15 COMMON19                 ; Insert destination disk in drive %1 - Old
;def 16 "Not able to SYS to %1 file system",CR,LF              ; New
;use 18 COMMON14                 ; Cannot %1 a SUBSTed or ASSIGNed drive - NEW

;class  D

;use 17 COMMON28                  ; Press any key to continue. . .      - Old

;end

                                        ;----------------------------------------
                                        ; Message Number Equates
                                        ;----------------------------------------

util                    equ  0ffh       ; all Utility messages
DOS_error               equ  1          ; DOS error CLASS
PARSE_error             equ  2          ; PARSE error CLASS
util_B                  equ  0bh        ; Utility CLASS B messages
                                        ;   (plain message)
util_C                  equ  0ch        ; Utility CLASS C messages
                                        ;   (insert message)
util_D                  equ  0dh        ; Utility CLASS D messages
                                        ;   (wait message)
extended_15             equ  15         ; DOS extended error 15
reqd_missing            equ  2          ; PARSE error 2

                                        ; CLASS B

no_room                 equ  7          ; No room for system on destination disk   Old
system_not_found        equ  8          ; Invalid path or System files not found   Old
done                    equ  9          ; System transferred                       Old
no_sys_on_def           equ  10         ; No system on default drive               Old
not_on_default          equ  11         ; Can not specify default drive            New
write_fail              equ  12         ; Write failure, diskette unusable         New
bad_path                equ  19         ; Invalid path
                                        ; CLASS C

cant_network            equ  13         ; Cannot %1 to a Network drive             Old
sys_disk                equ  14         ; Insert system disk in drive %1           Old
dest_disk               equ  15         ; Insert destination disk in drive %1      Old
cant_sys                equ  16         ; Not able to SYS to %1 file system        New
cant_assign             equ  18         ; Cannot %1 a SUBSTed or ASSIGNed drive    Old

                                        ; CLASS D

press_key               equ  17         ; Press any key to continue. . .           Change

                        BREAK <SYS >
