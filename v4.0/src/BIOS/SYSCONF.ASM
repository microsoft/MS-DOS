	PAGE	,132		       ;
;	SCCSID = @(#)sysconf.asm       0.0 86/10/20
TITLE	BIOS SYSTEM INITIALIZATION
%OUT ...SYSCONF

;==============================================================================
;REVISION HISTORY:
;AN000 - New for DOS Version 4.00 - J.K.
;AC000 - Changed for DOS Version 4.00 - J.K.
;AN00x - PTM number for DOS Version 4.00 - J.K.
;==============================================================================
;AN001; P132 Multiple character device installation problem.	   06/27/87 J.K.
;AN002; D24  MultiTrack= command added. 			   06/29/87 J.K.
;AN003; D41  REM command in CONFIG.SYS. 			   07/6/87  J.K.
;AN004; D184 Set DEVMARK for MEM command			   08/25/87 J.K.
;AN005; P568 CONFIG.SYS parsing error with FCBS=10,15		   08/31/87 J.K.
;AN006; P887 STACKS=0 does not show "ERROR in CONFIG.SYS..."	   09/09/87 J.K.
;AN007; D246, P976 Show "Bad command or parameters - ..." msg	   09/22/87 J.K.
;AN008; P1299 Set the second entry of DEVMARK for MEM command	   09/25/87 J.K.
;AN009; P1326 New Extended attribute				   09/28/87 J.K.
;AN010; P1820 New message SKL file				   10/20/87 J.K.
;AN011; P1970 AUTOTEST FCBS= command error msg inconsistent	   10/23/87 J.K.
;AN012; P2211 Setting the EA=7 for ANSI.SYS hangs the system	   11/02/87 J.K.
;AN013; P2342 REM not allowed after INSTALL command		   11/09/87 J.K.
;AN014; P2546 DEVICE= command still allowed after IFS=		   11/17/87 J.K.
;AN015; D358  New device driver INIT function package		   12/03/87 J.K.
;AN016; D285 Undo the extended error handling			   12/17/87 J.K.
;AN017; P3170 Do not call block device driver when drive # > 26    01/20/88 J.K.
;AN018; P3111 Take out the order dependency of the INSTALL=	   01/25/88 J.K.
;AN019; D479  New option to disable extended INT 16h function call 02/12/88 J.K.
;AN020; P3607 MEM does not give correct filename		   02/24/88 J.K.
;AN021; D493 Undo D358 & do not show error message for device driv 02/24/88 J.K.
;AN022; P3807 Single buffer unprotected - System hangs		   03/10/88 J.K.
;AN023; P3797 An INSTALL cmd right after Bad cmd is not executed   03/10/88 J.K.
;AN024; D503 Version change to 4.0 - IBMCACHE.SYS is an exception  03/15/88 J.K.
;AN025; D474 Change BUFFERS= /E option to /X for expanded memory   03/16/88 J.K.
;AN026; D506 Take out the order dependency of the IFS=		   03/28/88 J.K.
;AN027; P3957 Undo D503 - IBMCACHE.SYS version check problem	   03/30/88 J.K.
;AN028; P4086 Memory allocation error when loading share.exe	   03/31/88 J.K.
;AN029; D528 Install XMAEM.SYS first before everything else	   04/29/88 J.K.
;AN030; P4759 INT2f, INT 67h handlers for XMA			   05/11/88 J.K.
;AN031; P4889 Should check the validity of INT 67h call 	   05/17/88 G.A.
;AN032; P4934 P4759 INT 2fh number should be changed to 1Bh	   05/20/88 J.K.
;AN033; P5002 EMS w/single page allocated now works		   05/20/88 G.A.
;AN034; P5128 EMS INT 2FH HANDLER BUG				   06/24/88
;==============================================================================

TRUE	    EQU 0FFFFh
FALSE	    EQU 0
LF	equ	10
CR	equ	13
TAB	equ	 9
SEMICOLON equ	';'

IBMVER	   EQU	   TRUE
IBM	   EQU	   IBMVER
STACKSW    EQU	   TRUE 		;Include Switchable Hardware Stacks
IBMJAPVER  EQU	   FALSE		;If TRUE set KANJI true also
MSVER	   EQU	   FALSE
ALTVECT    EQU	   FALSE		;Switch to build ALTVECT version
KANJI	   EQU	   FALSE

HAVE_INSTALL_CMD      equ     00000001b ;AN018; CONFIG.SYS has INSTALL= commands
HAS_INSTALLED	      equ     00000010b ;AN018; SYSINIT_BASE installed.

IS_IFS		      equ   00000001b	;IFS command?
NOT_IFS 	      equ   11111110b
;
;AN016; Undo the extended attribute handling
;;Extended attribute value
;EA_UNSPECIFIED 	 equ	 0	 ;AN009;
;EA_DEVICE_DRIVER	 equ	 6	 ;AN009;
;EA_IFS_DRIVER		 equ	 7	 ;AN009;

DEFAULT_FILENUM = 8
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
	include smifssym.inc	;AN000; Reduced version of IFSSYM.INC.
	include DEVMARK.inc	;AN004;
	include version.inc
.list

	IF	NOT IBMJAPVER
	EXTRN	RE_INIT:FAR
	ENDIF

;

;J.K. 6/29/87 External variable defined in IBMBIO module for Multi-track
MULTRK_ON	EQU	10000000B	;User spcified Mutitrack=on, or System turns
					; it on after handling CONFIG.SYS file as a
					; default value, if MulTrk_flag = MULTRK_OFF1.
MULTRK_OFF1	EQU	00000000B	;initial value. No "Multitrack=" command entered.
MULTRK_OFF2	EQU	00000001B	;User specified Multitrack=off.

CODE segment public 'code'
	EXTRN	MulTrk_flag:word	;AN002;
	extrn	KEYRD_Func:byte 	;AN019;
	extrn	KEYSTS_Func:byte	;AN019;
CODE ends
;J.K. 6/29/87 End of Multi-track definition.

SYSINITSEG	SEGMENT PUBLIC 'SYSTEM_INIT'

ASSUME	CS:SYSINITSEG,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	BADOPM:BYTE,CRLFM:BYTE,BADCOM:BYTE,BADMEM:BYTE,BADBLOCK:BYTE
	EXTRN	BADSIZ_PRE:BYTE,BADLD_PRE:BYTE
;	 EXTRN	 BADSIZ_POST:BYTE,BADLD_POST:BYTE
	EXTRN	BADSTACK:BYTE,BADCOUNTRYCOM:BYTE
	EXTRN	SYSSIZE:BYTE,BADCOUNTRY:BYTE,INSUFMEMORY:BYTE
	EXTRN	CONDEV:BYTE,AUXDEV:BYTE,PRNDEV:BYTE,COMMND:BYTE,CONFIG:BYTE
	EXTRN	Cntry_Drv:BYTE,Cntry_Root:BYTE,Cntry_Path:BYTE
	EXTRN	DeviceParameters:byte
	EXTRN	MEMORY_SIZE:word
	EXTRN	BUFFERS:word
	EXTRN	FILES:byte,NUM_CDS:byte
	EXTRN	DOSINFO:dword,ENTRY_POINT:dword
	EXTRN	FCBS:byte,KEEP:byte
	EXTRN	CONFBOT:word,ALLOCLIM:word,COMMAND_LINE:byte
	EXTRN	ZERO:byte,SEPCHR:byte
	EXTRN	COUNT:word,CHRPTR:word,CNTRYFILEHANDLE:word
	EXTRN	MEMLO:word,MEMHI:word,PRMBLK:word,LDOFF:word
	EXTRN	PACKET:byte,UNITCOUNT:byte,BREAK_ADDR:dword
	EXTRN	BPB_ADDR:dword,DRIVENUMBER:byte,SYSI_COUNTRY:dword
	extrn	Config_Size:word		;AN000;
	extrn	Install_Flag:word		;AN000;
	extrn	BadOrder:byte			;AN000;
	extrn	Errorcmd:byte			;AN000;
	extrn	LineCount:word			;AN000;
	extrn	ShowCount:byte			;AN000;
	extrn	Buffer_LineNum:word		;AN000;
	extrn	IFS_Flag:word			;AN000;
	extrn	IFS_RH:byte			;AN000;
	extrn	H_Buffers:word			;AN000;
	extrn	Buffer_Slash_X:byte		;AN000;AN025;
	extrn	Badparm:byte			;AN007;
	extrn	ConfigMsgFlag:Word		;AN015;
	extrn	Org_Count:Word			;AN018;
	extrn	Multi_Pass_Id:byte		;AN026;

	EXTRN	MEM_ERR:NEAR,SetDOSCountryInfo:NEAR
	EXTRN	PARAROUND:NEAR,TEMPCDS:NEAR
	EXTRN	Set_Country_Path:NEAR,Move_ASCIIZ:NEAR,DELIM:NEAR
	EXTRN	BADFIL:NEAR,ROUND:NEAR
	extrn	Do_Install_Exec:NEAR		;AN018;
	extrn	SetDevMark:NEAR 		;AN030;

;AN016; Undo the extended attribute handling
;	 extrn	 Get_Ext_Attribute:near 	 ;AN009;

	IF	STACKSW

; Internal Stack Parameters
	EntrySize		equ	8

	MinCount		equ	8
	DefaultCount		equ	9
	MaxCount		equ	64

	MinSize 		equ	32
	DefaultSize		equ	128
	MaxSize 		equ	512

	extrn  stack_count:word
	extrn  stack_size:word
	extrn  stack_addr:dword

	ENDIF

	PUBLIC DOCONF
	PUBLIC GETCHR
	public Multi_Pass		;AN018;AN026;

	public	MultDeviceFlag
MultDeviceFlag	db	0		;AN001;
	public	DevMark_Addr
DevMark_Addr	dw	?		;AN004;Segment address for DEVMARK.
	public	SetDevMarkFlag
SetDevMarkFlag	    db	    0		;AN004;Flag used for DEVMARK

EMS_Stub_Installed  db	    0		;AN030;

Badparm_Ptr	label	dword
Badparm_Off	dw	0		;AN007;
Badparm_Seg	dw	0		;AN007;

XMAEM_file	db	'XMAEM.SYS',0	;AN029;

;IBMCACHE_file	 db	 'IBMCACHE.SYS',0;AN024;AN026;To cope with the IBMCACHE.SYS
					; problem of DOS version checking.

;******************************************************************************
;Take care of Config.sys file.
;SYSTEM parser data and code.
;******************************************************************************
.xlist
	include PSOPTION.INC			;Parsing options for SYSCONF.
	include PARSE.ASM			;together with PSDATA.INC
.list
;Control block definitions for PARSER.
;---------------------------------------------------
; BUFFER = [n | n,m] {/E}

Buf_Parms	label	byte	;AN000;
	dw	Buf_Parmsx	;AN000;
	db	1		;AN000; An extra delimeter list
	db	1		;AN000; length is 1
	db	SEMICOLON	;AN000;

Buf_Parmsx	label	byte	;AN000;
	db	1,2		;AN000; Min 1, Max 2 positional
	dw	Buf_Pos1	;AN000;
	dw	Buf_Pos2	;AN000;
	db	1		;AN000; 1 switch
	dw	SW_X_Ctrl	;AN000;AN025; /X control
	db	0		;AN000; no keywords

Buf_Pos1	label	word	;AN000;
	dw	8000h		;AN000; Numeric value
	dw	0		;AN000; no function
	dw	Result_Val	;AN000; Result value buffer
	dw	Buf_Range_1	;AN000; value list
	db	0		;AN000; no switches/keywords

Buf_Range_1	label	byte	;AN000; value definition
	db	1		;AN000; range definition
	db	1		;AN000; 1 definition of range
	db	1		;AN000; item tag for this range
	dd	1,10000 	;AN000; from 1 to 10000

Buf_Pos2	label	word	;AN000;
	dw	8001h		;AN000; Numeric value, Optional
	dw	0		;AN000; no function
	dw	Result_Val	;AN000; Result value buffer
	dw	Buf_Range_2	;AN000; value list
	db	0		;AN000; no switches/keywords

Buf_Range_2	label	byte	;AN000; value definition
	db	1		;AN000; range definition
	db	1		;AN000; 1 definition of range
	db	1		;AN000; item tag for this range
	dd	0,8		;AN000; from 0 to 8.

SW_X_Ctrl	label	word	;AN000;AN025;
	dw	0		;AN000; no matching flag
	dw	0		;AN000; no function
	dw	Result_Val	;AN000; return value
	dw	NoVal		;AN000; no value definition
	db	1		;AN000; # of switches
Switch_X	label	byte	;AN000;AN025;
	db	'/X',0		;AN000;AN025;
;local variables
P_Buffers	dw     0	;AN000;
P_H_Buffers	dw     0	;AN000;
P_Buffer_Slash_X db    0	;AN000;AN025;
Buffer_Pre_Scan  db    0	;AN030;

;Common definitions -------------
NoVal	db	0		;AN000;

Result_Val	label	byte	;AN000;
	db	?		;AN000; type returned
	db	?		;AN000; item tag returned
	dw	?		;AN000; ES:offset of the switch defined
RV_Byte 	label	byte	;AN000;
RV_Dword	label	dword	;AN000;
	dd	?		;AN000; value if number, or seg:offset to string.
;--------------------------------

; BREAK = [ ON | OFF ]

Brk_Parms	label	byte	;AN000;
	dw	Brk_Parmsx	;AN000;
	db	1		;AN000; An extra delimeter list
	db	1		;AN000; length is 1
	db	SEMICOLON	;AN000;

Brk_Parmsx	label	byte	;AN000;
	db	1,1		;AN000; Min 1, Max 1 positional
	dw	Brk_Pos 	;AN000;
	db	0		;AN000; no switches
	db	0		;AN000; no keywords

Brk_Pos 	label	word	;AN000;
	dw	2000h		;AN000; Simple string
	dw	0		;AN000; No functions
	dw	Result_Val	;AN000;
	dw	On_Off_String	;AN000; ON,OFF string descriptions
	db	0		;AN000; no keyword/switch synonyms

On_Off_String	label	byte	;AN000;
	db	3		;AN000; signals that there is a string choice
	db	0		;AN000; no range definition
	db	0		;AN000; no numeric values choice
	db	2		;AN000; 2 strings for choice
	db	1		;AN000; the 1st string tag
	dw	On_String	;AN000;
	db	2		;AN000; the 2nd string tag
	dw	Off_String	;AN000;

On_String	db	"ON",0	;AN000;
Off_String	db	"OFF",0 ;AN000;
;local variable
P_Ctrl_Break	db	0	;AN000; local variable

;--------------------------------

; COUNTRY = n {m {path}}
; or
; COUNTRY = n,,path

Cntry_Parms	label	byte	;AN000;
	dw	Cntry_Parmsx	;AN000;
	db	1		;AN000; An extra delimeter list
	db	1		;AN000; length is 1
	db	SEMICOLON	;AN000;

Cntry_Parmsx	label	byte	;AN000;
	db	1,3		;AN000; Min 1, Max 3 positional
	dw	Cntry_Pos1	;AN000;
	dw	Cntry_Pos2	;AN000;
	dw	Cntry_Pos3	;AN000;
	db	0		;AN000; no switches
	db	0		;AN000; no keywords

Cntry_Pos1	label	word	;AN000; control definition for positional 1
	dw	8000h		;AN000; Numeric value
	dw	0		;AN000; no functions
	dw	Result_Val	;AN000;
	dw	Cntry_Codepage_Range  ;AN000; country id code range description
	db	0		;AN000; no switch/keyword synonyms

Cntry_Codepage_Range  label   byte  ;AN000;
	db	1		;AN000; # of value definitions
	db	1		;AN000; # of ranges
	db	1		;AN000; Tag for this range
	dd	1,999		;AN000;

Cntry_Pos2	label	word	;AN000; control definition for positional 2
	dw	8001h		;AN000; Numeric value, optional
	dw	0		;AN000; no functions
	dw	Result_Val	;AN000;
	dw	Cntry_Codepage_Range  ;AN000; code page range descriptions.
	db	0		;AN000; no switch/keyword synonyms

Cntry_Pos3	label	word	;AN000; control definition for positional 3
	dw	0201h		;AN000; File spec, optional
	dw	0		;AN000; No functions. Don't need to CAP.
	dw	Result_Val	;AN000;
	dw	NoVal		;AN000; no value list
	db	0		;AN000; no switch/keyword synonyms

;Local variables
P_Cntry_Code	dw	0	;AN000;
P_Code_Page	dw	0	;AN000;

;--------------------------------

; FILES = n

Files_Parms	label	byte	;AN000;
	dw	Files_Parmsx	;AN000;
	db	1		;AN000; An extra delimeter list
	db	1		;AN000; length is 1
	db	SEMICOLON	;AN000;

Files_Parmsx	label	byte	;AN000;
	db	1,1		;AN000; Min 1, Max 1 positional
	dw	Files_Pos	;AN000;
	db	0		;AN000; no switches
	db	0		;AN000; no keywords

Files_Pos	label	byte	;AN000;
	dw	8000h		;AN000; Numeric value
	dw	0		;AN000; no functions
	dw	Result_Val	;AN000;
	dw	Files_Range	;AN000; Files range description
	db	0		;AN000; no switch/keyword synonyms

Files_Range	label	byte	;AN000;
	db	1		;AN000; # of value definitions
	db	1		;AN000; # of ranges
	db	1		;AN000; Tag for this range
	dd	8,255		;AN000;
;local variable
P_Files db	0		;AN000;

;--------------------------------

; FCBS = n,m

FCBS_Parms	label	byte	;AN000;
	dw	FCBS_Parmsx	;AN000;
	db	1		;AN000; An extra delimeter list
	db	1		;AN000; length is 1
	db	SEMICOLON	;AN000;

FCBS_Parmsx	label	byte	;AN000;
	db	2,2		;AN000; Min 2, Max 2 positional
	dw	FCBS_Pos_1	;AN000;
	dw	FCBS_Pos_2	;AN000;
	db	0		;AN000; no switches
	db	0		;AN000; no keywords

FCBS_Pos_1	label	byte	;AN000;
	dw	8000h		;AN000; Numeric value
	dw	0		;AN000; no functions
	dw	Result_Val	;AN000;
	dw	FCBS_Range	;AN000; FCBS range descriptions
	db	0		;AN000; no switch/keyword synonyms

FCBS_Range	label	byte	;AN000;
	db	1		;AN000; # of value definitions
	db	1		;AN000; # of ranges
	db	1		;AN000; Tag for this range
	dd	1,255		;AN000;

FCBS_Pos_2	label	byte	;AN000;
	dw	8000h		;AN000; Numeric value
	dw	0		;AN000; no functions
	dw	Result_Val	;AN000;
	dw	FCBS_Keep_Range ;AN000; FCBS KEEP range descriptions
	db	0		;AN000; no switch/keyword synonyms

FCBS_Keep_Range label	byte	;AN000;
	db	1		;AN000; # of value definitions
	db	1		;AN000; # of ranges
	db	1		;AN000; Tag for this range
	dd	0,255		;AN000;

;local variable
P_Fcbs	db	0		;AN000;
P_Keep	db	0		;AN000;
;--------------------------------

; LASTDRIVE = x

LDRV_Parms	label	byte	;AN000;
	dw	LDRV_Parmsx	;AN000;
	db	1		;AN000; An extra delimeter list
	db	1		;AN000; length is 1
	db	SEMICOLON	;AN000;

LDRV_Parmsx	label	byte	;AN000;
	db	1,1		;AN000; Min 1, Max 1 positional
	dw	LDRV_Pos	;AN000;
	db	0		;AN000; no switches
	db	0		;AN000; no keywords

LDRV_Pos	label	byte	;AN000;
	dw	0110h		;AN000; Drive only, Ignore colon.
	dw	0010h		;AN000; Remove colon at end
	dw	Result_Val	;AN000;
	dw	NoVal		;AN000; No value list
	db	0		;AN000; no switch/keyword synonyms

;local variable
P_Ldrv	db	0		;AN000;
;--------------------------------

; STACKS = n,m

STKS_Parms	label	byte	;AN000;
	dw	STKS_Parmsx	;AN000;
	db	1		;AN000; An extra delimeter list
	db	1		;AN000; length is 1
	db	SEMICOLON	;AN000;

STKS_Parmsx	label	byte	;AN000;
	db	2,2		;AN000; Min 2, Max 2 positional
	dw	STKS_Pos_1	;AN000;
	dw	STKS_Pos_2	;AN000;
	db	0		;AN000; no switches
	db	0		;AN000; no keywords

STKS_Pos_1	label	byte	;AN000;
	dw	8000h		;AN000; Numeric value
	dw	0		;AN000; no functions
	dw	Result_Val	;AN000;
	dw	STKS_Range	;AN000; number of stack range descriptions
	db	0		;AN000; no switch/keyword synonyms

STKS_Range	label	byte	;AN000;
	db	1		;AN000; # of value definitions
	db	1		;AN000; # of ranges
	db	1		;AN000; Tag for this range
	dd	0,64		;AN000;

STKS_Pos_2	label	byte	;AN000;
	dw	8000h		;AN000; Numeric value
	dw	0		;AN000; no functions
	dw	Result_Val	;AN000;
	dw	STK_SIZE_Range	;AN000; stack size range descriptions
	db	0		;AN000; no switch/keyword synonyms

STK_SIZE_Range label   byte	;AN000;
	db	1		;AN000; # of value definitions
	db	1		;AN000; # of ranges
	db	1		;AN000; Tag for this range
	dd	0,512		;AN000;
;local variables
P_Stack_Count	dw	0	;AN000;
P_Stack_Size	dw	0	;AN000;

;--------------------------------

; MULTITRACK = [ ON | OFF ]

MTrk_Parms	label	byte	;AN002;
	dw	MTrk_Parmsx	;AN002;
	db	1		;AN002; An extra delimeter list
	db	1		;AN002; length is 1
	db	SEMICOLON	;AN002;

MTrk_Parmsx	label	byte	;AN002;
	db	1,1		;AN002; Min 1, Max 1 positional
	dw	MTrk_Pos	;AN002;
	db	0		;AN002; no switches
	db	0		;AN002; no keywords

MTrk_Pos	label	word	;AN002;
	dw	2000h		;AN002; Simple string
	dw	0		;AN002; No functions
	dw	Result_Val	;AN002;
	dw	On_Off_String	;AN002; ON,OFF string descriptions
	db	0		;AN002; no keyword/switch synonyms

;local variables
P_Mtrk	db	0		;AN002;
;--------------------------------

; CPSW = [ ON | OFF ]

CPSW_Parms	label	byte	;AN002;
	dw	CPSW_Parmsx	;AN002;
	db	1		;AN002; An extra delimeter list
	db	1		;AN002; length is 1
	db	SEMICOLON	;AN002;

CPSW_Parmsx	label	byte	;AN002;
	db	1,1		;AN002; Min 1, Max 1 positional
	dw	CPSW_Pos	;AN002;
	db	0		;AN002; no switches
	db	0		;AN002; no keywords

CPSW_Pos	label	word	;AN002;
	dw	2000h		;AN002; Simple string
	dw	0		;AN002; No functions
	dw	Result_Val	;AN002;
	dw	On_Off_String	;AN002; ON,OFF string descriptions
	db	0		;AN002; no keyword/switch synonyms

;local variables
P_CPSW	db	0		;AN002;

;--------------------------------
; SWITCHES=/K

Swit_Parms	label	byte	;AN019;
	dw	Swit_Parmsx	;AN019;
	db	1		;AN019; An extra delimeter list
	db	1		;AN019; length is 1
	db	SEMICOLON	;AN019;

Swit_Parmsx	label	byte	;AN019;
	db	0,0		;AN019; No positionals
	db	1		;AN019; 1 switch for now.
	dw	Swit_K_Ctrl	;AN019; /K control
	db	0		;AN019; no keywords

Swit_K_Ctrl	label	word	;AN019;
	dw	0		;AN019; no matching flag
	dw	0		;AN019; no function
	dw	Result_Val	;AN019; return value
	dw	NoVal		;AN019; no value definition
	db	1		;AN019; # of switches
Swit_K		label	byte	;AN019;
	db	'/K',0		;AN019;
;local variables
P_Swit_K	db     0	;AN019;

;******************************************************************************

DOCONF:
	PUSH	CS
	POP	DS
	ASSUME	DS:SYSINITSEG

	MOV	AX,(CHAR_OPER SHL 8)	;GET SWITCH CHARACTER
	INT	21H
	MOV	[COMMAND_LINE+1],DL	; Set in default command line

	MOV	DX,OFFSET CONFIG	;NOW POINTING TO FILE DESCRIPTION
	MOV	AX,OPEN SHL 8		;OPEN FILE "CONFIG.SYS"
	STC				;IN CASE OF INT 24
	INT	21H			;FUNCTION REQUEST
;	 JC	 ENDCONF		 ;Wasn't there, or couldn't open (sickness)
	jc	No_Config_sys		;AN028;
	JMP	NOPROB			;PROBLEM WITH OPEN
No_Config_sys:				;AN028;
	mov	Multi_Pass_Id, 11	;AN028; set it to unreasonable number
ENDCONF:
	return


BADOP:	MOV	DX,OFFSET BADOPM	;WANT TO PRINT COMMAND ERROR "Unrecognized command..."
	invoke	PRINT
	call	Error_Line		;show "Error in CONFIG.SYS ..." .
	JMP	COFF

Badop_p 	proc	near		;AN000;
;Same thing as BADOP, but will make sure to set DS register back to SYSINITSEG
;and return back to the calller.
	push	cs
	pop	ds			;set ds to CONFIGSYS seg.
	mov	dx, offset badopm
	invoke	PRINT
	call	Error_Line
	ret
Badop_p 	endp

Badparm_p	proc	near		;AN007;
;Show "Bad command or parameters - xxxxxx"
;In Badparm_seg, Badparm_off -> xxxxx
;
	cmp	cs:Buffer_Pre_Scan, 1	;AN030; Pre scanning Buffers ... /X?
	je	BadParmp_Ret		;AN030;  then do not show any message.
	push	ds			;AN007;
	push	dx			;AN007;
	push	si			;AN007;

	push	cs			;AN007;
	pop	ds			;AN007;
	mov	dx, offset Badparm	;AN007;
	invoke	PRINT			;AN007;"Bad command or parameters - "
	lds	si, Badparm_ptr 	;AN007;
Badparm_Prt:				;AN007;print "xxxx" until CR.
	mov	dl, byte ptr [si]	;AN007;
	mov	ah,STD_CON_OUTPUT	;AN007;
	int	21h			;AN007;
	inc	si			;AN007;
	cmp	dl, CR			;AN007;
	jne	Badparm_Prt		;AN007;
	push	cs			;AN007;
	pop	ds			;AN007;
	mov	dx, offset CRLFM	;AN007;
	invoke	PRINT			;AN007;
	call	Error_Line		;AN007;
	pop	si			;AN007;
	pop	dx			;AN007;
	pop	ds			;AN007;
BadParmp_Ret:				;AN030;
	ret				;AN007;
Badparm_p	endp

NOPROB: 				;GET FILE SIZE (NOTE < 64K!!)
	MOV	BX,AX
	XOR	CX,CX
	XOR	DX,DX
	MOV	AX,(LSEEK SHL 8) OR 2
	INT	21H
	MOV	[COUNT],AX
	XOR	DX,DX
	MOV	AX,LSEEK SHL 8		;Reset pointer to beginning of file
	INT	21H
;	 MOV	 DX,CS
	mov	dx, [ConfBot]		;AN022;Use current CONFBOT value
	MOV	AX,[COUNT]
	mov	[config_size], ax	;save the size of config.sys file.
	call	ParaRound
	SUB	DX,AX
	SUB	DX,11H			;ROOM FOR HEADER
	MOV	[CONFBOT],DX		; Config starts here. New CONBOT value.
	CALL	TEMPCDS 		; Finally get CDS to "safe" location
ASSUME	DS:NOTHING,ES:NOTHING

	MOV	DX,[CONFBOT]
	MOV	DS,DX
	MOV	ES,DX
	XOR	DX,DX
	MOV	CX,[COUNT]
	MOV	AH,READ
	STC				;IN CASE OF INT 24
	INT	21H			;Function request
	PUSHF
;
; Find the EOF mark in the file.  If present, then trim length.

	SaveReg <AX,DI,CX>
	MOV	AL,1Ah			; eof mark
	MOV	DI,DX			; point ro buffer
	JCXZ	PutEOL			; no chars
	REPNZ	SCASB			; find end
	JNZ	PutEOL			; none found and count exahusted
;
; We found a 1A.  Back up
;
	DEC	DI			; backup past 1A
;
;  Just for the halibut, stick in an extra EOL
;
PutEOL:
	MOV	AL,CR
	STOSB				; CR
	MOV	AL,LF
	STOSB				; LF
	SUB	DI,DX			; difference moved
	MOV	Count,DI		; new count
;
; Restore registers
;
	RestoreReg  <CX,DI,AX>

	PUSH	CS
	POP	DS
ASSUME	DS:SYSINITSEG
	PUSH	AX
	MOV	AH,CLOSE
	INT	21H
	POP	AX
	POPF
	JC	CONFERR 		;IF NOT WE'VE GOT A PROBLEM
	CMP	CX,AX
	JZ	GETCOM			;COULDN'T READ THE FILE
CONFERR:
	MOV	DX,OFFSET CONFIG	;WANT TO PRINT CONFIG ERROR
	CALL	BADFIL
ENDCONV:JMP	ENDCONF

Multi_Pass:				;AN018;AN026; called to execute IFS=,  INSTALL= commands
	push	cs			;AN018;
	pop	ds			;AN018;
	cmp	Multi_Pass_id, 10	;J.K.
	jae	Endconv 		;J.K. Do nothing. Just return.
	push	Confbot 		;AN018;
	pop	es			;AN018; ES -> Confbot
	mov	si, Org_Count		;AN018;
	mov	Count, si		;AN018; set Count
	xor	si,si			;AN018;
	mov	Chrptr, si		;AN018; reset Chrptr, LineCount
	mov	LineCount, si		;AN018;
	call	GetChr			;AN018;
	jmp	Conflp			;AN018;
GETCOM:
	invoke	ORGANIZE		;ORGANIZE THE FILE
	CALL	GETCHR

CONFLP: JC	ENDCONV
	call	Reset_DOS_Version	;AN024;AN026; Still need to reset version even IBMDOS handles this through
					; function 4Bh call, since IBMDOS does not know when Load/Overlay call finishes.

IF	NOT BUFFERFLAG
	call	EMS_Stub_handler	;AN030;
ENDIF

	inc	LineCount		;AN000; Increase LineCount.
	mov	Buffer_Pre_Scan, 0	;AN030; Reset Buffer_Pre_Scan.
	mov	MultDeviceFlag,0	;AN001; Reset MultDeviceFlag.
	mov	SetDevMarkFlag,0	;AN004; Reset SetDevMarkFlag.
	cmp	al, LF			;AN000; LineFeed?
	je	Blank_Line		;AN000;  then ignore this line.
	MOV	AH,AL
	CALL	GETCHR
	jnc	TryI			;AN000;
	cmp	Multi_Pass_ID, 2	;AN026;
	jae	Endconv 		;AN026;Do not show Badop again for multi_pass.
	JMP	BADOP

COFF:	PUSH	CS
	POP	DS
	invoke	NEWLINE
	JMP	CONFLP
Blank_Line:				;AN000;
	call	Getchr			;AN000;
	jmp	CONFLP			;AN000;

COFF_P:
	push	cs
	pop	ds


;J.K. 1/27/88 ;;;;;;;;;;;;;;;;;;
;To handle INSTALL= commands, we are going to use multi-pass.
;The first pass handles the other commands and only set Install_Flag when
;it finds any INSTALL command.	 The second pass will only handle the
;INSTALL= command.

;------------------------------------------------------------------------------
;INSTALL command
;------------------------------------------------------------------------------
TRYI:
	cmp	Multi_Pass_Id, 0		;AN029; the initial pass for XMAEM.SYS
	je	Multi_Try_XMAEM 		;AN029;     and BUFFERS= ... /X pre scan.
	cmp	Multi_Pass_Id, 2		;AN026; the second pass for IFS= ?
	je	Multi_Try_J			;AN026;
	cmp	Multi_Pass_Id, 3		;AN026; the third pass for INSTALL= ?
	je	Multi_Try_I			;AN026;
	cmp	ah, 'I' 			;AN018; INSTALL= command?
	jne	TryB				;AN018; the first pass is for normal operation.
	or	Install_Flag, HAVE_INSTALL_CMD	;AN018; Set the flag
	jmp	coff				;AN018; and handles the next command

Multi_Try_XMAEM:				;AN029;
	cmp	ah, 'D' 			;AN029; device= command?
	jne	Multi_Try_Buff			;AN029; no skip it.
	call	Chk_XMAEM			;AN029; is it for XMAEM.SYS?
	jnz	Multi_Pass_FIlter		;AN029; no skip it.
	mov	byte ptr es:[si-1], 0FFh	;AN029; mark this command as a Null command for the next pass.
	jmp	TryDJ				;AN029; execute this command.
Multi_Try_Buff: 				;AN030;
	cmp	ah, 'B' 			;AN030; Buffers= command?
	jne	Multi_Pass_Filter		;AN030;
	mov	Buffer_Pre_Scan, 1		;AN030; Set Buffer_Pre_Scan
	jmp	TryB				;AN030; TryB will set P_Buffer_Slash_X to non-zero value.

Multi_Try_J:					;AN026;
	cmp	ah, 'J' 			;AN026; IFS= command?
	jne	Multi_Pass_Filter		;AN026; No. Ignore this.
	jmp	GotJ				;AN026; Handles IFS= command.

Multi_Try_I:					;AN026;
	cmp	ah, 'I' 			;AN026; INSTALL= command?
	jne	Multi_Pass_Filter		;AN026; No. Ignore this.
	call	Do_Install_Exec 		;Install it.
	jmp	Coff				;to handle next Install= command.

Multi_Pass_Filter:				;AN023;AN026;
	cmp	ah, 'Y' 			;AN023; Comment?
	je	Multi_Pass_Adjust		;AN023;
	cmp	ah, 'Z' 			;AN023; Bad command?
	je	Multi_Pass_Adjust		;AN023;
	cmp	ah, '0' 			;AN023; REM?
	jne	Multi_Pass_Coff 		;AN023; ignore the rest of the commands.
Multi_Pass_Adjust:				;AN023; These commands need to
	dec	Chrptr				;AN023;  adjust chrptr, count
	inc	Count				;AN023;  for NEWLINE proc.
Multi_Pass_Coff:				;AN023;
	jmp	Coff				;AN018; To handle next INSTALL= commands.

;------------------------------------------------------------------------------

Sysinit_Parse	proc
;Set up registers for SysParse
;In)	ES:SI -> command line in  CONFBOT
;	DI -> offset of the parse control defintion.
;
;Out)	Calls SYSPARSE.
;	Carry will set if Parse error.
;	*** The caller should check the EOL condition by looking at AX
;	*** after each call.
;	*** If no parameters are found, then AX will contain a error code.
;	*** If the caller needs to look at the SYNOMYM@ of the result,
;	***  the caller should use CS:@ instead of ES:@.
;	CX register should be set to 0 at the first time the caller calls this
;	 procedure.
;	AX - exit code
;	BL - TErminated delimeter code
;	CX - new positional ordinal
;	SI - set to pase scanned operand
;	DX - selected result buffer

	push	es			;save es,ds
	push	ds

	push	es
	pop	ds			;now DS:SI -> command line
	push	cs
	pop	es			;now ES:DI -> control definition

	mov	cs:Badparm_Seg,ds	;AN007;Save the pointer to the parm
	mov	cs:Badparm_Off,si	;AN007; we are about to parse for Badparm msg.
	mov	dx, 0
	call	SysParse
	cmp	ax, $P_NO_ERROR 	;no error
