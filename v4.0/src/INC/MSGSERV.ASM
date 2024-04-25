; * * * * * * * * * * * * START OF SPECIFICATIONS * * * * * * * * * * * * * * *
;
; MODULE NAME: MSGSERV.SAL
;
; DESCRIPTIVE NAME: Message Services SALUT file
;
; FUNCTION: This module incorporates all the messages services and
;	    is called upon at build time to INCLUDE the code requested
;	    by a utility. Code is requested using the macro MSG_SERVICES.
;
; ENTRY POINT: Since this a collection of subroutines, entry point is at
;	    requested procedure.
;
; INPUT: Since this a collection of subroutines, input is dependent on function
;	    requested.
;
; EXIT-NORMAL: In all cases, CARRY FLAG = 0
;
; EXIT-ERROR: In all cases, CARRY FLAG = 1
;
; INTERNAL REFERENCES: (list of included subroutines)
;
;	- SYSLOADMSG
;	- SYSDISPMSG
;	- SYSGETMSG
;
;
; EXTERNAL REFERENCES: None
;
; NOTES: At build time, some modules must be included. These are only included
;	 once using assembler switches. Other logic is included at the request
;	 of the utility.
;
;	 COMR and COMT are assembler switches to conditionally assemble code
;	 for RESIDENT COMMAND.COM and TRANSIENT COMMAND.COM to reduce resident
;	 storage and multiple EQUates.
;
; REVISION HISTORY: Created MAY 1987
;
;     Label: DOS - - Message Retriever
;	     (c) Copyright 1988 Microsoft
;
;
; * * * * * * * * * * * * END OF SPECIFICATIONS * * * * * * * * * * * * * * * *
; Page 

;   $SALUT	     $M  (2,5,22,62)			     ;;AN000;; Set SALUT formatting

IF  $M_STRUC						     ;;AN000;; IF we haven't included the structures yet THEN
    $M_STRUC	     =	FALSE				     ;;AN000;;	 Let the assembler know that we have
							     ;;AN000;;	   and include them

    PAGE
    SUBTTL	     DOS - Message Retriever - MSGSTR.INC Module
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; STRUCTURE: $M_SUBLIST_STRUC
;;
;; Replacable parameters are described by a sublist structure
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_SUBLIST_STRUC STRUC					     ;;AN000;;
							     ;;
    $M_S_SIZE	     DB        11			     ;;AN000;; SUBLIST size  (PTR to next SUBLIST)
    $M_S_RESV	     DB        0			     ;;AN000;; RESERVED
    $M_S_VALUE	     DD        ?			     ;;AN000;; Time, Date or PTR to data item
    $M_S_ID	     DB        ?			     ;;AN000;; n of %n
    $M_S_FLAG	     DB        ?			     ;;AN000;; Data-type flags
    $M_S_MAXW	     DB        ?			     ;;AN000;; Maximum field width
    $M_S_MINW	     DB        ?			     ;;AN000;; Minimum field width
    $M_S_PAD	     DB        ?			     ;;AN000;; Character for Pad field
							     ;;
$M_SUBLIST_STRUC ENDS					     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; STRUCTURE: $M_CLASS_ID
;;
;; Each class will be defined by this structure.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_CLASS_ID STRUC					     ;;AN000;;
							     ;;
    $M_CLS_ID	     DB        -1			     ;;AN000;; Class identifer
    $M_COMMAND_VER   DW        EXPECTED_VERSION 	     ;;AN003;; COMMAND.COM version check
    $M_NUM_CLS_MSG   DB        0			     ;;AN000;; Total number of message in class
							     ;;
$M_CLASS_ID ENDS					     ;;
							     ;;AN000;;
    $M_CLASS_ID_SZ   EQU       TYPE $M_CLASS_ID 	     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; STRUCTURE: $M_ID_STRUC
;;
;; Each message will be defined by this structure.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_ID STRUC						     ;;AN000;;
							     ;;
    $M_NUM	     DW        -1			     ;;AN000;; Message Number
    $M_TXT_PTR	     DW        ?			     ;;AN000;; Pointer to message text
							     ;;
$M_ID ENDS						     ;;AN000;;
							     ;;AN000;; Status Flag Values:
    $M_ID_SZ	     EQU       TYPE $M_ID		     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; STRUCTURE: $M_RES_ADDRS
;;
;; Resident data area definition of variables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_RES_ADDRS STRUC					     ;;AN000;;
							     ;;
    $M_EXT_ERR_ADDRS DD        0			     ;;AN000;; Allow pointers to THREE Extended error locations
    $M_EXT_FILE      DD        0			     ;;AN001;;
    $M_EXT_COMMAND   DD        0			     ;;AN000;;
    $M_EXT_TERM      DD        -1			     ;;AN000;;
    $M_PARSE_COMMAND DD        0			     ;;AN000;;
    $M_PARSE_ADDRS   DD        0			     ;;AN000;; Allow pointers to TWO Parse error locations
    $M_PARSE_TERM    DD        -1			     ;;AN000;;
    $M_CRIT_ADDRS    DD        0			     ;;AN000;; Allow pointers to TWO Critical error locations
    $M_CRIT_COMMAND  DD        0			     ;;AN000;;
    $M_CRIT_TERM     DD        -1			     ;;AN000;;
    $M_DISK_PROC_ADDR DD       -1			     ;;AN004;; Address of READ_DISK_PROC
    $M_CLASS_ADDRS   DD        $M_NUM_CLS DUP(0)	     ;;AN000;; Allow pointers to specified classes
    $M_CLS_TERM      DD        -1			     ;;AN000;;
    $M_DBCS_VEC      DD        0			     ;;AN000;; Save DBCS vector
    $M_HANDLE	     DW        ?			     ;;AN000;;
    $M_SIZE	     DB        0			     ;;AN000;;
    $M_CRLF	     DB        0DH,0AH			     ;;AN004;; CR LF message
    $M_CLASS	     DB        ?			     ;;AN004;; Saved class
    $M_RETURN_ADDR   DW        ?			     ;;AN000;;
    $M_MSG_NUM	     DW        $M_NULL			     ;;AN000;;
    $M_DIVISOR	     DW        10			     ;;AN000;; Default = 10 (must be a WORD for division)
    $M_TEMP_BUF      DB        $M_TEMP_BUF_SZ DUP("$")	     ;;AN000;; Temporary buffer
    $M_BUF_TERM      DB        "$"			     ;;AN000;;

$M_RES_ADDRS ENDS					     ;;AN000;;
							     ;;
$M_RES_ADDRS_SZ EQU  TYPE $M_RES_ADDRS			     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; STRUCTURE: $M_COUNTRY_INFO
;;
;; Important fields of the Get Country Information call
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_COUNTRY_INFO STRUC					     ;;AN000;; Expected Country infomation
							     ;;
    $M_HEADER	     DB       $M_RES_ADDRS_SZ-$M_TEMP_BUF_SZ-1 DUP(?) ;;AN000;; Go past first part of struc
    $M_DATE_FORMAT   DW       ? 			     ;;AN000;; <------- Date Format
    $M_CURR_SEPARA   DB       5 DUP(?)			     ;;AN000;;
    $M_THOU_SEPARA   DB       ?,0			     ;;AN000;; <------- Thou Separator
    $M_DECI_SEPARA   DB       ?,0			     ;;AN000;; <------- Decimal Separator
    $M_DATE_SEPARA   DB       ?,0			     ;;AN000;; <------- Date Separator
    $M_TIME_SEPARA   DB       ?,0			     ;;AN000;; <------- Time Separator
    $M_CURR_FORMAT   DB       ? 			     ;;AN000;;
    $M_SIG_DIGS_CU   DB       ? 			     ;;AN000;;
    $M_TIME_FORMAT   DB       ? 			     ;;AN000;; <------- Time Format
							     ;;
$M_COUNTRY_INFO ENDS					     ;;AN000;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
ELSE							     ;;AN000;;	ELSE if we have already included the STRUCTURES
; 
;   $SALUT  $M	(2,5,13,62)				     ;;AN000;;	Set SALUT formatting for code section

    IF	    MSGDATA					     ;;AN000;;	IF this is a request to include the data area
      MSGDATA =  FALSE					     ;;AN000;;	  Let the assembler know not to include it again
							     ;;AN000;;	  and include it
      PAGE
      SUBTTL  DOS - Message Retriever - MSGRES.TAB Module
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	DATA NAME: $M_RES_TABLE
;;
;;	REFERENCE LABEL: $M_RT
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
IF    COMR						     ;;AN000;; Since COMMAND.COM includes this twice
      $M_RT   EQU	       $M_RT2			     ;;AN000;;	we must redefine the label so no
      $M_RT2  LABEL  BYTE				     ;;AN000;;	 assembly errors occur
      $M_ALTLABEL = TRUE				     ;;AN000;; Flag that label was changed
ELSE							     ;;AN000;;
      $M_RT   LABEL   BYTE				     ;;AN000;;
ENDIF							     ;;AN000;;
      $M_RES_ADDRS <>					     ;;AN000;; Resident addresses
							     ;;
      include COPYRIGH.INC				     ;;AN001;; Include Copyright 1988 Microsoft
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ENDIF						     ;;AN000;; END of include of Data table

; 
    IF	    NOT  $M_MSGDATA_ONLY			     ;;AN000;; IF this was a request for only the data table THEN
							     ;; 	don't include any more code
							     ;;AN000;; Figure out what other code to include
      IF      DISK_PROC 				     ;;AN003;;	 Is the request to include the READ_DISK code
	IF	COMR					     ;;AN003;;	 (Only Resident COMMAND.COM should ask for it)
	  $M_RT   EQU		   $M_RT2		     ;;AN003;;
	ENDIF
	DISK_PROC = FALSE				     ;;AN003;;	 Yes, THEN include it and reset flag
	PAGE
	SUBTTL	DOS - Message Retriever - DISK_PROC Module
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: DISK_PROC
;;
;;	FUNCTION: Used in COMMAND.COM if we need to access the Parse or Extended
;;		  errors from disk\diskette
;;	INPUTS: AX has the message number
;;		DX has the message class
;;		AND ... the COMMAND.COM Variable RESGROUP:COMSPEC is
;;		assumed to be set!!
;;
;;	OUTPUTS: ES:DI points to message length (BYTE) followed by text
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
	PUBLIC	READ_DISK_PROC				     ;;
							     ;;
READ_DISK_PROC PROC FAR 				     ;;AN003;;

	PUSH	AX					     ;;AN003;; Save everything
	PUSH	BX					     ;;AN003;;
	PUSH	DX					     ;;AN003;;
	PUSH	SI					     ;;AN003;;
	PUSH	BP					     ;;AN003;;
	PUSH	DS					     ;;AN003;;
	PUSH	DI					     ;;AN003;;
	MOV	BP,AX					     ;;AN003;; Save message number
	MOV	AX,DOS_EXTENDED_OPEN			     ;;AN003;; Set INT 21 function
	LEA	SI,RESGROUP:COMSPEC			     ;;AN003;; Get addressibilty to COMMAND.COM
	PUSH	CS					     ;;AN003;;
	POP	DS					     ;;AN003;;
	MOV	DI,-1					     ;;AN003;; No extended attribute list
	MOV	BX,NO_CRIT_OPEN 			     ;;AN003;; Don't generate critical error
	MOV	DX,NOT_EX_FAIL_EX_OPEN			     ;;AN003;; Open Flag
	INT	21H					     ;;AN003;; Open the file
	POP	DI					     ;;AN003;; Retreive LSEEK pointer
							     ;;AN003;; Error ?
;	$IF	NC,LONG 				     ;;AN003;;	No,
	JNC $MXL1
	JMP $MIF1
$MXL1:
	  PUSH	  DI					     ;;AN003;; Save LSEEK pointer
	  MOV	  BX,AX 				     ;;AN003;;	 Set handle in BX
	  MOV	  AX,DOS_LSEEK_FILE			     ;;AN003;;	 LSEEK to the errors
	  XOR	  CX,CX 				     ;;AN003;;	   Value has been set by COMMAND.COM
	  MOV	  DX,DI 				     ;;AN003;;
	  INT	  21H					     ;;AN003;;	 LSEEK the file
	  POP	  DX					     ;;AN003;; Retreive LSEEK pointer
							     ;;AN003;;	 Error ?
;	  $IF	  NC					     ;;AN003;;	  No,
	  JC $MIF2
	    INC     CX					     ;;AN003;;	   Set flag to first pass
;	    $DO 					     ;;AN003;;
$MDO3:
	      PUSH    DX				     ;;AN003;;	   Save LSEEK pointer
	      PUSH    CX				     ;;AN003;;	   Save first pass flag
	      PUSH    AX				     ;;AN003;;	   Save number of messages (if set yet)
	      XOR     SI,SI				     ;;AN003;;	   Reset buffer index
	      MOV     AH,DOS_READ_BYTE			     ;;AN003;;	   Read
	      MOV     CX,$M_TEMP_BUF_SZ 		     ;;AN003;;	     the first part of the header
	      LEA     DX,$M_RT.$M_TEMP_BUF		     ;;AN003;;	       into the temp buffer
	      INT     21H				     ;;AN003;;	   Read it
	      MOV     DI,DX				     ;;AN003;;
	      POP     AX				     ;;AN003;;
	      POP     CX				     ;;AN003;;
	      OR      CX,CX				     ;;AN003;;
;	      $IF     NZ				     ;;AN003;;
	      JZ $MIF4
		XOR	CX,CX				     ;;AN003;;	   Set flag to second pass
		XOR	AH,AH				     ;;AN003;;	   Get number of messages in class
		MOV	AL,DS:[DI].$M_NUM_CLS_MSG	     ;;AN003;;
		MOV	SI,$M_CLASS_ID_SZ		     ;;AN003;;	   Initialize index
		CMP	DS:[DI].$M_COMMAND_VER,EXPECTED_VERSION ;;AN003;;  Is this the right version of COMMAND.COM?
;	      $ENDIF					     ;;AN003;;
$MIF4:
	      POP     DX				     ;;AN003;;
;	      $IF     Z 				     ;;AN003;;	   Yes,
	      JNZ $MIF6
;		$SEARCH 				     ;;AN003;;
$MDO7:
		  CMP	  BP,WORD PTR $M_RT.$M_TEMP_BUF[SI]  ;;AN003;;	     Is this the message I'm looking for?
;		$EXITIF Z				     ;;AN003;;	     Yes, (ZF=1)
		JNZ $MIF7
		  CLC					     ;;AN003;;	      Reset carry, exit search
;		$ORELSE 				     ;;AN003;;	     No,  (ZF=0)
		JMP SHORT $MSR7
$MIF7:
		  ADD	  SI,$M_ID_SZ			     ;;AN003;;	      Increment index
		  ADD	  DX,$M_ID_SZ			     ;;AN003;;	      Add offset of first header
		  DEC	  AX				     ;;AN003;;	      Decrement # of messages left
;		$LEAVE	Z				     ;;AN003;;	      Have we exhausted all messages?
		JZ $MEN7
		  CMP	  SI,$M_TEMP_BUF_SZ-1		     ;;AN003;;	       No, Have we exhausted the buffer?
;		$ENDLOOP A				     ;;AN003;;		No, Check next message (ZF=1)
		JNA $MDO7
$MEN7:
		  STC					     ;;AN003;;	       Yes, (ZF=0) set error (ZF=0)
;		$ENDSRCH				     ;;AN003;;
$MSR7:
;	      $ELSE					     ;;AN003;;	   No,
	      JMP SHORT $MEN6
$MIF6:
		XOR	CX,CX				     ;;AN003;;	     Set Zero flag to exit READ Loop
		STC					     ;;AN003;;	     Set Carry
;	      $ENDIF					     ;;AN003;;
$MEN6:
;	    $ENDDO  Z					     ;;AN003;;	       Get next buffer full if needed
	    JNZ $MDO3
							     ;;AN003;; Error ?
;	    $IF     NC					     ;;AN003;;	No,
	    JC $MIF16
	      MOV     AX,DOS_LSEEK_FILE 		     ;;AN003;;	 Prepare to LSEEK to the specific message
	      XOR     CX,CX				     ;;AN003;;	 Value has been set by COMMAND.COM
	      ADD     DX,$M_CLASS_ID_SZ 		     ;;AN003;;	 Add offset of first header
	      ADD     DX,WORD PTR $M_RT.$M_TEMP_BUF[SI]+2    ;;AN003;;	 Add offset from msg structure
	      INT     21H				     ;;AN003;;	 LSEEK the file
	      MOV     AH,DOS_READ_BYTE			     ;;AN003;;	   Read
	      MOV     CX,$M_TEMP_BUF_SZ 		     ;;AN003;;	     the message
	      LEA     DX,$M_RT.$M_TEMP_BUF		     ;;AN003;;	       into the temp buffer
	      INT     21H				     ;;AN003;;	   Read it
	      MOV     DI,DX				     ;;AN003;;	       into the temp buffer
	      PUSH    DS				     ;;AN003;;	       into the temp buffer
	      POP     ES				     ;;AN003;;	       into the temp buffer
;	    $ENDIF					     ;;AN003;;
$MIF16:
;	  $ENDIF					     ;;AN003;;
$MIF2:
	  PUSHF 					     ;;AN003;;	   Close file handle
	  MOV	  AH,DOS_CLOSE_FILE			     ;;AN003;;	   Close file handle
	  INT	  21H					     ;;AN003;;
	  $M_POPF					     ;;AN003;;
;	$ENDIF						     ;;AN003;; Yes there was an error,
$MIF1:
	POP	DS					     ;;AN003;;
	POP	BP					     ;;AN003;;
	POP	SI					     ;;AN003;;
	POP	DX					     ;;AN003;;
	POP	BX					     ;;AN003;;
	POP	AX					     ;;AN003;;
							     ;;AN003;;	     abort everything
	RET						     ;;AN003;;

READ_DISK_PROC ENDP					     ;;AN003;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ENDIF						     ;;AN003;; END of include for DISK_PROC
;

      IF      SETSTDIO					     ;;AN000;;	 Is the request to include the code for SETSTDIO
	SETSTDIO = FALSE				     ;;AN000;;	 Yes, THEN include it and reset flag
	PAGE
	SUBTTL	DOS - Message Retriever - SETSTDIO Module
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: SETSTDIO
;;
;;	FUNCTION:
;;	INPUTS:
;;
;;	OUPUTS:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
IF	FARmsg						     ;AN001;
	SETSTDINON PROC FAR				     ;AN001;
ELSE							     ;AN001;
	SETSTDINON PROC NEAR				     ;AN001;
ENDIF							     ;AN001;
	PUSH	AX					     ;AN002; Save changed regs
	PUSH	BX					     ;AN002;
	PUSH	DX					     ;AN002;
	MOV	AX,DOS_IOCTL_GET_INFO			     ;AN001; Get info using IOCTL
	MOV	BX,STDIN				     ;AN001;
	XOR	DX,DX					     ;AN001;
	INT	21H					     ;AN001;

	OR	DH,$M_CRIT_ERR_MASK			     ;AN001; Turn on bit
	MOV	AX,DOS_IOCTL_SET_INFO			     ;AN001; Set info using IOCTL
	INT	21H					     ;AN001;
	POP	DX					     ;AN002; Restore Regs
	POP	BX					     ;AN002;
	POP	AX					     ;AN002;

	RET						     ;AN001;
							     ;AN001;
	SETSTDINON ENDP 				     ;AN001;

IF	FARmsg						     ;AN001;
	SETSTDINOFF PROC FAR				     ;AN001;
