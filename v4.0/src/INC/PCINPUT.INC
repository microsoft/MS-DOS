;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Source...: PCINPUT.INC						      :
; Created..: 01-01-82							      :
; Standards: 01-07-86							      :
; Revised..: 11-17-87							      :
; Version..: PC DOS							      :
; Called as: FAR, NEAR or INT						      :
; Public as: INPUT							      :
;									      :
;-----------------------------------------------------------------------------+
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; DEFAULT								      :
;									      :
;	  Performs the following functions:				      :
;									      :
;	  - Initializes pointers and counters				      :
;	  - Initializes input buffer with default value (from screen or strg) :
;	  - Set options and display input buffer as default on screen	      :
;	  - Display field delimiters					      :
;	  - Display minus or plus sign					      :
;									      :
;									      :
; Entry:  ES:SI        = Points to current ICB				      :
;	  DS:DI        = Points to PB					      :
;									      :
;	  WR_CURSIZE   = Current cursor size				      :
;									      :
; Exit:   Default displayed						      :
;									      :
;-----------------------------------------------------------------------------+
;
DEFAULT        PROC NEAR
;
; Initialize input buffer with default buffer
;
	       PUSH BP
	       PUSH ES			     ;save registers
	       PUSH DS
	       PUSH DI
	       PUSH SI
;
	       MOV  DX,ES:[SI]+ICB_FIELDLEN  ;save for later				 ;=W
	       MOV  BX,ES:[SI]+ICB_DEFLEN    ;save for later				 ;=W
;
	       MOV  AX,ES:[SI]+ICB_DEFSEG    ;get source string segment 		 ;=W
	       MOV  DS,AX								 ;=W
;
	       MOV  AX,ES:[SI]+ICB_FIELDOFF  ;get destination offset			 ;=W
	       MOV  DI,AX								 ;=W
;
	       MOV  AX,ES:[SI]+ICB_FIELDSEG  ;get destination segment			 ;=W
	       MOV  CX,ES:[SI]+ICB_DEFOFF    ;get source string offset			 ;=W
	       MOV  SI,CX								 ;=W
	       MOV  ES,AX								 ;=W
;
	       PUSH DI
	       MOV  CX,DX		     ;clear input buffer			 ;=W
	       MOV  AL,WR_SPACE 							 ;=W
	       CLD									 ;=W
	       REP  STOSB								 ;=W
	       POP  DI
;											 ;=W
	       MOV  BP,0
	       MOV  CX,BX		     ;initialize number of bytes in		 ;=W
					     ; default string
	       CMP  CX,DX		     ;check if default string is
	       JBE  DEF10		     ; longer than input buffer
;
	       MOV  CX,DX		     ;error set to input buffer leng
	       MOV  BP,ICB_STRU 	     ;set error indicating default was
					     ; truncated
DEF10:
	       CLD
	       REP  MOVSB		     ;move default into input buffer
;
	       POP  SI			     ;restore registers
	       POP  DI
	       POP  DS
	       POP  ES
;
	       OR   ES:[SI]+ICB_STATUS,BP    ;save error status
	       POP  BP
;
; Calculate row and column of input field and set the desired display attribute
;
	       MOV  AX,ES:[SI]+ICB_ROW	     ;get input field row
	       MOV  [DI]+CR_ROW,AX
;
	       MOV  AX,ES:[SI]+ICB_COL	     ;get input field column
	       MOV  [DI]+CR_COL,AX
;
	       CALL PCROWCL_CALL	     ;calculate row and column info
					     ; return CR_RCOFF and CR_BEGROWOFF
	       MOV  AL,[DI]+WR_EATTR	     ;set the entry attribute to the
	       MOV  [DI]+WR_CATTR,AL	     ; current attribute
;
; Initialize variables for left justified field
;
	       TEST ES:[SI]+ICB_OPT1,ICB_RJU ;check if right justified
	       JNE  DEF20
;
	       MOV  [DI]+WR_LEFTCHAR,1	     ;set left character marker to
					     ;beginning of input field
	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;get max field length			 ;=W
;
	       TEST ES:[SI]+ICB_OPT3,ICB_HOR ;check if horizontal scrolling		 ;=W
	       JE   DEF15		     ;no					 ;=W
	       MOV  AX,ES:[SI]+ICB_WIDTH     ;get field width for horizontal scrolling	 ;=W
					     ;because we only show a windowful of field  ;=W
DEF15:											 ;=W
	       MOV  [DI]+WR_RIGHTCHAR,AX     ;set ptr to rightmost character		 ;=W
	       CALL CAL_COORS		     ;get end of field char, byte		 ;=W
	       JMP  DEF30		     ;and next byte positions
;
; Initialize variables for right justified field
;
DEF20:	       ;
	       ; code here
	       ;
;
; Display default even if password option is active
;
DEF30:	       PUSH ES:[SI]+ICB_OPT1	     ;save option word
;
	       TEST ES:[SI]+ICB_OPT1,ICB_PSW ;check if password option active
	       JE   DEF40
;
	       AND  ES:[SI]+ICB_OPT1,NOT ICB_PSW
					     ;set option word to force disp
					     ; of default value
DEF40:
	       MOV  AX,2		     ;set option to actually display
	       CALL WORD PTR [DI]+WR_DISPLAY ; default value in proper
					     ; justification
	       POP  ES:[SI]+ICB_OPT1	     ;restore original password
;
; Display initial cursor in proper size and location
;
	       MOV  AX,[DI]+IN_CURNOR	     ;set cursor size for replace
	       MOV  [DI]+WR_CURSIZE,AX
;
	       TEST ES:[SI]+ICB_STATUS,ICB_SINS
	       JE   DEF45		     ;check if insert is active
;
	       MOV  AX,[DI]+IN_CURINS	     ;set cursor size for insert
	       MOV  [DI]+WR_CURSIZE,AX
;
DEF45:
	       CALL CAL_COORS		     ;calculate coordinates			 ;=W
	       CALL CURSOR		     ;initialize cursor size and locat
;
; Determine if characters in input buffer are allowonce chars and set flags
;

    jmp  Def65	 ;temp until bug in allowonce scan fixed

	       PUSH ES			     ;save registers
	       PUSH SI
;
	       MOV  BX,ES		     ;set segment of ICB
	       MOV  DX,SI		     ;set offset of ICB
;
	       MOV  CX,ES:[SI]+ICB_FIELDLEN  ;get field length
;
	       PUSH ES:[SI]+ICB_FIELDOFF     ;get field offset
	       PUSH ES:[SI]+ICB_FIELDSEG     ;get field segment
	       POP  ES
	       POP  SI
;
DEF50:	       MOV  AL,ES:[SI]		     ;get character from input buffer
	       MOV  [DI]+DBC_KS,AL	     ; and set to PCINDBC PB
;
	       INC  SI			     ;point to next byte
;
	       CALL PCINDBC_CALL	     ;call PCINDBC

	       TEST [DI]+DBC_STAT,DBC_DBCS   ;check if keystroke double byte
	       JE   DEF60
;
	       CMP  CX,0		     ;if last loop is double character
	       JBE  DEF60		     ; and is missing trailing byte
					     ; then, consider a single byte
;
	       MOV  AH,ES:[SI]		     ;get character from input buffer
	       MOV  [DI]+DBC_KS,AH	     ; and set to PCINDBC PB
	       INC  SI			     ;point to next byte
	       DEC  CX			     ;adjust loop pointer for additial
					     ; character read (double byte)
;
DEF60:	       PUSH ES			     ;save registers
	       PUSH SI
;
	       MOV  ES,BX		     ;load ICB
	       MOV  SI,DX
;
	       CALL ON_ALLOWONCE	     ;Scan the allowonce string for
					     ; the character in AX and set flag
					     ; if found
	       POP  SI			     ;restore registers
	       POP  ES
;
	       LOOP DEF50		     ;get next keystroke
;
	       POP  SI			     ;restore registers
	       POP  ES
;
; Display field delimiters
;
DEF65:											 ;=W
	       MOV  AX,01		     ;assume "[ ]" as delimiters                 ;=W
;											 ;=W
	       TEST ES:[SI]+ICB_OPT1,ICB_BEN ;display entry delimiters			 ;=W
	       JE   DEF100		     ;no, leave 				 ;=W
;											 ;=W
	       TEST ES:[SI]+ICB_OPT3,ICB_WIN ;does field use windowing			 ;=W
	       JE   DEF70		     ;no, check others				 ;=W
;											 ;=W
	       TEST ES:[SI]+ICB_OPT1,ICB_BOX ;check if delimiter = box			 ;=W
	       JE   DEF90		     ;no, display normal delimiters		 ;=W
;											 ;=W
	       MOV  AX,06		     ;display box				 ;=W
	       JMP  DEF90		     ;done with delimiters			 ;=W
DEF70:											 ;=W
	       TEST ES:[SI]+ICB_OPT3,ICB_HOR ;does field use horiz. window		 ;=W
	       JE   DEF80								 ;=W
;											 ;=W
	       MOV  AX,03		     ;display "[ >"                              ;=W
	       CMP  ES:[SI]+ICB_HRSTART,01H  ;are we at beginning of window ?		 ;=W
	       JLE  DEF80		     ;yes					 ;=W
;
	       MOV  AX,04		     ;no, display "< >"                          ;=W
DEF80:											 ;=W
	       CALL DELIMITER		     ;do it					 ;=W
;
	       TEST ES:[SI]+ICB_OPT1,ICB_BOX ;check if also need box			 ;=W
	       JE   DEF100								 ;=W
;											 ;=W
	       MOV  AX,06		     ;display box				 ;=W
DEF90:											 ;=W
	       CALL DELIMITER		     ;do it					 ;=W
;
; Display minus or plus sign if active
;
DEF100:
	       TEST ES:[SI]+ICB_OPT1,ICB_MUS ;Check if minus/plus sign
	       JE   DEFEXIT		     ; display option is active
;
	       MOV  [DI]+WR_KEYCONF,0	     ;initialize to plus sign key
;
	       TEST ES:[SI]+ICB_OPT1,ICB_SMU ;Check if default is negative
	       JE   DEF110
;
	       OR   [DI]+WR_KEYCONF,WR_MUS   ;initialize to minus sign key
;
DEF110:        CALL PLUS_MINUS		     ;display plus or minus sign and
					     ; set status
;
DEFEXIT:				     ;continue
;
	       RET
DEFAULT        ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; PRE_EXIT								      :
;									      :
;	  Performs the following functions:				      :
;									      :
;	  - Removes field delimiters					      :
;	  - Inserts commas as specified 				      :
;	  - Inserts decimal point as specified				      :
;	  - Adjusts field to specified significant digits		      :
;	  - Displays buffer contents in exit color			      :
;	  - Checks if original default has changed			      :
;	  - Check if entry is in specified numeric range		      :
;	  - Sets minus or plus sign indicator in exit color		      :
;	  - Remove thousand separators from input string buffer 	      :
;	  - Restore original cursor position and size, only in text mode      :
;									      :
; Entry:  ES:SI        = Points to current ICB				      :
;	  DS:DI        = Points to PB					      :
;									      :
; Exit:   None								      :
;									      :
;-----------------------------------------------------------------------------+
;
PRE_EXIT       PROC NEAR

;
; Inserts commas as specified
;
	       ;
	       ; Code here
	       ;
;
; Inserts decimal point as specified
;
	       ;
	       ; Code here
	       ;
;
; Adjusts field to specified significant digits
;
	       ;
	       ; Code here
	       ;
;
; Calculate color attribute of exit colors
;
	       TEST ES:[SI]+ICB_OPT1,ICB_XCL ;check if option to use exit
	       JE   PRE10		     ; colors is active
;
	       MOV  AL,[DI]+WR_XATTR	     ;set the exit attribute to the
	       MOV  [DI]+WR_CATTR,AL	     ; current attribute
;
; Display default value of input buffer in proper justification
;
PRE10:	       MOV  [DI]+WR_LEFTCHAR,1	     ;set left character
	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;set right marker
;
	       TEST ES:[SI]+ICB_OPT3,ICB_HOR ;horizontal scrolling mode ?		 ;=W
	       JE   PRE15		     ;no, display all buffer			 ;=W
	       MOV  AX,ES:[SI]+ICB_WIDTH     ;use width instead of all buffer		 ;=W
PRE15:
	       MOV  [DI]+WR_RIGHTCHAR,AX
;
	       MOV  AX,2		     ;set option to actually display
	       CALL WORD PTR [DI]+WR_DISPLAY ; default value in proper
;					     ; justification
; Process minus/plus key options
;
	       TEST ES:[SI]+ICB_OPT1,ICB_MUS ;Check if minus/plus sign
	       JE   PRE40		     ; display option is active
;
	       MOV [DI]+WR_KEYCONF,0	     ;initialize to plus sign
;
	       TEST ES:[SI]+ICB_STATUS,ICB_SMUS
	       JE   PRE20		     ;Check if sign is negative
;
	       OR   [DI]+WR_KEYCONF,WR_MUS   ;initialize to minus sign key
;
PRE20:	       TEST ES:[SI]+ICB_STATUS,ICB_SPUS
	       JE   PRE30		     ;Check if sign is positive
;
	       OR   [DI]+WR_KEYCONF,WR_PUS   ;initialize to plus sign key
;
PRE30:	       CALL PLUS_MINUS		     ;display plus or minus sign
					     ; according to WR_KEYCONF setting
;
; Replace field entry delimiters with exit delimiters
;
PRE40:	       TEST ES:[SI]+ICB_OPT1,ICB_BEX ;check if field delimiters
	       JE   PRE60		     ; should be displayed on exit
;
	       MOV  AX,2		     ;option to remove delimiters
	       CALL DELIMITER		     ;display delimiters
;
	       TEST ES:[SI]+ICB_OPT1,ICB_BOX ;check if box around field
	       JE   PRE60		     ; should be displayed
;
	       MOV  AX,7		     ;set option to remove box
	       CALL DELIMITER		     ;display delimiters
;
; Check if default value has changed and set return flag
;
PRE60:	       PUSH DS			     ;save registers
	       PUSH SI
	       PUSH ES
	       PUSH DI
;
	       MOV  CX,ES:[SI]+ICB_DEFLEN    ;initialize to default length
	       CMP  CX,ES:[SI]+ICB_FIELDLEN  ;check if default length is less
	       JBE  PRE70		     ; than field length
;
	       MOV  CX,ES:[SI]+ICB_FIELDLEN  ;initialize to field length
;
PRE70:	       MOV  AX,ES:[SI]+ICB_DEFSEG    ;compare default string to 		 ;=W
	       MOV  DS,AX								 ;=W
	       MOV  AX,ES:[SI]+ICB_FIELDOFF						 ;=W
	       MOV  DI,AX								 ;=W
;
	       MOV  AX,ES:[SI]+ICB_DEFOFF    ;	current input string			 ;=W
	       MOV  BX,ES:[SI]+ICB_FIELDSEG						 ;=W
	       MOV  ES,BX								 ;=W
	       MOV  SI,AX								 ;=W
;
	       REPE CMPSB		     ;compare default and input strings
;
	       POP  DI			     ;restore registers
	       POP  ES
	       POP  SI
	       POP  DS
;
	       CMP  CX,0		     ;are we done ?				 ;=W
	       JE   PRE80		     ;check if strings compared
;
	       OR   ES:[SI]+ICB_STATUS,ICB_SDEF
					     ;set flag that default changed
;
; Check if entry is within specified numeric range, if not set flag
;
PRE80:	       ;
	       ; code here
	       ;
;
; Remove thousand separators if specified from input string buffer
;
PRE90:	       ;
	       ; code here
	       ;
;
; Restore original cursor position and size
;
PRE95:
	       TEST ES:[SI]+ICB_STATUS,ICB_CUR_ON  ;is cursor on ?
	       JE   PRE100			   ;no, quit
	       CALL CURSOR		     ;erase the graphics cursor
PRE100:
	       OR   ES:[SI]+ICB_STATUS,ICB_DONE ;exit condition found, exit		 ;=W
;											 ;=W
; Check if ICB_SAV option selected. If selected, then save contents of the		 ;=W
; input buffer to the default buffer.							 ;=W
;											 ;=W
	       TEST ES:[SI]+ICB_OPT4,ICB_SAV ;check ?					 ;=W
	       JE   PRE200		     ;no, exit now				 ;=W
;											 ;=W
	       PUSH ES			     ;save registers				 ;=W
	       PUSH DS									 ;=W
	       PUSH DI									 ;=W
	       PUSH SI									 ;=W
;											 ;=W
	       MOV  CX,ES:[SI]+ICB_ENDBYTE   ;# of bytes to copy from input		 ;=W
					     ; buffer to default buffer 		 ;=W
	       MOV  ES:[SI]+ICB_DEFLEN,CX    ;reset default length
;
	       MOV  AX,ES:[SI]+ICB_FIELDSEG  ;get destination segment			 ;=W
	       MOV  DS,AX								 ;=W
;											 ;=W
	       MOV  AX,ES:[SI]+ICB_DEFOFF    ;get source string offset			 ;=W
	       MOV  DI,AX								 ;=W
;											 ;=W
	       MOV  AX,ES:[SI]+ICB_DEFSEG    ;get source string segment 		 ;=W
	       MOV  BX,ES:[SI]+ICB_FIELDOFF  ;get destination offset			 ;=W
	       MOV  SI,BX								 ;=W
	       MOV  ES,AX								 ;=W
;											 ;=W
	       CLD									 ;=W
	       REP  MOVSB		     ;move default into input buffer		 ;=W
;											 ;=W
	       POP  SI			     ;restore registers 			 ;=W
	       POP  DI									 ;=W
	       POP  DS									 ;=W
	       POP  ES									 ;=W
PRE200: 										 ;=W
	       RET
PRE_EXIT       ENDP
;											 ;=W
PAGE											 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;									      : 	 ;=W
; RIGHT_H_JUST								      : 	 ;=W
;									      : 	 ;=W
;	  Process keystroke and update display with input buffer changes      : 	 ;=W
;	  for the following functions:					      : 	 ;=W
;									      : 	 ;=W
;	  Home key	  Up arrow	  Allowonce replace mode	      : 	 ;=W
;	  End key	  Down arrow	  Allowonce insert mode 	      : 	 ;=W
;	  Left arrow	  Control end	  Allow replace mode		      : 	 ;=W
;	  Right arrow	  Delete key	  Allow insert mode		      : 	 ;=W
;									      : 	 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;											 ;=W
RIGHT_H_JUST   PROC NEAR								 ;=W
;											 ;=W
	       ;									 ;=W
	       ; code here								 ;=W
	       ;									 ;=W
;											 ;=W
	       RET									 ;=W
RIGHT_H_JUST   ENDP									 ;=W
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; RIGHT_JUST								      :
;									      :
;	  Process keystroke and update display with input buffer changes      :
;	  for the following functions:					      :
;									      :
;	  Home key	  Up arrow	  Allowonce replace mode	      :
;	  End key	  Down arrow	  Allowonce insert mode 	      :
;	  Left arrow	  Control end	  Allow replace mode		      :
;	  Right arrow	  Delete key	  Allow insert mode		      :
;									      :
;-----------------------------------------------------------------------------+
;
RIGHT_JUST     PROC NEAR
;
	       ;
	       ; code here
	       ;
;
	       RET
