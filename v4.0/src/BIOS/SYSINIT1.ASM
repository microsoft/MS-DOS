	PAGE	,132			;
;	SCCSID = @(#)sysinit1.asm	1.7 85/10/24
TITLE	BIOS SYSTEM INITIALIZATION
%OUT ...SYSINIT1
;==============================================================================
;REVISION HISTORY:
;AN000 - New for DOS Version 4.00 - J.K.
;AC000 - Changed for DOS Version 4.00 - J.K.
;AN00x - PTM number for DOS Version 4.00 - J.K.
;==============================================================================
;AN001; p40 Boot from the system with no floppy diskette drives    6/26/87 J.K.
;AN002; d24  MultiTrack= command added. 			   6/29/87 J.K.
;AN003; d9  Double word mov for 386 machine			   7/15/87 J.K.
;AN004; p447 BUFFERS = 50 /E without EMS installed hangs	   8/25/87 J.K.
;AN005; d184 Set DEVMARK for MEM command			   8/25/87 J.K.
;AN006; p851 Installable files not recognized corretly. 	   9/08/87 J.K.
;AN007; p1299 Set the second entry of DEVMARK for MEM command	   9/25/87 J.K.
;AN008; p1361 New Extended Attribute				   9/28/87 J.K.
;AN009; p1326 Buffers = 50 /e hangs				   9/28/87 J.K.
;AN010; New EMS Interface
;AN011; New Message SKL file					  10/20/87 J.K.
;AN012; P2211 Setting EA=7 for ANSI.SYS hangs the system	  11/02/87 J.K.
;AN013; p2343 Set the name for SYSINIT_BASE for MEM command	  11/11/87 J.K.
;AN014; D358  New device driver INIT function package		  12/03/87 J.K.
;AN015; For Installed module with no parameter			  12/11/87 J.K.
;AN016; D285 Undo the Extended Attribute handling		  12/17/87 J.K.
;AN017; P2806 Show "Error in CONFIG.SYS ..." for INSTALL= command 12/17/87 J.K.
;AN018; P2914 Add Extended Memory Size in SYSVAR		  01/05/88 J.K.
;AN019; P3111 Take out the order dependency of the INSTALL=	  01/25/88 J.K.
;AN020; P3497 Performace fix for new buffer scheme		  02/15/88 J.K.
;AN021; D486 SHARE installation for big media			  02/23/88 J.K.
;AN022; D493 Undo D358 & do not show error message for device driv02/24/88 J.K.
;AN023; D474 Change BUFFERS= /E option to /X for expanded memory  03/16/88 J.K.
;AN024; D506 Take out the order dependency of the IFS=		  03/28/88 J.K.
;AN025; P4086 Memory allocation error when loading SHARE.EXE	  03/31/88 J.K.
;AN026; D517 New Balanced Real memory buffer set up scheme	  04/18/88 J.K.
;AN027; D528 Install XMAEM.SYS first before everything else	  04/29/88 J.K.
;AN028; P4669 SHARE /NC causes an error 			  05/03/88 J.K.
;AN029; P4759 Install EMS INT2fh, INT 67h handler		  05/12/88 J.K.
;AN030; P4934 P4759 INT 2Fh handler number be changed to 1Bh	  05/20/88 J.K.
;==============================================================================

TRUE	    EQU 0FFFFh
FALSE	    EQU 0
CR	    equ 13
LF	    equ 10
TAB	    equ  9

IBMVER	   EQU	   TRUE
IBM	   EQU	   IBMVER
STACKSW    EQU	   TRUE 		;Include Switchable Hardware Stacks
IBMJAPVER  EQU	   FALSE		;If TRUE set KANJI true also
MSVER	   EQU	   FALSE
ALTVECT    EQU	   FALSE		;Switch to build ALTVECT version
KANJI	   EQU	   FALSE
MYCDS_SIZE equ	   88			;J.K. Size of Curdir_List. If it is not
					;the same, then will generate compile error.

;
	IF	IBMJAPVER
NOEXEC	EQU	TRUE
	ELSE
NOEXEC	EQU	FALSE
	ENDIF

DOSSIZE EQU	0A000H
;dossize equ	 0C000H 	;J.K. for the debugging version of IBMDOS.

.xlist
;	INCLUDE dossym.INC
	include smdossym.inc	;J.K. Reduced version of DOSSYM.INC
	INCLUDE devsym.INC
	include ioctl.INC
	include BIOSTRUC.INC
	include smifssym.inc		;AN000;
	include defems.inc		;AN010;
	include DEVMARK.inc		;AN005;
	include cputype.inc

	include version.inc

.list

;AN000 J.K. If MYCDS_SIZE <> CURDIRLEN, then force a compilatiaon error.
	if	MYCDS_SIZE NE CURDIRLEN
	   %OUT  !!! SYSINIT1 COMPILATION FAILED. DIFFERENT CDS SIZE !!!
	   .ERRE   MYCDS_SIZE EQ CURDIRLEN
	endif

	IF	NOT IBMJAPVER
	EXTRN	RE_INIT:FAR
	ENDIF

;---------------------------------------
;Equates for Main stack and stack Initialization program
	IF	STACKSW

EntrySize		equ	8

MinCount		equ	8
DefaultCount		equ	9
MaxCount		equ	64

MinSize 		equ	32
DefaultSize		equ	128
MaxSize 		equ	512

AllocByte		equ	es:byte ptr [bp+0]
IntLevel		equ	es:byte ptr [bp+1]
SavedSP 		equ	es:word ptr [bp+2]
SavedSS 		equ	es:word ptr [bp+4]
NewSP			equ	es:word ptr [bp+6]
Free			equ	0
allocated		equ	1
overflowed		equ	2
clobbered		equ	3


;External variables in IBMBIO for INT19h handling rouitne. J.K. 10/23/86
CODE segment public 'code'
	EXTRN	Int19sem:byte

	IRP	AA,<02,08,09,0A,0B,0C,0D,0E,70,72,73,74,76,77>
		EXTRN Int19OLD&AA:dword
	ENDM
CODE ends
	ENDIF
;---------------------------------------
;J.K. 6/29/87 External variable defined in IBMBIO module for Multi-track
MULTRK_ON	EQU	10000000B	;User spcified Mutitrack=on, or System turns
					; it on after handling CONFIG.SYS file as a
					; default value, if MulTrk_flag = MULTRK_OFF1.
MULTRK_OFF1	EQU	00000000B	;initial value. No "Multitrack=" command entered.
MULTRK_OFF2	EQU	00000001B	;User specified Multitrack=off.

CODE segment public 'code'
	EXTRN	MulTrk_flag:word	;AN002;
CODE ends
;J.K. 6/29/87 End of Multi-track definition.

SYSINITSEG	SEGMENT PUBLIC 'SYSTEM_INIT'

ASSUME	CS:SYSINITSEG,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	BADCOM:BYTE
	EXTRN	SYSSIZE:BYTE
	EXTRN	CONDEV:BYTE,AUXDEV:BYTE,PRNDEV:BYTE,COMMND:BYTE
	extrn	DeviceParameters:byte
	extrn	DevMark_Addr:word
	extrn	SetDevMarkFlag:byte
	extrn	PathString:byte 			;AN021;
	extrn	LShare:byte				;AN021;
	extrn	ShareWarnMsg:byte			;AN021;

	EXTRN	INT24:NEAR,MEM_ERR:NEAR
	EXTRN	DOCONF:NEAR
	extrn	Multi_Pass:NEAR 			;AN024;
	extrn	BadLoad:near
	extrn	Error_Line:near

	PUBLIC	CURRENT_DOS_LOCATION
	PUBLIC	FINAL_DOS_LOCATION
	PUBLIC	DEVICE_LIST
	PUBLIC	SYSI_COUNTRY
	PUBLIC	MEMORY_SIZE
	PUBLIC	DEFAULT_DRIVE
	PUBLIC	BUFFERS
	PUBLIC	FILES
	PUBLIC	NUM_CDS
	PUBLIC	SYSINIT
	PUBLIC	CNTRYFILEHANDLE
	PUBLIC	COMMAND_LINE
	public	Big_Media_Flag				;AN021;Set by IBMINIT

	IF	STACKSW
 ;Internal Stack Information
	PUBLIC	STACK_COUNT
	PUBLIC	STACK_SIZE
	PUBLIC	STACK_ADDR
	ENDIF

	PUBLIC dosinfo,entry_point
	PUBLIC fcbs,keep
	PUBLIC confbot,alloclim
	PUBLIC zero,sepchr,STALL
	PUBLIC count,chrptr,org_count
	PUBLIC bufptr,memlo,prmblk,memhi
	PUBLIC ldoff,area,PACKET,UNITCOUNT
	PUBLIC BREAK_ADDR,BPB_ADDR,drivenumber
	public Config_Size
	public Install_Flag
	public COM_Level
	public CMMT
	public CMMT1
	public CMMT2
	public Cmd_Indicator
	public LineCount
	public ShowCount
	public Buffer_LineNum
	public DoNotShowNum
	public IFS_Flag
	public IFS_RH
	public H_Buffers
	public Buffer_Slash_X			;AN023;
	public ConfigMsgFlag			;AN014;
	public Do_Install_Exec			;AN019;
	public Multi_Pass_Id			;AN024;


;
SYSINIT$:
	IF	STACKSW
.SALL
	  include MSSTACK.INC		;Main stack program and data definitions
;	  include STKMES.INC		;Fatal stack error message
	  include MSBIO.CL5		;Fatal stack error message
.XALL
	    public Endstackcode
Endstackcode	label byte
	ENDIF

;
SYSINIT:
	JMP	GOINIT
DOSINFO 		LABEL	DWORD
			DW	0000
CURRENT_DOS_LOCATION	DW	0000

MSDOS			LABEL	DWORD
ENTRY_POINT		LABEL	DWORD
			DW	0000
FINAL_DOS_LOCATION	DW	0000
DEVICE_LIST		DD	00000000

SYSI_Country		LABEL	DWORD		;J.K. 5/29/86 Pointer to
			DW	0000		;country table in DOS
			DW	0000

Fake_Floppy_Drv 	db	0		;AN001;Set to 1 if this machine
						;does not have any floppies!!!
Big_Media_Flag		db	0		;AN021;Set by IBMINIT if > 32 MB fixed media exist.
;
;Variables for Stack Initialization Program.
	IF	STACKSW
STACK_COUNT		DW	DefaultCount
STACK_SIZE		DW	DefaultSize
STACK_ADDR		DD	00000000
	ENDIF
; various default values

MEMORY_SIZE		DW	0001
DEFAULT_DRIVE		DB	00	;initialized by IBMINIT.
BUFFERS 		DW	-1	; initialized during buffer allocation
H_Buffers		dw	0	;AN000; # of the Heuristic buffers. Initially 0.
Buffer_Pages		dw	0	;AN000; # of extended memory pages for the buffer.
BufferBuckets		dw	0	;AN000;
Buffer_odds		dw	0	;AN000;
SingleBufferSize	dw	?	;AN000; Maximum sector size + buffer header
MaxNumBuf1		db     15	;AN026;Num of buffers in a bucket group 1.
MaxNumBuf2		db     15	;AN026;Num of buffers in a possible bucket group 2.
NthBuck 		db	0	;AN026; 1st bucket group = 1st bucket through Nth Bucket. The rest = second group

IF	BUFFERFLAG

FIRST_PAGE		DW	0, 0
LAST_PAGE		DW	0, 0
NPA640			DW	0
EMS_SAVE_BUF		DB	0,0,0,0,0,0,0,0,0,0,0,0

ENDIF

FILES			DB	8	; enough files for pipe
FCBS			DB	4	; performance for recycling
Keep			DB	0	; keep original set
NUM_CDS 		DB	5	; 5 net drives
CONFBOT 		DW	?
ALLOCLIM		DW	?
FOOSTRNG		DB	"A:\",0
COMMAND_LINE		DB	2,0,"P" ;Default Command.com Args
			DB	29 DUP (0)
ZERO			DB	0
SepChr			DB	0
LineCount		dw	0	;AN000;  Line count in config.sys
ShowCount		db	'     ',CR,LF,'$' ;AN000;  Used to convert Linecount to ASCII.
Buffer_LineNum		dw	0	;AN000; Line count for "BUFFERS=" command if entered.

Sys_Model_Byte		db	0FFh	;model byte used in SYSINIT
Sys_Scnd_Model_Byte	db	0	;secondary model byte used in SYSINIT
;
Buffer_Slash_X		db	0	;AN000;AN023; BUFFERS= ... /X option entered.
Real_IBM_Page_Id	dw	0	;AN029;
IBM_Frame_Seg		dw	0	;AN000; segment value for physical IBM page frame.
Frame_Info_Buffer	dw	(MAX_NUM_PAGEFRAME * 4) dup (0) ;AN010; For EMS. as per spec. 2 words per entry
EMSHandleName		db	'BUFFERS ' ;AN010; 8 char. EMS handle name
EMS_Ctrl_Tab		dd	0	;AN010;
EMS_State_Buf		dd	0	;AN010;
BUF_PREV_OFF		dw	0	;AN020;
EMS_Buf_First		dw	0	;AN020;

	IF	NOT NOEXEC
COMEXE	EXEC0 <0,COMMAND_LINE,DEFAULT_DRIVE,ZERO>
	ENDIF

;------------------------------------------------------------------
;J.K.  2/23/87 ;variables for INSTALL= command.

Multi_Pass_Id		db	0	;AN024;AN027;
Install_Flag		dw	0	;AN000;
   HAVE_INSTALL_CMD	 equ	 00000001b ;AN019; CONFIG.SYS has INSTALL= commands
   HAS_INSTALLED	 equ	 00000010b ;AN019; SYSINIT_BASE installed.
   SHARE_INSTALL	 equ	 00000100b ;AN021; Used to install SHARE.EXE

Config_Size		dw	0	;AN000; size of config.sys file. Set by SYSCONF.ASM
Sysinit_Base_Ptr	dd	0	;AN000; pointer to SYSINIT_BASE
Sysinit_Ptr		dd	0	;AN000; returning addr. from SYSINIT_BASE
CheckSum		dw	0	;AN000; Used by Sum_up

Ldexec_FCB		db	20 dup (' ')	;AN000;big enough
Ldexec_Line		db	0		;AN000;# of parm characters
Ldexec_start		db	' '		;AN000;
Ldexec_parm		db	80 dup (0)	;AN000;

INSTEXE EXEC0 <0,Ldexec_Line,Ldexec_FCB,Ldexec_FCB>  ;AN000;

;AN016; Undo the extended attribute handling
;EA_QueryList		 label	 byte
;			 dw	 1	 ;AN008; I need just one EA info.
;			 db	 02h	 ;AN008; Type is BINARY
;			 dw	 8000h	 ;AN008; Flag is SYSTEM DEFINED.
;			 db	 8	 ;AN008; Length of name is 8 bytes
;			 db	 'FILETYPE' ;AN008; Name is FILETYPE
;Ext_Attr_List		 dw	 1	 ;AN008; Just 1 Extended attribute List
;			 db	 2	 ;AN008;EA_TYPE
;			 dw	 8000h	 ;AN008;FLAG
;			 db	 0	 ;AN008;Failure reason
;			 db	 8	 ;AN008;Length of NAME
;			 dw	 1	 ;AN008;Length of VALUE
;			 db	 'FILETYPE' ;AN008;Name
;Ext_Attr_Value 	 db	 0	 ;AN008;Value
;SIZE_EXT_ATTR_LIST	 equ	 $-Ext_Attr_List	 ;AN008;
;
;;Extended attribute value
;EA_INSTALLABLE 	 equ	 4	 ;AN008;Value for Installable file

;------------------------------------------------------------------
;J.K. 5/15/87  ;Request header, variables for IFS= command.

IFS_Flag	dw	0			;AN000; Set to 1 if it is an IFS.
   IS_IFS	  equ	00000001b		;IFS command?
   NOT_IFS	  equ	11111110b

IFS_RH	IFSRH <LENGTH_INIT, IFSINIT,,,,>	;AN000; IFS initialization request packet

;------------------------------------------------------------------
;Variables for Comment=
COM_Level	db	0		;AN000;level of " " in command line
CMMT		db	0		;AN000;length of COMMENT string token
CMMT1		db	0		;AN000;token
CMMT2		db	0		;AN000;token
Cmd_Indicator	db	?		;AN000;
DoNotShowNum	db	0		;AN000;

;------------------------------------------------------------------
COUNT		DW	0000
Org_Count	dw	0000		;AN019;
CHRPTR		DW	0000
CntryFilehandle DW 0000
Old_Area	dw	0		;AN013;
Impossible_Owner_Size dw 0		;AN013; Paragraph
;------------------------------------------------------------------
BucketPTR LABEL  dword			;AN000;
BUFPTR	LABEL	DWORD			;LEAVE THIS STUFF IN ORDER!
MEMLO	DW	0
PRMBLK	LABEL	WORD
MEMHI	DW	0
LDOFF	DW	0
AREA	DW	0

PACKET			DB	24	;AN014; Was 22
			DB	0
			DB	0	;INITIALIZE CODE
			DW	0
			DB	8 DUP (?)
UNITCOUNT		DB	0
BREAK_ADDR		DD	0
BPB_ADDR		DD	0
DriveNumber		DB	0
ConfigMsgFlag		dw	0	;AN014;AN022; Used to control "Error in CONFIG.SYS line #" message

TempStack		DB	80h DUP (?)

GOINIT:
;J.K. before doing anything else, let's set the model byte
;SB33043*****************************************************************
	mov	ah,0c0h 		;get system configuration     ;SB ;3.30*
	int	15h			; *			      ;SB ;3.30*
;SB33043*****************************************************************
	jc	No_ROM_Config
	cmp	ah, 0			; double check
	jne	No_ROM_Config
	mov	al, ES:[BX.bios_SD_modelbyte]
	mov	cs:[Sys_Model_Byte], al
	mov	al, ES:[BX.bios_SD_scnd_modelbyte]
	mov	cs:[Sys_Scnd_Model_Byte], al
	jmp	short Move_Myself
No_ROM_Config:				; Old ROM
	mov	ax, 0f000h
	mov	ds, ax
	mov	al, byte ptr ds:[0fffeh]
	mov	cs:[Sys_Model_Byte], al ;set the model byte.
;J.K.6/24/87 Set Fake_Floppy_Drv if there is no diskette drives in this machine.
;SB34SYSINIT1001********************************************************
;SB	execute the equipment determination interrupt and then
;SB	check the returned value to see if we have any floppy drives
;SB	if we have no floppy drive we set cs:Fake_Floppy_Drv to 1
;SB	See the AT Tech Ref BIOS listings for help on the equipment
;SB	flag interrupt (11h)

	int	11h
	test	ax,1			; has floppy ?
	jnz	Move_Myself
	mov	cs:Fake_Floppy_Drv,1	; no floppy, fake.

;SB34SYSINIT1001********************************************************
Move_Myself:
	CLD				; Set up move
	XOR	SI,SI
	MOV	DI,SI

	IF	MSVER
	MOV	CX,cs:[MEMORY_SIZE]
	CMP	CX,1			; 1 means do scan
	JNZ	NOSCAN
	MOV	CX,2048 		;START SCANNING AT 32K BOUNDARY
	XOR	BX,BX

MEMSCAN:INC	CX
	JZ	SETEND
	MOV	DS,CX
	MOV	AL,[BX]
	NOT	AL
	MOV	[BX],AL
	CMP	AL,[BX]
	NOT	AL
	MOV	[BX],AL
	JZ	MEMSCAN
SETEND:
	MOV	cs:[MEMORY_SIZE],CX
	ENDIF

	IF	IBMVER OR IBMJAPVER
	MOV	CX,cs:[MEMORY_SIZE]
	ENDIF

NOSCAN: 				; CX is mem size in para
	MOV	AX,CS
	MOV	DS,AX
ASSUME	DS:SYSINITSEG

	MOV	AX,OFFSET SYSSIZE
	Call	ParaRound
	SUB	CX,AX			;Compute new sysinit location
	MOV	ES,CX
	MOV	CX,OFFSET SYSSIZE + 1
	SHR	CX,1			;Divide by 2 to get words
	REP	MOVSW			;RELOCATE SYSINIT

	ASSUME	ES:SYSINITSEG

	PUSH	ES
	MOV	AX,OFFSET SYSIN
	PUSH	AX

AAA_DUMMY	PROC	FAR
	RET
AAA_DUMMY	ENDP
;
;	MOVE THE DOS TO ITS PROPER LOCATION
;
SYSIN:

	ASSUME	DS:NOTHING,ES:SYSINITSEG,SS:NOTHING

	MOV	AX,[CURRENT_DOS_LOCATION]   ; Where it is (set by BIOS)
	MOV	DS,AX
	MOV	AX,[FINAL_DOS_LOCATION]     ; Where it is going (set by BIOS)
	MOV	ES,AX

	ASSUME	ES:NOTHING

	XOR	SI,SI
	MOV	DI,SI

	MOV	CX,DOSSIZE/2
	REP	MOVSW

	LDS	SI,[DEVICE_LIST]	; Set for call to DOSINIT
	MOV	DX,[MEMORY_SIZE]	; Set for call to DOSINIT

	CLI
	MOV	AX,CS
	MOV	SS,AX
	MOV	SP,OFFSET LOCSTACK	; Set stack

	ASSUME	SS:SYSINITSEG

	IF	NOT ALTVECT
	STI				; Leave INTs disabled for ALTVECT
	ENDIF
LOCSTACK LABEL BYTE

	CALL	MSDOS			; Call DOSINIT
					;ES:DI -> SysInitVars_Ext
	mov	ax, word ptr es:[di.SYSI_InitVars] ;J.K. 5/29/86
	mov	word ptr [dosinfo], ax
	mov	ax, word ptr es:[di.SYSI_InitVars+2]
	mov	word ptr [dosinfo+2],ax ;set the sysvar pointer

	mov	ax, word ptr es:[di.SYSI_Country_Tab]
	mov	word ptr [SYSI_Country],ax
	mov	ax, word ptr es:[di.SYSI_Country_Tab+2]
	mov	word ptr [SYSI_Country+2],ax	;set the SYSI_Country pointer J.K.

	les	di, dosinfo		;es:di -> dosinfo

	clc					;AN018;Get the extended memory size
;SB34SYSINIT1002**************************************************************
;SB	execute the get extended memory size subfunction in the BIOS INT 15h
;SB	if the function reports an error do nothing else store the extended
;SB	memory size reported at the appropriate location in the dosinfo buffer
;SB	currently pointed to by es:di.	Use the offsets specified in the
;SB	definition of the sysinitvars struct in inc\sysvar.inc
;SB		5 LOCS

	mov	ah,88h
	int	15h				;check extended memory size
	jc	No_Ext_Memory
	mov	es:[di].SYSI_EXT_MEM,ax 	;save extended memory size
No_Ext_Memory:

;SB34SYSINIT1002**************************************************************
	mov	word ptr es:[di.SYSI_IFS], -1	;AN000; Initialize SYSI_IFS chain.
	mov	word ptr es:[di.SYSI_IFS+2], -1 ;AN000;

	mov	ax, es:[di.SYSI_MAXSEC] 	;AN020; Get the sector size
	add	ax, BUFINSIZ			;AN020; size of buffer header
	mov	[SingleBufferSize], ax		;AN020; total size for a buffer

	mov	al, Default_Drive		;AN000;Get the 1 based boot drive number set by IBMINIT
	mov	es:[di.SYSI_BOOT_DRIVE], al	;AN000; set SYSI_BOOT_DRIVE

; Determine if 386 system...
	Get_CPU_Type			; macro to determine cpu type
	cmp	ax, 2			; is it a 386?
	jne	Not_386_System		; no: don't mess with flag
	mov	es:[di.SYSI_DWMOVE], 1		  ;AN003;
Not_386_System: 				  ;AN003;
	MOV	AL,ES:[DI.SYSI_NUMIO]
	MOV	DriveNumber,AL		; Save start of installable block drvs

	MOV	AX,CS
	SUB	AX,11H			; room for header we will copy shortly
	mov	cx, [SingleBufferSize]	;AN020;Temporary Single buffer area
	shr	cx, 1			;AN020;
	shr	cx, 1			;AN020;
	shr	cx, 1			;AN020;
	shr	cx, 1			;AN020; Paragraphs
	inc	cx			;AN020;
	sub	ax, cx			;AN020;
	MOV	[CONFBOT],AX		; Temp "unsafe" location

	push	es			;AN020;
	push	di			;AN020;
	les	di, es:[di.SYSI_BUF]	;AN020;get the buffer hash entry pointer
	les	di, es:[di.HASH_PTR]	;AN020;
	mov	word ptr es:[di.BUFFER_BUCKET],0	;AN020;
	mov	word ptr es:[di.BUFFER_BUCKET+2], ax	;AN020;
	mov	es, ax			;AN020;
	xor	ax, ax			;AN020;
	mov	di, ax			;AN020;es:di -> Single buffer
	mov	es:[di.BUF_NEXT], ax	;AN020;points to itself
	mov	es:[di.BUF_PREV], ax	;AN020;points to itself
	mov	word ptr es:[di.BUF_ID],00FFh	       ;AN020;free buffer, clear flag
	mov	word ptr es:[di.BUF_SECTOR], 0	       ;AN020;
	mov	word ptr es:[di.BUF_SECTOR+2], 0       ;AN020;
	pop	di			;AN020;
	pop	es			;AN020;

	PUSH	DS			; Save as input to RE_INIT
	PUSH	CS
	POP	DS
ASSUME	DS:SYSINITSEG
	CALL	TEMPCDS 		; Set up CDSs so RE_INIT and SYSINIT
					;   can make DISK system calls

	POP	DS			; Recover DS input to RE_INIT
ASSUME	DS:NOTHING

	IF	NOT IBMJAPVER
	CALL	RE_INIT 		; Re-call the BIOS
	ENDIF

	STI				; INTs OK
	CLD				; MAKE SURE
; DOSINIT has set up a default "process" (PHP) at DS:0. We will move it out
; of the way by putting it just below SYSINIT at end of memory.
	MOV	BX,CS
	SUB	BX,10H
	MOV	ES,BX
	XOR	SI,SI
	MOV	DI,SI
	MOV	CX,80H
	REP	MOVSW
	MOV	WORD PTR ES:[PDB_JFN_Pointer + 2],ES	; Relocate
	MOV	AH,SET_CURRENT_PDB
	INT	21H			; Tell DOS we moved it
	PUSH	DS
	PUSH	CS
	POP	DS
ASSUME	DS:SYSINITSEG
	MOV	DX,OFFSET INT24 	;SET UP INT 24 HANDLER
	MOV	AX,(SET_INTERRUPT_VECTOR SHL 8) OR 24H
	INT	21H

	MOV	BX,0FFFFH
	MOV	AH,ALLOC
	INT	21H			;FIRST TIME FAILS
	MOV	AH,ALLOC
	INT	21H			;SECOND TIME GETS IT
	MOV	[AREA],AX
	MOV	[MEMHI],AX		; MEMHI:MEMLO now points to
					; start of free memory
	IF	ALTVECT
	MOV	DX,OFFSET BOOTMES
	invoke	PRINT			;Print message DOSINIT couldn't
	ENDIF

	POP	DS
ASSUME	DS:NOTHING

	MOV	DL,[DEFAULT_DRIVE]
	OR	DL,DL
	JZ	NODRVSET		; BIOS didn't say
	DEC	DL			;A = 0
	MOV	AH,SET_DEFAULT_DRIVE
	INT	21H			;SELECT THE DISK
;J.K.  2/23/87	Modified to handle INSTALL= command.
NODRVSET:
	CALL	DOCONF			;DO THE CONFIG STUFF
	inc	cs:Multi_Pass_Id	;AN027;
	call	Multi_Pass		;AN027;
	inc	cs:Multi_Pass_Id	;AN024;
	call	Multi_Pass		;AN024;
	call	EndFile
	test	Install_Flag, HAVE_INSTALL_CMD		;AN019;
	jz	DoLast					;AN019;
	inc	cs:Multi_Pass_Id			;AN024;
	call	Multi_Pass				;AN019;AN024; Execute INSTALL= commands

;J.K. [AREA] has the segment address for the allocated memory of SYSINIT,CONFBOT.
;Free the CONFBOT area used for CONFIG.SYS and SYSINIT itself.
DoLast:
	call	LoadShare		;AN021; Try to load share.exe, if needed.
	mov	cs:[DoNotShowNum], 1	;AN000; Done with CONFIG.SYS. Do not show line number message.
	mov	cx, [area]		;AN000;
	mov	es, cx			;AN000;
	mov	ah, 49h 		;AN000; Free allocated memory for command.com
	int	21h			;AN000;

	test	cs:[Install_flag], HAS_INSTALLED ;AN013; SYSINIT_BASE installed?
	jz	Skip_Free_SYSINITBASE		 ;AN013; No.
;Set Block from the Old_Area with Impossible_Owner_size.
;This will free the unnecessary SYSINIT_BASE that had been put in memory to
;handle INSTALL= command.
	push	es			       ;AN013;
	push	bx			       ;AN013;
	mov	ax, cs:[Old_Area]	       ;AN013;
	mov	es, ax			       ;AN013;
	mov	bx, cs:[Impossible_Owner_Size] ;AN013;
	mov	ah, SETBLOCK		       ;AN013;
	int	21h			       ;AN013;
	MOV	AX,ES			       ;AN013;
	DEC	AX			       ;AN013;
	MOV	ES,AX			       ;Point to arena
	MOV	ES:[arena_owner],8	       ;Set impossible owner
	pop	bx			       ;AN013;
	pop	es			       ;AN013;
Skip_Free_SYSINITBASE:			       ;AN013;
	IF	NOEXEC
	MOV	BP,DS			       ;SAVE COMMAND.COM SEGMENT
	PUSH	DS
	POP	ES
	MOV	BX,CS
	SUB	BX,10H			       ; Point to current PHP
	MOV	DS,BX
	XOR	SI,SI
	MOV	DI,SI
	MOV	CX,80H
	REP	MOVSW			       ; Copy it to new location for shell
	MOV	WORD PTR ES:[PDB_JFN_Pointer + 2],ES	; Relocate
	MOV	BX,ES
	MOV	AH,SET_CURRENT_PDB
	INT	21H			       ; Tell DOS we moved it
	MOV	ES:[PDB_PARENT_PID],ES	       ;WE ARE THE ROOT
	ENDIF

	PUSH	CS
	POP	DS
ASSUME	DS:SYSINITSEG
;
; SET UP THE PARAMETERS FOR COMMAND
;

	MOV	SI,OFFSET COMMAND_LINE+1

	IF	NOEXEC
	MOV	DI,81H
	ELSE
	PUSH	DS
	POP	ES
	MOV	DI,SI
	ENDIF

	MOV	CL,-1
COMTRANLP:				;FIND LENGTH OF COMMAND LINE
	INC	CL
	LODSB
	STOSB				;COPY COMMAND LINE IN
	OR	AL,AL
	JNZ	COMTRANLP
	DEC	DI
	MOV	AL,CR		       ; CR terminate
	STOSB

	IF	NOEXEC
	MOV	ES:[80H],CL		; Set up header
	MOV	AL,[DEFAULT_DRIVE]
	MOV	ES:[5CH],AL
	ELSE
	MOV	[COMMAND_LINE],CL	;Count
	ENDIF

	MOV	DX,OFFSET COMMND	;NOW POINTING TO FILE DESCRIPTION

	IF	NOEXEC
	MOV	ES,BP			;SET LOAD ADDRESS
	MOV	BX,100H
	CALL	LDFIL			;READ IN COMMAND
	JC	COMERR
	MOV	DS,BP
	MOV	DX,80H
	MOV	AH,SET_DMA		;SET DISK TRANFER ADDRESS
	INT	21H
	CLI
	MOV	SS,BP
	MOV	SP,DX
	STI
	XOR	AX,AX			;PUSH A WORD OF ZEROS
	PUSH	AX
	PUSH	BP			;SET HIGH PART OF JUMP ADDRESS
	MOV	AX,100H
	PUSH	AX			;SET LOW PART OF JUMP ADDRESS
CCC	PROC	FAR
	RET				;CRANK UP COMMAND!
CCC	ENDP

	ELSE
; We are going to open the command interpreter and size it as is done in
; LDFIL.  The reason we must do this is that SYSINIT is in free memory.  If
; there is not enough room for the command interpreter, EXEC will probably
; overlay our stack and code so when it returns with an error SYSINIT won't be
; here to catch it.  This code is not perfect (for instance .EXE command
; interpreters are possible) because it does its sizing based on the
; assumption that the file being loaded is a .COM file.  It is close enough to
; correctness to be usable.

	PUSH	DX			; Save pointer to name

; First, find out where the command interpreter is going to go.
	MOV	BX,0FFFFH
	MOV	AH,ALLOC
	INT	21H			;Get biggest piece
	MOV	AH,ALLOC
	INT	21H			;SECOND TIME GETS IT
	JC	MEMERRJX		; Oooops
	MOV	ES,AX
	MOV	AH,DEALLOC
	INT	21H			; Give it right back
	MOV	BP,BX
; ES:0 points to Block, and BP is the size of the block
;   in para.

; We will now adjust the size in BP DOWN by the size of SYSINIT. We
;   need to do this because EXEC might get upset if some of the EXEC
;   data in SYSINIT is overlayed during the EXEC.
	MOV	BX,[MEMORY_SIZE]
	MOV	AX,CS
	SUB	BX,AX			; BX is size of SYSINIT in Para
	ADD	BX,11H			; Add the SYSINIT PHP
	SUB	BP,BX			; BAIS down
	JC	MEMERRJX		; No Way.

	MOV	AX,(OPEN SHL 8) 	;OPEN THE FILE being EXECED
	STC				;IN CASE OF INT 24
	INT	21H
	JC	COMERR			; Ooops
	MOV	BX,AX			;Handle in BX
	XOR	CX,CX
	XOR	DX,DX
	MOV	AX,(LSEEK SHL 8) OR 2
	STC				;IN CASE OF INT 24
	INT	21H			; Get file size in DX:AX
	JC	COMERR
    ; Convert size in DX:AX to para in AX
	ADD	AX,15			; Round up size for conversion to para
	ADC	DX,0
	MOV	CL,4
	SHR	AX,CL
	MOV	CL,12
	SHL	DX,CL			; Low nibble of DX to high nibble
	OR	AX,DX			; AX is now # of para for file
	ADD	AX,10H			; 100H byte PHP
	CMP	AX,BP			; Will it fit?
	JB	OKLD			; Jump if yes.
MEMERRJX:
	JMP	MEM_ERR

OKLD:
	MOV	AH,CLOSE
	INT	21H			; Close file
	POP	DX			; Recover pointer to name
	PUSH	CS
	POP	ES
	ASSUME	ES:SYSINITSEG
	MOV	BX,OFFSET COMEXE	; Point to EXEC block
	MOV	WORD PTR [BX.EXEC0_COM_LINE+2],CS	; Set segments
	MOV	WORD PTR [BX.EXEC0_5C_FCB+2],CS
	MOV	WORD PTR [BX.EXEC0_6C_FCB+2],CS
	XOR	AX,AX			;Load and go
	MOV	AH,EXEC
	STC				;IN CASE OF INT 24
	INT	21H			;GO START UP COMMAND
	ENDIF
; NOTE FALL THROUGH IF EXEC RETURNS (an error)

COMERR:
	MOV	DX,OFFSET BADCOM	;WANT TO PRINT COMMAND ERROR
	INVOKE	BADFIL
STALL:	JMP	STALL

	PUBLIC	TEMPCDS
TEMPCDS:
ASSUME	DS:SYSINITSEG
	LES	DI,[DOSINFO]

	MOV	CL,BYTE PTR ES:[DI.SYSI_NUMIO]
	XOR	CH,CH
	MOV	ES:[DI.SYSI_NCDS],CL
	MOV	AL,CL
	MOV	AH,SIZE curdir_list
	MUL	AH
	call	ParaRound
	MOV	SI,[CONFBOT]
	SUB	SI,AX
	MOV	[ALLOCLIM],SI		; Can't alloc past here!
	MOV	WORD PTR ES:[DI.SYSI_CDS + 2],SI
	MOV	AX,SI
	MOV	WORD PTR ES:[DI.SYSI_CDS],0
	LDS	SI,ES:[DI.SYSI_DPB]
ASSUME	DS:NOTHING
	MOV	ES,AX
	XOR	DI,DI

FOOSET: 				; Init CDSs
	MOV	AX,WORD PTR [FOOSTRNG]
	STOSW
	MOV	AX,WORD PTR [FOOSTRNG + 2]
	STOSW
	INC	BYTE PTR [FOOSTRNG]
	XOR	AX,AX
	PUSH	CX
	MOV	CX,curdir_flags - 4
	REP	STOSB
	CMP	SI,-1
;	 JNZ	 NORMCDS
;J.K. 6/24/87 Should handle the system that does not have any floppies.
;J.K. In this case, we are going to pretended there are two dummy floppies
;J.K. in the system. Still they have DPB and CDS, but we are going to
;J.K. 0 out Curdir_Flags, Curdir_devptr of CDS so IBMDOS can issue
;J.K. "Invalid drive specification" message when the user try to
;J.K. access them.
	je	Fooset_Zero		;AN001;Don't have any physical drive.
;SB34SYSINIT1003*************************************************************
;SB	Check to see if we are faking floppy drives.  If not go to NORMCDS.
;SB	If we are faking floppy drives then see if this CDS being initialised
;SB	is for drive a: or b: by checking the appropriate field in the DPB
;SB	pointed to by ds:si.  If not for a: or b: then go to NORMCDS.  If
;Sb	for a: or b: then execute the code given below starting at Fooset_Zero.
;SB	For dpb offsets look at inc\dpb.inc.
;SB	 5 LOCS

	cmp	cs:Fake_Floppy_Drv,1	;fake drive ?
	jnz	NORMCDS
	cmp	ds:[si].dpb_drive,02	;check for a: or b:
	jae	NORMCDS

;SB34SYSINIT1003*************************************************************
Fooset_Zero:				;AN001;
	XOR	AX,AX
	MOV	CL,3
	REP	STOSW
	POP	CX
	JMP	SHORT FINCDS
NORMCDS:
	POP	CX
;J.K. If a non-fat based media is detected (by DPB.NumberOfFat == 0), then
; set curdir_flags to 0.  This is for signaling IBMDOS and IFSfunc that
; this media is a non-fat based one.
	cmp	[SI.dpb_FAT_count], 0	;AN000; Non fat system?
	je	SetNormCDS		;AN000; Yes. Set curdir_Flags to 0. AX = 0 now.
	MOV	AX,CURDIR_INUSE 	;AN000;  else, FAT system. set the flag to CURDIR_INUSE.
SetNormCDS:				;AN000;
	STOSW				; curdir_flags
	MOV	AX,SI
	STOSW				; curdir_devptr
	MOV	AX,DS
	STOSW
	LDS	SI,[SI.dpb_next_dpb]
FINCDS:
	MOV	AX,-1
	STOSW				; curdir_ID
	STOSW				; curdir_ID
	STOSW				; curdir_user_word
	mov	ax,2
	stosw				; curdir_end
	mov	ax, 0			;AN000;Clear out 7 bytes (curdir_type,
	stosw				;AN000;  curdir_ifs_hdr, curdir_fsda)
	stosw				;AN000;
	stosw				;AN000;
	stosb				;AN000;
	LOOP	FOOSET
	MOV	BYTE PTR [FOOSTRNG],"A"
	return

;------------------------------------------------------------------------------
; Allocate FILEs
;------------------------------------------------------------------------------
ENDFILE:
; WE ARE NOW SETTING UP FINAL CDSs, BUFFERS, FILES, FCSs STRINGs etc.  We no
; longer need the space taken by The TEMP stuff below CONFBOT, so set ALLOCLIM
; to CONFBOT.

;J.K.  2/23/87 If this procedure has been called to take care of INSTALL= command,
;then we have to save ES,SI registers.

;	 test	 [Install_Flag],IS_INSTALL ;AN000; Called to handle INSTALL=?
;	 jz	 ENDFILE_Cont		 ;AN000;
;	 push	 es			 ;AN000; Save es,si for CONFIG.SYS
;	 push	 si			 ;AN000;
;	 test	 [Install_Flag],HAS_INSTALLED ;AN000; Sysinit_base already installed?
;	 jz	 ENDFILE_Cont		 ;AN000; No. Install it.
;	 jmp	 DO_Install_EXEC	 ;AN000; Just handle "INSTALL=" cmd only.
;ENDFILE_Cont:				 ;AN000;

	push	ds			    ;AN002;
	mov	ax, Code		    ;AN002;
	mov	ds, ax			    ;AN002;
	assume	ds:Code
	cmp	MulTrk_flag, MULTRK_OFF1    ;AN002;=0, MULTRACK= command entered?
	jne	MulTrk_Flag_Done	    ;AN002;
	or	MulTrk_flag, MULTRK_ON	    ;AN002; Default will be ON.
MulTrk_Flag_Done:			    ;AN002;
	pop	ds			    ;AN002;
	assume	ds:nothing

	MOV	AX,[CONFBOT]
	MOV	[ALLOCLIM],AX

	PUSH	CS
	POP	DS
	INVOKE	ROUND
	MOV	AL,[FILES]
	SUB	AL,5
	JBE	DOFCBS
	push	ax			;AN005;
	mov	al, DEVMARK_FILES	;AN005;
	call	SetDevMark		;AN005; Set DEVMARK for SFTS (FILES)
	pop	ax			;AN005;
	XOR	AH,AH			; DO NOT USE CBW INSTRUCTION!!!!!
					;  IT DOES SIGN EXTEND.
	MOV	BX,[MEMLO]
	MOV	DX,[MEMHI]
	LDS	DI,[DOSINFO]		;GET POINTER TO DOS DATA
	LDS	DI,[DI+SYSI_SFT]	;DS:BP POINTS TO SFT
	MOV	WORD PTR [DI+SFLINK],BX
	MOV	WORD PTR [DI+SFLINK+2],DX   ;SET POINTER TO NEW SFT
	PUSH	CS
	POP	DS
	LES	DI,DWORD PTR [MEMLO]	;POINT TO NEW SFT
	MOV	WORD PTR ES:[DI+SFLINK],-1
	MOV	ES:[DI+SFCOUNT],AX
	MOV	BL,SIZE SF_ENTRY
	MUL	BL			;AX = NUMBER OF BYTES TO CLEAR
	MOV	CX,AX
	ADD	[MEMLO],AX		;ALLOCATE MEMORY
	MOV	AX,6
	ADD	[MEMLO],AX		;REMEMBER THE HEADER TOO
	or	[SetDevMarkFlag], FOR_DEVMARK ;AN005;
	INVOKE	ROUND			; Check for mem error before the STOSB
	ADD	DI,AX
	XOR	AX,AX
	REP	STOSB			;CLEAN OUT THE STUFF

;------------------------------------------------------------------------------
; Allocate FCBs
;------------------------------------------------------------------------------
DOFCBS:
	PUSH	CS
	POP	DS
	INVOKE	ROUND
	mov	al, DEVMARK_FCBS	;AN005;='X'
	call	SetDevMark		;AN005;
	MOV	AL,[FCBS]
	XOR	AH,AH			; DO NOT USE CBW INSTRUCTION!!!!!
					;  IT DOES SIGN EXTEND.
	MOV	BX,[MEMLO]
	MOV	DX,[MEMHI]
	LDS	DI,[DOSINFO]		;GET POINTER TO DOS DATA
	ASSUME	DS:NOTHING
	MOV	WORD PTR [DI+SYSI_FCB],BX
	MOV	WORD PTR [DI+SYSI_FCB+2],DX ;SET POINTER TO NEW Table
	MOV	BL,CS:Keep
	XOR	BH,BH
	MOV	[DI+SYSI_keep],BX
	PUSH	CS
	POP	DS
	ASSUME	DS:SYSINITSEG
	LES	DI,DWORD PTR [MEMLO]	;POINT TO NEW Table
	MOV	WORD PTR ES:[DI+SFLINK],-1
	MOV	ES:[DI+SFCOUNT],AX
	MOV	BL,SIZE SF_ENTRY
	MOV	CX,AX
	MUL	BL			;AX = NUMBER OF BYTES TO CLEAR
	ADD	[MEMLO],AX		;ALLOCATE MEMORY
	MOV	AX,size sf-2
	ADD	[MEMLO],AX		;REMEMBER THE HEADER TOO
	or	[SetDevMarkFlag], FOR_DEVMARK ;AN005;
	INVOKE	ROUND			; Check for mem error before the STOSB
	ADD	DI,AX			;Skip over header
	MOV	AL,"A"
FillLoop:
	PUSH	CX			; save count
	MOV	CX,SIZE sf_entry	; number of bytes to fill
	cld
	REP	STOSB			; filled
	MOV	WORD PTR ES:[DI-(SIZE sf_entry)+sf_ref_count],0
	MOV	WORD PTR ES:[DI-(SIZE sf_entry)+sf_position],0
	MOV	WORD PTR ES:[DI-(SIZE sf_entry)+sf_position+2],0
	POP	CX
	LOOP	FillLoop

;------------------------------------------------------------------------------
; Allocate Buffers
;------------------------------------------------------------------------------

; Search through the list of media supported and allocate 3 buffers if the
; capacity of the drive is > 360KB

	CMP	[BUFFERS], -1			; Has buffers been already set?
	je	DoDefaultBuff
	cmp	Buffer_Slash_X, 1		;AN000;
	jne	DO_Buffer			;AN000;
	call	DoEMS				;AN000; Carry set if (enough) EMS is not available
	jc	DoDefaultBuff			;AN000;  Error. Just use default buffer.
DO_Buffer:
	jmp	DOBUFF				; the user entered the buffers=.

DoDefaultBuff:
	mov	[H_Buffers], 0			;AN000; Default is no heuristic buffers.
	MOV	[BUFFERS], 2			; Default to 2 buffers
	PUSH	AX
	PUSH	DS
	LES	BP,CS:[DOSINFO] 		; Search through the DPB's
	LES	BP,DWORD PTR ES:[BP.SYSI_DPB]	; Get first DPB

ASSUME DS:SYSINITSEG
	PUSH	CS
	POP	DS

NEXTDPB:
	; Test if the drive supports removeable media
	MOV	BL, BYTE PTR ES:[BP.DPB_DRIVE]
	INC	BL
	MOV	AX, (IOCTL SHL 8) OR 8
	INT	21H

; Ignore fixed disks
	OR	AX, AX			; AX is nonzero if disk is nonremoveable
	JNZ	NOSETBUF

; Get parameters of drive
	XOR	BX, BX
	MOV	BL, BYTE PTR ES:[BP.DPB_DRIVE]
	INC	BL
	MOV	DX, OFFSET DeviceParameters
	MOV	AX, (IOCTL SHL 8) OR GENERIC_IOCTL
	MOV	CX, (RAWIO SHL 8) OR GET_DEVICE_PARAMETERS
	INT	21H
	JC	NOSETBUF		; Get next DPB if driver doesn't support
					; Generic IOCTL

; Determine capacity of drive
; Media Capacity = #Sectors * Bytes/Sector
	MOV	BX, WORD PTR DeviceParameters.DP_BPB.BPB_TotalSectors

; To keep the magnitude of the media capacity within a word,
; scale the sector size
; (ie. 1 -> 512 bytes, 2 -> 1024 bytes, ...)
	MOV	AX, WORD PTR DeviceParameters.DP_BPB.BPB_BytesPerSector
	XOR	DX, DX
	MOV	CX, 512
	DIV	CX				; Scale sector size in factor of
						; 512 bytes

	MUL	BX				; AX = #sectors * size factor
	OR	DX, DX				; Just in case of LARGE floppies
	JNZ	SETBUF
	CMP	AX, 720 			; 720 Sectors * size factor of 1
	JBE	NOSETBUF
SETBUF:
	MOV	[BUFFERS], 3
	jmp	Chk_Memsize_for_Buffers 	; Now check the memory size for default buffer count
;	 JMP	 BUFSET 			 ; Jump out of search loop
NOSETBUF:
	CMP	WORD PTR ES:[BP.DPB_NEXT_DPB],-1
	jz	Chk_Memsize_for_Buffers
;	 JZ	 BUFSET
	LES	BP,ES:[BP.DPB_NEXT_DPB]
	JMP	NEXTDPB

;J.K. 10/15/86 DCR00014.
;From DOS 3.3, the default number of buffers will be changed according to the
;memory size too.
; Default buffers = 2
; If diskette Media > 360 kb, then default buffers = 3
; If memory size > 128 kb (2000H para), then default buffers = 5
; If memory size > 256 kb (4000H para), then default buffers = 10
; If memory size > 512 kb (8000H para), then default buffers = 15.

Chk_Memsize_for_Buffers:
	cmp	[memory_size], 2000h
	jbe	BufSet
	mov	[buffers], 5
	cmp	[memory_size], 4000h
	jbe	BufSet
	mov	[buffers], 10
	cmp	[memory_size], 8000h
	jbe	BufSet
	mov	[buffers], 15

BUFSET:
ASSUME	DS:NOTHING
	POP	DS
	POP	AX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;J.K. Here we should put extended stuff and new allocation scheme!!!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*******************************************************************************
;									       *
; Function: Actually allocate BUFFERS into the (extended) memory and initialize*
;	    it. 							       *
;	    If it is installed in real memory, the number of buffers in each   *
;	    bucket will be balanced out as far as possible for perfermance.    *
;	    Also, if the user specified the secondary buffer cache, it will    *
;	    be installed in the real memory.				       *
;									       *
; Input :								       *
;    BuffINFO.EMS_MODE - 0=IBM mode, -1 = do not use extended memory.	       *
;    BuffINFO.Frame_Page  -  Page frame 0 segment address		       *
;    MEMHI:MEMLO - Start of the next available memory			       *
;    Buffer_Pages = Number of extended memory pages for buffer		       *
;    BUFFERS = Number of buffers					       *
;    H_Buffers = Number of secondary buffers				       *
;									       *
; Output:								       *
;	BuffINFO.Cache_Count - # of caches to be installed.		       *
;	Hash table set. 						       *
;	BuffINFO set.							       *
;	BufferBuckets set.						       *
;	MaxNumBuf1, MaxNumBuf2, and NthBuck set.			       *
;									       *
; Subroutines to be called:						       *
;									       *
; Logic:								       *
; {									       *
;	IF (BuffINFO.EMS_MODE == -1) THEN				       *
;	      { 							       *
;		IF BUFFERS < 30 THEN					       *
;		     {# of Bucket = 1; MaxNumBuf1 = BUFFERS; NthBuck = 1}      *
;		ELSE {							       *
;		      # of Bucket = BUFFERS/15; 			       *
;		      r = BUFFERS mod 15;				       *
;		      IF r == 0 THEN NthBuck = # of Bucket		       *
;		      ELSE						       *
;			{						       *
;			  AddBuff = r / # of Bucket;			       *
;			  NthBuck = r mod # of Bucket;			       *
;			  MaxNumBuf1 = 15 + AddBuff; /* 1st Bucket - Nth Bucket*
;			  MaxNumBuf2 = 15 + AddBuff +1;/*(N+1)th Bucket to last*
;			}						       *
;		     }							       *
;	      } 							       *
;	ELSE								       *
;	      { 							       *
;		# of Bucket = Buffer_Pages * 2; 	 /* 2 buckets per page *
;	      };							       *
;									       *
;	/*Now allocate memory for Hash table */ 			       *
;	Hash Table Size = (size Buffer_Hash_Entry) * # of Bucket;	       *
;	Set BuffINFO.Hash_ptr to MEMHI:MEMLO;				       *
;	Adjust MEMHI:MEMLO according to Hash table size;		       *
;									       *
;	/*Set buffers*/ 						       *
;	IF (EMS_MODE   <> -1) THEN					       *
;	    Set_EMS_Buffer						       *
;	ELSE			/*Do not use the extended memory */	       *
;	    Set_Buffer; 						       *
;/*Now set the caches if specified.*/					       *
;	IF (BuffINFO.Cache_count > 0)  THEN				       *
;	   {Set BuffINFO.Cache_ptr to MEMHI:MEMLO;			       *
;	    MEMHI:MEMLO = MEMHI:MEMLO + 512 * BuffINFO.Cache_count;	       *
;	   };								       *
; };									       *
;									       *
;*******************************************************************************
DOBUFF: 					;AN000;
	lds	bx, cs:[DosInfo]		;AN000; ds:bx -> SYSINITVAR

	mov	ax, [Buffers]				;AN000;Set SYSI_BUFFERS
	mov	word ptr ds:[bx.SYSI_BUFFERS], ax	;AN000;
	mov	ax, [H_Buffers] 			;AN000;
	mov	word ptr ds:[bx.SYSI_BUFFERS+2], ax	;AN000;

	lds	bx, ds:[bx.SYSI_BUF]		;AN000; now, ds:bx -> BuffInfo
	cmp	ds:[bx.EMS_MODE], -1		;AN000;
;	$IF	E, LONG 			;AN000;
	JE $$XL1
	JMP $$IF1
$$XL1:
	    xor    dx, dx			;AN000;
	    mov    ax, [Buffers]		;AN000; < 99
	    cmp al, 30				;AN026; if less than 30,
;	    $IF  B				;AN026;
	    JNB $$IF2
		mov [BufferBuckets], 1		;AN026;  then put every buffer
		mov ds:[bx.HASH_COUNT], 1	;AN026;    into one bucket
		mov [MaxNumBuf1], al		;AN026;
		mov [NthBuck], 1		;AN026;
;	    $ELSE				;AN026; else...
	    JMP SHORT $$EN2
$$IF2:
		mov cl, 15			;AN026; Magic number 15.
		div cl				;AN026; al=# of buckets, ah=remainders
		push ax 			;AN026; save the result
		xor  ah, ah			;AN026;
		mov  [BufferBuckets], ax	;AN026;
		mov  ds:[bx.HASH_COUNT], ax	;AN026;
		pop  ax 			;AN026;
		or   ah, ah			;AN026;
;		$IF  Z				;AN026;if no remainders
		JNZ $$IF4
		   mov [NthBuck], al		;AN026;then set NthBuck=# of bucket for Set_Buffer proc.
;		$ELSE				;AN026;else
		JMP SHORT $$EN4
$$IF4:
		   mov cl, al			;AN026;
		   mov al, ah			;AN026;remainder/# of buckets
		   xor ah, ah			;AN026; =
		   div cl			;AN026;al=additional num of buffers
		   or  ah, ah			;AN026;ah=Nth bucket
;		   $IF	Z			;AN026;
		   JNZ $$IF6
		      add [MaxNumBuf1], al	;AN026;
		      mov ax, [BufferBuckets]	;AN026;
		      mov [NthBuck], al 	;AN026;
;		   $ELSE			;AN026;
		   JMP SHORT $$EN6
$$IF6:
		      mov [NthBuck], ah 	;AN026;
		      add [MaxNumBuf1], al	;AN026;MaxNumNuf are initially set to 15.
		      add [MaxNumBuf2], al	;AN026;
		      inc [MaxNumBuf1]		;AN026;Additional 1 more buffer for group 1 buckets.
;		   $ENDIF			;AN026;
$$EN6:
;		$ENDIF				;AN026;
$$EN4:
;	    $ENDIF				;AN026;
$$EN2:
;	$ELSE					;AN000; Use the extended memory.
	JMP SHORT $$EN1
$$IF1:
	    mov   ax, [Buffer_Pages]		;AN000;
	    mov   cx, MAXBUCKETINPAGE		;AN000;
	    mul   cx				;AN000; gauranteed to be word boundary.
	    mov   [BufferBuckets], ax		;AN000;
	    mov   ds:[bx.HASH_COUNT], ax	;AN000;
;	$ENDIF					;AN000;
$$EN1:
	invoke Round				;AN000; get [MEMHI]:[MEMLO]
	mov	al, DEVMARK_BUF 		;AN005; ='B'
	call	SetDevMark			;AN005;
;Now, allocate Hash table at [memhi]:[memlo]. AX = Hash_Count.
	mov	ax, [BufferBuckets]		;AN026; # of buckets==Hash_Count
	mov	cx, size BUFFER_HASH_ENTRY	;AN000;
	mul	cx				;AN000; now AX = Size of hash table.
	les	di, ds:[bx.HASH_PTR]		;AN000; save Single buffer address.
	mov	cx, [MemLo]			      ;AN000;
	mov	word ptr ds:[bx.HASH_PTR], cx	      ;AN000; set BuffINFO.HASH_PTR
	mov	cx, [MemHi]			      ;AN000;
	mov	word ptr ds:[bx.HASH_PTR+2], cx       ;AN000;
	mov	[Memlo], ax			      ;AN000;
	or	[SetDevMarkFlag], FOR_DEVMARK	;AN005;
	call	Round				;AN000; get new [memhi]:[memlo]
;Allocate buffers
	push	ds				;AN000; Save Buffer info. ptr.
	push	bx				;AN000;
	cmp	ds:[bx.EMS_MODE], -1		;AN000;
;	$IF	NE				;AN000;
	JE $$IF13
	    call   Set_EMS_Buffer		;AN000;
;	$ELSE					;AN000;
	JMP SHORT $$EN13
$$IF13:
	    call   Set_Buffer			;AN000;
;	$ENDIF					;AN000;
$$EN13:
	pop	bx				;AN000;
	pop	ds				;AN000;
;Now set the secondary buffer if specified.
	cmp	[H_Buffers], 0			;AN000;
;	$IF	NE				;AN000;
	JE $$IF16
	    call   Round			;AN000;
	    mov    cx, [MemLo]			;AN000;
	    mov    word ptr ds:[bx.CACHE_PTR], cx    ;AN000;
	    mov    cx, [MemHi]			     ;AN000;
	    mov    word ptr ds:[bx.CACHE_PTR+2], cx  ;AN000;
	    mov    cx, [H_Buffers]		     ;AN000;
	    mov    ds:[bx.CACHE_COUNT], cx	     ;AN000;
	    mov    ax, 512			;AN000; 512 byte
	    mul    cx				;AN000;
	    mov    [Memlo], ax			;AN000;
	    or	   [SetDevMarkFlag], FOR_DEVMARK ;AN005;
	    call   Round			;AN000;
;	$ENDIF					;AN000;
$$IF16:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;J.K. END OF NEW BUFFER SCHEME.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DOBUFF:
;	 INVOKE  ROUND
;	 DEC	 [BUFFERS]		 ; FIRST DEC acounts for buffer already
;					 ;    in system.
;	 JZ	 BUF1			 ; All done
;	 PUSH	 DS
;	 LES	 DI,BUFPTR
;	 LDS	 BX,DOSINFO
;	 MOV	 AX,WORD PTR [BX.SYSI_BUF]   ; Link in new buffer
;	 MOV	 WORD PTR ES:[DI.buf_link],AX
;	 MOV	 AX,WORD PTR [BX.SYSI_BUF+2]
;	 MOV	 WORD PTR ES:[DI.buf_link+2],AX
;	 MOV	 WORD PTR [BX.SYSI_BUF],DI
;	 MOV	 WORD PTR [BX.SYSI_BUF+2],ES
;	 MOV	 WORD PTR ES:[DI.buf_ID],00FFH	 ;NEW BUFFER FREE
;	 mov	 word ptr es:[di.buf_Sector],0	 ;AN000;
;	 mov	 word ptr es:[di.buf_Sector+2],0 ;AN000;
;	 MOV	 BX,[BX.SYSI_MAXSEC]
;	 POP	 DS
;	 ADD	 BX,BUFINSIZ
;	 ADD	 [MEMLO],BX
;	 JMP	 DOBUFF

;------------------------------------------------------------------------------
; Allocate CDSs
;------------------------------------------------------------------------------
BUF1:
	INVOKE	ROUND
	push	ax				;AN005;
	mov	ax, DEVMARK_CDS 		;AN005;='L'
	call	SetDevMark			;AN005;
	pop	ax				;AN005;
	LES	DI,[DOSINFO]
	MOV	CL,BYTE PTR ES:[DI.SYSI_NUMIO]
	CMP	CL,[NUM_CDS]
	JAE	GOTNCDS 			; User setting must be at least NUMIO
	MOV	CL,[NUM_CDS]
GOTNCDS:
	XOR	CH,CH
	MOV	ES:[DI.SYSI_NCDS],CL
	MOV	AX,[MEMHI]
	MOV	WORD PTR ES:[DI.SYSI_CDS + 2],AX
	MOV	AX,[MEMLO]
	MOV	WORD PTR ES:[DI.SYSI_CDS],AX
	MOV	AL,CL
	MOV	AH,SIZE curdir_list
	MUL	AH
	call	ParaRound
	ADD	[MEMHI],AX
	or	[SetDevMarkFlag], FOR_DEVMARK	;AN005;
	INVOKE	ROUND				; Check for mem error before initializing
	LDS	SI,ES:[DI.SYSI_DPB]
ASSUME	DS:NOTHING
	LES	DI,ES:[DI.SYSI_CDS]
	CALL	FOOSET

;------------------------------------------------------------------------------
; Allocate Space for Internal Stack
;------------------------------------------------------------------------------

	IF	STACKSW

	PUSH	CS
	POP	DS
	ASSUME	DS:SYSINITSEG

	IF	IBM
;Don't install the system stack on the PCjr. Ignore STACKS=command too.
		CMP	[Sys_Model_Byte], 0FDh	     ; PCjr = 0FDh
		JE	SkipStack_brdg
	ENDIF

;J.K. 10/15/86 DCR00013
;If the use does not entered STACKS= command, as a default, do not install
;sytem stacks for PC1, PC XT, PC Portable cases.
;Otherwise, install it to the user specified value or to the default
;value of 9, 128 for the rest of the system.

	cmp	word ptr [stack_addr], -1	;Has the user entered "stacks=" command?
	je	DoInstallStack			;Then install as specified by the user
	cmp	[Sys_Scnd_Model_Byte], 0	;PC1, XT has the secondary model byte = 0
	jne	DoInstallStack			;Other model should have default stack of 9, 128
	cmp	[Sys_Model_Byte], 0FFh		;PC1 ?
	je	SkipStack_brdg
	cmp	[Sys_Model_Byte], 0FEh		;PC/XT or PC Portable ?
	jne	DoInstallStack
SkipStack_Brdg:
	jmp	SkipStack
DoInstallStack:
	mov	ax, [stack_count]		;J.K. Stack_count = 0?
	cmp	ax, 0				;then, stack size must be 0 too.
	jz	SkipStack_brdg			;Don't install stack.
;J.K. 10/21/86 Dynamic Relocation of Stack code.
	call	Round				;[memhi] = Seg. for stack code
						;[memlo] = 0
;J.K. Set DEVMARK block into memory for MEM command
;J.K. DEVMARK_ID = 'S' for stack
	mov	al, DEVMARK_STK 		;AN005;='S'
	call	SetDevMark

	mov	ax, [memhi]
	mov	es, ax				;ES -> Seg. the stack code is going to move.
	assume	es:nothing
	push	cs
	pop	ds
	xor	si,si				;!!We know that Stack code is at the beginning of SYSINIT.
	xor	di,di
	mov	cx, offset Endstackcode
	mov	[memlo],cx
	call	Round				;Have enough space for relocation?
	rep	movsb

	mov	ax, [memlo]
	mov	word ptr [stack_addr],ax	;set for stack area initialization
	mov	ax, [memhi]			;This will be used by Stack_Init routine.
	mov	word ptr [stack_addr+2],ax

;	Space for Internal Stack area = STACK_COUNT(ENTRYSIZE + STACK_SIZE)
	MOV	AX, EntrySize
	ADD	AX, [STACK_SIZE]
	MOV	CX, [STACK_COUNT]
	MUL	CX
	call	ParaRound			; Convert size to pargraphs
	ADD	[MEMHI], AX
	or	[SetDevMarkFlag], FOR_DEVMARK	;AN005;To set the DEVMARK_SIZE for Stack by ROUND routine.
	INVOKE	ROUND				; Check for memory error before
						; continuing
	CALL	StackInit			; Initialize hardware stack. CS=DS=sysinitseg, ES=Relocated stack code & data

SkipStack:
	ENDIF

	PUSH	CS
	POP	DS
	ASSUME	DS:SYSINITSEG

	MOV	AL,[FILES]
	XOR	AH,AH				; DO NOT USE CBW INSTRUCTION!!!!!
						;  IT DOES SIGN EXTEND.
	MOV	CX,AX
	XOR	BX,BX				;Close standard input
	MOV	AH,CLOSE
	INT	21H
	MOV	BX,2
RCCLLOOP:					;Close everybody but standard output
	MOV	AH,CLOSE			; Need output so we can print message
	INT	21H				; in case we can't get new one open.
	INC	BX
	LOOP	RCCLLOOP

	MOV	DX,OFFSET CONDEV
	MOV	AL,2
	MOV	AH,OPEN 			;OPEN CON FOR READ/WRITE
	STC					; Set for possible INT 24
	INT	21H
	JNC	GOAUX
	INVOKE	BADFIL
	JMP	SHORT GOAUX2

GOAUX:	PUSH	AX
	MOV	BX,1				;close standard output
	MOV	AH,CLOSE
	INT	21H
	POP	AX

	MOV	BX,AX				;New device handle
	MOV	AH,XDUP
	INT	21H				;Dup to 1, STDOUT
	MOV	AH,XDUP
	INT	21H				;Dup to 2, STDERR

GOAUX2: MOV	DX,OFFSET AUXDEV
	MOV	AL,2				;READ/WRITE ACCESS
	INVOKE	OPEN_DEV

	MOV	DX,OFFSET PRNDEV
	MOV	AL,1				;WRITE ONLY
	INVOKE	OPEN_DEV

;J.K.9/29/86 *******************
;Global Rearm command for Shared Interrupt devices attached in the system;
;Shared interrupt attachment has some problem when it issues interrupt
;during a warm reboot.	Once the interrupt is presented by the attachment,
;no further interrupts on that level will be presented until a global rearm
;is issued.  By the request of the system architecture group, IBMBIO will
;issue a global rearm after every device driver is loaded.
;To issue a global rearm:	;For PC1, XT, Palace
;			  OUT 02F2h, XX  ; Interrupt level 2
;			  OUT 02F3h, XX  ; Interrupt level 3
;			  OUT 02F4h, XX  ; Interrupt level 4
;			  OUT 02F5h, XX  ; Interrupt level 5
;			  OUT 02F6h, XX  ; Interrupt level 6
;			  OUT 02F7h, XX  ; Interrupt level 7
;
;				;For PC AT, in addition to the above commands,
;				;need to handle the secondary interrupt handler
;			  OUT 06F2h, XX  ; Interrupt level 10
;			  OUT 06F3h, XX  ; Interrupt level 11
;			  OUT 06F4h, XX  ; Interrupt level 12
;			  OUT 06F6h, XX  ; Interrupt level 14
;			  OUT 06F7h, XX  ; Interrupt level 15
;
;				;For Round-Up machine
;			  None.
; where XX stands for any value.
; For your information, after Naples level machine, the system service bios
; call (INT 15h), function AH=0C0h returns the system configuration parameters
;

	cmp	[sys_model_byte], 0FDh		;PCjr?
;	 je	 GoCheckInstall
	je	Set_Sysinit_Base
;SB33045*******************************************************************
	push	ax			;Save Regs		      ;SB ;3.30*
	push	bx			; *			      ;SB ;3.30*
	push	dx			; *			      ;SB ;3.30*
	push	es			; *			      ;SB ;3.30*
	mov	al,0ffh 		;Reset h/w by writing to port ;SB ;3.30*
	mov	dx,2f2h 		;Get starting address	      ;SB ;3.30*
	out	dx,al			; out 02f2h,0ffh
	inc	dx
	out	dx,al			; out 02f3h,0ffh
	inc	dx
	out	dx,al			; out 02f4h,0ffh
	inc	dx
	out	dx,al			; out 02f5h,0ffh
	inc	dx
	out	dx,al			; out 02f6h,0ffh
	inc	dx
	out	dx,al			; out 02f7h,0ffh
;SB33045*******************************************************************

;SB33046*******************************************************************
;SB Secondary global rearm						  ;3.30
	mov	ax,0f000h		;Get machine type	      ;SB ;3.30*
	mov	es,ax			; *			      ;SB ;3.30*
	cmp	byte ptr es:[0fffeh],0fch ;Q:Is it a AT type machine  ;SB ;3.30*
	je	startrearm		  ; *if AT no need to check
	mov	ah,0c0h 		;Get system configuration     ;SB ;3.30*
	int	15h			; *			      ;SB ;3.30*
	jc	finishrearm		; *jmp if old rom	      ;SB ;3.30*
;								      ;SB ;3.30*
; Test feature byte for secondary interrupt controller		      ;SB ;3.30*
;								      ;SB ;3.30*
	test	es:[bx.bios_SD_featurebyte1],ScndIntController ;      ;SB ;3.30*
	je	finishrearm		;Jmp if it is there	      ;SB ;3.30*
startrearm:
	mov	al,0ffh 		;Write any pattern to port    ;SB ;3.30*
	mov	dx,6f2h 		;Get starting address	      ;SB ;3.30*
	out	dx,al			;out 06f2h,0ffh
	inc	dx			;Bump address		      ;SB ;3.30*
	out	dx,al			;out 06f3h,0ffh
	inc	dx			;Bump address		      ;SB ;3.30*
	out	dx,al			;out 06f4h,0ffh
	inc	dx			;Bump address		      ;SB ;3.30*
	inc	dx			;Bump address		      ;SB ;3.30*
	out	dx,al			;out 06f6h,0ffh
	inc	dx			;Bump address		      ;SB ;3.30*
	out	dx,al			;out 06f7h,0ffh
finishrearm:				;			      ;SB ;3.30*
	pop	es			;Restore regs		      ;SB ;3.30*
	pop	dx			; *			      ;SB ;3.30*
	pop	bx			; *			      ;SB ;3.30*
	pop	ax			; *			      ;SB ;3.30*
;SB33046*******************************************************************

;J.K. 9/29/86 Global Rearm end *******************

;------------------------------------------------------------------------------
; Allocate SYSINIT_BASE for INSTALL= command
;------------------------------------------------------------------------------
;J.K. SYSINIT_BASE allocation.
;Check if ENDFILE has been called to handle INSTALL= command.

Set_Sysinit_Base:
;GoCheckInstall:
;	 test	 [Install_Flag], HAVE_INSTALL_CMD ;AN019;;AN021;install sysinit base all the time.
;	 jz	 Skip_SYSINIT_BASE		  ;AN019;

;J.K.--------------------------------------------------------------------------
;SYSINIT_BASE will be established in the secure area of
;lower memory when it handles the first INSTALL= command.
;SYSINIT_BASE is the place where the actual EXEC function will be called and
;will check SYSINIT module in high memory if it is damaged by the application
;program.  If SYSINIT module has been broken, then "Memory error..." message
;is displayed by SYSINIT_BASE.
;------------------------------------------------------------------------------
	push	ax				 ;AN013; Set DEVMARK for MEM command
	mov	ax, [memhi]			 ;AN013;
	sub	ax, [area]			 ;AN013;
	mov	[Impossible_owner_size], ax	 ;AN013;Remember the size in case.
	mov	al, DEVMARK_INST		 ;AN013;
	call	SetDevMark			 ;AN013;
	pop	ax				 ;AN013;

	mov	di, [memhi]			 ;AN000;
	mov	es, di				 ;AN000;
	assume	es:nothing			 ;AN000;
	mov	word ptr [sysinit_base_ptr+2],di ;AN000; save this entry for the next use.
	xor	di, di				 ;AN000;
	mov	word ptr [sysinit_base_ptr], di  ;AN000; es:di -> destination.
	mov	si, offset SYSINIT_BASE 	 ;AN000; ds:si -> source code to be relocated.
	mov	cx, Size_SYSINIT_BASE		 ;AN000;
	add	[memlo],cx			 ;AN000;
	or	cs:[SetDevMarkFlag], FOR_DEVMARK ;AN013;
	call	round				 ;AN000; check mem error. Also, readjust MEMHI for the next use.
	rep	movsb				 ;AN000; reallocate it.

	mov	word ptr [Sysinit_Ptr], offset SYSINITPTR ;AN000; Returing address from
	mov	word ptr [Sysinit_Ptr+2], cs		  ;AN000;  SYSINIT_BASE back to SYSINIT.
	or	[Install_Flag],HAS_INSTALLED	 ;AN000; Set the flag.

;------------------------------------------------------------------------------
; Free the rest of the memory from MEMHI to CONFBOT.  Still from CONFBOT to
; the top of the memory will be allocated for SYSINIT and CONFIG.SYS if
; HAVE_INSTALL_CMD.
;------------------------------------------------------------------------------
;Skip_SYSINIT_BASE:				;AN021;

	INVOKE	ROUND
	MOV	BX,[MEMHI]
	MOV	AX,[AREA]
	mov	[Old_Area], ax			;AN013; Save [AREA]
	MOV	ES,AX				;CALC WHAT WE NEEDED
	SUB	BX,AX
	MOV	AH,SETBLOCK
	INT	21H				;GIVE THE REST BACK
	PUSH	ES
	MOV	AX,ES
	DEC	AX
	MOV	ES,AX				;Point to arena
	MOV	ES:[arena_owner],8		;Set impossible owner
	POP	ES

	mov	bx,0ffffh			;AN000;
	mov	ah,Alloc			;AN000;
	int	21h				;AN000;
	mov	ah,Alloc			;AN000;
	int	21h				;AN000; Allocate the rest of the memory

	mov	[memhi],ax			;AN000; Start of the allocated memory
	mov	[memlo],0			;AN000;   to be used next.

	;;;; At this moment, memory from [MEMHI]:0 to Top-of-the memory is
	;;;; allocated.
	;;;; To protect sysinit, confbot module (From CONFBOT (or =ALLOCLIM at
	;;;; this time) to the Top-of-the memory), here we are going to
	;;;; 1). "SETBLOCK" from MEMHI to CONFBOT.
	;;;; 2). "ALLOC" from CONFBOT to the top of the memory.
	;;;; 3). "Free Alloc Memory" from MEMHI to CONFBOT.
;Memory allocation for SYSINIT, CONFBOT module.
	mov	es, ax				;AN000;
	mov	bx, [confbot]			;AN000;
	sub	bx, ax				;AN000; CONFBOT - MEMHI
	dec	bx				;AN000; Make a room for the memory block id.
	dec	bx				;AN000; make sure!!!.
	mov	ah, SETBLOCK			;AN000;
	int	21h				;AN000; this will free (CONFBOT to top of memory)
	mov	bx, 0ffffh			;AN000;
	mov	ah, ALLOC			;AN000;
	int	21h				;AN000;
	mov	ah, ALLOC			;AN000;
	int	21h				;AN000; allocate (CONFBOT to top of memory)
	mov	[area],ax			;AN000; Save Allocated memory segment.
						;AN000; Need this to free this area for COMMAND.COM.
	mov	es, [memhi]			;AN000;
	mov	ah, 49h 			;AN000; Free Allocated Memory.
	int	21h				;AN000; Free (Memhi to CONFBOT(=AREA))

;	 IF	 NOEXEC
;	 MOV	 BX,0FFFFH		 ;ALLOCATE THE REST OF MEM FOR COMMAND
;	 MOV	 AH,ALLOC
;	 INT	 21H
;	 MOV	 AH,ALLOC
;	 INT	 21H
;	 MOV	 DS,AX
;	 ENDIF

;	 test	 cs:[Install_Flag],IS_INSTALL ;AN000;
;	 jnz	 DO_Install_Exec	      ;AN000;

ENDFILE_Ret:
	return


Do_Install_Exec proc near			;AN000; Now, handles INSTALL= command.

	push	si				;AN000; save SI for config.sys again.

	;;;; We are going to call LOAD/EXEC function.
	;;;;;Set ES:BX to the parameter block here;;;;;;;
	;;;;;Set DS:DX to the ASCIIZ string. Remember that we already has 0
	;;;;;after the filename. So parameter starts after that. If next
	;;;;;character is a line feed (i.e. 10), then assume that the 0
	;;;;;we already encountered used to be a carrage return. In this
	;;;;;case, let's set the length to 0 which will be followed by
	;;;;;carridge return.
;J.K. ES:SI -> command line in CONFIG.SYS. Points to the first non blank
;character after =.
	push	es				;AN000;
	push	ds				;AN000;
	pop	es				;AN000;
	pop	ds				;AN000; es->sysinitseg, ds->confbot seg
	assume	ds:nothing			;AN000;
	mov	dx, si				;AN000; ds:dx->file name,0 in CONFIG.SYS image.
;AN016; UNDO THE EXTENDED ATTRIBUTES HANDLING
;	 mov	 ax, OPEN SHL 8 		 ;AN008;
;	 int	 21h				 ;AN008;
;	 jc	 SysInitPtr			 ;AN008;
;	 mov	 bx, ax 			 ;AN008;handle
;	 call	 Get_Ext_Attribute		 ;AN008;Get the extended attribute.
;	 cmp	 al, EA_INSTALLABLE		 ;AN008;
;	 je	 EA_Installable_OK		 ;AN012;
;	 stc					 ;AN012;
;	 jmp	 SysInitPtr			 ;AN012;
;EA_Installable_OK:				 ;AN012;
	xor	cx,cx				;AN000;
	cld					;AN000;
	mov	cs:Ldexec_start, ' '		;AN015; Clear out the parm area
	mov	di, offset Ldexec_parm		;AN000;
InstallFilename:				;AN000;  skip the file name
	lodsb					;AN000;  al = ds:si; si++
	cmp	al, 0				;AN000;
	je	Got_InstallParm 		;AN000;
	jmp	InstallFilename 		;AN000;
Got_InstallParm:				;AN000;  copy the parameters to Ldexec_parm
	lodsb					;AN000;
	mov	es:[di], al			;AN000;
	cmp	al, LF				;AN000;AN028;  line feed?
	je	Done_InstallParm		;AN000;AN028;
	inc	cl				;AN000;  # of char. in the parm.
	inc	di				;AN000;
	jmp	Got_Installparm 		;AN000;
Done_Installparm:				;AN000;
	mov	byte ptr cs:[Ldexec_line], cl	;AN000;  length of the parm.
	cmp	cl, 0				;AN015;If no parm, then
	jne	Install_Seg_Set 		;AN015; let the parm area
	mov	byte ptr cs:[Ldexec_Start],CR	;AN015;   starts with CR.
Install_Seg_Set:				;AN015;
	mov	word ptr cs:0, 0		;AN000;  Make a null environment segment
	mov	ax, cs				;AN000;   by overlap JMP instruction of SYSINITSEG.
	mov	cs:[INSTEXE.EXEC0_ENVIRON],ax	;AN000; Set the environment seg.
	mov	word ptr cs:[INSTEXE.EXEC0_COM_LINE+2],ax  ;AN000; Set the seg.
	mov	word ptr cs:[INSTEXE.EXEC0_5C_FCB+2],ax    ;AN000;
	mov	word ptr cs:[INSTEXE.EXEC0_6C_FCB+2],ax    ;AN000;
	call	Sum_up				;AN000;
	mov	es:CheckSum, ax 		;AN000;  save the value of the sum
	xor	ax,ax				;AN000;
	mov	ah, EXEC			;AN000;  Load/Exec
	mov	bx, offset INSTEXE		;AN000;  ES:BX -> parm block.
	push	es				;AN000; Save es,ds for Load/Exec
	push	ds				;AN000; these registers will be restored in SYSINIT_BASE.
	jmp	cs:dword ptr SYSINIT_BASE_PTR	;AN000; jmp to SYSINIT_BASE to execute
						; LOAD/EXEC function and check sum.

;J.K. This is the returning address from SYSINIT_BASE.
SYSINITPTR:					;AN000; returning far address from SYSINIT_BASE
	pop	si				;AN000; restore SI for CONFIG.SYS file.
	push	es				;AN000;
	push	ds				;AN000;
	pop	es				;AN000;
	pop	ds				;AN000; now ds - sysinitseg, es - confbot
	jnc	Exec_Exit_Code
	test	cs:Install_Flag, SHARE_INSTALL	;AN021; Called by LoadShare proc?
	jnz	Install_Error_Exit		;AN021; Just exit with carry set.
	push	si				;AN000; Error in loading the file for INSTALL=.
	call	BadLoad 			;AN000; ES:SI-> path,filename,0.
	pop	si				;AN000;
	jmp	Install_Exit_Ret
Exec_Exit_Code:
	test	cs:Install_Flag, SHARE_INSTALL	;AN021; Called by LoadShare proc?
	jnz	Install_Exit_Ret		;AN021; Just exit.
	mov	ah, 4dh 			;AN017;
	int	21h				;AN017;
	cmp	ah, 3				;AN017;Only accept "Stay Resident" prog.
	je	Install_Exit_Ret		;AN017;
	call	Error_Line			;AN017;Inform the user
Install_Error_Exit:				;AN021;
	stc					;AN021;
Install_Exit_Ret:
	ret
Do_Install_Exec endp

Public	ParaRound
ParaRound:
	ADD	AX,15
	RCR	AX,1
	SHR	AX,1
	SHR	AX,1
	SHR	AX,1
	return

;------------------------------------------------------------------------------
;J.K. SYSINIT_BASE module.
;In: After relocation,
;    AX = 4B00h - Load and execute the program DOS function.
;    DS = CONFBOT. Segment of CONFIG.SYS file image
;    ES = Sysinitseg. Segment of SYSINIT module itself.
;    DS:DX = pointer to ASCIIZ string of the path,filename to be executed.
;    ES:BX = pointer to a parameter block for load.
;    SYSSIZE (Byte) - offset vaule of End of SYSINIT module label
;    BIGSIZE (word) - # of word from CONFBOT to SYSSIZE.
;    CHKSUM (word) - Sum of every byte from CONFBOT to SYSSIZE in a
;			word boundary moduler form.
;    SYSINIT_PTR (dword ptr) - Return address to SYSINIT module.
;Note: SYSINIT should save necessary registers and when the control is back


	public	Sysinit_Base
Sysinit_Base:					;AN000;
	mov	word ptr cs:SYSINIT_BASE_SS, SS ;AN000; save stack
	mov	word ptr cs:SYSINIT_BASE_SP, SP ;AN000;
	int	21h				;AN000; LOAD/EXEC DOS call.
	mov	SS, word ptr cs:SYSINIT_BASE_SS ;AN000; restore stack
	mov	SP, word ptr cs:SYSINIT_BASE_SP ;AN000;
	pop	ds				;AN000; restore CONFBOT seg
	pop	es				;AN000; restore SYSINITSEG
	jc	SysInit_Base_End		;AN000; LOAD/EXEC function failed.
						;At this time, I don't have to worry about
						;that SYSINIT module has been broken or not.
	call	Sum_up				;AN000; Otherwise, check if it is good.
	cmp	es:CheckSum, AX 		;AN000;
	je	SysInit_Base_End		;AN000;
;Memory broken. Show "Memory allocation error" message and stall.
	mov	ah, 09h 			;AN000;
	push	cs				;AN000;
	pop	ds				;AN000;
	mov	dx, Mem_alloc_err_msg		;AN000;
	int	21h				;AN000;
Stall_now: jmp	  Stall_now			;AN000;

SysInit_Base_End: jmp	  es:Sysinit_Ptr	;AN000; return back to sysinit module

Sum_up: 					;AN000;
;In:
;   ES - SYSINITSEG.
;OUT: AX - Result
;Remark: Since this routine will only check starting from "LocStack" to the end of
;	 Sysinit segment, the data area,  and the current stack area are not
;	 coverd.  In this sense, this check sum routine only gives a minimal
;	 gaurantee to be safe.
;First sum up CONFBOT seg.
	push	ds				;AN021;
	mov	ax,es:ConfBot			;AN021;
	mov	ds,ax				;AN021;
	xor	si,si				;AN000;
	xor	ax,ax				;AN000;
	mov	cx,es:Config_Size		;AN000; If CONFIG_SIZE has been broken, then this
						;whole test better fail.
	shr	cx, 1				;AN000; make it a word count
	jz	Sum_Sys_Code			;AN025; When CONFIG.SYS file not exist.
Sum1:						;AN000;
	add	ax, ds:word ptr [si]		;AN000;
	inc	si				;AN000;
	inc	si				;AN000;
	loop	Sum1				;AN000;
;Now, sum up SYSINIT module.
Sum_Sys_Code:					;AN025;
	mov	si, offset LocStack		;AN000; Starting after the stack.
						;AN000;  This does not cover the possible STACK code!!!
	mov	cx, offset SYSSIZE		;AN000; SYSSIZE is the label at the end of SYSINIT
	sub	cx, si				;AN000;  From After_Checksum to SYSSIZE
	shr	cx, 1				;AN000;
Sum2:						;AN000;
	add	ax, es:word ptr [si]		;AN000;
	inc	si				;AN000;
	inc	si				;AN000;
	loop	Sum2				;AN000;
	pop	ds				;AN021;
	ret					;AN000;

Sysinit_Base_SS  equ $-Sysinit_Base		;AN000;
		dw	?			;AN000;
Sysinit_Base_SP  equ $-Sysinit_Base		;AN000;
		dw	?			;AN000;
Mem_Alloc_Err_msg equ $-Sysinit_Base		;AN000;
;include BASEMES.INC				;AN000; Memory allocation error message
include MSBIO.CL4				;AN011; Memory allocation error message
End_Sysinit_Base	label	byte		;AN000;
SIZE_SYSINIT_BASE	equ $-Sysinit_Base	;AN000;

;
;AN016; Undo the extended attribute handling
;	 public  Get_Ext_Attribute
;Get_Ext_Attribute	 proc	 near	 ;AN008;
;;In: BX - file handle
;;Out: AL = The extended attribute got from the handle.
;;     AX destroyed.
;;     Carry set when DOS function call fails.
;
;	 push	 ds			 ;AN008;
;	 push	 si			 ;AN008;
;	 push	 es			 ;AN008;
;	 push	 di			 ;AN008;
;	 push	 cx			 ;AN008;
;
;	 push	 cs			 ;AN008;
;	 pop	 ds			 ;AN008;
;	 push	 cs			 ;AN008;
;	 pop	 es			 ;AN008;
;
;	 mov	 Ext_Attr_Value, 0ffh	 ;AN008; Initialize to unrealistic value
;	 mov	 ax, 5702h		 ;AN008;Get extended attribute by handle thru LIST
;	 mov	 si, offset EA_QueryList  ;AN008;
;	 mov	 di, offset Ext_Attr_List ;AN008;
;	 mov	 cx, SIZE_EXT_ATTR_LIST  ;AN008;
;	 int	 21h			 ;AN008;
;	 mov	 al, Ext_Attr_Value	 ;AN008;
;	 pop	 cx			 ;AN008;
;	 pop	 di			 ;AN008;
;	 pop	 es			 ;AN008;
;	 pop	 si			 ;AN008;
;	 pop	 ds			 ;AN008;
;	 ret				 ;AN008;
;Get_Ext_Attribute	 endp		 ;AN008;


;------------------------------------------------------------------------------

DoEMS	proc	near
;*******************************************************************************
; Function: Called prior to DOBUFF subroutine.	Only called when /E option     *
;	    for the buffers= command has been specified.		       *
;	    This routine will check if the extended memory is avaiable,        *
;	    and determine what is the page number.  We only use physical page  *
;	    254.  if it is there, then this routine will calculate the number  *
;	    of pages needed for buffers and will allocate logical pages in the *
;	    extended memory and get the page handle of them.		       *
;									       *
; Input :								       *
;	Buffers - Number of buffers					       *
;	Buffer_LineNum - Saved line number to be used in case of Error case    *
;									       *
; Output:								       *
;    BuffINFO.EMS_Handle						       *
;    Buffer_Pages = Number of pages for buffer in the extended memory.	       *
;    BuffINFO.EMS_MODE =  -1  No extended memory or Non-IBM compatible mode.   *
;    Buffers = the number will be changed to be a multiple of 30.	       *
;    Carry set if no extended memory exist or if it is not big enough.	       *
;    AX, BX, CX, DX destroyed.						       *
;									       *
; Logic:								       *
; {									       *
;	Get EMS Version (AH=46h);					       *
;	If (EMS not installed  or it is not IBM compatible or		       *
;	    (Available_pages * 30 < Buffers) then			       *
;	     {Show error message "Error in CONFIG.SYS line #";		       *
;	     Set carry; Exit }; 					       *
;  else 								       *
;	Buffer_Pages = Roundup(BUFFERS/30);  /* Round up 30 buffers per page*/ *
;	Buffers = Buffer_Pages * 30;	     /* Set the new number of Buffers*/*
;	Allocate Buffer_Pages (AH=43h) and set EMS_Handle;		       *
; };									       *
;									       *
;*******************************************************************************

	push	es				;AN000;
	push	di				;AN000; save es, di
	push	si				;AN010;
	push	bx				;AN010;
	xor	di,di				;AN004; if vector pointer of
	mov	es, di				;AN004; EMS (INT 67h) is 0,0
	mov	di, word ptr es:[EMS_INT * 4]	;AN004; then error.
	mov	ax, word ptr es:[EMS_INT * 4 +2]   ;AN009;
	or	ax,di				   ;AN009;
;	$IF	NZ,AND,LONG			;AN004;
	JNZ $$XL2
	JMP $$IF18
$$XL2:
	les	di, cs:[DosInfo]		;AN000; es:di -> SYSINITVAR
	les	di, es:[di.SYSI_BUF]		;AN000; now, es:di -> BuffInfo

	mov	ah, EMS_STATUS			;AN000; get the status of EMS = 40h
	int	EMS_INT 			;AN000;
	or	ah, ah				;AN000; EMS installed?
;	$IF	Z,AND,LONG			;AN000;
	JZ $$XL3
	JMP $$IF18
$$XL3:
	     mov ah, EMS_VERSION		;AN010;=46h
	     int  EMS_INT			;AN010;
	     cmp AL, EMSVERSION 		;AN010;40h = 4.0
;	$IF    AE,AND,LONG			;AN010;
	JAE $$XL4
	JMP $$IF18
$$XL4:
	     call Check_IBM_PageID		;AN000; IBM (compatible) mode?

IF	BUFFERFLAG
		mov	ax, cs:[LAST_PAGE]
		mov	es:[di.EMS_LAST_PAGE], ax
		mov	ax, cs:[LAST_PAGE+2]
		mov	es:[di.EMS_LAST_PAGE+2], ax
		mov	ax, cs:[FIRST_PAGE]
		mov	es:[di.EMS_FIRST_PAGE], ax
		mov	ax, cs:[FIRST_PAGE+2]
		mov	es:[di.EMS_FIRST_PAGE+2], ax
		mov	ax, cs:[NPA640]
		mov	es:[di.EMS_NPA640], ax
		mov	es:[di.EMS_SAFE_FLAG], 1
ENDIF

;	$IF	NC,AND,LONG			;AN000;
	JNC $$XL5
	JMP $$IF18
$$XL5:
	     mov ah, EMAP_STATE 		;AN010; Check if the size of
	     mov al, GET_MAP_SIZE		;AN010;   the MAP state table
	     mov bx, 1				;AN010; # of pages
	     int  EMS_INT			;AN010;   is acceptable.
	     or  ah, ah 			;AN010;
;	$IF	Z,AND				;AN010;
	JNZ $$IF18
	     cmp al, EMS_MAP_BUFF_SIZE		;AN010; Curretly=12 bytes
;	$IF	BE,AND				;AN010;
	JNBE $$IF18
	     mov  ah, EQ_PAGES			;AN000; Get number of unallocated & total pages = 42h
	     int  EMS_INT			;AN000; result in BX
	     xor  dx, dx			;AN000;
	     mov  ax, cs:[Buffers]		;AN000;
	     mov  cx, MAXBUFFINBUCKET*MAXBUCKETINPAGE	;AN000;
	     call Roundup			;AN000; find out how many pages are needed.
	     cmp  bx, ax			;AN000; AX is the number of pages for [buffers]
;	$IF	AE,AND				;AN000;
	JNAE $$IF18
	     mov  cs:[Buffer_Pages], ax 	;AN000;
	     mov  bx, ax			;AN000; prepare for Get handle call.
	     mul  cx				;AN000;
	     mov  cs:[Buffers], ax		;AN000; set new [Buffers] for the extended memory.
	     mov  ah, E_GET_HANDLE		;AN000; allocate pages = 43h
	     int  EMS_INT			;AN000; page handle in DX.
	     or   ah, ah			;AN000;
;	$IF	Z				;AN000; pages allocated.
	JNZ $$IF18
	     mov ah, EMS_HANDLE_NAME		;AN010;
	     mov al, SET_HANDLE_NAME		;AN010;
	     push es				;AN010;
	     push di				;AN010;
	     push ds				;AN010;
	     push cs				;AN010;
	     pop  ds				;AN010;
	     mov  si, offset EMSHandleName	;AN010;
	     int  EMS_INT			;AN010; Set the handle name
	     pop  ds				;AN010;
	     pop  di				;AN010;
	     pop  es				;AN010;
	     xor  ah,ah 			;AN010;
	     mov es:[di.EMS_MODE], ah		;AN000; put 0 in EMS_mode.
	     mov es:[di.EMS_HANDLE], dx 	;AN000; save EMS handle
	     mov ax, cs:[IBM_Frame_Seg] 	;AN010;
	     mov es:[di.EMS_PAGE_FRAME],ax	;AN010;
	     mov ax, cs:[Real_IBM_Page_Id]	 ;AN029;
	     mov es:[di.EMS_PAGEFRAME_NUMBER], ax;AN029;
	     mov ax, es 			;AN010;
	     mov word ptr cs:[EMS_Ctrl_tab+2],ax ;AN010;
	     mov word ptr cs:[EMS_state_buf+2],ax;AN010;
	     push di				;AN010;save di-> Buffinfo
	     add di, EMS_SEG_CNT		;AN010;
	     mov word ptr cs:[EMS_Ctrl_tab], di ;AN010;
	     pop di				;AN010;
	     add di, EMS_MAP_BUFF		;AN010;
	     mov word ptr cs:[EMS_state_Buf],di ;AN010;
	     clc				;AN000;
;	$ELSE					;AN000;
	JMP SHORT $$EN18
$$IF18:
	     mov  ax, cs:[Buffer_LineNum]	;AN000; Show error message.
	     push cs:[LineCount]		;AN017; Save current line count
	     mov  cs:[LineCount], ax		;AN000; Now, we can change Linecount
	     call Error_Line			;AN000; since we are through with CONFIG.SYS file.
	     pop cs:[LineCount] 		;AN017; Restore line count
	     stc				;AN000;
;	$ENDIF
$$EN18:
	pop	bx				;AN010;
	pop	si				;AN010;
	pop	di				;AN000;
	pop	es				;AN000;
	ret					;AN000;
DoEMS	endp

;
Set_Buffer	proc	near
;*******************************************************************************
;Function: Set buffers in the real memory.				       *
;	   For each hash table entry, set the pointer to the		       *
;	   corresponding hash bucket.					       *
;	   Lastly set the memhi, memlo for the next available free address.    *
;	   ** At the request of IBMDOS, each hash bucket will start at the     *
;	   ** new segment.						       *
;									       *
;Input:    ds:bx -> BuffInfo.						       *
;	   [Memhi]:[MemLo = 0] = available space for the hash bucket.	       *
;	   BufferInfo.Hash_Ptr -> Hash table.				       *
;	   BufferBuckets = # of buckets to install.			       *
;	   SingleBufferSize = Buffer header size + Sector size		       *
;	   MaxNumBuff1 = Number of buffers in the first group of buckets       *
;	   MaxNumBuff2 = Number of buffers in the second group of buckets      *
;	   NthBuck = 1st thru Nth bucket are the first group		       *
;									       *
;Output:   Buffers, hash buckets and Hash table entries established.	       *
;	   [Memhi]:[Memlo] = address of the next available free space.	       *
;									       *
;	   { For (every bucket) 					       *
;	     { Set Hash table entry;					       *
;	       Next buffer ptr = buffer size;				       *
;	       For (every buffer in the bucket) 			       *
;	       { Calll Set_Buffer_Info; /*Set link, id... */		       *
;		 IF (last buffer in a bucket) THEN			       *
;		    {last buffer's next_ptr -> first buffer;                   *
;		     first buffer's prev_ptr -> last buffer;                   *
;		    };							       *
;		 Next buffer ptr += buffer size;			       *
;	       };							       *
;	     }; 							       *
;	     MEMHI:MEMLO = Current Buffer_Bucket add + (# of odd * buffer size)*
;	   };								       *
;*******************************************************************************

	assume	ds:nothing			;AN000;to make sure.
	lds	bx, ds:[bx.HASH_PTR]		;AN000;now, ds:bx -> hash table
	xor	dx, dx				;AN026;To be used to count buckets
;	$DO					;AN000;For each bucket
$$DO21:
	    inc  dl				      ;AN026; Current bucket number
	    mov  word ptr ds:[bx.BUFFER_BUCKET],0     ;AN000;Memlo is 0 after ROUND.
	    mov  di, [MemHi]			      ;AN000;
	    mov  word ptr ds:[bx.BUFFER_BUCKET+2], di ;AN000;Hash entry set.
	    mov word ptr ds:[bx.DIRTY_COUNT], 0       ;AN020;set DIRTY_COUNT, BUFFER_RESERVED to 0.
	    mov  es, di 			;AN000;
	    xor  di, di 			;AN000;es:di -> hash bucket
	    xor  cx, cx 			;AN000
	    xor  ax, ax 			;AN000
;	    $DO 				;AN000;For each buffer in the bucket
$$DO22:
		call Set_Buffer_Info		;AN000;Set buf_link, buf_id...
		inc cx				;AN000;buffer number
		cmp dl, [NthBuck]		;AN026;Current bucket number > NthBuck?
;		$IF BE				;AN026;
		JNBE $$IF23
		    cmp cl, [MaxNumBuf1]	;AN026; last buffer of the 1st group?
;		$ELSE				;AN026;
		JMP SHORT $$EN23
$$IF23:
		    cmp cl, [MaxNumBuf2]	;AN026; last buffer of the 2nd group?
;		$ENDIF				;AN026;
$$EN23:

;		$IF  E				     ;AN020;Yes, last buffer
		JNE $$IF26
		   mov	word ptr es:[di.BUF_NEXT], 0 ;AN020;the last buffer's next -> the first buffer in bucket (Circular chain)
		   mov	word ptr es:[BUF_PREV], di   ;AN020;the first buffer's prev -> the last buffer
;		$ENDIF				     ;AN020;
$$IF26:
		mov  di, ax			;AN000;adjust next buffer position
;	    $ENDDO   E				;AN000;flag set already for testing last buffer.
	    JNE $$DO22
	    add  [Memlo], ax			;AN000;AX is the size of this bucket.
	    or	 [SetDevMarkFlag], FOR_DEVMARK	;AN005;Update DEVMARK_SIZE
	    call Round				;AN000;memhi:memlo adjusted for the next bucket.
	    add  bx, size BUFFER_HASH_ENTRY	;AN000;ds:bx -> next hash entry.
	    dec  [BufferBuckets]		;AN000;
;	$ENDDO	 Z				;AN000;
	JNZ $$DO21
	ret					;AN000;
Set_Buffer	endp

;
Set_EMS_Buffer	    proc    near
;*******************************************************************************
;Function: Set buffers in the extended memory.				       *
;	   For each hash table entry, set the pointer to the corresponding     *
;	   hash bucket. 						       *
;									       *
;Input:    ds:bx -> BuffInfo.						       *
;	   BuffINFO.Hash_Ptr -> Hash table.				       *
;	   BuffINFO.EMS_Handle = EMS handle				       *
;	   Buffers = tatal # of buffers to install.			       *
;		     Multiple of MAXBUFFINBUCKET*MAXBUCKETINPAGE.	       *
;	   Buffer_Pages = # of extended memory pages for buffers.	       *
;	   BufferBuckets = # of buckets to install.			       *
;	   SingleBufferSize = Buffer header size + Sector size. 	       *
;									       *
;Output:   Buffers, hash buckets and Hash table entries established.	       *
;									       *
;	   { For (each page)						       *
;	     { Map the page;			/*Map the page into Page frame *
;	       For (each bucket)		/*Each page has two buckets */ *
;	       {							       *
;		 Set EMS_Page;						       *
;		 Set Buffer_Bucket;					       *
;		 Next buffer ptr = buffer size; 			       *
;		 For (every buffer)		/*A bucket has 15 buffers */   *
;		 { Set Buf_link to Next buffer ptr;			       *
;		   Set Buffer_ID to free;				       *
;		   If (last buffer in this bucket) THEN 		       *
;		      {Buf_link = -1;					       *
;		       Next buffer ptr = 0;				       *
;		      };						       *
;		   Next buffer ptr += buffer size;			       *
;		 };							       *
;	       };							       *
;	     }; 							       *
;	   };								       *
;*******************************************************************************

	assume	ds:nothing			;AN000;to make sure.

IF	BUFFERFLAG

	push	ax
	mov	ax, offset ems_save_buf
	mov	word ptr cs:[ems_state_buf], ax
	push	cs
	pop	word ptr cs:[ems_state_buf+2]
	pop	ax

ENDIF

	call	Save_MAP_State			;AN010;
	mov	dx, es:[bx.EMS_Handle]		;AN000;save EMS_Handle
	lds	si, ds:[bx.HASH_PTR]		;AN000;now ds:si -> Hash table
	xor	bx, bx				;AN000;starting logical page number.
;	$DO					;AN000;For each page,
$$DO30:
	     call  Map_Page			;AN000;map it to IBM physical page 254.
	     mov   di, cs:IBM_Frame_Seg 	;AN000;
	     mov   es, di			;AN000
	     xor   di, di			;AN000;es:di -> bucket
	     xor   ax, ax			;AN000
	     xor   cx, cx			;AN000
;	     $DO				;AN000;For each bucket,
$$DO31:
		 mov ds:[si.EMS_PAGE_NUM], bx	;AN000;set the logical page number in Hash table.
		 mov word ptr ds:[si.BUFFER_BUCKET], di   ;AN000;set the offset in hash table for this bucket.
		 mov word ptr ds:[si.BUFFER_BUCKET+2], es ;AN000;set the segment value in hash table.
		 mov word ptr ds:[si.DIRTY_COUNT], 0	  ;AN020;set DIRTY_COUNT, BUFFER_RESERVED to 0.
		 push cx			;AN000;save bucket number
		 xor cx, cx			;AN000;
;		 $DO				;AN000;For each buffer in a bucket,
$$DO32:
		     call Set_Buffer_Info	;AN000;AX adjusted for the next buffer.
		     inc  cx			;AN000;inc number of buffers in this bucket.
		     cmp  cx, 1 		;AN020;The first buffer in the bucket?
;		     $IF  E			;AN020;
		     JNE $$IF33
			  mov  cs:[EMS_Buf_First], di ;AN020;then save the offset value
;		     $ENDIF			;AN020;
$$IF33:
		     cmp  cx, MAXBUFFINBUCKET	;AN000;
;		     $IF  E			;AN000
		     JNE $$IF35
			  push word ptr cs:[EMS_Buf_First]  ;AN020;
			  pop  word ptr es:[di.BUF_NEXT]    ;AN020;the last buffer's next -> the first buffer in bucket (Circular chain)
			  push di			    ;AN020;save di
			  push di			    ;AN020;di-> last buffer
			  mov  di, cs:[EMS_Buf_First]	    ;AN020;es:di-> first buffer
			  pop  word ptr es:[di.BUF_PREV]    ;AN020;the first buffer's prev -> the last buffer
			  pop  di			    ;AN020;restore di
;		     $ENDIF				    ;AN000;
$$IF35:
		     mov di, ax 		;AN000;advance di to the next buffer position.
;		 $ENDDO  E			;AN000;
		 JNE $$DO32
		 add si, size BUFFER_HASH_ENTRY ;AN000;ds:si -> next hash table entry
		 pop cx 			;AN000;restore bucket number
		 inc cx 			;AN000;next bucket
		 cmp cx, MAXBUCKETINPAGE	;AN000;2 buckets per page
;	     $ENDDO  E				;AN000;
	     JNE $$DO31
	     inc bx				;AN000;increse logical page number
	     cmp bx, cs:[Buffer_Pages]		;AN000;reached the maximum page number?
;	$ENDDO	E				;AN000;
	JNE $$DO30
	call	Restore_MAP_State		;AN010;
	 ret					;AN000;
Set_EMS_Buffer	    endp


Set_Buffer_Info        proc
;Function: Set buf_link, buf_id, Buf_Sector
;In: ES:DI -> Buffer header to be set.
;    AX = DI
;Out:
;    Above entries set.


	push	[Buf_Prev_Off]			;AN020;
	pop	es:[di.BUF_PREV]		;AN020;
	mov	Buf_Prev_Off, ax		;AN020;
	add ax, [SingleBufferSize]		;AN000;adjust ax
	mov word ptr es:[di.BUF_NEXT], ax	;AN020;
	mov word ptr es:[di.BUF_ID], 00FFh	;AN000;new buffer free
	mov word ptr es:[di.BUF_SECTOR], 0	;AN000;To compensate the MASM 3 bug
	mov word ptr es:[di.BUF_SECTOR+2],0	;AN000;To compensate the MASM 3 bug
	ret					;AN000;
Set_Buffer_Info        endp

Check_IBM_PageID	proc	near
;Function: check if the physical page 255 exists. (Physical page 255 is only
;	   one we are intereseted in, and this will be used for BUFFER
;	   manipulation by IBMBIO, IBMDOS)
;In: nothing
;Out: Carry clear and IBM_Frame_Seg set if it exist.  All registers saved.
		push	es				;AN000;
	push	ax				;AN000;
	push	bx				;AN000;
	push	cx				;AN000;
	push	dx				;AN000;
	push	di				;AN010;

IF	NOT BUFFERFLAG

	mov	ax, 1B00h			;AN029;AN030;AN0 Check EMS int 2fh installed.
	int	2fh				;AN029;
	cmp	al, 0ffh			;AN029;
	jne	Cp_IBM_Err			;AN029;If not installed, then no IBM page.
	mov	ax, 1B01h			;AN029;AN030;Then ask if IBM page exists.
	mov	di, IBM_PAGE_ID 		;AN029;=255
	int	2fh				;AN029;
	or	ah, ah				;AN029;
	jnz	Cp_IBM_Err			;AN029;;No IBM Page
	mov	cs:IBM_Frame_Seg, es		;AN029;;Save Physical IBM page frame addr.
	mov	cs:Real_IBM_Page_Id, di 	;AN029;;Real page number for it.
	clc					;AN029;
	jmp	short Cp_ID_Ret 		;AN029;

ELSE
	 push	 cs				 ;AN000;
	 pop	 es				 ;AN000;
	 mov	 ah, GET_PAGE_FRAME		 ;AN010;=58h
	 mov	 al, GET_NUM_PAGEFRAME		 ;AN010;=01h How many page frames?
	 int	 EMS_INT			 ;AN010;
	 or	 ah, ah 			 ;AN010;
	 jnz	 hkn_err			 ;AN010;
	 cmp	 cx, MAX_NUM_PAGEFRAME		 ;AN010;
	 ja	 hkn_err			 ;AN010; cannot handle this big number
	 push	 cx				 ;AN010;
	 mov	 ah, GET_PAGE_FRAME		 ;AN010;
	 mov	 al, GET_PAGEFRAME_TAB		 ;AN010;
	 mov	 di, offset Frame_info_Buffer	 ;AN010;
	 int	 EMS_INT			 ;AN010;
	 pop	 cx				 ;AN010;
	 or	 ah, ah 			 ;AN010;
	 jnz	 cp_IBM_Err			 ;AN010;
Cp_IBM_ID:					 ;AN010;

;	mov	dx, es:[di]
;	mov	cs:[FIRST_PAGE], dx
;	mov	dx, es:[di+2]
;	mov	cs:[FIRST_PAGE+2], dx

	xor	dx, dx

;	int	3
find_page:
	cmp	es:[di], 0a000h ; is current page above 640K
	jb	next		; NO - goto check_last

	inc	dx		; count the no. of pages above 640K

	cmp	dx, 1
	jne	first_ok

	mov	ax, es:[di]
	mov	cs:[FIRST_PAGE], ax
	mov	ax, es:[di+2]
	mov	cs:[FIRST_PAGE+2], ax

first_ok:
	mov	ax, cs:[FIRST_PAGE]
	cmp	ax, es:[di]	; is this page less than the one we have in
				; FIRST_PAGE
	jbe	check_last	; NO - goto check_last
	mov	ax, es:[di]	; update FIRST_PAGE with this page segment
	mov	cs:[FIRST_PAGE], ax
	mov	ax, es:[di+2]
	mov	cs:[FIRST_PAGE+2], ax
	jmp	next

hkn_err: jmp	cp_ibm_err

check_last:
	mov	ax, cs:[LAST_PAGE]	;
	cmp	ax, es:[di]	; is this page greater than the one we have in
				; LAST_PAGE?
	ja	next		; NO - goto next
	mov	ax, es:[di]	; update LAST_PAGE with this value.
	mov	cs:[LAST_PAGE], ax
	mov	ax, es:[di+2]
	mov	cs:[LAST_PAGE+2], ax

next:
	add	di, 4
	loop	find_page

	cmp	dx, 3			; there should be at least 3 pages
					; above 640K for the buffers to be
					; installed.
	jb	Cp_IBM_Err

	mov	ax, cs:[LAST_PAGE]
	mov	cs:IBM_Frame_Seg, ax
	mov	ax, cs:[LAST_PAGE+2]
	mov	cs:Real_IBM_Page_Id, ax
	mov	cs:[NPA640], dx
	clc
	jmp	short Cp_Id_Ret

ENDIF


;	 cmp	 word ptr es:[di+2], IBM_PAGE_ID ;AN010; the second word is the id
;	 je	 Got_IBM_ID			 ;AN010;
;	 add	 di, 4				 ;AN010; advance to the next row (4 bytes)
;	 loop	 Cp_IBM_ID			 ;AN010;

Cp_IBM_Err:					;AN010;;AN029;
	stc					;AN000;;AN029;
	jmp	short Cp_ID_Ret 		;AN000;;AN029;

;Got_IBM_ID:					 ;AN000;
;	 mov	 ax, word ptr es:[di]		 ;AN010;Physical seg. addr.
;	 mov	 cs:IBM_Frame_Seg, ax		 ;AN000;
;	 clc					 ;AN000;
Cp_ID_Ret:					;AN000;
	pop	di				;AN010;
	pop	dx				;AN000;
	pop	cx				;AN000;
	pop	bx				;AN000;
	pop	ax				;AN000;
	pop	es				;AN000;
	ret					;AN000;
Check_IBM_PageID	endp

;
Save_Map_State	proc				;AN010;
;Function: Save the map state.
;In)
;    EMS_Ctrl_Tab = double word pointer to EMS_state control table address
;    EMS_state_Buf = double word pointer to EMS_MAP_BUFF address
;Out) Map state saved
	push	ax				;AN010;
	push	ds				;AN010;
	push	si				;AN010;
	push	es				;AN010;
	push	di				;AN010;
	lds	si, cs:EMS_Ctrl_Tab		;AN010;
	les	di, cs:EMS_state_Buf		;AN010;
	mov	ah, EMAP_STATE			;AN010; =4Fh
	mov	al, GET_MAP_STATE		;AN010; =00h
	int	EMS_INT 			;AN010;
	pop	di				;AN010;
	pop	es				;AN010;
	pop	si				;AN010;
	pop	ds				;AN010;
	pop	ax				;AN010;
	ret					;AN010;
Save_Map_State	endp
;
Restore_Map_State	proc			;AN010;
	push	ax				;AN010;
	push	ds				;AN010;
	push	si				;AN010;
	lds	si, cs:EMS_state_Buf		;AN010;
	mov	ah, EMAP_STATE			;AN010;
	mov	al, SET_MAP_STATE		;AN010;
	int	EMS_INT 			;AN010;
	pop	si				;AN010;
	pop	ds				;AN010;
	pop	ax				;AN010;
	ret					;AN010;
Restore_Map_State	endp
;
Map_Page	proc	near			;AN000;
;Function: Map the logical page in BX of handle in DX to the physical page 255
;In)
;    BX = logical page number
;    DX = EMS handle
;    EMS_Ctrl_Tab = double word pointer to EMS_state control table address
;    EMS_state_Buf = double word pointer to EMS_MAP_BUFF address
;Out) Logical page mapped into first phsical page frame.
;    AX saved.

	push	ax				;AN000;
	mov	ah, EMAP_L_TO_P 		;AN000;
	mov	al, byte ptr cs:Real_IBM_PAGE_ID	 ;AN029;= 255
	int	EMS_INT 			;AN000;
	pop	ax				;AN000;
	ret					;AN000;
