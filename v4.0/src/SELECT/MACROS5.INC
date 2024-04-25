;;****************************************************************************
;;     Assembler MACROS for use with SELECT.
;;     File: MACROS5.INC
;;     Latest Change Date: July 28, 1987
;;
;; These macros define powerful assembler verbs neccessary for SELECT.
;;
;; Note: Many of the macros make use of an ASCII-N string for passing
;;	 parameters.  The string is defined below.
;;		   DW  count
;;		   DB  "string_variable",?
;;
;;	 COUNT is the length of the string and is a word.
;;	 It is necessary to follow the string with at least one byte for the
;;	 purpose of changing the ASCII-N string to an ASCII-Z string.
;;
;;****************************************************************************
page					;;AN000;
;;************************************************************************;;
;;
;;   GET_COUNTRY_DEFAULTS: Get country, keyboard and codepage for the
;;		 specified entry from the CTY_TABLE.
;;
;;   SYNTAX:  GET_COUNTRY_DEFAULTS  VAR_TABLE, VAR_INDEX
;;
;;   INPUT:
;;	 VAR_TABLE = 1: Use CTY_TAB_A
;;		   = 2: Use CTY_TAB_B
;;	 VAR_INDEX = index into country list table
;;
;;   OUTPUT:
;;	 N_COUNTRY    = Country code
;;	 N_KYBD_VAL   = 0: Keyboard code is not valid
;;		      = 1: Keyboard code is valid
;;	 S_KEYBOARD   = Keyboard code (ASCII-N format)
;;	 N_CP_PRI     = Primary code page
;;	 N_CP_SEC     = Secondary code page
;;	 N_DESIGNATES = Number of disignates
;;	 N_CPSW       = Cpsw status
;;	 N_CTY_RES    = Reserved
;;
;;
;;   OPERATION:  The country code, keyboard, primary codepage and the
;;	 seondary codepage from the CTY_TABLE for the specified index is
;;	 returned as spedified above.
;;
;;   Note:  Index of the first item is the table is 1.
;;
;;****************************************************************************
GET_COUNTRY_DEFAULTS	MACRO	VAR_TABLE, VAR_INDEX ;;AN000;

    MOV  BX, VAR_TABLE				 ;;AN000; Get which table to search
    MOV  AX, VAR_INDEX				 ;;AN000; Get where to start in the table
    CALL GET_CNTY_DEF_ROUTINE			 ;;AN000;
    ENDM					 ;;AN000;

;;************************************************************************;;
;;
;;   GET_DOS_COUNTRY: Get current country information.
;;
;;   SYNTAX:  GET_DOS_COUNTRY  buffer, var_country
;;
;;   INPUT:
;;	 BUFFER = 38 byte data buffer area for country information.
;;
;;   OUTPUT:
;;	 VAR_COUNTRY = Default country code
;;
;;   OPERATION:  DOS function call 65h (id=1) is performed to get the extended
;;	 country information into the specified data buffer for the default
;;	 and the active CON device.  The country code value from the data buffer
;;	 is returned in the memory variable specified.
;;
;;****************************************************************************
GET_DOS_COUNTRY  MACRO	BUFFER, VAR_COUNTRY	 ;;AN000;


	PUSH	ES				 ;;AN000;
	PUSH	DS				 ;;AN000;
	POP	ES				 ;;AN000;

	MOV	DI, OFFSET BUFFER		 ;;AN000; Get the address of the buffer
	MOV	AX, 6501H			 ;;AN000; Fn call 65h with ID value = 1
	MOV	BX, -1				 ;;AN000; Code page of interest (current)
	MOV	DX, -1				 ;;AN000; Get information for default country
	MOV	CX, 38				 ;;AN000; Amount of data to return
	DOSCALL 				 ;;AN000;

	MOV	BX, [DI]+3			 ;;AN000; Get the country ID
	MOV	VAR_COUNTRY, BX 		 ;;AN000;

	POP	ES				 ;;AN000;

	ENDM					 ;;AN000;
