SUBTTL Initialized data and data used at DOS initialization
PAGE
; DATA AREA for MS-DOS

IFNDEF  KANJI
KANJI   EQU     0       ;FALSE
ENDIF

CONSTANTS       SEGMENT BYTE PUBLIC 'CONST'
        EXTRN   international_table:BYTE
        EXTRN   Current_Country:WORD


        ORG     0
CONSTRT EQU     $               ; Start of constants segment

        PUBLIC  DevStrLen
DEVSTRLEN DB    3              ; Size of below
        PUBLIC  DevString
DEVSTRING DB    "DEV"          ; Dummy device directory

;
; Table of routines for assignable devices
;
; MSDOS allows assignment if the following standard devices:
;   stdin  (usually CON input)
;   stdout (usually CON output)
;   auxin  (usually AUX input)
;   auxout (usually AUX output)
;   stdlpt (usually PRN output)
;
; SPECIAL NOTE:
;   Status of a file is a strange idea.  We choose to handle it in this manner:
;   If we're not at end-of-file, then we always say that we have a character.
;   Otherwise, we return ^Z as the character and set the ZERO flag.  In this
;   manner we can support program written under the old DOS (they use ^Z as EOF
;   on devices) and programs written under the new DOS (they use the ZERO flag
;   as EOF).

; Default FCBs for boot up

sftabl      LABEL   DWORD                     ; file table
            DW      -1
            DW      -1
            DW      sf_default_number  ; Number of entries in table
            DB      sf_default_number DUP ( (SIZE sf_entry) DUP (0))

        I_AM    NoSetDir,BYTE           ; true -> do not set directory
        I_am    DidCTRLC,BYTE           ; true -> we did a ^C exit
        I_am    SpaceFlag,BYTE          ; true -> embedded spaces are allowed
                                        ; in FCB
; the next two variables relate to the position of the logical stdout/stdin
; cursor.  They are only meaningful when stdin/stdout are assigned to the
; console.

        i_am    CARPOS,BYTE             ; cursor position in stdin
        i_am    STARTPOS,BYTE           ; position of cursor at beginning
                                        ; of buffered input call
        I_AM    PFLAG,BYTE
        I_AM    VERFLG,BYTE             ; Initialize with verify off
        I_AM    CONTPOS,WORD
        PUBLIC  CHARCO
CHARCO      DB      00000011B           ; Allows statchks every 4 chars...

        I_AM    DMAADD,DWORD            ; User's disk transfer address
                                        ; (disp/seg)
            ORG     $-CONSTRT-4
            DW      80H
            DW      ?

ENDMEM      DW      ?

            PUBLIC  switch_character
switch_character    DB  '/'

            PUBLIC  device_availability
device_availability DB  0FFH

            I_AM    FirstArena,WORD         ; first free block found
            I_AM    BestArena,WORD          ; best free block found
            I_AM    LastArena,WORD          ; last free block found
            I_AM    AllocMethod,BYTE        ; how to alloc first(best)last
            I_AM    arena_head,WORD

; The following block of data is used by SYSINIT.  Do not change the order or
; size of this block

            PUBLIC  SYSINITVAR
SYSINITVAR  LABEL   WORD
        I_AM    DPBHEAD,DWORD           ; Pointer to head of DPB-FAT list
        I_AM    sft_addr,DWORD          ; Pointer to first FCB table
            ORG     $-CONSTRT-4
            short_addr  sftabl
            DW      ?                   ; DOS segment set at INIT

; The following address points to the CLOCK device
        i_am    BCLOCK,DWORD
; The following address is used by DISKSTATCHK it is always points to the
; console input device header
        I_AM    BCON,DWORD              ; Console device entry points
        i_am    NUMIO,BYTE              ; Number of disk tables
MAXSEC      DW      0                   ; Maximum allowed sector size
        I_AM    BUFFHEAD,DWORD          ; Pointer to head of buffer queue