;	$IF	E,OR
	JE $$LL1
	cmp	ax, $P_RC_EOL		;or the end of line?
;	$IF	E
	JNE $$IF1
$$LL1:
		clc
;	$ELSE
	JMP SHORT $$EN1
$$IF1:
		stc
;	$ENDIF
$$EN1:
	pop	ds
	pop	es			;restore es,ds
	ret
Sysinit_Parse	endp

;------------------------------------------------------------------------------
; Buffer command
;------------------------------------------------------------------------------
;*******************************************************************************
;									       *
; Function: Parse the parameters of buffers= command.			       *
;									       *
; Input :								       *
;	ES:SI -> parameters in command line.				       *
; Output:								       *
;	Buffers set							       *
;	Buffer_Slash_X	flag set if /X option chosen.			       *
;	H_Buffers set if secondary buffer cache specified.		       *
;									       *
; Subroutines to be called:						       *
;	Sysinit_Parse							       *
; Logic:								       *
; {									       *
;	Set DI points to Buf_Parms;  /*Parse control definition*/	       *
;	Set DX,CX to 0; 						       *
;	Reset Buffer_Slash_X;						       *
;	While (End of command line)					       *
;	{ Sysinit_parse;						       *
;	  if (no error) then						       *
;	       if (Result_Val.$P_SYNONYM_ptr == Slash_E) then /*Not a switch   *
;		    Buffer_Slash_X = 1					       *
;	       else if	 (CX == 1) then 	    /* first positional */     *
;			  Buffers = Result_Val.$P_Picked_Val;		       *
;		    else  H_Buffers = Result_Val.$P_Picked_Val; 	       *
;	  else	{Show Error message;Error Exit} 			       *
;	};								       *
;	If (Buffer_Slash_X is off & Buffers > 99) then Show_Error;	       *
; };									       *
;									       *
;*******************************************************************************
;TryB:	 CMP	 AH,'B' 		 ;BUFFER COMMAND?
;	 JNZ	 TRYC
;	 invoke  GETNUM
;	 JZ	 TryBBad		 ; Gotta have at least one
;	 CMP	 AX,100 		 ; check for max number
;	 JB	 SaveBuf
;TryBBad:JMP	 BadOp
;SaveBuf:
;	 MOV	 [BUFFERS],AX
;CoffJ1: JMP	 COFF

