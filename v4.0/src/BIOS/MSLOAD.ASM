
page	,132;
title	Non-Contiguous IBMBIO Loader (MSLOAD)
;==============================================================================
;REVISION HISTORY:
;AN000 - New for DOS Version 4.00 - J.K.
;AC000 - Changed for DOS Version 4.00 - J.K.
;AN00x - PTMs for DOS Version 4.00 - J.K.
;==============================================================================
;AN001; - P1820 New Message SKL file				   10/20/87 J.K.
;AN002; - D381	For SYS.COM, put the version number		   01/06/88 J.K.
;==============================================================================
;JK, 1987 -
;     For DOS 4.00, MSLOAD program has been changed to allow:
;	  1. 32 bit calculation,
;	  2. Reading a FAT sector when needed, instead of reading the whole FAT
;	     sectors at once.  This will make the Boot time faster, and eliminate
;	     the memory size limitation problem,
;	  3. Solving the limitation of the file size (29 KB) of IBMBIO.COM,
;	  4. Adding the boot error message.  Show the same boot error message
;	     and do the same behavior when the read operation of IBMBIO.COM
;	     failes as the MSBOOT program, since MSLOAD program is the
;	     extention of MSBOOT program.
;

IF1
	%OUT ASSEMBLING: Non-Contiguous IBMBIO Loader (MSLOAD)
	%OUT

ENDIF


DSKADR	= 1Eh * 4		;ROM bios diskette table vector position

bootseg 	segment at 0h


       org	7C00h
Boot_Sector	label	byte
bootseg 	ends


dosloadseg	segment at 70h
       org	00h
IBMBIO_Address	label   byte

dosloadseg	ends


cseg		segment public para 'code'
		assume	cs:cseg,ds:nothing,es:nothing,ss:nothing

include MSload.inc
include Bootform.inc		;AN000; Extended bpb, boot record defintion.
include versiona.inc		;AN001; Version number for SYS.COM

sec9	equ	522h		;;** 8/3/87 DCL

BIOOFF		equ	700h
;
org	0h

start:
	jmp Save_Input_Values
SYS_Version	dw	EXPECTED_VERSION ;AN001; From VERSIONA.INC file
Mystacks	dw	64 dup (0)	;AN000; local stack
MyStack_ptr	label	word

;local data
Number_Of_Heads 	dw	0
Size_Cluster		dw	0
Start_Sector_L	      dw      0
Start_Sector_H	      dw      0 		;J.K.
Temp_H			dw	0		;J.K. For 32 bit calculation
Temp_Cluster		dw	0		;J.K. Temporary place for cluster number
Last_Fat_SecNum 	dw	-1		;Fat sector number starting from the first fat entry.
Sector_Count		dw	0
Number_Of_FAT_Sectors	dw	0
Hidden_Sectors_L	dw	0
Hidden_Sectors_H	dw	0		;J.K.
Sector_Size		dw	0
Reserved_Sectors	dw	0
Last_Found_Cluster	dw	0
Next_BIO_Location	dw	0
First_Sector_L		dw	0
First_Sector_H		dw	0		;J.K.
Drive_Lim_L		dw	0		;J.K. Max. number of sectors
Drive_Lim_H		dw	0		;J.K.
Sectors_Per_Track	dw	0
Drive_Number		db	0
FAT_Size		db	0
Media_Byte		db	0
EOF			db	0
Org_Rom_Disktable	dd	0
FAT_Segment		dw	0
Sectors_Per_Cluster	db	0

