;;****************************************************************************
;;     Assembler MACROS for use with SELECT.
;;     File: MACROS.INC
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
;;****************************************************************************
;;  Macro Change History.
;;
;;  June 18, 1987 - Split MACROS.INC into 5 smaller files.  They are:
;;			     MACROS.INC
;;			     MACROS2.INC
;;			     MACROS3.INC
;;			     MACROS4.INC
;;			     MACROS5.INC
;;		   At the end of the files, there is an INCLUDE statement
;;		   to include the next file.  Therefore, the modules which
;;		   use these macros do not have to add more include statements.
;;		   The only one that must have an INCLUDE statement is
;;		   MACROS.INC.
;;
;;		  - Removed the PUSHH and POPP macros from the other macro
;;		   definitions.
;;
;;  June 22, 1987 - Added the SCAN_PARAMETERS macro.
;;
;;  June 24, 1987 - Added the PREPARE_FILE, WRITE_LINE and SAVE_FILE macros.
;;		  - Revised the SCAN_PARAMETERS macro to read two of the
;;		    parameters from a file instead of the command line.
;;
;;  June 26, 1987 - Changed the EXEC_PROGRAM macros to perform a call to
;;		    EXEC_PROGRAM_ROUTINE which performs the same tasks are the
;;		    previously defined macro.  EXEC_PROGRAM_ROUTINE was added
;;		    to ROUTINES.INC.
;;
;;  June 29, 1987 - Changed the GET_COUNTRY_INDEX to a subroutine call to
;;		    GET_CNTY_INDEX_ROUTINE.  The routine has been changed
;;		    to get the new information from the structure, NUM_DESIGNATES,
;;		    CPSW_STAT, and RESERVED_1.
;;		   - Changed GET_COUNTRY_DEFAULTS, GET_KEYBOARD_INDEX and
;;		     GET_KEYBOARD macros to perform subroutines calls.
;;
;;****************************************************************************
PAGE					;AN000;
INCLUDE  MAC_EQU.INC			;AN000;
;;****************************************************************************
;;
;;   PUSHH:	pushes the listed registers on the stack
;;
;;   SYNTAX:   PUSHH <register list>
;;
;;   INPUT:    register list = AX, BX, CX, DX, SI, DI, BP, SS, SP, CS, DS, ES
;;
;;   OUTPUT:   none
;;
;;   OPERATION:
;;
;;   PUSHH  ALLOWS THE PROGRAMER TO SPECIFY A LIST OF REGISTER TO
;;   BE PUSHED ON A SINGLE LINE.
;;
;;****************************************************************************
PUSHH	MACRO	REG_LIST		;;AN000;
	IRP	REG,<REG_LIST>		;;AN000;
	PUSH	REG			;;AN000; save registers
	ENDM				;;AN000;
		ENDM			;;AN000;
;;****************************************************************************
;;
;;   POPP:     pops the listed registers on the stack
;;
;;   SYNTAX:   POPP <register list>
;;
;;   INPUT:    register list = AX, BX, CX, DX, SI, DI, BP, SS, SP, CS, DS, ES
;;
;;   OUTPUT:   none
;;
;;   OPERATION:
;;
;;   POPP ALLOWS THE PROGRAMER TO SPECIFY A LIST OF REGISTER TO
;;   BE POPPED ON A SINGLE LINE.
;;
;;****************************************************************************
POPP	MACRO	REG_LIST		;;AN000;
	IRP	REG,<REG_LIST>		;;AN000;
	POP	REG			;;AN000; return registers to initial state
	ENDM				;;AN000;
		ENDM			;;AN000;
;;****************************************************************************
;;
;;   DOSCALL:  DOS interrupt 21 function call
;;
;;   SYNTAX:   DOSCALL
;;
;;   INPUT:    none
;;
;;   OUTPUT:   none
;;
;;   OPERATION:
;;
;;   DOSCALL INVOKES THE DOS INTERRUPT 21 FUNCTION CALL.
;;   THE AH REGISTER MUST ALREADY BE LOADED WITH THE
;;   REQUIRED VALUE.
;;
;;****************************************************************************
DOSCALL MACRO				;;AN000;
	INT	21H			;;AN000; call to DOS
	ENDM				;;AN000;
