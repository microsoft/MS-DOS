/*    */
/**************************************************************************/
/*                                                                        */
/*  UTILITY NAME:      Subst                                              */
/*                                                                        */
/*  SOURCE FILE NAME:  Subst.C						  */
/*                                                                        */
/*  STATUS:            Subst Utility, DOS Version 4.0                     */
/*                                                                        */
/*  FUNCTIONAL DESCRIPTION:  This utility allows the substitution of a    */
/*  physical drive for a pathname on another drive such that operations   */
/*  performed using the physical drive as an argument take place on the   */
/*  pathname.                                                             */
/*                                                                        */
/*  SYNTAX:            [d:][path]SUBST                     or             */
/*                     [d:][path]SUBST d: d:path           or             */
/*                     [d:][path]SUBST d: /D                              */
/*            where:                                                      */
/*                     [d:][path] to specify the drive and path that      */
/*                     contains the SUBST command file                    */
/*                                                                        */
/*                     d: specifies the drive letter that you want        */
/*                     to use to refer to another drive or path.          */
/*                                                                        */
/*                     d:path to specify the drive or path that you       */
/*                     want to refer to with a nickname.                  */
/*                                                                        */
/*                     /D to delete a substitution.  You must specify     */
/*                        the letter of the drive whose substitution      */
/*                        you want to delete.                             */
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
/*  Converted to CMERGE 03/26/85 					  */
/*                                                                        */
/*  M000        June 5/85       					  */
/*  Changed low version check for specific 320.                           */
/*                                                                        */
/*  M001        June 12/85      	                                  */
/*  The original IBM version of SUBST allowed the delete switch "/D"      */
/*  immediately after the drive specification.  The argument parsing code */
/*  has been Revised to allow this combination.                           */
/*                                                                        */
/*  M002        July 3/85       	                                  */
/*  When there are only two operand make sure that there are no additional*/
/*  switch characters.                                                    */
/*                                                                        */
/*  M003        July 9/85       	                                  */
/*  Altered pathname verification tests to so that the same error message */
/*  will result.                                                          */
/*                                                                        */
/*  M004        July 29/85      	                                  */
/*  Only allow 2 characters in the drive name specifier for delete (used  */
/*  to be three).                                                         */
/*                                                                        */
/*              May /87         	                                  */
/*  Deletion of source code dealing with parsing and displaying messages  */
/*  and addition of SYSLOADMSG, SYSDISPMSG, SYSPARSE in order to conform  */
/*  to DOS Version 4.0 specifications to utilize common DOS parser and    */
/*  message service routines.                                             */
/*                                                                        */
/*  AC000:  Changed code for DOS Version 4.0         5/87	          */
/*                                                                        */
/*  AN000:  New code for DOS Version 4.0             5/87	          */
/*            AN000;M = message services                                  */
/*            AN000;P = parser service                                    */
/*                                                                        */
/*  Ax001:  Changed code req'd - PTM0003920          3/88	          */
/*            Incorrect message response                                  */
/*                                                                        */
/*  Ax002:  Changed code req'd - PTM0004045          3/88	          */
/*            Incomplete message response                                 */
/*                                                                        */
/**************************************************************************/

#include "cds.h"
#include "dos.h"
#include "fcntl.h"
#include "jointype.h"
#include "string.h"
#include "substpar.h"                                                          /* ;AN000; Parser structures */
#include "sysvar.h"

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ PARSE EQUATES ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
#define ASCII_DRIVE       'A'-1                                                /* ;AN000;P Convert to Ascii drive */
#define CAPRESULT         0x0001                                               /* ;AN000;P Cap result by file table */
#define DRVONLY_OPT       0x0101                                               /* ;AN000;P Drive only & optional */
#define ERRORLEVEL1       1                                                    /* ;AN000;P Parsing error occurred */
#define FALSE             0
#define FILESPEC_OPT      0x0201                                               /* ;AN000;P File spec & optional */
#define MAX               256                                                  /* ;AN000;P Define a limit */
#define MAXPOSITION       2                                                    /* ;AN000;P Max positionals in cmdline */
#define MINPOSITION       0                                                    /* ;AN000;P Min positionals in cmdline */
#define NOCAPPING         0x0000                                               /* ;AN000;P Do not cap result */
#define NULL              0
#define SWITCH_OPT        0x0000                                               /* ;AN000;P Optional switch */

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ MESSAGE EQUATES ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
#define MSG_PARMNUM       1                                                    /* ;AN000;M Incorrect Num of Parms */
#define MSG_BADPATH       2                                                    /* ;AN000;M Path not Found */
#define MSG_NOMEM         3                                                    /* ;AN000;M Insufficient memory */
#define MSG_BADPARM       4                                                    /* ;AN000;M Invalid parameter */
#define MSG_NETERR        5                                                    /* ;AN000;M Cannot %1 a network drv */
#define MSG_INVSWTCH      6                                                    /* ;AN000;M Invalid switch */

