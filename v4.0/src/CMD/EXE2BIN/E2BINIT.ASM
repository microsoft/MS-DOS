
Title	E2BINIT(EXE2BIN)

;*****************************************************************************
;   Loader for EXE files under 86-DOS
;   VER 1.5
;	05/21/82   Added rev number
;   VER 1.6
;	07/01/82   A little less choosy about size matches
;   VER 2.0  M.A.U
;	10/08/82   Modified to use new 2.0 system calls for file i/o
;   Ver 2.1  M.A.U
;	10/27/82   Added the DOS version check
;   Ver 2.2  MZ
;	8/30/83     Fixed command line parsing
;   Ver 2.3  EE
;	10-12-83    More fixes to command line parsing
;   Ver 2.4  NP
;	10/17/83    Use Printf for messages
;   Ver 2.5  MZ     Fix LOCATE sss D: problem
;	04/09/87    Add PARSER and MESSAGE RETRIEVER
;   Ver 4.00  DRM
;*****************************************************************************


INCLUDE SYSMSG.INC
MSG_UTILNAME <EXE2BIN>							;AN000;

	subttl	Main Code Area						;AN000;
	page


; The following switch allows use with the "old linker", which put a version
; number where the new linker puts the number of bytes used in the last page.
; If enabled, this will cause a test for 0004 at this location (the old linker
; version number), and if equal, change it to 200H so all of the last page
; will be used.

OLDLINK EQU	0			;1 to enable, 0 to disable

CODE	SEGMENT PARA PUBLIC 'CODE'					;AN000;
CODE	ENDS								;AN000;
DATA	SEGMENT PARA PUBLIC 'DATA'					;AN000;
DATA	ENDS								;AN000;
STACK	SEGMENT PARA PUBLIC 'STACK'					;AN000;
STACK	ENDS								;AN000;
ZLOAD	SEGMENT PARA PUBLIC 'ZLOAD'					;AN000;
ZLOAD	ENDS								;AN000;

DATA	SEGMENT PARA PUBLIC 'DATA'					;AN000;

MSG_SERVICES <MSGDATA>							;AN000;

Command_Line_Buffer db 128 dup(0)					;AN000;
Command_Line_Length equ $ - Command_Line_Buffer 			;AN000;

Fatal_Error db	0							;AN000;

Command_Line db NO



rev	db	"2.4"


file1_ext db	".EXE",00h
file2_ext db	".BIN",00h

per11	db	0							;AN000;
per2	db	0
per22	db	0							;AN000;

update	equ	0							;AN000;
noupdate equ	-1							;AN000;

file1	db	(64+13) dup(?)
fnptr	dw	offset file1		; Ptr to filename in file1
handle1 dw	1 dup(?)

file2	db	(64+13) dup(?)
f2cspot dw	offset file2		; Ptr to spot in file2, file1 maybe added
handle2 dw	1 dup(?)

dma_buf db	80h dup(0)		; DMA transfer buffer

INBUF	DB	5,0
	DB	5 DUP(?)

;The following locations must be defined for storing the header:

RUNVAR	LABEL	BYTE			;Start of RUN variables
RELPT	DW	?
LASTP	LABEL	WORD
RELSEG	DW	?
SIZ	LABEL	WORD			;Share these locations
PAGES	DW	?
RELCNT	DW	?
HEADSIZ DW	?
	DW	?
LOADLOW DW	?
INITSS	DW	?
INITSP	DW	?
	DW	?
INITIP	DW	?
INITCS	DW	?
RELTAB	DW	?
RUNVARSIZ EQU	$-RUNVAR

DBCS_Vector_Off dw 0							;AN000;
DBCS_Vector_Seg dw 0							;AN000;

parse_ptr DW	?

DATA	ENDS


STACK	SEGMENT PARA PUBLIC 'STACK'
	DB	(362 - 80h) + 80H DUP (?) ; (362 - 80h) is IBMs ROM requirement
					; (New - Old) == size of growth
STACK	ENDS
;



ZLOAD	SEGMENT PARA PUBLIC 'ZLOAD'
	db	?
ZLOAD	ENDS
LOAD	EQU	ZLOAD
;



;
;*****************************************************************************
; Include files
;*****************************************************************************
;

.xlist
INCLUDE DOSSYM.INC			; also versiona.inc		;AN000;
INCLUDE SYSCALL.INC							;AN000;
INCLUDE E2BMACRO.INC							;AN000;
INCLUDE E2BEQU.INC							;AN000;
INCLUDE E2BTABLE.INC							;AN000;
INCLUDE E2BPARSE.INC							;AN000;
include version.inc
.list



