	PAGE				;AN000;
;  $SALUT (4,4,8,41)
;(deleted).XLIST
;(deleted)INCLUDE   STRUC.INC ;AN020;structured macro definitions for .IF,.ELSE etc.
;(deleted).LIST
;
; NOTE:   basesw must be set properly to allow the PARSER to access psdata.
;	   - basesw undefined	 means	 CS seg. override for psdata access.
;	   - basesw = 1 	 means	 DS seg. override for psdata access &
;					 DS must point to psdata.
;	   - basesw = 0 	 means	 ES seg. override for psdata access &
;					 ES must point to psdata.
;
;
IFNDEF basesw				;AN022;
   psdata_seg EQU   CS			;AN022;
ELSE					;AN022;
   IF  basesw				;AN022;IF "basesw  EQU  1" specified by caller THEN
       psdata_seg EQU	DS		;AN022;
   ELSE 				;AN022;
       psdata_seg EQU	ES		;AN022;ELSE only other choice is ES (basesw EQU 0)
   ENDIF				;AN022;
ENDIF					;AN022;

ifndef incsw				;AN000; (tm03) Someone doesn't want to include psdata
   incsw equ	 1			;AN000; include psdata.inc (tm03)
endif					;AN000; (tm03)
if incsw				;AN000; If incsw = 1 then (tm03)
   include psdata.inc			;AN000;    include psdata.inc (tm03)
endif					;AN000; endif		  (tm03)
   PAGE 				;AN000;
IF1					;AN000;
   %OUT INCLUDING COMP=COMMON DSN=PARSE.ASM...;AN000;
ENDIF					;AN000;
;***********************************************************************
; SysParse;
;
;  Function : Parser Entry
;
;  Input: DS:SI -> command line
;	  ES:DI -> parameter block
;	  psdata_seg -> psdata.inc
;	  CX = operand ordinal
;
;	  Note:  ES is the segment containing all the control blocks defined
;		 by the caller, except for the DOS COMMAND line parms, which
;		 is in DS.
;
;  Output: CY = 1   error of caller, means invalid parameter block or
;		    invalid value list. But this parser does NOT implement
;		    this feature. Therefore CY always zero.
;
;	   CY = 0   AX = return code
;		    BL = terminated delimiter code
;		    CX = new operand ordinal
;		    SI = set past scaned operand
;		    DX = selected result buffer
;
; Use:	$P_Skip_Delim, $P_Chk_EOL, $P_Chk_Delim, $P_Chk_DBCS
;	$P_Chk_Swtch, $P_Chk_Pos_Control, $P_Chk_Key_Control
;	$P_Chk_Sw_Control, $P_Fill_Result
;
; Vars: $P_Ordinal(RW), $P_RC(RW), $P_SI_Save(RW), $P_DX(R), $P_Terminator(R)
;	$P_SaveSI_Cmpx(W), $P_Flags(RW), $P_Found_SYNONYM(R), $P_Save_EOB(W)
;
;-------- Modification History -----------------------------------------
;
;  4/04/87 : Created by K. K,
;  4/28/87 : $P_Val_YH assemble error (tm01)
;	   : JMP SHORT assemble error (tm02)
;  5/14/87 : Someone doesn't want to include psdata (tm03)
;  6/12/87 : $P_Bridge is missing when TimeSw equ 0 and (CmpxSw equ 1 or
;	     DateSW equ 1)	      (tm04)
;  6/12/87 : $P_SorD_Quote is missing when QusSw equ 0 and CmpxSW equ 1
;				      (tm05) in PSDATA.INC
;  6/12/87 : $P_FileSp_Char and $P_FileSP_Len are missing
;	     when FileSW equ 0 and DrvSW equ 1 (tm06) in PSDATA.INC
;  6/18/87 : $VAL1 and $VAL3, $VAL2 and $VAL3 can be used in the same
;	     value-list block	      (tm07)
;  6/20/87 : Add $P_SW to check if there's an omiting parameter after
;	     switch (keyword) or not. If there is, backup si for next call
;	     (tm08)
;  6/24/87 : Complex Item checking does not work correctly when CmpSW equ 1
;	     and DateSW equ 0 and TimeSW equ 0 (tm09)
;  6/24/87 : New function flag $P_colon_is_not_necessary for switch
;	     /+15 and /+:15 are allowed for user (tm10)
;  6/29/87 : ECS call changes DS register but it causes the address problem
;	     in user's routines. $P_Chk_DBCS (tm11)
;  7/10/87 : Switch with no_match flag (0x0000H) does not work correctly
;					  (tm12)
;  7/10/87 : Invalid switch/keyword does not work correctly
;					  (tm13)
;  7/10/87 : Drive_only breaks 3 bytes after the result buffer
;					  (tm14)
;  7/12/87 : Too_Many_Operands sets DX=0 as the PARSE result
;					  (tm15)
;  7/24/87 : Negative lower bound on numeric ranges cause trouble

;  7/24/87 : Quoted strings being returned with quotes.

;  7/28/87 : Kerry S (;AN018;)
;	     Non optional value on switch (match flags<>0 and <>1) not flagged
;	     as an error when missing.	Solution: return error 2.  Modules
;	     affected: $P_Chk_SW_Control.

;  7/29/87 : Kerry S (;AN019;)
;	     Now allow the optional bit in match flags for switches.  This
;	     allows the switch to be encountered with a value or without a
;	     value and no error is returned.
;

;  8/28/87 : Ed K, Kerry S (;AN020;)
;  9/14/87   In PROC $P_Get_DecNum, when checking for field separators
;	     within a date response, instead of checking just for the one
;	     character defined by the COUNTRY DEPENDENT INFO, check for
;	     all three chars, "-", "/", and ".". Change $P_Chk_Switch to allow
;	     slashes in date strings when DateSw (assembler switch) is set.

;  9/1/87  : Kerry S (;AN021)
;	     In PROC $P_String_Comp, when comparing the switch or keyword on
;	     the command line with the string in the control block the
;	     comparing was stopping at a colon (switch) or equal (keyword)
;	     on the command line and assuming a match.	This allowed a shorter
;	     string on the command line than in the synonym list in the control
;	     block.  I put in a test for a null in the control block so the
;	     string in the control block must be the same length as the string
;	     preceeding the colon or equal on the command line.

;  8/28/87 : Kerry S (;AN022;)
;	     All references to data in PSDATA.INC had CS overrides.  This caused
;	     problems for people who included it themselves in a segment other
;	     than CS.  Added switch to allow including PSDATA.INC in any
;	     segment.

;  9/16/87 : Ed K (;AN023;) PTM1040
;	     in $p_set_cdi PROC, it assumes CS points to psdata. Change Push CS
;	     into PUSH PSDATA_SEG.  In $P_Get_DecNum PROC, fix AN020
;	     forced both TIME and DATE to use the delims, "-","/",".".
;	     Created FLag, in $P_time_Format PROC, to request the delim in
;	     BL be used if TIME is being parsed.

;  9/24/87 : Ed K
;	     Removed the include to STRUC.INC.	Replaced the STRUC macro
;	     invocations with their normally expanded code; made comments
;	     out of the STRUC macro invocation statements to maintain readability.

;  9/24/87 : Ed K (;AN024;) PTM1222
;	     When no CONTROL for a keyword found, tried to fill in RESULT
;	     pointed to by non-existant CONTROL.

; 10/15/87 : Ed K (;AN025;) PTM1672
;	     A quoted text string can be framed only by double quote.  Remove
;	     support to frame quoted text string with single quote.
;	     (apostrophe) $P_SorD_Quote is removed from PSDATA.INC.
;	     $P_SQuote EQU also removed from PSDATA.INC.  Any references to
;	     single quote in PROC prologues are left as is for history reasons.

;	     This fixes another bug, not mentioned in p1672, in that two
;	     quote chars within a quoted string is supposed to be reported as
;	     one quote character, but is reported as two quotes.  This changed
;	     two instructions in PROC $P_Quoted_Str.

;	     Also fixed are several JMP that caused a NOP, these changed to
;	     have the SHORT operator to avoid the unneeded NOP.

;	     The code and PSDATA.INC have been aligned for ease of reading.

; 10/26/87 : Ed K (;AN026;) PTM2041, DATE within SWITCH, BX reference to
;	     psdata buffer should have psdata_seg.

; 10/27/87 : Ed K (;AN027;) PTM2042 comma between keywords implies
;	     positional missing.

; 11/06/87 : Ed K (;AN028;) PTM 2315 Parser should not use line feed
;	     as a line delimiter, should use carriage return.
;	     Define switch: LFEOLSW, if on, accept LF as end of line char.

; 11/11/87 : Ed K (;AN029;) PTM 1651 GET RID OF WHITESPACE AROUND "=".

; 11/18/87 : Ed K (;AN030;) PTM 2551 If filename is just "", then
;	     endless loop since SI is returned still pointing to start
;	     of that parm.

; 11/19/87 : Ed K (;AN031;) PTM 2585 date & time getting bad values.
;	     Vector to returned string has CS instead of Psdata_Seg, but
;	     when tried to fix it on previous version, changed similar
;	     but wrong place.

; 12/09/87 : Bill L (;AN032;) PTM 2772 colon and period are now valid
;	     delimiters between hours, minutes, seconds for time. And period
;	     and comma are valid delimiters between seconds and 100th second.

; 12/14/87 : Bill L (;AN033;) PTM 2722 if illegal delimiter characters
;	     in a filespec, then flag an error.

; 12/22/87 : Bill L (;AN034;)	    All local data to parser is now
;	     indexed off of the psdata_seg equate instead of the DS register.
;	     Using this method, DS can point to the segment of PSP or to psdata
;  -->	     local parser data. Why were some references to local data changed
;	     to do this before, but not all ?????

; 02/02/88 : Ed K (;AC035;) INSPECT utility, suggests optimizations.

; 02/05/88 : Ed K (;AN036;) P3372-UPPERCASE TRANSLATION, PSDATA_SEG HOSED.
;
; 02/08/88 : Ed K (;AN037;) P3410-AVOID POP OF CS, CHECK BASESW FIRST.

; 02/19/88 : Ed K (;AN038;) p3524 above noon and "am" should be error

; 02/23/88 : Ed K (;AN039;) p3518 accept "comma" and "period" as decimal
;	     separator in TIME before hundredths field.
;
;***********************************************************************
IF FarSW				;AN000;(Check if need far return)
SysParse proc far			;AN000;
ELSE					;AN000;
SysParse proc near			;AN000;
ENDIF					;AN000;(of FarSW)
;	$SALUT	(4,9,17,41)
	mov	psdata_seg:$P_Flags,0	;AC034; Clear all internal flags
IF	TimeSw				;AN039; FOR TIME ONLY
	MOV    PSDATA_SEG:$P_ORIG_ORD,CX ;AN039; ORIGINAL ORDINAL FROM CX
	MOV    PSDATA_SEG:$P_ORIG_STACK,SP ;AN039; ORIGINAL VALUE OF STACK FROM SP
	MOV    PSDATA_SEG:$P_ORIG_SI,SI ;AN039; ORIGINAL START PARSE POINTER FROM SI
$P_REDO_TIME:				;AN039; try to parse time again
ENDIF					;AN039; FOR TIME ONLY
	cld				      ;AN000; confirm forward direction
	mov	psdata_seg:$P_ordinal,cx      ;AC034; save operand ordinal
	mov	psdata_seg:$P_RC,$P_No_Error  ;AC034; Assume no error
	mov	psdata_seg:$P_Found_SYNONYM,0 ;AC034; initalize synonym pointer

	mov	word ptr psdata_seg:$P_DX,0   ;AC034; (tm15)
IF KeySW				;AN029;
;IN CASE THE USER PUT OPTIONAL WHITESPACE CHARS AROUND THE "=" USED IN
;KEYWORD DEFINITIONS, SCAN THE COMMAND LINE AND COMPRESS OUT ANY WHITESPACES
;NEXT TO "=" BEFORE STARTING THE USUAL PARSING.
       push	 cx			;AN029;
       push	 dx			;AN029;
       push	 di			;AN029;

       push	 si			;AN029; remember where command line starts
       mov	 cx,-1			;AN029; init counter
;      $do
$P_loc_eol:				;AN029;
	  inc	    cx			;AN029; bump counter of chars up to EOL
	  lodsb 			;AN029; get a char from command line
	  CALL	    $P_Chk_EOL		;AN029; see if AL is EOL char

;      enddo z
       jnz	 $P_loc_EOL		;AN029; not found that EOL char

       mov	 psdata_seg:$P_count_to_EOL,cx ;AN029;AC034;; save count of chars up to EOL
       pop	 si			;AN029; restore start of command line

;scan command string for combinations including "=",
;      and replace each with just the simple "="

;REPEAT UNTIL ONE PASS IS MADE WHEREIN NO CHANGES WERE MADE
;  $do
$P_DO1: 			   ;AN029;
       push si			   ;AN029; remember where string started
       MOV  CX,psdata_seg:$P_COUNT_TO_EOL ;AN029;AC034;; set  count to no. chars in string,
				   ;AN029; not counting the EOL char
       XOR  BX,BX		   ;AN029;SET $P_REG_BL_DQ_SW TO "NOT IN QUOTES", AND...
				   ;AN029;SET $P_REG_BH_CG_SW TO "NO CHANGES MADE"
;MAKE ONE PASS THRU THE STRING, LOOKING AT EACH CHARACTER
;      $do			   ;AN029;
$P_DO2: 			   ;AN029;
	   cmp	BYTE PTR [SI],$P_double_quote ;AN029;
;	   $if	e		   ;AN029;if a double quote was found
	   JNE $P_IF3		   ;AN029;
	       NOT  $P_REG_BL_DQ_SW ;AN029;TOGGLE THE DOUBLE QUOTE STATE SWITCH
;	   $endif		   ;AN029;
$P_IF3: 			   ;AN029;
	   OR	$P_REG_BL_DQ_SW,$P_REG_BL_DQ_SW ;AN029;IS THE DOUBLE QUOTE SWITCH SET?
;	   $if	Z		   ;AN029;IF NOT IN DOUBLE QUOTES
	   JNZ $P_IF5		   ;AN029;
	       mov  ax,word ptr [si] ;AN029; get pair to be checked out
	       cmp  ax,$P_BL_EQ    ;AN029;" ="
;	       $if  e,or	   ;AN029;
	       JE $P_LL6	   ;AN029;
	       cmp  ax,$P_EQ_BL    ;AN029;"= "
;	       $if  e,or	   ;AN029;
	       JE $P_LL6	   ;AN029;
	       cmp  ax,$P_EQ_TB    ;AN029; "=<tab>"
;	       $if  e,or	   ;AN029;
	       JE $P_LL6	   ;AN029;
	       cmp  ax,$P_TB_EQ    ;AN029;"<tab>="
;	       $if  e		   ;AN029;if this pair to be replaced with a single "="
	       JNE $P_IF6	   ;AN029;
$P_LL6: 			   ;AN029;
		   mov	BYTE PTR [SI],$P_Keyword ;AN029; "="
		   inc	si	   ;AN029;point to next char after the new "="
		   mov	di,si	   ;AN029;move target right after new "="

		   push si	   ;AN029;remember where i am, right after new "="
		   PUSH CX	   ;AN029;SAVE CURRENT COUNT
		   inc	si	   ;AN029;source is one beyond that
		   push es	   ;AN029;remember the extra segment
		   push ds	   ;AN029;temporarily, set source seg and
		   pop	es	   ;AN029; target seg to the command line seg
		   rep	movsb	   ;AN029;move chars left one position
		   pop	es	   ;AN029;restore the extra segment
		   POP	CX	   ;AN029;RESTORE CURRENT COUNT
		   pop	si	   ;AN029;back to where I was

		   DEC	SI	   ;AN029;LOOK AT FIRST CHAR JUST MOVED
		   MOV	$P_REG_BH_CG_SW,-1 ;AN029;set switch to say "a change was made"
		   DEC	psdata_seg:$P_COUNT_TO_EOL ;AN029;AC034;;because just threw away a char
		   dec	CX	   ;AN029;DITTO
;	       $endif		   ;AN029;comparand pair found?
$P_IF6: 			   ;AN029;
;	   $endif		   ;AN029;double quote switch?
$P_IF5: 			   ;AN029;
	   inc	si		   ;AN029;bump index to look at next char in command string
	   dec	CX		   ;AN029;one less char to look at
;(deleted ;AC035;)  CMP  CX,0		    ;AN029;is char count all gone yet?
;      $enddo LE		   ;AN029;quit if no more chars
       JNLE $P_DO2		   ;AN029;
       pop  si			   ;AN029;remember where string started
       OR   $P_REG_BH_CG_SW,$P_REG_BH_CG_SW ;AN029;WAS "A CHANGE MADE"?
