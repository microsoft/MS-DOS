
	page	60,132;
	title	EDLPARSE for EDLIN


;******************* START OF SPECIFICATIONS *****************************
;
; MODULE NAME: EDLPARSE.SAL
;
; DESCRIPTIVE NAME: PARSES THE EXTERNAL COMMAND LINE FOR EDLIN
;
; FUNCTION: THIS ROUTINE PROVIDES PARSING CAPABILITIES FOR THE
;	    EXTERNAL COMMAND LINE OF EDLIN.  IT PARSES FOR THE PRESENCE
;	    OF A REQUIRED FILESPEC AND AN OPTIONAL SWITCH (/B).
;
; ENTRY POINT: PARSER_COMMAND
;
; INPUT: DOS COMMAND LINE
;
; EXIT NORMAL: AX = 0FFH    - VALID SWITCH AND FILESPEC SPECIFIED
;
; EXIT ERROR:  AX NOT= 0FFH - INVALID SWITCH OR NO FILESPEC SPECIFIED
;
; INTERNAL REFERENCES
;
;	ROUTINE: PARSER_COMMAND - THIS ROUTINE PARSES FOR THE PRESENCE
;				  OF THE /B SWITCH AND A FILESPEC.  THE
;				  FILEPSEC IS REQUIRED, WHILE THE SWITCH
;				  IS OPTIONAL.
;
; EXTERNAL REFERENCES:
;
;     ROUTINE: PARSE.ASM - THIS IS THE PARSER CODE.
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK EDLIN+EDLCMD1+EDLCMD2+EDLMES+EDLPARSE
;
; REVISION HISTORY:
;
;	AN000	VERSION 4.00 - IMPLEMENTS THE SYSTEM PARSER (SYSPARSE)
;
; COPYRIGHT: "THE IBM PERSONAL COMPUTER EDLIN UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988"
;	     "LICENSED MATERIAL - PROPERTY OF Microsoft"
;
;
;******************** END OF SPECIFICATIONS ******************************


;======================= equates for edlparse ============================

parse_ok	equ	0			;an000;good parse return
parse_command	equ	081h			;an000;offset of command line
nul		equ	0			;an000;nul
fs_flag 	equ	05h			;an000;filespec found
sw_flag 	equ	03h			;an000;switch found
true		equ	0ffffh			;an000;true
false		equ	00h			;an000;false
too_many	equ	01h			;an000;too many parms

;======================= end equates =====================================


CODE	SEGMENT PUBLIC BYTE
CODE	ENDS

CONST	SEGMENT PUBLIC BYTE
CONST	ENDS

cstack	segment stack
cstack	ends

DATA	SEGMENT PUBLIC BYTE

	extrn	path_name:byte
	extrn	org_ds:word			;an000; dms;

	public	parse_switch_b			;an000;parse switch result
	public	filespec			;an000;actual filespec

;======================= input parameters control blocks =================
; these control blocks are used by sysparse and must be pointed to by
; es:di on invocation.

		public	parms			;an000;share parms
parms		label	byte			;an000;parms control block
		dw	dg:parmsx		;an000;point to parms structure
		db	00h			;an000;no additional delims.

parmsx		label	byte			;an000;parameter types
		db	1,1			;an000;must have filespec
		dw	dg:fs_pos		;an000;filespec control block
		db	1			;an000;max. number of switches
		dw	dg:sw_b 		;an000;\b switch control block
		db	00h			;an000;no keywords

;======================= filespec positional tables ======================

fs_pos		label	byte			;an000;filespec positional
		dw	0200h			;an000;filespec/not optional
		dw	0001h			;an000;cap
		dw	dg:filespec_res 	;an000;filespec result table
		dw	dg:noval		;an000;value list/none
		db	0			;an000;no keyword/switch syns.

filespec_res	label	byte			;an000;filespec result table
parse_fs_res	db	?			;an000;must be filespec (05)
parse_fs_tag	db	?			;an000;item tag
parse_fs_syn	dw	?			;an000;synonym pointer
parse_fs_off	dw	?			;an000;offset to filespec
parse_fs_seg	dw	?			;an000;segment of filespec

;======================= switch tables /b ================================

sw_b		label	byte			;an000;/b switch
		dw	0000h			;an000;no match flags
		dw	0000h			;an000;no cap
		dw	dg:switch_res		;an000;result buffer
		dw	dg:noval		;an000;value list/none
		db	1			;an000;1 switch
sw_b_switch	db	"/B",0			;an000;/B means ignore CTL-Z

