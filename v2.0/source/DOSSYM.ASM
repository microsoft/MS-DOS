include DOSMAC.ASM
IF2
    %OUT    DOSSYM in Pass 2
ENDIF

IFNDEF  ALTVECT
ALTVECT EQU     0       ;FALSE
ENDIF

BREAK <Control character definitions>

c_DEL       EQU     7Fh         ;    ASCII rubout or delete previous char
c_BS        EQU     08h         ; ^H ASCII backspace
c_CR        EQU     0Dh         ; ^M ASCII carriage return
c_LF        EQU     0Ah         ; ^J ASCII linefeed
c_ETB       EQU     17h         ; ^W ASCII end of transmission
c_NAK       EQU     15h         ; ^U ASCII negative acknowledge
c_ETX       EQU     03h         ; ^C ASCII end of text
c_HT        EQU     09h         ; ^I ASCII tab

BREAK <BPB Definition>


;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
; Certain structures, constants and system  calls  below  are  private  to ;
; the DOS  and  are  extremely  version-dependent.  They may change at any ;
; time at  the  implementors'  whim.   As  a  result,  they  must  not  be ;
; documented to  the  general  public.   If  an  extreme case arises, they ;
; must be documented with this warning.                                    ;
;                                                                          ;
; Those structures and constants that are subject to  the  above  will  be ;
; marked and bracketed with the flag:                                      ;
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

BREAK  <Bios Parameter Block>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;

; Bios Parameter Block definition
; This structure is used to build a full DPB

BPBLOCK STRUC
BPSECSZ DW      ?       ; Size in bytes of physical sector
BPCLUS  DB      ?       ; Sectors/Alloc unit
BPRES   DW      ?       ; Number of reserved sectors
BPFTCNT DB      ?       ; Number of FATs
BPDRCNT DW      ?       ; Number of directory entries
BPSCCNT DW      ?       ; Total number of sectors
BPMEDIA DB      ?       ; Media descriptor byte
BPFTSEC DW      ?       ; Number of sectors taken up by one FAT
BPBLOCK ENDS
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

BREAK <Disk I/O Buffer Header>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;

; Field definition for I/O buffer information

BUFFINFO        STRUC
NEXTBUF         DD      ?       ; Pointer to next buffer in list
; The next two items are often refed as a word
BUFDRV          DB      ?       ; Logical drive # assoc with buffer FF = free
BUFDIRTY        DB      ?       ; Dirty flag
BUFPRI          DB      ?       ; Buffer selection priority (see EQUs below)
VISIT           DB      ?       ; Visit flag for buffer pool scans
BUFSECNO        DW      ?       ; Sector number of buffer
; The next two items are often refed as a word
BUFWRTCNT       DB      ?       ; For FAT sectors, # times sector written out
BUFWRTINC       DB      ?       ; "   "     "   , # sectors between each write
BUFDRVDP        DD      ?       ; Pointer to drive parameters
BUFFINFO        ENDS

BUFINSIZ        EQU     SIZE BUFFINFO
                                ; Size of structure in bytes

FREEPRI EQU     0
LBRPRI  EQU     2               ; Last byte of buffer read
LBWPRI  EQU     4               ; Last byte written
RPRI    EQU     6               ; Read but not last byte
WPRI    EQU     8               ; Written but not last byte
DIRPRI  EQU     15              ; Directory Sector
FATPRI  EQU     30              ; FAT sector
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

BREAK <User stack inside of system call>
; Location of user registers relative user stack pointer

user_environ    STRUC
user_AX     DW      ?
user_BX     DW      ?
user_CX     DW      ?
user_DX     DW      ?
user_SI     DW      ?
user_DI     DW      ?
user_BP     DW      ?
user_DS     DW      ?
user_ES     DW      ?
user_IP     DW      ?
user_CS     DW      ?
user_F      DW      ?
user_environ    ENDS

BREAK <interrupt definitions>

INTTAB          EQU     20H
INTBASE         EQU     4 * inttab
ENTRYPOINT      EQU     INTBASE+40H

        IF      ALTVECT
ALTTAB  EQU     0F0H
ALTBASE EQU     4 * ALTTAB
        ENDIF

