PAGE ,132 ;
TITLE MODESCRN.ASM - SCREEN SUPPORT FOR THE MODE COMMAND

.XLIST
INCLUDE STRUC.INC
.LIST

INCLUDE  COMMON.STC	;definitions of message sublist blocks ;AC001;

;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป				   ;AN000;
;บ											  บ				   ;AN000;
															   ;AN000;
;  AC000 - P3200: Was displaying a message that Sam Nunn had deleted from the
;		  USA.MSG file because it looked like a common message.  Now
;		  I use a different (better) message.  It was "Invalid paramters",
;		  is now "Function not supported - ????".

;  AX001 - P3976: Need to have all pieces of messages in MODE.SKL so have to
;		  implement the SYSGETMSG method of getting addressability to
;		  the pieces.  This means that the code does a SYSGETMSG call
;		  which returns a pointer (DS:SI) to the message piece.  The
;		  address is then put in the sublist block for the message
;		  being issued.

;  AX002 - P5159: Need to use get extended country call (6523) to get the yes
;     7-14-88	  no answer

;บ											  บ				   ;AN000;
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ				   ;AN000;

;ษออออออออออออออออออออออออออออออออ  M A C R O S  อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

BREAK	MACRO	X
   JMP	   endcase_&X
ENDM


SCRN	MACRO COMMAND,MOD
		      MOV    AH,COMMAND ;REQUEST FUNCTION OF SCREEN BIOS
 IFNB <MOD>
		      MOV    AL,MOD	;SET MODE TO SCREEN
 ENDIF
		      INT    10H	;CALL BIOS SCREEN HANDLER
;
     ENDM
;
DISPLAY 	MACRO	MSG
IFNB <MSG>
	MOV	DX,OFFSET MSG
ENDIF
	CALL	PRINTF
ENDM


SET_LEFT_SHIFT_LIMIT	MACRO
	LOCAL	LIMIT_SET
	ASSUME	DS:ROM_BIOS
;
	PUSH	DS
	PUSH	AX
	MOV	AX,ROM_BIOS_SEG
	MOV	DS,AX
	CMP	DS:MACHINE_TYPE,JUNIOR		;IF this machine is a Junior THEN
	JNE	LIMIT_SET
	  MOV	BYTE PTR CS:LEFT_LIMIT,JR_LEFT_LIMIT	;USE THE JUNIOR'S LEFT LIMIT
	LIMIT_SET:
	POP	AX
	POP	DS
;
	ASSUME	DS:PRINTF_CODE
;
ENDM

set_submessage_ptr   MACRO submessage,message ;PUT pointer to "subMESSAGE" into submessage pointer field of "message".

MOV   AX,submessage			     ;AX=message number 		;AN001;
MOV   DH,utility_msg_class		     ;DH=message class=utility class	;AN001;
CALL  SYSGETMSG 			     ;DS:SI=>message piece				  ;AN001;
MOV   BP,OFFSET sublist_&message	     ;address the sublist control block ;AN001;
MOV   [BP].sublist_off,SI		     ;the sublist now points to the desired message piece ;AN001;
ENDM												  ;AN001;


;---------------------------------------------------------------------------
;   SET_UP_FOR_PRINTF
;PRINTF depends on DS containing the segment that the messages are in, so if
;DS is being used to address data areas elsewhere it needs to be temporarily
;set to the message file segment.
;---------------------------------------------------------------------------
;
SET_UP_FOR_PRINTF	MACRO

	PUSH	DS		;SAVE DS
	PUSH	CS
	POP	DS		;DS NOW HAS MESSAGE SEGMENT
;
ENDM

;----------------------------------------------------------------------------
;   REPLACE_DS
;Replace the contents DS had before the PRINTF call. Assume that DS was pushed.
;-----------------------------------------------------------------------------

REPLACE_DS	MACRO

	POP	DS
;
ENDM

;บ											  บ
;ศออออออออออออออออออออออออออออออออ  M A C R O S  อออออออออออออออออออออออออออออออออออออออออผ