;  $enddo Z			   ;AN029;QUIT when no changes were made
   JNZ $P_DO1			   ;AN029;
   pop	di			   ;AN029;
   pop	dx			   ;AN029;
   pop	cx			   ;AN029;

;NOW THAT ALL WHITESPACE SURROUNDING "=" HAVE BEEN COMPRESSED OUT,
;RESUME NORMAL PARSING...
ENDIF					;AN029; KEYWORDS SUPPORTED?
	call	$P_Skip_Delim		;AN000; Move si to 1st non white space
	jnc	$P_Start		;AN000; If EOL is not encountered, do parse

;--------------------------- End of Line
	mov	ax,$P_RC_EOL		;AN000; set exit code to -1
	push	bx			;AN000;
	mov	bx,es:[di].$P_PARMSX_Address ;AN000; Get the PARMSX address to
	cmp	cl,es:[bx].$P_MinP	;AN000; check ORDINAL to see if the minimum
	jae	$P_Fin			;AN000; positional found.

	mov	ax,$P_Op_Missing	;AN000; If no, set exit code to missing operand
$P_Fin: 				;AN000;
	pop	bx			;AN000;
	jmp	$P_Single_Exit		;AN000; return to the caller

;---------------------------
$P_Start:				;AN000;
	mov	psdata_seg:$P_SaveSI_Cmpx,si ;AN000;AC034;  save ptr to command line for later use by complex,
	push	bx			;AN000; quoted string or file spec.
	push	di			;AN000;
	push	bp			;AN000;
	lea	bx,psdata_seg:$P_STRING_BUF ;AC034; set buffer to copy from command string
	test	psdata_seg:$P_Flags2,$P_Extra ;AC034; 3/9 extra delimiter encountered ?
	jne	$P_Pack_End		;AN000; 3/9 if yes, no need to copy

$P_Pack_Loop:				;AN000;
	lodsb				;AN000; Pick a operand from buffer
	call	$P_Chk_Switch		;AN000; Check switch character
	jc	$P_Pack_End_BY_EOL	;AN020; if carry set found delimiter type slash, need backup si, else continue

	call	$P_Chk_EOL		;AN000; Check EOL character
	je	$P_Pack_End_BY_EOL	;AN000; need backup si

	call	$P_Chk_Delim		;AN000; Check delimiter
	jne	$P_PL01 		;AN000; If no, process next byte

	test	psdata_seg:$P_Flags2,$P_Extra ;AC034; 3/9 If yes and white spec,
; (tm08)jne	$P_Pack_End		;AN000; 3/9 then
	jne	$P_Pack_End_backup_si	;AN000; (tm08)

	call	$P_Skip_Delim		;AN000; skip subsequent white space,too
	jmp	short $P_Pack_End	;AN000; finish copy by placing NUL at end

$P_PAck_End_backup_si:			;AN000; (tm08)
	test	psdata_seg:$P_Flags2,$P_SW+$P_equ ;AN000;AC034;  (tm08)
	je	$P_Pack_End		;AN000; (tm08)

	dec	si			;AN000; (tm08)
	jmp	short $P_Pack_End	;AN025; (tm08)

$P_PL01:				;AN000;
	mov	psdata_seg:[bx],al	;AN000; move byte to STRING_BUF
	cmp	al,$P_Keyword		;AN000; if it is equal character,
	jne	$P_PL00 		;AN000; then

	or	psdata_seg:$P_Flags2,$P_equ ;AC034; remember it in flag
$P_PL00:				;AN000;
	inc	bx			;AN000; ready to see next byte
	call	$P_Chk_DBCS		;AN000; was it 1st byte of DBCS ?
	jnc	$P_Pack_Loop		;AN000; if no, process to next byte

	lodsb				;AN000; if yes, store
	mov	psdata_seg:[bx],al	;AN000;    2nd byte of DBCS
	inc	bx			;AN000; update pointer
	jmp	short $P_Pack_Loop	;AN000; process to next byte

$P_Pack_End_BY_EOL:			;AN000;
	dec	si			;AN000; backup si pointer
$P_Pack_End:				;AN000;
	mov	psdata_seg:$P_SI_Save,si     ;AC034; save next pointer, SI
	mov	byte ptr psdata_seg:[bx],$P_NULL ;AN000; put NULL at the end
	mov	psdata_seg:$P_Save_EOB,bx    ;AC034; 3/17/87 keep the address for later use of complex
	mov	bx,es:[di].$P_PARMSX_Address ;AN000; get PARMSX address
	lea	si,psdata_seg:$P_STRING_BUF  ;AC034;
	cmp	byte ptr psdata_seg:[si],$P_Switch ;AN000; the operand begins w/ switch char ?
	je	$P_SW_Manager		     ;AN000; if yes, process as switch

	test	psdata_seg:$P_Flags2,$P_equ   ;AC034; the operand includes equal char ?
	jne	$P_Key_manager		     ;AN000; if yes, process as keyword

$P_Positional_Manager:			;AN000; else process as positional
	mov	al,es:[bx].$P_MaxP	;AN000; get maxp
	xor	ah,ah			;AN000; ax = maxp
	cmp	psdata_seg:$P_ORDINAL,ax ;AC034; too many positional ?
	jae	$P_Too_Many_Error	;AN000; if yes, set exit code to too many

	mov	ax,psdata_seg:$P_ORDINAL ;AC034; see what the current ordinal
	shl	ax,1			;AN000; ax = ax*2
	inc	bx			;AC035; add '2' to
	inc	bx			;AC035;  BX reg
					;AN000; now bx points to 1st CONTROL
;(changed ;AC035;) add	   bx,2 	;AN000; now bx points to 1st CONTROL
	add	bx,ax			;AN000; now bx points to specified CONTROL address
	mov	bx,es:[bx]		;AN000; now bx points to specified CONTROL itself
	call	$P_Chk_Pos_Control	;AN000; Do process for positional
	jmp	short $P_Return_to_Caller ;AN000; and return to the caller

$P_Too_Many_Error:			;AN000;
	mov	psdata_seg:$P_RC,$P_Too_Many ;AC034; set exit code
	jmp	short $P_Return_to_Caller ;AN000; and return to the caller
;
$P_SW_Manager:				;AN000;
	mov	al,es:[bx].$P_MaxP	;AN000; get maxp
	xor	ah,ah			;AN000; ax = maxp
	inc	ax			;AN000;
	shl	ax,1			;AN000; ax = (ax+1)*2
	add	bx,ax			;AN000; now bx points to maxs
	mov	cl,es:[bx]		;AN000;
	xor	ch,ch			;AN000; cx = maxs
	or	cx,cx			;AN000; at least one switch ?
	je	$P_SW_Not_Found 	;AN000;

	inc	bx			;AN000; now bx points to 1st CONTROL address

$P_SW_Mgr_Loop: 			;AN000;
	push	bx			;AN000;
	mov	bx,es:[bx]		;AN000; bx points to Switch CONTROL itself
	call	$P_Chk_SW_Control	;AN000; do process for switch
	pop	bx			;AN000;
	jnc	$P_Return_to_Caller	;AN000; if the CONTROL is for the switch, exit

	inc	bx			;AC035; add '2' to
	inc	bx			;AC035;  BX reg
					;AN000; else bx points to the next CONTROL
;(changed ;AC035;)  add     bx,2	;AN000; else bx points to the next CONTROL
	loop	$P_SW_Mgr_Loop		;AN000; and loop

$P_SW_Not_Found:			;AN000;
	mov	psdata_seg:$P_RC,$P_Not_In_SW ;AC034; here no CONTROL for the switch has
	jmp	short $P_Return_to_Caller0    ;AN000; not been found, means error.
;
$P_Key_Manager: 			;AN000;
	mov	al,es:[bx].$P_MaxP	;AN000; get maxp
	xor	ah,ah			;AN000; ax = maxp
	inc	ax			;AN000;
	shl	ax,1			;AN000; ax = (ax+1)*2
	add	bx,ax			;AN000; now bx points to maxs
	mov	al,es:[bx]		;AN000;
	xor	ah,ah			;AN000; ax = maxs
	shl	ax,1			;AN000;
	inc	ax			;AN000; ax = ax*2+1
	add	bx,ax			;AN000; now bx points to maxk
	mov	cl,es:[bx]		;AN000;
	xor	ch,ch			;AN000; cx = maxk
	or	cx,cx			;AN000; at least one keyword ?
	je	$P_Key_Not_Found	;AN000;

	inc	bx			;AN000; now bx points to 1st CONTROL

$P_Key_Mgr_Loop:			;AN000;
	push	bx			;AN000;
	mov	bx,es:[bx]		;AN000; bx points to keyword CONTROL itself
	call	$P_Chk_Key_Control	;AN000; do process for keyword
	pop	bx			;AN000;
	jnc	$P_Return_to_Caller	;AN000; if the CONTROL is for the keyword, exit

	inc	bx			;AC035; add '2' to
	inc	bx			;AC035;  BX reg
					;AN000; else bx points to the next CONTROL
;(changed ;AC035;)  add     bx,2	;AN000; else bx points to the next CONTROL
	loop	$P_Key_Mgr_Loop 	;AN000; and loop

$P_Key_Not_Found:			;AN000;
	mov	psdata_seg:$P_RC,$P_Not_In_Key ;AC034; here no CONTROL for the keyword has
$P_Return_to_Caller0:			;AN000; not been found, means error.

;(deleted ;AN024;)	 mov	 bx,es:[bx-2]		 ;AN000; (tm13) backup bx

;(deleted ;AN024;)	 mov	 al,$P_String		 ;AN000; Set
;(deleted ;AN024;)	 mov	 ah,$P_No_Tag		 ;AN000;     result
;(deleted ;AN024;)	 call	 $P_Fill_Result 	 ;AN000;	    buffer

$P_Return_to_Caller:			;AN000;
	pop	bp			;AN000;
	pop	di			;AN000;
	pop	bx			;AN000;
	mov	cx,psdata_seg:$P_Ordinal    ;AC034; return next ordinal
	mov	ax,psdata_seg:$P_RC	    ;AC034; return exit code
	mov	si,psdata_seg:$P_SI_Save    ;AC034; return next operand pointer
	mov	dx,psdata_seg:$P_DX	    ;AC034; return result buffer address
	mov	bl,psdata_seg:$P_Terminator ;AC034; return delimiter code found
$P_Single_Exit: 			;AN000;
	clc				;AN000;
	ret				;AN000;
SysParse endp				;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Chk_Pos_Control
;
; Function: Parse CONTROL block for a positional
;
; Input:     ES:BX -> CONTROL block
;	     psdata_seg:SI -> $P_STRING_BUF
;
; Output:    None
;
; Use:	 $P_Fill_Result, $P_Check_Match_Flags
;
; Vars: $P_Ordinal(W), $P_RC(W)
;***********************************************************************
$P_Chk_Pos_Control proc 		;AN000;
	push	ax			;AN000;
	mov	ax,es:[bx].$P_Match_Flag ;AN000;
	test	ax,$P_Repeat		;AN000; repeat allowed ?
	jne	$P_CPC00		;AN000; then do not increment ORDINAL

	inc	psdata_seg:$P_ORDINAL	;AC034; update the ordinal
$P_CPC00:				;AN000;
	cmp	byte ptr psdata_seg:[si],$P_NULL ;AN000; no data ?
	jne	$P_CPC01		;AN000;

	test	ax,$P_Optional		;AN000; yes, then is it optional ?
	jne	$P_CPC02		;AN000;

	mov	psdata_seg:$P_RC,$P_Op_Missing ;AC034; no, then error	     3/17/87
	jmp	short $P_CPC_Exit	;AN000;

$P_CPC02:				;AN000;
	push	ax			;AN000;
	mov	al,$P_String		;AN000; if it is optional return NULL
	mov	ah,$P_No_Tag		;AN000; no item tag indication
	call	$P_Fill_Result		;AN000;
	pop	ax			;AN000;
	jmp	short $P_CPC_Exit	;AN000;

$P_CPC01:				;AN000;
	call	$P_Check_Match_Flags	;AN000;
$P_CPC_Exit:				;AN000;
	pop	ax			;AN000;
	ret				;AN000;
$P_Chk_Pos_Control endp 		;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Chk_Key_Control
;
; Function: Parse CONTROL block for a keyword
;
; Input:     ES:BX -> CONTROL block
;	     psdata_seg:SI -> $P_STRING_BUF
;
; Output:    CY = 1 : not match
;
; Use:	 $P_Fill_Result, $P_Search_KEYorSW, $P_Check_Match_Flags
;
; Vars: $P_RC(W), $P_SaveSI_Cmpx(W), $P_KEYorSW_Ptr(R), $P_Flags(W)
;***********************************************************************
$P_Chk_Key_Control proc 		;AN000;
IF	KeySW				;AN000;(Check if keyword is supported)
	or	psdata_seg:$P_Flags2,$P_Key_Cmp ;AC034; Indicate keyword for later string comparison
	call	$P_Search_KEYorSW	;AN000; Search the keyword in the CONTROL block
	jc	$P_Chk_Key_Err0 	;AN000; not found, then try next CONTROL

	and	psdata_seg:$P_Flags2,0ffh-$P_Key_Cmp ;AC034; reset the indicator previously set
;
	push	ax			     ;AN000;	      keyword=
	mov	ax,psdata_seg:$P_KEYorSW_Ptr ;AC034;	      ^       ^
	sub	ax,si			;AN000;  SI	KEYorSW
	add	psdata_seg:$P_SaveSI_Cmpx,ax ;AC034; update for complex, quoted or file spec.
	pop	ax			;AN000;
;
	mov	si,psdata_seg:$P_KEYorSW_Ptr ;AC034; set si just after equal char
	cmp	byte ptr psdata_seg:[si],$P_NULL ;AN000; any data after equal ?
	je	$P_Chk_Key_Err1 	;AN000; if no, syntax error

	call	$P_Check_Match_Flags	;AN000; else, process match flags
	clc				;AN000;
	jmp	short $P_Chk_Key_Exit	;AN000;

$P_Chk_Key_Err0:			;AN000;
	stc				;AN000; not found in keyword synonym list
	jmp	short $P_Chk_Key_Exit	;AN000;

$P_Chk_Key_Err1:			;AN000;
	mov	psdata_seg:$P_RC,$P_Syntax ;AC034; no parameter is not specified after "="
$P_Chk_Key_ErrExit:			;AN000;
	push	ax			;AN000;
	mov	al,$P_String		;AN000; set
	mov	ah,$P_No_Tag		;AN000;    result
	call	$P_Fill_Result		;AN000; 	 buffer
	pop	ax			;AN000;
	clc				;AN000;
$P_Chk_Key_Exit:			;AN000;
	ret				;AN000;
ELSE					;AN000;(of IF KeySW)
	stc				;AN000;this logic works when the KeySW
	ret				;AN000;is reset.
ENDIF					;AN000;(of KeySW)
$P_Chk_Key_Control endp 		;AN000;
PAGE					;AN000;
;***********************************************************************
IF	KeySW+SwSW			;AN000;(Check if keyword or switch is supported)
; $P_Search_KEYorSW:
;
; Function: Seach specified keyword or switch from CONTROL
;
; Input:     ES:BX -> CONTROL block
;	     psdata_seg:SI -> $P_STRING_BUF
;
; Output:    CY = 1 : not match
;
; Use:	 $P_String_Comp, $P_MoveBP_NUL, $P_Found_SYNONYM
;***********************************************************************
$P_Search_KEYorSW proc			;AN000;
	push	bp			;AN000;
	push	cx			;AN000;
	mov	cl,es:[bx].$P_nid	;AN000; Get synonym count
	xor	ch,ch			;AN000; and set it to cx
	or	cx,cx			;AN000; No synonyms specified ?
	je	$P_KEYorSW_Not_Found	;AN000; then indicate not found by CY

	lea	bp,es:[bx].$P_KEYorSW	;AN000; BP points to the 1st synonym
$P_KEYorSW_Loop:			;AN000;
	call	$P_String_Comp		;AN000; compare string in buffer w/ the synonym
	jnc	$P_KEYorSW_Found	;AN000; If match, set it to synonym pointer

	call	$P_MoveBP_NUL		;AN000; else, bp points to the next string
	loop	$P_KEYorSW_Loop 	;AN000; loop nid times
$P_KEYorSW_Not_Found:			;AN000;
	stc				;AN000; indicate not found in synonym list
	jmp	short $P_KEYorSW_Exit	;AN000; and exit

$P_KEYorSW_Found:			;AN000;
	mov	psdata_seg:$P_Found_SYNONYM,bp ;AC034; set synonym pointer
	clc				;AN000; indicate found
$P_KEYorSW_Exit:			;AN000;
	pop	cx			;AN000;
	pop	bp			;AN000;
	ret				;AN000;