;
; interrupt assignments
;
        IF      NOT ALTVECT
int_abort           EQU     INTTAB          ; abort process
int_command         EQU     int_abort+1     ; call MSDOS
int_terminate       EQU     int_abort+2     ; int to terminate address
int_ctrl_c          EQU     int_abort+3     ; ^c trapper
int_fatal_abort     EQU     int_abort+4     ; hard disk error
int_disk_read       EQU     int_abort+5     ; logical sector disk read
int_disk_write      EQU     int_abort+6     ; logical sector disk write
int_keep_process    EQU     int_abort+7     ; terminate program and stay resident
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
int_spooler         EQU     int_abort+8     ; spooler call
int_fastcon         EQU     int_abort+9     ; fast CON interrupt
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        ELSE
int_abort           EQU     INTTAB          ; abort process
int_command         EQU     int_abort+1     ; call MSDOS
int_terminate       EQU     ALTTAB          ; int to terminate address
int_ctrl_c          EQU     int_terminate+1 ; ^c trapper
int_fatal_abort     EQU     int_terminate+2 ; hard disk error
int_disk_read       EQU     int_abort+5     ; logical sector disk read
int_disk_write      EQU     int_abort+6     ; logical sector disk write
int_keep_process    EQU     int_abort+7     ; terminate program and stay resident
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
int_spooler         EQU     int_terminate+3 ; spooler call
int_fastcon         EQU     int_abort+9     ; fast CON interrupt
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        ENDIF

addr_int_abort          EQU    4 * int_abort
addr_int_command        EQU    4 * int_command
addr_int_terminate      EQU    4 * int_terminate
addr_int_ctrl_c         EQU    4 * int_ctrl_c
addr_int_fatal_abort    EQU    4 * int_fatal_abort
addr_int_disk_read      EQU    4 * int_disk_read
addr_int_disk_write     EQU    4 * int_disk_write
addr_int_keep_process   EQU    4 * int_keep_process
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
addr_int_spooler        EQU    4 * int_spooler
addr_int_fastcon        EQU    4 * int_fastcon
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

BREAK <Disk map>
;  MSDOS partitions the disk into 4 sections:
;
;  phys sector 0:   +-------------------+
;       |           | boot/reserved     |
;       |           +-------------------+
;       |           |  File allocation  |
;       v           |      table(s)     |
;                   |  (multiple copies |
;                   |     are kept)     |
;                   +-------------------+
;                   |     Directory     |
;                   +-------------------+
;                   |     File space    |
;                   +-------------------+
;                   |   Unaddressable   |
;                   |  (to end of disk) |
;                   +-------------------+
;
; All partition boundaries are sector boundaries.  The size of the FAT is
; adjusted to maximize the file space addressable.

BREAK <Directory entry>

;
;       +---------------------------+
;       |  (12 BYTE) filename/ext   |       0       0
;       +---------------------------+
;       |     (BYTE) attributes     |       11      B
;       +---------------------------+
;       |    (10 BYTE) reserved     |       12      C
;       +---------------------------+
;       | (WORD) time of last write |       22      16
;       +---------------------------+
;       | (WORD) date of last write |       24      18
;       +---------------------------+
;       |   (WORD) First cluster    |       26      1A
;       +---------------------------+
;       |     (DWORD) file size     |       28      1C
;       +---------------------------+
;
;   First byte of filename  = E5 -> free directory entry
;                           = 00 -> end of allocated directory
;   Time:   Bits 0-4=seconds/2, bits 5-10=minute, 11-15=hour
;   Date:   Bits 0-4=day, bits 5-8=month, bits 9-15=year-1980
;
dir_entry   STRUC
dir_name    DB      11 DUP (?)          ; file name
dir_attr    DB      ?                   ; attribute bits
dir_pad     DB      10 DUP (?)          ; reserved for expansion
dir_time    DW      ?                   ; time of last write
dir_date    DW      ?                   ; date of last write
dir_first   DW      ?                   ; first allocation unit of file
dir_size_l  DW      ?                   ; low 16 bits of file size
dir_size_h  DW      ?                   ; high 16 bits of file size
dir_entry   ENDS

