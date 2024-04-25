
	PAGE	,132

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  FILENAME:		CPS Printer Device Driver INIT module (CPSPInn)
;;  MODULE NAME:
;;  TYPE:		Assemble file  (non-resident code)
;;  LINK PROCEDURE:	Link CPSPMnn+CPSFONT+CPSPInn into .EXE format. CPSPM01
;;			must be first.	CPSPInn must be last.  Everything
;;			before CPSPInn will be resident.
;;  INCLUDE FILES:
;;			CPSPEQU.INC
;;
;;  LAYOUT :		This file is divided into two main section :
;;			  ++++++++++++++++++++++++
;;			  ++	DEVICE Parser	++
;;			  ++++++++++++++++++++++++
;;
;;			  ++++++++++++++++++++++++
;;			  ++	INIT Command	++
;;			  ++++++++++++++++++++++++
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
INCLUDE CPSPEQU.INC			;;
INT2F_LOW	EQU	(4*2FH) 	;; WGR interrupt 2F vector location	    ;AN000;
INT2F_HI	EQU	(4*2FH)+2	;; WGR					    ;AN000;
					;;
.XLIST					;;
INCLUDE SYSMSG.INC			;; WGR					    ;AN000;
.LIST					;;
					;;
MSG_UTILNAME <PRINTER>			;; WGR					    ;AN000;
					;;
PUBLIC	INIT				;;
PUBLIC	CODE_END			;; for MAP listing only
PUBLIC	RESIDENT_END			;;
PUBLIC	STACK_ALLOCATED 		;;
					;;
					;;
EXTRN	PRINTER_DESC_NUM:WORD		;;
EXTRN	PRINTER_DESC_TBL:WORD		;;
EXTRN	INIT_CHK:WORD,TABLE:WORD	;;
EXTRN	HARD_SL1:BYTE,RAM_SL1:BYTE	;;
EXTRN	HARD_SL2:BYTE,RAM_SL2:BYTE	;;
EXTRN	HARD_SL3:BYTE,RAM_SL3:BYTE	;;
EXTRN	HARD_SL4:BYTE,RAM_SL4:BYTE	;;
EXTRN	RESERVED1:WORD,RESERVED2:WORD	;;
					;;
					;;
					;;
CSEG	SEGMENT PARA PUBLIC 'CODE'      ;;
	ASSUME	CS:CSEG 		;;
					;;
					;;
EXTRN	PARSER:NEAR			;; WGR					    ;AN000;
EXTRN	ROM_INT2F:WORD			;; WGR					    ;AN000;
EXTRN	INT2F_COM:NEAR			;; WGR					    ;AN000;
EXTRN	ABORT:BYTE			;; WGR					    ;AN000;

CODE_END     EQU $			;; end of resident code
					;;
	     DW  0			;; -- there are 16 bytes kept,
					;;    including this word
					;;
RESIDENT_END DW  0FFFH			;; end of extended resident area
STACK_ALLOCATED  DW -1			;; end of extended resident area
					;;
	     DW  150 DUP(0)		;; need some space here.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	End of resident code
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;
;;			  ++++++++++++++++++++++++
;;			  ++	INIT Command	++
;;			  ++++++++++++++++++++++++
;;
;;====	Command Code 0 - Initialization  ======
;;
;; messages returned :
;;
;; msg_bad_syntax  -- syntax error from parser, no driver installation
;; msg_no_init	   -- device cannot be initialised
;; msg_insuff_mem  -- insufficient memory
;;
;; layout :	the initialization is done in two stages :
;;
;;		  ++++++++++++++++++++++++
;;		  ++   INIT Stage 1	++	to examine and extract the
;;		  ++++++++++++++++++++++++	parameters defined for the
;;						device_id in DEVICE command,
;;						according to the printer
;;						description table for the
;;						device_id.
;;
;;		  ++++++++++++++++++++++++
;;		  ++   INIT Stage 2	++	to set the BUFfer for the LPTn
;;		  ++++++++++++++++++++++++	or PRN according to device_id's
;;						parameters
;;
;;
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
					;;
DEV_NUM dw	?			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;     Tables for the deivce_id parameters in the order of device_id in the
;     PARSE table
;     === the tables serves as the link between LPTn to be defined in the 2nd
;	  stage, and the device_id that is processed in the first stage.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; device ID indicators :
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DID_MAX EQU	4			;; device entris exepcted in PARSE
;; not more than 16.			;; table
					;;
DID_STATUS DW	0			;; status of parsing device id
					;;  =  0 : all Device-ID bad
					;;  -- see DID_BIT
					;;
DID_MATCH  DW	0			;; this DID has device_name matched
					;;
DID_FAIL   DW	0			;; to fail the good DID_STATUS and
					;; the matched name. (due to
					;; inconsistency among the same LPTn
					;; or between PRN and LPT1.)
					;;
;; (DID_STATUS) AND (DID_MATCH) XOR (DID_FAIL) determines the success of DID
					;;		       initialization
					;;
DID_ONE EQU	00001H			;; first device-ID
DID_TWO EQU	00002H			;; second "
DID_THREE EQU	  00004H		;; third  "
DID_FOUR  EQU	  00008H		;; fourth "
;;maximun number of device_id = 16	;;
					;;
DID_BIT LABEL WORD			;;
	DW	DID_ONE 		;;
	DW	DID_TWO 		;;
	DW	DID_THREE		;;
	DW	DID_FOUR		;;
;;maximun number of device_id = 16	;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; device paramters according to the
					;; device_id defined in DEVICE and the
					;; parameters defined for the device_id
					;; in the printer description table.
					;;
HRMAX	LABEL	word			;; number of hwcp+cart slots supported
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
CTMAX	LABEL	word			;; number of cart slots supported
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
RMMAX	LABEL	word			;; number of ram-slots supported
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
RBUMAX	LABEL	word			;; number of ram-designate slots
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
DESCO	LABEL	word			;; offset to the description table
					;; where the device_id is defined.
	DW	-1			;;  did = 1
	DW	-1			;;  did = 2
	DW	-1			;;  did = 3
	DW	-1			;;  did = 4
;upto max  DID_MAX			;;
					;;
FSIZE	LABEL	word			;; font size of the device
	DW	 0			;;  did = 1
	DW	 0			;;  did = 2
	DW	 0			;;  did = 3
	DW	 0			;;  did = 4