subttl	Save Input Values
page
;***********************************************************************
;  Save_Input_Values
;***********************************************************************
;
; Input:     none
;
;   DL = INT 13 drive number we booted from
;   CH = media byte
;   BX = First data sector (low) on disk (0-based)
;   DS:SI = Original ROM BIOS DISKETTE Parameter table.
;J.K. 6/2/87 If an extended Boot Record, then AX will be the First data sector
;J.K. high word.  Save AX and set First_Sector_H according to AX if it is an
;J.K. extended boot record.
;   AX = First data sector (High) on disk ;
; Output:
;
;   BX = first data sector on disk
;
;   Media_Byte = input CH
;   Drive_Number = input DL
;   First_Sector_L = input BX
;   First_Sector_H = input AX, if an extended Boot record.;J.K.
;   Drive_Lim_L = maximum sector number in this media ;J.K.
;   Drive_Lim_H = high word of the above
;   Hidden_Sectors_L = hidden secotrs
;   Hidden_Sectors_H
;   Reserved_Sectors = reserved sectors
;   Sectors_Per_Track = Sectors/track
;   Number_Of_Heads = heads/cylinder
;
;   DS = 0
;   AX,DX,SI destroyed
;
; Calls:     none
;-----------------------------------------------------------------------
;Function:
; Save input information and BPB informations from the boot record.
;
;----------------------------------------------------------------------
Save_Input_Values:


	mov	First_Sector_L,bx	   ;AC000;
	mov	media_Byte,ch
	mov	Drive_Number,dl
	mov	word ptr Org_Rom_Disktable, si
	push	ds
	pop	word ptr Org_Rom_Disktable+2
	xor	cx,cx				;Segment 0
	mov	ds,cx
	assume	ds:Bootseg

	push	es				;;** DCL 8/3/87
	mov	es,cx				;;** DCL 8/3/87
	assume	es:Bootseg			;;** DCL 8/3/87

	MOV	SI,WORD PTR DS:DSKADR	;			  ARR 2.41
	MOV	DS,WORD PTR DS:DSKADR+2 ; DS:SI -> CURRENT TABLE  ARR 2.41

	MOV	DI,SEC9 		; ES:DI -> NEW TABLE	  ARR 2.41
	MOV	CX,11	   ; taken from ibmboot.asm		  ARR 2.41
	CLD				;
	REP	MOVSB			; COPY TABLE		  ARR 2.41
	PUSH	ES			;			  ARR 2.41
	POP	DS			; DS = 0		  ARR 2.41

	MOV	WORD PTR DS:DSKADR,SEC9 ;			  ARR 2.41
	MOV	WORD PTR DS:DSKADR+2,DS ; POINT DISK PARM VECTOR TO NEW TABLE
	pop	es			;;** DCL 8/3/87
	assume	es:nothing

	mov	cx,Boot_Sector.EXT_BOOT_BPB.EBPB_BYTESPERSECTOR      ;AN000;
	mov	cs:Sector_Size, cx				     ;AN000;
	mov	cl,Boot_Sector.EXT_BOOT_BPB.EBPB_SECTORSPERCLUSTER   ;AN000;
	mov	cs:Sectors_Per_Cluster, cl			     ;AN000;
	mov	cx,Boot_Sector.EXT_BOOT_BPB.EBPB_SECTORSPERTRACK     ;Get Sectors per track
	mov	cs:Sectors_Per_Track,cx
	mov	cx,Boot_Sector.EXT_BOOT_BPB.EBPB_HEADS		     ;Get BPB heads per cylinder
	mov	cs:Number_Of_Heads,cx
	mov	cx,Boot_Sector.EXT_BOOT_BPB.EBPB_SECTORSPERFAT	     ;Get sectors per FAT
	mov	cs:Number_Of_FAT_Sectors,cx
	mov	cx,Boot_Sector.EXT_BOOT_BPB.EBPB_RESERVEDSECTORS     ;Get Reserved Sectors
	mov	cs:Reserved_Sectors,cx
	mov	cx,word ptr Boot_Sector.EXT_BOOT_BPB.EBPB_HIDDENSECTOR	 ;Get hidden sectors
	mov	cs:Hidden_Sectors_L,cx
	mov	cx, Boot_Sector.EXT_BOOT_BPB.EBPB_TOTALSECTORS	     ;AN000;
	mov	cs:Drive_Lim_L, cx				     ;AN000;

;J.K. First of all, check if it the boot record is an extended one.
;J.K. This is just a safe guard in case some user just "copy" the 4.00 IBMBIO.COM
;J.K. to a media with a conventional boot record.

	cmp	Boot_Sector.EXT_BOOT_SIG, EXT_BOOT_SIGNATURE		;AN000;
	jne	Relocate						;AN000;
	mov	cs:First_Sector_H, AX					;AN000; start data sector (high)
	mov	ax,word ptr Boot_Sector.EXT_BOOT_BPB.EBPB_HIDDENSECTOR+2  ;AN000;
	mov	cs:Hidden_Sectors_H,ax					  ;AN000;
	cmp	cx, 0							;AN000; CX set already before (=Totalsectors)
	jne	Relocate						;AN000;
	mov	ax, word ptr Boot_Sector.EXT_BOOT_BPB.EBPB_BIGTOTALSECTORS   ;AN000;
	mov	cs:Drive_Lim_L, ax					     ;AN000;
	mov	ax, word ptr Boot_Sector.EXT_BOOT_BPB.EBPB_BIGTOTALSECTORS+2 ;AN000;
	mov	cs:Drive_Lim_H, ax					  ;AN000;
subttl	Relocate
page
;
;***********************************************************************
;  RELOCATE
;***********************************************************************
;
; Notes:
;
;   Relocate the loader code to top-of-memory.
;
; Input:     none
;
; Output:    Code and data relocated.
;	     ax,cx,si,di destroyed
;
; Calls:     none
;-----------------------------------------------------------------------
; Copy code from Start to Top of memory.
;
; The length to copy is Total_length
;
; Jump to relocated code
;-----------------------------------------------------------------------
;
Relocate:
	assume	ds:nothing
	cld				;AN000;
	xor	si,si			;AN000;
	mov	di,si			;AN000;
;SB34LOAD000****************************************************************
;SB  Determine the number of paragraphs (16 byte blocks) of memory.
;SB	This involves invoking the memory size determination interrupt,
;SB	which returns the number of 1K blocks of memory, and then
;SB	converting this to the number of paragraphs.
;SB	Leave the number of paragraphs of memory in AX.

	int	12h			;get system memory size in Kbytes
	mov	cl,6			;
	shl	ax,cl			;memory size in paragraphs