attr_read_only      EQU      1h
attr_hidden         EQU      2h
attr_system         EQU      4h
attr_volume_id      EQU      8h
attr_directory      EQU     10h
attr_archive        EQU     20h

attr_all            EQU     attr_hidden+attr_system+attr_directory
                                        ; OR of hard attributes for FINDENTRY

attr_ignore         EQU     attr_read_only+attr_archive
                                        ; ignore this(ese) attribute(s)
                                        ; during search first/next

attr_changeable     EQU     attr_read_only+attr_hidden+attr_system+attr_archive
                                        ; changeable via CHMOD

BREAK <File allocation Table information>
;
; The File Allocation Table uses a 12-bit entry for each allocation unit on the
; disk.  These entries are packed, two for every three bytes.  The contents of
; entry number N is found by 1) multiplying N by 1.5; 2) adding the result to
; the base address of the Allocation Table; 3) fetching the 16-bit word at this
; address; 4) If N was odd (so that N*1.5 was not an integer), shift the word
; right four bits; 5) mask to 12 bits (AND with 0FFF hex).  Entry number zero
; is used as an end-of-file trap in the OS and is passed to the BIOS to help
; determine disk format.  Entry 1 is reserved for future use.  The first
; available allocation unit is assigned entry number two, and even though it is
; the first, is called cluster 2.  Entries greater than 0FF8H are end of file
; marks; entries of zero are unallocated.  Otherwise, the contents of a FAT
; entry is the number of the next cluster in the file.
;
; Clusters with bad sectors are tagged with FF7H.  Any non-zero number would do
; because these clusters show as allocated, but are not part of any allocation
; chain and thus will never be allocated to a file.  A particular number is
; selected so that disk checking programs know what to do (ie.  a cluster with
; entry FF7H which is not in a chain is not an error).

BREAK <DPB structure>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;

DIRSTRLEN       EQU     64      ; Max length in bytes of directory strings

dpb     STRUC
dpb_drive           DB      ?   ; Logical drive # assoc with DPB (A=0,B=1,...)
dpb_UNIT            DB      ?   ; Driver unit number of DPB
dpb_sector_size     DW      ?   ; Size of physical sector in bytes
dpb_cluster_mask    DB      ?   ; Sectors/cluster - 1
dpb_cluster_shift   DB      ?   ; Log2 of sectors/cluster
dpb_first_FAT       DW      ?   ; Starting record of FATs
dpb_FAT_count       DB      ?   ; Number of FATs for this drive
dpb_root_entries    DW      ?   ; Number of directory entries
dpb_first_sector    DW      ?   ; First sector of first cluster
dpb_max_cluster     DW      ?   ; Number of clusters on drive + 1
dpb_FAT_size        DB      ?   ; Number of records occupied by FAT
dpb_dir_sector      DW      ?   ; Starting record of directory
dpb_driver_addr     DD      ?   ; Pointer to driver
dpb_media           DB      ?   ; Media byte
dpb_first_access    DB      ?   ; This is initialized to -1 to force a media
                                ; check the first time this DPB is used
dpb_next_dpb        DD      ?   ; Pointer to next Drive parameter block
dpb_current_dir     DW      ?   ; Cluster number of start of current directory
                                ; 0 indicates root, -1 indicates invalid
                                ; (disk ? changed)
dpb_dir_text        DB      DIRSTRLEN DUP(?)
                                ; ASCIZ string of current directory
dpb     ENDS

DPBSIZ  EQU     SIZE dpb        ; Size of the structure in bytes

DSKSIZ  =       dpb_max_cluster ; Size of disk (temp used during init only)
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

