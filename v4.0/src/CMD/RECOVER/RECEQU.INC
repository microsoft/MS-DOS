;fsexec equ true
const	segment public para 'const'     ;AC000;bgb
Len_FS_ID_String equ 8			; length of fat_12 and fat_16 strings ;AN000;bgb
Command_Line_Length equ 128		; length of command line area  ;AN000;bgb
Len_FS_String_End equ 8 		; length of rec.exe + 0H   ;AN000;bgb
FALSE	EQU	0
;TRUE	 EQU	 -1

bdos	equ	21h
boot	equ	20h
aread	equ	25h
awrite	equ	26h


;IBMVER	EQU	false ; not for single drive system ;AC000;bgb
;KANJI	EQU	true  ; set this to true for assembling jap version ;AC000;bgb
tab	equ	09h
aread	equ	25h
awrite	equ	26h
fcb	equ	5ch
FCB1	equ	5Ch
FCB2	equ	6Ch
FCB_Filename_Length	equ	11

NO			equ	0						;AN000;
YES			equ	not NO						;AN000;


Not_Include		equ	0
Do_Include		equ	1

No_Ext_Attrib		equ	0						;AN000;
No_Entry		equ	0


FAT12_File_System	equ 01h 						;AN000;
FAT16_File_System	equ 04h 						;AN000;
New_File_System 	equ 06h 						;AN000;

Bad_Exit		equ	0FFh			;Errorlevel = 0FFh	;AN000;

Net_Check		equ   1200h						;AN000;
Assign_Check		equ 8000h						;AN000;

DBCS_Lead		equ	81h
DBCS_Blank		equ  40h
DBCS_Vector_Size	equ 2
End_Of_Vector		equ 0
Blank			equ	" "                                             ;AN000;

Found_Yes		equ   1 						;AN000;
Found_No		equ    0						;AN000;

Asciiz_End		equ  0							;AN000;

Dir_Attribute		equ	10h
Vol_Attribute		equ	08h

Dir_Entries_Per_Sector	equ	512/32


Critical_Error_Fail	equ	3
Write_Protect		equ	0
Drive_Not_Ready 	equ	2


Len_FS_String_Buffer	equ	13

;Limits
BIG_FAT_THRESHOLD	equ 4086						;AN000;

; equates from recinit
;***********************************************
Multiplex		equ   2Fh			      ; 		;AN000;
Set_Append_X		equ 0B707h			   ;			;AN000;;
Append_X		equ    0B706h			       ;		;AN000;;
Append_X_Set		equ 1				   ;			;AN000;
Append_Off		equ  0				     ;			;AN000;
Append_ON		equ   1 			      ; 		;AN000;
fcb1			equ	05ch		;				;AN000;bgb

String_Done equ 0
No_Error equ	0
rec_error   equ     1
Stderr	equ	2
Len_FS_String_Buffer equ 13



;-------------------------------------------------------------------------------
; DATA STRUCTURES
;-------------------------------------------------------------------------------

Exec_Block_Parms struc
Segment_Env	dw  0
Offset_Command	dw  0
Segment_Command dw  0
Offset_FCB1	dw  0
Segment_FCB1	dw  0
Offset_FCB2	dw  0
Segment_FCB2	dw  0

Exec_Block_Parms ends



;-------------------------------------------------------------------------------
; media id
;-------------------------------------------------------------------------------
Media_ID struc									;AN000;
Media_ID_Info_Level dw 0							;AN000;
Media_ID_Serial_Number dd 0							;AN000;
Media_ID_Volume_Label db 11 dup(" ")                                            ;AN000;
Media_ID_File_System db 8  dup(" ")                                             ;AN000;
Media_ID ends									;AN000;

;-------------------------------------------------------------------------------
; device parameters
;-------------------------------------------------------------------------------
A_DeviceParameters	struc

SpecialFunctions	db	?
DeviceType		db	?
DeviceAttributes	dw	?
NumberOfCylinders	dw	?
MediaType		db	?
BytePerSector		dw	?
SectorsPerCluster	db	?
ReservedSectors 	dw	?
NumberOfFATs		db	?
RootEntries		dw	?
TotalSectors		dw	?
MediaDescriptor 	db	?
SectorsPerFAT		dw	?
SectorsPerTrack 	dw	?
Heads			dw	?
HiddenSectors		dd	?
Ext_Total_Sectors	dd	?
Reserved_Area		db	6 dup(?)

A_DeviceParameters	ends




;-------------------------------------------------------------------------------
; relative sector buffer
;-------------------------------------------------------------------------------
Relative_Sector_Buffer	struc			;				;AN000;

Start_Sector_Low	dw	?		;Low word of RBA sector 	;AN000;
Start_Sector_High	dw	?		;High word of RBA sector	;AN000;
Number_Sectors		dw	?		;Number of sectors		;AN000;
Buffer_Offset		dw	?		;Address of data buffer 	;AN000;
Buffer_Segment		dw	?		;				;AN000;

Relative_Sector_Buffer ends			;				;AN000;


;-------------------------------------------------------------------------------
; xal ????
;-------------------------------------------------------------------------------
XAL	struc									;AN000;

XAL_Tsize	dw	?							;AN000;
XAL_TCount	dw	?							;AN000;
XAL_LSize	dw	?							;AN000;
XAL_LCount	dw	?							;AN000;
XAL_Data	db	512-8 dup(?)						;AN000;

XAL	ends									;AN000;

;-------------------------------------------------------------------------------
const	ends
