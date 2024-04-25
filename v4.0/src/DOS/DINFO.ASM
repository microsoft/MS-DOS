;	SCCSID = @(#)dinfo.asm	1.1 85/04/10
;	SCCSID = @(#)dinfo.asm	1.1 85/04/10
TITLE	DISK_INFO - Internal Get Disk Info
NAME	DISK_INFO
; Low level routine for returning disk drive information from a local
;   or NET device
;
; DISK_INFO
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

Installed = TRUE

	i_need	THISCDS,DWORD
	i_need	CURBUF,DWORD
	i_need	EXTERR_LOCUS,BYTE
if debug
	I_need	BugLev,WORD
	I_need	BugTyp,WORD
include bugtyp.asm
endif

Break	<DISK_INFO -- Get Disk Drive Information>

; Inputs:
;	[THISCDS] Points to the Macro List Structure of interest
;		(It MAY NOT be NUL, error not detected)
; Function:
;	Get Interesting Drive Information
; Returns:
;	DX = Number of free allocation units
;	BX = Total Number of allocation units on disk
;	CX = Sector size
;	AL = Sectors per allocation unit
;	AH = FAT ID BYTE
;	Carry set if error (currently user FAILed to I 24)
; Segs except ES preserved, others destroyed

	procedure   DISK_INFO,NEAR
	DOSAssume   CS,<DS>,"Disk_Info"
	ASSUME	ES:NOTHING

	Invoke	TestNet
	JNC	LOCAL_INFO
IF NOT Installed
	transfer NET_DISK_INFO
ELSE
	MOV	AX,(multNET SHL 8) OR 12
	INT	2FH
	return
ENDIF

LOCAL_INFO:
	MOV	[EXTERR_LOCUS],errLOC_Disk
	EnterCrit   critDisk
	invoke	FATREAD_CDS		; perform media check.
	JC	CRIT_LEAVE
	MOV	BX,2
	invoke	UNPACK			; Get first FAT sector into CURBUF
	JC	CRIT_LEAVE
	LDS	SI,[CURBUF]
ASSUME	DS:NOTHING
	MOV	AH,[SI].bufinsiz	; get FAT ID BYTE
	context DS
	MOV	CX,ES:[BP.dpb_max_cluster]
;
; Examine the current free count.  If it indicates that we have an invalid
; count, do the expensive calculation.
;
	MOV	DX,ES:[BP.dpb_free_cnt] ; get free count
	CMP	DX,-1			; is it valid?
	JZ	DoScan
;
; Check to see if it is in a reasonalbe range.	If so, trust it and return.
; Otherwise, we need to blast out an internal error message and then recompute
; the count.
;
	CMP	DX,CX			; is it in a reasonable range?
	JB	GotVal			; yes, trust it.
	fmt	TypInt,LevLog,<"Internal error: MaxClus <= FreeClus\n">
DoScan:
	XOR	DX,DX
	DEC	CX
SCANFREE:
	invoke	UNPACK
	JC	Crit_Leave
	JNZ	NOTFREECLUS
	INC	DX			; A free one
NOTFREECLUS:
	INC	BX			; Next cluster
	LOOP	SCANFREE
	DEC	BX			; BX was next cluster.	Convert to
ReturnVals:
	DEC	BX			; count
	MOV	AL,ES:[BP.dpb_cluster_mask]
	INC	AL			; Sectors/cluster
	MOV	CX,ES:[BP.dpb_sector_size]  ; Bytes/sector
	MOV	ES:[BP.dpb_free_cnt],DX
	CLC
CRIT_LEAVE:
	LeaveCrit   critDisk
	return
;
; We have correctly computed everything previously.  Load up registers for
; return.
;
GotVal: MOV	BX,CX			; get cluster count
	JMP	ReturnVals

EndProc DISK_INFO

CODE	ENDS
    END
