					;AN000;bgb
page	,132				;
TITLE	RECINIT.SAL - MS-DOS File/Disk Recovery Utility
;*****************************************************************************
;*****************************************************************************
; Include files
;*****************************************************************************
;
 .xlist
	include pathmac.inc
 INCLUDE RECSEG.INC			;AN000;bgb
	INCLUDE DOSSYM.INC		;AN000;BGB
INCLUDE SYSCALL.INC			;AN000;BGB
INCLUDE RECEQU.INC			;AN000;BGB
INCLUDE RECMACRO.INC			;AN000;BGB
INCLUDE RECPARSE.INC			;AN000;BGB
 .list

;
;*****************************************************************************
; External Data Declarations
;*****************************************************************************
data	segment public para 'Data'	 ;an000;bgb
	EXTRN	movsi:word  ;move si pointer here for display of invalid parm	;an031;bgb
	extrn	command_line_buffer:byte ;AN000;bgb
	extrn	ExitStatus:Byte 	;AN000;bgb
	Extrn	FATTbl:byte
	Extrn	SubstErr:Byte
	Extrn	NotNetM:Byte
	Extrn	User_Drive:Byte 	;AN000;BGB
	Extrn	Baddrv:Byte
	Extrn	Drive_Letter_Msg:Byte	;AN000;BGB
	Extrn	Parse_Error_Msg:Byte
	extrn	fname_buffer:byte	;AN000;BGB
	extrn	PSP_Segment:word	;AN000;bgb
	extrn	fatal_error:byte	;AN000;bgb
	extrn	found:byte		;AN000;bgb
	extrn	done:byte	       ;AN000;bgb
	extrn	bpb_buffer:byte        ;AN000;bgb
	extrn	data_start_low:word	;AN000;bgb
	extrn	data_start_high:word	 ;AN000;bgb
	extrn	driveletter:byte	      ;AN000;bgb
	extrn	drive:byte		;AN000;bgb
	extrn	transrc:byte		  ;AN000;bgb
	extrn	int_23_old_off:word	;AN000;bgb
	extrn	int_23_old_seg:word	;AN000;bgb
	extrn	int_24_old_off:word	;AN000;bgb
	extrn	int_24_old_seg:word	;AN000;bgb
	extrn	append:byte		 ;AN000;bgb
ifdef fsexec
	extrn	fat12_string:byte	;AN000;bgb
	extrn	fat16_string:byte	;AN000;bgb
	extrn	media_id_buffer:byte	;AN000;bgb
	extrn	fs_not_fat:byte 	;AN000;bgb				;an022;bgb
	extrn	FS_String_Buffer:Byte	;AN011;bgb				;an022;bgb
	extrn	FS_String_end:Byte   ;AN011;bgb 				;an022;bgb
endif
data	ends ;an000;bgb


code	segment public para 'CODE'	 ;an000;bgb
	pathlabl recinit
;*****************************************************************************
; recinit procedures
;*****************************************************************************
public	Main_Init, Init_Io, Preload_Messages, Parse_recover
public	Parse_good, Parse_err, Validate_Target_Drive
public	 Check_Target_Drive, Check_For_Network, Check_Translate_Drive
public	 Hook_interrupts, Clear_Append_X, RECOVER_IFS, Reset_Append_X
public	exitpgm 								;an026;bgb
;*****************************************************************************
; External Routine Declarations
;*****************************************************************************
;	Extrn	EXEC_FS_Recover:Near						;an022;bgb
	 Extrn	 SysLoadMsg:Near
	Extrn	SysDispMsg:Near
	Extrn	Main_Routine:Near
	Extrn	INT_23:Near
	Extrn	INT_24:Near

;*****************************************************************************
;Routine name:	MAIN_INIT
;*****************************************************************************
;
;description: Main routine for recover program
;
;Called Procedures: get_psp
;		    Init_IO
;		    Validate_Target_Drive
;		    Hook_Interrupts
;		    RECOVER_IFS (goes to main-routine)
;
;Input: None
;
;Output: None
;
;Change History: Created	5/8/87	       MT
;
;Psuedocode
;----------
;	get info from psp
;	Parse input and load messages (CALL Init_Input_Output)
;	IF no error
;	   Check target drive letter (CALL Validate_Target_Drive)
;	   IF no error
;	      Set up Control Break (CALL Hook_Interrupts)
;	      IF no error
;		 CALL RECOVER_IFS (goes to main routine)
;	      ENDIF
;	   ENDIF
;	ENDIF
;	Exit program
;*****************************************************************************
procedure Main_Init			;;AN000;
	xor	bp,bp
	Set_Data_Segment		;Set DS,ES to Data segment	;AN000;bgb
	call	get_psp
	mov	Fatal_Error,No		;Init the error flag		;AN000;
	call	Init_Io 		;Setup messages and parse	;AN000;
	cmp	Fatal_Error,Yes 	;Error occur?			;AN000;
