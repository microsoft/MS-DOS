	PAGE	90,132			;A2
	title	LABEL.SAL - DOS LABEL COMMAND
;*****************************************************************************
;*									     *
;*  MODULE NAME:       LABEL						     *
;*									     *
;*  DESCRIPTIVE NAME:  LABEL a diskette or disk 			     *
;*									     *
;*  FUNCTION:	       Create, change or delete a volume label on a disk.    *
;*									     *
;*  ENTRY POINT:       Start						     *
;*									     *
;*  INPUT:	       (DOS command line parameters)			     *
;*		       [d:][path]LABEL [d:][volume label]		     *
;*    where:								     *
;*	[d:][path] before LABEL specifies the drive and path that contains   *
;*	the LABEL command file. 					     *
;*									     *
;*	[d:][volume label] specifies the volume label.	Volume labels are    *
;*	used to identify a disk.  They can be up to 11 characters and are in *
;*	the same format as volume labels created by FORMAT/V.		     *
;*									     *
;*  EXIT-NORMAL:  ERRORLEVEL 0 - Normal completion			     *
;*									     *
;*  EXIT-ERROR:   ERRORLEVEL 1 - Any error				     *
;*									     *
;*  EFFECTS: The volume label is set to the indicated string.  The volume    *
;*	     serial number, if present, is also displayed.		     *
;*									     *
;*  INCLUDED FILES:  None						     *
;*									     *
;*  INTERNAL REFERENCES:						     *
;*									     *
;*    Routines: 							     *
;*	CHARACTER_CHECK - See if char is valid for filename		     *
;*	CHECK_DELETE - Get user Y/N if to delete old label		     *
;*	CHECK_FOR_DRIVE_LETTER - Parse for drive in string		     *
;*	CHECK_TRANSLATE_DRIVE - See if drive is SUBST or ASSIGN 	     *
;*	CHK_DBCS -See if specified byte is a DBCS lead byte		     *
;*	CHK_DBCS_BLANK - Process DBCS blank char			     *
;*	CREATE_NEW_LABEL - Output new vol label 			     *
;*	DATA AREAS - STACK, buffers, FCB'S, message sublists                 *
;*	DELETE_OLD_LABEL - Delete original volume label 		     *
;*	DISPLAY_MSG - Send msg to system message handler		     *
;*	DRIVE_SETUP - Verify drive, get default, setup drive ID 	     *
;*	ERROR_EXIT - Abnormal return to DOS				     *
;*	FIND_FIRST_CHAR - Locate first non blank in input		     *
;*	FIND_OLD_LABEL - Get the existing volume label			     *
;*	GET_NEW_LABEL - Parse new vol label name into path		     *
;*	GET_SERIAL_NUM - Get vol ser number from "GET_MEDIA_ID" 	     *
;*	GET_USER_INPUT - Read from user new vol label			     *
;*	MAIN CODE - PSP, entry point					     *
;*	MAIN_BEGIN - High level function control			     *
;*	OUTPUT_OLD_LABEL - Display the original vol label		     *
;*	PRELOAD_MESSAGES - Set up sys msgs, DOS version check		     *
;*	PROCESS_STRING - Mov string to buf, check bad chars		     *
;*	SETUP_CRLF - Carriage return, line feed 			     *
;*	SETUP_DELLABEL - "Delete current volume label (Y/N)?"		     *
;*	SETUP_HASLABEL - "Volume in drive %1 is %2"			     *
;*	SETUP_INVCHAR - "Invalid characters in volume label"		     *
;*	SETUP_INVDRIVE - "Invalid drive specification"			     *
;*	SETUP_NETDRIVE - "Cannot %1 a Network drive"			     *
;*	SETUP_NEWLABEL - "Volume label (11 characters, ENTER for none)?"     *
;*	SETUP_NOLABEL - "Volume in drive %1 has no label"		     *
;*	SETUP_NOROOM - "Cannot make directory entry"			     *
;*	SETUP_SERIALNUM - "Volume Serial Number is %1-%2"		     *
;*	SETUP_SUBSTASGN - "Cannot %1 a SUBSTed or ASSIGNed drive"	     *
;*	SETUP_TOOMANY - "Too many files open"				     *
;*									     *
;*    Data Areas:							     *
;*	CONTROL BLOCKS - SUBLISTS for message parameters		     *
;*	BUFFERS - For GET_MEDIA_ID, several FCB'S                            *
;*	PSP - Contains the DOS command line parameters. 		     *
;*	STACK - Temporary save area					     *
;*									     *
;*  EXTERNAL REFERENCES:						     *
;*									     *
;*    Routines: 							     *
;*	SYSDISPMSG (NEAR)  - Message display routine			     *
;*	SYSLOADMSG (NEAR)  - System message loader			     *
;*									     *
;*    Data Areas:							     *
;*	DTA - defined for the DOS FINDFIRST function.			     *
;*									     *
;*  NOTES:  LABEL should not be used with SUBSTed drives. The root directory *
;*	    of the actual drive will be the target of LABEL.  LABEL should   *
;*	    not be used with ASSIGNed drives or to label network drives.     *				   *
;*									     *
;*	    This module should be processed with the SALUT pre-processor     *
;*	    with the re-alignment not requested, as:			     *
;*									     *
;*		 SALUT LABEL,NUL					     *
;*									     *
;*	    To assemble these modules, the sequential or alphabetical	     *
;*	    ordering of segments may be used.				     *
;*									     *
;*	    Sample LINK command:					     *
;*									     *
;*		 LINK @LABEL.ARF					     *
;*									     *
;*	    Where the LABEL.ARF is defined as:				     *
;*									     *
;*		 LABEL+ 						     *
;*		 LABELM 						     *
;*									     *
;*	    These modules should be linked in this order. The load module is *
;*	    a COM file.  It should be converted via EXE2BIN to a .COM file.  *
;*									     *
;*  REVISION HISTORY:							     *
;*									     *
;*    AN000;D  DBCS Support	       (New LOC)	  06/87  S. Maes     *
;*    AN000;M  Message service routine (New LOC)	  06/87  S. Maes     *
;*    AC000;M  Message service routine (Changed LOC)	  06/87  S. Maes     *
;*    AN000;S  Serial Number	       (New LOC)	  06/87  S. Maes     *
;*    AC000;K  SALUT					  08/87  E. Kiser    *
;*    Ax001;   DCR0524 - enable deletion of labelID	  04/88  S. Maes     *
;*    Ax002;   PTM4282 - parse complete line for invalids 04/88  S. Maes     *
;*    AN003;   PTM4588 - scan entire line fails DBCS	  05/88  S. Maes     *
;*									     *
;*  COPYRIGHT: The following notice is found in the OBJ code generated	     *
;*	       in the LABELM.SAL module.				     *
;*									     *
;*	       "Version 4.00 (C)Copyright 1988 Microsoft
;*	       "Licensed Material - Program Property of Microsoft"		     *
;*									     *
;*****************************************************************************
	HEADER	<DEFINITIONS - LOCAL MACROS AND LOCAL EQUATES>
IF1
	%OUT	COMPONENT=LABEL, MODULE=LABEL.SAL
ENDIF
HEADER	MACRO	TEXT
.XLIST
	SUBTTL	&TEXT
.LIST
	PAGE
	ENDM
;*****************************************************************************
; Equate Area
;*****************************************************************************
;		   $SALUT (4,20,25,36) ;AN000;K
;		DOS FUNCTION CALLS
FCB_SEARCH	   equ	11h
FCB_DELETE	   equ	13h
GET_DEFAULT	   equ	19h
SET_DTA 	   equ	1Ah
CLOSE		   equ	3Eh
READ		   equ	3Fh
IOCTL		   equ	44h
LOC_OR_NET	   equ	9h	   ;AN000;K Local or network, subfunc of IOCTL
EXIT		   equ	4Ch
CREATE_FILE	   equ	5Bh
YN_CHECK	   equ	6523h	   ;AN001; 65=GetExtCtry 23=Y/NCheck
GET_MEDIA_ID	   equ	6900h	   ;AN000;S Int 21 for Serial Number
GET_DBCS_ENV	   equ	6300h	   ;AN000;D DBCS support
XNAMETRANS	   equ	60h	   ;AN000;