;SB34LOAD000****************************************************************
	mov	cl,4			;AN000;
	mov	dx, cs:Sector_Size	;AN000;
	shr	dx,cl			;AN000;
	inc	dx			;AN000;
	sub	ax, dx			;AN000;
	mov	cs:Fat_Segment, ax	;AN000;This will be used for FAT sector
	mov	dx, offset total_length ;AN000;
	shr	dx, cl			;AN000;
	inc	dx			;AN000;
	sub	ax, dx			;AN000;
	mov	es, ax			;AN000;es:di -> place be relocated.
	push	cs			;AN000;
	pop	ds			;AN000;ds:si -> source
	mov	cx, offset total_length ;AN000;
	rep	movsb			;AN000;

	push	es			;AN000;
	mov	ax, offset Setup_stack	;AN000;
	push	ax			;AN000;massage stack for destination of cs:ip
Dumbbb	proc	far			;AN000;
	ret				;AN000;
Dumbbb	endp				;AN000;


;	 push	 cs				 ;Set up ds segreg
;	 pop	 ds
;	 xor	 ax,ax				 ;Set up ES segreg
;	 mov	 es,ax
;
;	 assume  es:bootseg,ds:cseg
;
;	 mov	 si,offset Start		 ;Source
;	 mov	 di,offset Relocate_Start	 ;Target
;	 mov	 cx,Relocate_Length		 ;Length
;	 rep	 movsb				 ;Go do it
;	 jmp	 far ptr Relocate_Start



subttl	Setup Stack
page
;***********************************************************************
;  Setup_Stack
;***********************************************************************
;
; Input:     none
;
; Output:
;
;   SS:SP set
;   AX destroyed
;-----------------------------------------------------------------------
; First thing is to reset the stack to a better and more known place.
;
; Move the stack to just under the boot record and relocation area (0:7C00h)
;
; Preserve all other registers
;----------------------------------------------------------------------

Setup_Stack:
	assume	ds:nothing, es:nothing, ss:nothing
;	 CLI				 ;Stop interrupts till stack ok
	mov	ax,cs
	MOV	SS,AX			;Set up the stack to the known area.
	mov	sp, offset MyStack_Ptr
;	 MOV	 SP,7C00h - 50		 ;Leave room for stack frame
;	 MOV	 BP,7C00h - 50		 ;Point BP as stack index pointer
;	 STI

subttl	Find_Cluster_Size
page
;***********************************************************************
;  Find_Cluster_Size
;***********************************************************************
;
; Input:     BPB information in loaded boot record at 0:7C00h
;
; Output:
;
;	DS = 0
;	AX = Bytes/Cluster
;	BX = Sectors/Cluster
;	SI destroyed
; Calls:     none
;-----------------------------------------------------------------------
;
; Get Bytes/sector from BPB
;
; Get sectors/cluster from BPB
;
; Bytes/cluster = Bytes/sector * sector/cluster
;----------------------------------------------------------------------
Find_Cluster_Size:

;For the time being just assume the boot record is valid and the BPB
;is there.

	xor	ax,ax				;Segment 0
	mov	ds,ax

	assume ds:bootseg

	mov	ax,Boot_Sector.EXT_BOOT_BPB.EBPB_BYTESPERSECTOR    ;AC000;Get BPB bytes/sector
	xor	bx,bx
	mov	bl,Boot_Sector.EXT_BOOT_BPB.EBPB_SECTORSPERCLUSTER ;AC000;Get sectors/cluster
	mul	bx				;Bytes/cluster
	mov	cs:Size_Cluster,ax		;Save it


subttl	Determine FAT size
page
;***********************************************************************
;  Determine_FAT_Size
;***********************************************************************
;
; Notes:
;
;   Determine if FAT is 12 or 16 bit FAT. 12 bit FAT if floppy, read MBR
;   to find out what system id byte is.
;
; Input:
;
; Output:
;
;   cs:Fat_Size = FAT12_bit or FAT16_bit
;   All other registers destroyed
;
;----------------------------------------------------------------------
Determine_FAT_Size:
	mov	cs:FAT_Size,FAT12_bit		;AN000;Assume 12 bit fat
	mov	dx, cs:Drive_Lim_H		;AN000;
	mov	ax, cs:Drive_Lim_L		;AN000;
	sub	ax, cs:Reserved_Sectors 	;AN000;
	sbb	dx, 0				;AN000;now, dx;ax = available total sectors
	mov	bx, cs:Number_Of_FAT_Sectors	;AN000;
	shl	bx, 1				;AN000;2 FATs
	sub	ax, bx				;AN000;
	sbb	dx, 0				;AN000;now, dx;ax = tatal sectors - fat sectors
	mov	bx, Boot_Sector.EXT_BOOT_BPB.EBPB_ROOTENTRIES ;AN000;
	mov	cl, 4				;AN000;
	shr	bx, cl				;AN000;Sectors for dir entries = dir entries / Num_DIR_Sector
	sub	ax, bx				;AN000;
	sbb	dx, 0				;AN000;
	xor	cx, cx				;AN000;
	mov	cl, Boot_Sector.EXT_BOOT_BPB.EBPB_SECTORSPERCLUSTER ;AN000;
	push	ax				;AN000;
	mov	ax, dx				;AN000;
	xor	dx, dx				;AN000;
	div	cx				;AN000;
	mov	cs:Temp_H, ax			;AN000;
	pop	ax				;AN000;
