	PAGE 64,132 ;
;	SCCSID = @(#)driver.asm 4.13 85/10/15
;	SCCSID = @(#)driver.asm 4.13 85/10/15
;
; External block device driver
; Hooks into existing routines in IBMBIO block driver via Int 2F mpx # 8.
; This technique minimizes the size of the driver.
;

; Revised Try_h: to test for flagheads  as msg was being displayed on FormFactor
;  this caused the FormFactor to be set in the Head
; Revised the # of sectors/cluster for F0h to 1
;==============================================================================
;REVISION HISTORY:
;AN000 - New for DOS Version 4.00 - J.K.
;AC000 - Changed for DOS Version 4.00 - J.K.
;AN00x - PTM number for DOS Version 4.00 - J.K.
;==============================================================================
;AN001 - d55 Unable the fixed disk accessibility of DRIVER.SYS.     7/7/87 J.K.
;AN002 - p196 Driver.sys does not signal init. failure		    8/17/87 J.K.
;AN003 - p267 "No driver letter..." message                         8/19/87 J.K.
;AN004 - p268 "Too many parameter..." message                       8/20/87 J.K.
;AN005 - p300 "Bad 1.44MB BPB information..."                       8/20/87 J.K.
;AN006 - p490 Driver should reject identical parms		    8/28/87 J.K.
;AN007 - p921 Parser.ASM problem				    9/18/87 J.K.
;AN008 - d493 New init request structure			    2/25/88 J.K.
;==============================================================================

code segment byte public
assume cs:code,ds:code,es:code

;AN000;
.xlist
include SYSMSG.INC			;equates and macros
.list
MSG_UTILNAME <DRIVER>

iTEST = 0
;---------------------------------------------------
;
;	Device entry point
;
DSKDEV	LABEL	WORD
	DW	-1,-1			; link to next device
	DW	0000100001000000B	; bit 6 indicates DOS 3.20 driver
	DW	STRATEGY
	DW	DSK$IN
DRVMAX	DB	1

;
; Various equates
;
CMDLEN	equ	0			;LENGTH OF THIS COMMAND
UNIT	equ	1			;SUB UNIT SPECIFIER
CMD	equ	2			;COMMAND CODE
STATUS	equ	3			;STATUS
MEDIA	equ	13			;MEDIA DESCRIPTOR
TRANS	equ	14			;TRANSFER ADDRESS
COUNT	equ	18			;COUNT OF BLOCKS OR CHARACTERS
START	equ	20			;FIRST BLOCK TO TRANSFER
EXTRA	equ	22			;Usually a pointer to Vol Id for error 15
CONFIG_ERRMSG  equ     23		;AN009; To set this field to Non-zero
					;	to display "Error in CONFIG.SYS..."

PTRSAV	DD	0


STRATP PROC FAR

STRATEGY:
	MOV	WORD PTR CS:[PTRSAV],BX
	MOV	WORD PTR CS:[PTRSAV+2],ES
	RET

STRATP ENDP

DSK$IN:
	push	es
	push	bx
	push	ax
	les	bx,cs:[ptrsav]
	cmp	byte ptr es:[bx].cmd,0
	jnz	Not_Init
	jmp	DSK$INIT

not_init:
; Because we are passing the call onto the block driver in IBMBIO, we need to
; ensure that the unit number corresponds to the logical (DOS) unit number, as
; opposed to the one that is relevant to this device driver.
	mov	al,byte ptr cs:[DOS_Drive_Letter]
	mov	byte ptr es:[bx].UNIT,al
	mov	ax,0802H
	int	2fH
;
; We need to preserve the flags that are returned by IBMBIO. YUK!!!!!
;
	pushf
	pop	bx
	add	sp,2
	push	bx
	popf

exitp	proc	far
DOS_Exit:
	pop	ax
	POP	BX
	POP	ES
	RET				;RESTORE REGS AND RETURN
EXITP	ENDP

include msbds.inc			; include BDS structures
;include versiona.inc

BDS	DW	-1			;Link to next structure
	DW	-1
	DB	1			;Int 13 Drive Number
	DB	3			;Logical Drive Letter
FDRIVE:
	DW	512			;Physical sector size in bytes
	DB	-1			;Sectors/allocation unit
	DW	1			;Reserved sectors for DOS
	DB	2			;No. allocation tables
	DW	64			;Number directory entries
	DW	9*40			;Number sectors (at 512 bytes ea.)
	DB	00000000B		;Media descriptor, initially 00H.
	DW	2			;Number of FAT sectors
	DW	9			;Sector limit
	DW	1			;Head limit
	DW	0			;Hidden sector count
	dw	0			;AN000; Hidden sector count (High)
	dw	0			;AN000; Number sectors (low)
	dw	0			;AN000; Number sectors (high)
	DB	0			; TRUE => Large fats
OPCNT1	DW	0			;Open Ref. Count
	DB	2			;Form factor
FLAGS1	DW	0020H			;Various flags
	DW	80			;Number of cylinders in device
RecBPB1 DW	512			; default is that of 3.5" disk
	DB	2
	DW	1
	DB	2
	DW	70h
	DW	2*9*80
	DB	0F9H
	DW	3
	DW	9
	DW	2
	DW	0
	dw	0			;AN000;
	dw	0			;AN000;
	dw	0			;AN000;
	db	6 dup (0)		;AC000;
TRACK1	DB	-1			;Last track accessed on this drive
TIM_LO1 DW	-1			;Keep these two contiguous (?)
TIM_HI1 DW	-1
VOLID1	DB	"NO NAME    ",0         ;Volume ID for this disk
VOLSER	dd	0			;AN000;
FILE_ID db	"FAT12   ",0            ;AN000;

DOS_Drive_Letter	db	?	; Logical drive associated with this unit

ENDCODE LABEL WORD			; Everything below this is thrown away
					; after initialisation.

DskDrv	    dw	    offset FDRIVE	; "array" of BPBs

;AN000; For system parser;

FarSW	equ	0	; Near call expected

DateSW	equ	0	; Check date format

TimeSW	equ	0	; Check time format

FileSW	equ	0	; Check file specification

CAPSW	equ	0	; Perform CAPS if specified

CmpxSW	equ	0	; Check complex list

NumSW	equ	1	; Check numeric value

KeySW	equ	0	; Support keywords

SwSW	equ	1	; Support switches

Val1SW	equ	1	; Support value definition 1

Val2SW	equ	1	; Support value definition 2

Val3SW	equ	0	; Support value definition 3

DrvSW	equ	0	; Support drive only format

QusSW	equ	0	; Support quoted string format
;---------------------------------------------------
;.xlist
assume ds:nothing				;AN007;!!!Parse.ASM sometimes assumes DS
						;      to access its own variable!!!
	include PARSE.ASM			;together with PSDATA.INC
assume ds:code					;AN007;
;.list
;Control block definitions for PARSER.
;---------------------------------------------------
Parms	label	byte
	dw	Parmsx		;AN000;
	db	0		;AN000;No extras

Parmsx	label	byte		;AN000;
	db	0,0		;AN000;No positionals
	db	5		;AN000;5 switch control definitions
	dw	D_Control	;AN000;/D
	dw	T_Control	;AN000;/T
	dw	HS_Control	;AN000;/H, /S
	dw	CN_Control	;AN000;/C, /N
	dw	F_Control	;AN000;/F
	db	0		;AN000;no keywords

D_Control	label	word	;AN000;
	dw	8000h		;AN000;numeric value
	dw	0		;AN000;no functions
	dw	Result_Val	;AN000;result buffer
	dw	D_Val		;AN000;value defintions
	db	1		;AN000;# of switch in the following list
Switch_D	label	byte	;AN000;
	db	'/D',0          ;AN000;

D_Val	label	byte		;AN000;
	db	1		;AN000;# of value defintions
	db	1		;AN000;# of ranges
	db	1		;AN000;Tag value when match
;	 dd	 0,255		 ;AN000;
	dd	0,127		;AN001;Do not allow a Fixed disk.

Result_Val	label	byte	;AN000;
	db	?		;AN000;
Item_Tag	label	byte	;AN000;
	db	?		;AN000;
Synonym_ptr	label	word	;AN000;
	dw	?		;AN000;es:offset -> found Synonym
RV_Byte 	label	byte	;AN000;
RV_Word 	label	word	;AN000;
RV_Dword	label	dword	;AN000;
	dd	?		;AN000;value if number, or seg:off to string

T_Control	label	word	;AN000;
	dw	8000h		;AN000;numeric value
	dw	0		;AN000;no functions
	dw	Result_Val	;AN000;result buffer
	dw	T_Val		;AN000;value defintions
	db	1		;AN000;# of switch in the following list
Switch_T	label	byte	;AN000;
	db	'/T',0          ;AN000;

T_Val	label	byte		;AN000;
	db	1		;AN000;# of value defintions
	db	1		;AN000;# of ranges
	db	1		;AN000;Tag value when match
	dd	1,999		;AN000;

HS_Control	label	word	;AN000;
	dw	8000h		;AN000;numeric value
	dw	0		;AN000;no function flag
	dw	Result_Val	;AN000;Result_buffer
	dw	HS_VAL		;AN000;value definition
	db	2		;AN000;# of switch in following list
Switch_H	label	byte	;AN000;
	db	'/H',0          ;AN000;
Switch_S	label	byte	;AN000;
	db	'/S',0          ;AN000;

HS_Val	 label	 byte		;AN000;
	db	1		;AN000;# of value defintions
	db	1		;AN000;# of ranges
	db	1		;AN000;Tag value when match
	dd	1,99		;AN000;

CN_Control	 label	 word	;AN000;
	dw	0		;AN000;no match flags
	dw	0		;AN000;no function flag
	dw	Result_Val	;AN000;no values returned
	dw	NoVal		;AN000;no value definition
;	 db	 2		 ;AN000;# of switch in following list
	db	1		;AN001;
Switch_C	label	byte	;AN000;
	db	'/C',0          ;AN000;
;Switch_N	 label	 byte	 ;AN000;
;	 db	 '/N',0          ;AN000;

Noval	db	0		;AN000;

F_Control	label	word	;AN000;
	dw	8000h		;AN000;numeric value
	dw	0		;AN000;no function flag
	dw	Result_Val	;AN000;Result_buffer
	dw	F_VAL		;AN000;value definition
	db	1		;AN000;# of switch in following list
Switch_F	label	byte	;AN000;
	db	'/F',0          ;AN000;

F_Val		label	byte	;AN000;
	db	2		;AN000;# of value definitions (Order dependent)
	db	0		;AN000;no ranges
	db	4		;AN000;# of numeric choices
F_Choices	label	byte	;AN000;
	db	1		;AN000;1st choice (item tag)
	dd	0		;AN000;0
	db	2		;AN000;2nd choice
	dd	1		;AN000;1
	db	3		;AN000;3rd choice
	dd	2		;AN000;2
	db	4		;AN000;4th choice
	dd	7		;AN000;7


;AN000;System messages handler data
;AN000;Put the data here
.sall
MSG_SERVICES <MSGDATA>

;AN000;Place the messages here
MSG_SERVICES <DRIVER.CL1, DRIVER.CL2, DRIVER.CLA>

;AN000;Put messages handler code here.
MSG_SERVICES <LOADmsg,DISPLAYmsg,CHARmsg>
.xall

;
; Sets ds:di -> BDS for this drive
;
SetDrive:
	push	cs
	pop	ds
	mov	di,offset BDS
	ret

;
; Place for DSK$INIT to exit
;
ERR$EXIT:
	MOV	AH,10000001B			   ;MARK ERROR RETURN
	lds	bx, cs:[ptrsav]
	mov	byte ptr ds:[bx.MEDIA], 0	   ;AN002; # of units
	mov	word ptr ds:[bx.CONFIG_ERRMSG], -1 ;AN009;Show IBMBIO error message too.
	JMP	SHORT ERR1

Public EXIT
EXIT:	MOV	AH,00000001B
ERR1:	LDS	BX,CS:[PTRSAV]
	MOV	WORD PTR [BX].STATUS,AX ;MARK OPERATION COMPLETE

RestoreRegsAndReturn:
	POP	DS
	POP	BP
	POP	DI
	POP	DX
	POP	CX
	POP	AX
	POP	SI
	jmp	dos_exit


drivenumb   db	    5
cyln	    dw	    80
heads	    dw	    2
ffactor     db	    2
slim	    dw	    9

Switches    dw	0

Drive_Let_Sublist	label	dword
	db     11	;AN000;length of this table
	db	0	;AN000;reserved
	dw	D_Letter;AN000;
D_Seg	dw	?	;AN000;Segment value. Should be CS
	db	1	;AN000;DRIVER.SYS has only %1
	db	00000000b ;AN000;left align(in fact, Don't care), a character.
	db	1	;AN000;max field width 1
	db	1	;AN000;min field width 1
	db	' '     ;AN000;character for pad field (Don't care).

D_Letter	db	"A"

if iTEST
Message:
	push	ax
	push	ds
	push	cs
	pop	ds
	mov	ah,9
	int	21h
	pop	ds
	pop	ax
	ret
extrn	nodrive:byte,loadokmsg:byte,letter:byte, badvermsg:byte
endif


if iTEST
%OUT Testing On
initmsg     db	    "Initializing device driver",13,10,"$"
stratmsg    db	    "In strategy of driver",10,13,"$"
dskinmsg    db	    "In DSKIN part of driver",10,13,"$"
outinitmsg  db	    "Out of init code ",10,13,"$"
exitmsg     db	    "Exiting from driver",10,13,"$"
parsemsg    db	    "Parsing switches",10,13,"$"
errmsg	    db	    "Error occurred",10,13,"$"
linemsg     db	    "Parsed line",10,13,"$"
int2fokmsg  db	    "****************Int2f loaded**************",10,13,"$"
mediamsg    db	    "Media check ok",10,13,"$"
getbpbmsg   db	    "getbpb ok",10,13,"$"
iookmsg     db	    "Successful I/O",10,13,"$"
parseokmsg  db	    "Parsing done fine",10,13,"$"
nummsg	    db	    "Number read is "
number	    db	    "00  ",10,13,"$"
drvmsg	    db	    "Process drive "
driven	    db	    "0",10,13,"$"
cylnmsg     db	    "Process cylinder ",10,13,"$"
slimmsg     db	    "Process sec/trk ",10,13,"$"
hdmsg	    db	    "Process head "
hdnum	    db	    "0",10,13,"$"
ffmsg	    db	    "Process form factor "
ffnum	    db	    "0",10,13,"$"
nxtmsg	    db	    "Next switch ",10,13,"$"
msg48tpi    db	    "Got a 48 tpi drive",10,13,"$"

ENDIF

DSK$INIT:
	PUSH	SI
	PUSH	AX
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	BP
	PUSH	DS

	LDS	BX,CS:[PTRSAV]		;GET POINTER TO I/O PACKET

	MOV	AL,BYTE PTR DS:[BX].UNIT    ;AL = UNIT CODE
	MOV	AH,BYTE PTR DS:[BX].MEDIA   ;AH = MEDIA DESCRIP
	MOV	CX,WORD PTR DS:[BX].COUNT   ;CX = COUNT
	MOV	DX,WORD PTR DS:[BX].START   ;DX = START SECTOR

	LES	DI,DWORD PTR DS:[BX].TRANS

	PUSH	CS
	POP	DS

	ASSUME	DS:CODE

	cld
	push	cs			;AN000; Initialize Segment of Sub list.
	pop	[D_Seg] 		;AN000;
	call	SYSLOADMSG		;AN000; linitialize message handler
	jnc	GoodVer 		;AN000; Error. Do not install driver.
	mov	cx, 0			;AN000; No substitution
	mov	dh, -1			;AN000; Utility message
	call	Show_Message		;AN000; Show message
	jmp	err$exitj2		;AN000;  and exit

;; check for correct DOS version
;	 mov	 ah,30h
;	 int	 21H

;	 cmp	 ax,expected_version
;	 je	 GoodVer

;	cmp	al,DOSVER_HI
;	jnz	BadDOSVer
;	cmp	ah,DOSVER_LO
;	jz	GoodVer

;BadDOSVer:
;	 Mov	 dx,offset BadVerMsg
;	 call	 message
;	 jmp	 err$exitj2		 ; do not install driver

GoodVer:
	mov	ax,0800H
	int	2fH			    ; see if installed
	cmp	al,0FFH
	jnz	err$exitj2		    ; do not install driver if not present
	lds	bx,[ptrsav]
	mov	si,word ptr [bx].count	    ; get pointer to line to be parsed
	mov	ax,word ptr [bx].count+2
	mov	ds,ax
	call	Skip_Over_Name		    ; skip over file name of driver
	mov	di,offset BDS		    ; point to BDS for drive
	push	cs
	pop	es			    ; es:di -> BDS
	Call	ParseLine
	jc	err$exitj2
	LDS	BX,cs:[PTRSAV]
	mov	al,byte ptr [bx].extra	; get DOS drive letter
	mov	byte ptr es:[di].DriveLet,al
	mov	cs:[DOS_Drive_Letter],al
	add	al,"A"
;	 mov	 cs:[letter],al 	 ; set up for printing final message
	mov	cs:[D_Letter], al	;AN000;
	call	SetDrvParms		; Set up BDS according to switches
	jc	err$exitj2
	mov	ah,8			; Int 2f multiplex number
	mov	al,1			; install the BDS into the list
	push	cs
	pop	ds			; ds:di -> BDS for drive
	mov	di,offset BDS
	int	2FH
	lds	bx,dword ptr cs:[ptrsav]
	mov	ah,1
	mov	cs:[DRVMAX],ah
	mov	byte ptr [bx].media,ah
	mov	ax,offset ENDCODE
	mov	word ptr [bx].TRANS,AX	    ; set address of end of code
	mov	word ptr [bx].TRANS+2,CS
	mov	word ptr [bx].count,offset DskDrv
	mov	word ptr [bx].count+2,cs

	push	dx
	push	cs
	pop	ds
	mov	si, offset Drive_Let_SubList  ;AC000;
	mov	ax, LOADOK_MSG_NUM	;load ok message
	mov	cx, 1			;AN000; 1 substitution
	mov	dh, -1			;AN000; utility message
	call	Show_Message
;	 mov	 dx,offset loadokmsg
;	 call	 message
	pop	dx
	jmp	EXIT

err$exitj2:
	stc
	jmp	err$exit

;
; Skips over characters at ds:si until it hits a `/` which indicates a switch
; J.K. If it hits 0Ah or 0Dh, then will return with SI points to that character.
Skip_Over_Name:
	call	scanblanks
loop_name:
	lodsb
	cmp	al,CR				;AN003;
	je	End_SkipName			;AN003;
	cmp	al,LF				;AN003;
	je	End_SkipName			;AN003;
	cmp	al,'/'
	jnz	loop_name
End_SkipName:					;AN003;
	dec	si			    ; go back one character
	RET

;ParseLine:
;	 push	 di
;	 push	 ds
;	 push	 si
;	 push	 es
;Next_Swt:
;IF iTEST
;	 mov	 dx,offset nxtmsg
;	 call	 message
;ENDIF
;	 call	 ScanBlanks
;	 lodsb
;	 cmp	 al,'/'
;	 jz	 getparm
;	 cmp	 al,13		     ; carriage return
;	 jz	 done_line
;	 CMP	 AL,10		     ; line feed
;	 jz	 done_line
;	 cmp	 al,0		     ; null string
;	 jz	 done_line
;	 mov	 ax,-2		     ; mark error invalid-character-in-input
;	 stc
;	 jmp	 short exitparse
;
;getparm:
;	 call	 Check_Switch
;	 mov	 cs:Switches,BX      ; save switches read so far
;	 jnc	 Next_Swt
;	 cmp	 ax,-1		     ; mark error number-too-large
;	 stc
;	 jz	 exitparse
;	 mov	 ax,-2		     ; mark invalid parameter
;	 stc
;	 jmp	 short exitparse
;
;done_line:
;	 test	 cs:Switches,flagdrive	   ; see if drive specified
;	 jnz	 okay
;	 push	 dx
;	 mov	 ax, 2
;	 call	 Show_Message
;	 mov	 dx,offset nodrive
;	 call	 message
;	 pop	 dx
;	 mov	 ax,-3		     ; mark error no-drive-specified
;	 stc
;	 jmp	 short exitparse
;
;okay:
;	 call	 SetDrive			; ds:di points to BDS now.
;	 mov	 ax,cs:Switches
;	 and	 ax,fChangeline+fNon_Removable	; get switches for Non_Removable and Changeline
;	 or	 ds:[di].flags,ax
;	 xor	 ax,ax		     ; everything is fine
;
;;
;; Can detect status of parsing by examining value in AX.
;;	 0  ==>  Successful
;;	 -1 ==>  Number too large
;;	 -2 ==>  Invalid character in input
;;	 -3 ==>  No drive specified
;
;	 clc
;exitparse:
;	 pop	 es
;	 pop	 si
;	 pop	 ds
;	 pop	 di
;	 ret



ParseLine	proc	near
;In) DS:SI -> Input string
;    ES = CS
;    ES:DI -> BDS table inside this program
;
;Out)
;	if successfule, then {	AX will be set according to the switch
;				flag value.  BDS.Flag, Drivenumb, cylin,
;				slim, heads ffactor are set }
;	else
;	   {
;	    If (no drive specified) then { display messages };
;	    Set carry;
;	   }
;
;Subroutine to be called:
;	SYSPARSE:NEAR, SHOW_MESSAGE:NEAR, GET_RESULT:NEAR
;
;Logic:
;{	While (Not end_of_Line)
;	 {
;	  SYSPARSE ();
;	  if (no error) then
;	      GET_RESULT ()
;	else
;	      Set carry;
;	  };
;
;	if (carry set) then Exit;	/* Initialization failed */
;	if (No drive number entered)	/* Drive number is a requirement */
;	 then { Show_Message ();
;		exit;
;	      };
;
	assume	ds:nothing		;AN000;make sure
	push	di			;AN000;save BDS pointer
	mov	di, offset PARMS	;AN000;now, es:di -> parse control definition
SysP_While:				;AN000;
	xor	cx, cx			;AN004; I don't have positionals.
	xor	dx, dx			;AN000;
	call	SYSPARSE		;AN000;
	cmp	ax, $P_RC_EOL		;AN000;end of line?
	je	SysP_End		;AN000;
	cmp	ax, $P_NO_ERROR 	;AN000;no error?
	jne	SysP_Fail		;AN000;
	call	Get_Result		;AN000;
	jmp	SysP_While		;AN000;
SysP_End:				;AN000;
	test	Switches, FLAGDRIVE	;AN000;drive number specified?
	jnz	SysP_Ok 		;AN000;Drive number is a requirement
	push	ds			;AN000;
	mov	ax, NODRIVE_MSG_NUM	;AN000;no drive specification
	mov	cx, 0			;AN000;no substitutions
	mov	dh, -1			;AN000;utility message
	call	Show_Message		;AN000;
	pop	ds			;AN000;
	jmp short SysP_Err		;AN003;
SysP_Fail:				;AN000;
	mov	dh, 2			;AN000; parse error
	mov	cx, 0			;AN000;
	call	Show_Message		;AN000; Show parse error
SysP_Err:				;AN003;
	stc				;AN000;
	jmp short PL_Ret		;AN000;
SysP_Ok:				;AN000;
	clc				;AN000;
PL_Ret: 				;AN000;
	pop	di			;AN000;restore BDS pointer
	ret				;AN000;
ParseLine	endp

;
Get_Result	proc	near
;In) A successful result of SYSPARSE in Result_Val
;    es = cs, ds = command line segment
;Out)
;   Switches set according to the user option.
;   Drivenumb, Cyln, Heads, Slim, ffactor set if specified.
;Logic)
;   Switch (Synonym_Ptr)
;	{ case Switch_D: Switches = Switches | FLAGDRIVE; /* Set switches */
;			 Drivenumb = Reg_DX.Value_L;
;			 break;
;
;	  case Switch_T: Switches = Switches | Flagcyln;
;			 Cyln	= Reg_DX.Value_L;
;			 break;
;
;	  case Switch_H: Switches = Switches | Flagheads;
;			 Heads	= Reg_DX.Value_L;
;			 break;
;
;	  case Switch_S: Switches = Switches | FlagSecLim;
;			 Slim	= Reg_DX.Value_L;
;			 break;
;
;	  case Switch_C: Switches = Switches | fChangeline;
;			 break;
;
;;	   case Switch_N: Switches = Switches | fNon_Removable;
;;			  break;
;
;	  case Switch_F: Switches = Switches | Flagff;
;			 Reg_DX = (Reg_DX.ITEM_Tag - 1)*5;/*Get the offset of
;							  /*the choice.
;			 ffactor = byte ptr (F_Choices + DX + 1);
;					/*Get the value of it */
;			 break;
;
;	}
;


	mov	ax, Synonym_Ptr 	;AN000;
	push	ax			;AN006; save Synonym_ptr
	cmp	ax, offset Switch_D	;AN000;
	jne	Stch_T			;AN000;
	or	Switches, FLAGDRIVE	;AN000;
	mov	al, RV_Byte		;AN000;
	mov	Drivenumb, al		;AN000;
	jmp	GR_Ret			;AN000;
