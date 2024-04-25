

	page	58,132
;******************************************************************************
	TITLE	ErrHndlr - Error Handler 
;******************************************************************************
;   (C) Copyright MICROSOFT Corp. 1986
;
;    Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;    Module:	ErrHndlr - Recover from exception and priveledged operation errors
;
;    Version:	0.04
;
;    Date:	June 6,1986
;
;    Authors:	Brad Tate    
;
;******************************************************************************
;
;  CHANGES:
;
;    DATE     REVISION			DESCRIPTION
;  --------   --------   ------------------------------------------------------
;  06/06/86   Original 
;  06/28/86   0.02	Name changed from MEMM386 to MEMM
;  06/28/86   0.02	Removed STI at end of ErrHndlr
;  06/28/86   0.02	Changed error # display to leading zeroes
;  07/06/86   0.04	Changed assume to DGROUP
;
;******************************************************************************
	page
;******************************************************************************
;
;  Functional description:
;
;	This module contains the code that displays an error message and
;	asks the user to continue or reboot.
;
;******************************************************************************
	page
.386P
;
 	include	vdmseg.inc
	include	vdmsel.inc
	include	vm386.inc
	include	kbd.inc
;******************************************************************************
;  	Public Declarations
;******************************************************************************
;
	public	ErrHndlr		; Display message and continue or reboot
	public	Error_Flag
;******************************************************************************
;  	Externs
;******************************************************************************
_TEXT	segment
	extrn	RetReal:near		; return to real mode
	extrn	egetc:near		; get keyboard character
	extrn	WaitKBD:near		; wait for keyboard ready
_TEXT	ends

_DATA	segment
	extrn	powr10:word		; power of 10's table
	extrn	POE_Mess:byte		; privileged operation error
	extrn	POE_Num:byte 		; where to put error code
	extrn	POE_Len:abs		; length of message
	extrn	EXCPE_Mess:byte		; exception error message
	extrn	EXCPE_Num:byte		; where to put error code
	extrn	EXCPE_CS:byte		; where to put CS
	extrn	EXCPE_EIP:byte		; where to put EIP
	extrn	EXCPE_ERR:byte		; where to put ERR
	extrn	EXCPE_Len:abs		; length of message
_DATA	ends
;
romdata	segment	use16 at 40h
	org	71h
fBreak	db	?
fReset	dw	?
romdata	ends
;
;******************************************************************************
;  	Equates
;******************************************************************************
;					   
MASTER   	=	0A1H		; Master interrupt i/o port
SLAVE        	=	021H		; Slave interrupt i/o port
NMI     	=	070H		; Non-Maskable interrupt i/o port
DIS_MSTSLV  	=	00H		; Value to write to disable master/slave
DIS_NMI         =	080H		; Value to write to disable NMI
ENA_NMI		=	008H		; Value to write to enable NMI
B		=	48 		; make code for B
C		=	46 		; make code for C
ENTER		=	28 		; make code for enter key
ATTR		=	07		; attribute for write string
WRSTR		=	1301h		; write string function code (format 1)
CPOSN		=	5*256+0		; cursor position to write
;
;
;******************************************************************************
;		LOCAL DATA     
;******************************************************************************
_DATA	segment
Error_Flag	dw	0		; flags for Instruction Prefixes
masterp		db	0		; save master port value
slavep		db	0		; save slave port value
mode		db	0		; save mode
boot		db	0		; value to reboot
continue	db	0		; value to continue

GPsavERR	dw	0		; GP fault Error Code save
GPsavEIP	dd	0		; GP fault EIP save
GPsavCS		dw	0		; GP fault CS save

_DATA	ends
;	
;******************************************************************************
;
;	ErrHndlr - displays the appropriate error message and prompts the
;		    user for a character to continue or reboot.  The screen
;		    is cleared by this routine.  If the user chooses to
;		    continue, the system is in real mode.
;
;	entry:	ax = 0 => Privileged operation error
;		ax = 1 => Exception error
;		bx = error number to display
;
;	exit:	either reboot, or exit in "real" mode with CLI
;
;	used:	none
;
;	stack: 
;
;******************************************************************************
_TEXT	segment
	ASSUME	CS:_TEXT, DS:DGROUP, ES:DGROUP
ErrHndlr	proc	near
;
; save fault infos
;
	push	eax
	push	ds
	push	VDMD_GSEL
	pop	ds
	mov	eax, dword ptr [bp.VTFO]		; error code
	mov	[GPsavERR], ax
	mov	eax, dword ptr [bp.VTFOE+VMTF_EIP]	; EIP
	mov	[GPsavEIP], eax
	mov	ax, word ptr [bp.VTFOE+VMTF_CS]		; CS
	mov	[GPsavCS], ax
	pop	ds
	pop	eax

  	call	RetReal			; return to real mode
;
	push	ax
	push	bx
	push	cx
	push	dx
	push	bp
	push	di
;
	push	ax			; save input to this routine
	in	al,MASTER		; get value of master interrupt port
	mov	[masterp],al		; save it
	in	al,SLAVE		; get value of slave interrupt port
	mov	[slavep],al		; save it
	mov	al,DIS_MSTSLV		; value to disable master/slave int
	out	MASTER,al		; disable master
	out	SLAVE,al		; disable slave
	mov	al,DIS_NMI		; value to disable NMI
	out	NMI,al
