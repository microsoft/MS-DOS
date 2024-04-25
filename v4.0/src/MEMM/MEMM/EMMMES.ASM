

	page 58,132
;******************************************************************************
	title	EMMMES - messages for MEMM
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:	EMMMES - messages for MEMM
;
;   Version:	0.05
;
;   Date:	May 24,1986
;
;   Author:
;
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;	05/24/86 Original
;	06/26/86 0.02		changed version #.
;	06/28/86 0.02		Name changed from MEMM386 to MEMM
;	07/06/86 0.04		changed version #.
;	07/06/86 0.04		changed assume to DGROUP
;	07/06/86 0.04		moved some messages to LAST
;	07/08/86 0.04		Changed messages for incorrect machine
;	07/09/86 0.05		changed version displayed version# to 3.20.
;
;******************************************************************************
.lfcond
.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
	public	InitMess
	public	InstallMess
	public	ISizeMess
	public	ExtSizeMess
	public	SysSizeMess
	public	PFBAMess
	public	ActiveMess
	public	InactiveMess
	public	AutoMess
	public	POE_Mess
	public	POE_Num
	public	POE_Len
	public	EXCPE_Mess
	public	EXCPE_Num
	public	EXCPE_CS
	public	EXCPE_EIP
	public	EXCPE_ERR
	public	EXCPE_Len
	public	InvParm
	public	InvPFBA
	public	InvMRA
	public	Adj_Size
	public	InsfMem
	public	Incorrect_DOS
	public	Incorrect_PRT
	public	Already_Inst
	public	PFWarning
	public	No_PF_Avail
	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
	include	ascii_sm.equ
	include	vdmseg.inc

	page
;******************************************************************************
;			S E G M E N T   D E F I N I T I O N
;******************************************************************************

;******************************************************************************
;
;	LAST Segment messages
;
;******************************************************************************
;
LAST	segment

InitMess	db	CR,LF
		db	"MICROSOFT Expanded Memory Manager 386  Version 4.00",CR,LF
		db	"(C) Copyright MICROSOFT Corporation 1988",CR,LF
		db	"$"

InstallMess	db	"EMM386 Installed.", CR,LF
		db	"                   Extended memory allocated:    "
ExtSizeMess	db	"      KB",CR,LF
		db	"                   System memory allocated:      "
SysSizeMess	db	"      KB",CR,LF
		db	"                                                 "
		db	"--------",CR,LF
		db	"                   Expanded memory available:    "
ISizeMess	db	"      KB",CR,LF
		db	"                   Page frame base address:      "
PFBAMess	db	"XX000 H",CR,LF
		db	"$"

ActiveMess	db	"EMM386 Active.",CR,LF
		db	CR,LF
		db	"$"

InactiveMess	db	"EMM386 Inactive.",CR,LF
		db	CR,LF
		db	"$"

AutoMess	db	"EMM386 is in Auto mode.",CR,LF
		db	CR,LF
		db	"$"

;
; install error messages
;

InvParm		db	"Invalid parameter specified.",CR,LF
		db	"$"

InvPFBA		db	"Page Frame Base Address adjusted.",CR,LF
		db	"$"

InvMRA		db	"Mapping Register Address adjusted.",CR,LF
		db	"$"

Adj_Size	db	"Size of expanded memory pool adjusted.",CR,LF
		db	"$"

PFWarning	db	"WARNING - "
		db	"Option ROM or RAM detected within page frame."
		db	CR,LF
		db	CR,LF
		db	BEL
		db	"$"

InsfMem 	db	"EMM386 not installed - insufficient memory.",CR,LF
		db	BEL
		db	CR,LF
		db	"$"

Incorrect_DOS	db	"EMM386 not installed - incorrect DOS version.",CR,LF
		db	BEL
		db	CR,LF
		db	"$"

Incorrect_PRT	db	"EMM386 not installed - incorrect machine type.",CR,LF
		db	BEL
		db	CR,LF
		db	"$"

No_PF_Avail	db	"EMM386 not installed - "
		db	"unable to set page frame base address.",CR,LF
		db	BEL
		db	CR,LF
		db	"$"

Already_Inst	db	"EMM386 already installed.",CR,LF
		db	BEL
		db	CR,LF
		db	"$"

LAST	ends

	page
;******************************************************************************
;
;	_DATA Segment messages
;
;******************************************************************************
;
_DATA	segment

;
; run time error messages
;
POE_Mess	db	CR,LF
		db	BEL
		db	"EMM386 Privileged operation error #"
POE_Num		db	"xx -",CR,LF
		db	"Deactivate EMM386 and Continue (C) or reBoot (B)"
		db	" (C or B) ? "
POE_Len		=	$-POE_Mess
		db	"$"

EXCPE_Mess	db	CR,LF
		db	BEL
		db	"EMM386 Exception error #"
EXCPE_Num	db	"xx @"
EXCPE_CS	db	"xxxx:"
EXCPE_EIP	db	"xxxxxxxx Code "
EXCPE_ERR	db	"xxxx"
		db	CR,LF,"Press enter to reboot"
EXCPE_Len	=	$-EXCPE_Mess
		db	"$"

;
_DATA	ends

	end


