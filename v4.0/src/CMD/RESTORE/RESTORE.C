
/*  0 */

/**************************************************************************/
/*
/*  MODULE NAME :  RESTORE utility
/*
/*  SOURCE FILE NAME: RESTORE.C
/*
/*  DESCRIPTIVE NAME : Restore one or more backed-up files from a
/*		       disk to another disk
/*
/*  FUNCTION: Restore files saved by BACKUP utility to their
/*	      destination disk.  This utility will be able to identify
/*	      which of the two backup formats was used and to do the
/*	      restore accordingly.
/*
/*  NOTES:  This RESTORE utility recognize two data formats:
/*	    1. The data format used by BACKUP utility of 3.2 and before.
/*	    2. The data format used by BACKUP utility of 3.3 and above,
/*	       and also used by CP/DOS 1.0 and above.
/*
/*	    DEPENDENCY:
/*	    This utility has a dependency on the BACKUP utility to
/*	    perform file backup correctly using the data structure
/*	    agreed on.
/*
/*	    RESTRICTION:
/*	    This utility is able to restore the files which are previously
/*	    backup by the BACKUP utility only.
/*
/*  ENTRY POINT: Main
/*
/*  INPUT: (PARAMETERS)
/*
/*	COMMAND SYNTAX:
/*	      [d:][path]Restore d: [d:][path][filename][.ext]
/*	      [/S] [/P] [/B:date] [/A:date] [/E:time][/L:time][/M] [/N]
/*
/*	Parameters:
/*	      The first parameter you specify is the drive designator of
/*	      the disk containing the backed up files.	The second
/*	      parameter is the a filespec indicating which files you want
/*	      to restore.
/*	Switches:
/*	      /S - Restore subdirectories too.
/*	      /P - If any hidden or read-only files match the filespec,
/*		   prompt the user for permission to restore them.
/*	      /B - Only restore those files which were last Revised on or
/*		   before the given date.
/*	      /A - Only restore those files which were last Revised on or
/*		   after the given date.
/*	      /E - Only restore those files which were last Revised at or
/*		   earlier then the given time.
/*	      /L - Only restore those files which were last Revised at or
/*		   later then the given time.
/*	      /M - Only restore those files which have been Revised since
/*		   the last backup.
/*	      /N - Only restore those files which no longer exist on the
/*		   destination disk.
/*
/*  EXIT-ERROR:
/*	 The restore program sets the ERRORLEVEL in the following manner:
/*
/*	   0   Normal completion
/*	   1   No files were found to backup
/*	   2   Some files not restored due to sharing conflict
/*	   3   Terminated by user
/*	   4   Terminated due to error
/*
/*
/*   SOURCE HISTORY:
/*
/*	Modification History:
/*
/*	   Code added in DOS 3.3 to allow control file > 64k commented as:
/*	   /* !wrw */
/*
/*	 ;AN000; Code added in DOS 4.0
/*		;AN000;2  Support for APPEND /X deactivation
/*		;AN000;3  Support for Extended Attributes
/*		;AN000;4  Support for PARSE service routines
/*		;AN000;5  Support for code page file tags
/*		;AN000;6  Support for MESSAGE retriever
/*		;AN000;8  Eliminate double prompting on single drive systems
/*		;AN000;9  Fix for termination on "Unable to MKDIR"
/*		;AN000;10 Fix for p1620
/*		;AN001;   Add CR, LF to end of command line
/*		;AN002;   Make parser errors display the offending parameter
/*		;AN003;   Only disallow restore of system files in ROOT !!
/*		;AN004;   Fix parser
/*		;AN005;   Replace COM_STRRCHR dbcs routine, fixes p5029
/*****************  END OF SPECIFICATION    *********************************/

#include "rt.h"
#include "rt1.h"
#include "rt2.h"
#include "restpars.h"                                                 /*;AN000;4*/
#include "dos.h"                                                      /*;AN000;2*/
#include "comsub.h"             /* common subroutine def'n */
#include "doscalls.h"
#include "error.h"


BYTE destddir[MAXPATH+3] = {'\0'};
BYTE srcddir[MAXPATH+3] = {'\0'};
BYTE rtswitch=0;
BYTE control_flag=0;
BYTE control_flag2=0;
BYTE *buf_pointer;