CODE	SEGMENT PARA PUBLIC 'CODE'
	assume	cs:CODE,ds:DATA,es:NOTHING,SS:STACK			;AN000;

psp_ptr dw	1 dup(?)						;AN000;
;
;*****************************************************************************
; SysDisplayMsg Declarations
;*****************************************************************************
;
.xlist
MSG_SERVICES <LOADmsg>							;AN000;
MSG_SERVICES <DISPLAYmsg,CHARmsg>					;AN000;
MSG_SERVICES <EXE2BIN.CLA,EXE2BIN.CLB>					;AN000;
MSG_SERVICES <EXE2BIN.CL1,EXE2BIN.CL2>					;AN000;
MSG_SERVICES <EXE2BIN.CTL>						;AN000;


.list

;
;*****************************************************************************
; External Routine Declarations
;*****************************************************************************
;

	public	SysDispMsg						;AN000;
	public	SysLoadMsg						;AN000;


;*****************************************************************************
;Routine name:	Main_Init
;*****************************************************************************
;
;Description: Main control routine for init section
;
;Called Procedures: Message (macro)
;		    Check_DOS_Version
;		    Init_Input_Output
;		    Validate_Target_Drive
;		    Hook_CNTRL_C
;
;Input: None
;
;Output: None
;
;Change History: Created	6/22/87 	DM
;
;*****************************************************************************

procedure Main_Init near		;				;AN000;

	ASSUME	DS:NOTHING		; THIS IS WHAT dos GIVES YOU	;AN000;
	ASSUME	ES:NOTHING						;AN000;

	PUSH	DS							;AN000;
	mov	psp_ptr,ds						;AN000;
	XOR	AX,AX							;AN000;
	PUSH	AX			;Push return address to DS:0	;AN000;

	MOV	AX,SEG DATA		;SET UP ADDRESSABILITY TO	;AN000;
	MOV	DS,AX			; THE DATA SEGMENT		;AN000;
	ASSUME	DS:DATA 		;TELL ASSEMBLER WHAT I JUST DID ;AN000;

	mov	Fatal_Error,No		;Init the error flag		;AN000;
	call	Init_Input_Output	;Setup messages and parse	;AN000;
	cmp	Fatal_Error,Yes 	;Error occur?			;AN000;
;	$IF	NE			;Nope, keep going		;AN000;
	JE $$IF1
	    call    LOCATE		;Go do the real program 	;AN000;
;	$ENDIF								;AN000;
$$IF1:
	xor	al,al							;AN000;
	Dos_call Exit							;AN000;
	int	20h			;If other exit fails		;AN000;

Main_Init endp								;AN000;

;*****************************************************************************
;Routine name: Init_Input_Output
;*****************************************************************************
;
;Description: Initialize messages, Parse command line, allocate memory as
;	      needed. If there is a /FS switch, go handle it first as
;	      syntax of IFS format may be different from FAT format.
;
;Called Procedures: Preload_Messages
;		    Parse_For_FS_Switch
;		    Parse_Command_Line
;		    Interpret_Parse
;
;Change History: Created	6/22/87 	DM
;
;Input: PSP command line at 81h and length at 80h
;	Fatal_Error  = No
;
;Output: Fatal_Error = YES/NO
;
;*****************************************************************************

procedure Init_Input_Output near					;AN000;

	call	Preload_Messages	;Load up message retriever	;AN000;
	cmp	Fatal_Error,YES 	;Quit?				;AN000;
;	$IF	NE			;Nope, keep going		;AN000;
	JE $$IF3
	    call    Parse_Command_Line	;Parse in command line input	;AN000;
;	$ENDIF								;AN000;
$$IF3:
	ret								;AN000;

Init_Input_Output endp							;AN000;

;*****************************************************************************
;Routine name: Preload_Messages
;*****************************************************************************
;
;Description: Preload messages using common message retriever routines.
;
;Called Procedures: SysLoadMsg
;
;
;Change History: Created	6/22/87 	DM
;
;Input: Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;
;*****************************************************************************

procedure Preload_Messages near 					;AN000;

	call	SYSLOADMSG		;Preload the messages		;AN000;
;	$IF	C			;Error? 			;AN000;
	JNC $$IF5
	    call    SYSDISPMSG						;AN000;
	    mov     fatal_error, YES					;AN000;
