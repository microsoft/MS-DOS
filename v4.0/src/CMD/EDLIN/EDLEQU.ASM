	page	60,132			;

	.xlist
	include DOSSYM.INC
	include EDLSTDSW.INC
	.list

;======================= START OF SPECIFICATIONS =========================
;
; MODULE NAME: EDLEQU.SAL
;
; DESCRIPTIVE NAME: EQUATES FOR EDLIN
;
; FUNCTION: PROVIDES EQUATES FOR EDLIN.  IT ALSO PROVIDES THE MACRO
;	    VAL_YN.
;
; ENTRY POINT: NA
;
; INPUT: NA
;
; EXIT NORMAL: NA
;
; EXIT ERROR: NA
;
; INTERNAL REFERENCES:
;
;	ROUTINE: VAL_YN - VALIDATES Y/N RESPONSES FROM THE KEYBOARD
;
; EXTERNAL REFERENCES:
;
;	ROUTINE: NA
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK EDLIN+EDLCMD1+EDLCMD2+EDLMES+EDLPARSE
;
; REVISION HISTORY:
;
;	AN000	VERSION 4.00 - REVISIONS MADE RELATE TO THE FOLLOWING:
;
;				- IMPLEMENT SYSPARSE
;				- IMPLEMENT MESSAGE RETRIEVER
;				- IMPLEMENT DBCS ENABLING
;				- ENHANCED VIDEO SUPPORT
;				- EXTENDED OPENS
;				- SCROLLING ERROR
;
; COPYRIGHT: "MS DOS EDLIN UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988 Microsoft"
;
;======================= END OF SPECIFICATIONS ===========================






COMAND_LINE_LENGTH EQU 128
QUOTE_CHAR EQU	16H			;Quote character = ^V
CR	EQU	13
STKSIZ	EQU	200h
STACK	equ	stksiz

asian_blk equ	40h			;an000;asian blank 2nd. byte
dbcs_lead_byte equ 81h			;an000;asian blank lead byte
nul	equ	00h			;an000;nul character
Access_Denied equ 0005h 		;an000;extended error code for access denied

;======== Y/N validation equates =========================================

yn_chk	equ	23h			;an000;check for Y/N response
max_len equ	01h			;an000;max. len. for Y/N char.
yes	equ	01h			;an000;boolean yes value
no	equ	00h			;an000;boolean no value

;======== text display values for initialization =========================

video_get equ	0fh			;an000;int 10 get video attributes
video_set equ	00h			;an000;int 10 set video attributes
video_text equ	03h			;an000;80 X 25 color monitor

;======== code page values for functions =================================

get_set_cp equ	66h			;an000;get or set code page
get_cp	equ	01h			;an000;get active code page
set_cp	equ	02h			;an000;set active code page

;======== screen length & width defaults =================================

std_out equ	01h			;an000;console output
display_attr equ 03h			;an000;display for IOCTL
Get_Display equ 7fh			;an000;Get display for IOCTL
Def_Disp_Len equ 25			;an000;default display length
Def_Disp_Width equ 80			;an000;default display width

;======== extended open equates ==========================================

rw	equ	0082h			;an000;read/write
					;      compatibility
					;      noinherit
					;      int 24h handler
					;      no commit

ext_read equ	0080h			;an000;read
					;      compatibility
					;      noinherit
					;      int 24h handler
					;      no commit

rw_flag equ	0101h			;an000;fail if file not exist
					;      open if file exists
					;      don't validate code page

creat_flag equ	0110h			;an000;create if file does not exist
					;      fail if file exists
					;      don't validate code page

open_flag equ	0101h			;an000;fail if file not exist
					;      open if file exists
					;      don't validate code page

creat_open_flag equ 0112h		;an000;create if file does not exist
					;      open/replace if file exists
					;      don't validate code page

attr	equ	00h			;an000;attributes set to 0

;======== parse value equates ============================================

nrm_parse_exit equ 0ffffh		;an000;normal exit from sysparse
too_many equ	01h			;an000;too many parms entered
op_missing equ	02h			;an000;required operand missing
sw_missing equ	03h			;an000;not a valid switch


;======== Strucs =========================================================

Display_Buffer_Struc Struc		;an000;dms;

	Display_Info_Level db	   ?	;an000;dms;
	Display_Reserved db	 ?	;an000;dms;
	Display_Buffer_Size dw	    ?	;an000;dms;
	Display_Flags dw      ? 	;an000;dms;
	Display_Mode db      ?		;an000;dms;
					;  TEXT=01
					;  APA =02
	Display_Mode_Reserved db      ? ;an000;dms;
	Display_Colors dw      ?	;an000;dms;# of colors
	Display_Width_Pixels dw      ?	;an000;dms;# of pixels in width
	Display_Length_Pixels dw      ? ;an000;dms;# of pixels in len.
	Display_Width_Char dw	   ?	;an000;dms;# of chars in width
	Display_Length_Char dw	    ?	;an000;dms;# of chars in length

Display_Buffer_Struc ends		;an000;dms;


