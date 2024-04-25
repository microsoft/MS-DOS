/* 0 */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*    Utility Name:     ATTRIB.EXE                                           */
/*                                                                           */
/*    Source File Name: ATTRIB.C                                             */
/*                                                                           */
/*    Utility Function:                                                      */
/*                                                                           */
/*       Allows you to set or reset the Archive bit, the Read-Only bit and   */
/*       the Extended Attributes.  Also allows you to display the current    */
/*       setting of those attributes.                                        */
/*                                                                           */
/*    Status:           ATTRIB Utility, DOS Version 4.0                      */
/*                                                                           */
/*    Entry Point: inmain(line)                                              */
/*                                                                           */
/*    Input:       line = DOS command line parameters                        */
/*                                                                           */
/*    Exit-normal: attribute set, or attribute printed to output device      */
/*                                                                           */
/*    Exit-error:  error message written to standard error device            */
/*                                                                           */
/*    Internal References:                                                   */
/*                                                                           */
/*      Routines:                                                            */
/*                                                                           */
/*    External References:                                                   */
/*                                                                           */
/*       Routines:                                                           */
/*              parse()          module=_parse.sal                           */
/*              sysloadmsg()     module=_msgret.sal                          */
/*              sysdispmsg()     module=_msgret.sal                          */
/*              getpspbyte()     module=new_c.sal                            */
/*              putpspbyte()     module=new_c.sal                            */
/*              segread()        module=dos.h(C library)                     */
/*              intdosx()        module=dos.h(C library)                     */
/*              intdos()         module=dos.h(C library)                     */
/*                                                                           */
/*    Notes:                                                                 */
/*    Syntax (Command Line)                                                  */
/*                                                                           */
/*  ATTRIB [+R|-R] [+A|-A] [d:][path]filename[.ext] [[id]|[id=value]] [/S]   */
/*                                                                           */
/*            where:                                                         */
/*                                                                           */
/*                 +R = Make file ReadOnly by setting READONLY bit           */
/*                 -R = Reset READONLY bit                                   */
/*                 +A = Set ARCHIVE bit                                      */
/*                 -A = Reset ARCHIVE bit                                    */
/*                                                                           */
/*                 id = Set or display the extended attribute named by id.   */
/*                      Only one id processed per invocation. id can be *.   */
/*                                                                           */
/*                 /S = Process subdirectories also                          */
/*                                                                           */
/*    Copyright 1988 Microsoft Corporation				     */
/*                                                                           */
/*    Revision History:                                                      */
/*                                                                           */
/*               Modified 6/22/87   v. 4.0			             */
/*               Rewritten 9/28/87   v. 4.0 		      - AN000	     */
/*                        - fixed check for "." & ".."        - AN001        */
/*               PTM 3195 - changed Extended attribute MSGs   - AN002        */
/*               PTM 3588 - Do C exit not DOS exit.           - AN003        */
/*               PTM 3783 - Fix for hang problem.             - AN004        */
/*                                                                           */
/*   NOTE:                                                                   */
/*     When extended attributes are added back in, make sure you change the  */
/*     attrib.skl file back to the original DOS 4.0 ext. attr. error msgs.   */
/*                                                                           */
/*     Also, this C program requires a special lib when linking to take care */
/*     of the fact that the c lib saves the DOS environment on the heap and  */
/*     if the environment is > 32k, STACK OVERFLOW will occur.               */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

#include <stdio.h>                                                     /*;AN000;*/
#include <io.h>                                                        /*;AN000;*/
#include <dos.h>                                                       /*;AN000;*/
#include <string.h>                                                    /*;AN000;*/
#include "parse.h"                                                     /*;AN000;*/
#include "msgret.h"                                                    /*;AN000;*/
#include "attrib.h"                                                    /*;AN000;*/

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/* Beginning of code (variables declared in attrib.h)                        */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

/*
 * inmain() - This routine receives control from an assembler routine and from
 *            here, main is called. This routine first parses the command line
 *            and then does the appropriate action.
 */
