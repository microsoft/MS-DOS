

TITLE	 SELECT Stub			;AN000;
SUBTTL	 SELSTUB.ASM			;AN000;

PAGE	 60,132 			;AN000;

	INCLUDE SYSMSG.INC			;AN000;
	MSG_UTILNAME <SELECT>			;AN000;

CODE	 SEGMENT PARA  PUBLIC 'CODE'            ;AN000;
	 ASSUME  CS:code			;AN000;
	 ASSUME  DS:code			;AN000;
	 ASSUME  ES:NOTHING			;AN000;
	 ASSUME  SS:NOTHING			;AN000;

	 ORG	 100H				;AN000;
MAIN	 PROC	 FAR				;AN000;
BEGIN:	 JMP	 A0				;AN000;

prognm	 DB	 "SELECT.EXE",0      ;AN000; EXEC this program

execparm DW	0		;AN000; environment string
	 DW	 80H		 ;AN000; command string offset
comseg	 DW	 (?)		 ;AN000; command string segment
	 DW	 5CH		 ;AN000; use the FCB's from this program
seg1	 DW	 (?)		 ;AN000; .
	 DW	 6CH		 ;AN000; use the FCB's from this program
seg2	 DW	 (?)		 ;AN000; .

enter	 equ	 13		 ;AN000;ENTER key
escape	 equ	 27		 ;AN000;ESC key

	 EVEN			 ;AN000;
stck	 DB	 255 DUP(0)	 ;AN000;stack
stck_beg DB	 0		 ;AN000;

A0:				 ;AN000;
	 MOV	SP,OFFSET stck_beg ;AN000;setup local stack

	 CALL	LOAD_MSG	   ;AN000;
	 MOV	AX,10		 ;AN000;insert SELECT diskette in drive A:
	 CALL	DISPLAY_MSG	 ;AN000;

AGN:				 ;AN000;
	 XOR	 AH,AH		 ;AN000;get ENTER key
	 INT	 16H		 ;AN000;
	 CMP	 AL,ESCAPE	 ;AN000;if ESC, then exit
	 JE	 EXIT		 ;AN000;
	 CMP	 AL,ENTER	 ;AN000;if ENTER
	 JE	 INPOK		 ;AN000; then continue
	 MOV	 AX,11		 ;AN000;else, sound BELL
	 CALL	 DISPLAY_MSG	 ;AN000;
	 JMP	 AGN		 ;AN000;try again
INPOK:				 ;AN000;
	 CALL	 CHECK_DISKETTE  ;AN000;ensure INSTALL diskette in drive
	 JNC	 DSKTOK 	 ;AN000;if so, continue
	 CALL	 CLEAR_SCREEN	 ;AN032;SEH
	 MOV	 AX,11		 ;AN000;else, sound BELL
	 CALL	 DISPLAY_MSG	 ;AN000;
	 MOV	 AX,10		 ;AN032;SEH  flash msg on screen to insert SELECT diskette
	 CALL	 DISPLAY_MSG	 ;AN032;     if user has not inserted it
	 JMP	 AGN		 ;AN000;try again
DSKTOK: 			 ;AN000;
	 CALL	 CLEAR_SCREEN	 ;AN000;

; Issue SETBLOCK to free memory

	 PUSH	 CS		 ;AN000; restore ES pointing to this segment
	 POP	 ES		 ;AN000; .
	 LEA	 AX,endofcode	 ;AN000; get the address of the program end
	 MOV	 BL,16		 ;AN000; get the paragraph size
	 DIV	 BL		 ;AN000; get the number of paragraphs
	 INC	 AL		 ;AN000; round up to next paragraph
	 SUB	 AH,AH		 ;AN000; clear high remainder
	 MOV	 BX,AX		 ;AN000; set up call
	 MOV	 AH,4AH 	 ;AN000; setblock function code
	 INT	 21H		 ;AN000; issue function to free memory

; EXEC the main program

	 MOV	 AX,CS		 ;AN000; get our segment
	 MOV	 DS,AX		 ;AN000;
	 MOV	 comseg,AX	 ;AN000; put in parameter blocks
	 MOV	 seg1,AX	 ;AN000; .
	 MOV	 seg2,AX	 ;AN000; .
	 MOV	 DX,OFFSET prognm ;AN000; get a pointer to the program name
	 MOV	 BX,OFFSET execparm ;AN000; get a pointer to the program parms
	 MOV	 AX,4BH*256	 ;AN000; get function code - load & execute
	 INT	 21H		 ;AN000; exec SELECT
