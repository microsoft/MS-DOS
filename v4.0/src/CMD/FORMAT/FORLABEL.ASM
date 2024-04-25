
;
;*****************************************************************************
;*****************************************************************************
;
;UTILITY NAME: FORMAT.COM
;
;MODULE NAME: FORLABEL.SAL
;
;		Interpret_Parse
;			|
;*			|
;³ÚÄÄÄÄÄ¿ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿|ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;À´VolIDÃ´Get_New_LabelÃÄ´Get_11_CharactersÃÂ´Change_Blanks³
; ÀÄÄÄÄÄÙÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;					    ³ÚÄÄÄÄÄÄÄÄÄÄÄ¿
;					    Ã´Skip_Blanks³
;					    ³ÀÄÄÄÄÄÄÄÄÄÄÄÙ
;					    ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;					    Ã´Check_DBCS_OverrunÃ´Check_DBCS_Character³
;					    ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;					    ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;					    À´Copy_FCB_String³
;					     ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;*****************************************************************************
;*****************************************************************************

data	segment public para 'DATA'
data	ends

code	segment public para 'CODE'
	assume	cs:code,ds:data
code	ends

.xlist
INCLUDE FORCHNG.INC
INCLUDE FORMACRO.INC
INCLUDE SYSCALL.INC
INCLUDE FOREQU.INC
INCLUDE FORSWTCH.INC
.list

;
;*****************************************************************************
; Equates
;*****************************************************************************
;

None	equ	0
StdIn	equ	0
StdOut	equ	1
StdErr	equ	2
Tab	equ	09h
Label_Buffer_length equ 80h
Create_Worked equ 0								;an024;


;
;*****************************************************************************
; External Data Declarations
;*****************************************************************************
;

	Extrn	SwitchMap:Word
	Extrn	Switch_String_Buffer:Byte
	Extrn	VolFCB:Byte
	Extrn	MsgBadCharacters:Byte
	Extrn	MsgLabelPrompt:Byte
	Extrn	MsgBadVolumeID:Byte
	Extrn	MsgCRLF:Byte
	Extrn	VolNam:Byte
	Extrn	Vol_Label_Count:Byte
	Extrn	VolDrive:Byte
	Extrn	Drive:Byte
	Extrn	Command_Line:Byte
	Extrn	Vol_Label_Buffer:Byte
	Extrn	DelDrive:Byte
	Extrn	DelFCB:Byte

code	segment public para 'CODE'

;************************************************************************************************
;Routine name Volid
;************************************************************************************************
;
;Description: Get volume id from command line /V:xxxxxxx if it is there, or
;	      else prompt user for volume label, parse the input. At this
;	      point setup the FCB and create the volume label. If failure,
;	      prompt user that they entered bad input, and try again.
;
;	      Note: This routine in 3.30 and prior used to check for /V
;		    switch. Volume labels are always required now, so /V
;		    is ignored, except to get volume label on command line.
;
;Called Procedures: Message (macro)
;		    Get_New_Label
;
;Change History: Created	5/1/87	       MT
;
;Input: Switch_V
;	Command_Line = YES/NO
;
;Output: None
;
;Psuedocode
;----------
;
;	Save registers
;	IF /V switch entered
;	   IF /v:xxxxx form not entered
;	      CALL Get_New_Label     ;Return string in Volume_Label
;	   ENDIF
;	ELSE
;	   CALL Get_New_Label	  ;Return string in Volume_Label
;	ENDIF
;	DO
;	   Create volume label
;	LEAVE Create Ok
;	   Display Bad Character message
;	   CALL Get_New_Label	;Return string in Volume_Label
;	ENDDO
;	Restore registers
;	ret
;*****************************************************************************

Procedure Volid 				;				;AN000;

	push	ds				;Save registers 		;AN000;
	push	si				; "  "	  "  "			;AN000;
	test	SwitchMap,Switch_V		;Was /V entered 		 ;AN000;
