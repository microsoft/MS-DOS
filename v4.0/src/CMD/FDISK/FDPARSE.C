
#include "dos.h"                                                        /* AN000 */
#include "fdisk.h"                                                      /* AN000 */
#include "extern.h"                                                     /* AN000 */
#include "parse.h"                                                      /* AN000 */
#include "string.h"                                                     /* AN000 */
#include "subtype.h"                                                    /* AN000 */
#include "msgret.h"                                                     /* AN000 */


/*  */
/******************************************************************************/
/*Routine name:  PARSE_COMMAND_LINE                                           */
/******************************************************************************/
/*                                                                            */
/*Description:   Sets up flags, preloads messages, and parses the command     */
/*               line for switchs.                                            */
/*                                                                            */
/*Called Procedures:                                                          */
/*                                                                            */
/*Change History: Created        5/30/87         DRM                          */
/*                                                                            */
/*Input: None                                                                 */
/*                                                                            */
/*Output: None                                                                */
/*                                                                            */
/******************************************************************************/


char parse_command_line(argc,argv)                                      /* AN000 */

char *argv[];                                /* array of pointer arguments AN000 */
int  argc;

BEGIN                                                                   /* AN000 */


        char    cmd_line[128];                                          /* AN000 */
        char    finished;                                               /* AN000 */
        int     i;                                                      /* AN000 */
        char    parse_good;                                             /* AN000 */
        char    far *cmdline;

        parse_init();                                                   /* AN000 */

        /* Initialize parse_flag to true and don't change unless error */
        parse_good = TRUE;                                              /* AN000 */

        regs.h.ah = (unsigned char) 0x62;
        intdosx(&regs, &regs, &segregs);

        FP_OFF(cmdline) = 0x81;
        FP_SEG(cmdline) = regs.x.bx;

        i = 0;
        while ( *cmdline != (char) '\x0d' ) cmd_line[i++] = *cmdline++;
        cmd_line[i++] = (char) '\x0d';
        cmd_line[i++] = (char) '\0';

        regs.x.si = (unsigned)cmd_line;                                 /* AN000 make DS:SI point to source */
        regs.x.cx = u(0);                                               /* AN000 operand ordinal (whatever that means) */
        regs.x.dx = u(0);                                               /* AN000 operand ordinal (whatever that means) */
        regs.x.di = (unsigned)&p_p;                                     /* AN000 address of parm list */
        Parse_Ptr = (unsigned)cmd_line;                                 /* AN010 */
        regs.x.si = (unsigned)cmd_line;                                 /* AN010 */

        finished = FALSE;
        while ( !finished )                                            /* AN000 */
         BEGIN                                                         /* AN000 */

          Parse_Ptr = regs.x.si;                                       /* AN010  point to next parm       */
          parse(&regs,&regs);                                          /* AN000 Call DOS PARSE service routines*/

          if (regs.x.ax == u(NOERROR))                                 /* AN000 If there was an error*/
             BEGIN
              if (regs.x.dx == (unsigned)&p_buff)                      /* AN000 */
                check_disk_validity();                                 /* AN000 It's a drive letter */

              if (regs.x.dx == (unsigned)&sp_buff)                     /* AN000 */
                process_switch();                                      /* AN000 It's a switch*/
             END
          else
             BEGIN
              if (regs.x.ax == u(0xffff))
                 finished = TRUE;                                      /* AN000 Then we are done*/
              else
                BEGIN
                 Parse_msg(regs.x.ax,STDERR,Parse_err_class);          /* AN010  */
                 parse_good = FALSE;
                 finished = TRUE;                                      /* AN000 Then we are done*/
                END
              END
          END /* End WHILE */                                          /* AN000 */

        return(parse_good);                                             /* AN000 Return to caller*/

END     /* end parser */                                                /* AN000 */


/*  */
/******************************************************************************/
/*Routine name:  INIT_PARSE                                                   */
/******************************************************************************/
/*                                                                            */
/*Description:   Sets up ALL VALUES AND STRUCTS FOR PARSER.                   */
/*                                                                            */
/*Called Procedures:                                                          */
/*                                                                            */
/*Change History: Created        6/15/87         DRM                          */
/*                                                                            */
/*Input: None                                                                 */
/*                                                                            */
/*Output: None                                                                */
/*                                                                            */
/******************************************************************************/


void parse_init()                                                       /* AN000 */

