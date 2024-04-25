
	PAGE	,132

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  FILENAME:		CPS Printer Device Driver INIT module (CPSPInn)
;;  MODULE NAME:
;;  TYPE:		Assemble file  (non-resident code)
;;  LINK PROCEDURE:	Link CPSPMnn+CPSFONT+CPSPInn into .EXE format. CPSPM01
;;			must be first.	CPSPInn must be last.  Everything
;;			before CPSPInn will be resident.
;;  INCLUDE FILES:
;;			CPSPEQU.INC
;;
;;  LAYOUT :		This file is divided into two main section :
;;			  ++++++++++++++++++++++++
;;			  ++	DEVICE Parser	++
;;			  ++++++++++++++++++++++++
;;
;;			  ++++++++++++++++++++++++
;;			  ++	INIT Command	++
;;			  ++++++++++++++++++++++++
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
INCLUDE CPSPEQU.INC			;;
					;;
PUBLIC	INIT				;;
PUBLIC	CODE_END			;; for MAP listing only
PUBLIC	RESIDENT_END			;;
PUBLIC	STACK_ALLOCATED 		;;
					;;
					;;
EXTRN	PRINTER_DESC_NUM:WORD		;;
EXTRN	PRINTER_DESC_TBL:WORD		;;
EXTRN	INIT_CHK:WORD,TABLE:WORD	;;
EXTRN	HARD_SL1:BYTE,RAM_SL1:BYTE	;;
EXTRN	HARD_SL2:BYTE,RAM_SL2:BYTE	;;
EXTRN	HARD_SL3:BYTE,RAM_SL3:BYTE	;;
EXTRN	HARD_SL4:BYTE,RAM_SL4:BYTE	;;
EXTRN	RESERVED1:WORD,RESERVED2:WORD	;;
					;;
EXTRN	MSG_NO_INIT_P:BYTE		;;
EXTRN	MSG_NO_INIT:BYTE		;;
EXTRN	MSG_BAD_SYNTAX:BYTE		;;
EXTRN	MSG_INSUFF_MEM:BYTE		;;
					;;
					;;
CSEG	SEGMENT PARA PUBLIC 'CODE'      ;;
	ASSUME	CS:CSEG 		;;
					;;
					;;
CODE_END     EQU $			;; end of resident code
					;;
	     DW  0			;; -- there are 16 bytes kept,
					;;    including this word
					;;
RESIDENT_END DW  0FFFH			;; end of extended resident area
STACK_ALLOCATED  DW -1			;; end of extended resident area
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	End of resident code
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Incorporating Device Command Parser :
;;
;; -- extracted from PARSE4E.ASM, size 49582 bytes
;;
;; (some modifications have to be made in the section right after the parser's
;;  document and before the GET_PARMS_A, one of them is :)
;;
;; -- move the TABLE to the printer device driver's main module
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;			  ++++++++++++++++++++++++
;;			  ++	DEVICE Parser	++
;;			  ++++++++++++++++++++++++
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;   PARSER's code -- non resident
;;
;;	-- set ES:[DI] pointing to the Request Header before calling PARSER
;;
;;	to be called as PARSER with ES:[DI] defined as Request Header
;;	If there is any syntax error in the DEVICE command line, the
;;	Parser return a 0 in the first word (NUMBER)of the first table.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;
; Description: A command parser for DEVICE command in the CONFIG.SYS file.
; ------------
;
; Procedures contained in the file:
; ---------------------------------
;	       PARSER:	Main routine for command processing.
;	       GET_CHAR:  Gets a character from command line.
;	       IS_ALPH:  Checks if character is an alpha character.
;	       IS_DIGIT:  Checks if character is a digit.
;	       IS_DELIM:  Checks if character is a DOS delimiter.
;	       DEVICE_PARSE:  Pulls device name from command line and
;			      inserts in table.
;	       ID_PARSE:  Pulls id name from command line and insers in table
;	       HWCP_PARMS:  Extract HWCP number, converts it to binary and
;			    inserts it in table.
;	       HWCP_PARSE:  Extracts HWCP number if only one number is given.
;	       MUL_HWCP:  Extracts multiple HWCP's numbers, if they are given
;			  in a list.
;	       DESG_PARMS:  Extracts designate number, converts it to binary
;			    and inserts it in table.
;	       DESG_FONT:  Extracts the designate and the font if both were
;			   given in command line.
;	       DESG_PARSE:  Pulls designate number if it is the only one given.
;	       GET_NUMBER:  Converts a number to binary.
;	       OFFSET_TABLE:  Updates the counter in table #1.
;	       FIND_RIGHT_BR:  Looks for a right bracket.
;
;
; Change history:
; ---------------
;
;
;LOGIC:
;------
;	 Establish addressability to parameters.
;	 Skip until end of path and file name -first delimiter
;
;   Loop:
;	 Isolate the first non-delimiter or non delimeter characters.
;	  If End_of_Line_Delimiter then
;	    return an error_code
;	  Else
;	    If first non-delimiter is ALPHA then
;	      (assume a device name)
;	      Extracts device name
;	  Update offset counter
;
;	 Isolate the first non-delimiter characters after id name.
;	  If End_of_Line_Delimiter then
;	    return an error_code
;	  Else
;	    If first non-delimiter is ALPHA-NUMARIC or
;	     If character is '(' then
;	      (assume an id name)
;	      Extracts id name
;	  Update offset counter
;
;	  Pull out HWCP
;	    If error flag is set then exit
;	    Else if end of line flag is set then exit
;
;	  Pull out DESG parms
;	    If error_flag is set then exit.
;	    Else if end of line flag is set then exit
;	    Else if Number of devices is four then Exit
;	 Else Loop
;
;
;Subroutines Logic:
;------------------
;
;  GET_CHAR:
;  ---------
;	       Load character in AL
;	       If character less than 20h then
;		 turn Z-flag on
;
;  IS_ALPHA:
;  ---------
;	       Save character
;	       'Convert character to upper case'
;	       If character >=A and <=Z then
;		 turn Z-flag on
;		 exit
;	       Else
;		 Restore character
;		 exit.
;
;  IS_DIGIT:
;  ---------   If Character >=0 and <=9 then
;		 turn Z-flag on
;
;  IS_DELIMITER:
;  -------------
;	       If character a dos delimiter (' ','=',',',';',TAB)
;		  then turn Z-flag on
;
;  DEVICE_PARSE:
;  -------------
;	       Set device name length counter.
;	       Loop
;		 If a dos delimiter then
;		   add spaces to name (if require)
;		 Else if char is ALPHA-NUM then
;		   save in table
;		   If name >8 character thne
;		     error; exit
;		 Else
;		   error; exit
;
;  ID_PARSE:
;  ---------   Set id name length counter.
;	       Loop
;		 If a dos delimiter then
;		   add spaces to name (if require)
;		 Else if char is ALPHA-NUM then
;		   save in table
;		   If name >8 character then
;		     error; exit
;		 Else if char is ')' or '(' then
;		   set flags
;		 Else
;		   error; exit
;
;  HWCP_PARMS:
;  -----------
;	Loop:	Set flags off
;		If char is a DIGIT then
;		  convert number to binary
;		  update table
;		Else if char is ',' then
;		  no HWCP was given
;		  exit
;		Else if char is '(' then
;		  assume multiple HWCP
;		Else if char is ')' then
;		  end of parms, exit
;		Else if not a delimiter then
;		  error, exit set carry flag set carry flag
;		Loop
;
;  HWCP_PARSE:
;  -----------	Increment counter
;		Get number and convert to binary
;		Update the table
;		Set table_5 pointer
;
;  MUL_HWCP:
;  ---------
;      Loop:	If char is ')' then
;		  end of list, exit
;		If char is a DIGIT
;		  Get number and convert to binary
;		  Update table.
;		If char is not a delimiter then
;		  error, exit set carry flag
;		Loop
;
;  DESG_PARMS:
;  -----------
;	 Loop:	If char is a DIGIT then
;		  Get number and convert to binary
;		  Update table.
;		If char is a ')' then
;		  end of parms, exit
;		If char is a '(' then
;		  assume given desg. and font
;		If char is a ',' then
;		  no desg ginven
;		  scane for ')'
;		If char is not a delimiter then
;		  error, exit set carry flag
;		Loop
;
;  DESG_FONT:
;  ----------
;	Loop:	If char is a ',' then
;		  no desg number was given
;		  update table
;		If char is a ')' then
;		  end of desg-font pair, exit
;		If char is a DIGIT then
;		  Get number and convert to binary
;		  Update table
;		If char not a delimiter then
;		  error, exit set carry flag
;		Loop
;
;  DESG_PARSE:
;  -----------	Get number and conver to binary
;		Update table
;
;  GET_NUMBER:
;  -----------	Get ASCII number from parms
;		conver to binary
;		add to total
;
;  OFFSET_TABLE:
;  -------------
;		Increment the number of parms
;
;  FIND_RIGHT_BR:
;  --------------
;	  Loop: If char is ')' then
;		  found bracket exit
;		If char is not ' ' then
;		  error, exit set carry flag
;		Loop
; END
;------------------------------------------------------
;
; The following is the table structure of the parser.	All fields are
; two bytes field (accept for the device and id name)
;
; TABLE HEADER :
; ÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Number of devices.	  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	 Device  # 1  offset	 ÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄ>ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´		  ³			     ³
;    ³	 Device  # 2  offset	  ³		  ³	 Table_1  (a)	     ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´		  ³			     ³
;    ³	 Device  # 3  offset	  ³		  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	 Device  # 4  offset	  ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;
; N = 1,2,3 or 4.  A two bytes number indicating the number of device specified.
; DEVICE # N OFFSET : a two bytes offset address to table_1. (ie. Device #1 offset
; is a pointer to table_1 (a). Device #2 offset is a pointer to table_1
; (b)...etc.).	 If an error was detected in the command N is set to zero.
;
;
;
; TABLE_1 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿	      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Number of Offsets.	  ³	      ³ 			 ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´    ÚÄÄÄÄÄÄ³      Table_2  (a)	 ³
;    ³	 Device Name  offset	 ÄÅÄÄÄÄÙ      ³ 			 ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´	      ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;    ³	 Device  Id   offset	 ÄÅÄÄÄÄÄÄ¿
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´	 ³    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³	 Device  HWCP offset	 ÄÅÄÄÄÄ¿ ³    ³ 			 ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´    ³ ÀÄÄÄÄ³      Table_3  (a)	 ³
;    ³	 Device  Desg offset	 ÄÅÄÄ¿ ³      ³ 			 ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´  ³ ³      ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;    ³	    "Reserved"            ³  ³ ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³ ³      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;				     ³ ³      ³ 			 ³
;				     ³ ÀÄÄÄÄÄÄ³      Table_4  (a)	 ³
;				     ³	      ³ 			 ³
;				     ³	      ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;				     ³	      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;				     ³	      ³ 			 ³
;				     ÀÄÄÄÄÄÄÄÄ³      Table_5  (a)	 ³
;					      ³ 			 ³
;					      ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;
;  N=Length of table_1, or the number of offsets contained in table_1.
;  The offsets are pointers (two bytes) to the parameters value of the device.
;  "Reserved" : a two byte memory reserved for future use of the "PARMS" option.
;
;
; TABLE_2 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of devices name ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  Device   name 	  ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
; N = Length of device name.  Device length is always 8 byte long.
; Device Name : the name of the device (eg. LPT1, CON, PRN).  The name
; is paded with spaces to make up the rest of the 8 characters.
;
;
;
; TABLE_3 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of Id name.	  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	   Id	Name		  ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
; N = Length of id name.  Id name length is always 8 byte long.
; Id Name : the name of the id (eg. EGA, VGA, 3812).  The name
; is paded with spaces to make up the rest of the 8 character.
;
;
;
; TABLE_4 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of table.	  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  HWCP	#  1		  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  HWCP	#  2		  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³		.		  ³
;    ³		.		  ³
;    ³		.		  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  HWCP	#  10		  ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;
; N = Length of table in words. Or the number of HWCP's.
; HWCP # N : a hardware code page number converted to binary.  The maximum
; number of pages allowed is 10.
;
;
;
; TABLE_5 :
; ÍÍÍÍÍÍÍÍÍ
;
;    ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    ³ N = Length of table.	  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  Designate		  ³
;    ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    ³	  Font			  ³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
; N = Lenght of table.	0 - nothing was specified
;			1 - Only a designate was specified.
;			2 - Designate and font were given.  If the Desg field
;			    was left empty in the DEVICE command then the
;			    Designate field is filled with 0FFFFH.
; Designate, Font : Are the Desg. and Font binary numbers.
;
;------------------------------------------------------
;

