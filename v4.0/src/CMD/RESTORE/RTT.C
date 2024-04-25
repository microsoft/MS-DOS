static char *SCCSID = "@(#)rtt.c        8.1 86/09/20";

/*  0 */

#include <stdio.h>
#include "rt.h"
#include "rt1.h"
#include "rt2.h"
#include <comsub.h>			/* common subroutine def'n */
#include <doscalls.h>
#include <basemid.h>
#include <wrwdefs.h>		   /* wrw! */

unsigned char destddir[MAXPATH+3] = {'\0'};
unsigned char srcddir[MAXPATH+3] = {'\0'};
unsigned char rtswitch=0;
unsigned char control_flag=0;
unsigned char control_flag2=0;
unsigned char filename[MAXFSPEC] = {"OSO001.MSG"};
unsigned char *buf_pointer;

/****************************************************************************/
/* The following comments are necessary to be here to make msgprof.exe	    */
/* correctly.								    */
/****************************************************************************/
/* #define  INSERT_SOURCE_DISK	      MSG_INS_BACKUP_DISK	    */
/* #define  SOURCE_TARGET_SAME	      MSG_REST_SOUR_TARG_SAME	    */
/* #define  INVALID_NUM_PARM	      MSG_REST_NUM_INVAL_PARA	    */
/* #define  INVALID_DRIVE	      MSG_REST_INVAL_SPEC	    */
/* #define  NO_FILE_TO_RESTORE	      MSG_REST_NO_FILE_FOUND	    */
/* #define  INVALID_PARM	      MSG_REST_INVAL_PARA	    */
/* #define  LAST_FILE_NOT_RESTORED    MSG_REST_LAST_FILE_NOT	    */
/* #define  SOURCE_NO_BACKUP_FILE     MSG_REST_SOURCE_NO_BACK	    */
/* #define  INSUFFICIENT_MEMORY       MSG_REST_INSUF_MEM	    */
/* #define  FILE_SEQUENCE_ERROR       MSG_REST_FILE_SEQ_ERROR	    */
/* #define  FILE_CREATION_ERROR       MSG_REST_FILE_CREAT_ERROR     */
/* #define  TARGET_IS_FULL	      MSG_REST_TARG_FULL	    */
/* #define  NOT_ABLE_TO_RESTORE_FILE  MSG_REST_CANNOT_REST_FILE     */
/* #define  INVALID_DOS_VER	      MSG_REST_INVAL_VERS	    */
/* #define  FILE_SHARING_ERROR	      MSG_REST_FILE_SHAR	    */
/* #define  FILE_WAS_CHANGED	      MSG_REST_CHNG_REPL	    */
/* #define  DISK_OUT_OF_SEQUENCE      MSG_REST_DISK_OUT_SEQ	    */
/* #define  FILE_IS_READONLY	      MSG_REST_FILE_READ	    */
/* #define  SYSTEM_FILE_RESTORED      MSG_REST_SYS		    */
/* #define  FILES_WERE_BACKUP_ON      MSG_REST_FILE_BACKUP	    */
/* #define  RESTORE_FILE_FROM_DRIVE   MSG_REST_FILE_FROM	    */
/* #define  INSERT_TARGET_DISK	      MSG_REST_TARG_DISK	    */
/* #define  FILE_TO_BE_RESTORED       MSG_REST_FILENAME 	    */
/* #define  DISKETTE_NUM	      MSG_REST_DISKETTE 	    */
/* #define  PATH_NOT_FOUND	      MSG_BACK_INVAL_PATH	    */

