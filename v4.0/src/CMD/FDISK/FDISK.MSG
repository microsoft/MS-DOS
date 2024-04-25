/*           FDISK MESSAGE FILE                                         */

/************************************************************************/
/* Please log all modifications to this file:                           */
/*----------------------------------------------------------------------*/
/* Date: 04/04/86                                                       */
/* Changed by: Mark T	                                                */
/* Message changed: menu_1 - menu_38                                    */
/* Reason: Creation of file                                             */
/*----------------------------------------------------------------------*/
/* Date: 05/04/87                                                       */
/* Changed by: Dennis M	                                                */
/* Message changed: menu_1 - menu_44                                    */
/* Reason: DOS 3.3						        */
/*----------------------------------------------------------------------*/
/* Date:                                                                */
/* Changed by:                                                          */
/* Message changed:                                                     */
/* Reason:                                                              */
/*----------------------------------------------------------------------*/
/***********************************************************************/

/************************************************************************/
/*  FDISK MESSAGES                                                      */
/*                                                                      */
/* Portions of the screen that are handled in the msg are indicated on  */
/* the listing of the screen with the message name given. If the text   */
/* message is defined in another screen, then the name is followed by   */
/* a "#" character                                                      */
/*                                                                      */
/* NOTE TO TRANSLATORS                                                  */
/* The characters inside the <> and the ^^ are control characters and   */
/* should not be translated. The Control characters are defined as      */
/* follows:                                                             */
/*                                                                      */
/* <H> - Highlight the following text                                   */
/* <R> - Regular text                                                   */
/* <U> - Underline the following text                                   */
/* <B> - Blink the following text                                       */
/* <O> - Turn off Blink                                                 */
/* <Y> - Print YES character, as set by define                          */
/* <N> - Print NO character, as set by define                           */
/* <W> - Sound the beep                                                 */
/* <S> - Save cursor position for later use                             */
/* <G> - Cursor position left justified and regular proceed to right    */
/* <C> - Clear the screen out from control char to end of line          */
/* <I> - Insert character from Insert[] string. This string must be set */
/*       up prior to displaying the message. The first <I> will insert  */
/*       Insert[0], the second Insert[1], etc....This will move the     */
/*       cursor one postition. The Insert%% string will be initialized  */
/*                                                                      */
/*                                                                      */
/*  Multiple control characters can be between the <>.                  */
/*                                                                      */
/*  The ^^ indicates Row and column for the text and has the format of  */
/*  ^rrcc^ where the numbers are decimal and zero based .first row/col  */
/*  is 00. The numbers are in decimal, and must be 2 characters, which  */
/*  means rows/cols 0-9 should be listed as 00-09. For example, the 5th */
/*  row, 3rd column on the screen would be listed as ^0402^.            */
/*                                                                      */
/*  The column number is always the column desired. The row number is   */
/*  an offset from the previous row. For example, if the text just      */
/*  printed is on row 6, and the next text should be printed 2 rows     */
/*  down in column 0, then the control strin would be ^0201^. The first */
/*  row specified in the message is assumed to be based off of row 0,   */
/*  it would actually specify the actual row for the start of the msg   */
/*  to be printed.                                                      */
/*                                                                      */
/* NOTE: ALWAYS SAVE THIS FILE WITH NO TABS CHARACTERS                  */
/************************************************************************/


/************************************************************************/
/*                                                                      */
/* Define Area for text variables                                       */
/*                                                                      */
/************************************************************************/

#define ACTIVE_PART  'A'   /* Character to indicate active status */
#define DRIVE_INDICATOR ':' /* Character displayed to indicate drive letter */

/*                                                                      */
/*                                                                      */
/* The following character strings are required to display the          */
/* menu screens for FDISK. The messages have a label type of: menu_xx   */
/*                                                                      */
/*                                                                      */

/*******************************************************************************************************/
/*  Screen for DO_MAIN_MENU                                                                            */
/*                                                                                                     */
/*       ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*       ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*     ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*     00³                             IBM Personal Computer                              ³menu_1      */
/*     01³                     Fixed Disk Setup Program Version 3.40                      ³menu_1      */
/*     02³                        (C%Copyright IBM Corp. 1983,1988                        ³menu_1      */
/*     03³                                                                                ³            */
/*     04³                                 FDISK Options                                  ³menu_2      */
/*     05³                                                                                ³            */
/*     06³    Current fixed disk drive: #                                                 ³menu_5      */
/*     07³                                                                                ³            */
/*     08³    Choose one of the following:                                                ³menu_3      */
/*     09³                                                                                ³            */
/*     10³    1.  Create DOS Partition or Logical DOS Drive                               ³menu_2      */
/*     11³    2.  Set active partition                                                    ³menu_2      */
/*     12³    3.  Delete DOS Partition or Logical DOS Drive                               ³menu_2      */
/*     13³    4.  Display partition information                                           ³menu_2      */
/*     14³    5.  Select next fixed disk drive                                            ³menu_4      */
/*     15³                                                                                ³            */
/*     16³                                                                                ³            */
/*     17³    Enter choice: [#]                                                           ³menu_7      */
/*     18³                                                                                ³            */
/*     19³                                                                                ³            */
/*     20³    Warning! No partitions are set active - disk 1 is not startable unless      ³menu_6      */
/*     21³    a partition is set active.                                                  ³            */
/*     22³                                                                                ³            */
/*     23³                                                                                ³            */
/*     24³    Press ESC to exit FDISK                                                     ³menu_2      */
/*     ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/*******************************************************************************************************/


