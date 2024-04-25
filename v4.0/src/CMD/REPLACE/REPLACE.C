/*  0  */
/**************************************************************************/
/*                                                                        */
/*  UTILITY NAME:      Replace                                            */
/*                                                                        */
/*  SOURCE FILE NAME:  Replace.C     					  */
/*                                                                        */
/*  STATUS:            Replace Utility, DOS Version 4.00                  */
/*                                                                        */
/*  FUNCTIONAL DESCRIPTION:  REPLACE is an external DOS utility that      */
/*                           allows a user to selectively replace         */
/*                           files on the target with files of the        */
/*                           same name from the source.  The user can     */
/*                           also selectively add files from the source   */
/*                           to the target.                               */
/*                                                                        */
/*  SYNTAX:            [d:][path]REPLACE[d:][path]filename[.ext]          */
/*                     [d:][path] [/A][/P][/R][/S][/U][/W]                */
/*            where:                                                      */
/*                     [d:][path] before REPLACE specifies the drive      */
/*                     and path that contains the REPLACE command file,   */
/*                     if it is not the current directory of the          */
/*                     default drive.                                     */
/*                                                                        */
/*                     [d:][path]filename[.ext] specifies the names of    */
/*                     the files on the source that are to be replaced    */
/*                     on the target or added to the target.  The file    */
/*                     name can contain global file name characters.      */
/*                                                                        */
/*                     [d:][path] specifies the target drive and          */
/*                     directory.  The files in this directory are        */
/*                     the ones that are to be replaced, if /A is         */
/*                     specified the source files are copied to this      */
/*                     directory.  The default is the directory on the    */
/*                     current drive.                                     */
/*                                                                        */
/*                     /A copies all files specified by the source that   */
/*                        do not exist on the target.                     */
/*                                                                        */
/*                     /P prompts as each file is encountered on the tar- */
/*                        get, allowing selective replacing or adding.    */
/*                                                                        */
/*                     /R replaces files that are read-only on the target.*/
/*                                                                        */
/*                     /S searches all directories of the target for      */
/*                        files matching the source file name.            */
/*                                                                        */
/*                     /U replaces updated date/time attribute source     */
/*                        files to the target.                            */
/*                                                                        */
/*                     /W waits for you to insert a diskette before be-   */
/*                        ginning to search for source files.             */
/*                                                                        */
/*         ** NOTE **  /A + /S and A/ + /U cannot be used together.       */
/*                                                                        */
/*  LINKS:                                                                */
/*    COMSUBS.LIB - DOS DBCS function calls                               */
/*    MAPPER.LIB  - DOS function calls                                    */
/*    SLIBC3.LIB  - C library functions                                   */
/*    _MSGRET.SAL - Assembler interface for common DOS message services   */
/*    _PARSE.SAL  - Assembler interface for common DOS parser             */
/*    _REPLACE.SAL- Assembler control break and critical error handlers   */
/*                                                                        */
/*  ERROR HANDLING:    Error message is displayed and utility is          */
/*                     then terminated (with appropriate error level).    */
/*                                                                        */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  */
/*                                                                        */
/*  MODIFICATIONS:                                                        */
/*                                                                        */
/*    RW     :  R. W		                           1986           */
/*                                                                        */
/*    ;AC000;:  Changed code for DOS Version 4.00   S.M    1987           */
/*                                                                        */
/*    ;AN000;:  New code for DOS Version 4.00       S.M    1987           */
/*              ;AN000;A - Append/X                                       */
/*              ;AN000;EA- Extended Attributes                            */
/*              ;AN000;EC- Extended Country Info                          */
/*              ;AN000;M - Message handler                                */
/*              ;AN000;P - Parser                                         */
/*              ;AN000;U - /U (update switch)                             */
/*                                                                        */
/*    ;Ax001;:  New code required - PTM0000001      S.M    1987           */
/*              Set archive bit ON after replace                          */
/*                                                                        */
/*    ;Ax002;:  Change code req'd - PTM0003154      S.M    1988           */
/*              Enable filesize update in directory                       */
/*                                                                        */
/*    ;Ax003;:  Change code req'd - PTM0003753      S.M    1988           */
/*              Dsearchf return garbage                                   */
/*                                                                        */
/*    ;Ax004;:  Change code req'd - PTM0003891      S.M    1988           */
/*              One char subdir name not handled                          */
/*                                                                        */
/*    ;Ax005;:  Change code req'd - PTM0003907      S.M    1988           */
/*              Incorrect message responses                               */
/*                                                                        */
/*    ;Ax006;:  Change code req'd - PTM0004124      S.M    1988           */
/*              Incorrect message responses                               */
/*                                                                        */
/**************************************************************************/

#include "comsub.h"                                                            /* ;AN000;P DBCS functions */
#include "dos.h"                                                               /* ;AN000;M Used for the REGS union */
#include "replacep.h"                                                          /* ;AN000;P Parser structures */

/* ------------- ERRORLEVEL CODES ---------------*/
#define ERRLEVELNEG1      -1                                                   /* ;AC000; */
#define ERRLEVEL0         0                                                    /* ;AC000; No error */
#define ERRLEVEL1         1                                                    /* ;AC000; Invalid function number */
#define ERRLEVEL2         2                                                    /* ;AC000; File not found */
#define ERRLEVEL3         3                                                    /* ;AN000; Path not found */
#define ERRLEVEL8         8                                                    /* ;AC000; Insufficient memory */
#define ERRLEVEL11        11                                                   /* ;AC000; Invalid format */

/* ------------- INT 21h FUNCTIONS --------------*/
#define GETVEC_CRITERR    0x3524                                               /* ;AN000;A Int 21,get vector,criterr */
#define GETVEC_CTLBRK     0x3523                                               /* ;AN000;A Int 21,get vector,ctlbrk */
#define GETX_INSTALL      0xB700                                               /* ;AN000;A Is Append/x installed? */
#define GETX_STATUS       0xB706                                               /* ;AN000;A Get the Append/x status */
#define GETX_VERSION      0xB702                                               /* ;AN000;A Is it the DOS Append/x? */
#define SETVEC_CRITERR    0x2524                                               /* ;AN000;A Int 21,set vector,criterr */
#define SETVEC_CTLBRK     0x2523                                               /* ;AN000;A Int 21,set vector,ctlbrk */
#define SETX_STATUS       0xB707                                               /* ;AN000;A Set the Append/x status */

/* ------------- INT 21h RETURN CODES -----------*/
#define INSUFFMEM         8
#define NOERROR           0
#define NOMOREFILES       18
#define TARGETFULL        -1

/* ------------- MESSAGE EQUATES ----------------*/
#define BLNK              ' '                                                  /* ;AN000;M For sublist.pad_char */
#define CARRY             0x0001                                               /* ;AN000;M */
#define DEC_INPUT         161                                                  /* ;AN000;M Byte def for sublist.flags */
#define DOS_CON_INPUT     0xC8                                                 /* ;AN000;M Input for Y/N response */
#define EXT_ERR_CLASS     0x01                                                 /* ;AN000;M DOS Extended error class */
#define NO_INPUT          0x00                                                 /* ;AN000;M No input characters */
#define PARSE_ERR_CLASS   0x02                                                 /* ;AN000;M Parse error class */
#define RESERVED          0                                                    /* ;AN000;M Reserved byte field */
#define STDERR            0x0002                                               /* ;AN000;M Standard error device handle */
#define STDOUT            0x0001                                               /* ;AN000;M Std output device handle */
#define STR_INPUT         16                                                   /* ;AN000;M Byte def for sublist.flags */
#define SUBCNT0           0                                                    /* ;AN000;M 0 substitutions in message */
#define SUBCNT1           1                                                    /* ;AN000;M 1 substitution in message */
#define SUBLIST_LENGTH    11                                                   /* ;AN000;M Length of sublist structure */
#define UTILITY_CLASS     0x0ff                                                /* ;AN000;M Utility message class */

/* ------------- MESSAGES -----------------------*/
#define MSG_NOMEM         1                                                    /* ;AN000;M Insufficient memory */
#define MSG_INCOMPAT      2                                                    /* ;AN000;M Invalid parameter combo */
#define MSG_NOSOURCE      3                                                    /* ;AN000;M Source path required */
#define MSG_NONEREPL      4                                                    /* ;AN000;M No files replaced */
#define MSG_NONEADDE      5                                                    /* ;AN000;M No files added */
#define MSG_START         6                                                    /* ;AN000;M Press any key to continue */
#define MSG_ERRFNF        7                                                    /* ;AN000;M File not Found */
#define MSG_ERRPNF        8                                                    /* ;AN000;M Path not Found */
#define MSG_ERRACCD       9                                                    /* ;AN000;M Access denied */
#define MSG_ERRDRV        10                                                   /* ;AN000;M Invalid drive specification */
#define MSG_BADPARM       11                                                   /* ;AN000;M Invalid parameter */
#define MSG_WARNSAME      12                                                   /* ;AN000;M File cannot be copied...*/
#define MSG_ERRDSKF       13                                                   /* ;AN000;M Insufficient disk space */
#define MSG_REPLACIN      14                                                   /* ;AN000;M Replacing %1 */
#define MSG_ADDING        15                                                   /* ;AN000;M Adding %1 */
#define MSG_SOMEREPL      16                                                   /* ;AN000;M %1 file(s) replaced */
#define MSG_SOMEADDE      17                                                   /* ;AN000;M %1 file(s) added */
#define MSG_NONFOUND      18                                                   /* ;AN000;M No files found */
#define MSG_QREPLACE      19                                                   /* ;AN000;M Replace %1? (Y/N) */
#define MSG_QADD          20                                                   /* ;AN000;M Add %1? (Y/N) */
#define MSG_XTRAPARM      21                                                   /* ;AN005;M Too many parameters */
#define MSG_BADSWTCH      22                                                   /* ;AN005;M Invalid switch */

/* ------------- PARSE EQUATES ------------------*/
#define A_SW              "/A"                                                 /* ;AN000;P For switch id /A */
#define P_SW              "/P"                                                 /* ;AN000;P For switch id /P */
#define R_SW              "/R"                                                 /* ;AN000;P For switch id /R */
#define S_SW              "/S"                                                 /* ;AN000;P For switch id /S */
#define U_SW              "/U"                                                 /* ;AN000;P For switch id /U */
#define W_SW              "/W"                                                 /* ;AN000;P For switch id /W */
#define CAPRESULT         0x0001                                               /* ;AN000;P Cap result by file table */
#define MAXPOSITION       2                                                    /* ;AN000;P Max positionals allowed */
#define MINPOSITION       1                                                    /* ;AN000;P Min positionals allowed */
#define NOCAPPING         0x0000                                               /* ;AN000;P Do not capitalize */
#define OPT_FILESPEC      0x0201                                               /* ;AN000;P Filespec & optional */
#define OPT_SWITCH        0x0001                                               /* ;AN000;P Optional (switch) */
#define REQ_FILESPEC      0x0200                                               /* ;AN000;P Filespec required */

/* ------------- MISCELLANEOUS ------------------*/
#define ARCHIVE           0x20                                                 /* Archive bit file attribute */
#define BUF               512                                                  /* ;AC000; */
#define FALSE             0
#define INACTIVE          0x0000                                               /* ;AN000;A Append/x inactive status */
#define MAX               256                                                  /* ;AC000; */
#define MAXMINUS1         255                                                  /* ;AC000; */
#define NULL              0
#define SATTRIB           0
#define SUBDIR            0x10
#define TATTRIB           SUBDIR
#define TRUE              !FALSE
#define X_INSTALLED       0xffff                                               /* ;AN000;A Set the Append/x status */

struct filedata                                                                /* ;AC000; Files used in copy operations */
{
  char     attribute ;
  unsigned time ;
  unsigned date ;
  long     size ;
  char     name[15] ;
} ;

struct parm_list                                                               /* ;AN000;EA To be passed to Extd Create */
{
  unsigned ea_list_offset ;                                                    /* ;AN000;EA List structure (filled in) */
  unsigned ea_list_segment ;                                                   /* ;AN000;EA */
  unsigned number ;                                                            /* ;AN000;EA ID for iomode */
  char     format ;                                                            /* ;AN000;EA Format for iomode */
  unsigned iomode ;                                                            /* ;AN000;EA (Mainly sequential) */
} eaparm_list = {                                                              /* ;AN000;EA */
                 -1,                                                           /* ;AN000;EA */
                 -1,                                                           /* ;AN000;EA (will recv segment addr) */
                 1,                                                            /* ;AN000;EA */
                 6,                                                            /* ;AN000;EA */
                 2                                                             /* ;AN000;EA */
                } ;                                                            /* ;AN000;EA */