RIGHT_JUST     ENDP
;											 ;=W
PAGE											 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;									      : 	 ;=W
; LEFT_H_JUST								      : 	 ;=W
;									      : 	 ;=W
;	  Process keystroke and update display with input buffer changes      : 	 ;=W
;	  for the following functions:					      : 	 ;=W
;									      : 	 ;=W
;	  Home key	  Up arrow	  Allowonce replace mode	      : 	 ;=W
;	  End key	  Down arrow	  Allowonce insert mode 	      : 	 ;=W
;	  Left arrow	  Control end	  Allow replace mode		      : 	 ;=W
;	  Right arrow	  Delete key	  Allow insert mode		      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
;	  Following information is used:				      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
;	    ÚÄ (ICB_FIELDSEG:ICB_FIELDOFF) Beginning address of input	      : 	 ;=W
;	    ³				   buffer in memory.		      : 	 ;=W
;	    ³								      : 	 ;=W
;	    ³		ÚÄ (WR_CUBYTE)	 Byte offset into the input buffer    : 	 ;=W
;	    ³		³		 of where characters will be added    : 	 ;=W
;	    ³		³		 to input buffer.		      : 	 ;=W
;	    ³		³						      : 	 ;=W
;	  ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;	  ³ S ³ L ³ T ³ L ³ T ³ S ³ S ³   ³   ³   ³   ³   ³   ³   ³	      : 	 ;=W
;	  ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ	      : 	 ;=W
;	    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	      : 	 ;=W
;				     ³					      : 	 ;=W
;		 (ICB_FIELDLEN) Length of input field in bytes. 	      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
;	  The following demonstrates the before and after input buffer	      : 	 ;=W
;	  images.  (S = Single byte, L = DBCS lead byte, T = DBCS trailing    : 	 ;=W
;	  byte) 							      : 	 ;=W
;									      : 	 ;=W
;	  Deleting a double byte:					      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ S ³	³   ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Deleting a single byte:					      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ S ³ L ³ T ³   ³ S ³ L ³ T ³ L ³ T ³   ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Backspace removal of a double byte:				      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ S ³	³   ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Backspace removal of a single byte:				      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ S ³ S ³ S ³ L ³ T ³   ³ S ³ S ³ S ³ L ³ T ³   ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÁÄÄÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Replacing a double byte with a double byte:			      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ L ³ T ³ S ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Replacing a double byte with a single byte: (Option 1)	      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ S ³ S ³   ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Replacing a double byte with a single byte: (Option 2)	      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ S ³	³ S ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Replacing a single byte with a single byte:			      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ S ³ L ³ T ³   ³ S ³ L ³ T ³ S ³ L ³ T ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Replacing a single byte with a double byte.			      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ S ³   ³	³   ³ S ³ L ³ T ³ L ³ T ³   ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Replacing a single byte with a double byte without enough buffer:   : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ S ³ L ³ T ³   ³ S ³ L ³ T ³ S ³ L ³ T ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Inserting a single byte.					      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ L ³ T ³	³   ³ S ³ L ³ T ³ S ³ L ³ T ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Inserting a single byte without enough buffer generate an error:    : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ L ³ T ³ S ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ	      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ S ³ S ³	³   ³ S ³ L ³ T ³ S ³ S ³   ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ	      : 	 ;=W
;									      : 	 ;=W
;	  Inserting a double byte character:				      : 	 ;=W
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;		³ S ³ L ³ T ³ S ³   ³	³   ³ S ³ L ³ T ³ L ³ T ³ S ³	      : 	 ;=W
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÙ	      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
; Entry:  ES:SI       = Points to current ICB				      : 	 ;=W
;	  DS:DI       = Points to PB					      : 	 ;=W
;									      : 	 ;=W
;	  INC_KS      = Keystroke from returned from PCINCHA		      : 	 ;=W
;									      : 	 ;=W
;	  WR_KEYCONF  = Bit flag inidicating the options set for INC_KS       : 	 ;=W
;	  WR_KEYCONF2	keystroke.					      : 	 ;=W
;									      : 	 ;=W
; Exit:   None. 							      : 	 ;=W
;									      : 	 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;											 ;=W
LEFT_H_JUST    PROC NEAR								 ;=W
;											 ;=W
; Initialize right and left boundary markers						 ;=W
;											 ;=W
	       TEST [DI]+WR_KEYCONF,WR_MASK  ;check to see if editing key entered	 ;=W
	       JNE  LHJ5		     ;yes, must check for editing keys		 ;=W
	       JMP  LHJ190		     ;no, skip checks for editing keys		 ;=W
											 ;=W
;											 ;=W
; Process home key									 ;=W
;											 ;=W
LHJ5:	       TEST [DI]+WR_KEYCONF,WR_HOM   ;check if home key pressed 		 ;=W
	       JE   LHJ10								 ;=W
;											 ;=W
	       ;									 ;=W
	       ; add ICB_WHM option to process window home key movement 		 ;=W
	       ;									 ;=W
;											 ;=W
	       MOV  ES:[SI]+ICB_CURCHAR,1    ;initialize cursor to 1st byte		 ;=W
					     ; position, assuming no windowing		 ;=W
					     ; wrap is occurring			 ;=W
	       MOV  [DI]+WR_HRCHAR,1	     ;reset the horiz. window			 ;=W
	       CALL CAL_COORS		     ;calculate cursor position 		 ;=W
	       MOV  AX,3		     ;display delimiters "[ >"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       JMP  LHJEXIT		     ; returns WR_CURROW, WR_CURROW		 ;=W
					     ; and WR_CUBYTE				 ;=W
;											 ;=W
; Process end key									 ;=W
;											 ;=W
LHJ10:	       TEST [DI]+WR_KEYCONF,WR_END   ;check if home key pressed 		 ;=W
	       JNE  LHJ12								 ;=W
	       JMP  LHJ20
LHJ12:											 ;=W
	       ;									 ;=W
	       ; add ICB_WEN to move cursor to end of current window row		 ;=W
	       ;									 ;=W
;											 ;=W
	       CALL CAL_COORS		     ;get current end of field info		 ;=W
	       MOV  AX,[DI]+WR_ENCHAR	     ;adjust one past end buffer charac 	 ;=W
	       INC  AX									 ;=W
	       MOV  ES:[SI]+ICB_CURCHAR,AX   ;set current cursor position to		 ;=W
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       MOV  AX,4		     ;display delimiters "< >"                   ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LHJ17		     ;no					 ;=W
	       MOV  AX,5		     ;display delimiters "< ]"                   ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LHJ15
	       MOV  ES:[SI]+ICB_CURCHAR,1    ;wrap to first character position
	       MOV  [DI]+WR_HRCHAR,1	     ;reset the horiz. window			 ;=W
	       MOV  AX,3		     ;display delimiters "[ >"                   ;=W
	       JMP  LHJ19		     ;exit
LHJ15:
	       TEST ES:[SI]+ICB_OPT2,ICB_AXC ;is autoexit option set ?			 ;=W
	       JE   LHJ16		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;yes, set autoexit flag			 ;=W
LHJ16:											 ;=W
	       MOV  BX,ES:[SI]+ICB_FIELDLEN  ;adjust horizontal window			 ;=W
	       SUB  BX,ES:[SI]+ICB_WIDTH     ;(below this line may not work for 	 ;=W
	       INC  BX			     ; DBCS support)				 ;=W
	       MOV  [DI]+WR_HRCHAR,BX							 ;=W
	       JMP  LHJ19								 ;=W
LHJ17:											 ;=W
	       MOV  CX,[DI]+WR_CUBYTE	     ;check if need to adjust horz.		 ;=W
	       CMP  CX,ES:[SI]+ICB_WIDTH     ; window					 ;=W
	       JA   LHJ18								 ;=W
	       MOV  [DI]+WR_HRCHAR,1							 ;=W
	       MOV  AX,3		     ;display delimiters "[ >"                   ;=W
	       JMP  LHJ19								 ;=W
LHJ18:											 ;=W
	       MOV  BX,[DI]+WR_ENBYTE	     ;yes, adjust it				 ;=W
	       SUB  BX,ES:[SI]+ICB_WIDTH						 ;=W
	       ADD  BX,2								 ;=W
	       MOV  [DI]+WR_HRCHAR,BX							 ;=W
LHJ19:											 ;=W
	       CALL CAL_COORS		     ;re-calculate display			 ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       JMP  LHJEXIT		     ;exit					 ;=W
;											 ;=W
; Process left arrow									 ;=W
;											 ;=W
LHJ20:	       TEST [DI]+WR_KEYCONF,WR_LFT   ;check if left arrow key pressed		 ;=W
	       JE   LHJ40								 ;=W
;											 ;=W
	       ;									 ;=W
	       ; add ICB_CSW option to wrap cursor from top/bottom end to end		 ;=W
	       ;									 ;=W
;											 ;=W
	       ;									 ;=W
	       ; add ICB_WAR option to wrap cursor on same row end to end		 ;=W
	       ;									 ;=W
;											 ;=W
	       MOV  BX,ES:[SI]+ICB_CURCHAR   ;get cursor position			 ;=W
	       CMP  BX,1		     ;is cursor in first position ?		 ;=W
	       JA   LHJ30		     ;no					 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LHJ23
	       MOV  BX,ES:[SI]+ICB_FIELDLEN  ;adjust horizontal window			 ;=W
	       MOV  ES:[SI]+ICB_CURCHAR,BX   ;wrap to first character position
	       SUB  BX,ES:[SI]+ICB_WIDTH     ;(below this line may not work for 	 ;=W
	       INC  BX			     ; DBCS support)				 ;=W
	       MOV  [DI]+WR_HRCHAR,BX							 ;=W
;
	       MOV  AX,5		     ;display delimiters "< ]"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       JMP  LHJ32		     ;exit
LHJ23:
	       MOV  AX,3		     ;display delimiters "[ >"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_AXC ;is autoexit option set ?			 ;=W
	       JE   LHJ25		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;yes, set autoexit flag			 ;=W
	       JMP  LHJ400								 ;=W
LHJ25:											 ;=W
	       CALL PCMBEEP_CALL	     ;error beep				 ;=W
	       JMP  LHJEXIT		     ;exit					 ;=W
LHJ30:											 ;=W
	       DEC  ES:[SI]+ICB_CURCHAR      ;adjust cursor to one position		 ;=W
;
	       CMP  BX,[DI]+WR_HRCHAR	     ;is cursor to the left of horz.wind. ?	 ;=W
	       JG   LHJ32		     ;no					 ;=W
	       DEC  [DI]+WR_HRCHAR	     ;yes, adjust horiz. window 		 ;=W
	       MOV  AX,4		     ;display delimiters "< >"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
LHJ32:					     ; towards the left 			 ;=W
	       CALL CAL_COORS		     ;calculate cursor position
	       JMP  LHJEXIT		     ;exit					 ;=W
;											 ;=W
; Process right arrow									 ;=W
;											 ;=W
LHJ40:	       TEST [DI]+WR_KEYCONF,WR_RGT   ;check if left arrow key pressed		 ;=W
	       JE   LHJ60								 ;=W
;											 ;=W
	       ;									 ;=W
	       ; add ICB_WAR option to wrap cursor on same row end to end		 ;=W
	       ;									 ;=W
;											 ;=W
	       CALL CAL_COORS		     ;get cursor position			 ;=W
;											 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LHJ50								 ;=W
;											 ;=W
	       MOV  AX,5		     ;display delimiters "< ]"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       CALL PCMBEEP_CALL	     ;error beep				 ;=W
	       JMP  LHJEXIT		     ;exit					 ;=W
;											 ;=W
LHJ50:	       INC  ES:[SI]+ICB_CURCHAR      ;adjust cursor to one position		 ;=W
					     ; towards the right			 ;=W
	       MOV  BX,[DI]+WR_HRCHAR	     ;get begin. of horiz. wondow		 ;=W
	       ADD  BX,ES:[SI]+ICB_WIDTH     ;add width to get end of window		 ;=W
	       CMP  BX,ES:[SI]+ICB_CURCHAR   ;is cursor past end of window ?		 ;=W
	       JG   LHJ52		     ;no					 ;=W
	       INC  [DI]+WR_HRCHAR	     ;yes, adjust the horiz. window		 ;=W
	       MOV  AX,4		     ;display delimiters "< >"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
LHJ52:											 ;=W
	       CALL CAL_COORS		     ;calculate cursor position 		 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LHJ55		     ;no					 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LHJ53
	       MOV  ES:[SI]+ICB_CURCHAR,1    ;wrap to first character position
	       MOV  [DI]+WR_HRCHAR,1	     ;reset the horiz. window			 ;=W
	       MOV  AX,3		     ;display delimiters "[ >"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       JMP  LHJ55		     ;exit
LHJ53:
	       DEC  [DI]+WR_HRCHAR	     ;yes, adjust wind back one position	 ;=W
	       MOV  AX,5		     ;display delimiters "< ]"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_AXC ;is autoexit option set ?			 ;=W
	       JE   LHJ55		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;set autoexit flag 			 ;=W
LHJ55:											 ;=W
	       CALL CAL_COORS		     ;calculate cursor position 		 ;=W
	       JMP  LHJEXIT		     ;exit					 ;=W
;											 ;=W
; Process up arrow									 ;=W
;											 ;=W
LHJ60:	       ;									 ;=W
	       ; adjust cursor position 						 ;=W
	       ;									 ;=W
											 ;=W
	       ;									 ;=W
	       ; check for field wrap, exit, error beep 				 ;=W
	       ;									 ;=W
;											 ;=W
; Process down arrow									 ;=W
;											 ;=W
LHJ70:	       ;									 ;=W
	       ; adjust cursor position 						 ;=W
	       ;									 ;=W
											 ;=W
	       ;									 ;=W
	       ; check for field wrap, exit, error beep 				 ;=W
	       ;									 ;=W
;											;=W
; Process cntrl+end key 								 ;=W
;											 ;=W
LHJ80:	       TEST [DI]+WR_KEYCONF,WR_CED   ;check if control+end key pressed		 ;=W
	       JE   LHJ100								 ;=W
;											 ;=W
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LHJ90								 ;=W
;											 ;=W
	       CALL PCMBEEP_CALL	     ;error beep				 ;=W
	       JMP  LHJEXIT		     ;exit					 ;=W
LHJ90:
	       MOV  BX,[DI]+WR_CUBYTE	     ;delete from current byte position 	 ;=W
	       CALL CLEAR_BUFFER							 ;=W
;											 ;=W
	       CALL CAL_COORS		     ;calculate cursor position
	       JMP  LHJEXIT		     ;display field, set cursor, exit		 ;=W
;											 ;=W
; Process delete key									 ;=W
;											 ;=W
LHJ100:        TEST [DI]+WR_KEYCONF,WR_DEL   ;check if delete key pressed		 ;=W
	       JE   LHJ130								 ;=W
;											 ;=W
	       ;									 ;=W
	       ; Add ICB_WDL option in off state to delete on current line only 	 ;=W
	       ;									 ;=W
;											 ;=W
	       CALL CAL_COORS		     ;get cursor position			 ;=W
;											 ;=W
	       CMP  [DI]+WR_FIELDEND,1	     ;check if cursor past end of field 	 ;=W
	       JE   LHJ110								 ;=W
;											 ;=W
	       CALL REMOVE_CHAR 	     ;remove character at current offst 	 ;=W
					     ; and shift remaining in place		 ;=W
	       CALL CAL_COORS		     ;calculate cursor position
	       JMP  LHJEXIT		     ;display field, set cursor, exit		 ;=W
;											 ;=W
LHJ110:        CALL PCMBEEP_CALL	     ;error beep				 ;=W
	       JMP  LHJEXIT		     ;exit					 ;=W
;											 ;=W
; Process backspace key 								 ;=W
;											 ;=W
LHJ130:        TEST [DI]+WR_KEYCONF,WR_BCK   ;check if backspace key pressed		 ;=W
	       JE   LHJ160								 ;=W
;											 ;=W
	       MOV  BX,ES:[SI]+ICB_CURCHAR   ;get cursor position			 ;=W
	       CMP  BX,1		     ;check if cursor is at first		 ;=W
	       JA   LHJ140		     ; field position				 ;=W
;
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LHJ133
	       MOV  BX,ES:[SI]+ICB_FIELDLEN  ;adjust horizontal window			 ;=W
	       MOV  ES:[SI]+ICB_CURCHAR,BX   ;wrap to first character position
	       SUB  BX,ES:[SI]+ICB_WIDTH     ;(below this line may not work for 	 ;=W
	       INC  BX			     ; DBCS support)				 ;=W
	       MOV  [DI]+WR_HRCHAR,BX							 ;=W
;
	       MOV  AX,5		     ;display delimiters "< ]"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       JMP  LHJ145		     ;exit
LHJ133:
	       MOV  AX,3		     ;display delimiters "[ >"                   ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_AXC ;is autoexit option set ?			 ;=W
	       JE   LHJ135		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;yes, set autoexit flag			 ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       JMP  LHJ400								 ;=W
LHJ135: 										 ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       CALL PCMBEEP_CALL	     ;error beep				 ;=W
	       JMP  LHJEXIT		     ;exit					 ;=W
LHJ140: 										 ;=W
	       DEC  ES:[SI]+ICB_CURCHAR      ;adjust cursor to one position
					     ; towards the left 			 ;=W
	       CMP  BX,[DI]+WR_HRCHAR	     ;is cursor in front of the wind. ? 	 ;=W
	       JG   LHJ142		     ;no					 ;=W
	       DEC  [DI]+WR_HRCHAR	     ;yes, adjust the horiz. window		 ;=W
	       MOV  AX,4		     ;display delimiters "< >"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
LHJ142: 										 ;=W
;											 ;=W
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CALL REMOVE_CHAR 	     ;remove character at current offst 	 ;=W
					     ; and shift remaining in place		 ;=W
LHJ145: 										 ;=W
	       CALL CAL_COORS		     ;calculate cursor position
	       JMP  LHJEXIT		     ;display field, set cursor, exit		 ;=W
;											 ;=W
; Process insert key toggle								 ;=W
;											 ;=W
LHJ160:        TEST [DI]+WR_KEYCONF,WR_INS   ;check if insert key pressed		 ;=W
	       JE   LHJ180		     ; if not, continue 			 ;=W
;											 ;=W
	       TEST ES:[SI]+ICB_STATUS,ICB_SINS  ;check if in insert mode ?		 ;=W
	       JE   LHJ165		     ;no, put in insert mode			 ;=W
;											 ;=W
	       MOV  BX,[DI]+IN_CURNOR	     ;set cursor size for normal		 ;=W
	       MOV  [DI]+WR_CURSIZE,BX	     ; cursor					 ;=W
;											 ;=W
	       AND  ES:[SI]+ICB_STATUS,NOT ICB_SINS					 ;=W
	       JMP  LHJ170		     ;turn insert mode off			 ;=W
;											 ;=W
LHJ165:        MOV  BX,[DI]+IN_CURINS	     ;set cursor size for insert		 ;=W
	       MOV  [DI]+WR_CURSIZE,BX	     ; cursor					 ;=W
;											 ;=W
	       OR   ES:[SI]+ICB_STATUS,ICB_SINS 					 ;=W
					     ;turn insert mode on			 ;=W
;											 ;=W
LHJ170: 										 ;=W
;											 ;=W
	       PUSH DS			     ;save registers				 ;=W
	       PUSH DI									 ;=W
;											 ;=W
	       MOV  DI,40H		     ;point DS:DI to KB_FLAG in BIOS		 ;=W
	       MOV  DS,DI								 ;=W
	       MOV  DI,17H								 ;=W
	       MOV  AX,[DI]		     ;get current BIOS KB_FLAG			 ;=W
;											 ;=W
	       AND  AX,NOT WR_INSSTATE	     ;set BIOS insert active flag off		 ;=W
;											 ;=W
	       TEST ES:[SI]+ICB_STATUS,ICB_SINS 					 ;=W
	       JE   LHJ175		     ;check if insert should be set on		 ;=W
;											 ;=W
	       OR   AX,WR_INSSTATE	     ;set BIOS insert active flag on		 ;=W
;											 ;=W
LHJ175:        POP  DI			     ;restore registers 			 ;=W
	       POP  DS									 ;=W
;											 ;=W
	       JMP  LHJEXIT		     ;exit					 ;=W
;											 ;=W
; Process allowonce key option								 ;=W
;											 ;=W
LHJ180:        ;									 ;=W
	       ; insert or replace							 ;=W
	       ;									 ;=W
;											 ;=W
	       ;									 ;=W
	       ; adjust input buffer							 ;=W
	       ;									 ;=W
;											 ;=W
	       ;									 ;=W
	       ; check for field wrap, exit, error beep 				 ;=W
	       ;									 ;=W
;											 ;=W
	       ;									 ;=W
	       ; adjust cursor position 						 ;=W
	       ;									 ;=W
;											 ;=W
; Process allowed keystroke in replace mode						 ;=W
;											 ;=W
LHJ190:        TEST [DI]+WR_KEYCONF,WR_ALL   ;check if allow key pressed		 ;=W
	       JNE  LHJ195								 ;=W
;											 ;=W
	       CALL PCMBEEP_CALL	     ;error beep key not defined		 ;=W
	       JMP  LHJEXIT		     ;exit					 ;=W
;											 ;=W
LHJ195:        TEST ES:[SI]+ICB_STATUS,ICB_SINS 					 ;=W
	       JE   LHJ198		     ;check if insert is active 		 ;=W
;											 ;=W
	       JMP  LHJ270		     ;do insert display 			 ;=W
;											 ;=W
LHJ198: 										 ;=W
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LHJ200								 ;=W
;											 ;=W
	       CALL PCMBEEP_CALL	     ;error beep key not defined		 ;=W
	       JMP  LHJEXIT		     ;exit					 ;=W
;											 ;=W
; Check if character to be replaced in field buffer is double byte character		 ;=W
;											 ;=W
LHJ200:        PUSH ES			     ;save registers				 ;=W
	       PUSH SI									 ;=W
;											 ;=W
	       PUSH ES:[SI]+ICB_FIELDSEG     ;get segment of input buffer		 ;=W
	       PUSH ES:[SI]+ICB_FIELDOFF     ;get offset of input buffer		 ;=W
	       POP  SI									 ;=W
	       POP  ES									 ;=W
