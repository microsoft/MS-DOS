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
/* Reason: DOS 3.3                                                      */
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

#define YES    'Y'
#define NO     'N'
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

"^0029^<R>Microsoft DOS        \
 ^0121^<R>Fixed Disk Setup Program Version 4.00\
 ^0124^<R>(C)Copyright 1988 Microsoft Corp";



/*-------------------------------------------------------------*/
 char far *menu_2 =

"^0433^<H>FDISK Options\
 ^0604^<H>1. <R>Create DOS Partition or Logical DOS Drive\
 ^0104^<H>2. <R>Set active partition\
 ^0104^<H>3. <R>Delete DOS Partition or Logical DOS Drive\
 ^0104^<H>4. <R>Display partition information\
 ^1104^<R>Press <H>Esc<R> to exit FDISK";

/*-------------------------------------------------------------*/
 char far *menu_3 =

"^0804^<R>Choose one of the following:";

/*-------------------------------------------------------------*/
 char far *menu_4 =

"^1404^<H>5. <R>Select next fixed disk drive";

/*-------------------------------------------------------------*/
 char far *menu_5 =

"^0604^<R>Current fixed disk drive: <H><I>";

/*-------------------------------------------------------------*/
 char far *menu_6 =

"^2004^<H>Warning! <R>No partitions are set active - disk 1 is not startable unless\
 ^0104^<R>a partition is set active";

/*-------------------------------------------------------------*/
 char far *menu_7 =

"^1704^<H>Enter choice: [<S> ]";

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

"^0420^<H>Create DOS Partition or Logical DOS Drive";

/*-------------------------------------------------------------*/
 char far *menu_9 =

"^1004^<H>1. <R>Create Primary DOS Partition\
 ^0104^<H>2. <R>Create Extended DOS Partition";

/*-------------------------------------------------------------*/
 char far *menu_10 =

"^1204^<H>3. <R>Create Logical DOS Drive(s) in the Extended DOS Partition";

/*-------------------------------------------------------------*/
 char far *menu_11 =

"^2404^<R>Press <H>Esc<R> to return to FDISK Options";


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

"^0427^<H>Create Primary DOS Partition";

/*-------------------------------------------------------------*/
 char far *menu_13 =

"^0804^<R>Do you wish to use the maximum available size for a Primary DOS Partition\
 ^0104^<R>and make the partition active (<Y>/<N>).....................? <H>[<S> ]";

/*-------------------------------------------------------------*/
 char far *menu_45 =

"^0804^<R>Do you wish to use the maximum available size for a Primary DOS Partition\
 ^0104^<R>(<Y>/<N>)...................................................? <H>[<S> ]";


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

"^0804^<R>Partition Status   Type    Size in Mbytes   Percentage of Disk Used\
 ^0104^<R> <II> <I>        <I>    <IIIIIII>       <IIII>        <IIII>\
 ^0104^<R> <II> <I>        <I>    <IIIIIII>       <IIII>        <IIII>\
 ^0104^<R> <II> <I>        <I>    <IIIIIII>       <IIII>        <IIII>\
 ^0104^<R> <II> <I>        <I>    <IIIIIII>       <IIII>        <IIII>";

/*-------------------------------------------------------------*/
 char far *menu_15 =

"^1404^<R>Total disk space is <HIIIIR> Mbytes (1 Mbyte = 1048576 bytes)";

/*-------------------------------------------------------------*/
 char far *menu_16 =

"^1504^<RC>Maximum space available for partition is <HIIIIR> Mbytes (<HIIIIR>)";

/*-------------------------------------------------------------*/
 char far *menu_39 =

"^1804^<RC>Enter partition size in Mbytes or percent of disk space (%) to\
 ^0104^<RC>create a Primary DOS Partition.................................: <H>[<IIISI>]";


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

"^0427^<H>Create Extended DOS Partition";

/*-------------------------------------------------------------*/
 char far *menu_42 =

"^1804^<RC>Enter partition size in Mbytes or percent of disk space (%) to\
 ^0104^<RC>create an Extended DOS Partition..............................: <H>[<IIISI>]";


/*-------------------------------------------------------------*/
 char far *menu_46 =

"^2404^<R>Press <H>Esc<R> to continue";




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

"^0112^<HC>Create Logical DOS Drive(s) in the Extended DOS Partition";

/*-------------------------------------------------------------*/
 char far *menu_19 =

"^0300^<H>Drv Volume Label  Mbytes  System  Usage\
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

"^0341^<H>Drv Volume Label  Mbytes  System  Usage\
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

