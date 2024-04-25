;	SCCSID = @(#)macro2.asm 1.2 85/07/23
TITLE	MACRO2 - Pathname and macro related internal routines
NAME	MACRO2
;
;   TransFCB	    written
;   TransPath	    written
;   TransPathSet    written
;   TransPathNoSet  Written
;   Canonicalize    written
;   PathSep	    written
;   SkipBack	    written
;   CopyComponent   written
;   Splice	    written
;   $NameTrans	    written
;   DriveFromText
;   TextFromDrive
;   PathPref
;   ScanPathChar
;
;   Revision history:
;
;	Created: MZ 4 April 1983
;		 MZ 18 April 1983   Make TransFCB handle extended FCBs
;		 AR 2 June 1983     Define/Delete macro for NET redir.
;		 MZ 3 Nov 83	    Fix InitCDS to reset length to 2
;		 MZ 4 Nov 83	    Fix NetAssign to use STRLEN only
;		 MZ 18 Nov 83	    Rewrite string processing for subtree
;				    aliasing.
;		 BAS 3 Jan 85	    ScanPathChar to search for path separator
;				    in null terminated string.
;
;   MSDOS performs several types of name translation.  First, we maintain for
;   each valid drive letter the text of the current directory on that drive.
;   For invalid drive letters, there is no current directory so we pretend to
;   be at the root.  A current directory is either the raw local directory
;   (consisting of drive:\path) or a local network directory (consisting of
;   \\machine\path.  There is a limit on the point to which a ..  is allowed.
;
;   Given a path, MSDOS will transform this into a real from-the-root path
;   without .  or ..  entries.	Any component that is > 8.3 is truncated to
;   this and all * are expanded into ?'s.
;
;   The second part of name translation involves subtree aliasing.  A list of
;   subtree pairs is maintained by the external utility SUBST.	The results of
;   the previous 'canonicalization' are then examined to see if any of the
;   subtree pairs is a prefix of the user path.  If so, then this prefix is
;   replaced with the other subtree in the pair.
;
;   A third part involves mapping this "real" path into a "physical" path.  A
;   list of drive/subtree pairs are maintained by the external utility JOIN.
;   The output of the previous translation is examined to see if any of the
;   subtrees in this list are a prefix of the string.  If so, then the prefix
;   is replaced by the appropriate drive letter.  In this manner, we can
;   'mount' one device under another.
;
;   The final form of name translation involves the mapping of a user's
;   logical drive number into the internal physical drive.  This is
;   accomplished by converting the drive number into letter:CON, performing
;   the above translation and then converting the character back into a drive
;   number.
;
;   curdir_list     STRUC
;   curdir_text     DB	    DIRSTRLEN DUP (?) ; text of assignment and curdir
;   curdir_flags    DW	    ?		    ; various flags
;   curdir_devptr   DD	    ?		    ; local pointer to DPB or net device
;   curdir_ID	    DW	    ?		    ; cluster of current dir (net ID)
;		    DW	    ?
;   curdir_end	    DW	    ?		    ; end of assignment
;   curdir_list     ENDS
;   curdir_netID    EQU     DWORD PTR curdir_ID
;   ;Flag word masks
;   curdir_isnet    EQU     1000000000000000B
;   curdir_inuse    EQU     0100000000000000B
;
;
;   There are two main entry points:  TransPath and TransFCB.  TransPath will
;   take a path and form the real text of the pathname with all .  and ..
;   removed.  TransFCB will translate an FCB into a path and then invoke
;   TransPath.
;
;   Implementation note:  CURDIR_End field points to the point in the text
;   string where the user may back up to via ..  It is the location of a
;   separator character.  For the root, it points at the leading /.  For net
;   assignments it points at the end (nul) of the initial assignment:
;   A:/     \\foo\bar	    \\foo\bar\blech\bozo
;     ^ 	     ^		     ^
; A: -> d: /path/ path/ text
;
;   A000  version 4.00  Jan. 1988

.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGroup,CS:DOSGroup

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
.cref
.list
.sall

Installed = TRUE

	I_need	Splices,BYTE		; TRUE => splices are being done.
	I_need	WFP_Start,WORD		; pointer to beginning of expansion
	I_need	Curr_Dir_End,WORD	; offset to end of current dir
	I_need	ThisCDS,DWORD		; pointer to CDS used
	I_need	ThisDPB,DWORD		; pointer to DPB used
	I_need	NAME1,11		; Parse output of NameTrans
	I_need	OpenBuf,128		; ususal destination of strings
	I_need	ExtFCB,BYTE		; flag for extended FCBs
	I_need	Sattrib,BYTE		; attribute of search
	I_need	fSplice,BYTE		; TRUE => do splice after canonicalize
	I_need	fSharing,BYTE		; TRUE => no redirection allowed
	I_Need	NoSetDir,BYTE		; TRUE => syscall is interested in
					; entry, not contents.	We splice only
					; inexact matches
	I_Need	cMeta,BYTE		; count of meta chars in path
	I_Need	Temp_Var,WORD		;AN000; variable for temporary use 3/31/KK
	I_Need	DOS34_FLAG,WORD 	;AN000; variable for dos34
	I_Need	NO_FILTER_PATH,DWORD	;AN000; pointer to orignal path
Table	SEGMENT
	EXTRN	CharType:BYTE
Table	ENDS

BREAK <TransFCB - convert an FCB into a path, doing substitution>

;
;   TransFCB - Copy an FCB from DS:DX into a reserved area doing all of the
;	gritty substitution.
;
;   Inputs:	DS:DX - pointer to FCB
;		ES:DI - point to destination
;   Outputs:	Carry Set - invalid path in final map
;		Carry Clear - FCB has been mapped into ES:DI
;		    Sattrib is set from possibly extended FCB
;		    ExtFCB set if extended FCB found
;   Registers modified: most

Procedure   TransFCB,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
PUBLIC MACRO001S,MACRO001E
MACRO001S:
	LocalVar    FCBTmp,15
MACRO001E:
	Enter
	Context ES			; get DOSGroup addressability
	SaveReg <ES,DI> 		; save away final destination
	LEA	DI,FCBTmp		; point to FCB temp area
	MOV	[ExtFCB],0		; no extended FCB found
	MOV	[Sattrib],0		; default search attributes
	invoke	GetExtended		; get FCB, extended or not
	JZ	GetDrive		; not an extended FCB, get drive
	MOV	AL,[SI-1]		; get attributes
	MOV	[SAttrib],AL		; store search attributes
	MOV	[ExtFCB],-1		; signal extended FCB
GetDrive:
	LODSB				; get drive byte
	invoke	GetThisDrv
	jc	BadPack
	CALL	TextFromDrive		; convert 0-based drive to text
;
; Scan the source to see if there are any illegal chars
;
	MOV	BX,OFFSET DOSGroup:CharType
 IF  DBCS				;AN000;
;----------------------------- Start of DBCS 2/13/KK
	SaveReg <SI>			;AN000;; back over name, ext
	MOV	CX,8			;AN000;; 8 chars in main part of name
FCBScan:LODSB				;AN000;; get a byte
	invoke	testkanj		;AN000;
	jz	notkanj2		;AN000;
	DEC	CX			;AN000;
	JCXZ	VolidChck		;AN000;; Kanji half char screw up
	LODSB				;AN000;; second kanji byte
	jmp	short Nextch		;AN000;
VolidChck:				;AN000;
	TEST	[SAttrib],attr_volume_id ;AN000;; volume id ?
	JZ	Badpack 		 ;AN000;; no, error
	OR	[DOS34_FLAG],DBCS_VOLID  ;AN000;; no, error
	DEC	CX			 ;AN000;; cx=-1
	INC	SI			 ;AN000;; next char
	JMP	SHORT FCBScango 	 ;AN000;
notkanj2:				 ;AN000;
	XLAT	ES:CharType		 ;AN000;;get bits
	TEST	AL,fFCB 		 ;AN000;
	JZ	BadPack 		 ;AN000;
NextCh: 				 ;AN000;
	LOOP	FCBScan 		 ;AN000;
FCBScango:				 ;AN000;
	ADD	CX,3			;AN000;; Three chars in extension
FCBScanE:				;AN000;
	LODSB				;AN000;
	invoke	testkanj		;AN000;
	jz	notkanj3		;AN000;
	DEC	CX			;AN000;
	JCXZ	BadPack 		;AN000;; Kanji half char problem
	LODSB				;AN000;; second kanji byte
	jmp	short NextChE		;AN000;
notkanj3:				;AN000;
	XLAT	ES:CharType		;AN000;; get bits
	TEST	AL,fFCB 		;AN000;
	JZ	BadPack 		;AN000;
NextChE:				;AN000;
	LOOP	FCBScanE		;AN000;
;----------------------------- End of DBCS 2/13/KK
 ELSE

	MOV	CX,11
	SaveReg <SI>			; back over name, ext
FCBScan:LODSB				; get a byte
	XLAT	ES:CharType		; get bits
	TEST	AL,fFCB
	JZ	BadPack
NextCh: LOOP	FCBScan
 ENDIF
	RestoreReg  <SI>
	MOV	BX,DI
	invoke	PackName		; crunch the path
	RestoreReg  <DI,ES>		; get original destination
	Context DS			; get DS addressability
	LEA	SI,FCBTmp		; point at new pathname
	CMP	BYTE PTR [BX],0
	JZ	BadPack
	SaveReg <BP>
	CALL	TransPathSet		; convert the path
	RestoreReg  <BP>
	JNC	FCBRet			; bye with transPath error code
BadPack:
	STC
	MOV	AL,error_path_not_found
FCBRet: Leave
	return
EndProc TransFCB,NoCheck

BREAK <TransPath - copy a path, do string sub and put in current dir>

;
;   TransPath - copy a path from DS:SI to ES:DI, performing component string
;	substitution, insertion of current directory and fixing .  and ..
;	entries.  Perform splicing.  Allow input string to match splice
;	exactly.
;
;   TransPathSet - Same as above except No splicing is performed if input path
;	matches splice.
;
;   TransPathNoSet - No splicing/local using is performed at all.
;
;   The following anomalous behaviour is required:
;
;	Drive letters on devices are ignored.  (set up DummyCDS)
;	Paths on devices are ignored. (truncate to 0-length)
;	Raw net I/O sets ThisCDS => NULL.
;	fSharing => dummyCDS and no subst/splice.  Only canonicalize.
;
;   Other behaviour:
;
;	ThisCDS set up.
;	FatRead done on local CDS.
;	ValidateCDS done on local CDS.
;
;   Brief flowchart:
;
;	if fSharing then
;	    set up DummyCDS (ThisCDS)
;	    canonicalize (sets cMeta)
;	    splice
;	    fatRead
;	    return
;	if \\ or d:\\ lead then
;	    set up null CDS (ThisCDS)
;	    canonicalize (sets cMeta)
;	    return
;	if device then
;	    set up dummyCDS (ThisCDS)
;	    canonicalize (sets cMeta)
;	    return
;	if file then
;	    getCDS (sets (ThisCDS) from name)
;	    validateCDS (may reset current dir)
;	    Copy current dir
;	    canonicalize (set cMeta)
;	    splice
;	    generate correct CDS (ThisCDS)
;	    if local then
;		fatread
;	    return
;
;   Inputs:	DS:SI - point to ASCIZ string path
;		DI - point to buffer in DOSGroup
;   Outputs:	Carry Set - invalid path specification: too many .., bad
;		    syntax, etc. or user FAILed to I 24.
;		WFP_Start - points to beginning of buffer
;		Curr_Dir_End - points to end of current dir in path
;		DS - DOSGroup
;   Registers modified: most

Procedure   TransPath,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	XOR	AL,AL
	JMP	SHORT SetSplice
	Entry	TransPathSet
	MOV	AL,-1
SetSplice:
	MOV	NoSetDir,AL		;   NoSetDir = !fExact;
	MOV	AL,-1
	Entry	TransPathNoSet
	MOV	WORD PTR [NO_FILTER_PATH],SI   ;AN000;;IFS. save old path for IFS
	MOV	WORD PTR [NO_FILTER_PATH+2],DS ;AN000;;IFS.

	MOV	fSplice,AL		;   fSplice = TRUE;
	MOV	cMeta,-1
	MOV	WFP_Start,DI
	MOV	Curr_Dir_End,-1 	; crack from start
	Context ES
	LEA	BP,[DI+TEMPLEN] 	; end of buffer
;
; if this is through the server dos call, fsharing is set.  We set up a
; dummy cds and let the operation go.
;
	TEST	fSharing,-1		; if no sharing
	JZ	CheckUNC		; skip to UNC check
;
; ES:DI point to buffer
;
	CALL	DriveFromText		; get drive and advance DS:SI
	invoke	GetThisDrv		; Set ThisCDS and convert to 0-based
	jc	NoPath
	CALL	TextFromDrive		; drop in new
	LEA	BX,[DI+1]		; backup limit
	CALL	Canonicalize		; copy and canonicalize
	retc				; errors
;
; Perform splices for net guys.
;
	Context DS
	MOV	SI,wfp_Start		; point to name
	TEST	fSplice,-1
	JZ	NoServerSplice
	CALL	Splice
NoServerSplice:
	Context DS			; for FATREAD
	LES	DI,ThisCDS		; for fatread
	EnterCrit   critDisk
	Invoke	FatRead_CDS
	LeaveCrit   critDisk
NoPath:
	MOV	AL,error_path_not_found ; Set up for possible bad path error
	return				; any errors are in Carry flag
	ASSUME	DS:NOTHING
;
; Let the network decide if the name is for a spooled device.  It will map
; the name if so.
;
CheckUnc:
	MOV	WORD PTR ThisCDS,-1	; NULL thisCDS
	CallInstall NetSpoolCheck,multNet,35
	JNC	UNCDone
;
; At this point the name is either a UNC-style name (prefixed with two leading
; \\s) or is a local file/device.  Remember that if a net-spooled device was
; input, then the name has been changed to the remote spooler by the above net
; call.  Also, there may be a drive in front of the \\.
;
NO_CHECK:
	CALL	DriveFromText		; eat drive letter
	PUSH	AX			; save it
	MOV	AX,WORD PTR [SI]	; get first two bytes of path
	Invoke	PathChrCmp		; convert to normal form
	XCHG	AH,AL			; swap for second byte
	Invoke	PathChrCmp		; convert to normal form
	JNZ	CheckDevice		; not a path char
	CMP	AH,AL			; are they same?
	JNZ	CheckDevice		; nope
;
; We have a UNC request.  We must copy the string up to the beginning of the
; local machine root path
;

	POP	AX
	MOVSW				; get the lead \\
UNCCpy: LODSB				; get a byte
 IF  DBCS				;AN000;
;----------------------------- Start of DBCS 2/23/KK
	invoke	testkanj		;AN000;
	jz	notkanj1		;AN000;
	STOSB				;AN000;
	LODSB				;AN000;
	OR	AL,AL			;AN000;
	JZ	UNCTerm 		;AN000;; Ignore half kanji error for now
	STOSB				;AN000;
	jmp	UNCCpy			;AN000;
notkanj1:				;AN000;
;----------------------------- End of DBCS 2/23/KK
 ENDIF					;AN000;
	invoke	UCase			;AN000;; convert the char
	OR	AL,AL
	JZ	UNCTerm 		; end of string.  All done.
	Invoke	PathChrCmp		; is it a path char?
	MOV	BX,DI			; backup position
	STOSB
	JNZ	UNCCpy			; no, go copy
	CALL	Canonicalize		; wham (and set cMeta)
UNCDone:
	Context DS
 IF  DBCS
;----------------------------- Start of DBCS 2/23/KK
	retc				;AN000; Return if error from Canonicalize

; Although Cononicalize has done lots of good things for us it may also have
; done e5 to 05 conversion on the fisrt char following a path sep char which is
; not wanted on a UNC request as this should be left for the remote station.
; The simplest thing to do is check for such conversions and convert them back
; again.
; This check loop is also called from the DoFile section of TransPath if the
; file is a remote file. Entry point when called is TP_check05 with the
; inputs/outputs as follows;
;	Inputs : ES:DI = Buffer to check for re-conversion
;	Outputs: None
;	Used   : DI,AX


	MOV	DI,WFP_start		;AN000;; ES:DI points to converted string
TP_check05:				;AN000;
	MOV	AL,BYTE PTR ES:[DI]	;AN000;; Get character from path
	OR	AL,AL			;AN000;; End of null terminated path?
	JZ	TP_end05		;AN000;; Finished, CF =0 from OR (ret success)
	invoke	testkanj		;AN000;; Kanji lead character?
	JZ	TP_notK 		;AN000;; Check for path seperator if not
	INC	DI			;AN000;; Bypass Kanji second byte
	JMP	TP_nxt05		;AN000;; Go to check next character
TP_notK:				;AN000;
	invoke	PathChrCmp		;AN000;; Is it a path seperator char?
	JNZ	TP_nxt05		;AN000;; Check next character if not
	CMP	BYTE PTR ES:[DI+1],05	;AN000;; 05 following path sep char?
	JNZ	TP_nxt05		;AN000;; Check next character if not
	MOV	BYTE PTR ES:[DI+1],0E5h ;AN000;; Convert 05 back to E5
TP_nxt05:				;AN000;
	INC	DI			;AN000;; Point to next char in path
	JMP	TP_check05		;AN000;; Test all chars in path
TP_end05:
;----------------------------- End of DBCS 2/23/KK
 ENDIF					;AN000;
	return				; return error code

	ASSUME	DS:NOTHING
UNCTerm:
	STOSB				;AN000;
	JMP	UNCDone 		;AN000;

CheckDevice:
;
; Check DS:SI for device.  First eat any path stuff
;
	POP	AX			; retrieve drive info
	CMP	BYTE PTR DS:[SI],0	; check for null file
	JNZ	CheckPath
	MOV	AL,error_file_not_found ; bad file error
	STC				; signal error on null input
	RETURN				; bye!
CheckPath:
	SaveReg <AX,BP> 		; save drive number
	Invoke	CheckThisDevice 	; snoop for device
	RestoreReg  <BP,AX>		; get drive letter back
	JNC	DoFile			; yes we have a file.
;
; We have a device.  AX has drive letter.  At this point we may fake a CDS ala
; sharing DOS call.  We know by getting here that we are NOT in a sharing DOS
; call.
;
	MOV	fSharing,-1		; simulate sharing dos call
	invoke	GetThisDrv		; set ThisCDS and init DUMMYCDS
	MOV	fSharing,0		;
;
; Now that we have noted that we have a device, we put it into a form that
; getpath can understand.  Normally getpath requires d:\ to begin the input
; string.  We relax this to state that if the d:\ is present then the path
; may be a file.  If D:/ (note the forward slash) is present then we have
; a device.
;
	CALL	TextFromDrive
	MOV	AL,'/'                  ; path sep.
	STOSB
	invoke	StrCpy			; move remainder of string
	CLC				; everything OK.
	Context DS			; remainder of OK stuff
	return
;
; We have a file.  Get the raw CDS.
;
DoFile:
	ASSUME	DS:NOTHING
	invoke	GetVisDrv		; get proper CDS
	MOV	AL,error_path_not_found ; Set up for possible bad file error
	retc				; CARRY set -> bogus drive/spliced
;
; ThisCDS has correct CDS.  DS:SI advanced to point to beginning of path/file.
; Make sure that CDS has valid directory; ValidateCDS requires a temp buffer
; Use the one that we are going to use (ES:DI).
;
	SaveReg <DS,SI,ES,DI>		; save all string pointers.
	invoke	ValidateCDS		; poke CDS amd make everything OK
	RestoreReg <DI,ES,SI,DS>	; get back pointers
	MOV	AL,error_path_not_found ; Set up for possible bad path error
	retc				; someone failed an operation
;
; ThisCDS points to correct CDS.  It contains the correct text of the
; current directory.  Copy it in.
;
	SaveReg <DS,SI>
	LDS	SI,ThisCDS		; point to CDS
	MOV	BX,DI			; point to destination
	ADD	BX,[SI].curdir_end	; point to backup limit
;	LEA	SI,[SI].curdir_text	; point to text
	LEA	BP,[DI+TEMPLEN] 	; regenerate end of buffer
 IF  DBCS				;AN000;
;------------------------ Start of DBCS 2/13/KK
Kcpylp: 				;AN000;
	LODSB				;AN000;
	invoke	TestKanj		;AN000;
	jz	Notkanjf		;AN000;
	STOSB				;AN000;
	MOVSB				;AN000;
	CMP	BYTE PTR [SI],0 	;AN000;
	JNZ	Kcpylp			;AN000;
	MOV	AL, '\'                 ;AN000;
	STOSB				;AN000;
	JMP	SHORT GetOrig		;AN000;
Notkanjf:				;AN000;
	STOSB				;AN000;
	OR	AL,AL			;AN000;
	JNZ	Kcpylp			;AN000;
	DEC	DI			;AN000;; point to NUL byte

;------------------------ End of DBCS 2/13/KK
 ELSE					;AN000;
	invoke	FStrCpy 		; copy string.	ES:DI point to end
	DEC	DI			; point to NUL byte
 ENDIF					;AN000;
;
; Make sure that there is a path char at end.
;
	MOV	AL,'\'
	CMP	ES:[DI-1],AL
	JZ	GetOrig
	STOSB
;
; Now get original string.
;
GetOrig:
	DEC	DI			; point to path char
	RestoreReg  <SI,DS>
;
; BX points to the end of the root part of the CDS (at where a path char
; should be) .	Now, we decide whether we use this root or extend it with the
; current directory.  See if the input string begins with a leading \
;
	CALL	PathSep 		; is DS:SI a path sep?
	JNZ	PathAssure		; no, DI is correct. Assure a path char
	OR	AL,AL			; end of string?
	JZ	DoCanon 		; yes, skip.
;
; The string does begin with a \.  Reset the beginning of the canonicalization
; to this root.  Make sure that there is a path char there and advance the
; source string over all leading \'s.
;
	MOV	DI,BX			; back up to root point.
SkipPath:
	LODSB
	invoke PathChrCmp
	JZ	SkipPath
	DEC	SI
	OR	AL,AL
	JZ	DoCanon
;
; DS:SI start at some file name.  ES:DI points at some path char.  Drop one in
; for yucks.
;
PathAssure:
	MOV	AL,'\'
	STOSB
;
; ES:DI point to the correct spot for canonicalization to begin.
; BP is the max extent to advance DI
; BX is the backup limit for ..
;
DoCanon:
	CALL	Canonicalize		; wham.
	retc				; badly formatted path.
 IF  DBCS				;AN000;
;--------------------- Start of DBCS 2/13/KK
; Although Cononicalize has done lots of good things for us it may also have
; done e5 to 05 conversion on the fisrt char following a path sep char which is
; not wanted if this a remote file as this should be left for the remote
; station. Check for a leading \\ in the path buffer and call TP_check05 to
; reconvert if found.

	MOV	DI,WFP_start		;AN000;; ES:DI points to string
	MOV	AX,WORD PTR ES:[DI]	;AN000;; Get leading 2 chars from path buffer
	invoke	PathChrCmp		;AN000;; First char a path char?
	JNZ	TP_notremote		;AN000;; Not remote if not.
	invoke	PathChrCmp		;AN000;; Second char a path char?
	JNZ	TP_notremote		;AN000;; Not remote if not
	CALL	TP_check05		;AN000;; Remote so convert 05 back to e5
TP_notremote:				;AN000;
;--------------------- End of DBCS 2/13/KK
 ENDIF
;
; The string has been moved to ES:DI.  Reset world to DOS context, pointers
; to wfp_start and do string substitution.  BP is still the max position in
; buffer.
;
	Context DS
	MOV	DI,wfp_start		; DS:SI point to string
	LDS	SI,ThisCDS		; point to CDS
	ASSUME	DS:NOTHING
;	LEA	SI,[SI].curdir_text	; point to text
	CALL	PathPref		; is there a prefix?
	JNZ	DoSplice		; no, do splice
;
; We have a match. Check to see if we ended in a path char.
;
 IF  DBCS				;AN000;
;---------------------------- Start of DBCS 2/13/KK
	PUSH	BX			;AN000;
	MOV	BX,SI			;AN000;
	MOV	SI,WORD PTR ThisCDS	;AN000;; point to CDS
LOOKDUAL:				;AN000;
	MOV	AL,BYTE PTR [SI]	;AN000;
	invoke	TESTKANJ		;AN000;
	JZ	ONEINC			;AN000;
	INC	SI			;AN000;
	INC	SI			;AN000;
	CMP	SI,BX			;AN000;
	JB	LOOKDUAL		;AN000;
	POP	BX			;AN000;; Last char was KANJI, don't look back
	JMP	SHORT Pathline		;AN000;;  for path sep, there isn't one.
					;AN000;
ONEINC: 				;AN000;
	INC	SI			;AN000;
	CMP	SI,BX			;AN000;
	JB	LOOKDUAL		;AN000;
	POP	BX			;AN000;
;------------------------ End of DBCS 2/13/KK
 ENDIF					;AN000;
	MOV	AL,DS:[SI-1]		; last char to match
	Invoke	PathChrCmp		; did we end on a path char? (root)
	JZ	DoSplice		; yes, no current dir here.
Pathline:				; 2/13/KK
	CMP	BYTE PTR ES:[DI],0	; end at NUL?
	JZ	DoSplice
	INC	DI			; point to after current path char
	MOV	Curr_Dir_End,DI 	; point to correct spot
;
; Splice the result.
;
DoSplice:
	Context DS			; back to DOSGROUP
	MOV	SI,wfp_Start		; point to beginning of string
	XOR	CX,CX
	TEST	fSplice,-1
	JZ	SkipSplice
	CALL	Splice			; replaces in place.
SkipSplice:
	ASSUME	DS:NOTHING
;
; The final thing is to assure ourselves that a FATREAD is done on the local
; device.
;
	Context DS
	LES	DI,ThisCDS		; point to correct drive
	TEST	ES:[DI].curdir_flags,curdir_isnet
	retnz				; net, no fatread necessary
	JCXZ	Done
	EnterCrit   critDisk
	invoke	FatRead_CDS
	LeaveCrit   critDisk
	MOV	AL,error_path_not_found ; Set up for possible bad path error
Done:	return				; any errors in carry flag.
EndProc TransPath

BREAK <Canonicalize - copy a path and remove . and .. entries>

;
;   Canonicalize - copy path removing . and .. entries.
;
;   Inputs:	DS:SI - point to ASCIZ string path
;		ES:DI - point to buffer
;		BX - backup limit (offset from ES) points to slash
;		BP - end of buffer
;   Outputs:	Carry Set - invalid path specification: too many .., bad
;		    syntax, etc.
;		Carry Clear -
;		    DS:DI - advanced to end of string
;		    ES:DI - advanced to end of canonicalized form after nul
;   Registers modified: AX CX DX (in addition to those above)

Procedure Canonicalize,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
;
; We copy all leading path separators.
;
	LODSB				;   while (PathChr (*s))
	Invoke	PathChrCmp
 IF  DBCS
	JNZ	CanonDec0		; 2/19/KK
 ELSE
	JNZ	CanonDec
 ENDIF
	CMP	DI,BP			;	if (d > dlim)
	JAE	CanonBad		;	    goto error;
	STOSB
	JMP	Canonicalize		;	    *d++ = *s++;
 IF  DBCS				;AN000;
CanonDec0:				;AN000; 2/19/KK
;	mov	cs:Temp_Var,di		;AN000; 3/31/KK
 ENDIF					;AN000;
CanonDec:
	DEC	SI
;
; Main canonicalization loop.  We come here with DS:SI pointing to a textual
; component (no leading path separators) and ES:DI being the destination
; buffer.
;
CanonLoop:
;
; If we are at the end of the source string, then we need to check to see that
; a potential drive specifier is correctly terminated with a path sep char.
; Otherwise, do nothing
;
	XOR	AX,AX
	CMP	[SI],AL 		;	if (*s == 0) {
	JNZ	DoComponent
 IF  DBCS				;AN000;
	call	chk_last_colon		;AN000; 2/18/KK
 ELSE					;AN000;
	CMP	BYTE PTR ES:[DI-1],':'  ;           if (d[-1] == ':')
 ENDIF					;AN000;
	JNZ	DoTerminate
	MOV	AL,'\'                  ;               *d++ = '\';
	STOSB
	MOV	AL,AH
DoTerminate:
	STOSB				;	    *d++ = 0;
	CLC				;	    return (0);
	return
 IF  DBCS				;AN000;
;---------------- Start of DBCS 2/18/KK
chk_last_colon	proc			;AN000;
	push	si			;AN000;
	push	ax			;AN000;
	push	bx			;AN000;
	mov	si,[WFP_START]		;AN000;;PTM. for cd ..	use beginning of buf
	cmp	si,di			;AN000;; no data stored ?
	jb	CLC02			;AN000;;PTM. for cd ..
	inc	si			;AN000;; make NZ flag
	JMP	SHORT CLC09		;AN000;
CLC02:					;AN000;
	mov	bx,di			;AN000;
	dec	bx			;AN000;
CLC_lop:				;AN000;
	cmp	si,bx			;AN000;
	jb	CLC00			;AN000;
	jne	CLC09			;AN000;
CLC01:					;AN000;
	CMP	BYTE PTR ES:[DI-1],':'  ;AN000;;           if (d[-1] == ':')
	jmp	CLC09			;AN000;
CLC00:					;AN000;
	mov	al,es:[si]		;AN000;
	inc	si			;AN000;
	invoke	testkanj		;AN000;
	je	CLC_lop 		;AN000;
	inc	si			;AN000;
	jmp	CLC_lop 		;AN000;
CLC09:					;AN000;
	pop	bx			;AN000;
	pop	ax			;AN000;
	pop	si			;AN000;
	ret				;AN000;
chk_last_colon	endp			;AN000;
;---------------- Endt of DBCS 2/18/KK
 ENDIF					;AN000;

CanonBad:
	CALL	ScanPathChar		; check for path chars in rest of string
	MOV	AL,error_path_not_found ; Set up for bad path error
	JZ	PathEnc 		; path character encountered in string
	MOV	AL,error_file_not_found ; Set bad file error
PathEnc:
	STC
	return
;
; We have a textual component that we must copy.  We uppercase it and truncate
; it to 8.3
;
DoComponent:				;	    }
	CALL	CopyComponent		;	if (!CopyComponent (s, d))
	retc				;	    return (-1);
;
; We special case the . and .. cases.  These will be backed up.
;
	CMP	WORD PTR ES:[DI],'.' + (0 SHL 8)
	JZ	Skip1
	CMP	WORD PTR ES:[DI],'..'
	JNZ	CanonNormal
	DEC	DI			;	    d--;
Skip1:	CALL	SkipBack		;	    SkipBack ();
	MOV	AL,error_path_not_found ; Set up for possible bad path error
	retc
	JMP	CanonPath		;	    }
;
; We have a normal path.  Advance destination pointer over it.
;
CanonNormal:				;	else
	ADD	DI,CX			;	    d += ct;
;
; We have successfully copied a component.  We are now pointing at a path
; sep char or are pointing at a nul or are pointing at something else.
; If we point at something else, then we have an error.
;
CanonPath:
	CALL	PathSep
	JNZ	CanonBad		; something else...
;
; Copy the first path char we see.
;
	LODSB				; get the char
	Invoke	PathChrCmp		; is it path char?
	JNZ	CanonDec		; no, go test for nul
	CMP	DI,BP			; beyond buffer end?
	JAE	CanonBad		; yep, error.
	STOSB				; copy the one byte
;
; Skip all remaining path chars
;
CanonPathLoop:
	LODSB				; get next byte
	Invoke	PathChrCmp		; path char again?
	JZ	CanonPathLoop		; yep, grab another
	DEC	SI			; back up
	JMP	CanonLoop		; go copy component
EndProc Canonicalize

BREAK <PathSep - determine if char is a path separator>

;
;   PathSep - look at DS:SI and see if char is / \ or NUL
;   Inputs:	DS:SI - point to a char
;   Outputs:	AL has char from DS:SI (/ => \)
;		Zero set if AL is / \ or NUL
;		Zero reset otherwise
;   Registers modified: AL

Procedure   PathSep,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	AL,[SI] 		; get the character
	entry	PathSepGotCh		; already have character
	OR	AL,AL			; test for zero
	retz				; return if equal to zero (NUL)
	invoke	PathChrCmp		; check for path character
	return				; and return HIS determination
EndProc PathSep

BREAK <SkipBack - move backwards to a path separator>

;
;   SkipBack - look at ES:DI and backup until it points to a / \
;   Inputs:	ES:DI - point to a char
;		BX has current directory back up limit (point to a / \)
;   Outputs:	ES:DI backed up to point to a path char
;		AL has char from output ES:DI (path sep if carry clear)
;		Carry set if illegal backup
;		Carry Clear if ok
;   Registers modified: DI,AL

Procedure   SkipBack,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
 IF  DBCS		       ;AN000;
;-------------------------- Start of DBCS 2/13/KK
	PUSH	DS		;AN000;
	PUSH	SI		;AN000;
	PUSH	CX		;AN000;
	PUSH	ES		;AN000;
	POP	DS		;AN000;
	MOV	SI,BX		;AN000;; DS:SI -> start of ES:DI string
	MOV	CX,DI		;AN000;; Limit of forward scan is input DI
	MOV	AL,[SI] 	;AN000;
	invoke	PathChrCmp	;AN000;
	JNZ	SkipBadP	;AN000;; Backup limit MUST be path char
	CMP	DI,BX		;AN000;
	JBE	SkipBadP	;AN000;
	MOV	DI,BX		;AN000;; Init backup point to backup limit
Skiplp: 			;AN000;
	CMP	SI,CX		;AN000;
	JAE	SkipOK		;AN000;; Done, DI is correct backup point
	LODSB			;AN000;
	invoke	Testkanj	;AN000;
	jz	Notkanjv	;AN000;
	lodsb			;AN000;; Skip over second kanji byte
	JMP	Skiplp		;AN000;
NotKanjv:			;AN000;
	invoke	PathChrCmp	;AN000;
	JNZ	Skiplp		;AN000;; New backup point
	MOV	DI,SI		;AN000;; DI point to path sep
	DEC	DI		;AN000;
	jmp	Skiplp		;AN000;
SkipOK: 			;AN000;
	MOV	AL,ES:[DI]	;AN000;; Set output AL
	CLC			;AN000;; return (0);
	POP	CX		;AN000;
	POP	SI		;AN000;
	POP	DS		;AN000;
	return			;AN000;
				;AN000;
SkipBadP:			;AN000;
	POP	CX		;AN000;
	POP	SI		;AN000;
	POP	DS		;AN000;
;-------------------------- End of DBCS 2/13/KK
 ELSE				;AN000;
	CMP	DI,BX			;   while (TRUE) {
	JB	SkipBad 		;	if (d < dlim)
	DEC	DI			;	    goto err;
	MOV	AL,ES:[DI]		;	if (pathchr (*--d))
	invoke	PathChrCmp		;	    break;
	JNZ	SkipBack		;	}
	CLC				;   return (0);
	return				;
 ENDIF					;AN000;
SkipBad:				;err:
	MOV	AL,error_path_not_found ; bad path error
	STC				;   return (-1);
	return				;
EndProc SkipBack

Break <CopyComponent - copy out a file path component>

;
;   CopyComponent - copy a file component from a path string (DS:SI) into ES:DI
;
;   Inputs:	DS:SI - source path
;		ES:DI - destination
;		ES:BP - end of buffer
;   Outputs:	Carry Set - too long
;		Carry Clear - DS:SI moved past component
;		    CX has length of destination
;   Registers modified: AX,CX,DX

Procedure   CopyComponent,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
CopyBP	    EQU     WORD PTR [BP]
CopyD	    EQU     DWORD PTR [BP+2]
CopyDoff    EQU     WORD PTR [BP+2]
CopyS	    EQU     DWORD PTR [BP+6]
CopySoff    EQU     WORD PTR [BP+6]
CopyTemp    EQU     BYTE PTR [BP+10]
	SUB	SP,14			; room for temp buffer
	SaveReg <DS,SI,ES,DI,BP>
	MOV	BP,SP
	MOV	AH,'.'
	LODSB
	STOSB
	CMP	AL,AH			;   if ((*d++=*s++) == '.') {
	JNZ	NormalComp
	CALL	PathSep 		;	if (!pathsep(*s))
	JZ	NulTerm
TryTwoDot:
	LODSB				;	    if ((*d++=*s++) != '.'
	STOSB
	CMP	AL,AH
	JNZ	CopyBad
	CALL	PathSep
	JNZ	CopyBad 		;		|| !pathsep (*s))
NulTerm:				;		return -1;
	XOR	AL,AL			;	*d++ = 0;
	STOSB
	MOV	CopySoff,SI
	JMP	SHORT GoodRet		;	}
NormalComp:				;   else {
	MOV	SI,CopySoff
	Invoke	NameTrans		;	s = NameTrans (s, Name1);
	CMP	SI,CopySOff		;	if (s == CopySOff)
	JZ	CopyBad 		;	    return (-1);
	TEST	fSharing,-1		;	if (!fSharing) {
	JNZ	DoPack
	AND	DL,1			;	    cMeta += fMeta;
	ADD	cMeta,DL		;	    if (cMeta > 0)
	JG	CopyBad 		;		return (-1);
	JNZ	DoPack			;	    else
	OR	DL,DL			;	    if (cMeta == 0 && fMeta == 0)
	JZ	CopyBadPath		;		return (-1);
DoPack: 				;	    }
	MOV	CopySoff,SI
	Context DS
	MOV	SI,OFFSET DOSGroup:NAME1
	LEA	DI,CopyTemp
	SaveReg <DI>
	Invoke	PackName		;	PackName (Name1, temp);
	RestoreReg  <DI>
	Invoke	StrLen			;	if (strlen(temp)+d > bp)
	DEC	CX
	ADD	CX,CopyDoff
	CMP	CX,CopyBP
	JAE	CopyBad 		;	    return (-1);
	MOV	SI,DI			;	strcpy (d, temp);
	LES	DI,CopyD
	Invoke	FStrCpy
GoodRet:				;	}
	CLC
	JMP	SHORT CopyEnd		;   return 0;
CopyBad:
	STC
	CALL	ScanPathChar		; check for path chars in rest of string
	MOV	AL,error_file_not_found ; Set up for bad file error
	JNZ	CopyEnd
CopyBadPath:
	STC
	MOV	AL,error_path_not_found ; Set bad path error
CopyEnd:
	RestoreReg  <BP,DI,ES,SI,DS>
	LAHF
	ADD	SP,14			; reclaim temp buffer
	Invoke	Strlen
	DEC	CX
	SAHF
	return
EndProc CopyComponent,NoCheck

Break <Splice - pseudo mount by string substitution>

;
;   Splice - take a string and substitute a prefix if one exists.  Change
;	ThisCDS to point to physical drive CDS.
;   Inputs:	DS:SI point to string
;		NoSetDir = TRUE => exact matches with splice fail
;   Outputs:	DS:SI points to thisCDS
;		ES:DI points to DPB
;		String at DS:SI may be reduced in length by removing prefix
;		and substituting drive letter.
;		CX = 0 If no splice done
;		CX <> 0 otherwise
;		ThisCDS points to proper CDS if spliced, otherwise it is
;		    left alone
;		ThisDPB points to proper DPB
;   Registers modified: DS:SI, ES:DI, BX,AX,CX

Procedure   Splice,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	TEST	Splices,-1
	JZ	AllDone
	SaveReg <<WORD PTR ThisCDS>,<WORD PTR ThisCDS+2>>   ; TmpCDS = ThisCDS
	SaveReg <DS,SI>
	RestoreReg <DI,ES>
	XOR	AX,AX			;   for (i=1; s = GetCDSFromDrv (i); i++)
SpliceScan:
	invoke	GetCDSFromDrv
	JC	SpliceDone
	INC	AL
	TEST	[SI.curdir_flags],curdir_splice
	JZ	SpliceScan		;	if ( Spliced (i) ) {
	SaveReg <DI>
	CALL	PathPref		;	    if (!PathPref (s, d))
	JZ	SpliceFound		;
SpliceSkip:
	RestoreReg  <DI>
	JMP	SpliceScan		;		continue;
SpliceFound:
	CMP	BYTE PTR ES:[DI],0	;	    if (*s || NoSetDir) {
	JNZ	SpliceDo
	TEST	NoSetDir,-1
	JNZ	SpliceSkip
SpliceDo:
	MOV	SI,DI			;		p = src + strlen (p);
	SaveReg <ES>
	RestoreReg  <DS,DI>
	CALL	TextFromDrive1		;		src = TextFromDrive1(src,i);
	MOV	AX,Curr_Dir_End
	OR	AX,AX
	JS	NoPoke
	ADD	AX,DI			;		curdirend += src-p;
	SUB	AX,SI
	MOV	Curr_Dir_End,AX
NoPoke:
	CMP	BYTE PTR [SI],0 	;		if (*p)
	JNZ	SpliceCopy		;		    *src++ = '\\';
	MOV	AL,"\"
	STOSB
SpliceCopy:				;		strcpy (src, p);
	invoke	FStrCpy
	ADD	SP,4			; throw away saved stuff
	OR	CL,1			; signal splice done.
	JMP	SHORT DoSet		;		return;
SpliceDone:				;		}
	ASSUME	DS:NOTHING		;   ThisCDS = TmpCDS;
	RestoreReg  <<WORD PTR ThisCDS+2>,<WORD PTR ThisCDS>>
AllDone:
	XOR	CX,CX
DoSet:
	LDS	SI,ThisCDS		;   ThisDPB = ThisCDS->devptr;
	LES	DI,[SI].curdir_devptr
	MOV	WORD PTR ThisDPB,DI
	MOV	WORD PTR ThisDPB+2,ES
	return
EndProc Splice

Break <$NameTrans - partially process a name>

;
;   $NameTrans - allow users to see what names get mapped to.  This call
;   performs only string substitution and canonicalization, not splicing.  Due
;   to Transpath playing games with devices, we need to insure that the output
;   has drive letter and :  in it.
;
;   Inputs:	DS:SI - source string for translation
;		ES:DI - pointer to buffer
;   Outputs:
;	Carry Clear
;		Buffer at ES:DI is filled in with data
;		ES:DI point byte after nul byte at end of dest string in buffer
;	Carry Set
;		AX = error_path_not_found
;   Registers modified: all

Procedure   $NameTrans,Near
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	SaveReg <DS,SI,ES,DI>
	MOV	DI,OFFSET DOSGroup:OpenBuf
	CALL	TransPath		; to translation (everything)
	RestoreReg  <DI,ES,SI,DS>
	JNC	TransOK
	transfer    SYS_Ret_Err
TransOK:
	MOV	SI,OFFSET DOSGroup:OpenBuf
	Context DS
GotText:
	Invoke	FStrCpy
	Transfer    SYS_Ret_OK
EndProc $NameTrans

Break	<DriveFromText - return drive number from a text string>

;
;   DriveFromText - examine DS:SI and remove a drive letter, advancing the
;   pointer.
;
;   Inputs:	DS:SI point to a text string
;   Outputs:	AL has drive number
;		DS:SI advanced
;   Registers modified: AX,SI.

Procedure   DriveFromText,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:NOTHING
	XOR	AL,AL			;	drive = 0;
	CMP	BYTE PTR [SI],0 	;	if (*s &&
	retz
	CMP	BYTE PTR [SI+1],':'     ;           s[1] == ':') {
	retnz
 IF  DBCS				;AN000;
;--------------------- Start of DBCS 2/18/KK
	push	ax		       ;AN000;
	mov	al,[si] 	       ;AN000;
	invoke	testkanj	       ;AN000;
	pop	ax		       ;AN000;
	retnz			       ;AN000;
;--------------------- End of DBCS 2/18/KK
 ENDIF				       ;AN000;
	LODSW				;	    drive = (*s | 020) - 'a'+1;
	OR	AL,020h
	SUB	AL,'a'-1                ;           s += 2;
	retnz
	MOV	AL,-1			; nuke AL...
	return				;	    }
EndProc DriveFromText

Break	<TextFromDrive - convert a drive number to a text string>

;
;   TextFromDrive - turn AL into a drive letter: and put it at es:di with
;   trailing :. TextFromDrive1 takes a 1-based number.
;
;   Inputs:	AL has 0-based drive number
;   Outputs:	ES:DI advanced
;   Registers modified: AX

Procedure TextFromDrive,NEAR
	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:NOTHING
	INC	AL
	Entry	TextFromDrive1
	ADD	AL,'A'-1                ;   *d++ = drive-1+'A';
	MOV	AH,":"                  ;   strcat (d, ":");
	STOSW
	return
EndProc TextFromDrive

Break	<PathPref - see if one path is a prefix of another>

;
;   PathPref - compare DS:SI with ES:DI to see if one is the prefix of the
;   other.  Remember that only at a pathchar break are we allowed to have a
;   prefix: A:\ and A:\FOO
;
;   Inputs:	DS:SI potential prefix
;		ES:DI string
;   Outputs:	Zero set => prefix found
;		    DI/SI advanced past matching part
;		Zero reset => no prefix, DS/SI garbage
;   Registers modified: CX

Procedure   PathPref,NEAR
	Invoke	DStrLen 		; get length
	DEC	CX			; do not include nul byte
 IF  DBCS				;AN000;
;----------------------- Start of DBCS 2/13/KK
	SaveReg <AX>			;AN000;; save char register
CmpLp:					;AN000;
	MOV	AL,[SI] 		;AN000;
	invoke	Testkanj		;AN000;
	jz	NotKanj9		;AN000;
	CMPSW				;AN000;
	JNZ	Prefix			;AN000;
	DEC	CX			;AN000;
	LOOP	CmpLp			;AN000;
	JMP	SHORT NotSep		;AN000;
NotKanj9:				;AN000;
	CMPSB				;AN000;
	JNZ	Prefix			;AN000;
	LOOP	CmpLp			;AN000;
;----------------------- End of DBCS 2/13/KK
 ELSE					;AN000;
	REPZ	CMPSB			; compare
	retnz				; if NZ then return NZ
	SaveReg <AX>			; save char register
 ENDIF					;AN000;
	MOV	AL,[SI-1]		; get last byte to match
	Invoke	PathChrCmp		; is it a path char (Root!)
	JZ	Prefix			; yes, match root (I hope)
NotSep: 				; 2/13/KK
	MOV	AL,ES:[DI]		; get next char to match
	CALL	PathSepGotCh		; was it a pathchar?
Prefix:
	RestoreReg  <AX>		; get back original
	return
EndProc PathPref

Break	<ScanPathChar - see if there is a path character in a string>

;
;     ScanPathChar - search through the string (pointed to by DS:SI) for
;     a path separator.
;
;     Input:	DS:SI target string (null terminated)
;     Output:	Zero set => path separator encountered in string
;		Zero clear => null encountered
;     Registers modified: SI

Procedure     ScanPathChar,NEAR
	LODSB				; fetch a character
 IF  DBCS				;AN000;
	invoke	TestKanj		;AN000;; 2/13/KK
	jz	NotKanjr		;AN000;; 2/13/KK
	LODSB				;AN000;; 2/13/KK
	OR	AL,AL			;AN000;; 2/13/KK  3/31/removed
	JNZ	ScanPathChar		;AN000;; 2/13/KK  3/31/removed
	INC	AL			;AN000;; 2/13/KK
	return				;AN000;; 2/13/KK
					;AN000;
NotKanjr:				;AN000;; 2/13/KK
 ENDIF					;AN000;
	call	PathSepGotCh
	JNZ	ScanPathChar		; not \, / or NUL => go back for more
	invoke	PathChrCmp		; path separator?
	return
EndProc       ScanPathChar

CODE ends
END
