TITLE	CHKDISK  - procedures that read or write to the disk
page	,132					;

	.xlist
	include chkseg.inc							;an005;bgb
	INCLUDE CHKCHNG.INC
	INCLUDE DOSSYM.INC
	INCLUDE CHKEQU.INC
	INCLUDE CHKMACRO.INC
	include pathmac.inc


CONST	SEGMENT PUBLIC PARA  'DATA'
	EXTRN	FIXMES_ARG:word
	EXTRN	BADW_ARG:word
	EXTRN	badrw_num:word,BADRW_STR:WORD,HAVFIX:byte
	EXTRN	DIRTYFAT:byte,DOFIX:byte,SECONDPASS:byte
	EXTRN	HECODE:byte,USERDIR:byte,FRAGMENT:byte
	EXTRN	ORPHEXT:byte,ALLDRV:byte,FIXMFLG:byte,DIRCHAR:byte
	EXTRN	EOFVAL:word,BADVAL:word
	extrn	fTrunc:BYTE
CONST	ENDS

DATA	SEGMENT PUBLIC PARA 'DATA'
	EXTRN	THISDPB:dword,NUL_ARG:byte
	EXTRN	NAMBUF:byte,SRFCBPT:word,FATMAP:word
	EXTRN	USERDEV:byte,HARDCH:dword,CONTCH:dword
	EXTRN	ExitStatus:Byte,Read_Write_Relative:Byte
	extrn	bytes_per_sector:word						;an005;bgb
	extrn	sec_count:word, paras_per_64k:word, secs_per_64k:word		 ;an005;bgb
	extrn	fattbl_seg:word, paras_per_fat:word		       ;an005;bgb
DATA	ENDS

CODE	SEGMENT PUBLIC PARA 'CODE'
ASSUME	CS:DG,DS:DG,ES:DG,SS:DG
	EXTRN	FCB_TO_ASCZ:NEAR
	EXTRN	EPRINT:NEAR
	EXTRN	PROMPTYN:NEAR,DIRPROC:NEAR
	EXTRN	DOCRLF:NEAR,UNPACK:NEAR,PACK:NEAR
	EXTRN	CHECKNOFMES:NEAR
public read_disk, Read_once, write_disk, Write_once				;an005;bgb
public ReadFt, seg_adj, calc_sp64k						;an005;bgb
	.list


	pathlabl chkdisk
;=========================================================================	;an005;bgb
; READ_DISK	:	This routine reads the logical sector count requested.	;an005;bgb
;			It will read a maximum of 64k in one read.  If more	;an005;bgb
;			than 64k exists it will continue looping until		;an005;bgb
;			all sectors have been read.				;an005;bgb
;										;an005;bgb
;	Inputs	:	AL - Drive letter					;an005;bgb
;			ES:BX - Segment:offset of transfer address		;an005;bgb
;			CX - Sector count					;an005;bgb
;			DX - 1st  sector					;an005;bgb
;										;an005;bgb
;	Outputs :	Logical sectors read					;an005;bgb
; LOGIC 									;an005;bgb
; ***** 									;an005;bgb
;    adjust es:bx to es:00							;an005;bgb
;    calcluate sectors-per-64k (how many sectors are there that can fit within a 64k segment?)
;    DO while there are more sectors to read than sectors-per-64k		;an005;bgb
;	set sector-count to sectors-per-64k					;an005;bgb
;	perform the disk read							;an005;bgb
;	bump the seg addr to the new addr					;an005;bgb
;	dec  the number of sectors to read by sectors-per-64k			;an005;bgb
;	bump the starting sector number by the sectors-per-64k			;an005;bgb
;    ENDDO									;an005;bgb
;    perform a disk read for less than sectors-per-64k				;an005;bgb
;=========================================================================	;an005;bgb
procedure	read_disk							;an005;bgb
	savereg <ax,bx,cx,dx,es>						;an005;bgb
	call	seg_adj 			;an000;calc new seg:off 	;an005;bgb
	call	calc_sp64k			;an000;secs/64k 		;an005;bgb
;	$DO				; do while more than 64k		;an005;bgb
$$DO1:
	    cmp     cx,secs_per_64k	    ;an000;exceed 64k			;an005;bgb
;	$LEAVE	LE			    ;an000;yes				;an005;bgb
	JLE $$EN1
	    mov     sec_count,cx	;an000;save cx				;an005;bgb
	    mov     cx,secs_per_64k	;an000;get maximum read 		;an005;bgb
	    call    read_once		;an000;read it				;an005;bgb
