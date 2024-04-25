page	,132				;
TITLE	RECOVER.SAL - MS-DOS File/Disk Recovery Utility
;----------------------------------------------------------
;
;	Recover - Program to rebuild an ms.dos directory
;
;	Copyright 1988 by Microsoft Corporation
;
;-----------------------------------------------------------
.xlist
	include recchng.inc		;an000;bgb
	include recseg.inc		;AN000;bgb
	INCLUDE DOSSYM.INC		;AN000;bgb
	INCLUDE RECEQU.INC		;AN000;bgb
	INCLUDE RECdata.INC		;AN000;bgb
	INCLUDE recmacro.inc		;AN000;bgb
	INCLUDE sysmsg.INC		;AN000;bgb
	include pathmac.inc
	msg_utilname<recover>
;										;AN000;bgb
;*****************************************************************************
; Extrn Declarations
;*****************************************************************************
data	segment public para 'DATA'	;An000;bgb
	extrn	Askmsg:Byte
	extrn	Baddrv:Byte
	extrn	FatErrRead:Byte
	extrn	FATErrWrite:Byte
	extrn	Dirmsg:Byte
	extrn	RecMsg:Byte
	extrn	OpnErr:Byte
	extrn	no_mem_arg:word 	;an013;bgb
data	ends				;AN000;bgb


;******************************************************************************
; Public entries
;******************************************************************************
code	segment public para 'code'	;An000;bgb
	pathlabl recover
public	GetFat, getSmall, getfat1, getret, SetFat, setsmall, f_exists		;AN000;bgb
public nofspec, kill_bl, endl, next_char
Public	Main_Routine

IF KANJI
   public islead
   PUBLIC	notlead
   PUBLIC	dbcsmore
   PUBLIC	TESTKANJ
ENDIF


;PUBLIC  stop
public	setfat2, setfat1, setRet, GetKeystroke, Prompt, Load, ReadFt, WrtFat	;AN000;bgb
public	wrtit,	wrtok, fEOF, EOFok, printerr, SFFromFCB, Main_Routine		;AN000;bgb
public	slashok, kill_bl, next_char, name_copied, sja, sjb, not_root		;AN000;bgb
public	same_drive, sj1, no_errors, same_dir, noname, drvok, See_If_File	;AN000;bgb
public	step2,	step3, step4, direrr, fill_dir, file_spec			;AN000;bgb
public	RecFil, recfil0, rexit1, int_23, rabort, rest_dir, no_fudge		;AN000;bgb
public	int_24, int_24_back, ireti, Read_File, Bad_File_Read, read_fats 	;AN000;bgb
public	fill_fat, rexit2, sfsize, stop_read, calc_fat_addr			;an027;bgb
	EXTRN	Write_Disk:NEAR,Read_Disk:NEAR,report:NEAR			; AC000;SM
	Extrn	Main_Init:Near
	Extrn	Change_Blanks:Near						;an012;bgb
	Extrn	Build_String:Near
	extrn	seg_adj:near
	extrn	exitpgm:near						       ;an026;bgb
.list

;*****************************************************************************	;an005;bgb
;   calc_fat_addr - calculate the seg/off of the fat cell from the cell number	;an005;bgb
;										;an005;bgb
;   Inputs:	AX the fat cell number						;an005;bgb
;		BX the fat table offset
;		ES the fat table segment (same as program seg)			;an005;bgb
;   Outputs:	BX contains the offset of the fat cell				;an005;bgb
;		ES contains the segment of the fat cell 			;an005;bgb
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
    savereg <ax,dx>		    ; ax already has cluster number		;an005;bgb
    lea     bx,fattbl		    ;point to fat table in memory		;an005;bgb
    call    seg_adj		    ;es:bx = es:00
    mov     bx,0008h		    ;  set up div by para (* 2 bytes per clus)	;an005;bgb
    xor     dx,dx		    ; zero dx for word divide			;an005;bgb
    div     bx			    ; do it					;an005;bgb
    mov     bx,es		    ; get fat table segment			;an005;bgb
    add     bx,ax		    ; add number of paras to the cluster	;an005;bgb
    mov     es,bx		    ; move it back				;an005;bgb
    shl     dx,1		    ; remainder times 2 			;an005;bgb
    mov     bx,dx		    ; offset = 00 + remainder			;an005;bgb
    restorereg <dx,ax>								;an005;bgb
  return									;an005;bgb
EndProc calc_fat_addr								;an005;bgb



	break	<GetFat - return the contents of a fat entry>
;*****************************************************************************
;   GetFat - return the contents of a fat cell
;
;   Inputs:	AX the fat cell number
;   Outputs:	BX contains the contents of the fat cell AX
;		CX contains the number of bytes per sector
;   Registers Revised: SI
;
; pseudocode:
; ----------
;    if large-fat, then
;	double fat-number			 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
;	fat-table offset = fat-num * 2		 2  4  6  8  10 12 14 16 18 20
;    else
;	fat-table offset = fat-num + (fat-num/2)
;
; LARGE FAT SUPPORT  - if this is a 16-bit fat, use the new calc algorithm
; *****************
;******************************************************************************
Procedure GetFat,NEAR
	set_data_segment
	lea	bx,fattbl		;point to fat table in memory			   ;AC000;bgb
	cmp	MaxClus,4086		;   if (MaxClus >= 4086) {
;	$IF	AE			;changed to above because max clusters	;an005;bgb
	JNAE $$IF1
					;can now be 'FFFF'hex			;an005;bgb
		call	calc_fat_addr		; ;set up div by para		;an005;bgb
		mov	bx,word ptr es:[bx]	; get contents of fat		;an005;bgb
;	$ELSE	;small fat		    ;AN000;bgb
	JMP SHORT $$EN1
$$IF1:
getSmall:   push    ax			    ;save fat-num     ;       i = clus + clus/2;
	    mov     si,ax		    ;save fat-num     ;
	    sar     ax,1		    ;div by 2	      ;
	    pushf			    ;save low bit     ;
	    add     si,ax		    ;clus + clus/2    ;
	    mov     bx,word ptr [bx][si]    ;	    b = b[i];
	    popf			    ;get low bit      ;
;	    $IF     C			;AN000;bgb
	    JNC $$IF3
		mov	cl,4			;	    b >>= 4;
		shr	bx,cl			;
;	    $ENDIF			;AN000;bgb
$$IF3:
getfat1:    and bh,0fh	     ;even fat-num  ;	    b &= 0xFFF; AC000;bgb
	    pop     ax			    ;	    }
;	$ENDIF				;AN000;bgb
$$EN1:
getret: mov	cx,secsiz		;   c = SecSize;
	return
EndProc GetFat

;
	break	<SetFat - change the contents of a fat element>