;		DBCS SPECIAL CHARACTER DEFINITIONS

DBCSBLK_BYTEONE    equ	81h	   ;AN000;D 1st byte of DBCS blank
DBCSBLK_BYTETWO    equ	40h	   ;AN000;D 2nd byte of DBCS blank
SBCSBLANKS	   equ	2020h	   ;AN000;D 2 SBCS blanks

;		MISCELLANEOUS EQUATES

ASCII_DRV	   equ	"A"-1	   ;AN000;D Convert to Ascii drive
BLANK		   equ	" "
CHAR_ZERO	   equ	"0"	   ;AN000;K Padding for serial number
COLON		   equ	":"
DEFAULT_DRIVE	   equ	0
DOT_LOCATION	   equ	8
DRIVE_INVALID	   equ	0FFh
END_OF_STRING	   equ	0
MAX_CHARS	   equ	11
MAX_INPUT	   equ	100h-81h   ;Size of input buffer
NO		   equ	0	   ;AN001; Compare for Y/N response
PERIOD		   equ	"."
YES		   equ	1	   ;AN001; Compare for Y/N response
ZERO		   equ	0

;		ERROR LEVEL RETURN CODES

ERRORLEVEL_0	   equ	0
ERRORLEVEL_1	   equ	1

;		ATTRIBUTE OF DIRECTORY ENTRY

VOL_ATTRIBUTE	   equ	8

;		ERROR CODES FROM DOS FUNCTIONS

VOL_NOT_FOUND	   equ	0FFh
TOO_MANY_FILES	   equ	4

;		ID IF MESSAGES DISPLAYED BY "LABEL"

TOO_MANY_MSG	   equ	1	   ;AN000;M Too many files open
NO_ROOM_MSG	   equ	2	   ;AN000;M Cannot make directory entry
INV_CHAR_MSG	   equ	3	   ;AN000;M Invalid characters in volume label
NEW_LABEL_MSG	   equ	4	   ;AN000;M Vol label (11 chars, ENTER for none)?
INV_DRIVE_MSG	   equ	5	   ;AN000;M Invalid drive specification
NETWORKDRIVEMSG    equ	6	   ;AN000;M Cannot %1 a Network drive
SUBSTASSIGNMSG	   equ	7	   ;AN000;M Cannot %1 a SUBSTed or ASSIGNed drive
NO_LABEL_MSG	   equ	8	   ;AN000;M Volume in drive %1 has no label
SERIAL_NUM_MSG	   equ	9	   ;AN000;M Volume Serial Number is %1
HAS_LABEL_MSG	   equ	10	   ;AN000;M Volume in Drive %1 is %2
DEL_LABEL_MSG	   equ	11	   ;AN001;M Delete current volume label (Y/N)?
CRLF_MSG	   equ	12	   ;AN001;M CR,LF

;		DEFINITIONS OF FIELDS WITHIN MSG SUBLISTS

MAXWIDTH	   equ	0	   ;AN000;M 0 will ensure no padding
MINWIDTH	   equ	1	   ;AN000;M At least 1 char to insert in msg
STR_INPUT	   equ	16	   ;AN000;M Byte definition for s?_flags
SUBLIST_LENGTH	   equ	11	   ;AN000;M Length of sublist structure
RESERVED	   equ	0	   ;AN000;M Reserved byte field
CR		   equ	0Dh	   ;Carriage Return
NO_INPUT	   equ	00h	   ;AN000;M No input characters
DOS_CON_INPUT	   equ	00C8h	   ;AN000;M No input characters
EXT_ERR_CLASS	   equ	01h	   ;AN000;M DOS Extended error class
UTILITY_MSG_CLASS  equ	0FFh	   ;AN000;M Utility message class
STDIN		   equ	0000h	   ;File handle
STDOUT		   equ	0001h	   ;Standard Output device handle
STDERR		   equ	0002h	   ;Standard Error Output device handle
BIN_HEX_WORD	   equ	23h	   ;AN000;M a0100011
RIGHT_ALIGN	   equ	80h	   ;AN000;M 10xxxxxx
CHAR_FIELD_CHAR    equ	0	   ;AN000;M a0000000
		   HEADER <MAIN CODE - PSP, ENTRY POINT>
CSEG		   segment public

		   ASSUME cs:CSEG,ds:CSEG,es:CSEG,ss:CSEG

		   EXTRN SYSDISPMSG:NEAR ;SYSTEM DISPLAY MESSAGE ROUTINE
		   EXTRN SYSLOADMSG:NEAR ;SYSTEM MESSAGE LOADER ROUTINE

		   org	5Ch
FCB1		   label byte

		   org	80h
Num_Parms	   label byte

		   org	81h
Parm_Area	   label byte

		   org	100h
Start:				   ;DOS ENTRY POINT
		   jmp	Main_Begin ;SKIP CONSTANTS
		   HEADER <DATA AREAS - STACK, BUFFERS, FCB'S, MESSAGE SUBLISTS>
		   EVEN
Stack_Area	   db	512 dup ("S") ;Added in DOS 3.20 to support hardware requiring
End_Stack_Area	   db	0	   ;large stacks. DO NOT PUT DATA ABOVE THIS !
New_Vol_Path	   db	" :\"	   ;Path for new vol label
New_Vol_Name	   db	"        " ;Where first 8 chars go
New_Vol_Ext	   db	".   ",0   ;Dot and extension
End_Parameters	   dw	0	   ;End of input string

Program_Flag	   db	0	   ;Status Flag
USER_INPUT	   equ	01h	   ;User has input already
LABEL_FND	   equ	02h	   ;Volume label found
NO_DELETE	   equ	04h	   ;No need for label delete
GET_INPUT	   equ	08h	   ;Need user input
CHAR_BAD	   equ	10h	   ;Invalid character in string
FOUND_DBCS	   equ	20h	   ;AN000;K in process of handling DBCS chars

Vol_FCB 	   db	0FFh	   ;Extended FCB
		   db	0,0,0,0,0
		   db	VOL_ATTRIBUTE ;Attribute for vol label
FCB_Drive	   db	0	   ;Drive number
Vol_Name	   db	"???????????" ;Match any vol name found
		   db	25 dup (0) ;Rest of the opened FCB
Label_Name	   db	"???????????",0 ;AN000;
FCB_Drive_Char	   db	" "	   ;AN000;K printable version of FCB_Drive above

TranSrc 	   db	"A:CON",0,0 ;AN000;A Device so we don't hit the drive
TranDst 	   db	64 dup(' ') ;AN000;A
Label_Word	   db	"LABEL",0  ;AN000;M Message substitution parm

Del_FCB 	   db	0FFh	   ;Extended FCB
		   db	0,0,0,0,0
		   db	VOL_ATTRIBUTE ;Attribute for vol label
Del_Drive	   db	0	   ;Drive number
Del_Name	   db	"???????????" ;Match any vol name found

;		MESSAGE SUBLIST STRUCTURES

Sublist1	   Label Dword	   ;AN000;M Substitution list
s1_nxtlst	   db	SUBLIST_LENGTH ;AN000;M (11)Ptr to next sublist
s1_reserve	   db	RESERVED   ;AN000;M (0)Reserved
s1_offset	   dw	?	   ;AN000;M Time/date or data pointer
s1_segment	   dw	?	   ;AN000;M Time/date or data pointer
s1_id		   db	1	   ;AN000;M N of %n
s1_flags	   db	?	   ;AN000;M Data-type flags (a0sstttt)
s1_maxwidth	   db	?	   ;AN000;M Maximum field width
s1_minwidth	   db	?	   ;AN000;M Minimum field width
s1_padchar	   db	?	   ;AN000;M Char to pad field

