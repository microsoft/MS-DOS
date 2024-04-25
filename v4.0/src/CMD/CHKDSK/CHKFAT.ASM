TITLE	CHKFAT	- procedures that acces the fat and/or fatmap
page	,132					;

	.xlist
	include chkseg.inc							;an005;bgb
	INCLUDE CHKCHNG.inc
	INCLUDE DOSSYM.inc
	INCLUDE CHKEQU.inc
	INCLUDE CHKMACRO.inc
	include pathmac.inc


CONST	SEGMENT PUBLIC PARA  'DATA'
	EXTRN	CREATMES:byte,FIXMES_ARG:word
	EXTRN	FREEMES:byte
	EXTRN	BADW_ARG:word,FATAL_END:word
	EXTRN	badrw_num:word,BADRW_STR:WORD,HAVFIX:byte
	EXTRN	FREEBYMES1:byte,FREEBYMES2:byte
	EXTRN	FREE_ARG1:WORD,FREE_ARG2:WORD,FREE_ARG3:WORD,ORPHCNT:dword
	EXTRN	DIRTYFAT:byte,CROSSCNT:dword,DOFIX:byte,SECONDPASS:byte
	EXTRN	BADSIZ:word,ORPHSIZ:word,LCLUS:word,ORPHFCB:byte
	EXTRN	HECODE:byte,USERDIR:byte,FRAGMENT:byte
	EXTRN	ORPHEXT:byte,ALLDRV:byte,FIXMFLG:byte,DIRCHAR:byte
	EXTRN	BIGFAT:byte,EOFVAL:word,BADVAL:word
	extrn	fTrunc:BYTE, rarg1:word 					;an018;bgb
	extrn	temp_dd:dword						      ;an049;bgb
CONST	ENDS

DATA	SEGMENT PUBLIC PARA 'DATA'
	extrn	fatcnt:byte							;an005;bgb
	EXTRN	THISDPB:dword,NUL_ARG:byte
	EXTRN	NAMBUF:byte,SRFCBPT:word,FATMAP:word
	EXTRN	MCLUS:word,CSIZE:byte,SSIZE:word
	EXTRN	DSIZE:word,ARG1:word,ARG_BUF:byte,ERRCNT:byte
	EXTRN	USERDEV:byte,HARDCH:dword,CONTCH:dword
	EXTRN	ExitStatus:Byte,Read_Write_Relative:Byte
	extrn	bytes_per_sector:word, fattbl:word				;an005;bgb
	extrn	sec_count:word, secs_per_64k:word, paras_per_64k:word		  ;an005;bgb
	extrn	fattbl_seg:word, fatsiz:word, paras_per_fat:word		    ;an005;bgb
	extrn	end_of_fatmap:word						;an030;bgb
	extrn	root_entries:word						;ac048;bgb;an047;bgb
DATA	ENDS

CODE	SEGMENT PUBLIC PARA 'CODE'
ASSUME	CS:DG,DS:DG,ES:DG,SS:DG
	EXTRN	PRINTF_CRLF:NEAR,FCB_TO_ASCZ:NEAR, recover:near
	EXTRN	EPRINT:NEAR, makorphnam:near
	EXTRN	DOINT26:NEAR,PROMPTYN:NEAR,CHECKFILES:NEAR,DIRPROC:NEAR
	EXTRN	DOCRLF:NEAR, getfilsiz:near, fatal:near, write_disk:near
	EXTRN	GETENT:NEAR,CHECKNOFMES:NEAR, systime:near
	EXTRN	multiply_32_bits:near					     ;an049;bgb

public calc_fatmap_seg, MARKMAP, CHKMAP, CHKMAPLP, ORPHAN, CONTLP, RET18
public PromptRecover, NOCHAINREC, CHKMAPLP2, NEXTCLUS
public DISPFRB, FINDCHAIN, CHKMAPLP3, CHAINLP, INSERTEOF, FAT12_4, CHKCHHEAD
public ADDCHAIN, CHGOON, NEXTCLUS2,
public CHAINREC, MAKFILLP, GOTENT, OPAGAIN, GOTORPHNAM, ENTMADE, NEXTENT
public NXTORP, RET100, nextorph
public AMDONE, REWRITE, WRTLOOP
public WRTOK, NOWRITE, DONE, CROSSCHK, calc_fat_addr, pack, unpack
	.list
PHONEY_STACK DW 5 DUP(0)							;ac048;bgb

	pathlabl chkfat
;*****************************************************************************	;an005;bgb
;   CALC-FAT-ADDR - calculate the seg/off of the fat cell from the cell number	;an005;bgb
;										;an005;bgb
;   Inputs:   es - fat table segment
;	      si - cluster number
;
;   Outputs:  es - fat table segment + cluster seg
;	      di - cluster offset
;										;an005;bgb
; LARGE FAT SUPPORT								;an005;bgb
;*******************								;an005;bgb
; the offset into the fat table is cluster number times 2 (2 bytes per fat entry) ;an005;bgb
; This will result not only in the segment boundary being passed, but also in	;an005;bgb
; a single-word math overflow.	  So, we calculate the the address as follows:	;an005;bgb
; 0. start with cluster number (1-65535)					;an005;bgb
; 1. divide by 8 to get the number of paragraphs per fat-cell  (0-8191) 	;an005;bgb
;    remainder =					       (0-7)		;an005;bgb
; 2. multiply the remainder by 2 to get offset in bytes        (0-15)		;an005;bgb
; You now have a paragraph-offset number that you can use to calc the addr into ;an005;bgb
; the fat table.  To get the physical addr you must add it to the offset of the ;an005;bgb
; table in memory.								;an005;bgb
; 3. add the paras to the segment register					;an005;bgb
; 4. add the offset to the offset register					;an005;bgb
;****************************************************************************** ;an005;bgb
Procedure calc_fat_addr,near							;an005;bgb
    savereg <ax,bx,dx>		    ;						;an005;bgb
    mov     ax,si		     ;get cluster number from si
    mov     bx,0008h		    ; div by para (* 2 bytes per clus)	;an005;bgb
    xor     dx,dx		    ; zero dx for word divide			;an005;bgb
    div     bx			    ; do it				    ;an022;bgb;bgb
    mov     bx,es		    ; get fat table segment			;an005;bgb
    add     bx,ax		    ; add number of paras to the cluster	;an005;bgb
    mov     es,bx		    ; move it back				;an005;bgb
    shl     dx,1		    ; remainder times 2 			;an005;bgb
    mov     di,dx		    ; offset = 00 + remainder			;an005;bgb
    restorereg <dx,bx,ax>							;an005;bgb
  return									;an005;bgb