;RESERVED MEMORY:
TABLE_1 	DW	?			; Pointer at offsets.
TABLE_2 	DW	?			; Pointer at device name.
TABLE_3 	DW	?			; Pointer at id name.
TABLE_4 	DW	?			; Pointer at hwcp.
TABLE_5 	DW	?			; Pointer at desg and font.
;TABLE		 DB	 290 DUP (?)		 ; Table of parsed parms. Max 4 devices.
DEVNUM		DW	?			; Counter to number of devices.
RIGHT_FLAG	DB	?			; Flag to indicate a left bracket.
DEV_ERR_FLG	DB	?			; Device name error flag.
ID_ERR_FLG	DB	?			; Id name error flag.
ERROR_FLAG	DB	?			; Error flag_terminate program if set to 1.
COMMA_FLAG	DB	?			; Indicate the number of commas incounterd.
HWCP_FLAG	DB	?			; Flag for multiple hwcps.
DESG_FLAG	DB	?			; Flag indicates desg. and font.

;Main part of program-links different sumbroutines together

PARSER		PROC

		PUSH	AX			; ;;;;;;;;;;;;;;;;;;
		PUSH	BX			; ;
		PUSH	CX			; ; SAVE
		PUSH	DX			; ; ALL
		PUSH	DS			; ; REGISTERS.
		PUSH	ES			; ;
		PUSH	DI			; ;
		PUSH	SI			; ;;;;;;;;;;;;;;;;;;

		LES	SI,RH.RH0_BPBA	       ; Point at all after DEVICE=
						; in the CONFIG.SYS file.


;Skip to end of file name, to the first DOS delimiter.

		MOV	DEVNUM,02H		; Number of devices counter.

GET_PARMS_A:	CALL	GET_CHAR		; Get command character in AL .
		JZ	EXIT_B			; No parms found.
		CALL	IS_DELIM		; If not a delimiter then.
		JNE	GET_PARMS_A		; Check next character.

		MOV	DI,OFFSET TABLE 	; Get the table address.
		ADD	DI,02H			; Point at devices offsets.
		MOV	BX,DI			;
		ADD	BX,08H			; Point BX at parms offsets.
TAB2:		CALL	UPDATE_TABLE		; Update table pointers value.

CLR_DELIM:	CALL	GET_CHAR		; Get character into AL.
		JZ	EXIT_B			; No parms found.
		CALL	IS_ALPHA		; If alpha then assume.
		JZ	DEVICE			; A device name.
		CALL	IS_DELIM		; Is it a delimiter
		JNE	EXIT_A			; If not then error.
		JMP	CLR_DELIM		; Get next character.

DEVICE: 	MOV	DEV_ERR_FLG,00H 	; Set device error flag off;
		CALL	DEVICE_PARSE		; Call routine to parse device name.
		CMP	DEV_ERR_FLG,01H 	; If error flag is
		JZ	EXIT_A			; set then exit.
		CALL	OFFSET_TABLE		; Update table.

ID_PARMS:	CALL	GET_CHAR		; Load a character in AL.
		JZ	EXIT_A			; Exit if end of line (error).
		CMP	AL,'('                  ; If AL is a '(' then
		JE	ID			; Parse ID name.
		CALL	IS_ALPHA		; If an Alpha
		JE	ID			; Then parse ID name.
		CALL	IS_DIGIT		; If a digit
		JE	ID			; Then parse ID name.
		CALL	IS_DELIM		; If not a delimiter
		JNE	EXIT_A			; Then error, exit
		JMP	ID_PARMS		; Get another number

EXIT_B: 	CMP	DEVNUM,02H		; If device number above 2 then
		JA	EXIT_C			; Exit parse.
		JMP	EXIT_A			; Else error, exit

ID:		MOV	ID_ERR_FLG,00H		; Set id error flag off.
		CALL	ID_PARSE		; Parse ID name.
		CMP	ID_ERR_FLG,01H		; Was error flag set, then
		JE	EXIT_A			; Print error message.
		CALL	OFFSET_TABLE		; Update table of offsets.

		CALL	HWCP_PARMS		; Get code page number
		CMP	ERROR_FLAG,01H		; If error, then
		JE	EXIT_A			; Print error message and exit
		CMP	ERROR_FLAG,02H		; If end of string
		JE	EXIT_H			; Then exit.

		CALL	DESG_PARMS		; Get designate number
		CMP	ERROR_FLAG,01H		; If error, then
		JE	EXIT_A			; Print error message and exit
		JMP	EXIT_H			; Then exit.

EXIT_A: 	MOV	DI,OFFSET TABLE 	; Load table offset
		MOV	DS:WORD PTR [DI],00H	; Set error to on.
		STC				; Set carry flag
		JMP	EXIT_P			; Exit parse.

EXIT_H: 	MOV	DI,OFFSET TABLE 	; Load table offset.
		ADD	DS:WORD PTR [DI],01H	; Increment number of devices.
		CMP	DEVNUM,08H		; If 4 devices loaded
		JE	EXIT_C			; Then exit parse.
		ADD	DEVNUM,02H		; Increment the number of devices
		ADD	DI,DEVNUM		; Point at next devices offset.
		MOV	BX,TABLE_5		; BX point at
		ADD	BX,06H			; end of previous table.
		JMP	TAB2			; Get next device.

EXIT_C: 	CLC

EXIT_P: 	POP	SI			; ;;;;;;;;;;;;;;;;;;
		POP	DI			; ;
		POP	ES			; ;  RESTORE
		POP	DS			; ;  ALL
		POP	DX			; ;  REGISTERS.
		POP	CX			; ;
		POP	BX			; ;
		POP	AX			; ;;;;;;;;;;;;;;;;;;
		RET

PARSER		ENDP


;********************************************************
;** GET_CHAR : a routine to get next character pointed **
;** to by ES:SI into AL.			       **
;********************************************************

GET_CHAR	PROC

		MOV	AL,ES:BYTE PTR [SI]	; Load character pointed to
		CMP	AL,09H			; by ES:[SI] in AL.
		JE	ZOFF			; If tab then O.K
		CMP	AL,20H			; Turn Z-flag on
		JL	TURN_Z_ON		; if character
ZOFF:		INC	SI			; is below
		JMP	GET_CHAR_X		; 20h.
						; ( End of line
TURN_Z_ON:	CMP	AL,AL			;   delimiters ).
GET_CHAR_X:	RET

GET_CHAR	ENDP


;********************************************************
;** IS_ALPHA : a routine to check the character in     **
;** AL if it is an alpha character (a...z,A...Z).      **
;** If character is lower case, convert to upper case. **
;********************************************************

IS_ALPHA	PROC

		PUSH	AX			; Save value of AL
		AND	AL,0DFH 		; Convert to upper case
		CMP	AL,'A'                  ; If <'A', then
		JB	IS_ALPHA_X		; NZ-flag is set, exit
		CMP	AL,'Z'                  ; If >'Z', then
		JA	IS_ALPHA_X		; NZ-flag is set, exit
		CMP	AL,AL			; Force Z-flag
		POP	DX			; Discard lower case.
		JMP	IA_X			; Exit.
IS_ALPHA_X:	POP	AX			; Restore value of AL
IA_X:		RET

IS_ALPHA	ENDP


;********************************************************
;** IS_DIGIT : a routine to check if the character in  **
;** AL register is a digit (i.e. 1..9). 	       **
;********************************************************

IS_DIGIT	PROC

		CMP	AL,'0'                  ; If < '0' then
		JB	IS_NUM_X		; NZ-flag is set, exit
		CMP	AL,'9'                  ; If > '9' then
		JA	IS_NUM_X		; NZ-flag is set, exit
		CMP	AL,AL			; Set Z-flag to indecate digit
IS_NUM_X:	RET

IS_DIGIT	ENDP


;********************************************************
;** IS_DELIM : This routine check if the character in  **
;** AL is a delimiter. ('+',' ',';',',','=',tab)       **
;********************************************************

IS_DELIM	PROC

		CMP	AL,' '                  ; Test for space.
		JE	IS_DELIM_X		; Z-flag is set, exit
		CMP	AL,','                  ; Test for comma.
		JE	IS_DELIM_X		; Z-flag is set, exit
		CMP	AL,';'                  ; Test for semicolon.
		JE	IS_DELIM_X		; Z-flag is set, exit
		CMP	AL,'='                  ; Test for equal sign.
		JE	IS_DELIM_X		; Z-flag is set, exit
		CMP	AL,09h			; Test for TAB.