;											 ;=W
	       ADD  SI,[DI]+WR_CUBYTE	     ;add cursor offset into buffer		 ;=W
	       DEC  SI			     ;make zero based				 ;=W
;											 ;=W
	       MOV  CX,ES		     ;save offset of character to		 ;=W
	       MOV  DX,SI		     ; replace					 ;=W
;											 ;=W
	       MOV  AL,ES:[SI]		     ;get byte that cursor is pointing		 ;=W
	       MOV  [DI]+DBC_KS,AL	     ; to check if DBCS 			 ;=W
	       CALL PCINDBC_CALL	     ;call routine to check if char		 ;=W
					     ; is lead double byte char 		 ;=W
;											 ;=W
	       POP  SI			     ;restore registers 			 ;=W
	       POP  ES									 ;=W
;											 ;=W
	       TEST [DI]+DBC_STAT,DBC_DBCS   ;check if char is lead DBCS		 ;=W
	       JE   LHJ220		     ; if no, jump to single byte code		 ;=W
;											 ;=W
; Replace double byte character with double byte character				 ;=W
;											 ;=W
	       TEST [DI]+WR_KEYCONF2,WR_DBC  ;check if keystroke is DBC 		 ;=W
	       JE   LHJ210		     ;continue with single byte 		 ;=W
;											 ;=W
	       MOV  AX,[DI]+INC_KS	     ;set double byte character to		 ;=W
					     ; input buffer replacing			 ;=W
					     ; double byte character			 ;=W
	       PUSH ES									 ;=W
	       PUSH SI									 ;=W
;											 ;=W
	       MOV  ES,CX		     ;save offset of character to		 ;=W
	       MOV  SI,DX		     ; replace					 ;=W
	       MOV  ES:[SI],AX		     ;replace double byte			 ;=W
;											 ;=W
	       POP  SI			     ;restore registers 			 ;=W
	       POP  ES									 ;=W
;											 ;=W
	       JMP  LHJ260		     ;exit					 ;=W
;											 ;=W
; Replace double byte character with single byte character				 ;=W
;											 ;=W
LHJ210:        MOV  AX,[DI]+INC_KS	     ;get keystroke and replace double		 ;=W
					     ; byte with single byte			 ;=W
;											 ;=W
	       PUSH ES									 ;=W
	       PUSH SI									 ;=W
;											 ;=W
	       MOV  ES,CX		     ;save offset of character to		 ;=W
	       MOV  SI,DX		     ; replace single byte			 ;=W
	       MOV  ES:[SI],AL								 ;=W
;											 ;=W
	       POP  SI			     ;restore registers 			 ;=W
	       POP  ES									 ;=W
;											 ;=W
	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;set ending byte				 ;=W
	       MOV  [DI]+WR_RIGHTBYTE,AX						 ;=W
;											 ;=W
	       MOV  AX,[DI]+WR_CUBYTE	     ;set markers for shift to remove		 ;=W
	       INC  AX			     ;adjust past replaced leading byte 	 ;=W
	       MOV  [DI]+WR_LEFTBYTE,AX      ; trailing byte				 ;=W
;											 ;=W
	       MOV  BX,1		     ;set number of positions to shift		 ;=W
	       MOV  AX,2		     ;set option to shift left			 ;=W
	       CALL SHIFT		     ;call shift 1 position toward left 	 ;=W
	       JMP  LHJ260		     ;exit					 ;=W
;											 ;=W
; Replace single byte character with single byte character				 ;=W
;											 ;=W
LHJ220:        TEST [DI]+WR_KEYCONF2,WR_DBC  ;check if double byte character		 ;=W
	       JNE  LHJ230		     ; continue with single byte		 ;=W
;											 ;=W
	       MOV  AX,[DI]+INC_KS	     ;get keystroke				 ;=W
;											 ;=W
	       PUSH ES									 ;=W
	       PUSH SI									 ;=W
;											 ;=W
	       MOV  ES,CX		     ;save offset of character to		 ;=W
	       MOV  SI,DX		     ; replace single byte			 ;=W
	       MOV  ES:[SI],AL								 ;=W
;											 ;=W
	       POP  SI			     ;restore registers 			 ;=W
	       POP  ES									 ;=W
;											 ;=W
	       JMP  LHJ260		     ;exit					 ;=W
;											 ;=W
; Replace single byte character with double byte character				 ;=W
;											 ;=W
LHJ230: 										 ;=W
	       CALL CAL_COORS		     ;calculate cursor position 		 ;=W
	       MOV  BX,[DI]+WR_ENBYTE	     ;get end byte of input field		 ;=W
	       MOV  AX,[DI]+WR_ENCHAR	     ;get end character of field		 ;=W
	       CMP  AX,ES:[SI]+ICB_CURCHAR   ;is cursor past end character		 ;=W
	       JA   LHJ240								 ;=W
;											 ;=W
	       MOV  BX,[DI]+WR_CUBYTE	     ;set cursor character position		 ;=W
LHJ240: 										 ;=W
	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;get end of field position 		 ;=W
	       SUB  AX,BX		     ;subtract to get the remaining space	 ;=W
	       CMP  AX,1		     ;will byte fit ?				 ;=W
	       JGE  LHJ250		     ;yes					 ;=W
;											 ;=W
	       CALL PCMBEEP_CALL	     ;error beep because replace char		 ;=W
	       JMP  LHJEXIT		     ; will not fit and exit			 ;=W
;											 ;=W
LHJ250:        MOV  BX,ES:[SI]+ICB_FIELDLEN  ;set ending byte				 ;=W
	       MOV  [DI]+WR_RIGHTBYTE,BX						 ;=W
;											 ;=W
	       MOV  BX,[DI]+WR_CUBYTE	     ;set markers for shift to remove		 ;=W
	       INC  BX			     ;adjust past replaced leading byte 	 ;=W
	       MOV  [DI]+WR_LEFTBYTE,BX      ; trailing byte				 ;=W
;											 ;=W
	       MOV  BX,1		     ;set number of positions to shift		 ;=W
	       MOV  AX,1		     ;set option to shift right 		 ;=W
	       CALL SHIFT		     ;call shift 1 position toward		 ;=W
					     ; left					 ;=W
	       MOV  AX,[DI]+INC_KS	     ;get keystroke				 ;=W
;											 ;=W
	       PUSH ES									 ;=W
	       PUSH SI									 ;=W
;											 ;=W
	       MOV  ES,CX		     ;save offset of character to		 ;=W
	       MOV  SI,DX		     ; replace double byte			 ;=W
	       MOV  ES:[SI],AX								 ;=W
;											 ;=W
	       POP  SI			     ;restore registers 			 ;=W
	       POP  ES									 ;=W
;											 ;=W
; Calculate new ending and cursor coordinates						 ;=W
;											 ;=W
LHJ260: 										 ;=W
	       CALL CAL_COORS		     ;calculate cursor position 		 ;=W
	       INC  ES:[SI]+ICB_CURCHAR      ;point to next char			 ;=W
	       MOV  BX,[DI]+WR_HRCHAR	     ;get begin. of horiz. wondow		 ;=W
	       ADD  BX,ES:[SI]+ICB_WIDTH     ;add width to get end of window		 ;=W
	       CMP  BX,ES:[SI]+ICB_CURCHAR   ;is cursor past end of window ?		 ;=W
	       JG   LHJ265		     ;no					 ;=W
	       INC  [DI]+WR_HRCHAR	     ;yes, adjust the horiz. window		 ;=W
	       MOV  AX,4		     ;display delimiters "< >"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
LHJ265: 										 ;=W
	       CALL CAL_COORS		     ;calculate cursor position 		 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LHJ267		     ;no					 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LHJ266
	       MOV  ES:[SI]+ICB_CURCHAR,1    ;wrap to first character position
	       MOV  [DI]+WR_HRCHAR,1	     ;reset the horiz. window			 ;=W
	       MOV  AX,3		     ;display delimiters "[ >"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       JMP  LHJ267		     ;exit
LHJ266:

	       DEC  [DI]+WR_HRCHAR	     ;yes, adjust wind back one position	 ;=W
	       MOV  AX,5		     ;display delimiters "< ]"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_AXD ;is autoexit option set ?			 ;=W
	       JE   LHJ267		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;set autoexit flag 			 ;=W
LHJ267: 										 ;=W
	       CALL CAL_COORS		     ;calculate cursor position 		 ;=W
	       JMP  LHJEXIT		     ;display field, set cursor, exit		 ;=W
;											 ;=W
; Process allowed keystroke in insert mode						 ;=W
;											 ;=W
LHJ270: 										 ;=W
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LHJ280								 ;=W
;											 ;=W
	       CALL PCMBEEP_CALL	     ;error beep key not defined		 ;=W
	       JMP  LHJEXIT		      ;exit					 ;=W
;											 ;=W
; Check if enough room available to insert single or double byte character		 ;=W
;											 ;=W
LHJ280: 										 ;=W
	       MOV  CX,ES:[SI]+ICB_FIELDSEG  ;get segment of input buffer		 ;=W
	       MOV  DX,ES:[SI]+ICB_FIELDOFF  ;get offset of input buffer		 ;=W
;											 ;=W
	       ADD  DX,[DI]+WR_CUBYTE	     ;add cursor offset into buffer		 ;=W
	       DEC  DX			     ;make zero based				 ;=W
;											 ;=W
	       MOV  BX,1		     ;initialize to single byte 		 ;=W
;											 ;=W
	       TEST [DI]+WR_KEYCONF2,WR_DBC  ;check for double byte character		 ;=W
	       JE   LHJ290								 ;=W
;											 ;=W
	       MOV  BX,2		     ;reset to double byte character		 ;=W
LHJ290: 										 ;=W
	       PUSH BX									 ;=W
	       CALL CAL_COORS		     ;calculate cursor position 		 ;=W
	       MOV  BX,[DI]+WR_ENBYTE	     ;get end byte of input field		 ;=W
	       MOV  AX,[DI]+WR_ENCHAR	     ;get end character of field		 ;=W
	       CMP  AX,ES:[SI]+ICB_CURCHAR   ;is cursor past end character		 ;=W
	       JA   LHJ300								 ;=W
;											 ;=W
	       MOV  BX,[DI]+WR_CUBYTE	     ;set cursor character position		 ;=W
LHJ300: 										 ;=W
	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;get end of field position 		 ;=W
	       SUB  AX,BX		     ;subtract to get the remaining space	 ;=W
	       POP  BX									 ;=W
	       CMP  AX,BX		     ;will byte fit ?				 ;=W
	       JGE  LHJ310		     ;yes					 ;=W
;											 ;=W
	       CALL PCMBEEP_CALL	     ;error beep replace character		 ;=W
	       JMP  LHJEXIT		     ; will not fit and exit			 ;=W
;											 ;=W
; Shift to insert single or double byte character, BX= # bytes to shift 		 ;=W
;											 ;=W
LHJ310:        MOV  AX,ES:[SI]+ICB_FIELDLEN  ;set ending byte to make room in		 ;=W
	       MOV  [DI]+WR_RIGHTBYTE,AX     ; buffer by shifting characters		 ;=W
;											 ;=W
	       MOV  AX,[DI]+WR_CUBYTE	     ;set markers for shift to remove		 ;=W
	       MOV  [DI]+WR_LEFTBYTE,AX      ; trailing byte				 ;=W
;											 ;=W
	       MOV  AX,1		     ;set option to shift right, BX=		 ;=W
					     ; number of bytes to insert		 ;=W
	       CALL SHIFT		     ;call shift 1 position toward		 ;=W
					     ; left					 ;=W
	       MOV  AX,[DI]+INC_KS	     ;get keystroke				 ;=W
;											 ;=W
; Insert single byte character								 ;=W
;											 ;=W
	       CMP  BX,2		     ;check how many bytes should be		 ;=W
	       JE   LHJ320		     ; inserted 				 ;=W
;											 ;=W
	       PUSH ES									 ;=W
	       PUSH SI									 ;=W
;											 ;=W
	       MOV  ES,CX		     ;save offset of character to		 ;=W
	       MOV  SI,DX		     ; replace single byte			 ;=W
	       MOV  ES:[SI],AL		     ;insert single byte character		 ;=W
;											 ;=W
	       POP  SI			     ;restore registers 			 ;=W
	       POP  ES									 ;=W
;											 ;=W
	       JMP  LHJ330								 ;=W
;											 ;=W
; Insert double byte character								 ;=W
;											 ;=W
LHJ320:        PUSH ES									 ;=W
	       PUSH SI									 ;=W
;											 ;=W
	       MOV  ES,CX		     ;save offset of character to		 ;=W
	       MOV  SI,DX		     ; replace					 ;=W
	       MOV  ES:[SI],AX		     ;insert double byte character		 ;=W
;											 ;=W
	       POP  SI			     ;restore registers 			 ;=W
	       POP  ES									 ;=W
;											 ;=W
; Calculate new ending and cursor coordinates						 ;=W
;											 ;=W
LHJ330: 										 ;=W
	       CALL CAL_COORS		     ;get new end coordinates			 ;=W
;											 ;=W
	       INC  ES:[SI]+ICB_CURCHAR      ;point to next char			 ;=W
	       MOV  BX,[DI]+WR_HRCHAR	     ;get begin. of horiz. wondow		 ;=W
	       ADD  BX,ES:[SI]+ICB_WIDTH     ;add width to get end of window		 ;=W
	       CMP  BX,ES:[SI]+ICB_CURCHAR   ;is cursor past end of window ?		 ;=W
	       JG   LHJ332		     ;no					 ;=W
	       INC  [DI]+WR_HRCHAR	     ;yes, adjust the horiz. window		 ;=W
	       MOV  AX,4		     ;display delimiters "< >"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
LHJ332: 										 ;=W
	       CALL CAL_COORS		     ;calculate cursor position
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LHJ335		     ;no					 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LHJ333
	       MOV  ES:[SI]+ICB_CURCHAR,1    ;wrap to first character position
	       MOV  [DI]+WR_HRCHAR,1	     ;reset the horiz. window			 ;=W
	       MOV  AX,3		     ;display delimiters "[ >"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       JMP  LHJ335		     ;exit
LHJ333:
	       DEC  [DI]+WR_HRCHAR	     ;yes, adjust wind back one position	 ;=W
	       MOV  AX,5		     ;display delimiters "< ]"                   ;=W
	       CALL DELIMITER		     ;display delimiter 			 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_AXD ;is autoexit option set ?			 ;=W
	       JE   LHJ335		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;set autoexit flag 			 ;=W
LHJ335:
	       CALL CAL_COORS		     ;calculate cursor position 		 ;=W
	       JMP  LHJEXIT		     ;display cursor
;											 ;=W
; Display field & Exit									 ;=W
;											 ;=W
LHJ400:
	       CALL WORD PTR [DI]+WR_DISPLAY ;display current input buffer		 ;=W
					     ; in left justified field			 ;=W
	       JMP  LHJCUR
LHJEXIT:										 ;=W
	       CALL WORD PTR [DI]+WR_DISPLAY ;display current input buffer		 ;=W
					     ; in left justified field			 ;=W
	       TEST ES:[SI]+ICB_STATUS,ICB_CUR_ON ;is cursor on ?
	       JNE  LHJCUR			  ;cursor is already on, don't turn it on ;=W
	       CALL CURSOR		     ;display cursor				 ;=W
LHJCUR:
;											 ;=W
	       RET									 ;=W
LEFT_H_JUST    ENDP									 ;=W
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; LEFT_JUST								      :
;									      :
;	  Process keystroke and update display with input buffer changes      :
;	  for the following functions:					      :
;									      :
;	  Home key	  Up arrow	  Allowonce replace mode	      :
;	  End key	  Down arrow	  Allowonce insert mode 	      :
;	  Left arrow	  Control end	  Allow replace mode		      :
;	  Right arrow	  Delete key	  Allow insert mode		      :
;									      :
;									      :
;	  Following information is used:				      :
;									      :
;									      :
;	    ÚÄ (ICB_FIELDSEG:ICB_FIELDOFF) Beginning address of input	      :
;	    ³				   buffer in memory.		      :
;	    ³								      :
;	    ³		ÚÄ (WR_CUBYTE)	 Byte offset into the input buffer    :
;	    ³		³		 of where characters will be added    :
;	    ³		³		 to input buffer.		      :
;	    ³		³						      :
;	  ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;	  ³ S ³ L ³ T ³ L ³ T ³ S ³ S ³   ³   ³   ³   ³   ³   ³   ³	      :
;	  ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ	      :
;	    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	      :
;				     ³					      :
;		 (ICB_FIELDLEN) Length of input field in bytes. 	      :
;									      :
;									      :
;	  The following demonstrates the before and after input buffer	      :
;	  images.  (S = Single byte, L = DBCS lead byte, T = DBCS trailing    :
;	  byte) 							      :
;									      :
;	  Deleting a double byte:					      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ S ³	³   ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ	      :
;									      :
;	  Deleting a single byte:					      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ S ³ L ³ T ³   ³ S ³ L ³ T ³ L ³ T ³   ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ	      :
;									      :
;	  Backspace removal of a double byte:				      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ S ³	³   ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ	      :
;									      :
;	  Backspace removal of a single byte:				      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ S ³ S ³ S ³ L ³ T ³   ³ S ³ S ³ S ³ L ³ T ³   ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÁÄÄÄÙ	      :
;									      :
;	  Replacing a double byte with a double byte:			      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ L ³ T ³ S ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÙ	      :
;									      :
;	  Replacing a double byte with a single byte: (Option 1)	      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ S ³ S ³   ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÙ	      :
;									      :
;	  Replacing a double byte with a single byte: (Option 2)	      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ S ³	³ S ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÙ	      :
;									      :
;	  Replacing a single byte with a single byte:			      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ S ³ L ³ T ³   ³ S ³ L ³ T ³ S ³ L ³ T ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÙ	      :
;									      :
;	  Replacing a single byte with a double byte.			      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ S ³   ³	³   ³ S ³ L ³ T ³ L ³ T ³   ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÙ	      :
;									      :
;	  Replacing a single byte with a double byte without enough buffer:   :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ S ³ L ³ T ³   ³ S ³ L ³ T ³ S ³ L ³ T ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÙ	      :
;									      :
;	  Inserting a single byte.					      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ L ³ T ³	³   ³ S ³ L ³ T ³ S ³ L ³ T ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÙ	      :
;									      :
;	  Inserting a single byte without enough buffer generate an error:    :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ L ³ T ³ S ³   ³ S ³ L ³ T ³ L ³ T ³ S ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ	      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ S ³ S ³	³   ³ S ³ L ³ T ³ S ³ S ³   ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ	      :
;									      :
;	  Inserting a double byte character:				      :
;		ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;		³ S ³ L ³ T ³ S ³   ³	³   ³ S ³ L ³ T ³ L ³ T ³ S ³	      :
;		ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÙ	      :
;									      :
;									      :
; Entry:  ES:SI       = Points to current ICB				      :
;	  DS:DI       = Points to PB					      :
;									      :
;	  INC_KS      = Keystroke from returned from PCINCHA		      :
;									      :
;	  WR_KEYCONF  = Bit flag inidicating the options set for INC_KS       :
;	  WR_KEYCONF2	keystroke.					      :
;									      :
; Exit:   None. 							      :
;									      :
;-----------------------------------------------------------------------------+
;
LEFT_JUST      PROC NEAR
;
; Initialize right and left boundary markers
;
	       MOV  [DI]+WR_LEFTCHAR,1	     ;set left character to beginning
					     ; of field
;
	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;set right marker past end of
	       INC  AX			     ; field
	       MOV  [DI]+WR_RIGHTCHAR,AX
;
	       TEST [DI]+WR_KEYCONF,WR_MASK  ;check to see if editing key entered	 ;=W
	       JNE  LJ5 		     ;yes, must check for editing keys		 ;=W
	       JMP  LJ190		     ;no, skip checks for editing keys		 ;=W

;
; Process home key
;
LJ5:	       TEST [DI]+WR_KEYCONF,WR_HOM   ;check if home key pressed
	       JE   LJ10
;
	       ;
	       ; add ICB_WHM option to process window home key movement
	       ;
;
	       MOV  ES:[SI]+ICB_CURCHAR,1    ;initialize cursor to 1st byte
					     ; position, assuming no windowing
					     ; wrap is occurring
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       JMP  LJEXIT		     ; returns WR_CURROW, WR_CURROW
					     ; and WR_CUBYTE
;
; Process end key
;
LJ10:	       TEST [DI]+WR_KEYCONF,WR_END   ;check if home key pressed
	       JE   LJ20
;
	       ;
	       ; add ICB_WEN to move cursor to end of current window row
	       ;
;
	       CALL CAL_COORS		     ;get current end of field info		 ;=W