;;****************************************************************************
;;
;;   GET_COUNTRY_INDEX: Scan CTY_TABLE for the specified country code and
;;			 return index of country code into the table.
;;
;;   SYNTAX:  GET_COUNTRY_INDEX  var_country, var_tab, var_index
;;
;;   INPUT:
;;	 var_country = The country code
;;
;;   OUTPUT:
;;	 var_tab = 1: Country code is in table CTY_TAB_A
;;		 = 2: Country code is in table CTY_TAB_B
;;	 var_index = The index into the country list.
;;
;;   OPERATION:  The CTY_TABLE is scanned for the specified country code and
;;	 the index into the table is returned.
;;
;;   Note:  The index of the first item in the table is 1.
;;
;;************************************************************************;;
GET_COUNTRY_INDEX	MACRO	VAR_COUNTRY, VAR_TAB, VAR_INDEX  ;;AN000;

    MOV  CX, VAR_COUNTRY			 ;;AN000; Get the country index
    CALL GET_CNTY_INDEX_ROUTINE 		 ;;AN000; Search the table for this value
    MOV  VAR_TAB, DX				 ;;AN000; Which table it was found in
    MOV  VAR_INDEX, BX				 ;;AN000; Which location in that table
    ENDM					 ;;AN000;
;;****************************************************************************
;;
;;   GET_KEYBOARD_INDEX: Scan KYBD_TABLE for the specified keyboard code and
;;			 return index of keyboard code in the table and the
;;			 alternate keyboard indicator.
;;
;;   SYNTAX:  GET_KEYBOARD_INDEX  name_kybd, var_table, var_index, var_alt
;;
;;   INPUT:
;;	 name_kybd = The keyboard code in ASCII-N format.
;;
;;   OUTPUT:
;;	 var_table = 1: Keyboard is IN table KYBD_TAB_A
;;		   = 2: Keyboard is in table KYBD_TAB_B
;;	 var_index = The index into keyboard table.
;;	 var_alt   = 0: No alternate keyboard
;;		   = 1: Alternate keyboard present
;;
;;   OPERATION:  The KYBD_TABLE is scanned for the specifies keyboard code and
;;	 the index into the table is returned.
;;
;;   Note:  The index of the first item in the table is 1.
;;
;;************************************************************************
GET_KEYBOARD_INDEX	MACRO	NAME_KYBD, VAR_TABLE, VAR_INDEX, VAR_ALT ;;AN000;

    MOV  DI, OFFSET NAME_KYBD			 ;;AN000; The name of the keyboard to search for
    CALL GET_KYBD_INDEX_ROUTINE 		 ;;AN000; Search for this keyboard code
    MOV  VAR_TABLE, DX				 ;;AN000; Which table the code was found in
    MOV  VAR_INDEX, BX				 ;;AN000; Which index in the table
    MOV  VAR_ALT, AL				 ;;AN000; Returned alternate keyboard byte
    ENDM					 ;;AN000;
;;************************************************************************;;
;;
;;   GET_KEYBOARD: Get the keyboard code and the alternate keyboard
;;	 indicator from the KYBD_TABLE for the item specified by the index
;;	 into the keyboard table.
;;
;;   SYNTAX:  GET_KEYBOARD  var_table, var_index, name_kybd, var_alt
;;
;;   INPUT:
;;	 var_table = 1: Keyboard code is in table KYBD_TAB_A
;;		   = 2: Keyboard code is is table KYBD_TAB_B
;;	 var_index  = index into the keyboard table.
;;
;;   OUTPUT:
;;	 name_kybd = keyboard code in ASCII-N format.
;;	 var_alt   = 0: No alternate keyboard
;;		   = 1: Alternate keyboard present
;;
;;   OPERATION:  The keyboard code from the KYBD_TABLE for the specified
;;	 index item is returned.  Also, the alternate keyboard present
;;	 variable is updated.
;;
;;   Note: Index of the first item in the table is 1.
;;
;;****************************************************************************
GET_KEYBOARD	MACRO	VAR_TABLE, VAR_INDEX, NAME_KYBD, VAR_ALT  ;;AN000;

    MOV  AX, VAR_INDEX				 ;;AN000; Where to start the search
    MOV  CX, VAR_TABLE				 ;;AN000; Which table to search
    MOV  DI, OFFSET NAME_KYBD			 ;;AN000; The name of the keyboard code returned
    CALL GET_KYBD_ROUTINE			 ;;AN000;
    MOV  VAR_ALT, AL				 ;;AN000; Returned alternate code
    ENDM					 ;;AN000;