EndProc calc_fat_addr								;an005;bgb

;=========================================================================
; UNPACK	:	This routine calculates the position in the FAT
;			where the cluster number resides and obtains
;			its contents.
;
;	Inputs	:	SI - Cluster number
;	Outputs :	DI - Cluster contents
;			zero flag is set if fat cell = zero
;
; LOGIC
;	- get addr of fat table
;	- if 16-bit fat,
;	  then get the address of the cell (calc_fat_addr)
;	       mov it into di
;	       set the zero flag
;	  else multiply the cluster-number by 1.5 to get the byte-offset
;	       move the contents of the cluster into di
;	       if the cluster-number is odd,
;	       then shift it right by 1 nibble
;		    set the zero flag
;	       else (its already shifted right)
;		    set the zero flag
;=========================================================================
UNPACK	proc	near				;ac005; dms;unpack FAT
	push	es								;an005;bgb
	mov	es,fattbl_seg			;point to FAT in memory 	;an005;bgb
	mov	DI,SI				;put cluster number in DI
	cmp	[BIGFAT],0			;big fat?
;	$IF	nz				;yes
	JZ $$IF1
		call	calc_fat_addr		;calc addr of cluster		;an005;bgb
		mov	di,word ptr es:[di]	;es:bx points to fat cluster	;an005;bgb
		or	DI,DI			; Set zero
;	$ELSE					;small fat
	JMP SHORT $$EN1
$$IF1:
	       SHR     DI,1
	       ADD     DI,SI			; Mult by 1.5
	       mov     DI,word ptr es:[di]
	       TEST    SI,1			;is the cluster number odd?
;	       $IF     nz	     ;last bit is non-zero; means it is odd
	       JZ $$IF3
		       SHR     DI,1		;shift by 1 nibble
		       SHR     DI,1
		       SHR     DI,1
		       SHR     DI,1
		       and     di,0fffh 	;ac005; dms;
;		$ELSE				;ac005; dms;even cluster bound.
		JMP SHORT $$EN3
$$IF3:
		       AND     DI,0FFFH
;		$ENDIF
$$EN3:
;	$ENDIF
$$EN1:
	pop	es
	return
UNPACK	endp					;ac005; dms;

;=========================================================================
; PACK		: This routine puts data into the FAT.
;
;	Inputs	: SI - Cluster number to be packed
;		  dx - Data to be packed
;
;	Outputs : Altered FAT
; LOGIC
;	- set the fat-changed-flags
;	- get the seg of the fat-table
;	- if 16-bit fat,
;	  then get the address of the cell (calc_fat_addr)
;	       mov the new value into it
;	  else multiply the cluster-number by 1.5 to get the byte-offset
;	       move the contents of the cluster into di
;	       if the cluster-number is odd,
;	       then shift it right by 1 nibble
;		    set the zero flag
;	       else (its already shifted right)
;		    set the zero flag
;=========================================================================
PACK	proc	near				;ac005; dms;
	savereg <si,di,es>							;ac048;bgb
	mov	[DIRTYFAT],1			;Set FAT dirty byte
	mov	[HAVFIX],1			;Indicate a fix
	mov	es,fattbl_seg			;				;an005;bgb
	mov	DI,SI
	cmp	[BIGFAT],0
;	$IF	nz				;ac005; dms;big fat?
	JZ $$IF7
		call	calc_fat_addr		;calc addr of cluster		;an005;bgb
		mov	es:[di],dx		;move dx into cluster		;an005;bgb
;	$ELSE
	JMP SHORT $$EN7
$$IF7:
		shr	di,1		;offset = clus-num * 1.5
		add	di,si		;offset = clus-num * 1.5
		push	di		;save cluster offset
		mov	DI,es:[di]	;get previous value, 4 nibbles
		test	si,1			;is the cluster number odd?
;		$IF	nz	      ;last bit is non-zero; means it is odd
		JZ $$IF9
			SHL	dx,1		;shift by 1 nibble
			SHL	dx,1
			SHL	dx,1
			SHL	dx,1
			AND	DI,0FH		;zero out 1st 3 nibbles '000f'
;		$ELSE				;even cluster number
		JMP SHORT $$EN9
$$IF9:
			AND	DI,0F000H	;zero out last 3 nibbles 'f000'
;		$ENDIF
$$EN9:
		or	DI,dx			;put new value in with old
		pop	si			;get cluster offset
		mov	es:[SI],DI
;	$ENDIF
$$EN7:
	restorereg <es,di,si>							;ac048;bgb
	ret
PACK	endp					;ac005; dms;

;=========================================================================	;an005;bgb
; CROSSCHK	: this proc gets the value of the fatmap entry that is pointed	;an005;bgb
;		    to by an orphan						;an005;bgb
;										;an005;bgb
;	Inputs	: si - cluster number of the orphan				;an005;bgb
;										;an005;bgb
;	Outputs : ah - contents of the fatmap pointed to by di			;an005;bgb
; LOGIC 									;an005;bgb
; ***** 									;an005;bgb
;=========================================================================	;an005;bgb
procedure	CROSSCHK							;an005;bgb
	push	es
	mov	es,fatmap							;an005;bgb
	xor	di,di								;an005;bgb
	ADD	DI,SI
	mov	ah,es:[di]							;an005;bgb
	TEST	AH,10H
	pop	es
	ret