$P_Search_KEYorSW endp			;AN000;
;***********************************************************************
; $P_MoveBP_NUL
;***********************************************************************
$P_MoveBP_NUL proc			;AN000;
$P_MBP_Loop:				;AN000;
	cmp	byte ptr es:[bp],$P_NULL ;AN000; Increment BP that points
	je	$P_MBP_Exit		;AN000; to the synomym list

	inc	bp			;AN000; until
	jmp	short $P_MBP_Loop	;AN000; NULL encountered.

$P_MBP_Exit:				;AN000;
	inc	bp			;AN000; bp points to next to NULL
	ret				;AN000;
$P_MoveBP_NUL endp			;AN000;
ENDIF					;AN000;(of KeySW+SwSW)
PAGE					;AN000;
;***********************************************************************
; $P_Chk_SW_Control
;
; Function: Parse CONTROL block for a switch
;
; Input:     ES:BX -> CONTROL block
;	     psdata_seg:SI -> $P_STRING_BUF
;
; Output:    CY = 1 : not match
;
; Use:	 $P_Fill_Result, $P_Search_KEYorSW, $P_Check_Match_Flags
;
; Vars:  $P_SaveSI_Cmpx(W), $P_KEYorSW_Ptr(R), $P_Flags(W)
;***********************************************************************
$P_Chk_SW_Control proc			;AN000;


IF	SwSW				;AN000;(Check if switch is supported)
	or	psdata_seg:$P_Flags2,$P_Sw_Cmp ;AC034; Indicate switch for later string comparison
	call	$P_Search_KEYorSW	;AN000; Search the switch in the CONTROL block
	jc	$P_Chk_SW_Err0		;AN000; not found, then try next CONTROL

	and	psdata_seg:$P_Flags2,0ffh-$P_Sw_Cmp ;AC034; reset the indicator previously set
;
	push	ax			;AN000; 	      /switch:
	mov	ax,psdata_seg:$P_KEYorSW_Ptr ;AC034;	      ^       ^
	sub	ax,si			;AN000;  SI	KEYorSW
	add	psdata_seg:$P_SaveSI_Cmpx,ax ;AC034; update for complex list
	pop	ax			;AN000;
;
	mov	si,psdata_seg:$P_KEYorSW_Ptr ;AC034; set si at the end or colon
	cmp	byte ptr psdata_seg:[si],$P_NULL ;AN000; any data after colon
	jne	$P_CSW00		;AN000; if yes, process match flags

	cmp	byte ptr psdata_seg:[si-1],$P_Colon ;AN000; if no, the switch terminated by colon ?
	jne	$P_Chk_if_data_required ;AN000; if yes,

	mov	psdata_seg:$P_RC,$P_Syntax ;AC034; return syntax error
	jmp	short $P_Chk_SW_Exit	;AN000;

$P_Chk_if_data_required:		;AN018; no data, no colon
	cmp	es:[bx].$P_Match_Flag,0 ;AN018; should have data? zero match flag means switch followed by nothing is OK
	je	$P_Chk_SW_Exit		;AN018; match flags not zero so should have something if optional bit is not on

	test	es:[bx].$P_Match_Flag,$P_Optional ;AN019; see if no value is valid
	jnz	$P_Chk_SW_Exit		;AN019; if so, then leave, else yell

	mov	psdata_seg:$P_RC,$P_Op_Missing ;AC034; return required operand missing
	jmp	short $P_Chk_SW_Exit	;AN018;

$P_CSW00:				;AN000;
	call	$P_Check_Match_Flags	;AN000; process match flag
	clc				;AN000; indicate match
	jmp	short $P_Chk_SW_Single_Exit ;AN000;

$P_Chk_SW_Err0: 			;AN000;
	stc				;AN000; not found in switch synonym list
	jmp	short $P_Chk_SW_Single_Exit ;AN000;

$P_Chk_SW_Exit: 			;AN000;
	push	ax			;AN000;
	mov	al,$P_String		;AN000; set
	mov	ah,$P_No_Tag		;AN000;    result
	call	$P_Fill_Result		;AN000; 	 buffer
	pop	ax			;AN000;
	clc				;AN000;
$P_Chk_SW_Single_Exit:			;AN000;
	ret				;AN000;
ELSE					;AN000;(of IF SwSW)
	stc				;AN000; this logic works when the SwSW
	ret				;AN000; is reset.
ENDIF					;AN000;(of SwSW)
$P_Chk_SW_Control endp			;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Fill_Result
;
; Function: Fill the result buffer
;
; Input:    AH = Item tag
;	    AL = type
;		  AL = 1: CX,DX has 32bit number (CX = high)
;		  AL = 2: DX has index(offset) into value list
;		  AL = 6: DL has driver # (1-A, 2-B, ... , 26 - Z)
;		  AL = 7: DX has year, CL has month and CH has date
;		  AL = 8: DL has hours, DH has minutes, CL has secondsn,
;			  amd CH has hundredths
;		  AL = else: psdata_seg:SI points to returned string buffer
;	    ES:BX -> CONTROL block
;
; Output:   None
;
; Use:	$P_Do_CAPS_String, $P_Remove_Colon, $P_Found_SYNONYM
;
; Vars: $P_DX(W)
;***********************************************************************
$P_Fill_Result proc			;AN000;
	push	di			;AN000;
	mov	di,es:[bx].$P_Result_Buf ;AN000; di points to result buffer
	mov	psdata_seg:$P_DX,di	;AC034; set returned result address
	mov	es:[di].$P_Type,al	;AN000; store type
	mov	es:[di].$P_Item_Tag,ah	;AN000; store item tag
	push	ax			;AN000;
	mov	ax,psdata_seg:$P_Found_SYNONYM ;AC034; if yes,
	mov	es:[di].$P_SYNONYM_Ptr,ax ;AN000;   then set it to the result
	pop	ax			;AN000;
$P_RLT04:				;AN000;
	cmp	al,$P_Number		;AN000; if number
	jne	$P_RLT00		;AN000;

$P_RLT02:				;AN000;
	mov	word ptr es:[di].$P_Picked_Val,dx ;AN000; then store 32bit
	mov	word ptr es:[di+2].$P_Picked_Val,cx ;AN000;	number
	jmp	short $P_RLT_Exit	;AN000;

$P_RLT00:				;AN000;
	cmp	al,$P_List_Idx		;AN000; if list index
	jne	$P_RLT01		;AN000;

	mov	word ptr es:[di].$P_Picked_Val,dx ;AN000; then store list index
	jmp	short $P_RLT_Exit	;AN000;

$P_RLT01:				;AN000;
	cmp	al,$P_Date_F		;AN000; Date format ?
	je	$P_RLT02		;AN000;

	cmp	al,$P_Time_F		;AN000; Time format ?
	je	$P_RLT02		;AN000;
;
	cmp	al,$P_Drive		;AN000; drive format ?
	jne	$P_RLT03		;AN000;

	mov	byte ptr es:[di].$P_Picked_Val,dl ;AN000; store drive number
	jmp	short $P_RLT_Exit	;AN000;

$P_RLT03:				;AN000;
	cmp	al,$P_Complex		;AN000; complex format ?
	jne	$P_RLT05		;AN000;

	mov	ax,psdata_seg:$P_SaveSI_Cmpx ;AC034; then get pointer in command buffer
	inc	ax			;AN000; skip left Parentheses
	mov	word ptr es:[di].$P_Picked_Val,ax ;AN000; store offset
	mov	word ptr es:[di+2].$P_Picked_Val,ds ;AN000; store segment
	jmp	short $P_RLT_Exit	;AN000;

$P_RLT05:				;AN000;
;------------------------  AL = 3, 5, or 9
	mov	word ptr es:[di].$P_Picked_Val,si ;AN000; store offset of STRING_BUF
;(replaced ;AN031;)  mov word ptr es:[di+word].$P_Picked_Val,cs ;AN000; store segment of STRING_BUF
	mov	word ptr es:[di+2].$P_Picked_Val,Psdata_Seg ;AN031; store segment of STRING_BUF
;
	push	ax			;AN000;
	test	byte ptr es:[bx].$P_Function_Flag,$P_CAP_File ;AN000; need CAPS by file table?
	je	$P_RLT_CAP00		;AN000;

	mov	al,$P_DOSTBL_File	;AN000; use file upper case table
	jmp	short $P_RLT_CAP02	;AN000;

$P_RLT_CAP00:				;AN000;
	test	byte ptr es:[bx].$P_Function_Flag,$P_CAP_Char ;AN000; need CAPS by char table ?
	je	$P_RLT_CAP01		;AN000;

	mov	al,$P_DOSTBL_Char	;AN000; use character upper case table
$P_RLT_CAP02:				;AN000;
	call	$P_Do_CAPS_String	;AN000;  process CAPS along the table
$P_RLT_CAP01:				;AN000;
	pop	ax			;AN000;
	test	byte ptr es:[bx].$P_Function_Flag,$P_Rm_Colon ;AN000; removing colon at end ?
	je	$P_RLT_Exit		;AN000;

	call	$P_Remove_Colon 	;AN000; then process it.
$P_RLT_Exit:				;AN000;
	pop	di			;AN000;
	ret				;AN000;
$P_Fill_Result endp			;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Check_Match_Flags
;
; Function:  Check the mutch_flags and make the exit code and set the
;	     result buffer
;
;	    Check for types in this order:
;		Complex
;		Date
;		Time
;		Drive
;		Filespec
;		Quoted String
;		Simple String
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;	     ES:BX -> CONTROL block
;
; Output:    None
;
; Use:	     $P_Value, P$_SValue, $P_Simple_String, $P_Date_Format
;	     $P_Time_Format, $P_Complex_Format, $P_File_Foemat
;	     $P_Drive_Format
;***********************************************************************
$P_Check_Match_Flags proc		;AN000;
	mov	psdata_seg:$P_err_flag,$P_NULL ;AN033;AC034;; clear filespec error flag.
	push	ax			;AN000;
	mov	ax,es:[bx].$P_Match_Flag ;AN000; load match flag(16bit) to ax

	or	ax,ax			;AC035; test ax for zero
;(changed ;AC035;)  cmp     ax,0	;AN000; (tm12)
	jne	$P_Mat			;AN000; (tm12)

	push	ax			;AN000; (tm12)
	push	bx			;AN000; (tm12)
	push	dx			;AN000; (tm12)
	push	di			;AN000; (tm12)
	mov	psdata_seg:$P_RC,$P_Syntax ;AC034; (tm12)
	mov	ah,$P_No_Tag		;AN000; (tm12)
	mov	al,$P_String		;AN000; (tm12)
	call	$P_Fill_Result		;AN000; (tm12)
	pop	di			;AN000; (tm12)
	pop	dx			;AN000; (tm12)
	pop	bx			;AN000; (tm12)
	pop	ax			;AN000; (tm12)
	jmp	short $P_Bridge 	;AC035; (tm12)

$P_Mat: 				;AN000; (tm12)

IF	CmpxSW				;AN000;(Check if complex item is supported)
	test	ax,$P_Cmpx_S		;AN000; Complex string
	je	$P_Match01		;AN000;

	mov	psdata_seg:$P_RC,$P_No_Error ;AC034; assume no error
	call	$P_Complex_Format	;AN000; do process
	cmp	psdata_seg:$P_RC,$P_Syntax ;AC034; if error, examine the next type
	jne	$P_Bridge		;AN000;

$P_Match01:				;AN000;
ENDIF					;AN000;(of CmpxSW)
IF	DateSW				;AN000;(Check if date format is supported)
	test	ax,$P_Date_S		;AN000; Date string
	je	$P_Match02		;AN000;

	mov	psdata_seg:$P_RC,$P_No_Error ;AC034; assume no error
	call	$P_Date_Format		;AN000; do process
	cmp	psdata_seg:$P_RC,$P_Syntax ;AC034; if error, examine the next type
	jne	$P_Bridge		;AN000;

$P_Match02:				;AN000;
ENDIF					;AN000;(of DateSW)
IF	TimeSW				;AN000;(Check if time format is supported)
	test	ax,$P_Time_S		;AN000; Time string
	je	$P_Match03		;AN000;

	mov	psdata_seg:$P_RC,$P_No_Error ;AC034; assume no error
	call	$P_Time_Format		;AN000; do process
	cmp	psdata_seg:$P_RC,$P_Syntax ;AC034; if error, examine the next type
;	je	$P_Match03		;AN000:

	jne	$P_Bridge		;AN000; (tm09)

ENDIF					;AN000;(of TimeSW)  (tm04)
	jmp	short $P_Match03	;AN025; (tm09)

$P_Bridge:				;AN000;
;	jmp	short $P_Match_Exit (tm02)

	jmp	$P_Match_Exit		;AN000; (tm02)

$P_Match03:				;AN000;
; ENDIF ;AN000;(of TimeSW) (tm04)
IF	NumSW				;AN000;(Check if numeric value is supported)
	test	ax,$P_Num_Val		;AN000; Numeric value
	je	$P_Match04		;AN000;

	mov	psdata_seg:$P_RC,$P_No_Error ;AC034; assume no error
	call	$P_Value		;AN000; do process
	cmp	psdata_seg:$P_RC,$P_Syntax ;AC034; if error, examine the next type
	jne	$P_Match_Exit		;AN000;

$P_Match04:				;AN000;
	test	ax,$P_SNUM_Val		;AN000; Signed numeric value
	je	$P_Match05		;AN000;

	mov	psdata_seg:$P_RC,$P_No_Error ;AC034; assume no error
	call	$P_SValue		;AN000; do process
	cmp	psdata_seg:$P_RC,$P_Syntax ;AC034; if error, examine the next type
	jne	$P_Match_Exit		;AN000;

$P_Match05:				;AN000;
ENDIF					;AN000;(of NumSW)
IF	DrvSW				;AN000;(Check if drive only is supported)
	test	ax,$P_Drv_Only		;AN000; Drive only
	je	$P_Match06		;AN000;

	mov	psdata_seg:$P_RC,$P_No_Error ;AC034; assume no error
	call	$P_File_Format		;AN000; 1st, call file format
	call	$P_Drive_Format 	;AN000; check drive format, next
	cmp	psdata_seg:$P_RC,$P_Syntax ;AC034; if error, examinee the next type
	jne	$P_Match_Exit		;AN000;

$P_Match06:				;AN000;
ENDIF					;AN000;(of DrvSW)
IF	FileSW				;AN000;(Check if file spec is supported)
	test	ax,$P_File_Spc		;AN000; File spec
	je	$P_Match07		;AN000;

	mov	psdata_seg:$P_RC,$P_No_Error ;AC034; assume no error
	call	$P_File_Format		;AN000; do process
	cmp	psdata_seg:$P_RC,$P_Syntax ;AC034; if error, examine the next type
	jne	$P_Match_Exit		;AN000;

$P_Match07:				;AN000;
ENDIF					;AN000;(of FileSW)
IF	QusSW				;AN000;(Check if quoted string is supported)
	test	ax,$P_Qu_String 	;AN000; Quoted string
	je	$P_Match08		;AN000;

	mov	psdata_seg:$P_RC,$P_No_Error ;AC034; assume no error
	call	$P_Quoted_Format	;AN000; do process
	cmp	psdata_seg:$P_RC,$P_Syntax ;AC034; if error, examine the next type
	jne	$P_Match_Exit		;AN000;

$P_Match08:				;AN000;
ENDIF					;AN000;(of QusSW)
	test	ax,$P_Simple_S		;AN000; Simple string
	je	$P_Match09		;AN000;

	mov	psdata_seg:$P_RC,$P_No_Error ;AC034; assume no error
	call	$P_Simple_String	;AN000; do process
;;;;	cmp	psdata_seg:$P_RC,$P_Syntax ;AC034; These two lines will be alive
;;;;	jne	$P_Match_Exit			   ;when extending the match_flags.
$P_Match09:				;AN000;
$P_Match_Exit:				;AN000;
	cmp	psdata_seg:$P_err_flag,$P_error_filespec ;AC034; bad filespec ?
	jne	$P_Match2_Exit		;AN033; no, continue
	cmp	psdata_seg:$P_RC,$P_No_Error ;AN033;AC034;; check for other errors ?
	jne	$P_Match2_Exit		;AN033; no, continue
	mov	psdata_seg:$P_RC,$P_Syntax ;AN033;AC034;; set error flag
$P_Match2_Exit: 			;AN033;
	pop	ax			;AN000;
	ret				;AN000;
$P_Check_Match_Flags endp		;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Remove_Colon;
;
; Function: Remove colon at end
;
; Input:    psdata_seg:SI points to string buffer to be examineed
;
; Output:   None
;
; Use:	$P_Chk_DBCS
;***********************************************************************
$P_Remove_Colon proc			;AN000;
	push	ax			;AN000;
	push	si			;AN000;