BREAK <File Control Block definition>
;
; Field definition for FCBs
; The FCB has the following structure:
;
;       +---------------------------+
;       |   Drive indicator(byte)   |
;       +---------------------------+
;       |    Filename (8 chars)     |
;       +---------------------------+
;       |    Extension (3 chars)    |
;       +---------------------------+
;       |   Current Extent(word)    |
;       +---------------------------+
;       |    Record size (word)     |
;       +---------------------------+
;       |    File Size (2 words)    |
;       +---------------------------+
;       |       Date of write       |
;       +---------------------------+
;       |       Time of write       |
;       +---------------------------+
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
;       | Flags:                    |
;       |  bit 7=0 file/1 device    |
;       |  bit 6=0 if dirty         |
;       |  bits 0-5 deviceid        |
;       +---------------------------+
;       |   first cluster in file   |
;       +---------------------------+
;       | position of last cluster  |
;       +---------------------------+
;       |   last cluster accessed   |   12 bit-+--- packed in 3 bytes
;       +---------------------------+          |
;       |     parent directory      |   <------+
;       +---------------------------+
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;       |    next record number     |
;       +---------------------------+
;       |   random record number    |
;       +---------------------------+
;

sys_fcb     STRUC
fcb_drive   DB      ?
fcb_name    DB      8 DUP (?)
fcb_ext     DB      3 DUP (?)
fcb_EXTENT  DW      ?
fcb_RECSIZ  DW      ?       ; Size of record (user settable)
fcb_FILSIZ  DW      ?       ; Size of file in bytes; used with the following
                            ; word
fcb_DRVBP   DW      ?       ; BP for SEARCH FIRST and SEARCH NEXT
fcb_FDATE   DW      ?       ; Date of last writing
fcb_FTIME   DW      ?       ; Time of last writing
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
fcb_DEVID   DB      ?       ; Device ID number, bits 0-5 if file.
                            ; bit 7=0 for file, bit 7=1 for I/O device
                            ; If file, bit 6=0 if dirty
                            ; If I/O device, bit 6=0 if EOF (input)
                            ;               Bit 5=1 if Raw mode
                            ;               Bit 0=1 if console input device
                            ;               Bit 1=1 if console output device
                            ;               Bit 2=1 if null device
                            ;               Bit 3=1 if clock device
fcb_FIRCLUS DW      ?       ; First cluster of file
fcb_CLUSPOS DW      ?       ; Position of last cluster accessed
fcb_LSTCLUS DW      ?       ; Last cluster accessed and directory
            DB      ?       ; pack 2 12 bit numbers into 24 bits...
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
fcb_NR      DB      ?       ; Next record
fcb_RR      DB      4 DUP (?)               ; Random record
sys_fcb     ENDS

FILDIRENT       = fcb_FILSIZ            ; Used only by SEARCH FIRST and
                                        ; SEARCH NEXT

;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
devid_file_clean        EQU     40h     ; true if file and not written
devid_file_mask_drive   EQU     3Fh     ; mask for drive number

devid_device            EQU     80h     ; true if a device
devid_device_EOF        EQU     40h     ; true if end of file reached
devid_device_raw        EQU     20h     ; true if in raw mode
devid_device_special    EQU     10h     ; true if special device
devid_device_clock      EQU     08h     ; true if clock device
devid_device_null       EQU     04h     ; true if null device
devid_device_con_out    EQU     02h     ; true if console output
devid_device_con_in     EQU     01h     ; true if consle input

;
; structure of devid field as returned by IOCTL is:
;
;       BIT     7   6   5   4   3   2   1   0
;             |---|---|---|---|---|---|---|---|
;             | I | E | R | S | I | I | I | I |
;             | S | O | A | P | S | S | S | S |
;             | D | F | W | E | C | N | C | C |
;             | E |   |   | C | L | U | O | I |
;             | V |   |   | L | K | L | T | N |
;             |---|---|---|---|---|---|---|---|
;       ISDEV = 1 if this channel is a device
;             = 0 if this channel is a disk file
;
;       If ISDEV = 1
;
;             EOF = 0 if End Of File on input
;             RAW = 1 if this device is in Raw mode
;                 = 0 if this device is cooked
;             ISCLK = 1 if this device is the clock device
;             ISNUL = 1 if this device is the null device
;             ISCOT = 1 if this device is the console output
;             ISCIN = 1 if this device is the console input
;
;       If ISDEV = 0
;             EOF = 0 if channel has been written
;             Bits 0-5  are  the  block  device  number  for
;                 the channel (0 = A, 1 = B, ...)
;
devid_ISDEV     EQU     80h
devid_EOF       EQU     40h
devid_RAW       EQU     20h
devid_SPECIAL   EQU     10H
devid_ISCLK     EQU     08h
devid_ISNUL     EQU     04h
devid_ISCOT     EQU     02h
devid_ISCIN     EQU     01h