IS_DELIM_X:	RET				; Exit

IS_DELIM	ENDP


;********************************************************
;** DEVICE_PARSE : Parse the device driver name and    **
;** store in table.  Update offset.		       **
;********************************************************

DEVICE_PARSE	PROC

		MOV	DI,TABLE_2
		MOV	DS:WORD PTR [DI],0008H	; Save dev name size.
		ADD	DI,02H			; Increment DI.
		MOV	CX,9			; Set counter.
NEXT_C: 	CALL	IS_ALPHA		; if Check then.
		JZ	SAVE_C			; Save it.
		CALL	IS_DIGIT		; if Digit then.
		JZ	SAVE_C			; Save it.
		CMP	AL,'-'                  ; If '-' then.
		JZ	SAVE_C			; Save it.
		CALL	IS_DELIM		; If a delimiter then.
		JZ	ADD_SPACE1		; Pad with spaces.
		CMP	AL,':'                  ; If a colon
		JE	ADD_SPACE1		; then end device parse
		JMP	ERR_DEV_PAR		; Else an error.

SAVE_C: 	DEC	CX			; Decrement counter.
		CMP	CX,0			; If counter zero then.
		JE	ERR_DEV_PAR		; Error.
		MOV	DS:BYTE PTR [DI],AL	; Save char in table.
		INC	DI			; Increment pointer.
		CALL	GET_CHAR		; Get another char.
		JZ	ERR_DEV_PAR
		JMP	NEXT_C			; Check char.

ERR_DEV_PAR:	MOV	DEV_ERR_FLG,01H 	; Set error flag.
		JMP	DEV_PAR_X		; Exit.

ADD_SPACE1:	DEC	CX			; Check counter.
		CMP	CX,1
		JL	DEV_PAR_X		; Exit if already 8.
LL1:		MOV	DS:BYTE PTR [DI],' '    ; Pad name with spaces.
		INC	DI			; Increment pointer.
		LOOP	LL1			; Loop again.
DEV_PAR_X:	RET

DEVICE_PARSE	ENDP


;********************************************************
;** ID_PARSE : Parse the id driver name and	       **
;** store in table.  Update offset.		       **
;********************************************************

ID_PARSE	PROC

		MOV	DI,TABLE_3
		MOV	DS:WORD PTR [DI],0008H	; Save dev name size.
		ADD	DI,02H			; Increment DI.
		MOV	RIGHT_FLAG,00H		; Clear flag.
		MOV	CX,9			; Set counter.

NEXT_I: 	CALL	IS_ALPHA		; If Check then.
		JZ	SAVE_I			; Save it.
		CALL	IS_DIGIT		; if Digit then.
		JZ	SAVE_I			; Save it.
		CMP	AL,'-'                  ; If '-' then.
		JZ	SAVE_I			; Save it.
		CMP	AL,'('                  ; If '(' then.
		JE	RIG_BR_FLG		; Set flag.
		CMP	AL,')'                  ; If ')' then
		JE	BR_FLG_LEF		; Pad with spaces.
		CALL	IS_DELIM		; If a delimiter then.
		JZ	ADD_SPACE2		; Pad with spaces.
		JMP	ERR_ID_PAR		; Else an error.

SAVE_I: 	DEC	CX			; Decrement counter.
		CMP	CX,0			; If counter zero then.
		JLE	ERR_ID_PAR		; Error.
		MOV	DS:BYTE PTR [DI],AL	; Save char in table.
		INC	DI			; Increment pointer.
		CALL	GET_CHAR		; Get another char.
		JZ	ADD_SPACE2		; Exit routine.
		JMP	NEXT_I			; Check char.

ERR_ID_PAR:	MOV	ID_ERR_FLG,01H		; Set error falg on.
		JMP	ID_PAR_X		; Exit.

BR_FLG_LEF:	CMP	RIGHT_FLAG,01H		; If left bracket was
		JNE	ERR_ID_PAR		; found and no previous
		JMP	ADD_SPACE2		; Bracket found, then error

RIG_BR_FLG:	CMP	RIGHT_FLAG,01H		; If more than one bracket
		JE	ERR_ID_PAR		; then error.
		CMP	CX,09			; If '(' and already id
		JB	ERR_ID_PAR		; then error.
		MOV	RIGHT_FLAG,01H		; Set flag for.
		CALL	GET_CHAR		; Left brackets.
		JZ	ERR_ID_PAR		; If end of line,exit.
		JMP	NEXT_I			; Check character.

ADD_SPACE2:	DEC	CX			; Check counter.
		CMP	CX,1
		JL	ID_PAR_X		; Exit if already 8.

LL2:		MOV	DS:BYTE PTR [DI],' '    ; Pad name with spaces.
		INC	DI			; Increment pointer.
		LOOP	LL2			; Loop again.

ID_PAR_X:	RET

ID_PARSE	ENDP

;********************************************************
;** HWCP_PARMS : Scane for the hardware code page, and **
;** parse it if found.	Flag  codes set to:	       **
;** ERROR_FLAG = 0 - parsing completed. No error.      **
;** ERROR_FLAG = 1 - error found exit parse.	       **
;** ERROR_FLAG = 2 - end of line found, exit parse.    **
;********************************************************


HWCP_PARMS	PROC

		MOV	COMMA_FLAG,00H		; Set the comma flag off.
		MOV	ERROR_FLAG,00H		; Set the error flag off.
		DEC	SI			; Point at current char in Al.
		CMP	RIGHT_FLAG,01H		; If no left brackets then
		JNE	LEFT_BR 		; Exit parse.

HWCP_1: 	CALL	GET_CHAR		; Load character in AL.
		JZ	LEFT_BR 		; Exit, if end of line.
		CALL	IS_DIGIT		; Check if digit, then
		JE	HP1			; Parse hwcp parms.
		CMP	AL,','                  ; If a comma
		JE	COMMA_1 		; Jump to comma_1
		CMP	AL,')'                  ; If a ')' then
		JE	RIGHT_BR		; end of current dev parms.
		CMP	AL,'('                  ; If a '(' then
		JE	HWCP_2			; There are multible hwcp.
		CALL	IS_DELIM		; Else, if not a delimiter
		JNE	EXIT_2			; Then error, exit
		JMP	HWCP_1			; Get another character.

LEFT_BR:	CMP	RIGHT_FLAG,01H		; If no left bracket
		JE	EXIT_2			; Then error, exit
		JMP	RB1			; Jump to rb1

COMMA_1:	CMP	COMMA_FLAG,01H		; If comma flag set
		JE	COM_2_HC		; Then exit hwcp parse.
		MOV	COMMA_FLAG,01H		; Else set comma flag.
JMP HWCP_1 ; Get another character.

HWCP_2: 	CMP	RIGHT_FLAG,01H		; If left bracket not set
		JNE	EXIT_2			; then error.
		CALL	MUL_HWCP		; else call multiple hwcp
		ADD	DI,02H			; routine.  Increment DI
		MOV	TABLE_5,DI		; Desg. Table starts at end
		CALL	OFFSET_TABLE		; Update table of offsets.
		JMP	HP_X			; Exit.

HP1:		JMP	HWCP			; Jump too long.

COM_2_HC:	MOV	DI,TABLE_4		; DI points at hwcp table
		MOV	DS:WORD PTR [DI],0000H	; Set number of pages to
		MOV	COMMA_FLAG,00H		; Zero and reset comma flag.
		ADD	DI,02H			; Increment DI.
		MOV	TABLE_5,DI		; Desg. Table starts at end
		CALL	OFFSET_TABLE		; Update table of offsets.
		JMP	HP_X			; of hwcp table.  Exit.

RIGHT_BR:	CMP	RIGHT_FLAG,01H		; If left brackets not
		JNE	EXIT_2			; Found then error.
RB1:		MOV	ERROR_FLAG,02H		; Set end of line flag.
		MOV	BX,TABLE_4		; Point at hwcp table
		ADD	BX,02H			; Adjust pointer to  desg
		MOV	TABLE_5,BX		; table, and save in table_5
		MOV	DI,TABLE_1		; Point at table of offsets
		ADD	DI,08H			; Set at DESG offset
		MOV	DS:WORD PTR [DI],BX	; Update table.
		JMP	HP_X			; Exit



EXIT_2: 	MOV	ERROR_FLAG,01H		; Set error flag.
		JMP	HP_X			; and exit.

HWCP:		CMP	RIGHT_FLAG,01H		; If left brackets not
		JNE	EXIT_2			; Found then error.
		CALL	HWCP_PARSE		; Call parse one hwcp.
		CMP	ERROR_FLAG,01H		; If error flag set
		JE	HP_X			; Then exit,  else
		CALL	OFFSET_TABLE		; Update table of offsets.

HP_X:		RET

HWCP_PARMS	ENDP


;********************************************************
;** HWCP_PARSE : Parse the hardware code page page     **
;** number and change it from hex to binary.	       **
;********************************************************

HWCP_PARSE	PROC

		MOV	DI,TABLE_4		; Load address of hwcpages.
		ADD	DS:WORD PTR [DI],0001H	; Set count to 1

		CALL	GET_NUMBER		; Convert number to binary.
		CMP	ERROR_FLAG,01H		; If error then
		JE	HWCP_X			; Exit.
		MOV	DS:WORD PTR [DI+2],BX	; Else, save binary page number
		ADD	DI,04H			; Increment counter
		MOV	TABLE_5,DI		; Set pointer of designate num

HWCP_X: 	RET

HWCP_PARSE	ENDP


;********************************************************
;** MUL_HWCP : Parse multiple hardware code pages      **
;** and convert them from hex to binary numbers.       **
;********************************************************

MUL_HWCP	PROC

		MOV	DI,TABLE_4		; Load offset of table_4
		MOV	BX,DI			; in DI and Bx.
		MOV	HWCP_FLAG,00H		; Set hwcp flag off.

MH1:		CALL	GET_CHAR		; Load character in AL.
		JZ	MH3			; Exit if end of line.
		CMP	AL,')'                  ; If ')' then exit
		JE	MH2			; end of parms.
		CALL	IS_DIGIT		; If a digit, then
		JE	MH4			; Convert number to binary.
		CALL	IS_DELIM		; If not a delimiter
		JNE	MH3			; then error, exit
		JMP	MH1			; get another character.

