page	,132					;
;

;*****************************************************************************
;*****************************************************************************
;UTILITY NAME: FORMAT.COM
;
;MODULE NAME: FOREXEC.SAL
;
;
;
; ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
; ³EXEC_FS_FORMAT³
; ÀÄÂÄÄÄÄÄÄÄÄÄÄÄÄÙ
;   ³
;   ³ÚÄÄÄÄÄÄ¿
;   Ã´Shrink³
;   ³ÀÄÄÄÄÄÄÙ
;   ³ÚÄÄÄÄÄÄÄÄÄÄ¿
;   Ã´Setup_EXEC³
;   ³ÀÄÄÄÄÄÄÄÄÄÄÙ
;   ³ÚÄÄÄÄÄÄÄÄÄ¿	  ÚÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   Ã´EXEC_ArgVÃÄÄÄÄÄÄÄÄÄÄ´EXEC_Program³
;   ³ÀÄÄÄÄÄÄÄÄÄÙ	  ÀÄÄÄÄÄÄÄÄÄÄÄÄÙ
;   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   Ã´EXEC_Cur_DirectoryÃÄ´EXEC_Program³
;   ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÄÄÄÄÄÄÙ
;   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄ¿	  ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   À´EXEC_RoutineÃÄÄÄÄÄÄÄ´Build_Path_And_EXECÃÄ´EXEC_Program³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÙ	  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
; Change List: AN000 - New code DOS 3.3 spec additions
;	       AC000 - Changed code DOS 3.3 spec additions
;*****************************************************************************
;*****************************************************************************

title	DOS	3.30 FORMAT EXEC Module

IF1
	%OUT	ASSEMBLING: DOS 3.3 FORMAT EXEC LOADER
	%OUT
ENDIF

code	segment public para 'code'
	assume	cs:code
code	ends

;
;*****************************************************************************
; Include files
;*****************************************************************************
;

.xlist
INCLUDE FORCHNG.INC
INCLUDE FORMACRO.INC
INCLUDE SYSCALL.INC
INCLUDE FOREQU.INC
.list

;
;*****************************************************************************
; Public Data
;*****************************************************************************
;

	Public	Drive_Letter_Msg

;
;*****************************************************************************
; Public Routines
;*****************************************************************************
;


IF FSExec					;an018; dms;if /FS: desired

	Public	EXEC_FS_Format

ENDIF		;FSExec 			;an018; dms;end /FS: conditional

	Extrn	GetFSiz:near


;
;*****************************************************************************
; External Data Declarations
;*****************************************************************************
;

	extrn	ExitStatus:Byte
	extrn	Fatal_Error:Byte
	extrn	FS_String_Buffer:Byte
	extrn	msgEXECFailure:Byte
	extrn	PSP_Segment:Word
	extrn	drive:byte

;
;****************************************************************************
; Structures
;****************************************************************************
;


Exec_Block_Parms struc
Segment_Env dw	0
Offset_Command dw 0
Segment_Command dw 0
Offset_FCB1 dw	0
Segment_FCB1 dw 0
Offset_FCB2 dw	0
Segment_FCB2 dw 0

Exec_Block_Parms ends


;
;****************************************************************************
; Equates
;****************************************************************************
;


String_Done	equ	0
No_Error	equ	0
Error		equ	1
Stderr		equ	2
Stack_Space	equ	02eh							;an000; dms; IBM addition ROM paras

;
;****************************************************************************
; PSP Area
;****************************************************************************
;

PSP	segment public	para   'DUMMY'

org	2Ch
PSP_ENV_SEGMENT label word

FCB1	equ	5Ch

FCB2	equ	6Ch

org	80h
Command_Line label byte


PSP	ends

;
;****************************************************************************
; Data Area
;****************************************************************************
;

data	segment public para 'DATA'
	assume	ds:data,es:nothing

Exec_Block Exec_Block_Parms <>
EXEC_Path db	66 dup(0)

Drive_Letter_Msg db "A:",0			;Drive for exec fail message

SP_Save 	dw	?			;an000; dms;
SS_Save 	dw	?			;an000; dms;


;These next two should stay togather
; ---------------------------------------
						;
Path_String db	"PATH=" 			;				;AN000;
Len_Path_String equ $ - Path_String		;				;AN000;
						;
