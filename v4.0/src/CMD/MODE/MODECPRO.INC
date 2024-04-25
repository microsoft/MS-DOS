; MODECPRO.INC - INCLUDED BY MODECP.SAL  
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: MODECP

; DESCRIPTIVE NAME: MODE, CODEPAGE HANDLER

;FUNCTION: Manages the codepage file, sending it to the
;	   device when a DESIGNATE is requested, telling
;	   the device which FONT to select when ACTIVATE
;	   is requested, and displaying the font status
;	   of the device when QUERY is requested.

; NOTES:
;	 This module should be processed with the SALUT pre-processor
;	 with re-allignment not requested, as:

;		SALUT MODECP,NUL,;


; ENTRY POINT: MODECP
;    LINKAGE: CALL MODECP

; INPUT: As defined by the "CODEPAGE_PARMS" STRUC.
;	All four segregs are expected to point to the one common
;	segment, called PRINTF_CODE.

; EXIT-NORMAL:	ERRORLEVEL 0 - Successful completion

; EXIT-ERROR: ERRORLEVEL 1 - An error message is also displayed

; EFFECTS:

; INTERNAL REFERENCES:
;    ROUTINES:
;	MODECP - HANDLES ALL PROCESSING FOR THE CODEPAGE SUPPORT IN MODE
;	SET_DEV_TYPE - SCANS LIST OF DEVICES FOR SPECIFIED DEVICE
;	SET_GLOBAL_CODEPAGE - DEVICE IS "*", INVOKE OR QUERY GLOBAL CODEPAGE
;	FUNCTION_SELECT - DETERMINES FUNCTION TO BE PERFORMED, DESIGNATE,QUERY,INVOKE
;	DO_DESIGNATE - PERFORMS START DESIGNATE, DOWNLOAD FONT FILE, DESIGNATE END
;	DES_START - HANDLES DETAILS OF START DESIGNATE FUNCTION
;	DES_START_ERROR - DIAGNOSES ERRORS FROM DESIGNATE START
;	MOVE_FILE - HANDLES DETAILS OF DOWNLOADING THE FONT FILE TO DEVICE
;	DES_END - HANDLES DETAILS OF DESIGNATE END FUNCTION
;	DO_INVOKE - HANDLES DETAILS OF INVOKE FUNCTION
;	DO_STATUS - INTERROGATES DEVICE FOR CODEPAGE STATUS
;	QUERY_ERROR - DISGNOSES ERRORS FROM QUERY REQUEST
;	DISPLAY_CPID - DISPLAYS THE CODEPAGE ID AS PART OF STATUS REPORT
;	SEND_MSG - SET UP ALL ERROR MESSAGES TO BE DISPLAYED
;	QUEUE - HANDLES INTERFACE TO "PRINTF" FOR ALL MESSAGES
;	EX_ERR - DOSCALL RESULTED IN CARRY, SO GO FIND OUT THE EXTENDED ERROR
;	DO_GENERIC_IOCTL - PROCESS ALL GENERIC IOCTL CALLS TO THE DEVICE
;

;    DATA AREAS:
;	WORKAREA - Temporary storage

; EXTERNAL REFERENCES:
;    ROUTINES:
;	PRINTF - Uses the MSG parm lists to construct the messages
;		 on STDOUT, on on STDERR.

;    DATA AREAS: A large buffer is allocated from free memory, if available.

; COPYRIGHT: The copyright notice is found in the OBJ code generated from
;	     the "MAIN.ASM" module of the MODE component of the DOS utility.

;****************** END OF SPECIFICATIONS *****************************
	IF1
	    %OUT INCLUDE MODECPRO.INC ;MODULE PROLOGUE
	ENDIF

;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;  AX001 - P3976: Need to have all pieces of messages in MODE.SKL so have to
;		  implement the SYSGETMSG method of getting addressability to
;		  the pieces.  This means that the code does a SYSGETMSG call
;		  which returns a pointer (DS:SI) to the message piece.  The
;		  address is then put in the sublist block for the message
;		  being issued.

;  AX002 - P4576  Segments were being trashed before calling message services
;		  because device type was wrong on IOCTL call because ES was
;		  zero when using CMPSB in SET_DEV_TYPE and no match was made.

;บ											  บ
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ

