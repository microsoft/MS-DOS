	PAGE	60,132;
	title	EDLIN Messages
;======================= START OF SPECIFICATIONS =========================
;
; MODULE NAME: EDLMES.SAL
;
; DESCRIPTIVE NAME: MESSAGE RETRIEVER INTERFACE MODULE
;
; FUNCTION: THIS MODULE PROVIDES AN INTERFACE FOR THE MODULES THAT ARE
;	    NEEDED TO INVOKE THE MESSAGE RETRIEVER.
;
; ENTRY POINT: PRINTF
;
; INPUT: OFFSET CARRIED IN DX TO APPLICABLE MESSAGE TABLE
;
; EXIT NORMAL: NO CARRY
;
; EXIT ERROR : CARRY
;
; INTERNAL REFERENCES:
;
;	ROUTINE: PRINTF - PROVIDES THE ORIGINAL INTERFACE FOR THE ORIGINAL
;			  PRINTF USED PRIOR TO VERSION 4.00.  PRINTS MESSAGES.
;
;		 DISP_MESSAGE - BUILDS THE REGISTERS NECESSARY FOR INVOCATION
;			  OF THE MESSAGE RETRIEVER, BASED ON THE TABLE
;			  POINTED TO BY DX.
;
;		 DISP_FATAL - INVOKED IF AN ERROR OCCURS (CARRY) IN THE
;			  MESSAGE RETRIEVER.  IT DISPLAYS THE APPROPRIATE
;			  MESSAGE.
;
; EXTERNAL REFERENCES:
;
;	ROUTINE: SYSLOADMSG - LOAD MESSAGES FOR THE MESSAGE RETRIEVER
;		 SYSDISPMSG - DISPLAYS THE REQUESTED MESSAGE
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS
;	 LINK EDLIN+EDLCMD1+EDLCMD2+EDLMES+EDLPARSE
;
; REVISION HISTORY:
;
;	AN000	VERSION DOS 4.00 - IMPLEMENTATION OF MESSAGE RETRIEVER
;
; COPYRIGHT: "MS DOS EDLIN UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988 Microsoft"
;	     "LICENSED MATERIAL - PROPERTY OF Microsoft  "
;
; MICROSOFT REVISION HISTORY
;
;	 MODIFIED BY: AARON R
;		      M.A. U
;		      N. P
;======================= END OF SPECIFICATIONS ===========================

.xlist

include sysmsg.inc				;an000;message retriever

msg_utilname <EDLIN>				;an000;EDLIN messages
.list
;-----------------------------------------------------------------------;
;									;
;	Done for Vers 2.00 (rev 9) by Aaron R				;
;	Update for rev. 11 by M.A. U					;
;	Printf for 2.5 by Nancy P					;
;									;
;-----------------------------------------------------------------------;

;=========================================================================
; revised edlmes.asm
;=========================================================================

fatal_error	equ	30			;an000;fatal message handler
unlim_width	equ	00h			;an000;unlimited output width
pad_blank	equ	20h			;an000;blank pad
pre_load	equ	00h			;an000;normal pre-load



message_table	struc				;an000;struc for message table

	entry1	dw	0			;an000;message number
	entry2	db	0			;an000;message type
	entry3	dw	0			;an000;display handle
	entry4	dw	0			;an000;pointer to sublist
	entry5	dw	0			;an000;substitution count
	entry6	db	0			;an000;use keyb input?
	entry7	dw	0			;an000;keyb buffer to use

message_table	ends				;an000;end struc

;=========================================================================
; macro disp_message: this macro takes a pointer to a message table
;		      and displays the applicable message based on
;		      the table's contents.
;		      this is to provide an interface into the module
;		      of the message retriever, SYSDISPMSG.
;
;	Date	  : 6/11/87
;=========================================================================

disp_message	macro	tbl			;an000;display message macro

	push	bx				;an000;
	push	cx				;an000;
	push	dx				;an000;
	push	di				;an000;
	push	si				;an000;

	push	tbl				;an000;exchange tbl with si
	pop	si				;an000;exchanged

	mov	ax,[si].entry1			;an000;move message number
	mov	bx,[si].entry3			;an000;display handle
	mov	cx,[si].entry5			;an000;number of subs
	mov	dl,[si].entry6			;an000;function type
	mov	di,[si].entry7			;an000;input buffer if appl.
	mov	dh,[si].entry2			;an000;message type
	mov	si,[si].entry4			;an000;sublist

	call	sysdispmsg			;an000;display the message

	pop	si				;an000;restore affected regs
	pop	di				;an000;
	pop	dx				;an000;
	pop	cx				;an000;
	pop	bx				;an000;

