;	SCCSID = @(#)delete.asm 1.3 85/10/18
;	SCCSID = @(#)delete.asm 1.3 85/10/18
TITLE	DOS_DELETE - Internal DELETE call for MS-DOS
NAME	DOS_DELETE
; Low level routine for deleting files
;
;   DOS_DELETE
;   REN_DEL_Check
;   FastOpen_Delete	       ; DOS 3.3
;   FastOpen_Update	       ; DOS 3.3
;   FastSeek_Open	       ; DOS 4.00
;   FSeek_dispatch	       ; DOS 4.00
;   FastSeek_Close	       ; DOS 4.00
;   FastSeek_Delete	       ; DOS 4.00
;   Delete_FSeek	       ; DOS 4.00
;   FastSeek_Lookup	       ; DOS 4.00
;   FastSeek_Insert	       ; DOS 4.00
;   FastSeek_Truncate	       ; DOS 4.00
;   FS_doit		       ; DOS 4.00
;
;   Revision history:
;
;   A000  version 4.00	Jan. 1988
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
INCLUDE FASTOPEN.INC
INCLUDE fastseek.inc
INCLUDE fastxxxx.inc
.cref
.list

Installed = TRUE

	i_need	NoSetDir,BYTE
	i_need	Creating,BYTE
	i_need	DELALL,BYTE
	i_need	THISDPB,DWORD
	i_need	THISSFT,DWORD
	i_need	THISCDS,DWORD
	i_need	CURBUF,DWORD
	i_need	ATTRIB,BYTE
	i_need	SATTRIB,BYTE
	i_need	WFP_START,WORD
	i_need	FoundDel,BYTE
	i_need	AUXSTACK,BYTE
	i_need	VOLCHNG_FLAG,BYTE
	i_need	JShare,DWORD
	i_need	FastOpenTable,BYTE		  ; DOS 3.3
	i_need	FastTable,BYTE			  ; DOS 4.00
	i_need	FSeek_drive,BYTE		  ; DOS 4.00
	i_need	FSeek_firclus,WORD		  ; DOS 4.00
	i_need	FSeek_logclus,WORD		  ; DOS 4.00
	i_need	FSeek_logsave,WORD		  ; DOS 4.00
	i_need	FastSeekflg,BYTE		  ; DOS 4.00
	i_need	Del_ExtCluster,WORD		  ; DOS 4.00
	i_need	SAVE_BX,WORD			  ; DOS 4.00
	i_need	DMAADD,DWORD
	i_need	RENAMEDMA,BYTE

; Inputs:
;	[WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL
;		terminated)
;	[CURR_DIR_END] Points to end of Current dir part of string
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[THISCDS] Points to CDS being used
;		(Low word = -1 if NUL CDS (Net direct request))
;	[SATTRIB] Is attribute of search, determines what files can be found
; Function:
;	Delete the specified file(s)
; Outputs:
;	CARRY CLEAR
;		OK
;	CARRY SET
;	    AX is error code
;		error_file_not_found
;			Last element of path not found
;		error_path_not_found
;			Bad path (not in curr dir part if present)
;		error_bad_curr_dir
;			Bad path in current directory part of path
;		error_access_denied
;			Attempt to delete device or directory
;		***error_sharing_violation***
;			Deny both access required, generates an INT 24.
;			This error is NOT returned. The INT 24H is generated,
;			  and the file is ignored (not deleted). Delete will
;			  simply continue on looking for more files.
;			  Carry will NOT be set in this case.
; DS preserved, others destroyed

fileFound   = 01h
fileDeleted = 10h

	procedure   DOS_DELETE,NEAR
	DOSAssume   CS,<DS>,"DOS_Delete"
	ASSUME	ES:NOTHING

	Invoke	TestNet
	JNC	LOCAL_DELETE
;	invoke	OWN_SHARE2		       ;IFS. IFS owns share ?		;AN000;
;	JZ	ifsshare		       ;IFS. yes			;AN000;
;	PUSH	WORD PTR [DMAADD+2]	       ;IFS. save DMAADD		;AN000;
;	PUSH	WORD PTR [DMAADD]	       ;IFS.				;AN000;
;	CALL	IFS_SEARCH_FIRST	       ;IFS. do search first		;AN000;
;	JC	nofiles 		       ;IFS. file not existing		;AN000;
delete_next_file:			       ;IFS.				;AN000;
;	CALL	IFS_REN_DEL_CHECK	       ;IFS. do REN_DEL_CHECK		;AN000;
;	JNC	share_okok		       ;IFS. share ok			;AN000;
;	MOV	AX,error_sharing_violation     ;IFS. share violation		;AN000;
;	JMP	SHORT nofiles		       ;IFS.				;AN000;
share_okok:
;	MOV	AX,(multNET SHL 8) OR 19       ;IFS. delete it now		;AN000;
;;	INT	2FH			       ;IFS.				;AN000;
;	JC	nofiles 		       ;IFS. error			;AN000;
;	invoke	DOS_SEARCH_NEXT 	       ;IFS. get next entry		;AN000;
;	JNC	delete_next_file	       ;IFS.				;AN000;
;	CLC				       ;IFS. no more files		;AN000;
nofiles:
;	POP	WORD PTR [DMAADD]	       ;IFS. retor DMAADD		;AN000;
;	POP	WORD PTR [DMAADD+2]	       ;IFS.				;AN000;
;	ret				       ;IFS. return
ifsshare:


IF NOT Installed
	transfer NET_DELETE
ELSE
	MOV	AX,(multNET SHL 8) OR 19
	INT	2FH
	return
ENDIF

LOCAL_DELETE:
	MOV	[FoundDel],00	; No files found and no files deleted
	EnterCrit   critDisk
	MOV	WORD PTR [CREATING],0E500H  ; Assume not del *.*
	MOV	SI,[WFP_START]
SKPNUL:
	LODSB
	OR	AL,AL
	JNZ	SKPNUL			    ; go to end
	SUB	SI,4			    ; Back over possible "*.*"
	CMP	WORD PTR [SI],("." SHL 8 OR "*")
	JNZ	TEST_QUEST
	CMP	BYTE PTR [SI+2],"*"
	JZ	CHECK_ATTS
TEST_QUEST:
	SUB	SI,9		; Back over possible "????????.???"
	XCHG	DI,SI
	context ES
	MOV	AX,"??"
	MOV	CX,4		; four sets of "??"
	REPE	SCASW
	JNZ	NOT_ALL
	XCHG	DI,SI
	LODSW
	CMP	AX,("?" SHL 8) OR "."
	JNZ	NOT_ALL
	LODSW
	CMP	AX,"??"
	JNZ	NOT_ALL
CHECK_ATTS:
	MOV	AL,BYTE PTR [SATTRIB]
	AND	AL,attr_hidden+attr_system+attr_directory+attr_volume_id+attr_read_only
					; Look only at hidden bits
	CMP	AL,attr_hidden+attr_system+attr_directory+attr_volume_id+attr_read_only
					; All must be set
	JNZ	NOT_ALL

; NOTE WARNING DANGER-----
;    This DELALL stuff is not safe. It allows directories to be deleted.
;	It should ONLY be used by FORMAT in the ROOT directory.
;

	MOV	[DELALL],0	     ; DEL *.* - flag deleting all
NOT_ALL:
	MOV	[NoSetDir],1
	invoke	GetPathNoSet
	ASSUME	ES:NOTHING
	JNC	Del_found
	JNZ	bad_path
	OR	CL,CL
	JZ	bad_path
No_file:
	MOV	AX,error_file_not_found
ErrorReturn:
	STC
	LeaveCrit   critDisk
	return

bad_path:
	MOV	AX,error_path_not_found
	JMP	ErrorReturn

Del_found:
	JNZ	NOT_DIR 		; Check for dir specified
	CMP	DelAll,0		; DelAll = 0 allows delete of dir.
	JZ	Not_Dir
Del_access_err:
	MOV	AX,error_access_denied
	JMP	ErrorReturn

NOT_DIR:
	OR	AH,AH		; Check if device name
	JS	Del_access_err	; Can't delete I/O devices
;
; Main delete loop.  CURBUF+2:BX points to a matching directory entry.
;
DELFILE:
	OR	[FoundDel],fileFound	; file found, not deleted yet
;
; If we are deleting the Volume ID, then we set VOLUME_CHNG flag to make
; DOS issue a build BPB call the next time this drive is accessed.
;
	PUSH	DS
	MOV	AH,[DELALL]
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
;; Extended Attributes
;	PUSH	AX			 ;FT. save cluster of XA		;AN000;
;	MOV	AX,DS:[BX.dir_ExtCluster];FT.					;AN000;
;	MOV	[Del_ExtCluster],AX	 ;FT.					;AN000;
;	POP	AX			 ;FT,					;AN000;

;; Extended Attributes
	TEST	[Attrib],attr_read_only ; are we deleting RO files too?
	JNZ	DoDelete		; yes
	TEST	DS:[BX.dir_attr],attr_read_only
	JZ	DoDelete		; not read only
	POP	DS
	JMP	SHORT DelNxt		; Skip it (Note ES:BP not set)

DoDelete:
	call	REN_DEL_Check		; Sets ES:BP = [THISDPB]
	JNC	DEL_SHARE_OK
	POP	DS
	JMP	SHORT DelNxt		; Skip it

DEL_SHARE_OK:
	Assert	ISBUF,<DS,DI>,"Del_Share_OK"
	TEST	[DI.buf_flags],buf_dirty  ;LB. if already dirty 		;AN000;
	JNZ	yesdirty		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	[DI.buf_flags],buf_dirty
yesdirty:
	MOV	[BX],AH 		; Put in E5H or 0
	MOV	BX,[SI] 		; Get firclus pointer
	POP	DS
	DOSAssume   CS,<DS>,"Del_Share_OK"
	OR	[FoundDel],fileDeleted	; Deleted file
	CMP	BX,2
	JB	DELEXT			; File has invalid FIRCLUS (too small)
	CMP	BX,ES:[BP.dpb_max_cluster]
	JA	DELEXT			; File has invalid FIRCLUS (too big)
;; FastSeek 10/27/86
	CALL	Delete_FSeek		; delete the fastseek entry
;; FastSeek 10/27/86

	invoke	RELEASE 		; Free file data
	JC	No_fileJ
; DOS 3.3  FastOpen

	CALL	FastOpen_Delete 	; delete the dir info in fastopen


; DOS 3.3  FastOpen
;; Extended Attributes
DELEXT:

;	MOV	BX,[Del_ExtCluster]	;FT. delete XA cluster chain		;AN000;
;	CMP	BX,2			;FT.					;AN000;
;	JB	DELNXT			;FT. XA has invalid cluster (too small) ;AN000;
;	CMP	BX,ES:[BP.dpb_max_cluster];FT.					;AN000;
;	JA	DELNXT			;FT. XA has invalid cluster (too big)	;AN000;
;	invoke	RELEASE 		;FT. Free extended attrs cluster	;AN000;
;	JC	No_fileJ		;FT.					;AN000;

;; Extended Attributes
DELNXT:
	LES	BP,[THISDPB]		; Possible to get here without this set
	invoke	GETENTRY		; Registers need to be reset
	JC	No_fileJ
	invoke	NEXTENT
if DEBUG
	JC	Flsh
	JMP	DelFile
flsh:
ELSE
	JNC	DELFILE
ENDIF
	LES	BP,[THISDPB]		; NEXTENT sets ES=DOSGROUP
	MOV	AL,ES:[BP.dpb_drive]
	invoke	FLUSHBUF
	JC	No_fileJ
;
; Now we need to test FoundDel for our flags.  The cases to consider are:
;
;   not found not deleted		file not found
;   not found	  deleted		*** impossible ***
;	found not deleted		access denied (read-only)
;	found	  deleted		no error
;
	TEST	FoundDel,fileDeleted	; did we delete a file?
	JZ	DelError		; no, figure out what's wrong.
; We set VOLCHNG_FLAG to indicate that we have changed the volume label
; and to force the DOS to issue a media check.
	TEST	[Attrib],attr_volume_id
	jz	No_Set_Flag
	PUSH	AX
	PUSH	ES
	PUSH	DI
	LES	DI,[THISCDS]
ASSUME	ES:NOTHING
	MOV	AH,BYTE PTR ES:[DI]	; Get drive
	SUB	AH,'A'                  ; Convert to 0-based
	mov	byte ptr [VOLCHNG_FLAG],AH
	XOR	BH,BH			;>32mb delte volume id from boot record ;AN000;
	invoke	Set_Media_ID		;>32mb set voulme id to boot record	;AN000;
	invoke	FATRead_CDS		; force media check
	POP	DI
	POP	ES
	POP	AX
No_Set_Flag:
	LeaveCrit   critDisk		; carry is clear
	return
DelError:
	TEST	FoundDel,fileFound	; not deleted.	Did we find file?
	JNZ	Del_access_errJ 	; yes. Access denied
No_fileJ:
	JMP	No_file 		; Nope
Del_Access_errJ:
	JMP	Del_access_err

EndProc DOS_DELETE

Break	<REN_DEL_Check - check for access for rename and delete>

; Inputs:
;	[THISDPB] set
;	[CURBUF+2]:BX points to entry
;	[CURBUF+2]:SI points to firclus field of entry
;	[WFP_Start] points to name
; Function:
;	Check for Exclusive access on given file.
;	  Used by RENAME, SET_FILE_INFO, and DELETE.
; Outputs:
;	ES:BP = [THISDPB]
;	NOTE: The WFP string pointed to by [WFP_Start] Will be Modified.  The
;		last element will be loaded from the directory entry.  This is
;		so the name given to the sharer doesn't have any meta chars in
;		it.
;	Carry set if sharing violation, INT 24H generated
;	    NOTE THAT AX IS NOT error_sharing_violation.
;		This is because input AX is preserved.
;		Caller must set the error if needed.
;	Carry clear
;		OK
; AX,DS,BX,SI,DI preserved

	procedure  REN_DEL_Check,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	PUSH	DS
	PUSH	DI
	PUSH	AX
	PUSH	BX
	PUSH	SI		; Save CURBUF pointers
	context ES
ASSUME	ES:DOSGROUP
	MOV	DI,[WFP_START]	; ES:DI -> WFP
	MOV	SI,BX
	MOV	DS,WORD PTR [CURBUF+2]	; DS:SI -> entry (FCB style name)
	MOV	BX,DI		; Set backup limit for skipback
	ADD	BX,2		; Skip over d: to point to leading '\'
	invoke	StrLen		; CX is length of ES:DI including NUL
	DEC	CX		; Don't include nul in count
	ADD	DI,CX		; Point to NUL at end of string
	invoke	SkipBack	; Back up one element
	INC	DI		; Point to start of last element
	MOV	[SAVE_BX],DI	;IFS. save for DOS_RENAME			   ;AN000;
	invoke	PackName	; Transfer name from entry to ASCIZ tail.
	POP	SI		; Get back entry pointers
	POP	BX
	PUSH	BX
	PUSH	SI		; Back on stack
	context DS
ASSUME	DS:DOSGROUP
;
; Close the file if possible by us.
;
if installed
	Call	JShare + 13 * 4
else
	Call	ShCloseFile
endif
	MOV	WORD PTR [THISSFT+2],DS
	MOV	WORD PTR [THISSFT],OFFSET DOSGROUP:AUXSTACK - (SIZE sf_entry)
				; Scratch space
	XOR	AH,AH		; Indicate file to DOOPEN (high bit off)
	invoke	DOOPEN		; Fill in SFT for share check
	LES	DI,[THISSFT]
	MOV	ES:[DI.sf_mode],sharing_deny_both   ; requires exclusive access
	MOV	ES:[DI.sf_ref_count],1	; Pretend open
	invoke	ShareEnter
	jc	CheckDone
	LES	DI,[THISSFT]
	MOV	ES:[DI.sf_ref_count],0	; Pretend closed and free
	invoke	SHAREEND		; Tell sharer we're done with THISSFT
	CLC
CheckDone:
	LES	BP,[THISDPB]
	POP	SI
	POP	BX
	POP	AX
	POP	DI
	POP	DS
	return

EndProc REN_DEL_Check

Break	<FastOpen_Delete - delete dir info in fastopen>

; Inputs:
;	None
; Function:
;	Call FastOpen to delete the dir info.
; Outputs:
;	None
;
;

	procedure  FastOpen_Delete,NEAR
ASSUME	DS:NOTHING,ES:NOTHING
	PUSHF			; save flag
	PUSH	SI		; save registers
	PUSH	BX
	PUSH	AX

	MOV	SI,[WFP_Start]			       ; ds:si points to path name
	MOV	AL,FONC_delete			       ; al = 3
fastinvoke:
	MOV	BX,OFFSET DOSGROUP:FastTable + 2
	CALL	DWORD PTR [BX]			       ; call fastopen

	POP	AX		; restore registers
	POP	BX
	POP	SI
	POPF			; restore flag
	return
EndProc FastOpen_Delete


Break	<FastOpen_Update - update dir info in fastopen>

; Inputs:
;	DL     drive number (A=0,B=1,,,)
;	CX     first cluster #
;	AH     0 updates dir entry
;	       1 updates CLUSNUM  , BP = new CLUSNUM
;	ES:DI  directory entry
; Function:
;	Call FastOpen to update the dir info.
; Outputs:
;	None
;
;

	procedure  FastOpen_Update,NEAR
ASSUME	DS:NOTHING,ES:NOTHING
	PUSHF			; save flag
	PUSH	SI
	PUSH	BX		; save regs
	PUSH	AX

	MOV	AL,FONC_update			       ; al = 4
	JMP	fastinvoke

EndProc FastOpen_Update

Break	<FastSeek_Open - create a file extent cache entry>

; Inputs:
;	DL     drive number (0=A,1=B,,,)
;	CX     first cluster #
; Function:
;	Create a file extent cache entry
; Outputs:
;	None
;
;

	procedure  FastSeek_Open,NEAR						;AN000;
ASSUME	DS:NOTHING,ES:NOTHING							;AN000;
										;AN000;
	TEST	[FastSeekflg],Fast_yes	       ; Fastseek installed ?		;AN000;
	JZ	fs_no11 		       ; no				;AN000;
	PUSH	SI			       ; save regs			;AN000;
	PUSH	AX								;AN000;
	MOV	AL,FSEC_open		       ; al = 11			;AN000;
fseek_disp:									;AN000;
	CALL	FSeek_dispatch		       ; call fastseek			;AN000;
	POP	AX			       ; restore regs			;AN000;
	POP	SI								;AN000;
fs_no11:									;AN000;
	return				       ; return 			;AN000;
EndProc FastSeek_Open								;AN000;

; Inputs:
;	none
; Function:
;	Call Fastseek
; Outputs:
;	Output of Fastseek
;

	procedure  FSeek_dispatch,NEAR
ASSUME	DS:NOTHING,ES:NOTHING							;AN000;
										;AN000;
	MOV	AH,FastSeek_ID		      ; fastseek ID  = 1		;AN000;
 entry Fast_Dispatch			      ; future fastxxxx entry		;AN000;
	PUSH	AX			      ; save ax 			;AN000;
	MOV	AL,AH			      ; al=fastseek ID			;AN000;
	XOR	AH,AH			      ; 				;AN000;
	DEC	AX			      ; 				;AN000;
	SHL	AX,1			      ; times 4 to get entry offset	;AN000;
	SHL	AX,1								;AN000;
										;AN000;
	MOV	SI,OFFSET DOSGROUP:FastTable + 2	; index to the		;AN000;
	ADD	SI,AX					; fastxxxx entry	;AN000;
	POP	AX					; restore ax		;AN000;
	CALL	DWORD PTR CS:[SI]			; call fastseek 	;AN000;
	return
EndProc FSeek_dispatch

Break	<FastSeek_Close -  close a file extent entry>

; Inputs:
;	DL     drive number (0=A,1=B,,,)
;	CX     first cluster #
; Function:
;	Close a file extent entry
; Outputs:
;	None
;
;

	procedure  FastSeek_Close,NEAR
ASSUME	DS:NOTHING,ES:NOTHING							;AN000;

	TEST	[FastSeekflg],Fast_yes	       ; Fastseek installed ?		;AN000;
	JZ	fs_no2			       ; no				;AN000;
	PUSH	SI			       ; save regs			;AN000;
	PUSH	AX			       ;				;AN000;
	MOV	AL,FSEC_close		       ; al = 12			;AN000;
	JMP	fseek_disp		       ; call fastseek			;AN000;
EndProc FastSeek_Close								;AN000;

Break	<FastSeek_Delete - delete a file extent  entry>

; Inputs:
;	DL     drive number (0=A,1=B,,,)
;	CX     first cluster #
; Function:
;	Delete a file extent entry
; Outputs:
;	None
;
;

	procedure  FastSeek_Delete,NEAR
ASSUME	DS:NOTHING,ES:NOTHING							;AN000;
										;AN000;
	TEST	[FastSeekflg],Fast_yes	       ; Fastseek installed ?		;AN000;
	JZ	fs_no2			       ; no				;AN000;
	PUSH	SI			       ; save regs			;AN000;
	PUSH	AX								;AN000;
	MOV	AL,FSEC_delete		       ; al=13				;AN000;
	JMP	fseek_disp		       ; call fastseek			;AN000;
EndProc FastSeek_Delete 							;AN000;
										;AN000;
; Inputs:
;	FastSeekflg= 0 , not installed
;		     1 , installed
;	BX= first cluster number
;	ES:BP = addr of DPB
; Function:
;	Delete a file extent entry
; Outputs:
;	None
;

	procedure  Delete_FSeek,NEAR						;AN000;
ASSUME	DS:NOTHING,ES:NOTHING							;AN000;
	TEST	[FastSeekflg],Fast_yes	       ; Fastseek installed ?		;AN000;
	JZ	fs_no2			       ; no				;AN000;
	PUSH	CX			; save regs				;AN000;
	PUSH	DX								;AN000;
	MOV	CX,BX			; first cluster #			;AN000;
	MOV	DL,ES:[BP.dpb_drive]	; drive #				;AN000;
	CALL	FastSeek_Delete 	; call fastseek to delete an entry	;AN000;
	POP	DX			; restore regs				;AN000;
	POP	CX								;AN000;
fs_no2: 									;AN000;
	return				; exit					;AN000;
EndProc Delete_FSeek								;AN000;

Break	<FastSeek_Lookup - look up a cluster number>

; Inputs:
;	FSeek_drive : drive number (0=A,1=B,,,)
;	FSeek_firclus: first cluster #
;	FSeek_logclus: logical cluster #
; Function:
;	Look up a physical cluster #
; Outputs:
;	carry clear, DI = physical cluster #, FSeek_logsave=DI-1
;	carry set,
;		   partially found, DI=last physical cluster #
;		      FSeek_logsave=last logical cluster #

	procedure  FastSeek_Lookup,NEAR 					;AN000;
ASSUME	DS:NOTHING,ES:NOTHING							;AN000;

	PUSH	AX			; save ax				;AN000;
	MOV	AL,FSEC_lookup		; al = 14				;AN000;
	PUSH	BX			; save bx				;AN000;
	CALL	FS_doit 		; call fastseek 			;AN000;
	MOV	[FSeek_logsave],BX	; save returned BX			;AN000;
	POP	BX			; restore bx				;AN000;
	POP	AX			; restore ax				;AN000;
	return									;AN000;
EndProc FastSeek_Lookup 							;AN000;
										;AN000;

Break	<FastSeek_Insert - insert a cluster number>

; Inputs:
;	FSeek_drive : drive number (0=A,1=B,,,)
;	FSeek_firclus: first cluster #
;	FSeek_logclus: logical cluster #
;	DI: physical cluster # to be inserted
; Function:
;	insert a physical cluster #
; Outputs:
;	none
;

	procedure  FastSeek_Insert,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	TEST	[FastSeekflg],FS_insert 	; insert mode set ?		;AN000;
	JZ	no_insert			; no				;AN000;
										;AN000;
	PUSH	AX				; save regs			;AN000;
	PUSH	BX								;AN000;
	MOV	AL,FSEC_insert			; al = 15			;AN000;
FSentry:									;AN000;
	CALL	FS_doit 			; call fastseek 		;AN000;
	POP	BX				; restore regs			;AN000;
	POP	AX								;AN000;
no_insert:
	return
EndProc FastSeek_insert

Break	<FastSeek_Truncate - truncate cluster numbers>

; Inputs:
;	FSeek_drive : drive number (0=A,1=B,,,)
;	FSeek_firclus: first cluster #
;	FSeek_logclus: logical cluster #
; Function:
;	truncate physical cluster #s starting from FSeek_logclus
; Outputs:
;	none
;

	procedure  FastSeek_Truncate,NEAR
ASSUME	DS:NOTHING,ES:NOTHING
										;AN000;
	TEST	[FastSeekflg],Fast_yes	       ; Fastseek installed ?		;AN000;
	JZ	fs_no			       ; no				;AN000;
	PUSH	AX			       ; save regs			;AN000;
	PUSH	BX								;AN000;
	MOV	AL,FSEC_truncate	       ; al = 16			;AN000;
	JMP	FSentry 		       ; call fastseek			;AN000;
fs_no:										;AN000;
	return									;AN000;
EndProc FastSeek_Truncate							;AN000;

; Inputs:
;	FSeek_drive : drive number (0=A,1=B,,,)
;	FSeek_firclus: first cluster #
;	FSeek_logclus: logical cluster #
; Function:
;	set up parameters and call fastseek
; Outputs:
;	outputs of fastseek
;
	procedure  FS_doit,NEAR
ASSUME	DS:NOTHING,ES:NOTHING
										;AN000;
	PUSH	CX			; save regs				;AN000;
	PUSH	DX								;AN000;
	PUSH	SI								;AN000;
	MOV	DL,[FSeek_drive]	; set drive #				;AN000;
	MOV	CX,[FSeek_firclus]	; set 1st cluster #			;AN000;
	MOV	BX,[FSeek_logclus]	; set logical cluster # 		;AN000;
										;AN000;
	CALL	FSeek_dispatch		; call fastseek 			;AN000;
										;AN000;
					; carry clear if found in DI		;AN000;
	POP	SI			; otherwise, carry set			;AN000;
										;AN000;
	POP	DX			; restore regs				;AN000;
	POP	CX								;AN000;
	return									;AN000;
EndProc FS_doit 								;AN000;


; Inputs:
;	same as DOS_SEARCH_FIRST
; Function:
;	do a IFS search first
; Outputs:
;	same as DOS_SEARCH_FIRST
;
	procedure  IFS_SEARCH_FIRST,NEAR					;AN000;
	DOSAssume   CS,<DS>,"IFS_SEARCH_FIRST"                                  ;AN000;
	ASSUME	ES:NOTHING							;AN000;

;	MOV	WORD PTR [DMAADD+2],DS	       ;IFS. replace with scratch area	;AN000;;AN000;
;	MOV	WORD PTR [DMAADD],OFFSET DOSGROUP:RENAMEDMA	;IFS.		;AN000;
;	invoke	SET_THISDPB		       ;IFS. THISDPB set		;AN000;
;	invoke	DOS_SEARCH_FIRST	       ;IFS. search first		;AN000;
;	return									;AN000;
EndProc IFS_SEARCH_FIRST							;AN000;


; Inputs:
;	THISDPB set
;	WFP_Start points to name
; Function:
;	do a IFS REN_DEL_CHECK
; Outputs:
;	same as REN_DEL_CHECK
;
	procedure  IFS_REN_DEL_CHECK,NEAR					;AN000;
	DOSAssume   CS,<DS>,"IFS_REN_DEL_CHECK"                                 ;AN000;
	ASSUME	ES:NOTHING							;AN000;

;	MOV	AX,WORD PTR [DMAADD+2]	       ;IFS. set up			;AN000;;AN000;
;	MOV	WORD PTR [CURBUF+2],AX	       ;IFS. curbuf+2 : bx -> dir entry ;AN000;
;	MOV	BX,WORD PTR [DMAADD]	       ;IFS.				;AN000;
;	ADD	BX,21			       ;IFS.				;AN000;
;	MOV	SI,BX			       ;IFS. curbuf+2:si -> dir_first	;AN000;
;	ADD	SI,dir_first		       ;IFS.				;AN000;
;	EnterCrit   critDisk		       ;IFS. enter critical section	;AN000;
;	CALL	REN_DEL_Check		       ;IFS. share check		;AN000;
;	LeaveCrit   critDisk		       ;IFS. leave critical section	;AN000;
;	return									;AN000;
EndProc IFS_REN_DEL_CHECK							;AN000;

CODE	ENDS
    END
