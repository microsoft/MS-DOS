	TITLE	SYS-2-	Program
	include version.inc
	INCLUDE SYSHDR.INC

	page	80,132
	BREAK	<SYS2 - Program Organization>
;******************+ START OF PSEUDOCODE +**************************************
; Ä Ä Ä Ä Ä Ä Ä Ä¿	ÚÄÄÄÄÄÄÄÄÄ¿
; Read_Directory ÃÄÄÄÄÄÄ´Find_DPB ³
; Ä Ä Ä Ä Ä Ä Ä ÄÙ	ÀÄÄÄÄÄÄÄÄÄÙ
; Ä Ä Ä Ä Ä Ä Ä Ä Ä ÄÄ¿
; Verify_File_LocationÃÄ¿
; Ä Ä Ä Ä Ä Ä Ä Ä Ä ÄÄÙ ³
; ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; ³ ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿  Ú Ä Ä Ä Ä Ä Ä ¿
; ÃÄ´Move_DIR_EntryÃÄÄÂ´Find_Empty_Entry ÃÄÄ´Direct_Access³
; ³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  À Ä Ä Ä Ä Ä Ä Ù
; ³		      ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
; ³		      À´Direct_Access³
; ³		       ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; ³  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; ³ ÚÄÄÄÄÄÄÄÄÄÄÄÄ¿     ÚÄÄÄÄÄÄÄÄÄÄÄ¿	    ÚÄÄÄÄÄÄÄ¿
; ÀÄ´Free_ClusterÃÄÄÄÄÂ´Is_It_EmptyÃÄÄÄÄÄÄÄÄ´Unpack ³
;   ÀÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³ÀÄÄÄÄÄÄÄÄÄÄÄÙ	    ÀÄÄÄÄÄÄÄÙ
;		      ³ÚÄÄÄÄÄÄÄÄÄÄ¿	    Ú Ä Ä Ä ¿
;		      Ã´Search_FATÃÄÄÄÄÄÄÄÄÂ´Unpack ³
;		      ³ÀÄÄÄÄÄÄÄÄÄÄÙ	   ³À Ä Ä Ä Ù
;		      ³ 		   ³ÚÄÄÄÄÄÄ¿
;		      ³ 		   Ã´Pack  ³
;		      ³ 		   ³ÀÄÄÄÄÄÄÙ
;		      ³ 		   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿  Ú Ä Ä Ä ¿
;		      ³ 		   Ã´Find_Empty_Cluster³ÄÄ´Unpack ³
;		      ³ 		   ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  À Ä Ä Ä Ù
;		      ³ 		   ³ÚÄÄÄÄÄÄÄÄÄ¿ 	  Ú Ä Ä Ä Ä Ä Ä ¿
;		      ³ 		   Ã´Xfer_DataÃÄÄÄÄÄÄÄÄÄÄÄ´Direct_Access³
;		      ³ 		   ³ÀÄÄÄÄÄÄÄÄÄÙ 	  À Ä Ä Ä Ä Ä Ä Ù
;		      ³ 		   ³Ú Ä Ä Ä Ä Ä Ä ¿
;	ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÙ 		   À´Direct_Access³
;	³				    À Ä Ä Ä Ä Ä Ä Ù
;	³ÚÄÄÄÄÄÄÄÄÄÄ¿	 ÚÄÄÄÄÄÄÄÄÄÄÄ¿	    Ú Ä Ä Ä ¿
;	À´Search_DIRÃÄÄÄÄ´Search_LoopÃÄÄÄÄÄÂ´Unpack ³
;	 ÀÄÄÄÄÄÄÄÄÄÄÙ	 ÀÄÄÄÄÄÄÄÄÄÄÄÙ	   ³À Ä Ä Ä Ù
;					   ³ÚÄÄÄÄÄÄ¿
;					   Ã´Pack  ³				     Direct_Access
;					   ³ÀÄÄÄÄÄÄÙ
;					   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿  Ú Ä Ä Ä ¿
;					   Ã´Find_Empty_Cluster³ÄÄ´Unpack ³
;					   ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  À Ä Ä Ä Ù
;					   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄ¿  Ú Ä Ä Ä ¿
;					   Ã´Sub_DIR_Loop³ÄÄ´Unpack ³
;					   ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÙ  À Ä Ä Ä Ù
;					   ³ÚÄÄÄÄÄÄÄÄÄ¿ 	  Ú Ä Ä Ä Ä Ä Ä ¿
;					   Ã´Xfer_DataÃÄÄÄÄÄÄÄÄÄÄÄ´Direct_Access³
;					   ³ÀÄÄÄÄÄÄÄÄÄÙ 	  À Ä Ä Ä Ä Ä Ä Ù
;					   ³Ú Ä Ä Ä Ä Ä Ä ¿
;					   À´Direct_Access³
;					    À Ä Ä Ä Ä Ä Ä Ù
;
;******************+ END OF PSEUDOCODE +*****************************************
	BREAK	<SYS2 - Data space>

	DATA	SEGMENT PARA PUBLIC

	extrn	TargDrvNum:BYTE, TargSpec:WORD, bio_owns_it:BYTE, DOS_VER:BYTE
	extrn	packet_sectors:WORD, packet_buffer:WORD, packet:WORD

	public	THIS_DPB, BUF, DIR_SECTOR, first_dir_sector


;			$SALUT (4,25,30,41)

first_dir_sector	dw   ?
current_dir_sector	dw   ?
last_dir_sector 	dw   ?
entries_per_sector	db   ?
current_entry		db   3
source_ptr		dw   ?
ibmbio_status		db   ?
ibmdos_status		db   ?
FAT_sectors		dw   FAT_sect_size ; initailize it to 12 sectors
FAT_changed		db   0		; FAT must be written - its packed
FAT_2			db   0		; if non zero, [packet] points at FAT 2
cluster_count		dw   ?		; number of clusters that must be free
last_cluster		dw   0		; cluster pointing to [current_cluster]
current_cluster 	dw   2		; start at cluster 2
next_cluster		dw   0		; cluster [current_cluster] points at
empty_cluster		dw   0		; newly aquired cluster
cluster_low		dw   0
cluster_high		dw   clusters_loaded

l_sector_offset 	dw   ?		; this is the value required to convert
					;  a sector from a cluster # to a
					;  logical sector # for INT 25 & 26

DIR_cluster		dw   0		; Sub DIR cluster being processed
					;  = 0 - not processing s Sub DIR
					;  = 1 - starting to process
					;	 (set by Search_Loop)
					;  = n - Sub DIR cluster now being
					;	 processed. (set by Xfer_Data)
present_cluster 	dw   ?		; current cluster for DIR search
sector_offset		dw   ?		; current sector in present_cluster
entry_number		db   ?		; DIR entry in current sector
FRAME_ptr		dw   ?
dir_sector_low		dw   ?
dir_sector_hi		dw   ?
DIR_offset		dw   ?
sector_count		db   1

FRAME			STRUC

p_cluster		dw   ?		; current cluster for DIR search
s_offset		dw   ?		; current sector in present_cluster
e_number		db   ?		; DIR entry in current sector

FRAME			ENDS

BIGFAT			DB   0		;0=12 bit FAT, NZ=16bit FAT
EOFVAL			DW   0FF8H	;0FF8 for 12 bit FAT,0FFF8 for 16 bit
BADVAL			DW   0FF7H	;0FF7 for 12 bit FAT,0FFF7 for 16 bit

THIS_DPB		DD   ?		;Pointer to drive DPB
CSIZE			DW   ?		;Sectors per cluster
SSIZE			DW   ?		;bytes per sector
DSIZE			DW   ?		;# alloc units on disk
FSIZE			DW   ?		;# sectors in 1 FAT
first_FAT		DW   ?		; first cluster of first FAT
num_of_FATS		db   ?		; number of FATS
MCLUS			DW   ?		;DSIZE + 1
;
; The following is used as the source/destination for a name trans
;
ENTRY_BUF		DB   size dir_entry DUP (?)
DIR_BUF 		DB   ( 34 * size frame) DUP (?) ; space for DIR frames - see Search_DIR
DIR_SECTOR		DB   512 DUP (?) ; space for 1 DIR sector

BUF			LABEL BYTE	; beginning of area for file reads

			DATA ENDS

;  $SALUT (4,4,9,41)

   CODE SEGMENT PARA PUBLIC

   ASSUME cs:CODE, ds:nothing, es:nothing

   BREAK <SYS - Find_DPB >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name:	Find_DPB
;*******************************************************************************
;
;Description:	Find_DPB gets the pointer to the Target DPB and initializes all
;		local valiables required by Move_DIR_Entry and Free_Cluster.
;
;NOTE:		This routine contains code that is specific for DOS 3.3.  It
;		must be removed for subsequent releases.  In and before
;		DOS 3.3 the DPB was one byte smaller.  The field dpb_FAT_size
;		was changed from a byte to a word in DOS 4.00.
;
;
;Entry: 	Called by Verify_File_Location
;
;Called Procedures:
;
;		INT 21 - 32h
;
;Input: 	al = Drive number
;
;Output:	All local variables initalized
;		DS:BX = pointer to DPB
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Find_DPB
;
;	get DPB pointer (INT 21 - 32h)
;	initalize first_dir_sector
;	initalize current_dir_sector
;	initalize current_cluster (0 for root)
;	calculate # of clusters required by IBMBIO
;	initalize [cluster_count]
;	calculate # of dir sectors
;	initalize [dir_sectors]
;	initalize [current_entry] to #3
;	allocate memory for FAT + 32 DIR frames
;	allocate memory for data sectors
;
;	ret
;
;	END Find_DPB
;
;******************-  END  OF PSEUDOCODE -**************************************


   PUBLIC Find_DPB

   Find_DPB PROC NEAR

   MOV	AH,GET_DPB			;Get the DPB			       ;AN004;
   INT	21H

   mov	ax,(disk_reset shl 8)		; reset the disk to protect all INT 26's
   INT	21h				;   that follow


					; initalize current_entry to #3

   ASSUME ds:nothing,es:DATA

   MOV	WORD PTR [THIS_DPB+2],DS	;				       ;AN004;
   push es				;				       ;AN004;
   pop	ds				;				       ;AN004;

   ASSUME ds:DATA

   mov	WORD PTR [THIS_DPB],bx		;				       ;AN004;
   lds	bx,[THIS_DPB]			;				       ;AN004;

   ASSUME ds:nothing

   mov	ax,[bx.dpb_sector_size] 	;				       ;AN004;
   mov	[SSIZE],ax			;Sector size in bytes		       ;AN004;

   xor	ax,ax				;				       ;AN004;
   mov	al,[bx.dpb_cluster_mask]	;				       ;AN004;
   inc	al				;				       ;AN004;
   mov	[CSIZE],ax			;Sectros per cluster		       ;AN004;

   mov	ax,[BX.dpb_first_FAT]		;First sector of FAT		       ;AN004;
   mov	[first_FAT],ax			;				       ;AN004;

   mov	al,[BX.dpb_FAT_count]		;Number of FATs 		       ;AN004;
   mov	[num_of_FATS],al		;				       ;AN004;

   mov	ax,[bx.dpb_max_cluster] 	;				       ;AN004;
   mov	[MCLUS],ax			;Bound for FAT searching	       ;AN004;

   cmp	ax,4096-10			;Big or little FAT?		       ;AN004;
;  $if	ae				;				       ;AN004;
   JNAE $$IF1
       inc  [BIGFAT]			;				       ;AN004;
       mov  [EOFVAL],0FFF8h		;				       ;AN004;
       mov  [BADVAL],0FFF7h		;				       ;AN004;
;  $endif				;				       ;AN004;
$$IF1:
   dec	ax				;				       ;AN004;
   mov	[DSIZE],ax			;Total data clusters on disk	       ;AN004;

					;--------------------------------------
					; calculate # of dir sectors and
					;    initalize last_dir_sector
					;--------------------------------------
   mov	ax,[bx.dpb_root_entries]	; max # of entries in the root	       ;AN004;
   mov	cx,size dir_entry		; size of each entry		       ;AN004;
   mul	cx				; size of root directory in bytes      ;AN004;
					; in AX:DX			       ;AN004;
   mov	cx,[SSIZE]			; # of bytes per sector 	       ;AN004;
   div	cx				; = # of root directory sectors        ;AN004;
   cmp	dx,0				; any remainder ?		       ;AN004;