;;************************************************************************;;
;;
;;   GET_ALT_KYBD_TABLE: Scan the ALT_KYB_TABLE for the specified keyboard,
;;	 and return the pointer to the specified keyboards alternate keyboard
;;	 code list.
;;
;;   SYNTAX:  GET_ALT_KYBD_TABLE  name_kybd, var_table, var_kyb
;;
;;   INPUT:
;;	 name_kybd  = Keyboard code in ASCII-N format.
;;
;;   OUTPUT:
;;	 var_table = Pointer to alternat keyboards list.
;;	 var_kyb   = 1: French
;;		   = 2: Italian
;;		   = 3: UK English
;;
;;   OPERATION:  The ALT_KYB_TABLE is scanned for the specified keyboard
;;	 code.	Pointer to a table of alternate keyboards available for the
;;	 specified keyboard code is returned as well as the keyboard identifier.
;;
;;****************************************************************************
GET_ALT_KYBD_TABLE	MACRO	NAME_KYBD, VAR_TABLE, VAR_KYB ;;AN000;
						 ;;
    MOV  SI, OFFSET ALT_KYB_TAB_1		 ;;AN000; Offset of the data in the table
    MOV  AL, ALT_KYB_TABLE			 ;;AN000; Number of entries in the table
    MOV  BX, 1					 ;;AN000; Index currently being scaned
						 ;;
    MOV  DX, NAME_KYBD+2			 ;;AN000;
    .WHILE <<WORD PTR [SI]> NE DX > AND 	 ;;AN000;
    .WHILE < BL LE AL > 			 ;;AN000;
	 INC  BL				 ;;AN000;
	 ADD  SI, TYPE ALT_KYB_DEF		 ;;AN000;
    .ENDWHILE					 ;;AN000;
						 ;;
    .IF < BL GT AL >				 ;;AN000; Entry NOT found
	 MOV  VAR_KYB, 0			 ;;AN000;
	 MOV  VAR_TABLE, 0			 ;;AN000; Pointer is 0 since entry not found
    .ELSE					 ;;AN000;
	 COPY_WORD   VAR_TABLE, [SI]+2		 ;;AN000; Copy the table entries
	 COPY_BYTE   VAR_KYB, [SI]+4		 ;;AN000;
    .ENDIF					 ;;AN000;
						 ;;
    ENDM					 ;;AN000;
