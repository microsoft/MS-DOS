;***************************************************************************
; Subroutines which are called by the macros in MACROS.INC.
; File: ROUTINES.ASM
;
; This is a stand alone module and is meant to be linked with the calling
; program.
;
;***************************************************************************
.ALPHA						;AN000;
INCLUDE  MAC_EQU.INC				;AN000;
INCLUDE  PAN-LIST.INC				;AN000;
INCLUDE  PANEL.MAC				;AN000;

;**********************************************************************
DATA	SEGMENT BYTE PUBLIC 'DATA'              ;AN000;


NULl_DEVICE		DB	  'nul',0       ;AN000;
CON_DEVICE		DB	  'con',0       ;AN000;

SUB_PROGRAM		DB	  0		;AN000;
			PUBLIC	  EXEC_ERR	;AN000;
EXEC_ERR		DB	  0		;AN000;
FIRST_TRY		DB	  0		;AN000;DT
INT24_STATUS		DB	  0		;AN000;
UNHOOKED		EQU	  0		;AN000;
HOOKED			EQU	  1		;AN000;
			PUBLIC	  EXEC_DEALLOC,EXEC_FDISK ;AN000;
EXEC_DEALLOC		DB	  0		;AN000;DT
EXEC_FDISK		DB	  0		;AN000;DT
EXEC_DEHELP		DB	  0		;AN000;DT

DATA	       ENDS				;AN000; DATA
;**********************************************************************

.XLIST						;AN000;
	INCLUDE STRUC.INC			;AN000;
	INCLUDE MACROS.INC			;AN000;
	INCLUDE VARSTRUC.INC			;AN000;
	INCLUDE EXT.INC 			;AN000;
	EXTRN	EXIT_DOS:FAR			;AN000;
	EXTRN	SYSDISPMSG:FAR			;AN000;
	EXTRN	HANDLE_ERROR_CALL:FAR		;AN000;
	EXTRN	ALLOCATE_MEMORY_CALL:FAR	;AN000;
	EXTRN	DEALLOCATE_MEMORY_CALL:FAR	;AN000;

	EXTRN	INT_23_VECTOR:NEAR		;AN074;SEH ctrl-break
	EXTRN	INT_24_VECTOR:NEAR		;AN000;
	EXTRN	INT_2F_VECTOR:NEAR		;AN000;
	EXTRN	INT_2F_256KB:NEAR		;AN000;
	EXTRN	INT_2F_FORMAT:NEAR		;AN111;JW
	EXTRN	ALLOCATE_HELP:FAR		;AN000;
	EXTRN	DEALLOCATE_HELP:FAR		;AN000;
.LIST						;AN000;

;**********************************************************************
CODE_FAR    SEGMENT PARA PUBLIC 'CODE'          ;AN000; Segment for far routine
	ASSUME	CS:CODE_FAR,DS:DATA		;AN000;
						;
;************************************************************************
;
;   APPEND_STRING:  Append an ASCII-N string to the specified string.
;
;   INPUT:
;	SI - OFFSET NAME_SRC
;	CX - IMMED_MAX
;	DI - OFFSET NAME_DEST
;
;   OUTPUT:
;	None.
;
;   OPERATION:
;
;
;****************************************************************************
PUBLIC	 APPEND_STRING_ROUTINE			;AN000;
APPEND_STRING_ROUTINE	PROC	FAR		;AN000;

	PUSH	ES				;AN000;
	PUSH	DS				;AN000;
	POP	ES				;AN000; ES and DS point to the data segment

	.IF < CX LT <WORD PTR [DI]> >		;AN000;
	   MOV	   [DI], CX			;AN000;
	.ELSE					;AN000;
	   SUB	   CX, [DI]			;AN000; Calculate space for the other string
	   .IF < CX GE <WORD PTR [SI]>> 	;AN000;
	      MOV     CX, [SI]			;AN000; Move the entire string
	   .ENDIF				;AN000;
	   MOV	   AX, [DI]			;AN000; Current size of destination string
	   ADD	   [DI], CX			;AN000; Add in the length of the new string
	   ADD	   DI, AX			;AN000; Add length of string to pointer
	   ADD	   DI, 2			;AN000; Increment to pass first word and last byte
	   ADD	   SI, 2			;AN000; Point source to start of the string
	   CLD					;AN000;
	   REP	   MOVSB			;AN000;
	.ENDIF					;AN000;

	POP	ES				;AN000;

	RET					;AN000;

APPEND_STRING_ROUTINE	ENDP			;AN000;
;************************************************************************
;
;   COPY_ROUTINE - Subroutine to perform the copy string operation.
;
;   INPUT:
;	SI - OFFSET NAME_SRC
;	AX - IMMED_MAX
;	DI - OFFSET NAME_DEST
;
;   OUTPUT:
;	None.
;
;   OPERATION: Copies NAME_SRC1 to NAME_DEST.  If NAME_SRC1 is longer then
;	IMMED_MAX,  then only IMMED_MAX bytes are copied.
;
;****************************************************************************
PUBLIC	 COPY_ROUTINE				;AN000;
COPY_ROUTINE   PROC    FAR			;AN000;

	PUSH	ES				;AN000;
	PUSH	DS				;AN000;
	POP	ES				;AN000; ES and DS point to the data segment

	PUSH	DI				;AN000; Save OFFSET NAME_DEST
	MOV	DX, AX				;AN000; Save IMMED_MAX
	CLD					;AN000; Move strings in the forward direction
	MOV	CX,WORD PTR [SI]		;AN000; Get length of source string
	ADD	SI,2				;AN000; Point SI to start of string
	ADD	DI,2				;AN000; Point DI to start of destination.
	.IF < CX GT AX >			;AN000;
	   MOV	   CX,AX			;AN000; Will not fit so adjust length
	.ENDIF					;AN000;
	SUB	AX,CX				;AN000; Amount of room left.
REP	MOVSB					;AN000; Move the string
	SUB	DX,AX				;AN000; Subtract the amount left over
	POP	SI				;AN000;
	MOV	WORD PTR [SI],DX		;AN000; Store the length of the string

	POP	ES				;AN000;
	RET					;AN000;

COPY_ROUTINE   ENDP				;AN000;
;******************************************************************************
;
;   PUSH_ROUTINE: Routine to do the actual pushing of the screen label
;
;   INPUT:
;	AX - Contains the address of the code for this screen
;
;   OUTPUT:
;	None.
;
;   OPERATION: The screen label address is pushed onto the SELECT stack
;	provided the numher of entries on the stack will not exceed the
;	maximum.  Error will NOT be generated if the function was not
;	successful.
;
;******************************************************************************
PUBLIC	 PUSH_ROUTINE				;AN000;
PUSH_ROUTINE	PROC	FAR			;AN000;

	.IF < STACK_INDEX B STACK_SIZE >	;AN000; Is there any room?
	   MOV	   BL,STACK_INDEX		;AN000; Get the index
	   MOV	   BH, 0			;AN000;
	   MOV	   SELECT_STACK[BX],AX		;AN000; Store the label
	   ADD	   STACK_INDEX,2		;AN000; Point to next free space
	.ENDIF					;AN000;
	RET					;AN000;
PUSH_ROUTINE	ENDP				;AN000;
;******************************************************************************
;
;   POP_ROUTINE: Routine to do the actual poping of the screen label
;
;   INPUT:
;	None.
;
;   OUTPUT:
;	SI contains the address of the screen code.
;
;   OPERATION: The screen label address is poped from the SELECT stack
;	provided there are entries on the stack.  If there are no values
;	on the stack then the address of the EXIT_DOS screen will be
;	returned.
;
;******************************************************************************
PUBLIC	 POP_ROUTINE				;AN000;
POP_ROUTINE    PROC    FAR			;AN000;

	.IF < STACK_INDEX A 0 > 		;AN000; Is there anything on the stack?
	   SUB	   STACK_INDEX,2		;AN000; Point to last item on the stack
	   MOV	   BL,STACK_INDEX		;AN000; Get the index
	   MOV	   BH, 0			;AN000;
	   MOV	   SI,SELECT_STACK[BX]		;AN000; Get the label
	.ELSE					;AN000;
	   MOV	   SI,OFFSET EXIT_DOS		;AN000; EXIT_DOS screen
	.ENDIF					;AN000;
	RET					;AN000;

POP_ROUTINE    ENDP				;AN000;
;************************************************************************
;
;   MAKE_DIR_PATHS_ROUTINE: Create the specified directory including all
;		the specified sub-directories if they do not exist.
;
;   INPUT:
;	BX - Points to an ASCII-N string containing the path to create
;
;   OUTPUT:
;	CY = 0 Success
;	CY = 1 Error - AX will contain an error code.
;
;   OPERATION: The directory pathname is created.
;	If the drive letter and colon are not followed by a '\', then the
;	macro will start creating the directories from the default directory.
;	If they are followed by a '\', then the macro will start at the root.
;	If an error occures, then sub-directories which have been created will
;	be removed.
;
;
;****************************************************************************
PUBLIC	 MAKE_DIR_PATHS_ROUTINE 		;AN000;
MAKE_DIR_PATHS_ROUTINE	PROC	FAR		;AN000;

	PUSH	ES				;AN000;
	PUSH	DS				;AN000;
	POP	ES				;AN000;


	MOV	AH, 1				;AN000; Flag indicating adding or deleting dirs
	MOV	SI, 0				;AN000; End of the first path created
	MOV	DI, BX				;AN000; Offset of the ASCII-N string
	ADD	DI, 5				;AN000; Point to the beginning of the path
	MOV	DX, WORD PTR [BX]		;AN000; Get the length of the string
	MOV	CX, DX				;AN000; Store in another variable as well
	SUB	CX, 3				;AN000; Skip the first 3 characters 'C:\'
	MOV	AL, '\'                         ;AN000; Delimiter to search for
	CLD					;AN000; Start searching in the forward direction