/*-------------------------------------------------------------*/
 char far *menu_1 =

"^0030^<R>è1001\
 ^0128^<R>è1002\
 ^0124^<R>è1003";



/*-------------------------------------------------------------*/
 char far *menu_2 =

"^0433^<H>è1004\
 ^0604^<H>è1005\
 ^0104^<H>è1006\
 ^0104^<H>è1007\
 ^0104^<H>è1008\
 ^1104^<R>è1009";

/*-------------------------------------------------------------*/
 char far *menu_3 =

"^0804^<R>è1010";

/*-------------------------------------------------------------*/
 char far *menu_4 =

"^1404^<H>è1011";

/*-------------------------------------------------------------*/
 char far *menu_5 =

"^0604^<R>è1012";

/*-------------------------------------------------------------*/
 char far *menu_6 =

"^2004^<H>è1013\
 ^0104^<R>è1014";

/*-------------------------------------------------------------*/
 char far *menu_7 =

"^1704^<H>è1015";

/*******************************************************************************************************/
/*  Screen for CREATE_PARTITION                                                                        */
/*                                                                                                     */
/*       ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*       ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*     ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*     00³                                                                                ³            */
/*     01³                                                                                ³            */
/*     02³                                                                                ³            */
/*     03³                                                                                ³            */
/*     04³                  Create DOS Partition or Logical DOS Drive                     ³menu_8      */
/*     05³                                                                                ³            */
/*     06³    Current fixed disk drive: #                                                 ³menu_5 #    */
/*     07³                                                                                ³            */
/*     08³    Choose one of the following:                                                ³menu_3 #    */
/*     09³                                                                                ³            */
/*     10³    1.  Create Primary DOS Partition                                            ³menu_9      */
/*     11³    2.  Create Extended DOS Partition                                           ³menu_9      */
/*     12³    3.  Create logical DOS Drive(s) in the Extended DOS Partition               ³menu_10     */
/*     13³                                                                                ³            */
/*     14³                                                                                ³            */
/*     15³                                                                                ³            */
/*     16³                                                                                ³            */
/*     17³    Enter choice: [ ]                                                           ³menu_7 #    */
/*     18³                                                                                ³            */
/*     19³                                                                                ³            */
/*     20³                                                                                ³            */
/*     21³                                                                                ³            */
/*     22³                                                                                ³            */
/*     23³                                                                                ³            */
/*     24³    Press ESC to return to FDISK Options                                        ³menu_11     */
/*     ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/*******************************************************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_8 =

"^0420^<H>è1016";

/*-------------------------------------------------------------*/
 char far *menu_9 =

"^1004^<H>è1017\
 ^0104^<H>è1018";

/*-------------------------------------------------------------*/
 char far *menu_10 =

"^1204^<H>è1019";

/*-------------------------------------------------------------*/
 char far *menu_11 =

"^2404^<R>è1020";


/*******************************************************************************************************/
/*  Screen for DOS_CREATE_PARTITION                                                                    */
/*                                                                                                     */
/*       ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*       ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*     ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*     00³                                                                                ³            */
/*     01³                                                                                ³            */
/*     02³                                                                                ³            */
/*     03³                                                                                ³            */
/*     04³                           Create Primary DOS Partition                         ³menu_12     */
/*     05³                                                                                ³            */
/*     06³    Current fixed disk drive: #                                                 ³menu_5 #    */
/*     07³                                                                                ³            */
/*     08³    Do you wish to use the maximum available size for a Primary DOS Partition   ³menu_13     */
/*     09³    and make the partition active (Y/N).....................? [Y]               ³menu_13     */
/*     10³                                                                                ³            */
/*     11³                                                                                ³            */
/*     12³                                                                                ³            */
/*     13³                                                                                ³            */
/*     14³                                                                                ³            */
/*     15³                                                                                ³            */
/*     16³                                                                                ³            */
/*     17³                                                                                ³            */
/*     18³                                                                                ³            */
/*     19³                                                                                ³            */
/*     20³                                                                                ³            */
/*     21³                                                                                ³            */
/*     22³                                                                                ³            */
/*     23³                                                                                ³            */
/*     24³    Press ESC to return to FDISK Options                                        ³menu_11     */
/*     ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/*******************************************************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_12 =

"^0427^<H>è1021";

/*-------------------------------------------------------------*/
 char far *menu_13 =

