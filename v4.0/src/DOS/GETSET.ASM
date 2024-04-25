;	SCCSID = @(#)getset.asm 1.2 85/07/23
TITLE  GETSET - GETting and SETting MS-DOS system calls
NAME   GETSET
;
; System Calls which get and set various things
;
;   $GET_VERSION
;   $GET_VERIFY_ON_WRITE
;   $SET_VERIFY_ON_WRITE
;   $INTERNATIONAL
;   $GET_DRIVE_FREESPACE
;   $GET_DMA
;   $SET_DMA
;   $GET_DEFAULT_DRIVE
;   $SET_DEFAULT_DRIVE
;   $GET_INTERRUPT_VECTOR
;   $SET_INTERRUPT_VECTOR
;   RECSET
;   $CHAR_OPER
;   $GetExtendedError		       DOS 3.3
;   Get_Global_CdPg		       DOS 4.0
;   $ECS_CALL			       DOS 4.0
;
;   Revision history:
;
;	Created: ARR 30 March 1983
;
;	A000   version 4.0   Jan. 1988
;	A006   D503-- fake version for IBMCACHE
;	A008   P4070- faske version for MS WINDOWS

.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

IFNDEF	ALTVECT
ALTVECT EQU	0			; FALSE
ENDIF

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xcref
include dossym.inc
include devsym.inc
include doscntry.inc
.cref
.list

	i_need	USERNUM,WORD
	i_need	MSVERS,WORD
	i_need	VERFLG,BYTE
	i_need	CNTCFLAG,BYTE
	i_need	DMAADD,DWORD
	i_need	CURDRV,BYTE
	i_need	chSwitch,BYTE
	i_need	COUNTRY_CDPG,byte	      ;DOS 3.3
	I_need	CDSCount,BYTE
	I_need	ThisCDS,DWORD
	i_need	EXTERR,WORD
	i_need	EXTERR_ACTION,BYTE
	i_need	EXTERR_CLASS,BYTE
	i_need	EXTERR_LOCUS,BYTE
	i_need	EXTERRPT,DWORD
	i_need	UCASE_TAB,BYTE
	i_need	FILE_UCASE_TAB,BYTE
	i_need	InterCon,BYTE
	i_need	CURRENTPDB,WORD
	i_need	DBCS_TAB,BYTE			   ;AN000;
	i_need	Special_version,WORD		   ;AN006;
	i_need	Fake_Count,BYTE 		   ;AN008;
	i_need	NLS_YES,BYTE			   ;AN000;
	i_need	NLS_yes2,BYTE			   ;AN000;
	i_need	NLS_NO,BYTE			   ;AN000;
	i_need	NLS_no2,BYTE			   ;AN000;


BREAK <$Get_Version -- Return DOS version number>
	procedure   $GET_VERSION,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	None
; Function:
;	Return DOS version number
; Outputs:
;	OEM number in BH
;	User number in BL:CX (24 bits)
;	Version number as AL.AH in binary
;	NOTE: On pre 1.28 DOSs AL will be zero

	context DS
	MOV	BX,[USERNUM + 2]
	MOV	CX,[USERNUM]
	MOV	AX,[MSVERS]
	invoke	get_user_stack
ASSUME	DS:NOTHING
	MOV	[SI.user_BX],BX
	MOV	[SI.user_CX],CX
	CMP	CS:[Fake_Count],0FFH		   ;AN008;
	JZ	reg				   ;AN008;
	CMP	CS:[Fake_Count],0		   ;AN008;
	JZ	usual				   ;AN008;
	DEC	CS:[Fake_Count] 		   ;AN008;
reg:						   ;AN008;
	CMP	CS:[Special_version],0		   ;AN006;
	JZ	usual				   ;AN006;
	MOV	AX,CS:[Special_version] 	   ;AN006;
usual:						   ;AN006;
	MOV	[SI.user_AX],AX 	; Really only sets AH
	return
EndProc $GET_VERSION

BREAK <$Get_Verify_on_Write - return verify-after-write flag>
	procedure   $GET_VERIFY_ON_WRITE,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	none.
; Function:
;	returns flag
; Returns:
;	AL = value of VERIFY flag

	MOV	AL,[VERFLG]
	return
EndProc $GET_VERIFY_ON_WRITE

BREAK <$Set_Verify_on_Write - Toggle verify-after-write flag>
	procedure   $SET_VERIFY_ON_WRITE,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	AL = desired value of VERIFY flag
; Function:
;	Sets flag
; Returns:
;	None

	AND	AL,1
	MOV	[VERFLG],AL
	return
EndProc $SET_VERIFY_ON_WRITE

BREAK <$International - return country-dependent information>
;
; Inputs:
;	MOV	AH,International
;	MOV	AL,country	(al = 0 => current country)
;      [MOV	BX,country]
;	LDS	DX,block
;	INT	21
; Function:
;	give users an idea of what country the application is running
; Outputs:
;	IF DX != -1 on input (get country)
;	  AL = 0 means return current country table.
;	  0<AL<0FFH means return country table for country AL
;	  AL = 0FF means return country table for country BX
;	  No Carry:
;	     Register BX will contain the 16-bit country code.
;	     Register AL will contain the low 8 bits of the country code.
;	     The block pointed to by DS:DX is filled in with the information
;	     for the particular country.
;		BYTE  Size of this table excluding this byte and the next
;		BYTE  Country code represented by this table
;			A sequence of n bytes, where n is the number specified
;			by the first byte above and is not > internat_block_max,
;			in the correct order for being returned by the
;			INTERNATIONAL call as follows:
;		WORD	Date format 0=mdy, 1=dmy, 2=ymd
;		5 BYTE	Currency symbol null terminated
;		2 BYTE	thousands separator null terminated
;		2 BYTE	Decimal point null terminated
;		2 BYTE	Date separator null terminated
;		2 BYTE	Time separator null terminated
;		1 BYTE	Bit field.  Currency format.
;			Bit 0.	=0 $ before #  =1 $ after #
;			Bit 1.	no. of spaces between # and $ (0 or 1)
;		1 BYTE	No. of significant decimal digits in currency
;		1 BYTE	Bit field.  Time format.
;			Bit 0.	=0 12 hour clock  =1 24 hour
;		DWORD	Call address of case conversion routine
;		2 BYTE	Data list separator null terminated.
;	  Carry:
;	     Register AX has the error code.
;	IF DX = -1 on input (set current country)
;	  AL = 0 is an error
;	  0<AL<0FFH means set current country to country AL
;	  AL = 0FF means set current country to country BX
;	  No Carry:
;	    Current country SET
;	    Register AL will contain the low 8 bits of the country code.
;	  Carry:
;	     Register AX has the error code.


	procedure   $INTERNATIONAL,NEAR   ; DOS 3.3
ASSUME	DS:NOTHING,ES:NOTHING
	CMP	AL,0FFH
	JZ	BX_HAS_CODE		; -1 means country code is in BX
	MOV	BL,AL			; Put AL country code in BX
	XOR	BH,BH
BX_HAS_CODE:
	PUSH	DS
	POP	ES
	PUSH	DX
	POP	DI			; User buffer to ES:DI
	context DS
	CMP	DI,-1
	JZ	international_set
	OR	BX,BX
	JNZ	international_find
	MOV	SI,OFFSET DOSGROUP:COUNTRY_CDPG
	JMP	SHORT international_copy

international_find:
	MOV	BP,0			 ; flag it for GetCntry only
	CALL	international_get
	JC	errtn
	CMP	BX,0			 ; nlsfunc finished it ?
	JNZ	SHORT international_copy ; no, copy by myself
	MOV	BX,DX			 ; put country back
	JMP	SHORT international_ok3

international_get:
	MOV	SI,OFFSET DOSGROUP:COUNTRY_CDPG
	CMP	BX,[SI.ccDosCountry]	 ; = current country id
	retz				 ; return if equal
	MOV	DX,BX
	XOR	BX,BX			 ; bx = 0, default code page
	CallInstall NLSInstall,NLSFUNC,0 ; check if NLSFUNC in memory
	CMP	AL,0FFH
	JNZ	interr			   ; not in memory
	CMP	BP,0			 ; GetCntry ?
	JNZ	stcdpg
	CallInstall GetCntry,NLSFUNC,4	 ; get country info
	JMP	chkok
stcdpg:
	CallInstall SetCodePage,NLSFUNC,3  ; set country info
chkok:
	CMP	AL,0			   ; success ?
	retz				   ; yes
setcarry:
	STC				 ; set carry
	ret
interr:
	MOV	AL,0FFH 		   ; flag nlsfunc error
	JMP	setcarry

international_copy:
	MOV	BX,[SI.ccDosCountry]	 ; = current country id
	MOV	SI,OFFSET DOSGROUP:COUNTRY_CDPG.ccDFormat
	MOV	CX,OLD_COUNTRY_SIZE
	REP	MOVSB			 ;copy country info
international_ok3:
	invoke	get_user_stack
ASSUME	DS:NOTHING
	MOV	[SI.user_BX],BX
international_ok:
	MOV	AX,BX		     ; Return country code in AX too.
	transfer SYS_RET_OK

international_set:
ASSUME	DS:DOSGROUP
	MOV	BP,1		     ; flag it for SetCodePage only
	CALL	international_get
	JNC	international_ok
errtn:
	CMP	AL,0FFH
	JZ	errtn2
	transfer SYS_RET_ERR	     ; return what we got from NLSFUNC
errtn2:
	error	error_Invalid_Function	; NLSFUNC not existent


EndProc $INTERNATIONAL



BREAK <$GetExtCntry - return extended country-dependent information>
;
; Inputs:
;	if AL >= 20H
;	  AL= 20H    capitalize single char, DL= char
;	      21H    capitalize string ,CX= string length
;	      22H    capitalize ASCIIZ string
;	      23H    YES/NO check, DL=1st char DH= 2nd char (DBCS)
;	      80H bit 0 = use normal upper case table
;		      1 = use file upper case table
;	   DS:DX points to string
;
;	else
;
;	MOV	AH,GetExtCntry	 ; DOS 3.3
;	MOV	AL,INFO_ID	( info type,-1	selects all)
;	MOV	BX,CODE_PAGE	( -1 = active code page )
;	MOV	DX,COUNTRY_ID	( -1 = active country )
;	MOV	CX,SIZE 	( amount of data to return)
;	LES	DI,COUNTRY_INFO ( buffer for returned data )
;	INT	21
; Function:
;	give users extended country dependent information
;	or capitalize chars
; Outputs:
;	  No Carry:
;	     extended country info is succesfully returned
;	  Carry:
;	     Register AX has the error code.
;	     AX=0, NO	 for YES/NO CHECK
;		1, YES


	procedure   $GetExtCntry,NEAR	; DOS 3.3
ASSUME	DS:NOTHING,ES:NOTHING
	CMP	AL,CAP_ONE_CHAR 	;AN000;MS. < 20H ?
	JAE	capcap			;AN000;MS.
	JMP	notcap			;AN000;MS. yes
capcap: 				;AN000;
	TEST	AL,UPPER_TABLE		;AN000;MS. which upper case table
	JNZ	fileupper		;AN000;MS. file upper case
	MOV	BX,OFFSET DOSGROUP:UCASE_TAB+2 ;AN000;MS. get normal upper case
	JMP	SHORT capit			   ;AN000;MS.
fileupper:					   ;AN000;
	MOV	BX,OFFSET DOSGROUP:FILE_UCASE_TAB+2;AN000;MS. get file upper case
capit:					;AN000;
	CMP	AL,CAP_ONE_CHAR 	;AN000;;MS.cap one char ?
	JNZ	chkyes			;AN000;;MS. no
	MOV	AL,DL			;AN000;;MS. set up AL
	invoke	GETLET3 		;AN000;;MS. upper case it
	invoke	get_user_stack		;AN000;;MS. get user stack
	MOV	byte ptr [SI.user_DX],AL;AN000;;MS. user's DL=AL
	JMP	SHORT nono		;AN000;;MS. done
chkyes: 				;AN000;
	CMP	AL,CHECK_YES_NO 	;AN000;;MS. check YES or NO ?
	JNZ	capstring		;AN000;;MS. no
	XOR	AX,AX			;AN000;;MS. presume NO
IF  DBCS				;AN000;
	PUSH	AX			;AN000;;MS.
	MOV	AL,DL			;AN000;;MS.
	invoke	TESTKANJ		;AN000;;MS. DBCS ?
	POP	AX			;AN000;;MS.
	JNZ	dbcs_char		;AN000;;MS. yes, return error
ENDIF					;AN000;
					;AN000;
	CMP	DL,NLS_YES		;AN000;;MS. is 'Y' ?
	JZ	yesyes			;AN000;;MS. yes
	CMP	DL,NLS_yes2		;AN000;;MS. is 'y' ?
	JZ	yesyes			;AN000;;MS. yes
	CMP	DL,NLS_NO		;AN000;;MS. is	'N'?
	JZ	nono			;AN000;;MS. no
	CMP	DL,NLS_no2		;AN000;;MS. is 'n' ?
	JZ	nono			;AN000;;MS. no
dbcs_char:				;AN000;
	INC	AX			;AN000;;MS. not YES or NO
yesyes: 				;AN000'
	INC	AX			;AN000;;MS. return 1
nono:					;AN000;
	transfer SYS_RET_OK		;AN000;;MS. done
capstring:				;AN000;
	MOV	SI,DX			;AN000;;MS. si=dx
	CMP	AL,CAP_STRING		;AN000;;MS. cap string ?
	JNZ	capascii		;AN000;;MS. no
	CMP	CX,0			;AN000;;MS. check count 0
	JZ	nono			;AN000;;MS. yes finished
concap: 				;AN000;
	LODSB				;AN000;;MS. get char
 IF  DBCS				;AN000;;MS.
	invoke	TESTKANJ		;AN000;;MS. DBCS ?
	JZ	notdbcs 		;AN000;;MS. no
	INC	SI			;AN000;;MS. skip 2 chars
	DEC	CX			;AN000;;MS. bad input, one DBCS char at end
	JZ	nono			;AN000;;MS. yes
	JMP	SHORT next99		;AN000;;MS.
notdbcs:				;AN000;
 ENDIF					;AN000;

	invoke	GETLET3 		;AN000;;MS. upper case it
	MOV	byte ptr [SI-1],AL	;AN000;;MS. store back
next99: 				;AN000;
	LOOP	concap			;AN000;;MS. continue
	JMP	nono			;AN000;;MS. done
capascii:				;AN000;
	CMP	AL,CAP_ASCIIZ		;AN000;;MS. cap ASCIIZ string ?
	JNZ	capinval		;AN000;;MS. no
concap2:				;AN000;
	LODSB				;AN000;;MS. get char
	CMP	AL,0			;AN000;;MS. end of string ?
	JZ	nono			;AN000;;MS. yes
 IF  DBCS				;AN000;;MS.
	invoke	TESTKANJ		;AN000;;MS. DBCS ?
	JZ	notdbcs2		;AN000;;MS. no
	CMP	BYTE PTR [SI],0 	;AN000;;MS. bad input, one DBCS char at end
	JZ	nono			;AN000;;MS. yes
	INC	SI			;AN000;;MS. skip 2 chars
	JMP	concap2 		;AN000;;MS.
notdbcs2:				;AN000;
 ENDIF					;AN000;
	invoke	GETLET3 		;AN000;;MS. upper case it
	MOV	byte ptr [SI-1],AL	;AN000;;MS. store back
	JMP	concap2 		;AN000;;MS. continue


notcap:
	CMP	CX,5			; minimum size is 5
	JB	sizeerror
	context DS
	MOV	SI,OFFSET DOSGROUP:COUNTRY_CDPG
	CMP	DX,-1			; active country ?
	JNZ	GETCDPG 		; no
	MOV	DX,[SI.ccDosCountry]	; get active country id
GETCDPG:
	CMP	BX,-1			; active code page?
	JNZ	CHKAGAIN		; no, check again
	MOV	BX,[SI.ccDosCodePage]	; get active code page id
CHKAGAIN:
	CMP	DX,[SI.ccDosCountry]	; same as active country id?
	JNZ	CHKNLS			; no
	CMP	BX,[SI.ccDosCodePage]	; same as active code page id?
	JNZ	CHKNLS			; no
CHKTYPE:
	MOV	BX,[SI.ccSysCodePage]	; bx = sys code page id
;	CMP	AL,SetALL		; select all?
;	JNZ	SELONE
;	MOV	SI,OFFSET DOSGROUP:COUNTRY_CDPG.ccNumber_of_entries
SELONE:
	PUSH	CX			; save cx
	MOV	CX,[SI.ccNumber_of_entries]
	MOV	SI,OFFSET DOSGROUP:COUNTRY_CDPG.ccSetUcase
NXTENTRY:
	CMP	AL,[SI] 		; compare info type
	JZ	FOUNDIT
	ADD	SI,5			; next entry
	LOOP	NXTENTRY
	POP	CX
capinval:
	error	error_Invalid_Function	; info type not found
FOUNDIT:
	MOVSB				; move info id byte
	POP	CX			; retsore char count
	CMP	AL,SetCountryInfo	; select country info type ?
	JZ	setsize
	MOV	CX,4			; 4 bytes will be moved
	MOV	AX,5			; 5 bytes will be returned in CX
OK_RETN:
	REP	MOVSB			; copy info
	MOV	CX,AX			; CX = actual length returned
	MOV	AX,BX			; return sys code page in ax
GETDONE:
	invoke	get_user_stack		; return actual length to user's CX
	MOV	[SI.user_CX],CX
	transfer SYS_RET_OK
setsize:
	SUB	CX,3			; size after length field
	CMP	WORD PTR [SI],CX	; less than table size
	JAE	setsize2		; no
	MOV	CX,WORD PTR [SI]	; truncate to table size
setsize2:
	MOV	ES:[DI],CX		; copy actual length to user's
	ADD	DI,2			; update index
	ADD	SI,2
	MOV	AX,CX
	ADD	AX,3			; AX has the actual length
	JMP	OK_RETN 		; go move it
CHKNLS:
	XOR	AH,AH
	PUSH	AX			   ; save info type
	POP	BP			   ; bp = info type
	CallInstall NLSInstall,NLSFUNC,0 ; check if NLSFUNC in memory
	CMP	AL,0FFH
	JZ	NLSNXT			   ;	 in memory
sizeerror:
	error	error_Invalid_Function
NLSNXT: CallInstall GetExtInfo,NLSFUNC,2  ;get extended info
	CMP	AL,0			   ; success ?
	JNZ	NLSERROR
	MOV	AX,[SI.ccSysCodePage]	; ax = sys code page id
	JMP	GETDONE
NLSERROR:
	transfer SYS_RET_ERR		; return what is got from NLSFUNC

EndProc $GetExtCntry

BREAK <$GetSetCdPg - get or set global code page>
;
; Inputs:
;	MOV	AH,GetSetCdPg	; DOS 3.3
;	MOV	AL,n		; n = 1 : get code page, n = 2 : set code page
;	MOV	BX,CODE_PAGE	( set code page only)
;	INT	21
; Function:
;	get or set the global code page
; Outputs:
;	  No Carry:
;	     global code page is set	(set global code page)
;	     BX = active code page id	(get global code page)
;	     DX = system code page id	(get global code page)
;	  Carry:
;	     Register AX has the error code.


	procedure   $GetSetCdPg,NEAR   ; DOS 3.3
ASSUME	DS:NOTHING,ES:NOTHING
	context DS
	MOV	SI,OFFSET DOSGROUP:COUNTRY_CDPG
	CMP	AL,1		       ; get global code page
	JNZ	setglpg 	       ; set global cod epage
	MOV	BX,[SI.ccDosCodePage]  ; get active code page id
	MOV	DX,[SI.ccSysCodePage]  ; get sys code page id
	invoke	get_user_stack
ASSUME DS:NOTHING
	MOV	[SI.user_BX],BX        ; update returned bx
	MOV	[SI.user_DX],DX        ; update returned dx
OK_RETURN:
	transfer SYS_RET_OK
ASSUME DS:DOSGROUP
setglpg:
	CMP	AL,2
	JNZ	nomem
;;;;;;; CMP	BX,[SI.ccDosCodePage]  ; same as active code page
;;;;;;; JZ	OK_RETURN	       ; yes
	MOV	DX,[SI.ccDosCountry]
	CallInstall NLSInstall,NLSFUNC,0 ; check if NLSFUNC in memory
	CMP	AL,0FFH
	JNZ	nomem			   ; not in memory
	CallInstall SetCodePage,NLSFUNC,1  ;set the code page
	CMP	AL,0			   ; success ?
	JZ	OK_RETURN		   ; yes
	CMP	AL,65			   ; set device code page failed
	JNZ	seterr
	MOV	AX,65
	MOV	[EXTERR],AX
	MOV	[EXTERR_ACTION],errACT_Ignore
	MOV	[EXTERR_CLASS],errCLASS_HrdFail
	MOV	[EXTERR_LOCUS],errLOC_SerDev
	transfer   From_GetSet

seterr:
	transfer  SYS_RET_ERR
nomem:
	error	error_Invalid_Function ; function not defined
;
EndProc $GetSetCdPg




BREAK <$Get_Drive_Freespace -- Return bytes of free disk space on a drive>
	procedure   $GET_DRIVE_FREESPACE,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	DL = Drive number
; Function:
;	Return number of free allocation units on drive
; Outputs:
;	BX = Number of free allocation units
;	DX = Total Number of allocation units on disk
;	CX = Sector size
;	AX = Sectors per allocation unit
;	   = -1 if bad drive specified
; This call returns the same info in the same registers (except for FAT pointer)
;      as the old FAT pointer calls

	context DS
	MOV	AL,DL
	invoke	GetThisDrv		; Get drive
SET_AX_RET:
	JC	BADFDRV
	invoke	DISK_INFO
	XCHG	DX,BX
	JC	SET_AX_RET		; User FAILed to I 24
	XOR	AH,AH			; Chuck Fat ID byte
DoSt:
	invoke	get_user_stack
ASSUME	DS:NOTHING
	MOV	[SI.user_DX],DX
	MOV	[SI.user_CX],CX
	MOV	[SI.user_BX],BX
	MOV	[SI.user_AX],AX
	return
BADFDRV:
;	MOV	AL,error_invalid_drive	; Assume error
	invoke	FCB_RET_ERR
	MOV	AX,-1
	JMP	DoSt
EndProc $GET_DRIVE_FREESPACE

BREAK <$Get_DMA, $Set_DMA -- Get/Set current DMA address>
	procedure   $GET_DMA,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	None
; Function:
;	Get DISK TRANSFER ADDRESS
; Returns:
;	ES:BX is current transfer address

	MOV	BX,WORD PTR [DMAADD]
	MOV	CX,WORD PTR [DMAADD+2]
	invoke	get_user_stack
	MOV	[SI.user_BX],BX
	MOV	[SI.user_ES],CX
	return
EndProc $GET_DMA

	procedure   $SET_DMA,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	DS:DX is desired new disk transfer address
; Function:
;	Set DISK TRANSFER ADDRESS
; Returns:
;	None

	MOV	WORD PTR [DMAADD],DX
	MOV	WORD PTR [DMAADD+2],DS
	return
EndProc $SET_DMA

BREAK <$Get_Default_Drive, $Set_Default_Drive -- Set/Get default drive>
	procedure   $GET_DEFAULT_DRIVE,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	None
; Function:
;	Return current drive number
; Returns:
;	AL = drive number

	MOV	AL,[CURDRV]
	return
EndProc $GET_DEFAULT_DRIVE

	procedure   $SET_DEFAULT_DRIVE,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	DL = Drive number for new default drive
; Function:
;	Set the default drive
; Returns:
;	AL = Number of drives, NO ERROR RETURN IF DRIVE NUMBER BAD

	MOV	AL,DL
	INC	AL			; A=1, b=2...
	invoke	GetVisDrv		; see if visible drive
	JC	SETRET			; errors do not set
;	LDS	SI,ThisCDS		; get CDS
;	TEST	[SI].curdir_flags,curdir_splice ; was it spliced?
;	JNZ	SetRet			; yes, do not set
	MOV	[CURDRV],AL		; no, set
SETRET:
	MOV	AL,[CDSCOUNT]		; let user see what the count really is
RET17:	return
EndProc $SET_DEFAULT_DRIVE

BREAK <$Get_Interrupt_Vector - Get/Set interrupt vectors>
	procedure   $GET_INTERRUPT_VECTOR,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	AL = interrupt number
; Function:
;	Get the interrupt vector
; Returns:
;	ES:BX is current interrupt vector

	CALL	RECSET
	LES	BX,DWORD PTR ES:[BX]
	invoke	get_user_stack
	MOV	[SI.user_BX],BX
	MOV	[SI.user_ES],ES
	return
EndProc $GET_INTERRUPT_VECTOR

	procedure   $SET_INTERRUPT_VECTOR,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	AL = interrupt number
;	DS:DX is desired new interrupt vector
; Function:
;	Set the interrupt vector
; Returns:
;	None

	CALL	RECSET
	CLI				; Watch out!!!!! Folks sometimes use
	MOV	ES:[BX],DX		;   this for hardware ints (like timer).
	MOV	ES:[BX+2],DS
	STI
	return
EndProc $SET_INTERRUPT_VECTOR

	IF	ALTVECT
TABLE	SEGMENT
VECIN:
; INPUT VECTORS
Public GSET001S,GSET001E
GSET001S  label byte
	DB	22H			; Terminate
	DB	23H			; ^C
	DB	24H			; Hard error
	DB	28H			; Spooler
LSTVEC	DB	?			; ALL OTHER

VECOUT:
; GET MAPPED VECTOR
	DB	int_terminate
	DB	int_ctrl_c
	DB	int_fatal_abort
	DB	int_spooler
LSTVEC2 DB	?			; Map to itself

NUMVEC	=	VECOUT-VECIN
GSET001E label byte
TABLE	ENDS
	ENDIF

procedure   RECSET,NEAR

	IF	ALTVECT
	context ES
	MOV	[LSTVEC],AL		; Terminate list with real vector
	MOV	[LSTVEC2],AL		; Terminate list with real vector
	MOV	CX,NUMVEC		; Number of possible translations
	MOV	DI,OFFSET DOSGROUP:VECIN    ; Point to vectors
	REPNE	SCASB
	MOV	AL,ES:[DI+NUMVEC-1]	; Get translation
	ENDIF

	XOR	BX,BX
	MOV	ES,BX
	MOV	BL,AL
	SHL	BX,1
	SHL	BX,1
	return
EndProc recset

BREAK <$Char_Oper - hack on paths, switches so that xenix can look like PCDOS>
;
; input:    AL = function:
;		    0 - read switch char
;		    1 - set switch char (char in DL)
;		    2 - read device availability
;			Always returns available
;		    3 - set device availability
;			No longer supported (NOP)
; output:   (get) DL - character/flag
;
	procedure   $CHAR_OPER,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING
	context DS
	CMP	AL,1
	JB	CharGetSw
	JZ	CharSetSw
	CMP	AL,3
	JB	CharGetDev
	JZ	CharSetDev
	MOV	AL,-1
	return
CharGetSw:
	MOV	DL,chSwitch
	JMP	SHORT CharSet
CharSetSw:
	MOV	chSwitch,DL
	return
CharGetDev:
	MOV	DL,-1
CharSet:
	Invoke	Get_User_Stack
	ASSUME	DS:NOTHING
	MOV	[SI.User_DX],DX
CharSetDev:
	return
EndProc $CHAR_OPER

BREAK <$GetExtendedError - Return Extended DOS error code>
;
; input:    None
; output:   AX = Extended error code (0 means no extended error)
;	    BL = recommended action
;	    BH = class of error
;	    CH = locus of error
;	    ES:DI = may be pointer
;
	procedure   $GetExtendedError,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING
	Context DS
	MOV	AX,[EXTERR]
	LES	DI,[EXTERRPT]
	MOV	BX,WORD PTR [EXTERR_ACTION]	; BL = Action, BH = Class
	MOV	CH,[EXTERR_LOCUS]
	invoke	get_user_stack
ASSUME	DS:NOTHING
	MOV	[SI.user_DI],DI
	MOV	[SI.user_ES],ES
	MOV	[SI.user_BX],BX
	MOV	[SI.user_CX],CX
	transfer SYS_RET_OK
EndProc $GetExtendedError

BREAK <$Get_Global_CdPg  - Return Global Code Page>
;
; input:    None
; output:   AX = Global Code Page
;
	procedure   Get_Global_CdPg,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING
	PUSH	SI
	MOV	SI,OFFSET DOSGROUP:COUNTRY_CDPG
	MOV	AX,CS:[SI.ccDosCodePage]
	POP	SI
	return
EndProc Get_Global_CdPg

;-------------------------------Start of DBCS 2/13/KK
BREAK	<ECS_call - Extended Code System support function>

ASSUME	DS:NOTHING, ES:NOTHING

	procedure   $ECS_call,NEAR

; Inputs:
;	AL = 0	get lead byte table
;		on return DS:SI has the table location
;
;	AL = 1	set / reset interim console flag
;		DL = flag (00H or 01H)
;		no return
;
;	AL = 2	get interim console flag
;		on return DL = current flag value
;
;	AL = OTHER then error, and returns with:
;		AX = error_invalid_function
;
;  NOTE: THIS CALL DOES GUARANTEE THAT REGISTER OTHER THAN
;	 SS:SP WILL BE PRESERVED!

 IF  DBCS									;AN000;
										;AN000;
	or	al, al			; AL = 0 (get table)?			;AN000;
	je	get_lbt 							;AN000;
	cmp	al, SetInterimMode	; AL = 1 (set / reset interim flag)?	;AN000;
	je	set_interim							;AN000;
	cmp	al, GetInterimMode	; AL = 2 (get interim flag)?		;AN000;
	je	get_interim							;AN000;
	error	error_invalid_function						;AN000;
										;AN000;
get_lbt:				; get lead byte table			;AN000;
	push	ax								;AN000;
	push	bx								;AN000;
	push	ds								;AN000;
	context DS								;AN000;
	MOV	BX,offset DOSGROUP:COUNTRY_CDPG.ccSetDBCS			;AN000;
	MOV	AX,[BX+1]		; set EV address to DS:SI		;AN000;
	MOV	BX,[BX+3]							;AN000;
	ADD	AX,2			; Skip Lemgth				;AN000;
	invoke	get_user_stack							;AN000;
 assume ds:nothing								;AN000;
	MOV	[SI.user_SI], AX						;AN000;
	MOV	[SI.user_DS], BX						;AN000;
	pop	ds								;AN000;
	pop	bx								;AN000;
	pop	ax								;AN000;
	transfer SYS_RET_OK							;AN000;

set_interim:				; Set interim console flag		;AN000;
	push	dx								;AN000;
	and	dl,01			; isolate bit 1 			;AN000;
	mov	[InterCon], dl							;AN000;
	push	ds								;AN000;
	mov	ds, [CurrentPDB]						;AN000;
	mov	byte ptr ds:[PDB_InterCon], dl	; update value in pdb		;AN000;
	pop	ds								;AN000;
	pop	dx								;AN000;
	transfer SYS_RET_OK							;AN000;

get_interim:									;AN000;
	push	dx								;AN000;
	push	ds								;AN000;
	mov	dl,[InterCon]							;AN000;
	invoke	get_user_stack		; get interim console flag		;AN000;
 assume ds:nothing								;AN000;
	mov	[SI.user_DX],DX 						;AN000;
	pop	ds								;AN000;
	pop	dx								;AN000;
	transfer SYS_RET_OK							;AN000;
 ELSE										;AN000;
	or	al, al			; AL = 0 (get table)?  ;AN000;
	jnz	okok					       ;AN000;
get_lbt:						       ;AN000;
	invoke	get_user_stack				       ;AN000;
 assume ds:nothing					       ;AN000;
	MOV	[SI.user_SI], Offset Dosgroup:DBCS_TAB+2       ;AN000;
	MOV	[SI.user_DS], CS			       ;AN000;
okok:							       ;AN000;
	transfer SYS_RET_OK		;		       ;AN000;

 ENDIF							       ;AN000;

$ECS_call endp						       ;AN000;

CODE	ENDS
    END