Sublist2	   Label Dword	   ;AN000;M Substitution list
s2_nxtlst	   db	SUBLIST_LENGTH ;AN000;M (11)Ptr to next sublist
s2_reserve	   db	RESERVED   ;AN000;M (0)Reserved
s2_offset	   dw	?	   ;AN000;M Time/date or data pointer
s2_segment	   dw	?	   ;AN000;M Time/date or data pointer
s2_id		   db	2	   ;AN000;M N of %n
s2_flags	   db	?	   ;AN000;M Data-type flags (a0sstttt)
s2_maxwidth	   db	?	   ;AN000;M Maximum field width
s2_minwidth	   db	?	   ;AN000;M Minimum field width
s2_padchar	   db	?	   ;AN000;M Char to pad field

;		GET_MEDIA_ID STRUCTURE

SerNumBuf	   Label Byte	   ;AN000;S GET_MEDIA_ID buffer
		   dw	0	   ;AN000;S Info level (set on input)
SerNum		   dd	0	   ;AN000;S Serial #
		   db	11 DUP(' ') ;AN000;S Volume label
		   db	8 DUP(' ') ;AN000;S File system type

;		CHK_DBCS STRUCTURE
DBCSev_Off	   dw	0	   ;AC000;D offset of DBCS EV
DBCSev_Seg	   dw	0	   ;AC000;D segment of DBCS EV

		   HEADER <MAIN_BEGIN - HIGH LEVEL FUNCTION CONTROL>
;  $SALUT (4,4,9,36)		   ;AN000;K
;*****************************************************************************
;*									     *
;*  SUBROUTINE NAME:	  main_begin					     *
;*									     *
;*  SUBROUTINE FUNCTION:  Preload message file and check DOS version	     *
;*			    by calling SYSLOADMSG			     *
;*			  Get the command line parameters		     *
;*			  Parse command line				     *
;*			  Verify the correctness of the parameters	     *
;*			  Get label if exists				     *
;*			  Get serial number if exists			     *
;*			  Get new volume name				     *
;*			  Make new volume file				     *
;*			  Print messages by calling SYSDISPMSG		     *
;*									     *
;*  EXTERNAL ROUTINES:	  SYSDISPMSG					     *
;*			  SYSLOADMSG					     *
;*									     *
;*  INTERNAL ROUTINES:	  Character_Check	      Main_Begin	     *
;*			  Check_Delete		      Output_Old_Label	     *
;*			  Check_For_Drive_Letter      Preload_Messages	     *
;*			  Check_Trans_Drive	      Process_String	     *
;*			  Chk_DBCS		      Setup_CRLF	     *
;*			  Chk_DBCS_Blank	      Setup_DelLabel	     *
;*			  Create_New_Label	      Setup_HasLabel	     *
;*			  Delete_Old_Label	      Setup_InvChar	     *
;*			  Display_Msg		      Setup_InvDrive	     *
;*			  Drive_Setup		      Setup_NetDrive	     *
;*			  Error_Exit		      Setup_NewLabel	     *
;*			  Find_First_Char	      Setup_NoLabel	     *
;*			  Find_Old_Label	      Setup_NoRoom	     *
;*			  Get_New_Label 	      Setup_SerialNum	     *
;*			  Get_Serial_Num	      Setup_SubstAsgn	     *
;*			  Get_User_Input	      Setup_TooMany	     *
;*									     *
;*****************************************************************************
   PUBLIC MAIN_BEGIN
Main_Begin Proc Near
   mov	sp,offset End_Stack_Area   ;Move stack to user area(Added in DOS 3.20)
   cld
   call Preload_Messages	   ;AN000;M Check DOS version & load msgs
   call Drive_Setup		   ;Get Drive letters
   call Find_Old_Label		   ;Get label if exist
   call Get_New_Label		   ;Get New Name
   call Check_Delete		   ;AN001; See if delete needed or wanted
   call Delete_Old_Label	   ;Del the old label if it exists
   call Create_New_Label	   ;Make new Vol file
   mov	ax,(EXIT shl 8)+ERRORLEVEL_0 ;all done, pass back zero ret code
   INT	21H
Main_Begin ENDP

   HEADER <DRIVE_SETUP - VERIFY DRIVE, GET DEFAULT, SETUP DRIVE ID>
;*****************************************************************************
;  Verify specified drive, get default if needed, setup drive letters
;*****************************************************************************

   PUBLIC DRIVE_SETUP
Drive_Setup PROC NEAR
   cmp	al,DRIVE_INVALID	   ;Was specified drive ok ?
;  $if	e			   ;AN000;K No
   JNE $$IF1
       mov  ax,INV_DRIVE_MSG	   ;Nope, tell & quit
       call Setup_InvDrive	   ;AN000;M
       call Display_Msg 	   ;AN000;M Set up msg & display
       call Error_Exit
;  $endif			   ;AN000;K
$$IF1:
;			    Get_Drive:
   mov	al,FCB1 		   ;Get specified drive
   cmp	al,DEFAULT_DRIVE	   ;Was drive given ?
;  $if	e			   ;AN000;K No
   JNE $$IF3
       mov  ah,GET_DEFAULT	   ;No, get default drive
       INT  21H
       inc  al			   ;Get a: based on 1, not 0
;  $endif			   ;AN000;K
$$IF3:
;			    Drive_Letter:
   mov	FCB_Drive,al		   ;Put drive number in FCB
   mov	Del_Drive,al		   ;Put drive number in FCB
   mov	bl,al
   mov	al,FCB_Drive		   ;AN000;K get numeric value of drive letter
   add	al,ASCII_DRV		   ;AN000;M  ("A"-1)
   mov	FCB_Drive_Char,al	   ;AN000;K make drive printable
   mov	ax,(IOCTL SHL 8)+LOC_OR_NET ;(4409h)determine drive type
   INT	21H
   test dx,1000h		   ;bit 12 on means network drive
;  $if	nz			   ;AN000;K
   JZ $$IF5
       mov  ax,NETWORKDRIVEMSG
       call Setup_NetDrive	   ;AN000;M
       call Display_Msg 	   ;AN000;M First display the msg
       call Error_Exit
;  $endif			   ;AN000;K
$$IF5:
   call Check_Trans_Drive	   ;AN000;A Is drv SUBSTed/ASSIGNed?
;  $if	nz			   ;AN000;K Yes
   JZ $$IF7
       mov  ax,SUBSTASSIGNMSG	   ;AN000;A Prepare SUBST/ASSIGN msg
       call Setup_SubstAsgn	   ;AN000;M
       call Display_Msg 	   ;AN000;A Display the message
       call Error_Exit		   ;AN000;A Then exit
;  $endif			   ;AN000;K
$$IF7:
   mov	al,Del_Drive
   add	al,ASCII_DRV		   ;AN000;K ("A"-1) Convert to Ascii
   mov	New_Vol_Path,al 	   ;Put drive letter in path
   ret
Drive_Setup ENDP

   HEADER <CHECK_TRANSLATE_DRIVE - SEE IF DRIVE IS SUBST OR ASSIGN>
;*****************************************************************************
;  Routine name: Check_Translate_Drive
;*****************************************************************************
;  Descr:  Do a name translate call on the drive letter to see if it is
;	   assigned by SUBST or ASSIGN
;  Input:  Drive

   PUBLIC CHECK_TRANS_DRIVE
Check_Trans_Drive PROC NEAR	   ;AN000;A
   mov	bl,FCB_Drive_Char	   ;AN000;A Get drive
   mov	byte ptr [TranSrc],bl	   ;AN000;A Make string "x:\"
   mov	si,offset TranSrc	   ;AN000;A Point to translate string
   mov	di,offset TranDst	   ;AN000;A Point at output buffer
   mov	ah,XNAMETRANS		   ;AN000;A (60H) Get real path
   INT	21H			   ;AN000;A
   mov	bl,byte ptr [TranSrc]	   ;AN000;A Get drive letter from path
   cmp	bl,byte ptr [TranDst]	   ;AN000;A Did drive letter change?
   ret				   ;AN000;A
Check_Trans_Drive ENDP		   ;AN000;A

   HEADER <FIND_OLD_LABEL - GET THE EXISTING VOLUME LABEL>