MH2:		CALL	GET_CHAR		; Get next character
		JMP	MH_X			; and exit.

MH3:		MOV	ERROR_FLAG,01H		; Set error flag on.
		JMP	MH_X			; Exit.

MH4:		ADD	HWCP_FLAG,01H		; Set hwcp flag on (0 off)
		ADD	DI,02H			; Increment table pointer
		PUSH	BX			; Save Bx
		CALL	GET_NUMBER		; Convert number to binary.
		MOV	DS:WORD PTR [DI],BX	; Add number to table
		POP	BX			; Restore BX.
		CMP	ERROR_FLAG,01H		; If error then
		JE	MH_X			; Exit.
		ADD	DS:WORD PTR [BX],01H	; Increment hwcp count.
		DEC	SI			; Point at character in AL
		JMP	MH1			;   (delimeter or ')').
MH_X:		RET

MUL_HWCP	ENDP



;********************************************************
;** DESG_PARMS : Scane for the designate numbers, and  **
;** parse it if found.	Flag  codes set to:	       **
;** ERROR_FLAG = 0 - parsing completed. No error.      **
;** ERROR_FLAG = 1 - error found exit parse.	       **
;** ERROR_FLAG = 2 - end of line found, exit parse.    **
;********************************************************


DESG_PARMS	PROC

		MOV	DI,TABLE_1		; Get offset of dev in DI
		MOV	BX,TABLE_5		; & offset of desg. in BX.
		ADD	DI,08			; Location of desg offset in table.
		MOV	DS:WORD PTR [DI],BX	; Update table.
		MOV	COMMA_FLAG,00H		; Set comma flag off.

		cmp	al,'('
		je	df
		cmp	al,')'
		je	right_br2

		cmp	al,','
		jne	desg_parm1
		mov	comma_flag,01h

DESG_PARM1:	CALL	GET_CHAR		; Get character in AL.
		JZ	EXIT_3			; Error, if end of line
		CALL	IS_DIGIT		; If character is a digit
		JE	DESG			; Then convert to binary.
		CMP	AL,')'                  ; If a ')', then
		JE	RIGHT_BR2		; end of parameters.
		CMP	AL,'('                  ; If a '(' then
		JE	DF			; parse desg and font.
		CMP	AL,','                  ; If a comma then
		JE	DP3			; set flag.
		CALL	IS_DELIM		; If not a delimiter
		JNE	EXIT_3			; then error.
		JMP	DESG_PARM1		; Get another character.

RIGHT_BR2:	CMP	RIGHT_FLAG,01H		; IF no '(' encountered,
		JNE	EXIT_3			; then error, exit
		JMP	DP_x			; Jump to DP1.

EXIT_3: 	MOV	ERROR_FLAG,01H		; Set error flag on
		JMP	DP_X			; Exit.

DF:		CMP	RIGHT_FLAG,01H		; If no '(' encountered
		JB	EXIT_3			; then error, exit
		CALL	DESG_FONT		; Parse desg and font.
		JMP	DP1			; Jump to DP1.

DP2:		CALL	FIND_RIGHT_BR		; Check for ')'
		JMP	DP_X			; Exit.

DP3:		CMP	COMMA_FLAG,01H		; If comma flag set
		JE	DP2			; then error
		MOV	COMMA_FLAG,01H		; Else set comma flag on.
		JMP	DESG_PARM1		; Get another character.

DESG:		MOV	ERROR_FLAG,00H		; Set error flag off.
		CALL	DESG_PARSE		; Parse desg.
DP1:		CMP	ERROR_FLAG,01H		; If error flag on then
		JE	DP_X			; Exit,
		CALL	FIND_RIGHT_BR		; Else check for ')'
		CALL	OFFSET_TABLE		; Update table

DP_X:		RET

DESG_PARMS	ENDP



;********************************************************
;** DESG_FONT : Parse the designate and font numbers & **
;** change them from decimal to binary. 	       **
;********************************************************


DESG_FONT	PROC


		MOV	DI,TABLE_5		; Get desg font table.
		MOV	COMMA_FLAG,00H		; Set comma flag off.
DF1:		CALL	GET_CHAR		; Load a character in AL.
		JZ	DF3			; Error if end of line.
		CMP	AL,','                  ; Check if a comma.
		JE	DF2			; Set flag.
		CALL	IS_DIGIT		; If a digit, then
		JE	DF5			; Convert number to binary.
		CMP	AL,')'                  ; If a ')' then
		JE	DF4			; Exit.
		CALL	IS_DELIM		; If not a delimiter
		JNE	DF3			; then error, exit
		JMP	DF1			; Get another character.

DF2:		CMP	COMMA_FLAG,01H		; If comma flag on
		JE	DF3			; then error, exit
		MOV	COMMA_FLAG,01H		; Set comma flag on
		ADD	DS:WORD PTR [DI],01H	  ; Increment desg counter.
		MOV	DS:WORD PTR [DI+2],0FFFFH ; Load ffffh for desg empty
		JMP	DF1			  ; field.

DF3:		MOV	ERROR_FLAG,01H		; Set error flag on.
		JMP	DF_X			; Exit.

DF4:		CMP	DESG_FLAG,00H		; If desg flag off
		JE	DF3			; then error, exit
		JMP	DF_X			; Else exit.

DF5:		ADD	DS:WORD PTR [DI],01H	; Increment desg font count.
		CMP	DESG_FLAG,01H		; If desg flag is on
		JE	DF6			; then get font.
		CMP	COMMA_FLAG,01H		; if comma flag is on
		JE	DF6			; then get font.
		MOV	DESG_FLAG,01H		; Set desg flag on
		JMP	DF7			; Get desg number.

DF6:		ADD	DI,02H			; adjust pointer to font.
		MOV	DESG_FLAG,02H		; Set desg and font flag.
DF7:		CALL	GET_NUMBER		; Get a number & convert to
		CMP	ERROR_FLAG,01H		; binary.
		JE	DF_X			; If error flag set, Exit.
		MOV	DS:WORD PTR [DI+2],BX	; Store number in table.
		CMP	DESG_FLAG,02H		; If desg and font flag
		JNE	DF1			; not set, then get char.
		CALL	FIND_RIGHT_BR		; Check for right bracket.

DF_X:		RET

DESG_FONT	ENDP


;********************************************************
;** DESG_PARSE : Parse the designate number and        **
;** change it from decimal to binary.		       **
;********************************************************

DESG_PARSE	PROC

		MOV	DI,TABLE_5		; Load designate location
		ADD	DS:WORD PTR [DI],0001H	; Update table count.

		CALL	GET_NUMBER		; Get the ascii number and
		CMP	ERROR_FLAG,01H		; conver it to binary
		JE	DESG_X			; If error then exit

		MOV	DS:WORD PTR [DI+2],BX	; Else, save desg number


DESG_X: 	RET

DESG_PARSE	ENDP


;********************************************************
;** GET_NUMBER : Convert the number pointed to by  SI  **
;** to a binary number and store it in BX	       **
;********************************************************

GET_NUMBER	PROC

		MOV	CX,0AH			; Set multiplying factor
		XOR	BX,BX			; Clear DX

NEXT_NUM:	SUB	AL,30H			; Conver number to binary
		CBW				; Clear AH
		XCHG	AX,BX			; Switch ax and bx to mul
		MUL	CX			; already converted number by 10.
		JO	ERR_NUM 		; On over flow jump to error.
		ADD	BX,AX			; Add number to total.
		JC	ERR_NUM 		; On over flow jump to error.
		XOR	AX,AX			; Clear AX (clear if al=0a).
		CALL	GET_CHAR		; Get next character
		JZ	GET_NUM_X		; Exit, if end of line.
		CALL	IS_DIGIT		; Call is digit.
		JNZ	GET_NUM_X		; Exit if not a number.
		JMP	NEXT_NUM		; Loop.

ERR_NUM:	MOV	ERROR_FLAG,01H		; Set error code to 1.

GET_NUM_X:	RET

GET_NUMBER	ENDP


;********************************************************
;** UPDATE_TABLE : This routine set up pointers to the **
;** different offsets of the different tables	       **
;********************************************************

UPDATE_TABLE	PROC

		MOV	DS:WORD PTR [DI],BX	; Offset of offsets
		MOV	TABLE_1,BX		; Table_1 points at offsets

		MOV	DI,BX			;
		ADD	BX,0CH			;
		MOV	DS:WORD PTR [DI+2],BX	; Offset of DEVICE name.
		MOV	TABLE_2,BX		; Table_2 point at device name.

		ADD	BX,0AH			;
		MOV	DS:WORD PTR [DI+4],BX	; Offset of ID name.
		MOV	TABLE_3,BX		; Table_3 point at ID name.

		ADD	BX,0AH			;
		MOV	DS:WORD PTR [DI+6],BX	; Offset of HWCP pages.
		MOV	TABLE_4,BX		; Table_4 point at HWCP pages.

		RET

UPDATE_TABLE	ENDP


;********************************************************
;** OFFSET_TABLE : This routine set up pointers of     **
;** tables number one and two.			       **
;********************************************************

OFFSET_TABLE	PROC

		MOV	DI,TABLE_1		; Increment the number
		ADD	DS:WORD PTR [DI],01H	; of parms foun. (ie. id,hwcp
		RET				; and desg)

OFFSET_TABLE	ENDP


;********************************************************
;** FIND_RIGHT_BR :This routine scane the line for a   **
;** ')' if cannot find it turns error flag on          **
;********************************************************

FIND_RIGHT_BR	PROC

FBR1:		CMP	AL,')'                  ; If a right bracket
		JE	FBR_X			; then exit.
		CMP	AL,' '                  ; If not a space
		JNE	FBR2			; Then error.
		CALL	GET_CHAR		; Get a character
		JZ	FBR2			; If end of line then exit.
		JMP	FBR1			; Else get another character.

FBR2:		MOV	ERROR_FLAG,01H		; Set error flag on
FBR_X:		MOV	AL,20H			; Erase character from AL.
		RET

FIND_RIGHT_BR	ENDP