;upto max  DID_MAX			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Hard/RAM slots table in the order of DEVICE parameters
;
;   number of entries in all HARD_SLn is determined by the max. {HSLOTS}, and
;   number of entries in all RAM_SLn  is determined by the max. {RSLOTS}
;
;   -- they are initialized according to the device_id defined in the DEVICE.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
HARD_SLA LABEL	word			;; index in the order of device in
	DW	OFFSET	(HARD_SL1)	;; the PARSE-talbes
	DW	OFFSET	(HARD_SL2)	;;
	DW	OFFSET	(HARD_SL3)	;;
	DW	OFFSET	(HARD_SL4)	;;
; up to DID_MAX 			;;
					;;
RAM_SLA LABEL	word			;;
	DW	OFFSET (RAM_SL1)	;;
	DW	OFFSET (RAM_SL2)	;;
	DW	OFFSET (RAM_SL3)	;;
	DW	OFFSET (RAM_SL4)	;;
; up to DID_MAX 			;;
					;;
SUB_SIZE	EQU	11		;; WGR sublist size			    ;AN000;
LEFT_ASCIIZ	EQU	00010000B	;; WGR left-aligned asciiz string	    ;AN000;
UNLIMITED	EQU	0		;; WGR unlimited message size.		    ;AN000;
					;; WGR					    ;AN000;
SUBLIST LABEL	DWORD			;; WGR					    ;AN000;
	DB	SUB_SIZE		;; WGR					    ;AN000;
	DB	0			;; WGR					    ;AN000;
MSG_PTR DW	?			;; WGR					    ;AN000;
MSG_SEG DW	SEG CSEG		;; WGR					    ;AN000;
	DB	1			;; WGR					    ;AN000;
	DB	LEFT_ASCIIZ		;; WGR					    ;AN000;
	DB	UNLIMITED		;; WGR					    ;AN000;
	DB	1			;; WGR					    ;AN000;
	DB	" "                     ;; WGR                                      ;AN000;
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	 ++++++++++++++++++++++++
;;	 ++    INIT Command    ++
;;	 ++++++++++++++++++++++++
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
INIT	PROC	NEAR			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; parse the initialization parameters in DEVICE command
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
	PUSH	BX			;; WGR					    ;AN000;
	CALL	SYSLOADMSG		;; WGR load messages			    ;AN000;
	JNC	CONT_1			;; WGR if no error then continue	    ;AN000;
	CALL	SYSDISPMSG		;; WGR error (DOS version)..display	    ;AN000;
	POP	BX			;; WGR message....			    ;AN000;
	JMP	SYNTAX_ERROR		;; WGR ...and exit with error code.	    ;AN000;
					;; WGR					    ;AN000;
CONT_1: 				;; WGR					    ;AN000;
	POP	BX			;; WGR					    ;AN000;
	CMP	BUF.BFLAG,BF_PRN	;; since PRN is the FIRST device header
	JNE	NOT_PRN 		;;
					;;
					;;
	MOV	AX,OFFSET CODE_END	;; defined only once for each DEVICE
	XOR	CX,CX			;;
	MOV	CL,4			;;
	SHR	AX,CL			;;
	PUSH	CS			;;
	POP	CX			;;
	ADD	AX,CX			;;
	INC	AX			;; leave 16 bytes,room for resident_end
	MOV	RESIDENT_END,AX 	;;
					;;
	CALL	PARSER			;; call only once, for PRM
					;;
	JMP	PROCESS_TABLE		;;
					;;
NOT_PRN :				;;
	CMP	DEV_NUM,1		;;
					;;
	JNB	PROCESS_TABLE		;;
					;;
	JMP	SYNTAX_ERROR		;;
					;;
					;;
					;;
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;
;;	 ++++++++++++++++++++++++
;;	 ++   INIT Stage 1     ++
;;	 ++++++++++++++++++++++++
;;
;;  INIT - FIRST STAGE :
;;
;;    == test and extract if the parameters on device-id is valid
;;    == determine the DID_STATUS according to the validity of the parameters
;;    == procedure(s) called -- DID_EXTRACT
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
					;;
PROCESS_TABLE : 			;;
					;;
	PUSH	CS			;;
	POP	ES			;; PSE points to Device offsets
	MOV	DI,OFFSET(table)	;; ES:[DI]
	MOV	DX,PSE.PAR_DEV_NUM	;;
	MOV	DEV_NUM,DX		;;
					;;
	CMP	DEV_NUM,0		;;
	JNZ	NO_SYNTAX_ERR		;;
					;;
					;; WGR					    ;AN000;
	PUSH	BX			;; WGR					    ;AN000;
	MOV	AX,BAD_SYNTAX_MSG	;; WGR 'bad syntax' message                 ;AN000;
	MOV	BX,STDERR		;; WGR	to standard error		    ;AN000;
	XOR	CX,CX			;; WGR					    ;AN000;
	XOR	DL,DL			;; WGR					    ;AN000;
	MOV	DH,UTILITY_MSG_CLASS	;; WGR class = parse error		    ;AN000;
	CALL	SYSDISPMSG		;; WGR display message. 		    ;AN000;
	POP	BX			;; WGR					    ;AN000;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SYNTAX_ERROR :				;; set the request header status
					;; according to the STATE
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	AX, RESIDENT_END	;;
	PUSH	CS			;;
	POP	CX			;; CX=CS
	SUB	AX,Cx			;; additional segment required.
CS_LOOP1:				;;
	CMP	AX,1000H		;;
	JB	CS_LPEND1		;;
	ADD	CX,1000H		;;
	SUB	AX,1000H		;;
	JMP	CS_LOOP1		;;
					;;
CS_LPEND1:				;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
					;;
	LES	DI,dword ptr buf.rh_ptro ;; get Request Header address
;	MOV	RH.RH0_ENDO,AX		;;
	MOV	RH.RH0_ENDO,0		;;
	MOV	RH.RH0_ENDS,CX		;;
	mov	rh.RH0_CONFIG_ERRMSG, -1  ;DCR D493 2/25/88 "Error in CONFIG.SYS..." msg flag.
	MOV	RH.RHC_STA,stat_cmderr	;; set status in request header
					;;
	JMP	INIT_RETurn		;;
					;;
					;;
NO_SYNTAX_ERR : 			;;
					;;
	CMP	DX,DID_MAX		;;
	JNA	NEXT_DID		;;
					;;
	MOV	INIT_CHK,0001H		;; ERROR 0001
	JMP	BAD_DID 		;; more than supported no. of device
					;;