;*****************************************************************************
;  Find old volume label
;*****************************************************************************
;  Input:  VOL_FCB set to find any vol label
;  Output: VOL_FCB has label name if one found
;	   PROGRAM_FLAG = LABEL_FND if one is found
;	   LABEL_NAME gets found label name

   PUBLIC FIND_OLD_LABEL
Find_Old_Label PROC NEAR
   mov	dx,offset Vol_FCB	   ;Point at FCB to find vol
   mov	ah,SET_DTA		   ;(1AH)
   INT	21H
   mov	dx,offset Vol_FCB	   ;Point at FCB to find vol
   mov	ah,FCB_SEARCH		   ;(11H)
   INT	21H			   ;Find vol label
   cmp	al,VOL_NOT_FOUND	   ;Find one
;  $if	ne			   ;AN000;K Yes
   JE $$IF9
       or   Program_Flag,LABEL_FND ;Yes, set flag
       mov  si,offset Vol_Name	   ;Found name
       mov  di,offset Label_Name   ;Where to put it
       mov  cx,MAX_CHARS	   ;How many characters
       rep  movsb		   ;Move the string
;  $endif			   ;AN000;K
$$IF9:
;			     Find_Return:
   ret
Find_Old_Label ENDP

   HEADER <GET_NEW_LABEL - PARSE NEW VOL LABEL NAME INTO PATH>
;*****************************************************************************
;  Parse new volume label name into path.
;*****************************************************************************
;  Input:  PARM_AREA has input string
;  Output: NEW_VOL_NAME has ASCIIZ string for new label, or an END_OF_STRING
;	   if nothing entered

   PUBLIC GET_NEW_LABEL
Get_New_Label PROC NEAR
;  $do				   ;AN000;K
$$DO11:
       xor  cx,cx		   ;Zero counter
       mov  si,offset Parm_Area    ;Input buffer
       mov  di,offset New_Vol_Name ;Target Buffer
       call Find_First_Char	   ;Get first not blank char
       test Program_Flag,GET_INPUT ;Find input?
       jnz  Need_User_Input	   ;No, go get it
       call Process_String	   ;Scan string, move it
       test Program_Flag,CHAR_BAD  ;Invalid characters?
       jnz  Need_User_Input	   ;Yes, get user to input
       mov  al,END_OF_STRING	   ;Mark end of ASCIIZ string
       stosb
       cmp  New_Vol_Name,END_OF_STRING ;Any chars entered?
;  $leave ne			   ;Yes, all done here
   JNE $$EN11
       test Program_Flag,USER_INPUT ;See if command line parse
;  $leave nz			   ;No, user had his chance
   JNZ $$EN11
Need_User_Input:
       test Program_Flag,USER_INPUT ;Is this the first time here?
;      $if  z			   ;AN000;K Yes, label not already gone out
       JNZ $$IF14
	   call Output_Old_Label   ;Yes, print current vol label
;      $endif			   ;AN000;K
$$IF14:
Input_New_Label:
       call Get_User_Input	   ;Get new string
;  $enddo			   ;AN000;K Go parse it again
   JMP SHORT $$DO11
$$EN11:
   ret
Get_New_Label ENDP

   HEADER <FIND_FIRST_CHAR - LOCATE FIRST NON BLANK IN INPUT>
;*****************************************************************************
;  Find the first non blank character in input string
;*****************************************************************************
;  Input:  SI = pointer to next character
;  Output: PROGRAM_FLAG = GET_INPUT if user input needed
;	   AL = First not blank character
;  Notes:  GET_INPUT set if nothing follows drive letter

   PUBLIC FIND_FIRST_CHAR
Find_First_Char PROC NEAR
;  $do				   ;AN000;K
$$DO17:
       and  Program_Flag,not GET_INPUT ;Clear flag
       lodsb			   ;Get char
       call Chk_DBCS		   ;AN000;D Check DBCS env
;      $if  c			   ;AN000;K
       JNC $$IF18
	   call Chk_DBCS_Blank	   ;AN000;D Is it a DBCS blank?
;      $endif			   ;AN000;K
$$IF18:
       cmp  al,BLANK		   ;Is it a blank?
;  $enddo ne			   ;AN000;K No, quit
   JE $$DO17
   call Check_For_Drive_Letter	   ;Parse out drive letter
   call Chk_DBCS		   ;AN000;D Check DBCS env
;  $if	c			   ;AN000;K
   JNC $$IF21
       call Chk_DBCS_Blank	   ;AN000;D Is it a DBCS blank?
       and  Program_Flag,not FOUND_DBCS ;AN000;K forget this was a dbcs for now
;  $endif			   ;AN000;K
$$IF21:
   cmp	al,BLANK		   ;Blank following drive letter?
;  $if	e			   ;AN000;K
   JNE $$IF23
       or   Program_Flag,GET_INPUT
;  $endif			   ;AN000;K
$$IF23:
   ret
Find_First_Char ENDP

   HEADER <CHK_DBCS -SEE IF SPECIFIED BYTE IS A DBCS LEAD BYTE>
;*****************************************************************************
;  Check DBCS environment
;*****************************************************************************
;  Function: Check if a specified byte is in ranges of the DBCS lead bytes
;  Input:    AL = Code to be examined
;  Output:   If CF is on then a lead byte of DBCS
;  Register: FL is used for the output, others are unchanged.

   PUBLIC CHK_DBCS
Chk_DBCS PROC			   ;AC000;D
   push ds			   ;AC000;D save regs, about to be clobbered
   push si			   ;AC000;D
   cmp	DBCSev_Seg,ZERO 	   ;AC000;D Already set ?
;  $if	e			   ;AN000;K if the vector not yet found
   JNE $$IF25
       push ax			   ;AC000;D
       mov  ax,GET_DBCS_ENV	   ;AC000;D GET DBCS EV call
       INT  21H 		   ;AC000;D ds:si points to the dbcs vector
       ASSUME ds:NOTHING	   ;AN000;K that function clobbered old DS
       mov  DBCSev_Off,si	   ;AC000;D remem where dbcs vector is so next
       mov  DBCSev_Seg,ds	   ;AC000;D time don't have to look for it
       pop  ax			   ;AC000;D
;  $endif			   ;AN000;K
$$IF25:
   mov	si,DBCSev_Off		   ;AC000;D set DS:SI to point to
   mov	ds,DBCSev_Seg		   ;AC000;D  the dbcs vector
;  $search			   ;AN000;K
$$DO27:
       cmp  word ptr [si],ZERO	   ;AC000;D vec ends with nul terminator entry
;  $leave e			   ;AN000;K if that was terminator entry, quit
   JE $$EN27
       cmp  al,[si]		   ;AC000;D look at LOW value of vector
;  $exitif nb,and		   ;AN000;K if this byte in range of LOW
   JB $$IF27
       cmp  al,[si+1]		   ;AC000;D look at HIGH value of vector
;  $exitif na			   ;AN000;K if this byte is still in range
   JA $$IF27
       or   Program_Flag,FOUND_DBCS ;AN000;K remember we found one of a pair
       stc			   ;AC000;D set flag to say, found a DBCS char
;  $orelse			   ;AN000;K since char not in this vector
   JMP SHORT $$SR27
$$IF27:
       add  si,2		   ;AC000;D go look at next vec in dbcs table
;  $endloop			   ;AN000;K go back and ck out new vector entry
   JMP SHORT $$DO27
$$EN27:
       clc			   ;AC000;D set flag to say not a DBCS char
;  $endsrch			   ;AN000;K
$$SR27:
   pop	si			   ;AC000;D restore the regs
   pop	ds			   ;AC000;D
   ASSUME ds:CSEG		   ;AN000;K tell masm, DS back to normal
   ret				   ;AC000;D
Chk_DBCS ENDP			   ;AC000;D

   HEADER <CHK_DBCS_BLANK - PROCESS DBCS BLANK CHAR>
;*****************************************************************************
;  Check DBCS char for a blank (8140)
;*****************************************************************************
;  Function: Check if a specified byte is a DBCS blank
;  Input:    AL = Byte to be examined
;	     SI = Points to next byte
;  Output:   SI = UNchanged

   PUBLIC CHK_DBCS_BLANK