PROCESS_NEXT_DIR:				;AN000;
	CMP	AH, 1				;AN000; Adding or deleting directories?
	JNE	DELETING_DIR_1			;AN000; If adding, then jump
	CMP	CX,0				;AN000; Is the string length zero?
	JNE	LENGTH_NOT_ZERO 		;AN000;
	JMP	NORMAL_EXIT			;AN000;
DELETING_DIR_1: 				;AN000;
	CMP	SI, DI				;AN000; Was this the first DIR created?
	JNE	LENGTH_NOT_ZERO 		;AN000;
	JMP	ERROR_EXIT			;AN000;

LENGTH_NOT_ZERO:				;AN000;
REPNZ	SCASB					;AN000;
	JNZ	STRING_END			;AN000; If not zero, we reached the string end

	INC	CX				;AN000; By adjusting DI, more bytes to the strings end
	CMP	AH,1				;AN000; Adding or deleting
	JNE	DELETING_DIR_2			;AN000;
	DEC	DI				;AN000; Back DI up to point to the '\'
STRING_END:					;AN000;
	MOV	WORD PTR [BX], DX		;AN000; Length of entire string
	SUB	WORD PTR [BX], CX		;AN000; Subtract the amount left in string
	JMP	ADJUST_DONE			;AN000;
DELETING_DIR_2: 				;AN000;
	INC	DI				;AN000; Adjust DI to point to the '\'
	MOV	WORD PTR [BX], CX		;AN000; Length left in string
ADJUST_DONE:					;AN000;

	CMP	AH, 1				;AN000; Adding or deleting directories
	JNE	DELETING_DIR_3			;AN000;
	CMP	SI, 0				;AN000; Created a DIR yet?
	JNE	MAKE_START			;AN000;
	PUSH	AX				;AN000;
;**********************************************************************
	PUSHH	<DX,DI> 			;AN000;

	MOV	DI,BX				;AN000; Get the offset of the string
	CALL	FAR PTR POS_ZERO		;AN000; Make into an ASCII-Z string
	MOV	INT_24_ERROR, 0 		;AN000; Zero the number of critical errors
	MOV	DX,BX				;AN000; Get the start of the string
	ADD	DX, 2				;AN000;
	MOV	AH,3BH				;AN000; DOS function call number
	DOSCALL 				;AN000;

	POPP	<DI,DX> 			;AN000;
;**********************************************************************
	POP	AX				;AN000;
	JNC	DIR_DONE			;AN000;
	MOV	SI, DI				;AN000;
MAKE_START:					;AN000;
	PUSH	AX				;AN000;
;**********************************************************************
	PUSHH	<DX,DI> 			;AN000;
	MOV	DI,BX				;AN000;
	CALL	FAR PTR POS_ZERO		;AN000; position the '0' at the end of the path
	MOV	INT_24_ERROR, 0 		;AN000; Zero the number of critical errors
	MOV	DX,BX				;AN000; advance pointer to beginning of path
	ADD	DX, 2				;AN000;
	MOV	AH,39H				;AN000; make directory interrupt
	DOSCALL 				;AN000; call to DOS interrupt 21
	POPP	<DI,DX> 			;AN000;
;**********************************************************************
	JC	CANNOT_MAKE			;AN000;
	POP	AX				;AN000;
	JMP	DIR_DONE			;AN000;
CANNOT_MAKE:					;AN000;
	POP	CX				;AN000; Pop the previously saved AX value
	PUSH	AX				;AN000; Push the make dir error message
	MOV	AX, '\'                         ;AN000;
	STD					;AN000; Now search in the backward direction
	MOV	CX, WORD PTR [BX]		;AN000;
	JMP	DIR_DONE			;AN000;
DELETING_DIR_3: 				;AN000;
	PUSH	AX				;AN000;
;**********************************************************************
	PUSHH	<DX,DI> 			;AN000;
	MOV	DI,BX				;AN000;
	CALL	FAR PTR POS_ZERO		;AN000; position the '0' at the end of the path
	MOV	INT_24_ERROR, 0 		;AN000; Zero the number of critical errors
	MOV	DX,BX				;AN000; advance pointer to beginning of path
	ADD	DX, 2				;AN000;
	MOV	AH,3AH				;AN000; remove the specified directory
	DOSCALL 				;AN000; call to DOS interrupt 21
	POPP	<DI,DX> 			;AN000;
;**********************************************************************
	JC	ERROR_POP_EXIT			;AN000;
	POP	AX				;AN000;
DIR_DONE:					;AN000;
	MOV	BYTE PTR [DI], '\'              ;AN000; Put the delimiter back
	CMP	CX,0				;AN000;
	JE	NORMAL_EXIT			;AN000; If CX = 0, string ends
	DEC	CX				;AN000;
	CMP	AH,1				;AN000;
	JNE	DELETING_DIR_4			;AN000;
	INC	DI				;AN000;
	JMP	PROCESS_NEXT_DIR		;AN000;
DELETING_DIR_4: 				;AN000;
	DEC	DI				;AN000;
	JMP	PROCESS_NEXT_DIR		;AN000;

ERROR_POP_EXIT: 				;AN000;
	POP	CX				;AN000; Pop the extra value off the stack.
ERROR_EXIT:					;AN000;
	POP	AX				;AN000; Pop the error message number
	STC					;AN000;
	JMP	PATHS_DONE			;AN000;
NORMAL_EXIT:					;AN000;
	CLC					;AN000;

PATHS_DONE:					;AN000;
	MOV	WORD PTR [BX], DX		;AN000; Restore the original path length

	POP	ES				;AN000;

	RET					;AN000;

MAKE_DIR_PATHS_ROUTINE	ENDP			;AN000;
;************************************************************************
;
;   POS_ZERO - Position a zero at the end of an ASCII-N string, making it
;	into an ASCII-Z string.
;
;   INPUT:
;	DI - Points to the string to covert.
;
;   OUTPUT:
;	None.
;
;   OPERATION: An ASCII-N string is converted to an ASCII-Z string.
;
;****************************************************************************
PUBLIC	 POS_ZERO				;AN000;
POS_ZERO	PROC	FAR			;AN000;

	PUSH	AX				;AN000;
	PUSH	DI				;AN000;

	MOV	AX,[DI] 			;AN000; Get the length of the string
	ADD	DI,AX				;AN000; Add the length to the offset
	ADD	DI,2				;AN000; Adjust for the length word
	MOV	BYTE PTR [DI],0 		;AN000; Position the zero after the end.

	POP	DI				;AN000;
	POP	AX				;AN000;

	RET					;AN000;

POS_ZERO	ENDP				;AN000;
;************************************************************************
;
;   BEEP_ROUTINE - Cause the speaker to create a tone of a given frequency
;	and duration.
;
;   INPUT:
;	DI - The frequency of the tone to create.
;	BX - The duration of the tone.
;
;   OUTPUT:
;	None.
;
;   OPERATION: Causes the speaker to produce a tone.
;
;****************************************************************************
PUBLIC	 BEEP_ROUTINE				;AN000;
BEEP_ROUTINE	PROC	FAR			;AN000;

	MOV	AL,0B6H 			;AN000; write timer mode register
	OUT	43H,AL				;AN000;
	MOV	DX,14H				;AN000; timer divisor=
	MOV	AX,4F38H			;AN000;  1331000/frequency
	DIV	DI				;AN000;
	OUT	42H,AL				;AN000; write timer 2 count low byte
	MOV	AL,AH				;AN000;
	OUT	42H,AL				;AN000; write timer 2 count high byte
	IN	AL,61H				;AN000; get current PORT B setting
	MOV	AH,AL				;AN000; and save it in AH
	OR	AL,3				;AN000; turn on speaker
	OUT	61H,AL				;AN000;
B_WAIT: MOV	CX,2801 			;AN000; wait 10 milliseconds
SPKR_ON:LOOP	SPKR_ON 			;AN000;
	DEC	BX				;AN000;
	JNZ	B_WAIT				;AN000; beep until finished
	MOV	AL,AH				;AN000; recover value of port
	OUT	61H,AL				;AN000;
	RET					;AN000;

BEEP_ROUTINE	ENDP				;AN000;
;************************************************************************
;
;   BIN_TO_CHAR_ROUTINE:  Convert a binary number to ASCII format.
;
;   INPUT:
;	AX - The binary number to convert.
;	DI - Pointer to the ASCII-N string to store the result.
;
;   OUTPUT:
;	None.
;
;   OPERATION:	The specified 16 bit numeric variable contents are
;	converted to ASCII and stored in ASCII-N format.  Leading zeros
;	will not be stored.
;
;****************************************************************************
PUBLIC	 BIN_TO_CHAR_ROUTINE			;AN000;
BIN_TO_CHAR_ROUTINE	PROC	FAR		;AN000;

	MOV	SI, DI				;AN000; Copy the string pointer
	ADD	SI, 6				;AN000; Point to the string END
	MOV	CX, 10				;AN000; Number to divide AX by

	.WHILE < NONZERO AX>			;AN000;
	   MOV	   DX, 0			;AN000; Zero the high order word
	   DIV	   CX				;AN000; Divide the binary number
	   ADD	   DL, 48			;AN000; Convert to ASCII
	   MOV	   [SI], DL			;AN000; Store in the string.
	   DEC	   SI				;AN000; Point to the next free string space
	.ENDWHILE				;AN000;
	SUB	SI, DI				;AN000; Get the difference in the pointers
	DEC	SI				;AN000; Adjust for the lenght word
	MOV	WORD PTR [DI], 5		;AN000; Store the number of characters
	SUB	WORD PTR [DI], SI		;AN000; Subtract the number of extra digits
	MOV	CX, WORD PTR [DI]		;AN000;
	MOV	BX, DI				;AN000;
	ADD	BX, 2				;AN000;
	.WHILE < NONZERO CX >			;AN000;
	   COPY_BYTE	[BX],[BX+SI]		;AN000;
	   DEC	   CX				;AN000;
	   INC	   BX				;AN000;
	.ENDWHILE				;AN000;
	RET					;AN000;

