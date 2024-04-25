PAGE ,132 ;														   ;AN000;
TITLE MODECOM.ASM - RS232 SUPPORT FOR THE MODE COMMAND									   ;AN000;
															   ;AN000;
.XLIST															   ;AN000;
INCLUDE STRUC.INC													   ;AN000;
.LIST															   ;AN000;

;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป				   ;AN000;
;บ											  บ				   ;AN000;
															   ;AN000;
;  AC000 - P2852: Loading resident code trashed CX which was used as a shift
;		  count.

;  AC001 - P3540: PS/2 only parms other than baud not being treated properly.

;บ											  บ				   ;AN000;
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ				   ;AN000;
															   ;AN000;
															   ;AN000;
DISPLAY MACRO	MESSAGE 												   ;AN000;
	MOV	DX,OFFSET MESSAGE											   ;AN000;
	CALL	PRINTF													   ;AN000;
ENDM															   ;AN000;
															   ;AN000;
;------------------------------------------------------------------------						   ;AN000;
															   ;AN000;
ABORT	MACRO														   ;AN000;
	JMP	ENDIF01 												   ;AN000;
ENDM															   ;AN000;
															   ;AN000;
															   ;AN000;
;------------------------------------------------------------------------						   ;AN000;
															   ;AN000;
INCLUDE  common.stc	   ;contains the following structure								   ;AN000;
															   ;AN000;
															   ;AN000;
;parm_list_entry   STRUC		   ;used by parse_parameters and invoke 					   ;AN000;
;															   ;AN000;
;parm_type	      DB       bogus											   ;AN000;
;item_tag	      DB       0FFH											   ;AN000;
;value1 	      DW       bogus	   ;used only for filespecs and code page numbers				   ;AN000;
;value2 	      DW       bogus	   ;used only for filespecs and code page numbers				   ;AN000;
;keyword_switch_ptr   DW       0											   ;AN000;
;															   ;AN000;
;parm_list_entry   ENDS 												   ;AN000;
															   ;AN000;
															   ;AN000;
															   ;AN000;
;ษอออออออออออออออออออออออออออออออ E Q U A T E S ออออออออออออออออออออออออออออออออออออออออป				   ;AN000;
;บ											บ				   ;AN000;
															   ;AN000;

INCLUDE modequat.inc		 ;AN000;include definition of false, machine types

															   ;AN000;
AT_family   EQU 0FCH		 ;model byte for 286 boxes								   ;AN000;
DEV1	    EQU "1"              ;CHAR IN "COM1:"                                                                          ;AN000;
DEV2	    EQU "2"              ;CHAR IN "COM2:"                                                                          ;AN000;
DEV3	    EQU "3"              ;CHAR IN "COM3:"                                                                          ;AN000;
DEV4	    EQU "4"              ;CHAR IN "COM4:"                                                                          ;AN000;
OFFTO	    EQU modeto		 ;OFFSET OF MODETO IN RESIDENT CODE FROM SEGMENT					   ;AN000;
				 ; STORED AT 530H BY MODELOAD								   ;AN000;
not_specified	     EQU   0												   ;AN000;
parm_list	     EQU   [BP] 											   ;AN000;
;Roughrider  EQU 05		  ;sub model byte									    ;AN000;
SPACE	    EQU " "              ;BLANK CHARACTER                                                                          ;AN000;
;Trailboss   EQU 04		  ;sub model byte for 'Trailboss'                                                           ;AN000;
true	    EQU 0FFH													   ;AN000;
;Wrangler    EQU 0F8H		  ;primary model byte									    ;AN000;
															   ;AN000;
															   ;AN000;
;บ											  บ				   ;AN000;
;ศอออออออออออออออออออออออออออออออ  E Q U A T E S  ออออออออออออออออออออออออออออออออออออออออผ				   ;AN000;

				; BEGINNING OF PROC MODETO)								   ;AN000;
ROM    SEGMENT AT 0													   ;AN000;
    ORG    50H														   ;AN000;
VECT14H    LABEL  DWORD 	;RS232 CALL, POINTS TO PROC MODETO WHEN 						   ;AN000;
				; WHEN CODE IS RESIDENT 								   ;AN000;
    ORG    400H 													   ;AN000;
SERIAL_BASE	LABEL	WORD	;SERIAL PORT ADDRESSES									   ;AN000;
	ORG	530H													   ;AN000;
