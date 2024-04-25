;
page 60,132
;
title CP/DOS  DOSExecPrg  mapper

buffer	segment word public 'buffer'
			public	DosExecPgmCalled
DosExecPgmCalled	db	0			  ;????????????
			public	DosExecPgmReturnCode
DosExecPgmReturnCode	dw	0

DosExecParameterBlock	label	word
EnvironmentSegment	dw	0
ArgumentPointer 	dd	0
Default_5C_FCB		dd	0
Default_6C_FCB		dd	0

buffer	ends

dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
; ************************************************************************* *
; *
; *	 MODULE: DosExecPgm
; *
; *	 FUNCTION:  Allows a program to execute another program
; *
; *	 CALLING SEQUENCE:
; *
; *		push	Asyncindic	; execute asynchronously
; *		push	TraceIndic	; trace process
; *		push	Argpointer	; address of arguments string
; *		push	Envpointer	; address of environment string
; *		push	Processid	; address to put process id
; *		push	PgmPointer	; address of program filename
; *		call	dosexecpgm
; *
; *	 RETURN SEQUENCE:    AX = error code
; *
; *
; *
; *	 MODULES CALLED:   INT 21H   function 4BH and 4DH
; *
; *
; *
; *************************************************************************

	public	dosexecpgm
	.sall
	.xlist
	include macros.inc
	.list

inv_parm equ 0002
not_suf_mem equ 0004

str	struc
old_bp	dw	?
return	dd	?
Pgmpointer dd	?	; address of program file name
Processid  dd	?	; this is used when only sync exec
EnvPointer dd	?	; address of environment string
ArgPointer dd	?	; address of argument string
Traceindic dw	?	; ignored,  what is a trace process?
Asyncindic dw	?	; ignored,  PC-DOS always waits!
str	ends

dosexecpgm proc   far				; push registers
	Enter	dosexecpgm

	mov	ax,seg buffer			; setup buffer segment
	mov	ds,ax				;   and copy info into
	assume	ds:buffer			;      data buffer

	mov	ax,word ptr [bp+2].EnvPointer	; seg portion only for pc-dos
	mov	EnvironmentSegment,ax		; copy environment string

	les	di,[bp].ArgPointer
	mov	word ptr ArgumentPointer+0,di	; copy argument string
	mov	word ptr ArgumentPointer+2,es

	xor	ax,ax
	mov	word ptr Default_5C_FCB+0,ax	; setup defaults
	mov	word ptr Default_5C_FCB+2,ax

	mov	word ptr Default_6C_FCB+0,ax
	mov	word ptr Default_6C_FCB+2,ax

	mov	bx,ds
	mov	es,bx
	mov	bx,offset buffer:DosExecParameterBlock

	lds	dx,[bp].PgmPointer	   ; setup program name
	mov	ax,4b00h
	int	21h			   ; exec program  and
	jc	ErrorExit		   ;   check for error

	mov	ah,4dh
	int	21h			   ; get return code of program
	jc	ErrorExit		   ;   just executed and jump if
					   ;	   error
	mov	bx,seg buffer
	mov	ds,bx
	mov	DosExecPgmReturnCode,ax    ; else, save return code

	xor	ax,ax			   ; set no error code

ErrorExit:
	Mexit				   ; pop registers
	ret	size str - 6		   ; return

dosexecpgm  endp

dosxxx	ends

	end
