;	SCCSID = @(#)fcbio.asm	1.5 85/07/30
;	SCCSID = @(#)fcbio.asm	1.5 85/07/30
TITLE	FCBIO - FCB system calls
NAME	FCBIO

;
; Ancient 1.0 1.1 FCB system calls
;				    regen   save
;   $GET_FCB_POSITION	    written none    none
;   $FCB_DELETE 	    written none    none
;   $GET_FCB_FILE_LENGTH    written none    none
;   $FCB_CLOSE		    written close   none
;   $FCB_RENAME 	    written none    none
;   SaveFCBInfo
;   ResetLRU
;   SetOpenAge
;   LRUFCB
;   FCBRegen
;   BlastSFT
;   CheckFCB
;   SFTFromFCB
;   FCBHardErr
;
;   Revision history:
;
;	Created: ARR 4 April 1983
;		 MZ  6 June  1983 completion of functions
;		 MZ 15 Dec   1983 Brain damaged programs close FCBs multiple
;				  times.  Change so successive closes work by
;				  always returning OK.	Also, detect I/O to
;				  already closed FCB and return EOF.
;		 MZ 16 Jan   1984 More braindamage.  Need to separate info
;				  out of sft into FCB for reconnection
;
;	A000	 version 4.00  Jan. 1988
;
.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
INCLUDE FASTOPEN.INC
.cref
.list

 AsmVars <Kanji>

	I_need	OpenBuf,128		; buffer for translating paths
	I_need	RenBuf,128		; buffer for rename paths
	i_need	THISDPB,DWORD
	i_need	EXTERR,WORD
	i_need	ALLOWED,BYTE
	I_need	ThisSFT,DWORD		; SFT in use
	I_need	WFP_start,WORD		; pointer to canonical name
	I_need	Ren_WFP,WORD		; pointer to canonical name
	I_need	Attrib,BYTE		; Attribute for match attributes
	I_need	sftFCB,DWORD		; pointer to SFTs for FCB cache
	I_need	FCBLRU,WORD		; least recently used count
	I_need	Proc_ID,WORD		; current process ID
	I_Need	Name1,14		; place for device names
	I_need	DEVPT,DWORD		; device pointer
	I_need	OpenLRU,WORD		; open age
	I_need	KeepCount,WORD		; number of fcbs to keep
	I_need	User_In_AX,WORD 	; user input system call.
	I_need	JShare,DWORD		; share jump table
	I_need	FastOpenTable,BYTE	; DOS 3.3 fastopen
if debug
	I_need	BugLev,WORD
	I_need	BugTyp,WORD
	include bugtyp.asm
endif


Break <$Get_FCB_Position - set random record fields to current pos>

;
;   $Get_FCB_Position - look at an FCB, retrieve the current position from the
;	extent and next record field and set the random record field to point
;	to that record
;
;   Inputs:	DS:DX point to a possible extended FCB
;   Outputs:	The random record field of the FCB is set to the current record
;   Registers modified: all

Procedure $Get_FCB_Position,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	invoke	GetExtended		; point to FCB
	invoke	GetExtent		; DX:AX is current record
	MOV	WORD PTR [SI.fcb_RR],AX ; drop in low order piece
	MOV	[SI+fcb_RR+2],DL	; drop in high order piece
	CMP	[SI.fcb_RECSIZ],64
	JAE	GetFCBBye
	MOV	[SI+fcb_RR+2+1],DH	; Set 4th byte only if record size < 64
GetFCBBye:
	transfer    FCB_Ret_OK
EndProc $GET_FCB_POSITION

Break <$FCB_Delete - remove several files that match the input FCB>

;
;   $FCB_delete - given an FCB, remove all directory entries in the current
;	directory that have names that match the FCB's ?  marks.
;
;   Inputs:	DS:DX - point to an FCB
;   Outputs:	directory entries matching the FCB are deleted
;		AL = FF if no entries were deleted.
;   Registers modified: all

Procedure $FCB_Delete,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	DI,OFFSET DOSGroup:OpenBuf  ; appropriate place
	invoke	TransFCB		; convert FCB to path
	JC	BadPath 		; signal no deletions
	Context DS
	invoke	DOS_Delete		; wham
	JC	BadPath
GoodPath:
	transfer    FCB_Ret_OK		; do a good return
BadPath:
;

; Error code is in AX
;
	transfer    FCB_Ret_Err 	; let someone else signal the error
EndProc $FCB_DELETE

Break <$Get_FCB_File_Length - return the length of a file>

;
;   $Get_FCB_File_Length - set the random record field to the length of the
;	file in records (rounded up if partial).
;
;   Inputs:	DS:DX - point to a possible extended FCB
;   Outputs:	Random record field updated to reflect the number of records
;   Registers modified: all

Procedure   $Get_FCB_File_Length,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	invoke	GetExtended		; get real FCB pointer
					; DX points to Input FCB
	MOV	DI,OFFSET DOSGroup:OpenBuf  ; appropriate buffer
	SaveReg <DS,SI> 		; save pointer to true FCB
	Invoke	TransFCB		; Trans name DS:DX, sets SATTRIB
	RestoreReg  <SI,DS>
	JC	BadPath
	SaveReg <DS,SI> 		; save pointer
	Context DS
	invoke	Get_File_Info		; grab the info
	RestoreReg  <SI,DS>		; get pointer back
	JC	BadPath 		; invalid something
	MOV	DX,BX			; get high order size
	MOV	AX,DI			; get low order size
	MOV	BX,[SI.fcb_RECSIZ]	; get his record size
	OR	BX,BX			; empty record => 0 size for file
	JNZ	GetSize 		; not empty
	MOV	BX,128
GetSize:
	MOV	DI,AX			; save low order word
	MOV	AX,DX			; move high order for divide
	XOR	DX,DX			; clear out high
	DIV	BX			; wham
	PUSH	AX			; save dividend
	MOV	AX,DI			; get low order piece
	DIV	BX			; wham
	MOV	CX,DX			; save remainder
	POP	DX			; get high order dividend
	JCXZ	LengthStore		; no roundup
	ADD	AX,1
	ADC	DX,0			; 32-bit increment
LengthStore:
	MOV	WORD PTR [SI.FCB_RR],AX ; store low order
	MOV	[SI.FCB_RR+2],DL	; store high order
	OR	DH,DH
	JZ	GoodPath		; not storing insignificant zero
	MOV	[SI.FCB_RR+3],DH	; save that high piece
GoodRet:
	transfer    FCB_Ret_OK
EndProc $GET_FCB_FILE_LENGTH

Break <$FCB_Close - close a file>

;
;   $FCB_Close - given an FCB, look up the SFN and close it.  Do not free it
;	as the FCB may be used for further I/O
;
;   Inputs:	DS:DX point to FCB
;   Outputs:	AL = FF if file was not found on disk
;   Registers modified: all

Procedure $FCB_Close,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	XOR	AL,AL			; default search attributes
	invoke	GetExtended		; DS:SI point to real FCB
	JZ	NoAttr			; not extended
	MOV	AL,[SI-1]		; get attributes
NoAttr:
	MOV	[Attrib],AL		; stash away found attributes
	invoke	SFTFromFCB
	JC	GoodRet 		; MZ 16 Jan Assume death
;
; If the sharer is present, then the SFT is not regenable.  Thus, there is
; no need to set the SFT's attribute.
;
;;; 9/8/86 F.C. save SFT attribute and restore it back when close is done
	MOV	AL,ES:[DI].sf_attr
	XOR	AH,AH
	PUSH	AX
;;; 9/8/86 F.C. save SFT attribute and restore it back when close is done
	invoke	CheckShare
	JNZ	NoStash
	MOV	AL,Attrib
	MOV	ES:[DI].sf_attr,AL	; attempted attribute for close
NoStash:
	MOV	AX,[SI].FCB_FDATE	; move in the time and date
	MOV	ES:[DI].sf_date,AX
	MOV	AX,[SI].FCB_FTIME
	MOV	ES:[DI].sf_time,AX
	MOV	AX,[SI].FCB_FilSiz
	MOV	WORD PTR ES:[DI].sf_size,AX
	MOV	AX,[SI].FCB_FilSiz+2
	MOV	WORD PTR ES:[DI].sf_size+2,AX
	OR	ES:[DI].sf_Flags,sf_close_nodate
	Context DS			; let Close see variables
	invoke	DOS_Close		; wham
	LES	DI,ThisSFT
;;; 9/8/86 F.C. restore SFT attribute
	POP	CX
	MOV	ES:[DI].sf_attr,CL
;;; 9/8/86 F.C. restore SFT attribute
	PUSHF
	TEST	ES:[DI.sf_ref_count],-1 ; zero ref count gets blasted
	JNZ	CloseOK
	PUSH	AX
	MOV	AL,'M'
	invoke	BlastSFT
	POP	AX
CloseOK:
	POPF
	JNC	GoodRet
	CMP	AL,error_invalid_handle
	JZ	GoodRet
	MOV	AL,error_file_not_found
	transfer    FCB_Ret_Err
EndProc $FCB_CLOSE

Break	<$FCB_Rename - change names in place>

;
;   $FCB_Rename - rename a file in place within a directory.  Renames multiple
;	files copying from the meta characters.
;
;   Inputs:	DS:DX point to an FCB.	The normal name field is the source
;		    name of the files to be renamed.  Starting at offset 11h
;		    in the FCB is the destination name.
;   Outputs:	AL = 0 -> no error occurred and all files were renamed
;		AL = FF -> some files may have been renamed but:
;		    rename to existing file or source file not found
;   Registers modified: all

Procedure $FCB_Rename,NEAR
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	invoke	GetExtended		; get pointer to real FCB
	SaveReg <DX>
	MOV	AL,[SI] 		; get drive byte
	ADD	SI,10h			; point to destination
	MOV	DI,OFFSET DOSGroup:RenBuf   ; point to destination buffer
	SaveReg <<WORD PTR DS:[SI]>,DS,SI>  ; save source pointer for TransFCB
	MOV	DS:[SI],AL		; drop in real drive
	MOV	DX,SI			; let TransFCB know where the FCB is
	invoke	TransFCB		; munch this pathname
	RestoreReg  <SI,DS,<WORD PTR DS:[SI]>>	; get path back
	RestoreReg  <DX>		; Original FCB pointer
	JC	BadRen			; bad path -> error
	MOV	SI,WFP_Start		; get pointer
	MOV	Ren_WFP,SI		; stash it
	MOV	DI,OFFSET DOSGroup:OpenBuf  ; appropriate spot
	invoke	TransFCB		; wham
					; NOTE that this call is pointing
					;  back to the ORIGINAL FCB so
					;  SATTRIB gets set correctly
	JC	BadRen			; error
	invoke	DOS_Rename
	JC	BadRen
	transfer    FCB_Ret_OK
BadRen:
;
; AL has error code
;
	transfer    FCB_Ret_Err

EndProc $FCB_RENAME

Break <Misbehavior fixers>

;
;   FCBs suffer from several problems.	First, they are maintained in the
;   user's space so he may move them at will.  Second, they have a small
;   reserved area that may be used for system information.  Third, there was
;   never any "rules for behavior" for FCBs; there was no protocol for their
;   usage.
;
;   This results in the following misbehavior:
;
;	infinite opens of the same file:
;
;	While (TRUE) {			While (TRUE) {
;	    FCBOpen (FCB);		    FCBOpen (FCB);
;	    Read (FCB); 		    Write (FCB);
;	    }				    }
;
;	infinite opens of different files:
;
;	While (TRUE) {			While (TRUE) {
;	    FCBOpen (FCB[i++]); 	    FCBOpen (FCB[i++]);
;	    Read (FCB); 		    Write (FCB);
;	    }				    }
;
;	multiple closes of the same file:
;
;	FCBOpen (FCB);
;	while (TRUE)
;	    FCBClose (FCB);
;
;	I/O after closing file:
;
;	FCBOpen (FCB);
;	while (TRUE) {
;	    FCBWrite (FCB);
;	    FCBClose (FCB);
;	    }
;
;   The following is am implementation of a methodology for emulating the
;   above with the exception of I/O after close.  We are NOT attempting to
;   resolve that particular misbehavior.  We will enforce correct behaviour in
;   FCBs when they refer to a network file or when there is file sharing on
;   the local machine.
;
;   The reserved fields of the FCB (10 bytes worth) is divided up into various
;   structures depending on the file itself and the state of operations of the
;   OS.  The information contained in this reserved field is enough to
;   regenerate the SFT for the local non-shared file.  It is assumed that this
;   regeneration procedure may be expensive.  The SFT for the FCB is
;   maintained in a LRU cache as the ONLY performance inprovement.
;
;   No regeneration of SFTs is attempted for network FCBs.
;
;   To regenerate the SFT for a local FCB, it is necessary to determine if the
;   file sharer is working.  If the file sharer is present then the SFT is not
;   regenerated.
;
;   Finally, if there is no local sharing, the full name of the file is no
;   longer available.  We can make up for this by using the following
;   information:
;
;	The Drive number (from the DPB).
;	The physical sector of the directory that contains the entry.
;	The relative position of the entry in the sector.
;	The first cluster field.
;	The last used SFT.
;      OR In the case of a device FCB
;	The low 6 bits of sf_flags (indicating device type)
;	The pointer to the device header
;
;
;   We read in the particular directory sector and examine the indicated
;   directory entry.  If it matches, then we are kosher; otherwise, we fail.
;
;   Some key items need to be remembered:
;
;	Even though we are caching SFTs, they may contain useful sharing
;	information.  We enforce good behavior on the FCBs.
;
;	Network support must not treat FCBs as impacting the ref counts on
;	open VCs.  The VCs may be closed only at process termination.
;
;	If this is not an installed version of the DOS, file sharing will
;	always be present.
;
;	We MUST always initialize lstclus to = firclus when regenerating a
;	file. Otherwise we start allocating clusters up the wazoo.
;
;	Always initialize, during regeneration, the mode field to both isFCB
;	and open_for_both.  This is so the FCB code in the sharer can find the
;	proper OI record.
;
;   The test bits are:
;
;	00 -> local file
;	40 -> sharing local
;	80 -> network
;	C0 -> local device

Break	<SaveFCBInfo - store pertinent information from an SFT into the FCB>

;
;   SaveFCBInfo - given an FCB and its associated SFT, copy the relevant
;	pieces of information into the FCB to allow for subsequent
;	regeneration. Poke LRU also.
;
;   Inputs:	ThisSFT points to a complete SFT.
;		DS:SI point to the FCB (not an extended one)
;   Outputs:	The relevant reserved fields in the FCB are filled in.
;		DS:SI preserved
;		ES:DI point to sft
;   Registers modified: All
;

Procedure   SaveFCBInfo,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	LES	DI,ThisSFT
	Assert	ISSFT,<ES,DI>,"SaveFCBInfo"
	invoke	IsSFTNet
	JZ	SaveLocal		; if not network then save local info
;
;----- In net support -----
;
	MOV	AX,WORD PTR ES:[DI].sf_serial_ID	;AN000;;IFS.  save IFS ID
	MOV	WORD PTR [SI].FCB_netID,ax		;AN000;;IFS.
;	SaveReg <ES,DI>
;	LES	DI,DWORD PTR ES:[DI].sf_netid
;	MOV	WORD PTR [SI].FCB_netID,DI  ; save net ID
;	MOV	WORD PTR [SI].FCB_netID+2,ES
;	RestoreReg  <DI,ES>
	MOV	BL,FCBNETWORK
;
;----- END In net support -----
;
IF debug
	JMP	SaveSFN
ELSE
	JMP	SHORT SaveSFN
ENDIF
SaveLocal:
	IF	Installed
	Invoke	CheckShare
	JZ	SaveNoShare		; no sharer
	JMP	SaveShare		; sharer present

SaveNoShare:
	TEST	ES:[DI].sf_flags,devid_device
	JNZ	SaveNoShareDev		; Device
;
; Save no sharing local file information
;
	MOV	AX,WORD PTR ES:[DI].sf_dirsec ; get directory sector F.C.
	MOV	[SI].fcb_nsl_dirsec,AX
	MOV	AL,ES:[DI].sf_dirpos	; location in sector
	MOV	[SI].fcb_nsl_dirpos,AL
	MOV	AX,ES:[DI].sf_firclus	; first cluster
	MOV	[SI].fcb_nsl_firclus,AX
	MOV	BL,00
;
; Create the bits field from the dirty/device bits of the flags word and the
; mode byte
;
SetFCBBits:
	MOV	AX,ES:[DI].sf_flags
	AND	AL,0C0h 		; mask off drive bits
	OR	AL,BYTE PTR ES:[DI].sf_mode ; stick in open mode
	MOV	[SI].fcb_nsl_bits,AL	; save dirty info
	JMP	SaveSFN 		; go and save SFN

;
; Save no sharing local device information
;
SaveNoShareDev:
	MOV	AX,WORD PTR ES:[DI].sf_devptr
	MOV	WORD PTR [SI].FCB_nsld_drvptr,AX
	MOV	AX,WORD PTR ES:[DI].sf_devptr + 2
	MOV	WORD PTR [SI].FCB_nsld_drvptr + 2,AX
	MOV	BL,FCBDEVICE
	JMP	SetFCBBits		; go and save SFN

SaveShare:
	ENDIF
;
;----- In share support -----
;
if installed
	Call	JShare + 10 * 4
else
	Call	ShSave
endif
;
;----- end in share support -----
;
SaveSFN:
	MOV	AX,ES:[DI].sf_flags
	AND	AL,3Fh			; get real drive
	OR	AL,BL
	MOV	[SI].fcb_l_drive,AL
	LEA	AX,[DI-SFTable]
;
; Adjust for offset to table.
;
	SUB	AX,WORD PTR SftFCB
	MOV	BL,SIZE sf_entry
	DIV	BL
	MOV	[SI].FCB_sfn,AL 	; last used SFN
	MOV	AX,FCBLRU		; get lru count
	INC	AX
	MOV	WORD PTR ES:[DI].sf_LRU,AX
	JNZ	SimpleStuff
;
; lru flag overflowed.	Run through all FCB sfts and adjust:  LRU < 8000h
; get set to 0.  Others -= 8000h.  This LRU = 8000h
;
	MOV	BX,sf_position
	invoke	ResetLRU
;
; Set new LRU to AX
;
SimpleStuff:
	MOV	FCBLRU,AX
	return
EndProc SaveFCBInfo

Break	<ResetLRU - reset overflowed lru counts>

;
;   ResetLRU - during lru updates, we may wrap at 64K.	We must walk the
;   entire set of SFTs and subtract 8000h from their lru counts and truncate
;   at 0.
;
;   Inputs:	BX is offset into SFT field where lru firld is kept
;		ES:DI point to SFT currently being updated
;   Outputs:	All FCB SFTs have their lru fields truncated
;		AX has 8000h
;   Registers modified: none

Procedure   ResetLRU,NEAR
	ASSUME CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:NOTHING
	Assert	ISSFT,<ES,DI>,"ResetLRU"
	MOV	AX,8000h
	SaveReg <ES,DI>
	LES	DI,sftFCB		; get pointer to head
	MOV	CX,ES:[DI].sfCount
	LEA	DI,[DI].sfTable 	; point at table
ovScan:
	SUB	WORD PTR ES:[DI+BX],AX	; decrement lru count
	JA	ovLoop
	MOV	WORD PTR ES:[DI.BX],AX	; truncate at 0
ovLoop:
	ADD	DI,SIZE SF_Entry	; advance to next
	LOOP	ovScan
	RestoreReg  <DI,ES>
	MOV	ES:[DI+BX],AX
	return
EndProc ResetLRU

Break	<SetOpenAge - update the open age of a SFT>

;
;   SetOpenAge - In order to maintain the first N open files in the FCB cache,
;   we keep the 'open age' or an LRU count based on opens.  We update the
;   count here and fill in the appropriate field.
;
;   Inputs:	ES:DI point to SFT
;   Outputs:	ES:DI has the open age field filled in.
;		If open age has wraparound, we will have subtracted 8000h
;		    from all open ages.
;   Registers modified: AX
;

Procedure   SetOpenAge,NEAR
	ASSUME CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:NOTHING
	Assert	ISSFT,<ES,DI>,"SetOpenAge"
	MOV	AX,OpenLRU
	INC	AX
	MOV	ES:[DI].sf_OpenAge,AX
	JNZ	SetDone
	MOV	BX,sf_Position+2
	invoke	ResetLRU
SetDone:
	MOV	OpenLRU,AX
	return
EndProc SetOpenAge

Break	<LRUFCB - perform LRU on FCB sfts>

;
;   LRUFCB - find LRU fcb in cache.  Set ThisSFT and return it.  We preserve
;	the first keepcount sfts if they are network sfts or if sharing is
;	loaded.  If carry is set then NO BLASTING is NECESSARY.
;
;   Inputs:	none
;   Outputs:	ES:DI point to SFT
;		ThisSFT points to SFT
;		SFT is zeroed
;		Carry set of closes failed
;   Registers modified: none
;

Procedure   LRUFCB,NEAR
	ASSUME CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:NOTHING
	Invoke	Save_World
;
; Find nth oldest NET/SHARE FCB.  We want to find its age for the second scan
; to find the lease recently used one that is younger than the open age.  We
; operate be scanning the list n times finding the least age that is greater
; or equal to the previous minimum age.
;
;   BP is the count of times we need to go through this loop.
;   AX is the current acceptable minimum age to consider
;
	mov	bp,KeepCount		; k = keepcount;
	XOR	AX,AX			; low = 0;
;
; If we've scanned the table n times, then we are done.
;
lru1:
	CMP	bp,0			; while (k--) {
	JZ	lru75
	DEC	bp
;
; Set up for scan.
;
;   AX is the minimum age for consideration
;   BX is the minimum age found during the scan
;   SI is the position of the entry that corresponds to BX
;
	MOV	BX,-1			;     min = 0xffff;
	MOV	si,BX			;     pos = 0xffff;
	LES	DI,SFTFCB		;     for (CX=FCBCount; CX>0; CX--)
	MOV	CX,ES:[DI].sfCount
	LEA	DI,[DI].sfTable
;
; Innermost loop.  If the current entry is free, then we are done.  Or, if the
; current entry is busy (indicating a previous aborted allocation), then we
; are done.  In both cases, we use the found entry.
;
lru2:
	cmp	es:[di].sf_ref_count,0
	jz	lru25
	cmp	es:[di].sf_ref_count,sf_busy
	jnz	lru3
;
; The entry is usable without further scan.  Go and use it.
;
lru25:
	MOV	si,DI			;	      pos = i;
	JMP	lru11			;	      goto got;
;
; See if the entry is for the network or for the sharer.
;
;  If for the sharer or network then
;	if the age < current minimum AND >= allowed minimum then
;	    this entry becomes current minimum
;
lru3:
	TEST	ES:[DI].sf_flags,sf_isnet   ;	  if (!net[i]
	JNZ	lru35
if installed
	Invoke	CheckShare		;		&& !sharing)
	JZ	lru5			;	  else
ENDIF
;
; This SFT is for the net or is for the sharer.  See if it less than the
; current minimum.
;
lru35:
	MOV	DX,ES:[DI].sf_OpenAge
	CMP	DX,AX			;	  if (age[i] >= low &&
	JB	lru5
	CMP	DX,BX
	JAE	lru5			;	      age[i] < min) {
;
; entry is new minimum.  Remember his age.
;
	mov	bx,DX			;	      min = age[i];
	mov	si,di			;	      pos = i;
;
; End of loop.	gp back for more
;
lru5:
add	di,size sf_entry
	loop	lru2			;	      }
;
; The scan is complete.  If we have successfully found a new minimum (pos != -1)
; set then threshold value to this new minimum + 1.  Otherwise, the scan is
; complete.  Go find LRU.
;
lru6:	cmp	si,-1			; position not -1?
	jz	lru75			; no, done with everything
	lea	ax,[bx+1]		; set new threshold age
	jmp	lru1			; go and loop for more
lru65:	stc
	jmp	short	lruDead 	;	  return -1;
;
; Main loop is done.  We have AX being the age+1 of the nth oldest sharer or
; network entry.  We now make a second pass through to find the LRU entry
; that is local-no-share or has age >= AX
;
lru75:
	mov	bx,-1			; min = 0xffff;
	mov	si,bx			; pos = 0xffff;
	LES	DI,SFTFCB		; for (CX=FCBCount; CX>0; CX--)
	MOV	CX,ES:[DI].sfCount
	LEA	DI,[DI].sfTable
;
; If this is is local-no-share then go check for LRU else if age >= threshold
; then check for lru.
;
lru8:
	TEST	ES:[DI].sf_flags,sf_isnet
	jnz	lru85			; is for network, go check age
	invoke	CheckShare		; sharer here?
	jz	lru86			; no, go check lru
;
; Network or sharer.  Check age
;
lru85:
	cmp	es:[di].sf_OpenAge,ax
	jb	lru9			; age is before threshold, skip it
;
; Check LRU
;
lru86:
	cmp	es:[di].sf_LRU,bx	; is LRU less than current LRU?
	jae	lru9			; no, skip this
	mov	si,di			; remember position
	mov	bx,es:[di].sf_LRU	; remember new minimum LRU
;
; Done with this entry, go back for more.
;
lru9:
	add	di,size sf_entry
	loop	lru8
;
; Scan is complete.  If we found NOTHING that satisfied us then we bomb
; out.	The conditions here are:
;
;   No local-no-shares AND all net/share entries are older than threshold
;
lru10:
	cmp	si,-1			; if no one f
	jz	lru65			;     return -1;
lru11:
	mov	di,si
	MOV	WORD PTR ThisSFT,DI	; set thissft
	MOV	WORD PTR ThisSFT+2,ES
;
; If we have sharing or thisSFT is a net sft, then close it until ref count
; is 0.
;
	TEST	ES:[DI].sf_flags,sf_isNet
	JNZ	LRUClose
IF INSTALLED
	Invoke	CheckShare
	JZ	LRUDone
ENDIF
;
; Repeat close until ref count is 0
;
LRUClose:
	Context DS
	LES	DI,ThisSFT
	CMP	ES:[DI].sf_ref_count,0	; is ref count still <> 0?
	JZ	LRUDone 		; nope, all done

;	Message     1,"LRUFCB: closing "
;	MessageNum  <WORD PTR THISSFT+2>
;	Message     1,":"
;	MessageNum  <WORD PTR THISSFT>

	Invoke	DOS_Close
	jnc	LRUClose		; no error => clean up
	cmp	al,error_invalid_handle
	jz	LRUClose
	stc
	JMP	short LRUDead
LRUDone:
	XOR	AL,AL
	invoke	BlastSFT		; fill SFT with 0 (AL)
LRUDead:
	Invoke	Restore_World
	ASSUME	DS:NOTHING
	LES	DI,ThisSFT
	Assert	ISSFT,<ES,DI>,"LRUFCB return"
	retnc
	MOV	AL,error_FCB_unavailable
	return
EndProc LRUFCB

Break	<FCBRegen - regenerate a sft from the info in the FCB>

;
;   FCBRegen - examine reserved field of FCB and attempt to generate the SFT
;	from it.
;
;   Inputs:	DS:SI point to FCB
;   Outputs:	carry clear Filled in SFT
;		Carry set unrecoverable error
;   Registers modified: all

Procedure   FCBRegen,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING
;
; General data filling.  Mode is sf_isFCB + open_for_both, date/time we do
; not fill, size we do no fill, position we do not fill,
; bit 14 of flags = TRUE, other bits = FALSE
;
	MOV	AL,[SI].fcb_l_drive
;
; We discriminate based on the first two bits in the reserved field.
;
	TEST	AL,FCBSPECIAL		; check for no sharing test
	JZ	RegenNoSharing		; yes, go regen from no sharing
;
; The FCB is for a network or a sharing based system.  At this point we have
; already closed the SFT for this guy and reconnection is impossible.
;
; Remember that he may have given us a FCB with bogus information in it.
; Check to see if sharing is present or if the redir is present.  If either is
; around, presume that we have cycled out the FCB and give the hard error.
; Otherwise, just return with carry set.
;
	invoke	CheckShare		; test for sharer
	JNZ	RegenFail		; yep, fail this.
	MOV	AX,multNet SHL 8	; install check on multnet
	INT	2FH
	OR	AL,AL			; is it there?
	JZ	RegenDead		; no, just fail the operation
RegenFail:
	MOV	AX,User_In_AX
	cmp	AH,fcb_close
	jz	RegenDead
	invoke	FCBHardErr		; massive hard error.
RegenDead:
	STC
	return				; carry set
;
; Local FCB without sharing.  Check to see if sharing is loaded.  If so
; fail the operation.
;
RegenNoSharing:
	invoke	CheckShare		; Sharing around?
	JNZ	RegenFail
;
; Find an SFT for this guy.
;
	invoke	LRUFcb
	retc
	MOV	ES:[DI].sf_mode,SF_IsFCB + open_for_both + sharing_compat
	AND	AL,3Fh			; get drive number for flags
	CBW
	OR	AX,sf_close_noDate	; normal FCB operation
;
; The bits field consists of the upper two bits (dirty and device) from the
; SFT and the low 4 bits from the open mode.
;
	MOV	CL,[SI].FCB_nsl_bits	; stick in dirty bits.
	MOV	CH,CL
	AND	CH,0C0h 		; mask off the dirty/device bits
	OR	AL,CH
	AND	CL,access_mask		; get the mode bits
	MOV	BYTE PTR ES:[DI].sf_mode,CL
	MOV	ES:[DI].sf_flags,AX	; initial flags
	MOV	AX,Proc_ID
	MOV	ES:[DI].sf_PID,AX
	SaveReg <DS,SI,ES,DI>
	Context ES
	MOV	DI,OFFSET DOSGroup:Name1
	MOV	CX,8
	INC	SI			; Skip past drive byte to name in FCB
RegenCopyName2:
	LODSB

 IF  DBCS				;AN000;
	invoke	testkanj		;AN000;
	jz	notkanj9		;AN000;
	STOSB				;AN000;
	DEC	CX			;AN000;
	JCXZ	DoneNam2		;AN000; ; Ignore split kanji char error
	LODSB				;AN000;
	jmp	short StuffChar2	;AN000;
					;AN000;
notkanj9:				;AN000;
 ENDIF					;AN000;

	Invoke	UCase
StuffChar2:
	STOSB
	LOOP	RegenCopyName2
DoneNam2:
	Context DS
	MOV	[ATTRIB],attr_hidden + attr_system + attr_directory
					; Must set this to something interesting
					; to call DEVNAME.
	Invoke	DevName 		; check for device
	ASSUME	DS:NOTHING,ES:NOTHING
	RestoreReg  <DI,ES,SI,DS>
	JC	RegenFileNoSharing	; not found on device list => file
;
; Device found.  We can ignore disk-specific info
;
	MOV	BYTE PTR ES:[DI].sf_flags,BH   ; device parms
	MOV	ES:[DI].sf_attr,0	; attribute
	LDS	SI,DEVPT		; get device driver
	MOV	WORD PTR ES:[DI].sf_devptr,SI
	MOV	WORD PTR ES:[DI].sf_devptr+2,DS
	return				; carry is clear

RegenDeadJ:
	JMP	RegenDead
;
; File found.  Just copy in the remaining pieces.
;
RegenFileNoSharing:
	MOV	AX,ES:[DI].sf_flags
	AND	AX,03Fh
	SaveReg <DS,SI>
	Invoke	Find_DPB
	MOV	WORD PTR ES:[DI].sf_devptr,SI
	MOV	WORD PTR ES:[DI].sf_devptr+2,DS
	RestoreReg  <SI,DS>
	jc	RegenDeadJ		; if find DPB fails, then drive
					; indicator was bogus
	MOV	AX,[SI].FCB_nsl_dirsec
	MOV	WORD PTR ES:[DI].sf_dirsec,AX
	MOV	WORD PTR ES:[DI].sf_dirsec+2,0	;AN000;>32mb
	MOV	AX,[SI].FCB_nsl_firclus
	MOV	ES:[DI].sf_firclus,AX
	MOV	ES:[DI].sf_lstclus,AX
	MOV	AL,[SI].FCB_nsl_dirpos
	MOV	ES:[DI].sf_dirpos,AL
	INC	ES:[DI].sf_ref_count	; Increment reference count.
					; Existing FCB entries would be
					; flushed unnecessarily because of
					; check in CheckFCB of the ref_count.
					; July 22/85 - BAS
	LEA	SI,[SI].FCB_name
	LEA	DI,[DI].sf_name
	MOV	CX,fcb_extent-fcb_name
RegenCopyName:
	LODSB

	IF	DBCS			;AN000;
	invoke	testkanj
	jz	notkanj1
	STOSB
	DEC	CX
	JCXZ	DoneNam 		; Ignore split kanji char error
	LODSB
	jmp	short StuffChar

notkanj1:
	ENDIF				;AN000;

	Invoke	UCase
StuffChar:
	STOSB
	LOOP	RegenCopyName
DoneNam:
	clc
	return
EndProc FCBRegen

;
;   BlastSFT - fill SFT with garbage
;
;   Inputs: ES:DI point to SFT
;	    AL has fill
;   Outputs: SFT is filled with nonsense
;	    *FLAGS PRESERVED*
;   Registers modified: CX

Procedure   BlastSFT,NEAR
	SaveReg <DI>
	MOV	CX,SIZE sf_entry
	REP	STOSB
	RestoreReg  <DI>
	MOV	ES:[DI].sf_ref_count,0	; set ref count
	MOV	ES:[DI].sf_LRU,0	; set lru
	MOV	ES:[DI].sf_OpenAge,-1	; Set open age
	return
EndProc BlastSFT

Break	<CheckFCB - see if the SFT pointed to by the FCB is still OK>

;   CheckFCB - examine an FCB and its contents to see if it needs to be
;   regenerated.
;
;   Inputs:	DS:SI point to FCB (not extended)
;		AL is SFT index
;   Outputs:	Carry Set - FCB needs to be regened
;		Carry clear - FCB is OK. ES:DI point to SFT
;   Registers modified: AX and BX

Procedure   CheckFCB,NEAR
	ASSUME DS:NOTHING,ES:NOTHING
	LES	DI,sftFCB
	CMP	BYTE PTR ES:[DI].SFCount,AL
	JC	BadSFT
	MOV	BL,SIZE sf_entry
	MUL	BL
	LEA	DI,[DI].sftable
	ADD	DI,AX
	MOV	AX,Proc_ID
	CMP	ES:[DI].sf_PID,AX
	JNZ	BadSFT			; must match process
	CMP	ES:[DI].sf_ref_count,0
	JZ	BadSFT			; must also be in use
	MOV	AL,[SI].FCB_l_Drive
	TEST	AL,FCBSPECIAL		; a special FCB?
	JZ	CheckNoShare		; No. try local or device
;
; Since we are a special FCB, try NOT to use a bogus test instruction.
; FCBSHARE is a superset of FCBNETWORK.
;
	PUSH	AX
	AND	AL,FCBMASK
	CMP	AL,FCBSHARE		; net FCB?
	POP	AX
	JNZ	CheckNet		; yes
;
;----- In share support -----
;
if installed
	Call	JShare + 11 * 4
else
	Call	ShChk
endif
	JC	BadSFT
	JMP	SHORT CheckD
;
;----- End in share support -----
;
CheckFirClus:
	CMP	BX,ES:[DI].sf_firclus
	JNZ	BadSFT
CheckD: AND	AL,3Fh
	MOV	AH,BYTE PTR ES:[DI].sf_flags
	AND	AH,3Fh
	CMP	AH,AL
	retz				; carry is clear
BadSFT: STC
	return				; carry is clear
CheckNet:
;
;----- In net support -----
;
;	MOV	AX,[SI].FCB_net_handle
;	CMP	AX,WORD PTR ES:[DI].sf_NETID+4
;	JNZ	BadSFT
;	MOV	AX,WORD PTR [SI].FCB_netID
;	CMP	AX,WORD PTR ES:[DI].sf_netid
;	JNZ	BadSFT
	MOV	AX,WORD PTR [SI].FCB_netID	  ;AN000;IFS.DOS 4.00
	CMP	AX,WORD PTR ES:[DI].sf_serial_ID  ;AN000;IFS.DOS 4.00
	JNZ	BadSFT
;
;----- END In net support -----
;
	return

CheckNoShare:
	TEST	AL,FCBDEVICE		; Device?
	JNZ	CheckNoShareDev 	; Yes
;
; Check no sharing local file
;
	MOV	BX,[SI].FCB_nsl_Dirsec
	CMP	WORD PTR ES:[DI].sf_dirsec+2,0	;AN000;F.C. >32mb
	JNZ	BadSFt				;AN000;F.C. >32mb

	CMP	BX,WORD PTR ES:[DI].sf_dirsec	;AN000;F.C. >32mb
	JNZ	BadSFT
	MOV	BL,[SI].FCB_nsl_Dirpos
	CMP	BL,ES:[DI].sf_dirpos
	JNZ	BadSFt
;
; Since the bits field comes from two different spots, compare them separately.
;
	MOV	BL,[SI].FCB_nsl_bits
	MOV	BH,BYTE PTR ES:[DI].sf_flags
	XOR	BH,BL
	AND	BH,0C0h
	JNZ	BadSFT			; dirty/device bits are different
	XOR	BL,BYTE PTR ES:[DI].sf_mode
	AND	BL,access_mask
	JNZ	BadSFT			; access modes are different
; Make sure that the names are the same in the FCB and the SFT
; This case can appear under the following scenario:
;		Create	FOO
;		Rename	FOO -> BAR
;		Open	BAR
; The SFT will still contain the name for the old file name.
; July 30/85 - BAS
	PUSH	DI
	PUSH	SI
	LEA	DI,[DI].sf_name
	LEA	SI,[SI].fcb_name
	MOV	CX,11
	REPE	CMPSB
	POP	SI
	POP	DI
	JNZ	BadSFT
	MOV	BX,[SI].FCB_nsl_firclus
	JMP	CheckFirClus

CheckNoShareDev:
	MOV	BX,WORD PTR [SI].FCB_nsld_drvptr
	CMP	BX,WORD PTR ES:[DI].sf_devptr
	JNZ	BadSFT
	MOV	BX,WORD PTR [SI].FCB_nsld_drvptr + 2
	CMP	BX,WORD PTR ES:[DI].sf_devptr + 2
	JNZ	BadSFT
	JMP	CheckD

EndProc CheckFCB

Break	<SFTFromFCB - take a FCB and obtain a SFT from it>

;
;   SFTFromFCB - the workhorse of this compatability crap.  Check to see if
;	the SFT for the FCB is Good.  If so, make ThisSFT point to it.	If not
;	good, get one from the cache and regenerate it.  Overlay the LRU field
;	with PID
;
;   Inputs:	DS:SI point to FCB
;   Outputs:	ThisSFT point to appropriate SFT
;		Carry clear -> OK ES:DI -> SFT
;		Carry set -> error in ax
;   Registers modified: ES,DI, AX

Procedure   SFTFromFCB,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING
	SaveReg <AX,BX>
	MOV	AL,[SI].fcb_sfn 	; set SFN for check
	invoke	CheckFCB
	RestoreReg  <BX,AX>
	MOV	WORD PTR ThisSFT,DI	; set thissft
	MOV	WORD PTR ThisSFT+2,ES
	JNC	SetSFT			; no problems, just set thissft

	fmt	typFCB,LevCheck,<"FCB $x:$x does not match SFT $x:$x\n">,<DS,SI,ES,DI>

	Invoke	Save_World
	invoke	FCBRegen
	Invoke	Restore_World		; restore world
	MOV	AX,EXTERR
	retc

;	Message 1,<"FCBRegen Succeeded",13,10>

SetSFT: LES	DI,ThisSFT
	PUSH	Proc_ID 		; set process id
	POP	ES:[DI].sf_PID
	return				; carry is clear
EndProc SFTFromFCB

Break	<FCBHardErr - generate INT 24 for hard errors on FCBS>

;
;   FCBHardErr - signal to a user app that he is trying to use an
;	unavailable FCB.
;
;   Inputs:	none.
;   Outputs:	none.
;   Registers modified: all
;

Procedure   FCBHardErr,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING
	MOV	AX,error_FCB_Unavailable
	MOV	[ALLOWED],allowed_FAIL
	LES	BP,[THISDPB]
	MOV	DI,1				; Fake some registers
	MOV	CX,DI
	MOV	DX,ES:[BP.dpb_first_sector]
	invoke	HARDERR
	STC
	return
EndProc FCBHardErr

CODE ENDS
END
