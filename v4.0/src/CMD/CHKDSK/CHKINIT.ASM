page	,132					;
;*****************************************************************************
;*****************************************************************************
;UTILITY NAME: CHKOVER.COM
;
;MODULE NAME: CHKINIT.SAL
;
;ÚÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Main_Init ³
;ÀÄÂÄÄÄÄÄÄÄÄÄÙ
;  ³
;  ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿     ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  Ã´Init_Input_OutputÃÄÄÄÄÂ´Preload_Messages³
;  ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;  ³			   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  ³			   Ã´Parse_Drive_Letter ³
;  ³			   ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;  ³			   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  ³			   Ã´Parse_Command_Line ³
;; ³			   ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;  ³			   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  ³			   À´Interpret_Parse³
;  ³			    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;  ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  Ã´Validate_Target_DriveÃÂ´Check_Target_Drive³
;  ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;  ³			   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  ³			   Ã´Check_For_Network³
;  ³			   ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;  ³			   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  ³			   À´Check_Translate_Drive³
;  ³			    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;  ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  Ã´Hook_Interrupts³
;  ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;  ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  Ã´Clear_Append_X³
;  ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;  ³ÚÄÄÄÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  Ã´CHKDSK_IFSÃÂ´EXEC_FS_CHKDSK³
;  ³ÀÄÄÄÄÄÄÄÄÄÄÙ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;  ³		³ÚÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  ³		À´Main_Routine³
;  ³		 ÀÄÄÄÄÄÄÄÄÄÄÄÄÙ
;  ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  À´Reset_Append_X³
;   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;*****************************************************************************
;;an099;dcl for p3202
;*****************************************************************************

;
;*****************************************************************************
; Include files
;*****************************************************************************
.xlist										;an000;bgb
include chkseg.inc					   ;an005;bgb		;an000;bgb
include pathmac.inc								;an000;bgb
INCLUDE CHKEQU.INC				;				;an000;bgb;AN000;
INCLUDE CHKCHNG.INC				;List of changes		;an000;bgb
include dossym.inc								;an000;bgb
INCLUDE SYSCALL.INC				;				;an000;bgb;AN000;
INCLUDE CHKMACRO.INC				;				;an000;bgb;AN000;
INCLUDE CHKPARSE.INC				;				;an000;bgb;AN000;
INCLUDE IOCTL.INC								;an000;bgb
.list										;an000;bgb
										;an000;bgb
										;an000;bgb
										;an000;bgb
psp    segment public para 'DUMMY'						;an000;bgb
	org	05Ch								;an000;bgb
FCB1	label	byte								;an000;bgb
	org	06Ch								;an000;bgb
FCB2	label	byte								;an000;bgb
psp    ends									;an000;bgb
										;an000;bgb
;										;an000;bgb
DATA	segment public para 'DATA'						;an000;bgb
;*****************************************************************************	;an000;bgb
; Data	Area									;an000;bgb
;*****************************************************************************	;an000;bgb
old_drive db 0									;an000;bgb

include version.inc

IF  IBMCOPYRIGHT

ELSE

myramdisk db 'RDV 1.20'

ENDIF

myvdisk   db 'VDISK'								;an000;bgb
bytes_per_sector     dw   0			;an005;bgb			;an000;bgb
BPB_Buffer A_DeviceParameters <>		;				;an000;bgb;AN000;
										;an000;bgb
Data_Start_Low dw ?				;				;an000;bgb;AN000;
Data_Start_High dw ?				;				;an000;bgb
										;an000;bgb
public command_line_buffer							;an046;bgb
Command_Line_Buffer db 128 dup(0)		;				;an000;bgb;AN000;
Command_Line_Length equ $ - Command_Line_Buffer ;				;an000;bgb;AN000;
										;an046;bgb
Fatal_Error db	0				;				;an000;bgb;AN000;
										;an000;bgb
Command_Line db NO				;				;an000;bgb
Append	db	0				;				;an000;bgb
										;an000;bgb
ifdef	fsexec									;an038;bgb
 ;These should stay together			 ;				;an038;bgb
 ; ---------------------------------------	 ;  ;				;an038;bgb
 FS_String_Buffer db 13 dup(" ")		 ;				;an038;bgb
 FS_String_End db "CHK.EXE",0			 ;				;an038;bgb
 Len_FS_String_End equ $ - FS_String_End	 ;				;an038;bgb
 ;----------------------------------------	 ;				;an038;bgb
 FS_Not_Fat db	 0				 ;				;an038;bgb
 FAT12_String db "FAT12   "			 ;				;an038;bgb
 FAT16_String db "FAT16   "			 ;				;an038;bgb
 Len_FS_ID_String equ $ - FAT16_String		 ;				;an038;bgb
 Media_ID_Buffer Media_ID <>			 ;				;an038;bgb
endif										;an038;bgb

ExitStatus db	0				;				;an000;bgb;AN000;
										;an000;bgb
PSP_Segment dw	0				;				;an000;bgb;AN000;
tot_bytes_lo  dw  0		     ; low word of number of sectors in disk	;an000;bgb;an006;bgb
tot_bytes_hi  dw  0		     ;high word of number of sectors in disk	;an000;bgb;an006;bgb
fat_dir_secs  dw  0		     ;sectors in fat, directory and resvd	;an000;bgb;an006;bgb
										;an000;bgb
;*****************************************************************************	;an000;bgb
; Public Data Declarations							;an000;bgb
;*****************************************************************************	;an000;bgb
	public	bpb_buffer							;an000;bgb;an006;bgb
	public	tot_bytes_lo							;an000;bgb;an006;bgb
	public	tot_bytes_hi							;an000;bgb;an006;bgb
	public	fat_dir_secs							;an000;bgb;an006;bgb
	public	bytes_per_sector						;an000;bgb;an005;bgb
	Public	Data_Start_Low							;an000;bgb
	Public	Data_Start_High 						;an000;bgb
	Public	Fatal_Error							;an000;bgb
	Public	ExitStatus							;an000;bgb
	Public	PSP_Segment							;an000;bgb
ifdef	fsexec									;an038;bgb
	Public	FS_String_Buffer						;an038;bgb
endif										;an038;bgb
;										;an000;bgb
;*****************************************************************************	;an000;bgb
; External Data Declarations							;an000;bgb
;*****************************************************************************	;an000;bgb
	EXTRN	movsi:word  ;move si pointer here for display of invalid parm	;an046;bgb;an000;bgb;an005;bgb
	EXTRN	fatcnt:Byte							;an000;bgb;an005;bgb
	EXTRN	AllDrv:Byte							;an000;bgb
	EXTRN	VolNam:Byte							;an000;bgb
	EXTRN	BadDrvM:Byte							;an000;bgb
	EXTRN	OrphFCB:Byte							;an000;bgb
	EXTRN	Arg_Buf:Byte							;an000;bgb
	EXTRN	Noisy:Byte							;an000;bgb
	EXTRN	DoFix:Byte							;an000;bgb
	EXTRN	SubstErr:Byte							;an000;bgb
	EXTRN	No_Net_Arg:Byte 						;an000;bgb
	EXTRN	UserDev:Byte							;an000;bgb
	EXTRN	BadDrv_Arg:Byte 						;an000;bgb
	EXTRN	TranSrc:Byte							;an000;bgb
	EXTRN	ContCh:Word							;an000;bgb
	EXTRN	HardCh:Word							;an000;bgb
	EXTRN	Fragment:Byte							;an000;bgb
	EXTRN	Parse_Error_Msg:Byte						;an000;bgb
	EXTRN	Chkprmt_End:Byte						;an000;bgb
	extrn	save_drive:byte 						;an000;bgb
	EXTRN	Read_Write_Relative:Byte					;an000;bgb
	EXTRN	inval_media:byte						;an000;bgb;an033;bgb
data	ends									;an000;bgb
										;an000;bgb
										;an000;bgb
code	segment public para 'CODE'						;an000;bgb
;*****************************************************************************	;an000;bgb
; External Routine Declarations 						;an000;bgb
;*****************************************************************************	;an000;bgb
ifdef	fsexec									;an038;bgb
	EXTRN	Exec_FS_CHKDSK:Near						;an000;bgb
endif
	EXTRN	SysLoadMsg:Near 						;an000;bgb
	EXTRN	SysDispMsg:Near 						;an000;bgb
	EXTRN	Done:Near							;an000;bgb
	EXTRN	Main_Routine:Near						;an000;bgb
	EXTRN	INT_23:Near							;an000;bgb
	EXTRN	INT_24:Near							;an000;bgb
	EXTRN	Path_Name:Near							;an000;bgb
	extrn	read_once:near							;an000;bgb

	public	p97, multiply_32_bits						;an000;bgb
	public	func60								;an000;bgb
	public	hook_interrupts 						;an000;bgb
	public get_bpb									;an000;bgb

   pathlabl chkinit							   ;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name:	Main_Init							;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description: Main control routine for init section				;an000;bgb