;J.K. We assume that cx > dx.
	div	cx				;AN000;
	cmp	ax, 4096-10			;AN000;
;	 jb	 Determine_First_Cluster	 ;AN000;
	jb	Read_In_FirstClusters
	mov	cs:FAT_Size, FAT16_Bit		;AN000;16 bit fat

;	 cmp	 cs:Media_Byte,0F8h		 ;Is it floppy
;	 jne	 FAT_Size_Found 		 ;Yep, all set
;	 mov	 cs:Logical_Sector,0		 ;Got hardfile, go get MBR
;	 xor	 ax,ax
;	 mov	 es,ax
;	 mov	 di,offset Relocate_Start
;	 mov	 cs:Sector_Count,1
;	 call	 Disk_Read
;	 mov	 si,offset Relocate_Start+1C2h
;	 mov	 cx,4
;	 xor	 ax,ax
;	 mov	 ds,ax
;Find_Sys_Id:
;	 mov	 cs:FAT_Size,FAT12_bit		     ;Assume 12 bit fat
;	 cmp	 byte ptr [si],1
;	 je	 FAT_Size_Found
;	 mov	 cs:FAT_Size,FAT16_bit		     ;Assume 12 bit fat
;	 cmp	 byte ptr [si],4
;	 je	 Fat_Size_Found
;	 add	 si,16
;	 loop	 Find_Sys_Id
;	;xxxxxxxxxxxxxxxxxxxxxxxxxx error
;FAT_Size_Found:


subttl Read_In_FirstClusters
page
;***********************************************************************
;  Read_In_FirstClusters
;***********************************************************************
;
; Notes: Read the start of the clusters that covers at least IBMLOADSIZE
;	 fully.  For example, if sector/cluster = 2, and IBMLOADSIZE=3
;	 then we are going to re-read the second cluster to fully cover
;	 MSLOAD program in the cluster boundary.
;
; Input:
;   IBMLOADSIZE - Make sure this value is the same as the one in
;		  MSBOOT program when you build the new version!!!!!
;
;   Sectors_Per_Cluster
;   Size_Cluster
;   First_Sector_L
;   First_Sector_H
;
; Output: MSLOAD program is fully covered in a cluster boundary.
;	  AX = # of clusters we read in so far.
;
; Calls:     Disk_Read
; Logic:
;	AX; DX = IBMLOADSIZE / # of sector in a cluster.
;	if DX = 0 then Ok. (MSLOAD is in a cluster boundary.)
;      else		   (Has to read (AX+1)th cluster to cover MSLOAD)
;	read (AX+1)th cluster into the address after the clusters we
;	read in so far.
;-----------------------------------------------------------------------

Read_In_FirstClusters:
	mov	ax, IBMLOADSIZE 			;AN000;
	div	cs:Sectors_Per_Cluster			;AN000;
	cmp	ah, 0					;AN000;
	je	Set_Next_Cluster_Number 		;AN000;
	xor	ah, ah					;AN000;
	push	ax					;AN000;
	mov	cx, cs:First_Sector_L			;AN000;
	mov	cs:Start_Sector_L, cx			;AN000;
	mov	cx, cs:First_Sector_H			;AN000;
	mov	cs:Start_Sector_H, cx			;AN000;
	mul	cs:Sectors_Per_Cluster			;AN000; Now, AX=# of sectors
	add	cs:Start_Sector_L, ax			;AN000;
	adc	cs:Start_Sector_H, 0			;AN000;
	pop	ax					;AN000;
	push	ax					;AN000;
	mov	di, BIOOFF				;AN000;
	mul	cs:Size_Cluster 			;AN000;AX = # of bytes read in before this cluster
	add	di, ax					;AN000;
	xor	ax, ax					;AN000;
	mov	es, ax					;AN000;
	mov	al, cs:Sectors_Per_Cluster		;AN000;
	mov	cs:Sector_Count, ax			;AN000;
	call	Disk_Read				;AN000;
	pop	ax					;AN000;
	inc	ax					;AN000;# of clusters read in so far.

subttl Set_Next_Cluster_Number
page
;***********************************************************************
;  Set_Next_Cluster_Number
;***********************************************************************
;
; Notes: Set LAST_Found_Cluster for the next use.
;	 Last_Found_Cluster is the cluster number we are in now.
;	 Since cluster number is 0 based and there are 2 clusters int
;	 the beginning of FAT table used by the system, we just add
;	 1 to set Last_Found_Cluster.
;
; Input:
;   AX = # of clusters read in so far.
;
; Output:
;
;   cs:Last_Found_Cluster
;
; Calls:     none
;------------------------------------------------------------------
Set_Next_Cluster_Number:
	inc	ax			      ;AN000; For Last_Found_Cluster
	mov	cs:Last_Found_Cluster,ax      ;2 is the first data cluster number(0 based)