"^0804^<R>è1022\
 ^0104^<R>è1023";

/*-------------------------------------------------------------*/
 char far *menu_45 =

"^0804^<R>è1022\
 ^0104^<R>è1024";


/*******************************************************************************************************/
/*  Screen for INPUT_DOS_CREATE                                                                        */
/*                                                                                                     */
/*       ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*       ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*     ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*     00³                                                                                ³            */
/*     01³                                                                                ³            */
/*     02³                                                                                ³            */
/*     03³                                                                                ³            */
/*     04³                           Create Primary DOS Partition                         ³menu_12 #   */
/*     05³                                                                                ³            */
/*     06³    Current fixed disk drive: #                                                 ³menu_5 #    */
/*     07³                                                                                ³            */
/*     08³    Partition Status   Type    Size in Mbytes   Percentage of Disk Used         ³menu_14     */
/*     09³     ## #        #    #######       ####        ###%                            ³            */
/*     10³     ## #        #    #######       ####        ###%                            ³            */
/*     11³     ## #        #    #######       ####        ###%                            ³            */
/*     12³     ## #        #    #######       ####        ###%                            ³            */
/*     13³                                                                                ³            */
/*     14³    Total disk space is #### Mbytes (1 Mbyte = 1048576 bytes)                   ³menu_15     */
/*     15³    Maximum space available for partition is #### Mbytes (###%)                  ³menu_16     */
/*     16³                                                                                ³            */
/*     17³                                                                                ³            */
/*     18³    Enter partition size in Mbytes or percent of disk space (%) to              ³menu_39     */
/*     19³    create a Primary DOS Partition..................................[####]      ³            */
/*     20³                                                                                ³            */
/*     21³                                                                                ³            */
/*     22³                                                                                ³            */
/*     23³                                                                                ³            */
/*     24³    Press ESC to return to FDISK Options                                        ³menu_11     */
/*     ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/****************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_14 =

"^0804^<R>è1025\
 ^0104^<R> <II> <I>        <I>    <IIIIIII>       <IIII>        <IIII>\
 ^0104^<R> <II> <I>        <I>    <IIIIIII>       <IIII>        <IIII>\
 ^0104^<R> <II> <I>        <I>    <IIIIIII>       <IIII>        <IIII>\
 ^0104^<R> <II> <I>        <I>    <IIIIIII>       <IIII>        <IIII>";

/*-------------------------------------------------------------*/
 char far *menu_15 =

"^1404^<R>è1026";

/*-------------------------------------------------------------*/
 char far *menu_16 =

"^1504^<RC>è1027";

/*-------------------------------------------------------------*/
 char far *menu_39 =

"^1804^<RC>è1028\
 ^0104^<RC>è1029";


/****************************************************************************************************/
/*  Screen for EXT_CREATE_PARTITION                                                                 */
/*                                                                                                  */
/*    ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*    ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*  ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*  00³                                                                                ³            */
/*  01³                                                                                ³            */
/*  02³                                                                                ³            */
/*  03³                                                                                ³            */
/*  04³                           Create Extended DOS Partition                        ³menu_17     */
/*  05³                                                                                ³            */
/*  06³    Current fixed disk drive: #                                                 ³menu_5 #    */
/*  07³                                                                                ³            */
/*  08³    Partition Status   Type    Size in Mbytes   Percentage of Disk Used         ³menu_14 #   */
/*  09³     ##  #       #   #######       ####                   ###%                  ³            */
/*  10³     ##  #       #   #######       ####                   ###%                  ³            */
/*  11³     ##  #       #   #######       ####                   ###%                  ³            */
/*  12³     ##  #       #   #######       ####                   ###%                  ³            */
/*  13³                                                                                ³            */
/*  14³    Total disk space is #### Mbytes (1 Mbyte = 1048576 bytes)                   ³menu_15 #   */
/*  15³    Maximum space available for partition is #### Mbytes (##%)                  ³menu_16 #   */
/*  16³                                                                                ³            */
/*  17³                                                                                ³            */
/*  18³    Enter partition size in Mbytes or percent of disk space (%) to              ³menu_42 #   */
/*  19³    create an Extended DOS Partition................................[####]      ³            */
/*  20³                                                                                ³            */
/*  21³                                                                                ³            */
/*  22³                                                                                ³            */
/*  23³                                                                                ³            */
/*  24³    Press ESC to continue                                                       ³menu_46     */
/*  ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/***************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_17 =

"^0427^<H>è1030";

/*-------------------------------------------------------------*/
 char far *menu_42 =

