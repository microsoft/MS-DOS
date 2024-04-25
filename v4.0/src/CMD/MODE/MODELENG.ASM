PAGE ,132 ;
TITLE MODELENG.ASM - VARIOUS SERVICE ROUTINES

;This module contains procedures:
;MODELENG - convert 3 digit or less ASCII string to binary number
;GET_MACHINE_TYPE - determine the machine type based on model byte and sub model byte

.XLIST
   INCLUDE STRUC.INC
.LIST
;.SALL

;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;  AX001 - P4031: Was allowing rate and delay settings on ATs that did not have
;		  the functionality in the BIOS.  Have to check specifically for
;		  a date of 11/15/85 or later.

;  AX002 - P4543: Add VAIL and SNOWMASS to legal choices for 19200 baud

;บ											  บ
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ



;ษอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

PUBLIC	 get_machine_type
PUBLIC	 MODELENG

;บ											  บ
;ศอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออผ

;ษออออออออออออออออออออออออออออออออ  M A C R O S  อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

BREAK MACRO destination 	 ;AN001;

JMP   ENDCASE_&destination	 ;AN001;

ENDM				 ;AN001;

;บ											  บ
;ศออออออออออออออออออออออออออออออออ  M A C R O S  อออออออออออออออออออออออออออออออออออออออออผ


;ษออออออออออออออออออออออออออออออออ E Q U A T E S อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

AT_or_XT286_or_PS2_50_or_PS2_60  EQU   0FCH  ;AN000;primary model byte for all 286 based machines
BIOS_date			 EQU   ES:[DI]	   ;used for accessing parts of the BIOS date ;AN001;
INTCONV 			 EQU   48	   ;CONVERT ASCII TO NUMERIC
model_byte_AH			 EQU   AH
return_system_configuration	 EQU   0C0H	   ;INT 15H subfunction
system_descriptor_table 	 EQU   ES:[BX]
system_services 		 EQU   15H	   ;ROM BIOS call
XT2				 EQU   0FBH  ;AN000;model byte for 2nd release of XT

INCLUDE  modequat.inc

;บ											  บ
;ศอออออออออออออออออออออออออออออออ  E Q U A T E S  ออออออออออออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออ  S T R U C T U R E S  ออออออออออออออออออออออออออออออออออออป
;บ											  บ

BIOS_date_struc   STRUC 	       ;in form mm/dd/yy  ;AN001;
   month    DW	  ?					  ;AN001;
   slash1   DB	  ?					;AN001;
   day	    DW	  ?					;AN001;
   slash2   DB	  ?					;AN001;
   year     DW	  ?					;AN001;
BIOS_date_struc   ENDS					;AN001;


system_descriptor    STRUC
   length_of_descriptor    DW	 bogus			;number of bytes in the descriptor table
   primary_model_byte	   DB	 bogus
   secondary_model_byte    DB	 bogus
system_descriptor    ENDS

;บ											  บ
;ศอออออออออออออออออออออออออออออ  S T R U C T U R E S  ออออออออออออออออออออออออออออออออออออผ


ROM	SEGMENT AT 0F000H

ORG   0FFF5H				     ;location of date ROM BIOS for the release was written ;AN001;
date_location  LABEL WORD		     ;AN001;

ORG   0FFFEH
model_byte	LABEL	BYTE

ROM	ENDS



PRINTF_CODE   SEGMENT PUBLIC
	 ASSUME CS:PRINTF_CODE,DS:PRINTF_CODE



;ษอออออออออออออออออออออออออออออออออออ  D A T A	ออออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

HUNDRED  DB    100
TEN	 DB    10


;บ											  บ
;ศอออออออออออออออออออออออออออออออออออ  D A T A	ออออออออออออออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

EXTRN	 machine_type:BYTE	       ;see 'rescode.sal'
EXTRN	 submodel_byte:BYTE	       ;see 'rescode.sal'

;บ											  บ
;ศอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออผ


MODELENG PROC	 NEAR
;
;INPUT:BP HAS ADDR OF PARM FIELD IN DATA SPACE (DS:)
;
    MOV    BL,0 		  ;INIT BL TO 0
;   IF THIS PARAMETER IS A THREE DIGIT NUMBER,
    CMP    BYTE PTR DS:[BP]+2,0 ;LOOK AT THIRD DIGIT
    JE	   ENDIF01
    CMP    BYTE PTR DS:[BP]+2,20H		;see if third char is a blank
    JE	   ENDIF01		;IF there is a third digit THEN
;
      MOV    AL,DS:[BP]     ;GET FIRST DIGIT
      SUB    AL,INTCONV     ;CONVERT TO INT
      MUL    HUNDRED	    ;HUNDREDTHS PLACE
      ADD    BL,AL	    ;ADD TO BL
      INC    BP 	    ;BUMP TO NEXT DIGIT
    ENDIF01:	;ENDIF THIS PARAMETER IS A THREE DIGIT NUMBER
    MOV    AL,DS:[BP]	    ;GET NEXT DIGIT
    SUB    AL,INTCONV	    ;CONVERT TO INT
       JNC    ENDIF02
       MOV     BL,0FFH	  ;encountered an error so put a bogus number in the sum
    ENDIF02:
    MUL    TEN		    ;TENS PLACE
    ADD    BL,AL	    ;ADD TO BL
    INC    BP		    ;GO TO NEXT DIGIT
    MOV    AL,DS:[BP]	    ;GET NEXT DIGIT
    SUB    AL,INTCONV	    ;CONVERT TO INT
    ADD    BL,AL	    ;ADD TO BL
    RET