devid_block_dev EQU     1Fh             ; mask for block device number

;
; find first/next buffer
;
find_buf    STRUC
find_buf_sattr      DB  ?           ; attribute of search
find_buf_drive      DB  ?           ; drive of search
find_buf_name       DB  11 DUP (?)  ; formatted name
find_buf_LastEnt    DW  ?           ; LastEnt
find_buf_ThisDPB    DD  ?           ; This DPB
find_buf_DirStart   DW  ?           ; DirStart
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

find_buf_attr       DB  ?           ; attribute found
find_buf_time       DW  ?           ; time
find_buf_date       DW  ?           ; date
find_buf_size_l     DW  ?           ; low(size)
find_buf_size_h     DW  ?           ; high(size)
find_buf_pname      DB  13 DUP (?)  ; packed name
find_buf    ENDS

BREAK <Process data block>
;
; Process data block (otherwise known as program header)
;

FilPerProc          EQU     20

Process_data_block  STRUC
PDB_Exit_Call       DW      ?           ; INT int_abort system terminate
PDB_block_len       DW      ?           ; size of execution block
                    DB      ?
PDB_CPM_Call        DB  5 DUP (?)       ; ancient call to system
PDB_Exit            DD      ?           ; pointer to exit routine
PDB_Ctrl_C          DD      ?           ; pointer to ^C routine
PDB_Fatal_abort     DD      ?           ; pointer to fatal error
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
PDB_Parent_PID      DW      ?           ; PID of parent (terminate PID)
PDB_JFN_Table       DB  FilPerProc DUP (?)
                                        ; indices into system table
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
PDB_environ         DW      ?           ; seg addr of environment
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
PDB_User_stack      DD      ?           ; stack of self during system calls
PDB_PAD1            DB      1Eh DUP (?)
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
PDB_Call_system     DB      5 DUP (?)   ; portable method of system call
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
PDB_PAD2            DB      6h DUP (?)  ;
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
Process_data_block  ENDS

BREAK <EXEC and EXE file structures>
;
; EXEC arg block - load/go program
;

;
; The following get used as arguments to the EXEC system call.  They indicate
; whether or not the program is executed or whether or not a program header
; gets created.
;
exec_func_no_execute    EQU 1           ; no execute bit
exec_func_overlay       EQU 2           ; overlay bit

Exec0           STRUC
Exec0_environ   DW      ?               ; seg addr of environment
Exec0_com_line  DD      ?               ; pointer to asciz command line
Exec0_5C_FCB    DD      ?               ; default fcb at 5C
Exec0_6C_FCB    DD      ?               ; default fcb at 6C
Exec0           ENDS

Exec1           STRUC
Exec1_environ   DW      ?               ; seg addr of environment
Exec1_com_line  DD      ?               ; pointer to asciz command line
Exec1_5C_FCB    DD      ?               ; default fcb at 5C
Exec1_6C_FCB    DD      ?               ; default fcb at 6C
Exec1_SP        DW      ?               ; stack pointer of program
Exec1_SS        DW      ?               ; stack seg register of program
Exec1_IP        DW      ?               ; entry point IP
Exec1_CS        DW      ?               ; entry point CS
Exec1           ENDS

Exec3           STRUC
Exec3_load_addr DW      ?               ; seg address of load point
Exec3_reloc_fac DW      ?               ; relocation factor
Exec3           ENDS

;
; Exit codes in upper byte
;
Exit_terminate      EQU     0
Exit_abort          EQU     0
Exit_Ctrl_C         EQU     1
Exit_Hard_Error     EQU     2
Exit_Keep_process   EQU     3

;
; EXE file header
;