Stch_T: 				;AN000;
	cmp	ax, offset Switch_T	;AN000;
	jne	Stch_H			;AN000;
	or	Switches, FLAGCYLN	;AN000;
	mov	ax, RV_Word		;AN000;
	mov	Cyln, ax		;AN000;
	jmp	GR_Ret			;AN000;
Stch_H: 				;AN000;
	cmp	ax, offset Switch_H	;AN000;
	jne	Stch_S			;AN000;
	or	Switches, FLAGHEADS	;AN000;
	mov	ax, RV_Word		;AN000;
	mov	Heads, ax		;AN000;
	jmp	GR_Ret			;AN000;
Stch_S: 				;AN000;
	cmp	ax, offset Switch_S	;AN000;
	jne	Stch_C			;AN000;
	or	Switches, FLAGSECLIM	;AN000;
	mov	ax, RV_Word		;AN000;
	mov	Slim, ax		;AN000;
	jmp	GR_Ret			;AN000;
Stch_C: 				;AN000;
	cmp	ax, offset Switch_C	;AN000;
;	 jne	 Stch_N 		 ;AN000;
	jne	Stch_F			;AN001;
	or	Switches, fCHANGELINE	;AN000;
	jmp	GR_Ret			;AN000;
;Stch_N:				 ;AN000;
;	 cmp	 ax, offset Switch_N	 ;AN000;
;	 jne	 Stch_F 		 ;AN000;
;	 or	 Switches, fNON_REMOVABLE  ;AN000;
;	 jmp	 GR_Ret 		 ;AN000;
Stch_F: 				;AN000;
	cmp	ax, offset Switch_F	;AN000;
	jne	GR_Not_Found_Ret	;AN000;error in SYSPARSE
	or	Switches, FLAGFF	;AN000;
	push	si			;AN004;
	mov	si, offset F_Choices	;AN000;
	xor	ax, ax			;AN000;
	mov	al, Item_Tag		;AN000;
	dec	al			;AN000;
	mov	cl, 5			;AN000;
	mul	cl			;AN000;
	add	si, ax			;AN000;
	mov	al, byte ptr es:[si+1]	;AN000;get the result of choices
	mov	ffactor, al		;AN000;set form factor
	pop	si			;AN004;