;;************************************************************************;;
;;
;;   GET_ALT_KEYBOARD: Get the alternate keyboard code from the specified
;;	 alternate keyboard table for the item specified by the index.
;;
;;   SYNTAX:  GET_ALT_KEYBOARD	var_table, var_kyb, var_index, name_kybd
;;
;;   INPUT:
;;	 var_table  = Pointer to alternate keyboard table
;;	 var_kyb    = 1: French
;;		    = 2: Italian
;;		    = 3: UK English
;;	 var_index  = Index into the keyboard table.
;;
;;   OUTPUT:
;;	 name_kybd = The keyboard code in ASCII-N format.
;;
;;   OPERATION:  The keyboard code from the specified table for the
;;	 specified index item is returned.
;;
;;   NOTE:  The index of the first item is the table is 1.
;;
;;****************************************************************************
GET_ALT_KEYBOARD	MACRO	VAR_TABLE, VAR_KYB, VAR_INDEX, NAME_KYBD ;;AN000;

    MOV  AX, VAR_INDEX				 ;;AN000; Get the table index
    DEC  AX					 ;;AN000; Make the index start at 0
    MOV  SI, VAR_TABLE				 ;;AN000; Pointer to the table
    INC  SI					 ;;AN000; Adjust pointer for table length byte
    .IF < VAR_KYB EQ ALT_FRENCH>		 ;;AN000;
	 MOV  CX, TYPE FR_STRUC 		 ;;AN000;
    .ELSEIF < VAR_KYB EQ ALT_ITALIAN >		 ;;AN000;
	 MOV  CX, TYPE IT_STRUC 		 ;;AN000;
    .ELSE					 ;;AN000;
	 MOV  CX, TYPE UK_STRUC 		 ;;AN000;
    .ENDIF					 ;;AN000;
    MUL  CX					 ;;AN000;
    ADD  SI, AX 				 ;;AN000; Get the address of the required entry
						 ;;
    PUSH ES					 ;;AN000;
    PUSH DS					 ;;AN000;
    POP  ES					 ;;AN000;
    MOV  DI, OFFSET NAME_KYBD			 ;;AN000;
    MOV  CX, LEN_ALT_KYBD_ID			 ;;AN000; Number of bytes in the keyboard code
    MOV  [DI], CX				 ;;AN000;
    ADD  DI, 2					 ;;AN000;
    CLD 					 ;;AN000;
    REP  MOVSB					 ;;AN000;
    POP  ES					 ;;AN000;
    ENDM					 ;;AN000;