;	$LEAVE	C								;an005;bgb
	JC $$EN1
	    mov     cx,es							;an005;bgb
	    add     cx,paras_per_64k	; adjust transfer area			;an005;bgb
	    mov     es,cx							;an005;bgb
	    mov     cx,sec_count	; restore sector count			;an005;bgb
	    sub     cx,secs_per_64k	;an000;get sectors remaining		;an005;bgb
	    add     dx,secs_per_64k	;an000;adjust starting sector		;an005;bgb
;	$ENDDO									;an005;bgb
	JMP SHORT $$DO1
$$EN1:
	call	read_once	    ;an000;read it				;an005;bgb
	restorereg <es,dx,cx,bx,ax>						;an005;bgb
	ret									;an005;bgb
read_disk	endp								 ;an005;bgb
										;an005;bgb
										;an005;bgb
;*****************************************************************************	;an005;bgb
;Routine name: Read_once							;an005;bgb
;*****************************************************************************	;an005;bgb
;										;an005;bgb
;description: Read in data using Generic IOCtl					;an005;bgb
;										;an005;bgb
;Called Procedures: None							;an005;bgb
;										;an005;bgb
;										;an005;bgb
;Change History: Created	5/13/87 	MT				;an005;bgb
;										;an005;bgb
;Input: AL = Drive number (0=A) 						;an005;bgb
;	es:BX = Transfer address						;an005;bgb
;	CX = Number of sectors							;an005;bgb
;	Read_Write_Relative.Start_Sector_High = Number of sectors high		;an005;bgb
;	DX = logical sector number low						;an005;bgb
;										;an005;bgb
;Output: CY if error								;an005;bgb
;	 AH = INT 25h error code						;an005;bgb
;										;an005;bgb
;Psuedocode									;an005;bgb
;----------									;an005;bgb
;	Save registers								;an005;bgb
;	Setup structure for function call					;an005;bgb
;	Read the disk (AX=440Dh, CL = 6Fh)					;an005;bgb
;	Restore registers							;an005;bgb
;	ret									;an005;bgb
;*****************************************************************************	;an005;bgb
Procedure Read_once				;				;an005;bgb
	savereg  <ax,bx,cx,dx,si,di,bp,es,ds>	;Change it to Read relative sect;an005;bgb
	mov	Read_Write_Relative.Buffer_Offset,bx ;Get transfer buffer add	 ;an005;bgb
	mov	bx,es				;				;AN005;bgb
	mov	Read_Write_Relative.Buffer_Segment,bx ;Get segment		;an005;bgb
	mov	Read_Write_Relative.Number_Sectors,cx ;Number of sec to read	;an005;bgb
	mov	Read_Write_Relative.Start_Sector_Low,dx ;Start sector		;an005;bgb
	mov	bx,offset Read_Write_Relative	;				;an005;bgb
	mov	cx,0FFFFh			;Read relative sector		;an005;bgb
	INT	25h				;Do the read			;an005;bgb
	pop dx					;Throw away flags on stack	;an005;bgb
	restorereg <ds,es,bp,di,si,dx,cx,bx,ax> 				;an005;bgb
	return									;an005;bgb
 Read_once endp 								;an005;bgb
										;an005;bgb
										;an005;bgb
;=========================================================================	;an005;bgb
; WRITE-DISK	:	This routine reads the logical sector count requested.	;an005;bgb
;			It will read a maximum of 64k in one read.  If more	;an005;bgb
;			than 64k exists it will continue looping until		;an005;bgb
;			all sectors have been read.				;an005;bgb
;										;an005;bgb
;	Inputs	:	AL - Drive letter					;an005;bgb
;			ES:BX - Segment:offset of transfer address		;an005;bgb
;			CX - Sector count					;an005;bgb
;			DX - 1st  sector					;an005;bgb
;										;an005;bgb
;	Outputs :	Logical sectors read					;an005;bgb
; LOGIC 									;an005;bgb
; ***** 									;an005;bgb
;    adjust es:bx to es:00							;an005;bgb
;    calcluate sectors-per-64k (how many sectors are there that can fit within a 64k segment?)
;    DO while there are more sectors to read than sectors-per-64k		;an005;bgb
;	set sector-count to sectors-per-64k					;an005;bgb
;	perform the disk read							;an005;bgb
;	bump the seg addr to the new addr					;an005;bgb
;	dec  the number of sectors to read by sectors-per-64k			;an005;bgb
;	bump the starting sector number by the sectors-per-64k			;an005;bgb
;    ENDDO									;an005;bgb
;    perform a disk read for less than sectors-per-64k				;an005;bgb
;=========================================================================	;an005;bgb
procedure      write_disk							;an005;bgb
	savereg <ax,bx,cx,dx,es>						;an013;bgb
	call	seg_adj 		;an000;calc new seg:off 		;an005;bgb
