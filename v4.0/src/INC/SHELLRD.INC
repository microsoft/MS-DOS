;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		 SHELLRD.INC					      :
;									      :
; Description:		 Include file for SHELLRD.ASM			      :
;									      :
; Revised:		 04-21-88					      :
;									      :
;-----------------------------------------------------------------------------+
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		INIT_GTEXT					      :
;									      :
; Description:		Initialize the PCGRAPH parameter block with the PCB   :
;			contained in AX.				      :
;									      :
; Entry:		AX    = Panel ID to initialize into PCGRAPH parameter :
;				block.					      :
;									      :
; Exit: 		ES:DI = Address of initialized PCGRAPH parameter      :
;				block.					      :
;									      :
; Entry point:		INIT_GTEXT					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
INIT_GTEXT     PROC NEAR
;
	       CALL FAR PTR GET_PCB	     ;return panel address at ES:DI
;
	       PUSH ES:[DI]+PCB_FLAGSEG      ;flag string segment
	       PUSH ES:[DI]+PCB_FLAGOFF      ;flag string offset
	       PUSH ES:[DI]+PCB_EXPANDSEG    ;segment of text string
	       PUSH ES:[DI]+PCB_EXPANDOFF    ;offset of text string
	       PUSH ES:[DI]+PCB_WIDTH	     ;width of panel
	       PUSH ES:[DI]+PCB_LROW	     ;lower right corner
	       PUSH ES:[DI]+PCB_UCOL	     ;column location of panel
	       PUSH ES:[DI]+PCB_UROW	     ;row location of panel
	       PUSH ES:[DI]+PCB_CCBID	     ;Index number of log color
	       MOV  AL,ES:[DI]+PCB_OPT4
;
	       LEA  DI,GEN_DATA 	     ;point graphics window structure
					     ; to data area
	       MOV  [DI]+G_DRAWT_F,AL	     ;set flags
	       POP  AX			     ;get color index
	       POP  BX			     ;get upper row
	       MOV  [DI]+G_DRAWTROWO,BX      ;window row origin (top left)
	       POP  [DI]+G_DRAWTCOLO	     ;window column origin
	       POP  CX			     ;get lower row and calculate
	       SUB  CX,BX		     ; number of lines in text panel
	       INC  CX
	       MOV  [DI]+G_DRAWTLINES,CX
	       POP  [DI]+G_DRAWTLEN	     ;width of panel text
;
	       POP  WORD PTR [DI].G_DRAWTSTRING
					     ;panel text string address
	       POP  WORD PTR [DI+2].G_DRAWTSTRING
	       POP  WORD PTR [DI].G_DRAWTFLAGS
					     ;panel text flag string address
	       POP  WORD PTR [DI+2].G_DRAWTFLAGS
;
	       DEC  [DI]+G_DRAWTROWO	     ;window row origin (top left)
	       DEC  [DI]+G_DRAWTCOLO	     ;window column origin
;
	       MOV  BX,G_DRAWT_WA+G_DRAWT_WC+G_DRAWT_UA
	       CMP  [DI]+G_DRAWT_F,0	     ;check if source flags option used
	       JE   IGT10
;
	       CMP  WORD PTR [DI].G_DRAWTFLAGS,0
	       JNE  IGT10
;
	       OR   BX,G_DRAWT_UF	     ;set option to use source flags
					     ; option
;
IGT10:	       MOV  [DI]+G_DRAWTOPT,BX	     ;option word
	       MOV  [DI]+G_DRAWTSKIP,0	     ;num bytes in source to next line
;
	       PUSH ES			     ;save pointer to panel data
	       PUSH DI
	       CALL FAR PTR GET_COLOR	     ;get color attribute
	       MOV  AL,ES:[DI]+CCB_A1	     ;get normal panel color
	       POP  DI			     ;point back to panel data
	       POP  ES
	       MOV  [DI]+G_DRAWT_A,AL	     ;window attribute
	       MOV  [DI]+G_DRAWTOUT,AL	     ;outline color attribute
;
	       MOV  AX,DATA		     ;point to segment containing
	       MOV  ES,AX		     ; general data area
;
	       RET
INIT_GTEXT     ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PROCESS_SCROLL					      :
;									      :
; Description:		Highlight mouse fields in the specified range as      :
;			the up and down arrows are used.  The range of mouse  :
;			fields to highlight are specified in AX and BX with   :
;			intervening fields in consecutive order.  The help    :
;			ID for each selection is calculated from the values   :
;			set to COM_HCBIDL and COM_HCBIDH.  It is important    :
;			that the help equates are in sequential order.	      :
;									      :
;			ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿		      :
;	     COM_HCBIDL ÄÄ 1. First element to highlight ÄÄÄÄ AX	      :
;			³  2.	     :	     :		  ³		      :
;			³  3.	     :	     :		  ³		      :
;	     COM_HCBIDH ÄÄ 4. Last element to highlight  ÄÄÄÄ BX	      :
;			ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		      :
;									      :
;									      :
; Entry:		AX	   = First element to highlight 	      :
;			BX	   = Last element to highlight		      :
;									      :
;			COM_HCBIDL = First element help ID		      :
;			COM_HCBIDH = Last element help ID		      :
;			COM_HCBID  = Set to desired help ID for all selections:
;				     and set COM_HCBIDL and COM_HCBIDH to 0.  :
;									      :
;			COM_SCROPT = Set scroll option for multiple	      :
;				     selections.  COM_HCBID and COM_CURPUPF   :
;				     must be initialized before entry.	      :
;									      :
; Exit: 		COM_MOK   0= Mouse input			      :
;				  1= Keyboard input			      :
;			COM_KEY    = Keystroke (keyboard or mouse value)      :
;			COM_ROW    = Row of mouse pointer (text coordinates)  :
;			COM_COL    = Column of mouse pointer (text coord)     :
;			COM_POSITION = Line number of scroll bar element      :
;			COM_CURRF  = Current mouse field ID		      :
;			COM_DELTA  = Scroll bar delta from current top	      :
;				     element displayed in panel 	      :
;			COM_HCBID  = Current help equate		      :
;									      :
;									      :
; Notes:		None.						      :
;									      :
; Entry point:		PROCESS_SCROLL					      :
;									      :
; Internal references:	PCTRACK_CALL					      :
;			PCINPUT_CALL					      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PROCESS_SCROLL PROC FAR
;
	       PUSH AX			     ;save registers
	       PUSH BX
	       PUSH CX
	       PUSH DX
	       PUSH DI
	       PUSH ES
	       PUSH SI
	       PUSH DS
;
; initialize first highlighted field
;
	       MOV  COM_HLPTEMP,0	     ;set to unique scroll help
;
	       CMP  COM_HCBIDL,0	     ;check if unique scroll item
	       JNE  SI04		     ; help option active
;
	       CMP  COM_HCBIDH,0
	       JNE  SI04
;
	       PUSH COM_HCBID		     ;set help ID
	       POP  COM_HLPTEMP
;
SI04:	       MOV  COM_FLDT,2		     ;scroll field type
;
	       MOV  CX,BX		     ;calulate number of entries
	       SUB  CX,AX		     ; in list
	       XOR  CH,CH		     ;clear to zero
	       ADD  CL,'1'                   ;adjust for string value
	       MOV  COM_CNT,CX		     ;save value
;
	       CMP  COM_SCROPT,1	     ;when using this option make
	       JNE  SI05		     ; sure starting help ID initializd
					     ; to COM_HCBID and the current
					     ; field to highlight COM_CURPUPF
;
	       MOV  DX,AX		     ;get first field
	       MOV  AX,COM_CURPUPF	     ;make new mouse field the current
	       MOV  COM_LASTF,AX	     ; field
	       JMP  SI07
;
SI05:	       MOV  CX,COM_HCBIDL	     ;initialize starting help ID
	       MOV  COM_HCBID,CX
;
	       MOV  COM_CURPUPF,AX	     ;make new mouse field the current
	       MOV  COM_LASTF,AX	     ; field
	       MOV  DX,AX		     ;get first field
;
SI07:	       MOV  CX,BX		     ;get last field
	       CALL FAR PTR LOC_MOUSEF	     ;get actual mouse field number
	       CALL FAR PTR MOUSE_OFF
	       CALL FAR PTR MOUSE_HIGH	     ;highlight mouse field
	       CALL FAR PTR MOUSE_ON
;
; Poll for keyboard or mouse input
;
SI10:	       CMP  COM_HLPTEMP,0	     ;check if single help ID selection
	       JE   SI11		     ; active
;
	       MOV  AX,COM_HLPTEMP	     ;set single help ID for all scroll
	       MOV  COM_HCBID,AX	     ; selections
;
SI11:	       MOV  AX,0		     ;turn monocasing off
	       CALL FAR PTR PROCESS_KEY      ;get keystroke

	       MOV  BX,COM_KEY		     ;get keystroke
;
; Exit if mouse action
;
SI12:	       CMP  COM_MOK,1		     ;check if keyboard input
	       JE   SI15
;
	       CMP  BX,ES:[DI]+KY_ENTER      ;check if Enter pressed
	       JNE  SI13
;
	       CMP  COM_SCROPT,1	     ;is this the multiple select opt?
	       JE   SI13		     ;yes, jump out of procedure
;
	       MOV  AX,COM_CURPUPF	     ;get current highlighted field
	       CALL FAR PTR GET_MOUSEF	     ;get mouse structure
;
	       MOV  AX,ES:[DI]+MS_KEYS	     ;keystroke assigned to field
	       MOV  COM_KEY,AX
	       MOV  COM_MOK,0		     ;set for keystroke input
;
SI13:	       JMP  SIEXIT		     ;mouse action exit
;
; Process down arrow key
;
SI15:	       CMP  BX,ES:[DI]+KY_DARROW     ;check if up arrow pressed
	       JNE  SI30
;
	       CMP  COM_CURPUPF,CX	     ;check if below last field
	       JAE  SI20
;
	       INC  COM_HCBID		     ;point to next help equate
	       INC  COM_CURPUPF 	     ;no, point to next field
	       JMP  SI45		     ;now change highlight
;
SI20:	       PUSH COM_HCBIDL		     ;initialize help to first field
	       POP  COM_HCBID
	       MOV  COM_CURPUPF,DX	     ;yes, point to first field
	       JMP  SI45		     ;now change highlight
;
; process up arrow key
;
SI30:	       CMP  BX,ES:[DI]+KY_UARROW     ;check if up arrow pressed
	       JNE  SI50
;
	       CMP  COM_CURPUPF,DX	     ;check if above first field
	       JBE  SI40
;
	       DEC  COM_HCBID		     ;point to next help equate
	       DEC  COM_CURPUPF 	     ;no, point to previous field
	       JMP  SI45
;
SI40:	       PUSH COM_HCBIDH		     ;initialize help to last field
	       POP  COM_HCBID
	       MOV  COM_CURPUPF,CX	     ;yes, point to last field
;
; Remove last field highlight and display new highlight
;
SI45:	       CALL FAR PTR MOUSE_OFF	     ;turn mouse pointer off
;
	       MOV  AX,COM_LASTF	     ;unhighlight last mouse field
	       CALL FAR PTR LOC_MOUSEF	     ;get actual field number
	       CALL FAR PTR MOUSE_UNHIGH
;
	       MOV  AX,COM_CURPUPF	     ;highlight current mouse field
	       CALL FAR PTR LOC_MOUSEF	     ;get actual field number
	       CALL FAR PTR MOUSE_HIGH
;
	       CALL FAR PTR MOUSE_ON	     ;turn mouse pointer on
;
	       MOV  AX,COM_CURPUPF	     ;set last field as current
	       MOV  COM_LASTF,AX
	       JMP  SI10		     ;poll for next keystroke
;
; Process Enter key
;
SI50:	       CMP  BX,ES:[DI]+KY_ENTER      ;check if Enter pressed
	       JNE  SI60
;
	       CMP  COM_SCROPT,1	     ;is this the multiple select opt?
	       JE   SIEXIT		     ;yes, jump out of procedure
;
	       MOV  AX,COM_CURPUPF	     ;get current highlighted field
	       CALL FAR PTR GET_MOUSEF	     ;get mouse structure
;
	       MOV  AX,ES:[DI]+MS_KEYS	     ;keystroke assigned to field
	       MOV  COM_KEY,AX
	       MOV  COM_MOK,0		     ;set for keystroke input
	       JMP  SIEXIT		     ;exit process_scroll
;
; if escape key, exit
;
SI60:	       CMP  BX,ES:[DI]+KY_CANCEL     ;check if Escape pressed
	       JNE  SI70
;
	       JMP  SIEXIT
;
; if not multiple select, exit on number
;
SI70:	       CMP  COM_SCROPT,1	     ;is this the multiple select opt?
	       JE   SI90		     ;yes, jump to check space bar
;
	       CMP  BX,'1'                   ;compare to a one
	       JB   SI80
;
	       CMP  BX,COM_CNT		     ;compare to number of entries
	       JBE  SIEXIT
;
SI80:	       JMP  SI100		     ;poll for next keystroke
;
; multiple select, exit on spacebar
;
SI90:	       CMP  BX,ES:[DI]+KY_SELECT     ;was this the space bar?
	       JE   SIEXIT		     ;yes, exit routine
;
SI100:	       CALL FAR PTR PCMBEEP_CALL     ;beep on unknown keystroke  P*3940
	       JMP  SI10		     ;poll for next keystroke
;
; Unhighlight field before exit
;
SIEXIT:        CALL FAR PTR MOUSE_OFF	     ;turn mouse pointer off
	       MOV  AX,COM_CURPUPF	     ;get last field
;
	       CALL FAR PTR LOC_MOUSEF
	       CALL FAR PTR MOUSE_UNHIGH     ;unhighlight field before exit
	       CALL FAR PTR MOUSE_ON	     ;turn mouse point on
;
	       MOV  COM_FLDT,0		     ;no field type
;
	       POP  DS			     ;restore registers
	       POP  SI
	       POP  ES
	       POP  DI
	       POP  DX
	       POP  CX
	       POP  BX
	       POP  AX
;
	       RET
PROCESS_SCROLL ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PROCESS_INPUT					      :
;									      :
; Description:		Display input field contents relative to location of  :
;			associated panel and optionally process keystroke     :
;			before returning.				      :
;									      :
; Entry:		COM_ICBID  = Input field ID to process. 	      :
;			COM_HCBID  = Help ID assigned to input field.	      :
;			COM_INOPT 0= Display data entry 		      :
;				  1= Do not display data entry (Password)     :
;									      :
; Exit: 		ES:DI	   = Address of input field data	      :
;			CX	   = Length of data			      :
;			AX	   = Return key 			      :
;									      :
;			COM_MOK   0= Mouse input			      :
;				  1= Keyboard input			      :
;			COM_KEY    = Keystroke (keyboard or mouse value)      :
;			COM_ROW    = Row of mouse pointer (text coordinates)  :
;			COM_COL    = Column of mouse pointer (text coord)     :
;			COM_CURRF  = Current mouse field ID		      :
;			COM_DELTA  = Scroll bar delta from current top	      :
;				     element displayed in panel 	      :
;									      :
;									      :
; Entry point:		PROCESS_INPUT					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	GET_ICB      = Get specified input control block.     :
;									      :
;			PCINPUT_CALL = Call to external CAS routine.	      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PROCESS_INPUT  PROC FAR
;
	       PUSH BX
	       PUSH DX
;
; initialize
;
	       MOV  COM_FLDT,1		     ;input field
;
	       MOV  IN_CURNOR,0607H	     ;non-mono cursor size
;
	       CMP  GV_VIDMODE,7	     ;check if mono mode
	       JNE  PH03
;
	       MOV  IN_CURNOR,0C0DH	     ;mono cursor size
;
; remove mouse pointer
;
PH03:	       CALL FAR PTR MOUSE_OFF	     ;turn mouse pointer off
;
; locate specified input control block
;
	       MOV  AX,COM_ICBID	     ;get PCINPUT field
	       MOV  IN_ICBID,AX
	       CALL FAR PTR GET_ICB	     ;ES:DI points to ICB
;
; initialize, display and exit field
;
	       AND  ES:[DI]+ICB_OPT1,NOT ICB_PSW
					     ;deactivate password option
	       CMP  COM_INOPT,0 	     ;check if password option is on
	       JE   PH04
;
	       OR   ES:[DI]+ICB_OPT1,ICB_PSW ;activate password option
;
PH04:	       AND  ES:[DI]+ICB_STATUS,NOT ICB_DONE
	       AND  ES:[DI]+ICB_STATUS,NOT ICB_SINS
;
	       MOV  ES:[DI]+ICB_CURCHAR,1
;
PH05:	       OR   ES:[DI]+ICB_OPT4,ICB_INIT
	       AND  ES:[DI]+ICB_OPT3,NOT ICB_KEY
	       CALL FAR PTR PCINPUT_CALL     ;initialize field
	       AND  ES:[DI]+ICB_OPT4,NOT ICB_INIT
	       OR   ES:[DI]+ICB_OPT3,ICB_KEY
					     ;remove initialization option
;
; Process field
;
PH06:	       XOR  AX,AX
	       OR   ES:[DI]+ICB_OPT3,ICB_KEY
	       AND  ES:[DI]+ICB_OPT4,NOT ICB_INIT
	       TEST ES:[DI]+ICB_OPT2,ICB_UPC ;check if monocasing option active
	       JE   PH07
;
	       MOV  AX,0000000000000001B     ;set monocasing option on
;
PH07:	       TEST IN_OPT,IN_UTRAN	     ;check if translation option actv
	       JE   PH10
;
	       MOV  AX,0000000000000010B     ;set translation option on
;
; display mouse pointer
;
PH10:	       CALL FAR PTR MOUSE_ON	     ;turn mouse pointer on
;
; Poll keyboard and mouse
;
	       CALL FAR PTR PROCESS_KEY
	       MOV  AX,COM_KEY		     ;get keystroke
;
	       CMP  COM_MOK, 0		     ;mouse field?
	       JNE  PH12		     ;no, continue
	       CMP  COM_RSTFLD, 0	     ;restrict mouse field?
	       JE   PH12		     ;no, continue
	       CMP  AH, 0		     ;extended char?
	       JE   PH12		     ;no, continue
	       CMP  AL,0		     ;unrestricted extended char?
	       JE   PH12		     ;yes, continue
	       CMP  AL, COM_RSTFLD	     ;mouse field in current set?
	       JNE  PH11		     ;no, return new field index
	       XOR  AL, AL		     ;clear ID byte
comment        |
	       cmp  ah, rtarrow 	     ;
	       jne  ph1005		     ;
	       mov  es,in_icbseg	     ;
	       mov  di,in_icboff	     ;
	       inc  es:[di]+icb_hrstart      ;
	       INC  ES:[DI]+ICB_CURCHAR      ;
	       AND  ES:[DI]+ICB_OPT3,NOT ICB_KEY
	       OR   ES:[DI]+ICB_OPT4,ICB_INIT
	       jmp  ph12		     ;
ph1005:        cmp  ah, lfarrow 	     ;
	       jne  ph12		     ;
	       mov  es,in_icbseg	     ;
	       mov  di,in_icboff	     ;
	       dec  es:[di]+icb_hrstart      ;
	       DEC  ES:[DI]+ICB_CURCHAR      ;
	       AND  ES:[DI]+ICB_OPT3,NOT ICB_KEY
	       OR   ES:[DI]+ICB_OPT4,ICB_INIT
	       |
	       JMP  PH12		     ;continue
