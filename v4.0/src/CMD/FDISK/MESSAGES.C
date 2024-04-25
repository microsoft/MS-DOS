
#include "dos.h"                                                        /* AN000 */
#include "msgret.h"                                                     /* AN000 */
#include "fdisk.h"                                                      /* AN000 */
#include "extern.h"                                                     /* AN000 */
#include "subtype.h"                                                    /* AN000 */
#include "stdio.h"                                                      /* AN000 */

/*  */
/******************************************************************************/
/*Routine name:  PRELOAD_MESSAGES                                             */
/******************************************************************************/
/*                                                                            */
/*Description:   Preloads messages for Display_Msg and returns error code     */
/*               if incorrect DOS version, insuffient memory, or unable to    */
/*               to find messages.                                            */
/*                                                                            */
/*Called Procedures:    sysloadmsg                                            */
/*                      display_msg                                           */
/*                                                                            */
/*Change History: Created        5/30/87         DRM                          */
/*                                                                            */
/*Input: None                                                                 */
/*                                                                            */
/*Output: None                                                                */
/*                                                                            */
/******************************************************************************/


char preload_messages()                                                 /* AN000 */

BEGIN                                                                   /* AN000 */

char message_flag;                                                      /* AN000 */

     /* load all messages for FDISK */
     message_flag = c(TRUE);                                            /* AN000 */
     sysloadmsg(&regs,&regs);                                           /* AN000   load the messages         */

     if ((regs.x.cflag & CARRY_FLAG) == CARRY_FLAG)                     /* AN000   If msg load problem       */
       BEGIN
        sysdispmsg(&regs,&regs);                                        /* AN000   write the error message */
        message_flag = FALSE;                                           /* AN000 */
       END
     return(message_flag);                                              /* AN000 */

END                                                                     /* AN000 */

/*  */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/
/*                                                                           */
/*    Subroutine Name: display_msg                                           */
/*                                                                           */
/*    Subroutine Function:                                                   */
/*       Display the requested message to the standard output device         */
/*                                                                           */
/*    Input:                                                                 */
/*        (1) Number of the message to be displayed (see FDISK.SKL)          */
/*        (2) Number of substitution parameters (%1,%2)                      */
/*        (3) Offset of sublist control block                                */
/*        (4) Message Class, 0=no input, 1=input via INT 21 AH=1             */
/*                                                                           */
/*    Output:                                                                */
/*        The message is written to the standard output device.  If input    */
/*        was requested, the character code of the key pressed is returned   */
/*        in regs.x.ax.                                                      */
/*                                                                           */
/*    Normal exit: Message written to handle                                 */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              Sysdispmsg (module _msgret.sal)                              */
/*                                                                           */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/

void display_msg(msgnum,msghan,msgparms,msgsub,msginput,msgclass) /*;AN000 AC014;                           */
int   msgnum;                           /*;AN000; message number              */
int   msghan;                           /*;AN000; output device               */
int   msgparms;                         /*;AN000; number of substitution parms*/
int   *msgsub;                          /*;AN000; offset of sublist           */
char  msginput;                         /*;AN000; 0=no input, else input func */
char  msgclass;                         /*;AN014; 0=no input, else input func */

BEGIN
        regs.x.ax = u(msgnum);             /*;AN000; set registers               */
        regs.x.bx = u(msghan);             /*;AN000;                             */
        regs.x.cx = u(msgparms);           /*;AN000;                             */
        regs.h.dh = uc(msgclass);          /*;AN014;                             */
        regs.h.dl = uc(msginput);          /*;AN000;                             */
        regs.x.si = u(msgsub);             /*;AN000;                             */
        sysdispmsg(&regs,&regs);           /*;AN000;  write the messages         */

        return;                            /*;AN000;                             */
END

/*  */
/******************************************************************************/
/*Routine name:  GET_YES_NO_VALUES                                            */
/******************************************************************************/
/*                                                                            */
/*Description:   Uses SYSGETMSG to get the translated values for Y and N      */
/*               for display purposes.                                        */
/*                                                                            */
/*Called Procedures:    sysgetmsg                                             */
/*                      sysdispmsg                                            */
/*                                                                            */
/*Change History: Created        5/11/88         DRM                          */
/*                                                                            */
/*Input: None                                                                 */
/*                                                                            */
/*Output: None                                                                */
/*                                                                            */
/******************************************************************************/


char get_yes_no_values()                                                /* AN012 */

BEGIN                                                                   /* AN012 */

char            message_flag;                                           /* AN012 */
char far        *msg_buff;                                              /* AN012 */

     message_flag = c(TRUE);                                            /* AN012 */

     /* do sysgetmsg for 'Y' */
     regs.x.ax = YesMsg;                                                /* AN012 */
     regs.h.dh = uc(utility_msg_class);                                 /* AN012 */
     sysgetmsg(&regs,&segregs,&regs);                                   /* AN012 */

     FP_OFF(msg_buff) = regs.x.si;                                      /* AN012 */
     FP_SEG(msg_buff) = segregs.ds;                                     /* AN012 */

     Yes = *msg_buff;                                                   /* AN012 */

     if ((regs.x.cflag & CARRY_FLAG) != CARRY_FLAG)                     /* AN012   If msg load problem       */
          BEGIN                                                         /* AN012 */
          /* do sysgetmsg for 'N' */
          regs.x.ax = NoMsg;                                            /* AN012 */
          regs.h.dh = uc(utility_msg_class);                            /* AN012 */
          sysgetmsg(&regs,&segregs,&regs);                              /* AN012 */

          FP_OFF(msg_buff) = regs.x.si;                                 /* AN012 */
          FP_SEG(msg_buff) = segregs.ds;                                /* AN012 */

          No = *msg_buff;                                               /* AN012 */

          END                                                           /* AN012 */

     if ((regs.x.cflag & CARRY_FLAG) == CARRY_FLAG)                     /* AN012   If msg load problem       */
       BEGIN                                                            /* AN012 */
        sysdispmsg(&regs,&regs);                                        /* AN012   write the error message */
        message_flag = FALSE;                                           /* AN012 */
       END                                                              /* AN012 */

     return(message_flag);                                              /* AN012 */

END                                                                     /* AN012 */