Map_Page	endp				;AN000;
;

Roundup proc
;In: DX;AX - operand
;    CX    - divisor
;    Important: DX should be less than CX.
;out: AX - Quotient (Rounded up)

	div cx					;AN000;
	or  dx, dx				;AN000;
	jz  RU_ret				;AN000;
	inc AX					;AN000;
RU_ret: 					;AN000;
	ret					;AN000;
Roundup endp
;------------------------------------------------------------------------------
;J.K. 5/6/86. IBMSTACK initialization routine.
	IF	STACKSW
.SALL

INCLUDE STKINIT.INC

.XALL
	ENDIF
;------------------------------------------------------------------------------
	public	SetDevMark
SetDevMark	proc
;Set the DEVMARK for MEM command.
;In: [MEMHI] - the address to place DEVMARK
;    [MEMLO] = 0
;    AL = ID for DEVMARK_ID
;OUT: DEVMARK established.
;     the address saved in cs:[DevMark_Addr]
;     [MEMHI] increase by 1.

	push	es				;AN005;
	push	cx				;AN005;

	mov	cx, cs:[memhi]			;AN005;
	mov	cs:[DevMark_Addr],cx		;AN005;
	mov	es, cx				;AN005;
	mov	es:[DEVMARK_ID], al		;AN005;
	inc	cx				;AN007;
	mov	es:[DEVMARK_SEG], cx		;AN007;

	pop	cx				;AN005;
	pop	es				;AN005;
	inc	cs:[memhi]			;AN005;
	ret					;AN005;
