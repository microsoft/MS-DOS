;	SCCSID = @(#)misc.asm	1.1 85/04/10
TITLE MISC - Miscellanious routines for MS-DOS
NAME  MISC
;
; Miscellaneous system calls most of which are CAVEAT
;
;   $SLEAZEFUNC
;   $SLEAZEFUNCDL
;   $GET_INDOS_FLAG
;   $GET_IN_VARS
;   $GET_DEFAULT_DPB
;   $GET_DPB
;   $DISK_RESET
;   $SETDPB
;   $Dup_PDB
;   $CREATE_PROCESS_DATA_BLOCK
;   SETMEM
;   FETCHI_CHECK
;   $GSetMediaID
;
;   Revision  history:
;
;	Created: ARR 30 March 1983
;
;	A000   version 4.00   Jan. 1988
;	A001   D490 -- Change IOCTL subfunctions from 63h, 43h to 66h , 46h

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
.cref
.list

ENTRYPOINTSEG	EQU	0CH
MAXDIF		EQU	0FFFH
SAVEXIT 	EQU	10

	i_need	LASTBUFFER,DWORD
	i_need	BuffHead,DWORD
	i_need	INDOS,BYTE
	i_need	SYSINITVAR,BYTE
	i_need	CurrentPDB,WORD
	i_need	CreatePDB,BYTE
	i_need	FATBYTE,BYTE
	i_need	THISCDS,DWORD
	i_need	THISSFT,DWORD
	i_need	FETCHI_TAG,WORD 		 ; for TAG CHECK
	i_need	BUF_HASH_COUNT,WORD		 ;AN000; number of Hash Entries
	i_need	HIGH_SECTOR,WORD		 ;AN000; high word of sector #
	i_need	DOS34_FLAG,WORD 		 ;AN000;
if debug
	I_need	BugLev,WORD
	I_need	BugTyp,WORD
include bugtyp.asm
endif

BREAK <SleazeFunc -- get a pointer to media byte>

;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
; Inputs:
;	None
; Function:
;	Return Stuff sort of like old get fat call
; Outputs:
;	DS:BX = Points to FAT ID byte (IBM only)
;		GOD help anyone who tries to do ANYTHING except
;		READ this ONE byte.
;	DX = Total Number of allocation units on disk
;	CX = Sector size
;	AL = Sectors per allocation unit
;	   = -1 if bad drive specified

	procedure   $SLEAZEFUNC,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	MOV	DL,0

entry	$SLEAZEFUNCDL
;Same as above except drive passed in DL (0=default, 1=A, 2=B, ...)

	context DS
	MOV	AL,DL
	invoke	GETTHISDRV		; Get CDS structure
SET_AL_RET:
;	MOV	AL,error_invalid_drive	; Assume error				;AC000;
	JC	BADSLDRIVE
	invoke	DISK_INFO
	JC	SET_AL_RET		; User FAILed to I 24
	MOV	[FATBYTE],AH
; NOTE THAT A FIXED MEMORY CELL IS USED --> THIS CALL IS NOT
; RE-ENTRANT. USERS BETTER GET THE ID BYTE BEFORE THEY MAKE THE
; CALL AGAIN
	MOV	DI,OFFSET DOSGROUP:FATBYTE
	XOR	AH,AH			; AL has sectors/cluster
	invoke	get_user_stack
ASSUME	DS:NOTHING
	MOV	[SI.user_CX],CX
	MOV	[SI.user_DX],BX
	MOV	[SI.user_BX],DI
	MOV	[SI.user_DS],CS 	; stash correct pointer
	return
BADSLDRIVE:
	transfer    FCB_Ret_ERR
EndProc $SLEAZEFUNC
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

BREAK <$Get_INDOS_Flag -- Return location of DOS critical-section flag>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
; Inputs:
;	None
; Function:
;	Returns location of DOS status for interrupt routines
; Returns:
;	Flag location in ES:BX

	procedure   $GET_INDOS_FLAG,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	invoke	get_user_stack
	MOV	[SI.user_BX],OFFSET DOSGROUP:INDOS
	MOV	[SI.user_ES],SS
	return
EndProc $GET_INDOS_FLAG
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

BREAK <$Get_IN_VARS -- Return a pointer to DOS variables>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
; Return a pointer to interesting DOS variables This call is version
; dependent and is subject to change without notice in future versions.
; Use at risk.
	procedure   $GET_IN_VARS,NEAR
	invoke	get_user_stack
	MOV	[SI.user_BX],OFFSET DOSGROUP:SYSINITVAR
	MOV	[SI.user_ES],SS
	return
EndProc $GET_IN_VARS
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;


BREAK <$Get_Default_DPB,$Get_DPB -- Return pointer to DPB>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
; Inputs:
;	None
; Function:
;	Return pointer to drive parameter table for default drive
; Returns:
;	DS:BX points to the DPB
;	AL = 0 If OK, = -1 if bad drive (call 50 only)

	procedure   $GET_DEFAULT_DPB,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

	MOV	DL,0

	entry	$GET_DPB
; Same as above only drive passed in DL (0=default, 1=A, 2=B, ...)

	context DS
	MOV	AL,DL
	invoke	GETTHISDRV		; Get CDS structure
	JC	ISNODRV 		; no valid drive
	LES	DI,[THISCDS]		; check for net CDS
	TEST	ES:[DI.curdir_flags],curdir_isnet
	JNZ	ISNODRV 		; No DPB to point at on NET stuff
	EnterCrit CritDisk
	invoke	FATRead_CDS		; Force Media Check and return DPB
	LeaveCrit CritDisk
	JC	ISNODRV 		; User FAILed to I 24, only error we
					;   have.
	invoke	get_user_stack
ASSUME	DS:NOTHING
	MOV	[SI.user_BX],BP
	MOV	[SI.user_DS],ES
	XOR	AL,AL
	return

ISNODRV:
	MOV	AL,-1
	return
EndProc $GET_Default_dpb
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;


BREAK <$Disk_Reset -- Flush out all dirty buffers>

	procedure   $DISK_RESET,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	None
; Function:
;	Flush and invalidate all buffers
; Returns:
;	Nothing

	MOV	AL,-1
 entry $DISK_RESET2
	context DS
	EnterCrit   critDisk
	OR	[DOS34_FLAG],FROM_DISK_RESET					;AN000;
	invoke	FLUSHBUF
	AND	[DOS34_FLAG],NO_FROM_DISK_RESET 				;AN000;
;
; We will "ignore" any errors on the flush, and go ahead and invalidate.  This
; call doesn't return any errors and it is supposed to FORCE a known state, so
; let's do it.
;
; Invalidate 'last-buffer' used
;
	MOV	BX,-1
	MOV	WORD PTR [LASTBUFFER+2],BX
	MOV	WORD PTR [LASTBUFFER],BX
;
;	TEST	[DOS34_FLAG],IFS_DRIVE_RESET	 ;AN000;;IFS. from ifs call back ?
;	JZ	FreeDone			 ;AN000;;IFS. no
;	AND	[DOS34_FLAG],NO_IFS_DRIVE_RESET  ;AN000;;IFS. clear the flag
;	LeaveCrit   critDisk			 ;AN000;;IFS.
;	return					 ;AN000;;IFS. return
FreeDone:
	LeaveCrit   critDisk
	MOV	AX,-1
	CallInstall NetFlushBuf,multNET,32
	return
EndProc $DISK_RESET

BREAK <$SetDPB - Create a valid DPB from a user-specified BPB>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
	procedure   $SETDPB,NEAR
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	ES:BP Points to DPB
;	DS:SI Points to BPB
; Function:
;	Build a correct DPB from the BPB
; Outputs:
; ES:BP and DS preserved all others destroyed

	MOV	DI,BP
	ADD	DI,2			; Skip over dpb_drive and dpb_UNIT
	LODSW
	STOSW				; dpb_sector_size
	CMP	BYTE PTR [SI.BPFTCNT-2],0     ; FAT file system drive		;AN000;
	JNZ	yesfat			      ; yes				;AN000;
	MOV	BYTE PTR ES:[DI.dpb_FAT_count-4],0
	JMP	setend			      ; NO				;AN000;
yesfat:
	MOV	DX,AX
	LODSB
	DEC	AL
	STOSB				; dpb_cluster_mask
	INC	AL
	XOR	AH,AH
LOG2LOOP:
	TEST	AL,1
	JNZ	SAVLOG
	INC	AH
	SHR	AL,1
	JMP	SHORT LOG2LOOP
SAVLOG:
	MOV	AL,AH
	STOSB				; dpb_cluster_shift
	MOV	BL,AL
	MOVSW				; dpb_first_FAT Start of FAT (# of reserved sectors)
	LODSB
	STOSB				; dpb_FAT_count Number of FATs
;	OR	AL,AL			; NONFAT ?				;AN000;
;	JZ	setend			; yes, don't do anything                ;AN000;
	MOV	BH,AL
	LODSW
	STOSW				; dpb_root_entries Number of directory entries
	MOV	CL,5
	SHR	DX,CL			; Directory entries per sector
	DEC	AX
	ADD	AX,DX			; Cause Round Up
	MOV	CX,DX
	XOR	DX,DX
	DIV	CX
	MOV	CX,AX			; Number of directory sectors
	INC	DI
	INC	DI			; Skip dpb_first_sector
	MOVSW				; Total number of sectors in DSKSIZ (temp as dpb_max_cluster)
	LODSB
	MOV	ES:[BP.dpb_media],AL	; Media byte
	LODSW				; Number of sectors in a FAT
	STOSW				;AC000;;>32mb dpb_FAT_size
	MOV	DL,BH			;AN000;;>32mb
	XOR	DH,DH			;AN000;;>32mb
	MUL	DX			;AC000;;>32mb Space occupied by all FATs
	ADD	AX,ES:[BP.dpb_first_FAT]
	STOSW				; dpb_dir_sector
	ADD	AX,CX			; Add number of directory sectors
	MOV	ES:[BP.dpb_first_sector],AX

	MOV	CL,BL		       ;F.C. >32mb				;AN000;
	CMP	WORD PTR ES:[BP.DSKSIZ],0	;F.C. >32mb			;AN000;
	JNZ	normal_dpb	       ;F.C. >32mb				;AN000;
	XOR	CH,CH		       ;F.C. >32mb				;AN000;
	MOV	BX,WORD PTR [SI+BPB_BigTotalSectors-BPB_SectorsPerTrack]	;AN000;
	MOV	DX,WORD PTR [SI+BPB_BigTotalSectors-BPB_SectorsPerTrack+2]	;AN000;
	SUB	BX,AX		       ;AN000;;F.C. >32mb
	SBB	DX,0		       ;AN000;;F.C. >32mb
	OR	CX,CX		       ;AN000;;F.C. >32mb
	JZ	norot		       ;AN000;;F.C. >32mb
rott:				       ;AN000;;F.C. >32mb
	CLC			       ;AN000;;F.C. >32mb
	RCR	DX,1		       ;AN000;;F.C. >32mb
	RCR	BX,1		       ;AN000;;F.C. >32mb
	LOOP	rott		       ;AN000;;F.C. >32mb
norot:				       ;AN000;
	MOV	AX,BX		       ;AN000;;F.C. >32mb
	JMP	setend		       ;AN000;;F.C. >32mb
normal_dpb:
	SUB	AX,ES:[BP.DSKSIZ]
	NEG	AX			; Sectors in data area
;;	MOV	CL,BL			; dpb_cluster_shift
	SHR	AX,CL			; Div by sectors/cluster
setend:
	INC	AX
	MOV	ES:[BP.dpb_max_cluster],AX
	MOV	ES:[BP.dpb_next_free],0 ; Init so first ALLOC starts at
					; begining of FAT
	MOV	ES:[BP.dpb_free_cnt],-1 ; current count is invalid.
	return
EndProc $SETDPB
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

BREAK <$Create_Process_Data_Block,SetMem -- Set up process data block>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
;
; Inputs:   DX is new segment address of process
;	    SI is end of new allocation block
;
	procedure   $Dup_PDB,NEAR
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	MOV	CreatePDB,0FFH		; indicate a new process
	MOV	DS,CurrentPDB
	PUSH	SI
	JMP	SHORT	CreateCopy
EndProc $Dup_PDB

	procedure   $CREATE_PROCESS_DATA_BLOCK,NEAR
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

; Inputs:
;	DX = Segment number of new base
; Function:
;	Set up program base and copy term and ^C from int area
; Returns:
;	None
; Called at DOS init

	CALL	get_user_stack
	MOV	DS,[SI.user_CS]
	PUSH	DS:[PDB_Block_len]
CreateCopy:
	MOV	ES,DX
	XOR	SI,SI			; copy all 80h bytes
	MOV	DI,SI
	MOV	CX,80H
	REP	MOVSW
; DOS 3.3 7/9/86

	MOV	CX,FilPerProc		; copy handles in case of
	MOV	DI,PDB_JFN_Table	; Set Handle Count has been issued
	PUSH	DS
	LDS	SI,DS:[PDB_JFN_Pointer]
	REP	MOVSB
	POP	DS

; DOS 3.3 7/9/86
	TEST	CreatePDB,0FFh		; Shall we create a process?
	JZ	Create_PDB_cont 	; nope, old style call
;
; Here we set up for a new process...
;

	PUSH	CS			; Called at DOSINIT time, NO SS
	POP	DS
	DOSAssume   CS,<DS>,"MISC/Create_Copy"
	XOR	BX,BX			; dup all jfns
	MOV	CX,FilPerProc		; only 20 of them

Create_dup_jfn:
	PUSH	ES			; save new PDB
	invoke	SFFromHandle		; get sf pointer
	MOV	AL,-1			; unassigned JFN
	JC	CreateStash		; file was not really open
	TEST	ES:[DI].sf_flags,sf_no_inherit
	JNZ	CreateStash		; if no-inherit bit is set, skip dup.
;
; We do not inherit network file handles.
;
	MOV	AH,BYTE PTR ES:[DI].sf_mode
	AND	AH,sharing_mask
	CMP	AH,sharing_net_fcb
	jz	CreateStash
;
; The handle we have found is duplicatable (and inheritable).  Perform
; duplication operation.
;
	MOV	WORD PTR [THISSFT],DI
	MOV	WORD PTR [THISSFT+2],ES
	invoke	DOS_DUP 		; signal duplication
;
; get the old sfn for copy
;
	invoke	pJFNFromHandle		; ES:DI is jfn
	MOV	AL,ES:[DI]		; get sfn
;
; Take AL (old sfn or -1) and stash it into the new position
;
CreateStash:
	POP	ES
	MOV	ES:[BX].PDB_JFN_Table,AL; copy into new place!
	INC	BX			; next jfn...
	LOOP	create_dup_jfn

	MOV	BX,CurrentPDB		; get current process
	MOV	ES:[PDB_Parent_PID],BX	; stash in child
	MOV	[CurrentPDB],ES
	ASSUME	DS:NOTHING
	MOV	DS,BX
;
; end of new process create
;
Create_PDB_cont:
	MOV	BYTE PTR [CreatePDB],0h ; reset flag
	POP	AX

	entry	SETMEM
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

; Inputs:
;	AX = Size of memory in paragraphs
;	DX = Segment
; Function:
;	Completely prepares a program base at the
;	specified segment.
; Called at DOS init
; Outputs:
;	DS = DX
;	ES = DX
;	[0] has INT int_abort
;	[2] = First unavailable segment
;	[5] to [9] form a long call to the entry point
;	[10] to [13] have exit address (from int_terminate)
;	[14] to [17] have ctrl-C exit address (from int_ctrl_c)
;	[18] to [21] have fatal error address (from int_fatal_abort)
; DX,BP unchanged. All other registers destroyed.

	XOR	CX,CX
	MOV	DS,CX
	MOV	ES,DX
	MOV	SI,addr_int_terminate
	MOV	DI,SAVEXIT
	MOV	CX,6
	REP	MOVSW
	MOV	ES:[2],AX
	SUB	AX,DX
	CMP	AX,MAXDIF
	JBE	HAVDIF
	MOV	AX,MAXDIF
HAVDIF:
	SUB	AX,10H			; Allow for 100h byte "stack"
	MOV	BX,ENTRYPOINTSEG	;	in .COM files
	SUB	BX,AX
	MOV	CL,4
	SHL	AX,CL
	MOV	DS,DX
	MOV	WORD PTR DS:[PDB_CPM_Call+1],AX
	MOV	WORD PTR DS:[PDB_CPM_Call+3],BX
	MOV	DS:[PDB_Exit_Call],(int_abort SHL 8) + mi_INT
	MOV	BYTE PTR DS:[PDB_CPM_Call],mi_Long_CALL
	MOV	WORD PTR DS:[PDB_Call_System],(int_command SHL 8) + mi_INT
	MOV	BYTE PTR DS:[PDB_Call_System+2],mi_Long_RET
	MOV	WORD PTR DS:[PDB_JFN_Pointer],PDB_JFN_Table
	MOV	WORD PTR DS:[PDB_JFN_Pointer+2],DS
	MOV	WORD PTR DS:[PDB_JFN_Length],FilPerProc
;
; The server runs several PDB's without creating them VIA EXEC.  We need to
; enumerate all PDB's at CPS time in order to find all references to a
; particular SFT.  We perform this by requiring that the server link together
; for us all sub-PDB's that he creates.  The requirement for us, now, is to
; initialize this pointer.
;
	MOV	word ptr DS:[PDB_Next_PDB],-1
	MOV	word ptr DS:[PDB_Next_PDB+2],-1
	return

EndProc $CREATE_PROCESS_DATA_BLOCK

;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
	procedure   FETCHI_CHECK,NEAR
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSHF
	CMP	CS:[FETCHI_TAG],22642
	JZ	TAG_OK
	invoke	DOSINIT 	      ; go to hell
TAG_OK:
	POPF
	return
EndProc FETCHI_CHECK

BREAK <$GSetMediaID -- get set media ID>
; Inputs:
;	BL= drive number as defined in IOCTL
;	AL= 0 get media ID
;	    1 set media ID
;	DS:DX= buffer containing information
;		DW  0  info level (set on input)
;		DD  ?  serial #
;		DB  11 dup(?)  volume id
;		DB   8 dup(?)  file system type
; Function:
;	Get or set media ID
; Returns:
;	carry clear, DS:DX is filled
;	carry set, error

	procedure   $GSetMediaID,NEAR ;AN000;
ASSUME	DS:NOTHING,ES:NOTHING	      ;AN000;

	MOV	CX,0866H	      ;AN000;MS.; assume get  for IOCTL
	CMP	AL,0		      ;AN001;MS.; get ?
	JZ	doioctl 	      ;AN000;MS.; yes
	CMP	AL,1		      ;AN000;MS.; set ?
	JNZ	errorfunc	      ;AN000;MS.; no
	MOV	CX,0846H	      ;AN001;MS.;
doioctl:			      ;AN000;
	MOV	AL,0DH		      ;AN000;MS.; generic IOCTL
	invoke	$IOCTL		      ;AN000;MS.; let IOCTL take care of it
	return			      ;AN000;MS.;
errorfunc:			      ;AN000;
	error	error_invalid_function;AN000;MS.	; invalid function
EndProc $GSetMediaID		      ;AN000;

CODE	ENDS
END
