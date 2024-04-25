;********************************************************************************
; File: PRN_DEF.ASM
;
; Subroutines to read the printer profile file, extract the printer names,
; build a scroll list for the cas services and retrieve addition information
; from the file on a specific printer.
; Also contains a subroutine to change the parameters for the SELECT command
; in the autoexec.bat file.
;
;********************************************************************************
PAGE	, 132				   ;AN000;
.ALPHA					;AN000;
.XLIST					;AN000;
INCLUDE MACROS.INC			;AN000;
INCLUDE STRUC.INC			;AN000;
.LIST					;AN000;

;***************************************************************************
; Define the public subroutines in this module
;***************************************************************************
PUBLIC	 GET_PRINTER_TITLES_ROUTINE	 ;AN000;
PUBLIC	 GET_PRINTER_INFO_ROUTINE	 ;AN000;
PUBLIC	 RELEASE_PRINTER_INFO_ROUTINE	 ;AN000;
PUBLIC	 CHANGE_AUTOEXEC_ROUTINE	 ;AN000;
;***************************************************************************
; Define the public values in this module
;***************************************************************************
PUBLIC	 SEG_LOC			;AN000; The segment where the printer data is stored
PUBLIC	 NAMES_OFF			;AN000; The offset in the segment of the names table
PUBLIC	 N_PRN_NAMES			;AN000; The number of printer definitions read from the profile
PUBLIC	 MAX_NAME			;AN000; The longest name in the list
PUBLIC	 SIZE_NAMES			;AN000; The number of bytes between each printer name (abs)
PUBLIC	 SEL_FLG			;AN000; AN000; SELECT runtime flag

EXTRN	 SYSPARSE: FAR;AN000;
EXTRN	 POS_ZERO: FAR;AN000;
EXTRN	 COPY_ROUTINE: FAR;AN000;
EXTRN	 I_PRINTER: WORD;AN000;
EXTRN	 N_PRINTER_TYPE: BYTE;AN000;
EXTRN	 S_MODE_PARM: WORD;AN000;
EXTRN	 S_CP_DRIVER: WORD;AN000;
EXTRN	 S_CP_PREPARE: WORD;AN000;
EXTRN	 S_GRAPH_PARM: WORD;AN000;
EXTRN	 HOOK_INT_24:FAR;AN000;
EXTRN	 RESTORE_INT_24:FAR;AN000;
EXTRN	 INT_24_ERROR:WORD;AN000;


EXTRN	 BIN_TO_CHAR_ROUTINE:FAR;AN000;

DATA	SEGMENT BYTE PUBLIC 'DATA';AN000;


SEL_FLG 	   DB	     0	  ;AN000; Select flag byte
;INSTALLRW	   EQU	     80H  ;AN000; INSTALL diskette is R/W

SEG_LOC 	   DW	     0	  ;AN000; Location of the segment where the data is
NAMES_OFF	   DW	     0	  ;AN000; The offset of the names table in the segment
SEGMENT_SIZE	   DW	     0	  ;AN000; Amount of memory available
BUFFER_START	   DW	     0	  ;AN000; Starting offset of the file data buffer
BUFFER_SIZE	   DW	     0	  ;AN000; Number of bytes in the file data buffer
FILE_PTR_AT_START  DD	     0	  ;AN000; The file pointer for the data which is at
				  ;  the beginning of the file data buffer
AMOUNT_OF_DATA	   DW	     0	  ;AN000; The number of bytes in the file data buffer
CURRENT_PARSE_LOC  DW	     0	  ;AN000; The location to start the next parse.
END_CUR_LINE	   DW	     0	  ;AN000; The address of the end of the line currently being parsed
CX_ORDINAL_VALUE   DW	     0	  ;AN000; The value returned by the parse for next call
NUM_PRINTER_DEFS   DB	     0	  ;AN000; The number of printer definitions in the file
N_PRN_NAMES	   DW	     0	  ;AN000; The next free index into the names table
FILE_HANDLE	   DW	     0	  ;AN000; Handle for the printer definition file.
MAX_NAME	   DW	     0	  ;AN000; The length of the longest printer name found in the file
START_NEXT_LINE    DW	     0	  ;AN000; The starting offset of the next line to parse
APPEND_POINTER	   DW	     0	  ;AN000; Offset of the ASCII-N string to append to the SELECT line
FILENAME	   DW	     0	  ;AN000; Offset of the ASCII-N string containing the filename
CDP_FOUND	   DB	     0	  ;AN000;
CPP_FOUND	   DB	     0	  ;AN000;


W_VALUE       DW	0	;AN000;
STRING_N      DB   10 DUP(0);AN000;


;AD000;JW BLANK_MODE	     DW   END_BLANK_MODE - $ - 3   ; The blank line for inserting mode parameters
;AD000;JW	   DB	'     , , , , ',?
;AD000;JW	   END_BLANK_MODE EQU  $

BLANK_STRING	   DW	0			 ;AN000; Blank values for the other printer profile parameters

E_SIZE_CR_LF	   EQU	2			 ;AN000; The number of bytes in W_CR_LF
W_CR_LF 	   DB	13,10			 ;AN000; Carrage return and line feed to append to the select line

READ_FLAG	   DB	     0			 ;AN000; Flag for use when reading data
    AT_EOF	   EQU	     1B 		 ;AN000; Indicates when the end of file has been reached
    LAST_LINE	   EQU	     10B		 ;AN000; Indicates if this is the last line in the buffer

    RESET_EOF	   EQU	     11111110B		 ;AN000; Masks for resetting the flags
    RESET_LST_LINE EQU	     11111101B ;AN000;

PARSE_FLAG	   DB	     0			 ;AN000; Flag for use when parsing the data
    FIRST_PARSE    EQU	     1B 		 ;AN000; Indicates if this is the first line being parsed
    LINE_DONE	   EQU	     10B		 ;AN000; Indicates if the current line has already been parsed
    FIRST_NAME	   EQU	     100B		 ;AN000; Indicates if a printer names has already been found

    RESET_FIRST_PARSE	EQU  11111110B		 ;AN000; Masks for resetting the flags
    RESET_LINE_DONE	EQU  11111101B	   ;AN000;
    RESET_FIRST_NAME	EQU  11111011B	  ;AN000;

;***************************************************************************
; Error codes returned.
;***************************************************************************
ERR_NOT_ENOUGH_MEM	EQU	  1		 ;AN000; There was not enough memory to build the names table
ERR_OPENING_FILE	EQU	  2		 ;AN000; Error opening a file
ERR_READING_FILE	EQU	  3		 ;AN000; Error reading from a file
ERR_FINDING_VALUE	EQU	  4		 ;AN000; Error finding the number of prn defs at the beginning of the file
ERR_LINE_TOO_LONG	EQU	  5		 ;AN000; There was a line too long for the buffer
ERR_FINDING_NAME	EQU	  6		 ;AN000; There was an error locating a printer name after a P or S
ERR_ACCESSING_FILE	EQU	  7		 ;AN000; There was an error updating the file pointer
ERR_TOO_MANY_DEFS	EQU	  8		 ;AN000; There are too many defintion in the file
ERR_NUMBER_MATCH	EQU	  9		 ;AN000; The number of actual definition do not match the number expected
ERR_ALLOCATING_MEM	EQU	  10		 ;AN000; There was an error allocating memory
ERR_CDP_CPP		EQU	  11		 ;AN000; A prn defn had either a CDP or CPP but not both
ERR_PRN_DEFN		EQU	  12  ;AN000;

TRUE			EQU	  1	     ;AN000;
FALSE			EQU	  0	    ;AN000;


E_CR			EQU	  13	     ;AN000;
E_LF			EQU	  10	     ;AN000;
E_FILE_TERM		EQU	  1AH  ;AN000;

E_MAX_PRN_NAME_LEN	EQU	  40		 ;AN000; The maximum printer name length
LENGTH_FILE_PTR 	EQU	  4		 ;AN000; The number of bytes in the file pointer
MAX_NUM_PRINTER_DEFS	EQU	  31		 ;AC089;SEH ;AC073; The maximum number of printer definitions
MIN_SIZE_FILE_BUFFER	EQU	  0400H 	 ;AN000; The minimum amount of memory needed for the file data buffer
LENGTH_PRT_TYPE_IND	EQU	  1		 ;AN000; The length of the printer type indicator
SIZE_NAMES		EQU	  E_MAX_PRN_NAME_LEN+LENGTH_FILE_PTR+LENGTH_PRT_TYPE_IND ;AN000; The size of one entry in the names table
NAMES_TABLE_SIZE	EQU	  SIZE_NAMES * MAX_NUM_PRINTER_DEFS	     ;AN000; The size of the names table
MINIMUM_MEMORY		EQU	  NAMES_TABLE_SIZE + MIN_SIZE_FILE_BUFFER		 ;AN000; The minimum amount of memory required

RANGE_ONLY		EQU	  1		 ;AN000; The parser is only to look for ranges of values
RANGE_AND_STRING	EQU	  3		 ;AN000; The parser is to look for ranges and strings

NUMERIC_VALUE		EQU	  08000H	 ;AN000; Parser constant for searching for numeric values
SIMPLE_STRING		EQU	  02000H	 ;AN000; Parser constant for searching for strings


; Control blocks for the parser.
;  The PARMS INPUT BLOCK
PARMS	      LABEL	BYTE	   ;AN000;
    PAR_EXTEN	   DW	OFFSET PARMSX	 ;AN000; Offset of the PARMS EXTENSION BLOCK
    PAR_NUM	   DB	2		 ;AN000; The number of further definitions
		   DB	0	      ;AN000;
		   DB	1	      ;AN000;
		   DB	1AH	      ;AN000;

; The PARMS EXTENSION BLOCK
PARMSX	      LABEL	BYTE;AN000;
    PAX_MINP	   DB	0  ;AN000;
    PAX_MAXP	   DB	1  ;AN000;
		   DW	CONTROL_P1    ;AN000;
    PAX_MAX_SW	   DB	0;AN000;
    PAX_MAX_K1	   DB	0;AN000;

; The control blocks for the definition of positional parameters, switch and
; keywords.
CONTROL_P1    EQU  $  ;AN000;
CTL_FUNC_FL	   DW	2000H;AN000;
		   DW	0002H	      ;AN000;
		   DW	RESULT_P1     ;AN000;
		   DW	VALUE_LIST_P1 ;AN000;
		   DB	0	      ;AN000;