;	$IF	NZ				;Yes, see if label entered also ;AN000;
	JZ $$IF1
	   cmp	   Command_Line,YES		;Is there a string there?	;AN000;
;	   $IF	   NE				;Nope				;AN000;
	   JE $$IF2
	      call    Get_New_Label		;Go get volume label from user	;AN000;
;	   $ENDIF				;				;AN000;
$$IF2:
;	$ELSE					;Label not entered on cmd line	;AN000;
	JMP SHORT $$EN1
$$IF1:
	   call    Get_New_Label		;Go get label from user 	;AN000;
;	$ENDIF					;				;AN000;
$$EN1:
	mov	dl,drive			;Get drive number  A=0		;AN000;
	inc	dl				;Make it 1 based		;AN000;
	mov	DelDrive,dl			;Put into FCBs			;AN000;
	mov	VolDrive,dl			;				;AN000;
	mov	dx,offset DelFCB		;Point at FCB to delete label	;AN000;
	DOS_Call FCB_Delete			;Do the delete			;AN000;
	mov	dx,offset VolFCB		;Point at FCB for create	;AN000;
	DOS_CALL FCB_Create			;Go create it			;AN000;
	cmp	dl,Create_Worked		;See if the create worked	;an024;
;	$IF	E								;an024;
	JNE $$IF6
	   mov	   dx,offset VolFCB		;Point to the FCB created	;an022; dms;
	   DOS_Call FCB_Close			;Close the newly created FCB	;an022; dms;
;	$ENDIF									;an024;
$$IF6:

	pop	si				;Restore registers		;AN000;
	pop	ds				; "  "	   "  " 		;AN000;
	ret					;				;AN000;

Volid	endp					;				;AN000;

;*****************************************************************************
;Routine name: Get_New_Label
;*****************************************************************************
;
;Description: Prompts, inputs and verifies a volume label string. Continues
;	      to prompt until valid vol label is input
;
;Called Procedures: Message (macro)
;		    Build_String
;		    Get_11_Characters
;
;Change History: Created	3/18/87 	MT
;
;Input: None
;
;Output: Volume_Label holds
;
;Psuedocode
;----------
;
;	DO
;	   Display  new volume label prompt
;	   Input vol label
;	   IF No error (NC)
;	      Build Asciiz string with label, pointer DS:SI (CALL Build_String)
;	      Call Get_11_Characters (Error returned CY)
;	   ENDIF
;	LEAVE no error (NC)
;	   Display label error
;	ENDDO
;	ret
;*****************************************************************************

Procedure Get_New_Label 			;				;AN000;

;	$DO					;Loop until we get good one	;AN000;
$$DO8:
	   Message msgLabelPrompt		;Prompt to input Vol label	;AN000;
	   mov	ax,(Std_Con_Input_Flush shl 8) + 0 ;an000; dms;clean out input
	   int	21h				;an000; dms;
	   mov	dx,offset Vol_Label_Count	;an000; dms;beginning of buffer
	   mov	ah,Std_Con_String_Input 	;an000; dms;get input
	   int	21h				;an000; dms;
	   mov	ax,(Std_Con_Input_Flush shl 8) + 0 ;an000; dms; clean out input
	   int	21h				;an000; dms;
;	   $IF	   NC				;Read ok if NC, Bad sets CY	;AN000;
	   JC $$IF9
	      mov     si,offset Vol_Label_Buffer ;Get pointer to string 	 ;AN000;
	      call    Get_11_Characters 	;Handle DBCS stuff on input	;AN000;
;	   $ENDIF				;Ret CY if error		;AN000;
$$IF9:
;	$LEAVE	NC				;Done if NC			;AN000;
	JNC $$EN8
	   Message MsgCRLF			;next line			;an020; dms;
	   Message msgBadVolumeID		;Tell user error		;AN000;
;	$ENDDO					;Try again			;AN000;
	JMP SHORT $$DO8
$$EN8:
	Message MsgCRLF 			;an000; dms;next line
	ret					;				;AN000;

Get_New_Label endp				;				;AN000;