RESSEG	LABEL	DWORD		;VECTOR OF MODETO, WHEN RESIDENT							   ;AN000;
ROM	   ENDS 													   ;AN000;
PAGE															   ;AN000;
PRINTF_CODE	   SEGMENT  PUBLIC											   ;AN000;
	   ASSUME CS:PRINTF_CODE,DS:PRINTF_CODE 									   ;AN000;
															   ;AN000;
;ษอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออป				   ;AN000;
;บ											  บ				   ;AN000;
															   ;AN000;
EXTRN  B_item_tag:ABS		 ;see modepars										   ;AN000;
EXTRN  baud_19200:BYTE													   ;AN000;
EXTRN  busy_retry_active:ABS	 ;see invoke.asm									   ;AN000;
EXTRN  E_item_tag:ABS		 ;see modepars										   ;AN000;
EXTRN  eight_item_tag:ABS	 ;see modepars										   ;AN000;
EXTRN  ERR1:WORD													   ;AN000;
EXTRN  even_item_tag:ABS	 ;see modepars										   ;AN000;
EXTRN  error_retry_active:ABS	 ;see invoke.asm									   ;AN000;
EXTRN  five_item_tag:ABS	 ;see modepars										   ;AN000;
EXTRN  fourtyeighthundred_item_tag:ABS	   ;see modepars.asm								   ;AN000;
EXTRN  fourtyeighthundred_str:BYTE											   ;AN000;
EXTRN  illegal_device_ptr:WORD	  ;see modesubs.inc									   ;AN000;
EXTRN  INITMSG:BYTE,DEVICE:BYTE,PPARITY:BYTE,PDATA:BYTE,PSTOP:BYTE,PPARM:BYTE						   ;AN000;
EXTRN  keyword:ABS													   ;AN000;
EXTRN  machine_type:BYTE	 ;see 'rescode'                                                                            ;AN000;
EXTRN  mark_item_tag:ABS	 ;see modepars										   ;AN000;
EXTRN  MODELOAD:NEAR													   ;AN000;
EXTRN  MODETO:WORD													   ;AN000;
EXTRN  new_com_initialize:BYTE		     ;flag indicating that a PS/2 only parm was specified			   ;AC001;
EXTRN  nineteentwohundred_item_tag:ABS	     ;see modepars.asm								   ;AN000;
EXTRN  nineteentwohundred_str:BYTE	;see modepars.asm								   ;AN000;
EXTRN  ninetysixhundred_item_tag:ABS											   ;AC001;
EXTRN  ninetysixhundred_str:BYTE											   ;AN000;
EXTRN  no_retry_active:ABS	 ;see invoke.asm									   ;AN000;
EXTRN  noerror:byte		 ;boolean indicating success of previous actions					   ;AN000;
EXTRN  none_item_tag:ABS	 ;see modepars										   ;AN000;
EXTRN  onefifty_str:BYTE												   ;AN000;
EXTRN  oneten_item_tag:ABS	 ;see modepars.asm									   ;AN000;
EXTRN  oneten_str:BYTE													   ;AN000;
EXTRN  onefifty_item_tag:ABS	 ;see modepars.asm									   ;AN000;
EXTRN  one_point_five_item_tag:ABS     ;see modepars.asm								   ;AN000;
EXTRN  one_point_five_str:BYTE	  ;see modesubs.inc									   ;AN000;
EXTRN  p_item_tag:ABS		 ;see modepars.asm									   ;AN000;
EXTRN  parm_lst:BYTE		 ;parm_list_entry  max_pos_parms DUP (<>)						   ;AN000;
EXTRN  parms_form:BYTE													   ;AN000;
EXTRN  pstop_ptr:WORD		;see modedefs.inc									  ;AN000;
EXTRN  odd_item_tag:ABS 	 ;see modepars										   ;AN000;
EXTRN  one_item_tag:ABS 	 ;see modepars										   ;AN000;
EXTRN  PBAUD_ptr:WORD		 ;see 'modemes'                                                                            ;AN000;
EXTRN  PRINTF:NEAR													   ;AN000;
EXTRN  PARM1:BYTE,PARM2:BYTE,PARM3:BYTE,MODE:BYTE,FLAG:BYTE								   ;AN000;
;PARM1	DB	10 DUP(0)												   ;AN000;
;PARM2	DB	0													   ;AN000;
;PARM3	DB	0													   ;AN000;
;MODE	DB	0													   ;AN000;
;FLAG	DB	0													   ;AN000;
EXTRN  R_item_tag:ABS													   ;AN000;
EXTRN  RATEMSG:WORD	  ;CR,LF,"Invalid baud rate specified",BEEP,CR,LF,"$"                                              ;AN000;
EXTRN  ready_retry_active:ABS	 ;see invoke.asm									   ;AN000;
;EXTRN	RES_MODEFLAG:ABS	;RETRY FLAG IN RESIDENT CODE, (OFFSET FROM						   ;AN000;
EXTRN  res_com_retry_type:ABS	 ;retry type flag, displacement from address pointed to by 50:30 when code is resident, see rescode
EXTRN  seven_item_tag:ABS	  ;see modepars 									   ;AN000;
EXTRN  sixhundred_item_tag:ABS	   ;see modepars.asm									   ;AN000;
EXTRN  sixhundred_str:BYTE												   ;AN000;
EXTRN  six_item_tag:ABS       ;see modepars										   ;AN000;
EXTRN  space_item_tag:ABS     ;see modepars										   ;AN000;
EXTRN  submodel_byte:BYTE     ;see 'rescode'                                                                               ;AN000;
EXTRN  threehundred_item_tag:ABS     ;see modepars.asm									   ;AN000;
EXTRN  threehundred_str:BYTE												   ;AN000;
EXTRN  twelvehundred_item_tag:ABS     ;see modepars.asm 								   ;AN000;
EXTRN  twelvehundred_str:BYTE												   ;AN000;
EXTRN  twentyfourhundred_str:BYTE											   ;AN000;
EXTRN  twentyfourhundred_item_tag:ABS	  ;see modepars.asm								   ;AN000;
EXTRN  two_item_tag:ABS 	;see modepars										   ;AN000;
															   ;AN000;
															   ;AN000;
;บ											  บ				   ;AN000;
;ศอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออผ				   ;AN000;
															   ;AN000;
															   ;AN000;
;ษอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออป				   ;AN000;
;บ											  บ				   ;AN000;
															   ;AN000;
PUBLIC	baud_index		;holder of the index in the parm list of the baud rate requested			   ;AN000;
PUBLIC	data_bits_index 	;set by invoke										   ;AN000;
PUBLIC	MODECOM 													   ;AN000;
PUBLIC	parity_index		;set by invoke										   ;AN000;
PUBLIC	SERIAL_BASE		;Make available to RESCODE and MAIN							   ;AN000;
PUBLIC	retry_index		;make available to analyze_and_invoke							   ;AN000;
PUBLIC	setcom			;get it listed in the link map								   ;AN000;
PUBLIC	setto			;get it listed in link map for debugging						   ;AN000;
PUBLIC	stop_bits_index 	;set by invoke										   ;AN000;
															   ;AN000;
;บ											  บ				   ;AN000;
;ศอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออผ				   ;AN000;
															   ;AN000;
															   ;AN000;
															   ;AN000;
;ษอออออออออออออออออออออออออออออออออออ  D A T A	ออออออออออออออออออออออออออออออออออออออออออป				   ;AN000;
;บ											  บ				   ;AN000;
															   ;AN000;
															   ;AN000;
;THESE FOLLOWING BAUD RATES REPRESENT THE 1ST 2 CHAR									   ;AN000;
baud_index  DW	     TYPE parm_list_entry ;holder of the index into the parm list of the baud rate			   ;AN000;
data_bits_index DW   0	   ;holder of the index into the parm list of the data bits					   ;AN000;
parity_index	DW   0	   ;holder of the index into the parm list of the parity					   ;AN000;
stop_bits_index DW   0	   ;holder of the index into the parm list of the stop bits					   ;AN000;
retry_index	DW   0													   ;AN000;
															   ;AN000;
;INITMSG    DB	  CR,LF 												   ;AN000;
;	    DB	  "COM"                                                                                                    ;AN000;
;DEVICE     DB	  " "                                                                                                      ;AN000;
;	    DB	  ": "             ;SEPARATOR BLANK                                                                        ;AN000;
;PBAUD	    DB	  4 DUP(" ")                                                                                               ;AN000;
;	    DB	  ","    ;SEPARATOR                                                                                        ;AN000;
;PPARITY    DB	  "e"    ;DEFAULT IS EVEN PARITY                                                                           ;AN000;
;	    DB	  ","    ;SEPARATOR                                                                                        ;AN000;
;PDATA	    DB	  "7"    ;DEFAULT IS 7 DATA BITS PER BYTE                                                                  ;AN000;
;	    DB	  ","    ;SEPARATOR                                                                                        ;AN000;
;PSTOP	    DB	  "1"    ;DEFAULT FOR BAUD > 110, CHANGED TO 2 FOR 110                                                     ;AN000;
;	    DB	  ","    ;SEPARATOR                                                                                        ;AN000;
;PPARM	    DB	  " "                                                                                                      ;AN000;
;	    DB	  CR,LF,"$"    ;END OF 'INITMSG'                                                                           ;AN000;
															   ;AN000;
															   ;AN000;
;บ											  บ				   ;AN000;
;ศอออออออออออออออออออออออออออออออออออ  D A T A	ออออออออออออออออออออออออออออออออออออออออออผ				   ;AN000;
															   ;AN000;
															   ;AN000;
SUBTTL SET UP FOR SERIAL RETRY												   ;AN000;
PAGE															   ;AN000;
;
;
;-------------------------------------------------------------------------------
;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ									       ณ
;ณ SETTO								       ณ
;ณ -----								       ณ
;ณ									       ณ
;ณ  Set the resident retry flag to type of retry active for comx.	       ณ
;ณ									       ณ
;ณ  INPUT:  device - holds '1', '2', '3' or '4' (ascii) for x of lptx.         ณ
;ณ	    retry_index - holds index value for the parsed retry parameter.    ณ
;ณ	    resseg - holds offset of resident code in memory		       ณ
;ณ	    res_com_retry_type - holds offset of com retry flag in resident    ณ
;ณ	      code.							       ณ
;ณ									       ณ
;ณ									       ณ
;ณ  RETURN: pparm - set to 'P', 'B', 'R', 'E', or '-' for type of retry active.ณ
;ณ	    flag in resident code set					       ณ
;ณ									       ณ
;ณ									       ณ
;ณ  MESSAGES: none.							       ณ
;ณ									       ณ
;ณ									       ณ
;ณ  REGISTER								       ณ
;ณ  USAGE:	AL - new setting for resident flag. (see RESCODE.SAL for       ณ
;ณ		     format)						       ณ
;ณ		CL - shift bit count					       ณ
;ณ		ES - holds segment of resident code			       ณ
;ณ		BP - offset of parameter list				       ณ
;ณ		DI - offset of retry index within parameter list	       ณ
;ณ		DL - current resident flag setting			       ณ
;ณ									       ณ
;ณ									       ณ
;ณ  PSUEDO CODE:							       ณ
;ณ									       ณ
;ณ	SAVE REGISTERS							       ณ
;ณ	SET UP SEGMENT REGISTER AND BIT MASKS				       ณ
;ณ	IF <RETRY REQUESTED>						       ณ
;ณ	   SET UP PARAMETER LIST STRUCTURE				       ณ
;ณ	   SET BIT MASK FOR TYPE OF RETRY AND SET pparm TO PROPER LETTER       ณ
;ณ	   IF <RESIDENT CODE IS NOT LOADED>				       ณ
;ณ	      LOAD RESIDENT CODE					       ณ
;ณ	   ENDIF							       ณ
;ณ	   GET CURRENT com_lpt_retry_type				       ณ
;ณ	   SET AND STORE NEW com_lpt_retry_type 			       ณ
;ณ	ELSEIF <RESIDENT CODE ALREADY LOADED>				       ณ
;ณ	   GET CURRENT com_lpt_retry_type				       ณ
;ณ	   IF <POSITIONAL PARAMETER SPECIFIED>				       ณ
;ณ	      SET FLAG TO ZERO, SET pparm TO PROPER LETTER		       ณ
;ณ	   ELSE 							       ณ
;ณ	      SET pparm TO PROPER LETTER FOR CURRENT SETTING		       ณ
;ณ	   ENDIF							       ณ
;ณ	ELSE								       ณ
;ณ	   SET pparm TO '-'                                                    ณ
;ณ	ENDIF								       ณ
;ณ	RESTORE REGISTERS						       ณ
;ณ	RETURN								       ณ
;ณ									       ณ
;ณ									       ณ
;ณ									       ณ
;ณ  SIDE EFFECT: Loads resident code if it is needed and has not been loaded.  ณ
;ณ									       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
;
SETTO	 PROC	 NEAR													   ;AN663;
															   ;AN663;
      PUSH ES			;save registers 									   ;AN663;
      PUSH DI														   ;AN663;
      PUSH AX														   ;AN663;
      PUSH DX														   ;AN663;
															   ;AN663;
      XOR  AX,AX		;clear a reg										   ;AN663;
      MOV  ES,AX		;set to segment at 0									   ;AN663;
      MOV  CL,device													   ;AN663;
      AND  CL,07H													   ;AN663;
      DEC  CL														   ;AN663;
      SHL  CL,1 													   ;AN663;
      MOV  DH,11111100B 	;set bit mask to clear old flag setting 						   ;AN663;
      ROL  DH,CL													   ;AN663;
															   ;AN663;
      .IF <retry_index NE 0> THEN			;retry specified, set						   ;AN663;
							;  byte in resident code					   ;AN663;
	 MOV  DI,retry_index				;  to proper setting.						   ;AN663;
							;  if code is not loaded,					   ;AN663;
	 .SELECT					;  loaded it.							   ;AN663;
	 .WHEN <parm_list[DI].item_tag EQ P_item_tag>									   ;AN663;
	    MOV  AL,busy_retry_active											  ;AN663;
	    MOV  pparm,'p'                                                                                                 ;AN663;
	 .WHEN <parm_list[DI].item_tag EQ E_item_tag>									   ;AN663;
	    MOV  AL,error_retry_active											   ;AN663;
	    MOV  pparm,'e'                                                                                                 ;AN663;
	 .WHEN <parm_list[DI].item_tag EQ B_item_tag>									   ;AN663;
	    MOV  AL,busy_retry_active											   ;AN663;
	    MOV  pparm,'b'                                                                                                 ;AN663;
	 .WHEN <parm_list[DI].item_tag EQ R_item_tag>									   ;AN663;
	    MOV  AL,ready_retry_active											   ;AN663;
	    MOV  pparm,'r'                                                                                                 ;AN663;
	 .ENDSELECT													   ;AN663;
															   ;AN663;
	 .IF <<WORD PTR ES:resseg> EQ 0000H> THEN									   ;AN663;
	    PUSH  CX					;save shift count
	    CALL modeload				;load the resident code 					   ;AN663;
	    POP   CX					;restore shift count
	 .ENDIF 													   ;AN663;
															   ;AN663;
	 MOV  ES,ES:WORD PTR resseg[2]											   ;AN663;
	 MOV  DL,BYTE PTR ES:res_com_retry_type 									   ;AN663;
							;get the old setting						   ;AN663;
	 ROL  AL,CL													   ;AN663;
	 AND  DL,DH													   ;AN663;
	 OR   DL,AL													   ;AN663;
	 MOV  BYTE PTR ES:res_com_retry_type,DL 	;store the new setting						   ;AN663;
															   ;AN663;
      .ELSEIF <<WORD PTR ES:resseg> NE 0000H> THEN	;if code is loaded but no					   ;AN663;
							;  retry is specified then					   ;AN663;
	 MOV  ES,ES:WORD PTR resseg[2]											   ;AN663;
	 MOV  DL,BYTE PTR ES:res_com_retry_type 									   ;AN663;
															   ;AN663;
	 .IF <parms_form NE keyword>			;if 'NONE' was specified                                           ;AN663;
							;  with positional parameter					   ;AN663;
	    AND  DL,DH					;  set bits to zero						   ;AN663;
	    MOV  BYTE PTR ES:res_com_retry_type,DL									   ;AN663;
															   ;AN663;
	 .ELSE						;else update pparm with 					   ;AN663;
							;  current retry type						   ;AN663;
	    NOT  DH													   ;AN663;
	    AND  DL,DH													   ;AN663;
	    SHR  DL,CL													   ;AN663;
															   ;AN663;
	    .SELECT					;set pparm to proper letter					   ;AN663;
	    .WHEN <DL EQ no_retry_active>										   ;AN663;
	       MOV  pparm,'-'                                                                                              ;AN663;
	    .WHEN <DL EQ error_retry_active>										   ;AN663;
	       MOV  pparm,'e'                                                                                              ;AN663;
	    .WHEN <DL EQ busy_retry_active>										   ;AN663;
	       MOV  pparm,'b'                                                                                              ;AN663;
	    .WHEN <DL EQ ready_retry_active>										   ;AN663;
	       MOV  pparm,'r'                                                                                              ;AN663;
	    .ENDSELECT													   ;AN663;
															   ;AN663;
	 .ENDIF 													   ;AN663;
															   ;AN663;
      .ELSE						;no retry, no code resident					   ;AN663;
															   ;AN663;
	 MOV  pparm,'-'                                                                                                    ;AN663;
															   ;AN663;
      .ENDIF														   ;AN663;
															   ;AN663;
      POP  DX														   ;AN663;
      POP  AX			;restore registers									   ;AN663;
      POP  DI														   ;AN663;
      POP  ES														   ;AN663;
      RET														   ;AN663;
															   ;AN663;
SETTO ENDP														   ;AN663;



SUBTTL SET SERIAL PROTOCOL
PAGE

;------------------------------------------------------------------------------

;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
;ณ									       ณ
;ณ SETCOM								       ณ
;ณ ------								       ณ
;ณ									       ณ
;ณ									       ณ
;ณ									       ณ
;ณ  INPUT:								       ณ
;ณ									       ณ
;ณ									       ณ
;ณ									       ณ
;ณ									       ณ
;ณ									       ณ
;ณ									       ณ
;ณ  RETURN:								       ณ
;ณ									       ณ
;ณ									       ณ
;ณ									       ณ
;ณ  MESSAGES: none.							       ณ
;ณ									       ณ
;ณ									       ณ
;ณ  REGISTER								       ณ
;ณ  USAGE:								       ณ
;ณ									       ณ
;ณ									       ณ
;ณ  ASSUMPTIONS: All parms have been checked for validity as being possible andณ
;ณ		 supported on the machine.				       ณ
;ณ									       ณ
;ณ									       ณ
;ณ									       ณ
;ณ  SIDE EFFECT:							       ณ
;ณ									       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

SETCOM PROC    NEAR													   ;AN000;
															   ;AN000;
															 ;AN000;
MOV   BP,OFFSET parm_lst   ;address the parm list via parm_list which is [BP]						;AN000;
MOV    DI,baud_index	    ;DI=index into parm list of the baud rate entry						;AN000;

.SELECT 		   ;prepare AL for old init and CL for new init 						;AC001;

   .WHEN <parm_list[DI].item_tag EQ oneten_item_tag>									;AC001;
      MOV   AL,0													;AN000;
      MOV   CL,0
      MOV   pbaud_ptr,OFFSET oneten_str 										;AN000;
   .WHEN <parm_list[DI].item_tag EQ onefifty_item_tag> THEN							      ;AN000;
      MOV   AL,00100000B												;AN000;
      MOV   CL,1
      MOV   pbaud_ptr,OFFSET onefifty_str										;AN000;
   .WHEN <parm_list[DI].item_tag EQ threehundred_item_tag> THEN 						      ;AN000;
      MOV   AL,01000000B												;AN000;
      MOV   CL,2
      MOV   pbaud_ptr,OFFSET threehundred_str										;AN000;
   .WHEN <parm_list[DI].item_tag EQ sixhundred_item_tag> THEN							      ;AN000;
      MOV   AL,01100000B												;AN000;
      MOV   CL,3
      MOV   pbaud_ptr,OFFSET sixhundred_str										;AN000;
   .WHEN <parm_list[DI].item_tag EQ twelvehundred_item_tag> THEN						      ;AN000;
      MOV   AL,10000000B												;AN000;
      MOV   CL,4
      MOV   pbaud_ptr,OFFSET twelvehundred_str										;AN000;
   .WHEN <parm_list[DI].item_tag EQ twentyfourhundred_item_tag> THEN						      ;AN000;
      MOV   AL,10100000B												;AN000;
      MOV   CL,5
      MOV   pbaud_ptr,OFFSET twentyfourhundred_str									;AN000;
   .WHEN <parm_list[DI].item_tag EQ fourtyeighthundred_item_tag> THEN						      ;AN000;
      MOV   AL,11000000B												;AN000;
      MOV   CL,6
      MOV   pbaud_ptr,OFFSET fourtyeighthundred_str									;AN000;
   .WHEN <parm_list[DI].item_tag EQ ninetysixhundred_item_tag> THEN							;AN000;
      MOV   AL,11100000B												;AN000;
      MOV   CL,7
      MOV   pbaud_ptr,OFFSET ninetysixhundred_str									;AN000;
   .WHEN <parm_list[DI].item_tag EQ nineteentwohundred_item_tag> NEAR THEN   ;handle 19200 case if 19, 19200, 19.2 or 19.2K specified
      MOV   CL,8	      ;value for 19200 baud, no old equivalent							;AC001;
      MOV   pbaud_ptr,OFFSET nineteentwohundred_str									;AC001;

.ENDSELECT													     ;AC001;
;	   AL IS:  XXX00000 for the baud rate, CL has appropriate value for baud

MOV   DI,parity_index												  ;AN000;
.IF <parm_list[DI].item_tag EQ none_item_tag> THEN								  ;AN000;
   MOV PPARITY,"n"          ;set up message for no PARITY                                                       ;AN000;
   MOV	 BH,0		    ;AL already set properly for old init						  ;AN000;
.ELSEIF <parm_list[DI].item_tag EQ odd_item_tag> THEN								  ;AN000;
   MOV PPARITY,"o"          ;set up message for odd PARITY                                                       ;AN000;
   OR	 AL,08H 	    ;PUT THE 000XX000 BITS TO AL PARM WHERE XX=01 FOR PARITY=ODD			 ;AN000
   MOV	 BH,1		    ;new initialize									 ;AN000;
.ELSEIF <parm_list[DI].item_tag EQ space_item_tag> THEN 							   ;AN000;
   MOV PPARITY,"s"          ;set up message for space PARITY                                                       ;AN000;
   MOV	 BH,4		    ;SPACE not supported in old init							  ;AN000;
.ELSEIF <parm_list[DI].item_tag EQ mark_item_tag> THEN								  ;AN000;
   MOV PPARITY,"m"          ;set up message for mark PARITY                                                       ;AN000;
   MOV	 BH,3		    ;MARK parity not supported in old init						  ;AN000;
.ELSE			   ;not specified or asked for even							  ;AN000;
   MOV PPARITY,"e"          ;set up message for even PARITY, the default if not specified                        ;AN000;
   OR	 AL,18H 	    ;PUT THE 000XX000 BITS TO AL PARM WHERE XX=11 FOR PARITY=EVEN			 ;AN000
   MOV	 BH,2			 ;even parity for new initialize						 ;AN000;
.ENDIF														  ;AN000;

MOV   DI,data_bits_index											  ;AN000;
.IF <parm_list[DI].item_tag EQ five_item_tag> THEN								  ;AN000;
   MOV	 pdata,"5"            ;set up message for 5 bits                                                         ;AN000;
   MOV	 CH,0		      ;not old init for 5 data bits							  ;AN000;
.ELSEIF <parm_list[DI].item_tag EQ six_item_tag> THEN								  ;AN000;
   MOV	 pdata,"6"            ;set up message for 6 bits                                                         ;AN000;
   MOV	 CH,1		      ;no old init for 6 data bits							  ;AN000;
.ELSEIF <parm_list[DI].item_tag EQ eight_item_tag> THEN 							  ;AN000;
   MOV	 pdata,"8"            ;set up message for 8 bits                                                         ;AN000;
   OR	 AL,03H 	    ;IN THE 000000XX POSITION, SET XX=11 TO MEAN 8 DATA BITS				     ;AN000;
   MOV	 CH,3													  ;AN000;
.ELSE			      ;asked for 7 or skipped the parm and will get 7 as default			  ;AN000;
   OR	 AL,02H 	    ;IN THE 000000XX POSITION, SET XX=10 TO MEAN 7 DATA BITS				     ;AN000;
   MOV	 CH,2		      ;message already set up for 7 bits						  ;AN000;
.ENDIF														  ;AN000;

;PUT THE NO. STOP BITS TO AL PARM IN THE 00000X00 POSITION and BL for new init						     ;AN000
MOV   DI,stop_bits_index											  ;AN000;
MOV   BL,0		      ;assume stop bits was 1, message already set up				      ;AN000;
.SELECT
														  ;AN000;
   .WHEN <parm_list[DI].item_tag EQ two_item_tag>							;AN000;
      MOV   pstop,"2"         ;set up message for 2 stop bits                                         ;AN000;
      MOV   BL,1	      ;value for two or 1.5								    ;AN000;

   .WHEN <parm_list[DI].item_tag EQ one_point_five_item_tag>		     ;AN000;				  ;AN000;
      MOV   pstop_ptr,OFFSET one_point_five_str 	       ;set up message for 1.5 stop bits		  ;AN000;
      MOV   BL,1	      ;new init for 1.5 								;AN000;

   .WHEN <stop_bits_index EQ not_specified>		 ;if stop bits not specified			   ;AN000;
      MOV   DI,baud_index												;AC000;
      .IF <parm_list[DI].item_tag EQ oneten_item_tag>	  ;BAUD=110 SPECIFIED THEN SET DEFAULT STOP BITS TO TWO 	;AC000;
	 OR    AL,04H		  ;TURN ON BIT IN 00000X00 POSITION TO REQUEST 2 STOP BITS		 ;AN000;
	 MOV   pstop,"2"         ;set up message for 2 stop bits                                         ;AN000;
      .ENDIF			 ;FOR STOPBITS=1, LEAVE THAT BIT OFF, message already set by modecom	;AN000;

;  .OTHERWISE specified 1, everything set up

.ENDSELECT		   ;IF not 1.5 or two, already set up for 1						;AN000;
														  ;AN000;
.IF <new_com_initialize EQ true> THEN										     ;AC001;
   XOR	 AL,AL		   ;ask for no break									     ;AN000;
   MOV	 AH,4		   ;new set baud BIOS call								     ;AN001;
.ELSE			   ;old style com initialization						    ;AN000;	 ;AC001;
   XOR	 AH,AH		   ;AH=0 requests initialization								 ;AC001;
.ENDIF															 ;AC001;

														      ;AN000;
;SET DX PARM TO REQUEST WHICH COM DEVICE									   ;AN000;
 XOR   DX,DX													   ;AN000;
 MOV   DL,DEVICE	       ;device set by modepars in first_parm_case:					   ;AN000;
 AND   DL,07		       ;convert to binary 1 thru 4							   ;AN000;
 DEC   DL		       ;put in BIOS digestable 0 thru 3 						   ;AN000;
;	    AH ALREADY IS 0 or 4, WHICH REQUESTS								      ;AN000;
;	    INITIALIZATION OF THE RS232 									      ;AN000;
;	    ACCORDING TO PARMS IN AL and/or BX and CX.								      ;AN000;
 .IF <noerror EQ true> THEN											      ;AN000;
    INT 14H		       ;INIT THE RS232									      ;AN000;
;														      ;AN000;
;	    NOW THAT THE RS232 IS INITIALIZED,									      ;AN000;
    CALL    SETTO	 ;LOOK AT P PARM, MAYBE TIMEOUT TO BE RETRIED						      ;AN000;
;														      ;AN000;
    DISPLAY INITMSG	       ;TELL USER RS232 IS INITIALIZED							      ;AN000;
 .ENDIF 													      ;AN000;

     RET														   ;AN000;
SETCOM ENDP														   ;AN000;
															   ;AN000;
															   ;AN000;
SUBTTL															   ;AN000;
PAGE															   ;AN000;
															   ;AN000;
															   ;AN000;

MODECOM PROC	NEAR


       MOV    AL,DEVICE 	  ;AL= DEVICE ID OF "1", "2", "3" or "4"
       AND    AL,07		  ;TRANSLATE TO BINARY
       DEC    AL		  ;PUT IN ZERO BASE
       SAL    AL,1		  ;POSITION OF PORT ADDRESS WORD (2*AL)
       XOR    AH,AH		  ;CLEAR AH
       MOV    SI,AX
       XOR    AL,AL		  ;CLEAR AX
       PUSH   DS
       MOV    DS,AX
       CMP    WORD PTR DS:SERIAL_BASE[SI],0	  ;SEE IF THE COM PORT EXISTS
       POP    DS
       JNE    THEN01A
	  MOV	DI,0			  ;the device name is always the first parm					    ;AN000;
	  MOV	BP,OFFSET parm_lst   ;address the parm list via parm_list which is [BP] 				 ;AN000;
	  MOV	CX,parm_list[DI].value1 						    ;AN000;
	  MOV  illegal_device_ptr,CX
	  DISPLAY err1			 ;AN000;"Illegal device name - COMX"
	  MOV  noerror,false		  ;AN000;
	 ABORT
;
THEN01A:

;		     DEFINE DEFAULTS:
	 MOV PSTOP,"1"            ;ONE STOP BIT, OK FOR BAUD>110
	 MOV PDATA,"7"            ;7 DATA BITS
	 MOV PPARM,"-"            ;NO SERIAL TIMEOUT RETRY
;

;WE HAVE THE INFORMATION NEEDED TO INITIALIZE THE RS232 DEVICE
;
	 CALL SETCOM		  ;SET THE RS232 DEVICE
;
;    : ELSE ,SINCE COUNT WAS NOT BIG ENUF
ENDIF01:			 ;jump to here if the port does not exist
     RET			  ;RETURN TO MODE MAIN ROUTINE
MODECOM ENDP
PRINTF_CODE	ENDS
    END