;										;an000;bgb
;Called Procedures: Check_DOS_Version						;an000;bgb
;		    Init_Input_Output						;an000;bgb
;		    Validate_Target_Drive					;an000;bgb
;		    Hook_Interrupts						;an000;bgb
;		    Clear_Append_X						;an000;bgb
;		    CHKDSK_IFS							;an000;bgb
;		    Reset_Append_X						;an000;bgb
;										;an000;bgb
;Input: None									;an000;bgb
;										;an000;bgb
;Output: None									;an000;bgb
;										;an000;bgb
;Change History: Created	5/8/87	       MT				;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	Set segregs to DATA							;an000;bgb
;	Get segment of PSP							;an000;bgb
;	Fatal_Error = NO							;an000;bgb
;	Flush all buffers (INT 21h AH=0Dh)					;an000;bgb
;	Parse input and load messages (CALL Init_Input_Output)			;an000;bgb
;	IF !Fatal_Error 							;an000;bgb
;	   Check target drive letter (CALL Validate_Target_Drive)		;an000;bgb
;	   IF !Fatal_Error							;an000;bgb
;	      Set up Control Break (CALL Hook_Interrupts)			;an000;bgb
;	      IF !Fatal_Error							;an000;bgb
;		 CALL Clear_Append_X						;an000;bgb
;		 CALL CHKDSK_IFS						;an000;bgb
;		 CALL Reset_Append_X						;an000;bgb
;	      ENDIF								;an000;bgb
;	   ENDIF								;an000;bgb
;	ENDIF									;an000;bgb
;	Exit program								;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
Procedure Main_Init				;				;an000;bgb;AN000;
	Set_Data_Segment			;Setup addressibility		;an000;bgb;AN000;
	call get_psp								;an000;bgb
;;;;;;;;DOS_Call GetCurrentPSP			;Get PSP segment address	;an000;bgb;ac034;bgb
;;;;;;;;mov	PSP_Segment,bx			;Save it for later		;an000;bgb;ac034;bgb
	mov	Fatal_Error,No			;Init the error flag		;an000;bgb;AN000;
	Dos_Call	Disk_Reset		;Flush all buffers		;an000;bgb
	call	Init_IO 			;Setup messages and parse	;an000;bgb;AN000;
	cmp	Fatal_Error,Yes 		;Error occur?			;an000;bgb;AN000;
;	$IF	NE				;Nope, keep going		;an000;bgb;AN000;
	JE $$IF1
	   call    Validate_Target_Drive	;Check drive letter		;an000;bgb;AN000;
	   cmp	   Fatal_Error,Yes		;Error occur?			;an000;bgb;AN000;
;	   $IF	   NE				;Nope, keep going		;an000;bgb;AN000;
	   JE $$IF2
;;;;;;;;;;;;;;call    Hook_Interrupts		;Set CNTRL -Break hook		;an000;bgb;AN000;
	      call    Clear_Append_X		;				;an000;bgb;AN000;
	      call    CHKDSK_IFS		;Chkdsk correct file system	;an000;bgb;AN000;
	      call    Reset_Append_X		;				;an000;bgb;AN000;
;	   $ENDIF				;				;an000;bgb;AN000;
$$IF2:
;	$ENDIF					;				;an000;bgb;AN000;
$$IF1:
	mov	al,ExitStatus			;Get Errorlevel 		;an000;bgb;AN000;
	DOS_Call Exit				;Exit program			;an000;bgb;AN000;
	int	20h				;If other exit fails		;an000;bgb;AN000;
Main_Init endp					;				;an000;bgb;AN000;
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: get_psp								;an000;bgb
;*****************************************************************************	;an000;bgb
;Description: get info from the psp area					;an000;bgb
;										;an000;bgb
;Called Procedures: get_drive							;an000;bgb
;										;an000;bgb
;Change History: Created	8/7/87	       bgb				;an000;bgb
;										;an000;bgb
;Input: none									;an000;bgb
;										;an000;bgb
;Output: psp_segment								;an000;bgb
;	 command_line_buffer							;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;	get addr of psp 							;an000;bgb
;	move command line into data seg 					;an000;bgb
;	get drive number of target						;an000;bgb
;	get addr of data seg							;an000;bgb
;	call get_drive								;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
Procedure get_psp			;;AN000;				;an000;bgb
;;;;;;;;DOS_Call GetCurrentPSP		;Get PSP segment address	:AN035;b;an000;bgbgb
;;;;;;;;mov	PSP_Segment,bx		;Save it for later		;AN035;b;an000;bgbgb
; get command line from psp							;an000;bgb;AN000;bgb
	mov	cx,PSP_Segment		;point ds to data seg			;an000;bgb;AN000;bgb
	mov	ds,cx			;  "   "   "   "    "                   ;an000;bgb;AN000;bgb
	assume	ds:NOTHING,es:dg	;  "   "   "   "    "                   ;an000;bgb;AN000;bgb
; get the drive number of the target from the psp (0=default, a=1, b=2, c=3) ;AN;an000;bgb000;bgb
	mov	bl,ds:[FCB1]	    ;Get target drive from FCB -74	    ;AN0;an000;bgb00;
	Set_Data_Segment	    ;Set DS,ES to Data segment		    ;AN0;an000;bgb00;bgb
	call	get_drive							;an000;bgb
	ret									;an000;bgb
get_psp   endp				;				;AN000; ;an000;bgb
										;an000;bgb
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: get_drive							;an000;bgb
;*****************************************************************************	;an000;bgb
;Description: get drive letter from reg bl					;an000;bgb
;										;an000;bgb
;Change History: Created	8/7/87	       bgb				;an000;bgb
;										;an000;bgb
;Input: bl = drive num (default=0)						;an000;bgb
;										;an000;bgb
;Output: driveletter								;an000;bgb
;	 user_drive								;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;	IF drive-num = default							;an000;bgb
;	   get default drive number (a=1)					;an000;bgb
;	   convert to letter							;an000;bgb
;	ELSE									;an000;bgb
;	   convert to letter							;an000;bgb
;	ENDIF									;an000;bgb
;	move letter into data areas						;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
Procedure get_drive			;;AN000;				;an000;bgb
; convert drive number to drive letter						;an000;bgb
	    cmp     bl,0  ;a=1 b=2 c=3	;Is it default drive? 0=default ;AN000; ;an000;bgb
;	    $IF     E			;Yes, turn it into drive letter ;AN000; ;an000;bgb
	    JNE $$IF5
; get default drive number							;an000;bgb
		DOS_Call Get_Default_Drive ;Get default drive num in al    ;AN00;an000;bgb0;
					;a=0, b=1, c=2				;an000;bgb
;	    $ELSE			;Not default, A=1		;AN000; ;an000;bgb
	    JMP SHORT $$EN5
$$IF5:
; bl already contains the correct drive number - save it			;an000;bgb
		dec	bl		;make it zero based			;an000;bgb
		mov	al,bl							;an000;bgb
;	    $ENDIF			; 74+40=b4				;an000;bgb
$$EN5:
	    mov     BadDrvm+1,al		 ; "  "    "  " 		;an000;bgb ;AN000;
	    inc     al								;an000;bgb
	    mov     byte ptr Buffer.drnum_stroff,al			     ;	;an000;bgb   ;
	    mov     AllDrv,al			 ;				;an000;bgb ;AC000;
	    mov     VolNam,al			 ;				;an000;bgb ;AC000;
	    mov     OrphFCB,al			 ;				;an000;bgb ;AC000;
	    dec     al								;an000;bgb
	    add     al,"A"		;convert it to letter		;AN000; ;an000;bgb
	    mov     arg_buf,al	    ;set up prompt msg			    ;AN0;an000;bgb00;bgb
	ret									;an000;bgb
get_drive endp				;				;AN000; ;an000;bgb
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Init_Input_Output						;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;description: Initialize messages, Parse command line if FAT file system	;an000;bgb
;										;an000;bgb
;Called Procedures: Preload_Messages						;an000;bgb
;		   Parse_Command_Line						;an000;bgb
;										;an000;bgb
;Change History: Created	5/10/87 	MT				;an000;bgb
;										;an000;bgb
;Input: PSP command line at 81h and length at 80h				;an000;bgb
;										;an000;bgb
;Output: FS_Not_FAT = YES/NO							;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	FS_Not_FAT = NO 							;an000;bgb
;	Load messages (CALL Preload_Messages)					;an000;bgb
;	IF !Fatal_Error 							;an000;bgb
;	   Get file system type (INT 21h AX=440Dh, CX=084Eh GET MEDIA_ID)	;an000;bgb
;	   IF CY (Old type diskette),OR 					;an000;bgb
;	   IF "FAT_12  ",OR							;an000;bgb
;	   IF "FAT_16  "							;an000;bgb
;	      CALL Parse_Command_Line						;an000;bgb
;	      IF !Fatal_Error							;an000;bgb
;		 Interpret_Parse						;an000;bgb
;	      ENDIF								;an000;bgb
;	   ELSE 								;an000;bgb
;	      Get drive letter only (CALL Parse_Drive_Letter)			;an000;bgb
;	      FS_Not_FAT = YES							;an000;bgb
;	   ENDIF								;an000;bgb
;	ENDIF									;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
Procedure Init_IO		      ; 			      ;AN000;	;an000;bgb
										;an000;bgb
	call	Preload_Messages		;Load up message retriever	;an000;bgb;AN000;
ifdef	fsexec									;an038;bgb
	mov	FS_Not_FAT,No							;an038;bgb
	cmp	Fatal_Error,YES 		;Quit?				;an038;bgb;AN000;
;	$IF	NE				;Nope, keep going		;an038;bgb;AN000;
	JE $$IF8
	   mov	   al,GENERIC_IOCTL		;Generic IOCtl call		;an038;bgb;AN000;
	   push    ds				;				;an038;bgb;AN000;
	   mov	   bx,PSP_Segment		;				;an038;bgb;AN000;
	   mov	   ds,bx			;				;an038;bgb;AN000;
	   assume  ds:nothing			;				;an038;bgb;AN000;
										;an038;bgb
	   mov	   bl,ds:FCB1			;Get drive (A=1)		;an038;bgb;AN000;
										;an038;bgb
	   pop	   ds				;				;an038;bgb;AN000;
	   assume  ds:dg			;				;an038;bgb;AN000;
	   xor	   bh,bh			;Set bh=0			;an038;bgb;AN000;
	   mov	   ch,RawIO			;Get Media ID call		;an038;bgb;AN000;
	   mov	   cl,GET_MEDIA_ID		;				;an038;bgb;AN000;
	   lea	   dx,Media_ID_Buffer		;Point at buffer		;an038;bgb;AN000;
	   DOS_Call IOCtl			;Do function call		;an038;bgb;AN000;