;*****************************************************************************
;Routine name: Get_11_Characters
;*****************************************************************************
;
;Description: Handle DBCS considerations, and build FCB to create vol label
;
;
;Called Procedures: Change_Blanks
;		    Skip_Blanks
;		    Check_DBCS_Overrun
;		    Copy_FCB_String
;
;Change History: Created	5/12/87 	MT
;
;Input: DS:SI = Asciiz string containing volume label input
;	Command_Line = YES/NO
;
;Output: Volname will contain an 8.3 volume label in FCB
;	 CY set on invalid label
;
;Psuedocode
;----------
;	Save regs used
;	Scan line replacing all DBCS blanks with SBCS  (CALL_Change_Blanks)
;	Skip over leading blanks (Call Skip_Blanks)
;	IF leading blanks ,AND
;	IF Command line
;	   Indicate invalid label (STC)
;	ELSE
;	   See if DBCS character at 11th byte (CALL Check_DBCS_Overrun)
;	   IF DBCS character at 11th byte
;	      Indicate invalid label (STC)
;	   ELSE
;	   Put string into FCB (CALL Copy_FCB_STRING)
;	   CLC
;	   ENDIF
;	ENDIF
;	Restore regs
;	ret
;*****************************************************************************

Procedure Get_11_Characters			;				;AN000;

	call	Change_Blanks			;Change DBCS blanks to SBCS	;AN000;
	call	Skip_Blanks			;Skip over leading blanks	;AN000;
;	$IF	C,AND				;Find leading blanks?		;AN000;
	JNC $$IF13
	cmp	Command_Line,YES		;Is this command line input?	;AN000;
;	$IF	E				;Yes				;AN000;
	JNE $$IF13
	   stc					;Indicate error (CY set)	;AN000;
;	$ELSE					;Leading blanks ok		;AN000;
	JMP SHORT $$EN13
$$IF13:
	   call    Check_DBCS_Overrun		;Is DBCS char at 11th byte?	;AN000;
;	   $IF	   C				;Yes				;AN000;
	   JNC $$IF15
	      stc				;Indicate invalid label 	;AN000;
;	   $ELSE				;No, good characters		;AN000;
	   JMP SHORT $$EN15
$$IF15:
	      call    Copy_FCB_String		;Put string into FCB		;AN000;
	      clc				;Indicate everything A-OK!	;AN000;
;	   $ENDIF				;				;AN000;
$$EN15:
;	$ENDIF					;				;AN000;
$$EN13:
	ret					;				;AN000;

Get_11_Characters endp				;				;AN000;

;*****************************************************************************
;Routine name: Change_Blanks
;*****************************************************************************
;
;Description: Replace all DBCS blanks with SBCS blanks, end string with
;	      Asciiz character if one doesn't already exist
;
;Called Procedures: Check_DBCS_Character
;
;Change History: Created	6/12/87 	MT
;
;Input: DS:SI = String containing volume label input
;
;Output: DS:SI = ASCIIZ string with all DBCS blanks replaced with 2 SBCS blanks
;
;
;Psuedocode
;----------
;
;	Save pointer to string
;	DO
;	LEAVE End of string (0)
;	   See if DBCS character (Check_DBCS_Character)
;	   IF CY (DBCS char found)
;	      IF first byte DBCS blank, AND
;	      IF second byte DBCS blank
;		 Convert to SBCS blanks
;	      ENDIF
;	      Point to next byte to compensate for DBCS character
;	   ENDIF
;	ENDDO
;	Tack on ASCIIZ character to string
;	Restore pointer to string
;
;*****************************************************************************

Procedure Change_Blanks 			;				;AN000;

	push	si				;Save pointer to string 	;AN000;
	push	cx				;				;AN000;
	push	ax				;				;AN000;
	xor	cx,cx				;				;AN000;
;	$DO					;Do while not CR		;AN000;
$$DO19:
	   cmp	   byte ptr [si],Asciiz_End	;Is it end of string?		;AN000;