;	$IF	NE			;Nope, keep going		;AN000;
	JE $$IF1
	    call    Validate_Target_Drive ;Check drive letter		  ;AN000;
	    cmp     Fatal_Error,Yes	;Error occur?			;AN000;
;	    $IF     NE			;Nope, keep going		;AN000;
	    JE $$IF2
		call	Hook_Interrupts ;Set CNTRL -Break hook		;AN000;
		cmp	Fatal_Error,Yes ;Error occur?			;AN000;
;		$IF	NE		;Nope, keep going		;AN000;
		JE $$IF3
		    call    RECOVER_IFS ;RECOVER correct file system	 ;AN000;
;		$ENDIF			;				;AN000;
$$IF3:
;	    $ENDIF			;				;AN000;
$$IF2:
;	$ENDIF				;				;AN000;
$$IF1:
exitpgm: mov	 al,ExitStatus		 ;Get Errorlevel		 ;AN000;
	DOS_Call Exit			;Exit program			;AN000;
	int	20h			;If other exit fails		;AN000;

Main_Init endp				;				;AN000;

;*****************************************************************************
;Routine name: get_psp
;*****************************************************************************
;Description: get info from the psp area
;
;Called Procedures: get_drive
;
;Change History: Created	8/7/87	       bgb
;
;Input: none
;
;Output: psp_segment
;	 command_line_buffer
;
;Psuedocode
;----------
;	get addr of psp
;	move command line into data seg
;	get drive number of target
;	get addr of data seg
;	call get_drive
;	ret
;*****************************************************************************
Procedure get_psp			;;AN000;
	DOS_Call GetCurrentPSP		;Get PSP segment address	:AN000;bgb
	mov	PSP_Segment,bx		;Save it for later		;AN000;bgb
; get command line from psp							;AN000;bgb
	mov	cx,PSP_Segment		;point ds to data seg			;AN000;bgb
	mov	ds,cx			;  "   "   "   "    "                   ;AN000;bgb
	assume	ds:NOTHING,es:dg	;  "   "   "   "    "                   ;AN000;bgb
	mov	si,Command_Line_Parms	;ds:si --> old area in psp		;AN000;bgb
	LEA	di,command_line_buffer ; es:di -> new area in data
	mov	cx,128			; do for 128 bytes
	rep	movsb			; mov 1 byte until cx=0
; get the drive number of the target from the psp (0=default, a=1, b=2, c=3) ;AN000;bgb
	mov	bl,ds:[FCB1]	    ;Get target drive from FCB -74	    ;AN000;
	Set_Data_Segment	    ;Set DS,ES to Data segment		    ;AN000;bgb
	call	get_drive
	ret
get_psp   endp				;				;AN000;


;*****************************************************************************
;Routine name: get_drive
;*****************************************************************************
;Description: get drive letter from reg bl
;
;Change History: Created	8/7/87	       bgb
;
;Input: bl = drive num (default=0)
;
;Output: driveletter
;	 drive_letter_msg
;	 user_drive
;
;Psuedocode
;----------
;	IF drive-num = default
;	   get default drive number (a=1)
;	   convert to letter
;	ELSE
;	   convert to letter
;	ENDIF
;	move letter into data areas
;	ret
;*****************************************************************************
Procedure get_drive			;;AN000;
; convert drive number to drive letter
	    cmp     bl,0  ;a=1 b=2 c=3	;Is it default drive? 0=default ;AN000;
;	    $IF     E			;Yes, turn it into drive letter ;AN000;
	    JNE $$IF7
; get default drive number
		DOS_Call Get_Default_Drive ;Get default drive num in al    ;AN000;
					;a=0, b=1, c=2
		mov	drive,al	;					;AN000;bgb
;	    $ELSE			;Not default, A=1		;AN000;
	    JMP SHORT $$EN7
$$IF7:
; bl already contains the correct drive number - save it
		dec	bl		;a=0 b=1 c=2
		mov	drive,bl	;					;AN000;bgb
		mov	al,bl
;	    $ENDIF			; 74+40=b4
$$EN7:
	    add     al,"A"		;convert it to letter		;AN000;
	    mov     driveletter,al	;set up prompt msg			;AN000;bgb
	    mov     Drive_Letter_Msg,al ;Save it in message		;AN000;
	    mov     User_Drive,al	;Put it into path strings	;     ;
	ret
get_drive endp				;				;AN000;

;*****************************************************************************
;Routine name: Init_Io
;*****************************************************************************
;description: Initialize messages, Parse command line if FAT file system
;
;Called Procedures: Preload_Messages
;		   Parse_Recover
;
;Change History: Created	5/10/87 	MT
;
;Input: PSP command line at 81h and length at 80h
;
;Output: FS_Not_FAT = YES/NO
;	 Drive_Letter_Msg set up for any future messages that need it
;
;Psuedocode
;----------
;	Load messages (CALL Preload_Messages)
;	IF no fatal error
;	   Get file system type (12-bit fat, 16-bit fat, big fat, ifs)
;	   IF old-type-diskette, or
;	      dos4.00 12-bit fat, or
;	      dos4.00 16-bit fat, then
;	      Go handle FAT based Recover syntax's (Call Parse_Recover)
;	   ELSE
;	      FS_Not_FAT = YES
;	   ENDIF
;	ENDIF
;	ret
;*****************************************************************************
Procedure Init_IO			;;AN000;
; load the error messages from the system					;an022;bgb
	call	Preload_Messages	;Load up message retriever	;AN000;