;  $if	nz				;				       ;AN004;
   JZ $$IF3
       inc  ax				;				       ;AN004;
;  $endif				;				       ;AN004;
$$IF3:
   mov	[first_dir_sector],ax		; save for last directory sector calc. ;AN004;

   mov	ax,[bx.dpb_FAT_size]		;Sectors for one fat		       ;AN004;
   cmp	DOS_VER,0			; running on current version?	       ;AN019;

;  $if	ne				; BANG! - we'er running on DOS 3.3     ;AN019;
   JE $$IF5
					;	  dpb_FAT_size is only a BYTE
					;	  so ajust it to a word
       xor  ah,ah							       ;AN019;
       dec  bx				; BACK UP the index into the DPB       ;AN019;
       mov  WORD PTR [THIS_DPB],bx	;   save it for later (dpb_next_free)  ;AN021;
					; Now  everything else lines up !
;  $endif
$$IF5:

   mov	[FSIZE],ax			;				       ;AN004;

   mov	ax,[SSIZE]			;				       ;AN004;
   mov	cx,SIZE dir_entry		;				       ;AN004;
   div	cx				;				       ;AN004;
   dec	ax				; first entry number is zero	       ;AN004;
   mov	[entries_per_sector],al 	;				       ;AN004;
   cmp	[BIGFAT],0			; is it a big fat ?		       ;AN004;

;  $if	e				; if not			       ;AN004;
   JNE $$IF7
       mov  ax,[FSIZE]			;				       ;AN004;
       mov  [FAT_sectors],ax		; bring it down to the actual size     ;AN004;
;  $endif				;				       ;AN004;
$$IF7:
					;--------------------------------------
					; initalize first_dir_sector
					;	and current_dir_sector
					;--------------------------------------
   mov	ax,[bx.dpb_dir_sector]		; first dir sector		       ;AN004;
   mov	[current_dir_sector],ax 	; save it for later		       ;AN004;
   xchg [first_dir_sector],ax		; save it and recover # of dir sectors ;AN004;

   add	ax,[first_dir_sector]		; # of last directory sector	       ;AN004;
   mov	[l_sector_offset],ax		;				       ;AN004;
   dec	ax				;				       ;AN004;
   mov	[last_dir_sector],ax		; save it for later		       ;AN004;

   ret					;				       ;AN004;

   Find_DPB ENDP

   BREAK <SYS - Move_DIR_Entry >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Move_DIR_Entry
