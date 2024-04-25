;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	CASERVIC.ASM
;
;
;
;	CAS SERVICES....FROM TSUISRD.ASM
;
;
;	DATE:	 MAY 15, 1987
;
;
;
;	;AN004;  for PTM 1064 temporary fix until the CASSFAR.LIB
;		 is fixed.  The HELP routines of CAS, zero out the
;		 frequency value.
;
;	;AN005;  The help text comes up blank.	No checking was done
;		 for invalid helps (HRD_ERROR & HRD_DOSERROR).	Now,
;		 there is checking added to PCHLPRD_CALL!
;
;	;AN006;  for PTM 1756 - added error checking for wrong diskette
;		 when help accessed. JW
;
;	;AN007;  for PTM 1810 - during a help request processing, any error
;		 caused a problem because the manage_help routine would
;		 try to remove a help panel which had not been displayed.
;
;	;AN008;  for PTM 2191 - added code to display selected option when
;		 selection is made by numeric input.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.ALPHA					;AN000;
	INCLUDE    STRUC.INC		;AN000;
	INCLUDE    MACROS.INC		;AN006;JW
	INCLUDE    PANEL.MAC		;AN000;
	INCLUDE    PAN-LIST.INC 	;AN000;
	INCLUDE    SELECT.INC		;AN000;
	INCLUDE    CASTRUC.INC		;AN000;
	INCLUDE    DATA.MAC		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Variable(s) for Conditional Assembly
;
;    These conditional assembly values are declared and set in an external
;    file and included during assembly.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	INCLUDE CASVAR.INC	;AN000;
				;
	EXTRN	DISK_PANEL:WORD ;AN000;
	EXTRN	SEARCH_FILE:WORD;AN000;
	EXTRN	FK_ENT:BYTE	;AN000;
	EXTRN	FK_ENT_LEN:ABS	;AN000;
	EXTRN	E_FILE_ATTR:ABS ;AN000;
	EXTRN	E_RETURN:ABS	;AN000;
	EXTRN	ACTIVE:BYTE	;AN000;
	EXTRN	ALTERNATE:BYTE	;AN000;
	EXTRN	LCD:ABS 	;AN000;
	EXTRN	E_RETURN:ABS	;AN000;
	EXTRN	ERROR_ACTIVE:BYTE;AN000;
	EXTRN	MEM_SIZE:WORD	;AN024;
				;;;;;;;;;
	EXTRN	DISPLAY_MESSAGE_ROUTINE:FAR ;AN024;
	EXTRN	HOOK_INT_24:FAR 	;AN000;
	EXTRN	RESTORE_INT_24:FAR	;AN000;
	EXTRN	FIND_FILE_ROUTINE:FAR	;AN000;
	EXTRN	GET_FUNCTION_CALL:NEAR	;AN000;
	EXTRN	HANDLE_CHILDREN:NEAR	;AN000;
	EXTRN	PREPARE_PANEL_CALL:NEAR ;AN000;
	EXTRN	ALLOCATE_HELP:FAR	;AN024;
	EXTRN	DEALLOCATE_HELP:FAR	;AN024;
	EXTRN	ALLOCATE_LVB:FAR	;AN024;
	EXTRN	DEALLOCATE_LVB:FAR	;AN024;

;
; Table at OFFSET 0 of panel file
;
EXT_FILE STRUC				;AN024;
 PCBS	 DW	 0			;AN024;offset of PCB vector table
 NPCBS	 DW	 0			;AN024;number of PCBs
 SCBS	 DW	 0			;AN024;offset of SCB vector table
 NSCBS	 DW	 0			;AN024;number of SCBs
 COLTBL  DW	 0			;AN024;offset of COLOR attribute table
 NCOLTBL DW	 0			;AN024;number of COLOR attribute sets
 MONTBL  DW	 0			;AN024;offset of MONO attribute table
 NMONTBL DW	 0			;AN024;number of MONO attribute sets
EXT_FILE ENDS				;AN024;
					;
DATA	  SEGMENT BYTE PUBLIC 'DATA'    ;AN024;
CFILE	  DB   'SELECT.DAT',0           ;AN024;compressed panel file
REPCHAR   EQU  255			;AN024;character used as repeat flag
DATA	  ENDS				;AN024; 								;AN000;
					;
IF CASFAR				;AN000;
   IFE CASRM				;AN000;
	       EXTRN   INPUT:FAR	;AN000;
	       EXTRN   HLPRD:FAR	;AN000;
	       EXTRN   SLCTP:FAR	;AN000;
	       EXTRN   PANEL:FAR	;AN000;
	       EXTRN   DISPQ:FAR	;AN000;
	       EXTRN   INCHA:FAR	;AN000;
	       EXTRN   MBEEP:FAR	;AN000;
	       EXTRN   INSTRN:FAR	;AN000;
	       EXTRN   GVIDO:FAR	;AN000;
	       EXTRN   WWRAP:FAR	;AN000;
   ENDIF				;AN000;
					;
SELECT	SEGMENT PARA PUBLIC 'SELECT'    ;AN000;segment for far routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; IF NEAR procedure, then define segment and EXTRN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ELSE					;AN000;
					;
SELECT	SEGMENT PARA PUBLIC 'SELECT'    ;AN000;segment for far routine
   IFE CASRM				;AN000;
	EXTRN	INPUT:NEAR		;AN000;
	EXTRN	HLPRD:NEAR		;AN000;
	EXTRN	SLCTP:NEAR		;AN000;
	EXTRN	PANEL:NEAR		;AN000;
	EXTRN	DISPQ:NEAR		;AN000;
	EXTRN	INCHA:NEAR		;AN000;
	EXTRN	MBEEP:NEAR		;AN000;
	EXTRN	INSTRN:NEAR		;AN000;
	EXTRN	GVIDO:NEAR		;AN000;
	EXTRN	WWRAP:NEAR		;AN000;
   ENDIF				;AN000;
ENDIF					;AN000;
	ASSUME	CS:SELECT,DS:DATA,ES:DATA ;AN000;

	PUBLIC	CURSOROFF,PCGVIDO_CALL,INITIALIZE;AN000;
	PUBLIC	GET_KEY,PCDISPQ_CALL,PCPANEL_CALL;AN000;
	PUBLIC	GET_SCROLL_CALL,PCINPUT_CALL,CURSORON;AN000;
	PUBLIC	GET_SCB,GET_PCB,GET_ICB,PCMBEEP_CALL,PCSLCTP_CALL;AN000;
	EXTRN	GET_HELP_ID:NEAR	;AN000;
	EXTRN	ADJUST_DOWN:NEAR	;AN000;
	EXTRN	ADJUST_UP:NEAR		;AN000;
	EXTRN	INIT_SCROLL_CALL:NEAR	;AN000;
	EXTRN	INIT_PQUEUE_CALL:NEAR	;AN000;
	EXTRN	DISPLAY_PANEL_CALL:NEAR ;AN000;
	EXTRN	HANDLE_ERROR_CALL:FAR	;AN006;JW
	EXTRN	EXIT_SELECT:NEAR	;AN006;JW
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GET_SCROLL_CALL
;
;	  Process scroll field relative to current active panel.
;	  Automatically handle help request, display and interaction.
;
; Entry:  WR_DRETSEG   = Segment of dynamic return key string
;	  WR_DRETOFF   = Offset of dynamic return key string
;	  WR_DRETLEN   = Length of dynamic return key string
;
;	  WR_HCBCONT   = ID of the desired contextual help text
;
;	  WR_SCBID     = SCB Number of scroll field
;
;	  AX	     0 = Use default highlight and scroll list position
;		     1 = Initialize highlight and scroll list position
;			 to the top of the list
;
; Exit:   AX	       = Contains keystroke
;	  BX	       = Current element
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PUSHH	MACRO	REG_LIST	;;AN000;
	IRP	REG,<REG_LIST>	;;AN000;
	PUSH	REG		;;AN000; save registers
	ENDM			;;AN000;
		ENDM		;;AN000;
				;;
POPP	MACRO	REG_LIST	;;AN000;
	IRP	REG,<REG_LIST>	;;AN000;
	POP	REG		;;AN000; return registers to initial state
	ENDM			;;AN000;
		ENDM		;;AN000;
				;;
DOSCALL   MACRO 		;;AN000;
	  INT	  21H		;;AN000; call to DOS
	  ENDM			;;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GET_SCROLL_CALL PROC NEAR		;AN000;
	       PUSH CX			;AN000;
	       PUSH DX			;AN000;
	       PUSH SI			;AN000;
	       PUSH DI			;AN000;
	       PUSH ES			;AN000;
;					;
; Initialize to top			;
;					;
	       MOV  BX,WR_SCBID 	;AN000;get PCSLCTP field
	       CALL GET_SCB		;AN000;ES:DI points to SCB
;					;
	       CMP  AX,0		;AN000;check to start list & highlight
	       JE   GS10		;AN000; at top
;					;
	       MOV  ES:[DI]+SCB_TOPELE,1;AN000;intialize parameters
	       MOV  ES:[DI]+SCB_CURELE,AX;AN000;
;					;
; Locate PCB data and initialize SCB	;
;					;
GS10:	       MOV  BX,QM_ACTIVEPAN	;AN000;get the active panel number
	       CALL GET_PCB		;AN000;ES:DI address of panel PCB
					;
	       PUSH ES:[DI]+PCB_UROW	;AN000;    ;get active panel row
	       PUSH ES:[DI]+PCB_UCOL	;AN000;    ;get active panel column
	       PUSH ES:[DI]+PCB_CCBID	;AN000;get active panel color index
					;
	       MOV  BX,WR_SCBID 	;AN000;get PCSLCTP field
	       CALL GET_SCB		;AN000;ES:DI points to SCB
					;
	       POP  ES:[DI]+SCB_CCBID	;AN000;get the panel's current color ind
	       POP  ES:[DI]+SCB_RELCOL	;AN000;set the panel's relative column
	       POP  ES:[DI]+SCB_RELROW	;AN000;set the panel's relative row
;
; Build actual return string in complete buffer
;
	       CALL SET_RETKEYS 	     ;AN000;create complete return string
	       CALL SET_NUMKEYS 	     ;AN000;GHG

	       PUSH WR_CRETSEG		     ;AN000;initialize SCB with complete
	       POP  ES:[DI]+SCB_RLSEG	     ;AN000; return string information

	       PUSH WR_CRETOFF		     ;AN000;
	       POP  ES:[DI]+SCB_RLOFF	     ;AN000;

	       PUSH WR_CRETLEN		     ;AN000;
	       POP  ES:[DI]+SCB_RLLEN	     ;AN000;
;
; Process scroll field
;
	       AND  ES:[DI]+SCB_OPT1,NOT SCB_UKS;AN000;
					    ;set to not use keystrokes
	       CALL PCSLCTP_CALL	     ;AN000;display scroll field

	       MOV  BX,ES:[DI]+SCB_CURELE    ;AN000;get last current element
	       MOV  AX,ES:[DI]+SCB_KS	     ;AN000;get last keystroke
;
;
; determine if current element has specific contextual help text
;
	       MOV  WR_HLPOPT,HLP_OVER	       ;AN000;GHG position help panel with default
	       PUSH AX			       ;AN000;GHG
	       MOV  BX,WR_SCBID 	       ;AN000;GHG
	       MOV  AX,ES:[DI]+SCB_CURELE      ;AN000;GHG
	       CALL ADJUST_DOWN 	       ;AN000;GHG
	       MOV  CX,AX		       ;AN000;GHG
	       MOV  AX,2		       ;AN000;GHG
	       CALL GET_HELP_ID 	       ;AN000;GHG
	       MOV  WR_HCBCONT,AX	       ;AN000;GHG get current contextual help ID
	       XOR  AH,AH		       ;AN000;GHG
	       MOV  AL,DH		       ;AN000;GHG
	       MOV  WR_HLPROW,AX	       ;AN000;GHG row override of 6
	       MOV  AL,DL		       ;AN000;GHG
	       MOV  WR_HLPCOL,AX	       ;AN000;GHG row override of 6
	       POP  AX			       ;AN000;GHG

	       CALL CHK_NUMKEYS 	     ;AN000;GHG
	       CALL CHK_RETKEYS 	     ;AN000;check if used by other routine
	       JCXZ GS20		     ;AN000;keystroke not used elsewhere

	       JMP  GS10		     ;AN000;keystroke used elswhere, continu
					     ; from last position
;
; Exit
;
GS20:	       MOV  BX,ES:[DI]+SCB_CURELE    ;AN000;return current element
;
; display the selected option and exit immediately
;
	       PUSH AX			     ;AN008;JW
	       PUSH BX			     ;AN008;JW
	       OR   ES:[DI]+SCB_OPT1,SCB_RD  ;AN008;JW
	       CALL PCSLCTP_CALL	     ;AN008;JW display scroll field and exit
	       AND  ES:[DI]+SCB_OPT1,NOT SCB_RD ;AN008;JW
	       POP  BX			     ;AN008;JW
	       POP  AX			     ;AN008;JW

	       POP  ES			     ;AN000;
	       POP  DI			     ;AN000;
	       POP  SI			     ;AN000;
	       POP  DX			     ;AN000;
	       POP  CX			     ;AN000;

	       RET			     ;AN000;