;
	       MOV  AX,[DI]+WR_ENCHAR	     ;adjust one past end buffer charac
	       INC  AX
	       MOV  ES:[SI]+ICB_CURCHAR,AX   ;set current cursor position to
					     ; end of field
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LJ17		     ;no					 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LJ16
	       MOV  ES:[SI]+ICB_CURCHAR,1    ;wrap to first character position
	       CALL CAL_COORS		     ;get cursor position
	       JMP  LJEXIT		     ;exit
LJ16:
	       TEST ES:[SI]+ICB_OPT2,ICB_AXC ;is autoexit option set ?			 ;=W
	       JE   LJ17		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;yes, set autoexit flag			 ;=W
LJ17:											 ;=W
	       JMP  LJEXIT		     ;exit
;
; Process left arrow
;
LJ20:	       TEST [DI]+WR_KEYCONF,WR_LFT   ;check if left arrow key pressed
	       JE   LJ40
;
	       ;
	       ; add ICB_WAR option to wrap cursor on same row end to end
	       ;
;
	       CMP  ES:[SI]+ICB_CURCHAR,1    ;check if cursor is at first
	       JA   LJ30		     ; field position
;
	       TEST ES:[SI]+ICB_OPT2,ICB_AXC ;is autoexit option set ?			 ;=W
	       JE   LJ25		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;yes, set autoexit flag			 ;=W
	       JMP  LJCUR								 ;=W
LJ25:											 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LJ27
	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;get last position
	       MOV  ES:[SI]+ICB_CURCHAR,AX   ;put as current position
	       CALL CAL_COORS
	       JMP  LJEXIT
LJ27:
	       CALL PCMBEEP_CALL	     ;error beep
	       JMP  LJEXIT		     ;exit
;
LJ30:	       DEC  ES:[SI]+ICB_CURCHAR      ;adjust cursor to one position
					     ; towards the left
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       JMP  LJEXIT		     ;exit
;
; Process right arrow
;
LJ40:	       TEST [DI]+WR_KEYCONF,WR_RGT   ;check if left arrow key pressed
	       JE   LJ60
;
	       ;
	       ; add ICB_CSW option to wrap cursor from top/bottom end to end
	       ;
;
	       ;
	       ; add ICB_AXC option to auto enter if cursor reaches end
	       ;
;
	       ;
	       ; add ICB_WAR option to wrap cursor on same row end to end
	       ;
;
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field
	       JE   LJ50
;
	       CALL PCMBEEP_CALL	     ;error beep
	       JMP  LJEXIT		     ;exit
;
LJ50:	       INC  ES:[SI]+ICB_CURCHAR      ;adjust cursor to one position
					     ; towards the left
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LJ55		     ;no					 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LJ52
	       MOV  ES:[SI]+ICB_CURCHAR,1    ;wrap to first character position
	       CALL CAL_COORS		     ;get cursor position
	       JMP  LJEXIT		     ;exit
LJ52:
	       TEST ES:[SI]+ICB_OPT2,ICB_AXC ;is autoexit option set ?			 ;=W
	       JE   LJ55		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;set autoexit flag 			 ;=W
LJ55:											 ;=W
	       JMP  LJEXIT		     ;exit
;
; Process up arrow
;
LJ60:	       ;
	       ; adjust cursor position
	       ;

	       ;
	       ; check for field wrap, exit, error beep
	       ;
;
; Process down arrow
;
LJ70:	       ;
	       ; adjust cursor position
	       ;

	       ;
	       ; check for field wrap, exit, error beep
	       ;
;
; Process cntrl+end key
;
LJ80:	       TEST [DI]+WR_KEYCONF,WR_CED   ;check if control+end key pressed
	       JE   LJ100
;
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field
	       JE   LJ90
;
	       CALL PCMBEEP_CALL	     ;error beep
	       JMP  LJEXIT		     ;exit
;
LJ90:	       CALL CAL_COORS		     ;get current end of field info		 ;=W
;
	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;set rightmost area to refresh on
	       MOV  [DI]+WR_RIGHTDISP,AX     ; display to entire field
;
	       MOV  BX,[DI]+WR_CUBYTE	     ;delete from current byte position
	       CALL CLEAR_BUFFER
;
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       JMP  LJ340		     ;display field, set cursor, exit
;
; Process delete key
;
LJ100:	       TEST [DI]+WR_KEYCONF,WR_DEL   ;check if delete key pressed
	       JE   LJ130
;
	       ;
	       ; Add ICB_WDL option in off state to delete on current line only
	       ;
;
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,1	     ;check if cursor past end of field
	       JE   LJ110
;
	       CALL REMOVE_CHAR 	     ;remove character at current offst
					     ; and shift remaining in place
	       JMP  LJ340		     ;display field, set cursor, exit
;
LJ110:	       CALL PCMBEEP_CALL	     ;error beep
	       JMP  LJEXIT		     ;exit
;
; Process backspace key
;
LJ130:	       TEST [DI]+WR_KEYCONF,WR_BCK   ;check if backspace key pressed
	       JE   LJ160
;
	       CMP  ES:[SI]+ICB_CURCHAR,1    ;check if cursor is at first
	       JA   LJ140		     ; field position
;
	       TEST ES:[SI]+ICB_OPT2,ICB_AXC ;is autoexit option set ?			 ;=W
	       JE   LJ135		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;yes, set autoexit flag			 ;=W
	       JMP  LJCUR								 ;=W
LJ135:											 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LJ137
	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;get last position
	       MOV  ES:[SI]+ICB_CURCHAR,AX   ;put as current position
	       CALL CAL_COORS
	       JMP  LJEXIT
LJ137:
	       CALL PCMBEEP_CALL	     ;error beep
	       JMP  LJEXIT		     ;exit
;
LJ140:	       DEC  ES:[SI]+ICB_CURCHAR      ;adjust cursor to one position
					     ; towards the left
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CALL REMOVE_CHAR 	     ;remove character at current offst
					     ; and shift remaining in place
;
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       JMP  LJ340		     ;display field, set cursor, exit
;
; Process insert key toggle
;
LJ160:	       TEST [DI]+WR_KEYCONF,WR_INS   ;check if insert key pressed
	       JE   LJ180		     ; if not, continue
;
	       TEST ES:[SI]+ICB_STATUS,ICB_SINS  ;check if in insert mode ?
	       JE   LJ165		     ;no, put in insert mode
;
	       MOV  BX,[DI]+IN_CURNOR	     ;set cursor size for normal
	       MOV  [DI]+WR_CURSIZE,BX	     ; cursor
;
	       AND  ES:[SI]+ICB_STATUS,NOT ICB_SINS
	       JMP  LJ170		     ;turn insert mode off
;
LJ165:	       MOV  BX,[DI]+IN_CURINS	     ;set cursor size for insert
	       MOV  [DI]+WR_CURSIZE,BX	     ; cursor
;
	       OR   ES:[SI]+ICB_STATUS,ICB_SINS
					     ;turn insert mode on
;
LJ170:
;
	       PUSH DS			     ;save registers
	       PUSH DI
;
	       MOV  DI,40H		     ;point DS:DI to KB_FLAG in BIOS
	       MOV  DS,DI
	       MOV  DI,17H
	       MOV  AX,[DI]		     ;get current BIOS KB_FLAG
;
	       AND  AX,NOT WR_INSSTATE	     ;set BIOS insert active flag off
;
	       TEST ES:[SI]+ICB_STATUS,ICB_SINS
	       JE   LJ175		     ;check if insert should be set on
;
	       OR   AX,WR_INSSTATE	     ;set BIOS insert active flag on
;
LJ175:	       POP  DI			     ;restore registers
	       POP  DS
;
	       JMP  LJEXIT		     ;exit
;
; Process allowonce key option
;
LJ180:	       ;
	       ; insert or replace
	       ;
;
	       ;
	       ; adjust input buffer
	       ;
;
	       ;
	       ; check for field wrap, exit, error beep
	       ;
;
	       ;
	       ; adjust cursor position
	       ;
;
; Process allowed keystroke in replace mode
;
LJ190:	       TEST [DI]+WR_KEYCONF,WR_ALL   ;check if allow key pressed
	       JNE  LJ195
;
	       CALL PCMBEEP_CALL	     ;error beep key not defined
	       JMP  LJEXIT		     ;exit
;
LJ195:	       TEST ES:[SI]+ICB_STATUS,ICB_SINS
	       JE   LJ198		     ;check if insert is active
;
	       JMP  LJ270		     ;do insert display
;
LJ198:
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field
	       JE   LJ200
;
	       CALL PCMBEEP_CALL	     ;error beep key not defined
	       JMP  LJEXIT		     ;exit
;
; Check if character to be replaced in field buffer is double byte character
;
LJ200:	       PUSH ES			     ;save registers
	       PUSH SI
;
	       PUSH ES:[SI]+ICB_FIELDSEG     ;get segment of input buffer
	       PUSH ES:[SI]+ICB_FIELDOFF     ;get offset of input buffer
	       POP  SI
	       POP  ES
;
	       ADD  SI,[DI]+WR_CUBYTE	     ;add cursor offset into buffer
	       DEC  SI			     ;make zero based
;
	       MOV  CX,ES		     ;save offset of character to
	       MOV  DX,SI		     ; replace
;
	       MOV  AL,ES:[SI]		     ;get byte that cursor is pointing
	       MOV  [DI]+DBC_KS,AL	     ; to check if DBCS
	       CALL PCINDBC_CALL	     ;call routine to check if char
					     ; is lead double byte char
;
	       POP  SI			     ;restore registers
	       POP  ES
;
	       TEST [DI]+DBC_STAT,DBC_DBCS   ;check if char is lead DBCS
	       JE   LJ220		     ; if no, jump to single byte code
;
; Replace double byte character with double byte character
;
	       TEST [DI]+WR_KEYCONF2,WR_DBC  ;check if keystroke is DBC
	       JE   LJ210		     ;continue with single byte
;
	       MOV  AX,[DI]+INC_KS	     ;set double byte character to
					     ; input buffer replacing
					     ; double byte character
	       PUSH ES
	       PUSH SI
;
	       MOV  ES,CX		     ;save offset of character to
	       MOV  SI,DX		     ; replace
	       MOV  ES:[SI],AX		     ;replace double byte
;
	       POP  SI			     ;restore registers
	       POP  ES
;
	       JMP  LJ260		     ;exit
;
; Replace double byte character with single byte character
;
LJ210:	       MOV  AX,[DI]+INC_KS	     ;get keystroke and replace double
					     ; byte with single byte
;
	       PUSH ES
	       PUSH SI
;
	       MOV  ES,CX		     ;save offset of character to
	       MOV  SI,DX		     ; replace single byte
	       MOV  ES:[SI],AL
;
	       POP  SI			     ;restore registers
	       POP  ES
;
	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;set ending byte
	       MOV  [DI]+WR_RIGHTBYTE,AX
;
	       MOV  AX,[DI]+WR_CUBYTE	     ;set markers for shift to remove
	       INC  AX			     ;adjust past replaced leading byte 	 ;=W
	       MOV  [DI]+WR_LEFTBYTE,AX      ; trailing byte
;
	       MOV  BX,1		     ;set number of positions to shift
	       MOV  AX,2		     ;set option to shift left
	       CALL SHIFT		     ;call shift 1 position toward left
	       JMP  LJ260		     ;exit
;
; Replace single byte character with single byte character
;
LJ220:	       TEST [DI]+WR_KEYCONF2,WR_DBC  ;check if double byte character
	       JNE  LJ230		     ; continue with single byte
;
	       MOV  AX,[DI]+INC_KS	     ;get keystroke
;
	       PUSH ES
	       PUSH SI
;
	       MOV  ES,CX		     ;save offset of character to
	       MOV  SI,DX		     ; replace single byte
	       MOV  ES:[SI],AL
;
	       POP  SI			     ;restore registers
	       POP  ES
;
	       JMP  LJ260		     ;exit
;
; Replace single byte character with double byte character
;
LJ230:	       MOV  BX,ES:[SI]+ICB_CURCHAR   ;set cursor character position
	       MOV  [DI]+WR_LEFTCHAR,BX      ; to left marker
;
	       CALL CAL_COORS		     ;get the current end of field		 ;=W
					     ; coordinates
	       MOV  AX,[DI]+WR_ENCHAR	     ;get end character of field
	       CMP  AX,ES:[SI]+ICB_CURCHAR   ;is cursor past end character
	       JA   LJ240
;
	       MOV  AX,ES:[SI]+ICB_CURCHAR   ;cursor is past last char
;
LJ240:	       MOV  [DI]+WR_RIGHTCHAR,AX     ;set right marker
;
	       MOV  BX,1		     ;One byte is already available
					     ; check if room for trailing byte
	       MOV  AX,1		     ;set up call to LEFT_DISP to
	       CALL WORD PTR [DI]+WR_DISPLAY ; determine if additional byte
					     ; will fit in input buffer
	       CMP  AX,0		     ;check if double byte character
	       JE   LJ250		     ; will fit
;
	       CALL PCMBEEP_CALL	     ;error beep because replace char
	       JMP  LJEXIT		     ; will not fit and exit
;
LJ250:	       MOV  BX,ES:[SI]+ICB_FIELDLEN  ;set ending byte
	       MOV  [DI]+WR_RIGHTBYTE,BX
;
	       MOV  BX,[DI]+WR_CUBYTE	     ;set markers for shift to remove
	       INC  BX			     ;adjust past replaced leading byte
	       MOV  [DI]+WR_LEFTBYTE,BX      ; trailing byte
;
	       MOV  BX,1		     ;set number of positions to shift
	       MOV  AX,1		     ;set option to shift right
	       CALL SHIFT		     ;call shift 1 position toward
					     ; left
	       MOV  AX,[DI]+INC_KS	     ;get keystroke
;
	       PUSH ES
	       PUSH SI
;
	       MOV  ES,CX		     ;save offset of character to
	       MOV  SI,DX		     ; replace double byte
	       MOV  ES:[SI],AX
;
	       POP  SI			     ;restore registers
	       POP  ES
;
; Calculate new ending and cursor coordinates
;
LJ260:
	       MOV  BX,[DI]+WR_ENCHAR	     ;set rightmost area to refresh on		 ;=W
	       CALL CAL_COORS		     ;get new end coordinates			 ;=W
	       CMP  BX,[DI]+WR_ENCHAR	     ;is old END_CHAR > new END_CHAR ?		 ;=W
	       JG   LJ261		     ;yes, use old END_CHAR (so display 	 ;=W
	       MOV  BX,[DI]+WR_ENCHAR	     ; is updated correctly)

LJ261:					     ;set rightmost area to refresh on		 ;=W
	       MOV  [DI]+WR_RIGHTDISP,BX     ; display to new ending character

	       INC  ES:[SI]+ICB_CURCHAR      ;point to next char

	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LJ265		     ;no					 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LJ262
	       MOV  ES:[SI]+ICB_CURCHAR,1    ;wrap to first character position
	       JMP  LJ340		     ;display field, set cursor, exit
LJ262:
	       TEST ES:[SI]+ICB_OPT2,ICB_AXD ;is autoexit option set ?			 ;=W
	       JE   LJ265		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;set autoexit flag 			 ;=W
LJ265:											 ;=W
	       JMP  LJ340		     ;display field, set cursor, exit
;
; Process allowed keystroke in insert mode
;
LJ270:
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field
	       JE   LJ280
;
	       CALL PCMBEEP_CALL	     ;error beep key not defined
	       JMP  LJEXIT		     ;exit
;
; Check if enough room available to insert single or double byte character
;
LJ280:
	       MOV  CX,ES:[SI]+ICB_FIELDSEG  ;get segment of input buffer
	       MOV  DX,ES:[SI]+ICB_FIELDOFF  ;get offset of input buffer
;
	       ADD  DX,[DI]+WR_CUBYTE	     ;add cursor offset into buffer
	       DEC  DX			     ;make zero based
;
	       MOV  BX,1		     ;initialize to single byte
;
	       TEST [DI]+WR_KEYCONF2,WR_DBC  ;check for double byte character
	       JE   LJ290
;
	       MOV  BX,2		     ;reset to double byte character
;
LJ290:	       MOV  AX,ES:[SI]+ICB_CURCHAR   ;set cursor character position
	       MOV  [DI]+WR_LEFTCHAR,AX      ; to left marker
;
	       CALL CAL_COORS		     ;get the current end of field		 ;=W
					     ; coordinates
	       MOV  AX,[DI]+WR_ENCHAR	     ;get end character of field
;
	       CMP  AX,ES:[SI]+ICB_CURCHAR   ;is cursor past end character
	       JA   LJ300
;
	       MOV  AX,ES:[SI]+ICB_CURCHAR   ;cursor is past last char
	       DEC  AX
;
LJ300:	       MOV  [DI]+WR_RIGHTCHAR,AX     ;set right marker
;
	       MOV  AX,1		     ;set up call to LEFT_DISP to
	       CALL WORD PTR [DI]+WR_DISPLAY ; determine if additional byte
					     ; will fit in input buffer
					     ; BX= number of bytes to insert
	       CMP  AX,0		     ;check if double byte character
	       JE   LJ310		     ; will fit
;
	       CALL PCMBEEP_CALL	     ;error beep replace character
	       JMP  LJEXIT		     ; will not fit and exit
;
; Shift to insert single or double byte character, BX= # bytes to shift
;
LJ310:	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;set ending byte to make room in
	       MOV  [DI]+WR_RIGHTBYTE,AX     ; buffer by shifting characters
;
	       MOV  AX,[DI]+WR_CUBYTE	     ;set markers for shift to remove
	       MOV  [DI]+WR_LEFTBYTE,AX      ; trailing byte
;
	       MOV  AX,1		     ;set option to shift right, BX=
					     ; number of bytes to insert
	       CALL SHIFT		     ;call shift 1 position toward
					     ; left
	       MOV  AX,[DI]+INC_KS	     ;get keystroke
;
; Insert single byte character
;
	       CMP  BX,2		     ;check how many bytes should be
	       JE   LJ320		     ; inserted
;
	       PUSH ES
	       PUSH SI
;
	       MOV  ES,CX		     ;save offset of character to
	       MOV  SI,DX		     ; replace single byte
	       MOV  ES:[SI],AL		     ;insert single byte character
;
	       POP  SI			     ;restore registers
	       POP  ES
;
	       JMP  LJ330
;
; Insert double byte character
;
LJ320:	       PUSH ES
	       PUSH SI
;
	       MOV  ES,CX		     ;save offset of character to
	       MOV  SI,DX		     ; replace
	       MOV  ES:[SI],AX		     ;insert double byte character
;
	       POP  SI			     ;restore registers
	       POP  ES
;
; Calculate new ending and cursor coordinates
;
LJ330:
	       CALL CAL_COORS		     ;get new end coordinates			 ;=W
;
	       MOV  AX,[DI]+WR_ENCHAR	     ;set rightmost area to refresh on
	       MOV  [DI]+WR_RIGHTDISP,AX     ; display to old ending character
;
	       INC  ES:[SI]+ICB_CURCHAR      ;point to next char
;
	       CALL CAL_COORS		     ;get cursor position			 ;=W
	       CMP  [DI]+WR_FIELDEND,0	     ;check if cursor past end of field 	 ;=W
	       JE   LJ340		     ;no					 ;=W
	       TEST ES:[SI]+ICB_OPT2,ICB_CSW ;is cursor wrap option on ?		 ;=W
	       JE   LJ335
	       MOV  ES:[SI]+ICB_CURCHAR,1    ;wrap to first character position
	       JMP  LJ340		     ;display field, set cursor, exit
LJ335:
	       TEST ES:[SI]+ICB_OPT2,ICB_AXD ;is autoexit option set ?			 ;=W
	       JE   LJ340		     ;no					 ;=W
	       OR   [DI]+WR_KEYCONF2,WR_RET  ;set autoexit flag 			 ;=W
;
; Display field
;
LJ340:
	       MOV  AX,ES:[SI]+ICB_CURCHAR   ;set left character to cursor
	       DEC  AX			     ; last cursor position
	       MOV  [DI]+WR_LEFTCHAR,AX
;
	       MOV  AX,[DI]+WR_RIGHTDISP     ;set right character marker to		 ;=W
	       MOV  [DI]+WR_RIGHTCHAR,AX     ; max possible field length
;
	       CALL CAL_COORS		     ;get end of field char, byte		 ;=W
					     ; and next byte positions

	       MOV  AX,2		     ;set display option
	       CALL WORD PTR [DI]+WR_DISPLAY ;display current input buffer
					     ; in left justified field
;
; Exit
;
LJEXIT: 					  ;continue
	       TEST ES:[SI]+ICB_STATUS,ICB_CUR_ON ;is cursor on ?
	       JNE  LJCUR			  ;cursor is already on, don't turn it on ;=W
	       CALL CURSOR			  ;display cursor			      ;=W