"^1704^<RC>Total Extended DOS Partition size is <HIIIIR> Mbytes (1 MByte = 1048576 bytes)";

/*-------------------------------------------------------------*/
 char far *menu_22 =

"^1804^<RC>Maximum space available for logical drive is <HIIIIR> Mbytes <H>(<IIII>)";

/*-------------------------------------------------------------*/
 char far *menu_40 =

"^2004^<RC>Enter logical drive size in Mbytes or percent of disk space (%)...<H>[<IIISI>]";


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

"^0430^<H>Set Active Partition";

/*-------------------------------------------------------------*/
 char far *menu_24 =

"^1604^<R>Enter the number of the partition you want to make active...........: <H>[<S> ]";


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

"^0419^<H>Delete DOS Partition or Logical DOS Drive";

/*-------------------------------------------------------------*/
 char far *menu_26 =

"^1004^<HC>1.  <R>Delete Primary DOS Partition\
 ^0104^<HC>2.  <R>Delete Extended DOS Partition";

/*-------------------------------------------------------------*/
 char far *menu_27 =

"^1204^<HC>3.  <R>Delete Logical DOS Drive(s) in the Extended DOS Partition";

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

"^0426^<H>Delete Primary DOS Partition";

/*-------------------------------------------------------------*/
 char far *menu_29 =

"^1604^<HBC>Warning! <OR>Data in the deleted Primary DOS Partition will be lost.\
 ^0104^<RC>Do you wish to continue (<Y>/<N>).................? <H>[<S> ]";

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

"^0426^<H>Delete Extended DOS Partition";

/*-------------------------------------------------------------*/
 char far *menu_31 =

"^1604^<HBC>Warning! <OR>Data in the deleted Extended DOS Partition will be lost.\
 ^0104^<RC>Do you wish to continue (<Y>/<N>).................? <H>[<S> ]";

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

"^0112^<H>Delete Logical DOS Drive(s) in the Extended DOS Partition";

/*-------------------------------------------------------------*/
 char far *menu_33 =

"^1904^<HBC>Warning! <OR>Data in a deleted Logical DOS Drive will be lost.\
 ^0104^<RC>What drive do you want to delete...............................? <H>[<S> ]";

/*-------------------------------------------------------------*/
 char far *menu_34 =

"^2204^<R>Are you sure (<Y>/<N>)..............................? <H>[<S> ]";

/*-------------------------------------------------------------*/
 char far *menu_41 =

"^2104^<R>Enter Volume Label..............................? <H>[<S>           ]";

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

"^0426^<H>Display Partition Information";

/*-------------------------------------------------------------*/
 char far *menu_36 =

"^1704^<RC>The Extended DOS Partition contains Logical DOS Drives.\
 ^0104^<RC>Do you want to display the logical drive information (<Y>/<N>)......?<H>[<S> ]";

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

"^0121^<H>Display Logical DOS Drive Information";

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

"^1304^<H>System will now restart\
 ^0204^<R>Insert DOS Startup diskette in drive A:\
 ^0104^<R>Press any key when ready . . .<S>";


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

"^2104^<CH>Primary DOS Partition deleted\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *status_2 =

"^2104^<CH>Extended DOS Partition deleted\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *status_3 =

"^0004^<H>Drive deleted";
/* NOTE - the ^rrcc^ must be the first thing in this string */

/*-------------------------------------------------------------*/
 char far *status_4 =

"^2104^<CH>Partition <I> made active\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *status_5 =

"^2104^<CH>Primary DOS Partition created\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *status_6 =

"^2104^<CH>Extended DOS Partition created\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *status_7 =

"^2204^<CH>Logical DOS Drive created, drive letters changed or added<W>";

/*-------------------------------------------------------------*/
 char far *status_8 =

"^2104^<CH>No partitions defined\
 ^0100^<C>";

/*-------------------------------------------------------------*/
 char far *status_9 =

"^1004^<CH>No logical drives defined\
 ^0100^<C>";

/*-------------------------------------------------------------*/
 char far *status_10 =

"^1804^<CH>Drive letters have been changed or deleted<W>";

/*-------------------------------------------------------------*/
 char far *status_11 =

"^0004^<H>Drive redirected";
/* NOTE - the ^rrcc^ must be the first thing in this string */

/*-------------------------------------------------------------*/
 char far *status_12 =

"^2104^<CH>Primary DOS Partition created, drive letters changed or added\
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

"^0004^<CH>No fixed disks present.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_2 =