ifdef fsexec									;an022;bgb
	mov	FS_Not_FAT,No							;an022;bgb
	cmp	Fatal_Error,YES 	;Quit?				;AN000; ;an022;bgb
;	$IF	NE			;Nope, keep going		;AN000; ;an022;bgb
	JE $$IF10
; get file system type from ioctl						;an022;bgb
	    mov     al,generic_ioctl	 ;al=0d (get media id)			;AN000;;an030;bgb
	    xor     bx,bx		;use default drive		;AN009;b;an022;bgbgb
	    mov     ch,Rawio		;8 = disk io				;an030;bgb;an022;bgb
	    mov     cl,Get_Media_Id	;66h					;an030;bgb
	    lea     dx,Media_ID_Buffer ;Point at buffer 	       ;AN000;	;an022;bgb
	    DOS_Call IOCtl		;Do function call ah=44 	;AN000; ;an022;bgb
; is it DOS 3.3 or below?			;carry flag means old dos	;an022;bgb
;	    $IF     C,OR		;Old style diskette, OR 	;AN000; ;an022;bgb
	    JC $$LL11
; is it a new-12 bit fat?							;an022;bgb
	       lea     si,FAT12_String ;Check for FAT_12 string        ;AN000;	;an022;bgb
	       lea     di,Media_ID_Buffer.Media_ID_File_System ;	    ;AN0;an022;bgb00;
	       mov     cx,Len_FS_ID_String ;Length of compare		   ;AN00;an022;bgb0;
	       repe    cmpsb		   ;Find it?			   ;AN00;an022;bgb0;
;	    $IF     E,OR		;Nope, keep going		;AN000; ;an022;bgb
	    JE $$LL11
; is it a new 16-bit fat?							;an022;bgb
	       lea     si,FAT16_String ;Check for FAT_16 string        ;AN000;	;an022;bgb
	       lea     di,Media_ID_Buffer.Media_ID_File_System ;	    ;AN0;an022;bgb00;
	       mov     cx,Len_FS_ID_String ;Length of compare		   ;AN00;an022;bgb0;
	       repe    cmpsb		   ;Do compare			   ;AN00;an022;bgb0;
;	    $IF     E			; is it new 16-bit fat? 	;AN000; ;an022;bgb
	    JNE $$IF11
$$LL11:
endif										;an022;bgb
; file system is fat based, continue (old or new)				;an022;bgb
		call	Parse_Recover	;Yes, go sort out syntax		;an022;bgb
;										;an022;bgb
; non-fat based system								;an022;bgb
ifdef fsexec									;an022;bgb
;	    $ELSE			;We got FS other than FAT	;AN000; ;an022;bgb
	    JMP SHORT $$EN11
$$IF11:
		mov	FS_Not_FAT,Yes	;Indicate exec file system	;AN000; ;an022;bgb
		mov	cx,8							;an022;bgb;an011;bgb
		lea	si,Media_ID_Buffer.Media_ID_File_System ;get file system;an022;bgb ;an011;bgb
		lea	di,fs_string_buffer ;put it here			;an022;bgb;an011;bgb
		rep	movsb							;an022;bgb;an011;bgb
		lea	di,fs_string_buffer ;point to beginning again		;an022;bgb;an011;bgb
;		$DO	COMPLEX 	;search th string until eol found	;an022;bgb;an011;bgb
		JMP SHORT $$SD13
$$DO13:
		    inc     di		;next char				;an022;bgb;an011;bgb
;		$STRTDO 		;start loop here			;an022;bgb;an011;bgb
$$SD13:
		    cmp     byte ptr [di],' '	 ;end of string ?		;an022;bgb	   ;an011;bgb
;		$ENDDO	E		;end loop when eol found		;an022;bgb;an011;bgb
		JNE $$DO13
		lea	si,fs_string_end ;get end of string - rec.exe		;an022;bgb;an011;bgb
		mov	cx,8		; 8 more chars				;an022;bgb;an011;bgb
		rep	movsb		;move it in				;an022;bgb;an011;bgb
;	    $ENDIF			; fat based file system 	;AN000; ;an022;bgb
$$EN11:
;	$ENDIF				; no error from msg retreiver	   ;AN00;an022;bgb0;
$$IF10:
endif										;an022;bgb
	ret				;				;AN000;
Init_Io 	  endp			;				;AN000;

