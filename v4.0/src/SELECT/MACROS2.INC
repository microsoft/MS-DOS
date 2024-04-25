;;****************************************************************************
;;     Assembler MACROS for use with SELECT.
;;     File: MACROS2.INC
;;     Latest Change Date: August 04, 1987
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
page					;AN000;
;;************************************************************************
;;
;;   CLOSE_FILE: Close File
;;
;;   SYNTAX:  CLOSE_FILE  handle
;;
;;   INPUT:   handle = The handle of the file to close.
;;
;;   OUTPUT:  CY = 0, AX = undefined,  successful
;;	      CY = 1, AX = error code
;;
;;   OPERATION:
;;
;;   THIS MACROS CLOSES THE FILE WITH THE GIVEN FILE HANDLE.
;;   IT MAKES USE OF INT 21 (AH=3EH).
;;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;;   IS RETURNED IN AX.
;;
;;**************************************************************************
CLOSE_FILE   MACRO   HANDLE			 ;;AN000;
						 ;;
    MOV  BX, HANDLE				 ;;AN000;
    CALL FAR PTR CLOSE_FILE_ROUTINE		 ;;AN000;
    ENDM					 ;;AN000;
;;**************************************************************
;;
;;   CREATE_FILE: Create new File
;;
;;   SYNTAX:  CREATE_FILE  name_file, immed_attr, var_handle
;;
;;   INPUT:   name_file - filename in ASCII-N string format.
;;	      immed_attr - file attribute
;;
;;   OUTPUT:  CY = 0 Success: var_handle contain the file handle
;;	      CY = 1 Error: AX contains as error code
;;
;;
;;   OPERATION:
;;
;;   CREATE_FILE CREATES A FILE WITH THE GIVEN NAME USING INT 21H (AH=5BH)
;;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;;   IS RETURNED IN AX.
;;
;;**************************************************************************
CREATE_FILE  MACRO   NAME_FILE, IMMED_ATTR, VAR_HANDLE ;;AN000;
    LEA  DI, NAME_FILE				;;AN000;
    MOV  CX, IMMED_ATTR 			;;AN000;
    CALL CREATE_FILE_ROUTINE			;;AN000;
    MOV  VAR_HANDLE, AX 			;;AN000;
    ENDM					;;AN000;
;;****************************************************************************
;;
;;   ERASE_FILE: Erase File
;;
;;   SYNTAX:  ERASE_FILE  filename
;;
;;   INPUT:   filename = POINTER TO ASCII-N STRING - FILE NAME
;;
;;   OUTPUT:  CY = 0, AX = undefined,  successful
;;	      CY = 1, AX = error code
;;
;;   OPERATION:
;;
;;   ERASE_FILE ERASES THE FILE USING INT 21H (AH=41H).
;;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;;   IS RETURNED IN AX.
;;
;;****************************************************************************
ERASE_FILE   MACRO   FILE_NAME			;;AN000;

    LEA  DI, FILE_NAME				;;AN000;
    CALL ERASE_FILE_ROUTINE			;;AN000;
    ENDM					;;AN000;
;;****************************************************************************
;;
;;   CHMOD_FILE: Change file attributes to read/write
;;
;;   SYNTAX:  CHMOD_FILE  filename
;;
;;   INPUT:   filename = POINTER TO ASCII-N STRING - FILE NAME
;;
;;   OUTPUT:  None.
;;
;;   OPERATION:
;;	The CHMOD dos call is executed (43H) to change the file's attributes
;;	to read/write.
;;
;;****************************************************************************
CHMOD_FILE   MACRO   FILE_NAME			;;AN000;

    LEA  DI, FILE_NAME				;;AN000;
    CALL CHMOD_FILE_ROUTINE			;;AN000;
    ENDM					;;AN000;
;;************************************************************************
;;   FIND_FILE: Find File
;;
;;   SYNTAX:  FIND_FILE   name, attribute
;;
;;   INPUT:   name = POINTER TO ASCII-N STRING - FILE NAME
;;	      attribute - the file attribute used in the search
;;
;;   OUTPUT:  CY = 0, AX = undefined,  successful
;;	      CY = 1, AX = error code
;;
;;   OPERATION:
;;
;;   FINDFILE FINDS THE FIRST FILENAME SPECIFIED USING INT 21 (AH=4EH).
;;   AND LOADS INFORMATION INTO THE CURRENT DTA.
;;   NOTE : THE DEFAULT DTA IS AT 80H IN THE PSP.
;;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;;   IS RETURNED IN AX.
;;
;;************************************************************************
FIND_FILE  MACRO   LOC_FILE,ATTRIBUTE		 ;;AN000;
						 ;;
    LEA  DI, LOC_FILE				 ;;AN000;
    MOV  CX, ATTRIBUTE				 ;;AN000;
    CALL FIND_FILE_ROUTINE			 ;;AN000;
    ENDM					 ;;AN000;
