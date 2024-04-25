;	SCCSID = @(#)disk.asm	1.1 85/04/10
;	SCCSID = @(#)disk.asm	1.1 85/04/10
TITLE	DISK - Disk utility routines
NAME	Disk
; Low level Read and write routines for local SFT I/O on files and devs
;
;   SWAPCON
;   SWAPBACK
;   DOS_READ
;   DOS_WRITE
;   get_io_sft
;   DirRead
;   FIRSTCLUSTER
;   SET_BUF_AS_DIR
;   FATSecRd
;   DREAD
;   CHECK_WRITE_LOCK
;   CHECK_READ_LOCK
;
;   Revision history:
;
;	A000   version 4.00  Jan. 1988
;

;
; get the appropriate segment definitions
;
.xlist
include dosseg.asm
include fastseek.inc				;AN000;
include fastxxxx.inc				;AN000;

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
include version.inc
.cref
.list

Installed = TRUE

	I_need	DirStart,WORD
	I_Need	CONSft,DWORD		; SFT for swapped console In/Out
	i_need	CONSWAP,BYTE
	i_need	IDLEINT,BYTE
	i_need	THISSFT,DWORD
	i_need	DMAADD,DWORD
	i_need	DEVCALL,BYTE
	i_need	CALLSCNT,WORD
	i_need	CALLXAD,DWORD
	i_need	CONTPOS,WORD
	i_need	NEXTADD,WORD
	i_need	CONBUF,BYTE
	i_need	ClusFac,BYTE
	i_need	SecClusPos,BYTE
	i_need	DirSec,DWORD		     ;AN000;
	i_need	ClusNum,WORD
	i_need	NxtClusNum,WORD
	i_need	ReadOp,BYTE
	i_need	CURBUF,DWORD
	i_need	ALLOWED,BYTE
	i_need	EXTERR_LOCUS,BYTE
	i_need	FastSeekflg,BYTE	     ;AN000;
	i_need	HIGH_SECTOR,WORD	     ;AN000;
	I_need	JShare,DWORD		     ;AN000;
	i_need	DOS34_FLAG,WORD 	     ;AN000;

IF	BUFFERFLAG

	i_need	BUF_EMS_MODE,BYTE
	i_need  BUF_EMS_LAST_PAGE,BYTE
	I_need	BUF_EMS_FIRST_PAGE,DWORD
	I_need	BUF_EMS_SAFE_FLAG,BYTE
	I_need	BUF_EMS_NPA640,WORD
	I_need	BUF_EMS_PAGE_FRAME,WORD
	I_need	BUF_EMS_PFRAME,WORD
	I_need	LASTBUFFER,DWORD

	extrn	save_user_map:near
	extrn	restore_user_map:near
	extrn	Setup_EMS_Buffers:near

ENDIF

Break	<SwapCon, Swap Back - Old-style I/O to files>
; * * * * Drivers for file input from devices * * * *

;   Indicate that ther is no more I/O occurring through another SFT outside of
;   handles 0 and 1
;
;   Inputs:	DS is DOSGroup
;   Outputs:	CONSWAP is set to false.
;   Registers modified: none

	procedure   SWAPBACK,NEAR
	DOSAssume   CS,<DS>,"SwapBack"
	ASSUME	ES:NOTHING
	MOV	BYTE PTR [CONSWAP],0	; signal no conswaps
	return
EndProc SWAPBACK

;   Copy ThisSFT to CONSFT for use by the 1-12 primitives.
;
;   Inputs:	ThisSFT as the sft of the desired file
;		DS is DOSGroup
;   Outputs:	CONSWAP is set.  CONSFT = ThisSFT.
;   Registers modified: none
	procedure   SWAPCON,NEAR
	DOSAssume   CS,<DS>,"SwapCon"
	ASSUME	ES:NOTHING
	SaveReg <ES,DI>
	MOV	BYTE PTR [CONSWAP],1	;   CONSwap = TRUE;
	LES	DI,ThisSFT
	Assert	ISSFT,<ES,DI>,"SwapCon"
	MOV	WORD PTR CONSFT,DI
	MOV	WORD PTR CONSFT+2,ES
	RestoreReg  <DI,ES>
	return
EndProc SWAPCON

Break	<DOS_READ -- MAIN READ ROUTINE AND DEVICE IN ROUTINES>

;
; Inputs:
;	[THISSFT] set to the SFT for the file being used
;	[DMAADD] contains transfer address
;	CX = No. of bytes to read
; Function:
;	Perform read operation
; Outputs:
;    Carry clear
;	SFT Position and cluster pointers updated
;	CX = No. of bytes read
;	ES:DI point to SFT
;    Carry set
;	AX is error code
;	CX = 0
;	ES:DI point to SFT
; DS preserved, all other registers destroyed

	procedure   DOS_READ,NEAR
	DOSAssume   CS,<DS>,"DOS_Read"
	ASSUME	ES:NOTHING

IF	BUFFERFLAG
	cmp	[BUF_EMS_MODE], -1
	jz	dos_rd_call
	call	choose_buf_page
	jnc	sav_map_rd_hndl
	return
sav_map_rd_hndl:
;	call	save_user_map
dos_rd_call:
ENDIF
	

	LES	DI,[THISSFT]
	Assert	ISSFT,<ES,DI>,"DOS_Read"
;
; Verify that the sft has been opened in a mode that allows reading.
;
	MOV	AL,BYTE PTR ES:[DI.sf_mode]
	AND	AL,access_mask
	CMP	AL,open_for_write
	JNE	READ_NO_MODE		;Is read or both
	transfer   SET_ACC_ERR

READ_NO_MODE:
	invoke	SETUP
	JCXZ	NoIORet 		; no bytes to read - fast return
	invoke	IsSFTNet
	JZ	LOCAL_READ

;	invoke	OWN_SHARE		;AN000;;IFS. IFS owns share ?
;	JZ	IFS_HAS_SHARE		;AN000;;IFS. yes
;	EnterCrit   critDisk		;AN000;;IFS. enter critical section
;	CALL	CHECK_READ_LOCK 	;AN000;;IFS. check read lock
;	JNC	READ_OK2		;AN000;;IFS. lock check ok
;	JMP	SHORT critexit		;AN000;;IFS. fail
READ_OK2:				;AN000;
;	LeaveCrit   critDisk		;AN000;;IFS. leave critical section
IFS_HAS_SHARE:				;AN000;

IF NOT Installed
	transfer NET_READ
ELSE
	MOV	AX,(multNET SHL 8) OR 8
	INT	2FH
	return
ENDIF

;
; The user ended up requesting 0 bytes of input.  We do nothing for this case
; except return immediately.
;
NoIORet:
	CLC
	return

LOCAL_READ:
	TEST	ES:[DI.sf_flags],devid_device  ; Check for named device I/O
	JNZ	READDEV
	MOV	[EXTERR_LOCUS],errLOC_Disk
	EnterCrit   critDisk
	TEST	[FastSeekflg],Fast_yes	       ; FastSeek installed ?
	JZ	FS_no			       ; no
	OR	[FastSeekflg],FS_begin	       ; set fastseek mode
FS_no:
	invoke	DISKREAD
	PUSHF				      ; save flag
	AND	CS:[FastSeekflg],FS_end       ; reset fastseek mode
	POPF				      ; retore flag
critexit:
	LeaveCrit   critDisk
	return

;
; We are reading from a device.  Examine the status of the device to see if we
; can short-circuit the I/O.  If the device in the EOF state or if it is the
; null device, we can safely indicate no transfer.
;
READDEV:
	DOSAssume   CS,<DS>,"DISK/ReadDev"
	ASSUME	ES:NOTHING
	MOV	[EXTERR_LOCUS],errLOC_SerDev
	MOV	BL,BYTE PTR ES:[DI.sf_flags]
	LES	DI,[DMAADD]
	TEST	BL,devid_device_EOF	; End of file?
	JZ	ENDRDDEVJ3
	TEST	BL,devid_device_null	; NUL device?
	JZ	TESTRAW 		; NO
	XOR	AL,AL			; Indicate EOF by setting zero
ENDRDDEVJ3:
	JMP	ENDRDDEVJ2

;
; We need to hit the device.  Figure out if we do a raw read or we do the
; bizarre std_con_string_input.
;
TESTRAW:
	TEST	BL,devid_device_raw	; Raw mode?
	JNZ	DVRDRAW 		; Yes, let the device do all local editing
	TEST	BL,devid_device_con_in	; Is it console device?
	JZ	NOTRDCON
	JMP	READCON

DVRDRAW:
	DOSAssume   CS,<DS>,"DISK/DvRdRaw"
	PUSH	ES
	POP	DS			; Xaddr to DS:DI
ASSUME	DS:NOTHING
ReadRawRetry:
	MOV	BX,DI			; DS:BX transfer addr
	XOR	AX,AX			; Media Byte, unit = 0
	MOV	DX,AX			; Start at 0
	invoke	SETREAD
	PUSH	DS			; Save Seg part of Xaddr
	LDS	SI,[THISSFT]
	Assert	ISSFT,<DS,SI>,"DOS_Read/DvRdRawR"
	invoke	DEVIOCALL
	MOV	DX,DI			; DS:DX is preserved by INT 24
	MOV	AH,86H			; Read error
	MOV	DI,[DEVCALL.REQSTAT]
	TEST	DI,STERR
	JZ	CRDROK			; No errors
	invoke	CHARHARD
	MOV	DI,DX			; DS:DI is Xaddr
	OR	AL,AL
	JZ	CRDROK			; Ignore
	CMP	AL,3
	JZ	CRDFERR 		; fail.
	POP	DS			; Recover saved seg part of Xaddr
	JMP	ReadRawRetry		; Retry

;
; We have encountered a device-driver error.  We have informed the user of it
; and he has said for us to fail the system call.
;
CRDFERR:
	POP	DI			; Clean stack
DEVIOFERR:
	LES	DI,[THISSFT]
	Assert	ISSFT,<ES,DI>,"DOS_Read/DEVIOFERR"
	transfer    SET_ACC_ERR_DS

CRDROK:
	POP	DI			; Chuck saved seg of Xaddr
	MOV	DI,DX
	ADD	DI,[CALLSCNT]		; Amount transferred
	JMP	SHORT ENDRDDEVJ3

; We are going to do a cooked read on some character device.  There is a
; problem here, what does the data look like?  Is it a terminal device, line
; CR line CR line CR, or is it file data, line CR LF line CR LF?  Does it have
; a ^Z at the end which is data, or is the ^Z not data?  In any event we're
; going to do this:  Read in pieces up to CR (CRs included in data) or ^z (^z
; included in data).  this "simulates" the way con works in cooked mode
; reading one line at a time.  With file data, however, the lines will look
; like, LF line CR.  This is a little weird.

NOTRDCON:
	MOV	AX,ES
	MOV	DS,AX
ASSUME	DS:NOTHING
	MOV	BX,DI
	XOR	DX,DX
	MOV	AX,DX
	PUSH	CX
	MOV	CX,1
	invoke	SETREAD
	POP	CX
	LDS	SI,[THISSFT]
	Assert	ISSFT,<DS,SI>,"DOS_Read/NotRdCon"
	LDS	SI,[SI.sf_devptr]
DVRDLP:
	invoke	DSKSTATCHK
	invoke	DEVIOCALL2
	PUSH	DI		; Save "count" done
	MOV	AH,86H
	MOV	DI,[DEVCALL.REQSTAT]
	TEST	DI,STERR
	JZ	CRDOK
	invoke	CHARHARD
	POP	DI
	MOV	[CALLSCNT],1
	CMP	AL,1
	JZ	DVRDLP			;Retry
	CMP	AL,3
	JZ	DEVIOFERR		; FAIL
	XOR	AL,AL			; Ignore, Pick some random character
	JMP	SHORT DVRDIGN

CRDOK:
	POP	DI
	CMP	[CALLSCNT],1
	JNZ	ENDRDDEVJ2
	PUSH	DS
	MOV	DS,WORD PTR [CALLXAD+2]
	MOV	AL,BYTE PTR [DI]	; Get the character we just read
	POP	DS
DVRDIGN:
	INC	WORD PTR [CALLXAD]	; Next character
	MOV	[DEVCALL.REQSTAT],0
	INC	DI			; Next character
	CMP	AL,1AH			; ^Z?
	JZ	ENDRDDEVJ2		; Yes, done zero set (EOF)
	CMP	AL,c_CR 		; CR?
	LOOPNZ	DVRDLP			; Loop if no, else done
	INC	AX			; Resets zero flag so NOT EOF, unless
					;  AX=FFFF which is not likely
ENDRDDEVJ2:
	JMP	SHORT ENDRDDEV

ASSUME	DS:NOTHING,ES:NOTHING

TRANBUF:
	LODSB
	STOSB
	CMP	AL,c_CR 	; Check for carriage return
	JNZ	NORMCH
	MOV	BYTE PTR [SI],c_LF
NORMCH:
	CMP	AL,c_LF
	LOOPNZ	TRANBUF
	JNZ	ENDRDCON
	XOR	SI,SI		; Cause a new buffer to be read
	invoke	OUTT		; Transmit linefeed
	OR	AL,1		; Clear zero flag--not end of file
ENDRDCON:
	Context DS
	CALL	SWAPBACK
	MOV	[CONTPOS],SI
ENDRDDEV:
	Context DS
	MOV	[NEXTADD],DI
	JNZ	SETSFTC 	; Zero set if Ctrl-Z found in input
	LES	DI,[THISSFT]
	Assert	ISSFT,<ES,DI>,"DOS_Read/EndRdDev"
	AND	BYTE PTR ES:[DI.sf_flags],NOT devid_device_EOF ; Mark as no more data available
SETSFTC:
	invoke	SETSFT
	return

ASSUME	DS:NOTHING,ES:NOTHING

READCON:
	DOSAssume   CS,<DS>,"ReadCon"
	CALL	SWAPCON
	MOV	SI,[CONTPOS]
	OR	SI,SI
	JNZ	TRANBUF
	CMP	BYTE PTR [CONBUF],128
	JZ	GETBUF
	MOV	WORD PTR [CONBUF],0FF80H	; Set up 128-byte buffer with no template
GETBUF:
	PUSH	CX
	PUSH	ES
	PUSH	DI
	MOV	DX,OFFSET DOSGROUP:CONBUF
	invoke	$STD_CON_STRING_INPUT		; Get input buffer
	POP	DI
	POP	ES
	POP	CX
	MOV	SI,2 + OFFSET DOSGROUP:CONBUF
	CMP	BYTE PTR [SI],1AH	; Check for Ctrl-Z in first character
	JNZ	TRANBUF
	MOV	AL,1AH
	STOSB
	DEC	DI
	MOV	AL,c_LF
	invoke	OUTT		; Send linefeed
	XOR	SI,SI
	JMP	ENDRDCON

EndProc DOS_READ

Break	<DOS_WRITE -- MAIN WRITE ROUTINE AND DEVICE OUT ROUTINES>

;
; Inputs:
;	[THISSFT] set to the SFT for the file being used
;	[DMAADD] contains transfer address
;	CX = No. of bytes to write
; Function:
;	Perform write operation
;	NOTE: If CX = 0 on input, file is truncated or grown
;		to current sf_position
; Outputs:
;    Carry clear
;	SFT Position and cluster pointers updated
;	CX = No. of bytes written
;	ES:DI point to SFT
;    Carry set
;	AX is error code
;	CX = 0
;	ES:DI point to SFT
; DS preserved, all other registers destroyed

	procedure   DOS_WRITE,NEAR
	DOSAssume   CS,<DS>,"DOS_Write"
	ASSUME	ES:NOTHING

IF	BUFFERFLAG
	cmp	[BUF_EMS_MODE], -1
	jz	dos_wrt_call
	call	choose_buf_page
	jnc	sav_map_wrt_hndl
	return
sav_map_wrt_hndl:
;	call	save_user_map
dos_wrt_call:
ENDIF


	LES	DI,[THISSFT]
	Assert	ISSFT,<ES,DI>,"DosWrite"
	MOV	AL,BYTE PTR ES:[DI.sf_mode]
	AND	AL,access_mask
	CMP	AL,open_for_read
	JNE	Check_FCB_RO		 ;Is write or both
BadMode:
	transfer    SET_ACC_ERR

;
; NOTE: The following check for writting to a Read Only File is performed
;	    ONLY on FCBs!!!!
;	We ALLOW writes to Read Only files via handles to allow a CREATE
;	    of a read only file which can then be written to.
;	This is OK because we are NOT ALLOWED to OPEN a RO file via handles
;	    for writting, or RE-CREATE an EXISTING RO file via handles. Thus,
;	    CREATing a NEW RO file, or RE-CREATing an existing file which
;	    is NOT RO to be RO, via handles are the only times we can write
;	    to a read-only file.
;
Check_FCB_RO:
	TEST	ES:[DI.sf_mode],sf_isfcb
	JZ	WRITE_NO_MODE		; Not an FCB
	TEST	ES:[DI].sf_attr,attr_read_only
	JNZ	BadMode 		; Can't write to Read_Only files via FCB
WRITE_NO_MODE:
	invoke	SETUP
	invoke	IsSFTNet
	JZ	LOCAL_WRITE

;	invoke	OWN_SHARE		;AN000;;IFS. IFS owns share ?
;	JZ	IFS_HAS_SHARE2		;AN000;;IFS. yes
;	EnterCrit   critDisk		;AN000;;IFS. enter critical section
;	CALL	CHECK_WRITE_LOCK	;AN000;;IFS. check write lock
;	JC	nocommit		;AN000;;IFS. lock error
;
;	LeaveCrit   critDisk		;AN000;;IFS. leave critical section
IFS_HAS_SHARE2: 			;AN000;


IF NOT Installed
	transfer NET_WRITE
ELSE
	MOV	AX,(multNET SHL 8) OR 9
	INT	2FH
;	JC	nomore		       ;AN000;;IFS. error
;	invoke	OWN_SHARE	       ;AN000;;IFS. IFS owns share ?
;	JZ	nomore		       ;AN000;;IFS. yes
;
;	MOV	AX,1		       ;AN000;;IFS. update all SFT for new size
;	call	JShare + 14 * 4        ;AN000;;IFS. call ShSu

nomore: 			       ;AN000;
	return
ENDIF


LOCAL_WRITE:
	TEST	ES:[DI.sf_flags],devid_device  ; Check for named device I/O
	JNZ	WRTDEV
	MOV	[EXTERR_LOCUS],errLOC_Disk
	EnterCrit   critDisk
	TEST	[FastSeekflg],Fast_yes	       ;AN000;FO. FastSeek installed ?
	JZ	FS_no2			       ;AN000;FO. no
	OR	[FastSeekflg],FS_begin	       ;AN000;FO. set fastseek mode
FS_no2: 				       ;AN000;
	invoke	DISKWRITE
	PUSHF				       ;AN000;FO. save flag
	AND	CS:[FastSeekflg],FS_end        ;AN000;FO. reset fastseek mode
	POPF				       ;AN000;FO. restore flag
;; Extended Open
	JC	nocommit		       ;AN000;EO.
	LES	DI,[THISSFT]		       ;AN000;EO.
	TEST	ES:[DI.sf_mode],auto_commit_write ;AN000;EO.
	JZ	nocommit		       ;AN000;EO.
	PUSH	CX			       ;AN000;EO.
	invoke	DOS_COMMIT		       ;AN000;EO.
	POP	CX			       ;AN000;EO.
nocommit:				       ;AN000;
;; Extended Open
	LeaveCrit   critDisk
	return

DVWRTRAW:
ASSUME	DS:NOTHING
	XOR	AX,AX			; Media Byte, unit = 0
	invoke	SETWRITE
	PUSH	DS			; Save seg of transfer
	LDS	SI,[THISSFT]
	Assert	ISSFT,<DS,SI>,"DosWrite/DvWrtRaw"
	invoke	DEVIOCALL		; DS:SI -> DEVICE
	MOV	DX,DI			; Offset part of Xaddr saved in DX
	MOV	AH,87H
	MOV	DI,[DEVCALL.REQSTAT]
	TEST	DI,STERR
	JZ	CWRTROK
	invoke	CHARHARD
	MOV	BX,DX			; Recall transfer addr
	OR	AL,AL
	JZ	CWRTROK 		; Ignore
	CMP	AL,3
	JZ	CWRFERR
	POP	DS			; Recover saved seg of transfer
	JMP	DVWRTRAW		; Try again

CWRFERR:
	POP	AX			; Chuck saved seg of transfer
	JMP	CRDFERR 		; Will pop one more stack element

CWRTROK:
	POP	AX			; Chuck saved seg of transfer
	POP	DS
	DOSAssume   CS,<DS>,"DISK/CWrtOK"
	MOV	AX,[CALLSCNT]		; Get actual number of bytes transferred
ENDWRDEV:
	LES	DI,[THISSFT]
	Assert	ISSFT,<ES,DI>,"DosWrite/EndWrDev"
	MOV	CX,AX
	invoke	ADDREC
	return

WRTNUL:
	MOV	DX,CX			;Entire transfer done
WrtCookJ:
	JMP	WRTCOOKDONE

WRTDEV:
	DOSAssume   CS,<DS>,"DISK/WrtDev"
	MOV	[EXTERR_LOCUS],errLOC_SerDev
	OR	BYTE PTR ES:[DI.sf_flags],devid_device_EOF  ; Reset EOF for input
	MOV	BL,BYTE PTR ES:[DI.sf_flags]
	XOR	AX,AX
	JCXZ	ENDWRDEV		; problem of creating on a device.
	PUSH	DS
	MOV	AL,BL
	LDS	BX,[DMAADD]		; Xaddr to DS:BX
ASSUME	DS:NOTHING
	MOV	DI,BX			; Xaddr to DS:DI
	XOR	DX,DX			; Set starting point
	TEST	AL,devid_device_raw	; Raw?
	JZ	TEST_DEV_CON
	JMP	DVWRTRAW

TEST_DEV_CON:
	TEST	AL,devid_device_con_out ; Console output device?
	JNZ	WRITECON
	TEST	AL,devid_device_null
	JNZ	WRTNUL
	MOV	AX,DX
	CMP	BYTE PTR [BX],1AH	; ^Z?
	JZ	WRTCOOKJ		; Yes, transfer nothing
	PUSH	CX
	MOV	CX,1
	invoke	SETWRITE
	POP	CX
	LDS	SI,[THISSFT]
	OR	CS:[DOS34_FLAG],X25_Special;AN000;;PTM. bad x25 driver
	MOV	AH,3			;AN000;;PTM. prompt critical error ASAP
	invoke	IOFUNC			;AN000;;PTM.
	Assert	ISSFT,<DS,SI>,"DosWrite/TestDevCon"
	LDS	SI,[SI.sf_devptr]
DVWRTLP:
	invoke	DSKSTATCHK
	invoke	DEVIOCALL2
	PUSH	DI
	MOV	AH,87H
	MOV	DI,[DEVCALL.REQSTAT]
	TEST	DI,STERR
	JZ	CWROK
	invoke	CHARHARD
	POP	DI
	MOV	[CALLSCNT],1
	CMP	AL,1
	JZ	DVWRTLP 	; Retry
	OR	AL,AL
	JZ	DVWRTIGN	; Ignore
	JMP	CRDFERR 	; Fail, pops one stack element

CWROK:
	POP	DI
	CMP	[CALLSCNT],0
	JZ	WRTCOOKDONE
DVWRTIGN:
	INC	DX
	INC	WORD PTR [CALLXAD]
	INC	DI
	PUSH	DS
	MOV	DS,WORD PTR [CALLXAD+2]
	CMP	BYTE PTR [DI],1AH	; ^Z?
	POP	DS
	JZ	WRTCOOKDONE
	MOV	[DEVCALL.REQSTAT],0
	LOOP	DVWRTLP
WRTCOOKDONE:
	MOV	AX,DX
	POP	DS
	JMP	ENDWRDEV

WRITECON:
	PUSH	DS
	Context DS
	CALL	SWAPCON
	POP	DS
ASSUME	DS:NOTHING
	MOV	SI,BX
	PUSH	CX
WRCONLP:
	LODSB
	CMP	AL,1AH		; ^Z?
	JZ	CONEOF
	invoke	OUTT
	LOOP	WRCONLP
CONEOF:
	POP	AX			; Count
	SUB	AX,CX			; Amount actually written
	POP	DS
	DOSAssume   CS,<DS>,"DISK/ConEOF"
	CALL	SWAPBACK
	JMP	ENDWRDEV
EndProc DOS_WRITE

;   Convert JFN number in BX to sf_entry in DS:SI We get the normal SFT if
;   CONSWAP is FALSE or if the handle desired is 2 or more.  Otherwise, we
;   retrieve the sft from ConSFT which is set by SwapCon.

	procedure   get_io_sft,near
ASSUME	DS:NOTHING,ES:NOTHING
	TEST	ConSwap,-1
	JNZ	GetRedir
GetNormal:
	Context DS
	PUSH	ES
	PUSH	DI
	invoke	SFFromHandle
	JC	RET44P
	MOV	SI,ES
	MOV	DS,SI
ASSUME	DS:NOTHING
	MOV	SI,DI
RET44P:
	POP	DI
	POP	ES
	return
GetRedir:
	CMP	BX,1
	JA	GetNormal
	LDS	SI,ConSFT
	Assert	ISSFT,<DS,SI>,"GetIOSft"
	CLC
	return
EndProc get_io_sft

Break	<DIRREAD -- READ A DIRECTORY SECTOR>

; Inputs:
;	AX = Directory block number (relative to first block of directory)
;	ES:BP = Base of drive parameters
;	[DIRSEC] = First sector of first cluster of directory
;	[CLUSNUM] = Next cluster
;	[CLUSFAC] = Sectors/Cluster
; Function:
;	Read the directory block into [CURBUF].
; Outputs:
;	[NXTCLUSNUM] = Next cluster (after the one skipped to)
;	[SECCLUSPOS] Set
;	ES:BP unchanged
;	[CURBUF] Points to Buffer with dir sector
;	Carry set if error (user said FAIL to I 24)
; DS preserved, all other registers destroyed.

	procedure   DirRead,NEAR
	DOSAssume   CS,<DS>,"DirRead"
	ASSUME	ES:NOTHING
	Assert	    ISDPB,<ES,BP>,"DirRead"

;
; Note that ClusFac is is the sectors per cluster.  This is NOT necessarily
; the same as what is in the DPB!  In the case of the root directory, we have
; ClusFac = # sectors in the root directory.  The root directory is detected
; by DIRStart = 0.
;
	XOR	DX,DX
	CMP	DirStart,0
	jnz	SubDir
	XCHG	AX,DX
	JMP	DoRead
;
; Convert the sector number in AX into cluster and sector-within-cluster pair
;
SubDir:
	MOV	DL,AL
	AND	DL,ES:[BP.dpb_cluster_mask]
;
; DX is the sector-in-cluster
;
	MOV	CL,ES:[BP.dpb_cluster_shift]
	SHR	AX,CL
;
; DX is position in cluster
; AX is number of clusters to skip
;
DoRead:
	MOV	[SECCLUSPOS],DL
	MOV	CX,AX
	MOV	AH,DL
;
; CX is number of clusters to skip.
; AH is remainder
;
	MOV	DX,WORD PTR [DIRSEC+2]	     ;AN000;>32mb
	MOV	[HIGH_SECTOR],DX	     ;AN000;>32mb
	MOV	DX,WORD PTR [DIRSEC]
	ADD	DL,AH
	ADC	DH,0
	ADC	[HIGH_SECTOR],0 	     ;AN000;>32mb

	MOV	BX,[CLUSNUM]
	MOV	[NXTCLUSNUM],BX
	JCXZ	FIRSTCLUSTER
SKPCLLP:
	invoke	UNPACK
	retc
	XCHG	BX,DI
	invoke	IsEOF			; test for eof based on fat size
	JAE	HAVESKIPPED
	LOOP	SKPCLLP
HAVESKIPPED:
	MOV	[NXTCLUSNUM],BX
	MOV	DX,DI
	MOV	BL,AH
	invoke	FIGREC

	entry	FIRSTCLUSTER

	MOV	[ALLOWED],allowed_RETRY + allowed_FAIL
	XOR	AL,AL		; Indicate pre-read
	invoke	GETBUFFR
	retc

	entry	SET_BUF_AS_DIR
	DOSAssume   CS,<DS>,"SET_BUF_AS_DIR"
	ASSUME	ES:NOTHING
; Set the type of CURBUF to be a directory sector.
; Only flags are modified.

	PUSH	DS
	PUSH	SI
	LDS	SI,[CURBUF]
	Assert	ISBUF,<DS,SI>,"SetBufAsDir"
	OR	[SI.buf_flags],buf_isDIR	; Clears carry
	POP	SI
	POP	DS
	return
EndProc DirRead

Break	<FATSECRD -- READ A FAT SECTOR>

; Inputs:
;	Same as DREAD
;	DS:BX = Transfer address
;	CX = Number of sectors
;	DX = Absolute record number
;	ES:BP = Base of drive parameters
; Function:
;	Calls BIOS to perform FAT read.
; Outputs:
;	Same as DREAD

	procedure   FATSecRd,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	Assert	    ISDPB,<ES,BP>,"FATSecRd"
	MOV	[ALLOWED],allowed_RETRY + allowed_FAIL
	MOV	DI,CX
	MOV	CL,ES:[BP.dpb_FAT_count]
	MOV	AX,ES:[BP.dpb_FAT_size] 	;AN000;>32mb
;	XOR	AH,AH
	XOR	CH,CH				;AN000;>32mb
	PUSH	DX
NXTFAT:
	MOV	[HIGH_SECTOR],0       ;AN000;>32mb FAT sectors cannot exceed
	PUSH	CX		      ;AN000;>32mb
	PUSH	AX
	MOV	CX,DI
	invoke	DSKREAD
	POP	AX
	POP	CX
	JZ	RET41P		; Carry clear
	ADD	DX,AX
	LOOP	NXTFAT
	POP	DX
	MOV	CX,DI

; NOTE FALL THROUGH

Break	<DREAD -- DO A DISK READ>

; Inputs:
;	DS:BX = Transfer address
;	CX = Number of sectors
;	DX = Absolute record number	      (LOW)
;	[HIGH_SECTOR]= Absolute record number (HIGH)
;	ES:BP = Base of drive parameters
;	[ALLOWED] must be set in case call to HARDERR needed
; Function:
;	Calls BIOS to perform disk read. If BIOS reports
;	errors, will call HARDERRRW for further action.
; Outputs:
;	Carry set if error (currently user FAILED to INT 24)
; DS,ES:BP preserved. All other registers destroyed.

	entry	DREAD
ASSUME	DS:NOTHING,ES:NOTHING

	Assert	ISDPB,<ES,BP>,"DREAD"
	invoke	DSKREAD
	retz			; Carry clear
	MOV	BYTE PTR [READOP],0
	invoke	HARDERRRW
	CMP	AL,1		; Check for retry
	JZ	DREAD
	CMP	AL,3		; Check for FAIL
	CLC
	JNZ	NO_CAR		; Ignore
	STC
NO_CAR:
	return

RET41P: POP	DX
	return
EndProc FATSecRd


Break	<CHECK_WRITE_LOCK>

; Inputs:
;	output of SETUP
;	ES:DI -> SFT
; Function:
;	check write lock
; Outputs:
;	Carry set if error
;	Carry clear if ok

	procedure   CHECK_WRITE_LOCK,NEAR      ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING		       ;AN000;

	TEST	ES:[DI].sf_attr,attr_volume_id ;AN000;;MS.  volume id
	JZ	write_cont		       ;AN000;;MS.  no
	invoke	SET_ACC_ERR_DS		       ;AN000;;MS.
	return				;AN000;;MS.
write_cont:				;AN000;
	PUSH	CX			;AN000;;MS. save reg
	OR	CX,CX			;AN000;;MS.
	JNZ	Not_Truncate		;AN000;;MS.
	MOV	CX,0FFFFH		;AN000;;MS. check for lock on whole file
Not_Truncate:				;AN000;
	MOV	AL,80H			;AN000;;MS. check write access
	invoke	LOCK_CHECK		;AN000;;MS. check lock
	POP	CX			;AN000;;MS. restore reg
	JNC	WRITE_OK		;AN000;;MS. lock ok
	invoke	WRITE_LOCK_VIOLATION	;AN000;;MS. issue I24
	JNC	CHECK_WRITE_LOCK	;AN000;;MS. retry
WRITE_OK:				;AN000;
	return				;AN000;;MS.
EndProc CHECK_WRITE_LOCK		;AN000;


Break	<CHECK_READ_LOCK>

; Inputs:
;	ES:DI -> SFT
;	output of SETUP
; Function:
;	check read lock
; Outputs:
;	Carry set if error
;	Carry clear if ok

	procedure   CHECK_READ_LOCK,NEAR       ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING		       ;AN000;

	TEST	ES:[DI].sf_attr,attr_volume_id ;AN000;;MS.  volume id
	JZ	do_retry		       ;AN000;;MS.  no
	invoke	SET_ACC_ERR		       ;AN000;;MS.
	return				       ;AN000;;MS.
do_retry:				;AN000;
	MOV	AL,0			;AN000;;MS. check read access
	invoke	LOCK_CHECK		;AN000;;MS. check lock
	JNC	READ_OK 		;AN000;;MS. lock ok
	invoke	READ_LOCK_VIOLATION	;AN000;;MS. issue I24
	JNC	CHECK_READ_LOCK 	;AN000;;MS. retry
READ_OK:				;AN000; MS.
	return				;AN000;;MS.
EndProc CHECK_READ_LOCK 		;AN000;

IF BUFFERFLAG

;-------------------------------------------------------------------------
;	Function name	: 	choose_buf_page
;	Inputs		:	DMAADD = Xaddr
;				cx = # of bytes to transfer
;	Outputs		:	if NC
;
;				SAFE_FLAG - 0 ==> page is safe. no need to
;						  detect collision between
;						  user & system buffer.
;				SAFE_FLAG - 1 ==> page is unsafe. Must check
;						  for collision
;
;				CY - error
;
;
;	High Level Alogrithm:
;
;	1. If Xaddr. is above the first physical page above 640K
;	   2. choose that page
;	   3. set safe flag
;	4. else
;	   5. choose highest page above 640K
;	   6. If 6 or more pages above 640k
;	      7. Set safe flag				
;	   8. else
;	      9. if Xaddr. + # of bytes to transfer does not spill into the
;	     	 chosen page
;		 10. set safe flag
;	      11.else
;		 12. clear safe flag
;	      13.endif
;	   14.endif
;	15.endif
;
;----------------------------------------------------------------------------
Procedure 	choose_buf_page,near

	assume cs:dosgroup, ds:nothing, es:nothing, ss:dosgroup

	push	cx
	push	bx
	push	dx
	push	si
	push	ds
	push	ax

	mov	ax, word ptr [DMAADD+2]
	and	ax, 0fc00h  	; page segment of transfer segment

	cmp	ax, word ptr [BUF_EMS_FIRST_PAGE]
	ja	pick_first
	
	cmp	[BUF_EMS_NPA640], 6
	jae	safe_pick_last

	add	cx, word ptr [DMAADD]	; get final offset 
	mov	bx, cx

	mov	cl, 4
	shr	bx, cl		; get # of paragraphs
	mov	ax, word ptr [DMAADD+2]	; get initial segment
	add	ax, bx		; get final segment

	and	ax, 0fc00h
	cmp	ax, word ptr [BUF_EMS_LAST_PAGE]
	jne	safe_pick_last

	mov	[BUF_EMS_SAFE_FLAG], 0
	jmp	fin_choose_page

safe_pick_last:
	mov	[BUF_EMS_SAFE_FLAG], 1
	jmp	fin_choose_page

;pick_last:
;	mov	ax, word ptr [BUF_EMS_LAST_PAGE]
;	mov	[BUF_EMS_PFRAME], ax
;	mov	ax, word ptr [BUF_EMS_LAST_PAGE+2]
;	mov	[BUF_EMS_PAGE_FRAME], ax
;	xor	ax, ax
;	jmp	fin_choose_page

pick_first:
	mov	ax, word ptr [BUF_EMS_FIRST_PAGE]
	cmp	[BUF_EMS_PFRAME], ax
	je	fin_choose_page
	call	restore_user_map
	mov	word ptr [LASTBUFFER], -1
	mov	[BUF_EMS_PFRAME], ax
	mov	ax, word ptr [BUF_EMS_FIRST_PAGE+2]
	mov	[BUF_EMS_PAGE_FRAME], ax
	mov	[BUF_EMS_SAFE_FLAG], 1
	call	Setup_EMS_Buffers
	call	save_user_map
	jmp	fin_choose_page

err_choose_page:
	stc

fin_choose_page:
	clc

	pop	ax
	pop	ds
	pop	si
	pop	dx
	pop	bx
	pop	cx
	return

EndProc	choose_buf_page	

ENDIF

CODE	ENDS
    END