GET_SCROLL_CALL ENDP			     ;AN000;
PAGE					     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GET_INPUT_CALL
;
;	  Process input field relative to current active panel.
;	  Automatically handle help request, display and interaction.
;
; Entry:  WR_DRETSEG   = Segment of dynamic return key string
;	  WR_DRETOFF   = Offset of dynamic return key string
;	  WR_DRETLEN   = Length of dynamic return key string
;
;	  WR_HCBCONT   = ID of the desired contextual help text
;
;	  IN_ICBID     = ICB Number of input field
;
; Exit:   AX	       = Contains keystroke
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUBLIC GET_INPUT_CALL		     ;AN000;GHG
GET_INPUT_CALL PROC NEAR		     ;AN000;GHG
	       PUSH CX			     ;AN000;GHG
	       PUSH DX			     ;AN000;GHG
	       PUSH SI			     ;AN000;GHG
	       PUSH DI			     ;AN000;GHG
	       PUSH ES			     ;AN000;GHG
					     ;GHG
	       MOV  BX,IN_ICBID 	     ;AN000;GHG get PCSLCTP field
	       CALL GET_ICB		     ;AN000;GHG ES:DI points to SCB
					     ;GHG
GI10:	       CALL SET_RETKEYS 	     ;AN000;GHG create complete return string
					     ;GHG
	       PUSH WR_CRETSEG		     ;AN000;GHG initialize SCB with complete
	       POP  ES:[DI]+ICB_RETSEG	     ;AN000;GHG  return string information
					     ;GHG
	       PUSH WR_CRETOFF		     ;AN000;GHG
	       POP  ES:[DI]+ICB_RETOFF	     ;AN000;GHG
					     ;GHG
	       PUSH WR_CRETLEN		     ;AN000;GHG
	       POP  ES:[DI]+ICB_RETLEN	     ;AN000;GHG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Process input field
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	       CALL PCINPUT_CALL	     ;AN000;GHG display input field
					     ;GHG
	       PUSHH   <SI,DI,ES,DS>	     ;AN000;GHG
	       PUSH	ES:[DI]+ICB_FIELDOFF ;AN000;GHG
	       PUSH	ES:[DI]+ICB_FIELDSEG ;AN000;GHG
	       PUSH	ES:[DI]+ICB_DEFOFF   ;AN000;GHG
	       PUSH	ES:[DI]+ICB_DEFSEG   ;AN000;GHG
					     ;GHG
	       MOV	CX,ES:[DI]+ICB_FIELDLEN;AN000;GHG
	       OR	CX,CX		     ;AN000;GHG
	       JE	GI_11		     ;AN000;GHG
					     ;GHG
	       POP	ES		     ;AN000;GHG
	       POP	DI		     ;AN000;GHG
	       POP	DS		     ;AN000;GHG
	       POP	SI		     ;AN000;GHG
	       CLD			     ;AN000;GHG
	       REP	MOVSB		     ;AN000;GHG
GI_11:	       POPP    <DS,ES,DI,SI>	     ;AN000;GHG
	       PUSH	ES:[DI]+ICB_ENDBYTE  ;AN000;GHG
	       POP	ES:[DI]+ICB_DEFLEN   ;AN000;GHG
					     ;GHG
	       MOV  AX,ES:[DI]+ICB_KEYRET    ;AN000;GHG get last keystroke
;					      GHG
;
; determine if current element has specific contextual help text
;
					     ;GHG
	       MOV  WR_HLPOPT,HLP_OVER	     ;AN000;GHG position help panel with default
	       PUSH AX			     ;AN000;GHG
	       MOV  AX,1		     ;AN000;GHG
	       MOV  BX,IN_ICBID 	     ;AN000;GHG
	       CALL GET_HELP_ID 	     ;AN000;GHG
	       MOV  WR_HCBCONT,AX	     ;AN000;GHG get current contextual help ID
	       XOR  AH,AH		     ;AN000;GHG
	       MOV  AL,DH		     ;AN000;GHG
	       MOV  WR_HLPROW,AX	     ;AN000;GHG row override
	       MOV  AL,DL		     ;AN000;GHG
	       MOV  WR_HLPCOL,AX	     ;AN000;GHG col override
	       POP  AX			     ;AN000;GHG
					     ;GHG
	       CALL CURSOROFF		     ;AN000;GHG Turn cursor OFF!!!!
	       CALL CHK_RETKEYS 	     ;AN000;GHG check if used by other routine
	       JCXZ GI20		     ;AN000;GHG keystroke not used elsewhere
					     ;GHG
	       JMP  GI10		     ;AN000;GHG keystroke used elswhere, continue
					     ;GHG from last position
GI20:	       POP  ES			     ;AN000;GHG
	       POP  DI			     ;AN000;GHG
	       POP  SI			     ;AN000;GHG
	       POP  DX			     ;AN000;GHG
	       POP  CX			     ;AN000;GHG
					     ;GHG
	       RET			     ;AN000;GHG
GET_INPUT_CALL ENDP			     ;AN000;GHG
PAGE					     ;AN000;GHG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GHG
;
; GET_INPUT
;
;	  Process input field relative to current active panel.
;	  Automatically handle help request, display and interaction.
;
;
; Entry:   WR_DRETSEG = Segment of call's return key string
;	   WR_DRETOFF = Offset of call's return key string
;	   WR_DRETLEN = Length of call's return key string
;
;	   WR_HCBCONT	= ID of the desired contextual help text
;
;
; Exit:   AX	   = Contains Keystroke
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GET_INPUT      PROC NEAR		 ;AN000;
	       RET			 ;AN000;
GET_INPUT      ENDP			 ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GET_KEY
;
;	   Get a keystroke from the keyboard and return to calling routine
;	   if not used.  This routine uses the string of return keys and
;	   builds the complete set of return keys.  Once the complete set of
;	   return keys is built, the CAS keyboard routine is called to look
;	   for a keystroke.  When a keystroke is pressed, the CAS routine
;	   returns and the keystroke is checked to determine if help should
;	   be processed.  If the keystroke is not used by help, then it is
;	   returned to the calling routine for use.
;
; Entry:   WR_DRETSEG = Segment of call's return key string
;	   WR_DRETOFF = Offset of call's return key string
;	   WR_DRETLEN = Length of call's return key string
;
; Exit:    AX = Contains unused keystroke returned from call
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GET_KEY        PROC NEAR		;AN000;

	       PUSH CX			;AN000;save registers
;
; Create complete return key string
;
CGK10:	       MOV  AX,0		;AN000;clear to zero
					;
	       CALL SET_RETKEYS 	;AN000;create complete return string
					;
	       PUSH WR_CRETSEG		;AN000;initialize PCINSTR parameters
	       POP  INS_SSEG		;AN000; with complete return string data
					;
	       PUSH WR_CRETOFF		;AN000;
	       POP  INS_SOFF		;AN000;
					;
	       PUSH WR_CRETLEN		;AN000;
	       POP  INS_SLEN		;AN000;
;					;
; Get keystroke from keyboard		;
;					;
CGK20:	      MOV  INC_OPT,INC_KWAIT	;AN000;wait for keystroke
	      CALL PCINCHA_CALL 	;AN000;call CAS routine
;
; Check if keystroke is a valid return key
;
	       MOV  INS_OPT,INS_FKS	;AN000;set find keystroke option
	       MOV  AX,INC_KS		;AN000;set keystroke to PCINSTR
	       MOV  INS_KS,AX		;AN000; parameter
					;
	       CALL PCINSTR_CALL	;AN000;check if good key
					;
	       TEST INS_RSLT,0FFFFH	;AN000;check if key found
	       JNE  CGK30		;AN000;yes
					;
	       CALL PCMBEEP_CALL	;AN000;no
	       JMP  CGK20		;AN000;try again
;
; Check if help keystroke and process if yes
;
CGK30:	       CALL CHK_RETKEYS 	;AN000;check keystroke
	       JCXZ CGKEXIT		;AN000;not used return to calling routin
	       JMP  CGK10		;AN000;if used by help, get another key
					;
CGKEXIT:       POP  CX			;AN000;restore registers
	       RET			;AN000;
GET_KEY        ENDP			;AN000;
PAGE					;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SET_RETKEYS
;
;	  Combine the calling routine's dynamic return key string with
;	  the return keys of the child panels currently displayed into
;	  one complete return string.
;
; Entry:  WR_DRETSEG = Segment of call's dynamic return key string
;	  WR_DRETOFF = Offset of call's dynamic return key string
;	  WR_DRETLEN = Length of call's dynamic return key string
;
; Exit:   WR_CRETSEG = Segment of complete return key string to use
;	  WR_CRETOFF = Offset of complete return key string to use
;	  WR_CRETLEN = Length of complete return key string to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_RETKEYS    PROC NEAR		;AN000;
	       PUSH CX			;AN000;
	       PUSH DX			;AN000;
	       PUSH DI			;AN000;
	       PUSH SI			;AN000;
	       PUSH ES			;AN000;
	       PUSH DS			;AN000;
;
; do not exceed WR_MAXRETKSZ  buffer length
;
;
; Move keystrokes from dynamic return key string to complete return strg buffer
;
	       CLD			;AN000;auto increment
	       PUSH WR_CRETSEG		;AN000;get segment of complete return
	       POP  ES			;AN000; buffer
					;
	       MOV  DI,WR_CRETOFF	;AN000;get offset of complete return
					;
	       MOV  CX,WR_DRETLEN	;AN000;get length of dynamic return strg
	       MOV  DX,CX		;AN000; and initialize DX counter
					;
	       MOV  SI,WR_DRETOFF	;AN000;get offset of dynamic return strg
					;
	       PUSH DS			;AN000;save data segment
					;
	       PUSH WR_DRETSEG		;AN000;get offset of dynamic return strg
	       POP  DS			;AN000;
					;
	       REP  MOVSB		;AN000;copy dynamic return key string
					; to complete return key buffer
	       POP  DS			;AN000;restore data segment
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Add assigned keys from displayed child panels to complete return buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	       MOV  SI,QM_RETKEYSOFF	;AN000;get offset of return buffer
					;
	       MOV  CX,QM_RETKEYSLEN	;AN000;
	       ADD  DX,CX		;AN000;add length of return keys
					;
	       PUSH DS			;AN000;save data segment
					;
	       PUSH QM_RETKEYSSEG	;AN000;
	       POP  DS			;AN000;get segment of return buffer
					;
	       REP  MOVSB		;AN000;copy string sent
					;
	       POP  DS			;AN000;restore data segment
					;
	       MOV  CX,WR_MAXRETKSZ	;AN061;
	       SUB  CX,DX		;AN061;
	       MOV  AL,0		;AN061;
	       REP  STOSB		;AN061;
					;
	       MOV  WR_CRETLEN,DX	;AN000;initialize current return string
;					;
; Exit					;
;					;
SRK30:	       POP  DS			;AN000;restore registers
	       POP  ES			;AN000;
	       POP  SI			;AN000;
	       POP  DI			;AN000;
	       POP  DX			;AN000;
	       POP  CX			;AN000;
	       RET			;AN000;
SET_RETKEYS    ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SET_NUMKEYS
;
; Entry:  WR_CRETSEG  = Segment of call's dynamic return key string
;	  WR_CRETOFF  = Offset of call's dynamic return key string
;	  WR_CRETLEN  = Length of call's dynamic return key string
;
; Exit:   WR_CRETSEG' = Segment of complete return key string to use
;	  WR_CRETOFF' = Offset of complete return key string to use
;	  WR_CRETLEN' = Length of complete return key string to use
;
;	GORD GIDDINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NUMKEYS        DB	'123456789'     ;AN000;
					;
SET_NUMKEYS    PROC NEAR		;AN000;
	       PUSH AX			;AN000;save registers
	       PUSH BX			;AN000;
	       PUSH CX			;AN000;
	       PUSH DI			;AN000;
	       PUSH SI			;AN000;
	       PUSH ES			;AN000;
	       PUSH DS			;AN000;
;
; Move numeric keystrokes into completed return strg buffer
;
	       MOV  BX,WR_SCBID 	;AN000;get PCSLCTP field
	       CALL GET_SCB		;AN000;ES:DI points to SCB
					;
	       TEST ES:[DI]+SCB_OPT3,SCB_NUMS;AN000;
	       JZ   SNK_30		;AN000;
					;
	       PUSH ES:[DI]+SCB_SELSEG	;AN000;
	       PUSH ES:[DI]+SCB_SELOFF	;AN000;
	       PUSH ES:[DI]+SCB_NUMELE	;AN000;
	       POP  CX			;AN000;
	       POP  DI			;AN000;
	       POP  ES			;AN000;
	       XOR  AX,AX		;AN000;
					;
SNR_10:        MOV  BX,SCB_ACTIVEON	;AN000;
	       CMP  ES:[DI],BX		;AN000;
	       JNE  SNR_15		;AN000;
	       INC  AX			;AN000;
SNR_15:        INC  DI			;AN000;
	       INC  DI			;AN000;
	       LOOP SNR_10		;AN000;
					;
	       CMP  AX,9		;AN000;
	       JBE  SNR_20		;AN000;
	       MOV  AX,9		;AN000;
SNR_20:        MOV  CX,AX		;AN000;
					;
	       PUSH WR_CRETOFF		;AN000;get offset of complete return
	       PUSH WR_CRETSEG		;AN000;get segment of complete return
	       POP  ES			;AN000;
	       POP  DI			;AN000;
					;
	       ADD  DI,WR_CRETLEN	;AN000;get length of dynamic return strg
	       ADD  WR_CRETLEN,CX	;AN000;
	       LEA  SI,NUMKEYS		;AN000;
	       PUSH CS			;AN000;
	       POP  DS			;AN000;
					;
	       CLD			;AN000;auto increment
	       REP  MOVSW		;AN000;
					;