;;************************************************************************
;;   FIND_NEXT: Find the next match in the directory.
;;
;;   SYNTAX:  FIND_NEXT
;;
;;   INPUT:
;;	 None.
;;
;;   OUTPUT:  CY = 0, AX = undefined,  successful
;;	      CY = 1, AX = error code
;;
;;   OPERATION: This macro must be called after FIND_FIRST.  It searched
;;	 the same directory as the FIND_FIRST command for the next match.
;;	 If none is found then the carry flag is set.
;;	 This macro uses the data in the DTA for the directory seach so
;;	 it is important not to change the address of the current DTA.
;;
;;
;;************************************************************************
FIND_NEXT  MACRO   LOC_FILE,ATTRIBUTE		;;AN000;
	CALL  HOOK_INT_24			;;AN000;
	MOV	INT_24_ERROR, FALSE		;;AN000; Zero the number of critical errors
	MOV	AH,4FH				;;AN000;
	DOSCALL 				;;AN000;
	CALL  RESTORE_INT_24			;;AN000;
	ENDM					;;AN000;
;;**************************************************************************
;;
;;   OPEN_FILE - Open File
;;
;;   SYNTAX:  OPEN_FILE  file_name, mode, handle
;;
;;   INPUT:   file_name = POINTER TO ASCII-N STRING - FILE NAME
;;	      mode =  0,1,2 (read,write,read/write)
;;	      handle = POINTER TO A LOCATION TO STORE FILE HANDLE
;;
;;   OUTPUT:  CY = 0, AX = FILE HANDLE, successful
;;	      CY = 1, AX = error code
;;
;;   OPERATION:
;;
;;   THIS MACRO OPENS A FILE FOR READ/WRITE OPERATIONS.
;;   IT MAKES USE OF INT 21 (AH=3DH).
;;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;;   IS RETURNED IN AX.
;;
;;**************************************************************************
OPEN_FILE   MACRO   FILE_NAME,MODE,HANDLE	;;AN000;

    LEA  DI, FILE_NAME				;;AN000;
    MOV  AL, MODE				;;AN000;
    CALL OPEN_FILE_ROUTINE			;;AN000;
    MOV  HANDLE, AX				;;AN000;
    ENDM					;;AN000;
;;**************************************************************************
;;
;;   RENAME_FILE - Rename File
;;
;;   SYNTAX:  RENAME_FILE  old_name, new_name
;;
;;   INPUT:   old_name = POINTER TO ASCII-N STRING -OLD FILE NAME
;;	      new_name = POINTER TO ASCII-N STRING -NEW FILE NAME
;;
;;   OUTPUT:  CY = 0, AX = undefined,  successful
;;	      CY = 1, AX = error code
;;
;;   OPERATION:
;;
;;   THIS MACRO RENAMES A FILE GIVEN 2 NAMES.
;;   IT MAKES USE OF INT 21 (AH=56H).
;;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;;   IS RETURNED IN AX.
;;
;;**************************************************************************
RENAME_FILE  MACRO   OLD_NAME,NEW_NAME		 ;;AN000;
						 ;;
    LEA  SI, OLD_NAME				 ;;AN000;
    LEA  DI, NEW_NAME				 ;;AN000;
    CALL RENAME_FILE_ROUTINE			 ;;AN000;
    ENDM					 ;;AN000;