LJCUR:
;
	       RET
LEFT_JUST      ENDP
;-----------------------------------------------------------------------------+
;									      :
; CAL_COORS								      :
;									      :
;	 Calculates character coordinates based on the display format	      :
;	 currently active (windowing and horizontal display).		      :
;									      :
;	 The following examples demonstrate the values that are set on	      :
;	 exit from this routine:					      :
;									      :
;									      :
;	 Example: Horizontal field coordinates calculated.		      :
;									      :
;		  ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ			      :
;		  ³123456789012345678901234567890			      :
;		  ³2							      :
;		  ³3	   [sLtLtssss....]				      :
;			       ^					      :
;			    ³  ³    ³					      :
;			    ³  ³    ÀÄ WR_ENCHAR = 7			      :
;			    ³  ³       WR_ENBYTE = 9			      :
;			    ³  ³       WR_RGCHAR = 7			      :
;			    ³  ³					      :
;			    ³  ÀÄÄÄÄÄÄ WR_CUCHAR = 3			      :
;			    ³	       WR_CUBYTE = 4			      :
;			    ³	       WR_UPCHAR = 3			      :
;			    ³	       WR_DNCHAR = 3			      :
;			    ³	       WR_CURROW = 3			      :
;			    ³	       WR_CURCOL = 13			      :
;			    ³						      :
;			    ÀÄÄÄÄÄÄÄÄÄ WR_LFCHAR = 1			      :
;				       WR_HRCHAR = 1			      :
;									      :
;									      :
;	 Example: Horizontal field scroll coordinates calculated:	      :
;									      :
;		  ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ			      :
;		  ³123456789012345678901234567890			      :
;		  ³2	     ÚÄÄÄÄÄ¿					      :
;		  ³3	    s³LtLt ³Ltsss.....				      :
;			    ³ÀÄÄÄÄÄÙ	³				      :
;			    ³ ³ ^	³				      :
;			    ³ ³ ³	³				      :
;			    ³ ³ ³	À WR_ENCHAR = 7 		      :
;			    ³ ³ ³	  WR_ENBYTE = 10		      :
;			    ³ ³ ³	  WR_RGCHAR = 7 		      :
;			    ³ ³ ³					      :
;			    ³ ³ ÀÄÄÄÄÄÄÄÄ WR_CUCHAR = 3 		      :
;			    ³ ³ 	  WR_CUBYTE = 4 		      :
;			    ³ ³ 	  WR_UPCHAR = 3 		      :
;			    ³ ³ 	  WR_DNCHAR = 3 		      :
;			    ³ ³ 	  WR_CURROW = 3 		      :
;			    ³ ³ 	  WR_CURCOL = 14		      :
;			    ³ ³ 					      :
;			    ³ ÀÄÄÄÄÄÄÄÄÄÄ WR_HRCHAR = 2 		      :
;			    ³						      :
;			    ÀÄÄÄÄÄÄÄÄÄÄÄÄ WR_LFCHAR = 1 		      :
;									      :
;									      :
;									      :
;	 Example: Windowed field coordinates calculated.		      :
;									      :
;		  ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ			      :
;		  ³123456789012345678901234567890			      :
;		  ³2		     ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ WR_LFCHAR=	6	      :
;		  ³3		     ³	  ÚÄÄÄÄÄÄÄÄ WR_UPCHAR=	3	      :
;		  ³4		     ³ ÚÄÄ³ÄÄ¿				      :
;		  ³5		     ³ ³ABCDE³				      :
;		  ³6		     ÀÄÄFGHI.³				      :
;		  ³7		       ³ Ú³³ÀÄÄÄÄÄÄ WR_RGCHAR= 10	      :
;		  ³8		       ÀÄ³³ÀÄÄÄÄÄÄÄ WR_ENCHAR=	9	      :
;		  ³9			 ³³				      :
;					 ³ÀÄÄÄÄÄÄÂÄ WR_CUCHAR=	8	      :
;					 ³	 ÃÄ WR_CURCOL= 24	      :
;					 ³	 ÀÄ WR_CURROW=	6	      :
;					 ³				      :
;					 ÀÄÄÄÄÄÄÄÄÄ WR_DNCHAR= 13	      :
;									      :
;									      :
; Entry: ICB_CURCHAR   = The character position into the input field from     :
;			 which the exit coordinates will be calculated.       :
;									      :
;	 WR_HRCHAR     = The character position into the input field that     :
;			 is currently the first displayed character of the    :
;			 horizontal window.				      :
;									      :
;	 ICB_WIDTH     = The width of windowed or horizontal scroll field.    :
;									      :
;	 ICB_FIELDLEN  = Input field buffer length.			      :
;									      :
;	 ICB_FIELDOFF  = Input field buffer offset.			      :
;									      :
;	 ICB_FIELDSEG  = Input field buffer segment.			      :
;									      :
;									      :
; Exit:  WR_RGCHAR     = Character offset into input buffer of the character  :
;			 appearing at the beginning of the current line that  :
;			 WR_CUCHAR is located on.			      :
;									      :
;	 WR_LFCHAR     = Character offset into input buffer of the character  :
;			 appearing at the end of the current line that	      :
;			 WR_CUCHAR is located on.			      :
;									      :
;	 WR_UPCHAR     = Character offset into input buffer of the character  :
;			 displayed directly above the position that	      :
;			 WR_CUCHAR is located on.			      :
;									      :
;	 WR_DNCHAR     = Character offset into input buffer of the character  :
;			 displayed directly below the position that	      :
;			 WR_CUCHAR is located on.			      :
;									      :
;	 WR_ENCHAR     = Number of characters currently entered in the	      :
;			 field.  This value may be less than the number       :
;			 of bytes used to represent the characters if	      :
;			 double byte characters are present.		      :
;									      :
;	 WR_CURROW     = Actual row offset into the video buffer of the       :
;			 character specified by WR_CURCHAR.		      :
;									      :
;	 WR_CURCOL     = Actual column offset into the video buffer of the    :
;			 character specified by WR_CUCHAR.		      :
;									      :
;	 WR_ENBYTE     = Number of bytes currently used to represent	      :
;			 entered characters in the buffer.  This counter      :
;			 can be used to calculate the current end	      :
;			 position of the entered data in the field.	      :
;									      :
;	 WR_CUBYTE     = Number of bytes into input field where WR_CUCHAR     :
;			 appears.					      :
;									      : 	 ;=W
;	 WR_CUCHAR     = Offset of current cursor position in input field.    : 	 ;=W
;									      : 	 ;=W
;	 WR_HRBYTE     = Number of bytes into input field where WR_HRCHAR     :
;			 appears.					      :
;									      :
;	 WR_FIELDEND   = Boolean flag,	 0 = cursor not past end of field     : 	 ;=W
;					 1 = cursor is past end of field      : 	 ;=W
;									      :
;-----------------------------------------------------------------------------+
;
CAL_COORS      PROC NEAR
;
	       PUSH AX			     ;save registers
	       PUSH BX
	       PUSH CX
	       PUSH DX
	       PUSH ES
	       PUSH SI
	       PUSH BP									 ;=W
;											 ;=W
; initialize general variables for all display modes					 ;=W
;
	       MOV  [DI]+WR_FIELDEND,0	     ;initialize boolean flag that		 ;=W
					     ;cursor is not past end of field		 ;=W
	       MOV  AX,ES:[SI]+ICB_CURCHAR   ;get current char. offset			 ;=W
	       MOV  [DI]+WR_CUCHAR,AX	     ;save it					 ;=W
;
	       MOV  AX,ES:[SI]+ICB_ROW	     ;initialize row offset of field		 ;=W
	       DEC  AX									 ;=W
	       MOV  [DI]+WR_CURROW,AX	     ;char row offset inot video buf		 ;=W
	       MOV  AX,ES:[SI]+ICB_COL	     ;initialize col offset of field		 ;=W
	       DEC  AX									 ;=W
	       MOV  [DI]+WR_CURCOL,AX	     ;char col offset into video buf		 ;=W
;
	       MOV  [DI]+WR_LFCHAR,1	     ;leftmost character possible char		 ;=W
	       MOV  [DI]+WR_RGCHAR,1	     ;rightmost character possible char 	 ;=W
	       MOV  [DI]+WR_ENBYTE,0	     ;end byte of data in input buffer		 ;=W
	       MOV  [DI]+WR_ENCHAR,0	     ;end character in input buffer		 ;=W
	       MOV  [DI]+WR_HRBYTE,1	     ;byte of first char in horz. window	 ;=W
;
	       MOV  AX,[DI]+WR_CUCHAR	     ;get current position			 ;=W
	       MOV  [DI]+WR_UPCHAR,1	     ;topmost char in current column		 ;=W
	       MOV  [DI]+WR_DNCHAR,1	     ;bottommost char in current column 	 ;=W
;
	       MOV  BP,0		     ;have not found current char yet		 ;=W
	       MOV  CX,1		     ;counter tracking number of bytes		 ;=W
	       MOV  DX,1		     ;counter tracking number of chars		 ;=W
;
; Determine display format of field
;
	       TEST ES:[SI]+ICB_OPT3,ICB_WIN ;check if windowing option on
	       JE   CC10
;
	       JMP  CC200		     ;process window option
;
CC10:	       TEST ES:[SI]+ICB_OPT3,ICB_HOR ;check if horizontal scroll option
	       JE   CC20		     ; on
;
	       JMP  CC100		     ;process horizontal scroll
;
; Process fully displayed horizontal field
;
CC20:											 ;=W
	       MOV  [DI]+WR_HRCHAR,1	     ;leftmost character possible char
;
; Examine the next byte in the input buffer
;
CC30:	       CMP  CX,ES:[SI]+ICB_FIELDLEN  ;check if entire field has been
	       JBE  CC35		     ; scanned and exit
;
	       CMP  BP,0		     ;found current char yet ?			 ;=W
	       JE   CC40		     ;no, find it				 ;=W
	       JMP  CCEXIT
;
CC35:	       PUSH ES			     ;save registers
	       PUSH SI
;
	       PUSH ES:[SI]+ICB_FIELDSEG     ;get segment of input buffer
	       PUSH ES:[SI]+ICB_FIELDOFF     ;get offset of input buffer
	       POP  SI
	       POP  ES
;
	       DEC  CX			     ;make byte count zero based
	       ADD  SI,CX		     ;add byte count to input fld offst
	       INC  CX			     ;make byte count one based
	       MOV  AL,ES:[SI]		     ;get byte in input buffer to
	       MOV  [DI]+DBC_KS,AL	     ; check if DBCS
	       CALL PCINDBC_CALL	     ;call routine to check if char
					     ; is lead double byte char
;
	       POP  SI			     ;restore registers
	       POP  ES
;
; Check if end data byte and character should be updated
;
	       CMP  AL,WR_BLANK 	     ;check if blanking character found
	       JE   CC40		     ;now adjust pointers
;
	       MOV  [DI]+WR_ENBYTE,CX	     ;set current byte count
	       MOV  [DI]+WR_ENCHAR,DX	     ;set current character count
	       MOV  [DI]+WR_RGCHAR,DX	     ;set right most character
;
; Check if current character pointer
;
CC40:	       CMP  [DI]+WR_CUCHAR,DX	     ;check if current character found
	       JNE  CC50
;
	       MOV  BP,1		     ;current char found			 ;=W
	       MOV  [DI]+WR_UPCHAR,DX	     ;set up and down character
	       MOV  [DI]+WR_DNCHAR,DX	     ; to current character
;
	       MOV  [DI]+WR_CUBYTE,CX	     ;set current character byte count
	       ADD  [DI]+WR_CURCOL,CX	     ;set actual column of cursor based
	       DEC  [DI]+WR_CURCOL	     ; on current character byte count		 ;=W
;
; Increment pointers and counters to next character and byte position check
;
CC50:	       INC  CX			     ;adjust byte counter
	       INC  DX			     ;adjust character counter
;
	       TEST [DI]+DBC_STAT,DBC_DBCS   ;check if byte is leading DBC byte
	       JE   CC30
;
	       INC  CX			     ;adjust byte count for trail byte
	       JMP  CC30





;
; Calculate horizontal scroll coordinates
;
CC100:
	       MOV  AX,[DI]+WR_CUCHAR	     ;initialize current character
	       CMP  AX,[DI]+WR_HRCHAR	     ;horizontal display position must
	       JAE  CC120		     ; not be less than current char
					     ; position
	       MOV  [DI]+WR_HRCHAR,AX	     ;set current char position as
					     ; new horizontal position
;
; Examine the next byte in the input buffer
;
CC120:	       CMP  CX,ES:[SI]+ICB_FIELDLEN  ;check if entire field has been
	       JBE  CC122		     ; scanned and exit 			 ;=W
;
	       CMP  BP,0		     ;found current char yet ?			 ;=W
	       JE   CC130		     ;no, find it				 ;=W
;
	       JMP  CCEXIT								 ;=W
CC122:											 ;=W
	       PUSH ES			     ;save registers
	       PUSH SI
;
	       PUSH ES:[SI]+ICB_FIELDSEG     ;get segment of input buffer
	       PUSH ES:[SI]+ICB_FIELDOFF     ;get offset of input buffer
	       POP  SI
	       POP  ES
;
	       DEC  CX			     ;make byte count zero based
	       ADD  SI,CX		     ;add byte count to input fld offst
	       INC  CX			     ;make byte count one based
	       MOV  AL,ES:[SI]		     ;get byte in input buffer to
	       MOV  [DI]+DBC_KS,AL	     ; check if DBCS
	       CALL PCINDBC_CALL	     ;call routine to check if char
					     ; is lead double byte char
;
	       POP  SI			     ;restore registers
	       POP  ES
;											 ;=W
; Set WR_HRBYTE to correct byte count							 ;=W
;											 ;=W
	       CMP  [DI]+WR_HRCHAR,DX	     ;is this position the first char		 ;=W
					     ;in the horizl. window ?			 ;=W
	       JNE  CC125		     ;no					 ;=W
;
	       MOV  [DI]+WR_HRBYTE,CX	     ;save # byte for first char in h. wind.	 ;=W
;
; Check if end data byte and character should be updated
;
CC125:	       CMP  AL,WR_BLANK 	     ;check if blanking character found
	       JE   CC130		     ;now adjust pointers
;
	       MOV  [DI]+WR_ENBYTE,CX	     ;set current byte count
	       MOV  [DI]+WR_ENCHAR,DX	     ;set current character count
	       MOV  [DI]+WR_RGCHAR,DX	     ;set right most character
;
; Check if current character pointer
;
CC130:	       CMP  [DI]+WR_CUCHAR,DX	     ;check if current character found
	       JNE  CC140
;
	       MOV  BP,1		     ;current char found
	       MOV  [DI]+WR_UPCHAR,DX	     ;set up and down character
	       MOV  [DI]+WR_DNCHAR,DX	     ; to current character
;
	       MOV  [DI]+WR_CUBYTE,CX	     ;set current character byte count
	       MOV  BX,CX		     ;set actual column of cursor based 	 ;=W
					     ; on current character byte count		 ;=W
	       SUB  BX,[DI]+WR_HRBYTE	     ;subtract beginning of horiz. wind.	 ;=W
	       ADD  [DI]+WR_CURCOL,BX	     ;add to window offset = new column 	 ;=W
;
; Increment pointers and counters to next character and byte position check
;
CC140:	       INC  CX			     ;adjust byte counter
	       INC  DX			     ;adjust character counter
;
	       TEST [DI]+DBC_STAT,DBC_DBCS   ;check if byte is leading DBC byte
	       JE   CC120
;
	       INC  CX			     ;adjust byte count for trail byte
	       JMP  CC120





;
; Calculate windowing coordinates							 ;=W
;
CC200:											 ;=W
;
; Examine the next byte in the input buffer						 ;=W
;
	       CMP  CX,ES:[SI]+ICB_FIELDLEN  ;check if entire field has been		 ;=W
	       JBE  CC235		     ; scanned and exit 			 ;=W
;
	       CMP  BP,0		     ;found current char yet ?			 ;=W
	       JE   CC240		     ;no, find it				 ;=W
;
	       JMP  CCBYE		     ;boolean flag should have been set 	 ;=W
					     ; already, if needed			 ;=W
CC235:	       PUSH ES			     ;save registers				 ;=W
	       PUSH SI									 ;=W
;
	       PUSH ES:[SI]+ICB_FIELDSEG     ;get segment of input buffer		 ;=W
	       PUSH ES:[SI]+ICB_FIELDOFF     ;get offset of input buffer		 ;=W
	       POP  SI									 ;=W
	       POP  ES									 ;=W
;
	       DEC  CX			     ;make byte count zero based		 ;=W
	       ADD  SI,CX		     ;add byte count to input fld offst 	 ;=W
	       INC  CX			     ;make byte count one based 		 ;=W
	       MOV  AL,ES:[SI]		     ;get byte in input buffer to		 ;=W
	       MOV  [DI]+DBC_KS,AL	     ; check if DBCS				 ;=W
	       CALL PCINDBC_CALL	     ;call routine to check if char		 ;=W
					     ; is lead double byte char 		 ;=W
;
	       POP  SI			     ;restore registers 			 ;=W
	       POP  ES									 ;=W
;											 ;=W
; Check if end data byte and character should be updated				 ;=W
;											 ;=W
	       CMP  AL,WR_BLANK 	     ;check if blanking character found 	 ;=W
	       JE   CC240		     ;now adjust pointers			 ;=W
;
	       MOV  [DI]+WR_ENBYTE,CX	     ;set current byte count			 ;=W
	       MOV  [DI]+WR_ENCHAR,DX	     ;set current character count		 ;=W
	       MOV  [DI]+WR_RGCHAR,DX	     ;set right most character			 ;=W
;											 ;=W
; Check if current character pointer							 ;=W
;											 ;=W
CC240:
	       CMP  [DI]+WR_CUCHAR,DX	     ;check if current character found		 ;=W
	       JNE  CC250		     ;no					 ;=W
;
	       MOV  BP,1		     ;found current char
	       MOV  [DI]+WR_CUBYTE,CX	     ;set current character byte count		 ;=W
;
	       PUSH DX			     ;needed for division			 ;=W
	       MOV  AX,CX		     ;get current cursor pos. in field		 ;=W
	       DEC  AX			     ;make it zero based for divide		 ;=W
;
	       CMP  CX,ES:[SI]+ICB_FIELDLEN  ;are we past end of field ?		 ;=W
	       JLE  CC241		     ;no					 ;=W
	       MOV  [DI]+WR_FIELDEND,1	     ;yes, set boolean flag			 ;=W
	       DEC  AX			     ;make cursor pos. be inside field		 ;=W
					     ; for division				 ;=W
	       CWD			     ;calculate current row,column		 ;=W
	       IDIV ES:[SI]+ICB_WIDTH	     ; row = cur_byte / width-1 		 ;=W
					     ; col = cur_byte mod width-1		 ;=W
	       INC  DX			     ;reposition cursor in correct pos. 	 ;=W
	       JMP  CC244								 ;=W
CC241:											 ;=W
	       CWD			     ;calculate current row,column for		 ;=W
	       IDIV ES:[SI]+ICB_WIDTH	     ; cursor positions inside the field	 ;=W
					     ; row = cur_byte / width of field		 ;=W
					     ; col = cur_byte mod width of field	 ;=W
CC244:											 ;=W
	       ADD  [DI]+WR_CURROW,AX	     ;set actual row of cursor			 ;=W
	       ADD  [DI]+WR_CURCOL,DX	     ;set actual column of cursor		 ;=W
;
	       MOV  BX,CX		     ;calculate WR_LFCHAR			 ;=W
CC245:	       DEC  BX			     ;get the correct cur_byte			 ;=W
	       MOV  AX,BX		     ;cur_byte/width				 ;=W
	       CWD									 ;=W
	       IDIV ES:[SI]+ICB_WIDTH							 ;=W
	       CMP  DX,0		     ;is the remainder zero ?			 ;=W
	       JNE  CC245		     ;no, not at beginning of row, do again	 ;=W
;
	       MOV  [DI]+WR_LFCHAR,BX	     ;yes, this is beginning of row		 ;=W
;
	       POP  DX									 ;=W
;
; Increment pointers and counters to next character and byte position check		 ;=W
;											 ;=W
CC250:	       INC  CX			     ;adjust byte counter			 ;=W
	       INC  DX			     ;adjust character counter			 ;=W
;
	       TEST [DI]+DBC_STAT,DBC_DBCS   ;check if byte is leading DBC byte 	 ;=W
	       JE   CC260								 ;=W
;
	       INC  CX			     ;adjust byte count for trail byte		 ;=W