;*****************************************************************************
;Routine name: Preload_Messages
;*****************************************************************************
;Description: Preload messages using common message retriever routines.
;
;Called Procedures: SysLoadMsg
;
;Change History: Created	5/1/87	       MT
;
;Input: Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;	Preload All messages (Call SysLoadMsg)
;	IF error
;	   Display SysLoadMsg error message
;	   Fatal_Error = YES
;	ENDIF
;	ret
;*****************************************************************************
Procedure Preload_Messages		;;AN000;						 ;
	call	SysLoadMsg		;Preload the messages		;AN000;
;	$IF	C			;Error? 			;AN000;
	JNC $$IF18
	    call    SysDispMsg		;Display preload msg		;AN000;
	    mov     Fatal_Error, YES	;Indicate error exit		;AN000;
;	$ENDIF				;				;AN000;
$$IF18:
	ret				;				;AN000;

Preload_Messages endp			;				;AN000;

;*****************************************************************************
;Routine name: Parse_Command_Line
;*****************************************************************************
;Description: Parse the command line. Check for errors, and display error and
;		 exit program if found. Use parse error messages except in case
;		 of no parameters, which has its own message
;
;Called Procedures: Message (macro)
;		    SysParse
;		    parse_good
;		    parse_err
;
;Change History: Created	5/1/87	       MT
;
;Input: Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;	 PARSE-ADDR
;	 DRIVELETTER
;	 PARSE-ADDR
;
;Psuedocode
;----------
;    set up regs to call sysparse
;DO UNTIL error=yes or return(ax)=finish(-1)
;    call sysparse
;    IF ax=good return(0)
;	   call parse-good
;    ELSE
;	   call parse-err
;    ENDIF
;ENDLOOP
;ret
;
;A. normal proc ==  1- ax=good 0
;		    2- ax=done -1
;B. no parm	==  1- ax=error 2
;
;C. too many	==  1- ax=good 0
;		    2- ax=error 1
;D. syntax	==  1- ax=error 9
;*****************************************************************************
Procedure Parse_recover 		;					;AN000;bgb
	push	ds			; save ds				;AN000;bgb
; set up to call sysparse							;AN000;bgb
	set_data_segment		;ds,es point to data seg
	LEA	si,command_line_buffer ;ds:si -> cmd line
	LEA	di,parms_input_block   ;es:di--> parms input block	   ;AN000;bgb
	xor	cx,cx			;cx = 0 				;AN000;bgb
	xor	dx,dx			;dx = 0 				;AN000;bgb
	mov	done,no
; call sysparse until error or end of cmd line					;AN000;bgb
;	$DO				;AN000;bgb
$$DO20:
	    call    SysParse		;go parse				;AN000;bgb
	    cmp     ax,$p_rc_eol	; -1 end of command line?		   ;AN000;bgb
;	    $LEAVE  E			; yes - done				    ;AN000;bgb
	    JE $$EN20
	    cmp     ax,$p_no_error	; good return code ??? (0)		;AN000;bgb
;	    $IF     E			; yes					;AN000;bgb
	    JNE $$IF22
		call	parse_good	; go get it				;AN000;bgb
;	    $ELSE			; ax not= good				;AN000;bgb
	    JMP SHORT $$EN22
$$IF22:
		call	parse_err	; check for error			;AN000;bgb
;	    $ENDIF			; eol					;AN000;bgb
$$EN22:
	    cmp     Fatal_Error,YES	;Can we continue?			    ;AN000;bgb
;	    $LEAVE  E			    ;NO 				    ;AN000;bgb
	    JE $$EN20
;	$ENDDO				;					;AN000;bgb
	JMP SHORT $$DO20
$$EN20:
	pop	ds			;					;AN000;bgb
	ret				;					;AN000;bgb
					;					;AN000;bgb
Parse_recover endp			;					;AN000;bgb
					;					;AN000;bgb
					;AN000;bgb
;*****************************************************************************
;Routine name: parse_good
;*****************************************************************************
;
;Description: when the ax register returned by sysparse indicates and error,
;	      this procedure is called.  it then determines which error
;	      occurred, and calls parse_message to display the msg.
;
;Called Procedures: parse_message (macro)
;
;Change History: Created	7/23/87 	bgb
;
;Input:
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;
;	  found=yes
;	  IF data=drive
;	       save drive number and letter
;	  ELSE
;	       IF data=filespec
;		    save filespec
;	       ELSE
;		    call parse-msg
;	       ENDIF
;	  ENDIF
;*****************************************************************************
;
Procedure Parse_good			;				;AN000;bgb
	cmp	parse_type,$p_drive  ; 6 if data=drive ;AN000;bgb
;	$IF	E			; not eol, good syntax, drive entered ;AN000;bgb
	JNE $$IF27
	    mov     bl,byte ptr parse_addr ;AN000;bgb
	    dec     bl			;Make drive 0 based		;AN000;bgb
	    mov     drive,bl		;AN000;bgb
	    add     bl,'A'		;make it character		;AN000;bgb
	    mov     driveletter,bl	;save into drive letter 	;AN000;bgb
;	$ELSE				; no - filespec entered 	;AN000;bgb
	JMP SHORT $$EN27
$$IF27:
	    cmp     parse_type,$p_file_spec ; 5 if data = filespec ;AN000;bgb