"^1804^<RC>è1028\
 ^0104^<RC>è1031";


/*-------------------------------------------------------------*/
 char far *menu_46 =

"^2404^<R>è1032";




/*****************************************************************************************************/
/*  Screen for VOLUME_CREATE                                                                         */
/*                                                                                                   */
/*     ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*     ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*   00³                                                                                ³            */
/*   01³            Create Logical DOS Drive(s) in the Extended Partition               ³menu_18     */
/*   02³                                                                                ³            */
/*   03³Drv Volume Label  Mbytes  System  Usage  Drv Volume Label  Mbytes  System  Usage³menu_19/20  */
/*   04³##  ###########    ####  ########  ###%  ##  ###########    ####  ########  ###%³            */
/*   05³##  ###########    ####  ########  ###%  ##  ###########    ####  ########  ###%³            */
/*   06³##  ###########    ####  ########  ###%  ##  ###########    ####  ########  ###%³            */
/*   07³##  ###########    ####  ########  ###%  ##  ###########    ####  ########  ###%³            */
/*   08³##  ###########    ####  ########  ###%  ##  ###########    ####  ########  ###%³            */
/*   09³##  ###########    ####  ########  ###%  ##  ###########    ####  ########  ###%³            */
/*   10³##  ###########    ####  ########  ###%  ##  ###########    ####  ########  ###%³            */
/*   11³##  ###########    ####  ########  ###%  ##  ###########    ####  ########  ###%³            */
/*   12³##  ###########    ####  ########  ###%  ##  ###########    ####  ########  ###%³            */
/*   13³##  ###########    ####  ########  ###%  ##  ###########    ####  ########  ###%³            */
/*   14³##  ###########    ####  ########  ###%  ##  ###########    ####  ########  ###%³            */
/*   15³##  ###########    ####  ########  ###%                                         ³            */
/*   16³                                                                                ³            */
/*   17³    Total Extended DOS partition size is #### Mbytes (1 Mbyte = 1048576 bytes)  ³menu_17     */
/*   18³    Maximum space available for logical drive is #### Mbytes (###%)             ³menu_22     */
/*   19³                                                                                ³            */
/*   20³    Enter logical drive size in Mbytes or percent of disk space (%)...[####]    ³menu_40     */
/*   21³                                                                                ³            */
/*   22³                                                                                ³            */
/*   23³                                                                                ³            */
/*   24³    Press ESC to return to FDISK Options                                        ³menu_11     */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/***************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_18 =

"^0112^<HC>è1033";

/*-------------------------------------------------------------*/
 char far *menu_19 =

"^0300^<H>è1034\
^0100^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0100^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0100^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0100^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0100^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0100^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>";

/*----------------------------------------------------------*/
 char far *menu_43 =

"^1000^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0100^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0100^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0100^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0100^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0100^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>";

/*-------------------------------------------------------------*/
 char far *menu_20 =

"^0341^<H>è1034\
^0141^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0141^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0141^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0141^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0141^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0141^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>";

/*---------------------------------------------------------*/
 char far *menu_44 =

"^1041^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0141^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0141^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0141^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>\
^0141^<H><II>  <RIIIIIIIIIII>    <IIII>  <IIIIIIII>  <IIII>";

/*-------------------------------------------------------------*/
 char far *menu_21 =

"^1704^<RC>è1035";

/*-------------------------------------------------------------*/
 char far *menu_22 =

"^1804^<RC>è1036";

/*-------------------------------------------------------------*/
 char far *menu_40 =

"^2004^<RC>è1037";


/*****************************************************************************************************/
/*  Screen for CHANGE_ACTIVE_PARTITION                                                               */
/*                                                                                                   */
/*     ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*     ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*   00³                                                                                ³            */
/*   01³                              Set Active Partition                              ³menu_23     */
/*   02³                                                                                ³            */
/*   03³                                                                                ³            */
/*   04³                                                                                ³            */
/*   05³                                                                                ³            */
/*   06³    Current fixed disk drive: #                                                 ³menu_5 #    */
/*   07³                                                                                ³            */
/*   08³    Partition Status   Type    Size in Mbytes   Percentage of Disk Used         ³menu_14 #   */
/*   09³     ## #        #   #######       ####         ###%                            ³            */
/*   10³     ## #        #   #######       ####         ###%                            ³            */
/*   11³     ## #        #   #######       ####         ###%                            ³            */
/*   12³     ## #        #   #######       ####         ###%                            ³            */
/*   13³                                                                                ³            */
/*   14³    Total disk space is #### Mbytes (1 Mbyte = 1048576 bytes)                   ³menu_15 #   */
/*   15³                                                                                ³            */
/*   16³    Enter the number of the partition you want to make active............:[#]   ³menu_24     */
/*   17³                                                                                ³            */
/*   18³                                                                                ³            */
/*   19³                                                                                ³            */
/*   20³                                                                                ³            */
/*   21³                                                                                ³            */
/*   22³                                                                                ³            */
/*   23³                                                                                ³            */
/*   24³    Press ESC to return to FDISK Options                                        ³menu_11     */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/*****************************************************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_23 =

"^0430^<H>è1038";

/*-------------------------------------------------------------*/
 char far *menu_24 =