CC260:
	       JMP  CC200								 ;=W
;
; Exit
;
CCEXIT: 										 ;=W
	       MOV  AX,[DI]+WR_CUBYTE	     ;is cursor past end of field		 ;=W
	       CMP  AX,ES:[SI]+ICB_FIELDLEN  ;??					 ;=W
	       JLE  CCBYE		     ;no					 ;=W
;
	       MOV  [DI]+WR_FIELDEND,1	     ;yes, set boolean flag			 ;=W
CCBYE:
	       MOV  AX,[DI]+WR_ENBYTE	     ;set ICB_ENDBYTE				 ;=W
	       MOV  ES:[SI]+ICB_ENDBYTE,AX						 ;=W
;
	       MOV  AX,[DI]+WR_HRBYTE	     ;set ICB_HRSTART				 ;=W
	       MOV  ES:[SI]+ICB_HRSTART,AX						 ;=W
;
	       POP  BP
	       POP  SI			     ;restore registers
	       POP  ES
	       POP  DX			     ;restore registers
	       POP  CX
	       POP  BX
	       POP  AX
;
	       RET
CAL_COORS      ENDP
;
PAGE											 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;									      : 	 ;=W
; SET_DISP_ADDR 							      : 	 ;=W
;									      : 	 ;=W
;	    Determine which display routine to use. The choice is between     : 	 ;=W
;	    left justified, right justified, double byte support, no double   : 	 ;=W
;	    byte support, windowing, horizontal scrolling.		      : 	 ;=W
;	    Also pick the justify routine to use.			      : 	 ;=W
;									      : 	 ;=W
;			     ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿			      : 	 ;=W
;			     ³	   DISPLAY	³			      : 	 ;=W
;			     ÀÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÙ			      : 	 ;=W
;	ÚÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄ¿ 	      : 	 ;=W
;  ÚÄÄÄÄÁÄÄÄÄ¿ ³       ³		 ÚÄÄÄÄÁÄÄÄÄÄ¿ ³       ³ 	      : 	 ;=W
;  ³LEFT_DISP³ ³       ³		 ³RIGHT_DISP³ ³       ³ 	      : 	 ;=W
;  ÀÄÄÄÄÄÄÄÄÄÙ ³       ³		 ÀÄÄÄÄÄÄÄÄÄÄÙ ³       ³ 	      : 	 ;=W
;	 ÚÄÄÄÄÄÁÄÄÄÄÄ¿ ³		       ÚÄÄÄÄÄÄÁÄÄÄÄÄ¿ ³ 	      : 	 ;=W
;	 ³LEFT_H_DISP³ ³		       ³RIGHT_H_DISP³ ³ 	      : 	 ;=W
;	 ÀÄÄÄÄÄÄÄÄÄÄÄÙ ³		       ÀÄÄÄÄÄÄÄÄÄÄÄÄÙ ³ 	      : 	 ;=W
;		 ÚÄÄÄÄÄÁÄÄÄÄ¿			       ÚÄÄÄÄÄÄÁÄÄÄÄ¿	      : 	 ;=W
;		 ³LEFTS_DISP³			       ³RIGHTS_DISP³	      : 	 ;=W
;		 ÀÄÄÄÄÄÄÄÄÄÄÙ			       ÀÄÄÄÄÄÄÄÄÄÄÄÙ	      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
; DISPLAY ROUTINES							      : 	 ;=W
;  LEFT_DISP	 - left justified, double byte support, windowing	      : 	 ;=W
;  LEFTS_DISP	 - left justified, no double byte support, windowing	      : 	 ;=W
;  LEFT_H_DISP	 - left justified, double byte support, horizontal scrolling  : 	 ;=W
;  RIGHT_DISP	 - right justified, double byte support, windowing	      : 	 ;=W
;  RIGHTS_DISP	 - right justified, no double byte support, windowing	      : 	 ;=W
;  RIGHT_H_DISP  - right justified, double byte support, horizontal scrolling : 	 ;=W
;									      : 	 ;=W
; JUSTIFY ROUTINES							      : 	 ;=W
;  LEFT_H_JUST	 - left justified, horizontal scrolling 		      : 	 ;=W
;  LEFT_JUST	 - left justified, windowing				      : 	 ;=W
;  RIGHT_H_JUST  - right justified, horizontal scrolling		      : 	 ;=W
;  RIGHT_JUST	 - right justified, windowing				      : 	 ;=W
;									      : 	 ;=W
; Entry:    ES:SI - ICB control block					      : 	 ;=W
;	    DS:DI - IN control block					      : 	 ;=W
; Exit:     none							      : 	 ;=W
;									      : 	 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;											 ;=W
SET_DISP_ADDR  PROC NEAR								 ;=W
;
	       PUSH AX									 ;=W
	       PUSH BX									 ;=W
;
	       TEST ES:[SI]+ICB_OPT1,ICB_RJU ;check if field right just 		 ;=W
	       JNE  SD20		     ;if yes, jump				 ;=W
;
; Display value of input buffer left justified						 ;=W
;
	       TEST ES:[SI]+ICB_OPT3,ICB_HOR ;check if field is in horizontial		 ;=W
	       JE   SD10		     ;no,  windowing mode			 ;=W
;
	       MOV  AX,OFFSET LEFT_H_DISP						 ;=W
	       MOV  BX,OFFSET LEFT_H_JUST						 ;=W
;
	       JMP  SDEXIT								 ;=W
SD10:											 ;=W
	       MOV  AX,OFFSET LEFT_DISP 						 ;=W
	       MOV  BX,OFFSET LEFT_JUST 						 ;=W
;
	       TEST DS:[DI]+IN_OPT,IN_ADBCS  ;check if double byte is active		 ;=W
	       JNE  SDEXIT		     ;yes					 ;=W
	       MOV  AX,OFFSET LEFTS_DISP     ;no, single byte only			 ;=W
	       JMP  SDEXIT								 ;=W
;
; Display default value of input buffer right justified 				 ;=W
;
SD20:											 ;=W
	       TEST ES:[SI]+ICB_OPT3,ICB_HOR ;check if field is in horizontial		 ;=W
	       JE   SD30		     ;no,  windowing mode			 ;=W
;
	       MOV  AX,OFFSET RIGHT_H_DISP						 ;=W
	       MOV  BX,OFFSET RIGHT_H_JUST						 ;=W
;
	       JMP  SDEXIT								 ;=W
SD30:											 ;=W
	       MOV  AX,OFFSET RIGHT_DISP						 ;=W
	       MOV  BX,OFFSET RIGHT_DISP						 ;=W
;
	       TEST DS:[DI]+IN_OPT,IN_ADBCS  ;check if double byte is active		 ;=W
	       JNE  SDEXIT		     ;yes					 ;=W
	       MOV  AX,OFFSET RIGHTS_DISP    ;no, single byte only			 ;=W
;
SDEXIT: 										 ;=W
	       MOV  DS:[DI]+WR_DISPLAY,AX    ;save addr of routine to call		 ;=W
	       MOV  DS:[DI]+WR_JUSTIFY,BX    ;save addr of routine to call		 ;=W
;
	       POP  BX									 ;=W
	       POP  AX									 ;=W
;
	       RET									 ;=W
SET_DISP_ADDR  ENDP									 ;=W
;
PAGE											 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;									      : 	 ;=W
; RIGHTS_DISP								      : 	 ;=W
;									      : 	 ;=W
; Entry:								      : 	 ;=W
;									      : 	 ;=W
; Exit: 								      : 	 ;=W
;									      : 	 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;											 ;=W
RIGHTS_DISP    PROC NEAR								 ;=W
;											 ;=W
	       ;									 ;=W
	       ; code here								 ;=W
	       ;									 ;=W
;											 ;=W
	       RET									 ;=W
RIGHTS_DISP    ENDP									 ;=W
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; RIGHT_H_DISP								      :
;									      :
; Entry:								      :
;									      :
; Exit: 								      :
;									      :
;-----------------------------------------------------------------------------+
;
RIGHT_H_DISP   PROC NEAR
;
	       ;
	       ; code here
	       ;
;
	       RET
RIGHT_H_DISP   ENDP
;
PAGE											 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;									      : 	 ;=W
; RIGHT_DISP								      : 	 ;=W
;									      : 	 ;=W
; Entry:								      : 	 ;=W
;									      : 	 ;=W
; Exit: 								      : 	 ;=W
;									      : 	 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;											 ;=W
RIGHT_DISP     PROC NEAR								 ;=W
;											 ;=W
	       ;									 ;=W
	       ; code here								 ;=W
	       ;									 ;=W
;											 ;=W
	       RET									 ;=W
RIGHT_DISP     ENDP									 ;=W
;											 ;=W
PAGE											 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;									      : 	 ;=W
; LEFT_H_DISP								      : 	 ;=W
;									      : 	 ;=W
;	  Calculates if the specified character will fit in the input	      : 	 ;=W
;	  buffer at the specified character position without display.	      : 	 ;=W
;	  The byte offset where this character should be inserted is	      : 	 ;=W
;	  returned or a flag indicating that the character will not fit.      : 	 ;=W
;									      : 	 ;=W
;	  Displays the specified portion of the input field buffer from       : 	 ;=W
;	  the left character marker to the end of the field.  The following   : 	 ;=W
;	  display options are handled by this routine:			      : 	 ;=W
;									      : 	 ;=W
;	  - Display of the input field in a wrapped window		      : 	 ;=W
;	  - Adjustment of double byte characters to prevent malformed	      : 	 ;=W
;	    characters							      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
;	  The following pointers are used:				      : 	 ;=W
;									      : 	 ;=W
;	    ÚÄ (ICB_FIELDSEG:ICB_FIELDOFF) Beginning address of input	      : 	 ;=W
;	    ³				 buffer in memory.		      : 	 ;=W
;	    ³								      : 	 ;=W
;	    ³		ÚÄ (WR_HRCHAR)	 Left marker delimiting the left      : 	 ;=W
;	    ³		³		 most character position in the       : 	 ;=W
;	    ³		³		 input buffer.			      : 	 ;=W
;	    ³		³						      : 	 ;=W
;	    ³		³						      : 	 ;=W
;	    ³		³						      : 	 ;=W
;	    ³		³						      : 	 ;=W
;	    ³		³						      : 	 ;=W
;	  ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;	  ³ S ³ L ³ T ³ L ³ T ³ S ³ L ³ T ³ S ³ S ³ S ³ S ³   ³   ³	      : 	 ;=W
;	  ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ	      : 	 ;=W
;	    ³	      ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´	      : 	 ;=W
;	    ³	      ³    Area to display (ICB_WIDTH)			      : 	 ;=W
;	    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	      : 	 ;=W
;				     ³					      : 	 ;=W
;		ICB_FIELDLEN  Length of input field in bytes.		      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
; Entry:  ES:SI        = Points to current ICB				      : 	 ;=W
;	  DS:DI        = Points to PB					      : 	 ;=W
;									      : 	 ;=W
;	  WR_CATTR     = Logical color attribute to use when updating screen  : 	 ;=W
;			 if the use of the color attribute string is not      : 	 ;=W
;			 specified.					      : 	 ;=W
;									      : 	 ;=W
;	  CR_RCOFF     = Beginning offset of the upper left input field       : 	 ;=W
;			 display corner from the beginning of the video       : 	 ;=W
;			 buffer.					      : 	 ;=W
;									      : 	 ;=W
;	  CR_SCRWIDTH  = Width of the video buffer in characters and	      : 	 ;=W
;			 attributes.					      : 	 ;=W
;									      : 	 ;=W
;	  WR_HRCHAR    = The offset into the input buffer, in characters,     : 	 ;=W
;			 of where to begin display.			      : 	 ;=W
;									      : 	 ;=W
; Exit:   (none)							      : 	 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;											 ;=W
LEFT_H_DISP    PROC NEAR								 ;=W
;
	       PUSH ES			     ;save PB pointers				 ;=W
	       PUSH DI									 ;=W
	       PUSH BX									 ;=W
	       PUSH [DI]+CR_RCOFF	     ;save input field display offset		 ;=W
;											 ;=W
; Initialize MOVEG parm block								 ;=W
;
	       MOV  AX,ES:[SI]+ICB_FIELDOFF  ;get offset of the input buffer		 ;=W
	       MOV  [DI]+WR_FIELDOFF,AX 						 ;=W
											 ;=W
	       MOV  AX,ES:[SI]+ICB_FIELDSEG  ;get segment of the input buffer		 ;=W
	       MOV  [DI]+MG_TEXTSEG,AX							 ;=W
											 ;=W
	       MOV  AX,ES:[SI]+ICB_ATTROFF   ;get offset of color attribute buffer	 ;=W
	       MOV  [DI]+MG_ATTOFF,AX							 ;=W
											 ;=W
	       MOV  AX,ES:[SI]+ICB_ATTRSEG   ;get segment of color attribute		 ;=W
	       MOV  [DI]+MG_ATTSEG,AX	     ;buffer					 ;=W
											 ;=W
	       MOV  AX,[DI]+IN_LVBSEG	     ;get segment of the LVB			 ;=W
	       MOV  [DI]+MG_MIXSEG,AX							 ;=W
											 ;=W
	       MOV  AL,[DI]+WR_CATTR	     ;get logical color attribute		 ;=W
	       MOV  [DI]+MG_SOURCE_A,AL 						 ;=W
;											 ;=W
; Display all characters in input buffer starting with WR_HRCHAR			 ;=W
; and continuing until ICB_WIDTH-1 number of characters has been displayed.		 ;=W
;
	       MOV  AX,ES:[SI]+ICB_FIELDOFF  ;calcuate beginning character		 ;=W
	       ADD  AX,[DI]+WR_HRBYTE	     ;to display				 ;=W
	       DEC  AX									 ;=W
	       MOV  [DI]+WR_FIELDOFF,AX      ;save it					 ;=W
	       MOV  [DI]+MG_TEXTOFF,AX	     ; to display				 ;=W
;
	       MOV  [DI]+MG_OPT,MG_WA+MG_SC+MG_UA					 ;=W
					     ;set write attribute option		 ;=W
					     ;set use logical attribute option		 ;=W
	       TEST ES:[SI]+ICB_OPT1,ICB_PSW ;check if password option active		 ;=W
	       JNE  LHD10								 ;=W
;
	       OR   [DI]+MG_OPT,MG_WC	     ;set write character option		 ;=W
LHD10:											 ;=W
	       MOV  AX,ES:[SI]+ICB_WIDTH     ;get field width				 ;=W
	       MOV  [DI]+MG_NUM,AX	     ;number of words to move into the		 ;=W
					     ; LVB					 ;=W
;
	       MOV  AX,[DI]+IN_LVBOFF	     ;set the actual LVB offset of		 ;=W
	       ADD  AX,[DI]+CR_RCOFF	     ; the character to write			 ;=W
	       MOV  [DI]+MG_MIXOFF,AX							 ;=W
;
	       CALL PCMOVEG_CALL	     ;call PCMOVEG to write the char(s) 	 ;=W
;											 ;=W
; Check if last character is DBCS							 ;=W
;											 ;=W
	       PUSH ES									 ;=W
	       PUSH SI									 ;=W
;
	       MOV  AX,ES:[SI]+ICB_FIELDSEG ;get input buffer segment			 ;=W
	       MOV  BX,ES:[SI]+ICB_FIELDOFF ;get input buffer offset			 ;=W
	       ADD  BX,[DI]+WR_HRBYTE	    ;add offset of beginning of window		 ;=W
	       ADD  BX,ES:[SI]+ICB_WIDTH    ;add width to get last character		 ;=W
	       SUB  BX,2		    ;subtract to get correct byte		 ;=W
	       MOV  ES,AX								 ;=W
	       MOV  SI,BX								 ;=W
	       MOV  AL,ES:[SI]		    ;get the character				 ;=W
;
	       POP  SI									 ;=W
	       POP  ES									 ;=W
;
	       PUSH AX									 ;=W
	       MOV  [DI]+DBC_KS,AL							 ;=W
	       CALL PCINDBC_CALL	    ;check if char is lead DBCS 		 ;=W
	       POP  AX									 ;=W
	       TEST [DI]+DBC_STAT,DBC_DBCS  ;is it ?					 ;=W
	       JE   LHD30		    ;no, display the character			 ;=W
;
	       MOV  AL,1DH		    ;display '', can't split DBCS char          ;=W
;											 ;=W
; Display the last character								 ;=W
;											 ;=W
LHD30:											 ;=W
	       MOV  [DI]+MG_OPT,MG_WA+MG_SC+MG_UA					 ;=W
					     ;set write attribute option		 ;=W
					     ;set use logical attribute option		 ;=W
	       TEST ES:[SI]+ICB_OPT1,ICB_PSW ;check if password option active		 ;=W
	       JNE  LHD40								 ;=W
;
	       OR   [DI]+MG_OPT,MG_WC+MG_UC  ;set write character option		 ;=W
LHD40:											 ;=W
	       MOV  [DI]+MG_SOURCE_C,AL      ;character to display			 ;=W
	       MOV  [DI]+MG_NUM,1	     ;number of words to move into the		 ;=W
					     ; LVB					 ;=W
;
	       MOV  AX,ES:[SI]+ICB_WIDTH     ;add width to get last character		 ;=W
	       MOV  BX,2								 ;=W
	       MUL  BX			     ;x2 to account for attr. bytes		 ;=W
	       ADD  AX,[DI]+IN_LVBOFF	     ;set the actual LVB offset of		 ;=W
	       ADD  AX,[DI]+CR_RCOFF	     ; the character to write			 ;=W
	       SUB  AX,2		     ;subtract to get correct byte		 ;=W
	       MOV  [DI]+MG_MIXOFF,AX							 ;=W
;
	       CALL PCMOVEG_CALL	     ;call PCMOVEG to write the char(s) 	 ;=W
LHDEXIT:										 ;=W
	       POP  [DI]+CR_RCOFF	     ;save input field display offset		 ;=W
	       POP  BX			     ;restore registers 			 ;=W
	       POP  DI									 ;=W
	       POP  ES									 ;=W
;
	       RET									 ;=W
LEFT_H_DISP    ENDP									 ;=W
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; LEFT_DISP								      :
;									      :
;	  Calculates if the specified character will fit in the input	      :
;	  buffer at the specified character position without display.	      :
;	  The byte offset where this character should be inserted is	      :
;	  returned or a flag indicating that the character will not fit.      :
;									      :
;	  Displays the specified portion of the input field buffer from       :
;	  the left character marker to the end of the field.  The following   :
;	  display options are handled by this routine:			      :
;									      :
;	  - Display of the input field in a wrapped window		      :
;	  - Adjustment of double byte characters to prevent malformed	      :
;	    characters							      :
;									      :
;									      :
;	  The following pointers are used:				      :
;									      :
;	    ÚÄ (ICB_FIELDSEG:ICB_FIELDOFF) Beginning address of input	      :
;	    ³				 buffer in memory.		      :
;	    ³								      :
;	    ³		ÚÄ (WR_LEFTCHAR) Left marker delimiting the left      :
;	    ³		³		 most character position in the       :
;	    ³		³		 input buffer.			      :
;	    ³		³						      :
;	    ³		³		 Right marker delimiting the right    :
;	    ³		³		 most character position in the       :
;	    ³		³		 input buffer.	 (WR_RIGHTCHAR)       :
;	    ³		³					³	      :
;	  ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      :
;	  ³ S ³ L ³ T ³ L ³ T ³ S ³ L ³ T ³ S ³ S ³ S ³ S ³   ³   ³	      :
;	  ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ	      :
;	    ³	      ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´	      :
;	    ³	      ³    Area to display				      :
;	    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	      :
;				     ³					      :
;		ICB_FIELDLEN  Length of input field in bytes.		      :
;									      :
;									      :
; Entry:  ES:SI        = Points to current ICB				      :
;	  DS:DI        = Points to PB					      :
;									      :
;	  AX	     1 = This option will calculate if the specified number   :
;			 of bytes in BX can fit into input buffer at the      :
;			 specified character position considering the display :
;			 coordinates and options.  No update of the display   :
;			 screen will occur.  A flag indicating if the bytes   :
;			 can be inserted or not is returned.  If the bytes    :
;			 will fit the offset from the beginning of the input  :
;			 field in bytes is returned indicating where the      :
;			 characters should be inserted. 		      :
;									      :
;		     2 = This option will update the display screen in the    :
;			 proper format with the input buffer characters       :
;			 starting at the specified left offset character      :
;			 to the right character marker. 		      :
;									      :
;	  BX	       = Number of bytes to insert starting at the specified  :
;			 character position.				      :
;									      :
;	  WR_CATTR     = Logical color attribute to use when updating screen  :
;			 if the use of the color attribute string is not      :
;			 specified.					      :
;									      :
;	  CR_RCOFF     = Beginning offset of the upper left input field       :
;			 display corner from the beginning of the video       :
;			 buffer.					      :
;									      :
;	  CR_SCRWIDTH  = Width of the video buffer in characters and	      :
;			 attributes.					      :
;									      :
;	  WR_LEFTCHAR  = The offset into the input buffer, in characters,     :
;			 of where the specified bytes should fit.	      :
;									      :
;	  WR_RIGHTCHAR = The offset into the input buffer, in characters,     :
;			 of where the right most character position.	      :
;									      :
;									      :
; Exit:   If AX on entry is set to 1 then on exit:			      :
;									      :
;	  AX	     0 = The specified number of characters will fit.	      :
;		     1 = The specified number of characters will not fit.     :
;									      :
;	  WR_LEFTBYTE  = The offset into the input buffer, in bytes, of the   :
;			 left most character position.			      :
;									      :
;	  WR_RIGHTBYTE = The offset into the input buffer, in bytes, of the   :
;			 right most character position. 		      :
;									      :
;									      :
;	 If AX on entry is set to 2 then the input field buffer is	      :
;	 displayed on the screen.					      :
;									      :
;-----------------------------------------------------------------------------+
;
LEFT_DISP      PROC NEAR
;
	       PUSH ES			     ;save PB pointers
	       PUSH DI
	       PUSH BX
	       PUSH [DI]+CR_RCOFF	     ;save input field display offset