VALUE_LIST_P1	   EQU	$;AN000;
VAL_NUM 	   DB	1	  ;AN000; Number of value definitions
		   DB	1	  ;AN000; Number of range definitions
		   DB	8	  ;AN000; Return value if parameter is in this range
		   DD	0   ;AN000;
		   DD	255 ;AN000;
		   DB	0	  ;AN000; Number of actual value definitions
NUM_STRINGS	   DB	2	  ;AN000; Number of string definitions
		   DB	1	  ;AN000; Value to be returned if this string is matched
		   DW	OFFSET KEYWORD_PARALLEL;AN000;
		   DB	2	  ;AN000; Value to be returned if this string is matched
		   DW	OFFSET KEYWORD_SERIAL;AN000;

		   DB	3	  ;AN000; Value to be returned if this string is matched
		   DW	OFFSET KEYWORD_MODE;AN000;
		   DB	4	  ;AN000; Value to be returned if this string is matched
		   DW	OFFSET KEYWORD_CODE_DRIVER;AN000;
		   DB	5	  ;AN000; Value to be returned if this string is matched
		   DW	OFFSET KEYWORD_CODE_PREPARE;AN000;
		   DB	6	  ;AN000; Value to be returned if this string is matched
		   DW	OFFSET KEYWORD_GRAPHICS;AN000;

KEYWORD_PARALLEL	DB   'P',0;AN000;
KEYWORD_SERIAL		DB   'S',0;AN000;
KEYWORD_MODE		DB   'SP',0;AN000;
KEYWORD_CODE_DRIVER	DB   'CDP',0;AN000;
KEYWORD_CODE_PREPARE	DB   'CPP',0;AN000;
KEYWORD_GRAPHICS	DB   'GP',0;AN000;

RESULT_P1	   LABEL     BYTE;AN000;
		   DB	0	  ;AN000; Type of operand returned
MATCHED_TAG	   DB	0	  ;AN000; Matched item tag
SYNONYM_PTR	   DW	0	  ;AN000; Offset of synonym returned
RESULT_FIELD	   DB	0,0,0,0   ;AN000; Unsure what this is...


;AD000;JW ;***************************************************************************
;AD000;JW ; Parser control blocks for parsing the mode parameters
;AD000;JW ;***************************************************************************
;AD000;JW MODE_PARMS	LABEL	  BYTE
;AD000;JW		DW   MODE_PARMSX
;AD000;JW		DB   0
;AD000;JW
;AD000;JW MODE_PARMSX	LABEL	  BYTE
;AD000;JW		DB   0,0
;AD000;JW		DB   0
;AD000;JW		DB   1
;AD000;JW		DW   OFFSET CNTL_BAUD
;AD000;JW
;AD000;JW CNTL_BAUD	LABEL	  BYTE
;AD000;JW		DW   SIMPLE_STRING
;AD000;JW		DW   2
;AD000;JW		DW   RESULT_P1
;AD000;JW		DW   MODE_VALUES
;AD000;JW		DB   5
;AD000;JW SYN_BAUD	DB   'BAUD',0
;AD000;JW SYN_PARITY	DB   'PARITY',0
;AD000;JW SYN_DATA	DB   'DATA',0
;AD000;JW SYN_STOP	DB   'STOP',0
;AD000;JW SYN_RETRY	DB   'RETRY',0
;AD000;JW
;AD000;JW MODE_VALUES	LABEL	  BYTE
;AD000;JW		DB	  0


;***************************************************************************
; Parser control blocks for parsing the AUTOEXEC.BAT file for 'SELECT'
;***************************************************************************
SELECT_PARMX  LABEL	BYTE	 ;AN000;
	      DB   1,1		    ;AN000;
	      DW   SELECT_CONTROL   ;AN000;
	      DB   0		    ;AN000;
	      DB   0		    ;AN000;

SELECT_CONTROL	   LABEL     BYTE;AN000;
	      DW   2000H	    ;AN000;
	      DW   2		    ;AN000;
	      DW   RESULT_P1	    ;AN000;
	      DW   SELECT_VALUE     ;AN000;
	      DB   0		    ;AN000;

SELECT_VALUE  LABEL	BYTE	 ;AN000;
	      DB   3		    ;AN000;
	      DB   0		    ;AN000;
	      DB   0		    ;AN000;
	      DB   1		    ;AN000;
	      DB   1		    ;AN000;
	      DW   OFFSET SELECT_STR;AN000;

SELECT_STR    DB   'SELECT',0;AN000;
ALLOC_FLAG    DB   0
ALLOCATED     EQU  80H


DATA	ENDS			;AN000;

CODE_FAR SEGMENT BYTE PUBLIC 'CODE';AN000;

	ASSUME	CS:CODE_FAR, DS:DATA, ES:DATA;AN000;

;***************************************************************************
; Routines for extracting the printer names from the file data and storing
; them in a table located in high memory.  In addition to the name, the
; type of printer, whether Parallel or Serial and the location in the file
; of this printer name is also saved in the table.
;***************************************************************************

;******************************************************************************
;
; Routine:  GET_PRINTER_TITLES_ROUTINE - Reads the names of all the printers
;			      and their location in the file into a data
;			      buffer in high memory.
;
; Input:
;    DI - The offset of name of the file which contains the printer definitions
;	  in ASCII-N format.
;
; Output:
;    If CY = 1: Indicates that an error has occured.
;	  BX - The error code for the error which this subroutine detected.
;	  AX - The error code which was returned if the error was as a result
;	       of a DOS call.
;    If CY = 0: No error has occured.
;	  AX, BX - Undefined.
;
;******************************************************************************
GET_PRINTER_TITLES_ROUTINE   PROC FAR		 ;AN000;
						 ;
    CALL HOOK_INT_24				 ;AN000;
;;  int 3
;;  nop

    PUSH ES					 ;AN000;
    ;**********************************************************************
    ; Allocate the necessary memory for the buffer.  A maximum of 64K is
    ; allocated.
    ;**********************************************************************
    CALL ALLOCATE_MEMORY			 ;AN000; Allocate the memory for the printer data
    .IF < C >					 ;AN000; Was there an error?
	 JMP  EXIT_WITH_ERROR			 ;AN000; If so, exit the subroutine
    .ENDIF					 ;AN000;
    ;**********************************************************************
    ; See if there is enough memory to continue.
    ;**********************************************************************
    .IF < SEGMENT_SIZE B MINIMUM_MEMORY>	 ;AN000; Is there enough memory?
	 MOV  BX, ERR_NOT_ENOUGH_MEM		 ;AN000; No! Return error code.
	 JMP  EXIT_WITH_ERROR			 ;AN000; Exit the subroutine
    .ENDIF					 ;AN000;
    ;**********************************************************************
    ; Set the pointer for the file data buffer and save the size of this buffer.
    ;**********************************************************************
    MOV  BUFFER_START, NAMES_TABLE_SIZE 	 ;AN000; Starting address of the file data buffer
    MOV  BX, SEGMENT_SIZE			 ;AN000; Total amount of memory available
    SUB  BX, NAMES_TABLE_SIZE			 ;AN000; Calculate the size of the file data buffer
    MOV  BUFFER_SIZE, BX			 ;AN000; Save this size.
    MOV  NAMES_OFF, 0				 ;AN000; Offset of the printer names table
    ;**********************************************************************
    ; Open the printer definition file.
    ;**********************************************************************
    MOV  INT_24_ERROR, 0			 ;AN000;
    CALL POS_ZERO				 ;AN000; Turn the ASCII-N string into an ASCII-Z string
    MOV  DX, DI 				 ;AN000; Get address of the ASCII-N string
    ADD  DX, 2					 ;AN000; Address of the filename
    MOV  AX, 3D00H				 ;AN000; Open file for reading.
    DOSCALL					 ;AN000;
    .IF < C >					 ;AN000; Was there an error opening the file?
	 MOV  BX, ERR_OPENING_FILE		 ;AN000; Yes! Return this error code
	 JMP  EXIT_WITH_ERROR			 ;AN000;
    .ENDIF					 ;AN000;
    MOV  FILE_HANDLE, AX			 ;AN000; Save the handle for the file
    ;**********************************************************************
    ; Initialize the variable which holds the file pointer at the beginning
    ; of the buffer.
    ;**********************************************************************
    MOV  WORD PTR FILE_PTR_AT_START, 0		 ;AN000; Zero the low word
    MOV  WORD PTR FILE_PTR_AT_START+2, 0	 ;AN000; Zero the high word
    AND  READ_FLAG, RESET_EOF			 ;AN000; Indicate we are not at EOF
    ;**********************************************************************
    ; Read data into the file buffer.
    ;**********************************************************************
    MOV  DI, BUFFER_START			 ;AN000; Start reading at this offset
    SUB  DI, NAMES_TABLE_SIZE			 ;AN000; Make into an offset in the buffer instead of the segment
    CALL READ_FROM_HERE 			 ;AN000; Read in the data.
    .IF < C >					 ;AN000; Was there an error reading from the file?
	 MOV  BX, ERR_READING_FILE		 ;AN000; Return this error code
	 JMP  EXIT_WITH_ERROR			 ;AN000; Return from this subroutine
    .ENDIF					 ;AN000;
    ;**********************************************************************
    ; Initialize the variables needed for the parsing.
    ;**********************************************************************
    MOV  CURRENT_PARSE_LOC, NAMES_TABLE_SIZE	 ;AN000; Start parsing from the beginning.
    MOV  CX_ORDINAL_VALUE, 0			 ;AN000; The first parse, CX must be zero.
    MOV  N_PRN_NAMES, 0 			 ;AN000; There are not names in the table now
    AND  PARSE_FLAG, RESET_LINE_DONE		 ;AN000; The current line has NOT been parsed
    OR	 PARSE_FLAG, FIRST_PARSE		 ;AN000; Indicate that this is the first parse
    ;**********************************************************************
    ; Setup the control blocks for the parser
    ;**********************************************************************
    MOV   PAR_EXTEN, OFFSET PARMSX		 ;AN000; Load the address of the parse extention block
    ;**********************************************************************
    ; Parse the data.  If this is the first parse, then look for the number
    ; of printer definitions.  If it is not, then look for the parameters
    ; P and S which preface the printer names.
    ;**********************************************************************
    MOV  VAL_NUM, RANGE_ONLY			 ;AN000; Parse for a range of values only
    MOV  CTL_FUNC_FL, NUMERIC_VALUE		 ;AN000; Indicate we are looking for numbers
    MOV  NUM_STRINGS, 2 			 ;AN000; The number of parameters to look for
    ;**********************************************************************
    ; See if there is a complete line in the remainder of the buffer.  If there
    ; is not, then read more data into the buffer starting with the start of
    ; the current line.
    ;**********************************************************************
