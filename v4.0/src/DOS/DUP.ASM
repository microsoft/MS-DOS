;	SCCSID = @(#)dup.asm	1.1 85/04/10
;	SCCSID = @(#)dup.asm	1.1 85/04/10
TITLE	DOS_DUP - Internal SFT DUP (for network SFTs)
NAME	DOS_DUP
; Low level DUP routine for use by EXEC when creating a new process. Exports
;   the DUP to the server machine and increments the SFT ref count
;
; DOS_DUP
;
;   Modification history:
;
;	Created: ARR 30 March 1983
;

;
; get the appropriate segment definitions
;
.xlist
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
.cref
.list

	i_need	THISSFT,DWORD

BREAK <DOS_DUP -- DUP SFT across network>

; Inputs:
;	[THISSFT] set to the SFT for the file being DUPed
;		(a non net SFT is OK, in this case the ref
;		 count is simply incremented)
; Function:
;	Signal to the devices that alogical open is occurring
; Returns:
;	ES:DI point to SFT
;    Carry clear
;	SFT ref_count is incremented
; Registers modified: None.
; NOTE:
;	This routine is called from $CREATE_PROCESS_DATA_BLOCK at DOSINIT
;	time with SS NOT DOSGROUP. There will be no Network handles at
;	that time.

	procedure   DOS_DUP,NEAR
	ASSUME	ES:NOTHING,SS:NOTHING

	LES	DI,ThisSFT
	Entry	Dos_Dup_Direct
	Assert	ISSFT,<ES,DI>,"DOSDup"
	invoke	IsSFTNet
	JNZ	DO_INC
	invoke	DEV_OPEN_SFT
DO_INC:
	Assert	ISSFT,<ES,DI>,"DOSDup/DoInc"
	INC	ES:[DI.sf_ref_count]	; Clears carry (if this ever wraps
					;   we're in big trouble anyway)
	return

EndProc DOS_DUP

CODE	ENDS
    END