;;****************************************************************************
;;
;;   EXEC_PROGRAM: Loads another program into memory and begins execution.
;;
;;   SYNTAX:  EXEC_PROGRAM  child, name_com, parm_block, re_dir
;;
;;   INPUT:   child	 = Name of the program to execute (ASCII-N format)
;;	      name_com	 = The command line to be passed to parm_block
;;	      parm_block = Parameter block for child program.
;;	      re_dir = 1: Redirect Stdout and Stderr to null
;;		     = 0: Don't redirect output.
;;
;;   OUTPUT:  CY = 0: Successful
;;	      CY = 1: Error - AX has the error code.
;;
;;   OPERATION:  The command line to be passed to the parameter block is
;;	 copied to the command buffer specified for the parameter block and
;;	 a carrage return is appended to the end of the buffer.  (The
;;	 command line length can be zero.
;;
;;	 The segment offsets in the parameter block are defined and DOS
;;	 function call 29H is performed to set up the default FCB's.
;;
;;	 DOS function call 4Bh is performed to load and execute the
;;	 specified child program.  The contents of SS and SP are destroyed
;;	 during the call, so they must be save and restored later.  When the
;;	 parent program (SELECT) gets control, all available memory is
;;	 allocated to it.  It is assumed that memory has been freed (Function
;;	 call 4Ah - FREE_MEM) before invoking this function.
;;
;;************************************************************************;;
EXEC_PROGRAM	MACRO  CHILD, NAME_COM, PARM_BLOCK, RE_DIR ;;AN000;

    MOV  AX, OFFSET CHILD			 ;;AN000;
    PUSH AX					 ;;AN000;
    MOV  AX, OFFSET NAME_COM			 ;;AN000;
    PUSH AX					 ;;AN000;
    MOV  AX, OFFSET PARM_BLOCK			 ;;AN000;
    PUSH AX					 ;;AN000;
    MOV  AX, RE_DIR				 ;;AN000;
    PUSH AX					 ;;AN000;
    CALL EXEC_PROGRAM_ROUTINE			 ;;AN000;
    ENDM					 ;;AN000;
;;*****************************************************************************
;;
;;   FREE_MEM: Free memory by modifying the memory block
;;
;;   SYNTAX:  FREE_MEM	address
;;
;;   INPUT:
;;	 address - The address of the first free paragraph in memory.
;;
;;   OUTPUT: CY = 0, AX=undefined,  successful
;;	     CY = 1, AX= error code
;;
;;   OPERATION:
;;
;;   FREEMEM MODIFIES ALLOCATED MEMORY BLOCKS TO
;;   CONTAIN THE NEW SPECIFIED BLOCK SIZE.
;;   IT MAKES USE OF DOS INT 21 (AH=4AH).
;;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;;   IS RETURNED IN AX.
;;
;;****************************************************************************
FREE_MEM  MACRO  address			 ;;AN000;
	PUSH	ES				 ;;AN000;
	MOV	AH,62H				 ;;AN000;
	DOSCALL 				;;AN000; Get the current PSP segment
	MOV	ES,BX				;;AN000; Load current PSP segment
	MOV	BX, ADDRESS			;;AN000; size of program in paragraphs in bx  reg

	MOV	AH,4AH				;;AN000; free memory function
	DOSCALL 				;;AN000;
	POP	ES				;;AN000;
	ENDM					;;AN000;
;;****************************************************************************
;;
;;   CLEAR_SCREEN: clear the screen to white on blue
;;
;;   SYNTAX:  CLEAR_SCREEN
;;
;;   INPUT:
;;	None.
;;
;;   OUTPUT:
;;	None.
;;
;;   OPERATION: Clears the screen using the BIOS function to scroll the
;;	screen completely.
;;
;;****************************************************************************
CLEAR_SCREEN	MACRO				;;AN000;
	MOV	CX,0			;;AN000;
	MOV	DX,184Fh		;;AN000;  scroll screen from (0,0) tO (24,79)
	MOV	AX,0600h		;;AN000;  AH = 6, Scroll Function
					;;  AL = 0, Clear scroll area
	MOV	BH,01FH 		;;AN000;  video I/O interrupt
	INT	10H			;;AN000;
	MOV	DX,0			;;AN000; RKJ-set cursor posn to top right hand corner
	MOV	BH,0			;;AN000; RKJ
	MOV	AH,2			;;AN000; RKJ
	INT	10H			;;AN000; RKJ
	ENDM				;;AN000;
;;****************************************************************************
;;
;;   CLEAR_SCREEN2: clear the screen to white on black
;;
;;   SYNTAX:  CLEAR_SCREEN2
;;
;;   INPUT:
;;	None.
;;
;;   OUTPUT:
;;	None.
;;
;;   OPERATION: Clears the screen using the BIOS function to scroll the
;;	screen completely.
;;
;;****************************************************************************
CLEAR_SCREEN2	MACRO			;;AN000;
	MOV	CX,0			;;AN000;
	MOV	DX,184Fh		;;AN000;  scroll screen from (0,0) tO (24,79)
	MOV	AX,0600h		;;AN000;  AH = 6, Scroll Function
					;;  AL = 0, Clear scroll area
	MOV	BH,7			;;AN000;  video I/O interrupt
	INT	10H			;;AN000;
	MOV	DX,0			;;AN000; RKJ-set cursor posn to top right hand corner
	MOV	BH,0			;;AN000; RKJ
	MOV	AH,2			;;AN000; RKJ
	INT	10H			;;AN000; RKJ
	ENDM				;;AN000;
;;****************************************************************************
;;
;;   POS_CURSOR: position the cursor to top left corner of screen
;;
;;   SYNTAX:  POS_CURSOR
;;
;;   INPUT:
;;	None.
;;
;;   OUTPUT:
;;	None.
;;
;;   OPERATION: Homes the cursor using the BIOS function call.
;;
;;****************************************************************************
POS_CURSOR	MACRO			;;AN085; SEH
	PUSH	AX			;;AN085; SEH
	PUSH	BX			;;AN085; SEH
	PUSH	CX			;;AN085; SEH
	PUSH	DX			;;AN085; SEH
	PUSH	SI			;;AN085; SEH
	PUSH	DI			;;AN085; SEH
	PUSH	ES			;;AN085; SEH
	MOV	DX,0			;;AN085; SEH-set cursor posn to top left hand corner
	XOR	BH,BH			;;AN085; SEH
	MOV	AH,2			;;AN085; SEH
	INT	10H			;;AN085; SEH
	POP	ES			;;AN085; SEH
	POP	DI			;;AN085; SEH
	POP	SI			;;AN085; SEH
	POP	DX			;;AN085; SEH
	POP	CX			;;AN085; SEH
	POP	BX			;;AN085; SEH
	POP	AX			;;AN085; SEH
ENDM					;;AN085; SEH
;;****************************************************************************
;;
;;   BEEP:    Produce a tone on the PC speaker
;;
;;   SYNTAX:  BEEP frequency, duration
;;
;;   INPUT:   frequency = 37 to 32767
;;	      duration	= 1 to 65535
;;
;;   OUTPUT:  A SOUND
;;
;;   OPERATION:
;;
;;   BEEP CREATES A TONE USING THE PC SPEAKER
;;
;;****************************************************************************
BEEP	MACRO	FREQ,DUR		;;AN000;


	MOV	DI, FREQ		;;AN000; set the frequency
	MOV	BX, DUR 		;;AN000; set the duration
	CALL	BEEP_ROUTINE		;;AN000;

	ENDM				;;AN000;
;;**************************************************************************
;;
;;   GOTO : used instead of branching assembler intructions
;;
;;   SYNTAX:  GOTO  label
;;
;;   INPUT:   label = an assembler label for a branching instruction
;;
;;   OUTPUT:  none
;;
;;   OPERATION:
;;
;;
;;**************************************************************************
GOTO	MACRO	LABEL				;;AN000;
	JMP	LABEL				;;AN000; jump to label
	ENDM					;;AN000;
;;************************************************************************;;
;;
;;   BYTE_TO_CHAR:  Convert a 8-bit binary number to ASCII format.
;;
;;   SYNTAX:  BYTE_TO_CHAR  var_num, name_str
;;
;;   INPUT:
;;	 var_num  =  binary number to convert.	(8 bits)
;;
;;   OUTPUT:
;;	 name_str =  ASCII-N string for the specifed value.
;;
;;   OPERATION:  The specified 8 bit numeric variable contents are converted
;;	 to ASCII and stored in ASCII-N format.  Leading zeros will not be
;;	 stored.
;;
;;************************************************************************;;
BYTE_TO_CHAR	 MACRO	 VAR_NUM, NAME_STR	;;AN000;


	MOV	AL, VAR_NUM			;;AN000;
	MOV	AH, 0				;;AN000;
	MOV	DI, OFFSET NAME_STR		;;AN000;
	CALL	BIN_TO_CHAR_ROUTINE		;;AN000;
	ENDM					;;AN000;
;;************************************************************************;;
;;
;;   WORD_TO_CHAR:  Convert a binary number to ASCII format.
;;
;;   SYNTAX:  WORD_TO_CHAR  var_num, name_str
;;
;;   INPUT:
;;	 var_num  =  binary number to convert.	(16 bits)
;;
;;   OUTPUT:
;;	 name_str =  ASCII-N string for the specifed value.
;;
;;   OPERATION:  The specified 16 bit numeric variable contents are converted
;;	 to ASCII and stored in ASCII-N format.  Leading zeros will not be
;;	 stored.
;;
;;************************************************************************;;
WORD_TO_CHAR	 MACRO	 VAR_NUM, NAME_STR	;;AN000;

	MOV	AX, VAR_NUM			;;AN000;
	MOV	DI, OFFSET NAME_STR		;;AN000;
	CALL	BIN_TO_CHAR_ROUTINE		;;AN000;
	ENDM					;;AN000;

INCLUDE  MACROS6.INC				;;AN000;