CURRENT_VIDEO_STATE EQU 15 ;REQUEST TO BIOS SCREEN TO RETURN SCREEN STATE
SET_SCREEN_MODE EQU 0	      ;REQUEST TO BIOS SCREEN TO SET SCREEN MODE
COL40	 EQU	1	 ;FLAG BIT TO REQUEST 40 COL
COL80	 EQU	2	 ;FLAG BIT TO REQUEST 80 COL
CNT4	 EQU	4	 ;COUNT NO. TIMES TO DISPLAY "NUMBERS" FOR 40COL
CNT8	 EQU	8	 ;COUNT NO. TIMES TO DISPLAY "NUMBERS" FOR 80COL
FORTY	 EQU	40	 ;SCREEN WIDTH
MONO_MODE EQU	7	 ;MONOCHROME SCREEN MODE
no	 EQU	 0	;AC002;value to compare with when user responds with no character
NOEXIT	  EQU	 0		  ;EXIT SWITCH VALUE TO REPEAT LOOP
EXIT	  EQU	 1		  ;EXIT SWITCH VALUE TO LEAVE LOOP
YES	  EQU	  1	;AC002;value AX will be if user types yes character ("y", "s", "j" etc)
;





;	 OFFSETS INTO VIDEO TABLE, AT 40:90
SHIFCT40 EQU	02H		  ;SHIFT COUNT FOR 40 COL
SHIFCT80 EQU	012H		  ;SHIFT COUNT FOR 80 COL
SHIFCTGR EQU	022H		  ;SHIFT COUNT FOR GRAPHICS
CR	    EQU    13		  ;CARRIAGE RETURN
LF	    EQU    10		  ;LINE FEED
BEEP	    EQU    7		  ;SOUND THE AUDIBLE ALARM
LOWERCASE   EQU    20H		  ;ADD THIS TO UPPER, GET LOWER CASE
TRUE	EQU	0FFH

RIGHT_LIMIT EQU    01	  ;SAME FOR ALL TYPES OF MACHINES
JUNIOR	    EQU    0FDH 	  ;MACHINE TYPE SIGNITURE FOR PC JUNIOR
JR_LEFT_LIMIT  EQU 031H 	  ;LEFT LIMIT FOR SCREEN SHIFT ON PC JUNIOR
;
EGA_SIG 	EQU	0AA55H	  ;SIGNITURE FOR THE EGA CARD
;
ROM_BIOS  SEGMENT AT 0F000H
	ORG	0FFFEH
;
	MACHINE_TYPE	LABEL	BYTE		;MACHINE TYPE BURNED IN ROM
;
ROM_BIOS  ENDS

ROM_BIOS_SEG	EQU	0F000H
;
SIGNITURE  SEGMENT AT 0C000H			;SEGMENT OF EGA AREA
	ORG	0
SIGWORD DW	?			;SIGNITURE OF THE EGA IS STORED HERE IF THE CARD IS PRESENT
SIGNITURE	ENDS
;
PRINTF_CODE   SEGMENT PUBLIC
     ASSUME CS:PRINTF_CODE,DS:PRINTF_CODE
;


;ษอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

PUBLIC	 HANDLE_40_OR_80	 ;make available to "ANALYZE_AND_INVOKE"
PUBLIC	 SHIFT_SCREEN		 ;make available to "ANALYZE_AND_INVOKE"


;บ											  บ
;ศอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