;	   $IF	   C,OR 			;Old style diskette, OR 	;an038;bgb;AN000;
	   JC $$LL9
	   lea	   si,FAT12_String		;Check for FAT_12 string	;an038;bgb;AN000;
	   lea	   di,Media_ID_Buffer.Media_ID_File_System ;		 ;AN000;;an038;bgb
	   mov	   cx,Len_FS_ID_String		;Length of compare		;an038;bgb;AN000;
	   repe    cmpsb			;Find it?			;an038;bgb;AN000;
;	   $IF	   E,OR 			;Nope, keep going		;an038;bgb;AN000;
	   JE $$LL9
	   lea	   si,FAT16_String		;Check for FAT_16 string	;an038;bgb;AN000;
	   lea	   di,Media_ID_Buffer.Media_ID_File_System ;		 ;AN000;;an038;bgb
	   mov	   cx,Len_FS_ID_String		;Length of compare		;an038;bgb;AN000;
	   repe    cmpsb			;Do compare			;an038;bgb;AN000;
;	   $IF	   E				;Find it?			;an038;bgb;AN000;
	   JNE $$IF9
$$LL9:
endif										;an038;bgb
	      call    Parse_Command_Line	;Parse in command line input	;an038;bgb;AN000;
ifdef	fsexec									;an038;bgb
;	   $ELSE				;We got FS other than FAT	;an038;bgb;AN000;
	   JMP SHORT $$EN9
$$IF9:
;;;;;;;;;;;;;;call    Parse_Drive_Letter	;Only look for drive letter	;an038;bgb;AN000;
	      mov     FS_Not_FAT,Yes		;Indicate exec file system	;an038;bgb;AN000;
		mov	cx,8							;an038;bgb;an027;bgb
		lea	si,Media_ID_Buffer.Media_ID_File_System ;get file system;an038;bgb ;an027;bgb
		lea	di,fs_string_buffer ;put it here			;an038;bgb;an027;bgb
		rep	movsb							;an038;bgb;an027;bgb
		lea	di,fs_string_buffer ;point to beginning again		;an038;bgb;an027;bgb
;		$DO	COMPLEX 	;search th string until eol found	;an038;bgb;an027;bgb
		JMP SHORT $$SD11
$$DO11:
		    inc     di		;next char				;an038;bgb;an027;bgb
;		$STRTDO 		;start loop here			;an038;bgb;an027;bgb
$$SD11:
		    cmp     byte ptr [di],' '	 ;end of string ?		;an038;bgb;an027;bgb
;		$ENDDO	E		;end loop when eol found		;an038;bgb;an027;bgb
		JNE $$DO11
		lea	si,fs_string_end ;get end of string - rec.exe		;an038;bgb;an027;bgb
		mov	cx,8		; 8 more chars				;an038;bgb;an027;bgb
		rep	movsb		;move it in				;an038;bgb;an027;bgb
;	   $ENDIF				;				;an038;bgb;AN000;
$$EN9:
;	$ENDIF					;				;an038;bgb;AN000;
$$IF8:
endif										;an038;bgb
	ret					;				;an000;bgb;AN000;
										;an000;bgb
Init_IO endp			      ; 			      ;AN000;	;an000;bgb
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Preload_Messages 						;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description: Preload messages using common message retriever routines. 	;an000;bgb
;										;an000;bgb
;Called Procedures: SysLoadMsg							;an000;bgb
;										;an000;bgb
;										;an000;bgb
;Change History: Created	5/1/87	       MT				;an000;bgb
;										;an000;bgb
;Input: Fatal_Error = NO							;an000;bgb
;										;an000;bgb
;Output: Fatal_Error = YES/NO							;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	Preload All messages (Call SysLoadMsg)					;an000;bgb
;	IF error								;an000;bgb
;	   Display SysLoadMsg error message					;an000;bgb
;	   Fatal_Error = YES							;an000;bgb
;	ENDIF									;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
Procedure Preload_Messages			;				;an000;bgb;AN000;
						;				;an000;bgb
	call	SysLoadMsg			;Preload the messages		;an000;bgb;AN000;
;	$IF	C				;Error? 			;an000;bgb;AN000;
	JNC $$IF16
	   call    SysDispMsg			;Display preload msg		;an000;bgb;AN000;
	   mov	   Fatal_Error, YES		;Indicate error exit		;an000;bgb;AN000;
;	$ENDIF					;				;an000;bgb;AN000;
$$IF16:
	ret					;				;an000;bgb;AN000;
										;an000;bgb
Preload_Messages endp				;				;an000;bgb;AN000;
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Parse_Drive_Letter						;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description: Copy the command line - then parse looking only for drive 	;an000;bgb
;		 letter. Ignore errors, because this is only called to get	;an000;bgb
;		 the drive letter for non-FAT chkdsk				;an000;bgb
;										;an000;bgb
;Called Procedures: SysParse							;an000;bgb
;										;an000;bgb
;Change History: Created	5/12/87 	MT				;an000;bgb
;										;an000;bgb
;Input: Command line input at 81h						;an000;bgb
;										;an000;bgb
;Output: None									;an000;bgb
;										;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;	Copy command line to buffer						;an000;bgb
;	DO									;an000;bgb
;	   Parse buffer line (CALL SysParse) using drive letter only tables	;an000;bgb
;	LEAVE end of parse							;an000;bgb
;	ENDDO missing operand							;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
;Procedure Parse_Drive_Letter			 ;				 ;an000;bgb;AN000;
;	Set_Data_Segment			;Set DS,ES to Data segment	;an000;bgb;AN000;
;	mov	cx,PSP_Segment			;Get segment of PSP		;an000;bgb;AN000;
;	mov	ds,cx				;  "  "    "  " 		;an000;bgb;AN000;
;	assume	ds:nothing			;				;an000;bgb;AN000;
;	mov	si,Command_Line_Parms		;Point to command line		;an000;bgb;AN000;
;	lea	di,Command_Line_Buffer		;Point to buffer to save to	;an000;bgb;AN000;
;	mov	cx,Command_Line_Length		;Number of bytes to move	;an000;bgb;AN000;
;	rep	movsb				;Copy the entire buffer 	;an000;bgb;AN000;
;	Set_Data_Segment			;				;an000;bgb;AN000;
;	lea	si,Command_Line_Buffer		;Pointer to parse line		;an000;bgb;AN000;
;	lea	di,input_table			;Pointer to control table	;an000;bgb;AN000;
;	$DO					;Parse for drive letter 	;an000;bgb;AN000;
;	   xor	   dx,dx			;Parse line @SI 		;an000;bgb;AN000;
;	   xor	   cx,cx			;Parse table @DI		;an000;bgb;AN000;
;	   call    SysParse			;Go parse			;an000;bgb;AN000;
;	   cmp	   ax,End_Of_Parse		;Check for end of parse 	;an000;bgb;AN000;
;	$LEAVE	E				;In other words, no drive letter;an000;bgb;AN000;
;	   cmp	   ax,Operand_Missing		; exit if positional missing	;an000;bgb;AN000;
;	$ENDDO	E				;Ignore errors!!!		;an000;bgb;AN000;
;	Set_Data_Segment			;				;an000;bgb;AN000;
;	ret					;				;an000;bgb;AN000;
;										;an000;bgb
;Parse_Drive_Letter endp			 ;				 ;an000;bgb;AN000;
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Parse_Command_Line						;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description: Parse the command line. Check for errors, and display error and	;an000;bgb
;		 exit program if found. Use parse error messages except in case ;an000;bgb
;		 of no parameters, which has its own message			;an000;bgb
;										;an000;bgb
;Called Procedures: Message (macro)						;an000;bgb
;		    SysParse							;an000;bgb
;		    Interpret_Parse						;an000;bgb
;										;an000;bgb
;Change History: Created	5/1/87	       MT				;an000;bgb
;										;an000;bgb
;Input: Fatal_Error = NO							;an000;bgb
;	PSP_Segment								;an000;bgb
;										;an000;bgb
;Output: Fatal_Error = YES/NO							;an000;bgb
;	 Parse output buffers set up						;an000;bgb
;										;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;	SEARCH									;an000;bgb
;	   Parse command line (CALL SysParse)					;an000;bgb
;	EXITIF end of parsing command line					;an000;bgb
;	   Figure out last thing parsed (Call Interpret_Parse)			;an000;bgb
;	ORELSE									;an000;bgb
;	   See if parse error							;an000;bgb
;	ENDLOOP parse error							;an000;bgb
;	   See what was parsed (Call Interpret_Parse)				;an000;bgb
;	   Fatal_Error = YES							;an000;bgb
;	ENDSRCH 								;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
Procedure Parse_Command_Line			;				;an000;bgb;AN000;
										;an000;bgb
	push	ds				;Save data segment		;an000;bgb;AN000;
	Set_Data_Segment			;				;an000;bgb;AN000;
	mov	cx,PSP_Segment			;Get segment of PSP		;an000;bgb;AN000;
	mov	ds,cx				;  "  "    "  " 		;an000;bgb;AN000;
										;an000;bgb
	assume	ds:nothing,es:dg		;				;an000;bgb;AN000;
										;an000;bgb
	mov	si,Command_Line_Parms		;Point at command line		;an000;bgb;AN000;
	lea	di,Command_Line_Buffer		;Where to put a copy of it	;an000;bgb;AN000;
	mov	cx,Command_Line_Length		;How long was input?		;an000;bgb;AN000;
	repnz	movsb				;Copy it			;an000;bgb;AN000;
	lea	Di,Command_Line_Buffer		;				;an046;bgb
