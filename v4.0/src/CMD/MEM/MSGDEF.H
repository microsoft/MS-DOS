/************************************************************************/
/* MSGDEF.H		- This include file defines each message type	*/
/*			  that can occur in MEM.  These defines will	*/
/*			  be used by MEM to build the proper message.	*/
/*									*/
/*	Date	: 10/29/87						*/
/************************************************************************/

#define NewLineMsg			10
#define Title1Msg			11
#define Title2Msg			12
#define Title3Msg			13
#define Title4Msg			14
#define MainLineMsg			15
#define DriverLineMsg			16
#define DeviceLineMsg			17
#define TotalMemoryMsg			18
#define AvailableMemoryMsg		19
#define FreeMemoryMsg			20
#define EMSTotalMemoryMsg		21
#define EMSFreeMemoryMsg		22
#define EXTMemoryMsg			23
#define InterruptVectorMsg		24
#define ROMCommunicationAreaMsg 	25
#define DOSCommunicationAreaMsg 	26
#define IbmbioMsg			27
#define IbmdosMsg			28
#define SystemDataMsg			29
#define SystemProgramMsg		30
#define SystemDeviceDriverMsg		31
#define InstalledDeviceDriverMsg	32
#define SingleDriveMsg			33
#define MultipleDrivesMsg		34
#define ConfigBuffersMsg		35
#define ConfigFilesMsg			36
#define ConfigFcbsMsg			37
#define ConfigStacksMsg 		38
#define ConfigDeviceMsg 		39
#define ConfigIFSMsg			40
#define ConfigLastDriveMsg		41
#define ConfigInstallMsg		45	/* gga */
#define UnownedMsg			42
#define BlankMsg			43
#define HandleMsg			44
#define EXTMemAvlMsg			46	/* ;an001; dms;*/
#define StackMsg			47
#define FreeMsg 			48
#define ProgramMsg			49
#define EnvironMsg			50
#define DataMsg 			51


#define ParseError1Msg			01
#define ParseError10Msg 		10

/************************************************************************/
/*		Message Retriever Standard Equates			*/
/************************************************************************/

#define Ext_Err_Class			0x0001
#define Parse_Err_Class 		0x0002
#define Utility_Msg_Class		0x00ff
#define No_Handle			0xffff
#define No_Replace			0x0000
#define Sublist_Length			0x000b
#define Reserved			0x0000
#define Left_Align			0x0000
#define Right_Align			0x0080
#define Char_Field_Char 		0x0000
#define Char_Field_ASCIIZ		0x0010
#define Unsgn_Bin_Byte			0x0011
#define Unsgn_Bin_Word			0x0021
#define Unsgn_Bin_DWord 		0x0031
#define Sgn_Bin_Byte			0x0012
#define Sgn_Bin_Word			0x0022
#define Sgn_Bin_DWord			0x0032
#define Bin_Hex_Byte			0x0013
#define Bin_Hex_Word			0x0023
#define Bin_Hex_DWord			0x0033
#define No_Input			0x0000
#define STDIN				0x0000
#define STDOUT				0x0001
#define STDERR				0x0002
#define Blank				0x0020

#define SubCnt1 			0x0001
#define SubCnt2 			0x0002
#define SubCnt3 			0x0003
#define SubCnt4 			0x0004
#define SubCnt5 			0x0005

#define CarryFlag			0x0001