GR_Ret: 				;AN000;
	pop	ax			;AN006; Restore Synonym ptr
	push	di			;AN006; Save di
	push	ax			;AN006;
	pop	di			;AN006;
	mov	byte ptr es:[di], ' '   ;AN006;We don't have this switch any more.
	pop	di			;AN006;
	jmp	short Gr_Done_Ret	;AN006;
GR_Not_Found_Ret:
	pop	ax			;AN006;adjust stack
GR_Done_Ret:
	ret				;AN000;
Get_Result	endp


;
; Scans an input line for blank or tab characters. On return, the line pointer
; will be pointing to the next non-blank character.
;
ScanBlanks:
	lodsb
	cmp	al,' '
	jz	ScanBlanks
	cmp	al,9		    ; Tab character
	jz	ScanBlanks
	dec	si
	ret

;
; Gets a number from the input stream, reading it as a string of characters.
; It returns the number in AX. It assumes the end of the number in the input
; stream when the first non-numeric character is read. It is considered an error
; if the number is too large to be held in a 16 bit register. In this case, AX
; contains -1 on return.
;
;GetNum:
;	 push	 bx
;	 push	 dx
;	 xor	 ax,ax
;	 xor	 bx,bx
;	 xor	 dx,dx
;
;next_char:
;	 lodsb
;	 cmp	 al,'0'              ; check for valid numeric input
;	 jb	 num_ret
;	 cmp	 al,'9'
;	 ja	 num_ret
;	 sub	 al,'0'
;	 xchg	 ax,bx		     ; save intermediate value
;	 push	 bx
;	 mov	 bx,10
;	 mul	 bx
;	 pop	 bx
;	 add	 al,bl
;	 adc	 ah,0
;	 xchg	 ax,bx		     ; stash total
;	 jc	 got_large
;	 cmp	 dx,0
;	 jz	 next_char
;got_large:
;	 mov	 ax,-1
;	 jmp	 short get_ret
;
;num_ret:
;	 mov	 ax,bx
;	 dec	 si		     ; put last character back into buffer
;
;get_ret:
;	 pop	 dx
;	 pop	 bx
;	 ret


