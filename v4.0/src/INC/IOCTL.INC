
%OUT IOCTL.INC...
; THESE ARE ALL THE IMPORTANT STRUCTURES AND EQUATES FOR IOCTL
;==============================================================================
;REVISION HISTORY:
;AN000 - New for DOS Version 4.00 - J.K.
;AC000 - Changed for DOS Version 4.00 - J.K.
;AN00x - PTM number for DOS Version 4.00 - J.K.
;==============================================================================
;AN001; D241 Provide support of Multi-track Format/Verify	   9/23/87 J.K.
;AN002; P1535 Unformatted hard file problem			  10/15/87 J.K.
;AN003; D490 IOCTL subfunction 63h,43h,64h,44h conflicts with OS2  2/26/88 J.K.
;==============================================================================

;*** J.K.
;General Guide -
;Category Code:
; 0... .... DOS Defined
; 1... .... User defined
; .xxx xxxx Code

;Function Code:
; 0... .... Return error if unsupported
; 1... .... Ignore if unsupported
; .0.. .... Intercepted by DOS
; .1.. .... Passed to driver
; ..0. .... Sends data/commands to device
; ..1. .... Quries data/info from device
; ...x .... Subfunction
;
; Note that "Sends/queries" data bit is intended only to regularize the
; function set.  It plays no critical role; some functions may contain both
; command and query elements. The convention is that such commands are
; defined as "sends data".

;*****************************;*
; BLOCK DRIVERS 	      ;*
;*****************************;*

; IOCTL SUB-FUNCTIONS
IOCTL_GET_DEVICE_INFO	EQU	0
IOCTL_SET_DEVICE_INFO	EQU	1
IOCTL_READ_HANDLE	EQU	2
IOCTL_WRITE_HANDLE	EQU	3
IOCTL_READ_DRIVE	EQU	4
IOCTL_WRITE_DRIVE	EQU	5
IOCTL_GET_INPUT_STATUS	EQU	6
IOCTL_GET_OUTPUT_STATUS EQU	7
IOCTL_CHANGEABLE?	EQU	8
IOCTL_DeviceLocOrRem?	EQU	9
IOCTL_HandleLocOrRem?	EQU	0Ah   ;10
IOCTL_SHARING_RETRY	EQU	0Bh   ;11
GENERIC_IOCTL_HANDLE	EQU	0Ch   ;12
GENERIC_IOCTL		EQU	0Dh   ;13

; GENERIC IOCTL CATEGORY CODES
IOC_OTHER		EQU	0	; Other device control J.K. 4/29/86
IOC_SE			EQU	1	; SERIAL DEVICE CONTROL
IOC_TC			EQU	2	; TERMINAL CONTROL
IOC_SC			EQU	3	; SCREEN CONTROL
IOC_KC			EQU	4	; KEYBOARD CONTROL
IOC_PC			EQU	5	; PRINTER CONTROL
IOC_DC			EQU	8	; DISK CONTROL (SAME AS RAWIO)

; GENERIC IOCTL SUB-FUNCTIONS
RAWIO			EQU	8

; RAWIO SUB-FUNCTIONS
GET_DEVICE_PARAMETERS	EQU	60H
SET_DEVICE_PARAMETERS	EQU	40H
READ_TRACK		EQU	61H
WRITE_TRACK		EQU	41H
VERIFY_TRACK		EQU	62H
FORMAT_TRACK		EQU	42H
GET_MEDIA_ID		EQU	66h		;AN000;AN003;changed from 63h
SET_MEDIA_ID		EQU	46h		;AN000;AN003;changed from 43h
GET_ACCESS_FLAG 	EQU	67h		;AN002;AN003;Unpublished function.Changed from 64h
SET_ACCESS_FLAG 	EQU	47h		;AN002;AN003;Unpublished function.Changed from 44h

; SPECIAL FUNCTION FOR GET DEVICE PARAMETERS
BUILD_DEVICE_BPB	EQU	000000001B

; SPECIAL FUNCTIONS FOR SET DEVICE PARAMETERS
INSTALL_FAKE_BPB	EQU	000000001B
ONLY_SET_TRACKLAYOUT	EQU	000000010B
TRACKLAYOUT_IS_GOOD	EQU	000000100B

; SPECIAL FUNCTION FOR FORMAT TRACK
STATUS_FOR_FORMAT		EQU	000000001B
DO_FAST_FORMAT			equ	000000010B	;AN001;
; CODES RETURNED FROM FORMAT STATUS CALL
FORMAT_NO_ROM_SUPPORT		EQU	000000001B
FORMAT_COMB_NOT_SUPPORTED	EQU	000000010B

; DEVICETYPE VALUES
MAX_SECTORS_IN_TRACK	EQU	63	; MAXIMUM SECTORS ON A DISK.(Was 40 in DOS 3.2)
DEV_5INCH		EQU	0
DEV_5INCH96TPI		EQU	1
DEV_3INCH720KB		EQU	2
DEV_8INCHSS		EQU	3
DEV_8INCHDS		EQU	4
DEV_HARDDISK		EQU	5
DEV_OTHER		EQU	7