PH11:	       XOR  AH, AH		     ;clear keystroke byte
;
PH12:	       MOV  COM_KEY, AX 	     ;update keystroke
	       CALL FAR PTR MOUSE_OFF	     ;
;
; Pass keystroke to input field for processing
;
PH50:	       MOV  ES,IN_ICBSEG	     ;point to current ICB
	       MOV  DI,IN_ICBOFF
	       MOV  ES:[DI]+ICB_KS,AX	     ;set keystroke to ICB
;
	       CALL FAR PTR PCINPUT_CALL     ;process input field
;
	       MOV  ES,IN_ICBSEG	     ;point to current ICB
	       MOV  DI,IN_ICBOFF
;
	       MOV  AX,ES:[DI]+ICB_KS	     ;return keystroke
;
	       TEST ES:[DI]+ICB_STATUS,ICB_DONE
	       jne  ph51
	       jmp  PH06		     ;check for exit condition
;
ph51:	       CALL FAR PTR MOUSE_ON	     ;turn mouse pointer on
	       CALL FAR PTR CURSOROFF	     ;turn hardware cursor off
	       MOV  COM_FLDT,0		     ;no field type
	       MOV  COM_INOPT,0 	     ;no password option
;
	       MOV  DX,ES:[DI]+ICB_OPT4      ;get option word 4
;
	       PUSH ES:[DI]+ICB_ENDBYTE      ;return length of data
	       PUSH ES:[DI]+ICB_FIELDOFF     ;return offset of data
	       PUSH ES:[DI]+ICB_FIELDSEG     ;return segment of data
;
	       POP  ES
	       POP  DI
	       POP  CX
;
	       TEST DX,ICB_TRUN 	     ;field is DOS pathname?
	       JZ   PH60		     ;no, continue
;
	       MOV  SI,DI		     ;save string offset
	       ADD  DI,CX		     ;get end of string offset
	       MOV  BYTE PTR ES:[DI],0	     ;null-terminate pathname
	       MOV  DI,SI		     ;restore string offset
;
	       CALL TRUNC_NAME		     ;truncate DOS names & extensions
	       PUSH ES							;MJK005
	       PUSH DI							;MJK005
	       MOV  ES,IN_ICBSEG	     ;point to current ICB	;MJK005
	       MOV  DI,IN_ICBOFF					;MJK005
	       MOV  ES:[DI]+ICB_ENDBYTE,CX   ;return length of data	;MJK005
	       POP  DI							;MJK005
	       POP  ES							;MJK005
;
PH60:	       POP  DX
	       POP  BX
;
	       RET
PROCESS_INPUT  ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PROCESS_KEY					      :
;									      :
; Description:		Poll keyboard then mouse return only if action	      :
;			occurs. 					      :
;									      :
; Entry:		AX	 0000000000000001 = Monocasing		      :
;				 0000000000000010 = Translation table	      :
;									      :
;			COM_HLPOPT = set to 10 to deactivate help	      :
;			COM_HCBID  = Help ID assigned to input field.	      :
;									      :
; Exit: 		COM_MOK   0= Mouse input			      :
;				  1= Keyboard input			      :
;			COM_KEY    = Keystroke (keyboard or mouse value)      :
;			COM_ROW    = Row of mouse pointer (text coordinates)  :
;			COM_COL    = Column of mouse pointer (text coord)     :
;			COM_CURRF  = Current mouse field ID		      :
;			COM_DELTA  = Scroll bar delta from current top	      :
;				     element displayed in panel 	      :
;									      :
;			COM_FLDT  0= no field	   used to determine if       :
;				  1= input field   cursor should be displayed :
;				  2= scroll field			      :
;									      :
; Entry point:		PROCESS_KEY					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	PCTRACK_CALL = Call to external CAS routine.	      :
;			PCINPUT_CALL = Call to external CAS routine.	      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PROCESS_KEY    PROC FAR
;
	       PUSH AX			     ;save registers
	       PUSH BX
	       PUSH CX
	       PUSH DX
;
	       MOV  INC_KS,0		     ;initialize to no keystroke
	       MOV  INC_OPT,0
;
	       TEST AX,0000000000000001B     ;check if monocasing
	       JE   PK05
;
	       OR   INC_OPT,INC_AMONO	     ;initialize to monocasing
	       CMP  IN_MONOSEG,0	     ;monocasing table gotten?	P5197
	       JNE  PK02		     ;yes, don't get again      P5197
	       CALL GET_MONO_DOS	     ;get DOS monocasing table	P5197
PK02:					     ;				P5197
	       MOV  BX,IN_MONOOFF	     ;get from PCINPUT control block
	       MOV  INC_MONOOFF,BX	     ;set in PCINCHA control block
	       MOV  BX,IN_MONOSEG	     ;get from PCINPUT control block
	       MOV  INC_MONOSEG,BX	     ;set in PCINCHA control block
;
PK05:	       TEST AX,0000000000000010B     ;check if translation table
	       JE   PK10
;
	       OR   INC_OPT,INC_UTRAN	     ;initialize for translation table
;
; Poll keyboard for input
;
PK10:	       MOV  KS_CHAR,0		     ;clear out 		P*4663
	       TEST COM_PROCFLAG,COM_KPLOCK  ;keyboard locked?		P*4457
	       JZ   PK17		     ;no, get keystroke 	P*4457
	       IN   AL,64H		     ;get keyboard lock bit	P*4457
	       TEST AL,10H		     ;is keyboard locked?	P*4457
	       JNZ  PK15		     ;OK, keyboard not locked	P*4457
	       JMP  PK40		     ;check time/date		P*4457
PK15:
	       CALL INIT_MOUSE		     ;initialize mouse		P*4457
	       CALL MOUSE_ON		     ;turn on mouse		P*4457
PK17:					     ;				P*4457


	       MOV  AH,1		     ;keystroke status		MJK013
	       TEST COM_PROCFLAG,COM_EXTKEYB ;extended keyboard?	P*4732
	       JZ   PK17_05		     ;no, get normal keystroke	P*4732
	       MOV  AH,11H		     ;get extended keystroke	P*4732
PK17_05:				     ;				P*4732
	       INT  16H 		     ;is there any keystrokes?	MJK013
	       JZ   PK17_10		     ;don't save keystroke      P*4663
	       MOV  KS_CHAR,AX		     ;save the keystroke	MJK013
PK17_10:				     ;				P*4663
;
	       CALL PCINCHA_CALL	     ;call CAS routine
;
	       CMP  INC_KS,0		     ;check if keystroke returned
	       JE   PK20		     ;yes, pass to input field
;
	       CMP  INC_KS, 0003H	     ;ctrl/c or ctrl/break?	P*4663
	       JNE  PK18		     ;no, continue		P*4663
	       MOV  AX, KS_CHAR 	     ;get status keystroke	P*4663
	       CMP  AL, 03H		     ;same ASCII character?	P*4663
	       JE   PK19		     ;yes, must be ctrl/c	P*4663
	       MOV  INC_KS, 0		     ;ignore ctrl/break 	P*4663
	       JMP  PK40		     ;continue			P*4663
PK18:					     ;				p*4663

	       CMP  INC_KS, 6800H	     ;keystroke is alt-f1?

	       JNE  PK19		     ;no, continue
	       MOV  INC_KS, 8500H	     ;translate to f11
;
PK19:	       CALL CHK_OVERRUN 	     ;check for overrun keystrokes
;
	       MOV  COM_MOK,1		     ;set to indicate keyboard
	       XOR  AX,AX		     ;clear to zero
	       MOV  COM_ROW,AX		     ; pointer row
	       MOV  COM_COL,AX		     ; pointer column
	       MOV  COM_DELTA,AX	     ; scroll bar delta
	       MOV  AX,INC_KS		     ;set keystroke from keyboard
	       MOV  COM_KEY,AX
;
	       MOV  AX,COM_CURRF	     ;sav field ID before help process
	       MOV  COM_HELPF,AX
;
	       JMP  PK30
;
; Poll mouse for action
;
PK20:	       TEST COM_STATE,COM_MOUS	     ;check if mouse configured
	       JNE  PK22		     ; do call if no
	       JMP  PK40		     ; skip call if yes
;
PK22:	       LEA  DI,GEN_DATA 	     ;check mouse for button press
	       MOV  [DI]+M_FUNC,M_GET
	       CALL FAR PTR PCTRACK_CALL
;
	       XOR  CH,CH		     ;clear to zero
	       XOR  DH,DH		     ;clear to zero
	       MOV  CL,[DI]+M_GETBUT	     ;get button pressed
	       MOV  DL,[DI]+M_GETFIELD	     ;get field of current pointer
;
	       CMP CL, 2		     ;process keystroke
	       JNE PK24X
;
	       TEST COM_STATE2,COM_ENHA
	       JZ PK24X
;
	       MOV COM_BUT2,1
	       MOV CL, 1
	       JMP PK24
;
PK24X:	       MOV COM_BUT2,0
	       CMP  CL,1		     ;mouse configuration
	       JE   PK24		     ; 0= no button pressed
;
	       CMP  CL,4		     ; 1= button 1 pressed
	       JE   PK24		     ; 2= button 2 pressed
					     ; 3= button 3 pressed
					     ; 4= double click button 1
	       JMP  PK40
;
PK24:	       OR   DL,DL		     ;check if pointer in active field
	       JNZ  PK26		     ; when button pressed, if not
	       JMP  PK40		     ; poll again
;
PK26:	       CMP  GE_MODEL,MODEL_AT	     ;check if AT
	       JNE  PK29
;
	       CMP  GE_SUBMODEL,SUBMD_AT     ;make sure AT
	       JE   PK28
;
	       CMP  GE_SUBMODEL,SUBMD_AS     ;make sure AT/skyrocket
	       JNE  PK29
;
PK28:	       CALL KEYLOCK		     ;check if keyboard on AT is
	       JNZ  PK29
;
	       JMP  PK40		     ; locked, poll again
;
PK29:	       MOV  COM_MOK,0		     ;set to indicate mouse
	       MOV  AX,COM_CURRF	     ;sav field ID before help process
	       MOV  COM_HELPF,AX
	       MOV  COM_CURRF,DX	     ;set current field number
	       MOV  AX,[DI]+M_GETROW	     ;get mouse pointer row where
	       MOV  COM_ROW,AX		     ; button was pressed
	       MOV  AX,[DI]+M_GETCOL	     ;get mouse pointer column where
	       MOV  COM_COL,AX		     ; button was pressed
	       MOV  AX,[DI]+M_GETFKEY	     ;get keystroke assigned to field
	       MOV  COM_KEY,AX
;
	       MOV  AX,[DI]+M_GETDELTA	     ;scroll delta (if in sb field)
	       MOV  COM_DELTA,AX
	       XOR  CX,CX
	       MOV  AX,[DI]+M_GETSPOS	     ;text row/col position in bar
	       MOV  COM_POSITION,AX
;
; Check for help option before exit
;
PK30:	       CMP  COM_HLPOPT,10	     ;check if help deactivated
	       JE   PKEXIT		     ;exit
;
	       MOV  AX,STR_TOTAL	     ;get keystroke structure
	       CALL FAR PTR GET_STRING	     ;structure at ES:DI
;
	       MOV  AX,COM_KEY		     ;get keystroke
	       CMP  AX,ES:[DI]+KY_CHELP
	       JNE  PKEXIT
;
	       CALL FAR PTR CURSOROFF	     ;turn hardware cursor off
	       PUSH COM_HELPF		     ;save field ID before help process
	       CALL MANAGE_HELP 	     ;process all types of help
	       POP  COM_CURRF		     ;reset original field ID before hl
;
	       CMP  COM_FLDT,1		     ;redisplay cursor if input field
	       JNE  PK40
;
	       CALL FAR PTR CURSORON	     ;turn hardware cursor on
;
; Check if date and time should be updated.
;
PK40:	       CALL DISP_DATETIME	     ;update date/time
	       JMP  PK10
;
; Exit
;
PKEXIT:        PUSH ES
	       PUSH DI
	       MOV  AX, 40H
	       MOV  ES, AX
	       MOV  BX, 17H
	       MOV  AL, ES:[BX]
	       XOR  AH, AH
	       MOV  COM_SHIFT, AX
	       POP  DI
	       POP  ES
;
	       POP  DX			     ;exit
	       POP  CX
	       POP  BX
	       POP  AX
;
	       RET
PROCESS_KEY    ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									P5197 :
;  GET_MONO_DOS 							      :
;	    Get segment and offset of the DOS monocasing table and return it  :
;									      :
;  Entry:  None 							      :
;									      :
;  Exit:   None 							      :
;									P5197 :
;-----------------------------------------------------------------------------+
GET_MONO_DOS   PROC NEAR
;
	       PUSH ES			     ;				P5197
	       PUSH DI			     ;				P5197
	       PUSH AX			     ;				P5197
;
	       MOV  AH,65H		     ;extended country info	P5197
	       MOV  AL,04H		     ;get uppercase table ptrs	P5197
	       MOV  BX,-1		     ;default code page 	P5197
	       MOV  DX,-1		     ;default country id	P5197
	       MOV  CX,05H		     ;# bytes returned		P5197
	       PUSH DS
	       POP  ES			     ;ES:DI ptrs to return buf	P5197
	       MOV  DI,OFFSET TEMP_WKA	     ;use as temp buffer	P5197
	       INT  21H
	       JC   GET_MONO_RET
;
	       INC  DI			     ;skip info id		P5197
;
	       MOV  AX,WORD PTR [DI]	     ;get DOS mono table offset P5197
	       MOV  IN_MONOOFF,AX	     ;save it			P5197
	       ADD  DI,2
	       MOV  AX,WORD PTR [DI]	     ;get DOS mono table seg	P5197
	       MOV  IN_MONOSEG,AX	     ;save it			P5197
;
GET_MONO_RET:
	       POP  AX			     ;				P5197
	       POP  DI			     ;restore registers 	P5197
	       POP  ES			     ;				P5197
;
	       RET			     ;				P5197
GET_MONO_DOS   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		CHK_OVERRUN					      :
;									      :
; Description:		Check for multiple entries of cursor keys to	      :
;			eliminate overrun in typeamatic mode.		      :
;									      :
; Entry:		INC_KS	   = Key stroke 			      :
;									      :
; Exit: 		INC_KS	   = Returned keystroke 		      :
;									      :
; Entry point:		CHK_OVERRUN					      :
;									      :
; Notes:		Duplicate cursor keystrokes are removed.	      :
;									      :
; Internal references:	PCINCHA_CALL = Call to external CAS routine.	      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
CHK_OVERRUN    PROC NEAR
;
	       PUSH CX
	       PUSH DI
	       PUSH ES
;
	       MOV  CX,KS_TABLE_LEN	     ;len of cursor keystroke table
	       ROR  CX,1		     ;set number of entries
	       MOV  AX,DS		     ;get segment of table
	       MOV  ES,AX		     ;set segment of table
	       MOV  DI,OFFSET KS_TABLE	     ;offset of table
	       MOV  AX,INC_KS		     ;current keystroke
	       CLD
	       REPNZ SCASW		     ;scan table for keystroke match
	       JNZ  CHK_OVRET		     ;no match found
;
CHK_OV10:      MOV  AH,1		     ;keystroke status
	       TEST COM_PROCFLAG,COM_EXTKEYB ;extended keyboard?	P*4732
	       JZ   CHK_OV20		     ;no, get normal keystroke	P*4732
	       MOV  AH,11H		     ;get extended keystroke	P*4732
CHK_OV20:				     ;				P*4732
	       INT  16H 		     ;check for next keystroke
	       JZ   CHK_OVRET		     ;no, keystroke available
;
	       CMP  AX,KS_CHAR		     ;is it the same as before	MJK013
	       JNE  CHK_OVRET		     ;no, return
;
	       MOV  AH,0		     ;keystroke read
	       TEST COM_PROCFLAG,COM_EXTKEYB ;extended keyboard?	P*4732
	       JZ   CHK_OV30		     ;no, get normal keystroke	P*4732
	       MOV  AH,10H		     ;get extended keystroke	P*4732
CHK_OV30:				     ;				P*4732
	       INT  16H 		     ;remove it
	       JMP  CHK_OV10		     ;check next keystroke
;
CHK_OVRET:     POP  ES
	       POP  DI
	       POP  CX
;
	       RET
CHK_OVERRUN    ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		DISP_DATETIME					      :
;									      :
; Description:		display the date and time on the display.	      :
;									      :
; Entry:		COM_STATE2:					      :
;			COM_DATE   = O - no date displayed		      :
;				     1 - display date and time		      :
;									      :
; Exit: 		Display updated 				      :
;									      :
; Entry point:		DISP_DATETIME					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	UPDATE_DISPLAY					      :
;			MOUSE_OFF					      :
;			MOUSE_ON					      :
;									      :
; External references:	PCDATES_CALL = Call to external CAS routine.	      :
;			PCTIMES_CALL = Call to external CAS routine.	      :
;									      :
;-----------------------------------------------------------------------------+
;
DISP_DATETIME  PROC NEAR
;
	       PUSH AX			     ;save registers
	       PUSH BX
	       PUSH CX
	       PUSH DX
	       PUSH SI
	       PUSH DI
	       PUSH ES
;
	       TEST COM_STATE2,COM_DATE      ;is the date option active?
	       JNZ  DT_02		     ;yes, continue
	       JMP  DT_RET		     ;return
;
; Set up to get the date and time.
;
DT_02:	       MOV  DI,OFFSET TIME_WKA	     ;time workarea
	       MOV  BX,DS:[DI+4]	     ;save currect seconds
;
	       CALL PCDATES_CALL	     ;get date
;
	       CALL PCTIMES_CALL	     ;get time
;
	       TEST COM_PROCFLAG,COM_NODATE  ;should date not be displayed?
	       JNZ  DT_RET		     ;yes, return
;
	       TEST COM_PROCFLAG,COM_PSCEXEC ;has PSC ended execution?
	       JZ   DT_05		     ;no, continue
;
	       AND  COM_PROCFLAG,NOT COM_PSCEXEC ;reset PSC ended execution
	       JMP  DT_20		     ;display time/date

DT_05:	       MOV  AX,COM_BASESCR	     ;get base screen
	       CMP  AX,COM_BASE_WKA	     ;has it changed?
	       JE   DT_10		     ;no, see if time has changed
;
	       MOV  COM_BASE_WKA,AX	     ;save new base screen
	       JMP  DT_20		     ;continue
;
DT_10:	       CMP  BX,DS:[DI+4]	     ;has the time minutes changed?
	       JE   DT_RET		     ;no, don't update it
;
DT_20:	       MOV  SI,PAN_ATITLE	     ;get panel id for moveg
	       MOV  AX,1		     ;row to display
	       MOV  BX,3		     ;column to display
	       MOV  CX,LENGTH DATE_WKA	     ;len of date
	       MOV  DX,OFFSET DATE_WKA
	       PUSH DS
	       POP  ES
;
	       CALL FAR PTR MOUSE_OFF	     ;turn mouse off