BIN_TO_CHAR_ROUTINE	ENDP			;AN000;
;**************************************************************************
;
;   PREPARE_FILE_ROUTINE:  Prepare a file and a buffer for the construction
;	of that file line by line.
;
;   INPUT:
;	BX = The address of an ASCII-N string containing the name of the file
;	     to create.
;
;   OUTPUT:  CY = 0: No error was encountered.
;	     CY = 1: There was an error encountered.
;
;   OPERATION:	A attempt is made to create the file.  If it fails because
;	the file already exists, then the file is opened for writing.
;	The user will then write to the file be calling WRITE_LINE macro.  The
;	data will be temperarily stored in a buffer to limit the actual number
;	of writes to the file.
;
;**************************************************************************
PUBLIC	 PREPARE_FILE_ROUTINE			;AN000;
PREPARE_FILE_ROUTINE	PROC FAR		;AN000;
						;
    ;**********************************************************************
    ; Try to create the file
    ;**********************************************************************
    MOV  DI, BX 				;AN000; Get the address of the file name string
    CALL POS_ZERO				;AN000; Make the ASCII-N string into an ASCII-Z
    MOV  DX, DI 				;AN000; Get the address again
    ADD  DX, 2					;AN000; Pass the length word and point to string
    MOV  N_WRITE_ERR_CODE, 0			;AN000; Indicate there have been no errors yet
    MOV  INT_24_ERROR, 0			;AN000; Zero the number of critical errors
    MOV  CX, 0					;AN000; Attributes to give the file
    MOV  AH, 3CH				;AN000; Function for creating a file
    DOSCALL					;AN000; Create the file
    ;**********************************************************************
    ; See if an error has occured.
    ;**********************************************************************
    .IF < C >					;AN000; Did the DOS fn. return an error?
	 .IF < AX EQ 5 >			;AN000; Was the error ACCESS DENIED?
	      MOV  DX, BX			;AN000; Get the address of the string
	      MOV  INT_24_ERROR, 0		;AN000; Zero the number of critical errors
	      MOV  AX, 3D01H			;AN000; DOS Fn. for opening a file
	      DOSCALL				;AN000;
	      .IF < C > 			;AN000; Was there an error?
		   MOV	N_WRITE_ERR_CODE, AX	;AN000; Save this error code
	      .ENDIF				;AN000;
	 .ELSE					;AN000;
	      MOV  N_WRITE_ERR_CODE, AX 	;AN000;
	 .ENDIF 				;AN000;
    .ENDIF					;AN000;
						;
    .IF < N_WRITE_ERR_CODE NE 0 >		;AN000;
	 STC					;AN000;
    .ELSE					;AN000;
	 MOV  N_WRITE_HANDLE, AX		;AN000;
	 CLC					;AN000;
    .ENDIF					;AN000;
						;
END_PREPARE_FILE:				;AN000;
						;
    RET 					;AN000;
						;
PREPARE_FILE_ROUTINE	ENDP			;AN000;
;**************************************************************************
;
;   WRITE_LINE_ROUTINE:  Write a line to the file being constructed.
;
;   INPUT:
;	BX = The address of an ASCII-N string containing the line to write
;	     to the file.
;
;   OUTPUT:  CY = 0: No error was encountered.
;	     CY = 1: An error was encountered.
;
;   OPERATION:	The line that is passed, has a CR and a LF appended to the
;	end of the line.  The data is then stored in a buffer.	When the
;	buffer is full, the data is written to the disk.
;
;**************************************************************************
PUBLIC	 WRITE_LINE_ROUTINE			;AN000;
WRITE_LINE_ROUTINE PROC FAR			;AN000;


    ; See if there has been an error so far	;
    .IF < N_WRITE_ERR_CODE EQ 0 >		;AN000; Has there been an error?
	 MOV  SI, BX				;AN000; No! Get the string address
	 ADD  SI, WORD PTR [BX] 		;AN000; Get the end of string address
	 ADD  SI, 2				;AN000; Adjust for the length word
	 MOV  BYTE PTR [SI], E_CR		;AN000; Append a carrage return to the string
	 MOV  BYTE PTR [SI+1], E_LF		;AN000; Append a line feed to the string
	 MOV  CX, WORD PTR [BX] 		;AN000; Get the length of the string
	 ADD  CX, 2				;AN000; Increase the string length by two
	 MOV  DX, BX				;AN000; Get the address of the string
	 ADD  DX, 2				;AN000; Adjust pointer for length word
	 MOV  BX, N_WRITE_HANDLE		;AN000; Handle for the already opened file
	 MOV  INT_24_ERROR, 0			;AN000; Zero the number of critical errors
	 MOV  AH, 40H				;AN000; Function call for writing to a file
	 DOSCALL				;AN000; Write the line
	 .IF < C >				;AN000; Was there an error?
	      MOV  N_WRITE_ERR_CODE, AX 	;AN000; Yes! Save the error code
	 .ENDIF 				;AN000;
    .ENDIF					;AN000;
    RET 					;AN000;
						;
WRITE_LINE_ROUTINE ENDP 			;AN000;
;**************************************************************************
;
;   SAVE_FILE_ROUTINE:	Empty the data in the buffer being used to create
;	     the file and then close the file.
;
;   INPUT:
;	BX - The address of the string containing the file name.
;
;   OUTPUT:  CY = 0: No error was encountered.
;	     CY = 1: An error was encountered.
;		     AX will contain the code of the error which occured.
;
;   OPERATION:	The routine will check to see if there is any data left in
;	the buffer.  If there is, the data is written to the file being
;	created.  The file is then closed.  If errors were encountered at
;	anytime during the create process, then the carry flag will be set
;	and the error code will be returned in AX.
;
;**************************************************************************
PUBLIC	 SAVE_FILE_ROUTINE			;AN000;
SAVE_FILE_ROUTINE  PROC FAR			;AN000;
						;
    .IF < N_WRITE_ERR_CODE NE 0 >		;AN000; Has an error been encountered?
	 MOV  DI, BX				;AN000; Yes! Erase the file.
	 CALL POS_ZERO				;AN000; Make string into an ASCII-Z string
	 MOV  INT_24_ERROR, 0			;AN000; Zero the number of critical errors
	 MOV  DX, DI				;AN000; Get the address of the string
	 ADD  DX, 2				;AN000; Advance pointer past length word
	 MOV  AH, 41H				;AN000; DOS function for erasing a file
	 DOSCALL				;AN000; Erase the file
    .ELSE					;AN000; Otherwise, if no error.
	 MOV  BX, N_WRITE_HANDLE		;AN000; Get the file handle
	 MOV  INT_24_ERROR, 0			;AN000; Zero the number of critical errors
	 MOV  AH, 3EH				;AN000; DOS function for closing a file
	 DOSCALL				;AN000; Close the file
	 .IF < C >				;AN000; Error closing the file?
	      MOV  N_WRITE_ERR_CODE, AX 	;AN000; Yes! Save the error code
	 .ENDIF 				;AN000;
    .ENDIF					;AN000;
						;
    MOV  AX, N_WRITE_ERR_CODE			;AN000; Return the error code
    .IF < N_WRITE_ERR_CODE NE 0 >		;AN000; Have errors been encountered?
	 STC					;AN000; Yes! Set the carry flag
    .ELSE					;AN000; No!
	 CLC					;AN000; Clear the carry flag
    .ENDIF					;AN000;
						;
    RET 					;AN000;
						;