;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;
;;			  ++++++++++++++++++++++++
;;			  ++	INIT Command	++
;;			  ++++++++++++++++++++++++
;;
;;====	Command Code 0 - Initialization  ======
;;
;; messages returned :
;;
;; msg_bad_syntax  -- syntax error from parser, no driver installation
;; msg_no_init	   -- device cannot be initialised
;; msg_insuff_mem  -- insufficient memory
;;
;; layout :	the initialization is done in two stages :
;;
;;		  ++++++++++++++++++++++++
;;		  ++   INIT Stage 1	++	to examine and extract the
;;		  ++++++++++++++++++++++++	parameters defined for the
;;						device_id in DEVICE command,
;;						according to the printer
;;						description table for the
;;						device_id.
;;
;;		  ++++++++++++++++++++++++
;;		  ++   INIT Stage 2	++	to set the BUFfer for the LPTn
;;		  ++++++++++++++++++++++++	or PRN according to device_id's
;;						parameters
;;
;;
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
					;;
DEV_NUM dw	?			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;     Tables for the deivce_id parameters in the order of device_id in the
;     PARSE table
;     === the tables serves as the link between LPTn to be defined in the 2nd
;	  stage, and the device_id that is processed in the first stage.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; device ID indicators :
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DID_MAX EQU	4			;; device entris exepcted in PARSE
;; not more than 16.			;; table
					;;
DID_STATUS DW	0			;; status of parsing device id
					;;  =  0 : all Device-ID bad
					;;  -- see DID_BIT
					;;
DID_MATCH  DW	0			;; this DID has device_name matched
					;;
DID_FAIL   DW	0			;; to fail the good DID_STATUS and
					;; the matched name. (due to
					;; inconsistency among the same LPTn
					;; or between PRN and LPT1.)
					;;
;; (DID_STATUS) AND (DID_MATCH) XOR (DID_FAIL) determines the success of DID
					;;		       initialization
					;;
DID_ONE EQU	00001H			;; first device-ID
DID_TWO EQU	00002H			;; second "
DID_THREE EQU	  00004H		;; third  "
DID_FOUR  EQU	  00008H		;; fourth "
;;maximun number of device_id = 16	;;
					;;
DID_BIT LABEL WORD			;;
	DW	DID_ONE 		;;
	DW	DID_TWO 		;;
	DW	DID_THREE		;;
	DW	DID_FOUR		;;
;;maximun number of device_id = 16	;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; device paramters according to the
					;; device_id defined in DEVICE and the
					;; parameters defined for the device_id
					;; in the printer description table.
					;;
HRMAX	LABEL	word			;; number of hwcp+cart slots supported
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
CTMAX	LABEL	word			;; number of cart slots supported
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
RMMAX	LABEL	word			;; number of ram-slots supported
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
RBUMAX	LABEL	word			;; number of ram-designate slots
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
DESCO	LABEL	word			;; offset to the description table
					;; where the device_id is defined.
	DW	-1			;;  did = 1
	DW	-1			;;  did = 2
	DW	-1			;;  did = 3
	DW	-1			;;  did = 4
;upto max  DID_MAX			;;
					;;
FSIZE	LABEL	word			;; font size of the device
	DW	 0			;;  did = 1
	DW	 0			;;  did = 2
	DW	 0			;;  did = 3
	DW	 0			;;  did = 4
;upto max  DID_MAX			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Hard/RAM slots table in the order of DEVICE parameters
;
;   number of entries in all HARD_SLn is determined by the max. {HSLOTS}, and
;   number of entries in all RAM_SLn  is determined by the max. {RSLOTS}
;
;   -- they are initialized according to the device_id defined in the DEVICE.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
HARD_SLA LABEL	word			;; index in the order of device in
	DW	OFFSET	(HARD_SL1)	;; the PARSE-talbes
	DW	OFFSET	(HARD_SL2)	;;
	DW	OFFSET	(HARD_SL3)	;;
	DW	OFFSET	(HARD_SL4)	;;
; up to DID_MAX 			;;
					;;
RAM_SLA LABEL	word			;;
	DW	OFFSET (RAM_SL1)	;;
	DW	OFFSET (RAM_SL2)	;;
	DW	OFFSET (RAM_SL3)	;;
	DW	OFFSET (RAM_SL4)	;;
; up to DID_MAX 			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	 ++++++++++++++++++++++++
;;	 ++    INIT Command    ++
;;	 ++++++++++++++++++++++++
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
INIT	PROC	NEAR			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; parse the initialization parameters in DEVICE command
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
					;;
	CMP	BUF.BFLAG,BF_PRN	;; since PRN is the FIRST device header
	JNE	NOT_PRN 		;;
					;;
					;;
	MOV	AX,OFFSET CODE_END	;; defined only once for each DEVICE
	XOR	CX,CX			;;
	MOV	CL,4			;;
	SHR	AX,CL			;;
	PUSH	CS			;;
	POP	CX			;;
	ADD	AX,CX			;;
	INC	AX			;; leave 16 bytes,room for resident_end
	MOV	RESIDENT_END,AX 	;;
					;;
	CALL	PARSER			;; call only once, for PRM
					;;
	JMP	PROCESS_TABLE		;;
					;;
NOT_PRN :				;;
	CMP	DEV_NUM,1		;;
					;;
	JNB	PROCESS_TABLE		;;
					;;
	JMP	SYNTAX_ERROR		;;
					;;
					;;
					;;
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;
;;	 ++++++++++++++++++++++++
;;	 ++   INIT Stage 1     ++
;;	 ++++++++++++++++++++++++
;;
;;  INIT - FIRST STAGE :
;;
;;    == test and extract if the parameters on device-id is valid
;;    == determine the DID_STATUS according to the validity of the parameters
;;    == procedure(s) called -- DID_EXTRACT
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
					;;
PROCESS_TABLE : 			;;
					;;
	PUSH	CS			;;
	POP	ES			;; PSE points to Device offsets
	MOV	DI,OFFSET(table)	;; ES:[DI]
	MOV	DX,PSE.PAR_DEV_NUM	;;
	MOV	DEV_NUM,DX		;;
					;;
	CMP	DEV_NUM,0		;;
	JNZ	NO_SYNTAX_ERR		;;
					;;
	XOR	AX,AX			;;
	MOV	AH,09H			;;
	MOV	DX,OFFSET MSG_BAD_SYNTAX;;
	INT	21H			;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SYNTAX_ERROR :				;; set the request header status
					;; according to the STATE
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	AX, RESIDENT_END	;;
	PUSH	CS			;;
	POP	CX			;; CX=CS
	SUB	AX,Cx			;; additional segment required.
CS_LOOP1:				;;
	CMP	AX,1000H		;;
	JB	CS_LPEND1		;;
	ADD	CX,1000H		;;
	SUB	AX,1000H		;;
	JMP	CS_LOOP1		;;
					;;
CS_LPEND1:				;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
					;;
	LES	DI,dword ptr buf.rh_ptro ;; get Request Header address
;	MOV	RH.RH0_ENDO,AX		;;
	MOV	RH.RH0_ENDO,0		;;
	MOV	RH.RH0_ENDS,CX		;;
	MOV	RH.RHC_STA,stat_cmderr	;; set status in request header
					;;
	JMP	INIT_RETurn		;;
					;;
					;;
NO_SYNTAX_ERR : 			;;
					;;
	CMP	DX,DID_MAX		;;
	JNA	NEXT_DID		;;
					;;
	MOV	INIT_CHK,0001H		;; ERROR 0001
	JMP	BAD_DID 		;; more than supported no. of device
					;;
NEXT_DID:				;;
	PUSH	DI			;; pointer to PAR_OT (table 1)
	AND	DX,DX			;;
	JNZ	SCAN_DESC		;;
	JMP	END_DID 		;; DI = offset to the 1st PARSE table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCAN_DESC:				;;
	MOV	DI,PSE.PAR_OFF		;; points to the nth device
					;;
					;; find the description for the
					;;device-id
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	CX,PRINTER_DESC_NUM	;;
	MOV	SI, OFFSET(PRINTER_DESC_TBL); offset to the description table
	PUSH	CS			;;
	POP	DS			;;
;	$SEARCH 			;;
$$DO1:
	    PUSH    CX			;; save device count
	    PUSH    SI			;; pointer to printer-descn's offset
	    MOV     SI,CS:WORD PTR[SI]	;;
	    AND     CX,CX		;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	$LEAVE	Z			;; LEAVE if no more device description
	JZ $$EN1
	    PUSH    DI			;; save offset to PAR_DEVOT
	    MOV     DI,PSE.PAR_DIDO	;;
	    MOV     CX,PSE.PAR_DIDL	;; length of parsed device name
	    LEA     DI,PSE.PAR_DID	;; pointer to parse device name
					;;
	    PUSH    SI			;;
	    LEA     SI,[SI].TYPEID	;; offset to name of device-id
	    REPE    CMPSB		;;
	    POP     SI			;;
	    POP     DI			;; get back offset to PAR_DEVOT
					;;;;;;;;;;;;;;;;;;;;;;;;
;	$EXITIF Z			;; EXIT if name matched
	JNZ $$IF1
					;;
	    CALL    DID_EXTRACT 	;; get the parameters
					;;
	    POP     SI			;; balance push-pop
	    POP     CX			;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	$ORELSE 			;; try next description :
	JMP SHORT $$SR1
$$IF1:
					;;
	    POP     SI			;; of printer_descn offset table
	    INC     SI			;;
	    INC     SI			;; next offset to PRINTER_DESCn
					;;
	    POP     CX			;; one description less
	    DEC     CX			;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	$ENDLOOP			;; DEVICE-ID not defined in
	JMP SHORT $$DO1
$$EN1:
					;; printer_desc;
					;;
	    MOV     AX,INIT_CHK 	;;
	    AND     AX,AX		;;
	    JNZ     UNCHANGED		;;
	    MOV     INIT_CHK,0004H	;; ERROR 0004
UNCHANGED:				;;
	    POP     SI			;; balance push-pop
	    POP     CX			;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	$ENDSRCH			;; End of scanning printer_desc
$$SR1:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	POP	DI			;;
	INC	DI			;;
	INC	DI			;; points to next device in PART_OT
	DEC	DX			;;
					;;
	JMP	NEXT_DID		;;
					;;
END_DID :				;;
	POP	DI			;;
BAD_DID :				;;
					;;
	MOV	AX,DID_STATUS		;;
	AND	AX,AX			;;
	JNZ	DEF_BUFFER		;;
					;;
	JMP	END_LPT 		;;
					;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;