NEXT_DID:				;;
	PUSH	DI			;; pointer to PAR_OT (table 1)
	AND	DX,DX			;;
	JNZ	SCAN_DESC		;;
	JMP	END_DID 		;; DI = offset to the 1st PARSE table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCAN_DESC:				;;
	MOV	DI,PSE.PAR_OFF		;; points to the nth device
					;;
					;; find the description for the
					;;device-id
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	CX,PRINTER_DESC_NUM	;;
	MOV	SI, OFFSET(PRINTER_DESC_TBL); offset to the description table
	PUSH	CS			;;
	POP	DS			;;
;	$SEARCH 			;;
$$DO1:
	    PUSH    CX			;; save device count
	    PUSH    SI			;; pointer to printer-descn's offset
	    MOV     SI,CS:WORD PTR[SI]	;;
	    AND     CX,CX		;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	$LEAVE	Z			;; LEAVE if no more device description
	JZ $$EN1
	    PUSH    DI			;; save offset to PAR_DEVOT
	    MOV     DI,PSE.PAR_DIDO	;;
	    MOV     CX,PSE.PAR_DIDL	;; length of parsed device name
	    LEA     DI,PSE.PAR_DID	;; pointer to parse device name
					;;
	    PUSH    SI			;;
	    LEA     SI,[SI].TYPEID	;; offset to name of device-id
	    REPE    CMPSB		;;
	    POP     SI			;;
	    POP     DI			;; get back offset to PAR_DEVOT
					;;;;;;;;;;;;;;;;;;;;;;;;
;	$EXITIF Z			;; EXIT if name matched
	JNZ $$IF1
					;;
	    CALL    DID_EXTRACT 	;; get the parameters
					;;
	    POP     SI			;; balance push-pop
	    POP     CX			;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	$ORELSE 			;; try next description :
	JMP SHORT $$SR1
$$IF1:
					;;
	    POP     SI			;; of printer_descn offset table
	    INC     SI			;;
	    INC     SI			;; next offset to PRINTER_DESCn
					;;
	    POP     CX			;; one description less
	    DEC     CX			;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	$ENDLOOP			;; DEVICE-ID not defined in
	JMP SHORT $$DO1
$$EN1:
					;; printer_desc;
					;;
	    MOV     AX,INIT_CHK 	;;
	    AND     AX,AX		;;
	    JNZ     UNCHANGED		;;
	    MOV     INIT_CHK,0004H	;; ERROR 0004
UNCHANGED:				;;
	    POP     SI			;; balance push-pop
	    POP     CX			;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	$ENDSRCH			;; End of scanning printer_desc
$$SR1:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	POP	DI			;;
	INC	DI			;;
	INC	DI			;; points to next device in PART_OT
	DEC	DX			;;
					;;
	JMP	NEXT_DID		;;
					;;
END_DID :				;;
	POP	DI			;;
BAD_DID :				;;
					;;
	MOV	AX,DID_STATUS		;;
	AND	AX,AX			;;
	JNZ	DEF_BUFFER		;;
					;;
	JMP	END_LPT 		;;
					;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;
;;	++++++++++++++++++++++++
;;	++   INIT Stage 2     ++
;;	++++++++++++++++++++++++
;;
;; INIT -- SECOND STAGE :
;;
;;	== match the device_name extracted in stage 1 with the name of PRN or
;;	   LPTn
;;
;;	== if the PRN/LPTn has never been defined before, then set up the BUF
;;	   for the PRN/LPTn if the DID_STATUS is good; otherwise message will
;;	   be generated indicating it cannot be initilized.
;;
;;	== if there is PRN, LPT1 is also setup, and vice vera. IF both PRN and
;;	   LPT1 are on the DEVICE command, or there are multiple entries for
;;	   the same LPTn, the consistency is checked. It they are inconsistent
;;	   the associated LPTn or PRN is forced to fail by : DID_FAIL.
;;
;;	== if the device_name on the DEVICE command is not one of the supported
;;	   PRN or LPTn, then DID_MATCH bit will not be set. An error message
;;	   will be generated for the device_name indicating it cannot be
;;	   initialized.
;;
;;	== procedure(s) called : CHK_DID   .. check DID parameters for device
;;					      whose name matched.
;;				 DEV_CHECK .. if device-name duplicated, or
;;					      there are both PRN/LPT1 : check
;;					      for consistent parameters.
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DEF_BUFFER :				;;
	PUSH	CS			;;
	POP	ES			;; PSE points to Device offsets
	MOV	DI,OFFSET(table)	;; ES:[DI]
	xor	cx,cx			;; device order in parse table
;SEARCH 				;;
$$DO7:
	    PUSH    DI			;; pointer to PAR_OT
	    PUSH    CX			;; save device count
	    MOV     DI,PSE.PAR_OFF	;;   "     "  PAR_DEVOT
	    cmp     cx,dev_num		;;
					;;
;LEAVE NB				;; LEAVE if no more device entry
	   jb	    MORE_DEVICE 	;;
	   JMP	    $$EN7
MORE_DEVICE :				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; more parsed_device to be checked
	    PUSH    DI			;; save offset to PAR_DEVOT
	    MOV     DI,PSE.PAR_DNMO	;;
	    MOV     CX,PSE.PAR_DNML	;; length of parsed device name
	    LEA     DI,PSE.PAR_DNM	;; pointer to parse device name
					;;
	    LDS     SI,DWORD PTR BUF.DEV_HDRO ; get the offset to device-n header
	    LEA     SI,HP.DH_NAME	;; "       offset to name of device-n
	    REPE    CMPSB		;;
	    POP     DI			;; get back offset to PAR_DEVOT
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;
;EXITIF Z				;; EXIT if name matched
	JZ  NAME_MATCHED		;;
					;;
	JMP MORE_PARSED_DEVICE		;;
					;;