BEGIN                                                                   /* AN000 */


  primary_flag            = FALSE;                                      /* AN000 */
  extended_flag           = FALSE;                                      /* AN000 */
  logical_flag            = FALSE;                                      /* AN000 */
  disk_flag               = FALSE;                                      /* AN000 */
  quiet_flag              = FALSE;                                      /* AN000 */

  p_p.p_parmsx_ptr        = (unsigned)&p_px;                            /* AN000 Address of extended parm list */
  p_p.p_num_extra         = uc(1);                                      /* AN000 */
  p_p.p_len_extra_delim   = uc(1);                                      /* AN000 */
  p_p.p_extra_delim       = c(SEMICOLON);                               /* AN000 */

  p_px.p_minp             = uc(0);                                      /* AN000 1 required positional */
  p_px.p_maxp             = uc(1);                                      /* AN000 1 maximum positionals */
  p_px.p_con1_ptr         = (unsigned)&p_con;                           /* AN000 pointer to next control blk */
  p_px.p_maxs             = uc(2);                                      /* AN000 number of switches */
  p_px.p_swi1_ptr         = (unsigned)&p_swi1;                          /* AN000 pointer to next control blk */
  p_px.p_swi2_ptr         = (unsigned)&p_swi2;                          /* AN000 pointer to next control blk */
  p_px.p_maxk             = uc(NOVAL);                                  /* AN000 no keywords */

  p_con.p_match_flag     = u(0x8001);                                   /* AN000 DRIVE NUMBER 1 OR 2 optional */
  p_con.p_function_flag  = u(0x0000);                                   /* AN000 DO NOTHING FOR FUNCTION FLAG */
  p_con.p_buff1_ptr      = (unsigned)&p_buff;                           /* AN000 */
  p_con.p_val1_ptr       = (unsigned)&p_val;                            /* AN000 */
  p_con.p_nid            = uc(0);                                       /* AN000 */

  p_swi1.sp_match_flag    = u(0x8000);                                   /* AN000 Optional (switch) */
  p_swi1.sp_function_flag = u(0x0000);                                   /* AN000 DO NOTHING FOR FUNCTION FLAG */
  p_swi1.sp_buff1_ptr     = (unsigned)&sp_buff;                          /* AN000 */
  p_swi1.sp_val1_ptr      = (unsigned)&sp_val;                           /* AN000 */
  p_swi1.sp_nid           = uc(3);                                       /* AN000 3 switches allowed */
  strcpy((char *) p_swi1.sp_switch1,PRI);                                /* AN000 /a switch */
  strcpy((char *) p_swi1.sp_switch2,EXT);                                /* AN000 /a switch */
  strcpy((char *) p_swi1.sp_switch3,LOG);                                /* AN000 /a switch */

  p_swi2.sp_match_flag    = u(0x0001);                                   /* AN000 Optional (switch) */
  p_swi2.sp_function_flag = u(0x0000);                                   /* AN000 DO NOTHING FOR FUNCTION FLAG */
  p_swi2.sp_buff1_ptr     = (unsigned)&sp_buff;                          /* AN000 */
  p_swi2.sp_val1_ptr      = (unsigned)NOVAL;                             /* AN000 */
  p_swi2.sp_nid           = uc(1);                                       /* AN000 3 switches allowed */
  strcpy((char *) p_swi2.sp_switch4,QUIET);                                /* AN000 /a switch */

  p_val.p_values         =  uc(1);                                      /* AN000 - Number of values items returned */
  p_val.p_range          =  uc(1);                                      /* AN000 - Number of ranges */
  p_val.p_range_one      =  uc(1);                                      /* AN000 - range number one */
  p_val.p_low_range      =  ul(1);                                      /* AN000 - low value for range */
  p_val.p_high_range     =  ul(2);                                      /* AN000 - high value for range */

  sp_val.p_values      =  uc(1);                                        /* AN000 - Number of values items returned */
  sp_val.p_range       =  uc(1);                                        /* AN000 - Number of ranges */
  sp_val.p_range_one   =  uc(1);                                        /* AN000 - range number one */
  sp_val.p_low_range   =  ul(1);                                        /* AN000 - low value for range */
  sp_val.p_high_range  =  ul(4000);                                     /* AN000 - high value for range */

  return;                                                               /* AN000 */

END
                                                                        /* AN000 */
/*  */
/******************************************************************************/
/*Routine name:  CHECK_DISK_VALIDITY                                          */
/******************************************************************************/
/*                                                                            */
/*Description:   Checks the return buffer from parse for the positional       */
/*               value to be equal to 0 or 1.                                 */
/*                                                                            */
/*Called Procedures:                                                          */
/*                                                                            */
/*Change History: Created        6/18/87         DRM                          */
/*                                                                            */
/*Input: None                                                                 */
/*                                                                            */
/*Output: None                                                                */
/*                                                                            */
/******************************************************************************/


void check_disk_validity()                                              /* AN000 */

BEGIN                                                                   /* AN000 */

        disk_flag = (FLAG)TRUE;                                         /* AN000 */
        cur_disk_buff = ((char)p_buff.p_value - 1);                     /* AN000 */
        return;                                                         /* AN000 */
END                                                                     /* AN000 */