;----------------------------------------




;These should stay togather
; ---------------------------------------
						;
Search_FORMAT db "FORMAT"			;				;AC000;
Len_Search_FORMAT equ $ - Search_FORMAT 	;				;     ;
Search_Format_End equ $
						;				;     ;
;----------------------------------------


;These next two should stay togather
; ---------------------------------------





data	ends

code	segment public para 'code'
	assume	cs:code,ds:data

;
;****************************************************************************
; Main Routine
;****************************************************************************
;
;
;
;
;

IF FSExec					;an018; dms;if /FS: desired


Procedure Exec_FS_Format			;				;AC000;

	Set_Data_Segment			;
	call	Set_FCB1_Drive			;an000;dms;
	call	Shrink				;				;     ;
	mov	al,ExitStatus			;Setblock fail? 		;AC000;
	cmp	al,Error			; "  "	  "  "			;     ;
;	$IF	NE				;Nah, keep crusin!		;AN000;
	JE $$IF1
	   call    Setup_Exec			;				;     ;
	   call    Exec_Argv			;try exec from dir BASIC loaded ;     ;
	   mov	   al,ExitStatus		;				;AC000;
	   cmp	   al,Error			;				;     ;
;	   $IF	   E,AND			;				;AC000;
	   JNE $$IF2
	   call    Exec_Cur_Directory		;				;     ;
	   mov	   al,ExitStatus		;Try exec from cur directory	;AC000;
	   cmp	   al,Error			;				;     ;
;	   $IF	   E,AND			;				;AC000;
	   JNE $$IF2
	   call    EXEC_Routine 		;				;     ;
	   mov	   al,ExitStatus		;				;AC000;
	   cmp	   al,Error			;				;     ;
;	   $IF	   E				;				;AC000;
	   JNE $$IF2
  ;	      mov     bl,FCB1			;Get target drive from FCB
  ;	      mov     bl,Drive			;an000;dms;
	      push    ds			;an000;dms;save ds
	      push    si			;an000;dms;save si
	      mov     si,PSP_Segment		;an000;dms;get psp
	      mov     ds,si			;an000;dms;put psp in ds
	      assume  ds:PSP			;an000;dms;

	      mov     si,FCB1			;an000;dms;ptr to 1st. FCB
	      mov     bl,byte ptr ds:[si]	;an000;dms;get drive ID

	      pop     si			;an000;dms;restore si
	      pop     ds			;an000;dms;restore ds
	      Set_Data_Segment			;an000;dms;set segments

	      cmp     bl,0			;Is it default drive?		;AN000;
;	      $IF     E 			;Yes, turn it into drive letter ;AN000;
	      JNE $$IF3
		 push	 ax			;Save exit code 		;AN000;
		 DOS_Call Get_Default_Drive	;Get the default drive		;AN000;
		 add	 al,"A" 		;Turn into drive letter 	;AN000;
		 mov	 Drive_Letter_Msg,al	;Save it in message		;AN000;
		 pop	 ax			;Get return code back		;AN000;
;	      $ELSE				;Not default, A=1		;AN000;
	      JMP SHORT $$EN3
$$IF3:
		 add	 bl,"A"-1		;Convert to drive letter	;AN000;
		 mov	 Drive_Letter_Msg,bl	;				;AN000;
;	      $ENDIF				;AN000;
$$EN3:
	      Message msgEXECFailure		;				;AC000;
;	   $ELSE				;				;AN000;
	   JMP SHORT $$EN2
$$IF2:
	      DOS_Call WaitProcess		;				;AC000;
	      mov     ExitStatus,al		;				;     ;
;	   $ENDIF				;				;AN000;
$$EN2:
;	$ENDIF
$$IF1:
	mov	Fatal_Error,YES 		;Not really, indicates FS used	;AN000;
	ret					;				;     ;

Exec_FS_Format endp


;
;****************************************************************************
; Shrink
;****************************************************************************
;
;
;
;