;
	       PUSH AX			     ;
	       MOV  AX, PAN_ATITLE	     ;set panel id
	       CALL FAR PTR GET_ATTR	     ;get color attr
	       AND  AH, 0F0H		     ;mask off foreground
	       CMP  AH, 0F0H		     ;background is white?
	       POP  AX			     ;
	       JNE  DT_28		     ;no, continue
	       MOV  MG_SOURCE_F,G_DRAWTUBOTM ;underline 		P*4816
DT_28:

;		CMP  GV_VIDMODE,11H	      ;mode 11? 		 P*4816
;		JNE  DT_30		      ;no, don't underline       P*4816
;		MOV  MG_SOURCE_F,G_DRAWTUBOTM ;underline		 P*4816


DT_30:					     ;				P*4816
	       CALL UPDATE_DISPLAY	     ;display date
;
	       MOV  BX,69		     ;column to display
	       MOV  CX,LENGTH TIME_WKA	     ;len of time
	       MOV  DX,OFFSET TIME_WKA
;
	       PUSH AX			     ;
	       MOV  AX, PAN_ATITLE	     ;set panel id
	       CALL FAR PTR GET_ATTR	     ;get color attr
	       AND  AH, 0F0H		     ;mask off foreground
	       CMP  AH, 0F0H		     ;background is white?
	       POP  AX			     ;
	       JNE  DT_38		     ;no, continue
	       MOV  MG_SOURCE_F,G_DRAWTUBOTM ;underline 		P*4816
DT_38:


;	       CMP  GV_VIDMODE,11H	     ;mode 11?			P*4816
;	       JNE  DT_40		     ;no, don't underline       P*4816
;	       MOV  MG_SOURCE_F,G_DRAWTUBOTM ;underline 		P*4816
DT_40:					     ;				P*4816
	       CALL UPDATE_DISPLAY	     ;display time
;
	       CALL FAR PTR MOUSE_ON	     ;turn mouse on
;
DT_RET:        POP  ES			     ;restore registers
	       POP  DI
	       POP  SI
	       POP  DX
	       POP  CX
	       POP  BX
	       POP  AX
;
	       RET
DISP_DATETIME  ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		KEYLOCK 					      :
;									      :
; Description:		Determine if AT keyboard lock is on.		      :
;									      :
; Entry:		None.						      :
;									      :
; Exit: 		ZF = 1	: keyboard is locked			      :
;			ZF = 0	: keyboard is unlocked			      :
;									      :
; Entry point:		KEYLOCK 					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
KEYLOCK        PROC NEAR
;
	       PUSH BX
	       PUSH CX
;
	       CLI			     ;disable ints while checking kybd
	       MOV  AL,READ_KBD_INPT	     ;get kybd read input command
	       OUT  STATUS_PORT,AL	     ;issue the command
	       SUB  CX,CX		     ;cls controller count cmd issue
;
KEYLOCK10:     IN   AL,STATUS_PORT
	       TEST AL,INPT_BUF_FULL
	       LOOPNZ  KEYLOCK10	     ;wait for command to be accepted
	       JNZ  KEYLOCK50		     ;exit if command not accepted
;
	       SUB  CX,CX
	       MOV  BL,6
;
KEYLOCK20:     IN   AL,STATUS_PORT
	       TEST AL,OUTPT_BUF_FULL
	       JNZ  KEYLOCK30		     ;branch if OBF
;
	       LOOP KEYLOCK20		     ;loop until response or timeout
	       DEC  BL			     ;timeout loop attempted six times
	       JNZ  KEYLOCK20
;
	       INC  BL			     ;set ZF = 0 if no response
	       JMP  KEYLOCK50
;
KEYLOCK30:     IN   AL,INPUT_PORT	     ;read keyboard input port
	       TEST AL,KYBD_INH 	     ;test to see if kybd lock is on
;
KEYLOCK50:
;
KEYLOCK60:     STI			     ;enable ints
	       POP  CX			     ;restore regs
	       POP  BX
;
	       RET			     ;Exit
KEYLOCK        ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		COMMAND_LINE					      :
;									      :
; Description:		Command line dialog.				      :
;									      :
; Entry:		COM_OLDCBKOFF  = offset of original crtl+break	      :
;			COM_OLDCBKSEG  = segment of original crtl+break       :
;			COM_CMDBUF     = required to invoke COMMAND.COM       :
;			COM_CMDINPBUF  = command line input buffer	      :
;			COM_CMDINPLEN  = length of command line input buf     :
;			COM_CMDBUFLEN  = length including '/C'                :
;			COM_CMDDRIVE   = current drive and path to display    :
;			COM_CMDPATH	 for command line input prompt	      :
;			KY_COMDLINE    = command line	  Shift + F9	      :
;			KY_LASTCOMD    = last command	  up arrow	      :
;			KY_NEXTCOMD    = next command	  dn arrow	      :
; Exit: 								      :
;									      :
; Entry point:		COMMAND_LINE					      :
;									      :
; Notes:		Changed procedure to use a COMMAND.COM PSC execution. :
;									      :
; Internal references:	PCTRACK_CALL					      :
;									      :
; External references:	INT 21H  AH=40H   Write string to standard output.    :
;			INT 21H  AH=25H   Set interrupt vector address.       :
;			INT 21H  AH=35H   Get interrupt vector address.       :
;			INT 21H  AH=49H   Deallocate memory.		      :
;			INT 21H  AH=47H   Read current directory.	      :
;			INT 21H  AH=19H   Read current disk.		      :
;			INT 21H  AH=06H   Write char to standard output.      :
;			INT 21H  AH=4BH   EXEC command line.		      :
;									      :
;-----------------------------------------------------------------------------+
;
COMMAND_LINE   PROC FAR

	       TEST COM_STATE,COM_FLCL	     ;check if command line active
	       JNE  MC10
;
	       CALL FAR PTR OPT_INACTIVE     ;display error panel for inactive *PCR
	       JMP  MCEXIT		     ;exit
;
; save registers
;
MC10:	       CALL FAR PTR REMOVE_OLDPD     ;remove last pull down panel
	       MOV  COM_CURPD,0
;
	       PUSH AX
	       PUSH BX
	       PUSH CX
	       PUSH DX
	       PUSH BP
	       PUSH SI
	       PUSH DI
;
; disable mouse tracker
;
	       CALL FAR PTR MOUSE_OFF	     ;turn mouse pointer off
	       CALL FAR PTR DEL_MOUSEF	     ;delete all mouse fields
	       CALL FAR PTR MOUSE_DIS	     ;disable mouse support
;
; Set current directory path
;
	       CMP  COM_CDIALOG,COM_APPMENU  ;check if program menu dialog
	       JNE  MC20		     ; don't ask for dir from DOS Serv
;
	       JMP  MC30
;
MC20:	       CMP  COM_CDIALOG,COM_PAAB     ;check if program menu dialog
	       JE   MC30		     ; don't ask for dir from DOS Serv
;
	       CMP  COM_CDIALOG,COM_DCLR     ;check if program menu dialog
	       JE   MC30		     ; don't ask for dir from DOS Serv
;
	       XOR  AX,AX		     ;get current selected directory
	       MOV  AX,1		     ;get current selected dir	;P*4245
	       CALL RETURN_PATH 	     ; in DOS services
;
	       MOV  BX,OFFSET FULLSPEC	     ;file name
	       MOV  DL,DS:BYTE PTR[BX]	     ;drive id
	       CALL SET_DRIVE		     ;set to the drive
;
	       PUSH DI
	       MOV  AH,0EH		     ;change to selected drive
	       MOV  DX,DATA
	       MOV  DS,DX
	       LEA  DI,FULLSPEC
	       MOV  DL,[DI]
	       SUB  DL,'A'
	       INT  21H
	       POP  DI
;
	       MOV  AH,3BH		     ;change to selected directory
	       MOV  DX,DATA
	       MOV  DS,DX
	       LEA  DX,FULLSPEC
	       INT  21H
;
; Move in COMSPEC to PSC workarea for new COMMAND.COM PSC execution.
;
MC30:	       MOV  SI,OFFSET COM_PFILSPEC   ;COMSPEC location
;
	       mov  dl, byte ptr [si]	     ;get drive letter of comspec
	       call set_drive		     ;set logical drive
;
	       MOV  DI,OFFSET PEC_COM	     ;PSC workarea location
	       MOV  PEC_BYTE,0		     ;clear length
;
MC40:	       MOV  AL,DS:BYTE PTR [SI]      ;get character
	       CMP  AL,0		     ;end of string?
	       JE   MC50		     ;yes, add parm sep char
;
	       MOV  DS:BYTE PTR [DI],AL      ;put character in PSC workarea
	       INC  PEC_BYTE		     ;adjust length
	       INC  SI			     ;point to next COMSPEC char
	       INC  DI			     ;point to next PSC position
	       JMP  MC40		     ;get next character
;
MC50:	       MOV  DS:BYTE PTR [DI],PEC_SEP ;set parameter seperator char
	       INC  PEC_BYTE		     ;adjust length
	       PUSH DS
	       POP  ES			     ;set segment of PSC workarea
	       MOV  DI,OFFSET PEC_TITLE      ;set offset of PSC workarea

	       OR   COM_PROCFLAG,COM_CMDPSC  ;set COMMAND.COM PSC exec	P*3748
	       CALL FAR PTR PROCESS_PSC      ;set up to process PSC
;
	       POP  DI			     ;restore registers
	       POP  SI
	       POP  BP
	       POP  DX
	       POP  CX
	       POP  BX
	       POP  AX
;
MCEXIT:
;
	       RET
COMMAND_LINE   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; SET_DRIVE								      :
;									      :
;	  On a single drive system, set the logical to the physical drive.    :
;									      :
; Entry:  DL - Drive letter						      :
;									      :
; Exit:   Logical drive set						      :
;									      :
; Notes:  None								      :
;									      :
;-----------------------------------------------------------------------------+
;
SET_DRIVE      PROC NEAR

	       PUSH BX			     ;				P*4831
	       PUSH DX			     ;				P*4831
	       PUSH AX			     ;				P*4831

	       AND  DL,0DFH		     ; convert it to		P*4831
	       SUB  DL,40H		     ;	 an binary number.	P*4831
	       MOV  BL,DL
	       MOV  AX,440FH		     ; I/O control		P*4831
	       INT  21H 		     ; set logical drive letter P*4831

	       POP  AX			     ;				P*4831
	       POP  DX			     ;				P*4831
	       POP  BX			     ;				P*4831
	       RET			     ; return to caller 	P*4831

SET_DRIVE      ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCCLRRD_CALL					      :
;									      :
; Description:		Call to PCCLRRD.				      :
;									      :
; Entry:		PCCLRRD parameter block initialized.		      :
;									      :
; Exit: 		PCCLRRD parameter block initialized.		      :
;									      :
; Entry point:		PCCLRRD_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCCLRRD_CALL   PROC NEAR		     ;*PCR (ENTIRE PROC)
;
	       PUSH DS			     ;Set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;Save registers
;
	       LEA  DI,CRD_OPT1 	     ;Set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;Make call to CAS-RM
	       MOV  BX,CRD_RN		     ;Set cas routine number
	       INT  CASINT		     ;Call routine
ELSE
	       CALL CLRRD
ENDIF
;
; copy the color index vector into buffer below clrrd buffer
;
	       MOV  AX,16		     ;calc length of color read and
	       MOV  BX,MAX_COLRBUF	     ; write buffers
	       MUL  BX			     ;# paragraphs * 16 = # bytes
	       SUB  AX,500		     ;leave room for safe buffer
	       ADD  AX,CRD_BUFOFF	     ;add current crd buf offset
	       MOV  DI,AX
	       MOV  SI,CRD_CCBVECOFF	     ;get source address
	       MOV  CRD_CCBVECOFF,DI	     ;set destination offset
;
	       CMP  CRD_ERROR,0 	     ;was there an error
	       JNE  CR_EXIT		     ;yes, don't overwrite
	       CMP  CRD_DOSERROR,0	     ;was there an error
	       JNE  CR_EXIT		     ;yes, don't overwrite
;
	       MOV  ES,CRD_BUFSEG	     ;set destination segment
	       MOV  CX,CRD_CCBVECLEN	     ;get the length to move
	       PUSH DS
	       MOV  AX,CRD_CCBVECSEG	     ;set source segment
	       MOV  DS,AX
;
	       REP  MOVSB		     ;move the data
	       POP  DS
;
CR_EXIT:       POP  DI			     ;Restore registers
	       POP  DS
;
	       RET
PCCLRRD_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		SET_DEFAULT					      :
;									      :
; Description:		Set default value in specified ICB control block.     :
;									      :
; Entry:		ES:DI	      = Address of default value.	      :
;			CX	      = Length of string.		      :
;			AX	      = ICB number of input field.	      :
;									      :
; Exit: 		None.						      :
;									      :
; Entry point:		None.						      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
SET_DEFAULT    PROC FAR
;
	       PUSH ES			     ;save default segment
	       PUSH DI			     ;save default offset
;
	       CALL FAR PTR GET_ICB	     ;get input control block
;
	       MOV  ES:[DI]+ICB_CURCHAR,1    ;reset starting cursor position
	       MOV  ES:[DI]+ICB_DEFLEN,CX    ;set length
	       POP  ES:[DI]+ICB_DEFOFF	     ;offset
	       POP  ES:[DI]+ICB_DEFSEG	     ;segment
;
	       RET
SET_DEFAULT    ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		GET_PCB 					      :
;									      :
; Description:		Return address of specified panel control block.      :
;									      :
; Entry:		AX	      = Number of PCB vector desired.	      :
;									      :
;			COM_PCBVECSEG = PCB vector segment.		      :
;			COM_PCBVECOFF = PCB vector offset.		      :
;			COM_PCBVECLEN = number of bytes in each vector	      :
;									      :
; Exit: 		ES:DI = Address of specified PCB		      :
;									      :
; Entry point:								      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
GET_PCB        PROC FAR
;
	       PUSH AX
	       PUSH BX
	       PUSH CX
	       PUSH DX
;
; read panel control block vector to obtain PCB address
;
	       MOV  BX,COM_PCBVECSEG	    ;get beginning PCB vector address
	       MOV  ES,BX
	       MOV  DI,COM_PCBVECOFF
;
	       DEC  AX			     ;make zero based
	       MOV  BX,COM_PCBVECLEN	     ;multiply PCB element length by
					     ; desired vector number in BX
	       MUL  BX			     ; to determine offset into PCB vec
	       ADD  DI,AX		     ;add offset inside table
	       MOV  BX,ES:[DI]		     ;get actual PCB segment
	       MOV  CX,ES:[DI]+2	     ;point past PCB seg to get PCB off
;
	       MOV  ES,BX		     ;set ES:DI to panel's actual
	       MOV  DI,CX		     ; PCB address
;
	       POP  DX
	       POP  CX
	       POP  BX
	       POP  AX
;
	       RET
GET_PCB        ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		GET_SCB 					      :
;									      :
; Description:		Return address of specified scroll control block.     :
;									      :
; Entry:		AX	      = Number of SCB vector desired.	      :
;									      :
;			COM_SCBVECSEG = SCB vector segment.		      :
;			COM_SCBVECOFF = SCB vector offset.		      :
;			COM_SCBVECLEN = number bytes in each vector	      :
;									      :
; Exit: 		ES:DI = Address of specified SCB		      :
;									      :
; Entry point:								      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
GET_SCB        PROC NEAR
;
	       PUSH AX
	       PUSH BX
	       PUSH CX
	       PUSH DX
;
; read panel control block vector to obtain SCB address
;
	       MOV  BX,COM_SCBVECSEG	    ;get beginning SCB vector address
	       MOV  ES,BX
	       MOV  DI,COM_SCBVECOFF
;
	       DEC  AX			     ;make zero based
	       MOV  BX,COM_SCBVECLEN	     ;multiply SCB element length by
					     ; desired vector number in BX
	       MUL  BX			     ; to determine offset into SCB vec
	       ADD  DI,AX		     ;add offset inside table
	       MOV  BX,ES:[DI]		     ;get actual SCB segment
	       MOV  CX,ES:[DI]+2	     ;point past SCB seg to get SCB off
;
	       MOV  ES,BX		     ;set ES:DI to panel's actual
	       MOV  DI,CX		     ; PCB address
;
	       POP  DX
	       POP  CX
	       POP  BX
	       POP  AX
;
	       RET
GET_SCB        ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		GET_ICB 					      :
;									      :
; Description:		Return address of specified input control block.      :
;									      :
; Entry:		AX	      = Number of ICB vector desired.	      :
;									      :
;			COM_ICBVECSEG = ICB vector segment.		      :
;			COM_ICBVECOFF = ICB vector offset.		      :
;			COM_ICBVECLEN = vector length.			      :
;									      :
; Exit: 		ES:DI = Address of specified ICB		      :
;									      :
; Entry point:								      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
GET_ICB        PROC FAR
;
	       PUSH AX
	       PUSH BX
	       PUSH CX
	       PUSH DX
;
; read input control block vector to obtain PCB address
;
	       MOV  BX,COM_ICBVECSEG	    ;get beginning ICB vector address
	       MOV  ES,BX
	       MOV  DI,COM_ICBVECOFF
;
	       DEC  AX			     ;make zero based
	       MOV  BX,COM_ICBVECLEN	     ;multiply ICB element length by
					     ; desired vector number in BX
	       MUL  BX			     ; to determine offset into ICB vec
	       ADD  DI,AX		     ;add offset inside table
	       MOV  BX,ES:[DI]		     ;get actual ICB segment
	       MOV  CX,ES:[DI]+2	     ;point past ICB seg to get ICB off
;
	       MOV  ES,BX		     ;set ES:DI to input's actual
	       MOV  DI,CX		     ; ICB address
;
	       TEST COM_STATE,COM_TEXT	     ;check if in text mode
	       JE   GIEXIT
;
	       AND  ES:[DI]+ICB_OPT1,NOT ICB_BOX
					     ;if in text mode deactivate box
					     ; option
;
GIEXIT:        POP  DX
	       POP  CX
	       POP  BX
	       POP  AX
;
	       RET
GET_ICB        ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		GET_ERROR					      :
;									      :
; Description:		Return address of error message.		      :
;									      :
; Entry:		AX	      = Number of vector desired.	      :
;									      :
;			COM_ERRVECSEG = Error message vector segment.	      :
;			COM_ERRVECOFF = Error message vector offset.	      :
;			COM_ERRVECLEN = Length of each vector in bytes.       :
;									      :
; Exit: 		ES:DI = Address of specified error message.	      :
;			AX    = length of error message.		      :
;									      :
; Entry point:		GET_ERROR					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
GET_ERROR      PROC FAR
;
	       PUSH BX
	       PUSH CX
	       PUSH DX
;
; read error message vector
;
	       MOV  BX,COM_ERRVECSEG	     ;get beginning vector address
	       MOV  ES,BX
	       MOV  DI,COM_ERRVECOFF
;
	       DEC  AX			     ;make zero based
	       MOV  BX,COM_ERRVECLEN	     ;multiply element length by
					     ; desired vector number in BX
	       MUL  BX			     ; to determine offset into vector
	       ADD  DI,AX		     ;add offset inside table
	       MOV  CX,ES:[DI]		     ;get error text offset
	       XOR  AX,AX		     ;clear to zero
	       MOV  AL,ES:[DI]+2	     ;get error text length