MODELENG ENDP


ascii_to_int   PROC  NEAR  ;input: AX=2 digit ascii number ;AN001;
			   ;output: BL has binary value 	   ;AN001;
			   ;assume: no overflow or underflow	   ;AN001;

    PUSH   AX		    ;the MUL destroys AH		   ;AN001;
    SUB    AL,INTCONV	    ;CONVERT high order digit to binary    ;AN001;
    MUL    TEN		    ;TENS PLACE 			   ;AN001;
    MOV    BL,AL	    ;ADD TO BL				   ;AN001;
    POP    AX							   ;AN001;
    MOV    AL,AH	    ;AL=low order digit 		   ;AN001;
    SUB    AL,INTCONV	    ;CONVERT TO binary			   ;AN001;
    ADD    BL,AL	    ;ADD TO BL				   ;AN001;
    RET 							   ;AN001;

ascii_to_int   ENDP						   ;AN001;


;------------------------------------------------------------------------------

;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ
;ณ GET_MACHINE_TYPE
;ณ ----------------
;ณ
;ณ  Get the machine type and store for future reference.
;ณ
;ณ
;ณ  INPUT: none
;ณ
;ณ
;ณ  RETURN: A scalar value indicating the type of machine is stored in
;ณ	    'machine_type'.
;ณ
;ณ
;ณ  MESSAGES: none
;ณ
;ณ
;ณ
;ณ  REGISTER
;ณ  USAGE AND
;ณ  COMVENTIONS: AX - general usage
;ณ		 BX - used to address the system descriptor table
;ณ
;ณ
;ณ
;ณ
;ณ
;ณ  ASSUMPTIONS: DS has segment of MODE's data area
;ณ
;ณ
;ณ  SIDE EFFECT: ES is changed.
;ณ
;ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ


get_machine_type  PROC	  NEAR



PUSH  ES
PUSH  BX			       ;will be used to point to 'system descriptor table'
MOV   AH,return_system_configuration
INT   15H
.IF   NC	     ;IF the call was handled successfully
   MOV	 AH,system_descriptor_table.secondary_model_byte
   MOV	 submodel_byte,AH				;save submodel byte
   MOV	 AH,system_descriptor_table.primary_model_byte
.ELSE
   MOV	 AX,ROM 		;get addressability to the model byte
   MOV	 ES,AX
   MOV	 AH,ES:model_byte
.ENDIF

.IF <model_byte_AH EQ AT_or_XT286_or_PS2_50_or_PS2_60> THEN    ;AN000;may have a submodel byte, check it

   .IF <submodel_byte EQ PS2Model60> THEN	;AN000;
      MOV   AH,PS2Model60			;AN000;
   .ELSEIF <submodel_byte EQ VAIL> OR		;AN000;
   .IF <submodel_byte EQ PS2Model50> THEN	;AN000;
      MOV   AH,PS2Model50			;AN000;
   .ELSEIF <submodel_byte EQ XT286> THEN	;AN000;
      MOV   AH,XT286				;AN000;
   .ELSEIF <submodel_byte EQ AT3> THEN		;AN000;
      MOV   DI,OFFSET date_location		       ;ES:DI=>BIOS date (BIOS_date EQU ES:[DI])	       ;AN001;

;     CASE BIOS_date=											;AN001;

;	 later than 1985:										;AN001;

	       MOV   AX,BIOS_date.year			 ;AX=ASCII form of BIOS date year	       ;AN001;
	       CALL  ascii_to_int			 ;BL=binary form of BIOS date year		;AN001;
	       .IF <BL GT 85> THEN			 ;IF AT built in 86 or later		  ;AN001;

	    MOV   AH,AT4										;AN001;
	    BREAK 0											;AN001;

	       .ENDIF											;AN001;

;	 1985, on 11/15:	       ;BL already has year from above check				;AN001;

	       .IF <BL EQ 85> AND									;AN001;
	       .IF <BIOS_date.month EQ "11"> AND                                                        ;AN001;
	       .IF <BIOS_date.day EQ "51"> THEN       ;"51" is the word form of "15"                    ;AN001;

	    MOV   AH,AT4										;AN001;
	    BREAK 0											;AN001;

	       .ENDIF											;AN001;

;	 otherwise:		       ;internal release of third version of AT 				       ;AN001;

	    MOV   AH,AT3										;AN001;


       ENDCASE_0:											;AN001;

   .ELSEIF <submodel_byte EQ AT2> THEN		;AN000;
      MOV   AH,AT2				;AN000;
   .ENDIF					;AN000;IF none of the above AH has correct value for AT1 (FC)
.ELSEIF <model_byte_AH EQ XT2> THEN		;AN000;
   MOV	 AH,PCXT				;AN000;no difference from XT1
.ENDIF						;AN000;

MOV   DS:machine_type,AH	 ;AH was set as result of getting the system configuration or during the IF.
POP   BX
POP   ES

RET			;RETURN TO MODE MAIN ROUTINE
get_machine_type  ENDP
PRINTF_CODE   ENDS
    END
