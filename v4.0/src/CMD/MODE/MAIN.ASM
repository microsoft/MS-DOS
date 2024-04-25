;m
	PAGE	,132			;
	TITLE	MODE COMMAND - MAIN PROCEDURE AND COMMAND PARSING
.XLIST
   INCLUDE STRUC.INC
.LIST
;.SALL


;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;  AC001 - P3976: Need to have all pieces of messages in MODE.SKL so have to
;		  implement the SYSGETMSG method of getting addressability to
;		  the pieces.  This means that the code does a SYSGETMSG call
;		  which returns a pointer (DS:SI) to the message piece.  The
;		  address is then put in the sublist block for the message
;		  being issued.

;  AN002 - P4011: Need to close all open handles before terminating and staying
;		  resident so don't eat into the total available handles for the
;		  system.
;บ											  บ
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ

INCLUDE  SYSMSG.INC

MSG_UTILNAME <MODE>


;ษอออออออออออออออออออออออออออออออ  E Q U A T E S  ออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

false	EQU	00H
STDIN	    EQU   0		       ;AN002;handle for standard input device
STDPRN	    EQU   4		       ;AN002;handle for standard printer device
TERMINATE EQU	4CH			;INT 21 "TERMINATE RETURNING CODE" FUNCTION
terminate_and_stay_resident    EQU   31H   ;INT 21 "terminate and remain resident"
truu	 EQU   0FFH

;บ											  บ
;ศอออออออออออออออออออออออออออออออ  E Q U A T E S  ออออออออออออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออ  S T R U C T U R E S  ออออออออออออออออออออออออออออออออออออป
;บ											  บ


;บ											  บ
;ศอออออออออออออออออออออออออออออ  S T R U C T U R E S  ออออออออออออออออออออออออออออออออออออผ


	PAGE
PRINTF_CODE SEGMENT PUBLIC
	ASSUME	CS:PRINTF_CODE,DS:PRINTF_CODE,SS:PRINTF_CODE


;ษอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

PUBLIC	 main
PUBLIC	 SYSDISPMSG
PUBLIC	 SYSGETMSG


;บ											  บ
;ศอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

EXTRN	analyze_and_invoke:NEAR
EXTRN	get_machine_type:NEAR		      ;get model and sub-model bytes
EXTRN	initialize_sublists:NEAR	  ;see display.asm
EXTRN	move_destination:ABS		  ;location of res code after it has been moved
EXTRN	noerror:BYTE
EXTRN	parse_parameters:NEAR
EXTRN	PRINTF:NEAR
EXTRN	rescode_length:ABS	       ;length in paragraphs of the resident code
EXTRN	stay_resident:BYTE	       ;boolean indicating just loaded resident code see 'rescode'

;บ											  บ
;ศอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออออออออ  D A T A	ออออออออออออออออออออออออออออออออออออออออออป
;บ											  บ


	DB	"The MODE command "
	DB	"--------------------------------------------------------------"

;บ											  บ
;ศอออออออออออออออออออออออออออออออออออ  D A T A	ออออออออออออออออออออออออออออออออออออออออออผ

;ษออออออออออออออออออออออออออออ	P R O C E D U R E S  อออออออออออออออออออออออออออออออออออออป
;บ											  บ

close_handles  PROC  NEAR		  ;AN002;close all standard device handles
					  ;AN002;
MOV   AH,3EH				  ;AN002;
					  ;AN002;
.FOR BX = STDIN TO STDPRN		  ;AN002;
   INT	 21H				  ;AN002;
.NEXT BX				  ;AN002;
					  ;AN002;
RET					  ;AN002;
					  ;AN002;
close_handles  ENDP			  ;AN002;

;บ											  บ
;ศออออออออออออออออออออออออออออ	P R O C E D U R E S  อออออออออออออออออออออออออออออออออออออผ


;
;-------------------------------------------------------------------------------

MSG_SERVICES <MSGDATA>		    ;define message service data area

MSG_SERVICES <LOADmsg,GETmsg,DISPLAYmsg,CHARmsg,NUMmsg,INPUTmsg>	;AC001;
MSG_SERVICES <mode.cla,mode.clb,mode.cl1,mode.cl2>    ;class B is for messages > 30
;;RPS  MSG_SERVICES <mode.cl1,mode.cl2>


main  PROC  NEAR

CALL  SYSLOADMSG		    ;load the message text
.IF NC THEN			    ;IF messages loaded successfully THEN
   CALL  get_machine_type
   CALL  initialize_sublists
   CALL  parse_parameters
   .IF <noerror EQ truu> THEN	       ;no problems parsing so continue
      CALL  analyze_and_invoke		  ;semantically analyze the parms and invoke appropriate routine
   .ENDIF

   MOV	AH,TERMINATE		       ;assume won't stay resident
   .IF <noerror EQ false> THEN
      MOV  AL,1 		       ;had a problem somewhere
   .ELSE
      .IF   <stay_resident EQ truu> THEN
	 CALL  close_handles		  ;close all standard devices;AN002;
	 MOV  DX,move_destination
	 MOV  CL,4			  ;4 right shifts = divide by 16
	 SAR  DX,CL			  ;DX=offset of start of resident code in paragraphs
					  ;SET END OF RESIDENT CODE FOR "terminate and remain resident"
					  ;TO first usable
	 ADD   DX,rescode_length	  ;BYTE OF PROGRAM segment PREFIX
	 MOV  AH,terminate_and_stay_resident
      .ENDIF
      MOV  AL,0 		       ;all went well
   .ENDIF
.ELSE				       ;ABORT

   CALL  SYSDISPMSG			  ;display some "I'm crashing" message

.ENDIF


INT	21H			 ;TERMINATE RETURNING ERRORLEVEL INDICATING success
RET

include msgdcl.inc

main  ENDP

PRINTF_CODE ENDS
	END
