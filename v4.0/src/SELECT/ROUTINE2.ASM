;***************************************************************************
; Subroutines which are called by the macros in MACROS.INC.
; File: ROUTINE2.ASM
; Latest Change Date: August 04, 1987
;
; This is a stand alone module and is meant to be linked with the calling
; program.
;
;***************************************************************************
.ALPHA						 ;AN000;
;**********************************************************************
DATA	SEGMENT BYTE PUBLIC 'DATA'               ;AN000;

PATH_STRING		DW	  0		 ;AN000;
STRING_SIZE		DW	  0		 ;AN000;
PATH_PTR		DW	  0		 ;AN000;
PATH_SIZE		DW	  0		 ;AN000;
MAX_CHAR		DW	  0		 ;AN000;
CHAR_COUNT		DW	  0		 ;AN000;


SEARCH_FLAG		DB	  0		 ;AN000;

    PERIOD		EQU	  00000001B	 ;AN000;
    SLASH_FOUND 	EQU	  00000010B	 ;AN000;


    RESET_PERIOD	EQU	  11111110B	 ;AN000;
    RESET_SLASH_FOUND	EQU	  11111101B	 ;AN000;

INVALID_STRING		DB	  '"/\[]:|<>+=;, ' ;AN000;
			END_INVALID_STRING  EQU  $ ;AN000;
SIZE_INVALID_STR	EQU	  END_INVALID_STRING - INVALID_STRING ;AN000;

ZEROED_CHAR		DB	  0	      ;AN000;
			DB	  0	      ;AN000;

SEP_POSITION		DW	  0	      ;AN000;
NUM_PATHS		DW	  0	      ;AN000;


ERR_INVALID_DRV 	EQU	  1	      ;AN000;
ERR_NO_DRIVE		EQU	  2	      ;AN000;
ERR_DRIVE		EQU	  3	      ;AN000;
ERR_LEADING_SLASH	EQU	  4	      ;AN000;
ERR_NO_SLASH		EQU	  5	      ;AN000;
ERR_LAST_SLASH		EQU	  6	      ;AN000;
ERR_INVALID_CHAR	EQU	  7	      ;AN000;

OLD_ATTRIB		DW	  0	      ;AN000;
NEW_ATTRIB		DW	  0	      ;AN000;
WAY			DW	  0	      ;AN000;



PUBLIC	      CHK_W_PROTECT_FLAG	      ;AN000;
PUBLIC	      W_PROTECT_FLAG		      ;AN000;

W_P_FILENAME_A		DB	  'A:\',12 DUP(0), 0    ;AC000;JW
W_P_FILENAME_B		DB	  'B:\',12 DUP(0), 0    ;AN000;JW
CHK_W_PROTECT_FLAG	DB	  0			;AN000;
W_PROTECT_FLAG		DB	  0			;AN000;
DRIVE_FLAG		DB	  ?			;AN000;JW


NUM_FILES		DW	  0			;AN000;
LIST_TYPE		DW	  0			;AN000;
STR_PTR 		DW	  0			;AN000;
FILE_PTR		DW	  0			;AN000;



DATA	       ENDS				 ;AN000; DATA
;**********************************************************************
						 ;
	.XLIST					 ;AN000;
	INCLUDE STRUC.INC			 ;AN000;
	INCLUDE MACROS.INC			 ;AN000;
	INCLUDE VARSTRUC.INC			 ;AN000;
	INCLUDE EXT.INC 			 ;AN000;
	INCLUDE MAC_EQU.INC			 ;AN000;
	EXTRN	EXIT_DOS:FAR			 ;AN000;
	EXTRN	POS_ZERO:FAR			 ;AN000;
	EXTRN	HOOK_INT_24:FAR 		 ;AN000;
	EXTRN	RESTORE_INT_24:FAR		 ;AN000;
	EXTRN	GGET_STATUS:FAR 		 ;AN000;
	.LIST					 ;AN000;
						 ;
						 ;
;**********************************************************************
CODE_FAR    SEGMENT PARA PUBLIC 'CODE'           ;AN000; Segment for far routine
	ASSUME	CS:CODE_FAR,DS:DATA		 ;AN000;
						 ;
;********************************************************************************
; CHECK_DOS_PATH_ROUTINE: Check to see if the sepecified path for the DOS
;	      SET PATH command is valid.
;
; INPUT:
;    SI = Points to an ASCII-N string containing the path to check.  There sould
;	  be an extra byte following the string to facilitate changing the string
;	  into an ASCII-Z string.
;
; OUTPUT:
;    If CY = 0, the path is valid.
;    If CY = 1, The path is NOT valid:
;
;********************************************************************************
PUBLIC	 CHECK_DOS_PATH_ROUTINE 		 ;AN000;
CHECK_DOS_PATH_ROUTINE	PROC FAR		 ;AN000;
						 ;
    MOV  PATH_PTR, SI				 ;AN000; Get the pointer from the path
    MOV  AX, [SI]				 ;AN000; Get the lenth of the path string
    .IF < AX EQ 0 >				 ;AN000; If the length is zero then return that
	 JMP  NO_ERROR_DOS_PATH 		 ;AN000;    the path is valid.
    .ENDIF					 ;AN000;
    MOV  PATH_SIZE, AX				 ;AN000; Save the size of the string
    ADD  SI, 2					 ;AN000; Adjust path pointer for length word
						 ;
    .REPEAT					 ;AN000; Check all the path names in the string
	 MOV  AL, ';'                            ;AN000; separator between filenames
	 MOV  CX, PATH_PTR			 ;AN000; Get the pointer to the path
	 ADD  CX, 2				 ;AN000; Point to the start of the string
	 ADD  CX, PATH_SIZE			 ;AN000; Add the size of the path
	 SUB  CX, SI				 ;AN000; Subtract current pointer - Get length of string remaining
	 CALL ISOLATE_NEXT_PATH 		 ;AN000; Make the next path name into an ASCII-Z string
	 PUSH SEP_POSITION			 ;AN000; Save the position of the path seperator
	 PUSH WORD PTR ZEROED_CHAR		 ;AN000; Save the character that was made into a zero
	 MOV  CX, SEP_POSITION			 ;AN000;
	 SUB  CX, SI				 ;AN000; Get the length of the string
	 MOV  AX, 0101H 			 ;AN000;
	 CALL FAR PTR CHECK_VALID_PATH		 ;AN000; Check if it is a valid filename
	 POP  WORD PTR ZEROED_CHAR		 ;AN000;
	 POP  SEP_POSITION			 ;AN000;
	 CALL RESTORE_SEPARATOR 		 ;AN000; Restore the character between the path names
	 .IF < C >				 ;AN000; Was the file name not valid?
	      JMP  ERROR_DOS_PATH		 ;AN000; Exit the subroutine
	 .ENDIF 				 ;AN000;
	 MOV  SI, DI				 ;AN000; Get the pointer to the next path name
    .UNTIL < ZERO SI >				 ;AN000; If zero, all path names have been examined.
NO_ERROR_DOS_PATH:				 ;AN000;
    CLC 					 ;AN000;
    JMP  EXIT_DOS_PATH				 ;AN000;
ERROR_DOS_PATH: 				 ;AN000;
    STC 					 ;AN000;
EXIT_DOS_PATH:					 ;AN000;
    RET 					 ;AN000;
						 ;
CHECK_DOS_PATH_ROUTINE	ENDP			 ;AN000;
						 ;
						 ;