EndProc CROSSCHK								;an005;bgb

;*****************************************************************************	;an005;bgb
; INIT_FATMAP									;an005;bgb
; description: initialize the fatmap area to all zeros				;an005;bgb
;										;an005;bgb
; called from: main-routine							;an005;bgb
;										;an005;bgb
;Change History: Created    8/31/87	       bgb				;an005;bgb
;										;an005;bgb
;Input: segment addr of the fatmap						;an005;bgb
;	number of clusters in the fat (1-65535) 				;an005;bgb
;										;an005;bgb
;Output: fatmap 								;an005;bgb
;										;an005;bgb
; LOGIC 									;an005;bgb
;----------									;an005;bgb
;*****************************************************************************	;an005;bgb
Procedure init_fatmap,Near		   ;AN000;bgb				   ;an005;bgb
    savereg <es,di,ax,cx>
    mov     es,fatmap			;get seg of the fatmap			;an005;bgb
    xor     di,di			;get off of the fatmap			;an005;bgb
    mov     cx,[MCLUS]			;do once for each cluster
    xor     AL,AL			;zero means free
    REP     STOSB		    ;Initialize fatmap to all free
    mov     byte ptr es:[di],al 			   ;			;an010;bgb
    restorereg <cx,ax,di,es>
    return
endproc init_fatmap			    ;				    ;AN000;
;
;*****************************************************************************	;an005;bgb
; CALC_FATMAP_SEG								;an005;bgb
; description: calculate the segment of the fatmap for addressing purposes	;an005;bgb
;										;an005;bgb
; called from: main-routine							;an005;bgb
;										;an005;bgb
;Change History: Created    8/31/87	       bgb				;an005;bgb
;										;an005;bgb
;Input: bytes-per-sector							;an005;bgb
;	fatsiz									;an005;bgb
;										;an005;bgb
;Output: ram-based fat table							;an005;bgb
;	 paras-per-fat	     - number of paragraphs of mem in the fat
;	 fattbl-seg	     - segment number of fat table
;	 fatmap 	     - segment number of the fat map table
;										;an005;bgb
; LOGIC 									;an005;bgb
;----------									;an005;bgb
;     - calc length fat-table (in paras)					 ;an005;bgb
;	    = bytes-per-sector / 16 * sectors-per-fat				;an005;bgb
;     - calc segment of fat table in memory					;an005;bgb
;	    = es  +   64k							;an005;bgb
;     - calc segment of fatmap area in memory					;an005;bgb
;	    = es + 64k	+ length of fat-table					;an005;bgb
;*****************************************************************************	;an005;bgb
Procedure calc_fatmap_seg,Near		       ;AN000;bgb			       ;an005;bgb
; calc fat table length 							;an005;bgb
	push	es
	mov	ax,bytes_per_sector	; bytes per sector			;an005;bgb
	xor	dx,dx								;an005;bgb
	mov	bx,16								;an005;bgb
	div	bx			; paras per sector		    ;an022;bgb;bgb
	mov	cx,fatsiz		;2	   ; get sectors per fat	;an005;bgb
	xor	dx,dx								;an005;bgb
	mul	cx			; paras per fat 			;an005;bgb
	mov	paras_per_fat,ax						;an005;bgb
; calc fat table segment							 ;an005;bgb
	mov	bx,es			;get seg of fat-table			;an005;bgb
	add	bx,01000h		;add 64k for end of pgm seg		;an005;bgb
	mov	fattbl_seg,bx		;starting segment of fattbl		;an005;bgb
; calc fatmap segment								:an005;bgb
	add	ax,bx		 ;seg of fatmap= seg of fattbl + size of fattbl ;an005;bgb
	mov	fatmap,ax		 ;this is the seg of the fatmap 	 ;an005;bgb
; find segment number of end of fatmap						;an030;bgb
;ptm p5000	  mov	  bx,paras_per_fat	  ;each fat cell is 2 bytes		  ;an030;bgb
;ptm p5000	  shr	  bx,1			  ;each fatmap cell is 1 byte = 	  ;an030;bgb
	mov	bx, [MCLUS]		;P5000 INIT_FATMAP use [MCLUS]
	shr	bx, 1			;P5000 convert it to para.
	shr	bx, 1			;P5000
	shr	bx, 1			;P5000
	shr	bx, 1			;P5000
	add	ax,bx			;add in fatmap seg	   =		;an030;bgb
	inc	ax			;P5000
	mov	end_of_fatmap,ax	;last seg value 			;an030;bgb
	pop	es
	ret				;				      ;AN000;
endproc calc_fatmap_seg 		    ;				    ;AN000;
;
										;ac048;bgb
;*****************************************************************************	;ac048;bgb
; FIX_ENTRY - fill in the dir entry with the lost cluster information, give it	;ac048;bgb
;	      unique filename, and write it back to disk.			;ac048;bgb
;										;ac048;bgb
; WARNING!! NOTE!! -->								;ac048;bgb
;										;ac048;bgb
; called by - CHAINREC								;ac048;bgb
;										;ac048;bgb
; inputs: AX - drive number							;ac048;bgb
;	  BX - ram offset of beginning of sector				;ac048;bgb
;	  CX -									;ac048;bgb
;	  DX - sector number low						;ac048;bgb
;	  SP -									;ac048;bgb
;	  BP -									;ac048;bgb
;	  SI - cluster number of first cluster in this lost chain		;ac048;bgb
;	  DI - points to entry in ram						;ac048;bgb
;										;ac048;bgb
; output: AX -									;ac048;bgb
;	  BX -									;ac048;bgb
;	  CX -									;ac048;bgb
;	  DX -									;ac048;bgb
;	  SP -									;ac048;bgb
;	  BP -									;ac048;bgb
;	  SI -									;ac048;bgb
;	  DI-									;ac048;bgb
;										;ac048;bgb
; Regs abused - di,si,cx							;ac048;bgb
;										;ac048;bgb
;logic: 1. save the starting cluster number					;ac048;bgb
;										;ac048;bgb
;	2. if the recovered file name already exists, then use the next one.	;ac048;bgb
;	   do this until the name is unique.					;ac048;bgb
;										;ac048;bgb
;	3. move all the pertinant info into the dir entry.			;ac048;bgb
;										;ac048;bgb
;	4. write the dir entry out to disk.					;ac048;bgb
;*****************************************************************************	;ac048;bgb
procedure fix_entry,near							;ac048;bgb
    mov     ds:[DI+26],SI		;move 1st clus num into dir entry	;ac048;bgb	   ;an005;bgb
    savereg <ax,dx,bx>			;Save INT 26 data			;ac048;bgb