;	    $IF     E			; was file spec entered       ;AN000;bgb
	    JNE $$IF29
;		    push    si		; save input offset reg 		;AN000;bgb
;		    push    ds		; save input seg reg			;AN000;bgb
;		    push    cx		; save count				;AN000;bgb
;		    push    es		; save other seg reg			;AN000;bgb
;		    mov     cx,ds	;es points to data			;AN000;bgb
;		    mov     es,cx	;es points to data			;AN000;bgb
;		    mov     si,word ptr parse_addr ;get offset to filespec   ;AN000;bgb
;		    mov     ds,word ptr parse_addr+2 ;get segment to filespec	;AN000;bgb
;		    mov     cx,128	; mov 128 bytes 			;AN000;bgb
;		    rep     movs es:fname_buffer,ds:[si] ;move it		    ;AN000;bgb
;		    pop     es		; save other seg reg			;AN000;bgb
;		    pop     cx		; save other seg reg			;AN000;bgb
;		    pop     ds		; save other seg reg			;AN000;bgb
;		    pop     si		; save other seg reg			;AN000;bgb
;	    $ELSE			; no, no drive or filespec    ;AN000;bgb
	    JMP SHORT $$EN29
$$IF29:
		mov	ax,$p_syntax	;tell user bad syntax	   ;AN000;bgb
		parse_message		;display msg		   ;AN000;bgb
		mov Fatal_Error,YES ;Indicate death!  ;AN000;bgb
;	    $ENDIF			; was drive entered ?		;AN000;bgb
$$EN29:
;	$ENDIF				;if data=drive		      ;AN000;bgb
$$EN27:
	ret				;					;aN000;bgb
					;AN000;bgb
parse_good endp 			;				;AN000;bgb

					;AN000;bgb
;*****************************************************************************
;Routine name: parse_err
;*****************************************************************************
;
;Description: when the ax register returned by sysparse indicates and error,
;	      this procedure is called.  it then determines which error
;	      occurred, and calls parse_message to display the msg.
;
;Called Procedures: parse_message (macro)
;
;Change History: Created	7/23/87 	bgb
;
;Input:
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;
;	  IF ax=done	   (end of cmd line?) -1
;	       IF found=no (eol, but no parameters listed)
;		    call parse-msg
;	       ENDIF
;	  ELSE		   (error other than eol)
;	       call parse-msg
;	  ENDIF
;*****************************************************************************
;
Procedure Parse_err			;					;AN000;bgb
	mov Fatal_Error,YES ;Indicate death!  ;AN000;bgb			;AN000;bgb
	cmp ax,$P_Op_Missing		; 2 = no parameters ?			;AN000;bgb
;	$IF E				;					;AN000;bgb
	JNE $$IF33
	    message baddrv		; yes (invalid drive or filename)	;AN000;bgb
;	$ELSE									;AN000;bgb
	JMP SHORT $$EN33
$$IF33:
	   mov	   byte ptr [si],00	;zero terminate display string	;an031;bgb
	   dec	   si			;look at previous char			;an031;bgb
nextsi:
public nextsi
	   dec	   si			;look at previous char			;an031;bgb
	   cmp	   byte ptr [si],' '	;find parm separator			;an031;bgb
	   jnz	   nextsi		;loop until begin of parm found
	   mov	   movsi,si		;mov si into display parms		;an031;bgb
	    parse_message		;no- display parse message ;AN000;bgb	;AN000;bgb
;	$ENDIF									;AN000;bgb
$$EN33:
	ret				;					;AN000;bgb
parse_err endp				;					;AN000;bgb


;*****************************************************************************
;Routine name: Validate_Target_Drive
;*****************************************************************************
;
;Description: Control routine for validating the specified format target drive.
;	      If any of the called routines find an error, they will print
;	      message and terminate program, without returning to this routine
;
;Called Procedures: Check_Target_Drive
;		    Check_For_Network
;		    Check_Translate_Drive
;
;Change History: Created	5/1/87	       MT
;
;Input: Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;
;	CALL Check_Target_Drive
;	IF !Fatal_Error
;	   CALL Check_For_Network
;	   IF !Fatal_Error
;	      CALL Check_Translate_Drive
;	   ENDIF
;	ENDIF
;	ret
;*****************************************************************************
;
Procedure Validate_Target_Drive 	;				;AN000;
	call	Check_For_Network	;See if Network drive letter	;AN000;
	cmp	Fatal_Error,YES 	;Can we continue?		;AN000;
;	$IF	NE			;Yep				;AN000;
	JE $$IF36
	    call    Check_Translate_Drive ;See if Subst, Assigned   ;AN000;
	    call    Check_Target_Drive	;See if valid drive letter	;AN000;
;	$ENDIF				;- Fatal_Error passed back	;AN000;
$$IF36:
	ret				;				;AN000;

Validate_Target_Drive endp		;				;AN000;

