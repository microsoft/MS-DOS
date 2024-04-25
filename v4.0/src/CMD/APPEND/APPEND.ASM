page	60,120
;
.sall
title	APPEND
include sysmsg.inc
msg_utilname<APPEND>
;-----------------------------------------------------------------------------
;
;      Title:	       APPEND
;
;      Author:	       G. G. A. 		     Network version
;		       B. A. F.`		     DOS changes
;
;      Syntax:	       From the DOS command line:
;
;		       APPEND [d:]path[[;[d:]path]...]
;			     - Used to specify the directories to be
;			       searched after the working directory.
;
;		       APPEND ;
;			     - Used to release all appended directories.
;
;		       APPEND
;			     - Used to show appended directories.
;
;		       First time only:
;
;		       APPEND  [[d:]path |  | /X | /E | /X /E]
;			     - [d:]path Normal support and Set path
;			     -		Normal support
;			     - /X	Extended support, SEARCH, FIND and EXEC
;			     - /E	Use DOS Environment for path(s)
;
;      Revision History:
;      @@01 07/11/86 Fix hang in TopView start			    PTM P00000??
;      @@02 07/28/86 Fix APPEND size problem			    PTM P0000045
;      @@03 07/29/86 Fix APPEND status with /E problem		    PTM P00000??
;      @@04 07/30/86 Fix second APPEND hang			    PTM P0000053
;      @@05 08/13/86 Fix parameter error			    PTM P0000125
;      @@06 08/20/86 Fix APPEND xxx fails in TopView		    PTM P0000217
;      @@07 08/21/86 Resurrect APPEND version message		    PTM P0000252
;      @@08 08/21/86 APPEND=path first time hangs		    PTM P0000254
;      @@09 08/22/86 APPEND gets wrong path under nested COMMAND    PTM P0000276
;      @@10 08/28/86 Change message for @@05			    PTM P0000291
;      @@11 09/10/86 Support message profile and make
;		     msg length variable.	R.G.		    PTM P0000479
;      @@12 09/25/86 Allow second external append call. (RG)	    PTM P0000515
;      @@13 09/30/86 APPEND gets wrong path under nested COMMAND    PTM P0000600
;		     Again. Fix in COMMAND now, so remove @@09 changes
;      @@14 10/01/86 Lower case drive in path files		    PTM P0000600
;      @@15 10/06/86 Include "," and "=" in skip leading of
;		     argument area parsing.			    PTM P0000677
;      @@16 10/06/86 Fix not using full APPEND path		    PTM P0000794
;      @@17 12/03/86 When searching for "APPEND=" string in
;		     environment, make sure delimiter precedes.(RG) PTM P0000893
;
;-------------------------------------------------------------------
;
;      AN000	     3.30 changes, GGA 6/87 new code.			P000
;      AN001	     Support DRIVE and PATH modes			D043
;      AN002	     Add truename function				P1276
;      AN003	     Add extended handle open function			D250
;      AN005
;      AN006	     Add DBCS support
;      AN007	     Release Environmental Vector space 		P2666
;      AN008	     Allow equal symbol with append - APPEND=A:/1;	P2901
;      AN009	     Release Environmental Vector on only the		P3333
;		     first invocation of APPEND
;      AN010	     display invalid parm from command line		P3908
;
;
;-----------------------------------------------------------------------------
;Date	       Rev     Comments
;-----------------------------------------------------------------------------
;06-02-86      0.0     Begin conversion to PC/DOS version
;06-20-86      0.0     End conversion to PC/DOS version
;
page

cseg		segment public para 'CODE'
		assume	cs:cseg
		assume	ds:nothing,es:nothing

;-----------------------------------------------------------------------------
;	Equates
;-----------------------------------------------------------------------------

.xlist
;include fsi.lib
NETSYSUTIL   EQU  0C2H			; SYSTEM UTILITIES
NETENQ	     EQU  07H			; ENQ RESOURCE
NETDEQ	     EQU  08H			; DEQ RESOURCE
;include task.lib
TCBR_APPEND	EQU	   001H 	; APPEND ACTIVE
;include DOS.lib
DOSSERVER    EQU  5DH			; SERVER OPERATION
DOSSETERROR  EQU  0AH			; SET EXTENDED ERROR
;include server.lib
DPL		STRUC
DPL_AX		DW	0		;AX REG
DPL_BX		DW	0		;BX REG
DPL_CX		DW	0		;CX REG
DPL_DX		DW	0		;DX REG
DPL_SI		DW	0		;SI REG
DPL_DI		DW	0		;DI REG
DPL_DS		DW	0		;DS REG
DPL_ES		DW	0		;ES REG
DPL_XID 	DW	0		;RESERVED
DPL_UID 	DW	0		;SERVER USER ID
DPL_PID 	DW	0		;REDIRECTOR PROCESS ID
DPL		ENDS
include sysmac.lib
include versiona.inc
include appendp.inc			; parseing stuff for append			 ;AN004;
.list
;		extrn	end_address:near	; end of stay resident stuff

;		extrn	bad_append_msg:byte	; messages
;		extrn	path_error_msg:byte
;		extrn	parm_error_msg:byte
;		extrn	path_parm_error_msg:byte
;		extrn	no_append_msg:byte		; @@05
;		extrn	append_assign_msg:byte
;		extrn	append_TV_msg:byte		; @@01
;		extrn	bad_DOS_msg:byte
;		extrn	second_APPEND_msg:byte		; @@04

;		extrn	len_bad_append_msg:word 	;@@11
;		extrn	len_path_error_msg:word 	;@@11
;		extrn	len_parm_error_msg:word 	;@@11
;		extrn	len_path_parm_error_msg:word	;@@11
;		extrn	len_no_append_msg:word		;@@11
;		extrn	len_append_assign_msg:word	;@@11
;		extrn	len_append_TV_msg:word		;@@11
;		extrn	len_bad_DOS_msg:word		;@@11
;		extrn	len_second_APPEND_msg:word	;@@11

;	Environmental Vector

PSP_Env 	equ	2ch		;Environmental vector segment in PSP	;an007; dms;

;	Interrupts

DOS_function	equ	21h		; DOS function call interrupt
int_function	equ	2fh		; DOS internal function interrupt, used
					; to verify APPEND presence
termpgm 	equ	20h						; @@05
resident	equ	27h

;	Function calls

get_vector	equ	3521h		; DOS function call to get INT 21 vector
set_vector	equ	2521h		; DOS function call to set INT 21 vector
get_intfcn	equ	352fh		; DOS function call to get INT 2f vector
set_intfcn	equ	252fh		; DOS function call to set INT 2f vector
get_version	equ	30h		; DOS function call to get DOS version number
get_DTA 	equ	2fh		; DOS function get DTA
set_DTA 	equ	1ah		; DOS function set DTA
get_crit_err	equ	3524h		; DOS function call to get INT 24 vector
set_crit_err	equ	2524h		; DOS function call to set INT 24 vector
get_PSP 	equ	62h		; DOS function call to get PSP address
Free_Alloc_Mem	equ	49h		; DOS function call to free alloc. mem. ;an007; dms;

print_string	equ	09h		; DOS function call to get print a string
ctrl_break	equ	33h		; DOS function call to get/set ctrl-break

awrite		equ	40h		; write function
get_dir 	equ	47h		; get current dir
change_dir	equ	3bh		; change dir
get_disk	equ	19h		; get current disk
change_disk	equ	0eh		; change disk
term_stay	equ	31h		; terminate a process and stay resident
term_proc	equ	4ch		; terminate a process

redir_flag	equ	0000000000001000B ; redir flag for net installation check

;	DOS INT 2f function for APPEND presence

append_2f	equ	0b7h		; int 2f function code for append
applic_2f	equ	0aeh		; int 2f function code for applications
COMMAND_2f	equ	-1		; int 2f subfunction code for COMMAND call
append_inst	equ	0ffh		; flag means append is there

;	INT 2f sub-function codes						;AN000;

are_you_there	equ	0		; function code for presence check
old_dir_ptr	equ	1		; means APPEND 1.0 is trying to run
get_app_version equ	2		; fun code for get ver request
tv_vector	equ	3		; fun code for set TV vector
dir_ptr 	equ	4		; function code to return dirlist ptr
get_state	equ	6		; function code to return append ;AN001;
					; state 			 ;AN001;
set_state	equ	7		; function code to set append	 ;AN001;
					; state 			 ;AN001;

DOS_version	equ	10h		; function call to get DOS version
true_name	equ	11h		; one-shot truename fcn for ASCIIZ ops ;AN002;

;	DOS INT 21 function calls that APPEND traps

FCB_opn 	equ	0fh
file_sz 	equ	23h
handle_opn	equ	3dh
dat_tim 	equ	57h
FCB_sch1	equ	11h
handle_fnd1	equ	4eh
exec_proc	equ	4bh
ext_handle_opn	equ	6ch								  ;AN003;

break	macro			; this is a dummy break macro so PDB.INC
	endm			; won't blow up in the build

;	define some things for PDB (PSP)						  ;AN002;
											  ;AN002;
include pdb.inc 									  ;AN002;
											  ;AN002;
true_name_flag		equ	01h	; flag for true name function			  ;AN002;
eo_create		equ	00f0h	; mask to check extended opens for create	  ;AN003;

;	Error codes that don't mean stop looking

FCB_failed		equ	0ffh	; FCB open failed
FCB_file_not_found	equ	2	; file not found on FCB open
handle_file_not_found	equ	2	; file not found on handle open
handle_path_not_found	equ	3	; path not found on handle open
FCB_no_more_files	equ	18	; no more matching files
handle_no_more_files	equ	18	; no more matching files

;	Equates for TOPVIEW barrier
TV_TRUE equ	-1			; this was changed from TRUE	 ;AN000;
					; because 3.30 parser uses TRUE  ;AN000;
false	equ	0			;

;	Message equates

tab_char equ	9
cr	equ	13
lf	equ	10
beep	equ	7
STDOUT	equ	0001h			; standard output file
STDERR	equ	0002h			; standard error file
null	equ	0

page

;-----------------------------------------------------------------------------
;	Resident data area
;-----------------------------------------------------------------------------

version_loc:				; version number
	db	major_version,minor_version
;	 dw	 message_list		 ; pointer to message table

		even
vector_offset	dw	0		; save pointer to old int 21 here
vector_segment	dw	0
crit_vector_offset  dw	0		; save pointer to old int 24 here
crit_vector_segment dw	0
intfcn_offset	dw	0		; save pointer to old int 2f here
intfcn_segment	dw	0
dirlst_offset	dw	0		; save pointer to dir list here
dirlst_segment	dw	0
tv_vec_off	dw	0		; save TV vector here
tv_vec_seg	dw	0

pars_off	dd	cseg: SysParse	; save pointer to parser here
;pars_off	 dw	 offset SysParse ; save pointer to parser here
;pars_seg	 dw	 0

app_dirs_seg	dw	0		; save ES here during FCB

FCB_ptr 	dd	0		; save pointer to FCB here
handle_ptr	dd	0		; save pointer to ASCIIZ string here

stack_offset	dw	0
stack_segment	dw	0		; Calling process stack

incoming_AX	dw	0		; AX saved at entry to interrupt handler
incoming_CX	dw	0		; CX saved at entry to interrupt handler
; must be together
incoming_BX	dw	0		; BX saved at entry to interrupt handler
incoming_ES	dw	0		; ES saved at entry to interrupt handler
; must be together
ax_after_21	dw	0		; AX saved after call to real INT 21
; temp_DS_save	  dw	  0		  ; DS saved during stack ops
temp_CS_save	dw	0		; CS saved during stack ops (set_return_flags)
temp_IP_save	dw	0		; IP saved during stack ops (set_return_flags)
FCB_drive_id	db	0		; save the drive id for FCB opens here

;------------------------
;	DBCS stuff here 								 ;AN006;
											 ;AN006;
DBCSEV_OFF	DW	0		; OFFSET OF DBCS EV				 ;AN006;
DBCSEV_SEG	DW	0		; SEGMENT OF DBCS EV				 ;AN006;
											 ;AN006;
;DEFAULT DBCS ENVIRONMENTAL VECTOR							 ;AN006;
EVEV	DB	00H,00H 								 ;AN006;
	DB	00H,00H 								 ;AN006;
	DB	00H,00H 								 ;AN006;
											 ;AN006;
dbcs_fb 	dw	0		; offset of DBCS first byte chars found
;------------------------

initial_pass	dw	0		; flag used to indicate inital APPEND		 ;AN007;

incoming_DX	dw	0		; used for saves for extended open		  ;AN003;
incoming_SI	dw	0		; used for saves for extended open		  ;AN003;
incoming_DI	dw	0		; used for saves for extended open		  ;AN003;
incoming_DS	dw	0		; used for saves for extended open		  ;AN003;
true_name_count dw	0		; used to save number of chars in true_name dir   ;AN003;

int_save_ip	dw	0		; save registers here during critical
int_save_cs	dw	0		; error handler stack ops

work_disk	db	"?:\"		; user's working disk
work_dir	db	64 dup(" ")	; user's working dir
app_disk	db	"?:\"		; user's working disk
app_dir 	db	64 dup(" ")	; user's append disk's working dir
ctrl_break_state db	0		; save the old ctrl-break state here

end_search	db	0		; end search flag
try_dir 	db	128 dup (0)	; try this dir
fname		db	15 dup (0)	; 8.3 filename stripped from original
					; ASCIIZ string
app_dirs_ptr	dw	0		; pointer to appended dir to try

set_name	db	"SET     "	; SET command
; must be together
setappend_name	db	"SET "		; SET command
append_id	db	"APPEND="	; display from here for user
; must be together
app_dirs	db	";"
		db	128 dup (0)	; area for storing appended dirs
		db	0		; just to insure that the last dir is null terminated
semicolon	db	";",0		; null list

;	Flags / barriers added for TopView

tv_flag 	db	0		; flag to indicate re-entr from TopView

parse_flag	db	0		; flag used by APPEND parsing

FCB_ext_err	db	0		; flag used to indicate that FCB
					; open failed and ext err was done
crit_err_flag	db	0		; flag used to indicate that a critical
					; error happened
ext_err_flag	db	0		; flag used to indicate that ext err
					; must be set 0 = don't set, 1 = do set
in_middle	db	0		; flag used to tell if we made it to
					; middle of string before finding a space
equal_found	db	0		; multiple = check
;crit_sect_flag  db	 0		 ; critical section flag

stack_area	dw	99 dup(0)	; stack area for append
append_stack	dw	0

net_config	dw	0		; flag word for what (if any) network
					; config we are running under
					; as long as this word is zero, a clear determination
					; has not been made about the configuration

		even
ext_err_dpl	DPL	<>		; reserve a DPL for get/set extended error code


save_ext_err	DPL	<>		; reserve a DPL for first extended
					; error code

;-------------------------------------------------------------------	 ;AN001;
;									 ;AN001;
;	mode_flags	This status word is used to control the various  ;AN001;
;			APPEND functions and modes.			 ;AN001;
;									 ;AN001;
;-------------------------------------------------------------------	 ;AN001;
mode_flags	dw	Path_mode + Drive_mode + Enabled		 ;AN001;
					; mode control flags		 ;AN001;
					; initially - path, drive and	 ;AN001;
					; enabled			 ;AN001;

;	equates for mode_flags follow:					 ;AN001;

X_mode		equ	8000h		; in /X mode
E_mode		equ	4000h		; in /E mode
Path_mode	equ	2000h		; PATH in string OK		 ;AN001;
Drive_mode	equ	1000h		; DRIVE in string OK		 ;AN001;
Enabled 	equ	0001h		; APPEND enabled		 ;AN001;

;-------------------------------------------------------------------

cmd_name@	dd	?		; internal name string

expected_error	dw	?		; error to do append scan
expected_ext_error dw	?		; error to do append scan

cmd_env 	dw	?		; pointer to COMMANDs environment
cmd_buf 	dw	?		; CMDBUF offset (in SS)

incoming_DTA	dd	?		; user's DTA (on EXEC)
exec_DTA	db	21+1+2+2+2+2+13 dup(0)	; find DTA for exec emulation

old_syntax	db	0		; using network syntax

res_append	db	0		; resident append call		  ; @@05

abort_sp	dw	?		; sp to restore on errors	  ; @@05

crlf	label	byte
	db	CR,LF
crlf_len equ	 $ - crlf

;*******************************************************************		;an010;bgb
; parser message display area							;an010;bgb
;*******************************************************************		;an010;bgb
inv_parm    db	0bh	;length 						;an010;bgb
	    db	0	;reserved						;an010;bgb
si_off	    dw	0	;put offset of command line here			;an010;bgb
si_seg	    dw	0	;put segment of command line here			;an010;bgb
	    db	0	;use percent zero					;an010;bgb
	    db	Left_Align+Char_Field_ASCIIZ ;type of data			;an010;bgb
	    db	128			;max width				;an010;bgb
	    db	1			;min width				;an010;bgb
	    db	' '			;pad char				;an010;bgb

;-------------------------------------------------------------------
;
;	resident message area
;
;-------------------------------------------------------------------

MSG_SERVICES <MSGDATA>
MSG_SERVICES <DISPLAYmsg,CHARmsg>						;an010;bgb
MSG_SERVICES <APPEND.CLA,APPEND.CL1,APPEND.CTL>

.xlist
;-----------------------------------------------------------------------------
;	macros
;-----------------------------------------------------------------------------

;-----------------------------
;	save and restore register macros
save_regs macro
	push	bx
	push	cx
	push	dx

	push	di
	push	si
	push	ds
	push	es
	endm

restore_regs macro
	pop	es
	pop	ds
	pop	si
	pop	di

	pop	dx
	pop	cx
	pop	bx
	endm

;-----------------------------
;	this macro is used instead of the normal POPF instruction to help
;	prevent a 286 bug from occurring
popff	macro
	local	myret
	jmp	$+3
myret	label	near
	iret
	push	cs
	call	myret
	endm

;-----------------------------						  ; @@12
;	check character 						  ; @@12
;									  ; @@12
chkchar macro	char							  ; @@12
	lodsb								  ; @@12
	and	al,0dfh 						  ; @@12
	cmp	al,char 						  ; @@12
	jne	ccn_ret 						  ; @@12
	endm								  ; @@12
.list

page
;-----------------------------------------------------------------------------
;	resident routine - control transferred here on INT 21
;	check to see if this call has a function code we are interested in
;-----------------------------------------------------------------------------


tv_entry:
	pushf								  ; @@01
	jmp	check_fcb_open						  ; @@01

interrupt_hook:
resident_routine:
	pushf				; save the user's flags (old stack)

	cmp	tv_flag,TV_TRUE 	; see if in TV			 ;AN000;
	je	use_old 		; yes, old_vect

check_fcb_open: 							  ; @@01

;-------------------------------------------------------------------	 ;AN001;
;	first, check to see if APPEND disabled, if so, skip everything	 ;AN001;
;	and go to real INT 21 handler					 ;AN001;
;-------------------------------------------------------------------	 ;AN001;
	test	mode_flags,Enabled	; APPEND disabled?		 ;AN001;
	jz	real_jump		; yes, skip all other checks	 ;AN001;

	cmp	ah,FCB_opn		; FCB open?
	jump	E,FCB_open		; yes, do the APPEND

	cmp	ah,handle_opn		; handle open?
	jump	E,handle_open		; yes, do the APPEND

	cmp	ah,ext_handle_opn	; extended handle open? 			  ;AN003;
	jump	E,ext_handle_open	; yes, do the APPEND				  ;AN003;
											  ;AN003;
	cmp	ah,file_sz		; file size?
	jump	E,FCB_open		; yes, do the APPEND


	test	mode_flags,X_mode	; /X mode not selected
	jz	real_jump

	cmp	ah,FCB_sch1		; search?
	jump	E,FCB_search1		; yes, do the APPEND

	cmp	ah,handle_fnd1		; find?
	jump	E,handle_find1		; yes, do the APPEND

	cmp	tv_flag,TV_TRUE 	; cant do in TopView		 ;AN000;
	je	skip_exec
	cmp	ax,exec_proc*256+0	; EXEC?
	jump	E,exec_pgm		; yes, do the APPEND
skip_exec:
	cmp	ax,exec_proc*256+3	; EXEC?
	jump	E,exec_pgm		; yes, do the APPEND

	page
;-----------------------------------------------------------------------------
;	By here, we know that the call was not one we are interested in,
;	pass through to old INT 21.
;	Since this is done with a jmp, control will pass back to original caller
;	after DOS is finished.
;-----------------------------------------------------------------------------

real_jump:
	cmp	tv_flag,TV_TRUE 	; see if called by TV		 ;AN000;
	jne	use_old 		; yes, use old vect

	popff				; restore user's flags
	jmp	dword ptr tv_vec_off	; pass through to TV

use_old:
	popff				; restore user's flags (old stack)
	jmp	dword ptr Vector_Offset ; jump to old INT 21

page
;-----------------------------------------------------------------------------
;	FCB_search1 - this routine handles FCB search first calls
;-----------------------------------------------------------------------------

FCB_search1:
	mov	expected_ext_error,fcb_no_more_files
	jmp	short FCB_openx1

;-----------------------------------------------------------------------------
;	FCB_open - this routine handles FCB open calls
;-----------------------------------------------------------------------------

FCB_open:
	mov	expected_ext_error,fcb_file_not_found
FCB_openx1:
	call	check_config		; check the config flags
	call	crit_sect_set		; set critical section flag

	call	tv_barrier

	mov	incoming_AX,ax		; save user's AX
	mov	word ptr FCB_ptr+0,dx	; save FCB pointer
	mov	word ptr FCB_ptr+2,ds

	popff				; restore user's flags
	call	int_21			; try the open

	cli
	mov	AX_after_21,ax		; save AX as it came back from INT
	pushf				; save flags from operation
	cmp	al,FCB_failed		; open failed ?
	je	check_error		; yes, lets check extended error
	jmp	set_return_flags	; no, fix the stack, then ret to caller

check_error:
	call	get_ext_err_code	; get the extended error code
	mov	FCB_ext_err,1		; set FCB ext error
	call	save_first_ext_err	; save first extended error code
	mov	ax,ext_err_dpl.DPL_AX	; get error in ax
	cmp	ax,expected_ext_error	; file not found?
	je	FCB_openx2		; yes, lets look around for file
	lea	dx,save_ext_err 	;
	call	set_ext_err_code	; set the extended error code
	jmp	set_return_flags	; no, fix the stack, then return

FCB_openx2:

;	set up APPEND's stack

	popff				; get rid of the flags from the
					; real operation
;	mov	temp_DS_save,ds 	; Save DS reg
	mov	stack_segment,ss	; Save it
	mov	stack_offset,sp 	; Save it
	mov	ax,cs			; Get current segment
	mov	ss,ax			; and point stack seg here
	lea	sp,append_stack 	; set up new stack

	save_regs			; save registers

	push	cs			; establish addressability
	pop	ds

	call	ctrl_break_set		; set ctrl-break handler
	call	crit_err_set		; set crit err handler

	mov	ext_err_flag,1		; flag for setting critical error

;	fix FCB drive spec

	les	bx,dword ptr FCB_ptr	; ES:BX points to FCB
	mov	ah,ES:byte ptr [bx]	; get FCB drive spec
	cmp	ah,-1			; extended FCB?
	jne	not_ext_FCB1
	add	bx,1+5+1		; point to real drive letter
	mov	ah,ES:byte ptr [bx]	; get FCB drive spec

not_ext_FCB1:
	mov	FCB_drive_id,ah 	; save it for later
	mov	ES:byte ptr [bx],0	; zero the drive field out to
					; use default drive

	mov	ah,get_disk		; get disk
	call	int_21			; call DOS INT 21 handler

	add	al,"A"			; make it a character
	mov	work_disk,al		; save it

	mov	ah,get_dir		; get directory
	xor	dx,dx			; default drive
	lea	si,work_dir		; save area
	call	int_21			; call DOS INT 21 handler

	call	address_path		; get address of path
	cmp	es: byte ptr [di],";"	; is the append list null?
	jump	E,null_list		; exit append
	mov	app_dirs_seg,es 	; save app dirs segment
	mov	si,di			; source

try_another1:
	lea	di,try_dir		; destination
	call	get_app_dir		; copy dir to try into try_dir
	mov	app_dirs_ptr,si 	; save updated pointer


;-----------------------------
try_app_dir1:
	mov	app_disk,0		; zero for current dir
	cmp	try_dir+1,":"		; see if we have a drive
	jne	no_drive		; char should be a colon

;	yes, there was a drive specified, must do the change disk function call

	mov	ah,change_disk		; change disk
	mov	dl,try_dir		; get the char representation of the drive
	mov	app_disk,dl		; save it away for later use
	call	cap_dl
	sub	dl,"A"			; convert from char to drive spec
	call	int_21			; call DOS INT 21 handler
;	jc	check_end_dir_list	; there was an error, see if there is
					; another to try

	cmp	crit_err_flag,0 	; did we experience a critical error
	jne	set_err_code		; yes, fake a file_not_found

no_drive:
	mov	ah,get_dir		; get directory
	xor	dx,dx			; default drive
	lea	si,app_dir		; save area
	call	int_21			; call DOS INT 21 handler

;	check to see if there was a critical error

	cmp	crit_err_flag,0 	; did we experience a critical error
	je	cd_worked		; no, the cd worked
	jmp	short set_err_code

save_regs_and_set:
	pushf				; save everything again
	save_regs
	push	cs			; re-establish addressability
	pop	ds			; ds = cs

set_err_code:
	xor	ah,ah			; make ax look like open failed
	mov	al,FCB_failed
	mov	ax_after_21,ax		; save it away so we can restore it below

	jmp	no_more_to_try

cd_worked:
	lea	dx,try_dir		; point dx to dir to try
	mov	ah,change_dir		; change dir to appended directory
	call	int_21			; call DOS INT 21 handler

;	try the open in this dir

	restore_regs			; make regs look like when user
	mov	ax,incoming_AX		; called us

	call	int_21			; call DOS INT 21 handler
	mov	ax_after_21,ax		; save AX
	cmp	crit_err_flag,0 	; did we get critical error?
	jne	save_regs_and_set	; yes, fake a file_not_found
	cmp	al,FCB_failed	   ; did open work?
	jne	open_ok
	call	get_ext_err_code	; get the extended error code

open_ok:
	pushf				; save everything again
	save_regs

	push	cs			; re-establish addressability
	pop	ds			; ds = cs

;	restore user's working disk and restore the dir on the appended drive

	mov	ah,change_disk		; change disk back to our original
	mov	dl,work_disk
	call	cap_dl
	sub	dl,"A"			; convert from char to drive spec
	call	int_21			; call DOS INT 21 handler

	mov	ah,change_dir		; change dir
	lea	dx,app_disk		; save area (this time include drive)
	call	int_21			; call DOS INT 21 handler

;	this is for ..\dirname ptr

	mov	ah,change_dir		; change dir
	lea	dx,work_disk		; save area (this time include drive)
	call	int_21			; call DOS INT 21 handler

	mov	ax,ax_after_21		; restore AX
	cmp	al,FCB_failed		; did open work?
	jne	FCB_open_worked
	mov	ax,ext_err_dpl.DPL_AX
	cmp	ax,expected_ext_error
	jne	no_more_to_try		; not file not found

check_end_dir_list:
	mov	es,app_dirs_seg 	; restore es
	mov	si,app_dirs_ptr
	cmp	si,null 		; should we try again?
	je	no_more_to_try		; no
	jmp	try_another1		; yes

FCB_open_worked:
	mov	byte ptr ext_err_flag,0 ; the open worked, no need to set ext err code
	jmp	short set_disk

no_more_to_try:
;	restore user's working disk and dir

;	The following code up to label "null_list" which
;	restores the user's drive and path was moved in front
;	of the code to restore the drive spec in FCB.
;
	mov	ah,change_disk		; change disk
	mov	dl,work_disk
	call	cap_dl
	sub	dl,"A"			; convert from char to drive spec
	call	int_21			; call DOS INT 21 handler

	mov	ah,change_dir		; change dir
	lea	dx,work_disk		; save area (this time include drive)
	call	int_21			; call DOS INT 21 handler

null_list:
	mov	ah,FCB_drive_id 	; get FCB drive spec
;	cmp	ah,0			; did they ask for default drive?
;	je	fix_drive_spec		; yes, leave it alone
	jmp	short fix_drive_spec

set_disk:				; set drive number in FCB
	mov	ah,work_disk		; no, give them the found drive spec
	sub	ah,"A"-1		; convert from char to drive spec

;	ah has proper drive spec to put into FCB, do it

fix_drive_spec:
	les	bx,dword ptr FCB_ptr	; ES:BX points to FCB
	cmp	ES:byte ptr[bx],-1	; extended FCB
	jne	not_ext_FCB2		; put in the proper drive spec
	add	bx,1+5+1		; point to real drive letter

not_ext_FCB2:
	mov	ES:byte ptr [bx],ah


	call	ctrl_break_restore
	call	crit_err_restore

;	find out if there is a need to set the extended error code

	cmp	ext_err_flag,0		; do we need to set the extended error code?
	je	no_ext_err		; no, finish up
	lea	dx,ext_err_dpl
	cmp	FCB_ext_err,0
	je	handle_ext_err
	lea	dx,save_ext_err

handle_ext_err:
	call	set_ext_err_code	; yes, go set the ext error info

;	all done with append, clean things back up for the user

no_ext_err:
	restore_regs			; restore registers

	jmp	reset_stack		; fix stack, ret to caller
page

;-----------------------------------------------------------------------------
;	handle_find - APPEND handle find function
;-----------------------------------------------------------------------------

handle_find1:
	mov	incoming_CX,cx		; save user's CX
	mov	expected_error,handle_no_more_files
;	mov	expected_ext_error,handle_no_more_files
	jmp	short handle_openx

;-----------------------------------------------------------------------------
;	exec_pgm - APPEND exec program function
;-----------------------------------------------------------------------------

exec_pgm:
	mov	incoming_BX,bx		; save user's ES:BX
	mov	incoming_ES,es
	mov	expected_error,handle_file_not_found
;	mov	expected_ext_error,handle_no_more_files
	jmp	short handle_openx

;-----------------------------------------------------------------------------		  ;AN003;
;	ext_handle_open - APPEND extended handle open function					       ;AN003;
;-----------------------------------------------------------------------------		  ;AN003;
ext_handle_open:									  ;AN003;
	test	dx,eo_create		; does this call specify create?		  ;AN003;
	jz	no_eo_create		; no, we can continue				  ;AN003;
											  ;AN003;
	jmp	real_jump		; yes, do nothing but pass on to real		  ;AN003;
					; INT 21 handler				  ;AN003;
											  ;AN003;
;	getting here means the caller did not specify the create option 		  ;AN003;
											  ;AN003;
no_eo_create:										  ;AN003;
											  ;AN003;
	mov	incoming_BX,bx		; save user's registers                           ;AN003;
	mov	incoming_CX,cx		; extended open sure does use a lot		  ;AN003;
	mov	incoming_DX,dx		; of registers					  ;AN003;
	mov	incoming_SI,si								  ;AN003;
	mov	incoming_DI,di								  ;AN003;
	mov	incoming_ES,es								  ;AN003;
	mov	incoming_DS,ds								  ;AN003;
											  ;AN003;
	mov	expected_error,handle_file_not_found					  ;AN003;
	jmp	short handle_openx	; for now ...					  ;AN003;
											  ;AN003;
;-----------------------------------------------------------------------------
;	handle_open - APPEND handle open function
;-----------------------------------------------------------------------------

handle_open:
	mov	expected_error,handle_file_not_found
;	mov	expected_ext_error,handle_file_not_found

handle_openx:
	call	check_config		; check the config flags
	call	crit_sect_set		; set critical section flag

	call	tv_barrier		; no op on exec

	mov	incoming_AX,ax		; save user's AX
	mov	word ptr handle_ptr+0,dx	 ; save path pointer
	mov	word ptr handle_ptr+2,ds

	popff				; restore user's flags
	call	int_21			; try the open

	cli
	mov	AX_after_21,ax		; save AX as it came back from INT
	pushf				; save flags from operation

;	find out if we had an error, and if so was it the one we were
;	looking for

	jc	what_happened		; yes, lets find out what happened
	mov	incoming_AX,-1		; insure no exec done later
	jmp	set_return_flags	; no, fix the stack, then ret to caller
					; this means that the real call worked,
					; APPEND does not need to do anything

what_happened:
;	cmp	ax,handle_path_not_found  ; normal errors
;	je	handle_search		; yes, look for the file
	cmp	ax,expected_error	; was the error file not found?
	je	handle_search		; yes, look for the file
	jmp	set_return_flags	; no, fix the stack, then ret to caller


handle_search:
	call	get_ext_err_code	; get the extended error code information

;	set up APPEND's stack
	popff				; get rid of the flags from the
					; real operation
;	mov	temp_DS_save,ds 	; Save DS reg
	mov	stack_segment,ss	; Save it
	mov	stack_offset,sp 	; Save it
	mov	ax,cs			; Get current segment
	mov	ss,ax			; and point stack seg here
	lea	sp,append_stack 	; set up new stack

	save_regs			; save registers
	pushf				;
	push	cs			; establish addressability
	pop	ds

	call	crit_err_set

	call	ctrl_break_set

;	all done with the prep stuff, let's get down to business

;-------------------------------------------------------------------	 ;AN001;
;									 ;AN001;
;	before doing anything else, check DRIVE and PATH modes		 ;AN001;
;									 ;AN001;
;-------------------------------------------------------------------	 ;AN001;
;									 ;AN001;

	pushf				; save flags			 ;AN001;
	push	ax			; save AX			 ;AN001;
									 ;AN001;
	cmp	incoming_AX,exec_proc*256 ; is this call an exec?
	je	drive_and_path_ok


;-------------------------------------------------------------------
;	Set up ES:SI to point to incoming string
;-------------------------------------------------------------------

	cmp	incoming_AX,ext_handle_opn*256+0 ;is this call an ext open?		  ;AN003;
	jne	no_eo13 								  ;AN003;
	mov	si,incoming_SI		; DS:SI points to original name for ex open	  ;AN003;
	mov	es,incoming_DS		; but this code wants ES:SI to point to it	 ;AN003;
	lea	di,fname		; DS:DI points to fname area			  ;AN003;
	jmp	eo_skip3		; skip the old stuff				  ;AN003;
											  ;AN003;
no_eo13:										   ;AN003;
	les	si,dword ptr handle_ptr ; ES:SI points to original handle
	lea	di,fname		; DS:DI points to fname area
eo_skip3:
;-------------------------------------------------------------------

	test	mode_flags,Drive_mode	; Drive_mode enabled?
	jnz	check_path_mode 	; yes, go check path mode

	call	check_for_drive 	; no, find out if there is a drive
					; specified
	cmp	ax,0			; was there a drive letter?
	je	check_path_mode 	; no, go check path mode

;-------------------------------------------------------------------
;	getting here means that Drive_mode is disabled and that a drive letter
;	was found.  This means we give up on this APPEND operation

	jmp	drive_or_path_conflict


check_path_mode:
	test	mode_flags,Path_mode	; Path_mode enabled?
	jnz	drive_and_path_ok	; yes, go do the APPEND function

	call	check_for_path		; no, find out if there is a path
					; specified

	cmp	ax,0			; was there a path?
	jne	drive_or_path_conflict	; no, go do the APPEND function


	call	check_for_drive 	; no, find out if there is a drive
					; specified
	cmp	ax,0			; was there a drive letter?
	je	drive_and_path_ok	; no, everything is OK
					; yes, fall through and exit w/error

;-------------------------------------------------------------------	 ;AN001;
;	getting here means that Drive_mode is disabled and that a drive  ;AN001;
;	letter was found.  This means we give up on this APPEND operatio ;AN001; n

drive_or_path_conflict:

	pop	ax			; clean up stack
	popff

;	restore_regs			; restore some regs				  ;AN002;
;	pop	ax

	mov	ext_err_flag,1		; we need to set extended error info
	mov	ax,expected_error	; make ax look like we got file not found
	mov	ax_after_21,ax		; save it away so we can restore it below
	popff				; get flags from stack
	stc				; set the carry flag
	pushf				; put 'em back

	jmp	no_more_to_try2


drive_and_path_ok:							 ;AN001;
	pop	ax			; restore AX			 ;AN001;
	popff				; restore flags 		 ;AN001;
									 ;AN001;
;-------------------------------------------------------------------	 ;AN001;
;	end of code to check DRIVE and PATH modes			 ;AN001;
;-------------------------------------------------------------------	 ;AN001;

	cmp	incoming_AX,ext_handle_opn*256+0 ;is this call an ext open?		  ;AN003;
	jne	no_eo1									  ;AN003;
	mov	si,incoming_SI		; DS:SI points to original name for ex open	  ;AN003;
	mov	es,incoming_DS		; but this code wants ES:SI to point to it	 ;AN003;
	lea	di,fname		; DS:DI points to fname area			  ;AN003;
	jmp	eo_skip1		; skip the old stuff				  ;AN003;
											  ;AN003;
no_eo1: 										  ;AN003;
	les	si,dword ptr handle_ptr ; ES:SI points to original handle
	lea	di,fname		; DS:DI points to fname area
eo_skip1:										  ;AN003;
	call	get_fname		; strip just the 8.3 filename from
					; the original ASCIIZ string
	call	address_path		; address the path
	cmp	es: byte ptr [di],";"	; is append list null ?
	jump	E,no_more_to_try2	; exit append
	popff				;
	mov	si,di			; pointer to list of appended directories
	pushf				; push flags onto stack just for the
					; popff below

try_another2:
	popff
	lea	di,try_dir		; buffer to be filled with dir name
					; to try
	push	cx			; save CX
	call	get_app_dir		; this routine will return with a dir
					; to try in try_dir
	mov	true_name_count,cx	; save number of chars for later us		  ;AN003;
	pop	cx
	mov	app_dirs_ptr,si 	; save updated pointer


;-----------------------------
try_app_dir2:

	call	append_fname		; glue the filename onto the end of the dir to try


;	we now have an ASCIIZ string that includes the original 8.3 filename
;	and one of the appended dir paths

	mov	ax,incoming_AX
	mov	cx,incoming_CX
	lea	dx,try_dir		; point to new ASCIIZ string

	cmp	incoming_AX,ext_handle_opn*256+0     ; extended open?			  ;AN003;
	jne	not_eo1 								  ;AN003;
											  ;AN003;
;	this is an extended open call							  ;AN003;
											  ;AN003;
	save_regs									  ;AN003;
											  ;AN003;
	mov	si,dx			; ext open wants DS:SI -> filename		  ;AN003;
	push	cs									  ;AN003;
	pop	ds									  ;AN003;
											  ;AN003;
	mov	ax,incoming_AX		; function code 				  ;AN003;
	mov	bx,incoming_BX		; mode word					  ;AN003;
	mov	cx,incoming_CX		; attributes					  ;AN003;
	mov	dx,incoming_DX		; flags 					  ;AN003;
	mov	es,incoming_ES		; ES:DI parm_list pointer			  ;AN003;
	mov	di,incoming_DI								  ;AN003;
											  ;AN003;
	call	int_21			; try the extended open 			  ;AN003;
											  ;AN003;
	restore_regs									  ;AN003;
	pushf				; save flags					  ;AN003;
;	mov	es,incoming_ES		; restore es as it was				  ;AN003;
	jmp	not_exec2		; go find out what happened			  ;AN003;
											  ;AN003;
											  ;AN003;
not_eo1:										  ;AN003;
	cmp	incoming_AX,exec_proc*256+0	; exec pgm call
	jne	not_exec1

;	this is an exec call								  ;AN003;

	push	es
	push	bx
	mov	ah,get_DTA
	call	int_21
	mov	word ptr incoming_DTA+0,bx	; save callers DTA
	mov	word ptr incoming_DTA+2,es
	pop	bx
	pop	es
	push	ds
	push	dx
	mov	ah,set_DTA
	lea	dx,exec_DTA		; set for fake exec search
	push	cs
	pop	ds
	call	int_21
	pop	dx
	pop	ds
	mov	ah,handle_fnd1		; precess search by finds
	mov	expected_error,handle_no_more_files

not_exec1:

	push	es			; save append's ES
	push	bx			; save append's BX
	mov	es,incoming_ES		; must restore ES before doing the call ; fix for P37, GGA 9/10/87
	mov	bx,incoming_BX		; must resatore user's ES:BX

	call	int_21			; try the open

	pop	bx			; restore append's BX
	pop	es			; restore append's es
	pushf				; save flags
	cmp	incoming_AX,exec_proc*256+0	; exec pgm call
	jne	not_exec2
	push	ds
	push	dx
	push	ax
	mov	ah,set_DTA
	mov	dx,word ptr incoming_DTA+0	; restore callers DTA
	mov	ds,word ptr incoming_DTA+2
	call	int_21
	pop	ax
	pop	dx
	pop	ds
not_exec2:
	popff
	pushf
	jnc	found_it_remote 	; all done

	cmp	crit_err_flag,0 	; process critical errors
	jne	check_crit_err

	cmp	ax,handle_path_not_found  ; normal errors
	je	should_we_look_more

	cmp	ax,expected_error	; was the error we found file not found?
	je	should_we_look_more	; yes, look some more
	jmp	no_more_to_try2 	; no, any other error, we pack it in

should_we_look_more:
	mov	si,app_dirs_ptr 	; yes, see if we should look more
	cmp	si,null 		; should we try again?
	je	no_more_to_tryx
	jmp	try_another2		; yes
no_more_to_tryx:
	jmp	no_more_to_try2

check_crit_err:
	mov	ext_err_flag,1		; we need to set extended error info
	mov	ax,expected_error	; make ax look like we got file not found
	mov	ax_after_21,ax		; save it away so we can restore it below
	popff				; get clags from stack
	stc				; set the carry flag
	pushf				; put 'em back

	jmp	no_more_to_try2

found_it_remote:			; come here only if the file was found in
					; an appended directory
	mov	ax_after_21,ax		; save AX


;											  ;AN002;
;	Find out if this process has the true_name flag set in thier PSP.		  ;AN002;
;	At this point, DS:DX points to the true name of the found file			  ;AN002;
;											  ;AN002;
											  ;AN002;
	push	ax			; save some regs				  ;AN002;
	save_regs
											  ;AN002;
	mov	ah,get_PSP		; function code for get PSP operation		  ;AN002;
	call	int_21			; get the PSP, segment returned in BX		  ;AN002;
	mov	es,bx			; need to use it as a segment			  ;AN002;
	mov	di,PDB_Append		; get pointer to APPEND flag in PDB		  ;AN002;
											  ;AN002;
	mov	ax,es:[di]		; get APPEND flag into AX			  ;AN002;
	test	ax,true_name_flag	; is true name flag armed?			  ;AN002;
	jz	no_true_name		; no, don't copy true name                        ;AN002;
											  ;AN002;
	sub	ax,true_name_flag	; clear true name flag				  ;AN002;
	mov	es:[di],ax		; save it in PSP				  ;AN002;
											  ;AN002;
	mov	di,word ptr handle_ptr+0	; get user's buffer pointer ES:DI         ;AN002;
	mov	es,word ptr handle_ptr+2						  ;AN002;

;	find out if this is a handle find or an open or an exec

	cmp	incoming_AX,exec_proc*256+0   ; exec?
	je	no_true_name		; yes, do nothing with true name
											  ;AN002;
	cmp	incoming_AX,handle_fnd1*256+0	; handle find?
	jne	not_hf			; no, go do the easy stuff
											  ;AN002;
;	function we are doing is a handle find, must get part of true_name
;	string from append path, part from DTA.  Messy!

	lea	si,try_dir		; buffer that has last APPEND path tried

	mov	cx,true_name_count	; get number of chars in true_name dir		  ;AN002;

copy_true_name_loop2:
	mov	ah,ds:[si]		; get byte of append dir path			  ;AN002;
	mov	es:[di],ah		; copy it to user's buffer                        ;AN002;
	inc	si			; in this loop, the null is not copied		  ;AN002;
	inc	di									  ;AN002;
	loop	copy_true_name_loop2							  ;AN002;

;	put in the "\"

	mov	ah,"\"			; get a \
	mov	es:[di],ah		; copy it
	inc	di			; increment pointer

;	we have copied the first part of the string, now get the real filename
;	from the DTA

	push	es
	push	bx

	mov	ah,get_DTA
	call	int_21
	push	es
	pop	ds
	mov	si,bx

	pop	bx
	pop	es

copy_true_name_loop3:
	mov	ah,ds:[si+30]	     ; get byte of actual filename		       ;AN002;
	mov	es:[di],ah		; copy it to user's buffer                        ;AN002;
	cmp	ah,null 		; is it a null? 				  ;AN002;
	je	true_name_copied	; yes, all done 				  ;AN002;
	inc	si			; in this loop the null is copied		  ;AN002;
	inc	di									  ;AN002;
	jmp	copy_true_name_loop3							  ;AN002;

not_hf:
	mov	si,dx			; make DS:SI point to true name

copy_true_name_loop:									  ;AN002;
	mov	ah,ds:[si]		; get byte of true name 			  ;AN002;
	mov	es:[di],ah		; copy it to user's buffer                        ;AN002;
	cmp	ah,null 		; is it a null? 				  ;AN002;
	je	true_name_copied	; yes, all done 				  ;AN002;
	inc	si									  ;AN002;
	inc	di									  ;AN002;
	jmp	copy_true_name_loop							  ;AN002;
											  ;AN002;
true_name_copied:									  ;AN002;
											  ;AN002;
no_true_name:										  ;AN002;
	restore_regs			; restore some regs				  ;AN002;
	pop	ax
											  ;AN002;
											  ;AN002;
no_more_to_try2:

	call	ctrl_break_restore	; restore normal control break address
	call	crit_err_restore	; restore normal critical error  address

;	find out if there is a need to set the extended error code

	cmp	ext_err_flag,0		; do we need to set the extended error code?
	je	no_ext_err2		; no, finish up
	lea	dx,ext_err_dpl
	call	set_ext_err_code	; yes, go set the ext error info

;	reset flags, and pack it in

no_ext_err2:
	popff
	restore_regs			; restore registers
	pushf				; put the real flags on the stack

	jmp	reset_stack		; fix stack, ret to caller

page
;-------------------------------------------------------------------
;
;	support routines for drive and path mode checking
;
;
;-------------------------------------------------------------------


check_for_drive:			; input:  ES:SI -> original string
					; output: AX = 0  no drive present
					; output: AX = -1 drive present

	xor	ax,ax			; assume no drive letter present

	cmp	es: byte ptr [si+1],':' ; is the second char a ":"?
	jne	exit_check_for_drive	; no, skip setting the flag

	mov	ax,-1			; yes, set the flag

exit_check_for_drive:

	ret

;-------------------------------------------------------------------

check_for_path: 			; input:  ES:SI -> original string
					; output: AX = 0  no path present
					; output: AX = -1 path present

	push	si			; save pointer

	xor	ax,ax			; assume no path present


;	walk the string and look for "/", or "\".  Any of these mean that a
;	path is present

walk_handle_string:

	push	ax									 ;AN006;
	mov	al,es: byte ptr [si]	; is this a dbcs char?				 ;AN006;
	call	Chk_DBCS								 ;AN006;
	pop	ax									 ;AN006;
											 ;AN006;
	jnc	no_dbcs1		; no, keep looking				 ;AN006;

	add	si,2			; yes, skip it and the next char		 ;AN006;
	jmp	walk_handle_string	; the next char could be a "\", but		 ;AN006;
					; would not mean a path was found		 ;AN006;
											 ;AN006;
no_dbcs1:										 ;AN006;
	cmp	es: byte ptr [si],"\"	; is the char a "\"?
	je	found_path		; yes, set flag and return
	cmp	es: byte ptr [si],"/"	; is the char a "/"?
	je	found_path		; yes, set flag and return
	cmp	es: byte ptr [si],0	; is the char a null
	je	exit_check_for_path	; yes, got to the end of the
					; handle string

	inc	si			; point to next char
	jmp	walk_handle_string	; and look again

found_path:
	mov	ax,-1			; yes, set the flag

exit_check_for_path:
	pop	si			; restore si
	ret

page
;-----------------------------------------------------------------------------
;	Entry point for interrupt 2f handler
;-----------------------------------------------------------------------------

intfcn_hook:
	cmp	ah,append_2f		; is this function call for append?
;;;;;;	je	do_appends						  ; @@12
	jne	ih_10							  ; @@12
	jmp	do_appends						  ; @@12
ih_10:									  ; @@12
	cmp	ah,applic_2f		; is this function call for applications
	je	do_applic
	jmp	pass_it_on

do_applic:
	cmp	dx,-1			; not COMMAND call
	jump	NE,pass_it_on
	cmp	al,0			; match name request
	jne	ck01

	mov	cmd_buf,bx		; save CMDBUF offset
	call	check_cmd_name
	jne	no_internal1
	mov	al,append_inst		; inidicate I want this command
no_internal1:
	iret

ck01:
	cmp	al,1			; match name request
	jne	ck02

;	save pointer to parser

	mov	word ptr pars_off+0,di	; ES:DI points to COMMAND.COM's parser
	mov	word ptr pars_off+2,es	; save it for later

	mov	cmd_env,bx		; save env pointer address
	call	check_cmd_name
	jne	no_internal2
	call	COMMAND_begin		; process internal command
no_internal2:
	iret

ck02:
;	cmp	al,2			; set COMMAND active	    ; @@13; @@09
;	jne	ck03						    ; @@13; @@09
;	mov	cmd_active,1					    ; @@13; @@09
;	iret							    ; @@13; @@09
ck03:								    ; @@13; @@09
;	cmp	al,3			; set COMMAND in active     ; @@13; @@09
;	jne	ck04						    ; @@13; @@09
;	mov	cmd_active,0					    ; @@13; @@09
;	iret							    ; @@13; @@09
ck04:								    ; @@13; @@09
	jmp	pass_it_on

;*******************************************************************************
;   The following old code is commented out.				    @@12
;*******************************************************************************
;check_cmd_name:			 ; see if internal APPEND
;	push	es
;	push	cs
;	pop	es
;	push	di
;	push	cx
;	push	si
;	cmp	ds:byte ptr[si],6	; length must match
;	jne	skip_comp
;	comp	append_id,6,[si+1]	; see if APPEND is command
;skip_comp:
;	pop	si
;	pop	cx
;	pop	di
;	pop	es
;	ret
;*********************************************************************
check_cmd_name: 			; See if APPEND 		    @@12
	push	ax			;				    @@12
	push	si			;				    @@12
	push	cx			;				    @@12
	push	di			;				    @@12
	push	es			;				    @@12
	mov	si,cmd_buf		; DS:SI -> cmd buf ended with cr    @@12
	add	si,2			; 1st 2 bytes garbage		    @@12
					;				    @@12
ccn_skip_leading:			;				    @@12
	lodsb				; skip leading stuff		    @@12

	call	Chk_DBCS		; find out if this is DBCS			 ;AN006;
	jnc	no_dbcs2		; no, keep looking				 ;AN006;
	lodsb				; yes, skip it and the next byte		 ;AN006;
	jmp	ccn_skip_leading	; the second byte will be skipper when		 ;AN006;
					; we go back through				 ;AN006;

no_dbcs2:										 ;AN006;
	cmp	al," "			;	blank			    @@12
	je	ccn_skip_leading	;				    @@12
	cmp	al,tab_char		;	tab			    @@12
	je	ccn_skip_leading	;				    @@12
	cmp	al,","			;	comma			    @@12
	je	ccn_skip_leading	;				    @@12
	cmp	al,"="			;	equal			    @@12
	je	ccn_skip_leading	;				    @@12
	cmp	al,";"			;	semi-colon		    @@12
	je	ccn_skip_leading	;				    @@12
	cmp	al,"\"			;	back slash		    @@12
	je	ccn_skip_leading	;				    @@12
	cmp	al,cr			; bad ret for early terminate	    @@12
	jne	ccn_02			;				    @@12
	cmp	al,0			;   reset z for no match	    @@12
	jmp	ccn_ret 		;				    @@12
ccn_02: 				;				    @@12
	mov	di,si			; di -> beginning of possible	    @@12
	dec	di			;	"APPEND " string	    @@12
	lodsb				;				    @@12
	cmp	al,":"			;				    @@12
	jne	ccn_cont		;				    @@12
	mov	di,si			;				    @@12
	lodsb				;				    @@12
ccn_cont:				;				    @@12
	call	Chk_DBCS								 ;AN006;
	jnc	no_dbcs3		; no, carry on					 ;AN006;
	add	si,2			; yes, skip it and the next byte		 ;AN006;
	jmp	ccn_20									 ;AN006;
											 ;AN006;
no_dbcs3:										 ;AN006;
	cmp	al,"\"			; move di up upon "\"		    @@12
	jne	ccn_20			;				    @@12
	mov	di,si			;				    @@12
ccn_10: 				;				    @@12
	lodsb				;				    @@12
	jmp	ccn_cont		;				    @@12
ccn_20: 				;				    @@12
	cmp	al," "			; look for separator		    @@12
	je	ccn_30			; if found, then have command	    @@12
	cmp	al,"="			;				    @@12
	je	ccn_30			;				    @@12
	cmp	al,cr			;				    @@12
	je	ccn_30			;				    @@12
	cmp	al,tab_char		;				    @@12
	je	ccn_30			;				    @@12
	cmp	al,","			;				    @@12
	je	ccn_30			;				    @@12
	cmp	al,";"			;				    @@12
	jne	ccn_10			;				    @@12

ccn_30: 				;				    @@12
	sub	si,di			;				    @@12
	cmp	si,7			;				    @@12
	jne	ccn_ret 		; no match			    @@12
					;				    @@12
	mov	si,di			;				    @@12
	chkchar "A"			; look for "APPEND" string	    @@12
	chkchar "P"			;				    @@12
	chkchar "P"			;				    @@12
	chkchar "E"			;				    @@12
	chkchar "N"			;				    @@12
	chkchar "D"			;				    @@12
					; exit with z set for match	    @@12
ccn_ret:				;				    @@12
	pop	es			;				    @@12
	pop	di			;				    @@12
	pop	cx			;				    @@12
	pop	si			;				    @@12
	pop	ax			;				    @@12
	ret				;				    @@12

page
;-------------------------------------------------------------------	 ;AN000;
;									 ;AN000;
;	do_appends							 ;AN000;
;									 ;AN000;
;	This is the INT 2F handler for the APPEND			 ;AN000;
;			  subfunction					 ;AN000;
;									 ;AN000;
;	New functions added for 3.30:					 ;AN000;
;									 ;AN000;
;									 ;AN000;
;									 ;AN000;
;	Get /X status							 ;AN000;
;									 ;AN000;
;	Input:	AX = B706						 ;AN000;
;									 ;AN000;
;	Output: BX = 0000	/X not active				 ;AN000;
;		   = 0001	/X active				 ;AN000;
;									 ;AN000;
;									 ;AN000;
;									 ;AN000;
;	Set /X status							 ;AN000;
;									 ;AN000;
;	Input:	AX = B707						 ;AN000;
;									 ;AN000;
;		BX = 0000	turn /X off				 ;AN000;
;		BX = 0001	turn /X on (active)			 ;AN000;
;									 ;AN000;
;-------------------------------------------------------------------	 ;AN000;
;
do_appends:
	cmp	al,are_you_there	; is the function request for presence?
	jne	ck1

	mov	al,-1			; set flag to indicate we are here
	iret				; return to user

ck1:
	cmp	al,dir_ptr		; is the function request for pointer?
	jne	ck2

	les	di,dword ptr dirlst_offset     ; return dirlist pointer to caller
	iret

ck2:
	cmp	al,get_app_version	; is the function request for version?
	jne	ck3			; no, check for next function

	mov	ax,-1			; yes, set NOT NETWORK version
	iret

ck3:
	cmp	al,tv_vector		; is the function request for TV vector?
	jne	ck4			; no, check for old dir ptr

	mov	tv_vec_seg,es		; yes, save the TV vector
	mov	tv_vec_off,di

	push	cs			; set ES:DI to tv ent pnt
	pop	es			;
	lea	di,tv_entry

	xor	byte ptr tv_flag,TV_TRUE ; set flag			  ;AN000;
	iret

ck4:					;
	cmp	al,old_dir_ptr		; is it the old dir ptr
	jne	ck5			; no, pass it on

	push	ds
	push	cs
	pop	ds

	call	sysloadmsg						 ;AN000;
									 ;AN000;
	mov	ax,1			; message number		 ;AN000;
	mov	bx,STDERR		; handle			 ;AN000;
	xor	cx,cx			; sub count			 ;AN000;
	xor	dl,dl			; no input			 ;AN000;
	mov	dh,-1			; message class 		 ;AN000;
	call	sysdispmsg						 ;AN000;

	pop	ds
	mov	al,1
	call	terminate		; exit to DOS			  ; @@05

ck5:					;
	cmp	al,DOS_version		; is it the new version check
	jne	ck6			; no, pass it on

	mov	ax,mode_flags		; set mode bits
	xor	bx,bx			; destroy registers
	xor	cx,cx
	mov	dl,byte ptr version_loc   ; major version num
	mov	dh,byte ptr version_loc+1 ; minor version num
	iret

ck6:									 ;AN000;
	cmp	al,get_state		; is it get state call? 	 ;AN001;
	jne	ck7			; no, look some more		 ;AN000;
									 ;AN000;
	mov	bx,mode_flags		; get mode bits 		 ;AN000;
	iret				; return to user		 ;AN000;
									 ;AN000;
ck7:									 ;AN000;
	cmp	al,set_state		; is it set state  call?	 ;AN001;
	jne	ck8			; no, look some more		 ;AN000;
									 ;AN000;
	mov	mode_flags,bx		; save the new state		 ;AN001;
	iret								 ;AN000;
									 ;AN000;
ck8:									 ;AN000;

	cmp	al,true_name		; is it the set true name function?		  ;AN002;
	jne	ck9			; no, look some more				  ;AN002;
											  ;AN002;
	push	ax			; save some regs				  ;AN002;
	push	bx									  ;AN002;
	push	es									  ;AN002;
	push	di									  ;AN002;
											  ;AN002;
											  ;AN002;
;	get the PSP and then get the APPEND flags byte

	mov	ah,get_PSP		; function code to get PSP address		  ;AN002;
	call	int_21			; get the PSP address				  ;AN002;
	mov	es,bx			; need to use it as a segment			  ;AN002;
	mov	di,PDB_Append		; get pointer to APPEND flag in PDB		  ;AN002;
											  ;AN002;
;	is the flag already set?

	mov	ax,es:[di]		; get APPEND flag into AX			  ;AN002;
	test	ax,true_name_flag	; is it set?					  ;AN002;
	jnz	no_set_true_name	; yes, do nothing				  ;AN002;
											  ;AN002;
;	set the true_name flag

set_true_name:										  ;AN002;
	add	ax,true_name_flag	; set true name flag				  ;AN002;
	mov	es:[di],ax		; save in PSP					  ;AN002;
											  ;AN002;
no_set_true_name:
	pop	di			; restore some regs				  ;AN002;
	pop	es									  ;AN002;
	pop	bx									  ;AN002;
	pop	ax									  ;AN002;
											  ;AN002;
	iret				; return					  ;AN002;
											  ;AN002;
ck9:											  ;AN002;

;-------------------------------------------------------------------
;	fill in additional 2F functions here
;-------------------------------------------------------------------

pass_it_on:				; the function call (ah) was not for append
	jmp	dword ptr intfcn_Offset ; jump to old INT 2f

page
;-----------------------------------------------------------------------------
;	Entry point for interrupt 24 handler
;-----------------------------------------------------------------------------

crit_err_handler:

	mov	crit_err_flag,0ffh	; set critical error flag
	mov	al,3			; fail int 21h
	iret

page
;-----------------------------------------------------------------------------
;	miscellaneous routines
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;	tv_barrier
;-----------------------------------------------------------------------------

tv_barrier:

	cmp	tv_flag,TV_TRUE 	; in Topview			 ;AN000;
	jne	no_barrier

	push	ax
	mov	ax,2002h		; wait on DOS barrier
	int	2Ah
	pop	ax
no_barrier:
	ret

;-----------------------------
;	check_config - this routine is called by both the FCB and handle open
;	code.  I checks the net_config flag to see if it is zero, if so it
;	does an installation check. If it is non-zero, nothing is done.

check_config:

	push	ax			; save a few registers
	push	bx

;	examine the config flag to see if we already know what config we have

	cmp	net_config,0
	jne	do_not_look		; we know config already

;	the flag word has not been set before,	go find out what config we have

	mov	ax,0b800h		; installation code function code
	int	2fh			; do the installation check

	mov	net_config,bx		; save flag word for later

do_not_look:
	pop	bx			;restore regs and leave
	pop	ax
	ret

;*( Chk_DBCS ) *************************************************************
;*									   *
;*  Function: Check if a specified byte is in ranges of the DBCS lead bytes*
;*  Attention: If your code is resident, comment out the lines marked	   *
;*	       ;** .							   *
;*									   *
;*  Input:								   *
;*	   AL	 = Code to be examined					   *
;*									   *
;*									   *
;*  Output:								   *
;*	   If CF is on then a lead byte of DBCS 			   *
;*									   *
;* Register:								   *
;*	   FL is used for the output, others are unchanged.		   *
;*									   *
;***************************************************************************
Chk_DBCS	PROC
	PUSH	DS
	PUSH	SI
;	CMP	CS:DBCSEV_SEG,0 	; ALREADY SET ? ;**
;	JNE	DBCS00					;**
	MOV	SI,OFFSET EVEV		; SET DEFAULT OFFSET  ;**
	PUSH	CS					      ;**
	POP	DS			; SET DEFAULT SEGMENT ;**
     PUSH    AX
	MOV	AX,6300H		; GET DBCS EV CALL
	INT	21H
	MOV	CS:DBCSEV_OFF,SI			      ;**
	MOV	CS:DBCSEV_SEG,DS			      ;**
     POP     AX
DBCS00:
	MOV	SI,CS:DBCSEV_OFF			      ;**
	MOV	DS,CS:DBCSEV_SEG			      ;**
DBCS_LOOP:
	CMP	WORD PTR [SI],0
	JE	NON_DBCS
	CMP	AL,[SI]
	JB	DBCS01
	CMP	AL,[SI+1]
	JA	DBCS01
	STC
	JMP	DBCS_EXIT
DBCS01:
	ADD	SI,2
	JMP	DBCS_LOOP
NON_DBCS:
	CLC
DBCS_EXIT:
	POP	SI
	POP	DS
	RET
Chk_DBCS	ENDP


;-----------------------------
;	append_fname - glues the fname onto the end of the dir to try

append_fname:
	push	es
	push	ds
	pop	es
	lea	di,try_dir		; destination, sort of (dir name)
	lea	si,fname		; source (filename)

;	find the end of the dir name

	mov	dbcs_fb,-1		; set flag for no dbcs first byte chars 	 ;AN006;

walk_dir_name:
	mov	al,byte ptr [di]	; get a char from dir name
	cmp	al,null 		; are we at the end?
	je	end_of_dir		; yes, add on the fname

	call	Chk_DBCS		; char is in al 				 ;AN006;
	jnc	no_dbcs4		; no, keep looking				 ;AN006;
	mov	dbcs_fb,di		; save offset					 ;AN006;
	inc	di			; skip second byte

no_dbcs4:
	inc	di			; no, keep stepping
	jmp	walk_dir_name

;	now it is time to append the filename

end_of_dir:
	mov	al,byte ptr [di-1]	; get last char of dir name
	cmp	al,"\"			; is it a dir seperator?
	jne	check_next_dir_sep	; no, check the next dir sep char		 ;AN006;
											 ;AN006;
	sub	di,2			; yes, must find out if real dir sep		 ;AN006;
					; or DBCS second byte				 ;AN006;
	cmp	dbcs_fb,di		; is the char before our dir sep a DBCS 	 ;AN006;
					; first byte?					 ;AN006;
	jne	no_dbcs4a		; no, must check for the next dir sep		 ;AN006;
					; yes, this means we must put in a dir sep	 ;AN006;
	add	di,2			; restore di					 ;AN006;
	jmp	put_in_dir_sep		; put int the dir sep char			 ;AN006;
											 ;AN006;
no_dbcs4a:										 ;AN006;
	add	di,1			; restore di, then check next dir sep		 ;AN006;

check_next_dir_sep:
	cmp	al,"/"			; is it the other dir seperator?
	je	add_fname		; yes, no need to add one
put_in_dir_sep: 									 ;AN006;
	mov	al,"\"			; get dir seperator
	stosb				; add to end of dir

add_fname:
	lodsb				; get a char from fname
	stosb				; copy the char
	cmp	al,null 		; are we at the and of the filename?
	je	eo_name 		; yes, all done!
	jmp	add_fname







eo_name:
	pop	es
	ret


;-----------------------------
;	get_fname strips out the 8.3 filename from the original ASCIIZ string
;
;	INPUT:	ES:SI points to original string
;		DS:DI points to area for filename

get_fname:

	mov	bx,si			; save the pointer
	mov	dbcs_fb,-1		; set the dbcs flag off 			 ;AN006;

gfn1:
	mov	ah,ES:byte ptr [si]	; get a char from the source
	cmp	ah,null 		; is it a null?
	je	got_the_end		; yes, we found the end

	call	chk_dbcs		; is this char a DBCS first byte?		 ;AN006;
	jnc	no_dbcs5		; no, carry on
	mov	dbcs_fb,si		; yes, save pointer
	inc	si			; skip second byte

no_dbcs5:
	inc	si			; no, point to next char
	jmp	gfn1			; loop till end found

got_the_end:
	mov	ah,ES:byte ptr [si]	; get a char
	cmp	ah,"/"			; did we find a /
	je	went_too_far		; yes, we found the start
	cmp	ah,"\"			; did we find a \
	je	found_bslash		; yes, we found the start			 ;AN006;
	cmp	ah,":"			; did we find a :
	je	went_too_far		; yes, we found the start
	cmp	si,bx			; are we back to the original start?
	je	got_the_beg		; yes, we found the start of the fname
	dec	si			; step back a char, then look some more
	jmp	got_the_end

found_bslash:				; found a backslash, must figure out if 	 ;AN006;
					; is second byte of DBCS			 ;AN006;
	dec	si			; point to next char				 ;AN006;
	cmp	si,dbcs_fb		; do they match?
	jne	no_dbcs5a		; no, fix up si and carry on			 ;AN006;
	dec	si			; skip dbcs byte and loop some more		 ;AN006;
	jmp	got_the_end								 ;AN006;

no_dbcs5a:										 ;AN006;
	inc	si			; went too far by one extra			 ;AN006;
											 ;AN006;
went_too_far:
	inc	si			; went one char too far back

;	ES:SI now points to the beginning of the filename

got_the_beg:
	mov	ah,ES:byte ptr [si]	; get a char from the source
	mov	byte ptr [di],ah	; copy to dest
	cmp	ah,null 		; did we just copy the end?
	je	done_with_fname 	; yes, all done
	inc	si			; no, get the next char
	inc	di
	cmp	di,offset app_dirs_ptr	; make sure we dont try to copy past the
	je	done_with_fname 	; area
	jmp	got_the_beg

done_with_fname:
	ret

;-----------------------------
;	this code executed to return to caller after APPEND's stack has been
;	initialized

reset_stack:

;	reset the stack 								  ;AN002;

	popff				; restore flags from real open
	mov	ss,Stack_Segment	; Get original stack segment
	mov	sp,Stack_Offset 	; Get original stack pointer
	pushf				; put the flags on the old stack


;-----------------------------
;	before jumping to this routine, SS:SP must point to the caller's stack,
;	and the flags from the real INT 21 operation must have been pushed

set_return_flags:

;	must be sure to clear the true_name flag before leaving 			  ;AN002;
											  ;AN002;
	push	ax			; save some regs				  ;AN002;
	push	bx									  ;AN002;
	push	es									  ;AN002;
	push	di									  ;AN002;
											  ;AN002;
	mov	ah,get_PSP		; function code for get PSP operation		  ;AN002;
	call	int_21			; get the PSP, segment returned in BX		  ;AN002;
	mov	es,bx			; need to use it as a segment			  ;AN002;
	mov	di,PDB_Append		; get pointer to APPEND flag in PDB		  ;AN002;
											  ;AN002;
	mov	ax,es:[di]		; get APPEND flag into AX			  ;AN002;
	test	ax,true_name_flag	; is true name flag armed?			  ;AN002;
	jz	reset_stack2		; no, don't copy true name                        ;AN002;
											  ;AN002;
	sub	ax,true_name_flag	; clear true name flag				  ;AN002;
	mov	es:[di],ax		; save it in PSP				  ;AN002;
											  ;AN002;
											  ;AN002;
reset_stack2:										  ;AN002;
											  ;AN002;
	pop	di			; restore					  ;AN002;
	pop	es									  ;AN002;
	pop	bx									  ;AN002;
	pop	ax									  ;AN002;
											  ;AN002;
	cmp	tv_flag,TV_TRUE 					 ;AN000;
	jne	tv_flag_not_set

	mov	ax,2003h		; clear open barrier
	int	2Ah


;	pop down to the old flags on the user's stack

tv_flag_not_set:

	cmp	incoming_AX,exec_proc*256+0	; need to do exec
	jne	not_exec3
	popff				; discard bad flags
	mov	ax,incoming_AX		; set exec parms

	push	ds			; save DS, this must be done					;an005;
					; to pervent DS from being trashed on return to caller		;an005;

	push	cs
	pop	ds
	lea	dx,try_dir
	mov	bx,incoming_BX
	mov	es,incoming_ES
	call	int_21			; issue the exec

	pop	ds			; restore DS							; an005;

	pushf

not_exec3:
	popff				; get flags from real int 21 (old stack)
	pop	temp_IP_save		; save IP, CS
	pop	temp_CS_save
	lahf				; save flags in AH
	popff				; pop old flags off stack
	sahf				; replace old with new

;	push the new flags onto the stack, then fix CS and IP on stack

	pushf				; push new flags onto stack
	push	temp_CS_save		; restore IP, CS
	push	temp_IP_save
	mov	ax,AX_after_21		; Set AX as it was after open

	call	crit_sect_reset 	; clear the critical section flag
	iret				; return to the calling routine


;-----------------------------
;	This routine is used to extract an appended dir from the dir list
;	On entry, DS:DI points to an area for the appended dir
;	and ES:SI points to the source string

get_app_dir:

	xor	cx,cx			; keep a count of chars in cx			  ;AN003;
copy_dir:
	mov	ah,es:byte ptr [si]	; get the char, and copy it into dest
	cmp	ah,null 		; find a null?
	je	no_more_dirs		; yes, inform caller that this is the last one

	cmp	ah,";"			; check to see if we are at the end of a dir
	je	update_pointer		; yes,

	mov	byte ptr [di],ah	; if not null or semi-colon, then copy it
	inc	si			; increment both pointers
	inc	di
	inc	cx			; count of chars				  ;AN003;
	jmp	copy_dir		; do it some more

update_pointer:
	inc	si			; point to next char
	mov	ah,es:byte ptr [si]	; get char			  ; @@16
	cmp	ah,null 		; did we reach the end of the dir list?
	je	no_more_dirs		;

	cmp	ah,";"			; is is a semi-colon
	je	update_pointer
	jmp	all_done


no_more_dirs:
	xor	si,si			; set end search flag

all_done:
	mov	byte ptr [di],null	; null terminate destination
	ret				; return to caller

;-----------------------------
;	set ctrl-break check off
;	first, save the old state so we can restore it later,
;	then turn ctrl-break checking off

ctrl_break_set:

	mov	ah,ctrl_break		; function code for ctrl-break check
	xor	al,al			; 0 = get current state
	call	int_21			; call DOS INT 21 handler

	mov	ctrl_break_state,dl	; save the old ctrl-break state

	mov	ah,ctrl_break		; function code for ctrl-break check
	mov	al,01			; set current state
	xor	dl,dl			; 0 = off
	call	int_21			; call DOS INT 21 handler
	ret


;-----------------------------
;	restore ctrl-break checking flag to the way it was
ctrl_break_restore:
	mov	ah,ctrl_break		; function code for ctrl-break check
	mov	al,01			; set current state
	mov	dl,ctrl_break_state	; get the way is was before we messed with it
	call	int_21			; call DOS INT 21 handler
	ret

;-----------------------------
;	restore ctrl-break checking flag to the way it was
ctrl_break_rest:
	mov	ah,ctrl_break		; function code for ctrl-break check
	mov	al,01			; set current state
	mov	dl,ctrl_break_state	; get the way is was before we messed with it
	call	int_21
	ret

;-----------------------------
;
crit_err_set:
	mov	crit_err_flag,0 	; clear the critical error flag

	mov	ax,get_crit_err 	; Get INT 24h vector
	call	int_21			; call DOS INT 21 handler

	mov	crit_vector_offset,bx	; Save it
	mov	ax,es			; es hase segment for resident code
	mov	crit_vector_segment,ax

	lea	dx,crit_err_handler	; DS:DX = New INT 21h vector
	mov	ax,set_crit_err 	; function code for setting critical error vector
	call	int_21			; call DOS INT 21 handler
	ret				; go back to the caller


;-----------------------------
;
crit_err_restore:
	push	ds			; save ds for this function
	mov	ax,set_crit_err 	; function code for setting critical error vector
	mov	dx,crit_vector_offset	; get old int 24 offset
	mov	ds,crit_vector_segment	; get old int 24 segment
	call	int_21			; call INT 21
	pop	ds
	ret

;-----------------------------
;	crit_sect_set - issues an enque request to the server to protect
;	against reentry.  This request is issued only if the network is started,
;	and then, only for RCV, MSG, and SRV configurations
crit_sect_set:
	push	ax
	push	bx
	push	di
	push	es

	mov	ax,net_config		; check the server config flag
	cmp	ax,0			; is it zero?
	je	dont_set_crit_sect	; yes, skip it

	cmp	ax,redir_flag		; is it a redir?
	je	dont_set_crit_sect	; yes, skip it
					; otherwise, issue the request

;	the config flag was not zero or redir, so set crit section

	mov	ah,NETSYSUTIL
	mov	al,NETENQ
	mov	bx,TCBR_APPEND
	int	2Ah

dont_set_crit_sect:			; because of the config we don't want
	pop	es			; to set critical section
	pop	di
	pop	bx
	pop	ax
	ret

;-----------------------------
;
crit_sect_reset:
	push	ax
	push	bx

	mov	ax,net_config		; check the server config flag
	cmp	ax,0			; is it zero?
	je	not_set 		; yes, skip it

	cmp	ax,redir_flag		; is it a redir?
	je	not_set 		; yes, skip it

	mov	ah,NETSYSUTIL		; turn critical section off
	mov	al,NETDEQ
	mov	bx,TCBR_APPEND
	int	2Ah

not_set:
	pop	bx
	pop	ax
	ret


;-----------------------------
;	save_first_ext_err - this routine is used to save the extended
;		error info after the first FCB open.
save_first_ext_err:

	push	ax

	mov	ax,ext_err_dpl.DPL_AX		; copy all registers
	mov	save_ext_err.DPL_AX,ax
	mov	ax,ext_err_dpl.DPL_BX
	mov	save_ext_err.DPL_BX,ax
	mov	ax,ext_err_dpl.DPL_CX
	mov	save_ext_err.DPL_CX,ax
	mov	ax,ext_err_dpl.DPL_DX
	mov	save_ext_err.DPL_DX,ax
	mov	ax,ext_err_dpl.DPL_SI
	mov	save_ext_err.DPL_SI,ax
	mov	ax,ext_err_dpl.DPL_DI
	mov	save_ext_err.DPL_DI,ax
	mov	ax,ext_err_dpl.DPL_DS
	mov	save_ext_err.DPL_DS,ax
	mov	ax,ext_err_dpl.DPL_ES
	mov	save_ext_err.DPL_ES,ax

	pop	ax
	ret

;-----------------------------
;	get_ext_err_code - this routine is used to get the extended error
;		info for the error that cause append to start its search

get_ext_err_code:
	push	ax			; save register that are changed by this
	push	bx			; DOS function
	push	cx
	push	di
	push	si
	push	es
	push	ds

;	get the extended error information

	mov	ah,59h			; function code for get extended error
	xor	bx,bx			; version number
	call	int_21			; get the extended error

;	save it away in a DPL for set_ext_error_code
;	all fields in the DPL will be filled in except the last three,
;	which will be left at zero

	mov	ext_err_dpl.DPL_AX,ax
	mov	ext_err_dpl.DPL_BX,bx
	mov	ext_err_dpl.DPL_CX,cx
	mov	ext_err_dpl.DPL_DX,dx
	mov	ext_err_dpl.DPL_SI,si
	mov	ext_err_dpl.DPL_DI,di
	mov	ext_err_dpl.DPL_DS,ds
	mov	ext_err_dpl.DPL_ES,es


;	restore regs and return

	pop	ds
	pop	es			; restore registers
	pop	si
	pop	di
	pop	cx
	pop	bx
	pop	ax
	ret

;-----------------------------
;	set_ext_err_code - this routine is used to get the extended error
;		info for the error that cause append to start its search
;		CS:DX points to return list
set_ext_err_code:
	push	ax			; save register that are changed by this
	push	ds			; DOS function

;	get the extended error information

	mov	ah,DOSSERVER		; function code for DOSSERVER call
	mov	al,DOSSETERROR		; sub-function code for set extended error
	push	cs
	pop	ds
	call	int_21			; set the extended error

;	restore regs and return

	pop	ds			; restore registers
	pop	ax
	ret
page
;-----------------------------
;	This routine is used to initiate DOS calls from within the APPEND interrupt
;	handlers.  An INT instruction can not be used because it would cause APPEND
;	to be re-entered.
;
;	SS, SP saved incase call is EXEC which blows them away
int_21: 				;
	cmp	tv_flag,TV_TRUE 	; see if being re-entered	 ;AN000;
	jne	use_old_vec		; yes, pass through to DOS

	pushf				; to comp for iret pops
	call	dword ptr tv_vec_off	; Call INT 21h
	ret				;

use_old_vec:
	cmp	vector_segment,0	; not installed yet
	je	use_int

	pushf				;  to comp for iret pops
	call	dword ptr vector_offset ; Call INT 21h
	ret				;

use_int:
	int	DOS_function
	ret
page
;-----------------------------
;	This routine is used to locate the current APPEND path string
;	result to ES:DI

address_path:
address_status: 							  ; @@13
	test	mode_flags,E_mode
	jnz	get_env_mode

address_pathx:
	mov	ax,append_2f*256+dir_ptr	; get from buffer
	int	int_function
	clc
	ret

get_env_mode:					; get from environment
;	cmp	cmd_active,0			; different logic   ; @@13; @@09
;	jne	use_cmd_env			; if in COMMAND     ; @@13; @@09
	push	bx
	mov	ah,get_PSP
	call	int_21				; get the PSP
	mov	es,bx
	mov	bx,002ch			; address environment
	mov	ax,es:word ptr[bx]
	mov	es,ax
	pop	bx
	cmp	ax,0				; PSP pointer is set
	je	address_pathx						  ; @@13
use_cmd_env:								  ; @@13
;	cmp	cmd_env,0			; have not set my pointer yet
;	je	address_pathx						  ; @@13
;	mov	es,cmd_env						  ; @@13
env_mode1:
	mov	di,0				; start at start
	cmp	es:byte ptr[di],0		; no environment
	je	no_appendeq
find_append:
	cmp	es:word ptr[di],0		; at environment end
	je	no_appendeq
	push	di
	push	si
	push	cx
	push	ds
	push	cs
	pop	ds
	comp	,6+1,append_id			; string = "APPEND="
	pop	ds
	pop	cx
	pop	si
	pop	di
	je	at_appendeq
	inc	di
	jmp	find_append
at_appendeq:					; must insure this is	    @@17
	cmp	di,0				; genuine "APPEND=" string  @@17
	je	at_appendeq_genuine		; if start of environ ok    @@17
	dec	di				; else check that 0	    @@17
	cmp	es:byte ptr[di],0		;      precedes string	    @@17
	je	at_appendeq_10			; jmp if ok		    @@17
	add	di,8				; else cont.search after    @@17
	jmp	find_append			;      "="		    @@17
at_appendeq_10: 				;			    @@17
	inc	di				;			    @@17
at_appendeq_genuine:				;			    @@17
	add	di,6+1				; skip APPEND=
	cmp	es:byte ptr[di],0		; null value
	je	no_appendeq			; treat as not found
	cmp	es:byte ptr[di]," "
	je	no_appendeq
	cmp	es:byte ptr[di],";"
	je	no_appendeq
	clc					; set ok
	ret

no_appendeq:					; not found, use default
	lea	di,semicolon			; null list
	push	cs
	pop	es
	stc					; set error
	ret

;-----------------------------						  ; @@03
;	This routine is used to locate the current APPEND path string	  ; @@03
;	result to ES:DI.  Used by APPEND status.			  ; @@03

;address_status:						    ; @@13; @@03
;	test	mode_flags,E_mode				    ; @@13; @@03
;	jump	Z,address_pathx 				    ; @@13; @@03
;	jmp	use_cmd_env					    ; @@13; @@03

cap_dl: 					; convert dl to uppercase
	cmp	dl,"a"			; find out if we have a lower case; @@14
	jb	cap_dlx 		; char				  ; @@14
	cmp	dl,"z"							  ; @@14
	ja	cap_dlx 						  ; @@14
	sub	dl,"a"-"A"		; convert char to upper case	  ; @@14
cap_dlx:
	ret

;	end_address:				; this is the end of the TSR stuff		 ;AN002;

page
;-----------------------------------------------------------------------------
;	Main routine. Used to determine if APPEND has been loaded
;	before. If not, load resident portion of APPEND. Then handle setting
;	or displaying appended directory list.
;-----------------------------------------------------------------------------

main_begin:				; DOS entry point

	mov	ax,seg mystack		; set up stack
	mov	ss,ax
	lea	sp,mystack

	cld

	mov	res_append,0		; set external copy		  ; @@05

	push	cs			; make DS point to CS
	pop	ds

	push	cs			; make ES point to CS
	pop	es


;	find out if append has been loaded				  ; @@04
									  ; @@04
	mov	ah,append_2f		; int 2f function code for append ; @@04
	mov	al,are_you_there	; function code to ask if append  ; @@04
					; has been loaded		  ; @@04
	int	int_function						  ; @@04
									  ; @@04
	cmp	al,append_inst		; is append there?		  ; @@04
	jne	not_there_yet		; no				  ; @@04

	mov	dx,0			; set for network version	  ; @@07
	mov	ah,append_2f		; int 2F function code for append ; @@07
	mov	al,DOS_version		; function code for get version   ; @@07
	int	int_function						  ; @@07
	cmp	dx,word ptr version_loc ; does the version match?	  ; @@07
	jne	bad_append_ver		; no, cough up an error messsage  ; @@07


	call	sysloadmsg						 ;AN000;
									 ;AN000;
	mov	ax,9			; message number		 ;AN000;
	mov	bx,STDERR		; handle			 ;AN000;
	xor	cx,cx			; sub count			 ;AN000;
	xor	dl,dl			; no input			 ;AN000;
	mov	dh,-1			; message class 		 ;AN000;
	call	sysdispmsg						 ;AN000;
;	mov	cx,len_second_APPEND_msg; length of string		 ;AN000;   ; @@04
;	lea	dx,second_APPEND_msg	; second load message		 ;AN000;   ; @@04
;	call	print_STDERR		; display error message 	 ;AN000;   ; @@04
;	lea	dx,crlf 		; carriage return, line feed	  ; @@04
;	mov	cx,crlf_len		; length of string		  ; @@04
;	call	print_STDERR						  ; @@04
									  ; @@04
	mov	al,0fch 		; second load			  ; @@05
	call	terminate		; exit to DOS			  ; @@05

bad_append_ver: 			; append version mismatch	  ; @@07
	call	sysloadmsg						 ;AN000;
									 ;AN000;
	mov	ax,1			; message number		 ;AN000;
	mov	bx,STDERR		; handle			 ;AN000;
	xor	cx,cx			; sub count			 ;AN000;
	xor	dl,dl			; no input			 ;AN000;
	mov	dh,-1			; message class 		 ;AN000;
	call	sysdispmsg						 ;AN000;
;	mov	cx,len_bad_append_msg					 ;AN000;   ; @@07
;	lea	dx,bad_append_msg	; bad app message		 ;AN000;   ; @@07
;	call	print_STDERR						 ;AN000;   ; @@07
;	lea	dx,crlf 		; carriage return, line feed	  ; @@07
;	mov	cx,crlf_len		; length of string		  ; @@07
;	call	print_STDERR						  ; @@07
	mov	ax,0feh 		; bad APPEND version		  ; @@05
	call	terminate		; exit to DOS			  ; @@05

not_there_yet:								  ; @@04

	mov	cs:initial_pass,-1	; set a flag for initial pass			 ;AN007;
	call	do_command		; do actual APPEND

	mov	bx,4			; close all standard files
do_closes:
	mov	ah,3eh			; close file handle
	call	int_21
	dec	bx
	jns	do_closes

	call	set_vectors		; set append vectors on success   ; @@05

	call	Release_Environment	; release the environmental vector space	;an007; dms;

	lea	dx,end_address+15	; normal end
	mov	cl,4			; calc end address in paragraphs
	shr	dx,cl
	mov	ah,get_PSP		; calc space from PSP to my code  ; @@02
	call	int_21							  ; @@02
	mov	ax,cs							  ; @@02
	sub	ax,bx							  ; @@02
	add	dx,ax			; calc length to keep		  ; @@02
	mov	al,0			; exit with no error
	mov	ah,term_stay
	call	int_21

page

COMMAND_begin:				; COMMAND entry point
	save_regs
	mov	word ptr cmd_name@+0,si  ; save internal command buffer @
	mov	word ptr cmd_name@+2,ds
	cld

	mov	abort_sp,sp		; save sp for aborts		  ; @@05
	mov	res_append,1		; set resident copy		  ; @@05
	call	do_command		; do actual APPEND
abort_exit:				; exit to abort append		  ; @@05
	mov	sp,abort_sp						  ; @@05

	push	es
	push	di
	les	di,cmd_name@
	mov	es:byte ptr[di],0	; set no command now
	pop	di
	pop	es

	cmp	ax,0			; error
	jne	no_E_mode
	test	mode_flags,E_mode	; no /E processing
	jz	no_E_mode

	mov	ax,append_2f*256+dir_ptr; int 2f function code for append
	int	int_function
	push	es
	pop	ds
	mov	si,di

;	mov	ah,get_PSP		; set new command
;	call	int_21
	mov	bx,ss
	mov	es,bx
	mov	bx,cmd_buf		; command line iput buffer
	inc	bx			; skip max length
	mov	es:byte ptr[bx],3+1+6+1
	mov	di,bx			; address command line buffer
	inc	di			; skip current length
	push	ds
	push	si
	push	cs
	pop	ds
	move	,3+1+6+1,setappend_name ; set in "SET APPEND="
	pop	si
	pop	ds
	cmp	ds:byte ptr[si],";"	; null list is special case
	jne	copy_path
	mov	al," "
	stosb
	inc	es:byte ptr[bx]
	jmp	short copy_path_done
copy_path:
	lodsb
	cmp	al,0
	je	copy_path_done
	stosb
	inc	es:byte ptr[bx]
	jmp	copy_path
copy_path_done:
	mov	es:byte ptr[di],cr	; set end delimiter

	les	di,cmd_name@
	mov	al,3			; SET length
	stosb
	push	cs							  ; @@06
	pop	ds							  ; @@06
	move	,8,set_name		; set up "SET" command

	mov	ax,0			; set to do SET
no_E_mode:

	restore_regs
	ret

page

do_command:				; APPEND process

;	set ctrl-break check off
;	first, save the old state so we can restore it later,
;	then turn ctrl-break checking off

	mov	ah,ctrl_break		; function code for ctrl-break check
	xor	al,al			; 0 = get current state
	call	int_21

	mov	ctrl_break_state,dl	; save the old ctrl-break state

	mov	ah,ctrl_break		; function code for ctrl-break check
	mov	al,01			; set current state
	xor	dl,dl			; 0 = off
	call	int_21

;	find out if append has been loaded

	mov	ah,append_2f		; int 2f function code for append
	mov	al,are_you_there	; function code to ask if append
					; has been loaded
	int	int_function

	cmp	al,append_inst		; is append there?
	jne	not_already_there	; yes, don't try to put it
	jmp	already_there		; yes, don't try to put it
					; there again

;	get DOS version and decide if it is in the allowed range for
;	APPEND

not_already_there:
	mov	ah,get_version		; lets find out if we should do it
	call	int_21			; try the open
	cmp	ax,expected_version	; compare with DOS version
	jne	bad_DOS

	jmp	check_assign		; valid range
					; lets see if assign has been loaded

;	Break it to the user that he's trying to do an APPEND with
;	the wrong DOS version

bad_DOS:
	cmp	al,01			; DOS 1x or below has no handle fcns ; fixed P134 9/10/87 - gga
	ja	use_STDERR
;	lea	dx,bad_DOS_msg		; bad DOS message				  ;AN000;
;	mov	ah,print_string 							  ;AN000;
;	call	int_21									  ;AN000;
	call	sysloadmsg						 ;AN000;
									 ;AN000;
	mov	ax,8			; message number		 ;AN000;
	mov	bx,NO_HANDLE		; no handle			 ;AN000;
	xor	cx,cx			; sub count			 ;AN000;
	xor	dl,dl			; no input			 ;AN000;
	mov	dh,-1			; message class 		 ;AN000;
	call	sysdispmsg						 ;AN000;


	call	ctrl_break_rest
	int	termpgm 		; return to DOS 		  ; @@05

use_STDERR:
									 ;AN000;
	call	sysloadmsg						 ;AN000;
									 ;AN000;
	mov	ax,8			; message number		 ;AN000;
	mov	bx,STDERR		; handle			 ;AN000;
	xor	cx,cx			; sub count			 ;AN000;
	xor	dl,dl			; no input			 ;AN000;
	mov	dh,-1			; message class 		 ;AN000;
	call	sysdispmsg						 ;AN000;

;	mov	cx,len_bad_DOS_msg	; length of string		 ;AN000;
;	lea	dx,bad_DOS_msg		; bad DOS message		 ;AN000;
;	call	print_STDERR		; display error message 	 ;AN000;

	call	ctrl_break_rest
	mov	al,0ffh 		; bad DOS version		  ; @@05
	call	terminate		; exit to DOS			  ; @@05

check_assign:
	mov	ax,0600h
	int	2fh
	or	al,al
	jnz	assign_there
	jmp	check_TopView		; ASSIGN has not been loaded,	  ; @@01

;	ASSIGN has been loaded before APPEND, bad news!

assign_there:
	call	sysloadmsg						 ;AN000;
									 ;AN000;
	mov	ax,6			; message number		 ;AN000;
	mov	bx,STDERR		; handle			 ;AN000;
	xor	cx,cx			; sub count			 ;AN000;
	xor	dl,dl			; no input			 ;AN000;
	mov	dh,-1			; message class 		 ;AN000;
	call	sysdispmsg						 ;AN000;

;	mov	cx,len_append_assign_msg; length of string
;	lea	dx,append_assign_msg
;	call	print_STDERR		; display error message
	jmp	conflict_exit						  ; @@01
									  ; @@01
check_Topview:								  ; @@01
	mov	bx,0			; incase not there		  ; @@01
	mov	ax,10h*256+34		; TopView version check 	  ; @@01
	int	15h							  ; @@01
	cmp	bx,0							  ; @@01
	jnz	TopView_there						  ; @@01
	jmp	replace_vector		; TopView has not been loaded,	  ; @@01
									  ; @@01
;	TopView has been loaded before APPEND, bad news!		  ; @@01
									  ; @@01
TopView_there:								  ; @@01
;	mov	cx,len_append_TV_msg	; length of string		  ; @@01
;	lea	dx,append_TV_msg					  ; @@01
;	call	print_STDERR		; display error message 	  ; @@01
	call	sysloadmsg						 ;AN000;
									 ;AN000;
	mov	ax,7			; message number		 ;AN000;
	mov	bx,STDERR		; handle			 ;AN000;
	xor	cx,cx			; sub count			 ;AN000;
	xor	dl,dl			; no input			 ;AN000;
	mov	dh,-1			; message class 		 ;AN000;
	call	sysdispmsg						 ;AN000;

									  ; @@01
conflict_exit:								  ; @@01
	call	ctrl_break_rest
	mov	al,0fdh 						  ; @@05
	call	terminate		; exit to DOS			  ; @@05

;	get pointer to dir list, on return ES:DI points to buffer

already_there:

;	This code has been moved to main_begin				  ; @@07
;									  ; @@07
;	make sure the right version of APPEND has been loaded		  ; @@07
;

;	mov	dx,0			; set for network version	  ; @@07
;	mov	ah,append_2f		; int 2F function code for append ; @@07
;	mov	al,DOS_version		; function code for get version   ; @@07
;	int	int_function						  ; @@07
;	cmp	dx,word ptr version_loc ; does the version match?	  ; @@07
;	jump	NE,bad_append_ver	; no, cough up an error messsage  ; @@07

process_args:				; process all arguments

;-------------------------------------------------------------------
	mov	si,0081h		; DS:SI points to argument area
	mov	cs:byte ptr e_switch+9,0	; turn /E switch off

process_argsx:				; process all arguments
;


;	make sure that the /PATH and /X switches are re-enabled, and
;	various flags are cleared

	mov	ah,"/"
	mov	cs:byte ptr x_switch+9,ah		; re-enable /X switch
	mov	cs:byte ptr path_switch+9,ah		; re-enable /PATH switch
	mov	cs:byte ptr x_result.$P_Type,0		; clear flag
	mov	cs:byte ptr path_result.$P_Type,0	; clear flag
	mov	cs:byte ptr dirs_result.$P_Type,0	; clear flag
	mov	cs:parse_flag,0 			; clear parse flag

;	set up things to call PARSER

	push	cs			; make sure ES points to segment where
	pop	es			; parm block info is
	lea	di,cs:p_block2		; ES:DI points to parm block, for secondary parsing


	xor	cx,cx			; ordinal value, must start as 0
	xor	dx,dx			; must be 0

	call	Scan_For_Equal		; yes - let's see if we have "=" symbol ;an008; dms;
					; parse past it if we do

get_pars_info:
	call	dword ptr pars_off	; call to COMMAND.COM's parser

	cmp	ax,-1			; end of line?
	jne	not_end_of_line 	; no, carry on
	jmp	end_of_line_reached	; yes, go figure out what we got

not_end_of_line:

	cmp	ax,0			; no, find out if there an error
	je	not_parse_error 	; no, carry on
	jmp	parse_error		; yes, go display the error message

;	got here without any errors, set the proper bits in mode_flags

not_parse_error:
	mov	cs: parse_flag,0ffh	; set parse flag


check_e:
	cmp	e_result.$P_Type,3	; was there a /E in this pass?
	jne	check_x 		; no, look for an X

	mov	byte ptr e_switch+9,0	; turn this off so we don't allow another
	mov	e_result.$P_Type,0	; clear this so we don't get fooled later

	or	mode_flags,E_mode	; set E mode on

	jmp	get_pars_info		; go get another argument

check_x:
	cmp	x_result.$P_Type,3	; was there a /X on this pass? list index
	je	set_x			; yes, and it was /X w/o ON or OFF

	cmp	x_result.$P_Type,2	; was there a /X on this pass? list index
	jne	check_path

	mov	byte ptr x_switch+9,0	; turn this off so we don't allow  another
	mov	x_result.$P_Type,0	; clear this so we don't get fooled later

	cmp	x_result.$P_Item_Tag,1	; was /X or /X:ON specified?
	je	set_x			; yes, set X mode on
	and	mode_flags,NOT x_mode	; no, clear it
	jmp	get_pars_info

set_x:
	or	mode_flags,x_mode
	jmp	get_pars_info

check_path:
	cmp	path_result.$P_Type,2	; was there a /path on this pass? list index
	jne	check_dirs

	xor	ah,ah			; turn this off so we don't allow
	mov	byte ptr path_switch+9,ah	 ; another
	mov	path_result.$P_Type,0	; clear this so we don't get fooled later


	cmp	path_result.$P_Item_Tag,1	; was /PATH:ON specified?
	je	set_path			; yes, set PATH mode
	and	mode_flags,NOT path_mode	; no, clear it
	jmp	get_pars_info

set_path:
	or	mode_flags,path_mode	; set PATH mode on
	jmp	get_pars_info

;	find out if dirs specified

check_dirs:
	cmp	dirs_result.$P_Type,3	; was a simple string returned?
	je	check_dirs2		; yes, carry on
	jmp	get_pars_info		; no, all done for now

;	set up stuff to do the dirs copy

check_dirs2:
	push	es
	push	ds
	push	si
	push	di

	lds	si,dword ptr dirs_result.$P_Picked_Val	  ; get pointer to dirs string
	mov	dirs_result.$P_Type,0	; clear this so we don't get fooled later

	mov	di,0			; set incase int 2f not installed ; @@08
	mov	es,di							  ; @@08
	mov	ax,append_2f*256+dir_ptr  ; es:di -> internal result area ; @@08
	int	int_function						  ; @@08
	mov	ax,es			; see if active yet		  ; @@08
	or	ax,di							  ; @@08
	jnz	copy_dirs_loop		; ok, do the copy		  ; @@08
	push	cs			; not active, set myself	  ; @@08
	pop	es							  ; @@08
	lea	di,app_dirs						  ; @@08

copy_dirs_loop:
	movs	es: byte ptr[di],ds:[si]; copy char

	cmp	byte ptr ds:[si-1],0	; is char a null
	je	done_copy_dirs

	jmp	copy_dirs_loop

done_copy_dirs:

	pop	di
	pop	si
	pop	ds
	pop	es

	jmp	get_pars_info		; no error yet, loop till done

end_of_line_reached:
	mov	old_syntax,0		; process old format operands

	cmp	cs:initial_pass,-1	; is this the first APPEND			 ;AN006;
	je	first_one		; yes, clear flag and exit			 ;AN006;

	cmp	cs:parse_flag,0 	; if this flag is off, means null command line
					; was nothing on the command line
	je	display_dirs		; go display the dirs

first_one:										 ;AN006;
	mov	cs:initial_pass,0	; clear first pass flag 			 ;AN006;

done_for_now:
normal_exit:
	call	ctrl_break_rest 	; reset control break checking
	mov	ax,0			; set string
	ret				; exit to COMMAND


parse_error:
	push	ax			;save parser error code 		;an010;bgb
	call	sysloadmsg						 ;AN000;
	pop	ax			;restore parser error coed		;an010;bgb
	call	do_parse_err							;an010;bgb
	jmp	bad_parmx		; display message and get out

;-------------------------------------------------------------------

;	 mov	 si,0081h		 ; point si to argument area
;	 mov	 bx,ss
;	 mov	 ds,bx
;
;process_argsx: 			 ; process all arguments
;	 mov	 di,0			 ; set incase int 2f not installed ; @@08
;	 mov	 es,di							   ; @@08
;	 mov	 ax,append_2f*256+dir_ptr  ; es:di -> internal result area ; @@08
;	 int	 int_function						   ; @@08
;	 mov	 ax,es			 ; see if active yet		   ; @@08
;	 or	 ax,di							   ; @@08
;	 jnz	 have_ptr						   ; @@08
;	 push	 cs			 ; not active, set myself	   ; @@08
;	 pop	 es							   ; @@08
;	 lea	 di,app_dirs						   ; @@08
;have_ptr:								   ; @@08
;
;;	 step through the DOS command line argument area, and copy the new dir
;;	 list to the proper place in APPEND. This requires some parsing for
;;	 spaces, tabs chars, equal signs, as well as conversion to upper case
;
;	 cmp	 byte ptr[si],"="	 ; APPEND=path is OK syntax
;	 jne	 skip_leading
;	 inc	 si
;skip_leading:				 ; skip leading spaces
;	 lodsb
;	 cmp	 al," "
;	 je	 skip_leading
;	 cmp	 al,tab_char
;	 je	 skip_leading
;	 cmp	 al,"," 						   ; @@15
;	 je	 skip_leading						   ; @@15
;	 cmp	 al,"=" 						   ; @@15
;	 je	 skip_leading						   ; @@15
;	 cmp	 al,cr			 ; did we have command line arguments?
;	 jump	 E,display_dirs 	 ; no, display the dirs currently appended
;	 cmp	 al,"/" 		 ; is it a parm starter?	   ; @@05
;	 jump	 E,bad_path_parm	 ; yes, it's an error              ; @@05
;	 dec	 si
;
;copy_args:
;	 lodsb				 ; get char from command line area
;	 cmp	 al,cr			 ; are we at the end?
;	 jump	 E,found_end		 ; yes, display the currently appended dirs
;	 cmp	 al," " 		 ; is it a space?
;	 je	 found_space		 ; yes, at end
;	 cmp	 al,tab_char		 ; is it a tab?
;	 je	 found_space		 ; yes, treat it like a space
;	 cmp	 al,"/" 		 ; is it a parm starter?
;	 je	 bad_path_parm		 ; yes, it's an error              ; @@05
;	 cmp	 al,"a" 		 ; find out if we have a lower case char
;	 jb	 copy_char						   ; @@14
;	 cmp	 al,"z"
;	 ja	 copy_char						   ; @@14
;	 sub	 al,"a"-"A"		 ; convert char to upper case	   ; @@14
;
;copy_char:
;	 mov	 in_middle,-1		 ; say that we made it to the middle
;	 stosb				 ; no, copy char into resident storage area
;	 jmp	 copy_args		 ; do it some more
;
;found_space:
;	 cmp	 in_middle,0		 ; set the space flag then go through
;	 jump	 E,copy_args		 ; loop some more
;
;found_end:
;	 cmp	 in_middle,0		 ; if I found the end of string but not
;	 jump	 E,display_dirs 	 ; in the middle, go display some dirs
;
;	 mov	 es:byte ptr [di],0	 ; null terminate the string
;	 mov	 in_middle,0
;	 cmp	 al,cr
;	 je	 past_trailing
;
;skip_trailing: 			 ; skip end spaces
;	 lodsb
;	 cmp	 al," "
;	 je	 skip_trailing
;	 cmp	 al,tab_char
;	 je	 skip_trailing
;	 cmp	 al,"/" 		 ; path and parm not together	   ; @@05
;	 je	 bad_path_parm						   ; @@05
;	 cmp	 al,cr			 ; only white space allowed at end
;	 jne	 bad_path
;past_trailing:
;
;	 cmp	 old_syntax,0		 ; go back to normal mode
;	 je	 normal_exit
;	 jmp	 exit_append2
;normal_exit:
;	 call	 ctrl_break_rest	 ; reset control break checking
;	 mov	 ax,0			 ; set string
;	 ret				 ; exit to COMMAND

bad_path:				; bad paath operand
;	mov	cx,len_path_error_msg	; length of string
;	lea	dx,path_error_msg
	call	sysloadmsg						 ;AN000;
									 ;AN000;
	mov	ax,3			; message number		 ;AN000;
	mov	bx,STDERR		; handle			 ;AN000;
	xor	cx,cx			; sub count			 ;AN000;
	xor	dl,dl			; no input			 ;AN000;
	mov	dh,-1			; message class 		 ;AN000;
;gga	call	sysdispmsg						 ;AN000;

	jmp	short bad_parmx

bad_path_parm:				; bad parameter 		  ; @@05
;	mov	cx,len_path_parm_error_msg   ; length of string 	  ; @@05
;	lea	dx,path_parm_error_msg					  ; @@05
	call	sysloadmsg						 ;AN000;
	mov	ax,3			; message number		 ;AN000;
	mov	bx,STDERR		; standard error		 ;AN000;
	xor	cx,cx			; sub count			 ;AN000;
	xor	dl,dl			; no input			 ;AN000;
	mov	dh,-1			; message class 		 ;AN000;
	jmp	short bad_parmx 					  ; @@05
bad_parm:				; bad parameter
;	mov	cx,len_parm_error_msg	; length of string
;	lea	dx,parm_error_msg
	call	sysloadmsg						 ;AN000;
									 ;AN000;
	mov	ax,3			; message number		 ;AN000;
	mov	bx,STDERR		; standard error		 ;AN000;
	xor	cx,cx			; sub count			 ;AN000;
	xor	dl,dl			; no input			 ;AN000;
	mov	dh,-1			; message class 		 ;AN000;

bad_parmx:				; bad parameter
	push	ds
	push	cs
	pop	ds
;	call	print_STDERR		; display error message
	lea	si,inv_parm		; point to msg parm			;an010;bgb
	call	sysdispmsg						 ;AN000;
	pop	ds
	call	ctrl_break_rest
	mov	al,1							  ; @@05
	call	terminate		; exit to DOS			  ; @@05

;	This code has been moved to main_begin				  ; @@07
;bad_append_ver:			; append version mismatch	  ; @@07
;	push	ds							  ; @@07
;	push	cs							  ; @@07
;	pop	ds							  ; @@07
;	mov	cx,len_bad_append_msg					  ; @@07
;	lea	dx,bad_append_msg	; bad app message		  ; @@07
;	call	print_STDERR						  ; @@07
;	lea	dx,crlf 		; carriage return, line feed	  ; @@07
;	mov	cx,crlf_len		; length of string		  ; @@07
;	call	print_STDERR						  ; @@07
;	pop	ds							  ; @@07
;	call	ctrl_break_rest 					  ; @@07
;	mov	ax,0feh 		; bad APPEND version		  ; @@05
;	call	terminate		; exit to DOS			  ; @@05

;	Display currently appended directories

display_dirs:
	call	address_status		; get working path		  ; @@03
	push	ds
	push	es
	pop	ds

	cmp	es:byte ptr[di],";"	; no append now
	je	no_dirs_appended

;	count the chars in the dir list, cx will hold the count

	mov	si,di
	sub	si,6+1			; move pointer to APPEND
	mov	dx,si			; save pointer to string
	xor	cx,cx

scanit:
	lodsb				; get character
	cmp	al,null 		; are we at end?
	je	print_it		; yes, print it
	inc	cx			; look at the next character
	jmp	scanit			; loop till we find the end

print_it:
	call	print_STDOUT		; display appended dirs
	push	cs
	pop	ds
	lea	dx,crlf 		; carriage return, line feed
	mov	cx,crlf_len		; length of string
	call	print_STDOUT
	pop	ds

exit_append:
	cmp	old_syntax,0		; process old format operands
	je	exit_append2
	mov	si,0081h		; set up rescan
	mov	ah,get_PSP
	call	int_21
	mov	ds,bx
	jmp	process_argsx

exit_append2:
	mov	old_syntax,0		; after first time this must be off
	call	ctrl_break_rest 	; reset control break checking
	mov	ax,-1			; no action
	ret				; exit to COMMAND

no_dirs_appended:
	push	cs
	pop	ds

	call	sysloadmsg						 ;AN000;
									 ;AN000;
	mov	ax,5			; message number		 ;AN000;
	mov	bx,STDERR		; handle			 ;AN000;
	xor	cx,cx			; sub count			 ;AN000;
	xor	dl,dl			; no input			 ;AN000;
	mov	dh,-1			; message class 		 ;AN000;
	call	sysdispmsg						 ;AN000;

;	lea	dx,no_append_msg	; no dirs message		 ;AN000;
;	mov	cx,len_no_append_msg	; length of string		 ;AN000;
;	call	print_STDOUT						 ;AN000;
	pop	ds
	jmp	exit_append2		; APPEND = = fix		    ;GGA

page
;-------------------------------------------------------------------
;	Getting here means that APPEND has not been loaded yet.  Get the
;	old vector, save it, and point the vector to the new routine.
;-------------------------------------------------------------------

replace_vector:

	push	ds
	mov	si,0081h		; point si to argument area
	mov	ah,get_PSP
	call	int_21
	mov	ds,bx

;	Process /X and /E parameters

skip_leading2:				; skip leading spaces
;	lodsb
;	cmp	al," "
;	je	skip_leading2
;	cmp	al,tab_char
;	je	skip_leading2
;	cmp	al,cr			; at end
;	jump	E,parms_done
;	cmp	al,"/"
;	jne	set_old_syntax

found_slash:
;	lodsb
;	cmp	al,"e"
;	je	slash_E
;	cmp	al,"E"
;	je	slash_E
;	cmp	al,"x"
;	je	slash_X
;	cmp	al,"X"
;	je	slash_X
bad_parmy:
;	pop	ds
;	jmp	bad_parm
bad_path_parmy:
;	pop	ds
;	jmp	bad_path_parm

slash_X:
;	test	mode_flags,X_mode	; no duplicates allowed
;	jnz	bad_parmy
;	or	mode_flags,X_mode
;	jmp	short slashx

slash_E:
;	test	mode_flags,E_mode	; no duplicates allowed
;	jnz	bad_parmy
;	or	mode_flags,E_mode
slashx:
;	jmp	skip_leading2		; loop some more
set_old_syntax:
;;	test	mode_flags,0		; no /? switches on old mode
;;	jne	bad_path_parmy
	mov	old_syntax,1
parms_done:
	pop	ds
	jmp	exit_append
page

set_vectors:				; set append hooks		  ; @@05
	push	es

;	Get INT 2f vector. Save to call older 2f handlers

	mov	ax,get_intfcn		; Get INT 2fh vector
	call	int_21
	mov	intfcn_offset,bx	; Save it
	mov	intfcn_segment,es

;	get int 21 vector

	mov	ax,get_vector		; Get INT 21h vector
	call	int_21
	mov	vector_offset,bx	; Save it
	mov	vector_segment,es
	pop	es

	push	ds							  ; @@08
	push	cs							  ; @@08
	pop	ds							  ; @@08
	lea	dx,intfcn_hook		; DS:DX = New INT 2fh vector
	mov	ax,set_intfcn		; Hook the interrupt
	call	int_21

	lea	dx,interrupt_hook	; DS:DX = New INT 21h vector
	mov	ax,set_vector		; Hook the interrupt
	call	int_21

	mov	dirlst_segment,cs	; save the address of the dirlist
	lea	dx,app_dirs
	mov	dirlst_offset,dx
	pop	ds							  ; @@08

	ret								  ; @@05

terminate:				; terminate to dos or return	  ; @@05
	cmp	res_append,0						  ; @@05
	jne	is_res							  ; @@05
	call	Release_Environment	; release environmental vector		;ac009; dms;
	mov	ah,term_proc		; return to DOS on first time	  ; @@05
	call	int_21							  ; @@05
is_res: 								  ; @@05
	mov	ax,-1			; set abort requested		  ; @@05
	jmp	abort_exit		; must go back to COMMAND	  ; @@05


print_STDOUT:
	mov	bx,STDOUT		; Standard output device handle
	mov	ah,awrite		; function code for write
	call	int_21
	ret

print_STDERR:
	mov	bx,STDERR		; Standard output device handle
	mov	ah,awrite
	call	int_21
	ret

Release_Environment:								;an007; dms;

	push	ax			;save regs				;an007; dms;
	push	bx			;					;an007; dms;
	push	es			;					;an007; dms;
	mov	ah,Get_PSP		; get the PSP segment			;an007; dms;
	call	int_21			; invoke INT 21h			;an007; dms;
	mov	es,bx			; BX contains PSP segment - put in ES	;an007; dms;
	mov	bx,word ptr es:[PSP_Env]; get segment of environmental vector	;an007; dms;
	mov	es,bx			; place segment in ES for Free Memory	;an007; dms;
	mov	ah,Free_Alloc_Mem	; Free Allocated Memory 		;an007; dms;
	int	21h			; invoke INT 21h			;an007; dms;
	pop	es			; restore regs				;an007; dms;
	pop	bx			;					;an007; dms;
	pop	ax			;					;an007; dms;

	ret				; return to caller			;an007; dms;

;=========================================================================
; Scan_For_Equal	: This routine scans the command line from the
;			  beginning until it encounters anything other
;			  than the equal, tab, or space characters.
;			  Register SI is sent back to the caller pointing
;			  to the character that does not meet the match
;			  criteria.
;
;	Inputs	: DS:SI - pointer to next parm
;
;	Outputs : SI	- adjusted to byte not matching the following:
;			  "="
;			  " "
;			  TAB
;
;	Author	: DS
;	Date	: 1/27/88
;	Version : DOS 3.4
;=========================================================================

Scan_For_Equal:

	push	ax				; save regs			;an008; dms;
	push	cx				;				;an008; dms;

	xor	cx,cx				; clear cx			;an008; dms;
	mov	cl,byte ptr ds:[80h]		; get length of command line	;an008; dms;

Scan_For_Equal_Loop:

	cmp	cx,0				; at end?			;an008; dms;
	jbe	Scan_For_Equal_Exit		; exit loop			;an008; dms;
	mov	al,byte ptr ds:[si]		; get 1st. character		;an008; dms;
	call	Chk_DBCS			; DBCS lead byte?		;an008; dms;
	jnc	Scan_For_Equal_No_DBCS		; no				;an008; dms;
		cmp	byte ptr ds:[si],81h	; blank lead byte		;an008; dms;
		jne	Scan_For_Equal_Exit	; exit with adjusted SI 	;an008; dms;
		cmp	byte ptr ds:[si+1],40h	; DBCS blank			;an008; dms;
		jne	Scan_For_Equal_Exit	; exit with adjusted SI 	;an008; dms;

		add	si,2			; yes - DBCS lead byte		;an008; dms;
		sub	dx,2			; decrease counter		;an008; dms;
		jmp	Scan_For_Equal_Loop

Scan_For_Equal_No_DBCS:

	cmp	al,"="				; = found?			;an008; dms;
	je	Scan_For_Equal_Next		; next character		;an008; dms;
	cmp	al,20h				; space?			;an008; dms;
	je	Scan_For_Equal_Next		; next character		;an008; dms;
	cmp	al,09h				; tab?				;an008; dms;
	je	Scan_For_Equal_Next		; next character		;an008; dms;
	jmp	Scan_For_Equal_Exit		; exit with adjusted SI 	;an008; dms;

Scan_For_Equal_Next:

	inc	si				; adjust ptr			;an008; dms;
	dec	cx				; decrease counter		;an008; dms;
	jmp	Scan_For_Equal_Loop		; continue loop 		;an008; dms;

Scan_For_Equal_Exit:

	pop	cx				;				;an008; dms;
	pop	ax				;				;an008; dms;

	ret					; return to caller		;an008; dms;



;=========================================================================	;an010;bgb
; do_parse_err		: This routine sets up for the display of a parse	;an010;bgb
;			  error, and displays the offending parameter.		;an010;bgb
;										;an010;bgb
;	Inputs	: DS:SI - points just past offending parm in command line	;an010;bgb
;										;an010;bgb
;	Outputs : si_off- parm for msg ret.					;an010;bgb
;		  si_seg- parm for msg ret.					;an010;bgb
;		  command line - hex zero at end of offending parm		;an010;bgb
;										;an010;bgb
;	Date	: 3/29/88							;an010;bgb
;	Version : DOS 4.0 (wow!)						;an010;bgb
;=========================================================================	;an010;bgb
do_parse_err	PROC								;an010;bgb
;;;;;;;;mov	ax,3 ;removed- parser handles this				;an010;bgb
	mov	bx,STDERR		; handle				;an010;bgb
;;;;;;;;xor	cx,cx			; sub count				;an010;bgb
	mov	cx,1			;display invalid parm			;an010;bgb
	xor	dl,dl			; no input				;an010;bgb
	mov	dh,02			; message class of parse error		;an010;bgb
;;;;;;;;mov	cs:si_off,81h		   ;initialize pointer			;an010;bgb
										;an010;bgb
	   dec	  si			;point to last byte of invalid parm	;an010;bgb
public decsi									;an010;bgb
decsi:	   cmp	   byte ptr [si],' '	;are we pointing to a space?		;an010;bgb
;	   $IF	   E,OR 		;if so, we dont want to do that 	;an010;bgb
	   JE $$LL1
	   cmp	   byte ptr [si],0dh	;are we pointing to CR? 		;an010;bgb
;	   $IF	   E			;if so, we dont want to do that 	;an010;bgb
	   JNE $$IF1
$$LL1:
	       dec   si 		;find the last byte of parm		;an010;bgb
	       jmp   decsi							;an010;bgb
;	   $ENDIF								;an010;bgb
$$IF1:
	   mov	   byte ptr [si+1],00	  ;zero terminate display string	;an010;bgb
nextsi: 									;an010;bgb
public nextsi									;an010;bgb
	   dec	   si			;look at previous char			;an010;bgb
	   cmp	   byte ptr [si],' '	;find parm separator			;an010;bgb
	   jnz	   nextsi		;loop until begin of parm found 	;an010;bgb
										;an010;bgb
	mov	cs:si_off,si		;mov si into display parms		;an010;bgb
	mov	cs:si_seg,ds		   ;initialize pointer			;an010;bgb
	ret					; return to caller		;an010;bgb
do_parse_err	ENDP								;an010;bgb


;-------------------------------------------------------------------
;
;-------------------------------------------------------------------

MSG_SERVICES <LOADmsg>
MSG_SERVICES <APPEND.CLB,APPEND.CL2,APPEND.CTL>

end_address:				; this is the end of the TSR stuff		 ;AN004;

include parse.asm			; include the parser code
include msgdcl.inc

cseg	ends
sseg	segment para stack 'STACK'
	assume	ss:sseg
	dw	512 dup(0)
mystack dw	0
sseg	ends



	end	main_begin