kbdbusy:
	call	egetc			; q: is there stuff in keyboard buffer?
	jnz	kbdbusy			; y: get it and pitch it
					; n: continue
	pop	ax			; get entry condition
	or	ax,ax			; q: privileged error?
	jnz	excep			; n: exception error
	mov	bp,offset DGROUP:POE_Mess ; y: privileged error
	mov	cx,POE_Len
	mov	di,offset DGROUP:POE_Num; error number location
	mov	ax,bx			; error number in ax
	call	b2asc10			; convert to ascii
	mov	[boot],B		; key to boot
	mov	[continue],C		; key to continue
	jmp	skip_exc		; skip exception stuff
excep:
	mov	bp,offset DGROUP:EXCPE_Mess	; n: load up exception error
	mov	cx,EXCPE_Len		; length of msg
	mov	di,offset DGROUP:EXCPE_Num	; error number location
	mov	ax,bx			; error number in ax
	call	b2asc10			; convert to ascii
	mov	di,offset DGROUP:EXCPE_CS
	mov	ax,[GPsavCS]
	call	b2asc16
	mov	di,offset DGROUP:EXCPE_EIP
	mov	eax,[GPsavEIP]
	ror	eax,16
	call	b2asc16
	ror	eax,16
	call	b2asc16
	mov	di,offset DGROUP:EXCPE_ERR
	mov	ax,[GPsavERR]
	call	b2asc16
	mov	[boot],ENTER		; key to reboot
	mov	[continue],0ffh		; can't continue
skip_exc:
	mov	ah,0fh			; read video state
	int	10h
	mov	[mode],al		; save mode
;	mov	ax,3			; set to mode 3
;	int	10h			; standard 80 x 25 color
	mov	dx,CPOSN		; cursor position
	mov	bl,ATTR			; attribute
	mov	ax,WRSTR		; write string function code
	int	10h			; do it
	cli				; make sure int 10 didn't enable
key_loop:
	call	egetc			; get a character
	jz	key_loop		; nothing there yet
	cmp	al,[continue]		; q: continue?
	je	err_cont		; y
	cmp	al,[boot]		; q: boot?
	jne	key_loop		; n: try again
;******************************************************************************
;
;		Reboot system
;
;******************************************************************************
	assume	ds:romdata
	mov	ax,romdata
	mov	ds,ax			; ds = romdata segment
	mov	[freset],0		; cold restart
	mov	al,0fh or 80h		; shutdown byte address/disable NMI
	out	70h,al			; write CMOS address
	jmp	short $+2		; delay
	mov	al,0h			; shutdown code 0 = processor reset
	out	71h,al			; write shutdown code to shutdown byte
	call	WaitKBD			; wait for 8042 to accept command
	mov	al,0feh			; feh = pulse output bit 0 (reset)
	out	KbStatus,al		; reset processor
	hlt
	assume	ds:DGROUP
;
err_cont:
	xor	ah,ah			; ah = 0 to set video mode
	mov	al,[mode]		; restore their mode
	int	10h
	cli				; turn them off...
;
;	restore master, slave, and NMI
;
	mov	al,[masterp]		; get value of master interrupt port
	out	MASTER,al		; restore it
	mov	al,[slavep]		; get value of slave interrupt port
	out	SLAVE,al		; restore it
	mov	al,ENA_NMI		; value to enable NMI
	out	NMI,al				      
;	
	pop	di
	pop	bp
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
ErrHndlr	endp

page
;******************************************************************************
;
;	b2asc10 - converts binary to ascii decimal and store at _TEXT:DI
;		  stores 2 ascii chars (decimal # is right justified and
;		  filled on left with 0s)
;
;	entry:	ax = binary number
;		ds:DGROUP
;		ds:di = place to store ascii chars.
;
;	exit:	ASCII decimal representation of number stored at _TEXT:DI
;
;	used:	none
;
;	stack: 
;
;******************************************************************************
;
b2asc10 proc    near
;
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
;
	mov	si,2			; pointer to base 10 table
	mov	bl,1			; leading zeroes on
;
;   convert binary number to decimal ascii
;
b2_loop:
	xor	dx,dx			; clear word extension
	mov	cx,powr10[si]
	div	cx          		; divide by power of 10
	or	bl,bl
	jnz	b2_ascii
;
	or	ax,ax			; q: zero result?
	jnz	b2_ascii		;  n: go convert to ascii
;
	mov	al,' '			;  y: go blank fill
	jmp	b2_make_strg		;
;
b2_ascii:
	add	al,'0'			; put into ascii format
	mov	bl,1			; leading zeroes on
;
b2_make_strg:
	mov	ds:[di],al		; put ascii number into string
	xchg	ax,dx
	inc	di			; increment buffer string pointer
	dec	si			; decrement power of 10 pointer
	dec	si			; 
	jge	b2_loop			; Q: Last digit?  N: Jump if not
;
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret				; *** return ***
;
b2asc10 endp
;
;******************************************************************************
;
;	b2asc16 - converts binary to hexidecimal and store at _TEXT:DI
;		  stores 4 ascii chars (# is right justified and
;		  filled on left with 0s)
;
;	entry:	ax = binary number
;		ds:DGROUP
;		ds:di = place to store ascii chars.
;
;	exit:	ASCII hexidecimal representation of number stored at _TEXT:DI
;
;	used:	none
;
;	stack: 
;
;******************************************************************************
;
b2asc16 proc    near

	push	ax
	push	bx
	push	cx

	mov	cx,4
b2asc16_loop:
	mov	bl,ah
	shr	bl,4
	add	bl,'0'
	cmp	bl,'9'
	jbe	b2asc16_skip
	add	bl,'A'-'9'-1
b2asc16_skip:
	mov	ds:[di],bl
	shl	ax,4
	inc	di
	loop	b2asc16_loop

	pop	cx
	pop	bx
	pop	ax
	ret

b2asc16 endp

_TEXT	ENDS
	END