/*****************  START OF SPECIFICATION  *********************************/
/*									    */
/*  MODULE NAME :  RESTORE utility					    */
/*									    */
/*  DESCRIPTIVE NAME : Restore one or more backed-up files from a	    */
/*		       disk to another disk				    */
/*									    */
/*  FUNCTION: Restore files saved by BACKUP utility to their		    */
/*	      destination disk.  This utility will be able to identify	    */
/*	      which of the two backup formats was used and to do the	    */
/*	      restore accordingly.					    */
/*									    */
/*  NOTES:  This RESTORE utility recognize two data formats:		    */
/*	    1. The data format used by BACKUP utility of 3.2 and before.    */
/*	    2. The data format used by BACKUP utility of 3.3 and above,     */
/*	       and also used by CP/DOS 1.0 and above.			    */
/*									    */
/*	    DEPENDENCY: 						    */
/*	    This utility has a dependency on the BACKUP utility to	    */
/*	    perform file backup correctly using the data structure	    */
/*	    agreed on.							    */
/*									    */
/*	    RESTRICTION:						    */
/*	    This utility is able to restore the files which are previously  */
/*	    backup by IBM BACKUP utility only.				    */
/*									    */
/*  ENTRY POINT: Main							    */
/*									    */
/*  INPUT: (PARAMETERS) 						    */
/*									    */
/*	COMMAND SYNTAX: 						    */
/*	      [d:][path]Restore d: [d:][path][filename][.ext]		    */
/*	      [/S] [/P] [/B:date] [/A:date] [/E:time][/L:time][/M] [/N]     */
/*									    */
/*	Parameters:							    */
/*	      The first parameter you specify is the drive designator of    */
/*	      the disk containing the backed up files.	The second	    */
/*	      parameter is the a filespec indicating which files you want   */
/*	      to restore.						    */
/*	Switches:							    */
/*	      /S - Restore subdirectories too.				    */
/*	      /P - If any hidden or read-only files match the filespec,     */
/*		   prompt the user for permission to restore them.	    */
/*	      /B - Only restore those files which were last Revised on or  */
/*		   before the given date.				    */
/*	      /A - Only restore those files which were last Revised on or  */
/*		   after the given date.				    */
/*	      /E - Only restore those files which were last Revised at or  */
/*		   earlier then the given time. 			    */
/*	      /L - Only restore those files which were last Revised at or  */
/*		   later then the given time.				    */
/*	      /M - Only restore those files which have been Revised since  */
/*		   the last backup.					    */
/*	      /N - Only restore those files which no longer exist on the    */
/*		   destination disk.					    */
/*									    */
/*  EXIT-NORMAL:							    */
/*									    */
/*	      The following messages will be displayed when the program     */
/*	      exit normally.						    */
/*									    */
/*	      *** Files were backed up xx/xx/xxxx ***			    */
/*	      (xx/xx/xxxx will be different in differnt country codes)	    */
/*									    */
/*	      *** Restoring files from drive d: ***			    */
/*	      Diskette: xx						    */
/*	      path\filename.ext 					    */
/*	      path\filename.ext 					    */
/*	      path\filename.ext 					    */
/*	      path\filename.ext 					    */
/*	      .....							    */
/*									    */
/*  EXIT-ERROR: 							    */
/*	 The restore program sets the ERRORLEVEL in the following manner:   */
/*									    */
/*	   0   Normal completion					    */
/*	   1   No files were found to backup				    */
/*	   2   Some files not restored due to sharing conflict		    */
/*	   3   Terminated by user					    */
/*	   4   Terminated due to error					    */
/*									    */
/*  EFFECTS: None							    */
/*									    */
/*  OTHER USER INTERFACES:						    */
/*	   RESTORE prompts for the user to insert source diskette if	    */
/*	   the source disk specified is removable:			    */
/*									    */
/*	   Insert backup diskette 01 in drive d:			    */
/*	   (d: is the source diskette)					    */
/*	   Strike any key when ready					    */
/*									    */
/*	   If the destination disk is a removable drive, the following	    */
/*	   message is also displayed:					    */
/*									    */
/*	   Insert restore target in drive d:				    */
/*	   (d: is the destination disk) 				    */
/*	   Strike any key when ready					    */
/*									    */
/*	   No matter whether the destination disk is a removable drive	    */
/*	   or a non_removable drive, when the destination disk is full,     */
/*	   RESTORE output a message "Target is full" and exit.  RESTORE     */
/*	   does not prompt for user to change destination disk when it	    */
/*	   is full.							    */
/*									    */
/*	   When there is any system file restored, the following message    */
/*	   is displayed:						    */
/*	     System file restored					    */
/*	     Target disk may not be bootable				    */
/*									    */
/*  INTERNAL REFERENCES:						    */
/*	   ROUTINES:							    */
/*    Major routines are shown as follows:				    */
/*	      main							    */
/*	      parse_input_drive_and_file				    */
/*	      set_input_switches					    */
/*	      verify_input_switches					    */
/*	      dorestore 						    */
/*	      check_bkdisk_old						    */
/*	      printinfo 						    */
/*	      check_bkdisk_new						    */
/*	      search_src_disk_old					    */
/*	      check_flheader_old					    */
/*	      pathmatch 						    */
/*	      fspecmatch						    */
/*	      switchmatch						    */
/*	      restore_a_file						    */
/*	      search_src_disk_new					    */
/*	      findfirst_new						    */
/*	      findfile_new						    */
/*	      findnext_new						    */
/*	      check_flheader_new					    */
/*	      readonly_or_changed					    */
/*	      open_dest_file						    */
/*	      build_path_create_file					    */
/*	      dos_write_error						    */
/*	      set_attributes_and_close					    */
/*									    */
/*    Minor routines are shown as follows:				    */
/*	      signal_handler_routine					    */
/*	      usererror 						    */
/*	      unexperror						    */
/*	      exit_routine						    */
/*	      putmsg							    */
/*	      com_msg							    */
/*	      beep							    */
/*	      checkdosver						    */
/*	      separate							    */
/*	      initbuf							    */
/*	      init_control_buf						    */
/*	      set_reset_test_flag					    */
/*	      valid_input_date						    */
/*	      valid_input_time						    */
/*									    */
/*****************  END OF SPECIFICATION    *********************************/
/*****************  START OF SPECIFICATION  *********************************/
/*									    */
/*  SUBROUTINE NAME :  Main						    */
/*									    */
/*  DESCRIPTIVE NAME : Main routine for RESTORE utility 		    */
/*									    */
/*  FUNCTION: Main routine does the following:				    */
/*	      1. Verifies the DOS version				    */
/*	      2. Validate the input command line			    */
/*	      3. Calls dorestore to do the file restore.		    */
/*									    */
/*  NOTES:								    */
/*									    */
/*  ENTRY POINT: Main							    */
/*	Linkage: main((argc,argv)					    */
/*									    */
/*  INPUT: (PARAMETERS) 						    */
/*	   argc - number of arguments					    */
/*	   argv - array of pointers to arguments			    */
/*									    */
/*									    */
/*  EXIT-NORMAL:							    */
/*									    */
/*  EXIT-ERROR: 							    */
/*									    */
/*  EFFECTS: rtswitch is changed to reflect the switches passed.	    */
/*									    */
/*  INTERNAL REFERENCES:						    */
/*	   ROUTINES:							    */
/*		    dorestore						    */
/*		    checkdosver 					    */
/*		    set_input_switches					    */
/*		    parse_input_drive_and_file				    */
/*		    separate						    */
/*		    beep						    */
/*		    putmsg						    */
/*		    usererror						    */
/*		    exit_routine					    */
/*		    set_reset_test_flag 				    */
/*		    set_input_switches					    */
/*		    exit_routine					    */
/*									    */
/*  EXTERNAL REFERENCES:						    */
/*	   ROUTINES:							    */
/*		    com_strupr						    */
/*		    DSOSETSIGHANDLER					    */
/*									    */
/********************** END OF SPECIFICATIONS *******************************/
void main(argc,argv)  /* wrw! */
    int argc;
    char *argv[];
{
   /*variables for putmsg */
   unsigned char *ivtable[2];/*point to the table of bairables to insert*/
   unsigned char respdata; /*response data area*/
   unsigned int  msg_id;
   unsigned int retcode;

   unsigned int  destdnum;	  /*the destination disk in the integer form*/
   unsigned int  i;		  /*loop counter			    */
   unsigned int  j;		  /*arrary subcript			    */
   unsigned char *c;
   unsigned long drive_map;
   unsigned long prev_address;
   unsigned int  prev_action;
   unsigned char srcd;
   unsigned char destd;
   unsigned char srcf[MAXPATHF];
   unsigned char inpath[MAXPATH];
   unsigned char infname[MAXFNAME];
   unsigned char infext[MAXFEXT];
   unsigned char infspec[MAXFSPEC];
   unsigned int  next_arg;
   struct timedate td;
   void far  pascal signal_handler_routine();
   /************************************************************************/
   /* set signal handler						   */
   /************************************************************************/

   retcode = DOSSETSIGHANDLER(
	(void (far *)() )signal_handler_routine,   /* Signal handler address */
	(unsigned long far *)&prev_address,  /* Address of previous handler */
	(unsigned far *)&prev_action,	  /* Address of previous action */
	(unsigned)INSTALL_SIGNAL,	  /* Indicate request type */
	(unsigned)CTRL_C);		  /* Signal number */

   if (retcode != 0)
       com_msg(retcode);

   retcode = DOSSETSIGHANDLER(
	(void (far *)() )signal_handler_routine,   /* Signal handler address */
	(unsigned long far *)&prev_address,  /* Address of previous handler */
	(unsigned far *)&prev_action,	  /* Address of previous action */
	(unsigned)INSTALL_SIGNAL,	  /* Indicate request type */
	(unsigned)CTRL_BREAK);		  /* Signal number */

   if (retcode != 0)
      com_msg(retcode);

   /************************************************************************/
   /* check dos version 						   */
   /************************************************************************/
   retcode = checkdosver();
   if (retcode != TRUE) {

	msg_id = INVALID_DOS_VER;
	putmsg (ivtable,0,msg_id,NO_RESPTYPE,&respdata,RESPDATA_SIZE);

	usererror(ERROR_INVALID_DOSVER);
    }

   /************************************************************************/
   /*convert the input arguments into upper case			   */
   /************************************************************************/
   for (i=1; i <=argc-1; ++i) {
       com_strupr(argv[i]);
   }

   /************************************************************************/
   /* verify the number of parameters					   */
   /************************************************************************/
   if (argc-1 < MINARGS || argc-1 > MAXARGS) {
	msg_id = INVALID_NUM_PARM;    /*invalid number of parameters*/
	putmsg (ivtable,0,msg_id,NO_RESPTYPE,&respdata,RESPDATA_SIZE);
	usererror(INVALIDPARM);
   }
   /* endif*/

   /************************************************************************/
   /* call subroutine to parse the drive and file name entered		   */
   /************************************************************************/
   parse_input_drive_and_file( argc, argv, &destd, &srcd,
			      srcf, &next_arg) ;

   /************************************************************************/
   /* separate the filename for search into prefix(inpath),		   */
   /* filename(infname), and file extension (infext)			   */
   /* Also take care of the situation that user enter '.' only             */
   /* for file spec.							   */
   /************************************************************************/
   separate(srcf,inpath,infname,infext,infspec);
   if (strlen(infname) > MAXFNAME-1 ||
       strlen(infext) > MAXFEXT-1 ||
       strlen(inpath) > MAXPATH-1 ||
       strcmp(infspec,"LPT1")==0 ||
       strcmp(infspec,"LPT2")==0 ||
       strcmp(infspec,"PRN")==0 ||
       strcmp(infspec,"CON")==0 ||
       strcmp(infspec,"NUL")==0 ||
       strcmp(infspec,"AUX")==0 ||
       strcmp(infspec,"LPT1:")==0 ||
       strcmp(infspec,"LPT2:")==0 ||
       strcmp(infspec,"PRN:")==0 ||
       strcmp(infspec,"CON:")==0 ||
       strcmp(infspec,"NUL:")==0 ||
       strcmp(infspec,"AUX:")==0 )
   {
       msg_id =  INVALID_PARM;
       ivtable[0] = infspec;
       putmsg (ivtable,1,msg_id,NO_RESPTYPE,&respdata,RESPDATA_SIZE);
       usererror(INVALIDPARM);	     /* invalid parm */
   }

   /************************************************************************/
   /* set wildcard flag according to whether there is '*' or/and  '?' in   */
   /* file specification						   */
   /************************************************************************/
   c = infspec;
   while (*c) {
      if (*c == '*' || *c == '?') {
	set_reset_test_flag(&control_flag,WILDCARD,SET);
	break;
      }
      else
	c = c+1;
   } /*end while*/

   /************************************************************************/
   /* if there is any more parameters to be parsed, call set_input_switches*/
   /* to parse them started from argv[next_arg] 			   */
   /************************************************************************/
   if (next_arg != 0 && argc > next_arg) {
       set_input_switches(  argc, argv, &next_arg, &td);
   }	/* started from argv[next_arg] should be switches */

   /************************************************************************/
   /* call dorestore to actually do the restoring			   */
   /************************************************************************/
   dorestore(srcd,destd,inpath,infname,infext,infspec,&td);

   /************************************************************************/
   /* output a msg in the following situations: 			   */
   /*	       if flag indicates no file found				   */
   /************************************************************************/
   if (set_reset_test_flag(&control_flag,FOUND,TEST)==FALSE) {
      beep();
      msg_id = NO_FILE_TO_RESTORE; /*warning! No files were found to restore*/
      putmsg (ivtable,0,msg_id,NO_RESPTYPE,&respdata,RESPDATA_SIZE);
      exit_routine(NOFILES);
   }

   exit_routine(NORMAL);

} /* end of main*/