/*=============================*/
BYTE srcd;							      /*;AN000;4*/
BYTE destd;							      /*;AN000;4*/
BYTE inpath  [MAXPATH]; 					      /*;AN000;*/
BYTE infname [MAXFNAME];					      /*;AN000;*/
BYTE infext  [MAXFEXT]; 					      /*;AN000;*/
BYTE infspec [MAXFSPEC];					      /*;AN000;*/
/*=============================*/
/*---------------------------------------*/
/*-					 */
/*- Data structures for the PARSER	 */
/*-					 */
/*---------------------------------------*/

struct	subst_list sublist;		/*;AN000;6 Message substitution list */
char	response_buff[5];		/*;AN000;6 User response buffer *//*;AN000;6*/

BYTE append_indicator = 0xff;		/*;AN000;2 Indicates the support for APPEND /X is active */
WORD original_append_func;		/*;AN000;2 APPEND functions on program entry*/
struct timedate td;

/*****************  START OF SPECIFICATION  *********************************/
/*
/*  SUBROUTINE NAME :  Main
/*
/*  DESCRIPTIVE NAME : Main routine for RESTORE utility
/*
/*  FUNCTION: Main routine does the following:
/*	      1. Verifies the DOS version
/*	      2. Validate the input command line
/*	      3. Calls dorestore to do the file restore.
/*
/*  NOTES:
/*
/*  ENTRY POINT: Main
/*	Linkage: main((argc,argv)
/*
/*  INPUT: (PARAMETERS)
/*	   argc - number of arguments
/*	   argv - array of pointers to arguments
/*
/*  EFFECTS: rtswitch is changed to reflect the switches passed.
/*
/********************** END OF SPECIFICATIONS *******************************/
void main(argc,argv)  /* wrw! */
    int argc;
    char *argv[];
{
   WORD retcode;
   union REGS inregs,outregs;						/*AN000*/
   WORD  i;		/*loop counter */
   WORD  j;		/*arrary subcript */
   BYTE *c;
   DWORD drive_map;
   DWORD prev_address;
   WORD  prev_action;

/**********************************/
/**	PRELOAD MESSAGES	 **/
/**********************************/
   sysloadmsg(&inregs,&outregs);				      /*;AN000;6 Preload messages */
   if (outregs.x.cflag & CARRY) 				      /*;AN000;6 If there was an error */
    {								      /*;AN000;6*/
     sysdispmsg(&outregs,&outregs);				      /*;AN000;6 Display the error message */
     exit_routine(UNEXPECTED);					      /*;AN000;6 and terminate */
    }								      /*;AN000;6*/


/*********************************************/
/* Parse the drive and file name entered     */
/*********************************************/
   parse_command_line						      /*;AN000;4*/
     (								      /*;AN000;4*/
      argc,							      /*;AN000;4*/
      argv							      /*;AN000;4*/
     ); 							      /*;AN000;4*/

/*********************************************/
/*     Make sure APPEND /X is not active     */
/*********************************************/
    check_appendX();						      /*;AN000;2 */


/*********************************************/
/*   Take control of Control Break Interrupt */
/*********************************************/
   retcode = DOSSETSIGHANDLER
    (
      (void far *)signal_handler_routine,	/* Signal handler address */
      (DWORD far *)&prev_address,		/* Address of previous handler */
      (unsigned far *)&prev_action,		/* Address of previous action */
      (unsigned)INSTALL_SIGNAL, 		/* Indicate request type */
      (unsigned)CTRL_C				/* Signal number */
    );

   retcode = DOSSETSIGHANDLER
    (
	(void far *)signal_handler_routine,	/* Signal handler address */
	(DWORD far *)&prev_address,		/* Address of previous handler */
	(unsigned far *)&prev_action,		/* Address of previous action */
	(unsigned)INSTALL_SIGNAL,		/* Indicate request type */
	(unsigned)CTRL_BREAK			/* Signal number */
    );

/*********************************/
/*   Take control of Hard Errors */
/*********************************/
    set_int24_vector(); 			/*;AN000; Set Critical error vector (int 24h) */


   /************************************************************/
   /* call dorestore (RTDO.C) to actually do the restoring     */
   /************************************************************/
   dorestore(srcd,destd,inpath,infname,infext,infspec,&td);

   /************************************************************/
   /* output a msg in the following situations: 	       */
   /*	       if flag indicates no file found		       */
   /************************************************************/
   if (set_reset_test_flag(&control_flag,FOUND,TEST)==FALSE)
    {
		/*warning! No files were found to restore*/
      display_it(NO_FILE_TO_RESTORE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);      /*;AN000;6*/
      exit_routine(NOFILES);
    }

   exit_routine(NORMAL);

} /* end of main*/