inmain(line)                                                           /*;AN000;*/
   char *line;                                                         /*;AN000;*/
{                                                                      /*;AN000;*/
   main(line);                                                         /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     main()                                           */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Parse the command line, makes a full path-filename, does the       */
/*        appropriate function                                               */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

main(line)                                                             /*;AN000;*/
   char *line;                                                         /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD status;                                                        /*;AN000;*/

   WORD Parse_it();         /* forward declaration */                  /*;AN000;*/
   WORD Make_fspec();       /*   "         "       */                  /*;AN000;*/
   WORD Do_dir();           /*   "         "       */                  /*;AN000;*/
   void Error_exit();       /*   "         "       */                  /*;AN000;*/
   void Parse_err();        /*   "         "       */                  /*;AN000;*/

   /* initialize control variables */
   status = NOERROR;                                                   /*;AN000;*/
   descending = FALSE;                                                 /*;AN000;*/
   set_reg_attr = FALSE;                                               /*;AN000;*/
   pmask = mmask = 0x0;                                                /*;AN000;*/
   ext_attr[0] = BLANK;                                                /*;AN000;*/
   file[0] = '\0';                                                     /*;AN000;*/
   error_file_name[0] = '\0';                                          /*;AN000;*/

   /* load messages */
   sysloadmsg(&inregs,&outregs);                                       /*;AN000;*/
   if (outregs.x.cflag & CARRY) {                                      /*;AN000;*/
      sysdispmsg(&outregs,&outregs);                                   /*;AN000;*/
      Dexit(11);                                                       /*;AN000;*/
      }

   Check_appendx();        /* check APPEND /X status */                /*;AN000;*/
   Get_DBCS_vector();      /* get double byte table */                 /*;AN000;*/

   /* parse command line */
   status = Parse_it(line);                                            /*;AN000;*/
   if (status != NOERROR) {                                            /*;AN000;*/
      Parse_err(status);                                               /*;AN000;*/
      }                                                                /*;AN000;*/

   /* Do extended attribute translations here */
   Ext_translation();                                                  /*;AN000;*/


   /* Initialize any variables need for next phase of program */
   segread(&segregs);     /* init segment registers for DOS calls */   /*;AN000;*/

   /* make full filespec (drive + full path + filename) */
   strcpy(error_file_name,fspec);                                      /*;AN000;*/
   status = Make_fspec(fspec);                                         /*;AN000;*/
   if (status == NOERROR) {                                            /*;AN000;*/

      /* now do the work! */
      did_attrib_ok = FALSE;  /* needed if file not found and no */    /*;AN000;*/
                              /* error detected in Attrib().     */
      status = Do_dir(fspec,file);                                     /*;AN000;*/
      if (status == NOERROR && did_attrib_ok == FALSE)                 /*;AN000;*/
         status = FILENOTFOUND;                                        /*;AN000;*/
      }                                                                /*;AN000;*/

   /* determine if there was an error after attempt to do attrib function */
   /* NOTE: for ext. attr. calls, add 200 to the return code to get the   */
   /* ----  error code for this switch.                                   */
   switch(status) { /* Extended error codes */                         /*;AN000;*/
      case 0:                                                          /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 2:       /* File not found */                               /*;AN000;*/
             Error_exit(ERR_EXTENDED,2,ONEPARM);                       /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 3:       /* Path not found */                               /*;AN000;*/
             Error_exit(ERR_EXTENDED,3,ONEPARM);                       /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 5:       /* Access Denied */                                /*;AN000;*/
             Error_exit(ERR_EXTENDED,5,ONEPARM);                       /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 15:      /* Invalid drive specification */                  /*;AN000;*/
             Error_exit(ERR_EXTENDED,15,ONEPARM);                      /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 199:     /* EA error: undetermined cause */                 /*;AN000;*/
             strcpy(error_file_name,ext_attr);                         /*;AN000;*/
             Error_exit(ERR_EXTENDED,87,ONEPARM);                      /*;AN000;*/
             /* Display_msg(199,STDERR,NOSUBPTR,NOSUBCNT,NOINPUT);        /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 201:     /* EA error: name not found */                     /*;AN000;*/
             strcpy(error_file_name,ext_attr);                         /*;AN000;*/
             Error_exit(ERR_EXTENDED,87,ONEPARM);                      /*;AN000;*/
             /* Display_msg(201,STDERR,NOSUBPTR,NOSUBCNT,NOINPUT);        /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 202:     /* EA error: no space to hold name or value */     /*;AN000;*/
             strcpy(error_file_name,ext_attr);                         /*;AN000;*/
             Error_exit(ERR_EXTENDED,87,ONEPARM);                      /*;AN000;*/
             /* Display_msg(202,STDERR,NOSUBPTR,NOSUBCNT,NOINPUT);        /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 203:     /* EA error: name can't be set on this function */ /*;AN000;*/
             strcpy(error_file_name,ext_attr);                         /*;AN000;*/
             Error_exit(ERR_EXTENDED,87,ONEPARM);                      /*;AN000;*/
             /* Display_msg(204,STDERR,NOSUBPTR,NOSUBCNT,NOINPUT);        /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 204:     /* EA error: name can't be set */                  /*;AN000;*/
             strcpy(error_file_name,ext_attr);                         /*;AN000;*/
             Error_exit(ERR_EXTENDED,87,ONEPARM);                      /*;AN000;*/
             /* Display_msg(204,STDERR,NOSUBPTR,NOSUBCNT,NOINPUT);        /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 205:     /* EA error: name known to this FS but not supported */ /*;AN000;*/
             strcpy(error_file_name,ext_attr);                         /*;AN000;*/
             Error_exit(ERR_EXTENDED,87,ONEPARM);                      /*;AN000;*/
             /* Display_msg(205,STDERR,NOSUBPTR,NOSUBCNT,NOINPUT);        /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 206:     /* EA error: EA definition bad (type, length, etc.) */ /*;AN000;*/
             strcpy(error_file_name,ext_attr);                         /*;AN000;*/
             Error_exit(ERR_EXTENDED,87,ONEPARM);                      /*;AN000;*/
             /* Display_msg(206,STDERR,NOSUBPTR,NOSUBCNT,NOINPUT);        /*;AN000;*/
             break;                                                    /*;AN000;*/
      case 208:     /* EA error: EA value not supported */             /*;AN000;*/
             strcpy(error_file_name,ext_attr);                         /*;AN000;*/
             Error_exit(ERR_EXTENDED,87,ONEPARM);                      /*;AN000;*/
             /* Display_msg(208,STDERR,NOSUBPTR,NOSUBCNT,NOINPUT);        /*;AN000;*/
             break;                                                    /*;AN000;*/
      default:      /* Access Denied */                                /*;AN000;*/
             Error_exit(ERR_EXTENDED,5,ONEPARM);                       /*;AN000;*/
             break;                                                    /*;AN000;*/
      }                                                                /*;AN000;*/
   Reset_appendx();                                                    /*;AN000;*/



}  /* end of inmain */                                                 /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*    Subroutine Name: Display_msg                                           */
/*                                                                           */
/*    Subroutine Function:                                                   */
/*       Display the requested message to a given output device              */
/*                                                                           */
/*    Input:                                                                 */
/*        (1) Number of the message to be displayed (see ATTRIB.SKL)         */
/*        (2) Output device handle                                           */
/*        (3) Number of substitution parameters (%1,%2)                      */
/*        (4) Offset of sublist control block                                */
/*        (5) Message Class, 0=no input, 1=input via INT 21 AH=1             */
/*                                                                           */
/*    Output:                                                                */
/*        The message is written to the given output device.  If input       */
/*        was requested, the character code of the key pressed is returned   */
/*        in outregs.x.ax.                                                   */
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
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Display_msg(msgnum,msghan,msgparms,msgsub,msginput)                    /*;AN000;*/
   int   msgnum;                                                       /*;AN000;*/
   int   msghan;                                                       /*;AN000;*/
   int   msgparms;                                                     /*;AN000;*/
   int   *msgsub;                                                      /*;AN000;*/
   char  msginput;                                                     /*;AN000;*/
{
   inregs.x.ax = msgnum;                                               /*;AN000;*/
   inregs.x.bx = msghan;                                               /*;AN000;*/
   inregs.x.cx = msgparms;                                             /*;AN000;*/
   inregs.h.dh = utility_msg_class;                                    /*;AN000;*/
   inregs.h.dl = msginput;                                             /*;AN000;*/
   inregs.x.si = (WORD)msgsub;                                         /*;AN000;*/
   sysdispmsg(&inregs,&outregs);                                       /*;AN000;*/

   /* check for error printing message */
   if (outregs.x.cflag & CARRY) {                                      /*;AN000;*/
      outregs.x.bx = (WORD) STDERR;                                    /*;AN000;*/
      outregs.x.si = NOSUBPTR;                                         /*;AN000;*/
      outregs.x.cx = NOSUBCNT;                                         /*;AN000;*/
      outregs.h.dl = exterr_msg_class;                                 /*;AN000;*/
      sysdispmsg(&outregs,&outregs);                                   /*;AN000;*/
      }                                                                /*;AN000;*/
}


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Ext_translation()                                */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        This routine does all translation of extended attribute names to   */
/*        the form that will be returned by Get_ext_attr_names(). For        */
/*        example, "CODEPAGE" would be translated to "CP".                   */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Ext_translation()                                                      /*;AN000;*/
{                                                                      /*;AN000;*/
   if (strcmp(ext_attr,"CODEPAGE") == 0) {                             /*;AN000;*/
      strcpy(ext_attr,"CP");                                           /*;AN000;*/
      }                                                                /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Get_far_str()                                    */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        copies a filename from source to the target. The source is offset  */
/*        from the code segment instead of the data segment.                 */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: target = source                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Get_far_str(target,source,length)                                      /*;AN000;*/
   char *target;                                                       /*;AN000;*/
   DWORD *source;               /* segment = cs register */            /*;AN000;*/
   WORD  length;                                                       /*;AN000;*/
{                                                                      /*;AN000;*/
   char far *fptr;                                                     /*;AN000;*/
   WORD i;                                                             /*;AN000;*/

   if (length == 0) {                                                  /*;AN000;*/

      /* copy string in data segment */
      for (fptr = (char far *) *((DWORD *)source);(char)*fptr != NUL;) /*;AN000;*/
         *target++ = (char) *fptr++;                                   /*;AN000;*/
      *target = *fptr;  /*EOS character */                             /*;AN000;*/
      }                                                                /*;AN000;*/
   else {

      /* copy string in data segment */
      for (fptr = (char far *) *((DWORD *)source),i=0;i < length;i++)  /*;AN000;*/
         *target++ = (char) *fptr++;                                   /*;AN000;*/
      *target = 0x0;    /*EOS character */                             /*;AN000;*/
      }
   strcpy(fix_es_reg,NUL); /* fix for es reg. after using far ptr */   /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Dexit()                                          */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Does a DOS terminate.                                              */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: target = source                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Dexit(s)                                                               /*;AN000;*/
   WORD  s;                                                            /*;AN000;*/
{                                                                      /*;AN000;*/
   Reset_appendx();             /* Reset APPEND /X status */           /*;AN000;*/

/* inregs.h.ah = (BYTE)0x4c;                                           /*;AN003; ;AN000;*/
/* inregs.h.al = (BYTE)s;                                              /*;AN003; ;AN000;*/
/* intdos(&inregs,&outregs);        /*terminate*/                      /*;AN003; ;AN000;*/

   /* if it didn't work - kill it */
   exit();                                                             /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Dallocate()                                      */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Does a DOS allocate of length (in paragraphs).                     */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: target = source                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD *Dallocate(s)                                                     /*;AN000;*/
   WORD s;       /* length in bytes */                                 /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD length;  /*length in paragraphs */                             /*;AN000;*/

   length = (s / 16 + 1);                                              /*;AN000;*/
   inregs.x.bx = length;                                               /*;AN000;*/
   inregs.x.ax = 0x4800;                                               /*;AN000;*/
   intdos(&inregs,&outregs);                                           /*;AN000;*/
   if (outregs.x.cflag & CARRY) {                                      /*;AN000;*/
      Error_exit(ERR_EXTENDED,8,NOSUBCNT);                             /*;AN000;*/
      }                                                                /*;AN000;*/
   return((WORD *)outregs.x.ax);                                       /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Dfree()                                          */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Does a DOS de-allocate.                                            */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: target = source                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Dfree(segment)                                                         /*;AN000;*/
   WORD segment;                                                       /*;AN000;*/
{                                                                      /*;AN000;*/
   segregs.es = segment;                                               /*;AN000;*/
   inregs.x.ax = 0x4900;                                               /*;AN000;*/
   intdosx(&inregs,&outregs,&segregs);                                 /*;AN000;*/
   if (outregs.x.cflag & CARRY) {                                      /*;AN000;*/
      Error_exit(ERR_EXTENDED,8,NOSUBCNT);                             /*;AN000;*/
      }                                                                /*;AN000;*/
   strcpy(fix_es_reg,NUL); /* fix for es reg. after using far ptr */   /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Copy_far_ptr()                                   */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Copies a far ptr declared in any form to a real far ptr variable.  */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: status = NOERROR                                          */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Copy_far_ptr(p1_addr, p2_addr)                                         /*;AN000;*/
   DWORD *p1_addr;                                                     /*;AN000;*/
   WORD  *p2_addr;                                                     /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD  *dptr, *tptr;                                                 /*;AN000;*/

   dptr = (WORD *)p2_addr;                                             /*;AN000;*/
   tptr = (WORD *)p1_addr;                                             /*;AN000;*/

   *tptr++ = *dptr++;                                                  /*;AN000;*/
   *tptr = *dptr;                                                      /*;AN000;*/
   strcpy(fix_es_reg,NUL);       /* fix ES register */                 /*;AN000;*/
}                                                                      /*;AN000;*/

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Parse_it()                                       */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Parses the command line and returns error status.                  */
/*                                                                           */
/*    Input:  line                                                           */
/*                                                                           */
/*    Output: various control variables are set                              */
/*                                                                           */
/*    Normal exit: status = NOERROR                                          */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Parse_it(line)                                                    /*;AN000;*/
   char *line;                                                         /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD  i;                                                            /*;AN000;*/
   WORD  status;                                                       /*;AN000;*/
   WORD  no_value;                                                     /*;AN000;*/
   WORD  got_fn;         /* got filename - required parameter */       /*;AN000;*/
   WORD  pa,                                                           /*;AN000;*/
         ma,                                                           /*;AN000;*/
         pr,                                                           /*;AN000;*/
         mr;                                                           /*;AN000;*/
   char far *cptr;                                                     /*;AN000;*/
   char *ptr;                                                          /*;AN000;*/
   BYTE  p_mask[4],                                                    /*;AN000;*/
         m_mask[4];                                                    /*;AN000;*/
   char  string[129];                                                  /*;AN000;*/

   /* do setup for parser */
   for (i=0; i<4; i++) {                                               /*;AN000;*/
      p_mask[i] = m_mask[i] = 0;                                       /*;AN000;*/
      }                                                                /*;AN000;*/
   do_reg_attr = TRUE;                                                 /*;AN000;*/
   do_ext_attr = FALSE;                                                /*;AN000;*/
   set_reg_attr = FALSE;                                               /*;AN000;*/
   set_ext_attr = FALSE;                                               /*;AN000;*/
   no_value = TRUE;            /* no value found for keyword */        /*;AN000;*/
   got_fn = FALSE;             /* no filename yet */                   /*;AN000;*/

   inregs.x.si = (WORD)line;      /* Make DS:SI point to source */     /*;AN000;*/
   inregs.x.cx = 0;               /* Operand ordinal */                /*;AN000;*/
   inregs.x.di = (WORD)&p_p1;     /* Address of parm list */           /*;AN000;*/
   status = p_no_error;           /* Init no error condition */        /*;AN000;*/

   /* loop until error or end_of_line */
   while (status == p_no_error) {                                      /*;AN000;*/
      parse(&inregs,&outregs);                                         /*;AN000;*/
      status = outregs.x.ax;       /* get error status */              /*;AN000;*/

      /* check for errors, continue if none */
      if (status == p_no_error) {                                      /*;AN000;*/

         /* check if first positional */
         if (outregs.x.dx == (WORD)&pos1_buff) {                       /*;AN000;*/
            if (*(char *)pos1_buff.p_result_buff[0] == '+')  {         /*;AN000;*/
               p_mask[0] |= pos1_buff.p_item_tag;                      /*;AN000;*/
               }                                                       /*;AN000;*/
            else {                                                     /*;AN000;*/
               m_mask[0] |= pos1_buff.p_item_tag;                      /*;AN000;*/
               }                                                       /*;AN000;*/
            set_reg_attr = TRUE;                                       /*;AN000;*/
            do_reg_attr = FALSE;                                       /*;AN000;*/
            }                                                          /*;AN000;*/

         /* check if second positional */
         if (outregs.x.dx == (WORD)&pos2_buff) {                       /*;AN000;*/
            if (*(char *)pos2_buff.p_result_buff[0] == '+') {          /*;AN000;*/
               p_mask[1] |= pos2_buff.p_item_tag;                      /*;AN000;*/
               }                                                       /*;AN000;*/
            else {                                                     /*;AN000;*/
               m_mask[1] |= pos2_buff.p_item_tag;                      /*;AN000;*/
               }                                                       /*;AN000;*/
            set_reg_attr = TRUE;                                       /*;AN000;*/
            do_reg_attr = FALSE;                                       /*;AN000;*/
            }                                                          /*;AN000;*/

         /* check if third positional */
         if (outregs.x.dx == (WORD)&pos3_buff) {                       /*;AN000;*/

            /* copy filename from far string to data segment string */
            Get_far_str(fspec,pos3_buff.p_result_buff,0);              /*;AN000;*/
            got_fn = TRUE;                                             /*;AN000;*/
            }                                                          /*;AN000;*/

         /* check if fourth positional */
         if (outregs.x.dx == (WORD)&pos4_buff) {                       /*;AN000;*/
            if (*(char *)pos4_buff.p_result_buff[0] == '+')  {         /*;AN000;*/
               p_mask[2] |= pos4_buff.p_item_tag;                      /*;AN000;*/
               }                                                       /*;AN000;*/
            else {                                                     /*;AN000;*/
               m_mask[2] |= pos4_buff.p_item_tag;                      /*;AN000;*/
               }                                                       /*;AN000;*/
            set_reg_attr = TRUE;                                       /*;AN000;*/
            do_reg_attr = FALSE;                                       /*;AN000;*/
            }                                                          /*;AN000;*/

         /* check if fifth positional */
         if (outregs.x.dx == (WORD)&pos5_buff) {                       /*;AN000;*/
            if (*(char *)pos5_buff.p_result_buff[0] == '+') {          /*;AN000;*/
               p_mask[3] |= pos5_buff.p_item_tag;                      /*;AN000;*/
               }                                                       /*;AN000;*/
            else {                                                     /*;AN000;*/
               m_mask[3] |= pos5_buff.p_item_tag;                      /*;AN000;*/
               }                                                       /*;AN000;*/
            set_reg_attr = TRUE;                                       /*;AN000;*/
            do_reg_attr = FALSE;                                       /*;AN000;*/
            }                                                          /*;AN000;*/

         /* check if sixth positional */
         if (outregs.x.dx == (WORD)&pos6_buff) {                       /*;AN000;*/

            /* copy attribute name from far string to data segment string */
            Get_far_str(ext_attr,pos6_buff.p_result_buff,0);           /*;AN000;*/
            do_ext_attr = TRUE;                                        /*;AN000;*/
            do_reg_attr = FALSE;                                       /*;AN000;*/
            }                                                          /*;AN000;*/

         /* check if value of sixth positional */
         if (outregs.x.dx == (WORD)&pos6b_buff) {                      /*;AN000;*/

            /* parse a value that is complex (in parenthesis). */
            if (pos6b_buff.p_type == p_complex) {                      /*;AN000;*/

               /* Parse the complex and concatenate it together */
               inregs.x.cx = 0;       /* reset ordinal count */        /*;AN000;*/
               status = p_no_error;                                    /*;AN000;*/
               while (status != p_rc_eol) {                            /*;AN000;*/
                  parse(&inregs,&outregs);                             /*;AN000;*/
                  status = outregs.x.ax;       /* get error status */  /*;AN000;*/
                  if (status != p_no_error) {                          /*;AN000;*/
                     status = p_syntax;                                /*;AN000;*/
                     break;                                            /*;AN000;*/
                     }                                                 /*;AN000;*/
                  Get_far_str(string,pos6b_buff.p_result_buff,0);      /*;AN000;*/
                  strcat(ext_attr_value.ea_ascii,string);              /*;AN000;*/
                  inregs.x.si = outregs.x.si; /* update SI for parser */ /*;AN000;*/
                  }                                                    /*;AN000;*/
               status = p_no_error;                                    /*;AN000;*/
               ext_attr_value_type = EAISASCII;                        /*;AN000;*/
               }                                                       /*;AN000;*/
            else                                                       /*;AN000;*/
               Determine_type((WORD)pos6b_buff.p_type,pos6b_buff.p_result_buff); /*;AN000;*/
            set_ext_attr = TRUE;                                       /*;AN000;*/
            do_reg_attr = FALSE;                                       /*;AN000;*/
            do_ext_attr = FALSE;                                       /*;AN000;*/
            no_value = TRUE;      /* found a value for keyword */      /*;AN000;*/
            }                                                          /*;AN000;*/

         /* check for '/S' switch */
         if (outregs.x.dx == (WORD)&sw_buff) {                         /*;AN000;*/

            /* check if duplicate switch */
            if (descending == TRUE) {                                  /*;AN000;*/
                status = p_syntax;                                     /*;AN000;*/
                }                                                      /*;AN000;*/
            descending = TRUE;                                         /*;AN000;*/
            }                                                          /*;AN000;*/
         }     /* if no error */                                       /*;AN000;*/

      /* error, check if this is first positional, if so try again */
      /* using the second positional beacause they are optional    */
      else if (inregs.x.cx == 0 || inregs.x.cx == 1 ||                 /*;AN000;*/
               inregs.x.cx == 3 || inregs.x.cx == 4) {                 /*;AN000;*/
         inregs.x.cx++;    /* try next positional */                   /*;AN000;*/

         /* Check for a filename beginning with '+' because parser will drop */
         /* the plus sign anyways, and we need to flag it as an error        */
         for(ptr=(char *)inregs.x.si; *ptr == ' '; ptr++)              /*;AN000;*/
            /* NULL statement */ ;                                     /*;AN000;*/
         if (*ptr == '+')                                              /*;AN000;*/
            status = p_syntax;                                         /*;AN000;*/
         else                                                          /*;AN000;*/
            status = p_no_error;                                       /*;AN000;*/
         strcpy(fix_es_reg,NUL);                                       /*;AN000;*/

         continue;  /* go back up to while loop */                     /*;AN000;*/
         }                                                             /*;AN000;*/

      /* Check for keyword (an attribute name - fourth positional) */
      else if (status == p_not_in_key) {                               /*;AN000;*/
         inregs.x.di = (WORD)&p_p2;   /* change control blocks to */   /*;AN000;*/
                                      /* be able to parse the keyword */
         inregs.x.cx = 0;       /* reset ordinal count */              /*;AN000;*/
         status = p_no_error;                                          /*;AN000;*/
         no_value = FALSE;   /* got keyword and equal sign */          /*;AN000;*/
         continue;                                                     /*;AN000;*/
         }                                                             /*;AN000;*/

      if (status == p_no_error) {                                      /*;AN000;*/
         inregs.x.cx = outregs.x.cx;       /* update CX for parser */  /*;AN000;*/
         inregs.x.si = outregs.x.si;       /* update SI for parser */  /*;AN000;*/
         }                                                             /*;AN000;*/
      }   /* while loop */                                             /*;AN000;*/

   /* check error status and if at end of line */
   if (status == p_rc_eol) {                                           /*;AN000;*/
      status = p_no_error;                                             /*;AN000;*/
      }                                                                /*;AN000;*/

   /* Check for filename on command line */
   if (!got_fn && status == p_no_error) {                              /*;AN000;*/
      status = p_op_missing;                                           /*;AN000;*/
      }                                                                /*;AN000;*/

   /* Check for keyword and equal sign but no value */
   if (!no_value) {                                                    /*;AN000;*/
      status = p_syntax;                                               /*;AN000;*/
      }                                                                /*;AN000;*/

   /* check for duplicate +R +R or +A +A or -A -A or -R -R */
   for (pr=0,mr=0,pa=0,ma=0,i=0; i<4; i++) {                           /*;AN000;*/
      if (p_mask[i] & READONLY)                                        /*;AN000;*/
         pr++;                                                         /*;AN000;*/
      if (m_mask[i] & READONLY)                                        /*;AN000;*/
         mr++;                                                         /*;AN000;*/
      if (p_mask[i] & ARCHIVE)                                         /*;AN000;*/
         pa++;                                                         /*;AN000;*/
      if (m_mask[i] & ARCHIVE)                                         /*;AN000;*/
         ma++;                                                         /*;AN000;*/
      }                                                                /*;AN000;*/
   if ((pr > 1) || (mr > 1) || (pa > 1) || (ma > 1)) {                 /*;AN000;*/
      status = p_syntax;                                               /*;AN000;*/
      }                                                                /*;AN000;*/
   else {                                                              /*;AN000;*/
      for (pmask=0,mmask=0,i=0; i<4; i++) {                            /*;AN000;*/
         pmask |= p_mask[i];                  /* combine masks */      /*;AN000;*/
         mmask |= m_mask[i];                                           /*;AN000;*/
         }                                                             /*;AN000;*/
      }                                                                /*;AN000;*/

   /* check for duplicate -R +R or -A +A */
   if ((pmask & mmask & READONLY) || (pmask & mmask & ARCHIVE)) {      /*;AN000;*/
      status = p_syntax;                                               /*;AN000;*/
      }                                                                /*;AN000;*/
   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Determine_type()                                 */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Determines the type of the new value of an attribute being set by  */
/*        the user in terms of extended attribute types.                     */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: target = source                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Determine_type(parser_type,result_ptr)                                 /*;AN000;*/
   WORD parser_type;                                                   /*;AN000;*/
   WORD *result_ptr;                                                   /*;AN000;*/
{                                                                      /*;AN000;*/
   DWORD number;                                                       /*;AN000;*/
   char string[129];                                                   /*;AN000;*/

   switch(parser_type) {                                               /*;AN000;*/
      case p_number:                                                   /*;AN000;*/
         ext_attr_value_type = EAISBINARY;                             /*;AN000;*/
         number = (DWORD)*(DWORD *)result_ptr;                         /*;AN000;*/
         if (number > 0xffff) {                                        /*;AN000;*/
            ext_attr_value.ea_bin.length = 4;                          /*;AN000;*/
            ext_attr_value.ea_bin.dword = number;                      /*;AN000;*/
            }                                                          /*;AN000;*/
         else if (number > 0xff) {                                     /*;AN000;*/
            ext_attr_value.ea_bin.length = 2;                          /*;AN000;*/
            ext_attr_value.ea_bin.dword = number;                      /*;AN000;*/
            }                                                          /*;AN000;*/
         else {                                                        /*;AN000;*/
            ext_attr_value.ea_bin.length = 1;                          /*;AN000;*/
            ext_attr_value.ea_bin.dword = number;                      /*;AN000;*/
            }                                                          /*;AN000;*/
         break;                                                        /*;AN000;*/

      case p_complex:                                                  /*;AN000;*/

         /* Taken care of in Parse_it() */
         break;                                                        /*;AN000;*/

      case p_string:                                                   /*;AN000;*/
      case p_quoted_string:                                            /*;AN000;*/
         Get_far_str(string,result_ptr,0);                             /*;AN000;*/

         /* is the type EAISLOGICAL or EAISASCII */
         if (strcmp(string,"ON") == 0) {                               /*;AN000;*/
            ext_attr_value.ea_logical = TRUE;                          /*;AN000;*/
            ext_attr_value_type = EAISLOGICAL;                         /*;AN000;*/
            }                                                          /*;AN000;*/
         else if (strcmp(string,"OFF") == 0) {                         /*;AN000;*/
            ext_attr_value.ea_logical = FALSE;                         /*;AN000;*/
            ext_attr_value_type = EAISLOGICAL;                         /*;AN000;*/
            }                                                          /*;AN000;*/
         else {                                                        /*;AN000;*/
            strcpy(ext_attr_value.ea_ascii,string);                    /*;AN000;*/
            ext_attr_value_type = EAISASCII;                           /*;AN000;*/
            }                                                          /*;AN000;*/
         break;                                                        /*;AN000;*/

      default:                                                         /*;AN000;*/
         ext_attr_value_type = EAISUNDEF;                              /*;AN000;*/
         ext_attr_value.ea_undef = TRUE;                               /*;AN000;*/
         break;                                                        /*;AN000;*/
      }                                                                /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Make_fspec()                                     */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Makes a full path-filename from the filename & current directory   */
/*        information.                                                       */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Make_fspec(fspec)                                                 /*;AN000;*/
   char *fspec;                                                        /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD Check_DBCS();       /* forward declaration */                  /*;AN000;*/

   char path[256];                                                     /*;AN000;*/
   WORD status;                                                        /*;AN000;*/
   WORD i,j;                                                           /*;AN000;*/

   status = NOERROR;                                                   /*;AN000;*/

   strcpy(path,fspec);                                                 /*;AN000;*/

   /* Check if user did not enter a drive letter */
   if (fspec[1] != ':') {                                              /*;AN000;*/
      inregs.x.ax = 0x1900;         /* Get current drive */            /*;AN000;*/
      intdos(&inregs,&outregs);                                        /*;AN000;*/
      fspec[0] = 'A' + (outregs.x.ax & 0xff);                          /*;AN000;*/
      fspec[1] = ':';                                                  /*;AN000;*/
      fspec[2] = NUL;                                                  /*;AN000;*/
      strcat(fspec,path);                                              /*;AN000;*/
      }                                                                /*;AN000;*/

   /* Check if user didn't enter a path in filename */
   if (!Check_DBCS(fspec,2,'\\')) {                                    /*;AN000;*/
      strcpy(path,&fspec[2]);                                          /*;AN000;*/
      fspec[2] = '\\';                                                 /*;AN000;*/
      inregs.x.ax = 0x4700;            /* Get current directory */     /*;AN000;*/
      inregs.x.si = (WORD)(&fspec[3]);                                 /*;AN000;*/
      inregs.h.dl = fspec[0] - 'A' +1;                                 /*;AN000;*/
      intdos(&inregs,&outregs);                                        /*;AN000;*/
      status = outregs.x.ax;                                           /*;AN000;*/

      if (!(outregs.x.cflag & CARRY)) {                                /*;AN000;*/
         status = NOERROR;                                             /*;AN000;*/
         if (!Check_DBCS(fspec,strlen(fspec)-1,'\\'))                  /*;AN000;*/
            strcat(fspec,"\\");                                        /*;AN000;*/
         strcat(fspec,path);                                           /*;AN000;*/
         }                                                             /*;AN000;*/
      }                                                                /*;AN000;*/

   /* seperate the file specification into path and filename */
   for (i=strlen(fspec);(i>=0) && (!Check_DBCS(fspec,i,'\\')); i--)    /*;AN000;*/
      /* null statement */ ;                                           /*;AN000;*/
   i++;                                                                /*;AN000;*/
   j = 0;                                                              /*;AN000;*/
   while (fspec[i+j] != '\0') {                                        /*;AN000;*/
      file[j] = fspec[i+j];                                            /*;AN000;*/
      fspec[i+j] = '\0';                                               /*;AN000;*/
      j++;                                                             /*;AN000;*/
      }                                                                /*;AN000;*/
   file[j] = '\0';                                                     /*;AN000;*/

   /* Check for filenames of: . (current dir) .. (parent dir) */
   if (strcmp(file,".") == 0)                                          /*;AN001;*/
      strcpy(file,"*.*");                                              /*;AN001;*/
   else if (strcmp(file,"..") == 0) {                                  /*;AN001;*/
      strcat(fspec,"..\\");                                            /*;AN001;*/
      strcpy(file,"*.*");                                              /*;AN001;*/
      }

   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Dta_save()                                       */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*                  saves an area in the PSP, but who knows.                 */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Dta_save(t,l)
   char   *t;
   unsigned l;
{
   unsigned i;

   for (i = 0; i < l; i++) *(t+i) = getpspbyte(0x80+i)
      /* null statement */  ;
 }


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Dta_restore()                                    */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*              Restores the data that was saved in Dta_save().              */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: target = source                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Dta_restore(t,l)
   char     *t;
   unsigned l;
{
   unsigned i;

   for (i = 0; i < l; i++) putpspbyte(0x80+i,*(t+i))
      /* null statement */  ;
}


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Find_first()                                     */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Find_first(s,f,a)
   char  *s;
   char  *f;
   WORD  *a;
{
   WORD  status;
   WORD  i;
   WORD  o;
   char  *t;

   t = f;
   *f = '\0';

   inregs.x.ax = 0x4e00;             /* DOS find first */
   inregs.x.cx = (*a & 0x00ff );
   inregs.x.dx = (WORD)s;
   intdos(&inregs,&outregs);
   status = outregs.x.ax;

   /* Check for no errors */
   if (!(outregs.x.cflag & CARRY)) {
      for (i = 0; i < 14; i++)
          *f++ = getpspbyte(0x80+30+i);
      *a = getpspbyte(0x80+21);
      status = NOERROR;
      }
   return(status);
}


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Find_next()                                      */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Find_next(f,a)
   char  *f;
   WORD  *a;
{
   WORD  status;
   WORD  i;
   WORD  o;
   char  *t;

   t = f;
   *f = '\0';

   inregs.x.ax = 0x4f00;          /* DOS find next */
   intdos(&inregs,&outregs);
   status = outregs.x.ax;

   if (!(outregs.x.cflag & CARRY)) {
      for (i = 0; i < 14; i++)
          *f++ = getpspbyte(0x80+30+i);
      *a = getpspbyte(0x80+21);
      status = NOERROR;
      }
   return(status);
}


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Get_reg_attrib()                                 */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*          Does a DOS get attribute byte.                                   */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: return = 0                                                */
/*                                                                           */
/*    Error exit: return = error code                                        */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Get_reg_attrib(fspec,attr_byte)                                   /*;AN000;*/
   char *fspec;                                                        /*;AN000;*/
   BYTE *attr_byte;                                                    /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD status;                                                        /*;AN000;*/

   inregs.x.ax = (WORD)0x4300;                                         /*;AN000;*/
   inregs.x.dx = (WORD)fspec;                                          /*;AN000;*/
   intdos(&inregs,&outregs);                                           /*;AN000;*/
   status = outregs.x.ax;                                              /*;AN000;*/

   /* Check for error */                                               /*;AN000;*/
   if (!(outregs.x.cflag & CARRY)) {                                   /*;AN000;*/
      *attr_byte = (BYTE)outregs.h.cl;                                 /*;AN000;*/
      status = NOERROR;                                                /*;AN000;*/
      }                                                                /*;AN000;*/
   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Ext_open()                                       */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*          Does a DOS extended open of a filename and returns a file handle.*/
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: handle = file handle, return = 0                          */
/*                                                                           */
/*    Error exit: handle = ?; return = error code                            */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Ext_open(fspec,handle)                                            /*;AN000;*/
   char *fspec;                                                        /*;AN000;*/
   WORD *handle;                                                       /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD status;                                                        /*;AN000;*/

   inregs.x.ax = (WORD)0x6c00;                                         /*;AN000;*/
   inregs.x.bx = (WORD)0x80;                                           /*;AN000;*/
   inregs.x.cx = (WORD)0x0;                                            /*;AN000;*/
   inregs.x.dx = (WORD)0x0101;                                         /*;AN000;*/
   inregs.x.si = (WORD)fspec;                                          /*;AN000;*/
   inregs.x.di = (WORD)&plist;                                         /*;AN000;*//*;AN000;*/
   intdos(&inregs,&outregs);                                           /*;AN000;*/
   status = outregs.x.ax;                                              /*;AN000;*/

   /* Check for error */                                               /*;AN000;*/
   if (!(outregs.x.cflag & CARRY)) {                                   /*;AN000;*/
      *handle = outregs.x.ax;                                          /*;AN000;*/
      status = NOERROR;                                                /*;AN000;*/
      }                                                                /*;AN000;*/
   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Get_ext_attrib()                                 */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*          Does a DOS Get extended attributes and returns far ptr to list.  */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: handle = file handle, return = 0                          */
/*                                                                           */
/*    Error exit: handle = ?; return = error code                            */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Get_ext_attrib(handle,list_ptr,qlist_ptr)                         /*;AN000;*/
   WORD handle;                                                        /*;AN000;*/
   WORD far **list_ptr;   /* ptr to far ptr to list returned */        /*;AN000;*/
   WORD *qlist_ptr;       /* query list */                             /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD status;                                                        /*;AN000;*/
   WORD attr_size;                                                     /*;AN000;*/
   WORD *list_seg;                                                     /*;AN000;*/
   WORD *ptr;                                                          /*;AN000;*/

   /* get size of attribute list */                                    /*;AN000;*/
   inregs.x.bx = handle;                                               /*;AN000;*/
   inregs.x.ax = 0x5702;       /* Get extended attributes*/            /*;AN000;*/
   inregs.x.si = (WORD)qlist_ptr;   /* query one attribute */          /*;AN000;*/
   inregs.x.cx = (WORD)0;      /* just get size of return buffer */    /*;AN000;*/
   intdos(&inregs,&outregs);                                           /*;AN000;*/
   status = outregs.x.ax;                                              /*;AN000;*/

   /* if no errors then get extended attributes */
   if (!(outregs.x.cflag & CARRY)) {                                   /*;AN000;*/
      attr_size = outregs.x.cx;                                        /*;AN000;*/

      /* allocate buffer space for extended attr. list */
      /* uses MAX_ATTR_SIZE if possible so that buffer can be used */
      /* to set the largest attribute possible                     */
      if (attr_size > MAX_ATTR_SIZE)                                   /*;AN000;*/
          list_seg = Dallocate(attr_size);                             /*;AN000;*/
      else                                                             /*;AN000;*/
          list_seg = Dallocate(MAX_ATTR_SIZE);                         /*;AN000;*/

      /* get extended attributes */
      inregs.x.bx = handle;                                            /*;AN000;*/
      inregs.x.ax = 0x5702;       /* Get extended attributes */        /*;AN000;*/
      inregs.x.si = (WORD)qlist_ptr;   /* query one attribute */       /*;AN000;*/
      inregs.x.di = (WORD)0x0;    /* return buffer offset */           /*;AN000;*/
      inregs.x.cx = attr_size;    /* size to get all attributes */     /*;AN000;*/
      segregs.es = (WORD)list_seg; /* segment of ea list to return */  /*;AN000;*/
      intdosx(&inregs,&outregs,&segregs);                              /*;AN000;*/
      strcpy(fix_es_reg,NUL);    /* restores original ES reg. value */ /*;AN000;*/
      status = outregs.x.ax;                                           /*;AN000;*/

      /* if no errors then fix up far pointer to list */
      if (!(outregs.x.cflag & CARRY)) {                                /*;AN000;*/

         /* convert segment returned from Dallocate to far ptr */
         *list_ptr = 0;                                                /*;AN000;*/
         ptr = (WORD *)list_ptr;                                       /*;AN000;*/
         ptr++;                                                        /*;AN000;*/
         *ptr = (WORD)list_seg;                                        /*;AN000;*/
         (*list_ptr)++;                                                /*;AN000;*/
         strcpy(fix_es_reg,NUL);  /* restores ES register value */     /*;AN000;*/
         status = NOERROR;                                             /*;AN000;*/
         }                                                             /*;AN000;*/
      }                                                                /*;AN000;*/
   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Get_ext_attr_names()                             */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*          Does a DOS Get extended attribute names and return a far ptr to  */
/*          the querylist of names.                                          */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: handle = file handle, return = 0                          */
/*                                                                           */
/*    Error exit: handle = ?; return = error code                            */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Get_ext_attr_names(handle,list_ptr,num_entries)                   /*;AN000;*/
   WORD handle;                                                        /*;AN000;*/
   WORD far **list_ptr;   /* ptr to far ptr to list returned */        /*;AN000;*/
   WORD *num_entries;     /* number of entries in list */              /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD status;                                                        /*;AN000;*/
   WORD attr_size;                                                     /*;AN000;*/
   WORD *list_seg;                                                     /*;AN000;*/
   WORD *ptr;                                                          /*;AN000;*/

   /* get size of attribute name list */                               /*;AN000;*/
   inregs.x.bx = handle;                                               /*;AN000;*/
   inregs.x.ax = 0x5703;       /* Get extended attribute names */      /*;AN000;*/
   inregs.x.cx = (WORD)0;      /* just get size of return buffer */    /*;AN000;*/
   intdos(&inregs,&outregs);                                           /*;AN000;*/
   status = outregs.x.ax;                                              /*;AN000;*/

   /* if no errors then get extended attribute names */
   if (!(outregs.x.cflag & CARRY)) {                                   /*;AN000;*/
      attr_size = outregs.x.cx;                                        /*;AN000;*/

      /* allocate buffer space for extended attr. list */
      list_seg = Dallocate(attr_size);                                 /*;AN000;*/

      /* get extended attributes */
      inregs.x.bx = handle;                                            /*;AN000;*/
      inregs.x.ax = 0x5703;       /* Get extended attributes */        /*;AN000;*/
      inregs.x.di = (WORD)0x0;    /* return buffer offset */           /*;AN000;*/
      inregs.x.cx = attr_size;    /* size to get all names */          /*;AN000;*/
      segregs.es = (WORD)list_seg; /* segment of ea list to return */  /*;AN000;*/
      intdosx(&inregs,&outregs,&segregs);                              /*;AN000;*/
      strcpy(fix_es_reg,NUL);    /* restores original ES reg. value */ /*;AN000;*/
      status = outregs.x.ax;                                           /*;AN000;*/
      *num_entries = 0;                                                /*;AN000;*/

      /* if no errors then fix up far pointer to list */
      if (!(outregs.x.cflag & CARRY)) {                                /*;AN000;*/

         /* convert segment returned from Dallocate to far ptr */
         *list_ptr = 0;                                                /*;AN000;*/
         ptr = (WORD *)list_ptr;                                       /*;AN000;*/
         ptr++;                                                        /*;AN000;*/
         *ptr = (WORD)list_seg;                                        /*;AN000;*/
         *num_entries = (WORD)*(WORD far *)*list_ptr;                  /*;AN000;*/
         (*list_ptr)++;                                                /*;AN000;*/
         strcpy(fix_es_reg,NUL);  /* restores ES register value */     /*;AN000;*/
         status = NOERROR;                                             /*;AN000;*/
         }                                                             /*;AN000;*/
      }                                                                /*;AN000;*/
   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Set_reg_attrib()                                 */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*          Sets the attribute byte of a file (not extended attributes).     */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Set_reg_attrib(fspec,attr_byte)                                   /*;AN000;*/
   char *fspec;                                                        /*;AN000;*/
   BYTE attr_byte;                                                     /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD status;                                                        /*;AN000;*/

   /* set attribute byte (archive & read-only bits) */
   inregs.x.ax = 0x4301;          /* do DOS chmod call  */             /*;AN000;*/
   inregs.x.dx = (WORD)fspec;                                          /*;AN000;*/
   inregs.h.ch = 0x0;                                                  /*;AN000;*/
   inregs.h.cl = (BYTE)attr_byte;                                      /*;AN000;*/
   intdos(&inregs,&outregs);                                           /*;AN000;*/
   status = outregs.x.ax;                                              /*;AN000;*/
                                                                       /*;AN000;*/
   /* Check for error */
   if (!(outregs.x.cflag & CARRY))
      status = NOERROR;                                                /*;AN000;*/
   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Set_ext_attrib()                                 */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*          Set an extended attribute for a file.                            */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Set_ext_attrib(handle,list_ptr)                                   /*;AN000;*/
   WORD handle;                                                        /*;AN000;*/
   WORD far *list_ptr;                                                 /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD status;                                                        /*;AN000;*/

   /* set extended attribute */
   inregs.x.ax = 0x5704;          /* DOS set ext. attr. */             /*;AN000;*/
   inregs.x.bx = handle;                                               /*;AN000;*/
   inregs.x.di = 0x0;                    /* list offset */             /*;AN000;*/
   segregs.es = (WORD)FP_SEG(list_ptr);  /* list segment */            /*;AN000;*/
   intdosx(&inregs,&outregs,&segregs);                                 /*;AN000;*/
   status = outregs.x.ax;                                              /*;AN000;*/
                                                                       /*;AN000;*/
   /* Check for error */
   if (!(outregs.x.cflag & CARRY))                                     /*;AN000;*/
      status = NOERROR;                                                /*;AN000;*/
   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     CheckYN()                                        */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*          Check for a valid Yes/No answer.                                 */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD CheckYN(fspec)                                                    /*;AN000;*/
   char *fspec;                                                        /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD answer;                                                        /*;AN000;*/
   WORD key;                                                           /*;AN000;*/

   while (TRUE) {                                                      /*;AN000;*/
      msg_str2.sub_value_seg = segregs.ds;                             /*;AN000;*/
      msg_str2.sub_value = (WORD)fspec;                                /*;AN000;*/
      Display_msg(11,STDOUT,ONEPARM,&msg_str2,INPUT);                  /*;AN000;*/
      key = outregs.x.ax;          /* get key from AX */               /*;AN000;*/
      inregs.x.dx = key;           /* put key in DX */                 /*;AN000;*/
      inregs.x.ax = 0x6523;        /* check Y/N */                     /*;AN000;*/
      intdos(&inregs,&outregs);                                        /*;AN000;*/
      answer = outregs.x.ax;                                           /*;AN000;*/
      Display_msg(14,STDOUT,NOSUBPTR,NOSUBCNT,NOINPUT);                /*;AN000;*/

      if (answer == YES || answer == NO)                               /*;AN000;*/
         break;                                                        /*;AN000;*/
      }                                                                /*;AN000;*/
   return(answer);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Find_ext_attrib()                                */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Given an extended attribute name, search the list of attributes    */
/*        for a file to find this attribute. Return either TRUE for found    */
/*        or FALSE for not found.                                            */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: target = source                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Find_ext_attrib(lptr,attribute,num,addr)                          /*;AN000;*/
   WORD far *lptr;                                                     /*;AN000;*/
   char *attribute;                                                    /*;AN000;*/
   WORD num;                                                           /*;AN000;*/
   struct name_list far **addr;                                        /*;AN000;*/
{                                                                      /*;AN000;*/
   struct name_list far *ptr;                                          /*;AN000;*/
   WORD   i,j;                                                         /*;AN000;*/
   WORD   length;                                                      /*;AN000;*/
   WORD   found;                                                       /*;AN000;*/
   WORD   match;                                                       /*;AN000;*/

   found = FALSE;                                                      /*;AN000;*/

   /* loop thru return list structure for the ext. attr. we want */
   for (ptr = (struct name_list far *)lptr,i=0;i < num; i++) {         /*;AN000;*/

      /* compare attribute name to see if this is it */
      if (ptr->nl_name_len == (length = strlen(attribute))) {          /*;AN000;*/
         match = TRUE;                                                 /*;AN000;*/
         for (j=0;j<length ;j++) {                                     /*;AN000;*/
            if (ptr->nl_name[j] != attribute[j]) {                     /*;AN000;*/
               match = FALSE;                                          /*;AN000;*/
               break;                                                  /*;AN000;*/
               }                                                       /*;AN000;*/
            }                                                          /*;AN000;*/
         if (match) {                                                  /*;AN000;*/
            found = TRUE;                                              /*;AN000;*/
            break;                                                     /*;AN000;*/
            }                                                          /*;AN000;*/
         }                                                             /*;AN000;*/

      /* advance ptr to next extended attr. structure */
      length = NAME_SIZE + ptr->nl_name_len;                           /*;AN000;*/
      ptr = (struct name_list far *)((BYTE far *)ptr + length);        /*;AN000;*/
      strcpy(fix_es_reg,NUL);                                          /*;AN000;*/
      }                                                                /*;AN000;*/

   /* found the extended attribute wanted, pass addr back */
   if (found) {                                                        /*;AN000;*/
      *addr = ptr;                                                     /*;AN000;*/
      }                                                                /*;AN000;*/
   strcpy(fix_es_reg,NUL);                                             /*;AN000;*/
   return(found);                                                      /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Print_ext_attrib()                               */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Given an extended attribute name, search the list of attributes    */
/*        for a file to find this attribute. Return either TRUE for found    */
/*        or FALSE for not found.                                            */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: target = source                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Print_ext_attrib(fspec,type,name_ptr,num,attr_ptr)                /*;AN000;*/
   char *fspec;                                                        /*;AN000;*/
   WORD type;                                                          /*;AN000;*/
   struct name_list far *name_ptr;                                     /*;AN000;*/
   WORD num;                                                           /*;AN000;*/
   struct attr_list far *attr_ptr;                                     /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD status;                                                        /*;AN000;*/
   WORD i;                                                             /*;AN000;*/
   WORD length;                                                        /*;AN000;*/
   WORD value;                                                         /*;AN000;*/
   BYTE far *value_ptr;                                                /*;AN000;*/
   char string[129];                                                   /*;AN000;*/
   char far *cptr;                                                     /*;AN000;*/
   struct name_list far *ptr;                                          /*;AN000;*/

   /* find value field in attribute list */
   length = ATTR_SIZE + attr_ptr->at_name_len;                         /*;AN000;*/
   value_ptr = (BYTE far *)((BYTE far *)attr_ptr + length);            /*;AN000;*/
   length = attr_ptr->at_value_len;                                    /*;AN000;*/
   strcpy(fix_es_reg,NUL);                                             /*;AN000;*/

   status = NOERROR;                                                   /*;AN000;*/
   switch (type) {                                                     /*;AN000;*/
      case EAISUNDEF:                                                  /*;AN000;*/
         msg_str2.sub_value_seg = segregs.ds;                          /*;AN000;*/
         msg_str2.sub_value = (WORD)fspec;                             /*;AN000;*/
         Display_msg(12,STDOUT,ONEPARM,&msg_str2,NOINPUT);             /*;AN000;*/
         break;                                                        /*;AN000;*/
      case EAISLOGICAL:                                                /*;AN000;*/
         msg_str.sub_value_seg = segregs.ds;                           /*;AN000;*/
         if ((BYTE)*(BYTE far *)value_ptr == 0)                        /*;AN000;*/
            msg_str.sub_value = (WORD)str_off;                         /*;AN000;*/
         else                                                          /*;AN000;*/
            msg_str.sub_value = (WORD)str_on;                          /*;AN000;*/
         msg_str1.sub_value_seg = segregs.ds;                          /*;AN000;*/
         msg_str1.sub_value = (WORD)fspec;                             /*;AN000;*/
         Display_msg(9,STDOUT,TWOPARM,&msg_str,NOINPUT);               /*;AN000;*/
         break;                                                        /*;AN000;*/
      case EAISBINARY:                                                 /*;AN000;*/
         if (length == 1) {                                            /*;AN000;*/
            msg_num.sub_flags = sf_unsbin2d | sf_byte | sf_right;      /*;AN000;*/
            value = (BYTE)*(BYTE far *)value_ptr;                      /*;AN000;*/
            }                                                          /*;AN000;*/
         else if (length == 2) {                                       /*;AN000;*/
            msg_num.sub_flags = sf_unsbin2d | sf_word | sf_right;      /*;AN000;*/
            value = (WORD)*(WORD far *)value_ptr;                      /*;AN000;*/
            }                                                          /*;AN000;*/
         else if (length == 4) {                                       /*;AN000;*/
            msg_num.sub_flags = sf_unsbin2d | sf_dword | sf_right;     /*;AN000;*/
            value = (DWORD)*(DWORD far *)value_ptr;                    /*;AN000;*/
            }                                                          /*;AN000;*/
         msg_num.sub_value_seg = segregs.ds;                           /*;AN000;*/
         msg_num.sub_value = (WORD)&value;                             /*;AN000;*/
         msg_str1.sub_value_seg = segregs.ds;                          /*;AN000;*/
         msg_str1.sub_value = (WORD)fspec;                             /*;AN000;*/
         Display_msg(9,STDOUT,TWOPARM,&msg_num,NOINPUT);               /*;AN000;*/
         break;                                                        /*;AN000;*/
      case EAISASCII:                                                  /*;AN000;*/
         msg_str2.sub_value_seg = segregs.ds;                          /*;AN000;*/
         msg_str2.sub_value = (WORD)fspec;                             /*;AN000;*/
         Display_msg(12,STDOUT,ONEPARM,&msg_str2,NOINPUT);             /*;AN000;*/
         Get_far_str(string,&value_ptr,length);                        /*;AN000;*/
         msg_str2.sub_value = (WORD)string;                            /*;AN000;*/
         Display_msg(8,STDOUT,ONEPARM,&msg_str2,NOINPUT);              /*;AN000;*/
         break;                                                        /*;AN000;*/
      case EAISDATE:                                                   /*;AN000;*/
         msg_str1.sub_value_seg = segregs.ds;                          /*;AN000;*/
         msg_str1.sub_value = (WORD)fspec;                             /*;AN000;*/
         value = (WORD)*(WORD far *)value_ptr;                         /*;AN000;*/
         Convert_date(value,&msg_date.sub_value,&msg_date.sub_value_seg); /*;AN000;*/
         Display_msg(9,STDOUT,TWOPARM,&msg_date,NOINPUT);              /*;AN000;*/
         break;                                                        /*;AN000;*/
      case EAISTIME:                                                   /*;AN000;*/
         msg_str1.sub_value_seg = segregs.ds;                          /*;AN000;*/
         msg_str1.sub_value = (WORD)fspec;                             /*;AN000;*/
         value = (WORD)*(WORD far *)value_ptr;                         /*;AN000;*/
         Convert_time(value,&msg_time.sub_value,&msg_time.sub_value_seg); /*;AN000;*/
         Display_msg(9,STDOUT,TWOPARM,&msg_time,NOINPUT);              /*;AN000;*/
         break;                                                        /*;AN000;*/
      case EANAMES:                                                    /*;AN000;*/
         msg_str2.sub_value_seg = segregs.ds;                          /*;AN000;*/
         msg_str2.sub_value = (WORD)fspec;                             /*;AN000;*/
         Display_msg(12,STDOUT,ONEPARM,&msg_str2,NOINPUT);             /*;AN000;*/

         /* display special attribute names */
         for (i=0; i < MAX_SPL; i++) {                                 /*;AN000;*/
            msg_str2.sub_value = (WORD)specials[i].name;               /*;AN000;*/
            Display_msg(8,STDOUT,ONEPARM,&msg_str2,NOINPUT);           /*;AN000;*/
            }                                                          /*;AN000;*/

         /* display each attribute name */
         for (ptr = name_ptr,i=0; i<num; i++) {                        /*;AN000;*/
            cptr = (char far *)((BYTE far *)ptr + 4);                  /*;AN000;*/
            Get_far_str(string,&cptr,(WORD)ptr->nl_name_len);          /*;AN000;*/

            msg_str2.sub_value = (WORD)string;                         /*;AN000;*/
            Display_msg(8,STDOUT,ONEPARM,&msg_str2,NOINPUT);           /*;AN000;*/

            /* advance ptr to next extended attr. structure */
            length = NAME_SIZE + ptr->nl_name_len;                     /*;AN000;*/
            ptr = (struct name_list far *)((BYTE far *)ptr + length);  /*;AN000;*/
            strcpy(fix_es_reg,NUL);                                    /*;AN000;*/
            }                                                          /*;AN000;*/
         Display_msg(14,STDOUT,NOSUBPTR,NOSUBCNT,NOINPUT);             /*;AN000;*/
         Display_msg(14,STDOUT,NOSUBPTR,NOSUBCNT,NOINPUT);             /*;AN000;*/
         break;                                                        /*;AN000;*/
      default:                                                         /*;AN000;*/
         msg_str2.sub_value_seg = segregs.ds;                          /*;AN000;*/
         msg_str2.sub_value = (WORD)fspec;                             /*;AN000;*/
         Display_msg(12,STDOUT,ONEPARM,&msg_str2,NOINPUT);             /*;AN000;*/
         break;                                                        /*;AN000;*/
      } /* endswitch */                                                /*;AN000;*/
   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*    Subroutine Name: Convert_date                                          */
/*                                                                           */
/*    Subroutine Function:                                                   */
/*       Convert date word returned by DOS to the form required by the       */
/*       message retriever.                                                  */
/*                                                                           */
/*       DOS returns:   yyyyyyym mmmddddd                                    */
/*                                                                           */
/*                      y = 0-119 (1980-2099)                                */
/*                      m = 1-12                                             */
/*                      d = 1-31                                             */
/*                                                                           */
/*       Message retriever requires:  yyyyyyyy yyyyyyyy mmmmmmmm dddddddd    */
/*                                                                           */
/*    Input:                                                                 */
/*        (1) Date word in form given by DOS                                 */
/*        (2) Address of first word to place result (yyyyyyyy yyyyyyyy)      */
/*        (3) Address of second word to place result (mmmmmmmm dddddddd)     */
/*                                                                           */
/*    Output:                                                                */
/*        Double word result updated with date in form required by           */
/*        message retriever.                                                 */
/*                                                                           */
/*    Normal exit: Result word updated                                       */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Convert_date(dosdate,msgdate1,msgdate2)
   WORD dosdate;
   WORD *msgdate1;
   WORD *msgdate2;
{
   WORD     day,month,year;

   year = dosdate;
   year = ((year >> 1) & 0x7f00) + 80*256;   /* DOS year + 80 */
   year = (year >> 8) & 0x007f;                                        /*;AN000;*/
   day = dosdate;
   day = (day << 8) & 0x1f00;
   month = dosdate;
   month = (month >> 5) & 0x000f;
   *msgdate1 = year;
   *msgdate2 = month | day;
}


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*    Subroutine Name: Convert_time                                          */
/*                                                                           */
/*    Subroutine Function:                                                   */
/*       Convert time word returned by DOS to the form required by the       */
/*       message retriever.                                                  */
/*                                                                           */
/*       DOS returns:   hhhhhmmm mmmsssss                                    */
/*                                                                           */
/*                      h = hours (0-23)                                     */
/*                      m = minutes (0-59)                                   */
/*                      s = seconds/2                                        */
/*                                                                           */
/*       Message retriever requires:  hhhhhhhh mmmmmmmm ssssssss hhhhhhhh    */
/*                                                                           */
/*    Input:                                                                 */
/*        (1) Time word in form given by DOS                                 */
/*        (2) Address of first word to place result (hhhhhhhh hhhhhhhh)      */
/*        (3) Address of second word to place result (ssssssss 00000000)     */
/*                                                                           */
/*    Output:                                                                */
/*        Double word result updated with time in form required by           */
/*        message retriever.                                                 */
/*                                                                           */
/*    Normal exit: Result word updated                                       */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Convert_time(dostime,msgtime1,msgtime2)
   WORD dostime;
   WORD *msgtime1;
   WORD *msgtime2;
{
   WORD     hours,minutes,seconds;

   hours = dostime;
   hours = hours >> 11 & 0x001f;
   seconds = dostime;
   seconds = seconds & 0x001f * 2;   /* seconds * 2 */
   minutes = dostime;
   minutes = minutes << 3 & 0x3f00;
   *msgtime1 = hours | minutes;
   *msgtime2 = seconds;
}


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Regular_attrib()                                 */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Handles all function for archive bit and read-only bit.            */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Regular_attrib(fspec)                                             /*;AN000;*/
   char *fspec;                                                        /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD status;                                                        /*;AN000;*/
   WORD i;                                                             /*;AN000;*/
   char string[16];                                                    /*;AN000;*/

   /* get attributes */
   if ((status = Get_reg_attrib(fspec,&attr)) != NOERROR) {            /*;AN000;*/
      return(status);                                                  /*;AN000;*/
      }                                                                /*;AN000;*/

   /* Check whether to display values or set new ones */
   if (set_reg_attr) {                                                 /*;AN000;*/
      attr = (attr & (~mmask)) | pmask;                                /*;AN000;*/
      status = Set_reg_attrib(fspec,attr);                             /*;AN000;*/
      }                                                                /*;AN000;*/
   else {                                                              /*;AN000;*/
      for (i = 0; i < 8; i++)                                          /*;AN000;*/
         if ((attr & bits[i]) != 0 )                                   /*;AN000;*/
            string[i] = as[i];                                         /*;AN000;*/
         else                                                          /*;AN000;*/
            string[i] = ' ';                                           /*;AN000;*/
      for (i=8; i < 16; i++)                                           /*;AN000;*/
         string[i] = ' ';                                              /*;AN000;*/
      string[16] = '\0';                                               /*;AN000;*/

      msg_str.sub_value_seg = segregs.ds;                              /*;AN000;*/
      msg_str.sub_value = (WORD)string;                                /*;AN000;*/
      msg_str1.sub_value_seg = segregs.ds;                             /*;AN000;*/
      msg_str1.sub_value = (WORD)fspec;                                /*;AN000;*/
      Display_msg(9,STDOUT,TWOPARM,&msg_str,NOINPUT);                  /*;AN000;*/
      }                                                                /*;AN000;*/

   did_attrib_ok = TRUE;                                               /*;AN000;*/
   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Special_attrib()                                 */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*          Handles all function for special attributes. For example, "DATE" */
/*          is a special attribute because it is not an extended attribute,  */
/*          but ATTRIB does support its function.                            */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Special_attrib(handle,fspec,id)                                   /*;AN000;*/
   WORD handle;                                                        /*;AN000;*/
   char *fspec;                                                        /*;AN000;*/
   WORD id;                                                            /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD status;                                                        /*;AN000;*/
   DWORD filesize;                                                     /*;AN000;*/
   long size;                                                          /*;AN000;*/
   long filelength();                                                  /*;AN000;*/

   msg_str1.sub_value_seg = segregs.ds;                                /*;AN000;*/
   msg_str1.sub_value = (WORD)fspec;                                   /*;AN000;*/

   /* check to set if user is trying to set a special attribute, if so */
   /* then return error.                                               */
   if (set_ext_attr)                                                   /*;AN000;*/
      return(EARCNOTEVER+200);                                         /*;AN000;*/

   /* determine which info to get by using ID */
   if (id == A_FILESIZE) {       /* get filesize */                    /*;AN000;*/

      /* get file size, if error return error code */
      if ((size = filelength(handle)) == (long)-1) {                   /*;AN000;*/
         return(FILENOTFOUND);                                         /*;AN000;*/
         }                                                             /*;AN000;*/
      filesize = (DWORD)size;                                          /*;AN000;*/
      msg_dword.sub_value = (WORD)&filesize;                           /*;AN000;*/
      msg_dword.sub_value_seg = (WORD)segregs.ds;                      /*;AN000;*/
      Display_msg(9,STDOUT,TWOPARM,&msg_dword,NOINPUT);                /*;AN000;*/
      }                                                                /*;AN000;*/

   else if (id == A_DATE) {                                            /*;AN000;*/
      inregs.x.ax = 0x5700;      /* get date */                        /*;AN000;*/
      inregs.x.bx = handle;                                            /*;AN000;*/
      intdos(&inregs,&outregs);                                        /*;AN000;*/
      status = outregs.x.ax;                                           /*;AN000;*/
      if (outregs.x.cflag & CARRY)                                     /*;AN000;*/
         return(status);                                               /*;AN000;*/

      Convert_date(outregs.x.dx,&msg_date.sub_value,&msg_date.sub_value_seg); /*;AN000;*/
      Display_msg(9,STDOUT,TWOPARM,&msg_date,NOINPUT);                 /*;AN000;*/
      }                                                                /*;AN000;*/

   else if (id == A_TIME) {                                            /*;AN000;*/
      inregs.x.ax = 0x5700;      /* get time */                        /*;AN000;*/
      inregs.x.bx = handle;                                            /*;AN000;*/
      intdos(&inregs,&outregs);                                        /*;AN000;*/
      status = outregs.x.ax;                                           /*;AN000;*/
      if (outregs.x.cflag & CARRY)                                     /*;AN000;*/
         return(status);                                               /*;AN000;*/

      Convert_time(outregs.x.cx,&msg_time.sub_value,&msg_time.sub_value_seg); /*;AN000;*/
      Display_msg(9,STDOUT,TWOPARM,&msg_time,NOINPUT);                 /*;AN000;*/
      }                                                                /*;AN000;*/

   did_attrib_ok = TRUE;                                               /*;AN000;*/
   return(NOERROR);                                                    /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Extended_attrib()                                */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*          Determine what functions the user wants and then gets the        */
/*          extended attributes and regular attributes and then checks       */
/*          the attributes against what the user wanted and either do it or  */
/*          return error.                                                    */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Extended_attrib(handle,fspec)                                     /*;AN000;*/
   WORD handle;                                                        /*;AN000;*/
   char *fspec;                                                        /*;AN000;*/
{                                                                      /*;AN000;*/
   WORD status;                                                        /*;AN000;*/
   WORD num;                                                           /*;AN000;*/
   WORD type;                                                          /*;AN000;*/
   WORD length;                                                        /*;AN000;*/
   WORD i;                                                             /*;AN000;*/
   WORD far *name_ptr,                                                 /*;AN000;*/
        far *nptr;                                                     /*;AN000;*/
   WORD far *list_ptr;                                                 /*;AN000;*/
   BYTE far *value_ptr;                                                /*;AN000;*/
   char far *cptr;                                                     /*;AN000;*/
   char *ptr;                                                          /*;AN000;*/
   struct query_list qlist;                                            /*;AN000;*/

   /* get extended attribute names, if error return with error code */
   if ((status = Get_ext_attr_names(handle,&name_ptr,&num)) != NOERROR) { /*;AN000;*/
      return(status);                                                  /*;AN000;*/
      }                                                                /*;AN000;*/

   /* Check for keyword "*", print all extended attribute names */
   /* ***** this is a special piece of code                     */
   if (strcmp(ext_attr,"*") == 0) {                                    /*;AN000;*/
      do_ext_attr = TRUE;                                              /*;AN000;*/
      set_ext_attr = FALSE;                                            /*;AN000;*/
      nptr = name_ptr;                                                 /*;AN000;*/
      type = EANAMES;                                                  /*;AN000;*/
      status = Print_ext_attrib(fspec,type,name_ptr,num,list_ptr);     /*;AN004;*/
      did_attrib_ok = TRUE;                                            /*;AN004;*/
      return(status);                                                  /*;AN004;*/
      }                                                                /*;AN000;*/

   /* find if extended attribute name is in list */
   else if (!Find_ext_attrib(name_ptr,ext_attr,num,&nptr)) {           /*;AN000;*/
      return(EARCNOTFOUND+200);                                        /*;AN000;*/
      }                                                                /*;AN000;*/
   else                                                                /*;AN000;*/
      type = ((struct name_list far *)nptr)->nl_type;                  /*;AN000;*/

   /* Check if extended attribute is hidden , if so leave */
   if (((struct name_list far *)nptr)->nl_flags & EAHIDDEN) {          /*;AN000;*/
      did_attrib_ok = TRUE;                                            /*;AN000;*/
      return(NOERROR);                                                 /*;AN000;*/
      }                                                                /*;AN000;*/

   /* Get the extended attribute value */
   qlist.ql_num = 1;                                                   /*;AN000;*/
   qlist.ql_type = ((struct name_list far *)nptr)->nl_type;            /*;AN000;*/
   qlist.ql_flags = ((struct name_list far *)nptr)->nl_flags;          /*;AN000;*/
   qlist.ql_name_len = ((struct name_list far *)nptr)->nl_name_len;    /*;AN000;*/
   cptr = (char far *)((BYTE far *)nptr + 4);                          /*;AN000;*/
   Get_far_str(qlist.ql_name,&cptr,qlist.ql_name_len);                 /*;AN000;*/

   if ((status = Get_ext_attrib(handle,&list_ptr,&qlist)) != NOERROR) { /*;AN000;*/
      return(status);                                                  /*;AN000;*/
      }                                                                /*;AN000;*/

   /* Check if doing a display or set, and go do it */
   if (do_ext_attr) {                                                  /*;AN000;*/
      status = Print_ext_attrib(fspec,type,name_ptr,num,list_ptr);     /*;AN000;*/
      }                                                                /*;AN000;*/
   else {                                                              /*;AN000;*/

      /* Check if extended attribute is read-only or create-only */
      /* or if the type is undefined. if true, display error     */
      if ((qlist.ql_flags & (EAREADONLY | EACREATEONLY)) ||            /*;AN000;*/
                                     (qlist.ql_type & EAISUNDEF)) {    /*;AN000;*/
         return(EARCNOTEVER+200); /* error will be displayed */        /*;AN000;*/
         }                                                             /*;AN000;*/

      /* Check type of current attribute against the type the user */
      /* is trying to set the attribute to. If they differ, error. */
      if (qlist.ql_type != ext_attr_value_type) {                      /*;AN000;*/
         return(EARCDEFBAD+200);  /* error will be displayed */        /*;AN000;*/
         }                                                             /*;AN000;*/

      /* find value field in attribute list */
      length = ATTR_SIZE + qlist.ql_name_len;                          /*;AN000;*/
      value_ptr = (BYTE far *)((BYTE far *)list_ptr + length);         /*;AN000;*/
      length = ((struct attr_list far *)list_ptr)->at_value_len;       /*;AN000;*/
      strcpy(fix_es_reg,NUL);                                          /*;AN000;*/

      /* CODEPAGE attrbute only - display Y/N message if changing codepage */
      /* to a new value and cp != 0, ask for confirmation.                 */
      if (strcmp(qlist.ql_name,"CP") == 0 &&                           /*;AN000;*/
           (WORD)*(WORD far *)value_ptr != 0 &&                        /*;AN000;*/
           (WORD)*(WORD far *)value_ptr != (WORD)ext_attr_value.ea_bin.dword) { /*;AN000;*/
         if (CheckYN(fspec) == NO) {                                   /*;AN000;*/
            did_attrib_ok = TRUE;                                      /*;AN000;*/
            return(NOERROR);                                           /*;AN000;*/
            }                                                          /*;AN000;*/
         }                                                             /*;AN000;*/

      /* Determine type of extended attribute and set the correct value */
      switch (ext_attr_value_type) {                                   /*;AN000;*/
         case EAISLOGICAL:                                             /*;AN000;*/
            *(BYTE far *)value_ptr = (BYTE)ext_attr_value.ea_logical;  /*;AN000;*/
            break;                                                     /*;AN000;*/
         case EAISBINARY:                                              /*;AN000;*/
            if (length == 1)                                           /*;AN000;*/
               *(BYTE far *)value_ptr = (BYTE)ext_attr_value.ea_bin.dword; /*;AN000;*/
            else if (length == 2)                                      /*;AN000;*/
               *(WORD far *)value_ptr = (WORD)ext_attr_value.ea_bin.dword; /*;AN000;*/
            else                                                       /*;AN000;*/
               *(DWORD far *)value_ptr = (DWORD)ext_attr_value.ea_bin.dword; /*;AN000;*/
            break;                                                     /*;AN000;*/
         case EAISASCII:                                               /*;AN000;*/
            length = strlen(ext_attr_value.ea_ascii); /* get string length */ /*;AN000;*/
            ((struct attr_list far *)list_ptr)->at_value_len = length; /*;AN000;*/
            for (ptr=ext_attr_value.ea_ascii,i=0;i < length;i++) {     /*;AN000;*/
               *(char far *)value_ptr = *ptr++;                        /*;AN000;*/
               ((char far *)value_ptr)++;                              /*;AN000;*/
               }                                                       /*;AN000;*/
            break;                                                     /*;AN000;*/
         case EAISDATE:                                                /*;AN000;*/
            *(WORD far *)value_ptr = (WORD)ext_attr_value.ea_date;     /*;AN000;*/
            break;                                                     /*;AN000;*/
         case EAISTIME:                                                /*;AN000;*/
            *(WORD far *)value_ptr = (WORD)ext_attr_value.ea_time;     /*;AN000;*/
            break;                                                     /*;AN000;*/
         }                                                             /*;AN000;*/

      list_ptr--;           /* make list_ptr point to num entries */   /*;AN000;*/
      *(WORD far *)list_ptr = 1;      /* num entries = 1 */            /*;AN000;*/

      if ((status = Set_ext_attrib(handle,list_ptr)) != NOERROR) {     /*;AN000;*/
         return(status);                                               /*;AN000;*/
         }                                                             /*;AN000;*/
      }                                                                /*;AN000;*/
   did_attrib_ok = TRUE;                                               /*;AN000;*/
   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Attrib()                                         */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*          Determine what functions the user wants and then gets the        */
/*          extended attributes and regular attributes and then checks       */
/*          the attributes against what the user wanted and either do it or  */
/*          return error.                                                    */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Attrib(path,file)                                                 /*;AN000;*/
   char *path,                                                         /*;AN000;*/
        *file;                                                         /*;AN000;*/
{                                                                      /*;AN000;*/
   char fspec[128];                                                    /*;AN000;*/
   WORD status;                                                        /*;AN000;*/
   WORD handle;                                                        /*;AN000;*/
   WORD i;                                                             /*;AN000;*/
   WORD found_spl;        /* boolean */                                /*;AN000;*/
   WORD id;                                                            /*;AN000;*/

   strcpy(fspec,path);     /* make full filename */                    /*;AN000;*/
   strcat(fspec,file);                                                 /*;AN000;*/

   /* Check for extended & special attributes */
   if (set_ext_attr || do_ext_attr) {                                  /*;AN000;*/

      /* Check for special attribute keywords */
      found_spl = FALSE;                                               /*;AN000;*/
      for (i=0; i < MAX_SPL; i++) {                                    /*;AN000;*/
         if (strcmp(ext_attr,specials[i].name) == 0) {                 /*;AN000;*/
            found_spl = TRUE;                                          /*;AN000;*/
            id = specials[i].id;                                       /*;AN000;*/
            break;                                                     /*;AN000;*/
            }                                                          /*;AN000;*/
         }                                                             /*;AN000;*/

      /* Do an extended open, if error return error code */
      if ((status = Ext_open(fspec,&handle)) != NOERROR) {             /*;AN000;*/
         return(status);                                               /*;AN000;*/
         }                                                             /*;AN000;*/

      /* Special attributes */
      if (found_spl) {                                                 /*;AN000;*/
         status = Special_attrib(handle,fspec,id);                     /*;AN000;*/
         }                                                             /*;AN000;*/

      /* Extended attributes */
      else {                                                           /*;AN000;*/
         status = Extended_attrib(handle,fspec);                       /*;AN000;*/
         }                                                             /*;AN000;*/
      close(handle);                                                   /*;AN000;*/
      }                                                                /*;AN000;*/

   /* Check if setting archive bit or readonly bit */
   if (set_reg_attr || do_reg_attr) {                                  /*;AN000;*/
      if ((status = Regular_attrib(fspec)) != NOERROR) {               /*;AN000;*/
         return(status);                                               /*;AN000;*/
         }                                                             /*;AN000;*/
      }                                                                /*;AN000;*/

   return(status);                                                     /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Do_dir()                                         */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Given the full path-filename, determine if descending option is    */
/*        set and then recursively (if option set) find all files in this    */
/*        directory and all files in any subdirectories (if option set).     */
/*        For each directory call Attrib()  which will process a file.       */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

WORD Do_dir(path,file)
   char *path,
        *file;
{
   char     dta_area[128];
   char     subdirectory[256];
   char     next[32];
   WORD     status;
   WORD     search_attrib;

   next[0] = '\0';                                                     /*;AN000;*/
   Dta_save(dta_area,128);
   status = NOERROR;                                                   /*;AN000;*/

   /* first, but only if descending, scan for subdirectories */
   if (descending) {
      strcpy(subdirectory,path);
      strcat(subdirectory,"*.*");

      search_attrib = SUBDIR; /* Find all except volume labels*/       /*;AN000;*/
      status = Find_first(subdirectory,next,&search_attrib);

      while (status == NOERROR) {
         if ((next[0] != '.') && ((search_attrib & SUBDIR) != 0)) {
             strcpy(subdirectory,path);
             strcat(subdirectory,next);
             strcat(subdirectory,"\\");
             status = Do_dir(subdirectory,file);
             }
         if (status == NOERROR) {
            strcpy(subdirectory,path);
            strcat(subdirectory,"*.*");

            search_attrib = SUBDIR;                                    /*;AN000;*/
            status = Find_next(next,&search_attrib);
            }
         }     /* while */
      }     /* if descending */

   if (status == NOMOREFILES)
      status = NOERROR;

   /* now, search this directory for files that match */
   if (status == NOERROR) {
      strcpy(subdirectory,path);
      strcat(subdirectory,file);

      search_attrib = SUBDIR;                                          /*;AN000;*/
      status = Find_first(subdirectory,next,&search_attrib);
      while(status == NOERROR) {

         /* Check that this file is not a directory, system file, */
         /* or a hidden file.                                     */
         if (  (next[0] != '.') &&
               ((search_attrib & SUBDIR) == 0) &&
               ((search_attrib & SYSTEM) == 0) &&
               ((search_attrib & HIDDEN) == 0) )  {
            status = Attrib(path,next);
            }

         if (status == NOERROR) {
            search_attrib = SUBDIR;                                    /*;AN000;*/
            status = Find_next(next,&search_attrib);
            }
         }      /* while */
       }
   if (status == NOMOREFILES)
      status = NOERROR;

   if (status != NOERROR) {                                           /*;AN000;*/
      }

   Dta_restore(dta_area,128);
   return(status);
}


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Check_appendx()                                  */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Check APPEND /X status.  If it is not active,                      */
/*        do nothing. If it is active, then turn it off                      */
/*        and set flag indicating that fact.                                 */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: append_active_flg                                              */
/*                                                                           */
/*    Normal exit: flag set if /X active                                     */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Check_appendx()                                                        /*;AN000;*/
{                                                                      /*;AN000;*/
   void ctl_brk_handler();                                             /*;AN000;*/
   extern crit_err_handler();                                          /*;AN000;*/
   WORD *ptr;                                                          /*;AN000;*/

   inregs.x.ax = 0xb700;         /* Is appendx installed ? */          /*;AN000;*/
   int86(0x2f,&inregs,&outregs);                                       /*;AN000;*/
   if (outregs.h.al) {                                                 /*;AN000;*/
      inregs.x.ax = 0xb702;           /* Get version */                /*;AN000;*/
      int86(0x2f,&inregs,&outregs);                                    /*;AN000;*/
      if (outregs.x.ax == 0xffff) {                                    /*;AN000;*/
         inregs.x.ax = 0xb706;        /* Get /X status */              /*;AN000;*/
         int86(0x2f,&inregs,&outregs);                                 /*;AN000;*/
         append_x_status = outregs.x.bx;  /* save status to restore */ /*;AN000;*/

         /* turn off append /x */
         inregs.x.ax = 0xb707;        /* Set /X status */              /*;AN000;*/
         inregs.x.bx = append_x_status & INACTIVE;                     /*;AN000;*/
         int86(0x2f,&inregs,&outregs);                                 /*;AN000;*/
         }                                                             /*;AN000;*/
      }                                                                /*;AN000;*/

   /* get critical error handler vector for later */
   inregs.x.ax = 0x3524;       /* get critical error vector */         /*;AN000;*/
   intdosx(&inregs,&outregs,&segregs);                                 /*;AN000;*/
   ptr = (WORD *)&old_int24_off;                                       /*;AN000;*/
   *ptr++ = (WORD)outregs.x.bx;                                        /*;AN000;*/
   *ptr = (WORD)segregs.es;                                            /*;AN000;*/

   /* set crtl-c & critical error handler vector */
   segread(&segregs);
   inregs.x.ax = 0x2523;        /* crtl-c - int 23 */                  /*;AN000;*/
   inregs.x.dx = (WORD) ctl_brk_handler;                               /*;AN000;*/
   segregs.ds = (WORD) segregs.cs;                                     /*;AN000;*/
   intdosx(&inregs,&outregs,&segregs);                                 /*;AN000;*/

   inregs.x.ax = 0x2524;        /* critical err - int 24 */            /*;AN000;*/
   inregs.x.dx = (WORD) crit_err_handler;                              /*;AN000;*/
   segregs.ds = (WORD) segregs.cs;                                     /*;AN000;*/
   intdosx(&inregs,&outregs,&segregs);                                 /*;AN000;*/
   strcpy(fix_es_reg,NUL);      /* restore ES register */              /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Reset_appendx()                                  */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Reset APPEND /X status.  If it is not active,                      */
/*        do nothing. If it is active, then turn it on                       */
/*        and set flag indicating that fact.                                 */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: append_active_flg                                              */
/*                                                                           */
/*    Normal exit: flag set if /X active                                     */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Reset_appendx()                                                        /*;AN000;*/
{                                                                      /*;AN000;*/
   if (append_x_status != 0)  {                                        /*;AN000;*/
      inregs.x.ax = 0xb707;                                            /*;AN000;*/
      inregs.x.bx = append_x_status;                                   /*;AN000;*/
      int86(0x2f,&inregs,&outregs);                                    /*;AN000;*/
      }                                                                /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Check_DBCS()                                     */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Given an array and a position in the array, check if the character */
/*        is a non-DBCS character.                                           */
/*                                                                           */
/*    Input:  array, character position, character                           */
/*                                                                           */
/*    Output: TRUE - if array[position-1] != DBCS character  AND             */
/*                      array[position] == character.                        */
/*            FALSE - otherwise                                              */
/*    Normal exit: none                                                      */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
WORD Check_DBCS(array,position,character)                              /*;AN000;*/
   char *array;                                                        /*;AN000;*/
   WORD position;                                                      /*;AN000;*/
   char character;                                                     /*;AN000;*/
{                                                                      /*;AN000;*/
   BYTE far *ptr;                                                      /*;AN000;*/
   WORD i;                                                             /*;AN000;*/
   char c;                                                             /*;AN000;*/
   char darray[128];        /* DBCS array, put "D" in every position*/ /*;AN000;*/
                            /* that corresponds to the first byte   */
                            /* of a DBCS character.                 */
   for (i=0;i<128;i++)                                                 /*;AN000;*/
      darray[i] = ' ';                                                 /*;AN000;*/

   /* Check each character, starting with the first in string, for DBCS */
   /* characters and mark each with a "D" in the corresponding darray.  */
   for (i=0;i<position;i++) {                                          /*;AN000;*/
      c = array[i];                                                    /*;AN000;*/

      /* look thru DBCS table to determine if character is first byte */
      /* of a double byte character                                   */
      for (ptr=DBCS_ptr; (WORD)*(WORD far *)ptr != 0; ptr += 2) {      /*;AN000;*/

         /* check if byte is within range values of DOS DBCS table */
         if (c >= *ptr && c <= *(ptr+1)) {                             /*;AN000;*/
            darray[i] = 'D';                                           /*;AN000;*/
            i++;           /* skip over second byte of DBCS */         /*;AN000;*/
            break;
            }
         }                                                             /*;AN000;*/
      }                                                                /*;AN000;*/

   /* if character is not DBCS then check to see if it is == to character */
   if (darray[position-1] != 'D' && character == array[position]) {    /*;AN000;*/
      return (TRUE);                                                   /*;AN000;*/
      }                                                                /*;AN000;*/
   else                                                                /*;AN000;*/
      return (FALSE);                                                  /*;AN000;*/
}                                                                      /*;AN000;*/


/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Get_DBCS_vector()                                */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Gets the double-byte table vector.                                 */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit: none                                                      */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
Get_DBCS_vector()                                                      /*;AN000;*/
{                                                                      /*;AN000;*/
    WORD *ptr;                                                         /*;AN000;*/
    WORD *buffer;                                                      /*;AN000;*/
    DWORD far *addr_ptr;                                               /*;AN000;*/

    /* allocate a buffer for DBCS table vector */
    buffer = Dallocate(5);      /* at least 5 bytes big */             /*;AN000;*/

    inregs.x.ax = 0x6507;      /* get extended country info */         /*;AN000;*/
    inregs.x.bx = -1;             /* use active code page */           /*;AN000;*/
    inregs.x.cx = 5;              /* 5 bytes of return data */         /*;AN000;*/
    inregs.x.dx = -1;             /* use default country */            /*;AN000;*/
    inregs.x.di = 0;              /* buffer offset */                  /*;AN000;*/
    segregs.es = (WORD)buffer;    /* buffer segment */                 /*;AN000;*/
    intdosx(&inregs,&outregs,&segregs);                                /*;AN000;*/
    strcpy(fix_es_reg,NUL);                                            /*;AN000;*/

    outregs.x.di++;            /* skip over id byte */                 /*;AN000;*/

    /* make a far ptr from ES:[DI] */
    addr_ptr = 0;                                                      /*;AN000;*/
    ptr = (WORD *)&addr_ptr;                                           /*;AN000;*/
    *ptr = (WORD)outregs.x.di;   /* get offset */                      /*;AN000;*/
    ptr++;                                                             /*;AN000;*/
    *ptr = (WORD)segregs.es;     /* get segment */                     /*;AN000;*/
    DBCS_ptr = (BYTE far *)*addr_ptr;                                  /*;AN000;*/
    DBCS_ptr += 2;               /* skip over table length */          /*;AN000;*/

    /* DBCS_ptr points to DBCS table */                                /*;AN000;*/
    strcpy(fix_es_reg,NUL);                                            /*;AN000;*/
}                                                                      /*;AN000;*/



/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Error_exit()                                     */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        displays an extended error message with - filename                 */
/*                                                                           */
/*    Input:  error_file_name[] must contain name of file, if needed for     */
/*            message output.                                                */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
void Error_exit(msg_class,ext_err_num,subcnt)                          /*;AN000;*/
                                                                       /*;AN000;*/
   int msg_class;                                                      /*;AN000;*/
   int ext_err_num;                                                    /*;AN000;*/
   int subcnt;                                                         /*;AN000;*/
{                                                                      /*;AN000;*/
   segread(&segregs);                                                  /*;AN000;*/
   msg_error.sub_value_seg = segregs.ds;                               /*;AN000;*/
   msg_error.sub_value = (WORD)error_file_name;                        /*;AN000;*/
   inregs.x.ax = (WORD)ext_err_num;                                    /*;AN000;*/
   inregs.x.bx = STDERR;                                               /*;AN000;*/
   inregs.x.cx = subcnt;                                               /*;AN000;*/
   inregs.h.dh = (WORD)msg_class;                                      /*;AN000;*/
   inregs.h.dl = NOINPUT;                                              /*;AN000;*/
   inregs.x.si = (WORD)&msg_error;                                     /*;AN000;*/
   sysdispmsg(&inregs,&outregs);                                       /*;AN000;*/

   /* check for error printing message */
   if (outregs.x.cflag & CARRY) {                                      /*;AN000;*/
      outregs.x.bx = (WORD) STDERR;                                    /*;AN000;*/
      outregs.x.si = NOSUBPTR;                                         /*;AN000;*/
      outregs.x.cx = NOSUBCNT;                                         /*;AN000;*/
      outregs.h.dl = exterr_msg_class;                                 /*;AN000;*/
      sysdispmsg(&outregs,&outregs);                                   /*;AN000;*/
      }                                                                /*;AN000;*/

   Reset_appendx();             /* Reset APPEND /X status */           /*;AN000;*/
   exit(1);                                                            /*;AN000;*/
}                                                                      /*;AN000;*/



/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     Parse_err()                                      */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        displays an parser   error message with - filename                 */
/*                                                                           */
/*    Input:  error_file_name[] must contain name of file, if needed for     */
/*            message output.                                                */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
void Parse_err(error_num)                                              /*;AN000;*/

   WORD error_num;                                                     /*;AN000;*/
{                                                                      /*;AN000;*/
   char *cptr;                                                         /*;AN000;*/
   char *sptr;                                                         /*;AN000;*/

   /* take out leading spaces, point to beginning of parameter */
   for (((int)sptr) = inregs.x.si; ((int)sptr) < outregs.x.si && *sptr == BLANK; sptr++)  /*;AN000;*/
      /* null statement */ ;                                           /*;AN000;*/

   /* find end of this parameter in command line and put end-of-string there */
   for (cptr = sptr; ((int)cptr) < outregs.x.si && *cptr != BLANK; cptr++)    /*;AN000;*/
      /* null statement */ ;                                           /*;AN000;*/
   *cptr = NUL;                                                        /*;AN000;*/
   strcpy(error_file_name,sptr);                                       /*;AN000;*/

   /* check for messages with no parameter */
   if (error_num == p_op_missing)                                      /*;AN000;*/
      Error_exit(ERR_PARSE,error_num,NOSUBCNT);                        /*;AN000;*/
   else                                                                /*;AN000;*/
      Error_exit(ERR_PARSE,error_num,ONEPARM);                         /*;AN000;*/
}                                                                      /*;AN000;*/




/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                                                                           */
/*     Subroutine Name:     ctl_brk_handler                                  */
/*                                                                           */
/*     Subroutine Function:                                                  */
/*        Crtl-break interrupt handler.                                      */
/*                                                                           */
/*    Input:  none                                                           */
/*                                                                           */
/*    Output: none                                                           */
/*                                                                           */
/*    Normal exit:                                                           */
/*                                                                           */
/*    Error exit: None                                                       */
/*                                                                           */
/*    Internal References:                                                   */
/*              None                                                         */
/*                                                                           */
/*    External References:                                                   */
/*              None                                                         */
/*                                                                           */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
void ctl_brk_handler()
{
   Reset_appendx();
   exit(3);                                                            /*;AN000;*/
/* inregs.x.ax = 0x4c03;     /* DOS terminate int call */              /*;AN000;*/
/* intdos(&inregs,&outregs);                                           /*;AN000;*/
}