endm						;an000;end macro disp_message

;=========================================================================
; macro disp_message: end macro
;=========================================================================

CODE	SEGMENT PUBLIC BYTE
CODE	ENDS

CONST	SEGMENT PUBLIC BYTE
CONST	ENDS

cstack	segment stack
cstack	ends

DATA	SEGMENT PUBLIC BYTE

	extrn	path_name:byte

DATA	ENDS

DG	GROUP	CODE,CONST,cstack,DATA

code	segment public	byte			;an000;code segment
	assume cs:dg,ds:dg,es:dg,ss:CStack	;an000;

	public	printf				;an000;share printf
	public	disp_fatal			;an000;fatal error display
	public	pre_load_message		;an000;message loader

.xlist
msg_services <MSGDATA>				;an000;
.list

;======================= sysmsg.inc invocation ===========================
;
;	include sysmsg.inc - message retriever services
;
;
; options selected:
;		    NEARmsg
;		    DISPLAYmsg
;		    LOADmsg
;		    CHARmsg
;		    NUMmsg
;		    CLSAmsg
;		    CLSBmsg
;		    CLSCmsg
;
;=========================================================================

.xlist

 msg_services <LOADmsg> 			;an000;no version check
 msg_services <DISPLAYmsg,CHARmsg,NUMmsg,INPUTmsg>  ;an000;display messages
 msg_services <EDLIN.CLA,EDLIN.CLB,EDLIN.CLC>	;an000;message types
 msg_services <EDLIN.CL1,EDLIN.CL2>		;an000;message types
 msg_services <EDLIN.CTL>			;an000;

.list

;=========================================================================
; printf: printf is a replacement of the printf procedure used in DOS
;	  releases prior to 4.00.  printf invokes the macro disp_message
;	  to display a message through the new message handler.  the
;	  interface into printf will continue to be a pointer to a message
;	  passed in DX.  the pointer is pointing to more than a message
;	  now.	it is pointing to a table for that message containing
;	  all relevant information for printing the message.  the macro
;	  disp_message operates on these tables.
;
;	Date	  : 6/11/87
;=========================================================================

printf	proc	near				;an000;printf procedure

	disp_message	dx			;an000;display a message
;	$if	c				;an000;if an error occurred
	JNC $$IF1
		call	disp_fatal		;an000;display the fatal error
;	$endif					;an000;
$$IF1:

	ret					;an000;return to caller

printf	endp					;an000;end printf proc


;=========================================================================
; disp_fatal: this routine displays a fatal error message in the event
;	      an error occurred in disp_message.
;
;	Date	  : 6/11/87
;=========================================================================

disp_fatal proc near				;an000;fatal error message

	mov	ax,fatal_error			;an000;fatal_error number
	mov	bx,stdout			;an000;print to console
	mov	cx,0				;an000;no parameters
	mov	dl,no_input			;an000;no keyboard input
	mov	dh,UTILITY_MSG_CLASS		   ;an000;utility messages

	call	sysdispmsg			;an000;display fatal error

	ret					;an000;return to caller

disp_fatal endp 				;an000;end disp_fatal proc

;=========================================================================
; PRE_LOAD_MESSAGE : This routine provides access to the messages required
;		     by EDLIN.	This routine will report if the load was
;		     successful.  An unsuccessful load will cause EDLIN
;		     to terminate with an appropriate error message.
;
;	Date	  : 6/11/87
;=========================================================================

PRE_LOAD_MESSAGE	proc	near		;an000;pre-load messages


	call	SYSLOADMSG			;an000;invoke loader

;	$if	c				;an000;if an error
	JNC $$IF3
		pushf				;an000;save flags
		call	SYSDISPMSG		;an000;let him say why
		popf				;an000;restore flags
;	$endif					;an000;
$$IF3:

	ret					;an000;return to caller

PRE_LOAD_MESSAGE	endp			;an000;end proc

include msgdcl.inc

code	ends					;an000;end code segment




