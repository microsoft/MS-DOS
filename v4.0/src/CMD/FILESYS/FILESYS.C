/*  */
/*----------------------------------------------------------------------+
|                                                                       |
|       FILESYS provides an interface to IFSFUNC to allow assignment of |
|       logical drive letters to various devices.                       |
|                                                                       |
|       FILESYS also allows the user to cancel the attach for a drive   |
|       or device or list the currently attched devices.                |
|                                                                       |
|                                                                       |
|       ALIAS provides an interface to IFSFUNC that allows the user     |
|       to cause automatic substitution of an alternate filename string |
|       for a pseudo-device driver name.                                |
|                                                                       |
|       PROGRAM PROPERTY OF Microsoft, Copyright 1988 Microsoft Corp.   |
|                                                                       |
|  INPUT:                                                               |
|       Command line from user.                                         |
|                                                                       |
|  OUTPUT:                                                              |
|       Attached device, detached device, or  list of attached devices. |
|                                                                       |
+----------------------------------------------------------------------*/

#include "stdio.h"                                                                                                               /* ;an000; */
#include "stdlib.h"                                                                                                              /* ;an000; */
#include "dos.h"                /* allows use of intdos calls */                                                                 /* ;an000; */
#include "string.h"             /* allows use of str* calls */                                                                   /* ;an000; */
#include "parse.h"              /* allows use of parser */                                                                       /* ;an000; */
#include "msgret.h"             /* allows use of msg ret */                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
#define ZERO                    0                                                                                                /* ;an002; */
#define NULL                    0                                                                                                /* ;an000; */
#define FALSE                   0                                                                                                /* ;an000; */
#define TRUE                    1                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
#define MORE_DEVICES            0x0000  /* more devices in list */                                                               /* ;an000; */
#define NO_MORE_FILES           0x0012  /* no more files DOS error */                                                            /* ;an000; */
#define INVALID_FUNCTION_NUM    0x0001  /* invalid function - Get RDR list */                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
#define IFS_DEVICE              0X01    /* IFS device type */                                                                    /* ;an000; */
#define IFS_DRIVE               0X02    /* IFS drive type */                                                                     /* ;an000; */
#define NET_PRINTER             0x03    /* network printer device type */                                                        /* ;an000; */
#define NET_DRIVE               0x04    /* network drive device type  */                                                         /* ;an000; */
                                                                                                                                 /* ;an000; */
#define GET_PAUSE_STATUS        0x5f00  /* DOS call to get pause status */                                                       /* ;an000; */
#define GET_REDIR_LIST_ENTRY    0x5f02  /* DOS call to get redir entry */                                                        /* ;an000; */
#define REDIRECT_DEVICE         0x5f03  /* DOS call to redir device */                                                           /* ;an000; */
#define CANCEL_REDIRECTION      0x5f04  /* DOS call to cancel redirection */                                                     /* ;an000; */
#define GET_ATTACH_LIST         0x5f06  /* DOS call to get attached devices*/                                                    /* ;an000; */
#define GET_EXTENDED_ERROR      0x5900  /* DOS call to get extended error */                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
#define CARRY_FLAG              0x0001  /* mask for carry flag */                                                                /* ;an000; */
#define PARITY_FLAG             0x0004  /* mask for parity flag */                                                               /* ;an000; */
#define ACARRY_FLAG             0x0010  /* mask for aux carry flag */                                                            /* ;an000; */
#define ZERO_FLAG               0x0040  /* mask for zero flag */                                                                 /* ;an000; */
#define SIGN_FLAG               0x0080  /* mask for sign flag */                                                                 /* ;an000; */
#define TRAP_FLAG               0x0100  /* mask for trap flag */                                                                 /* ;an000; */
#define INTERRUPT_FLAG          0x0200  /* mask for interrupt flag */                                                            /* ;an000; */
#define DIRECTION_FLAG          0x0400  /* mask for direction flag */                                                            /* ;an000; */
#define OVERFLOW_FLAG           0x0800  /* mask for overflow flag */                                                             /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Define subroutines                                              */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
void    main(int, char *[]);                                                                                                     /* ;an000; */
void    parse_init(void);                                                                                                        /* ;an000; */
void    device_attach(int, char *, char *, char *);                                                                              /* ;an000; */
void    device_detach(char *);                                                                                                   /* ;an000; */
void    fs_status(char *);                                                                                                       /* ;an000; */
int     get_pause_stat(unsigned char);                                                                                           /* ;an000; */
void    fs_error(int);                                                                                                           /* ;an000; */
void    fs_build_print_message(int, char *, char *, char *);                                                                     /* ;an000; */
void    string_build(void);                                                                                                      /* ;an000; */
void    check_pause_status(unsigned char, int *, int *, int *);                                                                  /* ;an000; */
void    print_status(int, int, int, int *);                                                                                      /* ;an000; */
void    Sub0_Message(int,int,unsigned char);                                                                                     /* ;an000; */
void    fs_strcpy(char *, char far *);                                                                                           /* ;an000; */
int     fs_strlen(char far *);                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
extern  void    sysloadmsg(union REGS *, union REGS *);                                                                          /* ;an000; */
extern  void    sysdispmsg(union REGS *, union REGS *);                                                                          /* ;an000; */
extern  void    parse(union REGS *, union REGS *);                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
struct p_parms  p_p;                                                                                                             /* ;an000; */
struct p_parms  p_p1;                                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
struct p_parmsx p_px;                                                                                                            /* ;an000; */
struct p_parmsx p_px1;                                                                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
struct p_control_blk p_con1;                                                                                                     /* ;an000; */
struct p_control_blk p_con1a;                                                                                                    /* ;an000; */
struct p_control_blk p_con2;                                                                                                     /* ;an000; */
struct p_control_blk p_con3;                                                                                                     /* ;an000; */
struct p_control_blk p_con4;                                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
struct p_control_blk p_swt1;                                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
struct p_result_blk  p_result1;                                                                                                  /* ;an000; */
struct p_result_blk_D p_resultD;                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
struct p_value_blk   p_noval;                                                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
char    cmd_line[128];                                                                                                           /* ;an000; */
char    far *cmdline;                                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
  struct sublistx                                                               /* sublist for replaceable parms.       */       /* ;an000; */
  {                                                                                                                              /* ;an000; */
    unsigned char size;                                                         /* sublist size                         */       /* ;an000; */
    unsigned char reserved;                                                     /* reserved for future growth           */       /* ;an000; */
    unsigned far *value;                                                        /* pointer to replaceable parm          */       /* ;an000; */
    unsigned char id;                                                           /* type of replaceable parm             */       /* ;an000; */
    unsigned char flags;                                                        /* how parm is to be displayed          */       /* ;an000; */
    unsigned char max_width;                                                    /* max width of replaceable field       */       /* ;an000; */
    unsigned char min_width;                                                    /* min width of replaceable field       */       /* ;an000; */
    unsigned char pad_char;                                                     /* pad character for replaceable field  */       /* ;an000; */
  } sublist[4];                                                                 /* end of sublis                        */       /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
