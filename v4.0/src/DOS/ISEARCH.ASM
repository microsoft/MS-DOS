;	SCCSID = @(#)isearch.asm	1.1 85/04/10
TITLE	DOS_SEARCH - Internal SEARCH calls for MS-DOS
NAME	DOS_SEARCH
; Low level routines for doing local and NET directory searches
;
;   DOS_SEARCH_FIRST
;   DOS_SEARCH_NEXT
;   RENAME_NEXT
;
;   Revision history:
;
;	Created: ARR 30 March 1983
;	A000	version 4.00  Jan. 1988
;	A001	PTM 3564 -- serach for fastopen

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
INCLUDE fastopen.inc
INCLUDE fastxxxx.inc
.cref
.list

Installed = TRUE

	i_need	NoSetDir,BYTE
	i_need	Creating,BYTE
	i_need	THISCDS,DWORD
	i_need	CURBUF,DWORD
	i_need	DMAADD,DWORD
	i_need	DummyCDS,128
	i_need	THISDPB,DWORD
	i_need	THISDRV,BYTE
	i_need	NAME1,BYTE
	i_need	ATTRIB,BYTE
	i_need	DIRSTART,WORD
	i_need	LASTENT,WORD
	i_need	FOUND_DEV,BYTE
	I_need	WFP_Start,WORD
	i_need	EXTERR_LOCUS,BYTE
	i_need	FastopenFlg,BYTE
	I_need	DOS34_FLAG,WORD

; Inputs:
;	[WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL
;		terminated)
;	[CURR_DIR_END] Points to end of Current dir part of string
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[THISCDS] Points to CDS being used
;		(Low word = -1 if NUL CDS (Net direct request))
;	[SATTRIB] Is attribute of search, determines what files can be found
;	[DMAADD] Points to 53 byte buffer
; Function:
;	Initiate a search for the given file spec
; Outputs:
;	CARRY CLEAR
;	    The 53 bytes ot DMAADD are filled in as follows:
;
;	LOCAL
;	    Drive Byte (A=1, B=2, ...) High bit clear
;		NEVER STORE DRIVE BYTE AFTER  found_it
;	    11 byte search name with Meta chars in it
;	    Search Attribute Byte, attribute of search
;	    WORD LastEnt value
;	    WORD DirStart
;	    4 byte pad
;	    32 bytes of the directory entry found
;	NET
;	    21 bytes First byte has high bit set
;	    32 bytes of the directory entry found
;
;	CARRY SET
;	    AX = error code
;		error_no_more_files
;			No match for this file
;		error_path_not_found
;			Bad path (not in curr dir part if present)
;		error_bad_curr_dir
;			Bad path in current directory part of path
; DS preserved, others destroyed

	procedure   DOS_SEARCH_FIRST,NEAR
	DOSAssume   CS,<DS>,"DOS_Search_First"
	ASSUME	ES:NOTHING

	LES	DI,[THISCDS]
	CMP	DI,-1
	JNZ	TEST_RE_NET
IF NOT Installed
	transfer NET_SEQ_SEARCH_FIRST
ELSE
	MOV	AX,(multNET SHL 8) OR 25
	INT	2FH
	return
ENDIF

TEST_RE_NET:
	TEST	ES:[DI.curdir_flags],curdir_isnet
	JZ	LOCAL_SEARCH_FIRST
IF NOT Installed
	transfer NET_SEARCH_FIRST
ELSE
	MOV	AX,(multNET SHL 8) OR 27
	INT	2FH
	return
ENDIF

LOCAL_SEARCH_FIRST:
	EnterCrit   critDisk
	TEST	[DOS34_FLAG],SEARCH_FASTOPEN  ;AN000;
	JZ	NOFN			      ;AN000;
	OR	[FastOpenflg],Fastopen_Set    ;AN000;
NOFN:					      ;AN000;
	MOV	[NoSetDir],1		; if we find a dir, don't change to it
	CALL	CHECK_QUESTION		;AN000;;FO. is '?' in path
	JNC	norm_getpath		;AN000;;FO. no
	AND	[FastOpenflg],Fast_yes	;AN000;;FO. reset fastopen
norm_getpath:
	invoke	GetPath
getdone:
	JNC	find_check_dev
	JNZ	bad_path
	OR	CL,CL
	JZ	bad_path
find_no_more:
	MOV	AX,error_no_more_files
BadBye:
	AND	CS:[FastOpenflg],Fast_yes  ;AN000;;FO. reset fastopen

	STC
	LeaveCrit   critDisk
	return

bad_path:
	MOV	AX,error_path_not_found
	JMP	BadBye

find_check_dev:
	OR	AH,AH
	JNS	found_entry
	MOV	[LastEnt],-1		; Cause DOS_SEARCH_NEXT to fail
	INC	[Found_Dev]		; Tell DOS_RENAME we found a device
found_entry:
;
; We set the physical drive byte here Instead of after found_it; Doing
; a search-next may not have wfp_start set correctly
;
	LES	DI,[DMAADD]
	MOV	SI,WFP_Start		; get pointer to beginning
	LODSB
	SUB	AL,'A'-1                ; logical drive
	STOSB				; High bit not set (local)
found_it:
	LES	DI,[DMAADD]
	INC	DI
	PUSH	DS			;FO.;AN001; save ds
	TEST	[Fastopenflg],Set_For_Search	  ;FO.;AN001; from fastopen
	JZ	notfast 			  ;FO.;AN001;
	MOV	SI,BX				  ;FO.;AN001;
	MOV	DS,WORD PTR [CURBUF+2]		  ;FO.;AN001;
	JMP	SHORT movmov			  ;FO.;AN001;


notfast:
	MOV	SI,OFFSET DOSGROUP:NAME1; find_buf 2 = formatted name
movmov:
; Special E5 code
	MOVSB
	CMP	BYTE PTR ES:[DI-1],5
	JNZ	NOTKANJB
	MOV	BYTE PTR ES:[DI-1],0E5H
NOTKANJB:

	MOV	CX,10
	REP	MOVSB
	POP	DS			;FO.;AN001; restore ds


	MOV	AL,[Attrib]
	STOSB
	PUSH	AX			; Save AH device info
	MOV	AX,[LastEnt]
	STOSW
	MOV	AX,[DirStart]
	STOSW
; 4 bytes of 21 byte cont structure left for NET stuff
	ADD	DI,4
	POP	AX			; Recover AH device info
	OR	AH,AH
	JS	DOSREL			; Device entry is DOSGROUP relative
	CMP	WORD PTR [CURBUF],-1
	JNZ	OKSTORE
	TEST	[FastOPenFlg],Set_For_Search ;AN000;;FO. from fastopen and is good
	JNZ	OKSTORE 		     ;AN000;;FO.



	; The user has specified the root directory itself, rather than some
	; contents of it. We can't "find" that.
	MOV	WORD PTR ES:[DI-8],-1	; Cause DOS_SEARCH_NEXT to fail by
					;   stuffing a -1 at Lastent
	JMP	find_no_more

OKSTORE:
	MOV	DS,WORD PTR [CURBUF+2]
ASSUME	DS:NOTHING
DOSREL:
	MOV	SI,BX			; SI-> start of entry

; NOTE: DOS_RENAME depends on BX not being altered after this point

	MOV	CX,SIZE dir_entry
;;;;; 7/29/86
	MOV	AX,DI			; save the 1st byte addr
	REP	MOVSB
	MOV	DI,AX			; restore 1st byte addr
	CMP	BYTE PTR ES:[DI],05H	; special char check
	JNZ	NO05
	MOV	BYTE PTR ES:[DI],0E5H	; convert it back to E5
NO05:

;;;;; 7/29/86
	AND	CS:[FastOpenflg],Fast_yes  ;AN000;;FO. reset fastopen
	context DS
	CLC
	LeaveCrit   critDisk
	return

EndProc DOS_SEARCH_FIRST

BREAK <DOS_SEARCH_NEXT - scan for subsequent matches>

; Inputs:
;	[DMAADD] Points to 53 byte buffer returned by DOS_SEARCH_FIRST
;	    (only first 21 bytes must have valid information)
; Function:
;	Look for subsequent matches
; Outputs:
;	CARRY CLEAR
;	    The 53 bytes at DMAADD are updated for next call
;		(see DOS_SEARCH_FIRST)
;	CARRY SET
;	    AX = error code
;		error_no_more_files
;			No more files to find
; DS preserved, others destroyed

	procedure   DOS_SEARCH_NEXT,NEAR
	DOSAssume   CS,<DS>,"DOS_Search_Next"
	ASSUME	ES:NOTHING

	LES	DI,[DMAADD]
	MOV	AL,ES:[DI]
	TEST	AL,80H			; Test for NET
	JZ	LOCAL_SEARCH_NEXT
IF NOT Installed
	transfer NET_SEARCH_NEXT
ELSE
	MOV	AX,(multNET SHL 8) OR 28
	INT	2FH
	return
ENDIF

LOCAL_SEARCH_NEXT:
;AL is drive A=1
	MOV	[EXTERR_LOCUS],errLOC_Disk
	EnterCrit   critDisk
	MOV	WORD PTR ThisCDS,OFFSET DOSGROUP:DummyCDS
	MOV	WORD PTR ThisCDS+2,CS
	ADD	AL,'A'-1
	invoke	InitCDS

;	invoke	GetThisDrv		; Set CDS pointer

	JC	No_files		; Bogus drive letter
	LES	DI,[THISCDS]		; Get CDS pointer
	LES	BP,ES:[DI.curdir_devptr]; Get DPB pointer
	invoke	GOTDPB			; [THISDPB] = ES:BP

	mov	AL,ES:[BP.dpb_drive]
	mov	ThisDrv,AL

	MOV	WORD PTR [CREATING],0E500H
	MOV	[NoSetDir],1		; if we find a dir, don't change to it
	LDS	SI,[DMAADD]
ASSUME	DS:NOTHING
	LODSB				; Drive Byte

;	DEC	AL
;	MOV	[THISDRV],AL

	entry	RENAME_NEXT		; Entry used by DOS_RENAME

	context ES			; THIS BLOWS ES:BP POINTER TO DPB
	MOV	DI,OFFSET DOSGROUP:NAME1
	MOV	CX,11
	REP	MOVSB			; Search name
	LODSB				; Attribute
	MOV	[ATTRIB],AL
	LODSW				; LastEnt
	OR	AX,AX
	JNS	cont_load
No_files:
	JMP	find_no_more

cont_load:
	PUSH	AX			; Save LastEnt
	LODSW				; DirStart
	MOV	BX,AX
	context DS
	LES	BP,[THISDPB]		; Recover ES:BP
	invoke	SetDirSrch
	JNC	SEARCH_GOON
	POP	AX			; Clean stack
	JMP	No_files

SEARCH_GOON:
	invoke	StartSrch
	POP	AX
	invoke	GetEnt
	JC	No_files
	invoke	NextEnt
	JC	No_files
	XOR	AH,AH			; If Search_Next, can't be a DEV
	JMP	found_it

EndProc DOS_SEARCH_NEXT


;Input: [WFP_START]= pointer to final path
;Function: check '?' char
;Output: carry clear, if no '?'
;	 carry set, if '?' exists

	procedure   CHECK_QUESTION,NEAR ;AN000;
	ASSUME	ES:NOTHING,DS:NOTHING	;AN000;

	PUSH	CS			;AN000;;FO.
	POP	DS			;AN000;;FO. ds:si -> final path
	MOV	SI,[WFP_START]		;AN000;;FO.
getnext:				;AN000;
	LODSB				;AN000;;FO. get char
	OR	AL,AL			;AN000;;FO. is it null
	JZ	NO_Question		;AN000;;FO. yes
	CMP	AL,'?'                  ;AN000;;FO. is '?'
	JNZ	getnext 		;AN000;;FO. no
	STC				;AN000;;FO.
NO_Question:				;AN000;
	return				;AN000;;FO.

EndProc CHECK_QUESTION			;AN000;

CODE	ENDS
    END
