
;****************************************************
;* TRANSIENT MESSAGE POINTERS & SUBSTITUTION BLOCKS *
;****************************************************

msg_disp_class	db	Util_msg_class
msg_cont_flag	db	No_cont_flag

;  extended error string output
;
Extend_Buf_ptr	dw	0				;AN000;set to no message
Extend_Buf_sub	db	0				;AN000;set to no substitutions
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
Extend_Buf_off	dw	OFFSET	TranGroup:String_ptr_2	;AN000;offset of arg
Extend_Buf_seg	dw	0				;AN000;segment of arg
		db	0				;AN000;first subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	128				;AN000;maximum width
		db	0				;AN000;minimum width
		db	blank				;AN000;pad character

;  "Duplicate file name or file not found"
;
Renerr_Ptr	dw	1002				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Invalid path or file name"
;
BadCPMes_Ptr	dw	1003				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Insufficient disk space"
;
NoSpace_Ptr	dw	1004				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Out of environment space"
;
EnvErr_Ptr	dw	1007				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "File creation error"
;
FulDir_Ptr	dw	1008				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Batch file missing",13,10
;
BadBat_Ptr	dw	1009				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Insert disk with batch file",13,10
;
NeedBat_Ptr	dw	1010				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Bad command or file name",13,10
;
BadNam_Ptr	dw	1011				;AN000;message number
		db	no_subst			;AN000;number of subst


;  "Access denied",13,10
;
AccDen_Ptr	dw	1014				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "File cannot be copied onto itself",13,10
;
OverWr_Ptr	dw	1015				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Content of destination lost before copy",13,10
;
LostErr_Ptr	dw	1016				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Invalid filename or file not found",13,10
;
InOrNot_Ptr	dw	1017				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "%1 File(s) copied",13,10
;
Copied_Ptr	dw	1018				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:Copy_num	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Right_Align+Unsgn_Bin_Word	;AN000;binary to decimal
		db	9				;AN000;maximum width
		db	9				;AN000;minimum width
		db	blank				;AN000;pad character

;  "%1 File(s) "
;
DirMes_Ptr	dw	1019				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:Dir_num	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Right_Align+Unsgn_Bin_Word	;AN000;binary to decimal
		db	9				;AN000;maximum width
		db	9				;AN000;minimum width
		db	blank				;AN000;pad character

;  "%1 bytes free",13,10
;
BytMes_Ptr	dw	1020				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:Bytes_Free	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Right_Align+Unsgn_Bin_DWord	;AN000;long binary to decimal
		db	10				;AN000;maximum width
		db	10				;AN000;minimum width
		db	blank				;AN000;pad character

;  "Invalid drive specification",13,10
;
BadDrv_Ptr	dw	1021				;AN000;message number
		db	no_subst			;AN000;number of subst


;  "Code page %1 not prepared for system",13,10
;
CP_not_set_Ptr	dw	1022				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:System_cpage	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Right_Align+Unsgn_Bin_Word	;AN000;binary to decimal
		db	5				;AN000;maximum width
		db	1				;AN000;minimum width
		db	blank				;AN000;pad character

;  "Code page %1 not prepared for all devices",13,10
;
CP_not_all_Ptr	dw	1023				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:System_cpage	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Right_Align+Unsgn_Bin_Word	;AN000;binary to decimal
		db	5				;AN000;maximum width
		db	1				;AN000;minimum width
		db	blank				;AN000;pad character

;  "Active code page: %1",13,10
;
CP_active_Ptr	dw	1024				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:System_cpage	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Right_Align+Unsgn_Bin_Word	;AN000;binary to decimal
		db	5				;AN000;maximum width
		db	1				;AN000;minimum width
		db	blank				;AN000;pad character

;  "NLSFUNC not installed",13,10
;
NLSFUNC_Ptr	dw	1025				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Invalid code page",13,10
;
Inv_Code_Page	dw	1026				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Current drive is no longer valid"
;
BadCurDrv	dw	1027				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Press any key to continue"
;
PauseMes_Ptr	dw	1028				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Label not found",13,10
;
BadLab_Ptr	dw	1029				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Syntax error",13,10
;
SyntMes_Ptr	dw	1030				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Invalid date",13,10
;
BadDat_Ptr	dw	1031				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Current date is %1 %2",13,10
;
CurDat_Ptr	dw	1032				;AN000;message number
		db	2				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:Arg_Buf	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	3				;AN000;maximum width
		db	3				;AN000;minimum width
		db	blank				;AN000;pad character
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
CurDat_yr	dw	0				;AN000;year
CurDat_mo_day	dw	0				;AN000;month,day
		db	2				;AN000;second subst
		db	DATE_MDY_4			;AN000;date
		db	10				;AN000;maximum width
		db	10				;AN000;minimum width
		db	blank				;AN000;pad character


;  "SunMonTueWedThuFriSat"
;
WeekTab 	dw	1033				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Enter new date (%1):"
;
NewDat_Ptr	dw	1034				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
NewDat_Format	dw	0				;AN000;offset of replacement
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	8				;AN000;maximum width
		db	8				;AN000;minimum width
		db	blank				;AN000;pad character