EXE_file    STRUC
exe_signature   DW  ?                   ; must contain 4D5A  (yay zibo!)
exe_len_mod_512 DW  ?                   ; low 9 bits of length
exe_pages       DW  ?                   ; number of 512b pages in file
exe_rle_count   DW  ?                   ; count of reloc entries
exe_par_dir     DW  ?                   ; number of paragraphs before image
exe_min_BSS     DW  ?                   ; minimum number of para of BSS
exe_max_BSS     DW  ?                   ; max number of para of BSS
exe_SS          DW  ?                   ; stack of image
exe_SP          DW  ?                   ; SP of image
exe_chksum      DW  ?                   ; checksum  of file (ignored)
exe_IP          DW  ?                   ; IP of entry
exe_CS          DW  ?                   ; CS of entry
exe_rle_table   DW  ?                   ; byte offset of reloc table
exe_iov         DW  ?                   ; overlay number (0 for root)
exe_sym_tab     DD  ?                   ; offset of symbol table in file
EXE_file    ENDS

exe_valid_signature     EQU 5A4Dh
exe_valid_old_signature EQU 4D5Ah

symbol_entry    STRUC
sym_value       DD  ?
sym_type        DW  ?
sym_len         DB  ?
sym_name        DB  255 dup (?)
symbol_entry    ENDS

BREAK <Internal system file table format>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
;
; system file table
;

sft             STRUC
sft_link        DD      ?
sft_count       DW      ?               ; number of entries
sft_table       DW      ?               ; beginning of array of the following
sft             ENDS

;
; system file table entry
;

sf_entry        STRUC
sf_ref_count    DB      ?               ; number of processes sharing fcb
sf_mode         DB      ?               ; mode of access
sf_attr         DB      ?               ; attribute of file
sf_fcb          DB      (SIZE sys_fcb) DUP (?)
                                        ; actual FCB
sf_entry        ENDS

sf_default_number   EQU     5h
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

BREAK <Memory arena structure>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
;
; arena item
;
arena   STRUC
arena_signature     DB  ?               ; 4D for valid item, 5A for last item
arena_owner         DW  ?               ; owner of arena item
arena_size          DW  ?               ; size in paragraphs of item
arena   ENDS

arena_owner_system  EQU 0               ; free block indication

arena_signature_normal  EQU 4Dh         ; valid signature, not end of arena
arena_signature_end     EQU 5Ah         ; valid signature, last block in arena
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

BREAK <Machine instruction definitions>

mi_INT          EQU     0CDh
mi_Long_JMP     EQU     0EAh
mi_Long_CALL    EQU     09Ah
mi_Long_RET     EQU     0CBh

BREAK <Standard I/O assignments>

stdin       EQU     0
stdout      EQU     1
stderr      EQU     2
stdaux      EQU     3
stdprn      EQU     4

BREAK <Xenix subfunction assignments>

open_for_read   EQU 0
open_for_write  EQU 1
open_for_both   EQU 2

BREAK <Xenix error codes>

;
; XENIX calls all return error codes through AX.  If an error occurred then the
; carry bit will be set and the error code is in AX.  If no error occurred then
; the carry bit is reset and AX contains returned info.
;

no_error_occurred               EQU     0                                                              ?

error_invalid_function          EQU     1
error_file_not_found            EQU     2
error_path_not_found            EQU     3
error_too_many_open_files       EQU     4
error_access_denied             EQU     5
error_invalid_handle            EQU     6
error_arena_trashed             EQU     7
error_not_enough_memory         EQU     8
error_invalid_block             EQU     9
error_bad_environment           EQU     10
error_bad_format                EQU     11
error_invalid_access            EQU     12
error_invalid_data              EQU     13
;**** unused                    EQU     14
error_invalid_drive             EQU     15
error_current_directory         EQU     16
error_not_same_device           EQU     17
error_no_more_files             EQU     18

alloc_not_enough_memory         EQU     error_not_enough_memory
alloc_arena_trashed             EQU     error_arena_trashed

close_invalid_handle            EQU     error_invalid_handle
close_invalid_function          EQU     error_invalid_function

chdir_path_not_found            EQU     error_path_not_found

chmod_path_not_found            EQU     error_path_not_found
chmod_access_denied             EQU     error_access_denied
chmod_invalid_function          EQU     error_invalid_function

creat_access_denied             EQU     error_access_denied
creat_path_not_found            EQU     error_path_not_found
creat_too_many_open_files       EQU     error_too_many_open_files