SNK_30:        POP  DS			;AN000;restore registers
	       POP  ES			;AN000;
	       POP  SI			;AN000;
	       POP  DI			;AN000;
	       POP  CX			;AN000;
	       POP  BX			;AN000;
	       POP  AX			;AN000;
	       RET			;AN000;
SET_NUMKEYS    ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CHK_RETKEYS
;
;	   Check return key for active function keys
;
;	   Note:  That currently this routine searchs for only the help
;	   function keys (F1=Help, F5=Index, F7=Keys); however, other
;	   function keys could be searched for and processed in this
;	   routine before returning to the main dialog.
;
; Entry:   AX =  Keystroke
;
; Exit:    CX =  0= keystroke not used
;		 1= keystroke used
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_RETKEYS    PROC NEAR		;AN000;
	       PUSHF			     ;AN000;save registers and variables
	       PUSH AX			     ;AN000;
	       PUSH BX			     ;AN000;
	       PUSH DX			     ;AN000;
	       PUSH SI			     ;AN000;
	       PUSH DI			     ;AN000;
	       PUSH ES			     ;AN000;
	       PUSH DS			     ;AN000;
	       PUSH WR_HCBCONT		     ;AN000;save contextual help ID
	       PUSH QM_ACTIVEPAN	     ;AN000;save current active panel
	       PUSH WR_SCBID		     ;AN000;save current SCB ID
	       PUSH WR_DRETSEG		     ;AN000;save dynamic return key vars
	       PUSH WR_DRETOFF		     ;AN000;
	       PUSH WR_DRETLEN		     ;AN000;
	       PUSH MB_FREQUENCY	     ;AN004;GHG   for PTM 1064
;
; Check if keystroke pressed displays, processes, or removes contextual help
;
	       CALL MANAGE_HELP 	     ;AN000;
;
	       CMP  CX,0		     ;AN000;check if keystroke used by help
	       JE   CHK10		     ;AN000;no, check other functions
;
	       JMP  CHKEXIT		     ;AN000;yes, exit
;
; Keys may be check here and processed for other functions
;
CHK10:					     ;AN000;
;
; Exit to calling routine
;
CHKEXIT:       POP  MB_FREQUENCY	     ;AN004;GHG   for PTM 1064
	       POP  WR_DRETLEN		     ;AN000;save dynamic return key vars
	       POP  WR_DRETOFF		     ;AN000;
	       POP  WR_DRETSEG		     ;AN000;
	       POP  WR_SCBID		     ;AN000;restore current SCB ID
	       POP  QM_ACTIVEPAN	     ;AN000;restore current active panel
	       POP  WR_HCBCONT		     ;AN000;restore contextual help ID
	       POP  DS			     ;AN000;
	       POP  ES			     ;AN000;
	       POP  DI			     ;AN000;
	       POP  SI			     ;AN000;
	       POP  DX			     ;AN000;
	       POP  BX			     ;AN000;
	       POP  AX			     ;AN000;
	       POPF			     ;AN000;
	       RET			     ;AN000;
CHK_RETKEYS    ENDP			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CHK_NUMKEYS
;
;	   Check return key for numeric keys
;
; Entry:   AX =  Keystroke
;
; Exit:    AX =  The first character in the completed return key string
;	      WR_CRETSEG:WR_CRETOFF
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_NUMKEYS    PROC NEAR			;AN000;
	       PUSH ES				;AN000;
	       PUSH DI				;AN000;
	       PUSH BX				;AN000;
	       MOV  BX,WR_SCBID 		;AN000;
	       CALL GET_SCB			;AN000;
	       TEST ES:[DI]+SCB_OPT3,SCB_NUMS	;AN000;
	       JZ   CNK_20			;AN000;
	       OR   AH,AH			;AN000;
	       JNZ  CNK_20			;AN000;
	       CMP  AL,'1'                      ;AN000;
	       JB   CNK_20			;AN000;
	       CMP  AL,'9'                      ;AN000;
	       JA   CNK_20			;AN000;
						;
	       MOV  BX,AX			;AN000; now form the index value
	       SUB  BX,'0'                      ;AN000; from the keystroke!
						;
	       PUSHH <ES,DI>			;AN000;GHG
	       PUSHH <WR_CRETSEG,WR_CRETOFF>	;AN000;GHG
	       POPP  <DI,ES>			;AN000;GHG
	       MOV  AL,ES:[DI]			;AN000;GHG
	       POPP  <DI,ES>			;AN000;GHG
						;				;
	       MOV  ES:[DI]+SCB_KS,AX		;AN000;
	       PUSH AX				;AN000;
	       MOV  AX,BX			;AN000;get PCSLCTP field
	       MOV  BX,WR_SCBID 		;AN000;
	       CALL ADJUST_UP			;AN000;
	       MOV  ES:[DI]+SCB_CURELE,AX	;AN000;
	       POP  AX				;AN000;
						;
CNK_20:        POP  BX				;AN000;
	       POP  DI				;AN000;
	       POP  ES				;AN000;
	       RET				;AN000;
CHK_NUMKEYS    ENDP				;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; MANAGE_HELP
;
;	  Manage contextual, indexed and keys help.  This routine is used     :
;	  to display, process and remove help from the screen.
;
; Entry:  AX		  = Keystroke pressed
;
;	  WR_HLPOPT	  = Help display and operation options
;	  WR_HLPROW	  = Override row for help panel
;	  WR_HLPCOL	  = Override column for help panel
;
;	  WR_HCBCONT	  = Current contextual help ID
;	  WR_HCBHELP	  = Help-on-help ID
;	  WR_HCBKEYS	  = Keys help ID
;
;	  WR_PCBHPAN	  = Help panel ID
;
;	  WR_SCBCONT	  = Scroll ID for context forms of help
;	  WR_SCBINDX	  = Scroll ID for indexed forms of help
;
;	  WR_KEYQUIT	  = Quit keystroke (Esc)
;	  WR_KEYKEYS	  = Keys help keystroke (F7=Keys)
;	  WR_KEYHELP	  = Help-on-help keystroke (F1=Help)
;	  WR_KEYCONT	  = Contextual help keystroke (F1=Help)
;	  WR_KEYINDX	  = Indexed help keystroke (F5=Index)
;	  WR_KEYSWIT	  = Switch keystroke (F2=Switch)
;
;	  HRD_FILSPOFF	  = Offset of contextual help file path name
;	  HRD_FILSPSEG	  = Segment of contextual help file path name
;
; Exit:   AX		  = Keystroke
;	  CX	      0   = Keystroke not used
;		      1   = Keystroke used
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MANAGE_HELP    PROC NEAR			;AN000;
;
; Check if help is displayed
;
	       MOV  CX,0			;AN000;

	       PUSH DS			     ;AN007;JW
	       PUSH CS			     ;AN007;JW
	       POP  DS			     ;AN007;JW
	       CMP  ERROR_ACTIVE,1	     ;AN007;JW is an error being processed?
	       POP  DS			     ;AN007;JW
	       JNE  MH00		     ;AN007;JW no, continue
	       JMP  MHEXIT		     ;AN007;JW yes, exit

MH00:	       CMP  WR_HLPDIS,0 	     ;AN000;check if help is displayed
	       JE   MH30		     ;AN000;

	       CMP  AX,WR_KEYSWIT	     ;AN000;check if any key but switch
	       JNE  MH10		     ;AN000; and remove help

	       TEST WR_HLPDIS,HLP_INDX	     ;AN000;check if index displayed
	       JNE  MH05		     ;AN000;yes

	       MOV  QM_OPT1,QM_RVMCHD	     ;AN000;remove child panel
	       MOV  AX,WR_PCBENTR	     ;AN000;Enter panel
	       MOV  QM_ID,AX		     ;AN000;parent PCB number
	       CALL PCDISPQ_CALL	     ;AN000;

MH05:	       MOV  QM_OPT1,QM_PUSHCHD	     ;AN000;add child panel
	       MOV  AX,WR_PCBHELP	     ;AN000;F1=Help panel
	       MOV  QM_ID,AX		     ;AN000;parent PCB number
	       CALL PCDISPQ_CALL	     ;AN000;
	       JMP  MH20		     ;AN000;

MH10:	       CALL REMOVE_HELP 	     ;AN000;restore original display queues
	       JMP  MH80		     ;AN000;exit
;
; Process read help text
;
MH20:	       CALL PROCESS_HELP	     ;AN000;process contextual help

	       MOV  CX,1		     ;AN000;set keystroke used flag

	       CMP  AX,WR_KEYSWIT	     ;AN000;check if help should be left
	       JNE  MH25		     ;AN000; on the screen

	       MOV  QM_OPT1,QM_RVMCHD	     ;AN000;remove child panel
	       MOV  AX,WR_PCBHELP	     ;AN000;F1=Help
	       MOV  QM_ID,AX		     ;AN000;parent PCB number
	       CALL PCDISPQ_CALL	     ;AN000;

	       MOV  AX,WR_PCBHELP	     ;AN000;F1=Help
	       MOV  QM_ID,AX		     ;AN000;parent PCB number
	       CALL PCDISPQ_CALL	     ;AN000;

	       TEST WR_HLPDIS,HLP_INDX	     ;AN000;check if index displayed
	       JNE  MH22		     ;AN000;yes

	       MOV  QM_OPT1,QM_PUSHCHD	     ;AN000;add child panel
	       MOV  AX,WR_PCBENTR	     ;AN000;Enter panel
	       MOV  QM_ID,AX		     ;AN000;parent PCB number
	       CALL PCDISPQ_CALL	     ;AN000;

MH22:	       JMP  MH80		     ;AN000;exit

MH25:	       CMP  AL,01BH		     ;AN000;check for quit key
	       JNE  MH30		     ;AN000; refresh display

	       CALL REMOVE_HELP 	     ;AN000;restore original display queues
	       JMP  MH80		     ;AN000;exit

; Read help if requested

MH30:	       CMP  AX,WR_KEYHELP	     ;AN000;check if F1=help requested
	       JNE  MH60		     ;AN000;

	       CMP  WR_HLPDIS,0 	     ;AN000;is help already displayed
	       JE   MH40		     ;AN000;no

	       CALL REMOVE_HELP 	     ;AN000;restore original display queues

MH40:	       TEST WR_HLPDIS,HLP_CONT	     ;AN000;check if contextual help already
	       JE   MH50		     ;AN000; on

	       MOV  WR_HLPPAN,HLP_KEYS	     ;AN000;turn on help on keys
	       OR   WR_HLPPAN,HLP_CONT	     ;AN000;turn on contextual help
	       OR   WR_HLPPAN,HLP_INDX	     ;AN000;turn on help index

	       PUSH WR_HCBHELP		     ;AN000;set help-on-help ID
	       POP  HRD_ID		     ;AN000;

	       MOV  WR_HLPDIS,HLP_HELP	     ;AN000;turn help-on-help status on
	       CALL READ_HELP		     ;AN000;prepare help text
	       JMP  MH20		     ;AN000;loop to process

MH50:	       MOV  WR_HLPPAN,HLP_KEYS	     ;AN000;turn on help on keys
	       OR   WR_HLPPAN,HLP_HELP	     ;AN000;turn on help-on-help
	       OR   WR_HLPPAN,HLP_INDX	     ;AN000;turn on help index

	       PUSH WR_HCBCONT		     ;AN000;get current contextual help text
	       POP  HRD_ID		     ;AN000; ID

	       MOV  WR_HLPDIS,HLP_CONT	     ;AN000;turn contextual help status on
	       CALL READ_HELP		     ;AN000;prepare help text
	       JMP  MH20		     ;AN000;loop to process
;
; Check if indexed help requested for display
;
MH60:	       CMP  AX,WR_KEYINDX	     ;AN000;check if index selected
	       JNE  MH70		     ;AN000;

	       CMP  WR_HLPDIS,0 	     ;AN000;is help already displayed
	       JE   MH65		     ;AN000;no

	       CALL REMOVE_HELP 	     ;AN000;restore original display queues

MH65:	       MOV  WR_HLPPAN,HLP_CONT	     ;AN000;turn on contextual help
	       OR   WR_HLPPAN,HLP_KEYS	     ;AN000;turn on help on keys

	       MOV  HRD_ID,0		     ;AN000;set contextual help ID

	       MOV  WR_HLPDIS,HLP_INDX	     ;AN000;turn index status on
	       CALL READ_HELP		     ;AN000;prepare help text
	       JMP  MH20		     ;AN000;loop to process
;
; Check if keys help requested for display
;
MH70:	       CMP  AX,WR_KEYKEYS	     ;AN000;check for help on keys
	       JNE  MHEXIT		     ;AN000;

	       CMP  WR_HLPDIS,0 	     ;AN000;is help already displayed
	       JE   MH75		     ;AN000;no

	       CALL REMOVE_HELP 	     ;AN000;restore original display queues

MH75:	       MOV  WR_HLPPAN,HLP_CONT	     ;AN000;turn on contextual help
	       OR   WR_HLPPAN,HLP_INDX	     ;AN000;turn on help index

	       PUSH WR_HCBKEYS		     ;AN000;set keys help ID
	       POP  HRD_ID		     ;AN000;

	       MOV  WR_HLPDIS,HLP_KEYS	     ;AN000;turn keys help status on
	       CALL READ_HELP		     ;AN000;prepare help text
	       JMP  MH20		     ;AN000;loop to process