#define BLNK              ' '                                                  /* ;AN000;M For sublist.pad_char */
#define CARRY             0x0001                                               /* ;AN000;M To test carry from msg hndlr */
#define D_SWITCH          "/D"                                                 /* ;AN000;M For switch id */
#define EXT_ERR_CLASS     0x01                                                 /* ;AN000;M DOS Extended error class */
#define MAXWIDTH          0                                                    /* ;AN000;M 0 ensures no padding */
#define MINWIDTH          1                                                    /* ;AN000;M At least 1 char in parm */
#define NO_INPUT          0x00                                                 /* ;AN000;M No input characters */
#define PARSE_ERR_CLASS   0x02                                                 /* ;AN000;M Parse error class */
#define RESERVED          0                                                    /* ;AN000;M Reserved byte field */
#define STDERR            0x0002                                               /* ;AN000;M Standard error device handle */
#define STDOUT            0x0001                                               /* ;AN000;M Std output device handle */
#define STR_INPUT         16                                                   /* ;AN000;M Byte def for sublist.flags */
#define SUB_ID0           0                                                    /* ;AN000;M 0 for error substitution */
#define SUB_ID1           1                                                    /* ;AN000;M Only 1 replaceable parameter */
#define SUBCNT0           0                                                    /* ;AN000;M 0 substitutions in message */
#define SUBCNT1           1                                                    /* ;AN000;M 1 substitution in message */
#define SUBLIST_LENGTH    11                                                   /* ;AN000;M Length of sublist structure */
#define UTILITY_CLASS     0x0ff                                                /* ;AN000;M Utility message class */

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ MISCELLANEOUS ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
extern long GetDPB() ;
extern char fDelete() ;                                                        /* SM '87 compiler required extern */
extern char *malloc() ;                                                        /* SM '87 compiler required extern */
extern char *strbscan() ;                                                      /* SM '87 compiler required extern */

char cmdln_drive[64]   = {0} ;                                                 /* ;AN002; Save user's input in   */
char cmdln_flspec[64]  = {0} ;                                                 /* ;AN002; order to pass to error */
char cmdln_invalid[64] = {0} ;                                                 /* ;AN002; */
char cmdln_switch[64]  = {0} ;                                                 /* ;AN002; message, if needed     */
char fix_es_reg[1] ;                                                           /* ;AN000;P Corrects es reg after type-"far" */
char p_drive[3] ;                                                              /* ;AN000;P Recvs drive ltr from parser */
char p_filespec[64] ;                                                          /* ;AN000;P Recvs filespec from parser */
char replparm_SUBST[]  = "SUBST" ;                                             /* ;AN000;P Cannot SUBST a network drv */

unsigned char source[MAX] = {0} ;                                              /* ;AN000;P buffer for string manipulation */

int index ;                                                                    /* ;AN000;P Used in creating cmdline string */

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
/*                        Parse the command line by calling SYSPARSE      */
/*                        Verify the correctness of the parameters        */
/*                        Check for deletion switch                       */
/*                        Check source path and destination not same      */
/*                        Determine if source or destination is network   */
/*                        Determine if currently spliced                  */
/*                        Print messages by calling SYSDISPMSG            */
/*                                                                        */
/*  EXTERNAL ROUTINES:    SYSLOADMSG                                      */
/*                        SYSDISPMSG                                      */
/*                        SYSPARSE                                        */
/*                                                                        */
/*  INTERNAL ROUTINES:    BackFix           Load_Msg                      */
/*                        fDelete           Display_Msg                   */
/*                        Insert            Parser_Prep                   */
/*                        Display           dispmsg_terminate             */
/*                                                                        */
/**************************************************************************/