public nextdi									;an046;bgb
nextdi: 									;an046;bgb
	mov	al,0dh				;search for end of line 	;an046;bgb
	cmp	al,ES:[Di]			   ;zero terminate string	   ;an046;bgb
;	$IF	NZ								;an046;bgb
	JZ $$IF18
	    inc    di								;an046;bgb
	    jmp    nextdi							;an046;bgb
;	$ELSE									;an046;bgb
	JMP SHORT $$EN18
$$IF18:
	    mov    byte ptr ES:[di+1],00					;an046;bgb
;	$ENDIF									;an046;bgb
$$EN18:
										;an046;bgb
	Set_Data_Segment			;Set DS,ES to Data segment	;an000;bgb;AN000;
	xor	cx,cx				;				;an000;bgb;AN000;
	xor    dx,dx			       ;Required for SysParse call     ;;an000;bgbAN000;
	lea	si,Command_Line_Buffer		;Pointer to parse line		;an000;bgb  ;AN000;
	lea	di,input_table			;Pointer to control table	;an000;bgb   ;AN000;
;	$SEARCH 				;Loop until all parsed		;an000;bgb;AN000;
$$DO21:
	   cmp	   Fatal_Error,Yes		;Interpret something bad?	;an000;bgb;AN000;
;	$EXITIF E,OR				;If so, don't parse any more    ;an000;bgb;AN000;
	JE $$LL22
	   call    SysParse			;Go parse			;an000;bgb;AN000;
	   cmp	   ax,End_Of_Parse		;Check for end of parse 	;an000;bgb;AN000;
;	$EXITIF E				;Is it? 			;an000;bgb;AN000;
	JNE $$IF21
$$LL22:
						;All done			;an000;bgb;AN000;
;	$ORELSE 				;Not end			;an000;bgb;AN000;
	JMP SHORT $$SR21
$$IF21:
	   cmp	   ax,0 			;Check for parse error		;an000;bgb;AN000;
;	$LEAVE	NE				;Stop if there was one		;an000;bgb;AN000;
	JNE $$EN21
	   call    Interpret_Parse		;Go find what we parsed 	;an000;bgb;AN000;
;	$ENDLOOP				;Parse error, see what it was	;an000;bgb;AN000;
	JMP SHORT $$DO21
$$EN21:

	   dec	  si			;point to last byte of invalid parm
public decsi
decsi:	   cmp	   byte ptr [si],' '	;are we pointing to a space?		;an046;bgb
;	   $IF	   E,OR 		;if so, we dont want to do that
	   JE $$LL26
	   cmp	   byte ptr [si],0dh	;are we pointing to CR? 		;an046;bgb
;	   $IF	   E			;if so, we dont want to do that
	   JNE $$IF26
$$LL26:
	       dec   si 		;find the last byte of parm
	       jmp   decsi
;	   $ENDIF
$$IF26:
	   mov	   byte ptr [si+1],00	  ;zero terminate display string  ;an046;bgb
nextsi:
public nextsi
	   dec	   si			;look at previous char			;an046;bgb
	   cmp	   byte ptr [si],' '	;find parm separator			;an046;bgb
	   jnz	   nextsi		;loop until begin of parm found
	   mov	   movsi,si		;mov si into display parms		;an046;bgb
	   PARSE_MESSAGE			;Display parse error		;an000;bgb;AN000;
	   mov	   Fatal_Error,YES		;Indicate death!		;an000;bgb;AN000;
;	$ENDSRCH				;				;an000;bgb;AN000;
$$SR21:
	pop	ds				;				;an000;bgb;AN000;
	ret					;				;an000;bgb;AN000;
										;an000;bgb
Parse_Command_Line endp 			;				;an000;bgb;AN000;
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Interpret_Parse							;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;description: Get any switches entered, and dr					;an000;bgb
;										;an000;bgb
;										;an000;bgb
;Called Procedures: Message (macro)						;an000;bgb
;										;an000;bgb
;Change History: Created	5/1/87	       MT				;an000;bgb
;										;an000;bgb
;Input: DS:DrNum (FCB at 5Ch)							;an000;bgb
;										;an000;bgb
;Output: Noisy = ON/OFF 							;an000;bgb
;	 DoFix = ON/OFF 							;an000;bgb
;	 ALLDRV = Target drive, A=1						;an000;bgb
;	 VOLNAM = Target drive, A=1						;an000;bgb
;	 ORPHFCB = Target drive, A=1						;an000;bgb
;	 BADDRVm+1 = Target drive, A=0						;an000;bgb
;	 Arg_Buf = Target drive letter						;an000;bgb
;	 Fragment > 1 if filespec entered					;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	Noisy = OFF								;an000;bgb
;	DoFix = OFF								;an000;bgb
;	IF /V									;an000;bgb
;	   Noisy = ON								;an000;bgb
;	ENDIF									;an000;bgb
;	IF /F									;an000;bgb
;	   DoFix = ON								;an000;bgb
;	ENDIF									;an000;bgb
;	IF file spec entered							;an000;bgb
;	   Build filename							;an000;bgb
;	   Fragment = 1 							;an000;bgb
;	ENDIF									;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
Procedure Interpret_Parse			;				;an000;bgb;AN000;
										;an000;bgb
	push	ds				;Save segment			;an000;bgb;AN000;
	push	si				;Restore SI for parser		;an000;bgb;AN000;
	push	cx				;				;an000;bgb;AN000;
	push	di				;				;an000;bgb
	Set_Data_Segment			;				;an000;bgb
	cmp	byte ptr Buffer.dfType,Type_Drive ;Have drive letter?	;AN000; ;an000;bgb
;	$IF	E				;Yes, save info 		;an000;bgb;AN000;
	JNE $$IF29
	   and	   word ptr dfcontrol,filespec	;dont let another drive letter	;an000;bgb
	   mov	   al,byte ptr Buffer.Drnum_stroff ;Get drive entered	       ;;an000;bgbAN000;
	   mov	   AllDrv,al			;				;an000;bgb;AC000;
	   mov	   VolNam,al			;				;an000;bgb;AC000;
	   mov	   OrphFCB,al			;				;an000;bgb;AC000;
	   dec	   al				;Make it 0 based		;an000;bgb;AN000;
	   mov	   BadDrvm+1,al 		; "  "	  "  "			;an000;bgb;AN000;
	   add	   al,'A'			;Make it a drive letter 	;an000;bgb;AN000;
	   mov	   Arg_Buf,al			;Save it			;an000;bgb;AN000;
;	$ENDIF					;				;an000;bgb;AN000;
$$IF29:
	cmp	SwBuffer.Switch_Pointer,offset Sw_v			 ;AN020;;an000;bgbbgb
;	$IF	E				;				;an000;bgb;AN000;
	JNE $$IF31
	   mov	   Noisy,ON			;Set flag			;an000;bgb;AC000;
	   mov	   byte ptr sw_v,blank						;an000;bgb;an020;bgb
;	$ENDIF					;				;an000;bgb;AN000;
$$IF31:
	cmp	SwBuffer.Switch_Pointer,offset sw_f			 ;AN020;;an000;bgbbgb
;	$IF	E				;				;an000;bgb;AN000;
	JNE $$IF33
	   mov	   DoFix,ON			;Set flag			;an000;bgb;AC000;
	   mov	   byte ptr sw_f,blank					       ;;an000;bgban020;bgb
;	$ENDIF					;				;an000;bgb;AN000;
$$IF33:
;;;;;;; cmp	FileSpec_Buffer.FileSpec_Pointer,offset FileSpec_Control.Keyword;an000;bgb ;AN000;
	cmp	buffer.dftype, type_filespec					;an000;bgb
;	$IF	E				;				;an000;bgb;AN000;
	JNE $$IF35
	   mov	   word ptr dfcontrol,0 ;dont let another drive letter or filesp;an000;bgbec
	   mov	   si,Buffer.drnum_StrOff ;			  ;AN000;	;an000;bgb
	   lea	   di,Path_Name 		;Point to where to build path	;an000;bgb;AN000;
	   cld					;SI-DI dir is up		;an000;bgb;AN000;
;	   $DO					;Move string one char at a time ;an000;bgb;AN000;
$$DO36:
	      cmp     byte ptr [si],Asciiz_End	;Is it the end? 		;an000;bgb;AN000;
;	   $LEAVE  E				;You got it			;an000;bgb;AN000;
	   JE $$EN36
	      movsb				;Nope, move the character	;an000;bgb;AN000;
;	   $ENDDO				;And keep crusin		;an000;bgb;AN000;
	   JMP SHORT $$DO36
$$EN36:
	   inc	   fragment			;To be compat with old code	;an000;bgb;AN000;
;	$ENDIF					;				;an000;bgb;AN000;
$$IF35:
	pop	di				;Restore parse regs		;an000;bgb;AN000;
	pop	cx				;				;an000;bgb;AN000;
	pop	si				;				;an000;bgb;AN000;
	pop	ds				;				;an000;bgb;AN000;
	ret					;				;an000;bgb;AN000;
										;an000;bgb
										;an000;bgb
