	PAGE	,132			;
	TITLE	COMPPAR.SAL - LOOK AT COMMAND LINE PARMS
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: COMPPAR.SAL
;
; DESCRIPTIVE NAME: Handle the definition of the DOS command line parameters
;		    and the interface to the DOS system PARSER.
;
;FUNCTION: The static data areas are prescribed by the DOS system PARSER
;	   to define the several parameters presented to COMP.	These
;	   data areas are passed to the PARSER, and its responses checked
;	   to determine the nature of the user's specifications.  Any errors
;	   found in the user's parameters are defined in messages back
;	   to the user.
;
; ENTRY POINT: PARSER, near
;
; INPUT: (DOS COMMAND LINE PARAMETERS)
;
;	[d:][path] COMP [d:][path][filenam1[.ext]] [d:][path][filenam2[.ext]]
;
;	 Where
;	 [d:][path] before COMP to specify the drive and path that
;		    contains the COMP command file.
;
;	 [d:][path][filenam1[.ext]] -  to specify the FIRST (or primary)
;		    file or group of files to be compared
;
;	 [d:][path][filenam2[.ext]]  - to specify the SECOND file or group
;		    of files to be compared with the corresponding file
;		    from the FIRST group
;
;	 Global filename characters are allowed in both filenames,
;	 and will cause all of the files matching the first filename
;	 to be compared with the corresponding files from the second
;	 filename.  Thus, entering COMP A:*.ASM B:*.BAK will cause
;	 each file from drive A:  that has an extension of .ASM to be
;	 compared with a file of the same name (but with an extension
;	 of .BAK) from drive B:.
;
;	 If you enter only a drive specification, COMP will assume
;	 all files in the current directory of the specified drive.
;	 If you enter a path without a filename, COMP assumes all
;	 files in the specified directory.  Thus, COMP A:\LEVEL1
;	 B:\LEVEL2 will compare all files in directory A:\LEVEL1 with
;	 the files of the same names in directory B:\LEVEL2.
;
;	 If no parameters are entered with the COMP command, you will
;	 be prompted for both.	If the second parm is omitted, COMP
;	 will prompt for it.  If you simply press ENTER when prompted
;	 for the second filename, COMP assumes *.* (all files
;	 matching the primary filename), and will use the current
;	 directory of the default drive.
;
;	 If no file matches the primary filename, COMP will prompt
;	 again for both parameters.
;
;
;	Upon entry to PARSER in this module,
;	"CURRENT_PARM" = offset to start of parm text in command string
;	"ORDINAL" = initialized to zero
;	PSP+81H = text of DOS command line parms string
;
; EXIT-NORMAL: If a Code Page number was specified
;		  BX = Offset to language table to be loaded
;		  DX = Integer value of Code Page specified
;	       If /STATUS (or /STA) was specified
;		  BX = 0
;	       If Question mark was specified
;		  BX=-1
;
; EXIT-ERROR: If there was any problem with the parms,
;	      the question mark is assumed, and the appropriate
;	      PARSE error message is displayed.
;	      The Errorlevel code of "EXPAR" (3), meaning: "PARM ERROR",
;	      set in "EXITFL", is requested to be returned to the user.
;
; INTERNAL REFERENCES:
;    ROUTINES:
;	PARSE_ERROR:NEAR Display the appropriate Parse error message.
;
;    DATA AREAS:
;	The several parameter control blocks, defined by the System
;	PARSER interface, defining the COMP parameters.
;
; EXTERNAL REFERENCES:
;    ROUTINES:
;	SENDMSG:NEAR	Uses Msg Descriptor to drive message handler.
;	SYSPARSE:NEAR	System Command Line Common Parser.
;
;    DATA AREAS:
;	EXITFL:BYTE	Errorlevel return code.
;	MSGNUM_PARSE:WORD Message descriptor for all parse errors.
;
; NOTES:
;	 This module should be processed with the SALUT preprocessor
;	 with the re-alignment not requested, as:
;
;		SALUT COMPPAR,NUL
;
;	 To assemble these modules, the alphabetical or sequential
;	 ordering of segments may be used.
;
;	 For LINK instructions, refer to the PROLOG of the main module,
;	 COMP1.SAL.
;
; REVISION HISTORY:
;	     A000 Version 4.0 : add PARSER, System Message Handler,
;		  Add compare of extended attributes, if present.
;
; COPYRIGHT: The following notice is found in the OBJ code generated from
;	     the "COMPSM.SAL" module:
;
;	     "The DOS COMP Utility"
;	     "Version 4.0  (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Property of Microsoft"
;
;PROGRAM AUTHOR: Edwin M. K.
;	 modified: Bill L.
;****************** END OF SPECIFICATIONS *****************************
	IF1				;AN000;
	    %OUT    COMPONENT=COMP, MODULE=COMPPAR.SAL... ;AN000;
	ENDIF				;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;