;
	       MOV  DI,CX		     ;set ES:DI to panel's actual
					     ; PCB address
;
	       POP  DX
	       POP  CX
	       POP  BX
;
	       RET
GET_ERROR      ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		GET_BUTTON					      :
;									      :
; Description:		Return address of graphics button.		      :
;									      :
; Entry:		AX	      = Number of vector desired.	      :
;									      :
;			COM_BCBVECSEG = vector segment. 		      :
;			COM_BCBVECOFF = vector offset.			      :
;			COM_BCBVECLEN = Length of each vector in bytes.       :
;									      :
; Exit: 		ES:DI = Address of specified string.		      :
;									      :
; Entry point:		GET_BUTTON					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
GET_BUTTON     PROC NEAR
;
	       PUSH BX
	       PUSH CX
	       PUSH DX
;
; read keystroke vector
;
	       MOV  BX,COM_BCBVECSEG	    ;get beginning vector address
	       MOV  ES,BX
	       MOV  DI,COM_BCBVECOFF
;
	       DEC  AX			     ;make zero based
	       MOV  BX,COM_BCBVECLEN	     ;multiply element length by
					     ; desired vector number in BX
	       MUL  BX			     ; to determine offset into vector
	       ADD  DI,AX		     ;add offset inside table
	       MOV  CX,ES:[DI]		     ;get text offset
	       MOV  DI,CX		     ;set ES:DI to actual data
;
	       POP  DX
	       POP  CX
	       POP  BX
;
	       RET
GET_BUTTON     ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		GET_STRING					      :
;									      :
; Description:		Return address of string.			      :
;									      :
; Entry:		AX	      = Number of ICB vector desired.	      :
;									      :
;			COM_STRVECSEG = String vector segment.		      :
;			COM_STRVECOFF = String vector offset.		      :
;			COM_STRVECLEN = Length of each vector in bytes.       :
;									      :
; Exit: 		ES:DI = Address of specified string.		      :
;			AX    = length of string.			      :
;									      :
; Entry point:		GET_STRING					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
GET_STRING     PROC FAR
;
	       PUSH DX
	       PUSH BX
	       PUSH CX
;
; read error message vector
;
	       MOV  BX,COM_STRVECSEG	    ;get beginning vector address
	       MOV  ES,BX
	       MOV  DI,COM_STRVECOFF
;
	       DEC  AX			     ;make zero based
	       MOV  BX,COM_STRVECLEN	     ;multiply element length by
					     ; desired vector number in BX
	       MUL  BX			     ; to determine offset into vector
	       ADD  DI,AX		     ;add offset inside table
	       MOV  CX,ES:[DI]		     ;get text offset
	       XOR  AX,AX		     ;clear to zero
	       MOV  AL,ES:[DI]+2	     ;get text length
;
	       MOV  DI,CX		     ;set ES:DI to actual data
;
	       POP  CX
	       POP  BX
	       POP  DX
;
	       RET
GET_STRING     ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		GET_ATTR					      :
;									      :
; Description:		Returns the normal and highlight color attributes     :
;			of a specified panel.				      :
;									      :
;									      :
; Entry:		AX	      = Panel ID number.		      :
;									      :
; Exit: 		AH	      = Panel's normal color attr             :
;			AL	      = Panel's highlight color attr          :
;									      :
; Entry point:		GET_ATTR					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
GET_ATTR       PROC FAR
;
	       PUSH ES			     ;save registers
	       PUSH DI
;
	       CALL FAR PTR GET_PCB	     ;load the panel's PCB in ES:DI
	       MOV  AX,ES:[DI]+PCB_CCBID     ;get panel's color index number
;
	       CALL FAR PTR GET_COLOR	     ;load the color index
	       MOV  AH,ES:[DI]+CCB_A1	     ;get the normal color attr
	       MOV  AL,ES:[DI]+CCB_A2	     ;get the highlighted color attr
;
	       POP  DI			     ;restore registers
	       POP  ES
;
	       RET
GET_ATTR       ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		GET_COLOR					      :
;									      :
; Description:		Returns ES:DI pointing to color index specified in    :
;			AX.  Use the CCB_PB to reference the desired color    :
;			attributes.					      :
;									      :
; Entry:		AX	      = Color index to return.		      :
;			CRD_CCBVECOFF = Offset of color index.		      :
;			CRD_CCBVECSEG = Segment of color index. 	      :
;									      :
; Exit: 		ES:DI	      = Address of color index		      :
;									      :
; Entry point:		GET_COLOR					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
GET_COLOR      PROC FAR
;
	       PUSH AX			     ;save registers
	       PUSH BX
	       PUSH DX
;
	       DEC  AX			     ; default index and make zero
					     ; based
	       PUSH CRD_CCBVECSEG	     ;get color index segment
	       POP  ES
;
	       PUSH CRD_CCBVECOFF	     ;get color index offset
	       POP  DI
;
	       MOV  BX,COM_CCBLEN	     ;multiply CCB element length by
	       MUL  BX			     ; desired vector add offset
	       ADD  DI,AX		     ; to color index offset
;
	       POP  DX			     ;restore registers
	       POP  BX
	       POP  AX
;
	       RET
GET_COLOR      ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		SET_SHLVMDOS					      :
;									      :
; Description:		Set shell video mode from current DOS video mode.     :
;									      :
; Entry:		COM_STATE    = Option word indicating invocation      :
;				       parameters passed through PSP.	      :
;									      :
; Exit: 		PCGVIDO      = Parmeter block initialized.	      :
;			COM_DVIDMODE = Original DOS video mode. 	      :
;			COM_SVIDMODE = Current Shell video mode.	      :
;									      :
; Entry point:		SET_SHLVMDOS					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	PCGVIDO_CALL					      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
SET_SHLVMDOS   PROC NEAR
;
	       LEA  DI,GEN_DATA 	     ;load offset of PCGRAPH PB
	       MOV  [DI]+G_INITVFLAG,0	     ;init to VGA hardware available
;
; Check if mode 10H requested
;
	       TEST COM_STATE,COM_M10H	     ;check if graphics mode 10H
	       JE   VMD20		     ; requested (EGA/VGA)
;
	       TEST GV_STAT1,GV_256K	     ;256K memory on EGA card
	       JNE  VMD10
;
	       MOV  COM_ERRID,ERR_256K	     ;set error for less than 256KB
	       JMP  VMDEXIT		     ; available on graphics adaphter
;
VMD10:	       MOV  AL,10H		     ;set for mode 10H
	       JMP  VMD60
;
; Check if mode 11H requested
;
VMD20:	       TEST COM_STATE,COM_M11H	     ;check if graphics mode 11H
	       JE   VMD40		     ; requested (VGA/MCGA)
;
	       TEST GV_STAT1,GV_EGAA	     ;check if VGA/EGA hardware avail
	       JNE  VMD30
;
	       CMP  GE_MODEL,MODEL_30	     ;check for MCGA support
	       JNE  VMD30
;
	       OR   IN_OPT,IN_MCGA	     ;MCGA active
	       MOV  [DI]+G_INITVFLAG,G_INITNOVGA
					     ;no VGA hardware available
;
VMD30:	       MOV  AL,11H		     ;set for mode 11H
	       JMP  VMD60
;
; check if mode 12H requested
;
VMD40:	       TEST COM_STATE,COM_M12H	     ;check if graphics mode 12H
	       JE   VMD70
;
	       TEST GV_STAT1,GV_256K	     ;256K memory on EGA card
	       JNE  VMD50
;
	       MOV  COM_ERRID,ERR_256K	     ;set error for less than 256KB
	       JMP  VMDEXIT		     ; available on graphics adaphter
;
VMD50:	       MOV  AL,12H		     ;set for mode 12H
;
; set graphics video mode
;
VMD60:	       CMP  AL,12H		     ;check for mode 12H
	       JE   VMD62
;
	       CMP  AL,11H		     ;check for mode 11H
	       JE   VMD62
;
	       JMP  VMD65		     ;must be mode 10H
;
VMD62:	       CMP  GE_MODEL,MODEL_30	     ;check if model 30
	       JE   VMD65
;
	       CMP  GE_MODEL,MODEL_25	     ;check if model 25
	       JE   VMD65
;
	       PUSH AX
	       MOV  AX, 1A00H		     ;BIOS check display
	       INT  10H
	       CMP  AL, 1AH		     ;VGA supported?
	       POP  AX
	       JE   VMD65		     ;yes, continue
;
	       MOV  AL,0		     ;set error in video mode
	       JMP  VMD80		     ;exit
;
VMD65:	       MOV  [DI]+G_INITVMODE,AL      ;set desired graphics video mode
	       MOV  [DI]+G_FUNC,G_INIT	     ;initialize graphics support
	       MOV  BX,DATA		     ;point to general PCGRAPH
	       MOV  ES,BX		     ; initialize parameter block
	       PUSH AX
	       CALL PCGRAPH_CALL	     ;initialize graphics
	       POP  AX
	       JMP  VMD80
;
; set text video mode
;
VMD70:	       MOV  AL,7		     ;initialize
	       CMP  AL,COM_DVIDMODE	     ;if monochrome text mode is active
	       JE   VMD80		     ; no need to set mode
;
	       MOV  AL,3
	       CMP  AL,COM_DVIDMODE	     ;if color text mode is active no
	       JE   VMD80		     ; need to set mode
;
	       XOR  AH,AH		     ;set to color text mode
	       PUSH AX			     ;save
	       INT  10H
	       POP  AX			     ;restore
;
; read all video information and check if mode set successful
;
VMD80:	       CALL PCGVIDO_CALL	     ;get new video information and
	       CMP  AL,GV_VIDMODE	     ; check if mode set successful
	       JE   VMD100		     ;yes
;
	       MOV  COM_ERRID,ERR_MODE	     ;requested video mode failed
	       JMP  VMDEXIT
;
VMD100:        MOV  COM_SVIDMODE,AL	     ;save current shell video mode
	       cmp  al, 7		     ;monochrome text mode active?
	       jne  vmd101		     ;no, continue
	       and  COM_STATE,not COM_FLCS   ;inactivate color change
vmd101:
	       CALL FAR PTR CURSOROFF	     ;deactive cursor
;
VMDEXIT:				     ;exit
;
	       RET
SET_SHLVMDOS   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		SET_DOSVMSHL					      :
;									      :
; Description:		Set original DOS video mode from current shell mode   :
;			and disable mouse support			      :
;									      :
; Entry:		PCGVIDO      = Parmeter block initialized.	      :
;			COM_DVIDMODE = Original DOS video mode. 	      :
;			COM_SVIDMODE = Current Shell video mode.	      :
;			COM_STATE    = Invocation options.		      :
;									      :
; Exit: 		PCGVIDO      = Parmeter block initialized.	      :
;									      :
; Entry point:		SET_DOSVMSHL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	PCGVIDO_CALL					      :
;			PCTRACK_CALL					      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
SET_DOSVMSHL   PROC NEAR
;
; Disable mouse support
;
	       CALL FAR PTR MOUSE_DIS	     ;disable mouse support
;
; Check if shell is in text mode
;
VMS10:	       CMP  COM_STATE,COM_TEXT
	       JNE  VMS20
;
; Terminate shell graphics mode and restore original DOS video mode
;
	       LEA  DI,GEN_DATA 	     ;load offset of PCGRAPH PB
	       MOV  [DI]+G_FUNC,G_TERM	     ;terminate graphics support
	       MOV  BX,DATA		     ;point to general PCGRAPH
	       MOV  ES,BX		     ;initialize parameter block
	       CALL PCGRAPH_CALL	     ;initialize graphics
	       JMP  VMSEXIT
;
; Shell is in text video mode, restore original DOS video mode
;
VMS20:	       MOV  AL,COM_DVIDMODE	     ;if shell mode and DOS mode are
	       XOR  AH,AH		     ;shell and DOS modes are different
	       INT  10H 		     ; reset original DOS mode
;
; Exit
;
VMSEXIT:       MOV  AL,0		     ;clear screen
	       MOV  CH,0
	       MOV  CL,0
	       MOV  DX,GV_NUMLINES	     ;set DH to bottom row
	       MOV  DL,80		     ;set DL to screen width in chars
	       MOV  BH,07H		     ;set white on black color
	       MOV  AH,6
	       INT  10H
;
	       CALL FAR PTR CURSORON
	       CALL PCGVIDO_CALL
;
	       RET
SET_DOSVMSHL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		SET_CMDVMSHL					      :
;									      :
; Description:		Set shell command line video mode from current shell  :
;			mode.						      :
;									      :
; Entry:		PCGVIDO      = Parmeter block initialized.	      :
;			COM_DVIDMODE = Original DOS video mode. 	      :
;			COM_STATE    = Invocation options.		      :
;									      :
; Exit: 		COM_CVIDMODE = Shell command line video mode.	      :
;			PCGVIDO      = Parmeter block initialized.	      :
;									      :
; Entry point:		SET_CMDVMSHL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	PCGVIDO_CALL					      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
SET_CMDVMSHL   PROC FAR
;
; Check if shell text mode is active
;
	       CMP  COM_STATE,COM_TEXT
	       JE   CMDEXIT
;
; Terminate shell graphics mode and restore original DOS video mode
;
	       LEA  DI,GEN_DATA 	     ;load offset of PCGRAPH PB
	       MOV  [DI]+G_FUNC,G_TERM	     ;terminate graphics support
	       MOV  BX,DATA		     ;point to general PCGRAPH
	       MOV  ES,BX		     ;initialize parameter block
	       CALL PCGRAPH_CALL	     ;initialize graphics
;
; Set shell command line to text video mode
;
	       MOV  AL,7		     ;initialize to monochrome mode
	       CMP  COM_DVIDMODE,AL	     ;check if DOS video mode was
	       JE   CMD10		     ; monochrome
;
	       MOV  AL,3		     ;set color text mode
;
CMD10:	       XOR  AH,AH		     ;set command line video mode
	       INT  10H
;
; Exit
;
CMDEXIT:       CALL PCGVIDO_CALL
;
	       RET
SET_CMDVMSHL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		SET_SHLVMCMD					      :
;									      :
; Description:		Set shell video mode from shell command line video    :
;			mode.						      :
;									      :
; Entry:		COM_STATE    = Option word indicating invocation      :
;				       parameters passed through PSP.	      :
;									      :
; Exit: 		PCGVIDO      = Parmeter block initialized.	      :
;			COM_DVIDMODE = Original DOS video mode. 	      :
;			COM_SVIDMODE = Current Shell video mode.	      :
;									      :
; Entry point:		SET_SHLVMCMD					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	PCGVIDO_CALL					      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
SET_SHLVMCMD   PROC FAR
;
; Check if shell graphics modes 10H, 11H, and 12H were active
;
	       LEA  DI,GEN_DATA 	     ;load offset of PCGRAPH PB
	       MOV  [DI]+G_INITVFLAG,0
;
	       TEST COM_STATE,COM_M11H	     ;check if graphics mode 11H
	       JE   SMC20		     ; requested (VGA/MCGA)
;
	       TEST GV_STAT1,GV_EGAA	     ;check if VGA/EGA hardware avail
	       JNE  SMC10
;
	       CMP  GE_MODEL,MODEL_30	     ;check for MCGA support
	       JNE  SMC10
;
	       OR   IN_OPT,IN_MCGA	     ;MCGA active
	       MOV  [DI]+G_INITVFLAG,G_INITNOVGA
					     ;no VGA hardware available
;
SMC10:	       MOV  AL,11H		     ;set for mode 11H
	       JMP  SMC50
;
SMC20:	       CMP  COM_SVIDMODE,10H	     ;check if mode 10 active
	       JE   SMC50
;
	       CMP  COM_SVIDMODE,12H	     ;check if mode 12 active
	       JE   SMC50
;
	       MOV  AH,0FH		     ;get current video mode
	       INT  10H
;
	       CMP  AL,COM_SVIDMODE	     ;check if command line video mode
	       JNE  SMC30		     ; changed and reset if yes
;
	       JMP  SMCEXIT
;
; Switch to monochrome monitor
;
SMC30:	       CMP  COM_SVIDMODE,3H	     ;check if color mode should be set
	       JE   SMC40
;
	       PUSH DS
;
	       XOR  AX,AX		     ;clear to zero
	       MOV  ES,AX		     ;point to BIOS data area and
	       MOV  DL,ES:[410H]	     ; get mode byte
	       OR   DL,00110000B
	       MOV  ES:[410H],DL
	       XOR  AH,AH		     ;set color monochrome mode
	       MOV  AL,7H
	       INT  10H
;
	       POP  DS
;
	       JMP  SMCEXIT
;
; Switch to color monitor in text mode 80x25
;
SMC40:	       PUSH DS
;
	       XOR  AX,AX		     ;clear to zero
	       MOV  ES,AX		     ;point to BIOS data area and
	       MOV  DL,ES:[410H]	     ; get mode byte
	       AND  DL,11001111B
	       OR   DL,00100000B
	       MOV  ES:[410H],DL
	       XOR  AH,AH		     ;set color mode
	       MOV  AL,3H
	       INT  10H
;
	       POP  DS
;
	       JMP  SMCEXIT
;
; Initialize shell graphics mode from shell command line text mode
;
SMC50:	       MOV  AH,0FH		     ;get current video mode
	       INT  10H
;
	       CMP  AL,7H		     ;check if command line mode set
	       JNE  SMC60		     ; for monochrome, if yes reset to
					     ; graphics monitor
;
	       PUSH DS
;
	       XOR  AX,AX		     ;clear to zero
	       MOV  ES,AX		     ;point to BIOS data area and
	       MOV  DL,ES:[410H]	     ; get mode byte
	       AND  DL,11001111B
	       OR   DL,00100000B
	       MOV  ES:[410H],DL
	       XOR  AH,AH		     ;set color 80x25 mode before
	       MOV  AL,3H		     ; setting graphics mode
	       INT  10H
;
	       POP  DS
;
SMC60:	       LEA  DI,GEN_DATA 	     ;load offset of PCGRAPH PB
	       MOV  AL,COM_SVIDMODE	     ;set the shell graphics video mode
	       MOV  [DI]+G_INITVMODE,AL
	       MOV  [DI]+G_FUNC,G_INIT	     ;initialize graphics support
	       MOV  BX,DATA		     ;point to general PCGRAPH
	       MOV  ES,BX		     ;initialize parameter block
	       CALL PCGRAPH_CALL	     ;initialize graphics
;
; Exit
;
SMCEXIT:       CALL PCGVIDO_CALL
;
	       RET
SET_SHLVMCMD   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		CURSOROFF					      :
;									      :
; Description:		Deactivates hardware cursor from display.	      :
;									      :
; Entry:		None						      :
;									      :
; Exit: 		None.						      :
;									      :
; Entry point:		CURSOROFF					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
CURSOROFF      PROC FAR
;
	       PUSH AX			     ;save registers
	       PUSH BX
	       PUSH CX
;
	       MOV  AH,3		     ;function to get cursor info
	       MOV  BH,0		     ;page zero
	       INT  10H
	       OR   CH,20H		     ;set bit 6
	       MOV  AH,1		     ;function to set cursor
	       INT  10H