;make sure this name is unique							;ac048;bgb
    DOS_Call Disk_Reset 		;func 0d - flush buffers	  ;AC000;ac048;bgb;
    mov     dx,OFFSET DG:ORPHFCB	;point to filename file0000.chk 	;ac048;bgb
    mov     AH,FCB_OPEN 		;open the file just put into the dir	;ac048;bgb
OPAGAIN:									;ac048;bgb
;   $do 									;ac048;bgb
$$DO13:
	INT	21H								;ac048;bgb
	or	AL,AL			;did the open fail?			;ac048;bgb
;   $leave  nz									;ac048;bgb
    JNZ $$EN13
	call	MAKORPHNAM		;Try next name				;ac048;bgb
;   $enddo									;ac048;bgb
    JMP SHORT $$DO13
$$EN13:
GOTORPHNAM:				 ;di still points to entry		;ac048;bgb
	mov	SI,OFFSET DG:ORPHFCB + 1 ;ORPHFCB Now has good name		;ac048;bgb
	mov	cx,11			 ;move filename, ext			;ac048;bgb
	REP	MOVSB								;ac048;bgb
	call	MAKORPHNAM		 ;Make next name			;ac048;bgb
	xor	ax,ax			 ;fill dir entry with zeros		;ac048;bgb
	mov	cx,11								;ac048;bgb
	REP	STOSB								;ac048;bgb
; Add in time for orphan file - BAS July 17/85					;ac048;bgb
	push	dx			;save starting sector number		;ac048;bgb;an045;bgb
	call	SYSTIME 							;ac048;bgb
	STOSW				; Time					;ac048;bgb
	mov	ax,dx								;ac048;bgb
	STOSW				; Date					;ac048;bgb
	pop	dx			;restore starting sector number 	;ac048;bgb ;an045;bgb
	mov	SI,ds:[DI]		;get starting cluster number		;ac048;bgb			     ;an005;bgb
	inc	DI			;skip firstclus in entry		;ac048;bgb
	inc	DI								;ac048;bgb
	PUSH	DI			;save it from getfilsiz 		;ac048;bgb
	call	GETFILSIZ		;calc file size from number of clus	;ac048;bgb
	POP	DI			;restore di				;ac048;bgb
	STOSW				;ax=file size low			;ac048;bgb
	mov	ax,dx			;dx=filesize high			;ac048;bgb
	STOSW				;					;ac048;bgb
	restorereg <bx,dx,ax>	;offset, sector num, drive num			;ac048;bgb
	mov	cx,1		;number of sectors = 1				;ac048;bgb
	call	DOINT26 	;write it out to disk				;ac048;bgb
	ret									;ac048;bgb
endproc fix_entry								;ac048;bgb
										;ac048;bgb
;*****************************************************************************	;ac048;bgb;an047;bgb
; NEXTORPH - find the cluster number of the next orphan.  This assumes that	;ac048;bgb;an047;bgb
;	     there is at least one lost cluster available.			;ac048;bgb;an047;bgb
;										;ac048;bgb;an047;bgb
; WARNING!! NOTE!! -->								;ac048;bgb;an047;bgb
;										;ac048;bgb;an047;bgb
; called by - PROCEDURE NAME							;ac048;bgb;an047;bgb
;										;ac048;bgb;an047;bgb
; inputs: AX -									;ac048;bgb;an047;bgb
;	  BX -									;ac048;bgb;an047;bgb
;	  CX -									;ac048;bgb;an047;bgb
;	  DX -								      ;a;ac048;bgbn047;bgb
;	  SP -								       ;;ac048;bgban047;bgb
;	  BP -								      ;a;ac048;bgbn047;bgb
;	  SI - cluster number of the previous orphan			      ;a;ac048;bgbn047;bgb
;	  DI -								      ;a;ac048;bgbn047;bgb
;	  DS -								      ;a;ac048;bgbn047;bgb
;	  ES - points to one byte map of the fat			      ;a;ac048;bgbn047;bgb
;									      ;a;ac048;bgbn047;bgb
; output: AX -								       ;;ac048;bgban047;bgb
;	  BX -								      ;a;ac048;bgbn047;bgb
;	  CX -								       ;;ac048;bgban047;bgb
;	  DX -								      ;a;ac048;bgbn047;bgb
;	  SP -								      ;a;ac048;bgbn047;bgb
;	  BP -								      ;a;ac048;bgbn047;bgb
;	  SI - cluster number of one past the orphan				;ac048;bgb;an047;bgb
;	  DI - cluster number of the orphan				      ;a;ac048;bgbn047;bgb
;	  DS -								      ;a;ac048;bgbn047;bgb
;	  ES -								      ;a;ac048;bgbn047;bgb
;									      ;a;ac048;bgbn047;bgb
; Regs abused - none								;ac048;bgb;an047;bgb
;									       ;;ac048;bgban047;bgb
;logic: 1. save ax & es, and point to fat map					;ac048;bgb;an047;bgb
;									      ;a;ac048;bgbn047;bgb
;	2. do until the head of a chain is found:				;ac048;bgb ;an047;bgb
;									       ;;ac048;bgban047;bgb
;	   3. get the next cell 						;ac048;bgb    ;an047;bgb
;									       ;;ac048;bgban047;bgb
;	   4. bump pointers into fat map					;ac048;bgb ;an047;bgb
;									       ;;ac048;bgban047;bgb
;	5. restore ax & es						       ;;ac048;bgban047;bgb
;*****************************************************************************;a;ac048;bgbn047;bgb
procedure NEXTORPH,near 						      ;a;ac048;bgbn047;bgb
    savereg <ax,es>			;save regs abused			;ac048;bgb
    mov     es,[FATMAP] 		;point to fat map			;ac048;bgb