;	$ENDIF								;AN000;
$$IF5:
	ret								;AN000;
Preload_Messages endp							;AN000;


;*****************************************************************************
;Routine name: Parse_Command_Line
;*****************************************************************************
;
;Description: Parses command line.
;
;Called Procedures: Message (macro)
;		    Sysparse
;
;Change History: Created	6/22/87 	DM
;
;Input: Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;
;*****************************************************************************


Procedure Parse_Command_Line						;AN000;

	push	ds							;AN000;
	mov	ds,psp_ptr						;AN000;
	ASSUME	DS:NOTHING						;AN000;
	mov	si,Command_Line_Parms					;AN000;
	mov	ax,seg command_line_table				;AN000;
	push	es							;AN000;
	mov	es,ax							;AN000;
	ASSUME	ES:NOTHING						;AN000;
	mov	di,offset Command_Line_Table				;AN000;
	xor	cx,cx							;AN000;

;	$DO								;AN000;
$$DO7:
	    xor     dx,dx						;AN000;
	    mov     es:parse_ptr,si
	    call    Sysparse						;AN000;
	    cmp     ax,No_Error 					;AN000;

;	    $IF     E							;AN000;
	    JNE $$IF8

		push	ax						;AN000;
		push	bx						;AN000;
		push	ds						;AN000;
		push	es						;AN000;
		push	si						;AN000;
		push	di						;AN000;

		cmp	cx,1						;AN000;

;		$IF	E						;AN000;
		JNE $$IF9

		    mov     ax,seg rb_string1_off			;AN000;
		    mov     ds,ax					;AN000;
		    ASSUME  DS:NOTHING					;AN000;
		    mov     si,offset rb_string1_off			;AN000;
		    mov     ax,ds:[si]					;AN000;
		    mov     bx,ax					;AN000;


		    mov     ax,ds:[si+2]				;AN000;
		    mov     ds,ax					;AN000;
		    ASSUME  DS:NOTHING					;AN000;
		    mov     si,bx					;AN000;

		    mov     ax,seg file1				;AN000;
		    mov     es,ax					;AN000;
		    ASSUME  ES:NOTHING					;AN000;
		    mov     di,offset file1				;AN000;
		    call    copyfs					;AN000;

;		$ELSE							;AN000;
		JMP SHORT $$EN9
$$IF9:

		    mov     ax,seg rb_string2_off			;AN000;
		    mov     ds,ax					;AN000;
		    ASSUME  DS:NOTHING					;AN000;
		    mov     si,offset rb_string2_off			;AN000;
		    mov     ax,ds:[si]					;AN000;
		    mov     bx,ax					;AN000;


		    mov     ax,ds:[si+2]				;AN000;
		    mov     ds,ax					;AN000;
		    ASSUME  DS:NOTHING					;AN000;
		    mov     si,bx					;AN000;

		    mov     ax,seg file2				;AN000;
		    mov     es,ax					;AN000;
		    ASSUME  ES:NOTHING					;AN000;
		    mov     di,offset file2				;AN000;
		    call    copyfs					;AN000;

;		$ENDIF							;AN000;
$$EN9:

		pop	di						;AN000;
		pop	si						;AN000;
		pop	es						;AN000;
		ASSUME	ES:NOTHING					;AN000;
		pop	ds						;AN000;
		ASSUME	DS:NOTHING					;AN000;
		pop	bx						;AN000;
		pop	ax						;AN000;

;	    $ENDIF							;AN000;
$$IF8:

	    cmp     ax,No_Error 					;AN000;

;	$ENDDO	NE							;AN000;
	JE $$DO7

	cmp	ax,End_of_Parse 	;Check for parse error		;AN000;
;	$IF	NE							;AN000;
	JE $$IF14
		push	ax						;AN001;
		mov	ax,es:parse_ptr 				;AN001;
		mov	es:parsoff,ax					;AN001;
		mov	es:parseg,ds					;AN001;
		mov	byte ptr ds:[si],0				;AN001;
		pop	ax						;AN001;
		parse_message		       ;Must enter file name	;AN000;
		mov	es:Fatal_Error,YES     ;Indicate death! 	;AN000;
;	$ENDIF								;AN000;
$$IF14:

	pop	es							;AN000;
	ASSUME	ES:NOTHING						;AN000;
	pop	ds							;AN000;
	ASSUME	DS:DATA 						;AN000;

	ret								;AN000;