;	$DO				; do while more than 64k		;an005;bgb
$$DO5:
	    cmp     cx,secs_per_64k	;an000;exceed 64k			;an005;bgb
;	$LEAVE	LE			;an000;yes				;an005;bgb
	JLE $$EN5
	    mov     sec_count,cx	;an000;save cx				;an005;bgb
	    mov     cx,secs_per_64k	;an000;get maximum read 		;an005;bgb
	    call   write_once		;an000;read it				;an005;bgb
;	$LEAVE	C								;an005;bgb
	JC $$EN5
	    mov     cx,es							;an005;bgb
	    add     cx,paras_per_64k	; adjust transfer area			;an005;bgb
	    mov     es,cx							;an005;bgb
	    mov     cx,sec_count	; restore sector count			;an005;bgb
	    sub     cx,secs_per_64k	;an000;get sectors remaining		;an005;bgb
	    add     dx,secs_per_64k	;an000;adjust starting sector		;an005;bgb
;	$ENDDO									;an005;bgb
	JMP SHORT $$DO5
$$EN5:
	call	write_once		;an000;read it				;an005;bgb
	restorereg <es,dx,cx,bx,ax>						;an013;bgb
	ret									;an005;bgb
write_disk	endp								;an005;bgb
										;an005;bgb
;*****************************************************************************	;an005;bgb
;Routine name: Write_once							;an005;bgb
;*****************************************************************************	;an005;bgb
;										;an005;bgb
;description: Write Data using int 26						;an005;bgb
;										;an005;bgb
;Called Procedures: None							;an005;bgb
;										;an005;bgb
;										;an005;bgb
;Change History: Created	5/13/87 	MT				;an005;bgb
;										;an005;bgb
;Input: AL = Drive number (0=A) 						;an005;bgb
;	DS:BX = Transfer address						;an005;bgb
;	CX = Number of sectors							;an005;bgb
;	Read_Write_Relative.Start_Sector_High = already set up			;an048;bgb
;	DX = logical sector number low						;an005;bgb
;										;an005;bgb
;Output: CY if error								;an005;bgb
;	 AH = INT 26h error code						;an005;bgb
;										;an005;bgb
;Psuedocode									;an005;bgb
;----------									;an005;bgb
;	Save registers								;an005;bgb
;	Setup structure for function call					;an005;bgb
;	Write to disk (AX=440Dh, CL = 4Fh)					;an005;bgb
;	Restore registers							;an005;bgb
;	ret									;an005;bgb
;*****************************************************************************	;an005;bgb
Procedure Write_once				 ;				;an005;bgb
    savereg <ax,bx,cx,dx,di,si,bp,es,ds>	 ;This is setup for INT 26h right;AN005;bgb
    mov  Read_Write_Relative.Buffer_Offset,bx	 ;Get transfer buffer add	;AN005;bgb
    mov  bx,es					 ;				;AN005;bgb
    mov  Read_Write_Relative.Buffer_Segment,bx	 ;Get segment			;AN005;bgb
    mov  Read_Write_Relative.Number_Sectors,cx	 ;Number of sec to write	;AN005;bgb
    mov  Read_Write_Relative.Start_Sector_Low,dx ;Start sector			;AN005;bgb
    mov  cx,0FFFFh				 ;Write relative sector 	;AN005;bgb
    lea  bx,read_write_relative 		 ;				;an005;bgb
    INT  026h					 ;Do the write			;AN005;bgb
    pop  dx					 ;flags is returned on the stack;AN005;bgb
    restorereg <ds,es,bp,si,di,dx,cx,bx,ax>	 ;				;AN005;bgb
	ret					 ;				;AN005;bgb
Write_once endp 				 ;				;AN005;bgb
										;an005;bgb