NAME_MATCHED :				;;
					;;
	    POP     CX			;; the DID order
	    PUSH    BX			;;
	    MOV     BX,CX		;;
	    ADD     BX,BX		;;
	    MOV     AX,DID_BIT[BX]	;;
	    OR	    DID_MATCH,AX	;; this DID matched
	    POP     BX			;;
	    PUSH    CX			;;
					;;
	    LEA     SI,BUF.PAR_EXTRACTO ;; was the LPT1/PRN defined before ?
	    MOV     AX,CS:[SI].PAR_DNMO ;;
	    CMP     AX,0FFFFH		;;
					;;
	    JNE     DEV_COMPARE 	;; DI = PAR_DEVOT
					;;-----------------------------------
					;;
					;; no device previousely defined
	    MOV     AX,PSE.PAR_DNMO	;;
	    MOV     CS:[SI].PAR_DNMO,AX ;; define device parameters for LPTn
					;;
	    MOV     AX,PSE.PAR_DIDO	;;
	    MOV     CS:[SI].PAR_DIDO,AX ;;
					;;
	    MOV     AX,PSE.PAR_HWCPO	;;
	    MOV     CS:[SI].PAR_HWCPO,AX ;;
					;;
	    MOV     AX,PSE.PAR_DESGO	;;
	    MOV     CS:[SI].PAR_DESGO,AX ;;
					;;
	    MOV     AX,PSE.PAR_PARMO	;;
	    MOV     CS:[SI].PAR_PARMO,AX ;;
					;;
					;;---------------------------------
	    CALL    CHK_DID		;; define the STATE according to
					;; DID_STATUS
	    JMP     MORE_PARSED_DEVICE	;;
					;;
DEV_COMPARE :				;;-------------------------------
					;; e.g. LPT1 and PRN shares one BUF.
					;;	or duplicated device name
	    CALL    DEV_CHECK		;;
					;;
	    CMP     BUF.STATE,CPSW	;;
	    JNE     DEV_COMPARE_FAIL	;;
					;;
	    JMP     MORE_PARSED_DEVICE	;;
					;;
DEV_COMPARE_FAIL :			;;
					;;
	    POP     CX			;;
	    POP     DI			;; balance push-pop
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;$ORELSE				;;
	JMP	  END_LPT
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MORE_PARSED_DEVICE :			;; name does not match
					;;
	    POP     CX			;;
	    INC     CX			;;
	    POP     DI			;;
	    INC     DI			;;
	    INC     DI			;; points to next device in PART_OT
					;;
	    jmp     $$DO7		;;
;$ENDLOOP				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
$$EN7:					;; no device found for LPTn
					;;
	    POP     CX			;;
	    POP     DI			;; balance push-pop
					;;
	    CMP     BUF.STATE,CPSW	;;
	    JE	    END_LPT		;; for LPT1/PRN pair
					;;
	    MOV     BUF.STATE,NORMAL	;; no device defined for the LPTn
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; End of defining LPTn Buffer
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;$ENDSRCH				;;
END_LPT :				;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; set the request header status
					;; according to the STATE
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	AX, RESIDENT_END	;;
	PUSH	CS			;;
	POP	CX			;; CX=CS
	SUB	AX,Cx			;; additional segment required.
CS_LOOP2:				;;
	CMP	AX,1000H		;;
	JB	CS_LPEND2		;;
	ADD	CX,1000H		;;
	SUB	AX,1000H		;;
	JMP	CS_LOOP2		;;
					;;
CS_LPEND2:				;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
					;;
	LES	DI,dword ptr buf.rh_ptro ;; get Request Header address
	MOV	RH.RH0_ENDO,AX		;;
	MOV	RH.RH0_ENDS,CX		;;
	XOR	AX,AX			;; clear error code to be returned
	MOV	CX,BUF.STATE		;;
	CMP	CX,CPSW 		;;
	JE	MATCH_GOOD		;;
	MOV	AX,STAT_CMDERR		;;
					;;
MATCH_GOOD :				;;
	MOV	RH.RHC_STA,AX		;; set status in request header
	CALL	LOAD_INT2F		;; WGR load INT2f handler		    ;AN000;
					;;
BUF_END :				;;
					;;
	CMP	BUF.BFLAG,BF_LPT1	;;
	JNE	BUF_MESSAGES		;;
					;;
	CMP	BUF.STATE,CPSW		;;
	JNE	BUF_MESSAGES		;;
					;; set PRN to the same setting as LPT1
	PUSH	BX			;;
					;;
	LEA	SI,BUF.RNORMO		;;
	LEA	CX,BUF.BUFEND		;;
	SUB	CX,SI			;;
	MOV	BX,BUF.PRN_BUFO 	;; where PRN buffer is
	LEA	DI,BUF.RNORMO		;;
	PUSH	CS			;;
	POP	ES			;;
	PUSH	CS			;;
	POP	DS			;;
	REP	MOVSB			;;
					;;
	POP	BX			;;
					;;
BUF_MESSAGES :				;;
	CMP	BUF.BFLAG,BF_LPT3	;; generate error message is this is
	je	last_round		;; the last LPTn
	Jmp	INIT_RETURN		;;
					;; ERROR messages will be generated
					;; at the end of initialization of all
					;; the LPT devices
last_round :				;;
	MOV	AX,RESIDENT_END 	;;
	ADD	AX,STACK_SIZE		;;
	MOV	RESIDENT_END,AX 	;;
	PUSH	CS			;;
	POP	CX			;; CX=CS
	SUB	AX,Cx			;; additional segment required.
CS_LOOP3:				;;
	CMP	AX,1000H		;;
	JB	CS_LPEND3		;;
	ADD	CX,1000H		;;
	SUB	AX,1000H		;;
	JMP	CS_LOOP3		;;
					;;
CS_LPENd3:				;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
					;;
	MOV	RH.RH0_ENDO,AX		;; STACK !!!!!
	MOV	STACK_ALLOCATED,0	;; from now on, internal stack is used
					;;
	MOV	AX,DID_STATUS		;; what is the DID combination ?
	AND	AX,DID_MATCH		;;
	XOR	AX,DID_FAIL		;;
					;;
	AND	AX,AX			;;
	JNZ	CODE_STAYED		;;
;	MOV	RH.RH0_ENDO,0		;; none of the devices are good
					;;
					;;
CODE_STAYED :				;;
	MOV	DI,OFFSET TABLE 	;;
	push	CS			;;
	POP	ES			;;
					;;
	XOR	CX,CX			;;