;*****************************************************************************
;Routine name: Check_Target_Drive
;*****************************************************************************
;
;Description: Check to see if valid DOS drive by checking if drive is
;	      removable. If error, the drive is invalid. Save default
;	      drive info. Also get target drive BPB information, and compute
;	      the start of the data area
;
;Called Procedures: Message (macro)
;
;Change History: Created	5/1/87	       MT
;
;Input: Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;	 User_Drive = default drive
;
;Psuedocode
;----------
;
;	Get default drive
;	See if drive LOCAL     (INT 21h, AX=4409h IOCtl)
;	IF error - drive invalid
;	   Display Invalid drive message
;	   Fatal_Error= YES
;	ENDIF
;	Get BPB of target drive (Generic IOCtl Get Device parameters)
;	Compute start of data area
;	ret
;*****************************************************************************
;
Procedure Check_Target_Drive		;				;AN000;
	mov	al,0Dh			;Get BPB information		;AN000;
	mov	cx,0860h		; "  "	 "  "			;AN000;
;;;;;;;;mov	bl,byte ptr parse_addr	; "  "	 "  " ;AN000;
	mov	bl,drive		;drive number	 ;A=0,B=1		;AN000;bgb
	inc	bl			;a=1					;AN000;bgb
	lea	dx,BPB_Buffer	 ; "  "   "  "			 ;AN000;
	DOS_Call IOCtl			; "  "	 "  "			;AN000;
	xor	cx,cx			;Find # sectors used by FAT's   ;AN000;
	mov	cl,BPB_Buffer.NumberOfFATs ; "  "   "  "		   ;AN000;
	mov	ax,BPB_Buffer.SectorsPerFAT ; "  "   "  "		    ;AN000;
	mul	cx			; "  "	 "  "			;AN000;
	push	dx			;Save results			;AN000;
	push	ax			;     "  "			;AN000;
	mov	ax,BPB_Buffer.RootEntries ;Find number of sectors in root ;AN000;
	mov	cl,Dir_Entries_Per_Sector ; by dividing RootEntries	  ;AN000;
	div	cl			; by (512/32)			;AN000;
	pop	bx			;Get low sectors per FAT back	;AN000;
	pop	dx			;Get high part			;AN000;
	add	ax,bx			;Add to get FAT+Dir sectors	;AN000;
	adc	dx,bp ;zero		;High part			;AN000;
	add	ax,ReservedSectors	;Add in Boot record sectors	;AN000;
	adc	dx,bp ;zero		;to get start of data (DX:AX)	;AN000;
	mov	Data_Start_Low,ax	;Save it			;AN000;
	mov	Data_Start_High,dx	;				;AN000;
	ret				;And we're outa here            ;AN000;
Check_Target_Drive endp 		;				;AN000;

;*****************************************************************************
;Routine name: Check_For_Network
;*****************************************************************************
;
;Description: See if target drive isn't local, or if it is a shared drive. If
;	      so, exit with error message. The IOCtl call is not checked for
;	      an error because it is called previously in another routine, and
;	      invalid drive is the only error it can generate. That condition
;	      would not get this far
;
;Called Procedures: Message (macro)
;
;Change History: Created	5/1/87	       MT
;
;Input: Drive
;	   Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;	See if drive is local (INT 21h, AX=4409 IOCtl)
;	IF not local
;	   Display network message
;	   Fatal_ERROR = YES
;	ELSE
;	   IF  8000h bit set on return
;	      Display assign message
;	      Fatal_Error = YES
;	   ENDIF
;	ENDIF
;	ret
;*****************************************************************************
;
Procedure Check_For_Network		;				;AN000;
; is device local?  int 21, ah=44, al=9
	mov	bl,drive		;drive number	 ;A=0,B=1		;AN000;bgb
	inc	bl			;drive number	 ;A=1,B=2 for IOCtl call;AN000;bgb
	mov	al,09h			;See if drive is local			;AC000;bgb
	DOS_Call IOCtl			;-this will fail if bad drive	;AC000;
;	$IF	C			;CarrY means invalid drive	   ;AC000;
	JNC $$IF38
	    Message BadDrv		;Print message			;AC000;
	    mov     Fatal_Error,Yes	;Indicate error 		;AN000;
;	$ELSE
	JMP SHORT $$EN38
$$IF38:
	    test    dx,Net_Check	;if (x & 1200H)(redir or shared);     ;
;	    $IF     NZ			;Found a net drive		;AC000;
	    JZ $$IF40
		Message NotNetM 	;Tell 'em                       ;AC000;
		mov	Fatal_Error,Yes ;Indicate bad stuff		;AN000;
;	    $ELSE			;Local drive, now check assign	;AN000;
	    JMP SHORT $$EN40
$$IF40:
		test	dx,Assign_Check ;8000h bit is bad news		;     ;
;		$IF	NZ		;Found it			;AC000;
		JZ $$IF42
		    Message SubstErr	;Tell error			;AC000;
		    mov     Fatal_Error,Yes ;Indicate bad stuff 	    ;AN000;