Interpret_Parse endp				;				;an000;bgb;AN000;
										;an000;bgb
										;an000;bgb
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Validate_Target_Drive						;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description: Control routine for validating the specified format target drive. ;an000;bgb
;	      If any of the called routines find an error, they will print	;an000;bgb
;	      message and terminate program, without returning to this routine	;an000;bgb
;										;an000;bgb
;Called Procedures: Check_Target_Drive						;an000;bgb
;		    Check_For_Network						;an000;bgb
;		    Check_Translate_Drive					;an000;bgb
;										;an000;bgb
;Change History: Created	5/1/87	       MT				;an000;bgb
;										;an000;bgb
;Input: Fatal_Error = NO							;an000;bgb
;										;an000;bgb
;Output: Fatal_Error = YES/NO							;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	CALL Check_Target_Drive 						;an000;bgb
;	IF !Fatal_Error 							;an000;bgb
;	   CALL Check_For_Network						;an000;bgb
;	   IF !Fatal_Error							;an000;bgb
;	      CALL Check_Translate_Drive					;an000;bgb
;	   ENDIF								;an000;bgb
;	ENDIF									;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
Procedure Validate_Target_Drive 		;				;an000;bgb;AN000;
    call    Check_For_Network		 ;See if Network drive letter	 ;an000;;an043;bgbbgb;AN000;
    cmp     Fatal_Error,YES		    ;Can we continue?		    ;an0;an043;bgb00;bgb;AN000;
;   $IF     NE				    ;Yep			    ;an0;an043;bgb00;bgb;AN000;
    JE $$IF40
	call	Check_Target_Drive		;See if valid drive letter	;an000;bgb;AN000;
	cmp	Fatal_Error,YES 		;Can we continue?		;an000;bgb;AN000;
;	$IF	NE				;Yep				;an000;bgb;AN000;
	JE $$IF41
	   call    Check_For_Network		;See if Network drive letter	;an000;bgb;AN000;
	   cmp	   Fatal_Error,YES		;Can we continue?		;an000;bgb;AN000;
;	   $IF	   NE				;Yep				;an000;bgb;AN000;
	   JE $$IF42
	      call    Check_Translate_Drive	;See if Subst, Assigned 	;an000;bgb;AN000;
;	   $ENDIF				;- Fatal_Error passed back	;an000;bgb;AN000;
$$IF42:
;	$ENDIF					;				;an000;bgb;AN000;
$$IF41:
;   $ENDIF									;an000;bgb
$$IF40:
	ret					;				;an000;bgb;AN000;
										;an000;bgb
Validate_Target_Drive endp			;				;an000;bgb;AN000;
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Check_Target_Drive						;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description: Check to see if valid DOS drive by checking if drive is		;an000;bgb
;	      removable. If error, the drive is invalid. Save default		;an000;bgb
;	      drive info. Also get target drive BPB information, and compute	;an000;bgb
;	      the start of the data area					;an000;bgb
;										;an000;bgb
;Called Procedures: Message (macro)						;an000;bgb
;										;an000;bgb
;Change History: Created	5/1/87	       MT				;an000;bgb
;										;an000;bgb
;Input: Fatal_Error = NO							;an000;bgb
;										;an000;bgb
;Output: BIOSFile = default drive letter					;an000;bgb
;	 DOSFile = default drive letter 					;an000;bgb
;	 CommandFile = default drive letter					;an000;bgb
;	 Fatal_Error = YES/NO							;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	Get default drive (INT 21h, AH = 19h)					;an000;bgb
;	Convert it to drive letter						;an000;bgb
;	Save into BIOSFile,DOSFile,CommandFile					;an000;bgb
;	See if drive removable (INT 21h, AX=4409h IOCtl)			;an000;bgb
;	IF error - drive invalid						;an000;bgb
;	   Display Invalid drive message					;an000;bgb
;	   Fatal_Error= YES							;an000;bgb
;	ENDIF									;an000;bgb
;	Get BPB of target drive (Generic IOCtl Get Device parameters)		;an000;bgb
;	Compute start of data area						;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
Procedure Check_Target_Drive			;				;an000;bgb;AN000;
    call    func60				;				;an000;bgb
    mov     al,save_drive							;an000;bgb
    cmp     al,0ffh			;save drive spec			;an000;bgb
;   $IF     E									;an000;bgb
    JNE $$IF46
	   Message BadDrv_Arg			;Print message			;an000;bgb;AC000;
	   mov	   Fatal_Error,Yes		;Indicate error 		;an000;bgb;AN000;
	   jmp	   Exit_Baddrv			;dont do rest of proc		;an000;bgb;an021;bgb;an099;
;   $ENDIF									;an000;bgb
$$IF46:
	DOS_Call Get_Default_Drive		;Find the current drive  19	;an000;bgb;AC000;
	mov	UserDev,al			;Save it			;an000;bgb;	;
	cmp	AllDrv,0			;Was drive entered?		;an000;bgb;AN002;
;	$IF	E				;No				;an000;bgb;AN002;
	JNE $$IF48
	   mov	   BadDrvm+1,al 		;Save 0 based number		;an000;bgb;AN002;
	   inc	   al				;Make 1 based			;an000;bgb;AN002;
	   mov	   byte ptr Buffer.Drnum_stroff,al			    ;	;an000;bgb  ;
	   mov	   AllDrv,al			;Use default drive for		;an000;bgb;AN002;
	   mov	   VolNam,al			;entries for drive fields	;an000;bgb;AN002;
	   mov	   OrphFCB,al			;				;an000;bgb;AN002;
	   add	   al,'A'-1			;Make it a drive letter 	;an000;bgb;AN002;
	   mov	   Arg_Buf,al			;Save it			;an000;bgb;AN002;
;	$ENDIF					;				;an000;bgb;AN002;
$$IF48:
	mov	bl,alldrv			;Get drive number (A=1)    ;AN00;an044;bgb;an000;bgb0;
	mov	al,09h				;See if drive is local		;an000;bgb;AC000;
	DOS_Call IOCtl				;-this will fail if bad drive	;an000;bgb;AC000;
;	$IF	C				;CY means invalid drive 	;an000;bgb;AC000;
	JNC $$IF50
	   Message BadDrv_Arg			;Print message			;an000;bgb;AC015;bgb
	   mov	   Fatal_Error,Yes		;Indicate error 		;an000;bgb;AN015;bgb
;	$ENDIF					;				;an000;bgb;AN000;
$$IF50:
	cmp	fatal_error,no							;an000;bgb
;	$IF	E								;an000;bgb
	JNE $$IF52
get_bpb:   mov	   al,GENERIC_IOCTL		   ;Get BPB information 	;an000;bgb   ;AN000;
	   mov	   ch,RawIO			   ; "  "   "  "		;an000;bgb   ;AN000;
	   mov	   cl,GET_DEVICE_PARAMETERS	   ;				;an000;bgb   ;AN000;
	   mov	   bl,AllDrv			   ; "  "   "  "		;an000;bgb   ;AN000;
	   lea	   dx,BPB_Buffer		   ; dx points to bpb area	;an000;bgb   ;AN000;
	   mov	   byte ptr bpb_buffer, 0ffh	   ;turn bit 0 on to get bpb inf;an000;bgbo of disk ;an008;bgb
	   DOS_Call IOCtl			   ; "  "   "  "		;an000;bgb   ;AN000;
	   mov	   bx,dx			   ;use bx as the pointer to bpb;an000;bgb   ;an015;bgb
;	   $IF	   C			   ;is ioct not supported or bad?	;an000;bgb   ;an015;bgb
	   JNC $$IF53
	      mov     al,BadDrvm+1		   ; drive number a=0		;an000;bgb   ;AN015;bgb
	      lea     bx,chkprmt_end		   ; transfer address es:bx	;an000;bgb   ;an015;bgb
	      ;warning! this label must be the last in the code segment 	;an000;bgb
	      mov     cx,1			   ; 1 sector - boot record	;an000;bgb   ;an015;bgb
	      mov     dx,0			   ; logical sector 0		;an000;bgb   ;an015;bgb
	      mov     Read_Write_Relative.Start_Sector_High,0 ; 		;an000;bgb   ;an015;bgb
	      call    read_once 						;an000;bgb   ;an015;bgb
;	      $IF     C 		   ;couldnt read the boot?		;an000;bgb   ;an015;bgb
	      JNC $$IF54
		  Message BadDrv_Arg		       ;Print message		;an000;bgb	 ;AC015;bgb
		  mov	  Fatal_Error,Yes	       ;Indicate error		;an000;bgb	 ;AN015;bgb
;	      $ELSE			;ioct not supported - is it vdisk	;an000;bgb   ;an015;bgb
	      JMP SHORT $$EN54
$$IF54:
;		  mov	di,bx							;an000;bgb;an022;bgb
;		  add	di,3		;es:di --> to vdisk area in boot rcd	;an000;bgb;an022;bgb
;		  lea	si,myvdisk	;ds:si --> proper vdisk string		;an000;bgb;an022;bgb
;		  mov	cx,5		; compare 5 bytes			;an000;bgb;an022;bgb
;		  repe	cmpsb		;compare both strings			;an000;bgb;an022;bgb
IF  IBMCOPYRIGHT
;		  $IF	NE							;an000;bgb;an022;bgb
;		      jmp     baddrv						;an000;bgb
;		  $ENDIF							;an000;bgb;an022;bgb
ELSE
;		  $IF	NE
			mov   di,bx
			add   di,3
			lea   si,myramdisk
			mov   cx,8
			repe  cmpsb

;			$IF   NE
			JE $$IF56
			jmp   baddrv
