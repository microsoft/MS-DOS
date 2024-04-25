;	SCCSID = @(#)exec.asm	1.3 85/08/13
;	SCCSID = @(#)exec.asm	1.3 85/08/13
;    AN000 version 4.0 jan. 1988
;    A007  PTM 3957 - fake vesrion for IBMCACHE.COM
;    A008  PTM 4070 - fake version for MS WINDOWS

SUBTTL $exec - load/go a program
PAGE
;
; Assembler usage:
;	    LDS     DX, name
;	    LES     BX, blk
;	    MOV     AH, Exec
;	    MOV     AL, func
;	    INT     int_command
;
;	AL  Function
;	--  --------
;	 0  Load and execute the program.
;	 1  Load, create  the  program	header	but  do  not
;	    begin execution.
;	 3  Load overlay. No header created.
;
;	    AL = 0 -> load/execute program
;
;	    +---------------------------+
;	    | WORD segment address of	|
;	    | environment.		|
;	    +---------------------------+
;	    | DWORD pointer to ASCIZ	|
;	    | command line at 80h	|
;	    +---------------------------+
;	    | DWORD pointer to default	|
;	    | FCB to be passed at 5Ch	|
;	    +---------------------------+
;	    | DWORD pointer to default	|
;	    | FCB to be passed at 6Ch	|
;	    +---------------------------+
;
;	    AL = 1 -> load program
;
;	    +---------------------------+
;	    | WORD segment address of	|
;	    | environment.		|
;	    +---------------------------+
;	    | DWORD pointer to ASCIZ	|
;	    | command line at 80h	|
;	    +---------------------------+
;	    | DWORD pointer to default	|
;	    | FCB to be passed at 5Ch	|
;	    +---------------------------+
;	    | DWORD pointer to default	|
;	    | FCB to be passed at 6Ch	|
;	    +---------------------------+
;	    | DWORD returned value of	|
;	    | CS:IP			|
;	    +---------------------------+
;	    | DWORD returned value of	|
;	    | SS:IP			|
;	    +---------------------------+
;
;	    AL = 3 -> load overlay
;
;	    +---------------------------+
;	    | WORD segment address where|
;	    | file will be loaded.	|
;	    +---------------------------+
;	    | WORD relocation factor to |
;	    | be applied to the image.	|
;	    +---------------------------+
;
; Returns:
;	    AX = error_invalid_function
;	       = error_bad_format
;	       = error_bad_environment
;	       = error_not_enough_memory
;	       = error_file_not_found
;
;   Revision history:
;
;	 A000	version 4.00  Jan. 1988
;
include EA.INC
include version.inc

	I_Need	   Temp_Var2,WORD	     ;AN000;file type from $open
	I_Need	   Special_Entries,WORD      ;AN007;address of special entries
	I_Need	   Special_Version,WORD      ;AN007;special version number
	I_Need	   Fake_Count,BYTE	     ;AN008;fake version count

IF	BUFFERFLAG
	extrn	restore_user_map:near
ENDIF

TABLE	SEGMENT

exec_init_SP	    DW	?
exec_init_SS	    DW	?
exec_init_IP	    DW	?
exec_init_CS	    DW	?

exec_internal_buffer	EQU OpenBuf

exec_signature	    DW	?		; must contain 4D5A  (yay zibo!)
exec_len_mod_512    DW	?		; low 9 bits of length
exec_pages	    DW	?		; number of 512b pages in file
exec_rle_count	    DW	?		; count of reloc entries
exec_par_dir	    DW	?		; number of paragraphs before image
exec_min_BSS	    DW	?		; minimum number of para of BSS
exec_max_BSS	    DW	?		; max number of para of BSS
exec_SS 	    DW	?		; stack of image
exec_SP 	    DW	?		; SP of image
exec_chksum	    DW	?		; checksum  of file (ignored)
exec_IP 	    DW	?		; IP of entry
exec_CS 	    DW	?		; CS of entry
exec_rle_table	    DW	?		; byte offset of reloc table
Exec_header_len     EQU $-Exec_Signature

exec_internal_buffer_size   EQU (128+128+53+curdirLEN)
%out	Please make sure that the following are contiguous and of the
%out	following sizes:
%out
%out	OpenBuf     128
%out	RenBuf	    128
%out	SearchBuf    53
%out	DummyCDS    CurDirLen

TABLE	ENDS

.sall

procedure   $Exec,NEAR
	ASSUME	DS:NOTHING, ES:NOTHING
PUBLIC EXEC001S,EXEC001E
EXEC001S:
	LocalVar    exec_blk,DWORD
	LocalVar    exec_func,BYTE
	LocalVar    exec_load_high,BYTE
	LocalVar    exec_fh,WORD
	LocalVar    exec_rel_fac,WORD
	LocalVar    exec_res_len_para,WORD
	LocalVar    exec_environ,WORD
	LocalVar    exec_size,WORD
	LocalVar    exec_load_block,WORD
	LocalVar    exec_dma,WORD
	LocalVar    execNameLen,WORD
	LocalVar    execName,DWORD
EXEC001E:
	Enter
;
; validate function
;

	CMP	AL,3			; only 0, 1 or 3 are allowed
	JNA	exec_check_2

exec_bad_fun:
	MOV	EXTERR_LOCUS,errLOC_Unk ; Extended Error Locus
	mov	al,error_invalid_function

exec_ret_err:
	Leave
	transfer    SYS_RET_ERR

exec_check_2:
	CMP	AL,2
	JZ	exec_bad_fun

	MOV	exec_blkL,BX		; stash args
	MOV	exec_blkH,ES
	MOV	exec_func,AL
	MOV	exec_load_high,0
;
; set up length of exec name
;
	MOV	execNameL,DX
	MOV	execNameH,DS
	MOV	SI,DX			; move pointer to convenient place
	invoke	DStrLen
	MOV	ExecNameLen,CX		; save length

	XOR	AL,AL			; open for reading
	PUSH	BP
	invoke	$OPEN			; is the file there?
	POP	BP
	JC	exec_ret_err
;File Type Checking
;	CMP	BYTE PTR [Temp_Var2],EAEXISTING      ;AN000;;FT.  old file ?
;	JZ	oldexf				     ;AN000;;FT.  yes
;	TEST	BYTE PTR EXEC_FUNC,EXEC_FUNC_OVERLAY ;AN000;;FT.  exec overlay?
;	JNZ	exovrly 			     ;AN000;;FT.  yes
;	CMP	BYTE PTR [Temp_Var2],EAEXECUTABLE    ;AN000;;FT.  only file type
;	JZ	oldexf				     ;AN000;;FT.  3 & 4 will pass
;	CMP	BYTE PTR [Temp_Var2],EAINSTALLABLE   ;AN000;;FT.
;	JZ	oldexf				     ;AN000;;FT.
;exerr: 					      ;AN000;;FT.
;	MOV	AL,error_access_denied		     ;AN000;;FT.  error
;	JMP	exec_ret_err			     ;AN000;;FT.
;exovrly:					      ;AN000;;FT.
;	CMP	BYTE PTR [Temp_Var2],EAOVERLAY	     ;AN000;;FT.  only 5,6,7  pass
;	JZ	oldexf				     ;AN000;;FT.
;	CMP	BYTE PTR [Temp_Var2],EADEV_DRIVER    ;AN000;;FT.
;	JZ	oldexf				     ;AN000;;FT.
;	CMP	BYTE PTR [Temp_Var2],EAIFS_DRIVER    ;AN000;;FT.
;	JNZ	exerr				     ;AN000;;FT.
;
;oldexf:					      ;AN000;
;File Type Checking

	MOV	exec_fh,AX
	MOV	BX,AX
	XOR	AL,AL
	invoke	$IOCTL
	JC	Exec_bombJ
	TEST	DL,devid_ISDEV
	JZ	exec_check_environ
	MOV	AL,error_file_not_found
Exec_bombJ:
	JMP	Exec_Bomb

BadEnv:
	MOV	AL,error_bad_environment
	JMP	exec_bomb

exec_check_environ:
	MOV	exec_load_block,0
	MOV	exec_environ,0

	TEST	BYTE PTR exec_func,exec_func_overlay	; overlays... no environment
	JNZ	exec_read_header
	LDS	SI,exec_blk		; get block
	MOV	AX,[SI].Exec1_environ	; address of environ
	OR	AX,AX
	JNZ	exec_scan_env
	MOV	DS,CurrentPDB
	MOV	AX,DS:[PDB_environ]
	MOV	exec_environ,AX
	OR	AX,AX
	JZ	exec_read_header

exec_scan_env:
	MOV	ES,AX
	XOR	DI,DI
	MOV	CX,07FFFh		; at most 32k of environment
	XOR	AL,AL

exec_get_environ_len:
	REPNZ	SCASB			; find that nul byte
	JNZ	BadEnv
	DEC	CX			; Dec CX for the next nul byte test
	JB	BadEnv			; gone beyond the end of the environment
	SCASB				; is there another nul byte?
	JNZ	exec_get_environ_len	; no, scan some more
	PUSH	DI
	LEA	BX,[DI+0Fh+2]
	ADD	BX,ExecNameLen		; BX <- length of environment
					; remember argv[0] length
					; round up and remember argc
	MOV	CL,4
	SHR	BX,CL			; number of paragraphs needed
	PUSH	ES
	invoke	$ALLOC			; can we get the space?
	POP	DS
	POP	CX
	JNC	exec_save_environ
	JMP	exec_no_mem		; nope... cry and sob

exec_save_environ:
	MOV	ES,AX
	MOV	exec_environ,AX 	; save him for a rainy day
	XOR	SI,SI
	MOV	DI,SI
	REP	MOVSB			; copy the environment
	MOV	AX,1
	STOSW
	LDS	SI,execName
	MOV	CX,execNameLen
	REP	MOVSB

exec_read_header:
;
; We read in the program header into the above data area and determine
; where in this memory the image will be located.
;
	Context DS
	MOV	CX,exec_header_len	; header size
	MOV	DX,OFFSET DOSGROUP:exec_signature
	PUSH	ES
	PUSH	DS
	CALL	ExecRead
	POP	DS
	POP	ES
	JC	exec_bad_file
	OR	AX,AX
	JZ	exec_bad_file
	CMP	AX,exec_header_len	; did we read the right number?
	JNZ	exec_com_filej		; yep... continue
	TEST	exec_max_BSS,-1 	; indicate load high?
	JNZ	exec_check_sig
	MOV	exec_load_high,-1
exec_check_sig:
	MOV	AX,exec_signature
	CMP	AX,exe_valid_signature	; zibo arises!
	JZ	exec_save_start 	; assume com file if no signature
	CMP	AX,exe_valid_old_signature  ; zibo arises!
	JZ	exec_save_start 	; assume com file if no signature

exec_com_filej:
	JMP	exec_com_file

;
; We have the program header... determine memory requirements
;
exec_save_start:
	MOV	AX,exec_pages		; get 512-byte pages
	MOV	CL,5			; convert to paragraphs
	SHL	AX,CL
	SUB	AX,exec_par_dir 	; AX = size in paragraphs
	MOV	exec_res_len_para,AX

;
; Do we need to allocate memory?  Yes if function is not load-overlay
;
	TEST	BYTE PTR exec_func,exec_func_overlay
	JZ	exec_allocate		; allocation of space
;
; get load address from block
;
	LES	DI,exec_blk
	MOV	AX,ES:[DI].exec3_load_addr
	MOV	exec_dma,AX
	MOV	AX,ES:[DI].exec3_reloc_fac
	MOV	exec_rel_fac,AX
IF DEBUG
	JMP	exec_find_res
ELSE
	JMP	SHORT exec_find_res
ENDIF

exec_no_mem:
	MOV	AL,error_not_enough_memory
	JMP	SHORT exec_bomb

exec_bad_file:
	MOV	AL,error_bad_format

exec_bomb:
	ASSUME	DS:NOTHING,ES:NOTHING
	MOV	BX,exec_fh
	CALL	exec_dealloc
	LeaveCrit   CritMem
	SaveReg <AX,BP>
	invoke	$CLOSE
	RestoreReg  <BP,AX>
	JMP	Exec_Ret_Err

exec_allocate:
	DOSAssume   CS,<DS>,"EXEC/exec_allocate"
	PUSH	AX
	MOV	BX,0FFFFh		; see how much room in arena
	PUSH	DS
	invoke	$ALLOC			; should have carry set and BX has max
	POP	DS
	POP	AX
	ADD	AX,10h			; room for header
	CMP	BX,11h			; enough room for a header
	JB	exec_no_mem
	CMP	AX,BX			; is there enough for bare image?
	JA	exec_no_mem
	TEST	exec_load_high,-1	; if load high, use max
	JNZ	exec_BX_max		; use max
	ADD	AX,exec_min_BSS 	; go for min allocation
	JC	exec_no_mem		; oops! carry
	CMP	AX,BX			; enough space?
	JA	exec_no_mem		; nope...
	SUB	AX,exec_min_BSS
	ADD	AX,exec_max_BSS 	; go for the MAX
	JC	exec_BX_max
	CMP	AX,BX
	JBE	exec_got_block

exec_BX_max:
	MOV	AX,BX

exec_got_block:
	PUSH	DS
	MOV	BX,AX
	MOV	exec_size,BX
	invoke	$ALLOC			; get the space
	POP	DS
	JC	exec_no_mem
	MOV	exec_load_block,AX
	ADD	AX,10h
	TEST	exec_load_high,-1
	JZ	exec_use_ax		; use ax for load info
	ADD	AX,exec_size		; go to end
	SUB	AX,exec_res_len_para	; drop off header
	SUB	AX,10h			; drop off pdb
exec_use_ax:
	MOV	exec_rel_fac,AX 	; new segment
	MOV	exec_dma,AX		; beginning of dma

;
; Determine the location in the file of the beginning of the resident
;
exec_find_res:
	MOV	DX,exec_par_dir
	PUSH	DX
	MOV	CL,4
	SHL	DX,CL			; low word of location
	POP	AX
	MOV	CL,12
	SHR	AX,CL			; high word of location
	MOV	CX,AX			; CX <- high

;
; Read in the resident image (first, seek to it)
;
	MOV	BX,exec_fh
	PUSH	DS
	XOR	AL,AL
	invoke	$LSEEK			; seek to resident
	POP	DS
	jnc	exec_big_read
	jmp	exec_bomb

exec_big_read:				; Read resident into memory
	MOV	BX,exec_res_len_para
	CMP	BX,1000h		; too many bytes to read?
	JB	exec_read_ok
	MOV	BX,0FE0h		; max in one chunk FE00 bytes

exec_read_ok:
	SUB	exec_res_len_para,BX	; we read (soon) this many
	PUSH	BX
	MOV	CL,4
	SHL	BX,CL			; get count in bytes from paras
	MOV	CX,BX			; count in correct register
	PUSH	DS
	MOV	DS,exec_dma		; Set up read buffer
	ASSUME	DS:NOTHING
	XOR	DX,DX
	PUSH	CX			; save our count
	CALL	ExecRead
	POP	CX			; get old count to verify
	POP	DS
	JC	exec_bad_fileJ
	DOSAssume   CS,<DS>,"EXEC/exec_read_ok"
	CMP	CX,AX			; did we read enough?
	POP	BX			; get paragraph count back
	JZ	execCheckEnd		; and do reloc if no more to read
;
; The read did not match the request.  If we are off by 512 bytes or more
; then the header lied and we have an error.
;
	SUB	CX,AX
	CMP	CX,512
	JAE	Exec_Bad_fileJ
;
; We've read in CX bytes... bump DTA location
;
ExecCheckEnd:
	ADD	exec_dma,BX		; bump dma address
	TEST	exec_res_len_para,-1
	JNZ	exec_big_read
;
; The image has now been read in.  We must perform relocation to
; the current location.
;
exec_do_reloc:
	MOV	CX,exec_rel_fac
	MOV	AX,exec_SS		; get initial SS
	ADD	AX,CX			; and relocate him
	MOV	exec_init_SS,AX

	MOV	AX,exec_SP		; initial SP
	MOV	exec_init_SP,AX

	LES	AX,DWORD PTR exec_IP
	MOV	exec_init_IP,AX
	MOV	AX,ES
	ADD	AX,CX			; relocated...
	MOV	exec_init_CS,AX

	XOR	CX,CX
	MOV	DX,exec_rle_table
	MOV	BX,exec_fh
	PUSH	DS
	XOR	AX,AX
	invoke	$LSEEK
	POP	DS

	JNC	exec_get_entries
exec_bad_filej:
	JMP	exec_bad_file

exec_get_entries:
	MOV	DX,exec_rle_count	; Number of entries left

exec_read_reloc:
	ASSUME	DS:NOTHING
	PUSH	DX
	MOV	DX,OFFSET DOSGROUP:exec_internal_buffer
	MOV	CX,((exec_internal_buffer_size)/4)*4
	PUSH	DS
	CALL	ExecRead
	POP	ES
	POP	DX
	JC	exec_bad_filej
	MOV	CX,(exec_internal_buffer_size)/4
	MOV	DI,OFFSET DOSGROUP:exec_internal_buffer ; Pointer to byte location in header
;
; Relocate a single address
;
	MOV	SI,exec_rel_fac

exec_reloc_one:
	OR	DX,DX			; Any more entries?
	JE	exec_set_PDBJ

exec_get_addr:
	LDS	BX,DWORD PTR ES:[DI]	; Get ra/sa of entry
	MOV	AX,DS			; Relocate address of item
	ADD	AX,SI
	MOV	DS,AX
	ADD	[BX],SI
	ADD	DI,4
	DEC	DX
	LOOP	exec_reloc_one		; End of internal buffer?

;
; We've exhausted a single buffer's worth.  Read in the next piece
; of the relocation table.
;

	PUSH	ES
	POP	DS
	JMP	exec_read_reloc

exec_set_PDBJ:
	JMP	exec_set_PDB

exec_no_memj:
	JMP	exec_no_mem

;
; we have a .COM file.	First, determine if we are merely loading an overlay.
;
exec_com_file:
	TEST	BYTE PTR exec_func,exec_func_overlay
	JZ	exec_alloc_com_file
	LDS	SI,exec_blk		; get arg block
	LODSW				; get load address
	MOV	exec_dma,AX
	MOV	AX,0FFFFh
	JMP	SHORT exec_read_block	; read it all!

; We must allocate the max possible size block (ick!)  and set up
; CS=DS=ES=SS=PDB pointer, IP=100, SP=max size of block.
;
exec_alloc_com_file:
	MOV	BX,0FFFFh
	invoke	$ALLOC			; largest piece available as error
	OR	BX,BX
	JZ	exec_no_memj
	MOV	exec_size,BX		; save size of allocation block
	PUSH	BX
	invoke	$ALLOC			; largest piece available as error
	POP	BX			; get size of block...
	MOV	exec_load_block,AX
	ADD	AX,10h			; increment for header
	MOV	exec_dma,AX
	XOR	AX,AX			; presume 64K read...
	CMP	BX,1000h		; 64k or more in block?
	JAE	exec_read_com		; yes, read only 64k
	MOV	AX,BX			; convert size to bytes
	MOV	CL,4
	SHL	AX,CL
exec_read_com:
	SUB	AX,100h 		; remember size of psp
exec_read_block:
	PUSH	AX			; save number to read
	MOV	BX,exec_fh		; of com file
	XOR	CX,CX			; but seek to 0:0
	MOV	DX,CX
	XOR	AX,AX			; seek relative to beginning
	invoke	$LSEEK			; back to beginning of file
	POP	CX			; number to read
	MOV	DS,exec_dma
	XOR	DX,DX
	PUSH	CX
	CALL	ExecRead
	POP	SI			; get number of bytes to read
	jnc	OkRead
	jmp	exec_bad_file
OkRead:
	CMP	AX,SI			; did we read them all?
	JZ	exec_no_memj		; exactly the wrong number... no memory
	TEST	BYTE PTR exec_func,exec_func_overlay
	JNZ	exec_set_PDB		; no starto, chumo!
	MOV	AX,exec_DMA
	SUB	AX,10h
	MOV	exec_init_CS,AX
	MOV	exec_init_IP,100h	; initial IP is 100
;
; SI is at most FF00h.	Add FE to account for PSP - word of 0 on stack.
;
	ADD	SI,0FEh 		; make room for stack
	MOV	exec_init_SP,SI 	; max value for read is also SP!
	MOV	exec_init_SS,AX
	MOV	DS,AX
	MOV	WORD PTR [SI],0 	; 0 for return

exec_set_PDB:
	MOV	BX,exec_fh		; we are finished with the file.
	CALL	exec_dealloc
	PUSH	BP
	invoke	$CLOSE			; release the jfn
	POP	BP
	CALL	exec_alloc
	TEST	BYTE PTR exec_func,exec_func_overlay
	JZ	exec_build_header
	CALL	Scan_Execname		;MS.;AN007;
	CALL	Scan_Special_Entries	;MS.;AN007;
	Leave
	transfer    SYS_RET_OK		; overlay load -> done

exec_build_header:
	MOV	DX,exec_load_block
;
; assign the space to the process
;

	MOV	SI,arena_owner		; pointer to owner field

	MOV	AX,exec_environ 	; get environ pointer
	OR	AX,AX
	JZ	NO_OWNER		; no environment
	DEC	AX			; point to header
	MOV	DS,AX
	MOV	[SI],DX 		; assign ownership
NO_OWNER:
	MOV	AX,exec_load_block	; get load block pointer
	DEC	AX
	MOV	DS,AX			; point to header
	MOV	[SI],DX 		; assign ownership

	PUSH	DS			;AN000;MS. make ES=DS
	POP	ES			;AN000;MS.
	MOV	DI,ARENA_NAME		;AN000;MS. ES:DI points to destination
	CALL	Scan_Execname		;AN007;MS. parse execname
					;	   ds:si->name, cx=name length
	PUSH	CX			;AN007;;MS. save for fake version
	PUSH	SI			;AN007;;MS. save for fake version

movename:				;AN000;
	LODSB				;AN000;;MS. get char
	CMP	AL,'.'                  ;AN000;;MS. is '.' ,may be name.exe
	JZ	mem_done		;AN000;;MS. no, move to header
					;AN000;
	STOSB				;AN000;;MS. move char
	LOOP	movename		;AN000;;MS. continue
mem_done:				;AN000;
	XOR	AL,AL			;AN000;;MS. make ASCIIZ
	CMP	DI,SIZE ARENA		;AN000;MS. if not all filled
	JAE	fill8			;AN000;MS.
	STOSB				;AN000;MS.
fill8:					;AN000;
	POP    SI			;AN007;MS. ds:si -> file name
	POP    CX			;AN007;MS.

	CALL   Scan_Special_Entries	;AN007;MS.

	PUSH	DX
	MOV	SI,exec_size
	ADD	SI,DX
	invoke	$Dup_PDB		; ES is now PDB
	POP	DX

	PUSH	exec_environ
	POP	ES:[PDB_environ]
;
; set up proper command line stuff
;
	LDS	SI,exec_blk		; get the block
	PUSH	DS			; save its location
	PUSH	SI
	LDS	SI,[SI.exec0_5C_FCB]	; get the 5c fcb
;
; DS points to user space 5C FCB
;
	MOV	CX,12			; copy drive, name and ext
	PUSH	CX
	MOV	DI,5Ch
	MOV	BL,[SI]
	REP	MOVSB
;
; DI = 5Ch + 12 = 5Ch + 0Ch = 68h
;
	XOR	AX,AX			; zero extent, etc for CPM
	STOSW
	STOSW
;
; DI = 5Ch + 12 + 4 = 5Ch + 10h = 6Ch
;
	POP	CX
	POP	SI			; get block
	POP	DS
	PUSH	DS			; save (again)
	PUSH	SI
	LDS	SI,[SI.exec0_6C_FCB]	; get 6C FCB
;
; DS points to user space 6C FCB
;
	MOV	BH,[SI] 		; do same as above
	REP	MOVSB
	STOSW
	STOSW
	POP	SI			; get block (last time)
	POP	DS
	LDS	SI,[SI.exec0_com_line]	; command line
;
; DS points to user space 80 command line
;
	OR	CL,80h
	MOV	DI,CX
	REP	MOVSB			; Wham!
;
; Process BX into default AX (validity of drive specs on args).  We no longer
; care about DS:SI.
;
	DEC	CL			; get 0FFh in CL
	MOV	AL,BH
	XOR	BH,BH
	invoke	GetVisDrv
	JNC	exec_BL
	MOV	BH,CL
exec_BL:
	MOV	AL,BL
	XOR	BL,BL
	invoke	GetVisDrv
	JNC	exec_Set_Return
	MOV	BL,CL
exec_set_return:
	invoke	get_user_stack		; get his return address
	PUSH	[SI.user_CS]		; suck out the CS and IP
	PUSH	[SI.user_IP]
	PUSH	[SI.user_CS]		; suck out the CS and IP
	PUSH	[SI.user_IP]
	POP	WORD PTR ES:[PDB_Exit]
	POP	WORD PTR ES:[PDB_Exit+2]
	XOR	AX,AX
	MOV	DS,AX
	POP	DS:[addr_int_terminate] ; save them where we can get them later
	POP	DS:[addr_int_terminate+2]   ; when the child exits.
	MOV	WORD PTR DMAADD,80h
	MOV	DS,CurrentPDB
	MOV	WORD PTR DMAADD+2,DS
	TEST	BYTE PTR exec_func,exec_func_no_execute
	JZ	exec_go

	LDS	SI,DWORD PTR exec_init_SP   ; get stack
	LES	DI,exec_blk		; and block for return
	MOV	ES:[DI].exec1_SS,DS	; return SS

	DEC	SI			; 'push' default AX
	DEC	SI
	MOV	[SI],BX 		; save default AX reg
	MOV	ES:[DI].exec1_SP,SI	; return 'SP'

	LDS	AX,DWORD PTR exec_init_IP
	MOV	ES:[DI].exec1_CS,DS	; initial entry stuff

	MOV	ES:[DI].exec1_IP,AX
	Leave
	transfer    SYS_RET_OK

exec_go:
	LDS	SI,DWORD PTR exec_init_IP   ; get entry point
	LES	DI,DWORD PTR exec_init_SP   ; new stack
	MOV	AX,ES
;
; DS:SI points to entry point
; AX:DI points to initial stack
; DX has PDB pointer
; BX has initial AX value
;
	CLI
	MOV	BYTE PTR INDOS,0
	ASSUME	SS:NOTHING
	MOV	SS,AX			; set up user's stack
	MOV	SP,DI			; and SP
	STI
	PUSH	DS			; fake long call to entry
	PUSH	SI
	MOV	ES,DX			; set up proper seg registers
	MOV	DS,DX
	MOV	AX,BX			; set up proper AX
procedure   exec_long_ret,FAR

IF	BUFFERFLAG
	invoke	restore_user_map
ENDIF

	RET
EndProc exec_long_ret

EndProc $Exec

Procedure   ExecRead,NEAR
	CALL	exec_dealloc
	MOV	bx,exec_fh
	PUSH	BP
	invoke	$READ
	POP	BP
	CALL	exec_alloc
	return
EndProc ExecRead

procedure   exec_dealloc,near
	ASSUME	    DS:NOTHING,ES:NOTHING
	PUSH	    BX
	MOV	    BX,arena_owner_system
	EnterCrit   CritMEM
	CALL	    ChangeOwners
	POP	    BX
	return
EndProc exec_dealloc

procedure   exec_alloc,near
	PUSH	    BX
	MOV	    BX,CurrentPDB
	CALL	    ChangeOwners
	LeaveCrit   CritMEM
	POP	    BX
	return
EndProc exec_alloc

procedure   ChangeOwners,NEAR
	pushf
	PUSH	AX
	MOV	AX,exec_environ
	CALL	ChangeOwner
	MOV	AX,exec_load_block
	Call	ChangeOwner
	POP	AX
	popf
	return
EndProc ChangeOwners

Procedure   ChangeOwner,near
	OR	AX,AX			; is area allocated?
	retz				; no, do nothing
	DEC	AX
	PUSH	DS
	MOV	DS,AX
	MOV	DS:[arena_owner],BX
	POP	DS
	return
EndProc ChangeOwner

Procedure    Scan_Execname,near 	;AN000;MS.

	LDS	SI,execName		;AN000;MS. DS:SI points to name
save_begin:				;AN000;
	MOV	CX,SI			;AN000;MS. CX= starting addr
scan0:					;AN000;
	LODSB				;AN000;MS. get char
	CMP	AL,':'                  ;AN000;;MS. is ':' , may be A:name
	JZ	save_begin		;AN000;;MS. yes, save si
	CMP	AL,'\'                  ;AN000;;MS. is '\', may be A:\name
	JZ	save_begin		;AN000;;MS. yes, save si
	CMP	AL,0			;AN000;;MS. is end of name
	JNZ	scan0			;AN000;;MS. no, continue scanning
	SUB	SI,CX			;AN000;;MS. get name's length
	XCHG	SI,CX			;AN000;;MS. cx= length, si= starting addr

	return				;AN000;;MS.
EndProc Scan_Execname			;AN000;;MS.


Procedure    Scan_Special_Entries,near	;AN000;MS.

	DEC    CX			;AN007;MS. cx= name length
	MOV    DI,CS:[Special_Entries]	;AN007;MS. es:di -> addr of special entries
	CALL   Reset_Version		;AN008;MS.
	PUSH   CS			;AN007;MS.
	POP    ES			;AN007;MS.
Getentries:				;AN007;MS.
	MOV    AL,ES:[DI]		;AN007;MS. end of list
	OR     AL,AL			;AN007;MS.
	JZ     end_list 		;AN007;MS. yes
	MOV    CS:[Temp_Var2],DI	;AN007;MS. save di
	CMP    AL,CL			;AN007;MS. same length ?
	JNZ    skipone			;AN007;MS. no
	INC    DI			;AN007;MS. es:di -> special name
	PUSH   CX			;AN007;MS. save length and name addr
	PUSH   SI			;AN007;MS.
	REPZ   CMPSB			;AN007;MS. same name ?
	JNZ    not_matched		;AN007;MS. no
	MOV    AX,ES:[DI]		;AN007;MS. get special version
	MOV    CS:[Special_Version],AX	;AN007;MS. save it
	MOV    AL,ES:[DI+2]		;AN008;MS. get fake count
	MOV    CS:[Fake_Count],AL	;AN007;MS. save it
	POP    SI			;AN007;MS.
	POP    CX			;AN007;MS.
	JMP    SHORT end_list		;AN007;MS.
not_matched:				;AN007;MS.
	POP    SI			;AN007;MS. restore si,cx
	POP    CX			;AN007;MS.
skipone:				;AN007;MS.
	MOV    DI,CS:[Temp_Var2]	;AN007;MS. restore old di
	XOR    AH,AH			;AN007;MS. position to next entry
	ADD    DI,AX			;AN007;MS.
	ADD    DI,4			;AN007;MS.
	JMP    Getentries		;AN007;MS.


end_list:				;AN007;MS.
	return
EndProc Scan_Special_Entries		;AN000;;MS.

Procedure    Reset_Version,near 	;AN008;MS.

	CMP    CS:[Fake_Count],0FFH	;AN008;MS.
	JNZ    dont_reset		;AN008;MS.
	MOV    CS:[Special_Version],0	;AN008;MS. reset to current version
dont_reset:
	return
EndProc Reset_Version,near		;AN008;;MS.