;
; Processes a switch in the input. It ensures that the switch is valid, and
; gets the number, if any required, following the switch. The switch and the
; number *must* be separated by a colon. Carry is set if there is any kind of
; error.
;
;Check_Switch:
;	 lodsb
;	 and	 al,0DFH	     ; convert it to upper case
;	 cmp	 al,'A'
;	 jb	 err_swtch
;	 cmp	 al,'Z'
;	 ja	 err_swtch
;	 mov	 cl,cs:switchlist    ; get number of valid switches
;	 mov	 ch,0
;	 push	 es
;	 push	 cs
;	 pop	 es			 ; set es:di -> switches
;	 push	 di
;	 mov	 di,1+offset switchlist  ; point to string of valid switches
;	 repne	 scasb
;	 pop	 di
;	 pop	 es
;	 jnz	 err_swtch
;	 mov	 ax,1
;	 shl	 ax,cl		 ; set bit to indicate switch
;	 mov	 bx,cs:switches
;	 or	 bx,ax		 ; save this with other switches
;	 mov	 cx,ax
;	 test	 ax,7cH 	 ; test against switches that require number to follow
;	 jz	 done_swtch
;	 lodsb
;	 cmp	 al,':'
;	 jnz	 reset_swtch
;	 call	 ScanBlanks
;	 call	 GetNum
;	 cmp	 ax,-1		 ; was number too large?
;	 jz	 reset_swtch
;IF iTEST
;	 push	 ax
;	 add	 al,'0'
;	 add	 ah,'0'
;	 mov	 cs:number,ah
;	 mov	 cs:number+1,al
;	 mov	 dx,offset nummsg
;	 call	 message
;	 pop	 ax
;ENDIF
;	 call	 Process_Num
;
;done_swtch:
;	 ret
;
;reset_swtch:
;	 xor	 bx,cx			 ; remove this switch from the records
;err_swtch:
;	 stc
;	 jmp	 short done_swtch