SetDevMark	endp

;*******************************************************************************
;Function: Load  SHARE.EXE, if Big_Media_Flag = 1 and SHARE.EXE has not been   *
;	   loaded yet.							       *
;	   This routine will use the same path for SHELL= command.	       *
;	   If SHELL= command has not been entered, then default to the root    *
;	   directory.							       *
;	   If load fails, then issue message "Warning: SHARE.EXE not loaded"   *
;									       *
;Input:    Big_Media_Flag, COMMND					       *
;Output:   Share.exe loaded if necessary.				       *
;									       *
;*******************************************************************************
LoadShare	proc	near			;AN021;
	cmp	Big_Media_Flag, 1		;AN021;
	jne	LShare_Ret			;AN021;
;Check if SHARE is already loaded.
	mov	ax, 1000h			;AN021;multShare installation check
	int	2fh				;AN021;
	cmp	al, 0ffh			;AN021;
	jz	LShare_Ret			;AN021;Share already loaded!
;SHARE not loaded.
	push	cs				;AN021;
	pop	ds				;AN021;
	push	cs				;AN021;
	pop	es				;AN021;
	mov	si, offset COMMND		;AN021;
	mov	di, offset PathString		;AN021;
LShare_String:					;AN021;
	movsb					;AN021;
	cmp	byte ptr [di-1], 0		;AN021;reached to the end?
	jne	LShare_string			;AN021;
	mov	si, offset PathString		;AN021;SI= start of PathString
