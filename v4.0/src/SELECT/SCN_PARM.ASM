;********************************************************************************
; File: SCN_PARM.ASM
;
; Subroutine for scanning the SELECT command line, and if the appropriate
; parameter is specified, additional information is read from the disk.
;
;********************************************************************************
.ALPHA					;AN000;
.XLIST					;AN000;
INCLUDE  MACROS.INC			;AN000;
INCLUDE  STRUC.INC			;AN000;
INCLUDE  EXT.INC			;AN000;
.LIST					;AN000;


PUBLIC	 SCAN_PARAMETERS_ROUTINE	;AN000;
EXTRN	 SYSPARSE:FAR			;AN000;
EXTRN	 POS_ZERO:FAR			;AN000;
EXTRN	 HOOK_INT_24:FAR		;AN000;
EXTRN	 RESTORE_INT_24:FAR		;AN000;
EXTRN	 CLOSE_FILE_ROUTINE:FAR 	;AN000;


DATA	 SEGMENT   BYTE PUBLIC	  'DATA';AN000;

PARMS	 LABEL	   BYTE 		;AN000;
    PAR_EXTEN	   DW	PARMSX		 ;AN000; Offset of the PARMS EXTENSION BLOCK
    PAR_NUM	   DB	0		 ;AN000; The number of further definitions

; The PARMS EXTENSION BLOCK
PARMSX	 LABEL	   BYTE 		 ;AN000;
    PAX_MINP	   DB	1		 ;AN000;
    PAX_MAXP	   DB	1		 ;AN000;
		   DW	OFFSET CONTROL_P1;AN000;
    PAX_MAX_SW	   DB	0		 ;AN000;
    PAX_MAX_K1	   DB	0		 ;AN000;

CONTROL_P1    LABEL	BYTE		 ;AN000;
		   DW	02000H		 ;AN000;
		   DW	0000H		 ;AN000;
		   DW	RESULT_P1	 ;AN000;
		   DW	VALUE_LIST_P1	 ;AN000;
		   DB	0		 ;AN000;

VALUE_LIST_P1	   LABEL     BYTE	 ;AN000;
		   DB	3		 ;AN000; Number of value definitions
		   DB	0		 ;AN000; Number of range definitions
		   DB	0		 ;AN000; Number of actual value definitions
		   DB	2		 ;AN000; Number of string definitions
		   DB	0		 ;AN000; Value to be returned if this string is matched
		   DW	OFFSET KEYWORD_MENU;AN000;
		   DB	1		 ;AN000; Value to be returned if this string is matched
		   DW	OFFSET KEYWORD_FDISK ;AN000;

KEYWORD_MENU  DB   'MENU',0       ;AN000;
KEYWORD_FDISK DB   'FDISK',0      ;AN000;

RESULT_P1	   LABEL     BYTE ;AN000;
		   DB	0	  ;AN000; Type of operand returned
		   DB	0	  ;AN000; Matched item tag
		   DW	0	  ;AN000; Offset of synonym returned
		   DB	0,0,0,0   ;AN000; Unsure what this is...


MODE	      DW   0		  ;AN000;
option_0      dw   0
OPTION_1      DW   0		  ;AN000;
OPTION_2      DW   0		  ;AN000;
OPTION_3      DW   0		  ;AN033;SEH
FILE_HANDLE   DW   0		  ;AN000;

DATA	 ENDS			  ;AN000;

CODE_FAR SEGMENT   BYTE PUBLIC	  'CODE' ;AN000;

    ASSUME    CS:CODE_FAR, DS:DATA, ES:DATA ;AN000;