Chk_DBCS_Blank PROC NEAR	   ;AN000;D
   cmp	al,DBCSBLK_BYTEONE	   ;AN000;D Is the leading byte 81h?
;  $if	e,and			   ;AN000;K
   JNE $$IF33
   cmp	byte ptr [si],DBCSBLK_BYTETWO ;AN000;D Is the 2nd byte 40h?
;  $if	e			   ;AN000;K Yes, change to 2 SBCS blanks
   JNE $$IF33
;		 Convert_DBCS_Blank: ;AN000;D
       mov  word ptr es:[si]-1,SBCSBLANKS ;AN000;D Fill it up with blank-blank
       mov  al,BLANK		   ;AN000;K pretend this char is a blank
;  $endif			   ;AN000;K
$$IF33:
;		  DBCS_Blank_Exit: ;AN000;D
   ret				   ;AN000;D And leave
Chk_DBCS_Blank ENDP		   ;AN000;D

   HEADER <CHECK_FOR_DRIVE_LETTER - PARSE FOR DRIVE IN STRING>
;*****************************************************************************
;  Parse a drive letter out of the string [Check_For_Drive_Letter]
;*****************************************************************************
;  Input:  SI = pointer to next character
;	   CX = character count
;  Output: SI = SI+1 if drive letter entered

   PUBLIC CHECK_FOR_DRIVE_LETTER
Check_For_Drive_Letter PROC NEAR
   test Program_Flag,USER_INPUT    ;Input not from command line?
;  $if	z			   ;AN000;K
   JNZ $$IF35
       cmp  cx,END_OF_STRING	   ;Anything parsed yet
;      $if  e			   ;AN000;
       JNE $$IF36
	   cmp	al,CR		   ;First char a CR ?
;	   $if	ne
	   JE $$IF37
	       cmp  byte ptr [si],COLON ;Drive letter entered?
;	       $if  e		   ;AN000;K
	       JNE $$IF38
		   inc	si	   ;Yes, point past the colon
		   lodsb	   ;And get next character
;	       $endif		   ;AN000;K
$$IF38:
;	   $endif		   ;AN000;K
$$IF37:
;      $endif			   ;AN000;K
$$IF36:
;  $endif			   ;AN000;K
$$IF35:
Drive_Letter_Ret:
   ret
Check_For_Drive_Letter ENDP

   HEADER <PROCESS_STRING - MOV STRING TO BUF, CHECK BAD CHARS>
;*****************************************************************************
;  Move the input string into buffer, checking for bad characters
;*****************************************************************************
;  Input:  SI = pointer to next character
;	   DI = pointer to buffer
;	   AL = current character in string
;  Output: PROGRAM_FLAG = CHAR_BAD if invalid char in string (Flag set in
;	   called Character_Check routine)
;  Notes:  Insert a "." in string to seperate 8th and 9th characters so
;	   ASCIIZ string is the result.

   PUBLIC PROCESS_STRING
Process_String PROC NEAR
   cmp	al,CR			   ;is it an ENTER ?
;  $if	e
   JNE $$IF43
       test Program_Flag,USER_INPUT ;has user been told to provide input?
;      $if  nz			   ;If user has been prompted for input
       JZ $$IF44
	   cmp	cx,ZERO 	   ;And he said - nothing
;	   $if	e
	   JNE $$IF45
	       jmp  Process_String_Return ;AN001; ENTER is acceptable
;	   $endif
$$IF45:
;      $endif
$$IF44:
;  $else			   ;Since got other than just ENTER
   JMP SHORT $$EN43
$$IF43:
       test Program_Flag,FOUND_DBCS ;AN000;K If prev char not 1st of DBCS pair
       jz   Do_More_Check	   ;AN000;K then go check it out
       and  Program_Flag,not FOUND_DBCS ;AN000; Reset flag, found its partner
       cmp  cx,11		   ;AC003; Continue to check chars but don't
       jge  Scan_Continue	   ;AC003; store anything more
       jmp  short Got_Ok_Character ;AN000; Partner is ok
Do_More_Check:
       call Chk_DBCS		   ;AN000;D Check DBCS env
       jnc  Check_Char		   ;AN000;D If carry, it's a DBCS char
       cmp  cx,10		   ;AC003; If previous char was the 10th
       jge  Scan_Continue	   ;AC003; then there is no room for 11th DBCS
       call Chk_DBCS_Blank	   ;AN000;D Is it a DBCS blank?
       jmp  Got_Ok_Character	   ;AN000;D
Check_Char:
       call Character_Check	   ;Is it a valid char ?
       test Program_Flag,CHAR_BAD
       jnz  Process_String_Return  ;Flag was set, char was invalid
       cmp  cx,11		   ;AN003; Continue to check chars but don't
       jge  Scan_Continue	   ;AN003; store anything more
Got_Ok_Character:
       stosb			   ;Good char, store it
Scan_Continue:			   ;AN003; Skip storing chars since past limit
       inc  cx			   ;Inc character count
       cmp  cx,DOT_LOCATION	   ;Do we need "." for extension?
       jne  Get_Next_Char	   ;No
       mov  al,PERIOD		   ;Get a "." for extension
       stosb			   ;And save it
Get_Next_Char:
       lodsb			   ;Get next character
       cmp  cx,MAX_INPUT	   ;AN002; Have we reached end?
       jne  Process_String	   ;No, go diddle with it
;  $endif
$$EN43:
Process_String_Return:
   ret
Process_String ENDP

   HEADER <CHARACTER_CHECK - SEE IF CHAR IS VALID FOR FILENAME>
;*****************************************************************************
;  See if a character is valid for filename [Character_Check]
;*****************************************************************************
;  Input:  AL = character to be checked
;  Output: AL = character
;	   PROGRAM_FLAG = CHAR_BAD if invalid characters found

   PUBLIC CHARACTER_CHECK
Character_Check PROC NEAR
   or	Program_Flag,CHAR_BAD	   ;Assume bad character
   cmp	al,"*"
   je	Char_Check_Done
   cmp	al,"?"
   je	Char_Check_Done
   cmp	al,"["
   je	Char_Check_Done
   cmp	al,"]"
   je	Char_Check_Done
   cmp	al,":"
   je	Char_Check_Done
   cmp	al,"<"
   je	Char_Check_Done
   cmp	al,"|"
   je	Char_Check_Done
   cmp	al,">"
   je	Char_Check_Done
   cmp	al,"+"
   je	Char_Check_Done
   cmp	al,"="
   je	Char_Check_Done
   cmp	al,";"
   je	Char_Check_Done
   cmp	al,","
   je	Char_Check_Done
   cmp	al,"/"
   je	Char_Check_Done
   cmp	al,"\"
   je	Char_Check_Done
   cmp	al,'.'
   je	Char_Check_Done
   cmp	al,'"'
   je	Char_Check_Done
   cmp	al," "
   jb	Char_Check_Done
   and	Program_Flag,not CHAR_BAD  ;Char is ok
Char_Check_Done:
   ret
Character_Check ENDP

   HEADER <OUTPUT_OLD_LABEL - DISPLAY THE ORIGINAL VOL LABEL>
;*****************************************************************************
;  Print the old volume label
;*****************************************************************************
;  Input:  PROGRAM_FLAG = LABEL_FND if there is a label
;  Output: None
;  Notes:  Print the volume label

   PUBLIC OUTPUT_OLD_LABEL
Output_Old_Label PROC NEAR
   mov	ax,HAS_LABEL_MSG	   ;Assume label
   call Setup_HasLabel		   ;AN000;M
   test Program_Flag,LABEL_FND	   ;Is there one?
;  $if	z			   ;AN000;K If no label found, then
   JNZ $$IF50
       mov  ax,NO_LABEL_MSG	   ;No, other message
       call Setup_NoLabel	   ;AN000;M
;  $endif			   ;AN000;K
$$IF50:
   call Display_Msg		   ;AC000;M Set up msg and display
   call Get_Serial_Num		   ;AN000;S Since LABEL_FND, ck for SN