;
; Help was processed restore original active panel and return key string
;
MH80:	       MOV  QM_OPT1,0		     ;AN000;make original panel active
	       CALL PCDISPQ_CALL	     ;AN000; and update the return keys

	       CALL SET_RETKEYS 	     ;AN000;restore original return keys

	       PUSH AX			     ;AN000;save keystroke

	       MOV  AX,1     ;;AN000;;;;;;;;;;0    ;set break option off

	       CMP  WR_HLPDIS,0 	     ;AN000;is help displayed
	       JE   MH90		     ;AN000;

	       MOV  AX,1		     ;AN000;turn break option on

MH90:	       CALL PCPANEL_CALL	     ;AN000;make original panel the active
					     ; panel with the child panels
	       POP  AX			     ;AN000;restore keystroke
;
; Exit
;
MHEXIT: 				     ;AN000;exit
;
	       RET			     ;AN000;
MANAGE_HELP    ENDP			     ;AN000;

PAGE					     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; READ_HELP
;
;	  Read Help Text and Prepare for Display:
;
;	  o  Read the specified contextual help text into the help buffer     :
;
;	  o  Save the current parent and child display queues
;
;	  o  Add the contextual help panel to the new display queue
;
;	  o  Exit without updating display
;
;
; Entry:  WR_PCBHPAN	= Help panel ID
;	  WR_SCBCONT	= Scroll ID for context forms of help
;	  WR_SCBINDX	= Scroll ID for indexed forms of help
;
;	  HRD_ID	= Current contextual help ID to read
;	  HRD_FILSPOFF	= Offset of help file path name
;	  HRD_FILSPSEG	= Segment of help file path name
;
;	  WR_HLPOPT	= Help options
;	  WR_HLPDIS	= Help display status
;	  WR_HLPPAN	= Active help panels
;	  WR_HLPROW	= Override row for help panel
;	  WR_HLPCOL	= Override column for help panel
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
READ_HELP      PROC NEAR		     ;AN000;
	       PUSH BX			     ;AN000;save registers
	       PUSH DX			     ;AN000;
	       PUSH DI			     ;AN000;
	       PUSH QM_ACTIVEPAN	     ;AN000;
;
; Read specified help text from file into memory buffer
;
	       MOV  HRD_OPT1,HRD_TEXT	     ;AN000;set the contextual option
					     ;
	       TEST WR_HLPDIS,HLP_INDX	     ;AN000;check if index status on
	       JE   RH05		     ;AN000;
					     ;
	       MOV  HRD_OPT1,HRD_TOPIC	     ;AN000;set the indexed help option
					     ;
RH05:	       CALL HOOK_INT_24 	     ;AN000;
					     ;
RH06:	       PUSH HRD_BUFOFF		     ;AN000;
	       PUSH HRD_BUFLEN		     ;AN000;save help buffer length
					     ;
	       CALL PCHLPRD_CALL	     ;AN005;GHG call help read routine
	       JNC  RH07		     ;AN006;JW
					     ;
	       POP  HRD_BUFLEN		     ;AN006;JW restore help buffer length
	       POP  HRD_BUFOFF		     ;AN006;JW
	       MOV  BX,ERR_INS_INSTALL	     ;AN060;JW
	       MOV  CX,E_RETURN 	     ;AN000;
	       CALL HANDLE_ERROR_CALL	     ;AN000;
	       JNC  RH06		     ;AN000;
	       CLEAR_SCREEN2		     ;AN000;
	       JMP  EXIT_SELECT 	     ;AN000;
					     ;
RH07:	       POP  HRD_BUFLEN		     ;AN000;restore help buffer length
	       POP  HRD_BUFOFF		     ;AN000;
	       CALL RESTORE_INT_24	     ;AN006;JW
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Handle error for help text not found
;
; Perform WORD WRAP on help buffer...
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	       PUSH HRD_TEXTSEG 	     ;AN000;GHG
	       POP  WWP_SRCTXTSEG	     ;AN000;GHG
					     ;GHG
	       PUSH HRD_TEXTOFF 	     ;AN000;GHG
	       POP  WWP_SRCTXTOFF	     ;AN000;GHG
					     ;GHG
	       PUSH HRD_TEXTLEN 	     ;AN000;GHG
	       POP  WWP_SRCTXTLEN	     ;AN000;GHG
					     ;GHG
	       PUSH WR_MAXHELPSZ	     ;AN000;GHG
	       POP  WWP_SRCBUFLEN	     ;AN000;GHG
					     ;GHG
	       PUSH ES			     ;AN000;GHG
	       PUSH DI			     ;AN000;GHG
	       MOV  BX,WR_SCBCONT	     ;AN000;GHG get help scroll ID
	       CALL GET_SCB		     ;AN000;GHG ES:DI points to SCB
	       MOV  BX,ES:[DI]+SCB_WIDTH     ;AN000;GHG calculate number of help text
	       MOV  WWP_WIDTH,BX	     ;AN000;GHG
	       POP  DI			     ;AN000;GHG
	       POP  ES			     ;AN000;GHG
					     ;GHG
					     ;GHG
	       XOR  AX,AX		     ;AN000;GHG
	       MOV  WWP_NUMLINES,AX	     ;AN000;GHG
	       MOV  WWP_ERROR,AX	     ;AN000;GHG
	       MOV  WWP_OPT1,WWP_LEFTJUST+WWP_HYPHEN+WWP_SRCBUFFER ;AN000;GHG
					     ;GHG
	       CALL PCWWRAP_CALL	     ;AN000;GHG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Determine position and add help panel to parent display queue
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	       MOV  QM_OPT1,QM_PUSHPQU	     ;AN000;push parent queue
	       OR   QM_OPT1,QM_PUSHCQU	     ;AN000;push child queue
	       CALL PCDISPQ_CALL	     ;AN000;update display queue

	       TEST WR_HLPOPT,HLP_OVER	     ;AN000;check for help panel position
	       JE   RH10		     ;AN000; override

	       PUSH WR_HLPCOL		     ;AN000;set override
	       POP  QM_COLUMOVER	     ;AN000;

	       PUSH WR_HLPROW		     ;AN000;set override
	       POP  QM_ROWOVER		     ;AN000;

RH10:	       MOV  QM_OPT1,QM_RVMCHD	     ;AN000;remove child panel
	       MOV  AX,WR_PCBENTR	     ;AN000;Enter panel
	       MOV  QM_ID,AX		     ;AN000;parent PCB number
	       CALL PCDISPQ_CALL	     ;AN000;update display queue

	       MOV  AX,WR_PCBQUIT	     ;AN000;Quit panel
	       MOV  QM_ID,AX		     ;AN000;parent PCB number
	       CALL PCDISPQ_CALL	     ;AN000;update display queue

	       MOV  QM_OPT1,QM_PUSHPAN	     ;AN000;add help panel
	       OR   QM_OPT2,QM_BREAKON	     ;AN000;break on
	       MOV  BX,WR_PCBHPAN	     ;AN000;
	       MOV  QM_ID,BX		     ;AN000;get help panel number
	       MOV  QM_ACTIVEPAN,BX	     ;AN000;make help panel active
	       CALL PCDISPQ_CALL	     ;AN000;update display queue

	       MOV  QM_OPT2,0		     ;AN000;set options off
	       MOV  QM_ROWOVER,0	     ;AN000;deactivate overrides
	       MOV  QM_COLUMOVER,0	     ;AN000;
;
; Check if help panel's children are active and add to display queue
;
	       MOV  QM_OPT1,QM_PUSHCHD	     ;AN000;add child panels option

	       MOV  BX,WR_PCBQUIT	     ;AN000;Esc=Quit
	       MOV  QM_ID,BX		     ;AN000;get help panel number
	       CALL PCDISPQ_CALL	     ;AN000;update display queue

	       TEST WR_HLPPAN,HLP_CONT	     ;AN000;check if contextual help active
	       JE   RH15		     ;AN000;

	       MOV  BX,WR_PCBHELP	     ;AN000;F1=Help panel
	       MOV  QM_ID,BX		     ;AN000;get help panel number
	       CALL PCDISPQ_CALL	     ;AN000;update display queue

RH15:	       TEST WR_HLPPAN,HLP_HELP	     ;AN000;check if help-on-help active
	       JE   RH20		     ;AN000;

	       MOV  BX,WR_PCBHELP	     ;AN000;F1=Help panel
	       MOV  QM_ID,BX		     ;AN000;get help panel number
	       CALL PCDISPQ_CALL	     ;AN000;update display queue

RH20:	       TEST WR_HLPPAN,HLP_INDX	     ;AN000;check if help index active
	       JE   RH30		     ;AN000;

	       MOV  BX,WR_PCBINDX	     ;AN000;F5=Index panel
	       MOV  QM_ID,BX		     ;AN000;get help panel number
	       CALL PCDISPQ_CALL	     ;AN000;update display queue

RH30:	       TEST WR_HLPPAN,HLP_KEYS	     ;AN000;check if help keys active
	       JE   RH40		     ;AN000;

	       MOV  BX,WR_PCBKEYS	     ;AN000;
	       MOV  QM_ID,BX		     ;AN000;get help panel number
	       CALL PCDISPQ_CALL	     ;AN000;update display queue
;
; Locate help panel PCB data and initialize common data
;
RH40:	       MOV  BX,WR_PCBHPAN	     ;AN000;get help panel ID
	       CALL GET_PCB		     ;AN000;ES:DI points to PCB

	       PUSH ES:[DI]+PCB_UROW	     ;AN000;get help panel row
	       PUSH ES:[DI]+PCB_UCOL	     ;AN000;get help panel column
;
; Initialize for indexed form of help
;
	       TEST WR_HLPDIS,HLP_INDX	     ;AN000;check is index help status is on
	       JE   RH50		     ;AN000;

	       LEA  AX,WR_REFBUF	     ;AN000;get address of refresh table
	       MOV  WR_REFOFF,AX	     ;AN000;

	       LEA  AX,WR_REFBUF	     ;AN000;get address of refresh table
	       MOV  WR_REFOFF,AX	     ;AN000;

	       MOV  QM_OPT1,QM_PUSHCHD	     ;AN000;push child
	       MOV  AX,WR_PCBENTR	     ;AN000;Enter panel
	       MOV  QM_ID,AX		     ;AN000;parent PCB number
	       CALL PCDISPQ_CALL	     ;AN000;update display queue

	       MOV  BX,WR_SCBINDX	     ;AN000;get help scroll ID
	       CALL GET_SCB		     ;AN000;ES:DI points to SCB

	       POP  ES:[DI]+SCB_RELCOL	     ;AN000;set panel's relative column
	       POP  ES:[DI]+SCB_RELROW	     ;AN000;set panel's relative row

	       MOV  ES:[DI]+SCB_TOPELE,1     ;AN000;set top element
	       MOV  ES:[DI]+SCB_CURELE,1     ;AN000;set current line
	       MOV  ES:[DI]+SCB_CURCOL,1     ;AN000;display offset into opt strings

	       ;
	       ; adjust scrolling field width to be contained within panel
	       ;

	       MOV  AX,HRD_TOPICLEN	     ;AN000;get topic length
	       MOV  ES:[DI]+SCB_OASLEN,AX    ;AN000;fixed string length
	       MOV  ES:[DI]+SCB_NUMCOL,AX    ;AN000;maximum number of cols to scroll

	       ;
	       ;  adjust scrolling field number of display lines to be
	       ;  contained within panel
	       ;

	       PUSH HRD_TOPICNUM	     ;AN000;set number of elements
	       POP  ES:[DI]+SCB_NUMELE	     ;AN000;

	       MOV  AX,HRD_TOPICSEG	     ;AN000;set segment of topic vector
	       MOV  ES:[DI]+SCB_OAPSEG,AX    ;AN000;
	       MOV  ES:[DI]+SCB_OASSEG,AX    ;AN000;set option array string segment

	       PUSH HRD_TOPICOFF	     ;AN000;set offset of topic vector
	       POP  ES:[DI]+SCB_OAPOFF	     ;AN000;

	       JMP  RHEXIT		     ;AN000;index initialized
;
; Initialize for contextual forms of help (cont, help, and keys)
;
RH50:	       LEA  AX,WR_REFBUF	     ;AN000;get address of refresh table
	       MOV  WR_REFOFF,AX	     ;AN000;
;
	       MOV  BX,WR_SCBCONT	     ;AN000;get help scroll ID
	       CALL GET_SCB		     ;AN000;ES:DI points to SCB
;
	       POP  ES:[DI]+SCB_RELCOL	     ;AN000;set panel's relative column
	       POP  ES:[DI]+SCB_RELROW	     ;AN000;set panel's relative row
;
	       MOV  ES:[DI]+SCB_TOPELE,1     ;AN000;GHG set top element
	       MOV  ES:[DI]+SCB_CURELE,1     ;AN000;GHG set current line
	       MOV  ES:[DI]+SCB_CURCOL,1     ;AN000;display offset into opt strings