;****************************************************************************
;
;   SCAN_PARAMETERS_ROUTINE: Scan SELECT command line for parameters.
;
;   SYNTAX:  SCAN_PARAMETERS   mode, option, path, filename, buffer, buff_size
;
;   INPUT:
;	DI = The name of the file which contains the FDISK parameters.
;	     (ASCII-N format)
;	SI = A buffer where the data read from the file can be stored.
;	CX = The size of the buffer.
;
;   OUTPUT:
;	AX = Install mode
;	   = 0: Parameter is MENU
;	   = 1: Parameter is FDISK
;	   = 0FFH: Parameter is invalid
;	BX = 0
;	   = 1
;	   = 2
;	   = 0FFh: Parameter is invalid (not 0, 1, 2)
;	CX = 0,1,2
;	DI = Install path in ASCII-N format
;
;   OPERATION:	The SELECT command line is scanned for parameters.  The
;	return codes for the various parameters are provided in variables
;	defined above.	If the parameter on the command line is FDISK, then
;	the file specified in FILENAME is opened and additional parameters
;	are read.  If the parameters in the file are invalid, or if the file
;	cannot be found, then 0FFh is returned in MODE and OPTION, and the
;	path length is set to zero.
;
;  Note:
;	Before this macro is executed, there must be as ASSUME ES:DATA
;	statement.  If not, the parser will not execute properly and
;	either the computer will hang or erroneous values will be returned.
;
;****************************************************************************
    PATH      EQU  [BP+12]			 ;AN000;
    FILENAME  EQU  [BP+10]			 ;AN000;
    BUFFER    EQU  [BP+8]			 ;AN000;
    BUFF_SIZE EQU  [BP+6]			 ;AN000;
						 ;
SCAN_PARAMETERS_ROUTINE PROC FAR		 ;AN000;
    PUSH BP					 ;AN000;
    MOV  BP, SP 				 ;AN000;
						 ;
    MOV  OPTION_1, E_SELECT_INV 		 ;AN000;
    MOV  OPTION_2, E_SELECT_INV 		 ;AN000;
						 ;
    PUSH ES					 ;AN000; Save the extra register
    MOV  AX, DATA				 ;AN000; ES contain control block segment
    MOV  ES, AX 				 ;AN000;
    MOV  DI, OFFSET PARMS			 ;AN000; DI contains offset of control block
    MOV  SI, 0081H				 ;AN000; SI contains offset of command line
    MOV  DX, 0					 ;AN000; DX and CX must be zero
    MOV  CX, 0					 ;AN000;
    MOV  AH, 062H				 ;AN000; Get the PSP segment
    DOSCALL					 ;AN000;
						 ;
    PUSH BX					 ;AN000; Save for later reference
NEXT_PARSE:					 ;AN000;
    POP  AX					 ;AN000; Get the PSP segment
    PUSH AX					 ;AN000; Place on stack again
    PUSH DS					 ;AN000; Save the current data segment
    MOV  DS, AX 				 ;AN000; Load DS with the segment of the command line
    CALL SYSPARSE				 ;AN000; Parse the command line
    POP  DS					 ;AN000; Restore the data segment
						 ;
    .IF < AX EQ 0 >				 ;AN000; Were there any errors?
	 MOV  BX, DX				 ;AN000; No! Get the address of the result block
	 MOV  AL, [BX]+1			 ;AN000; Yes! Get the returned value
	 MOV  AH, 0				 ;AN000; Zero the high byte
	 MOV  MODE, AX				 ;AN000; Store the result
	 JMP  NEXT_PARSE			 ;AN000; Parse the next parameter
    .ELSEIF < AX NE -1 >			 ;AN000; If there was an error, indicate so.
	 MOV  MODE, E_SELECT_INV		 ;AN000; Return that the values are invalid
	 MOV  OPTION_1, E_SELECT_INV		 ;AN000;
	 MOV  OPTION_2, E_SELECT_INV		 ;AN000;
    .ENDIF					 ;AN000;
    POP  AX					 ;AN000; Take the PSP segment off the stack
    MOV  AX,MODE				 ;AN000; Store the result
    POP  ES					 ;AN000;
    POP  BP					 ;AN000;
    RET 					 ;AN000;