TryB:
	CMP	AH,'B'
	JNZ	TryC
	mov	P_Buffer_Slash_X, 0	;AN000;AN025;
	mov	di, offset Buf_Parms	;AN000;
	xor	cx, cx			;AN000;
	mov	dx, cx			;AN000;

;	$SEARCH 			;AN000;
$$DO4:
	    call   Sysinit_Parse	;AN000;
;	$EXITIF    C			;AN000; Parse Error,
	JNC $$IF4
	    call   Badparm_p		;AN007;   and Show messages and end the search loop.
;	$ORELSE 			;AN000;
	JMP SHORT $$SR4
$$IF4:
	    cmp    ax, $P_RC_EOL	;AN000; End of Line?
;	$LEAVE	   E			;AN000;  then jmp to $Endloop for semantic check.
	JE $$EN4
	    cmp    Result_Val.$P_SYNONYM_PTR, offset Switch_X ;AN000;AN025;
;	    $IF    E					      ;AN000;
	    JNE $$IF8
		mov	P_Buffer_Slash_X, 1		      ;AN000;AN025; set the flag
;	    $ELSE					      ;AN000;
	    JMP SHORT $$EN8
$$IF8:
		mov	ax, word ptr Result_Val.$P_PICKED_VAL ;AN000;
		cmp	cx, 1				      ;AN000;
;		$IF	E				      ;AN000;
		JNE $$IF10
		    mov    P_Buffers, ax		      ;AN000;
;		$ELSE					      ;AN000;
		JMP SHORT $$EN10
$$IF10:
		    mov    P_H_Buffers, ax		      ;AN000;
;		$ENDIF					      ;AN000;
$$EN10:
;	    $ENDIF					      ;AN000;
$$EN8:
;	$ENDLOOP			;AN000;
	JMP SHORT $$DO4
$$EN4:
	    cmp     P_Buffers, 99	;AN000;
;	    $IF     A,AND		;AN000;
	    JNA $$IF15
	    cmp     P_Buffer_Slash_X, 0 ;AN000;AN025;
;	    $IF     E			;AN000;
	    JNE $$IF15
		 call	Badparm_p	;AN000;
		 mov	P_H_Buffers, 0	;AN000;
;	    $ELSE			;AN000;
	    JMP SHORT $$EN15
$$IF15:
		 mov	ax, P_Buffers	;AN000; We don't have any problem.
		 mov	Buffers, ax	;AN000; Now, let's set it really.
		 mov	ax, P_H_Buffers ;AN000;
		 mov	H_Buffers, ax	;AN000;
		 mov	al, P_Buffer_Slash_X  ;AN000;AN025;
		 mov	Buffer_Slash_X, al    ;AN000;AN025;
		 mov	ax, LineCount	      ;AN000;
		 mov	Buffer_LineNum, ax    ;AN000; Save the line number for the future use.
;	    $ENDIF			;AN000;
$$EN15:
;	$ENDSRCH			;AN000;
$$SR4:
	jmp	Coff

;------------------------------------------------------------------------------
; Break command
;------------------------------------------------------------------------------
;*******************************************************************************
;									       *
; Function: Parse the parameters of Break = command.			       *
;									       *
; Input :								       *
;	ES:SI -> parameters in command line.				       *
; Output:								       *
;	Turn the Control-C check on or off.				       *
;									       *
; Subroutines to be called:						       *
;	Sysinit_Parse							       *
; Logic:								       *
; {									       *
;	Set DI to Brk_Parms;						       *
;	Set DX,CX to 0; 						       *
;	While (End of command line)					       *
;	{ Sysinit_Parse;						       *
;	  if (no error) then						       *
;	       if (Result_Val.$P_Item_Tag == 1) then	  /*ON		 */    *
;		   Set P_Ctrl_Break, on;				       *
;	       else					  /*OFF 	 */    *
;		   Set P_Ctrl_Break, off;				       *
;	  else {Show message;Error_Exit};				       *
;	};								       *
;	If (no error) then						       *
;	   DOS function call to set Ctrl_Break check according to	       *
; };									       *
;									       *
;********************************************************************************
;TryC:	 CMP	 AH,'C'
;	 JZ	 GOTC
;	 JMP	 TRYDJ
;GOTC:
;	 CMP	 AL,'O' 		 ;FIRST LETTER OF "ON" or "OFF"
;	 JNZ	 TryCBad
;	 CALL	 GETCHR
;	 JC	 TryCBad
;	 CMP	 AL,'N' 		 ;SECOND LETTER OF "ON"
;	 JNZ	 TryCoff
;	 MOV	 AH,SET_CTRL_C_TRAPPING  ;TURN ON CONTROL-C CHECK
;	 MOV	 AL,1
;	 MOV	 DL,AL
;	 INT	 21H
;CoffJ2: JMP	 Coff
;TryCOff:CMP	 AL,'F'
;	 JNZ	 TryCBad		 ; Check for "OFF"
;	 CALL	 GetChr
;	 JC	 TryCBad
;	 CMP	 AL,'F'
;	 JZ	 COffJ2
;TryCBad:JMP	 BadOp
;
TryC:
	CMP	AH,'C'
	JNZ	TRYM
	mov	di, offset Brk_Parms	;AN000;
	xor	cx,cx			;AN000;
	mov	dx,cx			;AN000;
;	$SEARCH 			;AN000;
$$DO19:
	    call   Sysinit_Parse	;AN000;
;	$EXITIF    C			;AN000; Parse error
	JNC $$IF19
	    call   Badparm_p		;AN007;  Show message and end the serach loop.
;	$ORELSE 			;AN000;
	JMP SHORT $$SR19
$$IF19:
	    cmp    ax, $P_RC_EOL	;AN000; End of Line?
;	$LEAVE	   E			;AN000;  then end the $ENDLOOP
	JE $$EN19
	    cmp    Result_Val.$P_ITEM_TAG, 1	 ;AN000;
;	    $IF    E				 ;AN000;
	    JNE $$IF23
	       mov    P_Ctrl_Break, 1		 ;AN000; Turn it on
;	    $ELSE				 ;AN000;
	    JMP SHORT $$EN23
$$IF23:
	       mov    P_Ctrl_Break, 0		 ;AN000; Turn it off
;	    $ENDIF				 ;AN000;
$$EN23:
;	$ENDLOOP			   ;AN000; we actually set the ctrl break
	JMP SHORT $$DO19
$$EN19:
	    mov    ah, SET_CTRL_C_TRAPPING ;AN000; if we don't have any parse error.
	    mov    al, 1		   ;AN000;
	    mov    dl, P_Ctrl_Break	   ;AN000;
	    Int    21h			   ;AN000;
;	$ENDSRCH			   ;AN000;
$$SR19:
	jmp	Coff

;------------------------------------------------------------------------------
; MultiTrack command
;------------------------------------------------------------------------------
;*******************************************************************************
;									       *
; Function: Parse the parameters of MultiTrack= command.		       *
;									       *
; Input :								       *
;	ES:SI -> parameters in command line.				       *
; Output:								       *
;	Turn MulTrk_Flag on or off.					       *
;									       *
; Subroutines to be called:						       *
;	Sysinit_Parse							       *
; Logic:								       *
; {									       *
;	Set DI to Brk_Parms;						       *
;	Set DX,CX to 0; 						       *
;	While (End of command line)					       *
;	{ Sysinit_Parse;						       *
;	  if (no error) then						       *
;	       if (Result_Val.$P_Item_Tag == 1) then	  /*ON		 */    *
;		   Set P_Mtrk, on;					       *
;	       else					  /*OFF 	 */    *
;		   Set P_Mtrk, off;					       *
;	  else {Show message;Error_Exit};				       *
;	};								       *
;	If (no error) then						       *
;	   DOS function call to set MulTrk_Flag according to P_Mtrk.	       *
;									       *
; };									       *
;									       *
;********************************************************************************
TryM:					;AN002;
	CMP	AH,'M'			;AN002;
	JNZ	TRYW			;AN002;
	mov	di, offset Mtrk_Parms	;AN002;
	xor	cx,cx			;AN002;
	mov	dx,cx			;AN002;
;	$SEARCH 			;AN002;
$$DO28:
	    call   Sysinit_Parse	;AN002;
;	$EXITIF    C			;AN002; Parse error
	JNC $$IF28
	    call   Badparm_p		;AN007;  Show message and end the serach loop.
;	$ORELSE 			;AN002;
	JMP SHORT $$SR28
$$IF28:
	    cmp    ax, $P_RC_EOL	;AN002; End of Line?
;	$LEAVE	   E			;AN002;  then end the $ENDLOOP
	JE $$EN28
	    cmp    Result_Val.$P_ITEM_TAG, 1	 ;AN002;
;	    $IF    E				 ;AN002;
	    JNE $$IF32
	       mov    P_Mtrk, 1 		 ;AN002; Turn it on temporarily.
;	    $ELSE				 ;AN002;
	    JMP SHORT $$EN32
$$IF32:
	       mov    P_Mtrk, 0 		 ;AN002; Turn it off temporarily.
;	    $ENDIF				 ;AN002;
$$EN32:
;	$ENDLOOP			;AN002; we actually set the MulTrk_Flag here.
	JMP SHORT $$DO28
$$EN28:
	    push   ds			;AN002;
	    mov    ax, Code		;AN002;
	    mov    ds, ax		;AN002;
	    assume ds:Code
	    cmp    P_Mtrk, 0		;AN002;
;	    $IF    E			;AN002;
	    JNE $$IF36
	       mov    MulTrk_Flag, MULTRK_OFF2	  ;AN002; 0001h
;	    $ELSE				  ;AN002;
	    JMP SHORT $$EN36
$$IF36:
	       mov    MulTrk_Flag, MULTRK_ON	  ;AN002; 8000h
;	    $ENDIF			;AN002;
$$EN36:
	    pop    ds			;AN002;
	    assume ds:SYSINITSEG
;	$ENDSRCH			;AN002;
$$SR28:
	jmp	Coff			;AN002;

;------------------------------------------------------------------------------
; CPSW command
;------------------------------------------------------------------------------
;*******************************************************************************
;									       *
; Function: Parse the parameters of CPSW= command.			       *
;									       *
; Input :								       *
;	ES:SI -> parameters in command line.				       *
; Output:								       *
;	Turn CPSW on or off.						       *
;									       *
; Subroutines to be called:						       *
;	Sysinit_Parse							       *
; Logic:								       *
; {									       *
;	Set DI to CPSW_Parms;						       *
;	Set DX,CX to 0; 						       *
;	While (End of command line)					       *
;	{ Sysinit_Parse;						       *
;	  if (no error) then						       *
;	       if (Result_Val.$P_Item_Tag == 1) then	  /*ON		 */    *
;		   Set P_CPSW, on;					       *
;	       else					  /*OFF 	 */    *
;		   Set P_CPSW, off;					       *
;	  else {Show message;Error_Exit};				       *
;	};								       *
;	If (no error) then						       *
;	   DOS function call to set CPSW according to P_CPSW.		       *
; };									       *
;									       *
;********************************************************************************
TryW:					;AN002;
	CMP	AH,'W'			;AN002;
	JNZ	TRYDJ			;AN002;
	mov	di, offset CPSW_Parms	;AN002;
	xor	cx,cx			;AN002;
	mov	dx,cx			;AN002;
;	$SEARCH 			;AN002;
$$DO40:
	    call   Sysinit_Parse	;AN002;
;	$EXITIF    C			;AN002; Parse error
	JNC $$IF40
	    call   Badparm_p		;AN007;  Show message and end the serach loop.
;	$ORELSE 			;AN002;
	JMP SHORT $$SR40
$$IF40:
	    cmp    ax, $P_RC_EOL	;AN002; End of Line?
;	$LEAVE	   E			;AN002;  then end the $ENDLOOP
	JE $$EN40
	    cmp    Result_Val.$P_ITEM_TAG, 1	 ;AN002;
;	    $IF    E				 ;AN002;
	    JNE $$IF44
	       mov    P_CPSW, 1 		 ;AN002; Turn it on temporarily.
;	    $ELSE				 ;AN002;
	    JMP SHORT $$EN44
$$IF44:
	       mov    P_CPSW, 0 		 ;AN002; Turn it off temporarily.
;	    $ENDIF				 ;AN002;
$$EN44:
;	$ENDLOOP			;AN002; we actually set the MulTrk_Flag here.
	JMP SHORT $$DO40
$$EN40:
	    mov    ah, SET_CTRL_C_TRAPPING ;AN000; The same function number as Ctrl_Break
	    mov    al, 4		   ;AN000; Set CPSW state function
	    mov    dl, P_CPSW		   ;AN000; 0=off, 1=on
	    Int    21h			   ;AN000;
;	$ENDSRCH			;AN002;
$$SR40:
	jmp	Coff			;AN002;

;------------------------------------------------------------------------------
; Device command
;------------------------------------------------------------------------------
TRYDJ:
	and	cs:IFS_Flag, NOT_IFS	;AN000; Reset the flag
	CMP	AH,'D'
	JZ	GOTDJ
	CMP	AH,'J'
	jz	GOTJ
	JMP	TRYQ
GOTJ:					;AN000; IFS= command.
	or	cs:[IFS_Flag], IS_IFS	;AN000; set the flag.
	cmp	Multi_Pass_Id, 2	;second pass?
	je	GOTDJ			;then proceed
	jmp	Coff			;else ignore this until the second pass.

;	 jmp	 GOTDJ_Cont
;GOTD:
;	 test	 cs:[IFS_Flag], HAD_IFS  ;AN000; Cannot have DEVICE= command after IFS= command.
;	 jz	 GOTDJ_Cont		 ;AN000;
;	 call	 Incorrect_Order	 ;AN000; Display "Incorrect order ..." msg.
;	 jmp	 COFF			 ;AN000;

