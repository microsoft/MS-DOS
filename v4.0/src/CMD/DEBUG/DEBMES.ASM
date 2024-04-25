PAGE	60,132				;
	TITLE	DEBMES.SAL - DEBUGGER MESSAGES PC DOS
	IF1
	    %OUT    COMPONENT=DEBUG, MODULE=DEBMES
	ENDIF

;******************* START OF SPECIFICATIONS *****************************
;
; MODULE NAME:DEBMES.SAL
;
; DESCRIPTIVE NAME: SUPPLIES APPLICABLE MESSAGES TO DEBUG.ASM
;
; FUNCTION: THIS ROUTINE PROVIDES A MEANS BY WHICH MESSAGES MAY BE
;	    OUTPUT FOR DEBUG.  THIS IS HANDLED THROUGH THE MESSAGE
;	    RETRIEVER FUNCTION SYSDISPMSG.  TO
;	    FACILITATE MIGRATION AWAY FROM THE PRINTF UTILITY
;	    THE INTERFACE FOR INVOKING MESSAGES HAS REMAINED THE SAME.
;	    THIS IS ACCOMPLISHED THROUGH THE USE OF MACROS AND TABLES.
;	    EACH MESSAGE HAS A TABLE OF VALUES REQUIRED BY THE MESSAGE
;	    RETRIEVER UTILITIES.  THE MACROS OPERATE ON THESE TABLES
;	    TO SUPPLY SYSDISPMSG WITH THE VALUES NECESSARY
;	    TO PRINT A MESSAGE.
;
; ENTRY POINT: PRINTF
;
; INPUT: PRINTF IS INVOKED AS IT HAS ALWAYS BEEN INVOKED.  DX MUST
;	 POINT TO THE OFFSET OF A MESSAGE TABLE.  THE TABLE POINTED TO
;	 BY DX CONTAINS ALL THE NECESSARY INFORMATION FOR THAT MESSAGE
;	 TO BE PRINTED.
;
; EXIT-NORMAL: NO CARRY
;
; EXIT-ERROR: CARRY SET - EITHER MESSAGE NOT FOUND OR UNABLE TO BE DISPLAYED
;
; INTERNAL REFERENCES:
;
;	ROUTINE:DISP_MESSAGE - THIS MACRO IS USED TO DIPLAY A MESSAGE
;			       VIA SYSDISPMSG.	IT TAKES AS INPUT A POINTER
;			       IN DX.  THIS POINTER POINTS TO A TABLE OF
;			       VALUES FOR THE REQUESTED MESSAGE.
;			       DISP_MESSAGE OBTAINS THE VALUES IT NEEDS TO
;			       TO INVOKE SYSDISPMSG FROM THIS TABLE.
;
; EXTERNAL REFERENCES:
;
;	ROUTINE: SYSMSG.INC  - THIS ROUTINE IS SUPPLIED TO INTERFACE THE
;			       MESSAGE RETRIEVER SERVICES.
;
; NOTES: THIS MODULE SHOULD BE PROCESSED WITH THE SALUT PRE-PROCESSOR
;	 WITH OPTIONS "PR".
;	 LINK DEBUG+DEBCOM1+DEBCOM2+DEBCOM3+DEBASM+DEBUASM+DEBERR+DEBCONST+
;	      DEBDATA+DEBMES
;
; REVISION HISTORY:
;
;	AN000	VERSION DOS 4.0 - MESSAGE RETRIEVER IMPLEMENTED.  DMS:6/17/87
;
;
; COPYRIGHT: "MS DOS DEBUG Utility"
;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Property of Microsoft  "
;
;******************** END OF SPECIFICATIONS ******************************
.xlist

	include sysmsg.inc		;an000;message retriever

.list

msg_utilname <DEBUG>			;an000;DEBUG messages

;=========================================================================
;revised debmes.asm
;=========================================================================

fatal_error	equ	45		;fatal message handler error
unlim_width	equ	00h		;unlimited output width
pad_blank	equ	20h		;blank pad
pre_load	equ	00h		;an000;normal pre-load
pad_zero	equ	30h		;an000;zero pad


FALSE	EQU	0
TRUE	EQU	NOT FALSE

;SYSVER 	 EQU FALSE		 ;if true, i/o direct to bios
	INCLUDE SYSVER.INC