SCAN_PARAMETERS_ROUTINE ENDP			 ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   SCAN_INFO_FILE_ROUTINE: Scan SELECT.TMP file for parameters.
;
;   INPUT:
;	The following variables have been passed to this routine from the
;	     SCAN_INFO_FILE macro by pushing them on the stack:
;	     PATH      EQU [BP+12]
;	     FILENAME  EQU [BP+10]
;	     BUFFER    EQU [BP+8]
;	     BUFF_SIZE EQU [BP+6]
;
;   OUTPUT:
;	AX = Install mode
;	   = 0: Parameter is MENU
;	   = 1: Parameter is FDISK
;	   = 0FFH: Parameter is invalid
;	BX = 1
;	   = 2
;	   = 3
;	   = 0FFh: Parameter is invalid (not 1, 2, 3)
;	CX = 1
;	   = 2
;	   = 0FFh: Parameter is invalid (not 1, 2)
;	DX = 1
;	   = 2
;	   = 0FFh: Parameter is invalid (not 1, 2)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC	SCAN_INFO_FILE_ROUTINE		 ;AN000;
SCAN_INFO_FILE_ROUTINE	PROC	FAR		 ;AN000;
    CALL HOOK_INT_24				 ;AN000;
						 ;
    PUSH BP					 ;AN000;
    MOV  BP, SP 				 ;AN000;
    MOV  OPTION_0, E_SELECT_INV 		 ;AN000;
    MOV  OPTION_1, E_SELECT_INV 		 ;AN000;
    MOV  OPTION_2, E_SELECT_INV 		 ;AN000;
    MOV  OPTION_3, E_SELECT_INV 		 ;AN033;SEH
    PUSH ES					 ;AN000; Save the extra register
						 ;
    .IF < MODE NE E_SELECT_INV> AND NEAR	 ;AN000; If no error has occured yet,
    .IF < MODE EQ 1 >	NEAR			 ;AN000;   and if the parameter was FDISK...
	 MOV  DI, FILENAME			 ;AN000; Get the offset of the filename
	 CALL POS_ZERO				 ;AN000; Make into an ASCII-Z string
	 MOV  DX, DI				 ;AN000; Load filename offset again
	 ADD  DX, 2				 ;AN000; Adjust pointer past the length word
	 MOV  AX, 3D00H 			 ;AN000; Fn call for opening a file for reading
	 DOSCALL				 ;AN000; Open the file
	 .IF < C >				 ;AN000; If there was as error, do not continue
	      JMP  FILE_ERROR			 ;AN000; Return INVALID parameters to the caller
	 .ENDIF 				 ;AN000;
	 MOV  FILE_HANDLE, AX			 ;AN000; Save the returned file handle
	 MOV  AH, 3FH				 ;AN000; DOS Fn for reading from a file
	 MOV  DX, BUFFER			 ;AN000; Get the offset of the data buffer
	 MOV  CX, BUFF_SIZE			 ;AN000; Get the number of bytes in the buffer
	 MOV  BX, FILE_HANDLE			 ;AN000; Get the file handle for the opened file
	 DOSCALL				 ;AN000; Read from the file
	 .IF < C >				 ;AN000; If there was an error, do not continue
	      JMP  FILE_ERROR			 ;AN000; Return INVALID parameters to the caller
	 .ENDIF 				 ;AN000;
	 MOV  SI, BUFFER			 ;AN000; Get the offset of the data buffer
	 MOV  BH, 0				 ;AN000; Zero the high byte
	 MOV  BL, BYTE PTR [SI] 		 ;AN000; Get the first byte from the file
	 SUB  BL, '0'                            ;AN000; Turn into a binary number
	 MOV  OPTION_0, BX			 ;AN000; Save this as the first option
	 MOV  BL, BYTE PTR [SI+3] 		 ;AN000; Get the first byte from the file
	 SUB  BL, '0'                            ;AN000; Turn into a binary number
	 MOV  OPTION_1, BX			 ;AN000; Save this as the first option
	 MOV  BL, BYTE PTR [SI+6]		 ;AN000; Get the second option in the file
	 SUB  BL, '0'                            ;AN000; Make into a binary value
	 MOV  OPTION_2, BX			 ;AN000; Save this second option
	 MOV  BL, BYTE PTR [SI+9]		 ;AN033; SEH Get the third option in the file
	 SUB  BL, '0'                            ;AN033; SEH Make into a binary value
	 MOV  OPTION_3, BX			 ;AN033; SEH Save this third option
	 MOV  SI, BUFFER			 ;AN000; Get the offset of the data buffer
	 ADD  SI, 12				 ;AC033; SEH Point to the start of the path line
	 MOV  DI, PATH				 ;AN000; Get the offset of the path storage
	 MOV  BX, DI				 ;AN000;
	 ADD  DI, 2				 ;AN000; Adjust pointer past the length word
						 ; AX contains the number of characters read from the file
	 SUB  AX, 12				 ;AC033; SEH Number of characters left in the buffer
	 MOV  CX, 0				 ;AN000; Number of characters in the path string
	 MOV  WORD PTR [BX], 0			 ;AN000; Zero the string length to begin
	 .WHILE < AX GT 0 >			 ;AN000; Continue while there are characters left
	      MOV  DL, [SI]			 ;AN000; Get the character from the buffer
	      .IF < DL EQ E_CR > OR		 ;AN000; See if this is the end of the line
	      .IF < DL EQ E_LF >		 ;AN000;
		   MOV	[BX], CX		 ;AN000; Store the length of path
		   .LEAVE			 ;AN000;
	      .ENDIF				 ;AN000;
	      MOV  [DI], DL			 ;AN000; Store the byte in the path
	      INC  DI				 ;AN000; Increment the path pointer
	      INC  SI				 ;AN000; Increment the source pointer
	      INC  CX				 ;AN000; Increment the count of characters
	      DEC  AX				 ;AN000; Decrement the numbers of characters left
	      .IF < CX A M_INSTALL_PATH >	 ;AN000; If more then 40 characters then an error
		   JMP	FILE_ERROR		 ;AN000;
	      .ENDIF				 ;AN000;
	 .ENDWHILE				 ;AN000;
	 .IF < OPTION_1 AE 1 > AND		 ;AN000; If option is 1 or 2 then a path is needed
	 .IF < OPTION_1 BE 3 >			 ;AN000;
	      .IF < <WORD PTR [BX]> EQ 0 >	 ;AN000; If the path length was 0, return error
		   JMP	FILE_ERROR		 ;AN000;
	      .ENDIF				 ;AN000;
	 .ELSE					 ;AN000;
	      .IF < <WORD PTR [BX]> NE 0 >	 ;AN000; If option is 3 and there is a path, error
		   JMP	FILE_ERROR		 ;AN000;
	      .ENDIF				 ;AN000;
	 .ENDIF 				 ;AN000;
	 JMP  CLOSE_THE_FILE			 ;AN000;