EXTRN CANT_SHIFT:WORD	    ;CR,LF,"Unable to shift screen",BEEP,EOM
EXTRN PRINTF:NEAR		;interface to message service ROUTINE
EXTRN SCRNTAB:NEAR		;LOADS VIDEO INIT TABLE RETURNING POINTER TO IT
;
EXTRN PARM1:BYTE,PARM2:BYTE,PARM3:BYTE,MODE:BYTE,FLAG:BYTE
;PARM1	DB	10 DUP(0)
;PARM2	DB	0
;PARM3	DB	0
;MODE	DB	0
;FLAG	DB	0
EXTRN NEW_VIDEO_PARMS_SEGMENT:WORD
EXTRN	NOERROR:BYTE		  ;INDICATE IF AN ERROR OCCURED YET
ENDPARM EQU	MODE
EXTRN	ALT_SELECT:ABS		;INT 10 FUNCTION GET MONITOR TYPE
EXTRN	EGA_INFO:ABS		;INT 10 FUNCTION GET INFO
EXTRN	COLOR_ON_IT:ABS 	;INT 10 RETURN FOR COLOR MONITOR HOOKED TO EGA
;
LEFT_LIMIT  DB	   02EH 	  ;SCREEN SHIFT LEFT LIMIT, MAY BE Revised
;
SWITCH	  DB	 0		  ;LOOP CONTROLLER
;AC000;OK	 DB	1		 ;INDICATOR OF VALID REQUEST:
;				     1=BAD, 0=GOOD
;
EXTRN L_item_tag:ABS			  ;see MODEpars.asm	  ;AN000;
EXTRN R_item_tag:ABS			  ;see MODEpars.asm	  ;AN000;
EXTRN T_item_tag:ABS			  ;see MODEpars.asm	  ;AN000;

EXTRN RIGHTMOST:WORD	;message number for "rightmost 9",EOM	;AC001;
EXTRN LEFTMOST:WORD    ;message number for "leftmost 0",EOM	;AC001;
;AC001;EXTRN LFTM_OR_RGHTM_PTR:WORD
EXTRN SHIFT_MSG:WORD	    ;CR,LF,"Do you see the ...",CR,LF,EOM ;AX000;
;AC000;EXTRN MSGI:WORD	  ;CR,LF,"Invalid parameters",BEEP,CR,LF,"$"	 ;AX000;
EXTRN NUMBERS:WORD   ;"0123456789"				  ;AX000;
EXTRN LEFT:WORD 		;message number for "left",EOM	  ;AC001;
EXTRN RIGHT:WORD		;message number for "right",EOM   ;AC001;
;AC001;EXTRN LEFT_OR_RIGHT_PTR:WORD	      ;PART OF MESSAGE "Unable to shift screen ..."
EXTRN sublist_cant_shift:BYTE	 ;definition of submessage ;AC001;
EXTRN sublist_shift_msg:BYTE	 ;definition of submessage ;AC001;
EXTRN SYSGETMSG:NEAR		 ;used to get the address of a message part ;AC001;
EXTRN utility_msg_class:ABS	 ;input for sysgetmsg	;AC001;


;บ											  บ
;ศอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออผ



;----------------------------------------------------------------------------


HANDLE_40_OR_80   PROC	NEAR	    ;AN000;

;      SCREEN WIDTH IN BL
;
       SCRN   CURRENT_VIDEO_STATE,0 ;GET CURRENT SCREEN MODE
       MOV    DS:MODE,AL	    ;STORE CURRENT MODE
;      IF THE REQUEST WAS FOR 40 COL,
       CMP    BL,FORTY		  ;COMPARE WITH BL, OUTPUT FROM 'MODELENG'
       JNE    ELSE01
;
;AC000;  MOV	OK,0		    ;INDICATE A LEGAL FUNCTION DONE
;	 CASE	current mode =

;	    0,
;	    2,
;	    5,
;	    6,
;	    7,
;	    11:

			   .IF <DS:mode EQ 0> OR
			   .IF <DS:mode EQ 2> OR
			   .IF <DS:mode EQ 5> OR
			   .IF <DS:mode EQ 6> OR
			   .IF <DS:mode EQ 7> OR
			   .IF <DS:mode EQ 011H> THEN
	       MOV   DS:MODE,0		 ;SWITCH TO 40 COL, BW
	       BREAK 0
			   .ENDIF

;	    1,
;	    3,
;	    4,
;	    12,
;	    13:

			   .IF <DS:mode EQ 1> OR
			   .IF <DS:mode EQ 3> OR
			   .IF <DS:mode EQ 4> OR
			   .IF <DS:mode EQ 012H> OR
			   .IF <DS:mode EQ 013H> THEN
	       MOV   DS:MODE,1		 ;SWITCH TO 40 COL, COLOR
	       BREAK 0
			   .ENDIF


	 ENDCASE_0:


	 SCRN	SET_SCREEN_MODE,DS:MODE ;SWITCH TO 40 COL
