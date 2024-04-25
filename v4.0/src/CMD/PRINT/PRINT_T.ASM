	page	80,132
	TITLE	4.00 PRINT  TRANSIENT
;			$SALUT (4,25,30,41)
			INCLUDE pridefs.inc

SaveReg 		MACRO reglist	;; push those registers
IRP			reg,<reglist>
			PUSH reg
ENDM
ENDM

RestoreReg		MACRO reglist	;; pop those registers
IRP			reg,<reglist>
			POP  reg
ENDM
ENDM

BREAK			<Transient Portion>
;******************* START OF SPECIFICATIONS ***********************************
;
; MODULE NAME:		PRINT_T.SAL
;
; DESCRIPTIVE NAME:	TRANSIENT  -  Print Initialization and Instalation
;			Routine.   DOS PRINT program for background printing
;			of   text files to the list device - Transient Portion.
;
;  FUNCTION:	- Call the DOS PARSE Service Routines to process the command
;		  line. Search for valid input:
;			 - filenames (may be more than one
;			 - switches: /D:device
;				     /B:buffsize  512 to 16k - 512 default
;				     /Q:quesiz	    4 to 32  -	10 default
;				     /S:timeslice   1 to 255 -	 8 default
;				     /U:busytick    1 to 255 -	 1 default
;				     /M:maxtick     1 to 255 -	 2 default
;				     /T    terminate
;				     /C    cancel
;				     /P    print
;		- Install the resident component if not already installed
;		- Submit files for printing to the resident component
;
;  INPUT:	Parameter string from command line in the PSP
;
;  OUTPUT:	All parameters specified are updated. Files are submitted to
;		the resident component for printing.
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	LINK - TRANSIENT
;
;  NORMAL	-
;  EXIT:
;
;  ERROR	-
;  EXIT:
;
;  EXTERNAL	-
;  REFERENCES:
;
;  CHANGE	03/11/87 - Major restructureing of TRANSIENT - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START  TRANSIENT
;
;	If pdb_environ != 0
;		deallocate memory
;	endif
;	call SYSLOADMSG
;	if no error (if there is - SYSLOADMSG is already set to
;				display it - ie DOS ver error
;		if not installed
;			call Load_R_Msg
;			if no error
;				get all interupt values
;			else
;				load error message #
;				set error flag
;			endif
;		else
;			if PSPRINT conflict
;				load error message #
;				set error flag
;			endif
;		endif
;	endif
;	if no error and
;	get and set INT 24 handler
;	update path character
;	Set up for Parse_Input call
;	Do
;	Leave if end of command line
;	Leave if error flag set
;		call parse_input
;		if carry set
;			set up for Invalid_parm message
;		endif
;	Leave if error flag set
;		update Parse_C_B
;		if file_name
;			call Submit_Name
;		endif
;		if switch
;			Do_case switch
;				Bgncase_/D
;					if valid value and not installed
;						move device name to LISTNAME
;						reset carry
;					else
;						set carry
;					endif
;				Endcase_/D
;				Bgncase_/B
;					if valid value and not installed
;						update BLKSIZ
;						reset carry
;					else
;						set carry
;					endif
;				Endcase_/B
;				Bgncase_/Q
;					if valid value and not installed
;						update BLKSIZ
;						reset carry
;					else
;						set carry
;					endif
;				Endcase_/Q
;				Bgncase_/S
;					if valid value and not installed
;						update TIMESLICE, SLICECNT
;						reset carry
;					else
;						set carry
;					endif
;				Endcase_/S
;				Bgncase_/U
;					if valid value and not installed
;						update BUSYTICK
;						reset carry
;					else
;						set carry
;					endif
;				Endcase_/U
;				Bgncase_/M
;					if valid value and not installed
;						update MAXTICK
;						reset carry
;					else
;						set carry
;					endif
;				Endcase_/M
;				Bgncase_/T
;					if installed
;						set up for cancel
;						call IntWhileBusy
;					endif
;					call Set_Buffer
;					reset carry
;				Endcase_/T
;				Bgncase_/C
;					if installed
;						set CanFlag
;					else
;						call Set_Buffer
;					endif
;					reset carry
;				Endcase_/C
;				Bgncase_/P
;					if installed
;						reset CanFlag
;					else
;						call Set_Buffer
;					endif
;					reset carry
;				Endcase_/P
;			end_case
;			if carry set
;				set up for Invalid_parm message
;			endif
;		endif
;	enddo
;	if no error
;		if not installed
;			call Set_Buffer
;		else
;			get queue pointer
;			check for off line
;			display queue
;		endif
;	else
;		call DispMsg  (display the fatal error)
;	endif
;
;	return
;
;	END  TRANSIENT
;
;==================== END - PSEUDOCODE =========================================

CodeR			Segment public para

			extrn SliceCnt:BYTE, BusyTick:BYTE, MaxTick:BYTE, TimeSlice:BYTE
			extrn EndRes:WORD, BlkSiz:WORD, QueueLen:BYTE, PChar:BYTE
			extrn ListName:BYTE, FileQueue:BYTE, EndQueue:WORD, Buffer:WORD
			extrn EndPtr:WORD, NxtChr:WORD, MoveTrans:FAR, TO_DOS:FAR

			extrn MESBAS:WORD, R_MES_BUFF:WORD

CodeR			EndS


			BREAK <Transient Data>

;----------------------------------------
; Transient data
;----------------------------------------

DATA			SEGMENT public BYTE



			public namebuf

			ORG  0

SWITCHAR		DB   ?
PathChar		db   "\"

SubPack 		db   0		; Level
			dd   ?		; pointer to filename

;--- Ints used by print. These ints are loaded here before the
; resident is installed, just in case an error before print
; is installed cases it to be never installed and the ints
; have to be restored.

i28vec			dd   ?		; SOFTINT
i2fvec			dd   ?		; COMINT
i05vec			dd   ?
i13vec			dd   ?
i14vec			dd   ?
i15vec			dd   ?
i17vec			dd   ?
i1cvec			dd   ?		; INTLOC

;--- Temp stack for use durint int 23 and 24 processing
			db   278 + 80H dup (?) ; 278 == IBM's ROM requirements
intStk			dw   ?


;--- Print installed flag:
; 0 = Not installed yet: process only configuration parameters
;	during the command line parse
; 1 = Partially installed: process only print commands AND flag
;	configuration parameters as errors AND finish by executing
;	the keep process
; 2 = Already installed: process only print commands AND flag
;	configuration parameters as errors
PInst			db   0		; defaults to not installed
CanFlag 		db   0		; cancel mode flag (0= no cancel)
Ambig			db   ?		; =1 if a filename is ambigous
DevSpec 		db   0		; =1 a device was specified with the
					;  /d option, do not prompt
QFullMes		db   0		; =1 queue full message issued already
HARDCH			DD   ?		;Pointer to real INT 24 handler

TokBuf			DB   (MaxFileLen+16) dup(?) ; token buffer for input

NulPtr			dw   ?		; pointer to the nul in NameBuf
FNamPtr 		dw   ?		; pointer to name portion of file name
NameBuf 		db   (MaxFileLen+16) dup(?) ; full name buffer for file
					;  plus room for ambigous expansion

whichmsg		dw   (CLASS_C shl 8)+FstMes ; initial message for
					;		file queue loop

SearchBuf		find_buf <>	; search buffer

					;--------------------------------------
					; PARSE Equates
					;--------------------------------------

EOL			equ  -1 	; Indicator for End-Of-Line
NOERROR 		equ  0		; Return Indicator for No Errors

DEVICE			equ  0		; device
BUFFSIZ 		equ  1		; buffsiz
QUESIZ			equ  2		; quesiz
TIME			equ  3		; timeslice
BUSYT			equ  4		; busytick
MAXT			equ  5		; maxtick
TERM			equ  6		; Terminate
CANC			equ  7		; Cancel
PRINT			equ  8		; Print

file_spec		equ  5		; Parse Type for file spec found

					;--------------------------------------
					; PARSE Control Block
					;--------------------------------------

ORDINAL 		DW   0		; Current Parse ordinal value
SCAN_PTR		DW   81h	; Current Parse location Pointer
MSG_PTR 		DW   81h	; Last Parse location Pointer

					;--------------------------------------
					;  STRUCTURE TO DEFINE ADDITIONAL
					;	COMMAND LINE PARAMETERS
					;--------------------------------------
PARMS			LABEL WORD
			DW   OFFSET DG:PARMSX ; POINTER TO PARMS STRUCTURE
			DB   0		; NO DELIMITER LIST FOLLOWS

					;--------------------------------------
					;  STRUCTURE TO DEFINE SYNTAX
					;--------------------------------------
PARMSX			LABEL BYTE
			DB   0,1	; A POSITIONAL PARAMETER IS VALID
			DW   OFFSET DG:POS1 ; POINTER TO POSITIONAL DEFINITION
			DB   9		; THERE ARE 9 TYPES OF SWITCHES
			DW   OFFSET DG:SW1 ; POINTER TO THE /D:device SWITCH DEFINITION AREA
			DW   OFFSET DG:SW2 ; POINTER TO THE /B:buffsiz SWITCH DEFINITION AREA
			DW   OFFSET DG:SW3 ; POINTER TO THE /Q:quesiz SWITCH DEFINITION AREA
			DW   OFFSET DG:SW4 ; POINTER TO THE /S:timeslice SWITCH DEFINITION AREA
			DW   OFFSET DG:SW5 ; POINTER TO THE /U:busytick SWITCH DEFINITION AREA
			DW   OFFSET DG:SW6 ; POINTER TO THE /M:maxval SWITCH DEFINITION AREA
			DW   OFFSET DG:SW7 ; POINTER TO THE /T	TERMINATE SWITCH DEFINITION AREA
			DW   OFFSET DG:SW8 ; POINTER TO THE /C CANCEL SWITCH DEFINITION AREA
			DW   OFFSET DG:SW9 ; POINTER TO THE /P PRINT SWITCH DEFINITION AREA
			DW   0		; THERE ARE NO KEYWORDS IN PRINT SYNTAX

					;--------------------------------------
					;
					; NOTE: Do NOT change the layout or size
					;	of the following entries:
					;	 --- SW1 through SW9  ---
					;	Their size and position are used
					;	to calculate an index for a
					;	DO_CASE (jump table). This is
					;	possible ONLY if the size of all
					;	9 entries are exactly the same,
					;	congruant, and in this exact
					;	order. Any changes here MUST be
					;	matched in the Process_A_Switch
					;	PROC.
					;
					;	The following formula is used:
					;
					;	Index = (offset P_SYN - offset
					;		SW1) / SW_SIZE
					;
					;--------------------------------------


					;--------------------------------------
					;  STRUCTURE TO DEFINE THE POSITIONAL
					;	    PARAMETER (File Name)
					;--------------------------------------
POS1			LABEL WORD
			DW   0203H	; OPTIONAL, REPEATABLE FILE SPEC
			DW   0001H	; CAPS BY FILE TABLE
			DW   OFFSET DG:PARSE_BUFF ; PLACE RESULT IN BUFFER
			DW   OFFSET DG:NOVALS ; NO VALUES LIST REQUIRED
			DB   0		; NO KEYWORDS

					;--------------------------------------
					; STRUCTURE TO DEFINE /D:device SWITCH
					;--------------------------------------
SW1			LABEL WORD
			DW   2001H	; MUST BE PRINT OUTPUT DEVICE
					; (optional simple string)
			DW   1h 	; Caps by file table
			DW   OFFSET DG:PARSE_BUFF ; PLACE RESULT IN BUFFER
			DW   OFFSET DG:NOVALS ; VALUE LIST NOT NECESSARY
			DB   1		; ONE SWITCH IN FOLLOWING LIST
SW_PTR			DB   "/D",0	; /D: INDICATES DEVICE SPECIFIED

SW_SIZE 		equ  $ - SW1
					;--------------------------------------
					; STRUCTURE TO DEFINE /B:buffsiz SWITCH
					;--------------------------------------
SW2			LABEL WORD
			DW   8001H	; MUST BE NUMERIC (optional)
			DW   0		; NO FUNCTION FLAGS
			DW   OFFSET DG:PARSE_BUFF ; PLACE RESULT IN BUFFER
			DW   OFFSET DG:VALUE_BUF ; NEED VALUE LIST FOR buffsiz
			DB   1		; ONE SWITCH IN FOLLOWING LIST
B_SWITCH		DB   "/B",0	; /B: INDICATES buffsiz REQUESTED

					;--------------------------------------
					; STRUCTURE TO DEFINE /Q:quesiz SWITCH
					;--------------------------------------
SW3			LABEL WORD
			DW   8001H	; MUST BE NUMERIC (optional)
			DW   0		; NO FUNCTION FLAGS
			DW   OFFSET DG:PARSE_BUFF ; PLACE RESULT IN BUFFER
			DW   OFFSET DG:VALUE_QUE ; NEED VALUE LIST FOR quesiz
			DB   1		; ONE SWITCH IN FOLLOWING LIST
Q_SWITCH		DB   "/Q",0	; /Q: INDICATES quesiz REQUESTED

					;--------------------------------------
					; STRUCTURE TO DEFINE /S:timeslice SWITCH
					;--------------------------------------
SW4			LABEL WORD
			DW   8001H	; MUST BE NUMERIC (optional)
			DW   0		; NO FUNCTION FLAGS
			DW   OFFSET DG:PARSE_BUFF ; PLACE RESULT IN BUFFER
			DW   OFFSET DG:VALUE_TIME ; NEED VALUE LIST FOR timeslice
			DB   1		; ONE SWITCH IN FOLLOWING LIST
S_SWITCH		DB   "/S",0	; /S: INDICATES timeslice REQUESTED

					;--------------------------------------
					; STRUCTURE TO DEFINE /U:busytick SWITCH
					;--------------------------------------
SW5			LABEL WORD
			DW   8001H	; MUST BE NUMERIC (optional)
			DW   0		; NO FUNCTION FLAGS
			DW   OFFSET DG:PARSE_BUFF ; PLACE RESULT IN BUFFER
			DW   OFFSET DG:VALUE_BUSY ; NEED VALUE LIST FOR busytick
			DB   1		; ONE SWITCH IN FOLLOWING LIST
U_SWITCH		DB   "/U",0	; /U: INDICATES busytick REQUESTED

					;--------------------------------------
					; STRUCTURE TO DEFINE /M:maxtick SWITCH
					;--------------------------------------
SW6			LABEL WORD
			DW   8001H	; MUST BE NUMERIC (optional)
			DW   0		; NO FUNCTION FLAGS
			DW   OFFSET DG:PARSE_BUFF ; PLACE RESULT IN BUFFER
			DW   OFFSET DG:VALUE_MAXT ; NEED VALUE LIST FOR maxtick
			DB   1		; ONE SWITCH IN FOLLOWING LIST
M_SWITCH		DB   "/M",0	; /M: INDICATES maxtick REQUESTED

					;--------------------------------------
					;  STRUCTURE TO DEFINE /T Terminate SWITCH
					;--------------------------------------
SW7			LABEL WORD
			DW   8001H	; SWITCH ONLY
					; (optional simple string)
			DW   0		; NO FUNCTION FLAGS
			DW   OFFSET DG:PARSE_BUFF ; PLACE RESULT IN BUFFER
			DW   OFFSET DG:NOVALS ; VALUE LIST NOT NECESSARY
			DB   1		; ONE SWITCH IN FOLLOWING LIST
			DB   "/T",0	; /T: INDICATES Terminate REQUESTED

					;--------------------------------------
					;  STRUCTURE TO DEFINE /C Cancel SWITCH
					;--------------------------------------
SW8			LABEL WORD
			DW   8003H	; SWITCH ONLY
					; (optional, repeatable simple string)
			DW   0		; NO FUNCTION FLAGS
			DW   OFFSET DG:PARSE_BUFF ; PLACE RESULT IN BUFFER
			DW   OFFSET DG:NOVALS ; VALUE LIST NOT NECESSARY
			DB   1		; ONE SWITCH IN FOLLOWING LIST
C_SW_ptr		DB   "/C",0	; /C: INDICATES Cancel REQUESTED

					;--------------------------------------
					;  STRUCTURE TO DEFINE /P Print SWITCH
					;--------------------------------------
SW9			LABEL WORD
			DW   8003H	; SWITCH ONLY
					; (optional, repeatable simple string)
			DW   0		; NO FUNCTION FLAGS
			DW   OFFSET DG:PARSE_BUFF ; PLACE RESULT IN BUFFER
			DW   OFFSET DG:NOVALS ; VALUE LIST NOT NECESSARY
			DB   1		; ONE SWITCH IN FOLLOWING LIST
P_SW_ptr		DB   "/P",0	; /P: INDICATES Print REQUESTED

					;--------------------------------------
					;  VALUE LIST FOR FILE NAMES
					;--------------------------------------
NOVALS			LABEL WORD
			DB   0		; NO VALUES

					;--------------------------------------
					;  VALUE LIST DEFINITION FOR buffsiz
					;--------------------------------------
VALUE_BUF		LABEL BYTE
			DB   1		; ONE VALUE ALLOWED
			DB   1		; ONLY ONE RANGE
			DB   BUFFSIZ	; IDENTIFY IT AS buffsiz
					; USER CAN SPECIFY /+512 THROUGH /+16K
			DD   MinBufferLen,MaxBufferLen

					;--------------------------------------
					;  VALUE LIST DEFINITION FOR quesiz
					;--------------------------------------
VALUE_QUE		LABEL BYTE
			DB   1		; ONE VALUE ALLOWED
			DB   1		; ONLY ONE RANGE
			DB   QUESIZ	; IDENTIFY IT AS quesiz
					; USER CAN SPECIFY /+4 THROUGH /+32
			DD   MinQueueLen,MaxQueueLen

					;--------------------------------------
					;  VALUE LIST DEFINITION FOR timeslice
					;--------------------------------------
VALUE_TIME		LABEL BYTE
			DB   1		; ONE VALUE ALLOWED
			DB   1		; ONLY ONE RANGE
			DB   TIME	; IDENTIFY IT AS timeslice
					; USER CAN SPECIFY /+1 THROUGH /+255
			DD   MinTimeSlice,MaxTimeSlice

					;--------------------------------------
					;  VALUE LIST DEFINITION FOR busytick
					;--------------------------------------
VALUE_BUSY		LABEL BYTE
			DB   1		; ONE VALUE ALLOWED
			DB   1		; ONLY ONE RANGE
			DB   BUSYT	; IDENTIFY IT AS busytick
					; USER CAN SPECIFY /+1 THROUGH /+255
			DD   MinBusyTick,MaxBusyTick

					;--------------------------------------
					;  VALUE LIST DEFINITION FOR maxtick
					;--------------------------------------
VALUE_MAXT		LABEL BYTE
			DB   1		; ONE VALUE ALLOWED
			DB   1		; ONLY ONE RANGE
			DB   MAXT	; IDENTIFY IT AS maxtick
					; USER CAN SPECIFY /+1 THROUGH /+255
			DD   MinMaxTick,MaxMaxTick

					;--------------------------------------
					;  RETURN BUFFER FOR PARSE INFORMATION
					;--------------------------------------
PARSE_BUFF		LABEL BYTE
P_TYPE			DB   ?		; TYPE RETURNED
P_ITEM_TAG		DB   ?		; SPACE FOR ITEM TAG
P_SYN			DW   ?		; POINTER TO LIST ENTRY
P_PTR_L 		DW   ?		; SPACE FOR POINTER / VALUE - LOW
P_PTR_H 		DW   ?		; SPACE FOR POINTER / VALUE - HIGH

					;----------------------------------------
					; SUBLIST for Message call
					;----------------------------------------

SUBLIST 		LABEL WORD

			DB   sub_size	; size of sublist
			DB   0		; reserved
insert_ptr_off		DW   0		; pointer to insert - offset
insert_ptr_seg		DW   DG 	; pointer to insert - segment
insert_num		DB   0		; number of insert
			DB   Char_Field_ASCIIZ ; data type flag - ASCII Z string
			DB   MaxFileLen ; maximum field size
			DB   1		; minimum field size
			DB   " "	; pad character

sub_size		equ  $ - SUBLIST ; size of sublist


OPEN_FILE		label dword

			dw   offset DG:NameBuf ; name pointer offset
open_seg		dw   ?		; name pointer segment

DATA			ENDS

			BREAK <Transient Code>

Code			Segment public para
Code			EndS

Code			Segment public para

			public TransRet,TransSize,GoDispMsg

			extrn SYSLOADMSG:NEAR, SYSGETMSG:NEAR, SYSDISPMSG:NEAR
			extrn SYSPARSE:NEAR

			ASSUME CS:DG,DS:nothing,ES:nothing,SS:Stack

;  $SALUT (4,4,9,41)

TRANSIENT:
					;-------------------------------------
					; Install Print
					;-------------------------------------

   cld
   mov	ax,ds:[pdb_environ]
   or	ax,ax

;  $if	nz				; if pdb_environ != 0		       ;AC000;
   JZ $$IF1

       push es				; deallocate memory
       mov  es,ax
       mov  ah,dealloc
       int  21h
       pop  es

;  $endif				;				       ;AC000;
$$IF1:

   call SYSLOADMSG			; Initialize the Message Service code  ;AN000;

;  $if	c				; if error			       ;AC000;
   JNC $$IF3

       mov  ah,dh			; set up class for DispMsg

;  $else				; else - no error - keep going
   JMP SHORT $$EN3
$$IF3:

       push cs
       pop  ax
       mov  ds,ax
       mov  es,ax

       ASSUME DS:DG,ES:DG
					; NOTE: es must ALWAYS point to DG

       mov  ax,0100h			; Ask if already installed
       int  ComInt
       or   al,al

;      $if  z				; if not installed		       ;AC000;
       JNZ $$IF5

	   call Load_R_Msg		;				       ;AC000;

;	   $if	nc			; if no error			       ;AC000;
	   JC $$IF6

	       call Save_Vectors	;				       ;AC000;

;	   $endif			; endif - NB: - If carry IS set,       ;AC000;
$$IF6:
					; Load_R_Msg will have loaded the
					; error message #

;      $else				;  else - we are installed	       ;AC000;
       JMP SHORT $$EN5
$$IF5:

	   cmp	al,1

;	   $if	z			; if PSPRINT conflict		       ;AC000;
	   JNZ $$IF9

	       mov  ax,(CLASS_B shl 8) + CONFLICTMES ; load error message #    ;AC000;

	       stc			; set the error flag		       ;AC000;

;	   $else			;				       ;AC000;
	   JMP SHORT $$EN9
$$IF9:

	       mov  [PInst],2		; remember print already installed
					;	   and that we only do one pass
	       mov  al," "		; invalidate install switches	       ;AN005;
	       mov  SW_PTR,al		; /D				       ;AN005;
	       mov  B_SWITCH,al 	; /B				       ;AN005;
	       mov  Q_SWITCH,al 	; /Q				       ;AN005;
	       mov  S_SWITCH,al 	; /S				       ;AN005;
	       mov  U_SWITCH,al 	; /U				       ;AN005;
	       mov  M_SWITCH,al 	; /M				       ;AN005;
	       clc			; reset the error flag		       ;AC000;

;	   $endif			;				       ;AC000;
$$EN9:
;      $endif				;				       ;AC000;
$$EN5:
;  $endif				;				       ;AC000;
$$EN3:

;  $if	nc,and				; if no errors so far and..............;AC000;
   JC $$IF14

   call GetHInt 			; save current int 24 vector
   call SetInts 			; set int 23 and 24 vectors
   mov	ax,CHAR_OPER shl 8
   int	21h
   mov	[SWITCHAR],dl			; Get user switch character
   cmp	dl,"-"

;  $if	e				; if "-"			       ;AC000;
   JNE $$IF14
       mov  [PathChar],"/"		; alternate path character
;  $endif				;				       ;AC000;
$$IF14:

					; Set up for Parse_Input call

;  $do					; Do_until end of command line	       ;AC000;
$$DO16:

;  $leave c				;  quit if an error occured	       ;AC000;
   JC $$EN16

       call parse_input 		;				       ;AC000;

       mov  [ordinal],cx		;  update Parse_C_B		       ;AC000;
       mov  [scan_ptr],si		;				       ;AC000;

       cmp  al,EOL			;  are we at the end?		       ;AC000;

;  $leave e				; leave if end of line		       ;AC000;
   JE $$EN16

       cmp  al,noerror			;				       ;AC000;

;      $if  ne				;  if error			       ;AC000;
       JE $$IF19

	   mov	ah,Parse_error		;   set class to Parse error	       ;AC000;


	   stc				;    set the error flag 	       ;AC000;

;      $endif				;  endif			       ;AC000;
$$IF19:

;  $leave c				; leave the loop if error ocurred      ;AC000;
   JC $$EN16

       cmp  [p_type],File_Spec		;  is it a file spec?		       ;AC000;

;      $if  e				;  if it is a file spec 	       ;AC000;
       JNE $$IF22

	   call Submit_File		;				       ;AC000;

;      $else				;  else - we must now have a	       ;AC000;
       JMP SHORT $$EN22
$$IF22:
					;	valid switch!


					;  Do_case switch

	   push cs			;   set up for CASE		       ;AC000;
	   pop	ds			;				       ;AC000;
	   mov	ax,[p_syn]		;				       ;AC000;
	   sub	ax,OFFSET DG:SW_PTR	;				       ;AC000;
	   mov	dl,SW_SIZE		;				       ;AC000;
	   div	dl			;				       ;AC000;
	   cmp	ah,noerror		;				       ;AC000;
	   mov	di,ax			;				       ;AC000;
	   mov	ax,(CLASS_B shl 8) + invparm ; set message in case of error    ;AC000;

;	   $if	e			; if no error in jump calculation      ;AC000;
	   JNE $$IF24

	       call Process_A_Switch	;				       ;AC000;

;	   $else
	   JMP SHORT $$EN24
$$IF24:

	       stc			; set the error flag		       ;AC000;

;	   $endif			; endif - no error in jump calculation ;AC000;
$$EN24:

;      $endif				; endif - name or switch	       ;AC000:
$$EN22:

;  $leave c				; leave the loop if error ocurred      ;AC000;
   JC $$EN16

;  $enddo				; enddo 			       ;AC000;
   JMP SHORT $$DO16
$$EN16:

;  $if	nc,long 			; if no error so far		       ;AC000;
   JNC $$XL1
   JMP $$IF30
$$XL1:

       cmp  [PInst],0			; is print already installed?

;      $if  e				; if not installed		       ;AC000;
       JNE $$IF31

	   call Set_Buffer		; NOTE from now on the TRANSIENT could ;AC000;
					; be in a SEGMENT that is different
					; than the one set up by the loader!
					; *** MOV xx,DG will no longer work ***
					; (use PUSH CS , POP xx instead)

;      $endif				; endif  - installed		       ;AC000;
$$IF31:

					; Grab the pointer to the queue and
					;  lock it down.  Remember that since
					;  there are threads in the background,
					;  we may get a busy return.  We sit
					;  here in a spin loop until we can
					;  actually lock the queue.

       mov  ax,0104h			; get status
       call IntWhileBusy		; on return DS:SI points to queue

       ASSUME DS:nothing
					;------------------------------------
					;    check for off-line
					;------------------------------------

       cmp  dx,ErrCnt1			; check count

;      $if  ae				; if count too high		       ;AC000;
       JNAE $$IF33

	   mov	ax,(CLASS_B shl 8) + CntMes ; printer might be off-line        ;AC000;
	   call DispMsg 		;				       ;AC000;

;      $endif				; endif - count Too high	       ;AC000;
$$IF33:

;					;------------------------------------
;					;    display current queue
;					;	 ds:si points to print queue
;					;	 ds:di must point to display
;					;			  buffer
;					; xNameTrans will copy the name into
;					;   the name buffer.  It will do
;					;   any name truncation if needed
;					;   (including any DBSC characters)
;					;
;					;------------------------------------
;      mov  di,offset dg:NameBuf	;				       ;AN009;
;      mov  ax,(xNameTrans SHL 8)	; check for name translation	       ;AN009;
;      int  21h 			; get real path and name	       ;AN009;

;;;;;;;;;;;;;xxxxxxxxxxxxxxxxx
       call copy_to_arg_buf
;;;;;;;;;;;;;xxxxxxxxxxxxxxxxx

       mov  ax,[whichmsg]		;				       ;AN000;
       mov  [whichmsg],(CLASS_C shl 8) + SecMes ; set up in queue msg	       ;AC000;
       cmp  byte ptr ds:[si],0		; is the queue empty?

;      $if  ne				; if queue not empty		       ;AC000;
       JE $$IF35

;	   $do				;				       ;AC000;
$$DO36:

	       push ds
	       call DispMsg		;				       ;AC000;
	       pop  ds
	       add  si,MaxFileLen	; point to next entry in queue

;;;;;;;;;;;;;xxxxxxxxxxxxxxxxx
	       call copy_to_arg_buf
;;;;;;;;;;;;;xxxxxxxxxxxxxxxxx

;		mov  di,offset dg:NameBuf ;					;AN009;
;		mov  ax,(xNameTrans SHL 8) ; check for name translation 	;AN009;
;		int  21h		 ; get real path and name		;AN009;
	       mov  ax,[whichmsg]	;				       ;AC009;
	       cmp  byte ptr ds:[si],0	; end of queue?

;	   $enddo e			;				       ;AC000;
	   JNE $$DO36

;      $else				; else - queue is empty 	       ;AC000;
       JMP SHORT $$EN35
$$IF35:

	   mov	ax,(CLASS_B shl 8) + NoFils ;				       ;AC000;
	   call DispMsg 		;				       ;AC000;

;      $endif				; endif - queue not empty	       ;AC000;
$$EN35:

					;------------------------------------
					;    exit transient
					;------------------------------------

       mov  ax,0105H			; unlock the print queue
       call IntWhileBusy		; on return DS:SI points to queue
       cmp  [PInst],1			; are we partially installed ?

;      $if  e				; if so...  complete the process       ;AC000;
       JNE $$IF40

	   mov	ax,CodeR		; close Std Devices
	   mov	ds,ax

	   ASSUME DS:CodeR

	   xor	bx,bx
	   mov	cx,5			; StdIN,StdOUT,StdERR,StdAUX,StdPRN

;	   $do				; Close STD handles before keep process;AC000;
$$DO41:

	       mov  ah,CLOSE
	       int  21h
	       inc  bx

;	   $enddo loop			;				       ;AC000;
	   LOOP $$DO41


	   mov	dx,[ENDRES]		; install print...
	   mov	ax,KEEP_PROCESS shl 8	; Exit code 0

;      $else				; else -			       ;AC000;
       JMP SHORT $$EN40
$$IF40:

	   mov	ax,(EXIT shl 8) 	; quit with no error

;      $endif				; endif -			       ;AC000;
$$EN40:

;  $else				; else - a fatal error occured	       ;AC000;
   JMP SHORT $$EN30
$$IF30:

       call DispMsg			; display the error message	       ;AC000;
       mov  ax,(EXIT shl 8)		; quit with error


;  $endif				; erdif - errors		       ;AC000;
$$EN30:


   int	21h				; either EXIT or KEEP_PROCESS

   push es
   xor	ax,ax
   push ax

   foo	proc	far
   ret					; Must use this method, version may be < 2.00
   foo	endp

   BREAK <Process_A_Switch>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:     Process_A_Switch
;
;  FUNCTION: This routine is a DO Case that processes all valid switched for
;	     PRINT.
;
;  INPUT:    Jump table offset calculated in the main routine.
;
;  OUTPUT:   Proper processing for the switch
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	Call from: TRANSIENT
;
;  NORMAL	-
;  EXIT:
;
;  ERROR	-
;  EXIT:
;
;  EXTERNAL	Call to:   DispMsg	  Parse_Input	    GetAbsN
;  REFERENCES:		   IntWhileBusy   GetAbsN2
;
;  CHANGE	04/01/87 - make SWITCH processing a PROC - FJG
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	 START Process_A_Switch
;	 END Process_A_Switch
;
;******************** END   - PSEUDOCODE ***************************************

   Process_A_Switch PROC NEAR

   shl	di,1				;				       ;AC000;

   jmp	cs:JMPTABLE[di] 		;				       ;AC000;

JMPTABLE LABEL WORD			;				       ;AC000;

   DW	CASE_D				;				       ;AN000;
   DW	CASE_B				;				       ;AN000;
   DW	CASE_Q				;				       ;AN000;
   DW	CASE_S				;				       ;AN000;
   DW	CASE_U				;				       ;AN000;
   DW	CASE_M				;				       ;AN000;
   DW	CASE_T				;				       ;AN000;
   DW	CASE_C				;				       ;AN000;
   DW	CASE_P				;				       ;AN000;

   ASSUME ds:DG,es:DG

CASE_D: 				; Bgncase_/D			       ;AN000;

   cmp	[PInst],0			;				       ;AC000;

;  $if	e,and				;  if not installed		       ;AC000;
   JNE $$IF47

					;   move device name to LISTNAME
   mov	bp,[P_PTR_L]			;				       ;AC000;
   mov	di,bp				;  save start address		       ;AC000;
   mov	ax,[P_PTR_H]			;				       ;AC000;
   mov	es,ax				;

   ASSUME es:nothing

   xor	al,al				; find the length of input name        ;AN000;
   mov	cx,9				; it can not be longer than 8 + :      ;AN000;

   ASSUME es:DG 			; this is a bogus assume to keep the
					;      assembler happy
   repne scas NameBuf			; (use NameBuf to tell assembler its   ;AN000;
					; a byte search)
   ASSUME es:nothing			; this puts it back right

   dec	di				; back up to first null 	       ;AN000;
   mov	ax,di				; pointer to end		       ;AN000;
   sub	ax,bp				; subtract start pointer	       ;AN000;
   mov	cx,ax				; difference is the length	       ;AN000;
   or	cx,cx				; is it non zero?		       ;AN000;

;  $if	ne				; if we have a name		       ;AN000;
   JE $$IF47

       mov  si,di			; set DS:SI up to source (Parse Buffer);AN000;
       mov  ax,es			; set ES:DI up to LISTNAME (in CodeR)  ;AN000;
       mov  ds,ax			;				       ;AN000;
       mov  ax,CodeR			;
       mov  es,ax			;

       ASSUME DS:nothing,ES:CodeR

       mov  WORD PTR [LISTNAME],2020h	; Nul out default
       mov  [LISTNAME+2]," "		;
       mov  di,OFFSET CodeR:LISTNAME	;
       dec  si				; back up to last character	       ;AN004;
       cmp  BYTE PTR [si],':'		; is there a ':' at the end of the name?

;      $if  e				; if it is			       ;AC000;
       JNE $$IF48
	   dec	cx			; Chuck the trailing ':'
;      $endif				;				       ;AC000;
$$IF48:

       cmp  cx,8			; is the name still longer than 8?

;      $if  a				; if it is			       ;AC000;
       JNA $$IF50
	   mov	cx,8			; Limit to 8 chars for device
;      $endif				;				       ;AC000;
$$IF50:

       mov  si,bp			;				       ;AC000;
       rep  movsb			; move the device name into LISTNAME					 ;AC000;
       mov  si,bp			;
       mov  [DevSpec],1 		; remember that a device was specified
       clc				;   reset carry 		       ;AC000;

;  $else				;  else 			       ;AC000;
   JMP SHORT $$EN47
$$IF47:

       stc				;   set carry			       ;AC000;

;  $endif				;  endif			       ;AC000;
$$EN47:

   push cs				;
   pop	cx				;
   mov	ds,cx				;
   mov	es,cx				;
   mov	al," "				; invalidate this switch	       ;AN005;
   mov	SW_PTR,al			; /D				       ;AN005;


   JMP	CASE_END			; Endcase_/D			       ;AN000;

CASE_B: 				; Bgncase_/B			       ;AN000;

   ASSUME ds:DG,es:DG

   cmp	[PInst],0			;

;  $if	e				;  if not installed		       ;AC000;
   JNE $$IF54

       mov  ax,[P_PTR_L]		;   get the value		       ;AC000;
       push ds				;   update BLKSIZ
       mov  dx,CodeR			;
       mov  ds,dx			;

       ASSUME DS:CodeR

       mov  [BLKSIZ],ax 		;
       pop  ds				;

       ASSUME DS:DG

       clc				;   reset carry 		       ;AC000;

;  $else				;  else 			       ;AC000;
   JMP SHORT $$EN54
$$IF54:

       stc				;   set carry			       ;AC000;

;  $endif				;  endif			       ;AC000;
$$EN54:

   mov	al," "				; invalidate this switch	       ;AN005;
   mov	B_SWITCH,al			; /B				       ;AN005;

   JMP	CASE_END			; Endcase_/B			       ;AN000;

CASE_Q: 				; Bgncase_/Q			       ;AN000;

   cmp	[PInst],0			;

;  $if	e				;  if not installed		       ;AC000;
   JNE $$IF57

       mov  ax,[P_PTR_L]		;   get the value		       ;AC000;
       push ds				;   update BLKSIZ
       mov  dx,CodeR			;
       mov  ds,dx			;

       ASSUME DS:CodeR

       mov  [QueueLen],al		;
       pop  ds				;

       ASSUME DS:DG

       clc				;   reset carry 		       ;AC000;

;  $else				;  else 			       ;AC000;
   JMP SHORT $$EN57
$$IF57:

       stc				;   set carry			       ;AC000;

;  $endif				;  endif			       ;AC000;
$$EN57:

   mov	al," "				; invalidate this switch	       ;AN005;
   mov	Q_SWITCH,al			; /Q				       ;AN005;

   JMP	CASE_END			; Endcase_/Q			       ;AN000;

CASE_S: 				; Bgncase_/S			       ;AN000;

   cmp	[PInst],0			;

;  $if	e				;  if not installed		       ;AC000;
   JNE $$IF60

       mov  ax,[P_PTR_L]		;   get the value		       ;AC000;
       push ds				;   update TIMESLICE, SLICECNT
       mov  dx,CodeR			;
       mov  ds,dx			;

       ASSUME ds:CodeR

       mov  [TIMESLICE],al		;
       mov  [SLICECNT],al		;
       pop  ds				;

       ASSUME ds:DG

       clc				;   reset carry 		       ;AC000;

;  $else				;  else 			       ;AC000;
   JMP SHORT $$EN60
$$IF60:

       stc				;   set carry			       ;AC000;

;  $endif				;  endif			       ;AC000;
$$EN60:

   mov	al," "				; invalidate this switch	       ;AN005;
   mov	S_SWITCH,al			; /S				       ;AN005;

   JMP	CASE_END			; Endcase_/S			       ;AN000;

CASE_U: 				; Bgncase_/U			       ;AN000;

   cmp	[PInst],0			;

;  $if	e				;  if not installed		       ;AC000;
   JNE $$IF63

       mov  ax,[P_PTR_L]		;   get the value		       ;AC000;
       push ds				;   update BUSYTICK
       mov  dx,CodeR			;
       mov  ds,dx			;

       ASSUME ds:CodeR

       mov  [BUSYTICK],al		;
       pop  ds				;

       ASSUME ds:DG

       clc				;   reset carry 		       ;AC000;

;  $else				;  else 			       ;AC000;
   JMP SHORT $$EN63
$$IF63:

       stc				;   set carry			       ;AC000;

;  $endif				;  endif			       ;AC000;
$$EN63:

   mov	al," "				; invalidate this switch	       ;AN005;
   mov	U_SWITCH,al			; /U				       ;AN005;

   JMP	CASE_END			; Endcase_/U			       ;AN000;

CASE_M: 				; Bgncase_/M			       ;AN000;

   cmp	[PInst],0			;

;  $if	e				;  if not installed		       ;AC000;
   JNE $$IF66

       mov  ax,[P_PTR_L]		;   get the value		       ;AC000;
       push ds				;   update MAXTICK
       mov  dx,CodeR			;
       mov  ds,dx			;

       ASSUME ds:CodeR

       mov  [MAXTICK],al		;
       pop  ds				;

       ASSUME ds:DG

       clc				;   reset carry 		       ;AC000;

;  $else				;  else 			       ;AC000;
   JMP SHORT $$EN66
$$IF66:

       stc				;   set carry			       ;AC000;

;  $endif				;  endif			       ;AC000;
$$EN66:

   mov	al," "				; invalidate this switch	       ;AN005;
   mov	M_SWITCH,al			; /M				       ;AN005;

   JMP	CASE_END			; Endcase_/M			       ;AN000;

CASE_T: 				; Bgncase_/T			       ;AN000;

   push si				;   save parse pointer

   cmp	[PInst],0			;  has print been installed?

;  $if	e				;  if not installed		       ;AC000;
   JNE $$IF69

       call Set_Buffer			;  do it now			       ;AC000;

;  $endif				;  endif			       ;AC000;
$$IF69:
					;   set up for cancel
   mov	ax,0103H			;   cancel command

   call IntWhileBusy			;

   pop	si				;   restore parse pointer

   clc					;  reset carry			       ;AC000;

   JMP	CASE_END			; Endcase_/T			       ;AN000;

CASE_C: 				; Bgncase_/C			       ;AN000;

   cmp	[PInst],0			;  has print been installed?

;  $if	ne				;  if installed 		       ;AC000;
   JE $$IF71

       mov  [CanFlag],1 		;   set CanFlag

;  $else				;  else 			       ;AC000;
   JMP SHORT $$EN71
$$IF71:

       call Set_Buffer			;				       ;AC000;

;  $endif				;  endif			       ;AC000;
$$EN71:

   clc					;  reset carry			       ;AC000;

   JMP	CASE_END			; Endcase_/C			       ;AN000;

CASE_P: 				; Bgncase_/P			       ;AN000;

   cmp	[PInst],0			;  has print been installed?

;  $if	ne				;  if installed 		       ;AC000;
   JE $$IF74

       mov  [CanFlag],0 		;   reset CanFlag

;  $else				;  else 			       ;AC000;
   JMP SHORT $$EN74
$$IF74:

       call Set_Buffer			;				       ;AC000;

;  $endif				;  endif			       ;AC000;
$$EN74:

   clc					;  reset carry			       ;AC000;

					; Endcase_/P

CASE_END:				; End_case			       ;AN000;

;  $if	c				; if carry set			       ;AC000;
   JNC $$IF77

       mov  ax,(Parse_error shl 8) + INVPARM ; set up for Invalid_parm message ;AN000:

       cmp  [PInst],0			;  has print been installed?

;      $if  ne				;  if installed 		       ;AN005;
       JE $$IF78

	   call DispMsg 		;  display the message and keep going  ;AN005;

;      $endif				;  endif			       ;AN005;
$$IF78:

;  $endif				; endif 			       ;AC000;
$$IF77:

   ret

   Process_A_Switch ENDP

   BREAK <Submit_File>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	Submit_File -  PRINT TRANSIENT to Resident Interface Routine
;
;  FUNCTION:	Resolved ambiguous file names (containing ? and *) and submits
;		the file to the Resident component of PRINT for printing.
;
;  INPUT:	File name in Parse buffer
;
;  OUTPUT:	None.
;
;  NOTE:	This code is primarily old code, but it has been completely
;		restructured and SALUTed.
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	Call from: TRANSIENT
;
;  NORMAL	-
;  EXIT:
;
;  ERROR	-
;  EXIT:
;
;  EXTERNAL	Call to:   DispMsg	  Parse_Input	    GetAbsN
;  REFERENCES:		   IntWhileBusy   GetAbsN2
;
;  CHANGE	04/01/87 - change PaFile to Submit_File   - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	 START
;	 .
;	 .
;	 .
;	 .
;	 .
;
; INPUT: CanFlag and Ambig set appropriately
;
;	if CanFlag
;		set up cancel
;		call IntWhileBusy
;		if error
;			process the error
;		endif
;	else
;		if Ambig and
;
;		call getabsn
;
;		if error
;			load error message
;			call DispMsg
;		else
;			do (until not Ambig)
;				call open_file
;				if error
;					do error handling
;				else
;					close file
;					submit packet
;					if error
;						set up message
;					endif
;				endif
;				if error
;					call Dispmsg
;				endif
;			leave if error
;				if Ambig
;					call Absn2 (will set fail if at end)
;				else
;					set fail
;				endif
;			enddo on fail
;			if no message
;				reset fail
;			endif
;		endif
;	endif
;	.
;	.
;	.
;	if error message
;		call DispMsg
;	endif
;
;	ret
;
;	END
;
;******************** END   - PSEUDOCODE ***************************************

   Submit_File PROC NEAR

   ASSUME ds:DG,es:DG

   nop					; for production - uncomment this line and comment the next
;  int 3
   nop

   cmp	[PInst],0			; has print been installed?

;  $if	e				; if not .....			       ;AC000;
   JNE $$IF81

       call Set_Buffer			; ... better do it now		       ;AC000;

;  $endif				; endif - installed		       ;AC000;
$$IF81:

   cld					; just in case...
   mov	[Ambig],0			; assume not an ambigous file

					;------------------------------------
					;    Check for drive specifier
					;------------------------------------

   mov	si,P_PTR_L			;				       ;AC000;
   mov	ax,P_PTR_H			;				       ;AC000;
   mov	ds,ax

   ASSUME ds:nothing

   mov	di,offset dg:NameBuf		; buffer for full file name
   cmp	byte ptr [si+1],":"		; check if there is a drive designator

;  $if	ne				; if no :			       ;AC000;
   JE $$IF83

       mov  ah,Get_Default_Drive	; get it...
       int  21h
       mov  dl,al			; save for later (used in DoPath)
       inc  dl				; adjust to proper code (A=1,B=2,...)
       add  al,"A"			; conver to letter code
       stosb				; store letter code
       mov  al,":"
       stosb
       clc				; clear error flag		       ;AC000;

;  $else				; else - theres a drive 	       ;AC000;
   JMP SHORT $$EN83
$$IF83:

       mov  al,byte ptr [si]		; get drive letter
       sub  al,"@"			; conver to proper code...

;      $if  a				; if a valid drive		       ;AC000;
       JNA $$IF85

	   mov	dl,al			; save for later (used in DoPath)
	   movsb			; move the drive letter
	   movsb			; move the ":"
	   clc				;				       ;AC000;

;      $else				;				       ;AC000;
       JMP SHORT $$EN85
$$IF85:

	   mov	ax,(CLASS_B shl 8) + InvDrvMes ; set up error message	       ;AC000;
	   stc				; set error flag		       ;AC000;

;      $endif				;				       ;AC000;
$$EN85:

;  $endif				; endif - :			       ;AC000;
$$EN83:


					;------------------------------------
					; could have CF & message # here
					;------------------------------------
;  $if	nc				; if no error so far		       ;AC000;
   JC $$IF89

					;------------------------------------
					;    Check for full path
					;------------------------------------
       mov  al,[PathChar]
       cmp  byte ptr [si],al		; does it start from the root?

;      $if  ne				; if not get the current path	       ;AC000;
       JE $$IF90

	   stosb			; store path character
	   push si
	   mov	si,di			; buffer for current directory
	   mov	ah,Current_Dir		; get current directory
	   int	21h

;	   $if	c			; if an error occures		       ;AC000;
	   JNC $$IF91

	       pop  si			; clear the stack

	       mov  ax,(CLASS_B shl 8) + InvDrvMes ; set up error message      ;AC000;

;	   $else			; else - no error so far	       ;AC000;
	   JMP SHORT $$EN91
$$IF91:


;	       $do			; find terminating nul		       ;AC000;
$$DO93:

		   lodsb
		   or	al,al

;	       $enddo z 		;				       ;AC000;
	       JNZ $$DO93

	       dec  si			; adjust to point to nul
	       mov  ax,di		; save pointer to beg. of path
	       mov  di,si		; here is were the file name goes
	       pop  si			; points to file name
	       cmp  ax,di		; if equal then file is in the root

;	       $if  ne			; if not, add a path char	       ;AC000;
	       JE $$IF95

		   mov	al,[PathChar]
		   stosb		; put path separator before file name

;	       $endif			;				       ;AC000;
$$IF95:
					;------------------------------------
					;    Check for valid drive.
					;------------------------------------

					; Done by getting current dir of
					; the drive in question (already in
					; DL) into NameBuf. If no error the
					; valid drive and we throw away the
					; current dir stuf by overwriting it
					; with the filename.

	       clc			; reset error flag		       ;AC000;

;	   $endif			;				       ;AC000;
$$EN91:

;      $else				; else - it starts from the root       ;AC000;
       JMP SHORT $$EN90
$$IF90:
					; DL has drive number (from DrvFound)
	   push si
	   mov	si,di			; buffer for current directory
	   mov	ah,Current_Dir		; get current directory
	   int	21h
	   pop	si

;	   $if	c			;				       ;AC000;
	   JNC $$IF99

	       mov  ax,(CLASS_B shl 8) + InvDrvMes ;			       ;AC000;

;	   $endif			;				       ;AC000;
$$IF99:

;      $endif				;				       ;AC000;
$$EN90:

;  $endif				; endif errors			       ;AC000;
$$IF89:

					;------------------------------------
					; could have CF & message # here
					;------------------------------------

;  $if	nc				; if no error so far		       ;AC000;
   JC $$IF103

       mov  cx,MaxFileLen		; lets not overflow file name buffer
       mov  ax,di			; CX := MaxFileLen -
					;	long(&NameBuf - &PtrLastchar)
       sub  ax,offset dg:NameBuf	; size of the filename so far
       sub  cx,ax			; size left for the filename

;      $if  c				; if too long			       ;AC000;
       JNC $$IF104

	   mov	cx,1			; Set cx to Fall through to FNTooLong

;      $endif				;				       ;AC000;
$$IF104:

					; WHILE (Length(FileName) <= MaxFileLen)
;      $search				;	DO copy in the file name       ;AC000;
$$DO106:

	   lodsb
	   stosb
	   cmp	al,"*"

;	   $if	e,or			; if its ambigous - *,	or......       ;AC000;
	   JE $$LL107

	   cmp	al,"?"			;			       :

;	   $if	e			; if its ambigous - ?,	.......:       ;AC000;
	   JNE $$IF107
$$LL107:

	       mov  [Ambig],1		;	ambigous filename found

;	   $endif			; endif - ambigous		       ;AC000;
$$IF107:

	   or	al,al			;	end of name?
	   clc				;				       ;AC000;

;      $exitif z			;				       ;AC000;
       JNZ $$IF106

;      $orelse				;				       ;AC000;
       JMP SHORT $$SR106
$$IF106:

;      $endloop loop			;				       ;AC000;
       LOOP $$DO106

	   dec	di			; the name was too long !
	   mov	[NulPtr],di
	   mov	ax,(CLASS_C shl 8) + NamTMes ;				       ;AC000;
	   stc				;				       ;AN010;

;      $endsrch 			; we have the full absolute name...    ;AC000;
$$SR106:


;  $endif				; endif errors			       ;AC000;
$$IF103:

   push cs				; restore ds to DG
   pop	ds

   ASSUME ds:DG

					;------------------------------------
					; could have CF & message #
					;------------------------------------
;  $if	nc,long 			;				       ;AC000;
   JNC $$XL2
   JMP $$IF114
$$XL2:

       dec  di
       mov  [NulPtr],di 		; save pointer to termanting nul

					;------------------------------------
					;    check for an option following name
					;------------------------------------
       call Parse_Input 		;				       ;AC000;

       cmp  ax,noerror			;  a parse error?		       ;AC000;

;      $if  e				; if no parse error		       ;AC000;
       JNE $$IF115


	   cmp	[P_SYN],offset DG:C_SW_ptr ;  is it the cancel switch /C       ;AC000;

;	   $if	e			; if it is			       ;AC000;
	   JNE $$IF116

	       mov  [CanFlag],1 	; set cancel flag

;	   $else			; else - it is not		       ;AC000;
	   JMP SHORT $$EN116
$$IF116:

	       cmp  [P_SYN],offset DG:P_SW_ptr ;  is it the print switch /P    ;AC000;

;	       $if  e			; if it is			       ;AC000;
	       JNE $$IF118

		   mov	[CanFlag],0	; reset cancel flag

;	       $endif			;				       ;AC000;
$$IF118:

;	   $endif			;				       ;AC000;
$$EN116:

;	   $if	e			; if /C or /P found		       ;AC000;
	   JNE $$IF121

	       mov  [ordinal],cx	;				       ;AC000;
	       mov  [scan_ptr],si	;				       ;AC000;

;	   $endif			;				       ;AC000;
$$IF121:

;      $endif				;				       ;AC000;
$$IF115:
					;--------------------------------------
					;------------------------------------
					;    check file exists
					;------------------------------------

       cmp  [CanFlag],1 		; are we in cancel mode

;      $if  e				; if cancel mode		       ;AC000;
       JNE $$IF124
					;------------------------------------
					;     Issue a cancel command
					;------------------------------------

					; NOTE: ds:dx MUST point to NameFuf !!!

					; set up cancel
	   mov	dx,offset dg:NameBuf	; filename
	   mov	ax,0102H
	   call IntWhileBusy

;	   $if	c			;				       ;AC000;
	   JNC $$IF125

	       cmp  ax,2

;	       $if  ne			; Original Print Code timing jump      ;AC000;
	       JE $$IF126
					;------------------------------------
					;***** PROCESS CANCEL ERROR
					;------------------------------------
;	       $endif			;				       ;AC000;
$$IF126:

	       mov  ax,(CLASS_C shl 8) + BadCanMes ;			       ;AC000;
	       stc			;				       ;AC000;

;	   $endif			;				       ;AC000;
$$IF125:

;      $else long			; submit mode active		       ;AC000;
       JMP $$EN124
$$IF124:

	   cmp	[Ambig],1		; is this an ambigous name?

;	   $if	e,and			; if it is ambigous		       ;AC000;
	   JNE $$IF130

					; do another ambigous name
	   call GetAbsN 		; get abs name into NameBuf

;	   $if	c			; if an error occured		       ;AC000;
	   JNC $$IF130

	       mov  ax,(CLASS_C shl 8) + BadNameMes ;			       ;AC000;
	       call DispMsg		; call DispMsg			       ;AN000;

;	   $else long			; there is at least 1 name	       ;AC000;
	   JMP $$EN130
$$IF130:

;	       $do			; until all names processed	       ;AC000;
$$DO132:

					; Check if this is a local drive -
					;    If it is, convert the filename
					;    to its physical name.

		   lea	si,NameBuf	; DS:SI = NameBuf containing name      ;AN010;
		   mov	bl,ds:[si]	; get DRIVE ID			       ;AN010;
		   sub	bl,40h		; convert to a number		       ;AN010;
					; IOCtl call to see if target drive is local
		   mov	ax,(IOCTL SHL 8) + 9 ;AN010;
		   INT	21h		; IOCtl + dev_local  <4409>	       ;AN010;

;		   $if	nc,and		; target drive local and	       ;AN010;
		   JC $$IF133

		   test dx,1200H	; check if (x & 0x1000) 	       ;AN010;
					;      (redirected or shared)
;		   $if	z,and		; if RC indicates NO network drive     ;AN010;
		   JNZ $$IF133

					; Translate the file name into an
					; absolute path name - note that
					; from this point on only SERVER DOS
					; calls will work with this name!

		   lea	di,TokBuf	; DS:DI = output buffer 	       ;AN010;
		   mov	ax,(xNameTrans SHL 8) ; check for name translation     ;AN010;
		   int	21h		; get real path and name	       ;AN010;

;		   $if	nc		; if no errors so far		       ;AN010;
		   JC $$IF133

		       xchg di,si	; switch source and destination        ;AN010;
		       mov  cx,((MaxFileLen+16)/2) ; move Max buffer	       ;AN010;
		       cld		;AN010;
		       rep  movsw	; move name back into NameBuf	       ;AN010;

;		   $endif		;				       ;AN010;
$$IF133:
					; set up to open file
		   xor	cx,cx		; zero attribute type		       ;AC000;
		   mov	di,cx		;				       ;AC001;
		   dec	di		; no list supplied		       ;AC001;
		   mov	dx,(ignore_cp shl 8) + (failopen shl 4) + openit ;     ;AC001;
		   mov	open_seg,es	; segment fix up for OPEN_FILE	       ;AC000;
		   lds	si,OPEN_FILE	;				       ;AC001;
		   mov	bx,open_mode	; set open mode 		       ;AC000;
		   mov	ah,ExtOpen	; open for reading exist.	       ;AN010;
		   mov	al,ds:[si]	; recover drive ID		       ;AN010;

		   call TO_DOS		; make a SERVER DOS call	       ;AC010;

;		   $if	c		; if error			       ;AC000;
		   JNC $$IF135

					; do error handling
		       SaveReg <SI,DI,BP,ES,DS>

		       mov  ah,GetExtendedError
		       int  21h
		       mov  ah,DOS_error

		       RestoreReg <DS,ES,BP,DI,SI>
		       stc		;				       ;AC000;

;		   $else		;				       ;AC000;
		   JMP SHORT $$EN135
$$IF135:
					; close file
		       mov  bx,ax	; copy handle
		       mov  ah,close
		       int  21h 	;
		       clc		; clear error flag		       ;AC000;

					; submit packet
		       mov  dx,offset dg:NameBuf ;
		       mov  word ptr [SubPack+1],dx ; store pointer to name in
		       mov  word ptr [SubPack+3],ds ;  submit packet
		       mov  dx,offset dg:SubPack ; DS:DX address of packet
		       mov  ax,0101H	; submit a file to resident
		       call IntWhileBusy

;		       $if  nc,and	; if successfull, or		       ;AC000;
		       JC $$IF137

		       cmp  ax,error_queue_full

;		       $if  ne		; if error but queue not full	       ;AC000;
		       JE $$IF137

			   mov	[QFullMes],0 ; queue is not full
			   clc		; reset the error flag		       ;AC000;

;		       $else		; else - the queue IS full	       ;AC000;
		       JMP SHORT $$EN137
$$IF137:

			   cmp	[QFullMes],1 ; has the message already been issued?

;			   $if	ne	; if the message has not been posted   ;AC000;
			   JE $$IF139

			       mov  [QFullMes],1 ; set the 'message posted' flag
			       mov  ax,(CLASS_B shl 8) + FullMes ; load msg #  ;AC000;
			       stc	; display the message		       ;AC000;
;			   $else
			   JMP SHORT $$EN139
$$IF139:
			       clc	; make sure carry clear
;			   $endif	; message processed		       ;AC000;
$$EN139:

;		       $endif		; queue errors			       ;AC000;
$$EN137:

;		   $endif		; OPENing errors		       ;AC000;
$$EN135:

;		   $if	c		; if error			       ;AC000;
		   JNC $$IF144

		       call DispMsg	; display the error with this file     ;AC000;

;		   $endif		;				       ;AC000;
$$IF144:

;	       $leave c 		; quit if error in displaying message  ;AC000;
	       JC $$EN132

		   cmp	[Ambig],1	; are we processing an ambigous name?

;		   $if	e		; if Ambiguous			       ;AC000;
		   JNE $$IF147
					; call Absn2 (will set fail if at end)
		       call GetAbsN2	; get another file name

;		   $else		;				       ;AC000;
		   JMP SHORT $$EN147
$$IF147:

		       mov  ax,0	; set fail			       ;AC000;
		       stc		;				       ;AC000;

;		   $endif		;				       ;AC000;
$$EN147:

;	       $enddo c,long		; end do on fail		       ;AC000;
	       JC $$XL3
	       JMP $$DO132
$$XL3:
$$EN132:

	       cmp  ax,0		; is there a message?		       ;AC000;

;	       $if  e			; if no message 		       ;AC000;
	       JNE $$IF151

		   clc			; reset fail			       ;AC000;

;	       $endif			; no message to display 	       ;AC000;
$$IF151:

;	   $endif			; any submission errors 	       ;AC000;
$$EN130:

;      $endif				; submit or cancel		       ;AC000;
$$EN124:

;  $endif				; any errors so far		       ;AC000;
$$IF114:

;  $if	c				; if error			       ;AC000;
   JNC $$IF156

       call DispMsg			; display the submit error	       ;AC000;

;  $endif				;				       ;AC000;
$$IF156:

   ret					; finished submission		       ;AC000;

   Submit_File ENDP

   BREAK <Set_Buffer>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	Set_Buffer  -  PRINT Build Resident Buffer routine.
;
;  FUNCTION:	Calculate the buffer size required by the resident component and
;		move the transient portion accordingly
;
;  NOTE:	This code is primarily old code, but it has been partly
;		restructured in order to SALUT it.
;
;  INPUT:	None.
;
;  OUTPUT:	Resident Buffer established, and TRANSIENT moved accordingly.
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	Called from: TRANSIENT
;
;  NORMAL	-
;  EXIT:
;
;  ERROR	-
;  EXIT:
;
;  EXTERNAL	Calls to:  DispMsg,  Parse_Input
;  REFERENCES:
;
;  CHANGE	03/11/87 - Change SETBUF to Set_Buffer	 - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	 START
;	 END
;
;******************** END   - PSEUDOCODE ***************************************

   Set_Buffer PROC NEAR

   push cs
   pop	ds
   assume ds:DG
   mov	dl,[PathChar]			; transfer PathChar (in PRINT_T)
   mov	ax,CodeR
   mov	es,ax
   assume es:CodeR
   mov	[PChar],dl			; to PChar (in PRINT_R)


					;------------------------------------
					;    check device
					;------------------------------------

   cmp	[DevSpec],1			; was it already specified?

;  $if	ne,and				; if not specified ...........	       ;AC000;
   JE $$IF158

   lea	di,TokBuf			; ES:DI point to TokBuf      :	       ;AC000;
   mov	[TokBuf],9			; max of 9 chars	     :
   mov	[TokBuf+1],0			; assume zero in	     :

   push es				;				       ;AC000;
   mov	ax,ds				;				       ;AC000;
   mov	es,ax				;				       ;AC000;

   assume es:DG 			;				       ;AC000;

   mov	ax,(CLASS_D shl 8) + prompt	; DispMsg treats 'prompt' as :	       ;AC000;
					;	a special case	     :
   call DispMsg 			;			     :	       ;AC000;

   mov	ax,(CLASS_B shl 8) + NEXT_LINE	; advance to next line after :	       ;AC000;
					;	"buffered input" call:
   call DispMsg 			;			     :	       ;AC000;

   pop	es				;				       ;AC000;

   assume es:CodeR

   mov	cl,[TokBuf+1]			; check how many read in     :
   or	cl,cl				;			     :

;  $if	nz				; if a CR was typed..........:	       ;AC000;
   JZ $$IF158

       xor  ch,ch
       mov  si,offset dg:TokBuf+2
       mov  di,offset CodeR:ListName
       push si
       mov  dx,si			; get ready to capitalize	       ;AN007;
       add  si,cx
       mov  byte ptr [si],0		; turn it into an ascii z string       ;AN007;
       mov  ax,(GetExtCntry SHL 8) + Cap_ASCIIZ ; let DOS capitalize the string ;AN007;
       INT  21h 			; call DOS to do it		      ;AN007;
       dec  si
       cmp  byte ptr [si],':'

;      $if  e				; if a :			       ;AC000;
       JNE $$IF159
	   dec	cx			; get rid of trailing ':'
;      $endif				; endif - a :			       ;AC000;
$$IF159:

       cmp  cx,8			; is it greater than 8 ?	       ;AN000;

;      $if  a				; if greater - force it to 8.:	       ;AC000;
       JNA $$IF161

	   mov	cx,8			;				       ;AN000;

;      $endif				;				       ;AC000;
$$IF161:

       pop  si

       rep  movsb			;				       ;AC000;

;  $endif				;				       ;AC000;
$$IF158:
					;------------------------------------
					;    queue size
					;------------------------------------
   push es
   pop	ds

   ASSUME ds:CodeR

   mov	ax,MaxFileLen			; maximum length of a file name
   mul	[QueueLen]			; AX = result
   add	ax,offset CodeR:FileQueue
   mov	[EndQueue],ax			; save pointer to last nul
   inc	ax
   mov	[buffer],ax			; beggining of buffer

					;------------------------------------
					;--- buffer size
					;------------------------------------

   add	ax,[BlkSiz]
   mov	[ENDPTR],AX			; Set end of buffer pointer
   mov	[NXTCHR],AX			; Buffer empty
   add	ax,100h 			; allow for header
   add	ax,16				; Convert to para
   shr	ax,1
   shr	ax,1
   shr	ax,1
   shr	ax,1
   mov	[EndRes],ax			; Add size of buffer to term res size

					; Now JUMP into PRINT_R - the resident
   jmp	MoveTrans			;   code to initialize the buffer space

TransRet:				; after moving the transient we come
					;  here.
   sti					; Ints were off during initialization
   push cs				; CAUTION !!!! from here on in DG is
   pop	ax				;  not the ASSEMBLED DG - its bogus -
   mov	ds,ax				;  after the move! Only PUSH/POP will
   mov	es,ax				;  work.
   mov	WORD PTR [insert_ptr_seg],ax	; fix up segment in SUBLIST for msgs!  ;AC002;
   mov	WORD PTR [P_PTR_H],ax		; fix up segment for PARSE	       ;AC002;

   ASSUME ds:DG,es:DG


   call SYSLOADMSG			; RE-Initialize the Message Services   ;AN016;
					;  - WARNING!!! the Message retriver
					;    keeps track of offset and SEGMENT
					;    for extended and parse errors
					;    EVEN THOUGH WE ARE NEAR!!!  since
					;    the location could now have been
					;    moved - it must now be reset

					;------------------------------------
					;   normalize int handlers for new location of dg
					;------------------------------------

   mov	ax,(SET_INTERRUPT_VECTOR shl 8) or 23h
   mov	dx,OFFSET DG:INT_23
   int	21h
   mov	ax,(SET_INTERRUPT_VECTOR shl 8) or 24h
   mov	dx,OFFSET DG:INT_24
   int	21h

   mov	[PInst],1			; remember we just installed resident part

   ret					; finished			       ;AC000;

   Set_Buffer ENDP

   BREAK <copy_to_arg_buf>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:     copy_to_arg_buf
;
;  FUNCTION: Copies the names of the files in the print queue into NameBuf
;		- one name copied per invocation
;
;  INPUT:
;
;  OUTPUT:
;
;
;  REGISTERS USED: T.B.D.
;
;  LINKAGE:	Called from:
;
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START copy_to_arg_buf
;
;	ret
;
;	END copy_to_arg_buf
;
;******************** END   - PSEUDOCODE ***************************************

   copy_to_arg_buf PROC NEAR

   push di
   push si
   push ax				; must preserve AX (could be message #);AN000;
   mov	di,offset dg:NameBuf

;  $do					;				       ;AC000;
$$DO164:

       lodsb
       or   al,al

;  $leave z				;				       ;AC000;
   JZ $$EN164

       stosb

;  $enddo				;				       ;AC000;
   JMP SHORT $$DO164
$$EN164:

   stosb
   pop	ax				; must preserve AX (could be message #);AN000;
   pop	si
   pop	di

   ret

   copy_to_arg_buf ENDP

   BREAK <IntWhileBusy>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	IntWhileBusy
;
;  FUNCTION:
;
;  INPUT:
;
;  OUTPUT:
;
;
;  REGISTERS USED: T.B.D.
;
;  LINKAGE:	Called from:
;
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START IntWhileBusy
;
;	ret
;
;	END IntWhileBusy
;
;******************** END   - PSEUDOCODE ***************************************

   IntWhileBusy PROC NEAR

;  $search complex			;				       ;AC000;
   JMP SHORT $$SS167
$$DO167:

       pop  ax

;  $strtsrch				;				       ;AC000;
$$SS167:

       push ax
       int  ComInt

;  $exitif nc				;				       ;AC000;
   JC $$IF167

       add  sp,2			; clear off AX and clear carry

;  $orelse				;				       ;AC000;
   JMP SHORT $$SR167
$$IF167:

       cmp  ax,error_busy

;  $leave nz				;				       ;AC000;
   JNZ $$EN167

;  $endloop				;				       ;AC000;
   JMP SHORT $$DO167
$$EN167:

       add  sp,2			; clear off AX
       stc				;				       ;AC000;

;  $endsrch				;				       ;AC000;
$$SR167:

   ret

   IntWhileBusy ENDP

   BREAK <GetAbsN>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	GetAbsN
;
;  FUNCTION:	Return first absolute name from ambigous name
;
;  INPUT:	NameBuf has the ambigous File Name
;
;  OUTPUT:	Carry Set if no files match
;		else NameBuf has the absolute name
;
;  REGISTERS USED: T.B.D.
;
;  LINKAGE:	Called from:
;
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START GetAbsN
;
;	ret
;
;	END GetAbsN
;
;******************** END   - PSEUDOCODE ***************************************

   GetAbsN PROC NEAR

   ASSUME ds:DG,es:DG

   mov	ah,Set_DMA			; buffer for ffirst / fnext
   mov	dx,offset dg:SearchBuf
   int	21h
					;------------------------------------
					;    look for a match
					;------------------------------------
   mov	dx,offset dg:NameBuf
   mov	cx,0				; no attributes
   mov	ah,Find_First
   int	21h

;  $if	nc				; if no error			       ;AC000;
   JC $$IF174

					;------------------------------------
					;    Place new name in NameBuf
					;------------------------------------
       mov  si,[NulPtr]
       std				; scan back

;      $do				;				       ;AC000;
$$DO175:

	   lodsb
	   cmp	al,PathChar

;      $enddo e 			;				       ;AC000;
       JNE $$DO175

       cld				; just in case...
       inc  si
       inc  si
       mov  [FnamPtr],si
       call CopyName
       clc				;				       ;AC000;

;  $endif				; endif -no error		       ;AC000;
$$IF174:

   ret

   GetAbsN ENDP

   BREAK <GetAbsN2>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	GetAbsN2
;
;  FUNCTION:	Return next absolute name from ambigous
;
;  INPUT:
;
;  OUTPUT:
;
;  REGISTERS USED: T.B.D.
;
;  LINKAGE:	Called from:
;
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START GetAbsN2
;
;	ret
;
;	END GetAbsN2
;
;******************** END   - PSEUDOCODE ***************************************

   GetAbsN2 PROC NEAR

   mov	ah,Set_DMA			; buffer for ffirst / fnext
   mov	dx,offset dg:SearchBuf
   int	21h
   mov	ah,Find_Next
   int	21h

;  $if	nc				; if no error			       ;AC000;
   JC $$IF178

       call CopyName			; we found one
       clc				;				       ;AC000;

;  $endif				; endif - no error		       ;AC000;
$$IF178:

   mov	ax,0				; signal no message available

   ret					; return

   GetAbsN2 ENDP

   BREAK <CopyName>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	CopyName
;
;  FUNCTION:	Copy name from search buf to NameBuf
;
;  INPUT:
;
;  OUTPUT:
;
;  REGISTERS USED: T.B.D.
;
;  LINKAGE:	Called from:
;
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START CopyName
;
;	ret
;
;	END CopyName
;
;******************** END   - PSEUDOCODE ***************************************

   CopyName PROC NEAR

   mov	di,[FNamPtr]
   mov	si,offset dg:SearchBuf.find_buf_pname
   cld

;  $do					; until null is found		       ;AC000;
$$DO180:

       lodsb				; move the name
       stosb
       or   al,al			; nul found?

;  $enddo e				;				       ;AC000;
   JNE $$DO180

   ret

   CopyName ENDP

   BREAK <Save_Vectors>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	 Save_Vectors
;
;  FUNCTION:	 save int vectors in case of error
;
;  INPUT:
;
;  OUTPUT:
;
;  REGISTERS USED: T.B.D.
;
;  LINKAGE:	Called from:
;
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START Save_Vectors
;
;	ret
;
;	END Save_Vectors
;
;******************** END   - PSEUDOCODE ***************************************

   Save_Vectors PROC NEAR

   mov	ax,(get_interrupt_vector shl 8) or SOFTINT ; (SOFTINT)
   int	21h

   ASSUME es:nothing

   mov	word ptr [i28vec+2],es
   mov	word ptr [i28vec],bx

   mov	ax,(get_interrupt_vector shl 8) or COMINT ; (COMINT)
   int	21h
   mov	word ptr [i2fvec+2],es
   mov	word ptr [i2fvec],bx

   mov	ax,(get_interrupt_vector shl 8) or 13h
   int	21h
   mov	word ptr [i13vec+2],es
   mov	word ptr [i13vec],bx

   mov	ax,(get_interrupt_vector shl 8) or 15h
   int	21h
   mov	word ptr [i15vec+2],es
   mov	word ptr [i15vec],bx

   mov	ax,(get_interrupt_vector shl 8) or 17h
   int	21h
   mov	word ptr [i17vec+2],es
   mov	word ptr [i17vec],bx

   mov	ax,(get_interrupt_vector shl 8) or 14h
   int	21h
   mov	word ptr [i14vec+2],es
   mov	word ptr [i14vec],bx

   mov	ax,(get_interrupt_vector shl 8) or 05h
   int	21h
   mov	word ptr [i05vec+2],es
   mov	word ptr [i05vec],bx

   mov	ax,(get_interrupt_vector shl 8) or INTLOC ; (INTLOC)
   int	21h
   mov	word ptr [i1cvec+2],es
   mov	word ptr [i1cvec],bx

   push cs
   pop	es

   ASSUME es:DG

   Save_Vectors ENDP

   BREAK <GetHInt>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	GetHInt
;
;  FUNCTION:	Install PRINT Interupt Handler routines
;
;  INPUT:
;
;  OUTPUT:
;
;  REGISTERS USED: T.B.D.
;
;  LINKAGE:	Called from: TRANSIENT,
;
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START GetHInt
;
;	ret
;
;	END GetHInt
;
;******************** END   - PSEUDOCODE ***************************************

   GetHInt PROC NEAR

   ASSUME ds:DG,es:DG

   push es
   mov	ax,(GET_INTERRUPT_VECTOR shl 8) OR 24h
   int	21h

   ASSUME es:nothing

   mov	WORD PTR [HARDCH],bx
   mov	WORD PTR [HARDCH+2],es
   pop	es

   ASSUME es:DG

   ret

   GetHInt ENDP

   BREAK <SetInts>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	SetInts
;
;  FUNCTION:	Install PRINT Interupt Handler routines
;
;  INPUT:
;
;  OUTPUT:
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	Called from: TRANSIENT,
;
;  NORMAL
;  EXIT:
;
;  ERROR
;  EXIT:
;
;  EXTERNAL
;  REFERENCES:
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START SetInts
;
;	ret
;
;	END SetInts
;
;******************** END   - PSEUDOCODE ***************************************

   SetInts PROC NEAR

   ASSUME ds:DG,es:DG

   mov	AX,(SET_INTERRUPT_VECTOR shl 8) OR 23h
   mov	DX,OFFSET DG:INT_23
   int	21h

   mov	ax,(SET_INTERRUPT_VECTOR shl 8) OR 24h
   mov	dx,OFFSET DG:INT_24
   int	21h

   ret

   SetInts ENDP

   BREAK <Int_24>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	Int_24
;
;  FUNCTION:	INT 24 handler
;
;  INPUT:
;
;  OUTPUT:
;
;  NOTE:	This is coded as a PROC but is never called
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	INTerupt 24
;
;  NORMAL
;  EXIT:
;
;  ERROR
;  EXIT:
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START Int_24
;
;	ret
;
;	END Int_24
;
;******************** END   - PSEUDOCODE ***************************************


INT_24_RETADDR DW OFFSET DG:INT_24_BACK

in_int_23 db 0				; reentrancy flag


   INT_24 PROC FAR

   ASSUME ds:nothing,es:nothing,ss:nothing

   pushf
   push cs
   push [INT_24_RETADDR]
   push WORD PTR [HARDCH+2]
   push WORD PTR [HARDCH]

   ret

   INT_24 ENDP

   BREAK <INT_24_BACK>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	INT_24_BACK
;
;  FUNCTION:	INT 24 post processor
;
;  INPUT:
;
;  OUTPUT:
;
;  NOTE:	This is NOT a PROC
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	INTerupt 24
;
;  NORMAL
;  EXIT:
;
;  ERROR
;  EXIT:
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START INT_24_BACK
;
;	ret
;
;	END INT_24_BACK
;
;******************** END   - PSEUDOCODE ***************************************

INT_24_BACK:

   cmp	al,2				; Abort?

;  $if	z				; if abort			       ;AC000;
   JNZ $$IF182

       inc  [in_int_23] 		; no int 23's allowed
       push cs
       pop  ds

       ASSUME ds:DG

       push cs
       pop  ss

       ASSUME ss:DG

       mov  sp, offset dg:intStk	; setup local int stack
       cmp  [PInst],2

;      $if  ne				; if not installed		       ;AC000;
       JE $$IF183

	   call Restore_ints

;      $endif				; endif - not installed 	       ;AC000;
$$IF183:

       mov  ah,EXIT
       mov  al,0FFH
       int  21h

;  $endif				; endif - abort
$$IF182:

   IRET

   BREAK <Int_23>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	Int_23
;
;  FUNCTION:	INT 23 handler
;
;  INPUT:
;
;  OUTPUT:
;
;  NOTE:	This is NOT a PROC
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	INTerupt 23
;
;  NORMAL
;  EXIT:
;
;  ERROR
;  EXIT:
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START Int_23
;
;	ret
;
;	END Int_23
;
;******************** END   - PSEUDOCODE ***************************************

INT_23:

   ASSUME ds:nothing,es:nothing,ss:nothing

   cmp	[in_int_23],0			; check for a re-entrant call

;  $if	e				; If its OK			       ;AC000;
   JNE $$IF186

       inc  [in_int_23] 		; make sure no more int 23's
       push cs
       pop  ds

       ASSUME ds:DG

       push cs
       pop  ss

       ASSUME ss:DG

       mov  sp, offset dg:intStk	; setup local int stack
       cmp  [PInst],2

;      $if  ne				; if not installed - undo	       ;AC000;
       JE $$IF187

	   call Restore_ints		;				       ;AC000;

;      $else				; else - dont undo		       ;AC000;
       JMP SHORT $$EN187
$$IF187:

	   mov	ax,0105H
	   call IntWhileBusy		; unlock print queue (just in case)

;      $endif				; endif - undo			       ;AC000;
$$EN187:

       mov  ah,EXIT
       mov  al,0FFH
       int  21h

;  $endif				; endif - its OK		       ;AC000;
$$IF186:

   iret 				;

   BREAK <Restore_ints>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	Restore_ints
;
;  FUNCTION:	Restore all ints used by print to original values
;
;  INPUT:
;
;  OUTPUT:
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	Called from: TRANSIENT,
;
;  NORMAL
;  EXIT:
;
;  ERROR
;  EXIT:
;
;  EXTERNAL
;  REFERENCES:
;
;  CHANGE	05/20/87 - Header added       - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START Restore_ints
;
;	ret
;
;	END Restore_ints
;
;******************** END   - PSEUDOCODE ***************************************

   Restore_ints PROC NEAR

   ASSUME ds:DG,es:nothing,ss:DG

   cli
   mov	ax,(set_interrupt_vector shl 8) or SOFTINT ; (SOFTINT)
   push ds
   lds	dx,[i28vec]
   int	21h
   pop	ds

   mov	ax,(set_interrupt_vector shl 8) or COMINT ; (COMINT)
   push ds
   lds	dx,[i2fvec]
   int	21h
   pop	ds

   mov	ax,(set_interrupt_vector shl 8) or 13h
   push ds
   lds	dx,[i13vec]
   int	21h
   pop	ds

   mov	ax,(set_interrupt_vector shl 8) or 15h
   push ds
   lds	dx,[i15vec]
   int	21h
   pop	ds

   mov	ax,(set_interrupt_vector shl 8) or 17h
   push ds
   lds	dx,[i17vec]
   int	21h
   pop	ds

   mov	ax,(set_interrupt_vector shl 8) or 14h
   push ds
   lds	dx,[i14vec]
   int	21h
   pop	ds

   mov	ax,(set_interrupt_vector shl 8) or 05h
   push ds
   lds	dx,[i05vec]
   int	21h
   pop	ds

   mov	ax,(set_interrupt_vector shl 8) or INTLOC ; (INTLOC)
   push ds
   lds	dx,[i1cvec]
   int	21h
   pop	ds
   sti

   ret

   Restore_ints ENDP


   BREAK <Parse_Input>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	Parse_Input  -	PRINT Command Line Parser
;
;  FUNCTION:	Call the DOS PARSE Service Routines to process the command
;		line. Search for valid input:
;			 - filenames (may be more than one
;			 - switches: /D:device
;				     /B:buffsize  512 to 16k - 512 default
;				     /Q:quesiz	    4 to 32  -	10 default
;				     /S:timeslice   1 to 255 -	 8 default
;				     /U:busytick    1 to 255 -	 1 default
;				     /M:maxtick     1 to 255 -	 2 default
;				     /T    terminate
;				     /C    cancel
;				     /P    print
;
;  INPUT:	Current Parse parameters in the Parse_C_B
;		      [ORDINAL]  -  CURRENT ORDINAL VALUE
;		      [SCAN_PTR] -  CURRENT SCAN POINT
;				 -  DS:[SCAN_PTR] - Pionter to Parse string
;		ES:DI - Pointer to PARMS block
;
;  OUTPUT:	PARSE_BUFF filled in:
;
;		     P_TYPE	  - TYPE RETURNED
;		     P_ITEM_TAG   - SPACE FOR ITEM TAG
;		     P_SYN	  - POINTER TO LIST ENTRY
;		     P_PTR_L	  - SPACE FOR POINTER / VALUE - LOW
;		     P_PTR_H	  - SPACE FOR POINTER / VALUE - HIGH
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	Called from: TRANSIENT, Set_Buffer and Submit_File
;
;  NORMAL	CF = 0
;  EXIT:
;
;  ERROR	CF = 1 If user enters:
;  EXIT:		   - any invalid parameter or switch
;			   - an invalid value for a valid switch
;		AX = Parse error number
;
;  EXTERNAL	- System parse service routines
;  REFERENCES:
;
;  CHANGE	03/11/87 - First release      - F. G.
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	 START
;	 END
;
;******************** END   - PSEUDOCODE ***************************************

   Parse_Input PROC NEAR

Syntax_Error equ 9			; Parse syntax error
Parse_EOL equ 0FFh			; Parse End Of Line
					;--------------------------------------
					;  Load appropriate registers
					;     from the Parse_Control_Block
					;--------------------------------------
   ASSUME ds:DG,es:DG,ss:nothing

   mov	cx,[ORDINAL]			; CURRENT ORDINAL VALUE 	       ;AN000;
   mov	si,[SCAN_PTR]			; CURRENT SCAN POINT		       ;AN000;
   mov	[MSG_PTR],si			; Save start in case of error	       ;AN000;
   lea	di,PARMS			;				       ;AN000;
   mov	dx,0				; RESERVED			       ;AN000;
   push ds				;				       ;AN000;
   mov	ax,CodeR			;				       ;AN000;
   sub	ax,10h				; back up 100h to start of psp	       ;AN000;
   mov	ds,ax				; DS:SI  = command string in PSP       ;AN000;

					;--------------------------------------
   ASSUME ds:nothing			;  Call the Parse service routines
					;--------------------------------------

					; CX	- Ordinal value
					; DX	- zero (reserved)
					; DS:SI - Pionter to Parse string
					; ES:DI - Pointer to PARMS block

   call SYSPARSE			; PARSE IT!			       ;AN000;

   pop	ds				;				       ;AN000;

   ASSUME ds:DG

   cmp	ax,NOERROR			; no errors?			       ;AN000;

;  $if	e				; if no errors			       ;AN000;
   JNE $$IF191

       clc				; WE'ER DONE                           ;AN000;

;  $else				; else - there was an error	       ;AN000;
   JMP SHORT $$EN191
$$IF191:

       cmp  al,Parse_EOL		; error FFh  ?			       ;AN000;

;      $if  ne				; if not EOL			       ;AN000;
       JE $$IF193

	   cmp	al,Syntax_Error 	; error 1 to 9 ?		       ;AN000;

;	   $if	a			; if parse error		       ;AN000;
	   JNA $$IF194

	       mov  al,Syntax_Error	; Parse syntax error

;	   $endif			; endif errors			       ;AN000;
$$IF194:

	   lea	bx,Parse_Ret_Code
	   xlat cs:[bx]

;      $endif				; endif errors			       ;AN000;
$$IF193:

       stc				; SET ERROR FLAG		       ;AN000;

;  $endif				; endif - no error		       ;AN000;
$$EN191:

   ret					; NORMAL RETURN TO CALLER	       ;AN000;

Parse_Ret_Code label byte

   db	0				; Ret Code 0 -			       ;AC003;
   db	9				; Ret Code 1 - Too many parameters     ;AC003;
   db	9				; Ret Code 2 - Required parameter msg  ;AC003;
   db	3				; Ret Code 3 - Invalid switch	       ;AC003;
   db	9				; Ret Code 4 - Invalid keyword	       ;AC003;
   db	9				; Ret Code 5 - (reserved)	       ;AC003;
   db	6				; Ret Code 6 - Parm val out of range   ;AC003;
   db	9				; Ret Code 7 - Parameter val not allow ;AC003;
   db	9				; Ret Code 8 - Parm format not correct ;AC003;
   db	9				; Ret Code 9 - Invalid Parameter       ;AC003;

   Parse_Input ENDP



   BREAK <DispMsg>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	DispMsg  -  PRINT Display Transient Message Routine
;
;  FUNCTION:	Display the transient messages for PRINT
;
;  INPUT:	Al = message number
;		Ah = class  - 0 - Message Service class
;			      1 - DOS extended error
;			      2 - Parse error
;			      A - PRINT_R message
;			      B - PRINT_T message
;			      C - PRINT_T message with insert
;							DS:SI = sublist
;			      D - PRINT_T message with input buffer where:
;							ES:DI = input buffer
;  OUTPUT:	- Messages output to Output Device
;
;  REGISTERS USED:  CX DX
;  (NOT RESTORED)
;
;  LINKAGE:	Call from  PRINT_R, TRANSIENT
;
;  NORMAL	-
;  EXIT:
;
;  ERROR	-
;  EXIT:
;
;  CHANGE	03/11/87 - First release      - F. G.
;  LOG: 	09/28/87 - move back to tranient - make 'NEAR'
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START DispMsg
;
;	point to SUBLIST
;	reset response	(DL)
;	set class to utility (DH)
;	reset insert  (CX)
;	set output handle (BX)
;	if CLASS requires insert
;		load insert required
;	endif
;	if CLASS requires response
;		flush keystroke buffer
;		load response required (Dir CON in no echo)
;	endif
;	if CLASS is not Utility
;		set CLASS
;	endif
;	call SysDispMsg to display message
;	if error
;		set class to DOS_error
;		set error flag
;	endif
;
;	ret
;
;	END DispMsg
;
;******************** END   - PSEUDOCODE ***************************************

   DispMsg PROC NEAR

   ASSUME CS:DG,DS:nothing,ES:nothing,SS:nothing

   push ds				;				       ;AN000;
   push si				;				       ;AN000;
   push cs				; called before and after relocation   ;AC002;
   pop	ds				;  - don't use DG                      ;AC002;

   ASSUME CS:DG,DS:DG,ES:nothing,SS:nothing

   lea	si,SUBLIST			; point to sublist		       ;AN000;
   xor	dx,dx				; reset response  (DL)		       ;AN000;
   dec	dh				;				       ;AN000;
   xor	cx,cx				; reset insert	(CX)		       ;AN000;
   mov	bx,STDOUT			; set output handle (BX)	       ;AC014;

   cmp	ah,CLASS_C			; is it CLASS C 		       ;AN000;

;  $if	e,or				; CLASS C requires insert	       ;AC012;
   JE $$LL198

   cmp	ah,DOS_Error			; is it a DOS error?		       ;AN012;

;  $if	e				; DOS requires insert		       ;AN012;
   JNE $$IF198
$$LL198:

       mov  cx,offset DG:NameBuf	; set up insert pointer to NameBuf     ;AN005;
       mov  insert_ptr_off,cx		;				       ;AN005;
       push cs				;				       ;AN005;
       pop  [insert_ptr_seg]		;				       ;AN005;
       cmp  ah,CLASS_C			;				       ;AC012;
;      $if  e,and			;				       ;AC012;
       JNE $$IF199
       cmp  al,BadNameMes		;				       ;AN010;
;      $if  b				;				       ;AN010;
       JNB $$IF199
	   mov	[insert_num],1		;				       ;AN005;
;      $else				;				       ;AN010;
       JMP SHORT $$EN199
$$IF199:
	   mov	[insert_num],0		;				       ;AN010;
;      $endif				;				       ;AN010;
$$EN199:
       mov  cx,1			; 1 parameter to replace	       ;AN005;

;  $endif				;				       ;AN000;
$$IF198:

   cmp	ah,CLASS_D			; is it CLASS D 		       ;AN000;

;  $if	e				; CLASS D requires response	       ;AN000;
   JNE $$IF203

					; flush keystroke buffer?
       mov  dl,buffered_input		; load response required (INT 21h 0A)  ;AN000;

;  $endif				;				       ;AN000;
$$IF203:

   cmp	ah,Parse_error

;  $if	be				; if Parse or DOS error
   JNBE $$IF205

       mov  dh,ah
       mov  bx,STDERR			; set output handle (BX)	       ;AN014;

;  $endif				;
$$IF205:

;  $if	e				; if it is a parse error - show them
   JNE $$IF207
					; what is wrong
       mov  cx,[MSG_PTR]		;  set up sublist offset	       ;AN005;
       mov  [insert_ptr_off],cx 	;				       ;AN005;
       mov  cx,CodeR			;  set up sublist segment (PSP)        ;AN005;
       sub  cx,10h			;				       ;AN005;
       mov  [insert_ptr_seg],cx 	;				       ;AN005;
       push si				;  save current pointer 	       ;AN005;
       push ds				;				       ;AN005;
       mov  si,[SCAN_PTR]		; point to end of bad parm	       ;AN005;
       mov  ds,cx			;				       ;AN005;
       mov  BYTE PTR ds:[si],0		; terminate the parameter	       ;AN005;
       pop  ds				;   restore current pointer	       ;AN005;
       pop  si				;				       ;AN005;
       mov  [insert_num],0		;				       ;AN005;
       mov  cx,1			; 1 parameter to replace	       ;AN005;

;  $endif
$$IF207:

   xor	ah,ah				;				       ;AN000;

   call SysDispMsg			; to display message		       ;AN002;

;  $if	c				; error ..................	       ;AN000;
   JNC $$IF209

       mov  ah,DOS_error		; load error exit code		       ;AN000;
       stc				; indicate failure		       ;AN000;

;  $endif				;				       ;AN000;
$$IF209:

   pop	si				;				       ;AN000;
   pop	ds				;				       ;AN000;

   ret					;				       ;AN000;

   DispMsg ENDP

   GoDispMsg PROC FAR

   call DispMsg 			; This allows long calls form CODER    ;AN000;

   ret					;				       ;AN000;

   GoDispMsg ENDP

   BREAK <Load_R_Msg>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	Load_R_Msg  -  PRINT Load  Resident Message Routine
;
;  FUNCTION:	Load the PRINT resident messages into their
;		current message buffer.  Note that PRINT 'pumps' the
;		error text out as part of the data stream.  For this reason
;		the message service code is NOT used to display RESIDENT messages.
;
;  INPUT:	Messages in PRINT_RM, and Message Retriver code in PRINT_TM.
;
;  OUTPUT:	Resident messages loaded into the resident message buffer
;		and Message Sevices code initalized
;
;  NOTE:	Messages ERRO through ERR12, ERRMEST through AllCan, FATMES
;		BADDDRVM, GOODMES and BADMES are used in place - whereever
;		the Message retriever points to them. BADDRVM is moved directly behind
;		FATMES.
;
;  REGISTERS USED:  DS:SI - points to message text
;  (NOT RESTORED)  (   AX - message # - not destroyed)
;		   (   DH - Class - not destroyed)
;
;  LINKAGE:	Call from TRANSIENT
;
;  NORMAL	CF = 0
;  EXIT:
;
;  ERROR	CF = 1
;  EXIT:	AX = error number
;
;  CHANGE	03/11/87 - First release      - F. G.
;  LOG: 	09/28/87 - P1175 - all resident messages must be moved
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	 START
;	 END
;
;******************** END   - PSEUDOCODE ***************************************

   Load_R_Msg PROC NEAR

					;--------------------------------------
					; Load the Resident Messages
					;--------------------------------------
   mov	ax,CodeR			;				       ;AN000;
   mov	es,ax				;				       ;AN000;

   ASSUME DS:nothing,ES:CodeR

   lea	di,R_MES_BUFF			; set destination to resident buffer   ;AN000;
   mov	bx,OFFSET CodeR:MESBAS		; use BX as an index to MESBAS (CodeR) ;AN000;

					;--------------------------------------
					; Move messages ERR0 thru ERR12
					;--------------------------------------

   mov	ax,ERR0 			; message # 19 to start 	       ;AN000;
   mov	dx,(DOS_error shl 8)		; Class is DOS error		       ;AN000;

;  $do					;				       ;AN000;
$$DO211:

       call MoveMes			; LOAD the message		       ;AN000;
;  $leave c				; leave loop if ERROR		       ;AN000;
   JC $$EN211
       mov  byte ptr es:[di],DOLLAR	; append a delimiter
       inc  di				; move to next message		       ;AN000;
       inc  al				; advance message #		       ;AN000;
       cmp  al,ERR12			; are we past ERR12 ?		       ;AN000;

;  $enddo a				; if not, do it again		       ;AN000;
   JNA $$DO211
$$EN211:

;  $if	nc				; if no ERROR			       ;AN000;
   JC $$IF214
					;--------------------------------------
					; Do rocessing for ERRMEST through
					;      BADDRVM
					;--------------------------------------

       mov  ax, errmest 		; message # 3 to start		       ;AN000;
       mov  dx,(CLASS_Util shl 8)	; Class is Utility		       ;AN000;

;      $do				; now we are past ERR12 	       ;AN000;
$$DO215:

	   call MoveMes 		; LOAD the message		       ;AC002;
;      $leave c 			; leave loop if ERROR		       ;AC002;
       JC $$EN215
	   inc	al			; advance message #		       ;AC002;
	   cmp	al,BADDRVM		; are we past BADDRVM		       ;AC002;

;      $enddo a 			;				       ;AN000;
       JNA $$DO215
$$EN215:

;  $endif				; endif - no error		       ;AN000;
$$IF214:

   push cs				;				       ;AN000;
   pop	es				;				       ;AN000;
   push cs				;				       ;AN000;
   pop	ds				;				       ;AN000;

   ASSUME DS:DG,ES:DG

   ret					;				       ;AN000;

   Load_R_Msg ENDP
					;--------------------------------------
					; Move the Messages into their
					;	final resting place
					;--------------------------------------
MoveMes PROC NEAR

   mov	es:[bx],di			; save the pointer to this message     ;AN000;
   call SYSGETMSG			; line up the pointer on the message   ;AN000;
;  $if	nc				; if no error			       ;AN000;
   JC $$IF219
					; all being well --- WE NOW HAVE---
					; DS:SI - aimed at the message file
					; ES:DI - aimed at the Resident Buffer
					; CX	    - # of characters
       cld				; go ahead			       ;AN000;
       rep  movsb			; and copy it!			       ;AN000;
       inc  bx				; set up for next pointer	       ;AN000;
       inc  bx				;				       ;AN000;

;  $endif				; endif - no error		       ;AN000;
$$IF219:

   ret					;				       ;AN000;

   MoveMes ENDP


CODE ENDS


STACK SEGMENT STACK

   dw	100 dup(0)

TransSize LABEL BYTE			; end of transient
					;  only because code is para algned
STACK ENDS

   END	Transient