;
; This routine takes the switch just input, and the number following (if any),
; and sets the value in the appropriate variable. If the number input is zero
; then it does nothing - it assumes the default value that is present in the
; variable at the beginning.
;
;Process_Num:
;	 push	 ds
;	 push	 cs
;	 pop	 ds
;	 test	 Switches,cx	     ; if this switch has been done before,
;	 jnz	 done_ret	     ; ignore this one.
;	 test	 cx,flagdrive
;	 jz	 try_f
;	 mov	 drivenumb,al
;IF iTEST
;	 add	 al,"0"
;	 mov	 driven,al
;	 mov	 dx,offset drvmsg
;	 call	 message
;ENDIF
;	 jmp	 short done_ret
;
;try_f:
;	 test	 cx,flagff
;	 jz	 try_t
;	 mov	 ffactor,al
;IF iTEST
;	 add	 al,"0"
;	 mov	 ffnum,al
;	 mov	 dx,offset ffmsg
;	 call	 message
;ENDIF
;
;try_t:
;	 cmp	 ax,0
;	 jz	 done_ret	     ; if number entered was 0, assume default value
;	 test	 cx,flagcyln
;	 jz	 try_s
;	 mov	 cyln,ax
;IF iTEST
;	 mov	 dx,offset cylnmsg
;	 call	 message
;ENDIF
;	 jmp	 short done_ret
;
;try_s:
;	 test	 cx,flagseclim
;	 jz	 try_h
;	 mov	 slim,ax
;IF iTEST
;	 mov	 dx,offset slimmsg
;	 call	 message
;ENDIF
;	 jmp	 short done_ret
;
;; Switch must be one for number of Heads.
;try_h:
;	 test	 cx,flagheads
;	 jz	 done_ret
;	 mov	 heads,ax
;IF iTEST
;	 add	 al,"0"
;	 mov	 hdnum,al
;	 mov	 dx,offset hdmsg
;	 call	 message
;ENDIF
;
;done_ret:
;	 pop	 ds
;	 ret