;      ELSE ,SINCE REQUEST NOT FOR 40 COL,
       JMP    SHORT ENDIF01
ELSE01:
;    : : IF REQUEST FOR 80 COL
	 CMP	BL,80
	 JNE	ENDIF02
;
;AC000;    MOV	  OK,0		    ;INDICATE A LEGAL FUNCTION DONE
  ;	   CASE   current mode =

  ;	      0,
  ;	      2,
  ;	      5,
  ;	      6,
  ;	      7,
  ;	      11:

			     .IF <DS:mode EQ 0> OR
			     .IF <DS:mode EQ 2> OR
			     .IF <DS:mode EQ 5> OR
			     .IF <DS:mode EQ 6> OR
			     .IF <DS:mode EQ 7> OR
			     .IF <DS:mode EQ 011H> THEN
		 MOV   DS:MODE,2	   ;SWITCH TO 80 COL, BW
		 BREAK 1
			     .ENDIF

  ;	      1,
  ;	      3,
  ;	      4,
  ;	      12,
  ;	      13:

			     .IF <DS:mode EQ 1> OR
			     .IF <DS:mode EQ 3> OR
			     .IF <DS:mode EQ 4> OR
			     .IF <DS:mode EQ 012H> OR
			     .IF <DS:mode EQ 013H> THEN
		 MOV   DS:MODE,3	   ;SWITCH TO 80 COL, COLOR
		 BREAK 1
			     .ENDIF


	   ENDCASE_1:

	   SCRN   SET_SCREEN_MODE,DS:MODE
;    : : ENDIF ,END REQUEST FOR 80 COL
ENDIF02:
;    : ENDIF ,END REQUEST FOR 40 COL
ENDIF01:


RET		     ;AN000;

HANDLE_40_OR_80   ENDP			  ;AN000;


;------------------------------------------------------------------------------


SHIFT_SCREEN	PROC  NEAR		      ;AN000;shift the screen

;    DO SHIFT UNTIL HE CAN SEE END CHAR
     MOV    SWITCH,NOEXIT	  ;SET TO REPEAT NEXT LOOP
DO01:
;    : IF second PARM (sd) IS AN "R"?
       CMP   DS:PARM2,R_item_tag		;AC000;
       JE    SKIP03				;IT'S AN R SO TRY TO SHIFT RIGHT
       JMP   ELSE03				;NOT AN R SO CHECK FOR L
;
       SKIP03:
;AC000;  MOV	CS:OK,0 	  ;INDICATE A LEGAL FUNCTION DONE
	 SCRN	CURRENT_VIDEO_STATE,0		;CHECK CURRENT VIDEO MODE
	 CMP	AL,MONO_MODE			;IF mode >= mono THEN must be EGA mono so ...
;	 $IF	GE
	 JNGE $$IF1
;AC001;    MOV	LEFT_OR_RIGHT_PTR,OFFSET RIGHT	  ;YELL BECAUSE CAN'T SHIFT AN EGA OR MONO
	   set_submessage_ptr right,cant_shift	  ;set up message sublist with pointer to "right"
	   DISPLAY	CANT_SHIFT		  ;YELL BECAUSE CAN'T SHIFT AN EGA OR MONO
;	 $ELSE	LONG				  ;JUMP PAST SHIFT LOOP
	 JMP $$EN1
$$IF1:
;
CHECK_FOR_EGA:					;SEE IF SCREEN IS HOOKED TO EGA
	MOV	AX,SIGNITURE			;GET TO SEGMENT OF SIGNITURE WORD
	MOV	ES,AX				;ADDRESS THROUGH ES
	CMP	WORD PTR ES:SIGWORD,EGA_SIG	;IF EGA card being used THEN
	JNE	TRY_TO_SHIFT
	  MOV	  AH,ALT_SELECT   ;AH GETS INT FUNCTION SPECIFIER
	  MOV	  BL,EGA_INFO	  ;SPECIFY IN BL THE OPTION OF THE FUNCTION OF INT 10 WE
	  MOV	  BH, COLOR_ON_IT ;protect against RT PC problem
	  not	  bh		  ; masm 5.0 won't allow "not color_on_it"
	  INT	  10H		  ;RETURN MONITOR TYPE HOOKED TO EGA IN BH
	  CMP	  BH,COLOR_ON_IT   ;IF COLOR HOOKED TO EGA THEN
	  JNE	  TRY_TO_SHIFT