main(c, v)
int c ;
char *v[] ;
{
  char far * fptr ;                                                            /* ;AN000;P Pointer to parser's buffer */

  int delflag       = FALSE ;                                                  /* Deletion specified M001 */
  int fchar         = 0 ;                                                      /* ;AN000;P Parser filespec chars */
  int more_to_parse = TRUE ;                                                   /* ;AN000;P While parsing cmdline */
  int pdrive_flg    = FALSE ;                                                  /* ;AN000;P Is there a drive letter? */
  int pflspec_flg   = FALSE ;                                                  /* ;AN000;P Is there a filespec? */

/************************ BEGIN ***********************************************/

  load_msg() ;                                                                 /* ;AN000;M Point to msgs & chk DOS ver */

  for (index = 1; index <= c; index++)                                         /* ;AN000;P Loop through end of cmd line */
  {                                                                            /* ;AN000;P */
    strcat(source,v[index]) ;                                                  /* ;AN000;P Add the argument */
    strcat(source," ") ;                                                       /* ;AN000;P Separate with a space */
  }                                                                            /* ;AN000;P */
  Parser_Prep(source) ;                                                        /* ;AN000;P Initialization for the parser */

  while (more_to_parse)                                                        /* ;AN000;P test the flag */
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
          for (fptr = rslt2.fp_result_buff; (char)*fptr != NULL; fptr++)       /* ;AN000;P From beg of buf til nul */
          {                                                                    /* ;AN000;P */
            p_filespec[fchar] = (char)*fptr ;                                  /* ;AN000;P copy from rslt field buf */
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
          else                                                                 /* ;AN000;P else it's a duplicate switch */
            dispmsg_terminate(MSG_INVSWTCH,cmdln_switch) ;                     /* ;AN000;P display err msg & exit util */
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
          case P_Too_Many     :  dispmsg_terminate(MSG_PARMNUM,cmdln_invalid) ; /* ;AN000;P incorrect syntax */
                                 break ;                                       /* ;AN000;P more_to_parse = FALSE */
          case P_Not_In_SW    :  dispmsg_terminate(MSG_INVSWTCH,cmdln_invalid) ; /* ;AN000;P Invalid switch */
                                 break ;                                       /* ;AN000;P more_to_parse = FALSE */
          case P_Op_Missing   :                                                /* ;AN000;P Required operand missing */
          case P_Not_In_Key   :                                                /* ;AN000;P Not in kywrd list provided */
          case P_Out_Of_Range :                                                /* ;AN000;P Out of range specified */
          case P_Not_In_Val   :                                                /* ;AN000;P Not in val list provided */
          case P_Not_In_Str   :                                                /* ;AN000;P Not in strg list provided */
          case P_Syntax       :  dispmsg_terminate(MSG_BADPARM,cmdln_invalid) ; /* ;AN000;P incorrect syntax */
                                 break ;                                       /* ;AN000;P more_to_parse = FALSE */
          default             :  display_msg(MSG_BADPARM,cmdln_invalid) ;      /* ;AN000;P */
                                 exit(ERRORLEVEL1) ;                           /* ;AN000;P Something's wrong */
        }                                                                      /* ;AN000;P */
      }                                                                        /* ;AN000;P */
      else                                                                     /* ;AN000;P End of the cmdline */
        more_to_parse = FALSE ;                                                /* ;AN000;P */
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

  GetVars(&SysVars) ;
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000;P (Set es reg correct) */

  if (c == 1)                                                                  /* display all tree aliases */
    Display() ;
  else
    if (delflag)                                                               /* ;AC000;P Are we to delete a subst? */
    {
      if (!fDelete(p_drive))
        dispmsg_terminate(MSG_BADPARM,cmdln_drive) ;                           /* :AC002; */
      strcpy(fix_es_reg,NULL) ;                                                /* ;AN000;P (Set es reg correct) */
    }
    else
      Insert(p_drive,p_filespec) ;                                             /* ;AC000;P */

  exit(0) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