GOTDJ:
	MOV	BX,CS			;DEVICE= or IFS= command.
	MOV	DS,BX

	MOV	WORD PTR [BPB_ADDR],SI
	MOV	WORD PTR [BPB_ADDR+2],ES

;J.K. In case it is for IFS=, then set the parameter pointer.
	mov	word ptr [ifs_rh.IFSR_PARMS@], SI   ;AN000; for IFS
	mov	word ptr [ifs_rh.IFSR_PARMS@+2], ES ;AN000;

	CALL	ROUND
;J.K. Set up the DEVMARK entries here for MEM command.
;J.K. Only the DEVMARK_ID and DEVMARK_FILENAME will be set.
;J.K. DEVMARK_SIZE should be set after a successful process of this file.
	call	Set_DevMark		;AN004;
	inc	[MEMHI] 		;AN004;Size of DEVMARK is a paragraph!!
					;Don't forget decrease MEMHI
					; with an unsuccessful process of this file!!.
	XOR	AX,AX
	MOV	WORD PTR [ENTRY_POINT],AX
	MOV	AX,[MEMHI]
	MOV	WORD PTR [ENTRY_POINT+2],AX	;SET ENTRY POINT

	IF	NOT NOEXEC
	MOV	[LDOFF],AX		;SET LOAD OFFSET
	ENDIF

	PUSH	ES
	POP	DS
ASSUME	DS:NOTHING
	MOV	DX,SI			;DS:DX POINTS TO FILE NAME

	IF	NOEXEC
	LES	BX,DWORD PTR CS:[MEMLO]
	CALL	LDFIL			;LOAD IN THE DEVICE DRIVER
	ELSE
; We are going to open the cdevice driver and size it as is done
;  in LDFIL. The reason we must do this is that EXEC does NO checking
;  for us. We must make sure there is room to load the device without
;  trashing SYSINIT. This code is not
;  perfect (for instance .EXE device drivers are possible) because
;  it does its sizing based on the assumption that the file being loaded
;  is a .COM file. It is close enough to correctness to be usable.
	MOV	ES,AX			;ES:0 is LOAD addr
	MOV	AX,OPEN SHL 8		;OPEN THE FILE
	STC				;IN CASE OF INT 24
	INT	21H
	JC	BADLDRESET
	MOV	BX,AX			;Handle in BX
;AN016; UNDO THE EXTENDED ATTRIBUTE HANDLING
;	 call	 Get_Ext_Attribute	 ;AN009;
;	 jc	 BadLdReset		 ;AN009;
;	 test	 cs:[IFS_Flag], IS_IFS	 ;AN009;
;	 jnz	 Chk_Ext_Attr_IFS	 ;AN009;
;	 cmp	 al, EA_UNSPECIFIED	 ;AN009;Check the extended attr. for device driver
;	 je	 Ext_Attr_Ok		 ;AN009;  Allow 0 and EA_DEVICE_DRIVER
;	 cmp	 al, EA_DEVICE_DRIVER	 ;AN009;
;	 je	 Ext_Attr_Ok		 ;AN009;
;	 stc				 ;AN012;BadLdReset depends on the carry bit.
;	 jmp	 BadLdReset		 ;AN009;
;Chk_Ext_Attr_IFS:			 ;AN009;
;	 cmp	 al, EA_IFS_DRIVER	 ;AN009;
;	 je	 Ext_Attr_Ok		 ;AN012;
;	 stc				 ;AN012;
;	 jmp	 BadLdReset		 ;AN012;
;Ext_Attr_Ok:				 ;AN009;
	PUSH	DX			; Save pointer to name
	XOR	CX,CX
	XOR	DX,DX
	MOV	AX,(LSEEK SHL 8) OR 2
	STC				;IN CASE OF INT 24
	INT	21H			; Get file size in DX:AX
	JNC	GO_AHEAD_LOAD
	MOV	AH,CLOSE		; Close file
	INT	21H
	POP	DX			; Clean stack
	STC				; Close may clear carry
	JMP	SHORT BADLDRESET

GO_AHEAD_LOAD:
    ; Convert size in DX:AX to para in AX
	ADD	AX,15			; Round up size for conversion to para
	ADC	DX,0
	MOV	CL,4
	SHR	AX,CL
	MOV	CL,12
	SHL	DX,CL			; Low nibble of DX to high nibble
	OR	AX,DX			; AX is now # of para for file

	MOV	CX,ES			; CX:0 is xaddr
	ADD	CX,AX			; New device will take up to here
	JC	MEM_ERRJY		; WOW!!!!
	CMP	CX,CS:[ALLOCLIM]
	JB	OKLDX
MEM_ERRJY:
	JMP	MEM_ERR

OKLDX:
	POP	DX			; Recover name pointer
	MOV	AH,CLOSE		; Close file
	INT	21H
	MOV	BX,CS
	MOV	ES,BX
	MOV	BX,OFFSET PRMBLK	;ES:BX POINTS TO PARAMETERS
	MOV	AL,3
	MOV	AH,EXEC
	STC				;IN CASE OF INT 24
	INT	21H			;LOAD IN THE DEVICE DRIVER
	ENDIF

BADLDRESET:
	PUSH	DS
	POP	ES			;ES:SI BACK TO CONFIG.SYS
	PUSH	CS
	POP	DS			;DS BACK TO SYSINIT
ASSUME	DS:SYSINITSEG
	JNC	GOODLD
BADBRK:
	test	cs:[SetDevMarkFlag],SETBRKDONE ;AN004;If already Set_Break is done,
	jnz	Skip0_ResetMEMHI	;AN004; then do not
	dec	cs:[MEMHI]		   ;AN004;Adjust MEMHI by a paragrah of DEVMARK.
Skip0_ResetMEMHI:
	cmp	byte ptr es:[si], CR	;file name is CR? (Somebody entered "device=" without filename)
	jne	BADBRK_1
	jmp	BADOP			;show "Unrecognized command in CONFIG.SYS"
BADBRK_1:
	invoke	BADLOAD
	JMP	COFF

GOODLD:
;J.K. If it is IFS=, then we should set IFS_DOSCALL@ field in IFSHEADER.
	test	cs:[IFS_Flag], IS_IFS		;AN000;
	jz	Skip_IFSHEADER_Set		;AN000;
	push	es				;AN000;
	push	di				;AN000;
	push	ds				;AN000;
	mov	bx, word ptr cs:[ENTRY_POINT+2] ;AN000;
	mov	ds, bx				;AN000; DS:0 will be the header
	les	di, cs:[DosInfo]		;AN000;
	mov	bx, word ptr es:[di.SYSI_IFS_DOSCALL@]	 ;AN000;
	mov	word ptr ds:[IFS_DOSCALL@], bx		 ;AN000;
	mov	bx, word ptr es:[di.SYSI_IFS_DOSCALL@]+2 ;AN000;
	mov	word ptr ds:[IFS_DOSCALL@]+2, bx	 ;AN000;
	pop	ds				;AN000;
	pop	di				;AN000;
	pop	es				;AN000;
Skip_IFSHEADER_Set:				;AN000;
	SaveReg <ES,SI> 		;INITIALIZE THE DEVICE
;	 call	 Chk_IBMCACHE		 ;AN024 IBMCACHE.SYS problem.;AN026;IBMDOS will handles this thru 4Bh call.
Restore:MOV	BL,ES:[SI]		;   while ((c=*p) != 0)
	OR	BL,BL
	JZ	Got
	INC	SI			;	p++;
	JMP	Restore
Got:	MOV	BYTE PTR ES:[SI],' '	;   *p = ' ';
	SaveReg <ES,SI>
	PUSH	CS
	POP	ES

	test	cs:[IFS_Flag], IS_IFS	;AN000;
	jz	Got_Device_Com		;AN000;
	mov	bx, IFS_CALL@		;AN000; offset from the start of IFSHEADER
	call	CallIFS 		;AN000;
	jmp	short End_Init_Call
Got_Device_Com:
	push	ds			;AN017;
	push	si			;AN017;
	lds	si, cs:[ENTRY_POINT]	;AN017; Peeks the header attribute
	test	word ptr ds:[si.SDEVATT], DEVTYP  ;AN017;Block device driver?
	jnz	Got_Device_Com_Cont		  ;AN017;No.
	lds	si, cs:[DOSINFO]	;AN017; DS:SI -> SYS_VAR
	cmp	ds:[si.SYSI_NUMIO], 26	;AN017; No more than 26 drive number
	jb	Got_Device_Com_Cont	;AN017;
	pop	si			;AN017;
	pop	ds			;AN017;
	pop	si			;AN017;clear the stack
	pop	es			;AN017;
	jmp	BadNumBlock		;AN017;
Got_Device_Com_Cont:			;AN017;
	pop	si			;AN017;
	pop	ds			;AN017;
	MOV	BX,SDEVSTRAT
	invoke	CALLDEV 		;   CallDev (SDevStrat);
	MOV	BX,SDEVINT
	invoke	CALLDEV 		;   CallDev (SDevInt);
End_Init_Call:
	RestoreReg  <SI,DS>
	MOV	BYTE PTR [SI],0 	;   *p = 0;

	PUSH	CS
	POP	DS

	test	[IFS_Flag], IS_IFS	;AN000;
	jz	Was_Device_Com		;AN000;
	cmp	[ifs_rh.IFSR_RETCODE], 0 ;AN000; Was a success ?
	jne	Erase_Dev_do		;AN000;
	pop	si			;AN000; restore es:si to clean up the
	pop	es			;AN000; stack for Set_Break call.
	mov	ax, word ptr [Entry_Point+2]	   ;AN000; Get the loaded segment
	add	ax, word ptr [ifs_rh.IFSR_RESSIZE] ;AN000;
	mov	word ptr [Break_addr], 0	   ;AN000;
	mov	word ptr [Break_addr+2], ax	   ;AN000;
	or	cs:[SetDevMarkFlag], FOR_DEVMARK       ;AN004;
	invoke	Set_Break		;AN000; Will also check the memory size too.
	push	es			;AN000; Save it again, in case, for Erase_Dev_Do.
	push	si			;AN000;
	jc	Erase_Dev_do		;AN000;
Link_IFS:				;AN000;
	les	di, cs:[dosinfo]	;AN000;
	mov	cx, word ptr es:[di.SYSI_IFS]	;AN000; save old pointer
	mov	dx, word ptr es:[di.SYSI_IFS+2] ;AN000;
	lds	si, cs:[Entry_Point]		;AN000;
	mov	word ptr es:[di.SYSI_IFS],si	;AN000;
	mov	word ptr es:[di.SYSI_IFS+2], ds ;AN000;
	mov	word ptr ds:[si], cx		;AN000; We don't permit multiple IFSs.
	mov	word ptr ds:[si+2], dx		;AN000;
	pop	si			;AN000; Restore es:si for the next command.
	pop	es			;AN000;
;	 mov	 cs:[IFS_Flag], HAD_IFS  ;AN014; Set the flag.
	jmp	COFF			;AN000;

ERASE_DEV_do:				;AC000;; Modified to show message "Error in CONFIG.SYS..."
	pop	si
	pop	es
	push	cs
	pop	ds
	test	[SetDevMarkFlag],SETBRKDONE ;AN004;If already Set_Break is done,
	jnz	Skip1_ResetMEMHI	;AN004; then do not
	dec	[MEMHI] 		;AN004;Adjust MEMHI by a paragrah of DEVMARK.
Skip1_ResetMEMHI:
	cmp	ConfigMsgFlag, 0	;AN015;
	je	No_Error_Line_Msg	;AN015;
	call	Error_Line		;AN021; No "Error in CONFIG.SYS" msg for device driver. DCR D493
	mov	ConfigMsgFlag, 0	;AN015;AN021;Set the default value again.
No_Error_Line_Msg:			;AN015;
	JMP	Coff

Was_Device_Com: 			;AN000;
	MOV	AX,WORD PTR [BREAK_ADDR+2]
	CMP	AX,[MEMORY_SIZE]
	JB	BREAKOK
	POP	SI
	POP	ES
	JMP	BADBRK

BREAKOK:
	LDS	DX,[ENTRY_POINT]	;SET DS:DX TO HEADER
	MOV	SI,DX
	ADD	SI,SDEVATT		;DS:SI POINTS TO ATTRIBUTES
	LES	DI,CS:[DOSINFO] 	;ES:DI POINT TO DOS INFO
	MOV	AX,DS:[SI]		;GET ATTRIBUTES
	TEST	AX,DEVTYP		;TEST IF BLOCK DEV
	JZ	ISBLOCK
	or	cs:[SetDevMarkFlag],FOR_DEVMARK ;AN004;
	invoke	Set_Break		; Go ahead and alloc mem for device
	jc	Erase_Dev_do		;device driver's Init routien failed.
	TEST	AX,ISCIN		;IS IT A CONSOLE IN?
	JZ	TRYCLK
	MOV	WORD PTR ES:[DI.SYSI_CON],DX
	MOV	WORD PTR ES:[DI.SYSI_CON+2],DS

TRYCLK: TEST	AX,ISCLOCK		;IS IT A CLOCK DEVICE?
	JZ	GOLINK
	MOV	WORD PTR ES:[DI+SYSI_CLOCK],DX
	MOV	WORD PTR ES:[DI+SYSI_CLOCK+2],DS
GOLINK: JMP	LINKIT

ISBLOCK:
	MOV	AL,CS:[UNITCOUNT]	;IF NO UNITS FOUND, erase the device
	OR	AL,AL
	jz	Erase_Dev_do
;	 JNZ	 PERDRV
;	 MOV	 AX, -1
;	 JMP	 ENDDEV

PERDRV:
	CBW				; WARNING NO DEVICE > 127 UNITS
	MOV	CX,AX
	MOV	DH,AH
	MOV	DL,ES:[DI.SYSI_NUMIO]	;GET NUMBER OF DEVICES
	MOV	AH,DL
	ADD	AH,AL			; Check for too many devices
	CMP	AH,26			; 'A' - 'Z' is 26 devices
	JBE	OK_BLOCK
BadNumBlock:				;AN017;
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET BADBLOCK
	invoke	PRINT
	JMP	ERASE_DEV_do

OK_BLOCK:
	or	cs:[SetDevMarkFlag],FOR_DEVMARK ;AN004;
	invoke	SET_BREAK		; Alloc the device
	ADD	ES:[DI.SYSI_NUMIO],AL	;UPDATE THE AMOUNT
	ADD	CS:DriveNumber,AL	; remember amount for next device
	LDS	BX,CS:[BPB_ADDR]	;POINT TO BPB ARRAY
PERUNIT:
	LES	BP,CS:[DOSINFO]
	LES	BP,DWORD PTR ES:[BP.SYSI_DPB]	;GET FIRST DPB

SCANDPB:CMP	WORD PTR ES:[BP.DPB_NEXT_DPB],-1
	JZ	FOUNDPB
	LES	BP,ES:[BP.DPB_NEXT_DPB]
	JMP	SCANDPB
FOUNDPB:
	MOV	AX,CS:[MEMLO]
	MOV	WORD PTR ES:[BP.DPB_NEXT_DPB],AX
	MOV	AX,CS:[MEMHI]
	MOV	WORD PTR ES:[BP.DPB_NEXT_DPB+2],AX
	LES	BP,DWORD PTR CS:[MEMLO]
	ADD	WORD PTR CS:[MEMLO],DPBSIZ
	or	cs:[SetDevMarkFlag], FOR_DEVMARK       ;AN004;Add DPB area for this unit
	CALL	ROUND			;Check for alloc error
	MOV	WORD PTR ES:[BP.DPB_NEXT_DPB],-1
	MOV	ES:[BP.DPB_FIRST_ACCESS],-1

	MOV	SI,[BX] 		;DS:SI POINTS TO BPB
	INC	BX
	INC	BX			;POINT TO NEXT GUY
	MOV	WORD PTR ES:[BP.DPB_DRIVE],DX
	MOV	AH,SETDPB		;HIDDEN SYSTEM CALL
	INT	21H
	MOV	AX,ES:[BP.DPB_SECTOR_SIZE]
	PUSH	ES
	LES	DI,CS:[DOSINFO] 	;ES:DI POINT TO DOS INFO
	CMP	AX,ES:[DI.SYSI_MAXSEC]
	POP	ES
	ja	Bad_BPB_Size_Sector
	PUSH	DS
	PUSH	DX
	LDS	DX,CS:[ENTRY_POINT]
	MOV	WORD PTR ES:[BP.DPB_DRIVER_ADDR],DX
	MOV	WORD PTR ES:[BP.DPB_DRIVER_ADDR+2],DS
	POP	DX
	POP	DS
	INC	DX
	INC	DH
	LOOP	PERUNIT
	PUSH	CS
	POP	DS
	CALL	TEMPCDS 		; Set CDS for new drives

LINKIT:
	LES	DI,CS:[DOSINFO] 	;ES:DI = DOS TABLE
	MOV	CX,WORD PTR ES:[DI.SYSI_DEV]	;DX:CX = HEAD OF LIST
	MOV	DX,WORD PTR ES:[DI.SYSI_DEV+2]

	LDS	SI,CS:[ENTRY_POINT]	;DS:SI = DEVICE LOCATION
	MOV	WORD PTR ES:[DI.SYSI_DEV],SI	;SET HEAD OF LIST IN DOS
	MOV	WORD PTR ES:[DI.SYSI_DEV+2],DS
	MOV	AX,DS:[SI]		;GET POINTER TO NEXT DEVICE
	MOV	WORD PTR CS:[ENTRY_POINT],AX	;AND SAVE IT

	MOV	WORD PTR DS:[SI],CX	;LINK IN THE DRIVER
	MOV	WORD PTR DS:[SI+2],DX