;
	       POP  CX			     ;restore registers
	       POP  BX
	       POP  AX
;
	       RET
CURSOROFF      ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		CURSORON					      :
;									      :
; Description:		Displays the hardare cursor.			      :
;									      :
; Entry:		None.						      :
;									      :
; Exit: 		None.						      :
;									      :
; Entry point:		CURSORON					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
CURSORON       PROC FAR
;
	       PUSH AX			     ;save registers
	       PUSH BX
	       PUSH CX
	       PUSH DX			     ;>>SN
;
	       MOV  AH,3		     ;function to get cursor info
	       MOV  BH,0		     ;page zero
	       INT  10H
	       AND  CH,NOT 20H		     ;clear bit 6
	       MOV  AH,1		     ;function to set cursor
	       INT  10H
;
	       POP  DX			     ;>>SN
	       POP  CX			     ;restore registers
	       POP  BX
	       POP  AX
;
	       RET
CURSORON       ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCINPUT_CALL					      :
;									      :
; Description:		Call to PCINPUT.				      :
;									      :
; Entry:		PCINPUT parameter block initialized.		      :
;									      :
; Exit: 		PCINPUT parameter block initialized.		      :
;									      :
; Entry point:		PCINPUT_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCINPUT_CALL   PROC FAR
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       TEST COM_STATE2,COM_DBCS      ;check if DBCS option active
	       JE   INPT10
;
	       OR  IN_OPT,IN_DDBCS+IN_ADBCS  ;activate DBCS
;
INPT10:        LEA  DI,IN_OPT		     ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,IN_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL INPUT
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCINPUT_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCINCHA_CALL					      :
;									      :
; Description:		Call to PCINCHA.				      :
;									      :
; Entry:		PCINCHA parameter block initialized.		      :
;									      :
; Exit: 		PCINCHA parameter block initialized.		      :
;									      :
; Entry point:		PCINCHA_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCINCHA_CALL   PROC NEAR
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       TEST COM_STATE2,COM_DBCS      ;check if DBCS option active
	       JE   INCH10
;
	       OR  INC_OPT,INC_DDBCS	     ;activate DBCS
;
INCH10:        LEA  DI,INC_OPT		     ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,INC_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL INCHA
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCINCHA_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCDISPQ_CALL					      :
;									      :
; Description:		Call to PCDISPQ.				      :
;									      :
; Entry:		PCDISPQ parameter block initialized.		      :
;									      :
; Exit: 		PCDISPQ parameter block initialized.		      :
;									      :
; Entry point:		PCDISPQ_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCDISPQ_CALL   PROC NEAR
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       LEA  DI,QM_OPT1		     ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,QM_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL DISPQ
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCDISPQ_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCPANEL_CALL					      :
;									      :
; Description:		Initialize for call to PCPANEL including refresh of   :
;			input and scroll fields in the logical video buffer   :
;			before display. 				      :
;									      :
; Entry:		PCPANEL parameter block initialized.		      :
;									      :
;			AX  0= Logical video buffer mode write		      :
;			    1= Direct video mode write			      :
;									      :
; Exit: 		PCPANEL parameter block initialized.		      :
;									      :
; Entry point:		PCPANEL_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCPANEL_CALL   PROC NEAR
;
; initialize PCDISPQ info for PCPANEL call
;
	       CMP  AX,1		     ;check if direct video buffer
	       JE   PP10		     ; write option active
;
	       MOV  BX,QM_PANQUENUM
	       MOV  PM_PANQUENUM,BX	     ;number of panels in parent queue
;
	       MOV  BX,QM_CHDQUENUM
	       MOV  PM_CHDQUENUM,BX	     ;number panels in child queue
;
	       MOV  BX,QM_ACTIVEPAN
	       MOV  PM_ACTIVEPAN,BX	     ;active parent panel number
;
	       MOV  PM_OPT1,PM_DOA+PM_DOV+PM_DOQ+PM_CL
	       MOV  PM_PANPDQNUM,1	     ;beg/ending parent PDQ number
	       MOV  PM_PANBRKOFF,0	     ;panel off in lvb of break panel
;
; actual PCPANEL call
;
PP10:	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       LEA  DI,PM_OPT1		     ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,PM_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL PANEL
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
; Exit
;
PPEXIT: 				     ;exit
;
	       RET
PCPANEL_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCMBEEP_CALL					      :
;									      :
; Description:		Call to PCMBEEP.				      :
;									      :
; Entry:		PCMBEEP parameter block initialized.		      :
;									      :
; Exit: 		PCMBEEP parameter block initialized.		      :
;									      :
; Entry point:		PCMBEEP_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCMBEEP_CALL   PROC FAR
;
	       TEST COM_STATE2,COM_SOUD      ;check if sound is off
	       JE   BEXIT
;
	       PUSH CX			     ;save registers
	       PUSH DX
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       LEA  DI,MB_FREQUENCY	     ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,MB_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL MBEEP
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       POP  DX			     ;restore registers
	       POP  CX
;
BEXIT:
;
	       RET
PCMBEEP_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCSLCTP_CALL					      :

;									      :
; Description:		Call to PCSLCTP.				      :
;									      :
; Entry:		ES:DI = beginning address of PCSLCTP parameter block. :
;									      :
; Exit: 		PCSLCTP parameter block initialized.		      :
;									      :
; Entry point:		PCSLCTP_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCSLCTP_CALL   PROC NEAR
;
; Initialize color index vector
;
	       MOV  AX,PM_CCBVECNUM	     ;set color index number
	       MOV  ES:[DI]+SCB_CCBVECNUM,AX
;
	       MOV  AX,CRD_CCBVECOFF	     ;set color index offset
	       MOV  ES:[DI]+SCB_CCBVECOFF,AX
;
	       MOV  AX,CRD_CCBVECSEG	     ;set color index segment
	       MOV  ES:[DI]+SCB_CCBVECSEG,AX
;
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,SCB_RN		     ;set CAS routine number
	       INT  CASINT		     ;call slctopt
ELSE
	       CALL SLCTP
ENDIF
;
	       RET
PCSLCTP_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCHLPRD_CALL					      :
;									      :
; Description:		Call to PCHLPRD.				      :
;									      :
; Entry:		PCHLPRD parameter block initialized.		      :
;									      :
; Exit: 		PCHLPRD parameter block initialized.		      :
;									      :
; Entry point:		PCHLPRD_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCHLPRD_CALL   PROC NEAR
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       LEA  DI,HRD_OPT1 	      ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,HRD_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL HLPRD
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCHLPRD_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCINSTR_CALL					      :
;									      :
; Description:		Call to PCINSTR.				      :
;									      :
; Entry:		PCINSTR parameter block initialized.		      :
;									      :
; Exit: 		PCINSTR parameter block initialized.		      :
;									      :
; Entry point:		PCINSTR_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCINSTR_CALL   PROC NEAR
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       LEA  DI,INS_OPT		      ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,INS_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL INSTRN
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCINSTR_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCGVIDO_CALL					      :
;									      :
; Description:		Call to PCGVIDO.				      :
;									      :
; Entry:		PCGVIDO parameter block initialized.		      :
;									      :
; Exit: 		PCGVIDO parameter block initialized.		      :
;									      :
; Entry point:		PCGVIDO_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCGVIDO_CALL   PROC NEAR
;
	       PUSH ES
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       LEA  DI,GV_STAT1 	     ;set DI to proper parameter block
					     ; for call
;
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,GV_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL GVIDO
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       POP  ES
;
	       RET
PCGVIDO_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCCLRWR_CALL					      :
;									      :
; Description:		Call to PCCLRWR.				      :
;									      :
; Entry:		PCCLRWR parameter block initialized.		      :
;									      :
; Exit: 		PCCLRWR parameter block initialized.		      :
;									      :
; Entry point:		PCCLRWR_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCCLRWR_CALL   PROC NEAR
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       LEA  DI,CWR_OPT		     ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,CWR_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL CLRWR
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCCLRWR_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCCRITE_CALL					      :
;									      :
; Description:		Call to PCCRITE.				      :
;									      :
; Entry:		PCCRITE parameter block initialized.		      :
;									      :
; Exit: 		PCCRITE parameter block initialized.		      :
;									      :
; Entry point:		PCCRITE_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCCRITE_CALL   PROC NEAR
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       LEA  DI,CE_OPT		     ;set DI to proper parameter block
					     ; for call
;
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,CE_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL CRITE
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCCRITE_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCWWRAP_CALL					      :
;									      :
; Description:		Call to PCWWRAP.				      :
;									      :
; Entry:		PCWWRAP parameter block initialized.		      :
;									      :
; Exit: 		PCWWRAP parameter block initialized.		      :
;									      :
; Entry point:		PCWWRAP_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCWWRAP_CALL   PROC NEAR
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       LEA  DI,WWP_OPT1 	     ;set DI to proper parameter block
					     ; for call
;
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,WWP_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL WWRAP
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCWWRAP_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCTRACK_CALL					      :
;									      :
; Description:		Call to PCTRACK.				      :
;									      :
; Entry:		PCTRACK parameter block initialized.		      :
;									      :
; Exit: 		PCTRACK parameter block initialized.		      :
;									      :
; Entry point:		PCTRACK_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCTRACK_CALL   PROC FAR
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       PUSH DS			     ;point to PCTRACK parameter block
	       POP  ES
;
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,MS_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL TRACK
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCTRACK_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCGRAPH_CALL					      :
;									      :
; Description:		Call to PCGRAPH.				      :
;									      :
; Entry:		PCGRAPH parameter block initialized.		      :
;									      :
; Exit: 		PCGRAPH parameter block initialized.		      :
;									      :
; Entry point:		PCGRAPH_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCGRAPH_CALL   PROC NEAR
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,MS_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL GRAPH
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCGRAPH_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCST2IN_CALL					      :
;									      :
; Description:		Call to PCST2IN.				      :
;									      :
; Entry:		PCST2IN parameter block initialized.		      :
;									      :
; Exit: 		PCST2IN parameter block initialized.		      :
;									      :
; Entry point:		PCST2IN_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCST2IN_CALL   PROC NEAR
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       LEA  DI,ST2_OPT1 	     ;set DI to proper parameter block
					     ; for call
;
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,S2I_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL ST2IN
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCST2IN_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		PCMOVEC_CALL					      :
;									      :
; Description:		Call to PCMOVEC.				      :
;									      :
; Entry:		PCMOVEC parameter block initialized.		      :
;									      :
; Exit: 		PCMOVEC parameter block initialized.		      :
;									      :
; Entry point:		PCMOVEC_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
PCMOVEC_CALL   PROC NEAR
;
	       PUSH DS			     ;set segment
	       POP  ES
;
	       PUSH DS
	       PUSH DI			     ;save registers
;
	       LEA  DI,MO_OPT		     ;set DI to proper parameter block
					     ; for call
;
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,MO_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL MOVEC
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
;
	       RET
PCMOVEC_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		SHELLDA_CALL					      :
;									      :
; Description:		Call to SHELLDA.				      :
;									      :
; Entry:		None						      :
;									      :
; Exit: 		None						      :
;									      :
; Entry point:		SHELLDA_CALL					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
SHELLDA_CALL   PROC NEAR
;
	       CALL SHELLDA
;
	       RET
SHELLDA_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; PCROWCL_CALL								      :
;									      :
;	  Call to PCROWCL.						      :
;									      :
; Entry:  PB initialized.						      :
;									      :
; Exit:   None								      :
;									      :
; Notes:  None								      :
;									      :
;-----------------------------------------------------------------------------+
;
PCROWCL_CALL   PROC NEAR

	       PUSH ES
	       PUSH DS			     ;set segment
	       POP  ES

	       PUSH DS
	       PUSH DI			     ;save registers

	       LEA  DI,CR_SCRWIDTH	     ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,CR_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL ROWCL
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
	       POP  ES
;
	       RET
PCROWCL_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; PCMOVEG_CALL								      :
;									      :
;	  Call to PCMOVEG.						      :
;									      :
; Entry:  PB initialized.						      :
;									      :
; Exit:   None								      :
;									      :
; Notes:  None								      :
;									      :
;-----------------------------------------------------------------------------+
;
PCMOVEG_CALL   PROC NEAR

	       PUSH ES
	       PUSH DS			     ;set segment
	       POP  ES

	       PUSH DS
	       PUSH DI			     ;save registers

	       LEA  DI,MG_OPT		     ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,MG_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL MOVEG
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
	       POP  ES
;
	       RET
PCMOVEG_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; PCGEQUP_CALL								      :
;									      :
;	  Call to PCGEQUP.						      :
;									      :
; Entry:  PB initialized.						      :
;									      :
; Exit:   None								      :
;									      :
; Notes:  None								      :
;									      :
;-----------------------------------------------------------------------------+
;
PCGEQUP_CALL   PROC NEAR

	       PUSH ES
	       PUSH DS			     ;set segment
	       POP  ES

	       PUSH DS
	       PUSH DI			     ;save registers

	       LEA  DI,GE_OPT		     ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,MG_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL GEQUP
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
	       POP  ES
;
	       RET
PCGEQUP_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; PCDATES_CALL								      :
;									      :
;	  Call to PCDATES.						      :
;									      :
; Entry:  PB initialized.						      :
;									      :
; Exit:   None								      :
;									      :
; Notes:  None								      :
;									      :
;-----------------------------------------------------------------------------+
;
PCDATES_CALL   PROC NEAR

	       PUSH ES
	       PUSH DS			     ;set segment
	       POP  ES

	       PUSH DS
	       PUSH DI			     ;save registers

	       LEA  DI,DTS_OPT		     ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,DTS_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL DATES
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
	       POP  ES
;
	       RET
PCDATES_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; PCTIMES_CALL								      :
;									      :
;	  Call to PCTIMES.						      :
;									      :
; Entry:  PB initialized.						      :
;									      :
; Exit:   None								      :
;									      :
; Notes:  None								      :
;									      :
;-----------------------------------------------------------------------------+
;
PCTIMES_CALL   PROC NEAR

	       PUSH ES
	       PUSH DS			     ;set segment
	       POP  ES

	       PUSH DS
	       PUSH DI			     ;save registers

	       LEA  DI,TMS_OPT		     ;set DI to proper parameter block
					     ; for call
IF CASRM
	       MOV  AH,00H		     ;make call to CAS-RM
	       MOV  BX,TMS_RN		     ;set CAS routine number
	       INT  CASINT		     ;call routine
ELSE
	       CALL TIMES
ENDIF
	       POP  DI			     ;restore registers
	       POP  DS
	       POP  ES
;
	       RET
PCTIMES_CALL   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		CHANGE_APPM					      :
;									      :
; Description:		Display Application menu screen.		      :
;									      :
; Entry:		None.						      :
;									      :
; Exit: 		COM_CDIALOG					      :
;									      :
; Entry point:		CHANGE_APPM					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
CHANGE_APPM    PROC FAR
;
	       TEST COM_STATE,COM_APPM	     ;check if app menu active
	       JNE  CAM10
;
	       CALL FAR PTR OPT_INACTIVE     ;display error panel for inactive *PCR
	       JMP  CAMEXIT
;
CAM10:	       MOV  COM_HLPOPT2,0	     ;set for normal shell help
	       MOV  COM_HCBIDAAB,HLP_AABPROGRAM
	       MOV  COM_HCBID,HLP_AABPROGRAM
;
	       MOV  AX,MFF_AABAOPT	     ;default to program menu AAB field
	       CALL FAR PTR LOC_MOUSEF
	       MOV  COM_CURAABF,AX
;
	       MOV  APP_SKIN,0		     ;set to reinitialize app menu fld
	       MOV  COM_CDIALOG,COM_PAAB     ;set for menu action bar dialog
	       MOV  COM_BASESCR,COM_APPSCR   ;initialize for display of DOS scr
;
CAMEXIT:
;
	       RET
CHANGE_APPM    ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		ALLOCATE_BUFB					      :
;									      :
; Description:		Allocate memory for directory and file buffers.       :
;									      :
; Entry:		COM_STATE2  = Invocation parameters.		      :
;			COM_DFSIZE  = Optional buffer override size in parags.:
;									      :
;			MAX_DIR1BUF = Size of directory buffer 1 in paragraph :
;			MAX_DIR2BUF = Size of directory buffer 2 in paragraph :
;			MAX_DOSWBUF = Size of view, copy, move working buffer :
;			MAX_EXECBUF = Size of app menu and/or command prompt  :
;				      free space to be made avail to dos in   :
;				      resident mode only.		      :
;									      :
;			Allocated by one DOS call with COM_DATA4SEG as	      :
;			starting segment.				      :
;									      :
;			COM_DATA4LEN  Optional DOS Services directory	      :
;			COM_DATA4OFF  list 1 buffer.			      :
;			COM_DATA4SEG					      :
;									      :
;			COM_DATA5LEN  Optional DOS Services directory	      :
;			COM_DATA5OFF  list 2 buffer.			      :
;			COM_DATA5SEG					      :
;									      :
;			COM_DATA6LEN  Optional DOS Services file list 1       :
;			COM_DATA6OFF  buffer				      :
;			COM_DATA6SEG					      :
;									      :
;			COM_DATA7LEN  Optional DOS Services file list 2       :
;			COM_DATA7OFF  buffer				      :
;			COM_DATA7SEG					      :
;									      :
;			COM_DATA8LEN  Optional DOS Services		      :
;			COM_DATA8OFF  buffer				      :
;			COM_DATA8SEG					      :
;									      :
; Entry point:		ALLOCATE_BUFB					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	INT 21H  48H Allocate memory			      :
;									      :
;-----------------------------------------------------------------------------+
;
ALLOCATE_BUFB  PROC FAR
;
	       TEST COM_STATE,COM_DOSS	     ;check if DOS Services configured
	       JNE  AMB05		     ;exit
;
	       JMP  AMBEXIT
;
; Determine avail memory, calc memory to allocate for shell functions
;
AMB05:	       MOV  AH,48H		     ;find out how many parags are aval
	       MOV  BX,0FFFFH		     ; in BX on return
	       INT  21H
;
; adjust for resident mode operation
;
	       TEST COM_STATE,COM_RESS	     ;check if resident mode is active
	       JE   AMB11		     ; if yes, check if prompt or menu
					     ; options are active, if yes,
					     ; reduce avail size by 64KB to
					     ; allow room for command line
					     ; or prog menu operation
;
AMB08:	       CMP  BX,MAX_EXECBUF	     ;64K remaining?
	       JB   AMB_ERR		     ;no, error
;
	       SUB  BX,MAX_EXECBUF	     ;save 64KB for execution of
					     ; command prompt or program menu
					     ; only if in resident mode
;
AMB11:	       MOV  CX,BX		     ;save avail paraghs for compare
;
	       TEST COM_STATE,COM_RESS	     ;check if resident mode is active
	       JNE  AMB12		     ; if yes, reserve room required
					     ; memory for view, copy,,,
					     ; if not, DOS funcs in shell will
					     ; automatically allocate memory
					     ; as needed
;
	       CMP  BX,MAX_DOSWBUF	     ;10K remaining?
	       JB   AMB_ERR		     ;no, error
;
	       SUB  BX,MAX_DOSWBUF	     ;reserve working memory for copy
					     ; and view functions (10KB)