;
	       MOV  AX,WWP_NUMLINES	     ;AN000;GHG Use WordWrap # lines
	       DEC  AX			     ;AN000;GHG
	       MOV  ES:[DI]+SCB_NUMELE,AX    ;AN000;initialize number of elements

	       PUSH HRD_TEXTSEG 	     ;AN000;set segment of help text
	       POP  ES:[DI]+SCB_OAPSEG	     ;AN000;

	       PUSH HRD_TEXTOFF 	     ;AN000;set offset of help text
	       POP  ES:[DI]+SCB_OAPOFF	     ;AN000;
	       MOV  BX,ES:[DI]+SCB_WIDTH     ;AN000;GHG  SKIP OVER FIRST ELEMENT
	       ADD  ES:[DI]+SCB_OAPOFF,BX    ;AN000;GHG

RHEXIT:        POP  QM_ACTIVEPAN	     ;AN000;restore current active panel
	       POP  DI			     ;AN000;restore registers and exit
	       POP  DX			     ;AN000;
	       POP  BX			     ;AN000;
	       RET			     ;AN000;
READ_HELP      ENDP			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCESS_HELP
;
;	  Process Help Panel and Text:
;	  o  Update display to make help panel active
;	  o  Configure proper return keys
;	  o  Process scrolling of help text until exit key pressed
;
; Entry:  WR_PCBHPAN	= Help panel ID
;	  WR_SCBCONT	= Scroll ID for context forms of help
;	  WR_SCBINDX	= Scroll ID for indexed forms of help
;
; Exit:   AX = Exit keystroke pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PROCESS_HELP   PROC NEAR		;AN000;
	       PUSH BX			;AN000;save registers
	       PUSH DI			;AN000;
	       PUSH ES			;AN000;
	       PUSH WR_DRETSEG		;AN000;save dynamic return key vars
	       PUSH WR_DRETOFF		;AN000;
	       PUSH WR_DRETLEN		;AN000;
	       PUSH QM_ACTIVEPAN	;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Refresh display with help panel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	       PUSH WR_PCBHPAN		;AN000;set the help panel as active
	       POP  QM_ACTIVEPAN	;AN000;
					;
	       MOV  QM_OPT1,0		;AN000;make help panel active panel
	       CALL PCDISPQ_CALL	;AN000; and update the return keys
					;
	       MOV  AX,1		;AN000;set break option on
	       CALL PCPANEL_CALL	;AN000;refresh display
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Locate proper scroll SCB for help form
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	       MOV  BX,WR_SCBCONT	;AN000;set for contextual help form
					;
	       TEST WR_HLPDIS,HLP_INDX	;AN000;check if indexed help status on
	       JE   PH10		;AN000;
					;
	       MOV  BX,WR_SCBINDX	;AN000;set for indexed help form
					;
PH10:	       CALL INIT_HELP_TITLE	;AN000;** GG
	       CALL GET_SCB		;AN000;loads PCSLCTP vars with field
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Build return string of keystrokes and process help
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	       LEA  AX,WR_RETHLPBUF	;AN000;set help dynamic return keys
	       MOV  WR_DRETOFF,AX	;AN000;
					;
	       MOV  AX,WR_RETHLPLEN	;AN000;
	       MOV  WR_DRETLEN,AX	;AN000;
					;
	       MOV  AX,DATA		;AN000;
	       MOV  WR_DRETSEG,AX	;AN000;
					;
	       CALL SET_RETKEYS 	;AN000;create complete return string
					;
	       PUSH WR_CRETSEG		;AN000;initialize SCB with complete
	       POP  ES:[DI]+SCB_RLSEG	;AN000; return string information
					;
	       PUSH WR_CRETOFF		;AN000;
	       POP  ES:[DI]+SCB_RLOFF	;AN000;
					;
	       PUSH WR_CRETLEN		;AN000;
	       POP  ES:[DI]+SCB_RLLEN	;AN000;
					;
	       CALL PCSLCTP_CALL	;AN000;process help text until exit
					;
	       MOV  AX,ES:[DI]+SCB_KS	;AN000;get keystroke from PCSLCTP
					;
	       TEST WR_HLPDIS,HLP_INDX	;AN000;check if index help status is on
	       JE   PHEXIT		;AN000;
					;
	       CMP  AX,WR_KEYSELT	;AN000;check if select key pressed to
	       JNE  PHEXIT		;AN000; select desired topic
					;
	       MOV  BX,ES:[DI]+SCB_CURELE;AN000;get current selected element
	       MOV  WR_HCBCONT,BX	;AN000;return new contextual help number
					; selected from the help index
	       MOV  AX,WR_KEYHELP	;AN000;return contextual help key requst
					; instead of enter key
PHEXIT:        POP  QM_ACTIVEPAN	;AN000;restore current active panel
	       POP  WR_DRETLEN		;AN000;restore return key vars
	       POP  WR_DRETOFF		;AN000;
	       POP  WR_DRETSEG		;AN000;
	       POP  ES			;AN000;restore registers and exit
	       POP  DI			;AN000;
	       POP  BX			;AN000;
	       RET			;AN000;
PROCESS_HELP   ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; INITIALIZE_HELP_TITLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_HELP_TITLE PROC	NEAR		;AN000;
	PUSHH  <AX,BX,ES,DI,WR_SCBID>	;AN000;
					;
	MOV	BX,WR_PCBHPAN		;AN000;get help panel ID
	CALL	GET_PCB 		;AN000;ES:DI points to PCB
					;
	PUSH	ES:[DI]+PCB_UROW	;AN000;get help panel row
	PUSH	ES:[DI]+PCB_UCOL	;AN000;get help panel column
					;
	MOV	BX,SCR_TITLE_HLP	;AN000;
	MOV	WR_SCBID,BX		;AN000;
	CALL	GET_SCB 		;AN000;
					;
	POP	ES:[DI]+SCB_RELCOL	;AN000;
	POP	ES:[DI]+SCB_RELROW	;AN000;
					;
	PUSH	HRD_TEXTSEG		;AN000;
	POP	ES:[DI]+SCB_OAPSEG	;AN000;
					;
	PUSH	HRD_TEXTOFF		;AN000;
	POP	ES:[DI]+SCB_OAPOFF	;AN000;
					;
	PUSH	ES:[DI]+SCB_OPT1	;AN000;
	OR	ES:[DI]+SCB_OPT1,SCB_RD ;AN000;
	CALL	PCSLCTP_CALL		;AN000;display scroll field
	POP	ES:[DI]+SCB_OPT1	;AN000;
					;
	POPP   <WR_SCBID,DI,ES,BX,AX>	;AN000;
	RET				;AN000;
INIT_HELP_TITLE ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; REMOVE_HELP
;
;	  Remove Help Panel:
;
;	  o  Restore original parent and child display queues; thereby,
;	     removing help panels
;
;	  o  Exit without updating display
;
; Entry:  WR_KEYHELP	  = Help-on-help keystroke (F1=Help)
;
; Exit:   WR_HLPDIS  = Help status off
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
REMOVE_HELP    PROC NEAR		;AN000;
	       PUSH BX			     ;AN000;save registers
	       PUSH DI			     ;AN000;
;
; Restore original parent and child queues
;
	       MOV  QM_OPT1,QM_POPPQU	     ;AN000;restore parent queue
	       OR   QM_OPT1,QM_POPCQU	     ;AN000;restore child queue
	       CALL PCDISPQ_CALL	     ;AN000;update display queue
;
; Reset variables for exit
;
	       TEST WR_HLPDIS,HLP_CONT	     ;AN000;check if contextual help
	       JE   RM20		     ;AN000; already on, no set status off

	       CMP  AX,WR_KEYHELP	     ;AN000;check if help on help request
	       JE   RMEXIT		     ;AN000;

RM20:	       MOV  WR_HLPDIS,0 	     ;AN000;help panels not on
;
; Exit
;
RMEXIT:        POP  DI			     ;AN000;restore registers and exit
	       POP  BX			     ;AN000;
	       RET			     ;AN000;
REMOVE_HELP    ENDP			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GET_PCB
;
;	  Get Panel Control Block information for child or parent panel.      :
;
; Entry:  BX = Number of PCB vector desired.
;
; Exit:   ES = Segment of desired PCB.
;	  DI = Offset of desired PCB.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
GET_PCB        PROC NEAR		     ;AN000;
	       PUSH AX			     ;AN000;
	       PUSH BX			     ;AN000;
	       PUSH CX			     ;AN000;
	       PUSH DX			     ;AN000;GHG
;
; read panel control block vector to obtain PCB address
;
	       PUSH QM_PCBVECSEG	     ;AN000;get beginning PCB vector address
	       POP  ES			     ;AN000;
	       PUSH QM_PCBVECOFF	     ;AN000;
	       POP  DI			     ;AN000;

	       DEC  BX			     ;AN000;make zero based
	       MOV  AX,VECSEGLEN	     ;AN000;multiply PCB element length by
	       ADD  AX,VECOFFLEN	     ;AN000; desired vector number in BX
	       MUL  BX			     ;AN000; to determine offset into PCB vec
	       ADD  DI,AX		     ;AN000;add offset inside table
	       MOV  BX,ES:[DI]		     ;AN000;get actual PCB segment
	       MOV  CX,ES:[DI]+VECSEGLEN     ;AN000;point past PCB seg to get PCB off

	       MOV  ES,BX		     ;AN000;set ES:DI to panel's actual
	       MOV  DI,CX		     ;AN000; PCB address

	       POP  DX			     ;AN000;GHG
	       POP  CX			     ;AN000;
	       POP  BX			     ;AN000;
	       POP  AX			     ;AN000;

	       RET			     ;AN000;
GET_PCB        ENDP			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GET_SCB
;
;	  Get Scroll Field Control Block information.
;
; Entry:  BX = Number of SCB vector desired.
;
; Exit:   ES:DI = Address of desired SCB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
GET_SCB        PROC NEAR		     ;AN000;
;
	       PUSH AX			     ;AN000;
	       PUSH BX			     ;AN000;
	       PUSH CX			     ;AN000;
	       PUSH DX			     ;AN000;GHG
;
; read scroll control block vector to obtain SCB address
;
	       PUSH SRD_SCBVECSEG	     ;AN000;get beginning SCB vector address
	       POP  ES			     ;AN000;
	       PUSH SRD_SCBVECOFF	     ;AN000;
	       POP  DI			     ;AN000;
;
	       DEC  BX			     ;AN000;make zero based
	       MOV  AX,VECSEGLEN	     ;AN000;multiply SCB element length by
	       ADD  AX,VECOFFLEN	     ;AN000; desired vector number in BX
	       MUL  BX			     ;AN000; to determine offset into SCB vec
	       ADD  DI,AX		     ;AN000;add offset inside table
	       MOV  BX,ES:[DI]		     ;AN000;get actual SCB segment
	       MOV  CX,ES:[DI]+VECSEGLEN     ;AN000;point past SCB seg to get SCB off
;
	       MOV  ES,BX		     ;AN000;set ES:DI to scroll's actual
	       MOV  DI,CX		     ;AN000; SCB address
;
	       POP  DX			     ;AN000;GHG
	       POP  CX			     ;AN000;
	       POP  BX			     ;AN000;
	       POP  AX			     ;AN000;
;
	       RET			     ;AN000;
GET_SCB        ENDP			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GET_ICB
;
;	  Get Input Control Block information.
;
; Entry:  BX = Number of ICB vector desired.
;
; Exit:   ES:DI = Address of ICB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GET_ICB        PROC NEAR		     ;AN000;
	       PUSH AX			     ;AN000;
	       PUSH BX			     ;AN000;
	       PUSH CX			     ;AN000;
	       PUSH DX			     ;AN000;GHG
;
; read input control block vector to obtain ICB address
;
	       PUSH WR_ICBVECSEG	     ;AN000;get beginning ICB vector address
	       POP  ES			     ;AN000;
	       PUSH WR_ICBVECOFF	     ;AN000;
	       POP  DI			     ;AN000;

	       DEC  BX			     ;AN000;make zero based
	       MOV  AX,VECSEGLEN	     ;AN000;multiply ICB element length by
	       ADD  AX,VECOFFLEN	     ;AN000; desired vector number in BX
	       MUL  BX			     ;AN000; to determine offset into ICB vec
	       ADD  DI,AX		     ;AN000;add offset inside table
	       MOV  BX,ES:[DI]		     ;AN000;get actual ICB segment
	       MOV  CX,ES:[DI]+VECSEGLEN     ;AN000;point past ICB seg to get ICB off

	       MOV  ES,BX		     ;AN000;set ES:DI to field's actual
	       MOV  DI,CX		     ;AN000; ICB address

	       POP  DX			;AN000;GHG
	       POP  CX			;AN000;
	       POP  BX			;AN000;
	       POP  AX			;AN000;
	       RET			;AN000;
GET_ICB        ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; REFRESH_FLDS
;
;	  Refresh specified input and scrolling fields in the logical video   :
;	  buffer during screen build.
;
;	  Format = DW  Panel control block number
;		   DW  Number of fields in this record
;		   DW  Object type ID
;		   DW  Field ID
;
;		   DW  Object type ID
;		   DW  Field ID
;
; Entry:  WR_REFNUM   = Number of PCB entries
;	  WR_REFOFF   = Offset of table
;	  WR_REFSEG   = Segment of table
;
;	  PM_PANBRKID = Panel PCB number to refresh
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
REFRESH_FLDS   PROC NEAR		;AN000;
	       PUSH AX			     ;AN000;save registers
	       PUSH BX			     ;AN000;
	       PUSH CX			     ;AN000;
	       PUSH DX			     ;AN000;
	       PUSH ES			     ;AN000;
	       PUSH DI			     ;AN000;