ENDDEV:
	POP	SI
	POP	ES
	INC	AX			;AX = FFFF (no more devs if YES)?
	JZ	COFFJ3
	inc	cs:MultDeviceFlag	;AN001; Possibly multiple device driver.
	JMP	GOODLD			;OTHERWISE PRETEND WE LOADED IT IN
COFFJ3: mov	cs:MultDeviceFlag, 0	;AN001; Reset the flag
	JMP	COFF

Bad_BPB_Size_Sector:
	POP	SI
	POP	ES
	MOV	DX,OFFSET BADSIZ_PRE
;	 MOV	 BX,OFFSET BADSIZ_POST
	mov	bx, offset CRLFM	;AN???;
	invoke	PRNERR
	test	[SetDevMarkFlag],SETBRKDONE ;AN004;If already Set_Break is done,
	jnz	Skip2_ResetMEMHI	;AN004; then do not
	dec	[MEMHI] 		;AN004;Adjust MEMHI by a paragrah of DEVMARK.
Skip2_ResetMEMHI:
	JMP	COFF


;------------------------------------------------------------------------------
; Country command
; J.K. The syntax is:
;	COUNTRY=country id {,codepage {,path}}
;	COUNTRY=country id {,,path}	:Default CODEPAGE ID in DOS
;------------------------------------------------------------------------------
TRYQ:
	CMP	AH,'Q'
	JZ	TRYQ_CONT
	JMP	TRYF
TRYQ_CONT:

;	 invoke  GETNUM
;	 JZ	 TryQBad		 ; 0 is never a valid code, or number is
;					 ;   bad
;	 MOV	 BX,AX			 ; Country code in BX
;
;					 ;J.K. 5/26/86
;	 MOV	 DX,0			 ; assume no code page id
;
;	 invoke  skip_delim		 ;skip the delimeters after the first num
;	 jc	 TryQ_Def_File		 ;no more characters left? then use default file
;	 cmp	 al, CR 		 ;
;	 je	 TryQ_Def_File
;	 cmp	 al, LF
;	 jne	 TRYQ_YES_EXTENDED
;	 inc	 [COUNT]		 ;This is for NEWLINE routine in COFF.
;	 dec	 [CHRPTR]
;COFFJ41:
;	 JMP	 TryQ_Def_File		 ;O.K. no code page, no path specified. Use default path.
;
;TRYQ_YES_EXTENDED:
;	 cmp	 al, ','		 ;was the second comma?
;	 jne	 TryQ_GETNUM
;	 invoke  skip_delim		 ;Yes, skip ',' and other possible delim
;	 jmp	 short TRYQ_PATH	 ;and No code page id entered.
;TRYQ_GETNUM:
;	 invoke  GETNUM
;	 jc	 TryQBadCOM		 ;"Country=xxx,path" will not be accepted.
;;	 jc	 TRYQ_PATH		 ;Codepage is not specified. No code page.
;;					 ;At this point, AL already contain the
;;					 ;first char of the PATH.
;	 jz	 TryQBad		 ;codepage=0 entered. Error
;	 mov	 DX, AX 		 ;save code page in DX
;	 invoke  skip_delim		 ;move CHRPTR to the path string
;	 jc	 TryQ_Def_File		 ;no more char? then use default filename
;	 cmp	 al, CR
;	 je	 TryQ_Def_File
;	 cmp	 al, LF
;	 jne	 TryQ_PATH		 ;path entered.
;	 inc	 [COUNT]
;	 dec	 [CHRPTR]
;TryQ_Def_File:
;	 push	 dx			 ;save code page
;	 mov	 cs:CNTRY_DRV, 0	 ;flag that the default path has been used!!!
;	 mov	 dx, offset CNTRY_ROOT	 ;the default path
;	 jmp	 TRYQ_OPEN
;
;TryQBad:				 ;"Invalid country code or code page"
;	STC
;	MOV	DX,OFFSET BADCOUNTRY
;	 jmp	 TryQChkErr
;
;TryQBadCOM:				 ;Error in COUNTRY command
;	 STC
;	 MOV	 DX,OFFSET BADCOUNTRYCOM
;	 jmp	 TryQChkErr
;
;TRYQ_PATH:				 ;DS - sysinitseg, ES - CONFBOT,
;	 mov	 CX, [COUNT]		 ;AL - the first char of path
;	 inc	 CX			 ;BX - country id, DX - codepage id, 0 = No code page
;	 mov	 DI, SI
;TRYQ_PATH_LOOP:			 ;find the end of path to put 0 after that.
;	 mov	 AL, byte ptr ES:[DI]
;	 call	 delim
;	 jz	 TRYQ_PATH_END
;	 cmp	 al, 13
;	 jz	 TRYQ_PATH_END
;	 inc	 DI
;	 jmp	 short TRYQ_PATH_LOOP
;TryQBad_Brg:jmp short TryQBad
;TRYQ_PATH_END:
;	 mov	 es:byte ptr [di], 0	 ;make it a ASCIIZ string. (Organize did not handle this string)
;	 push	 ds			 ;switch ds,es
;	 push	 es
;	 pop	 ds
;	 pop	 es
;
;	 mov	 di, offset  CNTRY_DRV	 ;move the user specified path to CNTRY_DRV
;	 call	 Move_ASCIIZ
;
;	 push	 ds			 ;restore ds,es
;	 push	 es
;	 pop	 ds
;	 pop	 es
;
;;	  call	  Set_Country_Path	  ;set CNTRY_DRV
;
;	 push	 dx			 ;save DX
;	 mov	 dx, offset CNTRY_DRV	 ;Now DS:DX -> CNTRY_DRV

	mov	Cntry_Drv, 0		;AN000; Reset the drive,path to default value.
	mov	P_Code_Page,0		;AN000;
	mov	di, offset Cntry_Parms	;AN000;
	xor	cx,cx			;AN000;
	mov	dx,cx			;AN000;
;	$SEARCH 			;AN000;
$$DO49:
	    call   Sysinit_Parse	;AN000;
;	$EXITIF    C			;AN000; Parse error, check the error code and
	JNC $$IF49
	    call   Cntry_Error		;AN000;  Show message and end the serach loop.
	    mov    P_Cntry_Code, -1	;AN000; Signals that parse error.
;	$ORELSE 			;AN000;
	JMP SHORT $$SR49
$$IF49:
	    cmp    ax, $P_RC_EOL	;AN000; End of Line?
;	$LEAVE	   E			;AN000;  then end the $SEARCH LOOP
	JE $$EN49
	    cmp    Result_Val.$P_TYPE, $P_NUMBER		;AN000; Numeric?
;	    $IF    E						;AN000;
	    JNE $$IF53
		   mov	  ax, word ptr Result_Val.$P_PICKED_VAL ;AN000;
		   cmp	    cx, 1				;AN000;
;		   $IF	 E					;AN000;
		   JNE $$IF54
			 mov   P_Cntry_Code, ax 		;AN000;
;		   $ELSE					;AN000;
		   JMP SHORT $$EN54
$$IF54:
			 mov   P_Code_Page, ax			;AN000;
;		   $ENDIF					;AN000;
$$EN54:
;	    $ELSE				;AN000; Path entered.
	    JMP SHORT $$EN53
$$IF53:
		   push ds			;AN000;
		   push es			;AN000;
		   push si			;AN000;
		   push di			;AN000;
		   push cs			;AN000;
		   pop	es			;AN000;
		   lds	si, RV_Dword		;AN000; Move the path to known place.
		   mov	di, offset CNTRY_Drv	;AN000;
		   call Move_ASCIIZ		;AN000;
		   pop	di			;AN000;
		   pop	si			;AN000;
		   pop	es			;AN000;
		   pop	ds			;AN000;
;	    $ENDIF				;AN000;
$$EN53:
;	$ENDLOOP
	JMP SHORT $$DO49
$$EN49:
;	$ENDSRCH				;AN000;
$$SR49:
	cmp	P_Cntry_Code, -1		;AN000; Had a parse error?
	jne	TRYQ_OPEN			;AN000;
	jmp	Coff				;AN000;

TryQBad:				;"Invalid country code or code page"
       STC
       MOV     DX,OFFSET BADCOUNTRY
       jmp     TryQChkErr

TRYQ_OPEN:
	cmp	CNTRY_Drv, 0		;AC000;
	je	TRYQ_Def		;AC000;
	mov	dx, offset CNTRY_Drv	;AC000;
	jmp	TryQ_Openit		;AC000;
TRYQ_Def:				;AC000;
	mov	dx, offset CNTRY_Root	;AC000;
TryQ_Openit:
	mov	ax, 3d00h		;open a file
	stc
	int	21h
	jc	TryQFileBad		;open failure

	mov	cs:CntryFileHandle, ax	;save file handle
	mov	bx, ax
	mov	ax, cs:P_Cntry_Code	   ;AN000;
	mov	dx, cs:P_Code_Page	   ;AN000; Now, AX=country id, bx=filehandle
;	 xchg	 ax, bx 		 ;now, AX = country id, BX = file handle
	mov	cx, cs:[MEMHI]
	add	cx, 128 		;I need 2K buffer to handle COUNTRY.SYS
	cmp	cx, cs:[ALLOCLIM]
	ja	TryQMemory		;cannot allocate the buffer for country.sys

	mov	si, offset CNTRY_DRV	;DS:SI -> CNTRY_DRV
	cmp	byte ptr [si],0 	;default path?
	jne	TRYQ_Set_for_DOS
	inc	si
	inc	si			;DS:SI -> CNTRY_ROOT
TRYQ_Set_for_DOS:
	les	di, cs:SYSI_Country	;ES:DI -> country info tab in DOS
	push	di			;save di
	add	di, ccPath_CountrySys
	call	MOVE_ASCIIZ		;Set the path to COUNTRY.SYS in DOS.
	pop	di			;ES:DI -> country info tab again.
	mov	cx, cs:[MEMHI]
	mov	ds, cx
	xor	si, si			;DS:SI -> 2K buffer to be used.
	call	SetDOSCountryInfo	;now do the job!!!
	jnc	TryQchkERR		;read error or could not find country,code page combination
	cmp	cx, -1			;Could not find matching country_id,code page?
	je	TryQBad 		;then "Invalid country code or code page"
TryQFileBad:
	push	cs			;AN000;
	pop	es			;AN000;
	cmp	cs:CNTRY_DRV,0		;Is the default file used?
	je	TryQDefBad
;	 mov	 si, cs:[CONFBOT]
;	 mov	 es, si
;	 mov	 si, cs:[CHRPTR]
;	 dec	 si			 ;ES:SI -> path in CONFBOT
	mov	si, offset CNTRY_Drv
	jmp	short TryQBADLOAD
TryQDefBad:				;Default file has been used.
;	 push	 cs
;	 pop	 es
	mov	si, offset CNTRY_ROOT	;ES:SI -> \COUNTRY.SYS in SYSINIT_SEG
TryQBADLOAD:
	call	BADLOAD 		;DS will be restored to SYSINIT_SEG
	mov	cx, cs:[CONFBOT]
	mov	es, cx			;Restore ES -> CONFBOT.
	jmp	short CoffJ4
TryQMemory:
	MOV	DX,OFFSET INSUFMEMORY
TryQChkErr:
	mov	cx, cs:[CONFBOT]
	mov	es, cx			;restore ES -> CONFBOT seg
	push	cs
	pop	ds			;retore DS to SYSINIT_SEG
	jnc	CoffJ4			;if no error, then exit
	invoke	PRINT			;else show error message
	call	Error_Line		;AN000;
CoffJ4:
	mov	bx, CntryFileHandle
	mov	ah, 3eh
	int	21h			;close a file. Don't care even if it fails.
	JMP	COFF

Cntry_Error	proc	near
;Function: Show "Invalid country code or code page" messages, or
;		"Error in COUNTRY command" depending on the error code
;		in AX returned by SYSPARSE;
;In:	AX - error code
;	DS - Sysinitseg
;	ES - CONFBOT
;Out:	Show message.  DX destroyed.

	cmp	ax, $P_OUT_OF_RANGE
;	$IF	E
	JNE $$IF61
	     mov	dx, offset BadCountry ;"Invalid country code or code page"
;	$ELSE
	JMP SHORT $$EN61
$$IF61:
	     mov	dx, offset BadCountryCom ;"Error in CONTRY command"
;	$ENDIF
$$EN61:
	invoke	Print
	call	Error_Line
	ret
Cntry_Error	endp

;------------------------------------------------------------------------------
; Files command
;------------------------------------------------------------------------------
;*******************************************************************************
; Function: Parse the parameters of FILES= command.			       *
;									       *
; Input :								       *
;	ES:SI -> parameters in command line.				       *
; Output:								       *
;	Variable FILES set.						       *
;									       *
; Subroutines to be called:						       *
;	Sysinit_Parse							       *
; Logic:								       *
; {									       *
;	Set DI points to FILES_Parms;					       *
;	Set DX,CX to 0; 						       *
;	While (End of command line)					       *
;	{ Sysinit_parse;						       *
;	  if (no error) then						       *
;	     Files = Result_Val.$P_Picked_Val				       *
;	  else								       *
;	     Error Exit;						       *
;	};								       *
; };									       *
;									       *
;*******************************************************************************
TRYF:
	CMP	AH,'F'
	JNZ	TRYL

;	 invoke  GETNUM
;	 CMP	 AX,5			 ;j.k. change it to 8!!!!!!!!
;	 JB	 TryFBad		 ; Gotta have at least 5
;	 CMP	 AX,256
;	 JAE	 TryFBad		 ; Has to be a byte
;	 MOV	 [FILES],AL
;CoffJ5: JMP	 COFF
;TryFBad:JMP	 BadOp

	mov	di, offset Files_Parms	;AN000;
	xor	cx, cx			;AN000;
	mov	dx, cx			;AN000;

;	$SEARCH 			;AN000;
$$DO64:
	    call   Sysinit_Parse	;AN000;
;	$EXITIF    C			;AN000; Parse Error,
	JNC $$IF64
	    call   Badparm_p		;AN007;   and Show messages and end the search loop.
;	$ORELSE 			;AN000;
	JMP SHORT $$SR64
$$IF64:
	    cmp    ax, $P_RC_EOL	;AN000; End of Line?
;	$LEAVE	   E			;AN000;  then end the $ENDLOOP
	JE $$EN64
	    mov    al, byte ptr Result_Val.$P_PICKED_VAL ;AN000;
	    mov    P_Files, al		;AN000; Save it temporarily
;	$ENDLOOP			;AN000;
	JMP SHORT $$DO64
$$EN64:
	    mov    al, P_Files		;AN000;
	    mov    Files, al		;AN000; No error. Really set the value now.
;	$ENDSRCH			;AN000;
$$SR64:
	jmp	Coff

;------------------------------------------------------------------------------
; LastDrive command
;------------------------------------------------------------------------------
;*******************************************************************************
; Function: Parse the parameters of LASTDRIVE= command. 		       *
;									       *
; Input :								       *
;	ES:SI -> parameters in command line.				       *
; Output:								       *
;	Set the variable NUM_CDS.					       *
;									       *
; Subroutines to be called:						       *
;	Sysinit_Parse							       *
; Logic:								       *
; {									       *
;	Set DI points to LDRV_Parms;					       *
;	Set DX,CX to 0; 						       *
;	While (End of command line)					       *
;	{ Sysinit_Parse;						       *
;	  if (no error) then						       *
;	     Set NUM_CDS to the returned value; 			       *
;	  else	/*Error exit*/						       *
;	     Error Exit;						       *
;	};								       *
; };									       *
;									       *
;*******************************************************************************
TRYL:
	CMP	AH,'L'
	JNZ	TRYP

;	 OR	 AL,020h
;	 SUB	 AL,'a'
;	 JB	 TryLBad
;	 INC	 AL
;	 CMP	 AL,26			 ; a-z are allowed
;	 JA	 TryLBad
;	 MOV	 [NUM_CDS],AL
;CoffJ6: JMP	 COFF
;TryLBad:JMP	 BadOp

	mov	di, offset LDRV_Parms	;AN000;
	xor	cx, cx			;AN000;
	mov	dx, cx			;AN000;

;	$SEARCH 			;AN000;
$$DO70:
	    call   Sysinit_Parse	;AN000;
;	$EXITIF    C			;AN000; Parse Error,
	JNC $$IF70
	    call   Badparm_p		;AN007;   and Show messages and end the search loop.
;	$ORELSE 			;AN000;
	JMP SHORT $$SR70
$$IF70:
	    cmp    ax, $P_RC_EOL	;AN000; End of Line?
;	$LEAVE	   E			;AN000;  then end the $ENDLOOP
	JE $$EN70
	    mov    al, RV_Byte		;AN000; Pick up the drive number
	    mov    P_Ldrv, al		;AN000; Save it temporarily
;	$ENDLOOP			;AN000;
	JMP SHORT $$DO70
$$EN70:
	    mov    al, P_Ldrv		;AN000;
;	    sub    al, 'A'		;AN000; Convert it to drive number
;	    inc    al			;AN000; make it to be a number of drives.
	    mov    Num_CDS, al		;AN000; No error. Really set the value now.