ELSE							     ;AN001;
	SETSTDINOFF PROC NEAR				     ;AN001;
ENDIF							     ;AN001;

	PUSH	AX					     ;AN002; Save changed regs
	PUSH	BX					     ;AN002;
	PUSH	DX					     ;AN002;
	MOV	AX,DOS_IOCTL_GET_INFO			     ;AN001; Get info using IOCTL
	MOV	BX,STDIN				     ;AN001;
	XOR	DX,DX					     ;AN001;
	INT	21H					     ;AN001;

	AND	DH,NOT $M_CRIT_ERR_MASK 		     ;AN001; Turn off bit
	MOV	AX,DOS_IOCTL_SET_INFO			     ;AN001; Set info using IOCTL
	INT	21H					     ;AN001;
	POP	DX					     ;AN002; Restore Regs
	POP	BX					     ;AN002;
	POP	AX					     ;AN002;

	RET						     ;AN001;

	SETSTDINOFF ENDP				     ;AN001;

IF	FARmsg						     ;AN001;
	SETSTDOUTON PROC FAR				     ;AN001;
ELSE							     ;AN001;
	SETSTDOUTON PROC NEAR				     ;AN001;
ENDIF							     ;AN001;

	PUSH	AX					     ;AN002; Save changed regs
	PUSH	BX					     ;AN002;
	PUSH	DX					     ;AN002;
	MOV	AX,DOS_IOCTL_GET_INFO			     ;AN001; Get info using IOCTL
	MOV	BX,STDOUT				     ;AN001;
	XOR	DX,DX					     ;AN001;
	INT	21H					     ;AN001;

	OR	DH,$M_CRIT_ERR_MASK			     ;AN001; Turn on bit
	MOV	AX,DOS_IOCTL_SET_INFO			     ;AN001; Set info using IOCTL
	INT	21H					     ;AN001;
	POP	DX					     ;AN002; Restore Regs
	POP	BX					     ;AN002;
	POP	AX					     ;AN002;

	RET						     ;AN001;

	SETSTDOUTON ENDP				     ;AN001;

IF	FARmsg						     ;AN001;
	SETSTDOUTOFF PROC FAR				     ;AN001;
ELSE							     ;AN001;
	SETSTDOUTOFF PROC NEAR
ENDIF							     ;AN001;

	PUSH	AX					     ;AN002; Save changed regs
	PUSH	BX					     ;AN002;
	PUSH	DX					     ;AN002;
	MOV	AX,DOS_IOCTL_GET_INFO			     ;AN001; Get info using IOCTL
	MOV	BX,STDOUT				     ;AN001;
	XOR	DX,DX					     ;AN001;
	INT	21H					     ;AN001;

	AND	DH,NOT $M_CRIT_ERR_MASK 		     ;AN001; Turn off bit
	MOV	AX,DOS_IOCTL_SET_INFO			     ;AN001; Set info using IOCTL
	INT	21H					     ;AN001;
	POP	DX					     ;AN002; Restore Regs
	POP	BX					     ;AN002;
	POP	AX					     ;AN002;

	RET						     ;AN001;

	SETSTDOUTOFF ENDP				     ;AN001;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ENDIF						     ;;AN000;; END of include for SETSTDIO
; 
      IF      LOADmsg					     ;;AN000;;	 Is the request to include the code for SYSLOADMSG ?
	IF	COMR					     ;;AN000;;
	  $M_RT   EQU		   $M_RT2		     ;;AN000;;
	ENDIF
	LOADmsg = FALSE 				     ;;AN000;;	 Yes, THEN include it and reset flag
	PAGE
	SUBTTL	DOS - Message Retriever - LOADMSG.ASM Module
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: SYSLOADMSG
;;
;;	FUNCTION:
;;	INPUTS:
;;
;;	OUPUTS:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
IF	FARmsg						     ;;AN000;;
	SYSLOADMSG PROC FAR				     ;;AN000;;
ELSE							     ;;AN000;;
	SYSLOADMSG PROC NEAR				     ;;AN000;;
ENDIF							     ;;AN000;;
	PUSH	AX					     ;;AN000;
	PUSH	BX					     ;;AN000;
	PUSH	DX					     ;;AN000;
	PUSH	ES					     ;;AN000;
	PUSH	DI					     ;;AN000;
	XOR	CX,CX					     ;;AN000;  Reset to zero
	MOV	ES,CX					     ;;AN000;
	XOR	DI,DI					     ;;AN000;
	MOV	AX,DOS_GET_EXT_PARSE_ADD		     ;;AN000;; 2FH Interface
	MOV	DL,DOS_GET_EXTENDED			     ;;AN000;; Where are the Extended errors in COMMAND.COM
	INT	2FH					     ;;AN000;; Private interface
	MOV	WORD PTR $M_RT.$M_EXT_COMMAND+2,ES	     ;;AN000;;	Move into first avaliable table location
	MOV	WORD PTR $M_RT.$M_EXT_COMMAND,DI	     ;;AN000;;
							     ;;
	MOV	AX,DOS_GET_EXT_PARSE_ADD		     ;;AN000;; 2FH Interface
	MOV	DL,DOS_GET_PARSE			     ;;AN000;; Where are the Parse errors in COMMAND.COM
	INT	2FH					     ;;AN000;; Private interface
	MOV	WORD PTR $M_RT.$M_PARSE_COMMAND+2,ES	     ;;AN000;;	Move into first avaliable table location
	MOV	WORD PTR $M_RT.$M_PARSE_COMMAND,DI	     ;;AN000;;
							     ;;
	MOV	AX,DOS_GET_EXT_PARSE_ADD		     ;;AN000;; 2FH Interface
	MOV	DL,DOS_GET_CRITICAL			     ;;AN000;; Where are the Critical errors in COMMAND.COM
	INT	2FH					     ;;AN000;; Private interface
	MOV	WORD PTR $M_RT.$M_CRIT_COMMAND+2,ES	     ;;AN000;;	Move into first avaliable table location
	MOV	WORD PTR $M_RT.$M_CRIT_COMMAND,DI	     ;;AN000;;

	MOV	AX,DOS_GET_EXT_PARSE_ADD		     ;;AN001;; 2FH Interface
	MOV	DL,DOS_GET_FILE 			     ;;AN001;; Where are the FILE dependant in IFSFUNC.EXE
	INT	2FH					     ;;AN001;; Private interface
	MOV	WORD PTR $M_RT.$M_EXT_FILE+2,ES 	     ;;AN001;;	Move into first avaliable table location
	MOV	WORD PTR $M_RT.$M_EXT_FILE,DI		     ;;AN001;;

IF	COMR						     ;;  ** Special case for RESIDENT COMMAND.COM
	IF2
	  IFNDEF  READ_DISK_INFO			     ;;AN003;;
	    Extrn   READ_DISK_PROC:Far			     ;;AN003;;
	  ENDIF 					     ;;AN003;;
	ENDIF						     ;;AN003;;
ELSE							     ;;
	IF	FARmsg					     ;;AN000;;
	  CALL	  FAR PTR $M_MSGSERV_1			     ;;AN000;; Get addressibilty to MSGSERV CLASS 1 (EXTENDED Errors)
	ELSE						     ;;AN000;;
	  CALL	  $M_MSGSERV_1				     ;;AN000;; Get addressibilty to MSGSERV CLASS 1 (EXTENDED Errors)
	ENDIF						     ;;AN000;;
	MOV	WORD PTR $M_RT.$M_EXT_ERR_ADDRS+2,ES	     ;;AN000;; Move into first avaliable table location
	MOV	WORD PTR $M_RT.$M_EXT_ERR_ADDRS,DI	     ;;AN000;;
	MOV	WORD PTR $M_RT.$M_CRIT_ADDRS+2,ES	     ;;AN000;; Move into first avaliable table location
	MOV	WORD PTR $M_RT.$M_CRIT_ADDRS,DI 	     ;;AN000;;
							     ;;
	IF	FARmsg					     ;;AN000;;
	  CALL	  FAR PTR $M_MSGSERV_2			     ;;AN000;; Get addressibilty to MSGSERV CLASS 2 (PARSE Errors)
	ELSE						     ;;AN000;;
	  CALL	  $M_MSGSERV_2				     ;;AN000;; Get addressibilty to MSGSERV CLASS 2 (PARSE Errors)
	ENDIF						     ;;AN000;;
	MOV	WORD PTR $M_RT.$M_PARSE_ADDRS+2,ES	     ;;AN000;; Move into first avaliable table location
	MOV	WORD PTR $M_RT.$M_PARSE_ADDRS,DI	     ;;AN000;;
ENDIF							     ;;
							     ;;
	MOV	AX,DOS_GET_EXT_PARSE_ADD		     ;;AN001;; 2FH Interface
	MOV	DL,DOS_GET_ADDR 			     ;;AN001;; Where is the READ_DISK_PROC in COMMAND.COM
	INT	2FH					     ;;AN001;; Private interface
	MOV	WORD PTR $M_RT.$M_DISK_PROC_ADDR+2,ES	     ;;AN001;;	Move into first avaliable table location
	MOV	WORD PTR $M_RT.$M_DISK_PROC_ADDR,DI	     ;;AN001;;

	$M_BUILD_PTRS %$M_NUM_CLS			     ;;AN000;; Build all utility classes
							     ;;AN000;;
	CALL	$M_GET_DBCS_VEC 			     ;;AN000;; Save the DBCS vector

IF	NOT	NOCHECKSTDIN				     ;;AN000;; IF EOF check is not to be suppressed
	CALL	$M_CHECKSTDIN				     ;;AN000;;	 Set EOF CHECK
ENDIF							     ;;AN000;;
							     ;;AN000;;
IF	NOT	NOCHECKSTDOUT				     ;;AN000;; IF Disk Full check is not to be suppressed
	CALL	$M_CHECKSTDOUT				     ;;AN000;;	 Set Disk Full CHECK
ENDIF							     ;;AN000;;
							     ;;AN000;;
IF	NOVERCHECKmsg					     ;;AN000;; IF version check is to be supressed
	CLC						     ;;AN000;;	 Make sure carry is clear
ELSE							     ;;AN000;; ELSE
	PUSH	CX					     ;;AN000;;
	CALL	$M_VERSION_CHECK			     ;;AN000;;	 Check Version
ENDIF							     ;;AN000;;
							     ;;        Error ?
;	$IF	NC					     ;;AN000;; No.
	JC $MIF20
IF	  NOT	  NOVERCHECKmsg 			     ;;AN000;;	IF version check was not supressed
	  POP	  CX					     ;;AN000;;	Reset stack
ENDIF							     ;;AN000;;
	  POP	  DI					     ;;AN000;;	Restore REGS
	  POP	  ES					     ;;AN000;;
	  POP	  DX					     ;;AN000;;
	  POP	  BX					     ;;AN000;;
	  POP	  AX					     ;;AN000;;
;	$ELSE						     ;;AN000;; Yes,
	JMP SHORT $MEN20
$MIF20:
IF	  NOVERCHECKmsg 				     ;;AN000;;	IF version check is to be supressed
	  ADD	  SP,10 				     ;;AN000;;
	  STC						     ;;AN000;;	Reset carry flag
ELSE							     ;;AN000;;	IF version check is to be supressed
	  ADD	  SP,12 				     ;;AN000;;
	  STC						     ;;AN000;;	Reset carry flag
ENDIF							     ;;AN000;;	IF version check is to be supressed
;	$ENDIF						     ;;AN000;;
$MEN20:
	RET						     ;;AN000;;
							     ;;
	SYSLOADMSG ENDP 				     ;;AN000;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PAGE
	SUBTTL	DOS - Message Retriever - $M_VERSION_CHECK Proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Proc Name:	$M_GET_DBCS_VEC
;;
;;  Function:	Get the DBCS vector and save it for later use
;;
;;  Inputs:	None
;;
;;  Outputs:	None
;;
;;  Regs Changed:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_GET_DBCS_VEC PROC NEAR				     ;;AN000;;
							     ;;
	PUSH	AX					     ;;AN000;; Save character to check
	PUSH	SI					     ;;AN000;;
	PUSH	DS					     ;;AN000;;
	MOV	AX,DOS_GET_DBCS_INFO			     ;;AN000;; DOS function to get DBSC environment
	INT	21H					     ;;AN000;; Get environment pointer
	PUSH	DS					     ;;AN000;; Get environment pointer
	POP	ES					     ;;AN000;; Get environment pointer
	POP	DS					     ;;AN000;; Get environment pointer
;	$IF	NC					     ;;AN000;;
	JC $MIF23
	  MOV	  WORD PTR $M_RT.$M_DBCS_VEC,SI 	     ;;AN000;; Save DBCS Vector
	  MOV	  WORD PTR $M_RT.$M_DBCS_VEC+2,ES	     ;;AN000;;
;	$ENDIF						     ;;AN000;;
$MIF23:
	POP	SI					     ;;AN000;;
	POP	AX					     ;;AN000;; Retrieve character to check
	RET						     ;;AN000;; Return
							     ;;
$M_GET_DBCS_VEC ENDP					     ;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	IF	NOCHECKSTDIN				     ;AN001; Are we suppose to include the code for Checking EOF ?
	ELSE						     ;AN001; Yes, THEN include it
	  PAGE
	  SUBTTL  DOS - Message Retriever - $M_CHECKSTDIN Proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Proc Name:	$M_CHECKSTDIN
;;
;;  Function:
;;
;;  Inputs:	None
;;
;;  Outputs:
;;
;;  Regs Changed:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_CHECKSTDIN PROC NEAR 				     ;AN001;

	  MOV	  AX,DOS_IOCTL_GET_INFO 		     ;AN001; Get info using IOCTL
	  MOV	  BX,STDIN				     ;AN001;
	  XOR	  DX,DX 				     ;AN001;
	  INT	  21H					     ;AN001;

	  OR	  DH,$M_CRIT_ERR_MASK			     ;AN001; Turn on bit
	  MOV	  AX,DOS_IOCTL_SET_INFO 		     ;AN001; Set info using IOCTL
	  INT	  21H					     ;AN001;

	  RET						     ;AN001;

$M_CHECKSTDIN ENDP					     ;AN001;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ENDIF						     ;AN001; END of include for EOF Check
	IF	NOCHECKSTDOUT				     ;AN001; Are we suppose to include the code for Checking Disk Full?
	ELSE						     ;AN001; Yes, THEN include it
	  PAGE
	  SUBTTL  DOS - Message Retriever - $M_CHECKSTDOUT Proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Proc Name:	$M_CHECKSTDOUT
;;
;;  Function:
;;
;;  Inputs:	None
;;
;;  Outputs:
;;
;;  Regs Changed:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_CHECKSTDOUT PROC NEAR				     ;AN001;

	  MOV	  AX,DOS_IOCTL_GET_INFO 		     ;AN001; Get info using IOCTL
	  MOV	  BX,STDOUT				     ;AN001;
	  XOR	  DX,DX 				     ;AN001;
	  INT	  21H					     ;AN001;

	  OR	  DH,$M_CRIT_ERR_MASK			     ;AN001; Turn on bit
	  MOV	  AX,DOS_IOCTL_SET_INFO 		     ;AN001; Set info using IOCTL
	  INT	  21H					     ;AN001;

	  RET						     ;AN001;

$M_CHECKSTDOUT ENDP					     ;AN001;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ENDIF						     ;AN001;  END of include for Disk Full Check
	IF	NOVERCHECKmsg				     ;;AN000;; Are we suppose to include the code for DOS version check?
	ELSE						     ;;AN000;; Yes, THEN include it
	  PAGE
	  SUBTTL  DOS - Message Retriever - $M_VERSION_CHECK Proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Proc Name:	$M_VERSION_CHECK
;;
;;  Function:	Determine if DOS version is within allowable limits
;;
;;  Inputs:	None
;;
;;  Outputs:	CARRY_FLAG = 1 if Incorrect DOS version
;;		Registers set for SYSDISPMSG
;;		CARRY_FLAG = 0 if Correct DOS version
;;
;;  Regs Changed: AX
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_VERSION_CHECK PROC NEAR				     ;;AN000;;
							     ;;
	  MOV	  AH,DOS_GET_VERSION			     ;;AN000;; Check that version matches VERSIONA.INC
	  INT	  21H					     ;;AN000;;
							     ;;
	  CMP	  AX,EXPECTED_VERSION			     ;;AN000;; IF DOS_MAJOR is correct
;	  $IF	  E					     ;;AN000;;
	  JNE $MIF25
	    CLC 					     ;;AN000;;	 Clear the carry flag
;	  $ELSE 					     ;;AN000;; ELSE
	  JMP SHORT $MEN25
$MIF25:
IF	    NOT     COMR				     ;;  ** Special case for RESIDENT COMMAND.COM
	    CMP     AX,LOWEST_4CH_VERSION		     ;;AN000;; Does this version support AH = 4CH