FILE_ERROR:					 ;AN000; Here if there has been an error
	 MOV  MODE, E_SELECT_INV		 ;AN000;
	 MOV  OPTION_1, E_SELECT_INV		 ;AN000;
	 MOV  OPTION_2, E_SELECT_INV		 ;AN000;
	 MOV  OPTION_3, E_SELECT_INV		 ;AN033; SEH
	 MOV  BX, PATH				 ;AN000;
	 MOV  WORD PTR [BX], 0			 ;AN000;
CLOSE_THE_FILE: 				 ;AN000; Close the file
	 MOV  BX, FILE_HANDLE			 ;AN000; Get the file handle
	 CLOSE_FILE BX				 ;AN000; Close the file
    .ENDIF					 ;AN000;
    MOV  AX, option_0				 ;AN000; Return the parameters
    MOV  BX, OPTION_1				 ;AN000;
    MOV  CX, OPTION_2				 ;AN000;
    MOV  DX, OPTION_3				 ;AN033; SEH
						 ;
    POP  ES					 ;AN000; Restore the extra segment
    POP  BP					 ;AN000;
    CALL RESTORE_INT_24 			 ;AN000;
    RET  8					 ;AN000;
SCAN_INFO_FILE_ROUTINE	ENDP			 ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CODE_FAR ENDS					 ;AN000;
						 ;
END						 ;AN000;