;	$LEAVE	E,OR				;All done if so 		;AN000;
	JE $$EN19
	   cmp	   byte ptr [si],CR		;Is it CR?			;AN000;
;	$LEAVE	E,OR				;Exit if yes,end of label	;AN000;
	JE $$EN19
	   inc	   cx				;Count the character		;AN000;
	   cmp	   cx,Label_Buffer_Length	;Reached max chars? (80h)	;AN000;
;	$LEAVE	E				;Exit if so			;AN000;
	JE $$EN19
	   mov	   al,byte ptr [si]		;Get char to test for DBCS	;AN000;
	   call    Check_DBCS_Character 	;Test for dbcs lead byte	;AN000;
;	   $IF	   C				;We have a lead byte		;AN000;
	   JNC $$IF21
	      cmp     byte ptr [si],DBCS	;Is it a lead blank?		;AN000;
;	      $IF     E,AND			;If a dbcs char 		;AN000;
	      JNE $$IF22
	      cmp     byte ptr [si+1],DBCS_Blank ;Is it an Asian blank? 	;AN000;
;	      $IF     E 			;If an Asian blank		;AN000;
	      JNE $$IF22
		 mov	 byte ptr [si+1],Blank	;set up moves			;AN000;
		 mov	 byte ptr [si],Blank	;  to replace			;AN000;
;	      $ENDIF				;				;AN000;
$$IF22:
	      inc     si			;Point to dbcs char		;AN000;
;	   $ENDIF				;End lead byte test		;AN000;
$$IF21:
	   inc	   si				;Point to si+1			;AN000;
;	$ENDDO					;End do while			;AN000;
	JMP SHORT $$DO19
$$EN19:
	mov	byte ptr [si],Asciiz_End	;Mark end of string		;AN000;
	pop	ax				;Restore regs			;AN000;
	pop	cx				;				;AN000;
	pop	si				;				;AN000;
	ret					;return to caller		;AN000;

Change_Blanks endp				;				;AN000;

;*****************************************************************************
;Routine name: Skip_Blanks
;*****************************************************************************
;
;Description: Scan ASCIIZ string for leading blanks, return pointer to first
;	      non-blank character. Set CY if blanks found
;
;Called Procedures: None
;
;Change History: Created	6/12/87 	MT
;
;Input: DS:SI = ASCIIZ string containing volume label input
;
;Output: DS:SI = Input string starting at first non-blank character
;	 CY set if blanks found
;
;
;
;Psuedocode
;----------
;
;	Save original pointer, DI register
;	DO
;	  Look at character from string
;	LEAVE End of string (0)
;	  IF character is blank,OR
;	  IF character is tab
;	     INC pointer (SI)
;	     Indicate blank
;	  ELSE
;	     Indicate non-blank
;	  ENDIF
;	ENDDO non-blank
;	Get back pointer
;	Cmp string pointer to original pointer
;	IF NE
;	   STC
;	ELSE
;	   CLC
;	ENDIF
;	ret
;*****************************************************************************

Procedure Skip_Blanks				;				;AN000;

	push	di				;Preserve DI, just in case	;AN000;
	push	si				;Save pointer to string 	;AN000;
;	$DO					;Look at entire ASCIIZ string	;AN000;
$$DO26:
	   cmp	   byte ptr [si],ASCIIZ_End	;End of string? 		;AN000;
;	$LEAVE	E				;Yep, exit loop 		;AN000;
	JE $$EN26
	   cmp	   byte ptr [si],Blank		;Find a blank?			;AN000;
;	   $IF	   E,OR 			;Yes				;AN000;
	   JE $$LL28
	   cmp	   byte ptr [si],TAB		;Is it tab?			;AN000;
;	   $IF	   E				;Yes				;AN000;
	   JNE $$IF28
$$LL28:
	      inc     si			;Bump pointer to next character ;AN000;
	      clc				;Indicate found blank		;AN000;
;	   $ELSE				;Not blank or tab		;AN000;
	   JMP SHORT $$EN28