$P_RCOL_Loop:				;AN000;
	mov	al,psdata_seg:[si]	;AN000; get character
	or	al,al			;AN000; end of string ?
	je	$P_RCOL_Exit		;AN000; if yes, just exit

	cmp	al,$P_Colon		;AN000; is it colon ?
	jne	$P_RCOL00		;AN000;

	cmp	byte ptr psdata_seg:[si+byte],$P_NULL ;AN000; if so, next is NULL ?
	jne	$P_RCOL00		;AN000; no, then next char

	mov	byte ptr psdata_seg:[si],$P_NULL ;AN000; yes, remove colon
	jmp	short $P_RCOL_Exit	;AN000; and exit.

$P_RCOL00:				;AN000;
	call	$P_Chk_DBCS		;AN000; if not colon, then check if
	jnc	$P_RCOL01		;AN000; DBCS leading byte.

	inc	si			;AN000; if yes, skip trailing byte
$P_RCOL01:				;AN000;
	inc	si			;AN000; si points to next byte
	jmp	short $P_RCOL_Loop	;AN000; loop until NULL encountered

$P_RCOL_Exit:				;AN000;
	pop	si			;AN000;
	pop	ax			;AN000;
	ret				;AN000;
$P_Remove_Colon endp			;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Do_CAPS_String;
;
; Function: Perform capitalization along with the file case map table
;	    or character case map table.
;
; Input:    AL = 2 : Use character table
;	    AL = 4 : Use file table
;	    psdata_seg:SI points to string buffer to be capitalized
;
; Output:   None
;
; Use:	$P_Do_CAPS_Char, $P_Chk_DBCS
;***********************************************************************
$P_Do_CAPS_String proc			;AN000;
	push	si			;AN000;
	push	dx			;AN000;
	mov	dl,al			;AN000; save info id

$P_DCS_Loop:				;AN000;
	mov	al,psdata_seg:[si]	;AN000; load charater and
	call	$P_Chk_DBCS		;AN000; check if DBCS leading byte
	jc	$P_DCS00		;AN000; if yes, do not need CAPS

	or	al,al			;AN000; end of string ?
	je	$P_DCS_Exit		;AN000; then exit.

	call	$P_Do_CAPS_Char 	;AN000; Here a SBCS char need to be CAPS
	mov	psdata_seg:[si],al	;AN000; stored upper case char to buffer
	jmp	short $P_DCS01		;AN000; process nexit
$P_DCS00:				;AN000;
	inc	si			;AN000; skip DBCS leading and trailing byte
$P_DCS01:				;AN000;
	inc	si			;AN000; si point to next byte
	jmp	short $P_DCS_Loop	;AN000; loop until NULL encountered
$P_DCS_Exit:				;AN000;
	pop	dx			;AN000;
	pop	si			;AN000;
	ret				;AN000;
$P_Do_CAPS_String endp			;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Do_CAPS_Char;
;
; Function: Perform capitalization along with the file case map table
;	    or character case map table.
;
; Input:    DL = 2 : Use character table
;	    DL = 4 : Use file table
;	    AL = character to be capitalized
;
; Output:   None
;
; Use:	INT 21h /w AH=65h
;***********************************************************************
$P_Do_CAPS_Char proc			;AN000;
	cmp	al,$P_ASCII80		;AN000; need upper case table ?
	jae	$P_DCC_Go		;AN000;

	cmp	al,"a"                  ;AN000; if no,
	jb	$P_CAPS_Ret		;AN000;   check if  "a" <= AL <= "z"

	cmp	al,"z"                  ;AN000;
	ja	$P_CAPS_Ret		;AN000;   if yes, make CAPS

	and	al,$P_Make_Upper	;AN000;   else do nothing.
	jmp	short $P_CAPS_Ret	;AN000;

$P_DCC_Go:				;AN000;
	push	bx			;AN000;
	push	es			;AN000;
	push	di			;AN000;
IF	CAPSW				;AN000;(Check if uppercase conversion is supported)
	lea	di,psdata_seg:$P_File_CAP_Ptr ;AC034;
	cmp	dl,$P_DOSTBL_File	;AN000; Use file CAPS table ?
	je	$P_DCC00		;AN000;

ENDIF					;AN000;(of CAPSW)
	lea	di,psdata_seg:$P_Char_CAP_Ptr ;AC034; or use char CAPS table ?
$P_DCC00:				;AN000;
	cmp	psdata_seg:[di],dl	;AN000; already got table address ?
	je	$P_DCC01		;AN000; if no,

;In this next section, ES will be used to pass a 5 byte workarea to INT 21h,
; the GET COUNTYRY INFO call.  This usage of ES is required by the function
; call, regardless of what base register is currently be defined as PSDATA_SEG.
;BASESW EQU 0 means that ES is the psdata_seg reg.

IFDEF BASESW				;AN037; If BASESW has been defined, and
  IFE BASESW				;AN037; If ES is psdata base
	push	PSDATA_SEG		;AN037; save current base reg
  ENDIF 				;AN037;