CONST	SEGMENT PUBLIC BYTE

	extrn	arg_buf:byte			;an000;
	extrn	line_num:byte			;an000;
	extrn	line_flag:byte			;an000;
	extrn	Temp_Path:byte			;an000;

	public	baddrv_ptr,bad_vers_err,opt_err_ptr,nobak_ptr
	public	too_many_ptr,dskful_ptr,memful_ptr,badcom_ptr
	public	nodir_ptr,filenm_ptr,newfil_ptr,read_err_ptr
	public	nosuch_ptr,toolng_ptr,eof_ptr,dest_ptr
	public	mrgerr_ptr,ro_err_ptr,bcreat_ptr,ndname_ptr
	public	ask_ptr,qmes_ptr,crlf_ptr,lf_ptr,yes_byte
	public	prompt_ptr
	public	line_num_buf_ptr		;an000;DMS:6/15/87
	public	arg_buf_ptr			;an000;DMS:6/15/87
	public	cont_ptr			;an000;DMS:6/18/87
	public	cp_err_ptr			;an000;DMS:6/22/87
	public	Del_Bak_Ptr			;an000;dms;

	yes_byte	db	"y"

;============== REPLACEABLE PARAMETER SUBLIST STRUCTURE ==================
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
;	     replaceable parameter sublists
;=========================================================================

ed_read_sub	label	dword			;an000;a read error occurred

	db	11				;an000;sublist size
	db	00				;an000;reserved
	dd	dg:path_name			   ;an000;pointer to parameter
	db	01				;an000;parm 1
	db	Char_Field_ASCIIZ		;an000;left align/asciiz/char.
	db	unlim_width			;an000;unlimited width
	db	00				;an000;minimum width of 0
	db	pad_blank			;an000;pad with blanks

arg_sub 	label	dword			;an000;line output buffer

	db	11				;an000;sublist size
	db	00				;an000;reserved
	dd	dg:arg_buf			   ;an000;pointer to parameter
	db	01				;an000;parm 1
	db	Char_Field_ASCIIZ		;an000;left align/asciiz/char.
	db	unlim_width			;an000;unlimited width
	db	00				;an000;minimum width of 0
	db	pad_blank			;an000;pad with blank

num_sub 	label	dword			;an000;line number

	db	11				;an000;sublist size
	db	00				;an000;reserved
	dd	dg:line_num			   ;an000;pointer to parameter
	db	01				;an000;parm 1
	db	Right_Align+Unsgn_Bin_Word	;an000;right align/decimal
	db	08				;an000;maximum width
	db	08				;an000;minimum width of 0
	db	pad_blank			;an000;pad with blank

	db	11				;an000;optional flag
	db	00				;an000;reserved
	dd	dg:line_flag			   ;an000;pointer to parameter
	db	02				;an000;parm 2
	db	Char_Field_Char 		;an000;character
	db	01				;an000;minimum width of 1
	db	01				;an000;maximum width of 1
	db	pad_blank			;an000;pad with blank

BAK_Sub 	label	dword			;an000;line output buffer

	db	11				;an000;sublist size
	db	00				;an000;reserved
	dd	dg:Temp_Path			;an000;pointer to parameter
	db	00				;an000;parm 0
	db	Char_Field_ASCIIZ		;an000;left align/asciiz/char.
	db	unlim_width			;an000;unlimited width
	db	00				;an000;minimum width of 0
	db	pad_blank			;an000;pad with blank


;=========================================================================
;	     end replaceable parameter sublists
;=========================================================================

;======================= TABLE STRUCTURE =================================
;
;	bute 1-2  :	message number of message to be displayed
;	byte 3	  :	message type to be used, i.e.;class 1, utility, etc.
;	byte 4-5  :	display handle, i.e.; console, printer, etc.
;	byte 6-7  :	pointer to substitution list, if any.
;	byte 8-9  :	number of replaceable parameters, if any.
;	byte 10   :	type of input from keyboard, if any.
;	byte 11-12:	pointer to buffer for keyboard input, if any.
;
;=========================================================================


bad_vers_err	label	word		;an000;"Incorrect DOS version"
		dw	0001		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

prompt_ptr	label	word		;an000;"*",0
		dw	0006		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer


baddrv_ptr	label	word		;an000;"Invalid drive or file name"
					;an000;,0d,0a,0
		dw	0007		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

ndname_ptr	label	word		;an000;"File name must be
					;an000;specified",0d,0a,0
		dw	0008		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

opt_err_ptr	label	word		;an000;"Invalid parameter",0d,0a,0
		dw	0010		;an000;message number
		db	Parse_Err_Class ;an000;utility message
		dw	StdErr		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