SAVE_FILE_ROUTINE  ENDP 			;AN000;
;****************************************************************************
;
;   EXEC_PROGRAM_ROUTINE: Loads another program into memory and begins
;	     execution.
;
;   INPUT:   child	= Name of the program to execute (ASCII-N format)
;	     name_com	= The command line to be passed to parm_block
;	     parm_block = Parameter block for child program.
;	     re_dir	= Flag indicating whether to redirect the output or not.
;			= 1: Redirect the output.
;			= 0: Don't redirect the output.
;
;   OUTPUT:  CY = 0: Successful
;	     CY = 1: Error - AX has the error code.
;
;   OPERATION:	The command line to be passed to the parameter block is
;	copied to the command buffer specified for the parameter block and
;	a carrage return is appended to the end of the buffer.	(The
;	command line length can be zero.
;
;	The segment offsets in the parameter block are defined and DOS
;	function call 29H is performed to set up the default FCB's.
;
;	DOS function call 4Bh is performed to load and execute the
;	specified child program.  The contents of SS and SP are destroyed
;	during the call, so they must be save and restored later.  When the
;	parent program (SELECT) gets control, all available memory is
;	allocated to it.  It is assumed that memory has been freed (Function
;	call 4Ah - FREE_MEM) before invoking this function.
;
;************************************************************************

PUBLIC	 EXEC_PROGRAM_ROUTINE			;AN000;
EXEC_PROGRAM_ROUTINE  PROC FAR			;AN000;
						;
						;
    EX_CHILD	   EQU	     [BP]+12		;AN000; Equates for temporary variables
    EX_NAME_COM    EQU	     [BP]+10		;AN000;
    EX_PARM_BLOCK  EQU	     [BP]+8		;AN000;
    EX_RE_DIR	   EQU	     [BP]+6		;AN000;
						;
    MOV  SUB_PROGRAM, TRUE			;AN000;
						;
    PUSH BP					;AN000; Save base pointer
    MOV  BP, SP 				;AN000; Set up pointer for temp. variables
						;
    PUSH DS					;AN000; Save the segment registers
    PUSH ES					;AN000;
						;
    MOV  AH,2FH 				;AC000;JW
    DOSCALL					;AC000;JW get DTA address
    PUSH ES					;AC000;JW save DTA seg
    PUSH BX					;AC000;JW save DTA off
						;
    PUSH DS					;AN000;
    POP  ES					;AN000; Point ES to the current data segment
						;
    .IF < <WORD PTR EX_RE_DIR> EQ EXEC_DIR >	;AN000;
	 MOV  AH, 3EH				;AN000; Close Stdout
	 MOV  BX, STDOUT			;AN000;
	 DOSCALL				;AN000;
	 MOV  DX, OFFSET NULL_DEVICE		;AN000; Open the NULL device
	 MOV  AX, 3D01H 			;AN000;
	 DOSCALL				;AN000;
	 MOV  AH, 3EH				;AN000; Close Stderr
	 MOV  BX, STDERR			;AN000;
	 DOSCALL				;AN000;
	 MOV  DX, OFFSET NULL_DEVICE		;AN000; Open the NULL device
	 MOV  AX, 3D01H 			;AN000;
	 DOSCALL				;AN000;
    .ENDIF					;AN000;
						;
						;
    MOV  SI, EX_NAME_COM			;AN000; Get the address of the command line
    MOV  CX, WORD PTR [SI]			;AN000; Get the length of the command line
    MOV  BYTE PTR CMD_BUFF, CL			;AN000; Store the lenth of the string
    MOV  DI, OFFSET CMD_BUFF+1			;AN000; Location to place the string
    ADD  SI, 2					;AN000; Adjust pointer for length word
    CLD 					;AN000; Move in the forward direction
    REP  MOVSB					;AN000; Copy the string
    MOV  BYTE PTR [DI], 0DH			;AN000; Place a carriage return at the end.
						;
    MOV  DI, EX_CHILD				;AN000; Get the address of the program name string
    CALL POS_ZERO				;AN000; Turn into an ASCII-Z string
    MOV  SI,EX_PARM_BLOCK			;AN000; Address of the parameters
    MOV  AH,62H 				;AN000; DOS Function number for getting the PSP segment
    DOSCALL					;AN000; Get the current PSP segment
						;
    MOV  [SI]+8, BX				;AN000; Store PSP segment in the parm block
    MOV  [SI]+12, BX				;AN000; These are the FCB segments
    MOV  AX, DATA				;AN000; Get the address of the data segment
    MOV  [SI]+4, AX				;AN000; Segment of the command line
						;
    MOV  ES, BX 				;AN000; ES:DI points to the FCB to load
    MOV  DI, 5CH				;AN000; First FCB to load
    MOV  BX, SI 				;AN000; Move the address of the parm block
    MOV  SI, [BX]+2				;AN000; Get the address of the command line
    INC  SI					;AN000; Skip the length byte
    MOV  AX, 2900H				;AN000; DOS Function for parsing a command line
    DOSCALL					;AN000; Parse the command line
    MOV  AX, 2900H				;AN000;
    MOV  DI, 6CH				;AN000; ES:DI points to the second FCB
    DOSCALL					;AN000; Parse the second filename
						;
;INT 4BH DESTROYS SS,SP 			;
    MOV  WORD PTR SAVE_AREA, SP 		;AN000; Save the stack segment and pointer
    MOV  WORD PTR SAVE_AREA[2], SS		;AN000;
						;
    MOV      FIRST_TRY,TRUE			;AN000;DT initialize variables
    MOV      EXEC_DEALLOC,FALSE 		;AN000;DT
    MOV      EXEC_DEHELP,FALSE			;AN000;DT
						;
    MOV  INT_24_ERROR, 0			;AN000; Zero the number of critical errors
    PUSH DS					;AN000; Save the current data segment
    POP  ES					;AN000; Point ES to the current data segment
    MOV  DX, EX_CHILD				;AN000; Get the string with the name of the sub-program
    ADD  DX, 2					;AN000; Adjust pointer passed length word
    MOV  AX,4B00H				;AN000; DOS Function number of executing a sub-program
    PUSH BX					;AN000;DT
    DOSCALL					;AN000; Fork to the sub-process
    POP  BX					;AN000;DT
    .IF < c >					;AN000;DT
	 MOV	  EXEC_ERR,TRUE 		;AN000;DT
    .ELSE					;AN000;DT
       MOV	EXEC_ERR,FALSE			;AN000;DT
    .ENDIF					;AN000;DT
;RESTORE REGISTERS				;
    MOV  AX,DATA				;AN000; Restore the data register first
    MOV  DS,AX					;AN000; Load the data segment register
    MOV  ES,AX					;AN000;
    CLI 					;AN000; Turn off interrupts while setting SS
    MOV  SS,WORD PTR SAVE_AREA[2]		;AN000; Restore the stack segment and pointer
    MOV  SP,WORD PTR SAVE_AREA			;AN000;
    STI 					;AN000; Turn interrupts on again.
    CALL FAR PTR HOOK_INT_24			;AN000;
						;
    .IF < <WORD PTR EX_RE_DIR> EQ EXEC_DIR >	;AN000; Redirect Stdout?
	 MOV  AH, 3EH				;AN000; Close Stdout.
	 MOV  BX, 1				;AN000;
	 DOSCALL				;AN000;
	 MOV  DX, OFFSET CON_DEVICE		;AN000; Open CON as stdout.
	 MOV  AX, 3D01H 			;AN000;
	 DOSCALL				;AN000;
	 MOV  AH, 3EH				;AN000; Close Stderr.
	 MOV  BX, 2				;AN000;
	 DOSCALL				;AN000;
	 MOV  DX, OFFSET CON_DEVICE		;AN000; Open CON as stdout.
	 MOV  AX, 3D01H 			;AN000;
	 DOSCALL				;AN000;
    .ENDIF					;AN000;
						;
    MOV  AH,1AH 				;AN000;JW
    POP  DX					;AN000;JW get old DTA off
    POP  DS					;AN000;JW get old DTA seg
    DOSCALL					;AN000;JW restore the DTA address
						;
    POP  ES					;AN000; Restore all the registers.
    POP  DS					;AN000;
    POP  BP					;AN000; Restore the base pointer
						;
    MOV  AH, 4DH				;AN000; Get the return code from the sub-process
    DOSCALL					;AN000;
    .IF < AX NE 0 > or				;AN000; SAR;If not zero...
    .IF < EXEC_ERR eq TRUE >			;AN000; SAR
    .THEN					;AN000; SAR
	 MOV  SUB_ERROR,AL			;AN000;
	 STC					;AN000; Indicate there was an error
    .ELSE					;AN000; Otherwise...
	 MOV  SUB_ERROR,0			;AN000;
	 CLC					;AN000; No error.
    .ENDIF					;AN000;
    MOV  SUB_PROGRAM, FALSE			;AN000;
    MOV  EXEC_FDISK, FALSE			;AN000;DT reset FDISK flag
						;
    RET  8					;AN000; Return, popping the parameters.
EXEC_PROGRAM_ROUTINE  ENDP			;AN000;
;************************************************************************
;
;   GET_CNTY_DEF_ROUTINE: Get country, keyboard and codepage for the
;		specified entry from the CTY_TABLE.
;
;   INPUT:
;	BX = 1: Use CTY_TAB_A
;	   = 2: Use CTY_TAB_B
;	AX = index into country list table
;
;   OUTPUT:
;	N_COUNTRY    = Country code
;	N_KYBD_VAL   = 0: Keyboard code is not valid
;		     = 1: Keyboard code is valid
;	S_KEYBOARD   = Keyboard code (ASCII-N format)
;	N_CP_PRI     = Primary code page
;	N_CP_SEC     = Secondary code page
;	N_DESIGNATES = Number of disignates
;	N_CPSW	     = Cpsw status
;	N_CTY_RES    = Reserved
;
;
;   OPERATION:	The country code, keyboard, primary codepage and the
;	seondary codepage from the CTY_TABLE for the specified index is
;	returned as spedified above.
;
;   Note:  Index of the first item is the table is 1.
;
;****************************************************************************
PUBLIC	 GET_CNTY_DEF_ROUTINE			;AN000;
GET_CNTY_DEF_ROUTINE	PROC FAR		;AN000;
						; AX contains the search's start index
    SUB  AX, 1					;AN000; Make the first index 0
    MOV  DX, TYPE CTY_DEF			;AN000; There are 9 bytes per entry
    MUL  DX					;AN000; Calculate the starting offset
    MOV  SI, AX 				;AN000; Move the address into an index reg
						;
    .IF < BX EQ 1 >				;AN000; BX contains which table to search
	 ADD  SI, OFFSET CTY_TAB_A_1		;AN000; Use the first table
    .ELSE					;AN000;
	 ADD  SI, OFFSET CTY_TAB_B_1		;AN000; Use the second table
    .ENDIF					;AN000;
						;
    COPY_WORD	   N_COUNTRY, [SI+0]		;AN000; Get the counrty code
    COPY_BYTE	   N_KYBD_VAL, [SI+2]		;AN000; See if the keyboard is valid
    MOV 	   S_KEYBOARD, 2		;AN000; Length of the keyboard code string
    COPY_WORD	   S_KEYBOARD[2], [SI+3]	;AN000; Get the keyboard code string
    COPY_WORD	   N_CP_PRI, [SI+5]		;AN000; Get the primary code page
    COPY_WORD	   N_CP_SEC, [SI+7]		;AN000; Get the secondary code page
    COPY_WORD	   N_DESIGNATES, [SI+9] 	;AN000; Get the number of designates
    COPY_WORD	   N_CPSW, [SI+11]		;AN000; Get the code page switching status
    COPY_BYTE	   ALT_KYB_ID, [SI+13]		;AN000; Get default alternate keyboard
    COPY_BYTE	   N_CTY_RES, [SI+14]		;AN000; A reserved byte

    COPY_WORD	   I_KYBD_ALT,2 		;AC090;JW
    RET 					;AN000;

GET_CNTY_DEF_ROUTINE	ENDP			;AN000;
;****************************************************************************
;
;   GET_CNTY_INDEX_ROUTINE: Scan CTY_TABLE for the specified country code and
;			return index of country code into the table.
;
;   INPUT:
;	CX = The country code
;
;   OUTPUT:
;	DX = 1: Country code is in table CTY_TAB_A
;	   = 2: Country code is in table CTY_TAB_B
;	BX = The index into the country list.
;
;   OPERATION:	The CTY_TABLE is scanned for the specified country code and
;	the index into the table is returned.
;
;   Note:  The index of the first item in the table is 1.
;
;************************************************************************
PUBLIC	 GET_CNTY_INDEX_ROUTINE 		;AN000;
GET_CNTY_INDEX_ROUTINE	PROC FAR		;AN000;
						;
    MOV  DX, 1					;AN000; Which table to search
    MOV  AH, 0					;AN000; Clear the high byte
    .WHILE < DX LE 2 >				;AN000; Search the TWO tables
	 .IF < DX EQ 1 >			;AN000; Are we searching the first table?
	      MOV     SI, OFFSET CTY_TAB_A_1	;AN000; Yes! Get the offset of the table
	      MOV     AL, CTY_TAB_A		;AN000; Get the number of entries
	 .ELSE					;AN000; Otherwise...
	      MOV     SI, OFFSET CTY_TAB_B_1	;AN000; Get the offset of the second table
	      MOV     AL, CTY_TAB_B		;AN000; Get the number of entries in this table
	 .ENDIF 				;AN000;
	 MOV	 BX, 1				;AN000; Index currently being scaned
						;
						; CX contains the country code.
	 .WHILE < <WORD PTR [SI]> NE CX> AND	;AN000; Search until this code is found
	 .WHILE < BX LE AX >			;AN000; And while there are still table entries
	      INC     BX			;AN000; Increment the index into the table
	      ADD     SI, TYPE CTY_DEF		;AN000; Point to the next table record
	 .ENDWHILE				;AN000;
						;
	 .IF < BX GT AX >			;AN000; Index is finished for this table
	      INC    DX 			;AN000; Examine the next table
	 .ELSE					;AN000;
	      .LEAVE				;AN000; Exit the while loop
	 .ENDIF 				;AN000;
						;
    .ENDWHILE					;AN000;
    RET 					;AN000;
GET_CNTY_INDEX_ROUTINE	ENDP			;AN000;
;****************************************************************************
;
;   GET_KYBD_INDEX_ROUTINE: Scan KYBD_TABLE for the specified keyboard code and
;			return index of keyboard code in the table and the
;			alternate keyboard indicator.
;
;   INPUT:
;	DI = The offset of an ASCII-N string containing the keyboard code.
;
;   OUTPUT:
;	DX = 1: Keyboard is in table KYBD_TAB_A
;	   = 2: Keyboard is in table KYBD_TAB_B
;	BX = The index into keyboard table.
;	AL = 0: No alternate keyboard
;	   = 1: Alternate keyboard present
;
;   OPERATION:	The KYBD_TABLE is scanned for the specifies keyboard code and
;	the index into the table is returned.
;
;   Note:  The index of the first item in the table is 1.
;
;************************************************************************
PUBLIC	 GET_KYBD_INDEX_ROUTINE 		;AN000;
GET_KYBD_INDEX_ROUTINE	PROC FAR		;AN000;
						;
    MOV     BX, 0				;AN000; Zero the table index
    MOV     DX, 1				;AN000; Which table to search
    MOV     AH, 0				;AN000; Clear high byte to use 16-bit value
    .WHILE < DX LE 2 >				;AN000;
	 .IF < DX EQ 1 >			;AN000;
	      MOV     SI, OFFSET KYBD_TAB_A_1	;AN000; Get the offset of the table
	      MOV     AL, KYBD_TAB_A		;AN000; Get the number of entries
	 .ELSE					;AN000;
	      MOV     SI, OFFSET KYBD_TAB_B_1	;AN000; Get the offset of the second table
	      MOV     AL, KYBD_TAB_B		;AN000; Get the number of entries in this table
	 .ENDIF 				;AN000;
	 MOV	 BX, 1				;AN000; Index currently being scaned
						;
	 MOV	 CX, WORD PTR [DI+2]		;AN000; Get the keyboard code
	 .WHILE < <WORD PTR [SI]> NE CX> AND	;AN000;
	 .WHILE < BX LE AX >			;AN000;
	      INC     BX			;AN000;
	      ADD     SI, TYPE KYB_DEF		;AN000;
	 .ENDWHILE				;AN000;
						;
	 .IF < BX GT AX >			;AN000; Index is finished for this table
	     INC    DX				;AN000; Examine the next table
	 .ELSE					;AN000;
	     MOV    AL, BYTE PTR [SI+2] 	;AN000; Get the alternate keyboard flag
	    .LEAVE				;AN000; Exit the while loop
	 .ENDIF 				;AN000;
						;
    .ENDWHILE					;AN000;
    RET 					;AN000;
						;
GET_KYBD_INDEX_ROUTINE	ENDP			;AN000;
;************************************************************************;
;
;   GET_KYBD_ROUTINE: Get the keyboard code and the alternate keyboard
;	indicator from the KYBD_TABLE for the item specified by the index
;	into the keyboard table.
;
;   INPUT:
;	CX = 1: Keyboard code is in table KYBD_TAB_A
;	   = 2: Keyboard code is is table KYBD_TAB_B
;	AX = index into the keyboard table.
;	DI = Address of the keyboard code. (ASCII-N format)
;
;   OUTPUT:
;	AL = 0: No alternate keyboard
;	   = 1: Alternate keyboard present
;
;   OPERATION:	The keyboard code from the KYBD_TABLE for the specified
;	index item is returned.  Also, the alternate keyboard present
;	variable is updated.
;
;   Note: Index of the first item in the table is 1.
;
;****************************************************************************
PUBLIC	 GET_KYBD_ROUTINE			;AN000;
GET_KYBD_ROUTINE   PROC FAR			;AN000;
						; AX contins the search's start index
    SUB  AX, 1					;AN000; Make the first index 0
    MOV  DX, TYPE KYB_DEF			;AN000; There are 3 bytes per entry
    MUL  DX					;AN000; Calculate the offset into the table
    MOV  SI, AX 				;AN000; Move the address into an index reg
    .IF < CX EQ 1>				;AN000; CX Contains which table to search
	 ADD  SI, OFFSET KYBD_TAB_A_1		;AN000;
    .ELSE					;AN000;
	 ADD  SI, OFFSET KYBD_TAB_B_1		;AN000;
    .ENDIF					;AN000;
						;
    MOV 	   WORD PTR [DI], 2		;AN000; Length of the string
    COPY_WORD	   [DI+2], [SI] 		;AN000; Get the keyboard name
    MOV 	   AL, [SI+2]			;AN000; See if there is an alternate keyboard
    RET 					;AN000;
						;
GET_KYBD_ROUTINE   ENDP 			;AN000;
;;************************************************************************
;;
;;   CHK_EX_MEM_ROUTINE:  Check if the system supports expanded memory.
;;
;;   INPUT:
;;	 None.
;;
;;   OUTPUT:
;;	 SI = 0: Expanded memory is NOT supported.
;;	    = 1: Expanded memory is supported.
;;	 BX = 0: XMA card
;;	    = 1: MODEL 80
;;
;;   OPERATION:  A call to the system services (INT 15H, AH = C0H) is performed
;;	 to get the system configuration parameters. (model byte).
;;
;;	 The Personal System/2 Model 80 (model byte = 0F8h) always support
;;	 expanded memory.
;;
;;	 The Personal System/2 Models 50 and 60 (model byte = 0FCh) support
;;	 expanded memory if the CATSKILL 2 is present.	The CATSKILL 2 card has
;;	 the identity number of F7FEh.	F7H is read through the port address
;;	 101h and FEH is read through port 100H
;;
;;	 The PS2 50/60 also support expanded memory if the HOLSTER card is
;;	 is present (id = FEFEh).
;;
;;	 AT's (and some XT's ?) support expanded memory if the CATSKILL 1
;;	 (XMA) card is present.
;;
;;	 All other models do not support expanded memory.
;;
;;************************************************************************
SLOT_SETUP	EQU   08h			;AN000;Mask to put the desired adapter	 @RH2
CARD_ID_LO	EQU   100H			;AN000;PS/2 Adapter card id low and	   @RH2
CARD_ID_HI	EQU   101H			;AN000; high bytes - read only	   @RH2
						;Card IDs read from port 100,101   @RH2