MSG_LOOP :				;;
	CMP	CX,DEV_NUM		;;
	JNB	INIT_RETURN		;;
	SHR	AX,1			;;
	JC	MSG_NEXT		;;
					;; this device in parse table is bad
	PUSH	DI			;;
	PUSH	CX			;;
	PUSH	AX			;;
	PUSH	BX			;; WGR					    ;AN000;
	PUSH	DX			;; WGR					    ;AN000;
					;;
	MOV	DI,PSE.PAR_OFF		;;
	MOV	SI,PSE.PAR_DNMO 	;;
					;;
	PUSH	CS			;;
	POP	ES			;;
	PUSH	CS			;;
	POP	DS			;;
					;;
	MOV	CX,8			;;
	LEA	SI,[SI].PAR_DNM 	;;
	MOV	DI,SI			;;
	MOV	AL,' '                  ;; WGR                                      ;AN000;
	CLD				;; WGR					    ;AN000;
	REPNE	SCASB			;; WGR					    ;AN000;
	DEC	DI			;; WGR					    ;AN000;
	MOV	BYTE PTR ES:[DI],ZERO	;; WGR					    ;AN000;
					;; WGR					    ;AN000;
	MOV	MSG_SEG,CS		;; WGR					    ;AN000;
	MOV	MSG_PTR,SI		;; WGR					    ;AN000;
	MOV	AX,BAD_DEVICE_MSG	;; WGR					    ;AN000;
	MOV	BX,STDERR		;; WGR					    ;AN000;
	LEA	SI,SUBLIST		;; WGR					    ;AN000;
	MOV	CX,ONE			;; WGR					    ;AN000;
	XOR	DL,DL			;; WGR					    ;AN000;
	MOV	DH,UTILITY_MSG_CLASS	;; WGR					    ;AN000;
	CALL	SYSDISPMSG		;; WGR					    ;AN000;
					;;					    ;AN000;
	POP	DX			;; WGR					    ;AN000;
	POP	BX			;; WGR					    ;AN000;
	POP	AX			;;
	POP	CX			;;
	POP	DI			;;
					;;
MSG_NEXT :				;;
	INC	CX			;;
	INC	DI			;;
	INC	DI			;;
	JMP	MSG_LOOP		;;
					;;
					;;
INIT_RETURN :				;;
					;;
					;;
	RET				;;
					;;
INIT	ENDP				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Call by INIT to extract parameters for the deivce_id
;;
;; on rntry :
;;	ES:[DI]  PARSE Table 2, offsets of all parameters
;;	DS:[SI]  Printer Description table whose TYPEID matched
;;	DX	 "inverse" order of devices in the PARSE tables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
DID_EXTRACT PROC			;;
					;;
	PUSH	DX			;;
					;;-----------------------------
					;; define the DID_parameters
	PUSH	BX			;;
					;;
	MOV	BX,DEV_NUM		;;
	SUB	BX,DX			;; order in the Parse table
	add	bx,bx			;; double to index [bx]
	MOV	DX,BX			;;
					;;
	MOV	AX,DS:[SI].FONTSZ	;;
	MOV	FSIZE[BX],AX		;; size of font buffer to be created
					;;
	MOV	AX,DS:[SI].HSLOTS	;;
	CMP	AX,HARDSL_MAX		;;
	JNA	LESS_HARDSL		;;
	MOV	INIT_CHK, 0010H 	;; ERROR 0010H
	POP	BX			;;
	JMP	END_MATCH_BAD		;;
LESS_HARDSL :				;;
	CMP	AX,DS:[SI].HWCPMIN	;;
	JNB	VALID_HARDSL		;;
	MOV	INIT_CHK, 0012H 	;; ERROR 0012H
	POP	BX			;;
	JMP	END_MATCH_BAD		;;
VALID_HARDSL :				;;
	MOV	HRMAX[BX],AX		;;
	MOV	CTMAX[BX],AX		;; will be reduced by the no. of hwcp
					;;
	MOV	AX,DS:[SI].RSLOTS	;;
	CMP	AX,RAMSL_MAX		;;
	JNA	LESS_RAMSL		;;
	MOV	INIT_CHK, 0011H 	;; ERROR 0011H
	POP	BX			;;
	JMP	END_MATCH_BAD		;;
LESS_RAMSL :				;;
	MOV	RMMAX[BX],AX		;;	see also designate
					;;
	MOV	DESCO[BX],SI		;;
					;;
	POP	BX			;;
					;;----------------------------------
					;;
	PUSH	CX			;;
					;;
HWCPgt: PUSH	DI			;; get the hwcp
					;;
	MOV	DI,PSE.PAR_HWCPO	;;
	MOV	CX,PSE.PAR_HWCPL	;; no. of hwcp
	AND	CX,CX			;;
	JNZ	chk_hwcp		;;
	push	bx			;;
	mov	bx,dx			;;
	MOV	HRMAX[BX],CX		;;
	MOV	CX,DS:[SI].HWCPMIN	;;
	SUB	CTMAX[BX],CX		;; what is left becomes cartridge slot
	pop	bx			;;
	JMP	DESIGN			;;
					;; hwcp to be defined
chk_hwcp: MOV	AX,DS:[SI].HSLOTS	;; defined in printer_desc
	CMP	CX,AX			;;
	JA	BAD_MATCH2		;;
	CMP	CX,HARDSL_MAX		;;
	JNA	HWCP_GOOD		;; jump if system error
	MOV	INIT_CHK,0003H		;; ERROR 0003
	JMP	END_MATCH		;;
BAD_MATCH2:				;;
	MOV	INIT_CHK,0002H		;; ERROR 0002
	JMP	END_MATCH		;;
					;;
HWCP_GOOD:				;; there are sufficient hard-slot for
					;; HWCP
	PUSH	SI			;; printer description table of TYPEID
	PUSH	BX			;;
					;;
	MOV	BX,DX			;;
	MOV	AX,CTMAX[BX]		;;
					;;
	PUSH	CX			;; calculate what is left for cart_slot
	CMP	CX,DS:[SI].HWCPMIN	;;
	JNB	MORE_THAN_HWCPMIN	;;
	MOV	CX,DS:[SI].HWCPMIN	;;
MORE_THAN_HWCPMIN :			;;
	SUB	AX,CX			;;
	POP	CX			;;
	mov	HRMAX[BX],CX		;;
					;;
	MOV	CTMAX[BX],AX		;; no of cart-slot for designate
	MOV	SI,HARD_SLA[BX] 	;; get the corresponding hard-slots
					;;
	POP	BX			;;
					;;
	push	bx			;;
	push	dx			;;
	mov	bx,si			;;
	mov	dx,cx			;;
	mov	reserved1,dx		;; IF THERE IS ANY REPETITIVE HWCP
	mov	reserved2,bx		;; IF THERE IS ANY REPETITIVE HWCP
					;;
