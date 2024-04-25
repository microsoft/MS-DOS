/*    */
/**************************************************************************/
/*                                                                        */
/*  UTILITY NAME:      Join                                               */
/*                                                                        */
/*  SOURCE FILE NAME:  Join.C                                             */
/*                                                                        */
/*  STATUS:            Join Utility, DOS Version 4.0                      */
/*                                                                        */
/*  FUNCTIONAL DESCRIPTION:  This utility allows the splicing of a        */
/*    physical drive to a pathname on another physical drive such that    */
/*    operations performed using the pathname as an argument take place   */
/*    on the physical drive.                                              */
/*                                                                        */
/*  SYNTAX:            [d:][path]JOIN                      or             */
/*                     [d:][path]JOIN d: d:\directory      or             */
/*                     [d:][path]JOIN d: /D                               */
/*            where:                                                      */
/*                     [d:][path] to specify the drive and path that      */
/*                     contains the JOIN command file, if it is not       */
/*                     in the current directory of the default drive.     */
/*                                                                        */
/*                     d: to specify the drive to be connected to a       */
/*                     directory on another drive.                        */
/*                                                                        */
/*                     d:\directory to specify the directory that         */
/*                     you will join a drive under.  The directory        */
/*                     must be at the root and only one level deep.       */
/*                                                                        */
/*                     /D to disconnect a join.  You must specify the     */
/*                        drive letter of the drive whose join you        */
/*                        want to delete.                                 */
/*                                                                        */
/*  LINKS:                                                                */
/*    CDS.C       - Functions to get/set DOS CDS structures               */
/*    DPB.C       - Functions to get DOS DPB structures                   */
/*    ERRTST.C    - Drive and path validity testing functions             */
/*    SYSVAR.C    - Functions to get/set DOS System Variable structures   */
/*    COMSUBS.LIB - DOS DBCS function calls                               */
/*    MAPPER.LIB  - DOS function calls                                    */
/*    SLIBC3.LIB  - C library functions                                   */
/*    _MSGRET.SAL - Assembler interface for common DOS message services   */
/*    _PARSE.SAL  - Assembler interface for common DOS parser             */
/*                                                                        */
/*  ERROR HANDLING:    Error message displayed and utility is terminated. */
/*                                                                        */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  */
/*                                                                        */
/*  MODIFICATIONS:                                                        */
/*                                                                        */
/*  Converted to CMERGE 03/26/85 by GregT	                          */
/*                                                                        */
/*  M000        May 23/85       Barrys                                    */
/*  Disallow splicing similar drives.                                     */
/*                                                                        */
/*  M001        May 24/85       Barrys                                    */
/*  The original IBM version of JOIN allowed the delete splice switch     */
/*  "/D" immediately after the drive specification.  The argument parsing */
/*  code has been Revised to allow this combination.                     */
/*                                                                        */
/*  M002        June 5/85       Barrys                                    */
/*  Changed low version check for specific 320.                           */
/*                                                                        */
/*  M003        July 15/85      Barrys                                    */
/*  Checked for any possible switch characters in the other operands.     */
/*                                                                        */
/*  M004        July 15/85      Barrys                                    */
/*  Moved check for physical drive before check for NET and SHARED tests. */
/*                                                                        */
/*  33D0016     July 16/86      RosemarieG	                          */
/*  Put SHARED test on an equal basis with physical drive check.          */
/*  Last fix (M004) erroneously allowed joining physical or local shared  */
/*  drives.  This is because it only performed the SHARED test if the     */
/*  drive failed the physical test.                                       */
/*                                                                        */
/*              May /87         SusanM	                                  */
/*  Deletion of source code dealing with parsing and displaying messages  */
/*  and addition of SYSLOADMSG, SYSDISPMSG, SYSPARSE in order to conform  */
/*  to DOS Version 4.0 specifications to utilize common DOS parser and    */
/*  message service routines.                                             */
/*                                                                        */
/*  AC000:  Changed code for DOS Version 4.0         S.M 5/87	          */
/*                                                                        */
/*  AN000:  New code for DOS Version 4.0             S.M 5/87	          */
/*            AN000;M = message services                                  */
/*            AN000;P = parser service                                    */
/*                                                                        */
/*  Ax001:  Changed code req'd - PTM0003919          S.M 3/88	          */
/*            Incorrect message response                                  */
/*                                                                        */
/*  Ax002:  Changed code req'd - PTM0004046          S.M 3/88	          */
/*            Incomplete message response                                 */
/*                                                                        */
/**************************************************************************/