;=========================================================================
; macro disp_message: the macro takes the message obtained in get_message
;		      and displays it to the applicable screen device.
;=========================================================================

disp_message macro tbl			;an000;display message macro

	push	si			;an000;save affected reg
	push	di			;an000;
	push	ax			;an000;
	push	bx			;an000;
	push	cx			;an000;
	push	dx			;an000;

	push	tbl			;an000;exchange tbl with si
	pop	si			;an000;

	mov	ax,[si] 		;an000;move message number to ax
	mov	bx,[si+3]		;an000;display handle
	mov	cx,[si+7]		;an000;number of subs
	mov	dl,[si+9]		;an000;function type
	mov	di,[si+10]		;an000;input buffer if appl.
	mov	dh,[si+2]		;an000;message type
	mov	si,[si+5]		;an000;sublist

	call	sysdispmsg		;an000;display the message

	pop	dx			;an000;restore affected reg
	pop	cx			;an000;
	pop	bx			;an000;
	pop	ax			;an000;
	pop	di			;an000;
	pop	si			;an000;


endm					;an000;end macro disp_message

;=========================================================================
; macro disp_message: end macro
;=========================================================================



CODE	SEGMENT PUBLIC BYTE
CODE	ENDS

CONST	SEGMENT PUBLIC BYTE
CONST	ENDS

CSTACK	SEGMENT STACK
CSTACK	ENDS

DATA	SEGMENT PUBLIC BYTE

DATA	ENDS

DG	GROUP	CODE,CONST,CSTACK,DATA


code	segment public byte		;an000;code segment
	assume	cs:dg,ds:dg,ss:dg,es:dg ;an000;

	public	printf			;an000;share printf
;;	public	disp_fatal		;an000;fatal error display
	public	pre_load_message	;an000;message pre load

.xlist

msg_services <MSGDATA>

.list

;=========================================================================
;	  include sysmsg.inc - message retriever services
;options selected:
;		   NEARmsg
;		   DISPLAYmsg
;		   LOADmsg
;		   INPUTmsg
;		   CHARmsg
;		   NUMmsg
;		   CLSAmsg
;		   CLSBmsg
;		   CLSCmsg
;		   CLSDmsg
;=========================================================================

.xlist

msg_services <LOADmsg>			;an000;load the messages
msg_services <DISPLAYmsg,CHARmsg,NUMmsg>;an000;get and display messages
msg_services <INPUTmsg> 		;an000;input from keyboard
msg_services <DEBUG.CLA,DEBUG.CLB>	;an000;message types
msg_services <DEBUG.CLC,DEBUG.CLD>	;an000;
msg_services <DEBUG.CL1,DEBUG.CL2>	;an000;

.list

;=========================================================================
; printf: printf is a replacement of the printf procedure used in DOS
;	  releases prior 4.00.	printf invokes the macros get_message and
;	  disp_message to invoke the new message handler.  the interface
;	  into printf will continue to be a pointer to a message passed
;	  in DX.  the pointer is pointing to more than a message now.  it
;	  is pointing to a table for that message containing all relevant
;	  information for retieving and printing the message.  the macros
;	  get_message and disp_message operate on these tables.
;=========================================================================

printf	proc	near			;an000;printf procedure

	disp_message dx 		;an000;display a message
;;	$if	c			;an000;if an error occurred
;;		call disp_fatal 	;an000;display the fatal error
;;	$endif				;an000;

	ret				;an000;return to caller

printf	endp				;an000;end printf


;=========================================================================
; disp_fatal: this routine displays a fatal error message in the event
;	      an error occurred in disp_message.
;=========================================================================

;;disp_fatal	  proc	  near		  ;an000;fatal error message
;;
;;	  mov	  ax,fatal_error	  ;an000;fatal_error number
;;	  mov	  bx,stdout		  ;an000;print to console
;;	  mov	  cx,0			  ;an000;no parameters
;;	  mov	  dl,no_input		  ;an000;no input will be coming
;;	  mov	  dh,UTILITY_MSG_CLASS	     ;an000;utility messages
;;	  call	  sysdispmsg		  ;an000;dispaly fatal error
;;	  ret				  ;an000;return to caller
;;
;;disp_fatal	  endp			  ;an000;end disp_fatal