PARSE_NEXT_LINE:				 ;AN000;
    CALL SEARCH_LINE				 ;AN000; Search for the first parameter on the line
    .IF < C >					 ;AN000; Was there an error?
	 JMP  EXIT_WITH_ERROR			 ;AN000; Yes! Exit the routine
    .ENDIF					 ;AN000;
    .IF < BIT PARSE_FLAG AND FIRST_PARSE >	 ;AN000; Looking for a value or a string?
	 .IF < AX NE 0 >			 ;AN000; Was there an error?
	      MOV  BX, ERR_FINDING_VALUE	 ;AN000; Yes! Return with this error code
	      JMP  EXIT_WITH_ERROR		 ;AN000;
	 .ENDIF 				 ;AN000;
	 MOV  AL, RESULT_FIELD			 ;AN000; Get the low order byte of the value
	 MOV  NUM_PRINTER_DEFS, AL		 ;AN000; Store the number of definitions
	 AND  PARSE_FLAG, RESET_FIRST_PARSE	 ;AN000; Indicate the first parse is finished
	 MOV  VAL_NUM, RANGE_AND_STRING 	 ;AN000; Specify strings and ranges
	 MOV  CTL_FUNC_FL, SIMPLE_STRING	 ;AN000; Look for specific strings only.
    .ENDIF					 ;AN000;
    ;**********************************************************************
    ; See if we found a printer name
    ;**********************************************************************
    .IF < AX EQ 0 >				 ;AN000; Was an error found parsing the buffer
	 .IF < N_PRN_NAMES AE MAX_NUM_PRINTER_DEFS >	 ;AN000; Are there more the 255 printer defs?
	      MOV  BX, ERR_TOO_MANY_DEFS	 ;AN000; If so, return this error.
	      JMP  EXIT_WITH_ERROR		 ;AN000; Terminate the subroutine.
	 .ENDIF 		     ;AN000;
						 ; DX contains the address of the result block
	 CALL COPY_PRINTER_NAME 		 ;AN000; Copy the name to the table
	 .IF < C >				 ;AN000; Was there an error?
	      MOV  BX, ERR_FINDING_NAME 	 ;AN000; Yes! Return this error code
	      JMP  EXIT_WITH_ERROR		 ;AN000;
	 .ENDIF 				 ;AN000;
    .ENDIF					 ;AN000;
    ;**********************************************************************
    ; Start scanning the next line.
    ;**********************************************************************
    MOV  DI, START_NEXT_LINE			 ;AN000; Get the address of the next line to parse
    MOV  CURRENT_PARSE_LOC, DI			 ;AN000; Save it
    .IF < CURRENT_PARSE_LOC EQ 0 >		 ;AN000; Is there more data?
	 JMP  EXIT_WITHOUT_ERROR		 ;AN000; No! Exit the routine
    .ENDIF		    ;AN000;
    JMP  PARSE_NEXT_LINE			 ;AN000; Start processing this line
						 ;
EXIT_WITH_ERROR:				 ;AN000;
    STC 					 ;AN000; Set the carry flag, indicating error.
    JMP  EXIT_ROUTINE				 ;AN000;
EXIT_WITHOUT_ERROR:				 ;AN000;
    MOV  CX, N_PRN_NAMES			 ;AN000; The number of entries in the table
    .IF < CL NE NUM_PRINTER_DEFS >		 ;AN000; Did the number of definitions agree with the expected number?
	 MOV  BX, ERR_NUMBER_MATCH		 ;AN000; Return this error message
	 JMP  EXIT_WITH_ERROR			 ;AN000; Return, setting the carry flag.
    .ENDIF		  ;AN000;
    CLC 					 ;AN000; Clear the carry flag - No error.
EXIT_ROUTINE:					 ;AN000;
    CALL DEALLOCATE_MEMORY
    POP  ES					 ;AN000;
    CALL RESTORE_INT_24;AN000;
    RET 					 ;AN000;
						 ;
GET_PRINTER_TITLES_ROUTINE   ENDP		 ;AN000;
;********************************************************************************
;
;SEARCH_LINE: Search for the first parameter on a line.
;
;INPUT:
;    None.
;
;OUTPUT:
;    AX - Contains the return codes from the parser
;    If CY = 1: There was an error - BX contains an error code
;    if CY = 0: There were NO errors.
;    All the registers are set from the parser return.
;
;OPERATION:
;
;********************************************************************************
SEARCH_LINE   PROC NEAR 	    ;AN000;

    MOV  DI, CURRENT_PARSE_LOC			 ;AN000; Get the current location in the buffer
    CALL SCAN_FOR_EOLN				 ;AN000; Search for the end of the line
    MOV  START_NEXT_LINE, DI			 ;AN000; Save the start address of the next line
    .IF < C >					 ;AN000; Was the END OF LINE found?
	 .IF <BIT READ_FLAG AND AT_EOF> 	 ;AN000; Are we at the end of the file?
	      MOV  START_NEXT_LINE, 0		 ;AN000; Yes!  Indicate that this is the last line
	 .ELSE					 ;AN000; We are not the the end of the file
	      MOV  DI, CURRENT_PARSE_LOC	 ;AN000; The location to read from in the file
	      SUB  DI, NAMES_TABLE_SIZE 	 ;AN000; Make into an offset in the buffer instead of the segment
	      CALL READ_FROM_HERE		 ;AN000; Read in more data
	      .IF < C > 			 ;AN000; Was there an error reading from the file?
		   MOV	BX, ERR_READING_FILE	 ;AN000; Return this error code
		   JMP	EXIT_SEARCH_ERROR	 ;AN000; Return from this subroutine
	      .ENDIF				 ;AN000;
	      MOV  CURRENT_PARSE_LOC, NAMES_TABLE_SIZE ;AN000; Start back at the beginning of the buffer
	      MOV  DI, CURRENT_PARSE_LOC	 ;AN000; Get the current parse location again.
	      CALL SCAN_FOR_EOLN		 ;AN000; Once again look for the end of the line
	      MOV  START_NEXT_LINE, DI		 ;AN000; Save the start address of the nest line
	      .IF < C > 			 ;AN000; Was it found?
		   MOV	BX, ERR_LINE_TOO_LONG	 ;AN000; No! Indicate an error.
		   JMP	EXIT_SEARCH_ERROR	 ;AN000; Return with this error
	      .ENDIF				 ;AN000;
	 .ENDIF 				 ;AN000;
    .ENDIF					 ;AN000;
    ;**********************************************************************
    ; Set up the input parameters for the parse subroutine
    ;**********************************************************************
    MOV  DI, OFFSET PARMS			 ;AN000; Offset into ES of the PARMS control block
    MOV  SI, CURRENT_PARSE_LOC			 ;AN000; Where to start parsing
    MOV  DX, 0					 ;AN000;
    MOV  CX, CX_ORDINAL_VALUE			 ;AN000; The value returned by the parse last time.
    PUSH DS					 ;AN000; Save the current data segment
    PUSH ES					 ;AN000; Save the file data segment
    MOV  AX, DATA				 ;AN000; Get the current data segment
    MOV  ES, AX 				 ;AN000; This is the parser control blocks.
    MOV  AX, SEG_LOC			;AN000; Where the data to parse is located
    MOV  DS, AX 				 ;AN000;
    CALL SYSPARSE				 ;AN000; Do the parsing
    POP  ES					 ;AN000; Restore the file data segment
    POP  DS					 ;AN000; Restore the data segment
    CLC 					 ;AN000; Indicate there were no errors
    RET 					 ;AN000;
EXIT_SEARCH_ERROR:				 ;AN000; Here if there were errors
    STC 					 ;AN000; Indicate so to the calling program
    RET 					 ;AN000;

SEARCH_LINE   ENDP;AN000;
;********************************************************************************
; ALLOCATE_MEMORY: Allocate a maximum of 64K of memory.
;
; INPUT:
;    None.
;
; OUTPUT:
;    SEGMENT_SIZE = The size of the segment allocated.
;    SEG_LOC =	The location of the segment allocated.
;    If CY = 1: There was an error - BX contains an error code
;    If CY = 0: There was NO errors.
;
; Operation:
;
;********************************************************************************
ALLOCATE_MEMORY    PROC NEAR;AN000;

    AND  ALLOC_FLAG,NOT ALLOCATED
    MOV  BX, 0FFFH				 ;AN000; Try to allocate this amount of memory
    MOV  SEGMENT_SIZE, BX			 ;AN000; Save the amount of memory asked for
    MOV  AH, 48H				 ;AN000; DOS Fn. for allocating memory
    DOSCALL					 ;AN000; Allocate the memory
    .IF < C >					 ;AN000; Was there an error?
	 MOV  SEGMENT_SIZE, BX			 ;AN000; Save the size asked for in this request
	 MOV  AH, 48H				 ;AN000; DOS Fn. for allocating memory
	 DOSCALL				 ;AN000; Allocate the memory
    .ENDIF					 ;AN000;
    .IF < C >					 ;AN000; Was there an error allocating the memory?
	 MOV  BX, ERR_ALLOCATING_MEM		 ;AN000; Yes! Return an error code
	 STC					 ;AN000; Indicate that there was an error
    .ELSE					 ;AN000; Otherwise...
	 MOV  SEG_LOC, AX		;AN000; Save the location of the memory block allocated
	 MOV  ES, AX				 ;AN000; Save in the extra segment
	 MOV  CL, 4				 ;AN000; Multiply the number of paragraphs by 16
	 SHL  SEGMENT_SIZE, CL			 ;AN000;  to get the number of bytes.
	 OR   ALLOC_FLAG,ALLOCATED
	 CLC					 ;AN000; Indicate there was no error
    .ENDIF					 ;AN000;
    RET 					 ;AN000;

ALLOCATE_MEMORY    ENDP;AN000;


;********************************************************************************
; DEALLOCATE_MEMORY: deallocate memory.
;
; INPUT:
;    SEG_LOC   previously allocated segment
;
; OUTPUT:
;    None.
;
;********************************************************************************
DEALLOCATE_MEMORY PROC NEAR

	   TEST ALLOC_FLAG,ALLOCATED
	   JZ DEM10

	   PUSH ES
	   MOV	AX,SEG_LOC
	   MOV	ES,AX
	   MOV	AH,49H
	   INT	21H
	   POP	ES