XMAA_CARD_ID	EQU   0FEF7h			;AN000; XMA/A Card ID		   @RH2
HLST_CARD_ID	EQU   0FEFEh			;AN000; HOLSTER card id 		   JW
MODE_REG	EQU   31A7H			;AN000;  Mode register
TTPOINTER	EQU   31A0H			;AN000;  Translate Table Pointer	 (word)
						;
NUM_OF_SLOTS	EQU   8 			;AN000;
						;
PUBLIC	 CHK_EX_MEM_ROUTINE			;AN000;
CHK_EX_MEM_ROUTINE PROC FAR			;AN000;
						;
    PUSH ES					;AN000;
    MOV  AH, 0C0H				;AN000; Function number to get the model byte
    INT  15H					;AN000;
    .IF < AH eq 80H >				;AN000;IF AH = 80H
	 MOV  SI, 0				;AN000;then this is a PC or PCjr.  No Expanded memory
	 MOV  BX, 0				;AN000;JW not a model 80
    .ELSE near					;AN000;
	 .IF < AH ne 086H >			;AN000;If not an old XT or AT
	      MOV  AH, BYTE PTR ES:[BX]+2	;AN000; Get the model byte
	      MOV  AL, BYTE PTR ES:[BX]+3	;AN000; Get the sub-model byte
	 .ENDIF 				;AN000;
	 .IF < AH eq 0F8H>			;AN000; Is this a model 80?
	      MOV  SI, 1			;AN000; Yes! Expanded memory supported
	      MOV  BX, 1			;AN000;JW
	 .ELSEIF < AH eq 0FCH > and		;AN000; Is this a model 50 or 60?
	 .IF < AL eq 04 > or			;AN000;
	 .IF < AL eq 05 >			;AN000;
					;-------------------------------------
					; Search for XMA/A cards	      �
					;-------------------------------------
	      XOR     CX,CX			;AN000;Check all slots starting at 0	 @RH2
	      MOV     BX,0			;AN000;JW say not a model 80
	     .REPEAT				;AN000;
						;
		  MOV	  AL,CL 		;AN000;Enable the specific slot by ORing @RH2
		  OR	  AL,SLOT_SETUP 	;AN000; the slot (bits 0-2) with the	 @RH2
		  OUT	  96H,AL		;AN000; setup flag (bit 3).		   @RH2
						;
		  MOV	  DX,CARD_ID_LO 	;AN000;Read the signature ID of the card @RH2
		  IN	  AL,DX 		;AN000; 				   @RH2
		  XCHG	  AL,AH 		;AN000; 				   @RH2
		  MOV	  DX,CARD_ID_HI 	;AN000; 				   @RH2
		  IN	  AL,DX 		;AN000; 				   @RH2
						;
		  .IF < AX eq XMAA_CARD_ID > or ;AN000;
		  .IF < AX eq HLST_CARD_ID >	;AN000;JW
		       MOV  SI, 1		;AN000; Yes! Expanded memory supported
		       .LEAVE			;AN000;
		  .ENDIF			;AN000;
						;
		  .IF < CL eq NUM_OF_SLOTS >	;AN000;
		       MOV  SI, 0		;AN000; No! Expanded memoory isn't supported
		       .LEAVE			;AN000;
		  .ENDIF			;AN000;
						;
		  INC	  CL			;AN000;Check next adapter slot	@RH2
						;
	      .UNTIL				;AN000;
	      XOR  AX,AX			;AN000;JW
	      OUT  96H,AL			;AN000;JW Reset port to neutral state
						;
	 .ELSE					;AN000; AT or XT
					;-------------------------------------
					; Search for XMA cards		      �
					;-------------------------------------
	      MOV     DX,MODE_REG		;AN000;SAVE CONTENTS OF MODE REG
	      IN      AL,DX			;AN000;
	      PUSH    AX			;AN000;
						;
	      MOV     AX,0AA55H 		;AN000;DATA PATTERN (IN REAL MODE)
						;BE CERTAIN MODE REG GETS
						;REAL MODE
	      MOV     DX,MODE_REG		;AN000;I/O TO MODE REG
	      OUT     DX,AL			;AN000;WRITE PATTERN
	      MOV     DX,TTPOINTER + 1		;AN000;I/O TO TT POINTER (ODD ADDR)
	      XCHG    AL,AH			;AN000;CHRG BUS WITH INVERSE PATTERN
	      OUT     DX,AL			;AN000;WRITE IT
	      MOV     DX,MODE_REG		;AN000;
	      IN      AL,DX			;AN000;READ BACK MODE REG
	      XOR     AL,AH			;AN000;
	      AND     AL,0FH			;AN000;MASK OFF UNUSED BITS
						;ZERO FLAG = 0 IF ERROR
	      POP     AX			;AN000;
	      PUSHF				;AN000;SAVE FLAGS
	      MOV     DX,MODE_REG		;AN000;
	      OUT     DX,AL			;AN000;RESTORE MODE REG TO INITIAL STATE
	      POPF				;AN000;RESTORE FLAGS
	      .IF < z > 			;AN000;
		   MOV SI,1			;AN000;XMA card present
	      .ELSE				;AN000;
		   MOV SI,0			;AN000;no XMA card present
	      .ENDIF				;AN000;
	      MOV     BX,0			;AN000;not a model 80
	 .ENDIF 				;AN000;
    .ENDIF					;AN000;
    POP     ES					;AN000;
    RET 					;AN000;