;			$ENDIF
$$IF56:
;		  $ENDIF
ENDIF
;	      $ENDIF								;an000;bgb;an022;bgb
$$EN54:
	      add     bx,4		   ;boot-record-offset - device-paramete;an000;bgbr offset ;an015;bgb
;	   $ENDIF								;an000;bgb   ;an015;bgb
$$IF53:
;	$ENDIF									;an000;bgb
$$IF52:
	   cmp	   fatal_error,no						;an000;bgb
;	   $IF	   E								;an000;bgb
	   JNE $$IF61
	      call    get_boot_info						;an053;bgb
	      call    calc_space						;an000;bgb
;	   $ENDIF								;an000;bgb
$$IF61:
	      cmp     bytes_per_sector,0					;an000;bgb;an033;bgb
;	      $IF     E 							;an000;bgb;an033;bgb
	      JNE $$IF63
baddrv: 	  mov  fatal_error,yes						;an000;bgb;an033;bgb
		  mov	  dx,offset dg:inval_media				;an000;bgb;an033;bgb
		  invoke  printf_crlf						;an000;bgb;an033;bgb
;	      $ENDIF								;an000;bgb;an033;bgb
$$IF63:
Exit_Baddrv:					;AN099;
	     ret				;And we're outa here            ;an000;bgb;AN000;
Check_Target_Drive endp 			;				;an000;bgb;AN000;
										;an000;bgb
										;an000;bgb

;****************************************************************************** ;an053;bgb;an000;bgb
; get_boot_info 								;an053;bgb
;										;an053;bgb
;										;an053;bgb;an000;bgb
;	Inputs	: none								;an053;bgb;an000;bgb
;										;an053;bgb;an000;bgb
;	Outputs :								;an053;bgb
;****************************************************************************** ;an053;bgb;an000;bgb
Procedure get_boot_info        ;						;an053;bgb;an000;bgb
	      mov     cx,[bx].BytePerSector	; usually 512			;an053;bgb;an000;bgb	  ;an015;bgb
	      cmp     cx,512 ;vdisk sizes					;an053;bgb
;	      $IF     NE,AND ;vdisk sizes					;an053;bgb
	      JE $$IF65
	      cmp     cx,256 ;vdisk sizes					;an053;bgb
;	      $IF     NE,AND ;vdisk sizes					;an053;bgb
	      JE $$IF65
	      cmp     cx,128 ;vdisk sizes					;an053;bgb
;	      $IF     NE     ;vdisk sizes					;an053;bgb
	      JE $$IF65
		  jmp	 baddrv 						;an053;bgb
;	      $ENDIF								;an053;bgb
$$IF65:
	      mov     bytes_per_sector,cx     ; 		 ;		;an053;bgb;an000;bgb	  ;an005;bgb
										;an053;bgb
	      xor     cx,cx			      ;Find # sectors used by FA;an053;bgb;an000;bgbT's   ;AN000;
	      mov     cl,[bx].NumberOfFats	; "  "	 "  "			;an053;bgb;an000;bgb	  ;an015;bgb
	      cmp     cx,2		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     NE,AND							;an053;bgb
	      JE $$IF67
	      cmp     cx,1		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     NE							;an053;bgb
	      JE $$IF67
		  jmp	  baddrv	    ;must be 2 fats			;an053;bgb    ;an032;bgb
;	      $ENDIF								;an053;bgb
$$IF67:
	      mov     fatcnt,cl 						;an053;bgb;an000;bgb	  ;an005;bgb
										;an053;bgb
										;an053;bgb
	      xor     ax,ax							;an053;bgb
	      mov     al,[bx].SectorsPerCluster   ;get total sectors		;an053;bgb	;an000;bgb;an015;bgb
	      cmp     ax,1		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     NE,AND							;an053;bgb
	      JE $$IF69
	      cmp     ax,2		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     NE,AND							;an053;bgb
	      JE $$IF69
	      cmp     ax,4		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     NE,AND							;an053;bgb
	      JE $$IF69
	      cmp     ax,8		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     NE,AND							;an053;bgb
	      JE $$IF69
	      cmp     ax,16		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     NE,AND							;an053;bgb
	      JE $$IF69
	      cmp     ax,32		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     NE,AND							;an053;bgb
	      JE $$IF69
	      cmp     ax,64		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     NE,AND							;an053;bgb
	      JE $$IF69
	      cmp     ax,128		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     NE							;an053;bgb
	      JE $$IF69
		  jmp	  baddrv	    ;this is not!			;an053;bgb    ;an032;bgb
;	      $ENDIF								;an053;bgb
$$IF69:
										;an053;bgb
	      mov     ax,[bx].SectorsPerFAT	; "  "	 "  "			;an053;bgb;an000;bgb	  ;an015;bgb
	      cmp     ax,0		;make sure it is ok			;an053;bgb;an032;bgb
	      jz      baddrv		;this is not!				;an053;bgb;an032;bgb
	      mul     cx			      ; "  "   "  "		;an053;bgb;an000;bgb	  ;AN000;
	      push    bx		      ;save bpb pointer 		;an053;bgb;an000;bgb	  ;an015;bgb
	      push    dx			      ;Save results		;an053;bgb;an000;bgb	  ;AN000;
	      push    ax			      ;     "  "		;an053;bgb;an000;bgb	  ;AN000;
										;an053;bgb
	      mov     ax,[bx].RootEntries	;Find number of sectors in root ;an053;bgb;an000;bgb	  ;an015;bgb
	      cmp     ax,2		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     B,OR		;this is not!				;an053;bgb;an032;bgb
	      JB $$LL71
	      cmp     ax,512		;make sure it is ok			;an053;bgb;an032;bgb
;	      $IF     A 		;this is not!				;an053;bgb;an032;bgb
	      JNA $$IF71
$$LL71:
		jmp	baddrv							;an053;bgb
;	      $ENDIF								;an053;bgb
$$IF71:
										;an053;bgb
	      mov     cl,Dir_Entries_Per_Sector       ; by dividing RootEntries ;an053;bgb;an000;bgb	  ;AN000;
	      cmp     cl,0							;an053;bgb;an000;bgb;an022;bgb
;	      $IF     NE							;an053;bgb;an000;bgb;an022;bgb
	      JE $$IF73
		  div	  cl				  ; by (512/32) 	;an053;bgb;an000;bgb;an022;bgb;AN000;
;	      $ENDIF								;an053;bgb;an000;bgb;an022;bgb
$$IF73:
	      pop     bx			      ;Get low sectors per FAT b;an053;bgb;an000;bgback   ;AN000;
	      pop     dx			      ;Get high part		;an053;bgb;an000;bgb	  ;AN000;
	      add     ax,bx			      ;Add to get FAT+Dir sector;an053;bgb;an000;bgbs	  ;AN000;
	      adc     dx,0			      ;High part		;an053;bgb;an000;bgb	  ;AN000;
	      mov     fat_dir_secs,ax		      ;save it			;an053;bgb;an000;bgb	  ;an006;bgb
	      inc     fat_dir_secs		      ; 1 for reserved sector	;an053;bgb;an000;bgb	  ;an006;bgb
	      pop     bx		      ;restore bpb pointer		;an053;bgb;an000;bgb	  ;an015;bgb
	      add     ax,[bx].ReservedSectors	;Add in Boot record sectors	;an053;bgb;an000;bgb	  ;an015;bgb
	      adc     dx,0			      ;to get start of data (DX:;an053;bgb;an000;bgbAX)   ;AN000;
	      mov     Data_Start_Low,ax 	      ;Save it			;an053;bgb;an000;bgb	  ;AN000;
	      mov     Data_Start_High,dx	      ; 			;an053;bgb;an000;bgb	  ;AN000;
	ret					 ;				;an053;bgb;an000;bgb
get_boot_info endp	       ;						;an053;bgb;an000;bgb







;****************************************************************************** ;an000;bgb
; Calc_Space  : Calculate the total space that is				;an000;bgb
;				  addressible on the the disk by DOS.		;an000;bgb
;										;an000;bgb
;	Inputs	: none								;an000;bgb
;										;an000;bgb
;	Outputs : Fdsksiz - Size in bytes of the disk				;an000;bgb
;****************************************************************************** ;an000;bgb
Procedure Calc_Space	       ;						;an000;bgb
; get the total number of clusters on the disk					;an000;bgb ;an006;bgb
p97:	xor	ax,ax				 ;clear ax			;an000;bgb
	mov	ah,36h				 ;Get disk free space		;an000;bgb
	mov	dl,alldrv		; 1 based drive number			;an000;bgb
	push	bx			;save bpb pointer			;an000;bgb;an015;bgb
	int	21h				 ;bx = total space avail	;an000;bgb
;multiply by sectors per cluster						;an000;bgb
gtsecs: mov	ax,dx				 ;get total clusters		;an000;bgb
	xor	cx,cx				 ;clear cx			;an000;bgb
	pop	bx			;restore bpb pointer			;an000;bgb;an015;bgb
	mov	cl,[bx].SectorsPerCluster   ;get total sectors			;an000;bgb;an015;bgb
	push	bx			;save bpb pointer			;an000;bgb;an015;bgb
	xor	bx,bx				 ;clear bx			;an000;bgb
	call	Multiply_32_Bits		 ;multiply			;an000;bgb
;multiply by bytes per sector							;an000;bgb
	mov	dx,bx			;save bx				;an000;bgb;an015;bgb
	pop	bx			;get bpb addr				;an000;bgb;an015;bgb
	mov	cx,[bx].BytePerSector	;get total bytes			;an000;bgb;an015;bgb
	mov	bx,dx			;restore bx				;an000;bgb;an015;bgb
	call	Multiply_32_Bits		 ; multiply			;an000;bgb