;
; SetDrvParms sets up the recommended BPB in each BDS in the system based on
; the form factor. It is assumed that the BPBs for the various form factors
; are present in the BPBTable. For hard files, the Recommended BPB is the same
; as the BPB on the drive.
; No attempt is made to preserve registers since we are going to jump to
; SYSINIT straight after this routine.
;
SetDrvParms:
	push	cs
	pop	es
	xor	bx,bx
	call	SetDrive		; ds:di -> BDS
	;test	 cs:switches,flagff	 ; has formfactor been specified?
	;jz	 formfcont
	mov	bl,cs:[ffactor]
	mov	byte ptr [di].formfactor,bl   ; replace with new value
formfcont:
	mov	bl,[di].FormFactor
;AC000; The followings are redundanat since there is no input specified for Hard file.
;	 cmp	 bl,ffHardFile
;	 jnz	 NotHardFF
;	 mov	 ax,[di].DrvLim
;	 cmp	 ax, 0			 ;AN000;32 bit sector number?
;	 push	 ax
;	 mov	 ax,word ptr [di].hdlim
;	 mul	 word ptr [di].seclim
;	 mov	 cx,ax			 ; cx has # sectors per cylinder
;	 pop	 ax
;	 xor	 dx,dx			 ; set up for div
;	 div	 cx			 ; div #sec by sec/cyl to get # cyl
;	 or	 dx,dx
;	 jz	 No_Cyl_Rnd		 ; came out even
;	 inc	 ax			 ; round up
;No_Cyl_Rnd:
;	 mov	 cs:[cyln],ax
;	 mov	 si,di
;	 add	 si,BytePerSec		 ; ds:si -> BPB for hard file
;	 jmp	 short Set_RecBPB
;NotHardFF:
;AC000; End of deletion.
	cmp	bl,ff48tpi
	jnz	Got_80_cyln