;		$ENDIF			;				;AN000;
$$IF42:
;	    $ENDIF			;				;AN000;
$$EN40:
;	$ENDIF				;				;AN000;
$$EN38:
	ret				;				;AN000;

Check_For_Network endp			;				;AN000;

;*****************************************************************************
;Routine name: Check_Translate_Drive
;*****************************************************************************
;
;Description: Do a name translate call on the drive letter to see if it is
;	      assigned by SUBST or ASSIGN
;
;Called Procedures: Message (macro)
;
;Change History: Created	5/1/87	       MT
;
;Input: Drive_Letter_Msg has drive string
;	   Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;	Put drive letter in ASCIIZ string "d:\",0
;	Do name translate call (INT 21)
;	IF drive not same
;	   Display assigned message
;	   Fatal_Error = YES
;	ENDIF
;	ret
;*****************************************************************************
;
Procedure Check_Translate_Drive 	;				;AN000;
	mov	al,Drive_Letter_Msg	;Get target drive letter into	;AN000;
	mov	TranSrc,al		; "d:\",0 string		;AN000;
	lea	si,TranSrc	 ;Point to translate string	 ;AN000;
	push	ds			;Set ES=DS (Data segment)	;     ;
	pop	es			;     "  "	"  "		;     ;
	lea	di,FatTbl	 ;Point at output buffer	 ;     ;
	DOS_Call xNameTrans		;Get real path			;AC000;
;	$IF	NC								;an017;bgb
	JC $$IF46
	    mov     bl,byte ptr [TranSrc]   ;Get drive letter from path     ;	  ;
	    cmp     bl,byte ptr [Fattbl]    ;Did drive letter change?	    ;	  ;
;	    $IF     NE			    ;If not the same, it be bad     ;AC000;
	    JE $$IF47
		Message SubstErr	    ;Tell user			    ;AC000;
		mov	Fatal_Error,Yes     ;Setup error flag		    ;AN000;
;	    $ENDIF			    ;				    ;AN000;
$$IF47:
;	$ELSE									;an017;bgb
	JMP SHORT $$EN46
$$IF46:
	    mov     Fatal_Error,Yes	;Setup error flag		;AN000; ;an017;bgb
	    mov     bx,1							;an017;bgb
	    mov     cx,bp ;zero 						;an017;bgb
	    mov     dx,0100h							;an017;bgb
	    call    sysdispmsg							;an017;bgb
;	$ENDIF				;				;AN000; ;an017;bgb
$$EN46:
	ret				;				;AN000;

Check_Translate_Drive endp		;				;AN000;

;*****************************************************************************
;Routine name: Hook_Interrupts
;*****************************************************************************
;
;Description: Change the interrupt handler for INT 13h to point to the
;	      ControlC_Handler routine
;
;Called Procedures: None
;
;Change History: Created	4/21/87 	MT
;
;Input: None
;
;Output: None
;
;Psuedocode
;----------
;
;	Point at ControlC_Handler routine
;	Set interrupt handler (INT 21h, AX=2523h)
;	ret
;*****************************************************************************
;
 Procedure Hook_Interrupts		 ;				 ;AN000;
	mov	al,23h
	DOS_Call Get_Interrupt_Vector	;Get the INT 23h handler	;AC000;
	mov	word ptr INT_23_Old_Off,bx ;
	mov	bx,es			;				;AN000;
	mov	word ptr INT_23_Old_Seg,bx ;				   ;AN000;
	mov	al,23h			;Specify CNTRL handler		;     ;
	lea	dx, INT_23	 ;Point at it			 ;     ;
	push	ds			;Save data seg			;     ;
	push	cs			;Point to code segment		;     ;
	pop	ds			;				;     ;
	DOS_Call Set_Interrupt_Vector	;Set the INT 23h handler	;AC000;
	pop	ds			;Get Data degment back		;     ;
	mov	al,24h			;
	DOS_Call Get_Interrupt_Vector	;Get the INT 24h handler	;AC000;
	mov	word ptr INT_24_Old_Off,bx ;Save it
	mov	bx,es			;				;AN000;
	mov	word ptr INT_24_Old_Seg,bx ;
	mov	al,24h			;Specify handler		 ;     ;
	lea	dx, INT_24	 ;Point at it			 ;     ;
	push	ds			;Save data seg			;     ;
	push	cs			;Point to code segment		;     ;
	pop	ds			;				;     ;
	DOS_Call Set_Interrupt_Vector	;Set the INT 23h handler	;AC000;
	pop	ds			;Get Data degment back		;     ;
	ret				;				;AN000;

 Hook_Interrupts endp			 ;				 ;AN000;