;
; Check for minimum storage to run DOS Services
;
AMB12:	       MOV  TMP_DOSWBUF,MAX_DOSWBUF  ;max work buffer
	       MOV  TMP_DIRBUF,MAX_DIR1BUF   ;max directory buffer
;
	       CALL CHK_MINDOS		     ;check for minimum DOS
	       JNC  AMB30		     ;OK to allocate
;
	       TEST COM_STATE2,COM_BUFO      ;/B specified?
	       JZ   AMB14		     ;no, try for minimum system
;
	       CMP  COM_DFSIZE,SM_FILEBUF    ;User specified a small file buf?
	       JA   AMB_ERR		     ;no, /B just too large
;
AMB14:	       MOV  TMP_DOSWBUF,MIN_DOSWBUF  ;min work buffer
	       MOV  TMP_DIRBUF,MIN_DIR1BUF   ;min directory buffer
	       TEST COM_STATE,COM_RESS	     ;resident mode?
	       JNZ  AMB16		     ;yes, no need to adjust avail stg
;
	       ADD  BX,MAX_DOSWBUF	     ;change from 16K
	       SUB  BX,MIN_DOSWBUF	     ;	to 8K for View/Copy buffer
;
AMB16:	       CALL CHK_MINDOS		     ;check for absolutely minimum DOS
	       JNC  AMB30		     ;OK to allocate
;
AMB_ERR:       MOV  COM_ERRID,ERR_INSM	     ;insufficent memory available
	       JMP  AMBEXIT
;
; Allocate required shell memory
;
AMB30:	       XOR  AX,AX
	       MOV  AH,48H		     ;set allocate function number
	       INT  21H 		     ;allocate memory
	       JNC  AMB40		     ;check for error
;
	       MOV  COM_ERRID,ERR_INSM	     ;insufficent memory available
	       JMP  AMBEXIT
;
; Check if resident mode active and preallocate working DOS buffers
;
AMB40:	       MOV  CX,AX		     ;save beginning segment
;
	       TEST COM_STATE,COM_RESS	     ;check if resident mode is active
	       JE   AMB70		     ; if yes, pre-allocate required
					     ; memory for view, copy,,,
					     ; if not, DOS funcs in shell will
					     ; automatically allocate memory
					     ; as needed
;
	       TEST COM_STATE,COM_APPM	     ;check if app menu active
	       JNE  AMB60
;
	       MOV  COM_DATA8SEG,CX	     ;set segment of DOS work buffer
	       MOV  COM_DATA8OFF,0	     ;offset starts at zero
	       MOV  AX,TMP_DOSWBUF	     ;calculate length of buffer
	       MOV  BX,16		     ; in bytes
	       SUB  COM_DFSIZE,AX	     ;adjust remaining paragraphs
	       MUL  BX
	       MOV  COM_DATA8LEN,AX
	       ADD  CX,MAX_DOSWBUF	     ;adjust segment
	       JMP  AMB70
;
AMB60:	       MOV  AX,COM_DATA3SEG	     ;reuse app menu buffer
	       MOV  COM_DATA8SEG,AX	     ;set segment
	       MOV  AX,COM_DATA3OFF
	       MOV  COM_DATA8OFF,AX	     ;set offset
	       MOV  AX,COM_DATA3LEN	     ;set DOS working buffer size in
	       MOV  COM_DATA8LEN,AX	     ; bytes
;
; Use next available memory for dir buffer 1 and 2
;
AMB70:	       MOV  COM_DATA4SEG,CX	     ;set segment of directory list 1
	       MOV  COM_DATA4OFF,0	     ;offset starts at zero
	       MOV  AX,TMP_DIRBUF	     ;calculate length of buffer
	       ADD  CX,AX		     ;adjust new segment
	       SUB  COM_DFSIZE,AX	     ;adjust remaining paragraphs
	       MOV  BX,16
	       MUL  BX
	       MOV  COM_DATA4LEN,AX	     ;set length in paragraphs
;
	       TEST COM_STATE,COM_DRV2	     ;check if multiple drive display
	       JE   AMB80		     ; active
;
	       MOV  COM_DATA5SEG,CX	     ;set segment of directory list 2
	       MOV  COM_DATA5OFF,0	     ;offset starts at zero
	       MOV  AX,TMP_DIRBUF	     ;calculate length of buffer
	       ADD  CX,AX		     ;adjust new segment
	       SUB  COM_DFSIZE,AX	     ;adjust remaining paragraphs
	       MOV  BX,16
	       MUL  BX
	       MOV  COM_DATA5LEN,AX	     ;set length in paragraphs
;
; Use remaining memory for file buffers 1 and 2
;
AMB80:	       MOV  COM_DATA6SEG,CX	     ;set segment of file buf 1
	       MOV  COM_DATA6OFF,0	     ;offset starts at zero
;
	       MOV  AX,COM_DFSIZE	     ;get remaining buffer
;
	       TEST COM_STATE,COM_DRV2	     ;check if multiple drive display
	       JE   AMB90		     ; active
;
	       SHR  AX,1		     ;divide remaining buffer by 2
;
AMB90:	       MOV  COM_DATA6LEN,AX	     ;set file buffer 1 len in paraghs
	       ADD  CX,AX		     ;adjust new segment
	       SUB  COM_DFSIZE,AX	     ;adjust remaining buffer paraghs
;
	       TEST COM_STATE,COM_DRV2	     ;check if multiple drive display
	       JE   AMBEXIT		     ; active
;
	       MOV  COM_DATA7SEG,CX	     ;set segment of file buf 2
	       MOV  COM_DATA7OFF,0	     ;offset starts at zero
	       MOV  AX,COM_DFSIZE	     ;set # parags in file buf 2
	       MOV  COM_DATA7LEN,AX
;
AMBEXIT:				     ;exit
;
	       RET
ALLOCATE_BUFB  ENDP
;
PAGE
;
;-----------------------------------------------------------------------------+
;									      :
; Name: 		CHK_MINDOS					      :
;									      :
; Description:		Check for enough storage to run minimum DOS Services. :
;									      :
; Entry:		TMP_DOSWBUF - Size of DOS work buffer		      :
;			TMP_DIRBUF  - Size of DOS directory buffer	      :
;			COM_DFSIZE  - User specified file buffer size	      :
;			BX	    - Maximum memory available		      :
;									      :
; Exit: 		Carry flag set					      :
;									      :
; Entry point:		CHK_MINDOS					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None						      :
;									      :
; External references:	None						      :
;									      :
;-----------------------------------------------------------------------------+
;
CHK_MINDOS     PROC NEAR
;
	       XOR  AX,AX		     ;clear out
	       TEST COM_STATE,COM_RESS	     ;resident mode?
	       JZ   CHS14		     ;no, storage already adjusted
;
	       TEST COM_STATE,COM_APPM	     ;appl configured?
	       JNZ  CHS14		     ;yes, reuse appl workarea
;
	       ADD  AX,TMP_DOSWBUF	     ;10K or 8K for View/Copy buffer
;
CHS14:	       ADD  AX,TMP_DIRBUF	     ;8K or 4K for first dir buffer
	       TEST COM_STATE,COM_DRV2	     ;multiple buffers configured?
	       JZ   CHS16		     ;no, no second buffer needed
;
	       ADD  AX,TMP_DIRBUF	     ;8K or 4K for second dir buffer
;
CHS16:	       TEST COM_STATE2,COM_BUFO      ;/B specified?
	       JZ   CHS18		     ;no, add in for min file buffer
;
	       ADD  AX,COM_DFSIZE	     ;update total storage needed
	       CMP  BX,AX		     ;is storage available?
	       JA   CHS17		     ;yes
;
	       SUB  AX,COM_DFSIZE	     ;back out and use all of storage
	       JMP  CHS18		     ;continue

;	       JB   CHS_ERR		     ;no, display error message
;
CHS17:	       MOV  BX,AX		     ;set to allocate storage
	       JMP  CHS20
;
CHS18:	       ADD  AX,MIN_FILEBUF	     ;minimun file buffer to alloc
	       CMP  BX,AX		     ;is storage available
	       JB   CHS_ERR		     ;no, display error message
;
CHS20:	       MOV  COM_DFSIZE,BX	     ;set to allocate all avail storage
	       JMP  CHS_OK
;
CHS_ERR:       STC			     ;error
	       JMP  CHS_RET
;
CHS_OK:        CLC			     ;OK

CHS_RET:				     ;exit
;
	       RET
CHK_MINDOS     ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		MANAGE_ERROR					      :
;									      :
; Description:		Manage error messages.				      :
;									      :
; Entry:		COM_ERRID = ID number of error message. 	      :
;									      :
; Exit: 		None.						      :
;									      :
; Entry point:		MANAGE_ERROR					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	GET_ERROR					      :
;									      :
; External references:	INT 21H  AH=09H Print string to standard output.      :
;									      :
;-----------------------------------------------------------------------------+
;
MANAGE_ERROR   PROC NEAR
;
; Process critcal error messages before initialization is complete
;
	       CALL SET_DOSVMSHL	     ;set DOS video mode from shell
					     ; video mode
;
	       MOV  AX,COM_ERRID	     ;calculate offset into error
	       CALL FAR PTR GET_ERROR
;
	       PUSH DS			     ;save data segment address
;
	       MOV  CX,AX		     ;set message length
	       MOV  DX,DI		     ;set message offset
	       MOV  AX,ES		     ;set message segment
	       MOV  DS,AX
;
	       XOR  AX,AX		     ;clear to zero
	       MOV  AH,40H		     ;set print string function number
	       MOV  BX,1		     ;standard output
	       INT  21H 		     ;print string
;
	       MOV  AH,06		     ;print <CR> to screen
	       MOV  DL,CR
	       INT  21H
;
	       MOV  AH,06		     ;print <LF> to screen
	       MOV  DL,LF
	       INT  21H
;
	       POP  DS			     ;restore data segment address
;
	       RET
MANAGE_ERROR   ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		EXAMINE_PSP					      :
;									      :
; Description:		Examine Program Segment Prefix string for current     :
;			SHELLRD.EXE invocation parameters.		      :
;									      :
; Entry:		PSP initialized.				      :
;									      :
; Exit: 		COM_STATE   = Option word indicating invocation       :
;				      parameters passed through PSP.	      :
;									      :
;			Label	  Bit  Description			      :
;			--------  ---  -----------------------------------    :
;			COM_APPM   0   0= Application menu not configured.    :
;				       1= Application menu configured.	      :
;			COM_DOSS   1   0= DOS Services not configured.	      :
;				       1= DOS Services configured.	      :
;			COM_REFD   2   0= Do not refresh directory buffer     :
;					  during command line or PEC execution:
;				       1= Refresh directory buffer during     :
;					  command line or PEC execution.      :
;			COM_RESS   3   0= Transient shell.		      :
;				       1= Resident shell.		      :
;			COM_AUTI   4   0= Automatic predefined menu	      :
;					  installation is not active.	      :
;				       1= Automatic predefined menu	      :
;					  installation is active.	      :
;			COM_DRV2   5   0= Multiple drive buffer not active.   :
;				       1= Multiple drive buffer active.       :
;			COM_FLCL   6   0= Command line access is not active.  :
;				       1= Command line access is active.      :
;			COM_FLMI   7   0= Maintain menu item access is not    :
;					  active.			      :
;				       1= Maintain menu item access is active.:
;			COM_FLCS   8   0= Maintain color selections access is :
;					  not active.			      :
;				       1= Maintain color selections access is :
;					  active.			      :
;			COM_FLED   9   0= Exit to DOS is not active.	      :
;				       1= Exit to DOS is active.	      :
;			COM_MOUS  10   0= Mouse is not active.		      :
;				       1= Mouse is active.		      :
;			COM_LFMS  11   0= Right hand mouse.		      :
;				       1= Left hand mouse.		      :
;			COM_M10H  12   0= No function assigned. 	      :
;				       1= Graphics EGA mode 10H requested     :
;			COM_M11H  13   0= No function assigned. 	      :
;				       1= Graphics VGA/MCGA mode 11H requested:
;			COM_M12H  14   0= No function assigned. 	      :
;				       1= Graphics VGA mode 12H requested     :
;			COM_TEXT  15   0= No function assigned. 	      :
;				       1= Text mode is requested.	      :
;									      :
;			COM_STATE2  = Option word indicating invocation       :
;				      parameters passed through PSP.	      :
;									      :
;			Label	  Bit  Description			      :
;			--------  ---  -----------------------------------    :
;			COM_SOUD   0   0= Sound not active.		      :
;				       1= Sound active. 		      :
;									      :
;			COM_NLS    1   0= Not active.			      :
;				       1= NLS help index display option active:
;									      :
;			COM_DFSAV  2   0= Not active.			      :
;				       1= Directory and file save active.     :
;									      :
;			COM_BUFO   3   0= Not active.			      :
;				       1= Dir/file buffer size override on.   :
;									      :
;			COM_DBCS   4   0= Not active.			      :
;				       1= DBCS active.			      :
;									      :
;			COM_DATE   5   0= Not active.			      :
;				       1= Date/time active.		      :
;									      :
;			COM_COM2   5   0= Not active.			  D491:
;				       1= COM2 active.			  D491:
;									      :
;			COM_DFSIZE  = Size of DOS directory and file buffer   :
;				      to allocate in paragraphs.  Used only   :
;				      if buffer override option is active     :
;				      in COM_STATE2.			      :
;									      :
;			COM_PSPOFF  = Offset of SHELL.EXE PSP		      :
;			COM_PSPSEG  = Segment of SHELL.EXE PSP		      :
;									      :
; Entry point:		EXAMINE_PSP					      :
;									      :
; Notes:		EXAMINE_PSP is beginning overlay point for mouse      :
;			driver. 					      :
;									      :
; Internal references:	MANAGE_ERROR					      :
;			PCINSTR_CALL					      :
;									      :
; External references:	INT 21H  19H Return current drive		      :
;			INT 21H  47H Return current path		      :
;									      :
;-----------------------------------------------------------------------------+
;
EXAMINE_PSP    PROC NEAR
;
; Intialize to search PSP for invocation options
;
	       MOV  INS_OPT,0		     ;set to find string
	       MOV  ES, COM_PSPSEG	     ;get PSP segment
	       MOV  DI, 80H		     ;get offset of PSP length byte
	       MOV  CL, ES:[DI] 	     ;get PSP length byte
	       CMP  CL, 0		     ;any command line options?
	       JA   EP03		     ;yes, continue
	       MOV  COM_ERRID,ERR_PSP	     ;invalid psp command line
	       JMP  EPEXIT		     ;exit
EP03:	       XOR  CH, CH		     ;clear high byte
	       MOV  SI, COM_PSPOFF	     ;set offset of PSP
	       ADD  SI, 81H		     ;get command line buffer
	       LEA  DI, EP_CMDLIN	     ;set offset of command line buffer
	       MOV  INS_SOFF, DI	     ;save offset of command buffer
	       MOV  INS_SSEG, DATA	     ;save segment of command buffer
	       MOV  ES, INS_SSEG	     ;set segment of command buffer
	       mov  dl, 0		     ;init comment flag
	       mov  ins_slen, 0 	     ;init length of command search str
	       mov  com_cmdact, 0	     ;init actual length of commands
	       mov  com_cmdnum, 0	     ;init length of commands found
;
EP034:	       PUSH DS			     ;save data seg
	       MOV  DS, COM_PSPSEG	     ;PSP segment is source seg
	       mov  al, ds:[si] 	     ;
	       POP  DS			     ;
;
	       cmp  al, ' '                  ;
	       jbe  ep039		     ;
;
	       cmp  al, '{'                  ;
	       jne  ep037		     ;
	       mov  dl, 1		     ;
	       jmp  ep039		     ;
;
EP037:	       cmp  al, '}'                  ;
	       jne  ep038		     ;
	       mov  dl, 0		     ;
	       jmp  ep039		     ;
;
EP038:	       cmp  dl, 1		     ;
	       je   ep039		     ;
;
	       cmp  al, 'a'                  ;
	       jb   ep0385		     ;
	       cmp  al, 'z'                  ;
	       ja   ep0385		     ;
	       sub  al, 32		     ;
;
ep0385:        mov  es:[di], al 	     ;
	       inc  ins_slen		     ;
	       inc  com_cmdact		     ;
	       inc  di			     ;
;
ep039:	       inc  si			     ;
	       loop ep034		     ;
;
	       MOV  EP_ENDOFF, DI	     ;set offset of last byte in buffer
;
; Check for profile filename /PRO:filename.PRO
;
EP1900:        XOR  AX,AX		     ;get current drive
	       MOV  AH,19H
	       INT  21H
	       ADD  AL,65		     ;convert from # to alpha char
	       MOV  COM_RFILSPEC,AL	     ;complete current drive and path
;
	       MOV  AH,47H		     ;read current path
	       MOV  DL,0
	       LEA  SI,COM_RFILSPEC+3	     ;point past C:\
	       INT  21H
	       JNC  EP1910		     ;check for error
;
	       MOV  COM_ERRID,ERR_BADD	     ;bad disk or drive door open
	       JMP  EPEXIT
;
EP1910:        MOV  AX,STR_PROFACT	     ;profile active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0		     ;check if not found, error
	       JG   EP1920
;
	       JMP  EP05		     ;profile not active get next var
;
EP1920:        ADD  COM_CMDNUM,AX
;
	       PUSH INS_FOFF		     ;save invocation parameter offset
;
	       MOV  CX,INS_RSLT 	     ;save starting search point
	       ADD  CX,INS_FLEN 	     ;point past /PRO: to beginning of
					     ; profile file name
;
	       MOV  AX,STR_PROEXT	     ;profile extension
	       CALL FAR PTR GET_STRING
;
	       MOV  INS_FLEN,AX 	     ;length of find string
	       MOV  INS_FOFF,DI 	     ;offset of find string '.PRO'
	       MOV  INS_FSEG,ES 	     ;segment of string
	       CALL PCINSTR_CALL	     ;search for string
;
	       POP  INS_FOFF		     ;restore before exit
;
	       CMP  INS_RSLT,0
	       JG   EP1930
;
	       MOV  COM_ERRID,ERR_MOUS	     ;invalid profile file
	       JMP  EPEXIT
;
EP1930:        PUSH SI
	       PUSH DS
;
	       MOV  AX,INS_RSLT
	       SUB  AX,CX		     ;ending offset - starting offset
	       ADD  AX,INS_FLEN 	     ; + length of extension = # bytes
					     ; to move
	       ADD  COM_CMDNUM,AX	     ;
	       MOV  BX,INS_SOFF 	     ;calculate offset of source strg
	       ADD  BX,CX		     ; to move
	       DEC  BX
;
	       PUSH BX			     ;save source offset
	       PUSH INS_SSEG		     ;save source segment
;
	       MOV  CX,AX		     ; = number of bytes to move
	       LEA  DI,COM_RFILSPEC	     ;get dest offset
;
	       PUSH DS
	       PUSH ES
	       POP  DS
	       POP  ES
;
EP1940:        MOV  AL,ES:[DI]		     ;locate end of drive and path
	       CMP  AL,0		     ; in shell profile name buffer
	       JE   EP1980
;
	       INC  DI			     ;point to next character
	       JMP  EP1940
;
EP1980:        CMP  BYTE PTR ES:[DI-1],'\'   ;check if root and skip add of
	       JE   EP1990		     ; file separator