/* ------------- PARSE STRUCTURES ---------------*/
struct p_parms  p_p ;                                                          /* ;AN000;P # of extras & pts to descrptn */
struct p_parmsx p_px ;                                                         /* ;AN000;P min/max parms & pts to controls */
struct p_control_blk p_con1 ;                                                  /* ;AN000;P 1st posit parm in cmd str */
struct p_control_blk p_con2 ;                                                  /* ;AN000;P 2nd posit parm in cmd str */
struct p_switch_blk  p_swit ;                                                  /* ;AN000;P /A /P /R /S /U /W */
struct p_fresult_blk rslt1 ;                                                   /* ;AN000;P Result blk rtrnd from parser */
struct p_result_blk rslt2 ;                                                    /* ;AN000;P Result blk rtrnd from parser */
struct noval novals = {0} ;                                                    /* ;AN000;P Value list not used */

/* ------------- MISCELLANEOUS ------------------*/
union REGS inregs, outregs ;                                                   /* ;AN000;P Define register variables */
struct SREGS segregs ;                                                         /* ;AN000;  Segment regs for Int21 */

char append_installed    = FALSE ;                                             /* ;AN000;A ? */
char attr_list[BUF]      = {0} ;                                               /* ;AN000;EA Buf for list of attributes */
char cmdln_invalid[64]   = {0} ;                                               /* ;AN006; */
char cmdln_switch[64]    = {0} ;                                               /* ;AN006; message, if needed     */
char disk_full           = FALSE ;                                             /* RW Flag - Disk full on target */
char ea_flag             = FALSE ;                                             /* ;AN000;EA */
char errfname[MAX]       = {0} ;
char errline[MAX]        = {0} ;
char filename[MAX]       = {0} ;                                               /* RW Save area for filename being copied */
char fix_es_reg[2]       = {0} ;                                               /* ;AN000;P Corrects es reg after type-"far" */
char not_valid_input     = TRUE ;                                              /* ;AN000;M Flag for Y/N message */
char only_one_valid_file = FALSE ;                                             /* ;AN000; Flag indicating valid filecount */
char outline[MAX]        = {0} ;
char p_path[64]          = {0} ;                                               /* ;AN000;P Recvs path from parser */
char p_sfilespec[64]     = {0} ;                                               /* ;AN000;P Recvs filespec from parser */
char source[MAXMINUS1]   = {0} ;
char target[MAXMINUS1]   = {0} ;
char target_full         = FALSE ;                                             /* ;AN000; Check flag at exit */

unsigned char dbcs_search[3] = {0} ;                                           /* ;AN000; */

unsigned add        = FALSE ;                                                  /* /A switch */
unsigned counted    = 0 ;                                                      /* Num replaced or added */
unsigned descending = FALSE ;                                                  /* /S switch */
unsigned length ;
unsigned prompt     = FALSE ;                                                  /* /P switch */
unsigned readonly   = FALSE ;                                                  /* /R switch */
unsigned segment ;
unsigned update     = FALSE ;                                                  /* ;AN000;U /U switch */
unsigned wait       = FALSE ;                                                  /* /W switch */
unsigned x_status   = 0 ;                                                      /* ;AN000;A Original append/x state */
unsigned _psp ;

long oldint24 ;                                                                /* ;AN000; Rcv cntrl from, then ret to */

extern crit_err_handler() ;                                                    /* ;AN000; Assembler routine */
extern ctl_brk_handler() ;                                                     /* ;AN000; Assembler routine */

unsigned Check_Appendx_Install ();
unsigned Check_Appendx ();

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   main                                               */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Get addressability to msgs through SYSLOADMSG   */
/*                        Parse the command line by calling SYSPARSE      */
/*                        Allocate the data buffer to be used for copy    */
/*                        Make a fully qualified source path              */
/*                        Append current directory string                 */
/*                        Create a list of files to be replaced           */
/*                        Read and write files                            */
/*                        De-allocate data buffer                         */
/*                        Print messages by calling SYSDISPMSG            */
/*                                                                        */
/*  INPUT:             Command line arguments                             */
/*                                                                        */
/*  EXIT-NORMAL:       Information message displayed.                     */
/*                                                                        */
/*  EXIT-ERROR:        Error message displayed, appendx restored,         */
/*                     errorlevel set.                                    */
/*                                                                        */
/*  EXTERNAL ROUTINES:    SYSLOADMSG                                      */
/*                        SYSDISPMSG                                      */
/*                        SYSPARSE                                        */
/*                        crit_err_handler                                */
/*                        ctl_brk_handler                                 */
/*                                                                        */
/*  INTERNAL ROUTINES:    check_appendx             dta_restore           */
/*                        check_appendx_install     dta_save              */
/*                        dallocate                 dwrite                */
/*                        dchmod                    findfile              */
/*                        dclose                    get_ext_attr          */
/*                        dcompare                  getbyte               */
/*                        dcreate                   getdword              */
/*                        ddelete                   getword               */
/*                        dexit                     load_msg              */
/*                        dfree                     parser_prep           */
/*                        display_exit              putbyte               */
/*                        display_msg               putdword              */
/*                        doadd                     putword               */
/*                        docopy                    restore               */
/*                        dodir                     same                  */
/*                        dopen                     set_appendx           */
/*                        dread                     setup_crit_err        */
/*                        dsearchf                  setup_ctl_brk         */
/*                        dsearchn                                        */
/*                                                                        */
/**************************************************************************/