;	$ENDSRCH			;AN000;
$$SR70:
	jmp	Coff


;-------------------------------------------------------------------------------
; Setting Drive Parameters
;-------------------------------------------------------------------------------
TRYP:
	CMP	AH,'P'
	JNZ	TRYK
	invoke	PARSELINE
	JC	TryPBad
	invoke	SETPARMS
	INVOKE	DIDDLEBACK
	jc	TryPBad
	JMP	COFF
TryPBad:jmp	Badop
;-------------------------------------------------------------------------------
; Setting Internal Stack Parameters
; STACKS=M,N where
;	M is the number of stacks (range 8 to 64, default 9)
;	N is the stack size (range 32 to 512 bytes, default 128)
; J.K. 5/5/86: STACKS=0,0 implies no stack installation.
;	Any combinations that are not within the specified limits will
;	result in "Unrecognized command" error.
;-------------------------------------------------------------------------------
;*******************************************************************************
;									       *
; Function: Parse the parameters of STACKS= command.			       *
;	    The minimum value for "number of stacks" and "stack size" is       *
;	    8 and 32 each.  In the definition of SYSPARSE value list, they     *
;	    are set to 0.  This is for accepting the exceptional case of       *
;	    STACKS=0,0 case (,which means do not install the stack.)	       *
;	    So, after SYSPARSE is done, we have to check if the entered        *
;	    values (STACK_COUNT, STACK_SIZE) are within the actual range,      *
;	    (or if "0,0" pair has been entered.)			       *
; Input :								       *
;	ES:SI -> parameters in command line.				       *
; Output:								       *
;	Set the variables STACK_COUNT, STACK_SIZE.			       *
;									       *
; Subroutines to be called:						       *
;	Sysinit_Parse							       *
; Logic:								       *
; {									       *
;	Set DI points to STKS_Parms;					       *
;	Set DX,CX to 0; 						       *
;	While (End of command line)					       *
;	{ Sysinit_Parse;						       *
;	  if (no error) then						       *
;	     { if (CX == 1) then /* first positional = stack count */	       *
;		   P_Stack_Count = Result_Val.$P_Picked_Val;		       *
;	       if (CX == 2) then /* second positional = stack size */	       *
;		   P_Stack_Size = Result_Val.$P_Picked_Val;		       *
;	     }								       *
;	  else	/*Error exit*/						       *
;	     Error Exit;						       *
;	};								       *
;	Here check P_STACK_COUNT,P_STACK_SIZE if it meets the condition;       *
;	If O.K., then set Stack_Count, Stack_Size;			       *
;	 else Error_Exit;						       *
; };									       *
;*******************************************************************************
TRYK:
	CMP	AH,'K'
	JE	Do_TryK
	jmp	TRYS

		IF	STACKSW

;	 MOV	 SepChr,','
;	 INVOKE  GetNum 		 ; Get number of stacks
;	 MOV	 SepChr,0
;	 cmp	 ax, 0			 ;J.K. 5/5/86
;	 je	 TRYK_0 		 ;J.K. Let's accept 0.
;	 CMP	 AX, MinCount		 ; 8 <= Number of Stacks <= 64
;	 JB	 TryKBad
;	 CMP	 AX, MaxCount
;	 JA	 TryKBad
;TRYK_0:
;	 MOV	 [STACK_COUNT], AX
;
; Skip delimiters after the first number.
;
;	 invoke  Skip_delim		 ;J.K.
;	 JC	 TryKBad
;
;	 INVOKE  GetNum 		 ; Get size of individual stack
;	 JC	 TryKBad		 ; Number bad
;
;	 cmp	 ax, 0			 ;J.K. 5/5/86
;	 je	 TRYK_SIZE0		 ;J.K. 5/5/86. Accept 0
;
;	 CMP	 AX, MinSize		 ; 32 <= Stack Size <= 512
;	 JB	 TryKBad
;	 CMP	 AX, MaxSize
;	 JA	 TryKBad
;TRYK_SIZE0:
;	 MOV	 [STACK_SIZE], AX
;	 cmp	 ax,0
;	 je	 TRYK_BOTH0
;TRYK_OK:
;	 mov	 word ptr [stack_addr], -1 ;set the flag that the user entered stacks= command.
;	JMP	COFF
;TRYK_BOTH0:
;	 cmp	 [STACK_COUNT],0	 ;stack_size = 0. Stack_Count = 0 too?
;	 je	 TRYK_OK		 ;yes. accepted.
;TryKBad:
;	 MOV	 DX, OFFSET BADSTACK	 ;J.K. 5/26/86 "Invalid stack parameter"
;	 invoke  PRINT
;	 JMP	 COFF

Do_TryK:
	mov	di, offset STKS_Parms	;AN000;
	xor	cx, cx			;AN000;
	mov	dx, cx			;AN000;

;	$SEARCH 			;AN000;
$$DO76:
	    call   Sysinit_Parse	;AN000;
;	$EXITIF    C			;AN000; Parse Error,
	JNC $$IF76
	    mov    dx, offset BadStack	;AN000; "Invalid stack parameter"
	    call   Print		;AN000;   and Show messages and end the search loop.
	    call   Error_Line		;AN006;
;	$ORELSE 			;AN000;
	JMP SHORT $$SR76
$$IF76:
	    cmp    ax, $P_RC_EOL	;AN000; End of Line?
;	$LEAVE	   E			;AN000;  then end the $ENDLOOP
	JE $$EN76
	    mov    ax, word ptr Result_Val.$P_PICKED_VAL   ;AN000;
	    cmp    cx, 1				   ;AN000;
;	    $IF    E					   ;AN000;
	    JNE $$IF80
		 mov   P_Stack_Count, ax		   ;AN000;
;	    $ELSE					   ;AN000;
	    JMP SHORT $$EN80
$$IF80:
		 mov   P_Stack_Size, ax 		   ;AN000;
;	    $ENDIF					   ;AN000;
$$EN80:
;	$ENDLOOP					   ;AN000;
	JMP SHORT $$DO76
$$EN76:
	    cmp    P_Stack_Count, 0			   ;AN000;
;	    $IF    NE					   ;AN000;
	    JE $$IF84
		 cmp	P_Stack_Count, MINCOUNT 	   ;AN000;
;		 $IF	B,OR				   ;AN000;
		 JB $$LL85
		 cmp	P_Stack_Size, MINSIZE		   ;AN000;
;		 $IF	B				   ;AN000;
		 JNB $$IF85
$$LL85:
			mov  P_Stack_Count, -1		   ;AN000; Invalid
;		 $ENDIF 				   ;AN000;
$$IF85:
;	    $ELSE					   ;AN000;
	    JMP SHORT $$EN84
$$IF84:
		 cmp	P_Stack_Size, 0 		   ;AN000;
;		 $IF	NE				   ;AN000;
		 JE $$IF88
			mov  P_Stack_Count, -1		   ;AN000; Invalid
;		 $ENDIF 				   ;AN000;
$$IF88:
;	    $ENDIF					   ;AN000;
$$EN84:
	    cmp  P_Stack_Count, -1			   ;AN000; Invalid?
;	    $IF  E					   ;AN000;
	    JNE $$IF91
		 mov	Stack_Count, DEFAULTCOUNT	   ;AN000;Reset to default value.
		 mov	Stack_Size, DEFAULTSIZE 	   ;AN000;
		 mov	word ptr STACK_ADDR, 0		   ;AN000;
		 mov	dx, offset BadStack		   ;AN000;
		 call	Print				   ;AN000;
		 call	Error_Line			   ;AN006;
;	    $ELSE					   ;AN000;
	    JMP SHORT $$EN91
$$IF91:
		 mov	ax, P_Stack_Count		   ;AN000;
		 mov	Stack_Count, ax 		   ;AN000;
		 mov	ax, P_Stack_Size		   ;AN000;
		 mov	Stack_Size, ax			   ;AN000;
		 mov	word ptr Stack_Addr, -1 	   ;AN000;STACKS= been accepted.
;	    $ENDIF					   ;AN000;
$$EN91:
;	$ENDSRCH					   ;AN000;
$$SR76:
	jmp	Coff
		ENDIF
;------------------------------------------------------------------------------
; Switch command		;No longer supported.
;------------------------------------------------------------------------------
;TRYW:
;	 CMP	 AH,'W'
;	 JNZ	 TRYA
;	 JMP	 BadOp			 ; no longer implemented
;	MOV	DL,AL
;	MOV	AX,(CHAR_OPER SHL 8) OR 1      ;SET SWITCH CHARACTER
;	MOV	[COMMAND_LINE+1],DL
;	INT	21H
;	JMP	COFF
;------------------------------------------------------------------------------
; Availdev command		;No longer supported.
;------------------------------------------------------------------------------
;TRYA:
;	 CMP	 AH,'A'
;	 JNZ	 TRYS
;	 JMP	 BadOp			 ; NO LONGER IMPLEMENTED
;	CMP	AL,'F'			;FIRST LETTER OF "FALSE"
;	JNZ	COFFJ7
;	MOV	AX,(CHAR_OPER SHL 8) OR 3 ;TURN ON "/DEV" PREFIX
;	XOR	DL,DL
;	INT	21H
;COFFJ7: JMP	 COFF

;------------------------------------------------------------------------------
; shell command
;------------------------------------------------------------------------------
TRYS:
	CMP	AH,'S'
	JNZ	TRYX
	MOV	[COMMAND_LINE+1],0
	MOV	DI,OFFSET COMMND + 1
	MOV	[DI-1],AL
STORESHELL:
	CALL	GETCHR
	OR	AL,AL
	JZ	GETSHPARMS
	CMP	AL," "
	JB	ENDSH
	MOV	[DI],AL
	INC	DI
	JMP	STORESHELL

ENDSH:
	MOV	BYTE PTR [DI],0
	CALL	GETCHR
	CMP	AL,LF
	JNZ	CONV
	CALL	GETCHR
CONV:	JMP	CONFLP

GETSHPARMS:
	MOV	BYTE PTR [DI],0
	MOV	DI,OFFSET COMMAND_LINE+1
PARMLOOP:
	CALL	GETCHR
	CMP	AL," "
	JB	ENDSH
	MOV	[DI],AL
	INC	DI
	JMP	PARMLOOP

;------------------------------------------------------------------------------
; FCBS Command
;------------------------------------------------------------------------------
;*******************************************************************************
; Function: Parse the parameters of FCBS= command.			       *
;									       *
; Input :								       *
;	ES:SI -> parameters in command line.				       *
; Output:								       *
;	Set the variables FCBS, KEEP.					       *
;									       *
; Subroutines to be called:						       *
;	Sysinit_Parse							       *
; Logic:								       *
; {									       *
;	Set DI points to FCBS_Parms;					       *
;	Set DX,CX to 0; 						       *
;	While (End of command line)					       *
;	{ SYSPARSE;							       *
;	  if (no error) then						       *
;	     { if (CX == 1) then /* first positional = FCBS */		       *
;		   FCBS = Result_Val.$P_Picked_Val;			       *
;	       if (CX == 2) then /* second positional = KEEP */ 	       *
;		   KEEP = Result_Val.$P_Picked_Val;			       *
;	     }								       *
;	  else	/*Error exit*/						       *
;	     Error Exit;						       *
;	};								       *
; };									       *
;*******************************************************************************
TRYX:
	CMP	AH,'X'
	JNZ	TRYY
;	 invoke  GETNUM
;	 JZ	 TryXBad		 ; gotta have at least one
;	 CMP	 AX,256
;	 JAE	 TryXBad		 ; Can't be more than 8 bits worth
;	 MOV	 [FCBS],AL
;
; Skip delimiters after the first number including ","
;
;	 invoke  Skip_delim		 ;J.K.
;	 jc	 tryxbad
;	 invoke  GetNum
;	 JC	 TryXBad		 ; Number bad (Zero is OK here)
;	 CMP	 AX,256
;	 JAE	 TryXBad
;	 CMP	 AL,FCBS
;	 JA	 TryXBad
;	 MOV	 Keep,AL
;	 JMP	 COFF
;TryXBad:JMP	 BadOp

	mov	di, offset FCBS_Parms	;AN000;
	xor	cx, cx			;AN000;
	mov	dx, cx			;AN000;

;	$SEARCH 			;AN000;
$$DO95:
	    call   Sysinit_Parse	;AN000;
;	$EXITIF    C			;AN000; Parse Error,
	JNC $$IF95
	    call   Badparm_p		;AN007;   and Show messages and end the search loop.
;	$ORELSE 			;AN000;
	JMP SHORT $$SR95
$$IF95:
	    cmp    ax, $P_RC_EOL	;AN000; End of Line?
;	$LEAVE	   E			;AN000;  then end the $ENDLOOP
	JE $$EN95
	    mov    al, byte ptr Result_Val.$P_PICKED_VAL  ;AN000;
	    cmp    cx, 1		;AN000; The first positional?
;	    $IF    E			;AN000;
	    JNE $$IF99
		mov   P_Fcbs, al	;AN000;
;	    $ELSE			;AN000;
	    JMP SHORT $$EN99
$$IF99:
		mov   P_Keep, al	;AN000;
;	    $ENDIF			;AN000;
$$EN99:
;	$ENDLOOP			;AN000;
	JMP SHORT $$DO95
$$EN95:
	    mov    al, P_Fcbs		;AN005;make sure P_Fcbs >= P_Keep
	    cmp    al, P_Keep		;AN005;
;	    $IF    B			;AN005;
	    JNB $$IF103
;		 call  Badop_p		 ;AN005;
		call  Badparm_p 	;AN011;show "Bad parameter -" msg.
		mov   P_Keep, 0 	;AN005;
;	    $ELSE			;AN005;
	    JMP SHORT $$EN103
$$IF103:
		mov    Fcbs, al 	    ;AN000; No error. Really set the value now.
		mov    al, P_Keep	    ;AN000;
		mov    Keep, al 	    ;AN000;
;	    $ENDIF			;AN005;
$$EN103:
;	$ENDSRCH			;AN000;
$$SR95:
	jmp	Coff

;------------------------------------------------------------------------------
; Comment= Do nothing. Just decrese CHRPTR, and increase COUNT for correct
;		line number
;------------------------------------------------------------------------------
TRYY:					;AN000;
	cmp	ah, 'Y' 		;AN000;
	jne	Try0			;AN000;
DoNothing:
	dec	CHRPTR			;AN000;
	inc	COUNT			;AN000;
	jmp	COFF			;AN000;

;------------------------------------------------------------------------------
; REM command
;------------------------------------------------------------------------------
Try0:					;AN003;do nothing with this line.
	cmp	ah, '0' 		;AN003;
	je	DoNothing		;AN003;

;------------------------------------------------------------------------------
; SWITCHES command
;------------------------------------------------------------------------------
;*******************************************************************************
;									       *
; Function: Parse the option switches specified.			       *
; Note - This command is intended for the future use also.  When we need to    *
; to set system data flag, use this command.				       *
;									       *
; Input :								       *
;	ES:SI -> parameters in command line.				       *
; Output:								       *
;	P_Swit_K set if /K option chosen.				       *
;									       *
; Subroutines to be called:						       *
;	Sysinit_Parse							       *
; Logic:								       *
; {									       *
;	Set DI points to Swit_Parms;  /*Parse control definition*/	       *
;	Set DX,CX to 0; 						       *
;	While (End of command line)					       *
;	{ Sysinit_parse;						       *
;	  if (no error) then						       *
;	       if (Result_Val.$P_SYNONYM_ptr == Swit_K) then		       *
;		    P_Swit_K = 1					       *
;	       endif							       *
;	  else {Show Error message;Error Exit}				       *
;	};								       *
; };									       *
;									       *
;*******************************************************************************

	cmp	ah, '1' 		;AN019;Switches= command entered?
	jne	Tryz			;AN019;

	mov	di, offset Swit_Parms	;AN019;
	xor	cx, cx			;AN019;
	mov	dx, cx			;AN019;

;	$SEARCH 			;AN019;
$$DO107:
	    call   Sysinit_Parse	;AN019;
;	$EXITIF    C			;AN019; Parse Error,
	JNC $$IF107
	    call   Badparm_p		;AN019;   and Show messages and end the search loop.
;	$ORELSE 			;AN019;
	JMP SHORT $$SR107
$$IF107:
	    cmp    ax, $P_RC_EOL	;AN019; End of Line?
;	$LEAVE	   E			;AN019;  then jmp to $Endloop for semantic check.
	JE $$EN107
	    cmp    Result_Val.$P_SYNONYM_PTR, offset Swit_K   ;AN019;
;	    $IF    E					      ;AN019;
	    JNE $$IF111
		mov	P_Swit_K, 1			      ;AN019; set the flag
;	    $ENDIF					      ;AN019;
$$IF111:
;	$ENDLOOP			;AN019;
	JMP SHORT $$DO107
$$EN107:
	    cmp    P_Swit_K, 1		;AN019;If /K entered,
	    push   ds			;AN019;
	    mov    ax, Code		;AN019;
	    mov    ds, ax		;AN019;
	    assume ds:Code		;AN019;
;	    $IF    E			;AN019;
	    JNE $$IF114
	       mov    KEYRD_Func, 0	;AN019;Use the conventional keyboard functions
	       mov    KEYSTS_Func, 1	;AN019;
;	    $ENDIF			;AN019;
$$IF114:
	    pop    ds			;AN019;
	    assume ds:SYSINITSEG	;AN019;