EXIT:				 ;AN000;
	 MOV	 AX,4C00H	 ;AN000;
	 INT	 21H		 ;AN000;
	 RET			 ;AN000;

endofcode DB	?		 ;AN000;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Message Retriever code inserted at this point....
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MSG_SERVICES <MSGDATA>		 ;AN000;
MSG_SERVICES <NOVERCHECKmsg, DISPLAYmsg, LOADmsg>;AN000;
MSG_SERVICES <SELECT.CLA,SELECT.CLB>;AN000;
MSG_SERVICES <SELECT.CL1,SELECT.CL2>;AN000;

;****************************************************************************
;
;   DISPLAY_MSG:  Call the message retriever to display a message.
;
;   INPUT:
;	AX = message number
;
;   OUTPUT:
;	If CY = 1, there was an error displaying the message.
;	If CY = 0, there were no errors.
;
;   OPERATION:
;
;****************************************************************************
DISPLAY_MSG PROC NEAR		 ;AN000;
    MOV  BX, -1 		       ;AN000; HANDLE -1 ==> USE ONLY DOS FUNCTION 1-12
    MOV  SI, 0			       ;AN000; SUBSTITUTION LIST
    MOV  CX, 0			       ;AN000; SUBSTITUTION COUNT
    MOV  DL, 00 		       ;AN000; DOS INT21H FUNCTION FOR INPUT 0==> NO INPUT
    MOV  DI, 0			       ;AN000; INPUT BUFFER IF DL = 0AH
    MOV  DH,  -1		       ;AN000; MESSAGE CALL -1==> UTILITY MESSAGE
    CALL SYSDISPMSG		       ;AN000;
    RET 			       ;AN000;
DISPLAY_MSG ENDP		       ;AN000;

;****************************************************************************
;
;   LOAD_MSG:  Load the message
;
;   INPUT:
;	None
;
;   OUTPUT:
;	None
;
;****************************************************************************
LOAD_MSG PROC  NEAR		       ;AN000;
    CALL SYSLOADMSG		       ;AN000;
    RET 			       ;AN000;
LOAD_MSG ENDP			       ;AN000;

;****************************************************************************
;
;   CLEAR_SCREEN:  Clear the screen and move cursor to top of display
;
;   INPUT:
;	None
;
;   OUTPUT:
;	None
;
;****************************************************************************
CLEAR_SCREEN PROC NEAR		       ;AN000;

	 MOV	 CX,0000H	 ;AN000;0,0 upper left of scroll
	 MOV	 DX,184FH	 ;AC032;SEH  24,79 lower right of screen
	 MOV	 BH,07H 	 ;AN000;normal attribute
	 MOV	 AX,600H	 ;AN000;scroll screen
	 INT	 10H		 ;AN000;

	 MOV	 DX,0000H	 ;AN000;move cursor to 0,0
	 XOR	 BH,BH		 ;AN000;display page
	 MOV	 AH,2		 ;AN000;move cursor
	 INT	 10H		 ;AN000;

	 RET			 ;AN000;

CLEAR_SCREEN ENDP		 ;AN000;

;****************************************************************************
;
;   CHECK_DISKETTE:  Check for INSTALL diskette in drive A:
;
;   INPUT:
;	None
;
;   OUTPUT:
;	CY = 0	correct diskette in drive
;	CY = 1	incorrect diskette in drive
;
;****************************************************************************
CHECK_DISKETTE PROC NEAR	 ;AN000;
	 PUSH	 DS		 ;AN000;
	 PUSH	 CS		 ;AN000;
	 POP	 DS		 ;AN000;
	 MOV	 DX,OFFSET dta	 ;AN000;set new dta
	 MOV	 AH,1AH 	 ;AN000;
	 INT	 21H		 ;AN000;
	 MOV	 DX,OFFSET prognm ;AN000;search for this file
	 XOR	 CX,CX		 ;AN000;search attribute
	 MOV	 AH,4EH 	 ;AN000;find first matching file
	 INT	 21H		 ;AN000;
	 POP	 DS		 ;AN000;
	 RET			 ;AN000;
CHECK_DISKETTE ENDP		 ;AN000;

DTA	 DB	 ?		 ;AN000;start of dummy DTA for find first

include msgdcl.inc

MAIN	 ENDP			 ;AN000;
CODE	 ENDS			 ;AN000;
	 END	 BEGIN		 ;AN000;