#include "cds.h"
#include "ctype.h"
#include "dos.h"
#include "joinpars.h"                                                          /* ;AN000;P Parser structures */
#include "jointype.h"
#include "stdio.h"
#include "sysvar.h"

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ PARSE EQUATES ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
#define ASCII_DRIVE       'A'-1                                                /* ;AN000;P Convert to Ascii drive */
#define CAPRESULT         0x0001                                               /* ;AN000;P Cap result by file table */
#define DRVONLY_OPT       0x0101                                               /* ;AN000;P Drive only & optional */
#define ERRORLEVEL1       1                                                    /* ;AN000;P Parsing error occurred */
#define FILESPEC_OPT      0x0201                                               /* ;AN000;P File spec & optional */
#define MAXPOSITION       2                                                    /* ;AN000;P Max positionals in cmdline */
#define MINPOSITION       0                                                    /* ;AN000;P Min positionals in cmdline */
#define NOCAPPING         0x0000                                               /* ;AN000;P Do not cap result */
#define SWITCH_OPT        0x0000                                               /* ;AN000;P Optional switch */

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ MESSAGE EQUATES ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
#define MSG_NOMEM         1                                                    /* ;AN000;M Insufficient memory */
#define MSG_PARMNUM       2                                                    /* ;AN000;M Too many parameters */
#define MSG_DIRNEMP       3                                                    /* ;AN000;M Directory not empty */
#define MSG_BADPARM       4                                                    /* ;AN000;M Invalid parameter */
#define MSG_NETERR        5                                                    /* ;AN000;M Cannot %1 a network drive */
#define MSG_INVSWTCH      6                                                    /* ;AN000;M Invalid switch */

#define BLNK              ' '                                                  /* ;AN000;M For sublist.pad_char */
#define CARRY             0x0001                                               /* ;AN000;M Check carry flag */
#define D_SWITCH          "/D"                                                 /* ;AN000;M Only 1 switch */
#define EXT_ERR_CLASS     0x01                                                 /* ;AN000;M DOS Extended error class */
#define FALSE             0
#define MAX               256
#define MAXWIDTH          0                                                    /* ;AN000;M 0 ensures no padding */
#define MINWIDTH          1                                                    /* ;AN000;M At least 1 char in parm */
#define NO_HANDLE         0xffff                                               /* ;AN000;M No handle specified */
#define NO_INPUT          0x00                                                 /* ;AN000;M No input characters */
#define NO_REPLACE        0x00                                                 /* ;AN000;M No replacable parameters */
#define NULL              0
#define PARSE_ERR_CLASS   0x02                                                 /* ;AN000;M Parse error class */
#define RESERVED          0                                                    /* ;AN000;M Reserved byte field */
#define STDERR            0x0002                                               /* ;AN000;M Standard error device handle */
#define STDOUT            0x0001                                               /* ;AN000;M Std output device handle */
#define STR_INPUT         16                                                   /* ;AN000;M Byte def for sublist.flags */
#define SUB_ID1           1                                                    /* ;AN000;M Only 1 replaceable parameter */
#define SUBCNT0           0                                                    /* ;AN000;M 0 substitutions in message */
#define SUBCNT1           1                                                    /* ;AN000;M 1 substitution in message */
#define SUBLIST_LENGTH    11                                                   /* ;AN000;M Length of sublist structure */
#define UTILITY_CLASS     0x0ff                                                /* ;AN000;M Utility message class */

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ MISCELLANEOUS ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
extern char *strchr() ;                                                        /* M003 */
extern char *strbscan() ;                                                      /* SM extern'd */

char cmdln_drive[64]   = {0} ;                                                 /* ;AN002; Save user's input in   */
char cmdln_flspec[64]  = {0} ;                                                 /* ;AN002; order to pass to error */
char cmdln_invalid[64] = {0} ;                                                 /* ;AN002; */
char cmdln_switch[64]  = {0} ;                                                 /* ;AN002; message, if needed     */
char fix_es_reg[1] ;                                                           /* ;AN000;P Corrects es reg after type-"far" */
char p_drive[3]        = {0} ;                                                 /* ;AN000;P Recvs drive ltr from parser */
char p_filespec[64]    = {0} ;                                                 /* ;AN000;P Recvs filespec from parser */
char replparm_JOIN[]   = "JOIN" ;                                              /* ;AN000;P Cannot JOIN a network drv */

unsigned char source[MAX] = {0} ;                                              /* ;AN000;P buffer for string manipulation */

struct sysVarsType SysVars ;

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ PARSE STRUCTURES ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
struct p_parms  p_p ;                                                          /* ;AN000;P # of extras & pts to descrptn */
struct p_parmsx p_px ;                                                         /* ;AN000;P min/max parms & pts to controls */
struct p_control_blk p_con1 ;                                                  /* ;AN000;P 1st posit parm in cmd str */
struct p_control_blk p_con2 ;                                                  /* ;AN000;P 2nd posit parm in cmd str */
struct p_switch_blk p_swi1 ;                                                   /* ;AN000;P /D switch in cmd str */
struct p_result_blk rslt1 ;                                                    /* ;AN000;P Result blk rtrnd from parser */
struct p_fresult_blk rslt2 ;                                                   /* ;AN000;P Result blk rtrnd from parser */
struct p_result_blk rslt3 ;                                                    /* ;AN000;P Result blk rtrnd from parser */
struct noval novals = {0} ;                                                    /* ;AN000;P Value list not used */

union REGS inregs, outregs ;                                                   /* ;AN000;P Define register variables */