;*****************************************************************************
;   SetFat - given a fat index and a value, change the contents of the fat
;   cell to be the new value.
;
;   Inputs:	AX contains the fat cell to change
;		DX contains the new value to put into the fat cell
;   Outputs:	FAT [AX] = DX
;   Registers Revised: CX, SI
;
; LARGE FAT SUPPORT  - if this is a 16-bit fat, use the new calc algorithm
; *****************
;*****************************************************************************
Procedure SetFat,NEAR
	set_data_segment
	lea	bx,fattbl		;   b = &Table; 				   ;AC000;bgb
	cmp	MaxClus,4086 ;12 bit fat?   if (MaxClus >= 4086) {
;	$IF	AE  ;changed to above because max clusters now 'ffff'hex	;an005;bgb
	JNAE $$IF6
	    call    calc_fat_addr	    ; calc the fat cell addr		;an005;bgb
	    mov     word ptr es:[bx],dx     ; get the contents			;an005;bgb
;	$ELSE
	JMP SHORT $$EN6
$$IF6:
setsmall:   SaveReg <ax,dx>  ;yes, 12 bit fat
	    mov     si,ax    ; fat cell number	    i = clus + clus / 2;
	    sar     ax,1     ; fat cell num /2
	    pushf	     ; save result if ax was odd
	    add     si,ax    ; offset = 1 1/2 bytes * fat cell num
	    mov     ax,word ptr [bx][si]    ; get contents of fat cell
	    popf    ; get results from div  ;	    if ((clus&1) != 0) {
;	    $IF     C	; was fat cell num odd?
	    JNC $$IF8
		and	ax,000fh   ;yes 	;keep unchanged part
		mov	cl,4			;	    d <<= 4;
		shl	dx,cl
;	    $ELSE
	    JMP SHORT $$EN8
$$IF8:
setfat2:	and	ax,0f000h  ; no, even	;keep unchanged part
;	    $ENDIF
$$EN8:
setfat1:    or ax,dx		   ; move new value into ax
	    mov     word ptr [bx][si],ax    ;	    b[i] = a;
	    RestoreReg <dx,ax>
;	$ENDIF
$$EN6:
setret: return				;   return;
EndProc SetFat

;
	Break	<GetKeystroke - await a single keystroke and flush all remaining>
;*****************************************************************************
;   GetKeystroke - let the user hit a key and flush the input buffer.  Kanji/
;   Taiwanese force this
;
;   Inputs:	None.
;   Outputs:	None.
;   Registers Revised: AX
;*****************************************************************************
Procedure GetKeystroke,NEAR
	MOV	AX,(Std_CON_Input_Flush SHL 8) + Std_CON_Input_No_Echo
	INT	21H
	MOV	AX,(Std_CON_Input_Flush SHL 8) + 0
	INT	21H
	return
EndProc GetKeystroke


;*****************************************************************************
;PROMPT
;*****************************************************************************
Procedure Prompt,NEAR
	Cmp	Prompted,0
	retnz
	MOV	Prompted,1
	push	ds
	push	cs
; move drive letter in message
	lea	dx,askmsg		; AC000;SM					   ;AC000;bgb
; display msg
	call	DISPLAY_interface	;AC000;bgb
	pop	ax			; ;AN000;bgb
	pop	ds
; wait for user
	call	GetKeystroke

	    MOV     AL,cs:DRIVE 	; This is for ibm's single drive sys;AN000;bgb
	    CMP     AL,1
	    JA	    NOSET		; Values other than 0,1 are not appropriate.
	    PUSH    DS
	    MOV     BX,50H
	    MOV     DS,BX
	    MOV     DS:(BYTE PTR 4),AL	; Indicate drive changed
	    POP     DS
NOSET:

	return
EndProc Prompt


;
	Break	<Load	- set up registers for abs sector read/write>
;******************************************************************************
;   Load - load up all registers for absolute sector read/write of FAT
;
; called by: readft, writeft
;
;   Inputs:	none.
;   Outputs:	AL    - drive number (a=0)
;		ES:BX - point to FAT table					;an005;bgb
;		CX    - number of sectors in FAT
;		DX    - sector number of the first FAT sector
;		FatCnt - is set to the number of fats
;   Registers Revised: ax, dx, cx, bx
;******************************************************************************
Procedure Load,NEAR
	set_data_segment							;an005;bgb
	mov	dx,firfat		;sector number of first fat 1-65535
	mov	al,fatnum		;number of fats 	    2		 ;AC000;bgb
	mov	fatcnt,al		;FatCnt = FatNum;	    1-65535	 ;AC000;bgb
	mov	al,drive		;drive number		    a=0 b=1	;AN000;bgb
	mov	cx,fatsiz		;sectors in the fat	    1-65535
	lea	bx,fattbl		; es:bx --> fat table			;an005;bgb
	return
EndProc Load

	Break	<ReadFT - read in the entire fat>
;******************************************************************************
;   ReadFt - attempt to read in the fat.  If there are errors, step to
;   successive fats until no more.
;
;   Inputs:	none.
;   Outputs:	Fats are read until one succeeds.
;		Carry set indicates no Fat could be read.
;   Registers Revised: all
; LOGIC
; *****
;  DO for each of the fats on the disk:
;     read - all the sectors in the fat
;     increase the starting sector by the number of sectors in each fat
;
; LARGE FAT SUPPORT - the big change here is in read disk.  since the fat must	;an005;bgb
;     be within the first 32M, then the starting sector number of 65535 is ok,	;an005;bgb
;     as is a larger number of sectors to read/write.				;an005;bgb
;******************************************************************************
Procedure ReadFt,NEAR
	set_data_segment							;an027;bgb;an005;bgb
	mov	dx,firfat		;sector number of first fat 1-65535	;an027;bgb
	mov	al,fatnum		;number of fats 	    2		;an027;bgb ;AC000;bgb
	mov	fatcnt,al		;FatCnt = FatNum;	    1-65535	;an027;bgb ;AC000;bgb
	mov	al,drive		;drive number		    a=0 b=1	;an027;bgb;AN000;bgb
	mov	cx,fatsiz		;sectors in the fat	    1-65535	;an027;bgb
	lea	bx,fattbl		; es:bx --> fat table			;an027;bgb;an005;bgb
	clc				;clear carry flag			;an027;bgb
	mov	Read_Write_Relative.Start_Sector_High,bp ;set hi word to zero  ;AN000;
	call	Read_Disk		; read in fat #1		;AC000;
;	$IF  C				; was it a bad read?		     ;an027;bgb
	JNC $$IF12
	    add     dx,cx		;point to 2nd fat
	    call    Read_Disk		; read in 2nd fat		    ;AC000;
;	$ENDIF				;carry flag set if both fats bad       ;AC000;bgb
$$IF12:
ret										;an027;bgb
EndProc ReadFt


;
	Break	<WrtFat - write out the fat>
;*****************************************************************************
;   WrtFat - using the results of a ReadFt, attempt to write out the fat
;   until successful.
;
;   Inputs:	none.
;   Outputs:	A write of the fat is attempted in each fat position until
;		one succeeds.
;   Registers Revised: all
; LOGIC
; *****
;    DO for each fat on the disk
;	write the fat to disk
;	increase the starting sector number by the number of sectors per fat
;
; LARGE FAT SUPPORT - the big change here is in read disk.  since the fat must	;an005;bgb
;     be within the first 32M, then the starting sector number of 65535 is ok,	;an005;bgb
;     as is a larger number of sectors to read/write.				;an005;bgb
;****************************************************************************
Procedure WrtFat,NEAR
	call	load			;   load ();				;an005;bgb
;	$DO									;an005;bgb
$$DO14:
wrtit:	    call    Write_Disk		    ;	    Write_Disk ();		;an005;bgb
;	    $LEAVE  C								;an015;bgb
	    JC $$EN14
wrtok:	    add     dx,cx		    ;	    fatStart += fatsize;	;an005;bgb
	    dec     byte ptr fatcnt	    ;	} while (--fatcnt);		;an005;bgb
;	$ENDDO	Z								;an005;bgb
	JNZ $$DO14
$$EN14:
	return
EndProc WrtFat


;
	Break	<fEOF	- check to see if the argument is EOF>
;*****************************************************************************
;   fEOF - test BX to see if it indicates EOF
;
;   Inputs:	BX - contains cluster
;   Outputs:	Carry is set if BX indicates EOF
;   Registers Revised: none
;*****************************************************************************
Procedure fEOF,NEAR
    CMP     BX,MaxClus
	JBE	EOFok
	CMP	BL,0F7h 		; bad sector indicator
	JZ	EOFok
	STC
	return
EOFok:	CLC
	return
EndProc fEOF


;*****************************************************************************
;*****************************************************************************


;
	Break	<sfFromFCB - take an FCB and convert it to a sf pointer>
;*****************************************************************************
; SFFromFCB - index into System File tables for SFN.
;
;   Input:	ES:DI has FCB pointer
;   Output:	ES:DI points to Sys-File-table entry
;   Registers Revised: ES:DI, BX only
;
;*****************************************************************************
procedure SFFromFCB,NEAR
	MOV	BL,ES:[DI].FCB_SFN ;fcb+18 = system file table 00
	XOR	BH,BH		   ; 00
	SaveReg <AX,BX>
	MOV	AH,Get_IN_Vars		;52h
	INT	21h			;   p = DOSBASE();
					; bx = 0026, ax=5200 es=0257
	LES	DI,DWORD PTR ES:[BX].SYSI_FCB ;load es:di w/ ptr to sf table
					; es:di = 0b37:0000
	LEA	DI,[DI].sfTable 	; di=6			  AC000;bgb
	RestoreReg <BX>
	SaveReg <DX>
	MOV	AX,SIZE SF_Entry	;42
	MUL	BX			;0
	ADD	DI,AX			;6
	RestoreReg <DX,AX>
	return				;   return p;
EndProc SFFromFCB

;*****************************************************************************
;*****************************************************************************
Procedure get_dpb_info,Near				      ;AN000;bgb
; get dpb for drive indicated
	push	ds			;save ds seg reg
	mov	dl,drive		; get drive number a=0 b=1 c=2		;AN000;bgb
	inc	dl			; a=1, b=2, c=3
	mov	ah,GET_DPB		; hidden system call (032h)
	int	21h			; call dos
; note: ds is now changed !!!!
	cmp	al,0FFH 		; -1 = bad return code
;	$IF	NZ  ;AN000;bgb
	JZ $$IF17
; get sector size
	    mov     ax,word ptr [bx].dpb_sector_size ; get physical sector size
	    mov     es:bytes_per_sector,ax ; save bytes per sector 200		   ;AN000;bgb
; get sectors per cluster
	    xor     ch,ch		; zero out high byte ;ac000;bgb
	    mov     cl,byte ptr [bx].dpb_cluster_mask ; get sectors/cluster - 1
	    inc     cx			;1+1=2		  ; get sectors / cluster
	    mov     es:secall,cx	;2	   ; save sectors per cluster		   ;AC000;bgb
; get bytes per cluster
	    mul     cx			; ax = bytes per cluster
	    mov     eS:secsiz,ax	;400	   ; save bytes per cluster		   ;AC000;bgb
; first sector record
	    mov     ax,[bx].dpb_first_sector ; get record of first sector
	    mov     es:firrec,ax	;c	   ;					   ;AC000;bgb
;first	 dir	 entry
	    mov     dx,[bx].dpb_dir_sector ; get record of first directory entry
	    mov     es:firdir,dx	;5	   ;					   ;AC000;bgb
; first fat record
	    mov     si,[bx].dpb_first_fat ; get record of first fat
	    mov     es:firfat,si	;1     ; sector number of first fat		   ;AC000;bgb
; records in fat
	    mov     cX,[bx].dpb_fat_size ; get size of fat (num of rcds)	 ;AC000;BGB
	    mov     es:fatsiz,cX	;2	      ;SIZE OF FAT FROM DPB ;AC000;BGB
; number of cluster
	    mov     di,[bx].dpb_max_cluster ; get number of clusters
	    mov     es:lastfat,di	;163	     ; number of fat entries		  ;AC000;bgb
	    mov     es:MaxClus,di	;163	     ; number of fat entries		  ;AC000;bgb
; number of fats (1 or 2)
	    mov     ch,[bx].dpb_fat_count ; get number of fats on drive
	    mov     byte ptr es:fatnum,ch ;2   ; save number of fats on disk	    ;AC000;bgb
; max dir entries
	    mov     bx,[bx].dpb_root_entries ; get max number of dir entries
	    mov     ES:maxent,bx	;70	   ;					   ;AC000;bgb
	    pop     ds			; restore ds register to group		   ;AC000;bgb
;	$ELSE						      ;AN000;bgb
	JMP SHORT $$EN17
$$IF17:
	    pop     ds			; restore ds register to group		   ;AC000;bgb
	    jmp     noname		; bad return = display error msg
;	$ENDIF						      ;AN000;bgb
$$EN17:
	ret				;		      ;AN000;bgb
endproc get_dpb_info			    ;			  ;AN000;bgb
;

;
;*****************************************************************************
; assemble this part if doing japanese version
;
;INPUTS:  es:di - points to last char in filename
;	  ds:dx - point to beginning of filename
;
;*****************************************************************************
Procedure check_kanji,Near		;AN000;bgb
	IF	KANJI
	    lea     dx,[fname_buffer]	;point to filename ;AC000;bgb
	    PUSH    DX			;save regs
	    PUSH    DI			;save regs
	    MOV     BX,DI		;bx and di now point to last char in filename
	    MOV     DI,DX		;di now points to filename

;do for entrire filename
delloop:    CMP     DI,BX		;are we at the beginning of the filename?
	    JAE     GOTDELE		;yes, and we are finished
	    MOV     AL,[DI]		;get next char in filename
	    INC     DI			;point one past it
	    CALL    TESTKANJ		;see if it is dbcs
	    JZ	    NOTKANJ11
	    INC     DI			;bump to past 2nd of dbcs pair
	    JMP     DELLOOP		;check next char in file name
notkanj11:  cmp     al,[dirchar]	;is it '\' ?
	    JNZ     DELLOOP		;no, check next char
	    MOV     DX,DI		; Point to char after '/'
	    DEC     DX
	    DEC     DX			; Point to char before '/'
	    JMP     DELLOOP

;completed filename
gotdele:    MOV     DI,DX ;point to?
	    POP     AX			; Initial DI
	    POP     DX	  ;re-point to beginning of filename
	    SUB     AX,DI		; Distance moved
	    SUB     CX,AX		; Set correct CX
;	    CMP     DX,DI							;an024;bgb
;stop:	     $if     b								;an024;bgb
;		pop ax								;an024;bgb;an024;bgb
;		pop cx								;an024;bgb;an024;bgb;an024;bgb
;		jmp sja 							;an024;bgb
;;;;;;;;;;;;;;; JB	sja		    ; Found a pathsep			;an024;bgb
;	    $endif								;an024;bgb
;	    $if     a								;an024;bgb
;		pop ax								;an024;bgb;an024;bgb
;		pop cx								;an024;bgb;an024;bgb;an024;bgb
;		jmp sjb 							;an024;bgb
;;;;;;;;;;;;;;; JA	sjb		    ; Started with a pathsep, root	;an024;bgb
;	    $endif								;an024;bgb
	    MOV     AX,[DI]							;an024;bgb
	    CALL    TESTKANJ							;an024;bgb
	    JNZ     same_dirjk							;an024;bgb
	    XCHG    AH,AL							;an024;bgb
;	    cmp     al,[dirchar]						;an024;bgb
;	    $if     z								;an024;bgb
;		pop ax								;an024;bgb;an024;bgb;an024;bgb
;		pop cx								;an024;bgb;an024;bgb;an024;bgb
;		jmp sja 							;an024;bgb
;;;;;;;;;;;;;;;;jz	sja		    ; One character directory		;an024;bgb
;	    $endif								;an024;bgb
same_dirjk:
	    ret 							;AN000;bgb
	ENDIF
check_kanji endp			;				;AN000;bgb
;

;****************************************************************************
;****************************************************************************
	break
	IF	KANJI
TESTKANJ:   push    ds		 ;get dbcs vector				;an012;bgb
	    push    si
	    push    ax
	    mov     ax,6300h	 ;get dbcs vector				;an024;bgb;an012;bgb
	    int     21h 							;an012;bgb
	    pop     ax								;an024;bgb
	    sub     si,2	 ;prep for loop 				;an012;bgb
dbcsmore:									;an012;bgb
	    add     si,2		;point to next dbcs vector		;an012;bgb
	    cmp     word ptr ds:[SI],bp ;do until 00 found in dbcs vector table ;an012;bgb
	    je	    notlead		;00 found, quit 			;an012;bgb
	    CMP     AL,byte ptr ds:[si] ;look at lead byte of dbcs char 	;an012;bgb
	    jb	    dbcsmore		;al < lead byte means not dbcs		;an012;bgb
	    CMP     al,byte ptr ds:[si+1] ;look at 2nd byte of dbcs		;an012;bgb
	    JBE     ISLEAD  ;if it is between the 2 chars, it is dbcs		;an012;bgb
	    jmp     dbcsmore	 ;go get the next dbcs vector			;an012;bgb

NOTLEAD:
	    PUSH    AX
	    XOR     AX,AX		; Set zero
	    POP     AX
	    pop     si
	    pop     ds
	    RET
ISLEAD:
	    mov     es:dbcs_sw,1						   ;an024;bgb
	    PUSH    AX
	    XOR     AX,AX		; Set zero
	    INC     AX			; Reset zero
	    POP     AX
	    pop     si
	    pop     ds
	    RET
	ENDIF






;*****************************************************************************;an020;bgb
; copy the filename from the fcb to the data segment			      ;an020;bgb
;*****************************************************************************;an020;bgb
Procedure copy_fname,Near	       ;AN000;bgb				 ;an020;bgb
;get fcb1 from the psp
slashok: mov	 cx,PSP_Segment 	 ;Get addrbility of psp 	 ;AN000;bgb
	mov	ds,cx			;  "  "    "  "  "  "		;AN000;bgb
	assume	ds:dg,es:dg		; "   "    "  "  "  "		;AN000;bgb
	call	get_fcb

										;An018;bgb

; remove leading blanks and tabs from filename
nofspec: mov	 si,81h 		 ; point to command line		 ;AC000;bgb
	lea	di,fname_buffer 	; point to filename			;ac000;bgb
	xor	cx,cx			; zero pathname length
;	$DO		;get source chars until neither tabs or blanks found
$$DO20:
kill_bl:    lodsb			; get next char 			;AN000;bgb
	    cmp     al,tab		; leading tabs? (hex 9) 		;AN000;bgb
;	$LEAVE	NE,AND			; yes - done				    ;AN000;bgb
	JE $$LL21
	    cmp     al,' '		; leading blanks? (hex 20)		;AN000;bgb
;	$LEAVE	NE
	JNE $$EN20
$$LL21:
;	$ENDDO				;					;AN000;bgb
	JMP SHORT $$DO20
$$EN20:
;

;was any parameter entered at all?
endl:	cmp	al,13			; no name found if the 1st char is CR
	jne	next_char		; file name or drive entered
	jmp	noname			; no parameter entered



;copy filename from cmd line to fname buffer
next_char:
	stosb				; move byte in al to fname_buffer
	inc	cx			;inc fname counter
	lodsb				; get next byte
	cmp	al,' '			; terminated by blank?
	je	name_copied		; yes
	cmp	al,9			;terminated by tab?
	je	name_copied		; yes
	cmp	al,13			; terminated by CR?
	jne	next_char		; yes


;reset ds to data segment
name_copied:				; got file name
	push	es
	pop	ds			;ds now points to data seg
	assume	ds:dg

	mov	byte ptr [di],0 	; nul terminate the pathname
	dec	di			; adjust to the end of the pathname
	    ret 								;an020;bgb
copy_fname  endp			;					   ;an020;bgb




;*****************************************************************************;an020;bgb
; get a copy of the fcb 						      ;an020;bgb
;*****************************************************************************;an020;bgb
Procedure get_fcb,Near		    ;AN000;bgb				      ;an020;bgb
	mov	si,fcb			; ds:si point to fcb in the psp 	;AN000;bgb
	lea	di,fcb_copy		; es:di point to the copy in the data seg;AC000;bgb
	mov	cx,32			; move 32 bytes 			;AN000;bgb
	rep	movsb			; from ds:si (fcb) to es:di (fcb-copy)	  ;AN000;bgb
;check if it is not there (in psp)						;an024;bgb;an020;bgb
;	mov	si,fcb			;point to fcb1				;an024;bgb;AN014;bgb
;	cmp	byte ptr ds:[si+1],' '	;it will be blank if a filespec used	;an024;bgb;AN014;bgb
;	$IF	E,AND								;an024;bgb;Ac015;bgb
;	cmp	byte ptr ds:[84h],0dh	;this will be CR if drive letter used	;an024;bgb;AN015;bgb
;	$IF	NE	    ;if no drive letter and fcb blank, then filespec!	;an024;bgb;AN015;bgb
;now get the filename from the command line					;an024;bgb;an020;bgb
; step 1 - point to end of cmd line						;an024;bgb
	    mov     si,081h		;point to beginning of command line	;AN014;bgb
	    mov     cl,byte ptr ds:[80h] ;get length of cmd line		;AN014;bgb
	    xor     ch,ch		;zero out hi byte for word arith	;AN014;bgb
	    add     si,cx		;begin plus length of cmd line = end	;AN014;bgb
	    dec     si			;point to last char, not CR		;an020;bgb
;step 2 - find the first backslash						;an020;bgb
	    mov     exit_sw,bp ;false						;an024;bgb
;	    $DO 			;do until back slash found		;AN014;bgb
$$DO23:
		cmp	byte ptr ds:[si],'\'	 ;look for back slash		;AN014;bgb
;		$IF	E		;find it?				;an024;bgb;AN014;bgb
		JNE $$IF24
		    mov     al,[si-1]	;get possible leading byte		;an024;bgb
		    IF KANJI
		    call    testkanj	;is it a leading byte of DBCS?		;an024;bgb
		    ENDIF
;		    $IF     Z		;no- then it is subdir delimiter	;an024;bgb
		    JNZ $$IF25
			mov exit_sw,true    ;so exit the search loop		;an024;bgb
;		    $ELSE		;yes it is DBCS leading byte		;an024;bgb
		    JMP SHORT $$EN25
$$IF25:
			dec	si	;so skip the leading byte		    ;an024;bgb
;		    $ENDIF		;check for kanji			;an024;bgb
$$EN25:
;		$ENDIF								;an024;bgb
$$IF24:
		cmp	exit_sw,true						;an024;bgb
;		$LEAVE	E							;an024;bgb
		JE $$EN23
		cmp	byte ptr ds:[si],0	 ;look for 00 (not a filespec)	;AN018;bgb
;		$IF	E							;an020;bgb
		JNE $$IF30
		    ret 							;an020;bgb
;;;;;;;;;;;;;;;;je	nofspec 	;filespec not found			;ac020;bgb
;		$ENDIF								;an020;bgb
$$IF30:
		dec	si		;no , next char 			;AN014;bgb
;	    $ENDDO								;AN014;bgb
	    JMP SHORT $$DO23
$$EN23:
;found backslash, move it into fcb
	    inc     si			;point to 1st char of filename		;AN014;bgb
	    lea     di,fcb_copy+1	    ; move addr of fcb_copy into di	;an024;bgb;AN014;bgb
;	    $DO 			;do until eol - CR found		;AN014;bgb
$$DO33:
		lodsb			;get one byte of filename from cmd line ;AN014;bgb
		cmp	al,0dh		;end of line?				;AN014;bgb
;		$LEAVE	E		;if so, we are done			;AN014;bgb
		JE $$EN33
		cmp	al,'.'		;is it extension indicator?		;AN014;bgb
;		$IF	E		;yes					;AN014;bgb
		JNE $$IF35
		    lea     di,fcb_copy ;point to extension in fcb		;AN014;bgb
		    add     di,9	;point to extension in fcb		;AN014;bgb
;		$ELSE			;dont move the period			;AN014;bgb
		JMP SHORT $$EN35
$$IF35:
		    stosb		;move char into fcb			;AN014;bgb
;		$ENDIF								;AN014;bgb
$$EN35:
;	    $ENDDO								;AN014;bgb
	    JMP SHORT $$DO33
$$EN33:
;	$ENDIF									;AN014;bgb
	    ret 								;an020;bgb
get_fcb  endp			     ;						;an020;bgb
										;an020;bgb
										;an020;bgb
;
	Break	<Main	code of recover - Version check and exit if incorrect>
;*****************************************************************************
;Routine name:	Main_routine
;*****************************************************************************
;
;description: Main routine for recovering a file from a bad sector
;
;Called from:	recover_ifs in RECINIT.SAL
;
;
;Called Procedures: prompt
;		    readft
;		    read_file
;		    getfat (sic)
;		    feof
;		    sffromFCB
;		    bad-file-read
;		    report
;		    wrtfat
;		    stdprintf
;		    RECPROC.SAL
;
;Input: ????
;
;Output: FAT is changed if a bad sector is found.
;	 The file is complete except for the data in the bad sector.
;
;Change History: header created 7-19-87 	BGB
;
;Psuedocode
;----------
;
;*****************************************************************************
Main_Routine:

;get system switch character
	xor	bp,bp
	set_data_segment		; set es,ds to data			;AN000;bgb
		;;;;;;; call	change_blanks		; get dbcs blanks			;an012;bgb
	mov	ax,(char_oper shl 8)	; get switch character
	int	21h			; put into dl
	cmp	dl,"/"			; is it / ?
;	$IF	nz
	JZ $$IF39
	    jmp     slashok		    ; if not / , then not PC
;	$ENDIF
$$IF39:
	mov	[dirchar],"\"	     ; in PC, dir separator = \
	mov	[userdir],"\"

	call	copy_fname

;check for dbcs double byte chars
	push	di								;an019;bgb
	push	cx								;an019;bgb
	call	check_kanji
same_dirj:
	pop	cx							    ;an019;bgb
	pop	di							    ;an019;bgb
	mov	lastchar,di


;see if there are any '\' in filename parameter - means filespec		;an024;bgb
;do until a \ is found or end-of-string 					;an024;bgb
;	  if a \ is found							;an024;bgb
;	     then test for dbcs leading byte					;an024;bgb
;		  if it is not dbcs leading byte				;an024;bgb
;		     then exit loop						;an024;bgb
;		     else continue loop 					;an024;bgb
;   $DO 									;an024;bgb
$$DO41:
	dec	cx								;an024;bgb
	and	cx,cx ;compare cx to zero					;an024;bgb
;   $LEAVE  E									;an024;bgb
    JE $$EN41
	mov	al,[dirchar]	    ;05ch ; get directory separator character	;an024;bgb
	cmp	al,byte ptr [di]    ; (cx has the pathname length)		;an024;bgb
;	$IF	E			; reset direction, just in case 	;an024;bgb
	JNE $$IF43
	    mov     al,[di-1]	    ;get possible leading byte			;an024;bgb
	    IF KANJI
	       call    testkanj     ;see if it is leading byte			;an024;bgb
	    ENDIF
;	    $IF      Z		    ;not a leading byte? then its a '\' 	;an024;bgb
	    JNZ $$IF44
		mov lastbs,di							;an024;bgb
		mov di,lastchar 						;an024;bgb
		jmp sja 	    ;zero = not a leading byte			;an024;bgb
;	    $ENDIF								;an024;bgb
$$IF44:
;	$ENDIF									;an024;bgb
$$IF43:
	dec	di								;an024;bgb
;   $ENDDO									;an024;bgb
    JMP SHORT $$DO41
$$EN41:
;save current disk								;an008;bgb
	mov	ah,19h								;an008;bgb
	int	21h								;an008;bgb
	mov	old_drive,al							;an008;bgb
	jmp	same_dir		; no dir separator char. found, the
					; file is in the current directory
					; of the corresponding drive. Ergo,
					; the FCB contains the data already.


;handle filespec here
;at least one '\' found in filename
sja:
	jcxz	sjb			; no more chars left, it refers to root
	push	di								;an024;bgb
	mov	di,lastbs							;an024;bgb
	cmp	byte ptr [di-1],':'	  ; is the prvious character a disk def?;an024;bgb
	pop	di								;an024;bgb
	jne	not_root
sjb:
	mov	[the_root],01h		; file is in the root
not_root:
	inc	di			; point to dir separator char.
	mov	ax,bp ;set to zero
	stosb				; nul terminate directory name
;	pop	ax
;	push	di			; save pointer to file name
	mov	[fudge],01h		; remember that the current directory
					; has been changed.
;save current disk								;an008;bgb
	mov	ah,19h								;an008;bgb
	int	21h								;an008;bgb
	mov	old_drive,al							;an008;bgb
;----- Save current directory for exit ---------------------------------;
	mov	dl, drive		; get specified drive if any
;;;;;;; or	dl,dl			; default disk? 			;an021;bgb
;;;;;;; jz	same_drive							;an021;bgb
;;;;;;;;dec	dl			; adjust to real drive (a=0,b=1,...)	;an021;bgb
	mov	ah,set_default_drive	; change disks
	int	21h
;	cmp	al,-1			; error?
;	jne	same_drive
;BADDRVSPEC:
;	 lea	 dx,baddrv    ; AC000;SM					;AC000;bgb
;	 jmp	 printerr

same_drive:
	call	prompt
	mov	ah,Current_Dir		; userdir = current directory string
	mov	dx,bp ;set to zero
	lea	si,userdir+1		;AC000;bgb
	int	21h

;----- Change directories ----------------------------------------------;
	cmp	[the_root],01h
	lea	dx,[dirchar]		; assume the root				   ;AC000;bgb
	je	sj1
	lea	dx,[fname_buffer]	;AC000;bgb
sj1:
	push	di								;an024;bgb
	mov	di,lastbs							;an024;bgb
	mov	byte ptr [di],0 					   ;an024;bgb
	mov	ah,chdir		; change directory
	int	21h
	mov	byte ptr [di],'\'							 ;an024;bgb
	pop	di								;an024;bgb
	mov	al,Drive		;Get drive number		;AN000;bgb
	add	al,"A"-1		;Make it drive letter		;AN000;
	mov	Drive_Letter_Msg,al	;Put in message 		;AN000;
	lea	dx,baddrv		;AC000;bgb
	jnc	no_errors
	call	printerr
	jmp	rabort

;
no_errors:

	Break	<Set	up exception handlers>

;----- Parse filename to FCB -------------------------------------------;
;	pop	si								;an024;bgb
	mov	si,lastbs							;an024;bgb
	inc	si								;an024;bgb
	lea	di,fcb_copy		;AC000;bgb
	mov	ax,(parse_file_descriptor shl 8) or 1
	int	21h
;;;;;;;;push	ax
;-----------------------------------------------------------------------;
same_dir:
	lea	bx,fcb_copy		;point to 1st byte of fcb (drive num)  ;AC000;bgb
	cmp	byte ptr [bx+1],' '	; must specify file name
	jnz	drvok
	cmp	byte ptr [bx],0 ;or drive specifier
	jnz	drvok
	cmp	dbcs_sw,1		; or dbcs				;an024;bgb
	jz	drvok								;an024;bgb
noname: 				;AC000;bgb
	push	es
	pop	ds
	lea	dx,baddrv		;AC000;bgb
	call	display_interface	; AC000;bgb
	pop	ax		 ;reset stack					;an024;bgb
	pop	ax		 ;reset stack					;an024;bgb
	jmp	int_23
;****************************************************************************
; we're finished with parsing here, do the main function of recover.
drvok:
	CALL	Prompt			;wait for user keystroke to begin ;AN000;bgb
	call	get_dpb_info		;get device info		  ;AN000;bgb
	call	fill_fat		; fill fat table w/ null	  ;AN000;bgb
;	$IF	C			;was there not enuff memory to run?	;an013;bgb
	JNC $$IF48
	    lea     dx,no_mem_arg	;					;an013;bgb
	    call    printerr							;an013;bgb
	    jmp     rabort							;an013;bgb
;	$ENDIF				;fat could be read from disk		;an013;bgb
$$IF48:

	call	readft			;   readft ();			  ;AN000;bgb
;	$IF	C			; could the fat be read from disk? ;AN000;bgb
	JNC $$IF50
	    lea     dx,FATErrRead	;					       ;AC000;bgb
	    call    printerr
	    jmp     rabort
;	$ENDIF				;fat could be read from disk	   ;AN000;bgb
$$IF50:
See_If_File:				;					;AN000;
	lea	bx,fname_buffer 	;					;AC014;bgb
	cmp	byte ptr [bx+1],':'	;if fname = 'a:' and.....		;ac020;bgb
;	$IF	E,AND			    ;					;an020;bgb
	JNE $$IF52
	cmp	word ptr [bx+2],bp ;set to zero       ;all zeros following that, then	      ;an020;bgb
;	$IF	E			;then drive spec			;AN202;BGB
	JNE $$IF52
	    call    drive_spec		;only drive specified ;AN000;bgb
;	$ELSE				; file name specified ;AN000;bgb
	JMP SHORT $$EN52
$$IF52:
	    call    file_spec ;file can be 'f' or 'a:,0,file' or 'a:file' or 'file.ext' ;an020;bgb
;	$ENDIF						      ;AN000;bgb
$$EN52:


int_23: sti				;allow interrupts			;an026;bgb
	lds	dx,cs:dword ptr [int_24_old_off]     ;point to old vector	   ;an026;bgb
	mov	al,24h			;which interrupt to set?		;an026;bgb;AC000;
	DOS_Call Set_Interrupt_Vector	;set vector to old			;an026;bgb;AC000;

	lds	dx,cs:dword ptr [int_23_old_off]     ;point to old vector	;an026;bgb
	mov	al,23h			;which interrupt to set?		;an026;bgb;AC000;
	DOS_Call Set_Interrupt_Vector	;set vector to old			;an026;bgb;AC000;

	PUSH	CS			;reset ds				;an026;bgb
	POP	DS								;an026;bgb
aSSUME	DS:DG									;an026;bgb
	call	rest_dir
										;an026;bgb
	mov	cs:ExitStatus,0 	   ; good return			   ;AC000;
	jmp	[exitpgm]						       ;an026;bgb
rabort:
	ret				;Return to RECINIT for exit		;AC000;
					; mov	  ah,exit
					; int	  21h


;*************************************************************************
; DO until either
;*************************************************************************
procedure file_spec,near				      ;AN000;bgb
; try to open the file
recfil: lea	dx,fcb_copy		;   if (FCBOpen (FCB) == -1) {		;AC000;bgb
	mov	ah,FCB_OPEN   ; function ofh = open
	int	21h			;returns -1 in al if bad open
	cmp	al,0ffh 		;was file opened ok?  ;AN000;bgb
;	$IF	E			; no		 ;AN000;bgb
	JNE $$IF55
; display error msg
	    lea     si,FCB_Copy.fcb_name ;Point at filename in FCB	 ;	;AC000;bgb
	    lea     di,Fname_Buffer	;Point at buffer		;	;AC000;bgb
	    mov     cx,FCB_Filename_Length ;Length of filename		   ;AN000;
	    call    Change_Blanks	;Convert DBCS blanks to SBCS	;AN000;
	    call    Build_String	;Build ASCIIZ string ending	;AN000;
	    lea     dx,opnerr		; AC000;SM	printf (Can't open);    ;AC000;bgb
	    call    display_interface	; AC000;bgb
;ecfil0: $ELSE				;   LastFat = 1; ;AN000;bgb
recfil0:
	 JMP SHORT $$EN55
$$IF55:
f_exists:   call    process_file	;file was opend ok
rexit1:     mov     ah,DISK_RESET
	    int     21h
	    call    wrtfat		; save the fat
;	    $IF     C			;Couldn't write it                       ;AN000;
	    JNC $$IF57
		lea	dx,FATErrWrite	;Just tell user he is in deep!		;AC000;bgb
		call	display_interface ;					;AN000;bgb
;	    $ELSE
	    JMP SHORT $$EN57
$$IF57:
		call	report			    ;	report ();		;ac015;bgb
;	    $ENDIF			;AN000;bgb;				;AN000;
$$EN57:
;	$ENDIF				;AN000;bgb
$$EN55:
	ret				;AN000;bgb
endproc file_spec			    ;AN000;bgb

;*************************************************************************
; DO until either
;*************************************************************************
Procedure process_file,Near		    ;				    ;AN000;
recfile0:
    mov     lastfat,1			;set to 1 : means 1st fat read in
    lea     di,fcb_copy 		;   d = &FCB				;AC000;bgb
    mov     ax,[di].FCB_FilSiz		;55    siztmp = filsiz = d->filsiz;
    mov     filsiz,ax
    mov     siztmp,ax
    mov     ax,[di].FCB_FilSiz+2	;00
    mov     filsiz+2,ax
    mov     siztmp+2,ax
    SaveReg <ES,DI>			;   fatptr =
    call    sfFromFCB			;	sfFromFCB(d)->firclus;
    mov     ax,ES:[DI].sf_firclus	; es:di +0b = 84
    RestoreReg <DI,ES>
    mov     fatptr,ax
    or	    ax,ax			;   if (fatptr == 0)
;   $IF     NZ				;AN000;bgb
    JZ $$IF61
; read each fat in the file
;	$DO				;Loop until entire file read in ;AN000;bgb
$$DO62:
	    mov     bx,fatptr		;Get current cluster
	    call    fEOF		;Got to the end of the file?
;	$LEAVE	C			;Yes if CY			;AN000;bgb
	JC $$EN62
STOP_read:	call	Read_File	;Go read in the cluster
;	    $IF     C			;CY indicates an error		;AN000;bgb
	    JNC $$IF64
		call	Bad_File_Read	;Go play in the FAT
;	    $ELSE			;Read cluster in okay		;AN000;bgb
	    JMP SHORT $$EN64
$$IF64:
		mov	ax,secsiz	;Get bytes/cluster
		sub	siztmp,ax	;Is size left < 1 cluster?
		sbb	siztmp+2,bp ;zero      ;
;		$IF	C		;Yes				;AN000;bgb
		JNC $$IF66
		    xor     ax,ax	;Set our running count to 0
		    mov     siztmp,ax
		    mov     siztmp+2,ax
;		$ENDIF			;AN000; 			;AN000;bgb
$$IF66:
		mov	ax,fatptr	;The previous cluster is now
		mov	lastfat,ax	; the current cluster
;	    $ENDIF			;AX has current cluster 	;AN000;bgb
$$EN64:
	    call    getfat		;Get the next cluster
	    mov     fatptr,bx		;Save it
;	$ENDDO				;Keep chasing the chain 	;AN000;bgb
	JMP SHORT $$DO62
$$EN62:
;   $ENDIF				;All done with data		;AN000;bgb
$$IF61:
; recover extended attributes							;an032;bgb
;   SaveReg <ES,DI>			;Save regs			;AN000; ;an032;bgb
;   call    sfFromFCB			;Get sf pointer 		;AN000; ;an032;bgb
;   mov     ax,[di].sf_ExtCluster	;Look at extended attrib entry	;AN000; ;an032;bgb
;   cmp word ptr [di].sf_ExtCluster,bp ;zero   ;Is there extended attribs?     ;;an032;bgbAN000;
;   $IF     NE				;Yes				;AN000; ;an032;bgb
;	call	Read_File		;Try to read it in		;AN000; ;an032;bgb
;	$IF	C			;CY means we couldn't           ;AN000; ;an032;bgb
;	    mov word ptr [di].sf_ExtCluster,bp ;zero	     ;Off with its head!;an032;bgb;AN000;
;	    and ES:[di].sf_flags,NOT devid_file_clean ; mark file dirty ;AN000; ;an032;bgb
;	$ENDIF				;				;AN000; ;an032;bgb
;   $ENDIF				;				;AN000; ;an032;bgb
;   RestoreReg <DI,ES>			;				;AN000; ;an032;bgb
    lea     dx,fcb_copy 		;   close (FCB);		;AC000;bgb
    mov     ah,FCB_CLOSE
    int     21h 			;
  return				;AN000;bgb
endproc process_file			;AN000;bgb

;*************************************************************************
;***************************************************************************
	break
;----- Restore INT 24 vector and old current directory -----------------;
Procedure Rest_dir,Near 		;				;AN000;
	cmp	cs:[fudge],0
;	$IF	NE
	JE $$IF71
	    mov     ax,(set_interrupt_vector shl 8) or 24h
	    lds     dx,cs:[hardch]
	    int     21h
	    push    cs
	    pop     ds
	    lea     dx,userdir		    ; restore directory 		;AC000;bgb
	    mov     ah,chdir
	    int     21h
;	$ENDIF
$$IF71:
no_fudge:
	mov	dl,old_drive		; restore old current drive		;an008;bgb
	mov	ah,set_default_drive
	int	21h
	ret
endproc rest_dir

;;----- INT 24 Processing -----------------------------------------------;
;*************************************************************************
	int_24_retaddr dw int_24_back

	int_24	proc	far
	assume	ds:nothing,es:nothing,ss:nothing
	pushf				; ** MAKE CHANGES **
	push	cs
	push	[int_24_retaddr]
	push	word ptr [hardch+2]
	push	word ptr [hardch]
	assume	ds:dg,es:dg,ss:dg	;AN000;bgb
	ret
endproc int_24
;*************************************************************************
int_24_back:
	cmp	al,2			; abort?
	jnz	ireti
	push	cs
	pop	ds
assume	ds:dg,es:dg,ss:dg
	call	rest_dir
	ret				;Ret for common exit	     ;AC000;
ireti:
	iret

	break	< read in a cluster of the file>
;****************************************************************************
; READ_FILE
;Read in cluster of file.
;
; Input: Secall = sectors/cluster
;	 FatPtr = cluster to read
;	 Firrec = Start of data area - always in first 32mb of partition
;	 dx	= offset of fcb_copy ???
;
; Output: CY set if error on read on ret
;	  DI = pointer to FCB
;*****************************************************************************
Procedure Read_File,Near		;				;AN000;
	mov	cx,secall   ;2		;if (aread((fatptr-2)*secall+firrec) == -1) {
	mov	ax,fatptr   ;84 	;cluster number to read
	sub	ax,2	    ;ax=82	; -1 ;AN000;bgb
	mul	cx	    ;ax=104	; sectors/clus * (clus-2)
	add	ax,firrec   ;ax=110	; plus beg of data area
	adc	dx,bp	    ;0		;Handle high word of sector	      ;AN000;
	mov	Read_Write_Relative.Start_Sector_High,dx ;Start sector		      ;AN000;
	mov	dx,ax	    ;110	;clus-2
	mov	es,table    ;2b62	;segment of area past fat table 	;an005;bgb
	xor	bx,bx			;es:bx --> dir/file area		;an005;bgb
	mov	al,drive    ;0		;drive num  ;AN000;bgb
	call	Read_Disk		;	    ;					    ;AC000;
	lea	di,fcb_copy		;					;AC000;bgb
	ret				;				;AN000;
endproc Read_File			    ;				    ;AN000;


	break	< found a bad cluster in the file >
;*************************************************************************
;Play around with the FAT cluster chain, by marking the cluster that failed
;to read as bad. Then point the preceding cluster at the one following it.
;Special case if there is only one cluster, than file gets set to zero
;length with no space allocated.
;
; Input: FatPtr = Cluster that failed to read
;	 LastFat = Previous cluster, equals 1 if first cluster
;
; Output: AX = previous cluster
;	  File size = file size - cluster size ( = 0 if cluster size > file)
;***************************************************************************
Procedure Bad_File_Read,Near
	mov	ax,fatptr		;Get current cluster
	call	getfat			;Get the next cluster in BX
	cmp	lastfat,1		;Is this the first entry?
;	$IF	E			;Yes				      ;AC000;
	JNE $$IF73
	    call    fEOF		;Is the next the last cluster?
;	    $IF     C			;Yes				      ;AC000;
	    JNC $$IF74
		xor	bx,bx		;Need to zero out first cluster
;	    $ENDIF			; because the first one is bad!       ;AN000;
$$IF74:
	    SaveReg <ES,DI,BX>		;Save some info
	    call    sfFromFCB		;Get pointer to sf table
	    RestoreReg <BX>		;Get back clus to point to
	    mov     ES:[DI].sf_firclus,BX ;Skip offending cluster
	    RestoreReg <DI,ES>		;Get back regs
;	$ELSE				;Not first entry in chain	;AC000;
	JMP SHORT $$EN73
$$IF73:
	    mov     dx,bx		;DX = next cluster
	    mov     ax,lastfat		;AX = Previous cluster
	    call    setfat  ;prev fat points to next fat
					; offending cluster
;	$ENDIF				; Ta-Da!			;AN000;
$$EN73:
	mov	ax,fatptr		;Get the offending cluster
	mov	dx,0fff7h		;Mark it bad
	call	setfat			;Never use it again!
	mov	ax,secsiz		;Get bytes/sector
	cmp	siztmp+2,bp		;Is file  < 32mb long?
;	$IF	NE,AND			;     and			;AC000;
	JE $$IF78
	cmp	siztmp,ax		;Shorter than cluster size?
;	$IF	BE			;Yes				;AC000;
	JNBE $$IF78
	    mov     ax,siztmp		;File size = smaller of the two
;	$ENDIF				;AN000;
$$IF78:
	SaveReg <ES,DI> 		;Save regs
	call	sfFromFCB		;Get sf pointer
sfsize: sub	word ptr ES:[di].sf_size,ax ;Adjust internal file sizes
	sbb	word ptr ES:[di].sf_size+2,bp ;   "  "	 "  "
	sub	siztmp,ax		;Keep track of how much done
	sbb	siztmp,bp		 ;
	and	ES:[di].sf_flags,NOT devid_file_clean ; mark file dirty
	RestoreReg <DI,ES>		;	    sfFromFCB(d)->flags &= ~CLEAN;
	lea	di,fcb_copy
	sub	word ptr [di].fcb_filsiz,ax ;And change the FCB
	sbb	word ptr [di].fcb_filsiz+2,bp ;
	and	byte ptr [di].fcb_nsl_bits,NOT devid_file_clean ; mark file dirty	  ;AN000;
	mov	ax,lastfat		;AX = previous cluster
	ret				;				      ;AN000;
endproc Bad_File_Read			    ;				    ;AN000;


;*****************************************************************************	;an005;bgb
; description: fill the fat table in memory with the 'E5' character		;an005;bgb
;										;an005;bgb
; called from: main-routine							;an005;bgb
;										;an005;bgb
;Change History: Created	8/7/87	       bgb				;an005;bgb
;										;an005;bgb
;Input: bytes-per-sector							;an005;bgb
;	fatsiz									;an005;bgb
;	maxent									;an005;bgb
;										;an005;bgb
;Output: ram-based fat table							;an005;bgb
;										;an005;bgb
; LOGIC 									;an005;bgb
;----------									;an005;bgb
;	calc number of para in fat table					;an005;bgb
;	    = bytes-per-sector / 16 * sectors-per-fat				;an005;bgb
;	calc segment of directory area in memory				;an005;bgb
;	    = fat-table offset + length of fat-table				;an005;bgb
;	calc number of para in directory					;an005;bgb
;	    = entries-per-directory * bytes-per-entry / 16			;an005;bgb
;	do for each para							;an005;bgb
;	   move 16 bytes into memory						;an005;bgb
;*****************************************************************************	;an005;bgb
	  even
Procedure fill_fat,Near 		;AN000;bgb				;an005;bgb
; calc fat table length 							;an005;bgb
	set_data_segment							;an005;bgb
	mov	ax,bytes_per_sector	; bytes per sector			;an005;bgb
	xor	dx,dx								;an005;bgb
	mov	bx,16								;an005;bgb
	div	bx			; paras per sector			;an005;bgb
	mov	cx,fatsiz		;2	   ; get sectors per fat	;an005;bgb
	xor	dx,dx								;an005;bgb
	mul	cx			; paras per fat 			;an005;bgb
	mov	paras_per_fat,ax	;length of fat in paragraphs		;an005;bgb
; calc dir area addr								;an005;bgb
	mov	bx,es
	add	ax,bx			;seg of dir area			;an005;bgb
	mov	es,ax
	lea	bx,fattbl		;off					;an005;bgb
	call	seg_adj 		;seg:off = seg:0000			;an005;bgb
	mov	table,es		;segment of beginning of fat table	;an005;bgb
; calc dir area length								;an005;bgb
	mov	ax,maxent		;ax= max dir entries			;an005;bgb
	mov	bx,32			; 32 bytes per dir entry		;an005;bgb
	xor	dx,dx								;an005;bgb
	mul	bx			; bytes per dir 			;an005;bgb
	xor	dx,dx			;zero out for divide			;an005;bgb
	mov	bx,16			;divide by bytes per para		;an005;bgb
	div	bx			;paras per dir				;an005;bgb
; calc total length to fill							;an005;bgb
	add	ax,paras_per_fat ;paras/fat + paras/dir = total paras		;an005;bgb
; see if we have enough memory							;an013;bgb
    push    ax									;an013;bgb
    push    ds				;save ds reg				;an013;bgb
    mov     bx,es
    add     ax,bx			;add in starting seg of fat table	;an013;bgb
    inc     ax				; one more to go past our area		;an013;bgb
    DOS_Call GetCurrentPSP		;Get PSP segment address		;an013;bgb
    mov     ds,bx			;ds points to the psp			;an013;bgb
    Assume  DS:Nothing			;point to psp				;an013;bgb
    MOV     DX,DS:[2]			;get the last para of memory		;an013;bgb
    pop     ds									;an013;bgb
    assume  ds:dg
    cmp     dx,ax		     ;last-para must be greater or equal	;an013;bgb
;   $IF     AE		;it was, so complete filling the fat			;an013;bgb
    JNAE $$IF80
	pop	ax								    ;an013;bgb
;fill each para 								;an005;bgb
	push	ds
	pop	es
	lea	bx,fattbl		; es:di = point to beg of fat table	;an005;bgb
	call	seg_adj
	mov	di,bx
	mov	bx,ax			;total number of paras to do		;an005;bgb
	mov	ax,0e5e5h		;fill characters  Fill (d, 16*dirent, 0xe5e5);;an005;bgb
;	$DO				;do for each para			;an005;bgb
$$DO81:
	   mov	   cx,8 		   ; number of times to repeat		;an005;bgb
	   xor	   di,di		;bump addr pointers by 16 bytes -
	   rep	   stosw		   ; mov 2 bytes, 1 ea for 16 * num-of-entries	;an005;bgb
	   dec	   bx			;loop counter				;an005;bgb
;	$LEAVE	 Z			;until zero				;an005;bgb
	JZ $$EN81
	   mov	   dx,es		;since we move more than 64k total, we
	   inc	   dx			;have to bump es by 1 para, keeping
	   mov	   es,dx		;di at zero
;	$ENDDO									;an005;bgb
	JMP SHORT $$DO81
$$EN81:
;   $ELSE			     ;not enough memory 			;an013;bgb
    JMP SHORT $$EN80
$$IF80:
	pop ax									;an013;bgb
	stc			     ;set carry flag indicating badddd!!!	;an013;bgb
;   $ENDIF									;an013;bgb
$$EN80:
    return			    ;AN000;bgb				    ;an005;bgb
endproc fill_fat			;AN000;bgb				;an005;bgb
;

;

;*****************************************************************************
;*****************************************************************************
Procedure printerr,Near 		;AN000;bgb
	push	cs
	pop	ds
	PUSH	DX			; Save message pointer
	mov	dl,[user_drive] 	; restore old current drive
	mov	ah,set_default_drive
	int	21h
	POP	DX
	call	display_interface	; AC000;bgb
	mov	al,0ffh 		;   erc = 0xFF;
	ret				;AN000;bgb
endproc printerr			    ;AN000;bgb		  ;AN000;


;*************************************************************************
; CHK_FAT:
;
; inputs:  AX - last fat number for a file
;	   CX - bytes per cluster
;*************************************************************************
Procedure chk_fat,Near			;				;AN000;bgb
	push es
step1a: mov	filsiz,bp		 ;start the file size at 0
	mov	word ptr filsiz+2,bp	 ;start the file size at 0
	mov	dx,MaxClus		;	dx = MaxClus;
	mov	target,ax		; target = last fat in this file
	mov	exit_sw2,bp ;false	; set exit switch to no
;	$DO	COMPLEX 		; DO until exit 		 ;AN000;bgb
	JMP SHORT $$SD86
$$DO86:
	    mov     target,ax		;    do this 2+ times around
;	$STRTDO 			;    START here 1st time	 ;AN000;bgb
$$SD86:
step2:	    add     filsiz,cx		;add in cluster size
	    adc     word ptr filsiz+2,bp ;inc 2nd word if there was a carry
	    mov     ax,2		;start at first cluster
;	    $DO 			;DO until exit		     ;AN000;bgb
$$DO88:
Step3:		call	getfat		;   bx= contents of fat cell
		cmp	bx,target	;   reached the end of file yet?
;	    $LEAVE   E			;   yes - return to outer loop;AN000;bgb
	    JE $$EN88
step4:		inc	ax		;   no - inc target
		cmp	ax,dx		;	target > max-clusters?
;		$IF	NBE		;	yes			 ;AN000;bgb
		JBE $$IF90
		    mov     exit_sw2,true ;	      request exit both loops
;		$ENDIF			;				 ;AN000;bgb
$$IF90:
		cmp	exit_sw2,true	 ;	 exit requested?
;	    $ENDDO  E			;    $ENDDO if exit requested	 ;AN000;bgb
	    JNE $$DO88
$$EN88:
endlop2:    cmp     exit_sw2,true	 ;    outer loop test- exit requested?
;	$ENDDO	E			; ENDDO if exit requested	 ;AN000;bgb
	JNE $$DO86
	pop es				;	else- go do mov target,ax
	ret								 ;AN000;bgb
endproc chk_fat 						     ;AN000;bgb


;*****************************************************************************
;*****************************************************************************
	  even
Procedure main_loop1,Near		;AN000;bgb
;	$DO				;AN000;bgb
$$DO94:
	    call    read_fats		;inner loop AN000;bgb
	    cmp     exit_sw,true	; 1st way out of loop - fatptr>maxclus
;	$LEAVE	E			;  goto step7		     AN000;bgb
	JE $$EN94
	    call    chk_fat		; ended read_fats on carry from feof
; at this point target = head of list, filsiz = file size
step4a:     inc     filcnt		;   filcnt++;
	    mov     ax,maxent		;   if (filcnt > maxent)
	    cmp     filcnt,ax		; more files than possible dir entries?
;	    $IF     A			; yes - this is an error	       ;AN000;bgb
	    JNA $$IF96
direrr: 	dec	filcnt
		lea	dx,dirmsg	;						   ;AC000;bgb
		call	display_interface ;					;an006;bgb
		mov	exit_sw,true
;	    $ENDIF			;AN000;bgb
$$IF96:
nodirerr:   cmp     exit_sw,true
;	$LEAVE	E			;AN000;bgb
	JE $$EN94
	    call    fill_dir
	    mov     ax,fatptr
	    cmp     ax,MaxClus
;	$LEAVE	A			;AN000;bgb
	JA $$EN94
;ndlop1: $ENDDO 			 ;AN000;bgb
endlop1:
	 JMP SHORT $$DO94
$$EN94:
	ret								;AN000;bgb
endproc main_loop1			    ;				    ;AN000;bgb


;*****************************************************************************
; purpose: this procedure looks at all the fats for a particular file, until
;	   the end of file marker is reached. then returns
; inputs:  AX = fat cell number 2
; outputs: if any of the
;*****************************************************************************
Procedure read_fats,Near	       ;AN000;bgb
	push es
	mov	filsiz,bp		 ;start the file size at 0		;an027;bgb
	mov	word ptr filsiz+2,bp	 ;start the file size at 0		;an027;bgb
;	$DO				;AN000;bgb
$$DO101:
step1:	    call    getfat		;   if (fEOF (GetFat (a)) {
	    add     filsiz,cx		;add in cluster size			;an027;bgb
	    adc     word ptr filsiz+2,bp ;inc 2nd word if there was a carry	;an027;bgb
	    call    fEOF		;
;	$LEAVE	C			; goto step1a		       AN000;bgb
	JC $$EN101
step6:	    inc     fatptr		;   if (++fatptr <= MaxClus)
	    mov     ax,fatptr
	    cmp     ax,MaxClus
;	    $IF     A			;AN000;bgb
	    JNA $$IF103
		mov	exit_sw,true
;	    $ENDIF			;AN000;bgb
$$IF103:
	    cmp     exit_sw,true	; time to end?		      ;AN000;bgb
;	$ENDDO	E			;	goto step7	      ;AN000;bgb
	JNE $$DO101
$$EN101:
	pop es
	ret				;AN000;bgb
endproc read_fats			   ;				   ;AN000;bgb

;*****************************************************************************
;*****************************************************************************
	even
Procedure fill_dir,Near ;AN000;bgb
	lea	si,dirent+7		;   s = &dirent[7];				  ;AC000;bgb
;	$DO				;AN000;bgb
$$DO106:
nam0:	    inc     byte ptr [si]	;   while (++*s > '9')
	    cmp     byte ptr [si],'9'
;	$LEAVE	LE			;AN000;bgb
	JLE $$EN106
	    mov     byte ptr [si],'0'	;	*s-- = '0';
	    dec     si
;	$ENDDO							     ;AN000;bgb
	JMP SHORT $$DO106
$$EN106:
nam1:	mov	ah,GET_DATE		;   dirent.dir_date = GetDate ();
	int	21h
	sub	cx,1980 		; cx = 87
	add	dh,dh			; dh = 1-12
	add	dh,dh
	add	dh,dh
	add	dh,dh
	add	dh,dh			; dh = dh * 32 (32-384)
	rcl	cl,1
	or	dh,dl
	mov	byte ptr dirent+24,dh
	mov	byte ptr dirent+25,cl
	mov	ah,GET_TIME		;   dirent.dir_time = GetTime ();
	int	21h
	shr	dh,1			;seconds/2
	add	cl,cl			;minutes
	add	cl,cl
	add	cl,cl			;mins * 8
	rcl	ch,1
	add	cl,cl
	rcl	ch,1
	add	cl,cl
	rcl	ch,1
	or	dh,cl
	mov	byte ptr dirent+22,dh
	mov	byte ptr dirent+23,ch
	mov	ax,filsiz		;   dirent.dir_fsize = filsiz;
	mov	word ptr dirent+28,ax
	mov	ax,word ptr filsiz+2
	mov	word ptr dirent+30,ax
	mov	ax,target		;   dirent.dir_firclus = target;
	mov	word ptr dirent+26,ax
	lea	si,dirent		; di:si --> directory entry		;an005;bgb
	mov	cx,32			;move 32 bytes - 1 dir entry		;an005;bgb
	rep	movsb			;move ds:si to es:di, then		;an005;bgb
					;inc di and inc si			;an005;bgb
	inc	fatptr			;   if (++fatptr <= MaxClus)
	ret				;AN000;bgb
endproc fill_dir			   ;				   ;AN000;bgb
;
;*****************************************************************************
; DRIVE_SPEC -	this procedure is executed if the user only specifies a drive
;		letter to recover.
;*****************************************************************************
Procedure drive_spec,Near		;AN000;bgb
recdsk: xor	di,di			;init addr of dir/file area		;an005;bgb
	mov	es,table		;es:di --> area 			;an005;bgb
			 ;this addr is incremented by the rep movsb in fill_dir ;an005;bgb
	mov	fatptr,2		;INIT FATPTR	 ;   a = fatPtr = 2;
	mov	ax,fatptr		;
	MOV	exit_sw,bp ; false	; default to continue looping until true
	call	main_loop1
step7:	mov	al,drive		;AN000;bgb
	mov	dx,firdir		; write out constructed directory
	mov	cx,firrec
	sub	cx,dx
	xor	bx,bx			;addr of dir area			;an005;bgb
	mov	es,table		;seg of dir area			;an005;bgb
	call	Write_Disk
;	$IF	NC			;good write?				;an015;bgb
	JC $$IF109
	    lea     dx,recmsg		    ;						      ;AC000;bgb
	    mov     si,filcnt
	    mov     rec_num,si
	    call    display_interface	    ; AC000;bgb
;	$ENDIF									;an015;bgb
$$IF109:
rexit2: mov	ah,DISK_RESET
	int	21h
	call	wrtfat			; save the fat
;	$IF	C			;Couldn't write it              ;AN000;bgb         ;AN000;bgb
	JNC $$IF111
	    lea     dx,FATErrWrite	;Just tell user he is in deep!		;    ;AC000;bgb
	    call    display_interface	;					;AN000;bgb
;	$ENDIF				;				;AN000;bgb	  ;AN000;bgb
$$IF111:
	ret								;AN000;bgb
endproc drive_spec			    ;				    ;AN000;bgb
;
	pathlabl recover

include msgdcl.inc

code	ends
	end				;recover ;AC000;bgb