switch_res	label	byte			;an000;switch result table
parse_sw_res	db	?			;an000;must be string (03)
parse_sw_tag	db	?			;an000;item tag
parse_sw_syn	dw	?			;an000;synonym pointer
parse_sw_ptr	dd	?			;an000;pointer to result

noval		label	byte			;an000;value table
		db	0			;an000;no values


;======================= end input parameter control blocks ==============

filespec	db	128 dup (0)		;an000;holds filespec
parse_switch_b	db	?			;an000;hold boolean result
						;      of /b parse
parse_sw_b	db	"/B"			;an000;comparison switch

DATA	ENDS

DG	GROUP	CODE,CONST,cstack,DATA

code	segment public	byte			;an000;code segment
	assume cs:dg,ds:dg,es:dg,ss:CStack	;an000;

	public	parser_command			;an000;share this routine



;======================= begin main routine ==============================
.xlist

include parse.asm				;an000;parser

.list

parser_command	proc	near			;an000;parse routine

	push	es				;an000;save registers
	push	ds				;an000;
	push	di				;an000;
	push	si				;an000;

	mov	dg:parse_switch_b,false 	;an000;init. to false
	xor	cx,cx				;an000;set cx to 0
	xor	dx,dx				;an000;set dx to 0
	mov	di,offset dg:parms		;an000;point to parms
	mov	si,parse_command		;an000;point to ds:81h
	mov	ds,dg:org_ds			;an000;get ds at entry
	assume	ds:nothing			;an000;

parse_continue: 				;an000;loop return point

	call	sysparse			;an000;invoke parser
	cmp	ax,parse_ok			;an000;is it a good parse
	jne	parse_end			;an000;continue on good parse
	push	si
	mov	si,dx
	cmp	byte ptr es:[si],fs_flag	;an000;do we have a filespec
;	$if	e				;an000;yes we do
	JNE $$IF1
		call build_fs			;an000;save filespec
;	$else					;an000;
	JMP SHORT $$EN1
$$IF1:
		cmp  parse_switch_b,true	;an000;see if already set
;		$if  nz 			;an000;if not
		JZ $$IF3
		     call val_sw		;an000;see which switch
;		$else				;an000;
		JMP SHORT $$EN3
$$IF3:
		     mov  ax,too_many		;an000;set error level
		     jmp  parse_end		;an000;exit parser
;		$endif				;an000;
$$EN3:
;	$endif					;an000;
$$EN1:

	pop	si
	jmp	parse_continue			;an000;continue parsing

parse_end:					;an000;end parse routine

	pop	si				;an000;restore registers
	pop	di				;an000; for return to caller
	pop	ds				;an000;
	assume	ds:dg				;an000;
	pop	es				;an000;

	ret					;an000;return to caller

parser_command	endp				;an000;end parser_command


;======================= subroutine area =================================


;=========================================================================
; build_fs: This routine saves the filespec for use by the calling program.
;=========================================================================

build_fs	proc	near			;an000;save filespec

	push	ax				;an000;save affected regs.
	push	di				;an000;
	push	si				;an000;
	push	ds				;an000;
	push	es				;an000;

	mov	di,offset dg:filespec		;an000;point to filespec buffer
	lds	si,dword ptr es:parse_fs_off	;an000;get offset

build_cont:					;an000;continue routine

	lodsb					;an000;mov ds:si to al
	cmp	al,nul				;an000;is it end of filespec
;	$if	nz				;an000;if not
	JZ $$IF7
		stosb				;an000;move byte to filespec
		jmp build_cont			;an000;continue buffer fill
;	$endif					;an000;
$$IF7:
	stosb					;an000;save nul

	pop	es				;an000;restore regs
	pop	ds				;an000;
	pop	si				;an000;
	pop	di				;an000;
	pop	ax				;an000;

	ret					;an000;return to caller

build_fs	endp				;an000;end proc

;=========================================================================
; val_sw : determines which switch we have.
;=========================================================================

val_sw		proc	near			;an000;switch determination

	cmp	es:parse_sw_syn,offset es:sw_b_switch	;an000;/B switch?
;	$if	e				;an000;compare good
	JNE $$IF9
		mov	dg:parse_switch_b,true	;an000;signal /B found
;	$else					;an000;
	JMP SHORT $$EN9
$$IF9:
		mov	dg:parse_switch_b,false ;an000;signal /B not found
;	$endif					;an000;
$$EN9:

	ret					;an000;return to caller

val_sw		endp				;an000;end proc


code	ends					;an000;end segment
	end					;an000;