Procedure Shrink				;				;AC000;

	mov	ax,cs				;an000; dms;get code segment
	mov	bx,ds				;an000; dms;get data segment
	sub	ax,bx				;an000; dms;data seg size
	mov	bx,ax				;an000; dms;save paras
	mov	ax,offset End_Program		;Get the offset of end of loader;     ;
	mov	cl,4				;Div by 16 to get para's        ;     ;
	shr	ax,cl				;				;     ;
	add	bx,ax				;an000; dms;add in code space
	add	bx,Stack_Space			;an000; dms;adjust for stack
	add	bx,11h				;an000; dms;give PSP space
	mov	ax,PSP_Segment
	mov	es,ax
	assume	es:nothing

	DOS_Call SetBlock			;				;AC000;
;	$IF	C				;If didn't work, quit           ;AC000;
	JNC $$IF9
		Message msgEXECFailure		     ;				     ;	   ;
		mov	ExitStatus,Error	     ;Bad stuff, time to quit	     ;AN000;
;	$ENDIF					;				;AN000;
$$IF9:
	ret					;				;     ;

Shrink	endp					;				;AN000;


;
;****************************************************************************
; Setup_Exec
;****************************************************************************
;
;
;
;

Procedure Setup_Exec				;				;AC000;

	Set_Data_Segment
	mov	ax,PSP_Segment			;Get segment of PSP		;AN000;
	mov	ds,ax				;  "  "    "  " 		;AN000;
						;     ;
	assume	ds:PSP
						;Setup dword pointer to command line to be passed

	mov	es:Exec_Block.Segment_Command,ax ;Segment for command line	 ;     ;
	mov	es:Exec_Block.Offset_Command,offset ds:Command_Line ;		      ;     ;

						;Setup dword pointer to first FCB to be passed

	mov	es:Exec_Block.Segment_FCB1,ax	;Segment for FCB1		;     ;
	mov	es:Exec_Block.Offset_FCB1,offset ds:FCB1 ;Offset of FCB at 05Ch       ;     ;

						;Setup dword pointer to second FCB to be passed 			    ;	  ;

	mov	es:Exec_Block.Segment_FCB2,ax	;Segment for FCB2		;     ;
	mov	es:Exec_Block.Offset_FCB2,offset ds:FCB2 ;Offset of FCB at 06Ch       ;     ;

						;Setup segment of Environment string, get from PSP			    ;	  ;

	mov	ax,ds:PSP_Env_Segment		;				;     ;
	mov	es:Exec_Block.Segment_Env,ax	;				;     ;
	Set_Data_Segment
	ret					;				;     ;


Setup_EXEC endp 				;				;AN000;

;
;****************************************************************************
; Exec_Argv
;****************************************************************************
;
; Read the environment to get the Argv(0) string, which contains the drive,
; path and filename that was loaded for FORMAT.COM. This will be used to find
; the xxxxxfmt.exe, assuming that it is in the same location or path as
; FORMAT.COM
;

Procedure EXEC_Argv				;				;AC000;

	Set_Data_Segment			;DS,ES = DATA
	cld					;				;     ;
	mov	ax,Exec_Block.Segment_Env	;Get the environment		;     ;
	mov	ds,ax				;Get addressability		;     ;

	assume	ds:nothing

	xor	si,si				;Start at beginning		;     ;
;	$DO					;Find argv(0) location		;AN000;
$$DO11:
;	   $DO					;Look for 0			;AN000;
$$DO12:
	      inc     si			;Get character			;     ;
	      cmp     byte ptr [si-1],0 	;Find string seperator? 	;     ;
;	   $ENDDO  E				;Yep				;AC000;
	   JNE $$DO12
	   inc	   si				;Get next char			;     ;
	   cmp	   byte ptr [si-1],0		;Are we at Argv(0)? (00?)	;     ;
;	$ENDDO	E				;Yes if we found double 0's     ;AC000;
	JNE $$DO11
	add	si,2				;Skip the word count		;     ;
	mov	di,si				;Save where string starts	;     ;
;	$DO					;Find length of Argv(0) string	;AN000;
$$DO15:
	   inc	   si				;Get char			;     ;
	   cmp	   byte ptr [si-1],0		;Is it the end? 		;     ;
;	$ENDDO	E				;End found if 0 found		;AC000;
	JNE $$DO15
	mov	cx,si				;Get number of bytes in string	;     ;
	sub	cx,di				;Put in cx reg for rep count	;     ;
	mov	si,di				;Point to path			;     ;
	mov	di,offset es:EXEC_Path		;Point to where to put it	;     ;
	rep	movsb				;Move the string		;     ;
	Set_Data_Segment			;				;AN000'
	dec	di				;Point at end of ArgV string	;     ;
	std					;Look backwards 		;AN000;