"^1604^<R>è1039";


/*****************************************************************************************************/
/*  Screen for DELETE_PARTITION                                                                      */
/*                                                                                                   */
/*     ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*     ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*   00³                                                                                ³            */
/*   01³                                                                                ³            */
/*   02³                                                                                ³            */
/*   03³                                                                                ³            */
/*   04³                   Delete DOS Partition or Logical DOS Drive                    ³menu_25     */
/*   05³                                                                                ³            */
/*   06³    Current fixed disk drive: #                                                 ³menu_5 #    */
/*   07³                                                                                ³            */
/*   08³    Choose one of the following:                                                ³menu_3 #    */
/*   09³                                                                                ³            */
/*   10³    1.  Delete Primary DOS Partition                                            ³menu_26     */
/*   11³    2.  Delete Extended DOS Partition                                           ³menu_26     */
/*   12³    3.  Delete Logical DOS Drive(s) in the Extended DOS Partition               ³menu_27     */
/*   13³                                                                                ³            */
/*   14³                                                                                ³            */
/*   15³                                                                                ³            */
/*   16³                                                                                ³            */
/*   17³    Enter choice: [ ]                                                           ³menu_7 #    */
/*   18³                                                                                ³            */
/*   19³                                                                                ³            */
/*   20³                                                                                ³            */
/*   21³                                                                                ³            */
/*   22³                                                                                ³            */
/*   23³                                                                                ³            */
/*   24³    Press ESC to return to FDISK Options                                        ³menu_11     */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/*****************************************************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_25 =

"^0419^<H>è1040";

/*-------------------------------------------------------------*/
 char far *menu_26 =

"^1004^<HC>è1041\
 ^0104^<HC>è1042";

/*-------------------------------------------------------------*/
 char far *menu_27 =

"^1204^<HC>è1043";

/*****************************************************************************************************/
/*  Screen for DOS_DELETE                                                                            */
/*                                                                                                   */
/*     ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*     ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*   00³                                                                                ³            */
/*   01³                                                                                ³            */
/*   02³                                                                                ³            */
/*   03³                                                                                ³            */
/*   04³                           Delete Primary DOS Partition                         ³menu_28     */
/*   05³                                                                                ³            */
/*   06³    Current fixed disk drive: #                                                 ³menu_5 #    */
/*   07³                                                                                ³            */
/*   08³    Partition Status   Type    Size in Mbytes   Percentage of Disk Used         ³menu_14 #   */
/*   09³     ## #        #   #######       ####         ###%                            ³menu_14 #   */
/*   10³     ## #        #   #######       ####         ###%                            ³            */
/*   11³     ## #        #   #######       ####         ###%                            ³            */
/*   12³     ## #        #   #######       ####         ###%                            ³            */
/*   13³                                                                                ³            */
/*   14³    Total disk space is #### Mbytes (1 Mbyte = 1048576 bytes)                   ³menu_15 #   */
/*   15³                                                                                ³            */
/*   16³    Warning! Data in the deleted Primary DOS Partition will be lost.            ³menu_29     */
/*   17³    Do you wish to continue (Y/N).................? [N]                         ³menu_29     */
/*   18³                                                                                ³            */
/*   19³                                                                                ³            */
/*   20³                                                                                ³            */
/*   21³                                                                                ³            */
/*   22³                                                                                ³            */
/*   23³                                                                                ³            */
/*   24³    Press ESC to return to FDISK Options                                        ³menu_11     */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/*****************************************************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_28 =

"^0426^<H>è1044";

/*-------------------------------------------------------------*/
 char far *menu_29 =

"^1604^<HBC>è1045\
 ^0104^<RC>è1046";