;  "Invalid time",13,10
;
BadTim_Ptr	dw	1035				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Current time is %1",13,10
;
CurTim_Ptr	dw	1036				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
CurTim_hr_min	dw	0				;AN000;hours,minutes
CurTim_Sec_hn	dw	0				;AN000;seconds,hundredths
		db	1				;AN000;first subst
		db	Right_Align+TIME_HHMMSSHH_Cty	;AC059;time
		db	12				;AC059;maximum width
		db	12				;AC059;minimum width
		db	blank				;AN000;pad character

;  "Enter new time:"
;
NewTim_Ptr	dw	1037				;AN000;message number
		db	no_subst			;AN000;number of subst

;  ",    Delete (Y/N)?",13,10
;
Del_Y_N_Ptr	dw	1038				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "All files in directory will be deleted!",13,10
;  "Are you sure (Y/N)?",13,10
;
SureMes_Ptr	dw	1039				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Microsoft DOS Version %1.%2",13,10
;
VerMes_Ptr	dw	1040				;AN000;message number
		db	2				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:Major_Ver_Num ;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Right_Align+Unsgn_Bin_Word	;AN000;binary to decimal
		db	1				;AN000;maximum width
		db	1				;AN000;minimum width
		db	blank				;AN000;pad character
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:Minor_Ver_Num ;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	2				;AN000;second subst
		db	Unsgn_Bin_Word			;AN000;binary to decimal
		db	2				;AN000;maximum width
		db	2				;AN000;minimum width
		db	"0"                             ;AN000;pad character

;  "Volume in drive %1 has no label",13,10
;
VolMes_Ptr_2	dw	1041				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:vol_drv	;AN000;offset of drive
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Char_field_Char 		;AN000;character
		db	128				;AN000;maximum width
		db	1				;AN000;minimum width
		db	blank				;AN000;pad character

;  "Volume in drive %1 is %2",13,10
;
VolMes_Ptr	dw	1042				;AN000;message number
		db	2				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:vol_drv	;AN000;offset of drive
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	00000000b			;AN000;character
		db	128				;AN000;maximum width
		db	1				;AN000;minimum width
		db	blank				;AN000;pad character
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:CHARBUF	;AN000;offset of string
		dw	0				;AN000;segment of arg
		db	2				;AN000;second subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	128				;AN000;maximum width
		db	1				;AN000;minimum width
		db	blank				;AN000;pad character

;  "Volume Serial Number is %1-%2",13,10
;
VolSerMes_Ptr	dw	1043				;AN000;message number
		db	2				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:vol_serial+2	;AN000;offset of serial
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Right_Align+Bin_Hex_Word	;AN000;binary to hex
		db	4				;AN000;maximum width
		db	4				;AN000;minimum width
		db	"0"                             ;AN000;pad character
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:vol_serial	;AN000;offset of serial
		dw	0				;AN000;segment of arg
		db	2				;AN000;second subst
		db	Right_Align+Bin_Hex_Word	;AN000;binary to hex
		db	4				;AN000;maximum width
		db	4				;AN000;minimum width
		db	"0"                             ;AN000;pad character

;  "Invalid directory",13,10
;
BadCD_Ptr	dw	1044				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Unable to create directory",13,10
;
BadMkD_Ptr	dw	1045				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Invalid path, not directory,",13,10
;  "or directory not empty",13,10
;
BadRmD_Ptr	dw	1046				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Must specify ON or OFF",13,10
;
Bad_ON_OFF_Ptr	dw	1047				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Directory of  %1",13,10
;
DirHead_Ptr	dw	1048				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:BWDBUF	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	128				;AN000;maximum width
		db	0				;AN000;minimum width
		db	blank				;AN000;pad character

;  "No Path",13,10
;
NulPath_Ptr	dw	1049				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Invalid drive in search path",13,10
;
BadPMes_Ptr	dw	1050				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Invalid device",13,10
;
BadDev_Ptr	dw	1051				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "FOR cannot be nested",13,10
;
ForNestMes_Ptr	dw	1052				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Intermediate file error during pipe",13,10
;
PipeEMes_Ptr	dw	1053				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Cannot do binary reads from a device",13,10
;
InBDev_Ptr	dw	1054				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "BREAK is %1",13,10
;
CtrlcMes_Ptr	dw	1055				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	0				;AN000;offset of on/off (new)
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	128				;AN000;maximum width
		db	1				;AN000;minimum width
		db	blank				;AN000;pad character

;  "VERIFY is %1",13,10
;
VeriMes_Ptr	dw	1056				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	0				;AN000;offset of on/off (new)
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	128				;AN000;maximum width
		db	1				;AN000;minimum width
		db	blank				;AN000;pad character

;  "ECHO is %1",13,10
;
EchoMes_Ptr	dw	1057				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	0				;AN000;offset of on/off (new)
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	128				;AN000;maximum width
		db	1				;AN000;minimum width
		db	blank				;AN000;pad character