;=========================================================================
; PRE_LOAD_MESSAGE : This routine provides access to the messages required
;		     by DEBUG.	This routine will report if the load was
;		     successful.  An unsuccessful load will cause DEBUG
;		     to terminate with an appropriate error message.
;
;	Date	  : 6/15/87
;=========================================================================

PRE_LOAD_MESSAGE	proc	near		;an000;pre-load messages

	call	SYSLOADMSG			;an000;invoke loader

;	$if	c				;an000;if an error
	JNC $$IF1
		pushf				;an000;save flags
		call	SYSDISPMSG		;an000;let him say why
		popf				;an000;restore flags
;	$endif					;an000;
$$IF1:

	ret					;an000;return to caller

PRE_LOAD_MESSAGE	endp			;an000;end proc

include msgdcl.inc

code	ends				;an000;end code segment


CONST	SEGMENT PUBLIC BYTE

	PUBLIC	ENDMES_PTR,CRLF_PTR,NAMBAD_PTR
	PUBLIC	NOTFND_PTR,NOROOM_PTR,BADVER
	PUBLIC	NOSPACE_PTR,DRVLET
	PUBLIC	ACCMES_PTR,PROMPT_PTR
	PUBLIC	TOOBIG_PTR,SYNERR_PTR,BACMES_PTR
	PUBLIC	HEXERR_PTR,HEXWRT_PTR,WRTMES_PTR,EXEBAD_PTR,EXEWRT_PTR
	PUBLIC	EXECEMES_PTR, PARITYMES_PTR, NONAMESPEC_PTR
	PUBLIC	dr1_ptr,dr2_ptr,dr3_ptr,dr4_ptr 	;ac000;new messages
	PUBLIC	CHANGE_FLAG_PTR,DF_ERROR,BF_ERROR,BR_ERROR,BP_ERROR
	PUBLIC	CONSTEND

;======================= TABLE STRUCTURE =================================
;
;	byte 1	-	message number of message to be displayed
;	byte 2	-	message type to be used, i.e.;class 1, utility, etc.
;	byte 3	-	display handle, i.e.; console, printer, etc.
;	byte 4	-	pointer to substitution list, if any.
;	byte 6	-	number of replaceable parameters, if any.
;	byte 7	-	type of input from keyboard, if any.
;	byte 8	-	pointer to buffer for keyboard input, if any.
;
;=========================================================================

	IF	SYSVER

	    PUBLIC  BADDEV_PTR,BADLSTMES_PTR


baddev_ptr  label   word		;an000;"Bad device name",0
	    dw	    0006		;an000;message number 6
	    db	    UTILITY_MSG_CLASS	   ;an000;utility message
	    dw	    stdout		;an000;display handle
	    dw	    00			;an000;sublist
	    dw	    00			;an000;no subs
	    db	    no_input		;an000;no keyboard input
	    dw	    00			;an000;no keyboard buffer

badlstmes_ptr label word		;an000;"Couldn't open list device
					;      PRN","Enter name of list
					;      device?"
	    dw	    0007		;an000;message number 7
	    db	    UTILITY_MSG_CLASS	   ;an000;utility message
	    dw	    stdout		;an000;display handle
	    dw	    00			;an000;sublist
	    dw	    00			;an000;no subs
	    db	    DOS_KEYB_INP	;an000;keyboard input
	    dw	    00			;an000;no keyboard buffer


	ENDIF

;================= REPLACEABLE PARAMETER SUBLIST STRUCTURE ===============
;
;	byte 1	-	substitution list size, always 11
;	byte 2	-	reserved for use by message handler
;	byte 3	-	pointer to parameter to be used as a substitution
;	byte 7	-	which parameter is this to replace, %1, %2, etc.
;	byte 8	-	determines how the parameter is to be output
;	byte 9	-	determines the maximum width of the parameter string
;	byte 10 -	determines the minimum width of the parameter string
;	byte 11 -	define what is to be used as a pad character
;
;=========================================================================


;=========================================================================
;		replaceable parameter sublists
;=========================================================================

db_synerr_sub label dword		;an000;synerr parameters
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:arg_buf		;an000;point to argument buffer
	db	01			;an000;parameter one
	db	left_align+Char_field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum width
	db	pad_blank		;an000;blank pad

db_change_sub label dword		;an000;synerr parameters
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:arg_buf		;an000;point to argument buffer
	db	01			;an000;parameter one
	db	left_align+Char_field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum width
	db	pad_blank		;an000;blank pad