char *BackFix(p)
char *p ;
{
  char *p1 ;
  char *p2 ;

  p2 = p-1 ;
  while (*(p2 = strbscan(p1 = p2+1,"\\")) != NULL) ;

  /* p1 points to char after last path sep.                */
  /* If this is a NULL, p already has a trailing path sep. */

  if (*p1 != NULL)
    if ((p1 = malloc(strlen(p)+2)) == NULL)
      dispmsg_terminate(MSG_NOMEM) ;                                           /* ;AN000;M */
    else
    {
      strcpy(p1, p) ;
      strcat(p1, "\\") ;
      p = p1 ;
    }
  return(p) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

char fDelete(v)
char *v ;
{
  struct CDSType CDS ;
  int drive ;

  /* M004 Only 2 characters in the drive specifier */
  /*      (and move before the call to BackFix)    */

  if (strlen(v) != 2 || v[1] != ':')
    return(FALSE) ;

  v = BackFix(v) ;
  drive = *v - 'A' ;

  if (!fGetCDS(drive, &CDS)        ||                                          /* If CDS doesn't exist or */
     !TESTFLAG(CDS.flags,CDSLOCAL) ||                                          /* was not substed or      */
     drive == getdrv())                                                        /* is the current drive    */
    dispmsg_terminate(MSG_BADPARM,cmdln_drive) ;                               /* ;AC000;M */

  strcpy(CDS.text, "A:\\") ;                                                   /* Set-up text of curr directory */
  CDS.text[0] += drive ;
  CDS.cbEnd = 2 ;                                                              /* Set backup limit */

  /* If physical, then mark as inuse and set-up DPB pointer */

  CDS.flags = drive >= SysVars.cDrv ? FALSE : CDSINUSE ;
  CDS.pDPB = drive >= SysVars.cDrv ? 0L : GetDPB(drive) ;

  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000;P (Set es reg correct) */
  fPutCDS(drive, &CDS) ;
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000;P (Set es reg correct) */
  return(TRUE) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Insert(s, d)
char *s, *d ;
{
  struct CDSType CDS ;
  int drives, drived ;
  char buf[MAXPATHLEN] ;

  rootpath(d, buf) ;

  if (strlen(d) == 2 && d[1] == ':')
    dispmsg_terminate(MSG_BADPARM,cmdln_flspec) ;                              /* ;AC000;M Insure dest not just a drive */

  if (strlen(buf) == 3)                                                        /* Dest must exist, try root 1st */
    if (buf[1] != ':' || (buf[2]) != PathChr)
      dispmsg_terminate(MSG_BADPARM,cmdln_flspec) ;                            /* ;AC000;M */

  /* M003 - path verification was treated as an ELSE condition */
  /* else                          Must be subdir... make sure */

  if (open(buf,O_BINARY) != -1)
    dispmsg_terminate(MSG_BADPARM,cmdln_flspec) ;                              /* ;AC000;M */
  else
    if (access(buf,NULL) == -1)
      dispmsg_terminate(MSG_BADPATH,cmdln_flspec) ;                            /* ;AC000;M */

  s = BackFix(s) ;
  d = BackFix(buf) ;
  drives = *s - 'A' ;
  drived = *d - 'A' ;

  if (fNet(drives))                                                            /* Src can't be net drive, is reuse of CDS */
    dispmsg_terminate(MSG_NETERR) ;                                            /* ;AC000;M */

  strcpy(fix_es_reg,NULL);                                                     /* ;AN000;P (Set es reg correct) */
  if (fNet(drived))                                                            /* Dest can't be a net drive either */
    dispmsg_terminate(MSG_NETERR) ;                                            /* ;AC000;M */

  /* If src or dest invalid; or dest too long; or drives the same; or can't */
  /* get CDS for source; or source is current drive; or drive is net,       */
  /* splices or substed already; or destination is not physical             */

  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000;P (Set es reg correct) */
  if (drives < 0 || drives >= SysVars.cCDS ||
     drives == drived                      ||
     !fGetCDS(drives, &CDS)                ||
     drives == getdrv()                    ||
     TESTFLAG(CDS.flags,CDSNET|CDSSPLICE|CDSLOCAL))
    dispmsg_terminate(MSG_BADPARM,cmdln_drive) ;                               /* ;AC000;M */

  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000;P (Set es reg correct) */
  if (drived < 0 || drived >= SysVars.cCDS ||
     strlen(d) >= DIRSTRLEN                ||
     !fPhysical(drived))
    dispmsg_terminate(MSG_BADPARM,cmdln_flspec) ;                              /* ;AC000;M */

  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000;P (Set es reg correct) */
  if (strlen(d) != 3)                                                          /* Chop trailing \ if not at root */
    d[strlen(d)-1] = 0 ;

  strcpy(CDS.text, d) ;
  CDS.cbEnd = strlen(CDS.text) ;
  if (CDS.cbEnd == 3)
    CDS.cbEnd-- ;
  CDS.flags = CDSINUSE|CDSLOCAL ;
  if ((CDS.pDPB = GetDPB(drived)) == -1L)
    dispmsg_terminate(MSG_BADPARM,cmdln_flspec) ;                              /* ;AC000;M */

  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000;P (Set es reg correct) */
  CDS.ID = -1L ;
  fPutCDS(drives, &CDS) ;
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000;P (Set es reg correct) */
  return ;                                                                     /* ;AN000; */
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

Display()                                                                      /* Display current list of substs */
{
  struct CDSType CDS ;
  int i ;

  for (i=0 ; fGetCDS(i, &CDS) ; i++)
    if (TESTFLAG(CDS.flags,CDSLOCAL))
    {
      if (CDS.cbEnd == 2)
        CDS.cbEnd ++ ;
      CDS.text[CDS.cbEnd] = 0 ;
      printf("%c: => %s\n", i+'A', CDS.text) ;
    }
  return ;                                                                     /* ;AN000; */
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
  sysloadmsg(&inregs,&outregs) ;                                               /* ;AN000;M Load utility messages */
  if (outregs.x.cflag & CARRY)                                                 /* ;AN000;M If problem loading msgs */
  {                                                                            /* ;AN000;M */
    sysdispmsg(&outregs,&outregs) ;                                            /* ;AN000;M then display the err msg */
    exit(ERRORLEVEL1) ;                                                        /* ;AN000;M */
  }                                                                            /* ;AN000;M */
  return ;                                                                     /* ;AN000;M */
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
char *outline ;                                                                /* ;AN001; Substitution parameter */
{                                                                              /* ;AN000;M */
  unsigned char function ;                                                     /* ;AN000;M Y/N response or press key? */
  unsigned int message,                                                        /* ;AN000;M Message number to display */
               msg_class,                                                      /* ;AN000;M Which class of messages? */
               sub_cnt,                                                        /* ;AN000;M Number of substitutions? */
               handle ;                                                        /* ;AN000;M Display where? */

  struct sublist                                                               /* ;AN000;M */
  {                                                                            /* ;AN000;M */
    unsigned char size ;                                                       /* ;AN000;M Points to next sublist */
    unsigned char reserved ;                                                   /* ;AN000;M Required for sysdispmsg */
    unsigned far *value ;                                                      /* ;AN000;M Data pointer */
    unsigned char id ;                                                         /* ;AN000;M Id of substitution parm (%1) */
    unsigned char flags ;                                                      /* ;AN000;M Format of data - (a0sstttt) */
    unsigned char max_width ;                                                  /* ;AN000;M Maximum field width */
    unsigned char min_width ;                                                  /* ;AN000;M Minimum field width */
    unsigned char pad_char ;                                                   /* ;AN000;M char to pad field */
  } sublist ;                                                                  /* ;AN000;M */

  switch (msg_num)                                                             /* ;AN000;M Which msg to display? */
  {                                                                            /* ;AN000;M */
    case MSG_PARMNUM :  function  = NO_INPUT ;                                 /* ;AN000;M Y/N response or press key? */
                        message   = 2 ;                                        /* ;AN000;M Message number to display */
                        msg_class = UTILITY_CLASS ;                            /* ;AN000;M Which class of messages? */
                        sub_cnt   = SUBCNT1 ;                                  /* ;AN000;M Number of substitutions? */
                        handle    = STDERR ;                                   /* ;AN000;M Display where? */
                        break ;                                                /* ;AN000;M */
    case MSG_BADPATH :  function  = NO_INPUT ;                                 /* ;AN000;M Y/N response or press key? */
                        message   = 3 ;                                        /* ;AN000;M Message number to display */
                        msg_class = EXT_ERR_CLASS ;                            /* ;AN000;M Which class of messages? */
                        sub_cnt   = SUBCNT1 ;                                  /* ;AN000;M Number of substitutions? */
                        handle    = STDERR ;                                   /* ;AN000;M Display where? */
                        break ;                                                /* ;AN000;M */
    case MSG_NOMEM   :  function  = NO_INPUT ;                                 /* ;AN000;M Y/N response or press key? */
                        message   = 8 ;                                        /* ;AN000;M Message number to display */
                        msg_class = EXT_ERR_CLASS ;                            /* ;AN000;M Which class of messages? */
                        sub_cnt   = SUBCNT0 ;                                  /* ;AN000;M Number of substitutions? */
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
    case MSG_PARMNUM :                                                         /* ;AN000;M Incorrect num of parms */
    case MSG_BADPARM :                                                         /* ;AN000;M Invalid parameter */
    case MSG_BADPATH :  sublist.value     = (unsigned far *)outline ;          /* ;AN000;M Path not found */
                        sublist.reserved  = RESERVED ;                         /* ;AN000;M */
                        sublist.id        = SUB_ID0 ;                          /* ;AN000;M */
                        sublist.flags     = STR_INPUT ;                        /* ;AN000;M */
                        sublist.max_width = MAXWIDTH ;                         /* ;AN000;M */
                        sublist.min_width = MINWIDTH ;                         /* ;AN000;M */
                        sublist.pad_char  = (unsigned char)BLNK ;              /* ;AN000;M */
                        inregs.x.ax       = message ;                          /* ;AN000;M Cannot SUBST a network drive */
                        inregs.x.bx       = handle ;                           /* ;AN000;M STDERR */
                        inregs.x.si       = (unsigned int)&sublist ;           /* ;AN000;M Point to the sub buffer */
                        inregs.x.cx       = sub_cnt ;                          /* ;AN000;M SUBCNT1 */
                        inregs.h.dl       = function ;                         /* ;AN000;M STR_INPUT */
                        inregs.h.dh       = msg_class ;                        /* ;AN000;M Extended, Parse or Utility */
                        sysdispmsg(&inregs,&outregs) ;                         /* ;AN000;M Call common msg service */
                        break ;                                                /* ;AN000;M */
    case MSG_NETERR  :  sublist.value     = (unsigned far *)replparm_SUBST ;   /* ;AN000;M Cannot SUBST a network drive */
                        sublist.reserved  = RESERVED ;                         /* ;AN000;M */
                        sublist.id        = SUB_ID1 ;                          /* ;AN000;M */
                        sublist.flags     = STR_INPUT ;                        /* ;AN000;M */
                        sublist.max_width = MAXWIDTH ;                         /* ;AN000;M */
                        sublist.min_width = MINWIDTH ;                         /* ;AN000;M */
                        sublist.pad_char  = (unsigned char)BLNK ;              /* ;AN000;M */
                        inregs.x.ax       = message ;                          /* ;AN000;M Cannot SUBST a network drive */
                        inregs.x.bx       = handle ;                           /* ;AN000;M STDERR */
                        inregs.x.si       = (unsigned int)&sublist ;           /* ;AN000;M Point to the sub buffer */
                        inregs.x.cx       = sub_cnt ;                          /* ;AN000;M SUBCNT1 */
                        inregs.h.dl       = function ;                         /* ;AN000;M STR_INPUT */
                        inregs.h.dh       = msg_class ;                        /* ;AN000;M Extended, Parse or Utility */
                        sysdispmsg(&inregs,&outregs) ;                         /* ;AN000;M Call common msg service */
                        break ;                                                /* ;AN000;M */
    default          :  exit(ERRORLEVEL1) ;                                    /* ;AN000;M */
                        break ;                                                /* ;AN000;M */
  }                                                                            /* ;AN000;M */

    if (outregs.x.cflag & CARRY)                                               /* ;AN000;M Is the carry flag set? */
    {                                                                          /* ;AN000;M Then setup regs for extd-err */
      inregs.x.bx = STDERR ;                                                   /* ;AN000;M */
      inregs.x.cx = SUBCNT0 ;                                                  /* ;AN000;M */
      inregs.h.dl = NO_INPUT ;                                                 /* ;AN000;M */
      inregs.h.dh = EXT_ERR_CLASS ;                                            /* ;AN000;M */
      sysdispmsg(&inregs,&outregs) ;                                           /* ;AN000;M Call to display ext_err msg */
      exit(ERRORLEVEL1) ;                                                      /* ;AN000;M */
    }                                                                          /* ;AN000;M */
    return ;                                                                   /* ;AN000;M */
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
char *outline ;                                                                /* ;AN001; Substitution parameter */
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