;result is bytes on disk							;an000;bgb
	mov	tot_bytes_lo,ax 	     ;save high word			;an000;bgb
	mov	tot_bytes_hi,bx 	   ;save low word			;an000;bgb
	ret					 ;				;an000;bgb
Calc_Space    endp	       ;						;an000;bgb


;*****************************************************************************	;an000;bgb
;Routine name: Check_For_Network						;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description: See if target drive isn't local, or if it is a shared drive. If   ;an000;bgb
;	      so, exit with error message. The IOCtl call is not checked for	;an000;bgb
;	      an error because it is called previously in another routine, and	;an000;bgb
;	      invalid drive is the only error it can generate. That condition	;an000;bgb
;	      would not get this far						;an000;bgb
;										;an000;bgb
;Called Procedures: Message (macro)						;an000;bgb
;										;an000;bgb
;Change History: Created	5/1/87	       MT				;an000;bgb
;										;an000;bgb
;Input:    Drive_Letter_Buffer.Drive_Number					;an000;bgb
;	   Fatal_Error = NO							;an000;bgb
;										;an000;bgb
;Output: Fatal_Error = YES/NO							;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;	See if drive is local (INT 21h, AX=4409 IOCtl)				;an000;bgb
;	IF not local								;an000;bgb
;	   Display network message						;an000;bgb
;	   Fatal_ERROR = YES							;an000;bgb
;	ELSE									;an000;bgb
;	   IF  8000h bit set on return						;an000;bgb
;	      Display assign message						;an000;bgb
;	      Fatal_Error = YES 						;an000;bgb
;	   ENDIF								;an000;bgb
;	ENDIF									;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
Procedure Check_For_Network			;				;an000;bgb;AN000;
						;				;an000;bgb
	mov	bl,alldrv			;Drive is 1=A, 2=B		;an000;bgb;	;
	mov	al,09h				;See if drive is local or remote;an000;bgb;AC000;
	DOS_CALL IOCtl				;We will not check for error	;an000;bgb;AC000;
	test	dx,Net_Check			;if (x & 1200H)(redir or shared);an000;bgb;	;
;	$IF	NZ				;Found a net drive		;an000;bgb;AC000;
	JZ $$IF75
	   Message No_Net_Arg			;Tell 'em                       ;an000;bgb;AC000;
	   mov	   Fatal_Error,Yes		;Indicate bad stuff		;an000;bgb;AN000;
;	$ELSE					;Local drive, now check assign	;an000;bgb;AN000;
	JMP SHORT $$EN75
$$IF75:
	   test    dx,Assign_Check		;8000h bit is bad news		;an000;bgb;	;
;	   $IF	   NZ				;Found it			;an000;bgb;AC000;
	   JZ $$IF77
	      Message SubstErr			;Tell error			;an000;bgb;AC000;
	      mov     Fatal_Error,Yes		;Indicate bad stuff		;an000;bgb;AN000;
;	   $ENDIF				;				;an000;bgb;AN000;
$$IF77:
;	$ENDIF					;				;an000;bgb;AN000;
$$EN75:
	ret					;				;an000;bgb;AN000;
										;an000;bgb
Check_For_Network endp				;				;an000;bgb;AN000;
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Check_Translate_Drive						;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description: Do a name translate call on the drive letter to see if it is	;an000;bgb
;	      assigned by SUBST or ASSIGN					;an000;bgb
;										;an000;bgb
;Called Procedures: Message (macro)						;an000;bgb
;										;an000;bgb
;Change History: Created	5/1/87	       MT				;an000;bgb
;										;an000;bgb
;Input: Drive_Letter_Buffer.Drive_Number					;an000;bgb
;	   Fatal_Error = NO							;an000;bgb
;										;an000;bgb
;Output: Fatal_Error = YES/NO							;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;	Put drive letter in ASCIIZ string "d:\",0				;an000;bgb
;	Do name translate call (INT 21) 					;an000;bgb
;	IF drive not same							;an000;bgb
;	   Display assigned message						;an000;bgb
;	   Fatal_Error = YES							;an000;bgb
;	ENDIF									;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
Procedure Check_Translate_Drive 		;				;an000;bgb;AN000;
	call	func60				;				;an000;bgb
	mov	bl,byte ptr [TranSrc]		;Get drive letter from path	;an000;bgb;	;
	cmp	bl,byte ptr [Chkprmt_End]	;Did drive letter change?	;an000;bgb;	;
;	$IF	NE				;If not the same, it be bad	;an000;bgb;AC000;
	JE $$IF80
	   Message SubstErr			;Tell user			;an000;bgb;AC000;
	   mov	   Fatal_Error,Yes		;Setup error flag		;an000;bgb;AN000;
;	$ENDIF					;				;an000;bgb;AN000;
$$IF80:
	ret					;				;an000;bgb;AN000;
Check_Translate_Drive endp			;				;an000;bgb;AN000;
										;an000;bgb
										;an000;bgb
Procedure func60				;				;an000;bgb;AN000;
;  PUSH    DS			   ;ICE 					;an000;bgb
;  push    bx			   ;ICE 					;an000;bgb
;  push    ax			   ;ICE 					;an000;bgb
;										;an000;bgb
;  mov	   bx,0140H		   ;ICE 					;an000;bgb
;  xor	   ax,ax		   ;ICE 					;an000;bgb
;  mov	   ds,ax		   ;ICE 					;an000;bgb
;  mov	   ax,word ptr ds:[bx]	   ;ICE 					;an000;bgb
;  mov	   word ptr ds:[bx],ax	   ;ICE 					;an000;bgb
;										;an000;bgb
;  pop	   ax			   ;ICE 					;an000;bgb
;  pop	   bx			   ;ICE 					;an000;bgb
;  POP	   DS			   ;ICE 					;an000;bgb
										;an000;bgb
	mov	byte ptr [transrc],'A'						;an000;bgb
	mov	bl,alldrv			;Get drive		    ;	;an000;bgb  ;
	dec	bl				;Make it 0 based		;an000;bgb;AN001;
	add	byte ptr [TranSrc],bl		;Make string "d:\"		;an000;bgb;	;
	lea	si,TranSrc			;Point to translate string	;an000;bgb;	;
	push	ds				;Set ES=DS (Data segment)	;an000;bgb;	;
	pop	es				;     "  "	"  "		;an000;bgb;	;
	lea	di,Chkprmt_End			;Point at output buffer 	;an000;bgb;	;
	DOS_Call xNameTrans			;Get real path			;an000;bgb;AC000;
	ret					;				;an000;bgb;AN000;
func60 endp			 ;				 ;AN000;	;an000;bgb
										;an000;bgb
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Hook_Interrupts							;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description: Change the interrupt handler for INT 13h to point to the		;an000;bgb
;	      ControlC_Handler routine						;an000;bgb
;										;an000;bgb
;Called Procedures: None							;an000;bgb
;										;an000;bgb
;Change History: Created	4/21/87 	MT				;an000;bgb
;										;an000;bgb
;Input: None									;an000;bgb
;										;an000;bgb
;Output: None									;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	Point at ControlC_Handler routine					;an000;bgb
;	Set interrupt handler (INT 21h, AX=2523h)				;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
procedure Hook_Interrupts			;				;an000;bgb;AN000;
						;				;an000;bgb
	mov	al,23h								;an000;bgb
	DOS_Call Get_Interrupt_Vector		;Get the INT 23h handler	;an000;bgb;AC000;
	mov	word ptr [CONTCH],bx		;				;an000;bgb
	mov	bx,es				;				;an000;bgb;AN000;
	mov	word ptr [CONTCH+2],bx		;				;an000;bgb
	mov	al,23h				;Specify CNTRL handler		;an000;bgb;	;
	lea	dx, INT_23			;Point at it			;an000;bgb;	;
	push	ds				;Save data seg			;an000;bgb;	;
	push	cs				;Point to code segment		;an000;bgb;	;
	pop	ds				;				;an000;bgb;	;
	DOS_Call Set_Interrupt_Vector		;Set the INT 23h handler	;an000;bgb;AC000;
	pop	ds				;Get Data degment back		;an000;bgb;	;
	mov	al,24h				;				;an000;bgb
	DOS_Call Get_Interrupt_Vector		;Get the INT 24h handler	;an000;bgb;AC000;
	mov	word ptr [HardCh],bx		;Save it			;an000;bgb
	mov	bx,es				;				;an000;bgb
	mov	word ptr [HardCh+2],bx		;				;an000;bgb
	mov	al,24h				;Specify handler		;an000;bgb ;	 ;
	lea	dx, INT_24			;Point at it			;an000;bgb;	;
	push	ds				;Save data seg			;an000;bgb;	;
	push	cs				;Point to code segment		;an000;bgb;	;
	pop	ds				;				;an000;bgb;	;
	DOS_Call Set_Interrupt_Vector		;Set the INT 23h handler	;an000;bgb;AC000;
	pop	ds				;Get Data degment back		;an000;bgb;	;
	ret					;				;an000;bgb;AN000;
										;an000;bgb