;AC001;     MOV  LEFT_OR_RIGHT_PTR,OFFSET RIGHT  ;  YELL BECAUSE CAN'T SHIFT AN EGA
	    set_submessage_ptr right,cant_shift    ;set up message sublist with pointer to "right"
	    DISPLAY	 CANT_SHIFT
	    JMP  ELSE05 			 ;  JUMP PAST SHIFT LOOP
;
TRY_TO_SHIFT:
	 CALL	SCRNTAB 	  ;LOAD VIDEO TABLE IN WORK AREA
;	     DS NOW POINTS TO THE SEGMENT WHERE THE VIDEO TABLE WAS MOVED TO.
;	     BX HAS THE NEW OFFSET OF THE VIDEO TABLE

	  CMP	  BYTE PTR DS:[BX][SHIFCT40],RIGHT_LIMIT	;IF haven't shifted max right THEN
	  JG	  SHIFT_RIGHT
	    SET_UP_FOR_PRINTF
;AC001;     MOV 	LEFT_OR_RIGHT_PTR,OFFSET RIGHT
	    set_submessage_ptr right,cant_shift    ;set up message sublist with pointer to "right"
	    DISPLAY	CANT_SHIFT		;"Unable to shift screen right"
	    REPLACE_DS
	    JMP 	ELSE05
  SHIFT_RIGHT:
	 MOV	AL,DS:[BX][SHIFCT40]	;GET SHIFT COUNT FOR 40COL
	 SUB	AL,1		      ;SHIFT IT LEFT 1
	 MOV	DS:[BX][SHIFCT40],AL	;STORE IT BACK
	 MOV	AL,DS:[BX][SHIFCT80]	;GET SHIFT COUNT FOR 80COL
	 SUB	AL,2		      ;SHIFT LEFT 2
	 MOV	DS:[BX][SHIFCT80],AL	;STORE IT BACK
	 MOV	AL,DS:[BX][SHIFCTGR]	;GET GRAPHICS SHIFT COUNT
	 SUB	AL,1		      ;SHIFT LEFT 1
	 MOV	DS:[BX][SHIFCTGR],AL	;STORE IT BACK
;    : ELSE ,SINCE PARM2 IS NOT AN "R"
       JMP ENDIF03
ELSE03:
;    : : IF THIS CHAR IS AN "L"?
	 CMP DS:PARM2,L_item_tag		;AC000;
	 JE  SKIP05				;L WAS SPECIFIED SO TRY TO SHIFT LEFT
	 JMP	ELSE05				;WASN'T "L" OR "R" SO DONT'T TRY TO SHIFT
;	     SINCE IT IS "L",
;
	 SKIP05:
;AC000;    MOV	  CS:OK,0		  ;INDICATE A LEGAL FUNCTION DONE
	   SCRN CURRENT_VIDEO_STATE,0		;CHECK CURRENT VIDEO MODE
	   CMP	AL,MONO_MODE			;IF mode >= mono THEN must be EGA or mono so ...
	   JB	CHK_FOR_EGA
;AC001;      MOV	LEFT_OR_RIGHT_PTR,OFFSET LEFT	  ;YELL BECAUSE CAN'T SHIFT AN EGA
	     set_submessage_ptr left,cant_shift    ;set up message sublist with pointer to "left" ;AC001;
	     DISPLAY	CANT_SHIFT
	     JMP	ELSE05				  ;JUMP PAST SHIFT LOOP