struct                                                                                                                           /* ;an000; */
        {                                                                                                                        /* ;an000; */
        char           *target_fs_name;                                                                                          /* ;an000; */
        unsigned int    target_count;                                                                                            /* ;an000; */
        char            target_string[128];                                                                                      /* ;an000; */
        } GAL_Target;                                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
struct                                                                                                                           /* ;an000; */
        {                                                                                                                        /* ;an000; */
        char            device_string[9];                                                                                        /* ;an000; */
        } GAL_Device;                                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
struct                                                                                                                           /* ;an000; */
        {                                                                                                                        /* ;an000; */
        char            *attach_system;        /* pointer to filesys arg */                                                      /* ;an000; */
        unsigned int    attach_parms_num;      /* number of additional parms */                                                  /* ;an000; */
        char            attach_addl_parms[128];/* additional parms */                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
        }       Attach_block;                                                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
/*----------------------------------------------------------------------+
|       define register variables                                       |
+----------------------------------------------------------------------*/
union REGS inregs, outregs;                                                                                                      /* ;an000; */
struct   SREGS   segregs;                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*----------------------------------------------------------------------+
|                                                                       |
|       main - filesys and alias main routine                           |
|                                                                       |
|       handle parsing command line and calling all other routines      |
|                                                                       |
+----------------------------------------------------------------------*/
                                                                                                                                 /* ;an000; */
void main(argc,argv)                                                                                                             /* ;an000; */
                                                                                                                                 /* ;an000; */