;
; Initialize for table search
;
	       MOV  CX,WR_REFNUM	     ;AN000;get number of refresh table recs
	       CMP  CX,0		     ;AN000;check the number of PCB entries
	       JA   RF10		     ;AN000;
	       JMP  RFEXIT		     ;AN000;no records, exit

RF10:	       PUSH WR_REFOFF		     ;AN000;get address of refresh table
	       POP  WR_REFCNT		     ;AN000;

	       PUSH WR_REFSEG		     ;AN000;
	       POP  ES			     ;AN000;
;
; Locate matching table and PCB break number
;
RF20:	       MOV  DI,WR_REFCNT	     ;AN000;set beginning address of current
					     ; table record

	       MOV  AX,ES:[DI]+2	     ;AN000;get number of fields in record
	       MOV  BX,4		     ;AN000;4 bytes per field entry *
	       MUL  BX			     ;AN000; number of fields in this record
	       ADD  WR_REFCNT,AX	     ;AN000; + 4 bytes for the number of
	       ADD  WR_REFCNT,4 	     ;AN000; PCB bytes and the number of flds

	       MOV  BX,PM_PANBRKID	     ;AN000;
	       CMP  BX,ES:[DI]		     ;AN000;check if PCB match to table rec
	       JE   RF30		     ;AN000;

	       LOOP RF20		     ;AN000;check next table record
	       JMP  RFEXIT		     ;AN000;no match, exit
;
; Match found, refresh all fields
;
RF30:	       MOV  CX,ES:[DI]+2	     ;AN000;get number of fields

RF40:	       ADD  DI,4		     ;AN000;point to field data
	       MOV  AX,SCROLLOBJID	     ;AN000;check if scroll field
	       CMP  AX,ES:[DI]		     ;AN000;
	       JNE  RF50		     ;AN000;

	       MOV  BX,ES:[DI]+2	     ;AN000;get field ID
	       CALL REFRESH_SCB 	     ;AN000;update logical video buffer
	       JMP  RF60		     ;AN000;get next field entry

RF50:	       MOV  AX,INPUTOBJID	     ;AN000;check if input field
	       CMP  AX,ES:[DI]		     ;AN000;
	       JNE  RF60		     ;AN000;

	       MOV  BX,ES:[DI]+2	     ;AN000;get field ID
	       CALL REFRESH_ICB 	     ;AN000;update logical video buffer

RF60:	       LOOP RF40		     ;AN000;get next field in same record

RFEXIT:        POP  DI			     ;AN000;restore registers
	       POP  ES			     ;AN000;
	       POP  DX			     ;AN000;
	       POP  CX			     ;AN000;
	       POP  BX			     ;AN000;
	       POP  AX			     ;AN000;

	       RET			     ;AN000;
REFRESH_FLDS   ENDP			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; REFRESH_SCB
;
;	  Refresh scroll field in logic video buffer and exit.
;
; Entry:  BX = Scroll ID field number
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
REFRESH_SCB    PROC NEAR		     ;AN000;
	       PUSH ES			     ;AN000;save registers
	       PUSH DI			     ;AN000;

	       CALL GET_SCB		     ;AN000;load SCB address

	       PUSH ES:[DI]+SCB_OPT1	     ;AN000;save options
	       PUSH ES:[DI]+SCB_OPT3	     ;AN000;

	       OR   ES:[DI]+SCB_OPT1,SCB_RD  ;AN000;set display and exit option
	       AND  ES:[DI]+SCB_OPT1,NOT SCB_UKS;AN000;
	       OR   ES:[DI]+SCB_OPT3,SCB_LVBOVR;AN000;

	       PUSH PM_LVBOFF		     ;AN000;initialize logical video address
	       POP  ES:[DI]+SCB_LVBOFF	     ;AN000;

	       PUSH PM_LVBSEG		     ;AN000;
	       POP  ES:[DI]+SCB_LVBSEG	     ;AN000;

	       CALL PCSLCTP_CALL	     ;AN000;refresh logical video buffer

	       POP  ES:[DI]+SCB_OPT3	     ;AN000;restore option
	       POP  ES:[DI]+SCB_OPT1	     ;AN000;

RSEXIT:        POP  DI			     ;AN000;restore registers
	       POP  ES			     ;AN000;

	       RET			     ;AN000;
REFRESH_SCB    ENDP			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; REFRESH_ICB
;
;	  Refresh input field in logic video buffer and exit.
;
; Entry:  BX = Input ID field number
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
REFRESH_ICB    PROC NEAR		;AN000;
	PUSH	AX			;AN000;
	PUSH	ES			;AN000;save registers
	PUSH	DI			;AN000;
	PUSH	IN_ICBID		;AN000;
					;
	MOV	IN_ICBID,BX		;AN000;
	CALL	GET_ICB 		;AN000;load ICB address
					;
	CMP	ES:[DI]+ICB_FIELDLEN  ,0;AN000;
	CMP	ES:[DI]+ICB_FIELDOFF  ,0;AN000;
	CMP	ES:[DI]+ICB_FIELDSEG  ,0;AN000;
	CMP	ES:[DI]+ICB_DEFLEN    ,0;AN000;
	CMP	ES:[DI]+ICB_DEFOFF    ,0;AN000;
	CMP	ES:[DI]+ICB_DEFSEG    ,0;AN000;

	PUSH	IN_OPT			;AN000;
	PUSH	ES:[DI]+ICB_OPT1	;AN000;
	OR	ES:[DI]+ICB_OPT1,ICB_OUT;AN000;
	OR	IN_OPT,IN_LVBOV 	;AN000;
					;
	PUSH PM_LVBOFF			;AN000;initialize logical video address
	POP  IN_LVBOFF			;AN000;
					;
	PUSH PM_LVBSEG			;AN000;
	POP  IN_LVBSEG			;AN000;
					;
	CALL	PCINPUT_CALL		;AN000;
					;
	POP	ES:[DI]+ICB_OPT1	;AN000;
	POP	IN_OPT			;AN000;
	CALL	CURSOROFF		;AN000;
					;
	POP	IN_ICBID		;AN000;
	POP	DI			;AN000;restore registers
	POP	ES			;AN000;
	POP	AX			;AN000;
	RET				;AN000;
REFRESH_ICB	ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CURSOROFF
;
;	  Deactivates cursor from display.
;
; Entry:  None
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;
CURSOROFF  PROC NEAR	;AN000;
	PUSH	AX	;AN000;save registers
	PUSH	BX	;AN000;
	PUSH	CX	;AN000;
			;
	MOV	AH,3	;AN000;function to get cursor info
	MOV	BH,0	;AN000;page zero
	INT	10H	;AN000;
	OR	CH,20H	;AN000;set bit 6
	MOV	AH,1	;AN000;function to set cursor
	INT	10H	;AN000;
			;
	POP	CX	;AN000;restore registers
	POP	BX	;AN000;
	POP	AX	;AN000;
	RET		;AN000;
CURSOROFF	  ENDP	;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CURSORON
;
;	  Activates cursor display on screen.
;
; Entry:  None
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CURSORON       PROC NEAR	;AN000;
	PUSH	AX		;AN000;save registers
	PUSH	BX		;AN000;
	PUSH	CX		;AN000;
				;
	MOV	AH,3		;AN000;function to get cursor info
	MOV	BH,0		;AN000;page zero
	INT	10H		;AN000;
	AND	CH,NOT 20H	;AN000;clear bit 6
	MOV	AH,1		;AN000;function to set cursor
	INT	10H		;AN000;
				;
	POP	CX		;AN000;restore registers
	POP	BX		;AN000;
	POP	AX		;AN000;
				;
	RET			;AN000;
CURSORON	  ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCINCHA_CALL
;
;	  Call to PCINCHA.
;
; Entry:  PB initialized.
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCINCHA_CALL	PROC NEAR	;AN000;
				;
	CALL	CLEAR_INBUFF	;AN088;SEH this call was moved and now replaced to exist both before and after call
				;
	PUSH	DS		;AN000;set segment
	POP	ES		;AN000;
	PUSH	DS		;AN000;
	PUSH	DI		;AN000;save registers
	LEA	DI,INC_OPT	;AN000;set DI to proper parameter block
				; for call
IF CASRM			;AN000;
	MOV	AH,00H		;AN000;make call to CAS-RM
	MOV	BX,INC_RN	;AN000;set CAS routine number
	INT	CASINT		;AN000;call routine
ELSE				;AN000;
	CALL	INCHA		;AN000;
	CALL	CLEAR_INBUFF	;AC083;SEH call moved to after call to INCHA in order to flush buffer ;AN059;
ENDIF				;AN000;
	POP	DI		;AN000;restore registers
	POP	DS		;AN000;
	RET			;AN000;
PCINCHA_CALL   ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCDISPQ_CALL
;
;	  Call to PCDISPQ.
;
; Entry:  PB initialized.
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCDISPQ_CALL   PROC NEAR		;AN000;
	       PUSH DS			;AN000;set segment
	       POP  ES			;AN000;
	       PUSH DS			;AN000;
	       PUSH DI			;AN000;save registers
	       LEA  DI,QM_OPT1		;AN000;set DI to proper parameter block
IF CASRM				;AN000;
	       MOV  AH,00H		;AN000;make call to CAS-RM
	       MOV  BX,QM_RN		;AN000;set CAS routine number
	       INT  CASINT		;AN000;call routine
ELSE					;AN000;
	       CALL DISPQ		;AN000;
ENDIF					;AN000;
	       POP  DI			;AN000;restore registers
	       POP  DS			;AN000;
	       RET			;AN000;
PCDISPQ_CALL   ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCPANEL_CALL
;
;	  Initialize for call to PCPANEL including refresh of input and
;	  scroll fields in the logical video buffer before display.
;
; Entry:  PB initialized.
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCPANEL_CALL   PROC NEAR		;AN000;
	       PUSH QM_PANQUENUM	;AN000;
	       POP  PM_PANQUENUM	;AN000;number of panels in parent queue
					;
	       PUSH QM_CHDQUENUM	;AN000;
	       POP  PM_CHDQUENUM	;AN000;number panels in child queue
					;
	       PUSH QM_ACTIVEPAN	;AN000;
	       POP  PM_ACTIVEPAN	;AN000;active parent panel number
					;
	       MOV  BX,PM_DOA		;AN000;display child panels in active
	       OR   BX,PM_DOV		;AN000;use child row, col, color overrid
	       OR   BX,PM_DOQ		;AN000;display childs in active parent
	       OR   BX,PM_CL		;AN000;initialize LVB to base char/attr
					;
	       CMP  AX,1		;AN000;check if break option is on
	       JNE  PP05		;AN000;
					;
	       CMP  WR_REFIELDCNT,0	;AN000;GHG
	       JNE  PP06		;AN000;GHG
	       XOR  AX,AX		;AN000;GHG
	       JMP  PP05		;AN000;GHG
					;
PP06:	       OR   BX,PM_BK		;AN000;set panel manager break option on
					;
PP05:	       MOV  PM_OPT1,BX		;AN000;set options
	       MOV  PM_PANPDQNUM,1	;AN000;beg/ending parent PDQ number
	       MOV  PM_PANBRKOFF,0	;AN000;panel off in lvb of break panel
	       JMP  PP20		;AN000;begin update
					;set options to continue panel break
PP10:	       AND  PM_OPT1,NOT PM_CL	;AN000;turn init LVB base char/attr off
					;do Actual PCPANEL call
PP20:	       PUSH DS			;AN000;set segment
	       POP  ES			;AN000;
	       PUSH DS			;AN000;
	       PUSH DI			;AN000;save registers
	       LEA  DI,PM_OPT1		;AN000;set DI to proper parameter block
IF CASRM				;AN000;
	       MOV  AH,00H		;AN000;make call to CAS-RM
	       MOV  BX,PM_RN		;AN000;set CAS routine number
	       INT  CASINT		;AN000;call routine
ELSE					;AN000;
	       CALL PANEL		;AN000;
ENDIF					;AN000;
	       POP  DI			;AN000;restore registers
	       POP  DS			;AN000;
					;
	       CMP  AX,1		;AN000;check if the break option is
	       JNE  PPEXIT		;AN000; active
					;
	       MOV  AX,PM_PANPDQNUM	;AN000;beg/ending parent PDQ number
	       DEC  AX			;AN000;adjust for possible break option
					; on last panel in PDQ
	       CMP  AX,PM_PANQUENUM	;AN000;check if all panels updated
	       JA   PPEXIT		;AN000; when complete var is 1 greater
					;
	       CALL REFRESH_FLDS	;AN000;refresh fields in break panel
	       JMP  PP10		;AN000;continue to process panels
PPEXIT:        RET			;AN000;
PCPANEL_CALL   ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCMBEEP_CALL
;
;	  Call to PCMBEEP.
;
; Entry:  PB initialized.
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCMBEEP_CALL   PROC NEAR		;AN000;
	       PUSH DS			;AN000;set segment
	       POP  ES			;AN000;
	       PUSH DS			;AN000;
	       PUSH DI			;AN000;save registers
	       LEA  DI,MB_FREQUENCY	;AN000;set DI to proper parameter block
IF CASRM				;AN000;
	       MOV  AH,00H		;AN000;make call to CAS-RM
	       MOV  BX,MB_RN		;AN000;set CAS routine number
	       INT  CASINT		;AN000;call routine