;;****************************************************************************
;;
;;   INIT_VAR: Load a variable with an immediate value.
;;
;;   SYNTAX:  INIT_VAR	variable, expression
;;
;;   INPUT:   variable = Address of a variable.
;;	      expression = The immediate value to load into the variable.
;;
;;   OUTPUT:
;;	 None.
;;
;;   OPERATION:    The memory variable identified by var is assigned the
;;	 immediate value specified in immed.
;;
;;****************************************************************************
INIT_VAR   MACRO  VARIABLE,EXPRESSION		;;AN000;
	MOV	VARIABLE,EXPRESSION		;;AN000; move expression into variable
	ENDM					;;AN000;
;;****************************************************************************
;;
;;   COPY_WORD: Copy a word variable to another word variable.
;;
;;   SYNTAX:  COPY_WORD  var_dest, var_src
;;
;;   INPUT:   var_dest - The destination word variable.
;;	      var_src - The source word variable.
;;
;;   OUTPUT:  none
;;
;;   OPERATION:  The contents of var_src remain intact.
;;		 The contents of AX is destroyed.
;;
;;************************************************************************
COPY_WORD  MACRO  VAR_DEST, VAR_SRC		;;AN000;
	MOV	AX, VAR_SRC			;;AN000;
	MOV	VAR_DEST,AX			;;AN000;
	ENDM					;;AN000;
;;****************************************************************************
;;
;;   COPY_BYTE: Copy a byte variable to another byte variable.
;;
;;   SYNTAX:  COPY_WORD  var_dest, var_src
;;
;;   INPUT:   var_dest - The destination byte variable.
;;	      var_src - The source byte variable.
;;
;;   OUTPUT:  none
;;
;;   OPERATION:  The contents of var_src remain intact.
;;		 The contents of AL is destroyed.
;;
;;************************************************************************
COPY_BYTE  MACRO  VAR_DEST, VAR_SRC		;;AN000;
	MOV	AL, VAR_SRC			;;AN000;
	MOV	VAR_DEST,AL			;;AN000;
	ENDM					;;AN000;
;;****************************************************************************
;;
;;   COMP_WORDS:  Compare two 16 bit memory variable.
;;
;;   SYNTAX:  COMP_WORDS  var_dest, var_src
;;
;;   INPUT:   var_dest - The destination memory variable (16 bits)
;;	      var_src - The source memory variable	 (16 bits)
;;
;;   OUTPUT:  none
;;
;;   OPERATION:  The two 16 bit memory variables are compared and the status
;;	 flags are updated.  Refer to the ASSEMBLER reference for more details.
;;
;;************************************************************************
COMP_WORDS	MACRO	VAR_DEST, VAR_SRC	;;AN000;
						;
	MOV	AX, VAR_DEST			;;AN000;
	CMP	AX, VAR_SRC			;;AN000;
	ENDM					;;AN000;
;;****************************************************************************
;;
;;   COMP_BYTES:  Compare two 8 bit memory variables.
;;
;;   SYNTAX:  COMP_BYTES  var_dest, var_src
;;
;;   INPUT:   var_dest - The destination memory variable ( 8 bits)
;;	      var_src - The source memory variable	 ( 8 bits)
;;
;;   OUTPUT:  none
;;
;;   OPERATION:  The two 8 bit memory variables are compared and the status
;;	 flags are updated.  Refer to the ASSEMBLER reference for more details.
;;
;;************************************************************************
COMP_BYTES	MACRO	VAR_DEST, VAR_SRC	;;AN000;
						;
	MOV	AL, VAR_DEST			;;AN000;
	CMP	AL, VAR_SRC			;;AN000;
	ENDM					;;AN000;
;;****************************************************************************
;;
;;   INC_VAR:  Increment the specified memory variable by 1.
;;
;;   SYNTAX:  INC_VAR  var_dest
;;
;;   INPUT:   var_dest - The destination memory variable.
;;
;;   OUTPUT:  none
;;
;;   OPERATION:  The memory variable is incremented by one.
;;
;;************************************************************************
INC_VAR 	MACRO	VAR_DEST		;;AN000;
	INC	VAR_DEST			;;AN000;
	ENDM					;;AN000;