;
	       MOV  BYTE PTR ES:[DI],'\'     ;add path and filename separator
	       INC  DI			     ;point to where filename goes
;
EP1990:        POP  DS			     ;now move profile filename string
	       POP  SI			     ; to end of profile buffer path
;
	       REP  MOVSB		     ;copy profile filespec
;
	       POP  DS
	       POP  SI
;
; Open profile file
;
	       MOV  AH, 3DH		     ;DOS open handle
	       MOV  AL, 010B		     ;open for read/write
	       LEA  DX, COM_RFILSPEC	     ;set offset of profile filename
	       INT  21H 		     ;open profile file
	       JNC  EP_1992		     ;continue if no error
	       MOV  COM_ERRID,ERR_MOUS	     ;bad disk or drive door open
	       JMP  EPEXIT
;
; Read profile file to command buffer	     ;
;
ep_1992:       mov  dl, 0
	       mov  di, ep_endoff
	       MOV  BX, AX		     ;set file handle
;
ep_1993:       push dx
	       MOV  AH, 3FH		     ;DOS read handle
	       mov  cx, 1
	       lea  dx, gen_data
	       INT  21H 		     ;read profile into buffer
	       JNC  EP_1994		     ;continue if no error
	       pop  dx
	       MOV  COM_ERRID,ERR_MOUS	     ;bad disk or drive door open
	       JMP  EPEXIT

EP_1994:  ;    ADD  INS_SLEN, AX	     ;


epx034:
	       cmp  ax, 0		     ;
	       ja   epx035
;
	       pop  dx
	       jmp  ep1995
;
epx035:        pop  dx
;
	       mov  al, byte ptr gen_data    ;
;
	       cmp  al, ' '                  ;
	       jbe  epx039		     ;
;
	       cmp  al, '{'                  ;
	       jne  epx037		     ;
	       mov  dl, 1		     ;
	       jmp  epx039		     ;
;
epx037:        cmp  al, '}'                  ;
	       jne  epx038		     ;
	       mov  dl, 0		     ;
	       jmp  epx039		     ;
;
epx038:        cmp  dl, 1		     ;
	       je   epx039		     ;
;
	       cmp  al, 'a'                  ;
	       jb   epx0385		     ;
	       cmp  al, 'z'                  ;
	       ja   epx0385		     ;
	       sub  al, 32		     ;
;
epx0385:       mov  [di], al		     ;
	       inc  ins_slen		     ;
	       inc  com_cmdact		     ;
	       inc  di			     ;
;
epx039:        jmp  ep_1993		     ;
;
; Close profile handle
;
EP1995:        MOV  AH, 3EH		     ;
	       INT  21H 		     ;close handle
	       JNC  EP05		     ;continue if no error
	       MOV  COM_ERRID,ERR_MOUS	     ;bad disk or drive door open
	       JMP  EPEXIT
;
; Convert command string alpha to upper case
;
EP05:	       MOV  ES,INS_SSEG 	     ;get PSP command line segment
	       MOV  DI,INS_SOFF 	     ;point to PSP command line string
	       MOV  CX,INS_SLEN 	     ;get length of PSP
;
	       MOV  COM_STATE, 0	     ;
	       MOV  COM_STATE2,0	     ;initialize to zero
;
	       MOV  AX,STR_CDON 	     ;
	       CALL CHECK_STRING	     ;
	       CMP  INS_RSLT,0		     ;
	       JE   EP2510		     ;
	       ADD  COM_CMDNUM,AX	     ;
	       OR   COM_CONFIRM, COM_CONFDEL ;
ep2510:
	       MOV  AX,STR_CDOFF	     ;
	       CALL CHECK_STRING	     ;
	       CMP  INS_RSLT,0		     ;
	       JE   EP2511		     ;
	       ADD  COM_CMDNUM,AX	     ;
	       AND  COM_CONFIRM,NOT COM_CONFDEL
ep2511:
	       MOV  AX,STR_CRON 	     ;
	       CALL CHECK_STRING	     ;
	       CMP  INS_RSLT,0		     ;
	       JE   EP2520		     ;
	       ADD  COM_CMDNUM,AX	     ;
	       OR   COM_CONFIRM, COM_CONFREPL;
ep2520:
	       MOV  AX,STR_CROFF	     ;
	       CALL CHECK_STRING	     ;
	       CMP  INS_RSLT,0		     ;
	       JE   EP2521		     ;
	       ADD  COM_CMDNUM,AX	     ;
	       AND  COM_CONFIRM,NOT COM_CONFREPL
ep2521:
	       MOV  AX,STR_ASON 	     ;
	       CALL CHECK_STRING	     ;
	       CMP  INS_RSLT,0		     ;
	       JE   EP2530		     ;
	       ADD  COM_CMDNUM,AX	     ;
	       OR   COM_CONFIRM, COM_ALLOWSEL;
ep2530:
	       MOV  AX,STR_ASOFF	     ;
	       CALL CHECK_STRING	     ;
	       CMP  INS_RSLT,0		     ;
	       JE   EP2540		     ;
	       ADD  COM_CMDNUM,AX	     ;
	       AND  COM_CONFIRM,NOT COM_ALLOWSEL
ep2540:
	       MOV  AX,STR_SBNAME	     ;
	       CALL CHECK_STRING	     ;
	       CMP  INS_RSLT,0		     ;
	       JE   EP2550		     ;
	       ADD  COM_CMDNUM,AX	     ;
	       MOV  SORTSTAT, SST_NAME	     ;
	       JMP  EP2590
ep2550:
	       MOV  AX,STR_SBEXT	     ;
	       CALL CHECK_STRING	     ;
	       CMP  INS_RSLT,0		     ;
	       JE   EP2560		     ;
	       ADD  COM_CMDNUM,AX	     ;
	       MOV  SORTSTAT, SST_EXT	     ;
	       JMP  EP2590
ep2560:
	       MOV  AX,STR_SBSIZE	     ;
	       CALL CHECK_STRING	     ;
	       CMP  INS_RSLT,0		     ;
	       JE   EP2570		     ;
	       ADD  COM_CMDNUM,AX	     ;
	       MOV  SORTSTAT, SST_SIZE	     ;
	       JMP  EP2590
ep2570:
	       MOV  AX,STR_SBDATE	     ;
	       CALL CHECK_STRING	     ;
	       CMP  INS_RSLT,0		     ;
	       JE   EP2580		     ;
	       ADD  COM_CMDNUM,AX	     ;
	       MOV  SORTSTAT, SST_DATE	     ;
	       JMP  EP2590
ep2580:
	       MOV  AX,STR_SBDISK	     ;
	       CALL CHECK_STRING	     ;
	       CMP  INS_RSLT,0		     ;
	       JE   EP2590		     ;
	       ADD  COM_CMDNUM,AX	     ;
	       MOV  SORTSTAT, 0 	     ;
ep2590:
;
; Check for NLS translation option for help index display
;
	       MOV  AX,STR_NLS		     ;NLS configured
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP25
;
	       ADD  COM_CMDNUM,AX	     ;add length to found length
	       OR   COM_STATE2,COM_NLS	     ;app menu configured
;
; Check for application menu option
;
EP25:	       MOV  AX,STR_APPMENU	     ;app menu configured
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP30
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_APPM	     ;app menu configured
;
; Check for DOS Services option
;
EP30:	       MOV  AX,STR_DOSSERV	     ;DOS services configured
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP50
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_DOSS	     ;DOS services configured
;
; Check for transient mode operation
;
EP50:	       MOV  AX,STR_TRANS	     ;transient shell configured
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JNE  EP51
;
	       OR   COM_STATE,COM_RESS	     ;resident shell configured
	       JMP  EP60
;
EP51:	       ADD  COM_CMDNUM,AX
;
; Check for hi-res graphics mode operation = Mode 10
;
EP60:	       MOV  AX,STR_MODE10H	     ;graphics mode 10H
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP62
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_M10H	     ;activate graphics mode flag
	       JMP  EP74
;
; Check for hi-res graphics mode operation = Mode 11
;
EP62:	       MOV  AX,STR_MODE11H	     ;graphics mode 11H
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP64
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_M11H	     ;activate graphics mode flag
	       JMP  EP74
;
; Check for hi-res graphics mode operation = Mode 12
;
EP64:	       MOV  AX,STR_MODE12H	     ;graphics mode 12H
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP65
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_M12H	     ;activate graphics mode flag
	       JMP  EP74
;
; Check for text mode operation = Mode 7 or 3
;
EP65:	       MOV  AX,STR_TEXTS	     ;graphics mode 12H
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP66
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_TEXT	     ;activate text mode flag
	       JMP  EP74
;
; User did not set desired video mode, default to highest available
;
EP66:	       CMP  GE_MODEL,MODEL_30	     ;check if model 25 and 30
	       JNE  EP68
;
	       CMP  GE_SUBMODEL,SUBMD_30
	       JE   EP67
;
	       CMP  GE_SUBMODEL,SUBMD_25
	       JNE  EP68
;
EP67:	       OR   COM_STATE,COM_M11H	     ;default to mode 11H
	       JMP  EP74
;
; Check for VGA video
;
EP68:	       MOV  AX,1A00H		     ;BIOS check display
	       INT  10H 		     ;
	       CMP  AL,1AH		     ;VGA supported?
	       JNE  EP686		     ;no, continue
;
; VGA video, check for INFOWINDOW display
;
	       CMP  BL, 4		     ;infowindow display?
	       JNE  EP685		     ;no, continue
;
	       OR   COM_STATE, COM_M10H      ;mode for VGA with infowindow
	       JMP  EP74		     ;continue
;
; VGA video, non-INFOWINDOW, set highest available mode
;
EP685:	       MOV  AH, 1BH
	       MOV  BX, 0
	       PUSH DS
	       POP  ES
	       LEA  DI, GEN_DATA
	       INT  10H
	       PUSH ES:[DI]
	       PUSH ES:[DI+2]
	       POP  ES
	       POP  DI
;
	       TEST BYTE PTR ES:[DI+2], 00000100B
	       JZ   EP6851
	       OR   COM_STATE, COM_M12H
	       JMP  EP74
EP6851:        TEST BYTE PTR ES:[DI+2], 00000010B
	       JZ   EP6852
	       OR   COM_STATE, COM_M11H
	       JMP  EP74
EP6852:        TEST BYTE PTR ES:[DI+2], 00000001B
	       JZ   EP6853
	       OR   COM_STATE, COM_M10H
	       JMP  EP74
EP6853:        OR   COM_STATE, COM_TEXT
	       JMP  EP74
;
; Check for EGA video
;
EP686:	       MOV  AH,12H		     ;BIOS alternate select
	       MOV  BL,10H		     ;return EGA info
	       INT  10H 		     ;
	       CMP  BL,10H		     ;EGA video?
	       JNE  EP687		     ;yes, continue
;
; CGA or Monochrome video
;
	       OR   COM_STATE,COM_TEXT	     ;text mode operation
	       JMP  EP74		     ;continue
;
; EGA video, check for sufficient memory for mode 10
;
EP687:	       CMP  BL,3H		     ;256K available?
	       JAE  EP688		     ;yes, continue
;
	       OR   COM_STATE,COM_TEXT	     ;ega has no memory for mode 10
	       JMP  EP74		     ;continue
;
; EGA with 256K, check for cga or monochrome emulation
;
EP688:	       AND  CL,1111B		     ;save registers
	       CMP  CL,9
	       JE   EP689
;
; EGA emulating CGA or Monochrome
;
	       OR   COM_STATE,COM_TEXT
	       JMP  EP74
;
; EGA in EGA mode
;
EP689:	       OR   COM_STATE,COM_M10H
;
; Check for application main menu filename
;
EP74:	       TEST COM_STATE,COM_APPM	     ;if app menu not configured do not
	       JNE  EP75		     ; search for app main menu filespc
;
	       MOV  AX,STR_APMFILE	     ;app main menu filename
	       CALL CHECK_STRING	     ;search for string
	       CALL PCINSTR_CALL
	       CMP  INS_RSLT,0		     ;check if parameter found
	       JG   EP75
;
	       JMP  EP112		     ;check next parameter
;
EP75:	       XOR  AX,AX		     ;get current drive
	       MOV  AH,19H
	       INT  21H
	       ADD  AL,65		     ;convert from # to alpha char
	       MOV  APP_MFILSPEC,AL	     ;complete current drive and path
;
	       MOV  AH,47H		     ;read current path
	       MOV  DL,0
	       LEA  SI,APP_MFILSPEC+3	     ;point past C:\
	       INT  21H
	       JNC  EP78		     ;check for error
;
	       MOV  COM_ERRID,ERR_BADD	     ;bad disk or drive door open
	       JMP  EPEXIT
;
EP78:	       MOV  AX,STR_APMFILE	     ;app main menu filename
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JG   EP80
;
	       MOV  AX,STR_APPMFILE	     ;default app menu filename
	       CALL FAR PTR GET_STRING	     ;user did not supply new app menu
;
	       PUSH SI			     ;save data segment
	       PUSH DS
;
	       PUSH DI			     ;save filename offset
	       PUSH ES			     ;save filename segment
;
	       JMP  EP92		     ; SHELL.MEU file instead
;
EP80:	       PUSH INS_FOFF		     ;save invocation parameter offset
	       ADD  COM_CMDNUM,AX
;
	       MOV  CX,INS_RSLT 	     ;save starting search point
	       ADD  CX,INS_FLEN 	     ;point past /MEU: to beginning of
					     ; menu file name
	       MOV  AX,STR_AAPEXT	     ;main application menu extension
	       CALL FAR PTR GET_STRING
;
	       MOV  INS_FLEN,AX 	     ;length of string
	       MOV  INS_FOFF,DI 	     ;offset of string '.MEU'
	       MOV  INS_FSEG,ES 	     ;segment of string
	       CALL PCINSTR_CALL	     ;search for string
;
	       POP  INS_FOFF
;
	       CMP  INS_RSLT,0
	       JG   EP90
;
	       MOV  COM_ERRID,ERR_APIF	     ;invalid main app menu filename
	       JMP  EPEXIT
;
EP90:	       PUSH SI			     ;save data segment
	       PUSH DS
;
	       MOV  AX,INS_RSLT
	       SUB  AX,CX		     ;ending offset - starting offset
	       ADD  AX,INS_FLEN 	     ; + length of extension = # bytes
					     ; to move
	       ADD  COM_CMDNUM,AX
;
	       MOV  BX,INS_SOFF 	     ;calculate offset of source strg
	       ADD  BX,CX		     ; to move
	       DEC  BX
;
	       PUSH BX			     ;save source offset
	       PUSH INS_SSEG		     ;save source segment
;
EP92:	       MOV  CX,AX		     ; = number of bytes to move
	       LEA  DI,APP_MFILSPEC	     ;get dest offset
;
	       PUSH DS
	       PUSH ES
	       POP  DS
	       POP  ES
;
EP94:	       MOV  AL,ES:[DI]		     ;locate end of drive and path
	       CMP  AL,0		     ; in shell app menu file buffer
	       JE   EP98
;
	       INC  DI			     ;point to next character
	       JMP  EP94
;
EP98:	       CMP  BYTE PTR ES:[DI-1],'\'   ;check if root and skip add of
	       JE   EP99		     ; file separator
;
	       MOV  BYTE PTR ES:[DI],'\'     ;add path and filename separator
	       INC  DI			     ;point to where filename goes
;
EP99:	       POP  DS			     ;now move shell menu filename to
	       POP  SI			     ; end of app menu file path
;
	       REP  MOVSB		     ;copy application menu filespec
;
	       POP  DS
	       POP  SI
;
; Move copy of menu filename to first menu buffer
;
EP100:	       MOV  AX,STR_APMFILE	     ;app main menu filename
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JG   EP103
;
	       MOV  AX,STR_APPMFILE	     ;default app menu filename
	       CALL FAR PTR GET_STRING	     ;user did not supply new app menu
;
	       PUSH SI			     ;save data segment
	       PUSH DS
;
	       PUSH DI			     ;save filename offset
	       PUSH ES			     ;save filename segment
;
	       JMP  EP105		     ; SHELL.MEU file instead
;
EP103:	       PUSH INS_FOFF		     ;save invocation parameter offset
;
	       MOV  CX,INS_RSLT 	     ;save starting search point
	       ADD  CX,INS_FLEN 	     ;point past /MEU: to beginning of
					     ; menu file name
	       MOV  AX,STR_AAPEXT	     ;main application menu extension
	       CALL FAR PTR GET_STRING
;
	       MOV  INS_FLEN,AX 	     ;length of string
	       MOV  INS_FOFF,DI 	     ;offset of string '.MEU'
	       MOV  INS_FSEG,ES 	     ;segment of string
	       CALL PCINSTR_CALL	     ;search for string
;
	       POP  INS_FOFF
;
	       CMP  INS_RSLT,0
	       JG   EP104
;
	       MOV  COM_ERRID,ERR_APIF	     ;invalid main app menu filename
	       JMP  EPEXIT
;
EP104:	       PUSH SI			     ;save data segment
	       PUSH DS
;
	       MOV  AX,INS_RSLT
	       SUB  AX,CX		     ;ending offset - starting offset
	       ADD  AX,INS_FLEN 	     ; + length of extension = # bytes
					     ; to move
;
	       MOV  BX,INS_SOFF 	     ;calculate offset of source strg
	       ADD  BX,CX		     ; to move
	       DEC  BX
;
	       PUSH BX			     ;save source offset
	       PUSH INS_SSEG		     ;save source segment
;
EP105:	       MOV  CX,AX		     ; = number of bytes to move
	       LEA  DI,APP_MFILNAME	     ;get dest offset
;
	       PUSH DS
	       PUSH ES
	       POP  DS
	       POP  ES
;
EP108:	       POP  DS			     ;now move shell menu filename to
	       POP  SI			     ; end of app menu file path
;
	       REP  MOVSB		     ;copy application menu filespec
;
	       POP  DS
	       POP  SI
;
; Check for color filename
;
EP112:	       XOR  AX,AX		     ;get current drive
	       MOV  AH,19H
	       INT  21H
	       ADD  AL,65		     ;convert from # to alpha char
	       MOV  COM_CFILSPEC,AL	     ;complete current drive and path
;
	       MOV  AH,47H		     ;read current path
	       MOV  DL,0
	       LEA  SI,COM_CFILSPEC+3	     ;point past C:\
	       INT  21H
	       JNC  EP115		     ;check for error
;
	       MOV  COM_ERRID,ERR_BADD	     ;bad disk or drive door open
	       JMP  EPEXIT
;
EP115:	       MOV  AX,STR_CLFILE	     ;color filename
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0		     ;check if not found, error
	       JG   EP118
;
	       MOV  AX,STR_CLRFILE	     ;default color filename
	       CALL FAR PTR GET_STRING	     ;user did not supply new app menu
;
	       PUSH SI			     ;save data segment
	       PUSH DS
;
	       PUSH DI			     ;save offset of filename
	       PUSH ES			     ;save segment of filename
;
	       JMP  EP122		     ; SHELL.CLR file
;
EP118:	       PUSH INS_FOFF		     ;save invocation parameter offset
	       ADD  COM_CMDNUM,AX