DEM10:
	   RET
DEALLOCATE_MEMORY ENDP

;*******************************************************************************
;
; Routine: SCAN_FOR_EOLN - Scan the given string, for CR and LF.
;
; Input:
;    DI - Address of the string to scan for the eoln.
;
; Output:
;    If CY = 0: The end of the line was found.
;	DI - Contains the address of the start of the next line in the buffer.
;	   - If DI = 0, the data ends just after either the CR, LF or the
;	     CR and LF.  Therefore, more data must be read before the next line
;	     can be parsed.
;
;    If CY = 1: The end of the line was not found.
;
;*******************************************************************************
SCAN_FOR_EOLN PROC NEAR;AN000;

    MOV  CX, BUFFER_START			 ;AN000; The offset in the segment of the buffer
    ADD  CX, AMOUNT_OF_DATA			 ;AN000; Get the offset of the end of the data
    SUB  CX, DI 				 ;AN000; Subtract the file data pointer
						 ; CX - Contains the amount of data after pointer
    MOV  AL, 0					 ;AN000; Flag to indicate CR-LF has not been found yet
    .WHILE < CX A 0 >				 ;AN000; Search until the end of the data
	 .IF < <BYTE PTR ES:[DI]> EQ E_FILE_TERM >;AN000;
	      .IF < ZERO AL >	 ;AN000;
		   MOV	END_CUR_LINE, DI	 ;AN000; Save this location in the string
		   DEC	END_CUR_LINE		 ;AN000; Point to the real end of the line
	      .ENDIF	       ;AN000;
	      STC	       ;AN000;
	      MOV  DI, 0       ;AN000;
	      JMP  EXIT_SCAN   ;AN000;
	 .ENDIF 	       ;AN000;
	 .IF < <BYTE PTR ES:[DI]> EQ E_LF > OR	 ;AN000; Is this character a CR or a LF?
	 .IF < <BYTE PTR ES:[DI]> EQ E_CR >	;AN000;
	      .IF < ZERO AL >			 ;AN000; Has a CR or a LF already been found?
		   MOV	END_CUR_LINE, DI	 ;AN000; Save this location in the string
		   DEC	END_CUR_LINE		 ;AN000; Point to the real end of the line
	      .ENDIF	       ;AN000;
	      INC  AL				 ;AN000; Indicate that a CR or a LF has been found
	 .ELSEIF < NONZERO AL > 		 ;AN000; If we have passed the CR-LF,
	      CLC				 ;AN000;  Indicate we have found EOLN
	      JMP  EXIT_SCAN			 ;AN000; Leave the subroutine
	 .ENDIF 		;AN000;
	 DEC  CX				 ;AN000; One less character to the end
	 INC  DI				 ;AN000; Point to the next character
    .ENDWHILE ;AN000;

    .IF < AL AE 2 >				 ;AN000; Does the data run out right after the CR-LF?
	 MOV  DI, 0				 ;AN000; Return 0 indicating so.
    .ENDIF	 ;AN000;
    STC 					 ;AN000; Indicate that the whole line is not there

EXIT_SCAN:    ;AN000;
    RET       ;AN000;

SCAN_FOR_EOLN ENDP;AN000;
;*******************************************************************************
;
; Routine: COPY_PRINTER_NAME - Copy the name of the printer from the file
;		    into the buffer holding all the names.
;
; Input:
;    SI - Contains the address of the start of the printer name.
;    DX - Contains the address of the parse result block
;
; Output:
;    CY = 1: An error has occured.  The name of the printer has not been found.
;    CY = 0: No error.
;
; Operation:   The name from the file buffer is copied to the printer name
;	  table.  Starting from the address passed in DI, the file buffer is
;	  scanned until a valid character is found.  Starting from this point
;	  up to forty characters are transferred to the name table.  If no
;	  name is found, the carry flag is set, and nothing is recorded in the
;	  name table.
;	       After the name is copied, the remainder of the field in the table
;	  is cleared.
;
;*******************************************************************************
COPY_PRINTER_NAME  PROC NEAR;AN000;

    PUSH DS   ;AN000;
    PUSH ES   ;AN000;
    PUSH DX					 ;AN000; Save the address of the result block
    ;**********************************************************************
    ; Calculate the offset into the file data table for this entry
    ;**********************************************************************
    MOV  AX, N_PRN_NAMES		  ;AN000; The next free index into the names table
    MOV  BX, SIZE_NAMES 	     ;AN000; Get the number of bytes per entry
    MUL  BX					 ;AN000; Multiply by the index into the table
    MOV  DI, AX 				 ;AN000; Move the offset into an index register
    ;**********************************************************************
    ; Copy the type of printer first
    ;**********************************************************************
    POP  BX					 ;AN000; Get the result block address
    MOV  AL, DS:[BX+1]				 ;AN000; Get the matched item tag
    .IF < AL EQ 1 >				 ;AN000; Was the parameter a P?
	 MOV  AL, 'P'                            ;AN000; Yes!
    .ELSE					 ;AN000;
	 MOV  AL, 'S'                            ;AN000; No! It was an S
    .ENDIF					 ;AN000;
    MOV  ES:[DI+40], AL 			 ;AN000; Store in the table
    ;**********************************************************************
    ; Skip the spaces between the printer type indicator and the printer name
    ;**********************************************************************
    MOV  AL, 32 				 ;AN000; Character to skip - space
    XCHG SI, DI 				 ;AN000; Point DI to the line being scanned
    MOV  CX, END_CUR_LINE			 ;AN000; Get address of the last char in line
    SUB  CX, DI 				 ;AN000; Subtract start
    INC  CX					 ;AN000; Get the length of the line
    CLD 					 ;AN000; Scan forward
    REPZ  SCASB 				 ;AN000; Repeat search until character found
    JZ	 NAME_NOT_FOUND 			 ;AN000; If all spaces, then it is an error
    INC  CX					 ;AN000; Increment character count
    DEC  DI					 ;AN000; Decrement pointer to character
    ;***********************************************************************
    ; Move the printer name to the names list
    ;***********************************************************************
    XCHG SI, DI 				 ;AN000; Exchange the pointers again
    MOV  CX, END_CUR_LINE			 ;AN000; Get the address of the last char
    SUB  CX, SI 				 ;AN000; Subtract start
    INC  CX					 ;AN000; Get the length of the line
    .IF < CX A E_MAX_PRN_NAME_LEN >		 ;AN000; Is the length of the line too long?
	 MOV  CX, E_MAX_PRN_NAME_LEN		 ;AN000; Yes! Make the line length the maximum size
    .ENDIF					 ;AN000;
    MOV  DX, CX 				 ;AN000; Save the line length for later use
    .WHILE < NONZERO CX >			 ;AN000; Do while there are more characters in the string
	 MOV  AL, BYTE PTR ES:[SI]		 ;AN000; Get a character from the file data
	 .IF < AL NE 32 >			 ;AN000; Is this character a space?
	      MOV  BX, DX			 ;AN000; Get the line length
	      SUB  BX, CX			 ;AN000; Get the length of the line copied so far
	      INC  BX				 ;AN000;
	      .IF < MAX_NAME B BX >	     ;AN000; Is this name longer than the longest so far?
		   MOV	MAX_NAME, BX	     ;AN000; Yes! This is the new maximum
	      .ENDIF		  ;AN000;
	 .ENDIF 		  ;AN000;
	 MOV  BYTE PTR ES:[DI], AL		 ;AN000; Put the character in the names table
	 INC  SI				 ;AN000; Increment string pointers
	 INC  DI     ;AN000;
	 DEC  CX				 ;AN000; Decrement the number of characters left
    .ENDWHILE ;AN000;
    ;***********************************************************************
    ; Fill in the rest of the name area with spaces
    ;***********************************************************************
    MOV  CX, E_MAX_PRN_NAME_LEN 		 ;AN000; The maximum line length
						 ; DX contains the line length from last section
    SUB  CX, DX 				 ;AN000; Calculate the space left in the line
    MOV  AL, 32 				 ;AN000; Character to store
    REP  STOSB					 ;AN000; Store the blank characters
    ;***********************************************************************
    ; Store the file pointer to this printer name in the name list
    ;***********************************************************************
    INC  DI					 ;AN000; Point DI passed the printer type indicator
    MOV  SI, CURRENT_PARSE_LOC			 ;AN000; Get the start of the current line
    SUB  SI, NAMES_TABLE_SIZE			 ;AN000; Subtract offset of the start of the buffer
    MOV  CX, WORD PTR FILE_PTR_AT_START 	 ;AN000; Get the low order word of the pointer
    MOV  DX, WORD PTR FILE_PTR_AT_START[2]	 ;AN000; Get the high order word
    ADD  CX, SI 				 ;AN000; Add the offset of the start of this line
    ADC  DX, 0					 ;AN000; Add the high word
    MOV  WORD PTR ES:[DI], CX			 ;AN000; Store the low order word in the list
    MOV  WORD PTR ES:[DI+2], DX 		 ;AN000; Store the high order word
    INC  N_PRN_NAMES			  ;AN000; Point to the next free area in the list
    CLC 		 ;AN000;
    JMP  EXIT_COPY	 ;AN000;
NAME_NOT_FOUND: 	 ;AN000;
    STC 		 ;AN000;
EXIT_COPY:		 ;AN000;
    POP  ES		 ;AN000;
    POP  DS		 ;AN000;
    RET 		 ;AN000;

COPY_PRINTER_NAME  ENDP  ;AN000;