PUBLIC	 CHECK_VALID_PATH			 ;AN000;
;********************************************************************************
; CHECK_VALID_PATH: Check to see if the sepecified path is valid.
;
; INPUT:
;    SI = Points to an ASCII-Z string containing the path to check.  There sould
;	  be an extra byte following the string to facilitate changing the string
;	  into an ASCII-Z string.
;
;   CX = The size of the string containing the path.  The zero byte at the end
;	 of the string is NOT included in the length.
;
;    AL = 0: Drive letter cannot be specified.
;	= 1: Drive letter is optional and can be specified.
;	= 2: Drive letter must be specified.
;
;    AH = 0: First non-drive character cannot be a backslash ('\')
;	= 1: First non-drive character may be a backslash ('\')
;	= 2: First non-drive character must be a backslash ('\')
;
; OUTPUT:
;    If CY = 0, the path is valid.
;    If CY = 1, The path is NOT valid:
;	  AX = 1, The drive specified is invalid.
;	     = 2, There was no drive specified.
;	     = 3, There was a drive specified.
;	     = 4, There was a leading backslash
;	     = 5, The leading backslash was NOT present.
;	     = 6, There was a trailing backslash.
;
;********************************************************************************
CHECK_VALID_PATH   PROC FAR			 ;AN000;
						 ;
    PUSH DI					 ;AN000;
    MOV  STRING_SIZE, CX			 ;AN000; Save the size of the string
    MOV  PATH_STRING, SI			 ;AN000; Save the pointer to the string
    CALL CHECK_VALID_DRIVE			 ;AN000; See if there is a valid drive
    .IF < C >					 ;AN000; Is the drive specified invalid?
	 MOV  AX, ERR_INVALID_DRV		 ;AN000; Return this error code
	 JMP  EXIT_CHK_DRV			 ;AN000; Exit the subroutine
    .ENDIF					 ;AN000;
    .IF < BX EQ 0 >				 ;AN000; No drive sepecified?
	 .IF < AL EQ 2 >			 ;AN000; Must the drive be specified?
	      MOV  AX, ERR_NO_DRIVE		 ;AN000; Return this error code
	      JMP  EXIT_CHK_DRV 		 ;AN000; Exit the subroutine
	 .ENDIF 				 ;AN000;
    .ELSE					 ;AN000; Otherwise, the drive WAS specified.
	 .IF < AL EQ 0 >			 ;AN000; The drive cannot be specified
	      MOV  AX, ERR_DRIVE		 ;AN000; Return this error code
	      JMP  EXIT_CHK_DRV 		 ;AN000; Exit the subroutine
	 .ENDIF 				 ;AN000;
	 ADD  SI, 2				 ;AN000; Push pointer past the drive
    .ENDIF					 ;AN000;
    .IF < <BYTE PTR [SI]> EQ '\' >               ;AN000; Is the next byte a backslash?
	 .IF < AH EQ 0 >			 ;AN000; Is one permitted?
	      MOV  AX, ERR_LEADING_SLASH	 ;AN000; No! Return this error code
	      JMP  EXIT_CHK_DRV 		 ;AN000; Exit the subroutine
	 .ELSE					 ;AN000; Otherwise, one allowed.
	      INC  SI				 ;AN000; Push pointer past \
	 .ENDIF 				 ;AN000;
    .ELSE					 ;AN000; Otherwise, byte not a backslash
	 .IF < AH EQ 2 >			 ;AN000; Was one required?
	      MOV  AX, ERR_NO_SLASH		 ;AN000; If so, return this error code
	      JMP  EXIT_CHK_DRV 		 ;AN000; Exit from this subroutine
	 .ENDIF 				 ;AN000;
    .ENDIF					 ;AN000;
						 ;
    MOV  NUM_PATHS, 0				 ;AN000;
    .REPEAT					 ;AN000; Check all the path names in the string
	 MOV  AL, '\'                            ;AN000; Separator between filenames
	 MOV  CX, PATH_STRING			 ;AN000;
	 ADD  CX, STRING_SIZE			 ;AN000;
	 SUB  CX, SI				 ;AN000;
	 .IF < NUM_PATHS EQ 0 > AND		 ;AN000; If this is the first path checked...and
	 .IF < CX EQ 0 >			 ;AN000; If the length of the path is zero...
	      JMP  EXIT_NO_ERROR		 ;AN000; Exit with no error
	 .ENDIF 				 ;AN000;
	 CALL ISOLATE_NEXT_PATH 		 ;AN000; Make the next path name into an ASCII-Z string
	 CALL CHECK_VALID_FILENAME		 ;AN000; Check if it is a valid filename
	 CALL RESTORE_SEPARATOR 		 ;AN000; Restore the character between the path names
	 .IF < C >				 ;AN000; Was the file name not valid?
	      .IF < NUM_PATHS EQ 0 >		 ;AN000;
		   .LEAVE			 ;AN000;
	      .ELSE				 ;AN000;
		   MOV	AX, ERR_INVALID_CHAR	 ;AN000; If not, return this error code
		   JMP	EXIT_CHK_DRV		 ;AN000; Exit the subroutine
	      .ENDIF				 ;AN000;
	 .ENDIF 				 ;AN000;
	 MOV  SI, DI				 ;AN000; Get the pointer to the next path name
    .UNTIL < ZERO SI >				 ;AN000; If zero, all path names have been examined.
						 ;
    MOV  SI, PATH_STRING			 ;AN000; Get the pointer to the whole string
    ADD  SI, STRING_SIZE			 ;AN000; Add the string length
    DEC  SI					 ;AN000; Point to the last character in the string
    .IF < <BYTE PTR [SI]> EQ '\'>                ;AN000; Is the last character a \ ?
	 MOV  AX, ERR_LAST_SLASH		 ;AN000; If so, return this error code
	 JMP  EXIT_CHK_DRV			 ;AN000; Exit from the subroutine
    .ENDIF					 ;AN000;
EXIT_NO_ERROR:					 ;AN000;
    CLC 					 ;AN000; Indicate there were no errors
    JMP  EXIT_CHECK_PATH			 ;AN000;
						 ;
EXIT_CHK_DRV:					 ;AN000;
    STC 					 ;AN000; Indicate that there were errors
EXIT_CHECK_PATH:				 ;AN000;
    POP  DI					 ;AN000;
    RET 					 ;AN000;
						 ;
						 ;
CHECK_VALID_PATH   ENDP 			 ;AN000;
;********************************************************************************
; CHECK_VALID_DRIVE: Check to see if there is a drive specified on the path and
;	       if there is, is it valid.
;
; INPUT:
;    SI - Points to a string containing the path to search.
;
; OUTPUT:
;    If CY = 1, the drive is specified and is invalid
;    If CY = 0, The drive might be specified and is valid
;	  BX = 0: The drive is NOT specified.
;	     = 1: The drive IS specified.
;
;
;********************************************************************************
CHECK_VALID_DRIVE  PROC NEAR			 ;AN000;
						 ;
    PUSH AX					 ;AN000; Push all registers used
    .IF < <BYTE PTR [SI+1]> EQ ':' >             ;AN000; Is the second character in the string a ':'
	 MOV  AL, [SI]				 ;AN000; If so, get the first character
	 .IF < AL AE 'A' > AND                   ;AN000; Is it a capital letter?
	 .IF < AL BE 'Z' >                       ;AN000;
	      CLC				 ;AN000; If so, drive valid.
	      MOV  BX, 1			 ;AN000; Indicate the drive exists
	 .ELSEIF < AL AE 'a' > AND               ;AN000; Else, is the drive a lowercase letter?
	 .IF < AL BE 'z' >                       ;AN000;
	      CLC				 ;AN000; If so, the drive is valid
	      MOV  BX, 1			 ;AN000; Indicate that the drive exists
	 .ELSE					 ;AN000; Otherwise...
	      STC				 ;AN000; The drive is not valid
	 .ENDIF 				 ;AN000;
    .ELSE					 ;AN000;
	 CLC					 ;AN000; Indicate there were no errors
	 MOV  BX, 0				 ;AN000; The drive does not exist
    .ENDIF					 ;AN000;
    POP  AX					 ;AN000;
						 ;
    RET 					 ;AN000;
						 ;
CHECK_VALID_DRIVE  ENDP 			 ;AN000;
;********************************************************************************
; CHECK_VALID_FILENAME: Check to see if a filename is valid.
;
; INPUT:
;    SI - Points to an ASCII-Z string containing the filename to examine.
;
; OUTPUT:
;    If CY = 1, The filename is NOT valid.
;    If CY = 0, the filename IS valid.
;
;
;********************************************************************************
CHECK_VALID_FILENAME	PROC NEAR		 ;AN000;
						 ;
    INC  NUM_PATHS				 ;AN000;
    AND  SEARCH_FLAG, RESET_PERIOD		 ;AN000; Indicate no periods have been found yet
    MOV  MAX_CHAR, 8				 ;AN000; Up to 8 characters can be specified
    MOV  CHAR_COUNT, 0				 ;AN000; Number of character so far
    MOV  AL, [SI]				 ;AN000; Get the first character in the string
    .WHILE < AL NE 0 >				 ;AN000; Repeat untill we reach the string's end
	 INC  CHAR_COUNT			 ;AN000; Increment number of characters in path
	 MOV  BX, CHAR_COUNT			 ;AN000;
	 .IF < BX A MAX_CHAR > AND		 ;AN000;
	 .IF < AL NE '.' >                       ;AN000;
	      JMP  INVALID_CHAR 		 ;AN000;
	 .ENDIF 				 ;AN000;
	 .IF < AL B 20 >			 ;AN000; Is the character's code less than 20?
	      JMP  INVALID_CHAR 		 ;AN000; If so, it's invalid
	 .ELSE					 ;AN000; Otherwise...
	      CALL VALID_CHAR			 ;AN000; See if it's invalid
	      .IF < C > 			 ;AN000; If so,
		   JMP	INVALID_CHAR		 ;AN000; Exit the subroutine
	      .ENDIF				 ;AN000;
	 .ENDIF 				 ;AN000;
	 .IF < AL EQ '.' >                       ;AN000; Is the character a period?
	      .IF < BIT SEARCH_FLAG AND PERIOD > ;AN000; Is this the first one?
		   JMP	INVALID_CHAR		 ;AN000; If not, filename is invalid.
	      .ELSE				 ;AN000; Otherwise...
		   OR	SEARCH_FLAG, PERIOD	 ;AN000; Indicate that ONE has been found
		   .IF < CHAR_COUNT EQ 1 >	 ;AN000; Were there any characters before the period
			JMP  INVALID_CHAR	 ;AN000; If not, this is an invalid path
		   .ENDIF			 ;AN000;
		   MOV	MAX_CHAR, 3		 ;AN000; Allow three characters after the period
		   MOV	CHAR_COUNT, 0		 ;AN000; No characters yet
	      .ENDIF				 ;AN000;
	 .ENDIF 				 ;AN000;
	 INC  SI				 ;AN000; Point to next character
	 MOV  AL, [SI]				 ;AN000; Get that character
    .ENDWHILE					 ;AN000;
    .IF < CHAR_COUNT EQ 0 > AND 		 ;AN000;
    .IF < MAX_CHAR   EQ 8 >			 ;AN000;
	 DEC  NUM_PATHS 			 ;AN000;
	 JMP  INVALID_CHAR			 ;AN000;
    .ENDIF					 ;AN000;
    CLC 					 ;AN000; Indicate the name is valid
    JMP  CK_V_FILENAME				 ;AN000; Exit.
						 ;
INVALID_CHAR:					 ;AN000; Indicate that the name is not valid
    STC 					 ;AN000;
CK_V_FILENAME:					 ;AN000;
    RET 					 ;AN000;
						 ;
CHECK_VALID_FILENAME	ENDP			 ;AN000;
;********************************************************************************
; VALID_CHAR: Determine if a character is valid for a filename.
;
; INPUT:
;    AL = The character to check.
;
; OUTPUT:
;    If CY = 1, the character is not valid.
;    If CY = 0, the character IS valid.
;
;********************************************************************************
VALID_CHAR    PROC NEAR 			 ;AN000;
						 ;
    PUSH CX					 ;AN000; Save the registers used.
    PUSH DI					 ;AN000;
    PUSH ES					 ;AN000;
						 ;
    MOV  DI, OFFSET INVALID_STRING		 ;AN000; Get the address of string containing invalid characters
    PUSH DS					 ;AN000; Save the data segment
    POP  ES					 ;AN000; Make ES=DS
    MOV  CX, SIZE_INVALID_STR			 ;AN000; Get the size of the string
    CLD 					 ;AN000; Scan forward
    REPNZ     SCASB				 ;AN000; See if this character is in the invalid string
    .IF < Z >					 ;AN000; If so,
	 STC					 ;AN000; Indicate the character is invalid
    .ELSE					 ;AN000; Otherwise...
	 CLC					 ;AN000; Indicate the character is valid
    .ENDIF					 ;AN000;
    POP  CX					 ;AN000; Restore the registers
    POP  DI					 ;AN000;
    POP  ES					 ;AN000;
    RET 					 ;AN000;
						 ;
VALID_CHAR    ENDP				 ;AN000;
;********************************************************************************
; ISOLATE_NEXT_PATH: Search the filename for a '\'.  If found, it is replaced
;	  by a zero making the string into an ASCII-Z string.
;
; INPUT:
;    SI - Points to the first character in the path string
;    AL - Contains the character to search for
;    CX - Contains the length of the string
;
; OUTPUT:
;    DI - Points to the character following the next '\'
;    If this character is the last path element, DI = 0.
;
;    ZEROED_CHAR is loaded with the character which is made into a zero.
;
;********************************************************************************
ISOLATE_NEXT_PATH  PROC NEAR			 ;AN000;
						 ;
    PUSH AX					 ;AN000; Save registers used.
    PUSH BX					 ;AN000;
    PUSH CX					 ;AN000;
    PUSH SI					 ;AN000;
						 ;
    PUSH ES					 ;AN000; Make ES = DS
    PUSH DS					 ;AN000;
    POP  ES					 ;AN000;
    MOV  DI, SI 				 ;AN000; Copy the string pointer
						 ; CX holds the length of string after the pointer DI
						 ; AL holds the character to search for
    CLD 					 ;AN000; Search in the forward direction
    REPNZ     SCASB				 ;AN000; Search...
    JNZ  END_FOUND				 ;AN000; If NZ, we reached the string's end
    MOV  ZEROED_CHAR, AL			 ;AN000; Character overwritten with zero
    MOV  SEP_POSITION, DI			 ;AN000; Save the position of overwritten char
    DEC  SEP_POSITION				 ;AN000;
    MOV  BYTE PTR [DI-1], 0			 ;AN000; Make the character a zero
    CMP  CX,0					 ;AN031; SEH  User may have entered semicolon as last char, so check
    JE	 END_FOUND2				 ;AN031; SEH	   if it is last char instead of just a separator
    JMP  EXIT_ISOLATE				 ;AN000; Exit the subroutine
END_FOUND:					 ;AN000;
    MOV  AL, [DI]				 ;AN000; Get the last character
    MOV  ZEROED_CHAR, AL			 ;AN000; Save it.
    MOV  SEP_POSITION, DI			 ;AN000; Save its position
    MOV  BYTE PTR [DI], 0			 ;AN000; Make into a zero
END_FOUND2:					 ;AN031; SEH  Handle case of semicolon as last character in path
    MOV  DI, 0					 ;AN000; Indicate the string is finished
EXIT_ISOLATE:					 ;AN000;
    POP  ES					 ;AN000; Restore the registers.
    POP  SI					 ;AN000;
    POP  CX					 ;AN000;
    POP  BX					 ;AN000;
    POP  AX					 ;AN000;
						 ;
    RET 					 ;AN000;
						 ;
ISOLATE_NEXT_PATH  ENDP 			 ;AN000;
;********************************************************************************
; RESTORE_SEPARATOR: Restore the character which separates the characters in
;	  a path.
;
; INPUT:
;    SEP_POSITION - Contain the address of the location to restore the separator.
;    ZEROED_CHAR  - Contains the character to be restored.
;
; OUTPUT:
;    None.
;
;********************************************************************************
RESTORE_SEPARATOR  PROC NEAR			 ;AN000;
						 ;
    PUSH AX					 ;AN000; Save registers used
    PUSH SI					 ;AN000;
    MOV  SI, SEP_POSITION			 ;AN000; Get the position of the character
    MOV  AL, ZEROED_CHAR			 ;AN000; Get the character
    MOV  [SI], AL				 ;AN000; Save character in this position
    POP  SI					 ;AN000; Restore the registers
    POP  AX					 ;AN000;
    RET 					 ;AN000;
						 ;
RESTORE_SEPARATOR  ENDP 			 ;AN000;
;********************************************************************************
; CHANGE_ATTRIBUTE_ROUTINE:  Change the attributes on a group of files.
;
; INPUT:
;    SI = The address of a list of files to change the attributes of.
;    AX = 0: Attach a new attribute to the file.
;    AX = 1: Restore the original attribute to the files.
;    BX = The number of files in the list.
;
; OUTPUT:
;    If CY = 1, there were error encountered.
;    If CY = 0, there were no errors.
;
;********************************************************************************
PUBLIC	 CHANGE_ATTRIBUTE_ROUTINE		 ;AN000;
CHANGE_ATTRIBUTE_ROUTINE     PROC FAR		 ;AN000;
						 ;
    CALL HOOK_INT_24				 ;AN000;
						 ;
    MOV  WAY, AX				 ;AN000; Save flag indicating whether we are setting or restoring the attrb.
    MOV  NEW_ATTRIB, 02h			 ;AN000; Set new attribute to hidden.
    MOV  DI, 0					 ;AN000; Count of files processed
    .WHILE < DI B BX >				 ;AN000;
	 .IF < WAY EQ 0 >			 ;AN000; Setting the attribute?
	      MOV  WORD PTR [SI+12],0		 ;AN000; Make filename into a ASCII-Z string
	      MOV  DX, SI			 ;AN000; Load address of filename into DX
	      MOV  AX, 4300H			 ;AN000; Get the file's current attribute
	      DOSCALL				 ;AN000;
	      .IF < C > 			 ;AN000; Was there an error?
		   JMP	CHMOD_ERROR		 ;AN000; If so, exit the subroutine
	      .ENDIF				 ;AN000;
	      MOV  OLD_ATTRIB, CX		 ;AN000; Save the attribute
	      MOV  CX, NEW_ATTRIB		 ;AN000; Get the new attribute
	 .ELSE					 ;AN000; Otherwise, we are restoring the attribute
	      MOV  CX, [SI+12]			 ;AN000; Get the old attribute
	      MOV  OLD_ATTRIB, CX		 ;AN000; Save.
	      MOV  WORD PTR [SI+12], 0		 ;AN000; Make filename into an ASCII-Z string
	 .ENDIF 				 ;AN000;
	 MOV  DX, SI				 ;AN000; Pointer to the filename
	 MOV  AX, 4301H 			 ;AN000; DOS function for setting the attribute
	 DOSCALL				 ;AN000; Set it.
	 .IF < C >				 ;AN000; Was there an error?
	      JMP  CHMOD_ERROR			 ;AN000; If so, exit the subroutine
	 .ENDIF 				 ;AN000;
	 MOV  CX, OLD_ATTRIB			 ;AN000; Get the old attribute
	 MOV  [SI+12], CX			 ;AN000; Save in the table
	 ADD  SI, 14				 ;AN000; Point to the next filename
	 INC  DI				 ;AN000; Increment count of files processed
    .ENDWHILE					 ;AN000;
    CLC 					 ;AN000; Indicate there were no errors
    RET 					 ;AN000;
						 ;
CHMOD_ERROR:					 ;AN000;
    STC 					 ;AN000; Indicate there were errors
						 ;
    CALL RESTORE_INT_24 			 ;AN000;
						 ;
    RET 					 ;AN000;
						 ;
CHANGE_ATTRIBUTE_ROUTINE     ENDP		 ;AN000;
;****************************************************************************
;
;   COMPARE_ROUTINE:  Compare two strings.
;
;   INPUT:
;	SI = The address of the first string. (ASCII-N string)
;	DI = The address of the second string. (ASCII-N string)
;
;   OUTPUT:
;	If CY = 1, the strings do no compare.
;	If CY = 0, the strings are the same.
;
;   OPERATION:
;
;****************************************************************************
PUBLIC	 COMPARE_ROUTINE			 ;AN000;
COMPARE_ROUTINE    PROC FAR			 ;AN000;
						 ;
    PUSH ES					 ;AN000; Make ES = DS
    PUSH DS					 ;AN000;
    POP  ES					 ;AN000;
						 ;
    MOV  CX, [SI]				 ;AN000; Get the length of the first string
    .IF < [DI] NE CX >				 ;AN000; Are the lengths of the strings the same?
	 JMP  DO_NOT_COMPARE			 ;AN000; If not, the strings are not the same
    .ENDIF					 ;AN000;
    ADD  SI, 2					 ;AN000; Move points past the length words
    ADD  DI, 2					 ;AN000;
    CLD 					 ;AN000; Compare in the forward direction
    REPZ CMPSB					 ;AN000; Compare the strings
    JNZ  DO_NOT_COMPARE 			 ;AN000; If the zero flag cleared, strings are not the same
    CLC 					 ;AN000; Indicate the strings do compare
    JMP  EXIT_COMPARE				 ;AN000;
DO_NOT_COMPARE: 				 ;AN000;
    STC 					 ;AN000; Indicate the strings do no compare
EXIT_COMPARE:					 ;AN000;
    POP  ES					 ;AN000;
    RET 					 ;AN000;
						 ;
COMPARE_ROUTINE    ENDP 			 ;AN000;
;****************************************************************************
;
;   REMOVE_END_BLANKS: Removes the trailing blanks from a string.
;
;   INPUT:
;	ES:DI Points to the last character in the string.
;
;   OUTPUT:
;	ES:DI Points to the new end of the string after the blanks have been
;	      removed.
;
;   OPERATION:
;
;****************************************************************************
PUBLIC	 REMOVE_END_BLANKS			 ;AN000;
REMOVE_END_BLANKS  PROC FAR			 ;AN000;
						 ;
    MOV  CX, 0FFFFH				 ;AN000;
    MOV  AL, ' '                                 ;AN000;
    STD 					 ;AN000;
    REPZ SCASB					 ;AN000;
    .IF < NZ >					 ;AN000;
	 INC  DI				 ;AN000;
    .ENDIF					 ;AN000;
    RET 					 ;AN000;
						 ;
REMOVE_END_BLANKS  ENDP 			 ;AN000;
						 ;
;****************************************************************************
;
;   CHECK_WRITE_ROUTINE  Determine if the diskette in drive A is write
;		       protected.
;
;   INPUT:
;	CX = 0 - drive A		   ;AN000;JW
;	   = 1 - drive B		   ;AN000;JW
;
;   OUTPUT:
;	If CY = 1, The disk IS write protected.
;	If CY = 0, The disk is NOT write protected.
;
;   OPERATION:
;
;****************************************************************************
PUBLIC	 CHECK_WRITE_ROUTINE			 ;AN000;
CHECK_WRITE_ROUTINE	PROC FAR		 ;AN000;
						 ;
    MOV  DRIVE_FLAG,CL				 ;AN000;
						 ;
    CALL HOOK_INT_24				 ;AN000;
						 ;
    MOV  CHK_W_PROTECT_FLAG, TRUE		 ;AN000; Indicate to INT 24H handler we are looking for error
    MOV  W_PROTECT_FLAG, FALSE			 ;AN000; Error has not occured yet.
						 ;
    MOV  W_P_FILENAME_A+3, 0			 ;AN000; Make drive string into ASCII-Z string
    MOV  W_P_FILENAME_B+3, 0			 ;AN000; Make drive string into ASCII-Z string	  JW
    .IF < DRIVE_FLAG eq DRIVE_A >		 ;AN000;JW
       MOV  DX, OFFSET W_P_FILENAME_A		 ;AN000; Get address of the string
    .ELSE					 ;AN000;JW
       MOV  DX, OFFSET W_P_FILENAME_B		 ;AN000; Get address of the string JW
    .ENDIF					 ;AN000;JW
    MOV  CX, 0					 ;AN000; Attribute to give the file
    MOV  INT_24_ERROR, FALSE			 ;AN000;
    MOV  AH, 5AH				 ;AN000; DOS Fn. call to create a unique file
    DOSCALL					 ;AN000; Create the file
    .IF < C >					 ;AN000; Was there an error?
	 .IF < W_PROTECT_FLAG EQ TRUE > 	 ;AN000; If the INT 24H handler was call...
	      JMP  WRITE_PROTECTED		 ;AN000; The disk is write protected.
	 .ELSE					 ;AN000; Otherwise...
	      JMP  CHECK_ERROR			 ;AN000; There was some other disk error
	 .ENDIF 				 ;AN000;
    .ELSE					 ;AN000;
	.IF < W_PROTECT_FLAG EQ TRUE >		 ;AN000; If the INT 24H handler was call...
	     JMP  WRITE_PROTECTED		 ;AN000; The disk is write protected.
	.ENDIF					 ;AN000;
    .ENDIF					 ;AN000; There were no errors...
    CLOSE_FILE	   AX				 ;AN000; Close the created file
    .IF < DRIVE_FLAG eq DRIVE_A >		 ;AN000;JW
       MOV  DX, OFFSET W_P_FILENAME_A		 ;AN000; Get address of the string
    .ELSE					 ;AN000;JW
       MOV  DX, OFFSET W_P_FILENAME_B		 ;AN000; Get address of the string JW
    .ENDIF					 ;AN000;JW
    MOV  AH, 41H				 ;AN000; DOS Fn. for erasing a file
    DOSCALL					 ;AN000; Erase the file
    MOV  AX, 0					 ;AN000; Indicate the file is NOT write protected
    CLC 					 ;AN000; Indicate there were no errors
    JMP  CHECK_EXIT				 ;AN000; Exit the routine

WRITE_PROTECTED:				 ;AN000;
    MOV  AX, 1					 ;AN000; Indicate the file IS write protected
    CLC 					 ;AN000; Indicate there were no errors
    JMP  CHECK_EXIT				 ;AN000;

CHECK_ERROR:					 ;AN000;
    MOV  AX, 0					 ;AN000; Indicate the file is NOT write protected
    STC 					 ;AN000; Indicate that there WERE errors

CHECK_EXIT:					 ;AN000;
    CALL RESTORE_INT_24 			 ;AN000; Restore the original INT 24H handler
    MOV  CHK_W_PROTECT_FLAG, FALSE		 ;AN000; We are no longer expecting a write protect error
    RET 					 ;AN000;

CHECK_WRITE_ROUTINE	ENDP			 ;AN000;
;****************************************************************************
;
;   MATCH_FILES_ROUTINE  Determine is a list of file exist on a drive.
;
;   INPUT:
;	DI = Address of the ASCII-N string containing the drive and path to
;	     search for the files.
;	SI = The address of the list of file.  If AX = 2, the first two bytes
;	      in the list are ignored.
;	AX = The type of list to use.
;	   = 1: Use a list with only 12 bytes between the filenames.
;	   = 2: Use a list with only 14 bytes between the filenames.
;	CX = The number of files in the list.
;
;   OUTPUT:
;	If CY = 1, There was an error access the disk.
;	If CY = 0, There were no errors.
;	      AX = 1: All the files are on the disk.
;	      AX = 0: All the files are NOT on the disk.
;
;   OPERATION:
;
;****************************************************************************
PUBLIC	 MATCH_FILES_ROUTINE			 ;AN000;
MATCH_FILES_ROUTINE	PROC FAR		 ;AN000;
						 ;
						 ;
    PUSH ES					 ;AN000; Make ES = DS
    PUSH DS					 ;AN000;
    POP  ES					 ;AN000;
						 ;
    MOV  NUM_FILES, CX				 ;AN000; Save the number of files
    MOV  LIST_TYPE, AX				 ;AN000; Save the type of the list
						 ;
    MOV  CX, [DI]				 ;AN000; Get the length of the string
    ADD  DI, 2					 ;AN000; Point SI to the start of the string
    MOV  DX, DI 				 ;AN000; Copy the address of the string
    ADD  DI, CX 				 ;AN000; Point to the end of the string
    .IF < LIST_TYPE EQ 2 >			 ;AN000; If this list is a 14 byte list...
	 ADD  SI, 2				 ;AN000; Bypass the first two bytes in the list
    .ENDIF					 ;AN000;
    MOV  STR_PTR, DI				 ;AN000; Save the pointer to the path string
    MOV  FILE_PTR, SI				 ;AN000; Save the pointer to the file list
    MOV  BX, 0					 ;AN000; Initialize the count of files checked
						 ;
    .WHILE < BX B NUM_FILES >			 ;AN000; Perform NUM_FILES interations
	 CLD					 ;AN000;
	 MOV  CX, 12				 ;AN000; Move 12 bytes for the filename
	 REP  MOVSB				 ;AN000; Move the filename after the path string
	 MOV  BYTE PTR [DI], 0			 ;AN000; Make string into an ASCII-Z string
	 MOV  AH, 4EH				 ;AN000; DOS Fn. for find a file
	 MOV  CX, 0				 ;AN000; Attribute used for search
	 DOSCALL				 ;AN000; Get the matching filename
	 .IF < C >				 ;AN000; Was there an error?
	      .IF < AX EQ 18 >			 ;AN000; If error no = 18, then file not found
		   JMP	FILE_NOT_FOUND		 ;AN000; Return to the user
	      .ELSE				 ;AN000; Otherwise
		   JMP	MATCH_ERROR		 ;AN000; There was some other type of disk error
	      .ENDIF				 ;AN000; Exit the subroutine
	 .ENDIF 				 ;AN000;
	 MOV  DI, STR_PTR			 ;AN000; Get the pointer to the string
	 MOV  SI, FILE_PTR			 ;AN000; Get the pointer to the file list
	 .IF < LIST_TYPE EQ 1 > 		 ;AN000; Check list type for incrementing the file pointer
	      ADD  SI, 12			 ;AN000; 12 bytes between files for list type 1
	 .ELSE					 ;AN000;
	      ADD  SI, 14			 ;AN000; 14 bytes between files for list type 2
	 .ENDIF 				 ;AN000;
	 MOV  FILE_PTR, SI			 ;AN000; Save the new file name pointer
	 INC  BX				 ;AN000; Increment the count of files searched for
    .ENDWHILE					 ;AN000;
    CLC 					 ;AN000; Indicate there were no errors
    MOV  AX, 1					 ;AN000; Indicate that all the files were found
    JMP  EXIT_MATCH				 ;AN000;
FILE_NOT_FOUND: 				 ;AN000;
    CLC 					 ;AN000; Indicate that there were no errors
    MOV  AX, 0					 ;AN000; But, all the files were not found
    JMP  EXIT_MATCH				 ;AN000;
MATCH_ERROR:					 ;AN000;
    STC 					 ;AN000; Indicate that there were errors
EXIT_MATCH:					 ;AN000;
    POP  ES					 ;AN000;
    RET 					 ;AN000;
						 ;
MATCH_FILES_ROUTINE	ENDP			 ;AN000;
;************************************************************************
;
;   CLOSE_FILE_ROUTINE: Close File
;
;   INPUT:
;      BX = The file handle of the file to close.
;
;   OUTPUT:
;	     CY = 0, AX = undefined,  successful
;	     CY = 1, AX = error code
;
;   OPERATION:
;
;   THIS MACROS CLOSES THE FILE WITH THE GIVEN FILE HANDLE.
;   IT MAKES USE OF INT 21 (AH=3EH).
;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;   IS RETURNED IN AX.
;
;**************************************************************************
PUBLIC	 CLOSE_FILE_ROUTINE			 ;AN000;
CLOSE_FILE_ROUTINE PROC FAR			 ;AN000;
						 ;
						 ;
    CALL HOOK_INT_24				 ;AN000; Hook in the critical error handler
    MOV  INT_24_ERROR, FALSE			 ;AN000; Indicate no critical error have occured yet
    MOV  AH, 3EH				 ;AN000; DOS Fn. for closing a file
    DOSCALL					 ;AN000; Close the file
    CALL RESTORE_INT_24 			 ;AN000; Restore the old critical error handler
    RET 					 ;AN000;
						 ;
CLOSE_FILE_ROUTINE ENDP 			 ;AN000;
;**************************************************************
;
;   CREATE_FILE: Create new File
;
;   INPUT:
;	 DI = The address of the filename in ASCII-N format
;	 CX = The attribute to give the file
;
;   OUTPUT:
;	 If CY = 0: There were no errors.
;	      AX - The file handle of the created file.
;	 If CY = 1: There were file errors.  AX contains the error code.
;
;   OPERATION:
;
;   CREATE_FILE CREATES A FILE WITH THE GIVEN NAME USING INT 21H (AH=5BH)
;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;   IS RETURNED IN AX.
;
;**************************************************************************
PUBLIC	 CREATE_FILE_ROUTINE			 ;AN000;
CREATE_FILE_ROUTINE	PROC FAR		 ;AN000;
						 ;
    CALL HOOK_INT_24				 ;AN000;
    CALL POS_ZERO				 ;AN000;
    MOV  DX, DI 				 ;AN000;
    ADD  DX, 2					 ;AN000;
    MOV  INT_24_ERROR, FALSE			 ;AN000;
    MOV  AH,5BH 				 ;AN000;
    DOSCALL					 ;AN000;
    CALL RESTORE_INT_24 			 ;AN000;
    RET 					 ;AN000;
						 ;
CREATE_FILE_ROUTINE	ENDP			 ;AN000;
;****************************************************************************
;
;   ERASE_FILE_ROUTINE: Routine to erase a file.
;
;   INPUT:
;	 DI - The address of an ASCII-N string containing the name of the file
;	      to erase.
;
;   OUTPUT:
;	 If CY = 0, there were no error encountered.
;	 If CY = 1, there were errors.	AX contains the DOS error code.
;
;   OPERATION:
;
;   ERASE_FILE ERASES THE FILE USING INT 21H (AH=41H).
;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;   IS RETURNED IN AX.
;
;****************************************************************************
PUBLIC	 ERASE_FILE_ROUTINE			 ;AN000;
ERASE_FILE_ROUTINE PROC FAR			 ;AN000;

    CALL HOOK_INT_24				 ;AN000;
    CALL POS_ZERO				 ;AN000;
    MOV  INT_24_ERROR, FALSE			 ;AN000;
    MOV  DX, DI 				 ;AN000;
    ADD  DX, 2					 ;AN000;
    MOV  AH,41H 				 ;AN000;
    DOSCALL					 ;AN000;
    CALL RESTORE_INT_24 			 ;AN000;
    RET 					 ;AN000;

ERASE_FILE_ROUTINE ENDP 			 ;AN000;
;****************************************************************************
;
;   CHMOD_FILE_ROUTINE: Change file attributes to read/write
;
;   SYNTAX:  CHMOD_FILE_ROUTINE
;
;   INPUT:   DI = POINTER TO ASCII-N STRING - FILE NAME
;
;   OUTPUT:  None.
;
;   OPERATION:
;      The CHMOD dos call is executed (43H) to change the file's attributes
;      to read/write.
;
;****************************************************************************
PUBLIC CHMOD_FILE_ROUTINE			 ;AN000;
CHMOD_FILE_ROUTINE PROC FAR			 ;AN000;

	CALL HOOK_INT_24			 ;AN000;
	CALL POS_ZERO				 ;AN000;
	MOV  INT_24_ERROR, FALSE		 ;AN000;
	MOV  DX, DI				 ;AN000;
	ADD  DX, 2				 ;AN000;
	MOV  AH,043H				 ;AN000;
	MOV  AL,01				 ;AN000;
	XOR  CX,CX				 ;AN000;
	DOSCALL 				 ;AN000;
	CALL RESTORE_INT_24			 ;AN000;
	RET					 ;AN000;

CHMOD_FILE_ROUTINE ENDP 			 ;AN000;
;************************************************************************
;   FIND_FILE: Find File
;
;   INPUT:
;	 DI - The address of an ASCII-N string contian the name of the file
;	      to find.
;	 CX - The attribute to be used in the search.
;
;   OUTPUT:
;	 If CY = 1, there were errors encountered. AX contians the DOS error
;		    code.
;	 If CY = 0, there were no errors.
;
;   OPERATION:
;
;   FINDFILE FINDS THE FIRST FILENAME SPECIFIED USING INT 21 (AH=4EH).
;   AND LOADS INFORMATION INTO THE CURRENT DTA.
;   NOTE : THE DEFAULT DTA IS AT 80H IN THE PSP.
;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;   IS RETURNED IN AX.
;
;************************************************************************
PUBLIC	 FIND_FILE_ROUTINE			 ;AN000;
FIND_FILE_ROUTINE  PROC FAR			 ;AN000;
						 ;
    CALL HOOK_INT_24				 ;AN000;
    CALL POS_ZERO				 ;AN000;
    MOV  DX, DI 				 ;AN000;
    ADD  DX, 2					 ;AN000;
    MOV  INT_24_ERROR, FALSE			 ;AN000;
						 ; CX Contains the attribute to be used in the search
    MOV  AH,4EH 				 ;AN000;
    DOSCALL					 ;AN000;
    CALL  RESTORE_INT_24			 ;AN000;
    RET 					 ;AN000;

FIND_FILE_ROUTINE  ENDP 			 ;AN000;
;**************************************************************************
;
;   OPEN_FILE_ROUTINE - Open File
;
;   INPUT:
;	 DI - The address of an ASCII-N string containing the name of the
;	      file to open.
;	 AL - The mode to open the file with ( 0 = read, 1 = write,
;	      2 = read/write)
;
;   OUTPUT:
;	 If CY = 1, there were errors encountered.  AX contains the DOS error
;		    code.
;	 If CY = 0, there were no errors.  AX contains the file handle.
;
;   OPERATION:
;
;   THIS MACRO OPENS A FILE FOR READ/WRITE OPERATIONS.
;   IT MAKES USE OF INT 21 (AH=3DH).
;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;   IS RETURNED IN AX.
;
;**************************************************************************
PUBLIC	 OPEN_FILE_ROUTINE			 ;AN000;
OPEN_FILE_ROUTINE  PROC FAR			 ;AN000;
						 ;
    CALL HOOK_INT_24				 ;AN000;
    CALL POS_ZERO				 ;AN000;
    MOV  INT_24_ERROR, FALSE			 ;AN000;
    MOV  DX, DI 				 ;AN000;
    ADD  DX, 2					 ;AN000;
						 ; AL contains the mode for opening the file.
    MOV  AH,3DH 				 ;AN000;
    DOSCALL					 ;AN000;
    CALL RESTORE_INT_24 			 ;AN000;
    RET 					 ;AN000;

OPEN_FILE_ROUTINE  ENDP 			 ;AN000;
;**************************************************************************
;
;   RENAME_FILE_ROUTINE - Rename File
;
;   INPUT:
;	 SI - The address of an ASCII-N string containing the file to rename
;	      current file name.
;	 DI - The address of an ASCII-N string containing the new name for the
;	      file.
;
;   OUTPUT:
;	 If CY = 1, there were errors encountered.  AX contains the DOS error
;		   error code.
;	 If CY = 0, there were no errors.
;
;
;   OPERATION:
;
;   THIS MACRO RENAMES A FILE GIVEN 2 NAMES.
;   IT MAKES USE OF INT 21 (AH=56H).
;   IF AN ERROR OCCURS, THE CARRY FLAG IS SET, AND THE ERROR CODE
;   IS RETURNED IN AX.
;
;**************************************************************************
PUBLIC	 RENAME_FILE_ROUTINE			 ;AN000;
RENAME_FILE_ROUTINE	PROC FAR		 ;AN000;

    CALL HOOK_INT_24				 ;AN000;
    PUSH ES					 ;AN000;
    PUSH DS					 ;AN000;
    POP  ES					 ;AN000;
    PUSH DI					 ;AN000;
    ; SI Contains the address of the string containing the old filename.
    MOV  DI, SI 				 ;AN000;
    CALL POS_ZERO				 ;AN000;
    MOV  DX, DI 				 ;AN000;
    ADD  DX, 2					 ;AN000;

    POP  DI					 ;AN000;
    ; DI contains the address of the string containing the new filename.
    CALL POS_ZERO				 ;AN000;
    ADD  DI, 2					 ;AN000;

    MOV  INT_24_ERROR, FALSE			 ;AN000;
    MOV  AH,56H 				 ;AN000;
    DOSCALL					 ;AN000;
    POP  ES					 ;AN000;
    CALL  RESTORE_INT_24			 ;AN000;
    RET 					 ;AN000;

RENAME_FILE_ROUTINE	ENDP			 ;AN000;
;**************************************************************************
;
;   READ_FILE_ROUTINE: Transfer the specified number of bytes from a file into a
;	buffer location.
;
;   INPUT:
;	BX - The handle of the file to read.
;	DX - The address of where to store the data
;	CX - The number of characters to read
;
;   OUTPUT:
;	CY = 0, Read success.  AX - number of bytes read
;	CY = 1, Read error. AX contains the error code.
;
;   OPERATION:
;
;   THIS MACRO READS TO AN ALREADY OPENED FILE.
;   IT MAKES USE OF INT 21 (AH=3FH).
;   AX WILL RETURN THE NUMBER BYTES ACTUALLY WRITTEN.
;
;************************************************************************
PUBLIC	 READ_FILE_ROUTINE			 ;AN000;
READ_FILE_ROUTINE  PROC FAR			 ;AN000;
						 ;
    CALL HOOK_INT_24				 ;AN000;
    MOV  INT_24_ERROR, FALSE			 ;AN000;
						 ; BX - The file handle
						 ; CX - The number of bytes to read
						 ; DX - The address of the buffer to store the data
    MOV  AH,3FH 				 ;AN000;
    DOSCALL					 ;AN000;
    CALL RESTORE_INT_24 			 ;AN000;
    RET 					 ;AN000;

READ_FILE_ROUTINE  ENDP 			 ;AN000;
;**************************************************************************
;
;   WRITE_FILE_ROUTINE: Transfer the specified number of bytes from a buffer into a
;	specified file.
;
;   INPUT:
;	BX - The handle of the file to write to.
;	DX - The address of where the data is stored.
;	CX - The number of characters to write.
;
;   OUTPUT:
;	CY = 0, Write success.	AX - number of bytes written.
;	CY = 1, Write error. AX contains the error code.
;
;   OPERATION:
;
;   THIS MACRO WRITES TO AN ALREADY OPENED FILE.
;   IT MAKES USE OF INT 21 (AH=3DH).
;   AX WILL RETURN THE NUMBER BYTES ACTUALLY WRITTEN.
;
;************************************************************************
PUBLIC	 WRITE_FILE_ROUTINE			 ;AN000;
WRITE_FILE_ROUTINE PROC FAR			 ;AN000;
						 ;
    CALL HOOK_INT_24				 ;AN000;
    MOV  INT_24_ERROR, FALSE			 ;AN000;
						 ; BX - The file handle
						 ; CX - The number of bytes to read
						 ; DX - The address of the buffer to store the data
    MOV  AH,40H 				 ;AN000;
    DOSCALL					 ;AN000;
    CALL RESTORE_INT_24 			 ;AN000;
    RET 					 ;AN000;

WRITE_FILE_ROUTINE ENDP 			 ;AN000;
;***************************************************************************
;
;   CHECK_DISK:  Check is the specified fixed disk is present.	If disk is
;	present, return disk partition status.
;
;   INPUT:
;	AX = 1: First fixed disk.
;	   = 2: Second fixed disk.
;
;   OUTPUT:
;	CX = 0: Disk not present.
;	   = 1: Disk present - No DOS or EDOS partitions
;	   = 2: Disk present - DOS or EDOS partitions exist
;	BX = 01H: Primary DOS partition exists
;	   = 02H: Extended DOS partitions exists
;	   = 04H: Logical drives exist
;	   = 08H: Free space exists in EDOS partition
;	   = 10H: Free space exists on disk
;			      More than one status bit can be set
;	DX = 0: There is no free space in EDOS partition and the
;		disk.
;	   = 1: There is free space in the EDOS partition.
;	   = 2: There is no EDOS partition, but there is free
;			  disk space.
;	DI = Buffer for fixed disk status information.
;
;   OPERATION:	A call is performed to the FDISK utility (GET_DISK_STATUS)
;	to get the status of the specified fixed disk drive.  The returned
;	status information is checked and the memory variables are set as
;	specified above.
;
;***************************************************************************
PUBLIC	 CHECK_DISK_ROUTINE			 ;AN000;
CHECK_DISK_ROUTINE PROC FAR			 ;AN000;
						 ;
    PUSH ES					 ;AN000; Make ES = DS
    PUSH DS					 ;AN000;
    POP  ES					 ;AN000;
    PUSH DI					 ;AN000;
    ADD  DI, 2					 ;AN000;
    CALL GGET_STATUS				 ;AN000;
    POP  DI					 ;AN000;
    MOV  [DI+1], CL				 ;AN000; Store the number of table entries
    .IF < ZERO AX >				 ;AN000;
	 .IF < BIT BX AND M_DOS_EDOS_PART >	 ;AN000;
	      MOV  CX, PRESENT_WITH_PART	 ;AN000;
	 .ELSE					 ;AN000;
	      MOV  CX, PRESENT_WITHOUT_PART	 ;AN000;
	 .ENDIF 				 ;AN000;
    .ELSE					 ;AN000;
	 MOV  CX, NOT_PRESENT			 ;AN000;
    .ENDIF					 ;AN000;
    MOV  DX, NO_EDOS_SPACE			 ;AN000; Initialize
    .IF < BIT BX AND M_EDOS_EXISTS >		 ;AN000; Does the extended DOS partition exist?
	 .IF < BIT BX AND M_EDOS_SPACE >	 ;AN000; Yes! Is there free space in it?
	      MOV  DX, FREE_EDOS_SPACE		 ;AN000; Indicate that there is free space
	 .ELSEIF < BIT BX NAND M_FREE_SPACE >	 ;AN000; Is there no free space on the disk?
	      MOV  DX, NO_EDOS_SPACE		 ;AN000; Indicate there is no free space in EDOS or on the disk.
	 .ENDIF 				 ;AN000;
    .ELSEIF < BIT BX AND M_FREE_SPACE >		 ;AN000; No! There is no EDOS partition
	 MOV  DX, NO_EDOS_BUT_SPACE		 ;AN000; But there is free space on the disk
    .ENDIF					 ;AN000;
    POP  ES					 ;AN000;
    RET 					 ;AN000;
						 ;
CHECK_DISK_ROUTINE ENDP 			 ;AN000;
;************************************************************************;;
;
;   CHECK_VALID_MEDIA:	Check if the diskettes attached will support
;	installation of SELECT.  Also, check if install destination will
;	be selected by user or determined by SELECT.
;
;   SYNTAX:  CHECK_VALID_MEDIA	var_disk_a, var_disk_b, var_tot, var_disk,
;				var_def, var_index, var_option
;
;   INPUT:
;	var_disk_a  =  diskette A presence and type
;	var_disk_b  =  diskette B presence and type
;	var_tot     =  total number of dikettes
;	var_disk    =  0: first fixed disk is not present
;		    >  0: first fixed disk is present
;
;   OUTPUT:
;	CY = 0: Success variables are returned as defined below.
;	CY = 1: Error - invalid media
;	var_def   =  0 use default destination drive
;		  =  1 default destination drive not applicable
;	var_index =  1 default destination is drive C
;		  =  2 default destination is drive B
;	var_option = 1 possible drive B or C
;		   = 2 possible drive A or C
;		   = 3 possible drive A or B or C
;		   = 4 possible drive A or B
;
;   OPERATION:	The diskette drive types are checked for valid media type.
;	If the diskette media types are valid, a check is made to determine if
;	install destination will be user selected or will be determined by
;	SELECT.  The following checks are made.
;
;	 - if one diskette, return valid media and default destination is A
;
;	 - If two diskettes only, return valid and:
;	       if A = B, default = B
;	       if A <> B, default = A
;	       if A and B are mixed 720 and 1.44, destination option is A or B
;
;	 - If one diskette and a fixed disk only, return valid media and
;	   destination option is drive A or C.
;
;	 - If two diskettes and a fixed disk, return valid media and:
;	       if A = B, destination option is B or C
;	       if A <> B, destination option is A or C
;	       if A and B are mixed 720 and 1.44, destination option is
;		 A or B or C
;
;************************************************************************;;
PUBLIC	 CHECK_VALID_MEDIA_ROUTINE		 ;AN111;JW
CHECK_VALID_MEDIA_ROUTINE    PROC FAR		 ;AN111;JW


    VAR_DISK_A	   EQU	     AL 		 ;AN111;JW
    VAR_DISK_B	   EQU	     BL 		 ;AN111;JW
    VAR_DEF	   EQU	     CL 		 ;AN111;JW
    VAR_INDEX	   EQU	     DX 		 ;AN111;JW
    VAR_DISK	   EQU	     SI 		 ;AN111;JW
    VAR_OPTION	   EQU	     DI 		 ;AN111;JW

    .IF < VAR_DISK_A NE E_DISKETTE_INV >	 ;AN111; Is disk A present
	 .IF <VAR_DISK_B NE E_DISKETTE_INV>	 ;AN111; Is disk B present
	      .IF < VAR_DISK GT 0 >		 ;AN111; Hard disk is present?
		   MOV	  VAR_DEF, DO_NOT_USE_DEFAULT ;AN111; Yes! Destination drive is undefined
		   MOV VAR_OPTION,E_OPTION_B_C	 ;AN111; options will be B or C
		   MOV	  VAR_INDEX,DEF_DEST_C	 ;AN073; SEH highlight option C
		   CLC				 ;AN111; Indicate valid media
	      .ELSE				 ;AN111;
		   MOV	VAR_DEF, USE_DEFAULT	 ;AN111; Yes! Use the default destination = B
		   MOV	VAR_INDEX, DEF_DEST_B	 ;AN111; Drive B is that default
		   CLC				 ;AN111; Indicate valid media
	      .ENDIF				 ;AN111;
	 .ELSE					 ;AN111;
	      .IF < VAR_DISK GT 0 >		 ;AN111; Hard disk is present?
		   MOV	  VAR_DEF, DO_NOT_USE_DEFAULT ;AN111; Yes! Destination drive is undefined
		   MOV	  VAR_OPTION, E_OPTION_A_C ;AN111; options are A or C
		   MOV	  VAR_INDEX,DEF_DEST_C	 ;AN073; SEH highlight option C
		   CLC				 ;AN111; Indicate valid media
	      .ELSE				 ;AN111;
		   MOV	  VAR_DEF, USE_DEFAULT	 ;AN111; no, Use the default destination
		   MOV	  VAR_INDEX, DEF_DEST_A  ;AN111; Drive A is that default
		   CLC				 ;AN111; Indicate valid media
	      .ENDIF				 ;AN111;
	 .ENDIF 				 ;AN111;
    .ELSE					 ;AN111;
	 STC					 ;AN111; Indicate invalid media
    .ENDIF					 ;AN111;
    RET 					 ;AN111;

CHECK_VALID_MEDIA_ROUTINE    ENDP		 ;AN111;JW
;************************************************************************;;
;
;   SCAN_DISK_TABLE:  Scan the specified disk status table from the
;	specified index item for specified field and return status information.
;
;   INPUT:
;	CX = 1: First fixed disk
;	   = 2: Second fixed disk
;	AX = Index of the information to return
;
;   OUTPUT:
;	AX = 0: Success - Index into table is valid
;	   = 1: Error - Index invalid or end of table
;	N_NAME_PART   = Partition name.
;	N_SIZE_PART   = Partition size.
;	N_STATUS_PART = Partition status
;	P_DRIVE_PART  = Drive letter assigned.
;	P_LEVEL1_PART  = Version number (1st part).   For DOS 4.00 1st part = blank
;	P_LEVEL2_PART  = Version number (2nd part).   For DOS 4.00 2nd part = 4
;	P_LEVEL3_PART  = Version number (3rd part).   For DOS 4.00 3rd part = .
;	P_LEVEL4_PART  = Version number (4th part).   For DOS 4.00 4th part = 0
;
;   OPERATION:
;      Starts scanning the disk table from the point indicated by var_index
;      for either the name, status or type.  The table is scanned until either
;      the desired entry is found, or the end of the table is reached.	If
;      the end of the table is reached before a matching entry is found, then
;      var_ret returns 1, else if an entry is found, it returns 0.
;      If found, var_index will also return the index of the entry.
;
;      Note:  The index of the first entry in the table is 1.
;
;************************************************************************;;
PUBLIC	 SCAN_DISK_TABLE_ROUTINE							     ;AN000;
SCAN_DISK_TABLE_ROUTINE PROC FAR							     ;AN000;

    MOV  BX, 0					 ;AN000;
    .IF < CX EQ TABLE_ONE >			 ;AN000;
	 MOV  SI, OFFSET DISK_1_START		 ;AN000; Get the address of the first table
	 MOV  BL, DISK_1_VAL_ITEM		 ;AN000; Number of entries in the first table
    .ELSE					 ;AN000;
	 MOV  SI, OFFSET DISK_2_START		 ;AN000; Get the address of the second table
	 MOV  BL, DISK_2_VAL_ITEM		 ;AN000; Number of entries in the second table
    .ENDIF					 ;AN000;
    .IF < AX BE BX >				 ;AN000;
						 ; AX contains the index
	 DEC  AX				 ;AN000; Make the first index a 0
	 MOV  DX, TYPE DISK_STATUS		 ;AN000; Number of bytes in the structure
	 MUL  DX				 ;AN000; Calculate the offset into the table
	 ADD  SI, AX				 ;AN000; Add to the address of the table
	 COPY_BYTE	 N_NAME_PART,	[SI].N_PART_NAME   ;AN000; Copy the table entries
	 COPY_WORD	 N_SIZE_PART,	[SI].N_PART_SIZE   ;AN000;
	 COPY_BYTE	 N_STATUS_PART, [SI].N_PART_STATUS ;AN000;
	 COPY_BYTE	 P_DRIVE_PART,	[SI].P_PART_DRIVE  ;AN000;
	 COPY_BYTE	 N_TYPE_PART,	[SI].N_PART_TYPE   ;AN000;
	 COPY_BYTE	 N_LEVEL1_PART, [SI].N_PART_LEVEL1 ;AN065;SEH 1st part of version number   For DOS 4.00 1st part = blank
	 COPY_BYTE	 N_LEVEL2_PART, [SI].N_PART_LEVEL2 ;AN065;SEH 2nd part of version number   For DOS 4.00 2nd part = 4
	 COPY_BYTE	 N_LEVEL3_PART, [SI].N_PART_LEVEL3 ;AN065;SEH 2nd part of version number   For DOS 4.00 3rd part = .
	 COPY_BYTE	 N_LEVEL4_PART, [SI].N_PART_LEVEL4 ;AN065;SEH 2nd part of version number   For DOS 4.00 4th part = 0
	 MOV  AX, DATA_VALID			 ;AN000;
    .ELSE					 ;AN000;
	 MOV  AX, DATA_INVALID			 ;AN000;
    .ENDIF					 ;AN000;
    RET 					 ;AN000;

SCAN_DISK_TABLE_ROUTINE ENDP			 ;AN000;
;************************************************************************;;
;
;   UPDATE_DISK_TABLE:	Update the specifed disk status table for the
;	specified index item.
;
;   INPUT:
;	CX = 1: First fixed disk
;	   = 2: Second fixed disk
;	AX = Index into table
;
;   OUTPUT:
;	AX = 0: Success - Index into table is valid
;	   = 1: Error	- Index into table is not valid
;	partition name	 = N_NAME_PART
;	partition size	 = N_SIZE_PART
;	partition status = N_STATUS_PART
;	partition type	 = N_TYPE_PART
;	drive letter	 = P_DRIVE_PART
;
;   OPERATION:	If the index into the disk table is valid, the disk table
;	is updated for the specifed index.  Disk status information is obtained
;	from pre-defined locations as specified above.
;
;************************************************************************;;
PUBLIC	 UPDATE_DISK_TABLE_ROUTINE		 ;AN000;
UPDATE_DISK_TABLE_ROUTINE    PROC FAR		 ;AN000;

    MOV  BH, 0					 ;AN000;
    .IF < CX EQ TABLE_ONE >			 ;AN000;
	 MOV  SI, OFFSET DISK_1_START		 ;AN000; Get the address of the first table
	 MOV  BL, DISK_1_VAL_ITEM		 ;AN000; Number of entries in the first table
    .ELSE					 ;AN000;
	 MOV  SI, OFFSET DISK_2_START		 ;AN000; Get the address of the second table
	 MOV  BL, DISK_2_VAL_ITEM		 ;AN000; Number of entries in the second table
    .ENDIF					 ;AN000;
						 ; AX contains the index.
    DEC  AX					 ;AN000; Make the first index a 0
    MOV  DX, TYPE DISK_STATUS			 ;AN000; Number of bytes in the structure
    MUL  DX					 ;AN000; Calculate the offset into the table
    ADD  SI, AX 				 ;AN000; Add to the address of the table
    .IF < VAR_INDEX BE BX >			 ;AN000;
	 COPY_BYTE	[SI].N_PART_NAME,   N_NAME_PART    ;AN000;
	 COPY_WORD	[SI].N_PART_SIZE,   N_SIZE_PART    ;AN000;
	 COPY_BYTE	[SI].N_PART_STATUS, N_STATUS_PART  ;AN000;
	 COPY_BYTE	[SI].P_PART_DRIVE,  P_DRIVE_PART   ;AN000;
	 COPY_BYTE	[SI].N_PART_TYPE,   N_TYPE_PART    ;AN000;
	 MOV	 AX, DATA_VALID 		 ;AN000; No error.
    .ELSE					 ;AN000;
	 MOV	 AX, DATA_INVALID		 ;AN000; Indicate an error
    .ENDIF					 ;AN000;
    RET 					 ;AN000;
						 ;
UPDATE_DISK_TABLE_ROUTINE    ENDP		 ;AN000;
						 ;
CODE_FAR ENDS					 ;AN000;
						 ;
END						 ;AN000;