;;****************************************************************************
;;
;;   DEC_VAR:  Decrement the specified memory variable by 1.
;;
;;   SYNTAX:  DEC_VAR  var_dest
;;
;;   INPUT:   var_dest - The destination memory variable.
;;
;;   OUTPUT:  none
;;
;;   OPERATION:  The memory variable is decremented by one.
;;
;;************************************************************************
DEC_VAR 	MACRO	VAR_DEST		;;AN000;
	DEC	VAR_DEST			;;AN000;
	ENDM					;;AN000;
;;****************************************************************************
;;
;;   INIT:    initializes the DS to the beginning of the data
;;
;;   SYNTAX:  INIT
;;
;;   INPUT:   none
;;
;;   OUTPUT:  none
;;
;;   OPERATION:
;;
;;   THE MACRO SIMPLY SETS UP THE DATA SEGMENT.
;;
;;****************************************************************************
INIT	MACRO				;;AN000;
	PUSH	DS			;;AN000;
	XOR	AX,AX			;;AN000; make AX = 0
	PUSH	AX			;;AN000;
	MOV	AX,DATA 		;;AN000;
	MOV	DS,AX			;;AN000; initialize DS reg to beginning of data
	ENDM				;;AN000;
;;**************************************************************************
;;
;;   MERGE_STRING: merges 2 string blocks together to form a third one
;;
;;   SYNTAX:  MERGE_STRING  name_dest, immed_max, name_src1, name_src2
;;
;;   INPUT:   name_dest - Destination string variable (ASCII-N format)
;;	      immed_max - Maximum length of destination string
;;	      name_src1 - Source string variable 1 (ASCII-N format)
;;	      name_src2 - Source string variable 2 (ASCII-N format)
;;
;;   OUTPUT:
;;	 None.
;;
;;   OPERATION:
;;	 The string pointed to by name_scr1 is copied to the destination string
;;	 first followed by the string pointed to by name_scr2.	If the
;;	 destination string is not long enough to hold the new string, then
;;	 the strings are copied until all the space is used up.
;;	 It is assumed that the input strings and the output string
;;	 are in the current data segment.
;;
;;
;;**************************************************************************************
MERGE_STRING   MACRO   NAME_DEST, IMMED_MAX, NAME_SRC1, NAME_SRC2 ;;AN000;

	LEA	DI, NAME_DEST				;;AN000;
	LEA	SI, NAME_SRC1				;;AN000;
	MOV	AX, IMMED_MAX				;;AN000;
	CALL	COPY_ROUTINE				;;AN000;
	MOV	CX, IMMED_MAX				;;AN000;
	LEA	DI, NAME_DEST				;;AN000;
	LEA	SI, NAME_SRC2				;;AN000;
	CALL	APPEND_STRING_ROUTINE			;;AN000;
	ENDM						;;AN000;
;;**************************************************************************
;;
;;   APPEND_STRING:  Appends an ASCII-N string to the specified string.
;;
;;   SYNTAX:  APPEND_STRING  name_dest, immed_max, name_src
;;
;;   INPUT:   name_dest - Destination string variable (ASCII-N format)
;;	      immed_max - Maximum length of destination string
;;	      name_src	- Source string variable   (ASCII-N format)
;;
;;   OUTPUT:
;;	 None.
;;
;;   OPERATION:
;;	 The ASCII-N string text defined in name_scr is appended to the
;;	 end of name_dest.
;;
;;**************************************************************************************
APPEND_STRING	MACRO	NAME_DEST, IMMED_MAX, NAME_SRC	;;AN000;
	MOV	CX, IMMED_MAX				;;AN000;
	LEA	DI, NAME_DEST				;;AN000;
	LEA	SI, NAME_SRC				;;AN000;
	CALL	APPEND_STRING_ROUTINE			;;AN000;
	ENDM						;;AN000;