FILL_HWCP:				;;
	AND	CX,CX			;;
	JZ	DESIGN_P		;;
	INC	DI			;; next code page in PARSE table
	INC	DI			;;
	MOV	AX,ES:[DI]		;; get code page value
					;;
					;; IF THERE IS ANY REPETITIVE HWCP
	push	dx			;;
	push	bx			;;
hwcp_norep :				;;
	cmp	ax,cs:[bx].slt_cp	;;
	jne	hwcp_repnext		;;
	pop	bx			;;
	pop	dx			;;
	pop	dx			;;
	pop	bx			;;
	pop	si			;;
	jmp	end_match		;;
					;;
hwcp_repnext:				;;
	inc	bx			;;
	inc	bx			;;
	inc	bx			;;
	inc	bx			;;
	dec	dx			;;
	jnz	hwcp_norep		;;
	pop	bx			;;
	pop	dx			;;
					;;
	MOV	CS:[SI].SLT_CP,AX	;;
	MOV	AX,CS:[SI].SLT_AT	;; get the attributes
	OR	AX,AT_OCC		;; occupied
	OR	AX,AT_HWCP		;; hwcp slot
	MOV	CS:[SI].SLT_AT,AX	;;
	INC	SI			;;
	INC	SI			;; next slot
	INC	SI			;; next slot
	INC	SI			;; next slot
	DEC	CX			;;
	JMP	FILL_HWCP		;;
DESIGN_P:				;;
	pop	dx			;;
	pop	bx			;;
	POP	SI			;;
					;;---------------------
DESIGN: POP	DI			;; get the designate no.
	PUSH	DI			;;
					;;
	MOV	DI,PSE.PAR_DESGO	;;
	MOV	AX,PSE.PAR_DESGL	;;
	CMP	AX,1			;;
	JA	END_MATCH		;; there should have no font entry
	AND	AX,AX			;;
	JZ	DEF_RBUFMAX		;;
					;;
	MOV	AX,PSE.PAR_DESG 	;;
	AND	AX,AX			;;
	JZ	DEF_RBUFMAX		;;
					;;
	CMP	CS:[SI].CLASS,1 	;;
	JNE	DESIG_NOt_CLASS1	;;
					;;
	PUSH	BX			;; if there is any cartridge slot ?
	PUSH	AX			;;
	MOV	BX,DX			;;
	MOV	AX,ctmax[BX]		;;
	AND	AX,AX			;;
	POP	AX			;;
	POP	BX			;;
	JZ	END_MATCH		;; fail, as there is no physical RAM.
					;;
	CMP	AX,HARDSL_MAX		;; is the designate more than max ?
	JA	END_MATCH		;;
					;;
					;;
	JMP	DEF_RBUFMAX		;;
					;;
					;;
					;;
DESIG_NOT_CLASS1 :			;;
	PUSH	BX			;; if there is any physical RAM slot ?
	PUSH	AX			;;
	MOV	BX,DX			;;
	MOV	AX,RMMAX[BX]		;;
	AND	AX,AX			;;
	POP	AX			;;
	POP	BX			;;
	JZ	END_MATCH		;; fail, as there is no physical RAM.
					;;
					;;
	CMP	AX,RAMSL_MAX		;; is the designate more than max ?
	JA	END_MATCH		;;
					;;
DEF_RBUFMAX :				;;
	PUSH	BX			;;
	MOV	BX,DX			;;
	MOV	RBUMAX[BX],AX		;;
	POP	BX			;;
					;;
					;;
PARAM : 				;;
;PARM:	    POP     DI			;;
;	    PUSH    DI			;;
;;	    MOV     DI,PSE.PAR_PARMO	;;
					;;
					;,--------------------------
					;; GOOD device_id parameters
	shr	dx,1			;;
	MOV	AX,DID_ONE		;;
	MOV	CX,DX			;;
	AND	CX,CX			;;
	JZ	NO_SHL			;;
	SHL	AX,CL			;;
NO_SHL: OR	DID_STATUS,AX		;; is defined
					;;-------------------------
END_MATCH: POP	DI			;; end of extract
	POP	CX			;;
END_MATCH_BAD : 			;;
	POP	DX			;;
					;;
	RET				;;
					;;
DID_EXTRACT ENDP			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Called by INIT to define the STATE and BUF for the LPTn according to
;; the DID_STATUS. Create font buffer if requested through the "desi*nate"
;;
;; at entry :  CX = device order in parse table
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_DID PROC				;;
					;;
	push	cx			;;
	push	di			;;
	push	dx			;;
					;;
	MOV	AX,DID_STATUS		;;
					;;
	PUSH	CX			;; order 0 to m
	POP	DI			;;
	ADD	DI,DI			;; indexing : [DI]
					;;
	INC	CX			;;
	SHR	AX,CL			;; is the device parameter valid ?
					;;
	JC	DEFINE_BUFFER		;;
	JMP	LPT_FAIL		;;--------------------------
					;;
DEFINE_BUFFER : 			;;
					;; good device parameters as determined
	MOV	AX,DESCO[DI]		;;
	MOV	BUF.PDESCO,AX		;;
					;;
	PUSH	DI			;;
	MOV	DI,AX			;;
	MOV	AX,CS:[DI].CLASS	;;
	MOV	BUF.PCLASS,AX		;;
	POP	DI			;;
					;;
	MOV	AX,HARD_SLA[DI] 	;;  in the DID_EXTRACT
	MOV	BUF.HARDSO,AX		;;
					;;
	MOV	AX,RAM_SLA[DI]		;;
	MOV	BUF.RAMSO,AX		;;
					;;
	MOV	AX,HRMAX[DI]		;;
	MOV	BUF.HARDMX,AX		;;
					;;
	MOV	AX,CTMAX[DI]		;;
	MOV	BUF.HCARMX,AX		;;
					;;
	ADD	AX,HRMAX[DI]		;; defore "designate"
	MOV	BUF.HSLMX,AX		;;
					;;
					;;
	MOV	AX,RMMAX[DI]		;;
	MOV	BUF.RAMMX,AX		;;
					;;
	XOR	AX,AX			;;
	PUSH	CX			;; calculate the max. length of control
	MOV	CX,2			;; sequence that is allowed for the
	CMP	BUF.PCLASS,1		;; room reserved for physical slots.
	JNE	CTL_LOOP		;;
	MOV	CX,1			;; class 1 printer has one control seq.