;*****************************************************************************
;Routine name: Hook_CNTRL_C
;*****************************************************************************
;
;Description: Change the interrupt handler for INT 13h to point to the
;	      ControlC_Handler routine
;
;Called Procedures: None
;
;Change History: Created	4/21/87 	MT
;
;Input: None
;
;Output: None
;
;Psuedocode
;----------
;
;	Point at ControlC_Handler routine
;	Set interrupt handler (INT 21h, AX=2523h)
;	ret
;*****************************************************************************
;
;rocedure Hook_CNTRL_C				;				;AN000;
;	mov	al,23H				;Specify CNTRL handler		;     ;
;	mov	dx, offset ControlC_Handler	;Point at it			;     ;
;	push	ds				;Save data seg			;     ;
;	push	cs				;Point to code segment		;     ;
;	pop	ds				;				;     ;
;	DOS_Call Set_Interrupt_Vector		;Set the INT 23h handler	;AC000;
;	pop	ds				;Get Data degment back		;     ;
;	ret					;				;AN000;
;ook_CNTRL_C endp				;				;AN000;
;
;ontrolC_Handler:
;	set_data_segment
;;;;;;; Message msgInterrupt			;				;AC000;
;;;;;;;;mov	ExitStatus, ExitCtrlC
;	jmp	ExitPgm
;*****************************************************************************
;Routine name: Clear_Append_X
;*****************************************************************************
;
;Description: Determine if Append /XA is turned on thru INT 2Fh, and shut
;	      off for life of RECOVER if it is.
;
;Called Procedures: None
;
;
;Change History: Created	5/13/87 	MT
;
;Input: None
;
;Output: APPEND = YES/NO
;
;Psuedocode
;----------
;
;	Append = NO
;	See if APPEND /X is present (INT 2Fh, AX=0B706h)
;	IF present
;	   Turn append /X off (INT 2Fh, AX=B707h, BX = 0)
;	   Append = YES
;	ENDIF
;	ret
;*****************************************************************************
;
Procedure Clear_Append_X		;				 ;AN000;
	mov	Append,NO		;Init the Append /X flag	;AN000;
	mov	ax,Append_X		;Is Append /X there?		;AN000;
	int	Multiplex		; "  "	   "  " 		;AN000;
	cmp	bx,Append_X_Set 	;Was it turned on?		;AN000;
;	$IF	E			;Yep				;AN000;
	JNE $$IF51
	    mov     Append,YES		;Indicate that it was on	;AN000;
	    mov     ax,Set_Append_X	;Turn Append /X off		;AN000;
	    xor     bx,bx ;Append_Off	    ; "  "    "  "		    ;AN000;
	    int     Multiplex		; "  "	  "  "			;AN000;
;	$ENDIF				;				;AN000;
$$IF51:
	ret				;				;AN000;

Clear_Append_X endp			;				;AN000;


;*****************************************************************************
;Routine name: RECOVER_IFS
;*****************************************************************************
;
;description:
;
;Called Procedures: Main_Routine
;		   EXEC_FS_RECOVER
;
;Change History: Created	5/8/87	       MT
;
;Input: FS_Not_FAT = Yes/No
;
;Output: None
;
;Psuedocode
;----------
;
;	IF File system other than FAT
;	   Go call file system specific RECOVER (CALL EXEC_FS_RECOVER)
;	ELSE
;	   Do FAT based RECOVER (CALL Main_Routine)
;	ENDIF
;	ret
;*****************************************************************************
;
Procedure RECOVER_IFS			;				;AN000;
ifdef fsexec									;an022;bgb
;	cmp	FS_Not_Fat,YES		;Is the target FS a FAT?	;AN000; ;an022;bgb
;	$IF	E			;No, so need to exec the	;AN000; ;an022;bgb
;	    call    EXEC_FS_RECOVER	; file system specific prog.	;AN000; ;an022;bgb
;	$ELSE				;It's a FAT                     ;AN000; ;an022;bgb
endif										;an022;bgb
	    call    clear_append_x	;BGB
	    call    Main_Routine	;Use canned code!		;AN000;
	    call    reset_append_x	;BGB
ifdef fsexec									;an022;bgb
;	$ENDIF				;				;AN000; ;an022;bgb
endif										;an022;bgb
	ret				;				;AN000;

RECOVER_IFS endp			;				;AN000;

;*****************************************************************************
;Routine name: Reset_Append_X
;*****************************************************************************
;
;description: If APPEND /XA was on originally, turn it back on
;
;Called Procedures: None
;
;
;Change History: Created	5/13/87 	MT
;
;Input: None
;
;Output: APPEND = YES/NO
;
;Psuedocode
;----------
;
;	IF APPEND = YES
;	   Turn append /X on (INT 2Fh, AX=B707h, BX = 1)
;	ENDIF
;	ret
;*****************************************************************************
;
Procedure Reset_Append_X		;				;AN000;
	cmp	Append,Yes		;Was Append /X on to start with?;AN000;
;	$IF	E			;Yep				;AN000;
	JNE $$IF53
	    mov     ax,Set_Append_X	;Turn Append /X off		;AN000;
	    mov     bx,Append_On	; "  "	  "  "			;AN000;
	    int     Multiplex		; "  "	  "  "			;AN000;
;	$ENDIF				;				;AN000;
$$IF53:
	ret				;				;AN000;

Reset_Append_X endp			;				;AN000;

	pathlabl recinit
code	ends
	end main_init ;AC000;bgb