;;**************************************************************************
;;
;;   READ_FILE: Transfer the specified number of bytes from a file into a
;;	 buffer location.
;;
;;   SYNTAX:  READ_FILE  var_handle, buffer, immed_char, var_char
;;
;;   INPUT:
;;	 var_handle - The handle of the file to read.
;;	 buffer - The address of where to store the data
;;	 immed_char - The number of characters to read
;;
;;   OUTPUT:
;;	 CY = 0, Read success.	var_char - number of bytes read
;;	 CY = 1, Read error. AX contains the error code.
;;
;;   OPERATION:
;;
;;   THIS MACRO READS TO AN ALREADY OPENED FILE.
;;   IT MAKES USE OF INT 21 (AH=3FH).
;;   AX WILL RETURN THE NUMBER BYTES ACTUALLY WRITTEN.
;;
;;************************************************************************
READ_FILE    MACRO   VAR_HANDLE,BUFFER,IMMED_CHAR, VAR_CHAR ;;AN000;

    MOV  BX,VAR_HANDLE				 ;;AN000;
    MOV  DX,OFFSET BUFFER			 ;;AN000;
    MOV  CX,IMMED_CHAR				 ;;AN000;
    CALL READ_FILE_ROUTINE			 ;;AN000;
    ENDM					 ;;AN000;
;;**************************************************************************
;;
;;   WRITE_FILE: Transfer the specified number of bytes from a buffer into a
;;	 specified file.
;;
;;   SYNTAX:  WRITE_FILE  var_handle, buffer, immed_char, var_char
;;
;;   INPUT:
;;	 var_handle - The handle of the file to write to.
;;	 buffer - The address of where the data is stored.
;;	 immed_char - The number of characters to write.
;;
;;   OUTPUT:
;;	 CY = 0, Write success.  var_char - number of bytes written.
;;	 CY = 1, Write error. AX contains the error code.
;;
;;   OPERATION:
;;
;;   THIS MACRO WRITES TO AN ALREADY OPENED FILE.
;;   IT MAKES USE OF INT 21 (AH=3DH).
;;   AX WILL RETURN THE NUMBER BYTES ACTUALLY WRITTEN.
;;
;;************************************************************************
WRITE_FILE   MACRO   VAR_HANDLE, BUFFER, IMMED_CHAR, VAR_CHAR ;;AN000;
						 ;;
    MOV  BX,VAR_HANDLE				 ;;AN000;
    MOV  DX,OFFSET BUFFER			 ;;AN000;
    MOV  CX,IMMED_CHAR				 ;;AN000;
    CALL WRITE_FILE_ROUTINE			 ;;AN000;
    ENDM					 ;;AN000;
;;**************************************************************************
;;
;;   PREPARE_FILE:  Prepare a file and a buffer for the construction of that
;;	 file line by line.
;;
;;   SYNTAX:  PREPARE_FILE  filename
;;
;;   INPUT:
;;	 filename  =  The name of the file to create. (ASCII-N format)
;;
;;   OUTPUT:  CY = 0: No error was encountered.
;;	      CY = 1: There was an error encountered.
;;
;;   OPERATION:  A attempt is made to create the file.	If it fails because
;;	 the file already exists, then the file is opened for writing.
;;	 The user will then write to the file be calling WRITE_LINE macro.  The
;;	 data will be temperarily stored in a buffer to limit the actual number
;;	 of writes to the file.
;;
;;**************************************************************************
PREPARE_FILE  MACRO	FILENAME		 ;;AN000;

    MOV  BX, OFFSET FILENAME			 ;;AN000; Pass the address of the filename string
    CALL PREPARE_FILE_ROUTINE			 ;;AN000; Call a routine to do that actual work
    ENDM					 ;;AN000;
;;**************************************************************************
;;
;;   WRITE_LINE:  Write a line to the file being constructed.
;;
;;   SYNTAX:  WRITE_LINE  line
;;
;;   INPUT:
;;	 line  =  The line to write to the file. (ASCII-N format)
;;
;;   OUTPUT:  CY = 0: No error was encountered.
;;	      CY = 1: An error was encountered.
;;
;;   OPERATION:  The line that is passed, has a CR and a LF appended to the
;;	 end of the line.  The data is then stored in a buffer.  When the
;;	 buffer is full, the data is written to the disk.
;;
;;**************************************************************************
WRITE_LINE    MACRO	LINE			 ;;AN000;

    MOV  BX, OFFSET LINE			 ;;AN000; Pass the address of the line to write
    CALL WRITE_LINE_ROUTINE			 ;;AN000; Call a routine to do the actual work
    ENDM					 ;;AN000;
