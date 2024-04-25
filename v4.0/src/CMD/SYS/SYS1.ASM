	TITLE	SYS-1-	Program
	INCLUDE SYSHDR.INC
	include version.inc
	page	80,132

false	= 0

DATA	SEGMENT PARA PUBLIC

	public	TargDrvNum, TargSpec, bio_owns_it, DOS_VER
	public	packet, packet_sectors, packet_buffer
	extrn	THIS_DPB:dword, BUF:word, DIR_SECTOR:word, first_dir_sector:word

;			$SALUT (4,25,30,41)

DOS_VER 		DB   0		; DOS Version - 0 = current
					;		1 = 3.2 or 3
DEFALT			DB   0		; Default Drive (source - NUMBER
TargDrvNum		DB   0		; Target Drive (destination) - NUMBER
TargDrv 		DB   0		; Target Drive (destination) - LETTER
TargSpec		DB   "A:\",0	; z string for target name
IF IBMCOPYRIGHT
BIOSName		DB   "A:\IBMBIO.COM",0 ; z string for target name
DOSName 		DB   "A:\IBMDOS.COM",0 ; z string for target name
ELSE
BIOSName		DB   "A:\IO.SYS",0
DOSName 		DB   "A:\MSDOS.SYS",0
ENDIF

SourceBIOSName		LABEL WORD
SourceSpec		DB   "A:"
			DB   53 dup (0)
IF IBMCOPYRIGHT
SourceBIOS		DB   "\IBMBIO.COM",0
ELSE
SourceBIOS		DB   "\IO.SYS",0
ENDIF

IF  IBMCOPYRIGHT
NameLen 		equ  $ - SourceBios
ELSE
BiosNameLen		equ  $ - SourceBios
ENDIF

SourceDOSName		DB   "A:"
			DB   53 dup (0)
IF IBMCOPYRIGHT
SourceDOS		DB   "\IBMDOS.COM",0
ELSE
SourceDOS		DB   "\MSDOS.SYS",0
ENDIF

IF  IBMCOPYRIGHT
ELSE
DosNameLen		equ  $ - SourceDOS
ENDIF

SourceSize		dw   2
Spec_flag		db   0

IBMBIO_LOW		DW   0		;length of IBMBIO on disk
IBMBIO_HIGH		DW   0
IBMDOS_LOW		DW   0		;length of old IBMDOS on disk
IBMDOS_HIGH		DW   0

SIZE_OLD_HIGH		DW   0
SIZE_OLD_LOW		DW   0

NEWBIO_SIZE_LOW 	DW   0
NEWBIO_SIZE_HIGH	DW   0
NEWDOS_SIZE_LOW 	DW   0
NEWDOS_SIZE_HIGH	DW   0


Need_Clusters		dw   0
Bytes_Per_Cluster	dw   0
Number_Free_Clusters	dw   0

;	$SALUT	(4,9,17,41)
					;---------------------------------------
					;  SRORAGE FOR COMMAND LINE PARAMETERS
					;---------------------------------------

PARMS	LABEL	WORD
	DW	OFFSET PARMSX		; POINTER TO PARMS STRUCTURE
	DB	0			; NO DELIMITER LIST FOLLOWS
	DB	0			; NUMBER OF ADDITIONAL DELIMITERS

					;---------------------------------------
					;  STRUCTURE TO DEFINE SYS SYNTAX REQUIREMENT
					;---------------------------------------

PARMSX	LABEL	BYTE
PAR_MIN DB	1			; MINIMUM POSITIONAL PARAMETERS = 1    ;AC021;
	DB	2			; MAXIMUM PARAMETERS = 2	       ;AC021;
	DW	OFFSET POS1		; POINTER TO POSITIONAL DEFINITION
	DW	OFFSET POS1		; POINTER TO SAME POSITIONAL DEFINITION;AC021;
	DB	0			; THERE ARE NO SWITCHES
	DB	0			; THERE ARE NO KEYWORDS IN PRINT SYNTAX

					;---------------------------------------
					;  STRUCTURE TO DEFINE THE POSITIONAL PARAMETER (Drive ID)
					;---------------------------------------

POS1	LABEL	WORD
POSREP	DB	reqd			; MATCH FLAG LOW		       ;AC021;
POSTYP	DB	f_spec + drv_id 	; MATCH FLAG HIGH		       ;AC021;
	DW	0001H			; CAPS BY FILE TABLE
	DW	OFFSET POS_BUFF 	; PLACE RESULT IN POSITIONAL BUFFER
	DW	OFFSET NOVALS		; NO VALUES LIST REQUIRED
	DB	0			; NO KEYWORDS

reqd	equ	0
f_spec	equ	2
drv_id	equ	1
					;---------------------------------------
					;  VALUE LIST FOR POSITIONAL
					;---------------------------------------

NOVALS	LABEL	WORD
	DB	0			; NO VALUES

;			$SALUT (4,25,30,41)

					;---------------------------------------
					;  RETURN BUFFER FOR POSITIONAL INFORMATION
					;---------------------------------------
POS_BUFF		LABEL BYTE
POS_TYPE		DB   ?		; TYPE RETURNED
POS_ITEM_TAG		DB   ?		; SPACE FOR ITEM TAG
POS_SYN 		DW   ?		; POINTER TO LIST ENTRY
POS_OFF 		LABEL WORD
POS_DRV_ID		DB   ?		; SPACE FOR DRIVE NUMBER (1=A, 2=B, ect)
			DB   ?		;				       ;AC021;
POS_SEG 		DW   ?		;				       ;AC021;


failopen		equ  0		; extended open 'does not exist action
openit			equ  1		; extended open 'exists' action
replaceit		equ  2		; extended open 'exists' action - replace

OPEN_PARMS		label dword

open_off		dw   ?		; name pointer offset
open_seg		dw   ?		; name pointer segment

PACKET			dw   0,0	; CONTROL PACKET		       ;AN001;
packet_sectors		dw   0		; COUNT 			       ;AN001;
PACKET_BUFFER		dw   0,0	; BUFFER ADDRESS		       ;AN001;

					;---------------------------------------
					;  Buffer for IOCtl Get/Set Media
					;---------------------------------------

IOCTL_BUF		LABEL BYTE

IOCtl_Level		DW   0		; INFO LEVEL (SET ON INPUT)
IOCtl_Ser_No_Low	DW   ?		; SERIAL #
IOCtl_Ser_No_Hi 	DW   ?		; SERIAL #
IOCtl_Vol_ID		DB   "NO NAME    " ; VOLUME LABEL - 11 bytes
IOCTL_File_Sys		DB   8 DUP(' ') ; FILE SYSTEM TYPE

IOCTL_Ser_Vol_Sys	equ  $ - IOCtl_Ser_No_Low
file_sys_size		equ  $ - IOCtl_File_Sys

File_Sys_End		LABEL WORD

			db   0		; safety

fat_12			DB   "FAT12   " ; 12 bit FAT
FAT_len 		equ  $ - fat_12
fat_16			DB   "FAT16   " ; 16 or 32 bit FAT

					;---------------------------------------
					; SUBLIST for Message call
					;---------------------------------------

.xlist
			include sysmsg.inc

			MSG_UTILNAME <SYS> ;				       ;AN000;

			MSG_SERVICES <MSGDATA> ;			       ;AN000;
.list

SUBLIST 		LABEL DWORD

			DB   sub_size	; size of sublist
			DB   0		; reserved
insert_ptr_off		DW   ?		; pointer to insert - offset
insert_ptr_seg		DW   ?		; pointer to insert - segment
insert_number		DB   1		; number of insert
			DB   Char_Field_ASCIIZ ;type flag
insert_max		DB   3		; maximum field size (limited to 3)
					;   - this handles - SYS
					;   - and - D:\
			DB   1		; minimum field size
			DB   " "	; pad character

sub_size		equ  $ - SUBLIST ; size of sublist

sys_ptr 		db   "SYS",0

bio_owns_it		db   0
EntryFree		db   0		; for create file

;*** WARNING ***
; KEEP THE FOLLOWING ITEMS IN THE EXACT ORDER BELOW!!!
DOSEntFree		DB   1
BIOSEntFree		DB   1

Xfer_data		STRUC

InFH			DW   ?		; file handle of source
LenLow			DW   ?		; 32-bit length of source
LenHigh 		DW   ?
FTime			DW   ?		; place to store time of write
FDate			DW   ?		; place to store date of write
OutFH			DW   ?		; fh of destination

Xfer_data		ENDS

BIOSInFH		DW   ?		; file handle of source BIOS
BIOSLenLow		DW   ?		; 32-bit length of BIOS
BIOSLenHigh		DW   ?
BIOSTime		DW   2 DUP (?)	; place to store time of BIOS write
BIOSOutFH		DW   ?		; fh of BIOS destination
BIOSPos 		dw   0,0	;AN001;lseek position into file

DOSInFH 		DW   ?		; file handle of source DOS
DOSLenLow		DW   ?		; 32-bit length of DOS
DOSLenHigh		DW   ?
DOSTime 		DW   2 DUP (?)	; place to store time of DOS write
DOSOutFH		DW   ?		; fh of DOS destination
DOSPos			dw   0,0	;AN001;lseek position into file

IF IBMCOPYRIGHT
FCBDOS			DB   "IBMDOS  COM"
FCBBIO			DB   "IBMBIO  COM"
ELSE
FCBDOS			DB   "MSDOS   SYS"
FCBBIO			DB   "IO      SYS"
ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   The following is a Extended FCB
ExtFCB			db   0FFh
			db   5 dup (0)
			db   DOS_volume_atrib
ExtFCB_Drive		db   0
ExtFCB_Name		db   "???????????"
			db   24 dup (0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DOS_BUFFER		DB   80h DUP (?)
cbBuf			DW   ?		; number of bytes in buffer
pDOS			DW   ?		; offset of beginning of DOS in buffer
pDOSEnd 		DW   ?		; offset of end of DOS in buffer


public			boot
BOOT			LABEL BYTE
.xlist
			INCLUDE BOOT.INC
.list
					;
					; Following structure used by Generic IOCTL call Get Device Parameters to get
					; the BPB of a hard disk. It 'overflows' into area of BUF.
					;
DeviceParameters	a_DeviceParameters <1,DEV_HARDDISK>

DATA			ENDS

CODE			SEGMENT PARA PUBLIC

			EXTRN SYSLOADMSG:near, SYSDISPMSG:near, SYSPARSE:near
			EXTRN Data_Space:WORD, Find_DPB:near,
			EXTRN Move_DIR_Entry:near, Free_Cluster:near, Direct_Access:near

			BREAK <SYS - Main>
;******************* START OF SPECIFICATIONS ***********************************
;Routine name:	Main
;*******************************************************************************
;
;Description: Main control routine. Subroutines are structured so that they
;	      will pass back an error return code (message number) and set
;	      the fail flag (CF) if there was a fatal error.
;
;	NOTES:
;
;  1 -	This program uses its own internal stack.  The stack space provided
;	by DOS is used as an input buffer for transfering IBMBIO and IBMDOS.
;
;	SYS is linked with the CODE segment followed by the DATA segment. The
;	last symbol in DATA is BUF. It marks the end end of data and the
;	start of the BUFfer.  The BUFfer extends from here to SP.  The first
;	6.5Kb (13 sectors) in BUFfer are used for up to 12 sectors of the FAT
;	or the directory. In Main, the remaining space is set
;	as follows:
;		      cdBuf = SP - ( FAT_BUF + BUF )
;
;  2 -	The main line program calls 1 routine that loops until specific
;	requirements are met. It is:
;			Get_System_Files - if default drive has replaceable
;					   media this routine loops until
;					   a diskette with the correct system
;					   files is inserted.
;
;  3 -	Great effort is expended to keep the number of open files to a minimum.
;	This is required in case output is directed to NULL. (See DOS 4.00
;	PTR P71)
;
;Called Procedures: Init_Input_Output
;		    Validate_Target_Drive
;		    Get_System_Files
;		    Check_SYS_Conditions
;		    Do_SYS
;		    Message
;
;Input: Command line input in PSP
;
;Ouput: no error - System transfered to target media
;	   error - Appropriate error message displayed
;
;Change History: Created	5/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Main
;
;	setup messages and parsing (CALL Init_Input_Output)
;	if there is no error and
;		verify target drive is valid (CALL Validate_Target_Drive)
;	if there is no error and
;		get system files loaded (CALL Get_System_Files)
;	if there is no error and
;		verify target drive is SYSable (Check_SYS_Conditions)
;	if there is no error and
;		perform SYS operation (CALL Do_SYS)
;	if no error and
;		clean up loose ends (CALL Do_End)
;	if no error
;		load return code (System transfered)
;	endif
;	display message (CALL Message)
;	ret
;
;	END  Main
;
;******************-  END  OF PSEUDOCODE -**************************************

			ASSUME CS:CODE,DS:NOTHING,ES:NOTHING

			ORG  80H

PSP_PRAM		DB   128 DUP(?)

START:			JMP  BEGIN

			DB   " - SYS - Utility "
			DB   01Ah

			even

			db   510 dup(0) ; stack

EOS			EQU  BYTE PTR $

			DW   0		; RETURN OFFSET


public			Begin

BEGIN			PROC NEAR

;  $SALUT (4,4,9,41)

   mov	ax,OFFSET Data_Space
   add	ax,15				; round up to next segment
   mov	cl,4				; convert to segment value
   shr	ax,cl
   mov	cx,ds
   add	ax,cx				; generate DATA segment value
   mov	ds,ax

   ASSUME DS:DATA,ES:NOTHING

   mov	cx,sp				; get lowest available spot
   mov	sp,OFFSET EOS			; set up internal stack
   sub	cx,FAT_BUF + (OFFSET BUF)	; leave room for:
					;     CODE +
					;     DATA +
					;     FAT_BUF (12 sectors of FAT)

   mov	cbBuf,cx			; store length of Xfer buffer

   mov	dx,OFFSET DOS_BUFFER		; set up DTA
   mov	ah,SET_DMA
   INT	21h

   call Init_Input_Output		; setup messages and parsing	       ;AN000;

;  $if	nc,and				; there is no error and 	       ;AN000;
   JC $$IF1

   call Validate_Target_Drive		; verify target drive is valid	       ;AN000;

;  $if	nc,and				; there is no error		       ;AN000;
   JC $$IF1

   call Get_System_Files		; get system files loaded	       ;AN000;

;  $if	nc,and				; there is no error		       ;AN000;
   JC $$IF1

   call Check_SYS_Conditions		; verify target drive is SYSable       ;AN000;

;  $if	nc,and				; there is no error		       ;AN000;
   JC $$IF1

   call Do_SYS				; perform SYS operation 	       ;AN000;

;  $if	nc,and				; no error and			       ;AN000;
   JC $$IF1

   call Do_End				; clean up loose ends		       ;AN000;

;  $if	nc				; no error			       ;AN000;
   JC $$IF1

       mov  ax,(util_B shl 8) + done	; load return code (System transfered) ;AN000;

;  $endif				;				       ;AN000;
$$IF1:

   call Message 			; display message		       ;AN000;

   mov	ah,exit 			; just set function - RC set by MAIN
   int	21h				; if version is < DOS 2.0 the int 21

   ret					; ret if version < 2.00

BEGIN ENDP

   BREAK <SYS - Init_Input_Output >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Init_Input_Output
;*******************************************************************************
;
;Description: Initialize messages and Parse command line.
;
;Called Procedures: Preload_Messages
;		    Parse_Command_Line
;
;Input: PSP command line at 81h and length at 80h
;
;Output: no error  - CF = 0	  AX = 0
;	    error  - CF = 1	  AX = return code (message #)
;
;Change History: Created	5/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Init_Input_Output
;
;	load messages (CALL Preload_Messages)
;	if no error
;	    get DOS version
;	    if not = current and
;	    set not current flag
;	    if not = current - 1
;		load incorrect DOS version message
;		set fail flag
;	    else
;		if no error and
;			parse the saved command line (CALL Parse_Command_Line)
;		if no error
;			load return code (success)
;		endif
;	    endif
;	endif
;	ret
;
;	END  Init_Input_Output
;
;******************-  END  OF PSEUDOCODE -**************************************

public Init_Input_Output

   Init_Input_Output PROC NEAR

   call SysLoadMsg			; preload all error messages	       ;AN000;

;  $if	c				; if error  - set to Utility	       ;AN000;
   JNC $$IF3
       mov  ah,0bh			;				       ;AN000;
;  $else				;				       ;AN019;
   JMP SHORT $$EN3
$$IF3:
       mov  ax,(GET_VERSION shl 8)	;				       ;AN019;
       int  21h 			;				       ;AN019;
       xchg al,ah			;				       ;AN019;
       cmp  ax,(major_version shl 8) + minor_version ;			       ;AN019;
;      $if  ne				;				       ;AN019;
       JE $$IF5
	   mov	DOS_VER,0ffh		; keep track that DOS is down a level  ;AN019;
					;    0 = current (default)
;      $endif				;   ff = down one level 	       ;AN021;
$$IF5:
;      $if  be,and			;				       ;AN019;
       JNBE $$IF7
       cmp  ax,DOS_low			;				       ;AC023;
;      $if  ae				;				       ;AN019;
       JNAE $$IF7



cmp	   ax,(3 shl 8) + 40		;;;;		 to
;	   $if	e			;;;;	       cover
	   JNE $$IF8
mov	       DOS_VER,0		;;;;		4.00
;	   $endif			;;;;	  this must be remover
$$IF8:




	   clc				;				       ;AN019;
;      $else				;				       ;AN019;
       JMP SHORT $$EN7
$$IF7:
	   mov	ax,(util shl 8) + DOS_error ;				       ;AN019;
	   stc				;				       ;AN019;
;      $endif				;				       ;AN019;
$$EN7:

;      $if  nc,and			; no error and			       ;AN000;
       JC $$IF12

       xor  cx,cx			; zero out # of parms processed so far ;AN000;
       mov  si,command_line		; move here to loop thru twice	       ;AN000;
       call Parse_Command_Line		; parse the saved command line	       ;AN000;

;      $if  nc				; no error			       ;AN000;
       JC $$IF12

	   mov	al,noerror		; load return code (success)	       ;AN000;

;      $endif				;				       ;AN000;
$$IF12:
;  $endif				;				       ;AC019;
$$EN3:

   ret					;				       ;AN000;

   ENDPROC Init_Input_Output

   BREAK <SYS - Parse_Command_Line >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Parse_Command_Line
;*******************************************************************************
;
;Description: Parse the command line. Check for errors, loading return code and
;	      setting fail flag if found. Use parse error messages except in
;	      case of no parameters, which has its own message.
;
;Called Procedures: SysParse
;
;Input: None
;
;Output: no error - CF = 0
;	    error - CF = 1	  AX = return code (Parse error + error #)
;
;Change History: Created	5/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Parse_Command_Line
;
;	parse command line (Call Do_Parse)
;	if parse error
;		call GetError to find out what happened
;		(fail flag set)
;	else
;		if filespec found
;			set up to move filespec into SourceBIOSName
;			call Move_It to do the move
;			save size of filespec
;			set source spec flag
;		else
;			call Set_Target to process drive id (only other non error
;		endif
;		turn off filespec as valid input
;		if first parm was NOT a filespec (ie a drive id)
;			turn on optional bit
;		else
;			force required parms to 2
;		endif
;		call Do_Parse
;		if no errors
;			call Set_Target to initialize drive id
;			call Do_Parse to look for EOF or error
;			if eol
;				clear error flag
;			else
;				call Get_Error to see what went wrong
;			endif
;		else
;			if not EOL
;				call Get_Error to see what went wrong
;			else
;				clear error flag
;			endif
;		endif
;	endif
;
;	ret
;
;	END  Parse_Command_Line
;
;******************-  END  OF PSEUDOCODE -**************************************

public Parse_Command_Line

   Parse_Command_Line PROC NEAR
					;---------------------------------------
					; Parse Equates
					;---------------------------------------
;			  $SALUT (4,27,34,41)

eol			  equ	 -1	; Indicator for End-Of-Line	       ;AN000;
noerror 		  equ	 0	; Return Indicator for No Errors       ;AN000;
command_line		  equ	 081H	; offset of command line in PSP        ;AN000;
Syntax_Error		  equ	 9	; PARSE syntax error		       ;AN000;

;  $SALUT (4,4,9,41)

					;---------------------------------------
					;  Get address of command line
					;---------------------------------------

   push ds				;				       ;AN000;
   pop	es				;				       ;AN000;
   lea	di,PARMS			;				       ;AC021:

   call Do_Parse			;				       ;AC021:

   cmp	ax,0				; did we find our required parm?       ;AN000;

;  $if	ne				; no -check what happened	       ;AN000;
   JE $$IF15

       call Get_Error			;				       ;AC021;

;  $else				;				       ;AC021;
   JMP SHORT $$EN15
$$IF15:

       cmp  POS_TYPE,5			; is it a file spec?		       ;AN021;
;      $if  e				; if it is a file spec		       ;AN021;
       JNE $$IF17
	   push ds			; copy spec into source 	       ;AN021;
	   push di			;				       ;AN021;
	   push si			;				       ;AN021;
	   lea	di,SourceSpec		;				       ;AN021;
	   mov	si,word ptr POS_OFF	;				       ;AN021;
	   mov	ax,POS_SEG		;				       ;AN021;
	   mov	ds,ax			;				       ;AN021;

	   ASSUME ds:nothing,es:DATA

	   xor	bx,bx			;				       ;AN021;

	   call Move_Source		;				       ;AN021;

	   pop	si			;				       ;AN021;
	   pop	di			;				       ;AN021;
	   pop	ds			;				       ;AN021;

	   ASSUME ds:DATA,es:nothing

	   mov	SourceSize,bx		;				       ;AN021;
	   mov	Spec_Flag,1		; set spec flag 		       ;AN021;
;      $else				; must be a drive id		       ;AN021;
       JMP SHORT $$EN17
$$IF17:
	   call Set_Target		; initialize target just in case       ;AN021;
	   mov	SourceSpec,al		; save Source Spec		       ;AN000;
					; remember that the colon and size
;      $endif				;				       ;AN021;
$$EN17:
       and  POSTYP,drv_id		; off filespec bit - on drive bit      ;AN021;
       cmp  Spec_Flag,0 		; do we have a source spec ?	       ;AN021;
;      $if  e				; if spec flag not set		       ;AN021;
       JNE $$IF20
	   inc	POSREP			; turn on optional		       ;AN021;
;      $else				;				       ;AN021;
       JMP SHORT $$EN20
$$IF20:
	   inc	PAR_MIN 		; must have the second parm.	       ;AN021;
;      $endif				;				       ;AN021;
$$EN20:

       call Do_Parse			;				       ;AN021;

       cmp  ax,0			; no parse errors?		       ;AN000;

;      $if  e				; if no error - must be a drive id     ;AN021;
       JNE $$IF23
	   call Set_Target		; initialize target		       ;AN021;
	   cmp	Spec_Flag,0		; do we have a source spec ?	       ;AN021;
;	   $if	e			; if spec flag not set		       ;AN021;
	   JNE $$IF24
	       inc  Spec_Flag		; turn it on			       ;AN021;
;	   $endif			;				       ;AN021;
$$IF24:

	   call Do_Parse		; make sure there are no extra parms.  ;AN021;
	   cmp	ax,eol			;				       ;AN021;
;	   $if	e			;				       ;AN021;
	   JNE $$IF26
	       clc			;				       ;AN021;
;	   $else			;				       ;AN021;
	   JMP SHORT $$EN26
$$IF26:
	       call Get_Error		;				       ;AN021;
;	   $endif			;				       ;AN021;
$$EN26:
;      $else				; could be EOL or error 	       ;AN021;
       JMP SHORT $$EN23
$$IF23:
	   cmp	ax,eol			; is it EOL ?			       ;AN021;
;	   $if	ne			; if it is not eol		       ;AN021;
	   JE $$IF30
	       call Get_Error		; error - make sure it makes sense     ;AN021;
;	   $else			;				       ;AN021;
	   JMP SHORT $$EN30
$$IF30:
	       clc			;				       ;AN021;
;	   $endif			;				       ;AN021;
$$EN30:
;      $endif				;				       ;AN021;
$$EN23:
;  $endif				;				       ;AN000;
$$EN15:

   ret					;				       ;AN000;


   Move_Source PROC NEAR

;  $search				;				       ;AN021;
$$DO35:
       lodsb				;				       ;AN021;
       stosb				;				       ;AN021;
       inc  bl				;				       ;AN021;
       cmp  bl,54			; are we past the maximum?	       ;AN021;
;  $exitif a				;				       ;AN021;
   JNA $$IF35
       mov  ax,(util_B SHL 8) + bad_path ; Invalid path 		       ;AN021;
       stc				;				       ;AN021;
;  $orelse				;				       ;AN021;
   JMP SHORT $$SR35
$$IF35:
       or   al,al			;				       ;AN021;
;  $endloop z				;				       ;AN021;
   JNZ $$DO35
       dec  bl				;				       ;AN021;
       clc				;				       ;AN021;
;  $endsrch				;				       ;AN021;
$$SR35:

   ret					;				       ;AN021;

   ENDPROC Move_Source

   Do_Parse PROC NEAR

   mov	insert_ptr_off,si		; save it in case of error	       ;AN024;
   push cs				;				       ;AN000;
   pop	ds				;				       ;AN000;
   xor	dx,dx				;				       ;AN021;

   ASSUME ds:nothing,es:DATA

   call SysParse			; parse command line		       ;AN000;

   push es				;				       ;AN000;
   pop	ds				;				       ;AN000;

   ASSUME ds:DATA,es:nothing


   ret					;				       ;AN021;

   ENDPROC Do_Parse

   Set_Target PROC NEAR

   mov	al,byte ptr pos_drv_id		; initalize drive id		       ;AN000;
   mov	TargDrvNum,al			; save it for later		       ;AN000;
   mov	ExtFCB_Drive,al 		; save it for finding VOL id	       ;AN000;
   or	al,num_2_letter 		; convert to a drive letter	       ;AC000;
   mov	TargSpec,al			; save it for later		       ;AN000;
   mov	TargDrv,al			;				       ;AC000;
   ret					;				       ;AN021;

   ENDPROC Set_Target

   Get_Error PROC NEAR

   lea	bx,Parse_Ret_Code		; error - make sure it makes sense     ;AN000;
   xlat cs:[bx] 			;				       ;AN000;
   mov	ah,parse_error			; indicate parse error CLASS	       ;AN000;
   stc					; set fail flag 		       ;AN000;
   ret					;				       ;AN021;

   ENDPROC Get_Error

Parse_Ret_Code label byte

   db	0				; Ret Code 0 -			       ;AN000;
   db	1				; Ret Code 1 - Too many operands       ;AN000;
   db	2				; Ret Code 2 - Required operand missing;AC002;
   db	9				; Ret Code 3 - Not in switch list provided ;AC002;
   db	9				; Ret Code 4 - Not in keyword list provided;AC002;
   db	9				; Ret Code 5 - (not used)	       ;AN000;
   db	9				; Ret Code 6 - Out of range specified  ;AN000;
   db	9				; Ret Code 7 - Not in value list provided
   db	9				; Ret Code 8 - Not in string list provided
   db	9				; Ret Code 9 - Syntax error

   ENDPROC Parse_Command_Line

   BREAK <SYS - Validate_Target_Drive >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Validate_Target_Drive
;*******************************************************************************
;
;Description: Verify that target drive was specified, is not default drive,
;	      is a valid drive letter, and is not a network drive
;
;Called Procedures: Check_Default_Drive
;		    Check_Target_Drive
;		    Check_For_Network
;
;Input: None
;
;Output: no error  - CF = 0	  AX = 0
;	    error  - CF = 1	  AX = return code (message #)
;
;Change History: Created	5/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Validate_Target_Drive
;
;	can't have target as default (CALL Check_Default_Drive)
;	if no error and
;		can't have target as network (CALL Check_For_Network)
;	if no error
;		see if valid drive letter (CALL Check_Target_Drive)
;	ret
;
;	END  Validate_Target_Drive
;
;******************-  END  OF PSEUDOCODE -**************************************

public Validate_Target_Drive

   Validate_Target_Drive PROC NEAR

   call Check_Default_Drive		; can't have target as default         ;AN000;

;  $if	nc,and				; no error and			       ;AN000;
   JC $$IF40

   call Check_For_Network		; can't have target as network         ;AC022;

;  $if	nc				; no error			       ;AN000;
   JC $$IF40

       call Check_Target_Drive		; see if valid drive letter	       ;AC022;

;  $endif				;				       ;AN000;
$$IF40:

   ret					;				       ;AN000;

   ENDPROC Validate_Target_Drive

   BREAK <SYS - Check_Default_Drive >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Check_Default_Drive
;*******************************************************************************
;
;Description: Check to see if drive specified is default drive. If it is,
;	      load return code and set fail flag.
;
;Called Procedures: None
;
;Input: None
;
;Output: no error - CF = 0
;	    error - CF = 1	AX = 16d - Can not specify default drive
;
;Change History: Created	5/01/87 	FG
;Change History: Ax021		2/22/88 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Check_Default_Drive
;
;	initialize BIO and DOS found flags
;	if source specified
;		copy source into SourceDOSName from SourceBIOName
;	else
;		get_default_drive (INT21 Get_Default_Drive + 00 <1900>)
;		if target drive = default drive
;			load return code (Can not specify default drive)
;			set fail flag
;		else
;			initialize SourceBIOName and SourceDOSName
;			reset fail flag
;		endif
;	endif
;	remove	blanks in \IBMBIO.COM
;	remove	blanks in \IBMDOS.COM
;	ret
;
;	END  Check_Default_Drive
;
;******************-  END  OF PSEUDOCODE -**************************************

public Check_Default_Drive

   Check_Default_Drive PROC NEAR

   push ds
   pop	es

   ASSUME DS:DATA,ES:DATA

   mov	DOSEntFree,1			; set to not found		       ;AC021;
   mov	BIOSEntFree,1			; set to not found		       ;AC021;
   cmp	Spec_Flag,1			; was a source specified ?	       ;AN021;
;  $if	e				; if a source was specified	       ;AN021;
   JNE $$IF42
       lea  si,SourceSpec		; copy source for IBMDOS.COM	       ;AN021;
       mov  al,[si]			; get the drive ID		       ;AN025;
       sub  al,num_2_letter		; convert it to a 1 base number        ;AN025;
       mov  DEFALT,al			; save it in case its removable        ;AN025;
       lea  di,SourceDOSName		;				       ;AN021;
       mov  cx,SourceSize		; set up size to move		       ;AN021;
       rep  movsb			; move it!			       ;AN021;

;  $else				; figure out what the default is       ;AN021;
   JMP SHORT $$EN42
$$IF42:

       mov  ax,(Get_Default_Drive shl 8) + not_used ; get_default_drive
       INT  21h 			;   Get_Default_Drive  <1900>
       inc  al				; turn from phys drive to logical drive
       mov  DEFALT,al			; save default for later
       mov  SourceSpec,al
       or   SourceSpec,num_2_letter	; covert number to letter
       cmp  al,TargDrvNum		; is target drive = default drive
;      $if  e				; if it is the same - we have a problem;AC000;
       JNE $$IF44

	   mov	ax,(util_B shl 8) + not_on_default ; load return code
					;      - Can not specify default drive
	   stc				; set fail flag

;      $else				; it wasn't = so its ok                ;AC000;
       JMP SHORT $$EN44
$$IF44:

					; initalize SourceBIOSNane, SourceDOSName
	   mov	al,DEFALT
	   or	al,num_2_letter 	; turn into letter
	   mov	byte ptr SourceBIOSName,AL ; twiddle source name
	   mov	SourceDOSName,AL	; twiddle source name
	   clc				; reset fail flag		       ;AN000;

;      $endif				;				       ;AC000;
$$EN44:
;  $endif				;				       ;AN021;
$$EN42:
;  $if	nc				; if no error to this point	       ;AN021;
   JC $$IF48
       cld				;				       ;AN021;

       IF   IBMCOPYRIGHT
       mov  bx,NameLen			;				       ;AN021;
       mov  cx,bx			;				       ;AN021;
       ELSE
       mov  cx,BIOSNameLen
       ENDIF

       lea  di,SourceBiosName		; move IBMBIO.COM into place	       ;AN021;
       add  di,SourceSize		; move to end of specified part        ;AN021;
       lea  si,SourceBIOS		; point to system file name	       ;AN021;
       rep  movsb			;				       ;AN021;

       IF   IBMCOPYRIGHT
       mov  cx,bx			;				       ;AN021;
       ELSE
       mov  cx,DosNameLen
       ENDIF

       lea  di,SourceDOSName		; move IBMDOS.COM into place	       ;AN021;
       add  di,SourceSize		; move to end of specified part        ;AN021;
       lea  si,SourceDOS		; point to system file name	       ;AN021;
       rep  movsb			;				       ;AN021;
;  $endif				;				       ;AN021;
$$IF48:

   ret					;				       ;AN000;

   ENDPROC Check_Default_Drive

   BREAK <SYS - Check_Target_Drive >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Check_Target_Drive
;*******************************************************************************
;
;Description: Determine if target drive is valid. To do this, we will make an
;	      IOCTL - check media ID call.
;
;Called Procedures:
;
;Input:  Default_Drive
;
;Output: no error - CF = 0
;	    error - CF = 1	  AX = 16d - Can not specify default drive
;
;Change History: Created	5/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Check_Target_Drive
;
;	Check media ID (INT21 IOCTL + IOCTL_CHANGEABLE? <4408>)
;	if no error
;		if invalid drive
;			set return code
;			set fail flag
;		else
;			clear fail flag
;	else
;		reset fail flag
;	endif
;	if no error
;		if ASSIGNed or SUBSTd drive
;			set return code
;			set fail flag
;		else
;			clear fail flag
;	else
;		reset fail flag
;	endif
;	ret
;
;	END  Check_Target_Drive
;
;******************-  END  OF PSEUDOCODE -**************************************

public Check_Target_Drive

   Check_Target_Drive PROC NEAR

   mov	bl,TargDrvNum			; get the target drive number	       ;AN000;
   mov	ax,(IOCTL SHL 8) + IOCTL_CHANGEABLE? ; do a media check 	       ;AC000;
   INT	21h				;	  IOCtl + 08 <4408>	       ;AC000;

   cmp	ax,0fh				; is it invalid - al = F (CF may be set;AC000;

;  $if	e				;				       ;AC000;
   JNE $$IF50

       mov  ax,(DOS_error shl 8) + extended_15 ; load return code	       ;AC000;
					;		- invalid drive
       stc				;				       ;AC000;

;  $else				; if valid device so far - make sure   ;AN012;
   JMP SHORT $$EN50
$$IF50:
					; its not ASSIGNed or SUBSTed drive
       mov  si,offset TargSpec		; point to Target Spec		       ;AN012;
       mov  di,offset DIR_SECTOR	; point at output buffer	       ;AN012;
       mov  ax,(xNameTrans SHL 8)	; check for name translation	       ;AN012;
       int  21h 			; get real path 		       ;AN012;
;      $if  nc				;				       ;AC012;
       JC $$IF52
	   mov	bl,byte ptr [TargSpec]	; get drive letter from path	       ;AN012;
	   cmp	bl,byte ptr DIR_SECTOR	; did drive letter change?	       ;AN012;
;	   $if	ne			; if not the same, it be bad	       ;AN012;
	   JE $$IF53
	       lea  si,sys_ptr		; set insert pointer in SUBLIST        ;AN012;
	       mov  [insert_ptr_off],si ;				       ;AN012;
	       mov  [insert_ptr_seg],ds ;				       ;AN012;
	       lea  si,sublist		; set pointer to SUBLIST	       ;AN012;
	       mov  ax,(util_C shl 8) + cant_assign ; load ret cd (Cannot..SUB);AN012;
	       stc			; tell user			       ;AN012;
;	   $else			; - its ok			       ;AN012;
	   JMP SHORT $$EN53
$$IF53:
	       clc			; keep going			       ;AN012;
;	   $endif			;				       ;AN012;
$$EN53:
;      $else				; - its a critical error	       ;AN012;
       JMP SHORT $$EN52
$$IF52:
	   xor	ah,ah			; set up for extended error call       ;AN012;
	   inc	ah			;				       ;AN012;
;      $endif				;				       ;AN012;
$$EN52:
;  $endif				;				       ;AN012;
$$EN50:

   ret					;				       ;AC000;

   ENDPROC Check_Target_Drive

   BREAK <SYS - Check_For_Network >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Check_For_Network
;*******************************************************************************
;
;Description: Verify that the target drive is local, and not a shared drive.
;	      If shared,load return code and set fail flag.
;
;	      NOTE: This is a design point on how to determine net
;
;CALLed Procedures: None
;
;Input:  None
;
;Output: no error - CF = 0
;	    error - CF = 1	  AX = return code = 7 - Cannot SYS to a Network drive
;
;Change History: Created	5/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Check_For_Network
;
;	IOCtl call to see if target drive is local
;	if target drive not local (INT21 IOCtl + 09 <4409>) and
;	if return code indicates network drive (test 1200h)
;		set insert pointer in SUBLIST
;		set pointer to SUBLIST
;		load return code (Cannot SYS to a Network drive)
;		set fail flag
;	else
;		reset fail flag
;	endif
;	ret
;
;	END  Check_For_Network
;
;******************-  END  OF PSEUDOCODE -**************************************

public Check_For_Network

   Check_For_Network PROC NEAR

					; IOCtl call to see if target drive is local
   mov	bl,TargDrvNum			;   x = IOCTL (getdrive, Drive+1)      ;AC022;
   mov	ax,(IOCTL SHL 8) + dev_local
   INT	21h				; IOCtl + dev_local  <4409>

;  $if	nc,and				; target drive local and	       ;AC000;
   JC $$IF59

   test dx,1200H			; check if (x & 0x1000)
					;      (redirected or shared)
;  $if	nz				; return code indicates network drive  ;AC000;
   JZ $$IF59

       lea  si,sys_ptr			; set insert pointer in SUBLIST        ;AN000;
       mov  [insert_ptr_off],si 	;				       ;AN000;
       mov  [insert_ptr_seg],ds 	;				       ;AN000;
       lea  si,sublist			; set pointer to SUBLIST	       ;AN000;
       mov  ax,(util_C shl 8) + cant_network ; load return code (Cannot SYS to.;AC000;
       stc				; set fail flag 		       ;AN000;

;  $else				;				       ;AC000;
   JMP SHORT $$EN59
$$IF59:

       clc				; reset fail flag		       ;AC000;

;  $endif				;				       ;AC000;
$$EN59:

   ret					;				       ;AN000;

   ENDPROC Check_For_Network

   BREAK <SYS - Get_System_Files >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Get_System_Files
;*******************************************************************************
;
;Description:	    Ensure that the the files IBMBIO and IBMDOS are available
;		    on the source media. If they are not on the source media,
;		    and the media is removeable, a prompt will be issued to
;		    insert a new source.
;
;Called Procedures: Prompt_For_Media	       Open_File
;		    Check_Removable	       Fill_Memory
;
;Input: 	    IBMBIO and IBMDOS on source media
;
;Output: no error - CF = 0
;	    error - CF = 1	  AX = return code (message #)
;
;Change History:    Created	   5/01/87	   FG
;		    Major change   1/07/88	   FG	Ax019 now makes SYS check
;							for the CORRECT version
;							of IBMBIO !
;							IBMBIO looks like this:
;
;				       1	2	 3	  4	  5
;				  ÚÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄ
;				  ³  JMP   ³   LO   ³	HI   ³extected_version³
;				  ÀÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄ
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Get_System_Files
;
;	initalize SourceBIOSNane, SourceDOSName
;	do
;		find IBMBIOS
;		if found and
;			open file (CALL Open_File)
;		if no error and
;			find IBMDOS
;		if found and
;			open file (CALL Open_File)
;		if no error and
;			load memory with files (CALL Fill_Memory)
;		if no error and
;		if correct version of IBMBIO
;			reset fail flag
;			load success return code
;		else
;			check if source media replaceable (CALL Check_Removeable)
;			if fail flag reset (replaceable)
;				load message number (Insert system disk....)
;					  and class (utility)
;				set up pointer to insert (drive id)
;				prompt for source media (CALL Prompt_For_Media)
;				if fail flag reset
;					load return code (try again)
;				endif
;			endif
;		endif
;		leave if success return code
;		leave if fail flag set
;	enddo
;	ret
;
;	END  Get_System_Files
;
;******************-  END  OF PSEUDOCODE -**************************************

public Get_System_Files

   Get_System_Files PROC NEAR
   cld

;  $search				;				       ;AC018;
$$DO62:

       lea  si,DOS_BUFFER		; set up addressability
       mov  dx,OFFSET SourceBIOSName	; look on source for IBMBIOS
       mov  CX,DOS_system_atrib 	; its an 'everything' file
       mov  ah,Find_First		; do a find first INT21
       INT  21h 			;      Find_First <4Exx>

;      $if  nc,and			; if found and.....................    ;AC000;
       JC $$IF63
       mov  ax,ds:[si].find_buf_size_l	; move size (low and high)	       ;AC000;
       mov  WORD PTR NEWBIO_SIZE_LOW,AX ;     from DTA
       mov  ax,ds:[si].find_buf_size_h	;	to			       ;AC000;
       mov  WORD PTR NEWBIO_SIZE_HIGH,AX ;	  SYS data space
       mov  dx,OFFSET SourceBIOSName	; point to source name
       mov  di,OFFSET BIOSInFH		; pointer to block of data

       call Open_File			; open file

;      $if  nc,and			; if no error and....................  ;AC000;
       JC $$IF63

       mov  dx,OFFSET SourceDOSName	; look on source for IBMDOS
       mov  CX,DOS_system_atrib 	; its an 'everything' file
       mov  ah,Find_First		; do a find first INT21
       INT  21h 			;      Find_First <4Exx>

;      $if  nc,and			; if found and.......................  ;AC000;
       JC $$IF63

       mov  ax,ds:[si].find_buf_size_l	; move size (low and high)	       ;AC000;
       mov  WORD PTR NEWDOS_SIZE_LOW,AX ;   from DTA
       mov  ax,ds:[si].find_buf_size_h	;	to			       ;AC000;
       mov  WORD PTR NEWDOS_SIZE_HIGH,AX ;	   SYS data space
       mov  dx,OFFSET SourceDOSName	; pointer to source of DOS
       mov  di,OFFSET DOSInFH		; pointer to block of data

       call Open_File			; open file

;      $if  nc,and			; if no error and......................;AC000;
       JC $$IF63

       call Fill_Memory 		; load memory with files

;      $if  nc,and			; if no error..................:       ;AC019;
       JC $$IF63

       cmp  WORD PTR BUF+FAT_BUF+3,expected_version ; point to beginning       ;AN019;
					;  of buffer + near jump instruction

;      $if  e				; if correct version of IBMBIO	       ;AN019;
       JNE $$IF63

	   clc				; reset fail flag		       ;AN019:
	   mov	al,noerror		; load success return code	       ;AN000;

;      $else				; ELSE - something wrong with source   ;AC000;
       JMP SHORT $$EN63
$$IF63:

	   mov	bl,defalt		;; specify drive ;;dcl		       ;AN001;
	   call Check_Removeable	; check if source media replaceable    ;AC000;

;	   $if	nc			; fail flag reset (replaceable)        ;AC000;
	   JC $$IF65

	       mov  ax,(util_C shl 8) + sys_disk ; load message number	       ;AC000;
					;    - Insert system disk....
	       lea  si,SourceSpec	; set insert pointer to DRIVE ID       ;AC000;
	       mov  bx,SourceSize	; only display correct path length     ;AN025;

	       call Prompt_For_Media	; prompt for source media	       ;AN000;

;	       $if  nc			; fail flag reset		       ;AC000;
	       JC $$IF66

		   mov	ax,error_RC	; load return code (try again)	       ;AN000;

;	       $endif			;				       ;AC000;
$$IF66:

;	   $endif			;				       ;AC000;
$$IF65:

;      $endif				;				       ;AC000;
$$EN63:

;  $leave c				; if fail flag set		       ;AC018;
   JC $$EN62

       cmp  al,noerror			; is it an error return code?	       ;AC018;

;  $exitif e				; quit if success return code	       ;AC018;
   JNE $$IF62

       mov  bx,BIOSInFH 		;				       ;AC018;
       mov  ah,Close			;				       ;AC018;
       int  21h 			;				       ;AC018;

       mov  bx,DOSInFH			;				       ;AC018;
       mov  ah,Close			;				       ;AC018;
       int  21h 			;				       ;AC018;

;  $orelse				;				       ;AN018;
   JMP SHORT $$SR62
$$IF62:

;  $endloop long			;				       ;AC018;
   JMP $$DO62
$$EN62:
;  $endsrch				;				       ;AN018;
$$SR62:



   ret					;				       ;AN000;

   ENDPROC Get_System_Files

   BREAK <SYS - Prompt_For_Media >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Prompt_For_Media
;*******************************************************************************
;
;Description:	    Make call to Message to display:
;
;			Insert system disk in drive %1
;			and strike any key when ready
;
;Called Procedures: Message
;
;Input: 	    (AL) = message #
;		    (BL) = drive/path length
;		    (SI) = insert pointer
;
;Output: no error - CF = 0
;	    error - CF = 1	  AX = return code (DOS error)
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Prompt_For_Media
;
;	set up for message call
;	call Message  - display first line
;	if no error
;		clear insert indicator
;		load Message #x - Press any key to continue
;		ask for keystroke response (direct CON in no echo)
;		call Message  - display second line
;	endif
;	if error
;		load return code (DOS extended error)
;	endif
;	ret
;
;	END  Prompt_For_Media
;
;******************-  END  OF PSEUDOCODE -**************************************

public Prompt_For_Media

   Prompt_For_Media PROC NEAR

   mov	[insert_ptr_off],si		; set up for message call	       ;AN000;
   mov	[insert_ptr_seg],ds
   mov	insert_max,bl			; only display correct path length     ;AN025;
   lea	si,sublist			; set pointer to SUBLIST	       ;AN000;

   call Message 			; display first line		       ;AN000;

;  $if	nc				; if no error			       ;AN000;
   JC $$IF75

       mov  ax,(util_D shl 8) + press_key ; load Message		       ;AN000;
					;    - Press any key to continue
					; the class will signal to ask for
					; keystroke response
					;	 (direct CON in no echo)
       call Message			; display second line		       ;AN000;

;  $endif				;				       ;AN000;
$$IF75:

;  $if	c				; if an error occured		       ;AN000;
   JNC $$IF77

       mov  ah,DOS_error		; load return code (DOS extended error);AN000;

;  $endif				;				       ;AN000;
$$IF77:

   ret					;				       ;AN000;

   ENDPROC Prompt_For_Media

   BREAK <SYS - Check_Removeable >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Check_Removeable
;*******************************************************************************
;
;Description:	    Make IOCtl call to see if media in the drive indicated in
;		    BX is removable
;
;Called Procedures: None
;
;Input: 	    BX has drive (0=default, 1=A)
;
;Output: removeable	       - CF = 0
;	 nonremovable or error - CF = 1
;				 AX = 11d - No system on default drive
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Check_Removeable
;
;	if source not specified
;	       do an IOCTL changeable check (INT21 IOCtl + 08 <4408>)
;	       if no error
;		       test if removeable
;		       if removeable
;			       reset fail flag
;		       else
;			       load return code (No system on default drive)
;			       set fail flag
;		       endif
;	       endif
;	else
;	       load return code (No system on specified path)
;	       set fail flag
;	endif
;	ret
;
;	END  Check_Removeable
;
;******************-  END  OF PSEUDOCODE -**************************************

public Check_Removeable

   Check_Removeable PROC NEAR

   mov	ax,(IOCTL SHL 8) + IOCTL_CHANGEABLE? ; do a media check
   INT	21h				;	  IOCtl + 08 <4408>
					; cy set if remote or invalid device ;;dcl;;
;  $if	nc				;
   JC $$IF79
       cmp  ax,0			;
;      $if  e				;
       JNE $$IF80
	   clc				;
;      $else				;
       JMP SHORT $$EN80
$$IF80:
	   cmp	Spec_Flag,1		;				       ;AC025;
;	   $if	ne			;				       ;AC025;
	   JE $$IF82
	       mov  ax,(util_B shl 8) + no_sys_on_def ; No system on...        ;AC000;
;	   $else			;				       ;AC025;
	   JMP SHORT $$EN82
$$IF82:
	       mov  ax,(util_B shl 8) + system_not_found ; Invalid path or Sy..;AN021;
;	   $endif			;				       ;AC025;
$$EN82:
	   stc				;
;      $endif				;
$$EN80:
;  $endif				;
$$IF79:

   ret					;				       ;AN021;

   ENDPROC Check_Removeable

   BREAK <SYS - Open_File >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Open_File
;*****************************************************************************
;
;Description:	    Opens file and gets size and date
;
;Called Procedures: None
;
;Input: 	    ES:DI = Data space for DOS operations
;
;Output: no error - CF = 0
;	    error - CF = 1	      AX = DOS extended errors
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Open_File
;
;	open file for read (INT21 Read + 00 <3D00>)
;	if no error
;		save handle
;		find End Of File (INT21 LSeak + 02 <4202>)
;		zero offsets
;		get offsets (INT21)
;		save low part of size
;		save high part of size
;		find start of file (INT21 LSeak + 00 <4200>)
;		find last write time(INT21 File_Times + 00 <5700>)
;		save time
;		save date
;	else
;		load return code (DOS extended errors)
;	endif
;	ret
;
;	END  Open_File
;
;******************-  END  OF PSEUDOCODE -**************************************

public open_file

   Open_File PROC NEAR

   mov	ax,(OPEN SHL 8) + not_used	; open file for read
   INT	21h				;    Read + not_used <3D00>

;  $if	nc				; no error			       ;AC000;
   JC $$IF87

       mov  es:[di].InFH,ax		; save file handle		       ;AC000;
       mov  bx,ax			; get ready for seeks
       mov  ax,(LSeek SHL 8) + LSeek_EOF ; seek relative to eof
       xor  cx,cx			; zero offset
       xor  dx,dx			; zero offset
       INT  21h 			; find End Of File to get offsets
					;	LSeak + LSeek_EOF <4202>
       mov  es:[di].LenLow,ax		; save low part of size 	       ;AC000;
       mov  es:[di].LenHigh,dx		; save high part of size	       ;AC000;
       xor  dx,dx			; zero offset
       mov  ax,(LSeek SHL 8) + LSeek_Start ; seek relative to beginning
       INT  21h 			;	 LSeak + LSeek_Start <4200>
       mov  ax,(File_Times SHL 8) + 0	; find last write time
       INT  21h 			;	 File_Times + not_used <5700>
       mov  es:[di].FTime,cx		; save time			       ;AC000;
       mov  es:[di].FDate,dx		; save date			       ;AC000;

;  $else				;				       ;AC000;
   JMP SHORT $$EN87
$$IF87:

       mov  ah,DOS_error		; load return code (DOS extended error);AC000;

;  $endif				;				       ;AC000;
$$EN87:

   ret

   ENDPROC Open_File

   BREAK <SYS - Fill_Memory >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Fill_Memory
;*******************************************************************************
;
;Description:  Read in as much of IBMBIOS and IBMDOS as room permits
;
;Called Procedures: None
;
;Input: 	    None
;
;Output: no error - CF = 0
;	    error - CF = 1
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Fill_Memory
;
;	get length of buffer
;	get BIOS source handle
;	point to beginning of buffer
;	save total buffer length
;	if < 64k to read and
;	if amount to read < buffer
;		set length to IBMBIO length
;	endif
;	if amount to read > 0
;		read the file (INT21 read +00 <3F00>)
;	else
;		set size to zero
;		clear error flag (CF)
;	endif
;	if error or
;	if not all of file read
;		recover size
;		set fail flag
;	else
;		update pointer for dos read
;		recover size
;		calculate remainder
;		get DOS source handle
;		if < 64k to read and
;		if amount to read < buffer
;			set length to IBMBIO length
;		endif
;		read the file (INT21 read +00 <3F00>)
;		if no error and
;		if all of file read
;			update pointer for DOS read
;			reset fail flag
;		endif
;	endif
;	ret
;
;	END  Fill_Memory
;
;******************-  END  OF PSEUDOCODE -**************************************

public fill_memory

   Fill_Memory PROC NEAR

   mov	ax,4200h			; LSEEK to end of last read	       ;AN001;
   mov	bx,BIOSInFH			;				       ;AN001;
   mov	cx,BIOSPos[2]			;				       ;AN001;
   mov	dx,BIOSPos[0]			;				       ;AN001;
   int	21h				;				       ;AN001;
   mov	ax,4200h			; LSEEK to end of last read	       ;AN001;
   mov	bx,DOSInFH			;				       ;AN001;
   mov	cx,DOSPos[2]			;				       ;AN001;
   mov	dx,DOSPos[0]			;				       ;AN001;
   int	21h				;				       ;AN001;

   mov	cx,cbBuf			; get length of buffer
   mov	bx,BIOSInFH			; get bios source handle
   mov	dx,OFFSET BUF+FAT_BUF		; point to beginning of buffer
					; past area to read in boot rec
   push cx				; save away total length
   cmp	BIOSLenHigh,0			; is there < 64K to read?

;  $if	e,and				; if so - or...................        ;AC000;
   JNE $$IF90
					;			      :
   cmp	BIOSLenLow,cx			; more left to read?	      :
					; ie: is amount to read < buffer
;  $if	b				; if amount to read < buffer..:        ;AC000;
   JNB $$IF90

       mov  cx,BIOSLenLow		; set length to IBMBIO length

;  $endif				;				       ;AC000;
$$IF90:

   cmp	cx,0				; is there anything to read?

;  $if	a				; if so - read it
   JNA $$IF92

       mov  ah,Read			; read the file
       int  21h 			;     read + not_used <3F00>)

;  $else				; don't bother
   JMP SHORT $$EN92
$$IF92:

       xor  ax,ax
       clc

;  $endif
$$EN92:

;  $if	c,or				; if error or..................        ;AC000;
   JC $$LL95

   cmp	ax,cx				; Did we get it all?	      :

;  $if	nz				; if not all of file read.....:        ;AC000;
   JZ $$IF95
$$LL95:

       pop  cx				; recover size
       stc				; set fail flag

;  $else				;				       ;AC000;
   JMP SHORT $$EN95
$$IF95:

       add  BIOSPos[0],ax		; save amount read for later lseek     ;AN001;
       adc  BIOSPos[2],0		; save amount read for later lseek     ;AN001;

       add  dx,ax			; update pointer for DOS Read
       mov  pDOS,dx			; point to beginning of DOS
       sub  BIOSLenLow,ax		; decrement remaining
       sbb  BIOSLenHigh,0		; do 32 bit
       pop  cx				; get original length
       sub  cx,ax			; this much is left
       mov  bx,DOSInFH			; get bios source handle
       cmp  DOSLenHigh,0		; > 64K to read?
;      $if  e,and			; if < 64k to read and..........       ;AC000;
       JNE $$IF97
       cmp  DOSLenLow,cx		; is amount to read < buffer   :

;      $if  b				; if its less .................:       ;AC000;
       JNB $$IF97

	   mov	cx,DOSLenLow		; set length to IBMDOS length

;      $endif				;				       ;AC000;
$$IF97:

       mov  ah,Read			; read the file
       INT  21h 			;     read + not_used <3F00>)

;      $if  nc,and			; no error and...................      ;AC000;
       JC $$IF99

       cmp  ax,cx			; is all of file read ? 	:

;      $if  z				; all of file read..............:      ;AC000;
       JNZ $$IF99

	   add	DOSPos[0],ax		; save amount read for later lseek     ;AN001;
	   adc	DOSPos[2],0		; save amount read for later lseek     ;AN001;

	   add	dx,ax			; update pointer for DOS Read
	   mov	pDOSEnd,DX		; point to End of dos DOS
	   sub	DOSLenLow,AX		; decrement remaining
	   sbb	DOSLenHigh,0		; do 32 bit arithmetic
	   clc				; reset fail flag

;      $endif				;				       ;AC000;
$$IF99:

;  $endif				;				       ;AC000;
$$EN95:

   ret

   ENDPROC Fill_Memory

   BREAK <SYS - Check_SYS_Conditions >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Check_SYS_Conditions
;*******************************************************************************
;
;Description: Verify that the target disk is in a state that a SYS to it will
;	      be allowed. If an error occurs in any of the called routines,
;	      the return code will already be loaded by the failing routine.
;
;Called Procedures: Verify_File_System
;		    Read_Directory
;		    Verify_File_Location
;		    Determine_Free_Space
;
;Input: None
;
;Output: no error - CF = 0
;	    error - CF = 1	  AX = return code (message #)
;
;Change History: Created	5/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Check_SYS_Conditions
;
;	verify target is a FAT file system (CALL Verify_File_System)
;	if no error and
;		load root directory of target (CALL Read_Directory)
;	if no error and
;		check that IBMBIO,IBMDOS are in right place (CALL Verify_File_Location)
;	if no error and
;		check for  sufficient space for system files (CALL Determine_Free_Space)
;	if no error
;		load return code (success)
;		reset fail flag
;	endif
;	ret
;
;	END  Check_SYS_Conditions
;
;******************-  END  OF PSEUDOCODE -**************************************

public Check_SYS_Conditions

   Check_SYS_Conditions PROC NEAR

   call Verify_File_System		; verify target is a FAT file system   ;AN000;

;  $if	nc,and				; no error and			       ;AN000;
   JC $$IF102

   call Read_Directory			; load root directory of target        ;AN000;

;  $if	nc,and				; no error and			       ;AN000;
   JC $$IF102

   call Verify_File_Location		; check that IBMBIO,IBMDOS are in right;AN000;
					;    place
;  $if	nc				; no error and			       ;AN000;
   JC $$IF102

       call Determine_Free_Space	; check if enough space for system file;AN000;

;  $endif				;				       ;AN000;
$$IF102:

   ret					;				       ;AN000;

   ENDPROC Check_SYS_Conditions

   BREAK <SYS - Verify_File_System >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Verify_File_System
;*******************************************************************************
;
;Description: Get the file system for the specified drive, then compare to
;	      FAT. If not, issue message and exit. Must ensure that target
;	      drive has media in it before this routine is called
;
;Note:	      This routine contains code that is specifically required for
;	      operation on DOS 3.3.  This code must be removed for later releases
;	      of DOS.
;
;Called Procedures: None
;
;Input: 	    Drive Number (0=default, 1=A, 2=B) in BL
;
;Output: no error - CF = 0
;	    error - CF = 1
;		    AX = return code
;			  AH = utility messages
;			  AL = 15d - Not able to SYS to xxx file system
;		    CX = 1 - only one substitution
;		 DS:SI = sublist for substitution
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Verify_File_System
;
;	if   dos = current
;		load drive id (BL)
;		get_extended_device_parameters (INT21 IOCtl + 0Dh <440D> CX=086E) for drive
;		if error - check if old version destination
;			find out what the error was (CALL Get_DOS_Error)
;			if not old version error
;				load return code (DOS Extended Error Class)
;				set fail flag
;			else
;				reset fail flag
;			endif
;		else
;			if returned file system type = "FAT12   " or
;			if returned file system type = "FAT16   "
;				reset fail flag
;			else
;				indicate insert required
;				set up pointer for insert - sublist
;				load return code (Unable to SYS to xxxxxxxx file system)
;				set fail flag
;			endif
;		endif
;	endif
;
;	ret
;
;	END  Verify_File_System
;
;******************-  END  OF PSEUDOCODE -**************************************

public Verify_File_System

   Verify_File_System PROC NEAR

   cmp	DOS_VER,0			; running on current DOS ?	       ;AN019;
;  $if	e				; if we are			       ;AN019;
   JNE $$IF104
       mov  bl,TargDrvNum		; load drive id (BL)		       ;AN000;
       lea  dx,IOCtl_Buf		; point to output buffer	       ;AN000;
       mov  ax,(GetSetMediaID shl 8) + 0 ; get volid, ser# and filetype        ;AC019;
       INT  21h 			;  INT 21 GetSetMediaID request <6900> ;AC019;

;      $if  c				; error - check if old version dest    ;AN000;
       JNC $$IF105

	   call Get_DOS_Error		; find out what the error was	       ;AN000;

	   cmp	al,old_type_media	; is it IBM but < 4.0 ? 	       ;AN000;

;	   $if	ne			; not old version error 	       ;AN000;
	   JE $$IF106

	       mov  ah,DOS_error	; load return code (DOS Extended Error);AN000;
	       stc			; set fail flag 		       ;AN000;

;	   $else			;				       ;AN000;
	   JMP SHORT $$EN106
$$IF106:

	       clc			; reset fail flag		       ;AN000;

;	   $endif			;				       ;AN000;
$$EN106:

;      $else				; ELSE it is => 4.00		       ;AN000;
       JMP SHORT $$EN105
$$IF105:

	   lea	si,IOCtl_File_Sys	; see if file type is fat12	       ;AN000;
	   lea	di,fat_12		;				       ;AN000;
	   mov	cx,file_sys_size	;				       ;AN000;
	   cld				;				       ;AN000;
	   repe cmpsb			;				       ;AN000;
	   cmp	cx,3			; did it fail at the 2 in fat12 ?      ;AN000;

;	   $if	e,and			; if it did and............	       ;AN000;
	   JNE $$IF110

	   cmp	BYTE PTR ds:[si-1],"6"	; was it a 6 ?		  :	       ;AN000;

;	   $if	e			; if it was...............:	       ;AN000;
	   JNE $$IF110

	       repe cmpsb		; then keep going		       ;AN000;

;	   $endif			;				       ;AN000;
$$IF110:

	   cmp	cx,0			; did we reach the end ?	       ;AN000;

;	   $if	e			; if we did it was "FAT12   " or       ;AN000;
	   JNE $$IF112
					;     "FAT16   " so its OK to SYS

	       clc			; reset fail flag		       ;AN000;

;	   $else			;				       ;AN000;
	   JMP SHORT $$EN112
$$IF112:

	       lea  di,File_Sys_End	; set up pointer to end of insert      ;AN000;
	       dec  di			; back up to last character	       ;AN000;
	       mov  cx,file_sys_size	; strip off trailing blanks	       ;AN017;
	       mov  al," "		; strip off trailing blanks	       ;AN017;
	       std			; scan backwards		       ;AN017;
	       repe scas IOCTL_File_Sys ;				       ;AN017;
	       cld			; stops at 2 past last " "	       ;AN017;
	       inc  di			; 1 past			       ;AN017;
	       inc  di			; last (first) blank		       ;AN017;
	       xor  al,al		; make it an ASCIIZ		       ;AN017;
	       stos IOCTL_File_Sys	;				       ;AN017;
	       lea  si,IOCTL_File_Sys	; set up pointer to the insert	       ;AN000;
	       mov  [insert_ptr_off],si ;				       ;AN017;
	       mov  [insert_ptr_seg],ds ;				       ;AN017;
	       lea  si,sublist		; set pointer to SUBLIST	       ;AN017;
	       mov  ax,(util_C shl 8) + cant_sys ; load return code	       ;AN000;
					;  - Unable to SYS to xxx file system
	       stc			; set fail flag 		       ;AN000;

;	   $endif			;				       ;AN000;
$$EN112:

;      $endif				;				       ;AN000;
$$EN105:

;  $else				; not running on current DOS	       ;AN019;
   JMP SHORT $$EN104
$$IF104:

       clc				; keep going			       ;AN019;

;  $endif				; running on current DOS	       ;AN019;
$$EN104:

   ret					;				       ;AN000;

   ENDPROC Verify_File_System

   BREAK <SYS - Read_Directory >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Read_Directory
;*******************************************************************************
;
;Description: Read in first sector of directory. The reason that we do the
;	      direct read of the directory is the find first/next or search
;	      first/next do an exclusive search for volume labels. By using
;	      these CALLs, there is no way to determine if a volume label
;	      occupies the first location in the directory. Hence we get sleazy
;	      and read the directory directly (no pun intended) to get this
;	      info. Only read in the first sector of directory. Also, this
;	      ensures there is a media in the drive.
;
;CALLed Procedures: Prompt_for_Media, Find_DPB
;
;Input:  None
;
;Output: no error - CF = 0
;	    error - CF = 1	  AX = return code (message #)
;
;Change History: Created	5/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Read_Directory
;
;	set up drive letter in destignation filespecs
;	call Find_DPB to get directory location
;	load first DIR sector number
;	point at buffer for directory
;	read first sector of directory (INT 25h)
;	ret
;
;	END  Read_Directory
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Read_Directory

   Read_Directory PROC NEAR

   mov	al,TargDrv			; set up drive letter in destignation filespecs
   mov	BIOSName,al			; point names at destination drive
   mov	DOSName,al			;

   MOV	DL,TargDrvNum			; load drive
   PUSH DS				; save register
   call Find_DPB			; initalize DPB parameters
   POP	AX
   mov	ds,ax
   mov	es,ax
   xor	ax,ax				; request a read
   mov	dx,[first_dir_sector]		; read starting dir sector
   mov	[packet],dx			; get starting dir sector	       ;AN001;
   mov	bx,offset DIR_SECTOR
   mov	PACKET_BUFFER[0],bx		;				       ;AN001;
   mov	PACKET_BUFFER[2],ds		;				       ;AN001;
   mov	word ptr [packet_sectors],1	;				       ;AN001;
   call Direct_Access			; to read the sector

   mov	ax, (util_B shl 8) + write_fail ; load message			       ;AC000;
					;   - Write failure, diskette unuseable
					;  in case an error occured
   ret

   ENDPROC Read_Directory

   BREAK <SYS - Verify_File_Location >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Verify_File_Location
;*******************************************************************************
;
;Last Update: 09/22/87
;
;Description: Determines if IBMBIO and IBMDOS are the first two directory
;	      entries, or if these entries are empty. If so, find the size
;	      of the files if they exist. If spaces not empty and don't
;	      contain IBMBIO and IBMDOS, set fail flag and load return code.
;	      Also determines if existing IBMBIO starts in cluster 2. If not
;	      set fail flag and load return code.
;
;CALLed Procedures: None
;
;Input: 	    DIR in BUFFER
;
;Output: no error - CF = 0
;	    error - CF = 1
;		    AX = return code
;			  AH = utility essages
;			  AL = 8 - No room for system on destination disk
;			       9 - Incompatible system size
;
;Change History: Created	5/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Verify_File_Location
;
;	if all files deleted (Dir_Name in dir is 00h)
;		reset fail flag
;	else
;		if first file deleted (Dir_Name is 0E5h)
;			reset fail flag
;		else
;			if first file IBMBIO.COM
;				get IBMBIO Size
;				indicate we found IBMBIO
;				clear error flag
;			else
;				call Move_DIR_Entry
;				call Free_Cluster
;			endif
;		endif
;		if no error so far and
;		if IBMBIO found
;			call Free_Cluster
;		endif
;		if no error so far
;			if all files deleted starting at second location or
;			if second file deleted (Dir_Name is 0E5h)
;				reset fail flag
;			else
;				if second file IBMDOS.COM
;					get IBMDOS size
;					indicate we found IBMDOS
;					reset fail flag
;				else
;					call Move_DIR_Entry
;				endif
;			endif
;		endif
;	endif
;
;	ret
;
;	END  Verify_File_Location
;******************-  END  OF PSEUDOCODE -**************************************

   public Verify_File_Location

   Verify_File_Location PROC NEAR
					;---------------------------------------
					; Now see if the first two directory
					; entries are available...
					; First check for being free:
					;---------------------------------------
   mov	bp,OFFSET DIR_SECTOR
   mov	si,bp
   cmp	BYTE PTR [si],empty		; empty dir?

;  $if	e,or				; if all files deleted		       ;AC012;
   JE $$LL118
					;   (Dir_Name in dir is 00h)

   cmp	BYTE PTR [si],deleted		; is first file deleted ?

;  $if	e				; if it is			       ;AC012;
   JNE $$IF118
$$LL118:
					;   (Dir_Name is 0E5h)................:
       clc				; clear error flag		       ;AN003;
       call Free_Cluster		; check the cluster chain just in case ;AC012;

;  $else long				; not empty			       ;AC000;
   JMP $$EN118
$$IF118:
					;---------------------------------------
					; The first entry is not free.	See if
					;     the BIOS is there.
					;---------------------------------------
       mov  di,OFFSET FCBBIO		; pointer to name
       mov  cx,file_spec_length 	; length of name
       cld				; go forward
       rep  cmpsb			; check it

;      $if  e				; first file IBMBIO.COM 	       ;AC000;
       JNE $$IF120

	   dec	BIOSEntFree		; indicate we found IBMBIO ( = 0)
	   mov	si,bp
	   mov	ax,word ptr ds:[si].dir_size_l ; Get the size of IBMBIO        ;AC000;
	   mov	word ptr IBMBIO_Low,ax
	   mov	ax,word ptr ds:[si].dir_size_h ;			       ;AC000;
	   mov	word ptr IBMBIO_High,ax
	   cmp	ds:[si].dir_first,2	; does IBMBIO own Clust 2?	       ;AC005;
;	   $if	e			; if so 			       ;AC005;
	   JNE $$IF121
	       inc  [bio_owns_it]	;     - keep track		       ;AC005;
;	   $endif			;				       ;AC005;
$$IF121:

	   call Free_Cluster		;				       ;AN003;

;      $else				; its not IBMBIO		       ;AC000;
       JMP SHORT $$EN120
$$IF120:

	   mov	si,bp			; restore pointer to start of entry    ;AN003;
	   call Move_DIR_Entry		; move the entry out of the way        ;AN003;

;	   $if	nc,and			;				       ;AN003;
	   JC $$IF124

	   call Free_Cluster		; make sure reqd. clusters are free    ;AN003;

;	   $if	nc			;				       ;AC000;
	   JC $$IF124

	       xor  ax,ax		;

;	   $else			;				       ;AC000;
	   JMP SHORT $$EN124
$$IF124:

	       mov  ax,(util_B shl 8) + no_room ; load return code in case we fail;AN000;
	       stc			;    - No room for system on dest...   ;AC000;

;	   $endif			;				       ;AC000;
$$EN124:

;      $endif				;				       ;AC000;
$$EN120:

;  $endif				;				       ;AC000;
$$EN118:

					;---------------------------------------
					; Check the second entry
					;---------------------------------------

;  $if	nc				; if no errors so far		       ;AC000;
   JC $$IF129

					; ensure that the first sector of root ;AN003;
					;    is loaded			       ;AN003;
       mov  ax,[first_dir_sector]	; get starting dir sector	       ;AN001;
       mov  packet,ax			;				       ;AN001;
       mov  [packet_buffer],offset DIR_SECTOR ; 			       ;AN001;
       mov  word ptr [packet_sectors],1 ;				       ;AN001;
       xor  ax,ax			; request a read
       call Direct_Access		; to read the root

;      $if  nc				;				       ;AC000;
       JC $$IF130

	   add	bp,TYPE dir_entry	;				       ;AC000;
	   mov	si,bp			;				       ;AC000;
	   mov	ax,(util_B shl 8) + no_room ; load return code in case we fail ;AC000;
					;    - No room for system on dest..
	   cmp	BYTE PTR [si],empty	; empty dir entry?

;	   $if	e,or			; if deleted starting at 2nd entry or. ;AC000;
	   JE $$LL131

	   cmp	BYTE PTR [si],deleted	; deleted ?			    :

;	   $if	e			; if deleted (0E5h)...................:;AC000;
	   JNE $$IF131
$$LL131:

	       clc			; reset fail flag

;	   $else			;				       ;AC000;
	   JMP SHORT $$EN131
$$IF131:

					; This entry is not free.
	       mov  di,OFFSET FCBDOS	;   see if it is IBMDOS
	       mov  cx,file_spec_length ; length of name
	       rep  cmpsb		; compare it
	       mov  si,bp		; restore pointer to start	       ;AC000;

;	       $if  e			; if second file is IBMDOS.COM.        ;AC000;
	       JNE $$IF133

		   dec	DOSEntFree	; indicate we found IBMDOS
		   mov	ax,word ptr ds:[si].dir_size_l ; Get the size of       ;AC000;
		   mov	word ptr IBMDOS_Low,ax ;	   file for IBMDOS
		   mov	ax,word ptr ds:[si].dir_size_h ;		       ;AC000;
		   mov	word ptr IBMDOS_High,ax
		   clc			; reset fail flag		       ;AN000;

;	       $else			; error condition		       ;AC000;
	       JMP SHORT $$EN133
$$IF133:

		   call Move_DIR_Entry	;				       ;AN003;

;	       $endif			;				       ;AC000;
$$EN133:

;	   $endif			;				       ;AC000;
$$EN131:

;      $else				;				       ;AC000;
       JMP SHORT $$EN130
$$IF130:
	   mov	ax,(util_B shl 8) + no_room ; load return code in case we fail ;AN000;
;      $endif				;				       ;AC000;
$$EN130:

;  $endif				;				       ;AC000;
$$IF129:

   ret					;				       ;AN000;

   ENDPROC Verify_File_Location

   BREAK <SYS - Determine_Free_Space >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Determine_Free_Space
;*******************************************************************************
;
;Last Update: 3/18/87
;
;Description: Determine if there is enough space on the disk, given the free
;	      space and the space taken up by IBMBIO and IBMDOS to install the
;	      new IBMBIO and IBMDOS. Routine will set fail flag and load return
;	      code if there is not enough room.
;
;	      Here we make some VERY IMPORTANT assumptions.
;
;	      1) If IBMBIO exists on the disk currently, we assume it is in the
;		 correct place, i.e. at the front of the data area & contiguous.
;	      2) The stub loader portion of IBMBIO is less than 2048 bytes long.
;		 This number comes about by assuming we will never overlay
;		 anything smaller than 1920 bytes (DOS 1.10 IBMBIO size). This
;		 can be expanded to 2048 if we also assume the smallest possible
;		 cluster length is 512 bytes.
;
;	      Therefore, if we have an empty disk or IBMBIO exists, then we have
;	      enough contiguous room to install the portion of IBMBIO that
;	      requires itself to be contiguous.
;
;CALLed Procedures: None
;
;Input: 	    None
;
;Output: no error - CF = 0
;	    error - CF = 1
;		    AX = return code
;			  AH = utility messages
;			  AL = 8d - No room for system on destination disk
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Determine_Free_Space
;
;	get disk free space (INT21 Get_Drive_Freespace + 00 <3600>)
;	compute Bytes/Cluster (32bit math required)
;	convert current IBMBIO into cluster size (CALL Get_Cluster)
;	convert current IBMDOS into cluster size (CALL Get_Cluster)
;	get total number of clusters available
;	convert new IBMBIO into cluster size (CALL Get_Cluster)
;	convert new IBMDOS into cluster size (CALL Get_Cluster)
;	get total number of clusters needed
;	if available clusters < needed clusters
;		load return code (No room for system on destination disk)
;		set fail flag
;	else
;		reset fail flag
;	endif
;	ret
;
;	END  Determine_Free_Space
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Determine_Free_Space

   Determine_Free_Space PROC NEAR

   mov	ah,Get_Drive_Freespace		; get disk free space
   mov	dl,TargDrvNum			; get the drive number
   INT	21h				; Get_Drive_Freespace  <36xx>
					; compute Bytes/Cluster - 16 bit math ok
					;   AX = sectors / cluster
					;   CX = bytes / sector
					;   BX = available clusters
   mul	cx				; get bytes/cluster
					; result left in AX
   mov	Bytes_Per_Cluster,ax		; save this value for Get_Clusters
   mov	Number_Free_Clusters,bx 	; save available space

   mov	ax,IBMBIO_Low			; low result in AX, High result in DX
   mov	dx,IBMBIO_High
   call Get_Cluster			; convert old IBMBIO into cluster size

   add	Number_Free_Clusters,ax 	; add it to available space

   mov	ax,IBMDOS_Low			; low result in AX, High result in DX
   mov	dx,IBMDOS_High
   call Get_Cluster			; convert old IBMDOS into cluster size

   add	Number_Free_Clusters,AX 	; get total number of clusters available

   mov	ax,NEWBIO_Size_Low		; find total size of new DOS and BIOS
   mov	dx,NEWBIO_Size_High

   call Get_Cluster			; convert new IBMBIO into cluster size

   mov	Need_Clusters,ax		;save new BIO clusters

   mov	ax,NEWDOS_Size_Low
   mov	dx,NEWDOS_Size_High

   call Get_Cluster			; convert new IBMDOS into cluster size

   add	AX,Need_Clusters		; get total number of clusters needed

   cmp	AX,Number_Free_Clusters 	;Now see if there is enough room
					;	for all of it on the disk
;  $if	a				; if needed > available clusters       ;AC000;
   JNA $$IF140

       mov  ax,(util_B shl 8) + no_room ; load return code		       ;AC000;
					; - No room for system on dest..
       stc				; set fail flag

;  $else				;				       ;AC000;
   JMP SHORT $$EN140
$$IF140:

       clc				; reset fail flag

;  $endif				;				       ;AC000;
$$EN140:

   ret					;				       ;AN000;

   ENDPROC Determine_Free_Space

   BREAK <SYS - Get_Cluster >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Get_Cluster
;*******************************************************************************
;
;Description:	    Convert bytes to clusters, rounding up to the next
;		    cluster size if needed.
;
;Called Procedures: None
;
;Input: 	    (AX) = Number of bytes
;		    Bytes_Per_Cluster = # of bytes per cluster
;
;Output:	    (AX) = Number of clusters
;
;Registers used:    AX	BX  DX
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Get_Cluster
;
;	divide size by bytes_per_cluster
;	if there is a remainder
;		round up to next cluster
;	endif
;	ret
;
;	END Get_Cluster
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Get_Cluster

   Get_Cluster PROC NEAR

   mov	bx,Bytes_Per_Cluster		; Bytes/cluster
   div	bx				; divide size by bytes_per_cluster
   cmp	dx,0				; is there a remainder in DX?

;  $if	ne				; if there is a remainder	       ;AC000;
   JE $$IF143
					; we have another cluster to round up
       inc  ax				; round up to next cluster

;  $endif				;				       ;AC000;
$$IF143:

   ret

   ENDPROC Get_Cluster

   BREAK <SYS - Do_SYS >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Do_SYS
;*******************************************************************************
;
;Description: Control routine to handle the transfer of system files from
;	      memory to target drive.
;
;Called Procedures: Create_System
;		    Fill_Memory
;		    Dump_Memory
;
;Input: IBMBIO_Size_Loaded
;	IBMDOS_Size_Loaded
;
;Output: no error - CF = 0
;	    error - CF = 1	  AX = return code (message #)
;
;Change History: Created	5/01/87 	FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Do_SYS
;
;	create new IBMBIO and IBMDOS, in place if exist (CALL CREATE_SYSTEM)
;	if no error
;		search
;			write out contents of memory to file (CALL Dump_Memory)
;			load error return code (assume error)
;		leave if error
;		exit if if all files copied
;			reset fail flag
;		orelse
;			read in file from source (CALL Fill_Memory)
;			load error return code (assume error)
;		leave if error
;		endloop
;			set fail flag
;		endsearch
;	endif
;	ret
;
;	END  Do_SYS
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Do_SYS

   Do_SYS PROC NEAR

   call CREATE_SYSTEM			; create IBMBIO and IBMDOS, in place   ;AN000;

;  $if	nc				; no error			       ;AC000;
   JC $$IF145

       push ds
       lds  bx,THIS_DPB 		; set up pointer to DPB 	       ;AC000;
       mov  [bx.dpb_next_free],2	; reset Allocation to start of disk    ;AC000;
       pop  ds				;  so BIOS goes in right place!

;      $search				;				       ;AC000;
$$DO146:

	   call Dump_Memory		; write out contents of memory to file

	   mov	ax,(util_B shl 8) + no_room ; load error RC (assume error)     ;AC000;

;      $leave c 			; quit if error 		       ;AC000;
       JC $$EN146

	   mov	ax,DOSLenHigh		; more DOS to move ?
	   or	AX,DOSLenLow		; more low dos
	   or	AX,BIOSLenHigh		; more high BIOS
	   or	AX,BIOSLenLow		; more low BIOS

;      $exitif z			; if all files copied		       ;AC000;
       JNZ $$IF146

	   clc				;	 reset fail flag	       ;AC000;

;      $orelse				;				       ;AC000;
       JMP SHORT $$SR146
$$IF146:

	   call get_rest_of_system

	   mov	ax,(util_B shl 8) + no_room ; load error RC (assume error)     ;AC000;

;      $leave c 			; if error			       ;AC000;
       JC $$EN146

;      $endloop 			;				       ;AC000;
       JMP SHORT $$DO146
$$EN146:

;      $endsrch 			;				       ;AC000;
$$SR146:

;  $endif				;				       ;AC000;
$$IF145:

   ret					;				       ;AN000;

   ENDPROC Do_SYS

   PUBLIC Get_Rest_of_System

   Get_Rest_of_System Proc near

   pushf				;				       ;AN001;

   mov	bx,BIOSOutFH			;				       ;AN001;
   mov	ah,Close			;				       ;AN001;
   int	21h				;				       ;AN001;

   mov	bx,DOSOutFH			;				       ;AN001;
   mov	ah,Close			;				       ;AN001;
   int	21h				;				       ;AN001;

   mov	dx,offset SourceBIOSName	;				       ;AN001;
   mov	ax,(OPEN SHL 8) + not_used	; open file for read
   int	21h				;				       ;AN001;
   mov	biosinfh,ax

   mov	dx,offset SourceDOSName 	;				       ;AN001;
   mov	ax,(OPEN SHL 8) + not_used	; open file for read
   int	21h				;				       ;AN001;
   mov	dosinfh,ax

   call Fill_Memory			; read in file from source

   mov	bx,BIOSInFH			;				       ;AN001;
   mov	ah,Close			;				       ;AN001;
   int	21h				;				       ;AN001;

   mov	bx,DOSInFH			;				       ;AN001;
   mov	ah,Close			;				       ;AN001;
   int	21h				;				       ;AN001;

   mov	dx,offset BIOSName		;				       ;AN001;
   mov	ax,(Open shl 8) + 2		; Open file
   INT	21h
   mov	BIOSOutFH,ax

   mov	dx,offset DOSName		;				       ;AN001;
   mov	ax,(Open shl 8) + 2		; Open file
   INT	21h
   mov	DOSOutfh,ax

   popf 				;				       ;AN001;

   RET

   endproc get_rest_of_system

   BREAK <SYS - Create_System >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Create_System
;*******************************************************************************
;
;Description:
;
;Called Procedures: Create_File
;
;Input: 	    None
;
;Output:	    IBMBIO_Handle
;		    IBMDOS_Handle
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Create_System
;
;	create IBMBIO (CALL Create_File)
;	if no error and
;		save handle to IBMBIO_Handle
;		create IBMDOS (CALL Create_File)
;	if no error
;		save handle to IBMDOS_Handle
;		reset fail flag
;	endif
;	ret
;
;	END  Create_System
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Create_System

   Create_System PROC NEAR

   mov	[open_seg],ds
   mov	dx,OFFSET BIOSName		; point to IBMBIO ASCIIZ string
   mov	al,[BIOSEntFree]		; get status of IBMBIO		       ;AN006;
   mov	[EntryFree],al			; update file status (0 = found,1 = not;AN006;

   call Create_File			; create IBMBIO 		       ;AN000;

;  $if	nc,and				; no error and			       ;AC000;
   JC $$IF154

   mov	BIOSOutFH,ax			; save handle to IBMBIO_Handle
   mov	dx,OFFSET DOSName		; pointer to IBMDOS ASCIIZ string
   mov	al,[DOSEntFree] 		; get status of IBMDOS		       ;AN006;
   mov	[EntryFree],al			; update file status (0 = found,1 = not;AN006;

   call Create_File			; create IBMDOS 		       ;AN000;

;  $if	nc				; no error			       ;AC000;
   JC $$IF154

       mov  DOSOutFH,ax 		; save handle to IBMDOS_Handle

;  $endif				;				       ;AC000;
$$IF154:

   ret					;				       ;AN000;

   ENDPROC Create_System

   BREAK <SYS - Create_File >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Create_File
;*******************************************************************************
;
;Last Update: 9/23/87
;
;Description: Remove the read only attribute from IBMBIO and IBMDOS. If
;	      file not found error occurs, it is okay, because it just
;	      means the file was not there. Do create with read-only
;	      hidden, and system file attributes. This is an in place
;	      create if the file exists already.
;
;
;Called Procedures: None
;
;Input: 	    DS:DX = pointer to ASCIIZ string for file create
;
;Output: no error - CF = 0
;		    AX = file handle
;	    error - CF = 1
;		    AX = return code
;			  AH = extended DOS errors
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Create_File
;
;	set file attributes to 0 (INT21 CHMod + SetAtrib <4301>)
;	if no error or
;	if error = file not found and
;		ext Open file with attributes of 7 (INT21 ExtOpen + SetAtrib  <6C12> CX=7)
;	if no error
;		reset fail flag
;	else
;		load return code (DOS Extended Error)
;		set fail flag
;	endif
;	ret
;
;	END  Create_File
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Create_File

   Create_File PROC NEAR

   mov	ax,(CHMod shl 8) + SetAtrib	; set file attributes to 0
   xor	cx,cx				; set attributes to 0
   mov	[open_off],dx			; save pointer to ASCIIZ for OPEN
   INT	21h				;   CHMod + SetAtrib <4301>)

;  $if	nc				; no error			       ;AC000;
   JC $$IF156

       cmp  [EntryFree],0		; is file in the correct spot?	       ;AN006;
;      $if  ne				; if it is not - we have a problem     ;AN006;
       JE $$IF157
	   mov	dx,[open_off]		; get pointer to ASCIIZ for UNLINK     ;AN006;
	   mov	ax,(UNLINK shl 8)	; UNLINK the file
	   INT	21h			;   UNLINK	     <4100>)	       ;AN006;
;      $endif				;				       ;AN006;
$$IF157:
;  $else				; - check the error		       ;AN006;
   JMP SHORT $$EN156
$$IF156:
       call Get_DOS_Error		; find out what went wrong	       ;AN000;
       cmp  al,file_not_found		; not there?

;      $if  e				;   IBMBIO was not there	       ;AC000;
       JNE $$IF160
	   clc				;      ok to open		       ;AC000;
;      $else				;				       ;AC000;
       JMP SHORT $$EN160
$$IF160:
	   stc				;      some other error - quit	       ;AC000;
;      $endif				;				       ;AC000;
$$EN160:
;  $endif				;				       ;AC000;
$$EN156:
;  $if	nc				; if no error			       ;AC006;
   JC $$IF164

       lds  si,OPEN_PARMS		;				       ;AC005;
       xor  cx,cx			; DOS system file atributes	       ;AC005;
       cmp  DOS_VER,0			; running on current DOS ?	       ;AN019;

;      $if  ne				; if on old DOS 		       ;AN019;
       JE $$IF165
	   mov	dx,si			; DS:DX - file name		       ;AN019;
	   mov	ax,(Creat shl 8) + 0	; Create file  <3D00>		       ;AN019;
;      $else				;				       ;AN019;
       JMP SHORT $$EN165
$$IF165:
	   mov	di,cx			;				       ;AC005;
	   dec	di			;				       ;AC005;
	   mov	bx,open_mode		; set up for mode		       ;AN000;
	   mov	dx,(openit shl 4) + replaceit ; create if does not exist,      ;AN000;
					;     replace it if it does
	   mov	ax,(ExtOpen shl 8) + 0	; ext Open file with attributes of 0   ;AN000;
					; ExtOpen + SetAtrib  <6C12> CX=0
;      $endif				;				       ;AN019;
$$EN165:

       INT  21h 			; do the open

;  $endif				;				       ;AC000;
$$IF164:

;  $if	c				; if error			       ;AN000;
   JNC $$IF169

       call Get_DOS_Error		; find out what went wrong	       ;AN000;
       mov  ah,DOS_error		; load return code (DOS Extended Error);AN000;
       stc				;				       ;AN006;

;  $endif				;				       ;AN000;
$$IF169:

   ret					;				       ;AC000;

   ENDPROC Create_File

   BREAK <SYS - Dump_Memory >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Dump_Memory
;*******************************************************************************
;
;Description:	    Write out as much of IBMBIOS and IBMDOS as is in memory.
;
;Called Procedures: None
;
;Input: 	    None
;
;Output: no error - CF = 0
;	    error - CF = 1
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Dump_Memory
;
;	get pointer to start of buffer
;	subtract the start of IBMDOS
;	if lenght is non-zero and . . . . . . . . . . . . . . . .
;		load IBMBIOS handle				:
;		write out IBMBIOS (INT21 Write + 00 <4000>)	:
;	if no error and . . . . . . . . . . . . . . . . . . . . :
;	if not all data written . . . . . . . . . . . . . . . . :
;		set fail flag
;	endif
;	if no error so far
;		get beginning of dos
;		subtract end of dos
;		if lenght is non-zero and
;			load IBMDOS handle
;			write out IBMDOS (INT21 Write + 00 <4000>)
;		if no error and
;		if not all data written . . . . . . . . . . . . . . . . :
;			set fail flag
;		endif
;	endif
;	ret
;
;	END  Dump_Memory
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Dump_Memory

   Dump_Memory PROC NEAR

   mov	ax,4202h			; LSEEK to end of file		       ;AN001;
   mov	bx,BIOSOutFH			;				       ;AN001;
   xor	cx,cx				;				       ;AN001;
   xor	dx,dx				;				       ;AN001;
   int	21h				;				       ;AN001;
   mov	ax,4202h			; LSEEK to end of file		       ;AN001;
   mov	bx,DOSOutFH			;				       ;AN001;
   xor	cx,cx				;				       ;AN001;
   xor	dx,dx				;				       ;AN001;
   int	21h				;				       ;AN001;

   mov	dx,OFFSET BUF+FAT_BUF		; get pointer to start of buffer
   mov	cx,pDOS 			; beginning of next guy
   sub	cx,dx				; difference is length

;  $if	nz,and				; if lenght is non-zero and.......     ;AC000;
   JZ $$IF171

   mov	bx,BIOSOutFH			; load IBMBIOS handle		  :
   mov	ah,Write			; write out IBMBIOS		  :
   INT	21h				; Write + 00 <4000>		  :

;  $if	nc,and				; if no error and.................:    ;AC000;
   JC $$IF171

   cmp	ax,cx				; Did it work?			  :

;  $if	ne				; all data written................:    ;AC000;
   JE $$IF171

       stc				; set fail flag

;  $endif				;				       ;AC000;
$$IF171:

;  $if	nc				; if no error so far		       ;AC000;
   JC $$IF173

       mov  dx,pDOS			; get beginning of dos
       mov  cx,pDOSEnd			; subtract end of dos
       sub  cx,dx			; difference is length

;      $if  nz,and			; if lenght is non-zero and........    ;AC000;
       JZ $$IF174

       mov  bx,DOSOutFH 		; load IBMDOS handle		  :
       mov  ah,Write			; write out IBMDOS		  :
       INT  21h 			; Write + 00 <4000>		  :

;      $if  nc,and			; if no error.....................:    ;AC000;
       JC $$IF174

       cmp  ax,cx			; Did it work?			  :

;      $if  ne				; all data written................:    ;AC000;
       JE $$IF174

	   stc				; set fail flag

;      $endif				;				       ;AC000;
$$IF174:

;  $endif				;				       ;AC000;
$$IF173:

   ret

   ENDPROC Dump_Memory


   BREAK <SYS - Do_End >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Do_End
;*******************************************************************************
;
;Description:	    Finish off with IBMBIOS and IBMDOS
;
;Called Procedures: Close_File
;		    Write_Boot_Record
;
;Input: 	    None
;
;Output: no error - CF = 0
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Do_End
;
;	finish off and close IBMBIOS and IBMDOS (CALL Close_Files)
;	update boot record (CALL Write_Boot_Record)
;	ret
;
;	END  Do_End
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Do_End

   Do_End PROC NEAR

   call Close_File			; finish off & close IBMBIOS and IBMDOS;AN000;

   call Write_Boot_Record		; update boot record		       ;AN000;

   ret					;				       ;AN000;

   ENDPROC Do_End

   BREAK <SYS - Close_File >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Close_File
;*******************************************************************************
;
;Description:	    Set date and time on IBMBIOS and IBMDOS and close
;		    them.
;
;Called Procedures: None
;
;Input: 	    BIOSTime, BIOSOutFH, DOSTime. DOSOutFH
;
;Output:	    IBMBIOS and IBMDOS closed
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Close_File
;
;	load IBMBIOS time and date
;	load IBMBIOS handle
;	update file times (INT21 File_Times + 01 <5701>)
;	close file (INT21 Close + 00 <3E00>)
;	load IBMDOS time and date
;	load IBMDOS handle
;	update file times (INT21 File_Times + 01 <5701>)
;	close file (INT21 Close + 00 <3E00>)
;	ret
;
;	END  Close_File
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Close_File

   Close_File PROC NEAR

   mov	cx,BIOSTime			; load IBMBIOS time and date
   mov	dx,BIOSTime+2
   mov	bx,BIOSOutFH			; load IBMBIOS handle
   mov	ax,(File_Times SHL 8) + set	; update file times
   INT	21h				; File_Times + 01 <5701>
   mov	ah,Close			; close file IBMBIO
   INT	21h				; Close + not_used <3Exx>
   mov	cx,DOSTime			; load IBMDOS time and date
   mov	dx,DOSTime+2
   mov	bx,DOSOutFH			; load IBMDOS handle
   mov	ax,(File_Times SHL 8) + set	; update file times
   INT	21h				; File_Times + 01 <5701>
   mov	ah,Close			; close file IBMDOS
   INT	21h				; Close + not_used <3Exx>

   mov	dx,offset BIOSName		;				       ;AN001;
   mov	ax,(CHMod shl 8) + SetAtrib	; set file attributes to 0
   mov	cx,DOS_system_atrib		; DOS system file atributes
   INT	21h				;   CHMod + SetAtrib <4301>)

   mov	dx,offset DOSName		;				       ;AN001;
   mov	ax,(CHMod shl 8) + SetAtrib	; set file attributes to 0
   mov	cx,DOS_system_atrib		; DOS system file atributes
   INT	21h				;   CHMod + SetAtrib <4301>)

   ret					;				       ;AN000;

   ENDPROC Close_File

   BREAK <SYS - Write_Boot_Record >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Write_Boot_Record
;*******************************************************************************
;
;Description:	    Get a best guess EBPB and get the Media ID or fill the
;		    information in manually. Write out the canned boot record
;		    and then make IOCtl calls to set the EBPB and Media ID.
;
;Called Procedures: Create_Serial_ID
;
;Input: 	    None
;
;Output:	    Boot record on destination media is installed.
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Write_Boot_Record
;
;	get BPB using IOCtl Get Device Parameters (INT21 IOCtl + 0Dh <440d> CX=0860)
;	get volid, ser# and file type using IOCtl Get Media ID (INT21 IOCtl + 0Dh <440d> CX=086E)
;	if error and
;	get Extended error
;	if 'unknown media' - set fields manually
;		compute serial id and put in field (CALL Create_Serial_ID)
;		copy in volume label if available
;		set pointer to FAT1x (CALL FAT_Size)
;		move file system string into Boot_System_ID field
;	else
;		set fail flag
;		load return code (DOS error)
;	endif
;	if no fail flag
;		if fixed media
;			fill in Ext_PhyDrv in canned boot record
;		endif
;		set BPB using data from GET BPB IOCTL
;		write out canned boot record (INT26)
;		set volid, ser# and file type using Set Media ID (INT21 SetID <6900> CX=084E)
;	endif
;	ret
;
;	END  Write_Boot_Record
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Write_Boot_Record

   Write_Boot_Record PROC NEAR

   mov	bl,TargDrvNum			; Drive number			       ;AN000;
   mov	dx,offset DeviceParameters	;				       ;AN000;
   mov	cx,(rawio shl 8) + get_device_parameters ; Generic IOCtl Request       ;AN000;
					;     CX=0860
   mov	ax,(IOCtl shl 8) + generic_ioctl ; get BPB using Set Device Parm       ;AN000;
   INT	21h				; IOCtl + gen_IOCtl_request <440d>     ;AN000;

   cmp	DOS_VER,0ffh			; is it DOS 3.3?		       ;AN019;
;  $if	ne				; only do a GET if DOS 4.00		;AN019;
   JE $$IF177
       lea  dx,IOCtl_Buf		; point to output buffer	       ;AN000;
       mov  ax,(GetSetMediaID shl 8) + 0 ; get volid, ser# and file type       ;AC008;
       INT  21h 			; GetSetMediaID + 0  INT 21 <6900>     ;AC008;

;      $if  c				; error - see if its 'unknown media'   ;AN000;
       JNC $$IF178

	   call Get_DOS_Error		; get error			       ;AN000;
	   cmp	al,old_type_media	;				       ;AN000;

;	   $if	e			;				       ;AN019;
	   JNE $$IF179
	       stc			; do it all manually		       ;AN019;
;	   $else			;				       ;AN019;
	   JMP SHORT $$EN179
$$IF179:
	       clc			; some other dos error occured - le    ;AN019;
;	   $endif			;	       it go by 	       ;AN019;
$$EN179:

;      $endif				;				       ;AN019;
$$IF178:
;  $else				;				       ;AN019;
   JMP SHORT $$EN177
$$IF177:
       stc				; do it all manually		       ;AN019;
;  $endif				;				       ;AN019;
$$EN177:

;  $if	c				; if it is pre 4.00 IBM format	       ;AN000;
   JNC $$IF185

       call Create_Serial_ID		; compute serial id and put in field   ;AN000;

					; find first with type = VOLUME ID

       mov  dx,OFFSET ExtFCB		; set up for FCB call		       ;AN019;
       mov  ah,Dir_Search_First 	; do a find first INT21 	       ;AN019;

       INT  21h 			;      Find_First <11xx>	       ;AN000;

       cmp  al,0			; was a match found?  al = 0 yes       ;AN019;
					;		      al = ff no
;      $if  e				; if so - copy it in		       ;AN000;
       JNE $$IF186

	   lea	si,DOS_BUFFER + 8	; source id is in DTA		       ;AN019;
	   lea	di,IOCtl_Vol_ID 	; destination is in IOCtl_Buf	       ;AN000;
	   mov	cx,file_spec_length	; move 11 bytes worth		       ;AN000;
	   cld				; copy it in			       ;AN000;
	   rep	movsb			;				       ;AN000;

;      $else
       JMP SHORT $$EN186
$$IF186:

	   clc				; leave it as default - NO NAME

;      $endif				; endif 			       ;AN000;
$$EN186:

					; NOTE:
					; since the GET MEDIA ID failed - its
					; pre 32 bit fat  - so no 32 bit math
					; is required.
       call FAT_Size			; set pointer to FAT1x		       ;AN000;

       mov  cx,FAT_len			; move file system string into	       ;AN000;
					;     Boot_System_ID field
       lea  di,IOCTL_File_Sys		; update buffer 		       ;AN000;
       cld				;				       ;AN000;
       rep  movsb			;				       ;AN000;
;  $endif
$$IF185:

;  $if	nc				;				       ;AN000;
   JC $$IF190

       lea  si,DeviceParameters.DP_BPB
       lea  di,boot.EXT_BOOT_BPB
       mov  cx,type EXT_BPB_INFO
       cld
       rep  movsb

       cmp  DeviceParameters.DP_BPB.BPB_MediaDescriptor,hard_drive ; is it Hard drive?;AC000;

;      $if  e				; if its a hard drive		       ;AC000;
       JNE $$IF191

					; NOTE: The physical hard drive number
					;	is placed in the third byte from
					;	the end in the boot sector in
					;	DOS 3.2. This is a change from
					;	the previous DOS versions.

					; fill in PhyDrv in canned boot record
	   mov	al,80h			; (set physical hard drive number)     ;AC016;
;      $else
       JMP SHORT $$EN191
$$IF191:
	   xor	al,al			; (set physical drive number to zero)  ;AC016;
;      $endif				;				       ;AC000;
$$EN191:

       mov  BOOT.EXT_PHYDRV,al		; (set physical hard drive number)     ;AC016;

       cmp  DOS_VER,0			;				       ;AN019;
;      $if  ne				; copy IOCTL stuff into boot record    ;AN019;
       JE $$IF194
					;     (no set ID available for 3.3)
	   lea	si,IOCtl_Ser_No_Low	; point to source buffer (IOCTL)       ;AN000;
	   lea	di,BOOT.EXT_BOOT_SERIAL ; point to target buffer (BOOT record) ;AN000;

	   mov	cx,IOCTL_Ser_Vol_SyS	; move serial # , Volid , System       ;AN019;
	   cld				;				       ;AN019;
	   rep	movsb			;				       ;AN019;
;      $endif				;				       ;AN019;
$$IF194:

       xor  cx,cx			; Sector 0			       ;AN019;
       mov  [packet],cx 		; set starting sector as 0	       ;AN019;
       mov  bx,offset BOOT		;				       ;AN019;
       mov  packet_buffer[0],bx 	;				       ;AN019;
       mov  word ptr [packet_sectors],1 ;				       ;AN019;
       mov  ah,1			; request a write		       ;AN019;
       call Direct_Access		;				       ;AN019;

;      $if  c				;				       ;AC000;
       JNC $$IF196
;      $endif				;				       ;AC000;
$$IF196:

       cmp  DOS_VER,0			;				       ;AN019
;      $if  e				; only do a SET if DOS 4.00
       JNE $$IF198
	   mov	bl,TargDrvNum		; Drive number			       ;AN000;
	   lea	dx,IOCtl_Buf		; point to output buffer	       ;AN000;
	   mov	ax,(GetSetMediaID shl 8) + 1 ; set volid, ser# and filetype    ;AC008;
	   INT	21h			; GetSetMediaID + 1  INT 21 <6901>     ;AC008;
;      $endif				;AN019;
$$IF198:

;  $endif				;				       ;AC000;
$$IF190:

   ret

   ENDPROC Write_Boot_Record

   BREAK <SYS - FAT_Size >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: FAT_Size
;*******************************************************************************
;
;Description:	    Determine FAT Type (12 or 16)
;
;		    NOTE: This routine is only called if the IOCtl call for
;			  Get Media Type FAILS with an extended error of
;			  'Unknown media type'.  This indicates it is a
;			  pre DOS 4.00 media (ie: it MUST be a 12 or old style
;			  16 bit FAT
;
;			  This is the same algorithm used by FORMAT
;
; Algorithm:
;
; UsedSectors = number of reserved sectors
;	 + number of FAT Sectors	( Number of FATS * Sectors Per FAT )
;	 + number of directory sectors	( 32* Root Entries / bytes Per Sector )
;
; t_clusters = ( (Total Sectors - Used Sector) / Sectors Per Cluster)
;
;   if T_Clusters <= 4086 then it a FAT12 - else - its a FAT16
;
;Called Procedures: None
;
;Input: 	    EBPB of Target media in memory
;
;Output:	    SI: points to  "FAT12    "
;			       or  "FAT16     "
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  FAT_Size
;
;	Calculate the number of directory sectors
;	Calculate and add the number of FAT sectors
;	Add in the number of boot sectors
;	subtract used sectors from total sectors
;	if <= FAT THRESHOLD then
;		set pointer to FAT12
;	else
;		set pointer to FAT12
;	endif
;
;	ret
;
;	END  FAT_Size
;
;******************-  END  OF PSEUDOCODE -**************************************

   public FAT_Size

   FAT_Size PROC NEAR

					;--------------------------
					; Calculate UsedSectors
					;---------------------------

					; Calculate the number of directory sectors

   mov	ax, deviceParameters.DP_BPB.BPB_RootEntries ;			       ;AN000;
   mov	bx, TYPE dir_entry		;				       ;AN000;
   mul	bx				;				       ;AN000;
   add	ax, deviceParameters.DP_BPB.BPB_BytesPerSector ;		       ;AN000;
   dec	ax				;				       ;AN000;
   xor	dx,dx				;				       ;AN000;
   div	deviceParameters.DP_BPB.BPB_BytesPerSector ;			       ;AN000;
   mov	cx,ax				;				       ;AN000;

					; Calculate the number of FAT sectors

   mov	ax, deviceParameters.DP_BPB.BPB_SectorsPerFAT ; 		       ;AN000;
   mul	deviceParameters.DP_BPB.BPB_NumberOfFATs ;			       ;AN000;

					; Add in the number of boot sectors

   add	ax, deviceParameters.DP_BPB.BPB_ReservedSectors ;		       ;AN000;
   add	cx,ax				;				       ;AN000;

					;--------------------------
					; Calculate t_clusters
					;--------------------------

   mov	ax, deviceParameters.DP_BPB.BPB_TotalSectors ;			       ;AN000;

   sub	ax,cx				;Get sectors in data area	       ;AN000;
   xor	dx,dx				;				       ;AN000;
   xor	bx,bx				;				       ;AN000;
   mov	bl,deviceParameters.DP_BPB.BPB_SectorsPerCluster ;		       ;AN000;
   div	bx				;Get total clusters		       ;AN000;
   cmp	ax,BIG_FAT_THRESHOLD		;Is clusters < 4086?		       ;AN000;

;  $if	be				; if less then its a FAT12	       ;AN000;
   JNBE $$IF201
       lea  si,FAT_12			;				       ;AN000;
;  $else				;				       ;AN000;
   JMP SHORT $$EN201
$$IF201:
       lea  si,FAT_16			;				       ;AN000;
;  $endif				;				       ;AN000;
$$EN201:

   clc					; leave cleanly

   return				;				       ;AN000;

   ENDPROC FAT_Size

   BREAK <SYS - Create_Serial_ID >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Create_Serial_ID
;*******************************************************************************
;
;Description:	    Create unique 32 bit serial number by getting current date
;		    and time and then scrambling it around
;
;Called Procedures: None
;
;Input: 	    None
;
;Output:	    serial number installed in Boot_Serial
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Create_Serial_ID
;
;	Get date (INT21 Get_Date + 00 <2A00>)
;	Get time (INT21 Get_Time + 00 <2C00>)
;	Boot_Serial+0 = DX reg date + DX reg date
;	Boot_Serial+2 = CX reg time + CX reg time
;	ret
;
;	END  Create_Serial_ID
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Create_Serial_ID

   Create_Serial_ID PROC NEAR

   mov	ax,(Get_Date shl 8) + not_used	; Get date			       ;AN000;
   INT	21h				; Get_Date + not_used <2A00>	       ;AN000;
   mov	ax,(Get_Time shl 8) + not_used	; Get time			       ;AN000;
   INT	21h				; Get_Time + not_used <2C00>	       ;AN000;
   add	dx,dx				; Boot_Serial+0 = DX (date) + DX (date);AN000;
   add	cx,cx				; Boot_Serial+2 = CX (time) + CX (time);AN000;
   mov	IOCtl_Ser_No_Low,dx		; SERIAL # - low		       ;AN000;
   mov	IOCtl_Ser_No_Hi,cx		; SERIAL # - hi 		       ;AN000;

   ret					;				       ;AN000;

   ENDPROC Create_Serial_ID

   BREAK <SYS - Message >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Message
;*******************************************************************************
;
;Description:  Display a message
;
;Called Procedures: SYSDISPMSG, Get_DOS_Error
;
;Input: 	    (AL) message number
;		    (AH) message class
;			  = C - DS:SI points to sublist
;
;Output: no error   AX = 0
;	    error - AX = error exit code
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Message
;
;	if DOS error
;		call Get_DOS_error
;	endif
;	move message class into place
;	reset insert  (CX)
;	reset response	(DL)
;	set output handle (BX)
;	if CLASS requires insert
;		load insert required
;	if CLASS requires response
;		flush keystroke buffer
;		load response required (Dir CON in no echo)
;	endif
;	call SysDispMsg to display message
;	if error or
;		call Get_DOS_error
;		call SysDispMsg to try again
;	if not success message
;		load error exit code
;	else
;		load success exit code
;	endif
;	ret
;
;	END  Message
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Message

   Message PROC NEAR

   xor	dx,dx				; reset response  (DL)		       ;AN000;
   xor	cx,cx				; reset insert	(CX)		       ;AC024;
   dec	dh				; assume CLASS is Utility	       ;AN000;

   cmp	ah,PARSE_Error			;				       ;AN000;

;  $if	be,and				; if DOS or PARSE error 	       ;AN000;
   JNBE $$IF204

   mov	dh,ah				;				       ;AN000;

;  $if	e,and				; if PARSE error		       ;AN024;
   JNE $$IF204
   cmp	al,reqd_missing 		;				       ;AC024;
;  $if	ne				; and if theres something there        ;AC024;
   JE $$IF204

       push cs				; set up for insert		       ;AN024;
       pop  [insert_ptr_seg]		;   (offset set by parse routine)      ;AN024;
       mov  cs:[si],dl			; make it an ASCIIZ string	       ;AN024;
       mov  insert_number,dl		; zero out for %0
       mov  insert_max,030h		; set length to something reasonable   ;AN024;
       inc  cx				; there's an insert                    ;AC024;
       lea  si,SUBLIST			; point to the sublist		       ;AC024;

;  $endif				;				       ;AN024;
$$IF204:


   cmp	ah,DOS_Error			;				       ;AN000;

;  $if	be				; if DOS error			       ;AC019;
   JNBE $$IF206

       call Get_DOS_error		; to find out what message to display  ;AN000;
       mov  dh,DOS_Error		; ensure message type is DOS_Error     ;AN019;

;  $endif				;				       ;AN000;
$$IF206:

   mov	bx,STDERR			; set output handle (BX)	       ;AN000;

   cmp	ah,util_C			; is it CLASS C 		       ;AN000;

;  $if	e				; CLASS C requires insert	       ;AN000;
   JNE $$IF208

       inc  cx				; load insert required		       ;AN000;

;  $endif				;				       ;AN000;
$$IF208:

   cmp	ah,util_D			; is it CLASS D 		       ;AN000;

;  $if	e				; CLASS D requires response	       ;AN000;
   JNE $$IF210

       mov  dl,DOS_CON_INP		; load response required  - con: input ;AN000;

;  $endif				;				       ;AN000;
$$IF210:

   xor	ah,ah				;				       ;AN000;


   call SysDispMsg			; to display message		       ;AN000;

;  $if	c,and				; error and...............	       ;AN000;
   JNC $$IF212

   call SysDispMsg			; to try again		 :	       ;AN000;

;  $if	c				; if reaaly bad .........:	       ;AN000;
   JNC $$IF212

       mov  ax,return_error		; load error exit code		       ;AN000;

;  $else				;				       ;AN000;
   JMP SHORT $$EN212
$$IF212:

       mov  ax,success			; load success exit code	       ;AN000;

;  $endif				;				       ;AN000;
$$EN212:

   ret					;				       ;AN000;

   ENDPROC Message


   BREAK <SYS - Get_DOS_Error >
;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Get_DOS_Error
;*******************************************************************************
;
;Description:  Call DOS to obtain DOS extended error #
;
;Called Procedures: None
;
;Input: 	    None
;
;Output:	    AX = error number
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Get_DOS_Error
;
;	call DOS for extended error (INT21 GetExtendedError + 00 <5900>)
;	set up registers for return
;	ret
;
;	END  Get_DOS_Error
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Get_DOS_Error

   Get_DOS_Error PROC NEAR

   push bx
   mov	ax,(GetExtendedError shl 8) + not_used ; call DOS for extended error   ;AN000;
   xor	bx,bx
   push es				;				       ;AN000;
   INT	21h				;    GetExtendedError + not_used <5900>;AN000;
   pop	es
   pop	bx				;				       ;AN000;
   xor	cx,cx				; reset insert	(CX)		       ;AC024;

   ret					;				       ;AN000;

   ENDPROC Get_DOS_Error

   CODE ENDS

   include msgdcl.inc

   END	START