IF iTEST
	mov	dx,offset msg48tpi
	call	message
ENDIF
	mov	cx,40
	mov	cs:[cyln],cx
Got_80_cyln:
	shl	bx,1			; bx is word index into table of BPBs
	mov	si,offset BPBTable
	mov	si,word ptr [si+bx]	; get address of BPB
Set_RecBPB:
	add	di,RBytePerSec		; es:di -> Recommended BPB
	mov	cx,BPBSIZ
	cld
	repe	movsb			; move BPBSIZ bytes

	call	Handle_Switches 	; replace with 'new' values as
					; specified in switches.
;
; We need to set the media byte and the total number of sectors to reflect the
; number of heads. We do this by multiplying the number of heads by the number
; of 'sectors per head'. This is not a fool-proof scheme!!
;
	mov	ax,[di].Rdrvlim 	; this is OK for two heads
	sar	ax,1			; ax contains # of sectors/head
	mov	cx,[di].Rhdlim
	dec	cl			; get it 0-based
	sal	ax,cl
	jc	Set_All_Done_BRG	; We have too many sectors - overflow!!
	mov	[di].Rdrvlim,ax
	cmp	cl,1
; We use media descriptor byte F0H for any type of medium that is not currently
; defined i.e. one that does not fall into the categories defined by media
; bytes F8H, F9H, FCH-FFH.

	JE	HEAD_2_DRV
	MOV	AL, 1				;1 sector/cluster
	MOV	BL, BYTE PTR [DI].Rmediad
	CMP	BYTE PTR [DI].FormFactor, ffOther
	JE	GOT_CORRECT_MEDIAD
	MOV	CH, BYTE PTR [DI].FormFactor
	CMP	CH, ff48tpi
	JE	SINGLE_MEDIAD
	MOV	BL, 0F0h
	JMP	GOT_CORRECT_MEDIAD
Set_All_Done_BRG:jmp Set_All_Done
SINGLE_MEDIAD:
	CMP	WORD PTR [DI].RSecLim, 8	;8 SEC/TRACK?
	JNE	SINGLE_9_SEC
	MOV	BL, 0FEh
	JMP	GOT_CORRECT_MEDIAD
SINGLE_9_SEC:
	MOV	BL, 0FCh
	JMP	GOT_CORRECT_MEDIAD
HEAD_2_DRV:
	MOV	BL, 0F0h		;default 0F0h
	MOV	AL, 1			;1 sec/cluster
	CMP	BYTE PTR [DI].FormFactor, ffOther
	JE	GOT_CORRECT_MEDIAD
	CMP	BYTE PTR [DI].FormFactor, ff48tpi
	JNE	NOT_48TPI
	MOV	AL, 2
	CMP	WORD PTR [DI].RSecLim, 8	;8 SEC/TRACK?
	JNE	DOUBLE_9_SEC
	MOV	BL, 0FFh
	JMP	GOT_CORRECT_MEDIAD
DOUBLE_9_SEC:
	MOV	BL, 0FDh
	JMP	GOT_CORRECT_MEDIAD
NOT_48TPI:
	CMP	BYTE PTR [DI].FormFactor, ff96tpi
	JNE	NOT_96TPI
	MOV	AL, 1			;1 sec/cluster
	MOV	BL, 0F9h
	JMP	GOT_CORRECT_MEDIAD
NOT_96TPI:
	CMP	BYTE PTR [DI].FormFactor, ffSmall	;3-1/2, 720kb
	JNE	GOT_CORRECT_MEDIAD	;Not ffSmall. Strange Media device.
	MOV	AL, 2			;2 sec/cluster
	MOV	BL, 0F9h