db_drive_error label dword		;an000;drive error parameters
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:drvlet		;an000;point to drive letter
	db	01			;an000;parameter one
	db	left_align+Char_field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	01			;an000;1 byte
	db	01			;an000;1 byte
	db	pad_blank		;an000;blank pad



;=========================================================================
;		end replaceable parameter sublists
;=========================================================================


crlf_ptr label	word			;an000;13,10,0
	dw	0008			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


bacmes_ptr label word			;an000;32,8,0
	dw	0044			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


badver	label	word			;an000;"Incorrect DOS version"
	dw	0001			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

endmes_ptr label word			;an000;13,10,"Program terminated
					;	      normally",0
	dw	0009			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


nambad_ptr label word			;an000;"Invalid drive specification",0
	dw	0010			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


notfnd_ptr label word			;an000;"File not found",0
	dw	0002			;an000;message number
	db	Ext_Err_Class		;an000;extended error
	dw	stderr			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


noroom_ptr label word			;an000;"File creation error",0
	dw	0012			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


nospace_ptr label word			;an000;"Insufficient space on disk",0
	dw	0013			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


dr1_ptr label	word			;an000;"Disk error reading drive %1"
	dw	0014			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_drive_error	;an000;sublist
	dw	01			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


dr2_ptr label	word			;an000;"Disk error writing drive %1"
	dw	0015			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_drive_error	;an000;sublist
	dw	01			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


dr3_ptr label	word			;an000;"Write protect error reading
					;	drive %1"
	dw	0016			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_drive_error	;an000;sublist
	dw	01			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


dr4_ptr label	word			;an000;"Write protect error writing
					;	drive %1"
	dw	0017			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_drive_error	;an000;sublist
	dw	01			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


toobig_ptr label word			;an000;"Insufficient memory",0
	dw	0008			;an000;message number
	db	Ext_Err_Class		;an000;utility message
	dw	stderr			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

synerr_ptr label word			;an000;"%1^Error",0
	dw	0019			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_synerr_sub	;an000;sublist
	dw	01			;an000;1 sub - leading spaces
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


hexerr_ptr label word			;an000;"Error in EXE or HEX file",0
	dw	0020			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

exebad_ptr label word			;an000;"Error in EXE or HEX file",0
	dw	0020			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


hexwrt_ptr label word			;an000;"EXE and HEX files cannot be
					;	written",0
	dw	0021			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

exewrt_ptr label word			;an000;"EXE and HEX files cannot be
					;	written",0
	dw	0021			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


execemes_ptr label word 		;an000;"EXEC failure",0
	dw	0022			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


nonamespec_ptr label word		;an000;"(W)rite error, no destination
					;	defined",0
	dw	0023			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

accmes_ptr label word			;an000;Access denied",0
	dw	0024			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


paritymes_ptr label word		;an000;"Parity error or nonexistant
					;	memory error detected",0
	dw	0025			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


prompt_ptr label word			;an000;"-",0
	dw	0026			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


change_flag_ptr label word		;an000;"%1 -",0
	dw	0027			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_change_sub	;an000;sublist
	dw	01			;an000;no subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

df_error	db	"df",0
bf_error	db	"bf",0
br_error	db	"br",0
bp_error	db	"bp",0
drvlet		db	"A",0

CONSTEND LABEL	BYTE

CONST	ENDS