"^2204^<CH>Error reading fixed disk.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_3 =

"^2204^<CH>Error writing fixed disk.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_4 =

"^0004^<CHW>Incorrect DOS version.";

/*-------------------------------------------------------------*/
 char far *error_5 =

"^0004^<CHW>Cannot FDISK with network loaded.";

/*-------------------------------------------------------------*/
 char far *error_6 =

"^2204^<CH>No Primary DOS Partition to delete.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_7 =

"^2204^<CH>No Extended DOS Partition to delete.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_8 =

"^2204^<CH>Primary DOS Partition already exists.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_9 =

"^2204^<CH>Extended DOS Partition already exists.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_10 =

"^2204^<CH>No space to create a DOS partition.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_12 =

"^2204^<CH>Requested logical drive size exceeds the maximum available space.<W>\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_13 =

"^2204^<CH>Requested partition size exceeds the maximum available space.<W>\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_14 =

"^2204^<CH>No partitions to delete.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_15 =

"^2204^<CH>The only startable partition on Drive 1 is already set active.<W>\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_16 =

"^2204^<CH>No partitions to make active.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_17 =

"^2204^<CH>Partition selected (<I>) is not startable, active partition not changed.<W>";

/*-------------------------------------------------------------*/
 char far *error_19 =

"^2204^<CH>Cannot create Extended DOS Partition without\
 ^0104^<CH>Primary DOS Partition on disk 1.<W>";

/*-------------------------------------------------------------*/
 char far *error_20 =

"^2204^<CH>All available space in the Extended DOS Partition\
 ^0104^<CH>is assigned to logical drives.<W>";

/*-------------------------------------------------------------*/
 char far *error_21 =

"^2204^<CH>Cannot delete Extended DOS Partition while logical drives exist.<W>";

/*-------------------------------------------------------------*/
 char far *error_22 =

"^2204^<CH>All logical drives deleted in the Extended DOS Partition.<W>";

/*-------------------------------------------------------------*/
 char far *error_23 =

"^2204^<C>\
 ^0104^<CHI> is not a choice. Please enter <III>.<W>";

/*-------------------------------------------------------------*/
 char far *error_24 =

"^2204^<CH>Warning! The partition set active is not startable.<W>";

/*-------------------------------------------------------------*/
 char far *error_25 =

"^2204^<CH> Only non-startable partitions exist.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_26 =

"^2204^<CH>Only partitions on Drive 1 can be made active.<W>";

/*-------------------------------------------------------------*/
 char far *error_27 =

"^2204^<CH>Maximum number of Logical DOS Drives installed.<W>";

/*-------------------------------------------------------------*/
 char far *error_28 =

"^2204^<CH>Cannot create a zero size partition.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_29 =

"^2204^<CH>Drive <II> already deleted.\
 ^0100^<CW>";

/*-------------------------------------------------------------*/
 char far *error_30 =

"^2204^<CHB>Unable to access Drive <I>.<OW>";

/*-------------------------------------------------------------*/
 char far *error_31 =

"^2304^<CH>Invalid entry, please enter <III>.<W>";

/*-------------------------------------------------------------*/
 char far *error_32 =

"^2204^<CH>Cannot delete Primary DOS Partition on drive 1 \
 ^0104^<CH>when an Extended DOS Partition exists.<W>";

/*-------------------------------------------------------------*/
 char far *error_33 =

"^2200^<C>\
 ^0104^<CH>Invalid entry, please press Enter.<W>";

/*-------------------------------------------------------------*/
 char far *error_34 =

"^2204^<CH>Volume label does not match.<W>";

/*-------------------------------------------------------------*/
 char far *error_35 =

"^2204^<CH>Cannot create Logical DOS Drive without\
 ^0104^<CH>an Extended DOS Partition on the current drive.<W>";

/*-------------------------------------------------------------*/
 char far *error_36 =

"^2204^<CH>No Logical DOS Drive(s) to delete.\
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

"^2200^<HWB>Message string error <I>. See header of FDISKC.MSG for error definition";

/*-------------------------------------------------------------*/
 char far *internal_error =

"^2204^<HBW>Internal error";

/*                                                                      */
/* The following are not translatable. They are the partition names     */
/*                                                                      */

 char *DOS_part      = "PRI DOS";
 char *XENIX_part    = " XENIX ";
 char *EXTENDED_part = "EXT DOS";
 char *BAD_BLOCK_part= " Table ";
 char *PCIX_part     = " PC/IX ";
 char *NON_DOS_part  = "Non-DOS";