curdir_invalid_drive            EQU     error_invalid_drive

dealloc_invalid_block           EQU     error_invalid_block
dealloc_arena_trashed           EQU     error_arena_trashed

dup_invalid_handle              EQU     error_invalid_handle
dup_too_many_open_files         EQU     error_too_many_open_files

dup2_invalid_handle             EQU     error_invalid_handle

exec_invalid_function           EQU     error_invalid_function
exec_bad_environment            EQU     error_bad_environment
exec_bad_format                 EQU     error_bad_format
exec_not_enough_memory          EQU     error_not_enough_memory
exec_file_not_found             EQU     error_file_not_found

filetimes_invalid_function      EQU     error_invalid_function
filetimes_invalid_handle        EQU     error_invalid_handle

findfirst_file_not_found        EQU     error_file_not_found
findfirst_no_more_files         EQU     error_no_more_files
findnext_no_more_files          EQU     error_no_more_files

international_invalid_function  EQU     error_invalid_function

ioctl_invalid_handle            EQU     error_invalid_handle
ioctl_invalid_function          EQU     error_invalid_function
ioctl_invalid_data              EQU     error_invalid_data

lseek_invalid_handle            EQU     error_invalid_handle
lseek_invalid_function          EQU     error_invalid_function

mkdir_path_not_found            EQU     error_path_not_found
mkdir_access_denied             EQU     error_access_denied

open_invalid_access             EQU     error_invalid_access
open_file_not_found             EQU     error_file_not_found
open_access_denied              EQU     error_access_denied
open_too_many_open_files        EQU     error_too_many_open_files

read_invalid_handle             EQU     error_invalid_handle
read_access_denied              EQU     error_access_denied

rename_file_not_found           EQU     error_file_not_found
rename_not_same_device          EQU     error_not_same_device
rename_access_denied            EQU     error_access_denied

rmdir_path_not_found            EQU     error_path_not_found
rmdir_access_denied             EQU     error_access_denied
rmdir_current_directory         EQU     error_current_directory

setblock_invalid_block          EQU     error_invalid_block
setblock_arena_trashed          EQU     error_arena_trashed
setblock_not_enough_memory      EQU     error_not_enough_memory
setblock_invalid_function       EQU     error_invalid_function

unlink_file_not_found           EQU     error_file_not_found
unlink_access_denied            EQU     error_access_denied

write_invalid_handle            EQU     error_invalid_handle
write_access_denied             EQU     error_access_denied

BREAK <system call definitions>