DATA	SEGMENT PUBLIC BYTE

	PUBLIC	HEX_ARG1,HEX_ARG2,HEX_PTR,ARG_BUF
	PUBLIC	ARG_BUF_PTR,ADD_PTR,ERR_TYPE
	PUBLIC	CRLF_PTR,ADD_ARG,SUB_ARG,PROMPT_PTR
	PUBLIC	REGISTER_PTR,REG_NAME,REG_CONTENTS
	PUBLIC	SINGLE_REG_PTR,SINGLE_REG_ARG
	PUBLIC	ERRMES_PTR,LOC_PTR,LOC_ADD
	PUBLIC	LITTLE_PTR,BIG_PTR,LITTLE_CONTENTS
	PUBLIC	BIG_CONTENTS,COMP_PTR,COMP_ARG1,COMP_ARG2
	PUBLIC	COMP_ARG3,COMP_ARG4,COMP_ARG5,COMP_ARG6
	PUBLIC	WRTMES_PTR,WRT_ARG1,WRT_ARG2
	PUBLIC	IOTYP,MESTYP
	PUBLIC	ONE_CHAR_BUF,ONE_CHAR_BUF_PTR
	PUBLIC	OPBUF,UNASSEM_LN_PTR

	PUBLIC	xm_han_ret_ptr
	PUBLIC	xm_mapped_ptr
	PUBLIC	xm_err80_ptr
	PUBLIC	xm_err83_ptr
	PUBLIC	xm_err84_ptr
	PUBLIC	xm_err85_ptr
	PUBLIC	xm_err86_ptr
	PUBLIC	xm_err87_ptr
	PUBLIC	xm_err88_ptr
	PUBLIC	xm_err89_ptr
	PUBLIC	xm_err8a_ptr
	PUBLIC	xm_err8b_ptr
	PUBLIC	xm_err8d_ptr
	PUBLIC	xm_err8e_ptr
	PUBLIC	xm_err_gen_ptr
	PUBLIC	xm_parse_err_ptr
	PUBLIC	xm_status_ptr
	PUBLIC	xm_page_seg_ptr
	PUBLIC	xm_deall_ptr
	PUBLIC	xm_errff_ptr
	PUBLIC	xm_unall_ptr
	PUBLIC	xm_han_alloc_ptr

	EXTRN	XM_HANDLE_RET:word
	EXTRN	XM_LOG:byte
	EXTRN	XM_PHY:byte
	EXTRN	XM_PAGE_CNT:word
	EXTRN	XM_FRAME:word
	EXTRN	XM_DEALL_HAN:word
	EXTRN	XM_ALLOC_PG:word
	EXTRN	XM_TOTAL_PG:word
	EXTRN	XM_HAN_ALLOC:word
	EXTRN	XM_HAN_TOTAL:word

;=========================================================================
;		    begin parameter sublists
;=========================================================================

;======================= unassemble parameter sublists ===================

db_unassem_sb1 label dword		;an000;unassemble parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:arg_buf		;an000;point to argument buffer
	db	01			;an000;parameter one
	db	left_align+Char_field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum width
	db	pad_blank		;an000;blank pad

db_unassem_sb2 label dword		;an000;unassemble parameter 2
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:opbuf		;an000;point to argument buffer
	db	02			;an000;parameter two
	db	left_align+Char_field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum width
	db	pad_blank		;an000;blank pad


;================== hex argument parameter sublists ======================

db_hexarg_sb1 label dword		;an000;hex argument parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:hex_arg1		;an000;point to argument buffer
	db	01			;an000;parameter one
	db	right_align+bin_hex_word
					;an000;right align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

db_hexarg_sb2 label dword		;an000;hex argument parameter 2
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:hex_arg2		;an000;point to argument buffer
	db	02			;an000;parameter two
	db	right_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

db_hexarg_sb3 label dword		;an000;hex argument parameter 3
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:arg_buf		;an000;point to argument buffer
	db	03			;an000;parameter one
	db	left_align+Char_field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum width
	db	pad_blank		;an000;blank pad


;================== hex add parameter sublists ===========================

db_hexadd_sb1 label dword		;an000;hex add parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:add_arg		;an000;point to add_arg
	db	01			;an000;parameter one
	db	right_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

db_hexadd_sb2 label dword		;an000;hex argument parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:sub_arg		;an000;point to sub_arg
	db	02			;an000;parameter two
	db	right_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;================== end hex add parameter sublists =======================

;================== single register parameter sublists ===================
;string: "%1 %2",13,10,":",0

db_singrg_sb1 label dword		;an000;single register parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:arg_buf		;an000;point to argument buffer
	db	01			;an000;parameter one
	db	left_align+Char_field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

db_singrg_sb2 label dword		;an000;single register parameter 2
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:single_reg_arg	;an000;point single_reg_arg
	db	02			;an000;parameter two
	db	right_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;================== register parameter sublists ==========================
;string: "%1=%2  ",0

db_regist_sb1 label dword		;an000;register parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:reg_name		;an000;point to reg_name
	db	01			;an000;parameter one
	db	left_align+Char_field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	02			;an000;unlimited width
	db	02			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