LShare_Tail:					;AN021;
	dec	di				;AN021;
	cmp	byte ptr [di], "\"		;AN021;
	je	LShare_Got_Tail 		;AN021;
	cmp	byte ptr [di], ":"		;AN021;
	je	LShare_Got_Tail 		;AN021;
	cmp	di, si				;AN021;No path case (e.g. SHELL=command.com)
	je	LShare_Got_Tail_0		;AN021;
	jmp	LShare_Tail			;AN021;
LShare_Got_Tail:				;AN021;di -> "\" or ":"
	inc	di				;AN021;
LShare_Got_Tail_0:				;AN021;
	mov	si, offset LShare		;AN021;
LShare_Set_Filename:				;AN021;
	movsb					;AN021;Tag "SHARE.EXE",0,0Ah to the path.
	cmp	byte ptr [di-1], 0Ah		;AN021;Line feed?
	jne	LShare_Set_Filename		;AN021;
;Now, we got a path,filename with no parameters for SHARE.EXE
	mov	si, offset PathString		;AN021;
	or	Install_Flag, SHARE_INSTALL	;AN021;Signals Do_Install_Exec that this is for SHARE.EXE.
	call	Do_Install_Exec 		;AN021;execute it.
	jnc	LShare_Ret			;AN021;No problem
;Load/Exec failed.  Show "Warning: SHARE should be loaded for large media"
	push	cs				;AN021;
	pop	ds				;AN021;
	mov	dx, offset ShareWarnMsg 	;AN021;WARNING! SHARE should be loaded...
	invoke	Print				;AN021;
LShare_Ret:					;AN021;
	ret					;AN021;
LoadShare	endp				;AN021;

SYSINITSEG	ENDS
	   END
