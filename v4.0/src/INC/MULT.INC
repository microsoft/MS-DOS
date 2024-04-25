;	SCCSID = @(#)mult.asm	1.2 85/04/12
Break <Critical section and Multiplex channels>

;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
; Critical section definitions
;
; These below are subject to leave-all sections
critDisk    EQU     1			; Disk I/O critical section
critDevice  EQU     2			; Device I/O critical section
critShare   EQU     1			; Sharer I/O critical section
critMem     EQU     1			; memory maintenance critical section
critNet     EQU     5			; network critical section
critSFT     EQU     1			; sft table allocation
critIFS     EQU     6			; ifsfunc critical section
; These below are not subject to leave-all sections
critASSIGN  EQU     8			; Assign has munged a system call
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

;
; The current set of defined multiplex channels is (* means documented):
;
;   Channel(h)	Issuer		Receiver    Function
;      00	server		PSPRINT     print job control
;     *01	print/apps	PRINT	    Queueing of files
;      02	BIOS		REDIR	    signal open/close of printers
;
;      05	command 	REDIR	    obtain text of net int 24 message
;     *06	server/assign	ASSIGN	    Install check
;
;      08	external driver IBMBIO	    interface to internal routines
;
;      10	sharer/server	Sharer	    install check
;      11	DOS/server	Redir	    install check/redirection funcs
;      12	sharer/redir	DOS	    dos functions and structure maint
;      13	MSNET		MSNET	    movement of NCBs
;      13	external driver IBMBIO	    Reset_Int_13, allows installation
;					    of alternative INT_13 drivers after
;					    boot_up
;      14 (IBM) DOS		NLSFUNC     down load NLS country info,DOS 3.3
;      14 (MS)	APPS		POPUP	    MSDOS 4 popup screen functions
;      15	APPS		MSCDEX	    CD-ROM extensions interface
;      16	WIN386		WIN386	    Windows communications
;      17	Clipboard	WINDOWS     Clipboard interface
;     *18	Applications	MS-Manger   Toggle interface to manager
;      19	Shell
;      1A	Ansi.sys
;      1B	Fastopen,Vdisk	 IBMBIO     EMS INT 67H stub handler
;
;      AC	Graphics
;      AD	NLS (toronto)
;      AE
;      AF	Mode
;      B0	GRAFTABL	GRAFTABL
;


;MUX 00-3F reserverd for IBM
;MUX 80-BF reserverd for IBM
;MUX 40-7F reserved for Microsoft
;MUX C0-FF users



MultSHARE   EQU     10h 		; sharer
    ;	1   MFT_enter
    ;	2   MFTClose
    ;	3   MFTclU
    ;	4   MFTCloseP
    ;	5   MFTCloN
    ;	6   set_block
    ;	7   clr_block
    ;	8   chk_block
    ;	9   MFT_get
    ;	10  ShSave
    ;	11  ShChk
    ;	12  ShCol
    ;	13  ShCloseFile

MultNET     EQU     11h 		; Network support
MultIFS     EQU     11h 		; Network support
    ;	1   IFS_RMDIR
    ;	2   IFS_SEQ_RMDIR
    ;	3   IFS_MKDIR
    ;	4   IFS_SEQ_MKDIR
    ;	5   IFS_CHDIR
    ;	6   IFS_CLOSE
    ;	7   IFS_COMMIT
    ;	8   IFS_READ
    ;	9   IFS_WRITE
    ;	10  IFS_LOCK
    ;	11  IFS_UNLOCK
    ;	12  IFS_DISK_INFO
    ;	13  IFS_SET_FILE_ATTRIBUTE
    ;	14  IFS_SEQ_SET_FILE_ATTRIBUTE
    ;	15  IFS_GET_FILE_INFO
    ;	16  IFS_SEQ_GET_FILE_INFO
    ;	17  IFS_RENAME
    ;	18  IFS_SEQ_RENAME
    ;	19  IFS_DELETE
    ;	20  IFS_SEQ_DELETE
    ;	21  IFS_OPEN
    ;	22  IFS_SEQ_OPEN
    ;	23  IFS_CREATE
    ;	24  IFS_SEQ_CREATE
    ;	25  IFS_SEQ_SEARCH_FIRST
    ;	26  IFS_SEQ_SEARCH_NEXT
    ;	27  IFS_SEARCH_FIRST
    ;	28  IFS_SEARCH_NEXT
    ;	29  IFS_ABORT
    ;	30  IFS_ASSOPER
    ;	31  Printer_SET_STRING
    ;	32  IFSFlushBuf
    ;	33  IFSBufWrite
    ;	34  IFSResetEnvironment
    ;	35  IFSSpoolCheck
    ;	36  IFSSpoolClose

MultDOS     EQU     12h 		; DOS call back
    ;	1   DOS_CLOSE
    ;	2   RECSET
    ;	3   Get DOSGROUP
    ;	4   PATHCHRCMP
    ;	5   OUT
    ;	6   NET_I24_ENTRY
    ;	7   PLACEBUF
    ;	8   FREE_SFT
    ;	9   BUFWRITE
    ;	10  SHARE_VIOLATION
    ;	11  SHARE_ERROR
    ;	12  SET_SFT_MODE
    ;	13  DATE16
    ;	14  SETVISIT
    ;	15  SCANPLACE
    ;	16  SKIPVISIT
    ;	17  StrCpy
    ;	18  StrLen
    ;	19  Ucase
    ;	20  POINTCOMP
    ;	21  CHECKFLUSH
    ;	22  SFFromSFN
    ;	23  GetCDSFromDrv
    ;	24  Get_User_Stack
    ;	25  GetThisDrv
    ;	26  DriveFromText
    ;	27  SETYEAR
    ;	28  DSUM
    ;	29  DSLIDE
    ;	30  StrCmp
    ;	31  initcds
    ;	32  pjfnfromhandle
    ;	33  $NameTrans
    ;	34  CAL_LK
    ;	35  DEVNAME
    ;	36  Idle
    ;	37  DStrLen
    ;	38  NLS_OPEN	  DOS 3.3
    ;	39  $CLOSE	  DOS 3.3
    ;	40  NLS_LSEEK	  DOS 3.3
    ;	41  $READ	  DOS 3.3
    ;	42  FastInit	  DOS 4.0
    ;	43  NLS_IOCTL	  DOS 3.3
    ;	44  GetDevList	  DOS 3.3
    ;	45  NLS_GETEXT	  DOS 3.3
    ;	46  MSG_RETRIEVAL DOS 4.0
    ;	47  FAKE_VERSION  DOS 4.0
    ;
NLSFUNC     EQU     14h 		; NLSFUNC CALL , DOS 3.3
    ;	0   NLSInstall
    ;	1   ChgCodePage
    ;	2   GetExtInfo
    ;	3   SetCodePage
    ;	4   GetCntry
    ;
;FASTOPEN is not chained through INT 2F   ; DOS 3.3 F.C.
;	  it calls Multdos 42 to set up an entry routine address
    ;	0   Install status  (reserved)
    ;	1   Lookup
    ;	2   Insert
    ;	3   Delete
    ;	4   Purge	    (reserved)