ABORT                           EQU 0   ;  0      0
STD_CON_INPUT                   EQU 1   ;  1      1
STD_CON_OUTPUT                  EQU 2   ;  2      2
STD_AUX_INPUT                   EQU 3   ;  3      3
STD_AUX_OUTPUT                  EQU 4   ;  4      4
STD_PRINTER_OUTPUT              EQU 5   ;  5      5
RAW_CON_IO                      EQU 6   ;  6      6
RAW_CON_INPUT                   EQU 7   ;  7      7
STD_CON_INPUT_NO_ECHO           EQU 8   ;  8      8
STD_CON_STRING_OUTPUT           EQU 9   ;  9      9
STD_CON_STRING_INPUT            EQU 10  ; 10      A
STD_CON_INPUT_STATUS            EQU 11  ; 11      B
STD_CON_INPUT_FLUSH             EQU 12  ; 12      C
DISK_RESET                      EQU 13  ; 13      D
SET_DEFAULT_DRIVE               EQU 14  ; 14      E
FCB_OPEN                        EQU 15  ; 15      F
FCB_CLOSE                       EQU 16  ; 16     10
DIR_SEARCH_FIRST                EQU 17  ; 17     11
DIR_SEARCH_NEXT                 EQU 18  ; 18     12
FCB_DELETE                      EQU 19  ; 19     13
FCB_SEQ_READ                    EQU 20  ; 20     14
FCB_SEQ_WRITE                   EQU 21  ; 21     15
FCB_CREATE                      EQU 22  ; 22     16
FCB_RENAME                      EQU 23  ; 23     17
GET_DEFAULT_DRIVE               EQU 25  ; 25     19
SET_DMA                         EQU 26  ; 26     1A
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
GET_DEFAULT_DPB                 EQU 31  ; 31     1F
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
FCB_RANDOM_READ                 EQU 33  ; 33     21
FCB_RANDOM_WRITE                EQU 34  ; 34     22
GET_FCB_FILE_LENGTH             EQU 35  ; 35     23
GET_FCB_POSITION                EQU 36  ; 36     24
SET_INTERRUPT_VECTOR            EQU 37  ; 37     25
CREATE_PROCESS_DATA_BLOCK       EQU 38  ; 38     26
FCB_RANDOM_READ_BLOCK           EQU 39  ; 39     27
FCB_RANDOM_WRITE_BLOCK          EQU 40  ; 40     28
PARSE_FILE_DESCRIPTOR           EQU 41  ; 41     29
GET_DATE                        EQU 42  ; 42     2A
SET_DATE                        EQU 43  ; 43     2B
GET_TIME                        EQU 44  ; 44     2C
SET_TIME                        EQU 45  ; 45     2D
SET_VERIFY_ON_WRITE             EQU 46  ; 46     2E
; Extended functionality group
GET_DMA                         EQU 47  ; 47     2F
GET_VERSION                     EQU 48  ; 48     30
KEEP_PROCESS                    EQU 49  ; 49     31
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
GET_DPB                         EQU 50  ; 50     32
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
SET_CTRL_C_TRAPPING             EQU 51  ; 51     33
GET_INDOS_FLAG                  EQU 52  ; 52     34
GET_INTERRUPT_VECTOR            EQU 53  ; 53     35
GET_DRIVE_FREESPACE             EQU 54  ; 54     36
CHAR_OPER                       EQU 55  ; 55     37
INTERNATIONAL                   EQU 56  ; 56     38
; XENIX CALLS
;   Directory Group
MKDIR                           EQU 57  ; 57     39
RMDIR                           EQU 58  ; 58     3A
CHDIR                           EQU 59  ; 59     3B
;   File Group
CREAT                           EQU 60  ; 60     3C
OPEN                            EQU 61  ; 61     3D
CLOSE                           EQU 62  ; 62     3E
READ                            EQU 63  ; 63     3F
WRITE                           EQU 64  ; 64     40
UNLINK                          EQU 65  ; 65     41
LSEEK                           EQU 66  ; 66     42
CHMOD                           EQU 67  ; 67     43
IOCTL                           EQU 68  ; 68     44
XDUP                            EQU 69  ; 69     45
XDUP2                           EQU 70  ; 70     46
CURRENT_DIR                     EQU 71  ; 71     47
;    Memory Group
ALLOC                           EQU 72  ; 72     48
DEALLOC                         EQU 73  ; 73     49
SETBLOCK                        EQU 74  ; 74     4A
;    Process Group
EXEC                            EQU 75  ; 75     4B
EXIT                            EQU 76  ; 76     4C
WAIT                            EQU 77  ; 77     4D
FIND_FIRST                      EQU 78  ; 78     4E
;   Special Group
FIND_NEXT                       EQU 79  ; 79     4F
; SPECIAL SYSTEM GROUP
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
SET_CURRENT_PDB                 EQU 80  ; 80     50
GET_CURRENT_PDB                 EQU 81  ; 81     51
GET_IN_VARS                     EQU 82  ; 82     52
SETDPB                          EQU 83  ; 83     53
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
GET_VERIFY_ON_WRITE             EQU 84  ; 84     54
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
DUP_PDB                         EQU 85  ; 85     55
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
RENAME                          EQU 86  ; 86     56
FILE_TIMES                      EQU 87  ; 87     57

SET_OEM_HANDLER                 EQU 248 ; 248    F8
OEM_C1                          EQU 249 ; 249    F9
OEM_C2                          EQU 250 ; 250    FA
OEM_C3                          EQU 251 ; 251    FB
OEM_C4                          EQU 252 ; 252    FC
OEM_C5                          EQU 253 ; 253    FD
OEM_C6                          EQU 254 ; 254    FE
OEM_C7                          EQU 255 ; 255    FF
SUBTTL
                               