CHK_EX_MEM_ROUTINE ENDP 			;AN000;
;****************************************************************************
;
;   GET_PRINTER_PARAMS_ROUTINE: Get parameters for specified printer.
;
;   INPUT:
;	AX = The printer number.
;	BX = The number of the port to retrieve the information on.
;		   If var_port = 0, the information that is returned is
;		   that which corresponds to var_prt.
;	   BX = 0 : Get the information on printer number VAR_PRT
;	      = 1 : Get the information for the printer attached to LPT1
;	      = 2 : Get the information for the printer attached to LPT2
;	      = 3 : Get the information for the printer attached to LPT3
;	      = 4 : Get the information for the printer attached to COM1
;	      = 5 : Get the information for the printer attached to COM2
;	      = 6 : Get the information for the printer attached to COM3
;	      = 7 : Get the information for the printer attached to COM4
;
;   OUTPUT:
;	AX = 1: Printer information is valid
;	   = 0: Printer not valid: default values returned
;
;   OPERATION: Printer information for the specified printer is returned.
;	If the specified printer is not defined, default values will be
;	returned.
;	     I_PRINTER	    = Index into printer list (16 bit variable) : default 1
;	     N_PRINTER_TYPE = P: Parallel printer
;			    = S: Serial printer
;	     I_PORT	    = Port number	      (16 bit variable) : default 1
;	     I_REDIRECT     = Redirection port number (16 bit variable) : default 1
;	     S_MODE_PARM    = Mode parameters		  - ASCII-N format
;	     S_CP_DRIVER    = Code page driver parameters - ASCII-N format
;	     S_CP_PREPARE   = Code prepare parameters	  - ASCII-N format
;	     S_GRAPH_PARM   = Graphics parameters	  - ASCII-N format
;
;	The structures of printer information are searched for the one with
;	the same number as specified by AX.  If found, the information
;	in that structure is returned in the variables listed above.
;
;****************************************************************************
PUBLIC	 GET_PRINTER_PARAMS_ROUTINE		;AN000;
GET_PRINTER_PARAMS_ROUTINE   PROC FAR		;AN000;

    .IF < BX NE 0 >				;AN000;
	 DEC  BX				;AN000;
	 MOV  AX, TYPE PRINTER_DEF		;AN000;
	 MUL  BX				;AN000;
	 MOV  SI, AX				;AN000;
	 .IF < PRINTER_TABLES[SI].PRINTER_DATA_VALID EQ 1 > ;AN000;
	      JMP  COPY_INFO			;AN000;
	 .ELSE					;AN000;
	      JMP RETURN_DEFAULTS		;AN000;
	 .ENDIF 				;AN000;
    .ELSE					;AN000;
	 MOV  SI, 0				;AN000; Index into the printer table
	 MOV  BX, 1				;AN000; Which structure is being searched
	 .WHILE < BX BE 7 >			;AN000; Search the seven structures
	      .IF < PRINTER_TABLES[SI].PRINTER_TAB_NUM EQ AX > AND   ;AN000; Does the printer number match?
	      .IF < PRINTER_TABLES[SI].PRINTER_DATA_VALID EQ 1 >     ;AN000; And is this data valid?
		   JMP	COPY_INFO		;AN000;
	      .ENDIF				;AN000;
	      ADD  SI, TYPE PRINTER_DEF 	;AN000; Search the next structure
	      INC  BX				;AN000;
	 .ENDWHILE				;AN000;
RETURN_DEFAULTS:				;AN000;
	 MOV  I_PRINTER, 1			;AN000; Yes! Return the default information
	 MOV  I_PORT, 1 			;AN000;
	 MOV  I_REDIRECT, 1			;AN000;
	 MOV  S_MODE_PARM, 0			;AN000;
	 MOV  S_CP_DRIVER, 0			;AN000;
	 MOV  S_CP_PREPARE, 0			;AN000;
	 MOV  S_GRAPH_PARM, 0			;AN000;
	 MOV  AX, 0				;AN000; Indicate that the default values are being returned
	 JMP  EXIT_GET_PARAMS			;AN000;
    .ENDIF					;AN000;