;  $if	nc			   ;AN000;K SN must be known
   JC $$IF52
       mov  ax,SERIAL_NUM_MSG	   ;AN000;S Prepare for SN message
       call Setup_SerialNum	   ;AN000;M
       call Display_Msg 	   ;AC000;M Set up msg and display
;  $endif			   ;AN000;K
$$IF52:
   ret
Output_Old_Label ENDP

   HEADER <GET_SERIAL_NUM - GET VOL SER NUMBER FROM "GET_MEDIA_ID">
;*****************************************************************************
;  Get the volume serial number
;*****************************************************************************
;  Input:  FCB_Drive
;  Output: SerNum if no carry
;  Notes:  Only DOS Version 4.0 and above will contain serial numbers

   PUBLIC GET_SERIAL_NUM
Get_Serial_Num PROC NEAR	   ;AN000;S
   mov	ax,GET_MEDIA_ID 	   ;AN000;S
   mov	bh,0			   ;AN000;S
   mov	bl,FCB_Drive		   ;AN000;S Which drive to check
   lea	dx,SerNumBuf		   ;AN000;S Pt to the buffer
   INT	21H			   ;AN000;S Make the call
   ret				   ;AN000;S
Get_Serial_Num ENDP		   ;AN000;S

   HEADER <GET_USER_INPUT - READ FROM USER NEW VOL LABEL>
;*****************************************************************************
;  Input from user a new volume label string
;*****************************************************************************
;  Input:  PROGRAM_FLAG = CHAR_BAD if there were invalid characters in string
;  Output: New string placed in PARM_AREA
;  Notes:  Print bad character message if needed and prompt and get user input

   PUBLIC GET_USER_INPUT
Get_User_Input PROC NEAR
   test Program_Flag,CHAR_BAD	   ;Do we need bad char message
;  $if	nz			   ;AN000;K
   JZ $$IF54
       mov  ax,INV_CHAR_MSG	   ;Yes
       call Setup_InvChar	   ;AN000;M
       call Display_Msg 	   ;AC000;M Set up msg and display
       and  Program_Flag,not CHAR_BAD ;Char is ok
;  $endif			   ;AN000;K
$$IF54:
   mov	ax,NEW_LABEL_MSG	   ;Tell user to input new label
   call Setup_NewLabel		   ;AN000;M
   call Display_Msg		   ;AC000;M Set up msg and display
   mov	dx,offset Parm_Area	   ;Point where to put new name
   mov	cx,MAX_INPUT		   ;Number of characters to read
   mov	bx,STDIN		   ;Read from keyboard
   mov	ah,READ 		   ;(3FH)
   INT	21H
   or	Program_Flag,USER_INPUT    ;Indicate user input has been received
   ret
Get_User_Input ENDP

   HEADER <CHECK_DELETE - SEE IF OLD LABEL SHOULD BE DELETED>
;*****************************************************************************
;  Check to see if old label should be deleted
;*****************************************************************************
;  Input:  PROGRAM_FLAG = LABEL_FND if there is a label
;  Output: PROGRAM_FLAG = NO_DELETE if label should not be deleted
;  Notes:  Get user Y/N if to delete previous label

   PUBLIC CHECK_DELETE
Check_Delete PROC NEAR
   test Program_Flag,LABEL_FND	   ;AN001; Is there a vol label
   jz	Check_Delete_Return	   ;AN001; No, no need for prompt
   cmp	New_Vol_Name,END_OF_STRING ;AN001; Did user enter label
   jne	Check_Delete_Return	   ;AN001; Yes, no need for prompt
Delete_Prompt:			   ;AN001;
   mov	ax,DEL_LABEL_MSG	   ;AN001; Point at Y/N prompt
   call Setup_DelLabel		   ;AN001;M Prepare message
   call Display_Msg		   ;AN001;M Call to Sysdispmsg
   mov	dx,ax			   ;AN001; Char ret'd, prep for ck
   mov	ax,YN_CHECK		   ;AN001; GetExtCtry,Y/NCheck
   INT	21H			   ;AN001;
   cmp	ax,YES			   ;AN001; Delete label ?
   je	Check_Delete_Return	   ;AN001; Yes
   cmp	ax,NO			   ;AN001; Delete label ?
   je	Delete_Label		   ;AN001; Yes
   jne	Delete_Prompt		   ;AN001; No, try again
Delete_Label:			   ;AN001;
   or	Program_Flag,NO_DELETE	   ;AN001; Yes, set flag
Check_Delete_Return:		   ;AN001;
   mov	ax,CRLF_MSG		   ;AN001; Point at CRLF message
   call Setup_CRLF		   ;AN001;M Prepare message
   call Display_Msg		   ;AN001;M Call to Sysdispmsg
   ret				   ;AN001;
Check_Delete ENDP

   HEADER <DELETE_OLD_LABEL - DELETE ORIGINAL VOLUME LABEL>
;*****************************************************************************
;  Delete old volume label
;*****************************************************************************
;  Input:  VOL_FCB has name of label if one found
;	   PROGRAM_FLAG = NO_DELETE if label doesn't need to be deleted
;  Output: Vol label deleted if it exists and user say's it is okay
;  Notes:  Ask user if old label should be deleted.

   PUBLIC DELETE_OLD_LABEL
Delete_Old_Label PROC NEAR
   test Program_Flag,NO_DELETE	   ;Need to delete label ?
;  $if	z			   ;AN000;K
   JNZ $$IF56
       lea  dx,Del_FCB		   ;Point at FCB to delete vol
       mov  ah,FCB_DELETE	   ;(13H) label and delete it
       INT  21H 		   ;Can't use handle cause Chmod won't find it
;  $endif			   ;AN000;K
$$IF56:
   ret
Delete_Old_Label ENDP

   HEADER <CREATE_NEW_LABEL - OUTPUT NEW VOL LABEL>
;*****************************************************************************
;  Create new volume label file if user specified one
;*****************************************************************************

   PUBLIC CREATE_NEW_LABEL
Create_New_Label PROC NEAR
   cmp	New_Vol_Name,END_OF_STRING ;Did user enter a vol label
;  $if	ne			   ;AN000;K
   JE $$IF58
       mov  dx,offset New_Vol_Path ;Point at path for file
       mov  cx,VOL_ATTRIBUTE	   ;Set it as a volume label
       mov  ah,CREATE_FILE	   ;(5BH) Go make it
       INT  21H
;      $if  nc			   ;AN000;K
       JC $$IF59
	   mov	bx,ax		   ;shift file handle
	   mov	ah,CLOSE	   ;And close the file
	   INT	21H
;      $else			   ;AN000;K since there was creation error,
       JMP SHORT $$EN59
$$IF59:
	   cmp	ax,TOO_MANY_FILES  ;Is it
;	   $if	ne		   ;AN000;K if not "too many files", then
	   JE $$IF61
	       mov  ax,NO_ROOM_MSG ;AN000;M
	       call Setup_NoRoom   ;AN000;M
	       call Display_Msg    ;AN000;M
	       test Program_Flag,LABEL_FND ;AN000;K was an old label found?
;	       $if  ne		   ;AN000;K if there was an old one,
	       JE $$IF62
				   ;need to restore the previous label
				   ;because the new one did not stick
		   mov	si,offset Label_Name ;AN000;K where old name was kept
		   mov	di,offset New_Vol_Name ;AN000;K where to put old name
		   mov	cx,8	   ;AN000;K count of filename up to "."
		   rep	movsb	   ;AN000;K
		   inc	di	   ;AN000;K skip the "."
		   mov	cx,3	   ;AN000;K length of extension
		   rep	movsb	   ;AN000;K
		   mov	dx,offset New_Vol_Path ;AN000;K drive\path\filename
		   mov	cx,VOL_ATTRIBUTE ;AN000;K make it a label
		   mov	ah,CREATE_FILE ;AN000;K make a label
		   INT	21H	   ;AN000;K at least, try to, anyway...
;	       $endif		   ;AN000;K old label?
$$IF62:
;	   $else		   ;AN000;K since is "too many files", then...
	   JMP SHORT $$EN61