;;	++++++++++++++++++++++++
;;	++   INIT Stage 2     ++
;;	++++++++++++++++++++++++
;;
;; INIT -- SECOND STAGE :
;;
;;	== match the device_name extracted in stage 1 with the name of PRN or
;;	   LPTn
;;
;;	== if the PRN/LPTn has never been defined before, then set up the BUF
;;	   for the PRN/LPTn if the DID_STATUS is good; otherwise message will
;;	   be generated indicating it cannot be initilized.
;;
;;	== if there is PRN, LPT1 is also setup, and vice vera. IF both PRN and
;;	   LPT1 are on the DEVICE command, or there are multiple entries for
;;	   the same LPTn, the consistency is checked. It they are inconsistent
;;	   the associated LPTn or PRN is forced to fail by : DID_FAIL.
;;
;;	== if the device_name on the DEVICE command is not one of the supported
;;	   PRN or LPTn, then DID_MATCH bit will not be set. An error message
;;	   will be generated for the device_name indicating it cannot be
;;	   initialized.
;;
;;	== procedure(s) called : CHK_DID   .. check DID parameters for device
;;					      whose name matched.
;;				 DEV_CHECK .. if device-name duplicated, or
;;					      there are both PRN/LPT1 : check
;;					      for consistent parameters.
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DEF_BUFFER :				;;
	PUSH	CS			;;
	POP	ES			;; PSE points to Device offsets
	MOV	DI,OFFSET(table)	;; ES:[DI]
	xor	cx,cx			;; device order in parse table
;SEARCH 				;;
$$DO7:
	    PUSH    DI			;; pointer to PAR_OT
	    PUSH    CX			;; save device count
	    MOV     DI,PSE.PAR_OFF	;;   "     "  PAR_DEVOT
	    cmp     cx,dev_num		;;
					;;
;LEAVE NB				;; LEAVE if no more device entry
	   jb	    MORE_DEVICE 	;;
	   JMP	    $$EN7
MORE_DEVICE :				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; more parsed_device to be checked
	    PUSH    DI			;; save offset to PAR_DEVOT
	    MOV     DI,PSE.PAR_DNMO	;;
	    MOV     CX,PSE.PAR_DNML	;; length of parsed device name
	    LEA     DI,PSE.PAR_DNM	;; pointer to parse device name
					;;
	    LDS     SI,DWORD PTR BUF.DEV_HDRO ; get the offset to device-n header
	    LEA     SI,HP.DH_NAME	;; "       offset to name of device-n
	    REPE    CMPSB		;;
	    POP     DI			;; get back offset to PAR_DEVOT
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;
;EXITIF Z				;; EXIT if name matched
	JZ  NAME_MATCHED		;;
					;;
	JMP MORE_PARSED_DEVICE		;;
					;;
NAME_MATCHED :				;;
					;;
	    POP     CX			;; the DID order
	    PUSH    BX			;;
	    MOV     BX,CX		;;
	    ADD     BX,BX		;;
	    MOV     AX,DID_BIT[BX]	;;
	    OR	    DID_MATCH,AX	;; this DID matched
	    POP     BX			;;
	    PUSH    CX			;;
					;;
	    LEA     SI,BUF.PAR_EXTRACTO ;; was the LPT1/PRN defined before ?
	    MOV     AX,CS:[SI].PAR_DNMO ;;
	    CMP     AX,0FFFFH		;;
					;;
	    JNE     DEV_COMPARE 	;; DI = PAR_DEVOT
					;;-----------------------------------
					;;
					;; no device previousely defined
	    MOV     AX,PSE.PAR_DNMO	;;
	    MOV     CS:[SI].PAR_DNMO,AX ;; define device parameters for LPTn
					;;
	    MOV     AX,PSE.PAR_DIDO	;;
	    MOV     CS:[SI].PAR_DIDO,AX ;;
					;;
	    MOV     AX,PSE.PAR_HWCPO	;;
	    MOV     CS:[SI].PAR_HWCPO,AX ;;
					;;
	    MOV     AX,PSE.PAR_DESGO	;;
	    MOV     CS:[SI].PAR_DESGO,AX ;;
					;;
	    MOV     AX,PSE.PAR_PARMO	;;
	    MOV     CS:[SI].PAR_PARMO,AX ;;
					;;
					;;---------------------------------
	    CALL    CHK_DID		;; define the STATE according to
					;; DID_STATUS
	    JMP     MORE_PARSED_DEVICE	;;
					;;
DEV_COMPARE :				;;-------------------------------
					;; e.g. LPT1 and PRN shares one BUF.
					;;	or duplicated device name
	    CALL    DEV_CHECK		;;
					;;
	    CMP     BUF.STATE,CPSW	;;
	    JNE     DEV_COMPARE_FAIL	;;
					;;
	    JMP     MORE_PARSED_DEVICE	;;
					;;
DEV_COMPARE_FAIL :			;;
					;;
	    POP     CX			;;
	    POP     DI			;; balance push-pop
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;$ORELSE				;;
	JMP	  END_LPT
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MORE_PARSED_DEVICE :			;; name does not match
					;;
	    POP     CX			;;
	    INC     CX			;;
	    POP     DI			;;
	    INC     DI			;;
	    INC     DI			;; points to next device in PART_OT
					;;
	    jmp     $$DO7		;;
;$ENDLOOP				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
$$EN7:					;; no device found for LPTn
					;;
	    POP     CX			;;
	    POP     DI			;; balance push-pop
					;;
	    CMP     BUF.STATE,CPSW	;;
	    JE	    END_LPT		;; for LPT1/PRN pair
					;;
	    MOV     BUF.STATE,NORMAL	;; no device defined for the LPTn
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; End of defining LPTn Buffer
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;$ENDSRCH				;;
END_LPT :				;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; set the request header status
					;; according to the STATE
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	AX, RESIDENT_END	;;
	PUSH	CS			;;
	POP	CX			;; CX=CS
	SUB	AX,Cx			;; additional segment required.
CS_LOOP2:				;;
	CMP	AX,1000H		;;
	JB	CS_LPEND2		;;
	ADD	CX,1000H		;;
	SUB	AX,1000H		;;
	JMP	CS_LOOP2		;;
					;;
CS_LPEND2:				;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
					;;
	LES	DI,dword ptr buf.rh_ptro ;; get Request Header address
	MOV	RH.RH0_ENDO,AX		;;
	MOV	RH.RH0_ENDS,CX		;;
	XOR	AX,AX			;; clear error code to be returned
	MOV	CX,BUF.STATE		;;
	CMP	CX,CPSW 		;;
	JE	MATCH_GOOD		;;
	MOV	AX,STAT_CMDERR		;;
					;;
MATCH_GOOD :				;;
	MOV	RH.RHC_STA,AX		;; set status in request header
					;;
BUF_END :				;;
					;;
	CMP	BUF.BFLAG,BF_LPT1	;;
	JNE	BUF_MESSAGES		;;
					;;
	CMP	BUF.STATE,CPSW		;;
	JNE	BUF_MESSAGES		;;
					;; set PRN to the same setting as LPT1
	PUSH	BX			;;
					;;
	LEA	SI,BUF.RNORMO		;;
	LEA	CX,BUF.BUFEND		;;
	SUB	CX,SI			;;
	MOV	BX,BUF.PRN_BUFO 	;; where PRN buffer is
	LEA	DI,BUF.RNORMO		;;
	PUSH	CS			;;
	POP	ES			;;
	PUSH	CS			;;
	POP	DS			;;
	REP	MOVSB			;;
					;;
	POP	BX			;;
					;;
BUF_MESSAGES :				;;
	CMP	BUF.BFLAG,BF_LPT3	;; generate error message is this is
	je	last_round		;; the last LPTn
	Jmp	INIT_RETURN		;;
					;; ERROR messages will be generated
					;; at the end of initialization of all
					;; the LPT devices
last_round :				;;
	MOV	AX,RESIDENT_END 	;;
	ADD	AX,STACK_SIZE		;;
	MOV	RESIDENT_END,AX 	;;
	PUSH	CS			;;
	POP	CX			;; CX=CS
	SUB	AX,Cx			;; additional segment required.
CS_LOOP3:				;;
	CMP	AX,1000H		;;
	JB	CS_LPEND3		;;
	ADD	CX,1000H		;;
	SUB	AX,1000H		;;
	JMP	CS_LOOP3		;;
					;;
CS_LPENd3:				;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
					;;
	MOV	RH.RH0_ENDO,AX		;; STACK !!!!!
	MOV	STACK_ALLOCATED,0	;; from now on, internal stack is used
					;;
	MOV	AX,DID_STATUS		;; what is the DID combination ?
	AND	AX,DID_MATCH		;;
	XOR	AX,DID_FAIL		;;
					;;
	AND	AX,AX			;;
	JNZ	CODE_STAYED		;;
;	MOV	RH.RH0_ENDO,0		;; none of the devices are good
					;;
					;;
CODE_STAYED :				;;
	MOV	DI,OFFSET TABLE 	;;
	push	CS			;;
	POP	ES			;;
					;;
	XOR	CX,CX			;;
MSG_LOOP :				;;
	CMP	CX,DEV_NUM		;;
	JNB	INIT_RETURN		;;
	SHR	AX,1			;;
	JC	MSG_NEXT		;;
					;; this device in parse table is bad
	PUSH	DI			;;
	PUSH	CX			;;
	PUSH	AX			;;
					;;
	MOV	DI,PSE.PAR_OFF		;;
	MOV	SI,PSE.PAR_DNMO 	;;
					;;
	PUSH	CS			;;
	POP	ES			;;
	PUSH	CS			;;
	POP	DS			;;
					;;
	MOV	CX,8			;;
	LEA	SI,[SI].PAR_DNM 	;;
					;;
	MOV	DI,SI			;;
	ADD	DI,7			;; skip backward the blanks
	MOV	AL,20H			;;
	STD				;;
	REPE	SCASB			;;
	CLD				;;
					;;
	MOV	DI, OFFSET MSG_NO_INIT_P;;
	MOV	DX,DI			;; for INT 21H
	XOR	AX,AX			;;
	MOV	AH,09H			;;
	INT	21H			;;
					;;
					;;
	MOV	DI, OFFSET MSG_NO_INIT	;;
	MOV	DX,DI			;; for INT 21H
					;;
	INC	CX			;;
					;;
	PUSH	CX			;; remaining name that is non blank
	MOV	AX,CX			;;
	MOV	CX,8			;;
	SUB	CX,AX			;;
	ADD	DI,CX			;;
	MOV	DX,DI			;;
	POP	CX			;;
	REP	MOVSB			;;
					;;
					;;
	XOR	AX,AX			;;
	MOV	AH,09H			;;
	INT	21H			;;
					;;
	POP	AX			;;
	POP	CX			;;
	POP	DI			;;
					;;