;*******************************************************************************
; Routine: READ_FROM_HERE - Read from the file into the buffer starting from
;		    the file position pointed to by CURRENT_PARSE_LOC.
;
; Input:
;    DI - Contains the current parsing location in the buffer.
;
; Output:
;    FILE_PTR_AT_START - Updated for the new data read.
;
; Operation:
;
;*******************************************************************************
READ_FROM_HERE	   PROC NEAR;AN000;
						 ;
    ;**********************************************************************
    ; Update the R/W pointer in the file.
    ;**********************************************************************
    MOV  DX, WORD PTR FILE_PTR_AT_START 	 ;AN000; Get the low order word of the pointer
    MOV  CX, WORD PTR FILE_PTR_AT_START[2]	 ;AN000; Get the high order word of the pointer
    ADD  DX, DI 				 ;AN000; Add the offset of where to start reading
    ADC  CX, 0					 ;AN000; Take care of the carry condition
    MOV  WORD PTR FILE_PTR_AT_START, DX 	 ;AN000; Store the new starting position
    MOV  WORD PTR FILE_PTR_AT_START[2], CX	 ;AN000; Store the high word of pointer
    MOV  INT_24_ERROR, 0			 ;AN000;
    MOV  AX, 4200H				 ;AN000; DOS Function for moving the file pointer
    MOV  BX, FILE_HANDLE			 ;AN000; Load the file handle
    DOSCALL					 ;AN000; Move the file pointer
    .IF < C >					 ;AN000; Was an error encountered?
	 JMP  RETURN_WITH_ERROR 		 ;AN000; Yes! Exit the subroutine.
    .ENDIF					 ;AN000;
    ;**********************************************************************
    ; Read from the file into the data buffer
    ;**********************************************************************
    MOV  CX, BUFFER_SIZE			 ;AN000; Number of bytes to read.  As many as will fit.
    MOV  BX, FILE_HANDLE			 ;AN000; Load the DOS file handle for this file
    MOV  AH, 03FH				 ;AN000; The DOS function to perform
    MOV  DX, BUFFER_START			 ;AN000; The offset of the file data buffer
    MOV  INT_24_ERROR, 0			 ;AN000; Indicate that no critical errors have occured yet
    PUSH DS					 ;AN000; Save the current data segment
    PUSH ES					 ;AN000; Push the file data buffer
    POP  DS					 ;AN000; DS now points to the file data buffer
    DOSCALL					 ;AN000; Read from the file.
    POP  DS					 ;AN000; Restore the original data segment
    ;**********************************************************************
    ; See if the buffer was filled.
    ;**********************************************************************
    MOV  AMOUNT_OF_DATA, AX			 ;AN000; Save the amount of data that was read.
    .IF < AX B BUFFER_SIZE >			 ;AN000; Were less bytes read then we asked for?
	 OR   READ_FLAG, AT_EOF 		 ;AN000; Yes! Indicate that we are at EOF
;	 MOV  DI, AX				 ; Move number of characters into an index pointer
;	 MOV  BYTE PTR ES:[DI+NAMES_TABLE_SIZE], 00   ; Place a terminator at the end
    .ENDIF		    ;AN000;
    CLC 		    ;AN000;
    RET 		    ;AN000;

RETURN_WITH_ERROR:	    ;AN000;
    STC 		    ;AN000;
    RET 		    ;AN000;

READ_FROM_HERE	   ENDP      ;AN000;

;********************************************************************************
; Routines for extracting all the information supplied in the profile for a
; specific printer.  Given the printer number, the location of its definition
; is looked up in the names table.  The file is them parsed for the information.
;********************************************************************************

;******************************************************************************
; GET_PRINTER_INFO_ROUTINE - Get all the information contained in the printer
;	       profile file for the specified printer.
;
; INPUT:
;    AX - The number of the printer to return the information on.  The number
;	  is the index into the names table for this printer.
;
; OUTPUT:
;	If CY = 0, there were no errors.
;	The following variable are updated with the information found in
;	the file:
;	      I_PRINTER
;	      N_PRINTER_TYPE
;	      S_MODE_PARM
;	      S_CP_DRIVER
;	      S_CP_PREPARE
;	      S_GRAPH_PARM
;
;	If CY = 1, There were errors encountered.
;	     BX = An error code indicating the type of error that occured.
;
;		= 3  There was an error reading the file
;		= 7  There was a error accessing the file
;		= 11 A printer definition has either a CDP or a CPP
;		       Prefix, but BOTH were not present.
;		= 12 There was an error in the printer definition.
;		       - A line was found with an invalid prefix
;
;		If the error was a result of a DOS function, then
;		on return, AX will contain the DOS error code.
;
; Operation:
;
; Note:
;   The first printer name has an index of 1.
;
;******************************************************************************
GET_PRINTER_INFO_ROUTINE     PROC FAR;AN000;



    CALL HOOK_INT_24				 ;AN000;



    PUSH ES					 ;AN000; Save the extra segment register
    ;**********************************************************************
    ; Calculate the address of the specifed printer
    ;**********************************************************************
    MOV  I_PRINTER, AX				 ;AN000; Save the printer index
    DEC  AX					 ;AN000; Make the first index a 0
    MOV  BX, SIZE_NAMES 	     ;AN000; Number of bytes in each table entry
    MUL  BX					 ;AN000; Address is returned in AX
    MOV  DI, AX 				 ;AN000; Move the address to an index register
    ;**********************************************************************
    ; Get the file location for this printer name
    ;**********************************************************************
    MOV  AX, SEG_LOC			;AN000; Get the segment where the data is
    MOV  ES, AX 				 ;AN000; Save in a segment register
    MOV  CX, WORD PTR ES:[DI+41]		 ;AN000; Get the low order word of the file location
    MOV  DX, WORD PTR ES:[DI+43]		 ;AN000; Get the high order word of the file location
    ;**********************************************************************
    ; Determine if the information is already in the buffer or do we  have
    ; to read more information from the printer profile.
    ;**********************************************************************
    .IF < DX B <WORD PTR FILE_PTR_AT_START+2>>	 ;AN000; Compare the high order words
	 JMP  READ_MORE_INFORMATION		 ;AN000; Info in buffer is passed where we want.
    .ELSE					 ;AN000;
	 .IF < DX EQ < WORD PTR FILE_PTR_AT_START+2>> AND ;AN000; High words equal so
	 .IF < CX B <WORD PTR FILE_PTR_AT_START>>	  ;AN000; compare the low order words
	      JMP  READ_MORE_INFORMATION	 ;AN000; Info in buffer is passed where we want.
	 .ENDIF 			  ;AN000;
    .ENDIF			   ;AN000;
    MOV  BX, WORD PTR FILE_PTR_AT_START+2	 ;AN000; File location at beginning of buffer
    MOV  SI, WORD PTR FILE_PTR_AT_START 	 ;AN000; Low order word
    ADD  SI, AMOUNT_OF_DATA			 ;AN000; Get the file pointer of the end of the buffer
    ADC  BX, 0					 ;AN000; Add in the high word
    .IF < DX A BX >				 ;AN000; If data we want is further in the file,
	 JMP  READ_MORE_INFORMATION		 ;AN000; Read in more data
    .ELSE		       ;AN000;
	 .IF < DX EQ BX > AND			 ;AN000; If the high words are equal do the
	 .IF < CX A SI >			 ;AN000; comparison on the low order words
	      JMP  READ_MORE_INFORMATION	 ;AN000; Still not there, so read more info
	 .ENDIF 			  ;AN000;
    .ENDIF			   ;AN000;
    MOV  AX, I_PRINTER				 ;AN000; Get the index of this printer name
    .IF < AL EQ NUM_PRINTER_DEFS >		 ;AN000; Is this the last one in the list?
	 .IF < BIT READ_FLAG AND AT_EOF >	 ;AN000; If it is, and all the data has been read, process it
	      JMP  PARSE_HERE		   ;AN000;
	 .ELSE				   ;AN000;
	      JMP  READ_MORE_INFORMATION	 ;AN000; Not EOF, so read in more data just for safety
	 .ENDIF 			  ;AN000;
    .ENDIF			   ;AN000;
    MOV  CX, WORD PTR ES:[DI+SIZE_NAMES+41] ;AN000; Get the pointer to the NEXT printer name
    MOV  DX, WORD PTR ES:[DI+SIZE_NAMES+43] ;AN000; Get the high order word
    .IF < DX A BX >				 ;AN000; See if the next printer name is in the buffer
	 JMP  READ_MORE_INFORMATION		 ;AN000; If not, get more information
    .ELSE		       ;AN000;
	 .IF < DX EQ BX > AND			 ;AN000; If the high order words are equal,
	 .IF < CX A SI >			 ;AN000; Compare the low order.  Is the name there?
	      JMP  READ_MORE_INFORMATION	 ;AN000; If not, read more.
	 .ENDIF 			  ;AN000;
    .ENDIF			   ;AN000;
    JMP  PARSE_HERE				 ;AN000; The necessary info is there, so parse it.
    ;**********************************************************************
    ; The specified printer information is not currently in the buffer.  It
    ; is necessary to read it from the printer profile file.
    ;**********************************************************************
READ_MORE_INFORMATION:				 ;AN000;
    MOV  CX, WORD PTR ES:[DI+43]		 ;AN000; Get the file pointer of this printer name
    MOV  DX, WORD PTR ES:[DI+41]		 ;AN000; Get the low order word of pointer
    MOV  INT_24_ERROR, 0			 ;AN000; Indicate that no critical errors have occured yet
    MOV  AX, 4200H				 ;AN000; DOS Fn. for positioning file pointer
    MOV  BX, FILE_HANDLE			 ;AN000; Get the handle of the file
    DOSCALL					 ;AN000; Position the pointer
    .IF < C >					 ;AN000; If CY = 1, there was an error
	 MOV  BX, ERR_ACCESSING_FILE		 ;AN000; Return this error code
	 JMP  ERROR_EXIT			 ;AN000; Jump to exit routine
    .ENDIF	     ;AN000;
    MOV  WORD PTR FILE_PTR_AT_START, AX 	 ;AN000; Set the new pointer at the beginning of the buffer
    MOV  WORD PTR FILE_PTR_AT_START+2, DX	 ;AN000; Set the high order word
    MOV  AH, 3FH				 ;AN000; DOS Fn. for reading from a file
    MOV  DX, BUFFER_START			 ;AN000; Offset of the start of the data buffer
    MOV  BX, FILE_HANDLE			 ;AN000; Get the file handle
    MOV  CX, BUFFER_SIZE			 ;AN000; Read as many bytes as the buffer will hold
    MOV  INT_24_ERROR, 0			 ;AN000; Indicate that no critical errors have occured yet
    PUSH DS					 ;AN000; Save the current data segment
    PUSH ES					 ;AN000; Push the segment of the data buffer
    POP  DS					 ;AN000; Load DS with the segment where to store the data
    DOSCALL					 ;AN000; Read in the data
    POP  DS					 ;AN000; Restore the data segment
    .IF < C >	 ;AN000;
	 MOV  BX, ERR_READING_FILE;AN000;
	 JMP  ERROR_EXIT;AN000;
    .ENDIF	 ;AN000;
    .IF < AX NE BUFFER_SIZE >			 ;AN000; Were less bytes read then asked for?
	 OR   READ_FLAG, AT_EOF 		 ;AN000; If so, then we are at the end of file
    .ELSE					 ;AN000; Otherwise...
	 AND  READ_FLAG, RESET_EOF		 ;AN000; We are not at end of file
    .ENDIF		      ;AN000;
    MOV  AMOUNT_OF_DATA, AX			 ;AN000; Save the amount of data actually read
    ;**********************************************************************
    ; The printer data is in the data buffer.  Begin to parse the data.
    ;**********************************************************************