/*****************************************************************************************************/
/*  Screen for EXT_DELETE                                                                            */
/*                                                                                                   */
/*     ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*     ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*   00³                                                                                ³            */
/*   01³                                                                                ³            */
/*   02³                                                                                ³            */
/*   03³                                                                                ³            */
/*   04³                           Delete Extended DOS Partition                        ³menu_30     */
/*   05³                                                                                ³            */
/*   06³    Current fixed disk drive: #                                                 ³menu_5 #    */
/*   07³                                                                                ³            */
/*   08³    Partition Status   Type    Size in Mbytes   Percentage of Disk Used         ³menu_14 #   */
/*   09³     ## #        #   #######       ####         ###%                            ³menu_14 #   */
/*   10³     ## #        #   #######       ####         ###%                            ³            */
/*   11³     ## #        #   #######       ####         ###%                            ³            */
/*   12³     ## #        #   #######       ####         ###%                            ³            */
/*   13³                                                                                ³            */
/*   14³    Total disk space is #### Mbytes (1 Mbyte = 1048576 bytes)                   ³menu_15 #   */
/*   15³                                                                                ³            */
/*   16³    Warning! Data in the deleted Extended DOS partition will be lost.           ³menu_31     */
/*   17³    Do you wish to continue (Y/N).................? [N]                         ³menu_31     */
/*   18³                                                                                ³            */
/*   19³                                                                                ³            */
/*   20³                                                                                ³            */
/*   21³                                                                                ³            */
/*   22³                                                                                ³            */
/*   23³                                                                                ³            */
/*   24³    Press ESC to return to FDISK Options                                        ³menu_11     */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/*****************************************************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_30 =

"^0426^<H>è1047";

/*-------------------------------------------------------------*/
 char far *menu_31 =

"^1604^<HBC>è1048\
 ^0104^<RC>è1049";

/******************************************************************************************************/
/*  Screen for VOL_DELETE                                                                             */
/*                                                                                                    */
/*     ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³             */
/*     ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³             */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´             */
/*   00³                                                                                ³             */
/*   01³            Delete Logical DOS Drive(s) in the Extended DOS Partition           ³menu_32      */
/*   02³                                                                                ³             */
/*   03³Drv Volume Label  MBytes  System  Usage  Drv Volume Label  MBytes  System  Usage³menu_19/20 # */
/*   04³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³             */
/*   05³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³             */
/*   06³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³             */
/*   07³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³             */
/*   08³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³             */
/*   09³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³             */
/*   10³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³             */
/*   11³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³             */
/*   12³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³             */
/*   13³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³             */
/*   14³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³             */
/*   15³##  #############  ####  ########  ###%                                         ³             */
/*   16³                                                                                ³             */
/*   17³    Total Extended DOS Partition size is #### Mbytes (1 Mbyte = 1048576 bytes)  ³menu_21      */
/*   18³                                                                                ³             */
/*   19³    Warning! Data in a deleted Logical DOS Drive will be lost.                  ³menu_33      */
/*   20³    What drive do you want to delete...........................? [ ]            ³menu_33      */
/*   21³    Enter Volume Label.............................? [             ]            ³menu_41      */
/*   22³    Are you sure (Y/N).............................? [N]                        ³menu_34      */
/*   23³                                                                                ³             */
/*   24³    Press ESC to return to FDISK Options                                        ³menu_11     */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ             */
/******************************************************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_32 =

"^0112^<H>è1050";

/*-------------------------------------------------------------*/
 char far *menu_33 =

"^1904^<HBC>è1051\
 ^0104^<RC>è1052";

/*-------------------------------------------------------------*/
 char far *menu_34 =

"^2204^<R>è1053";

/*-------------------------------------------------------------*/
 char far *menu_41 =

"^2104^<R>è1054";

/******************************************************************************************************/
/*  Screen for DISPLAY_PARTITION_INFORMATION                                                          */
/*                                                                                                    */
/*     ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³             */
/*     ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³             */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´             */
/*   00³                                                                                ³             */
/*   01³                                                                                ³             */
/*   02³                                                                                ³             */
/*   03³                                                                                ³             */
/*   04³                           Display Partition Information                        ³menu_35      */
/*   05³                                                                                ³             */
/*   06³    Current fixed disk drive: #                                                 ³menu_5 #     */
/*   07³                                                                                ³             */
/*   08³    Partition Status   Type    Size in Mbytes   Percentage of Disk Used         ³menu_14 #    */
/*   09³     ## #        #   #######       ####         ###%                            ³menu_14 #    */
/*   10³     ## #        #   #######       ####         ###%                            ³             */
/*   11³     ## #        #   #######       ####         ###%                            ³             */
/*   12³     ## #        #   #######       ####         ###%                            ³             */
/*   13³                                                                                ³             */
/*   14³    Total disk space is #### Mbytes (1 Mbyte = 1048576 bytes)                   ³menu_15 #    */
/*   15³                                                                                ³             */
/*   16³                                                                                ³             */
/*   17³    The Extended DOS partition contains Logical DOS Drives.                     ³menu_36      */
/*   18³    Do you want to display the logical drive information (Y/N)......? [Y]       ³menu_36      */
/*   19³                                                                                ³             */
/*   20³                                                                                ³             */
/*   21³                                                                                ³             */
/*   22³                                                                                ³             */
/*   23³                                                                                ³             */
/*   24³    Press ESC to return to FDISK Options                                        ³menu_11     */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ             */
/******************************************************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_35 =

"^0426^<H>è1055";

/*-------------------------------------------------------------*/
 char far *menu_36 =