DEVHEAD LABEL   DWORD
        I_AM    NULDEV,DWORD            ; Set to list start passed by 
					; BIOS at DOS Init

        DW      DEVTYP OR ISNULL
        short_addr  SNULDEV
        short_addr  INULDEV
        DB      "NUL     "


        i_am    DAY,BYTE
        i_am    MONTH,BYTE
        i_am    YEAR,WORD
        i_am    DAYCNT,WORD
        i_am    WEEKDAY,BYTE
        ORG     $-CONSTRT-7
        DB      0,0
        DW      0,-1
        DB      0

        I_AM    CURDRV,BYTE             ; Default to drive A
        I_AM    LASTENT,WORD
        i_am    INDOS,BYTE              ; DOS status for interrupt processing
            ORG     $-CONSTRT-1
            DB      0
        I_AM    ErrorMode,BYTE          ; Flag for INT 24 processing
        PUBLIC  WPErr
WPERR       DB      -1                  ; Write protect error flag
        I_AM    CONSWAP,BYTE
        PUBLIC  IDLEINT
IDLEINT     DB      1
        PUBLIC  CNTCFLAG
CNTCFLAG    DB      0                   ; ^C check in dispatch disabled

        PUBLIC  LastBuffer
LASTBUFFER  LABEL   DWORD               ; Buffer queue recency pointer
            DW      -1
            DW      -1

; Combination of all device call parameters

        PUBLIC  DEVCALL
DEVCALL SRHEAD  <>
CALLUNIT    LABEL   BYTE
CALLFLSH    LABEL   WORD
        I_AM    CALLMED,BYTE
CALLBR      LABEL   DWORD
        PUBLIC  CALLXAD
CALLXAD     LABEL   DWORD
        I_AM    CALLRBYT,BYTE
        DB      3 DUP(?)
        PUBLIC CallBPB
CALLBPB     LABEL   DWORD
        I_AM    CALLSCNT,WORD
CALLSSEC    DW      ?

        I_AM    CALLDEVAD,DWORD             ; stash for device entry point

; Same as above for I/O calls

        PUBLIC  IOCall
IOCALL  SRHEAD  <>
IOFLSH  LABEL   WORD
        PUBLIC  IORCHR
IORCHR  LABEL   BYTE
        I_AM    IOMED,BYTE
        I_AM    IOXAD,DWORD
        I_AM    IOSCNT,WORD
        I_AM    IOSSEC,WORD

; Call struct for DSKSTATCHK
        PUBLIC  DSKSTCALL
DSKSTCALL       DB      DRDNDHL
                DB      0
        PUBLIC  DSKSTCOM
DSKSTCOM        DB      DEVRDND
        I_AM    DSKSTST,WORD
                DB      8 DUP (0)
        I_AM    DSKCHRET,BYTE
                short_addr  DEVIOBUF
                DW      ?               ; DOS segment set at Init
        PUBLIC  DSKSTCNT
DSKSTCNT        DW      1
                DW      0

; Days in year
        i_am    YRTAB,8
        ORG     $-CONSTRT-8
        DB      200,166                 ; Leap year
        DB      200,165
        DB      200,165
        DB      200,165

; Days of each month
        i_am    MONTAB,12
        ORG     $-CONSTRT-12
        DB      31                      ; January
        DB      28                      ; February--reset each 
					; time year changes
        DB      31                      ; March
        DB      30                      ; April
        DB      31                      ; May
        DB      30                      ; June
        DB      31                      ; July
        DB      31                      ; August
        DB      30                      ; September
        DB      31                      ; October
        DB      30                      ; November
        DB      31                      ; December

        IF      NOT IBM
        PUBLIC  OEM_HANDLER
OEM_HANDLER     DD      -1
        ENDIF

;WARNING For HIGHMEM version, these two vars must be at the end of the
; Constants segment to prevent them getting overwritten.
        I_AM    CurrentPDB,WORD
        i_am    CreatePDB,BYTE          ; flag for creating a process

        PUBLIC  LEAVEADDR
LEAVEADDR LABEL WORD
        short_addr    LEAVE

CONSTANTS       ENDS

SUBTTL Uninitialized data overlayed by initialization code
PAGE
DATA    SEGMENT WORD PUBLIC 'DATA'
; Init code overlaps with data area below

        ORG     0
        i_am    INBUF,128
        I_AM    CONBUF,131              ; The rest of INBUF and console buffer
        i_am    TIMEBUF,6
        I_AM    DEVIOBUF,2              ; Buffer for I/O under file assignment
        I_AM    EXITHOLD,DWORD

        PUBLIC  DevFCB
