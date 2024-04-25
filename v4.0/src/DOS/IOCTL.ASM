;	SCCSID = @(#)IOCTL.INC	1.15 85/09/05
TITLE	IOCTL - IOCTL system call
NAME	IOCTL

;
;
; IOCTL system call.
;
;
; $IOCTL
;
;   Revision history:
;
;	Created: ARR 4 April 1983
;
;	GenericIOCTL added:		KGS	22 April 1985
;
;	A000	version 4.00	Jan. 1988



.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

CODE	SEGMENT BYTE PUBLIC  'CODE'
	ASSUME	SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
include ioctl.inc
include ifssym.inc			 ;AN000;
.cref
.list

	i_need	THISCDS,DWORD
	i_need	IOCALL,BYTE
	i_need	IOMED,BYTE
	i_need	IOSCNT,WORD
	i_need	IOXAD,DWORD
	I_need	RetryCount,WORD
	I_need	RetryLoop,WORD
	I_need	EXTERR_LOCUS,BYTE
	I_need	OPENBUF,BYTE
	I_need	ExtErr,WORD
	I_need	DrvErr,BYTE
	I_need	USER_IN_AX,WORD 		;AN000;
	I_need	Temp_Var2,WORD			;AN000;

BREAK <IOCTL - munge on a handle to do device specific stuff>

;
;   Assembler usage:
;	    MOV     BX, Handle
;	    MOV     DX, Data
;
;	(or LDS     DX,BUF
;	    MOV     CX,COUNT)
;
;	    MOV     AH, Ioctl
;	    MOV     AL, Request
;	    INT     21h
;
;   AH = 0  Return a combination of low byte of sf_flags and device driver
;	    attribute word in DX, handle in BX:
;	    DH = high word of device driver attributes
;	    DL = low byte of sf_flags
;	 1  Set the bits contained in DX to sf_flags.  DH MUST be 0.  Handle
;	    in BX.
;	 2  Read CX bytes from the device control channel for handle in BX
;	    into DS:DX.  Return number read in AX.
;	 3  Write CX bytes to the device control channel for handle in BX from
;	    DS:DX.  Return bytes written in AX.
;	 4  Read CX bytes from the device control channel for drive in BX
;	    into DS:DX.  Return number read in AX.
;	 5  Write CX bytes to the device control channel for drive in BX from
;	    DS:DX.  Return bytes written in AX.
;	 6  Return input status of handle in BX. If a read will go to the
;	    device, AL = 0FFh, otherwise 0.
;	 7  Return output status of handle in BX. If a write will go to the
;	    device, AL = 0FFh, otherwise 0.
;	 8  Given a drive in BX, return 1 if the device contains non-
;	    removable media, 0 otherwise.
;	 9  Return the contents of the device attribute word in DX for the
;	    drive in BX.  0200h is the bit for shared.	1000h is the bit for
;	    network. 8000h is the bit for local use.
;	 A  Return 8000h if the handle in BX is for the network or not.
;	 B  Change the retry delay and the retry count for the system. BX is
;	    the count and CX is the delay.
;
;   Error returns:
;	    AX = error_invalid_handle
;	       = error_invalid_function
;	       = error_invalid_data
;
;-------------------------------------------------------------------------------
;
;   This is the documentation copied from DOS 4.0 it is much better
;   than the above
;
;	There are several basic forms of IOCTL calls:
;
;
;	** Get/Set device information:	**
;
;	ENTRY	(AL) = function code
;		  0 - Get device information
;		  1 - Set device information
;		(BX) = file handle
;		(DX) = info for "Set Device Information"
;	EXIT	'C' set if error
;		  (AX) = error code
;		'C' clear if OK
;		  (DX) = info for "Get Device Information"
;	USES	ALL
;
;
;	**  Read/Write Control Data From/To Handle  **
;
;	ENTRY	(AL) = function code
;		  2 - Read device control info
;		  3 - Write device control info
;		(BX) = file handle
;		(CX) = transfer count
;		(DS:DX) = address for data
;	EXIT	'C' set if error
;		  (AX) = error code
;		'C' clear if OK
;		  (AX) = count of bytes transfered
;	USES	ALL
;
;
;	**  Read/Write Control Data From/To Block Device  **
;
;	ENTRY	(AL) = function code
;		  4 - Read device control info
;		  5 - Write device control info
;		(BL) = Drive number (0=default, 1='A', 2='B', etc)
;		(CX) = transfer count
;		(DS:DX) = address for data
;	EXIT	'C' set if error
;		  (AX) = error code
;		'C' clear if OK
;		  (AX) = count of bytes transfered
;	USES	ALL
;
;
;	**  Get Input/Output Status  **
;
;	ENTRY	(AL) = function code
;		  6 - Get Input status
;		  7 - Get Output Status
;		(BX) = file handle
;	EXIT	'C' set if error
;		  (AX) = error code
;		'C' clear if OK
;		  (AL) = 00 if not ready
;		  (AL) = FF if ready
;	USES	ALL
;
;
;	**  Get Drive Information  **
;
;	ENTRY	(AL) = function code
;		  8 - Check for removable media
;		  9 - Get device attributes
;		(BL) = Drive number (0=default, 1='A', 2='B', etc)
;	EXIT	'C' set if error
;		  (AX) = error code
;		'C' clear if OK
;		  (AX) = 0/1 media is removable/fixed (func. 8)
;		  (DX) = device attribute word (func. 9)
;	USES	ALL
;
;
;	**  Get Redirected bit	**
;
;	ENTRY	(AL) = function code
;		  0Ah - Network stuff
;		(BX) = file handle
;	EXIT	'C' set if error
;		  (AX) = error code
;		'C' clear if OK
;		  (DX) = SFT flags word, 8000h set if network file
;	USES	ALL
;
;
;	**  Change sharer retry parameters  **
;
;	ENTRY	(AL) = function code
;		  0Bh - Set retry parameters
;		(CX) = retry loop count
;		(DX) = number of retries
;	EXIT	'C' set if error
;		  (AX) = error code
;		'C' clear if OK
;	USES	ALL
;
;
;   =================================================================
;
;	**  New Standard Control  **
;
;	ALL NEW IOCTL FACILITIES SHOULD USE THIS FORM.	THE OTHER
;	FORMS ARE OBSOLETE.
;
;   =================================================================
;
;	ENTRY	(AL) = function code
;		  0Ch - Control Function subcode
;		(BX) = File Handle
;		(CH) = Category Indicator
;		(CL) = Function within category
;		(DS:DX) = address for data, if any
;		(SI) = Passed to device as argument, use depends upon function
;		(DI) = Passed to device as argument, use depends upon function
;	EXIT	'C' set if error
;		  (AX) = error code
;		'C' clear if OK
;		  (SI) = Return value, meaning is function dependent
;		  (DI) = Return value, meaning is function dependent
;		  (DS:DX) = Return address, use is function dependent
;	USES	ALL
;
;    ============== Generic IOCTL Definitions for DOS 3.2 ============
;     (See dos/ioctl.mac for more info)
;
;	ENTRY	(AL) = function code
;		  0Dh - Control Function subcode
;		(BL) = Drive Number (0 = Default, 1= 'A')
;		(CH) = Category Indicator
;		(CL) = Function within category
;		(DS:DX) = address for data, if any
;		(SI) = Passed to device as argument, use depends upon function
;		(DI) = Passed to device as argument, use depends upon function
;
;	EXIT	'C' set if error
;		  (AX) = error code
;		'C' clear if OK
;		  (DS:DX) = Return address, use is function dependent
;	USES	ALL
;

	procedure   $IOCTL,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING
	MOV	SI,DS			; Stash DS for calls 2,3,4 and 5
	context DS
	CMP	AL,3
	JBE	ioctl_check_char	; char	device
	JMP	ioctl_check_block	; Block device
ioctl_check_char:
	invoke	SFFromHandle		; ES:DI -> SFT
	JNC	ioctl_check_permissions ; have valid handle
ioctl_bad_handle:
	error	error_invalid_handle

ioctl_check_permissions:
	CMP	AL,2
	JAE	ioctl_control_string
	CMP	AL,0
	MOV	AL,BYTE PTR ES:[DI.sf_flags]; Get low byte of flags
	JZ	ioctl_read		; read the byte
	PUSH	DX			;AN000;MS.
	AND	DH,0FEH 		;AN000;MS.allow DH=01H
	POP	DX			;AN000;MS.
	JZ	ioctl_check_device	; can I set with this data?
	error	error_invalid_data	; no DH <> 0

ioctl_bad_funj2:
	JMP	ioctl_bad_fun

ioctl_check_device:
	TEST	AL,devid_device 	; can I set this handle?
	JZ	do_exception		; no, it is a file.
	OR	DL,devid_device 	; Make sure user doesn't turn off the
					;   device bit!! He can muck with the
					;   others at will.
	MOV	[EXTERR_LOCUS],errLOC_SerDev
	MOV	BYTE PTR ES:[DI.sf_flags],DL  ;AC000;MS.; Set flags
do_exception:
	OR	BYTE PTR ES:[DI.sf_flags+1],DH;AN000;MS.;set 100H bit for disk full

	transfer    SYS_RET_OK





ioctl_read:
	MOV	[EXTERR_LOCUS],errLOC_Disk
	XOR	AH,AH
	TEST	AL,devid_device 	; Should I set high byte
	JZ	ioctl_no_high		; no
	MOV	[EXTERR_LOCUS],errLOC_SerDev
	LES	DI,ES:[DI.sf_devptr]	; Get device pointer
	MOV	AH,BYTE PTR ES:[DI.SDEVATT+1]	; Get high byte
ioctl_no_high:
	MOV	DX,AX
	invoke	get_user_stack
	MOV	[SI.user_DX],DX
	transfer    SYS_RET_OK

ioctl_control_string:
	TEST	ES:[DI.sf_flags],devid_device	; can I?
	JNZ	ioctl_ctl_str_1
	JMP	ioctl_bad_fun			; No it is a file
ioctl_ctl_str_1:
	TEST	ES:[DI.sf_flags],sf_isnet	;AN000;IFS.; IFS ?
	JZ	localrw 			;AN000;IFS.; no
	JMP	callifs 			;AN000;IFS.; call IFS
localrw:
	MOV	[EXTERR_LOCUS],errLOC_SerDev
	LES	DI,ES:[DI.sf_devptr]	; Get device pointer
	XOR	BL,BL			; Unit number of char dev = 0
	JMP	ioctl_do_string

ioctl_get_devj:
	JMP	ioctl_get_dev

ioctl_check_block:
	DEC	AL
	DEC	AL			; 4=2,5=3,6=4,7=5,8=6,9=7,10=8,11=9
	CMP	AL,3
	JBE	ioctl_get_devj
	CMP	AL,6
	JAE	ioctl_rem_media_check

	MOV	AH,1
	SUB	AL,4			; 6=0,7=1
	JZ	ioctl_get_status
	MOV	AH,3
ioctl_get_status:
	PUSH	AX
	invoke	GET_IO_SFT
	POP	AX
	JNC	DO_IOFUNC
	JMP	ioctl_bad_handle	; invalid SFT

DO_IOFUNC:
	invoke	IOFUNC
	MOV	AH,AL
	MOV	AL,0FFH
	JNZ	ioctl_status_ret
	INC	AL
ioctl_status_ret:
	transfer SYS_RET_OK

ioctl_rem_media_check:			; 4=2,5=3,6=4,7=5,8=6,9=7,10=8,11=9
	JE	ioctl_rem_mediaj

	SUB	AL,7			; 9=0,10=1,11=2,12=3,13=4,14=5,15=6
	JNZ	Rem_med_chk_1
	JMP	Ioctl_Drive_attr

ioctl_rem_mediaj:
	jmp	ioctl_rem_media

ioctl_bad_funj4:
	jmp	ioctl_bad_fun

Rem_med_chk_1:

	DEC	AL			; 10=0,11=1,12=2,13=3,14=4,15=5
	jnz	Set_Retry_chk
	Jmp	Ioctl_Handle_redirj

Set_Retry_chk:
	DEC	AL			; 11=0,12=1,13=2,14=3,15=4
	JZ	Set_Retry_Parameters

	DEC	AL			; 12=0,13=1,14=2,15=3
	JZ	GENERICIOCTLHANDLE

	DEC	AL			; 13=0,14=1,15=2
	JZ	GENERICIOCTL

	CMP	AL,2
	JA	ioctl_bad_funj4
	JMP	ioctl_drive_owner
Set_Retry_Parameters:
	MOV	RetryLoop,CX		; 0 retry loop count allowed
	OR	DX,DX			; zero retries not allowed
	JNZ	goodtr
	JMP	IoCtl_Bad_Fun
goodtr:
	MOV	RetryCount,DX		; Set new retry count
doneok:
	transfer	Sys_Ret_Ok	; Done

; Generic IOCTL entry point.
;	here we invoke the Generic IOCTL using the IOCTL_Req structure.
;	SI:DX -> Users Device Parameter Table
;	IOCALL -> IOCTL_Req structure
GENERICIOCTLHANDLE:
	invoke	SFFromHandle		; Get SFT for device.
	jnc	goodh
	JMP	ioctl_bad_handlej
goodh:
;	test	word ptr [DI.sf_flags],sf_isnet
	CALL	TEST_IFS_REMOTE 	;AN000;;IFS. test if remote
	JZ	okokok			;AN000;;IFS.
	jmp	ioctl_bad_fun		; Cannot do this over net.
okokok:
	TEST	[DI.sf_flags],sf_isnet	;AN000;IFS.; local IFS
	JNZ	callifs 		;AN000;IFS.; yes


	mov	[EXTERR_LOCUS],ErrLOC_Serdev
	les	di,es:[di.sf_devptr]	; Get pointer to device.
	jmp	short Do_GenIOCTL

GENERICIOCTL:
	mov	[EXTERR_LOCUS],ErrLOC_Disk
	cmp	ch,IOC_DC		; Only disk devices are allowed to use
	jne	ioctl_bad_fun		; no handles with Generic IOCTL.
	CALL	Check_If_Net		; ES:DI := Get_hdr_block of device in BL
	JNZ	ioctl_bad_fun		; There are no "net devices", and they
	PUSH	ES			;   certainly don't know how to do this ;AN000;
	PUSH	DI				 ;AN000;IFS.
	LES	DI,[THISCDS]			 ;AN000;IFS.	 ;
	TEST	ES:[DI.curdir_flags],curdir_isnet;AN000;IFS.	 ; local IFS ?
	POP	DI				 ;AN000;IFS.
	POP	ES				 ;AN000;IFS.
	JZ	Do_GenIOCTL			 ;AN000;IFS.	 ; no
callifs:
	CMP	byte ptr [User_In_AX+1],69H  ;AN000;	     ;IFS.
	JNZ	is44xx			     ;AN000;	     ;IFS.
	MOV	AX,440DH		     ;AN000;	     ;IFS.
	PUSH	AX			     ;AN000;	     ;IFS.
	JMP	SHORT callrose		     ;AN000;	     ;IFS.
is44xx:
	PUSH	[User_In_AX]		     ;AN000;	     ;IFS. call IFSFUNC
callrose:
	MOV	DS,SI			     ;AN000;	     ;IFS.
	MOV	AX,(multNET SHL 8) or  43    ;AN000;	     ;IFS.
	INT	2FH			     ;AN000;	     ;IFS.
	POP	BX			     ;AN000;	     ;IFS.
	JNC	doneok			     ;AN000;	     ;IFS.
	MOV	DI,AX			     ;AN000;	     ;IFS.
	JMP	device_err		     ;AN000;	     ;IFS.
Do_GenIOCTL:
	test	ES:[DI.SDEVATT],DEV320	; Can device handle Generic IOCTL funcs
	jz	ioctl_bad_fun
	PUSH	ES			; DEVIOCALL2 expects Device header block
	PUSH	DI			; in DS:SI
	;set up Generic IOCTL Request Block
	MOV	byte ptr IOCALL.ReqLen,(size IOCTL_Req)
	MOV	byte ptr IOCALL.ReqFunc,GENIOCTL
	MOV	byte ptr IOCALL.ReqUnit,BL
	MOV	byte ptr IOCALL.MajorFunction,CH
	MOV	byte ptr IOCALL.MinorFunction,CL
	MOV	word ptr IOCALL.Reg_SI,SI
	MOV	word ptr IOCALL.Reg_DI,DI
	MOV	word ptr IOCALL.GenericIOCTL_Packet,DX
	MOV	word ptr IOCALL.GenericIOCTL_Packet + 2,SI

	MOV	BX,offset DOSGROUP:IOCALL

	PUSH	SS
	POP	ES

ASSUME DS:NOTHING			; DS:SI -> Device header.
	POP	SI
	POP	DS
	jmp	ioctl_do_IO		; Perform Call to device driver

IOCtl_Handle_RedirJ:
	JMP	IOCTL_Handle_Redir
ioctl_bad_fun:
	error	error_invalid_function

ioctl_bad_handlej:
	jmp	ioctl_bad_handle

; Function 8
ioctl_rem_media:
	CALL	Check_If_Net
	JNZ	ioctl_bad_fun		; There are no "net devices", and they
					;   certainly don't know how to do this
					;   call.
	TEST	ES:[DI.SDEVATT],DEVOPCL ; See if device can
	JZ	ioctl_bad_fun		; NO
	MOV	[IOCALL.REQFUNC],DEVRMD
	MOV	AL,REMHL
	MOV	AH,BL			; Unit number
	MOV	WORD PTR [IOCALL.REQLEN],AX
	XOR	AX,AX
	MOV	[IOCALL.REQSTAT],AX
	PUSH	ES
	POP	DS
ASSUME	DS:NOTHING
	MOV	SI,DI			; DS:SI -> driver
	PUSH	SS
	POP	ES
	MOV	BX,OFFSET DOSGROUP:IOCALL   ; ES:BX -> Call header
	SaveReg <DS,SI>
	invoke	DEVIOCALL2
	RestoreReg <SI,DS>
	MOV	AX,[IOCALL.REQSTAT]	; Get Status word
	AND	AX,STBUI		; Mask to busy bit
	MOV	CL,9
	SHR	AX,CL			; Busy bit to bit 0
	transfer    SYS_RET_OK

; Function 9
Ioctl_Drive_attr:

;;;;;	MOV	AL,BL			;AC000;; Drive
;;;;;	invoke	GETTHISDRV		;AC000;
;;;;;					;AC000;
;;;;;	JC	ioctl_drv_err		; drive not valid
	call	Get_Driver_BL
	JC	ioctl_drv_err		; drive not valid
	MOV	AX,[Temp_Var2]		;AN000;IFS.
	mov	dx,word ptr es:[di.SDEVATT]	; get device attribute word
	MOV	BL,AL			; Phys letter to BL (A=0)
	LES	DI,[THISCDS]
;;;;;	TEST	ES:[DI.curdir_flags],curdir_isnet
	CALL	TEST_IFS_REMOTE2	;AN000;IFS. test if remote
	JZ	IOCTLShare
	OR	DX,1000h
IOCTLShare:
	Context DS
ASSUME	DS:NOTHING
	MOV	SI,OFFSET DOSGROUP:OPENBUF
	ADD	BL,"A"
	MOV	[SI],BL
	MOV	WORD PTR [SI+1],003AH	; ":",0
	MOV	AX,0300H
	CLC
	INT	int_IBM
	JNC	ioctlLocal		; Not shared
	OR	DX,0200H		; Shared, bit 9
IOCTLLocal:
	TEST	ES:[DI].curdir_flags,curdir_local
	JZ	ioctl_set_dx
	OR	DX,8000h

ioctl_set_DX:
	invoke	get_user_stack
	MOV	[SI.user_DX],DX
	transfer    SYS_RET_OK

ioctl_drv_err:
	MOV	AL,[DrvErr]		;AN000;IFS. DrvErr is saved in GetThisDrv
	transfer SYS_RET_ERR		;AN000;IFS.

; Function 10
Ioctl_Handle_redir:
	invoke	SFFromHandle		; ES:DI -> SFT
	JNC	ioctl_got_sft		; have valid handle
	error	error_invalid_handle

ioctl_got_sft:
	MOV	DX,ES:[DI.sf_flags]	; Get flags
	JMP	ioctl_set_DX

ioctl_bad_funj:
	JMP	ioctl_bad_fun

ioctl_get_dev:
	DOSAssume   CS,<DS>,"IOCTL/IOCtl_Get_Dev"
	CALL	Check_If_Net
	JNZ	ioctl_bad_funj		; There are no "net devices", and they
					;   certainly don't know how to do this
					;   call.
ioctl_do_string:
	TEST	ES:[DI.SDEVATT],DEVIOCTL; See if device accepts control
	JZ	ioctl_bad_funj		; NO
	DEC	AL
	DEC	AL
	JZ	ioctl_control_read
	MOV	[IOCALL.REQFUNC],DEVWRIOCTL
	JMP	SHORT ioctl_control_call
ioctl_control_read:
	MOV	[IOCALL.REQFUNC],DEVRDIOCTL
ioctl_control_call:
	MOV	AL,DRDWRHL
ioctl_setup_pkt:
	MOV	AH,BL			; Unit number
	MOV	WORD PTR [IOCALL.REQLEN],AX
	XOR	AX,AX
	MOV	[IOCALL.REQSTAT],AX
	MOV	[IOMED],AL
	MOV	[IOSCNT],CX
	MOV	WORD PTR [IOXAD],DX
	MOV	WORD PTR [IOXAD+2],SI
	PUSH	ES
	POP	DS
ASSUME	DS:NOTHING
	MOV	SI,DI			; DS:SI -> driver
	PUSH	SS
	POP	ES
	MOV	BX,OFFSET DOSGROUP:IOCALL   ; ES:BX -> Call header
ioctl_do_IO:
	invoke	DEVIOCALL2
	TEST	[IOCALL.REQSTAT],STERR	    ;Error?
	JNZ	Ioctl_string_err
	MOV	AX,[IOSCNT]		; Get actual bytes transferred
	transfer    SYS_RET_OK

Ioctl_string_err:
	MOV	DI,[IOCALL.REQSTAT]	;Get Error
device_err:
	AND	DI,STECODE		; mask out irrelevant bits
	MOV	AX,DI
	invoke	SET_I24_EXTENDED_ERROR
	mov	ax, cs:extErr
	transfer    SYS_RET_ERR

Get_Driver_BL:
	DOSAssume   CS,<DS>,"Get_Driver_BL"
	ASSUME	ES:NOTHING
; BL is drive number (0=default)
; Returns pointer to device in ES:DI, unit number in BL if carry clear
; No regs modified

	PUSH	AX
	MOV	AL,BL			; Drive
	invoke	GETTHISDRV
	JNC	ioctl_goodrv		;AC000;IFS.
	CMP	AL,error_not_dos_disk	;AN000;IFS.   if unknow media then
	JZ	ioctl_goodrv		;AN000;IFS.	 let it go
	STC				;AN000;IFS.   else
	JMP	SHORT ioctl_bad_drv	;AN000;IFS.	 error
ioctl_goodrv:
	XOR	BL,BL			; Unit zero on Net device
	MOV	[EXTERR_LOCUS],errLOC_Net
	LES	DI,[THISCDS]
;	TEST	ES:[DI.curdir_flags],curdir_isnet
	CALL	TEST_IFS_REMOTE2	;AN000;;IFS. test if remote
	LES	DI,ES:[DI.curdir_devptr]; ES:DI -> Dpb or net dev
	JNZ	got_dev_ptr		; Is net
	MOV	[EXTERR_LOCUS],errLOC_Disk
	MOV	BL,ES:[DI.dpb_UNIT]	; Unit number
	LES	DI,ES:[DI.dpb_driver_addr]  ; Driver addr
got_dev_ptr:
	CLC
	MOV	[Temp_Var2],AX		     ;AN000;IFS.
ioctl_bad_drv:
	POP	AX
	return

;
; Checks if the device is over the net or not. Returns result in ZERO flag.
; If no device is found, the return address is popped off the stack, and a
; jump is made to ioctl_drv_err.
;
; On Entry:
; Registers same as those for Get_Driver_BL
;
; On Exit:
; ZERO flag	- set if not a net device
;		- reset if net device
; ES:DI -> the device
;
Check_If_Net:
	CALL	Get_Driver_BL
	JC	ioctl_drv_err_pop	; invalid drive letter
entry TEST_IFS_REMOTE2
	PUSH	ES
	PUSH	DI
	LES	DI,[THISCDS]
	TEST	ES:[DI.curdir_flags],curdir_isnet
	JZ	belocal 		       ;AN000;	 ;IFS.
	LES	DI,ES:[DI.curdir_ifs_hdr]      ;AN000;	 ;IFS.	test if remote
TEST_REMOTE:				       ;AN000;
	TEST	ES:[DI.ifs_attribute],IFSREMOTE;AN000;	 ;IFS.
belocal:
	POP	DI
	POP	ES
	ret

ioctl_drv_err_pop:
	pop	ax			; pop off return address
	jmp	ioctl_drv_err

ioctl_bad_funj3:
	jmp	ioctl_bad_fun

ioctl_string_errj:
	jmp	ioctl_string_err

; Functions 14 and 15
ioctl_drive_owner:
	Call	Check_If_Net
	JNZ	ioctl_bad_funj3 	; There are no "net devices", and they
					;   certainly don't know how to do this
					;   call.
	TEST	ES:[DI.SDEVATT],DEV320	; See if device can handle this
	JZ	ioctl_bad_funj3 	; NO
	dec	al
	jz	GetOwner
	MOV	[IOCALL.REQFUNC],DEVSETOWN
	jmp	short ioctl_do_own
GetOwner:
	MOV	[IOCALL.REQFUNC],DEVGETOWN
ioctl_do_own:
	MOV	AL,OWNHL
	MOV	AH,BL			; Unit number
	MOV	WORD PTR [IOCALL.REQLEN],AX
	XOR	AX,AX
	MOV	[IOCALL.REQSTAT],AX
	PUSH	ES
	POP	DS
ASSUME	DS:NOTHING
	MOV	SI,DI			; DS:SI -> driver
	PUSH	SS
	POP	ES
	MOV	BX,OFFSET DOSGROUP:IOCALL   ; ES:BX -> Call header
	SaveReg <DS,SI>
	invoke	DEVIOCALL2
	RestoreReg <SI,DS>
	test	[IOCALL.REQSTAT],STERR
	jnz	ioctl_string_errj
	MOV	AL,BYTE PTR [IOCALL.REQUNIT]	; Get owner returned by device
						; owner returned is 1-based.
	transfer    SYS_RET_OK

EndProc $IOCTL


;Input: ES:DI -> SFT
;Functions: test if a remote file
;Output: Z flag set, local file
;

	procedure   TEST_IFS_REMOTE,NEAR  ;AN000;
	ASSUME	DS:NOTHING,ES:NOTHING	  ;AN000;

	TEST	ES:[DI.sf_flags],sf_isnet ;AN000;;IFS.	ifs ?
	JZ	nonifs			  ;AN000;;IFS.	no
	PUSH	ES		       ;AN000;;IFS. save regs
	PUSH	DI		       ;AN000;;IFS.
	LES	DI,ES:[DI.sf_IFS_hdr]  ;AN000;;IFS. get ifs header
	JMP	TEST_REMOTE	       ;AN000;;IFS.
nonifs: 			       ;AN000;
	return			       ;AN000;;IFS.
EndProc TEST_IFS_REMOTE 	       ;AN000;

CODE ENDS
END