int     argc;                   /* number of arguments passed on command line */                                                 /* ;an000; */
char    *argv[];                /* array of pointer to arguments */                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
  {                                                                                                                              /* ;an000; */
/*----------------------------------------------------------------------+
|       define some local variables                                     |
+----------------------------------------------------------------------*/
  int   arg_index;              /* index used for stepping through args */                                                       /* ;an000; */
  int   more_arguments;         /* flag used while looping calls to parser */                                                    /* ;an000; */
  int   i;                      /* loop counter                         */                                                       /* ;an000; */
  int   detach_flag;            /* signal to detach device              */                                                       /* ;an000; */
  int   good_parse;             /* signal a good parse occurred         */                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
  char  *string_ptr;             /* pointer to a string                  */                                                      /* ;an000; */
  char  file_spec_buf[64];      /* buffer to hold drive or device name  */                                                       /* ;an000; */
  char  fs_name_buf[64];        /* buffer to hold file system name      */                                                       /* ;an000; */
  char  string_buf[128];        /* buffer to hold device parms          */                                                       /* ;an000; */
  char  drive_letter;           /* drive letter to attach/detach        */                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
/*----------------------------------------------------------------------+
|       get started by calling the parser                               |
+----------------------------------------------------------------------*/
                                                                                                                                 /* ;an000; */
  sysloadmsg(&inregs, &outregs);                                                /* load the messages                    */       /* ;an000; */
  if ((outregs.x.cflag & CARRY_FLAG) == CARRY_FLAG)                             /* error?                               */       /* ;an000; */
         sysdispmsg(&outregs,&outregs);                                         /* tell user error and exit             */       /* ;an000; */
  else                                                                          /* execute program                      */       /* ;an000; */
  {                                                                                                                              /* ;an000; */
        inregs.h.ah = (unsigned char) 0x62;                                                                                      /* ;an000; */
        intdosx(&inregs, &inregs, &segregs);                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
        FP_OFF(cmdline) = 0x81;                                                                                                  /* ;an000; */
        FP_SEG(cmdline) = inregs.x.bx;                                                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
        i = 0;                                                                                                                   /* ;an000; */
        while ( *cmdline != (char) '\x0d' ) cmd_line[i++] = *cmdline++;                                                          /* ;an000; */
        cmd_line[i++] = (char) '\x0d';                                                                                           /* ;an000; */
        cmd_line[i++] = (char) '\0';                                                                                             /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        file_spec_buf[0] = NULL;                                                                                                 /* ;an000; */
        string_ptr = Attach_block.attach_addl_parms;                                                                             /* ;an000; */
        detach_flag = FALSE;                                                                                                     /* ;an000; */
        good_parse  = TRUE;                                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
        parse_init();                                                                                                            /* ;an000; */
        inregs.x.si = (unsigned)cmd_line;                                                                                        /* ;an000; */
        inregs.x.cx = (unsigned)0;                                                                                               /* ;an000; */
        inregs.x.dx = (unsigned)0;                                                                                               /* ;an000; */
        inregs.x.di = (unsigned)&p_p;   /* point to drive spec block */                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
        i = 0;                                                                                                                   /* ;an000; */
        parse(&inregs,&outregs);                                                                                                 /* ;an000; */
        if (outregs.x.ax != p_no_error)                                                                                          /* ;an000; */
        {                                                                                                                        /* ;an000; */
                inregs.x.si = (unsigned)cmd_line;                                                                                /* ;an000; */
                inregs.x.cx = (unsigned)0;                                                                                       /* ;an000; */
                inregs.x.dx = (unsigned)0;                                                                                       /* ;an000; */
                inregs.x.di = (unsigned)&p_p1;  /* point to simple string block */                                               /* ;an000; */
                parse(&inregs,&outregs);                                                                                         /* ;an000; */
        }                                                                                                                        /* ;an000; */
        while ((outregs.x.ax == p_no_error) && (good_parse == TRUE))                                                             /* ;an000; */
        {                                                                                                                        /* ;an000; */
                i++;                                                                                                             /* ;an000; */
                if (p_resultD.D_Type == p_drive)                                                                                 /* ;an000; */
                {                                                                                                                /* ;an000; */
                        drive_letter = (char) p_resultD.D_Res_Drive + ('A'-1);                                                   /* ;an000; */
                        file_spec_buf[0] = drive_letter;                                                                         /* ;an000; */
                        file_spec_buf[1] = (char) ':';                                                                           /* ;an000; */
                        file_spec_buf[2] = (char) '\0';                                                                          /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                if ((p_result1.P_Type == p_string) && ( i == 1))                                                                 /* ;an000; */
                        fs_strcpy(file_spec_buf,p_result1.p_result_buff);                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                if ((p_result1.P_Type == p_string) && (i == 2))                                                                  /* ;an000; */
                        fs_strcpy(fs_name_buf,p_result1.p_result_buff);                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
                if ((p_result1.P_Type == p_string) && (i > 2))                                                                   /* ;an000; */
                {                                                                                                                /* ;an000; */
                        fs_strcpy(string_ptr,p_result1.p_result_buff);                                                           /* ;an000; */
                        string_ptr += fs_strlen(p_result1.p_result_buff);                                                        /* ;an000; */
                        string_ptr++;                                                                                            /* ;an000; */
                }                                                                                                                /* ;an000; */
                if (p_result1.P_SYNONYM_Ptr == (unsigned int)p_swt1.p_keyorsw)                                                   /* ;an000; */
                {                                                                                                                /* ;an000; */
                        if (i != 2)                     /* switch in wrong place */                                              /* ;an000; */
                        {                                                                                                        /* ;an000; */
                                outregs.x.ax = p_syntax; /* signal error type */                                                 /* ;an000; */
                                good_parse = FALSE;                                                                              /* ;an000; */
                        }                                                                                                        /* ;an000; */
                        detach_flag = TRUE;                                                                                      /* ;an000; */
                }                                                                                                                /* ;an000; */
                if (good_parse == TRUE)                                                                                          /* ;an000; */
                        parse(&outregs,&outregs);                                                                                /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (outregs.x.ax != p_rc_eol)                                           /* an000; dms; parse error              */       /* ;an000; */
        {                                                                                                                        /* ;an000; */
                Sub0_Message(outregs.x.ax,STDOUT,Parse_Err_Class);              /* an000; dms; tell user error          */       /* ;an000; */
                exit(1);                                                        /* an000; dms; exit program             */       /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        /* which routine to invoke?                                     */                                                       /* ;an000; */
        switch (i)                                                                                                               /* ;an000; */
                {                                                                                                                /* ;an000; */
                case    0: fs_status(file_spec_buf);                            /* an000; dms; no parms - status        */       /* ;an000; */
                           break;                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                case    1: fs_status(file_spec_buf);                            /* an000; dms; 1 parm - selective status*/       /* ;an000; */
                           break;                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                default  : if ((i == 2) && (detach_flag == TRUE))               /* an000; dms; detach request?          */       /* ;an000; */
                                device_detach(file_spec_buf);                   /* an000; dms; yes                      */       /* ;an000; */
                           else                                                                                                  /* ;an000; */
                                device_attach(i,file_spec_buf,fs_name_buf,string_buf);  /*an000; dms; attach request     */      /* ;an000; */
                           break;                                                                                                /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
       }                                     /* end FILESYS MAIN */                                                              /* ;an000; */
  }                                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*----------------------------------------------------------------------+
|                                                                       |
|  SUBROUTINE NAME:     PARSE_INIT                                      |
|                                                                       |
|  SUBROUTINE FUNCTION:                                                 |
|                                                                       |
|       This routine is called by the FILESYS MAIN routine to initialize|
|       the parser data structures.                                     |
|                                                                       |
|  INPUT:                                                               |
|       none                                                            |
|                                                                       |
|  OUTPUT:                                                              |
|       properly initialized parser control blocks                      |
|                                                                       |
+----------------------------------------------------------------------*/
void parse_init()                                                                                                                /* ;an000; */
  {                                                                                                                              /* ;an000; */
  p_p.p_parmsx_address    = &p_px;      /* address of extended parm list */                                                      /* ;an000; */
  p_p.p_num_extra         = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_p1.p_parmsx_address   = &p_px1;     /* address of extended parm list */                                                      /* ;an000; */
  p_p1.p_num_extra        = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_px.p_minp             = 0;                                                                                                   /* ;an000; */
  p_px.p_maxp             = 4;                                                                                                   /* ;an000; */
  p_px.p_control[0]       = &p_con1;                                                                                             /* ;an000; */
  p_px.p_control[1]       = &p_con2;                                                                                             /* ;an000; */
  p_px.p_control[2]       = &p_con3;                                                                                             /* ;an000; */
  p_px.p_control[3]       = &p_con4;                                                                                             /* ;an000; */
  p_px.p_maxswitch        = 1;                                                                                                   /* ;an000; */
  p_px.p_switch[0]        = &p_swt1;                                                                                             /* ;an000; */
  p_px.p_maxkeyword       = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_px1.p_minp            = 0;                                                                                                   /* ;an000; */
  p_px1.p_maxp            = 4;                                                                                                   /* ;an000; */
  p_px1.p_control[0]      = &p_con1a;                                                                                            /* ;an000; */
  p_px1.p_control[1]      = &p_con2;                                                                                             /* ;an000; */
  p_px1.p_control[2]      = &p_con3;                                                                                             /* ;an000; */
  p_px1.p_control[3]      = &p_con4;                                                                                             /* ;an000; */
  p_px1.p_maxswitch       = 1;                                                                                                   /* ;an000; */
  p_px1.p_switch[0]       = &p_swt1;                                                                                             /* ;an000; */
  p_px1.p_maxkeyword      = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_con1.p_match_flag     = p_drv_only+ p_ig_colon+ p_optional;                                                                  /* ;an000; */
  p_con1.p_function_flag  = p_cap_char+ p_rm_colon;                                                                              /* ;an000; */
  p_con1.p_result_buf     = (unsigned int)&p_resultD;                                                                            /* ;an000; */
  p_con1.p_value_list     = (unsigned int)&p_noval;                                                                              /* ;an000; */
  p_con1.p_nid            = 0;                                                                                                   /* ;an000; */
  p_con1.p_keyorsw[0]     = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_con1a.p_match_flag    = p_simple_s+ p_optional;                                                                              /* ;an000; */
  p_con1a.p_function_flag = p_cap_char;                                                                                          /* ;an000; */
  p_con1a.p_result_buf    = (unsigned int)&p_result1;                                                                            /* ;an000; */
  p_con1a.p_value_list    = (unsigned int)&p_noval;                                                                              /* ;an000; */
  p_con1a.p_nid           = 0;                                                                                                   /* ;an000; */
  p_con1a.p_keyorsw[0]    = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_con2.p_match_flag     = p_simple_s+ p_optional;                                                                              /* ;an000; */
  p_con2.p_function_flag  = p_cap_char;                                                                                          /* ;an000; */
  p_con2.p_result_buf     = (unsigned int)&p_result1;                                                                            /* ;an000; */
  p_con2.p_value_list     = (unsigned int)&p_noval;                                                                              /* ;an000; */
  p_con2.p_nid            = 0;                                                                                                   /* ;an000; */
  p_con2.p_keyorsw[0]     = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_con3.p_match_flag     = p_simple_s+ p_optional;                                                                              /* ;an000; */
  p_con3.p_function_flag  = p_cap_char;                                                                                          /* ;an000; */
  p_con3.p_result_buf     = (unsigned int)&p_result1;                                                                            /* ;an000; */
  p_con3.p_value_list     = (unsigned int)&p_noval;                                                                              /* ;an000; */
  p_con3.p_nid            = 0;                                                                                                   /* ;an000; */
  p_con3.p_keyorsw[0]     = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_con4.p_match_flag     = p_simple_s+ p_optional;                                                                              /* ;an000; */
  p_con4.p_function_flag  = p_cap_char;                                                                                          /* ;an000; */
  p_con4.p_result_buf     = (unsigned int)&p_result1;                                                                            /* ;an000; */
  p_con4.p_value_list     = (unsigned int)&p_noval;                                                                              /* ;an000; */
  p_con4.p_nid            = 0;                                                                                                   /* ;an000; */
  p_con4.p_keyorsw[0]     = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_swt1.p_match_flag     = p_none;                                                                                              /* ;an000; */
  p_swt1.p_function_flag  = p_cap_char;                                                                                          /* ;an000; */
  p_swt1.p_result_buf     = (unsigned int)&p_result1;                                                                            /* ;an000; */
  p_swt1.p_value_list     = (unsigned int)&p_noval;                                                                              /* ;an000; */
  p_swt1.p_nid            = 1;                                                                                                   /* ;an000; */
  strcpy(p_swt1.p_keyorsw,"/D"+NULL);                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_noval.p_val_num       = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_result1.P_Type        = 0;                                                                                                   /* ;an000; */
  p_result1.P_Item_Tag    = 0;                                                                                                   /* ;an000; */
  p_result1.P_SYNONYM_Ptr = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_resultD.D_Type        = 0;                                                                                                   /* ;an000; */
  p_resultD.D_Item_Tag    = 0;                                                                                                   /* ;an000; */
  p_resultD.D_SYNONYM_Ptr = 0;                                                                                                   /* ;an000; */
  p_resultD.D_Res_Drive   = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  return;                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
  }                                     /* end parse_init */                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*----------------------------------------------------------------------+
|                                                                       |
|  SUBROUTINE NAME:     DEVICE_ATTACH                                   |
|                                                                       |
|  SUBROUTINE FUNCTION:                                                 |
|                                                                       |
|       This routine is called by the FILESYS MAIN routine when it has  |
|       determined that a device attach request has been included       |
|       on the FILESYS command line.                                    |
|                                                                       |
|  INPUT:                                                               |
|       device to attach and ifs name                                   |
|                                                                       |
|  OUTPUT:                                                              |
|       None                                                            |
|                                                                       |
+----------------------------------------------------------------------*/
void device_attach(parm_cnt, drive_ptr, fs_name_ptr, parm_ptr)                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
        int     parm_cnt;                                                                                                        /* ;an000; */
        char    *drive_ptr;                                                                                                      /* ;an000; */
        char    *fs_name_ptr;                                                                                                    /* ;an000; */
        char    *parm_ptr;                                                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
  {                                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
  strcpy(GAL_Device.device_string,drive_ptr);                                                                                    /* ;an000; */
  Attach_block.attach_system = fs_name_ptr;                                                                                      /* ;an000; */
  Attach_block.attach_parms_num = parm_cnt - 2;                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
  if (strchr(drive_ptr,(char)':') != 0)                                                                                          /* ;an000; */
    inregs.h.bl = IFS_DRIVE;                                                                                                     /* ;an000; */
  else                                                                                                                           /* ;an000; */
    inregs.h.bl = IFS_DEVICE;                                                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
  inregs.x.ax = REDIRECT_DEVICE;        /* fcn code for redir device */                                                          /* ;an000; */
  inregs.x.si = (unsigned int) &GAL_Device;                                                                                      /* ;an000; */
  inregs.x.di = (unsigned int) &Attach_block;          /* point to dest */                                                       /* ;an000; */
  inregs.x.cx = 0;                      /* = 0 for network compat. */                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
  intdos(&inregs, &outregs);            /* make the call */                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
  if ((outregs.x.cflag & CARRY_FLAG) == CARRY_FLAG) fs_error(outregs.x.ax);                                                      /* ;an000; */
  return;                                                                                                                        /* ;an000; */
  }                                     /* end of device attach */                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*----------------------------------------------------------------------+
|                                                                       |
|  SUBROUTINE NAME:     DEVICE_DETACH                                   |
|                                                                       |
|  SUBROUTINE FUNCTION:                                                 |
|                                                                       |
|       This routine is called by the FILESYS MAIN routine when it has  |
|       determined that a device detach request has been included       |
|       on the FILESYS command line.                                    |
|                                                                       |
|  INPUT:                                                               |
|       device to detach                                                |
|                                                                       |
|  OUTPUT:                                                              |
|       None                                                            |
|                                                                       |
+----------------------------------------------------------------------*/
void device_detach(char *rd_source)          /* source for detach (e.g. LPT1:, E:) */                                            /* ;an000; */
  {                                                                                                                              /* ;an000; */
  inregs.x.ax = CANCEL_REDIRECTION;     /* fcn code for cancel redir */                                                          /* ;an000; */
  inregs.x.si = (unsigned int) rd_source;              /* point to source */                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
  intdos(&inregs, &outregs);            /* make the call */                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
  if ((outregs.x.cflag & CARRY_FLAG) == CARRY_FLAG) fs_error(outregs.x.ax);                                                      /* ;an000; */
  }                                     /* end of device detach */                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*----------------------------------------------------------------------+
|                                                                       |
|       fs_status - display attach or alias list                        |
|                                                                       |
|       Inputs  : name  - pointer to a specific device                  |
|                                                                       |
|       Outputs : status report of current attached state               |
|                                                                       |
+----------------------------------------------------------------------*/
void fs_status(char *name)                                                                                                       /* ;an000; */
  {                                                                                                                              /* ;an000; */
  int   redir_index;                    /* counter variable */                                                                   /* ;an000; */
  int   first_net_entry;                /* flag */                                                                               /* ;an000; */
  int   np_paused;                      /* flag */                                                                               /* ;an000; */
  int   nd_paused;                      /* flag */                                                                               /* ;an000; */
  int   entry_type;                     /* save the device entry type */                                                         /* ;an000; */
  int   error_type;                     /* save the device error type */                                                         /* ;an002; */
  int   message_type;                   /* value of message to build*/                                                           /* ;an000; */
  int   search_flag;                    /* flag */                                                                               /* ;an000; */
  int   header_flag;                    /* flag used to help decide if header should be displayed */                             /* ;an000; */
  char  fs_name_array[9];                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
  /* initialize some things */                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  GAL_Target.target_fs_name = (char *)fs_name_array;                                                                             /* ;an000; */
  redir_index           = 0;            /* always start with entry 0 */                                                          /* ;an000; */
  first_net_entry       = TRUE;         /* so we don't check for pause on */                                                     /* ;an000; */
                                        /* every net entry */                                                                    /* ;an000; */
  np_paused             = FALSE;        /* always assume NOT paused */                                                           /* ;an000; */
  nd_paused             = FALSE;                                                                                                 /* ;an000; */
  header_flag = FALSE;                  /* always initialze as false */                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (name[0] == NULL)                                                      /* an000; dms;specific device search?   */     /* ;an000; */
                                                                                                                                 /* ;an000; */
                search_flag = FALSE;                                            /* an000; dms;no                        */       /* ;an000; */
                                                                                                                                 /* ;an000; */
        else                                                                                                                     /* ;an000; */
                search_flag = TRUE;                                             /* an000; dms;yes                       */       /* ;an000; */
                                                                                                                                 /* ;an000; */
  /* search through redir list */                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        inregs.x.ax = GET_ATTACH_LIST;                                          /* an000; dms;get list of devices       */       /* ;an000; */
        inregs.x.bx = redir_index;                                              /* an000; dms;list entry number         */       /* ;an000; */
        inregs.x.si = (unsigned int)&GAL_Device;                                /* an000; dms;point to device buffer    */       /* ;an000; */
        inregs.x.di = (unsigned int)&GAL_Target;                                /* an000; dms;point to target buffer    */       /* ;an000; */
        intdos(&inregs,&outregs);                                               /* an000; dms;invoke call               */       /* ;an000; */
        while ((outregs.x.ax != NO_MORE_FILES) &&                                                                                /* ;an000; */
              ((outregs.x.cflag & CARRY_FLAG) != CARRY_FLAG))                                                                    /* ;an000; */
        {                                                                                                                        /* ;an000; */
                error_type = outregs.h.bh;                                      /* an000; drm;save error  type          */       /* ;an002; */
                entry_type = outregs.h.bl;                                      /* an000; dms;save device type          */       /* ;an000; */
                if (search_flag == TRUE)                                        /* an000; dms;specific device?          */       /* ;an000; */
                {                                                                                                                /* ;an000; */
                        if (strcmpi(GAL_Device.device_string,name) == 0)        /* an000; dms;found the device?         */       /* ;an000; */
                        {                                                                                                        /* ;an000; */
                                Sub0_Message(TITLE1,STDOUT,Utility_Msg_Class);  /* an000; dms; print header for status  */       /* ;an000; */
                                Sub0_Message(TITLE2,STDOUT,Utility_Msg_Class);                                                   /* ;an000; */
                                Sub0_Message(TITLE3,STDOUT,Utility_Msg_Class);                                                   /* ;an000; */
                                header_flag = TRUE;                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
                                check_pause_status(entry_type,                                                                   /* ;an001; */
                                                   &np_paused,                                                                   /* ;an000; */
                                                   &nd_paused,                                                                   /* ;an000; */
                                                   &first_net_entry);                                                            /* ;an000; */
                                string_build();                                 /* an000; dms;build string              */       /* ;an000; */
                                if (error_type != ZERO)
                                    message_type = ERROR_RDR_MSG;                                                                /* ;an002; */
                                else                                                                                             /* ;an002; */
                                    print_status(entry_type,                                                                     /* ;an000; */
                                                 np_paused,                                                                      /* ;an000; */
                                                 nd_paused,                                                                      /* ;an000; */
                                                 &message_type);                                                                 /* ;an000; */
                                fs_build_print_message(message_type,                                                             /* ;an000; */
                                              GAL_Device.device_string,                                                          /* ;an000; */
                                              GAL_Target.target_fs_name,                                                         /* ;an000; */
                                              GAL_Target.target_string);                                                         /* ;an000; */
                        }                                                                                                        /* ;an000; */
                }                                                                                                                /* ;an000; */
                else                                                                                                             /* ;an000; */
                {                                                                                                                /* ;an000; */
                        if (!header_flag)       /* logic to display headers only once */                                         /* ;an000; */
                        {                                                                                                        /* ;an000; */
                        Sub0_Message(TITLE1,STDOUT,Utility_Msg_Class);          /* an000; dms; print header for status  */       /* ;an000; */
                        Sub0_Message(TITLE2,STDOUT,Utility_Msg_Class);                                                           /* ;an000; */
                        Sub0_Message(TITLE3,STDOUT,Utility_Msg_Class);                                                           /* ;an000; */
                        header_flag = TRUE;                                                                                      /* ;an000; */
                        }                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                        check_pause_status(entry_type,                                                                           /* ;an001; */
                                           &np_paused,                                                                           /* ;an000; */
                                           &nd_paused,                                                                           /* ;an000; */
                                           &first_net_entry);                                                                    /* ;an000; */
                        string_build();                                         /* an000; dms;build string              */       /* ;an000; */
                        if (error_type != ZERO)
                            message_type = ERROR_RDR_MSG;                                                                        /* ;an002; */
                        else                                                                                                     /* ;an002; */
                            print_status(entry_type,                                                                             /* ;an000; */
                                         np_paused,                                                                              /* ;an000; */
                                         nd_paused,                                                                              /* ;an000; */
                                         &message_type);                                                                         /* ;an000; */
                        fs_build_print_message(message_type,                                                                     /* ;an000; */
                                       GAL_Device.device_string,                                                                 /* ;an000; */
                                       GAL_Target.target_fs_name,                                                                /* ;an000; */
                                       GAL_Target.target_string);                                                                /* ;an000; */
                }                                                                                                                /* ;an000; */
                redir_index++;                                                  /* an000; dms;next entry                */       /* ;an000; */
                inregs.x.ax = GET_ATTACH_LIST;                                  /* an000; dms;get list of devices       */       /* ;an000; */
                inregs.x.bx = redir_index;                                      /* an000; dms;list entry number         */       /* ;an000; */
                inregs.x.si = (unsigned int)&GAL_Device;                        /* an000; dms;point to device buffer    */       /* ;an000; */
                inregs.x.di = (unsigned int)&GAL_Target;                        /* an000; dms;point to target buffer    */       /* ;an000; */
                intdos(&inregs,&outregs);                                       /* an000; dms;invoke call               */       /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (header_flag == FALSE)                                                                                                /* ;an000; */
                Sub0_Message(NO_ENTRIES,STDOUT,Utility_Msg_Class);                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
        return;                                                                                                                  /* ;an000; */
}                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*----------------------------------------------------------------------+
|                                                                       |
|  get_pause_stat - check the pause status of network printing or disk  |
|       redirection.                                                    |
|                                                                       |
+----------------------------------------------------------------------*/
get_pause_stat (unsigned char type)                                                                                              /* ;an000; */
  {                                                                                                                              /* ;an000; */
  int   return_flag;                 /* flag to return paused status */                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
  inregs.x.ax = GET_PAUSE_STATUS;                                                                                                /* ;an000; */
  inregs.h.bl = type;                                                                                                            /* ;an000; */
  intdos(&inregs, &outregs);                                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
  if (outregs.h.bh == 0) return_flag = TRUE;                                                                                     /* ;an000; */
  else return_flag = FALSE;                                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
  return(return_flag);                                                                                                           /* ;an000; */
  }                                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*----------------------------------------------------------------------+
|                                                                       |
|  SUBROUTINE NAME:     FS_ERROR                                        |
|                                                                       |
|  SUBROUTINE FUNCTION:                                                 |
|                                                                       |
|       This routine is called to handle any error conditions that      |
|       are detected by the FILESYS routines.                           |
|                                                                       |
|  INPUT:                                                               |
|       Error code (word)                                               |
|                                                                       |
|  OUTPUT:                                                              |
|       The corresponding error message is displayed on the screen.     |
|       (STDERR)                                                        |
|                                                                       |
+----------------------------------------------------------------------*/
void fs_error(int error_ax)                                                          /* error_ax holds error code            */  /* ;an000; */
                                                                                                                                 /* ;an000; */
  {                                                                                                                              /* ;an000; */
        inregs.x.ax = GET_EXTENDED_ERROR;                                       /* get the extended error               */       /* ;an000; */
        inregs.x.bx = NULL;                                                     /* clear bx to signal > DOS 3.0         */       /* ;an000; */
        intdos(&inregs, &outregs);                                              /* INT 21h call                         */       /* ;an000; */
                                                                                                                                 /* ;an000; */
        inregs.x.ax = outregs.x.ax;                                             /* get extended error in AX             */       /* ;an000; */
        inregs.x.bx = STDERR;                                                   /* output to standard error             */       /* ;an000; */
        inregs.x.cx = SubCnt0;                                                  /* no replaceables                      */       /* ;an000; */
        inregs.h.dl = No_Input;                                                 /* no keyboard input                    */       /* ;an000; */
        inregs.h.dh = Ext_Err_Class;                                            /* extended error class                 */       /* ;an000; */
        sysdispmsg(&inregs,&outregs);                                           /* display the message                  */       /* ;an000; */
                                                                                                                                 /* ;an000; */
     return;                                                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
  }                                                                             /* end of fs_error                      */       /* ;an000; */
                                                                                                                                 /* ;an000; */
/*=======================================================================*/                                                      /* ;an000; */
/* FS_Build_Print_Message:This routine builds the applicable message and */                                                      /* ;an000; */
/*                        prints it.                                     */                                                      /* ;an000; */
/*      Input   : Msg_Num       - The message number of the applicable   */                                                      /* ;an000; */
/*                                message                                */                                                      /* ;an000; */
/*      Output  : The printed message                                    */                                                      /* ;an000; */
/*                                                                       */                                                      /* ;an000; */
/*=======================================================================*/                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
void fs_build_print_message(msg_num, outline1, outline2, outline3)                                                               /* ;an000; */
int             msg_num;                                                                                                         /* ;an000; */
char            *outline1;                                                                                                       /* ;an000; */
char            *outline2;                                                                                                       /* ;an000; */
char            *outline3;                                                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
{                                                                                                                                /* ;an000; */
  unsigned status;                                                                                                               /* ;an000; */
  unsigned char function;                                                       /* type of input function               */       /* ;an000; */
  unsigned char msg_class;                                                                                                       /* ;an000; */
  unsigned int message,                                                         /* message number                       */       /* ;an000; */
               sub_cnt,                                                         /* num. of replaceable parameters       */       /* ;an000; */
               handle;                                                          /* display handle                       */       /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
  switch (msg_num)                                                              /* what message do we have?             */       /* ;an000; */
  {                                                                                                                              /* ;an000; */
    case PAUSE_RDR_MSG:  function  = No_Input;                                  /* no keyboard input                    */       /* ;an000; */
                         message   = PAUSE_RDR_MSG;                             /* message %1 REDIR %2 PAUSED           */       /* ;an000; */
                         msg_class = Utility_Msg_Class;                         /* utility message                      */       /* ;an000; */
                         sub_cnt   = SubCnt3;                                   /* 2 replaceable parms                  */       /* ;an000; */
                         handle    = STDOUT;                                    /* display to standard out              */       /* ;an000; */
                         break;                                                 /* end case statement                   */       /* ;an000; */
                                                                                                                                 /* ;an000; */
    case REDIR_MSG    :  function  = No_Input;                                  /* no keyboard input                    */       /* ;an000; */
                         message   = REDIR_MSG;                                 /* message - %1 REDIR %2                */       /* ;an000; */
                         msg_class = Utility_Msg_Class;                         /* utility message                      */       /* ;an000; */
                         sub_cnt   = SubCnt3;                                   /* 2 replaceable parms                  */       /* ;an000; */
                         handle    = STDOUT;                                    /* display to standard out              */       /* ;an000; */
                         break;                                                 /* end case statement                   */       /* ;an000; */

    case ERROR_RDR_MSG:  function  = No_Input;                                  /* no keyboard input                    */       /* ;an002; */
                         message   = ERROR_RDR_MSG;                             /* message %1 REDIR %2 ERROR            */       /* ;an002; */
                         msg_class = Utility_Msg_Class;                         /* utility message                      */       /* ;an002; */
                         sub_cnt   = SubCnt3;                                   /* 2 replaceable parms                  */       /* ;an002; */
                         handle    = STDOUT;                                    /* display to standard out              */       /* ;an002; */
                         break;                                                 /* end case statement                   */       /* ;an002; */
  }                                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
  switch(msg_num)                                                               /* what message number to print?        */       /* ;an000; */
  {                                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
    case ERROR_RDR_MSG  :                                                       /* message to print                     */       /* ;an002; */
    case PAUSE_RDR_MSG  :                                                       /* message to print                     */       /* ;an000; */
    case REDIR_MSG      : sublist[1].value     = (unsigned far *)outline1;      /* point to parm 1                      */       /* ;an000; */
                          sublist[1].size      = Sublist_Length;                /* length of sublist                    */       /* ;an000; */
                          sublist[1].reserved  = Reserved;                      /* reserved for future growth           */       /* ;an000; */
                          sublist[1].id        = 1;                             /* number of replaceable parm           */       /* ;an000; */
                          sublist[1].flags     = Char_Field_ASCIIZ+Left_Align;  /* string input data                    */       /* ;an000; */
                          sublist[1].max_width = 5;                             /* default max width - unlimited        */       /* ;an000; */
                          sublist[1].min_width = 5;                             /* min width of 1                       */       /* ;an000; */
                          sublist[1].pad_char  = Blank;                         /* pad with blanks                      */       /* ;an000; */
                                                                                                                                 /* ;an000; */
                          sublist[2].value     = (unsigned far *)outline2;      /* point to parm 2                      */       /* ;an000; */
                          sublist[2].size      = Sublist_Length;                /* length of sublist                    */       /* ;an000; */
                          sublist[2].reserved  = Reserved;                      /* reserved for future growth           */       /* ;an000; */
                          sublist[2].id        = 2;                             /* number of replaceable parm           */       /* ;an000; */
                          sublist[2].flags     = Char_Field_ASCIIZ+Left_Align;  /* string input data                    */       /* ;an000; */
                          sublist[2].max_width = 9;                             /* default max width - unlimited        */       /* ;an000; */
                          sublist[2].min_width = 9;                             /* min width of 1                       */       /* ;an000; */
                          sublist[2].pad_char  = Blank;                         /* pad with blanks                      */       /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                          sublist[3].value     = (unsigned far *)outline3;                                                       /* ;an000; */
                          sublist[3].size      = Sublist_Length;                /* length of sublist                    */       /* ;an000; */
                          sublist[3].reserved  = Reserved;                      /* reserved for future growth           */       /* ;an000; */
                          sublist[3].id        = 3;                             /* number of replaceable parm           */       /* ;an000; */
                          sublist[3].flags     = Char_Field_ASCIIZ+Left_Align;  /* string input data                    */       /* ;an000; */
                          sublist[3].max_width = 0;                             /* default max width - unlimited        */       /* ;an000; */
                          sublist[3].min_width = 1;                             /* min width of 1                       */       /* ;an000; */
                          sublist[3].pad_char  = Blank;                         /* pad with blanks                      */       /* ;an000; */
                                                                                                                                 /* ;an000; */
                          inregs.x.ax = message;                                /* put message number in AX             */       /* ;an000; */
                          inregs.x.bx = handle;                                 /* put handle in BX                     */       /* ;an000; */
                          inregs.x.si = (unsigned int)&sublist[1];              /* put sublist pointer in SI            */       /* ;an000; */
                          inregs.x.cx = sub_cnt;                                /* put sublist count in CX              */       /* ;an000; */
                          inregs.h.dl = function;                               /* put function type in DL              */       /* ;an000; */
                          inregs.h.dh = msg_class;                              /* put message class in DH              */       /* ;an000; */
                          sysdispmsg(&inregs,&outregs);                         /* display the message                  */       /* ;an000; */
                          break;                                                /* end case statement                   */       /* ;an000; */
  }                                                                                                                              /* ;an000; */
        return;                                                                                                                  /* ;an000; */
}                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* STRING_BUILD         - This routine takes a buffer filled with       */                                                       /* ;an000; */
/*                        multiple ASCIIZ strings and concatenates them */                                                       /* ;an000; */
/*                        into one string by convering all null chars.  */                                                       /* ;an000; */
/*                        to a blank.                                   */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  - GAL_Target  (struct)                                  */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs - converted buffer                                      */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void string_build()                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
{                                                                                                                                /* ;an000; */
        int     x;                                                                                                               /* ;an000; */
        int     i;                                                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
        x = 0;                                                                  /* an000; dms;index pointer             */       /* ;an000; */
        i = 0;                                                                  /* an000; dms;loop counter              */       /* ;an000; */
        while (i != GAL_Target.target_count)                                    /* an000; dms;while strings exist       */       /* ;an000; */
        {                                                                                                                        /* ;an000; */
                while (GAL_Target.target_string[x] != NULL)                     /* an000; dms;while not end of string   */       /* ;an000; */
                        x++;                                                    /* an000; dms;increment pointer         */       /* ;an000; */
                GAL_Target.target_string[x] = Blank;                            /* an000; dms;blank terminate string    */       /* ;an000; */
                x++;                                                            /* an000; dms;increment pointer         */       /* ;an000; */
                i++;                                                            /* an000; dms;next string               */       /* ;an000; */
        }                                                                                                                        /* ;an000; */
        GAL_Target.target_string[x] = NULL;                                     /* an000; null terminate buffer         */       /* ;an000; */
        return;                                                                                                                  /* ;an000; */
}                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* CHECK_PAUSE_STATUS   - This routine determines if the net drive or   */                                                       /* ;an000; */
/*                        printer is paused.                            */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  : regbl         - contents of register BL               */                                                       /* ;an000; */
/*                dr_pause      - driver pause flag                     */                                                       /* ;an000; */
/*                pr_pause      - printer pause flag                    */                                                       /* ;an000; */
/*                net_flag      - signals 1st. occurrence               */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : dr_pause      - flag set appropriately                */                                                       /* ;an000; */
/*                pr_pause      - flag set appropriately                */                                                       /* ;an000; */
/*                net_flag      - flag set appropriately                */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void check_pause_status(regbl, pr_pause, dr_pause, net_flag)                                                                     /* ;an001; */
                                                                                                                                 /* ;an000; */
        unsigned char   regbl;                                                                                                   /* ;an000; */
        int             *dr_pause;                                                                                               /* ;an000; */
        int             *pr_pause;                                                                                               /* ;an000; */
        int             *net_flag;                                                                                               /* ;an000; */
{                                                                                                                                /* ;an000; */
        if (((regbl == NET_PRINTER) ||                                          /* an000; dms; if net drive or printer  */       /* ;an000; */
           (regbl == NET_DRIVE)) &&                                                                                              /* ;an001; */
           (*net_flag == TRUE))                                                                                                  /* ;an001; */
        {                                                                                                                        /* ;an000; */
                *net_flag = FALSE;                                               /* an000; dms; set flag to false        */      /* ;an001; */
                *pr_pause = get_pause_stat(NET_PRINTER);                         /* an000; dms; see if printer paused    */      /* ;an000; */
                *dr_pause = get_pause_stat(NET_DRIVE);                           /* an000; dms; see if drive paused      */      /* ;an000; */
        }                                                                                                                        /* ;an000; */
        return;                                                                                                                  /* ;an000; */
}                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* PRINT_STATUS         - This routine determines the type of print     */                                                       /* ;an000; */
/*                        message that is to be used.                   */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  : entry_type    - type of device                        */                                                       /* ;an000; */
/*                np_paused     - flag                                  */                                                       /* ;an000; */
/*                nd_paused     - flag                                  */                                                       /* ;an000; */
/*                message_type  - type of message to print              */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : message_type  - message type to be printed            */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void print_status(entry_type, np_paused, nd_paused, message_type)                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        int     entry_type;                                                                                                      /* ;an000; */
        int     np_paused;                                                                                                       /* ;an000; */
        int     nd_paused;                                                                                                       /* ;an000; */
        int     *message_type;                                                                                                   /* ;an000; */
{                                                                                                                                /* ;an000; */
        if ((entry_type == NET_PRINTER) && (np_paused == TRUE))                                                                  /* ;an000; */
                *message_type = PAUSE_RDR_MSG;                                                                                   /* ;an000; */
        else                              /* printing not paused, try disk redir */                                              /* ;an000; */
        {                                                                                                                        /* ;an000; */
                if ((entry_type == NET_DRIVE) && (nd_paused == TRUE))                                                            /* ;an000; */
                        *message_type = PAUSE_RDR_MSG;                                                                           /* ;an000; */
                else                                                                                                             /* ;an000; */
                        *message_type = REDIR_MSG;                                                                               /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (entry_type == NET_PRINTER)            /* always want to add ":" to LPTx */                                           /* ;an000; */
                strncat(GAL_Device.device_string,":",1);                                                                         /* ;an000; */
                                                                                                                                 /* ;an000; */
        return;                                                                                                                  /* ;an000; */
}                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* SUB0_MESSAGE                 - This routine will print only those    */                                                       /* ;an000; */
/*                                messages that do not require a        */                                                       /* ;an000; */
/*                                a sublist.                            */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  : Msg_Num       - number of applicable message          */                                                       /* ;an000; */
/*                Handle        - display type                          */                                                       /* ;an000; */
/*                Message_Type  - type of message to display            */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : message                                               */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void Sub0_Message(Msg_Num,Handle,Message_Type)                                       /* print messages with no subs          */  /* ;an000; */
                                                                                                                                 /* ;an000; */
int             Msg_Num;                                                                                                         /* ;an000; */
int             Handle;                                                                                                          /* ;an000; */
unsigned char   Message_Type;                                                                                                    /* ;an000; */
                                                                                /*     extended, parse, or utility      */       /* ;an000; */
        {                                                                                                                        /* ;an000; */
        inregs.x.ax = Msg_Num;                                                  /* put message number in AX             */       /* ;an000; */
        inregs.x.bx = Handle;                                                   /* put handle in BX                     */       /* ;an000; */
        inregs.x.cx = No_Replace;                                               /* no replaceable subparms              */       /* ;an000; */
        inregs.h.dl = No_Input;                                                 /* no keyboard input                    */       /* ;an000; */
        inregs.h.dh = Message_Type;                                             /* type of message to display           */       /* ;an000; */
        sysdispmsg(&inregs,&outregs);                                          /* display the message                  */        /* ;an000; */
                                                                                                                                 /* ;an000; */
        return;                                                                                                                  /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* FS_STRCPY            - This routine will provide the string copy     */                                                       /* ;an000; */
/*                        capability for a far pointer.                 */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  : buffer        - pointer to the destination            */                                                       /* ;an000; */
/*                parse_ptr     - far pointer to source                 */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : buffer        - new string                            */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void fs_strcpy(buffer, parse_ptr)                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        char            *buffer;                                                                                                 /* ;an000; */
        char far        *parse_ptr;                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
        {                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                while ((*buffer = *parse_ptr) != NULL)                                                                           /* ;an000; */
                {                                                                                                                /* ;an000; */
                        buffer++;                                                                                                /* ;an000; */
                        parse_ptr++;                                                                                             /* ;an000; */
                }                                                                                                                /* ;an000; */
        return;                                                                                                                  /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* FS_STRLEN            - This routine calculates the string's length.  */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  : parse_ptr     - pointer to the string to measure      */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : i             - string's length                       */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
int  fs_strlen(parse_ptr)                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        char far        *parse_ptr;                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
        {                                                                                                                        /* ;an000; */
        int     i;                                                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
                for (i = 0; *parse_ptr != NULL; parse_ptr++)                                                                     /* ;an000; */
                        i++;                                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
                return(i);                                                                                                       /* ;an000; */
        }                                                                                                                        /* ;an000; */