db_regist_sb2 label dword		;an000;register parameter 2
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:reg_contents 	;an000;point to reg_contents
	db	02			;an000;parameter two
	db	right_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;================== error message parameter sublists =====================
;string: "%1 Error",0

db_error_sb1 label dword		;an000;error message parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:err_type		;an000;point to argument buffer
	db	01			;an000;parameter one
	db	left_align+Char_field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

;================== writing message parameter sublists ===================
;string: "Writing %1%2 bytes",0

db_wrtmes_sb1 label dword		;an000;wrtmes parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:wrt_arg1		;an000;point to argument buffer
	db	01			;an000;parameter one
	db	right_align+bin_hex_word
					;an000;right align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

db_wrtmes_sb2 label dword		;an000;wrtmes parameter 2
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:wrt_arg2		;an000;point to argument buffer
	db	02			;an000;parameter two
	db	left_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;================== loc address parameter sublists =======================
;string: "%1:%2=",0

db_locadd_sb1 label dword		;an000;loc address parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:arg_buf		;an000;point to argument buffer
	db	01			;an000;parameter one
	db	right_align+Char_field_ASCIIZ
					;an000;left align/ASCIZZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

db_locadd_sb2 label dword		;an000;loc address parameter 2
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:loc_add		;an000;point to loc_add
	db	02			;an000;parameter two
	db	right_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;================== little contents parameter sublists ===================
;string "%1",0

db_little_sb1 label dword		;an000;one byte output parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:little_contents	;an000;point to little_contents
	db	01			;an000;parameter one
	db	right_align+bin_hex_byte
					;an000;left align/byte/hexadecimal
	db	02			;an000;maximum of 2 bytes
	db	02			;an000;minimum of 2 bytes
	db	pad_zero		;an000;blank pad

;================== big argument parameter sublists ======================
;string: "%1",0

db_big_sb1 label dword			;an000;word argument parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:big_contents 	;an000;point to big_contents
	db	01			;an000;parameter one
	db	right_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;======================= comp argument parameter sublists ================
;string "%1:%2  %3  %4  %5:%6",0

db_comp_sb1 label dword 		;an000;comp argument parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:comp_arg1		;an000;point to comp_arg1
	db	01			;an000;parameter one
	db	right_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

db_comp_sb2 label dword 		;an000;comp argument parameter 2
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:comp_arg2		;an000;point to comp_arg2
	db	02			;an000;parameter two
	db	right_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

db_comp_sb3 label dword 		;an000;comp argument parameter 3
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:comp_arg3		;an000;point to comp_arg3
	db	03			;an000;parameter three
	db	right_align+bin_hex_byte
					;an000;left align/byte/hexadecimal
	db	02			;an000;maximum of 2 bytes
	db	02			;an000;minimum of 2 bytes
	db	pad_zero		;an000;blank pad

db_comp_sb4 label dword 		;an000;comp argument parameter 4
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:comp_arg4		;an000;point to comp_arg4
	db	04			;an000;parameter four
	db	right_align+bin_hex_byte
					;an000;left align/byte/hexadecimal
	db	02			;an000;maximum of 2 bytes
	db	02			;an000;minimum of 2 bytes
	db	pad_zero		;an000;blank pad

db_comp_sb5 label dword 		;an000;comp argument parameter 5
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:comp_arg5		;an000;point to comp_arg5
	db	05			;an000;parameter five
	db	right_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

db_comp_sb6 label dword 		;an000;comp argument parameter 6
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:comp_arg6		;an000;
	db	06			;an000;parameter 6
	db	right_align+bin_hex_word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;======================= disk error parameter sublists ===================
;string: "%1 error %2 drive %3",0

db_disk_sb1 label dword 		;an000;disk argument parameter 1
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:mestyp		;an000;point to mestyp
	db	01			;an000;parameter one
	db	left_align+Char_field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

db_disk_sb2 label dword 		;an000;disk argument parameter 2
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:iotyp		;an000;point to iotyp
	db	02			;an000;parameter two
	db	left_align+Char_field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

db_disk_sb3 label dword 		;an000;disk argument parameter 3
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:drive		;an000;point to drive
	db	03			;an000;parameter three
	db	left_align+char_field_char
					;an000;left align/character/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

arg_buf_sb1 label dword 		;an000;argument sublist
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:arg_buf		;an000;point to argument buffer
	db	01			;an000;parameter one
	db	left_align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