;
	   CHK_FOR_EGA: 				;SEE IF SCREEN IS HOOKED TO EGA
	     MOV	AX,SIGNITURE			;GET TO SEGMENT OF SIGNITURE WORD
	     MOV	ES,AX				;ADDRESS THROUGH ES
	     CMP	WORD PTR ES:SIGWORD,EGA_SIG	;IF EGA card being used THEN
	     JNE	TRY_TO_SHIFT_LEFT
	       MOV	  AH,ALT_SELECT   ;AH GETS INT FUNCTION SPECIFIER
	       MOV	  BL,EGA_INFO	  ;SPECIFY IN BL THE OPTION OF THE FUNCTION OF INT 10 WE
	       INT	  10H		  ;RETURN MONITOR TYPE HOOKED TO EGA IN BH
	       CMP	  BH,COLOR_ON_IT   ;IF COLOR HOOKED TO EGA THEN
	       JNE	  TRY_TO_SHIFT_LEFT
;AC001; 	 MOV	LEFT_OR_RIGHT_PTR,OFFSET LEFT	;  YELL BECAUSE CAN'T SHIFT AN EGA
		 set_submessage_ptr left,cant_shift    ;set up message sublist with pointer to "left"  ;AC001;
		 DISPLAY	CANT_SHIFT
		 JMP	ELSE05				;  JUMP PAST SHIFT LOOP
;
TRY_TO_SHIFT_LEFT:
	   CALL   SCRNTAB	  ;LOAD VIDEO TABLE IN WORK AREA
;	     DS NOW POINTS TO THE SEGMENT OF THE RESIDENT CODE,
;	     WHERE THE VIDEO TABLE WAS MOVED TO.
;
	   SET_LEFT_SHIFT_LIMIT 	;SET LIMIT TO SUIT MACHINE TYPE
;
	   MOV	  AL,BYTE PTR DS:[BX][SHIFCT40] ;AL=current horizontal sync position
	   CMP	  AL,CS:LEFT_LIMIT		;IF haven't shifted max left THEN
	     JL 	  SHIFT_LEFT
	     SET_UP_FOR_PRINTF
;AC001;      MOV	LEFT_OR_RIGHT_PTR,OFFSET LEFT
	     set_submessage_ptr left,cant_shift    ;set up message sublist with pointer to "left"  ;AC001;
	     DISPLAY	CANT_SHIFT
	     REPLACE_DS
	     JMP	ELSE05
  SHIFT_LEFT:
	   MOV	  AL,DS:[BX][SHIFCT40]	;GET SHIFT COUNT 40COL
	   ADD	  AL,1		      ;SHIFT RIGHT ONE
	   MOV	  DS:[BX][SHIFCT40],AL	;STORE IT BACK
	   MOV	  AL,DS:[BX][SHIFCT80]	;GET SHIFT COUNT 80COL
	   ADD	  AL,2		      ;SHIFT RIGHT 2
	   MOV	  DS:[BX][SHIFCT80],AL	;STORE IT BACK
	   MOV	  AL,DS:[BX][SHIFCTGR]	;GET GRAPHICS COUNT
	   ADD	  AL,1		      ;SHIFT RIGHT 8 PIXELS
	   MOV	  DS:[BX][SHIFCTGR],AL	;STORE IT BACK
;    : : ELSE ,SINCE CHAR IS NEITHER "R" NOR "L", QUIT
	 JMP	SHORT ENDIF05
;	 $ENDIF ;EGA or MONO
$$EN1:
ELSE05:
	   MOV	  CS:SWITCH,EXIT  ;REQUEST LOOP BE TERMINATED
;    : : ENDIF ,END IS THIS CHAR AN "L"? TEST
ENDIF05:
;    : ENDIF END, IS PARM2 AN "R"? TEST
ENDIF03:

PUBLIC	 ENDIF03

       MOV    AX,CS		  ;RESTORE THIS SEG
       MOV    DS,AX		  ; TO DS
;    LEAVE IF THE EXIT SWITCH IS SET
;AC001;     CMP    SWITCH,EXIT
;AC001;     JE	   ENDDO01
     .IF <switch NE exit> THEN NEAR
;
       SCRN CURRENT_VIDEO_STATE,0
       MOV    DS:MODE,AL	  ;SAVE CURRENT MODE