$$IF28:
	      stc				;Force exit			;AN000;
;	   $ENDIF				;				;AN000;
$$EN28:
;	$ENDDO	C				;Go look at next character	;AN000;
	JNC $$DO26
$$EN26:
	pop	di				;Get back original pointer	;AN000;
	cmp	di,si				;Are they the same?		;AN000;
;	$IF	NE				;If not equal blanks were found ;AN000;
	JE $$IF32
	   stc					;Set CY 			;AN000;
;	$ELSE					;No leading blanks found	;AN000;
	JMP SHORT $$EN32
$$IF32:
	   clc					;Clear CY			;AN000;
;	$ENDIF					;				;AN000;
$$EN32:
	pop	di				;Restore DI			;AN000;
	ret					;				;AN000;

Skip_Blanks endp				;				;AN000;


;*****************************************************************************
;Routine name: Copy_FCB_String
;*****************************************************************************
;
;Description: Build an 11 character string in the FCB from ASCIIZ string
;	      If nothing entered, than terminated with 0. Also add drive
;	      number in FCB
;
;Called Procedures: None
;
;Change History: Created	6/12/87 	MT
;
;Input: DS:SI = String containing volume label input
;
;Output: VOLNAM is filled in with Volume label string
;
;
;
;Psuedocode
;----------
;
;	Save regs
;	Init VolNam to blanks
;	DO
;	LEAVE if character is end of ASCIIZ string
;	   Mov character to FCB
;	   Inc counter
;	ENDDO all 11 chars done
;	Restore regs
;*****************************************************************************

Procedure Copy_FCB_String			;				;AN000;

	push	di				;				;AN000;
	push	cx				;				;AN000;
	push	si				;Save pointer to string 	;AN000;
	cld					;Set string direction to up	;AN000;
	mov	di,offset Volnam		;Init FCB field to blanks	;AN000;
	mov	al,Blank			; "  "	  "  "			;AN000;
	mov	cx,Label_Length 		; "  "	  "  "			;AN000;
	rep	stosb				; "  "	  "  "			;AN000;
	pop	si				;Get back pointer to string	;AN000;
	mov	di,offset VolNam		;Point at FCB field		;AN000;
	xor	cx,cx				;Init counter			;AN000;
;	$DO					;Copy characters over		;AN000;
$$DO35:
	   cmp	   byte ptr [si],ASCIIZ_End	;End of String? 		;AN000;
;	$LEAVE	E				;Yes, don't copy - leave blanks ;AN000;
	JE $$EN35
	   movsb				;Nope, copy character		;AN000;
	   inc	   cx				;Bump up count			;AN000;
	   cmp	   cx,Label_Length		;Have we moved 11?		;AN000;
;	$ENDDO	E				;Quit if so			;AN000;
	JNE $$DO35
$$EN35:
	pop	cx				;				;AN000;
	pop	di				;				;AN000;
	ret					;				;AN000;

Copy_FCB_String endp				;				;AN000;


;*****************************************************************************
;Routine name: Check_DBCS_Overrun
;*****************************************************************************
;
;Description: Check 11th byte, if the string is that long, to see
;	      if it is a DBCS character that is split down the middle. Must
;	      scan entire string to properly find DBCS characters, due to
;	      the fact a second byte of a DBCS character can fall into
;	      the range of the first byte environment vector, and thus look
;	      like a DBCS char when it really isn't
;
;Called Procedures: Check_DBCS_Character
;
;Change History: Created	6/12/87 	MT
;
;Input: DS:SI = String containing volume label input
;
;Output: CY set if DBCS character at bytes 11-12 in string
;
;*****************************************************************************

Procedure Check_DBCS_Overrun			;				;AN000;

	push	si				;Save pointer			;AN000;
	push	ax				;Save registers 		;AN000;
	push	cx				;  "  "   "  "			;AN000;
	mov	cx,si				;Get start of string		;AN000;
	add	cx,Label_Length 		;Find where to check for overrun;AN000;