one_char_sb1 label dword		;an000;character buffer sublist
	db	Sublist_Length		;an000;sublist size
	db	reserved		;an000;reserved
	dd	dg:one_char_buf 	;an000;point to argument buffer
	db	01			;an000;parameter one
	db	left_align+Char_Field_Char
					;an000;left align/character/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

xm_han_sub	label	dword		;an000;sublist for handles
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_HANDLE_RET	;an000;parameter 1
	db	01			;an000;parameter 1
	db	right_align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	30h			;an000;pad with zeros

xm_map_sub	label	dword		;an000;sublist for mappings
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_LOG		;an000;parameter 1
	db	01			;an000;parameter 1
	db	right_align+Bin_Hex_Byte;an000;
	db	02			;an000;maximum width
	db	02			;an000;minimum width
	db	30h			;an000;pad with zeros

	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_PHY		;an000;parameter 2
	db	02			;an000;parameter 2
	db	right_align+Bin_Hex_Byte;an000;
	db	02			;an000;maximum width
	db	02			;an000;minimum width
	db	30h			;an000;pad with zeros

xm_sta_sub	label	word		;an000;sublist for status
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_HANDLE_RET	;an000;parameter 1
	db	01			;an000;parameter 1
	db	right_align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	30h			;an000;pad with zeros

	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_PAGE_CNT		;an000;parameter 2
	db	02			;an000;parameter 2
	db	right_align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	30h			;an000;pad with zeros

xm_page_seg_sub label	word		;an000;sublist for frame seg status
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_PHY		;an000;parameter 1
	db	01			;an000;parameter 1
	db	right_align+Bin_Hex_Byte;an000;
	db	02			;an000;maximum width
	db	02			;an000;minimum width
	db	30h			;an000;pad with zeros

	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_FRAME		;an000;parameter 2
	db	02			;an000;parameter 2
	db	right_align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	30h			;an000;pad with zeros

xm_deall_sub	label	word		;an000;sublist for handle deallocation
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_DEALL_HAN 	;an000;parameter 1
	db	01			;an000;parameter 1
	db	right_align+Bin_Hex_Byte;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	30h			;an000;pad with zeros

xm_unall_sub	label	word		;an000;sublist unallocated page report
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_ALLOC_PG		;an000;parameter 1
	db	01			;an000;parameter 1
	db	right_align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	20h			;an000;pad with blanks

	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_TOTAL_PG		;an000;parameter 1
	db	02			;an000;parameter 1
	db	right_align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	20h			;an000;pad with zeros


xm_han_alloc_sub label	 word		 ;an000;sublist unallocated page report
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_HAN_ALLOC 	;an000;parameter 1
	db	01			;an000;parameter 1
	db	right_align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	20h			;an000;pad with blanks

	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dd	dg:XM_HAN_TOTAL 	;an000;parameter 1
	db	02			;an000;parameter 1
	db	right_align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	20h			;an000;pad with zeros
;=========================================================================
;		    end parameter sublists
;=========================================================================


unassem_ln_ptr label word		;an000;"%1%2",0
	dw	0032			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_unassem_sb1	;an000;sublist
	dw	02			;an000;2 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


hex_ptr label	word			;an000;"%1:%2 %3",0
	dw	0033			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_hexarg_sb1	;an000;sublist
	dw	03			;an000;3 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


add_ptr label	word			;an000;"%1  %2",0
	dw	0034			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_hexadd_sb1	;an000;sublist
	dw	02			;an000;2 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer



single_reg_ptr label word		;an000;"%1 %2",13,10,":",0
	dw	0035			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_singrg_sb1	;an000;sublist
	dw	02			;an000;2 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer



register_ptr label word 		;an000;"%1=%2  ",0 ex: AX=FFFF
	dw	0036			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_regist_sb1	;an000;sublist
	dw	02			;an000;2 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


errmes_ptr label word			;an000;"%1 Error",0
	dw	0037			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_error_sb1 	;an000;sublist
	dw	01			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


wrtmes_ptr label word			;an000;"Writing %1 bytes",0
	dw	0038			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_wrtmes_sb1	;an000;sublist
	dw	01			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


loc_ptr label	word			;an000:"%1;%2=",0 ex:CX:0000
	dw	0039			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_locadd_sb1	;an000;sublist
	dw	02			;an000;2 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