void main(argc, argv)                                                          /* ;AC000; */
int  argc ;
char *argv[] ;
{
  void display_exit() ;                                                        /* ;AN000; forward declaration */
  void display_msg() ;                                                         /* ;AN000; forward declaration */
  void dta_restore() ;                                                         /* ;AN000; forward declaration */
  void dta_save() ;                                                            /* ;AN000; forward declaration */
  void load_msg() ;                                                            /* ;AN000; forward declaration */
  void parser_prep() ;                                                         /* ;AN000; forward declaration */
  void putbyte() ;                                                             /* ;AC000; forward declaration */
  void putdword() ;                                                            /* ;AC000; forward declaration */
  void putword() ;                                                             /* ;AC000; forward declaration */
  void restore() ;                                                             /* ;AN000; forward declaration */
  void set_appendx() ;                                                         /* ;AN000; forward declaration */
  void setup_crit_err() ;                                                      /* ;AN000; forward declaration */
  void setup_ctl_brk() ;                                                       /* ;AN000; forward declaration */

  char *com_strchr() ;                                                         /* ;AN000; To search for DBCS "\\" */
  char getbyte() ;                                                             /* ;AC000; forward declaration */

  int same() ;                                                                 /* ;AN000; forward declaration */

  unsigned char *com_strrchr() ;                                               /* ;AN000; To search for DBCS "\\" */

  unsigned check_appendx() ;                                                   /* ;AN000; forward declaration */
  unsigned check_appendx_install() ;                                           /* ;AN000; forward declaration */
  unsigned dallocate() ;                                                       /* ;AN000; forward declaration */
  unsigned dchmod() ;                                                          /* ;AN000; forward declaration */
  unsigned dclose() ;                                                          /* ;AN000; forward declaration */
  unsigned dcompare() ;                                                        /* ;AN000; forward declaration */
  unsigned dcreate() ;                                                         /* ;AN000; forward declaration */
  unsigned ddelete() ;                                                         /* ;AN000; forward declaration */
  unsigned dexit() ;                                                           /* ;AN000; forward declaration */
  unsigned dfree() ;                                                           /* ;AN000; forward declaration */
  unsigned doadd() ;                                                           /* ;AN000; forward declaration */
  unsigned docopy() ;                                                          /* ;AN000; forward declaration */
  unsigned dodir() ;                                                           /* ;AN000; forward declaration */
  unsigned dopen() ;                                                           /* ;AN000; forward declaration */
  unsigned dread() ;                                                           /* ;AN000; forward declaration */
  unsigned dsearchf() ;                                                        /* ;AN000; forward declaration */
  unsigned dsearchn() ;                                                        /* ;AN000; forward declaration */
  unsigned dwrite() ;                                                          /* ;AN000; forward declaration */
  unsigned findfile() ;                                                        /* ;AN000; forward declaration */
  unsigned get_ext_attr() ;                                                    /* ;AN000; forward declaration */
  unsigned getword() ;                                                         /* ;AC000; forward declaration */

  long getdword() ;                                                            /* ;AC000; forward declaration */

  struct filedata files[500] ;                                                 /* ;AC000; 256 is true limit, but */
                                                                               /* 500 to accomodate segment wrap */
  char save[MAXMINUS1] ;
  char switch_buffer[3] ;                                                      /* ;AN000; Gets switch from parser */

  char far * fptr ;                                                            /* ;AN000;P Pts to parser's buf for flspc */

  int backslash_char          = FALSE ;                                        /* ;AN000; DBCS flag */
  int fchar                   = 0 ;                                            /* ;AN000;P Index into p_sfilespec */
  int first_time_thru_loop    = TRUE ;                                         /* ;AN000; Flag - bypass code if > 256 files */
  int i ;
  int index ;                                                                  /* ;AN000;P Forming string for parser */
  int more_to_parse           = TRUE ;                                         /* ;AN000;P While parsing cmdline */
  int need_to_reset_filecount = FALSE ;                                        /* ;AN000; Flag - get to 0 element of array */
  int search_more_files       = TRUE ;                                         /* ;AN000; Flag to loop > 256 files */

  unsigned filecount          = 0 ;
  unsigned have_source        = FALSE ;                                        /* Flag */
  unsigned have_target        = FALSE ;                                        /* Flag */
  unsigned status ;                                                            /* Mostly used for carry flag */

/************************ BEGIN ***********************************************/

  load_msg() ;                                                                 /* ;AN000;M Point to msgs & chk DOS ver */
  for (index = 1; index <= argc; index++)                                      /* ;AN000;P Form string for parser */
  {                                                                            /* ;AN000;P */
    strcat(source,argv[index]) ;                                               /* ;AN000;P Add the argument */
    strcat(source," ") ;                                                       /* ;AN000;P Separate with a space */
  }                                                                            /* ;AN000;P */
  parser_prep(source) ;                                                        /* ;AN000;P Initialization for the parser */

  while (more_to_parse)                                                        /* ;AN000;P Test the parse loop flag */
  {                                                                            /* ;AN000;P */
    index = 0 ;                                                                /* ;AN006; Init array index */
    parse(&inregs,&outregs) ;                                                  /* ;AN000;P Call the parser */
    if (outregs.x.ax == P_No_Error)                                            /* ;AN000;P If no error */
      if ((outregs.x.dx == (unsigned short)&rslt1) &&                          /* ;AN000;P if result is filespec */
         !(have_source))                                                       /* ;AN000;P & we don't have the source */
      {                                                                        /* ;AN000;P */
        for (fptr = rslt1.fp_result_buff; (char)*fptr != NULL; fptr++)         /* ;AN000;P get the filespec from parser */
        {                                                                      /* ;AN000;P */
          p_sfilespec[fchar] = (char)*fptr ;                                   /* ;AN000;P get the character */
          fchar++ ;                                                            /* ;AN000;P Move the char ptr */
        }                                                                      /* ;AN000;P */
        strcpy(fix_es_reg,NULL) ;                                              /* ;AN000;P (Set es reg correct) */
        have_source = TRUE ;                                                   /* ;AN000;P Set the flag */
        fchar       = 0 ;                                                      /* ;AN000;P Reset char ptr */
      }                                                                        /* ;AN000;P */
      else                                                                     /* ;AN000;P */
        if ((outregs.x.dx == (unsigned short)&rslt1) &&                        /* ;AN000;P if result is filespec */
           (have_source))                                                      /* ;AN000;P & we do have the source */
        {                                                                      /* ;AN000;P */
          for (fptr = rslt1.fp_result_buff; (char)*fptr != NULL; fptr++)       /* ;AN000;P get the filespec from parser */
          {                                                                    /* ;AN000;P */
            p_path[fchar] = (char)*fptr ;                                      /* ;AN000;P get the character */
            fchar++ ;                                                          /* ;AN000;P Move the char ptr */
          }                                                                    /* ;AN000;P */
          strcpy(fix_es_reg,NULL) ;                                            /* ;AN000;P (Set es reg correct) */
          have_target = TRUE ;                                                 /* ;AN000;P Set the flag */
        }                                                                      /* ;AN000;P */
        else                                                                   /* ;AN000;P */
        {                                                                      /* ;AN000;P */
          for (inregs.x.si;inregs.x.si<outregs.x.si;inregs.x.si++)             /* ;AN006; Copy whatever */
          {                                                                    /* ;AN006; parser just parsed */
            cmdln_switch[index] = *(char *)inregs.x.si ;                       /* ;AN006; */
            index++ ;                                                          /* ;AN006; */
          }                                                                    /* ;AN006; */
          strcpy(switch_buffer,rslt2.P_SYNONYM_Ptr) ;                          /* ;AN000;P Else copy switch into buf */
          switch (switch_buffer[1])                                            /* ;AN000;P Verify which switch */
          {                                                                    /* ;AN000;P */
            case 'A'   :  if (!add)                                            /* ;AN000;P /A switch */
                            add = TRUE ;                                       /* ;AN000;P */
                          else                                                 /* ;AN000;P */
                            display_exit(MSG_BADSWTCH,cmdln_switch,ERRLEVEL11) ;/* ;ANOO5;P It's a dup switch */
                          break ;                                              /* ;AN000;P */
            case 'P'   :  if (!prompt)                                         /* ;AN000;P /P switch */
                            prompt = TRUE ;                                    /* ;AN000;P */
                          else                                                 /* ;AN000;P */
                            display_exit(MSG_BADSWTCH,cmdln_switch,ERRLEVEL11) ;/* ;ANOO5;P It's a dup switch */
                          break ;                                              /* ;AN000;P */
            case 'R'   :  if (!readonly)                                       /* ;AN000;P /R switch */
                            readonly = TRUE ;                                  /* ;AN000;P */
                          else                                                 /* ;AN000;P */
                            display_exit(MSG_BADSWTCH,cmdln_switch,ERRLEVEL11) ;/* ;ANOO5;P It's a dup switch */
                          break ;                                              /* ;AN000;P */
            case 'S'   :  if (!descending)                                     /* ;AN000;P /S switch */
                            descending = TRUE ;                                /* ;AN000;P */
                          else                                                 /* ;AN000;P */
                            display_exit(MSG_BADSWTCH,cmdln_switch,ERRLEVEL11) ;/* ;ANOO5;P It's a dup switch */
                          break ;                                              /* ;AN000;P */
            case 'U'   :  if (!update)                                         /* ;AN000;P /U switch */
                            update = TRUE ;                                    /* ;AN000;P */
                          else                                                 /* ;AN000;P */
                            display_exit(MSG_BADSWTCH,cmdln_switch,ERRLEVEL11) ;/* ;ANOO5;P It's a dup switch */
                          break ;                                              /* ;AN000;P */
            case 'W'   :  if (!wait)                                           /* ;AN000;P /W switch */
                            wait = TRUE ;                                      /* ;AN000;P */
                          else                                                 /* ;AN000;P */
                            display_exit(MSG_BADSWTCH,cmdln_switch,ERRLEVEL11) ;/* ;ANOO5;P It's a dup switch */
                          break ;                                              /* ;AN000;P */
            default    :  display_exit(MSG_BADSWTCH,cmdln_switch,ERRLEVEL11) ; /* ;AN006; */
                          break ;                                              /* ;AN000;P */
          }                                                                    /* ;AN000;P */
        }                                                                      /* ;AN000;P */
    else                                                                       /* ;AN000;P */
      if (outregs.x.ax != P_RC_EOL)                                            /* ;AN000;P Is the parser */
      {                                                                        /* ;AN006; */
        for (inregs.x.si ; inregs.x.si < outregs.x.si ; inregs.x.si++)         /* ;AN006; Copy whatever */
        {                                                                      /* ;AN006; parser just parsed */
          cmdln_invalid[index] = *(char *)inregs.x.si ;                        /* ;AN006; */
          index++ ;                                                            /* ;AN006; */
        }                                                                      /* ;AN006; */
        switch (outregs.x.ax)                                                  /* ;AN000;P returning an error? */
        {                                                                      /* ;AN000;P */
          case P_Too_Many   :  display_exit(MSG_XTRAPARM,cmdln_invalid,ERRLEVEL11) ;/* ;AN005;P Too many parms */
                               break ;                                         /* ;AN000;P More_to_parse = FALSE */
          case P_Syntax     :  display_exit(MSG_BADPARM,cmdln_invalid,ERRLEVEL11) ;/* ;AN000;P Bad syntax */
                               break ;                                         /* ;AN000;P More_to_parse = FALSE */
          case P_Not_In_SW  :  display_exit(MSG_BADSWTCH,cmdln_invalid,ERRLEVEL11) ;/* ;AN005;P Invalid switch */
                               break ;                                         /* ;AN000;P More_to_parse = FALSE */
          case P_Op_Missing :  display_msg(MSG_NOSOURCE) ;                     /* ;AN000;P Source required */
                               dexit(ERRLEVEL11) ;                             /* ;AN000;P */
                               break ;                                         /* ;AN000;P More_to_parse = FALSE */
        }                                                                      /* ;AN000;P */
      }
      else                                                                     /* ;AN000;P */
        more_to_parse = FALSE ;                                                /* ;AN000;P End of the cmdline */
    inregs.x.cx = outregs.x.cx ;                                               /* ;AN000;P Move the count */
    inregs.x.si = outregs.x.si ;                                               /* ;AN000;P Move the pointer */
  }                                                                            /* ;AN000;P */

  /* Verify the correctness of the parameters */

  if ((add && descending) || (add && update))                                  /* ;AC000;P A+S or A+U */
  {
    display_msg(MSG_INCOMPAT) ;                                                /* ;AN000;P Incompatible switches */
    dexit(ERRLEVEL11) ;                                                        /* ;AC000; */
  }

  /* Allocate the data buffer to be used during the copy operations */

  length = 0x1000 ;
  status = dallocate(length) ;                                                 /* Allocate buffer */
  if (status == INSUFFMEM)                                                     /* Not enough mem? */
  {                                                                            /* then alloc what's available */
    length = outregs.x.bx ;                                                    /* ;AC000; */
    status = dallocate(length) ;
  }

  if (status != 0)                                                             /* If can't alloc at all */
  {                                                                            /* something's wrong */
    display_msg(MSG_NOMEM) ;                                                   /* ;AC000; no space for copies */
    dexit(ERRLEVEL8) ;                                                         /* ;AC000; */
  }

  segment = outregs.x.ax ;                                                     /* ;AC000; */
  length  = (length << 4) ;                                                    /* Convert to bytes */
  if (length == 0) length = 0xffff ;

  /* If the wait switch was on the command line, wait to continue */

  if (wait)
  {
    display_msg(MSG_START) ;                                                   /* ;AC000; Press any key... */
    inregs.x.ax = 0x0C08 ;                                                     /* ;AC000; */
    intdos(&inregs,&outregs) ;                                                 /* ;AC000; */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000; */
    if ( (status == NOERROR) && ((outregs.x.ax & 0x00ff) == 0) )               /* ;AC000; */
    {
      inregs.x.ax = 0x0100 ;                                                   /* ;AC000; */
      intdos(&inregs,&outregs) ;                                               /* ;AC000; */
      status = (outregs.x.cflag & CARRY) ;                                     /* ;AC000; */
    }
  }

  /* Make a fully qualified source path */

  strcpy(source,p_sfilespec) ;                                                 /* ;AN000;P Copy filespec recvd from parser */
  strcpy(save,source) ;
  strcpy(errfname,source) ;
  if (source[1] != ':')                                                        /* If no drive letter entered */
  {
    inregs.x.ax = 0x1900 ;                                                     /* :AC000; Get current drive */
    intdos(&inregs,&outregs) ;                                                 /* ;AC000; Int 21h */
    if (status == NOERROR)                                                     /* If no error */
    {                                                                          /* Insert current drive letter */
      source[0] = 'A' + (outregs.x.ax & 0xff) ;                                /* ;AC000; */
      source[1] = ':' ;
      source[2] = NULL ;
      strcat(source,save) ;
    }
  }

  /* Append current directory string */

  strcpy(errfname,source) ;
  if (source[2] != '\\')                                                       /* If not path from root */
  {
    strcpy(save,&source[2]) ;
    strcpy(&source[3],save) ;
    source[2]   = '\\' ;
    inregs.x.ax = 0x4700 ;                                                     /* ;AC000; Get current directory */
    inregs.x.si = (unsigned)(&source[3]) ;                                     /* ;AC000; */
    inregs.x.dx = source[0] - 'A' + 1 ;                                        /* ;AC000; */
    intdos(&inregs,&outregs) ;                                                 /* ;AC000; */
    if (outregs.x.cflag & CARRY)                                               /* ;AC000; If the carry flag is set */
      status = outregs.x.ax ;                                                  /* ;AC000;   get returned error */
    else                                                                       /* ;AC000; else */
      status = (outregs.x.cflag & CARRY) ;                                     /* ;AC000;   set status to NOERROR */
    if (status == NOERROR)                                                     /* If we got it, add it to user entered path */
    {
      if ((com_strrchr(source,'\\')) == NULL)                                  /* ;AC000; DBCS function */
        strcat(source,"\\") ;
      else
        if ((char *)(com_strrchr(source,'\\')) != &source[strlen(source)-1])   /* ;AN000; DBCS function */
          strcat(source,"\\") ;                                                /* ;AN000; */
      strcat(source,save) ;
    }
  }

  status = check_appendx_install() ;                                           /* ;AN000;A Check append/x install */
  if (status != NOERROR)                                                       /* ;AN000;A If append/x is installed */
  {                                                                            /* ;AN000;A */
    append_installed = TRUE ;                                                  /* ;AN000;A */
    x_status = check_appendx() ;                                               /* ;AN000;A Get the status */
    set_appendx(x_status & INACTIVE) ;                                         /* ;AN000;A Set it inactive */
  }                                                                            /* ;AN000;A */
  else                                                                         /* ;AN000;A */
    status = NOERROR ;                                                         /* ;AN000;A */

  setup_ctl_brk() ;                                                            /* ;AN000; Ctl brk vec now pts to us */
  setup_crit_err() ;                                                           /* ;AN000; Crit err vec now pts to us */

  /* Create a list of the files that we might just replace */

  strcpy(errfname,source) ;
  status = dsearchf(source,&files[filecount],SATTRIB) ;                        /* Find the first file */

  while (search_more_files)                                                    /* ;AN000; Search & replace/add */
  {
    while ( (filecount < MAXMINUS1) && (status == NOERROR) )
    {
      filecount++ ;
      if (need_to_reset_filecount)                                             /* ;AN000; Because of prev structure, */
      {                                                                        /* ;AN000; only way to get to 0 element */
        filecount = 0 ;                                                        /* ;AN000; */
        need_to_reset_filecount = FALSE ;                                      /* ;AN000; */
      }                                                                        /* ;AN000; */
      status = dsearchn(&files[filecount]) ;
    }

    if (status == NOMOREFILES)
    {
      status = NOERROR ;
      search_more_files = FALSE ;                                              /* ;AN000; Set for loop test */
      if (filecount == 1)                                                      /* ;AN000; Find the true filecount */
        only_one_valid_file = TRUE ;                                           /* ;AN000; */
      if (filecount > 1)                                                       /* ;AN000; Last file is no good */
        filecount-- ;                                                          /* ;AN000; so back counter up */
    }

    if ((first_time_thru_loop) && (status == NOERROR) )                        /* ;AN000; Bypassed if done already */
    {
      first_time_thru_loop = FALSE ;                                           /* ;AN000; > 256 files to replace */
      if (filecount == 0)
        display_exit(MSG_NONFOUND,source,ERRLEVEL2) ;                          /* ;AC000; */

      if (status == NOERROR)
      {
        /* fixup the source directory path so that it is useable */

        for (i = strlen(source)-1; (i >= 0) && (!backslash_char) && (source[i] != ':'); i--) /* ;AC000; */
          if ((source[i] == '\\') && (i != 0))                                 /* ;AN000; */
          {                                                                    /* ;AN000; */
            dbcs_search[0] = source[i-1] ;                                     /* ;AN000; Copy char to srch for DBCS */
            dbcs_search[1] = source[i] ;                                       /* ;AN000; Copy char to srch for DBCS */
            if (com_strchr(dbcs_search,'\\') != NULL)                          /* ;AN000; If there is a pointer */
            {                                                                  /* ;AN000; then backslash exists */
              backslash_char = TRUE ;                                          /* ;AN000; */
              i++ ;                                                            /* ;AN000; Bump up index */
            }                                                                  /* ;AN000; */
          }                                                                    /* ;AN000; */
          else                                                                 /* ;AN000; */
            if ((source[i] == '\\') && (i == 0))                               /* ;AN000; */
            {                                                                  /* ;AN000; */
              backslash_char = TRUE ;                                          /* ;AN000; */
              i++ ;                                                            /* ;AN000; */
            }                                                                  /* ;AN000; */
        if (i <= 0)
        {
          i = 0;
          source[0] = NULL ;
        }
        dbcs_search[0] = source[i-1] ;                                         /* ;AN000; Copy char to srch for DBCS */
        dbcs_search[1] = source[i] ;                                           /* ;AN000; Copy char to srch for DBCS */
        if ( ((com_strchr(dbcs_search,'\\'))!= NULL) || (source[i] == ':') )   /* ;AN000; */
          source[i+1] = NULL ;                                                 /* ;AN000; */

        /* fixup the target path */

        strcpy(target,p_path) ;                                                /* ;AN000;P Copy path recvd from parser */
        if (target[0] == NULL)
        {
          inregs.x.ax = 0x1900 ;                                               /* ;AC000; Get current drive */
          intdos(&inregs,&outregs) ;                                           /* ;AC000; */
          if (status == NOERROR)
          {
            target[0] = 'A' + (outregs.x.ax & 0xff) ;                          /* ;AC000; */
            target[1] = ':' ;
            target[2] = NULL ;
          }
        }

        strcpy(errfname,target) ;
        if ( (strlen(target) == 2) && (target[1] == ':') && (status == NOERROR) )
        {
          target[2]   = '\\' ;
          inregs.x.ax = 0x4700 ;                                               /* ;AC000; Get current dir */
          inregs.x.si = (unsigned)(&target[3]) ;                               /* ;AC000; */
          inregs.x.dx = target[0] - 'A' + 1 ;                                  /* ;AC000; */
          intdos(&inregs,&outregs) ;                                           /* ;AC000; */
          if (outregs.x.cflag & CARRY)                                         /* ;AC000; If the carry flag is set */
            status = outregs.x.ax ;                                            /* ;AC000;   get returned error */
          else                                                                 /* ;AC000; else                 */
            status = (outregs.x.cflag & CARRY) ;                               /* ;AC000;   set status to NOERROR */
        }

        strcpy(save,target) ;
        strcpy(errfname,target) ;
        if (target[1] != ':')
        {
          inregs.x.ax = 0x1900 ;                                               /* ;AC000; Get current drive */
          intdos(&inregs,&outregs) ;                                           /* ;AC000; */
          if (status == NOERROR)
          {
            target[0] = 'A' + (outregs.x.ax & 0xff) ;                          /* ;AC000; */
            target[1] = ':' ;
            target[2] = NULL ;
            strcat(target,save) ;
          }
        }

        strcpy(errfname,target) ;
        if (target[2] != '\\')                                                 /* ;AC000; */
        {
          strcpy(save,&target[2]) ;
          strcpy(&target[3],save) ;                                            /* ;AN004; */
          target[2]   = '\\' ;
          inregs.x.ax = 0x4700 ;                                               /* ;AC000; Get current directory */
          inregs.x.si = (unsigned)(&target[3]) ;                               /* ;AC000; */
          inregs.x.dx = target[0] - 'A' + 1 ;                                  /* ;AC000; */
          intdos(&inregs,&outregs) ;                                           /* ;AC000; */
          if (outregs.x.cflag & CARRY)                                         /* ;AC000; If the carry flag is set */
            status = outregs.x.ax ;                                            /* ;AC000;   get returned error */
          else                                                                 /* ;AC000; else */
            status = (outregs.x.cflag & CARRY) ;                               /* ;AC000;   set status to NOERROR */
          if (status == NOERROR)
          {                                                                    /* ;AC000; */
            if ((com_strrchr(target,'\\')) == NULL)                            /* ;AC004; DBCS func, if no backslash */
              strcat(target,"\\") ;                                            /* ;AC000; then add backslash */
            else                                                               /* ;AC000; */
              if ((char *)(com_strrchr(target,'\\')) != &target[strlen(target)-1]) /* ;AN000; If bkslsh not last char */
                strcat(target,"\\") ;                                          /* ;AN000; then add backslash */
            if (save[0] != '.')                                                /* ;AN004; If tgt is not cur dir */
              strcat(target,save) ;                                            /* ;AN004; then append subdir to path */
            else                                                               /* ;AN004; */
              if (save[1] == '.')                                              /* ;AN004; If tgt is parent dir */
              {                                                                /* ;AN004; */
                target[strlen(target)-1] = NULL ;                              /* ;AN004; then delete end backslash */
                *((unsigned char *)com_strrchr(target,'\\')+1) = NULL ;        /* ;AN004; del curdir name from path */
              }                                                                /* ;AN004; */
          }                                                                    /* ;AN004; */
        }

        strcpy(errfname,target) ;
        dbcs_search[0] = target[strlen(target)-2] ;                            /* ;AN000; Copy char to srch for DBCS */
        dbcs_search[1] = target[strlen(target)-1] ;                            /* ;AN000; Copy char to srch for DBCS */
        if ( ((com_strchr(dbcs_search,'\\')) != &dbcs_search[1]) &&            /* ;AN004; DBCS function */
           (status == NOERROR) )                                               /* ;AC000; */
          strcat(target,"\\") ;
      }
    }

    if ( (status == NOERROR) && (!add) )
      status = dodir(source,target,files,filecount) ;

    if ( (status == NOERROR) && (add) )
      status = doadd(source,target,files,filecount) ;

    filecount = 0 ;                                                            /* ;AN000; Reset for next loop */
    need_to_reset_filecount = TRUE ;                                           /* ;AN000; Get to 0 element */

    if (status != NOERROR)                                                     /* ;AN000; If there was an error */
      search_more_files = FALSE ;                                              /* ;AN000;   somewhere, drop out */
  }

  dfree(segment) ;

  switch(status)
  {
    case 0  : break ;
    case 2  : display_msg(MSG_ERRFNF,errfname) ;                               /* ;AC000; file not found */
              break ;
    case 3  : display_msg(MSG_ERRPNF,errfname) ;                               /* ;AC000; path not found */
              break ;
    case 5  : display_msg(MSG_ERRACCD,errfname) ;                              /* ;AC000; access denied */
              break ;
    case 15 : display_msg(MSG_ERRDRV,errfname) ;                               /* ;AC000; invalid drive */
              break ;
    default : dexit(ERRLEVEL1) ;                                               /* ;AC000; */
              break ;
  }

  if (add)
    if (counted == 0)
      display_msg(MSG_NONEADDE) ;                                              /* ;AC000; no files added */
    else
      display_msg(MSG_SOMEADDE,(char *)&counted) ;                             /* ;AC000; %1 files added */
  else
    if (counted == 0)
      display_msg(MSG_NONEREPL) ;                                              /* ;AC000; no files replaced */
    else
      display_msg(MSG_SOMEREPL,(char *)&counted) ;                             /* ;AC000; %1 files replaced */

  restore() ;                                                                  /* ;AN000; Cleanup before exit */
  dexit(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dodir(source,target,files,filecount)                                  /* ;AC000; */
char     *source ;
char     *target ;
struct   filedata *files ;
unsigned filecount ;
{
  char     dta_area[128] ;
  char     subdirectory[MAX] ;
  int      index ;
  unsigned status ;
  struct   filedata file ;

  dta_save(dta_area,128) ;
  strcpy(subdirectory,target) ;
  strcat(subdirectory,"*.*") ;
  status = dsearchf(subdirectory,&file,TATTRIB) ;
  while (status == NOERROR)
  {
    if ( ((file.attribute & SUBDIR) != 0) &&
       (descending) && (file.name[0] != '.') )
    {
      strcpy(subdirectory,target) ;
      strcat(subdirectory,file.name) ;
      strcat(subdirectory,"\\") ;
      status = dodir(source,subdirectory,files,filecount) ;                    /* Call self again */
      strcpy(subdirectory,target) ;
      strcat(subdirectory,"*.*") ;
    }
    else
    {
      index = findfile(files,&file,filecount) ;                                /* if there is a file and it  */
      if ( (index >= 0) && ((file.attribute & SUBDIR) == 0) )                  /* is not a subdirectory name */
        if (update)                                                            /* ;AN000;U If updt sw set,ck dt & tm */
          if ((files[index].date < file.date)  ||                              /* ;AN000;U If src.date < tgt.date or */
             ((files[index].date == file.date) &&                              /* ;AN000;U Src.dt == tgt.dt and */
             (files[index].time <= file.time))) ;                              /* ;AN000;U src.tm <= tgt.tm - do nthng */
          else                                                                 /* ;AN000;U Else src is newer - do cpy */
            status = docopy(source,target,&file,files[index].time,files[index].date) ; /* ;AN000;U */
        else                                                                   /* ;AN000;U Update switch was not set */
          status = docopy(source,target,&file,files[index].time,files[index].date) ;
    }
    if (status == NOERROR)
      status = dsearchn(&file) ;
  }

  dta_restore(dta_area,128) ;
  if (status == NOMOREFILES)
    status = NOERROR ;
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned doadd(source,target,files,filecount)                                  /* ;AC000; */
char     *source ;
char     *target ;
struct   filedata *files ;
unsigned filecount ;
{
  char     path[MAX] ;
  int      index ;
  unsigned status = NOERROR ;
  struct   filedata *f ;
  struct   filedata dummy ;

  if (only_one_valid_file)                                                     /* ;AN003; Eliminate extra loop */
    filecount-- ;                                                              /* ;AN003; */

  for (index = 0; (index <= filecount) && (status == NOERROR) ; index++)       /* ;AC000; */
  {
    f = files+index ;
    strcpy(path,target) ;
    strcat(path,f->name) ;
    status = dsearchf(path,&dummy,TATTRIB) ;
    if (((status == NOMOREFILES) && (f->name[0] != NULL)) ||                   /* ;AC000; Check for null filename */
       ((index==filecount)&&(f->name[0]!=NULL)&&(status==NOMOREFILES)))        /* ;AN004;006; Process single file */
      status = docopy(source,target,f,f->time,f->date) ;
    else                                                                       /* ;AN000; */
      status = NOERROR ;                                                       /* ;AN000; Skip this null file */
  }
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned findfile(files,file,filecount)                                        /* ;AC000; */
struct   filedata *files ;
struct   filedata *file ;
unsigned filecount ;
{
  int i ;

  if (only_one_valid_file)                                                     /* ;AN003; Eliminate extra loop */
    filecount-- ;                                                              /* ;AN003 */

  for (i = 0; i <= filecount; i++)                                             /* ;AC000; */
  {
    if (same(files->name,file->name))                                          /* ;AC000; */
      return(i) ;
    files++ ;
  }
  return(ERRLEVELNEG1) ;                                                       /* ;AC000; */
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned docopy(sdir,tdir,file,time,date)                                      /* ;AC000; */
char     *sdir ;
char     *tdir ;
struct   filedata *file ;
unsigned time ;
unsigned date ;
{
  char     *s,*t ;
  char     source[MAX] ;
  char     target[MAX] ;
  unsigned source_handle ;
  unsigned status ;
  unsigned target_handle ;
  unsigned try ;

  /* create the path names and check for equivalence */

  strcpy(source,sdir) ;
  strcat(source,file->name) ;
  strcpy(target,tdir) ;
  strcat(target,file->name) ;

  status = strcmp(source,target) ;
  if (status == NOERROR)
  {
    display_msg(MSG_WARNSAME,source) ;                                         /* ;AC000; File cannot be copied... */
    return(status) ;
  }

  /* We can replace!  if prompting, check to see */
  /* if this file is to be replaced or not       */

  while ( (prompt) && (not_valid_input) )                                      /* ;AN000;M Flag set in dcompare */
  {
    if (add)
      display_msg(MSG_QADD,target) ;                                           /* ;AC000; Add? filename */
    else
      display_msg(MSG_QREPLACE,target) ;                                       /* ;AC000; Replace? filename */
    status = dcompare() ;                                                      /* ;AN000; */
  }
  not_valid_input = TRUE ;                                                     /* ;AN000; Prepare for next file in loop */
  if (status == 2)
    return(ERRLEVEL0) ;                                                        /* ;AC000; */

  /* indicate what we are replacing */

  if (add)
    display_msg(MSG_ADDING,target) ;                                           /* ;AC000; Adding filename */
  else
    display_msg(MSG_REPLACIN,target) ;                                         /* ;AC000; Replacing filename */

  /* open the input file */

  status = dopen(source) ;                                                     /* ;AC000; Extended open */
  if (status != 0)
  {
    strcpy(errfname,source) ;
    return(status) ;
  }

  source_handle = outregs.x.ax ;                                               /* ;AN000; */

  get_ext_attr(source_handle,0) ;                                              /* ;AC000;EA Get the source's extd attributes */
  if (outregs.x.cx)                                                            /* ;AN000;EA If size is retd, attrs exist */
  {                                                                            /* ;AN000;EA */
    ea_flag                     = TRUE ;                                       /* ;AN000;EA */
    eaparm_list.ea_list_offset  = 0 ;                                          /* ;AN000;EA Use the read/write buffer */
    eaparm_list.ea_list_segment = segment ;                                    /* ;AN000;EA Use the read/write buffer */
    get_ext_attr(source_handle,outregs.x.cx) ;                                 /* ;AN000;EA Now get the extd attributes */
  }                                                                            /* ;AN000;EA */

  /* create the output file */
  /* if we are to overwrite READONLY files, set the mode so we can */

  if (!add)
  {
    inregs.x.cx = 0 ;                                                          /* ;AC000; */
    status = dchmod(target,0) ;
    if (status != 0)
    {
      strcpy(errfname,target) ;
      dclose(source_handle) ;
      return(status) ;
    }
    file->attribute = outregs.x.cx ;                                           /* ;AC000; */
    if (readonly)
      outregs.x.cx = outregs.x.cx & 0xfffe ;                                   /* ;AC000; */
    if (file->attribute != outregs.x.cx)                                       /* ;AC000; */
    {
      status = dchmod(target,1) ;
      if (status != 0)
      {
        strcpy(errfname,target) ;
        dclose(source_handle) ;
        return(status) ;
      }
    }
  }

  if (ea_flag)                                                                 /* ;AN000;EA If extd attrs exist */
    status = dcreate(target,&eaparm_list) ;                                    /* ;AN000;EA   open trgt w/extd attrs */
  else                                                                         /* ;AN000;EA */
    status = dcreate(target,-1) ;                                              /* ;AC000;EA Create the target file */

  strcpy(filename,target) ;                                                    /* Note that existing file*/
  if (status != 0)                                                             /*  will be deleted       */
  {
    strcpy(errfname,target) ;
    dclose(source_handle) ;
    return(status) ;
  }

  target_handle = outregs.x.ax ;                                               /* ;AC000; */

  /* now, copy all of the data from the in file to the out file */

  try = length ;
  while ( (try == length) && (status == NOERROR) )
  {
    status = dread(source_handle,segment,0,try) ;
    if (status == NOERROR)
    {
      try    = outregs.x.ax ;                                                  /* ;AC000; */
      status = dwrite(target_handle,segment,0,try) ;
      if (disk_full)                                                           /* RW If the target disk fills up */
      {
        strcpy(errline,filename) ;                                             /* ;AC000; save target filename */
        dclose(target_handle) ;                                                /* RW Close target file */
        ddelete(filename) ;                                                    /* RW Then delete target file */
        display_msg(MSG_ERRDSKF,errline) ;                                     /* ;AC000; Error disk full */
        status = TARGETFULL ;                                                  /* RW Tell me too */
      }
    }
  }

  if (status == NOERROR)
  {
    inregs.x.ax = 0x5701 ;                                                     /* ;AC000; Set files date and time */
    inregs.x.bx = target_handle ;                                              /* ;AC000; */
    inregs.x.cx = time ;                                                       /* ;AC000; */
    inregs.x.dx = date ;                                                       /* ;AC000; */
    intdos(&inregs,&outregs) ;                                                 /* ;AC000; */
    if (outregs.x.cflag & CARRY)                                               /* ;AC000; If the carry flag is set */
      status = outregs.x.ax ;                                                  /* ;AC000;   get returned error */
    else                                                                       /* ;AC000; else                 */
      status = (outregs.x.cflag & CARRY) ;                                     /* ;AC000;   set status to NOERROR */
  }

  if (status == NOERROR)
  {
    status = dclose(target_handle) ;                                           /* Close target file */
    if (status != NOERROR)
      strcpy(errfname,target) ;
    else
    {
      if ((file->attribute & ARCHIVE) != ARCHIVE)
        file->attribute += ARCHIVE ;                                           /* ;AN001; Set archive bit ON */
      inregs.x.cx = file->attribute ;                                          /* ;AC000; */
      if (!add)
        status = dchmod(target,1) ;                                            /* Reset attributes on target */
      if (status != NOERROR)
        strcpy(errfname,target) ;
      counted++ ;                                                              /* Increment num files processed */
    }
  }

  if (disk_full)                                                               /* RW If the target disk got full */
  {
    status      = NOERROR ;                                                    /* RW Then we've done all we can do */
    disk_full   = FALSE ;                                                      /* RW So forget about it */
    target_full = TRUE ;                                                       /* ;AN000; */
  }

  dclose(source_handle) ;
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

int same(s,t)                                                                  /* ;AC000; */
char *s ;
char *t ;
{
  while ( (*s != NULL) && (*t != NULL) )                                       /* ;AC000; */
  {                                                                            /* ;AC000; */
    if ( *s != *t )                                                            /* ;AC000; */
      return(FALSE) ;                                                          /* ;AN000;Removed "casemap" */
    s++ ;                                                                      /* ;AC000; */
    t++ ;                                                                      /* ;AC000; */
  }                                                                            /* ;AC000; */
  if ( *s != *t )
    return(FALSE) ;                                                            /* ;AN000;Removed "casemap" */
  return(TRUE) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dallocate(s)                                                          /* ;AC000; */
unsigned s ;
{
  unsigned status ;

  inregs.x.bx = s ;                                                            /* ;AC000; Num of paragraphs requested */
  inregs.x.ax = 0x4800 ;                                                       /* ;AC000; Int21 - allocate memory */
  intdos(&inregs,&outregs) ;                                                   /* ;AC000; */
  if (outregs.x.cflag & CARRY)                                                 /* ;AC000; If the carry flag is set */
    status = outregs.x.ax ;                                                    /* ;AC000;   get returned error */
  else                                                                         /* ;AC000; else */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000;   set status to NOERROR */
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dfree(s)                                                              /* ;AC000; */
unsigned s ;
{
  unsigned status ;

  segregs.es  = s ;                                                            /* ;AC000; */
  inregs.x.ax = 0x4900 ;                                                       /* ;AC000; */
  intdosx(&inregs,&outregs,&segregs) ;                                         /* ;AC000; */
  if (outregs.x.cflag & CARRY)                                                 /* ;AC000; If the carry flag is set */
    status = outregs.x.ax ;                                                    /* ;AC000;   get returned error */
  else                                                                         /* ;AC000; else                 */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000;   set status to NOERROR */
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dcreate(n,parm_value)                                                 /* ;AC000; */
char     *n ;
unsigned parm_value ;
{
  unsigned status ;

  inregs.x.ax = 0x6c00 ;                                                       /* ;AC000;EA Extended Create */
  inregs.x.bx = 8321 ;                                                         /* ;AN000;EA Mode */
  inregs.x.cx = 0 ;                                                            /* ;AN000;EA Create attribute */
  inregs.x.dx = 0x12 ;                                                         /* ;AC002;EA Function flag */
  inregs.x.di = parm_value ;                                                   /* ;AN000;EA Parm list value */
  inregs.x.si = (unsigned)(n) ;                                                /* ;AN000;EA Target file to create */
  intdos(&inregs,&outregs) ;                                                   /* ;AC000;EA Int 21 */
  if (outregs.x.cflag & CARRY)                                                 /* ;AC000;EA If the carry flag is set */
    status = outregs.x.ax ;                                                    /* ;AC000;EA   get returned error */
  else                                                                         /* ;AC000;EA else                 */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000;EA   set status to NOERROR */
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dopen(n)                                                              /* ;AC000; */
char *n ;
{
  unsigned status ;

  inregs.x.ax = 0x6c00 ;                                                       /* ;AC000;EA Extended open */
  inregs.x.bx = 8320 ;                                                         /* ;AN000;EA Open mode (flags) */
  inregs.x.cx = 0 ;                                                            /* ;AN000;EA Create attr (ignore) */
  inregs.x.dx = 257 ;                                                          /* ;AN000;EA Function control (flags) */
  inregs.x.si = (unsigned)(n) ;                                                /* ;AC000;EA File name to open */
  inregs.x.di = -1 ;                                                           /* ;AN000;EA Parm list (null) */
  intdos(&inregs,&outregs) ;                                                   /* ;AC000;EA Int 21 */
  if (outregs.x.cflag & CARRY)                                                 /* ;AC000;EA If the carry flag is set */
    status = outregs.x.ax ;                                                    /* ;AC000;EA   get returned error */
  else                                                                         /* ;AC000;EA else                 */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000;EA   set status to NOERROR */
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned ddelete(n)                                                            /* ;AC000; */
char *n ;                                                                      /* File to be deleted */
{
  unsigned status ;

  inregs.x.ax = 0x4100 ;                                                       /* ;AC000; */
  inregs.x.dx = (unsigned)(n) ;                                                /* ;AC000; */
  intdos(&inregs,&outregs) ;                                                   /* ;AC000; */
  if (outregs.x.cflag & CARRY)                                                 /* ;AC000; If the carry flag is set */
    status = outregs.x.ax ;                                                    /* ;AC000;   get returned error */
  else                                                                         /* ;AC000; else                 */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000;   set status to NOERROR */
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dread(h,s,o,l)                                                        /* ;AC000; */
unsigned h ;
unsigned s ;
unsigned o ;
unsigned l ;
{
  unsigned status ;

  inregs.x.ax = 0x3f00 ;                                                       /* ;AC000; Read from file or device */
  inregs.x.bx = h ;                                                            /* ;AC000; File handle */
  segregs.ds  = s ;                                                            /* ;AC000; Buffer segment */
  inregs.x.dx = o ;                                                            /* ;AC000; Buffer offset */
  inregs.x.cx = l ;                                                            /* ;AC000; Num of bytes to be read */
  intdosx(&inregs,&outregs,&segregs) ;                                         /* ;AC000; */
  if (outregs.x.cflag & CARRY)                                                 /* ;AC000; If the carry flag is set */
    status = outregs.x.ax ;                                                    /* ;AC000;   get returned error */
  else                                                                         /* ;AC000; else                 */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000;   set status to NOERROR */
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dwrite(handle,segment,offset,length)                                  /* ;AC000; */
unsigned handle ;
unsigned segment ;
unsigned offset ;
unsigned length ;
{
  unsigned status ;
  unsigned write_len ;                                                         /* Save area for num of bytes to write */

  inregs.x.ax = 0x4000 ;                                                       /* ;AC000; Write to file or device */
  inregs.x.bx = handle ;                                                       /* ;AC000; */
  segregs.ds  = segment ;                                                      /* ;AC000; */
  inregs.x.dx = offset ;                                                       /* ;AC000; */
  inregs.x.cx = length ;                                                       /* ;AC000; */
  write_len = length ;                                                         /* ;AC000; */
  intdosx(&inregs,&outregs,&segregs) ;                                         /* ;AC000; */
  if (outregs.x.cflag & CARRY)                                                 /* ;AC000; If the carry flag is set */
    status = outregs.x.ax ;                                                    /* ;AC000;   get returned error */
  else                                                                         /* ;AC000; else                 */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000;   set status to NOERROR */
  if (status == NOERROR)                                                       /* If there was not an error */
    if (write_len != outregs.x.ax)                                             /* And we didn't write reqtd num bytes */
      disk_full = TRUE ;                                                       /* Then the disk is full. Ret error */
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dclose(h)                                                             /* ;AC000; */
unsigned h ;
{
  unsigned status ;

  inregs.x.ax = 0x3e00 ;                                                       /* ;AC000; Close a file handle */
  inregs.x.bx = h ;                                                            /* ;AC000; File han ret by open/create */
  intdos(&inregs,&outregs) ;                                                   /* ;AC000; */
  if (outregs.x.cflag & CARRY)                                                 /* ;AC000; If the carry flag is set */
    status = outregs.x.ax ;                                                    /* ;AC000;   get returned error */
  else                                                                         /* ;AC000; else                 */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000;   set status to NOERROR */
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dchmod(n,a)                                                           /* ;AC000; */
char     *n ;
unsigned a ;
{
  unsigned status ;

  inregs.x.ax = 0x4300 | (a & 0x00ff) ;                                        /* ;AC000; Change file mode */
  inregs.x.dx = (unsigned)(n) ;                                                /* ;AC000; Ptr to asciiz path name */
  intdos(&inregs,&outregs) ;                                                   /* ;AC000; */
  if (outregs.x.cflag & CARRY)                                                 /* ;AC000; If the carry flag is set */
    status = outregs.x.ax ;                                                    /* ;AC000;   get returned error */
  else                                                                         /* ;AC000; else                 */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000;   set status to NOERROR */
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dsearchf(s,t,a)                                                       /* ;AC000; */
char     *s ;
struct   filedata *t ;
unsigned a ;
{
  unsigned i ;
  unsigned status ;

  inregs.x.ax = 0x4e00 ;                                                       /* ;AC000; Find first matching file */
  inregs.x.cx = a ;                                                            /* ;AC000; Attrib used in search */
  inregs.x.dx = (unsigned)(s) ;                                                /* ;AC000; Asciiz string ptr */
  intdos(&inregs,&outregs) ;                                                   /* ;AC000; */
  if (outregs.x.cflag & CARRY)                                                 /* ;AC000; If the carry flag is set */
    status = outregs.x.ax ;                                                    /* ;AC000;   get returned error */
  else                                                                         /* ;AC000; else */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000;   set status to NOERROR */
  if (status == NOERROR)
  {
    t->attribute = getbyte(_psp,0x80+21) ;
    t->time      = getword(_psp,0x80+22) ;
    t->date      = getword(_psp,0x80+24) ;
    t->size      = getdword(_psp,0x80+26) ;
    for (i = 0; i < 15; i++)
      t->name[i] = getbyte(_psp,0x80+30+i) ;
    strcpy(fix_es_reg,NULL) ;                                                  /* ;AN000; */
  }
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dsearchn(t)                                                           /* ;AC000; */
struct filedata *t ;
{
  unsigned i ;
  unsigned status ;

  inregs.x.ax = 0x4f00 ;                                                       /* ;AC000; Find next matching file */
  intdos(&inregs,&outregs) ;                                                   /* ;AC000; DTA contains prev call info */
  if (outregs.x.cflag & CARRY)                                                 /* ;AC000; If the carry flag is set */
    status = outregs.x.ax ;                                                    /* ;AC000;   get returned error */
  else                                                                         /* ;AC000; else */
    status = (outregs.x.cflag & CARRY) ;                                       /* ;AC000;   set status to NOERROR */
  if (status == NOERROR)
  {
    t->attribute = getbyte(_psp,0x80+21) ;
    t->time      = getword(_psp,0x80+22) ;
    t->date      = getword(_psp,0x80+24) ;
    t->size      = getdword(_psp,0x80+26) ;
    for (i = 0; i < 15; i++)
      t->name[i] = getbyte(_psp,0x80+30+i) ;
    strcpy(fix_es_reg,NULL) ;                                                  /* ;AN000; */
  }
  return(status) ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned dexit(s)                                                              /* ;AC000; */
unsigned s ;
{
  if (target_full)                                                             /* ;AN000; If unable to copy any files */
    s = ERRLEVEL8 ;                                                            /* ;AN000; Insufficient memory */
  exit(s) ;                                                                    /* ;AN000; terminate program */
  return ;
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

void dta_save(t,l)                                                             /* ;AC000; */
char     *t ;
unsigned l ;
{
  unsigned i ;

  for (i = 0; i < l; i++)
    *(t+i) = getbyte(_psp,0x80+i) ;
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */
  return ;                                                                     /* ;AC000; */
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

void dta_restore(t,l)                                                          /* ;AC000; */
char     *t ;
unsigned l ;
{
  unsigned i ;

  for (i = 0; i < l; i++)
    putbyte(_psp,0x80+i,*(t+i)) ;
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */
  return ;                                                                     /* ;AC000; */
}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

char getbyte(msegment,moffset)                                                 /* ;AN000; */
unsigned int msegment ;                                                        /* ;AN000; */
unsigned int moffset ;                                                         /* ;AN000; */
{                                                                              /* ;AN000; */
  char far * cPtr ;                                                            /* ;AN000; */

  FP_SEG(cPtr) = msegment ;                                                    /* ;AN000; */
  FP_OFF(cPtr) = moffset ;                                                     /* ;AN000; */
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */
  return(*cPtr) ;                                                              /* ;AN000; */
}                                                                              /* ;AN000; */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

unsigned getword(msegment,moffset)                                             /* ;AN000; */
unsigned int msegment ;                                                        /* ;AN000; */
unsigned int moffset ;                                                         /* ;AN000; */
{                                                                              /* ;AN000; */
  unsigned far * uPtr ;                                                        /* ;AN000; */

  FP_SEG(uPtr) = msegment ;                                                    /* ;AN000; */
  FP_OFF(uPtr) = moffset ;                                                     /* ;AN000; */
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */
  return(*uPtr) ;                                                              /* ;AN000; */
}                                                                              /* ;AN000; */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

long getdword(msegment,moffset)                                                /* ;AN000; */
unsigned int msegment ;                                                        /* ;AN000; */
unsigned int moffset ;                                                         /* ;AN000; */
{                                                                              /* ;AN000; */
  long far * lPtr ;                                                            /* ;AN000; */

  FP_SEG(lPtr) = msegment ;                                                    /* ;AN000; */
  FP_OFF(lPtr) = moffset ;                                                     /* ;AN000; */
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */
  return(*lPtr) ;                                                              /* ;AN000; */
}                                                                              /* ;AN000; */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

void putbyte(msegment,moffset,value)                                           /* ;AN000; */
unsigned int msegment ;                                                        /* ;AN000; */
unsigned int moffset ;                                                         /* ;AN000; */
char     value ;                                                               /* ;AN000; */
{                                                                              /* ;AN000; */
  char far * cPtr ;                                                            /* ;AN000; */

  FP_SEG(cPtr) = msegment ;                                                    /* ;AN000; */
  FP_OFF(cPtr) = moffset ;                                                     /* ;AN000; */
  *cPtr        = value ;                                                       /* ;AN000; */
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */
  return ;                                                                     /* ;AN000; */
}                                                                              /* ;AN000; */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

void putword(msegment,moffset,value)                                           /* ;AN000; */
unsigned int msegment ;                                                        /* ;AN000; */
unsigned int moffset ;                                                         /* ;AN000; */
unsigned value ;                                                               /* ;AN000; */
{                                                                              /* ;AN000; */
  unsigned far * uPtr ;                                                        /* ;AN000; */

  FP_SEG(uPtr) = msegment ;                                                    /* ;AN000; */
  FP_OFF(uPtr) = moffset ;                                                     /* ;AN000; */
  *uPtr        = value ;                                                       /* ;AN000; */
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */
  return ;                                                                     /* ;AN000; */
}                                                                              /* ;AN000; */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

void putdword(msegment,moffset,value)                                          /* ;AN000; */
unsigned int msegment ;                                                        /* ;AN000; */
unsigned int moffset ;                                                         /* ;AN000; */
long     value ;                                                               /* ;AN000; */
{                                                                              /* ;AN000; */
  long far * lPtr ;                                                            /* ;AN000; */

  FP_SEG(lPtr) = msegment ;                                                    /* ;AN000; */
  FP_OFF(lPtr) = moffset ;                                                     /* ;AN000; */
  *lPtr        = value ;                                                       /* ;AN000; */
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */
  return ;                                                                     /* ;AN000; */
}                                                                              /* ;AN000; */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   load_msg                                           */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Load the set of REPLACE Utility messages to     */
/*                        become available for display_msg call.          */
/*                                                                        */
/*  ERROR EXIT:        Utility will be terminated by sysloadmsg if        */
/*                     version check is incorrect.                        */
/*                                                                        */
/*  EXTERNAL REF:      SYSLOADMSG                                         */
/*                                                                        */
/**************************************************************************/

void load_msg()                                                                /* ;AN000;M */
{                                                                              /* ;AN000;M */
  sysloadmsg(&inregs,&outregs) ;                                               /* ;AN000;M Load utility messages */
  if (outregs.x.cflag & CARRY)                                                 /* ;AN000;M */
  {                                                                            /* ;AN000;M */
    sysdispmsg(&outregs,&outregs) ;                                            /* ;AN000;M If load error, display err msg */
    dexit(ERRLEVEL1) ;                                                         /* ;AN000;M */
  }                                                                            /* ;AN000;M */
  return ;                                                                     /* ;AN000;M Return with no error */
}                                                                              /* ;AN000;M */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   dcompare                                           */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Check a Y/N response using an Int21 Get         */
/*                        Extended Country information.                   */
/*                                                                        */
/*  INPUT:             function  (character to check) (global)            */
/*                                                                        */
/*  OUTPUT:            status    (carry flag if set or response)          */
/*                                                                        */
/*  NORMAL EXIT:       AX=0=No  (status = 2)                              */
/*                     AX=1=Yes (status = 1)                              */
/*                                                                        */
/**************************************************************************/

unsigned dcompare()                                                            /* ;AN000;EC */
{                                                                              /* ;AN000;EC */
  unsigned status ;                                                            /* ;AN000;EC Receives error cond or Y/N */

  inregs.x.dx = outregs.x.ax ;                                                 /* ;AN000;EC Char rec'd by msg hndlr to be ckd */
  inregs.x.ax = 0x6523 ;                                                       /* ;AN000;EC 65=Get-Ext-Cty 23=Y/N chk */
  intdos(&inregs,&outregs) ;                                                   /* ;AN000;EC Int21 call */
  if ((outregs.x.cflag & CARRY) ||                                             /* ;AN000;EC If the carry flag is set */
     (outregs.x.ax > 1))                                                       /* ;AN000;EC or invalid return code */
    not_valid_input = TRUE ;                                                   /* ;AN000;EC   then input is not valid */
  else                                                                         /* ;AN000;EC else */
  {                                                                            /* ;AN000;EC */
    not_valid_input = FALSE ;                                                  /* ;AN000;EC   input is valid */
    if (outregs.x.ax == 0)                                                     /* ;AC000;EC */
      status = 2 ;                                                             /* ;AN000;EC   2 = No */
    else                                                                       /* ;AC000;EC */
      status = 1 ;                                                             /* ;AN000;EC   1 = Yes */
  }                                                                            /* ;AN000;EC */
  return(status) ;                                                             /* ;AN000;EC */
}                                                                              /* ;AN000;EC */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   display_msg                                        */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  The correct message called by main is displayed */
/*                        to standard out or standard error.              */
/*                                                                        */
/*  INPUT:             msg_num   (message number to display)              */
/*                     outline   (string for replacement parm)            */
/*                                                                        */
/*  OUTPUT:            none                                               */
/*                                                                        */
/*  NORMAL EXIT:       The correct message called will be displayed to    */
/*                     standard out or standard error.                    */
/*                                                                        */
/*  ERROR EXIT:        Display error message corresponding to number      */
/*                     returned in AX.                                    */
/*                                                                        */
/*  EXTERNAL REF:      SYSDISPMSG                                         */
/*                                                                        */
/**************************************************************************/

void display_msg(msg_num,outline)                                              /* ;AN000;M */
int  msg_num ;                                                                 /* ;AN000;M Message number #define'd */
char *outline ;                                                                /* ;AN000;M String for replacemnt parm */
{                                                                              /* ;AN000;M */
  unsigned status ;                                                            /* ;AN000;M Receives carry flag if set */
  unsigned char function ;                                                     /* ;AN000;M Y/N response or press key? */
  unsigned int message,                                                        /* ;AN000;M Message number to display */
               msg_class,                                                      /* ;AN000;M Which class of messages? */
               sub_cnt,                                                        /* ;AN000;M Number of substitutions? */
               handle ;                                                        /* ;AN000;M Display where? */

  struct sublist                                                               /* ;AN000;M */
  {                                                                            /* ;AN000;M */
    unsigned char size ;                                                       /* ;AN000;M Points to next sublist */
    unsigned char reserved ;                                                   /* ;AN000;M Required for syddispmsg */
    unsigned far  *value ;                                                     /* ;AN000;M Data pointer */
    unsigned char id ;                                                         /* ;AN000;M Id of substitution parm (%1) */
    unsigned char flags ;                                                      /* ;AN000;M Format of data - (a0sstttt) */
    unsigned char max_width ;                                                  /* ;AN000;M Maximum field width */
    unsigned char min_width ;                                                  /* ;AN000;M Minimum field width */
    unsigned char pad_char ;                                                   /* ;AN000;M char to pad field */
  } sublist ;                                                                  /* ;AN000;M */

  switch (msg_num)                                                             /* ;AN000;M Which msg to display? */
  {                                                                            /* ;AN000;M */
    case MSG_NOMEM    :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 8 ;                                       /* ;AN000;M Message number to display */
                         msg_class = EXT_ERR_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT0 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_INCOMPAT :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 11 ;                                      /* ;AN000;M Message number to display */
                         msg_class = PARSE_ERR_CLASS ;                         /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT0 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_NOSOURCE :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 2 ;                                       /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT0 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_NONEREPL :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 3 ;                                       /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT0 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDOUT ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_NONEADDE :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 4 ;                                       /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT0 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDOUT ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_START    :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 21 ;                                      /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT0 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_ERRFNF   :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 2 ;                                       /* ;AN000;M Message number to display */
                         msg_class = EXT_ERR_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDOUT ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_ERRPNF   :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 3 ;                                       /* ;AN000;M Message number to display */
                         msg_class = EXT_ERR_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDOUT ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_ERRACCD  :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 5 ;                                       /* ;AN000;M Message number to display */
                         msg_class = EXT_ERR_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDOUT ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_ERRDRV   :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 15 ;                                      /* ;AN000;M Message number to display */
                         msg_class = EXT_ERR_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_BADPARM  :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 10 ;                                      /* ;AN000;M Message number to display */
                         msg_class = PARSE_ERR_CLASS ;                         /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_WARNSAME :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 11 ;                                      /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_ERRDSKF  :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 12 ;                                      /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_REPLACIN :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 13 ;                                      /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDOUT ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_ADDING   :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 14 ;                                      /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDOUT ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_SOMEREPL :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 15 ;                                      /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDOUT ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_SOMEADDE :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 16 ;                                      /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDOUT ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_NONFOUND :  function  = NO_INPUT ;                                /* ;AN000;M Y/N response or press key? */
                         message   = 17 ;                                      /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDOUT ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_QREPLACE :  function  = DOS_CON_INPUT ;                           /* ;AN000;M Y/N response or press key? */
                         message   = 22 ;                                      /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_QADD     :  function  = DOS_CON_INPUT ;                           /* ;AN000;M Y/N response or press key? */
                         message   = 23 ;                                      /* ;AN000;M Message number to display */
                         msg_class = UTILITY_CLASS ;                           /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_XTRAPARM :  function  = NO_INPUT ;                                /* ;AN005;M Y/N response or press key? */
                         message   = 1 ;                                       /* ;AN000;M Message number to display */
                         msg_class = PARSE_ERR_CLASS ;                         /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
    case MSG_BADSWTCH :  function  = NO_INPUT ;                                /* ;AN005;M Y/N response or press key? */
                         message   = 3 ;                                       /* ;AN000;M Message number to display */
                         msg_class = PARSE_ERR_CLASS ;                         /* ;AN000;M Which class of messages? */
                         sub_cnt   = SUBCNT1 ;                                 /* ;AN000;M Number of substitutions? */
                         handle    = STDERR ;                                  /* ;AN000;M Display where? */
                         break ;                                               /* ;AN000;M */
  }                                                                            /* ;AN000;M */

  switch (msg_num)                                                             /* ;AN000;M */
  {                                                                            /* ;AN000;M */
    case MSG_NOMEM    :                                                        /* ;AN000;M Insufficient memory */
    case MSG_INCOMPAT :                                                        /* ;AN000;M Invalid parameter combo */
    case MSG_NOSOURCE :                                                        /* ;AN000;M Source path required */
    case MSG_NONEREPL :                                                        /* ;AN000;M No files replaced */
    case MSG_NONEADDE :                                                        /* ;AN000;M No files added */
    case MSG_START    :  inregs.x.ax = message ;                               /* ;AN000;M Press any key... */
                         inregs.x.bx = handle ;                                /* ;AN000;M STDERR or STDOUT */
                         inregs.x.cx = sub_cnt ;                               /* ;AN000;M SUBCNT0 */
                         inregs.h.dl = function ;                              /* ;AN000;M NO_INPUT */
                         inregs.h.dh = msg_class ;                             /* ;AN000;M Extended, Parse or Utility */
                         sysdispmsg(&inregs,&outregs) ;                        /* ;AN000;M Call common msg service */
                         break ;                                               /* ;AN000;M */
    case MSG_BADPARM  :                                                        /* ;AN000;M Invalid parameter */
    case MSG_XTRAPARM :                                                        /* ;AN005;M Too many parameters */
    case MSG_BADSWTCH :                                                        /* ;AN005;M Invalid switch */
    case MSG_ERRFNF   :                                                        /* ;AN000;M File not found */
    case MSG_ERRPNF   :                                                        /* ;AN000;M Path not found */
    case MSG_ERRACCD  :                                                        /* ;AN000;M Access denied */
    case MSG_ERRDRV   :                                                        /* ;AN000;M Invalid drive specification */
    case MSG_WARNSAME :                                                        /* ;AN000;M File cannot be copied... */
    case MSG_ERRDSKF  :  sublist.value     = (unsigned far *)outline ;         /* ;AN000;M Insufficient disk space */
                         sublist.size      = SUBLIST_LENGTH ;                  /* ;AN000;M */
                         sublist.reserved  = RESERVED ;                        /* ;AN000;M */
                         sublist.id        = 0 ;                               /* ;AN000;M */
                         sublist.flags     = STR_INPUT ;                       /* ;AN000;M */
                         sublist.max_width = 0 ;                               /* ;AN000;M */
                         sublist.min_width = 1 ;                               /* ;AN000;M */
                         sublist.pad_char  = BLNK ;                            /* ;AN000;M */
                         inregs.x.ax       = message ;                         /* ;AN000;M Which message? */
                         inregs.x.bx       = handle ;                          /* ;AN000;M STDERR or STDOUT */
                         inregs.x.si       = (unsigned int)&sublist ;          /* ;AN000;M SUBCNT0 */
                         inregs.x.cx       = sub_cnt ;                         /* ;AN000;M NO_INPUT */
                         inregs.h.dl       = function ;                        /* ;AN000;M Extended, Parse or Utility */
                         inregs.h.dh       = msg_class ;                       /* ;AN000;M Call common msg service */
                         sysdispmsg(&inregs,&outregs) ;                        /* ;AN000;M */
                         break ;                                               /* ;AN000;M */
    case MSG_SOMEREPL :                                                        /* ;AN000;M %1 file(s) replaced */
    case MSG_SOMEADDE :  sublist.value     = (unsigned far *)outline ;         /* ;AN000;M %1 file(s) added */
                         sublist.size      = SUBLIST_LENGTH ;                  /* ;AN000;M */
                         sublist.reserved  = RESERVED ;                        /* ;AN000;M */
                         sublist.id        = 1 ;                               /* ;AN000;M */
                         sublist.flags     = DEC_INPUT ;                       /* ;AN000;M */
                         sublist.max_width = 0 ;                               /* ;AN000;M */
                         sublist.min_width = 1 ;                               /* ;AN000;M */
                         sublist.pad_char  = BLNK ;                            /* ;AN000;M */
                         inregs.x.ax       = message ;                         /* ;AN000;M Which message? */
                         inregs.x.bx       = handle ;                          /* ;AN000;M STDERR or STDOUT */
                         inregs.x.si       = (unsigned int)&sublist ;          /* ;AN000;M SUBCNT1 */
                         inregs.x.cx       = sub_cnt ;                         /* ;AN000;M NO_INPUT */
                         inregs.h.dl       = function ;                        /* ;AN000;M Extended, Parse or Utility */
                         inregs.h.dh       = msg_class ;                       /* ;AN000;M Call common msg service */
                         sysdispmsg(&inregs,&outregs) ;                        /* ;AN000;M */
                         break ;                                               /* ;AN000;M */
    case MSG_REPLACIN :                                                        /* ;AN000;M Replacing %1 */
    case MSG_ADDING   :                                                        /* ;AN000;M Adding %1 */
    case MSG_NONFOUND :                                                        /* ;AN000;M No files found */
    case MSG_QREPLACE :                                                        /* ;AN000;M Replace %1? (Y/N) */
    case MSG_QADD     :  sublist.value     = (unsigned far *)outline ;         /* ;AN000;M Add %1? (Y/N) */
                         sublist.size      = SUBLIST_LENGTH ;                  /* ;AN000;M */
                         sublist.reserved  = RESERVED ;                        /* ;AN000;M */
                         sublist.id        = 1 ;                               /* ;AN000;M */
                         sublist.flags     = STR_INPUT ;                       /* ;AN000;M */
                         sublist.max_width = 0 ;                               /* ;AN000;M */
                         sublist.min_width = 1 ;                               /* ;AN000;M */
                         sublist.pad_char  = BLNK ;                            /* ;AN000;M */
                         inregs.x.ax       = message ;                         /* ;AN000;M Which message? */
                         inregs.x.bx       = handle ;                          /* ;AN000;M STDERR or STDOUT*/
                         inregs.x.si       = (unsigned int)&sublist ;          /* ;AN000;M SUBCNT1 */
                         inregs.x.cx       = sub_cnt ;                         /* ;AN000;M NO_INPUT or DOS_CON_INPUT */
                         inregs.h.dl       = function ;                        /* ;AN000;M Extended, Parse or Utility */
                         inregs.h.dh       = msg_class ;                       /* ;AN000;M Call common msg service */
                         sysdispmsg(&inregs,&outregs) ;                        /* ;AN000;M */
                         break ;                                               /* ;AN000;M */
    default           :  restore() ;                                           /* ;AN000;M */
                         dexit(ERRLEVEL1) ;                                    /* ;AN000;M */
                         break ;                                               /* ;AN000;M */
  }                                                                            /* ;AN000;M */

  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000;P (Set es reg correct) */
  if (outregs.x.cflag & CARRY)                                                 /* ;AN000;M Is the carry flag set? */
  {                                                                            /* ;AN000;M Setup regs for extd-err */
    inregs.x.bx = STDERR ;                                                     /* ;AN000;M */
    inregs.x.cx = SUBCNT0 ;                                                    /* ;AN000;M */
    inregs.h.dl = NO_INPUT ;                                                   /* ;AN000;M */
    inregs.h.dh = EXT_ERR_CLASS ;                                              /* ;AN000;M */
    sysdispmsg(&inregs,&outregs) ;                                             /* ;AN000;M Call to display ext_err msg */
    restore() ;                                                                /* ;AN000;M */
    dexit(ERRLEVEL1) ;                                                         /* ;AN000;M */
  }                                                                            /* ;AN000;M */
  return ;                                                                     /* ;AN000;M */
}                                                                              /* ;AN000;M */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   get_ext_attr                                       */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Get the Extended Attributes of the source       */
/*                        file for the copy operation.                    */
/*                                                                        */
/*  INPUT:             source_handle                                      */
/*                     size_buffer (0=get size)                           */
/*                                                                        */
/*  OUTPUT:            status (no extended attributes for DOS 4.00)       */
/*                                                                        */
/**************************************************************************/

unsigned get_ext_attr(source_handle,size_buffer)                               /* ;AN000;EA */
unsigned source_handle ;                                                       /* ;AN000;EA */
unsigned size_buffer ;                                                         /* ;AN000;EA 0 or size returned */
{                                                                              /* ;AN000;EA */
  unsigned status ;                                                            /* ;AN000;EA */

  inregs.x.ax = 0x5702 ;                                                       /* ;AN000;EA Get Ext Attr By Handle */
  inregs.x.bx = source_handle ;                                                /* ;AN000;EA Source file handle */
  inregs.x.cx = size_buffer ;                                                  /* ;AN000;EA # of bytes or 0=get size */
  segregs.es  = segment ;                                                      /* ;AN000;EA Use buffer "segment" */
  inregs.x.di = 0 ;                                                            /* ;AN000;EA Put the attrs in buffer */
  inregs.x.si = -1 ;                                                           /* ;AN000;EA Select all attributes */
  intdosx(&inregs,&outregs,&segregs) ;                                         /* ;AN000;EA Int 21 */
  status = (outregs.x.cflag & CARRY) ;                                         /* ;AN000;EA Make the call */
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */
  return(status) ;                                                             /* ;AN000;EA */
}                                                                              /* ;AN000;EA */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   check_appendx_install                              */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Determine if append and correct version is      */
/*                        currently installed.                            */
/*                                                                        */
/*  INPUT:             none                                               */
/*                                                                        */
/*  OUTPUT:            status (TRUE or FALSE)                             */
/*                                                                        */
/**************************************************************************/

unsigned check_appendx_install()                                               /* ;AN000;X */
{                                                                              /* ;AN000;X */
  unsigned status = FALSE ;                                                    /* ;AN000;X */

  inregs.x.ax = GETX_INSTALL ;                                                 /* ;AN000;X Get Append /x status */
  int86(0x2f,&inregs,&outregs) ;                                               /* ;AN000;X Make the call */
  if (outregs.h.al)                                                            /* ;AN000;X */
  {                                                                            /* ;AN000;X */
    inregs.x.ax = GETX_VERSION ;                                               /* ;AN000;X */
    int86(0x2f,&inregs,&outregs) ;                                             /* ;AN000;X */
    if (outregs.x.ax == X_INSTALLED)                                           /* ;AN000;X */
      status = TRUE ;                                                          /* ;AN000;X */
  }                                                                            /* ;AN000;X */
  return(status) ;                                                             /* ;AN000;X */
}                                                                              /* ;AN000;X */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   check_appendx                                      */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Get the append /x status.                       */
/*                                                                        */
/*  INPUT:             none                                               */
/*                                                                        */
/*  OUTPUT:            bx (contains append bits set)                      */
/*                                                                        */
/**************************************************************************/

unsigned check_appendx()                                                       /* ;AN000;X */
{                                                                              /* ;AN000;X */
  inregs.x.ax = GETX_STATUS ;                                                  /* ;AN000;X Get Append /x status */
  int86(0x2f,&inregs,&outregs) ;                                               /* ;AN000;X Make the call */
  return(outregs.x.bx) ;                                                       /* ;AN000;X */
}                                                                              /* ;AN000;X */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   set_appendx                                        */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Set the append /x status.                       */
/*                                                                        */
/*  INPUT:             set_state (turn appendx bit off or reset original) */
/*                                                                        */
/*  OUTPUT:            none                                               */
/*                                                                        */
/**************************************************************************/

void set_appendx(set_state)                                                    /* ;AN000;X */
unsigned set_state ;                                                           /* ;AN000;X */
{                                                                              /* ;AN000;X */
  inregs.x.ax = SETX_STATUS ;                                                  /* ;AN000;X Set Append /x status */
  inregs.x.bx = set_state ;                                                    /* ;AN000;X */
  int86(0x2f,&inregs,&outregs) ;                                               /* ;AN000;X */
  return ;                                                                     /* ;AN000;X */
}                                                                              /* ;AN000;X */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   parser_prep                                        */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Initialize all structures for the parser.       */
/*                                                                        */
/*  INPUT:             source (command line string)                       */
/*                                                                        */
/*  OUTPUT:            none                                               */
/*                                                                        */
/**************************************************************************/

void parser_prep(source)                                                       /* ;AN000;P */
char *source ;                                                                 /* ;AN000;P Commandline */
{                                                                              /* ;AN000;P */
  p_p.p_parmsx_address    = &p_px ;                                            /* ;AN000;P Address of extd parm list */
  p_p.p_num_extra         = 0 ;                                                /* ;AN000;P No extra declarations */

  p_px.p_minp             = MINPOSITION ;                                      /* ;AN000;P 1 required positional */
  p_px.p_maxp             = MAXPOSITION ;                                      /* ;AN000;P 2 maximum positionals */
  p_px.p_control1         = &p_con1 ;                                          /* ;AN000;P pointer to next control blk */
  p_px.p_control2         = &p_con2 ;                                          /* ;AN000;P pointer to next control blk */
  p_px.p_maxs             = 1 ;                                                /* ;AN000;P Specify # of switches */
  p_px.p_switch           = &p_swit ;                                          /* ;AN000;P Point to the switch blk */
  p_px.p_maxk             = 0 ;                                                /* ;AN000;P Specify # of keywords */

  p_con1.p_match_flag     = REQ_FILESPEC ;                                     /* ;AN000;P File spec required */
  p_con1.p_function_flag  = CAPRESULT ;                                        /* ;AN000;P Cap result by file table */
  p_con1.p_result_buf     = (unsigned int)&rslt1 ;                             /* ;AN000;P */
  p_con1.p_value_list     = (unsigned int)&novals ;                            /* ;AN000;P */
  p_con1.p_nid            = 0 ;                                                /* ;AN000;P */

  p_con2.p_match_flag     = OPT_FILESPEC ;                                     /* ;AN000;P File spec & optional */
  p_con2.p_function_flag  = CAPRESULT ;                                        /* ;AN000;P Cap result by file table */
  p_con2.p_result_buf     = (unsigned int)&rslt1 ;                             /* ;AN000;P */
  p_con2.p_value_list     = (unsigned int)&novals ;                            /* ;AN000;P */
  p_con2.p_nid            = 0 ;                                                /* ;AN000;P */

  p_swit.sp_match_flag    = OPT_SWITCH ;                                       /* ;AN000;P Optional (switch) */
  p_swit.sp_function_flag = NOCAPPING ;                                        /* ;AN000;P Cap result by file table */
  p_swit.sp_result_buf    = (unsigned int)&rslt2 ;                             /* ;AN000;P */
  p_swit.sp_value_list    = (unsigned int)&novals ;                            /* ;AN000;P */
  p_swit.sp_nid           = 6 ;                                                /* ;AN000;P One switch allowed */
  strcpy(p_swit.sp_keyorsw1,A_SW) ;                                            /* ;AN000;P Identify the switch */
  strcat(p_swit.sp_keyorsw2,P_SW) ;                                            /* ;AN000;P Identify the switch */
  strcat(p_swit.sp_keyorsw3,R_SW) ;                                            /* ;AN000;P Identify the switch */
  strcat(p_swit.sp_keyorsw4,S_SW) ;                                            /* ;AN000;P Identify the switch */
  strcat(p_swit.sp_keyorsw5,U_SW) ;                                            /* ;AN000;P Identify the switch */
  strcat(p_swit.sp_keyorsw6,W_SW) ;                                            /* ;AN000;P Identify the switch */

  inregs.x.si = (unsigned int)source ;                                         /* ;AN000;P Make DS:SI point to source */
  inregs.x.cx = 0 ;                                                            /* ;AN000;P Operand ordinal */
  inregs.x.di = (unsigned int)&p_p ;                                           /* ;AN000;P Address of parm list */
  return ;                                                                     /* ;AN000;P */
}                                                                              /* ;AN000;P */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   display_exit                                       */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Display the message, then terminate the utility.*/
/*                                                                        */
/*  INPUT:             msg_num     (#define'd message to display)         */
/*                     outline     (sublist substitution)                 */
/*                     error_code  (errorlevel return code)               */
/*                                                                        */
/*  OUTPUT:            none                                               */
/*                                                                        */
/**************************************************************************/

void display_exit(msg_num,outline,error_code)                                  /* ;AN000;M */
int  msg_num ;                                                                 /* ;AN000;M Message number #define'd */
char *outline ;                                                                /* ;AN000;M */
int  error_code ;                                                              /* ;AN006; */
{                                                                              /* ;AN000;M */
  display_msg(msg_num,outline) ;                                               /* ;AN000;M First, display the msg */
  restore() ;                                                                  /* ;AN006; */
  dexit(error_code) ;                                                          /* ;AN000;M Then, terminate utility */
}                                                                              /* ;AN000;M */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   setup_ctl_brk                                      */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Change the CTL BRK vector to point to handler   */
/*                        routine.                                        */
/*                                                                        */
/*  INPUT:             none                                               */
/*                                                                        */
/*  OUTPUT:            none                                               */
/*                                                                        */
/**************************************************************************/

void setup_ctl_brk()                                                           /* ;AN000; */
{                                                                              /* ;AN000; */
  /* set the ctl brk vector to point to us */
  segread(&segregs) ;                                                          /* ;AN000; */
  inregs.x.ax = SETVEC_CTLBRK ;                                                /* ;AN000; Set vector,ctl brk */
  inregs.x.dx = (unsigned)ctl_brk_handler ;                                    /* ;AN000; Offset points to us */
  segregs.ds  = segregs.cs ;                                                   /* ;AN000; */
  intdosx(&inregs,&outregs,&segregs) ;                                         /* ;AN000; Int 21 */
  return ;                                                                     /* ;AN000; */
}                                                                              /* ;AN000; */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   setup_crit_err                                     */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Change the critical error vector to point to    */
/*                        the handler routine.                            */
/*                                                                        */
/*  INPUT:             none                                               */
/*                                                                        */
/*  OUTPUT:            none                                               */
/*                                                                        */
/**************************************************************************/

void setup_crit_err()                                                          /* ;AN000; */
{                                                                              /* ;AN000; */
  /* get and save original vector pointers */
  inregs.x.ax = GETVEC_CRITERR ;                                               /* ;AN000; Get vector,crit err */
  intdosx(&inregs,&outregs,&segregs) ;                                         /* ;AN000; Int 21 */
  oldint24 = outregs.x.bx ;                                                    /* ;AN000; Save orig offset */
  *((unsigned *)(&oldint24)+1) = segregs.es ;                                  /* ;AN000; */
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */

  /* set the crit err vector to point to us */
  segread(&segregs) ;                                                          /* ;AN000; */
  inregs.x.ax = SETVEC_CRITERR ;                                               /* ;AN000; Set vector,crit err */
  inregs.x.dx = (unsigned)crit_err_handler ;                                   /* ;AN000; Offset points to us */
  segregs.ds  = segregs.cs ;                                                   /* ;AN000; */
  intdosx(&inregs,&outregs,&segregs) ;                                         /* ;AN000; Int 21 */
  strcpy(fix_es_reg,NULL) ;                                                    /* ;AN000; */
  return ;                                                                     /* ;AN000; */
}                                                                              /* ;AN000; */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/**************************************************************************/
/*                                                                        */
/*  SUBROUTINE NAME:   restore                                            */
/*                                                                        */
/*  SUBROUTINE FUNCTION:  Restore the original appendx before exiting.    */
/*                                                                        */
/*  INPUT:             none                                               */
/*                                                                        */
/*  OUTPUT:            none                                               */
/*                                                                        */
/**************************************************************************/

void restore()                                                                 /* ;AN000; */
{                                                                              /* ;AN000; */
  /* restore append/x status */
  if (append_installed)                                                        /* ;AN000;A */
    set_appendx(x_status) ;                                                    /* ;AN000;A Reset append/x status */
  return ;                                                                     /* ;AN000; */
}                                                                              /* ;AN000; */