PARSE_HERE:		       ;AN000;
    MOV  CDP_FOUND, FALSE      ;AN000;
    MOV  CPP_FOUND, FALSE      ;AN000;
    PUSH DI					 ;AN000; Save the pointer into the names table
    ;**********************************************************************
    ; Load the printer profile fields with defaults.
    ;**********************************************************************
    COPY_STRING    S_MODE_PARM, 40, BLANK_STRING  ;AC000;JW
    COPY_STRING    S_CP_DRIVER, 22, BLANK_STRING  ;AN000;
    COPY_STRING    S_CP_PREPARE, 12, BLANK_STRING ;AN000;
    COPY_STRING    S_GRAPH_PARM, 20, BLANK_STRING ;AN000;
    POP  DI					 ;AN000; Restore the pointer into the names table
    ;**********************************************************************
    ; Get the type of printer.
    ;**********************************************************************
    MOV  AL, ES:[DI+40] 			 ;AN000; Get the printer type - Parallel or Serial from the table
    MOV  N_PRINTER_TYPE, AL			 ;AN000; Save in the appropriate variable
    ;**********************************************************************
    ; Get the offset of the start of this printer definition
    ;**********************************************************************
    MOV  CX, ES:[DI+41] 			 ;AN000; Get the low order word of the file pointer
    MOV  DX, ES:[DI+43] 			 ;AN000; Get the high order word
    SUB  DX, WORD PTR FILE_PTR_AT_START[2]	 ;AN000; Subtract the high order words
    SBB  CX, WORD PTR FILE_PTR_AT_START 	 ;AN000; Subtract the low order words
    ADD  CX, BUFFER_START			 ;AN000; Get the offset of the start of the definition
    MOV  CURRENT_PARSE_LOC, CX			 ;AN000; Save as the scan position
    OR	 PARSE_FLAG, FIRST_NAME    ;AN000;
PARSE_NEXT_PARM:		  ;AN000;
    MOV  DI, CURRENT_PARSE_LOC			 ;AN000; Get the current scan position
    CALL SCAN_FOR_EOLN				 ;AN000; Search for the end of this line
    MOV  START_NEXT_LINE, DI			 ;AN000; Save the position of the start of the next line
    MOV  SI, CURRENT_PARSE_LOC			 ;AN000; The position in the buffer to scan
    MOV  NUM_STRINGS, 6 			 ;AN000; Number of parameters to parse for
    MOV  DI, OFFSET PARMS			 ;AN000; Offset of the parameter blocks
    MOV  DX, 0					 ;AN000; The parser wants DX = 0.
    MOV  CX, 0					 ;AN000; Tell the parser this is the first scan of this line
    PUSH DS					 ;AN000; Save the current data segment
    PUSH ES					 ;AN000; Save the file data segment
    MOV  AX, DATA				 ;AN000; Get the current data segment
    MOV  ES, AX 				 ;AN000; This is the parser control blocks.
    MOV  AX, SEG_LOC				 ;AN000; Where the data to parse is located
    MOV  DS, AX 				 ;AN000;
    CALL SYSPARSE				 ;AN000; Do the parsing
    POP  ES					 ;AN000; Restore the file data segment
    POP  DS					 ;AN000; Restore the data segment
    .IF < AX EQ 0FFFFH >			 ;AN000; Was the end of the line found?
	 JMP  UPDATE_PARSE_PTR			 ;AN000; If so, start the next one
    .ELSEIF < NONZERO AX >			 ;AN000; Was an error encountered parsing the line?
	 MOV  BX, ERR_PRN_DEFN	     ;AN000;
	 JMP  ERROR_EXIT			 ;AN000; If so, exit the subroutine
    .ENDIF	     ;AN000;
    MOV  AL, MATCHED_TAG			 ;AN000; Get which string was matched
    .IF < AL EQ 1 > OR				 ;AN000; Was this a printer name and type?
    .IF < AL EQ 2 >	   ;AN000;
	 .IF < BIT PARSE_FLAG AND FIRST_NAME >	 ;AN000; Is this the first name encountered?
	      AND  PARSE_FLAG, RESET_FIRST_NAME  ;AN000; Indicate that the a name has been found
	 .ELSE					 ;AN000; Otherwise...
	      JMP  PARSING_DONE 		 ;AN000; This is the second name.  We are finished.
	 .ENDIF 		   ;AN000;
    .ELSEIF < AL EQ 3 > 			 ;AN000; AL = 3 ==> Mode parameters
	 CALL HANDLE_MODE			 ;AN000; Process
    .ELSEIF < AL EQ 4 > 			 ;AN000; AL = 4 ==> Code page driver parameters
	 MOV  CDP_FOUND, TRUE	   ;AN000;
	 CALL HANDLE_CODE_DRIVER		 ;AN000; Process
    .ELSEIF < AL EQ 5 > 			 ;AN000; AL = 5 ==> Code page preparation parameters
	 MOV  CPP_FOUND, TRUE	   ;AN000;
	 CALL HANDLE_CODE_PREPARE		 ;AN000; Process
    .ELSEIF < AL EQ 6 > 			 ;AN000; AL = 6 ==> Graphics parameters
	 CALL HANDLE_GRAPHICS			 ;AN000; Process
    .ENDIF		  ;AN000;
    ;**********************************************************************
    ; The current line has been parsed.  Point to the next line.
    ;**********************************************************************
UPDATE_PARSE_PTR:	  ;AN000;
    MOV  AX, START_NEXT_LINE			 ;AN000; Get the address of the start of the next line
    MOV  CURRENT_PARSE_LOC, AX			 ;AN000; Save this as the start of the current line
    .IF < CURRENT_PARSE_LOC EQ 0 >		 ;AN000; Is there any more data?
	 JMP  PARSING_DONE			 ;AN000; No. Exit the routine
    .ENDIF					 ;AN000;
    JMP  PARSE_NEXT_PARM			 ;AN000; Start the parsing again
    ;**********************************************************************
    ; The subroutine is finished.
    ;**********************************************************************
PARSING_DONE:		    ;AN000;
    MOV  AL, CDP_FOUND	    ;AN000;
    XOR  AL, CPP_FOUND	    ;AN000;
    .IF < NZ >		    ;AN000;
	 MOV  BX, ERR_CDP_CPP	   ;AN000;
	 JMP  ERROR_EXIT	   ;AN000;
    .ENDIF		    ;AN000;
    CLC 					 ;AN000; Clear the carry - No errors
    JMP  EXIT_INFO				 ;AN000; Exit the subroutine
ERROR_EXIT:	       ;AN000;
    STC 					 ;AN000; Set the carry - There were errors
EXIT_INFO:    ;AN000;
    POP  ES					 ;AN000; Restore the extra segment
    CALL RESTORE_INT_24;AN000;
    RET 					 ;AN000; return

GET_PRINTER_INFO_ROUTINE     ENDP;AN000;
;********************************************************************************
; HANDLE_MODE - Subroutine to process the mode parameter line in the printer
;    profile.
;
; INPUT:
;    SI - Points to the beginning of the line to process
;
; OUTPUT:
;    S_MODE_PARM - Filled with the information from the line.  The line will be
;	  in a format for use as the parameters for the MODE command.
;
;********************************************************************************
HANDLE_MODE   PROC NEAR;AN000;

;AD000;JW     PUSH SI
;AD000;JW     COPY_STRING    S_MODE_PARM, 13, BLANK_MODE
;AD000;JW     POP  SI
;AD000;JW
;AD000;JW NEXT_MODE_SCAN:				   ; Scan for the next keyword.
;AD000;JW     MOV  DI, OFFSET MODE_PARMS		   ; Offset of the control blocks for parsing the mode parameters
;AD000;JW     MOV  CX, 0				   ; Always tell the parser this is the first parse
;AD000;JW     MOV  DX, 0				   ; The parse wants DX = 0
;AD000;JW     PUSH ES					   ; Save the segment registers
;AD000;JW     PUSH DS
;AD000;JW     MOV  AX, DATA				   ; Get the location of the data segment
;AD000;JW     MOV  ES, AX				   ; Load in the extra segment register - The segment of the control blocks
;AD000;JW     MOV  AX, SEG_LOC				   ; Get the location of the printer data
;AD000;JW     MOV  DS, AX				   ; Load into the data segment - The segment of the data to parse
;AD000;JW     CALL SYSPARSE				   ; Parse the line.
;AD000;JW     POP  DS					   ; Restore the segment registers
;AD000;JW     POP  ES
;AD000;JW
;AD000;JW ;   PUSHH	<AX,BX,CX,DX,SI,DI>
;AD000;JW ;   MOV  W_VALUE, AX
;AD000;JW ;   WORD_TO_CHAR   W_VALUE, STRING_N
;AD000;JW ;   PRINTN	STRING_N
;AD000;JW ;   CR_LF
;AD000;JW ;   POPP	<DI,SI,DX,CX,BX,AX>
;AD000;JW
;AD000;JW     .IF < NONZERO AX >			   ; If errors or the end of the line, end the routine
;AD000;JW	   JMP	EXIT_MODE_SCAN
;AD000;JW     .ENDIF
;AD000;JW     MOV  BX, DX				   ; Move result pointer into an index register
;AD000;JW     .IF <<WORD PTR [BX+2]> EQ <OFFSET SYN_BAUD>>	     ; Was this the BAUD keyword?
;AD000;JW	   MOV	AX, 5				   ; Maximum number of character to copy
;AD000;JW	   MOV	DI, OFFSET S_MODE_PARM+2	   ; Where to put the baud parameters
;AD000;JW     .ELSEIF <<WORD PTR [BX+2]> EQ <OFFSET SYN_PARITY>>     ; Was this the PARITY keyword?
;AD000;JW	   MOV	AX, 1				   ; Maximum number of character to copy
;AD000;JW	   MOV	DI, OFFSET S_MODE_PARM+8	   ; Where to put the parity parameters
;AD000;JW     .ELSEIF <<WORD PTR [BX+2]> EQ <OFFSET SYN_DATA>>	     ; Was this the DATA keyword?
;AD000;JW	   MOV	AX, 1				   ; Maximum number of character to copy
;AD000;JW	   MOV	DI, OFFSET S_MODE_PARM+10	   ; Where to put the data parameters
;AD000;JW     .ELSEIF <<WORD PTR [BX+2]> EQ <OFFSET SYN_STOP>>	     ; Was this the STOP keyword?
;AD000;JW	   MOV	AX, 1				   ; Maximum number of character to copy
;AD000;JW	   MOV	DI, OFFSET S_MODE_PARM+12	   ; Where to put the stop parameters
;AD000;JW     .ELSEIF <<WORD PTR [BX+2]> EQ <OFFSET SYN_RETRY>>      ; Was this the RETRY keyword?
;AD000;JW	   MOV	AX, 1				   ; Maximum number of character to copy
;AD000;JW	   MOV	DI, OFFSET S_MODE_PARM+14	   ; Where to put the retry parameters
;AD000;JW     .ENDIF
;AD000;JW     CALL COPY_RESULT				   ; Copy the string
;AD000;JW     JMP  NEXT_MODE_SCAN			   ; Scan for the next keyword
;AD000;JW EXIT_MODE_SCAN:
;AD000;JW     CALL REMOVE_BLANKS			   ; Remove the blanks from the mode line
;AD000;JW

    MOV  DI, OFFSET S_MODE_PARM 		 ;AN000; Offset of the variable to load     JW
    MOV  CX, 40 				 ;AN000; Maximum width of the field		    JW
    CALL COPY_LINE				 ;AN000; Copy the information from the file data  JW
    RET 					 ;AN000; Return 			    JW