COPY_INFO:					;AN000;
    COPY_WORD	   I_PRINTER,	     PRINTER_TABLES[SI].PRINTER_INDEX  ;AN000; Copy the data out of the structure
    COPY_BYTE	   N_PRINTER_TYPE,   PRINTER_TABLES[SI].PRINTER_TYPE   ;AN000;
    COPY_WORD	   I_PORT,	     PRINTER_TABLES[SI].PORT_NUMBER    ;AN000;
    COPY_WORD	   I_REDIRECT,	     PRINTER_TABLES[SI].REDIRECTION_PORT ;AN000;
    PUSH SI							    ;AN000;
    COPY_STRING    S_MODE_PARM,  40, PRINTER_TABLES[SI].MODE_PARMS  ;AN000;
    POP  SI							    ;AN000;
    PUSH SI							    ;AN000;
    COPY_STRING    S_CP_DRIVER,  22, PRINTER_TABLES[SI].CODE_DRIVER ;AN000;
    POP  SI							    ;AN000;
    PUSH SI							    ;AN000;
    COPY_STRING    S_CP_PREPARE, 12, PRINTER_TABLES[SI].CODE_PREPARE ;AN000;
    POP  SI							    ;AN000;
    PUSH SI							    ;AN000;
    COPY_STRING    S_GRAPH_PARM, 20, PRINTER_TABLES[SI].GRAPHICS_PARMS ;AN000;
    POP  SI					;AN000;
    MOV  AX, 1					;AN000; Return that the data is valid

EXIT_GET_PARAMS:				;AN000;
    RET 					;AN000;
						;
GET_PRINTER_PARAMS_ROUTINE   ENDP		;AN000;
;****************************************************************************
;
;   SAVE_PRINTER_PARAMS_ROUTINE: Save the printer information in the printer
;	 structures.
;
;   INPUT:
;	AX = The printer number.
;
;   OUTPUT:
;	None.
;
;   OPERATION: Printer information for the specified printer is stored.
;	     I_PRINTER	    = Index into printer list (16 bit variable) : default 1
;	     N_PRINTER_TYPE = P: Parallel printer
;			    = S: Serial printer
;	     I_PORT	    = Port number	      (16 bit variable) : default 1
;	     I_REDIRECT     = Redirection port number (16 bit variable) : default 1
;	     S_MODE_PARM    = Mode parameters		  - ASCII-N format
;	     S_CP_DRIVER    = Code page driver parameters - ASCII-N format
;	     S_CP_PREPARE   = Code prepare parameters	  - ASCII-N format
;	     S_GRAPH_PARM   = Graphics parameters	  - ASCII-N format
;
;	The information is stored in the structures according to the type
;	and port number of this printer.  The first three structures are for
;	LPT1 - LPT3, while the next four are for COM1 - COM2.
;
;****************************************************************************
PUBLIC	 SAVE_PRINTER_PARAMS_ROUTINE		;AN000;
SAVE_PRINTER_PARAMS_ROUTINE  PROC FAR		;AN000;

    PUSH AX					;AN000; Save the printer number
    MOV  AX, TYPE PRINTER_DEF			;AN000; Get the size of each structure
    MOV  SI, I_PORT				;AN000; Get the port number
    .IF < N_PRINTER_TYPE EQ 'S'>                ;AN000; Is this a serial port?
	 ADD  SI, 3				;AN000; Yes! Store in the later 4 structures
    .ENDIF					;AN000;
    DEC  SI					;AN000; Make the first index a 0
    MUL  SI					;AN000; Calculate the address of the structure
    MOV  BX, AX 				;AN000; Put address into an index register
    COPY_WORD	   PRINTER_TABLES[BX].PRINTER_INDEX,	  I_PRINTER	;AN000; Copy the data into the structure
    COPY_BYTE	   PRINTER_TABLES[BX].PRINTER_TYPE,	  N_PRINTER_TYPE;AN000;
    COPY_WORD	   PRINTER_TABLES[BX].PORT_NUMBER,	  I_PORT	;AN000;
    COPY_WORD	   PRINTER_TABLES[BX].REDIRECTION_PORT,   I_REDIRECT	;AN000;
    COPY_STRING    PRINTER_TABLES[BX].MODE_PARMS,     40, S_MODE_PARM	;AC000;JW
    COPY_STRING    PRINTER_TABLES[BX].CODE_DRIVER,    22, S_CP_DRIVER	;AN000;
    COPY_STRING    PRINTER_TABLES[BX].CODE_PREPARE,   12, S_CP_PREPARE	;AN000;
    COPY_STRING    PRINTER_TABLES[BX].GRAPHICS_PARMS, 20, S_GRAPH_PARM	;AN000;
    .IF <I_PORT EQ 1 >							;AN029;
	COPY_STRING   S_GRAPHICS,M_GRAPHICS,S_GRAPH_PARM		;AN029;
    .ENDIF								;AN029;
    POP  AX					;AN000; Restore the printer number
    MOV  PRINTER_TABLES[BX].PRINTER_TAB_NUM, AX ;AN000; Save the number
    MOV  PRINTER_TABLES[BX].PRINTER_DATA_VALID, 1 ;AN000; Indicate that the data is valid

    MOV  SI, 0					;AN000;
    MOV  CX, 1					;AN000;
    .WHILE < CX BE 7 >				;AN000;
	 .IF < PRINTER_TABLES[SI].PRINTER_TAB_NUM EQ AX > AND ;AN000;
	 .IF < SI NE BX >			;AN000;
	      MOV  PRINTER_TABLES[SI].PRINTER_DATA_VALID, 0 ;AN000;
	 .ENDIF 				;AN000;
	 ADD  SI, TYPE PRINTER_DEF		;AN000;
	 INC  CX				;AN000;
    .ENDWHILE					;AN000;

    RET 					;AN000;

SAVE_PRINTER_PARAMS_ROUTINE  ENDP		;AN000;
;****************************************************************************
;
;   DISPLAY_MESSAGE_ROUTINE:  Call the message retriever to display a message.
;
;   INPUT:
;	AX = The number of the message to be displayed. (16 bit value)
;
;   OUTPUT:
;	If CY = 1, there was an error displaying the message.
;	If CY = 0, there were no errors.
;
;   OPERATION:
;
;****************************************************************************
PUBLIC	 DISPLAY_MESSAGE_ROUTINE		;AN000;
DISPLAY_MESSAGE_ROUTINE PROC FAR		;AN000; AX already contains the message number
    MOV  BX, -1 				;AN000; HANDLE -1 ==> USE ONLY DOS FUNCTION 1-12
    MOV  SI, 0					;AN000; SUBSTITUTION LIST
    MOV  CX, 0					;AN000; SUBSTITUTION COUNT
    MOV  DL, 00 				;AN000; DOS INT21H FUNCTION FOR INPUT 0==> NO INPUT
    MOV  DI, 0					;AN000; INPUT BUFFER IF DL = 0AH
    MOV  DH,  -1				;AN000; MESSAGE CALL -1==> UTILITY MESSAGE
    CALL SYSDISPMSG				;AN000;
    RET 					;AN000;
DISPLAY_MESSAGE_ROUTINE ENDP			;AN000;

;****************************************************************************
; Procedure for hooking the INT_23_VECTOR into vector table
; INPUT:
;   None.
; OUTPUT:
;   None.
;****************************************************************************
PUBLIC	 HOOK_INT_23				;AN074;SEH
HOOK_INT_23   PROC FAR				;AN074;SEH

    PUSH AX					;AN074;SEH
    PUSH BX					;AN074;SEH
    PUSH DX					;AN074;SEH
    PUSH ES					;AN074;SEH Save the segment registers.
    PUSH DS					;AN074;SEH
    PUSHF					;AN074;SEH
						;
       MOV  AL, 23H				;AN074;SEH Interrupt number to get the vector of
       MOV  AH, 35H				;AN074;SEH DOS Function number for getting a vector
       DOSCALL					;AN074;SEH Get the interrupt vector
       MOV  WORD PTR OLD_INT_23, BX		;AN074;SEH Save the old vactor offset
       MOV  AX, ES				;AN074;SEH Get the old vector segment
       MOV  WORD PTR OLD_INT_23[2], AX		;AN074;SEH Save the old vector segment
       PUSH DS					;AN074;SEH Save DS
       PUSH CS					;AN074;SEH Point DS to the current code segment
       POP  DS					;AN074;SEH
       MOV  DX, OFFSET INT_23_VECTOR		;AN074;SEH Load offset of the new vector
       MOV  AL, 23H				;AN074;SEH Interrupt number to set
       MOV  AH, 25H				;AN074;SEH DOS Fn. number for setting a vector
       DOSCALL					;AN074;SEH Set the vector
       POP  DS					;AN074;SEH Restore data segment
						;
    POPF					;AN074;SEH
    POP  DS					;AN074;SEH Restore the registers
    POP  ES					;AN074;SEH
    POP  DX					;AN074;SEH
    POP  BX					;AN074;SEH
    POP  AX					;AN074;SEH
						;
    RET 					;AN074;SEH
HOOK_INT_23   ENDP				;AN074;SEH

;****************************************************************************
; Procedure for restoring the old interrupt 23h vector.
; INPUT:
;   None.
; OUTPUT:
;   None.
;****************************************************************************
PUBLIC	 RESTORE_INT_23 			;AN074;SEH
RESTORE_INT_23 PROC FAR 			;AN074;SEH
						;
    PUSHF					;AN074;SEH
    PUSH AX					;AN074;SEH
    PUSH DX					;AN074;SEH
    PUSH DS					;AN074;SEH Save the data segment
						;
       PUSH DS					;AN074;SEH Save DS
       LDS  DX, OLD_INT_23			;AN074;SEH Load the address of the old vector
       MOV  AH, 25H				;AN074;SEH DOS Fn. number for setting an interrupt vector
       MOV  AL, 23H				;AN074;SEH Interrupt vector to set
       DOSCALL					;AN074;SEH Set the vector
       POP  DS					;AN074;SEH Restore data segment
						;
    POP  DS					;AN074;SEH Restore the data segment
    POP  DX					;AN074;SEH
    POP  AX					;AN074;SEH
    POPF					;AN074;SEH
						;
    RET 					;AN074;SEH