HEADER	MACRO	TEXT			;;AN000;
.XLIST					;;AN000;
	SUBTTL	TEXT			;;AN000;
.LIST					;;AN000;
	PAGE				;;AN000;
	ENDM				;;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;
;		      $SALUT (4,23,28,36) ;AN000;

		      INCLUDE COMPEQ.INC ;AN000;
;		      LOCAL EQUATES						      ;AN000;
MAX_PATH_LEN	      EQU  64	   ;MAX CHAR IN A PATH				;AN000;
EXPAR		      EQU  1	   ;RETURN TO DOS, INVALID DOS COMMAND LINE PARMS  ;AN000;
ZERO_PARM_CT	      EQU  0	   ;ORDINAL VALUE BEFORE FIRST PARM FOUND	;AN000;
FIRST_PARM_CT	      EQU  1	   ;ORDINAL VALUE AFTER FIRST PARM FOUND	;AN000;
NUL		      EQU  0	   ;ASCIIZ STRING DELIMITER			;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;
;		      EXIT CODES FROM SYSPARSE (WHEN CY=0)			      ;AN000;

SYSPRM_EX_OK	      EQU  0	   ; no error					;AN000;
SYSPRM_EX_MANY	      EQU  1	   ; too many operands				;AN000;
SYSPRM_EX_MISSING     EQU  2	   ; required operand missing			;AN000;
SYSPRM_EX_NOT_SWLIST  EQU  3	   ; not in switch list provided		;AN000;
SYSPRM_EX_NOT_KEYLIST EQU  4	   ; not in keyword list provided		;AN000;
SYSPRM_EX_RANGE       EQU  6	   ; out of range specified			;AN000;
SYSPRM_EX_VALUE       EQU  7	   ; not in value list provided 		;AN000;
SYSPRM_EX_STRING      EQU  8	   ; not in string list provided		;AN000;
SYSPRM_EX_SYNTAX      EQU  9	   ; syntax error				;AN000;
SYSPRM_EX_EOL	      EQU  -1	   ; end of command line			;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;
		      HEADER <STRUC - DEFINITIONS OF EXTERNAL CONTROL BLOCKS> ;AN000;
PSP		      STRUC	   ;AN000;
		      DB   80H DUP (?) ;SKIP OVER FIRST HALF OF PSP	       ;AN000;
PSP_PARMLEN	      DB   ?	   ;NUMBER OF BYTES IN DOS COMMAND LINE    ;AN000;
PSP_COMMAND	      DB   127 DUP(?) ;TEXT OF DOS COMMAND LINE 	      ;AN000;
PSP		      ENDS	   ;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;
FILESPEC	      STRUC	   ;AN000;
FS_DRIVE_ID	      DB   ?	   ;DRIVE LETTER		   ;AN000;
FS_COLON	      DB   ":"	   ;COLON SEPARATOR		   ;AN000;
FS_SLASH1	      DB   "\"	   ;LEADING BACKSLASH,START AT ROOT ;AN000;
FS_PATH 	      DB   MAX_PATH_LEN DUP (0) ;TEXT OF PATH			;AN000;

;LOCATION OF REMAINING FIELDS DEPENDS ON LENGTH OF ACTUAL PATH			;AN000;
;POSITIONS SHOWN ARE FOR MAX PATH LENGTH ONLY					;AN000;