;  "off"
;
OffMes_Ptr	dw	1059				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "on"
;
OnMes_Ptr	dw	1060				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Error writing to device",13,10
;
DevWMes_Ptr	dw	1061				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "Invalid path",13,10
;
Inval_Path_Ptr	dw	1062				;AN000;message number
		db	no_subst			;AN000;number of subst

;  unformatted string output
;
arg_Buf_Ptr	dw	1063				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:Arg_Buf	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	128				;AN000;maximum width
		db	0				;AN000;minimum width
		db	blank				;AN000;pad character

;  file name output
;
File_Name_Ptr	dw	1064				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:SRCBUF	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	128				;AN000;maximum width
		db	0				;AN000;minimum width
		db	blank				;AN000;pad character

;  file size output for dir
;
Disp_File_Size_Ptr dw	1065				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:File_size_low ;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Right_Align+Unsgn_Bin_DWord	;AN000;long binary to decimal
		db	10				;AN000;maximum width
		db	10				;AN000;minimum width
		db	blank				;AN000;pad character

;  unformatted string output
; %s
String_Buf_Ptr	dw	1066				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:String_ptr_2	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	128				;AN000;maximum width
		db	0				;AN000;minimum width
		db	blank				;AN000;pad character
		db	0				;AN000;

;  tab character
;
Tab_ptr 	dw	1067				;AN000;message number
		db	no_subst			;AN000;number of subst

;  " <DIR>   "
;
DMes_Ptr	dw	1068				;AN000;message number
		db	no_subst			;AN000;number of subst

;  destructive back space
;
Dback_Ptr	dw	1069				;AN000;message number
		db	no_subst			;AN000;number of subst

;  carriage return / line feed
;
ACRLF_Ptr	dw	1070				;AN000;message number
		db	no_subst			;AN000;number of subst

;  output a single character
;
;One_Char_Buf_Ptr dw	 1071				 ;AN000;message number
;		 db	 1				 ;AN000;number of subst
;		 db	 parm_block_size		 ;AN000;size of sublist
;		 db	 0				 ;AN000;reserved
;		 dw	 OFFSET  TranGroup:One_Char_Val  ;AN000;offset of charcacter
;		 dw	 0				 ;AN000;segment of arg
;		 db	 1				 ;AN000;first subst
;		 db	 Char_field_Char		 ;AN000;character
;		 db	 1				 ;AN000;maximum width
;		 db	 1				 ;AN000;minimum width
;		 db	 blank				 ;AN000;pad character

;  "mm-dd-yy"
;
USADat_Ptr	dw	1072				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "dd-mm-yy"
;
EurDat_Ptr	dw	1073				;AN000;message number
		db	no_subst			;AN000;number of subst

;  "yy-mm-dd"
;
JapDat_Ptr	dw	1074				;AN000;message number
		db	no_subst			;AN000;number of subst

;  date string for prompt
;
promptDat_Ptr	dw	1075				;AN000;message number
		db	2				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
		dw	OFFSET	TranGroup:Arg_Buf	;AN000;offset of arg
		dw	0				;AN000;segment of arg
		db	1				;AN000;first subst
		db	Char_field_ASCIIZ		;AN000;character string
		db	3				;AN000;maximum width
		db	3				;AN000;minimum width
		db	blank				;AN000;pad character
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
promptDat_yr	dw	0				;AN000;year
promptDat_moday dw	0				;AN000;month,day
		db	2				;AN000;second subst
		db	DATE_MDY_4			;AN000;date
		db	10				;AN000;maximum width
		db	8				;AN000;minimum width
		db	blank				;AN000;pad character


;  Time for prompt
;
promTim_Ptr	dw	1076				;AN000;message number
		db	1				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
PromTim_hr_min	dw	0				;AN000;hours,minutes
PromTim_Sec_hn	dw	0				;AN000;seconds,hundredths
		db	1				;AN000;first subst
		db	Right_Align+TIME_HHMMSSHH_24	;AC013;time
		db	11				;AN000;maximum width
		db	11				;AC013;minimum width
		db	blank				;AN000;pad character

;  Date and time for DIR
;
DirDatTim_Ptr	dw	1077				;AN000;message number
		db	2				;AN000;number of subst
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
DirDat_yr	dw	0				;AN000;year
DirDat_mo_day	dw	0				;AN000;month,day
		db	1				;AN000;first subst
		db	Right_Align+DATE_MDY_2		;AN000;date
		db	10				;AN000;maximum width
		db	8				;AN000;minimum width
		db	blank				;AN000;pad character
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
DirTim_hr_min	dw	0				;AN000;hours,minutes
DirTim_Sec_hn	dw	0				;AN000;seconds,hundredths
		db	2				;AN000;second subst
		db	Right_align+TIME_HHMM_Cty	;AN000;time
		db	6				;AN000;maximum width
		db	6				;AN000;minimum width
		db	blank				;AN000;pad character

;  "Directory already exists"
;
MD_exists_ptr	dw	1078				;AN000;message number
		db	no_subst			;AN000;number of subst

PATH_TEXT    DB "PATH="
PROMPT_TEXT  DB "PROMPT="
comspecstr   db "COMSPEC="