;	    $IF     B					     ;;AN000;; No,
	    JNB $MIF27
	      MOV     BX,NO_HANDLE			     ;;AN000;;	 No handle (version doesn't support)
;	    $ELSE					     ;;AN000;; Yes,
	    JMP SHORT $MEN27
$MIF27:
	      MOV     BX,STDERR 			     ;;AN000;;	 Standard Error
;	    $ENDIF					     ;;AN000;;
$MEN27:
ELSE
	    MOV     BX,NO_HANDLE			     ;;AN000;;	 No handle
ENDIF
	    MOV     AX,1				     ;;AN000;; Set message # 1
	    MOV     CX,NO_REPLACE			     ;;AN000;; No replacable parms
	    MOV     DL,NO_INPUT 			     ;;AN000;; No input
	    MOV     DH,UTILITY_MSG_CLASS		     ;;AN000;; Utility class message
	    STC 					     ;;AN000;; Set Carry Flag
;	  $ENDIF					     ;;AN000;;
$MEN25:
							     ;;
	  RET						     ;;AN000;; Return
							     ;;
$M_VERSION_CHECK ENDP					     ;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ENDIF						     ;;AN000;; END of include for DOS version check
      ENDIF						     ;;AN000;; END of include for SYSLOADMSG
; 
      IF      GETmsg					     ;;AN000;; Is the request to include the code for SYSGETMSG ?
	IF	COMR					     ;;AN000;;
	  $M_RT   EQU		   $M_RT2		     ;;AN000;;
	ENDIF						     ;;AN000;;
	GETmsg	=      FALSE				     ;;AN000;; Yes, THEN include it and reset flag
	PAGE
	SUBTTL	DOS - Message Retriever - GETMSG.ASM Module
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Proc Name:	SYSGETMSG
;;
;;  Function:	The GET service returns the segment, offset and size of the
;;		message text to the caller based on a message number.
;;		The GET function will not display the message thus assumes
;;		caller will handle replaceable parameters.
;;
;;  Inputs:
;;
;;  Outputs:
;;
;;  Psuedocode:
;;		Call $M_GET_MSG_ADDRESS
;;		IF MSG_NUM exists THEN
;;		   Set DS:SI = MSG_TXT_PTR + 1
;;		   CARRY_FLAG = 0
;;		ELSE
;;		   CARRY_FLAG = 1
;;		ENDIF
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
IF	FARmsg						     ;;AN000;;
	SYSGETMSG PROC	FAR				     ;;AN000;;
ELSE							     ;;AN000;;
	SYSGETMSG PROC	NEAR				     ;;AN000;;
ENDIF							     ;;AN000;;
							     ;;
;; Save registers needed later

	PUSH	AX					     ;;AN000;; Save changed regs
	PUSH	ES					     ;;AN000;;
	PUSH	DI					     ;;AN000;;
	PUSH	BP					     ;;AN000;;
							     ;;
IF	FARmsg						     ;;AN000;;
	CALL	FAR PTR $M_GET_MSG_ADDRESS		     ;;AN000;; Scan thru classes to find message
ELSE							     ;;AN000;;
	CALL	$M_GET_MSG_ADDRESS			     ;;AN000;; Scan thru classes to find message
ENDIF							     ;;AN000;; Return message in ES:DI
;	$IF	NC					     ;;AN000;; Message found?
	JC $MIF31
	  CMP	  DH,UTILITY_MSG_CLASS
	  CLC						     ;;AN000;;
;	  $IF	  NE
	  JE $MIF32
	    PUSH    ES					     ;;AN000;;
	    POP     DS					     ;;AN000;;	   Return message in DS:SI
;	  $ELSE
	  JMP SHORT $MEN32
$MIF32:
IF	    FARmsg					     ;;AN000;;	 Yes,
	    PUSH    ES					     ;;AN000;;
	    POP     DS					     ;;AN000;;	   Return message in DS:SI
ELSE							     ;;AN000;;
	    PUSH    CS					     ;;AN000;;	   Return message in DS:SI
	    POP     DS					     ;;AN000;;
ENDIF							     ;;AN000;;
;	  $ENDIF					     ;;AN000;;
$MEN32:
	  MOV	  SI,DI 				     ;;AN000;;	   Return message in DS:SI
;	$ENDIF						     ;;AN000;;
$MIF31:
							     ;;
	POP	BP					     ;;AN000;; Restore changed regs
	POP	DI					     ;;AN000;;
	POP	ES					     ;;AN000;;
	POP	AX					     ;;AN000;;
							     ;;
	RET						     ;;AN000;;	  Return
							     ;;
	SYSGETMSG ENDP					     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	IF	$M_SUBS 				     ;;AN000;; Include the common subroutines if they haven't yet
	  $M_SUBS = FALSE				     ;;AN000;; No, then include and reset the flag
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_GET_MSG_ADDRESS
;;
;;	FUNCTION:  To scan thru classes to return pointer to the message header
;;	INPUTS:    Access to $M_RES_ADDRESSES
;;	OUPUTS:    IF CX = 0 THEN Message was not found
;;		   IF CX > 1 THEN ES:DI points to the specified message
;;	REGS CHANGED: ES,DI,CX
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
IF	  FARmsg					     ;;AN000;;
	  $M_GET_MSG_ADDRESS PROC FAR			     ;;AN000;;
ELSE							     ;;AN000;;
	  $M_GET_MSG_ADDRESS PROC NEAR			     ;;AN000;;
ENDIF							     ;;AN000;;
							     ;;
	  PUSH	  SI					     ;;AN000;;
	  PUSH	  BX					     ;;AN000;;
	  XOR	  SI,SI 				     ;;AN000;; Use SI as an index
	  XOR	  CX,CX 				     ;;AN000;; Use CX as an size
;	  $DO						     ;;AN000;;
$MDO36:
	    CMP     DH,UTILITY_MSG_CLASS		     ;;AN000;; Were utility messages requested?
;	    $IF     E					     ;;AN000;; Yes,
	    JNE $MIF37
	      IF      FARmsg				     ;;AN000;;
		LES	DI,DWORD PTR $M_RT.$M_CLASS_ADDRS[SI] ;;AN000;;  Get address of class
		MOV	BX,ES				     ;;AN000;
	      ELSE					     ;;AN000;;
		MOV	DI,WORD PTR $M_RT.$M_CLASS_ADDRS[SI] ;;AN000;;	 Get address of class
		MOV	BX,DI				     ;;AN000;
	      ENDIF					     ;;AN000;;
;	    $ELSE					     ;;AN000;; No,
	    JMP SHORT $MEN37
$MIF37:
	      TEST    DH,PARSE_ERR_CLASS		     ;;AN000;;	 Were parse errors requested?
;	      $IF     NE				     ;;AN000;;	 Yes,
	      JE $MIF39
		LES	DI,DWORD PTR $M_RT.$M_PARSE_COMMAND[SI] ;;AN000;;   Get address of class
		MOV	BX,ES				     ;;AN000;
;	      $ELSE					     ;;AN000;;	 No, extended errors were specified
	      JMP SHORT $MEN39
$MIF39:
		CMP	AX,$M_CRIT_LO			     ;;AN000;;	   Is this a critical error?
;		$IF	AE,AND				     ;;AN000;;
		JNAE $MIF41
		CMP	AX,$M_CRIT_HI			     ;;AN000;;
;		$IF	BE				     ;;AN000;;	    Yes,
		JNBE $MIF41
		  LES	  DI,DWORD PTR $M_RT.$M_CRIT_ADDRS[SI] ;;AN000;; Get address of class
		  MOV	  BX,ES 			     ;;AN000;
;		$ELSE					     ;;AN000;;
		JMP SHORT $MEN41
$MIF41:
		  LES	  DI,DWORD PTR $M_RT.$M_EXT_ERR_ADDRS[SI] ;;AN000;; Get address of class
		  MOV	  BX,ES 			     ;;AN000;
;		$ENDIF					     ;;AN000;;
$MEN41:
;	      $ENDIF					     ;;AN000;;
$MEN39:
;	    $ENDIF					     ;;AN000;;
$MEN37:
							     ;;
	    CMP     BX,$M_TERMINATING_FLAG		     ;;AN000;; Are we finished all classes?
;	    $IF     E					     ;;AN000;; Yes,
	    JNE $MIF46
	      CMP     DH,UTILITY_MSG_CLASS		     ;;AN000;;	  Was it a UTILITY class?
;	      $IF     E 				     ;;AN000;;	  Yes,
	      JNE $MIF47
		STC					     ;;AN000;;	    Set the carry flag
;	      $ELSE					     ;;AN000;;	  No,
	      JMP SHORT $MEN47
$MIF47:
		MOV	$M_RT.$M_MSG_NUM,AX		     ;;AN000;;	    Save message number
		MOV	AX,$M_SPECIAL_MSG_NUM		     ;;AN000;;	    Set special message number
		MOV	BP,$M_ONE_REPLACE		     ;;AN000;;	    Set one replace in message
		XOR	SI,SI				     ;;AN000;;	    Reset the SI index to start again
		CLC					     ;;AN000;;
;	      $ENDIF					     ;;AN000;; No,
$MEN47:
;	    $ELSE					     ;;AN000;;
	    JMP SHORT $MEN46
$MIF46:
	      CMP     BX,$M_CLASS_NOT_EXIST		     ;;AN000;;	 Does this class exist?
;	      $IF     NE				     ;;AN001;;	 Yes,
	      JE $MIF51
		CALL	$M_FIND_SPECIFIED_MSG		     ;;AN000;;	   Try to find the message
;	      $ENDIF					     ;;AN000;;
$MIF51:
	      ADD     SI,$M_ADDR_SZ_FAR 		     ;;AN000;;	     Get next class
	      CLC					     ;;AN000;;
;	    $ENDIF					     ;;AN000;;
$MEN46:
;	  $LEAVE  C					     ;;AN000;;
	  JC $MEN36
	    OR	    CX,CX				     ;;AN000;;	   Was the message found?
;	  $ENDDO  NZ,LONG				     ;;AN000;;
	  JNZ $MXL2
	  JMP $MDO36
$MXL2:
$MEN36:

	  PUSHF 					     ;;AN006;; Save the flag state
	  CMP	  DH,EXT_ERR_CLASS			     ;;AN006;; Was an extended error requested?
;	  $IF	  E					     ;;AN006;; Yes,
	  JNE $MIF56
	    PUSH    DX					     ;;AN006;;	Save all needed registers
	    PUSH    BP					     ;;AN006;;
	    PUSH    CX					     ;;AN006;;
	    PUSH    ES					     ;;AN006;;
	    PUSH    DI					     ;;AN006;;
	    PUSH    AX					     ;;AN006;;

	    MOV     AX,IFSFUNC_INSTALL_CHECK		     ;;AN006;;	Check if IFSFUNC is installed
	    INT     2FH 				     ;;AN006;;
	    CMP     AL,IFSFUNC_INSTALLED		     ;;AN006;;	Is it installed?
	    POP     AX					     ;;AN006;;	Restore msg number
;	    $IF     E					     ;;AN006;;	 Yes,
	    JNE $MIF57
	      MOV     BX,AX				     ;;AN006;;	  BX is the extended error number
	      MOV     AX,IFS_GET_ERR_TEXT		     ;;AN006;;	  AX is the muliplex number
	      INT     2FH				     ;;AN006;;	  Call IFSFUNC
;	    $ELSE					     ;;AN006;;	 No,
	    JMP SHORT $MEN57
$MIF57:
	      STC					     ;;AN006;;	  Carry conditon
;	    $ENDIF					     ;;AN006;;
$MEN57:

;	    $IF     C					     ;;AN006;;	Was there an update?
	    JNC $MIF60
	      POP     DI				     ;;AN006;;	No,
	      POP     ES				     ;;AN006;;	 Restore old pointer
	      POP     CX				     ;;AN006;;
;	    $ELSE					     ;;AN006;;	Yes
	    JMP SHORT $MEN60
$MIF60:
	      ADD     SP,6				     ;;AN006;;	 Throw away old pointer
	      CALL    $M_SET_LEN_IN_CX			     ;;AN006;;	 Get the length of the ASCIIZ string
;	    $ENDIF					     ;;AN006;;
$MEN60:
	    POP     BP					     ;;AN006;;	Restore other Regs
	    POP     DX					     ;;AN006;;
;	  $ENDIF					     ;;AN006;;
$MIF56:
	  $M_POPF					     ;;AN006;; Restore the flag state

	  POP	  BX					     ;;AN000;;
	  POP	  SI					     ;;AN000;;
	  RET						     ;;AN000;; Return ES:DI pointing to the message
							     ;;
$M_GET_MSG_ADDRESS ENDP 				     ;;
							     ;;
$M_SET_LEN_IN_CX PROC NEAR				     ;;
							     ;;
	  PUSH	  DI					     ;;AN006;; Save position
	  PUSH	  AX					     ;;AN006;;
	  MOV	  CX,-1 				     ;;AN006;; Set CX for decrements
	  XOR	  AL,AL 				     ;;AN006;; Prepare compare register
	  REPNE   SCASB 				     ;;AN006;; Scan for zero
	  NOT	  CX					     ;;AN006;; Change decrement into number
	  DEC	  CX					     ;;AN006;; Don't include the zero
	  POP	  AX					     ;;AN006;;
	  POP	  DI					     ;;AN006;; Restore position
	  RET						     ;;AN006;;
							     ;;
$M_SET_LEN_IN_CX ENDP					     ;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_FIND_SPECIFIED_MSG
;;
;;	FUNCTION:  To scan thru message headers until message is found
;;	INPUTS:    ES:DI points to beginning of msg headers
;;		   CX contains the number of messages in class
;;		   DH contains the message class
;;	OUPUTS:    IF CX = 0 THEN Message was not found
;;		   IF CX > 1 THEN ES:DI points to header of specified message
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_FIND_SPECIFIED_MSG PROC NEAR 			     ;;AN000;;
							     ;;
	  CMP	  BX,1					     ;;AN004;;	Do we have an address to CALL?
;	  $IF	  E,AND 				     ;;AN004;;	Yes,
	  JNE $MIF64
	  CMP	  WORD PTR $M_RT.$M_DISK_PROC_ADDR,-1	     ;;AN004;;	Do we have an address to CALL?
;	  $IF	  NE					     ;;AN004;;	Yes,
	  JE $MIF64
	    CMP     AX,$M_SPECIAL_MSG_NUM		     ;;AN004;; Are we displaying a default Ext Err?
;	    $IF     E					     ;;AN004;;	. . . and . . .
	    JNE $MIF65
	      PUSH    AX				     ;;AN004;;	 Reset the special message number
	      MOV     AX,$M_RT.$M_MSG_NUM		     ;;AN004;;	 Get the old message number
	      CALL    DWORD PTR $M_RT.$M_DISK_PROC_ADDR      ;;AN004;;	 Call the READ_DISK_PROC to get error text
	      POP     AX				     ;;AN004;;	 Reset the special message number
;	    $ELSE					     ;;AN004;;	 Get the old message number
	    JMP SHORT $MEN65
$MIF65:
	      CALL    DWORD PTR $M_RT.$M_DISK_PROC_ADDR      ;;AN004;;	 Call the READ_DISK_PROC to get error text
;	    $ENDIF					     ;;AN004;;	 Get the old message number
$MEN65:
;	  $ELSE 					     ;;AN004;;
	  JMP SHORT $MEN64
$MIF64:
	    XOR     CX,CX				     ;;AN002;;	 CX = 0 will allow us to
	    CMP     DH,UTILITY_MSG_CLASS		     ;;AN001;;
;	    $IF     NE					     ;;AN001;;
	    JE $MIF69
	      MOV     CL,BYTE PTR ES:[DI].$M_NUM_CLS_MSG     ;;AN001;;	 Get number of messages in class
;	    $ELSE					     ;;AN001;;
	    JMP SHORT $MEN69
$MIF69:
IF	      FARmsg					     ;;AN001;;
	      CMP     BYTE PTR ES:[DI].$M_CLASS_ID,DH	     ;;AN002;; Check if class still exists at
ELSE
	      CMP     BYTE PTR CS:[DI].$M_CLASS_ID,DH	     ;;AN002;; Check if class still exists at
ENDIF
;	      $IF     E 				     ;;AN002;;	pointer (hopefully)
	      JNE $MIF71
IF		FARmsg					     ;;AN001;;
		MOV	CL,BYTE PTR ES:[DI].$M_NUM_CLS_MSG   ;;AN000;;	   Get number of messages in class
ELSE
		MOV	CL,BYTE PTR CS:[DI].$M_NUM_CLS_MSG   ;;AN000;;	   Get number of messages in class
ENDIF
;	      $ENDIF					     ;;AN002;;	  go on to the next class
$MIF71:
;	    $ENDIF					     ;;AN001;;
$MEN69:
	    ADD     DI,$M_CLASS_ID_SZ			     ;;AN000;;	   Point past the class header
	    STC 					     ;;AN004;;	 Flag that we haven't found anything yet
;	  $ENDIF					     ;;AN004;;
$MEN64:

;	  $IF	  C					     ;;AN004;; Have we found anything yet?
	  JNC $MIF75
	    CLC 					     ;;AN004;; No, reset carry
;	    $SEARCH					     ;;AN000;;
$MDO76:
	      OR      CX,CX				     ;;AN000;;	  Do we have any to check?
;	    $LEAVE  Z					     ;;AN000;;	     No, return with CX = 0
	    JZ $MEN76
	      CMP     DH,UTILITY_MSG_CLASS		     ;;AN001;;
;	      $IF     NE				     ;;AN001;;
	      JE $MIF78
		CMP	AX,WORD PTR ES:[DI].$M_NUM	     ;;AN001;; Is this the message requested?
;	      $ELSE					     ;;AN001;;
	      JMP SHORT $MEN78
$MIF78:
IF		FARmsg					     ;;AN001;;
		CMP	AX,WORD PTR ES:[DI].$M_NUM	     ;;AN000;; Is this the message requested?
ELSE
		CMP	AX,WORD PTR CS:[DI].$M_NUM	     ;;AN000;; Is this the message requested?
ENDIF
;	      $ENDIF
$MEN78:
;	    $EXITIF E					     ;;AN000;;
	    JNE $MIF76
;	    $ORELSE					     ;;AN000;
	    JMP SHORT $MSR76
$MIF76:
	      DEC     CX				     ;;AN000;;	  No, well do we have more to check?
;	    $LEAVE  Z					     ;;AN000;;	     No, return with CX = 0
	    JZ $MEN76
	      ADD     DI,$M_ID_SZ			     ;;AN000;;	     Yes, skip past msg header
;	    $ENDLOOP					     ;;AN000;;
	    JMP SHORT $MDO76
$MEN76:
	      STC					     ;;AN000;;
;	    $ENDSRCH					     ;;AN000;;	     Check next message
$MSR76:
;	    $IF     NC					     ;;AN000;;	 Did we find the message?
	    JC $MIF86
	      CMP     DH,UTILITY_MSG_CLASS		     ;;AN001;;	 Yes, is it a utility message?
	      CLC					     ;;AN001;;
;	      $IF     E 				     ;;AN001;;
	      JNE $MIF87
IF		FARmsg					     ;;AN001;;
ELSE							     ;;AN000;;
		PUSH	CS				     ;;AN000;;
		POP	ES				     ;;AN000;;	 Return ES:DI pointing to the message
ENDIF
;	      $ENDIF					     ;;AN001;;
$MIF87:
	      ADD     DI,WORD PTR ES:[DI].$M_TXT_PTR	     ;;AN000;; Prepare ES:DI pointing to the message
;	    $ENDIF					     ;;AN004;;
$MIF86:
;	  $ENDIF					     ;;AN004;;
$MIF75:
							     ;; 	  Yes, great we can return with CX > 0

;	  $IF	  NC					     ;;AN000;;	 Did we find the message?
	  JC $MIF91
	    XOR     CH,CH				     ;;AN000;;
	    MOV     CL,BYTE PTR ES:[DI] 		     ;;AN000;;	 Move size into CX
	    INC     DI					     ;;AN000;;	 Increment past length
;	  $ENDIF					     ;;AN004;;
$MIF91:

	  MOV	  $M_RT.$M_SIZE,$M_NULL 		     ;;AN004;; Reset variable
	  RET						     ;;AN000;; Return
							     ;;
$M_FIND_SPECIFIED_MSG ENDP				     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ENDIF						     ;;AN000;; END of include of common subroutines
      ENDIF						     ;;AN000;; END of include of SYSGETMSG
; 
      IF      DISPLAYmsg				     ;;AN000;; Is the request to include the code for SYSGETMSG ?
	IF	COMR					     ;;AN000;;
	  $M_RT   EQU		   $M_RT2		     ;;AN000;;
	ENDIF						     ;;AN000;;
	DISPLAYmsg =  FALSE				     ;;AN000;; Yes, THEN include it and reset flag
	PAGE
	SUBTTL	DOS - Message Retriever - DISPMSG.ASM Module
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Proc Name:	SYSDISPMSG
;;
;;  Function:	The DISPLAY service will output a defined message to a handle
;;		requested by the caller. It also provides function to display
;;		messages when handles are not applicable (ie. DOS function calls
;;		00h to 0Ah) Replaceable parameters are allowed and are
;;		defined previous to entry.
;;
;;		It is assumes that a PRELOAD function has already determined
;;		the addressibilty internally to the message retriever services.
;;  Inputs:
;;
;;  Outputs:
;;
;;  Psuedocode:
;;		Save registers needed later
;;		Get address of the message requested
;;		IF Message number exists THEN
;;		  IF replacable parameters were specified THEN
;;		     Display message with replacable parms
;;		  ELSE
;;		     Display string without replacable parms
;;		  ENDIF
;;		  IF character input was requested THEN
;;		     Wait for character input
;;		  ENDIF
;;		  Clear CARRY FLAG
;;		ELSE
;;		   Set CARRY FLAG
;;		ENDIF
;;		Return
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
IF	FARmsg						     ;;AN000;;
	SYSDISPMSG PROC FAR				     ;;AN000;;
ELSE							     ;;AN000;;
	SYSDISPMSG PROC NEAR				     ;;AN000;;
ENDIF							     ;;AN000;;
							     ;;
;; Save registers and values needed later

	PUSH	AX					     ;;AN000;; Save changed REGs
	PUSH	BX					     ;;AN000;;
	PUSH	CX					     ;;AN000;;
	PUSH	BP					     ;;AN000;;
	PUSH	DI					     ;;AN000;; Save pointer to input buffer (offset)
	PUSH	ES					     ;;AN000;; Save pointer to input buffer (segment)
	PUSH	DX					     ;;AN000;; Save Input/Class request

	MOV	BP,CX					     ;;AN000;; Use BP to hold replace count
	MOV	WORD PTR $M_RT.$M_HANDLE,BX		     ;;AN000;; Save handle
	MOV	BYTE PTR $M_RT.$M_CLASS,DH		     ;;AN004;; Save class

;; Get address of the message requested

IF	FARmsg						     ;;AN000;;
	CALL	FAR PTR $M_GET_MSG_ADDRESS		     ;;AN000;; Scan thru classes to find message
ELSE							     ;;AN000;;
	CALL	$M_GET_MSG_ADDRESS			     ;;AN000;; Scan thru classes to find message
ENDIF							     ;;AN000;;
	OR	CX,CX					     ;;AN000;; Was message found?
;	$IF	NZ					     ;;AN000;;	 YES, Message address in ES:DI
	JZ $MIF93

;; Test if replacable parameters were specified

	  OR	  BP,BP 				     ;;AN000;;	 Were replacable parameters requested
;	  $IF	  Z					     ;;AN000;;
	  JNZ $MIF94

;; Display string without replacable parms

	    CALL    $M_DISPLAY_STRING			     ;;AN000;; No, great . . . Display message
;	  $ELSE 					     ;;AN000;;
	  JMP SHORT $MEN94
$MIF94:
IF	    $M_REPLACE					     ;;AN000;;

;; Display message with replacable parms

	    CALL    $M_DISPLAY_MESSAGE			     ;;AN000;;	 Display the message with substitutions
ENDIF							     ;;AN000;;
;	  $ENDIF					     ;;AN000;;
$MEN94:
;	  $IF	  NC
	  JC $MIF97

	    POP     DX					     ;;AN000;; Get Input/Class request

	    CALL    $M_ADD_CRLF 			     ;;AN004;; Check if we need to add the CR LF chars.

	    POP     ES					     ;;AN000;; Get location of input buffer (if specified)
	    POP     DI					     ;;AN000;;

;; Test if character input was requested

IF	    INPUTmsg					     ;;AN000;;
	    OR	    DL,DL				     ;;AN000;; Was Wait-For-Input requested?
;	    $IF     NZ					     ;;AN000;;
	    JZ $MIF98
	      CALL    $M_WAIT_FOR_INPUT 		     ;;AN000;;
;	    $ENDIF					     ;;AN000;;
$MIF98:
ENDIF							     ;;AN000;;
;	  $ELSE 					     ;;AN000;;
	  JMP SHORT $MEN97
$MIF97:
	    ADD     SP,6				     ;;AN000;;
	    STC 					     ;;AN000;; Reset carry flag
;	  $ENDIF					     ;;AN000;;
$MEN97:
;	$ELSE						     ;;AN000;; No,
	JMP SHORT $MEN93
$MIF93:
	  POP	  ES					     ;;AN000;;	 Get pointer to input buffer (segment)
	  POP	  DI					     ;;AN000;;	 Get base pointer to first sublist (offset)
	  POP	  DX					     ;;AN000;;	 Get base pointer to first sublist (segment)
	  STC						     ;;AN000;;	 Set carry flag
;	$ENDIF						     ;;AN000;;
$MEN93:
							     ;;
;	$IF	NC					     ;;AN000;; Was there an error?
	JC $MIF104
	  POP	  BP					     ;;AN000;; No,
	  POP	  CX					     ;;AN000;;
	  POP	  BX					     ;;AN000;;
IF	  INPUTmsg					     ;;AN000;;
	  ADD	  SP,2					     ;;AN000;;
ELSE							     ;AN000;
	  POP	  AX					     ;;AN000;;
ENDIF							     ;;AN000;;
;	$ELSE						     ;;AN000;;	Yes,
	JMP SHORT $MEN104
$MIF104:
	  ADD	  SP,8					     ;;AN000;;	   Eliminate from stack
	  STC						     ;;AN000;;
;	$ENDIF						     ;;AN000;;
$MEN104:
							     ;;
	RET						     ;;AN000;; Return
							     ;;
	SYSDISPMSG ENDP 				     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
;;
;;	PROC NAME: $M_DISPLAY_STRING
;;
;;	FUNCTION:  Will display or write string
;;	INPUTS:    ES:DI points to beginning of message
;;		   CX contains the length of string to write (if applicable)
;;	OUTPUTS:   None
;;	REGS Revised: None
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_DISPLAY_STRING PROC NEAR				     ;;AN000;;
							     ;;
	PUSH	AX					     ;;AN000;;
	PUSH	BX					     ;;AN000;;
	PUSH	DX					     ;;AN000;;
							     ;;
	MOV	BX,$M_RT.$M_HANDLE			     ;;AN000;; Retrieve handle
							     ;;
IF	COMR						     ;;  ** Special case for RESIDENT COMMAND.COM
	CALL	$M_DISPLAY_$_STRING			     ;;AN000;; No, display $ terminated string
ELSE
	CMP	BX,$M_NO_HANDLE 			     ;;AN000;; Was there a handle specified?
;	$IF	E					     ;;AN000;;
	JNE $MIF107
	  CALL	  $M_DISPLAY_$_STRING			     ;;AN000;; No, display $ terminated string
;	$ELSE						     ;;AN000;;
	JMP SHORT $MEN107
$MIF107:
	  CALL	  $M_DISPLAY_H_STRING			     ;;AN000;; Yes, display string to handle
;	$ENDIF						     ;;AN000;;
$MEN107:
							     ;AN001;
;	$IF	C					     ;;AN000;;	Was there an error?
	JNC $MIF110
	  MOV	  AH,DOS_GET_EXT_ERROR			     ;;AN000;;	Yes,
	  MOV	  BX,DOS_GET_EXT_ERROR_BX		     ;;AN000;;	  Get extended error
	  INT	  21H					     ;;AN000;;
	  XOR	  AH,AH 				     ;;AN000;;	  Clear AH
	  ADD	  SP,6					     ;;AN000;;	  Clean up stack
	  STC						     ;;AN000;;	  Flag that there was an error
;	$ELSE						     ;;AN000;;	No,
	JMP SHORT $MEN110
$MIF110:
	  CMP	  BX,$M_NO_HANDLE			     ;;AN000;; Was there a handle specified?
;	  $IF	  NE					     ;;AN000;;
	  JE $MIF112
	    CMP     AX,CX				     ;AN001;	 Was it ALL written?
;	    $IF     NE					     ;AN001;	 No,
	    JE $MIF113
	      CALL    $M_GET_EXT_ERR_39 		     ;AN001;	   Set Extended error
	      ADD     SP,6				     ;AN001;	   Clean up stack
	      STC					     ;AN001;	   Flag that there was an error
;	    $ENDIF					     ;AN001;
$MIF113:
;	  $ENDIF					     ;AN001;
$MIF112:
;	$ENDIF						     ;;AN000;;
$MEN110:
ENDIF
;	$IF	NC					     ;;AN000;;	Was there ANY error?
	JC $MIF117
	  POP	  DX					     ;;AN000;;	Restore regs
	  POP	  BX					     ;;AN000;;
	  POP	  AX					     ;;AN000;;
;	$ENDIF						     ;;AN000;;
$MIF117:
	RET						     ;;AN000;; Return
							     ;;
$M_DISPLAY_STRING ENDP					     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_DISPLAY_$_STRING
;;
;;	FUNCTION:  Will display a $ terminated string
;;	INPUTS:    ES:DI points to beginning of message text (not the length)
;;	OUPUTS:    None
;;	REGS USED: AX,DX
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_DISPLAY_$_STRING PROC NEAR				     ;;AN000;;
							     ;;
	PUSH	DS					     ;;AN000;;
	PUSH	ES					     ;;AN000;;
	POP	DS					     ;;AN000;; Set DS to segment of message text
IF	NOT	COMR
	CMP	CX,$M_SINGLE_CHAR			     ;;AN000;; Is this a single character?
;	$IF	E					     ;;AN000;; Yes,
	JNE $MIF119
	  MOV	  AH,DOS_DISP_CHAR			     ;;AN000;;	 DOS Function to display CHARACTER
	  MOV	  DL,BYTE PTR ES:[DI]			     ;;AN000;;	 Get the character
	  INT	  21H					     ;;AN000;;	 Write character
	  POP	  DS					     ;;AN000;; Set DS to segment of message text
	  MOV	  AL,DL 				     ;;AN000;;	 Get the character in AL
	  CALL	  $M_IS_IT_DBCS 			     ;;AN000;;	 Is this the first byte of a DB character
	  PUSH	  DS					     ;;AN000;;
	  PUSH	  ES					     ;;AN000;;
	  POP	  DS					     ;;AN000;; Set DS to segment of message text
;	  $IF	  C					     ;;AN000;;	 Yes,
	  JNC $MIF120
	    MOV     DL,BYTE PTR ES:[DI]+1		     ;;AN000;; Get the next character
	    INT     21H 				     ;;AN000;;	 Write character
	    CLC 					     ;;AN000;;	 Clear the DBCS indicator
;	  $ENDIF					     ;;AN000;;
$MIF120:
;	$ELSE						     ;;AN000;; No,
	JMP SHORT $MEN119
$MIF119:
ENDIF
	  MOV	  AH,DOS_DISP_CHAR			     ;;AN000;;	 DOS Function to display CHARACTER
;	  $DO						     ;;AN002;; No,
$MDO123:
	    OR	    CX,CX				     ;;AN002;;	 Are there any left to display?
;	  $LEAVE  Z					     ;;AN002;;	 Yes,
	  JZ $MEN123
	    MOV     DL,BYTE PTR ES:[DI] 		     ;;AN002;;	   Get the character
	    INT     21H 				     ;;AN002;;	   Display the character
	    INC     DI					     ;;AN002;;	   Set pointer to next character
	    DEC     CX					     ;;AN002;;	   Count this character
;	  $ENDDO  Z					     ;;AN002;; No,
	  JNZ $MDO123
$MEN123:
IF	  NOT	  COMR
;	$ENDIF						     ;;AN000;;
$MEN119:
ENDIF
	CLC						     ;;AN000;;	 Char functions used don't return carry as error
	POP	DS					     ;;AN000;;
	RET						     ;;AN000;;
							     ;;
$M_DISPLAY_$_STRING ENDP				     ;;AN000;;
							     ;;
IF	NOT	COMR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_DISPLAY_H_STRING
;;
;;	FUNCTION:  Will display a string to a specified handle
;;	INPUTS:    ES:DI points to beginning of message
;;		   CX contains the number of bytes to write
;;		   BX contains the handle to write to
;;	OUPUTS:    None
;;	REGS USED: AX,DX
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_DISPLAY_H_STRING PROC NEAR				     ;;AN000;;
							     ;;
	XOR	AX,AX					     ;;AN002;; Set number of bytes written to 0
	OR	CX,CX					     ;;AN002;; For performance, don't write if not necessary
;	$IF	NZ					     ;;AN002;; Any chars to write?
	JZ $MIF127
	  PUSH	  DS					     ;;AN000;; Yes,
	  PUSH	  ES					     ;;AN000;;
	  POP	  DS					     ;;AN000;;	 Set DS to segment of message text
	  MOV	  AH,DOS_WRITE_HANDLE			     ;;AN000;;	 DOS function to write to a handle
	  MOV	  DX,DI 				     ;;AN000;;	 Pointer to data to write
	  CMP	  CX,$M_SINGLE_CHAR			     ;;AN000;;	 Is this a single character?
;	  $IF	  E					     ;;AN000;;	 Yes,
	  JNE $MIF128
	    INT     21H 				     ;;AN000;;	   Write character
	    POP     DS					     ;;AN000;;	     Set DS to segment of message text
	    PUSH    AX					     ;;AN000;;
	    MOV     AL,BYTE PTR ES:[DI] 		     ;;AN000;;	     Get the character
	    CALL    $M_IS_IT_DBCS			     ;;AN000;;	     Is this the first byte of a DB character
	    POP     AX					     ;;AN000;;	     Set DS to segment of message text
	    PUSH    DS					     ;;AN000;;
	    PUSH    ES					     ;;AN000;;
	    POP     DS					     ;;AN000;;	     Set DS to segment of message text
;	    $IF     C					     ;;AN000;;	     Yes,
	    JNC $MIF129
	      CLC					     ;;AN000;;	      Clear the DBCS indicator
	      MOV     AH,DOS_WRITE_HANDLE		     ;;AN000;;	      DOS function to write to a handle
	      INC     DX				     ;;AN000;;	      Point to next character
	      INT     21H				     ;;AN000;;	      Write character
;	    $ENDIF					     ;;AN000;;
$MIF129:
;	  $ELSE 					     ;;AN000;;	 No,
	  JMP SHORT $MEN128
$MIF128:
	    INT     21H 				     ;;AN000;;	   Write String at DS:SI to handle
;	  $ENDIF					     ;;AN000;;
$MEN128:
	  POP	  DS					     ;;AN000;;
;	$ENDIF						     ;;AN002;;
$MIF127:
							     ;;
	RET						     ;;AN000;;
							     ;;
$M_DISPLAY_H_STRING ENDP				     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_GET_EXT_ERR_39
;;
;;	FUNCTION:  Will set registers for extended error #39
;;	INPUTS:    None
;;	OUPUTS:    AX,BX,CX set
;;	REGS USED:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_GET_EXT_ERR_39 PROC NEAR				     ;AN001;
							     ;;
	MOV	AX,EXT_ERR_39				     ;AN001; Set AX=39
	MOV	BX,(ERROR_CLASS_39 SHR 8) + ACTION_39	     ;AN001; Set BH=1 BL=4
	MOV	CH,LOCUS_39				     ;AN001; Set CH=1
							     ;AN001;
	RET						     ;AN001;
							     ;;
$M_GET_EXT_ERR_39 ENDP					     ;AN001;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ENDIF
;;
;;	PROC NAME: $M_ADD_CRLF
;;
;;	FUNCTION:  Will decide whether to display a CRLF
;;	INPUTS:    DX contains the Input/Class requested
;;	OUTPUTS:   None
;;	REGS Revised: CX,ES,DI
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_ADD_CRLF PROC NEAR					     ;;AN004;;
							     ;;
	CMP	DH,UTILITY_MSG_CLASS			     ;;AN004;; Is it a utility message?
;	$IF	NE					     ;;AN004;; No,
	JE $MIF134
	  TEST	  DH,$M_NO_CRLF_MASK			     ;;AN004;;	 Are we to supress the CR LF?
;	  $IF	  Z					     ;;AN004;;	 No,
	  JNZ $MIF135
	    PUSH    DS					     ;;AN004;;
	    POP     ES					     ;;AN004;;	  Set ES to data segment
	    LEA     DI,$M_RT.$M_CRLF			     ;;AN004;;	  Point at CRLF message
	    MOV     CX,$M_CRLF_SIZE			     ;;AN004;;	  Set the message size
	    CALL    $M_DISPLAY_STRING			     ;;AN004;;	  Display the CRLF
;	  $ENDIF					     ;;AN004;;
$MIF135:
;	$ENDIF						     ;;AN004;;
$MIF134:
	RET						     ;;AN004;; Return
							     ;;
$M_ADD_CRLF ENDP					     ;;AN004;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_IS_IT_DBCS
;;
;;	FUNCTION:  Will decide whether character is Single or Double Byte
;;	INPUTS:    AL contains the byte to be checked
;;	OUPUTS:    Carry flag = 0 if byte is NOT in DBCS range
;;		   Carry flag = 1 if byte IS in DBCS range
;;	REGS USED: All restored
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_IS_IT_DBCS PROC NEAR 				     ;;AN000;;
							     ;;
	PUSH	ES					     ;;AN000;; Save Extra segment register
	PUSH	DI					     ;;AN000;; Save SI register
							     ;;
	LES	DI,$M_RT.$M_DBCS_VEC			     ;;AN000;;
	OR	DI,DI					     ;;AN000;; Was the DBCS vector set?
;	$IF	NZ					     ;;AN000;;
	JZ $MIF138
;	  $DO						     ;;AN000;;
$MDO139:
	    CMP     WORD PTR ES:[DI],$M_DBCS_TERM	     ;;AN000;; Is this the terminating flag?
	    CLC 					     ;;AN000;;
;	  $LEAVE  E					     ;;AN000;;
	  JE $MEN139
							     ;;        No,
	    CMP     AL,BYTE PTR ES:[DI] 		     ;;AN000;;	  Does the character fall in the DBCS range?
;	    $IF     AE,AND				     ;;AN000;;
	    JNAE $MIF141
	    CMP     AL,BYTE PTR ES:[DI]+1		     ;;AN000;;	  Does the character fall in the DBCS range?
;	    $IF     BE					     ;;AN000;;
	    JNBE $MIF141
	      STC					     ;;AN000;;	  Yes,
;	    $ENDIF					     ;;AN000;;	     Set carry flag
$MIF141:
	    INC     DI					     ;;AN000;;	  No,
	    INC     DI					     ;;AN000;;	     Go to next vector
;	  $ENDDO					     ;;AN000;;
	  JMP SHORT $MDO139
$MEN139:
;	$ENDIF						     ;;AN000;;
$MIF138:

	POP	DI					     ;;AN000;;
	POP	ES					     ;;AN000;; Restore SI register
	RET						     ;;AN000;; Return
							     ;;
$M_IS_IT_DBCS ENDP					     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_CONVERT2ASC
;;
;;	FUNCTION: Convert a binary number to a ASCII string
;;	INPUTS: DX:AX contains the number to be converted
;;		$M_RT_DIVISOR contains the divisor
;;	OUPUTS: CX contains the number of characters
;;		Top of stack  --> Last character
;;				     . . .
;;		Bot of stack  --> First character
;;	REGS USED:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_CONVERT2ASC PROC NEAR				     ;;AN000;;
							     ;;
	POP	[$M_RT.$M_RETURN_ADDR]			     ;;AN000;; Save Return Address
	XOR	BX,BX					     ;;AN000;; Use BP as a swapping register
							     ;;
	XCHG	BX,AX					     ;;AN000;; Initialize - Low Word in BP
	XCHG	AX,DX					     ;;AN000;;		  - High Word in AX
;	$DO						     ;;AN000;; DO UNTIL Low Word becomes zero
$MDO145:
	  DIV	  $M_RT.$M_DIVISOR			     ;;AN000;; Divide High Word by divisor
	  XCHG	  BX,AX 				     ;;AN000;; Setup to divide Low Word using remainder
							     ;; 	and save reduced High Word in BP
	  DIV	  $M_RT.$M_DIVISOR			     ;;AN000;; Divide Low Word by divisor
	  CMP	  DX,9					     ;;AN000;;	Make a digit of the remainder
;	  $IF	  A					     ;;AN000;;	IF 10 to 15,
	  JNA $MIF146
	    ADD     DL,55				     ;;AN000;;	   Make A to F ASCII
;	  $ELSE 					     ;;AN000;;	IF 0 to 9,
	  JMP SHORT $MEN146
$MIF146:
	    ADD     DL,'0'				     ;;AN000;;	   Make 0 to 9 ASCII
;	  $ENDIF					     ;;AN000;;
$MEN146:
	  PUSH	  DX					     ;;AN000;; Save the digit on the stack
	  INC	  CX					     ;;AN000;; Count that digit
	  OR	  AX,AX 				     ;;AN000;; Are we done?
;	$LEAVE	Z,AND					     ;;AN000;;
	JNZ $MLL149
	  OR	  BX,BX 				     ;;AN000;; AX and BX must be ZERO!!
;	$LEAVE	Z					     ;;AN000;; No,
	JZ $MEN145
$MLL149:
IF	  NOT	  COMR
	  CMP	  CX,$M_FIRST_THOU			     ;;AN000;; Are we at the first thousands mark
;	  $IF	  E					     ;;AN000;; Yes,
	  JNE $MIF150
	    CMP     $M_SL.$M_S_PAD,$M_COMMA		     ;;AN000;; Is the pad character a comma?
;	    $IF     E					     ;;AN000;; Yes,
	    JNE $MIF151
	      PUSH    WORD PTR $M_RT.$M_THOU_SEPARA	     ;;AN000;; Insert a thousand separator
	      INC     CX				     ;;AN000;;
;	    $ENDIF					     ;;AN000;;
$MIF151:
;	  $ELSE 					     ;;AN000;; No,
	  JMP SHORT $MEN150
$MIF150:
	    CMP     CX,$M_SECOND_THOU			     ;;AN000;;	 Are we at the first thousands mark
;	    $IF     E					     ;;AN000;;	      Yes,
	    JNE $MIF154
	      CMP     $M_SL.$M_S_PAD,$M_COMMA		     ;;AN000;; Is the pad character a comma?
;	      $IF     E 				     ;;AN000;; Yes,
	      JNE $MIF155
		PUSH	WORD PTR $M_RT.$M_THOU_SEPARA	     ;;AN000;; Insert a thousand separator
		INC	CX				     ;;AN000;;
;	      $ENDIF					     ;;AN000;;
$MIF155:
;	    $ELSE					     ;;AN000;;	      No,
	    JMP SHORT $MEN154
$MIF154:
	      CMP     CX,$M_THIRD_THOU			     ;;AN000;;	 Are we at the first thousands mark
;	      $IF     E 				     ;;AN000;;		Yes,
	      JNE $MIF158
		CMP	$M_SL.$M_S_PAD,$M_COMMA 	     ;;AN000;; Is the pad character a comma?
;		$IF	E				     ;;AN000;; Yes,
		JNE $MIF159
		  PUSH	  WORD PTR $M_RT.$M_THOU_SEPARA      ;;AN000;; Insert a thousand separator
		  INC	  CX				     ;;AN000;;
;		$ENDIF					     ;;AN000;;
$MIF159:
;	      $ENDIF					     ;;AN000;;
$MIF158:
;	    $ENDIF					     ;;AN000;;
$MEN154:
;	  $ENDIF					     ;;AN000;;
$MEN150:
ENDIF
	  XCHG	  AX,BX 				     ;;AN000;;	 Setup to divide the reduced High Word
							     ;;AN000;;	   and Revised Low Word
	  XOR	  DX,DX 				     ;;AN000;;	 Reset remainder
;	$ENDDO						     ;;AN000;;	 NEXT
	JMP SHORT $MDO145
$MEN145:
							     ;;AN000;; Yes,
	XOR	DX,DX					     ;;AN000;;	 Reset remainder
	XOR	AX,AX					     ;;AN000;;	 Reset remainder
	PUSH	[$M_RT.$M_RETURN_ADDR]			     ;;AN000;;	 Restore Return Address
	RET						     ;;AN000;;	 Return
							     ;;
$M_CONVERT2ASC ENDP					     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_DISPLAY_MESSAGE
;;
;;	FUNCTION:  Will display or write entire message (with replacable parameters)
;;	INPUTS:    ES:DI points to beginning of message
;;		   DS:SI points to first sublist structure in chain
;;		   BX contains the handle to write to (if applicable)
;;		   CX contains the length of string to write (before substitutions)
;;		   BP contains the count of replacables
;;
;;	OUTPUTS:
;;	REGS USED: All
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_DISPLAY_MESSAGE PROC NEAR				     ;;AN000;;
							     ;;
;	$DO						     ;;AN000;; Note: DS:SI -> message
$MDO165:
	  XOR	  DX,DX 				     ;;AN000;; Set size = 0
	  OR	  CX,CX 				     ;;AN000;; Are we finished the message yet?
;	  $IF	  NZ					     ;;AN000;; No,
	  JZ $MIF166
	    MOV     AH,"%"				     ;;AN000;;	 Prepare to scan for %
	    MOV     AL,0				     ;;AN004;;
							     ;;
;	    $DO 					     ;;AN000;;	 Scan through string until %
$MDO167:
	      CMP     BYTE PTR ES:[DI],AH		     ;;AN000;;	 Is this character NOT a %
;	    $LEAVE  E,AND				     ;;AN000;;	 No,
	    JNE $MLL168
	      CMP     BYTE PTR ES:[DI+1],AH		     ;;AN000;;	   Is the next character also a %
;	    $LEAVE  NE,AND				     ;;AN000;;	   No,
	    JE $MLL168
	      CMP     AL,AH				     ;;AN000;;	     Was the character before a %
;	    $LEAVE  NE					     ;;AN000;;	     No, GREAT found it
	    JNE $MEN167
$MLL168:
	      MOV     AL,BYTE PTR ES:[DI]		     ;;AN004;;	 Yes, (to any of the above)
	      CALL    $M_IS_IT_DBCS			     ;;AN004;;	   Is this character the first part of a DBCS?
;	      $IF     C 				     ;;AN004;;	   Yes,
	      JNC $MIF169
		INC	DI				     ;;AN004;;	     Increment past second part
;	      $ENDIF					     ;;AN004;;
$MIF169:
	      INC     DI				     ;;AN000;;	     Next character in string
	      INC     DX				     ;;AN000;;	     Size = Size + 1
	      DEC     CX				     ;;AN000;;	     Decrement total size
;	    $ENDDO  Z					     ;;AN000;;	 Exit scan if we're at the end of the line
	    JNZ $MDO167
$MEN167:
;	  $ENDIF					     ;;AN000;;
$MIF166:
							     ;;
	  PUSH	  SI					     ;;AN000;; Save beginning of sublists
	  XCHG	  CX,DX 				     ;;AN000;; Get size of message to display (tot sz in DX)
	  OR	  BP,BP 				     ;;AN000;; Do we have any replacables to do?
;	  $IF	  NZ					     ;;AN000;; Yes,
	  JZ $MIF173
	    DEC     BP					     ;;AN000;;	 Decrement number of replacables

;; Search through sublists to find applicable one

	    CMP     $M_RT.$M_MSG_NUM,$M_NULL		     ;;AN000;; Is this an Extended/Parse case
;	    $IF     E					     ;;AN000;; No,
	    JNE $MIF174
;	      $SEARCH					     ;;AN000;;
$MDO175:
		MOV	AL,$M_SL.$M_S_ID		     ;;AN000;;	 Get ID byte
		ADD	AL,30H				     ;;AN000;;	 Convert to ASCII
		CMP	AL,BYTE PTR ES:[DI]+1		     ;;AN000;;	 Is this the right sublist?
;	      $EXITIF E 				     ;;AN000;;
	      JNE $MIF175
;	      $ORELSE					     ;;AN000;;	 No,
	      JMP SHORT $MSR175
$MIF175:
		CMP	AL,$M_SPECIAL_CASE		     ;;AN000;;	   Does this sublist have ID = 0
;	      $LEAVE  E,AND				     ;;AN000;;	   Yes,
	      JNE $MLL178
		OR	DX,DX				     ;;AN000;;	   Are we at the end of the message?
;	      $LEAVE  Z 				     ;;AN000;;	   No,
	      JZ $MEN175
$MLL178:
		ADD	SI,WORD PTR $M_SL.$M_S_SIZE	     ;;AN000;;	     Next SUBLIST
;	      $ENDLOOP					     ;;AN000;;	   Yes,
	      JMP SHORT $MDO175
$MEN175:
		CMP	$M_RT.$M_CLASS,UTILITY_MSG_CLASS     ;;AN004;;	     Is it a utility message?
;		$IF	E				     ;;AN004;;	     Yes,
		JNE $MIF180
		  INC	  DX				     ;;AN000;;	       Remember to display CR,LF
		  INC	  DX				     ;;AN000;;		 at the end of the message
		  DEC	  CX				     ;;AN000;;	       Adjust message length
		  DEC	  CX				     ;;AN000;;
		  DEC	  DI				     ;;AN000;;	       Adjust ending address of message
		  DEC	  DI				     ;;AN000;;
;		$ELSE					     ;;AN004;;	     No,
		JMP SHORT $MEN180
$MIF180:
		  MOV	  DX,-1 			     ;;AN004;;	       Set special case
;		$ENDIF					     ;;AN004;;
$MEN180:
;	      $ENDSRCH					     ;;AN000;;
$MSR175:
;	    $ENDIF					     ;;AN000;;
$MIF174:
;	  $ENDIF					     ;;AN000;;
$MIF173:

;; Prepare and display this part of message

	  PUSH	  DI					     ;;AN000;; Save pointer to replace number
	  SUB	  DI,CX 				     ;;AN000;; Determine beginning of string
	  CALL	  $M_DISPLAY_STRING			     ;;AN000;; Display string until % (or end)
	  POP	  DI					     ;;AN000;; Get back pointer to replace number
	  POP	  CX					     ;;AN000;; Clean up stack in case error
;	$LEAVE	C,LONG					     ;;AN000;; Fail if carry was set
	JNC $MXL3
	JMP $MEN165
$MXL3:
	  PUSH	  CX					     ;;AN000;;

;; Save and reset pointer registers

	  MOV	  CX,DX 				     ;;AN000;; Get the size of the rest of the message
	  CMP	  $M_SL.$M_S_ID,$M_SPECIAL_CASE-30H	     ;;AN000;; Is this the %0 case?
;	  $IF	  NE					     ;;AN000;; No,
	  JE $MIF187
	    OR	    CX,CX				     ;;AN000;;	Are we finished the whole message?
;	    $IF     NZ					     ;;AN000;;	No,
	    JZ $MIF188
	      DEC     CX				     ;;AN000;;	  Decrement total size (%)
	      DEC     CX				     ;;AN000;;	  Decrement total size (#)
	      INC     DI				     ;;AN000;;	  Go past %
	      INC     DI				     ;;AN000;;	  Go past replace number
;	    $ELSE					     ;;AN000;;	Yes, (Note this will not leave because INC)
	    JMP SHORT $MEN188
$MIF188:
	      POP     SI				     ;;AN000;;	  Get back pointer to beginning of SUBLISTs
;	    $ENDIF					     ;;AN000;; Yes, Note this will not leave because INC
$MEN188:
;	  $ELSE 					     ;;AN000;;
	  JMP SHORT $MEN187
$MIF187:
	    OR	    CX,CX				     ;;AN000;;	Are we finished the whole message?
;	    $IF     Z					     ;;AN004;;	 No,
	    JNZ $MIF192
	      POP     SI				     ;;AN000;;	 Get back pointer to beginning of SUBLISTs
;	    $ELSE					     ;;AN000;; No,
	    JMP SHORT $MEN192
$MIF192:
	      CMP     CX,-1				     ;;AN004;;	 Are we at the end of the message?
;	      $IF     Z 				     ;;AN004;;	 No,
	      JNZ $MIF194
		XOR	CX,CX				     ;;AN004;;
;	      $ENDIF					     ;;AN000;;
$MIF194:
	      OR      DI,DI				     ;;AN004;;	Turn ZF off
;	    $ENDIF					     ;;AN000;;
$MEN192:
;	  $ENDIF					     ;;AN000;; Note this will not leave because INC
$MEN187:
;	$LEAVE	Z					     ;;AN000;;
	JZ $MEN165
	  PUSH	  BP					     ;;AN000;;	 Save the replace count
	  PUSH	  DI					     ;;AN000;;	 Save location to complete message
	  PUSH	  ES					     ;;AN000;;
	  PUSH	  CX					     ;;AN000;;	 Save size of the rest of the message
	  XOR	  CX,CX 				     ;;AN000;;	 Reset CX used for character count

;; Determine what action is required on parameter

	  CMP	  $M_RT.$M_MSG_NUM,$M_NULL		     ;;AN000;; Is this an Extended/Parse case
;	  $IF	  E					     ;;AN000;;
	  JNE $MIF199

IF	    CHARmsg					     ;;AN000;; Was Char specified?
	    TEST    BYTE PTR $M_SL.$M_S_FLAG,NOT Char_Type AND $M_TYPE_MASK ;;AN000;;
;	    $IF     Z					     ;;AN000;;
	    JNZ $MIF200

;; Character type requested
							     ;;AN000;;
	      LES     DI,DWORD PTR $M_SL.$M_S_VALUE	     ;;AN000;; Load pointer to replacing parameter
	      CALL    $M_CHAR_REPLACE			     ;;AN000;;
;	    $ELSE					     ;;AN000;;	 Get the rest of the message to display
	    JMP SHORT $MEN200
$MIF200:
ENDIF							     ;;AN000;;
IF	      NUMmsg					     ;;AN000;; Was Nnmeric type specified?
	      TEST    BYTE PTR $M_SL.$M_S_FLAG,NOT Sgn_Bin_Type AND $M_TYPE_MASK ;;AN000;;
;	      $IF     Z,OR				     ;;AN000;;
	      JZ $MLL202
	      TEST    BYTE PTR $M_SL.$M_S_FLAG,NOT Unsgn_Bin_Type AND $M_TYPE_MASK ;;AN000;;
;	      $IF     Z,OR				     ;;AN000;;
	      JZ $MLL202
	      TEST    BYTE PTR $M_SL.$M_S_FLAG,NOT Bin_Hex_Type AND $M_TYPE_MASK ;;AN000;;
;	      $IF     Z 				     ;;AN000;;
	      JNZ $MIF202
$MLL202:

;; Numeric type requested

		LES	DI,DWORD PTR $M_SL.$M_S_VALUE	     ;;AN000;; Load pointer to replacing parameter
		CALL	$M_BIN2ASC_REPLACE		     ;;AN000;;
;	      $ELSE					     ;;AN000;; Get the rest of the message to display
	      JMP SHORT $MEN202
$MIF202:
ENDIF							     ;;AN000;;
IF		DATEmsg 				     ;;AN000;; Was date specified?
		TEST	BYTE PTR $M_SL.$M_S_FLAG,NOT Date_Type AND $M_TYPE_MASK ;;AN000;;
;		$IF	E				     ;;AN000;;
		JNE $MIF204

;; Date type requested

		  CALL	  $M_DATE_REPLACE		     ;;AN000;;
;		$ELSE					     ;;AN000;; Get the rest of the message to display
		JMP SHORT $MEN204
$MIF204:
ENDIF							     ;;AN000;;
IF		  TIMEmsg				     ;;AN000;;	Was time (12 hour format) specified?

;; Time type requested (Default if we have not matched until here)

		  CALL	  $M_TIME_REPLACE		     ;;AN000;;
ENDIF							     ;;AN000;;

IF		  DATEmsg				     ;;AN000;;
;		$ENDIF					     ;;AN000;;
$MEN204:
ENDIF							     ;;AN000;;
IF		NUMmsg					     ;;AN000;;
;	      $ENDIF					     ;;AN000;;
$MEN202:
ENDIF							     ;;AN000;;
IF	      CHARmsg					     ;;AN000;;
;	    $ENDIF					     ;;AN000;;
$MEN200:
ENDIF							     ;;AN000;;

IF	    $M_REPLACE					     ;;AN000;;
;; With the replace information of the Stack, display the replaceable field

	    CALL    $M_DISPLAY_REPLACE			     ;;AN000;; Display the replace
ENDIF							     ;;AN000;;
;; None of the above - Extended/Parse replace
;	  $ELSE 					     ;;AN000;;
	  JMP SHORT $MEN199
$MIF199:
IF	    NOT     COMR
	    CALL    $M_EXT_PAR_REPLACE			     ;;AN000;;
ENDIF
;	  $ENDIF					     ;;AN000;;
$MEN199:

;; We must go back and complete the message after the replacable parameter if there is any left

;	  $IF	  NC					     ;;AN000;; IF there was an error displaying then EXIT
	  JC $MIF211
	    POP     CX					     ;;AN000;; Get size of the rest of the message
	    POP     ES					     ;;AN000;; Get address of the rest of the message
	    POP     DI					     ;;AN000;;
	    POP     BP					     ;;AN000;; Get replacment count
	    POP     SI					     ;;AN000;; ELSE get address of first sublist structure
;	  $ELSE 					     ;;AN000;;
	  JMP SHORT $MEN211
$MIF211:
	    ADD     SP,10				     ;;AN000;; Clean up stack if error
	    STC 					     ;;AN000;;
;	  $ENDIF					     ;;AN000;;
$MEN211:
	  CMP	  $M_RT.$M_MSG_NUM,$M_NULL		     ;;AN000;; Is this an Extended/Parse case
;	$ENDDO	NE,OR					     ;;AN000;;
	JNE $MLL214
;	$ENDDO	C,LONG					     ;;AN000;; Go back and display the rest of the message
	JC $MXL4
	JMP $MDO165
$MXL4:
$MLL214:
$MEN165:
							     ;;        IF there was an error displaying then EXIT
	MOV	$M_RT.$M_MSG_NUM,0			     ;;AN000;; Reset message number to null
	RET						     ;;AN000;; Return
							     ;;
$M_DISPLAY_MESSAGE ENDP 				     ;;AN000;;
IF	NOT	COMR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_EXT_PAR_REPLACE
;;
;;	FUNCTION:
;;	INPUTS:
;;	OUPUTS:
;;
;;	REGS USED:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_EXT_PAR_REPLACE PROC NEAR				     ;;AN000;;
							     ;;
	XOR	DX,DX					     ;;AN000;; Prepare for get binary value (HIGH)
	MOV	AX,$M_RT.$M_MSG_NUM			     ;;AN000;; Prepare for get binary value (LOW)
	MOV	$M_RT.$M_DIVISOR,$M_BASE10		     ;;AN000;; Set default divisor
							     ;;
	CALL	$M_CONVERT2ASC				     ;;AN000;;
							     ;;
;	$DO						     ;;AN000;;
$MDO215:
	  POP	  AX					     ;;AN000;;	 Get character in register
	  MOV	  BYTE PTR $M_RT.$M_TEMP_BUF[BX],AL	     ;;AN000;;	Move char into the buffer
	  INC	  BX					     ;;AN000;;	 Increase buffer count
	  CMP	  BX,$M_TEMP_BUF_SZ			     ;;AN000;;	 Is buffer full?
;	  $IF	  E					     ;;AN000;;	 Yes,
	  JNE $MIF216
	    CALL    $M_FLUSH_BUF			     ;;AN000;;	   Flush the buffer
;	  $ENDIF					     ;;AN000;;
$MIF216:
	  DEC	  CL					     ;;AN000;;	 Have we completed replace?
;	$ENDDO	Z					     ;;AN000;;
	JNZ $MDO215
							     ;;
	MOV	AX,$M_CR_LF				     ;;AN000;;	Move char into the buffer
	MOV	WORD PTR $M_RT.$M_TEMP_BUF[BX],AX	     ;;AN000;;	Move char into the buffer
	INC	BX					     ;;AN000;;	 Increase buffer count
	INC	BX					     ;;AN000;;	 Increase buffer count
	CALL	$M_FLUSH_BUF				     ;;AN000;;	   Flush the buffer
	RET						     ;;AN000::
							     ;;
$M_EXT_PAR_REPLACE ENDP 				     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ENDIF
	IF	$M_SUBS 				     ;;AN000;; Include the common subroutines if they haven't yet
	  $M_SUBS = FALSE				     ;;AN000;; No, then include and reset the flag
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_GET_MSG_ADDRESS
;;
;;	FUNCTION:  To scan thru classes to return pointer to the message header
;;	INPUTS:    Access to $M_RES_ADDRESSES
;;	OUPUTS:    IF CX = 0 THEN Message was not found
;;		   IF CX > 1 THEN DS:SI points to the specified message
;;	REGS CHANGED: ES,DI,CX,DS,SI
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
IF	  FARmsg					     ;;AN000;;
	  $M_GET_MSG_ADDRESS PROC FAR			     ;;AN000;;
ELSE							     ;;AN000;;
	  $M_GET_MSG_ADDRESS PROC NEAR			     ;;AN000;;
ENDIF							     ;;AN000;;
							     ;;
	  PUSH	  SI					     ;;AN000;;
	  PUSH	  BX					     ;;AN000;;
	  XOR	  SI,SI 				     ;;AN000;; Use SI as an index
	  XOR	  CX,CX 				     ;;AN000;; Use CX as an size
;	  $DO						     ;;AN000;;
$MDO219:
	    CMP     DH,UTILITY_MSG_CLASS		     ;;AN000;; Were utility messages requested?
;	    $IF     E					     ;;AN000;; Yes,
	    JNE $MIF220
	      IF      FARmsg				     ;;AN000;;
		LES	DI,DWORD PTR $M_RT.$M_CLASS_ADDRS[SI] ;;AN000;;  Get address of class
		MOV	BX,ES				     ;;AN000;
	      ELSE					     ;;AN000;;
		MOV	DI,WORD PTR $M_RT.$M_CLASS_ADDRS[SI] ;;AN000;;	 Get address of class
		MOV	BX,DI				     ;;AN000;
	      ENDIF					     ;;AN000;;
;	    $ELSE					     ;;AN000;; No,
	    JMP SHORT $MEN220
$MIF220:
	      TEST    DH,PARSE_ERR_CLASS		     ;;AN000;;	 Were parse errors requested?
;	      $IF     NE				     ;;AN000;;	 Yes,
	      JE $MIF222
		LES	DI,DWORD PTR $M_RT.$M_PARSE_COMMAND[SI] ;;AN000;;   Get address of class
		MOV	BX,ES				     ;;AN000;
;	      $ELSE					     ;;AN000;;	 No, extended errors were specified
	      JMP SHORT $MEN222
$MIF222:
		CMP	AX,$M_CRIT_LO			     ;;AN000;;	   Is this a critical error?
;		$IF	AE,AND				     ;;AN000;;
		JNAE $MIF224
		CMP	AX,$M_CRIT_HI			     ;;AN000;;
;		$IF	BE				     ;;AN000;;	    Yes,
		JNBE $MIF224
		  LES	  DI,DWORD PTR $M_RT.$M_CRIT_ADDRS[SI] ;;AN000;; Get address of class
		  MOV	  BX,ES 			     ;;AN000;
;		$ELSE					     ;;AN000;;
		JMP SHORT $MEN224
$MIF224:
		  LES	  DI,DWORD PTR $M_RT.$M_EXT_ERR_ADDRS[SI] ;;AN000;; Get address of class
		  MOV	  BX,ES 			     ;;AN000;
;		$ENDIF					     ;;AN000;;
$MEN224:
;	      $ENDIF					     ;;AN000;;
$MEN222:
;	    $ENDIF					     ;;AN000;;
$MEN220:
							     ;;
	    CMP     BX,$M_TERMINATING_FLAG		     ;;AN000;; Are we finished all classes?
;	    $IF     E					     ;;AN000;; Yes,
	    JNE $MIF229
	      CMP     DH,UTILITY_MSG_CLASS		     ;;AN000;;	  Was it a UTILITY class?
;	      $IF     E 				     ;;AN000;;	  Yes,
	      JNE $MIF230
		STC					     ;;AN000;;	    Set the carry flag
;	      $ELSE					     ;;AN000;;	  No,
	      JMP SHORT $MEN230
$MIF230:
		MOV	$M_RT.$M_MSG_NUM,AX		     ;;AN000;;	    Save message number
		MOV	AX,$M_SPECIAL_MSG_NUM		     ;;AN000;;	    Set special message number
		MOV	BP,$M_ONE_REPLACE		     ;;AN000;;	    Set one replace in message
		XOR	SI,SI				     ;;AN000;;	    Reset the SI index to start again
		CLC					     ;;AN000;;
;	      $ENDIF					     ;;AN000;; No,
$MEN230:
;	    $ELSE					     ;;AN000;;
	    JMP SHORT $MEN229
$MIF229:
	      CMP     BX,$M_CLASS_NOT_EXIST		     ;;AN000;;	 Does this class exist?
;	      $IF     NE				     ;;AN001;;	 Yes,
	      JE $MIF234
		CALL	$M_FIND_SPECIFIED_MSG		     ;;AN000;;	   Try to find the message
;	      $ENDIF					     ;;AN000;;
$MIF234:
	      ADD     SI,$M_ADDR_SZ_FAR 		     ;;AN000;;	     Get next class
	      CLC					     ;;AN000;;
;	    $ENDIF					     ;;AN000;;
$MEN229:
;	  $LEAVE  C					     ;;AN000;;
	  JC $MEN219
	    OR	    CX,CX				     ;;AN000;;	   Was the message found?
;	  $ENDDO  NZ,LONG				     ;;AN000;;
	  JNZ $MXL5
	  JMP $MDO219
$MXL5:
$MEN219:

	  PUSHF 					     ;;AN006;; Save the flag state
	  CMP	  DH,EXT_ERR_CLASS			     ;;AN006;; Was an extended error requested?
;	  $IF	  E					     ;;AN006;; Yes,
	  JNE $MIF239
	    PUSH    DX					     ;;AN006;;	Save all needed registers
	    PUSH    BP					     ;;AN006;;
	    PUSH    CX					     ;;AN006;;
	    PUSH    ES					     ;;AN006;;
	    PUSH    DI					     ;;AN006;;
	    PUSH    AX					     ;;AN006;;

	    MOV     AX,IFSFUNC_INSTALL_CHECK		     ;;AN006;;	Check if IFSFUNC is installed
	    INT     2FH 				     ;;AN006;;
	    CMP     AL,IFSFUNC_INSTALLED		     ;;AN006;;	Is it installed?
	    POP     AX					     ;;AN006;;	Restore msg number
;	    $IF     E					     ;;AN006;;	 Yes,
	    JNE $MIF240
	      MOV     BX,AX				     ;;AN006;;	  BX is the extended error number
	      MOV     AX,IFS_GET_ERR_TEXT		     ;;AN006;;	  AX is the muliplex number
	      INT     2FH				     ;;AN006;;	  Call IFSFUNC
;	    $ELSE					     ;;AN006;;	 No,
	    JMP SHORT $MEN240
$MIF240:
	      STC					     ;;AN006;;	  Carry conditon
;	    $ENDIF					     ;;AN006;;
$MEN240:

;	    $IF     C					     ;;AN006;;	Was there an update?
	    JNC $MIF243
	      POP     DI				     ;;AN006;;	No,
	      POP     ES				     ;;AN006;;	 Restore old pointer
	      POP     CX				     ;;AN006;;
;	    $ELSE					     ;;AN006;;	Yes
	    JMP SHORT $MEN243
$MIF243:
	      ADD     SP,6				     ;;AN006;;	 Throw away old pointer
	      CALL    $M_SET_LEN_IN_CX			     ;;AN006;;	 Get the length of the ASCIIZ string
;	    $ENDIF					     ;;AN006;;
$MEN243:
	    POP     BP					     ;;AN006;;	Restore other Regs
	    POP     DX					     ;;AN006;;
;	  $ENDIF					     ;;AN006;;
$MIF239:
	  $M_POPF					     ;;AN006;; Restore the flag state

	  POP	  BX					     ;;AN000;;
	  POP	  SI					     ;;AN000;;
	  RET						     ;;AN000;; Return ES:DI pointing to the message
							     ;;
$M_GET_MSG_ADDRESS ENDP 				     ;;
							     ;;
$M_SET_LEN_IN_CX PROC NEAR				     ;;
							     ;;
	  PUSH	  DI					     ;;AN006;; Save position
	  PUSH	  AX					     ;;AN006;;
	  MOV	  CX,-1 				     ;;AN006;; Set CX for decrements
	  XOR	  AL,AL 				     ;;AN006;; Prepare compare register
	  REPNE   SCASB 				     ;;AN006;; Scan for zero
	  NOT	  CX					     ;;AN006;; Change decrement into number
	  DEC	  CX					     ;;AN006;; Don't include the zero
	  POP	  AX					     ;;AN006;;
	  POP	  DI					     ;;AN006;; Restore position
	  RET						     ;;AN006;;
							     ;;
$M_SET_LEN_IN_CX ENDP					     ;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_FIND_SPECIFIED_MSG
;;
;;	FUNCTION:  To scan thru message headers until message is found
;;	INPUTS:    ES:DI points to beginning of msg headers
;;		   CX contains the number of messages in class
;;		   DH contains the message class
;;	OUPUTS:    IF CX = 0 THEN Message was not found
;;		   IF CX > 1 THEN ES:DI points to header of specified message
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_FIND_SPECIFIED_MSG PROC NEAR 			     ;;AN000;;
							     ;;
	  CMP	  BX,1					     ;;AN004;;	Do we have an address to CALL?
;	  $IF	  E,AND 				     ;;AN004;;	Yes,
	  JNE $MIF247
	  CMP	  WORD PTR $M_RT.$M_DISK_PROC_ADDR,-1	     ;;AN004;;	Do we have an address to CALL?
;	  $IF	  NE					     ;;AN004;;	Yes,
	  JE $MIF247
	    CMP     AX,$M_SPECIAL_MSG_NUM		     ;;AN004;; Are we displaying a default Ext Err?
;	    $IF     E					     ;;AN004;;	. . . and . . .
	    JNE $MIF248
	      PUSH    AX				     ;;AN004;;	 Reset the special message number
	      MOV     AX,$M_RT.$M_MSG_NUM		     ;;AN004;;	 Get the old message number
	      CALL    DWORD PTR $M_RT.$M_DISK_PROC_ADDR      ;;AN004;;	 Call the READ_DISK_PROC to get error text
	      POP     AX				     ;;AN004;;	 Reset the special message number
;	    $ELSE					     ;;AN004;;	 Get the old message number
	    JMP SHORT $MEN248
$MIF248:
	      CALL    DWORD PTR $M_RT.$M_DISK_PROC_ADDR      ;;AN004;;	 Call the READ_DISK_PROC to get error text
;	    $ENDIF					     ;;AN004;;	 Get the old message number
$MEN248:
;	  $ELSE 					     ;;AN004;;
	  JMP SHORT $MEN247
$MIF247:
	    XOR     CX,CX				     ;;AN002;;	 CX = 0 will allow us to
	    CMP     DH,UTILITY_MSG_CLASS		     ;;AN001;;
;	    $IF     NE					     ;;AN001;;
	    JE $MIF252
	      MOV     CL,BYTE PTR ES:[DI].$M_NUM_CLS_MSG     ;;AN001;;	 Get number of messages in class
;	    $ELSE					     ;;AN001;;
	    JMP SHORT $MEN252
$MIF252:
IF	      FARmsg					     ;;AN001;;
	      CMP     BYTE PTR ES:[DI].$M_CLASS_ID,DH	     ;;AN002;; Check if class still exists at
ELSE
	      CMP     BYTE PTR CS:[DI].$M_CLASS_ID,DH	     ;;AN002;; Check if class still exists at
ENDIF
;	      $IF     E 				     ;;AN002;;	pointer (hopefully)
	      JNE $MIF254
IF		FARmsg					     ;;AN001;;
		MOV	CL,BYTE PTR ES:[DI].$M_NUM_CLS_MSG   ;;AN000;;	   Get number of messages in class
ELSE
		MOV	CL,BYTE PTR CS:[DI].$M_NUM_CLS_MSG   ;;AN000;;	   Get number of messages in class
ENDIF
;	      $ENDIF					     ;;AN002;;	  go on to the next class
$MIF254:
;	    $ENDIF					     ;;AN001;;
$MEN252:
	    ADD     DI,$M_CLASS_ID_SZ			     ;;AN000;;	   Point past the class header
	    STC 					     ;;AN004;;	 Flag that we haven't found anything yet
;	  $ENDIF					     ;;AN004;;
$MEN247:

;	  $IF	  C					     ;;AN004;; Have we found anything yet?
	  JNC $MIF258
	    CLC 					     ;;AN004;; No, reset carry
;	    $SEARCH					     ;;AN000;;
$MDO259:
	      OR      CX,CX				     ;;AN000;;	  Do we have any to check?
;	    $LEAVE  Z					     ;;AN000;;	     No, return with CX = 0
	    JZ $MEN259
	      CMP     DH,UTILITY_MSG_CLASS		     ;;AN001;;
;	      $IF     NE				     ;;AN001;;
	      JE $MIF261
		CMP	AX,WORD PTR ES:[DI].$M_NUM	     ;;AN001;; Is this the message requested?
;	      $ELSE					     ;;AN001;;
	      JMP SHORT $MEN261
$MIF261:
IF		FARmsg					     ;;AN001;;
		CMP	AX,WORD PTR ES:[DI].$M_NUM	     ;;AN000;; Is this the message requested?
ELSE
		CMP	AX,WORD PTR CS:[DI].$M_NUM	     ;;AN000;; Is this the message requested?
ENDIF
;	      $ENDIF
$MEN261:
;	    $EXITIF E					     ;;AN000;;
	    JNE $MIF259
;	    $ORELSE					     ;;AN000;
	    JMP SHORT $MSR259
$MIF259:
	      DEC     CX				     ;;AN000;;	  No, well do we have more to check?
;	    $LEAVE  Z					     ;;AN000;;	     No, return with CX = 0
	    JZ $MEN259
	      ADD     DI,$M_ID_SZ			     ;;AN000;;	     Yes, skip past msg header
;	    $ENDLOOP					     ;;AN000;;
	    JMP SHORT $MDO259
$MEN259:
	      STC					     ;;AN000;;
;	    $ENDSRCH					     ;;AN000;;	     Check next message
$MSR259:
;	    $IF     NC					     ;;AN000;;	 Did we find the message?
	    JC $MIF269
	      CMP     DH,UTILITY_MSG_CLASS		     ;;AN001;;	 Yes, is it a utility message?
	      CLC					     ;;AN001;;
;	      $IF     E 				     ;;AN001;;
	      JNE $MIF270
IF		FARmsg					     ;;AN001;;
ELSE							     ;;AN000;;
		PUSH	CS				     ;;AN000;;
		POP	ES				     ;;AN000;;	 Return ES:DI pointing to the message
ENDIF
;	      $ENDIF					     ;;AN001;;
$MIF270:
	      ADD     DI,WORD PTR ES:[DI].$M_TXT_PTR	     ;;AN000;; Prepare ES:DI pointing to the message
;	    $ENDIF					     ;;AN004;;
$MIF269:
;	  $ENDIF					     ;;AN004;;
$MIF258:
							     ;; 	  Yes, great we can return with CX > 0

;	  $IF	  NC					     ;;AN000;;	 Did we find the message?
	  JC $MIF274
	    XOR     CH,CH				     ;;AN000;;
	    MOV     CL,BYTE PTR ES:[DI] 		     ;;AN000;;	 Move size into CX
	    INC     DI					     ;;AN000;;	 Increment past length
;	  $ENDIF					     ;;AN004;;
$MIF274:

	  MOV	  $M_RT.$M_SIZE,$M_NULL 		     ;;AN004;; Reset variable
	  RET						     ;;AN000;; Return
							     ;;
$M_FIND_SPECIFIED_MSG ENDP				     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ENDIF						     ;;AN000;; END of include of common subroutines
; 
	IF	$M_REPLACE				     ;;AN000;; Is the request to include the code for replaceable parms
	  $M_REPLACE = FALSE				     ;;AN000;;	   Tell the assembler we did
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
$M_DISPLAY_REPLACE PROC NEAR				     ;;AN000;;
							     ;;
	  XOR	  BX,BX 				     ;;AN000;; Use BX for buffer count
IF	  NOT	  COMR
	  CMP	  $M_SL.$M_S_ID,$M_SPECIAL_CASE-30H	     ;;AN000;; Is this the special case (convert to ASCII)
;	  $IF	  E					     ;;AN000;; Yes,
	  JNE $MIF276
	    MOV     WORD PTR $M_RT.$M_TEMP_BUF[BX],$M_SPACE_HYP ;;AN000;; Move in a " -"
	    INC     BX					     ;;AN000;;	   Increment count
	    INC     BX					     ;;AN000;;	   Increment count
	    MOV     BYTE PTR $M_RT.$M_TEMP_BUF[BX],$M_SPACE  ;;AN000;;	   Move in a " "
	    INC     BX					     ;;AN000;;	   Increment count
	    CALL    $M_FLUSH_BUF			     ;;AN000;;	   Write out " - " to prepare for special case
;	  $ENDIF					     ;;AN000;;	   If it fails we will catch it later
$MIF276:
ENDIF

	  POP	  BP					     ;;AN000;; Remember the return address
	  XOR	  BX,BX 				     ;;AN000;; Use BX for buffer count
	  XOR	  DX,DX 				     ;;AN000;; Use DX for count of parms taken off the stack

	  MOV	  $M_RT.$M_SIZE,CL			     ;;AN000;; Save size to later clear stack
	  MOV	  AL,BYTE PTR $M_SL.$M_S_MINW		     ;;AN000;; Get the minimum width
							     ;;
	  CMP	  AL,CL 				     ;;AN000;; Do we need pad chars added?
;	  $IF	  A					     ;;AN000;; Yes,
	  JNA $MIF278
	    SUB     AL,CL				     ;;AN000;;	 Calculate how many pad chars are needed.
	    MOV     DH,AL				     ;;AN000;;	 Save the number of pad characters
	    TEST    BYTE PTR $M_SL.$M_S_FLAG,Right_Align     ;;AN000;;	 Was replaceable parm to be right aligned?
;	    $IF     NZ					     ;;AN000;;	 Yes,
	    JZ $MIF279
;	      $DO					     ;;AN000;;	   Begin filling buffer with pad chars
$MDO280:
		MOV	AL,BYTE PTR $M_SL.$M_S_PAD	     ;;AN000;;
		MOV	BYTE PTR $M_RT.$M_TEMP_BUF[BX],AL    ;;AN000;;	   Move in a pad char
		INC	BX				     ;;AN000;;
		CMP	BX,$M_TEMP_BUF_SZ		     ;;AN000;;	   Is buffer full?
;		$IF	E				     ;;AN000;;	   Yes,
		JNE $MIF281
		  CALL	  $M_FLUSH_BUF			     ;;AN000;;	     Flush the buffer
;		$ENDIF					     ;;AN000;;
$MIF281:
		DEC	DH				     ;;AN000;;	   Have we filled with enough pad chars?
;	      $ENDDO  Z 				     ;;AN000;;	   No, next pad character
	      JNZ $MDO280
;	    $ENDIF					     ;;AN000;;
$MIF279:
;	  $ENDIF					     ;;AN000;;	   Yes,
$MIF278:
							     ;;
	  CMP	  BYTE PTR $M_SL.$M_S_MAXW,$M_UNLIM_W	     ;;AN000;; Is maximum width unlimited?
;	  $IF	  NE					     ;;AN000;;
	  JE $MIF286
	    CMP     BYTE PTR $M_SL.$M_S_MAXW,CL 	     ;;AN000;; Will we exceed maximum width?
;	    $IF     B					     ;;AN000;; Yes,
	    JNB $MIF287
	      SUB     CL,BYTE PTR $M_SL.$M_S_MAXW	     ;;AN000;;	 Calculate how many extra chars
	      MOV     DL,CL				     ;;AN000;;	 Remember how many chars to pop off
	      MOV     CL,BYTE PTR $M_SL.$M_S_MAXW	     ;;AN000;;	 Set new string length
;	    $ENDIF					     ;;AN000;;
$MIF287:
;	  $ENDIF					     ;;AN000;;
$MIF286:
	  OR	  CX,CX 				     ;;AN000;;
;	  $IF	  NZ					     ;;AN000;;
	  JZ $MIF290
;	    $DO 					     ;;AN000;; Begin filling buffer with string
$MDO291:
	      TEST    BYTE PTR $M_SL.$M_S_FLAG,NOT Char_Type AND $M_TYPE_MASK ;;AN000;;
;	      $IF     Z,AND				     ;;AN000;;
	      JNZ $MIF292
	      TEST    $M_SL.$M_S_FLAG,Char_field_ASCIIZ AND $M_SIZE_MASK ;  Is this replace a ASCIIZ string?
;	      $IF     NZ				     ;;AN000;; Yes,
	      JZ $MIF292
		MOV	AL,BYTE PTR ES:[DI]		     ;;AN000;;	 Get first character from string
		INC	DI				     ;;AN000;;	 Next character in string
;	      $ELSE					     ;;AN000;; No,
	      JMP SHORT $MEN292
$MIF292:
		POP	AX				     ;;AN000;;	 Get character in register
;	      $ENDIF					     ;;AN000;;
$MEN292:
	      MOV     BYTE PTR $M_RT.$M_TEMP_BUF[BX],AL      ;;AN000;;	Move char into the buffer
	      INC     BX				     ;;AN000;;	 Increase buffer count
	      CMP     BX,$M_TEMP_BUF_SZ 		     ;;AN000;;	 Is buffer full?
;	      $IF     E 				     ;;AN000;;	 Yes,
	      JNE $MIF295
		CALL	$M_FLUSH_BUF			     ;;AN000;;	   Flush the buffer
;	      $ENDIF					     ;;AN000;;
$MIF295:
	      DEC     CL				     ;;AN000;;	 Have we completed replace?
;	    $ENDDO  Z					     ;;AN000;;	   Test again
	    JNZ $MDO291
;	  $ENDIF					     ;;AN000;;
$MIF290:
							     ;;
	  TEST	  BYTE PTR $M_SL.$M_S_FLAG,Right_Align	     ;;AN000;;	 Was replaceable parm to be left aligned?
;	  $IF	  Z					     ;;AN000;; Yes,
	  JNZ $MIF299
	    OR	    DH,DH				     ;;AN000;;	 Do we need pad chars added?
;	    $IF     NZ					     ;;AN000;;	 Yes,
	    JZ $MIF300
;	      $DO					     ;;AN000;;	   Begin filling buffer with pad chars
$MDO301:
		MOV	AL,BYTE PTR $M_SL.$M_S_PAD	     ;;AN000;;
		MOV	BYTE PTR $M_RT.$M_TEMP_BUF[BX],AL    ;;AN000;;	   Move in a pad char
		INC	BX				     ;;AN000;;
		CMP	BX,$M_TEMP_BUF_SZ		     ;;AN000;;	   Is buffer full?
;		$IF	E				     ;;AN000;;	   Yes,
		JNE $MIF302
		  CALL	  $M_FLUSH_BUF			     ;;AN000;;	     Flush the buffer
;		$ENDIF					     ;;AN000;;
$MIF302:
		DEC	DH				     ;;AN000;;	   Have we filled with enough pad chars?
;	      $ENDDO  Z 				     ;;AN000;;	     Test again
	      JNZ $MDO301
;	    $ENDIF					     ;;AN000;;
$MIF300:
;	  $ENDIF					     ;;AN000;;
$MIF299:
							     ;;
	  TEST	  BYTE PTR $M_SL.$M_S_FLAG,NOT Char_Type AND $M_TYPE_MASK ;;AN000;;
;	  $IF	  Z,AND 				     ;;AN000;;
	  JNZ $MIF307
	  TEST	  $M_SL.$M_S_FLAG,Char_field_ASCIIZ AND $M_SIZE_MASK ;;AN000;;	Is this replace a ASCIIZ string?
;	  $IF	  NZ					     ;;AN000;; Yes,
	  JZ $MIF307
;	  $ELSE 					     ;;AN000;;
	  JMP SHORT $MEN307
$MIF307:
	    OR	    DL,DL				     ;;AN000;;
;	    $IF     NE					     ;;AN000;;
	    JE $MIF309
;	      $DO					     ;;AN000;;
$MDO310:
		POP	[$M_RT.$M_RETURN_ADDR]		     ;;AN000;;	 Clean Up stack using spare variable
		DEC	DL				     ;;AN000;;	 Are we done?
;	      $ENDDO  Z 				     ;;AN000;;
	      JNZ $MDO310
;	    $ENDIF					     ;;AN000;;
$MIF309:
;	  $ENDIF					     ;;AN000;;
$MEN307:
	  CALL	  $M_FLUSH_BUF				     ;;AN000;;	     Flush the buffer for the final time
	  PUSH	  BP					     ;;AN000;; Restore the return address
							     ;;
	  RET						     ;;AN000;;
							     ;;
$M_DISPLAY_REPLACE ENDP 				     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_FLUSH_BUFFER
;;
;;	FUNCTION: Display the contents of the temporary buffer
;;	INPUTS: DI contains the number of bytes to display
;;	OUTPUTS: BX reset to zero
;;
;;	REGS USED:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_FLUSH_BUF PROC NEAR					     ;;AN000;;
							     ;;
	  PUSH	  CX					     ;;AN000;; Save changed regs
	  PUSH	  ES					     ;;AN000;;
	  PUSH	  DI					     ;;AN000;;
	  PUSH	  DS					     ;;AN000;; Set ES pointing to buffer
	  POP	  ES					     ;;AN000;;
							     ;;
	  MOV	  CX,BX 				     ;;AN000;; Set number of bytes to display
	  XOR	  BX,BX 				     ;;AN000;; Reset buffer counter
	  LEA	  DI,$M_RT.$M_TEMP_BUF			     ;;AN000;; Reset buffer location pointer
	  CALL	  $M_DISPLAY_STRING			     ;;AN000;; Display the buffer
							     ;;
;	  $IF	  NC					     ;;AN000;; Error?
	  JC $MIF314
	    POP     DI					     ;;AN000;; No, Restore changed regs
	    POP     ES					     ;;AN000;;
	    POP     CX					     ;;AN000;;
;	  $ELSE 					     ;;AN000;; Yes,
	  JMP SHORT $MEN314
$MIF314:
	    ADD     SP,6				     ;;AN000;;	Fix stack
	    STC 					     ;;AN000;;
;	  $ENDIF					     ;;AN000;; Error?
$MEN314:
							     ;;
	  RET						     ;;AN000;; Return
							     ;;
$M_FLUSH_BUF ENDP					     ;;AN000;;
							     ;;
							     ;;
	  IF	  CHARmsg				     ;;AN000;; Is the request to include the code for CHAR replace?
	    $M_REPLACE =  TRUE				     ;;AN000;; Yes, THEN include it and flag that we will need common
	    $M_CHAR_ONLY = TRUE 			     ;;AN000;;	 replacement code later
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_CHAR_REPLACE
;;
;;	FUNCTION: Will prepare a single char or ASCIIZ string for replace
;;	INPUTS: DS:SI points at corresponding SUBLIST
;;		ES:DI contains the VALUE from SUBLIST
;;	OUTPUTS: CX contains number of characters on stack
;;		 Top of stack  --> Last character
;;					. . .
;;		 Bot of stack  --> First character
;;
;;	OTHER REGS Revised: AX
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_CHAR_REPLACE PROC NEAR				     ;;AN000;;
							     ;;
	    POP     BP					     ;;AN000;; Save return address
	    TEST    $M_SL.$M_S_FLAG,NOT Char_Field_Char AND $M_SIZE_MASK ;;AN000;; Was Character specified?
;	    $IF     Z					     ;;AN000;; Yes,
	    JNZ $MIF317
	      MOV     AL,BYTE PTR ES:[DI]		     ;;AN000;;	 Get the character
	      PUSH    AX				     ;;AN000;;	 Put it on the stack
	      INC     CX				     ;;AN000;;	 Increase the count
	      CALL    $M_IS_IT_DBCS			     ;;AN000;;	 Is this the first byte of a DB character
;	      $IF     C 				     ;;AN000;;	 Yes,
	      JNC $MIF318
		MOV	AL,BYTE PTR ES:[DI]+1		     ;;AN000;;	   Get the next character
		PUSH	AX				     ;;AN000;;	   Put it on the stack
		CLC					     ;;AN000;;	   Clear the carry
;	      $ENDIF					     ;;AN000;;
$MIF318:
;	    $ELSE					     ;;AN000;; No, it was an ASCIIZ string
	    JMP SHORT $MEN317
$MIF317:
;	      $DO					     ;;AN000;;
$MDO321:
		MOV	AL,BYTE PTR ES:[DI]		     ;;AN000;;	 Get the character
		OR	AL,AL				     ;;AN000;;	 Is it the NULL?
;	      $LEAVE  Z 				     ;;AN000;;	 No,
	      JZ $MEN321
		INC	DI				     ;;AN000;;	   Next character
		INC	CX				     ;;AN000;;	   Increment the count
;	      $ENDDO					     ;;AN000;;	 Yes,
	      JMP SHORT $MDO321
$MEN321:
	      SUB     DI,CX				     ;;AN000;;	 Set SI at the beginning of the string
;	    $ENDIF					     ;;AN000;;
$MEN317:
							     ;;AN000;;
	    PUSH    BP					     ;;AN000;; Restore return address
	    RET 					     ;;AN000;; Return
							     ;;
$M_CHAR_REPLACE ENDP					     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	  ENDIF 					     ;;AN000;; END of include of CHAR replace code
; 
	  IF	  NUMmsg				     ;;AN000;; Is the request to include the code for NUM replace?
	    $M_REPLACE =  TRUE				     ;;AN000;; Yes, THEN include it and flag that we will need common
	    $M_CHAR_ONLY = FALSE			     ;;AN000;;	 replacement code later
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_BIN2ASC_REPLACE
;;
;;	FUNCTION: Convert a signed or unsigned binary number to an ASCII string
;;		  and prepare to display
;;	INPUTS: DS:SI points at corresponding SUBLIST
;;		ES:DI contains the VALUE from SUBLIST
;;	OUTPUTS: CX contains number of characters on stack
;;		 Top of stack  --> Last character
;;					. . .
;;		 Bot of stack  --> First character
;;	OTHER REGS Revised: BX,DX,AX
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_BIN2ASC_REPLACE PROC NEAR				     ;;AN000;;
							     ;;
	    POP     BP					     ;;AN000;; Save return address
							     ;;
	    XOR     DX,DX				     ;;AN000;; Prepare for get binary value (HIGH)
	    XOR     AX,AX				     ;;AN000;; Prepare for get binary value (LOW)
	    MOV     $M_RT.$M_DIVISOR,$M_BASE16		     ;;AN000;; Set default divisor
	    XOR     BX,BX				     ;;AN000;; Use BP as the NEG flag (if applicable)
IF	    NOT     COMR
	    TEST    $M_SL.$M_S_FLAG,NOT $M_BYTE AND $M_SIZE_MASK ;;AN000;; Was BYTE specified?
;	    $IF     Z					     ;;AN000;;
	    JNZ $MIF325
	      MOV     AL, BYTE PTR ES:[DI]		     ;;AN000;; Setup byte in AL
	      TEST    $M_SL.$M_S_FLAG,NOT Sgn_Bin_Type AND $M_TYPE_MASK ;;AN000;; Was Signed binary specified?
;	      $IF     Z 				     ;;AN000;;
	      JNZ $MIF326
		TEST	AL,10000000b			     ;;AN000;; Is this number negative?
;		$IF	NZ				     ;;AN000;;	 Yes,
		JZ $MIF327
		  INC	  BX				     ;;AN000;;	   Remember that it was negative
		  AND	  AL,01111111b			     ;;AN000;;	   Make it positive
;		$ENDIF					     ;;AN000;;
$MIF327:
		MOV	$M_RT.$M_DIVISOR,$M_BASE10	     ;;AN000;;
;	      $ENDIF					     ;;AN000;;
$MIF326:
	      TEST    $M_SL.$M_S_FLAG,NOT Unsgn_Bin_Type AND $M_TYPE_MASK ;;AN000;; Was Signed binary specified?
;	      $IF     Z 				     ;;AN000;;
	      JNZ $MIF330
		MOV	$M_RT.$M_DIVISOR,$M_BASE10	     ;;AN000;;
;	      $ENDIF					     ;;AN000;;
$MIF330:
;	    $ELSE					     ;;AN000;;
	    JMP SHORT $MEN325
$MIF325:
ENDIF
	      TEST    $M_SL.$M_S_FLAG,NOT $M_WORD AND $M_SIZE_MASK ;;AN000;; Was WORD specified?
;	      $IF     Z 				     ;;AN000;;
	      JNZ $MIF333
		MOV	AX, WORD PTR ES:[DI]		     ;;AN000;; Setup byte in AL
		TEST	$M_SL.$M_S_FLAG,NOT Sgn_Bin_Type AND $M_TYPE_MASK ;; AN000;; Was Signed binary specified?
;		$IF	Z				     ;;AN000;;
		JNZ $MIF334
		  TEST	  AH,10000000b			     ;;AN000;; Is this number negative?
;		  $IF	  NZ				     ;;AN000;;	 Yes,
		  JZ $MIF335
		    INC     BX				     ;;AN000;;	   Remember that it was negative
		    AND     AH,01111111b		     ;;AN000;;	   Make it positive
;		  $ENDIF				     ;;AN000;;
$MIF335:
		  MOV	  $M_RT.$M_DIVISOR,$M_BASE10	     ;;AN000;;
;		$ENDIF					     ;;AN000;;
$MIF334:
		TEST	$M_SL.$M_S_FLAG,NOT Unsgn_Bin_Type AND $M_TYPE_MASK ;;AN000;; Was Signed binary specified?
;		$IF	Z				     ;;AN000;;
		JNZ $MIF338
		  MOV	  $M_RT.$M_DIVISOR,$M_BASE10	     ;;AN000;;
;		$ENDIF					     ;;AN000;;
$MIF338:
;	      $ELSE					     ;;AN000;;
	      JMP SHORT $MEN333
$MIF333:
IF		NOT	COMR
		MOV	AX, WORD PTR ES:[DI]		     ;;AN000;; Setup Double word in DX:AX
		MOV	DX, WORD PTR ES:[DI]+2		     ;;AN000;;
		TEST	$M_SL.$M_S_FLAG,NOT Sgn_Bin_Type AND $M_TYPE_MASK ;;AN000;; Was Signed binary specified?
;		$IF	Z				     ;;AN000;;
		JNZ $MIF341
		  TEST	  DH,10000000b			     ;;AN000;; Is this number negative?
;		  $IF	  NZ				     ;;AN000;;	 Yes,
		  JZ $MIF342
		    INC     BX				     ;;AN000;;	   Remember that it was negative
		    AND     DH,01111111b		     ;;AN000;;	   Make it positive
;		  $ENDIF				     ;;AN000;;
$MIF342:
		  MOV	  $M_RT.$M_DIVISOR,$M_BASE10	     ;;AN000;;
;		$ENDIF					     ;;AN000;;
$MIF341:
		TEST	$M_SL.$M_S_FLAG,NOT Unsgn_Bin_Type AND $M_TYPE_MASK ;;AN000;; Was Signed binary specified?
;		$IF	Z				     ;;AN000;;
		JNZ $MIF345
		  MOV	  $M_RT.$M_DIVISOR,$M_BASE10	     ;;AN000;;
;		$ENDIF					     ;;AN000;;
$MIF345:
ENDIF
;	      $ENDIF					     ;;AN000;;
$MEN333:
;	    $ENDIF					     ;;AN000;;
$MEN325:
							     ;;
	    CALL    $M_CONVERT2ASC			     ;;AN000;; Convert to ASCII string
IF	    NOT     COMR
	    OR	    BX,BX				     ;;AN000;;
;	    $IF     NZ					     ;;AN000;; Was number negative?
	    JZ $MIF349
	      XOR     DX,DX				     ;;AN000;; Yes,
	      MOV     DL,$M_NEG_SIGN			     ;;AN000;;	 Put "-" on the stack with the number
	      PUSH    DX				     ;;AN000;;
;	    $ENDIF					     ;;AN000;; No,
$MIF349:
ENDIF
							     ;;
	    PUSH    BP					     ;;AN000;; Restore return address
	    RET 					     ;;AN000;; Return
							     ;;
$M_BIN2ASC_REPLACE ENDP 				     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	  ENDIF 					     ;;AN000;; END of include of NUM replace code
; 
	  IF	  DATEmsg				     ;;AN000;; Is the request to include the code for DATE replace?
	    $M_REPLACE =  TRUE				     ;;AN000;; Yes, THEN include it and flag that we will need common
	    $M_CHAR_ONLY = FALSE			     ;;AN000;;	  replacement code later
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_DATE_REPLACE
;;
;;	FUNCTION: Convert a date to a decimal ASCII string using current
;;		  country format and prepare to display
;;	INPUTS: DS:SI points at corresponding SUBLIST
;;		ES:DI points at VALUE from SUBLIST
;;	OUTPUTS: CX contains number of characters on stack
;;		 Top of stack  --> Last character
;;					. . .
;;		 Bot of stack  --> First character
;;	OTHER REGS Revised: DX, AX
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_DATE_REPLACE PROC NEAR				     ;;AN000;;
							     ;;
	    POP     BP					     ;;AN000;; Save return address
	    MOV     $M_RT.$M_DIVISOR,$M_BASE10		     ;;AN000;; Set default divisor
	    CALL    $M_GET_DATE 			     ;;AN000;; Set date format/separator in $M_RT
							     ;;AN000;; All O.K.?
	    XOR     DX,DX				     ;;AN000;; Reset DX value
	    XOR     AX,AX				     ;;AN000;; Reset AX value
	    CMP     WORD PTR $M_RT.$M_DATE_FORMAT,0	     ;;AN000;; USA Date Format
;	    $IF     E					     ;;AN000;;	Beginning from end: (saved on the stack)
	    JNE $MIF351
	      CALL    $M_YEAR				     ;;AN000;;	 Get Year
	      CALL    $M_CONVERTDATE			     ;;AN000;;	Convert it to an ASCII string
	      PUSH    WORD PTR $M_RT.$M_DATE_SEPARA	     ;;AN000;;
	      INC     CX				     ;;AN000;; Increment count
	      XOR     AX,AX				     ;;AN000;; Reset AX value
	      MOV     AL,BYTE PTR $M_SL.$M_S_VALUE+3	     ;;AN000;;	Get Day
	      CALL    $M_CONVERTDATE			     ;;AN000;;	Convert it to an ASCII string
	      PUSH    WORD PTR $M_RT.$M_DATE_SEPARA	     ;;AN000;;
	      INC     CX				     ;;AN000;; Increment count
	      MOV     AL,BYTE PTR $M_SL.$M_S_VALUE+2	     ;;AN000;;	Get Month
	      CALL    $M_CONVERTDATE			     ;;AN000;;	Convert it to an ASCII string
;	    $ENDIF					     ;;AN000;;
$MIF351:
							     ;;
	    CMP     WORD PTR $M_RT.$M_DATE_FORMAT,1	     ;;AN000;; EUROPE Date Format
;	    $IF     E					     ;;AN000;;	Beginning from end: (saved on the stack)
	    JNE $MIF353
	      CALL    $M_YEAR				     ;;AN000;;	 Get Year
	      CALL    $M_CONVERTDATE			     ;;AN000;;	Convert it to an ASCII string
	      PUSH    WORD PTR $M_RT.$M_DATE_SEPARA	     ;;AN000;;
	      INC     CX				     ;;AN000;;
	      XOR     AX,AX				     ;;AN000;; Reset AX
	      MOV     AL,BYTE PTR $M_SL.$M_S_VALUE+2	     ;;AN000;;	Get Month
	      CALL    $M_CONVERTDATE			     ;;AN000;;	Convert it to an ASCII string
	      PUSH    WORD PTR $M_RT.$M_DATE_SEPARA	     ;;AN000;;
	      INC     CX				     ;;AN000;;
	      MOV     AL,BYTE PTR $M_SL.$M_S_VALUE+3	     ;;AN000;;	Get Day
	      CALL    $M_CONVERTDATE			     ;;AN000;;	Convert it to an ASCII string
;	    $ENDIF					     ;;AN000;;
$MIF353:
							     ;;
	    CMP     WORD PTR $M_RT.$M_DATE_FORMAT,2	     ;;AN000;; JAPAN Date Format
;	    $IF     E					     ;;AN000;;	Beginning from end: (saved on the stack)
	    JNE $MIF355
	      MOV     AL,BYTE PTR $M_SL.$M_S_VALUE+3	     ;;AN000;;	Get Day
	      CALL    $M_CONVERTDATE			     ;;AN000;;	Convert it to an ASCII string
	      PUSH    WORD PTR $M_RT.$M_DATE_SEPARA	     ;;AN000;;
	      INC     CX				     ;;AN000;;
	      MOV     AL,BYTE PTR $M_SL.$M_S_VALUE+2	     ;;AN000;;	Get Month
	      CALL    $M_CONVERTDATE			     ;;AN000;;	Convert it to an ASCII string
	      PUSH    WORD PTR $M_RT.$M_DATE_SEPARA	     ;;AN000;;
	      INC     CX				     ;;AN000;;
	      CALL    $M_YEAR				     ;;AN000;;	 Get Year
	      CALL    $M_CONVERTDATE			     ;;AN000;;	Convert it to an ASCII string
;	    $ENDIF					     ;;AN000;;
$MIF355:
							     ;;
	    PUSH    BP					     ;;AN000;; Restore return address
	    RET 					     ;;AN000;; Return
							     ;;
$M_DATE_REPLACE ENDP					     ;;AN000;;
							     ;;
$M_GET_DATE PROC    NEAR				     ;;AN000;;
	    MOV     AH,DOS_GET_COUNTRY			     ;;AN000;; Call DOS for country dependant info
	    MOV     AL,0				     ;;AN000;; Get current country info
	    LEA     DX,$M_RT.$M_TEMP_BUF		     ;;AN000;; Set up addressibility to buffer
	    INT     21H 				     ;;AN000;;
;	    $IF     C					     ;;AN000;; No,
	    JNC $MIF357
	      MOV     WORD PTR $M_RT.$M_DATE_FORMAT,$M_DEF_DATE_FORM ;;AN000;;	 Set default date format    (BH)
	      MOV     BYTE PTR $M_RT.$M_DATE_SEPARA,$M_DEF_DATE_SEP ;;AN000;;	Set default date separator (BL)
;	    $ENDIF					     ;;AN000;;
$MIF357:
	    RET 					     ;;AN000;;
$M_GET_DATE ENDP					     ;;AN000;;
							     ;;
$M_YEAR     PROC    NEAR				     ;;AN000;;
	    MOV     AX,WORD PTR $M_SL.$M_S_VALUE	     ;;AN000;;	Get Year
	    TEST    $M_SL.$M_S_FLAG,Date_MDY_4 AND $M_DATE_MASK ;;AN000;; Was Month/Day/Year (2 Digits) specified?
;	    $IF     Z					     ;;AN000;;
	    JNZ $MIF359
	      CMP     AX,$M_MAX_2_YEAR			     ;;AN000;;	Get Year
;	      $IF     A 				     ;;AN000;;
	      JNA $MIF360
		MOV	AX,$M_MAX_2_YEAR		     ;;AN000;;
;	      $ENDIF					     ;;AN000;;
$MIF360:
;	    $ENDIF					     ;;AN000;;
$MIF359:
	    RET 					     ;;AN000;;
$M_YEAR     ENDP					     ;;AN000;;
							     ;;
$M_CONVERTDATE PROC NEAR				     ;;AN000;;
	    POP     WORD PTR $M_RT.$M_TEMP_BUF		     ;;AN000;; Save return address
	    MOV     $M_RT.$M_SIZE,CL			     ;;AN000;; Save the size before conversion
	    CALL    $M_CONVERT2ASC			     ;;AN000;; Convert it to an ASCII string
	    DEC     CX					     ;;AN000;; Test if size only grew by 1
	    CMP     CL,$M_RT.$M_SIZE			     ;;AN000;; Did size only grow by one
;	    $IF     E					     ;;AN000;; Yes,
	    JNE $MIF363
	      MOV     AX,$M_TIMEDATE_PAD		     ;;AN000;;	 Get a pad character (0)
	      PUSH    AX				     ;;AN000;;	 Save it
	      INC     CX				     ;;AN000;;	 Count it
;	    $ENDIF					     ;;AN000;;
$MIF363:
	    INC     CX					     ;;AN000;; Restore CX
	    PUSH    WORD PTR $M_RT.$M_TEMP_BUF		     ;;AN000;; Save return address
	    RET 					     ;;AN000;;
$M_CONVERTDATE ENDP					     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	  ENDIF 					     ;;AN000;; END of include of DATE replace code
; 
	  IF	  TIMEmsg				     ;;AN000;; Is the request to include the code for TIME replace?
	    $M_REPLACE =  TRUE				     ;;AN000;; Yes, THEN include it and flag that we will need common
	    $M_CHAR_ONLY = FALSE			     ;;AN000;;	  replacement code later
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_TIME_REPLACE
;;
;;	FUNCTION: Convert a time to a decimal ASCII string
;;		  and prepare to display
;;	INPUTS: DS:SI points at corresponding SUBLIST
;;		ES:DI points at VALUE from SUBLIST
;;	OUTPUTS: CX contains number of characters on stack
;;		 Top of stack  --> Last character
;;					. . .
;;		 Bot of stack  --> First character
;;	REGS USED: BP,CX,AX
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_TIME_REPLACE PROC NEAR				     ;;AN000;;
							     ;;
	    POP     BP					     ;;AN000;; Save return address
	    MOV     $M_RT.$M_DIVISOR,$M_BASE10		     ;;AN000;; Set default divisor
	    CALL    $M_GET_TIME 			     ;;AN000;; All O.K.?
	    TEST    $M_SL.$M_S_FLAG,Time_Cty_Type AND $M_TIME_MASK ;;AN000;; Is this a request for current country info?
;	    $IF     NZ					     ;;AN000;; Yes,
	    JZ $MIF365
	      CMP     BYTE PTR $M_RT.$M_TIME_FORMAT,0	     ;;AN000;; Is the current country format 12 Hour?
;	      $IF     E 				     ;;AN000;; Yes,
	      JNE $MIF366
		MOV	AL,BYTE PTR $M_SL.$M_S_VALUE	     ;;AN000;;	Get Hours
		CMP	AL,12				     ;;AN000;;	Is hour 12 or less?
;		$IF	L,OR				     ;;AN000;;	 or
		JL $MLL367
		CMP	AL,23				     ;;AN000;;	  Is hour 24 or greater?
;		$IF	G				     ;;AN000;;	Yes,
		JNG $MIF367
$MLL367:
		  MOV	  AL,$M_AM			     ;;AN000;;
		  PUSH	  AX				     ;;AN000;;	  Push an "a" to represent AM.
		  INC	  CX				     ;;AN000;;
;		$ELSE					     ;;AN000;;	No,
		JMP SHORT $MEN367
$MIF367:
		  MOV	  AL,$M_PM			     ;;AN000;;
		  PUSH	  AX				     ;;AN000;;	  Push an "p" to represent PM.
		  INC	  CX				     ;;AN000;;
;		$ENDIF					     ;;AN000;;
$MEN367:
;	      $ENDIF					     ;;AN000;;
$MIF366:
;	    $ENDIF					     ;;AN000;;
$MIF365:
							     ;;
	    XOR     AX,AX				     ;;AN000;;
	    XOR     DX,DX				     ;;AN000;;
	    TEST    $M_SL.$M_S_FLAG,Time_HHMMSSHH_Cty AND $M_SIZE_MASK ;;AN000;; Was Hour/Min/Sec/Hunds (12 Hour) specified?
;	    $IF     NZ					     ;;AN000;;
	    JZ $MIF372
	      MOV     AL,BYTE PTR $M_SL.$M_S_VALUE+3	     ;;AN000;;	Get Hundreds
	      CALL    $M_CONVERTTIME			     ;;AN000;;
	      PUSH    WORD PTR $M_RT.$M_DECI_SEPARA	     ;;AN000;;
	      INC     CX				     ;;AN000;;
;	    $ENDIF					     ;;AN000;;
$MIF372:
	    TEST    $M_SL.$M_S_FLAG,Time_HHMMSSHH_Cty AND $M_SIZE_MASK ;;AN000;; Was Hour/Min/Sec/Hunds (12 Hour) specified?
;	    $IF     NZ,OR				     ;;AN000;;
	    JNZ $MLL374
	    TEST    $M_SL.$M_S_FLAG,Time_HHMMSS_Cty AND $M_SIZE_MASK ;;AN000;; Was Hour/Min/Sec (12 Hour) specified?
;	    $IF     NZ					     ;;AN000;;
	    JZ $MIF374
$MLL374:
	      MOV     AL,BYTE PTR $M_SL.$M_S_VALUE+2	     ;;AN000;;	Get Seconds
	      CALL    $M_CONVERTTIME			     ;;AN000;;
	      PUSH    WORD PTR $M_RT.$M_TIME_SEPARA	     ;;AN000;;
	      INC     CX				     ;;AN000;;
;	    $ENDIF					     ;;AN000;;
$MIF374:
							     ;;        Do Hour/Min (12 Hour)
	    MOV     AL,BYTE PTR $M_SL.$M_S_VALUE+1	     ;;AN000;;	Get Minutes
	    CALL    $M_CONVERTTIME			     ;;AN000;;
	    PUSH    WORD PTR $M_RT.$M_TIME_SEPARA	     ;;AN000;;
	    INC     CX					     ;;AN000;;
							     ;;
	    MOV     AL,BYTE PTR $M_SL.$M_S_VALUE	     ;;AN000;;	Get Hours
	    TEST    $M_SL.$M_S_FLAG,Time_Cty_Type AND $M_TIME_MASK ;;AN000;; Is this a request for current country info?
;	    $IF     NZ					     ;;AN000;; Yes,
	    JZ $MIF376
	      CMP     BYTE PTR $M_RT.$M_TIME_FORMAT,0	     ;;AN000;; Is the current country format 12 Hour?
;	      $IF     E 				     ;;AN000;; Yes,
	      JNE $MIF377
		CMP	AL,13				     ;;AN000;;	Is hour less than 12?
;		$IF	GE				     ;;AN000;;	Yes,
		JNGE $MIF378
		  SUB	  AL,12 			     ;;AN000;;	  Set to a 12 hour value
;		$ENDIF					     ;;AN000;;
$MIF378:
		CMP	AL,0				     ;;AN000;;	Is hour less than 12?
;		$IF	E				     ;;AN000;;	Yes,
		JNE $MIF380
		  MOV	  AL,12 			     ;;AN000;;	  Set to a 12 hour value
;		$ENDIF					     ;;AN000;;
$MIF380:
;	      $ENDIF					     ;;AN000;;
$MIF377:
;	    $ENDIF					     ;;AN000;;
$MIF376:
	    CALL    $M_CONVERT2ASC			     ;;AN000;; Convert it to ASCII
							     ;;
	    PUSH    BP					     ;;AN000;; Restore return address
	    RET 					     ;;AN000;; Return
							     ;;
$M_TIME_REPLACE ENDP					     ;;AN000;;
							     ;;
$M_GET_TIME PROC    NEAR				     ;;AN000;;
	    MOV     AH,DOS_GET_COUNTRY			     ;;AN000;; Call DOS for country dependant info
	    MOV     AL,0				     ;;AN000;; Get current country info
	    LEA     DX,$M_RT.$M_TEMP_BUF		     ;;AN000;; Set up addressibility to buffer
	    INT     21H 				     ;;AN000;;
;	    $IF     C					     ;;AN000;; No,
	    JNC $MIF384
	      MOV     WORD PTR $M_RT.$M_TIME_FORMAT,$M_DEF_TIME_FORM ;;AN000;;	 Set default time format    (BH)
	      MOV     BYTE PTR $M_RT.$M_TIME_SEPARA,$M_DEF_TIME_SEP ;;AN000;;	Set default time separator (BL)
	      MOV     BYTE PTR $M_RT.$M_DECI_SEPARA,$M_DEF_DECI_SEP ;;AN000;;	Set default time separator (BL)
;	    $ENDIF					     ;;AN000;;
$MIF384:
	    RET 					     ;;AN000;;
$M_GET_TIME ENDP					     ;;AN000;;
							     ;;
$M_CONVERTTIME PROC NEAR				     ;;AN000;;
	    POP     WORD PTR $M_RT.$M_TEMP_BUF		     ;;AN000;; Save return address
	    MOV     $M_RT.$M_SIZE,CL			     ;;AN000;; Save the size before conversion
	    CALL    $M_CONVERT2ASC			     ;;AN000;; Convert it to an ASCII string
	    DEC     CX					     ;;AN000;; Test if size only grew by 1
	    CMP     CL,$M_RT.$M_SIZE			     ;;AN000;; Did size only grow by one
;	    $IF     E					     ;;AN000;; Yes,
	    JNE $MIF386
	      MOV     AX,$M_TIMEDATE_PAD		     ;;AN000;;	 Get a pad character (0)
	      PUSH    AX				     ;;AN000;;	 Save it
	      INC     CX				     ;;AN000;;	 Count it
;	    $ENDIF					     ;;AN000;;
$MIF386:
	    INC     CX					     ;;AN000;; Restore CX
	    PUSH    WORD PTR $M_RT.$M_TEMP_BUF		     ;;AN000;; Save return address
	    RET 					     ;;AN000;;
$M_CONVERTTIME ENDP					     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	  ENDIF 					     ;;AN000;; END of include of TIME replace
	ENDIF						     ;;AN000;; END of include of Replacement common code
; 
	IF	INPUTmsg				     ;;AN000;; Is the request to include the code for NUM replace?
	  INPUTmsg =	FALSE				     ;;AN000;; Yes, THEN include it and reset the flag
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PROC NAME: $M_WAIT_FOR_INPUT
;;
;;	FUNCTION:  To accept keyed input and return extended key value
;;		   in AX register
;;	INPUTS:    DL contains the DOS function requested for input
;;	OUPUTS:    AX contains the extended key value that was read
;;	REGS USED:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							     ;;
$M_WAIT_FOR_INPUT PROC NEAR				     ;;AN000;;
							     ;;
	  PUSH	  CX					     ;;AN000;; Save CX
	  PUSH	  DX					     ;;AN000;; Save DX
	  PUSH	  DS					     ;;AN000;; Save Data segment
							     ;;
	  CMP	  DL,DOS_CLR_KEYB_BUF_MASK		     ;;AN001;; Are we to clear the keyboard buffer?
;	  $IF	  A					     ;;AN001;; Yes,
	  JNA $MIF388
	    MOV     AL,DL				     ;;AN001;;	 Mov function into AL
	    AND     AL,LOW_NIB_MASK			     ;;AN001;;	 Mask out the C in high nibble
	    MOV     AH,DOS_CLR_KEYB_BUF 		     ;;AN001;;	 Set input function
;	  $ELSE 					     ;;AN001;; No,
	  JMP SHORT $MEN388
$MIF388:
	    MOV     AH,DL				     ;;AN000;;	 Put DOS function in AH
;	  $ENDIF					     ;;AN001;;
$MEN388:
	  PUSH	  ES					     ;;AN000;; Get output buffer segment
	  POP	  DS					     ;;AN000;;
	  MOV	  DX,DI 				     ;;AN000;;	 Get output buffer offset in case needed
	  INT	  21H					     ;;AN000;; Get keyboard input
	  POP	  DS					     ;;AN000;;

	  CMP	  DL,DOS_BUF_KEYB_INP			     ;;AN000;;
	  CLC						     ;;AN000;;
;	  $IF	  NE					     ;;AN000;; If character input
	  JE $MIF391
	    CALL    $M_IS_IT_DBCS			     ;;AN000;;	Is this character DBCS?
;	    $IF     C					     ;;AN000;;
	    JNC $MIF392
	      MOV     CL,AL				     ;;AN000;; Save first character
	      MOV     AH,DL				     ;;AN001;; Get back function
	      INT     21H				     ;;AN000;; Get keyboard input
	      MOV     AH,CL				     ;;AN000;; Retreive first character  AX = xxxx
	      CLC					     ;;AN000;; Clear carry condition
;	    $ELSE					     ;;AN000;;
	    JMP SHORT $MEN392
$MIF392:
	      MOV     AH,0				     ;;AN000;; AX = 00xx where xx is SBCS
;	    $ENDIF					     ;;AN000;;
$MEN392:
;	  $ENDIF					     ;;AN000;;
$MIF391:
							     ;;
;	  $IF	  NC					     ;;AN000;;
	  JC $MIF396
	    POP     DX					     ;;AN000;;
	    POP     CX					     ;;AN000;;
;	  $ELSE 					     ;;AN000;;
	  JMP SHORT $MEN396
$MIF396:
	    ADD     SP,4				     ;;AN000;;
	    STC 					     ;;AN000;; Reset carry flag
;	  $ENDIF					     ;;AN000;;
$MEN396:
	  RET						     ;;AN000;; Return
							     ;;
$M_WAIT_FOR_INPUT ENDP					     ;;AN000;;
							     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ENDIF						     ;;AN000;; END of include of Wait for Input
      ENDIF						     ;;AN000;; END of include of SYSDISPMSG
    ENDIF						     ;;AN000;; END of include of MSG_DATA_ONLY
ENDIF							     ;;AN000;; END of include of Structure only