;*******************************************************************************
;
;Description:	Move_DIR_Entry will move the entry pointed to by the caller into
;		the first available location in the root, if one exists.
;
;Entry: 	Called by Verify_File_Location
;
;Called Procedures:
;
;		Find_Empty_Entry - find an available entry
;		Direct_Access	 - do an INT 25 & INT 26
;
;Input: 	first_dir_sector
;		current_dir_sector
;		last_dir_sector
;		current_entry
;		pointer set to source entry to be moved
;
;Output:	CF = 0 - DIR entry moved to first available entry
;		CF = 1 - Error, not able to free up entry
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Move_DIR_Entry
;
;	set dest = entry_buffer
;	save source pointer
;	copy input entry to buffer
;	if no error and
;	call Find_Empty_Entry to find hole in directory
;	if no error
;		set source to entry_buffer
;		set dest to hole pointer
;		copy buffer to enpty entry
;		if first_dir_sector != current_dir_sector
;		set up for write
;		call Direct_Access to write it out
;			if no error
;				set up for first_dir_sector
;				set up for read
;				call Direct_Access to read it in
;			endif
;		if no error
;			recover source pointer
;			null out entry being processed
;			set up for write
;			call Direct_Access to update the root
;		endif
;	endif
;
;	ret
;
;	END   Move_DIR_Entry
;
;******************-  END  OF PSEUDOCODE -**************************************


   PUBLIC Move_DIR_Entry

   Move_DIR_Entry PROC NEAR

   ASSUME ds:DATA			;  must ensure this is true xxxxxxxxxxxxxxxxx

					; source = source entry (#1 or #2) DS:SI
   lea	di,ENTRY_BUF			; dest	 = entry_buffer 	       ;AN004;
   mov	[source_ptr],si 		; save source pointer		       ;AN004;
   mov	ax,size dir_entry		;				       ;AN004;
   mov	cx,ax				;				       ;AN004;
   rep	movsb				; copy directory entry into entry buffer;AN004;
   lea	si,DIR_SECTOR			; start at beginning of directory      ;AN004;
   mov	di,si				; save start for end calculation       ;AN004;
   shl	ax,1				; set pointer for current entry to #3  ;AN004;
   add	ax,si				;				       ;AN004;
   mov	si,ax				;				       ;AN004;
   add	di,[SSIZE]			; calculate end of directory	       ;AN004;
   call Find_Empty_Entry		; find hole in directory	       ;AN004;
;  $if	nc				; if no error and		       ;AN004;
   JC $$IF9
       mov  di,si			; dest	 = hole pointer 	       ;AN004;
       lea  si,ENTRY_BUF		; source = entry_buffer 	       ;AN004;
       mov  cx,size dir_entry		;				       ;AN004;
       rep  movsb			; copy buffer to DTA		       ;AN004;
       mov  ax,[first_dir_sector]	;				       ;AN004;
       cmp  ax,[current_dir_sector]	;				       ;AN004;
;      $if  ne				; if first_dir_sector != current_dir_sector;AN004;
       JE $$IF10
	   mov	ah,-1			; set up for write		       ;AN004;
	   call Direct_Access		; write it out			       ;AN004;
;	   $if	nc			; if no error			       ;AN004;
	   JC $$IF11
	       mov  ax,[first_dir_sector] ; set up for first_dir_sector        ;AN004;
	       mov  [current_dir_sector],ax ; update current_dir_sector        ;AN004;
	       mov  [packet],ax 	;				       ;AN004;
	       xor  ah,ah		; set up for read		       ;AN004;
	       call Direct_Access	; read it in			       ;AN004;
;	   $endif			;				       ;AN004;
$$IF11:
;      $endif				;				       ;AN004;
$$IF10:
;      $if  nc				; if no error			       ;AN004;
       JC $$IF14
	   mov	si,[source_ptr] 	; recover source pointer	       ;AN004;
	   mov	BYTE PTR [si],deleted	; delete entry being processed	       ;AN004;
	   mov	BYTE PTR [si.dir_first],0 ; null out cluster #		       ;AN004;
	   cmp	si,offset DIR_SECTOR	;  are we at the first entry ?	       ;AN010;
;	   $if	e,and			; if so -			       ;AN010;
	   JNE $$IF15
	   cmp	BYTE PTR [si + size DIR_ENTRY],0 ; is second one a null entry? ;AN010;
;	   $if	e			; if so -			       ;AN010;
	   JNE $$IF15
	       mov  BYTE PTR [si + size DIR_ENTRY],deleted ; make it deleted   ;AN010;
;	   $endif			;				       ;AN010;
$$IF15:
	   mov	ah,-1			; set up for write		       ;AN004;
	   call Direct_Access		; write it out			       ;AN004;
;      $endif				;				       ;AN004;
$$IF14:
;  $endif				;				       ;AN004;
$$IF9:

   ret					;				       ;AN004;

   Move_DIR_Entry ENDP

   BREAK <SYS - Find_Empty_Entry >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Find_Empty_Entry
;*******************************************************************************
;
;Description:	Find_Empty_Entry scans all root directory sectors looking for
;		an empty entry.
;
; NOTE; 	It is assumed that each DIRectory entry is 32 bytes long
;
;Called Procedures:
;
;		Direct_Acces - do INT 25
;
;Input: 	current_dir_sector
;		last_dir_sector
;		first_dir_sector in DTA buffer
;		DS:SI set for first entry to check
;		DS:DI set to end of directory (sector)
;
;Output:	success 	pointer set to hole
;		CF = 0		current_entry updated
;				current_dir_sector updated
;
;		fail		message # set
;		CF = 1
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Find_Empty_Entry
;
;	search all available sectors
;		search for hole  (leaves pointer set to the hole)
;		leave if empty
;		leave if deleted
;		advace to next entry
;		exitif past end of sector
;			set carry
;		orelse
;		endloop
;			clear carry
;			save current_entry
;		endsrch
;	exitif hole found (no CF)
;		update current_entry
;	orelse
;		if not at end (current <= last)
;			set for read
;			call Direct_Access to read in next sector
;		else
;			load error message (no room for system files)
;			set error (CF)
;		endif
;	leave if error (CF)
;			update current_DIR_sector
;			update current_entry
;		endif
;	endloop
;	endsrch
;
;	ret
;
;	END  Find_Empty_Entry
;
;******************-  END  OF PSEUDOCODE -**************************************

   PUBLIC Find_Empty_Entry

   Find_Empty_Entry PROC NEAR

;  $search				; for sectors available 	       ;AN004;
$$DO19:
					;				       ;AN004;
;      $search				; for hole - this leaves pointer set at;AN004;
$$DO20:
					; the hole			       ;AN004;
	   cmp	BYTE PTR [si],empty	; empty   ?			       ;AN004;
;      $leave e 			;				       ;AN004;
       JE $$EN20
	   cmp	BYTE PTR [si],deleted	; deleted ?			       ;AN004;
;      $leave e 			;				       ;AN004;
       JE $$EN20
	   add	ax,size dir_entry	; advace to next entry		       ;AN004;
	   mov	si,ax			;				       ;AN004;
	   cmp	ax,di			; past end of sector ?		       ;AN004;
;      $exitif ae			; at end			       ;AN004;
       JNAE $$IF20
	   stc				; set carry			       ;AN004;
;      $orelse				;				       ;AN004;
       JMP SHORT $$SR20
$$IF20:
;      $endloop 			;				       ;AN004;
       JMP SHORT $$DO20
$$EN20:
	   clc				; clear carry			       ;AN004;
;      $endsrch 			;				       ;AN004;
$$SR20:
;  $exitif nc				; hole is found 		       ;AN004;
   JC $$IF19
;  $orelse				;				       ;AN004;
   JMP SHORT $$SR19
$$IF19:
       inc  [current_dir_sector]	; advance to next sector	       ;AN004;
       mov  ax,[current_dir_sector]	;				       ;AN004;
       cmp  ax,[last_dir_sector]	; past last_dir_sector ?	       ;AN004;
;  $leave a				; if at end (current <= last)	       ;AN004;
   JA $$EN19
       lea  si,DIR_SECTOR		; start at start of next sector        ;AN004;
       mov  [packet],ax 		;				       ;AN004;
       xor  ah,ah			; set for read			       ;AN004;
       call Direct_Access		; read in next sector		       ;AN004;
;      $if  c				; if error			       ;AN004;
       JNC $$IF30
	   dec	[current_dir_sector]	; restore curren_dir_sector	       ;AN004;
;      $endif				;				       ;AN004;
$$IF30:
;  $leave c				; error 			       ;AN004;
   JC $$EN19
       mov  ax,si			; reset pointer to start	       ;AN004;
;  $endloop a				; past last_dir_sector		       ;AN004;
   JNA $$DO19
$$EN19:
       mov  ax,(util shl 8) + no_room	; set message# and class	       ;AN004;
       stc				; ensure carry still set	       ;AN004;
;  $endsrch				;				       ;AN004;
$$SR19:

   ret					;				       ;AN004;

   Find_Empty_Entry ENDP



   BREAK <SYS - Direct_Access >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Direct_Access
;*******************************************************************************
;
;Description:  Direct_Access
;
;Called Procedures:
;
;		INT 25
;		INT 26
;
;Input:       ah = 0  - read
;	      ah = -1 - write
;
;Output:      CF = 0 - Sectors moved
;	      CF = 1 - Message and class in AX
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Direct_Access
;
;	save registers
;	if read
;		INT 25
;	else
;		zero ah
;		INT 26
;	endif
;	save return flag
;	clear stack
;	if error
;	       set message# and class
;	endif
;	restore registers
;
;	ret
;
;	END  Direct_Access
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Direct_Access

   Direct_Access PROC NEAR

   push si				; save registers		       ;AN004;
   push bp				; save registers		       ;AN004;
   cmp	DOS_VER,0			;				       ;AN019;

;  $if	e				;				       ;AN019;
   JNE $$IF35

       mov  cx,-1			; set up for INT		       ;AN004;
       mov  bx,offset packet		;				       ;AN004;

;  $else				;				       ;AN019;
   JMP SHORT $$EN35
$$IF35:
					; If running on DOS 3.3 the INT 25
					; interface is:
					;	al = drive number
					;	bx = buffer for read data
					;	cx = # of sectors
					;	dx = start sector
       mov  cx,word ptr [packet_sectors] ;				       ;AN019;
       mov  dx,[packet] 		; get starting dir sector	       ;AN019;
       mov  bx,PACKET_BUFFER[0] 	;				       ;AN019;

;  $endif				;				       ;AN019;
$$EN35:

   mov	al,TargDrvNum			; set up drive number		       ;AN004;
   dec	al				;				       ;AN004;
   cmp	ah,0				;				       ;AN004;
;  $if	e				; if read			       ;AN004;
   JNE $$IF38
       INT  25h 			; INT 25			       ;AN004;
;  $else				; else				       ;AN004;
   JMP SHORT $$EN38
$$IF38:
       xor  ah,ah			; zero ah			       ;AN004;
       INT  26h 			; INT 26			       ;AN004;
;  $endif				; endif 			       ;AN004;
$$EN38:
;; ?					; save return flag		       ;AN004;
   pop	ax				; clear stack			       ;AN004;
   pop	bp				;				       ;AN004;
   pop	si				;				       ;AN004;

   ret					;				       ;AN004;

   Direct_Access ENDP

   BREAK <SYS - Free_Cluster >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name:	Free_Cluster processor
;*******************************************************************************
;
;Description: IBMBIO MUST have at lease cluster 2 as its first cluster. This
;	      routine ensures that cluster 2 and any additional clusters (if
;	      needed) ARE available. If they are chained, their data is copied
;	      into the first available cluster, and the needed cluster is
;	      is replaced by this cluster in the FAT
;
;Entry:       Called by Verify_File_Location
;
;Called Procedures:
;
;	      Is_It_Empty - see if Cluster is empty
;	      Search_FAT  - scan FAT to see if the cluster is chained
;	      Search_DIR  - use FAT to walk directories looking for the cluster
;
;	NOTES: Check_FAT and Check_DIR will do the processing requred to move
;	       data out of the cluster and fix up the FAT and the Dir (if needed).
;
;Input:       All local DBP values initalized by Get_DPB
;
;Ouput:       CF = 0  -  Cluster available
;	      CF = 1  -  Cluster not available
;
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Free_Cluster
;
;	initialize [cluster_count]
;	do until all copies of FAT attempted
;		load FAT into memory (INT 25)
;	leave if successful
;	enddo
;	do until [cluster_count] = 0
;		call Is_It_Empty
;		if not found and
;		if no errors and
;		call Search_FAT
;		if not found and
;		if no errors
;			call Search_DIR
;		endif
;	leave if error
;	enddo
;
;	ret
;
;	END Free_Cluster
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Free_Cluster

   Free_Cluster PROC NEAR

   mov	ax,IBMLOADSIZE			; calculate # of clusters reqd	       ;AN004;
   xor	cx,cx				;				       ;AN004;
   mov	di,cx				;				       ;AN004;
   dec	di				;				       ;AN004;
   mov	cx,[CSIZE]			;   by IBMLOAD (consecutive clusters   ;AN004;
   div	cl				;   for IBMBIO) 		       ;AN004;
   cmp	ah,0				;				       ;AN004;
;  $if	ne				;				       ;AN004;
   JE $$IF41
       inc  al				;				       ;AN004;
       xor  ah,ah			;				       ;AN004;
;  $endif				;				       ;AN004;
$$IF41:
   inc	ax				; will be decrimenter immediately upon ;AN004;
					;   entering complex do below
   mov	[cluster_count],ax		; save for later		       ;AN004;
   mov	ax,[FAT_sectors]		;only read needed sectors	       ;AN004;
   mov	[packet_sectors],ax		;				       ;AN004;
   mov	cl,[num_of_FATS]		;Number of FATs 		       ;AN004;
   mov	ax,[first_FAT]			;First sector of FAT		       ;AN004;
   mov	[packet],ax			;				       ;AN004;
   mov	[packet_buffer],OFFSET BUF	; point to FAT buffer		       ;AN004;
   call Load_FAT			;				       ;AN004;
;  $if	nc				; no error so far.......	       ;AN004;
   JC $$IF43
;      $do  complex			;				       ;AN004;
       JMP SHORT $$SD44
$$DO44:
	   mov	[cluster_count],cx	;				       ;AN004;
	   call Is_It_Empty		;				       ;AN004;
;      $leave c 			;				       ;AN014;
       JC $$EN44
	   cmp	al,not_found		; ( -1 ?)			       ;AN004;
;	   $if	e			; if not found			       ;AN004;
	   JNE $$IF46
	       call Search_FAT		; scan FAT to see if cluster chained   ;AN004;
;	   $else			;				       ;AN004;
	   JMP SHORT $$EN46
$$IF46:
	       clc			;				       ;AN004;
;	   $endif			;				       ;AN004;
$$EN46:
;      $leave c 			;				       ;AN004;
       JC $$EN44
	   cmp	al,not_found		; if still not found		       ;AN004;
;	   $if	e			;				       ;AN004;
	   JNE $$IF50
	       call Search_DIR		; scan DIR to see who starts with #2   ;AN004;
;	   $else			;				       ;AC013;
	   JMP SHORT $$EN50
$$IF50:
	       clc			; ensure carry is still clear	       ;AC013;
;	   $endif			;				       ;AN004;
$$EN50:
;      $leave c 			;				       ;AN004;
       JC $$EN44
	   inc	[current_cluster]	;				       ;AN004;
;      $strtdo				;				       ;AN004;
$$SD44:
	   mov	cx,[cluster_count]	;				       ;AN004;
;      $enddo LOOP			;				       ;AN004;
       LOOP $$DO44
$$EN44:
;  $endif				;				       ;AN004;
$$IF43:
;  $if	c				;				       ;AN004;
   JNC $$IF57
       mov  ax,(util shl 8) + no_room	; error message - no room to sys       ;AN014;
;  $endif				;				       ;AN004;
$$IF57:

   ret					;				       ;AN004;

   Free_Cluster ENDP

   public Load_FAT

   Load_FAT PROC NEAR

   lea	bx,[packet]			;				       ;AN004;

;  $search				;				       ;AN004;
$$DO59:
       xchg cx,di			;				       ;AN004;
       push cx				;				       ;AN004;
       push di				;				       ;AN004;
       push dx				;				       ;AN004;
       push bx				;				       ;AN004;
       xor  ah,ah			;				       ;AN004;
       mov  al,TargDrvNum		; set up drive number		       ;AN004;
       dec  al				;				       ;AN004;
       cmp  DOS_VER,0			; if DOS 3.3			       ;AN019;

;      $if  ne				; load registers for old style INT 25  ;AN019;
       JE $$IF60
	   mov	bx,[packet_buffer]	;				       ;AN019;
	   mov	cx,[packet_sectors]	;				       ;AN019;
	   mov	dx,[packet]		;				       ;AN019;
;      $endif				;				       ;AN019;
$$IF60:

       push bp				;				       ;AN019;
       int  25h 			;Read in the FAT		       ;AN004;
       pop  ax				;Flags				       ;AN004;
       pop  bp				;				       ;AN019;
;  $exitif nc				; error - set up for next fat	       ;AN004;
   JC $$IF59
       add  sp,8			;Clean up stack 		       ;AN004;
       mov  ax,1			;				       ;AN004;
;	mov [packet],ax ; reset to first FAT				       ;AN004;
;  $orelse				;				       ;AN004;
   JMP SHORT $$SR59
$$IF59:
       pop  bx				;				       ;AN004;
       pop  dx				;				       ;AN004;
       pop  cx				;				       ;AN004;
       pop  di				;				       ;AN004;
       add  [packet],dx 		; point to start of next FAT	       ;AN004;
       inc  [FAT_2]			;				       ;AN004;
;  $endloop LOOP			;Try next FAT			       ;AN004;
   LOOP $$DO59
       mov  ax,(util shl 8) + no_room	; set message# and class	       ;AN004;
;  $endsrch				;				       ;AN004;
$$SR59:

   ret

   Load_FAT ENDP


   BREAK <SYS - Is_It_Empty >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Is_It_Empty
;*******************************************************************************
;
;Description: Is_It_Empty looks directly into the FAT to see if a specified
;	      cluster is allocated.
;
;Entry:       Called by Free_Cluster
;
;Called Procedures:
;
;	      Unpack - unpack a FAT cluster number (CF set on error)
;
;Input:       CX = cluster to check
;	      12 sectors of FAT in BUF
;
;Output:      CF = 0   AL = 0  - cluster 2 found empty
;		       AL =-1  - not found & no error
;	      CF = 1   - critical error
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Is_It_Empty
;
;	set up for call to Unpack
;	set cluster # to [cluster_number]
;	call Unpack
;	if no error
;		if cluster is not empty
;			if bad cluster
;				set error flag
;			else
;				if cluster belongs to IBMBIO
;					if next cluster is not contiguous
;						 reset ownership flag
;					endif
;					set cluster empty (ax = 0)
;				else
;					save cluster number
;					set cluster used (ax = -1)
;				endif
;		else
;			set cluster empty (ax = 0)
;		endif
;	endif
;
;	ret
;
;	END Is_It_Empty
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Is_It_Empty

   Is_It_Empty PROC NEAR

   mov	si,[current_cluster]		; set up for call to Unpack	       ;AN004;
   call Unpack				; to find the value		       ;AN004;
;  $if	nc				; if no error			       ;AN004;
   JC $$IF66
;      $if  nz				; cluster is not empty		       ;AN004;
       JZ $$IF67
	   mov	ax,di			;				       ;AN004;
	   cmp	al,bad_sector		;				       ;AN004;
;	   $if	e			;				       ;AN004;
	   JNE $$IF68
	       stc			;				       ;AN004;
;	   $else			;				       ;AN004;
	   JMP SHORT $$EN68
$$IF68:
	       cmp  [bio_owns_it],0	; is it owned by IBMBIO ?	       ;AN004;
;	       $if  ne			; if it is			       ;AN004;
	       JE $$IF70
		   dec	ax		;				       ;AN004;
		   cmp	ax,[current_cluster] ;				       ;AN004;
;		   $if	ne		;				       ;AC011;
		   JE $$IF71
		       dec  [bio_owns_it] ; its not the owner form here on     ;AC011;
;		   $endif		;				       ;AC011;
$$IF71:
		   xor	ax,ax		;				       ;AN004;
		   clc			; its IBMBIO's anyway                  ;AC011;
;	       $else			;				       ;AN004;
	       JMP SHORT $$EN70
$$IF70:
		   mov	[next_cluster],di ;				       ;AN004;
		   xor	ax,ax		; reset fail flag		       ;AN004;
		   dec	ax		;  - its not empty		       ;AN014;
;	       $endif			;				       ;AN004;
$$EN70:
;	   $endif			;				       ;AN004;
$$EN68:
;      $else				; its empty !			       ;AN005;
       JMP SHORT $$EN67
$$IF67:
	   xor	ax,ax			; its empty - and no error	       ;AN014;
;      $endif				;				       ;AN014;
$$EN67:
;  $endif				;				       ;AN004;
$$IF66:

   ret					;				       ;AN004;

   Is_It_Empty ENDP

   BREAK <SYS - Search_FAT >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Search_FAT
;*******************************************************************************
;
;Description: Search_FAT for a [cluster_number]. If it is listed in the FAT,
;	      then its chained into a file. The data in the [cluster_number] is
;	      then buffered, and copied into an empty cluster, and the FAT is
;	      updated
;
;Called Procedures:
;
;		Unpack		   - to find a FAT entry for a Cluster #
;		Pack		   - to set a FAT entry for a Cluster #
;		Find_Empty_Cluster - find an unused cluster
;		Xfer_Data	   - transfere data from one cluster to another
;		Direct_Access	   - absolute disk i/o
;
;Input: 	FAT in BUF
;		[cluster_number] of specified cluster
;
;Output:	CF = 0	- AX = 0 if cluster found
;			     = -1 if cluster not found
;		CF = 1 if critical error
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Search_FAT
;
;	set cluster # to [cluster_number]
;	search till at end of FAT
;		call Unpack
;	exitif cluster found
;		save [last_cluster]
;		clear CF
;	orelse
;		advance to next cluster
;	endloop if past last cluster in fat
;		set CF
;	endsrch
;	if cluster found
;		call Find_Empty_Cluster
;	endif
;
;	if empty cluster available and
;
;	call Xfer_Data
;
;	if no errors
;
;	set taget cluster as one pointing to [cluster_number]
;	set value to that of empty cluster
;	call Pack to update FAT
;	set target cluster as [cluster_number]
;	set cluster value to empty
;	call Pack to update FAT
;	set destination to first sector of first FAT
;	set count to # of fat sectors
;	set up for write
;	do until all FATS written
;		call Direct_Access
;		advace to next FAT  (ignore errors)
;	enddo
;
;	endif
;
;	if no errors
;		update DPB first cluster and total empty clusters
;	endif
;
;	ret
;
;	END Search_FAT
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Search_FAT

   Search_FAT PROC NEAR

   mov	si,[current_cluster]		; set cluster # to [cluster_number]    ;AN004;
;  $search				; till at end of FAT		       ;AN004;
$$DO79:
       call Unpack			;				       ;AN004;
;  $leave c				; quit on an error		       ;AN004;
   JC $$EN79
       cmp  di,[current_cluster]	; is it [current_cluster] ?	       ;AN004;
;  $exitif e				; it is 			       ;AN004;
   JNE $$IF79
       mov  [last_cluster],si		; save number for later 	       ;AN004;
       xor  ax,ax			;				       ;AN004;
       clc				; clear error flag (found)	       ;AN004;
;  $orelse				;				       ;AN004;
   JMP SHORT $$SR79
$$IF79:
       inc  si				; advance to next cluster	       ;AN004;
       xor  ax,ax			;				       ;AN004;
       dec  ax				;				       ;AN004;
       cmp  si,[MCLUS]			; at the end ?			       ;AN004;
;  $endloop e				; if past last cluster		       ;AN004;
   JNE $$DO79
$$EN79:
       stc				;				       ;AN014;
;  $endsrch				;				       ;AN004;
$$SR79:
;  $if	nc				; if cluster found		       ;AN004;
   JC $$IF85
       call Find_Empty_Cluster		; to move data to		       ;AN004;
;  $endif				;				       ;AN004;
$$IF85:
;  $if	nc,and				; empty cluster available and	       ;AN004;
   JC $$IF87
   call Xfer_Data			; to move data to new cluster	       ;AN004;
;  $if	nc,and				; no errors			       ;AN004;
   JC $$IF87
   mov	si,[last_cluster]		; set target [last_cluster]	       ;AN004;
   mov	dx,[empty_cluster]		; set value to [empty_cluster]	       ;AN004;
   call Pack				; to update FAT 		       ;AN004;
;  $if	nc,and				; no errors			       ;AN004;
   JC $$IF87
   mov	si,[empty_cluster]		; set target [empty_cluster]	       ;AN004;
   mov	dx,[next_cluster]		; set value to [next_cluster]	       ;AN004;
   call Pack				; to update FAT 		       ;AN004;
;  $if	nc,and				; no errors			       ;AN004;
   JC $$IF87
   mov	si,[current_cluster]		; set target [current_cluster]	       ;AN004;
   xor	dx,dx				; set cluster value to empty	       ;AN004;
   call Pack				; to update FAT 		       ;AN004;
;  $if	nc				; no errors			       ;AN004;
   JC $$IF87
       xor  ah,ah			;				       ;AN004;
       dec  ah				;				       ;AN004;
       call Direct_Access		; write it out - ignore errors	       ;AN004;
       mov  ax,[FSIZE]			;				       ;AN004;
       cmp  [FAT_2],0			;				       ;AN004;
;      $if  e				;				       ;AN004;
       JNE $$IF88
	   add	[packet],ax		;				       ;AN004;
	   inc	[FAT_2] 		; packet points to FAT #2	       ;AC006;
;      $else				;				       ;AN004;
       JMP SHORT $$EN88
$$IF88:
	   sub	[packet],ax		;				       ;AN004;
	   mov	[FAT_2],0		; reset - packet points to FAT #1      ;AN004;
;      $endif				;				       ;AN004;
$$EN88:
       xor  ah,ah			;				       ;AN004;
       dec  ah				;				       ;AN004;
       call Direct_Access		; write it out - ignore errors	       ;AN004;
       mov  [FAT_changed],0		; FAT now cleared		       ;AN004;
       push es				; update DPB first cluster	       ;AN004;
       mov  bx,ds			;				       ;AN004;
       mov  es,bx			;				       ;AN004;
       lds  bx,[THIS_DPB]		;				       ;AN004;

       ASSUME ds:nothing,es:DATA

       mov  [bx.dpb_next_free],2	;				       ;AN004;
       mov  ax,es			;				       ;AN004;
       mov  ds,ax			;				       ;AN004;
       pop  es				;				       ;AN004;
       xor  ax,ax			; signal success (ax = 0 , cf = 0)     ;AN004;

       ASSUME DS:data, es:nothing

;  $endif				;				       ;AN004;
$$IF87:
;  $if	c				;				       ;AN004;
   JNC $$IF92
       cmp  ax,-1			;				       ;AN004;
;      $if  e				;				       ;AN004;
       JNE $$IF93
	   clc				; not a critical error - keep trying   ;AN004;
;      $else				;				       ;AN004;
       JMP SHORT $$EN93
$$IF93:
	   stc				; major problem - critical error       ;AN004;
;      $endif				;				       ;AN004;
$$EN93:
;  $endif				;				       ;AN004;
$$IF92:

   ret					;				       ;AN000;

   Search_FAT ENDP

   BREAK <SYS - Find_Empty_Cluster >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Find_Empty_Cluster
;*******************************************************************************
;
;Description: Find_Empty_Cluster finds the first available empty cluster
;
;Called Procedures:
;
;		Unpack	- find next cluster number
;
;Input: 	none
;
;Output:	CF = 0 - empty cluster found (# in [empty_cluster])
;		CF = 1 - no empty clusters (ax = message)
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Find_Empty_Cluster
;
;	search till at end of FAT
;		call Unpack
;	exitif cluster is empty (ZF)
;		save empty cluster number
;		clear CF
;	orelse
;		advance to next cluster
;	endloop if past last cluster
;		load ax message # - no room for sys files
;		set CF
;	endsrch
;
;	ret
;
;	END Find_Empty_Cluster
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Find_Empty_Cluster

   Find_Empty_Cluster PROC NEAR

   mov	si,[current_cluster]		;				       ;AN004;
   mov	ax,[cluster_count]		;				       ;AN004;
   add	si,ax				; look past required space	       ;AN004;
;  $search				; till at end of FAT		       ;AN004;
$$DO97:
       call Unpack			; to convert # to value 	       ;AN004;
;  $exitif z				; cluster is empty		       ;AN004;
   JNZ $$IF97
       mov  [empty_cluster],si		; save it for later		       ;AN004;
       clc				; clear error flag		       ;AN004;
;  $orelse				;				       ;AN004;
   JMP SHORT $$SR97
$$IF97:
       inc  si				; advance to next cluster	       ;AN004;
       cmp  si,[MCLUS]			; past the end ?		       ;AN004;
;  $endloop e				; if past last cluster		       ;AN004;
   JNE $$DO97
       stc				; set error flag		       ;AN004;
       mov  ax,(util shl 8) + no_room	; error message - no room to sys       ;AN014;
;  $endsrch				;				       ;AN004;
$$SR97:

   ret					;				       ;AN004;

   Find_Empty_Cluster ENDP

   BREAK <SYS - Xfer_Data >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Xfer_Data
;*******************************************************************************
;
;Description: Xfer_Data moves the data from [cluster_number] into the cluster
;	      number passed in ax.
;
;Called Procedures:
;
;		Direct_Access - do disk i/o
;
;Input: 	[current_cluster]
;		[empty_cluster]
;
;Output:	CF = 0	- data transfered
;		CF = 1	- error - message in AX
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Xfer_Data
;
;	save active FAT starting sector
;	set source to first sector of [current_cluster]
;	set count to # of sectors per cluster
;	set up for read
;	call Direct_Access to read data
;	if no errors
;		set source to first sector of [empty_cluster]
;		set up for write
;		call Direct_Access to write data
;	endif
;	restore Fat starting sector
;	set count to FAT_sectors
;	set up for read
;	call Direct_Access to restore the FAT copy
;
;	endif
;
;	ret
;
;	END Xfer_Data
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Xfer_Data

   Xfer_Data PROC NEAR

   push [packet]			; save active FAT starting sector      ;AN004;
   push [packet+2]			;				       ;AN004;
   push [packet_sectors]		;				       ;AN004;
   mov	ax,[CSIZE]			;				       ;AN004;
   mov	[packet_sectors],ax		;				       ;AN004;
   mov	ax,[current_cluster]		; set source to [current_cluster]      ;AN004;
   call cluster_2_sector		; convert Cluster to sector #	       ;AN004;
   mov	[packet],ax			; low sector word		       ;AN004;
   mov	[packet+2],dx			; high sector word		       ;AN004;
   xor	ah,ah				; set up for read		       ;AN004;
   call Direct_Access			; to read data			       ;AN004;
;  $if	nc				; no errors			       ;AN004;
   JC $$IF102
       mov  ax,[empty_cluster]		; set destination to [empty_cluster]   ;AN004;
       cmp  [DIR_cluster],0		; have we just loaded a directory?     ;AN007;
;      $if  ne				; if so -			       ;AN007;
       JE $$IF103
	   mov	[DIR_cluster],ax	; save the new cluster		       ;AN007;
	   lea	bx,BUF			;				       ;AN007;
	   mov	[bx.dir_first],ax	; update the '.' entry start cluster   ;AN007;
;      $endif				;				       ;AN007;
$$IF103:
       call cluster_2_sector		; conver to logical sector	       ;AN004;
       mov  [packet],ax 		; low word			       ;AN004;
       mov  [packet+2],dx		; high word			       ;AN004;
       xor  ah,ah			; set up for write		       ;AN004;
       dec  ah				;				       ;AN004;
       call Direct_Access		; to write data 		       ;AN004;
;  $endif				;				       ;AN004;
$$IF102:
   pop	[packet_sectors]		;				       ;AN004;
   pop	[packet+2]			; restore starting sector	       ;AN004;
   pop	[packet]			;				       ;AN004;
   xor	ah,ah				; set up for read		       ;AN004;
   call Direct_Access			; to restore the FAT copy	       ;AN004;

   ret					;				       ;AN004;

   Xfer_Data ENDP

   BREAK <SYS - cluster_2_sector >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: cluster_2_sector
;*******************************************************************************
;
;Description:  cluster_2_sector
;
;
;Called Procedures:
;
;		none
;
;Input: 	AX - cluster number
;
;Output:	AX - low word of sector
;		DX - high word of sector
;		CX - sectors per cluster
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START cluster_2_sector
;
;	ret
;
;	END cluster_2_sector
;
;******************-  END  OF PSEUDOCODE -**************************************

   public cluster_2_sector

   cluster_2_sector PROC NEAR

   dec	ax				;    of [current_cluster]	       ;AN004;
   dec	ax				;				       ;AN004;
   mov	cx,[CSIZE]			;				       ;AN004;
   mul	cx				;				       ;AN004;
   add	ax,[l_sector_offset]		;				       ;AN004;

   ret					;				       ;AN004;

   cluster_2_sector ENDP

   BREAK <SYS - Search_DIR >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Search_DIR
;*******************************************************************************
;
;Description: Search_DIR walks the directory tree looking for the file that
;	      starts with [cluster_number]. If found, the data is moved to the
;	      first empty cluster (if available), and the directory entry is
;	      updated.
;
;	      This routine walks the DIR tree by creating a 'FRAME' for each
;	      Sub DIR it encounters. It saves all the data needed to continue
;	      the search once the Sub DIR has been checked.
;
;      FRAME   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;	       ³      present_cluster #     ³sector_offset ³ entry_number ³
;	       ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;	  byte	       1	    2		    3		   4
;
;	      There is space in DIR_BUF for 32 frames (current DOS maximum
;	      level of nesting).
;
;Called Procedures:
;
;		Search_Loop   - scan the directory
;
;Input: 	[current_cluster] - # of cluster to be freed
;
;Output:	CF = 0	cluster now available
;		CF = 1	error - ax = message #
;
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Search_DIR
;
;	set up for first_dir_sector of root DIR
;	set up for read
;	call Direct_Access to read first root sector
;	if no error
;		set [current_sector]
;		set [sector_count] = #_dir_sectors
;		set [current_entry] = 1
;		set [sub_dir_level] = 0
;		do until cluster free (NC)
;			call Search_Loop
;			if SubDir
;				save [current_cluster] in frame
;				save [current_sector]in frame
;				save [current_entry] in frame
;				save [sector_count] in frame
;				incriment [sub_dir_level] (frame)
;				zero ax
;				set error flag (CF)
;			else
;				if end of DIR (CF + 00) and
;				if [dir_count] > 0
;					recover [current_cluster] from frame
;					recover [current_sector] from frame
;					recover [current_entry] from frame
;					recover [sector_count] from frame
;					decriment [sub_dir_level]
;					zero ax
;					set error flag (CF)
;				 else
;					load error message - no room to sys
;				 endif
;				 set error flag (CF) (ax = message)
;			endif
;		leave if error (ax > 0)
;		enddo
;	endif
;
;	ret
;
;	END  Search_DIR
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Search_DIR

   Search_DIR PROC NEAR

   mov	ax,[first_dir_sector]		; set up for first_dir_sector of root  ;AN004;
   mov	[packet],ax			;				       ;AN004;
   mov	[packet+2],0			; zero out high word		       ;AN004;
   mov	[packet_sectors],1		; only process 1 sector at a time      ;AN004;
   mov	[packet_buffer],OFFSET DIR_SECTOR ;				       ;AN004;
   xor	ah,ah				; set up for read		       ;AN004;
   call Direct_Access			; to read first root sector	       ;AN004;
;  $if	nc,long 			; no error			       ;AN004;
   JNC $$XL1
   JMP $$IF106
$$XL1:
       xor  ax,ax			;				       ;AN004;
       mov  [present_cluster],ax	; set [present_cluster] = 0 (root)     ;AN004;
       mov  [entry_number],al		; set [entry_number] = 0 (first)       ;AN004;
       mov  ax,[first_dir_sector]	;				       ;AN013;
       mov  [sector_offset],ax		; set [sector_offset] = [first_dir_sec];AC015;
       lea  bx,DIR_BUF			; set [FRAME_ptr] = DIR_BUF	       ;AN004;
       mov  [FRAME_ptr],bx		;				       ;AN004;
;      $do				;  until cluster free (NC)	       ;AN004;
$$DO107:
	   call Search_Loop		;				       ;AN004;
;      $leave nc,long			; cluster found and moved	       ;AN004;
       JC $$XL2
       JMP $$EN107
$$XL2:
	   cmp	ax,0ffffh		;				       ;AN004;
;	   $if	e			; SubDir			       ;AN004;
	   JNE $$IF109

					; Search DIR returned with BX pointing
					;  to the current entry - now update
					;  current_cluster to this SubDIRs first
					;  cluster

	       mov  ax,[bx.dir_first]	; get starting cluster for where we    ;AN007;
					;  want to go
	       mov  bx,[present_cluster] ; get [present_cluster] for frame     ;AN004;
					;  (where we were)
	       mov  [present_cluster],ax ;  [present_cluster] for next pass    ;AN007;
	       xchg ax,bx		; recover old [present_cluster]        ;AN007;
	       mov  bx,[FRAME_ptr]	; get FRAME pointer		       ;AN004;
	       mov  [bx.p_cluster],ax	; save [present_cluster] in frame      ;AN004;
	       mov  ax,[sector_offset]	; save [sector_offset]in frame	       ;AC015;
	       mov  [bx.s_offset],ax	;				       ;AC015;
	       mov  al,[entry_number]	; save [entry_number] in frame	       ;AN004;
	       mov  [bx.e_number],al	;				       ;AN004;
	       xor  ax,ax		; reset -			       ;AN007;
	       mov  [sector_offset],ax	;	  [sector_offset]	       ;AC015;
	       mov  [entry_number],al	;	  [entry_number]	       ;AN007;
	       add  bx,SIZE FRAME	; incriment FRAME pointer	       ;AN004;
	       lea  ax,DIR_SECTOR	;				       ;AN004;
	       cmp  ax,bx		;				       ;AN004;
;	       $if  a			;				       ;AC007;
	       JNA $$IF110
		   mov	[FRAME_ptr],bx	;				       ;AN004;
		   clc			; no error			       ;AN004;
;	       $else			;				       ;AN004;
	       JMP SHORT $$EN110
$$IF110:
		   stc			; set error flag (CF)		       ;AN004;
;	       $endif			;				       ;AN004;
$$EN110:
;	   $else long			;				       ;AN004;
	   JMP $$EN109
$$IF109:
	       cmp  ax,0		;				       ;AN004;
;	       $if  e,and,long		; end of DIR (CF + 00) and	       ;AN004;
	       JE $$XL3
	       JMP $$IF114
$$XL3:
next_level_down:			;				       ;AN004;
	       mov  bx,[FRAME_ptr]	; recover FRAME_ptr - but remember **  ;AC007;
					;  it points to the next available
					;  frame - not the last one - so
	       sub  bx,SIZE FRAME	; move back!			       ;AN007;
	       lea  ax,DIR_BUF		;				       ;AN004;
	       cmp  ax,bx		;				       ;AN004;
;	       $if  be			; as long as there are still FRAMEs    ;AC007;
	       JNBE $$IF114
		   mov	ax,[bx.p_cluster] ; get [present_cluster] from frame   ;AN004;
		   mov	[present_cluster],ax ;				       ;AN004;
		   mov	ax,[bx.s_offset] ; recover [sector_offset] from frame  ;AC015;
		   mov	[sector_offset],ax ;				       ;AC015;
		   mov	al,[bx.e_number] ; recover [entry_number] from frame   ;AN004;
		   mov	[entry_number],al ;				       ;AN004;
		   mov	[FRAME_ptr],bx	;				       ;AN004;

					; Now set up at exactly same point
					;  as when SubDIR was entered -
					;  advance to next entry

		   inc	al		;				       ;AN004;
		   cmp	al,[entries_per_sector] ;			       ;AN004;
;		   $if	b		;				       ;AN004;
		   JNB $$IF115
		       inc  [entry_number] ;				       ;AN004;
		       clc		; no error			       ;AN004;
;		   $else		; we've left the sector                ;AN004;
		   JMP SHORT $$EN115
$$IF115:
if not ibmcopyright
			xor	al, al
			mov [entry_number], al	; shall we start at, say, ENTRY ZERO?  Hmmmmm?
endif
		       mov  ax,[present_cluster] ;			       ;AN004;
		       cmp  ax,0	; in the root ? 		       ;AN004;
;		       $if  ne		; no				       ;AN004;
		       JE $$IF117
			   mov	si,ax	;				       ;AN004;
			   mov	[cluster_high],1 ; force Upack to load FAT     ;AN004;
			   mov	ax,[FAT_sectors] ; get the size right	       ;AN004;
			   mov	[packet_sectors],ax ;			       ;AN004;
			   mov	[packet_buffer],OFFSET BUF ;		       ;AN004;
			   call Unpack	; to get next cluster # 	       ;AN004;
			   mov	[packet_buffer],OFFSET DIR_SECTOR ;	       ;AN004;
			   mov	[packet_sectors],1 ; set size back	       ;AN004;
			   mov	[cluster_high],1 ; ensure that FAT will be     ;AN004;
					;	      re-loaded

			   mov	ax,di	; check if at end		       ;AN007;
			   cmp	al,end_cluster ;  at the end?		       ;AN007;
;			   $if	nz	; not at end of line		       ;AN004;
			   JZ $$IF118
			       mov  [present_cluster],di ; save it	       ;AN004;
			       clc	;				       ;AN004;
;			   $else	; we are at the end of a Sub DIR chain ;AN004;
			   JMP SHORT $$EN118
$$IF118:

					; the following is a best attempt fix
					; to a bad design problem ...... (how
					;  to get back a level.....???

; SEPT 21 - best solution is to check BEFORE putting the entry in the frame
;			       (not when taking it off !!! )

			       jmp  next_level_down ;			       ;AN004;

;			   $endif	;				       ;AN004;
$$EN118:
;		       $else		;  yes - in the root		       ;AN004;
		       JMP SHORT $$EN117
$$IF117:
			   mov	ax,[sector_offset] ;			       ;AC015;
			   inc	ax	;				       ;AN004;
			   cmp	ax,[l_sector_offset] ;			       ;AC015;
;			   $if	b	;				       ;AN004;
			   JNB $$IF122
			       inc  [sector_offset] ;			       ;AN004;
if not ibmcopyright
				clc	; no error, continue with loop
endif
;			   $else	; end of the line		       ;AN004;
			   JMP SHORT $$EN122
$$IF122:
			       stc	; we failed to find it		       ;AN004;
;			   $endif	;				       ;AN004;
$$EN122:
;		       $endif		;				       ;AN004;
$$EN117:
;		   $endif		;				       ;AN004;
$$EN115:
;	       $else			;				       ;AN004;
	       JMP SHORT $$EN114
$$IF114:
		   stc			; set error flag (CF)		       ;AN004;
;	       $endif			;				       ;AN004;
$$EN114:
;	   $endif			;				       ;AN004;
$$EN109:
;	   $if	c			; error 			       ;AN004;
	   JNC $$IF130
	       mov  ax,(util shl 8) + no_room ; error message - no room to sys ;AN004;
;	   $endif			;				       ;AN004;
$$IF130:
;      $leave c 			; if error			       ;AN004;
       JC $$EN107
;      $enddo long			;				       ;AN004;
       JMP $$DO107
$$EN107:
;  $endif				;				       ;AN004;
$$IF106:

   ret					;				       ;AN004;

   Search_DIR ENDP

   BREAK <SYS - Search_Loop >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Search_Loop
;*******************************************************************************
;
;Description: Search_Loop scans through all entries of all sectors of all
;	      clusters of a given Directory for a specified cluster
;
;Called Procedures:
;
;		Unpack		   - to find a FAT entry for a Cluster #
;		Pack		   - to set a FAT entry for a Cluster #
;		Find_Empty_Cluster - find an unused cluster
;		Xfer_Data	   - transfere data from one cluster to another
;		Direct_Access	   - absolute disk i/o
;
;Input:
;
;Output:	CF = 0	found and freed [cluster_number]
;		CF = 1 - ax = 0 		- at end of directory
;			 ax = (message + class) - error occured
;			 ax = -1		- SubDir found
;			 bx = pointer to current entry
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Search_Loop
;
;	search till at end of directory - all clusters checked
;		search till at end of sectors - in given cluster
;			search till at end of sector - all entries checked
;			exitif starting cluster = [cluster_number]
;				set up for FAT
;				call Find_Empty_Cluster
;				if no error and
;				call Xfer_Data
;				reset for DIR
;				if no error
;					update dir_first_clust
;					set up for write
;					call Direct_Access to write out the directory
;				endif
;			orelse
;			leave if entry is a subdirectory (ah = ffh)
;				advace to next entry
;				zero ax
;			endloop if past end of sector
;				set fail flag (CF)
;			endsrch
;		exit if [current_cluster] found (NC)
;		orelse
;		leave if subdirectory found (CF + FF)
;			if sectors left to read
;				set up to read
;				call Direct_Access to read sector
;			else
;				set error flag (CF)
;				zero ax (end of sectors)
;			endif
;		endloop if error
;		endsrch
;	leave if [current_cluster] found (NC)
;	leave if SubDir found (CF + FF)
;	leave if Error (CF + message)
;		get [current_cluster] #
;		call Unpack to get next cluster #
;	exitif no more clusters
;		zero ax (end of clusters)
;		set error flag (CF)
;	orelse
;		convert cluster # to logical sector #
;		update [current_sector]
;	endloop
;	endsrch
;
;	ret
;
;	END  Search_Loop
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Search_Loop

   Search_Loop PROC NEAR

   mov	ax,[present_cluster]		; initailize for search 	       ;AN004;
   cmp	ax,0				;				       ;AN004;
;  $if	ne				;				       ;AN004;
   JE $$IF135
       call cluster_2_sector		; convert it to a sector	       ;AN004;
       add  ax,[sector_offset]		;				       ;AC015;
;      $if  c				;				       ;AN004;
       JNC $$IF136
	   inc	dx			;				       ;AN004;
;      $endif				;				       ;AN004;
$$IF136:
;  $else				;				       ;AN004;
   JMP SHORT $$EN135
$$IF135:
       mov  ax,[sector_offset]		;[sector_offset] = current root sector ;AC015;
       xor  dx,dx			;				       ;AN004;
;  $endif				;				       ;AN004;
$$EN135:
   mov	[packet],ax			;				       ;AN004;
   mov	[packet+2],dx			;				       ;AN004;
   xor	ah,ah				;				       ;AN004;
   call Direct_Access			; to read the DIR		       ;AN004;
   mov	al,SIZE dir_entry		;				       ;AN004;
   mov	cl,[entry_number]		;				       ;AN004;
   mul	cl				;				       ;AN004;
   lea	bx,DIR_SECTOR			;				       ;AN004;
   add	bx,ax				; BX now points to the DIR entry       ;AN004;
;  $search				; till at end of directory	       ;AN004;
$$DO140:
					;     - all clusters checked
;      $search				; till at end of sectors	       ;AN004;
$$DO141:
					;     - in given cluster
;	   $search			; till at end of sector 	       ;AN004;
$$DO142:
					;     - all entries checked
	       cmp  BYTE PTR [bx],deleted ; make sure the entry is valid !!!   ;AN019;
;	       $if  e			; if it is not -		       ;AN019;
	       JNE $$IF143
		   xor	ax,ax		;				       ;AN019:
		   mov	[bx.dir_first],ax ; zap the starting cluster	       ;AN019;
		   mov	[bx.dir_attr],al ;  zap the attribute		       ;AN019;
;	       $endif			;				       ;AN019;
$$IF143:
	       mov  ax,[bx.dir_first]	;				       ;AN004;
	       cmp  ax,[current_cluster] ;				       ;AN004;
;	   $exitif e,and,long		; starting cluster = [current_cluster] ;AN004;
	   JE $$XL4
	   JMP $$IF142
$$XL4:
	       cmp  BYTE PTR [bx],deleted ; make sure the entry is valid !!!   ;AN007;
;	   $exitif ne,and,long		; and entry is not deleted	       ;AN007;
	   JNE $$XL5
	   JMP $$IF142
$$XL5:
	       cmp  BYTE PTR [bx],dot	;				       ;AN007;
;	   $exitif ne,long		; and entry is not a . or .. name      ;AN007;
	   JNE $$XL6
	   JMP $$IF142
$$XL6:
	       test [bx.dir_attr],attr_directory ; is it a subdir ?	       ;AN007;
;	       $if  nz			;if entry is a subdirectory	       ;AN007;
	       JZ $$IF146
		   inc	[DIR_cluster]	; signal special processing	       ;AN007;
					;   Xfere_Data will use this later -
					;    0 = not a sub DIR
					;    1 = do Sub DIR processing and
					;	 update [DIR_cluster] to the
					;	 same value as [empty_cluster]
;	       $endif			;				       ;AN007;
$$IF146:
	       mov  ax,[packet] 	; save pointer to this DIR	       ;AN007;
	       mov  [dir_sector_low],ax ;				       ;AN007;
	       mov  ax,[packet+2]	;				       ;AN007;
	       mov  [dir_sector_hi],ax	;				       ;AN007;
	       mov  [source_ptr],bx	; save pointer			       ;AN004;
	       mov  [cluster_high],1	; force Upack to load FAT	       ;AN004;
	       mov  ax,[FAT_sectors]	; get the size right		       ;AN004;
	       mov  [packet_sectors],ax ;				       ;AN004;
	       mov  [packet],1		;				       ;AN004;
	       mov  [packet+2],0	;				       ;AN004;
	       mov  [packet_buffer],OFFSET BUF ;			       ;AN004;
	       call Find_Empty_Cluster	;				       ;AN004;
;	       $if  nc,and		; no errors so far		       ;AN004;
	       JC $$IF148
	       mov  si,[empty_cluster]	;				       ;AN004;
	       mov  dx,[next_cluster]	;				       ;AN004;
	       call PACK		;				       ;AN004;
;	       $if  nc,and		; no errors so far		       ;AN004;
	       JC $$IF148
	       mov  si,[current_cluster] ;				       ;AN004;
	       xor  dx,dx		; make it empty 		       ;AN004;
	       call PACK		;				       ;AN004;
;	       $if  nc			; no errors so far		       ;AN004;
	       JC $$IF148
		   cmp	[bigfat],0	;				       ;AN004;
;		   $if	ne		;				       ;AN004;
		   JE $$IF149
		       mov  [cluster_high],1 ; ensure that FAT will be updated ;AN004;
		       call Unpack	;				       ;AN004;
;		   $else		; must manualy write out 12 bit FATS   ;AN004;
		   JMP SHORT $$EN149
$$IF149:
		       xor  ah,ah	;				       ;AN004;
		       dec  ah		;				       ;AN004;
		       mov  [packet],1	; start with the first FAT	       ;AN004;
		       call Direct_Access ; write it out - ignore errors       ;AN004;
		       mov  ax,[FSIZE]	;				       ;AN004;
		       add  [packet],ax ; advance to second FAT 	       ;AN004;
		       xor  ah,ah	;				       ;AN004;
		       dec  ah		;				       ;AN004;
		       call Direct_Access ; write it out - ignore errors       ;AN004;
;		   $endif		;				       ;AN004;
$$EN149:
;	       $endif			;				       ;AN004;
$$IF148:
;	       $if  nc,and		; no error and			       ;AN004;
	       JC $$IF153
	       call Xfer_Data		;				       ;AN004;
;	       $if  nc			; no error			       ;AN004;
	       JC $$IF153
		   mov	ax,[empty_cluster] ; update dir_first_clust	       ;AN004;
		   mov	bx,[source_ptr] ; recover pointer		       ;AN004;
		   mov	[bx.dir_first],ax ;				       ;AN004;
		   mov	[packet_sectors],1 ; set size back		       ;AN004;
		   mov	[packet_buffer],OFFSET DIR_SECTOR ;		       ;AN004;
		   mov	ax,[dir_sector_low] ; reset DIR sector		       ;AN007;
		   mov	[packet],ax	;				       ;AN007;
		   mov	ax,[dir_sector_hi] ;				       ;AN007;
		   mov	[packet+2],ax	;				       ;AN007;
		   xor	ah,ah		; set up for write		       ;AN004;
		   dec	ah		;				       ;AN004;
		   call Direct_Access	; to write out the directory	       ;AN004;
;		   $if	nc,and		;				       ;AN004;
		   JC $$IF154
		   cmp	[DIR_cluster],0 ; is a DIR being processed ?	       ;AN007;
;		   $if	ne		;				       ;AN007;
		   JE $$IF154
		       call Sub_DIR_Loop ; update any children		       ;AN007;
;		   $endif		;				       ;AN007;
$$IF154:
;		   $if	nc		; if no errors			       ;AN007;
		   JC $$IF156
		       mov  ax,[FAT_sectors] ;only read needed sectors	       ;AN004;
		       mov  [packet_sectors],ax ;			       ;AN004;
		       mov  [packet],1	;				       ;AN004;
		       mov  [packet_buffer],OFFSET BUF ; point to FAT buffer   ;AN004;
		       mov  [cluster_high],clusters_loaded ;		       ;AN004;
		       mov  [cluster_low],0 ;				       ;AN004;
		       xor  cx,cx	;				       ;AN004;
		       mov  di,cx	;				       ;AN004;
		       dec  di		;				       ;AN004;
		       mov  cl,[num_of_FATS] ;				       ;AN004;
					;				       ;AN004;
		       call Load_FAT	; restore FAT			       ;AN004;
					;				       ;AN004;
		       push es		; update DPB first cluster	       ;AN004;
		       mov  bx,ds	;				       ;AN004;
		       mov  es,bx	;				       ;AN004;
		       lds  bx,[THIS_DPB] ;				       ;AN004;

		       ASSUME ds:nothing,es:DATA

		       mov  [bx.dpb_next_free],2 ;			       ;AN004;
		       mov  ax,es	;				       ;AN004;
		       mov  ds,ax	;				       ;AN004;
		       pop  es		;				       ;AN004;

		       ASSUME DS:data, es:nothing

;		   $endif		;				       ;AN004;
$$IF156:
;	       $endif			;				       ;AN004;
$$IF153:
;	   $orelse			;				       ;AN004;
	   JMP SHORT $$SR142
$$IF142:
	       xor  ax,ax		; get ready in case -----	       ;AN007;
	       cmp  BYTE PTR [bx],0	; at the end of the dir?	       ;AN007;
;	   $leave e			;   then no point in continuing        ;AN007;
	   JE $$EN142
	       dec  ax			; get ready in case we fail	       ;AN004;
	       test [bx.dir_attr],attr_directory ; is it a subdir ?	       ;AN004;
;	   $leave nz, and		;if entry is a subdirectory (ah = ffh) ;AN004;
	   JZ $$LL161
	       cmp  byte ptr [bx],dot	; but not a DOT 		       ;AN007;
;	   $leave ne			;				       ;AN007;
	   JNE $$EN142
$$LL161:
	       xor  ax,ax		; zero ax			       ;AN004;
	       add  bx,SIZE dir_entry	; advace to next entry		       ;AN004;
	       inc  [entry_number]	;				       ;AN004;
	       cmp  bx,OFFSET BUF	; are we out of sector ?	       ;AN004;
;	   $endloop ae,long		;if past end of sector		       ;AN004;
	   JAE $$XL7
	   JMP $$DO142
$$XL7:
$$EN142:
	       stc			; set fail flag (CF)		       ;AN004;
;	   $endsrch			;				       ;AN004;
$$SR142:
;      $exitif nc			;[current_cluster] found (NC)	       ;AN004;
       JC $$IF141
;      $orelse				;				       ;AN004;
       JMP SHORT $$SR141
$$IF141:

					; we have  CF = 1 and could have:
					;		AX = 0 -
					;		AX = 1 to fffe
					;		AX = ffff
					;  so - leave if anything other than
					;	AX = 0 (out of stuff)

;      $leave c,and			; if not out of stuff		       ;AN004;
       JNC $$LL166
	   cmp	ax,0			;				       ;AN009;
	   stc				; restore carry flag!		       ;AN007;
;      $leave nz			;	------ leave !		       ;AN009;
       JNZ $$EN141
$$LL166:
	   mov	ax,[sector_offset]	;				       ;AC015;
	   inc	ax			;				       ;AN004;
	   cmp	[present_cluster],0	; are we in the root?		       ;AN007;
;	   $if	e			; if so -			       ;AN004;
	   JNE $$IF167
	       cmp  ax,[l_sector_offset] ;   use root sectors		       ;AC013;
;	   $else			;  else -			       ;AN004;
	   JMP SHORT $$EN167
$$IF167:
	       cmp  ax,[CSIZE]		;      use sectors per cluster	       ;AN004;
;	   $endif			;				       ;AN004;
$$EN167:
;	   $if	b			; sectors left to read		       ;AN004;
	   JNB $$IF170
	       add  [packet],1		; advance to the next sector	       ;AN004;
;	       $if  c			;				       ;AN004;
	       JNC $$IF171
		   inc	[packet+2]	; adjust high word if needed	       ;AN004;
;	       $endif			;				       ;AN004;
$$IF171:
	       xor  ah,ah		; set up to read		       ;AN004;
	       mov  [entry_number],ah	;				       ;AN004;
	       inc  [sector_offset]	;				       ;AN004;
	       call Direct_Access	; to read sector		       ;AN004;
	       lea  bx,DIR_SECTOR	; set index to start of sector	       ;AN004;
;	   $else			;				       ;AN004;
	   JMP SHORT $$EN170
$$IF170:
	       xor  ax,ax		; zero ax (end of sectors)	       ;AN004;
	       stc			; set error flag (CF)		       ;AN004;
;	   $endif			;				       ;AN004;
$$EN170:
;      $endloop c,long			; if error			       ;AN004;
       JC $$XL8
       JMP $$DO141
$$XL8:
$$EN141:
;      $endsrch 			;				       ;AN004;
$$SR141:
;  $leave nc				; if [current_cluster] found (NC)      ;AN004;
   JNC $$EN140
;  $leave c,and 			;if SubDir found (CF + FF)	       ;AN004;
   JNC $$LL178
       cmp  ax,0			;				       ;AN004;
       stc				; set carry			       ;AN007;
;  $leave nz				; if Error (CF + messageor FFFFh)      ;AN004;
   JNZ $$EN140
$$LL178:

					;--------------------------------------
					; CF = 1 and AX = 0 means - no critical
					;			     errors
					;			  -  no Sub DIR
					;			     found
					;  inner SEARCH is out of sectors
					;   - so advance to the next cluster
					;--------------------------------------
       mov  si,[present_cluster]	; get [present_cluster] #	       ;AN004;
       cmp  si,0			; end of the root ?		       ;AN004;
;      $if  nz				;				       ;AN004;
       JZ $$IF179
	   mov	[cluster_high],1	; force Upack to load FAT	       ;AN004;
	   mov	ax,FAT_sectors		; get the size right		       ;AN004;
	   mov	[packet_sectors],ax	;				       ;AN004;
	   mov	[packet_buffer],OFFSET BUF ;				       ;AN004;
	   call Unpack			; to get next cluster # 	       ;AN004;
	   mov	[packet_sectors],1	; set size back 		       ;AN004;
	   mov	[cluster_high],1	; ensure that FAT will be re-loaded    ;AN004;
	   mov	[packet_buffer],OFFSET DIR_SECTOR ;			       ;AN004;
	   mov	ax,di			;				       ;AN007;
	   cmp	al,end_cluster		;				       ;AN007;
;      $endif				;				       ;AN004;
$$IF179:
;  $exitif z				; no more clusters		       ;AN004;
   JNZ $$IF140
       xor  ax,ax			; zero ax (end of clusters)	       ;AN004;
       stc				; set error flag (CF)		       ;AN004;
;  $orelse				;				       ;AN004;
   JMP SHORT $$SR140
$$IF140:
       mov  [present_cluster],di	;				       ;AN004;
       mov  ax,di			; set up for cluster_2_sector	       ;AN004;
       call cluster_2_sector		; convert cluster # to logical sector #;AN004;
       mov  [packet],ax 		;				       ;AN004;
       mov  [packet+2],dx		;				       ;AN004;
       xor  ax,ax			;				       ;AN004;
       mov  [sector_offset],ax		; reset [sector_offset] 	       ;AC015;
       mov  [entry_number],ah		; reset [entry_number]		       ;AN004;
       call Direct_Access		; to read sector		       ;AN004;
       lea  bx,DIR_SECTOR		; set pointer			       ;AN004;
;  $endloop c,long			; end loop if read fails	       ;AN004;
   JC $$XL9
   JMP $$DO140
$$XL9:
$$EN140:
;  $endsrch				;				       ;AN004;
$$SR140:

   ret					;				       ;AN004;

   Search_Loop ENDP

   BREAK <SYS - Sub_DIR_Loop >

;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Sub_DIR_Loop
;*******************************************************************************
;
;Description: Sub_DIR_Loop scans through all entries of a subdirectory looking
;	      child subdirectories. If found, their parent [dir_first] entries
;	      (the .. entry) are updated to point to the correct cluster
;
;Called Procedures:
;
;		Unpack		   - to find a FAT entry for a Cluster #
;		Direct_Access	   - absolute disk i/o
;
;Input: 	[empty_cluster]   - new parent Sub DIR cluster #
;		[DIR_cluster]	  - current cluster of DIR being looped
;
;Output:	CF = 0	at end of directory
;		CF = 1	a read/write error occured
;
;Change History: Created       10/07/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Sub_DIR _Loop
;
;	get DIR_cluster
;	call cluster_2_sector
;	update packet
;	set for read
;	reset entry pointer
;	reset sector count
;	call Direct_Access
;	if no error
;	      search till at end of directory - all clusters checked
;		    search till at end of sectors - in given cluster
;			  search till at end of sector - all entries checked
;			  leave if null entry
;				if entry is not deleted and
;				if this entry is a subdir and
;				if this is a true entry and
;				save current sector
;				save current entry
;				get start cluster
;				call cluster_2_sector
;				set for read
;				call Direct_Access
;				if no errors and
;				update pointer to parent
;				set for write
;				call Direct_Access
;				if no errors and
;				recover current sector
;				recover current entry
;				if no errors
;				     call Direct_Access
;				endif
;			  exitif error (CF)
;			  orelse
;				advance to next entry
;			  endloop if past end of sector
;				clear error flag
;			  endsrch
;		    leave if error
;			  advance to next sector (packet)
;			  incriment sector count
;		    exitif past end of cluster
;			  clear error flag
;		    orelse
;			  reset entry pointer
;			  set for read
;			  call Direct_Access
;		    endloop if error
;		    endsrch
;	      leave if error
;		    get DIR_cluster
;		    call UNPACK to find next Sub DIR cluster
;	      exitif at end of chain
;		    clear error flag
;	      orelse
;		    update DIR_cluster
;		    call cluster_2_sector
;		    update packet
;		    set for read
;		    call Direct_Access
;	      leave if error
;		    reset entry pointer
;		    reset sector count
;	      endloop
;	      endsrch
;	endif
;	reset Sub_DIR_cluster to 0
;
;	ret
;
;	END  Sub_DIR_Loop
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Sub_DIR_Loop

   Sub_DIR_Loop PROC NEAR

   mov	ax,[DIR_cluster]		; get DIR_cluster		       ;AN007;
   call cluster_2_sector		; to convert to a logical sector       ;AN007;
   mov	[packet],ax			; update packet 		       ;AN007;
   mov	[packet+2],dx			;				       ;AN007;
   xor	ax,ax				; set for read			       ;AN007;
   call Direct_Access			; to read the first sector of the DIR  ;AN007;
;  $if	nc,long 			; if no error			       ;AN007;
   JNC $$XL10
   JMP $$IF185
$$XL10:
       mov  [sector_count],1		; reset sector count		       ;AN007;
       lea  bx,DIR_SECTOR		; reset entry pointer		       ;AN007;
;      $search				; till at end of directory	       ;AN007;
$$DO186:
					;      - all clusters checked	       ;AN007;
;	   $search			; till at end of sectors	       ;AN007;
$$DO187:
					;      - in given cluster	       ;AN007;
;	       $search			; till at end of sector 	       ;AN007;
$$DO188:
					;      - all entries checked	       ;AN007;
		   mov	[dir_offset],bx ; reset entry pointer		       ;AN007;
		   cmp	BYTE PTR [bx],0 ; null entry (00)?		       ;AN007;
;	       $leave z 		; if null entry 		       ;AN007;
	       JZ $$EN188
		   cmp	BYTE PTR [bx],deleted ; deleted entry (E5)?	       ;AN007;
;		   $if	ne,and		; if entry is not deleted and	       ;AN007;
		   JE $$IF190
		   test [bx.dir_attr],attr_directory ; is it a subdir ?        ;AN007;
;		   $if	nz,and		; if this entry is a subdir and        ;AN007;
		   JZ $$IF190
		   cmp	BYTE PTR [bx],dot ; dot entry (2E)?		       ;AN007;
;		   $if	ne,and		; this is a true entry and	       ;AN007;
		   JE $$IF190
		   mov	ax,[packet]	; save current sector		       ;AN007;
		   mov	[dir_sector_low],ax ;				       ;AN007;
		   mov	ax,[packet+2]	;				       ;AN007;
		   mov	[dir_sector_hi],ax ;				       ;AN007;
		   mov	ax,[bx.dir_first] ; get start cluster		       ;AN007;
		   call cluster_2_sector ; convert to sector		       ;AN007;
		   mov	[packet],ax	; update packet 		       ;AN007;
		   mov	[packet+2],dx	;				       ;AN007;
		   xor	ax,ax		; set for read			       ;AN007;
		   call Direct_Access	; to read it in 		       ;AN007;
;		   $if	nc,and		; no errors and 		       ;AN007;
		   JC $$IF190
		   mov	ax,[empty_cluster] ; update pointer to parent	       ;AN007;
		   lea	bx,DIR_SECTOR	;				       ;AN007;
		   mov	[bx + dir_first + size dir_entry],ax ;			 ;AN007;
		   xor	ax,ax		; set for write 		       ;AN007;
		   dec	ax		;				       ;AN007;
		   call Direct_Access	; to write it back		       ;AN007;
;		   $if	nc,and		; if no errors and		       ;AN007;
		   JC $$IF190
		   mov	ax,[dir_sector_low] ;				       ;AN007;
		   mov	[packet],ax	; recover current sector	       ;AN007;
		   mov	ax,[dir_sector_hi] ;				       ;AN007;
		   mov	[packet+2],ax	;				       ;AN007;
;		   $if	nc		; if no errors			       ;AN007;
		   JC $$IF190
		       call Direct_Access ; to continue where we left off      ;AN007;
;		   $endif		;				       ;AN007;
$$IF190:
;	       $exitif c		; quit if error (CF)		       ;AN007;
	       JNC $$IF188
;	       $orelse			;				       ;AN007;
	       JMP SHORT $$SR188
$$IF188:
		   mov	bx,[dir_offset] ; recover current entry 	       ;AN007;
		   add	bx,SIZE dir_entry ; advance to next entry	       ;AN007;
		   cmp	bx,OFFSET BUF	;				       ;AN007;
;	       $endloop a		; if past end of sector 	       ;AN007;
	       JNA $$DO188
$$EN188:
		   clc			; clear error flag		       ;AN007;
;	       $endsrch 		;				       ;AN007;
$$SR188:
;	   $leave c			; if error - quit		       ;AN007;
	   JC $$EN187
	       xor  ax,ax		;				       ;AN007;
	       mov  ax,[CSIZE]		; incriment sector count	       ;AN007;
	       inc  [sector_count]	;				       ;AN007;
	       cmp  [sector_count],al	;				       ;AN007;
;	   $exitif a			; past end of cluster		       ;AN007;
	   JNA $$IF187
	       clc			; clear error flag		       ;AN007;
	       mov  [sector_count],1	; reset sector count		       ;AN007;
;	   $orelse			;				       ;AN007;
	   JMP SHORT $$SR187
$$IF187:
	       xor  ax,ax		; set for read			       ;AN007;
	       add  WORD PTR [packet],1 ; advance to next sector (packet)      ;AN007;
	       adc  [packet+2],ax	; look after carry		       ;AN007;
	       call Direct_Access	; to read in next sector	       ;AN007;
	       lea  bx,DIR_SECTOR	; reset entry pointer		       ;AN007;
;	   $endloop c,long		; if error - quit		       ;AN007;
	   JC $$XL11
	   JMP $$DO187
$$XL11:
$$EN187:
;	   $endsrch			;				       ;AN007;
$$SR187:
;      $leave c 			; if error - quit		       ;AN007;
       JC $$EN186
	   mov	si,[DIR_cluster]	; get DIR_cluster		       ;AN007;
	   push [packet_sectors]	; save current packet stuff	       ;AN007;
	   push [packet_buffer] 	;				       ;AN007;
	   mov	ax,[FAT_sectors]	; update packet to FAT		       ;AN007;
	   mov	[packet_sectors],ax	;				       ;AN007;
	   mov	[packet_buffer],OFFSET BUF ;				       ;AN007;
	   mov	[cluster_high],1	; force FAT to be reloaded - if needed ;AN007;
	   call UNPACK			; to find next Sub DIR cluster	       ;AN007;
	   pop	[packet_buffer] 	; recover packet to DIR 	       ;AN007;
	   pop	[packet_sectors]	;				       ;AN007;
	   mov	ax,di			;				       ;AN007;
	   cmp	al,end_cluster		;				       ;AN007;
;      $exitif e			; at end of chain		       ;AN007;
       JNE $$IF186
	   clc				; clear error flag		       ;AN007;
;      $orelse				;				       ;AN007;
       JMP SHORT $$SR186
$$IF186:
	   mov	[DIR_cluster],ax	;				       ;AN007;
	   call cluster_2_sector	; to convert to sector		       ;AN007;
	   mov	[packet],ax		; update packet 		       ;AN007;
	   mov	[packet+2],dx		;				       ;AN007;
	   xor	ax,ax			; set for read			       ;AN007;
	   call Direct_Access		; to read first sector of next cluster ;AN007;
;      $leave c 			; if error			       ;AN007;
       JC $$EN186
	   lea	bx,DIR_SECTOR		; reset entry pointer		       ;AN007;
	   mov	[sector_count],1	; reset sector count		       ;AN007;
;      $endloop long			;				       ;AN007;
       JMP $$DO186
$$EN186:
;      $endsrch 			;				       ;AN007;
$$SR186:
;  $endif				;				       ;AN007;
$$IF185:
   mov	[DIR_cluster],0 		; reset Sub_DIR_cluster to 0	       ;AN007;

   ret					;				       ;AN007;

   Sub_DIR_Loop ENDP

   BREAK <SYS - Unpack >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Unpack
;*******************************************************************************
;
;Description: Read an entry in the FAT
;
;Called Procedures:
;
;		Check_FAT - to make sure right part of FAT is loaded (16 bit only)
;
;Input: 	Cluster number in SI
;
;Output:	Return contents in DI
;		xX destroyed
;		ZF set if cluster is free
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Unpack
;
;	if 16 bit FAT
;		call Check_FAT
;		multiply # by 2
;		read value
;		check if empty
;	else
;		multiply # by 2
;		read value
;		if not word alligned
;			shift to allign
;		endif
;		mask off unused portion (set ZF if empty)
;	endif
;
;	ret
;
;	END Unpack
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Unpack

   Unpack PROC NEAR

   lea	bx,BUF				;				       ;AN004;
   mov	di,si				;				       ;AN004;
   cmp	[BIGFAT],0			;				       ;AN004;
;  $if	nz				; if 16 bit FAT 		       ;AN004;
   JZ $$IF208
       push si				;				       ;AN004;
       call Check_FAT			; make sure right part of FAT loaded   ;AN004;
;      $if  nc				;				       ;AN004;
       JC $$IF209
	   mov	di,si			; Check_FAT ajusts si		       ;AN004;
	   shl	di,1			; Mult by 2			       ;AN004;
	   mov	di,WORD PTR [di+bx]	;				       ;AN004;
	   or	di,di			; Set zero			       ;AN004;
	   clc				;				       ;AN004;
;      $endif				;				       ;AN004;
$$IF209:
       pop  si				;				       ;AN004;
;  $else				; is 12 bit fat 		       ;AN004;
   JMP SHORT $$EN208
$$IF208:
       shr  di,1			;				       ;AN004;
       add  di,si			; Mult by 1.5			       ;AN004;
       mov  di,WORD PTR [di+bx] 	;				       ;AN004;
       test si,1			;				       ;AN004;
;      $if  nz				; not allign on cluster 	       ;AN004;
       JZ $$IF212
	   shr	di,1			;				       ;AN004;
	   shr	di,1			;				       ;AN004;
	   shr	di,1			;				       ;AN004;
	   shr	di,1			;				       ;AN004;
;      $endif				;				       ;AN004;
$$IF212:
       and  di,0FFFh			;				       ;AN004;
;  $endif				;				       ;AN004;
$$EN208:


   ret					;				       ;AN004;

   Unpack ENDP

   BREAK <SYS - Pack >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Pack
;*******************************************************************************
;
;Description:	Change an entry in the FAT
;
;Called Procedures:
;
;		Check_FAT - to make sure right part of FAT is loaded (16 bit only)
;
;Input: 	si - cluster number to be packed
;		dx - data to be placed in cluster (si)
;
;Output:	bx,dx	destroyed
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Pack
;
;	if 16 bit FAT
;		call Check_FAT
;		convert cluster # to offset
;		add offset of FAT
;		store value
;	else
;		convert cluster # to offset
;		add offset of FAT
;		recover current entry word
;		if not alligned on word boundary
;			shift to allign
;			mask off value to be replaced (byte)
;		else
;			mask off value to be replaced (word)
;		endif
;	combine new value and ballace
;	store the entry
;
;	ret
;
;	END Pack
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Pack

   Pack PROC NEAR

   lea	bx,BUF				;				       ;AN004;
   push si				;				       ;AN004;
   mov	di,si				;				       ;AN004;
   cmp	[BIGFAT],0			;				       ;AN004;
;  $if	nz				; 16 bit FAT			       ;AN004;
   JZ $$IF215
       call Check_FAT			; make sure the part of the FAT we want;AN004;
					;   is loaded & ajust offset to match  ;AN004;
       shl  si,1			; convert cluster # to offset	       ;AN004;
       add  si,bx			; add offset of FAT		       ;AN004;
       mov  [si],dx			; store value			       ;AN004;
       mov  [FAT_changed],1		; the fat has been changed	       ;AN004;
;  $else				; its 12 bit FAT		       ;AN004;
   JMP SHORT $$EN215
$$IF215:
       shr  si,1			;				       ;AN004;
       add  si,bx			;				       ;AN004;
       add  si,di			;				       ;AN004;
       shr  di,1			;				       ;AN004;
       mov  di,[si]			;				       ;AN004;
;      $if  c				; no alligned			       ;AN004;
       JNC $$IF217
	   shl	dx,1			;				       ;AN004;
	   shl	dx,1			;				       ;AN004;
	   shl	dx,1			;				       ;AN004;
	   shl	dx,1			;				       ;AN004;
	   and	di,0Fh			;				       ;AN004;
;      $else				;				       ;AN004;
       JMP SHORT $$EN217
$$IF217:
	   and	di,0F000h		;				       ;AN004;
;      $endif				;				       ;AN004;
$$EN217:
       or   di,dx			;				       ;AN004;
       mov  [si],di			;				       ;AN004;
;  $endif				;				       ;AN004;
$$EN215:
   pop	si				;				       ;AN004;

   ret					;				       ;AN004;

   Pack ENDP

   BREAK <SYS - Check_FAT >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Check_FAT
;*******************************************************************************
;
;Description:	Check that the protion of the FAT that is referenced in SI
;		is presently in memory.
;
;		Only 12 sectors of the FAT are kept in memory. If the requested
;		cluster does not fall within that range, 12 sectors of the FAT
;		are read into memory - the first cluster will contain the entry
;		of interest.
;
;Called Procedures:
;
;		none
;
;Input: 	si - cluster number to be checked
;		[FAT_changed] = 0 - no need to write out FAT before changing
;			      = x - must write before reading.
;
;
;Output:	appropriate block of FAT in BUF
;		si ajusted to match
;		NB: BX, DX preserved (for UNPACK)
;
;Change History: Created	7/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Check_FAT
;
;
;	ret
;
;	END  Check_FAT
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Check_FAT

   Check_FAT PROC  NEAR

   push bx
   cmp	si,[cluster_low]		;				       ;AN004;
;  $if	ae,and				;				       ;AN004;
   JNAE $$IF221
   cmp	si,[cluster_high]		;				       ;AN004;
;  $if	be				;				       ;AN004;
   JNBE $$IF221
       sub  si,[cluster_low]		;				       ;AN004;
;  $else				; the cluster is outside the range
   JMP SHORT $$EN221
$$IF221:
					;  of the part of the FAT presently loaded.
					; convert cluster # into sector + offset
					; by dividing the cluster # by # of entries
					; per sector IE: sector = 512 bytes
					;	     cluster entry = 2 bytes
					;	then # of entries/sector = 256

       cmp  [FAT_changed],0		;				       ;AN004;
;      $if  ne				;				       ;AN004;
       JE $$IF223
	   xor	ah,ah			;				       ;AN004;
	   dec	ah			;				       ;AN004;
	   call Direct_Access		; write it out - ignore errors	       ;AN004;
	   mov	ax,[FSIZE]		;				       ;AN004;
	   cmp	[FAT_2],0		;				       ;AN004;
;	   $if	e			;				       ;AN004;
	   JNE $$IF224
	       add  [packet],ax 	;				       ;AN004;
;	   $else			;				       ;AN004;
	   JMP SHORT $$EN224
$$IF224:
	       sub  [packet],ax 	;				       ;AN004;
	       mov  [FAT_2],0		; packet points to FAT #2	       ;AN004;
;	   $endif			;				       ;AN004;
$$EN224:
	   xor	ah,ah			;				       ;AN004;
	   dec	ah			;				       ;AN004;
	   call Direct_Access		; write it out - ignore errors	       ;AN004;
	   mov	[FAT_changed],0 	; FAT now cleared		       ;AN004;
;      $endif				;				       ;AN004;
$$IF223:
       mov  ax,si			;				       ;AN004;
       xor  cx,cx			;				       ;AN004;
       mov  cl,al			; this is a cheap and		       ;AN004;
       mov  al,ah			;  dirty divide by 256		       ;AN004;
       xor  ah,ah			;   ax = result 		       ;AN004;
       push ax				; save starting sector		       ;AN006;
       mov  si,cx			;   cx = remainder		       ;AN004;
       inc  ax				; leave room for boot sector	       ;AN004;
       mov  [packet],ax 		;				       ;AN004;
       mov  [packet+2],0		;				       ;AN004;
       push dx				;				       ;AN004;
       call Direct_Access		;				       ;AN004;
;      $if  c				;				       ;AN004;
       JNC $$IF228
	   mov	ax,[FSIZE]		;				       ;AN004;
	   add	[packet],ax		;				       ;AN004;
	   mov	[FAT_2],1		; packet points to FAT #2	       ;AN004;
	   call Direct_Access		;				       ;AN004;
;      $endif				;				       ;AN004;
$$IF228:
       pop  dx				;				       ;AN004;
       pop  ax				; recover starting sector	       ;AN006;
;      $if  nc				;				       ;AN004;
       JC $$IF230
	   xchg al,ah			; convert sector back to cluster       ;AN004;
	   mov	[cluster_low],ax	; new bottom of FAT		       ;AN004;
	   mov	[cluster_high],ax	;				       ;AN004;
	   add	[cluster_high],clusters_loaded ; new top of FAT 	       ;AN004;
;      $endif				;				       ;AN004;
$$IF230:
;  $endif				;				       ;AN004;
$$EN221:
   pop	bx


   ret					;				       ;AN004;

   Check_FAT ENDP

   CODE ENDS

   END