;=========================================================================	;an005;bgb
; SEG_ADJ	:	This routine adjusts the segment:offset to prevent	;an005;bgb
;			address wrap.						;an005;bgb
;										;an005;bgb
;	Inputs	:	bx - Offset to adjust segment with			;an005;bgb
;			es - Segment to be adjusted				;an005;bgb
;										;an005;bgb
;	Outputs :	bx - New offset 					;an005;bgb
;			es - Adjusted segment					;an005;bgb
;=========================================================================	;an005;bgb
procedure	seg_adj 							;an005;bgb
	savereg <ax,cx,dx>							;an005;bgb
	mov	ax,bx				;an000;get offset		;an005;bgb
	mov	bx,0010h			;divide by 16			;an005;bgb
	xor	dx,dx				;an000;clear dx 		;an005;bgb
	div	bx				;an000;get para count	    ;an022;bgb
	mov	bx,es				;an000;get seg			;an005;bgb
	add	bx,ax				;an000;adjust for paras 	;an005;bgb
	mov	es,bx				;an000;save new seg		;an005;bgb
	mov	bx,dx				;an000;new offset		;an005;bgb
	restorereg <dx,cx,ax>							;an005;bgb
	ret									;an005;bgb
seg_adj 	endp								;an005;bgb
										;an005;bgb
										;an005;bgb
;=========================================================================	;an005;bgb
; CALC_SP64K	:	This routine calculates how many sectors, for this	;an005;bgb
;			particular media, will fit into 64k.			;an005;bgb
;										;an005;bgb
;	Inputs	:	DPB_SECTOR_SIZE - bytes/sector				;an005;bgb
;										;an005;bgb
;	Outputs :	SECS_PER_64K	- Sectors / 64k 			;an005;bgb
;			PARAS_PER_64K	- paragraphs per 64k			;an005;bgb
;=========================================================================	;an005;bgb
procedure	calc_sp64k							;an005;bgb
	savereg <ax,bx,cx,dx>							;an005;bgb
	mov	ax,0ffffh			;an000;64k			;an005;bgb
	mov	bx,bytes_per_sector		;an000;get bytes/sector 	;an005;bgb
	xor	dx,dx				;an000;clear dx 		;an005;bgb
	div	bx				;an000;sector count	    ;an022;bgb;bgb
	mov	secs_per_64k,ax 		;an000;save sector count	;an005;bgb
	mov	ax,bytes_per_sector		;an000;get bytes/sector 	;an005;bgb
	mov	bx,010h 			; divide by paras		;an005;bgb
	xor	dx,dx				;an000;clear dx 		;an005;bgb
	div	bx				; paras per sector	    ;an022;bgb;bgb
	mul	secs_per_64k			; times sectors 		;an005;bgb
	mov	paras_per_64k,ax		; = paras per 64k		;an005;bgb
	restorereg <dx,cx,bx,ax>		;an000;restore dx		;an005;bgb
	ret					;an000; 			;an005;bgb
calc_sp64k	endp				;an000; 			;an005;bgb
										;an005;bgb
										;an005;bgb
	Break	<ReadFT - read in the entire fat>				;an005;bgb
;****************************************************************************** ;an005;bgb
;   ReadFt - attempt to read in the fat.  If there are errors, step to		;an005;bgb
;   successive fats until no more.						;an005;bgb
;										;an005;bgb
;   Inputs:	none.								;an005;bgb
;   Outputs:	Fats are read until one succeeds.				;an005;bgb
;		Carry set indicates no Fat could be read.			;an005;bgb
;   Registers modified: all							;an005;bgb
; LOGIC 									;an005;bgb
; ***** 									;an005;bgb
;  DO for each of the fats on the disk: 					;an005;bgb
;     read - all the sectors in the fat 					;an005;bgb
;     increase the starting sector by the number of sectors in each fat 	;an005;bgb
;										;an005;bgb
; LARGE FAT SUPPORT - the big change here is in read disk.  since the fat must	;an005;bgb
;     be within the first 32M, then the starting sector number of 65535 is ok,	;an005;bgb
;     as is a larger number of sectors to read/write.				;an005;bgb
;****************************************************************************** ;an005;bgb
Procedure ReadFt,NEAR								;an005;bgb
    clc 				;Clear CY so we will loop		    ;an005;bgb
    mov     Read_Write_Relative.Start_Sector_High,0 ;			;an005;bgb
    call    Read_Disk			;	Read_Disk ();		    ;AC0;an005;bgb
;   $IF     C
    JNC $$IF9
	add	dx,cx			;	fatstart += fatsize		;an005;bgb
	call	Read_Disk		;	Read_Disk ();		    ;AC0;an005;bgb
;   $ENDIF
$$IF9:
bad_read: ret									;an005;bgb
EndProc ReadFt									;an005;bgb


	pathlabl chkdisk
CODE	ENDS
	END