;;**************************************************************************
;;
;;   COPY_STRING: Copy ASCII-N string text.
;;
;;   SYNTAX:  MOVE_STRING  name_dest, immed_max, name_src
;;
;;   INPUT:
;;	 name_dest - The destination string variable.
;;	 immed_max - The maximum length of destination string.
;;	 name_src - source string veriable (ASCII-N format)
;;
;;   OUTPUT:
;;	 None.
;;
;;   OPERATION: ASCII-N string text defined in name_src is copied to name_dest.
;;	 The number of characters copied to name_dest will not exceed immed_max.
;;
;;**************************************************************************
COPY_STRING MACRO  NAME_DEST, IMMED_MAX, NAME_SRC	;;AN000;
							;
	LEA	DI, NAME_DEST				;;AN000;
	LEA	SI, NAME_SRC				;;AN000;
	MOV	AX, IMMED_MAX				;;AN000;
	CALL	COPY_ROUTINE				;;AN000;
	ENDM						;;AN000;
;;**************************************************************************
;;
;;   PUSH_HEADING: Push screen label address to the SELECT stack
;;
;;   SYNTAX:  PUSH_HEADING  immed_lab
;;
;;   INPUT:
;;	 immed_lab - screen label
;;
;;   OUTPUT:
;;	 None.
;;
;;   OPERATION: The screen label address is pushed onto the SELECT stack
;;	 provided the numher of entries on the stack will not exceed the
;;	 maximum.  Error will NOT be generated if the function was not
;;	 successful.
;;
;;****************************************************************************
PUSH_HEADING	MACRO	IMMED_LAB			;;AN000;
	MOV	AX, OFFSET IMMED_LAB			;;AN000;
	CALL	PUSH_ROUTINE				;;AN000;
	ENDM						;;AN000;
;;**************************************************************************
;;
;;   POP_HEADING: Pop screen label address from the SELECT stack and jump
;;		  to the label address.
;;
;;   SYNTAX:  POP_HEADING
;;
;;   INPUT:
;;	 None.
;;
;;   OUTPUT:
;;	 None.
;;
;;   OPERATION: The screen label address from the SELECT stack is poped
;;	 if the number of entries on the stack is not zero.  If the number
;;	 of entries is zero, the EXIT_DOS screen label address will be used.
;;	 A jump to the screen label address is also performed.
;;
;;****************************************************************************
POP_HEADING	MACRO					;;AN000;
	CALL	POP_ROUTINE				;;AN000;
	JMP	SI					;;AN000;
	ENDM						;;AN000;
;;****************************************************************************
;;
;;   DIR: get current directory
;;
;;   SYNTAX:  DIR  dir_buffer
;;
;;   INPUT:   dir_buffer = POINTER TO A  64-BYTE USER MEMORY AREA
;;
;;   OUTPUT:  CY = 0, AX = N/A, successful
;;	      CY = 1, AX = error code
;;
;;   OPERATION:
;;
;;   DIR PLACES THE FULL PATH NAME OF THE CURRENT DIRECTORY FOR THE
;;   SPECIFIED DRIVE IN THE BUFFER.
;;   THE RETURNING STRING IS AN ASCIIZ STRING AND IT DOES NOT
;;   HAVE THE DRIVE LETTER OR A BACKSLASH.
;;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;;   IS RETURNED IN AX.
;;
;;****************************************************************************
DIR   MACRO   DIR_BUFFER			;;AN000;
    CALL HOOK_INT_24				;;AN000;
	MOV	SI,OFFSET DIR_BUFFER		;;AN000; pointer to 64 byte user area
	MOV	DL,0				;;AN000; give directory of the default drive
	MOV	AH,47H				;;AN000; get current directory
	DOSCALL 				;;AN000;
    CALL RESTORE_INT_24 			;;AN000;
      ENDM					;;AN000;