MAX_DEV_TYPE		EQU	7	; MAXIMUM DEVICE TYPE THAT WE
					; CURRENTLY SUPPORT.

;J.K. Bug in MASM 3.  A_BPB will be defined in PASS1 and, in PASS2 the
;compiler does not include BPB.INC and it will be treated as undefined.
IF1
	BPBINPASS1 = 0
	IFNDEF A_BPB
	    INCLUDE BPB.INC
	    BPBINPASS1 = 1
	ENDIF
ELSE
	IF BPBINPASS1
	    INCLUDE BPB.INC
	ENDIF
ENDIF

A_SECTORTABLE	    STRUC
ST_SECTORNUMBER 	DW	?
ST_SECTORSIZE		DW	?
A_SECTORTABLE	    ENDS

A_DEVICEPARAMETERS  STRUC
DP_SPECIALFUNCTIONS	DB	?
DP_DEVICETYPE		DB	?
DP_DEVICEATTRIBUTES	DW	?
DP_CYLINDERS		DW	?
DP_MEDIATYPE		DB	?
DP_BPB			DB	SIZE A_BPB DUP (?)
DP_TRACKTABLEENTRIES	DW	?
DP_SECTORTABLE		DB MAX_SECTORS_IN_TRACK * SIZE A_SECTORTABLE DUP (?)
A_DEVICEPARAMETERS  ENDS

A_TRACKREADWRITEPACKET STRUC
TRWP_SPECIALFUNCTIONS	DB	?
TRWP_HEAD		DW	?
TRWP_CYLINDER		DW	?
TRWP_FIRSTSECTOR	DW	?
TRWP_SECTORSTOREADWRITE DW	?
TRWP_TRANSFERADDRESS	DD	?
A_TRACKREADWRITEPACKET ENDS

;AN001; - FP_TRACKCOUNT is only meaningful when FP_SPECIALFUNCTIONS bit 1 = 1.
A_FORMATPACKET	    STRUC
FP_SPECIALFUNCTIONS	DB	?
FP_HEAD 		DW	?
FP_CYLINDER		DW	?
FP_TRACKCOUNT		DW	1
A_FORMATPACKET	    ENDS

A_VERIFYPACKET	    STRUC
VP_SPECIALFUNCTIONS	DB	?
VP_HEAD 		DW	?
VP_CYLINDER		DW	?
A_VERIFYPACKET	    ENDS

A_MEDIA_ID_INFO     STRUC
MI_LEVEL		DW	0		;J.K. 87 Info. level
MI_SERIAL		DD	?		;J.K. 87 Serial #
MI_LABEL		DB     11 DUP (' ')     ;J.K. 87 volume label
MI_SYSTEM		DB	8 DUP (' ')     ;J.K. 87 File system type
A_MEDIA_ID_INFO     ENDS

A_DISKACCESS_CONTROL	STRUC			;AN002; Unpublished function. Only for Hard file.
DAC_SPECIALFUNCTIONS	DB	0		;AN002; Always 0
DAC_ACCESS_FLAG 	DB	0		;AN002; Non Zero - allow disk I/O to unformatted hard file
A_DISKACCESS_CONTROL	ENDS			;AN002; 0 - Disallow disk I/O to unformatted hard file

;********************************;*
; CHARACTER DEVICES (PRINTERS)	 ;*
;********************************;*

;RAWIO SUB-FUNCTIONS
GET_RETRY_COUNT 	EQU	65H
SET_RETRY_COUNT 	EQU	45H

A_RETRYCOUNT	    STRUC
RC_COUNT		DW	?
A_RETRYCOUNT	    ENDS

;********************************;*		;J.K. 4/29/86
; CHARACTER DEVICES (SCREEN)	 ;*
;********************************;*		;J.K. 4/29/86
;
;SC_MODE_INFO	 struc
;SC_INFO_LENGTH 	 DW	 9
;SC_MODE		 DB	 0
;SC_COLORS		 DW	 0
;SC_WIDTH		 DW	 0
;SC_LENGTH		 DW	 0
;SC_MODE_INFO	 ends
;
;SC_INFO_PACKET_LENGTH	 EQU	 9		 ;LENGTH OF THE INFO PACKET.

;SUBFUNCTIONS FOR CON$GENIOCTL
;GET_SC_MODE		 EQU	 60h
;SET_SC_MODE		 EQU	 40h
;The following subfunctions are reserved for installable CODE PAGE switch
;console devices. - J.K. 4/29/86
;Get_active_codepage	 equ	 6Ah
;Invoke_active_codepage  equ	 4Ah
;Start_designate_codepage equ	 4Ch
;End_designate_codepage  equ	 4Dh
;Get_list_of_designated_codepage equ 6Bh
;J.K. 4/29/86 *** End of Con$genioctl equates & structures