$$IF61:
	       mov  ax,TOO_MANY_MSG ;AN000;M
	       call Setup_TooMany  ;AN000;M
	       call Display_Msg    ;AN000;M
;	   $endif		   ;AN000;K
$$EN61:
	   jmp	Error_Exit	   ;Tell user bad news and quit
;      $endif			   ;AN000;K
$$EN59:
;  $endif			   ;AN000;K
$$IF58:
   ret
Create_New_Label ENDP

   HEADER <PRELOAD_MESSAGES - SET UP SYS MSGS, DOS VERSION CHK>
;*****************************************************************************
;  Preload utility messages
;*****************************************************************************
;  Input:  None
;  Output: None
;  Notes:  Checks DOS version, if incorrect, or if error loading messages, will
;	     display error message and terminate

   PUBLIC PRELOAD_MESSAGES
Preload_Messages PROC NEAR	   ;AN000;M
   push ax			   ;AN000;M
   push bp			   ;AN000;M
   mov	bp,sp			   ;AN000;M
   push di			   ;AN000;M
   push si			   ;AN000;M
   call SYSLOADMSG		   ;AN000;M Load msgs & chk DOS ver
;  $if	c			   ;AN000;K
   JNC $$IF68
       call SYSDISPMSG		   ;AN000;M
       pop  si			   ;AN000;M
       pop  di			   ;AN000;M
       mov  sp,bp		   ;AN000;M
       pop  bp			   ;AN000;M
       pop  ax			   ;AN000;M
       call Error_Exit		   ;AN000;M
;  $endif			   ;AN000;K
$$IF68:
   pop	si			   ;AN000;M
   pop	di			   ;AN000;M
   mov	sp,bp			   ;AN000;M
   pop	bp			   ;AN000;M
   pop	ax			   ;AN000;M
   ret				   ;AN000;M
Preload_Messages ENDP		   ;AN000;M

   HEADER <DISPLAY_MSG - SEND MSG TO SYSTEM MESSAGE HANDLER>
;*****************************************************************************
;  Display utility messages
;*****************************************************************************
;  Input:  dx contains the messsage to display
;  Output: None
;  Notes:  The message called is displayed to stdout/stderr unless AX returns
;	     with error code (then setup for extended error to display)

   PUBLIC DISPLAY_MSG
Display_Msg PROC NEAR		   ;AN000;M
   push bp			   ;AN000;M
   mov	bp,sp			   ;AN000;M
   push di			   ;AN000;M
   push si			   ;AN000;M
   call SYSDISPMSG		   ;AN000;M Now display the message
;  $if	c			   ;AN000;K if there was a problem, then...
   JNC $$IF70
       mov  bx,STDERR		   ;AN000;M Error msg, so stderr
       mov  cx,0		   ;AN000;M Substitution count
       mov  dl,NO_INPUT 	   ;AN000;M No input characters
       mov  dh,EXT_ERR_CLASS	   ;AN000;M DOS Extended error class
       call SYSDISPMSG		   ;AN000;M Now display the extended error
       pop  si			   ;AN000;M
       pop  di			   ;AN000;M
       mov  sp,bp		   ;AN000;M
       pop  bp			   ;AN000;M
       call Error_Exit		   ;AN000;M Nothing we can do so leave
;  $endif			   ;AN000;K
$$IF70:
;			     Done: ;AN000;M
   pop	si			   ;AN000;M
   pop	di			   ;AN000;M
   mov	sp,bp			   ;AN000;M
   pop	bp			   ;AN000;M
   ret				   ;AN000;M Bye,bye
Display_Msg ENDP		   ;AN000;M

   HEADER <SETUP_TOOMANY - "Too many files open">
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_TOOMANY
Setup_TooMany PROC NEAR 	   ;AN000;M
   mov	ax,4			   ;AN000;M Utility's message number
   mov	bx,STDERR		   ;AN000;M Error msg, so stderr
   mov	cx,0			   ;AN000;M Substitution count
   mov	dl,NO_INPUT		   ;AN000;M No input characters
   mov	dh,EXT_ERR_CLASS	   ;AN000;M DOS Extended error class
   ret				   ;AN000;M Now display the message
Setup_TooMany ENDP		   ;AN000;M

   HEADER <SETUP_NOROOM - "Cannot make directory entry">
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_NOROOM
Setup_NoRoom PROC NEAR		   ;AN000;M
   mov	ax,82			   ;AN000;M Utility's message number
   mov	bx,STDERR		   ;AN000;M Error msg, so stderr
   mov	cx,0			   ;AN000;M Substitution count
   mov	dl,NO_INPUT		   ;AN000;M No input characters
   mov	dh,EXT_ERR_CLASS	   ;AN000;M DOS Extended error class
   ret				   ;AN000;M
Setup_NoRoom ENDP

   HEADER <SETUP_INVCHAR - "Invalid characters in volume label">
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_INVCHAR
Setup_InvChar PROC NEAR 	   ;AN000;M
   mov	ax,3			   ;AN000;M Utility's message number
   mov	bx,STDERR		   ;AN000;M Error msg, so stderr
   mov	cx,0			   ;AN000;M Substitution count
   mov	dl,NO_INPUT		   ;AN000;M No input characters
   mov	dh,UTILITY_MSG_CLASS	   ;AN000;M Utility message class
   ret				   ;AN000;M
Setup_InvChar ENDP		   ;AN000;M

   HEADER <SETUP_NEWLABEL - "Volume label (11 characters, ENTER for none)?">
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_NEWLABEL
Setup_NewLabel PROC NEAR	   ;AN000;M
   mov	ax,6			   ;AN000;M Utility's message number
   mov	bx,STDOUT		   ;AN000;M Info msg, so stdout
   mov	cx,0			   ;AN000;M Substitution count
   mov	dl,NO_INPUT		   ;AN000;M No input characters
   mov	dh,UTILITY_MSG_CLASS	   ;AN000;M Utility message class
   ret				   ;AN000;M
Setup_NewLabel ENDP		   ;AN000;M

   HEADER <SETUP_INVDRIVE - "Invalid drive specification">
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_INVDRIVE
Setup_InvDrive PROC NEAR	   ;AN000;M
   mov	s1_offset,offset FCB_Drive_Char ;AN000;M
   mov	s1_segment,ds		   ;AN000;M Setup segment
   mov	s1_flags,CHAR_FIELD_CHAR   ;AN000;M Set up the parm formatting
   mov	s1_maxwidth,MAXWIDTH	   ;AN000;M 0 ensures no padding
   mov	s1_minwidth,MINWIDTH	   ;AN000;M At least 1 char to insert
   mov	s1_padchar,BLANK	   ;AN000;M In case, pad with blanks
   mov	ax,15			   ;AN000;M Utility's message number
   mov	bx,STDERR		   ;AN000;M Error msg, so stderr
   lea	si,sublist1		   ;AN000;M Display invalid drive
   mov	cx,0			   ;AN000;M Substitution count
   mov	dl,NO_INPUT		   ;AN000;M No input characters
   mov	dh,EXT_ERR_CLASS	   ;AN000;M DOS Extended error class
   ret				   ;AN000;M
Setup_InvDrive ENDP		   ;AN000;M

   HEADER <SETUP_NETDRIVE - "Cannot %1 a Network drive">
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_NETDRIVE
Setup_NetDrive PROC NEAR	   ;AN000;M
   mov	s1_offset,offset Label_Word ;AN000;M Cannot LABEL a network...
   mov	s1_segment,ds		   ;AN000;M Setup segment
   mov	s1_flags,STR_INPUT	   ;AN000;M Set up the parm formatting
   mov	s1_maxwidth,MAXWIDTH	   ;AN000;M 0 ensures no padding
   mov	s1_minwidth,MINWIDTH	   ;AN000;M At least 1 char to insert
   mov	s1_padchar,BLANK	   ;AN000;M In case, pad with blanks
   mov	ax,8			   ;AN000;M Utility's message number
   mov	bx,STDERR		   ;AN000;M Error msg, so stderr
   lea	si,sublist1		   ;AN000;M Display network drive msg
   mov	cx,1			   ;AN000;M Substitution count
   mov	dl,NO_INPUT		   ;AN000;M No input characters
   mov	dh,UTILITY_MSG_CLASS	   ;AN000;M Utility message class
   ret				   ;AN000;M