ro_err_ptr	label	word		;an000;"File is READ-ONLY",0d,0a,0
		dw	0010		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

bcreat_ptr	label	word		;an000;"File Creation Error",0d,0a,0
		dw	0011		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

too_many_ptr	label	word		;an000;"Too many files open",0d,0a,0
		dw	0012		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

read_err_ptr	label	word		;an000;"Read error in:",
					;an000;0d,0a,"%1",0d,0a,0
		dw	0013		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	dg:ed_read_sub	;an000;point to sublist
		dw	0001		;an000;1 sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer


nobak_ptr	label	word		;an000;"Cannot edit .BAK file
					;an000;--rename file",0d,0a,0
		dw	0014		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

nodir_ptr	label	word		;an000;"No room in directory
					;an000;for file",0d,0d,0
		dw	0015		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

dskful_ptr	label	word		;an000;"Disk full. Edits lost.",0d,0a,0
		dw	0016		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

memful_ptr	label	word		;an000;"Insufficient memory",0d,0a,0
		dw	0008		;an000;message number
		db	Ext_Err_Class	;an000;extended error
		dw	stderr		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

filenm_ptr	label	word		;an000;"File not found",0d,0a
		dw	0002		;an000;message number
		db	Ext_Err_Class	;an000;utility message
		dw	stderr		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

badcom_ptr	label	word		;an000;"Entry error",0d,0a,0
		dw	0018		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

newfil_ptr	label	word		;an000;"New file",0d,0a,0
		dw	0019		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

nosuch_ptr	label	word		;an000;"Not found",0d,0a,0
		dw	0020		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

ask_ptr 	label	word		;an000;"O.K.? ",0
		dw	0021		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	DOS_KEYB_INP	;an000;keyboard input - AX
		dw	00		;an000;no keyboard buffer

toolng_ptr	label	word		;an000;"Line too long",0d,0a,0
		dw	0022		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

eof_ptr 	label	word		;an000;"End of input file",0d,0a,0
		dw	0023		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

qmes_ptr	label	word		;an000;"Abort edit (Y/N)? ",0
		dw	0024		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	DOS_KEYB_INP	;an000;keyboard input - AX
		dw	00		;an000;no keyboard buffer

dest_ptr	label	word		;an000;"Must specify destination
					;an000;line number",0d,0a,0
		dw	0025		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

mrgerr_ptr	label	word		;an000;"Not enough room to
					;an000;merge the entire file",0d,0a,0
		dw	0026		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

crlf_ptr	label	word		;an000;0d,0a,0
		dw	0027		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

lf_ptr		label	word		;an000;0a,0
		dw	0028		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

cont_ptr	label	word		;an000;"Continue (Y/N)?"
		dw	0029		;an000;message number
		db	UTILITY_MSG_CLASS  ;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no sub
		db	DOS_KEYB_INP	;an000;keyboard input
		dw	00		;an000;no keyboard buffer

arg_buf_ptr	label	word		;an000;argument buffer for
					;      line output
		dw	0031		;an000;message number
		db	UTILITY_MSG_CLASS     ;an000;utility message
		dw	stdout		;an000;display handle
		dw	dg:arg_sub	;an000;argument sublist
		dw	01		;an000;1 sub
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

line_num_buf_ptr label	word		;an000;holds line numbers
		dw	0032		;an000;message number
		db	UTILITY_MSG_CLASS     ;an000;utility message
		dw	stdout		;an000;display handle
		dw	dg:num_sub	;an000;argument sublist
		dw	02		;an000;2 subs
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

cp_err_ptr	label	word		;an000;"Cannot merge - Code page
					;	mismatch",0d,0a
		dw	0033		;an000;message number
		db	UTILITY_MSG_CLASS	;an000;utility message
		dw	stdout		;an000;display handle
		dw	00		;an000;no sublist
		dw	00		;an000;no subs
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

del_bak_ptr	label	word		;an000;"Access Denied - xxxxxxxx.BAK"
		dw	0005		;an000;message number
		db	Ext_Err_Class	;an000;utility message
		dw	stderr		;an000;display handle
		dw	dg:BAK_Sub	;an000;no sublist
		dw	01		;an000;no subs
		db	no_input	;an000;no keyboard input
		dw	00		;an000;no keyboard buffer

CONST	ENDS
	END