;
	       CALL LEFT_DISP_INIT	     ;initialize internal counter & vars	 ;=W
;
	       JMP  LF20		     ;begin of first row
;
; Start a new row in LVB
;
LF10:	       MOV  AX,[DI]+CR_RCOFF	     ;set ptr into LVB to next row.
	       ADD  AX,[DI]+CR_SCRWIDTH      ; Start with current position in
	       SUB  AX,ES:[SI]+ICB_WIDTH     ; LVB, add screen width in text
	       SUB  AX,ES:[SI]+ICB_WIDTH     ; and attributes, then subtract
	       MOV  [DI]+CR_RCOFF,AX	     ; the length of the input field
					     ; twice since length is just in
					     ; text chars
;
; Do not start new row
;
LF20:	       MOV  AX,ES:[SI]+ICB_WIDTH     ;counter contains number of bytes
	       MOV  [DI]+WR_CNTR2,AX	     ; available in current row of
					     ; input field
;
; Prepare to place next byte into LVB, verify chars remaining in input buffer
;
LF30:	       MOV  AX,[DI]+WR_CNTR3	     ;check if last character has been
	       CMP  [DI]+WR_RIGHTCHAR,AX     ; written in LVB (rightmost)
	       JGE  LF40		     ;if not last char jump ?
;
	       JMP  LF160		     ;yes, last character written
					     ; prepare to exit
;
; Check if end of field on display has been reached
;
LF40:	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;loop if number chars moved is
	       CMP  [DI]+WR_CNTR1,AX	     ; less than input buffer length
	       JLE  LF50		     ;
;
	       JMP  LF160
;
; Not complete
;
LF50:	       CMP  [DI]+WR_CNTR2,0	     ;loop while number of bytes
	       JE   LF10		     ; remaining in the row is greater
					     ; than zero, jump if bytes avail
;
	       CMP  [DI]+WR_MOVE,1	     ;check if entry option is to
	       JNE  LF60		     ; determine if bytes may be
					     ; inserted in displayed field
;
	       MOV  AX,[DI]+WR_LEFTCHAR      ;check if insertion calculations
	       CMP  [DI]+WR_CNTR3,AX	     ; should begin by comparing
	       JNE  LF60		     ; current counter with beginning
					     ; left character marker
;
	       MOV  AL,1		     ;check if insertion calculations
	       CMP  [DI]+WR_INSDONE,AL	     ; are complete
	       JE   LF60		     ;if yes, jump
;
; Adjust counters after pretending to insert a character into string and LVB
;
	       MOV  AX,[DI]+WR_BYTESINST     ;dec number bytes avail in row
	       ADD  [DI]+WR_CNTR1,AX	     ;inc number bytes moved into LVB
	       SUB  [DI]+WR_CNTR2,AX	     ;dec number bytes remaining in row
	       MOV  [DI]+WR_INSDONE,1	     ;set flag indicating insert calc
	       JMP  LF30		     ; complete
;
; Determine if current byte is a DBCS lead byte
;
LF60:	       MOV  BX,[DI]+WR_FIELDOFF      ;get the current byte in the
;
	       PUSH ES			     ;save registers
	       PUSH SI
;
	       PUSH ES:[SI]+ICB_FIELDSEG     ; input field buffer
	       PUSH [DI]+WR_FIELDOFF	     ;get the current byte in the
	       POP  SI
	       POP  ES
;
	       MOV  AL,ES:[SI]		     ;get character in input buffer
;
	       POP  SI			     ;restore registers
	       POP  ES
;
	       MOV  [DI]+DBC_KS,AL
;
	       CALL PCINDBC_CALL	     ;call routine to check if char
					     ; is lead double byte char
;
	       TEST [DI]+DBC_STAT,DBC_DBCS   ;check if char is lead DBCS
	       JNE  LF70		     ;if yes, jump to double byte code
;
	       JMP  LF130		     ;if no, jump to single byte code
;
; Current byte is leading byte of a double byte character
;
LF70:	       CMP  [DI]+WR_CNTR2,1	     ;check if there is room in current
	       JNE  LF80		     ; row for double byte character
;
	       JMP  LF110		     ;no room, adjust to next row
;
; Double byte character fits on current row
;
LF80:	       CMP  [DI]+WR_MOVE,2	     ;check if option to actually
	       JNE  LF100		     ; update display is active
;
	       MOV  AX,[DI]+WR_LEFTCHAR      ;check if character should be
	       CMP  [DI]+WR_CNTR3,AX	     ; displayed by verifying that
	       JL   LF100		     ; current character falls
					     ; between the left and right
	       MOV  AX,[DI]+WR_RIGHTCHAR     ; character markers
	       CMP  [DI]+WR_CNTR3,AX
	       JG   LF100
;
	       MOV  AX,[DI]+WR_FIELDOFF      ;get offset of character(s)
	       MOV  [DI]+MG_TEXTOFF,AX	     ; to display
;
	       MOV  [DI]+MG_OPT,MG_WA+MG_SC  ;set write attribute option
;
	       TEST ES:[SI]+ICB_OPT1,ICB_USC ;use attribute string
	       JNE  LF84
;
	       OR   [DI]+MG_OPT,MG_UA	     ;set use logical attribute option
;
LF84:	       TEST ES:[SI]+ICB_OPT1,ICB_PSW ;is option for password write
	       JNE  LF85		     ; active
;
	       OR   [DI]+MG_OPT,MG_WC	     ;set write character option
;
LF85:	       MOV  [DI]+MG_NUM,2	     ;number of words to move into LVB
	       MOV  AX,[DI]+IN_LVBOFF	     ;set actual offset into LVB
	       ADD  AX,[DI]+CR_RCOFF	     ; where character(s) will be
	       MOV  [DI]+MG_MIXOFF,AX	     ; written
;
	       CALL PCMOVEG_CALL	     ;call PCMOVEG to write characters
;
; Adjust pointers and counters after moving double byte character
;
LF100:	       MOV  AX,[DI]+WR_CNTR3	     ;LEFT returns the right and left
	       CMP  AX,[DI]+WR_LEFTCHAR      ; byte positions of the right and
	       JNE  LF104		     ; left chars.  See if the current
;
	       MOV  AX,[DI]+WR_CNTR4	     ; char is the left char, if so
	       MOV  [DI]+WR_LEFTBYTE,AX      ; store the byte offset, WR_CNTR4,
	       JMP  LF106		     ; into WR_LEFTBYTE
;
; Update right byte marker
;
LF104:	       MOV  AX,[DI]+WR_CNTR3	     ;LEFT returns the right and left
	       CMP  AX,[DI]+WR_RIGHTCHAR     ; byte positions of the right and
	       JNE  LF106		     ; left chars.  See if the current
;
	       MOV  AX,[DI]+WR_CNTR4	     ; char is the right char, if so
	       MOV  [DI]+WR_RIGHTBYTE,AX     ; store the byte offset, WR_CNTR4,
					     ; into WR_RIGHTBYTE
;
LF106:	       ADD  [DI]+WR_FIELDOFF,2	     ;inc number bytes moved from input
					     ; buffer
	       ADD  [DI]+CR_RCOFF,4	     ;inc pointer into LVB
	       ADD  [DI]+WR_CNTR1,2	     ;inc number of bytes moved into
					     ; LVB
	       SUB  [DI]+WR_CNTR2,2	     ;dec number of bytes remain
	       INC  [DI]+WR_CNTR3	     ;inc number of characters moved
					     ; into LVB from input string
	       ADD  [DI]+WR_CNTR4,2	     ;inc number of bytes moved from
	       JMP  LF30		     ; input string
;
; Blank fill remaining screen character positions on current row to prevent
;  double byte character from being split
;
LF110:	       CMP  [DI]+WR_MOVE,2	     ;check if option to update display
	       JNE  LF120		     ; is active
;
	       MOV  AX,[DI]+WR_LEFTCHAR      ;check if current character
	       CMP  [DI]+WR_CNTR3,AX	     ; should be displayed by verifying
	       JL   LF120		     ; that the character falls
					     ; within  the left and right
	       MOV  AX,[DI]+WR_RIGHTCHAR     ; character markers
	       CMP  [DI]+WR_CNTR3,AX
	       JG   LF120
;
	       MOV  AL,WR_BLANK 	     ;get blanking character
	       MOV  [DI]+MG_SOURCE_C,AL
;
	       MOV  [DI]+MG_OPT,MG_WA+MG_SC+MG_UC
					     ;set write attr, char and syn chk
	       TEST ES:[SI]+ICB_OPT1,ICB_USC
	       JNE  LF114		     ;use attribute string
;
	       OR   [DI]+MG_OPT,MG_UA	     ;set use logical attribute option
;
LF114:	       TEST ES:[SI]+ICB_OPT1,ICB_PSW ;check if password option active
	       JNE  LF115
;
	       OR   [DI]+MG_OPT,MG_WC	     ;set write character option
;
LF115:	       MOV  [DI]+MG_NUM,1	     ;number of words to move into the
					     ; LVB
	       MOV  AX,[DI]+IN_LVBOFF	     ;set the actual LVB offset of
	       ADD  AX,[DI]+CR_RCOFF	     ; the character to write
	       MOV  [DI]+MG_MIXOFF,AX
;
	       CALL PCMOVEG_CALL	     ;call PCMOVEG to write the char(s)
;
; Adjust pointers and counters after writing blanking character to LVB
;
LF120:	       ADD  [DI]+CR_RCOFF,2	     ;inc pointer into the LVB
	       INC  [DI]+WR_CNTR1	     ;inc number of bytes moved into
					     ; the LVB
	       DEC  [DI]+WR_CNTR2	     ;dec number of bytes remaining in
	       JMP  LF10		     ; the current row
;
; Byte is a single byte character
;
LF130:	       CMP  [DI]+WR_MOVE,2	     ;check if option to update display
	       JNE  LF150		     ; is active
;
	       MOV  AX,[DI]+WR_LEFTCHAR      ;check if current character
	       CMP  [DI]+WR_CNTR3,AX	     ; should be displayed by verifying
	       JL   LF150		     ; that the character falls
;
	       MOV  AX,[DI]+WR_RIGHTCHAR     ; character markers
	       CMP  [DI]+WR_CNTR3,AX
	       JG   LF150
;
	       MOV  AX,[DI]+WR_FIELDOFF      ;get offset of character(s)
	       MOV  [DI]+MG_TEXTOFF,AX	     ; to display
;
	       MOV  [DI]+MG_OPT,MG_WA+MG_SC+MG_UA
					     ;set write attribute option
					     ;set use logical attribute option
	       TEST ES:[SI]+ICB_OPT1,ICB_PSW ;check if password option active
	       JNE  LF135
;
	       OR   [DI]+MG_OPT,MG_WC	     ;set write character option
;
LF135:	       MOV  [DI]+MG_NUM,1	     ;number of words to move into the
					     ; LVB
;
	       MOV  AX,[DI]+IN_LVBOFF	     ;set the actual LVB offset of
	       ADD  AX,[DI]+CR_RCOFF	     ; the character to write
	       MOV  [DI]+MG_MIXOFF,AX
;
	       CALL PCMOVEG_CALL	     ;call PCMOVEG to write the char(s)
;
; Adjust pointers and counters after moving single byte character
;
LF150:	       MOV  AX,[DI]+WR_CNTR3	     ;LEFT returns the right and left
	       CMP  AX,[DI]+WR_LEFTCHAR      ; byte positions of the right and
	       JNE  LF154		     ; left chars.  See if the current
;
	       MOV  AX,[DI]+WR_CNTR4	     ; char is the left char, if so
	       MOV  [DI]+WR_LEFTBYTE,AX      ; store the byte offset, WR_CNTR4,
	       JMP  LF156		     ; into WR_LEFTBYTE
;
; Update right byte marker
;
LF154:	       MOV  AX,[DI]+WR_CNTR3	     ;LEFT returns the right and left
	       CMP  AX,[DI]+WR_RIGHTCHAR     ; byte positions of the right and
	       JNE  LF156		     ; left chars.  See if the current
;
	       MOV  AX,[DI]+WR_CNTR4	     ; char is the right char, if so
	       MOV  [DI]+WR_RIGHTBYTE,AX     ; store the byte offset, WR_CNTR4,
					     ; into WR_RIGHTBYTE
;
LF156:	       INC  [DI]+WR_FIELDOFF	     ;inc pointer input buffer
	       ADD  [DI]+CR_RCOFF,2	     ;inc pointer into LVB
	       INC  [DI]+WR_CNTR1	     ;inc counter with number bytes
					     ; moved into LVB
	       DEC  [DI]+WR_CNTR2	     ;dec counter with number of bytes
					     ; remaining in current row
	       ADD  [DI]+WR_CNTR3,1	     ;inc counter with number of chars
					     ; moved into the LVB from input
					     ; buffer
	       ADD  [DI]+WR_CNTR4,1	     ;inc counter with number of bytes
	       JMP  LF30		     ; moved into the LVB from input
					     ; buffer
;
; Completed updating LVB, adjust pointers
;
LF160:	       CMP  [DI]+WR_MOVE,1	     ;Check if option to calculate
	       JNE  LFEXIT		     ; if chars fit in buffer
;
; Set up proper return values for insert calculation
;
	       MOV  AX,1		     ;set flag indicating insert did
					     ; not fit
	       MOV  BX,[DI]+WR_CNTR3	     ;see if input field fit into LVB
	       DEC  BX			     ; by comparing the right char
	       CMP  [DI]+WR_RIGHTCHAR,BX     ; number with the number of chars
	       JNE  LFEXIT		     ; moved into the LVB.  If they
					     ; are equal the string fit into
					     ; the LVB.
	       CMP  [DI]+WR_INSDONE,1	     ;see if insert has been done
	       JE   LF170		     ;if yes set up return values
;
	       MOV  BX,ES:[SI]+ICB_FIELDLEN  ;if no, then insert is at end of
	       SUB  BX,[DI]+WR_CNTR1	     ; line i.e. past right char
	       INC  BX			     ;see if there is enough room left
	       CMP  BX,[DI]+WR_BYTESINST     ; to display char being inserted
	       JL   LFEXIT
;
LF170:	       MOV  AX,0		     ;set flag indicating insert fits
;
; Restores the registers to entry values and exits
;
LFEXIT:        POP  [DI]+CR_RCOFF	     ;save input field display offset
;
	       POP  BX			     ;restore registers
	       POP  DI
	       POP  ES
;
	       RET
LEFT_DISP      ENDP
;
PAGE
;-----------------------------------------------------------------------------+ 	 ;=W
;									      : 	 ;=W
; LEFTS_DISP			     (no double byte support)		      : 	 ;=W
;									      : 	 ;=W
;	  Calculates if the specified character will fit in the input	      : 	 ;=W
;	  buffer at the specified character position without display.	      : 	 ;=W
;	  The byte offset where this character should be inserted is	      : 	 ;=W
;	  returned or a flag indicating that the character will not fit.      : 	 ;=W
;									      : 	 ;=W
;	  Displays the specified portion of the input field buffer from       : 	 ;=W
;	  the left character marker to the end of the field.  The following   : 	 ;=W
;	  display options are handled by this routine:			      : 	 ;=W
;									      : 	 ;=W
;	  - Display of the input field in a wrapped window		      : 	 ;=W
;	  - Adjustment of double byte characters to prevent malformed	      : 	 ;=W
;	    characters							      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
;	  The following pointers are used:				      : 	 ;=W
;									      : 	 ;=W
;	    ÚÄ (ICB_FIELDSEG:ICB_FIELDOFF) Beginning address of input	      : 	 ;=W
;	    ³				 buffer in memory.		      : 	 ;=W
;	    ³								      : 	 ;=W
;	    ³		ÚÄ (WR_LEFTCHAR) Left marker delimiting the left      : 	 ;=W
;	    ³		³		 most character position in the       : 	 ;=W
;	    ³		³		 input buffer.			      : 	 ;=W
;	    ³		³						      : 	 ;=W
;	    ³		³		 Right marker delimiting the right    : 	 ;=W
;	    ³		³		 most character position in the       : 	 ;=W
;	    ³		³		 input buffer.	 (WR_RIGHTCHAR)       : 	 ;=W
;	    ³		³					³	      : 	 ;=W
;	  ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿	      : 	 ;=W
;	  ³ S ³ L ³ T ³ L ³ T ³ S ³ L ³ T ³ S ³ S ³ S ³ S ³   ³   ³	      : 	 ;=W
;	  ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÍÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ	      : 	 ;=W
;	    ³	      ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´	      : 	 ;=W
;	    ³	      ³    Area to display				      : 	 ;=W
;	    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	      : 	 ;=W
;				     ³					      : 	 ;=W
;		ICB_FIELDLEN  Length of input field in bytes.		      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
; Entry:  ES:SI        = Points to current ICB				      : 	 ;=W
;	  DS:DI        = Points to PB					      : 	 ;=W
;									      : 	 ;=W
;	  AX	     1 = This option will calculate if the specified number   : 	 ;=W
;			 of bytes in BX can fit into input buffer at the      : 	 ;=W
;			 specified character position considering the display : 	 ;=W
;			 coordinates and options.  No update of the display   : 	 ;=W
;			 screen will occur.  A flag indicating if the bytes   : 	 ;=W
;			 can be inserted or not is returned.  If the bytes    : 	 ;=W
;			 will fit the offset from the beginning of the input  : 	 ;=W
;			 field in bytes is returned indicating where the      : 	 ;=W
;			 characters should be inserted. 		      : 	 ;=W
;									      : 	 ;=W
;		     2 = This option will update the display screen in the    : 	 ;=W
;			 proper format with the input buffer characters       : 	 ;=W
;			 starting at the specified left offset character      : 	 ;=W
;			 to the right character marker. 		      : 	 ;=W
;									      : 	 ;=W
;	  BX	       = Number of bytes to insert starting at the specified  : 	 ;=W
;			 character position.				      : 	 ;=W
;									      : 	 ;=W
;	  WR_CATTR     = Logical color attribute to use when updating screen  : 	 ;=W
;			 if the use of the color attribute string is not      : 	 ;=W
;			 specified.					      : 	 ;=W
;									      : 	 ;=W
;	  CR_RCOFF     = Beginning offset of the upper left input field       : 	 ;=W
;			 display corner from the beginning of the video       : 	 ;=W
;			 buffer.					      : 	 ;=W
;									      : 	 ;=W
;	  CR_SCRWIDTH  = Width of the video buffer in characters and	      : 	 ;=W
;			 attributes.					      : 	 ;=W
;									      : 	 ;=W
;	  WR_LEFTCHAR  = The offset into the input buffer, in characters,     : 	 ;=W
;			 of where the specified bytes should fit.	      : 	 ;=W
;									      : 	 ;=W
;	  WR_RIGHTCHAR = The offset into the input buffer, in characters,     : 	 ;=W
;			 of where the right most character position.	      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
; Exit:   If AX on entry is set to 1 then on exit:			      : 	 ;=W
;									      : 	 ;=W
;	  AX	     0 = The specified number of characters will fit.	      : 	 ;=W
;		     1 = The specified number of characters will not fit.     : 	 ;=W
;									      : 	 ;=W
;	  WR_LEFTBYTE  = The offset into the input buffer, in bytes, of the   : 	 ;=W
;			 left most character position.			      : 	 ;=W
;									      : 	 ;=W
;	  WR_RIGHTBYTE = The offset into the input buffer, in bytes, of the   : 	 ;=W
;			 right most character position. 		      : 	 ;=W
;									      : 	 ;=W
;									      : 	 ;=W
;	 If AX on entry is set to 2 then the input field buffer is	      : 	 ;=W
;	 displayed on the screen.					      : 	 ;=W
;									      : 	 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
;											 ;=W
LEFTS_DISP    PROC NEAR 								;=W
;
	       PUSH ES			     ;save PB pointers				 ;=W
	       PUSH DI									 ;=W
	       PUSH BX									 ;=W
	       PUSH [DI]+CR_RCOFF	     ;save input field display offset		 ;=W