;	$ENDSRCH			;AN019;
$$SR107:
	jmp	Coff			;AN019;

;------------------------------------------------------------------------------
; Bogus command
;------------------------------------------------------------------------------
TRYZ:
	cmp	ah, 0FFh		;AN029;
	je	TryFF			;AN029;
	dec	CHRPTR
	inc	COUNT
	JMP	BADOP

;------------------------------------------------------------------------------
; Null command
;------------------------------------------------------------------------------
TryFF:					;AN029;Skip this command.
	jmp	DoNothing		;AN029;

GETCHR:
	PUSH	CX
	MOV	CX,COUNT
	JCXZ	NOCHAR
	MOV	SI,CHRPTR
	MOV	AL,ES:[SI]
	DEC	COUNT
	INC	CHRPTR
	CLC
GET_RET:
	POP	CX
	return
NOCHAR: STC
	JMP	SHORT GET_RET

Incorrect_Order proc	near		;AN000;
;Show "Incorrect order in CONFIG.SYS ..." message.
	mov	dx, offset BADORDER	;AN000;
	call	print			;AN000;
	call	ShowLineNum		;AN000;
	ret				;AN000;
Incorrect_Order endp			;AN000;
;
	public	Error_Line
Error_Line	proc	near		;AN000;
;Show "Error in CONFIG.SYS ..." message.
	push	cs			;AN000;
	pop	ds			;AN000;
	mov	dx, offset ErrorCmd	;AN000;
	call	print			;AN000;
	call	ShowLineNum		;AN000;
	ret				;AN000;
Error_Line	endp			;AN000;
;
ShowLineNum	proc	near		;AN000;
;J.K. Convert the binary LineCount to Decimal ASCII string in ShowCount
;and Display Showcount at the current curser position.
;In.) LineCount
;
;Out) the number is printed.
	push	es			;AN000;
	push	ds			;AN000;
	push	di			;AN000;

	push	cs			;AN000;
	pop	es			;AN000; es=cs
	push	cs			;AN000;
	pop	ds			;AN000;

;	 mov	 ax, '  '
;	 mov	 di, offset ShowCount	 ;clean it up.
;	 stosw
;	 stosw
;	 stosb				 ;lenght of ShowCount is 5.
;	 dec	 di			 ;let DI points to the least significant ASCII field.

	mov	di, offset ShowCount+4	;AN000; DI -> the least significant decimal field.
	mov	cx, 10			;AN000; decimal devide factor
	mov	ax, cs:LineCount	;AN000;
SLN_Loop:				;AN000;
	cmp	ax, 10			;AN000; < 10?
	jb	SLN_Last		;AN000;
	xor	dx,dx			;AN000;
	div	cx			;AN000;
	or	dl, 30h 		;AN000; add "0" (= 30h) to make it an ascii.
	mov	[di],dl 		;AN000;
	dec	di			;AN000;
	jmp	SLN_Loop		;AN000;
SLN_Last:				;AN000;
	or	al, 30h 		;AN000;
	mov	[di],al 		;AN000;
	mov	dx, di			;AN000;
	call	print			;AN000; show it.
	pop	di			;AN000;
	pop	ds			;AN000;
	pop	es			;AN000;
	ret				;AN000;
ShowLineNum	endp			;AN000;


CallIFS proc	near			;AN000;
;*******************************************************************************
; Function: Interface to IFS call. This procedure will call IFS_CALL@	       *
;									       *
; Input :								       *
;	    Entry_Point - Segment:Offset of loaded IFS. 		       *
;	    BX = IFS_CALL@ (offset of IFS_CALL@ from the IFS header)	       *
;	    ES = Segment of IFS request header				       *
;	    IFS_Packet - IFS Request packet				       *
;									       *
; Output:   Nothing							       *
;*******************************************************************************
	push	ax				;AN000;
	mov	ds, word ptr cs:[Entry_Point+2] ;AN000;
	add	bx, word ptr cs:[Entry_Point]	;AN000; DS:[BX] = Real IFS_CALL@ addr.
	mov	ax, ds:[bx]			;AN000; save it
	push	word ptr cs:[Entry_Point]	;AN000; save Entry point offset
	mov	word ptr cs:[Entry_Point], ax	;AN000; set for the call
	mov	bx, offset IFS_RH		;AN000; Now, ES:BX -> Request packet
	call	cs:[Entry_Point]		;AN000; Far call
	pop	word ptr cs:[Entry_Point]	;AN000; Restore Entry point offset
	pop	ax				;AN000;
	ret					;AN000;
CallIFS endp					;AN000;


Set_DevMark	proc	near			;AN004;
;*******************************************************************************
; Function: Set a paragraph of informations infront of a Device file or        *
;	    an IFS file to be loaded for MEM command.			       *
;	    The structure is:						       *
;	      DEVMARK_ID	byte "D" for device, "I" for IFS	       *
;	      DEVMARK_SIZE	size in para for the device loaded	       *
;	      DEVMARK_FILENAME	11 bytes. Filename			       *
;									       *
; Input :								       *
;	    [MEMHI] = address to set up DEVMARK.			       *
;	    [MEMLO] = 0 						       *
;	    ES:SI -> pointer to [drive][path]filename,0 		       *
;	    [IFS_Flag] = IS_IFS bit set if IFS= command.		       *
;									       *
; Output:   DEVMARK_ID, DEVMARK_FILENAME set				       *
;	    cs:[DevMark_addr] set.					       *
;	    AX, CX register destroyed.					       *
;*******************************************************************************
	push	ds			;AN004;
	push	si			;AN004;
	push	es			;AN004;
	push	di			;AN004;

	mov	di, cs:[MEMHI]		;AN004;
	mov	ds, di			;AN004;
	assume	ds:nothing		;AN004;
	mov	[DevMark_Addr], di	;AN004; save the DEVMARK address for the future.
	test	[IFS_Flag], IS_IFS	;AN004;
	jnz	SDVMK_IFS		;AN004;
	mov	al, DEVMARK_DEVICE	;AN004; ='D'
	jmp	short SDVMK_ID		;AN004;
SDVMK_IFS:
	mov	al, DEVMARK_IFS 	;AN004; ='I'
SDVMK_ID:				;AN004;
	mov	ds:[DEVMARK_ID], al	;AN004;
	inc	di			;AN008;
	mov	ds:[DEVMARK_SEG], di	;AN008;
	xor	al,al			;AN004;
	push	si			;AN004;
	pop	di			;AN004; now es:si = es:di = [path]filename,0
	mov	cx, 128 		;AN004; Maximum 128 char
	repnz	scasb			;AN004; find 0
	dec	di			;AN020; Now es:di-> 0
SDVMK_Backward: 			;AN004; find the pointer to the start of the filename.
	mov	al, byte ptr es:[di]	;AN004;;AN020;We do this by check es:di backward until
	cmp	al, '\' 		;AN004;;AN020; DI = SI or DI -> '\' or DI -> ':'.
	je	SDVMK_GotFile		;AN004;;AN020;
	cmp	al, ':' 		;AN004;
	je	SDVMK_GotFile		;AN004;
	cmp	di, si			;AN004;
	je	SDVMK_FilePtr		;AN004;
	dec	di			;AN004;
	jmp	SDVMK_BackWard		;AN004;
SDVMK_GotFile:				;AN004;
	inc	di			;AN004;
SDVMK_FilePtr:				;AN004; now es:di -> start of file name
	push	di			;AN004;
	pop	si			;AN004; save di to si.
	push	ds			;AN004; switch es, ds
	push	es			;AN004;
	pop	ds			;AN004;
	pop	es			;AN004; now, ds:si -> start of filename
	mov	di, DEVMARK_FILENAME	;AN004;
	push	di			;AN004;
	mov	al, ' ' 		;AN004;
	mov	cx, 8			;AN004;
	rep	stosb			;AN004; Clean up Memory.
	pop	di			;AN004;
	mov	cx, 8			;AN004; Max 8 char. only
SDVMK_Loop:				;AN004;
	lodsb				;AN004;
	cmp	al, '.' 		;AN004;
	je	SDVMK_Done		;AN004;
	cmp	al, 0			;AN004;
	je	SDVMK_Done		;AN004;
	stosb				;AN004;
	loop	SDVMK_Loop		;AN004;
SDVMK_Done:				;AN004;
	pop	di			;AN004;
	pop	es			;AN004;
	pop	si			;AN004;
	pop	ds			;AN004;
	ret				;AN004;
Set_DevMark	endp			;AN004;

Chk_XMAEM	proc	near		;AN029;
;Function: Check XMAEM.SYS file name.
;In: ES:SI -> path, filename, 0
;out: if XMAEM.SYS, then zero flag set.

	push	es			;AN029;
	push	si			;AN029;
	push	ds			;AN029;
	push	di			;AN029;
	push	cx			;AN029;
	mov	di, si			;AN029;save current starting pointer
CX_Cmp: 				;AN029;
	cmp	byte ptr es:[si], 0	;AN029;
	je	CX_Endfile		;AN029;
	inc	si			;AN029;
	jmp	CX_Cmp			;AN029;
CX_Endfile:				;AN029;
	dec	si			;AN029;
	cmp	byte ptr es:[si], '\'	;AN029;
	je	CX_Got_Tail		;AN029;
	cmp	byte ptr es:[si], ':'	;AN029;
	je	CX_Got_Tail		;AN029;
	cmp	di, si			;AN029;
	je	CX_Got_Tail0		;AN029;
	jmp	CX_Endfile		;AN029;
CX_Got_Tail:				;AN029;
	inc	si			;AN029;
CX_Got_Tail0:				;AN029;
	push	cs			;AN029;
	pop	ds			;AN029;
	push	si			;AN029;
	pop	di			;AN029;now es:di -> filename,0
	mov	cx, 9			;AN029;
	mov	si, offset XMAEM_File	;AN029;ds:si -> XMAEM.SYS,0
	repe	cmpsb			;AN029;
CX_Ret: 				;AN029;
	pop	cx			;AN029;
	pop	di			;AN029;
	pop	ds			;AN029;
	pop	si			;AN029;
	pop	es			;AN029;
	ret				;AN029;
Chk_XMAEM	endp

;Chk_IBMCACHE	 proc	 near		 ;AN024;AN026; Don't need this any more.
					 ; IBMDOS is going to handle this through 4Bh call.
;Function: IBMCACHE.SYS does not handle a DOS version 4.0 or above.
;	   So, this procedure will check if the device driver is IBMCACHE.SYS.
;	   If it is, through new INT 2fh interface "Set/Restore DOS version"
;		AX=122Fh
;		DX= 0 ; reset
;		    otherwise ; DH = minor version, DL = major version
;		INT 2fh
;In: ES:SI -> path, filename, 0
;out: if IBMCACHE.SYS, then DOS version changed to 4.00 temporarily.
;     Reset_Dos_Version proc will later reset it back to current DOS version 4.0.

;	 push	 es			 ;AN024;
;	 push	 si			 ;AN024;
;	 push	 ds			 ;AN024;
;	 push	 di			 ;AN024;
;	 push	 cx			 ;AN024;
;	 mov	 di, si 		 ;AN024;save current starting pointer
;CIC_Cmp:				 ;AN024;
;	 cmp	 byte ptr es:[si], 0	 ;AN024;
;	 je	 CIC_Endfile		 ;AN024;
;	 inc	 si			 ;AN024;
;	 jmp	 CIC_Cmp		 ;AN024;
;CIC_Endfile:				 ;AN024;
;	 dec	 si			 ;AN024;
;	 cmp	 byte ptr es:[si], '\'	 ;AN024;
;	 je	 CIC_Got_Tail		 ;AN024;
;	 cmp	 byte ptr es:[si], ':'	 ;AN024;
;	 je	 CIC_Got_Tail		 ;AN024;
;	 cmp	 di, si 		 ;AN024;
;	 je	 CIC_Got_Tail0		 ;AN024;
;	 jmp	 CIC_Endfile		 ;AN024;
;CIC_Got_Tail:				 ;AN024;
;	 inc	 si			 ;AN024;
;CIC_Got_Tail0: 			 ;AN024;
;	 push	 cs			 ;AN024;
;	 pop	 ds			 ;AN024;
;	 push	 si			 ;AN024;
;	 pop	 di			 ;AN024;now es:di -> filename,0
;	 mov	 cx, 12 		 ;AN024;
;	 mov	 si, offset IBMCACHE_File ;AN024;ds:si -> IBMCACHE.SYS,0
;	 repe	 cmpsb			 ;AN024;
;	 jnz	 CIC_ret		 ;AN024;
;	 mov	 ax, 122Fh		 ;AN024;Change DOS version to
;	 mov	 dx, 2803h		 ;AN024; DOS 3.4 temporarily.
;	 int	 2fh			 ;AN024;
;CIC_Ret:				 ;AN024;
;	 pop	 cx			 ;AN024;
;	 pop	 di			 ;AN024;
;	 pop	 ds			 ;AN024;
;	 pop	 si			 ;AN024;
;	 pop	 es			 ;AN024;
;	 ret				 ;AN024;
;Chk_IBMCACHE	 endp
;

Reset_DOS_Version	proc	near	;AN024;
;Function: issue AX=122Fh, DX=0, INT 2fh to restore the DOS version.
	push	ax			;AN024;
	push	dx			;AN024;
	mov	ax, 122Fh		;AN024;
	mov	dx, 0			;AN024;
	int	2fh			;AN024;
	pop	dx			;AN024;
	pop	ax			;AN024;
	ret				;AN024;
Reset_DOS_Version	endp


;Int 2F EMS handler + Int 67h handler for EMS
;=========================================================================
; Int_2F_EMS		- This routine provides support for VDISK,
;			  FASTOPEN, and BUFFERS to determine the physical
;			  EMS pages available for their usage.
;
;	Inputs	: AH - Function code (18h) to return available phys. page
;		  DI - FEh (Signals to return useable page for VDISK & FASTOPEN)
;		       FFh (Signals to return useable page for BUFFERS)
;
;		  AL = 0 is for installation check. - J.K.
;
;	Outputs : ES - Segment value for physical page
;		  DI - Physical Page number
;		  AH - Non-zero (physical page not available)
;		       Zero (valid physical page data returned)
;
;		  For installation check, AL = 0FFh for being present. - J.K.
;		  For the other functions, AX = 0 for successful op.
;					   AX = -1 for an error.
;
;	Date	: 5/5/88
;	Release : DOS 4.0
;=========================================================================

;Int_2F_Handler  proc			 ;traps Int_2f and checks for EMS	 ;an000; dms;

EMS_STUB_START label byte		;AN030;J.K.
;Dummy DEVICE HEADER for other dummy	;AN031; Symphony assumes int 67h handler seg as a device driver!
	DD	-1			;AN031;becomes pointer to next device header
	DW	0C040H			;AN031;attribute (character device)
	DW	0000			;AN031;pointer to harzard area. System will hang.
	DW	0000			;AN031;pointer to harzard area. System will hang.
	DB	'EMMXXXX0'		;AN031;device name

INTV2F	equ $-EMS_STUB_START		;AN030;J.K.pointer to old 2Fh handler		  ;an000; dms;
IntV2FO DW	?			;AN030;;offset				       ;an000; dms;
IntV2FS DW	?			;AN030;;segment 			       ;an000; dms;

OLDINT67_VECTOR equ $-EMS_STUB_START	;AN030;J.K.
OldInt67	dd	?		;AN030;; save pointer to old INT 67 handler here

IF	BUFFERFLAG

LOCKFLAG	equ $-EMS_STUB_START
LOCK_FLAG	db  ?

ELSE

EMSPAGE_CNT	equ	$-EMS_STUB_START ;AN030;J.K.
EMSPageCount	dw	?		;AN030;; save count of EMS mappable pages here

EMSReservedArray_X label word		;AN030;;J.K. For initialization routine
EMSRESERVEDARRAY equ $-EMS_STUB_START	;AN030;;J.K.
		 dw	0ffffh,0ffffh	;AN030;; array of reserved pages
		 dw	0ffffh,0ffffh	;AN030;; phys_page_segment, phys_page_number * 2 entries
MappableArray_X label  word		;AN030;;J.K. for initialization routine
MAPPABLEARRAY	equ  $-EMS_STUB_START	;AN030;;J.K.
		dw	64 dup (0,0)	;AN030;; table to get addresses from old INT 67 handler

ENDIF
					; 64 entries * 2 words
NEWEMS2F_OFF	equ	$-EMS_STUB_START;AN030;
Int_2F_EMS:				;AN030;;J.K. Name changed.
	cmp	ah,1Bh			;AN030;;AN032;2Fh trap for Mappable Phys. Add. Array ;an000; dms;
	je	Int_2F_EMS_MINE 	;AN030;;This one we want		       ;an000; dms;

	jmp	dword ptr cs:IntV2F	;AN030;;go to old interrupt handler	       ;an000; dms;

Int_2F_EMS_MINE:			;AN030;
	or	al, al			;AN030;;J.K. Installation check?
	jnz	Int_2F_5800_Func	;AN030;;J.K.
	mov	al, 0FFh		;AN030;;J.K. Yes, I am here!
	iret				;AN030;;J.K.

Int_2F_5800_Func:			;AN030;

IF	BUFFERFLAG
;	int	3
	cmp	di, 80h
	jne	st_flag
	mov	byte ptr cs:LOCKFLAG, 0
	jmp	Int_2f_5800_Good_Exit