FS_SLASH2	      DB   0	   ;TRAILING BACKSLASH			     ;AN000;
FS_FNAME	      DB   8 DUP (0) ;FILENAME				       ;AN000;
FS_PER		      DB   0	   ;PERIOD END OF FILENAME		     ;AN000;
FS_EXT		      DB   3 DUP (0) ;FILENAME EXTENSION		       ;AN000;
FILESPEC	      ENDS	   ;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;
		      HEADER <PARSING WORKAREAS> ;AN000;
;	     $SALUT (4,14,19,36)   ;AN000;
CSEG	     SEGMENT PARA PUBLIC 'CODE' ;AN000;
	     ASSUME CS:CSEG,DS:CSEG,ES:CSEG,SS:CSEG ;AN000;

	     EXTRN SENDMSG:NEAR    ;USES MSG DESCRIPTOR TO DRIVE MESSAGE HANDLR ;AN000;
	     EXTRN SYSPARSE:NEAR   ;SYSTEM COMMAND LINE PARSER			;AN000;

	     EXTRN EXITFL:BYTE	   ;ERRORLEVEL RETURN CODE		      ;AN000;
	     EXTRN PATH1:BYTE	   ;FIRST POSITIONAL PARM		      ;AN000;
	     EXTRN PATH2:BYTE	   ;SECOND POSITIONAL PARM		      ;AN000;
	     EXTRN MSGNUM_PPARSE:WORD ;MESSAGE DESCRIPTOR FOR ALL PARSE ERRORS ;AN000;
	     EXTRN SUBLIST_24:WORD ;sublist for parse error messages	      ;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;

CURRENT_PARM DW   81H		   ;POINTER INTO COMMAND OF NEXT OPERAND	;AN000;
	     PUBLIC CURRENT_PARM   ;AN000;

ORDINAL      DW   0		   ;ORDINAL NUMBER OF WHICH PARM TO PARSE	;AN000;
	     PUBLIC ORDINAL	   ;AN000;