;   $do 									;ac048;bgb
$$DO16:
loopno: mov	al,byte ptr es:[si]	;get the indicated fatmap entry 	;ac048;bgb   ;an005;bgb
	inc	si			;point to the next one			;ac048;bgb   ;an005;bgb
	inc	di			;point to the next one			;ac048;bgb   ;an005;bgb
	cmp	AL,89H			;stop when you find an	89		;ac048;bgb
;   $leave    z 	       ;this means head(80), found(1), and orphan(8)	;ac048;bgb
    JZ $$EN16
;   $enddo									;ac048;bgb
    JMP SHORT $$DO16
$$EN16:
    restorereg <es,ax>			;restore regs				;ac048;bgb
return										;ac048;bgb
endproc nextorph								;ac048;bgb
										;ac048;bgb
										;ac048;bgb

;****************************************************************************
; MARKMAP - make a mark in the fat map for every cluster encountered
;
; called by - markfat,
;
; inputs  - AL - the mark
;	    DI - cluster number
;
; outputs - CY if crosslink found
;	  - AH - previous mark
;	  - crosscnt (count of number of crosslinks found)
;	  - fatmap marked
;
; LOGIC
;******
;	- point to fatmap with es
;	- if that cell has been found before,
;	    then mark it crossed x'10'
;	    else mark it found	 al
;****************************************************************************
markmap: savereg <si,es>			 ;Save registers		 ;AN000;
	xor	si,si				;Get addr of map		;an005;bgb
	mov	es,[FATMAP]			;Get addr of map		;an005;bgb
	mov	ah,es:[di]			   ;Get entry at that spot	;an005;bgb
	or	ah,ah				;Is it zero?			;     ;
;	$IF	NZ ;already found - mark crossed;If not, we got crosslink	;AC000;
	JZ $$IF19
	   add	   word ptr crosscnt,1		;Count the crosslink		;     ;
	   adc	   word ptr crosscnt+2,0	;Count the crosslink		;     ;
	   or	   byte ptr es:[di],10H 	;Resets zero in map		;An005;bgb
	   stc					;Indicate crosslink on ret	;     ;
;	$ELSE	  ;not found - mark found	;No crosslink			;     ;
	JMP SHORT $$EN19
$$IF19:
	   mov	es:[di],al			;Set mark in map		;Ac005;bgb
	   clc					;Indicate things okay		;     ;
;	$ENDIF					;				;AN000;
$$EN19:
	restorereg <es,si>			;				;AN005;bgb
	ret					;				;     ;


;****************************************************************************
; CHKMAP - Compare FAT and FATMAP looking for badsectors and orphans
;
; called by -
;
; inputs  - fatmap
;	  - dsize - number of clusters on the disk
;
; outputs - badsiz -
;	  -
;	  -
; LOGIC
;******
;	- get addr of fatmap
;	- get offset of 1st cluster in fatmap
;	- do for all the clusters on the disk:
;	    - if the cluster has been found
;	      then get the next cluster in its chain
;		   if the cell was never pointed to by anyone (0)
;		   then get the contents of that cell from the fat
;			(the contents of the fat cell should be zero, too)
;			if the fat-cell is not zero
;			then (it should only be a bad sector)
;			     if it is a bad sector, inc the bad-sector-counter
;			     otherwise, we have found an orphan sector
;	  end-of-loop
;	- if there are any orphans,
;	  then recover them
;****************************************************************************
CHKMAP:
    push    es									;an014;bgb
    mov     es,fatmap		    ;get segment of the fatmap			;an005;bgb
    xor     si,si			;get the offset of the fatmap		;an005;bgb
    mov     si,2			;go past the first two (invalid) entries;an005;bgb
;do for all the clusters on the disk
    mov     cx,[DSIZE]		    ;loop for the number of clusters on the disk
CHKMAPLP:
    mov     al,es:[si]			;move a byte from the fatmap to al	;an005;bgb
    or	    al,al			;is the cluster found already?
;   $IF     Z				;fatmap cell is zero
    JNZ $$IF22
	call	unpack			;get the contents of it
;	$IF	NZ			;is there something in the cell?
	JZ $$IF23
	    cmp     di,[badval] 	;is the fat cell pointing to a bad sector? fff7
;	    $IF     Z			; yes
	    JNZ $$IF24
		inc  [badsiz]		  ;inc the bad sector counter
		mov  byte ptr es:[si],4 	      ;Flag the map		;an005;bgb
;	    $ELSE			; no, not a bad sector
	    JMP SHORT $$EN24
$$IF24:
orphan: 	inc  [orphsiz]		; then its an orphan
		mov  byte ptr es:[si],8 	      ;Flag it			;an005;bgb
;	    $ENDIF
$$EN24:
;	$ENDIF
$$IF23:
;   $ENDIF
$$IF22:
CONTLP:
    inc     si				;point si to next cluster
    loop    chkmaplp
    cmp     [orphsiz],0 							;an005;bgb
;   $IF     A		 ;if there are any orphans, go recover them		;an005;bgb
    JNA $$IF29
	call	recover
;   $ENDIF
$$IF29:
    pop  es									;an014;bgb
RET18:	ret

;*****************************************************************************
; PROMPTRECOVER - do the actual recovering of files
;
; inputs:   es - points to fatmap
;	    ax -
;	    bx -
;	    cx -
;	    dx -
;
; outputs:
; LOGIC
;	- ask the user if he wants to convert the orphans to files
;	-
;	-
;***************************************************************************
PromptRecover:
    mov     dx,OFFSET DG:FREEMES
    call    PROMPTYN			    ;Ask user
;   $IF     Z
    JNZ $$IF31
	jmp	CHAINREC
;   $ENDIF
$$IF31:
NOCHAINREC:
	mov	es,[fatmap]			;Free all orphans ;an005;bgb
	mov	si,2						  ;an005;bgb
	mov	cx,[dsize]
	xor	dx,dx	     ;dx is the new value (free)
CHKMAPLP2:
	mov	al,es:[si]	 ;get next byte from fatmap into al
	TEST	AL,8		 ; is it an orphan?
;	$IF	NZ		 ;yes
	JZ $$IF33
	    call    PACK	 ;si=cluster number dx=new value
;	$ENDIF
$$IF33:
NEXTCLUS:
       inc     si
	loop	CHKMAPLP2
	xor	ax,ax
	XCHG	ax,[ORPHSIZ]		;number of orphans = zero
	mov	cx,OFFSET DG:FREEBYMES1 ;print msg
	cmp	[DOFIX],0
;	$IF	Z
	JNZ $$IF35
	    mov     cx,OFFSET DG:FREEBYMES2
	    mov     [LCLUS],ax		 ;move number of lost clust would be ;an049;bgb
;	$ENDIF
$$IF35:
DISPFRB:				 ;ax=lost clusters (1-fff6)
	push	bx			 ;save it			     ;an049;bgb
	push	cx			 ;save it			     ;an049;bgb
	mov	cl,[csize]		 ;get sectors per cluster (1-32)     ;an049;bgb
	xor	ch,ch			 ;zero out high byte		     ;an049;bgb
	xor	dx,dx			 ;zero out hi word for word mult     ;an049;bgb
	mul	cx			 ;cx*ax=dx:ax  lost sectors (1-1ffec0);an049;bgb
	mov	bx,dx			 ;move high word for call	     ;an049;bgb
	mov	cx,ssize		 ;word to mult with		     ;an049;bgb
	call	multiply_32_bits	 ;bx:ax is result		     ;an049;bgb
	mov	word ptr rarg1,ax	 ;low word into low word	     ;an049;bgb
	mov	word ptr rarg1+2,bx	 ;hi  word into hi  word	      ;an049;bgb
	mov	[free_arg1],ax
	mov	[free_arg2],bx						     ;an049;bgb
	mov	[free_arg3],cx
	pop	cx
	pop	bx
	mov	dx,cx				;Point to right message;an049;bgb
	call	printf_crlf
	ret




;*****************************************************************************
; FINDCHAIN  -
;
; called by - recover
;
; inputs:
;
; outputs:
; LOGIC - search thru entire fatmap
;	-
;	-
;***************************************************************************
lostdeb  equ	0	;set private build version on				    ;an047;bgb
lost_str db	'00000' ;max size of cluster number
FINDCHAIN:
;Do chain recovery on orphans
	mov	es,[FATMAP]		; point to fatmap
	mov	SI,2			; point to fatmap
	mov	dx,si			; point to fatmap
	mov	cx,[DSIZE]		;get total number of clusters on disk
CHKMAPLP3:
	mov	al,es:[si]		;get next fatmap entry
	inc	si			;point to next fatmap entry
			;has to be an orphan(08)
	TEST	AL,8				;Orphan?
	jz	NEXTCLUS2			;Nope
			;make sure its not a regular file entry
	TEST	AL,1				;Seen before ?
	jnz	NEXTCLUS2			;Yup
;recover this chain
	savereg <si,cx,dx>			;Save search environment
	dec	SI
	or	byte ptr es:[si],81H		;Mark as seen and head


	IF	LOSTDEB 		;is this private build version?
	    call lostdisp		;display lost cluster numbers
	 ENDIF

	add	word ptr orphcnt,1		;Found a chain
	adc	word ptr orphcnt+2,0		;Found a chain
	mov	SI,dx			;point to the next fatmap entry
CHAINLP:
	call	UNPACK			;si = fat cell
	XCHG	SI,DI			;si=contents, di=cell number
	cmp	SI,[EOFVAL]		;is this the end of the file?
	JAE	CHGOON			;yes, then we are done
	PUSH	DI			;no, not eof
;dont do this next part if any of two conditions:
;   1. invalid cluster number
;   2. points to itself
	cmp	SI,2			;well, is it a valid cluster number?
	JB	INSERTEOF			;Bad cluster number
	cmp	SI,[dsize]
	JA	INSERTEOF			;Bad cluster number
	cmp	SI,DI			;how bout if it points to itself?
	jz	INSERTEOF			;Tight loop
; find out what it points TO
	    call    CROSSCHK
	    TEST    AH,8			    ;Points to a non-orphan?
	    jnz     CHKCHHEAD			    ;Nope
			      ;orphan points to nothing
INSERTEOF:
; you come here if:
;   1. invalid cluster number
;   2. points to itself
;   3. points to nothing
	POP	SI			;the previous cluster number
	mov	dx,0FFFH		;get eof value (12-bit)
	cmp	[BIGFAT],0
	jz	FAT12_4
	mov	dx,0FFFFH		;get eof value (16-bit)
FAT12_4:
	call	PACK			;stick it in!
	jmp	SHORT CHGOON		;and we are done
; orphan point to a head entry
CHKCHHEAD:
	TEST	AH,80H				;Previosly marked head?
	jz	ADDCHAIN			;Nope
	AND	BYTE PTR es:[DI],NOT 80H	   ;Turn off head bit
	sub	word ptr orphcnt,1		;Wasn't really a head
	sbb	word ptr orphcnt+2,0		;Wasn't really a head
	POP	DI				;Clean stack
	jmp	SHORT CHGOON
ADDCHAIN:
	TEST	AH,1				;Previosly seen?
	jnz	INSERTEOF			;Yup, don't make a cross link
	or	BYTE PTR es:[DI],1		   ;Mark as seen
	POP	DI				;Clean stack
	jmp	CHAINLP 			;Follow chain