;J.K. 12/9/86 THE ABOVE IS A QUICK FIX FOR 3.3 DRIVER.SYS PROB. OLD LOGIC IS COMMENTED OUT.
;	 mov	 bl,0F0H		 ; assume strange media
;	 mov	 al,1			 ; AL is sectors/cluster - match 3.3 bio dcl. 6/27/86
;	 ja	 Got_Correct_Mediad
;; We check to see if the form factor specified was "other"
;	 cmp	 byte ptr [di].FormFactor,ffOther
;	 jz	 Got_Correct_Mediad
;; We must have 1 or 2 heads (0 is ignored)
;	 mov	 bl,byte ptr [di].Rmediad
;	 cmp	 cl,1
;	 jz	 Got_Correct_Mediad
;; We must have one head - OK for 48tpi media
;	 mov	 al,1			 ; AL is sectors/cluster
;	 mov	 ch,byte ptr [di].FormFactor
;	 cmp	 ch,ff48tpi
;	 jz	 Dec_Mediad
;	 mov	 bl,0F0H
;	 jmp	 short Got_Correct_Mediad
;Dec_Mediad:
;	 dec	 bl			 ; adjust for one head
;J.K. END OF OLD LOGIC

Got_Correct_Mediad:
	mov	byte ptr [di].RSecPerClus,al
	mov	byte ptr [di].Rmediad,bl
; Calculate the correct number of Total Sectors on medium
	mov	ax,word ptr [di].Ccyln
	mov	bx,word ptr [di].RHdLim
	mul	bx
	mov	bx,word ptr [di].RSecLim
	mul	bx
; AX contains the total number of sectors on the disk
	mov	word ptr [di].RDrvLim,ax
;J.K. For ffOther type of media, we should set Sec/FAT, and # of Root directory
;J.K. accordingly.
	cmp	byte ptr [di].FormFactor, ffOther  ;AN005;
	jne	Set_All_Ok			;AN005;
	xor	dx, dx				;AN005;
	dec	ax				;AN005; DrvLim - 1.
	mov	bx, 3				;AN005; Assume 12 bit fat.
	mul	bx				;AN005;  = 1.5 byte
	mov	bx, 2				;AN005;
	div	bx				;AN005;
	xor	dx, dx				;AN005;
	mov	bx, 512 			;AN005;
	div	bx				;AN005;
	inc	ax				;AN005;
	mov	[di].RCSecFat, ax		;AN005;
	mov	[di].RCDir, 0E0h		;AN005; directory entry # = 224
Set_All_Ok:					;AN005;
	clc
Set_All_Done:
	RET

;
; Handle_Switches replaces the values that were entered on the command line in
; config.sys into the recommended BPB area in the BDS.
; NOTE:
;	No checking is done for a valid BPB here.
;
Handle_Switches:
	call	setdrive		; ds:di -> BDS
	test	cs:switches,flagdrive
	jz	done_handle		    ; if drive not specified, exit
	mov	al,cs:[drivenumb]
	mov	byte ptr [di].DriveNum,al
;	 test	 cs:switches,flagcyln
;	 jz	 no_cyln
	mov	ax,cs:[cyln]
	mov	word ptr [di].cCyln,ax
no_cyln:
	test	cs:switches,flagseclim
	jz	no_seclim
	mov	ax,cs:[slim]
	mov	word ptr [di].RSeclim,ax
no_seclim:
	test	cs:switches,flagheads
	jz	done_handle
	mov	ax,cs:[heads]
	mov	word ptr [di].RHdlim,ax
done_handle:
	RET


Show_Message	proc	near
;In) AX = message number
;    DS:SI -> Substitution list if necessary.
;    CX = 0 or n depending on the substitution number
;    DH = -1 FOR UTILITY MSG CLASS, 2 FOR PARSE ERROR
;Out) Message displayed using DOS function 9 with no keyboard input.
	push	cs		;AN000;
	pop	ds		;AN000;
	mov	bx, -1		;AN000;
	mov	dl, 0		;AN000;no input
	call	SYSDISPMSG	;AN000;
	ret			;AN000;
Show_Message	endp

;
; The following are the recommended BPBs for the media that we know of so
; far.

; 48 tpi diskettes

BPB48T	DW	512
	DB	2
	DW	1
	DB	2
	DW	112
	DW	2*9*40
	DB	0FDH
	DW	2
	DW	9
	DW	2
	DW	0

; 96tpi diskettes

BPB96T	DW	512
	DB	1
	DW	1
	DB	2
	DW	224
	DW	2*15*80
	DB	0F9H
	DW	7
	DW	15
	DW	2
	DW	0

BPBSIZ	=	$-BPB96T

; 3 1/2 inch diskette BPB

BPB35	DW	512
	DB	2
	DW	1			; Double sided with 9 sec/trk
	DB	2
	DW	70h
	DW	2*9*80
	DB	0F9H
	DW	3
	DW	9
	DW	2
	DW	0


BPBTable    dw	    BPB48T		; 48tpi drives
	    dw	    BPB96T		; 96tpi drives
	    dw	    BPB35		; 3.5" drives
; The following are not supported, so we default to 3.5" layout
	    dw	    BPB35		; Not used - 8" drives
	    dw	    BPB35		; Not Used - 8" drives
	    dw	    BPB35		; Not Used - hard files
	    dw	    BPB35		; Not Used - tape drives
	    dw	    BPB35		; Not Used - Other

switchlist  db	7,"FHSTDCN"         ; Preserve the positions of N and C.

; The following depend on the positions of the various letters in SwitchList

flagdrive   equ     0004H
flagcyln    equ     0008H
flagseclim  equ     0010H
flagheads   equ     0020H
flagff	    equ     0040H

;AN000;
;Equates for message number
NODRIVE_MSG_NUM   equ	2
LOADOK_MSG_NUM	  equ	3

code ends

end