HANDLE_MODE   ENDP;AN000;
;AD000;JW ;********************************************************************************
;AD000;JW ; REMOVE_BLANKS: Remove the blanks from the S_MODE_PARM string.  Any trailing
;AD000;JW ;    commas are also removed.
;AD000;JW ;
;AD000;JW ; INPUT:
;AD000;JW ;    None.
;AD000;JW ;
;AD000;JW ; OUTPUT:
;AD000;JW ;    None.
;AD000;JW ;
;AD000;JW ; OPERATION:
;AD000;JW ;
;AD000;JW ;
;AD000;JW ;********************************************************************************
;AD000;JW REMOVE_BLANKS PROC NEAR
;AD000;JW
;AD000;JW     MOV  CX, WORD PTR S_MODE_PARM
;AD000;JW     LEA  SI, S_MODE_PARM
;AD000;JW     INC  SI
;AD000;JW     ADD  SI, CX
;AD000;JW     MOV  BX, CX
;AD000;JW     .WHILE < CX AE 0 >
;AD000;JW	   .IF < <BYTE PTR [SI]> EQ <' '> > OR
;AD000;JW	   .IF < <BYTE PTR [SI]> EQ <','> >
;AD000;JW		DEC  BX
;AD000;JW	   .ELSE
;AD000;JW		.LEAVE
;AD000;JW	   .ENDIF
;AD000;JW	   DEC	SI
;AD000;JW	   DEC	CX
;AD000;JW     .ENDWHILE
;AD000;JW     MOV  WORD PTR S_MODE_PARM, BX
;AD000;JW
;AD000;JW     MOV  CX, BX
;AD000;JW     LEA  SI, S_MODE_PARM
;AD000;JW     ADD  SI, 2
;AD000;JW     MOV  DI, SI
;AD000;JW     .WHILE < CX A 0 >
;AD000;JW	   .IF < <BYTE PTR [SI]> NE <' '>>
;AD000;JW		.IF < SI NE DI >
;AD000;JW		     MOV  AL, [SI]
;AD000;JW		     MOV  [DI], AL
;AD000;JW		.ENDIF
;AD000;JW		INC  DI
;AD000;JW	   .ELSE
;AD000;JW		DEC  BX
;AD000;JW	   .ENDIF
;AD000;JW	   INC	SI
;AD000;JW	   DEC	CX
;AD000;JW     .ENDWHILE
;AD000;JW     MOV  WORD PTR S_MODE_PARM, BX
;AD000;JW     RET
;AD000;JW
;AD000;JW REMOVE_BLANKS ENDP
;********************************************************************************
; HANDLE_CODE_DRIVER - Subroutine to process the code page driver parameter
;    line in the printer profile.
;
; INPUT:
;    SI - Points to the beginning of the line to process
;
; OUTPUT:
;    S_CP_DRIVER - Filled with the information from the line.
;
; OPERATION: The line from the file is copied to the S_CP_DRIVER variable.
;    This variable is assumed to be a maximum of 22 characters wide.
;
;********************************************************************************
HANDLE_CODE_DRIVER PROC NEAR;AN000;

    MOV  DI, OFFSET S_CP_DRIVER 		 ;AN000; Offset of the variable to load
    MOV  CX, 22 				 ;AN000; Maximum width of the field
    CALL COPY_LINE				 ;AN000; Copy the information from the file data
    RET 	       ;AN000;

HANDLE_CODE_DRIVER ENDP;AN000;

;********************************************************************************
; HANDLE_CODE_PREPARE - Subroutine to process the code prepare parameter line
;    in the printer profile.
;
; INPUT:
;    SI - Points to the beginning of the line to process
;
; OUTPUT:
;    S_CP_PREPARE - Filled with the information from the line.
;
; OPERATION: The line from the file is copied to the variable S_CP_PREPARE.
;    The variable is assumed to be a maximum of 12 characters long.
;
;********************************************************************************
HANDLE_CODE_PREPARE	PROC NEAR;AN000;

    MOV  DI, OFFSET S_CP_PREPARE		 ;AN000; Offset of the variable to load
    MOV  CX, 12 				 ;AN000; Maximum length of the variable
    CALL COPY_LINE				 ;AN000; Copy the information from the file data
    RET 	       ;AN000;

HANDLE_CODE_PREPARE	ENDP;AN000;

;********************************************************************************
; HANDLE_GRAPHICS - Subroutine to process the graphics parameter line in the
;    printer profile.
;
; INPUT:
;    SI - Points to the beginning of the line to process
;
; OUTPUT:
;    S_GRAPH_PARM - Filled with the information from the line.
;
; OPERATION: The line from the file is copied to the S_GRAPH_PARM variable.
;    The variable is assumed to be a maximum of 20 characters long.
;
;********************************************************************************
HANDLE_GRAPHICS    PROC NEAR;AN000;

    MOV  DI, OFFSET S_GRAPH_PARM		 ;AN000; Offset of the variable to load
    MOV  CX, 20 				 ;AN000; Maximum width of the variable
    CALL COPY_LINE				 ;AN000; Load the variable with the data from the file
    RET 	       ;AN000;

HANDLE_GRAPHICS    ENDP;AN000;

;********************************************************************************
; COPY_RESULT: Copy the string pointed to in the result block to the specified
;    destination.
;
; INPUT:
;    AX - The maximum length of the string to copy.
;    DX - The offset in DS of the result block.
;    DI - The offset of where the string is to be stored
;
;
; OUTPUT:
;    CX - The length of the string copied.
;
; Operation: The string is copied from the result block to the area pointed to
;    by DS:DI.	The string is copied until a null character is encountered.
;
;********************************************************************************
COPY_RESULT   PROC NEAR;AN000;

    PUSH ES	       ;AN000;
    PUSH SI	       ;AN000;
    MOV  BX, DX 				 ;AN000; Put address into an index register
    LES  SI, [BX+4]				 ;AN000; Get the address of the string to copy
    MOV  CX, 0					 ;AN000; Zero the string length indicator
    .WHILE < CX B AX >				 ;AN000; Copy up to the number of character in AX
	 MOV  DL, BYTE PTR ES:[SI]		 ;AN000; Get the first byte
	 .LEAVE < ZERO DL >			 ;AN000; Terminate loop if this is a null char
	 MOV  BYTE PTR [DI], DL 		 ;AN000; Save character in the destination string
	 INC  SI				 ;AN000; Increment source pointer
	 INC  DI				 ;AN000; Increment destination pointer
	 INC  CX				 ;AN000; Increment number of characters moved
    .ENDWHILE ;AN000;
    POP  SI   ;AN000;
    POP  ES   ;AN000;
    RET       ;AN000;

COPY_RESULT   ENDP;AN000;

;********************************************************************************
; COPY_LINE - Copy a line from the printer profile data to a specified area.
;
; INPUT:
;    DI - Points to the location the data is to be copied to.
;    CX - Contains the maximum number of bytes copied.
;
; OUTPUT:
;    None.
;
; OPERATION: The current line being parsed is copied to the specified area.
;    The length of the line is calculated with the use of the variable
;    CUR_END_LINE.  If the lenght of the line is longer then the number passed
;    in CX, then only a portion of the line will be copied.
;
;********************************************************************************
COPY_LINE     PROC NEAR;AN000;


    PUSH SI					 ;AN000; Save the index regiter used by the parser
    PUSH DI					 ;AN000; Save the pointer to the variable to load
    ADD  DI, 2					 ;AN000; Push pointer passed the lenght word
    MOV  AX, END_CUR_LINE			 ;AN000; Get the pointer to the end of this line
    SUB  AX, SI 				 ;AN000; Get the distance to the end
    INC  AX					 ;AN000; Add to get the length of the line
    .IF < AX B CX >				 ;AN000; If length is greater then the maximum allowed,
	 MOV  CX, AX				 ;AN000; use the shorter length
    .ENDIF	  ;AN000;
    PUSH CX					 ;AN000; Save the length used.
    PUSH ES					 ;AN000; Swap the values in the segment registers
    PUSH DS	 ;AN000;
    POP  ES	 ;AN000;
    POP  DS	 ;AN000;
    CLD 					 ;AN000; Move in the forward direction
    REP  MOVSB					 ;AN000; Move the data
    POP  CX					 ;AN000; Restore the line length
    POP  DI					 ;AN000; Restore the pointer to the variable
    MOV  WORD PTR ES:[DI], CX			 ;AN000; Save the length of the string
    POP  SI					 ;AN000; Restore the parser pointer
    PUSH DS					 ;AN000; Swap the segment registers again
    PUSH ES	 ;AN000;
    POP  DS	 ;AN000;
    POP  ES	 ;AN000;
    RET 	 ;AN000;

COPY_LINE     ENDP;AN000;

;********************************************************************************
; Routine to deallocate the memory used for the storage of the printer profile
; data and the table of printer names.	These routines also close the profile
; file.
;********************************************************************************