;;****************************************************************************
;;
;;   MAKE_DIR: Make a Directory
;;
;;   SYNTAX:   MAKE_DIR directory
;;
;;   INPUT:    directory = An ASCII-N STRING GIVING THE REQUIRED
;;			   PATH
;;   OUTPUT:	CY = 0, AX = undefined,  call was successful
;;		CY = 1, AX = error code
;;
;;   OPERATION:
;;
;;   THE DIRECTORY IS MADE USING THE DOS INT 21H (AH=39H) CALL.
;;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;;   IS RETURNED IN AX.
;;
;;
;;****************************************************************************
MAKE_DIR MACRO	dir_len 		;;AN000;
    CALL HOOK_INT_24			;;AN000;

	MOV	DI,OFFSET dir_len	;;AN000;
	CALL	POS_ZERO		;;AN000; position the '0' at the end of the path
	MOV	DX,OFFSET dir_len[2]	;;AN000; advance pointer to beginning of path
	MOV	AH,39H			;;AN000; make directory interrupt
	DOSCALL 			;;AN000; call to DOS interrupt 21
	CALL  RESTORE_INT_24		;;AN000;
	ENDM				;;AN000;
;;**************************************************************************
;;
;;   MAKE_DIR_PATHS: Create the specified directory including all the specified
;;		 sub-directories if they do not exist.
;;
;;   SYNTAX:  MAKE_DIR_PATHS  name_dir
;;
;;   INPUT:
;;	 name_dir - Directory pathname in ASCII-N string format.
;;
;;   OUTPUT:
;;	 CY = 0 Success
;;	 CY = 1 Error - AX will contain an error code.
;;
;;   OPERATION: The directory pathname is created.
;;	 If the drive letter and colon are not followed by a '\', then the
;;	 macro will start creating the directories from the default directory.
;;	 If they are followed by a '\', then the macro will start at the root.
;;
;;
;;****************************************************************************
MAKE_DIR_PATHS	MACRO	NAME_DIR	;;AN000;

	MOV	BX, OFFSET NAME_DIR	;;AN000; Address of the ASCII-N string
	CALL	MAKE_DIR_PATHS_ROUTINE	;;AN000;
	ENDM				;;AN000;
;;****************************************************************************
;;
;;   REMOVE_DIR: Remove Directory
;;
;;   SYNTAX:   REMOVE_DIR directory
;;
;;   INPUT:    directory = An ASCII-N STRING giving the REQUIRED PATH
;;
;;   OUTPUT:   CY = 0, AX = undefined,	successful
;;	       CY = 1, AX = error code
;;
;;   OPERATION:
;;
;;   THE DIRECTORY IS REMOVED USING THE DOS INT 21H (AH=3AH) CALL.
;;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;;   IS RETURNED IN AX.
;;
;;   It is assumed that the string is located in the data segment
;;
;;****************************************************************************
REMOVE_DIR   MACRO   dir_len		;;AN000;

    CALL HOOK_INT_24			;;AN000;
	MOV	DI,OFFSET dir_len	;;AN000;
	CALL	POS_ZERO		;;AN000; position the '0' at the end of the path
	MOV	DX,OFFSET dir_len[2]	;;AN000; advance pointer to beginning of path
	MOV	AH,3AH			;;AN000; remove the specified directory
	DOSCALL 			;;AN000; call to DOS interrupt 21
	CALL  RESTORE_INT_24		;;AN000;
	ENDM				;;AN000;
;;**************************************************************************
;;
;;   CHANGE_DIR: Change the current directory to the specified directory.
;;
;;   SYNTAX:  CHANGE_DIR  name_dir
;;
;;   INPUT:
;;	 name_dir - directory pathname in ASCII-N string format.
;;
;;   OUTPUT:
;;	 CY = 0 Success
;;	 CY = 1 Error  AX will contain an error code
;;
;;   OPERATION: The directory pathname identified by the ASCII-N string
;;	 becomes the default directory.
;;
;;****************************************************************************
CHANGE_DIR	MACRO	NAME_DIR	;;AN000;

    CALL HOOK_INT_24			;;AN000;
	MOV	DI,OFFSET NAME_DIR	;;AN000; Get the offset of the string
	CALL	POS_ZERO		;;AN000; Make into an ASCII-Z string
	MOV	DX,OFFSET NAME_DIR+2	;;AN000; Get the start of the string
	MOV	AH,3BH			;;AN000; DOS function call number
	DOSCALL 			;;AN000;
    CALL RESTORE_INT_24 		;;AN000;
	ENDM				;;AN000;
INCLUDE  MACROS2.INC			;;AN000;