CHGOON:
	POP	dx				;Restore search
	POP	cx
	POP	SI
NEXTCLUS2:
	inc	dx
	loop	CHKMAPLP3
	ret



;*****************************************************************************	;ac048;bgb
; CHAINREC - the user has requested us to recover the lost clusters		;ac048;bgb
;										;ac048;bgb
; inputs:									;ac048;bgb
; note: although called from PROMPTRECOVER, this routine returns control to	;ac048;bgb
;	recover via the ret instruction.					;ac048;bgb
;*****************************************************************************	;ac048;bgb
										;ac048;bgb
;*****************************************************************************	;ac048;bgb
; CHAINREC - The user has requested us to recover the lost clusters		;ac048;bgb
;										;ac048;bgb
; WARNING!! NOTE!! --> the count of the number of lost cluster chains remains,
;		       for this proc, a single word.  More than 64k chains
;		       will cause this proc to fail.
;										;ac048;bgb
; called by - PROCEDURE NAME							;ac048;bgb
;										;ac048;bgb
; inputs: AX - N/A								;ac048;bgb
;	  bx -									;ac048;bgb
;	  cx - N/A								;ac048;bgb
;	  dx - N/A								;ac048;bgb
;	  SP -									;ac048;bgb
;	  BP - N/A								;ac048;bgb
;	  SI - N/A								;ac048;bgb
;	  DI - N/A								;ac048;bgb
; data:   root_entries								;ac048;bgb
;	  orphcnt								;ac048;bgb
;										;ac048;bgb
; output: AX -									;ac048;bgb
;	  bx -									;ac048;bgb
;	  cx -									;ac048;bgb
;	  dx -									;ac048;bgb
;	  SP -									;ac048;bgb
;	  BP -									;ac048;bgb
;	  SI -									;ac048;bgb
;	  DI-									;ac048;bgb
;										;ac048;bgb
; Regs abused - 								;ac048;bgb
;										;ac048;bgb
;logic: 1.									;ac048;bgb
;*****************************************************************************	;ac048;bgb
CHAINREC:									;ac048;bgb
	push	es		;save es if it is used for anything		;ac048;bgb
	push	ds		;make es point to data				;ac048;bgb
	pop	es								;ac048;bgb
;find the cluster number of the orphan						;ac048;bgb
	mov	SI,2			;start at first cluster ;an005;bgb	;ac048;bgb
	mov	DI,1			;point to previous cluster?		;ac048;bgb
	call	NEXTORPH		;di points to orphan			;ac048;bgb
;init for loop									;ac048;bgb
	savereg <si,di> 		;save orphan, orphan+1			;ac048;bgb
	mov	SI,DI			;si point to orphan			;ac048;bgb
	xor	ax,ax		 ;set count of dir entries processed to zero;ac048;bgb
	mov	dx,word ptr orphcnt	;get low word of lost clusters		  ;ac048;bgb;an049;bgb
	mov	word ptr temp_dd,dx	;get low word of lost clusters	     ;an049;bgb
	mov	dx,word ptr orphcnt+2	;get hi  word of lost clusters		  ;an049;bgb
	mov	word ptr temp_dd+2,dx	;get hi  word of lost clusters	     ;an049;bgb
	mov	BP,OFFSET DG:PHONEY_STACK ;Set BP to point to "root"		;ac048;bgb
;do for all dir entries:							;ac048;bgb
MAKFILLP:									;ac048;bgb
;   $DO 				;do for all root entries		;ac048;bgb
$$DO37:
	savereg <ax>		  ;cnt of entries processed, num orphans  ;ac048;bgb;an049;bgb
	call	GETENT			;DI points to entry			;ac048;bgb
	cmp	BYTE PTR ds:[DI],0E5H	;is this dir entry erased?	     ;an;ac048;bgb005;bgb
;	$if	z,or								;ac048;bgb
	JZ $$LL38
	cmp	BYTE PTR ds:[DI],0	;is this dir entry empty?	     ;an;ac048;bgb005;bgb
;	$if	z								;ac048;bgb
	JNZ $$IF38
$$LL38:
GOTENT:     mov     [HAVFIX],1		;Making a fix				;ac048;bgb
	    cmp     [DOFIX],0		;/f parameter specified?		;ac048;bgb
;	    $if     NZ			;yes- do the fix			;ac048;bgb
	    JZ $$IF39
		call	fix_entry						;ac048;bgb
;	    $endif								;ac048;bgb
$$IF39:
ENTMADE:    restorereg <ax,di,si>					     ;ac048;bgb;an049;bgb
	    sub     word ptr temp_dd,1	 ;finished with one orphan		 ;ac048;bgb;an049;bgb
	    sbb     word ptr temp_dd+2,0 ;finished with one orphan		 ;ac048;bgb;an049;bgb
	    cmp     word ptr temp_dd,0	;is that the last one?			;ac048;bgb;an049;bgb
;	    $IF     Z,AND		;no, check the hi word		     ;an049;bgb
	    JNZ $$IF41
	    cmp     word ptr temp_dd+2,0;is that the last one?			;ac048;bgb;an049;bgb
;	    $IF     Z			;neither are zero		     ;an049;bgb
	    JNZ $$IF41
		jmp	RET100		    ; yes,we are done			    ;ac048;bgb;an049;bgb
;	    $endif							     ;an049;bgb
$$IF41:
	    call    NEXTORPH		;get the cluster of the next one	;ac048;bgb
	    savereg <si,di>							;ac048;bgb
	    mov     SI,DI							;ac048;bgb
;	$else				;dir entry was not erased or zero	;ac048;bgb
	JMP SHORT $$EN38
$$IF38:
NEXTENT:    restorereg <ax>						     ;ac048;bgb;an049;bgb
;	$endif									;ac048;bgb
$$EN38:
NXTORP: inc	ax								;ac048;bgb
	cmp	ax,root_entries 	;do for 0 to (root_entries - 1) 	;ac048;bgb
;   $leave	z								;ac048;bgb
    JZ $$EN37