ELSE					;AN000;
	       CALL MBEEP		;AN000;
ENDIF					;AN000;
	       POP  DI			;AN000;restore registers
	       POP  DS			;AN000;
	       RET			;AN000;
PCMBEEP_CALL   ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCSLCTP_CALL
;
;	  Call to PCSCLTP.
;
; Entry:  ES:DI = beginning address of PCSLCTP parameter block.
;
; Exit:   None
;
;
; Initialize color index vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCSLCTP_CALL   PROC NEAR		 ;AN000;
					 ;
	       CALL CLEAR_INBUFF	 ;AN059;
					 ;
	       PUSH PM_CCBVECNUM	 ;AN000;set color index number
	       POP  ES:[DI]+SCB_CCBVECNUM;AN000;

	       PUSH CRD_CCBVECOFF	 ;AN000;set color index offset
	       POP  ES:[DI]+SCB_CCBVECOFF;AN000;

	       PUSH CRD_CCBVECSEG	 ;AN000;set color index segment
	       POP  ES:[DI]+SCB_CCBVECSEG;AN000;

	       PUSH ES:[DI]+SCB_OPT1	 ;AN000;
	       PUSH ES:[DI]+SCB_OPT2	 ;AN000;
	       PUSH ES:[DI]+SCB_OPT3	 ;AN000;
	       PUSH ES:[DI]+SCB_NUMLINE  ;AN000;
	       AND  ES:[DI]+SCB_OPT3,NOT SCB_NUMS;AN000;
IF CASRM				 ;AN000;
	       MOV  AH,00H		     ;AN000;make call to CAS-RM
	       MOV  BX,SCB_RN		     ;AN000;set CAS routine number
	       INT  CASINT		     ;AN000;call slctopt
ELSE					     ;AN000;
	       CALL SLCTP		     ;AN000;
ENDIF					     ;AN000;
	       POP  ES:[DI]+SCB_NUMLINE      ;AN000;
	       POP  ES:[DI]+SCB_OPT3	     ;AN000;
	       POP  ES:[DI]+SCB_OPT2	     ;AN000;
	       POP  ES:[DI]+SCB_OPT1	     ;AN000;
	       RET			     ;AN000;
PCSLCTP_CALL   ENDP			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCHLPRD_CALL
;
;	  Call to PCHLPRD.
;
; Entry:  PB initialized.
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCHLPRD_CALL   PROC NEAR		 ;AN000;
	       PUSH DS			 ;AN000;set segment
	       POP  ES			 ;AN000;
	       PUSH DS			 ;AN000;
	       PUSH DI			 ;AN000;save registers
	       LEA  DI,HRD_OPT1 	 ;;AN000;set DI to proper parameter block
IF CASRM				 ;AN000;
	       MOV  AH,00H		 ;AN000;make call to CAS-RM
	       MOV  BX,HRD_RN		 ;AN000;set CAS routine number
	       INT  CASINT		 ;AN000;call routine
ELSE					 ;AN000;
	       CALL HLPRD		 ;AN000;
ENDIF					 ;AN000;
	       .IF < HRD_ERROR eq 0 > and;AN005;GHG
	       .IF < HRD_DOSERROR eq 0 > ;AN005;GHG
		  CLC			 ;AN005;GHG
	       .ELSE			 ;AN005;GHG
		  STC			 ;AN005;GHG
	       .ENDIF			 ;AN005;GHG
					 ;
	       POP  DI			 ;AN000;restore registers
	       POP  DS			 ;AN000;
	       RET			 ;AN000;
PCHLPRD_CALL   ENDP			 ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCINSTR_CALL
;
;	  Call to PCINSTR.
;
; Entry:  PB initialized.
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCINSTR_CALL   PROC NEAR		 ;AN000;
	       PUSH DS			 ;AN000;set segment
	       POP  ES			 ;AN000;
	       PUSH DS			 ;AN000;
	       PUSH DI			 ;AN000;save registers
	       LEA  DI,INS_OPT		 ;;AN000;set DI to proper parameter block
IF CASRM				 ;AN000;
	       MOV  AH,00H		 ;AN000;make call to CAS-RM
	       MOV  BX,INS_RN		 ;AN000;set CAS routine number
	       INT  CASINT		 ;AN000;call routine
ELSE					 ;AN000;
	       CALL INSTRN		 ;AN000;
ENDIF					 ;AN000;
	       POP  DI			 ;AN000;restore registers
	       POP  DS			 ;AN000;
	       RET			 ;AN000;
PCINSTR_CALL   ENDP			 ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCINPUT_CALL
;
;	  Call to PCINPUT.
;
; Entry:  PB initialized.
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCINPUT_CALL   PROC NEAR		 ;AN000;
					 ;
	       CALL CLEAR_INBUFF	 ;AN059;
					 ;
	       PUSH DS			 ;AN000;set segment
	       POP  ES			 ;AN000;
	       PUSH DS			 ;AN000;
	       PUSH DI			 ;AN000;save registers
	       LEA  DI,IN_OPT		 ;AN000;set DI to proper parameter block
IF CASRM				 ;AN000;
	       MOV  AH,00H		 ;AN000;make call to CAS-RM
	       MOV  BX,IN_RN		 ;AN000;set CAS routine number
	       INT  CASINT		 ;AN000;call slctopt
ELSE					 ;AN000;
	       CALL INPUT		 ;AN000;
ENDIF					 ;AN000;
	       POP  DI			 ;AN000;restore registers
	       POP  DS			 ;AN000;
	       RET			 ;AN000;
PCINPUT_CALL   ENDP			 ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCGVIDO_CALL
;
;	  Call to PCGVIDO.
;
; Entry:  PB initialized.
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCGVIDO_CALL   PROC NEAR	;AN000;
	PUSH DS 		;AN000;set segment
	POP  ES 		;AN000;
	PUSH DS 		;AN000;
	PUSH DI 		;AN000;save registers
	LEA  DI,GV_STAT1	;AN000;set DI to proper parameter block
IF CASRM			;AN000;
	MOV  AH,00H		;AN000;make call to CAS-RM
	MOV  BX,GV_RN		;AN000;set CAS routine number
	INT  CASINT		;AN000;call routine
ELSE				;AN000;
	CALL GVIDO		;AN000;
ENDIF				;AN000;
	POP  DI 		;AN000;restore registers
	POP  DS 		;AN000;
	RET			;AN000;
PCGVIDO_CALL   ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCWWRAP_CALL
;
;	  Call to PCWWRAP.
;
; Entry:  PB initialized.
;
; Exit:   None
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCWWRAP_CALL   PROC NEAR	;AN000;
	PUSH DS 		;AN000;set segment
	POP  ES 		;AN000;
	PUSH DS 		;AN000;
	PUSH DI 		;AN000;save registers
	LEA  DI,WWP_OPT1	;AN000;set DI to proper parameter block
IF CASRM			;AN000;
	MOV  AH,00H		;AN000;make call to CAS-RM
	MOV  BX,PM_RN		;AN000;set CAS routine number
	INT  CASINT		;AN000;call slctopt
ELSE				;AN000;
	CALL WWRAP		;AN000;
ENDIF				;AN000;
	POP  DI 		;AN000;restore registers
	POP  DS 		;AN000;
	RET			;AN000;
PCWWRAP_CALL   ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; INITIALIZE
;
;	  Initialize the DOS allocated buffer with data (color, panels
;	  scrolling fields) and reserve room for help, queue management
;	  and the logical video buffer.
;
; Entry:  WR_DATA2LEN = Length of DOS allocated buffer
;	  WR_DATA2OFF = Offset of DOS allocated buffer
;	  WR_DATA2SEG = Segment of DOS allocated buffer
;
; Exit:   CY=0 and WR_ERROR = 0, No error occurred, 1= error occurred
;	  WR_DATA2LEN = Amount of DOS allocated buffer remaining
;	  WR_DATA2OFF = New offset of DOS allocated buffer
;
;	ELSE
;	  CY=1 and WR_ERROR = 1, Error occurred (WR_DATA2LEN/OFF are invalid)
;
; CY support added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INITIALIZE     PROC NEAR		;AN000;
					;AN000;
	PUSH ES 			;AN000;
	PUSH DI 			;AN000;
	PUSH DS 			;AN000;
	PUSH SI 			;AN000;
					;AN000;
	MOV  WR_ERROR,0 		;AN000;reset error inidicator
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Read Compressed Panel file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	MOV  DX,OFFSET CFILE		;AN024;filename to read , SELECT.DAT
	XOR  AL,AL			;AN024;
	MOV  AH,3DH			;AN024;
	INT  21H			;AN024;open file
					;AN024;
	MOV  BX,AX			;AN024;get file handle
	PUSH BX 			;AN024;save it
	XOR  CX,CX			;AN024;
	XOR  DX,DX			;AN024;
	MOV  AL,2			;AN024;move ptr to end of file
	MOV  AH,42H			;AN024;LSEEK
	INT  21H			;AN024;
					;AN024;
	PUSH AX 			;AN024;save length
	XOR  CX,CX			;AN024;zero file offset
	XOR  DX,DX			;AN024;      "
	MOV  AL,0			;AN024;move ptr to start of file
	MOV  AH,42H			;AN024;LSEEK
	INT  21H			;AN024;
	POP  BX 			;AN024;restore length
	PUSH BX 			;AN024;save it again
	SHR  BX,1			;AN024;convert to paragraph
	SHR  BX,1			;AN024;
	SHR  BX,1			;AN024;
	SHR  BX,1			;AN024;
	INC  BX 			;AN024;ensure enough room
	MOV  AX,BX			;AN024;
					;AN024;
	POP  CX 			;AN024;restore length
	POP  BX 			;AN024;restore file handle

	MOV  DX,WR_DATA2SEG		;AN024;GS:DI = target
	ADD  DX,MAX_MEMPAR		;AN024;
	SUB  DX,AX			;AN024;
	MOV  DS,DX			;AN024;get segment of read buffer
	XOR  DX,DX			;AN024;get offset to read into
	MOV  AH,3FH			;AN024;read it
	INT  21H			;AN024;
					;AN024;
	MOV  AH,3EH			;AN024;close it
	INT  21H			;AN024;
					;AN024;
	PUSH DS 			;AN024;save source segment
	MOV  AX,DATA			;AN024;
	MOV  DS,AX			;AN024;get DATA segment
	MOV  AX,WR_DATA2SEG		;AN024;ES:DI = target
	MOV  ES,AX			;AN024;
	MOV  DI,WR_DATA2OFF		;AN024;
	POP  DS 			;AN024;restore source segment
	XOR  SI,SI			;AN024;offset is zero
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Expand Panel file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	MOV  DX,0			;AN024;initialize result string
EC1:	CMP  CX,0			;AN024;any characters left?
	JNE  EC2			;AN024;yes
	JMP  DONE1			;AN024;no
					;AN024;
EC2:	LODSB				;AN024;get character
	DEC  CX 			;AN024;adjust character count
	MOV  BL,1			;AN024;set default repeat
	CMP  AL,REPCHAR 		;AN024;is it a repeat character
	JNE  EC4			;AN024;no
					;AN024;
	CMP  CX,0			;AN024;any characters left?
	JNE  EC2_4			;AN024;
	JMP  DONE1			;AN024;no
					;AN024;
EC2_4:	LODSB				;AN024;get number of characters
	DEC  CX 			;AN024;Adjust character count
	CMP  AL,REPCHAR 		;AN024;is it still the repeat character
	JNE  EC2_1			;AN024;no
	JMP  EC4			;AN024;
					;AN024;
EC2_1:	CMP  AL,1			;AN024;code <CR>?
	JNE  EC2_2			;AN024;no
					;AN024;
	MOV  AL,13			;AN024;
	JMP  EC4			;AN024;
					;AN024;
EC2_2:	CMP  AL,2			;AN024;code <EOF>?
	JNE  EC3			;AN024;no
					;AN024;
	MOV  AL,26			;AN024;
	JMP  EC4			;AN024;
					;AN024;
EC3:	MOV  BL,AL			;AN024;save number of repeats
					;AN024;
	CMP  CX,0			;AN024;any characters left?
	JNE  EC3_6			;AN024;
	JMP  DONE1			;AN024;no
					;AN024;
EC3_6:	LODSB				;AN024;get actual character
	DEC  CX 			;AN024;adjust character count
	CMP  AL,REPCHAR 		;AN024;coded character?
	JNE  EC4			;AN024;no
					;AN024;
	CMP  CX,0			;AN024;any characters left?
	JNE  EC3_8			;AN024;
	JMP  DONE1			;AN024;no
					;AN024;
EC3_8:	LODSB				;AN024;yes
	DEC  CX 			;AN024;adjust character count
	CMP  AL,REPCHAR 		;AN024;coded repchar?
	JE   EC4			;AN024;yes
					;AN024;
	CMP  AL,1			;AN024;coded <CR>?
	JNE  EC3_1			;AN024;no
					;AN024;
	MOV  AL,13			;AN024;yes
	JMP  EC4			;AN024;
					;AN024;
EC3_1:	CMP  AL,2			;AN024;coded <EOF>?
	JNE  EC3_2			;AN024;no
					;AN024;
	MOV  AL,26			;AN024;
	JMP  EC4			;AN024;
					;AN024;