;	$DO					;Find 'FORMAT' in ARGV string	;AC000;
$$DO17:
	   mov	   cx,Len_Search_FORMAT 	;Get length to compare		;AC000;
	   mov	   si,offset Search_FORMAT_End-1 ;Look at comp string from end	 ;AC000;
	   repe    cmpsb			;See if same string		;AC000;
;	$ENDDO	E				;				;AC000;
	JNE $$DO17
	mov	si,offset FS_String_Buffer	;				;AN000;
	inc	di				;DI = replacement point-1	;AC000;
	cld					;Set direction flag back	;AN000;
	mov	cx,Len_FS_String_Buffer 	;Length of string to move	;AN000;
	rep	movsb				;Build part of the path 	;     ;
	call	EXEC_Program			;				;     ;
	ret					;				;     ;

EXEC_ArgV endp					;				;AN000;

;
;****************************************************************************
; EXEC_Program
;****************************************************************************
;
;
;
;

Procedure EXEC_Program				;				;AC000;

	Set_Data_Segment			;				;AN000;
	mov	ExitStatus,No_Error		;Setup to Exec the file 	;     ;
	mov	dx,offset Exec_Path		;				;     ;
	mov	bx,offset Exec_Block		;				;     ;
	mov	al,0				;				;     ;
	mov	word ptr SP_Save,sp		;an000; dms;save sp
	mov	word ptr SS_Save,ss		;an000; dms;save ss

	DOS_Call Exec				;				;AC000;

	cli					;an000; dms;turn off int's
	mov	sp,word ptr SP_Save		;an000; dms;retrieve sp
	mov	ss,word ptr SS_Save		;an000; dms;retrieve ss
	sti					;an000; dms;turn on int's


;	$IF	C				;CY means failure		;AC000;
	JNC $$IF19
	   mov	   ExitStatus,Error		;Set error code 		;     ;
;	$ENDIF					;				;AN000;
$$IF19:
	ret					;				;     ;

EXEC_Program endp				;				;AN000;


;
;****************************************************************************
; EXEC_Routine
;****************************************************************************
;
;
;
;

Procedure EXEC_Routine				;				;AN000;

	Set_Data_Segment			;				;AN000;
	mov	ExitStatus,Error		;Assume the worst		;     ;
	cld					;				;     ;
	push	ds				;				;     ;
	mov	ax,Exec_Block.Segment_Env	;Get the environment		;     ;
	mov	ds,ax				;Get addressability		;     ;
	assume	ds:nothing			;

	xor	si,si				;Start at beginning		;     ;
;	$SEARCH 				;				;AC000;
$$DO21:
	   cmp	   word ptr ds:[si],0		;End of the Evironment? 	;     ;
;	$EXITIF E				;Reached end, no more look	;AC000;
	JNE $$IF21
						;				;     ;
;	$ORELSE 				;Look for 'PATH=' in environment;AN000;
	JMP SHORT $$SR21
$$IF21:
	   mov	   di,offset Path_String	;  "  "    "  " 		;AC000;
	   mov	   cx,Len_Path_String		;  "  "    "  " 		;AC000;
	   repe    cmpsb			;  "  "    "  " 		;AC000;
;	$LEAVE	E				;Found if EQ			;AC000;
	JE $$EN21
;	$ENDLOOP				;Found PATH in environment	;AC000;
	JMP SHORT $$DO21
$$EN21:
	   call    Build_Path_And_Exec		;				;AN000;
;	$ENDSRCH				;				;     ;
$$SR21:
	pop	ds				;				;     ;
	ret					;				;     ;

EXEC_Routine endp

;
;****************************************************************************
; Build_Path_For_EXEC
;****************************************************************************
;
;
;
;

Procedure Build_Path_And_Exec			;				;AN000;

;	$DO					;				;AC000;
$$DO27:
	   cmp	   byte ptr ds:[si],0		;All path entries done? 	;     ;