CTL_LOOP :				;;
	ADD	AX,CTL_MAX		;;
	DEC	AX			;; leave one byte for the length
	DEC	CX			;;
	JNZ	CTL_LOOP		;;
	MOV	BUF.FSELMAX,AX		;;
	POP	CX			;;
					;;
	MOV	AX,FSIZE[DI]		;;
	MOV	BUF.FTSZPA,AX		;; FTSIZE in paragraph
					;;
	PUSH	AX			;;
					;;
	MOV	DX,4			;;
FT_PARA:				;;
	ADD	AX,AX			;;
	DEC	DX			;;
	JNZ	FT_PARA 		;; font size
	MOV	BUF.FTSIZE,AX		;; font size in bytes (used with.RBUFMX)
					;;
	POP	DX			;; FTSIZE in paragraph
					;;
	MOV	CX,RBUMAX[DI]		;; create font buffer per .RBUFMX and
	MOV	BUF.RBUFMX,CX		;; assume sufficient memory for all the
					;; "designate request"
	PUSH	CX			;;
					;;
	CMP	BUF.PCLASS,1		;; always create font buffer for class1
	JNE	CLASS_NOT_1		;;
					;;
	AND	CX,CX			;;
	JZ	CLASS1_NOCX		;;
	ADD	CX,BUF.HARDMX		;;
	MOV	BUF.HSLMX,CX		;;
	JMP	CLASS_NOT_1		;;
					;;
CLASS1_NOCX:				;;
	MOV	CX,BUF.HSLMX		;;
					;;
CLASS_NOT_1 :				;;
	AND	CX,CX			;;
	JZ	MULTIPLE_DONE		;;
	MOV	AX,RESIDENT_END 	;;
MULTIPLE_FT :				;;
	ADD	AX,DX			;; allocate the font buffers at the end
	DEC	CX			;; of the resident codes
	JNZ	MULTIPLE_FT		;;
					;;
					;;
	MOV	CX,RESIDENT_END 	;;
	MOV	BUF.FTSTART,CX		;;
	MOV	RESIDENT_END,AX 	;;
					;;
					;;
MULTIPLE_DONE : 			;;
	POP	CX			;; designate requested
					;;
	CMP	BUF.PCLASS,1		;;
	JNE	DEF_RBUF		;;
					;; CLASS 1
	CMP	BUF.HARDMX,0		;;
	JE	DEFBUF_DONE		;;
					;;
	PUSH	CX			;; STACKS...
	PUSH	SI			;;
	PUSH	DS			;;
	PUSH	ES			;;
	PUSH	DI			;;
	PUSH	DX			;;
					;;
	MOV	DX,BUF.HARDMX		;;
	PUSH	DX			;; STACK +1 -- # of HWCP
					;;
	PUSH	CS			;;
	POP	DS			;;
	MOV	BUF.RBUFMX,0		;;
	MOV	SI,BUF.PDESCO		;;
	MOV	SI,CS:[SI].SELH_O	;;
	XOR	CX,CX			;;
	MOV	CL,CS:BYTE PTR [SI]	;;
	INC	CX			;; including the length byte
					;;
	MOV	DI,BUF.FTSTART		;; control template
DEF_FTBUF:				;; fill the  font buffer with the
	PUSH	DI			;;
	POP	ES			;;
	XOR	DI,DI			;;
					;;
	PUSH	CX			;;
	PUSH	SI			;;
	REP	MOVSB			;;
	POP	SI			;;
	POP	CX			;;
					;;
	PUSH	ES			;;
	POP	DI			;;
	ADD	DI,BUF.FTszpa		;;
	DEC	DX			;;
	JNZ	DEF_FTBUF		;;
					;;
	POP	DX			;; STACK -1
					;;
	MOV	SI,BUF.HARDSO		;;
	MOV	DI,BUF.FTSTART		;; define the HWCP values
DEF_FThwcp :				;;
	PUSH	DI			;;
	POP	ES			;;
	MOV	DI,CTL5202_OFFS 	;; offset to the HWCP words
					;;
	MOV	AX,CS:[SI].SLT_CP	;;
	MOV	ES:WORD PTR [DI],AX	;;
					;;
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
					;;
	PUSH	ES			;;
	POP	DI			;;
	ADD	DI,BUF.FTSZPA		;;
	DEC	DX			;;
	JNZ	DEF_FThwcp		;;
					;;
	POP	DX			;;
	POP	DI			;;
	POP	ES			;;
	POP	DS			;;
	POP	SI			;;
	POP	CX			;;
					;;
	JMP	DEFBUF_DONE		;;
					;;
					;;
DEF_RBUF :				;;
	MOV	BUF.RSLMX,CX		;; the no. of ram slots supported
	CMP	CX,RMMAX[DI]		;;
	JNB	DEFBUF_DONE		;;
	MOV	AX,RMMAX[DI]		;;
	MOV	BUF.RSLMX,AX		;; the max. of .RAMMX and .RBUFMX
					;;
DEFBUF_DONE :				;;
	MOV	BUF.STATE,CPSW		;; the LPTn is CPSW ----- STATE
					;;
	CMP	BUF.BFLAG,BF_PRN	;;
	JNE	RET_CHK_DID		;;
	MOV	AX,DID_BIT[DI]		;;
	MOV	BUF.DID_PRN,AX		;;
					;;
					;;
	JMP	RET_CHK_DID		;;
					;;
LPT_FAIL:				;;
					;;
	MOV	BUF.STATE,NORMAL	;; the LPTn is NORMAL --- STATE
					;;
					;;
RET_CHK_DID:				;;
					;;
	pop	dx			;;
	pop	di			;;
	pop	cx			;;
					;;
	RET				;;
					;;
CHK_DID ENDP				;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Called by INIT to check for consistency between duplicated device name and
;;	between PRN and LPT1
;;
;; at entry :  DI = pointer to PAR_DEVOT
;;	       BUF.STATE = any state
;;	       CX = DID order
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
DEV_CHECK PROC				;;
					;;
	LEA	SI,BUF.PAR_EXTRACTO	;;
					;;
	PUSH	CX			;;
					;;
	PUSH	SI			;; compare device id
	PUSH	DI			;;
	mov	SI,[SI].PAR_DIDO	;;
	MOV	DI,PSE.PAR_DIDO 	;;
	MOV	CX,PSE.PAR_DNML 	;;
	INC	CX			;; including length
	INC	CX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	Jz	hwcp_check		;;
	mov	init_chk,0021h		;; error 0021h
	Jmp	FORCE_LPT_BAD		;;
					;;