/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   main (program entry point)                         */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Preload message file                            */
/*                        Get the command line parameters                 */
/*                        Parse the command line by calling SYSPARSEC     */
/*                        Verify the correctness of the parameters        */
/*                        Check for splice deletion switch                */
/*                        Determine if directory not empty                */
/*                        Check source and destination drives not same    */
/*                        Determine if network or shared drive            */
/*                        Determine if currently spliced                  */
/*                        Determine if existing dir or can't mkdir        */
/*                        Print messages by calling SYSDISPMSG            */
/*                                                                        */
/*  EXTERNAL ROUTINES:    SYSLOADMSG                                      */
/*                        SYSDISPMSG                                      */
/*                        SYSPARSE                                        */
/*                                                                        */
/*  INTERNAL ROUTINES:    DoList                Parser_Prep               */
/*                        Load_Msg              dispmsg_terminate         */
/*                        Display_Msg                                     */
/*                                                                        */
/**************************************************************************/

main(c, v)
int c ;
char *v[] ;
{
  struct findType findbuf ;
  struct CDSType CDS ;

  char path [MAXPATHLEN],*p ;
  char far * fptr ;                                                            /* ;AN000;P Pointer to parser's buffer */

  int delflag      = FALSE ;                                                   /* M001 delete splice flag */
  int dstdrv ;                                                                 /* M000 dest. drive number */
  int fchar        = 0 ;                                                       /* ;AN000;P Parser filespec chars */
  int i ;
  int index ;                                                                  /* ;AN000;P Used in creating cmdline string */
  int more_toparse = TRUE ;                                                    /* ;AN000;P While parsing cmdline */
  int pdrive_flg   = FALSE ;                                                   /* ;AN000;P Is there a drive letter? */
  int pflspec_flg  = FALSE ;                                                   /* ;AN000;P Is there a filespec? */

/************************ BEGIN ***********************************************/

  load_msg() ;                                                                 /* ;AN000;M Point to msgs & chks DOS ver */

  for (index = 1; index <= c; index++)                                         /* ;AN000;P Loop through end of cmd line */
  {                                                                            /* ;AN000;P */
    strcat(source,v[index]) ;                                                  /* ;AN000;P Add the argument */
    strcat(source," ") ;                                                       /* ;AN000;P Separate with a space */
  }                                                                            /* ;AN000;P */
  Parser_Prep(source) ;                                                        /* ;AN000;P Initialization for the parser */

  while (more_toparse)                                                         /* ;AN000;P test the flag */
  {                                                                            /* ;AN000;P */
    index = 0 ;                                                                /* ;AN002; Init array index */
    parse(&inregs,&outregs) ;                                                  /* ;AN000;P call the parser */
    if (outregs.x.ax == P_No_Error)                                            /* ;AN000;P if no error */
    {                                                                          /* ;AN000;P */
      if (outregs.x.dx == (unsigned short)&rslt1)                              /* ;AN000;P if result is drv ltr */
      {                                                                        /* ;AN000;P */
        p_drive[0] = *(rslt1.p_result_buff) ;                                  /* ;AN000;P save the drive letter */
        p_drive[0] += (char)ASCII_DRIVE ;                                      /* ;AN000;P */
        p_drive[1] = COLON ;                                                   /* ;AN000;P */
        pdrive_flg = TRUE ;                                                    /* ;AN000;P and set the flag */
        for (inregs.x.si ; inregs.x.si < outregs.x.si ; inregs.x.si++)         /* ;AN002; Copy whatever */
        {                                                                      /* ;AN002; parser just parsed */
          cmdln_drive[index] = *(char *)inregs.x.si ;                          /* ;AN002; */
          index++ ;                                                            /* ;AN002; */
        }                                                                      /* ;AN002; */
      }                                                                        /* ;AN000;P */
      else                                                                     /* ;AN000;P */
        if (outregs.x.dx == (unsigned short)&rslt2)                            /* ;AN000;P if result is filespec */
        {                                                                      /* ;AN000;P */
          for (fptr = rslt2.fp_result_buff; (char)*fptr != NULL; fptr++)       /* ;AN000;P Point to parser's buffer */
          {                                                                    /* ;AN000;P */
            p_filespec[fchar] = (char)*fptr ;                                  /* ;AN000;P Copy char */
            fchar++ ;                                                          /* ;AN000;P */
          }                                                                    /* ;AN000;P */
          strcpy(fix_es_reg,NULL) ;                                            /* ;AN000;P (Set es reg correct) */
          pflspec_flg = TRUE ;                                                 /* ;AN000;P and set the flag */
          for (inregs.x.si ; inregs.x.si < outregs.x.si ; inregs.x.si++)       /* ;AN002; Copy whatever */
          {                                                                    /* ;AN002; parser just parsed */
            cmdln_flspec[index] = *(char *)inregs.x.si ;                       /* ;AN002; */
            index++ ;                                                          /* ;AN002; */
          }                                                                    /* ;AN002; */
        }                                                                      /* ;AN000;P */
        else                                                                   /* ;AN000;P */
        {                                                                      /* ;AN000;P */
          for (inregs.x.si ; inregs.x.si < outregs.x.si ; inregs.x.si++)       /* ;AN002; Copy whatever */
          {                                                                    /* ;AN002; parser just parsed */
            cmdln_switch[index] = *(char *)inregs.x.si ;                       /* ;AN002; */
            index++ ;                                                          /* ;AN002; */
          }                                                                    /* ;AN002; */
          if (!delflag)                                                        /* ;AN000;P Check for dup switch */
            delflag = TRUE ;                                                   /* ;AN000;P it's /D switch */
          else                                                                 /* ;AN000;P else it's a dup switch */
            dispmsg_terminate(MSG_INVSWTCH,cmdln_switch) ;                     /* ;AN000;P display msg & end */
        }                                                                      /* ;AN000;P */
    }                                                                          /* ;AN000;P */
    else                                                                       /* ;AN000;P */
      if (outregs.x.ax != P_RC_EOL)                                            /* ;AN000;P there must be an error */
      {                                                                        /* ;AN000;P */
        for (inregs.x.si ; inregs.x.si < outregs.x.si ; inregs.x.si++)         /* ;AN002; Copy whatever */
        {                                                                      /* ;AN002; parser just parsed */
          cmdln_invalid[index] = *(char *)inregs.x.si ;                        /* ;AN002; */
          index++ ;                                                            /* ;AN002; */
        }                                                                      /* ;AN002; */
        switch (outregs.x.ax)                                                  /* ;AN000;P See what error the    */
        {                                                                      /* ;AN000;P parser may have found */
          case P_Too_Many     :  dispmsg_terminate(MSG_PARMNUM,cmdln_invalid) ; /* ;AN002; Too many parameters */
                                 break ;                                       /* ;AN000;P more_toparse = FALSE */
          case P_Not_In_SW    :  dispmsg_terminate(MSG_INVSWTCH,cmdln_invalid) ;/* ;AN002; Invalid switch */
                                 break ;                                       /* ;AN000;P more_toparse = FALSE */
          case P_Op_Missing   :                                                /* ;AN000;P Required operand missing */
          case P_Not_In_Key   :                                                /* ;AN000;P Not in kywrd list provided */
          case P_Out_Of_Range :                                                /* ;AN000;P Out of range specified */
          case P_Not_In_Val   :                                                /* ;AN000;P Not in val list provided */
          case P_Not_In_Str   :                                                /* ;AN000;P Not in strg list provided */
          case P_Syntax       :  dispmsg_terminate(MSG_BADPARM,cmdln_invalid) ; /* ;AN000;P incorrect syntax */
                                 break ;                                       /* ;AN000;P more_toparse = FALSE */
          default             :  dispmsg_terminate(MSG_BADPARM,cmdln_invalid) ; /* ;AN000;P */
                                 break ;                                       /* ;AN000;P more_toparse = FALSE */
        }                                                                      /* ;AN000;P */
      }                                                                        /* ;AN000;P */
      else                                                                     /* ;AN000;P */
        more_toparse = FALSE ;                                                 /* ;AN000;P End of the cmdline */
    inregs.x.cx = outregs.x.cx ;                                               /* ;AN000;P Move the count */
    inregs.x.si = outregs.x.si ;                                               /* ;AN000;P Move the pointer */
  }                                                                            /* ;AN000;P */

  if (pdrive_flg && !(pflspec_flg || delflag))                                 /* ;AN000;P drive & no flspec or delete ? */
    dispmsg_terminate(MSG_BADPARM,cmdln_drive) ;                               /* ;AN000;P display error msg & exit utility */

  if (pflspec_flg && !pdrive_flg)                                              /* ;AN000;P filespec & no drive ? */
    dispmsg_terminate(MSG_BADPARM,cmdln_flspec) ;                              /* ;AN000;P display error msg & exit utility */

  if (delflag && !pdrive_flg)                                                  /* ;AN000;P delete & no drive ? */
    dispmsg_terminate(MSG_BADPARM,cmdln_switch) ;                              /* ;AN000;P display error msg & exit utility */

  if (pdrive_flg && pflspec_flg && delflag)                                    /* ;AN000;P drive, filespec & /D ? */
    dispmsg_terminate(MSG_PARMNUM,cmdln_switch) ;                              /* ;AN000;P display error msg & exit utility */

  GetVars(&SysVars) ;                                                          /* Access to DOS data structures */
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000;P (Set es reg correct) */

  if (c == 1)
    DoList() ;                                                                 /* list splices */
  else
  {
    i = p_drive[0] - 'A' ;                                                     /* ;AC000;P Convert to drv # */
    if (!fGetCDS(i, &CDS))
      dispmsg_terminate(MSG_BADPARM,cmdln_drive) ;                             /* ;AC000;M display error msg & exit utility */

    strcpy(fix_es_reg,NULL) ;                                                  /* ;AN000;P (Set es reg correct) */
    if (delflag == TRUE)                                                       /* Deassigning perhaps? */
    {
      if (!TESTFLAG(CDS.flags, CDSSPLICE))
        dispmsg_terminate(MSG_BADPARM,cmdln_switch) ;                          /* ;AC000;M If NOT spliced */

      if (fPathErr(CDS.text))
        dispmsg_terminate(MSG_BADPARM,cmdln_drive) ;                           /* ;AC000;M If prefix of curdir */

      CDS.text[0] = i + 'A' ;
      CDS.text[1] = ':' ;
      CDS.text[2] = '\\' ;
      CDS.text[3] = 0 ;
      CDS.cbEnd = 2 ;

      if (i >= SysVars.cDrv)
        CDS.flags = FALSE ;
      else
        CDS.flags = CDSINUSE ;
      GetVars(&SysVars) ;
      strcpy(fix_es_reg,NULL) ;                                                /* ;AN000;P (Set es reg correct) */
      SysVars.fSplice-- ;
      PutVars(&SysVars) ;
      strcpy(fix_es_reg,NULL) ;                                                /* ;AN000;P (Set es reg correct) */
      fPutCDS(i, &CDS) ;
      strcpy(fix_es_reg,NULL) ;                                                /* ;AN000;P (Set es reg correct) */
    }
    else
    {
      if (TESTFLAG(CDS.flags,CDSSPLICE))
        dispmsg_terminate(MSG_BADPARM,cmdln_drive) ;                           /* ;AC000; If now spliced */

      rootpath(p_filespec,path) ;                                              /* Get root path */

      if (i == getdrv() ||                                                     /* M004 Start */ /* Can't mov curdrv */
         !fPhysical(i)  ||                                                     /* ;AC000; */
         fShared(i))                                                           /* 33D0016   RG    */
      {                                                                        /* Determine if it was a NET error */
        if (fNet(i) || fShared(i))
          dispmsg_terminate(MSG_NETERR) ;                                      /* ;AC000;M display error msg & exit utility */
        dispmsg_terminate(MSG_BADPARM,cmdln_drive) ;                           /* ;AC000;M display error msg & exit utility */
      }

      strcpy(fix_es_reg,NULL) ;                                                /* ;AN000;P (Set es reg correct) */
      if (fPathErr(path) || *strbscan(path+3, "/\\") != 0)                     /* or curdir prefix */
        dispmsg_terminate(MSG_BADPARM,cmdln_flspec) ;                          /* ;AC000; */

      strcpy(fix_es_reg,NULL) ;                                                /* ;AN000;P (Set es reg correct) */
      if (fNet(path[0] - 'A') || fShared(path[0] - 'A'))
        dispmsg_terminate(MSG_NETERR) ;                                        /* ;AC000;M display error msg & exit utility */

      strcpy(fix_es_reg,NULL) ;                                                /* ;AN000;P (Set es reg correct) */
      dstdrv = *path - 'A' ;                                                   /* M000 Check src and dst drvs ar not same */
      if (i == dstdrv)                                                         /* M000 */
        dispmsg_terminate (MSG_BADPARM,cmdln_flspec) ;                         /* M000 */ /* ;AC000; */
      if (mkdir(path) == -1)                                                   /* If can't mkdir or if no dir or */
      {                                                                        /* if note is file  */
        if (ffirst(path, A_D, &findbuf) == -1 ||
           !TESTFLAG(findbuf.attr,A_D))
          dispmsg_terminate(MSG_BADPARM,cmdln_flspec) ;                        /* ;AC000;M display error msg & exit utility */

        p = path + strlen(path) ;
        strcat(p, "\\*.*") ;

        if (ffirst(path, 0, &findbuf) != -1)
          dispmsg_terminate(MSG_DIRNEMP,cmdln_flspec) ;                        /* ;AC001;M If dir not empty */

        *p = 0 ;
      }

      strcpy(CDS.text, path) ;
      CDS.flags = CDSINUSE | CDSSPLICE ;
      fPutCDS(i, &CDS) ;
      strcpy(fix_es_reg,NULL) ;                                                /* ;AN000;P (Set es reg correct) */
      GetVars(&SysVars) ;
      strcpy(fix_es_reg,NULL) ;                                                /* ;AN000;P (Set es reg correct) */
      SysVars.fSplice++ ;
      PutVars(&SysVars) ;
      strcpy(fix_es_reg,NULL) ;                                                /* ;AN000;P (Set es reg correct) */
    }
  }
  exit(0) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

DoList()                                                                       /* Print list of cur joins */
{
  int i ;
  struct CDSType CDS ;

  for (i=0 ; fGetCDS(i, &CDS) ; i++)
  {
    if (TESTFLAG(CDS.flags,CDSSPLICE))
      printf("%c: => %s\n", i+'A', CDS.text) ;
  }
  return ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   load_msg                                           */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Load the set of SUBST Utility messages to       */
/*                        become available for display_msg call.          */
/*                                                                        */
/*  ERROR EXIT:        Utility will be terminated by sysloadmsg if        */
/*                     version check is incorrect.                        */
/*                                                                        */
/*  EXTERNAL REF:      SYSLOADMSG                                         */
/*                                                                        */
/**************************************************************************/

load_msg()                                                                     /* ;AN000;M */
{                                                                              /* ;AN000;M */
   sysloadmsg(&inregs,&outregs) ;                                              /* ;AN000;M Load utility messages */
   if (outregs.x.cflag & CARRY)                                                /* ;AN000;M If problem loading msgs */
   {                                                                           /* ;AN000;M */
     sysdispmsg(&outregs,&outregs) ;                                           /* ;AN000;M then display the err msg */
     exit(ERRORLEVEL1) ;                                                       /* ;AN000;M and exit utility */
   }                                                                           /* ;AN000;M */
   return ;                                                                    /* ;AN000;M */
}                                                                              /* ;AN000;M */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   display_msg                                        */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  The correct message called by main is displayed */
/*                        to standard out.                                */
/*                                                                        */
/*  INPUT:             msg_num   (message number to display)              */
/*                     outline   (substitution parameter)                 */
/*                                                                        */
/*  OUTPUT:            none                                               */
/*                                                                        */
/*  ERROR EXIT:        Display error message corresponding to number      */
/*                     returned in AX.                                    */
/*                                                                        */
/*  EXTERNAL REF:      SYSDISPMSG                                         */
/*                                                                        */
/**************************************************************************/

display_msg(msg_num,outline)                                                   /* ;AN000;M */
int msg_num ;                                                                  /* ;AN000;M Message number #define'd */
char *outline ;                                                                /* ;AN000;M Substitution parameter */
{                                                                              /* ;AN000;M */
  unsigned char function ;                                                     /* ;AN000;M Y/N response or press key? */
  unsigned int message,                                                        /* ;AN000;M Message number to display */
               msg_class,                                                      /* ;AN000;M Which class of messages? */
               sub_cnt,                                                        /* ;AN000;M Number of substitutions? */
               handle ;                                                        /* ;AN000;M Display where? */

  struct sublist                                                               /* ;AN000;M */
  {                                                                            /* ;AN000;M */
    unsigned char size ;                                                       /* ;AN000;M Points to next sublist */
    unsigned char reserved ;                                                   /* ;AN000;M Required for disp msg */
    unsigned far *value ;                                                      /* ;AN000;M Data pointer */
    unsigned char id ;                                                         /* ;AN000;M Id of substitution parm (%1) */
    unsigned char flags ;                                                      /* ;AN000;M Format of data - (a0sstttt) */
    unsigned char max_width ;                                                  /* ;AN000;M Maximum field width */
    unsigned char min_width ;                                                  /* ;AN000;M Minimum field width */
    unsigned char pad_char ;                                                   /* ;AN000;M char to pad field */
  } sublist ;                                                                  /* ;AN000;M */

  switch (msg_num)                                                             /* ;AN000;M Which msg to display? */
  {                                                                            /* ;AN000;M */
    case MSG_NOMEM   :  function  = NO_INPUT ;                                 /* ;AN000;M Y/N response or press key? */
                        message   = 8 ;                                        /* ;AN000;M Message number to display */
                        msg_class = EXT_ERR_CLASS ;                            /* ;AN000;M Which class of messages? */
                        sub_cnt   = SUBCNT0 ;                                  /* ;AN000;M Number of substitutions? */
                        handle    = STDERR ;                                   /* ;AN000;M Display where? */
                        break ;                                                /* ;AN000;M */
    case MSG_PARMNUM :  function  = NO_INPUT ;                                 /* ;AN000;M Y/N response or press key? */
                        message   = 1 ;                                        /* ;AN000;M Message number to display */
                        msg_class = PARSE_ERR_CLASS ;                          /* ;AN000;M Which class of messages? */
                        sub_cnt   = SUBCNT1 ;                                  /* ;AN000;M Number of substitutions? */
                        handle    = STDERR ;                                   /* ;AN000;M Display where? */
                        break ;                                                /* ;AN000;M */
    case MSG_DIRNEMP :  function  = NO_INPUT ;                                 /* ;AN000;M Y/N response or press key? */
                        message   = 2 ;                                        /* ;AN000;M Message number to display */
                        msg_class = UTILITY_CLASS ;                            /* ;AN000;M Which class of messages? */
                        sub_cnt   = SUBCNT1 ;                                  /* ;AN000;M Number of substitutions? */
                        handle    = STDERR ;                                   /* ;AN000;M Display where? */
                        break ;                                                /* ;AN000;M */
    case MSG_BADPARM :  function  = NO_INPUT ;                                 /* ;AN000;M Y/N response or press key? */
                        message   = 10 ;                                       /* ;AN000;M Message number to display */
                        msg_class = PARSE_ERR_CLASS ;                          /* ;AN000;M Which class of messages? */
                        sub_cnt   = SUBCNT1 ;                                  /* ;AN000;M Number of substitutions? */
                        handle    = STDERR ;                                   /* ;AN000;M Display where? */
                        break ;                                                /* ;AN000;M */
    case MSG_NETERR  :  function  = NO_INPUT ;                                 /* ;AN000;M Y/N response or press key? */
                        message   = 12 ;                                       /* ;AN000;M Message number to display */
                        msg_class = UTILITY_CLASS ;                            /* ;AN000;M Which class of messages? */
                        sub_cnt   = SUBCNT1 ;                                  /* ;AN000;M Number of substitutions? */
                        handle    = STDERR ;                                   /* ;AN000;M Display where? */
                        break ;                                                /* ;AN000;M */
    case MSG_INVSWTCH:  function  = NO_INPUT ;                                 /* ;AN000;M Y/N response or press key? */
                        message   = 3 ;                                        /* ;AN000;M Message number to display */
                        msg_class = PARSE_ERR_CLASS ;                          /* ;AN000;M Which class of messages? */
                        sub_cnt   = SUBCNT1 ;                                  /* ;AN000;M Number of substitutions? */
                        handle    = STDERR ;                                   /* ;AN000;M Display where? */
                        break ;                                                /* ;AN000;M */
    default          :  exit(ERRORLEVEL1) ;                                    /* ;AN000;M */
                        break ;                                                /* ;AN000;M */
  }                                                                            /* ;AN000;M */

  switch (msg_num)                                                             /* ;AN000;M */
  {                                                                            /* ;AN000;M */
    case MSG_NOMEM   :  inregs.x.ax       = message ;                          /* ;AN000;M Insufficient memory */
                        inregs.x.bx       = handle ;                           /* ;AN000;M STDERR */
                        inregs.x.cx       = sub_cnt ;                          /* ;AN000;M SUBCNT0 */
                        inregs.h.dl       = function ;                         /* ;AN000;M NO_INPUT */
                        inregs.h.dh       = msg_class ;                        /* ;AN000;M Extended, Parse or Utility */
                        sysdispmsg(&inregs,&outregs) ;                         /* ;AN000;M Call common msg service */
                        break ;                                                /* ;AN000;M */
    case MSG_INVSWTCH:                                                         /* ;AN000;M Invalid switch */
    case MSG_DIRNEMP :                                                         /* ;AN000;M Directory not empty */
    case MSG_PARMNUM :                                                         /* ;AN000;M Too many parameters */
    case MSG_BADPARM :  sublist.value     = (unsigned far *)outline ;          /* ;AN000;M Invalid parameter */
                        sublist.size      = SUBLIST_LENGTH ;                   /* ;AN000;M */
                        sublist.reserved  = RESERVED ;                         /* ;AN000;M */
                        sublist.id        = 0 ;                                /* ;AN000;M */
                        sublist.flags     = STR_INPUT ;                        /* ;AN000;M */
                        sublist.max_width = MAXWIDTH ;                         /* ;AN000;M */
                        sublist.min_width = MINWIDTH ;                         /* ;AN000;M */
                        sublist.pad_char  = (unsigned char)BLNK ;              /* ;AN000;M */
                        inregs.x.ax       = message ;                          /* ;AN000;M Cannot JOIN a network drive */
                        inregs.x.bx       = handle ;                           /* ;AN000;M STDERR */
                        inregs.x.si       = (unsigned int)&sublist ;           /* ;AN000;M Point to the substitution buffer */
                        inregs.x.cx       = sub_cnt ;                          /* ;AN000;M SUBCNT1 */
                        inregs.h.dl       = function ;                         /* ;AN000;M STR_INPUT */
                        inregs.h.dh       = msg_class ;                        /* ;AN000;M Extended, Parse or Utility */
                        sysdispmsg(&inregs,&outregs) ;                         /* ;AN000;M Call common msg service */
                        break ;                                                /* ;AN000;M */
    case MSG_NETERR  :  sublist.value     = (unsigned far *)replparm_JOIN ;    /* ;AN000;M Cannot JOIN a network drive */
                        sublist.size      = SUBLIST_LENGTH ;                   /* ;AN000;M */
                        sublist.reserved  = RESERVED ;                         /* ;AN000;M */
                        sublist.id        = SUB_ID1 ;                          /* ;AN000;M */
                        sublist.flags     = STR_INPUT ;                        /* ;AN000;M */
                        sublist.max_width = MAXWIDTH ;                         /* ;AN000;M */
                        sublist.min_width = MINWIDTH ;                         /* ;AN000;M */
                        sublist.pad_char  = (unsigned char)BLNK ;              /* ;AN000;M */
                        inregs.x.ax       = message ;                          /* ;AN000;M Cannot JOIN a network drive */
                        inregs.x.bx       = handle ;                           /* ;AN000;M STDERR */
                        inregs.x.si       = (unsigned int)&sublist ;           /* ;AN000;M Point to the substitution buffer */
                        inregs.x.cx       = sub_cnt ;                          /* ;AN000;M SUBCNT1 */
                        inregs.h.dl       = function ;                         /* ;AN000;M STR_INPUT */
                        inregs.h.dh       = msg_class ;                        /* ;AN000;M Extended, Parse or Utility */
                        sysdispmsg(&inregs,&outregs) ;                         /* ;AN000;M Call common msg service */
                        break ;                                                /* ;AN000;M */
    default          :  exit(ERRORLEVEL1) ;                                    /* ;AN000;M */
                        break ;                                                /* ;AN000;M */
  }                                                                            /* ;AN000;M */

  if (outregs.x.cflag & CARRY)                                                 /* ;AN000;M Is the carry flag set? */
  {                                                                            /* ;AN000;M Then setup regs for extd-err */
    inregs.x.bx = STDERR ;                                                     /* ;AN000;M */
    inregs.x.cx = SUBCNT0 ;                                                    /* ;AN000;M */
    inregs.h.dl = NO_INPUT ;                                                   /* ;AN000;M */
    inregs.h.dh = EXT_ERR_CLASS ;                                              /* ;AN000;M */
    sysdispmsg(&inregs,&outregs) ;                                             /* ;AN000;M Call to display ext_err msg */
    exit(ERRORLEVEL1) ;                                                        /* ;AN000;M */
  }                                                                            /* ;AN000;M */
  return ;                                                                     /* ;AN000;M */
}                                                                              /* ;AN000;M */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   dispmsg_terminate                                  */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Display the message, then terminate the utility.*/
/*                                                                        */
/*  INPUT:             msg_num     (#define'd message to display)         */
/*                     outline     (substitution parameter)               */
/*                                                                        */
/**************************************************************************/

dispmsg_terminate(msg_num,outline)                                             /* ;AN000;P */
int msg_num ;                                                                  /* ;AN000;P Message number #define'd */
char *outline ;                                                                /* ;AN001;P Substitution parameter */
{                                                                              /* ;AN000;P */
  display_msg(msg_num,outline) ;                                               /* ;AN000;P First, display the msg */
  exit(ERRORLEVEL1) ;                                                          /* ;AN000;P Then, terminate utility */
}                                                                              /* ;AN000;P */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   Parser_Prep                                        */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Initialize all structures for the parser.       */
/*                                                                        */
/*  INPUT:             source (command line string)                       */
/*                                                                        */
/*  OUTPUT:            none                                               */
/*                                                                        */
/*  EXTERNAL REF:      parse                                              */
/*                                                                        */
/**************************************************************************/

Parser_Prep(source)                                                            /* ;AN000;P */
char *source ;                                                                 /* ;AN000;P Commandline */
{                                                                              /* ;AN000;P */
  p_p.p_parmsx_address    = &p_px ;                                            /* ;AN000;P Address of extended parm list */
  p_p.p_num_extra         = 0 ;                                                /* ;AN000;P No extra declarations */

  p_px.p_minp             = MINPOSITION ;                                      /* ;AN000;P */
  p_px.p_maxp             = MAXPOSITION ;                                      /* ;AN000;P */
  p_px.p_control1         = &p_con1 ;                                          /* ;AN000;P Point to 1st control blk */
  p_px.p_control2         = &p_con2 ;                                          /* ;AN000;P Point to 2nd control blk */
  p_px.p_maxs             = 1 ;                                                /* ;AN000;P Specify # of switches */
  p_px.p_switch           = &p_swi1 ;                                          /* ;AN000;P Point to the switch blk */
  p_px.p_maxk             = 0 ;                                                /* ;AN000;P Specify # of keywords */

  p_con1.p_match_flag     = DRVONLY_OPT ;                                      /* ;AN000;P Drive only & optional */
  p_con1.p_function_flag  = NOCAPPING ;                                        /* ;AN000;P Cap result by file table */
  p_con1.p_result_buf     = (unsigned int)&rslt1 ;                             /* ;AN000;P Point to result blk */
  p_con1.p_value_list     = (unsigned int)&novals ;                            /* ;AN000;P Point to no value list */
  p_con1.p_nid            = 0 ;                                                /* ;AN000;P Not a switch id */

  p_con2.p_match_flag     = FILESPEC_OPT ;                                     /* ;AN000;P File spec & optional */
  p_con2.p_function_flag  = CAPRESULT ;                                        /* ;AN000;P Cap result by file table */
  p_con2.p_result_buf     = (unsigned int)&rslt2 ;                             /* ;AN000;P Point to result blk */
  p_con2.p_value_list     = (unsigned int)&novals ;                            /* ;AN000;P Point to no value list */
  p_con2.p_nid            = 0 ;                                                /* ;AN000;P Not a switch id */

  p_swi1.sp_match_flag    = SWITCH_OPT ;                                       /* ;AN000;P Optional (switch) */
  p_swi1.sp_function_flag = NOCAPPING ;                                        /* ;AN000;P Cap result by file table */
  p_swi1.sp_result_buf    = (unsigned int)&rslt3 ;                             /* ;AN000;P Point to result blk */
  p_swi1.sp_value_list    = (unsigned int)&novals ;                            /* ;AN000;P Point to no value list */
  p_swi1.sp_nid           = 1 ;                                                /* ;AN000;P One switch allowed */
  strcpy(p_swi1.sp_keyorsw,D_SWITCH) ;                                         /* ;AN000;P Identify the switch */

  inregs.x.cx = 0 ;                                                            /* ;AN000;P Operand ordinal */
  inregs.x.di = (unsigned int)&p_p ;                                           /* ;AN000;P Address of parm list */
  inregs.x.si = (unsigned int)source ;                                         /* ;AN000;P Make DS:SI point to source */
  return ;                                                                     /* ;AN000; */
}                                                                              /* ;AN000;P */