;********************************************************************************
; RELEASE_PRINTER_INFO_ROUTINE - Close the printer profile file and free the
;	 allocated memory.
;
; INPUT:
;    None.
;
; OUTPUT:
;    If CY = 0, There were no error encountered.
;    If CY = 1, There was an error.
;	 AX = The DOS error code for the deallocate memory function
;
; OPERATION: Closes the printer file and deallocated the memory.
;
;********************************************************************************
RELEASE_PRINTER_INFO_ROUTINE	PROC FAR;AN000;




    CALL HOOK_INT_24				 ;AN000;


    PUSH ES					 ;AN000;
    ;**********************************************************************
    ; Close the printer definition file
    ;**********************************************************************
    MOV  INT_24_ERROR, 0			 ;AN000; Indicate that no critical errors have occured yet
    MOV  BX, FILE_HANDLE			 ;AN000; File handle of the profile file
    MOV  AH, 3EH				 ;AN000; DOS Fn. for closing a file
    DOSCALL					 ;AN000; Close the file
    ;**********************************************************************
    ; Deallocate the memory used for the data buffer
    ;**********************************************************************
    MOV  AX, SEG_LOC				 ;AN000; Location of the data buffer
    MOV  ES, AX 				 ;AN000;
    MOV  AH, 49H				 ;AN000; DOS Fn. for freeing allocated memory
    DOSCALL					 ;AN000; Free the memory
    POP  ES					 ;AN000;
    CALL RESTORE_INT_24;AN000;
    RET 	 ;AN000;

RELEASE_PRINTER_INFO_ROUTINE ENDP;AN000;

;*******************************************************************************
; Routines for changing the SELECT command line in the AUTOEXEC.BAT.
;*******************************************************************************

;********************************************************************************
; CHANGE_AUTOEXEC_ROUTINE: Search a file for a line beginning with SELECT, and
;			   change its parameters.
;
; INPUT:
;    DI - The offset of an ASCII-N string containing the file to search.
;    SI - The offset of an ASCII-N string containing the data to append as
;	  parameters.
;
; OUTPUT:
;    None.
;
; Operation:
;
;********************************************************************************
CHANGE_AUTOEXEC_ROUTINE PROC FAR;AN000;



    TEST SEL_FLG,INSTALLRW			 ;AN000; Is the install
						 ;AN000;    diskette read/write
						 ;AN000;   (has DISKCOPY occurred?)
    JNZ  AUTO_OK				 ;AN000;
    CLC 					 ;AN000; no error
    JMP  AUTO_EXIT_RO				 ;AN000; If not, exit

AUTO_OK:		  ;AN000;
    CALL HOOK_INT_24				 ;AN000;
    PUSH ES					 ;AN000;
    MOV  APPEND_POINTER, SI			 ;AN000; Save the address of the string to be appended
    MOV  FILENAME, DI				 ;AN000; Save the address of the string containing the filename
    ;**********************************************************************
    ; Allocate the memory needed for reading the autoexec file.  A maximum
    ; of 64K is allocated for use.
    ;**********************************************************************
    CALL ALLOCATE_MEMORY			 ;AN000; Allocate the memory needed
    .IF < C >					 ;AN000; Was there an error?
	 JMP  AUTO_EXIT_ERROR			 ;AN000; Yes!  Exit the subroutine
    .ENDIF					 ;AN000;
    MOV  BUFFER_START, 0			 ;AN000; Save the offset of the start of the buffer
    COPY_WORD BUFFER_SIZE, SEGMENT_SIZE 	 ;AN000; Save the size of the buffer
    ;**********************************************************************
    ; Open the input file
    ;**********************************************************************
    MOV  INT_24_ERROR, 0			 ;AN000; Indicate that no critical errors have occured yet
						 ; DI contains the address of the filename
    CALL POS_ZERO				 ;AN000; Make the string into an ASCII-Z string
    MOV  DX, DI 				 ;AN000; Load string offset
    ADD  DX, 2					 ;AN000; Adjust for length word
    MOV  AX, 3D02H				 ;AN000; DOS Fn. for opening a file for reading and writing
    DOSCALL					 ;AN000; Open the file
    .IF < C >					 ;AN000; Was there an error?
	 JMP  AUTO_EXIT_ERROR			 ;AN000; Exit the subroutine
    .ENDIF					 ;AN000;
    MOV  FILE_HANDLE, AX			 ;AN000; Save the file handle
    ;**********************************************************************
    ; Set the file pointer
    ;**********************************************************************
    MOV  WORD PTR FILE_PTR_AT_START[0], 0	 ;AN000; Set the file pointer of the data in the buffer
    MOV  WORD PTR FILE_PTR_AT_START[2], 0	 ;AN000; Set the high word
    MOV  CURRENT_PARSE_LOC, 0			 ;AN000; Set the current parsing location
    AND  READ_FLAG, RESET_EOF			 ;AN000; Indicate that the end of file has not been reached
    ;**********************************************************************
    ; Read data into the buffer
    ;**********************************************************************
    MOV  DI, CURRENT_PARSE_LOC			 ;AN000; Get the current parsing location
    CALL READ_FROM_HERE 			 ;AN000; Read data starting from this position
    .IF < C >					 ;AN000; Was there an error?
	 JMP  AUTO_EXIT_ERROR			 ;AN000; Yes! Exit the subroutine
   .ENDIF					 ;AN000;
    ;**********************************************************************
    ; Setup the control blocks for the parser
    ;**********************************************************************
    MOV   PAR_EXTEN, OFFSET SELECT_PARMX	  ;AN000; Address of the parameters extension block
    ;**********************************************************************
    ; Parse the file for 'SELECT'
    ;**********************************************************************
PARSE_FOR_SELECT:				 ;AN000; Here to parse the line
    CALL SEARCH_LINE				 ;AN000; Parse the line.
    .IF < C >					 ;AN000; Was there an error?
	 JMP  AUTO_EXIT_ERROR			 ;AN000; Yes! Exit the subroutine
    .ENDIF					 ;AN000;
    .IF < AX EQ 0 >				 ;AN000; Did the parser file 'SELECT'?
	 MOV  CURRENT_PARSE_LOC, SI		 ;AN000; Yes!  Save the position after select as parse location
	 MOV  DX, WORD PTR FILE_PTR_AT_START[0];AN000;
	 MOV  CX, WORD PTR FILE_PTR_AT_START[2];AN000;
	 ADD  DX, CURRENT_PARSE_LOC   ;AN000;
	 ADC  CX, 0		      ;AN000;
	 MOV  INT_24_ERROR, 0			 ;AN000; Indicate that no critical errors have occured yet
	 MOV  BX, FILE_HANDLE	 ;AN000;
	 MOV  AX, 4200H 	 ;AN000;
	 DOSCALL		 ;AN000;
	 .IF < C >				 ;AN000; Was there an error writing the data?
	      JMP  AUTO_EXIT_ERROR		 ;AN000; Yes! Exit the subroutine
	 .ENDIF 				 ;AN000;
	 ;*****************************************************************
	 ; Write the select parameters to the file
	 ;*****************************************************************
	 MOV  SI, APPEND_POINTER		 ;AN000; Address of the string to add to the select line
	 MOV  CX, [SI]				 ;AN000; Size of the string
	 MOV  DX, SI				 ;AN000; Get the address again
	 ADD  DX, 2				 ;AN000; Adjust pointer past length word
	 MOV  INT_24_ERROR, 0			 ;AN000; Indicate that no critical errors have occured yet
	 MOV  BX, FILE_HANDLE			 ;AN000; Get the handle for this file
	 MOV  AH, 40H				 ;AN000; DOS Fn. number for writing data
	 DOSCALL				 ;AN000; Write the data
	 ;*****************************************************************
	 ; Write a carrage return and a line feed to the file
	 ;*****************************************************************
	 MOV  INT_24_ERROR, 0			 ;AN000; Indicate that no critical errors have occured yet
	 MOV  DX, OFFSET W_CR_LF		 ;AN000; Address of string to write
	 MOV  CX, E_SIZE_CR_LF			 ;AN000; Size of the string
	 MOV  BX, FILE_HANDLE			 ;AN000; Get the file handle
	 MOV  AH, 40H				 ;AN000; DOS Fn. for writing data
	 DOSCALL				 ;AN000; Write the data
	 ;*****************************************************************
	 ; Truncate the file at the current file position
	 ;*****************************************************************
	 MOV  INT_24_ERROR, 0			 ;AN000; Indicate that no critical errors have occured yet
	 MOV  CX, 0		 ;AN000;
	 MOV  BX, FILE_HANDLE	 ;AN000;
	 MOV  AH, 40H		 ;AN000;
	 DOSCALL		 ;AN000;
	 ;*****************************************************************
	 ; Close the file.
	 ;*****************************************************************
	 CALL RELEASE_PRINTER_INFO_ROUTINE	 ;AN000; Close the original autoexec file
    .ELSE			     ;AN000;
	 ;*****************************************************************
	 ; Parse the next line.
	 ;*****************************************************************
	 MOV  DI, START_NEXT_LINE		 ;AN000; Get the address of the next line
	 MOV  CURRENT_PARSE_LOC, DI		 ;AN000; Save this as the current parse location
	 .IF < CURRENT_PARSE_LOC EQ 0 > 	 ;AN000; If this is zero, then there is no more data
	      JMP  AUTO_EXIT_CLEAR		 ;AN000; Exit the subroutine - No errors
	 .ENDIF 				 ;AN000;
	 JMP  PARSE_FOR_SELECT			 ;AN000; Parse the next line
    .ENDIF					 ;AN000;
    JMP  AUTO_EXIT_CLEAR			 ;AN000; Exit the subroutine - No errors

AUTO_EXIT_ERROR:				 ;AN000; Here if there was an error
    CALL RELEASE_PRINTER_INFO_ROUTINE		 ;AN000; Close the original file
    STC 					 ;AN000; Indicate that there was an error
    JMP  AUTO_EXIT				 ;AN000; Exit the subroutine

AUTO_EXIT_CLEAR:				 ;AN000; Exit here if NO errors.
    CLC 					 ;AN000; Indicate there were no errors
AUTO_EXIT:					 ;AN000; Here to exit
    CALL DEALLOCATE_MEMORY
    POP  ES					 ;AN000; Restore the extra segment
    CALL RESTORE_INT_24;AN000;
AUTO_EXIT_RO:	 ;AN000;
    RET 					 ;AN000;

CHANGE_AUTOEXEC_ROUTINE ENDP;AN000;

CODE_FAR    ENDS;AN000;

END	      ;AN000;