hwcp_check :				;;
	PUSH	SI			;; compare HWCP
	PUSH	DI			;;
	mov	SI,[SI].PAR_HWCPO	;;
	MOV	DI,PSE.PAR_HWCPO	;;
	MOV	AX,PSE.PAR_HWCPL	;;
	MOV	CX,2			;;
	SHL	AX,CL			;; multiply by two
	INC	AX			;; including length
	INC	AX			;;
	MOV	CX,AX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	Jz	desig_check		;;
	mov	init_chk,0022h		;; error 0022h
	Jmp	FORCE_LPT_BAD		;;
					;;
desig_check :				;;
	PUSH	SI			;; compare DESIGNATE
	PUSH	DI			;;
	mov	SI,[SI].PAR_DESGO	;;
	MOV	DI,PSE.PAR_DESGO	;;
	MOV	AX,PSE.PAR_DESGL	;;
	MOV	CX,2			;;
	SHL	AX,CL			;; multiply by two
	INC	AX			;; including length
	INC	AX			;;
	MOV	CX,AX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	Jz	param_check		;;
	mov	init_chk,0023h		;; error 0023h
	Jmp	FORCE_LPT_BAD		;;
					;;
param_check :				;;
	PUSH	SI			;; compare parameters
	PUSH	DI			;;
	mov	SI,[SI].PAR_PARMO	;;
	MOV	DI,PSE.PAR_PARMO	;;
	MOV	CX,PSE.PAR_PARML	;;
	INC	CX			;; including length
	INC	CX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	JZ	M_END			;;
	mov	init_chk,0024h		;; error 0024h
					;;
FORCE_LPT_BAD : 			;; the second set of parameters is
	MOV	BUF.STATE,NORMAL	;; bad
					;;
	CMP	BUF.BFLAG,BF_LPT1	;;
	JNE	M_END			;;
					;;
					;; since LPT1 is bad, force PRN to bad
	push	bx			;; force prn to be bad too
	mov	bx,buf.prn_bufo 	;;
	MOV	BUF.STATE,NORMAL	;;
	pop	bx			;;
					;;
	mov	AX,BUF.DID_PRN		;; if PRN was not good, DID_PRN = 0
	OR	DID_FAIL,AX		;;
					;;
					;;
M_END:					;; force the good did_status to fail if
					;; STATE is bad
	POP	CX			;;
	PUSH	CX			;; order 0 to m
	MOV	AX,DID_STATUS		;;
					;;
	INC	CX			;;
	SHR	AX,CL			;;
	POP	CX			;;
	JNC	DEV_CHECK_RET		;; already failed
					;;
	CMP	BUF.STATE,CPSW		;;
	JE	DEV_CHECK_RET		;;
					;;
	    PUSH    BX			;;
	    MOV     BX,CX		;;
	    ADD     BX,BX		;;
	    MOV     AX,DID_BIT[BX]	;;
	    OR	    DID_FAIL,AX 	;; force DID to fail
	    POP     BX			;;
					;;
					;;
DEV_CHECK_RET : 			;;
					;;
	RET				;;
					;;
					;;
DEV_CHECK ENDP				;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: LOAD_INT2F
;
; FUNCTION:
; THIS PROCEDURE LOADS THE INTERRUPT HANDLER FOR INT2FH
;
; AT ENTRY:
;
; AT EXIT:
;    NORMAL: INTERRUPT 2FH VECTOR POINTS TO INT2F_COM. OLD INT 2FH
;	     VECTOR STORED.
;
;    ERROR:  N/A
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SEMAPHORE  DB	  0								    ;AN000;
										    ;AN000;
LOAD_INT2F PROC   NEAR								    ;AN000;
	   CMP	  CS:SEMAPHORE,0		   ; already loaded?		    ;AN000;
	   JNE	  LI_1				   ; yes.....exit		    ;AN000;
	   PUSH   ES				   ; no...load. 		    ;AN000;
	   PUSH   CX				   ;				    ;AN000;
	   PUSH   AX				   ;				    ;AN000;
	   XOR	  AX,AX 			   ; point ES to low..		    ;AN000;
	   MOV	  ES,AX 			   ; memory.			    ;AN000;
	   MOV	  AX,ES:WORD PTR INT2F_LOW	   ; store original..		    ;AN000;
	   MOV	  CS:ROM_INT2F,AX		   ; interrupt 2Fh..		    ;AN000;
	   MOV	  CX,ES:WORD PTR INT2F_HI	   ; location.. 		    ;AN000;
	   MOV	  CS:ROM_INT2F+2,CX		   ;				    ;AN000;
	   OR	  AX,CX 			   ; check if old int2F..	    ;AN000;
	   JNZ	  LI_0				   ; is 0.			    ;AN000;
	   MOV	  AX,OFFSET ABORT		   ; yes....point to..		    ;AN000;
	   MOV	  CS:ROM_INT2F,AX		   ; IRET.			    ;AN000;
	   MOV	  AX,CS 			   ;				    ;AN000;
	   MOV	  CS:ROM_INT2F+2,AX		   ;				    ;AN000;
LI_0:						   ;				    ;AN000;
	   CLI					   ;				    ;AN000;
	   MOV	  ES:WORD PTR INT2F_LOW,OFFSET INT2F_COM ; replace vector..	    ;AN000;
	   MOV	  ES:WORD PTR INT2F_HI,CS	   ; with our own..		    ;AN000;
	   STI					   ;				    ;AN000;
	   POP	  AX				   ;				    ;AN000;
	   POP	  CX				   ;				    ;AN000;
	   POP	  ES				   ;				    ;AN000;
	   MOV	  CS:SEMAPHORE,1		   ; now loaded.		    ;AN000;
LI_1:	   RET					   ;				    ;AN000;
LOAD_INT2F ENDP

.XLIST
MSG_SERVICES <MSGDATA>			  ; WGR 				    ;AN000;
MSG_SERVICES <DISPLAYmsg,LOADmsg,CHARmsg> ; WGR 				    ;AN000;
MSG_SERVICES <PRINTER.CL1>		  ; WGR 				    ;AN000;
MSG_SERVICES <PRINTER.CL2>		  ; WGR 				    ;AN000;
MSG_SERVICES <PRINTER.CLA>		  ; WGR 				    ;AN000;
.LIST

include msgdcl.inc

CSEG	ENDS
	END
