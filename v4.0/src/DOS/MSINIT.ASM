;	SCCSID = @(#)msinit.asm 1.2 85/07/23
; TITLE MSINIT.ASM -- MS-DOS INITIALIZATION CODE
; AN000 version 4.0 Jan. 1988
; AN007 PTM 3957 - fake version for IBMCACHE.COM
; AN008 PTM 4070 - fake version for MS WINDOWS
include sysvar.inc
include doscntry.inc
include fastopen.inc

	I_need	DMAAdd,DWORD		; current dma address
	I_need	DPBHead,DWORD		; long pointer to DPB chain
	I_need	SFT_Addr,DWORD		; pointer to open file list
	I_need	NumIO,BYTE		; number of physical drives
	I_need	BuffHead,DWORD		; pointer to buffer chain
	I_need	EndMem,WORD		; first unavailable address in memory
	I_need	CurrentPDB,WORD 	; current process ID
	I_need	CreatePDB,BYTE		; TRUE => create a new PDB
	I_need	Arena_Head,WORD 	; paragraph address of head of arena
	I_need	sfTabl,BYTE		; internal file table
	I_need	SysInitVar,BYTE 	; label for internal structures
	I_need	NulDev,DWORD		; long pointer to device chain
	I_need	BCon,DWORD		; pointer to console device
	I_need	BClock,DWORD		; pointer to clock device
	I_need	CallUnit,BYTE		; unit field in dd packet
	I_need	CallBPB,DWORD		; returned BPB from DD
	I_need	Maxsec,WORD
	I_need	Dskchret,BYTE
	I_need	Devcall,BYTE
	i_need	Header,BYTE
	I_need	JShare,DWORD
	I_need	COUNTRY_CDPG,BYTE	 ; country info table, DOS 3.3
	I_need	SysInitTable,BYTE	 ; sys init table for SYSINIT
	I_need	FastOpenTable,BYTE	 ; table for FASTOPEN
	I_need	FETCHI_TAG,WORD 	 ; TAG CHECK
	I_need	Special_Entries,WORD	 ; address of special entries ;AN007;
	I_need	IFS_DOS_CALL,DWORD	 ; IFS IBMDOS CALL entry      ;AN000;
	I_need	HASHINITVAR,WORD	 ; hash table variables       ;AN000;
	I_need	Packet_Temp,WORD	 ; used for initial Hash table;AN000;
	I_need	BUF_HASH_PTR,DWORD	 ; used for initial Hash table;AN000;
	I_need	SWAP_ALWAYS_AREA,DWORD	 ; swap always area addr    ;AN000;
	I_need	SWAP_ALWAYS_AREA_LEN,WORD; swap always area length  ;AN000;
	I_need	SWAP_IN_DOS,DWORD	 ; swap in dos area	    ;AN000;
	I_need	SWAP_IN_DOS_LEN,WORD	 ; swap in dos area length  ;AN000;
	I_need	SWAP_AREA_LEN,WORD	 ; swap area length	    ;AN000;
	I_need	SWAP_START,BYTE 	 ; swap start addr	    ;AN000;
	I_need	SWAP_ALWAYS,BYTE	 ; swap always addr	    ;AN000;
	I_need	Hash_Temp,WORD		 ; temporary Hash table     ;AN000;

CODE		SEGMENT BYTE PUBLIC 'CODE'
	Extrn	IRETT:NEAR,INT2F:NEAR,CALL_ENTRY:NEAR,QUIT:NEAR,IFS_DOSCALL:FAR
	Extrn	COMMAND:NEAR,ABSDRD:NEAR,ABSDWRT:NEAR
CODE		ENDS

DATA	SEGMENT WORD PUBLIC 'DATA'
	ORG	0			; reset to beginning of data segment

Public MSINI001S,MSINI001E
MSINI001S label byte
INITBLOCK DB	110H DUP(0)	; Allow for segment round up

INITSP	DW	?
INITSS	DW	?
MSINI001E label byte

ASSUME	CS:DOSGROUP,SS:NOTHING

MOVDPB:
	DOSAssume   CS,<DS,ES>,"MovDPB"
; This section of code is safe from being overwritten by block move
	MOV	SS,CS:[INITSS]
	MOV	SP,CS:[INITSP]
	REP	MOVS	BYTE PTR [DI],[SI]
	CLD
	MOV	WORD PTR ES:[DMAADD+2],DX
	MOV	SI,WORD PTR [DPBHEAD]	; Address of first DPB
	MOV	WORD PTR ES:[DPBHEAD+2],ES
	MOV	WORD PTR ES:[sft_addr+2],ES
	MOV	CL,[NUMIO]	; Number of DPBs
	XOR	CH,CH
SETFINDPB:
	MOV	WORD PTR ES:[SI.dpb_next_dpb+2],ES
	MOV	ES:[SI.dpb_first_access],-1	 ; Never accessed before
	ADD	SI,DPBSIZ	; Point to next DPB
	LOOP	SETFINDPB
	SUB	SI,DPBSIZ
	MOV	WORD PTR ES:[SI.dpb_next_dpb+2],-1

;;	PUSH	ES
;;	MOV	DI,OFFSET DOSGroup:SYSBUF + 0Fh
;;	RCR	DI,1
;;	SHR	DI,1
;;	SHR	DI,1
;;	SHR	DI,1
;;	MOV	AX,ES
;;	ADD	AX,DI
;;	MOV	ES,AX
;;	ASSUME	ES:NOTHING
;;	XOR	DI,DI

;	MOV	DI,OFFSET DOSGroup:SYSBUF	; Set up one default buffer
;	MOV	WORD PTR [BUFFHEAD+2],ES
;	MOV	WORD PTR [BUFFHEAD],DI
;;	MOV	WORD PTR [Hash_Temp+4],ES   ;LB. intitialize one Hash entry   ;AN000;
;;	MOV	WORD PTR [Hash_Temp+2],DI   ;LB.			      ;AN000;
;;	MOV	WORD PTR [Hash_Temp+6],0    ;LB. dirty count =0 	      ;AN000;
;;	MOV	WORD PTR ES:[DI.buf_ID],00FFH
;;	MOV	WORD PTR ES:[DI.buf_next],DI  ;;;1/19/88
;;	MOV	WORD PTR ES:[DI.buf_prev],DI  ;;;1/19/88

;;	POP	ES
	MOV	SI,OFFSET DOSGROUP:Version_Fake_Table ;MS.;AN007;move special
	MOV	DI,ES:[Special_Entries] 	      ;MS.;AN007;entries
	MOV	CX,ES:[Temp_Var]		      ;MS.;AN007;
	REP	MOVSB				      ;MS.;AN007;

	ASSUME	ES:DOSGroup

	PUSH	ES
	INC	DX			    ; Leave enough room for the ARENA
	MOV	SI,EndMem
	invoke	$Dup_PDB
;	MOV	BYTE PTR [CreatePDB],0FFh   ; create jfns and set CurrentPDB
;	invoke	$CREATE_PROCESS_DATA_BLOCK     ; Set up segment
ASSUME	DS:NOTHING,ES:NOTHING
	POP	ES
	DOSAssume   CS,<ES>,"INIT/CreateProcess"
;
; set up memory arena
;SPECIAL NOTE FOR HIGHMEM VERSION
; At this point a process header has been built where the start of the CONSTANTS
; segment as refed by CS is. From this point until the return below be careful
; about references off of CS.
;
	MOV	AX,[CurrentPDB]
	MOV	ES:[CurrentPDB],AX	   ; Put it in the REAL location
	MOV	BYTE PTR ES:[CreatePDB],0h ; reset flag in REAL location
	DEC	AX
	MOV	ES:[arena_head],AX
	PUSH	DS
	MOV	DS,AX
	MOV	DS:[arena_signature],arena_signature_end
	MOV	DS:[arena_owner],arena_owner_system
	SUB	AX,ES:[ENDMEM]
	NEG	AX
	DEC	AX
	MOV	DS:[arena_size],AX
	POP	DS

	MOV	DI,OFFSET DOSGROUP:sftabl + SFTable   ; Point to sft 0
	MOV	AX,3
	STOSW		; Adjust Refcount
	MOV	DI,OFFSET DOSGROUP:SySInitTable

	IF	NOT Installed
	invoke	NETWINIT
;	ELSE
;	invoke	NETWINIT
;	%OUT Random NETWINIT done at install
	ENDIF

procedure XXX,FAR
	RET
EndProc XXX
DATA	ENDS

; the next segment defines a new class that MUST appear last in the link map.
; This defines several important locations for the initialization process that
; must be the first available locations of free memory.

LAST	SEGMENT PARA PUBLIC 'LAST'
	PUBLIC	SYSBUF
	PUBLIC	MEMSTRT

SYSBUF	LABEL	WORD
ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

INITIRET:			; Temp IRET instruction
	IRET

	entry	DOSINIT
	CLI
	CLD
	MOV	[ENDMEM],DX
	MOV	[INITSP],SP
	MOV	[INITSS],SS
	MOV	AX,CS
	MOV	SS,AX
ASSUME	SS:DOSGROUP
	MOV	SP,OFFSET DOSGROUP:INITSTACK
	MOV	WORD PTR [NULDEV+2],DS
	MOV	WORD PTR [NULDEV],SI   ; DS:SI Points to CONSOLE Device

	PUSH	DS		; Need Crit vector inited to use DEVIOCALL
	XOR	AX,AX
	MOV	DS,AX
	MOV	AX,OFFSET DOSGROUP:INITIRET
	MOV	DS:[addr_int_IBM],AX
	MOV	AX,CS
	MOV	DS:[addr_int_IBM+2],AX
	POP	DS

	CALL	CHARINIT
	PUSH	SI			; Save pointer to header
	PUSH	CS
	POP	ES
	ASSUME	ES:DOSGROUP
	MOV	DI,OFFSET DOSGROUP:sftabl + SFTable   ; Point to sft 0
	MOV	AX,3
	STOSW		; Refcount
	DEC	AL
	errnz	sf_mode-(sf_ref_count+2)
	STOSW		; Access rd/wr, compatibility
	XOR	AL,AL
	errnz	sf_attr-(sf_mode+2)
	STOSB		; attribute
	MOV	AL,devid_device_EOF OR devid_device OR ISCIN OR ISCOUT
	errnz	sf_flags-(sf_attr+1)
	STOSW		; Flags
	MOV	AX,SI
	errnz	sf_devptr-(sf_flags+2)
	STOSW			; Device pointer in devptr
	MOV	AX,DS
	STOSW
	XOR	AX,AX
	errnz	sf_firclus-(sf_devptr+4)
	STOSW			; firclus
	errnz	sf_time-(sf_firclus+2)
	STOSW			; time
	errnz	sf_date-(sf_time+2)
	STOSW			; date
	DEC	AX
	errnz	sf_size-(sf_date+2)
	STOSW			; size
	STOSW
	INC	AX
	errnz	sf_position-(sf_size+4)
	STOSW			; position
	STOSW
	ADD	DI,sf_name - sf_cluspos ;Point at name
	ADD	SI,SDEVNAME		; Point to name
	MOV	CX,4
	REP	MOVSW	; Name
	MOV	CL,3
	MOV	AL," "
	REP	STOSB	; Extension
	POP	SI	; Get back pointer to header
	OR	BYTE PTR [SI.SDEVATT],ISCIN OR ISCOUT
	MOV	WORD PTR [BCON],SI
	MOV	WORD PTR [BCON+2],DS
CHAR_INIT_LOOP:
	LDS	SI,DWORD PTR [SI]		; AUX device
	CALL	CHARINIT
	TEST	BYTE PTR [SI.SDEVATT],ISCLOCK
	JZ	CHAR_INIT_LOOP
	MOV	WORD PTR [BCLOCK],SI
	MOV	WORD PTR [BCLOCK+2],DS
	MOV	BP,OFFSET DOSGROUP:MEMSTRT	; ES:BP points to DPB
PERDRV:
	LDS	SI,DWORD PTR [SI]		; Next device
	CMP	SI,-1
	JZ	CONTINIT
	CALL	CHARINIT
	TEST	[SI.SDEVATT],DEVTYP
	JNZ	PERDRV				; Skip any other character devs
	MOV	CL,[CALLUNIT]
	XOR	CH,CH
	MOV	[SI.SDEVNAME],CL		; Number of units in name field
	MOV	DL,[NUMIO]
	XOR	DH,DH
	ADD	[NUMIO],CL
	PUSH	DS
	PUSH	SI
	LDS	BX,[CALLBPB]
PERUNIT:
	MOV	SI,[BX] 		; DS:SI Points to BPB
	INC	BX
	INC	BX			; On to next BPB
	MOV	ES:[BP.dpb_drive],DL
	MOV	ES:[BP.dpb_UNIT],DH
	PUSH	BX
	PUSH	CX
	PUSH	DX
	invoke	$SETDPB
	MOV	AX,ES:[BP.dpb_sector_size]
	CMP	AX,[MAXSEC]
	JBE	NOTMAX
	MOV	[MAXSEC],AX
NOTMAX:

	POP	DX
	POP	CX
	POP	BX
	MOV	AX,DS			; Save DS
	POP	SI
	POP	DS
	MOV	WORD PTR ES:[BP.dpb_driver_addr],SI
	MOV	WORD PTR ES:[BP.dpb_driver_addr+2],DS
	PUSH	DS
	PUSH	SI
	INC	DH
	INC	DL
	MOV	DS,AX
	ADD	BP,DPBSIZ
	LOOP	PERUNIT
	POP	SI
	POP	DS
	JMP	PERDRV

CONTINIT:
	PUSH	CS
	POP	DS
ASSUME	DS:DOSGROUP
;
; BP has the current offset to the allocated DPBs.  Calculate true address of
; buffers, FATs, free space
;
	MOV	DI,BP			; First byte after current DPBs
;
; Compute location of first buffer.  If we are to make buffers paragraph
; aligned, change this code to make sure that AX = 0 mod 16 and change the
; setting of the segment address part of BuffHead to make sure that the offset
; is zero.  Alternatively, this may be done by making segment LAST paragraph
; aligned.
;
;;;	MOV	BP,[MAXSEC]		; get size of buffer
	MOV	AX,OFFSET DOSGROUP:SYSBUF
;
; Compute location of DPBs
;
;;;	ADD	AX,BP			; One I/O buffer
;;;	ADD	AX,BUFINSIZ
	MOV	WORD PTR [DPBHEAD],AX	; True start of DPBs
	MOV	DX,AX
	SUB	DX,OFFSET DOSGROUP:SYSBUF
	MOV	BP,DX
	ADD	BP,DI			; Allocate buffer space
	SUB	BP,ADJFAC		; True address of free memory
	PUSH	BP
	MOV	DI,OFFSET DOSGROUP:MEMSTRT    ; Current start of DPBs
	ADD	DI,dpb_next_dpb 	; Point at dpb_next_dpb field
	MOV	CL,[NUMIO]
	XOR	CH,CH
TRUEDPBAD:
	ADD	AX,DPBSIZ	; Compute address of next DPB
	STOSW			; Set the link to next DPB
	ADD	DI,DPBSIZ-2	; Point at next address
	LOOP	TRUEDPBAD
	SUB	DI,DPBSIZ	; Point at last dpb_next_dpb field
	MOV	AX,-1
	STOSW			; End of list

	MOV	[Special_Entries],BP ;MS.;AN007 save starting address of Special entries
	MOV	SI,OFFSET DOSGROUP:Version_Fake_Table	;MS.;AN007
	MOV	DX,SI		     ;MS.;AN007
	XOR	AH,AH		     ;MS.;AN007
NextEntry:			     ;MS.;AN007
	LODSB			     ;MS.;AN007  get name length
	OR	AL,AL		     ;MS.;AN007  end of list
	JZ	endlist 	     ;MS.;AN007  yes
	ADD	SI,AX		     ;MS.;AN007  position to
	ADD	SI,3		     ;MS.;AN007  next entry
	JMP	NextEntry	     ;MS.;AN007
endlist:			     ;MS.;AN007
	SUB	SI,DX		     ;MS.;AN007
	MOV	[Temp_Var],SI	     ;MS.;AN007  si = total table length
	ADD	BP,SI		     ;MS.;AN007


	ADD	BP,15		; True start of free space (round up to segment)
	RCR	BP,1
	MOV	CL,3
	SHR	BP,CL		; Number of segments for DOS resources
;;;;;;	MOV	[IBMDOS_SIZE],BP ;MS. save it for information
	MOV	DX,CS
	ADD	DX,BP		; First free segment
	MOV	BX,0FH
	MOV	CX,[ENDMEM]

	IF	HIGHMEM
	SUB	CX,BP
	MOV	BP,CX		; Segment of DOS
	MOV	DX,CS		; Program segment
	ENDIF

	IF	NOT HIGHMEM
	MOV	BP,CS
	ENDIF

; BP has segment of DOS (whether to load high or run in place)
; DX has program segment (whether after DOS or overlaying DOS)
; CX has size of memory in paragraphs (reduced by DOS size if HIGHMEM)
	MOV	[ENDMEM],CX
	MOV	ES,BP
ASSUME	ES:DOSGROUP

	IF	HIGHMEM
	XOR	SI,SI
	MOV	DI,SI
	MOV	CX,OFFSET DOSGROUP:SYSBUF  ;# bytes to move
	SHR	CX,1		;# words to move (carry set if odd)
	REP MOVSW		; Move DOS to high memory
	JNC	NOTODD
	MOVSB
NOTODD:
	ENDIF

	MOV	WORD PTR ES:[DSKCHRET+3],ES
	XOR	AX,AX
	MOV	DS,AX
	MOV	ES,AX
ASSUME	DS:NOTHING,ES:NOTHING
	MOV	DI,INTBASE+2
	MOV	AX,BP		; Final DOS segment to AX

	EXTRN	DIVOV:near
	MOV	WORD PTR DS:[0],OFFSET DOSGROUP:DIVOV	; Set default divide trap address
	MOV	DS:[2],AX

; Set vectors 20-28 and 2A-3F to point to IRET.

	MOV	CX,17
	REP	STOSW		; Set 9 segments
				;   Sets segs for INTs 20H-28H
	ADD	DI,6		; Skip INT 29H vector (FAST CON) as it may
				;   already be set.
	MOV	CX,43
	REP	STOSW		; Set 22 segments
				;   Sets segs for vectors 2AH-3FH

	MOV	DI,INTBASE
	MOV	AX,OFFSET DOSGROUP:IRETT
	MOV	CX,9		; Set 9 offsets (skip 2 between each)
				;   Sets offsets for INTs 20H-28H

ISET1:
	STOSW
	ADD	DI,2
	LOOP	ISET1

	ADD	DI,4		; Skip vector 29H

	MOV	CX,22		; Set 22 offsets (skip 2 between each)
				;   Sets offsets for INTs 2AH-3FH

ISET2:
	STOSW
	ADD	DI,2
	LOOP	ISET2

	MOV	AX,BP		; Final DOS segment to AX

IF installed
; the following two are in the Code segment, thus the CS
; overrides
	MOV	WORD PTR DS:[02FH * 4],OFFSET DOSGROUP:INT2F
ENDIF

; Set up entry point call at vectors 30-31H
	MOV	BYTE PTR DS:[ENTRYPOINT],mi_Long_JMP
	MOV	WORD PTR DS:[ENTRYPOINT+1],OFFSET DOSGROUP:CALL_ENTRY
	MOV	WORD PTR DS:[ENTRYPOINT+3],AX

	IF	ALTVECT
	MOV	DI,ALTBASE+2
	MOV	CX,15
	REP	STOSW		; Set 8 segments (skip 2 between each)
	ENDIF

	MOV	WORD PTR DS:[addr_int_abort],OFFSET DOSGROUP:QUIT
	MOV	WORD PTR DS:[addr_int_command],OFFSET DOSGROUP:COMMAND
	MOV	WORD PTR DS:[addr_int_terminate],100H
	MOV	WORD PTR DS:[addr_int_terminate+2],DX
	MOV	WORD PTR DS:[addr_int_disk_read],OFFSET DOSGROUP:ABSDRD   ; INT 25
	MOV	WORD PTR DS:[addr_int_disk_write],OFFSET DOSGROUP:ABSDWRT  ; INT 26
	EXTRN	Stay_resident:NEAR
	MOV	WORD PTR DS:[addr_int_keep_process],OFFSET DOSGROUP:Stay_resident

	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
ASSUME	DS:DOSGROUP,ES:DOSGROUP
;
; Initialize the jump table for the sharer...
;
	MOV	DI,OFFSET DOSGroup:JShare
	MOV	AX,CS
	MOV	CX,15
JumpTabLoop:
	ADD	DI,2			; skip offset
	STOSW				; drop in segment
	LOOP	JumpTabLoop

	MOV	AX,OFFSET DOSGROUP:INITBLOCK
	ADD	AX,0Fh			; round to a paragraph
	MOV	CL,4
	SHR	AX,CL
	MOV	DI,DS
	ADD	DI,AX
	INC	DI
	MOV	[CurrentPDB],DI
	PUSH	BP
	PUSH	DX		; Save COMMAND address
	MOV	AX,[ENDMEM]
	MOV	DX,DI

	invoke	SETMEM		; Basic Header
ASSUME	DS:NOTHING,ES:NOTHING
	PUSH	CS
	POP	DS
ASSUME	DS:DOSGROUP
	MOV	DI,PDB_JFN_Table
	XOR	AX,AX
	STOSW
	STOSB			; 0,1 and 2 are CON device
	MOV	AL,0FFH
	MOV	CX,FilPerProc - 3
	REP	STOSB		; Rest are unused
	PUSH	CS
	POP	ES
ASSUME	ES:DOSGROUP
	MOV	WORD PTR [sft_addr+2],DS     ; Must be set to print messages

; After this points the char device functions for CON will work for
; printing messages

	IF	(NOT IBM) OR (DEBUG)
	IF	NOT ALTVECT
	MOV	SI,OFFSET DOSGROUP:HEADER
OUTMES:
	LODS	CS:BYTE PTR [SI]
	CMP	AL,"$"
	JZ	OUTDONE
	invoke	OUT
	JMP	SHORT OUTMES
OUTDONE:
	PUSH	CS			; OUT stomps on segments
	POP	DS
	PUSH	CS
	POP	ES
	ENDIF
	ENDIF

;F.C Modification start  DOS 3.3
	MOV	SI,OFFSET DOSGROUP:COUNTRY_CDPG  ;F.C. for DOS 3.3 country info
						 ; table address
	MOV	WORD PTR ES:[SI.ccUcase_ptr + 2],ES    ; initialize double word
	MOV	WORD PTR ES:[SI.ccFileUcase_ptr + 2],ES ; pointers with DOSGROUP
	MOV	WORD PTR ES:[SI.ccFileChar_ptr + 2],ES
	MOV	WORD PTR ES:[SI.ccCollate_ptr + 2],ES
	MOV	WORD PTR ES:[SI.ccMono_ptr + 2],ES
	MOV	WORD PTR ES:[SI.ccDBCS_ptr + 2],ES	; 2/16/KK

	MOV	SI,OFFSET DOSGROUP:SysInitTable
	MOV	WORD PTR ES:[SI.SYSI_Country_Tab + 2],ES
	MOV	WORD PTR ES:[SI.SYSI_InitVars + 2],ES

	MOV	WORD PTR ES:[BUFFHEAD+2],ES	  ;LB. DOS 4.00 buffer head pointer ;AN000;
	MOV	SI,OFFSET DOSGROUP:HASHINITVAR	  ;LB. points to Hashinitvar	   ;AN000;
	MOV	WORD PTR ES:[BUFFHEAD],SI	  ;LB.				   ;AN000;
	MOV	WORD PTR ES:[BUF_HASH_PTR+2],ES   ;LB.				   ;AN000;
	MOV	SI,OFFSET DOSGROUP:Hash_Temp	  ;LB.				   ;AN000;
	MOV	WORD PTR ES:[BUF_HASH_PTR],SI	  ;LB.				   ;AN000;

	MOV	SI,OFFSET DOSGROUP:FastOpenTable
	MOV	WORD PTR ES:[SI.FASTOPEN_NAME_CACHING + 2],ES
	MOV	ES:[FETCHI_TAG],22642	  ; TAG for IBM,
					  ; Fetchi's serial # = 822642
	MOV	WORD PTR ES:[IFS_DOS_CALL+2],ES   ;IFS. 			;AN000;
	MOV	SI,OFFSET DOSGROUP:IFS_DOSCALL	  ;IFS. 			;AN000;
	MOV	WORD PTR ES:[IFS_DOS_CALL],SI	  ;IFS. 			;AN000;

	MOV	DI,OFFSET DOSGROUP:SWAP_START	  ;IFS. 			;AN000;
	MOV	CX,OFFSET DOSGROUP:SWAP_END	  ;IFS. 			;AN000;
	MOV	DX,OFFSET DOSGroup:Swap_Always	  ;IFS. 			;AN000;
	MOV	BP,CX			;IFS.					;AN000;
	SUB	BP,DI			;IFS.					;AN000;
	SHR	BP,1			;IFS. div by 2, remainder in carry	;AN000;
	ADC	BP,0			;IFS. div by 2 + round up		;AN000;
	SHL	BP,1			;IFS. round up to 2 boundary.		;AN000;
	MOV	ES:[SWAP_AREA_LEN],BP	;IFS.					;AN000;

	SUB	CX,DX			;IFS.					;AN000;
	SUB	DX,DI			;IFS.					;AN000;
	SHR	CX,1			;IFS. div by 2, remainder in carry	;AN000;
	ADC	CX,0			;IFS. div by 2 + round up		;AN000;
	SHL	CX,1			;IFS. round up to 2 boundary.		;AN000;
	MOV	ES:[SWAP_IN_DOS_LEN],CX 	    ;IFS.			;AN000;
	MOV	WORD PTR ES:[SWAP_ALWAYS_AREA],DI   ;IFS.			;AN000;
	MOV	WORD PTR ES:[SWAP_ALWAYS_AREA+2],ES ;IFS.			;AN000;
	OR	DX,8000H			    ;IFS.			;AN000;
	MOV	ES:[SWAP_ALWAYS_AREA_LEN],DX	    ;IFS.			;AN000;
	MOV	DI,OFFSET DOSGroup:Swap_Always	    ;IFS.			;AN000;
	MOV	WORD PTR ES:[SWAP_IN_DOS],DI	    ;IFS.			;AN000;
	MOV	WORD PTR ES:[SWAP_IN_DOS+2],ES	    ;IFS.			;AN000;



;F.C Modification end	 DOS 3.3

; Move the FATs into position
	POP	DX			; Restore COMMAND address
	POP	BP
	POP	CX			; True address of free memory
	MOV	SI,OFFSET DOSGROUP:MEMSTRT	; Place to move DPBs from
	MOV	DI,WORD PTR [DPBHEAD]	; Place to move DPBs to
	SUB	CX,DI			; Total length of DPBs
	CMP	DI,SI
	JBE	MOVJMP			; Are we moving to higher or lower memory?
	DEC	CX			; Move backwards to higher memory
	ADD	DI,CX
	ADD	SI,CX
	INC	CX
	STD
MOVJMP:
	MOV	ES,BP
ASSUME	ES:DOSGROUP
	JMP	MOVDPB

CHARINIT:
ASSUME	DS:NOTHING,ES:NOTHING
; DS:SI Points to device header
	MOV	[DEVCALL.REQLEN],DINITHL
	MOV	[DEVCALL.REQUNIT],0
	MOV	[DEVCALL.REQFUNC],DEVINIT
	MOV	[DEVCALL.REQSTAT],0
	PUSH	ES
	PUSH	BX
	PUSH	AX
	MOV	BX,OFFSET DOSGROUP:DEVCALL
	PUSH	CS
	POP	ES
	invoke	DEVIOCALL2
	POP	AX
	POP	BX
	POP	ES
	RET

Public MSINI002S,MSINI002E
MSINI002S label byte

	DB	100H DUP(?)
INITSTACK LABEL BYTE
	DW	?
	DB	"ADD SPECIAL ENTRIES",0     ;AN007  tiltle
;The following entries don't expect version 4.0
;The entry format: name_length, name, expected version, fake count
;fake_count: ff means the version will be reset when Abort or Exec is encountered
;	     n means the version will be reset after n DOS version calls are issued
;
Version_Fake_Table:			    ;AN007  starting address for special
	DB	12,"IBMCACHE.COM",3,40,255  ;AN007  ibmcache     1
	DB	12,"IBMCACHE.SYS",3,40,255  ;AN007  ibmcache     2
	DB	12,"DXMA0MOD.SYS",3,40,255  ;AN007  lan support  3
	DB	10,"WIN200.BIN"  ,3,40,4    ;AN008  windows      4
	DB	 9,"PSCPG.COM"   ,3,40,255  ;AN008  vittoria     5
	DB	11,"DCJSS02.EXE" ,3,40,255  ;AN008  netview      6
	DB	 8,"ISAM.EXE"    ,3,40,255  ;AN008  basic        7
	DB	 9,"ISAM2.EXE"   ,3,40,255  ;AN008  basic        8
	DB	12,"DFIA0MOD.SYS",3,40,255  ;AN008  lan support  9
	DB	20  dup(0)		    ;AN007

MEMSTRT LABEL	WORD
MSINI002E label byte
ADJFAC	EQU	MEMSTRT-SYSBUF

LAST	ENDS