MSG_NEXT :				;;
	INC	CX			;;
	INC	DI			;;
	INC	DI			;;
	JMP	MSG_LOOP		;;
					;;
					;;
INIT_RETURN :				;;
					;;
					;;
	RET				;;
					;;
INIT	ENDP				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Call by INIT to extract parameters for the deivce_id
;;
;; on rntry :
;;	ES:[DI]  PARSE Table 2, offsets of all parameters
;;	DS:[SI]  Printer Description table whose TYPEID matched
;;	DX	 "inverse" order of devices in the PARSE tables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
DID_EXTRACT PROC			;;
					;;
	PUSH	DX			;;
					;;-----------------------------
					;; define the DID_parameters
	PUSH	BX			;;
					;;
	MOV	BX,DEV_NUM		;;
	SUB	BX,DX			;; order in the Parse table
	add	bx,bx			;; double to index [bx]
	MOV	DX,BX			;;
					;;
	MOV	AX,DS:[SI].FONTSZ	;;
	MOV	FSIZE[BX],AX		;; size of font buffer to be created
					;;
	MOV	AX,DS:[SI].HSLOTS	;;
	CMP	AX,HARDSL_MAX		;;
	JNA	LESS_HARDSL		;;
	MOV	INIT_CHK, 0010H 	;; ERROR 0010H
	POP	BX			;;
	JMP	END_MATCH_BAD		;;
LESS_HARDSL :				;;
	CMP	AX,DS:[SI].HWCPMIN	;;
	JNB	VALID_HARDSL		;;
	MOV	INIT_CHK, 0012H 	;; ERROR 0012H
	POP	BX			;;
	JMP	END_MATCH_BAD		;;
VALID_HARDSL :				;;
	MOV	HRMAX[BX],AX		;;
	MOV	CTMAX[BX],AX		;; will be reduced by the no. of hwcp
					;;
	MOV	AX,DS:[SI].RSLOTS	;;
	CMP	AX,RAMSL_MAX		;;
	JNA	LESS_RAMSL		;;
	MOV	INIT_CHK, 0011H 	;; ERROR 0011H
	POP	BX			;;
	JMP	END_MATCH_BAD		;;
LESS_RAMSL :				;;
	MOV	RMMAX[BX],AX		;;	see also designate
					;;
	MOV	DESCO[BX],SI		;;
					;;
	POP	BX			;;
					;;----------------------------------
					;;
	PUSH	CX			;;
					;;
HWCPgt: PUSH	DI			;; get the hwcp
					;;
	MOV	DI,PSE.PAR_HWCPO	;;
	MOV	CX,PSE.PAR_HWCPL	;; no. of hwcp
	AND	CX,CX			;;
	JNZ	chk_hwcp		;;
	push	bx			;;
	mov	bx,dx			;;
	MOV	HRMAX[BX],CX		;;
	MOV	CX,DS:[SI].HWCPMIN	;;
	SUB	CTMAX[BX],CX		;; what is left becomes cartridge slot
	pop	bx			;;
	JMP	DESIGN			;;
					;; hwcp to be defined
chk_hwcp: MOV	AX,DS:[SI].HSLOTS	;; defined in printer_desc
	CMP	CX,AX			;;
	JA	BAD_MATCH2		;;
	CMP	CX,HARDSL_MAX		;;
	JNA	HWCP_GOOD		;; jump if system error
	MOV	INIT_CHK,0003H		;; ERROR 0003
	JMP	END_MATCH		;;
BAD_MATCH2:				;;
	MOV	INIT_CHK,0002H		;; ERROR 0002
	JMP	END_MATCH		;;
					;;
HWCP_GOOD:				;; there are sufficient hard-slot for
					;; HWCP
	PUSH	SI			;; printer description table of TYPEID
	PUSH	BX			;;
					;;
	MOV	BX,DX			;;
	MOV	AX,CTMAX[BX]		;;
					;;
	PUSH	CX			;; calculate what is left for cart_slot
	CMP	CX,DS:[SI].HWCPMIN	;;
	JNB	MORE_THAN_HWCPMIN	;;
	MOV	CX,DS:[SI].HWCPMIN	;;
MORE_THAN_HWCPMIN :			;;
	SUB	AX,CX			;;
	POP	CX			;;
	mov	HRMAX[BX],CX		;;
					;;
	MOV	CTMAX[BX],AX		;; no of cart-slot for designate
	MOV	SI,HARD_SLA[BX] 	;; get the corresponding hard-slots
					;;
	POP	BX			;;
					;;
	push	bx			;;
	push	dx			;;
	mov	bx,si			;;
	mov	dx,cx			;;
	mov	reserved1,dx		;; IF THERE IS ANY REPETITIVE HWCP
	mov	reserved2,bx		;; IF THERE IS ANY REPETITIVE HWCP
					;;
FILL_HWCP:				;;
	AND	CX,CX			;;
	JZ	DESIGN_P		;;
	INC	DI			;; next code page in PARSE table
	INC	DI			;;
	MOV	AX,ES:[DI]		;; get code page value
					;;
					;; IF THERE IS ANY REPETITIVE HWCP
	push	dx			;;
	push	bx			;;
hwcp_norep :				;;
	cmp	ax,cs:[bx].slt_cp	;;
	jne	hwcp_repnext		;;
	pop	bx			;;
	pop	dx			;;
	pop	dx			;;
	pop	bx			;;
	pop	si			;;
	jmp	end_match		;;
					;;
hwcp_repnext:				;;
	inc	bx			;;
	inc	bx			;;
	inc	bx			;;
	inc	bx			;;
	dec	dx			;;
	jnz	hwcp_norep		;;
	pop	bx			;;
	pop	dx			;;
					;;
	MOV	CS:[SI].SLT_CP,AX	;;
	MOV	AX,CS:[SI].SLT_AT	;; get the attributes
	OR	AX,AT_OCC		;; occupied
	OR	AX,AT_HWCP		;; hwcp slot
	MOV	CS:[SI].SLT_AT,AX	;;
	INC	SI			;;
	INC	SI			;; next slot
	INC	SI			;; next slot
	INC	SI			;; next slot
	DEC	CX			;;
	JMP	FILL_HWCP		;;
DESIGN_P:				;;
	pop	dx			;;
	pop	bx			;;
	POP	SI			;;
					;;---------------------
DESIGN: POP	DI			;; get the designate no.
	PUSH	DI			;;
					;;
	MOV	DI,PSE.PAR_DESGO	;;
	MOV	AX,PSE.PAR_DESGL	;;
	CMP	AX,1			;;
	JA	END_MATCH		;; there should have no font entry
	AND	AX,AX			;;
	JZ	DEF_RBUFMAX		;;
					;;
	MOV	AX,PSE.PAR_DESG 	;;
	AND	AX,AX			;;
	JZ	DEF_RBUFMAX		;;
					;;
	CMP	CS:[SI].CLASS,1 	;;
	JNE	DESIG_NOt_CLASS1	;;
					;;
	PUSH	BX			;; if there is any cartridge slot ?
	PUSH	AX			;;
	MOV	BX,DX			;;
	MOV	AX,ctmax[BX]		;;
	AND	AX,AX			;;
	POP	AX			;;
	POP	BX			;;
	JZ	END_MATCH		;; fail, as there is no physical RAM.
					;;
	CMP	AX,HARDSL_MAX		;; is the designate more than max ?
	JA	END_MATCH		;;
					;;
					;;
	JMP	DEF_RBUFMAX		;;
					;;
					;;
					;;
DESIG_NOT_CLASS1 :			;;
	PUSH	BX			;; if there is any physical RAM slot ?
	PUSH	AX			;;
	MOV	BX,DX			;;
	MOV	AX,RMMAX[BX]		;;
	AND	AX,AX			;;
	POP	AX			;;
	POP	BX			;;
	JZ	END_MATCH		;; fail, as there is no physical RAM.
					;;
					;;
	CMP	AX,RAMSL_MAX		;; is the designate more than max ?
	JA	END_MATCH		;;
					;;
DEF_RBUFMAX :				;;
	PUSH	BX			;;
	MOV	BX,DX			;;
	MOV	RBUMAX[BX],AX		;;
	POP	BX			;;
					;;
					;;
PARAM : 				;;
;PARM:	    POP     DI			;;
;	    PUSH    DI			;;
;;	    MOV     DI,PSE.PAR_PARMO	;;
					;;
					;,--------------------------
					;; GOOD device_id parameters
	shr	dx,1			;;
	MOV	AX,DID_ONE		;;
	MOV	CX,DX			;;
	AND	CX,CX			;;
	JZ	NO_SHL			;;
	SHL	AX,CL			;;
NO_SHL: OR	DID_STATUS,AX		;; is defined
					;;-------------------------
END_MATCH: POP	DI			;; end of extract
	POP	CX			;;
END_MATCH_BAD : 			;;
	POP	DX			;;
					;;
	RET				;;
					;;
DID_EXTRACT ENDP			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Called by INIT to define the STATE and BUF for the LPTn according to
;; the DID_STATUS. Create font buffer if requested through the "desi*nate"
;;
;; at entry :  CX = device order in parse table
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_DID PROC				;;
					;;
	push	cx			;;
	push	di			;;
	push	dx			;;
					;;
	MOV	AX,DID_STATUS		;;
					;;
	PUSH	CX			;; order 0 to m
	POP	DI			;;
	ADD	DI,DI			;; indexing : [DI]
					;;
	INC	CX			;;
	SHR	AX,CL			;; is the device parameter valid ?
					;;
	JC	DEFINE_BUFFER		;;
	JMP	LPT_FAIL		;;--------------------------
					;;