;	   $IF	   NE				;				;AC000;
	   JE $$IF28
	      mov     di,offset EXEC_Path	;Point at where to put path	;     ;
	      mov     byte ptr es:[di],0	;End path just in case		;     ;
;	      $DO				;				;AC000;
$$DO29:
		 cmp	 byte ptr ds:[si],0	;End of Path?			;     ;
;	      $LEAVE  E 			;				;AC000;
	      JE $$EN29
		 cmp	 byte ptr ds:[si],';'	;End of entry?		       ;     ;
;		 $if	 e			;yes				;an000; dms;
		 JNE $$IF31
			 inc	si		;point to next character	;an000; dms;
			 jmp	EXIT_BPE_LOOP	;exit loop			;an000; dms;
;		 $endif 			;				;an000; dms;
$$IF31:
		 movsb				;Put char in path string	;     ;
;	      $ENDDO				;				;AN000;
	      JMP SHORT $$DO29
$$EN29:

EXIT_BPE_LOOP:					;				;an000; dms;
						;Path filled in,get backslash	;     ;
	      cmp     byte ptr ds:[si-1],0	;Any path there?		;     ;
;	      $IF     NE			;				;AC000;
	      JE $$IF34
						;Nope				;     ;
		 cmp	 byte ptr ds:[si-1],"\" ;Need a backslash?	     ;	   ;
;		 $IF	 NE			;				;AC000;
		 JE $$IF35
		    mov     byte ptr es:[di],"\" ;Yes, put one in	     ;	   ;
		    inc     di			;Line it up for next stuff	;     ;
		    inc     si			;				;     ;
;		 $ENDIF 			;				;AN000;
$$IF35:
		 push	 si			;Save place in path
		 push	 ds			;Save segment for environment	;AN000;
		 push	 es			;Xchange ds/es			;an000; dms;
		 pop	 ds			;				;an000; dms;
		 mov	 si,offset FS_String_Buffer ;Fill in filename		    ;	  ;
		 mov	 cx, Len_FS_String_Buffer ;				  ;	;
		 rep	 movsb			;				;     ;
		 call	 Exec_Program		;				;     ;
		 cmp	 ExitStatus,No_Error	;E if EXEC okay 		;AN000;
		 pop	 ds			;Get Env segment back		;     ;
		 pop	 si			;Get place in path back
;	      $ENDIF				;E if all paths done		;AN000;
$$IF34:
;	   $ENDIF				;E if all paths done		;AN000;
$$IF28:
;	$ENDDO	E				;Exit if E			;AN000;
	JNE $$DO27
	ret					;				;AN000;

Build_Path_And_EXEC Endp			;				;AN000;



;
;****************************************************************************
; Exec_Cur_Directory
;****************************************************************************
;
;
;
;

Procedure Exec_Cur_Directory			;				;AC000;

	Set_Data_Segment			;				;AN000;
	mov	si,offset FS_String_Buffer	;Setup path for current dir	;     ;
	mov	di,offset EXEC_Path		;				;     ;
	mov	cx,Len_FS_String_Buffer 	;				;     ;
	rep	movsb				;				;     ;
	call	EXEC_Program			;				;     ;
	ret					;				;     ;

EXEC_Cur_Directory endp 			;				;AN000;

;=========================================================================
; Set_FCB1_Drive	: This routine sets the 1st. byte of the FCB1,
;			  the drive identifier, to the default drive.
;=========================================================================

Procedure Set_FCB1_Drive			;an000;dms;set drive ID

	push	ds				;an000;dms;save ds
	push	si				;an000;dms;save si

	mov	si,PSP_Segment			;an000;dms;get segment of PSP
	mov	ds,si				;an000;dms;put it in ds
	assume	ds:PSP				;an000;dms;
	mov	si,FCB1 			;an000;dms;ptr to FCB1
	mov	byte ptr ds:[si],00h		;an000;dms;set drive ID to
						;      default drive
	pop	si				;an000;dms;restore si
	pop	ds				;an000;dms;restore ds
	Set_Data_Segment			;an000;dms;set up segmentation
	ret					;an000;dms;

Set_FCB1_Drive	endp				;an000;dms;

ENDIF		;FSExec 			;an018; dms;end /FS: conditional
						;	    assembly

public End_Program
End_Program label byte

code	ends
	end