;	     LEAVING CURRENT MODE IN AL,
       SCRN   SET_SCREEN_MODE	  ;RESET IN CURRENT MODE
;    : IF THIS IS "T"
       CMP    DS:PARM3,T_item_tag	  ;AC000;
       JNE    ELSE06
;
;	 DECIDE WHICH QUESTION TO DISPLAY...
;    : : IF REQUESTED FUNCTION IS "R"
	 CMP	 DS:PARM2,R_item_tag	     ;AC000;
	 JNE	 ELSE08

;AC001;    MOV	   LFTM_OR_RGHTM_PTR,OFFSET LEFTMOST
	   set_submessage_ptr leftmost,shift_msg   ;set up message sublist with pointer to "leftmost"  ;AC001;
;    : : ELSE ,SINCE WAS NOT "R"
	 JMP	 SHORT ENDIF08
ELSE08:
;AC001;    MOV	   LFTM_OR_RGHTM_PTR,OFFSET RIGHTMOST
	   set_submessage_ptr rightmost,shift_msg   ;set up message sublist with pointer to "rightmost"  ;AC001;
;    : : ENDIF END FUNCTION IS "R"? TEST
ENDIF08:

;	 decide how many times to display "0123456789"
	 OR	DS:MODE,01H	  ;SET UP TO TEST FOR COLOR OR B/W
	 MOV	CX,CNT8 	  ;(GUESS IT IS 80COL) SET LOOP CTR TO 8
;    : : IF 40 COL?
	 CMP	DS:MODE,COL40
	 JNE	ENDIF07
;
	   MOV	  CX,CNT4	  ;(FIX ABOVE GUESS) SET LOOP CTR TO 4
;    : : ENDIF ,END IS IT 40 COL? TEST
ENDIF07:
;
	 .REPEAT
	    SCRN   SET_SCREEN_MODE,DS:MODE		;clear the screen
	    PUSH  CX		    ;save loop counter
	    DO02:		      ;DO UNTIL LINE IS DISPLAYED across entire screen
	       DISPLAY NUMBERS	      ;DISPLAY 0123456789
;	    ENDDO WHEN CNT IN CX = 0
	    LOOP    DO02
	    DISPLAY   SHIFT_MSG     ;AN000;DISPLAY QUESTION, msg services will do the keyboard input, see modedefs.inc
	    MOV    DL,AL	    ;AC002;DL=character user entered
	    MOV   AX,6523H	    ;AN002;yes no check get extended error
	    INT   21H		    ;AN002;AX returned with indication of yes or no
	    POP   CX		    ;restore loop counter
	 .UNTIL <AX EQ yes> OR
	 .UNTIL <AX EQ no>
;    : : IF RESPONSE IS "Y"
	 CMP	AL,YES
	 JNE	ENDIF09
	   MOV	  SWITCH,EXIT	  ;TERMINATE THE LOOP
;    : : ENDIF ,END IS RESPONSE "N"? TEST
ENDIF09:
;    : ELSE ,SINCE "T" NOT SPECIFIED
       JMP    SHORT ENDIF06
ELSE06:
	 MOV	SWITCH,EXIT	  ;TERMINATE THE LOOP
;    : ENDIF ,END IS THIS "T"? TEST
ENDIF06:
;    LEAVE IF EXIT SWITCH IS SET
     CMP    SWITCH,EXIT
     JE     ENDDO01
;
;    ENDDO GO BACK AND SHIFT MORE
     JMP    DO01
     .ENDIF
ENDDO01:
;
;    IF NO LEGAL FUNCTIONS DONE,
;AC000;;    CMP    OK,0
;AC000;     JZ	   ENDIF10

;AC000;       DISPLAY MSGI		 ;FUSS ABOUT ILLEGAL PARAMETERS
;    ENDIF ,END ARE NO LEGAL FUNCTIONS DONE? TEST
;AC000;ENDIF10:
     RET			  ;RETURN TO MODE MAIN ROUTINE
SHIFT_SCREEN	ENDP			;AN000;
PRINTF_CODE    ENDS
	 END