/*  */
/******************************************************************************/
/*Routine name:  PROCESS_SWITCH                                               */
/******************************************************************************/
/*                                                                            */
/*Description:   This function looks at the return buffer of the parse and    */
/*               determins the switch, places value in buffer, and sets       */
/*               flag for specific switch.                                    */
/*                                                                            */
/*Called Procedures:                                                          */
/*                                                                            */
/*Change History: Created        6/18/87         DRM                          */
/*                                                                            */
/*Input: None                                                                 */
/*                                                                            */
/*Output: None                                                                */
/*                                                                            */
/******************************************************************************/


void process_switch()                                                   /* AN000 */

BEGIN                                                                   /* AN000 */


       BEGIN                                                            /* AN000 */
           if (sp_buff.p_synonym == (unsigned)p_swi1.sp_switch1)        /* AN000 */
            BEGIN                                                       /* AN000 */
             primary_flag = (FLAG)TRUE;                                 /* AN000 */
             primary_buff = (unsigned)sp_buff.p_value;                  /* AN000 */
            END                                                         /* AN000 */

           if (sp_buff.p_synonym == (unsigned)p_swi1.sp_switch2)        /* AN000 */
            BEGIN                                                       /* AN000 */
             extended_flag = (FLAG)TRUE;                                /* AN000 */
             extended_buff = (unsigned)sp_buff.p_value;                 /* AN000 */
            END                                                         /* AN000 */

           if (sp_buff.p_synonym == (unsigned)p_swi1.sp_switch3)        /* AN000 */
            BEGIN                                                       /* AN000 */
             logical_flag = (FLAG)TRUE;                                 /* AN000 */
             logical_buff = (unsigned)sp_buff.p_value;                  /* AN000 */
            END                                                         /* AN000 */

           if (sp_buff.p_synonym == (unsigned)p_swi2.sp_switch4)        /* AN000 */
            BEGIN                                                       /* AN000 */
             quiet_flag = (FLAG)TRUE;                                   /* AN000 */
            END                                                         /* AN000 */
       END                                                              /* AN000 */
        return;                                                         /* AN000 Return to caller*/
END     /* end parser */                                                /* AN000 */

/************************************************************************/                                                       /* ;an000; */
/* Parse_Message                - This routine will print only those    */
/*                                messages that require 1 replaceable   */
/*                                parm.                                 */
/*                                                                      */
/*      Inputs  : Msg_Num       - number of applicable message          */
/*                Handle        - display type                          */
/*                Message_Type  - type of message to display            */
/*                Replace_Parm  - pointer to parm to replace            */
/*                                                                      */
/*      Outputs : message                                               */
/*                                                                      */
/*      Date    : 03/28/88                                              */
/*      Version : DOS 4.00                                              */
/************************************************************************/

void Parse_msg(Msg_Num,Handle,Message_Type)                             /* AN010 */
                                                                        /* AN010 */
int             Msg_Num;                                                /* AN010 */
int             Handle;                                                 /* AN010 */
unsigned char   Message_Type;                                           /* AN010 */

BEGIN                                                                   /* AN010 */
char    far *Cmd_Ptr;                                                   /* AN010 */


        BEGIN                                                           /* AN010 */
        segread(&segregs);                                              /* AN010 */
        FP_SEG(Cmd_Ptr) = segregs.ds;                                   /* AN010 */
        FP_OFF(Cmd_Ptr) = regs.x.si;                                    /* AN010 */
        *Cmd_Ptr        = '\0';                                         /* AN010 */

        FP_SEG(sublistp[0].value) = segregs.ds;                         /* AN010 */
        FP_OFF(sublistp[0].value) = Parse_Ptr;                          /* AN010 */
        sublistp[0].size      = Sublist_Length;                         /* AN010 */
        sublistp[0].reserved  = Reserved;                               /* AN010 */
        sublistp[0].id        = 0;                                      /* AN010 */
        sublistp[0].flags     = Char_Field_ASCIIZ+Left_Align;           /* AN010 */
        sublistp[0].max_width = 80;                                     /* AN010 */
        sublistp[0].min_width = 01;                                     /* AN010 */
        sublistp[0].pad_char  = Blank;                                  /* AN010 */

        regs.x.ax = Msg_Num;                                            /* AN010 */
        regs.x.bx = Handle;                                             /* AN010 */
        regs.x.cx = SubCnt1;                                            /* AN010 */
        regs.h.dl = No_Input;                                           /* AN010 */
        regs.h.dh = Message_Type;                                       /* AN010 */
        regs.x.si = (unsigned int)&sublistp[0];                         /* AN010 */
        sysdispmsg(&regs,&regs);                                        /* AN010 */
        END                                                             /* AN010 */
        return;                                                         /* AN010 */
END                                                                     /* AN010 */