st_flag:
	cmp	di, 81h
	jne	Int_2f_5800_Err_Exit
	mov	byte ptr cs:LOCKFLAG, 1
	jmp	Int_2f_5800_Good_Exit
ELSE

	push	si			;AN030;;				       ;an000; dms;

;	 mov	 si,offset EMSReservedArray ;point to array containing pages	 ;an000; dms;
	mov	si, EMSRESERVEDARRAY	;AN030;;J.K.

	cmp	di,0feh 		;AN030;;VDISK or FASTOPEN request?	       ;an000; dms;
	jne	Int_2F_5800_Buff_Ck	;AN030;;no - check for buffers		       ;an000; dms;

	cmp	word ptr cs:[si],0ffffh  ;AN030;;valid entry?				;an000; dms;
	je	Int_2F_5800_Err_Exit	;AN030;;no - exit			       ;an000; dms;

	mov	es,word ptr cs:[si]	;AN030;;get segment value		       ;an000; dms;
	mov	di,word ptr cs:[si+2]	;AN030;;get physical page value 	       ;an000; dms;
	jmp	Int_2F_5800_Good_Exit	;AN030;;exit routine			       ;an000; dms;

Int_2F_5800_Buff_Ck:			;AN030;

	cmp	di,0ffh 		;AN030;;BUFFERS request?		       ;an000; dms;
	jne	Int_2F_5800_Err_Exit	;AN030;;no - exit with error		       ;an000; dms;

	add	si,4			;AN030;;point to second element in array       ;an000; dms;

	cmp	word ptr cs:[si],0ffffh  ;AN034;;valid entry?				;an000; dms;
	je	Int_2F_5800_Err_Exit	;AN034;;no - exit			       ;an000; dms;

	mov	es,word ptr cs:[si]	;AN030;;get segment value		       ;an000; dms;
	mov	di,word ptr cs:[si+2]	;AN030;;get physical page value 	       ;an000; dms;

ENDIF

Int_2F_5800_Good_Exit:			;AN030;

	xor	ax,ax			;AN030;;signal good return		       ;an000; dms;
	jmp	Int_2F_Exit		;AN030;;exit routine			       ;an000; dms;

Int_2F_5800_Err_Exit:			;AN030;

	mov	ax,0ffffh		 ;AN030;;signal error				;an000; dms;

Int_2F_Exit:				;AN030;


IF	NOT BUFFERFLAG
	pop	si			;AN030;;restore regs			       ;an000; dms;
ENDIF
	iret				;AN030;;return to caller		       ;an000; dms;



;-------------------------------------------------------------------
;
;	INT 67h Filter
;
;	This routine filters INT 67's looking for AH=58h.  When initialized,
;	the original INT 67 handler is called and the mappable address array
;	is changed to "reserve" two pages for DOS use.	This new array is
;	then returned to the calling program when INT 67 AH=58h is found.
;
;	Information about the two pages "reserved" for DOS is returned
;	via an unpublished INT 2Fh interface.
;
;	5/10/88 for DOS 4.0.
;-------------------------------------------------------------------

IF	NOT BUFFERFLAG

GetMappableArray equ	58h		; INT 67 function code for Get Mappable Array
GetPageFrame	equ	41h		; function code for getting the page frame address
null		equ	0		; zero value
I67Error8F	equ	8fh		;AN031;; invalid sub-function error

ENDIF

;-------------------------------------------------------------------
NEW67_OFFSET	equ	$-EMS_STUB_START	;J.K.
Int67Filter:				;AN030;

IF	BUFFERFLAG
;	int	3
	cmp	byte ptr cs:LOCKFLAG, 1
	jne	PassThru
	mov	ah, 80h
	stc
	iret
ELSE
	cmp	ah,GETMAPPABLEARRAY	;AN030;; is this the INT 67 call we are interested in?
	jne	PassThru		;AN030;; no, pass it to old INT 67 handler
					;AN030;; yes ...
	cmp	al,0			;AN031;; AL=0 return count and table
	je	I67Fcn0

	cmp	al,1			;AN031;; AL=1 return count only
	jne	I67Error		;AN031;; otherwise, error


;	return count of mappable pages

	sti				;AN031;; turn interrupts on

	mov	cx,word ptr cs:EMSPAGE_CNT    ;AN031;J.K. get number of mappable pages in fake table
	xor	ah,ah			;AN031;; good return code
	iret

;	return invalid sub-function code

I67Error:
	sti				;AN031;; turn interrupts on
	mov	ah,I67Error8F		;AN031;; invalid sub-function error
	iret


I67Fcn0:				;AN031

;	copy the fake table to user's buffer

	sti				;AN030;; turn interrupts on

	push	ds			;AN030; save some regs
	push	di			;AN030;
	push	si			;AN030;

	mov	cx,word ptr cs:EMSPAGE_CNT    ;AN030;J.K. get number of mappable pages in fake table
	shl	cx,1			;AN030;; count * 2 = number of words to copy

	push	cs			;AN030;; point DS:SI to fake table
	pop	ds			;AN030;
;	 lea	 si,MappableArray
	mov	si, MAPPABLEARRAY	;AN030;;J.K.

	rep	movsw			;AN030;; copy CX words from DS:SI to ES:DI

	xor	ah,ah			;AN030;; good return code
	mov	cx,word ptr cs:EMSPAGE_CNT ;AN030;; page count returned to user in CX


	pop	si			;AN030;; restore some regs
	pop	di			;AN030;
	pop	ds			;AN030;

	iret				;AN030;; end of INT 67 filter routine

ENDIF

;-------------------------------------------------------------------
;
;	PassThru - send request to old INT 67 handler
;
;-------------------------------------------------------------------

PassThru:
	jmp	dword ptr cs:OldINT67_VECTOR ;AN030;;J.K. jump to old INT 67 handler
					; (IRET will return to calling program)


EMS_STUB_END	label	byte		;AN030;
;-------------------------------------------------------------------

IF	NOT BUFFERFLAG
;-------------------------------------------------------------------
;
;	Int67FilterInit - This routine is called to initialize the INT 67
;	filter. It should be called as soon as possible after installation.
;
;-------------------------------------------------------------------

Int67FilterInit:			;AN030;
	push	es			;AN030;; save caller's ES:DI
	push	di			;AN030;

	push	cs			;AN030;; make ES:DI point to our array
	pop	es			;AN030;
	mov	di,offset MappableArray_X   ;AN030;

;	 call	 dword ptr cs:OldInt67	    ; get mappable array from EMS DD

	mov	ah, GetMappableArray	;AN030;
	xor	al,al			;AN030;
	int 67h 			;AN030;;J.K.


;------------------------
; scan table looking for highest phys_page_number

	xor	ax,ax			;AN030;;

	cmp	cx,0			;AN033;; are the any pages left?
	je	NoMoreEMSPages		;AN033;; no, don't bother looking any more

	call	GetHighestPage		;AN030;; get highest entry from table

	mov	EMSReservedArray_X+4,bx   ;AN030;; phys_page_segment
	mov	EMSReservedArray_X+6,ax   ;AN030;; phys_page_number

	cmp	cx,0			;AN033;; are the any pages left?
	je	NoMoreEMSPages		;AN033;; no, don't bother looking any more

	call	GetHighestPage		;AN030;; get next highest entry from table

	mov	EMSReservedArray_X+0,bx   ;AN030;; phys_page_segment
	mov	EMSReservedArray_X+2,ax   ;AN030;; phys_page_number

NoMoreEMSPages: 			;AN033;;
	mov	EMSPageCount,cx 	;AN030;; save new page count for INT 67 filter

	pop	di
	pop	es
	ret				;AN030;; return to calling program


	page
;-------------------------------------------------------------------
;
;	GetHighestPage - returns highest physical page number in AX
;	and segment for it in BX.  A -1 means no valid page found.
;
;-------------------------------------------------------------------
GetHighestPage:

	xor	ax,ax			;AN030;; zero candidate register
	mov	bx,ax			;AN030;; zero pointer to candidate page

	push	cx			;AN030;; save count
	push	dx			;AN030;
	push	di			;AN030;; save pointer

PageScanLoop:				;AN030;
	cmp	ax,ES:[di+2]		;AN030;; get phys_page_number
	ja	LookAtNextPage		;AN030;; this one is lower than the one we are holding

	cmp	es:[di], 0a000h 	; Only reserve pages in memory above 640K..
	jb	LookAtNextPage		; fix for ps2emm and m20emm with motherboard
					; disabled. 7/25/88. HKN.

	mov	ax,ES:[di+2]		;AN030;; this one is higher, make it new candidate
	mov	bx,di			;AN030;; pointer to new candidate page, used to zero
					; it later so we don't get the same one again
	mov	dx,cx			;AN030;; save count where we found candidate

LookAtNextPage: 			;AN030;
	add	di,4			;AN030;; point to next entry in mappable table

	loop	PageScanLoop		;AN030;; look at next entry

	cmp	bx,null 		;AN030;; did we find any pages?
	jne	FoundOne		;AN030;; yes, exit

	jmp	ReturnError		;AN030;

;------------------------
FoundOne:				;AN030;
	cmp	ax,3			;AN030;; could the one we found be part of a page frame
	ja	NotFrame		;AN030;; no, carry on

;	yes, find out if it is part of frame

	push	ax			;AN030;; save physical page number
	push	bx			;an030;; dms; bx destroyed by call
	mov	ah,GetPageFrame 	;AN030;; function code to get page frame ...
;	 call	 dword ptr cs:OldInt67	    ; ... from the EMS DD
	int	67h			;AN030;;J.K.
	or	ah,ah			;an030;;dms; error?
	pop	bx			;an030;;dms; restore bx
	pop	ax			;AN030;; restore phys page number
	jnz	NotFrame		;AN030;; no frame available, carry on

;	there is a frame, this page is part of frame, so return -1's

ReturnError:				;AN030;
	mov	ax,0ffffh		;AN030;; indicate failure
	mov	bx,ax			;AN030;; ax and bx = -1

	pop	di			;AN030;; restore pointer
	pop	dx
	pop	cx			;AN030;; restore count

	jmp	GHPExit 		;AN030;




;------------------------
;	Found a page, and it is not part of a page frame, so re-pack table
;	and return info.  The entry we "reserve" for DOS must be removed
;	from the table and the other entries moved up to repack the table.
;	The count must be reduced by 1 to reflect this change.

Notframe:				;AN030;

	mov	di,bx			;AN030;; make ES:DI point to highest page table entry

	mov	bx,ES:[di]		;AN030;; get segment address of page

	mov	cx,dx			;AN030;; get count from candidate page

	push ax 			;AN030;
PackLoop:				;AN030;
	mov	ax, es:[di+4]		;AN030;
	mov	es:[di+0], ax		;AN030;
	mov	ax, es:[di+6]		;AN030;
	mov	es:[di+2], ax		;AN030;
	add	di, 4			;AN030;
	loop	PackLoop		;AN030;; do it until done
	pop  ax 			;AN030;

	pop	di			;AN030;; restore pointer
	pop	dx			;AN030;
	pop	cx			;AN030;; restore count

	sub	cx,1			;AN030;; reduce count by one, one less page in table now

GHPExit:				;AN030;

	ret				;AN030;; return to caller

ENDIF

;=========================================================================
; EMS_Install_Check	: THIS MODULE DETERMINES WHETHER OR NOT EMS IS
;			  INSTALLED FOR THIS SESSION.
;
;	INPUTS		: NONE
;
;	OUTPUTS 	: ES:BX - FRAME ARRAY
;			  CY	- EMS NOT AVAILABLE
;			  NC	- EMS AVAILABLE
;
;	Date	: 5/6/88
;=========================================================================

EMS_Install_Check	proc	near	;AN030;; check if EMS is installed	       ;an000; dms;

	push	ax			;AN030;; save regs			       ;an000; dms;

	push	ds			;AN030;; save ds			       ;an000; dms;
	xor	ax,ax			;AN030;; set ax to 0			       ;an000; dms;
	mov	ds,ax			;AN030;; set ds to 0			       ;an000; dms;
	cmp	ds:word ptr[067h*4+0],0 ;AN030;; see if int 67h is there	       ;an000; dms;
	pop	ds			;AN030;; restore ds			       ;an000; dms;
	je	EMS_Install_Ck_Err_Exit ;AN030;; exit routine - EMS not loaded	       ;an000; dms;

	mov	ah,40h			;AN030;; Get Status function		       ;an000; dms;
	xor	al,al			;AN030;; clear al			       ;an000; dms;
	int	67h			;AN030;;				       ;an000; dms;
	or	ah,ah			;AN030;; EMS installed? 		       ;an000; dms;
	jnz	EMS_Install_Ck_Err_Exit ;AN030;; exit routine - EMS not loaded	       ;an000; dms;

	mov	ah,46h			;AN030;; Get Version number		       ;an000; dms;
	xor	al,al			;AN030;; clear al			       ;an000; dms;
	int	67h			;AN030;;				       ;an000; dms;
	cmp	al,40h			;AN030;; Version 4.0?			       ;an000; dms;
	jb	EMS_Install_Ck_Err_Exit ;AN030;; exit routine - wrong EMS loaded       ;an000; dms;

	clc				;AN030;; signal EMS loaded		       ;an000; dms;
	jmp	EMS_Install_Ck_Exit	;AN030;; exit routine			       ;an000; dms;

EMS_Install_Ck_Err_Exit:		;AN030;

	stc				;AN030;; signal EMS not loaded		       ;an000; dms;

EMS_Install_Ck_Exit:			;AN030;

	pop	ax			;AN030;; restore regs			       ;an000; dms;

	ret				;AN030;; return to caller		       ;an000; dms;

EMS_Install_Check	endp		;					;an000; dms;

EMS_Stub_Handler	proc	near	;AN030;
;At the request of Architecture Group, this logic is implemented.
;Function: If (Buffer_Slash_X <> 0 and EMS_Stub_Installed == 0),
;	    then { call Chk_EMS;
;		   if EMS is there, then install EMS_Stub dynamically
;		    and initialize it.}
;      Note: EMS_Stub consists of INT 2fh EMS handler and INT 67h handler.
;	   When EMS_Stub is installed, EMS_Stub_Installed will be set to 1.

	push	es			;AN030;
	push	si			;AN030;
	push	ds			;AN030;
	push	di			;AN030;
	push	ax			;AN030;
	push	cx			;AN030;
	cmp	EMS_Stub_Installed, 0	;AN030;
	je	EMS_Stub_X		;AN030;
	jmp	EMS_SH_Ret		;AN030;
EMS_Stub_X:				;AN030;
	cmp	Buffer_Slash_X, 0	;AN030;
	je     EMS_SH_Ret		;AN030;
	call	EMS_Install_Check	;AN030;
	jc	EMS_SH_Ret		;AN030;
;Install EMS_Stub.			;AN030;
EMS_Stub_Do:
	push	es			;AN030;
	xor	ax,ax			;AN030;save current Int 2fh, 67h vectors.
	mov	es, ax			;AN030;
	mov	ax, word ptr es:[2fh*4] ;AN030;
	mov	IntV2FO, ax		;AN030;
	mov	ax, word ptr es:[2fh*4+2]	;AN030;
	mov	IntV2FS, ax			;AN030;
	mov	ax, word ptr es:[67h*4] 	;AN030;
	mov	word ptr cs:[OldInt67], ax	;AN030;
	mov	ax, word ptr es:[67h*4+2]	;AN030;
	mov	word ptr cs:[OldInt67+2], ax	;AN030;
	pop	es				;AN030;

IF	NOT BUFFERFLAG
;initalize tables in INT 67h handler
	call	Int67FilterInit 		;AN030;
	cmp	ax, 0ffffh			; if the page found was part of a lim 4.0 page frame
	je	EMS_SH_ret			;	do not install stub.  7/24/88. HKN
ENDIF
	call	Round				;AN030;
	mov	ax, DEVMARK_EMS_STUB		;AN030;
	call	SetDevMark			;AN030;
	mov	ax, [memhi]			;AN030;
	mov	es, ax				;AN030;
	assume	es:nothing			;AN030;
	xor	di, di				;AN030;
	push	cs				;AN030;
	pop	ds				;AN030;
	mov	cx, offset EMS_STUB_END 	;AN030;
	mov	si, offset EMS_STUB_START	;AN030;
	sub	cx, si				;AN030;cx = size in byte
	mov	[memlo], cx			;AN030;
	rep	movsb				;AN030;
	or	[SetDevMarkFlag], FOR_DEVMARK	;AN030;set the devmark_size for MEM command.
	call	Round				;AN030;and get the next [memhi] avaiable.
	mov	EMS_Stub_Installed, 1		;AN030;

	xor	ax, ax				;AN030;
	mov	ds, ax				;AN030;
	cli					;AN030;
	mov	word ptr ds:[2Fh*4],NEWEMS2F_OFF;AN030;set the new int 2fh, 67h vectors.
	mov	word ptr ds:[2Fh*4+2], es	;AN030;
	mov	word ptr ds:[67h*4],NEW67_OFFSET;AN030;
	mov	word ptr ds:[67h*4+2], es	;AN030;
	sti					;AN030;
EMS_SH_Ret:					;AN030;
	pop	cx				;AN030;
	pop	ax				;AN030;
	pop	di				;AN030;
	pop	ds				;AN030;
	pop	si				;AN030;
	pop	es				;AN030;
	ret					;AN030;

EMS_Stub_Handler	endp			;AN030;


SYSINITSEG	ENDS
	END