ENDIF					;AN037;

	push	ax			;AN000; get CAPS table thru DOS call
	push	cx			;AN000;
	push	dx			;AN000;


	push	PSDATA_SEG		;AC036; pass current base seg into
					;(Note: this used to push CS.  BUG...
	pop	es			;AN000;   ES reg, required for
					;get extended country information
	mov	ah,$P_DOS_Get_TBL	;AN000; get extended CDI
	mov	al,dl			;AN000; upper case table
	mov	bx,$P_DOSTBL_Def	;AN000; get active CON
	mov	cx,$P_DOSTBL_BL 	;AN000; buffer length
	mov	dx,$P_DOSTBL_Def	;AN000; get for default code page
					;DI already set to point to buffer
	int	21h			;AN000; es:di point to buffer that
					;now has been filled in with info
	pop	dx			;AN000;
	pop	cx			;AN000;
	pop	ax			;AN000;
IFDEF BASESW				;AN037; If BASESW has been defined, and
  IFE BASESW				;AN037; If ES is psdata base
	pop	PSDATA_SEG		;AN037; restore current base reg
  ENDIF 				;AN037;
ENDIF					;AN037;
$P_DCC01:				;AN000;

;In this next section, ES will be used as the base of the XLAT table, provided
; by the previous GET COUNTRY INFO DOS call.  This usage of ES is made
; regardless of which base reg is currently the PSDATA_SEG reg.

IFDEF BASESW				;AN037; If BASESW has been defined, and
  IFE BASESW				;AN037; If ES is psdata base
	push	PSDATA_SEG		;AN037; save current base reg
  ENDIF 				;AN037;
ENDIF					;AN037;
	mov	bx,psdata_seg:[di+$P_DOS_TBL_Off] ;AN000; get offset of table
	mov	es,psdata_seg:[di+$P_DOS_TBL_Seg] ;AN000; get segment of table
	inc	bx			;AC035; add '2' to
	inc	bx			;AC035;  BX reg
					;AN000; skip length field
;(changed ;AN035;) add	   bx,word	;AN000; skip length field
	sub	al,$P_ASCII80		;AN000; make char to index
	xlat	es:[bx] 		;AN000; perform case map

IFDEF BASESW				;AN037; If BASESW has been defined, and
  IFE BASESW				;AN037; If ES is psdata base
	pop	PSDATA_SEG		;AN037; restore current base reg
  ENDIF 				;AN037;
ENDIF					;AN037;
	pop	di			;AN000;
	pop	es			;AN000;
	pop	bx			;AN000;
$P_CAPS_Ret:				;AN000;
	ret				;AN000;
$P_Do_CAPS_Char endp			;AN000;
PAGE					;AN000;
;***********************************************************************
IF	NumSW				;AN000;(Check if numeric value is supported)
; $P_Value / $P_SValue
;
; Function:  Make 32bit value from psdata_seg:SI and see value list
;	     and make result buffer.
;	     $P_SValue is an entry point for the signed value
;	     and this will simply call $P_Value after the handling
;	     of the sign character, "+" or "-"
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;	     ES:BX -> CONTROL block
;
; Output:    None
;
; Use:	$P_Fill_Result, $P_Check_OVF
;
; Vars: $P_RC(W), $P_Flags(RW)
;***********************************************************************
$P_SValue proc				;AN000; when signed value here
	push	ax			;AN000;
	or	psdata_seg:$P_Flags2,$P_Signed	    ;AC034; indicate a signed numeric
	and	psdata_seg:$P_Flags2,0ffh-$P_Neg  ;AC034; assume positive value
	mov	al,psdata_seg:[si]	;AN000; get sign
	cmp	al,$P_Plus		;AN000; "+" ?
	je	$P_SVal00		;AN000;

	cmp	al,$P_Minus		;AN000; "-" ?
	jne	$P_Sval01		;AN000; else

	or	psdata_seg:$P_Flags2,$P_Neg ;AC034; set this is negative value
$P_SVal00:				;AN000;
	inc	si			;AN000; skip sign char
$P_Sval01:				;AN000;
	call	$P_Value		;AN000; and process value
	pop	ax			;AN000;
	ret				;AN000;
$P_SValue endp				;AN000;
;***********************************************************************
$P_Value proc				;AN000;
	push	ax			;AN000;
	push	cx			;AN000;
	push	dx			;AN000;
	push	si			;AN000;
	xor	cx,cx			;AN000; cx = higher 16 bits
	xor	dx,dx			;AN000; dx = lower 16 bits
	push	bx			;AN000; save control pointer
$P_Value_Loop:				;AN000;
	mov	al,psdata_seg:[si]	;AN000; get character
	or	al,al			;AN000; end of line ?
	je	$P_Value00		;AN000;

	call	$P_0099 		;AN000; make asc(0..9) to bin(0..9)
	jc	$P_Value_Err0		;AN000;

	xor	ah,ah			;AN000;
	mov	bp,ax			;AN000; save binary number
	shl	dx,1			;AN000; to have 2*x
	rcl	cx,1			;AN000; shift left w/ carry
	call	$P_Check_OVF		;AN000; Overflow occurred ?
	jc	$P_Value_Err0		;AN000; then error, exit

	mov	bx,dx			;AN000; save low(2*x)
	mov	ax,cx			;AN000; save high(2*x)
	shl	dx,1			;AN000; to have 4*x
	rcl	cx,1			;AN000; shift left w/ carry
	call	$P_Check_OVF		;AN000; Overflow occurred ?
	jc	$P_Value_Err0		;AN000; then error, exit

	shl	dx,1			;AN000; to have 8*x
	rcl	cx,1			;AN000; shift left w/ carry
	call	$P_Check_OVF		;AN000; Overflow occurred ?
	jc	$P_Value_Err0		;AN000; then error, exit

	add	dx,bx			;AN000; now have 10*x
	adc	cx,ax			;AN000; 32bit ADD
	call	$P_Check_OVF		;AN000; Overflow occurred ?
	jc	$P_Value_Err0		;AN000; then error, exit

	add	dx,bp			;AN000; Add the current one degree decimal
	adc	cx,0			;AN000; if carry, add 1 to high 16bit
	call	$P_Check_OVF		;AN000; Overflow occurred ?
	jc	$P_Value_Err0		;AN000; then error, exit

	inc	si			;AN000; update pointer
	jmp	short $P_Value_Loop	;AN000; loop until NULL encountered
;
$P_Value_Err0:				;AN000;
	pop	bx			;AN000;
	jmp	$P_Value_Err		;AN000; Bridge
;
$P_Value00:				;AN000;
	pop	bx			;AN000; restore control pointer
	test	psdata_seg:$P_Flags2,$P_Neg ;AC034; here cx,dx = 32bit value
	je	$P_Value01		;AN000; was it negative ?

	not	cx			;AN000; +
	not	dx			;AN000; |- Make 2's complement
	add	dx,1			;AN000; |
	adc	cx,0			;AN000; +
$P_Value01:				;AN000; / nval =0
	mov	si,es:[bx].$P_Value_List ;AN000; si points to value list
	mov	al,es:[si]		;AN000; get nval
	cmp	al,$P_nval_None 	;AN000; no value list ?
	jne	$P_Value02		;AN000;

	mov	al,$P_Number		;AN000; Set type
	mov	ah,$P_No_Tag		;AN000; No ITEM_TAG set
	jmp	$P_Value_Exit		;AN000;

$P_Value02:				;AN000; / nval = 1
IF	Val1SW				;AN000;(Check if value list id #1 is supported)
;(tm07) cmp	al,$P_nval_Range	;AN000; have range list ?
;(tm07) jne	$P_Value03		;AN000;

	inc	si			;AN000;
	mov	al,es:[si]		;AN000; al = number of range
	cmp	al,$P_No_nrng		;AN000; (tm07)
	je	$P_Value03		;AN000; (tm07)

	inc	si			;AN000; si points to 1st item_tag
$P_Val02_Loop:				;AN000;
	test	psdata_seg:$P_Flags2,$P_Signed ;AC034;
	jne	$P_Val02_Sign		;AN000;

	cmp	cx,es:[si+$P_Val_XH]	;AN000; comp cx with XH
	jb	$P_Val02_Next		;AN000;

	ja	$P_Val_In		;AN000;

	cmp	dx,es:[si+$P_Val_XL]	;AN000; comp dx with XL
	jb	$P_Val02_Next		;AN000;

$P_Val_In:				;AN000;
;;;;;;	cmp	cx,es:$P_Val_YH]	; comp cx with YH (tm01)
	cmp	cx,es:[si+$P_Val_YH]	;AN000; comp cx with YH (tm01)
	ja	$P_Val02_Next		;AN000;

	jb	$P_Val_Found		;AN000;

	cmp	dx,es:[si+$P_Val_YL]	;AN000; comp dx with YL
	ja	$P_Val02_Next		;AN000;

	jmp	short $P_Val_Found	;AN000;

$P_Val02_Sign:				;AN000;
	cmp	cx,es:[si+$P_Val_XH]	;AN000; comp cx with XH
	jl	$P_Val02_Next		;AN000;

	jg	$P_SVal_In		;AN000;

	cmp	dx,es:[si+$P_Val_XL]	;AN000; comp dx with XL
	jl	$P_Val02_Next		;AN000;

$P_SVal_In:				;AN000;
	cmp	cx,es:[si+$P_Val_YH]	;AN000; comp cx with YH
	jg	$P_Val02_Next		;AN000;

	jl	$P_Val_Found		;AN000;

	cmp	dx,es:[si+$P_Val_YL]	;AN000; comp dx with YL
	jg	$P_Val02_Next		;AN000;

	jmp	short $P_Val_Found	;AN000;

$P_Val02_Next:				;AN000;
	add	si,$P_Len_Range 	;AN000;
	dec	al			;AN000; loop nrng times in AL
	jne	$P_Val02_Loop		;AN000;
					; / Not found
	mov	psdata_seg:$P_RC,$P_Out_of_Range ;AC034;
	mov	al,$P_Number		;AN000;
	mov	ah,$P_No_Tag		;AN000; No ITEM_TAG set
	jmp	short $P_Value_Exit	;AN000;

ENDIF					;AN000;(of Val1SW)
IF	Val1SW+Val2SW			;AN000;(Check if value list id #1 or #2 is supported)
$P_Val_Found:				;AN000;
	mov	al,$P_Number		;AN000;
	mov	ah,es:[si]		;AN000; found ITEM_TAG set
	jmp	short $P_Value_Exit	;AN000;

ENDIF					;AN000;(of Val1SW+Val2SW)
$P_Value03:				;AN000; / nval = 2
IF	Val2SW				;AN000;(Check if value list id #2 is supported)
;;;;	cmp	al,$P_nval_Value	; have match list ? ASSUME nval=2,
;;;;	jne	$P_Value04		; even if it is 3 or more.
;(tm07) inc	si			;AN000;
;(tm07) mov	al,es:[si]		;AN000; al = nrng
	mov	ah,$P_Len_Range 	;AN000;
	mul	ah			;AN000;  Skip nrng field
	inc	ax			;AN000;
	add	si,ax			;AN000; si points to nnval
	mov	al,es:[si]		;AN000; get nnval
	inc	si			;AN000; si points to 1st item_tag
$P_Val03_Loop:				;AN000;
	cmp	cx,es:[si+$P_Val_XH]	;AN000; comp cx with XH
	jne	$P_Val03_Next		;AN000;

	cmp	dx,es:[si+$P_Val_XL]	;AN000; comp dx with XL
	je	$P_Val_Found		;AN000;

$P_Val03_Next:				;AN000;
	add	si,$P_Len_Value 	;AN000; points to next value choice
	dec	al			;AN000; loop nval times in AL
	jne	$P_Val03_Loop		;AN000;
					;AN000; / Not found
	mov	psdata_seg:$P_RC,$P_Not_in_Val ;AC034;
	mov	al,$P_Number		;AN000;
	mov	ah,$P_No_Tag		;AN000; No ITEM_TAG set
	jmp	short $P_Value_Exit	;AN000;

ENDIF					;AN000;(of Val2SW)
$P_Value04:				;AN000; / nval = 3 or else
$P_Value_Err:				;AN000;
	mov	psdata_seg:$P_RC,$P_Syntax ;AC034;
	mov	al,$P_String		;AN000; Set type
	mov	ah,$P_No_Tag		;AN000; No ITEM_TAG set
$P_Value_Exit:				;AN000;
	call	$P_Fill_Result		;AN000;
	pop	si			;AN000;
	pop	dx			;AN000;
	pop	cx			;AN000;
	pop	ax			;AN000;
	ret				;AN000;
$P_Value endp				;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Check_OVF
;
; Function:  Check if overflow is occurred with consideration of
;	     signed or un-signed numeric value
;
; Input:     Flag register
;
; Output:    CY = 1  :	Overflow
;
; Vars:     $P_Flags(R)
;***********************************************************************
$P_Check_OVF proc			;AN000;
	pushf				;AN000;
	test	psdata_seg:$P_Flags2,$P_Neg ;AC034; is it negative value ?
	jne	$P_COVF 		;AN000; if no, check overflow

	popf				;AN000; by the CY bit
	ret				;AN000;

$P_COVF:				;AN000;
	popf				;AN000; else,
	jo	$P_COVF00		;AN000; check overflow by the OF

	clc				;AN000; indicate it with CY bit
	ret				;AN000; CY=0 means no overflow

$P_COVF00:				;AN000;
	stc				;AN000; and CY=1 means overflow
	ret				;AN000;
$P_Check_OVF endp			;AN000;
ENDIF					;AN000;(of FarSW)
;***********************************************************************
; $P_0099;
;
; Function:  Make ASCII 0-9 to Binary 0-9
;
; Input:     AL = character code
;
; Output:    CY = 1 : AL is not number
;	     CY = 0 : AL contains binary value
;***********************************************************************
$P_0099 proc				;AN000;
	cmp	al,"0"                  ;AN000;
	jb	$P_0099Err		;AN000;  must be 0 =< al =< 9

	cmp	al,"9"                  ;AN000;
	ja	$P_0099Err		;AN000;  must be 0 =< al =< 9

	sub	al,"0"                  ;AN000; make char -> bin
	clc				;AN000; indicate no error
	ret				;AN000;

$P_0099Err:				;AN000;
	stc				;AN000; indicate error
	ret				;AN000;
$P_0099 endp				;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Simple_String
;
; Function:  See value list for the simple string
;	     and make result buffer.
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;	     ES:BX -> CONTROL block
;
; Output:    None
;
; Use:	$P_Fill_Result, $P_String_Comp
;
; Vars: $P_RC(W)
;***********************************************************************
$P_Simple_String proc			;AN000;
	push	ax			;AN000;
	push	bx			;AN000;
	push	dx			;AN000;
	push	di			;AN000;
	mov	di,es:[bx].$P_Value_List ;AN000; di points to value list
	mov	al,es:[di]		;AN000; get nval
	or	al,al			;AN000; no value list ?
	jne	$P_Sim00		;AN000; then

	mov	ah,$P_No_Tag		;AN000; No ITEM_TAG set
	jmp	short $P_Sim_Exit	;AN000; and set result buffer

$P_Sim00:				;AN000;
IF	Val3SW+KeySW			;AN000;(Check if keyword or value list id #3 is supported)
	cmp	al,$P_nval_String	;AN000; String choice list provided ?
	jne	$P_Sim01		;AN000; if no, syntax error

	inc	di			;AN000;
	mov	al,es:[di]		;AN000; al = nrng
	mov	ah,$P_Len_Range 	;AN000;
	mul	ah			;AN000;  Skip nrng field
	inc	ax			;AN000; ax = (nrng*9)+1
	add	di,ax			;AN000; di points to nnval
	mov	al,es:[di]		;AN000; get nnval
	mov	ah,$P_Len_Value 	;AN000;
	mul	ah			;AN000; Skip nnval field
	inc	ax			;AN000; ax = (nnval*5)+1
	add	di,ax			;AN000; di points to nstrval
	mov	al,es:[di]		;AN000; get nstrval
	inc	di			;AC035; add '2' to
	inc	di			;AC035;  DI reg
					;AN000; di points to 1st string in list
;(replaced ;AC035;) add     di,2	;AN000; di points to 1st string in list
$P_Sim_Loop:				;AN000;
	mov	bp,es:[di]		;AN000; get string pointer
	call	$P_String_Comp		;AN000; compare it with operand
	jnc	$P_Sim_Found		;AN000; found on list ?

	add	di,$P_Len_String	;AN000; if no, point to next choice
	dec	al			;AN000; loop nstval times in AL
	jne	$P_Sim_Loop		;AN000;
					;AN000; / Not found
	mov	psdata_seg:$P_RC,$P_Not_In_Str ;AC034;
	mov	ah,$P_No_Tag		;AN000; No ITEM_TAG set
	jmp	short $P_Sim_Exit	;AN000;

$P_Sim_Found:				;AN000;
	mov	ah,es:[di-1]		;AN000; set item_tag
	mov	al,$P_List_Idx		;AN000;
	mov	dx,es:[di]		;AN000; get address of STRING
	jmp	short $P_Sim_Exit0	;AN000;
ENDIF					;AN000;(of Val3SW+KeySW)
$P_Sim01:				;AN000;
	mov	psdata_seg:$P_RC,$P_Syntax ;AC034;
	mov	ah,$P_No_Tag		;AN000; No ITEM_TAG set
$P_Sim_Exit:				;AN000;
	mov	al,$P_String		;AN000; Set type
$P_Sim_Exit0:				;AN000;
	call	$P_Fill_Result		;AN000;
	pop	di			;AN000;
	pop	dx			;AN000;
	pop	bx			;AN000;
	pop	ax			;AN000;
	ret				;AN000;
$P_Simple_String endp			;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_String_Comp:
;
; Function:  Compare two string
;
; Input:     psdata_seg:SI -> 1st string
;	     ES:BP -> 2nd string  (Must be upper case)
;	     ES:BX -> CONTROL block
;
; Output:    CY = 1 if not match
;
; Use:	$P_Chk_DBCS, $P_Do_CAPS_Char
;
; Vars: $P_KEYor_SW_Ptr(W), $P_Flags(R). $P_KEYorSW_Ptr
;***********************************************************************
$P_String_Comp proc			;AN000;
	push	ax			;AN000;
	push	bp			;AN000;
	push	dx			;AN000;
	push	si			;AN000;
	mov	dl,$P_DOSTBL_Char	;AN000; use character case map table
$P_SCOM_Loop:				;AN000;
	mov	al,psdata_seg:[si]	;AN000; get command character
	call	$P_Chk_DBCS		;AN000; DBCS ?
	jc	$P_SCOM00		;AN000; yes,DBCS

	call	$P_Do_CAPS_Char 	;AN000; else, upper case map before comparison
IF	KeySW+SwSW			;AN000;(Check if keyword or switch is supported)
	test	psdata_seg:$P_Flags2,$P_Key_Cmp ;AC034; keyword search ?
	je	$P_SCOM04		;AN000;

	cmp	al,$P_Keyword		;AN000; "=" is delimiter
	jne	$P_SCOM03		;AN000;IF "=" on command line AND  (bp+1=> char after the "=" in synonym list)

	cmp	byte ptr es:[bp+1],$P_NULL ;AN021;   at end of keyword string in the control block THEN
	jne	$P_SCOM_DIFFER		;AN021;

	jmp	short $P_SCOM05 	;AN000;   keyword found in synonym list

$P_SCOM04:				;AN000;
	test	psdata_seg:$P_Flags2,$P_SW_Cmp ;AC034; switch search ?
	je	$P_SCOM03		;AN000;

	cmp	al,$P_Colon		;AN000; ":" is delimiter, at end of switch on command line
	jne	$P_SCOM03		;AN000; continue compares

	cmp	byte ptr es:[bp],$P_NULL ;AN021; IF at end of switch on command AND
	jne	$P_SCOM_DIFFER		;AN021;   at end of switch string in the control block THEN

$P_SCOM05:				;AN000;   found a match
	inc	si			;AN000; si points to just after "=" or ":"
	jmp	short $P_SCOM_Same	;AN000; exit

$P_SCOM03:				;AN000;
ENDIF					;AN000;(of KeySW+SwSW)
	cmp	al,es:[bp]		;AN000; compare operand w/ a synonym
	jne	$P_SCOM_Differ0 	;AN000; if different, check ignore colon option

	or	al,al			;AN000; end of line
	je	$P_SCOM_Same		;AN000; if so, exit

	inc	si			;AN000; update operand pointer
	inc	bp			;AN000; 	   and synonym pointer
	jmp	short $P_SCOM01 	;AN000; loop until NULL or "=" or ":" found in case

$P_SCOM00:				;AN000; Here al is DBCS leading byte
	cmp	al,es:[bp]		;AN000; compare leading byte
	jne	$P_SCOM_Differ		;AN000; if not match, say different

	inc	si			;AN000; else, load next byte
	mov	al,psdata_seg:[si]	;AN000; and
	inc	bp			;AN000;
	cmp	al,es:[bp]		;AN000; compare 2nd byte
	jne	$P_SCOM_Differ		;AN000; if not match, say different, too

	inc	si			;AN000; else update operand pointer
	inc	bp			;AN000; 		and synonym pointer
$P_SCOM01:				;AN000;
	jmp	short $P_SCOM_Loop	;AN000; loop until NULL or "=" or "/" found in case

$P_SCOM_Differ0:			;AN000;

IF	SwSW				;AN000;(tm10)
	test	psdata_seg:$P_Flags2,$P_SW ;AC034;(tm10)
	je	$P_not_applicable	;AN000;(tm10)

	test	es:[bx].$P_Function_Flag,$P_colon_is_not_necessary ;AN000;(tm10)
	je	$P_not_applicable	;AN000;(tm10)

	cmp	byte ptr es:[bp],$P_NULL ;AN000;(tm10)
;(deleted ;AN025;) jne $P_not_applicable ;AN000;(tm10)
	je	$P_SCOM_Same		;AN025;(tm10)

$P_not_applicable:			;AN000;(tm10)
ENDIF					;AN000;(tm10)

	test	es:[bx].$P_Match_Flag,$P_Ig_Colon ;AN000; ignore colon option specified ?
	je	$P_SCOM_Differ		;AN000; if no, say different.

	cmp	al,$P_Colon		;AN000; End up with ":" and
	jne	$P_SCOM02		;AN000;    subseqently

	cmp	byte ptr es:[bp],$P_NULL ;AN000;       NULL ?
	jne	$P_SCOM_Differ		;AN000; if no, say different

	jmp	short $p_SCOM_Same	;AN000; else, say same

$P_SCOM02:				;AN000;
	cmp	al,$P_NULL		;AN000; end up NULL and :
	jne	$P_SCOM_Differ		;AN000;

	cmp	byte ptr es:[bp],$P_Colon ;AN000; if no, say different
	je	$p_SCOM_Same		;AN000; else, say same

$P_SCOM_Differ: 			;AN000;
	stc				;AN000; indicate not found
	jmp	short $P_SCOM_Exit	;AN000;

$P_SCOM_Same:				;AN000;
	mov	psdata_seg:$P_KEYorSW_Ptr,si ;AC034; for later use by keyword or switch
	clc				;AN000; indicate found
$P_SCOM_Exit:				;AN000;
	pop	si			;AN000;
	pop	dx			;AN000;
	pop	bp			;AN000;
	pop	ax			;AN000;
	ret				;AN000;
$P_String_Comp endp			;AN000;
PAGE					;AN000;
;***********************************************************************
IF	DateSW				;AN000;(Check if date format is supported)
; $P_Date_Format
;
; Function:  Convert a date string to DOS date format for int 21h
;	     with format validation.
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;	     ES:BX -> CONTROL block
;
; Output:    None
;
; Use:	$P_Fill_Result, $P_Set_CDI, $P_Get_DecNum
;
; Vars: $P_RC(W), $P_1st_Val(RW), $P_2nd_Val(RW), $P_3rd_Val(RW)
;***********************************************************************
$P_Date_Format proc			;AN000;
	push	ax			;AN000;
	push	cx			;AN000;
	push	dx			;AN000;
	push	si			;AN000;
	push	bx			;AN000;
	push	si			;AN000;
	call	$P_Set_CDI		;AN000; set country dependent information before process
;	mov	bl,psdata_seg:[si].$P_CDI_DateS ;load date separator ;AN020; (deleted)
;					note: the country info is still needed
;					to determine the order of the fields,
;					but the separator char is no longer used.
	pop	si			;AN000;
	mov	psdata_seg:$P_1st_Val,0 ;AC034; set initial value
	mov	psdata_seg:$P_2nd_Val,0 ;AC034; set initial value
	mov	psdata_seg:$P_3rd_Val,0 ;AC034; set initial value
	call	$P_Get_DecNum		;AN000; get 1st number
	jc	$P_DateF_Err0		;AN000;-----------------------+

	mov	psdata_seg:$P_1st_Val,ax ;AC034;	      |
	or	bl,bl			;AN000; end of line ?	      |
	je	$P_DateF_YMD		;AN000; 		      |

	call	$P_Get_DecNum		;AN000; get 2nd number	      |
	jc	$P_DateF_Error		;AN000; 		      |

	mov	psdata_seg:$P_2nd_Val,ax ;AC034;	      |
	or	bl,bl			;AN000; end of line ?	      |
	je	$P_DateF_YMD		;AN000; 		      |

	call	$P_Get_DecNum		;AN000; get 3rd number	      |
$P_DateF_Err0:				;AN000; Bridge	  <-----------+
	jc	$P_DateF_Error		;AN000;

	mov	psdata_seg:$P_3rd_Val,ax ;AC034;
	or	bl,bl			;AN000; end of line ?
	jne	$P_DateF_Error		;AN000;

$P_DateF_YMD:				;AN000;
	mov	bx,psdata_seg:$P_Country_Info.$P_CDI_DateF ;AC034; get date format
	cmp	bx,$P_Date_YMD		;AN000;
	je	$P_DateF00		;AN000;

	mov	ax,psdata_seg:$P_1st_Val ;AC034;
	or	ah,ah			;AN000;
	jne	$P_DateF_Error		;AN000;

	mov	cl,al			;AN000; set month
	mov	ax,psdata_seg:$P_2nd_Val ;AC034;
	or	ah,ah			;AN000; if overflow, error.
	jne	$P_DateF_Error		;AN000;

	mov	ch,al			;AN000; set date
	mov	dx,psdata_seg:$P_3rd_Val ;AC034; set year
	cmp	bx,$P_Date_DMY		;AN000; from here format = MDY
	jne	$P_DateF01		;AN000; if it is DMY

	xchg	ch,cl			;AN000;  then swap M <-> D
$P_DateF01:				;AN000;
	jmp	short $P_DateF02	;AN000;

$P_DateF00:				;AN000; / here format = YMD
	mov	dx,psdata_seg:$P_1st_Val ;AC034; set year
	mov	ax,psdata_seg:$P_2nd_Val ;AC034;
	or	ah,ah			;AN000; if overflow, error
	jne	$P_DateF_Error		;AN000;

	mov	cl,al			;AN000; set month
	mov	ax,psdata_seg:$P_3rd_Val ;AC034;
	or	ah,ah			;AN000; if overflow, error
	jne	$P_DateF_Error		;AN000;

	mov	ch,al			;AN000; set date
$P_DateF02:				;AN000;
	cmp	dx,100			;AN000; year is less that 100 ?
	jae	$P_DateF03		;AN000;

	add	dx,1900 		;AN000; set year 19xx
$P_DateF03:				;AN000;
	pop	bx			;AN000; recover CONTROL block
	pop	si			;AN000; recover string pointer
	mov	ah,$P_No_Tag		;AN000; set
	mov	al,$P_Date_F		;AN000;     result
	call	$P_Fill_Result		;AN000; 	   buffer
	jmp	short $P_Date_Format_Exit ;AN000;	to Date

$P_DateF_Error: 			;AN000;
	pop	bx			;AN000; recover CONTROL block
	pop	si			;AN000; recover string pointer
	mov	ah,$P_No_Tag		;AN000; set
	mov	al,$P_String		;AN000;     result
	call	$P_Fill_Result		;AN000; 	   buffer  to string
	mov	psdata_seg:$P_RC,$P_Syntax ;AC034; indicate syntax error
$P_Date_Format_Exit:			;AN000;
	pop	dx			;AN000;
	pop	cx			;AN000;
	pop	ax			;AN000;
	ret				;AN000;
$P_Date_Format endp			;AN000;
ENDIF					;AN000;(of DateSW)
PAGE					;AN000;
;***********************************************************************
IF	TimeSW+DateSW			;AN000;(Check if time or date format is supported)
; $P_Set_CDI:
;
; Function: Read CDI from DOS if it has not been read yet
;
; Input:    None
;
; Output:   psdata_seg:SI -> CDI
;
; Use:	INT 21h w/ AH = 38h
;***********************************************************************
$P_Set_CDI proc 			;AN000;
	lea	si,psdata_seg:$P_Country_Info ;AC034;
	cmp	psdata_seg:[si].$P_CDI_DateF,$P_NeedToBeRead ;AN000; already read ?
	je	$P_Read_CDI		;AN000;

	jmp	short $P_Set_CDI_Exit	;AN000; then do nothing

$P_Read_CDI:				;AN000; else read CDI thru DOS
	push	ds			;AN000;
	push	dx			;AN000;
	push	ax			;AN000;
	push	PSDATA_SEG		;AC023;
	pop	ds			;AN000; set segment register
	mov	ax,$P_DOS_Get_CDI	;AN000; get country information
	mov	dx,si			;AN000; set offset of CDI in local data area
	int	21h			;AN000;
	pop	ax			;AN000;
	pop	dx			;AN000;
	pop	ds			;AN000;
$P_Set_CDI_Exit:			;AN000;
	ret				;AN000;
$P_Set_CDI endp 			;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Get_DecNum:
;
; Function:  Read a chcrater code from psdata_seg:SI until specified delimiter
;	     or NULL encountered. And make a decimal number.
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;
; Output:    BL = delimiter code or NULL
;	     AX = Decimal number
;	     SI advanced to the next number
;	     CY = 1 : Syntax error, AL = Latest examineed number
;
; Use:	$P_0099
;***********************************************************************
$P_Get_DecNum proc			;AN000;
	push	cx			;AN000;
	push	dx			;AN000;
	xor	cx,cx			;AN000; cx will have final value
$P_GetNum_Loop: 			;AN000;
	mov	al,psdata_seg:[si]	;AN000; load character
	or	al,al			;AN000; end of line ?
	je	$P_GetNum00		;AN000; if yes, exit

	cmp	psdata_seg:$P_Got_Time,0 ;AC034; ;is this numeric in a time field?    ;AC023
	je	$P_Do_Date_Delims	;AN000;no, go check out Date delimiters  ;AC023

; Determine which delimiter(s) to check for.  Colon & period  or period only
	cmp	bl,$P_colon_period	;AN032; ;Time
	jne	$P_Do_Time_Delim1	;AN032; ;only check for period

	cmp	al,$P_Colon		;AN032; ;Is this a valid delimiter ?
	je	$P_GetNum01		;AN032; ;yes, exit

$P_Do_Time_Delim1:			;AN000;
	cmp	al,$P_Period		;;AC032;;AC023;Is this a valid delimiter ?
	je	$P_GetNum01		;AC023; yes, exit

	jmp	short $P_Neither_Delims ;AN023;

$P_Do_Date_Delims:			;AN000;
;Regardless of the date delimiter character specified in the country
;dependent information, check for the presence of any one of these
;three field delimiters: "-", "/", or ".".
	cmp	al,$P_Minus		;AN020;is this a date delimiter character?
	je	$P_GetNum01		;AN020;if yes, exit

	cmp	al,$P_Slash		;AN020;is this a date delimiter character?
	je	$P_GetNum01		;AN020;if yes, exit

	cmp	al,$P_Period		;AN020;is this a date delimiter character?
	je	$P_GetNum01		;AN000; if yes, exit

$P_Neither_Delims:			;AN023;

	call	$P_0099 		;AN000; convert it to binary
	jc	$P_GetNum_Exit		;AN000; if error exit

	mov	ah,0			;AN000;
	xchg	ax,cx			;AN000;
	mov	dx,10			;AN000;
	mul	dx			;AN000; ax = ax * 10
	or	dx,dx			;AN000; overflow
	jne	$P_GetNum02		;AN000; then exit

	add	ax,cx			;AN000;
	jc	$P_GetNum_Exit		;AN000;

	xchg	ax,cx			;AN000;
	inc	si			;AN000;
	jmp	short $P_GetNum_Loop	;AN000;

$P_GetNum00:				;AN000;
	mov	bl,al			;AN000; set bl to NULL
	clc				;AN000; indicate no error
	jmp	short $P_GetNum_Exit	;AN000;

$P_GetNum01:				;AN000;
	inc	si			;AN000; si points to next number
	clc				;AN000; indicate no error
	jmp	short $P_GetNum_Exit	;AN000;

$P_GetNum02:				;AN000;
	stc				;AN000; indicate error
$P_GetNum_Exit: 			;AN000;
	mov	ax,cx			;AN000;return value
	pop	dx			;AN000;
	pop	cx			;AN000;
	ret				;AN000;
$P_Get_DecNum endp			;AN000;
ENDIF					;AN000;(of TimeSW+DateSW)
PAGE					;AN000;
;***********************************************************************
IF	TimeSW				;AN000;(Check if time format is supported)
; $P_Time_Format
;
; Function:  Convert a time string to DOS time format for int 21h
;	     with format validation.
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;	     ES:BX -> CONTROL block
;
; Output:    None
;
; Use:	$P_Fill_Result, $P_Set_CDI, $P_Get_DecNum, $P_Time_2412
;
; Vars: $P_RC(W), $P_Flags(R), $P_1st_Val(RW), $P_2nd_Val(RW)
;	$P_3rd_Val(RW), $P_4th_Val(RW)
;***********************************************************************
$P_Time_Format proc			;AN000;
	push	ax			;AN000;
	push	cx			;AN000;
	push	dx			;AN000;
	push	si			;AN000;
	push	bx			;AN000;
	push	si			;AN000;
	call	$P_Set_CDI		;AN000; Set country independent
					; information before process
;(AN032; deleted)  mov	   bl,psdata_seg:[si].$P_CDI_TimeS ;load time separator
;(AN032; deleted)  mov	   bh,psdata_seg:[si].$P_CDI_Dec ;load decimal separator
	test	byte ptr psdata_seg:[si].$P_CDI_TimeF,1 ;AN000; 24 hour system
	pop	si			;AN000;
	jne	$P_TimeF00		;AN000; if no, means 12 hour system

	call	$P_Time_2412		;AN000; this routine handle "am" "pm"
$P_TimeF00:				;AN000;
	mov	psdata_seg:$P_1st_Val,0 ;AC034; set initial value
	mov	psdata_seg:$P_2nd_Val,0 ;AC034; set initial value
	mov	psdata_seg:$P_3rd_Val,0 ;AC034; set initial value
	mov	psdata_seg:$P_4th_Val,0 ;AC034; set initial value
	mov	psdata_seg:$P_Got_Time,1 ;AN023;AC034;; use time delimiter
	mov	bl,$P_colon_period	;AN032; flag, indicates use of
					; delimiters between hours,
					;  minutes,seconds
	call	$P_Get_DecNum		;AN000; get 1st number
	jc	$P_TimeF_Err0		;AN000;

	mov	psdata_seg:$P_1st_Val,ax ;AC034;
	or	bl,bl			;AN000; end of line ?
	je	$P_TimeF_Rlt		;AN000;

	call	$P_Get_DecNum		;AN000; get 2nd number
	jc	$P_TimeF_Err0		;AC038; if OK

	mov	psdata_seg:$P_2nd_Val,ax ;AC034;
	or	bl,bl			;AN000; end of line ?
	je	$P_TimeF_Rlt		;AN000;

;(;AN032; deleted) mov	   bl,bh		   ;set decimal separator
	mov	bl,$P_period_only	;AN032; flag, which to decimal separator
	call	$P_Get_DecNum		;AN000; get 3rd number
	jc	$P_TimeF_Err0		;AC039; if problem, bridge to error

	mov	psdata_seg:$P_3rd_Val,ax ;AC034;
	or	bl,bl			;AN000; end of line ?
;(DELETED ;AN039;)  je $P_TimeF_Rlt	;AN000;
	jne	$P_Time_4		;AN039; NOT END OF LINE,
					;AN039;   GO TO 4TH NUMBER
	test	psdata_seg:$P_Flags1,$P_Time_Again ;AN039; HAS TIME PARSE
					;AN039;    BEEN REPEATED?
	jnz	$P_TimeF_Rlt		;AN039; yes, this is really
					;AN039;   the end of line
					;AN039; no, time has not been repeated
	mov	si,psdata_seg:$P_SI_Save ;AN039; get where parser quit
					 ;AN039;   in command line
	cmp	byte ptr [si-1],$P_Comma ;AN039; look at delimiter
					;AN039;   from command line
	jne	$P_TimeF_Rlt		;AN039; was not a comma, this is
					;AN039;  really end of line
					;AN039; is comma before hundredths,
					;AN039;   redo TIME
	mov	byte ptr [si-1],$P_Period ;AN039; change that ambiguous
					;AN039;    comma to a decimal point
					;AN039;     parse can understand
	mov	psdata_seg:$P_Flags,0	;AN039; Clear all internal flags
	or	psdata_seg:$P_Flags1,$P_Time_Again ;AN039; indicate TIME
					;AN039; is being repeated
	mov	cx,psdata_seg:$P_ORIG_ORD ;AN039; ORIGINAL ORDINAL FROM CX
	mov	sp,psdata_seg:$P_ORIG_STACK ;AN039; ORIGINAL VALUE
					 ;AN039;   OF STACK FROM SP
	mov	si,psdata_seg:$P_ORIG_SI ;AN039; ORIGINAL START
					 ;AN039;   PARSE POINTER FROM SI
	jmp	$P_Redo_Time		;AN039; go try TIME again
; ===============================================================
$P_Time_4:				;AN039; READY FOR 4TH (HUNDREDTHS) NUMBER
	call	$P_Get_DecNum		;AN000; get 4th number
$P_TimeF_Err0:				;AN000; Bridge
	jc	$P_TimeF_Error		;AN000;

	mov	psdata_seg:$P_4th_Val,ax ;AC034;
	or	bl,bl			;AN000; After hundredth, no data allowed
	jne	$P_TimeF_Error		;AN000; if some, then error

$P_TimeF_RLT:				;AN000;
	mov	ax,psdata_seg:$P_1st_Val ;AC034;
	or	ah,ah			;AN000; if overflow then error
	jne	$P_TimeF_Err		;AN000;

	test	psdata_seg:$P_Flags1,$P_Time12am ;AN038;if "am" specified
	jz	$P_Time_notAM		;AN038;skip if no "AM" specified
					;since "AM" was specified,
	cmp	al,12			;AN038: if hour specified as later than noon
	ja	$P_TimeF_Err		;AN038; error if "AM" on more than noon
	jne	$P_Time_notAM		;AN038; for noon exactly,

	xor	al,al			;AN038; set hour = zero
$P_Time_notAM:				;AN038;
	test	psdata_seg:$P_Flags2,$P_Time12 ;AC034; if 12 hour system and pm is specified
	je	$P_TimeSkip00		;AN000; then

	cmp	al,12			;AN038; if 12:00 o'clock already
	je	$P_TimeSkip00		;AN038; it is PM already

	add	al,12			;AN000; add 12 hours to make it afternoon
	jc	$P_TimeF_Err		;AN000; if overflow then error

	cmp	al,24			;AN038; after adding 12, now cannot be >24
	ja	$P_TimeF_Err		;AN038; if too big, error

$P_TimeSkip00:				;AN000;
	mov	dl,al			;AN000; set hour
	mov	ax,psdata_seg:$P_2nd_Val ;AC034;
	or	ah,ah			;AN000; if overflow then error
	jne	$P_TimeF_Err		;AN000;

	mov	dh,al			;AN000; set minute
	mov	ax,psdata_seg:$P_3rd_Val ;AC034;
	or	ah,ah			;AN000; if overflow then error
	jne	$P_TimeF_Err		;AN000;

	mov	cl,al			;AN000; set second
	mov	ax,psdata_seg:$P_4th_Val ;AC034;
	or	ah,ah			;AN000; if overflow then error
	jne	$P_TimeF_Err		;AN000;

	mov	ch,al			;AN000; set hundredth
	pop	bx			;AN000; recover CONTROL block
	pop	si			;AN000; recover string pointer
	mov	ah,$P_No_Tag		;AN000; set
	mov	al,$P_Time_F		;AN000;    result
	call	$P_Fill_Result		;AN000; 	 buffer
	jmp	short $P_Time_Format_Exit ;AN000;    to time

$P_TimeF_Error: 			;AN000;
$P_TimeF_Err:				;AN000;
	pop	bx			;AN000; recover CONTROL block
	pop	si			;AN000; recover string pointer
	mov	ah,$P_No_Tag		;AN000; set
	mov	al,$P_String		;AN000;     result
	call	$P_Fill_Result		;AN000; 	  buffer to string
	mov	psdata_seg:$P_RC,$P_Syntax ;AC034; return syntax error
$P_Time_Format_Exit:			;AN000;
	mov	psdata_seg:$P_Got_Time,0 ;AN023;AC034;; finished with this time field
	pop	dx			;AN000;
	pop	cx			;AN000;
	pop	ax			;AN000;
	ret				;AN000;
$P_Time_Format endp			;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Time_2412:
;
; Function:  Remove "a", "p", "am", or "pm" from the end of stinrg
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;
; Output:    Set $P_Time12 flag when the string is terminated by "p"
;	     or "pm"
;
; Vars:  $P_Flags(W)
;***********************************************************************
$P_Time_2412 proc			;AN000;
	push	ax			;AN000;
	push	si			;AN000;
$P_T12_Loop:				;AN000;
	mov	al,psdata_seg:[si]	;AN000; Move
	inc	si			;AN000;     si
	or	al,al			;AN000;       to
	jne	$P_T12_Loop		;AN000; 	end of string

	mov	al,psdata_seg:[si-word] ;AN000; get char just before NULL
	or	al,$P_Make_Lower	;AN000; lower case map
	cmp	al,"p"                  ;AN000; only "p" of "pm" ?
	je	$P_T1200		;AN000;

	cmp	al,"a"                  ;AN000; only "a" of "am" ?
	je	$P_T1201		;AN000;

	cmp	al,"m"                  ;AN000; "m" of "am" or "pm"
	jne	$P_T12_Exit		;AN000;

	dec	si			;AN000;
	mov	al,psdata_seg:[si-word] ;AN000;
	or	al,$P_Make_lower	;AN000; lower case map
	cmp	al,"p"                  ;AN000; "p" of "pm" ?
	je	$P_T1200		;AN000;

	cmp	al,"a"                  ;AN000; "a" of "am" ?
	je	$P_T1201		;AN000; go process "a"

	jmp	short $P_T12_Exit	;AN000; no special chars found

$P_T1200:				;AN000; "P" found
	or	psdata_seg:$P_Flags2,$P_Time12 ;AC034; flag "PM" found
	jmp	short $P_Tclr_chr	;AN038; go clear the special char

$P_T1201:				;AN000; "A" found
	or	psdata_seg:$P_Flags1,$P_Time12AM ;AN038; flag "AM" found
$P_Tclr_chr:				;AN038;
	mov	byte ptr psdata_seg:[si-2],$P_NULL ;AN000; null out special char
$P_T12_Exit:				;AN000;
	pop	si			;AN000;
	pop	ax			;AN000;
	ret				;AN000;
$P_Time_2412 endp			;AN000;
ENDIF					;AN000;(of TimeSW)
PAGE					;AN000;
;***********************************************************************
IF	CmpxSW				;AN000;(Check if complex item is supported)
; $P_Complex_Format:
;
; Function:  Check if the input string is valid complex format.
;	     And set the result buffer.
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;	     ES:BX -> CONTROL block
;
; Output:    None
;
; Use:	$P_Fill_Result, $P_Chk_DBCS, $P_Chk_EOL, $P_Skip_Delim
;	$P_Quoted_str, $P_Chk_DSQuote
;
; Vars: $P_RC(W), $P_SI_Save(W), $P_SaveSI_Cmpx(R), $P_Save_EOB(R)
;***********************************************************************
$P_Complex_Format proc			;AN000;
	push	ax			;AN000;
	push	bx			;AN000;
	push	si			;AN000;
	mov	bx,psdata_seg:$P_SaveSI_Cmpx ;AC034; bx points to user buffer
	cmp	byte ptr [bx],$P_Lparen ;AN000; 1st char = left parentheses
	jne	$P_Cmpx_Err		;AN000;

	xor	ah,ah			;AN000; ah = parentheses counter
$P_Cmpx_Loop:				;AN000;
	mov	al,[bx] 		;AN000; load character from command buffer
	call	$P_Chk_EOL		;AN000; if it is one of EOL
	je	$P_CmpxErr0		;AN000; then error exit.

	cmp	al,$P_Lparen		;AN000; left parentheses ?
	jne	$P_Cmpx00		;AN000; then

	inc	ah			;AC035; add '1' to AH reg
					;AN000; increment parentheses counter
;(replaced ;AC035;) add     ah,1	;AN000; increment parentheses counter
	jc	$P_CmpxErr0		;AN000; if overflow, error
$P_Cmpx00:				;AN000;
	cmp	al,$P_Rparen		;AN000; right parentheses ?
	jne	$P_Cmpx01		;AN000; then

	dec	ah			;AC035; subtract '1' from AH reg
					;AN000; decrement parentheses counter
;(changed ;AC035;) sub	   ah,1 	;AN000; decrement parentheses counter
	jc	$P_CmpxErr0		;AN000; if overflow error

	je	$P_Cmpx03		;AN000; ok, valid complex

$P_Cmpx01:				;AN000;
;(deleted ;AN025;) call $P_Chk_DSQuote	;AN000; double or single quotation mark ? 3/17/KK
	cmp	al,$P_DQuote		;AN025; double quotation mark?
	jne	$P_Cmpx04		;AN000; 3/17/KK

	mov	psdata_seg:[si],al	;AN000; here quoted string is found in the complex list.
	inc	si			;AN000;
	inc	bx			;AN000; bx points to 2nd character
	call	$P_Quoted_Str		;AN000; skip pointers until closing of quoted string
	jc	$P_CmpxErr0		;AN000; if error in quoted string syntax then exit

	jmp	short $P_Cmpx05 	;AN000;

$P_Cmpx04:				;AN000;
	call	$P_Chk_DBCS		;AN000; was it a lead byte of DBCS ?
	jnc	$P_Cmpx02		;AN000;

	mov	psdata_seg:[si],al	;AN000; then store 1st byte
	inc	si			;AN000;
	inc	bx			;AN000;
	mov	al,[bx] 		;AN000; load 2nd byte
$P_Cmpx02:				;AN000;
	mov	psdata_seg:[si],al	;AN000; store SBCS or 2nd byte of DBCS
$P_Cmpx05:				;AN000;
	inc	si			;AN000;
	inc	bx			;AN000;
	jmp	short $P_Cmpx_Loop	;AN000; loop
;----					;AN000;
$P_Cmpx03:				;AN000;
	mov	byte ptr psdata_seg:[si],al ;AN000;
	mov	byte ptr psdata_seg:[si+byte],$P_NULL ;AN000;
	mov	byte ptr [bx],$P_NULL	;AN000; replace right parentheses with NULL
	mov	si,bx			;AN000; skip whitespaces
	inc	si			;AN000;     after
	call	$P_Skip_Delim		;AN000;        right parentheses
	mov	psdata_seg:$P_SI_Save,si ;AC034; save next pointer, SI
	jmp	short $P_Cmpx_Exit	;AN000;

$P_CmpxErr0:				;AN000;
	mov	si,psdata_seg:$P_Save_EOB ;AC034; if EOF encountered, restore
	mov	byte ptr psdata_seg:[si],$P_NULL ;AN000; EOB mark
$P_Cmpx_Err:				;AN000;
	mov	psdata_seg:$P_RC,$P_Syntax ;AC034;
$P_Cmpx_Exit:				;AN000;
	mov	ah,$P_No_Tag		;AN000;
	mov	al,$P_Complex		;AN000;
	pop	si			;AN000;
	pop	bx			;AN000;
	call	$P_Fill_Result		;AN000;
	pop	ax			;AN000;
	ret				;AN000;
$P_Complex_Format endp			;AN000;
ENDIF					;AN000;(of CpmxSW)
PAGE					;AN000;
;***********************************************************************
IF	QusSW				;AN000;(Check if quoted string is supported)
; $P_Quoted_Format:
;
; Function:  Check if the input string is valid quoted string format.
;	     And set the result buffer.
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;	     ES:BX -> CONTROL block
;
; Output:    None
;
; Use:	$P_Fill_Result, $P_Chk_DBCS, $P_Chk_EOL, $P_Skip_Delim
;	$P_Chk_DSQuote, $P_Quoted_Str
;
; Vars: $P_RC(W), $P_SI_Save(W), $P_SaveSI_Cmpx(R),$P_Save_EOB(R)
;***********************************************************************
$P_Quoted_Format proc			;AN000;
	push	ax			;AN000;
	push	bx			;AN000;
	push	si			;AN000;
	mov	bx,psdata_seg:$P_SaveSI_Cmpx ;AC034; bx points to user buffer
	mov	al,byte ptr [bx]	;AN000; get 1st character
;(deleted ;AN025;) call $P_Chk_DSQuote	;AN000; is it single or double quote ?
	cmp	al,$P_DQuote		;AN025; double quotation mark?
	jne	$P_Qus_Err		;AN000; if no, error

;	mov	psdata_seg:[si],al	;AN000; move it to internal buffer
;	inc	si			;AN000;
	inc	bx			;AN000; bx points to 2nd character
	call	$P_Quoted_Str		;AN000; skip pointers to the closing of quoted string
	jc	$P_Qus_Err0		;AN000; if invali quoted string syntax, exit

	mov	byte ptr psdata_seg:[si+byte],$P_NULL ;AN000; end up with NULL
	mov	si,bx			;AN000;
	inc	si			;AN000;
	call	$P_Skip_Delim		;AN000; skip whitespaces after closing quote
	mov	psdata_seg:$P_SI_Save,si ;AC034; save next pointer, SI
	jmp	short $P_Qus_Exit	;AN000;

$P_Qus_Err0:				;AN000;
	mov	si,psdata_seg:$P_Save_EOB ;AC034; if EOF encountered, restore
	mov	byte ptr psdata_seg:[si],$P_NULL ;AN000; EOB mark
$P_Qus_Err:				;AN000;AN000
	mov	psdata_seg:$P_RC,$P_Syntax ;AC034; indicate syntax error
$P_Qus_Exit:				;AN000;
	mov	ah,$P_No_Tag		;AN000; set
	mov	al,$P_Quoted_String	;AN000;    result
	pop	si			;AN000; 	 buffer
	pop	bx			;AN000; 	       to
	call	$P_Fill_Result		;AN000; 		 quoted string
	pop	ax			;AN000;
	ret				;AN000;
$P_Quoted_Format endp			;AN000;
ENDIF					;AN000;(of QusSW)
PAGE					;AN000;
;***********************************************************************
; $P_Chk_DSQuote;
;
; Function: Check if AL is double quotation or single quotation
;
; Input:    AL = byte to be examineed
;
; Output:   ZF on if AL is single or double quotetaion
;
; Vars:  $P_SorD_Quote(W)
;***********************************************************************
IF	QusSW+CmpxSW			;AN000;(Check if quoted string or complex item is supported)
;(deleted ;AN025;) $P_Chk_DSQuote proc			   ;
;(deleted ;AN025;)	   mov	   $P_SorD_Quote,$P_SQuote ; 3/17/87   assume single quote
;(deleted ;AN025;)	   cmp	   al,$P_DQuote 	   ; 1st char = double quotation ?
;(deleted ;AN025;)	   jne	   $P_CDSQ00		   ; 3/17/87
;(deleted ;AN025;)	   mov	   $P_SorD_Quote,al	   ; 3/17/87 set bigning w/ double quote
;(deleted ;AN025;)	   ret				   ; 3/17/87
;(deleted ;AN025;) $P_CDSQ00:				   ; 3/17/87
;(deleted ;AN025;)	   cmp	   al,$P_SQuote 	   ; 1st char = single quotation ?
;(deleted ;AN025;)	   ret				   ;
;(deleted ;AN025;) $P_Chk_DSQuote endp			   ;
    PAGE				;AN000;
;***********************************************************************
; $P_Quoted_Str:
;
; Function:  Copy chracacter from ES:BX to psdata_seg:SI until closing single
;	     (double) quotation found.
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;	     ES:BX -> Operand in command buffer
;
; Output:    CY on indicates EOF encounterd before closing quotation
;	     BX and SI
;
;
; Vars: $P_SorD_Quote(R)
;***********************************************************************
$P_Quoted_Str proc			;AN000;
	push	ax			;AN000;
$P_Qus_Loop:				;AN000;
	mov	ax,[bx] 		;AN000; 3/17/87
	call	$P_Chk_EOL		;AN000;
	je	$P_Qustr_Err0		;AN000;

;(deleted ;AN025;) cmp al,$P_SorD_Quote ;AN000; quotation ?   3/17/87
	cmp	al,$P_DQuote		;AN025; double quote?
	jne	$P_Qus00		;AN000;

;(deleted ;AN025;) cmp ah,$P_SorD_Quote ;AN000; contiguous quotation 3/17/87
	cmp	ah,$P_DQuote		;AN025; double quote?
	jne	$P_Qus02		;AN000;

;(deleted ;AN025:) mov word ptr psdata_seg:[si],ax ;AN000; 3/17/87
	mov	byte ptr psdata_seg:[si],al ;AN025; save one of the quotes
;(deleted ;AN025:) add si,2		;AN000;

	inc	si			;AC035; add '1' to SI reg
					;AN025; adjust target index
;(changed ;AC035;) add	   si,1 	;AN025; adjust target index
	inc	bx			;AC035; add '2' to
	inc	bx			;AC035;  BX reg
					;AN000; adjust source index by 2 to skip extra quote
;(changed ;AC035;) add	   bx,2 	;AN000; adjust source index by 2 to skip extra quote
	jmp	short $P_Qus_Loop	;AN000;

$P_Qus00:				;AN000;
	call	$P_Chk_DBCS		;AN000; was it a lead byte of DBCS ?
	jnc	$P_Qus01		;AN000;

	mov	psdata_seg:[si],al	;AN000; store 1st byte
	inc	si			;AN000;
	inc	bx			;AN000;
	mov	al,[bx] 		;AN000; load 2nd byte
$P_Qus01:				;AN000;
	mov	psdata_seg:[si],al	;AN000; store SBCS or 2nd byte of DBCS
	inc	si			;AN000;
	inc	bx			;AN000;
	jmp	short $P_Qus_Loop	;AN000;

$P_Qustr_Err0:				;AN000;
	stc				;AN000; indicate error
	jmp	short $P_Quoted_Str_Exit ;AN000;

$P_Qus02:				;AN000;
	mov	byte ptr psdata_seg:[si],0 ;AN000;
	clc				;AN000; indicate no error
$P_Quoted_Str_Exit:			;AN000;
	pop	ax			;AN000;
	ret				;AN000;
$P_Quoted_Str endp			;AN000;
ENDIF					;AN000;(of QusSW+CmpxSW)
PAGE					;AN000;
;***********************************************************************
IF	FileSW+DrvSW			;AN000;(Check if file spec or drive only is supported)
; $P_File_Format;
;
; Function:  Check if the input string is valid file spec format.
;	     And set the result buffer.
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;	     ES:BX -> CONTROL block
;
; Output:    None
;
; Use:	$P_Fill_Result, $P_Chk_DBCS, $P_FileSp_Chk
;
; Vars: $P_RC(W), $P_SI_Save(W), $P_Terminator(W), $P_SaveSI_Cmpx(R)
;	$P_SaveSI_Cmpx(R)
;***********************************************************************
$P_File_Format proc			;AN000;
	push	ax			;AN000;
	push	di			;AN000;
	push	si			;AN000;
	mov	di,psdata_seg:$P_SaveSI_cmpx ;AC034; get user buffer address
$P_FileF_Loop0: 			;AN000; / skip special characters
	mov	al,psdata_seg:[si]	;AN000; load character
	or	al,al			;AN000; end of line ?
	je	$P_FileF_Err		;AN000; if yes, error exit

	call	$P_FileSp_Chk		;AN000; else, check if file special character
	jne	$P_FileF03		;AN000; if yes,

;AN033; deleted   inc	  di			  ;skip
;AN033; deleted   inc	  si			  ;   the
;AN033; deleted   jmp	  short $P_FileF_Loop0	  ;	  character
	mov	psdata_seg:$P_err_flag,$P_error_filespec ;AN033;AC034;; set error flag- bad char.
	pop	si			;AN033;
	mov	byte ptr psdata_seg:[si],$P_NULL ;AN033;
	pop	di			;AN033;
	jmp	short $P_FileF02	;AN033;


$P_FileF_Err:				;AN000;
	pop	si			;AN000;
	mov	byte ptr psdata_seg:[si],$P_NULL ;AN000;
;(deleted ;AN030;) mov di,$P_SaveSI_cmpx ;AN000; get user buffer address
;(deleted ;AN030;) mov $P_SI_Save,di	 ;AN000; update pointer to user buffer
	pop	di			;AN000;
	test	es:[bx].$P_Match_Flag,$P_Optional ;AN000; is it optional ?
	jne	$P_FileF02		;AN000;

	mov	psdata_seg:$P_RC,$P_Op_Missing ;AC034; 3/17/87
	jmp	short $P_FileF02	;AN000;

$P_FileF03:				;AN000;
	pop	ax			;AN000; discard save si
	push	si			;AN000; save new si
$P_FileF_Loop1: 			;AN000;
	mov	al,psdata_seg:[si]	;AN000; load character (not special char)
	or	al,al			;AN000; end of line ?
	je	$P_FileF_RLT		;AN000;

	call	$P_FileSp_Chk		;AN000; File special character ?
	je	$P_FileF00		;AN000;

	call	$P_Chk_DBCS		;AN000; no, then DBCS ?
	jnc	$P_FileF01		;AN000;
	inc	di			;AN000; if yes, skip next byte
	inc	si			;AN000;
$P_FileF01:				;AN000;
	inc	di			;AN000;
	inc	si			;AN000;
	jmp	short $P_FileF_Loop1	;AN000;
;
$P_FileF00:				;AN000;
	mov	psdata_seg:$P_Terminator,al ;AC034;
	mov	byte ptr psdata_seg:[si],$P_NULL ;AN000; update end of string
	inc	di			;AN000;
	mov	psdata_seg:$P_SI_Save,di ;AC034; update next pointer in command line
$P_FileF_RLT:				;AN000;
	pop	si			;AN000;
	pop	di			;AN000;
$P_FileF02:				;AN000;

	pop	ax			;AN000; (tm14)
	test	ax,$P_File_Spc		;AN000; (tm14)
	je	$P_Drv_Only_Exit	;AN000; (tm14)

	push	ax			;AN000;  (tm14)

	mov	ah,$P_No_Tag		;AN000; set
	mov	al,$P_File_Spec 	;AN000;    result
	call	$P_Fill_Result		;AN000; 	 buffer to file spec
	pop	ax			;AN000;

$P_Drv_Only_Exit:			;AN000; (tm14)

	ret				;AN000;
$P_File_Format endp			;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_FileSp_Chk
;
; Function:  Check if the input byte is one of file special characters
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;	     AL = character code to be examineed
;
; Output:    ZF = 1 , AL is one of special characters
;***********************************************************************
$P_FileSp_Chk proc			;AN000;
	push	bx			;AN000;
	push	cx			;AN000;
	lea	bx,psdata_seg:$P_FileSp_Char ;AC034; special character table
	mov	cx,$P_FileSp_Len	;AN000; load length of it
$P_FileSp_Loop: 			;AN000;
	cmp	al,psdata_seg:[bx]	;AN000; is it one of special character ?
	je	$P_FileSp_Exit		;AN000;

	inc	bx			;AN000;
	loop	$P_FileSp_Loop		;AN000;

	inc	cx			;AN000; reset ZF
$P_FileSp_Exit: 			;AN000;
	pop	cx			;AN000;
	pop	bx			;AN000;
	ret				;AN000;
$P_FileSp_Chk endp			;AN000;
ENDIF					;AN000;(of FileSW+DrvSW)
PAGE					;AN000;
;***********************************************************************
IF	DrvSW				;AN000;(Check if drive only is supported)
; $P_Drive_Format;
;
; Function:  Check if the input string is valid drive only format.
;	     And set the result buffer.
;
; Input:     psdata_seg:SI -> $P_STRING_BUF
;	     ES:BX -> CONTROL block
;
; Output:    None
;
; Use:	$P_Fill_Result, $P_Chk_DBCS
;
; Vars: $P_RC(W)
;***********************************************************************
$P_Drive_Format proc			;AN000;
	push	ax			;AN000;
	push	dx			;AN000;
	mov	al,psdata_seg:[si]	;AN000;
	or	al,al			;AN000; if null string
	je	$P_Drv_Exit		;AN000; do nothing

	call	$P_Chk_DBCS		;AN000; is it leading byte ?
	jc	$P_Drv_Err		;AN000;

	cmp	word ptr psdata_seg:[si+byte],$P_Colon ;AN000; "d", ":", 0  ?
	je	$P_DrvF00		;AN000;

	test	es:[bx].$P_Match_Flag,$P_Ig_Colon ;AN000; colon can be ignored?
	je	$P_Drv_Err		;AN000;

	cmp	byte ptr psdata_seg:[si+byte],$P_NULL ;AN000; "d", 0  ?
	jne	$P_Drv_Err		;AN000;

$P_DrvF00:				;AN000;
	or	al,$P_Make_Lower	;AN000; lower case
	cmp	al,"a"                  ;AN000; drive letter must
	jb	$P_Drv_Err		;AN000; in range of

	cmp	al,"z"                  ;AN000; "a" - "z"
	ja	$P_Drv_Err		;AN000; if no, error

	sub	al,"a"-1                ;AN000; make text drive to binary drive
	mov	dl,al			;AN000; set
	mov	ah,$P_No_Tag		;AN000;    result
	mov	al,$P_Drive		;AN000; 	 buffer
	call	$P_Fill_Result		;AN000; 	       to drive
	jmp	short $P_Drv_Exit	;AN000;

$P_Drv_Err:				;AN000;
	mov	psdata_seg:$P_RC,$P_Syntax ;AC034;
$P_Drv_Exit:				;AN000;
	pop	dx			;AN000;
	pop	ax			;AN000;
	ret				;AN000;
$P_Drive_Format endp			;AN000;
ENDIF					;AN000;(of DrvSW)
PAGE					;AN000;
;***********************************************************************
; $P_Skip_Delim;
;
; Function: Skip delimiters specified in the PARMS list, white space
;	    and comma.
;
; Input:    DS:SI -> Command String
;	    ES:DI -> Parameter List
;
; Output:   CY = 1 if the end of line encounterd
;	    CY = 0 then SI move to 1st non-delimiter character
;	    AL = Last examineed character
;
; Use:	    $P_Chk_EOL, $P_Chk_Delim,
;
; Vars:     $P_Flags(R)
;***********************************************************************
$P_Skip_Delim proc			;AN000;
$P_Skip_Delim_Loop:			;AN000;
	LODSB				;AN000;
	call	$P_Chk_EOL		;AN000; is it EOL character ?
	je	$P_Skip_Delim_CY	;AN000; if yes, exit w/ CY on

	call	$P_Chk_Delim		;AN000; is it one of delimiters ?
	jne	$P_Skip_Delim_NCY	;AN000; if no, exit w/ CY off

	test	psdata_seg:$P_Flags2,$P_Extra ;AC034; extra delim or comma found ?
	je	$P_Skip_Delim_Loop	;AN000; if no, loop

	test	psdata_seg:$P_Flags2,$P_SW+$P_equ ;AC034; /x , or xxx=zzz , (tm08)
	je	short $P_Exit_At_Extra	;AN000; no switch, no keyword (tm08)

	dec	si			;AN000; backup si for next call (tm08)
	jmp	short $P_Exit_At_Extra	;AN000; else exit w/ CY off

$P_Skip_Delim_CY:			;AN000;
	stc				;AN000; indicate EOL
	jmp	short $P_Skip_Delim_Exit ;AN000;

$P_Skip_Delim_NCY:			;AN000;
	clc				;AN000; indicate non delim
$P_Skip_Delim_Exit:			;AN000; in this case, need
	dec	si			;AN000;  backup index pointer
	ret				;AN000;

$P_Exit_At_Extra:			;AN000;
	clc				;AN000; indicate extra delim
	ret				;AN000;
$P_Skip_Delim endp			;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Chk_EOL;
;
; Function: Check if AL is one of End of Line characters.
;
; Input:    AL = character code
;	    ES:DI -> Parameter List
;
; Output:   ZF = 1 if one of End of Line characters
;**********************************************************************
$P_Chk_EOL proc 			;AN000;
	push	bx			;AN000;
	push	cx			;AN000;
	cmp	al,$P_CR		;AN000; Carriage return ?
	je	$P_Chk_EOL_Exit 	;AN000;

	cmp	al,$P_NULL		;AN000; zero ?
	je	$P_Chk_EOL_Exit 	;AN000;

IF LFEOLSW				;AN028; IF LF TO BE ACCEPTED AS EOL
	cmp	al,$P_LF		;AN000; Line feed ?
	je	$P_Chk_EOL_Exit 	;AN000;
ENDIF					;AN028;

	cmp	byte ptr es:[di].$P_Num_Extra,$P_I_Have_EOL ;AN000; EOL character specified ?
	jb	$P_Chk_EOL_Exit 	;AN000;

	xor	bx,bx			;AN000;
	mov	bl,es:[di].$P_Len_Extra_Delim ;AN000; get length of delimiter list
	add	bx,$P_Len_PARMS 	;AN000; skip it
	cmp	byte ptr es:[bx+di],$P_I_Use_Default ;AN000; No extra EOL character ?
	je	$P_Chk_EOL_NZ		;AN000;

	xor	cx,cx			;AN000; Get number of extra chcracter
	mov	cl,es:[bx+di]		;AN000;
$P_Chk_EOL_Loop:			;AN000;
	inc	bx			;AN000;
	cmp	al,es:[bx+di]		;AN000; Check extra EOL character
	je	$P_Chk_EOL_Exit 	;AN000;

	loop	$P_Chk_EOL_Loop 	;AN000;

$P_Chk_EOL_NZ:				;AN000;
	cmp	al,$P_CR		;AN000; reset ZF
$P_Chk_EOL_Exit:			;AN000;
	pop	cx			;AN000;
	pop	bx			;AN000;
	ret				;AN000;
$P_Chk_EOL endp 			;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Chk_Delim;
;
; Function: Check if AL is one of delimiter characters.
;	    if AL+[si] is DBCS blank, it is replaced with two SBCS
;	    blanks.
;
; Input:    AL = character code
;	    DS:SI -> Next Character
;	    ES:DI -> Parameter List
;
; Output:   ZF = 1 if one of delimiter characters
;	    SI points to the next character
; Vars:  $P_Terminator(W), $P_Flags(W)
;***********************************************************************
$P_Chk_Delim proc			;AN000;
	push	bx			;AN000;
	push	cx			;AN000;
	mov	psdata_seg:$P_Terminator,$P_Space   ;AC034; Assume terminated by space
	and	psdata_seg:$P_Flags2,0ffh-$P_Extra ;AC034;
	cmp	al,$P_Space		;AN000; Space ?
	je	$P_Chk_Delim_Exit	;AN000;

	cmp	al,$P_TAB		;AN000; TAB ?
	je	$P_Chk_Delim_Exit	;AN000;

	cmp	al,$P_Comma		;AN000; Comma ?
	je	$P_Chk_Delim_Exit0	;AN000;

$P_Chk_Delim00: 			;AN000;
	cmp	al,$P_DBSP1		;AN000; 1st byte of DBCS Space ?
	jne	$P_Chk_Delim01		;AN000;

	cmp	byte ptr [si],$P_DBSP2	;AN000; 2nd byte of DBCS Space ?
	jne	$P_Chk_Delim01		;AN000;

	mov	al,$P_Space		;AN000;
	inc	si			;AN000; make si point to next character
	cmp	al,al			;AN000; Set ZF
	jmp	short $P_Chk_Delim_Exit ;AN000;

$P_Chk_Delim01: 			;AN000;
	cmp	byte ptr es:[di].$P_Num_Extra,$P_I_Have_Delim ;AN000; delimiter character specified ?
	jb	$P_Chk_Delim_Exit	;AN000;

	xor	cx,cx			;AN000;
	mov	cl,es:[di].$P_Len_Extra_Delim ;AN000; get length of delimiter list
	or	cx,cx			;AN000; No extra Delim character ?
	je	$P_Chk_Delim_NZ 	;AN000;

	mov	bx,$P_Len_PARMS-1	;AN000; set bx to 1st extra delimiter
$P_Chk_Delim_Loop:			;AN000;
	inc	bx			;AN000;
	cmp	al,es:[bx+di]		;AN000; Check extra Delim character
	je	$P_Chk_Delim_Exit0	;AN000;

	loop	$P_Chk_Delim_Loop	;AN000; examine all extra delimiter

$P_Chk_Delim_NZ:			;AN000;
	cmp	al,$P_Space		;AN000; reset ZF
$P_Chk_Delim_Exit:			;AN000;
;;;;	jne	$P_ChkDfin
;;;;	mov	psdata_seg:$P_Terminator,al ;AN034;
$P_ChkDfin:				;AN000;
	pop	cx			;AN000;
	pop	bx			;AN000;
	ret				;AN000;

$P_Chk_Delim_Exit0:			;AN000;
	mov	psdata_seg:$P_Terminator,al ;AC034; keep terminated delimiter
	test	psdata_seg:$P_Flags2,$P_Equ  ;AN027;AC034;; if terminating a key=
	jnz	$P_No_Set_Extra 	;AN027; then do not set the EXTRA bit

	or	psdata_seg:$P_Flags2,$P_Extra ;AC034; flag terminated extra delimiter or comma
$P_No_Set_Extra:			;AN027;
	cmp	al,al			;AN000; set ZF
	jmp	short $P_Chk_Delim_Exit ;AN000;

$P_Chk_Delim endp			;AN000;
PAGE					;AN000;
;***********************************************************************
; $P_Chk_Switch;
;
; Function: Check if AL is the switch character not in first position of
;	    $P_STRING_BUF
;
; Input:    AL = character code
;	    BX = current pointer within $P_String_Buf
;	    SI =>next char on command line (following the one in AL)
;
; Output:   CF = 1 (set)if AL is switch character, and not in first
;		 position, and has no chance of being part of a date string,
;		 i.e. should be treated as a delimiter.

;	    CF = 0 (reset, cleared) if AL is not a switch char, is in the first
;		 position, or is a slash but may be part of a date string, i.e.
;		 should not be treated as a delimiter.
;
; Vars:  $P_Terminator(W)

; Use:	 $P_0099
;***********************************************************************
$P_Chk_Switch proc			;AN000;

;AN020;; Function: Check if AL is the switch character from 2nd position of $P_STRING_BUF
;AN020;; Output:   ZF = 1 if switch character
;AN020;;	lea	bp,$P_STRING_BUF ;AN000;
;AN020;;	cmp	bx,bp		 ;AN000; 1st position ?
;AN020;;	je	$P_Chk_S_Exit_1  ;AN000;
;AN020;;	cmp	al,$P_Switch	 ;AN000;
;AN020;;	jmp	short $P_Chk_S_Exit_0  ;AN000;
;AN020;;$P_Chk_S_Exit_1:		       ;AN000;
;AN020;;	cmp	al,$P_Switch	 ;AN000; (tm08)
;AN020;;	jne	$P_Nop		;AN000; (tm08)
;AN020;;	or	$P_Flags2,$P_SW  ;AN000; (tm08) It could be valid switch
;AN020;;$P_Nop: 			;AN000; (tm08)
;AN020;;	inc	bp		       ;AN000;
;AN020;;	cmp	bx,bp		       ;AN000; reset ZF
;AN020;;$P_Chk_S_Exit_0:		       ;AN000;
;AN020;;	jne	$P_Chk_S_Exit	       ;AN000;
;AN020;;	mov	   $P_Terminator,al    ;AN000; store switch character
;AN020;;$P_Chk_S_Exit:			       ;AN000;

	LEA	BP,psdata_seg:$P_String_Buf ;AN020;AC034; BP=OFFSET of $P_String_Buf even in group addressing
;	.IF <BX NE BP> THEN		;AN020;IF not first char THEN
	cmp	BX,BP			;AN000;
	je	$P_STRUC_L2		;AN000;

;	    .IF <AL EQ $P_Switch> THEN	;AN020;otherwise see if a slash
	    cmp     AL,$P_Switch	;AN000;
	    jne     $P_STRUC_L5 	;AN000;

		STC			;AN020;not in first position and is slash, now see if might be in date string
IF	DateSw				;AN020;caller looking for date, see if this may be part of one
		PUSH	AX		;AN020;save input char
		MOV	AL,PSDATA_SEG:[BX-1] ;AN026;AL=char before the current char
		CALL	$P_0099 	;AN020;return carry set if not numeric
;		.IF   NC ;AND		;AN020;IF previous char numeric AND
		jc	$P_STRUC_L7	;AN000;

		    MOV     AL,[SI]	;AN020;AL=char after the current char
		    CALL    $P_0099	;AN020;return carry set if not numeric
;(deleted)	    .IF     NC THEN	;AN020;IF next char numeric THEN could be a date
;(deleted)		CLC		;AN020;reset CF so "/" not treated as a delimiter
;(deleted)	    .ENDIF		;AN026;
;		.ENDIF			;AN020;ENDIF looks like date (number/number)
$P_STRUC_L7:				;AN000;
		POP	AX		;AN020;restore AL to input char
ENDIF					;AN020;DateSw
;	    .ELSE			;AN020;
	    jmp     short $P_STRUC_L1	;AN000;

$P_STRUC_L5:				;AN000;
		CLC			;AN020;not a slash
;	    .ENDIF			;AN020;
;	.ELSE				;AN020;is first char in the buffer, ZF=0
	jmp	short $P_STRUC_L1	;AN000;

$P_STRUC_L2:				;AN000;
;	    .IF <AL EQ $P_Switch> THEN	;AN020;
	    cmp     AL,$P_Switch	;AN000;
	    jne     $P_STRUC_L12	;AN000;

		OR	psdata_seg:$P_Flags2,$P_SW ;AN020;AC034;;could be valid switch, first char and is slash
;	    .ENDIF			;AN020;
$P_STRUC_L12:				;AN000;
	    CLC 			;AN020;CF=0 indicating first char
;	.ENDIF				;AN020;
$P_STRUC_L1:				;AN000;

	ret				;AN000;
$P_Chk_Switch endp			;AN000;
	PAGE				;AN000;
;**************************************************************************
; $P_Chk_DBCS:
;
;  Function: Check if a specified byte is in ranges of the DBCS lead bytes
;
;  Input:
;	  AL	= Code to be examineed
;
;  Output:
;	  If CF is on then a lead byte of DBCS
;
; Use: INT 21h w/AH=63
;
; Vars:  $P_DBCSEV_Seg(RW), $P_DBCSEV_Off(RW)
;***************************************************************************
$P_Chk_DBCS PROC			;AN000;
;
	PUSH	DS			;AN000;
	PUSH	SI			;AN000;
	PUSH	bx			;AN000; (tm11)
	CMP	psdata_seg:$P_DBCSEV_SEG,0 ;AC034; ALREADY SET ?
	JNE	$P_DBCS00		;AN000;

	PUSH	AX			;AN000;
;	PUSH	BX			;AN000; (tm11)
	PUSH	ds			;AN000; (tm11)
	PUSH	CX			;AN000;
	PUSH	DX			;AN000;
	PUSH	DI			;AN000;
	PUSH	BP			;AN000;
	PUSH	ES			;AN000;
	XOR	SI,SI			;AN000;
	MOV	DS,SI			;AN000;
	MOV	AX,$P_DOS_GetEV 	;AN000; GET DBCS EV CALL
	INT	21H			;AN000;

;	MOV	AX,DS			;AN000; (tm11)
;	OR	AX,AX			;AN000; (tm11)
	MOV	bx,DS			;AN000; (tm11)
	OR	bx,bx			;AN000; (tm11)
	POP	ES			;AN000;
	POP	BP			;AN000;
	POP	DI			;AN000;
	POP	DX			;AN000;
	POP	CX			;AN000;
;	POP	BX			;AN000; (tm11)
	POP	ds			;AN000; (tm11)
	POP	AX			;AN000;
	JE	$P_NON_DBCS		;AN000;

$P_DBCS02:				;AN000;
	MOV	psdata_seg:$P_DBCSEV_OFF,SI ;AC034; save EV offset
;	MOV	psdata_seg:$P_DBCSEV_SEG,DS ;AC034; save EV segment
	MOV	psdata_seg:$P_DBCSEV_SEG,bx ;AC034; save EV segment (tm11)
$P_DBCS00:				;AN000;
	MOV	SI,psdata_seg:$P_DBCSEV_OFF ;AC034; load EV offset
	MOV	DS,psdata_seg:$P_DBCSEV_SEG ;AC034; and segment

$P_DBCS_LOOP:				;AN000;
	CMP	WORD PTR [SI],0 	;AN000; zero vector ?
	JE	$P_NON_DBCS		;AN000; then exit

	CMP	AL,[SI] 		;AN000;
	JB	$P_DBCS01		;AN000; Check if AL is in

	CMP	AL,[SI+BYTE]		;AN000;   range of
	JA	$P_DBCS01		;AN000;      the vector

	STC				;AN000; if yes, indicate DBCS and exit
	JMP	short $P_DBCS_EXIT	;AN000;

$P_DBCS01:				;AN000;
	INC	SI			;AC035; add '2' to
	INC	SI			;AC035;  SI reg
					;AN000; get next vector
;(changed ;AC035;) ADD	   SI,2 	;AN000; get next vector
	JMP	short $P_DBCS_LOOP	;AN000; loop until zero vector found

$P_NON_DBCS:				;AN000;
	CLC				;AN000; indicate SBCS
$P_DBCS_EXIT:				;AN000;
	POP	bx			;AN000; (tm11)
	POP	SI			;AN000;
	POP	DS			;AN000;
	RET				;AN000;
$P_Chk_DBCS ENDP			;AN000;