subttl	Read In FAT
page
;***********************************************************************
;  Read_In_FAT
;***********************************************************************
;
; Notes:
;
;   Reads in the entire FAT at 800:0. This gives the relocated portion
;   of this loader a maximum size of 768 bytes (8000 - 7D00).
;   With 64 KB memory system, this can support maximum size of FAT to
;   be 32 KB.  We assumes that the system memory size be 128 KB, if
;   the system has a big media with the total fat size bigger than
;   32 KB.
;
; Input:     none
;
; Output:
;
;   ES = 0
;   All sectors destroyed
;
; Calls:  READ DISK
;-----------------------------------------------------------------------
; Get number of sectors in FAT
;
; Set ES:DI to 800:0
;
; Read in the sectors
;
;----------------------------------------------------------------------
;Read_In_FAT:
;	 mov	 ax,cs:Number_Of_FAT_Sectors   ;Get sectors/FAT
;	 mov	 cs:Sector_Count,ax	       ;Number of sectors to read
;	 mov	 ax,cs:Hidden_Sectors_L        ;Hidden+Reserved = start of FAT sector
;	 mov	 dx,cs:Hidden_Sectors_H        ;AN000;
;	 add	 ax,cs:Reserved_Sectors
;	 adc	 dx, 0
;	 mov	 cs:Start_Sector_L,ax	     ;AC000;Save it, setup for disk read
;	 mov	 cs:Start_Sector_H,dx	     ;AN000;
;	 mov	 di, 800h			 ;AC000;
;	 mov	 es, di 			 ;AC000;
;	 xor	 di, di 			 ;AC000;
;	 assume  es:nothing
;	 call	 Disk_Read
;
subttl	Keep Loaded BIO
page
;***********************************************************************
;  KEEP LOADED BIO
;***********************************************************************
;
; Notes:
;
;   Determine how much of IBMBIO was loaded in when the loader was loaded
;   by the boot record (only the portion that is guaranteed to be contiguous)
;
; Input:
;
;   cs:Last_Found_Cluster = number of clusters used for loader+2
;
; Output:
;	ES=70h
;	DI = Next offset to load IBMBIO code
;	AX,BX,CX,DX,SI destroyed
;
;	cs:Next_BIO_Location = DI on output
;	cs:Last_Cluster = last cluster loaded
;
; Calls:     none
;-----------------------------------------------------------------------
;Number of clusters loaded+2 is in cs:Last_Found_Cluster
;
;Multiply cluster * cluster size in bytes to get total loaded for MSLOAD
;
;Subtract TOTAL_LOADED - LOADBIO_SIZE to get loaded IBMBIO in last cluster
;
;Relocate this piece of IBMBIO down to 70:0
;
;----------------------------------------------------------------------
Keep_Loaded_BIO:
	push	ds
	mov	ax,cs:Last_Found_Cluster	;Point to last cluster loaded
	sub	ax,1				;Get number of clusters loaded
	mul	cs:Size_Cluster 		;Get total bytes loaded by
						;This is always < 64k, so
						;lower 16 bits ok
	sub	ax,LoadBio_Size 		;Get portion of IBMBIO loaded
	mov	cx,ax				;Save length to move
	mov	ax,70h				;Segment at 70h
	mov	ds,ax
	mov	es,ax
	mov	si,offset Total_Length		;Point at IBMBIO
	mov	di,0				;Point at 70:0
	rep	movsb				;Relocate this code
	mov	cs:Next_Bio_Location,di 	;Save where to load next
	pop	ds