PARM_COUNT   DW   00H		   ;CURRENT PARM COUNT (USED TO TRICK "PARSER"	;AN000;
	     PUBLIC PARM_COUNT	   ;INTO PARSING FILE NAMES ENTERED FROM THE	;AN000;
				   ;KEYBOARD INSTEAD OF COMMAND LINE		;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;
	     HEADER <DOS COMMAND LINE PARSER CONTROL BLOCKS> ;AN000;

;INPUT PARAMETERS CONTROL BLOCK, POINTED TO BY ES:DI WHEN CALLING PARSER	;AN000;

	     PUBLIC PARMS	   ;LET LINK MAKE PARMS BLOCK ADDRESSABLE	;AN000;
PARMS	     LABEL BYTE 	   ;PARMS CONTROL BLOCK 			;AN000;
	     DW   PARMSX	   ;POINTER TO PARMS EXTENSION			;AN000;
	     DB   0		   ; NUMBER OF STRINGS (0, 1, 2)		;AN000;
				   ; NEXT LIST WOULD BE EXTRA DELIM LIST	;AN000;
				   ;  (,& WHITESPACE ALWAYS)			;AN000;
				   ; NEXT LIST WOULD BE EXTRA END OF LINE LIST	;AN000;
				   ;  (CR,LF,0 ALWAYS)				;AN000;

;SYSTEM PARSER PARAMETER EXTENSION CONTROL BLOCK				;AN000;
PARMSX	     LABEL BYTE 	   ;PARMS EXTENSION CONTROL BLOCK		;AN000;
	     DB   0,2		   ; MIN, MAX POSITIONAL OPERANDS ALLOWED	;AN000;
	     DW   CONTROL_POS	   ; DESCRIPTION OF POSITIONAL 1		;AN000;
	     DW   CONTROL_POS	   ; DESCRIPTION OF POSITIONAL 2		;AN000;

	     DB   0		   ; MAX SWITCH OPERANDS ALLOWED		;AN000;

	     DB   0		   ; MAX KEYWORD OPERANDS ALLOWED		;AN000;
				   ; THERE IS NO CONTROL BLOCK			;AN000;
				   ;  DEFINING KEYWORDS 			;AN000;

; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =		;AN000;
	     HEADER <POSITIONAL PARM DESCRIPTOR BLOCK> ;AN000;
;PARSER CONTROL BLOCK DEFINING THE ONLY POSITIONAL PARAMETER, OPTIONAL		;AN000;
;BOTH POSITIONAL PARAMETER ARE: 						;AN000;
;	[d:][path][filename[.ext]]						;AN000;

	     PUBLIC CONTROL_POS    ;LET LINK MAKE THIS ADDRESSABLE		;AN000;
CONTROL_POS  LABEL BYTE 	   ;FIRST POSITIONAL DESCRIPTOR FOR FILESPEC,	;AN000;
				   ; OPTIONAL					;AN000;
	     DW   0201H 	   ; CONTROLS TYPE MATCHED			;AN000;
				   ; SELECTED BITS: "FILESPEC" AND "OPTIONAL"	;AN000;

				   ; 8000H=NUMERIC VALUE, (VALUE LIST WILL BE CHECKED)	;AN000;
				   ; 4000H=SIGNED NUMERIC VALUE (VALUE LIST WILL BE  ;AN000;
				   ;   CHECKED) 				;AN000;
				   ; 2000H=SIMPLE STRING(VALUE LIST WILL BE CHECKED)  ;AN000;
				   ; 1000H=DATE STRING (VALUE LIST WON'T BE CHECKED)  ;AN000;
				   ; 0800H=TIME STRING (VALUE LIST WON'T BE CHECKED)  ;AN000;
				   ; 0400H=COMPLEX LIST (VALUE LIST WON'T BE CHECKED)  ;AN000;
				   ; 0200H=FILE SPEC (VALUE LIST WON'T BE CHECKED)  ;AN000;
				   ; 0100H=DRIVE ONLY (VALUE LIST WON'T BE CHECKED)  ;AN000;
				   ; 0080H=QUOTED STRING (VALUE LIST WON'T BE CHECKED)  ;AN000;
				   ; 0010H=IGNORE ":" AT END IN MATCH		;AN000;
				   ; 0002H=REPEATS ALLOWED			;AN000;
				   ; 0001H=OPTIONAL				;AN000;

	     DW   0001H 	   ;FUNCTION_FLAGS				;AN000;
				   ; 0001H=CAP RESULT BY FILE TABLE		;AN000;
				   ; 0002H=CAP RESULT BY CHAR TABLE		;AN000;
				   ; 0010H=REMOVE ":" AT END			;AN000;
	     DW   RESULT1	   ; RESULT BUFFER				;AN000;
	     DW   NOVALS	   ; VALUE LISTS				;AN000;
	     DB   0		   ; NUMBER OF KEYWORD/SWITCH SYNONYMS		;AN000;
				   ;   IN FOLLOWING LIST			;AN000;

; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =		;AN000;
;RESULTS CONTROL BLOCK FOR THE POSITIONAL PARAMETER				;AN000;
RESULT1      LABEL BYTE 	   ; BELOW FILLED IN FOR DEFAULTS		;AN000;
	     DB   5		   ; TYPE RETURNED: 0=RESERVED, 		;AN000;
				   ;	   1=NUMBER, 2=LIST INDEX,		;AN000;
				   ;	   3=STRING, 4=COMPLEX, 		;AN000;
				   ;	   5=FILESPEC, 6=DRIVE			;AN000;
				   ;	   7=DATE, 8=TIME			;AN000;
				   ;	   9=QUOTED STRING			;AN000;
RESULT_TAG   DB   0FFH		   ; MATCHED ITEM TAG				;AN000;
	     DW   0		   ;POINTER TO SYNONYM				;AN000;

RESULT_PTR1  DD   ?		   ; OFFSET OF STRING VALUE			;AN000;

; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =		;AN000;
;VALUE CONTROL BLOCK								;AN000;
NOVALS	     LABEL BYTE 	   ;AN000;
	     DB   0		   ; NUMBER OF VALUE DEFINITIONS (0 - 3)	;AN000;

; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;
	     HEADER <PARSER - ASK SYSPARM TO DECODE PARAMETERS> ;AN000;
;  $SALUT (4,4,9,36)		   ;AN000;
PARSER PROC NEAR		   ;AN000;
   PUBLIC PARSER		   ;AN000;

;INPUT: "CURRENT_PARM" = OFFSET TO NEXT PARM IN COMMAND STRING			;AN000;
;	"ORDINAL" = COUNT OF NEXT PARM TO PARSE 				;AN000;
;	PSP+81H = TEXT OF DOS COMMAND LINE PARMS STRING 			;AN000;

;OUTPUT: IF SPECIFIED, FIRST PARM GOES TO "PATH1".				;AN000;
;	 IF SPECIFIED, SECOND PARM GOES TO "PATH2".				;AN000;
;	 IF EITHER PARM MISSING, THEN "PATHn" STARTS WITH NUL CHAR.		;AN000;
;	 CARRY SET IF ERROR.							;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;

;  $SEARCH COMPLEX		   ;LOOP THRU COMMAND LINE			;AN000;
   JMP SHORT $$SS1
$$DO1:
				   ;LOOKING AT RETURN CODE FROM SYSPARSE...	;AN000;
       AND  AX,AX		   ;AN008; ;WERE THERE ANY ERRORS?			;AN000;
;  $EXITIF NE			   ;HAD A PROBLEM				;AN000;
   JE $$IF1
       CALL PARSE_ERROR 	   ;DISPLAY REASON FOR ERROR			;AN000;
       MOV  AL,01h		   ;AN000; ;pass back errorlevel ret code
       mov  ah,4ch
       int  21h
;  $ORELSE			   ;SINCE NO PROBLEM, SO FAR			;AN000;
   JMP SHORT $$SR1
$$IF1:
       MOV  ORDINAL,CX		   ;SAVE UPDATED COUNT				;AN000;
       MOV  CURRENT_PARM,SI	   ;REMEMBER HOW FAR I GOT			;AN000;
       MOV  BX,DX		   ;SET DATA BASE REG TO POINT TO		;AN000;
				   ;RESULT BUFFER OF THIS OPERAND		;AN000;

       MOV  SI,WORD PTR RESULT_PTR1 ;GET WHERE STRING IS PUT			;AN000;
				   ;GUESS, THIS IS THE FIRST PARM		;AN000;
       MOV  DI,OFFSET PATH1	   ;GET WHERE STRING IS TO GO			;AN000;

				   ;IF PARSING FILENAME INPUTED FROM KEYBOARD	;AN000;
				   ;THEN PARM_COUNT MUST = ZERO_PARM_CT = 0	;AN000;
       CMP  CX,PARM_COUNT	   ;IS THIS THE FIRST PARM OR JUST A FILENAME IN BUFFER ;AN000;

;      $IF  NE			   ;NO, MUST BE THE SECOND PARM 		;AN000;
       JE $$IF4
				   ;MADE A BAD GUESS, FIX IT			;AN000;
	   MOV	DI,OFFSET PATH2    ;CHANGE DEST TO WHERE SECOND STRING GOES	;AN000;
;      $ENDIF			   ;AN000;
$$IF4:

				   ;MOVE ASCIIZ STRING FROM DS:SI		;AN000;
				   ;WHERE COMMAND PARSE PUT IT			;AN000;
				   ;TO ES:DI WHERE COMP2 USES IT		;AN000;

;      $DO  COMPLEX		   ;AN000;
       JMP SHORT $$SD6
$$DO6:
	   STOSB		   ;PUT CHAR IN AL TO ES:DI			;AN000;
;      $STRTDO			   ;AN000;
$$SD6:
	   LODSB		   ;GET CHAR FROM DS:SI TO AL			;AN000;
	   CMP	AL,NUL		   ;IS THAT THE END OF STRING?			;AN000;
;      $ENDDO E 		   ;IF SO, QUIT 				;AN000;
       JNE $$DO6

;  $STRTSRCH			   ;AN000;
$$SS1:
       LEA  DI,PARMS		   ;ES:DI = PARSE CONTROL DEFINITON		;AN000;
       MOV  SI,CURRENT_PARM	   ;DS:SI = COMMAND STRING, NEXT PARM		;AN000;
       XOR  DX,DX		   ;RESERVED, INIT TO ZERO			;AN000;
       MOV  CX,ORDINAL		   ;OPERAND ORDINAL, INITIALLY ZERO		;AN000;
       CALL SYSPARSE		   ;LOOK AT DOS PARMS				;AN000;
				   ;AX=EXIT CODE				;AN000;
				   ;BL=TERMINATED DELIMETER CODE		;AN000;
				   ;CX=NEW OPERAND ORDINAL			;AN000;
				   ;SI=SET TO PAST SCANNED OPERAND		;AN000;
				   ;DX=SELECTED RESULT BUFFER			;AN000;
       CMP  AX,SYSPRM_EX_EOL	   ;IS THAT THE END OF THE PARMS?		;AN000;
				   ;IF NOT, LOOP BACK AND FIND OUT		;AN000;
				   ;WHAT THAT PARM IS				;AN000;
;  $ENDLOOP E			   ;END OF LIST 				;AN000;
   JNE $$DO1
       CLC			   ;RETURN FLAG FOR "NO ERROR"			;AN000;
;  $ENDSRCH			   ;FINISHED WITH DOS COMMAND LINE		;AN000;
$$SR1:
   RET				   ;RETURN TO CALLER				;AN000;
PARSER ENDP			   ;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;
   HEADER <PARSE_ERROR - DISPLAY REASON FOR PARSE ERROR> ;AN000;
PARSE_ERROR PROC NEAR		   ;AN000;

;INPUT: "FIRST_TIME" - IF NON-ZERO, FORCE ERROR CODE TO "TOO MANY PARMS"	;AN000;
;	 AX - ERROR NUMBER RETURNED FROM PARSE. 				;AN000;
;OUTPUT: APPROPRIATE ERROR MESSAGE IS DISPLAYED.				;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;

   MOV	MSGNUM_PPARSE,AX	   ;PASS MESSAGE NUMBER TO DESCRIPTOR		;AN000;
   MOV	DX,OFFSET MSGNUM_PPARSE     ;PASS MESSAGE DESCRIPTOR			 ;AN000;
   MOV	BX,CURRENT_PARM 							;AN000;
PE_BX:										;AN000;
   CMP	BX,SI			   ;are we past the point the parser stopped ?	;AN000;
   JAE	PE_BX_OK		   ;yes, we are done.				;AN000;
   CMP	BYTE PTR [BX],20H	   ;by-pass leading blanks			;AN000;
   JNE	PE_BX_OK								;AN000;
   INC	BX									;AN000;
   JMP	PE_BX									;AN000;
PE_BX_OK:									;AN000;
   MOV	SUBLIST_24.SUB_VALUE,BX 						;AN000;
;
;make a ASCIIZ string out of parameter
;
PE_LOOP:									;AN000;
   CMP	BX,SI			   ;are we past the point the parser stopped ?	;AN000;
   JAE	PE_OK			   ;yes, we are done.				;AN000;
   CMP	BYTE PTR [BX],20H	   ;check for spaec or end of line		;AN000;
   JE	PE_OK									;AN000;
   INC	BX									;AN000;
   JMP	PE_LOOP 								;AN000;
PE_OK:										;AN000;
   MOV	byte ptr [BX],00H	   ;end string with zero			;AN000;

   CALL SENDMSG 		   ;DISPLAY ERROR MESSAGE			;AN000;

   MOV	EXITFL,EXPAR		   ;ERRORLEVEL CODE TO "PARM ERROR"		;AN000;
   RET				   ;RETURN TO CALLER				;AN000;
PARSE_ERROR ENDP		   ;AN000;					;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =						;AN000;
CSEG ENDS			   ;AN000;
   END				   ;AN000;