Parse_Command_Line endp 						;AN000;

;*****************************************************************************

INCLUDE PARSE.ASM

;*****************************************************************************


procedure LOCATE near

	push	ds							;AN000;
	ASSUME	ES:NOTHING		; THIS IS THE WAY IT GETS HERE! ;AN000;
	mov	ax,es			; ES -> PSP			;AN000;
	mov	ds,ax			; DS -> PSP			;AN000;
	ASSUME	DS:NOTHING						;AN000;

	MOV	SI,offset file1
	MOV	BX,SEG DATA
	MOV	ES,BX
	assume	es:data 						;AN000;

	MOV	BX,WORD PTR DS:[2]	;Get size of memory


;-----------------------------------------------------------------------;

;
; The rules for the arguments are:
;   File 1:
;	If no extention is present, .EXE is used.
;   File 2:
;	If no drive is present in file2, use the one from file1
;	If no path is specified, then use current dir
;	If no filename is specified, use the filename from file1
;	If no extention is present in file2, .BIN is used
;


;----- Get the first file name
	push	ds							;AN000;
	push	es							;AN000;
	ASSUME	ES:DATA 						;AN000;
	pop	ds							;AN000;
	ASSUME	DS:DATA 						;AN000;

sj01:
	mov	si,offset file1 	;   d = file1;
	mov	per11,0 		;   assume no extension on file1;AC000;

;******************************************************************************