subttl Get Contiguous Clusters
page
;***********************************************************************
;  Get_Contiguous_Clusters
;***********************************************************************
;
; Notes: Go find clusters as long as they are contiguous
;
;
; Input:
;
;   cs:Next_BIO_Location
;   cs:
;
;
; Output:
;
;
; Calls: Get_Next_FAT_Entry
;-----------------------------------------------------------------------
;
;Set cs:Sector_Count to Sectors per cluster
;
;Call Get_Next_FAT_Entry to get next cluster in file
;
;Call Check_for_EOF
;
;IF (NC returned)
;
;   {Call Get_Next_FAT_Entry
;
;    IF (New cluster is contig to old cluster)
;	{Add sectors per cluster to cs:Sector_Count
;
;	 Call Check_For_EOF
;
;	 IF (NC returned)
;
;
;----------------------------------------------------------------------
Get_Contiguous_Cluster:
	xor	ah,ah
	mov	al,cs:Sectors_Per_Cluster	;Assume we will get one cluster
	mov	cs:Sector_Count,ax
	push	cs:Sector_Count
	call	Get_Next_Fat_Entry	;Go get it in AX
	pop	cs:Sector_Count
	mov	cs:Last_Found_Cluster,ax ;Update the last one found
	cmp	cs:EOF,END_OF_FILE
	je	GO_IBMBIO

;	 je	 GOTO_IBMBIO
;Got_Contig_Clusters:

	xor	dx,dx			;AN000;
	sub	ax,2			;Zero base the cluster
	xor	ch,ch
	mov	cl,cs:Sectors_Per_Cluster ;Get sectors per cluster
	mul	cx			;Get how many
	add	ax,cs:First_Sector_L	;AC000;See where the data sector starts
	adc	dx,cs:First_Sector_H	;AN000;
	mov	cs:Start_Sector_L,ax	;AC000;Save it
	mov	cs:Start_Sector_H,dx	;AN000;
	mov	di,cs:Next_Bio_Location ;Get where to put code
	push	cs:Sector_Count 	;Save how many sectors
	mov	ax,dosloadseg		;Get area to load code
	mov	es,ax
	call	Disk_Read
	pop	ax			;Get back total sectors read in
;	jc	##########
	mul	cs:Sector_Size		;AC000;Get number of bytes we loaded
;	 mul	 Boot_Sector.ByteSec
	add	cs:Next_Bio_Location,ax ;Point to where to load next
	jmp	Get_Contiguous_Cluster

subttl	GOTO IBMBIO
page
;***********************************************************************
;  GOTO_IBMBIO
;***********************************************************************
;
; Notes:
;
;  Set up required registers for IBMBIO, then jump to it (70:0)
;
; Input:     none
;
;   cs:Media_Byte = media byte
;   cs:Drive_Number = INT 13 drive number we booted from
;   cs:First_Sector_L = First data sector on disk (Low) (0-based)
;   cs:First_Sector_H = First data sector on disk (High)
;
; Output:
;
;   Required by MSINIT
;   DL = INT 13 drive number we booted from
;   CH = media byte
;   BX = First data sector on disk (0-based)
;   AX = First data sector on disk (High)
;   DI = Sectors/FAT for the boot media.
;
; Calls:     none
;-----------------------------------------------------------------------
;
; Set up registers for MSINIT then do Far Jmp
;
;----------------------------------------------------------------------
GO_IBMBIO:
	mov	ch,cs:Media_Byte	;Restore regs required for MSINT
	mov	dl,cs:Drive_Number	;Physical Drive number we booted from.
	mov	bx,cs:First_Sector_L	;AC000;
	mov	ax,cs:First_Sector_H	;AN000; AX will be the First data sector (High)
;J.K. Don't need this information any more.
;	mov	di,cs:Number_Of_FAT_Sectors ;AN000
	jmp	far ptr IBMBIO_Address


subttl	Disk Read
page
;***********************************************************************
; Disk_Read
;***********************************************************************
;
; Notes:
;
;  Read in the cs:Sector_Count number of sectors at ES:DI
;
;
; Input:     none
;
;   DI = Offset of start of read
;   ES = Segment of read
;   cs:Sector_Count = number of sectors to read
;   cs:Start_sector_L = starting sector (Low)
;   cs:Start_sector_H = starting sector (High)
;   Following is BPB info that must be setup prior to call
;   cs:Number_Of_Heads
;   cs:Number_Of_Sectors
;   cs:Drive_Number
;   cs:Sectors_Per_Track
;
; Output:
;
;   AX,BX,CX,DX,SI,DI destroyed
;-----------------------------------------------------------------------
; Divide start sector by sectors per track
; The remainder is the actual sector number, 0 based
;
; Increment actual sector number to get 1 based
;
; The quotient is the number of tracks - divide by heads to get the cyl
;
; The remainder is actual head, the quotient is cylinder
;
; Figure the number of sectors in that track, set AL to this
;
; Do the read
;
; If Error, Do RESET, then redo the INT 13h
;
; If successful read, Subtract # sectors read from Sector_Count, Add to Logical
; Sector, add #sectors read * Sector_Size to BX;
;
; If Sector_Count <> 0 Do next read
;----------------------------------------------------------------------
Disk_Read:

;
; convert a logical sector into Track/sector/head.  AX has the logical
; sector number
;
DODIV:
	MOV	cx,5			;5 retries

Try_Read:
	PUSH	cx			;Save it
	MOV	AX,cs:Start_Sector_L	;AC000; Get starting sector
	mov	dx, cs:Start_Sector_H	;AN000;
;	 XOR	 DX,DX
	push	ax			;AN000;
	mov	ax, dx			;AN000;
	xor	dx, dx			;AN000;
	DIV	word ptr cs:Sectors_Per_Track
	mov	cs:Temp_H, ax	      ;AN000;
	pop	ax			;AN000;
	div	word ptr cs:Sectors_Per_Track  ;AN000;[temp_h];AX = track, DX = sector number
	MOV	bx,cs:Sectors_Per_Track ;Get number of sectors we can read in
	sub	bx,dx			;this track
	mov	si,bx
	cmp	cs:Sector_Count,si    ;Is possible sectors in track more
	jae	Got_Length		;than what we need to read?
	mov	si,cs:Sector_Count    ;Yes, only read what we need to
Got_Length:
	INC	DL			; sector numbers are 1-based
	MOV	bl,dl			;Start sector in DL
	mov	dx, cs:Temp_H	      ;AN000;now, dx;ax = track
;	 XOR	 DX, DX
	push	ax			;AN000;
	mov	ax, dx			;AN000;
	xor	dx, dx			;AN000;
	DIV	word ptr cs:Number_Of_Heads  ;Start cyl in ax,head in DL
	mov	cs:Temp_h, ax	      ;AN000;
	pop	ax			;AN000;
	div	word ptr cs:Number_of_Heads ;AN000;now [temp_h];AX = cyliner, dx = head
;J.K. At this moment, we assume that Temp_h = 0, AX <= 1024, DX <= 255
	MOV	DH,DL
;
; Issue one read request.  ES:BX have the transfer address, AL is the number
; of sectors.
;
	MOV	CL,6
	SHL	AH,CL			;Shift cyl high bits up
	OR	AH,BL			;Mix in with sector bits
	MOV	CH,AL			;Setup Cyl low
	MOV	CL,AH			;Setup Cyl/high - Sector
	mov	bx,di			;Get back offset
	MOV	DL,cs:Drive_Number    ;Get drive
	mov	ax,si			;Get number of sectors to read (AL)

	MOV	AH,2			;Read
	push	ax			;Save length of read
	push	di
; Issue one read request.  ES:BX have the transfer address, AL is the number
; of sectors.
	INT	13H
	pop	di
	pop	ax
	pop	cx			;Get retry count back
	jnc	Read_OK
	mov	bx,di			;Get offset
	xor	ah,ah
	push	cx
	mov	dl,cs:Drive_Number
	push	di
	int	13h
	pop	di
	pop	cx
;	 loop	 Try_Read		 ;AC000;
       ;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx error
	dec	cx			;AN000;
	jz	Read_Error		;AN000;
	jmp	Try_Read		;AN000;
Read_Error:				;AN000;
	jmp	ErrorOut		;AN000;

Read_OK:
	xor	ah,ah			;Mask out read command, just get # read
	sub	cs:Sector_Count,ax	;Bump number down
	jz	Read_Finished
	add	cs:Start_Sector_L,ax	;AC000;Where to start next time
	adc	cs:Start_Sector_H, 0	;AN000;
	xor	bx,bx			  ;Get number sectors read
	mov	bl,al
	mov	ax,cs:Sector_Size	;Bytes per sector
	mul	bx			  ;Get total bytes read
	add	di,ax			  ;Add it to offset
	jmp	DODIV
Read_Finished:
	RET

subttl	GET NEXT FAT ENTRY
page
;***********************************************************************
;  GET_NEXT_FAT_ENTRY
;***********************************************************************
;
; Notes:
;
;   Given the last cluster found, this will return the next cluster of
;   IBMBIO. If the last cluster is (F)FF8 - (F)FFF, then the final cluster
;   of IBMBIO has been loaded, and control is passed to GOTO_IBMBIO
;   MSLOAD can handle maximum FAT area size of 64 KB.
;
; Input:
;
;    cs:Last_Found_Cluster
;    cs:Fat_Size
;
; Output:
;
;   cs:Last_Found_Cluster (updated)
;
; Calls:  Get_Fat_Sector
;-----------------------------------------------------------------------
; Get Last_Found_Cluster
;
; IF (16 bit FAT)
;    {IF (Last_Found_Cluster = FFF8 - FFFF)
;	 {JMP GOTO_IBMBIO}
;     ELSE
;	{Get offset by multiply cluster by 2}
;
; ELSE
;    {IF (Last_Found_Cluster = FF8 - FFF)
;	 {JMP GOTO_IBMBIO}
;     ELSE
;	{Get offset by	- multiply cluster by 3
;
;	 Rotate right to divide by 2
;
;	 IF (CY set - means odd number)
;	    {SHR 4 times to keep high twelve bits}
;
;	 ELSE
;	    {AND with 0FFFh to keep low 12 bits}
;	}
;    }
;
;
;----------------------------------------------------------------------
Get_Next_FAT_Entry:

	push	es				;AN000;
	mov	ax, cs:FAT_Segment		;AN000;
	mov	es, ax				;AN000; es-> Fat area segment
	assume	es:nothing

	mov	cs:EOF,End_Of_File		;Assume last cluster
	mov	ax,cs:Last_Found_Cluster	;Get last cluster
	cmp	cs:Fat_Size,FAT12_bit
	jne	Got_16_Bit
	mov	si, ax				;AN000;
	shr	ax, 1				;AN000;
	add	si, ax				;AN000; si = ax*1.5 = ax+ax/2
	call	Get_Fat_Sector			;AN000;
	jne	Ok_cluster			;AN000;
	mov	al, byte ptr es:[bx]		;AN000;
	mov	byte ptr cs:Temp_cluster, al	;AN000;
	inc	si				;AN000;
	call	Get_Fat_Sector			;AN000;read next FAT sector
	mov	al, byte ptr es:[0]		;AN000;
	mov	byte ptr cs:Temp_cluster+1, al	    ;AN000;
	mov	ax, cs:Temp_cluster		    ;AN000;
	jmp	short Even_Odd			;AN000;
Ok_cluster:					;AN000;
	mov	ax, es:[bx]			;AN000;
Even_Odd:					;AN000;

;	 xor	 bx,bx
;	 mov	 bl,3				 ;Mult by 3
;	 mul	 bx
;	 shr	 ax,1				 ;Div by 2 to get 1.5
;	 mov	 si,ax				 ;Get the final buffer offset
;	 mov	 ax,[si]+8000h			 ;Get new cluster

	test	cs:Last_Found_Cluster,1 	;Was last cluster odd?
	jnz	Odd_Result			;If Carry set it was odd
	and	ax,0FFFh			;Keep low 12 bits
	jmp	short Test_EOF			;

Odd_Result:
	 mov	cl,4				;AN000;Keep high 12 bits for odd
	 shr	ax,cl
Test_EOF:
	 cmp	 ax,0FF8h			 ;Is it last cluster?
	 jae	 Got_Cluster_Done		 ;Yep, all done here
	 jmp	short Not_Last_CLuster

Got_16_Bit:
	shl	ax,1				;Multiply cluster by 2
	mov	si,ax				;Get the final buffer offset
	call	Get_Fat_Sector			;AN000;
	mov	ax, es:[bx]			;AN000;
;	 mov	 ax,[si]+8000h			;Get new cluster
	cmp	ax,0FFF8h
	jae	Got_Cluster_Done

Not_Last_Cluster:
	mov	cs:EOF,not END_OF_FILE		  ;Assume last cluster

Got_Cluster_Done:
	pop	es
	ret


Get_Fat_Sector	proc	near
;Function: Find and read the corresponding FAT sector into ES:0
;In). SI = offset value (starting from FAT entry 0) of FAT entry to find.
;     ES = FAT sector segment
;     cs:Sector_Size
;Out). Corresponding FAT sector read in.
;      BX = offset value of the corresponding FAT entry in the FAT sector.
;      CX destroyed.
;      Zero flag set if the FAT entry is splitted, i.e. when 12 bit FAT entry
;      starts at the last byte of the FAT sector.  In this case, the caller
;      should save this byte, and read the next FAT sector to get the rest
;      of the FAT entry value.	(This will only happen with the 12 bit fat).

	push	ax			;AN000;
	push	si			;AN000;
	push	di			;AN000;
	push	dx			;AN000;
	xor	dx, dx			;AN000;
	mov	ax, si			;AN000;
	mov	cx, cs:Sector_Size	;AN000;
	div	cx			;AN000;ax = sector number, dx = offset
	cmp	ax, cs:Last_Fat_SecNum	;AN000;the same fat sector?
	je	GFS_Split_Chk		;AN000;don't need to read it again.
	mov	cs:Last_Fat_SecNum, ax	;AN000;
	push	dx			;AN000;
	xor	dx, dx			;AN000;
	add	ax, cs:Hidden_Sectors_L ;AN000;
	adc	dx, cs:Hidden_Sectors_H ;AN000;
	add	ax, cs:Reserved_Sectors ;AN000;
	adc	dx, 0			;AN000;
	mov	cs:Start_Sector_L, ax	;AN000;
	mov	cs:Start_Sector_H, dx	;AN000;set up for Disk_Read
	mov	cs:Sector_Count, 1	;AN000;1 sector
	xor	di, di			;AN000;
	call	Disk_Read		;AN000;
	pop	dx			;AN000;
	mov	cx, cs:Sector_Size	;AN000;
GFS_Split_Chk:				;AN000;
	dec	cx			;AN000;now, cx= sector size - 1
	cmp	dx, cx			;AN000;if the last byte of the sector, then splitted entry.
	mov	bx, dx			;AN000;Set BX to DX
	pop	dx			;AN000;
	pop	di			;AN000;
	pop	si			;AN000;
	pop	ax			;AN000;
	ret				;AN000;
Get_Fat_Sector	endp			;AN000;


Errorout:				;AN000;
	push	cs			;AN000;
	pop	ds			;AN000;
	mov	si, offset Sysmsg	;AN000;
	call	write			;AN000;
;SB34LOAD001****************************************************************
;SB  Wait for a keypress on the keyboard. Use the BIOS keyboard interrupt.
;SB	2 LOCS

	xor	ah,ah
	int	16h			;read keyboard
;SB34LOAD001****************************************************************

;SB34LOAD002****************************************************************
;SB  We have to restore the address of the original rom Disk parameter table
;SB  to the location at [0:DSKADR].  The address of this original table has been
;SB  saved previously in 0:Org_Rom_DiskTable and 0:Org_Rom_Disktable+2.
;SB  After this table address has been restored we can reboot by
;SB  invoking the bootstrap loader BIOS interrupt.

	xor	bx, bx
	mov	ds, bx
	les	bx, dword ptr ds:Org_Rom_DiskTable
	mov	si, DSKADR
	mov	word ptr ds:[si], bx	;restore offset
	mov	word ptr ds:[si+2], es	;restore segment
	int	19h			;reboot
;SB34LOAD002****************************************************************

Write	proc  near			;show error messages
;In) DS:SI -> ASCIIZ string.

	lodsb				;AN000;
	or	al, al			;AN000;
	jz	Endwr			;AN000;
;SB34LOAD003****************************************************************
;SB  Write the character in al to the screen.
;SB    Use Video service 'Write teletype to active page' (ROM_TELETYPE)
;SB    Use normal character attribute
	mov	ah, ROM_TELETYPE
	mov	bl, 7			;"normal" attribute ?
	int	10h			;video write
;SB34LOAD003****************************************************************
	jmp	Write			;AN000;
Endwr:					;AN000;
	ret				;AN000;
Write	endp
;

;include MSbtmes.inc	       ;AN000;
include MSbio.cl1	       ;AN001;

Relocate_Length   equ  $ - start
Total_Length label byte
LoadBIO_Size	equ	$ - Start

cseg	ends
	end	start