;
	       MOV  CX,INS_RSLT 	     ;save starting search point
	       ADD  CX,INS_FLEN 	     ;point past /K: to beginning of
					     ; color file name
;
	       MOV  AX,STR_CLREXT	     ;color profile extension
	       CALL FAR PTR GET_STRING
;
	       MOV  INS_FLEN,AX 	     ;length of find string
	       MOV  INS_FOFF,DI 	     ;offset of find string '.CLR'
	       MOV  INS_FSEG,ES 	     ;segment of string
	       CALL PCINSTR_CALL	     ;search for string
;
	       POP  INS_FOFF		     ;restore before exit
;
	       CMP  INS_RSLT,0
	       JG   EP120
;
	       MOV  COM_ERRID,ERR_CLRF	     ;invalid user color profile
	       JMP  EPEXIT
;
EP120:	       PUSH SI
	       PUSH DS
;
	       MOV  AX,INS_RSLT
	       SUB  AX,CX		     ;ending offset - starting offset
	       ADD  AX,INS_FLEN 	     ; + length of extension = # bytes
					     ; to move
	       ADD  COM_CMDNUM,AX
	       MOV  BX,INS_SOFF 	     ;calculate offset of source strg
	       ADD  BX,CX		     ; to move
	       DEC  BX
;
	       PUSH BX			     ;save source offset
	       PUSH INS_SSEG		     ;save source segment
;
EP122:	       MOV  CX,AX		     ; = number of bytes to move
	       LEA  DI,COM_CFILSPEC	     ;get dest offset
;
	       PUSH DS
	       PUSH ES
	       POP  DS
	       POP  ES
;
EP124:	       MOV  AL,ES:[DI]		     ;locate end of drive and path
	       CMP  AL,0		     ; in shell color file buffer
	       JE   EP128
;
	       INC  DI			     ;point to next character
	       JMP  EP124
;
EP128:	       CMP  BYTE PTR ES:[DI-1],'\'   ;check if root and skip add of
	       JE   EP129		     ; file separator
;
	       MOV  BYTE PTR ES:[DI],'\'     ;add path and filename separator
	       INC  DI			     ;point to where filename goes
;
EP129:	       POP  DS			     ;now move color filename string
	       POP  SI			     ; to end of color buffer path
;
	       REP  MOVSB		     ;copy color index filespec
;
	       POP  DS
	       POP  SI
;
; Check for multiple DOS Service drive buffers
;
EP130:	       MOV  AX,STR_MULTIPE	     ;multiple drive display
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP140
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_DRV2
;
; Check for active maintain color option
;
EP140:	       MOV  AX,STR_CLRACT	     ;color active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0		     ;
	       JE   EP150		     ;
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_FLCS	     ;maintain color is active
;
; Check for active maintain menu option
;
EP150:	       MOV  AX,STR_MENUACT	     ;menu maintainance active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP160
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_FLMI	     ;maintain menu is active
;
; Check for active exit to DOS option
;
EP160:	       AND  FLAG_FSEXIT, NOT DIT_L1  ;turn exit to DOS dither off start
	       AND  FLAG_FDEXIT, NOT DIT_L1  ;turn exit file system dither off
;
	       MOV  AX,STR_EXITDOS	     ;exit to DOS active
	       CALL CHECK_STRING	     ;search for string
;
	       OR   FLAG_FSEXIT, DIT_L1      ;turn exit to DOS dither on start
;
	       TEST COM_STATE,COM_APPM	     ;app menu configured
	       JNZ  EP161		     ;
;
	       OR   FLAG_FDEXIT, DIT_L1      ;turn exit from file system dither
					     ; on
;
EP161:	       CMP  INS_RSLT,0
	       JE   EP170
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_FLED	     ;exit to DOS is active
;
	       AND  FLAG_FSEXIT, NOT DIT_L1  ;turn exit to DOS dither off start
	       AND  FLAG_FDEXIT, NOT DIT_L1  ;turn exit file system dither off
;
; Check for active command line option
;
EP170:	       MOV  AX,STR_CMDLINE	     ;command line active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP180
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_FLCL	     ;command line is active
;
; Check for predefined menu installation option
;
EP180:	       MOV  AX,STR_PREDACT	     ;predefined menu active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP190
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_AUTI	     ;predefined is active
;
; Check for mouse filename /MOS:filename.MOS
;
EP190:	       XOR  AX,AX		     ;get current drive
	       MOV  AH,19H
	       INT  21H
	       ADD  AL,65		     ;convert from # to alpha char
	       MOV  COM_VFILSPEC,AL	     ;complete current drive and path
;
	       MOV  AH,47H		     ;read current path
	       MOV  DL,0
	       LEA  SI,COM_VFILSPEC+3	     ;point past C:\
	       INT  21H
	       JNC  EP191		     ;check for error
;
	       MOV  COM_ERRID,ERR_BADD	     ;bad disk or drive door open
	       JMP  EPEXIT
;
EP191:	       MOV  AX,STR_MOUSACT	     ;mouse active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0		     ;check if not found, error
	       JG   EP192
;
	       JMP  EP200		     ;mouse is not active get next var
;
EP192:	       OR   COM_STATE,COM_MOUS	     ;mouse is active
	       ADD  COM_CMDNUM,AX
;
	       PUSH INS_FOFF		     ;save invocation parameter offset
;
	       MOV  CX,INS_RSLT 	     ;save starting search point
	       ADD  CX,INS_FLEN 	     ;point past /MOS: to beginning of
					     ; mouse file name
;
	       MOV  AX,STR_MOSEXT	     ;mouse extension
	       CALL FAR PTR GET_STRING
;
	       MOV  INS_FLEN,AX 	     ;length of find string
	       MOV  INS_FOFF,DI 	     ;offset of find string '.MOS'
	       MOV  INS_FSEG,ES 	     ;segment of string
	       CALL PCINSTR_CALL	     ;search for string
;
	       POP  INS_FOFF		     ;restore before exit
;
	       CMP  INS_RSLT,0
	       JG   EP193
;
	       MOV  COM_ERRID,ERR_MOUS	     ;invalid mouse driver
	       JMP  EPEXIT
;
EP193:	       PUSH SI
	       PUSH DS
;
	       MOV  AX,INS_RSLT
	       SUB  AX,CX		     ;ending offset - starting offset
	       ADD  AX,INS_FLEN 	     ; + length of extension = # bytes
					     ; to move
	       ADD  COM_CMDNUM,AX
	       MOV  BX,INS_SOFF 	     ;calculate offset of source strg
	       ADD  BX,CX		     ; to move
	       DEC  BX
;
	       PUSH BX			     ;save source offset
	       PUSH INS_SSEG		     ;save source segment
;
	       MOV  CX,AX		     ; = number of bytes to move
	       LEA  DI,COM_VFILSPEC	     ;get dest offset
;
	       PUSH DS
	       PUSH ES
	       POP  DS
	       POP  ES
;
EP194:	       MOV  AL,ES:[DI]		     ;locate end of drive and path
	       CMP  AL,0		     ; in shell mouse file buffer
	       JE   EP198
;
	       INC  DI			     ;point to next character
	       JMP  EP194
;
EP198:	       CMP  BYTE PTR ES:[DI-1],'\'   ;check if root and skip add of
	       JE   EP199		     ; file separator
;
	       MOV  BYTE PTR ES:[DI],'\'     ;add path and filename separator
	       INC  DI			     ;point to where filename goes
;
EP199:	       POP  DS			     ;now move mouse filename string
	       POP  SI			     ; to end of mouse buffer path
;
	       REP  MOVSB		     ;copy mouse index filespec
;
	       POP  DS
	       POP  SI
;
; Check for left hand mouse option
;
EP200:	       MOV  AX,STR_LEFTACT	     ;left hand mouse
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP205
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE,COM_LFMS	     ;left hand mouse
;
; Check for sound active option
;
EP205:	       MOV  AX,STR_SOUDACT	     ;sound active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP207
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE2,COM_SOUD      ;sound active
;
; Check for dir/file buffer save option
;
EP207:	       MOV  AX,STR_DFSAVE	     ;check if option active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP210
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE2,COM_DFSAVE    ;dir/file buffer save option
					     ; active
;
; Save filespec of shell.hlp at COM_HFILSPEC
;
EP210:	       XOR  AX,AX		     ;get current drive
	       MOV  AH,19H
	       INT  21H
	       ADD  AL,65		     ;convert from # to alpha char
	       MOV  COM_HFILSPEC,AL	     ;complete current drive and path
;
	       MOV  AH,47H		     ;read current path
	       MOV  DL,0
	       LEA  SI,COM_HFILSPEC+3	     ;point past C:\
	       INT  21H
	       JNC  EP250
;
	       MOV  COM_ERRID,ERR_BADD	     ;bad disk or drive door open
	       JMP  EPEXIT
;
EP250:	       LEA  DI,COM_HFILSPEC	     ;get dest offset
;
	       MOV  AX,DS
	       MOV  ES,AX
;
EP260:	       MOV  AL,ES:[DI]		     ;locate end of drive and path
	       CMP  AL,0		     ; in shell help file buffer
	       JE   EP270
;
	       INC  DI			     ;point to next character
	       JMP  EP260
;
EP270:	       CMP  BYTE PTR ES:[DI-1],'\'   ;check if root and skip add of
	       JE   EP275		     ; file separator
;
	       MOV  BYTE PTR ES:[DI],'\'     ;add path and filename separator
	       INC  DI			     ;point to where filename goes
;
EP275:	       PUSH DS			     ;save register
;
	       PUSH DI
	       MOV  AX,STR_HLPFILE	     ;default help text filename
	       CALL FAR PTR GET_STRING
	       MOV  SI,DI		     ;get offset of SHELL.HLP
	       MOV  CX,AX		     ;get length
	       POP  DI
;
	       PUSH ES			     ;set source segment
	       POP  DS
;
	       REP  MOVSB
;
	       POP  DS			     ;restore
;
; Check for associate filename /ASC:filename.ASC
;
EP300:	       XOR  AX,AX		     ;get current drive
	       MOV  AH,19H
	       INT  21H
	       ADD  AL,65		     ;convert from # to alpha char
	       MOV  COM_AFILSPEC,AL	     ;complete current drive and path
;
	       MOV  AH,47H		     ;read current path
	       MOV  DL,0
	       LEA  SI,COM_AFILSPEC+3	     ;point past C:\
	       INT  21H
	       JNC  EP315		     ;check for error
;
	       MOV  COM_ERRID,ERR_BADD	     ;bad disk or drive door open
	       JMP  EPEXIT
;
EP315:	       MOV  AX,STR_ASOFILE	     ;associate filename /ASO
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0		     ;check if not found, error
	       JG   EP318
;
	       MOV  AX,STR_ASCEXT	     ;default associate filename
	       CALL FAR PTR GET_STRING	     ;user did not supply new app menu
;
	       PUSH SI			     ;save data segment
	       PUSH DS
;
	       PUSH DI			     ;save offset of filename
	       PUSH ES			     ;save segment of filename
;
	       JMP  EP322		     ; SHELL.ASO file
;
EP318:	       PUSH INS_FOFF		     ;save invocation parameter offset
	       ADD  COM_CMDNUM,AX
;
	       MOV  CX,INS_RSLT 	     ;save starting search point
	       ADD  CX,INS_FLEN 	     ;point past /ASO: to beginning of
					     ;	associate file name
;
	       MOV  AX,STR_ASOEXT	     ;assoicate profile extension
	       CALL FAR PTR GET_STRING
;
	       MOV  INS_FLEN,AX 	     ;length of find string
	       MOV  INS_FOFF,DI 	     ;offset of find string '.ASO'
	       MOV  INS_FSEG,ES 	     ;segment of string
	       CALL PCINSTR_CALL	     ;search for string
;
	       POP  INS_FOFF		     ;restore before exit
;
	       CMP  INS_RSLT,0
	       JG   EP320
;
	       MOV  COM_ERRID,ERR_ASRF	     ;invalid user associate profile
	       JMP  EPEXIT
;
EP320:	       PUSH SI
	       PUSH DS
;
	       MOV  AX,INS_RSLT
	       SUB  AX,CX		     ;ending offset - starting offset
	       ADD  AX,INS_FLEN 	     ; + length of extension = # bytes
					     ; to move
	       ADD  COM_CMDNUM,AX
	       MOV  BX,INS_SOFF 	     ;calculate offset of source strg
	       ADD  BX,CX		     ; to move
	       DEC  BX
;
	       PUSH BX			     ;save source offset
	       PUSH INS_SSEG		     ;save source segment
;
EP322:	       MOV  CX,AX		     ; = number of bytes to move
	       LEA  DI,COM_AFILSPEC	     ;get dest offset
;
	       PUSH DS
	       PUSH ES
	       POP  DS
	       POP  ES
;
EP324:	       MOV  AL,ES:[DI]		     ;locate end of drive and path
	       CMP  AL,0		     ; in shell associate file buffer
	       JE   EP328
;
	       INC  DI			     ;point to next character
	       JMP  EP324
;
EP328:	       CMP  BYTE PTR ES:[DI-1],'\'   ;check if root and skip add of
	       JE   EP329		     ; file separator
;
	       MOV  BYTE PTR ES:[DI],'\'     ;add path and filename separator
	       INC  DI			     ;point to where filename goes
;
EP329:	       POP  DS			     ;now move filename string
	       POP  SI			     ; to end of buffer path
;
	       REP  MOVSB		     ;copy associate filespec
;
	       POP  DS
	       POP  SI
;
; Check for buffer size override
;
EP350:	       MOV  AX,STR_BUFO 	     ;buffer size override active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP390
;
	       ADD  COM_CMDNUM,AX
	       MOV  AX,INS_SSEG 	     ;segment of PSP
	       MOV  ES,AX
	       MOV  BX,INS_SOFF 	     ;offset of PSP
	       ADD  BX,INS_RSLT 	     ;start of /B: parm
	       ADD  BX,INS_FLEN 	     ;start of kilobyte value
	       DEC  BX			     ;adjust for zero offset
	       PUSH BX
;
EP360:	       CMP  ES:BYTE PTR[BX],'0'      ;ASCII digit GE 0
	       JB   EP370		     ;no, end of digits
;
	       CMP  ES:BYTE PTR[BX],'9'      ;ASCII digit LE 9
	       JA   EP370		     ;no, end of digits
;
	       INC  BX
	       JMP  EP360		     ;check next digit
;
EP370:	       POP  AX
	       CMP  AX,BX		     ;any digits?
	       JE   EP390		     ;no, ignore /B parm
;
	       MOV  ST2_OPT1,ST2_DEC16BI+ST2_SETSTRLEN
					     ;convert ASCII value
	       MOV  ST2_STRGSEG,ES	     ;segment of value
	       MOV  ST2_STRGOFF,AX	     ;offset of value
	       SUB  BX,AX		     ;calculate numbers of digits
	       MOV  ST2_STRGLEN,BX	     ;set length to convert
	       ADD  COM_CMDNUM,BX
;
	       CALL PCST2IN_CALL	     ;convert the value
;
	       TEST ST2_ERROR,ST2_OUTOFMEM   ;value too large
	       JNZ  EP375		     ;yes, set to fail during alloc
;
	       CMP  ST2_NUMH,0		     ;value too large
	       JNE  EP375		     ;yes, set to fail during alloc
;
	       CMP  ST2_NUML,960	     ;value to large
	       JB   EP380		     ;no, attempt to alloc it
;
EP375:	       MOV  COM_DFSIZE,0F000H	     ;set to fail during alloc
	       JMP  EP385

EP380:	       MOV  AX,ST2_NUML 	     ;get kilobyte value
	       MOV  BX,64		     ;convert to paragraphs
	       MUL  BX			     ;kilo -> para
	       MOV  COM_DFSIZE,AX	     ;set value to allocate

EP385:	       OR   COM_STATE2,COM_BUFO      ;buffer size override active
;
; Check if DBCS is active
;
EP390:	       MOV  AX,STR_DBCS 	     ;DBCS active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP395
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE2,COM_DBCS      ;DBCS active
;
; Check for date/time active option
;
EP395:	       MOV  AX,STR_DATE 	     ;date active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP397
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE2,COM_DATE      ;date/time active
;
; Check for COM2 active option
;
EP397:	       MOV  AX,STR_COM2 	     ;COM2 active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0
	       JE   EP398
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE2,COM_COM2      ;COM2 active
;
; Check for enhancement activation
;
EP398:	       MOV  AX,STR_ENH		     ;COM2 active
	       CALL CHECK_STRING	     ;search for string
	       CMP  INS_RSLT,0		     ;
;>>SN	       JE   EP400
	       JE   EP399		     ;>>SN
;
	       ADD  COM_CMDNUM,AX
	       OR   COM_STATE2,COM_ENHA      ;COM2 active
;					     ;>>SN
; Check for Special Needs option	     ;>>SN
;					     ;>>SN
EP399:	       MOV  AX, STR_SN		     ;>>SN
	       CALL CHECK_STRING	     ;>>SN
	       CMP  INS_RSLT,0		     ;>>SN
	       JE   EP400		     ;>>SN
;					     ;>>SN
	       ADD  COM_CMDNUM, AX	     ;>>SN
	       OR   COM_STATE2,COM_SNA	     ;>>SN
;
; Check for invalid parameters
;
EP400:
	       MOV  AX, COM_CMDACT
	       CMP  AX, COM_CMDNUM
	       JE   EP405
;
	       MOV  COM_ERRID,ERR_BADCMD
	       JMP  EPEXIT
;
; Check for missing invocation parameter errors
;
EP405:	       TEST COM_STATE,COM_APPM
	       JNE  EP410
;
	       TEST COM_STATE,COM_DOSS
	       JNE  EP410
;
	       MOV  COM_ERRID,ERR_NODA	     ;dos/app both not active
	       JMP  EPEXIT
;
; Turn off color selection if mode 11 active
;
EP410:	       TEST COM_STATE,COM_M11H	     ;
	       JZ   EPEXIT		     ;
;
	       AND  COM_STATE, NOT COM_FLCS  ;
;
EPEXIT: 				     ;exit
;
	       RET
EXAMINE_PSP    ENDP
;
PAGE
;-----------------------------------------------------------------------------+
;									      :
; Name: 		CHECK_STRING					      :
;									      :
; Description:		Search for string identified by AX.		      :
;									      :
; Entry:		AX	    = String ID.			      :
;									      :
; Exit: 		INS_RSLT    = Offset into search string where match   :
;				      found.				      :
; Entry point:		CHECK_STRING					      :
;									      :
; Notes:		None.						      :
;									      :
; Internal references:	None.						      :
;									      :
; External references:	None.						      :
;									      :
;-----------------------------------------------------------------------------+
;
CHECK_STRING   PROC NEAR
;
	       CALL FAR PTR GET_STRING	     ;get address and length of string
;
	       MOV  INS_SPOFF,0 	     ;start at beginning of command lin
	       MOV  INS_FLEN,AX 	     ;set length of string to find
	       MOV  INS_FOFF,DI 	     ;set offset of string to find
	       MOV  INS_FSEG,ES 	     ;set segment of string to find
	       CALL PCINSTR_CALL
;
CHKSEXIT:				     ;exit
;
	       RET
CHECK_STRING   ENDP