"^1704^<RC>è1056\
 ^0104^<RC>è1057";

/*****************************************************************************************************/
/*  Screen for DISPLAY_VOLUME_INFORMATION                                                            */
/*                                                                                                   */
/*     ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*     ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*   00³                                                                                ³            */
/*   01³                     Display Logical DOS Drive Information                      ³menu_37     */
/*   02³                                                                                ³            */
/*   03³Drv Volume Label  Mbytes  System  Usage  Drv Volume Label  Mbytes  System  Usage³menu_19/20  */
/*   04³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³            */
/*   05³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³            */
/*   16³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³            */
/*   17³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³            */
/*   18³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³            */
/*   19³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³            */
/*   10³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³            */
/*   11³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³            */
/*   12³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³            */
/*   13³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³            */
/*   14³##  #############  ####  ########  ###%  ##  #############  ####  ########  ###%³            */
/*   15³##  #############  ####  ########  ###%                                         ³            */
/*   16³                                                                                ³            */
/*   17³    Total Extended DOS partition size is #### Mbytes (1 Mbyte = 1048576 bytes)  ³menu_17     */
/*   18³                                                                                ³            */
/*   19³                                                                                ³            */
/*   20³                                                                                ³            */
/*   21³                                                                                ³            */
/*   22³                                                                                ³            */
/*   23³                                                                                ³            */
/*   24³    Press ESC to return to FDISK Options                                        ³menu_11     */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/*****************************************************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_37 =

"^0121^<H>è1058";

/*****************************************************************************************************/
/*  Screen for SYSTEM_REBOOT                                                                         */
/*                                                                                                   */
/*     ³00000000001111111111222222222233333333334444444444555555555566666666667777777777³            */
/*     ³01234567890123456789012345678901234567890123456789012345678901234567890123456789³            */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´            */
/*   00³                                                                                ³            */
/*   01³                                                                                ³            */
/*   02³                                                                                ³            */
/*   03³                                                                                ³            */
/*   04³                                                                                ³            */
/*   05³                                                                                ³            */
/*   06³                                                                                ³            */
/*   07³                                                                                ³            */
/*   08³                                                                                ³            */
/*   09³                                                                                ³            */
/*   10³                                                                                ³            */
/*   11³                                                                                ³            */
/*   12³                                                                                ³            */
/*   13³    System will now restart                                                     ³menu_38     */
/*   14³                                                                                ³            */
/*   15³    Insert DOS diskette in drive A:                                             ³menu_38     */
/*   16³    Press any key when ready . . .                                              ³menu_38     */
/*   17³                                                                                ³            */
/*   18³                                                                                ³            */
/*   19³                                                                                ³            */
/*   20³                                                                                ³            */
/*   21³                                                                                ³            */
/*   22³                                                                                ³            */
/*   23³                                                                                ³            */
/*   24³                                                                                ³             */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            */
/*****************************************************************************************************/

/*-------------------------------------------------------------*/
 char far *menu_38 =

"^1304^<H>è1059\
 ^0204^<R>è1060\
 ^0104^<R>è1061";


/*                                                                      */
/*                                                                      */
/* The following character strings are required to display the          */
/* status messages indicating successful operation. These messages      */
/* have the form: status_xx                                             */
/*                                                                      */
/* Note: In order to overlay any previous message on the screen, these  */
/*       messages are all 2 lines long. The second line may only be     */
/*       a blank line. If 2 lines are needed for translation, use the   */
/*       second line for text.  Exceptions are those msgs on line 0,    */
/*       and status_3.                                                  */
/*                                                                      */

/*-------------------------------------------------------------*/
 char far *status_1 =

"^2104^<CH>è1062\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *status_2 =

"^2104^<CH>è1063\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *status_3 =

"^0004^<H>è1064";
/* NOTE - the ^rrcc^ must be the first thing in this string */

/*-------------------------------------------------------------*/
 char far *status_4 =

"^2104^<CH>è1065\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *status_5 =

"^2104^<CH>è1066\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *status_6 =

"^2104^<CH>è1067\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *status_7 =

"^2204^<CH>è1068";

/*-------------------------------------------------------------*/
 char far *status_8 =

"^2104^<CH>è1069\
 ^0100^<C>";

/*-------------------------------------------------------------*/
 char far *status_9 =

"^1004^<CH>è1070\
 ^0100^<C>";