Check_DBCS_OverRun_Cont:			;Scan string for DBCS chars	;AN000;

	   cmp	   byte ptr [si],ASCIIZ_End	;End of string? 		;AN000;
	   je	   DBCS_Good_Exit		;Yep				;AN000;

	   mov	   al,[si]			;Get character for routine	;AN000;
	   call    Check_DBCS_Character 	;See if DBCS leading character	;AN000;
;	   $if	   c				;DBCS if CY set 		;AN000;
	   JNC $$IF38
		   inc	si			;Next byte to handle DBCS	;AN000;
		   cmp	si,cx			;Is DBCS char spanning 11-12?	;AN000;
;		   $if	e			;truncate string
		   JNE $$IF39
			mov  byte ptr [si-1],20h;blank it out
			mov  byte ptr [si],20h	;blank it out
			jmp  DBCS_Good_Exit	;exit
;		   $endif			;
$$IF39:
;	   $else				;Not DBCS character		;an000; dms;
	   JMP SHORT $$EN38
$$IF38:
		   mov	al,[si] 		;Get character for routine	;an000; dms;
		   call Scan_For_Invalid_Char	;See if invalid vol ID char	;an000; dms;
		   jc	DBCS_Bad_Exit		;Bad char entered - exit	;an000; dms;
;	   $endif				;				;an000; dms;
$$EN38:

	   inc	   si				;Point to next character	;an000; dms;
	   jmp	   Check_DBCS_OverRun_Cont	;Continue looping		;an000; dms;

DBCS_Good_Exit:
										;an000; dms;
	clc					;Signal no error		;an000; dms;
	jmp	DBCS_Exit			;Exit routine			;an000; dms;

DBCS_Bad_Exit:									;an000; dms;

	stc					;Signal error			;an000; dms;

DBCS_Exit:									;an000; dms;

	pop	cx				;Restore registers		;AN000;
	pop	ax				; "  "	  "  "			;AN000;
	pop	si				;Restore string pointer 	;AN000;
	ret					;				;AN000;

Check_DBCS_Overrun endp 			;				;AN000;