;
	       CALL LEFT_DISP_INIT	     ;initialize internal counters & vars	 ;=W
;
	       JMP  LS20		     ;begin of first row			 ;=W
;											 ;=W
; Start a new row in LVB								 ;=W
;											 ;=W
LS10:	       MOV  AX,[DI]+CR_RCOFF	     ;set ptr into LVB to next row.		 ;=W
	       ADD  AX,[DI]+CR_SCRWIDTH      ; Start with current position in		 ;=W
	       SUB  AX,ES:[SI]+ICB_WIDTH     ; LVB, add screen width in text		 ;=W
	       SUB  AX,ES:[SI]+ICB_WIDTH     ; and attributes, then subtract		 ;=W
	       MOV  [DI]+CR_RCOFF,AX	     ; the length of the input field		 ;=W
					     ; twice since length is just in		 ;=W
					     ; text chars				 ;=W
;											 ;=W
; Do not start new row									 ;=W
;											 ;=W
LS20:	       MOV  AX,ES:[SI]+ICB_WIDTH     ;counter contains number of bytes		 ;=W
	       MOV  [DI]+WR_CNTR2,AX	     ; available in current row of		 ;=W
					     ; input field				 ;=W
;											 ;=W
; Prepare to place next byte into LVB, verify chars remaining in input buffer		 ;=W
;											 ;=W
LS30:	       MOV  AX,[DI]+WR_CNTR3	     ;check if last character has been		 ;=W
	       CMP  [DI]+WR_RIGHTCHAR,AX     ; written in LVB (rightmost)		 ;=W
	       JGE  LS40		     ;if not last char jump ?			 ;=W
;
	       JMP  LS160		     ;yes, last character written		 ;=W
					     ; prepare to exit				 ;=W
;											 ;=W
; Check if end of field on display has been reached					 ;=W
;											 ;=W
LS40:	       MOV  AX,ES:[SI]+ICB_FIELDLEN  ;loop if number chars moved is		 ;=W
	       CMP  [DI]+WR_CNTR1,AX	     ; less than input buffer length		 ;=W
	       JLE  LS50		     ;						 ;=W
;
	       JMP  LS160								 ;=W
;											 ;=W
; Not complete										 ;=W
;											 ;=W
LS50:	       CMP  [DI]+WR_CNTR2,0	     ;loop while number of bytes		 ;=W
	       JE   LS10		     ; remaining in the row is greater		 ;=W
					     ; than zero, jump if bytes avail		 ;=W
;
	       CMP  [DI]+WR_MOVE,1	     ;check if entry option is to		 ;=W
	       JNE  LS130		     ; determine if bytes may be		 ;=W
					     ; inserted in displayed field		 ;=W
;
	       MOV  AX,[DI]+WR_LEFTCHAR      ;check if insertion calculations		 ;=W
	       CMP  [DI]+WR_CNTR3,AX	     ; should begin by comparing		 ;=W
	       JNE  LS130		     ; current counter with beginning		 ;=W
					     ; left character marker			 ;=W
;
	       MOV  AL,1		     ;check if insertion calculations		 ;=W
	       CMP  [DI]+WR_INSDONE,AL	     ; are complete				 ;=W
	       JE   LS130		     ;if yes, jump				 ;=W
;											 ;=W
; Adjust counters after pretending to insert a character into string and LVB		 ;=W
;											 ;=W
	       MOV  AX,[DI]+WR_BYTESINST     ;dec number bytes avail in row		 ;=W
	       ADD  [DI]+WR_CNTR1,AX	     ;inc number bytes moved into LVB		 ;=W
	       SUB  [DI]+WR_CNTR2,AX	     ;dec number bytes remaining in row 	 ;=W
	       MOV  [DI]+WR_INSDONE,1	     ;set flag indicating insert calc		 ;=W
	       JMP  LS30		     ; complete 				 ;=W
;											 ;=W
; Byte is a single byte character							 ;=W
;											 ;=W
LS130:	       CMP  [DI]+WR_MOVE,2	     ;check if option to update display 	 ;=W
	       JNE  LS150		     ; is active				 ;=W
;
	       MOV  AX,[DI]+WR_LEFTCHAR      ;check if current character		 ;=W
	       CMP  [DI]+WR_CNTR3,AX	     ; should be displayed by verifying 	 ;=W
	       JL   LS150		     ; that the character falls 		 ;=W
					     ; within  the left and right		 ;=W
	       MOV  AX,[DI]+WR_RIGHTCHAR     ; character markers			 ;=W
	       CMP  [DI]+WR_CNTR3,AX							 ;=W
	       JG   LS150								 ;=W
;
	       MOV  AX,[DI]+WR_FIELDOFF      ;get offset of character(s)		 ;=W
	       MOV  [DI]+MG_TEXTOFF,AX	     ; to display				 ;=W
;
	       MOV  [DI]+MG_OPT,MG_WA+MG_SC+MG_UA					 ;=W
					     ;set write attribute option		 ;=W
					     ;set use logical attribute option		 ;=W
	       TEST ES:[SI]+ICB_OPT1,ICB_PSW ;check if password option active		 ;=W
	       JNE  LS135								 ;=W
;
	       OR   [DI]+MG_OPT,MG_WC	     ;set write character option		 ;=W
;
LS135:	       MOV  [DI]+MG_NUM,1	     ;number of words to move into the		 ;=W
					     ; LVB					 ;=W
;
	       MOV  AX,[DI]+IN_LVBOFF	     ;set the actual LVB offset of		 ;=W
	       ADD  AX,[DI]+CR_RCOFF	     ; the character to write			 ;=W
	       MOV  [DI]+MG_MIXOFF,AX							 ;=W
;
	       CALL PCMOVEG_CALL	     ;call PCMOVEG to write the char(s) 	 ;=W
;											 ;=W
; Adjust pointers and counters after moving single byte character			 ;=W
;											 ;=W
LS150:	       MOV  AX,[DI]+WR_CNTR3	     ;LEFT returns the right and left		 ;=W
	       CMP  AX,[DI]+WR_LEFTCHAR      ; byte positions of the right and		 ;=W
	       JNE  LS154		     ; left chars.  See if the current		 ;=W
;
	       MOV  AX,[DI]+WR_CNTR4	     ; char is the left char, if so		 ;=W
	       MOV  [DI]+WR_LEFTBYTE,AX      ; store the byte offset, WR_CNTR4, 	 ;=W
	       JMP  LS156		     ; into WR_LEFTBYTE 			 ;=W
;											 ;=W
; Update right byte marker								 ;=W
;											 ;=W
LS154:	       MOV  AX,[DI]+WR_CNTR3	     ;LEFT returns the right and left		 ;=W
	       CMP  AX,[DI]+WR_RIGHTCHAR     ; byte positions of the right and		 ;=W
	       JNE  LS156		     ; left chars.  See if the current		 ;=W
;
	       MOV  AX,[DI]+WR_CNTR4	     ; char is the right char, if so		 ;=W
	       MOV  [DI]+WR_RIGHTBYTE,AX     ; store the byte offset, WR_CNTR4, 	 ;=W
					     ; into WR_RIGHTBYTE			 ;=W
LS156:	       INC  [DI]+WR_FIELDOFF	     ;inc pointer input buffer			 ;=W
	       ADD  [DI]+CR_RCOFF,2	     ;inc pointer into LVB			 ;=W
	       INC  [DI]+WR_CNTR1	     ;inc counter with number bytes		 ;=W
					     ; moved into LVB				 ;=W
	       DEC  [DI]+WR_CNTR2	     ;dec counter with number of bytes		 ;=W
					     ; remaining in current row 		 ;=W
	       ADD  [DI]+WR_CNTR3,1	     ;inc counter with number of chars		 ;=W
					     ; moved into the LVB from input		 ;=W
					     ; buffer					 ;=W
	       ADD  [DI]+WR_CNTR4,1	     ;inc counter with number of bytes		 ;=W
	       JMP  LS30		     ; moved into the LVB from input		 ;=W
					     ; buffer					 ;=W
;											 ;=W
; Completed updating LVB, adjust pointers						 ;=W
;											 ;=W
LS160:	       CMP  [DI]+WR_MOVE,1	     ;Check if option to calculate		 ;=W
	       JNE  LSEXIT		     ; if chars fit in buffer			 ;=W
;											 ;=W
; Set up proper return values for insert calculation					 ;=W
;											 ;=W
	       MOV  AX,1		     ;set flag indicating insert did		 ;=W
					     ; not fit					 ;=W
	       MOV  BX,[DI]+WR_CNTR3	     ;see if input field fit into LVB		 ;=W
	       DEC  BX			     ; by comparing the right char		 ;=W
	       CMP  [DI]+WR_RIGHTCHAR,BX     ; number with the number of chars		 ;=W
	       JNE  LSEXIT		     ; moved into the LVB.  If they		 ;=W
					     ; are equal the string fit into		 ;=W
					     ; the LVB. 				 ;=W
	       CMP  [DI]+WR_INSDONE,1	     ;see if insert has been done		 ;=W
	       JE   LS170		     ;if yes set up return values		 ;=W
;
	       MOV  BX,ES:[SI]+ICB_FIELDLEN  ;if no, then insert is at end of		 ;=W
	       SUB  BX,[DI]+WR_CNTR1	     ; line i.e. past right char		 ;=W
	       INC  BX			     ;see if there is enough room left		 ;=W
	       CMP  BX,[DI]+WR_BYTESINST     ; to display char being inserted		 ;=W
	       JL   LSEXIT								 ;=W
;
LS170:	       MOV  AX,0		     ;set flag indicating insert fits		 ;=W
;											 ;=W
; Restores the registers to entry values and exits					 ;=W
;											 ;=W
LSEXIT:        POP  [DI]+CR_RCOFF	     ;save input field display offset		 ;=W
;
	       POP  BX			     ;restore registers 			 ;=W
	       POP  DI									 ;=W
	       POP  ES									 ;=W
;
	       RET									 ;=W
LEFTS_DISP     ENDP									 ;=W
;
PAGE
;-----------------------------------------------------------------------------+ 	 ;=W
;									      : 	 ;=W
;  DRAW_DEM								      : 	 ;=W
;	    Draw a input field delimiter				      : 	 ;=W
;									      : 	 ;=W
;  Entry:								      : 	 ;=W
;	   ES:SI  address of icon					      : 	 ;=W
;	   GC_ROW - character row to display delimiter			      : 	 ;=W
;	   GC_COL - character column to display delimiter		      : 	 ;=W
;									      : 	 ;=W
;  Exit:   None 							      : 	 ;=W
;									      : 	 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
DRAW_DEM       PROC NEAR								 ;=W
;
	       PUSH AX									 ;=W
	       PUSH BX									 ;=W
	       PUSH CX									 ;=W
	       PUSH DX									 ;=W
	       PUSH DI									 ;=W
	       PUSH SI									 ;=W
	       PUSH DS									 ;=W
	       PUSH ES									 ;=W
	       PUSH BP									 ;=W
;
	       MOV  BP,AX
;
	       MOV  DX,300H + graph_addr						 ;=W
	       MOV  AH,2		     ; Write Mode 2				 ;=W
	       MOV  AL,5		     ; Write Mode Register			 ;=W
	       OUT  DX,AX								 ;=W
;
	       MOV  DL,seq_addr 							 ;=W
	       MOV  AH,0FFH		     ;enable all maps				 ;=W
	       MOV  AL,s_map		     ;map mask					 ;=W
	       OUT  DX,AX		     ;set the registers 			 ;=W
;
	       MOV  AX,[DI]+WR_ROWBYTES 						 ;=W
	       MOV  BX,50H								 ;=W
	       MUL  BX									 ;=W
											 ;=W
	       MOV  BX,[DI]+GC_ROW							 ;=W
	       MUL  BX									 ;=W
	       ADD  AX,[DI]+GC_COL							 ;=W
;
	       MOV  BH,[DI]+WR_CATTR	     ;get current color attribute		 ;=W
;
	       CMP  [DI]+WR_VIDMODE,11H      ;check for graphics mode 11H
	       JNE  DD05		     ;nop, continue
	       MOV  BH,0FH		     ;yes, mode 11 is only black &
;
DD05:	       MOV  CL,4		     ;count for shift				 ;=W
	       SHR  BX,CL		     ;separate background/foreground		 ;=W
	       MOV  CL,4		     ;count for shift				 ;=W
	       SHR  BL,CL		     ;put in low order nibble			 ;=W
	       XCHG BL,BH		     ;foreground/background are reversed	 ;=W
					     ; for delimiter
; BL = background color, BH = foreground color
	       CMP  BP,02		     ;check if we want to remove delimiters	 ;=W
	       JNE  DD10		     ;no, ok					 ;=W
	       MOV  BH,BL		     ;make both background color		 ;=W
											 ;=W
DD10:											 ;=W
	       MOV  CL,[DI]+WR_VIDMODE							 ;=W
	       MOV  DX,[DI]+IN_OPT
;
	       PUSH ES			     ;make DS:SI point to bit maps		 ;=W
	       POP  DS									 ;=W
;
	       MOV  DI,AX								 ;=W
	       MOV  AX,0A000H								 ;=W
	       MOV  ES,AX								 ;=W
;
	       TEST DX,IN_MCGA		     ;mode 11H, non-VGA hardware?
	       JNE  DD100		     ;if so, go do it
;---------------------------------------------						 ;=W
; Mode 10,11,12 with VGA		     :						 ;=W
;---------------------------------------------						 ;=W
	       MOV  DX,300H + graph_addr       ;graphics chip				 ;=W
	       XOR  CH,CH								 ;=W
;
	       MOV  AL,CL		       ;save vid mode
	       MOV  CL,0EH		       ;# pixel rows in delimiter		 ;=W
	       CMP  AL,10H		       ;are we in graphics mode 10H
	       JE   DD40		       ;yes, # rows ok
	       ADD  CL,2		       ;no, mode 11,12 have 16 pixel rows
DD40:					       ; instead of 14 pixel rows.
	       MOV  BP,02H		       ;# pixel columns/8 in delimiter		 ;=W
;
	       MOV  AH,0FFH								 ;=W
	       MOV  AL,g_bit_mask	       ;bit mask index				 ;=W
	       OUT  DX,AX		       ;set bit mask				 ;=W
DD50:											 ;=W
	       PUSH CX									 ;=W
	       PUSH DI									 ;=W
	       MOV  CX,BP								 ;=W
DD60:											 ;=W
	       MOV  AH,0FFH		       ;background				 ;=W
	       MOV  AL,g_bit_mask	       ;bit mask index				 ;=W
	       OUT  DX,AX		       ;set bit mask				 ;=W
;
	       MOV  AL,ES:[DI]		       ;latch data				 ;=W
	       MOV  ES:[DI],BH		       ;set the dot				 ;=W
;
	       LODSB			       ;foreground				 ;=W
	       XCHG AL,AH								 ;=W
;
	       MOV  AL,g_bit_mask	       ;bit mask index				 ;=W
	       OUT  DX,AX		       ;set bit mask				 ;=W
;
	       MOV  AL,ES:[DI]		       ;latch data				 ;=W
	       MOV  ES:[DI],BL		       ;set the dot				 ;=W
;
	       INC  DI									 ;=W
	       LOOP DD60								 ;=W
;
	       POP  DI									 ;=W
	       ADD  DI,LINELEN								 ;=W
	       POP  CX									 ;=W
	       LOOP DD50								 ;=W
	       JMP  DDEXIT								 ;=W
;---------------------------------------------						 ;=W
; Mode 11H with no VGA			     :						 ;=W
;---------------------------------------------						 ;=W
DD100:	       XOR  CH,CH
	       MOV  CL,10H		     ;# pixel rows in delimiter
	       MOV  BP,02H		     ;# of pixel columns in delimiter

DD110:	       PUSH CX
	       PUSH DI
;
	       MOV  CX,BP
;
DD120:	       LODSB			     ;get icon row
;
DD130:	       XOR  AL,0FFH
	       MOV  ES:[DI],AL		     ;set the dot
	       INC  DI
	       LOOP DD120
;
	       POP  DI
;
	       ADD  DI,50H		     ;line length, 80
;
	       POP  CX
;
	       LOOP DD110
;
DDEXIT:        POP  BP
	       POP  ES
	       POP  DS
	       POP  SI
	       POP  DI
	       POP  DX
	       POP  CX
	       POP  BX
	       POP  AX
;
	       RET
DRAW_DEM       ENDP
;
PAGE
;-----------------------------------------------------------------------------+ 	 ;=W
;									      : 	 ;=W
;  GET_MONO_DOS 							      : 	 ;=W
;	    Get segment and offset of the DOS monocasing table and return it  : 	 ;=W
;									      : 	 ;=W
;  Entry:  None 							      : 	 ;=W
;									      : 	 ;=W
;  Exit:   None 							      : 	 ;=W
;									      : 	 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
GET_MONO_DOS   PROC NEAR								 ;=W
;
	       PUSH SI			     ;save registers				 ;=W
	       PUSH ES									 ;=W
	       PUSH DI									 ;=W
;
	       MOV  AH,65H		     ;extended country info			 ;=W
	       MOV  AL,02H		     ;get uppercase table ptrs			 ;=W
	       MOV  BX,-1		     ;default code page 			 ;=W
	       MOV  DX,-1		     ;default country id			 ;=W
	       MOV  CX,05H		     ;# bytes returned				 ;=W
	       PUSH DS									 ;=W
	       POP  ES			     ;ES:DI ptrs to return buffer		 ;=W
	       MOV  DI,OFFSET WR_CUCHAR      ;use as temp buffer			 ;=W
;
	       INT  21H 								 ;=W
;
	       INC  DI			     ;skip info id				 ;=W
	       MOV  SI,DI		     ;we need DI so use SI			 ;=W
	       POP  DI									 ;=W
;
	       MOV  AX,WORD PTR [SI]	     ;get DOS monocasing table offset		 ;=W
	       MOV  [DI]+IN_MONOOFF,AX	     ;save it					 ;=W
	       ADD  SI,2								 ;=W
	       MOV  AX,WORD PTR [SI]	     ;get DOS monocasing table segment		 ;=W
	       MOV  [DI]+IN_MONOSEG,AX	     ;save it					 ;=W
;
	       POP  ES			     ;restore registers 			 ;=W
	       POP  SI									 ;=W
;
	       RET									 ;=W
GET_MONO_DOS   ENDP
;
PAGE
;-----------------------------------------------------------------------------+ 	 ;=W
;									      : 	 ;=W
;  GET_DBCS								      : 	 ;=W
;	    Get segment and offset of the DOS double byte support table.      : 	 ;=W
;									      : 	 ;=W
;  Entry:  DS:DI							      : 	 ;=W
;									      : 	 ;=W
;  Exit:   None 							      : 	 ;=W
;									      : 	 ;=W
;-----------------------------------------------------------------------------+ 	 ;=W
GET_DBCS       PROC NEAR								 ;=W
;
	       PUSH SI
	       PUSH ES									 ;=W
	       PUSH DI									 ;=W
	       PUSH DI									 ;=W
;
	       MOV  AH,65H		     ;get extended country info
	       MOV  AL,07H		     ;get DBCS environment table
	       INT  21H 		     ;DOS function call,vector returned
					     ; in ES:DI
	       POP  SI			     ;ptr, SI -> IN_PB
	       INC  DI			     ;skip over id byte returned
	       MOV  AX,WORD PTR ES:[DI]      ;get offset of DBCS table
	       MOV  [DI]+IN_DBCSOFF,AX	     ;save it
;
	       ADD  DI,2		     ;skip over offset to get segment
	       MOV  BX,WORD PTR ES:[DI]      ;get segment of DBCS table
	       MOV  [DI]+IN_DBCSSEG,BX	     ;save it
;
	       POP  DI
;
	       MOV  SI,AX		     ;Point to DBCS table to get length
	       MOV  ES,BX
	       MOV  AX,WORD PTR ES:[SI]
	       MOV  [DI]+IN_DBCSLEN,AX
	       ADD  [DI]+IN_DBCSOFF,2	     ;change offset to point to table
;
	       POP  ES
	       POP  SI
;
	       RET
GET_DBCS       ENDP