/*-------------------------------------------------------------*/
 char far *status_10 =

"^1804^<CH>è1071";

/*-------------------------------------------------------------*/
 char far *status_11 =

"^0004^<H>è1072";
/* NOTE - the ^rrcc^ must be the first thing in this string */

/*-------------------------------------------------------------*/
 char far *status_12 =

"^2104^<CH>è1073\
 ^0100^<CW>";

/*-------------------------------------------------------------*/

/*                                                                      */
/*                                                                      */
/* The following character strings are required to display the          */
/* error messages. These have form: error_xx                            */
/*                                                                      */
/* Note: In order to overlay any previous message on the screen, these  */
/*       messages are all 2 lines long. The second line may only be     */
/*       a blank line. If 2 lines are needed for translation, use the   */
/*       second line for text.  Exceptions are those msgs on line 0.    */
/*       and those messages that start on line 23                       */
/*                                                                      */


/*-------------------------------------------------------------*/
 char far *error_1 =

"^0004^<CH>è1074\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_2 =

"^2204^<CH>è1075\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_3 =

"^2204^<CH>è1076\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_4 =

"^0004^<CHW>è1077";

/*-------------------------------------------------------------*/
 char far *error_5 =

"^0004^<CHW>è1078";

/*-------------------------------------------------------------*/
 char far *error_6 =

"^2204^<CH>è1079\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_7 =

"^2204^<CH>è1080\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_8 =

"^2204^<CH>è1081\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_9 =

"^2204^<CH>è1082\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_10 =

"^2204^<CH>è1083\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_12 =

"^2204^<CH>è1084\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_13 =

"^2204^<CH>è1085\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_14 =

"^2204^<CH>è1086\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_15 =

"^2204^<CH>è1087\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_16 =

"^2204^<CH>è1088\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_17 =

"^2204^<CH>è1089";

/*-------------------------------------------------------------*/
 char far *error_19 =

"^2204^<CH>è1090\
 ^0104^<CH>è1091";

/*-------------------------------------------------------------*/
 char far *error_20 =

"^2204^<CH>è1092\
 ^0104^<CH>è1093";

/*-------------------------------------------------------------*/
 char far *error_21 =

"^2204^<CH>è1094";

/*-------------------------------------------------------------*/
 char far *error_22 =

"^2204^<CH>è1095";

/*-------------------------------------------------------------*/
 char far *error_23 =

"^2204^<C>\
 ^0104^<CHI>è1096";

/*-------------------------------------------------------------*/
 char far *error_24 =

"^2204^<CH>è1097";

/*-------------------------------------------------------------*/
 char far *error_25 =

"^2204^<CH>è1098\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_26 =

"^2204^<CH>è1099";

/*-------------------------------------------------------------*/
 char far *error_27 =

"^2204^<CH>è1100";

/*-------------------------------------------------------------*/
 char far *error_28 =

"^2204^<CH>è1101\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_29 =

"^2204^<CH>è1102\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_30 =

"^2204^<CHB>è1103";

/*-------------------------------------------------------------*/
 char far *error_31 =

"^2304^<CH>è1104";

/*-------------------------------------------------------------*/
 char far *error_32 =

"^2204^<CH>è1105\
 ^0104^<CH>è1106";

/*-------------------------------------------------------------*/
 char far *error_33 =

"^2200^<C>\
 ^0104^<CH>è1107";

/*-------------------------------------------------------------*/
 char far *error_34 =

"^2204^<CH>è1108";

/*-------------------------------------------------------------*/
 char far *error_35 =

"^2204^<CH>è1109\
 ^0104^<CH>è1110";

/*-------------------------------------------------------------*/
 char far *error_36 =

"^2204^<CH>è1111\
 ^0100^<CW>";

/*-------------------------------------------------------------*/


/*                                                                      */
/*                                                                      */
/* The following message is only included as an aide to debug message   */
/* strings during translations. The FDISK message formatter will attempt*/
/* to the best of its ability to catch invalid message strings and      */
/* print the error. This message should NEVER appear for a user, so it  */
/* is not neccessary to translate this message                          */
/*                                                                      */
/*                                                                      */


/*-------------------------------------------------------------*/

 char far *debug_msg =

"^2200^<HWB>è1112";

/*-------------------------------------------------------------*/
 char far *internal_error =

"^2204^<HBW>è1113";
/*                                                                      */
/* The following are not translatable. They are the partition names     */
/*                                                                      */

 char *DOS_part      = "PRI DOS";
 char *XENIX_part    = " XENIX ";
 char *EXTENDED_part = "EXT DOS";
 char *BAD_BLOCK_part= " Table ";
 char *PCIX_part     = " PC/IX ";
 char *NON_DOS_part  = "Non-DOS";