;*****************************************************************************
;Routine name: Check_DBCS_Character
;*****************************************************************************
;
;Description: Check if specified byte is in ranges of DBCS vectors
;
;Called Procedures: None
;
;Change History: Created	6/12/87 	MT
;
;Input: AL = Character to check for DBCS lead character
;	DBCS_Vector = YES/NO
;
;Output: CY set if DBCS character
;	 DBCS_VECTOR = YES
;
;
;Psuedocode
;----------
;	Save registers
;	IF DBCS vector not found
;	   Get DBCS environmental vector (INT 21h
;	   Point at first set of vectors
;	ENDIF
;	SEARCH
;	LEAVE End of DBCS vectors
;	EXITIF Character > X1,AND  (X1,Y1) are environment vectors
;	EXITIF Character < Y1
;	  STC (DBCS character)
;	ORELSE
;	   Inc pointer to next set of vectors
;	ENDLOOP
;	   CLC (Not DBCS character)
;	ENDSRCH
;	Restore registers
;	ret
;*****************************************************************************

Procedure Check_DBCS_Character			;				;AN000;

	push	ds				;Save registers 		;AN000;
	push	si				; "  "	  "  "			;AN000;
	push	ax				; "  "	  "  "			;AN000;
	push	ds				; "  "	  "  "			;AN000;
	pop	es				;Establish addressability	;AN000;
	cmp	byte ptr es:DBCS_VECTOR,Yes	;Have we set this yet?		;AN000;
	push	ax				;Save input character		;AN000;
;	$IF	NE				;Nope				;AN000;
	JE $$IF43
	   mov	   al,0 			;Get DBCS environment vectors	;AN000;
	   DOS_Call Hongeul			;  "  "    "  " 		;AN000;
	   mov	   byte ptr es:DBCS_VECTOR,YES	;Indicate we've got vector      ;AN000;
	   mov	   es:DBCS_Vector_Off,si	;Save the vector		;AN000;
	   mov	   ax,ds			;				;AN000;
	   mov	   es:DBCS_Vector_Seg,ax	;				;AN000;
;	$ENDIF					; for next time in		;AN000;
$$IF43:
	pop	ax				;Restore input character	;AN000;
	mov	si,es:DBCS_Vector_Seg		;Get saved vector pointer	;AN000;
	mov	ds,si				;				;AN000;
	mov	si,es:DBCS_Vector_Off		;				;AN000;
;	$SEARCH 				;Check all the vectors		;AN000;
$$DO45:
	   cmp	   word ptr ds:[si],End_Of_Vector ;End of vector table? 	  ;AN000;
;	$LEAVE	E				;Yes, done			;AN000;
	JE $$EN45
	   cmp	   al,ds:[si]			;See if char is in vector	;AN000;
;	$EXITIF AE,AND				;If >= to lower, and		;AN000;
	JNAE $$IF45
	   cmp	   al,ds:[si+1] 		; =< than higher range		;AN000;
;	$EXITIF BE				; then DBCS character		;AN000;
	JNBE $$IF45
	   stc					;Set CY to indicate DBCS	;AN000;
;	$ORELSE 				;Not in range, check next	;AN000;
	JMP SHORT $$SR45
$$IF45:
	   add	   si,DBCS_Vector_Size		;Get next DBCS vector		;AN000;
;	$ENDLOOP				;We didn't find DBCS char       ;AN000;
	JMP SHORT $$DO45
$$EN45:
	   clc					;Clear CY for exit		;AN000;
;	$ENDSRCH				;				;AN000;
$$SR45:
	pop	ax				;Restore registers		;AN000;
	pop	si				; "  "	  "  "			;AN000;
	pop	ds				;Restore data segment		;AN000;
	ret					;				;AN000;

Check_DBCS_Character endp			;				;AN000;

;=========================================================================
; Scan_For_Invalid_Char : This routine scans the bad character table
;			  to determine if the referenced character is
;			  invalid.
;
;	Inputs	: Bad_Char_Table	- Table of bad characters
;		  Bad_Char_Table_Len	- Length of table
;		  AL			- Character to be searched for
;
;	Outputs : CY			- Bad character
;		  NC			- Character good
;=========================================================================

Procedure Scan_For_Invalid_Char 						;an000; dms;

	push	ax								;an000; dms;save ax
	push	cx								;an000; dms;save cx
	push	di								;an000; dms;save di

	lea	di,Bad_Char_Table						;an000; dms;point to bad character table
	mov	cx,Bad_Char_Table_Len						;an000; dms;get its length
	repnz	scasb								;an000; dms;scan the table
	cmp	cx,0000h							;an000; dms;did we find the character
;	$if	e								;an000; dms;no - a good character
	JNE $$IF51
		clc								;an000; dms;flag a good character
;	$else									;an000; dms;yes - a bad character
	JMP SHORT $$EN51
$$IF51:
		stc								;an000; dms;flag a bad character
;	$endif									;an000; dms;
$$EN51:

	pop	di								;an000; dms;restore di
	pop	cx								;an000; dms;restore cx
	pop	ax								;an000; dms;restore ax

	ret									;an000; dms;

Scan_For_Invalid_Char	endp							;an000; dms;


code	ends

data	segment public	para 'DATA'

Bad_Char_Table	label	byte			;an000; dms;table of invalid vol ID chars
	db	"*"
	db	"?"
	db	"["
	db	"]"
	db	":"
	db	"<"
	db	"|"
	db	">"
	db	"+"
	db	"="
	db	";"
	db	","
	db	"/"
	db	"\"
	db	'.'
	db	'"'
	db	" "
Bad_Char_Table_Len	equ	$-Bad_Char_Table;an000; dms;length of table

DBCS_Vector_Off dw 0				;
DBCS_Vector_Seg dw 0				;

data	ends
	end