;;**************************************************************************
;;
;;   SAVE_FILE:  Empty the data in the buffer being used to create the file
;;	      and then close the file.
;;
;;   SYNTAX:  SAVE_FILE  file_name, error_code
;;
;;   INPUT:
;;	 file_name = The name of the file being built.	If there has been
;;		an error encountered, then the file will be erased.
;;
;;   OUTPUT:  CY = 0: No error was encountered.
;;	      CY = 1: An error was encountered.
;;		      ERROR_CODE will contain the code of the error which
;;				 occured.
;;
;;   OPERATION:  The routine will check to see if there is any data left in
;;	 the buffer.  If there is, the data is written to the file being
;;	 created.  The file is then closed.  If errors were encountered at
;;	 anytime during the create process, then the carry flag will be set
;;	 and the error code will be returned in ERROR_CODE.
;;
;;**************************************************************************
SAVE_FILE     MACRO	FILE_NAME, ERROR_CODE	 ;;AN000;

    MOV  BX, OFFSET FILE_NAME			 ;;AN000; Get the address of the file name string
    CALL SAVE_FILE_ROUTINE			 ;;AN000; Call a subroutine to do the actual work
    MOV  ERROR_CODE, AX 			 ;;AN000; Store the returned error code
    ENDM					 ;;AN000;
;;**************************************************************************
;;
;;   CHECK_DOS_VERSION: Check DOS Version level is 4.00
;;
;;   SYNTAX:  CHECK_DOS_VERSION
;;
;;   INPUT:
;;	 None.
;;
;;   OUTPUT:  CY = 0: Current DOS Version is 4.00
;;	      CY = 1: Current DOS Version is other than level 4.00
;;
;;   OPERATION:  DOS function call 30h is performed to get the current DOS
;;	 version number.  If the DOS version is not 4.00, the carry flag is set.
;;
;;**************************************************************************
CHECK_DOS_VERSION   MACRO		;;AN000;
	MOV	AH, 30H 		;;AN000; DOS function number to perform
	DOSCALL 			;;AN000;
	.IF < AL EQ MAJOR_VERSION > AND ;;AC047;SEH check is now made in VERSIONA.INC
	.IF < AH EQ MINOR_VERSION >	;;AC047;SEH Check the DOS minor version
	CLC				;;AN000; This is the correct version
	.ELSE				;;AN000;
	STC				;;AN000; This is the incorrect version
	.ENDIF				;;AN000;
	ENDM				;;AN000;
;;**************************************************************************
;;
;;   SET_DISPLAY_MODE:	Set the display mode to 80 column.
;;
;;   SYNTAX:  SET_DISPLAY_MODE
;;
;;   INPUT:
;;	 None.
;;
;;   OUTPUT:
;;	 None.
;;
;;   OPERATION:  The Video Interrupt (INT 10H, AH = 0) is performed to set
;;	 the display to 80 column mode.
;;
;;************************************************************************
SET_DISPLAY_MODE	MACRO		;;AN000;

    CALL SET_DISPLAY_MODE_ROUTINE	;;AN000;
    ENDM				;;AN000;

;;************************************************************************
;;
;;   CHECK_EXPANDED_MEMORY:  Check if the system supports expanded memory.
;;
;;   SYNTAX:  CHECK_EXPANDED_MEMORY   var_xma
;;
;;   INPUT:
;;	 None.
;;
;;   OUTPUT:
;;	 var_xma   = 0: Expanded memory is NOT supported.
;;		   = 1: Expanded memory is supported.
;;	 var_mod80 = 0: Not model 80
;;		   = 1: Model 80
;;
;;   OPERATION:  A call to the system services (INT 15H, AH = C0H) is performed
;;	 to get the system configuration parameters. (model byte).
;;
;;	 The Personal System/2 Model 80 (model byte = 0F8h) always support
;;	 expanded memory.
;;
;;	 The Personal System/2 Models 50 and 60 (model byte = 0FCh) support
;;	 expanded memory if the ??? 2 is present.  The ??? 2 card has
;;	 the identity number of F7FEh.	F7H is read through the port address
;;	 101h and FEH is read through port 100H
;;
;;	 All other models do not support expanded memory.
;;
;;************************************************************************
CHECK_EXPANDED_MEMORY	MACRO	VAR_XMA, VAR_MOD80	;;AC000;JW

    CALL CHK_EX_MEM_ROUTINE				;;AN000;
    MOV  VAR_XMA, SI					;;AN000;
    MOV  VAR_MOD80,BX					;;AN000;JW
    ENDM						;;AN000;

INCLUDE  MACROS3.INC					;;AN000;