EC3_2:	INC  CX 			;AN024;unknown, restore
	DEC  SI 			;AN024;
	MOV  AL,REPCHAR 		;AN024;
					;AN024;
EC4:	ADD  DL,BL			;AN024;adjust length
	ADC  DH,0			;AN024;
					;AN024;
EC7:	PUSH CX 			;AN024;save CX
	XOR  CX,CX			;AN024;zero CX
	MOV  CL,BL			;AN024;set repeat number
					;AN024;
EC8:	REP  STOSB			;AN024;store char
	POP  CX 			;AN024;recover CX
	JMP  EC1			;AN024;
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Finished expanding panel file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
DONE1:					;AN024;
	MOV  AX,DATA			;AN024;restore DATA segment
	MOV  DS,AX			;AN024;
					;AN024;
	MOV  DI,WR_DATA2OFF		;AN024;restore pointer to start
	ADD  DX,16			;AN024;add paragraph to expanded length
	ADD  WR_DATA2OFF,DX		;AN024;save new available offset
					;AN024;
	MOV  AX,WR_DATA2LEN		;AN024;calculate remaining buffer space
	SUB  AX,DX			;AN024; from required space
	MOV  WR_DATA2LEN,AX		;AN024;set remaining space
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; initialize Color Table information
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	.IF < GV_VIDMODE eq 7 > or	;AN000;
	.IF < ACTIVE eq LCD >		;AN000;
	.THEN				;AN000;
	      MOV  AX,ES:[DI].MONTBL	;AN000;
	      MOV  BX,ES:[DI].NMONTBL	;AN000;
	.ELSE				;AN000;
	      MOV  AX,ES:[DI].COLTBL	;AN000;
	      MOV  BX,ES:[DI].NCOLTBL	;AN000;
	.ENDIF				;AN000;
					;AN000;
	MOV  PM_CCBVECNUM,BX		;AN000;
	MOV  PM_CCBVECOFF,AX		;AN000;set color index offset to PCPANEL
	MOV  CRD_CCBVECOFF,AX		;AN000;set color index offset to PCPANEL
	MOV  AX,ES			;AN000;set color index segment to
	MOV  PM_CCBVECSEG,AX		;AN000; PCPANEL
	MOV  CRD_CCBVECSEG,AX		;AN000; PCPANEL
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; initialize PCDISPQ information
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	MOV  AX,ES:[DI].NPCBS		;AN000;
	MOV  QM_PCBVECNUM,AX		;AN000;number of PCB elements in vector
					;AN000;
	MOV  AX,ES:[DI].PCBS		;AN000;
	MOV  QM_PCBVECOFF,AX		;AN000;offset of PCB vector
					;AN000;
	MOV  AX,ES			;AN000;
	MOV  QM_PCBVECSEG,AX		;AN000;segment of PCB vector
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; initialize PCPANEL with PCDISPQ and PCPANRD information
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	MOV  SI,ES:[DI].PCBS		;AN000;offset of PCB vector read from
	MOV  PM_PCBVECOFF,SI		;AN000; disk
					;AN000;
	MOV  AX,ES			;AN000;segment of PCB vector read from
	MOV  PM_PCBVECSEG,AX		;AN000; disk
					;AN000;
	MOV  CX,ES:[DI].NPCBS		;AN000;number of PCB vectors read from
	MOV  PM_PCBVECNUM,CX		;AN000; disk
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; add segment address to PCBs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	ADD  SI,2			;AN000;move to offset
I_PCB_SEG:				;AN000;
	MOV  BX,ES:[SI] 		;AN000;
	MOV  ES:[BX].PCB_EXPANDSEG,AX	;AN000;
	MOV  ES:[BX].PCB_CHILDSEG,AX	;AN000;
	ADD  SI,4			;AN000;
	LOOP I_PCB_SEG			;AN000;
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; add segment address to PCB vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	MOV  CX,ES:[DI].NPCBS		;AN000;number of PCB vectors
	MOV  SI,ES:[DI].PCBS		;AN000;offset of PCB vectors
I_PCBVEC_SEG:				;AN000;
	MOV  ES:[SI],AX 		;AN000;
	ADD  SI,4			;AN000;
	LOOP I_PCBVEC_SEG		;AN000;
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; initialize SCB vector table pointer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	MOV  AX,ES			;AN000;
	MOV  SRD_SCBVECSEG,AX		;AN000;get beginning SCB vector address
	MOV  SI,ES:[DI].SCBS		;AN000;
	MOV  SRD_SCBVECOFF,SI		;AN000;
	MOV  CX,ES:[DI].NSCBS		;AN000;number of SCB vectors
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; add segment address to SCBs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	ADD  SI,2			;AN000;move to offset
					;AN000;
I_SCB_SEG:				;AN000;
	MOV  BX,ES:[SI] 		;AN000;
	MOV  ES:[BX].SCB_UASEG,AX	;AN000;
	MOV  ES:[BX].SCB_DASEG,AX	;AN000;
	MOV  ES:[BX].SCB_PUSEG,AX	;AN000;
	MOV  ES:[BX].SCB_PDSEG,AX	;AN000;
	MOV  ES:[BX].SCB_PISEG,AX	;AN000;
	MOV  ES:[BX].SCB_AISEG,AX	;AN000;
	MOV  ES:[BX].SCB_CISEG,AX	;AN000;
	MOV  ES:[BX].SCB_UISEG,AX	;AN000;
	MOV  ES:[BX].SCB_DISEG,AX	;AN000;
	MOV  ES:[BX].SCB_INDEXSEG,AX	;AN000;
	MOV  ES:[BX].SCB_SELSEG,AX	;AN000;
	MOV  ES:[BX].SCB_OAPSEG,AX	;AN000;
	MOV  ES:[BX].SCB_OASSEG,AX	;AN000;
	ADD  SI,4			;AN000;
	LOOP I_SCB_SEG			;AN000;
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; add segment address to SCB vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	MOV  CX,ES:[DI].NSCBS		;AN000;number of SCB vectors
	MOV  SI,ES:[DI].SCBS		;AN000;offset of SCB vectors
I_SCBVEC_SEG:				;AN000;
	MOV  ES:[SI],AX 		;AN000;
	ADD  SI,4			;AN000;
	LOOP I_SCBVEC_SEG		;AN000;
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Init 4KB for logical video buffer for PCPANEL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
					;AN000;
	MOV  AX,GV_SCRWIDTH		;AN000;
	MOV  PM_LVBWIDTH,AX		;AN000;width of log vid buf in bytes
					;AN000;
	MOV  AX,GV_SCRLEN		;AN000;
	MOV  PM_LVBLEN,AX		;AN000;number bytes in logical video
					;AN000;
	PUSH WR_LVBOFF			;AN000;
	POP  PM_LVBOFF			;AN000;offset of logical video buffer
					;AN000;
	PUSH WR_LVBSEG			;AN000;set the allocated segment
	POP  PM_LVBSEG			;AN000;
					;AN000;
	MOV  AX,WR_LVBLEN		;AN000;calculate remaining buffer
	SUB  AX,GV_SCRLEN		;AN000;
	MOV  WR_LVBLEN,AX		;AN000;set remaining space
					;AN000;
	MOV  AX,GV_SCRLEN		;AN000;
	ADD  WR_LVBOFF,AX		;AN000;set new free buffer offset
					;AN000;
	MOV  LVB_INITED,TRUE		;AN000;LVB always remains
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCDISPQ buffer initialization option
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	MOV  QM_OPT1,QM_INIT		;AN000;Initialize working buffer
					;AN000;
	PUSH WR_MAXCHDQUE		;AN000;
	POP  QM_MAXCHDQUE		;AN000;max # of child queues to save
					;AN000;
	PUSH WR_MAXPANQUE		;AN000;
	POP  QM_MAXPANQUE		;AN000;max # of panel queues to save
					;AN000;
	PUSH WR_MAXNUMCHD		;AN000;
	POP  QM_MAXNUMCHD		;AN000;max # of parent panels queued
					;AN000;
	PUSH WR_MAXNUMPAN		;AN000;
	POP  QM_MAXNUMPAN		;AN000;max # of child panels queued
					;AN000;
	PUSH WR_LVBLEN			;AN000;
	POP  QM_BUFLEN			;AN000;length of avail buffer
					;AN000;
	PUSH WR_LVBOFF			;AN000;
	POP  QM_BUFOFF			;AN000;offset of buffer
					;AN000;
	PUSH WR_LVBSEG			;AN000;
	POP  QM_BUFSEG			;AN000;segment of buffer
					;AN000;
	CALL PCDISPQ_CALL		;AN000;update display queue
					;AN000;
	MOV  AX,WR_LVBLEN		;AN000;calculate remaining buffer space
	SUB  AX,QM_BUFLEN		;AN000; from required space
	MOV  WR_LVBLEN,AX		;AN000;set remaining space
					;AN000;
	MOV  AX,QM_BUFLEN		;AN000;add returned buffer size
	ADD  WR_LVBOFF,AX		;AN000;set new free buffer offset
					;AN000;
	PUSH QM_PANQUEOFF		;AN000;offset address of parent queue
	POP  PM_PANQUEOFF		;AN000;offset address of parent queue
					;AN000;
	PUSH QM_PANQUESEG		;AN000;segment address of parent queue
	POP  PM_PANQUESEG		;AN000;segment address of parent queue
					;AN000;
	PUSH QM_CHDQUEOFF		;AN000;offset of child queue
	POP  PM_CHDQUEOFF		;AN000;offset of child queue
					;AN000;
	PUSH QM_CHDQUESEG		;AN000;segment of child queue
	POP  PM_CHDQUESEG		;AN000;segment of child queue
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Reserve buffer for completed return key buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
	PUSH WR_MAXRETKSZ		;AN000;maximum number of bytes in return
	POP  WR_CRETLEN 		;AN000; buffer
					;AN000;
	PUSH WR_LVBOFF			;AN000;offset of completed return buffer
	POP  WR_CRETOFF 		;AN000;
					;AN000;
	PUSH WR_LVBSEG			;AN000;segment of completed return
	POP  WR_CRETSEG 		;AN000; buffer
					;AN000;
	MOV  AX,WR_LVBLEN		;AN000;calculate remaining buffer space
	SUB  AX,WR_MAXRETKSZ		;AN000;
	MOV  WR_LVBLEN,AX		;AN000;set remaining space
					;AN000;
	MOV  AX,WR_MAXRETKSZ		;AN000;
	ADD  WR_LVBOFF,AX		;AN000;set new free buffer offset
	CLC				;AN000;GHG
	JMP  IEXIT			;AN000;
					;AN000;
I110:	MOV  WR_ERROR,1 		;AN000;set error indicator
	STC				;AN000;GHG
IEXIT:					;AN000;exit
	POP  SI 			;AN000;
	POP  DS 			;AN000;
	POP  DI 			;AN000;
	POP  ES 			;AN000;
	RET				;AN000;
INITIALIZE     ENDP			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   INSERT_DISK_ROUTINE: Prompts user for insertion of disk into A: drive
;
;   INPUT:	DISK_PANEL - Panel number to be displayed
;		SEARCH_FILE - File to search for on diskette
;
;   OUTPUT:	none
;
;   OPERATION:	Panel macros are called to display the panel and search
;		for the file.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PUBLIC INSERT_DISK_ROUTINE		;AN000;
INSERT_DISK_ROUTINE PROC NEAR		;AN000;
					;
	.REPEAT 			;AN000;
	   MOV	   AX,PAN_INST_PROMPT	;AN000;
	   CALL    INIT_PQUEUE_CALL	;AN000;
	   MOV	   AX,DISK_PANEL	;AN000;
	   CALL    PREPARE_PANEL_CALL	;AN000;
	   MOV	   AX,PAN_HBAR		;AN000;
	   CALL    PREPARE_PANEL_CALL	;AN000;
	   CALL    HANDLE_CHILDREN	;AN000;
	   CALL    DISPLAY_PANEL_CALL	;AN000;
					;
	   MOV	   CX,FK_ENT_LEN	;AN000;
	   LEA	   DX,FK_ENT		;AN000;
	   CALL    GET_FUNCTION_CALL	;AN000;
					;
	   MOV	DI, SEARCH_FILE 	;AN000;
	   MOV	CX, E_FILE_ATTR 	;AN000;
	   CALL FIND_FILE_ROUTINE	;AN000;
	   .LEAVE < nc >		;AN000;
					;
	   MOV	   BX,ERR_DOS_DISK	;AN000;
	   MOV	   CX,E_RETURN		;AN000;
	   CALL    HANDLE_ERROR_CALL	;AN000;
	   JNC	   CONTINUE		;AN000;
	   CLEAR_SCREEN2		;AN000;
	   JMP	   EXIT_SELECT		;AN000;
CONTINUE:				;AN000;
	.UNTIL				;AN000;
					;
	RET				;AN000;
INSERT_DISK_ROUTINE	ENDP		;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Clear the input buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CLEAR_INBUFF   PROC NEAR		;AN059;
;					;
CI_1:	       MOV  AH,0BH		;AN059;
	       INT  21H 		;AN059;
	       CMP  AL,0		;AN059;
	       JE   CI_2		;AN059;
	       MOV  AH,07H		;AN059;
	       INT  21H 		;AN059;
	       JMP  CI_1		;AN059;
					;
CI_2:	       RET			;AN059;
CLEAR_INBUFF   ENDP			;AN059;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
SELECT	ENDS			;AN000;
	END			;AN000;