sj0:
	lodsb				;   while (!IsBlank(c=*p++)) {
	cmp	al,0
	JE	SJ2
	call	dbcs_check		; see if a dbcs character	;AN000;
	jc	dbcs_1			; dbcs character, go load another char ;AN000;
	cmp	al,'\'			;	if (c == '\\' || c == ':') {
	jnz	sj05
	mov	per11,update						;AC000;
	mov	fnptr,si		;	    fnptr = ptr to slash
sj05:
	cmp	al,':'			;	if (c == '\\' || c == ':') {
	jnz	checkper1
	mov	per11,update						;AC000;
	mov	fnptr,si		;	    fnptr = ptr to slash
checkper1:
	cmp	al,'.'			;	if (c == '.')
	jne	sj1
	mov	per11,noupdate		;   set file1 to have extension ;AN000;

sj1:

IF IBMCOPYRIGHT
ELSE
	cmp	al,'*'
	je	File1_Err
	cmp	al,'?'
	je	File1_Err
ENDIF

	jmp	short sj0		;	}

IF IBMCOPYRIGHT
ELSE
File1_Err:
	stc
	mov	dx, offset file1
	jmp	DosError
ENDIF

dbcs_1: 				;				;AN000;
	lodsb				; load another character and got to ;AN000;
	jmp	short sj0		; the start again.		;AN000;

;******************************************************************************

sj2:
get_second:
;----- Get the second file name
	MOV	SI,offset file1
	mov	di,offset file2 	;   d = file2

;******************************************************************************

sj3:
	cmp	word ptr [di],00	;   check to see if first character of
	je	sj32			;   file2 is a null.		;AN000;
	mov	si,offset file2 	;   set pointer to file2

;******************************************************************************

sj31:
	lodsb				;   If file2 first character is not a
	mov	f2cspot,si
	cmp	al,0			;   null, this loop will check to see
	JZ	maycopy 		;   the file has an extension assigned;AN000;
	call	dbcs_check		; to it.  If not it will set per2 to  ;AN000;
	jc	dbcs_2			; go load another byte		      ;AN000;
	mov	per22,noupdate		;				      ;AN000;
	cmp	al,'\'			;   0 so that in check_ext, the .BIN
	jnz	checkper6		;   will be added to the filename.
	mov	per2,update		;				      ;AC000;
	mov	per22,update		;				      ;AN000;
checkper6:
	cmp	al,':'			;	if (c == '\\' || c == ':') {
	jnz	checkper4
	mov	per22,update		;				      ;AN000;
checkper4:				;   there is an extension already.
	cmp	al,'.'			;
	jne	sj33			;
	mov	per2,noupdate		;				      ;AC000;

sj33:					;

IF IBMCOPYRIGHT
ELSE
	cmp	al,'*'
	je	File2_Err
	cmp	al,'?'
	je	File2_Err
ENDIF

	jmp	short sj31		;

IF IBMCOPYRIGHT
ELSE
File2_Err:
	stc
	mov	dx, offset file2
	jmp	DosError
ENDIF


dbcs_2:
	lodsb				;load another character and got to    ;AN000;
	jmp	short sj31		;the start again.		      ;AN000;

;******************************************************************************

maycopy:				;   Check to see if the 	      ;AN000;
	cmp	per22,noupdate		;   Last thing copied was either a    ;AN000;
	je	SJ5			;   driver letter or  "\".	      ;AN000;
	dec	f2cspot 						      ;AN000;
	mov	di,f2cspot						      ;AN000;

sj32:
					;   There is no second filename so
	mov	si,fnptr						      ;AN000;
	mov	per2,update		;   set per2 to 0 to get default .BIN ;AN000;
					;   extension in check_ext.

;******************************************************************************

copy1to2:								      ;AN000;
	lodsb				; This loop is executed when there is ;AN000;
	cmp	al,0			; no file2 specified on the command   ;AN000;
	JZ	SJ5			; line.  It will copy the file1 name  ;AN000;
	call	dbcs_check		; check for dbcs character	      ;AN000;
	jc	dbcs_3			; got a dbcs character, go copy.      ;AN000;
	cmp	al,'.'			; extension.  The defult extension    ;AN000;
	je	sj5			; of .BIN will be added in check_ext. ;AN000;
	stosb								      ;AN000;
	jmp	short copy1to2						      ;AN000;
dbcs_3:
	stosb				; Got a dbcs character. Copy	      ;AN000;
	lodsb				; two characters and then go to       ;AN000;
	stosb				; next character in filename.	      ;AN000;
	jmp	short copy1to2						      ;AN000;	     ;AN000;

;******************************************************************************

sj5:
;	mov	byte ptr es:[di],00h	;   *d = 0;
	mov	ah,Set_DMA		; Use find_first to see if file2 is
	mov	dx,offset dma_buf	; a directory.	If it isn't, go to
	int	21h			; set f2cspot to point to the spot
	mov	ah,Find_First		; right after the backslash, and
	mov	dx,offset file2 	; fall through to no_second so that
	mov	cx,-1			; file1's name will be added to file2.
	int	21h
	jc	check_ext
	test	dma_buf+21,00010000b
	jNZ	DoDirectory
	jmp	Check_Ext
DoDirectory:
	mov	AL,'\'
	mov	di,f2cspot
	dec	di
	stosb
SetSecond:
	mov	per22,update						;AN000;
	inc	di
	mov	f2cspot,di
	jmp	maycopy


;----- Check that files have an extension, otherwise set default
check_ext:
	cmp	per11,noupdate		;   if (per1 == NULL) { 	;AC000;
	jz	file1_ok
	mov	di,offset file1 	;	d = file1;
	mov	si,offset file1_ext	;	s = ".EXE";
	call	strcat			;	strcat (d, s);
file1_ok:				;	}
	cmp	per2,noupdate		;   if (per2 != NULL) { 	;AC000;
	je	file2_ok
	mov	di,offset file2 	;	d = file2;
	mov	si,offset file2_ext	;	s = ".BIN";
	call	strcat			;	strcap (d, s);
	jmp	short file2_ok		;	}

;-----------------------------------------------------------------------;
file2_ok:
	mov	dx,offset file1
	mov	ax,(open SHL 8) + 0	;for reading only
	INT	21H			;Open input file
	jc	bad_file
	mov	[handle1],ax
	jmp	exeload

bad_file:
	jmp	DosError

BADEXE:
	pop	ds
	ASSUME	DS:nothing						;AN000;
	MESSAGE msgNoConvert						;AC000;
	jmp	getout							;AN000;

ReadError:
	jmp	DosError

EXELOAD:
	ASSUME	DS:DATA 						;AN000;
	MOV	DX,OFFSET RUNVAR	;Read header in here
	MOV	CX,RUNVARSIZ		;Amount of header info we need
	push	bx
	mov	bx,[handle1]
	MOV	AH,read
	INT	21H			;Read in header
	pop	bx
	jc	ReadError
	CMP	[RELPT],5A4DH		;Check signature word
	JNZ	BADEXE
	MOV	AX,[HEADSIZ]		;size of header in paragraphs
	ADD	AX,31			;Round up first
	CMP	AX,1000H		;Must not be >=64K
	JAE	TOOBIG
	AND	AX,NOT 31
	MOV	CL,4
	SHL	AX,CL			;Header size in bytes

	push	dx
	push	cx
	push	ax
	push	bx
	mov	dx,ax
	xor	cx,cx
	mov	al,0
	mov	bx,[handle1]
	mov	ah,lseek
	int	21h
	jc	LseekError
	pop	bx
	pop	ax
	pop	cx
	pop	dx

	XCHG	AL,AH
	SHR	AX,1			;Convert to pages
	MOV	DX,[PAGES]		;Total size of file in 512-byte pages
	SUB	DX,AX			;Size of program in pages
	CMP	DX,80H			;Fit in 64K? (128 * 512 = 64k)
	JAE	TOOBIG
	XCHG	DH,DL
	SHL	DX,1			;Convert pages to bytes
	MOV	AX,[LASTP]		;Get count of bytes in last page
	OR	AX,AX			;If zero, use all of last page
	JZ	WHOLEP

	IF	OLDLINK
	    CMP     AX,4		;Produced by old linker?
	    JZ	    WHOLEP		;If so, use all of last page too
	ENDIF

	SUB	DX,200H 		;Subtract last page
	ADD	DX,AX			;Add in byte count for last page
WHOLEP:
	MOV	[SIZ],DX
	ADD	DX,15
	SHR	DX,CL			;Convert bytes to paragraphs
	MOV	BP,SEG LOAD
	ADD	DX,BP			;Size + start = minimum memory (paragr.)
	CMP	DX,BX			;Enough memory?
	JA	TOOBIG
	MOV	AX,[INITSS]
	OR	AX,[INITSP]
	OR	AX,[INITCS]
	JMP	ERRORNZ

TOOBIG:
	pop	ds
	ASSUME	DS:NOTHING						;AN000;
	MESSAGE msgOutOfMemory						;AN000;
	jmp	getout							;AN000;

LseekError:
	jmp	DosError


ERRORNZ:
	ASSUME	DS:DATA 						;AN000;
	jz	xj
	JMP	BADEXE			;AC000; For ptm P475;
xj:	MOV	AX,[INITIP]
	OR	AX,AX			;If IP=0, do binary fix
	JZ	BINFIX
	CMP	AX,100H 		;COM file must be set up for CS:100
	JNZ	ERRORNZ

	push	dx
	push	cx
	push	ax
	push	bx
	mov	dx,100h 		;chop off first 100h
	xor	cx,cx
	mov	al,1			;seek from current position
	mov	bx,[handle1]
	mov	ah,lseek
	int	21h
	jc	LseekError
	pop	bx
	pop	ax
	pop	cx
	pop	dx

	SUB	[SIZ],AX		;And count decreased size
	CMP	[RELCNT],0		;Must have no fixups
	JNZ	ERRORNZ
BINFIX:
	XOR	BX,BX			;Initialize fixup segment
;See if segment fixups needed
	CMP	[RELCNT],0
	JZ	LOADEXE
GETSEG:
	pop	ds
	ASSUME	DS:NOTHING						;AN000;
	MESSAGE msgFixUp						;AN000;
	PUSH	DS
	PUSH	ES
	POP	DS
	ASSUME	DS:DATA 						;AN000;
	MOV	AH,STD_CON_STRING_INPUT
	MOV	DX,OFFSET INBUF
	INT	21H			;Get user response
	MOV	SI,OFFSET INBUF+2
;;dcl;; MOV	BYTE PTR [SI-1],0	;Any digits?
	cmp	BYTE PTR [SI-1],0	;Any digits?			;AC000;
	JZ	GETSEG
DIGLP:
	LODSB
	SUB	AL,"0"
	JC	DIGERR
	CMP	AL,10
	JB	HAVDIG
	AND	AL,5FH			;Convert to upper case
	SUB	AL,7
	CMP	AL,10
	JB	DIGERR
	CMP	AL,10H
	JAE	DIGERR
HAVDIG:
	SHL	BX,1
	SHL	BX,1
	SHL	BX,1
	SHL	BX,1
	OR	BL,AL
	JMP	DIGLP

DIGERR:
	CMP	BYTE PTR [SI-1],0DH	;Is last char. a CR?
	JNZ	GETSEG
LOADEXE:
	XCHG	BX,BP			;BX has LOAD, BP has fixup

	MOV	CX,[SIZ]
	MOV	AH,read
	push	di
	mov	di,[handle1]
	PUSH	DS
	MOV	DS,BX
	ASSUME	DS:NOTHING						;AN000;
	XOR	DX,DX
	push	bx
	mov	bx,di
	INT	21H			;Read in up to 64K
	pop	bx
	POP	DS
	ASSUME	DS:DATA 						;AN000;
	pop	di
	Jnc	HAVEXE			;Did we get it all?

	jmp	DosError

LseekError2:
	jmp	DosError

HAVEXE:
	ASSUME	DS:DATA 						;AN000;
	CMP	[RELCNT],0		;Any fixups to do?
	JZ	STORE
	MOV	AX,[RELTAB]		;Get position of table

	push	dx
	push	cx
	push	ax
	push	bx
	mov	dx,ax
	xor	cx,cx
	mov	al,0
	mov	bx,[handle1]
	mov	ah,lseek
	int	21h
	jc	LseekError2
	pop	bx
	pop	ax
	pop	cx
	pop	dx

	MOV	DX,OFFSET RELPT 	;4-byte buffer for relocation address
RELOC:
	MOV	DX,OFFSET RELPT 	;4-byte buffer for relocation address
	MOV	CX,4
	MOV	AH,read
	push	bx
	mov	bx,[handle1]
	INT	21H			;Read in one relocation pointer
	pop	bx
	Jnc	RDCMP
	jmp	DosError
RDCMP:
	MOV	DI,[RELPT]		;Get offset of relocation pointer
	MOV	AX,[RELSEG]		;Get segment
	ADD	AX,BX			;Bias segment with actual load segment
	MOV	ES,AX
	ASSUME	ES:NOTHING						;AN000;
	ADD	ES:[DI],BP		;Relocate
	DEC	[RELCNT]		;Count off
	JNZ	RELOC
STORE:
	MOV	AH,CREAT
	MOV	DX,OFFSET file2
	xor	cx,cx
	INT	21H
	Jc	MKERR
	mov	[handle2],ax
	MOV	CX,[SIZ]
	MOV	AH,write
	push	di
	mov	di,[handle2]
	PUSH	DS
	MOV	DS,BX
	ASSUME	DS:NOTHING						;AN000;
	XOR	DX,DX			;Address 0 in segment
	push	bx
	mov	bx,di
	INT	21H
	pop	bx
	POP	DS
	ASSUME	DS:DATA 						;AN000;
	pop	di
	Jc	WRTERR			;Must be zero if more to come
	cmp	AX,CX
	jnz	NOROOM
	MOV	AH,CLOSE
	push	bx
	mov	bx,[handle2]
	INT	21H
	jc	CloseError
	pop	bx
	pop	ds
	pop	ds
	ASSUME	DS:NOTHING						;AN000;

	RET

;*******************************************************************************

NOROOM: 				;				     ;AN000;
	ASSUME	DS:DATA 						;AN000;
	MOV	AH,CLOSE		; Close the file here		     ;AN000;
	push	bx			;				     ;AN000;
	mov	bx,[handle2]		;				     ;AN000;
	INT	21H			;				     ;AN000;
	jc	CloseError		; If error let extend messages get it;AN000;
	pop	bx			;				     ;AN000;
	mov	ah,UNLINK		; Delete the file because it did     ;AN000;
	MOV	DX,OFFSET file2 	; not get written correctly.	     ;AN000;
	INT	21H			;				     ;AN000;
	jc	CloseError		; If error let extend messages get it;AN000;
	pop	ds			;				     ;AN000;
	ASSUME	DS:NOTHING		;				     ;AN000;
	message msgNoDiskSpace		; Put out insufficient disk space    ;AN000;
	jmp	getout			; message			     ;AN000;
	RET				; return to main_init		     ;AN000;

;*******************************************************************************

WRTERR: 								;AN000;
MKERR:									;AN000;
CloseError:								;AN000;

	public	DosError						;AN000;
DosError:								;AN000;
	mov	es:FileNameSegment,ds	   ; save for opens, creates,	;AN000;
	mov	es:FileNameOffset,dx					;AN000;

	mov	bx,0			; get the extended error code	;AN000;
	mov	ah,059h 						;AN000;
	int	21h							;AN000;

	mov	si,offset ds:Sublist_msg_exterror			;AC001;
	extend_message							;AN001;
	pop	ds							;AN001;

getout: 								;AN000;
	pop	ds							;AN000;
	ASSUME	DS:NOTHING						;AN000;

	ret								;AN000;


LOCATE	ENDP

;----- concatenate two strings
strcat	proc	near			;   while (*d)
	cmp	byte ptr [di],0
	jz	atend
	inc	di			;	d++;
	jmp	strcat
atend:					;   while (*d++ = *s++)
	lodsb
	stosb
	or	al,al			;	;
	jnz	atend
	ret
strcat	endp

;----- Find the first non-ignorable char, return carry if CR found
kill_bl proc	near
	cld
sj10:					;   while ( *p != 13 &&
	lodsb
	CMP	AL,13			;	    IsBlank (*p++))
	JZ	BreakOut
	CALL	IsBlank
	JZ	SJ10			;	;
BreakOut:
	dec	si			;   p--;
	cmp	al,0dh			;   return *p == 13;
	clc
	jne	sj11
	stc
sj11:
	ret
kill_bl endp

IsBlank proc	near
	cmp	al,00							;AN000;
	retz								;AN000;
	cmp	al,13
	retz
	cmp	al,' '			; space
	retz
	cmp	al,9			; tab
	retz
	cmp	al,','			; comma
	retz
	cmp	al,';'			; semicolon
	retz
	cmp	al,'+'			; plus
	retz
	cmp	al,10			; line feed
	retz
	cmp	al,'='			; equal sign
	return
IsBlank Endp


procedure copyfs near

	push	ax							;AN000;

;	$do				; while we have filespec	;AN000;
$$DO16:
	    lodsb			; move byte to al		;AN000;
	    cmp     al,0		; see if we are at		;AN000;
					; the end of the
					; filespec
;	$leave	e			; exit while loop		;AN000;
	JE $$EN16
	    stosb			; move byte to path_name	;AN000;
;	$enddo				; end do while			;AN000;
	JMP SHORT $$DO16
$$EN16:
	stosb								;AN000;
	pop	ax							;AN000;

	ret								;AN000;
copyfs	endp								;AN000;


procedure dbcs_check near

	push	ds				;Save registers 	;AC000;
	push	si				; "  "	  "  "		;AC000;
	push	ax				; "  "	  "  "		;AC000;
	push	ds				; "  "	  "  "		;AC000;
	pop	es				;Establish addressability;AC000;
	cmp	byte ptr es:DBCS_VECTOR,Yes	;Have we set this yet?	;AC000;
	push	ax				;Save input character	;AC000;
;	$IF	NE				;Nope			;AN000;
	JE $$IF19
	   mov	   al,0 			;Get DBCS environment vectors;AC000;
	   DOS_Call Hongeul			;  "  "    "  " 	;AC000;
	   mov	   byte ptr es:DBCS_VECTOR,YES	;Indicate we've got vector;AC000;
	   mov	   es:DBCS_Vector_Off,si	;Save the vector	;AC000;
	   mov	   ax,ds			;			;AC000;
	   mov	   es:DBCS_Vector_Seg,ax	;			;AC000;
;	$ENDIF					; for next time in	;AC000;
$$IF19:
	pop	ax				;Restore input character;AC000;
	mov	si,es:DBCS_Vector_Seg		;Get saved vector pointer;AC000;
	mov	ds,si				;			;AC000;
	mov	si,es:DBCS_Vector_Off		;			;AC000;
;	$SEARCH 				;Check all the vectors	;AC000;
$$DO21:
	   cmp	   word ptr ds:[si],End_Of_Vector ;End of vector table? ;AC000;
;	$LEAVE	E				;Yes, done		;AC000;
	JE $$EN21
	   cmp	   al,ds:[si]			;See if char is in vector;AC000;
;	$EXITIF AE,AND				;If >= to lower, and	;AC000;
	JNAE $$IF21
	   cmp	   al,ds:[si+1] 		; =< than higher range	;AC000;
;	$EXITIF BE				; then DBCS character	;AC000;
	JNBE $$IF21
	   stc					;Set CY to indicate DBCS;AC000;
;	$ORELSE 				;Not in range, check next;AC000;
	JMP SHORT $$SR21
$$IF21:
	   add	   si,DBCS_Vector_Size		;Get next DBCS vector	;AC000;
;	$ENDLOOP				;We didn't find DBCS chaR;AC000;
	JMP SHORT $$DO21
$$EN21:
	   clc					;Clear CY for exit	;AC000;
;	$ENDSRCH				;			;AC000;
$$SR21:
	pop	ax				;Restore registers	;AC000;
	pop	si				; "  "	  "  "		;AC000;
	pop	ds				;Restore data segment	;AC000;
	ret					;			;AC000;

	ret								;AN000;
dbcs_check  endp							;AN000;



CODE	ends


	end	main_init						;AC000;