DEVFCB  LABEL   BYTE                ; Uses NAME1, NAME2, NAME3 combined
; WARNING..  do not alter size or relative location of the following 4 items
; without first examining FCB_RENAME
        I_AM    NAME1,12                ; File name buffer
        I_AM    ATTRIB,BYTE
        I_AM    NAME2,13
        I_AM    NAME3,14

        I_AM    EXTFCB,BYTE

; WARNING - the following two items are accessed as a word
        I_AM    CREATING,BYTE
        I_AM    DELALL,BYTE

        I_AM    FoundDel,BYTE

        I_AM    user_SP,WORD
        I_AM    user_SS,WORD
        I_AM    CONTSTK,WORD
        I_AM    SECCLUSPOS,BYTE         ; Position of first sector 
					; within cluster
        I_AM    DSKERR,BYTE
        I_AM    TRANS,BYTE
        I_AM    READOP,BYTE
        I_AM    THISDRV,BYTE
        I_AM    THISDPB,DWORD
        I_AM    CLUSFAC,BYTE

; WARNING - the following two items are accessed as a word
        I_AM    DRIVESPEC,BYTE
        I_AM    ROOTSTART,BYTE

        I_AM    CLUSSPLIT,BYTE
        i_am    INSMODE,BYTE
        I_AM    CLUSSAVE,WORD
        I_AM    CLUSSEC,WORD
        I_AM    PREREAD,WORD            ; 0 means preread; 1 means optional
        I_AM    FATBYT,WORD
        I_AM    DEVPT,DWORD
        I_AM    THISFCB,DWORD           ; Address of user FCB

        I_AM    NEXTADD,WORD
        I_AM    RECPOS,4
        I_AM    RECCNT,WORD
        I_AM    LASTPOS,WORD
        I_AM    CLUSNUM,WORD
        I_AM    DIRSEC,WORD
        I_AM    DIRSTART,WORD
        I_AM    SECPOS,WORD             ; Position of first sector accessed
        I_AM    VALSEC,WORD             ; Number of valid (previously written)
					; sectors
        I_AM    BYTSECPOS,WORD          ; Position of first byte within sector
        I_AM    BYTPOS,4                ; Byte position in file of access
        I_AM    BYTCNT1,WORD            ; No. of bytes in first sector
        I_AM    BYTCNT2,WORD            ; No. of bytes in last sector
        I_AM    SECCNT,WORD             ; No. of whole sectors
        I_AM    ENTFREE,WORD
        I_AM    ENTLAST,WORD
        I_AM    NXTCLUSNUM,WORD
        I_AM    GROWCNT,DWORD
        I_AM    CURBUF,DWORD
        I_AM    VOLID,BYTE
        I_AM    NULLDEVPT,DWORD
        I_AM    CINSAV,DWORD
        I_AM    CINDSAV,BYTE
        I_AM    COUTDSAV,BYTE
        I_AM    COUTSAV,DWORD
        PUBLIC  SaveBX
SaveBX  DW      ?
        PUBLIC  SaveDS
SaveDS  DW      ?
        I_AM    ConC_spsave,WORD

        I_AM    exit_code,WORD              ; exit code of last proc.
        I_am    exit_type,BYTE              ; type of exit...

        IF      IBM
;For 2.00 this pads the DOS so that on a 2 disk IBM PC with no
;CONFIG.SYS file the space taken up by BIOS, DOS, res COMMAND is
;about 24K
IBMPAD  DB      540h DUP(?)
        ENDIF

; make those pushes fast!!!
EVEN
        DB      0A0H DUP (?)
        I_am    AuxStack,0A0h
        I_AM    DSKSTACK,0A0h        ; Stack space
        PUBLIC  IOSTACK
IOSTACK LABEL   BYTE

        PUBLIC  NSS
NSS         DW      ?
        PUBLIC  NSP
NSP         DW      ?

PAGE
        INCLUDE MSINIT.ASM

