;fsexec  equ	 true			     ;				     ;	 ;an038;bgb  ;
FCB	EQU	5CH

String_Done equ 0
No_Error equ	0
chk_Error   equ     1
Stderr	equ	2

FALSE	EQU	0
TRUE	EQU	NOT FALSE

; NOTE WARNING DANGER.
; THIS EQU DEFINES AN OFFSET INTO THE SEARCH FCB OF THE LASTENT VALUE.
; ITS LOCATION MAY CHANGE FROM DOS VERSION TO DOS VERSION.
;2.0/2.1 value
;THISENT EQU	 17H			 ;Relative entry number of current entry
;3.0 value
THISENT EQU	14H				;Relative entry number of current entry


;Attribute bits

RDONLY	EQU	1
HIDDN	EQU	2
SYSTM	EQU	4
VOLIDA	EQU	8
ISDIR	EQU	10H
DRVCHAR EQU	":"
;
;*****************************************************************************
; Equates
;*****************************************************************************
;

Multiplex equ	2Fh				;				;AN000;
Set_Append_X equ 0B707h 			;				;AN000;;
Append_X equ	0B706h				;				;AN000;;
Append_X_Set equ 1				;				;AN000;
Append_Off equ	0				;				;AN000;
Append_ON equ	1				;				;AN000;


Disk_Error	equ	80h			;INT 24h bit clear if disk error;AN000;

NO	equ	0								;AN000;
YES	equ	not NO								;AN000;

Year_Mask	equ	0FE00h
Month_Mask	equ	01E0h
Day_Mask	equ	001Fh
Hour_Mask	equ	0F800h
Minute_Mask	equ	07E0h

Not_Include	equ	0
Do_Include	equ	1


YES_Found equ	1
NO_Found equ	0

ON	equ	1
OFF	equ	0

No_Ext_Attrib	equ	0							;AN000;
No_Entry	equ	0
XA_Chain	equ	84h			;Mark head of XA chain		;AN000;

ifdef	fsexec									;an038;bgb
Len_FS_String_Buffer	equ	13						;an038;bgb
FAT12_File_System equ 01h							;an038;bgb;AN000;
FAT16_File_System equ 04h							;an038;bgb;AN000;
New_File_System equ 06h 							;an038;bgb;AN000;
endif

Bad_Exit	equ	0FFh			;Errorlevel = 0FFh		;AN000;

Net_Check equ	1200h								;AN000;
Assign_Check equ 8000h								;AN000;

Found_Yes equ	1								;AN000;
Found_No equ	0								;AN000;

Asciiz_End equ	0								;AN000;

Dir_Attribute	equ	10h
Vol_Attribute	equ	08h

Dir_Entries_Per_Sector	equ	512/32


Critical_Error_Fail	equ	3
Write_Protect	equ	0
Drive_Not_Ready equ	2

Blank	equ	" "                                                             ;AN000;

Head_Mask	equ	7Fh			;Mask to turn off head bit	;AN000;


;Limits
BIG_FAT_THRESHOLD equ 4086							;AN000;



;-------------------------------------------------------------------------------
; These are the data structures which we will need
;****************************************************************************
; Structures
;****************************************************************************
ifdef	fsexec									;an038;bgb
Exec_Block_Parms struc								;an038;bgb
Segment_Env dw	0								;an038;bgb
Offset_Command dw 0								;an038;bgb
Segment_Command dw 0								;an038;bgb
Offset_FCB1 dw	0								;an038;bgb
Segment_FCB1 dw 0								;an038;bgb
Offset_FCB2 dw	0								;an038;bgb
Segment_FCB2 dw 0								;an038;bgb
Exec_Block_Parms ends								;an038;bgb

Media_ID struc									;AN000;
Media_ID_Info_Level dw 0							;AN000;
Media_ID_Serial_Number dd 0							;AN000;
Media_ID_Volume_Label db 11 dup(" ")                                            ;AN000;
Media_ID_File_System db 8  dup(" ")                                             ;AN000;
Media_ID ends									;AN000;
endif										;an038;bgb

Sublist_Struc struc
Sublist_Size	db	?			;				;AN000;
Sublist_Rsv	db	?			;				;AN000;
Sublist_Offset	dw	?			;				;AN000;
Sublist_Segment dw	?			;				;AN000;
Sublist_Number	db	?			;				;AN000;
Sublist_Type	db	?			;				;AN000;
Sublist_Max	db	?			;				;AN000;
Sublist_Min	db	?			;				;AN000;
Sublist_Char	db	?			;				;AN000;
Sublist_Struc ends

A_DeviceParameters	struc

SpecialFunctions	db	?    ;1  0
DeviceType		db	?    ;1  1
DeviceAttributes	dw	?    ;2  2
NumberOfCylinders	dw	?    ;2  4
MediaType		db	?    ;1  6
BytePerSector		dw	?    ;2  7
SectorsPerCluster	db	?    ;
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
ReservedArea		db	6 dup(?)

A_DeviceParameters	ends




Relative_Sector_Buffer	struc			;				;AN000;

Start_Sector_Low	dw	?		;Low word of RBA sector 	;AN000;
Start_Sector_High	dw	?		;High word of RBA sector	;AN000;
Number_Sectors		dw	?		;Number of sectors		;AN000;
Buffer_Offset		dw	?		;Address of data buffer 	;AN000;
Buffer_Segment		dw	?		;				;AN000;

Relative_Sector_Buffer ends			;				;AN000;


XAL	struc									;AN000;

XAL_Tsize	dw	?							;AN000;
XAL_TCount	dw	?							;AN000;
XAL_LSize	dw	?							;AN000;
XAL_LCount	dw	?							;AN000;
XAL_Data	db	512-8 dup(?)						;AN000;

XAL	ends									;AN000;

DIRENT	STRUC
	DB	7 DUP (?)		;Ext FCB junk
	DB	?			;Drive
DIRNAM	DB	11 DUP (?)			;
DIRATT	DB	?				;
DIRCP	DW	?				;				;AN000;
DIR_XA	DW	?				;				;AN000;
DIRATT2 db	?				;				;AN000;
DIRRES	DB	5 DUP (?)			;				;AC000;
DIRTIM	DW	?				;
DIRDAT	DW	?				;
DIRCLUS DW	?				;
DIRESIZ DD	?				;
DIRENT	ENDS					;
ENTSIZ	EQU	SIZE DIRENT

;-------------------------------------------------------------------------------

