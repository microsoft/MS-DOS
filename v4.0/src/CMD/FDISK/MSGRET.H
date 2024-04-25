/*  */
/*----------------------------------------------------------------------+
|                                                                       |
| This file contains the structures and defines that are needed to use  |
| the message retriever C program.                                      |
|                                                                       |
|                                                                       |
| Date:         6-27-87                                                 |
|                                                                       |
+----------------------------------------------------------------------*/

#define NORMAL_PRELOAD         0                                        /* AN000 */
#define ALL_UTILITY_MESSAGES  -1                                        /* AN000 */
#define Utility_Msg_Class     -1                                        /* AN014 */
#define Ext_Err_Class          1                                        /* AN014 */

#define DosStdEr        2               /*;AN000;  standard error             */

#define nosubptr        0               /*;AN000;  no sublist pointer         */
#define nosubcnt        0               /*;AN000;  0 substitution count       */
#define oneparm         1               /*;AN000;  1 substitution count       */
#define twoparm         2               /*;AN000;  2 substitution count       */
#define noinput         0               /*;AN000;  no user input              */


#define utility_msg_class 0xff /*;AN000; Utility message type                */


/* Sublist Flag Values                                                 */

/* Alignment Indicator                                                 */
#define sf_left         0x00      /*;AN000; left align                 */
#define sf_right        0x80      /*;AN000; right align                */

/* Field Type                                                          */
#define sf_char         0x00      /*;AN000; character                  */
#define sf_unsbin2d     0x01      /*;AN000; unsigned binary to decimal */
#define sf_sbin         0x02      /*;AN000; signed binary to decimal   */
#define sf_unsbin2h     0x03      /*;AN000; unsigned binary to hex     */
#define sf_date         0x04      /*;AN000; date                       */
#define sf_time12       0x05      /*;AN000; time 12-hour               */
#define sf_time24       0x06      /*;AN000; time 24-hour               */


/* Data Variable Size                                                  */

#define sf_ch           0x00      /*;AN000; single character           */
#define sf_asciiz       0x10      /*;AN000; asciiz string              */
#define sf_word         0x20      /*;AN000; word                       */
#define sf_dword        0x30      /*;AN000; double word                */
#define sf_word         0x20      /*;AN000; word                       */

#define YesMsg          0x09                                            /* AN012 */
#define NoMsg           0x0A                                            /* AN012 */