;   $ENDDO									;ac048;bgb
    JMP SHORT $$DO37
$$EN37:
	restorereg <ax,ax>			;Clean Stack from si,di 	;ac048;bgb
	sub	word ptr orphcnt,dx		;Couldn't make them all         ;ac048;bgb
	sbb	word ptr orphcnt+2,0		;Couldn't make them all         ;ac048;bgb
	mov	dx,OFFSET DG:CREATMES						;ac048;bgb
	mov	byte ptr [arg_buf],0						;ac048;bgb
	call	EPRINT								;ac048;bgb
RET100: pop	es			;restore es				;ac048;bgb
	ret									;ac048;bgb
										;ac048;bgb
									       ;ac048;bgb
										;ac048;bgb

;*****************************************************************************
;*****************************************************************************
SUBTTL	AMDONE	- Finish up routine
PAGE
Public	AmDone
AMDONE:
ASSUME	DS:NOTHING
	cmp	[DIRTYFAT],0
	jz	NOWRITE 			;FAT not dirty
	cmp	[DOFIX],0
	jz	NOWRITE 			;Not supposed to fix
REWRITE:
	LDS	bx,[THISDPB]
ASSUME	DS:NOTHING
	mov	cx,[bx.dpb_FAT_size]		;Sectors for one fat (DCR)	;AC000;
	mov	DI,cx
	mov	CL,[bx.dpb_FAT_count]		;Number of FATs
	mov	dx,[bx.dpb_first_FAT]		;First sector of FAT
	PUSH	CS
	POP	DS
ASSUME	DS:DG
	mov	[ERRCNT],0
; set up to write to the disk
	xor	bx,bx		     ;offset of the fat-table ;an005;bgb
	mov	es,fattbl_seg	     ;segment of the fat-table ;an005;bgb
	mov	AL,[ALLDRV]
	dec	AL
	mov	AH,1
	PUSH	cx
WRTLOOP:
	XCHG	cx,DI
	PUSH	dx
	PUSH	cx
	PUSH	DI
	PUSH	ax

	call	Write_Disk			;Do relative sector write		;AC000;

	JNC	WRTOK
	inc	[ERRCNT]
						;mov	 [badrw_str],offset dg:writing
	POP	ax				; Get fat # in AH
	PUSH	ax				; Back on stack
	xchg	al,ah				; Fat # to AL
	xor	ah,ah				; Make it a word
	mov	[badrw_num],ax
	mov	dx,offset dg:badw_arg
	call	PRINTf_crlf
WRTOK:
	POP	ax
	POP	cx
	POP	DI
	POP	dx
	inc	AH
	ADD	dx,DI
	loop	WRTLOOP 			;Next FAT
	POP	cx				;Number of FATs
	cmp	CL,[ERRCNT]			;Error on all?
;	$if	e
	JNE $$IF47
	    jmp fatal
;	$endif
$$IF47:
; make sure that the data fields are always adressable, because
;we can come here after a ctl - break has happened. so point to them w/ cs:
NOWRITE:
	DOS_Call Disk_Reset			;				;AC000;
	mov	dx,OFFSET DG:USERDIR		;Recover users directory
	DOS_Call ChDir				;				;AC000;
	cmp	BYTE PTR cs:[FRAGMENT],1      ;Check for any fragmented files?	;an029;bgb
	jnz	DONE				;No -- we're finished
	call	CHECKFILES			;Yes -- report any fragments
Public	Done
DONE:
ASSUME	DS:NOTHING
	mov	DL,cs:[USERDEV] 		   ;Recover users drive 	;an029;bgb
	DOS_Call Set_Default_Drive		;				;AC000;
	ret









	IF	LOSTDEB 		;is this private build version?
Procedure lostdisp,near 						   ;an005;bgb
    savereg <ax,bx,cx,dx,si,di> 	     ;						 ;an005;bgb
	    mov  ax,dx	;save orig value

	    mov  cl,12	;shift 3 nibbles
	    shr  dx,cl	;remove al but last nibble
	    and  dx,000fh
	    cmp  dx,0ah
;	    $IF  B
	    JNB $$IF49
	       add  dx,30h ;make it char
;	    $ELSE
	    JMP SHORT $$EN49
$$IF49:
	       add  dx,37h
;	    $ENDIF
$$EN49:
	    push ax
	    mov  ah,2
	    int  21h
	    pop  ax

	    mov  dx,ax	;get orig value
	    mov  cl,8
	    shr  dx,cl
	    and  dx,000fh
	    cmp  dx,0ah
;	    $IF  B
	    JNB $$IF52
	       add  dx,30h ;make it char
;	    $ELSE
	    JMP SHORT $$EN52
$$IF52:
	       add  dx,37h
;	    $ENDIF
$$EN52:
	    push ax
	    mov  ah,2
	    int  21h
	    pop  ax

	    mov  dx,ax	;get orig value
	    mov  cl,4
	    shr  dx,cl
	    and  dx,000fh
	    cmp  dx,0ah
;	    $IF  B
	    JNB $$IF55
	       add  dx,30h ;make it char
;	    $ELSE
	    JMP SHORT $$EN55
$$IF55:
	       add  dx,37h
;	    $ENDIF
$$EN55:
	    push ax
	    mov  ah,2
	    int  21h
	    pop  ax

	    mov  dx,ax	;get orig value
	    and  dx,000fh
	    cmp  dx,0ah
;	    $IF  B
	    JNB $$IF58
	       add  dx,30h ;make it char
;	    $ELSE
	    JMP SHORT $$EN58
$$IF58:
	       add  dx,37h
;	    $ENDIF
$$EN58:
	    mov  ah,2
	    int  21h

	    mov  dl,' ' ;space after last number
	    mov  ah,2
	    int  21h

    restorereg <di,si,dx,bx,cx,ax>							 ;an005;bgb
  return									;an005;bgb
EndProc lostdisp								;an005;bgb
ENDIF


	pathlabl chkfat


CODE	ENDS
	END