RESTORE_INT_23	   ENDP 			;AN074;SEH
;****************************************************************************
; Procedure for hooking the INT_24_VECTOR into vector table
; INPUT:
;   None.
; OUTPUT:
;   None.
;****************************************************************************
PUBLIC	 HOOK_INT_24				;AN000;
HOOK_INT_24   PROC FAR				;AN000;

    PUSH AX					;AN000;
    PUSH BX					;AN000;
    PUSH DX					;AN000;
    PUSH ES					;AN000; Save the segment registers.
    PUSH DS					;AN000;
    PUSHF					;AN000;

    .IF < INT24_STATUS eq UNHOOKED >		;AN000;

       MOV  AL, 24H				;AN000; Interrupt number to get the vector of
       MOV  AH, 35H				;AN000; DOS Function number for getting a vector
       DOSCALL					;AN000; Get the interrupt vector
       MOV  WORD PTR OLD_INT_24, BX		;AN000; Save the old vactor offset
       MOV  AX, ES				;AN000; Get the old vector segment
       MOV  WORD PTR OLD_INT_24[2], AX		;AN000; Save the old vector segment
       PUSH DS					;AN000; Save DS
       PUSH CS					;AN000; Point DS to the current code segment
       POP  DS					;AN000;
       MOV  DX, OFFSET INT_24_VECTOR		;AN000; Load offset of the new vector
       MOV  AL, 24H				;AN000; Interrupt number to set
       MOV  AH, 25H				;AN000; DOS Fn. number for setting a vector
       DOSCALL					;AN000; Set the vector
       POP  DS					;AN000; Restore data segment
       MOV  INT24_STATUS,HOOKED 		;AN000;

    .ENDIF					;AN000;

    POPF					;AN000;
    POP  DS					;AN000; Restore the registers
    POP  ES					;AN000;
    POP  DX					;AN000;
    POP  BX					;AN000;
    POP  AX					;AN000;

    RET 					;AN000;
HOOK_INT_24   ENDP				;AN000;

;****************************************************************************
; Procedure for restoring the old interrupt 24h vector.
; INPUT:
;   None.
; OUTPUT:
;   None.
;****************************************************************************
PUBLIC	 RESTORE_INT_24 			;AN000;
RESTORE_INT_24 PROC FAR 			;AN000;

    PUSHF					;AN000;
    PUSH AX					;AN000;
    PUSH DX					;AN000;
    PUSH DS					;AN000; Save the data segment

    .IF < INT24_STATUS eq HOOKED >		;AN000;

       PUSH DS					;AN000; Save DS
       LDS  DX, OLD_INT_24			;AN000; Load the address of the old vector
       MOV  AH, 25H				;AN000; DOS Fn. number for setting an interrupt vector
       MOV  AL, 24H				;AN000; Interrupt vector to set
       DOSCALL					;AN000; Set the vector
       POP  DS					;AN000; Restore data segment
       MOV  INT24_STATUS,UNHOOKED		;AN000;

    .ENDIF					;AN000;

    POP  DS					;AN000; Restore the data segment
    POP  DX					;AN000;
    POP  AX					;AN000;
    POPF					;AN000;

    RET 					;AN000;
RESTORE_INT_24	   ENDP 			;AN000;
;****************************************************************************
; Procedure for hooking the INT_2F_VECTOR into vector table
; INPUT:
;   None.
; OUTPUT:
;   None.
;****************************************************************************
PUBLIC	 HOOK_INT_2F				;AN000;
PUBLIC	 RESTORE_INT_2F 			;AN000;
HOOK_INT_2F   PROC FAR				;AN000;

    PUSH AX					;AN000;
    PUSH BX					;AN000;
    PUSH DX					;AN000;
    PUSH ES					;AN000; Save the segment registers.
    PUSH DS					;AN000;
    MOV  AL, 2FH				;AN000; Interrupt number to get the vector of
    MOV  AH, 35H				;AN000; DOS Function number for getting a vector
    DOSCALL					;AN000; Get the interrupt vector
    MOV  WORD PTR OLD_INT_2F, BX		;AN000; Save the old vactor offset
    MOV  AX, ES 				;AN000; Get the old vector segment
    MOV  WORD PTR OLD_INT_2F[2], AX		;AN000; Save the old vector segment
    PUSH CS					;AN000; Point DS to the current code segment
    POP  DS					;AN000;
    MOV  DX, OFFSET INT_2F_VECTOR		;AN000; Load offset of the new vector
    MOV  AL, 2FH				;AN000; Interrupt number to set
    MOV  AH, 25H				;AN000; DOS Fn. number for setting a vector
    DOSCALL					;AN000; Set the vector
    POP  DS					;AN000; Restore the registers
    POP  ES					;AN000;
    POP  DX					;AN000;
    POP  BX					;AN000;
    POP  AX					;AN000;

    RET 					;AN000;

HOOK_INT_2F   ENDP				;AN000;
;****************************************************************************
; Procedure for restoring the old interrupt 2Fh vector.
; INPUT:
;   None.
; OUTPUT:
;   None.
;****************************************************************************
RESTORE_INT_2F PROC FAR 			;AN000;
	PUSHF					;AN000;
	PUSH AX 				;AN000;
	PUSH DX 				;AN000;
	PUSH DS 				;AN000; Save the data segment
	LDS  DX, OLD_INT_2F			;AN000; Load the address of the old vector
	MOV  AH, 25H				;AN000; DOS Fn. number for setting an interrupt vector
	MOV  AL, 2FH				;AN000; Interrupt vector to set
	DOSCALL 				;AN000; Set the vector
	POP  DS 				;AN000; Restore the data segment
	POP  DX 				;AN000;
	POP  AX 				;AN000;
	POPF					;AN000;
	RET					;AN000;
RESTORE_INT_2F	   ENDP 			;AN000;
;****************************************************************************
; Procedure for hooking the INT_2F_256KB into vector table
; INPUT:
;   None.
; OUTPUT:
;   None.
;****************************************************************************
PUBLIC	 HOOK_INT_2F_256KB			;AN000;
HOOK_INT_2F_256KB   PROC FAR			;AN000;

    PUSH AX					;AN000;
    PUSH BX					;AN000;
    PUSH DX					;AN000;
    PUSH ES					;AN000; Save the segment registers.
    PUSH DS					;AN000;
    MOV  AL, 2FH				;AN000; Interrupt number to get the vector of
    MOV  AH, 35H				;AN000; DOS Function number for getting a vector
    DOSCALL					;AN000; Get the interrupt vector
    MOV  WORD PTR OLD_INT_2F, BX		;AN000; Save the old vactor offset
    MOV  AX, ES 				;AN000; Get the old vector segment
    MOV  WORD PTR OLD_INT_2F[2], AX		;AN000; Save the old vector segment
    PUSH CS					;AN000; Point DS to the current code segment
    POP  DS					;AN000;
    MOV  DX, OFFSET INT_2F_256KB		;AN000; Load offset of the new vector
    MOV  AL, 2FH				;AN000; Interrupt number to set
    MOV  AH, 25H				;AN000; DOS Fn. number for setting a vector
    DOSCALL					;AN000; Set the vector
    POP  DS					;AN000; Restore the registers
    POP  ES					;AN000;
    POP  DX					;AN000;
    POP  BX					;AN000;
    POP  AX					;AN000;

    RET 					;AN000;

HOOK_INT_2F_256KB   ENDP			;AN000;
;****************************************************************************
; Procedure for hooking the INT_2F_FORMAT into vector table
; INPUT:
;   None.
; OUTPUT:
;   None.
;****************************************************************************
PUBLIC	 HOOK_INT_2F_FORMAT			;AN111;JW
HOOK_INT_2F_FORMAT  PROC FAR			;AN111;JW

    PUSH AX					;AN111;JW
    PUSH BX					;AN111;JW
    PUSH DX					;AN111;JW
    PUSH ES					;AN111; Save the segment registers.			 JW
    PUSH DS											 ;AN111;JW
    MOV  AL, 2FH				;AN111; Interrupt number to get the vector of	 JW
    MOV  AH, 35H				;AN111; DOS Function number for getting a vector	 JW
    DOSCALL					;AN111; Get the interrupt vector			 JW
    MOV  WORD PTR OLD_INT_2F, BX		;AN111; Save the old vactor offset			 JW
    MOV  AX, ES 				;AN111; Get the old vector segment			 JW
    MOV  WORD PTR OLD_INT_2F[2], AX		;AN111; Save the old vector segment			 JW
    PUSH CS					;AN111; Point DS to the current code segment	 JW
    POP  DS					;						 ;AN111;JW
    MOV  DX, OFFSET INT_2F_FORMAT		;AN111; Load offset of the new vector		 JW
    MOV  AL, 2FH				;AN111; Interrupt number to set 			 JW
    MOV  AH, 25H				;AN111; DOS Fn. number for setting a vector		 JW
    DOSCALL					;AN111; Set the vector				 JW
    POP  DS					;AN111; Restore the registers			 JW
    POP  ES					;AN111;JW
    POP  DX					;AN111;JW
    POP  BX					;AN111;JW
    POP  AX					;AN111;JW
						;
    RET 					;AN111;JW
						;
HOOK_INT_2F_FORMAT  ENDP			;AN111;JW
;****************************************************************************

CODE_FAR    ENDS				;AN000;
	    END 				;AN000;