hook_Interrupts endp				;				;an000;bgb;AN000;
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Clear_Append_X							;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description: Determine if Append /XA is turned on thru INT 2Fh, and shut	;an000;bgb
;	      off for life of CHKDSK if it is.					;an000;bgb
;										;an000;bgb
;Called Procedures: None							;an000;bgb
;										;an000;bgb
;										;an000;bgb
;Change History: Created	5/13/87 	MT				;an000;bgb
;										;an000;bgb
;Input: None									;an000;bgb
;										;an000;bgb
;Output: APPEND = YES/NO							;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	Append = NO								;an000;bgb
;	See if APPEND /X is present (INT 2Fh, AX=0B706h)			;an000;bgb
;	IF present								;an000;bgb
;	   Turn append /X off (INT 2Fh, AX=B707h, BX = 0)			;an000;bgb
;	   Append = YES 							;an000;bgb
;	ENDIF									;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
Procedure Clear_Append_X			;				;an000;bgb ;AN000;
										;an000;bgb
	mov	Append,NO			;Init the Append /X flag	;an000;bgb;AN000;
	mov	ax,Append_X			;Is Append /X there?		;an000;bgb;AN000;
	int	Multiplex			; "  "	   "  " 		;an000;bgb;AN000;
	cmp	bx,Append_X_Set 		;Was it turned on?		;an000;bgb;AN000;
;	$IF	E				;Yep				;an000;bgb;AN000;
	JNE $$IF82
	   mov	   Append,YES			;Indicate that it was on	;an000;bgb;AN000;
	   mov	   ax,Set_Append_X		;Turn Append /X off		;an000;bgb;AN000;
	   mov	   bx,Append_Off		; "  "	  "  "			;an000;bgb;AN000;
	   int	   Multiplex			; "  "	  "  "			;an000;bgb;AN000;
;	$ENDIF					;				;an000;bgb;AN000;
$$IF82:
	ret					;				;an000;bgb;AN000;
										;an000;bgb
Clear_Append_X endp				;				;an000;bgb;AN000;
										;an000;bgb
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: CHKDSK_IFS							;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description:									;an000;bgb
;										;an000;bgb
;Called Procedures: Main_Routine						;an000;bgb
;		   EXEC_FS_CHKDSK						;an000;bgb
;		   Done 							;an000;bgb
;										;an000;bgb
;Change History: Created	5/8/87	       MT				;an000;bgb
;										;an000;bgb
;Input: FS_Not_FAT = Yes/No							;an000;bgb
;										;an000;bgb
;Output: None									;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	IF File system other than FAT						;an000;bgb
;	   Go call file system specific CHKDSK (CALL Exec_FS_CHKDSK)		;an000;bgb
;	ELSE									;an000;bgb
;	   Do FAT based CHKDSK (CALL Main_Routine)				;an000;bgb
;	ENDIF									;an000;bgb
;	Restore current drive (CALL Done)					;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
										;an000;bgb
Procedure CHKDSK_IFS				;				;an000;bgb;AN000;
										;an000;bgb
ifdef	fsexec									;an038;bgb
	cmp	FS_Not_Fat,YES			;Is the target FS a FAT?	;an038;bgb;AN000;
;	$IF	E				;No, so need to exec the	;an038;bgb;AN000;
	JNE $$IF84
	   call    EXEC_FS_CHKDSK		; file system specific prog.	;an038;bgb;AN000;
;	$ELSE					;It's a FAT                     ;an038;bgb;AN000;
	JMP SHORT $$EN84
$$IF84:
endif										;an038;bgb
	   call    Main_Routine 		;Use canned code!		;an038;bgb;AN000;
ifdef	fsexec									;an038;bgb
;	$ENDIF					;				;an038;bgb;AN000;
$$EN84:
endif										;an038;bgb
	call	Done				;Restore current drive		;an000;bgb;AN000;
	ret					;				;an000;bgb;AN000;
										;an000;bgb
CHKDSK_IFS endp 				;				;an000;bgb;AN000;
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Reset_Append_X							;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;description: If APPEND /XA was on originally, turn it back on			;an000;bgb
;										;an000;bgb
;Called Procedures: None							;an000;bgb
;										;an000;bgb
;										;an000;bgb
;Change History: Created	5/13/87 	MT				;an000;bgb
;										;an000;bgb
;Input: None									;an000;bgb
;										;an000;bgb
;Output: APPEND = YES/NO							;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	IF APPEND = YES 							;an000;bgb
;	   Turn append /X on (INT 2Fh, AX=B707h, BX = 1)			;an000;bgb
;	ENDIF									;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
Procedure Reset_Append_X			;				;an000;bgb;AN000;
										;an000;bgb
	cmp	Append,Yes			;Was Append /X on to start with?;an000;bgb;AN000;
;	$IF	E				;Yep				;an000;bgb;AN000;
	JNE $$IF87
	   mov	   ax,Set_Append_X		;Turn Append /X off		;an000;bgb;AN000;
	   mov	   bx,Append_On 		; "  "	  "  "			;an000;bgb;AN000;
	   int	   Multiplex			; "  "	  "  "			;an000;bgb;AN000;
;	$ENDIF					;				;an000;bgb;AN000;
$$IF87:
	ret					;				;an000;bgb;AN000;
										;an000;bgb
Reset_Append_X endp				;				;an000;bgb;AN000;
										;an000;bgb
;*****************************************************************************	;an000;bgb
;Routine name: Multiply_32_Bits 						;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;Description: A real sleazy 32 bit x 16 bit multiply routine. Works by adding	;an000;bgb
;	      the 32 bit number to itself for each power of 2 contained in the	;an000;bgb
;	      16 bit number. Whenever a bit that is set in the multiplier (CX)	;an000;bgb
;	      gets shifted to the bit 0 spot, it means that that amount has	;an000;bgb
;	      been multiplied so far, and it should be added into the total	;an000;bgb
;	      value. Take the example CX = 12 (1100). Using the associative	;an000;bgb
;	      rule, this is the same as CX = 8+4 (1000 + 0100). The		;an000;bgb
;	      multiply is done on this principle - whenever a bit that is set	;an000;bgb
;	      is shifted down to the bit 0 location, the value in BX:AX is	;an000;bgb
;	      added to the running total in DI:SI. The multiply is continued	;an000;bgb
;	      until CX = 0. The routine will exit with CY set if overflow	;an000;bgb
;	      occurs.								;an000;bgb
;										;an000;bgb
;										;an000;bgb
;Called Procedures: None							;an000;bgb
;										;an000;bgb
;Change History: Created	7/23/87 	MT				;an000;bgb
;										;an000;bgb
;Input: BX:AX = 32 bit number to be multiplied					;an000;bgb
;	CX = 16 bit number to be multiplied. (Must be even number)		;an000;bgb
;										;an000;bgb
;Output: BX:AX = output.							;an000;bgb
;	 CY set if overflow							;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	Point at ControlC_Handler routine					;an000;bgb
;	Set interrupt handler (INT 21h, AX=2523h)				;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
Public Multiply_32_Bits 							;an000;bgb
Multiply_32_Bits proc				;				;an000;bgb;AN000;
										;an000;bgb
	push	di				;				;an000;bgb;AN000;
	push	si				;				;an000;bgb;AN000;
	xor	di,di				;Init result to zero		;an000;bgb
	xor	si,si				;				;an000;bgb
	cmp	cx,0				;Multiply by 0? 		;an000;bgb;AN000;
;	$IF	NE				;Keep going if not		;an000;bgb;AN000;
	JE $$IF89
;	   $DO					;This works by adding the result;an000;bgb;AN000;
$$DO90:
	      test    cx,1			;Need to add in sum of this bit?;an000;bgb;AN000;
;	      $IF     NZ			;Yes				;an000;bgb;AN000;
	      JZ $$IF91
		 add	 si,ax			;Add in the total so far for	;an000;bgb;AN000;
		 adc	 di,bx			; this bit multiplier (CY oflow);an000;bgb;AN000;
;	      $ELSE				;Don't split multiplier         ;an000;bgb;AN000;
	      JMP SHORT $$EN91
$$IF91:
		 clc				;Force non exit 		;an000;bgb;AN000;
;	      $ENDIF				;				;an000;bgb;AN000;
$$EN91:
;	   $LEAVE  C				;Leave on overflow		;an000;bgb;AN000;
	   JC $$EN90
	      shr     cx,1			;See if need to multiply value	;an000;bgb;AN000;
	      cmp     cx,0			;by 2				;an000;bgb;AN000;
;	   $LEAVE  E				;Done if cx shifted down to zero;an000;bgb;AN000;
	   JE $$EN90
	      add     ax,ax			;Each time cx is shifted, add	;an000;bgb;AN000;
	      adc     bx,bx			;value to itself (Multiply * 2) ;an000;bgb;AN000;
;	   $ENDDO  C				;CY set on overflow		;an000;bgb;AN000;
	   JNC $$DO90
$$EN90:
;	   $IF	   NC				;If no overflow, add in DI:SI	;an000;bgb;AN000;
	   JC $$IF97
	      mov     ax,si			; which contains the original	;an000;bgb;AN000;
	      mov     bx,di			; value if odd, 0 if even. This ;an000;bgb;AN000;
	      clc				;Set no overflow flag		;an000;bgb;AN000;
;	   $ENDIF				;				;an000;bgb;AN000;
$$IF97:
;	$ELSE					;				;an000;bgb
	JMP SHORT $$EN89
$$IF89:
	   xor	   ax,ax			;				;an000;bgb
	   xor	   bx,bx			;				;an000;bgb
;	$ENDIF					;Multiply by 0			;an000;bgb;AN000;
$$EN89:
	pop	si				;				;an000;bgb;AN000;
	pop	di				;				;an000;bgb;AN000;
	ret					;				;an000;bgb;AN000;
										;an000;bgb
Multiply_32_Bits endp								;an000;bgb
	pathlabl chkinit							;an000;bgb
code	ends									;an000;bgb
	end									;an000;bgb
										;an000;bgb
