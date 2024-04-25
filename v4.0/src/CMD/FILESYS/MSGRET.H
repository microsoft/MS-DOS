/************************************************************************/
/* MSGRET.H             - This include file defines each message type   */
/*                        that can occur in FILESYS.  The defines will  */
/*                        be used to build the proper message.          */
/*                                                                      */
/*      Date    : 10/29/87                                              */
/************************************************************************/

/************************************************************************/
/*              Message Retriever Standard Equates                      */
/************************************************************************/

#define PAUSE_RDR_MSG                   0x000A
#define REDIR_MSG                       0x000B
#define TITLE1                          0x000C
#define TITLE2                          0x000D
#define TITLE3                          0x000E
#define NO_ENTRIES                      0x000F
#define ERROR_RDR_MSG                   0x0010

#define Ext_Err_Class                   0x0001
#define Parse_Err_Class                 0x0002
#define Utility_Msg_Class               0x00ff
#define No_Handle                       0xffff
#define No_Replace                      0x0000
#define Sublist_Length                  0x000b
#define Reserved                        0x0000
#define Left_Align                      0x0000
#define Right_Align                     0x0080
#define Char_Field_Char                 0x0000
#define Char_Field_ASCIIZ               0x0010
#define Unsgn_Bin_Byte                  0x0011
#define Unsgn_Bin_Word                  0x0021
#define Unsgn_Bin_DWord                 0x0031
#define Sgn_Bin_Byte                    0x0012
#define Sgn_Bin_Word                    0x0022
#define Sgn_Bin_DWord                   0x0032
#define Bin_Hex_Byte                    0x0013
#define Bin_Hex_Word                    0x0023
#define Bin_Hex_DWord                   0x0033
#define No_Input                        0x0000
#define STDIN                           0x0000
#define STDOUT                          0x0001
#define STDERR                          0x0002
#define Blank                           0x0020

#define SubCnt0                         0x0000
#define SubCnt1                         0x0001
#define SubCnt2                         0x0002
#define SubCnt3                         0x0003
#define SubCnt4                         0x0004
#define SubCnt5                         0x0005