little_ptr label word			;an000;"%1",0 ex:FF
	dw	0040			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_little_sb1	;an000;sublist
	dw	01			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


big_ptr label	word			;an000;"%1",0
	dw	0041			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_big_sb1		;an000;sublist
	dw	01			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


comp_ptr label	word			;an000;"%1:%2  %3  %4  %5:%6",0
	dw	0042			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	stdout			;an000;display handle
	dw	dg:db_comp_sb1		;an000;sublist
	dw	06			;an000;6 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


arg_buf_ptr label	word		;an000;"%1"
	dw	0046			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	dg:arg_buf_sb1		;an000;sublist
	dw	01			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


one_char_buf_ptr label	word		;an000;"%1"
	dw	0047			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	dg:one_char_sb1 	;an000;sublist
	dw	01			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_unall_ptr	label	word		;an000;unallocated message report
	dw	0050			;an000;"%1 of a total %2 EMS pages
					;      have been allocated",cr,lf
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	dg:XM_UNALL_SUB 	;an000;sublist
	dw	02			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_han_alloc_ptr label	 word		;an000;unallocated message report
	dw	0051			;an000;"%1 of a total %2 EMS handles
					;      have been allocated",cr,lf
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	dg:XM_HAN_ALLOC_SUB	;an000;sublist
	dw	02			;an000;2 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_han_ret_ptr	label	word		;an000;prints handle created
	dw	0055			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	dg:XM_HAN_SUB		;an000;sublist
	dw	01			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_mapped_ptr	label	word		;an000;prints log/phy pages
	dw	0056			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	dg:XM_MAP_SUB		;an000;sublist
	dw	02			;an000;2 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err80_ptr	label	word		;an000;ems error message
	dw	0057			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err83_ptr	label	word		;an000;ems error message
	dw	0058			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err84_ptr	label	word		;an000;ems error message
	dw	0059			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err85_ptr	label	word		;an000;ems error message
	dw	0060			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err86_ptr	label	word		;an000;ems error message
	dw	0061			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err87_ptr	label	word		;an000;ems error message
	dw	0062			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err88_ptr	label	word		;an000;ems error message
	dw	0063			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err89_ptr	label	word		;an000;ems error message
	dw	0064			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err8a_ptr	label	word		;an000;ems error message
	dw	0065			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err8b_ptr	label	word		;an000;ems error message
	dw	0066			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err8d_ptr	label	word		;an000;ems error message
	dw	0067			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err8e_ptr	label	word		;an000;ems error message
	dw	0068			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_err_gen_ptr	label	word		;an000;ems error message
	dw	0070			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_parse_err_ptr label	word		;an000;input error message
	dw	0071			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_status_ptr	label	word		;an000;prints status of EMS
	dw	0072			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	dg:XM_STA_SUB		;an000;sublist
	dw	02			;an000;2 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_page_seg_ptr label	word		;an000;"Physical page %1 = Frame
					;	segment %2"
	dw	0075			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	dg:XM_PAGE_SEG_SUB	;an000;sublist
	dw	02			;an000;2 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_deall_ptr	label	word		;an000;"Handle %1 deallocated"

	dw	0076			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	dg:XM_DEALL_SUB 	;an000;sublist
	dw	01			;an000;1 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

xm_errff_ptr	    label word		;an000;"EMS not installed"

	dw	0078			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	stdout			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;0 subs
	db	no_input		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

arg_buf 	db   80 dup (?) 	;an000;argument buffer
one_char_buf	db   ?			;an000;character buffer

opbuf	db	51h dup (?)

hex_arg1 dw	?
hex_arg2 dw	?

add_arg dw	?
sub_arg dw	?

single_reg_arg dw ?

reg_name dw	?
reg_contents dw ?

err_type db	3	dup(0)		;ac000;changed to hold bf,bp,etc.

wrt_arg1 dw	?
wrt_arg2 dw	?

loc_add dw	?

little_contents dw ?
big_contents dw ?

comp_arg1 dw	?
comp_arg2 dw	?
comp_arg3 dw	?
comp_arg4 dw	?
comp_arg5 dw	?
comp_arg6 dw	?

mestyp	dw	?
iotyp	dw	?
drive	db	?


DATA	ENDS
	END