Setup_NetDrive ENDP		   ;AN000;M

   HEADER <SETUP_SUBSTASGN - "Cannot %1 a SUBSTed or ASSIGNed drive">
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_SUBSTASGN
Setup_SubstAsgn PROC NEAR	   ;AN000;M
   mov	s1_offset,offset Label_Word ;AN000;M Cannot LABEL a SUBSTed...
   mov	s1_segment,ds		   ;AN000;M Setup segment
   mov	s1_flags,STR_INPUT	   ;AN000;M Set up the parm formatting
   mov	s1_maxwidth,MAXWIDTH	   ;AN000;M 0 ensures no padding
   mov	s1_minwidth,MINWIDTH	   ;AN000;M At least 1 char to insert
   mov	s1_padchar,BLANK	   ;AN000;M In case, pad with blanks
   mov	ax,2			   ;AN000;M Utility's message number
   mov	bx,STDERR		   ;AN000;M Error msg, so stderr
   lea	si,sublist1		   ;AN000;M Display SUBST/ASSIGN drive ,dh
   mov	cx,1			   ;AN000;M Substitution count
   mov	dl,NO_INPUT		   ;AN000;M No input characters
   mov	dh,UTILITY_MSG_CLASS	   ;AN000;M Utility message class
   ret				   ;AN000;M
Setup_SubstAsgn ENDP		   ;AN000;M

   HEADER <SETUP_NOLABEL - "Volume in drive %1 has no label">
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_NOLABEL
Setup_NoLabel PROC NEAR 	   ;AN000;M
   mov	s1_offset,offset FCB_Drive_Char ;AN000;M
   mov	s1_segment,ds		   ;AN000;M Setup segment
   mov	s1_flags,CHAR_FIELD_CHAR   ;AN000;M Set up the parm formatting
   mov	s1_maxwidth,MAXWIDTH	   ;AN000;M 0 ensures no padding
   mov	s1_minwidth,MINWIDTH	   ;AN000;M At least 1 char to insert
   mov	s1_padchar,BLANK	   ;AN000;M In case, pad with blanks
   mov	ax,4			   ;AN000;M Utility's message number
   mov	bx,STDOUT		   ;AN000;M Info msg, so stdout
   lea	si,sublist1		   ;AN000;M Display drive
   mov	cx,1			   ;AN000;M Substitution count
   mov	dl,NO_INPUT		   ;AN000;M No input characters
   mov	dh,UTILITY_MSG_CLASS	   ;AN000;M Utility message class
   ret				   ;AN000;M
Setup_NoLabel ENDP		   ;AN000;M

   HEADER <SETUP_SERIALNUM - "Volume Serial Number is %1-%2">
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_SERIALNUM
Setup_SerialNum PROC NEAR	   ;AN000;M
   mov	s1_offset,offset SerNum+2  ;AN000;M
   mov	s1_segment,ds		   ;AN000;M Setup segment
   mov	s1_flags,BIN_HEX_WORD+RIGHT_ALIGN ;AN000;M Set up the parm formatting
   mov	s1_maxwidth,DWORD	   ;AN000;M 0 ensures no padding
   mov	s1_minwidth,DWORD	   ;AN000;M At least 1 char to insert
   mov	s1_padchar,CHAR_ZERO	   ;AN000;M In case, pad with ZERO CHAR
   mov	s2_offset,offset SerNum    ;AN000;M
   mov	s2_segment,ds		   ;AN000;M Setup segment
   mov	s2_flags,BIN_HEX_WORD+RIGHT_ALIGN ;AN000;M Set up the parm formatting
   mov	s2_maxwidth,DWORD	   ;AN000;M 0 ensures no padding
   mov	s2_minwidth,DWORD	   ;AN000;M At least 1 char to insert
   mov	s2_padchar,CHAR_ZERO	   ;AN000;M In case, pad with ZERO CHAR
   mov	ax,7			   ;AN000;M Utility's message number
   mov	bx,STDOUT		   ;AN000;M Info msg, so stdout
   lea	si,sublist1		   ;AN000;M Display serial number
   mov	cx,2			   ;AN000;M Substitution count
   mov	dl,NO_INPUT		   ;AN000;M No input characters
   mov	dh,UTILITY_MSG_CLASS	   ;AN000;M Utility message class
   ret				   ;AN000;M
Setup_SerialNum ENDP		   ;AN000;M

   HEADER <SETUP_HASLABEL - "Volume in drive %1 is %2">
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_HASLABEL
Setup_HasLabel PROC NEAR	   ;AN000;M
   mov	s1_offset,offset FCB_Drive_Char ;AN000;M
   mov	s1_segment,ds		   ;AN000;M Setup segment
   mov	s1_flags,CHAR_FIELD_CHAR   ;AN000;M Set up the parm formatting
   mov	s1_maxwidth,MAXWIDTH	   ;AN000;M 0 ensures no padding
   mov	s1_minwidth,MINWIDTH	   ;AN000;M At least 1 char to insert
   mov	s1_padchar,BLANK	   ;AN000;M In case, pad with blanks
   mov	s2_offset,offset Label_Name ;AN000;M
   mov	s2_segment,ds		   ;AN000;M Setup segment
   mov	s2_flags,STR_INPUT	   ;AN000;M Set up the parm formatting
   mov	s2_maxwidth,MAXWIDTH	   ;AN000;M 0 ensures no padding
   mov	s2_minwidth,MINWIDTH	   ;AN000;M At least 1 char to insert
   mov	s2_padchar,BLANK	   ;AN000;M In case, pad with blanks
   mov	ax,5			   ;AN000;M Utility's message number
   mov	bx,STDOUT		   ;AN000;M Info msg, so stdout
   lea	si,sublist1		   ;AN000;M Display drive then label
   mov	cx,2			   ;AN000;M Substitution count
   mov	dl,NO_INPUT		   ;AN000;M No input characters
   mov	dh,UTILITY_MSG_CLASS	   ;AN000;M Utility message class
   ret				   ;AN000;M
Setup_HasLabel ENDP		   ;AN000;M

   HEADER <SETUP_DELLABEL - "Delete current volume label (Y/N)?">
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_DELLABEL
Setup_DelLabel PROC NEAR	   ;AN001;M
   mov	ax,9			   ;AN001;M Utility's message number
   mov	bx,STDOUT		   ;AN001;M Info msg, so stdout
   mov	cx,0			   ;AN001;M Substitution count
   mov	dl,DOS_CON_INPUT	   ;AN001;M Input Y/N character
   mov	dh,UTILITY_MSG_CLASS	   ;AN001;M Utility message class
   ret				   ;AN001;M
Setup_DelLabel ENDP		   ;AN001;M

   HEADER <SETUP_CRLF - Carriage return, line feed>
;*****************************************************************************
;  Setup for utility messages
;*****************************************************************************
;  Input:  None
;  Output: None

   PUBLIC SETUP_CRLF
Setup_CRLF PROC NEAR		   ;AN001;M
   mov	ax,10			   ;AN001;M Utility's message number
   mov	bx,STDOUT		   ;AN001;M Info msg, so stdout
   mov	cx,0			   ;AN001;M Substitution count
   mov	dl,NO_INPUT		   ;AN001;M Input Y/N character
   mov	dh,UTILITY_MSG_CLASS	   ;AN001;M No input characters
   ret				   ;AN001;M
Setup_CRLF ENDP 		   ;AN001;M

   HEADER <ERROR_EXIT - ABNORMAL RETURN TO DOS>
;*****************************************************************************
;  Error on exit
;*****************************************************************************

   PUBLIC ERROR_EXIT
Error_Exit PROC NEAR		   ;AC000;M
   mov	ax,(EXIT SHL 8)+ERRORLEVEL_1 ;AN000;K Terminate, with ret code
   INT	21H
Error_Exit ENDP 		   ;AN000;M

End_Of_Program label byte
   Public End_Of_Program

CSEG ends
   end	Start