DEFINE_BUFFER : 			;;
					;; good device parameters as determined
	MOV	AX,DESCO[DI]		;;
	MOV	BUF.PDESCO,AX		;;
					;;
	PUSH	DI			;;
	MOV	DI,AX			;;
	MOV	AX,CS:[DI].CLASS	;;
	MOV	BUF.PCLASS,AX		;;
	POP	DI			;;
					;;
	MOV	AX,HARD_SLA[DI] 	;;  in the DID_EXTRACT
	MOV	BUF.HARDSO,AX		;;
					;;
	MOV	AX,RAM_SLA[DI]		;;
	MOV	BUF.RAMSO,AX		;;
					;;
	MOV	AX,HRMAX[DI]		;;
	MOV	BUF.HARDMX,AX		;;
					;;
	MOV	AX,CTMAX[DI]		;;
	MOV	BUF.HCARMX,AX		;;
					;;
	ADD	AX,HRMAX[DI]		;; defore "designate"
	MOV	BUF.HSLMX,AX		;;
					;;
					;;
	MOV	AX,RMMAX[DI]		;;
	MOV	BUF.RAMMX,AX		;;
					;;
	XOR	AX,AX			;;
	PUSH	CX			;; calculate the max. length of control
	MOV	CX,2			;; sequence that is allowed for the
	CMP	BUF.PCLASS,1		;; room reserved for physical slots.
	JNE	CTL_LOOP		;;
	MOV	CX,1			;; class 1 printer has one control seq.
CTL_LOOP :				;;
	ADD	AX,CTL_MAX		;;
	DEC	AX			;; leave one byte for the length
	DEC	CX			;;
	JNZ	CTL_LOOP		;;
	MOV	BUF.FSELMAX,AX		;;
	POP	CX			;;
					;;
	MOV	AX,FSIZE[DI]		;;
	MOV	BUF.FTSZPA,AX		;; FTSIZE in paragraph
					;;
	PUSH	AX			;;
					;;
	MOV	DX,4			;;
FT_PARA:				;;
	ADD	AX,AX			;;
	DEC	DX			;;
	JNZ	FT_PARA 		;; font size
	MOV	BUF.FTSIZE,AX		;; font size in bytes (used with.RBUFMX)
					;;
	POP	DX			;; FTSIZE in paragraph
					;;
	MOV	CX,RBUMAX[DI]		;; create font buffer per .RBUFMX and
	MOV	BUF.RBUFMX,CX		;; assume sufficient memory for all the
					;; "designate request"
	PUSH	CX			;;
					;;
	CMP	BUF.PCLASS,1		;; always create font buffer for class1
	JNE	CLASS_NOT_1		;;
					;;
	AND	CX,CX			;;
	JZ	CLASS1_NOCX		;;
	ADD	CX,BUF.HARDMX		;;
	MOV	BUF.HSLMX,CX		;;
	JMP	CLASS_NOT_1		;;
					;;
CLASS1_NOCX:				;;
	MOV	CX,BUF.HSLMX		;;
					;;
CLASS_NOT_1 :				;;
	AND	CX,CX			;;
	JZ	MULTIPLE_DONE		;;
	MOV	AX,RESIDENT_END 	;;
MULTIPLE_FT :				;;
	ADD	AX,DX			;; allocate the font buffers at the end
	DEC	CX			;; of the resident codes
	JNZ	MULTIPLE_FT		;;
					;;
					;;
	MOV	CX,RESIDENT_END 	;;
	MOV	BUF.FTSTART,CX		;;
	MOV	RESIDENT_END,AX 	;;
					;;
					;;
MULTIPLE_DONE : 			;;
	POP	CX			;; designate requested
					;;
	CMP	BUF.PCLASS,1		;;
	JNE	DEF_RBUF		;;
					;; CLASS 1
	CMP	BUF.HARDMX,0		;;
	JE	DEFBUF_DONE		;;
					;;
	PUSH	CX			;; STACKS...
	PUSH	SI			;;
	PUSH	DS			;;
	PUSH	ES			;;
	PUSH	DI			;;
	PUSH	DX			;;
					;;
	MOV	DX,BUF.HARDMX		;;
	PUSH	DX			;; STACK +1 -- # of HWCP
					;;
	PUSH	CS			;;
	POP	DS			;;
	MOV	BUF.RBUFMX,0		;;
	MOV	SI,BUF.PDESCO		;;
	MOV	SI,CS:[SI].SELH_O	;;
	XOR	CX,CX			;;
	MOV	CL,CS:BYTE PTR [SI]	;;
	INC	CX			;; including the length byte
					;;
	MOV	DI,BUF.FTSTART		;; control template
DEF_FTBUF:				;; fill the  font buffer with the
	PUSH	DI			;;
	POP	ES			;;
	XOR	DI,DI			;;
					;;
	PUSH	CX			;;
	PUSH	SI			;;
	REP	MOVSB			;;
	POP	SI			;;
	POP	CX			;;
					;;
	PUSH	ES			;;
	POP	DI			;;
	ADD	DI,BUF.FTszpa		;;
	DEC	DX			;;
	JNZ	DEF_FTBUF		;;
					;;
	POP	DX			;; STACK -1
					;;
	MOV	SI,BUF.HARDSO		;;
	MOV	DI,BUF.FTSTART		;; define the HWCP values
DEF_FThwcp :				;;
	PUSH	DI			;;
	POP	ES			;;
	MOV	DI,CTL5202_OFFS 	;; offset to the HWCP words
					;;
	MOV	AX,CS:[SI].SLT_CP	;;
	MOV	ES:WORD PTR [DI],AX	;;
					;;
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
					;;
	PUSH	ES			;;
	POP	DI			;;
	ADD	DI,BUF.FTSZPA		;;
	DEC	DX			;;
	JNZ	DEF_FThwcp		;;
					;;
	POP	DX			;;
	POP	DI			;;
	POP	ES			;;
	POP	DS			;;
	POP	SI			;;
	POP	CX			;;
					;;
	JMP	DEFBUF_DONE		;;
					;;
					;;
DEF_RBUF :				;;
	MOV	BUF.RSLMX,CX		;; the no. of ram slots supported
	CMP	CX,RMMAX[DI]		;;
	JNB	DEFBUF_DONE		;;
	MOV	AX,RMMAX[DI]		;;
	MOV	BUF.RSLMX,AX		;; the max. of .RAMMX and .RBUFMX
					;;
DEFBUF_DONE :				;;
	MOV	BUF.STATE,CPSW		;; the LPTn is CPSW ----- STATE
					;;
	CMP	BUF.BFLAG,BF_PRN	;;
	JNE	RET_CHK_DID		;;
	MOV	AX,DID_BIT[DI]		;;
	MOV	BUF.DID_PRN,AX		;;
					;;
					;;
	JMP	RET_CHK_DID		;;
					;;
LPT_FAIL:				;;
					;;
	MOV	BUF.STATE,NORMAL	;; the LPTn is NORMAL --- STATE
					;;
					;;
RET_CHK_DID:				;;
					;;
	pop	dx			;;
	pop	di			;;
	pop	cx			;;
					;;
	RET				;;
					;;
CHK_DID ENDP				;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Called by INIT to check for consistency between duplicated device name and
;;	between PRN and LPT1
;;
;; at entry :  DI = pointer to PAR_DEVOT
;;	       BUF.STATE = any state
;;	       CX = DID order
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
DEV_CHECK PROC				;;
					;;
	LEA	SI,BUF.PAR_EXTRACTO	;;
					;;
	PUSH	CX			;;
					;;
	PUSH	SI			;; compare device id
	PUSH	DI			;;
	mov	SI,[SI].PAR_DIDO	;;
	MOV	DI,PSE.PAR_DIDO 	;;
	MOV	CX,PSE.PAR_DNML 	;;
	INC	CX			;; including length
	INC	CX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	Jz	hwcp_check		;;
	mov	init_chk,0021h		;; error 0021h
	Jmp	FORCE_LPT_BAD		;;
					;;
hwcp_check :				;;
	PUSH	SI			;; compare HWCP
	PUSH	DI			;;
	mov	SI,[SI].PAR_HWCPO	;;
	MOV	DI,PSE.PAR_HWCPO	;;
	MOV	AX,PSE.PAR_HWCPL	;;
	MOV	CX,2			;;
	SHL	AX,CL			;; multiply by two
	INC	AX			;; including length
	INC	AX			;;
	MOV	CX,AX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	Jz	desig_check		;;
	mov	init_chk,0022h		;; error 0022h
	Jmp	FORCE_LPT_BAD		;;
					;;
desig_check :				;;
	PUSH	SI			;; compare DESIGNATE
	PUSH	DI			;;
	mov	SI,[SI].PAR_DESGO	;;
	MOV	DI,PSE.PAR_DESGO	;;
	MOV	AX,PSE.PAR_DESGL	;;
	MOV	CX,2			;;
	SHL	AX,CL			;; multiply by two
	INC	AX			;; including length
	INC	AX			;;
	MOV	CX,AX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	Jz	param_check		;;
	mov	init_chk,0023h		;; error 0023h
	Jmp	FORCE_LPT_BAD		;;
					;;
param_check :				;;
	PUSH	SI			;; compare parameters
	PUSH	DI			;;
	mov	SI,[SI].PAR_PARMO	;;
	MOV	DI,PSE.PAR_PARMO	;;
	MOV	CX,PSE.PAR_PARML	;;
	INC	CX			;; including length
	INC	CX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	JZ	M_END			;;
	mov	init_chk,0024h		;; error 0024h
					;;
FORCE_LPT_BAD : 			;; the second set of parameters is
	MOV	BUF.STATE,NORMAL	;; bad
					;;
	CMP	BUF.BFLAG,BF_LPT1	;;
	JNE	M_END			;;
					;;
					;; since LPT1 is bad, force PRN to bad
	push	bx			;; force prn to be bad too
	mov	bx,buf.prn_bufo 	;;
	MOV	BUF.STATE,NORMAL	;;
	pop	bx			;;
					;;
	mov	AX,BUF.DID_PRN		;; if PRN was not good, DID_PRN = 0
	OR	DID_FAIL,AX		;;
					;;
					;;
M_END:					;; force the good did_status to fail if
					;; STATE is bad
	POP	CX			;;
	PUSH	CX			;; order 0 to m
	MOV	AX,DID_STATUS		;;
					;;
	INC	CX			;;
	SHR	AX,CL			;;
	POP	CX			;;
	JNC	DEV_CHECK_RET		;; already failed
					;;
	CMP	BUF.STATE,CPSW		;;
	JE	DEV_CHECK_RET		;;
					;;
	    PUSH    BX			;;
	    MOV     BX,CX		;;
	    ADD     BX,BX		;;
	    MOV     AX,DID_BIT[BX]	;;
	    OR	    DID_FAIL,AX 	;; force DID to fail
	    POP     BX			;;
					;;
					;;
DEV_CHECK_RET : 			;;
					;;
	RET				;;
					;;
					;;
DEV_CHECK ENDP				;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
CSEG	ENDS
	END
